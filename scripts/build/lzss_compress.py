#!/usr/bin/env python3
"""
LZSS SLIDE4K Compressor for Technics KN5000

Compresses data using the SLIDE4K format used by the KN5000 firmware:
- 4KB sliding window (0x1000 bytes)
- 12-bit offset (masked with 0x0FFF)
- 4-bit length (stored in high nibble, actual length = value + 2)
- Flag byte: bit=1 for literal, bit=0 for back-reference
- Window pre-filled with zeros (positions 0-0xFED)
- Initial write position: 0x0FEE

Usage: python lzss_compress.py <input_file> <output_file> [--header "SLIDE4K"]
"""

import sys
import argparse

WINDOW_SIZE = 4096  # 0x1000
WINDOW_MASK = 0x0FFF
MIN_MATCH_LEN = 2
MAX_MATCH_LEN = 17  # 4 bits + 2 = 2-17
INITIAL_POS = 0x0FEE  # Pre-fill positions 0-0xFED with zeros


def find_longest_match(data, pos, window, window_pos):
    """Find the longest match in the sliding window."""
    if pos >= len(data):
        return 0, 0

    best_offset = 0
    best_length = 0

    # Search entire window for matches
    for offset in range(WINDOW_SIZE):
        match_len = 0
        src_pos = offset

        while (match_len < MAX_MATCH_LEN and
               pos + match_len < len(data) and
               window[src_pos] == data[pos + match_len]):
            match_len += 1
            src_pos = (src_pos + 1) & WINDOW_MASK

        if match_len > best_length:
            best_length = match_len
            best_offset = offset

    # Only use match if it's worthwhile (length >= 2)
    if best_length >= MIN_MATCH_LEN:
        return best_offset, best_length
    return 0, 0


def compress_lzss(data, header=None):
    """Compress data using SLIDE4K LZSS algorithm."""
    # Initialize sliding window with zeros
    window = bytearray(WINDOW_SIZE)
    window_pos = INITIAL_POS

    output = bytearray()
    if header:
        output.extend(header.encode('ascii'))
        output.append(0x00)  # Null terminator

    pos = 0

    while pos < len(data):
        # Collect up to 8 operations for one flag byte
        flag_byte = 0
        operations = []
        ops_count = 0

        for bit in range(8):
            if pos >= len(data):
                break  # Don't pad, just stop

            offset, length = find_longest_match(data, pos, window, window_pos)

            if length >= MIN_MATCH_LEN:
                # Back-reference: flag bit = 0
                operations.append((False, (offset, length)))
                # Update window with matched bytes
                for i in range(length):
                    window[window_pos] = data[pos + i]
                    window_pos = (window_pos + 1) & WINDOW_MASK
                pos += length
            else:
                # Literal: flag bit = 1
                flag_byte |= (1 << bit)
                byte = data[pos]
                operations.append((True, byte))
                window[window_pos] = byte
                window_pos = (window_pos + 1) & WINDOW_MASK
                pos += 1
            ops_count += 1

        if ops_count == 0:
            break

        # Write flag byte followed by operation data
        output.append(flag_byte)

        for is_literal, op_data in operations:
            if is_literal:
                output.append(op_data if isinstance(op_data, int) else 0)
            else:
                offset, length = op_data
                # Encode: low 8 bits of offset, then (high 4 bits of offset << 4) | (length - 2)
                low_offset = offset & 0xFF
                high_offset = (offset >> 8) & 0x0F
                encoded_length = (length - 2) & 0x0F
                output.append(low_offset)
                output.append((high_offset << 4) | encoded_length)

    return bytes(output)


def decompress_lzss(data, skip_header=0, output_size=None):
    """Decompress SLIDE4K LZSS data (for verification)."""
    window = bytearray(WINDOW_SIZE)
    window_pos = INITIAL_POS

    output = bytearray()
    pos = skip_header

    while pos < len(data):
        if output_size is not None and len(output) >= output_size:
            break

        flag_byte = data[pos]
        pos += 1

        for bit in range(8):
            if output_size is not None and len(output) >= output_size:
                break
            if pos >= len(data):
                break

            if flag_byte & (1 << bit):
                # Literal
                byte = data[pos]
                pos += 1
                output.append(byte)
                window[window_pos] = byte
                window_pos = (window_pos + 1) & WINDOW_MASK
            else:
                # Back-reference
                if pos + 1 >= len(data):
                    break
                low_offset = data[pos]
                high_and_len = data[pos + 1]
                pos += 2

                offset = low_offset | ((high_and_len >> 4) << 8)
                length = (high_and_len & 0x0F) + 2

                for _ in range(length):
                    if output_size is not None and len(output) >= output_size:
                        break
                    byte = window[offset]
                    output.append(byte)
                    window[window_pos] = byte
                    window_pos = (window_pos + 1) & WINDOW_MASK
                    offset = (offset + 1) & WINDOW_MASK

    return bytes(output)


def main():
    parser = argparse.ArgumentParser(description='LZSS SLIDE4K Compressor')
    parser.add_argument('input', help='Input file to compress')
    parser.add_argument('output', help='Output compressed file')
    parser.add_argument('--header', default='SLIDE4K', help='Header string (default: SLIDE4K)')
    parser.add_argument('--verify', action='store_true', help='Verify compression by decompressing')
    parser.add_argument('--decompress', action='store_true', help='Decompress instead of compress')
    parser.add_argument('--skip-header', type=int, default=8, help='Header bytes to skip when decompressing')

    args = parser.parse_args()

    with open(args.input, 'rb') as f:
        input_data = f.read()

    if args.decompress:
        output_data = decompress_lzss(input_data, args.skip_header)
        print(f'Decompressed: {len(input_data)} -> {len(output_data)} bytes')
    else:
        output_data = compress_lzss(input_data, args.header)
        print(f'Compressed: {len(input_data)} -> {len(output_data)} bytes ({len(output_data)*100//len(input_data)}%)')

        if args.verify:
            # Verify by decompressing
            header_len = len(args.header) + 1 if args.header else 0
            decompressed = decompress_lzss(output_data, header_len, len(input_data))
            if decompressed == input_data:
                print('Verification: OK')
            else:
                print(f'Verification: FAILED (got {len(decompressed)} bytes, expected {len(input_data)})')
                # Find first difference
                for i in range(min(len(decompressed), len(input_data))):
                    if decompressed[i] != input_data[i]:
                        print(f'First difference at offset 0x{i:X}: expected 0x{input_data[i]:02X}, got 0x{decompressed[i]:02X}')
                        break
                sys.exit(1)

    with open(args.output, 'wb') as f:
        f.write(output_data)


if __name__ == '__main__':
    main()
