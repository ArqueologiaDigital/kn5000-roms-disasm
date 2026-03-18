#!/usr/bin/env python3
"""
Decompress all 19 demo song preset SLIDE4K blocks from the KN5000 Table Data ROM.

The pointer table at ROM address 0x9C4000 contains 19 entries, each a 4-byte
little-endian pointer to a SLIDE4K-compressed block. Entry 18 (the last) is
the Feature Demo preset at 0x8E0000.

SLIDE4K format:
  Header: "SLIDE4K\\0" (8 bytes) + 3 size bytes + 3 metadata bytes = 14 bytes
  Buffer size (not exact decompressed size) = byte[8] + (byte[9] << 8) + byte[10]
  Compressed data follows at offset 14.

LZSS parameters:
  - 4KB sliding window (0x1000 bytes)
  - Window pre-filled with zeros (positions 0-0xFED)
  - Initial write position: 0xFEE
  - Flag byte: bit=1 literal, bit=0 back-reference
  - Back-reference: 12-bit offset (low byte + high nibble<<8), 4-bit length (+2)

Usage:
    python scripts/build/decompress_demo_presets.py [--output-dir DIR] [--rom ROM]
"""

import struct
import sys
import os
import argparse

# SLIDE4K parameters
WINDOW_SIZE = 4096
WINDOW_MASK = 0xFFF
PREFILL_SIZE = 0xFEE

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(os.path.dirname(SCRIPT_DIR))

ROM_BASE = 0x800000
POINTER_TABLE_ADDR = 0x9C4000
HEADER_SIZE = 14
HEADER_MAGIC = b'SLIDE4K\x00'


def decompress_slide4k(compressed_data, max_output=None):
    """Decompress SLIDE4K (LZSS) encoded data.

    The firmware decompresses until either the compressed stream is exhausted
    or the output reaches the buffer size declared in the header (max_output).
    """
    window = bytearray(WINDOW_SIZE)
    window_pos = PREFILL_SIZE

    output = bytearray()
    i = 0
    data_len = len(compressed_data)

    while i < data_len:
        if max_output is not None and len(output) >= max_output:
            break

        flags = compressed_data[i]
        i += 1

        for bit in range(8):
            if i >= data_len:
                break
            if max_output is not None and len(output) >= max_output:
                break

            if flags & (1 << bit):
                # Literal byte
                byte = compressed_data[i]
                i += 1
                output.append(byte)
                window[window_pos] = byte
                window_pos = (window_pos + 1) & WINDOW_MASK
            else:
                # Back-reference
                if i + 1 >= data_len:
                    break
                low = compressed_data[i]
                high = compressed_data[i + 1]
                i += 2

                offset = ((high & 0xF0) << 4) | low
                length = (high & 0x0F) + 2

                for _ in range(length):
                    if max_output is not None and len(output) >= max_output:
                        break
                    byte = window[offset]
                    output.append(byte)
                    window[window_pos] = byte
                    window_pos = (window_pos + 1) & WINDOW_MASK
                    offset = (offset + 1) & WINDOW_MASK

    return bytes(output)


def parse_pointer_table(rom):
    """Read the 19-entry pointer table at 0x9C4000."""
    table_offset = POINTER_TABLE_ADDR - ROM_BASE
    ptrs = []
    for i in range(20):
        off = table_offset + i * 4
        val = struct.unpack_from('<I', rom, off)[0]
        if val == 0:
            break
        ptrs.append(val)
    return ptrs


def get_compressed_block_end(rom, ptrs, idx):
    """Determine where the compressed block ends for entry idx.

    Returns the ROM address of the byte past the end of the block.
    For entries in the 0x9Cxxxx range, the next entry's address is the boundary.
    For entry 18 at 0x8E0000, scan for 0xFF padding.
    """
    addr = ptrs[idx]

    if addr >= 0x9C4000:
        # Entries in the main range - sorted sequentially
        main_addrs = sorted([(i, ptrs[i]) for i in range(len(ptrs))
                             if ptrs[i] >= 0x9C4000], key=lambda x: x[1])
        for j, (mi, ma) in enumerate(main_addrs):
            if mi == idx:
                if j < len(main_addrs) - 1:
                    return main_addrs[j + 1][1]
                else:
                    return 0x9FA000  # next section boundary
    else:
        # Entry 18 at 0x8E0000 - scan for trailing 0xFF padding
        foff = addr - ROM_BASE + HEADER_SIZE
        while foff < len(rom) - 16:
            if all(b == 0xFF for b in rom[foff:foff + 16]):
                return ROM_BASE + foff
            foff += 1
        return addr + 0x7000  # fallback

    return addr + 0x10000  # generous fallback


def main():
    parser = argparse.ArgumentParser(description='Decompress demo song preset SLIDE4K blocks')
    parser.add_argument('--rom', default=os.path.join(PROJECT_DIR,
                        'rebuilt_ROMs/kn5000_table_data.llvm.rom'),
                        help='Path to table data ROM')
    parser.add_argument('--output-dir', default=os.path.join(PROJECT_DIR,
                        'table_data/includes/demo_presets'),
                        help='Output directory for decompressed files')
    parser.add_argument('--analyze', type=int, nargs='*',
                        help='Analyze specific preset indices (hex dump)')
    args = parser.parse_args()

    # Read ROM
    with open(args.rom, 'rb') as f:
        rom = f.read()
    print(f"ROM size: {len(rom):,} bytes")

    # Parse pointer table
    ptrs = parse_pointer_table(rom)
    print(f"Found {len(ptrs)} pointer table entries\n")

    os.makedirs(args.output_dir, exist_ok=True)

    total_decomp = 0
    total_comp = 0

    for i, addr in enumerate(ptrs):
        foff = addr - ROM_BASE
        header = rom[foff:foff + HEADER_SIZE]

        if header[:8] != HEADER_MAGIC:
            print(f"Entry {i:2d}: ERROR - bad header at 0x{addr:08X}: {header[:8]}")
            continue

        buf_size = header[8] + (header[9] << 8) + header[10]
        metadata = header[11:14]

        # Get compressed data (from byte 14 to next entry boundary)
        end_addr = get_compressed_block_end(rom, ptrs, i)
        comp_data = rom[foff + HEADER_SIZE:end_addr - ROM_BASE]

        # Strip trailing 0xFF padding from compressed data
        while comp_data and comp_data[-1] == 0xFF:
            comp_data = comp_data[:-1]

        # Decompress (use buffer size as limit — firmware stops at buf_size)
        decompressed = decompress_slide4k(comp_data, buf_size)

        # Save
        out_path = os.path.join(args.output_dir, f"demo_preset_{i:02d}.bin")
        with open(out_path, 'wb') as f:
            f.write(decompressed)

        total_decomp += len(decompressed)
        total_comp += len(comp_data)

        print(f"Entry {i:2d}: addr=0x{addr:08X}  buf={buf_size:6d}  decomp={len(decompressed):6d}  "
              f"comp={len(comp_data):6d}  ratio={len(comp_data)*100/len(decompressed):4.1f}%  "
              f"meta=[{metadata[0]:02X},{metadata[1]:02X},{metadata[2]:02X}]")

    print(f"\nTotal: {total_decomp:,} bytes decompressed from {total_comp:,} bytes compressed")

    # Analyze specific presets if requested
    if args.analyze is not None:
        indices = args.analyze if args.analyze else [0, 18]
        for idx in indices:
            out_path = os.path.join(args.output_dir, f"demo_preset_{idx:02d}.bin")
            if not os.path.exists(out_path):
                print(f"\nPreset {idx}: file not found")
                continue

            with open(out_path, 'rb') as f:
                data = f.read()

            print(f"\n{'='*72}")
            print(f"ANALYSIS: Preset {idx} ({len(data)} bytes)")
            print(f"{'='*72}")

            # Hex dump first 256 bytes
            print(f"\nFirst 256 bytes:")
            for off in range(0, min(256, len(data)), 16):
                hexb = ' '.join(f'{data[off+j]:02X}' for j in range(min(16, len(data)-off)))
                ascb = ''.join(chr(data[off+j]) if 32 <= data[off+j] < 127 else '.'
                              for j in range(min(16, len(data)-off)))
                print(f"  {off:04X}: {hexb:<48s} {ascb}")

            # Check offset +30 (active parts bitmask, 16-bit LE)
            if len(data) > 31:
                val_at_1e = struct.unpack_from('<H', data, 0x1E)[0]
                print(f"\nOffset +0x1E (30): 0x{val_at_1e:04X} (active parts bitmask)")

            # Look for 0x82 bytes (potential end-of-track markers)
            eot_positions = [j for j in range(len(data)) if data[j] == 0x82]
            print(f"\n0x82 byte count: {len(eot_positions)}")
            if eot_positions[:20]:
                print(f"First 20 positions: {[f'0x{p:04X}' for p in eot_positions[:20]]}")

    print("\nDone.")
    return 0


if __name__ == '__main__':
    sys.exit(main())
