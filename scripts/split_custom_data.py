#!/usr/bin/env python3
"""Split the KN5000 Custom Data ROM (IC19) into binary sections.

The Custom Data Flash ROM (AMD AM29LV800B, 1MB) is mapped at 0x300000-0x3FFFFF.
It contains custom accompaniment styles, registration memory, LCD wallpaper space,
and a compressed SubCPU payload staging area.

This script extracts the data-bearing regions into separate .bin files for
use as binclude targets in the assembly source. Erased (0xFF) and zero-filled
regions are handled by ds directives in the assembly and don't need bin files.
"""

import os
import sys

ROM_PATH = "original_ROMs/kn5000_custom_data.ic19"
OUTPUT_DIR = "custom_data/includes"

# (output_filename, rom_start_offset, rom_end_offset_inclusive)
SECTIONS = [
    ("section_0.bin",   0x000000, 0x016FFF),  # Section 0: custom style data
    ("section_1_2.bin", 0x019000, 0x046FFF),  # Sections 1+2: custom style data
    ("section_3_4.bin", 0x049000, 0x076FFF),  # Sections 3+4: custom style data
    ("section_5_6.bin", 0x079000, 0x0A6FFF),  # Sections 5+6: custom style data
    ("section_7.bin",   0x0B0000, 0x0B0FFF),  # Section 7: minimal data
    ("registration.bin", 0x0D3000, 0x0D3FFF), # Registration memory (3 banks + config)
]

def main():
    with open(ROM_PATH, "rb") as f:
        rom = f.read()

    assert len(rom) == 0x100000, f"Expected 1MB ROM, got {len(rom)} bytes"

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for filename, start, end in SECTIONS:
        data = rom[start:end + 1]
        path = os.path.join(OUTPUT_DIR, filename)
        with open(path, "wb") as f:
            f.write(data)
        print(f"  {filename:20s}  0x{start:06X}-0x{end:06X}  ({len(data):6d} bytes)")

    print(f"\nExtracted {len(SECTIONS)} sections to {OUTPUT_DIR}/")

if __name__ == "__main__":
    main()
