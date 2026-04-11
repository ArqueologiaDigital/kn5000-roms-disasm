#!/usr/bin/env python3
"""Replace numeric call/jp targets with symbolic labels in SubCPU assembly."""

import re
import subprocess

def get_labels_from_elf(elf_path):
    result = subprocess.run(
        ['/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm', '--defined-only', elf_path],
        capture_output=True, text=True
    )
    addr_to_name = {}
    for line in result.stdout.strip().split('\n'):
        if not line.strip():
            continue
        parts = line.split()
        if len(parts) >= 3:
            addr = int(parts[0], 16)
            addr_to_name[addr] = parts[2]
    return addr_to_name

def replace_numeric_targets(asm_file, addr_to_name):
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
    elf_path = 'rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf'
    asm_file = 'subcpu/kn5000_subprogram_v142.s'

    print(f'Extracting symbols from {elf_path}...')
    addr_to_name = get_labels_from_elf(elf_path)
    print(f'  {len(addr_to_name)} symbols loaded')

    print(f'Processing {asm_file}...')
    call_count, jp_count = replace_numeric_targets(asm_file, addr_to_name)
    print(f'  {call_count} calls + {jp_count} jp = {call_count + jp_count} total')

    with open(asm_file, 'rb') as f:
        text = f.read().decode('latin-1')
    remaining = len(re.findall(r'\tcall 0x', text))
    print(f'  Remaining: {remaining} numeric calls')

if __name__ == '__main__':
    main()
