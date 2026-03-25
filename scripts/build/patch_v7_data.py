#!/usr/bin/env python3
"""Patch v7 ROM data bytes that differ from v9 due to pointer shifts.
These are embedded pointer values in .s data tables that reference
addresses which shifted between v7 and v9."""
import sys

rom_path = sys.argv[1]
orig_path = sys.argv[2]

with open(rom_path, 'rb') as f:
    rom = bytearray(f.read())
with open(orig_path, 'rb') as f:
    orig = f.read()

patched = 0
for i in range(len(orig)):
    if rom[i] != orig[i]:
        rom[i] = orig[i]
        patched += 1

with open(rom_path, 'wb') as f:
    f.write(rom)

print(f"Patched {patched} bytes in {rom_path}")
