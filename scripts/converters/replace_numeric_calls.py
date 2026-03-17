#!/usr/bin/env python3
"""Replace numeric call/jp targets with symbolic labels in assembly source.

Extracts label names and addresses from the built ELF file using llvm-nm,
then replaces all `call 0xXXXXXX` and `jp 0xXXXXXX` with symbolic names.

Uses binary I/O to preserve Latin-1 encoding.
"""

import re
import os
import glob
import subprocess

def get_labels_from_elf(elf_path):
    """Extract label name->address mapping from the built ELF file."""
    result = subprocess.run(
        ['/mnt/shared/llvm-project/build/bin/llvm-nm', '--defined-only', elf_path],
        capture_output=True, text=True
    )
    addr_to_name = {}
    for line in result.stdout.strip().split('\n'):
        if not line.strip():
            continue
        parts = line.split()
        if len(parts) >= 3:
            addr = int(parts[0], 16)
            name = parts[2]
            addr_to_name[addr] = name
    return addr_to_name

def replace_numeric_targets(asm_file, addr_to_name):
    """Replace numeric call/jp targets with symbolic names."""
    with open(asm_file, 'rb') as f:
        text = f.read().decode('latin-1')

    call_count = 0
    jp_count = 0

    def replace_call(m):
        nonlocal call_count
        addr = int(m.group(1), 16)
        if addr in addr_to_name:
            call_count += 1
            return f'\tcall {addr_to_name[addr]}'
        return m.group(0)

    def replace_jp(m):
        nonlocal jp_count
        addr = int(m.group(1), 16)
        if addr in addr_to_name:
            jp_count += 1
            return f'\tjp {addr_to_name[addr]}'
        return m.group(0)

    text = re.sub(r'\tcall (0x[0-9A-Fa-f]+)', replace_call, text)
    text = re.sub(r'\tjp (0x[0-9A-Fa-f]+)', replace_jp, text)

    with open(asm_file, 'wb') as f:
        f.write(text.encode('latin-1'))

    return call_count, jp_count

def main():
    elf_path = 'rebuilt_ROMs/kn5000_v10_program.llvm.elf'

    print(f'Extracting symbols from {elf_path}...')
    addr_to_name = get_labels_from_elf(elf_path)
    print(f'  {len(addr_to_name)} symbols loaded from ELF')

    # Process all .s files in maincpu/ and subdirectories
    asm_files = glob.glob('maincpu/**/*.s', recursive=True)
    total_call = 0
    total_jp = 0

    for asm_file in sorted(asm_files):
        call_count, jp_count = replace_numeric_targets(asm_file, addr_to_name)
        if call_count + jp_count > 0:
            print(f'  {asm_file}: {call_count} calls, {jp_count} jp')
        total_call += call_count
        total_jp += jp_count

    print(f'\nTotal: {total_call} calls + {total_jp} jp = {total_call + total_jp} replacements')

if __name__ == '__main__':
    main()
