#!/usr/bin/env python3
"""convert_wallpapers.py -- inline the two table_data wallpapers as typed .byte source.

QUESTION ANSWERED: table_data/kn5000_table_data.s pulled Wallpaper_0/1 in via
`.incbin "images/Wallpaper_0.bin"` (and _1). That .bin is itself a build product
regenerated from a committed PNG by scripts/build/indexed_images.py (verified
round-trip: `python3 scripts/build/indexed_images.py verify`). This script goes
one step further and removes the .incbin indirection entirely: it emits the
76,800 pixel bytes of each wallpaper as literal `.byte` rows (16/line, ROM
offset annotated, matching the convention already used by tone_database_records.s
and style_records.s), moves the whole "PRESET WALLPAPERS" section (both
wallpapers + their 1KB trailers/shade-ramp table) out of kn5000_table_data.s
into a new dedicated `table_data/wallpapers.s` -- the same modular pattern
already used for ui_bitmaps.s, fonts.s, style_records.s etc. -- and rewrites
kn5000_table_data.s to `.include` it.

Each wallpaper is a flat 320x240 8bpp indexed-colour raster (row-major, one
byte per pixel) -- see docs' table-data-rom.md "Wallpapers" section. There is
no finer structure to recover: this converts the *storage* from opaque binary
to typed assembly text, not from unknown to known (the content was already
fully documented before this ran).

The committed PNGs (table_data/images/Wallpaper_0.png / _1.png) remain the
authoritative human-editable form and are untouched. The checked-in raw
Wallpaper_0.bin/_1.bin duplicates become unreferenced by the LLVM build once
this runs, but are DELIBERATELY LEFT IN PLACE: archive/asl/table_data/
kn5000_table_data.asm still `binclude`s them directly for the archived ASL
mirror (`grep binclude archive/asl/table_data/kn5000_table_data.asm`), which
is exactly the icons_to_strings.bin precedent table-data-rom.md documents --
"the file stays on disk for the archived ASL mirror". Deleting them would
break `make asl-all` even though `make llvm-all`/the gate no longer reads them.

Usage:
    python3 scripts/converters/convert_wallpapers.py           # write wallpapers.s + patch
    python3 scripts/converters/convert_wallpapers.py --check   # only report, don't write
"""
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
TABLE_DIR = REPO / "table_data"
IMAGES_DIR = TABLE_DIR / "images"
MAIN_S = TABLE_DIR / "kn5000_table_data.s"
OUT_S = TABLE_DIR / "wallpapers.s"

OLD_BLOCK = '''; =============================================================================
; PRESET WALLPAPERS
; =============================================================================
; These 320x240 8bpp wallpaper images are referenced by the SetWallPaper
; routine in the Main CPU ROM via the wallpaper table at 0xEAAE62.
; Each wallpaper is 76,800 bytes (320 * 240).
; =============================================================================

\t.org 0x8ED000 - 0x800000, 0xFF
Wallpaper_0:\t; Blue textured pattern
\t.incbin "images/Wallpaper_0.bin"

\t; Wallpaper_0 trailer (0x8FFC00 - 0x8FFFFF, formerly includes/
\t; wallpaper_gap.bin -- the file stays on disk for the archived ASL
\t; mirror).  Like Wallpaper_1's trailer (see ui_bitmaps.s), the +0x380
\t; slot holds a 16-entry shade ramp of ascending {r, g, b, 0x00}
\t; quadruplets; this one matches WallpaperRamp_Navy.  No code reference
\t; found yet, so the RGB interpretation is tentative.
\t.zero 896
Wallpaper0_ShadeRamp:
\t.byte 0x1f, 0x1f, 0x28, 0x00
\t.byte 0x1f, 0x1f, 0x2d, 0x00
\t.byte 0x1f, 0x24, 0x2d, 0x00
\t.byte 0x1f, 0x1f, 0x33, 0x00
\t.byte 0x1f, 0x24, 0x33, 0x00
\t.byte 0x1f, 0x24, 0x38, 0x00
\t.byte 0x1f, 0x27, 0x38, 0x00
\t.byte 0x1f, 0x2c, 0x38, 0x00
\t.byte 0x1f, 0x27, 0x3d, 0x00
\t.byte 0x1f, 0x2c, 0x3d, 0x00
\t.byte 0x24, 0x27, 0x38, 0x00
\t.byte 0x24, 0x2c, 0x38, 0x00
\t.byte 0x24, 0x2c, 0x3d, 0x00
\t.byte 0x24, 0x2c, 0x43, 0x00
\t.byte 0x27, 0x2e, 0x41, 0x00
\t.byte 0x2b, 0x33, 0x46, 0x00
\t.zero 64

\t.org 0x900000 - 0x800000, 0xFF
Wallpaper_1:\t; Technics branded texture
\t.incbin "images/Wallpaper_1.bin"

\t; Wallpaper_1 trailer, UI bitmap/frame descriptor tables and pixel
\t; runs, and factory image banks (0x912C00 - 0x937FFF)
\t.include "ui_bitmaps.s"
'''

NEW_BLOCK = '''; =============================================================================
; PRESET WALLPAPERS (table_data/wallpapers.s: 0x8ED000-0x912BFF)
; =============================================================================
; These 320x240 8bpp wallpaper images are referenced by the SetWallPaper
; routine in the Main CPU ROM via the wallpaper table at 0xEAAE62.
; Each wallpaper is 76,800 bytes (320 * 240). See wallpapers.s.
; =============================================================================

\t.org 0x8ED000 - 0x800000, 0xFF
\t.include "wallpapers.s"

\t; Wallpaper_1 trailer, UI bitmap/frame descriptor tables and pixel
\t; runs, and factory image banks (0x912C00 - 0x937FFF)
\t.include "ui_bitmaps.s"
'''

TRAILER = '''
\t; Wallpaper_0 trailer (0x8FFC00 - 0x8FFFFF, formerly includes/
\t; wallpaper_gap.bin -- the file stays on disk for the archived ASL
\t; mirror).  Like Wallpaper_1's trailer (see ui_bitmaps.s), the +0x380
\t; slot holds a 16-entry shade ramp of ascending {r, g, b, 0x00}
\t; quadruplets; this one matches WallpaperRamp_Navy.  No code reference
\t; found yet, so the RGB interpretation is tentative.
\t.zero 896
Wallpaper0_ShadeRamp:
\t.byte 0x1f, 0x1f, 0x28, 0x00
\t.byte 0x1f, 0x1f, 0x2d, 0x00
\t.byte 0x1f, 0x24, 0x2d, 0x00
\t.byte 0x1f, 0x1f, 0x33, 0x00
\t.byte 0x1f, 0x24, 0x33, 0x00
\t.byte 0x1f, 0x24, 0x38, 0x00
\t.byte 0x1f, 0x27, 0x38, 0x00
\t.byte 0x1f, 0x2c, 0x38, 0x00
\t.byte 0x1f, 0x27, 0x3d, 0x00
\t.byte 0x1f, 0x2c, 0x3d, 0x00
\t.byte 0x24, 0x27, 0x38, 0x00
\t.byte 0x24, 0x2c, 0x38, 0x00
\t.byte 0x24, 0x2c, 0x3d, 0x00
\t.byte 0x24, 0x2c, 0x43, 0x00
\t.byte 0x27, 0x2e, 0x41, 0x00
\t.byte 0x2b, 0x33, 0x46, 0x00
\t.zero 64

\t.org 0x900000 - 0x800000, 0xFF
'''

WALLPAPERS = [
    ("Wallpaper_0", "Wallpaper_0.bin", 0x8ED000, "Blue textured pattern"),
    ("Wallpaper_1", "Wallpaper_1.bin", 0x900000, "Technics-branded texture"),
]


def format_pixels(label, bin_path, rom_base, description):
    data = bin_path.read_bytes()
    assert len(data) == 76800, f"{bin_path}: expected 76,800 B (320x240), got {len(data)}"
    lines = [f"{label}:\t; {description}\n"]
    for i in range(0, len(data), 16):
        chunk = data[i:i + 16]
        vals = ", ".join(f"0x{b:02x}" for b in chunk)
        lines.append(f"\t.byte\t{vals}\t; {rom_base + i:06X}\n")
    return "".join(lines)


def main():
    check_only = "--check" in sys.argv

    for _, bin_name, _, _ in WALLPAPERS:
        if not (IMAGES_DIR / bin_name).exists():
            print(f"ERROR: {IMAGES_DIR / bin_name} missing -- run `make tabledata-images` first",
                  file=sys.stderr)
            return 1

    header = (
        "; =============================================================================\n"
        "; WALLPAPERS -- 0x8ED000-0x912BFF: Wallpaper_0, its trailer, Wallpaper_1\n"
        "; =============================================================================\n"
        "; 320x240, 8bpp indexed colour, row-major, 76,800 bytes each. Referenced by\n"
        "; SetWallPaper via the wallpaper table at 0xEAAE62 in the Main CPU ROM. See\n"
        "; table-data-rom.md 'Wallpapers' for the palette and shade-ramp notes.\n"
        ";\n"
        "; Source of truth for the pixels: table_data/images/Wallpaper_{0,1}.png\n"
        "; (regenerate the raw .bin with `python3 scripts/build/indexed_images.py build`,\n"
        "; verify with `... verify`); the .byte rows below are that verified output,\n"
        "; inlined so this ROM image no longer depends on an .incbin of a checked-in\n"
        "; binary at assembly time. Generated by scripts/converters/convert_wallpapers.py\n"
        "; -- do not hand-edit the pixel rows; edit the PNG and regenerate.\n"
        "; =============================================================================\n\n"
    )

    label0, bin0, base0, desc0 = WALLPAPERS[0]
    label1, bin1, base1, desc1 = WALLPAPERS[1]
    out = header
    out += format_pixels(label0, IMAGES_DIR / bin0, base0, desc0)
    out += TRAILER
    out += format_pixels(label1, IMAGES_DIR / bin1, base1, desc1)

    if check_only:
        print(f"Would write {len(out):,} chars to {OUT_S}")
        return 0

    OUT_S.write_text(out)
    total_px = sum((IMAGES_DIR / b).stat().st_size for _, b, _, _ in WALLPAPERS)
    print(f"wrote {OUT_S} ({total_px:,} pixel bytes)")

    text = MAIN_S.read_text()
    if OLD_BLOCK not in text:
        print("ERROR: expected wallpaper block not found verbatim in kn5000_table_data.s",
              file=sys.stderr)
        return 1
    text = text.replace(OLD_BLOCK, NEW_BLOCK)
    MAIN_S.write_text(text)
    print(f"patched {MAIN_S}")
    print("NOTE: table_data/images/Wallpaper_0.bin and _1.bin are left in place on purpose "
          "-- archive/asl/table_data/kn5000_table_data.asm still binclude's them for the "
          "archived ASL mirror. Do not delete them; see this script's docstring.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
