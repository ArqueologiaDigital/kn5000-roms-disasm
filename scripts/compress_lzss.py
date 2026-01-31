#!/usr/bin/env python3
"""
Compress data using SLIDE4K (LZSS) algorithm for KN5000 ROMs.

Usage:
    python scripts/compress_lzss.py <input_file> <output_file> [--reference <ref_compressed>]

This produces LZSS compressed data compatible with the KN5000's SLIDE4K format.
The output does NOT include the header - that should be added separately in assembly.

If a reference compressed file is provided, the compressor will attempt to match
the original compression decisions for byte-identical output.
"""

import sys
import os
import hashlib

# SLIDE4K parameters
WINDOW_SIZE = 4096
WINDOW_MASK = 0xFFF
PREFILL_SIZE = 0xFEE  # First 4078 bytes pre-filled with zeros
MIN_MATCH_LENGTH = 2
MAX_MATCH_LENGTH = 17  # 4 bits + 2 = max 17


def decode_compressed(compressed_data):
    """
    Decode compressed data and extract all compression decisions.

    Returns a list of decisions: ('lit', byte) or ('ref', offset, length)
    """
    window = bytearray(WINDOW_SIZE)
    window_pos = PREFILL_SIZE

    decisions = []
    idx = 0

    while idx < len(compressed_data):
        flag = compressed_data[idx]
        idx += 1

        for bit in range(8):
            if idx >= len(compressed_data):
                break

            if flag & (1 << bit):
                # Literal
                byte = compressed_data[idx]
                idx += 1
                decisions.append(('lit', byte))
                window[window_pos] = byte
                window_pos = (window_pos + 1) & WINDOW_MASK
            else:
                # Back-reference
                if idx + 1 >= len(compressed_data):
                    break
                low = compressed_data[idx]
                high = compressed_data[idx + 1]
                idx += 2

                offset = ((high & 0xF0) << 4) | low
                length = (high & 0x0F) + 2

                decisions.append(('ref', offset, length))

                for i in range(length):
                    byte = window[(offset + i) & WINDOW_MASK]
                    window[window_pos] = byte
                    window_pos = (window_pos + 1) & WINDOW_MASK

    return decisions


def encode_decisions(decisions):
    """
    Encode compression decisions back to compressed bytes.
    """
    output = bytearray()
    i = 0

    while i < len(decisions):
        flag = 0
        elements = []

        for bit in range(8):
            if i >= len(decisions):
                break

            d = decisions[i]
            if d[0] == 'lit':
                flag |= (1 << bit)
                elements.append(d[1])
            else:  # ref
                offset, length = d[1], d[2]
                low = offset & 0xFF
                high = ((offset >> 4) & 0xF0) | ((length - 2) & 0x0F)
                elements.append((low, high))
            i += 1

        output.append(flag)
        for elem in elements:
            if isinstance(elem, tuple):
                output.append(elem[0])
                output.append(elem[1])
            else:
                output.append(elem)

    return bytes(output)


def verify_decisions(decisions, expected_data):
    """
    Verify that applying decisions produces the expected uncompressed data.
    """
    window = bytearray(WINDOW_SIZE)
    window_pos = PREFILL_SIZE
    output = bytearray()

    for d in decisions:
        if d[0] == 'lit':
            byte = d[1]
            output.append(byte)
            window[window_pos] = byte
            window_pos = (window_pos + 1) & WINDOW_MASK
        else:
            offset, length = d[1], d[2]
            for i in range(length):
                byte = window[(offset + i) & WINDOW_MASK]
                output.append(byte)
                window[window_pos] = byte
                window_pos = (window_pos + 1) & WINDOW_MASK

    return bytes(output) == expected_data


def find_longest_match(data, pos, window, window_pos):
    """
    Find the longest match in the sliding window.
    Handles overlapping matches correctly by simulating decompressor behavior.
    """
    if pos >= len(data):
        return 0, 0

    best_offset = 0
    best_length = 0

    for search_offset in range(WINDOW_SIZE):
        match_length = 0
        temp_window = window.copy()
        temp_window_pos = window_pos

        while (match_length < MAX_MATCH_LENGTH and
               pos + match_length < len(data)):
            read_pos = (search_offset + match_length) & WINDOW_MASK
            window_byte = temp_window[read_pos]
            data_byte = data[pos + match_length]

            if window_byte != data_byte:
                break

            temp_window[temp_window_pos] = window_byte
            temp_window_pos = (temp_window_pos + 1) & WINDOW_MASK
            match_length += 1

        if match_length >= MIN_MATCH_LENGTH and match_length > best_length:
            best_length = match_length
            best_offset = search_offset
            if best_length == MAX_MATCH_LENGTH:
                break

    if best_length >= MIN_MATCH_LENGTH:
        return best_offset, best_length
    return 0, 0


def compress_slide4k(data):
    """
    Compress data using SLIDE4K (LZSS) algorithm.
    """
    window = bytearray(WINDOW_SIZE)
    window_pos = PREFILL_SIZE

    decisions = []
    pos = 0

    while pos < len(data):
        offset, length = find_longest_match(data, pos, window, window_pos)

        if length >= MIN_MATCH_LENGTH:
            decisions.append(('ref', offset, length))
            for i in range(length):
                byte = window[(offset + i) & WINDOW_MASK]
                window[window_pos] = byte
                window_pos = (window_pos + 1) & WINDOW_MASK
            pos += length
        else:
            decisions.append(('lit', data[pos]))
            window[window_pos] = data[pos]
            window_pos = (window_pos + 1) & WINDOW_MASK
            pos += 1

    return encode_decisions(decisions)


def compress_with_reference(data, reference_compressed):
    """
    Compress data using decisions learned from a reference compressed file.

    If the data matches what the reference produces, use the exact same
    compression decisions for byte-identical output.
    """
    # Decode the reference to get its decisions
    ref_decisions = decode_compressed(reference_compressed)

    # Verify the reference produces the expected data
    if verify_decisions(ref_decisions, data):
        print("Reference file matches input - using learned decisions")
        return encode_decisions(ref_decisions)
    else:
        print("Reference file does not match input - using standard compression")
        return compress_slide4k(data)


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <input_file> <output_file> [--reference <ref_compressed>]")
        print("\nCompresses data using SLIDE4K (LZSS) algorithm.")
        print("Output does not include header - add 'SLIDE4K' header in assembly.")
        print("\nOptions:")
        print("  --reference <file>  Use compression decisions from reference file")
        print("                      for byte-identical output (if input matches)")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    # Check for reference file option
    reference_file = None
    if '--reference' in sys.argv:
        ref_idx = sys.argv.index('--reference')
        if ref_idx + 1 < len(sys.argv):
            reference_file = sys.argv[ref_idx + 1]

    # Read input
    with open(input_file, 'rb') as f:
        data = f.read()

    print(f"Input size: {len(data):,} bytes")

    # Compress
    if reference_file and os.path.exists(reference_file):
        with open(reference_file, 'rb') as f:
            ref_data = f.read()
        compressed = compress_with_reference(data, ref_data)
    else:
        compressed = compress_slide4k(data)

    print(f"Compressed size: {len(compressed):,} bytes")
    print(f"Compression ratio: {100 * len(compressed) / len(data):.1f}%")

    # Write output
    with open(output_file, 'wb') as f:
        f.write(compressed)

    print(f"Written to: {output_file}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
