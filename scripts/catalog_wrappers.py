#!/usr/bin/env python3
"""Catalog all raw encoding wrapper instances in the LLVM .s files.

For each instance, reconstructs the full byte sequence, decodes with unidasm,
and produces a mapping of (wrapper_mnemonic, sub_opcode, trailing_pattern) →
semantic instruction info.

Output: A structured report for defining LLVM TableGen instructions.
"""

import os
import re
import subprocess
import sys
import tempfile
from collections import defaultdict, Counter

# Project paths
ROMS_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S_DIRS = [
    os.path.join(ROMS_DIR, 'maincpu'),
    os.path.join(ROMS_DIR, 'hdae5000'),
    os.path.join(ROMS_DIR, 'subcpu_payload'),
    os.path.join(ROMS_DIR, 'subcpu_boot'),
    os.path.join(ROMS_DIR, 'table_data'),
]
UNIDASM = '/mnt/shared/tools/unidasm'

# Raw wrapper mnemonic pattern: category + size + digit(s)
# e.g., erpb3, erpw4, srib4, dri4, dd82, sd8b2, sd16b3, sd24b3, spib3, etc.
RAW_WRAPPER_RE = re.compile(
    r'^\s+(erp[bwl]\d|sri[bwl]\d|spi[bwl]\d|spd[bwl]\d|'
    r'sd8[bwl]\d|sd16[bwl]\d|sd24[bwl]\d|'
    r'dd8\d|dd16\d|dd24\d|dri\d|dpi\d|dpd\d)\s+(.+?)(?:\s*//.*)?$',
    re.MULTILINE
)

# Prefix computation from category and size
# Source modes (Opcode < 0xF0): prefix = base_opcode + size_offset
# Dest modes (Opcode >= 0xF0): prefix = base_opcode (no size offset)
CATEGORY_INFO = {
    # (base_opcode, is_source) — source modes add size*0x10
    'sd8':  (0xC0, True),
    'sd16': (0xC1, True),
    'sd24': (0xC2, True),
    'sri':  (0xC3, True),
    'spd':  (0xC4, True),
    'spi':  (0xC5, True),
    'erp':  (0xC7, True),
    'dd8':  (0xF0, False),
    'dd16': (0xF1, False),
    'dd24': (0xF2, False),
    'dri':  (0xF3, False),
    'dpd':  (0xF4, False),
    'dpi':  (0xF5, False),
}

SIZE_OFFSET = {'b': 0, 'w': 1, 'l': 2}


def parse_operands(operand_str):
    """Parse comma-separated hex operands like '0xFB, 0xCF, 0x14' into list of ints."""
    # Strip any trailing comment (// or ; or tab-separated comment)
    operand_str = re.split(r'\s*(?://|;|\t)', operand_str)[0].strip()
    parts = operand_str.split(',')
    result = []
    for p in parts:
        p = p.strip()
        if not p:
            continue
        # Strip inline comment markers
        p = re.split(r'\s*(?://|;)', p)[0].strip()
        if not p:
            continue
        if p.startswith('0x') or p.startswith('0X'):
            result.append(int(p, 16))
        elif p.isdigit() or (p.startswith('-') and p[1:].isdigit()):
            result.append(int(p))
        else:
            try:
                result.append(int(p))
            except ValueError:
                result.append(0)
    return result


def parse_mnemonic(mnemonic):
    """Parse raw wrapper mnemonic into (category, size_char, num_operands).

    Returns (category, size_char_or_None, num_operands).
    Dest modes (dd8, dri, dpi, etc.) have no size char.
    """
    # Source modes with size char: erp[bwl]N, sri[bwl]N, spi[bwl]N, spd[bwl]N,
    #                               sd8[bwl]N, sd16[bwl]N, sd24[bwl]N
    m = re.match(r'^(erp|sri|spi|spd|sd8|sd16|sd24)([bwl])(\d+)$', mnemonic)
    if m:
        return m.group(1), m.group(2), int(m.group(3))

    # Dest modes without size char: dd8N, dd16N, dd24N, driN, dpiN, dpdN
    m = re.match(r'^(dd8|dd16|dd24|dri|dpi|dpd)(\d+)$', mnemonic)
    if m:
        return m.group(1), None, int(m.group(2))

    return None, None, 0


def compute_prefix(category, size_char):
    """Compute the prefix byte from category and size."""
    base, is_source = CATEGORY_INFO[category]
    if is_source and size_char:
        return base + SIZE_OFFSET[size_char] * 0x10
    return base


def decode_bytes(byte_seq):
    """Run unidasm on a byte sequence and return the disassembly string."""
    with tempfile.NamedTemporaryFile(suffix='.bin', delete=False) as f:
        f.write(bytes(byte_seq))
        tmp_path = f.name
    try:
        result = subprocess.run(
            [UNIDASM, tmp_path, '-arch', 'tlcs900'],
            capture_output=True, text=True, timeout=5
        )
        # Parse output: "0: c7 fb cf 14  cp QIZH,0x14"
        for line in result.stdout.strip().split('\n'):
            line = line.strip()
            if line and line[0].isdigit():
                # Find the instruction part after the hex bytes
                # Format: "addr: hex_bytes  mnemonic operands"
                parts = line.split('  ', 1)
                if len(parts) >= 2:
                    return parts[-1].strip()
        return result.stdout.strip()
    except Exception as e:
        return f"ERROR: {e}"
    finally:
        os.unlink(tmp_path)


def collect_all_wrappers():
    """Scan all .s files and collect raw wrapper instances."""
    instances = []
    for s_dir in S_DIRS:
        if not os.path.isdir(s_dir):
            continue
        rom_name = os.path.basename(s_dir)
        for fname in sorted(os.listdir(s_dir)):
            if not fname.endswith('.s'):
                continue
            fpath = os.path.join(s_dir, fname)
            with open(fpath, 'r') as f:
                content = f.read()
            for m in RAW_WRAPPER_RE.finditer(content):
                mnemonic = m.group(1)
                operands_str = m.group(2).strip()
                instances.append({
                    'rom': rom_name,
                    'file': fname,
                    'mnemonic': mnemonic,
                    'operands_str': operands_str,
                })
    return instances


def analyze_instance(inst):
    """Analyze a single wrapper instance: compute bytes, decode, classify."""
    mnemonic = inst['mnemonic']
    category, size_char, num_ops = parse_mnemonic(mnemonic)
    if category is None:
        return None

    operands = parse_operands(inst['operands_str'])
    prefix = compute_prefix(category, size_char)

    # Full byte sequence: [prefix, operand_bytes...]
    full_bytes = [prefix] + operands

    # Decode with unidasm
    decoded = decode_bytes(full_bytes)

    return {
        'category': category,
        'size_char': size_char,
        'num_ops': num_ops,
        'prefix': prefix,
        'operands': operands,
        'full_bytes': full_bytes,
        'decoded': decoded,
        'mnemonic': mnemonic,
    }


def classify_sub_opcode(analysis):
    """Determine sub-opcode position and value for an analyzed instruction.

    Returns (sub_opc, position, num_pre, num_post) or None.
    position: 'end' if sub-opcode is the last operand byte,
              'middle' if it's between addressing bytes and immediate bytes.
    """
    category = analysis['category']
    operands = analysis['operands']
    decoded = analysis['decoded']
    size_char = analysis['size_char']

    if not operands:
        return None

    # For extended register prefix (erp), the pattern is:
    #   [prefix, reg_byte, sub_opcode, ...trailing_imm...]
    # reg_byte is always first operand (even index, register encoding)
    # sub_opcode is second operand
    if category == 'erp':
        if len(operands) >= 2:
            sub_opc = operands[1]
            num_pre = 1  # reg_byte before sub-opcode
            num_post = len(operands) - 2  # trailing immediates after sub-opcode
            if num_post == 0:
                return (sub_opc, 'end', num_pre, num_post)
            else:
                return (sub_opc, 'middle', num_pre, num_post)

    # For register-indirect (sri/dri), the pattern depends on addressing sub-mode:
    #   [prefix, addr_mode_byte, ...addr_bytes..., sub_opcode, ...trailing...]
    if category in ('sri', 'dri'):
        if len(operands) >= 1:
            addr_mode = operands[0]
            mode_type = addr_mode & 0x03
            if mode_type == 0:
                # (r32) — 1 addr byte, rest is sub-opcode + trailing
                if len(operands) >= 2:
                    sub_opc = operands[1]
                    num_pre = 1
                    num_post = len(operands) - 2
                    pos = 'middle' if num_post > 0 else 'end'
                    return (sub_opc, pos, num_pre, num_post)
            elif mode_type == 1:
                # (r32+d16) — 3 addr bytes (mode + d16), rest is sub-opcode + trailing
                if len(operands) >= 4:
                    sub_opc = operands[3]
                    num_pre = 3
                    num_post = len(operands) - 4
                    pos = 'middle' if num_post > 0 else 'end'
                    return (sub_opc, pos, num_pre, num_post)
            elif mode_type == 3:
                # Complex: (r32+r8), (r32+r16), (-r32), (r32+), (PC+d16)
                sub_type = (addr_mode >> 2) & 0x03
                if sub_type == 0:
                    # (r32+r8) — 2 addr bytes
                    if len(operands) >= 3:
                        sub_opc = operands[2]
                        num_pre = 2
                        num_post = len(operands) - 3
                        pos = 'middle' if num_post > 0 else 'end'
                        return (sub_opc, pos, num_pre, num_post)
                elif sub_type == 1:
                    # (r32+r16) — 2 addr bytes
                    if len(operands) >= 3:
                        sub_opc = operands[2]
                        num_pre = 2
                        num_post = len(operands) - 3
                        pos = 'middle' if num_post > 0 else 'end'
                        return (sub_opc, pos, num_pre, num_post)
                elif sub_type == 2:
                    # (-r32) or (r32+) — 1 addr byte
                    if len(operands) >= 2:
                        sub_opc = operands[1]
                        num_pre = 1
                        num_post = len(operands) - 2
                        pos = 'middle' if num_post > 0 else 'end'
                        return (sub_opc, pos, num_pre, num_post)
                elif sub_type == 3:
                    # (PC+d16) — 3 addr bytes (mode + d16)
                    if len(operands) >= 4:
                        sub_opc = operands[3]
                        num_pre = 3
                        num_post = len(operands) - 4
                        pos = 'middle' if num_post > 0 else 'end'
                        return (sub_opc, pos, num_pre, num_post)

    # For post-increment (spi/dpi), the pattern is:
    #   [prefix, reg_byte, sub_opcode, ...trailing...]
    if category in ('spi', 'dpi', 'spd', 'dpd'):
        if len(operands) >= 2:
            sub_opc = operands[1]
            num_pre = 1
            num_post = len(operands) - 2
            pos = 'middle' if num_post > 0 else 'end'
            return (sub_opc, pos, num_pre, num_post)

    # For direct addressing (sd8/dd8, sd16/dd16, sd24/dd24):
    # sd8: [prefix, addr8, sub_opcode, ...trailing...]
    # sd16: [prefix, addr16_lo, addr16_hi, sub_opcode, ...trailing...]
    # sd24: [prefix, addr24_lo, addr24_mid, addr24_hi, sub_opcode, ...trailing...]
    if category in ('sd8', 'dd8'):
        if len(operands) >= 2:
            sub_opc = operands[1]
            num_pre = 1
            num_post = len(operands) - 2
            pos = 'middle' if num_post > 0 else 'end'
            return (sub_opc, pos, num_pre, num_post)

    if category in ('sd16', 'dd16'):
        if len(operands) >= 3:
            sub_opc = operands[2]
            num_pre = 2
            num_post = len(operands) - 3
            pos = 'middle' if num_post > 0 else 'end'
            return (sub_opc, pos, num_pre, num_post)

    if category in ('sd24', 'dd24'):
        if len(operands) >= 4:
            sub_opc = operands[3]
            num_pre = 3
            num_post = len(operands) - 4
            pos = 'middle' if num_post > 0 else 'end'
            return (sub_opc, pos, num_pre, num_post)

    return None


def main():
    print("Collecting all raw wrapper instances...")
    instances = collect_all_wrappers()
    print(f"Found {len(instances)} instances")

    # Count by mnemonic
    mnem_counts = Counter(i['mnemonic'] for i in instances)
    print("\nInstances by mnemonic:")
    for mnem, count in sorted(mnem_counts.items(), key=lambda x: -x[1]):
        print(f"  {mnem:12s} {count:5d}")

    # Analyze and decode each unique pattern
    # Group by (mnemonic, operand_count, sub_opcode) to find unique patterns
    print("\nDecoding unique patterns (this may take a moment)...")

    # First, group instances to find unique byte patterns
    pattern_groups = defaultdict(list)
    for inst in instances:
        mnemonic = inst['mnemonic']
        operands = parse_operands(inst['operands_str'])
        category, size_char, num_ops = parse_mnemonic(mnemonic)

        # Create a pattern key: category, size, num_ops, and sub-opcode position
        # For erp: (category, size, sub_opc=operands[1])
        # For sri/dri: (category, size, addr_mode_type, sub_opc)
        # For others: (category, size, sub_opc)
        if category == 'erp' and len(operands) >= 2:
            key = (mnemonic, operands[1], len(operands) - 2)  # sub_opc, trail_count
        elif category in ('sri', 'dri') and len(operands) >= 1:
            addr_mode = operands[0] & 0x03
            if addr_mode == 0 and len(operands) >= 2:
                key = (mnemonic, 'r32', operands[1], len(operands) - 2)
            elif addr_mode == 1 and len(operands) >= 4:
                key = (mnemonic, 'r32+d16', operands[3], len(operands) - 4)
            elif addr_mode == 3 and len(operands) >= 2:
                sub_type = (operands[0] >> 2) & 0x03
                if sub_type <= 1 and len(operands) >= 3:
                    key = (mnemonic, f'r32+r{"8" if sub_type==0 else "16"}',
                           operands[2], len(operands) - 3)
                elif sub_type == 2 and len(operands) >= 2:
                    key = (mnemonic, 'r32+-', operands[1], len(operands) - 2)
                else:
                    key = (mnemonic, tuple(operands))
            else:
                key = (mnemonic, tuple(operands))
        elif category in ('spi', 'dpi', 'spd', 'dpd') and len(operands) >= 2:
            key = (mnemonic, operands[1], len(operands) - 2)
        elif category in ('sd8', 'dd8') and len(operands) >= 2:
            key = (mnemonic, operands[1], len(operands) - 2)
        elif category in ('sd16', 'dd16') and len(operands) >= 3:
            key = (mnemonic, operands[2], len(operands) - 3)
        elif category in ('sd24', 'dd24') and len(operands) >= 4:
            key = (mnemonic, operands[3], len(operands) - 4)
        else:
            key = (mnemonic, tuple(operands))

        pattern_groups[key].append(inst)

    print(f"Found {len(pattern_groups)} unique patterns")

    # Now decode one representative from each pattern
    results = []
    for key, group in sorted(pattern_groups.items(), key=lambda x: (-len(x[1]), x[0])):
        inst = group[0]  # Representative
        analysis = analyze_instance(inst)
        if analysis is None:
            continue

        sub_info = classify_sub_opcode(analysis)

        results.append({
            'key': key,
            'count': len(group),
            'analysis': analysis,
            'sub_info': sub_info,
            'example_operands': inst['operands_str'],
        })

    # Print detailed report
    print("\n" + "="*100)
    print("DETAILED PATTERN CATALOG")
    print("="*100)

    # Group by category for organized output
    by_category = defaultdict(list)
    for r in results:
        by_category[r['analysis']['category']].append(r)

    total_suffix = 0
    total_opimm = 0

    for cat in ['erp', 'sri', 'spi', 'spd', 'sd8', 'sd16', 'sd24',
                'dri', 'dpi', 'dpd', 'dd8', 'dd16', 'dd24']:
        if cat not in by_category:
            continue
        entries = by_category[cat]
        cat_count = sum(e['count'] for e in entries)
        print(f"\n--- {cat.upper()} ({cat_count} instances, {len(entries)} patterns) ---")

        for r in sorted(entries, key=lambda x: -x['count']):
            a = r['analysis']
            si = r['sub_info']
            hex_bytes = ' '.join(f'{b:02X}' for b in a['full_bytes'])

            if si:
                sub_opc, pos, num_pre, num_post = si
                pos_str = f"sub=0x{sub_opc:02X} pos={pos} pre={num_pre} post={num_post}"
                if pos == 'end':
                    total_suffix += 1
                else:
                    total_opimm += 1
            else:
                pos_str = "UNKNOWN"

            print(f"  {a['mnemonic']:10s} [{hex_bytes:30s}] → {a['decoded']:35s}  "
                  f"({r['count']:4d}x) {pos_str}")

    # Summary for TableGen definition planning
    print("\n" + "="*100)
    print("SUMMARY FOR TABLEGEN DEFINITIONS")
    print("="*100)
    print(f"\nTotal patterns: {len(results)}")
    print(f"  Suffix (sub-opcode at end):    {total_suffix}")
    print(f"  OpImm (sub-opcode in middle):  {total_opimm}")
    print(f"  Total instances:               {sum(r['count'] for r in results)}")

    # Print the suffix-at-end patterns (use ExtAddrModeSuffixInst)
    print("\n--- SUFFIX PATTERNS (use ExtAddrModeSuffixInst) ---")
    for r in sorted(results, key=lambda x: (x['analysis']['category'],
                                             x['sub_info'][0] if x['sub_info'] else 999)):
        si = r['sub_info']
        if si and si[1] == 'end':
            a = r['analysis']
            sub_opc = si[0]
            print(f"  {a['category']:6s} {a['size_char'] or '-':1s} "
                  f"sub=0x{sub_opc:02X} nops={a['num_ops']} "
                  f"→ {a['decoded']:35s} ({r['count']:4d}x)")

    # Print the opimm patterns (need new ExtAddrModeOpImmInst)
    print("\n--- OPIMM PATTERNS (need ExtAddrModeOpImmInst) ---")
    for r in sorted(results, key=lambda x: (x['analysis']['category'],
                                             x['sub_info'][0] if x['sub_info'] else 999)):
        si = r['sub_info']
        if si and si[1] == 'middle':
            a = r['analysis']
            sub_opc, _, num_pre, num_post = si
            print(f"  {a['category']:6s} {a['size_char'] or '-':1s} "
                  f"sub=0x{sub_opc:02X} pre={num_pre} post={num_post} "
                  f"nops={a['num_ops']} "
                  f"→ {a['decoded']:35s} ({r['count']:4d}x)")

    # Generate proposed mnemonic names
    print("\n" + "="*100)
    print("PROPOSED MNEMONIC NAMES")
    print("="*100)

    for r in sorted(results, key=lambda x: (x['analysis']['category'],
                                             x['sub_info'][0] if x['sub_info'] else 999)):
        si = r['sub_info']
        if not si:
            continue
        a = r['analysis']
        sub_opc = si[0]
        decoded = a['decoded']
        cat = a['category']
        sc = a['size_char'] or ''

        # Extract the operation from decoded disassembly
        op_parts = decoded.split()
        if op_parts:
            base_op = op_parts[0].lower()
        else:
            base_op = 'unknown'

        # Generate mnemonic: operation_detail_category
        # e.g., cp_imm_berp, ld_a_dri3, set_dd8
        suffix = f"{'b' if sc == 'b' else 'w' if sc == 'w' else 'l' if sc == 'l' else ''}{cat}"
        nops = a['num_ops']
        proposed = f"{base_op}_{suffix}{nops}" if nops > 0 else f"{base_op}_{suffix}"

        print(f"  0x{sub_opc:02X} {cat:6s}{sc:1s} {nops}ops "
              f"→ proposed: {proposed:30s} decoded: {decoded}")


if __name__ == '__main__':
    main()
