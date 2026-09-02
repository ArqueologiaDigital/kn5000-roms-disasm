#!/usr/bin/env python3
"""wsa1_bitmaps.py -- every WSA1R ROM range that is PIXEL DATA <-> a PNG, ROUND TRIP.

QUESTION ANSWERED (lane IMAGE, 2026-09-02, notes/lanes/BRIEF-2026-09-01.md):
"If a data range is an image, it should be represented in the source as an image
file."  Before this script the WSA1R tree carried ZERO image files: every bitmap
was `.byte` rows with, at best, an ASCII-art preview in a comment.  This script
makes the PNG the thing you edit and the `.byte` rows a generated artefact:

    python3 scripts/build/wsa1_bitmaps.py census    # re-derive the geometry from the ROMs
    python3 scripts/build/wsa1_bitmaps.py export    # ROM  -> PNG   (run once)
    python3 scripts/build/wsa1_bitmaps.py verify    # PNG  -> bytes, assert == the ROM
    python3 scripts/build/wsa1_bitmaps.py check     # PNG  -> assert the .s already says this
    python3 scripts/build/wsa1_bitmaps.py rewrite   # PNG  -> patch the .s `.byte` values

`check` is the one that belongs in a build: it re-derives every `.byte` value in
every listed range from the committed PNG and asserts the source already holds
exactly those bytes.  Edit a PNG, run `rewrite`, and the assembly follows; the
byte gate then says whether the ROM still rebuilds.

================================================================================
THE PIXEL FORMAT, AND WHY IT IS NOT A GUESS
================================================================================

Every bitmap here is drawn by ONE routine: SWI7 service 3,
`LCD_Svc_03_BlitColumns` at prom_a 0xF8EDB4, converted in an earlier wave.  Its
loop is the format:

    ld (XIZ+0x01),0x4f      ; CSRDIR DOWN  -- the SED1330 cursor steps one
                            ;                 RASTER LINE per byte written
    ...                     ; outer loop runs BC times
      ld BC,HL              ; inner count is HL
      ld E,(XIY) / inc 1,XIY / ld (XIZ),E     ; HL bytes, consecutive, down
    inc 1,WA                ; the next column starts ONE BYTE along in VRAM
    djnz16 bc, ...

One display-RAM byte is 8 HORIZONTAL pixels, MSB leftmost (SED1330 graphics
mode).  `inc 1,WA` advances the destination by one byte = 8 pixels to the right.
So a "column" is an 8-pixel-wide vertical strip, HL pixels tall, and:

    width  = BC * 8            height = HL
    pixel (x, y) = bit (7 - x%8) of byte  (x//8) * HL + y        [COLUMN-MAJOR]

★ THE CALIBRATION.  That same formula, applied to prom_a 0xFFCB00 with the
BC=40 / HL=240 its own blit site at 0xF941D3 sets, renders the word `Technics`
in a bold face.  A wrong reading does not produce a legible wordmark.  Nothing
else in this file needs to be taken on trust: it is the one routine, and this is
the reading in which its output is readable.

⚠ COLUMN-MAJOR IS NOT WHAT SEVERAL EXISTING SOURCE HEADERS SAY.  Headers on
Bitmap_F54718_48x20, Bitmap_F17C59_24x17, Bitmap_F05CE0 and Bitmap_F54D7E_304x6
describe the same op-03 objects as "N bytes per ROW x M rows".  The SIZE those
give is right and the LAYOUT is the transpose of the truth.  Their `.byte` rows
are unaffected -- the bytes are the ROM's in ROM order either way -- so this is a
comment-level error, not a byte-level one, and the byte gate can never see it.
Measured, on the eight 48x15 widgets at 0xFC48D7: column-major draws connected
slider tracks and envelope curves, row-major draws disconnected noise
(`--probe`).

⚠ EDGE DENSITY CANNOT SETTLE GRID PHASE.  It settles column-vs-row-major (a
transpose) but not where a repeating grid starts: over the 67 used slots of the
0xF78028 glyph array the mean 4-neighbour edge density is 0.2450 aligned and
0.2477 / 0.2493 / 0.2512 at +12 / +24 / +36 bytes, and on the array whose
alignment is CERTAIN (0xF31EE1) the misaligned reading scores *better*
(0.0801 vs 0.0857).  Phase comes from the code that computes the address.

================================================================================
WHERE EACH GEOMETRY COMES FROM
================================================================================

Three kinds of evidence, in descending order, and every entry names its own:

1. AN OP-0x03 DISPLAY-LIST RECORD.  `03 0C` + ptr32 + IX16 + BC16 + HL16, run by
   DLHandler_FarPtr (prom_b 0xF31ABE), which loads those fields and issues
   service 3.  `census` re-derives all of them from the four ROM images:
   119 records, 30 distinct targets, and NOT ONE target carries two different
   BC/HL pairs.  ★ The false-positive floor is MEASURED, not assumed: the same
   scan run for 80 randomly chosen two-byte opcode pairs finds 0 plausible
   records, mean 0.00, max 0.  So `03 0C` + plausible fields is a test with no
   observed noise.
2. CONVERTED CODE THAT SETS BC/HL AND THE SOURCE ADDRESS LITERALLY -- the splash
   blits, DrawValueGlyph_24x24, DLHandler_Glyph24x24, and the two pointer tables
   at 0xF5BEFB and 0xF09B7B.  Each entry names the instruction address.
3. Nothing else.  A range with no record and no code naming it is REFUSED and
   listed in REFUSED below, however obviously it looks like a picture.

PNG convention: 1-bit PNG, INK = BLACK (0), background = WHITE (255).
"""
import argparse
import os
import pathlib
import re
import struct
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required:  pip install Pillow")

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent   # .../wsa1
ROMS = {
    'a': (0xF80000, ROOT / 'original_ROMs' / 'wsa1_prom_a.ic12'),
    'b': (0xF00000, ROOT / 'original_ROMs' / 'wsa1_prom_b.ic13'),
    'c': (0xF80000, ROOT / 'original_ROMs' / 'wsa1_prom_c.ic28'),
    'd': (0x000000, ROOT / 'original_ROMs' / 'wsa1_prom_d.bin'),
}
SOURCES = {'a': ROOT / 'prom_a' / 'wsa1_prom_a.s',
           'b': ROOT / 'prom_b' / 'wsa1_prom_b.s'}


def entry(name, img, addr, bc, hl, evidence, order='col'):
    return dict(name=name, img=img, addr=addr, bc=bc, hl=hl,
                order=order, evidence=evidence)


def build_manifest():
    m = []

    # ---------------------------------------------------------------- prom_a
    # The three full-screen splash images.  Each is named by its OWN blit site,
    # which sets BC and HL as literals; see notes/FINDINGS-prom_a-splash-bitmaps.md.
    for nm, ad, site in [('SplashImage_DitherA',  0xFF8000, 0xF94131),
                         ('SplashImage_DitherB',  0xFFA580, 0xF94142),
                         ('SplashImage_Wordmark', 0xFFCB00, 0xF941D3)]:
        m.append(entry(nm, 'a', ad, 40, 240,
                       f'blit site prom_a {site:06X}: ldw BC,0x0028 / ldw HL,0x00F0 / '
                       f'ldb A,0x03 / swi 7.  320x240 is the panel (SED1330 SYSTEM SET '
                       f'C/R=40, L/F=240)'))

    # Two op-03 targets inside prom_a, named by the record pair at 0xF82B54/0xF82B60.
    m.append(entry('Bitmap_F82BB0', 'a', 0xF82BB0, 8, 10,
                   'op-03 record prom_a 0xF82B54 (BC=8, HL=10)'))
    m.append(entry('Bitmap_F82C00', 'a', 0xF82C00, 4, 32,
                   'op-03 record prom_a 0xF82B60 (BC=4, HL=32)'))

    # Ten 16x129 objects named by ten consecutive op-03 records at 0xFE8E31..0xFE8E9D.
    # ★ They TILE: 0xFF17E2 + 10 * 258 = 0xFF21F6, and each record's pointer is
    #   exactly the previous one plus 258, so the record list and the address
    #   arithmetic agree without either being assumed.
    for i in range(10):
        ad = 0xFF17E2 + i * 258
        m.append(entry(f'Bitmap_{ad:06X}', 'a', ad, 2, 129,
                       f'op-03 record prom_a 0x{0xFE8E31 + i * 12:06X} (BC=2, HL=129); the ten '
                       f'records tile 0xFF17E2-0xFF21F5 with no gap'))

    # Eight 48x15 UI widgets, named by the 8-entry pointer table at prom_b 0xF09B7B
    # whose consumer at 0xF09B29 sets BC=6, HL=15 literally.  The table's index
    # table at 0xF09B3B is 64 bytes whose maximum value is 7, which is what fixes
    # the entry count at 8 -- the words after entry 7 are code, not pointers.
    # ⚠ THIS CONTRADICTS the committed header of Bitmap1bpp_FC48E4 -- see REFUSED.
    for i in range(8):
        ad = 0xFC48D7 + i * 90
        m.append(entry(f'Widget_{ad:06X}', 'a', ad, 6, 15,
                       f'pointer table prom_b 0xF09B7B[{i}] = 0x{ad:06X}, stride 90 = 6*15; '
                       f'the consumer at 0xF09B29 sets BC=6 / HL=15 / A=3 / swi 7'))

    # ---------------------------------------------------------------- prom_b
    # op-03 record targets inside prom_b (see `census`).
    for ad, bc, hl, ev in [
        (0xF0191A, 3, 10, 'op-03 records 0xF02F6A 0xF03A21 0xF03AD9 0xF03C29 0xF32834'),
        (0xF01938, 3, 10, 'op-03 records naming 0xF01938 (5)'),
        (0xF01956, 3, 10, 'op-03 records naming 0xF01956 (5)'),
        (0xF01974, 3, 10, 'op-03 records naming 0xF01974 (5)'),
        (0xF01992, 2, 12, 'op-03 records naming 0xF01992 (10)'),
        (0xF019AA, 2, 12, 'op-03 records 0xF03ACD 0xF03AE5 0xF03AFD 0xF03B15 0xF03B7F '
                          '0xF03B94 0xF03C1D 0xF03C35 0xF03C4D 0xF03C65'),
        (0xF05CE0, 2, 12, 'op-03 records 0xF02B97 0xF06307 0xF0631D'),
        (0xF13D00, 2, 12, 'op-03 records 0xF13F50 0xF13F5C'),
        (0xF13D18, 2, 12, 'op-03 records 0xF14311 0xF1431D'),
        (0xF13D30, 2, 12, 'op-03 record 0xF14556'),
        (0xF13D48, 2, 12, 'op-03 record 0xF1454A'),
        (0xF17C59, 3, 17, 'op-03 record 0xF1AAA9'),
        (0xF283A7, 5, 30, 'op-03 records naming 0xF283A7 (32)'),
        (0xF2843D, 2,  9, 'op-03 records naming 0xF2843D (17)'),
        (0xF2CAC3, 5, 30, 'op-03 records 0xF2C981 0xF2C98D 0xF2C999'),
        (0xF54718, 6, 20, 'op-03 records 0xF542ED 0xF54305'),
        (0xF54790, 6, 20, 'op-03 records naming 0xF54790 (2)'),
        (0xF54D7E, 38, 6, 'op-03 record 0xF54325'),
    ]:
        m.append(entry(f'Bitmap_{ad:06X}', 'b', ad, bc, hl, ev))

    # The byte-identical dead copy of 0xF54D7E.  Its geometry is not its own --
    # it is the SAME 228 bytes, and the source header says so.
    m.append(entry('Bitmap_F54EDA_DuplicateOf_F54D7E', 'b', 0xF54EDA, 38, 6,
                   'byte-identical to 0xF54D7E (op-03 record 0xF54325, BC=38 HL=6); nothing '
                   'names this copy -- the geometry is inherited from the original, not '
                   'independently established'))

    # Six 40x40 framed curves selected by the 7-entry table at 0xF5BEFB and blitted
    # by 0xF5BECE, which sets BC=5 / HL=40 literally.
    for i in range(6):
        ad = 0xF019C2 + i * 200
        m.append(entry(f'Curve_{ad:06X}', 'b', ad, 5, 40,
                       f'selector table 0xF5BEFB -> blitter 0xF5BECE: ldw BC,0x0005 / '
                       f'ldw HL,0x0028 / ldb A,0x03 / swi 7.  Six distinct targets, '
                       f'stride 200 = 5*40, tiling 0xF019C2-0xF01E71'))

    # The 29-entry value-glyph array.  DrawValueGlyph_24x24 (0xF31873) quantises
    # through 0xF31DED (max 0x1C = 28), indexes the 29-entry pointer table at
    # 0xF31E6D, and blits BC=3 / HL=24.  29*72 = 2088 and 0xF31EE1+2088 = 0xF32709,
    # the end of the block.
    for i in range(29):
        ad = 0xF31EE1 + i * 72
        m.append(entry(f'ValueGlyph_{i:02d}_{ad:06X}', 'b', ad, 3, 24,
                       f'DrawValueGlyph_24x24 (0xF31873): ldw BC,0x0003 / ldw HL,0x0018; '
                       f'pointer table 0xF31E6D[{i}]'))

    # The 119-entry display-list glyph array.  DLHandler_Glyph24x24 (0xF31ACE,
    # opcode 0x23) computes 0xF78028 + index*72 and blits BC=3 / HL=24.  The
    # highest index any op-23 record in the four images carries is 118.
    #
    # ★ THE COMPETING FRAMING IS SETTLED, AND THIS ONE WON.  An earlier REFUSED
    #   entry here said the 110 `Bitmap_F78*` labels -- extents taken from the
    #   pointer table at 0xF003F9 -- were "a SECOND, incompatible reading of the
    #   same bytes" and left it open.  Resolved by lane RQ-SHEET, 2026-09-02, on
    #   the consuming code and not on which reading draws nicer pictures:
    #     * the array ENDS ON THIS GRID -- the 0x0E padding starts at 0xF7A1A0
    #       and 0xF7A1A0 - 0xF78028 = 8568 = 119 * 72, remainder 0 -- and 119 is
    #       also max-index-118 plus one, two measurements of different things;
    #     * exactly 1 of the pointer table's 121 targets in the span is on the
    #       72-byte grid, against 1.7 by chance, so its targets carry NO
    #       information about it;
    #     * that table misses the same way in its OTHER target region (3 of 24
    #       on a proven DisplayList_FC4000 record boundary, against 1.8), and no
    #       immediate in any of the four images equals 0xF003F9.
    #   The 110 labels are gone from prom_b/wsa1_prom_b.s; see
    #   notes/gen_prom_b_f78028_icon_sheet.py --evidence --selftest.
    for i in range(119):
        ad = 0xF78028 + i * 72
        m.append(entry(f'DLGlyph_{i:03d}_{ad:06X}', 'b', ad, 3, 24,
                       f'DLHandler_Glyph24x24 (0xF31ACE): mul WA,0x0048 / ld XIY,0x00F78028 / '
                       f'ldw BC,0x0003 / ldw HL,0x0018.  index {i}; the highest index in any '
                       f'op-23 record across the four images is 118'))

    # Three small shapes with literal source addresses in converted code.
    m.append(entry('Glyph_F318EE', 'b', 0xF318EE, 1, 16,
                   'sub_F31899 0xF318B2: ld XIY,0x00F318EE / ldw BC,0x0001 / ldw HL,0x0010'))
    m.append(entry('Glyph_F318FE', 'b', 0xF318FE, 1, 16,
                   'sub_F31899 0xF318DE: ld XIY,0x00F318FE / ldw BC,0x0001 / ldw HL,0x0010'))
    m.append(entry('Bitmap_F31952', 'b', 0xF31952, 5, 15,
                   'sub_F3190E 0xF31942: ld XIY,0x00F31952 / ldw BC,0x0005 / ldw HL,0x000F'))

    # Four 24x24 glyphs byte-identical to entries of the 0xF31EE1 array (the
    # source header at 0xF17AE0 states the byte identity).
    for i in range(4):
        ad = 0xF17AE0 + i * 72
        m.append(entry(f'Bitmap_{ad:06X}', 'b', ad, 3, 24,
                       'byte-identical to 72-byte entries of the 0xF31EE1 value-glyph array '
                       '(BC=3, HL=24 from DrawValueGlyph_24x24); the geometry is inherited '
                       'from the identity, not independently established'))

    # The 80x24 line drawing.  ⚠ Its geometry is the WEAKEST here: no record and no
    # code names 0xF0D5BF.  BC=10 is a boundary argument (the run must end at
    # 0xF0D6AF; the only 24-aligned start that does not split the 0x01..0x21 ramp
    # is 0xF0D5BF).  Kept because that argument is written out in the source, and
    # flagged as inference.
    m.append(entry('Bitmap_F0D5BF_80x24', 'b', 0xF0D5BF, 10, 24,
                   '⚠ INFERRED, no record and no code names it: the run must end at '
                   '0xF0D6AF and 0xF0D5BF is the only 24-aligned start that does not '
                   'split the 0x01..0x21 ramp above it -- see the source header'))
    return m


# Ranges that LOOK like pictures and are deliberately NOT converted.
REFUSED = [
    ("prom_a 0xFC48E4-0xFC52F7 `Bitmap1bpp_FC48E4` (2,580 B)",
     "Its committed header reads the range as 172 rows x 15 bytes ROW-MAJOR, 120 px wide, "
     "from a 15-byte autocorrelation peak.  The peak is real but it is the COLUMN HEIGHT "
     "of a column-major object, not a row stride: the pointer table at prom_b 0xF09B7B "
     "names eight 90-byte objects at 0xFC48D7 stride 90 = 6 * 15, blitted BC=6 / HL=15.  "
     "Those eight (720 B) ARE exported, as Widget_FC48D7..; the remaining 1,860 B of the "
     "range is named by nothing and its object grid is unknown."),
    ("prom_b 0xF54808 Bitmap_DrawbarA / 0xF54AC3 Bitmap_DrawbarB (699 B each)",
     "The source header establishes 3 slices of 233 bytes blitted 1 byte x 0x7B rows with "
     "the source advanced by 233 -- so the drawn image is a 123-row WINDOW into a 233-row "
     "slice, at an offset the caller computes from the drawbar value.  What the other 110 "
     "rows of each slice are is not established, so there is no single rectangle to call "
     "the image."),
    ("prom_b 0xF17AE0 second/third/fourth 72-byte cells beyond the four listed",
     "The header states four cells; nothing establishes a fifth."),
]


def rom(img):
    base, path = ROMS[img]
    return base, path.read_bytes()


def rom_slice(e):
    base, data = rom(e['img'])
    off = e['addr'] - base
    n = e['bc'] * e['hl']
    if off < 0 or off + n > len(data):
        sys.exit(f"{e['name']}: 0x{e['addr']:06X}+{n} is outside prom_{e['img']}")
    return data[off:off + n]


def to_grid(data, bc, hl, order):
    w, h = bc * 8, hl
    g = [[0] * w for _ in range(h)]
    for i, b in enumerate(data):
        if order == 'col':
            c, r = divmod(i, hl)
        else:
            r, c = divmod(i, bc)
        for k in range(8):
            if b >> (7 - k) & 1:
                g[r][8 * c + k] = 1
    return g


def from_grid(g, bc, hl, order):
    out = bytearray(bc * hl)
    for r in range(hl):
        for c in range(bc):
            b = 0
            for k in range(8):
                if g[r][8 * c + k]:
                    b |= 0x80 >> k
            out[c * hl + r if order == 'col' else r * bc + c] = b
    return bytes(out)


def png_path(e):
    return ROOT / f"prom_{e['img']}" / 'images' / f"{e['name']}.png"


def grid_to_png(g, path):
    h, w = len(g), len(g[0])
    img = Image.new('1', (w, h), 1)          # 1 = white background
    px = img.load()
    for y in range(h):
        for x in range(w):
            if g[y][x]:
                px[x, y] = 0                 # ink is BLACK
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def png_to_grid(path, w, h):
    img = Image.open(path).convert('1')
    if img.size != (w, h):
        sys.exit(f"{path.name}: expected {w}x{h}, PNG is {img.size[0]}x{img.size[1]}")
    px = img.load()
    return [[1 if px[x, y] == 0 else 0 for x in range(w)] for y in range(h)]


# --------------------------------------------------------------------------
# The address -> `.byte` value map, used by `check` and `rewrite`.
#
# ⚠ THE STALE-MAP GUARD the lane brief demands: every mapped byte is compared
#   against the ROM byte at the same address before anything is written, so a
#   map built from a source revision that does not match the ROM refuses instead
#   of silently patching the wrong bytes.
# --------------------------------------------------------------------------
BYTE_LINE = re.compile(r'^(\s*\.byte\s+)(.*?)((?:\s*;.*)?)$')
# ⚠ A COMMENT-ONLY LINE IS NOT A POSITION MARKER.  The first version of this
# regex accepted any `; <6 hex>` anywhere, and picked up the prose line
# `;          0xF319E9 is the literal ASCII "0123456789ABCDEF"` as an anchor --
# which shifted the whole 75-byte bitmap at 0xF31952 by 0x4C.  The map guard
# caught it (every byte was discarded), which is exactly what the guard is for,
# but the fix is to require the hint to be a TRAILING comment on a line that
# emits something.
ADDR_HINT = re.compile(r'^[^;]*\S[^;]*;\s*(?:0x)?([0-9A-F]{6})\b')
HEXVAL = re.compile(r'^0x[0-9A-Fa-f]{1,2}$')
DIRECTIVE = re.compile(r'^\s*\.([a-z_0-9]+)\b(.*)$')
LABEL_ONLY = re.compile(r'^\s*[.A-Za-z_][\w.]*:\s*(?:;.*)?$')
ASCII_LIT = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*(?:;.*)?$')
FILL_ARGS = re.compile(r'^\s*(\d+)\s*,\s*(\d+)\s*,')


def _line_size(line):
    """Bytes this line emits, or None if this script cannot say."""
    if LABEL_ONLY.match(line):
        return 0
    s = line.strip()
    if not s or s.startswith(';'):
        return 0
    m = DIRECTIVE.match(line)
    if not m:
        return None                      # an instruction: size unknown here
    d, rest = m.group(1), m.group(2)
    rest = rest.split(';')[0] if d != 'ascii' else rest
    if d == 'byte':
        return len([v for v in rest.split(',') if v.strip()])
    if d in ('short', 'word'):
        return 2 * len([v for v in rest.split(',') if v.strip()])
    if d == 'long':
        return 4 * len([v for v in rest.split(',') if v.strip()])
    if d == 'ascii':
        am = ASCII_LIT.match(rest)
        if not am:
            return None
        body = am.group(1)
        # count characters, collapsing backslash escapes to one byte each
        n = i = 0
        while i < len(body):
            i += 2 if body[i] == '\\' else 1
            n += 1
        return n
    if d == 'fill':
        fm = FILL_ARGS.match(rest)
        return int(fm.group(1)) * int(fm.group(2)) if fm else None
    return None


def source_map(img):
    """address -> (line index, value index) over the `.byte` lines of prom_<img>.

    ⚠ ONLY 8,756 of prom_b's 22,144 `.byte` lines carry a trailing address
    comment, so the map is built by PROPAGATING an address forward and backward
    across lines whose size this script can compute, anchored on every line that
    does carry one.  Propagation can be wrong -- so every mapped byte is then
    checked against the ROM byte at the address it was given, and any that
    disagrees is DISCARDED rather than trusted.  That is the brief's stale-map
    guard applied to the map's own construction: what survives is only the part
    of the map the ROM itself confirms.
    """
    base, rom_data = rom(img)
    lines = SOURCES[img].read_text(encoding='latin-1').split('\n')
    sizes = [_line_size(l) for l in lines]
    hints = []
    for l in lines:
        m = ADDR_HINT.search(l)
        hints.append(int(m.group(1), 16) if m else None)

    addr_of = [None] * len(lines)
    cur = None
    for i in range(len(lines)):                       # forward
        if hints[i] is not None:
            cur = hints[i]
        addr_of[i] = cur
        cur = None if (cur is None or sizes[i] is None) else cur + sizes[i]
    cur = None
    for i in range(len(lines) - 1, -1, -1):           # backward
        if hints[i] is not None:
            cur = hints[i]
        elif cur is not None and sizes[i] is not None:
            cur -= sizes[i]
        else:
            cur = None
        if addr_of[i] is None:
            addr_of[i] = cur

    amap = {}
    dropped = 0
    for li, line in enumerate(lines):
        if addr_of[li] is None:
            continue
        m = BYTE_LINE.match(line)
        if not m:
            continue
        vals = [v.strip() for v in m.group(2).split(',')]
        if not all(HEXVAL.match(v) for v in vals):
            continue
        for vi, v in enumerate(vals):
            a = addr_of[li] + vi
            off = a - base
            if not (0 <= off < len(rom_data)) or rom_data[off] != int(v, 16):
                dropped += 1                          # the guard, not an assumption
                continue
            amap[a] = (li, vi)
    return lines, amap, dropped


def patch_lines(lines, amap, addr, data, rom_data, base, who, apply_):
    """Return the number of value slots this range would change; optionally apply."""
    changed = 0
    per_line = {}
    for i, b in enumerate(data):
        a = addr + i
        if a not in amap:
            sys.exit(f"{who}: 0x{a:06X} is not covered by any plain `.byte` line -- "
                     f"refusing (the range may be `.incbin`, `.word`, or split across "
                     f"a directive this map does not read)")
        li, vi = amap[a]
        # STALE-MAP GUARD: what the source line says must be what the ROM says.
        cur = int([v.strip() for v in BYTE_LINE.match(lines[li]).group(2).split(',')][vi], 16)
        if cur != rom_data[a - base]:
            sys.exit(f"{who}: source line {li + 1} claims 0x{cur:02X} at 0x{a:06X} but the "
                     f"ROM holds 0x{rom_data[a - base]:02X} -- the map is stale, refusing")
        if cur != b:
            changed += 1
        per_line.setdefault(li, []).append((vi, b))
    if apply_:
        for li, updates in per_line.items():
            m = BYTE_LINE.match(lines[li])
            raw = m.group(2).split(',')
            # ⚠ REWRITE ONLY THE SLOTS THAT ACTUALLY CHANGE.  Re-spelling every
            # value on a touched line turned a one-byte edit into a 136-line diff
            # (0x0f -> 0x0F across neighbouring rows), which is exactly the
            # "check the diff SIZE against what you intended" failure the lane
            # brief's latin-1 addendum describes.
            dirty = False
            for vi, b in updates:
                if int(raw[vi].strip(), 16) != b:
                    lead = raw[vi][:len(raw[vi]) - len(raw[vi].lstrip())]
                    raw[vi] = lead + f'0x{b:02X}'
                    dirty = True
            if dirty:
                lines[li] = m.group(1) + ','.join(raw) + m.group(3)
    return changed


# --------------------------------------------------------------------------
def cmd_census(_):
    """Re-derive every op-03 record from the four ROMs and check the manifest."""
    import collections
    import random
    hits = collections.defaultdict(set)
    total = 0
    for k, (base, path) in ROMS.items():
        d = path.read_bytes()
        for i in range(len(d) - 12):
            if d[i] == 0x03 and d[i + 1] == 0x0C:
                ptr = struct.unpack_from('<I', d, i + 2)[0]
                bc = struct.unpack_from('<H', d, i + 8)[0]
                hl = struct.unpack_from('<H', d, i + 10)[0]
                if (ptr >> 24) or not (0xF00000 <= ptr < 0x1000000):
                    continue
                if not (1 <= bc <= 80 and 1 <= hl <= 512):
                    continue
                total += 1
                hits[ptr].add((bc, hl))
    print(f"op-03 records found: {total}   distinct targets: {len(hits)}")
    amb = {p: v for p, v in hits.items() if len(v) > 1}
    print(f"targets carrying more than one BC/HL pair: {len(amb)}")
    assert not amb, amb

    # The measured false-positive floor.
    random.seed(1)
    worst = 0
    trials = 0
    for k, (base, path) in ROMS.items():
        d = path.read_bytes()
        for _ in range(20):
            o1, o2 = random.randrange(256), random.randrange(256)
            if (o1, o2) == (0x03, 0x0C):
                continue
            c = 0
            for i in range(len(d) - 12):
                if d[i] == o1 and d[i + 1] == o2:
                    ptr = struct.unpack_from('<I', d, i + 2)[0]
                    bc = struct.unpack_from('<H', d, i + 8)[0]
                    hl = struct.unpack_from('<H', d, i + 10)[0]
                    if (ptr >> 24) or not (0xF00000 <= ptr < 0x1000000):
                        continue
                    if 1 <= bc <= 80 and 1 <= hl <= 512:
                        c += 1
            worst = max(worst, c)
            trials += 1
    print(f"NULL: same scan for {trials} random two-byte opcode pairs -> worst {worst} "
          f"plausible records")
    assert worst == 0, "the record test now has a nonzero false-positive floor"

    man = {e['addr']: e for e in build_manifest()}
    missing = [p for p in hits if p not in man]
    wrong = [(p, sorted(hits[p])[0], (man[p]['bc'], man[p]['hl']))
             for p in hits if p in man and sorted(hits[p])[0] != (man[p]['bc'], man[p]['hl'])]
    for p in sorted(missing):
        print(f"  ⚠ op-03 target 0x{p:06X} {sorted(hits[p])} is NOT in the manifest")
    for p, got, want in wrong:
        print(f"  ⚠ 0x{p:06X}: records say {got}, manifest says {want}")
    assert not missing and not wrong
    print("every op-03 target is in the manifest with the record's own BC/HL")
    return 0


def cmd_probe(_):
    """Report 4-neighbour edge density both ways for every entry."""
    print(f"{'name':44s} {'geometry':>10s} {'col-major':>10s} {'row-major':>10s}")
    for e in build_manifest():
        d = rom_slice(e)
        def dens(order):
            g = to_grid(d, e['bc'], e['hl'], order)
            h, w = len(g), len(g[0])
            n = t = 0
            for y in range(h):
                for x in range(w):
                    if x + 1 < w:
                        t += 1; n += g[y][x] != g[y][x + 1]
                    if y + 1 < h:
                        t += 1; n += g[y][x] != g[y + 1][x]
            return n / t if t else 0.0
        print(f"{e['name']:44s} {e['bc'] * 8:4d}x{e['hl']:<5d} "
              f"{dens('col'):10.4f} {dens('row'):10.4f}")
    return 0


def cmd_export(_):
    n = 0
    for e in build_manifest():
        grid_to_png(to_grid(rom_slice(e), e['bc'], e['hl'], e['order']), png_path(e))
        n += 1
    print(f"exported {n} PNGs")
    return 0


def cmd_verify(_):
    bad = 0
    tot = 0
    for e in build_manifest():
        p = png_path(e)
        if not p.exists():
            print(f"  MISSING {p}")
            bad += 1
            continue
        g = png_to_grid(p, e['bc'] * 8, e['hl'])
        got = from_grid(g, e['bc'], e['hl'], e['order'])
        want = rom_slice(e)
        tot += len(want)
        if got != want:
            i = next(k for k in range(len(want)) if got[k] != want[k])
            print(f"  MISMATCH {e['name']} at 0x{e['addr'] + i:06X}: "
                  f"PNG says 0x{got[i]:02X}, ROM holds 0x{want[i]:02X}")
            bad += 1
    print(f"verify: {len(build_manifest())} images, {tot:,} bytes, {bad} failures")
    return 1 if bad else 0


def _rewrite(apply_):
    man = build_manifest()
    total_changed = 0
    for img in sorted({e['img'] for e in man}):
        lines, amap, dropped = source_map(img)
        base, data = rom(img)
        changed = 0
        for e in man:
            if e['img'] != img:
                continue
            g = png_to_grid(png_path(e), e['bc'] * 8, e['hl'])
            changed += patch_lines(lines, amap, e['addr'],
                                   from_grid(g, e['bc'], e['hl'], e['order']),
                                   data, base, e['name'], apply_)
        if apply_ and changed:
            tmp = SOURCES[img].with_suffix('.s.tmp')
            tmp.write_text('\n'.join(lines), encoding='latin-1')
            os.replace(tmp, SOURCES[img])
        print(f"prom_{img}: {changed} `.byte` value(s) "
              f"{'rewritten' if apply_ else 'would change'}"
              f"   (map guard discarded {dropped:,} unconfirmed slots)")
        total_changed += changed
    return total_changed


def cmd_check(_):
    n = _rewrite(False)
    if n:
        print(f"check FAILED: the committed source does not match the PNGs in {n} places")
        return 1
    print("check: every listed range in the assembly is exactly what its PNG says")
    return 0


def cmd_rewrite(_):
    _rewrite(True)
    return 0


def cmd_list(_):
    man = build_manifest()
    tot = sum(e['bc'] * e['hl'] for e in man)
    print(f"{len(man)} images, {tot:,} bytes of pixel data\n")
    for e in man:
        print(f"{e['name']:44s} prom_{e['img']} 0x{e['addr']:06X}  "
              f"BC={e['bc']:3d} HL={e['hl']:4d}  {e['bc'] * 8}x{e['hl']}  "
              f"{e['bc'] * e['hl']:6d} B")
        print(f"    evidence: {e['evidence']}")
    print("\nREFUSED -- looks like a picture, geometry not established:")
    for what, why in REFUSED:
        print(f"  * {what}\n      {why}")
    return 0


# --------------------------------------------------------------------------
# Browsing aids.  ⚠ DERIVED, not authoritative: every one of these is rebuilt
# from the per-range PNGs by `sheet`, they are never read back, and nothing in
# the build depends on them.  They exist because 204 files of 16x12 are not
# something a person can actually look through, and because the splash
# COMPOSITE is a picture that neither of its two halves shows.
# --------------------------------------------------------------------------
SHEETS = [
    ('b', 'CONTACT_DLGlyph_IconSheet',   'DLGlyph_*.png',     12, 2,
     "the 119-cell 24x24 UI icon sheet at 0xF78028"),
    ('b', 'CONTACT_ValueGlyph',          'ValueGlyph_*.png',  10, 2,
     "the 29-step rotary knob at 0xF31EE1"),
    ('b', 'CONTACT_Curve',               'Curve_*.png',        6, 2,
     "the six 40x40 response curves at 0xF019C2"),
    ('a', 'CONTACT_KeyboardRuler',       'Bitmap_FF*.png',    10, 2,
     "the ten 16x129 keyboard strips at 0xFF17E2, C-2 through C8"),
    ('a', 'CONTACT_Widget',              'Widget_*.png',       4, 3,
     "the eight 48x15 pictograms at 0xFC48D7"),
]


def cmd_sheet(_):
    import glob
    for img, name, pat, cols, scale, what in SHEETS:
        d = ROOT / f'prom_{img}' / 'images'
        files = sorted(glob.glob(str(d / pat)))
        if not files:
            continue
        ims = [Image.open(f).convert('L') for f in files]
        w = max(i.width for i in ims)
        h = max(i.height for i in ims)
        rows = (len(ims) + cols - 1) // cols
        pad = 2
        S = Image.new('L', (cols * (w + pad) + pad, rows * (h + pad) + pad), 160)
        for k, i in enumerate(ims):
            S.paste(i, (pad + (k % cols) * (w + pad), pad + (k // cols) * (h + pad)))
        S = S.resize((S.width * scale, S.height * scale), Image.NEAREST)
        S.save(d / f'{name}.png')
        print(f"  {name}.png  {len(ims)} cells -- {what}")

    # ★ The splash COMPOSITE.  DitherA and DitherB are disjoint half-tones the
    #   SED1330 OR-composites across two layers, so neither file alone is the
    #   picture the user sees; this is.  (AND of the two = 0, popcounts equal.)
    d = ROOT / 'prom_a' / 'images'
    a = Image.open(d / 'SplashImage_DitherA.png').convert('L')
    b = Image.open(d / 'SplashImage_DitherB.png').convert('L')
    comp = Image.new('L', a.size)
    pa, pb, pc = a.load(), b.load(), comp.load()
    for y in range(a.height):
        for x in range(a.width):
            pc[x, y] = 0 if (pa[x, y] == 0 or pb[x, y] == 0) else 255
    comp.save(d / 'CONTACT_SplashImage_Composite.png')
    print("  CONTACT_SplashImage_Composite.png  -- DitherA OR DitherB, the picture "
          "the panel actually shows: `WSA`")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('command', choices=['census', 'probe', 'export', 'verify',
                                        'check', 'rewrite', 'list', 'sheet'])
    a = ap.parse_args()
    return globals()['cmd_' + a.command](a)


if __name__ == '__main__':
    sys.exit(main())
