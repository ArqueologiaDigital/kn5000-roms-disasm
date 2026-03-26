#!/usr/bin/env python3
"""
Generate v7 binary patches by comparing the v7 original ROM with the built ROM.

This script produces v7_binary_patches.bin which contains all byte-level
differences between the v7 build (from v9-derived source) and the v7 original ROM.

The patch file format is a sequence of records:
  [4 bytes: ROM offset (LE)] [4 bytes: length (LE)] [length bytes: correct data]

Run this after building the v7 ROM to regenerate patches when the source changes.
Usage: python3 scripts/build/generate_v7_patches.py
"""
import struct, os, sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(BASE_DIR)

V7_ORIG = 'original_ROMs/kn5000_v7_program.rom'
V7_BUILT = 'rebuilt_ROMs/kn5000_v7_program.llvm.rom'
PATCH_OUT = 'v7/maincpu/v7_binary_patches.bin'

if not os.path.exists(V7_ORIG):
    print(f"Error: {V7_ORIG} not found", file=sys.stderr)
    sys.exit(1)
if not os.path.exists(V7_BUILT):
    print(f"Error: {V7_BUILT} not found (build v7 first)", file=sys.stderr)
    sys.exit(1)

v7_orig = open(V7_ORIG, 'rb').read()
v7_built = open(V7_BUILT, 'rb').read()

if len(v7_orig) != len(v7_built):
    print(f"Error: size mismatch: orig={len(v7_orig)}, built={len(v7_built)}", file=sys.stderr)
    sys.exit(1)

# Find contiguous diff regions
patches = []
i = 0
while i < len(v7_orig):
    if v7_orig[i] != v7_built[i]:
        start = i
        while i < len(v7_orig) and v7_orig[i] != v7_built[i]:
            i += 1
        patches.append((start, v7_orig[start:i]))
    else:
        i += 1

# Write patch file
os.makedirs(os.path.dirname(PATCH_OUT), exist_ok=True)
total_bytes = 0
with open(PATCH_OUT, 'wb') as f:
    for offset, data in patches:
        f.write(struct.pack('<II', offset, len(data)))
        f.write(data)
        total_bytes += len(data)

print(f"Generated {len(patches)} patches ({total_bytes} bytes) -> {PATCH_OUT}")
