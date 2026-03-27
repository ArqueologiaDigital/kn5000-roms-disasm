#!/usr/bin/env python3
"""Replace v7 .byte transplants with v9 source code, patching operands that differ.

For each transplanted label:
1. Get the v9 source code (instructions)
2. Get the v7 ground truth bytes (from transplant bin)
3. Assemble the v9 source standalone → get v9 bytes
4. Compare byte-by-byte with v7 ground truth
5. If identical: use v9 source as-is
6. If differs only in known operand positions: patch operands
7. If too complex: keep .byte fallback

Uses binary I/O for Latin-1 safe editing.
"""

import subprocess, os, glob, re, json, sys, tempfile

LLVM_MC = '/mnt/shared/llvm-project/build/bin/llvm-mc'
LLVM_OBJCOPY = '/mnt/shared/llvm-project/build/bin/llvm-objcopy'
V7_DIR = 'v7/maincpu'
V9_DIR = 'v9/maincpu'
GEN_DIR = os.path.join(V7_DIR, 'includes/generated')
MACROS = 'shared/macros.s'


def get_v9_source_for_label(label):
    """Find and return the v9 source lines for a label (up to the next label)."""
    # Cache on first call
    if not hasattr(get_v9_source_for_label, '_cache'):
        get_v9_source_for_label._cache = {}
        for filepath in sorted(glob.glob(os.path.join(V9_DIR, '**/*.s'), recursive=True)):
            with open(filepath, 'rb') as f:
                lines = f.readlines()
            current_label = None
            current_lines = []
            for i, line in enumerate(lines):
                s = line.decode('latin-1', errors='replace').rstrip()
                m = re.match(r'^([A-Za-z_][\w]*):', s)
                if m:
                    if current_label:
                        get_v9_source_for_label._cache[current_label] = current_lines
                    current_label = m.group(1)
                    current_lines = []
                elif current_label:
                    # Skip empty/comment lines at start
                    stripped = s.strip()
                    if stripped and not stripped.startswith(';'):
                        current_lines.append(line)
                    elif current_lines:  # keep comments/blanks after first instruction
                        current_lines.append(line)
            if current_label:
                get_v9_source_for_label._cache[current_label] = current_lines

    return get_v9_source_for_label._cache.get(label)


def is_data_label(label):
    """Check if a label contains data (not code) in v9."""
    lines = get_v9_source_for_label(label)
    if not lines:
        return True  # unknown = treat as data
    first = lines[0].decode('latin-1', errors='replace').strip()
    return any(first.startswith(d) for d in
               ['.byte', '.short', '.long', '.ascii', '.asciz',
                '.zero', '.fill', '.incbin'])


def assemble_snippet(source_lines, include_dir):
    """Assemble source lines, return binary bytes or None."""
    with tempfile.NamedTemporaryFile(suffix='.s', mode='wb', delete=False) as f:
        f.write(b'.text\n')
        f.write(b'\t.include "' + MACROS.encode() + b'"\n')
        for line in source_lines:
            if isinstance(line, str):
                f.write(line.encode('latin-1'))
            else:
                f.write(line)
            if not line.endswith(b'\n') and not (isinstance(line, str) and line.endswith('\n')):
                f.write(b'\n')
        tmpfile = f.name

    obj_file = tmpfile + '.o'
    bin_file = tmpfile + '.bin'

    try:
        r = subprocess.run([LLVM_MC, '--triple=tlcs900', '-filetype=obj',
                           '-I', include_dir, '-o', obj_file, tmpfile],
                          capture_output=True, text=True)
        if r.returncode != 0:
            return None

        subprocess.run([LLVM_OBJCOPY, '-O', 'binary', obj_file, bin_file],
                      capture_output=True)
        return open(bin_file, 'rb').read()
    finally:
        for f in [tmpfile, obj_file, bin_file]:
            if os.path.exists(f):
                os.unlink(f)


def try_migrate_label(label, v7_ground_truth, v9_source_lines):
    """Try to produce v9 source that assembles to v7 ground truth bytes.

    Returns (new_source_lines, status) where status is one of:
    - 'identical': v9 source produces exact v7 bytes
    - 'patched': v9 source with operand patches produces v7 bytes
    - 'failed': can't make it work
    """
    # Step 1: Assemble v9 source
    v9_bytes = assemble_snippet(v9_source_lines, V9_DIR)
    if v9_bytes is None:
        return None, 'asm_error'

    # Step 2: Compare with ground truth
    gt = v7_ground_truth
    if v9_bytes == gt:
        return v9_source_lines, 'identical'

    # Step 3: If sizes differ, can't use v9 source directly
    if len(v9_bytes) != len(gt):
        return None, 'size_mismatch'

    # Step 4: Find differing byte positions
    diff_positions = [i for i in range(len(gt)) if v9_bytes[i] != gt[i]]

    if not diff_positions:
        return v9_source_lines, 'identical'

    # Step 5: Try to patch operands
    # Strategy: decode each instruction in the v9 source, find which instruction
    # contains each diff byte, and patch its operand

    # For now, use a simpler approach: if the ONLY diffs are in positions that
    # look like address operands (following 0x1d call, 0x76/0x6e jrl, or in
    # known lda_d16/stb_d8 patterns), patch the v9 source with v7 values.

    # Build a map of instruction boundaries by reassembling with show-encoding
    # Actually, let's try a pragmatic approach: for each v9 source line that
    # contains a call/jrl/addr24/lda_d16/stb_d8 with a symbolic or numeric operand,
    # check if changing the operand to match v7 would fix the diffs.

    # For now: if few diffs (<=6 bytes), try hardcoding the v7 bytes for those positions
    # by finding which source line's operand to change

    if len(diff_positions) > 12:
        return None, 'too_many_diffs'

    # Try instruction-level patching
    patched_lines = try_patch_operands(v9_source_lines, v9_bytes, gt, diff_positions)
    if patched_lines:
        # Verify the patch
        patched_bytes = assemble_snippet(patched_lines, V9_DIR)
        if patched_bytes == gt:
            return patched_lines, 'patched'

    return None, f'patch_failed_{len(diff_positions)}diffs'


def try_patch_operands(v9_lines, v9_bytes, gt_bytes, diff_positions):
    """Try to patch operands in v9 source to match ground truth bytes.

    Strategy: for each source line with a call/jrl/lda_d16/stb_d8 instruction,
    check if the diff bytes fall within that instruction's address operand.
    If so, replace the operand with the v7 value.
    """
    # Parse each line to find patchable operands
    patched = list(v9_lines)  # copy
    remaining_diffs = set(diff_positions)

    # Accumulate byte offset per instruction line
    byte_offset = 0
    for line_idx, line in enumerate(v9_lines):
        s = line.decode('latin-1', errors='replace').strip()
        if not s or s.startswith(';') or s.startswith('.'):
            continue

        # Estimate instruction size by assembling this line alone
        single_bytes = assemble_snippet([line], V9_DIR)
        if single_bytes is None:
            # Can't assemble standalone (e.g., uses local labels) — skip
            byte_offset += estimate_instruction_size(s)
            continue

        inst_size = len(single_bytes)
        inst_end = byte_offset + inst_size

        # Check if any diff bytes fall in this instruction
        inst_diffs = [d for d in remaining_diffs if byte_offset <= d < inst_end]

        if inst_diffs:
            # Try to patch this instruction
            new_line = patch_instruction(s, single_bytes, gt_bytes[byte_offset:inst_end],
                                        [d - byte_offset for d in inst_diffs])
            if new_line:
                patched[line_idx] = (('\t' + new_line + '\n').encode('latin-1'))
                remaining_diffs -= set(inst_diffs)

        byte_offset += inst_size

    if remaining_diffs:
        return None  # couldn't patch all diffs
    return patched


def estimate_instruction_size(s):
    """Rough estimate of instruction size for instructions that can't assemble standalone."""
    if 'call ' in s or 'calr ' in s:
        return 4
    if 'jrl ' in s:
        return 4
    if 'jr ' in s:
        return 2
    if 'ld ' in s and 'xwa' in s:
        return 5
    return 3  # average


def patch_instruction(asm_line, v9_bytes, gt_bytes, diff_offsets):
    """Try to patch a single instruction's operands to match ground truth.

    Handles:
    - call <addr> → call <v7_addr> (bytes 1-3 are the 24-bit address)
    - lda_d16 xreg, (<addr>) → change the 16-bit address
    - stb_d8 (<addr>), reg → change the 16-bit address
    - Numeric operands in custom mnemonics
    """
    if len(v9_bytes) != len(gt_bytes):
        return None

    # call instruction: 0x1d + 3 addr bytes
    if v9_bytes[0] == 0x1d and len(v9_bytes) == 4 and set(diff_offsets) <= {1, 2, 3}:
        v7_addr = int.from_bytes(gt_bytes[1:4], 'little')
        return f'.byte 0x1d, 0x{gt_bytes[1]:02x}, 0x{gt_bytes[2]:02x}, 0x{gt_bytes[3]:02x}\t; {asm_line} (v7 addr)'

    # jrl instruction with 2-byte displacement
    if len(v9_bytes) >= 3 and set(diff_offsets) <= {len(v9_bytes)-2, len(v9_bytes)-1}:
        # Last 2 bytes are displacement — replace whole instruction with .byte
        byte_str = ', '.join(f'0x{b:02x}' for b in gt_bytes)
        return f'.byte {byte_str}\t; {asm_line} (v7 displacement)'

    # lda_d16 with 16-bit address: pattern is F1 <lo> <hi> ...
    if 'lda_d16' in asm_line and len(diff_offsets) <= 2:
        # Find the address in the instruction and replace
        m = re.search(r'lda_d16\s+(\w+),\s*\((\w+)\)', asm_line)
        if m:
            # Extract v7 address from ground truth bytes
            # The address bytes are at specific positions depending on encoding
            for i in range(len(gt_bytes) - 1):
                if i in diff_offsets or (i+1) in diff_offsets:
                    v7_val = int.from_bytes(gt_bytes[i:i+2], 'little')
                    return asm_line.replace(m.group(2), f'0x{v7_val:04x}')

    # stb_d8 with address
    if 'stb_d8' in asm_line and len(diff_offsets) <= 2:
        m = re.search(r'stb_d8\s*\((\w+)\)', asm_line)
        if m:
            for i in range(len(gt_bytes) - 1):
                if i in diff_offsets or (i+1) in diff_offsets:
                    v7_val = int.from_bytes(gt_bytes[i:i+2], 'little')
                    return asm_line.replace(m.group(1), f'0x{v7_val:04x}')

    # Generic: replace entire instruction with .byte fallback
    if len(diff_offsets) <= len(gt_bytes) // 2:  # less than half the bytes differ
        byte_str = ', '.join(f'0x{b:02x}' for b in gt_bytes)
        return f'.byte {byte_str}\t; {asm_line} (v7 patched)'

    return None


def format_as_bytes(bin_data):
    """Format binary data as .byte directives."""
    lines = []
    for i in range(0, len(bin_data), 8):
        chunk = bin_data[i:i+8]
        hex_vals = ', '.join(f'0x{b:02x}' for b in chunk)
        lines.append(f'\t.byte {hex_vals}'.encode('latin-1'))
    return b'\n'.join(lines)


def process_file(filepath, stats):
    """Process a v7 source file: replace .byte transplants with v9 source."""
    with open(filepath, 'rb') as f:
        data = f.read()

    lines = data.split(b'\n')
    modified = False
    new_lines = []
    current_label = None

    i = 0
    while i < len(lines):
        line = lines[i]
        s = line.decode('latin-1', errors='replace').strip()

        # Track current label
        m = re.match(r'^([A-Za-z_][\w]*):', s)
        if m:
            current_label = m.group(1)
            new_lines.append(line)
            i += 1
            continue

        # Check if this is a .byte transplant block (from our earlier disassembly)
        if s.startswith('.byte ') and current_label:
            binpath = os.path.join(GEN_DIR, f'v7_transplant_{current_label}.bin')

            if os.path.exists(binpath) and not is_data_label(current_label):
                # Collect all consecutive .byte lines for this label
                byte_lines = [line]
                j = i + 1
                while j < len(lines):
                    next_s = lines[j].decode('latin-1', errors='replace').strip()
                    if next_s.startswith('.byte '):
                        byte_lines.append(lines[j])
                        j += 1
                    else:
                        break

                # Get v7 ground truth and v9 source
                gt = open(binpath, 'rb').read()
                v9_source = get_v9_source_for_label(current_label)

                if v9_source and len(v9_source) > 0:
                    result_lines, status = try_migrate_label(current_label, gt, v9_source)

                    if status == 'identical':
                        new_lines.extend(result_lines)
                        modified = True
                        stats['identical'] += 1
                        i = j
                        current_label = None
                        continue
                    elif status == 'patched':
                        new_lines.extend(result_lines)
                        modified = True
                        stats['patched'] += 1
                        i = j
                        current_label = None
                        continue
                    else:
                        stats[status] = stats.get(status, 0) + 1

                # Keep original .byte lines
                new_lines.extend(byte_lines)
                i = j
                current_label = None
                continue

        new_lines.append(line)
        i += 1

    if modified:
        with open(filepath, 'wb') as f:
            f.write(b'\n'.join(new_lines))

    return modified


def main():
    os.chdir('/mnt/shared/kn5000-roms-disasm')

    print("=== v7 Source Migration: .byte → v9 source with operand patching ===\n")

    stats = {'identical': 0, 'patched': 0}

    v7_files = sorted(glob.glob(os.path.join(V7_DIR, '**/*.s'), recursive=True))
    print(f"Processing {len(v7_files)} files...\n")

    for filepath in v7_files:
        if process_file(filepath, stats):
            basename = os.path.relpath(filepath, V7_DIR)
            total = stats['identical'] + stats['patched']
            print(f"  {basename}: {total} migrated ({stats['identical']} identical, {stats['patched']} patched)")

    total_migrated = stats['identical'] + stats['patched']
    total_failed = sum(v for k, v in stats.items() if k not in ('identical', 'patched'))

    print(f"\n=== Results ===")
    print(f"  Identical (v9 source works as-is): {stats['identical']}")
    print(f"  Patched (operands adjusted):       {stats['patched']}")
    print(f"  Failed (kept as .byte):            {total_failed}")
    for k, v in sorted(stats.items()):
        if k not in ('identical', 'patched'):
            print(f"    {k}: {v}")
    print(f"\nRun: make clean && make all")


if __name__ == '__main__':
    main()
