#!/usr/bin/env python3
"""
Compress data using the SLIDE8K (8K-window LZSS) algorithm for KN5000 ROMs.

Usage:
    python scripts/build/compress_slide8k.py <input_file> <output_file>
        [--reference <ref_compressed>] [--strict] [--with-header]

This produces LZSS compressed data compatible with the KN5000's SLIDE8K format
(see scripts/build/decompress_slide8k.py for the format description and
v10/maincpu/boot/system_handlers.s SLIDE_Decompress_8K_Init for the decoder).
By default the output does NOT include the 11-byte header; pass --with-header
to prepend "SLIDE8K\\0" + the 24-bit big-endian decompressed size.

If a reference compressed file is provided, the compressor replays the
original encoder's literal-vs-match decisions for byte-identical output.
Two properties of the factory streams make plain re-encoding insufficient,
and both are handled here:

  * The last flag byte may be only partially consumed (the decoder stops on
    the decompressed-size header field, mid-group), and its never-read high
    bits can be NONZERO (e.g. the stale German block ends with flag byte 0xA0
    of which only bit 0 is consumed).  The replay therefore re-emits the
    original flag byte values verbatim; the consumed bits are still verified
    against the replayed decisions.
  * The reference file may carry trailing bytes past the point where the
    decoder stops (each factory block is followed by one even-alignment pad
    byte of arbitrary value).  If the re-encoded stream is a strict prefix of
    the reference, the remaining original bytes are carried over verbatim.

With --strict, any input that cannot be reproduced from the reference
decisions is a hard error (used by the build so a rebuilt ROM can never
silently diverge from the factory bytes).
"""

import os
import sys

STRICT = False

# SLIDE8K parameters (SLIDE4K values in parentheses)
WINDOW_SIZE = 0x2000        # (0x1000)
WINDOW_MASK = 0x1FFF        # (0xFFF)
WINDOW_START_POS = 0x1FF6   # initial ring write position (0xFEE)
MIN_MATCH_LENGTH = 3        # count field 0 => 3 bytes
MAX_MATCH_LENGTH = 10       # 3-bit count field + 3 (SLIDE4K: 4-bit + 3 = 18)
MAGIC = b"SLIDE8K\x00"


def make_header(decompressed_size):
    """11-byte block header: magic + 24-bit big-endian decompressed size."""
    return MAGIC + bytes([(decompressed_size >> 16) & 0xFF,
                          (decompressed_size >> 8) & 0xFF,
                          decompressed_size & 0xFF])


def decode_compressed(compressed_data):
    """
    Decode compressed data and extract all compression decisions.

    Returns (decisions, flag_bytes):
        decisions  - list of ('lit', byte) or ('ref', offset, length)
        flag_bytes - one original flag byte value per group of up to 8
                     decisions, preserved so partially-consumed final groups
                     re-encode byte-identically
    """
    window = bytearray(WINDOW_SIZE)
    window_pos = WINDOW_START_POS

    decisions = []
    flag_bytes = []
    idx = 0

    while idx < len(compressed_data):
        flag = compressed_data[idx]
        idx += 1
        flag_bytes.append(flag)

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

                offset = ((high & 0xF8) << 5) | low
                length = (high & 0x07) + 3

                decisions.append(('ref', offset, length))

                for i in range(length):
                    byte = window[(offset + i) & WINDOW_MASK]
                    window[window_pos] = byte
                    window_pos = (window_pos + 1) & WINDOW_MASK

    return decisions, flag_bytes


def encode_decisions(decisions, flag_bytes=None):
    """
    Encode compression decisions back to compressed bytes.

    If `flag_bytes` is given (from decode_compressed), each group re-emits the
    original flag byte after verifying that its consumed bits agree with the
    decisions; bits beyond the last decision of a group are copied unchecked
    (the hardware decoder never reads them).
    """
    output = bytearray()
    i = 0
    group = 0

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
                high = ((offset >> 5) & 0xF8) | ((length - 3) & 0x07)
                elements.append((low, high))
            i += 1

        if flag_bytes is not None:
            orig = flag_bytes[group]
            used_mask = (1 << len(elements)) - 1
            if (orig ^ flag) & used_mask:
                raise ValueError(
                    f"group {group}: replayed flag bits 0x{flag:02X} disagree "
                    f"with original flag byte 0x{orig:02X}")
            flag = orig
        group += 1

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
    window_pos = WINDOW_START_POS
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

    # The reference stream may decode to a few extra trailing bytes past the
    # declared output size (the decoder stops on the size header field, so
    # bytes encoded past it are simply never produced on hardware), and it may
    # also fall short only where a trailing pad byte was decoded as flag bits.
    # The replayed decisions therefore only need to reproduce `expected_data`
    # as a PREFIX.
    return bytes(output)[:len(expected_data)] == expected_data


def find_longest_match(data, pos, window, window_pos, total_out):
    """
    Find the longest match in the ring for data[pos:], honoring decoder
    semantics: the ring is updated while a match is copied, so bytes the
    match itself has just written are legal source material (this is how
    runs longer than the distance back to window_pos are encoded).

    `total_out` guards the ring positions the decoder has not initialized:
    the firmware zero-fills only positions 0..WINDOW_START_POS-1, so the
    tail region [WINDOW_START_POS, WINDOW_SIZE) holds malloc garbage until
    the first `p - WINDOW_START_POS + 1` output bytes have been written.

    Returns (offset, length), or (0, 0) if no match of MIN_MATCH_LENGTH+.
    """
    if pos >= len(data):
        return 0, 0

    best_offset = 0
    best_length = 0

    for search_offset in range(WINDOW_SIZE):
        match_length = 0
        while (match_length < MAX_MATCH_LENGTH and
               pos + match_length < len(data)):
            read_pos = (search_offset + match_length) & WINDOW_MASK
            # distance from the current write position to read_pos
            dist = (read_pos - window_pos) & WINDOW_MASK
            if dist < match_length:
                # reading a byte this same match already wrote
                window_byte = data[pos + dist]
            else:
                if (read_pos >= WINDOW_START_POS and
                        read_pos - WINDOW_START_POS >= total_out):
                    break  # uninitialized ring byte: never reference it
                window_byte = window[read_pos]

            if window_byte != data[pos + match_length]:
                break
            match_length += 1

        if match_length >= MIN_MATCH_LENGTH and match_length > best_length:
            best_length = match_length
            best_offset = search_offset
            if best_length == MAX_MATCH_LENGTH:
                break

    if best_length >= MIN_MATCH_LENGTH:
        return best_offset, best_length
    return 0, 0


def compress_slide8k(data):
    """
    Compress data using the SLIDE8K (LZSS) algorithm, greedy longest-match.

    NOTE: produces a VALID stream, but not necessarily the same bytes the
    factory encoder emitted — use --reference for byte-identical rebuilds.
    """
    window = bytearray(WINDOW_SIZE)
    window_pos = WINDOW_START_POS

    decisions = []
    pos = 0

    while pos < len(data):
        offset, length = find_longest_match(data, pos, window, window_pos, pos)

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
    Compress data by replaying the decisions of a reference compressed file.

    If the reference decisions reproduce `data`, re-encode those exact
    decisions (with the original flag byte values) for byte-identical output.
    """
    ref_decisions, ref_flags = decode_compressed(reference_compressed)

    if verify_decisions(ref_decisions, data):
        print("Reference file matches input - using learned decisions")
        out = encode_decisions(ref_decisions, ref_flags)
        # A stream can end with dangling bytes the decoder never consumes:
        # the inter-block alignment pad byte, or a flag byte whose items were
        # never written.  Such bytes yield no decisions and would be lost on
        # re-encode.  If what we produced is an exact prefix of the reference,
        # carry the remaining original bytes over verbatim.
        if (len(out) < len(reference_compressed) and
                reference_compressed.startswith(bytes(out))):
            out = bytes(out) + reference_compressed[len(out):]
        if out != reference_compressed:
            if STRICT:
                raise SystemExit(
                    "ERROR: replayed stream is not byte-identical to the "
                    "reference. Refusing to continue under --strict.")
            print("WARNING: replayed stream differs from the reference bytes")
        return out
    else:
        if STRICT:
            raise SystemExit(
                "ERROR: input does not match the reference compression decisions.\n"
                "       The rebuilt data differs from the factory data, so the ROM\n"
                "       would not be byte-identical. Refusing to fall back.")
        print("Reference file does not match input - using standard compression")
        return compress_slide8k(data)


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <input_file> <output_file> "
              f"[--reference <ref_compressed>] [--strict] [--with-header]")
        print("\nCompresses data using the SLIDE8K (8K-window LZSS) algorithm.")
        print("Output does not include the header unless --with-header is given.")
        print("\nOptions:")
        print("  --reference <file>  Replay compression decisions from reference")
        print("                      file for byte-identical output (if input matches)")
        print("  --strict            Hard error if the reference cannot be replayed")
        print("  --with-header       Prepend 'SLIDE8K\\0' + 24-bit BE size header")
        sys.exit(1)

    global STRICT
    if '--strict' in sys.argv:
        STRICT = True
        sys.argv.remove('--strict')

    with_header = False
    if '--with-header' in sys.argv:
        with_header = True
        sys.argv.remove('--with-header')

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
        if STRICT and reference_file:
            raise SystemExit(f"ERROR: --strict given but reference file "
                             f"{reference_file} not found")
        compressed = compress_slide8k(data)

    print(f"Compressed size: {len(compressed):,} bytes")
    print(f"Compression ratio: {100 * len(compressed) / len(data):.1f}%")

    # Write output
    with open(output_file, 'wb') as f:
        if with_header:
            f.write(make_header(len(data)))
        f.write(compressed)

    print(f"Written to: {output_file}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
