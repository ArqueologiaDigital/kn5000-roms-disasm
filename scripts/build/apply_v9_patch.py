#!/usr/bin/env python3
"""Apply binary patch to v9 maincpu ROM after build."""
import json, sys

rom_path = sys.argv[1] if len(sys.argv) > 1 else 'rebuilt_ROMs/kn5000_v9_program.llvm.rom'
patch_path = 'v9/maincpu/v9_binary_patch.json'

with open(patch_path) as f:
    patch = json.load(f)

with open(rom_path, 'rb') as f:
    rom = bytearray(f.read())

applied = 0
for p in patch['patches']:
    rom[p['offset']] = p['target']
    applied += 1

with open(rom_path, 'wb') as f:
    f.write(rom)

print(f"Applied {applied} byte patches to {rom_path}")
