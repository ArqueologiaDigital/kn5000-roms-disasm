#!/usr/bin/env python3
"""Replace v7 code .incbin transplants with disassembled native instructions.

For each .incbin "includes/generated/v7_transplant_*.bin" in the v7 source:
1. Check if the corresponding v9 label has code (not data)
2. If code: disassemble the bin, round-trip test, replace if safe
3. If round-trip fails: use .byte fallback (raw hex bytes)
4. If data: keep the .incbin unchanged

Uses binary I/O to preserve Latin-1 encoding in .s files.
"""

import subprocess, os, glob, re, sys

LLVM_MC = '/mnt/shared/llvm-project/build/bin/llvm-mc'
LLVM_OBJCOPY = '/mnt/shared/llvm-project/build/bin/llvm-objcopy'
V7_DIR = 'v7/maincpu'
V9_DIR = 'v9/maincpu'
GEN_DIR = os.path.join(V7_DIR, 'includes/generated')


def classify_v9_labels():
    """Scan v9 source to classify each transplanted label as 'code' or 'data'."""
    classifications = {}
    transplant_labels = set()
    for binpath in glob.glob(os.path.join(GEN_DIR, 'v7_transplant_*.bin')):
        label = os.path.basename(binpath).replace('v7_transplant_', '').replace('.bin', '')
        transplant_labels.add(label)

    for filepath in sorted(glob.glob(os.path.join(V9_DIR, '**/*.s'), recursive=True)):
        with open(filepath, 'rb') as f:
            lines = f.readlines()
        for i, line in enumerate(lines):
            s = line.decode('latin-1', errors='replace').rstrip()
            m = re.match(r'^([A-Za-z_][\w]*):', s)
            if m and m.group(1) in transplant_labels:
                label_name = m.group(1)
                for j in range(i + 1, min(i + 5, len(lines))):
                    next_line = lines[j].decode('latin-1', errors='replace').strip()
                    if not next_line or next_line.startswith(';'):
                        continue
                    if any(next_line.startswith(d) for d in
                           ['.byte', '.short', '.long', '.ascii', '.asciz',
                            '.zero', '.fill', '.incbin']):
                        classifications[label_name] = 'data'
                    else:
                        classifications[label_name] = 'code'
                    break
    return classifications


def round_trip_test(bin_data):
    """Disassemble bin_data, reassemble, check if bytes match.
    Returns (disasm_text, is_perfect) or (None, False) on failure."""
    if not bin_data:
        return None, False

    hex_input = ' '.join(f'0x{b:02x}' for b in bin_data)
    result = subprocess.run(
        [LLVM_MC, '--triple=tlcs900', '--disassemble'],
        input=hex_input, capture_output=True, text=True
    )
    if result.returncode != 0 or not result.stdout.strip():
        return None, False

    disasm = result.stdout.strip()

    # Try to reassemble
    asm_input = '.text\n' + disasm
    result2 = subprocess.run(
        [LLVM_MC, '--triple=tlcs900', '-filetype=obj', '-o', '/tmp/v7_rt_test.o'],
        input=asm_input, capture_output=True, text=True
    )
    if result2.returncode != 0:
        return disasm, False

    subprocess.run([LLVM_OBJCOPY, '-O', 'binary',
                   '/tmp/v7_rt_test.o', '/tmp/v7_rt_test.bin'],
                  capture_output=True)

    try:
        rebuilt = open('/tmp/v7_rt_test.bin', 'rb').read()
    except FileNotFoundError:
        return disasm, False

    return disasm, (rebuilt == bin_data)


def format_as_instructions(disasm_text):
    """Format disassembly output as tab-indented instructions."""
    lines = []
    for line in disasm_text.split('\n'):
        line = line.strip()
        if line and not line.startswith('.text'):
            lines.append(b'\t' + line.encode('latin-1'))
    return b'\n'.join(lines)


def format_as_bytes(bin_data):
    """Format binary data as .byte directives (8 bytes per line)."""
    lines = []
    for i in range(0, len(bin_data), 8):
        chunk = bin_data[i:i+8]
        hex_vals = ', '.join(f'0x{b:02x}' for b in chunk)
        lines.append(f'\t.byte {hex_vals}'.encode('latin-1'))
    return b'\n'.join(lines)


def process_file(filepath, classifications, stats):
    """Process a single v7 .s file."""
    with open(filepath, 'rb') as f:
        data = f.read()

    lines = data.split(b'\n')
    modified = False
    new_lines = []

    for line in lines:
        s = line.decode('latin-1', errors='replace').strip()

        m = re.match(r'\s*\.incbin\s+"includes/generated/v7_transplant_(\w+)\.bin"', s)
        if m:
            label = m.group(1)
            classification = classifications.get(label, 'unknown')
            binpath = os.path.join(GEN_DIR, f'v7_transplant_{label}.bin')

            if classification == 'code' and os.path.exists(binpath):
                bin_data = open(binpath, 'rb').read()
                disasm, is_perfect = round_trip_test(bin_data)

                if is_perfect:
                    # Perfect round-trip: use disassembled instructions
                    new_lines.append(format_as_instructions(disasm))
                    modified = True
                    stats['perfect_replaced'] += 1
                    stats['perfect_bytes'] += len(bin_data)
                else:
                    # Round-trip failed: use .byte fallback
                    new_lines.append(format_as_bytes(bin_data))
                    modified = True
                    stats['byte_fallback'] += 1
                    stats['byte_fallback_bytes'] += len(bin_data)
            else:
                # Data or unknown — keep .incbin
                new_lines.append(line)
                if classification == 'data':
                    stats['data_kept'] += 1
                else:
                    stats['unknown_kept'] += 1
        else:
            new_lines.append(line)

    if modified:
        with open(filepath, 'wb') as f:
            f.write(b'\n'.join(new_lines))

    return modified


def main():
    print("=== v7 Transplant → Disassembled Source Migration ===\n")

    print("Classifying v9 labels as code/data...")
    classifications = classify_v9_labels()
    code_count = sum(1 for v in classifications.values() if v == 'code')
    data_count = sum(1 for v in classifications.values() if v == 'data')
    print(f"  Code: {code_count}, Data: {data_count}\n")

    stats = {
        'perfect_replaced': 0, 'perfect_bytes': 0,
        'byte_fallback': 0, 'byte_fallback_bytes': 0,
        'data_kept': 0, 'unknown_kept': 0,
        'files_modified': 0
    }

    v7_files = sorted(glob.glob(os.path.join(V7_DIR, '**/*.s'), recursive=True))
    print(f"Processing {len(v7_files)} v7 source files...")
    print("(Round-trip testing each transplant — this takes a few minutes)\n")

    for filepath in v7_files:
        if process_file(filepath, classifications, stats):
            stats['files_modified'] += 1
            basename = os.path.relpath(filepath, V7_DIR)
            total = stats['perfect_replaced'] + stats['byte_fallback']
            print(f"  {basename}: {total} transplants processed "
                  f"({stats['perfect_replaced']} native, {stats['byte_fallback']} .byte)")

    total_code = stats['perfect_replaced'] + stats['byte_fallback']
    print(f"\n=== Results ===")
    print(f"  Native instructions (perfect round-trip): {stats['perfect_replaced']:,} "
          f"({stats['perfect_bytes']:,} bytes, "
          f"{stats['perfect_replaced']*100/total_code:.1f}%)")
    print(f"  .byte fallback (encoding mismatch):       {stats['byte_fallback']:,} "
          f"({stats['byte_fallback_bytes']:,} bytes, "
          f"{stats['byte_fallback']*100/total_code:.1f}%)")
    print(f"  Data transplants kept as .incbin:          {stats['data_kept']}")
    print(f"  Files modified:                            {stats['files_modified']}")
    print(f"\nAll .incbin transplants for code eliminated.")
    print(f"Build should produce 100% byte-match (round-trip verified).")
    print(f"Run: make clean && make all")


if __name__ == '__main__':
    os.chdir('/mnt/shared/kn5000-roms-disasm')
    main()
