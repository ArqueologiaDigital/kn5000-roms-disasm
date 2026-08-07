#!/usr/bin/env python3
"""
Decompress SLIDE8K (LZSS) compressed data from KN5000 ROMs.

Usage:
    python scripts/build/decompress_slide8k.py <input.bin> [--offset OFF]
        [--output FILE] [--compressed-out FILE] [--expected-size N] [--quiet]
    python scripts/build/decompress_slide8k.py --all [--outdir DIR]

SLIDE8K is the 8-KByte-window variant of the SLIDE4K LZSS scheme.  Both are
decoded by the firmware routines in v10/maincpu/boot/system_handlers.s
(`SLIDE_Parse_Header` dispatches on the '4'/'8' character of the magic to
`SLIDE_Decompress_4K_Init` / `SLIDE_Decompress_8K_Init`).

Container layout (11-byte header, then the bitstream):

    offset  size  content
    0       7     magic "SLIDE8K"
    7       1     0x00 terminator
    8       3    decompressed size, 24-bit BIG-endian (same as SLIDE4K)
    11      ...   compressed stream

Bitstream (mirrors SLIDE4K except for the window/match geometry):

    * flag byte, LSB first: bit 1 = literal byte follows,
      bit 0 = 2-byte back-reference follows.  The firmware keeps the flag in a
      16-bit word as (0xFF00 | flags) and shifts right once per element; the
      0xFF sentinel reaching bit 8 is what triggers the reload, so exactly 8
      elements are consumed per flag byte.
    * back-reference bytes (low, high):
          offset = ((high & 0xF8) << 5) | low     ; 13-bit window position
          count  = (high & 0x07) + 3              ; 3..10 bytes copied
      (SLIDE4K: offset = ((high & 0xF0) << 4) | low, count = (high & 0x0F) + 3)
      Offsets are absolute ring positions, and the ring is updated while the
      copy runs, so self-overlapping matches replicate the decoder state.
    * ring: 0x2000 bytes, positions 0x0000-0x1FF5 zero-filled at start
      (the firmware zero-fills only up to the write position), write position
      starts at 0x1FF6 and wraps mod 0x2000.
      (SLIDE4K: 0x1000-byte ring, write position starts at 0xFEE.)
    * termination: purely by the decompressed-size header field.  The output
      count is checked before every compressed-stream byte read and after
      every element; the match copy loop itself is NOT bounds-checked, so a
      final back-reference may in principle overrun the declared size (none of
      the factory blocks do).  Trailing flag bits of the last flag byte are
      never examined and may be nonzero (block 1 below ends with flag byte
      0xA0 of which only 1 element is consumed).

Known SLIDE8K blocks (all in table_data/includes/icons_to_strings.bin, which
is included at ROM 0x944D78; each decompresses to exactly 0x9000 bytes of
multilingual help/hint text — pointer table + string pool):

    file off  ROM addr   stream end  content
    0x3EDC2   0x983B3A   0x42CBB     German, STALE duplicate: decodes garbled
                                     from output 0x55E0 on; referenced nowhere
    0x43918   0x988690   0x46DC1     English (language slots 0 and 4)
    0x46DC2   0x98BB3A   0x4A361     German
    0x4A362   0x98F0DA   0x4DC93     French
    0x4DC94   0x992A0C   0x51681     Spanish
    0x51682   0x9963FA   0x54C53     Indonesian

    Language pointer table: 6 x 32-bit LE ROM addresses at file offset
    0x432A0 (ROM 0x988018): EN, DE, FR, ES, EN, ID.

Every factory block is followed by ONE padding byte (varying value: leftover
encoder output, not read by the decoder) so that the next block starts on an
even address.  The compressed stream proper ends at "stream end" above.
"""

import argparse
import hashlib
import os
import sys

# SLIDE8K parameters (SLIDE4K values in parentheses)
WINDOW_SIZE = 0x2000        # (0x1000)
WINDOW_MASK = 0x1FFF        # (0xFFF)
WINDOW_START_POS = 0x1FF6   # initial ring write position (0xFEE)
HEADER_SIZE = 11            # "SLIDE8K" + 0x00 + 24-bit BE size
MAGIC = b"SLIDE8K\x00"

# Paths for --all mode
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(os.path.dirname(SCRIPT_DIR))
ICONS_TO_STRINGS = os.path.join(
    PROJECT_DIR, "table_data", "includes", "icons_to_strings.bin")

# (file_offset, ROM address, language tag) of the six factory blocks
KNOWN_BLOCKS = [
    (0x3EDC2, 0x983B3A, "german_stale"),   # unreferenced; garbled from 0x55E0
    (0x43918, 0x988690, "english"),
    (0x46DC2, 0x98BB3A, "german"),
    (0x4A362, 0x98F0DA, "french"),
    (0x4DC94, 0x992A0C, "spanish"),
    (0x51682, 0x9963FA, "indonesian"),
]


def parse_header(buf, offset=0):
    """Validate the SLIDE8K header at `offset`; return the decompressed size.

    The size is 24-bit big-endian, exactly as the firmware computes it:
        xix = (hdr[8] << 16) | (hdr[9] << 8) | hdr[10]
    """
    if buf[offset:offset + 8] != MAGIC:
        raise ValueError(
            f"no SLIDE8K header at offset 0x{offset:X} "
            f"(found {bytes(buf[offset:offset + 8])!r})")
    return (buf[offset + 8] << 16) | (buf[offset + 9] << 8) | buf[offset + 10]


def decompress_slide8k(buf, offset=0):
    """
    Decompress one SLIDE8K block starting at `offset` in `buf`.

    Faithful to SLIDE_Decompress_8K_Init: same ring geometry, same flag-word
    handling, and the same termination checks (output count vs. declared size
    before each stream read and after each element).

    Returns (payload, stream_len):
        payload    - decompressed bytes (== declared size for intact blocks)
        stream_len - compressed stream length in bytes, EXCLUDING the 11-byte
                     header and excluding the inter-block alignment pad byte
    """
    size = parse_header(buf, offset)
    i = offset + HEADER_SIZE

    window = bytearray(WINDOW_SIZE)   # ring; zero prefill
    wpos = WINDOW_START_POS
    out = bytearray()
    flag = 0                          # 16-bit flag word, 0xFF00 | flags

    while True:
        flag >>= 1
        if not (flag & 0x100):        # sentinel gone: need a new flag byte
            if len(out) >= size:
                break
            flag = 0xFF00 | buf[i]
            i += 1
        if flag & 1:
            # literal
            if len(out) >= size:
                break
            b = buf[i]
            i += 1
            out.append(b)
            window[wpos] = b
            wpos = (wpos + 1) & WINDOW_MASK
        else:
            # back-reference: 13-bit ring offset, 3-bit count field
            if len(out) >= size:
                break
            low = buf[i]
            i += 1
            if len(out) >= size:
                break
            high = buf[i]
            i += 1
            ref = ((high & 0xF8) << 5) | low
            count = (high & 0x07) + 3
            for k in range(count):    # ring is live during the copy
                b = window[(ref + k) & WINDOW_MASK]
                out.append(b)
                window[wpos] = b
                wpos = (wpos + 1) & WINDOW_MASK
        if len(out) >= size:
            break

    return bytes(out), i - offset - HEADER_SIZE


def process_block(data, offset, output=None, compressed_out=None,
                  expected_size=None, quiet=False):
    """Decompress one block, optionally writing payload / compressed stream."""
    size = parse_header(data, offset)
    payload, stream_len = decompress_slide8k(data, offset)

    if not quiet:
        print(f"  header offset:     0x{offset:X}")
        print(f"  declared size:     0x{size:X} ({size:,} bytes)")
        print(f"  decompressed:      0x{len(payload):X} ({len(payload):,} bytes)")
        print(f"  compressed stream: 0x{stream_len:X} bytes "
              f"(block ends at 0x{offset + HEADER_SIZE + stream_len:X})")
        print(f"  payload sha256:    {hashlib.sha256(payload).hexdigest()}")

    if expected_size is not None and len(payload) != expected_size:
        raise SystemExit(
            f"ERROR: decompressed 0x{len(payload):X} bytes, "
            f"expected 0x{expected_size:X}")

    if output:
        with open(output, "wb") as f:
            f.write(payload)
        if not quiet:
            print(f"  payload written:   {output}")
    if compressed_out:
        stream = data[offset + HEADER_SIZE:offset + HEADER_SIZE + stream_len]
        with open(compressed_out, "wb") as f:
            f.write(stream)
        if not quiet:
            print(f"  stream written:    {compressed_out}")

    return payload, stream_len


def main():
    ap = argparse.ArgumentParser(
        description="Decompress SLIDE8K (8K-window LZSS) blocks from KN5000 ROMs.")
    ap.add_argument("input", nargs="?", help="file containing a SLIDE8K block")
    ap.add_argument("--offset", type=lambda s: int(s, 0), default=0,
                    help="byte offset of the SLIDE8K header (default 0)")
    ap.add_argument("--output", help="write decompressed payload here")
    ap.add_argument("--compressed-out",
                    help="write the raw compressed stream (no header, no "
                         "alignment pad) here — usable as --reference for "
                         "compress_slide8k.py")
    ap.add_argument("--expected-size", type=lambda s: int(s, 0),
                    help="fail unless the payload is exactly this size")
    ap.add_argument("--all", action="store_true",
                    help="extract all six known blocks from "
                         "table_data/includes/icons_to_strings.bin")
    ap.add_argument("--bin", default=ICONS_TO_STRINGS,
                    help="override the source file for --all")
    ap.add_argument("--outdir", default=".",
                    help="output directory for --all (default: cwd)")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    if args.all:
        with open(args.bin, "rb") as f:
            data = f.read()
        os.makedirs(args.outdir, exist_ok=True)
        for idx, (off, rom, lang) in enumerate(KNOWN_BLOCKS):
            stem = f"slide8k_{idx:02d}_0x{rom:06x}_{lang}"
            if not args.quiet:
                print(f"Block {idx} ({lang}) @ file 0x{off:X} / ROM 0x{rom:X}:")
            process_block(
                data, off,
                output=os.path.join(args.outdir, stem + ".bin"),
                compressed_out=os.path.join(args.outdir, stem + ".compressed.bin"),
                expected_size=0x9000, quiet=args.quiet)
        return 0

    if not args.input:
        ap.error("input file required (or use --all)")
    with open(args.input, "rb") as f:
        data = f.read()
    process_block(data, args.offset, output=args.output,
                  compressed_out=args.compressed_out,
                  expected_size=args.expected_size, quiet=args.quiet)
    return 0


if __name__ == "__main__":
    sys.exit(main())
