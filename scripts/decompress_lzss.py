#!/usr/bin/env python3
"""
Decompress SLIDE4K (LZSS) compressed data from KN5000 ROMs.

Usage:
    python scripts/decompress_lzss.py [--compare FILE]

This script extracts and decompresses the compressed preset/parameter data
from the table_data ROM at 0x8E0000.

NOTE: This compressed data is NOT the Sub CPU ROM! The Sub CPU ROM is a separate
physical chip (kn5000_subprogram_v142.rom). The compressed data here contains
~33KB of preset/parameter data with MIDI-range values, not executable code.
"""

import sys
import os

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)

TABLE_DATA_ROM = os.path.join(PROJECT_DIR, "original_ROMs", "kn5000_table_data.rom")
COMPRESSED_BIN = os.path.join(PROJECT_DIR, "table_data", "includes", "subcpu_payload_compressed.bin")
ORIGINAL_SUBCPU = os.path.join(PROJECT_DIR, "original_ROMs", "kn5000_subprogram_v142.rom")
REBUILT_SUBCPU = os.path.join(PROJECT_DIR, "rebuilt_ROMs", "kn5000_subprogram_v142.rebuilt.rom")

# SLIDE4K parameters
WINDOW_SIZE = 4096
WINDOW_MASK = 0xFFF
PREFILL_SIZE = 0xFEE  # First 4078 bytes pre-filled with zeros


def decompress_slide4k(compressed_data):
    """
    Decompress SLIDE4K (LZSS) encoded data.

    Args:
        compressed_data: Bytes of compressed data (after header)

    Returns:
        Decompressed data as bytes
    """
    # Initialize sliding window with zeros
    window = bytearray(WINDOW_SIZE)
    window_pos = PREFILL_SIZE

    output = bytearray()
    i = 0
    data_len = len(compressed_data)

    while i < data_len:
        # Read flag byte
        flags = compressed_data[i]
        i += 1

        # Process 8 elements based on flag bits
        for bit in range(8):
            if i >= data_len:
                break

            if flags & (1 << bit):
                # Bit = 1: Literal byte
                byte = compressed_data[i]
                i += 1
                output.append(byte)
                window[window_pos] = byte
                window_pos = (window_pos + 1) & WINDOW_MASK
            else:
                # Bit = 0: Back-reference (2 bytes)
                if i + 1 >= data_len:
                    break

                low = compressed_data[i]
                high = compressed_data[i + 1]
                i += 2

                # Decode offset and length
                # offset = (high_nibble << 8) | low_byte
                # length = low_nibble + 2
                offset = ((high & 0xF0) << 4) | low
                length = (high & 0x0F) + 2

                # Copy from window
                for _ in range(length):
                    byte = window[offset]
                    output.append(byte)
                    window[window_pos] = byte
                    window_pos = (window_pos + 1) & WINDOW_MASK
                    offset = (offset + 1) & WINDOW_MASK

    return bytes(output)


def extract_from_table_data(rom_path):
    """
    Extract compressed SubCPU payload from table_data ROM.

    The payload is at offset 0x0E0000 in the ROM file (address 0x08E0000).
    Header is 14 bytes: "SLIDE4K" + null + 6 metadata bytes
    """
    with open(rom_path, 'rb') as f:
        # Seek to SubCPU payload location
        # ROM address 0x08E0000, ROM file starts at 0x0800000
        # So offset = 0x08E0000 - 0x0800000 = 0x0E0000
        f.seek(0x0E0000)

        # Read header (14 bytes as per assembly source)
        # db "SLIDE4K", 000h, 000h, 095h, 000h, "}Z", 0EEh
        header = f.read(14)
        print(f"Header: {header[:7]} ({header[:7].decode('ascii', errors='replace')})")
        print(f"Header bytes: {header.hex()}")

        # Verify it's SLIDE4K format
        if not header.startswith(b'SLIDE4K'):
            print("ERROR: Not a SLIDE4K compressed file!")
            return None, None

        # Read compressed data until we hit 0xFF padding
        # The compressed data ends around 0x08E6D40
        # That's offset 0x0E6D40 in the ROM file
        compressed_size = 0x6D40 - 14  # Subtract header size
        compressed_data = f.read(compressed_size)

        # Trim trailing 0xFF bytes (padding)
        while compressed_data and compressed_data[-1] == 0xFF:
            compressed_data = compressed_data[:-1]

        return header, compressed_data


def compare_files(data1, data2, name1="File1", name2="File2"):
    """Compare two byte sequences and report differences."""
    len1, len2 = len(data1), len(data2)

    print(f"\n{'='*60}")
    print(f"COMPARISON: {name1} vs {name2}")
    print(f"{'='*60}")
    print(f"  {name1} size: {len1:,} bytes (0x{len1:X})")
    print(f"  {name2} size: {len2:,} bytes (0x{len2:X})")

    if len1 != len2:
        print(f"  Size difference: {abs(len1 - len2):,} bytes")

    # Compare byte by byte
    min_len = min(len1, len2)
    differences = []

    for i in range(min_len):
        if data1[i] != data2[i]:
            differences.append(i)

    if not differences and len1 == len2:
        print(f"\n  ✓ FILES ARE IDENTICAL!")
        return True

    print(f"\n  Differences in overlapping region: {len(differences):,} bytes")

    if differences:
        # Show first 20 differences
        print(f"\n  First differences (up to 20):")
        for i, offset in enumerate(differences[:20]):
            print(f"    0x{offset:06X}: {name1}=0x{data1[offset]:02X}, {name2}=0x{data2[offset]:02X}")

        if len(differences) > 20:
            print(f"    ... and {len(differences) - 20} more differences")

        # Calculate match percentage
        match_pct = (min_len - len(differences)) / min_len * 100
        print(f"\n  Match percentage: {match_pct:.2f}%")

    # Check if one is a prefix of the other
    if len1 != len2 and not differences:
        shorter = name1 if len1 < len2 else name2
        print(f"\n  Note: {shorter} is a prefix of the other file")

    return False


def main():
    print("="*60)
    print("KN5000 SLIDE4K (LZSS) Decompressor")
    print("="*60)

    # Try to extract from table_data ROM first
    if os.path.exists(TABLE_DATA_ROM):
        print(f"\nExtracting from: {TABLE_DATA_ROM}")
        header, compressed_data = extract_from_table_data(TABLE_DATA_ROM)

        if compressed_data:
            print(f"Compressed data size: {len(compressed_data):,} bytes")
    elif os.path.exists(COMPRESSED_BIN):
        # Use pre-extracted binary
        print(f"\nUsing pre-extracted: {COMPRESSED_BIN}")
        with open(COMPRESSED_BIN, 'rb') as f:
            compressed_data = f.read()
        print(f"Compressed data size: {len(compressed_data):,} bytes")
        header = None
    else:
        print("ERROR: No source file found!")
        return 1

    # Decompress
    print("\nDecompressing...")
    decompressed = decompress_slide4k(compressed_data)
    print(f"Decompressed size: {len(decompressed):,} bytes (0x{len(decompressed):X})")

    # Save decompressed data
    output_path = os.path.join(PROJECT_DIR, "rebuilt_ROMs", "subcpu_payload_decompressed.bin")
    with open(output_path, 'wb') as f:
        f.write(decompressed)
    print(f"Saved to: {output_path}")

    # Compare with original SubCPU ROM
    if os.path.exists(ORIGINAL_SUBCPU):
        with open(ORIGINAL_SUBCPU, 'rb') as f:
            original_subcpu = f.read()
        compare_files(decompressed, original_subcpu, "Decompressed", "Original SubCPU ROM")

    # Compare with rebuilt SubCPU ROM
    if os.path.exists(REBUILT_SUBCPU):
        with open(REBUILT_SUBCPU, 'rb') as f:
            rebuilt_subcpu = f.read()
        compare_files(decompressed, rebuilt_subcpu, "Decompressed", "Rebuilt SubCPU ROM")

    # Also compare original vs rebuilt for reference
    if os.path.exists(ORIGINAL_SUBCPU) and os.path.exists(REBUILT_SUBCPU):
        with open(ORIGINAL_SUBCPU, 'rb') as f:
            original_subcpu = f.read()
        with open(REBUILT_SUBCPU, 'rb') as f:
            rebuilt_subcpu = f.read()
        compare_files(original_subcpu, rebuilt_subcpu, "Original SubCPU ROM", "Rebuilt SubCPU ROM")

    return 0


if __name__ == "__main__":
    sys.exit(main())
