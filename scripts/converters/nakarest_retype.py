#!/usr/bin/env python3
r"""nakarest_retype.py -- type the objects inside lane `nakarest`'s NAKA blob C
sources, and write the matching evidence header above each .s slice label.

QUESTION ANSWERED
-----------------
The NAKA blob sources this lane owns (`v10/maincpu/ui_widgets/naka_*.c`, with
v9/v7 copies) were generated with one anonymous `uint16_t field_XXXX` per word
across whole blobs -- including 8 bpp bitmaps, 1 bpp glyph strips and
records.  For every object listed in OBJECTS below this driver:

  * re-expresses the member run covering it in the C as a typed member (a
    bitmap as `uint8_t name[height][stride]`, ...) with a header comment
    naming the code that reads it and how the shape was pinned, using the
    structural editor scripts/converters/nakarest_c_model.py; and
  * writes the same evidence directly above the object's `.s` slice label
    (`Label: .incbin "includes/generated/<blob>.bin", off, len`), between
    marker lines, so a re-run replaces its own header and nothing else.

The object's offset and length are read from the .s slice label, never typed
in; each entry's stated shape is checked against the slice length.

Values come from the blob COMPILED FROM THAT VERSION'S OWN C (a scratch
compile, the same clang/ld.lld/objcopy recipe as the Makefile), not from
includes/generated -- v7's generated bins are patched in place by
apply_v7_c_divergence.py after compilation, so they are not what the C says.
`make gate` certifies the result.

RUN
    python3 scripts/converters/nakarest_retype.py                 # dry run
    python3 scripts/converters/nakarest_retype.py --apply         # v10, v9, v7
    python3 scripts/converters/nakarest_retype.py --render DIR    # PNG of every
                                                                  # 8 bpp bitmap
    make gate

The PNG render is how the dimensions were checked by eye: a wrong width shears
the picture, a right one shows the drawing.
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import nakarest_c_model as M  # noqa: E402

# Types this driver defines LOCALLY in the .c files it edits (naka_types.h
# belongs to lane nakabig), with their sizes for the structural editor.
LOCAL_TYPES = {
    'welcome_step_t': (12, '''/* One step of the welcome-screen animation script (12 bytes).
 * Walked by AcWelcomScreenProc (ui/drawbar_panel_ui.s): the current step
 * index lives at 0x024784, the table pointer at 0x024786, and a step is
 * reached as table + 12*index.  AcWelcomScreen_Select_NextStep hands `delay`
 * to SetApTimer (0 = run the next step at once); AcWelcomScreen_Select
 * dispatches on `op` (0..12 through a 13-entry jump table, anything else is
 * skipped) with the address of `arg` in xde; the single-glyph ops copy
 * {x, y} to their frame (lda xix, xsp+12; ldiw; ldiw) as the draw position
 * and push `arg` as DrawBitmapSP2's colour (a palette index). */
typedef struct __attribute__((packed)) {
    uint32_t delay;  /* +0  SetApTimer duration before this step runs */
    int16_t  x;      /* +4  draw position / op operand */
    int16_t  y;      /* +6 */
    int16_t  op;     /* +8  jump-table index 0..12 */
    uint16_t arg;    /* +10 op operand; the glyph ops' colour */
} welcome_step_t;
'''),
}
LOCAL_TYPES['mst_title_ref_t'] = (6, '''/* One entry of StyleSong_MasterTable (6 bytes): a title and its id.
 * Readers (ui/ui_mode_handlers.s): the MasterSetup dial handlers index the
 * table with 6*k (muls wa, 0x6), load +0 and Strcpy the title into the view;
 * the cell-select paths of MasterSetup and MstStyleAlp load the u16 at +4
 * (StyleSong_MasterTable_0x4 = table + 4, same 6*k index) and pass it as xde
 * to MainFuncCall(0x142000D, 0x1E20018). */
typedef struct __attribute__((packed)) {
    uint32_t title;  /* +0 pointer to a 34-byte entry of StyleSong_Titles */
    uint16_t id;     /* +4 0..999, each exactly once */
} mst_title_ref_t;
''')
for _t, (_n, _txt) in LOCAL_TYPES.items():
    M.TYPE_SIZES[_t] = _n

VERSIONS = ('v10', 'v9', 'v7')
LLVM = os.path.expanduser('~/compartilhado/llvm-project/build/bin')
S_FOR = {
    'naka_technichord_strings': 'technichord_string_data.s',
    'naka_style_bitmaps': 'style_bitmaps.s',
}

# ------------------------------------------------------------------ addresses
_NM = {}


def _nm(v):
    """name -> address from rebuilt_ROMs/kn5000_<v>_program.llvm.elf."""
    if v not in _NM:
        elf = os.path.join(ROOT, 'rebuilt_ROMs', 'kn5000_%s_program.llvm.elf' % v)
        out = subprocess.run([os.path.join(LLVM, 'llvm-nm'), '--defined-only', elf],
                             capture_output=True, text=True, check=True).stdout
        d = {}
        for ln in out.split('\n'):
            f = ln.split()
            if len(f) == 3 and f[1] in 'tT':
                d.setdefault(f[2], int(f[0], 16))
        _NM[v] = d
    return _NM[v]


def a(name):
    """`Name (0xADDR in v10/v9/v7)` or per-version addresses."""
    v = tuple(_nm(ver).get(name) for ver in VERSIONS)
    if v[0] is None:
        raise SystemExit('cannot resolve %s in the v10 ELF' % name)
    h = lambda x: '0x%06X' % x
    if v[2] is None:
        return '%s (v10 %s, v9 %s, not labelled in v7)' % (name, h(v[0]), h(v[1]))
    if v[0] == v[1] == v[2]:
        return '%s (%s in v10/v9/v7)' % (name, h(v[0]))
    if v[0] == v[1]:
        return '%s (v10/v9 %s, v7 %s)' % (name, h(v[0]), h(v[2]))
    return '%s (v10 %s, v9 %s, v7 %s)' % (name, h(v[0]), h(v[1]), h(v[2]))


def fmt(text):
    return re.sub(r'\{([A-Za-z_0-9]+)\}', lambda m: a(m.group(1)), text)


def wrap(text, width=70):
    out = []
    for para in text.split('\n\n'):
        out.append(textwrap.fill(' '.join(para.split()), width=width,
                                 break_long_words=False, break_on_hyphens=False))
    return '\n\n'.join(out)


# ------------------------------------------------------------------ evidence
DRAW_8BPP = (
    "Pixel format, from {DrawBitmapSPFast_Impl}: 8 bpp, one palette index per "
    "byte (palette: Palette_8bit_RGBA), rows top to bottom.  The routine copies "
    "`width` bytes per row to VRAM 0x43C00 + 320*y + x with Mem_Copy and then "
    "advances the source by (width + 1) & ~1, so a row occupies the width "
    "rounded up to even; the pad byte of an odd-width row is never drawn.")

USERBITMAP = (
    "Drawn by the UserBitmap view class: {VwUserBitmapProc}, on paint "
    "(0x1C0000D), calls the instance's function (+22 of the instance) with "
    "0x1E000A1 (address), 0x1E000A2 (width) and 0x1E000A3 (height) through "
    "ApFuncCall and hands the three to {DrawBitmapSPFast}.")


APFUNC = (
    "  The routine is one entry of the 44-entry ApFunction table that "
    "{InitializeMurai} registers with RegObjTabl 0x1600002, ApFunctionProc, "
    "0x2C, 0xE8070A, slot 0x121 (naka_widget_tables_2.c member ptrs_341); "
    "its name string \"%s\" sits in the parallel name table at 0xE807BE, "
    "slot 0x421.")
APFUNC_TOSHI = (
    "  The routine is entry %d of the 42-entry ApFunction table that "
    "{InitializeToshi} registers with RegObjTabl 0x1600002, ApFunctionProc, "
    "0x2A, 0xED1C9E, slot 0x122 (extensions/extension_data.s, still raw "
    "bytes there); its name string \"%s\" is entry %d of the parallel name "
    "table NoteNameStr_Table_5, slot 0x422.")


def userbitmap(proc, w, h, extra=''):
    return ("{%s} answers 0x1E000A1 with this address, 0x1E000A2 with 0x%X "
            "(width %d) and 0x1E000A3 with 0x%X (height %d).%s  " % (proc, w, w, h, h, extra)
            + USERBITMAP)


def bitmap(label, w, h, blob, who, shows):
    stride = (w + 1) & ~1
    return dict(kind='bitmap', blob=blob, label=label, w=w, h=h, stride=stride,
                who=who, shows=shows)


DRAWBAR_SLIDER = (
    "Width and height: one of three near-identical handlers in "
    "ui/drawbar_panel_ui.s that "
    "start at {Bitmap_QueryProperties3x} (the first is labelled; the second "
    "and third follow it unlabelled): each answers 0x1E000A1 with one slider "
    "bitmap's address, 0x1E000A2 with 22 (width) and 0x1E000A3 with 222 "
    "(height), which is how the 22 x 222 shape is pinned.  None of the three "
    "handler entry points (0xF7B4F1, 0xF7B51E, 0xF7B54B in v10) occurs as a "
    "32-bit or 24-bit little-endian value anywhere in the v10 program, table "
    "data, custom data or HD-AE5000 images (searched 2026-09-25): what reaches "
    "them, if anything, was not found.  The bitmaps themselves are "
    "also pointed at by a 9-entry table inside Naka_DrawbarSlider_Resources "
    "(naka_sequencer_channels.c member ptrs_5, 0xEEEFCC) in the order "
    "1,1,2,2,3,2,3,3,2 -- the colour sequence of the nine organ drawbars "
    "(16' and 5 1/3' brown; 8', 4' white; 2 2/3' black; 2' white; 1 3/5' and "
    "1 1/3' black; 1' white), which matches the renders: _1 has a brown "
    "handle, _2 white, _3 black.  The reader of that table was not traced.")

OBJECTS = [
    bitmap('Bitmap_Accita16', 120, 95, 'naka_technichord_strings',
           userbitmap('BitmapAccita16', 120, 95,
                      APFUNC % 'BitmapAccita16'),
           "A piano accordion, body red, bellows black, keyboard on the "
           "left, on the green (index 0xF7) background.  Same drawing as "
           "Bitmap_Accger16 with a different body colour; 'ita'/'ger' in the "
           "firmware's names presumably mean Italian/German -- an inference "
           "from the names, not from code."),
    bitmap('Bitmap_Accger16', 120, 95, 'naka_technichord_strings',
           userbitmap('BitmapAccger16', 120, 95,
                      APFUNC % 'BitmapAccger16'),
           "The same piano accordion as Bitmap_Accita16 with the body "
           "grey instead of red."),
    bitmap('Bitmap_SomeArrows', 294, 6, 'naka_technichord_strings',
           userbitmap('BitmapDrawsw', 294, 6,
                      APFUNC % 'BitmapDrawsw'),
           "A 294 x 6 strip of red slanted wedge marks on the green "
           "background, spaced unevenly across the width.  What it marks on "
           "screen was not traced (the instance that uses BitmapDrawsw was not "
           "followed); the label name Bitmap_SomeArrows predates this header."),
    bitmap('Bitmap_DrawbarNumberedSlider_1', 22, 222, 'naka_technichord_strings',
           DRAWBAR_SLIDER, "A drawbar: a black scale numbered 8 (top) to 1 "
           "with tick marks, above a BROWN (dark red) handle and a grey "
           "shaft."),
    bitmap('Bitmap_DrawbarNumberedSlider_2', 22, 222, 'naka_technichord_strings',
           DRAWBAR_SLIDER, "The same drawbar with a WHITE handle."),
    bitmap('Bitmap_DrawbarNumberedSlider_3', 22, 222, 'naka_technichord_strings',
           DRAWBAR_SLIDER, "The same drawbar with a BLACK handle."),
    bitmap('Bitmap_Technics_Logo', 312, 45, 'naka_technichord_strings',
           userbitmap('BitmapTechnics', 312, 45,
                      APFUNC % 'BitmapTechnics'),
           "The word Technics in the brand's serif logotype, black on "
           "green."),
    bitmap('Bitmap_KN5000_Logo', 199, 36, 'naka_technichord_strings',
           userbitmap('BitmapKn5000', 199, 36,
                      APFUNC % 'BitmapKn5000'),
           "'KN-5000' in black italic sans-serif on green."),
    bitmap('Bitmap_FadeInPicture', 112, 25, 'naka_style_bitmaps',
           userbitmap('BitmapFinpic', 112, 25, APFUNC_TOSHI % (22, 'BitmapFinpic', 22)),
           "A horizontal wedge that widens from a point at the left to full height at the right (a crescendo shape), dark grey with a black outline on the mid-grey background."),
    bitmap('Bitmap_FadeInText', 80, 18, 'naka_style_bitmaps',
           userbitmap('BitmapFinst', 80, 18, APFUNC_TOSHI % (23, 'BitmapFinst', 23)),
           "'FADE IN' in dark red italic capitals on grey."),
    bitmap('Bitmap_FadeOutPicture', 113, 25, 'naka_style_bitmaps',
           userbitmap('BitmapFoutpic', 113, 25, APFUNC_TOSHI % (24, 'BitmapFoutpic', 24)),
           "The mirror image of Bitmap_FadeInPicture: the wedge is full height at the left and narrows to a point at the right."),
    bitmap('Bitmap_FadeOutText', 108, 20, 'naka_style_bitmaps',
           userbitmap('BitmapFoutst', 108, 20, APFUNC_TOSHI % (25, 'BitmapFoutst', 25)),
           "'FADE OUT' in teal italic capitals on grey."),
]


def bitmap_header(o):
    title = ('%s  --  %d x %d bitmap, 8 bpp, row stride %d, %d bytes'
             % (o['label'], o['w'], o['h'], o['stride'], o['stride'] * o['h']))
    body = '\n\n'.join([
        'What it shows (render): ' + o['shows'],
        'Reader: ' + fmt(o['who']),
        fmt(DRAW_8BPP),
        "Dimensions pinned twice: the reader's own width/height constants, "
        "and width-rounded-to-even x height == the slice length.  A PNG render "
        "(scripts/converters/nakarest_retype.py --render DIR) shows the drawing "
        "upright; a wrong width would shear it.",
    ])
    return title + '\n\n' + wrap(body)


# ------------------------------------------------------------------ plumbing
def ui(v):
    return os.path.join(ROOT, v, 'maincpu', 'ui_widgets')


def compile_blob(v, blob):
    """The bytes the version's C compiles to (Makefile recipe, scratch dir)."""
    with tempfile.TemporaryDirectory() as t:
        o, elf, b = (os.path.join(t, 'x' + s) for s in ('.o', '.elf', '.bin'))
        subprocess.run([os.path.join(LLVM, 'clang'), '-target', 'tlcs900', '-ffreestanding',
                        '-c', '-O2', '-I', ui(v), '-o', o, os.path.join(ui(v), blob + '.c')],
                       check=True)
        subprocess.run([os.path.join(LLVM, 'ld.lld'), '-e', '0', '-T',
                        os.path.join(ui(v), blob + '_link.ld'), '-o', elf, o], check=True)
        subprocess.run([os.path.join(LLVM, 'llvm-objcopy'), '-O', 'binary', '-j', '.text',
                        elf, b], check=True)
        return open(b, 'rb').read()


def s_slices(spath, blob):
    """label -> (offset, length) for every label directly above an .incbin
    of `blob` (several labels may name one slice)."""
    lines = open(spath, encoding='latin-1').read().split('\n')
    out, pend = {}, []
    rx = re.compile(r'^\t\.incbin "includes/generated/%s\.bin", (0x[0-9A-Fa-f]+|\d+), '
                    r'(0x[0-9A-Fa-f]+|\d+)\s*$' % re.escape(blob))
    for ln in lines:
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$', ln)
        if m:
            pend.append(m.group(1))
            continue
        m = rx.match(ln)
        if m:
            for p in pend:
                out[p] = (int(m.group(1), 0), int(m.group(2), 0))
            pend = []
        elif ln.strip() and not ln.lstrip().startswith(';'):
            pend = []
    return out


def render(d, o, pix):
    from PIL import Image
    os.makedirs(d, exist_ok=True)
    p = open(os.path.join(ROOT, 'v10/maincpu/images/Palette_8bit_RGBA.bin'), 'rb').read()
    pal = b''.join(p[i:i + 3] for i in range(0, 1024, 4))
    w, h, st = o['w'], o['h'], o['stride']
    img = Image.new('P', (w, h))
    img.frombytes(b''.join(pix[y * st:y * st + w] for y in range(h)))
    img.putpalette(pal)
    img = img.convert('RGB').resize((w * 3, h * 3), Image.NEAREST)
    img.save(os.path.join(d, o['label'] + '.png'))


def prune_externs(cpath, before):
    """An extern the source used as NAKA_ADDR(...) before this pass and no
    longer uses at all was a false pointer inside a retyped object (pixel
    bytes FF FF FF 00 read as NakaData_RomEnd = 0x00FFFFFF, say): drop its
    declaration and its linker-script definition."""
    after = open(cpath, encoding='latin-1').read()
    ldpath = cpath[:-2] + '_link.ld'
    ld = open(ldpath, encoding='latin-1').read()
    gone = []
    for sym in re.findall(r'^extern const char ([A-Za-z0-9_]+);$', after, re.M):
        was = before.count('NAKA_ADDR(%s)' % sym)
        now = len(re.findall(r'\b%s\b' % re.escape(sym), after)) - 1
        if was and now == 0:
            gone.append(sym)
            after = re.sub(r'^extern const char %s;\n' % re.escape(sym), '', after, flags=re.M)
            ld = re.sub(r'^%s = 0x[0-9A-Fa-f]+;\n' % re.escape(sym), '', ld, flags=re.M)
    if gone:
        open(cpath, 'w', encoding='latin-1', newline='').write(after)
        open(ldpath, 'w', encoding='latin-1', newline='').write(ld)
    return gone


class Piece:
    """One object of a REGIONS entry: C member `name` (None = leave the C
    alone, .s only), at blob offset `off`, `size` bytes, with `header` text
    (None = no header) and the .s `labels` it carries (existing labels that
    other files reference MUST be listed, or the rewrite refuses)."""

    def __init__(self, name, off, size, header=None, member=None, labels=(), typed=''):
        self.name, self.off, self.size = name, off, size
        self.header, self.member, self.labels, self.typed = header, member, list(labels), typed


def ensure_typedef(cb, tname):
    """Insert LOCAL_TYPES[tname]'s typedef above the blob struct, once."""
    txt = LOCAL_TYPES[tname][1]
    if any(('} %s;' % tname) in l for l in cb.lines):
        return
    new = txt.rstrip('\n').split('\n') + ['']
    at = cb.s0
    cb.lines[at:at] = new
    n = len(new)
    cb.s0 += n
    cb.s1 += n
    cb.i0 += n
    cb.i1 += n


def glyph_rows(data, off, n, chars):
    """Initializer for n 16x17 1-bpp glyphs (uint8_t [n][17][2]); every row
    carries its bit picture.  Rows are stored BOTTOM-UP (DrawBitmapSP2_Impl
    draws row i at y0 + height - i), so row 0 is the glyph's bottom line."""
    out = []
    for g in range(n):
        base = off + 34 * g
        rows = []
        for r in range(17):
            hi, lo = data[base + 2 * r], data[base + 2 * r + 1]
            pic = ''.join('#' if ((hi << 8) | lo) & (0x8000 >> x) else '.' for x in range(16))
            rows.append('            { 0x%02X, 0x%02X },  /* %2d %s */' % (hi, lo, r, pic))
        body = '\n'.join(rows)
        if n == 1:
            return '{\n' + body.replace('            ', '        ') + '\n    }'
        out.append("        /* '%s' */ {\n%s\n        }," % (chars[g], body))
    return '{\n' + '\n'.join(out) + '\n    }'


REGIONS = []


WELCOME_READER = (
    "{AcWelcomScreenProc}, on its init message (0x1C00001), calls "
    "Get_Region_Code and stores the table address at 0x024786: "
    "Bitmap_DigitD+0x22 when the region code is 2, Bitmap_DigitD+0x8DA "
    "otherwise (the two `ld xwa, Bitmap_DigitD_0x...` loads; those names are "
    ".set in shared/positional_labels.s).  The step index lives at 0x024784; "
    "a step is table + 12*index (add, add, sll 2).  "
    "{AcWelcomScreen_Select_NextStep} increments the index, reads the step's "
    "+0 and hands it to SetApTimer (a zero delay runs the next step at once); "
    "{AcWelcomScreen_Select} loads +8 as the op, runs it only when "
    "0 <= op <= 12, through WelcomeScript_OpJumpOffsets below, with the "
    "address of +10 in xde.")


def welcome_region(cb, data, sl):
    """0xE9DE60..0xE9F148 (blob +0x17F12..+0x191FA): the seven 16x17 glyphs the
    welcome animation writes with, the two step tables, the clear rectangle,
    the op jump table and the PsMixer control proc table."""
    import struct
    # offsets only: the slice LENGTHS change once this region has been split
    tot = sl['NakaInst_TOTAL'][0]
    d = sl['Bitmap_DigitD'][0]
    assert sl['MidiParam_PanelCfgTable'][0] == d + 0x121C
    assert data[tot:tot + 6] == b'TOTAL\0'
    g_c = tot + 0x34
    assert (g_c, sl['Bitmap_Digit1'][0], sl['Bitmap_DigitL'][0], sl['Bitmap_DigitR'][0], d) == \
        (g_c, g_c + 34, g_c + 68, g_c + 170, g_c + 204)
    A, B, RECT, JT, PT, END = d + 0x22, d + 0x8DA, d + 0x11CE, d + 0x11D6, d + 0x11F0, d + 0x121C
    recs = {}
    for nm, lo, hi in (('A', A, B), ('B', B, RECT)):
        assert (hi - lo) % 12 == 0
        rr = [struct.unpack('<IhhhH', data[o:o + 12]) for o in range(lo, hi, 12)]
        assert rr[-1][3] == 0 and all(r[3] != 0 for r in rr[:-1]), nm   # op 0 only at the end
        assert all(0 <= r[3] <= 12 for r in rr), nm
        recs[nm] = rr
    rect = struct.unpack('<4h', data[RECT:JT])
    assert rect == (0, 0, 319, 239), rect
    jt = struct.unpack('<13h', data[JT:PT])
    assert jt[0] == 0 and jt[9] == jt[12], jt
    procs = struct.unpack('<11I', data[PT:END])
    assert all(0xF80000 <= x < 0xF83000 for x in procs), procs
    from collections import Counter

    GLYPH_FMT = (
        "Format, from {DrawBitmapSP2_Impl}: 1 bpp, each row one big-endian "
        "16-bit word (MSB = leftmost pixel; the routine byte-swaps the word "
        "it loads), (width + 15) / 16 words per row; a set bit is drawn in "
        "the colour argument, a clear bit is not drawn.  Rows are stored "
        "BOTTOM-UP: row i is drawn at y0 + height - i.  The callers push "
        "height 0x11 (17) and pass width 0x10 (16) -- `pushw 0x11 ... ldw "
        "de, 0x10; call DrawBitmapSP2` -- in the welcome-script op handlers "
        "that follow {AcWelcomScreen_RenderBytecode} (ui/drawbar_panel_ui.s; "
        "that code is only partly framed as instructions there, and was "
        "checked against unidasm), so each glyph is 17 x 2 = 34 bytes.")
    USE = (
        "Which op draws which glyph (handlers at AcWelcomScreen_RenderBytecode + "
        "the WelcomeScript_OpJumpOffsets entry, decoded with unidasm because "
        "ui/drawbar_panel_ui.s frames that code only partly): op 4 C, op 5 O, "
        "op 6 L, op 7 R, op 11 U, op 8 I then N, and ops 9 and 12 (one shared "
        "handler, offset 386) C-O-L-O-R with the U drawn only when op == 12 "
        "(`cp (XBC+0x08),0x000c; jr NZ` around it).  Step table A (region code "
        "2) uses ops 4/5/6/7 and 9 -- COLOR; table B uses 4/5/6/11/7 and 12 -- "
        "COLOUR.  Ops 4/5/6/7/11 push the step's arg as the colour (`pushw "
        "(xde)`, xde = &arg); op 8 pushes 0xFF.")

    DRAWN_BY = {'C': 'op 4 alone and ops 9/12 as the first letter of COLO(U)R',
                'I': 'op 8, before the N', 'N': 'op 8, after the I',
                'L': 'op 6 alone and ops 9/12 in COLO(U)R',
                'O': 'op 5 alone and ops 9/12 twice in COLO(U)R',
                'R': 'op 7 alone and ops 9/12 as the last letter of COLO(U)R',
                'U': 'op 11 alone and ops 9/12 only when op == 12 (COLOUR)'}
    first = [True]

    def glyph_piece(name, off, n, chars, labels, extra=''):
        hdr = ('%s  --  %s, %d glyph%s of 16 x 17 pixels, 1 bpp, %d bytes'
               % (name, ', '.join("'%s'" % c for c in chars), n, 's' if n > 1 else '', 34 * n))
        drawn = '; '.join("'%s' by %s" % (c, DRAWN_BY[c]) for c in chars)
        body = ("What it is: the letter%s %s, read from the bit pictures in the C "
                "(upside-down there, because the rows are stored bottom-up).%s  "
                "Drawn by the welcome-script op handlers: %s."
                % ('s' if n > 1 else '', '/'.join(chars), extra, drawn))
        if first[0]:
            body += '\n\n' + GLYPH_FMT + '\n\n' + USE
            first[0] = False
        else:
            body += ("\n\nFormat and readers: as WelcomeGlyph_C (the first glyph, "
                     "above): {DrawBitmapSP2_Impl} draws 16 x 17, 1 bpp, one "
                     "big-endian word per row, rows bottom-up; the op handlers after "
                     "{AcWelcomScreen_RenderBytecode} pass width 0x10 and height 0x11.")
        hdr = hdr + '\n\n' + wrap(fmt(body))
        dims = '[17][2]' if n == 1 else '[%d][17][2]' % n
        mem = M.NewMember('uint8_t', name, dims, 34 * n, glyph_rows(data, off, n, chars))
        return Piece(name, off, 34 * n, hdr, mem, labels,
                     typed='Typed in naka_technichord_strings.c as uint8_t %s%s.' % (name, dims))

    pieces = [Piece(None, tot, 0x34, labels=['NakaInst_TOTAL'])]
    pieces.append(glyph_piece('WelcomeGlyph_C', g_c, 1, 'C', [],
                              '  No label of its own in the .s: other files reach it as '
                              'NakaInst_TOTAL_0x34 (.set in shared/positional_labels.s); it '
                              'shares the old NakaInst_TOTAL slice with the strings above it.'))
    pieces.append(glyph_piece('Bitmap_Digit1', g_c + 34, 1, 'I', ['Bitmap_Digit1'],
                              '  The label name (Digit1) predates this header: the glyph is '
                              'the letter I, not a digit.'))
    pieces.append(glyph_piece('Bitmap_DigitL', g_c + 68, 3, 'LNO', ['Bitmap_DigitL'],
                              '  Glyphs 1 and 2 are reached as Bitmap_DigitL_0x22 and '
                              'Bitmap_DigitL_0x44 (.set in shared/positional_labels.s).'))
    pieces.append(glyph_piece('Bitmap_DigitR', g_c + 170, 1, 'R', ['Bitmap_DigitR']))
    pieces.append(glyph_piece('Bitmap_DigitD', d, 1, 'U', ['Bitmap_DigitD'],
                              '  The old Bitmap_DigitD slice ran 0x121C bytes: this glyph and '
                              'the five objects that follow it, which are split off below.'))

    def steps_piece(tag, lo, rr, cond, dotset):
        ops = Counter(r[3] for r in rr)
        hdr = ('WelcomeScript_Steps_%s  --  %d welcome_step_t records x 12 bytes = %d bytes'
               % (tag, len(rr), 12 * len(rr)))
        body = ("The welcome-screen animation script used %s.  Reached by other files "
                "as %s (.set in shared/positional_labels.s).\n\nReader: %s\n\n"
                "Record layout (welcome_step_t, defined in naka_technichord_strings.c): "
                "+0 u32 delay (SetApTimer), +4 s16 x, +6 s16 y, +8 s16 op, +10 u16 "
                "arg.  Count pinned by the layout: the table starts where the other "
                "one ends (or at the U glyph's end) and runs to the next object "
                "(WelcomeScreen_ClearRect) at a whole number of records; the only "
                "op-0 step is the last one, and op 0's jump offset is 0 -- the code at "
                "AcWelcomScreen_RenderBytecode itself, which posts event 0x1E000B3, "
                "the event AcWelcomScreen_Init_SwitchMode also posts to leave the "
                "screen.  Op histogram: %s."
                % (cond, dotset, WELCOME_READER,
                   ', '.join('op %d x%d' % kv for kv in sorted(ops.items()))))
        hdr = hdr + '\n\n' + wrap(fmt(body))
        rows = '\n'.join('        /* %3d */ { %d, %d, %d, %d, 0x%04X },' % ((k,) + r)
                         for k, r in enumerate(rr))
        mem = M.NewMember('welcome_step_t', 'WelcomeScript_Steps_%s' % tag, '[%d]' % len(rr),
                          12 * len(rr), '{\n' + rows + '\n    }')
        return Piece(mem.name, lo, 12 * len(rr), hdr, mem, [],
                     typed='Typed in naka_technichord_strings.c as welcome_step_t '
                           '%s[%d].' % (mem.name, len(rr)))

    pieces.append(steps_piece('A', A, recs['A'], 'when Get_Region_Code returns 2',
                              'Bitmap_DigitD_0x22'))
    pieces.append(steps_piece('B', B, recs['B'], 'for every other region code',
                              'Bitmap_DigitD_0x8DA'))
    hdr = ('WelcomeScreen_ClearRect  --  4 x s16 {x1, y1, x2, y2} = {0, 0, 319, 239}\n\n'
           + wrap(fmt("The whole 320 x 240 screen.  {AcWelcomScreen_Activate} "
                      "(when CheckNotDrawFlag is clear) turns the LCD off, passes this "
                      "rectangle to DrawBox with colour 0, updates the screen and turns "
                      "the LCD back on (`ld xwa, Bitmap_DigitD_0x11CE; ld bc, 0; call "
                      "DrawBox`; the name is .set in shared/positional_labels.s).  The "
                      "generator had read its last four bytes 3F 01 EF 00 as a pointer "
                      "to Naka_PresentationRootState (0x00EF013F); they are x2 = 319, "
                      "y2 = 239.")))
    pieces.append(Piece('WelcomeScreen_ClearRect', RECT, 8, hdr,
                        M.NewMember('int16_t', 'WelcomeScreen_ClearRect', '[4]', 8,
                                    '{ 0, 0, 319, 239 }'), [],
                        typed='Typed as int16_t WelcomeScreen_ClearRect[4].'))
    hdr = ('WelcomeScript_OpJumpOffsets  --  13 x s16 code offsets, one per op 0..12\n\n'
           + wrap(fmt("{AcWelcomScreen_Select} doubles the op (add hl, hl), loads the "
                      "word at Bitmap_DigitD_0x11D6 + 2*op (the name is .set in "
                      "shared/positional_labels.s), loads xix with "
                      "AcWelcomScreen_RenderBytecode and jumps indirectly -- so each "
                      "entry is the offset of an op handler from "
                      "AcWelcomScreen_RenderBytecode.  Values: %s.  What each handler "
                      "does (decoded with unidasm at label + offset, v10): op 0 (+0) "
                      "posts 0x1E000B3 and ends the script; op 1 (+896) just advances "
                      "to the next step; op 2 (+15) reads arg (cp iz, 2) and a 12-byte "
                      "record table in RAM at 0x03EA0C (not analysed); op 3 (+162) "
                      "calls SendEvent with 0x1C0000C; ops 4/5/6/7/11 (+179/+208/+237/"
                      "+293/+265) draw one glyph each -- C, O, L, R, U; op 8 (+321) "
                      "draws I then N; ops 9 and 12 (+386) draw C-O-L-O(-U)-R; op 10 "
                      "(+860) calls ApFuncCall on 0x120000B with 0x1E000AC, CaptureLcd, "
                      "then 0x1E000AD.  That code is not yet framed as instructions in "
                      "ui/drawbar_panel_ui.s, so the targets stay offsets, not labels."
                      % ', '.join(str(x) for x in jt))))
    pieces.append(Piece('WelcomeScript_OpJumpOffsets', JT, 26, hdr,
                        M.NewMember('int16_t', 'WelcomeScript_OpJumpOffsets', '[13]', 26,
                                    '{ ' + ', '.join(str(x) for x in jt) + ' }'), [],
                        typed='Typed as int16_t WelcomeScript_OpJumpOffsets[13].'))
    hdr = ('PsMixer_ControlProcTable  --  11 x u32 code addresses\n\n'
           + wrap(fmt("{PsMixer_ControlHelper} (ui/drawbar_panel_ui.s) loads the word at "
                      "+2 of a control record, multiplies it by 4 and indexes this table "
                      "(lda xbc, Bitmap_DigitD_0x11F0 -- .set in "
                      "shared/positional_labels.s -- then an indexed load into xhl), and "
                      "calls the entry with xbc = 0x1C0000D, the paint message; the same "
                      "`lda xbc, Bitmap_DigitD_0x11F0` occurs at 14 sites in that file.  "
                      "The eleven values (v10/v9) are %s: all inside the "
                      "AudioCtrl_DataBlock_* stretch of ui/drawbar_panel_ui.s, where only "
                      "0xF812AF, 0xF81890 and 0xF81ED2 are on a label "
                      "(AudioCtrl_DataBlock_Helper6/7/8) -- the other eight are entry "
                      "points that file's framing does not show.  v7 moves every entry "
                      "by -0x404 through v7_c_divergence.json (offsets 102862..102902), "
                      "which is itself evidence that they are code addresses.  Kept "
                      "numeric here because the targets have no labels to name."
                      % ', '.join('0x%06X' % x for x in procs))))
    pieces.append(Piece('PsMixer_ControlProcTable', PT, 44, hdr,
                        M.NewMember('uint32_t', 'PsMixer_ControlProcTable', '[11]', 44,
                                    '{\n' + '\n'.join('        0x%08X,' % x for x in procs)
                                    + '\n    }'), [],
                        typed='Typed as uint32_t PsMixer_ControlProcTable[11].'))
    # symbolic initializers the generator put inside this span: all proven
    # false pointers (record fields and the rectangle), listed by value
    fps = []
    for mb in cb.members:
        if g_c <= mb.offset < END:
            e = cb.entries[cb.by_name[mb.name]].expr
            if M.SYMBOLIC_RE.search(e):
                assert e.strip() in ('NAKA_ADDR(SLSrc_ScrollMode8)',
                                     'NAKA_ADDR(Naka_PresentationRootState)'), e
                fps.append(mb.name)
    return tot, END, pieces, fps


def mst_titles_region(cb, data, sl):
    """StyleSong_MasterTable (1000 x 6 B) and the 1000 title strings it points
    at (34 B each), blob +0x32D6..+0xCF26 of naka_style_bitmaps."""
    import struct
    base = cb.base()
    T = sl['StyleSong_MasterTable'][0]
    N = 1000
    S0 = T + 6 * N
    S1 = S0 + 34 * N
    recs = [struct.unpack('<IH', data[T + 6 * i:T + 6 * i + 6]) for i in range(N)]
    starts = [S0 + 34 * k for k in range(N)]
    assert sorted(p - base for p, _ in recs) == starts
    assert sorted(h for _, h in recs) == list(range(N))
    titles = [data[o:o + 34] for o in starts]
    for t in titles:
        assert len(t.split(b'\0')[0]) == 32 and t[32:] == b'\0\xff', t
    names = [t[:32].decode('latin-1') for t in titles]
    # alphabetical in table order, reverse alphabetical in memory order
    order = [(p - base - S0) // 34 for p, _ in recs]
    assert order == list(range(N - 1, -1, -1)), order[:5]
    assert all(n[29:].strip().isdigit() for n in names)
    hdr = ('StyleSong_MasterTable  --  %d mst_title_ref_t records x 6 bytes = %d bytes\n\n'
           % (N, 6 * N) + wrap(fmt(
               "An alphabetical list of 1000 titles, each with an id.  Readers "
               "(ui/ui_mode_handlers.s): the MasterSetup dial handlers "
               "(MasterSetup_HandleDialTurn, MasterSetup_DialTurn_ScrollUp, "
               "MasterSetup_DialDown_*) index it with 6*k (`muls wa, 0x6`), load "
               "+0 and Strcpy the title into the view, and search it with "
               "String_Compare; their bounds are 0x3E8 (1000) -- an index of 1000 "
               "wraps to 0 and an underflow reads entry 999 through "
               "StyleSong_MasterTable_0x176A (= +999*6, .set in "
               "shared/positional_labels.s), which is how the count is pinned.  "
               "The cell-select paths of MasterSetup and MstStyleAlp_EventDispatch "
               "load the u16 at +4 of entry 9*(page-1) + scroll + row "
               "(StyleSong_MasterTable_0x4, 9 rows per page) and hand it to "
               "MainFuncCall with 0x142000D / 0x1E20018.  Checked here: the 1000 "
               "title pointers are exactly the 1000 entries of StyleSong_Titles "
               "(entry k of this table -> title 999-k), and the ids are 0..999, "
               "each once.  What the id selects on the 0x142000D side was not "
               "traced.")))
    body = '\n'.join('        /* %3d */ { SELF(StyleSong_Titles[%d]), %d },' % (i, order[i], recs[i][1])
                     for i in range(N))
    tab = M.NewMember('mst_title_ref_t', 'StyleSong_MasterTable', '[%d]' % N, 6 * N,
                      '{\n' + body + '\n    }')
    hdr2 = ('StyleSong_Titles  --  %d title strings x 34 bytes = %d bytes\n\n' % (N, 34 * N)
            + wrap("Each entry is 32 characters -- a 29-column name, then a "
                   "right-aligned 3-digit number (e.g. \"Zorba's Band ... 120\"; "
                   "no code that reads the number separately was traced; it reads "
                   "like a tempo) -- then NUL and a 0xFF pad byte, the ALIGNED_STRING "
                   "layout.  Only reached through StyleSong_MasterTable's +0 "
                   "pointers (above); stored in REVERSE alphabetical order, so the "
                   "table's entry k points at title 999-k.  The old .s sliced this "
                   "run into 130 NakaInst_<title> labels that cut across the "
                   "34-byte entries; none of them was referenced except three "
                   "that naka_direct_play.c, naka_perf_style.c and "
                   "naka_effects_seq.c used as false pointers (16-bit value pairs "
                   "that happened to fall inside a title), which are numbers again "
                   "in those files."))
    tbody = '\n'.join('        /* %3d */ ALIGNED_STRING(%s),' % (k, M.c_string(titles[k][:32]))
                      for k in range(N))
    strs = M.NewMember('char', 'StyleSong_Titles', '[%d][34]' % N, 34 * N,
                       '{\n' + tbody + '\n    }')
    pieces = [Piece('StyleSong_MasterTable', T, 6 * N, hdr, tab, ['StyleSong_MasterTable'],
                    typed='Typed in naka_style_bitmaps.c as mst_title_ref_t '
                          'StyleSong_MasterTable[1000] (a local typedef).'),
              Piece('StyleSong_Titles', S0, 34 * N, hdr2, strs, ['StyleSong_Titles'],
                    typed='Typed as char StyleSong_Titles[1000][34], one '
                          'ALIGNED_STRING per entry.')]
    fps = []
    for mb in cb.members:
        if T <= mb.offset < S1:
            e = cb.entries[cb.by_name[mb.name]].expr
            if M.SYMBOLIC_RE.search(e):
                # the table's SELF(str_*) pointers are re-expressed as
                # SELF(StyleSong_Titles[k]) (asserted above: every record
                # points at a title start); the recompile check proves the
                # values are unchanged
                fps.append(mb.name)
    return T, S1, pieces, fps


REGIONS.append(dict(blob='naka_style_bitmaps', name='mst_titles', builder=mst_titles_region,
                    typedefs=('mst_title_ref_t',)))


REGIONS.append(dict(blob='naka_technichord_strings', name='welcome', builder=welcome_region,
                    typedefs=('welcome_step_t',)))


def build_regions_c(v, blob, cb, data, sl):
    for R in REGIONS:
        if R['blob'] != blob:
            continue
        start, end, pieces, fps = R['builder'](cb, data, sl)
        cp = [p for p in pieces if p.member is not None]
        c0, c1 = cp[0].off, cp[-1].off + cp[-1].size
        for p in pieces:
            if p.member is not None:
                p.member.pre_lines = M.comment_block(p.header) if p.header else []
        done = all(p.name in cb.by_name and cb.members[cb.by_name[p.name]].offset == p.off
                   for p in cp)
        if done:
            for p in cp:
                if p.header:
                    refresh_header(cb.members[cb.by_name[p.name]],
                                   dict(kind='piece', header=p.header, label=p.name))
            print('%s %-26s region %-28s already typed (headers refreshed)'
                  % (v, blob, R['name']))
            continue
        for t in R.get('typedefs', ()):
            ensure_typedef(cb, t)
        dropped, remap = cb.retype(c0, c1, [p.member for p in cp], data, false_pointers=fps)
        print('%s %-26s region %-28s +0x%05X..+0x%05X %d members; %d symbolic '
              'initializers replaced (%s); SELF remaps %s'
              % (v, blob, R['name'], c0, c1, len(cp), len(dropped),
                 ', '.join(dropped[:3]) + (' ...' if len(dropped) > 3 else ''),
                 remap or '-'))


def object_header(o):
    return bitmap_header(o) if o['kind'] == 'bitmap' else o['header']


def refresh_header(mb, o):
    """Replace this driver's own comment block above an already-typed member
    (the block whose first text line is the object's title) with the
    current text; every other comment line is kept."""
    title = object_header(o).split('\n')[0]
    pre = mb.pre
    for i, l in enumerate(pre):
        if l.strip().startswith('/* ---') and i + 1 < len(pre) and \
                pre[i + 1].strip() == '* ' + title:
            j = next(k for k in range(i + 1, len(pre)) if pre[k].rstrip().endswith('*/'))
            mb.pre = pre[:i] + M.comment_block(object_header(o)) + pre[j + 1:]
            return
    raise SystemExit('%s: no header block to refresh' % o['label'])


# Values the generator spelled NAKA_ADDR(<label>) that are NOT pointers.
# (file, exact old text, count, replacement, why).  Applied as a text edit;
# the recompile check proves the bytes are unchanged.
FALSE_POINTER_FIXES = [
    ('naka_direct_play', '.ptr_0534 = NAKA_ADDR(NakaInst_176),', 1,
     '.ptr_0534 = 0x00EC0098,  /* 16-bit pair 0x0098, 0x00EC (152, 236); the generator had '
     'made it a pointer to 0xEC0098, 12 bytes into StyleSong_Titles[516] -- '
     'not a pointer */'),
    ('naka_direct_play', '.ptr_057c = NAKA_ADDR(NakaInst_176_EC00C0),', 1,
     '.ptr_057c = 0x00EC00C0,  /* 16-bit pair 0x00C0, 0x00EC (192, 236); the generator had '
     'made it a pointer to 0xEC00C0, 18 bytes into StyleSong_Titles[517] -- '
     'not a pointer */'),
    ('naka_perf_style', '.ptr_1834 = NAKA_ADDR(NakaInst_176_EC00C0),', 1,
     '.ptr_1834 = 0x00EC00C0,  /* 16-bit pair 0x00C0, 0x00EC (192, 236); the generator had '
     'made it a pointer to 0xEC00C0, 18 bytes into StyleSong_Titles[517] -- '
     'not a pointer */'),
    ('naka_perf_style', '.ptr_1874 = NAKA_ADDR(NakaInst_176),', 1,
     '.ptr_1874 = 0x00EC0098,  /* 16-bit pair 0x0098, 0x00EC (152, 236); the generator had '
     'made it a pointer to 0xEC0098, 12 bytes into StyleSong_Titles[516] -- '
     'not a pointer */'),
    ('naka_effects_seq', '.inst_ptr   = NAKA_ADDR(NakaInst_o_s_Guitar_110),', 1,
     '.inst_ptr   = 0x00EC0008,  /* 16-bit pair 0x0008, 0x00EC (8, 236); the generator had '
     'made it a pointer to 0xEC0008, 4 bytes into StyleSong_Titles[512] -- not '
     'a pointer */'),
    ('naka_effects_seq', '.ptr_600e = NAKA_ADDR(NakaInst_o_s_Guitar_110),', 1,
     '.ptr_600e = 0x00EC0008,  /* 16-bit pair 0x0008, 0x00EC (8, 236); the generator had '
     'made it a pointer to 0xEC0008, 4 bytes into StyleSong_Titles[512] -- not '
     'a pointer */'),
]


def fix_false_pointers(v, apply):
    by = {}
    for f in FALSE_POINTER_FIXES:
        by.setdefault(f[0], []).append(f)
    for blob, fixes in by.items():
        cpath = os.path.join(ui(v), blob + '.c')
        txt = open(cpath, encoding='latin-1').read()
        if all(f[3] in txt for f in fixes):
            continue
        data = compile_blob(v, blob)
        before = txt
        for _, old, n, new, in ((f[0], f[1], f[2], f[3]) for f in fixes):
            if txt.count(old) != n:
                raise SystemExit('%s: %r occurs %d times, expected %d' % (cpath, old, txt.count(old), n))
            txt = txt.replace(old, new)
        print('%s %s: %d false pointers made numeric' % (v, blob, len(fixes)))
        if apply:
            open(cpath, 'w', encoding='latin-1', newline='').write(txt)
            gone = prune_externs(cpath, before)
            if compile_blob(v, blob) != data:
                raise SystemExit('%s %s: false-pointer fix changed the bytes' % (v, blob))
            print('   %s %s: recompiled, byte-identical; externs retired: %s' % (v, blob, gone))


def build_c(v, apply, render_dir):
    blobs = {}
    for o in OBJECTS:
        blobs.setdefault(o['blob'], []).append(o)
    for R in REGIONS:
        blobs.setdefault(R['blob'], [])
    for blob, objs in blobs.items():
        cpath = os.path.join(ui(v), blob + '.c')
        data = compile_blob(v, blob)
        sl = s_slices(os.path.join(ui(v), S_FOR[blob]), blob)
        cb = M.CBlob(cpath)
        if len(data) != cb.size:
            raise SystemExit('%s: compiled %d B, struct %d B' % (blob, len(data), cb.size))
        runs = []
        for o in sorted(objs, key=lambda o: sl[o['label']][0]):
            off, ln = sl[o['label']]
            k = cb.by_name.get(o['label'])
            if k is not None and cb.members[k].offset == off and cb.members[k].size == ln:
                refresh_header(cb.members[k], o)
                print('%s %-26s %-32s already typed (header refreshed)' % (v, blob, o['label']))
                continue
            if runs and runs[-1][1] == off:
                runs[-1][1] = off + ln
                runs[-1][2].append(o)
            else:
                runs.append([off, off + ln, [o]])
        for start, end, run in runs:
            new = []
            for o in run:
                off, ln = sl[o['label']]
                if o['kind'] == 'bitmap':
                    if o['stride'] * o['h'] != ln:
                        raise SystemExit('%s: %d x %d (stride %d) != slice %d B'
                                         % (o['label'], o['w'], o['h'], o['stride'], ln))
                    pix = data[off:off + ln]
                    if render_dir and v == 'v10':
                        render(render_dir, o, pix)
                    new.append(M.bitmap_member(o['label'], pix, o['w'], o['h'], o['stride'],
                                               pre=M.comment_block(bitmap_header(o)),
                                               per_line=24))
                print('%s %-26s %-32s +0x%05X %6d B  %s'
                      % (v, blob, o['label'], off, ln,
                         '%dx%d stride %d' % (o['w'], o['h'], o['stride'])
                         if o['kind'] == 'bitmap' else o['kind']))
            # every symbolic initializer inside a BITMAP run is a false
            # pointer (pixels the generator read as an address); the bytes are
            # kept exactly, from the compiled blob
            fps = []
            if all(o['kind'] == 'bitmap' for o in run):
                for mb in cb.members:
                    if start <= mb.offset < end and \
                            M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr):
                        fps.append(mb.name)
            dropped, remap = cb.retype(start, end, new, data, false_pointers=fps)
            print('   run +0x%05X..+0x%05X: %d false pointers dropped (%s), SELF remaps %s'
                  % (start, end, len(dropped), ', '.join(dropped[:6]), remap or '-'))
        build_regions_c(v, blob, cb, data, sl)
        n = cb.symbolize_self_pointers([o['label'] for o in objs if o['kind'] == 'bitmap'])
        print('   %d numeric pointers to these objects made SELF(...)' % n)
        if apply:
            before = open(cpath, encoding='latin-1').read()
            cb.write()
            gone = prune_externs(cpath, before)
            if gone:
                print('   externs no longer referenced (false pointers retired): %s' % gone)
            after = compile_blob(v, blob)
            if after != data:
                raise SystemExit('%s %s: retyped C compiles to different bytes' % (v, blob))
            print('   %s %s: recompiled, byte-identical (%d B)' % (v, blob, len(after)))


# ------------------------------------------------------------------ .s headers
RULE = '; ' + '-' * 77
MARK = '; [nakarest_retype] '


def s_header_lines(o):
    if o['kind'] == 'bitmap':
        text = bitmap_header(o)
        typed = ('Typed in %s.c as uint8_t %s[%d][%d] (rows of %d bytes).'
                 % (o['blob'], o['label'], o['h'], o['stride'], o['stride']))
    else:
        text = o['header']
        typed = o.get('typed', '')
    out = [RULE, MARK + o['label']]
    for ln in text.split('\n'):
        out.append(('; ' + ln).rstrip())
    if typed:
        out.append(';')
        for ln in wrap(typed).split('\n'):
            out.append('; ' + ln)
    out.append(RULE)
    # CLAUDE.md "Lowercase Hex": hex in .s comments is written lowercase
    return [re.sub(r'0x[0-9A-Fa-f]+', lambda m: m.group(0).lower(), l) for l in out]


def apply_s(v, apply):
    by_s = {}
    for o in OBJECTS:
        by_s.setdefault(S_FOR[o['blob']], []).append(o)
    for sname, objs in by_s.items():
        path = os.path.join(ui(v), sname)
        raw = open(path, 'rb').read()
        lines = raw.decode('latin-1').split('\n')
        for o in objs:
            lab = o['label'] + ':'
            idx = [i for i, l in enumerate(lines) if l == lab]
            if len(idx) != 1:
                raise SystemExit('%s: label %s found %d times' % (path, o['label'], len(idx)))
            i = idx[0]
            # a header goes above the FIRST of a run of labels naming one slice
            while i > 0 and re.match(r'^[A-Za-z_][A-Za-z0-9_]*:$', lines[i - 1]):
                i -= 1
            if i >= 2 and lines[i - 1] == RULE:
                k = i - 2
                while k >= 0 and lines[k] != RULE:
                    k -= 1
                if k >= 0 and lines[k + 1] == MARK + o['label']:
                    del lines[k:i]
                    i = k
            lines[i:i] = s_header_lines(o)
        out = '\n'.join(lines).encode('latin-1')
        print('%s %s: %+d bytes' % (v, sname, len(out) - len(raw)))
        if apply and out != raw:
            open(path, 'wb').write(out)


def piece_lines(p, blob):
    out = []
    if p.header:
        out += [RULE, MARK + p.name]
        for ln in p.header.split('\n'):
            out.append(('; ' + ln).rstrip())
        if p.typed:
            out.append(';')
            for ln in wrap(p.typed).split('\n'):
                out.append('; ' + ln)
        out.append(RULE)
        out = [re.sub(r'0x[0-9A-Fa-f]+', lambda m: m.group(0).lower(), l) for l in out]
    out += ['%s:' % l for l in p.labels]
    out.append('\t.incbin "includes/generated/%s.bin", 0x%X, 0x%X' % (blob, p.off, p.size))
    return out


_REFS = {}


def label_unreferenced(label, spath):
    """True when `label` occurs (as a word) in no tracked or working-tree file
    under v10/, v9/ or v7/ other than the .s files named like `spath`."""
    if label not in _REFS:
        r = subprocess.run(['git', 'grep', '-a', '-l', '-w', '-F', label, '--', 'v10', 'v9', 'v7'],
                           cwd=ROOT, capture_output=True, text=True)
        _REFS[label] = [f for f in r.stdout.split() if not f.endswith('/' + os.path.basename(spath))]
    return not _REFS[label]


def rewrite_s_span(path, lines, blob, pieces):
    """Replace the .s lines that emit [pieces[0].off, pieces[-1].end) of
    `blob` -- their labels, their .incbin lines and this driver's own header
    blocks -- by one (header, labels, .incbin) group per piece."""
    start, end = pieces[0].off, pieces[-1].off + pieces[-1].size
    o = start
    for p in pieces:
        assert p.off == o, (p.name, hex(p.off), hex(o))
        o += p.size
    rx = re.compile(r'^\t\.incbin "includes/generated/%s\.bin", (0x[0-9A-Fa-f]+|\d+), '
                    r'(0x[0-9A-Fa-f]+|\d+)\s*$' % re.escape(blob))
    inc = [(i, int(m.group(1), 0), int(m.group(2), 0)) for i, m in
           ((i, rx.match(l)) for i, l in enumerate(lines)) if m]
    span = [t for t in inc if start <= t[1] < end]
    if not span or span[0][1] != start or span[-1][1] + span[-1][2] != end:
        raise SystemExit('%s: slices do not tile +0x%X..+0x%X' % (path, start, end))
    for (i, a, n), (j, b, _) in zip(span, span[1:]):
        if a + n != b:
            raise SystemExit('%s: gap/overlap at +0x%X' % (path, a + n))
    first, last = span[0][0], span[-1][0]
    # walk back over the labels and our own header block above the first slice
    while first > 0 and re.match(r'^[A-Za-z_][A-Za-z0-9_]*:$', lines[first - 1]):
        first -= 1
    if first >= 1 and lines[first - 1] == RULE:
        k = first - 2
        while k >= 0 and lines[k] != RULE:
            k -= 1
        if k >= 0 and lines[k + 1].startswith(MARK):
            first = k
    old = lines[first:last + 1]
    # only labels, incbin lines, blank lines and OUR header blocks may be replaced
    in_hdr = False
    for l in old:
        if l == RULE:
            in_hdr = not in_hdr
            continue
        if in_hdr or not l.strip() or rx.match(l) or re.match(r'^[A-Za-z_][A-Za-z0-9_]*:$', l):
            continue
        raise SystemExit('%s: refusing to replace line %r' % (path, l))
    old_labels = {l[:-1] for l in old if re.match(r'^[A-Za-z_][A-Za-z0-9_]*:$', l)}
    new_labels = {l for p in pieces for l in p.labels}
    lost = old_labels - new_labels
    bad = sorted(l for l in lost if not label_unreferenced(l, path))
    if bad:
        raise SystemExit('%s: the rewrite would drop referenced labels %s' % (path, bad))
    if lost:
        print('   %d labels retired (no reference anywhere in v10/v9/v7 outside this '
              'file): %s%s' % (len(lost), ', '.join(sorted(lost)[:6]),
                               ' ...' if len(lost) > 6 else ''))
    new = []
    for p in pieces:
        new += piece_lines(p, blob)
    lines[first:last + 1] = new
    return len(new) - len(old)


def apply_regions_s(v, apply):
    for R in REGIONS:
        blob = R['blob']
        path = os.path.join(ui(v), S_FOR[blob])
        raw = open(path, 'rb').read()
        lines = raw.decode('latin-1').split('\n')
        data = compile_blob(v, blob)
        cb = M.CBlob(os.path.join(ui(v), blob + '.c'))
        sl = s_slices(path, blob)
        _, _, pieces, _ = R['builder'](cb, data, sl)
        d = rewrite_s_span(path, lines, blob, pieces)
        out = '\n'.join(lines).encode('latin-1')
        print('%s %s region %s: %+d lines, %+d bytes' % (v, S_FOR[blob], R['name'], d,
                                                       len(out) - len(raw)))
        if apply and out != raw:
            open(path, 'wb').write(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--render', metavar='DIR')
    ap.add_argument('--only-s', action='store_true', help='write only the .s headers')
    args = ap.parse_args()
    if not args.only_s:
        for v in VERSIONS:          # all versions first: the .s label check
            fix_false_pointers(v, args.apply)   # greps v10, v9 and v7 at once
    for v in VERSIONS:
        if not args.only_s:
            build_c(v, args.apply, args.render)
        apply_s(v, args.apply)
        apply_regions_s(v, args.apply)


if __name__ == '__main__':
    main()
