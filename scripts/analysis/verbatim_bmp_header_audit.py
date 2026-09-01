#!/usr/bin/env python3
"""verbatim_bmp_header_audit.py -- prove the six table_data FTBMP files are genuine,
uncompressed Windows BMPs and that they are already both viewable and byte-exact,
with no transformation between "committed source" and "ROM bytes".

QUESTION ANSWERED (lane BMP, 2026-09-02, notes/lanes/BRIEF-2026-09-01.md): the
inventory (notes/DEBT-INVENTORY-2026-09-02.md) frames table_data's six FTBMP files
as needing "a round-trip generator, not disassembly", on the pattern of
scripts/build/indexed_images.py and scripts/build/mono_images.py, which convert a
headerless raw pixel .bin (NOT independently viewable) into a PNG (viewable) and
regenerate the .bin at build time.

That pattern does not apply here. table_data/images/FTBMP0[1-6].BMP are already
complete, standard, self-describing Windows BMP files -- openable and editable in
any generic image tool with zero bespoke script, TODAY, as committed. The
`.incbin "images/FTBMPnn.BMP"` in table_data/kn5000_table_data.s reads that exact
committed file; there is no separate "raw .bin" the BMP was derived from and no
transform to invert. Building a PNG round-trip here would not gain viewability
(BMP already has it) and would only add machinery that must reproduce arbitrary
BMP header/palette fields with no benefit -- see docs/COMPLETENESS-STATUS.md's L4
section, which already calls this out: "FTBMP (the ROM stores real BMPs)" is one
of only three table_data asset classes needing no reverse converter.

This script is the check that backs that claim up: it parses the BITMAPFILEHEADER
+ BITMAPINFOHEADER of each of the six files and asserts every field a "genuine,
uncompressed, self-consistent BMP" claim depends on, not just the 'BM' magic and
overall size that table_data_debt.py's --selftest already checks.

    python3 scripts/analysis/verbatim_bmp_header_audit.py

Exits nonzero and names the failing field if any check fails.
"""
import pathlib
import struct
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
IMAGES = REPO / "table_data" / "images"

# name -> (offset, length) of the .incbin'd span inside original_ROMs/kn5000_table_data.rom,
# copied from scripts/analysis/extract_include_binaries.py's table_data dict, plus its
# one-line description of what the image actually shows (confirmed visually this session).
#
# FTBMP04's length was originally transcribed there as 0x09A53 -- this script caught the
# mismatch (committed file / header-declared size is 0x09A36, and 0xA753A + 0x09A36 lands
# exactly on FTBMP05's 0xB0F70 start, while +0x09A53 overruns it by 29 B) and both this
# table and extract_include_binaries.py were corrected together, 2026-09-02.
KNOWN = [
    ("FTBMP01.BMP", 0x80418, 0x13036, "Technics logo + world globe"),
    ("FTBMP02.BMP", 0x9344E, 0x0A6B6, "Upside-down showcasing subwoofers"),
    ("FTBMP03.BMP", 0x9DB04, 0x09A36, "Some floppy disks"),
    ("FTBMP04.BMP", 0xA753A, 0x09A36, "Inserting disks into the floppy drive"),
    ("FTBMP05.BMP", 0xB0F70, 0x0A076, "Arrows representing 360 surround sound"),
    ("FTBMP06.BMP", 0xBAFE6, 0x13036, "KN5000 name + rainbow comet"),
]

ROM = REPO / "original_ROMs" / "kn5000_table_data.rom"


def audit_one(name, rom_off, rom_len, desc, rom_bytes):
    p = IMAGES / name
    data = p.read_bytes()
    fail = []

    if len(data) != rom_len:
        fail.append(f"file is {len(data)} B, extractor recorded {rom_len} B")

    if rom_bytes is not None:
        span = rom_bytes[rom_off:rom_off + rom_len]
        if span != data:
            fail.append("does NOT match the ROM span at its recorded offset")

    if data[:2] != b"BM":
        fail.append("missing 'BM' magic")
        return fail  # nothing else is safe to parse

    file_size = struct.unpack_from("<I", data, 2)[0]
    data_offset = struct.unpack_from("<I", data, 10)[0]
    dib_size = struct.unpack_from("<I", data, 14)[0]
    width = struct.unpack_from("<i", data, 18)[0]
    height = struct.unpack_from("<i", data, 22)[0]
    planes = struct.unpack_from("<H", data, 26)[0]
    bpp = struct.unpack_from("<H", data, 28)[0]
    compression = struct.unpack_from("<I", data, 30)[0]
    image_size = struct.unpack_from("<I", data, 34)[0]
    colors_used = struct.unpack_from("<I", data, 46)[0]

    if file_size != len(data):
        fail.append(f"header file size {file_size} != actual {len(data)}")
    if dib_size != 40:
        fail.append(f"DIB header size {dib_size} != 40 (BITMAPINFOHEADER)")
    if planes != 1:
        fail.append(f"planes {planes} != 1")
    if bpp != 8:
        fail.append(f"bpp {bpp} != 8")
    if compression != 0:
        fail.append(f"compression {compression} != 0 (BI_RGB, uncompressed)")
    if colors_used != 256:
        fail.append(f"colors_used {colors_used} != 256")

    palette_bytes = colors_used * 4
    expected_data_offset = 14 + dib_size + palette_bytes
    if data_offset != expected_data_offset:
        fail.append(f"data offset {data_offset} != header(14)+DIB({dib_size})+palette({palette_bytes})={expected_data_offset}")

    stride = ((width * bpp + 31) // 32) * 4  # BMP rows pad to a 4-byte boundary
    expected_pixels = stride * abs(height)
    if image_size not in (0, expected_pixels):
        fail.append(f"image size field {image_size} != computed {expected_pixels} (0 is also legal for BI_RGB)")
    if len(data) - data_offset != expected_pixels:
        fail.append(f"pixel bytes on disk {len(data) - data_offset} != computed {expected_pixels}")
    if stride != width:
        fail.append(f"row stride {stride} != width {width} -- padding present, verify row handling")

    print(f"  {name:<14} {width}x{abs(height):<5} {len(data):>7,} B  offset=0x{data_offset:<4x} "
          f"palette={colors_used:<4} stride={stride:<4} -- {desc}")
    return fail


def main():
    rom_bytes = ROM.read_bytes() if ROM.exists() else None
    if rom_bytes is None:
        print(f"NOTE: {ROM} not found -- skipping the ROM-span cross-check "
              "(header/self-consistency checks still run)", file=sys.stderr)

    print("Six table_data FTBMP files -- BITMAPFILEHEADER + BITMAPINFOHEADER audit:")
    failures = []
    total = 0
    for name, off, length, desc in KNOWN:
        fs = audit_one(name, off, length, desc, rom_bytes)
        total += length
        for f in fs:
            failures.append(f"{name}: {f}")

    print(f"\n  TOTAL: {total:,} B across {len(KNOWN)} files")

    if failures:
        print(f"\nFAILED ({len(failures)}):")
        for f in failures:
            print(f"  - {f}")
        sys.exit(1)

    print("\nOK: all six are genuine uncompressed 8bpp BITMAPINFOHEADER BMPs, header-consistent, "
          "and (where the ROM was available) byte-identical to their recorded ROM span. "
          "They are already viewable in any generic image tool with zero bespoke script -- "
          "there is no headerless-blob step for a PNG round trip to replace.")


if __name__ == "__main__":
    main()
