#!/usr/bin/env python3
"""
Compress data using SLIDE4K (LZSS) algorithm for KN5000 ROMs.

Usage:
    python scripts/compress_lzss.py <input_file> <output_file> [--reference <ref_compressed>]

This produces LZSS compressed data compatible with the KN5000's SLIDE4K format.
By default the output does NOT include the header - that should be added
separately in assembly.

With --with-header the output is a whole-file SLIDE4K image: an 11-byte header
("SLIDE4K\\0" magic + 24-bit BIG-endian decompressed size) followed by the
stream. This is the firmware-update payload framing ("Program DATA FILE PCK" /
File Type 007, e.g. original_ROMs/kn5000_subprogram_v142_compressed.rom); in
that mode a --reference file is expected to carry the same 11-byte header,
which is validated and stripped before decision replay.

If a reference compressed file is provided, the compressor will attempt to match
the original compression decisions for byte-identical output.
"""

import sys
import os
import hashlib

STRICT = False

# Whole-file SLIDE4K image header (--with-header mode):
# 8-byte magic + 24-bit big-endian decompressed size = 11 bytes.
HEADER_MAGIC = b"SLIDE4K\x00"
HEADER_LEN = 11

# SLIDE4K parameters
WINDOW_SIZE = 4096
WINDOW_MASK = 0xFFF
PREFILL_SIZE = 0xFEE  # First 4078 bytes pre-filled with zeros
MIN_MATCH_LENGTH = 3
MAX_MATCH_LENGTH = 18  # 4-bit nibble + THRESHOLD(2) + 1 = max 18


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
                length = (high & 0x0F) + 3

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
                high = ((offset >> 4) & 0xF0) | ((length - 3) & 0x0F)
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

    # The reference stream may carry a few extra trailing bytes past the declared
    # output size (real ROM content that must be re-emitted verbatim), so the
    # replayed decisions only need to reproduce `expected_data` as a PREFIX.
    return bytes(output)[:len(expected_data)] == expected_data


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
        out = encode_decisions(ref_decisions)
        # A stream can end with a dangling flag byte whose items were never written
        # (the original encoder emitted the flag, then ran out of data). Such bytes
        # yield no decisions and would be lost on re-encode, leaving the output one
        # or more bytes short. If what we produced is an exact prefix of the
        # reference, carry the remaining original bytes over verbatim.
        if len(out) < len(reference_compressed) and reference_compressed.startswith(bytes(out)):
            out = bytes(out) + reference_compressed[len(out):]
        return out
    else:
        if STRICT:
            raise SystemExit(
                "ERROR: input does not match the reference compression decisions.\n"
                "       The rebuilt preset differs from the factory data, so the ROM\n"
                "       would not be byte-identical. Refusing to fall back.")
        print("Reference file does not match input - using standard compression")
        return compress_slide4k(data)


def parse_header(blob, name):
    """
    Validate an 11-byte whole-file SLIDE4K header; return the declared
    (24-bit big-endian) decompressed size.
    """
    if len(blob) < HEADER_LEN or not blob.startswith(HEADER_MAGIC):
        raise SystemExit(f"ERROR: {name} does not start with a SLIDE4K\\0 whole-file header")
    return (blob[8] << 16) | (blob[9] << 8) | blob[10]


def make_header(size):
    """Build the 11-byte whole-file header for a decompressed size."""
    if size >= (1 << 24):
        raise SystemExit(f"ERROR: decompressed size {size:,} does not fit the 24-bit header field")
    return HEADER_MAGIC + bytes([(size >> 16) & 0xFF, (size >> 8) & 0xFF, size & 0xFF])


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <input_file> <output_file> [--strict] [--with-header] [--reference <ref_compressed>]")
        print("\nCompresses data using SLIDE4K (LZSS) algorithm.")
        print("Output does not include header - add 'SLIDE4K' header in assembly.")
        print("\nOptions:")
        print("  --reference <file>  Use compression decisions from reference file")
        print("                      for byte-identical output (if input matches)")
        print("  --strict            Abort instead of falling back to fresh compression")
        print("                      when the input does not match the reference decisions")
        print("  --with-header       Emit a whole-file image: 11-byte header (SLIDE4K\\0 +")
        print("                      24-bit big-endian decompressed size) + stream. The")
        print("                      --reference file must carry the same header, which is")
        print("                      validated and stripped before decision replay.")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    global STRICT
    if '--strict' in sys.argv:
        STRICT = True
        sys.argv.remove('--strict')

    with_header = False
    if '--with-header' in sys.argv:
        with_header = True
        sys.argv.remove('--with-header')

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
        if with_header:
            declared = parse_header(ref_data, reference_file)
            if declared != len(data):
                raise SystemExit(
                    f"ERROR: reference header declares {declared:,} decompressed bytes\n"
                    f"       but the input is {len(data):,} bytes - wrong input/reference pairing.")
            ref_data = ref_data[HEADER_LEN:]
        compressed = compress_with_reference(data, ref_data)
    else:
        compressed = compress_slide4k(data)

    if with_header:
        compressed = make_header(len(data)) + compressed

    print(f"Compressed size: {len(compressed):,} bytes")
    print(f"Compression ratio: {100 * len(compressed) / len(data):.1f}%")

    # Write output
    with open(output_file, 'wb') as f:
        f.write(compressed)

    print(f"Written to: {output_file}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
