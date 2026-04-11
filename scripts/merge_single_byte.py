#!/usr/bin/env python3
"""
Merge single-byte .byte fragments with adjacent native instructions.

Strategy:
1. Track byte offsets from labels using ELF symbol table
2. For each .byte, read ROM bytes to determine the correct instruction
3. Generate candidate LLVM instructions, batch-verify encodings
4. Replace .byte + consumed lines with verified LLVM instruction
5. Binary I/O for Latin-1 safety
"""

import subprocess
import sys
import os
import re
import tempfile

LLVM_MC = '/home/fsanches/compartilhado/llvm-project/build/bin/llvm-mc'
LLVM_NM = '/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm'
UNIDASM = '/home/fsanches/compartilhado/tools/unidasm'
ROM_DIR = '/home/fsanches/compartilhado/kn5000-roms-disasm/rebuilt_ROMs'
REPO_DIR = '/home/fsanches/compartilhado/kn5000-roms-disasm'

ROM_BASE = {
    'maincpu': 0xE00000,
    'subcpu': 0x000000,
    'hdae5000': 0x280000,
    'table_data': 0x800000,
}

ELF_FILES = {
    'maincpu': f'{ROM_DIR}/kn5000_v10_program.llvm.elf',
    'subcpu': f'{ROM_DIR}/kn5000_subprogram_v142.llvm.elf',
    'hdae5000': f'{ROM_DIR}/hd-ae5000_v2_06i.llvm.elf',
    'table_data': f'{ROM_DIR}/kn5000_table_data.llvm.elf',
}

ROM_FILES = {
    'maincpu': f'{ROM_DIR}/kn5000_v10_program.llvm.rom',
    'subcpu': f'{ROM_DIR}/kn5000_subprogram_v142.llvm.rom',
    'hdae5000': f'{ROM_DIR}/hd-ae5000_v2_06i.llvm.rom',
    'table_data': f'{ROM_DIR}/kn5000_table_data.llvm.rom',
}

SINGLE_BYTE_PAT = re.compile(rb'^\s*\.byte\s+0x([0-9a-fA-F]{2})\s*$')
LABEL_PAT = re.compile(rb'^([A-Za-z_][A-Za-z0-9_]*)\s*:')
SKIP_DIRECTIVES = re.compile(
    rb'^\s*\.(globl|type|size|text|data|section|include|set|equ|macro|endm|'
    rb'if|else|endif|rept|endr|p2align)\b', re.IGNORECASE)

BYTE_REGS = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l']
WORD_REGS = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp']
LONG_REGS = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp']

# SRI prefix byte -> (base_reg, has_disp, size_class)
SRI_PREFIXES = {}
for i, reg in enumerate(['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp']):
    SRI_PREFIXES[0x80 + i] = (reg, False, 'b')
    SRI_PREFIXES[0x88 + i] = (reg, True, 'b')
    SRI_PREFIXES[0x90 + i] = (reg, False, 'w')
    SRI_PREFIXES[0x98 + i] = (reg, True, 'w')
    SRI_PREFIXES[0xA0 + i] = (reg, False, 'l')
    SRI_PREFIXES[0xA8 + i] = (reg, True, 'l')
    SRI_PREFIXES[0xB0 + i] = (reg, False, 'st_b')
    SRI_PREFIXES[0xB8 + i] = (reg, True, 'st_b')

STANDALONE_INSTS = {
    0x00: 'nop', 0x01: 'normal', 0x04: 'max',
    0x07: 'reti', 0x0E: 'ret', 0xFF: 'swi 7',
}

ALU_OPS_REG_MEM = {
    0x80: ('add', 'rm'), 0x88: ('add', 'mr'),
    0x90: ('adc', 'rm'), 0x98: ('adc', 'mr'),
    0xA0: ('sub', 'rm'), 0xA8: ('sub', 'mr'),
    0xB0: ('sbc', 'rm'), 0xB8: ('sbc', 'mr'),
    0xC0: ('and', 'rm'), 0xC8: ('and', 'mr'),
    0xD0: ('xor', 'rm'), 0xD8: ('xor', 'mr'),
    0xE0: ('or', 'rm'),  0xE8: ('or', 'mr'),
    0xF0: ('cp', 'rm'),  0xF8: ('cp', 'mr'),
}

ALU_MEM_IMM_B = {
    0x38: 'addmi8', 0x39: 'adcmi8', 0x3A: 'submi8', 0x3B: 'sbcmi8',
    0x3C: 'andmi8', 0x3D: 'xormi8', 0x3E: 'ormi8',  0x3F: 'cp',
}

ALU_MEM_IMM_W = {
    0x38: 'addmi16', 0x39: 'adcmi16', 0x3A: 'submi16', 0x3B: 'sbcmi16',
    0x3C: 'andmi16', 0x3D: 'xormi16', 0x3E: 'ormi16',  0x3F: 'cpw',
}

PREVBANK_OPS = {
    0x04: 'push qiz', 0x05: 'pop qiz',
    0x88: 'ld wa, qiz', 0x89: 'ld bc, qiz',
    0x8A: 'ld de, qiz', 0x8B: 'ld hl, qiz',
    0x98: 'ld qiz, wa', 0x99: 'ld qiz, bc',
    0x9A: 'ld qiz, de', 0x9B: 'ld qiz, hl',
}

# Global caches
_ROM_CACHE = {}
_LLVM_CACHE = {}  # instruction_text -> (bytes, mnemonic) or None


def load_symbol_table(elf_path):
    result = subprocess.run([LLVM_NM, '--no-sort', elf_path],
                          capture_output=True, text=True)
    symbols = {}
    for line in result.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 3:
            try:
                symbols[parts[2]] = int(parts[0], 16)
            except ValueError:
                pass
    return symbols


def load_rom(rom_path):
    with open(rom_path, 'rb') as f:
        return f.read()


def get_rom_data(rom_type):
    if rom_type not in _ROM_CACHE:
        _ROM_CACHE[rom_type] = (
            load_symbol_table(ELF_FILES[rom_type]),
            load_rom(ROM_FILES[rom_type]),
            ROM_BASE[rom_type]
        )
    return _ROM_CACHE[rom_type]


def _parse_encoding_line(line):
    """Parse an encoding line from llvm-mc output. Returns (bytes, mnemonic) or None."""
    if 'encoding:' not in line:
        return None
    enc_str = line.split('encoding: [')[1].split(']')[0]
    byte_strs = [s.strip() for s in enc_str.split(',')]
    enc_bytes = []
    for bs in byte_strs:
        if bs.startswith('0x'):
            enc_bytes.append(int(bs, 16))
        else:
            # Has relocations - still record the size
            return (len(byte_strs), line.split(';')[0].strip(), True)
    mnem = line.split(';')[0].strip()
    return (bytes(enc_bytes), mnem, False)


def batch_encode(instructions):
    """
    Encode a list of instructions with llvm-mc.
    Uses chunked batching with deduplication.
    Returns dict mapping instruction text -> (bytes, mnemonic) or None.
    """
    # Deduplicate and filter cached
    to_encode = list(set(inst for inst in instructions if inst not in _LLVM_CACHE))

    if to_encode:
        # Process in chunks to handle errors gracefully
        CHUNK_SIZE = 200
        for chunk_start in range(0, len(to_encode), CHUNK_SIZE):
            chunk = to_encode[chunk_start:chunk_start + CHUNK_SIZE]

            input_text = '\n'.join(chunk)
            result = subprocess.run(
                [LLVM_MC, '--triple=tlcs900', '--show-encoding'],
                input=input_text, capture_output=True, text=True
            )

            enc_lines = [l for l in result.stdout.splitlines() if 'encoding:' in l]

            if len(enc_lines) == len(chunk):
                # Perfect alignment
                for i, line in enumerate(enc_lines):
                    parsed = _parse_encoding_line(line)
                    if parsed:
                        enc_bytes, mnem, has_reloc = parsed
                        if has_reloc:
                            # Record size but mark as having relocation
                            _LLVM_CACHE[chunk[i]] = (b'\x00' * enc_bytes, mnem)
                        else:
                            _LLVM_CACHE[chunk[i]] = (enc_bytes, mnem)
                    else:
                        _LLVM_CACHE[chunk[i]] = None
            else:
                # Misalignment in this chunk only - mark all as size-unknown
                # Don't do individual encoding (too slow for large files)
                for inst in chunk:
                    if inst not in _LLVM_CACHE:
                        _LLVM_CACHE[inst] = None

    return {inst: _LLVM_CACHE.get(inst) for inst in instructions}


def get_line_byte_sizes(lines, source_filepath=None):
    """Compute byte size of each line. Returns dict {line_idx: size}."""
    line_sizes = {}

    # Collect native instruction lines
    native_lines = {}
    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped or stripped.startswith(b'#') or stripped.startswith(b'//') or stripped.startswith(b';'):
            continue
        if LABEL_PAT.match(line):
            continue
        if stripped.startswith(b'.'):
            continue
        native_lines[i] = stripped.decode('latin-1', errors='replace')

    # Batch encode all native instructions
    all_insts = list(native_lines.values())
    all_indices = list(native_lines.keys())

    if all_insts:
        results = batch_encode(all_insts)
        for idx, inst in zip(all_indices, all_insts):
            cached = results.get(inst)
            if cached is not None:
                enc_bytes, mnem = cached
                line_sizes[idx] = len(enc_bytes)

    # Handle directives
    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped:
            continue

        m = re.match(rb'^\s*\.byte\s+(.+?)(\s*#.*)?$', stripped)
        if m:
            vals = m.group(1).split(b',')
            line_sizes[i] = len(vals)
            continue

        if re.match(rb'^\s*\.long\b', stripped):
            content = stripped.split(b'.long', 1)[1]
            vals = content.split(b',')
            line_sizes[i] = 4 * len(vals)
            continue

        m = re.match(rb'^\s*\.(short|word)\b', stripped)
        if m:
            content = stripped.split(m.group(0), 1)[1]
            vals = content.split(b',')
            line_sizes[i] = 2 * len(vals)
            continue

        m = re.match(rb'^\s*\.zero\s+(\d+)', stripped)
        if m:
            line_sizes[i] = int(m.group(1))
            continue

        m = re.match(rb'^\s*\.fill\s+(\d+)', stripped)
        if m:
            line_sizes[i] = int(m.group(1))
            continue

        m = re.match(rb'^\s*\.ascii\s+"(.*)"', stripped)
        if m:
            s = m.group(1)
            try:
                decoded = s.decode('unicode_escape')
                line_sizes[i] = len(decoded.encode('latin-1'))
            except Exception:
                line_sizes[i] = len(s)
            continue

        m = re.match(rb'^\s*\.asciz\s+"(.*)"', stripped)
        if m:
            s = m.group(1)
            try:
                decoded = s.decode('unicode_escape')
                line_sizes[i] = len(decoded.encode('latin-1')) + 1
            except Exception:
                line_sizes[i] = len(s) + 1
            continue

        m = re.match(rb'^\s*\.incbin\s+"([^"]+)"', stripped)
        if m:
            inc_path = m.group(1).decode('latin-1', errors='replace')
            base_dir = os.path.dirname(source_filepath) if source_filepath else REPO_DIR
            for base in [base_dir, REPO_DIR]:
                full_path = os.path.join(base, inc_path)
                if os.path.isfile(full_path):
                    line_sizes[i] = os.path.getsize(full_path)
                    break
            continue

    return line_sizes


def generate_sri_candidates(rom_data, offset, prefix_byte):
    """Generate candidate LLVM instructions for an SRI prefix byte."""
    if prefix_byte not in SRI_PREFIXES:
        return []

    base_reg, has_disp, size_class = SRI_PREFIXES[prefix_byte]
    pos = offset + 1

    if has_disp:
        if pos >= len(rom_data):
            return []
        disp = rom_data[pos]
        if disp >= 128:
            disp = disp - 256
        pos += 1
    else:
        disp = None

    if disp is not None:
        mem_op = f'({base_reg}+{disp})' if disp >= 0 else f'({base_reg}{disp})'
    else:
        mem_op = f'({base_reg})'

    if pos >= len(rom_data):
        return []
    sub_op = rom_data[pos]

    is_store = size_class.startswith('st_')
    actual_size = size_class.replace('st_', '')

    if actual_size == 'b':
        regs = BYTE_REGS
        imm_ops = ALU_MEM_IMM_B
    elif actual_size == 'w':
        regs = WORD_REGS
        imm_ops = ALU_MEM_IMM_W
    elif actual_size == 'l':
        regs = LONG_REGS
        imm_ops = {}
    else:
        return []

    candidates = []

    # LD reg, (mem): sub_op 0x20-0x27
    if 0x20 <= sub_op <= 0x27 and not is_store:
        reg_idx = sub_op - 0x20
        if reg_idx < len(regs):
            candidates.append(f'ld {regs[reg_idx]}, {mem_op}')

    # LD (mem), reg: sub_op 0x40-0x47 (store prefix)
    if 0x40 <= sub_op <= 0x47 and is_store:
        reg_idx = sub_op - 0x40
        if reg_idx < len(regs):
            candidates.append(f'ld {mem_op}, {regs[reg_idx]}')

    # LD (mem), reg16/reg32: sub_op 0x50-0x57 / 0x60-0x67
    if is_store and 0x50 <= sub_op <= 0x57:
        reg_idx = sub_op - 0x50
        if reg_idx < len(regs):
            candidates.append(f'ld {mem_op}, {regs[reg_idx]}')
    if is_store and 0x60 <= sub_op <= 0x67:
        reg_idx = sub_op - 0x60
        if reg_idx < len(regs):
            candidates.append(f'ld {mem_op}, {regs[reg_idx]}')

    # LD (mem), imm: sub_op 0x00 (byte), 0x02 (word)
    if is_store and sub_op == 0x00 and pos + 1 < len(rom_data):
        imm = rom_data[pos + 1]
        candidates.append(f'ld {mem_op}, {imm}')
    if is_store and sub_op == 0x02 and pos + 2 < len(rom_data):
        imm = rom_data[pos + 1] | (rom_data[pos + 2] << 8)
        candidates.append(f'ldw {mem_op}, {imm}')

    # ALU reg, (mem) or (mem), reg: sub_op >= 0x80
    if sub_op >= 0x80:
        base_op = sub_op & 0xF8
        reg_idx = sub_op & 0x07
        if base_op in ALU_OPS_REG_MEM and reg_idx < len(regs):
            opcode, direction = ALU_OPS_REG_MEM[base_op]
            reg = regs[reg_idx]
            if direction == 'rm':
                candidates.append(f'{opcode} {reg}, {mem_op}')
            else:
                candidates.append(f'{opcode} {mem_op}, {reg}')

    # ALU (mem), imm: sub_op 0x38-0x3F
    if sub_op in imm_ops and not is_store:
        mnemonic = imm_ops[sub_op]
        if actual_size == 'b' and pos + 1 < len(rom_data):
            imm = rom_data[pos + 1]
            candidates.append(f'{mnemonic} {mem_op}, {imm}')
        elif actual_size == 'w' and pos + 2 < len(rom_data):
            imm = rom_data[pos + 1] | (rom_data[pos + 2] << 8)
            candidates.append(f'{mnemonic} {mem_op}, {imm}')

    return candidates


def generate_prevbank_candidates(rom_data, offset):
    """Generate candidate LLVM instructions for prevbank (0xD7) prefix."""
    if offset + 2 >= len(rom_data):
        return []

    byte2 = rom_data[offset + 1]
    if byte2 != 0xFA:
        return []

    byte3 = rom_data[offset + 2]
    if byte3 in PREVBANK_OPS:
        return [PREVBANK_OPS[byte3]]

    # cp qiz, imm
    if byte3 == 0xD8 and offset + 3 < len(rom_data):
        imm = rom_data[offset + 3]
        return [f'cp qiz, {imm}']

    return []


def generate_standalone_candidates(byte_val):
    """Generate candidates for standalone single-byte instructions."""
    if byte_val in STANDALONE_INSTS:
        return [STANDALONE_INSTS[byte_val]]
    return []


def generate_all_candidates(rom_data, offset):
    """Generate all possible LLVM candidates for the byte sequence at offset."""
    byte_val = rom_data[offset]
    candidates = []

    # 1. Standalone
    candidates.extend(generate_standalone_candidates(byte_val))

    # 2. Prevbank
    if byte_val == 0xD7:
        candidates.extend(generate_prevbank_candidates(rom_data, offset))

    # 3. SRI prefix
    if byte_val in SRI_PREFIXES:
        candidates.extend(generate_sri_candidates(rom_data, offset, byte_val))

    return candidates


def process_file(filepath, rom_type='maincpu', dry_run=True):
    """Process a single .s file to merge single-byte .byte fragments."""

    symbols, rom_data, base_addr = get_rom_data(rom_type)

    with open(filepath, 'rb') as f:
        lines = f.readlines()

    # Phase 1: Build label->address map
    label_addrs = {}
    for i, line in enumerate(lines):
        m = LABEL_PAT.match(line)
        if m:
            name = m.group(1).decode('latin-1', errors='replace')
            if name in symbols:
                label_addrs[i] = symbols[name]

    sorted_labels = sorted(label_addrs.items(), key=lambda x: x[0])

    # Phase 2: Get byte sizes for all lines
    line_sizes = get_line_byte_sizes(lines, filepath)

    # Phase 3: Find all single .byte lines and compute ROM offsets
    byte_line_info = []  # (line_idx, byte_val, rom_offset)
    offset_fail = 0

    for i, line in enumerate(lines):
        m = SINGLE_BYTE_PAT.match(line)
        if not m:
            continue

        byte_val = int(m.group(1), 16)

        # Find nearest preceding label
        best_label_line = None
        best_label_addr = None
        for label_line, label_addr in sorted_labels:
            if label_line <= i:
                best_label_line = label_line
                best_label_addr = label_addr
            else:
                break

        if best_label_addr is None:
            offset_fail += 1
            continue

        # Accumulate byte offset from label
        byte_offset = 0
        valid = True
        for j in range(best_label_line + 1, i):
            if j in line_sizes and line_sizes[j] is not None:
                byte_offset += line_sizes[j]
            else:
                stripped = lines[j].strip()
                if not stripped or stripped.startswith(b'#') or stripped.startswith(b'//') or stripped.startswith(b';'):
                    continue
                if LABEL_PAT.match(lines[j]):
                    continue
                if SKIP_DIRECTIVES.match(stripped):
                    continue
                valid = False
                break

        if not valid:
            offset_fail += 1
            continue

        rom_offset = (best_label_addr - base_addr) + byte_offset
        if rom_offset < 0 or rom_offset >= len(rom_data):
            offset_fail += 1
            continue

        if rom_data[rom_offset] != byte_val:
            offset_fail += 1
            continue

        byte_line_info.append((i, byte_val, rom_offset))

    # Phase 4: Generate all candidates and batch-verify
    all_candidates = []  # (byte_line_idx, candidate_text)
    candidate_map = {}  # byte_line_idx -> [candidate_texts]

    for idx, (line_idx, byte_val, rom_offset) in enumerate(byte_line_info):
        candidates = generate_all_candidates(rom_data, rom_offset)
        candidate_map[idx] = candidates
        for c in candidates:
            all_candidates.append(c)

    # Batch encode all unique candidates
    unique_candidates = list(set(all_candidates))
    if unique_candidates:
        batch_encode(unique_candidates)  # Fills _LLVM_CACHE

    # Phase 5: Match encodings against ROM bytes
    replacements = {}
    failed_count = 0

    for idx, (line_idx, byte_val, rom_offset) in enumerate(byte_line_info):
        candidates = candidate_map[idx]
        matched = None

        for candidate in candidates:
            cached = _LLVM_CACHE.get(candidate)
            if cached is None:
                continue
            enc_bytes, llvm_mnem = cached
            rom_slice = rom_data[rom_offset:rom_offset + len(enc_bytes)]
            if enc_bytes == rom_slice:
                matched = (llvm_mnem, len(enc_bytes))
                break

        if matched is None:
            # Try unidasm fallback
            matched = unidasm_fallback(rom_data, rom_offset)

        if matched is None:
            failed_count += 1
            continue

        llvm_inst, inst_size = matched

        # Determine how many source lines this consumes
        consumed_size = 1
        consumed_lines = [line_idx]

        j = line_idx + 1
        while consumed_size < inst_size and j < len(lines):
            stripped = lines[j].strip()
            if not stripped or stripped.startswith(b'#') or stripped.startswith(b'//') or stripped.startswith(b';'):
                j += 1
                continue
            if LABEL_PAT.match(lines[j]):
                break
            if j in line_sizes and line_sizes[j] is not None:
                consumed_size += line_sizes[j]
                consumed_lines.append(j)
                j += 1
            else:
                break

        if consumed_size != inst_size:
            failed_count += 1
            continue

        # Check no conflicts
        conflict = any(cl in replacements for cl in consumed_lines)
        if conflict:
            continue

        new_line = b'\t' + llvm_inst.encode('latin-1') + b'\n'
        replacements[consumed_lines[0]] = (new_line, consumed_lines[1:])

    # Phase 6: Apply replacements
    skip_lines = set()
    for line_idx, (new_line, extra_lines) in replacements.items():
        for el in extra_lines:
            skip_lines.add(el)

    new_lines = []
    for i, line in enumerate(lines):
        if i in skip_lines:
            continue
        if i in replacements:
            new_line, _ = replacements[i]
            new_lines.append(new_line)
        else:
            new_lines.append(line)

    total_byte_lines = len(byte_line_info) + offset_fail
    print(f"  {os.path.basename(filepath)}: "
          f"{total_byte_lines} single .byte, "
          f"{len(byte_line_info)} verified, "
          f"{len(replacements)} merged, "
          f"{failed_count} unsupported, "
          f"{offset_fail} offset-unresolved")

    if replacements and not dry_run:
        with open(filepath, 'wb') as f:
            f.writelines(new_lines)

    return len(replacements)


def unidasm_fallback(rom_data, offset):
    """Use unidasm to decode, then try to verify with LLVM."""
    end = min(offset + 8, len(rom_data))
    chunk = rom_data[offset:end]
    if not chunk:
        return None

    with tempfile.NamedTemporaryFile(suffix='.bin', delete=False) as f:
        f.write(chunk)
        fname = f.name

    try:
        result = subprocess.run(
            [UNIDASM, fname, '-arch', 'tlcs900', '-count', '1'],
            capture_output=True, text=True
        )
        line = result.stdout.strip()
        if not line:
            return None

        parts = line.split(': ', 1)
        if len(parts) < 2:
            return None

        hex_and_inst = parts[1]
        match = re.match(r'((?:[0-9a-f]{2}\s*)+)\s{2,}(.+)', hex_and_inst)
        if not match:
            return None

        hex_str = match.group(1).strip()
        mnemonic = match.group(2).strip()
        raw_bytes = bytes.fromhex(hex_str.replace(' ', ''))

        if 'db' in mnemonic.lower():
            return None

        # Try to convert unidasm mnemonic to LLVM
        candidates = generate_llvm_from_unidasm(mnemonic)

        # Batch encode candidates
        if candidates:
            batch_encode(candidates)
            for candidate in candidates:
                cached = _LLVM_CACHE.get(candidate)
                if cached is not None:
                    enc_bytes, llvm_mnem = cached
                    if enc_bytes == raw_bytes:
                        return (llvm_mnem, len(raw_bytes))
    finally:
        os.unlink(fname)

    return None


UNIDASM_REG_MAP = {
    'W': 'w', 'A': 'a', 'B': 'b', 'C': 'c',
    'D': 'd', 'E': 'e', 'H': 'h', 'L': 'l',
    'WA': 'wa', 'BC': 'bc', 'DE': 'de', 'HL': 'hl',
    'IX': 'ix', 'IY': 'iy', 'IZ': 'iz', 'SP': 'sp',
    'XWA': 'xwa', 'XBC': 'xbc', 'XDE': 'xde', 'XHL': 'xhl',
    'XIX': 'xix', 'XIY': 'xiy', 'XIZ': 'xiz', 'XSP': 'xsp',
    'QWA': 'qwa', 'QBC': 'qbc', 'QDE': 'qde', 'QHL': 'qhl',
    'QIX': 'qix', 'QIY': 'qiy', 'QIZ': 'qiz',
    'SR': 'sr', 'F': 'f',
}


def convert_operand(op_str):
    """Convert a unidasm operand to LLVM syntax."""
    op = op_str.strip()
    up = op.upper()

    if up in UNIDASM_REG_MAP:
        return UNIDASM_REG_MAP[up]

    m = re.match(r'\(([A-Z]+)\+0x([0-9A-Fa-f]+)\)', op)
    if m:
        reg = UNIDASM_REG_MAP.get(m.group(1), m.group(1).lower())
        return f'({reg}+{int(m.group(2), 16)})'

    m = re.match(r'\(([A-Z]+)-0x([0-9A-Fa-f]+)\)', op)
    if m:
        reg = UNIDASM_REG_MAP.get(m.group(1), m.group(1).lower())
        return f'({reg}-{int(m.group(2), 16)})'

    m = re.match(r'\(([A-Z]+)\)', op)
    if m:
        return f'({UNIDASM_REG_MAP.get(m.group(1), m.group(1).lower())})'

    m = re.match(r'0x([0-9A-Fa-f]+)', op)
    if m:
        return str(int(m.group(1), 16))

    if op.lstrip('-').isdigit():
        return op

    return op.lower()


def generate_llvm_from_unidasm(unidasm_mnem):
    """Generate candidate LLVM instructions from unidasm mnemonic."""
    mnem = unidasm_mnem.strip()

    standalone = {
        'nop': 'nop', 'normal': 'normal', 'max': 'max',
        'pop SR': 'pop_sr', 'push SR': 'push_sr',
        'reti': 'reti', 'ret': 'ret', 'decf': 'decf', 'incf': 'incf',
        'ldd': 'ldd', 'lddr': 'lddr', 'ldi': 'ldi', 'ldir': 'ldir',
    }
    if mnem in standalone:
        return [standalone[mnem]]

    parts = mnem.split(None, 1)
    if not parts:
        return []

    opcode = parts[0].lower()
    operands_str = parts[1] if len(parts) > 1 else ''

    operands = []
    if operands_str:
        depth = 0
        current = ''
        for ch in operands_str:
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            elif ch == ',' and depth == 0:
                operands.append(current.strip())
                current = ''
                continue
            current += ch
        if current.strip():
            operands.append(current.strip())

    llvm_ops = [convert_operand(op) for op in operands]
    candidates = []

    if opcode in ('push', 'pop') and len(llvm_ops) == 1:
        candidates.extend([f'{opcode} {llvm_ops[0]}', f'{opcode}w {llvm_ops[0]}'])
    elif opcode == 'ld' and len(llvm_ops) == 2:
        candidates.extend([f'ld {llvm_ops[0]}, {llvm_ops[1]}',
                          f'ldw {llvm_ops[0]}, {llvm_ops[1]}',
                          f'ldb {llvm_ops[0]}, {llvm_ops[1]}'])
    elif opcode == 'cp' and len(llvm_ops) == 2:
        candidates.extend([f'cp {llvm_ops[0]}, {llvm_ops[1]}',
                          f'cpw {llvm_ops[0]}, {llvm_ops[1]}'])
    elif opcode in ('add', 'sub', 'adc', 'sbc', 'and', 'or', 'xor'):
        if len(llvm_ops) == 2:
            candidates.extend([f'{opcode} {llvm_ops[0]}, {llvm_ops[1]}',
                              f'{opcode}w {llvm_ops[0]}, {llvm_ops[1]}',
                              f'{opcode}mi8 {llvm_ops[0]}, {llvm_ops[1]}',
                              f'{opcode}mi16 {llvm_ops[0]}, {llvm_ops[1]}'])
    elif opcode in ('extz', 'exts') and len(llvm_ops) == 1:
        candidates.append(f'{opcode} {llvm_ops[0]}')
    elif opcode == 'lda' and len(llvm_ops) == 2:
        candidates.append(f'lda {llvm_ops[0]}, {llvm_ops[1]}')
    elif opcode == 'swi' and len(llvm_ops) == 1:
        candidates.append(f'swi {llvm_ops[0]}')
    else:
        generic = opcode
        if llvm_ops:
            generic += ' ' + ', '.join(llvm_ops)
        candidates.append(generic)

    return candidates


def find_s_files(directory):
    s_files = []
    for root, dirs, files in os.walk(directory):
        for f in files:
            if f.endswith('.s'):
                s_files.append(os.path.join(root, f))
    return sorted(s_files)


def main():
    dry_run = True
    target_files = []
    target_dir = None

    for arg in sys.argv[1:]:
        if arg == '--dry-run':
            dry_run = True
        elif arg == '--apply':
            dry_run = False
        elif os.path.isfile(arg):
            target_files.append(arg)
        elif os.path.isdir(arg):
            target_dir = arg

    mode = "DRY RUN" if dry_run else "APPLY"
    print(f"Mode: {mode}")
    print()

    if target_files:
        total = 0
        for tf in target_files:
            rom_type = 'maincpu'
            if 'subcpu' in tf:
                rom_type = 'subcpu'
            elif 'hdae5000' in tf:
                rom_type = 'hdae5000'
            elif 'table_data' in tf:
                rom_type = 'table_data'
            count = process_file(tf, rom_type, dry_run)
            total += count
        print(f"\nTotal: {total} replacements")
    else:
        directory = target_dir or os.path.join(REPO_DIR, 'maincpu')
        s_files = find_s_files(directory)

        total = 0
        for f in s_files:
            rom_type = 'maincpu'
            if 'subcpu' in f:
                rom_type = 'subcpu'
            elif 'hdae5000' in f:
                rom_type = 'hdae5000'
            elif 'table_data' in f:
                rom_type = 'table_data'
            count = process_file(f, rom_type, dry_run)
            total += count

        print(f"\nTotal: {total} replacements across all files")


if __name__ == '__main__':
    main()
