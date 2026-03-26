#!/usr/bin/env python3
"""Apply v7 binary patches to the built ROM.

The v7 source files are shared with v9 and produce correct v9 bytes.
This script patches the remaining byte differences to produce a correct v7 ROM.

Patch format: sequence of [4B offset LE][4B length LE][data bytes]
"""
import struct, sys, os

rom_path = sys.argv[1] if len(sys.argv) > 1 else 'rebuilt_ROMs/kn5000_v7_program.llvm.rom'
patch_path = 'v7/maincpu/v7_binary_patches.bin'

if not os.path.exists(patch_path):
    print(f"Warning: {patch_path} not found, skipping v7 patches")
    sys.exit(0)

rom = bytearray(open(rom_path, 'rb').read())
patches = open(patch_path, 'rb').read()

pos = 0
count = 0
total_bytes = 0
while pos < len(patches):
    offset = struct.unpack('<I', patches[pos:pos+4])[0]
    length = struct.unpack('<I', patches[pos+4:pos+8])[0]
    data = patches[pos+8:pos+8+length]
    rom[offset:offset+length] = data
    pos += 8 + length
    count += 1
    total_bytes += length

with open(rom_path, 'wb') as f:
    f.write(rom)

print(f"Applied {count} v7 patches ({total_bytes} bytes) to {rom_path}")
