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


# blobs whose C / linker-script file is not named after the blob (Makefile)
C_FILE = {'naka_control_menu_header': 'control_menu_header'}
LD_FILE = {'naka_control_menu_header': 'naka_ctrl_menu_link'}


def c_path(v, blob):
    return os.path.join(ui(v), C_FILE.get(blob, blob) + '.c')


def compile_blob(v, blob):
    """The bytes the version's C compiles to (Makefile recipe, scratch dir)."""
    with tempfile.TemporaryDirectory() as t:
        o, elf, b = (os.path.join(t, 'x' + s) for s in ('.o', '.elf', '.bin'))
        subprocess.run([os.path.join(LLVM, 'clang'), '-target', 'tlcs900', '-ffreestanding',
                        '-c', '-O2', '-I', ui(v), '-o', o, c_path(v, blob)],
                       check=True)
        subprocess.run([os.path.join(LLVM, 'ld.lld'), '-e', '0', '-T',
                        os.path.join(ui(v), LD_FILE.get(blob, blob + '_link') + '.ld'), '-o', elf, o],
                       check=True)
        subprocess.run([os.path.join(LLVM, 'llvm-objcopy'), '-O', 'binary', '-j', '.text',
                        elf, b], check=True)
        return open(b, 'rb').read()


def s_slices(spath, blob, lines=None):
    """label -> (offset, length) for every label directly above an .incbin
    of `blob` (several labels may name one slice)."""
    if lines is None:
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

    def __init__(self, name, off, size, header=None, member=None, labels=(), typed='',
                 compact=False):
        self.name, self.off, self.size = name, off, size
        self.header, self.member, self.labels, self.typed = header, member, list(labels), typed
        self.compact = compact


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
                      "record table in RAM at 0x03EA0C (that table was not followed); op 3 (+162) "
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
        todo = 0
        for _, old, n, new, in ((f[0], f[1], f[2], f[3]) for f in fixes):
            if txt.count(old) == 0 and new not in txt:
                # the member has since been retyped as a widget-record field by
                # nakarest_type_records.py, which writes the value as a number
                continue
            if txt.count(old) != n:
                raise SystemExit('%s: %r occurs %d times, expected %d' % (cpath, old, txt.count(old), n))
            txt = txt.replace(old, new)
            todo += 1
        if not todo:
            continue
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
    return [lower_hex(l) for l in out]


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


CMARK = '; [nakarest] '


def lower_hex(t):
    """CLAUDE.md "Lowercase Hex" for comments -- but not the hex digits of a
    symbol name such as CharMap_FullPermutation_0x7B0."""
    return re.sub(r'(?<![A-Za-z0-9_])0x[0-9A-Fa-f]+', lambda m_: m_.group(0).lower(), t)


def ascii_only(t):
    """Header text quotes ROM strings; keep the .s files ASCII (a high byte
    makes ugrep treat a whole source as binary): non-ASCII -> \\xNN."""
    return ''.join(ch if ord(ch) < 0x80 else '\\x%02X' % ord(ch) for ch in t)


def piece_lines(p, blob):
    out = []
    if p.header and p.compact:
        parts = ascii_only(p.header).split('\n')
        out.append(CMARK + parts[0])
        if len(parts) > 2:                      # an admission line, never wrapped
            out.append(CMARK + parts[1])
        body = parts[-1] if len(parts) > 1 else ''
        for ln in textwrap.wrap(' '.join(body.split()), width=96 - len(CMARK),
                                break_long_words=False, break_on_hyphens=False):
            out.append(CMARK + ln)
        out = [lower_hex(l) for l in out]
    elif p.header:
        out += [RULE, MARK + p.name]
        for ln in p.header.split('\n'):
            out.append(('; ' + ln).rstrip())
        if p.typed:
            out.append(';')
            for ln in wrap(p.typed).split('\n'):
                out.append('; ' + ln)
        out.append(RULE)
        out = [lower_hex(l) for l in out]
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
    while first > 0 and (re.match(r'^[A-Za-z_][A-Za-z0-9_]*:$', lines[first - 1]) or
                         lines[first - 1].startswith(CMARK)):
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
        if in_hdr or not l.strip() or rx.match(l) or re.match(r'^[A-Za-z_][A-Za-z0-9_]*:$', l) \
                or l.startswith(CMARK):
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


# ---------------------------------------------------------------- object runs
# .s files whose slices are re-cut at the objects the firmware REGISTERS
# (scripts/analysis/nakarest_objtab_map.py), each piece headed by what starts
# in it.  The C is not touched by this pass.
OBJRUN_FILES = [
    ('disk_menu_file_io_screens.s', 'naka_disk_menu_file_io'),
    ('midi_reverb_presets_screens.s', 'naka_midi_reverb'),
    ('debug_naming_panel_sim.s', 'naka_debug_naming'),
    ('direct_play_medley_screens.s', 'naka_direct_play'),
    ('disk_warning_strings.s', 'naka_disk_warning'),
    ('sequencer_channel_containers.s', 'naka_sequencer_channels'),
    ('composer_style_convert_screens.s', 'naka_composer_style'),
    ('effects_sequencer_screens.s', 'naka_effects_seq'),
    ('msp_recording_screens.s', 'naka_msp_recording'),
    ('block_012.s', 'naka_block_012'),
    ('block_007.s', 'naka_block_007'),
    ('normal_mode_layout.s', 'naka_normal_mode'),
    ('naka_accomp7_widgets.s', 'naka_accomp7_widgets'),
    ('sound_menu_drawbar_screens.s', 'naka_sound_menu_drawbar'),
    ('sequencer_exit_widgets.s', 'naka_sequencer_exit'),
    ('master_style_grid_screens.s', 'naka_master_style'),
    ('control_menu_screens.s', 'naka_control_menu_header'),
    ('control_menu_screens.s', 'naka_ctrl_menu_body'),
    ('extension_device_screens.s', 'naka_extension_device'),
    ('performance_style_screens.s', 'naka_perf_style'),
    ('technichord_part_settings.s', 'naka_technichord_part'),
    ('technichord_string_data.s', 'naka_technichord_strings'),
    ('style_bitmaps.s', 'naka_style_bitmaps'),
    ('widget_names_charmap.s', 'naka_widget_names_charmap'),
]


def blob_base(v, path, blob, lines=None):
    """ROM address of blob offset 0: from any label on one of its slices
    (linked ELF), else from the C file's `#define BASE`."""
    sl = s_slices(path, blob, lines)
    sym = objmap(v).sym
    for lab, (off, _) in sl.items():
        if lab in sym:
            return sym[lab] - off
    c = os.path.join(ui(v), {'naka_control_menu_header': 'control_menu_header'}.get(blob, blob) + '.c')
    m = re.search(r'^#define BASE\s+(0x[0-9A-Fa-f]+)u?\s*$', open(c, encoding='latin-1').read(), re.M)
    return int(m.group(1), 16)
_MAPS = {}


def objmap(v):
    if v not in _MAPS:
        sys.path.insert(0, os.path.join(ROOT, 'scripts', 'analysis'))
        import nakarest_objtab_map as O
        _MAPS[v] = O.Map(v)
    return _MAPS[v]


def _ranges(ks):
    ks = sorted(ks)
    out, a = [], None
    for i, k in enumerate(ks):
        if a is None:
            a = k
        if i + 1 == len(ks) or ks[i + 1] != k + 1:
            out.append('%d' % a if a == k else '%d-%d' % (a, k))
            a = None
    return ', '.join(out)


CLS_NAME = {0x1600010: 'Viewable', 0x160000F: 'ResName', 0x1600002: 'ApFunction',
            0x1600001: 'Function', 0x1600003: 'MainFunction', 0x1600004: 'Class',
            0x160000C: 'ResEvent', 0x160000D: 'ResMethod'}
CLS_PROC = {k: v + 'Proc' for k, v in CLS_NAME.items()}


def _reg_short(r):
    if r['cls'] not in CLS_NAME:
        return r['desc']
    return ('%s slot 0x%X (table 0x%06X, %d entries, %s)'
            % (CLS_NAME[r['cls']], r['slot'], r['table'], r['count'], r['init']))


def _reg_full(m, r):
    """The file-level note for one registered table."""
    if r['cls'] not in CLS_NAME:
        return ('%s: not registered with RegObjTabl; found from its readers, named in '
                'each piece header below.' % r['desc'])
    if r.get('count_at') is not None:
        t = ('%s slot 0x%X: RegObjTable 0x%X, %s, 0x%06X, 0x%06X, 0x%X in %s (%s) -- '
             'the count, %d, is the word at 0x%06X; RegisterObjectTable stores '
             '{class, proc, count, table} at 0x27ED2 + 14*0x%X.'
             % (CLS_NAME[r['cls']], r['slot'], r['cls'], CLS_PROC[r['cls']], r['count_at'],
                r['table'], r['slot'], r['init'], r['file'].split('/maincpu/')[1],
                r['count'], r['count_at'], r['slot']))
    else:
        t = ('%s slot 0x%X: RegObjTabl 0x%X, %s, 0x%X, 0x%06X, 0x%X in %s (%s), '
             'i.e. RegisterObjectTable stores {class, proc, %d, table} at 0x27ED2 + 14*0x%X.'
             % (CLS_NAME[r['cls']], r['slot'], r['cls'], CLS_PROC[r['cls']], r['count'],
                r['table'], r['slot'], r['init'], r['file'].split('/maincpu/')[1], r['count'],
                r['slot']))
    if r['cls'] == 0x1600010:
        rn = m.by_slot.get(r['slot'] + 0x300)
        n0 = m.string_at(m.entries(rn)[0]) if rn and m.entries(rn) and m.inrom(m.entries(rn)[0]) else ''
        n, bad = m.check_links(r)
        outside = [k for k, a in enumerate(m.entries(r)) if not m.inrom(a)]
        t += ('  Element 0 is named "%s" in ResName slot 0x%X.  Links: %s%s.'
              % (n0, r['slot'] + 0x300,
                 'all %d records consistent' % n if not bad else
                 '%d of %d records have a disagreeing link (elements %s)'
                 % (len({k for k, _ in bad}), n, _ranges({k for k, _ in bad})),
                 ('; element%s %s point%s outside the program ROM (RAM records)'
                  % ('s' if len(outside) > 1 else '', _ranges(outside),
                     '' if len(outside) > 1 else 's')) if outside else ''))
    return t


FORMAT_NOTE = (
    "How these pieces were identified (scripts/analysis/nakarest_objtab_map.py): "
    "every RegObjTabl registration in the v10, v9 and v7 sources (the macro, "
    "and v7's written-out form) was parsed, each registered table was read out "
    "of the original ROM dump, and every address those tables point at is an "
    "object START: a Viewable table points at NAKA widget records, a ResName "
    "table (slot = Viewable slot + 0x300) at the name string of each element, "
    "an ApFunction / Function / MainFunction table (slot 0x1xx) at procedures "
    "and its slot + 0x300 twin at their names.  Each piece below starts at one "
    "such run of objects or at a label that already existed.  A widget record "
    "begins with the Viewable fields (the firmware's own names): +0 class "
    "(class id), +4 super, +6 sub, +8 next, +10 prev (element indices of the "
    "same table, 0xFFFF = none -- parent, first child, next and previous "
    "sibling, checked against each other for every table: the Links result "
    "per table), +12 flag, +14 rect (x1, y1, x2, y2).  Name strings are NUL-terminated and 0xFF-padded to "
    "even length.  Strings a record's `X` field (str, title, caption, name) "
    "points at are indexed too, so the bytes after a record are accounted "
    "for (in v10, 4 of the 3,340 records are followed by bytes nothing "
    "indexed starts at).  The first word of a widget record is its CLASS ID 0x016S_KKKK: "
    "ClassProc (ui/ui_widget_defs.s) takes (id >> 16) & 0xFFF as a registry "
    "slot -- the Class table that RegObjTable 0x1600004 put there -- and "
    "0x18 * (id & 0xFFFF) into it.  Each class definition gives the instance "
    "size (+8 allsize), and all 3,340 in-ROM widget records of v10 resolve to "
    "a class and are at least that far apart "
    "(THE CLASS SYSTEM, scripts/analysis/nakarest_objtab_map.py).")


def _cls_hist(m, starts):
    from collections import Counter
    cl = Counter()
    for a in starts:
        c = m.record_class(a)
        cl['%s (%d B)' % (c['name'], c['allsize']) if c else 'unresolved 0x%08X' % m.u32(a)] += 1
    return ', '.join('%s x%d' % (n, c) if c > 1 else n for n, c in cl.items())


def _group_text(m, kind, r, ks, starts):
    if kind == 'record':
        rn = m.by_slot.get(r['slot'] + 0x300)
        n0 = m.string_at(m.entries(rn)[0]) if rn and m.entries(rn) and m.inrom(m.entries(rn)[0]) else ''
        return ('widget record%s, element%s %s of %s%s: %s.'
                % ('s' if len(ks) > 1 else '', 's' if len(ks) > 1 else '', _ranges(ks),
                   _reg_short(r), ' ("%s")' % n0 if n0 else '', _cls_hist(m, starts)))
    if kind == 'text':
        shown = []
        for a in starts:
            fl = m.text_field.get(a, [])
            who = ', '.join(sorted({'%s.%s of element %d' % (cn, fn, k) for cn, fn, k in fl}))
            shown.append('"%s" (%s)' % (m.string_at(a, 48), who))
        return ('%d text%s the records point at (%s): %s.'
                % (len(shown), 's' if len(shown) > 1 else '', _reg_short(r),
                   '; '.join(shown[:4]) + ('; ...' if len(shown) > 4 else '')))
    if kind in ('classdef', 'classname', 'classsig', 'propnames'):
        names = []
        for k in ks:
            c = m.classes.get(((r['slot'] & 0xFFF) << 16) | k)
            if c and c['name'] not in names:
                names.append(c['name'])
        shown = ', '.join(names[:10]) + (', ...' if len(names) > 10 else '')
        if kind == 'classdef':
            return ('class definition entries %s of %s (24 bytes each: proc, parent, allsize, '
                    'selfsize, name, propdata, propname): %s.' % (_ranges(ks), _reg_short(r), shown))
        if kind == 'classname':
            return 'class-name strings (the +12 name) of classes %s of %s: %s.' % (
                _ranges(ks), _reg_short(r), shown)
        if kind == 'classsig':
            sig = [m.string_at(a) for a in starts]
            return ('propdata strings (the +16 field signature) of class%s %s of %s: %s.' % (
                'es' if len(ks) > 1 else '', _ranges(ks), _reg_short(r),
                ', '.join('%s "%s"' % (n, g) for n, g in list(zip(names, sig))[:6])
                + (', ...' if len(sig) > 6 else '')))
        ex = []
        for k in ks[:3]:
            c = m.classes.get(((r['slot'] & 0xFFF) << 16) | k)
            if c:
                ex.append('%s {%s}' % (c['name'], ', '.join(c['fields'][:-1])))
        return ('propname block%s (the +20 field-name table) of class%s %s of %s: %s%s.'
                % ('s' if len(ks) > 1 else '', 'es' if len(ks) > 1 else '', _ranges(ks),
                   _reg_short(r), '; '.join(ex), '; ...' if len(ks) > 3 else ''))
    if kind == 'name':
        names = [m.string_at(a) for a in starts]
        shown = ', '.join('"%s"' % x for x in names[:6]) + (', ...' if len(names) > 6 else '')
        par = m.by_slot.get(r['slot'] - 0x300)
        return ('name string%s, entr%s %s of %s%s: %s.'
                % ('s' if len(ks) > 1 else '', 'ies' if len(ks) > 1 else 'y', _ranges(ks),
                   _reg_short(r), ' (names for %s slot 0x%X)' % (CLS_NAME[par['cls']], par['slot'])
                   if par else '', shown))
    if kind in ('sbroot', 'sbgname', 'sbgroup', 'sbsname', 'sbvar', 'sbtitle'):
        R0 = r['table']
        if kind == 'sbroot':
            return ('the root of the MstStyle browser tree (0x%06X): 10 x {u32 group name, '
                    'u32 group table}.  MstStyle1_EventDispatch, MstStyle1Sub_HandleSubSelect '
                    'and MstStyle1Page_EventDispatch load (index*8)+4 -- the group table -- '
                    'through the label 4 bytes into it (StyleGroup_LatinDance_Table) and store '
                    'it at 0x0340D2; MstStyle1Grid_CellSelect and MstStyle2_NameB_Render load '
                    '+0, the name, through StyleGroup_LatinWorld_PairTable_0x2FA (= this '
                    'address).' % R0)
        if kind == 'sbgname':
            return ('group name string%s (16 characters): %s.' % (
                's' if len(starts) > 1 else '', ', '.join('"%s"' % m.string_at(a).strip() for a in starts)))
        if kind == 'sbgroup':
            return ('group table%s of the MstStyle browser, group%s %s: {u32 style name, u32 '
                    'variation table} x n + an all-zero entry; MstStyle*_CountEntries walk it 8 '
                    'bytes at a time until +0 is 0, the grid routines Strcpy +0 and pad it to '
                    '16 with Strncat, and +4 goes to 0x0340D6.' % (
                        's' if len(ks) > 1 else '', 's' if len(ks) > 1 else '', _ranges(ks)))
        if kind == 'sbsname':
            return ('style name string%s (16 characters): %s.' % (
                's' if len(starts) > 1 else '',
                ', '.join('"%s"' % m.string_at(a).strip() for a in starts[:6]) +
                (', ...' if len(starts) > 6 else '')))
        if kind == 'sbvar':
            return ('variation table%s of %d style%s: {u32 title, u16 id} x n + an all-zero '
                    'entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a '
                    'time from 0x0340D6 by the MstStyle2_* count loops.' % (
                        's' if len(starts) > 1 else '', len(starts), 's' if len(starts) > 1 else ''))
        return ('variation title%s (32 characters + NUL + 0xFF, the StyleSong_Titles '
                'layout): %s.' % ('s' if len(starts) > 1 else '',
                                  '; '.join('"%s"' % ' '.join(m.string_at(a, 34).split())
                                            for a in starts[:4]) + ('; ...' if len(starts) > 4 else '')))
    if kind == 'msgcat':
        return ('the IvMesage message catalog itself (0x%06X): %d records x 14 bytes '
                '{u16 kind, u32 code 0x00NNFFFF (NN = the error number shown; 0xFFFFFFFF '
                'none), u32 header table, u32 text table} and a terminator record whose '
                'pointers are 0.  Readers (ui/drawbar_panel_ui.s): IvMesageProc on init '
                '(0x1C00001) and IvMessage_SelectionChange / LanguageCheckReturn load +0 '
                'with index*14 (`muls wa, 0xe`, positional name ..._0x118) and send '
                '0x1C00001 to the window it selects; MessageText (event 0x1E0009F) returns '
                '+10 (..._0x122); CheckMsg_IncrementCheck stops at a record whose +10 '
                'is 0; IvMessage_Paint compares +0 with 5.' % (r['table'], r['count']))
    if kind == 'msgwin':
        return ('the 6 window object ids the catalog\'s kind field selects (`sla wa, 2` '
                'from ..._0x586): 0x00EE0014 NoMessage, 0x00EE0002 Completed, 0x00EE0005 '
                'Reminder, 0x00EE0009 Error, 0x00EE000D Other, 0x00EE0016 PleaseWait -- '
                'elements of Viewable slot 0xEE (InitializeMurai), all class Window.')
    if kind == 'msglang':
        uses = m.msg_langtab.get(starts[0], [])
        return ('per-language string table%s (6 pointers each: English, German, French, '
                'Spanish, Italian, Indonesian -- the order of the header table\'s own '
                'strings "English Header" ... "Indonesian Header") used as the %s of '
                'catalog record%s %s.' % (
                    's' if len(starts) > 1 else '',
                    '/'.join(sorted({role for a in starts for _, role in m.msg_langtab.get(a, [])})),
                    's' if len({k for a in starts for k, _ in m.msg_langtab.get(a, [])}) > 1 else '',
                    _ranges({k for a in starts for k, _ in m.msg_langtab.get(a, [])})))
    if kind == 'msgstr':
        langs = []
        for (t, i), a in zip(ks, starts):
            langs.append('%s "%s"' % (m.MSG_LANGS[i], m.string_at(a, 28).split('\n')[0]))
        return ('message text%s of the catalog: %s.' % (
            's' if len(starts) > 1 else '', '; '.join(langs[:4]) + ('; ...' if len(langs) > 4 else '')))
    if kind == 'table':
        if r['cls'] == 0x1600004:
            return 'the table itself: %s, %d class definitions x 24 bytes.' % (_reg_short(r), r['count'])
        return 'the table itself: %s, %d entry pointers x 4 bytes.' % (_reg_short(r), r['count'])
    raise ValueError(kind)


def _objects(m, base, lo, hi):
    """[(off, end, kind, reg, k)] of indexed objects starting in [lo, hi)."""
    out = []
    for a, vs in m.in_range(base + lo, base + hi):
        for kind, r, k in vs:
            out.append((a - base, a - base + m.extent(kind, r, k, a), kind, r, k))
    return out


_REFSV = {}


def refs(v):
    if v not in _REFSV:
        sys.path.insert(0, os.path.join(ROOT, 'scripts', 'analysis'))
        import nakarest_refs as NR
        _REFSV[v] = NR.Refs(v)
    return _REFSV[v]


def first_string(m, a):
    t = m.string_at(a, 60).split('\n')[0]
    return t[:48]


def _uses_text(uses, limit=4):
    by = {}
    for a, kind, f, ln, text, routine in uses:
        key = routine or f
        if key not in by:
            by[key] = (f, ' '.join(text.split())[:60])
    items = sorted(by.items())
    out = ['%s (%s: `%s`)' % (k, f, t) for k, (f, t) in items[:limit]]
    if len(items) > limit:
        out.append('%d more' % (len(items) - limit))
    return ', '.join(out)


def text_shape(m, lo, hi):
    """'Text ..., first string "..."', or, when the bytes open with a run of
    ROM pointers, 'a table of N pointers (all into this piece) then text'."""
    ptrs = []
    a = lo
    while a + 4 <= hi:
        v_ = m.u32(a)
        if not (0xE00000 <= v_ < 0x1000000):
            break
        ptrs.append(v_)
        a += 4
    if len(ptrs) >= 2:
        inside = all(lo <= p < hi for p in ptrs)
        t = first_string(m, ptrs[0]) if m.inrom(ptrs[0]) else ''
        return ('A table of %d pointers%s (%d B at 0x%06X), then text; entry 0 points at '
                '"%s"' % (len(ptrs), ' into this piece' if inside else '', hi - lo, lo, t))
    return 'Text (%d B at 0x%06X), first string "%s"' % (hi - lo, lo, first_string(m, lo))


def reader_chain(v, lo, hi):
    """(text, is_text): the symbolic/numeric source references into [lo, hi),
    and the data words below 0xF00000 pointing into it with, one hop back,
    the source references to the object holding each word."""
    R = refs(v)
    parts = []
    uses = R.in_range(lo, hi)
    if uses:
        parts.append('source references ' + _uses_text(uses))
    dw = R.data_refs(lo, hi, max_word_addr=0xF00000)
    if dw:
        conts = {}
        for a, val, nm in dw:
            base_nm = nm.split('+')[0]
            conts.setdefault(base_nm, []).append((a, val))
        cs = []
        for nm, words in list(conts.items())[:3]:
            ca = R.sym.get(nm)
            hop = R.in_range(ca, ca + 1) if ca is not None else []
            cs.append('%d data word%s in %s (at %s)%s' % (
                len(words), 's' if len(words) > 1 else '', nm,
                ', '.join('0x%06X' % a for a, _ in words[:3]),
                ', which is read by ' + _uses_text(hop, 2) if hop else ''))
        if len(conts) > 3:
            cs.append('words in %d more objects' % (len(conts) - 3))
        parts.append('; '.join(cs))
    for rlo, rhi in R.ram_mirror(lo, hi):
        ru = R.ram_in_range(rlo, rhi)
        parts.append('work-RAM image: Boot_InitWorkRAM copies these bytes to RAM 0x%05X..0x%05X '
                     '(its ld xde/xhl/xbc + ldir blocks)%s' % (
                         rlo, rhi, (', where they are read by ' + _uses_text(ru, 4)) if ru
                         else '; no literal RAM reference into that copy was found'))
    rom = R.rom[lo - 0xE00000:hi - 0xE00000]
    pr = sum(1 for b in rom if 32 <= b < 127 or b in (0, 0x0A, 0x0D, 0xFF))
    is_text = len(rom) > 0 and pr / len(rom) >= 0.9 and sum(1 for b in rom if 32 <= b < 127) >= len(rom) / 2
    return '; '.join(parts), is_text


WALLPAPER = (
    "a wallpaper palette: 256 x 4 bytes, three colour bytes and a 0 (the 4th byte "
    "of all 256 entries is 0; the channel order was not traced).  Its address is "
    "entr%s %s of the 12-pointer table Naka_DrawbarReg_Table (0x%06X), which "
    "Boot_InitWorkRAM copies to RAM 0x3F1E4 with the rest of the work-RAM image; "
    "GetWallPaletteRGB (display/graphics_text_vga.s) takes that table's entry "
    "[index] and returns the palette's entry [colour] (`sll 2` twice), and "
    "ChangeWallPalette_Impl (ui/ui_window_procs.s) calls it for colours 0..15 and "
    "writes DAC entries 0xE0..0xEF with SetPaletteRGB.  The 1024-byte size is the "
    "spacing of the 11 palettes here; the reader shown only reads entries 0..15.")


DEFAULT_PALETTE = (
    "the DEFAULT 256-colour palette: InitPaletteRGB (display/graphics_text_vga.s) "
    "points xbc at this address (`lda xwa, (0xeb37de:24)`), sets the end to +0x400 "
    "(`lda_dri XHL, 0xe1, 0x00, 0x04`) and copies the 1024 bytes, 4 at a time, to the "
    "palette RAM at 0x0324FC -- which SetPaletteRGB writes and Table_LookupDword reads "
    "4 bytes per colour (`sll xwa, 2`).  256 x {3 colour bytes, 0}: the 4th byte of all "
    "256 entries is 0; the channel order was not traced.")


def piece_note(v, name):
    """Hand-established purpose text for a piece, or None."""
    if name == 'naka_debug_naming+0xCE0':
        return DEFAULT_PALETTE
    if name.startswith('NakaColor_Palette'):
        R = refs(v)
        t = R.sym.get('Naka_DrawbarReg_Table')
        a = R.sym.get(name)
        if t is None or a is None:
            return None
        ks = [k for k in range(12)
              if int.from_bytes(R.rom[t - 0xE00000 + 4 * k:t - 0xE00000 + 4 * k + 4], 'little') == a]
        if not ks:
            return None
        return WALLPAPER % ('ies' if len(ks) > 1 else 'y', _ranges(ks), t)
    return None


def objrun_pieces(m, blob, base, S0, S1, labels_at, used):
    """Pieces for the blob span [S0, S1): cut at the start of every run of
    objects of one (kind, slot) and at every existing label; each piece says
    what starts in it and, when it starts inside an object, which one."""
    objs = _objects(m, base, S0 - 0x2000 if S0 > 0x2000 else 0, S1)
    cuts = {S0} | set(labels_at)
    prev = None
    for off, end, kind, r, k in objs:
        if off < S0:
            continue
        # a record's texts belong to its run (records and the strings they
        # point at alternate); so do a class table's definitions
        key = ({'text': 'record', 'msglang': 'msg', 'msgstr': 'msg', 'msgcat': 'msgc',
                'msgwin': 'msgc', 'sbvar': 'sbv', 'sbtitle': 'sbv', 'sbsname': 'sbg',
                'sbgroup': 'sbg', 'sbroot': 'sbr', 'sbgname': 'sbr'}.get(kind, kind), r['slot'])
        if key != prev:
            cuts.add(off)
        prev = key
    # inside stretches no registered object covers, cut where code refers
    # (a label or positional .set name, or a literal): each reader then
    # heads the bytes it actually reads
    covered = []
    for off, end, kind, r, k in objs:
        covered.append((off, max(end, off + 1)))
    covered.sort()
    R = refs(m.v)
    for u in R.in_range(base + S0, base + S1):
        c = u[0] - base
        if c & 1 or c in cuts:
            continue
        if any(a <= c < b for a, b in covered):
            continue
        cuts.add(c)
    cuts = sorted(c for c in cuts if S0 <= c < S1)
    pieces = []
    for i, c in enumerate(cuts):
        e = cuts[i + 1] if i + 1 < len(cuts) else S1
        inside = [o for o in objs if c <= o[0] < e]
        # the object this piece starts inside, if any (latest start before c
        # whose extent reaches past c)
        cont = [o for o in objs if o[0] < c < o[1]]
        # one sentence per (kind, table): records and their texts interleave,
        # and a piece may hold hundreds of them
        groups, gi = [], {}
        for off, end, kind, r, k in inside:
            used.setdefault(r['slot'], r)
            key = (kind, id(r))
            if key in gi:
                groups[gi[key]][2].append(k)
                groups[gi[key]][3].append(base + off)
            else:
                gi[key] = len(groups)
                groups.append([kind, r, [k], [base + off]])
        labs = labels_at.get(c, [])
        name = labs[0] if labs else '%s+0x%X' % (blob, c)
        paras = []
        if cont:
            off, end, kind, r, k = max(cont, key=lambda o: o[0])
            paras.append('Continues %s (starts 0x%06X, %d of its %d bytes are here or later)'
                         % (_group_text(m, kind, r, [k], [base + off]).rstrip('.'),
                            base + off, end - c, end - off) + '.')
            used.setdefault(r['slot'], r)
        first = inside[0][0] if inside else e
        covered = max([o[1] for o in cont], default=c)
        admit = None
        note = piece_note(m.v, name) if first > covered else None
        if note:
            paras.append(note[0].upper() + note[1:])
        elif first > covered:
            chain, is_text = reader_chain(m.v, base + covered, base + first)
            n = first - covered
            if chain and is_text:
                paras.append('%s; no registered NAKA table points into it; reached through %s.'
                             % (text_shape(m, base + covered, base + first), chain))
            elif chain:
                # kept on ONE line: the census looks for the phrase, and a
                # wrap between its words would hide the admission
                admit = ('purpose not established: layout of %d B at 0x%06X not derived; '
                         'readers below' % (n, base + covered))
                paras.append('Readers: %s.' % chain)
            else:
                admit = ('purpose not established: %d B at 0x%06X that no registered NAKA '
                         'table, symbol, 24/32-bit literal or data word points into'
                         % (n, base + covered))
        for kind, r, ks, starts in groups:
            paras.append(_group_text(m, kind, r, ks, starts))
        if len(labs) > 1:
            paras.append('Other labels here: %s.' % ', '.join(labs[1:]))
        text = '%s  +0x%X..+0x%X (0x%06X, %d B)\n%s' % (name, c, e, base + c, e - c,
                                                       ' '.join(paras))
        if admit:
            text = text.replace('\n', '\n' + admit + '\n', 1)
        pieces.append(Piece(name, c, e - c, text, None, labs, compact=True))
    return pieces


def write_file_note(lines, blob, text):
    """Insert/replace this driver's file-level note for `blob` after the
    file's leading comment lines."""
    mark = MARK + 'registered NAKA tables: ' + blob
    block = [RULE, mark] + ['; ' + l if l else ';' for l in text.split('\n')] + [RULE]
    block = [lower_hex(l).rstrip() for l in block]
    block.append('')      # keep it a separate comment run from the first piece
    if mark in lines:
        i = lines.index(mark) - 1
        j = lines.index(RULE, i + 2)
        if j + 1 < len(lines) and lines[j + 1] == '':
            j += 1
        lines[i:j + 1] = block
        return
    i = 0
    while i < len(lines) and lines[i] != RULE and not lines[i].startswith(CMARK) and \
            (lines[i].startswith(';') or not lines[i].strip()):
        i += 1
    lines[i:i] = block


def _incbin_spans(lines, blob):
    """[(first_off, end_off, {off: [labels]})] for maximal runs of contiguous
    .incbin slices of `blob` separated only by labels, blank lines and this
    driver's own header blocks."""
    rx = re.compile(r'^\t\.incbin "includes/generated/%s\.bin", (0x[0-9A-Fa-f]+|\d+), '
                    r'(0x[0-9A-Fa-f]+|\d+)\s*$' % re.escape(blob))
    spans, cur, pend, in_hdr = [], None, [], False
    for l in lines:
        if l == RULE:
            in_hdr = not in_hdr
            continue
        if in_hdr or l.startswith(CMARK):
            continue
        m = rx.match(l)
        if m:
            o, n = int(m.group(1), 0), int(m.group(2), 0)
            if cur is not None and cur[1] == o:
                cur[1] = o + n
            else:
                cur = [o, o + n, {}]
                spans.append(cur)
            if pend:
                cur[2].setdefault(o, []).extend(pend)
            pend = []
            continue
        lm = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):$', l)
        if lm:
            pend.append(lm.group(1))
            continue
        if not l.strip():
            continue
        cur, pend = None, []
    return spans


def protected_ranges(v, blob, path, lines):
    """Blob offset ranges already typed by OBJECTS / REGIONS (their own
    headers must not be replaced by an object-run header)."""
    out = []
    sl = s_slices(path, blob, lines)
    for o in OBJECTS:
        if o['blob'] == blob and o['label'] in sl:
            a, n = sl[o['label']]
            out.append((a, a + n))
    for R in REGIONS:
        if R['blob'] == blob:
            cb = M.CBlob(os.path.join(ui(v), blob + '.c'))
            start, end, _, _ = R['builder'](cb, compile_blob(v, blob), sl)
            out.append((start, end))
    return sorted(out)


def apply_objruns(v, apply):
    m = objmap(v)
    for sname, blob in OBJRUN_FILES:
        path = os.path.join(ui(v), sname)
        raw = open(path, 'rb').read()
        lines = raw.decode('latin-1').split('\n')
        # a whole-file `.incbin "<blob>.bin"` becomes the (offset, length)
        # form, the same bytes, so it can be cut like the others
        whole = '\t.incbin "includes/generated/%s.bin"' % blob
        if whole in lines:
            n = os.path.getsize(os.path.join(ROOT, v, 'maincpu', 'includes', 'generated', blob + '.bin'))
            lines[lines.index(whole)] = whole + ', 0x0, 0x%X' % n
        base = blob_base(v, path, blob, lines)
        total = 0
        used = {}
        prot = protected_ranges(v, blob, path, lines)
        for S0, S1, labels_at in _incbin_spans(lines, blob):
            # split the span around already-typed ranges
            segs, a = [], S0
            for p0, p1 in prot:
                if p1 <= a or p0 >= S1:
                    continue
                if p0 > a:
                    segs.append((a, p0))
                a = max(a, p1)
            if a < S1:
                segs.append((a, S1))
            for a0, a1 in segs:
                la = {k: w for k, w in labels_at.items() if a0 <= k < a1}
                pieces = objrun_pieces(m, blob, base, a0, a1, la, used)
                total += rewrite_s_span(path, lines, blob, pieces)
        if used:
            note = wrap(FORMAT_NOTE) + '\n\nTables with objects in this file:\n\n' + \
                '\n\n'.join(wrap(_reg_full(m, r)) for _, r in sorted(used.items()))
            write_file_note(lines, blob, note)
        out = '\n'.join(lines).encode('latin-1')
        print('%s %s objruns: %+d lines, %+d bytes' % (v, sname, total, len(out) - len(raw)))
        if apply and out != raw:
            open(path, 'wb').write(out)


# Comment corrections, applied idempotently to v10, v9 and v7: (file, the
# exact old text, the new text).  Each one corrects a claim PROVEN false; the
# reason is in the new text itself.
TEXT_FIXES = [
    ('control_menu_screens.s',
     """; ===========================================================================
; CPU Data Transmission Error Dialog Widgets (Screen Group 7)
; ===========================================================================
; These widgets form the error dialog displayed when Sub-CPU payload
; transfer fails during boot. The dialog shows a severe hardware error
; that typically requires service center attention.
;
; Widget format:
;   Byte 0-1: Entry length (low byte) + 0x00
;   Byte 2-3: Widget type = 0x0160 (text widget)
;   Byte 4-5: Screen group ID (0x07 = error dialogs)
;   Byte 6-7: Flags (0xffff = default)
;   Byte 8-9: Widget index within screen group
;   Remaining: Widget-specific data (position, font, text)
; ===========================================================================

; ---------------------------------------------------------------------------
; Widget 9: CAUTION!! Header
; Screen group 7, index 9
; ---------------------------------------------------------------------------
ErrorDialog_CautionHeader:
	.byte 0x2b, 0x00	; Entry length: 43 bytes
""",
     """; ===========================================================================
; CPU data-transmission error messages: elements 8-12 of the Viewable table
; of slot 0xf4 (0xed7c62, 14 entries, registered by InitializeToshi in
; extensions/extension_init.s)
; ===========================================================================
; Five records of class Label (class id 0x0160002b: root Class table, slot
; 0x160, entry 0x2b; 32 bytes: class, super, sub, next, prev, flag, rect,
; str, font, fontcolor -- the firmware's own field names) whose strings are
; "CAUTION!!", "** ERROR in CPU data transmission **", "Please try turning
; off and on again.", "If this message appears again," and "this unit
; needs repairing." (the text follows each record in
; extensions/extension_data.s).  Their parent (`super`) is element 7, a
; Window named "TEST1CP" in the parallel ResName table (slot 0x3f4);
; elements 1-6 are the "TEST1RAM" Window and its Labels; elements 0 and 13
; are full-screen (0,0)-(319,239) TtlScreen records.  The .include of this
; file sits in extension_data.s, which carries the rest of element 8 after
; the two bytes below, and elements 9-12.
;
; Record layout: the Viewable fields, +0 class id, +4 super (parent
; element), +6 sub (first child), +8 next, +10 prev (element indices,
; 0xffff = none), +12 flag, +14..+20 rect x1, y1, x2, y2 (element 8:
; (78,128)-(225,146), inside its parent's (4,120)-(315,237)); all 14 links
; of slot 0xf4 consistent (scripts/analysis/nakarest_objtab_map.py; lane
; ext's ext_lane_checks.py test1 found the same).
;
; CORRECTED (lane nakarest, 2026-09-25): this block used to describe the
; records as "Byte 0-1: entry length, Byte 2-3: widget type 0x0160, Byte
; 4-5: screen group ID (0x07 = error dialogs), Byte 6-7: flags, Byte 8-9:
; widget index within screen group", call this one "Widget 9 ... Screen
; group 7, index 9", and read the two bytes below as "Entry length: 43
; bytes".  Proven false by the links: the 0x07 at +4 is the parent element
; (element 7's +6 first child is 8), the 0x09 at +8 is the next sibling
; (element 9's +10 is 8), and 0x2b is the class index of Label for every
; one of the five records, whatever their length.  The earlier header's
; purpose statement, kept as written (not re-verified here -- note that the
; parent panel is named TEST1CP):
; These widgets form the error dialog displayed when Sub-CPU payload
; transfer fails during boot. The dialog shows a severe hardware error
; that typically requires service center attention.
; ===========================================================================
ErrorDialog_CautionHeader:
	.byte 0x2b, 0x00	; class id 0x0160002b (Label), low half: index 0x2b
"""),
]


# Evidence lines inserted directly above a label (idempotent): (file, label,
# text).  Lines are `; [nakarest] ` comments, replaced on every run.
LABEL_NOTES = [
    ('sequencer_channel_containers.s', 'Naka_DrawbarReg_Table',
     'Naka_DrawbarReg_Table: despite the name, entries 0-11 are the WALLPAPER PALETTE table: '
     'pointers to NakaColor_Palette2, 1, 6, 5, 4, 3, 10, 9, 8, 7, Blank, Blank '
     '(debug_naming_panel_sim.s).  This blob lies wholly inside the work-RAM initial image '
     '(ROM 0xEED8C8 onward, CharMap_FullPermutation_0x7B0) that Boot_InitWorkRAM copies with '
     'ldir, so the table '
     'lives at RAM 0x3F1E4, where GetWallPaletteRGB (display/graphics_text_vga.s: `ld xde, '
     '0x3f1e4`) indexes it (`sll 2`) and returns entry [colour] of the palette; '
     'ChangeWallPalette_Impl sets DAC entries 0xE0..0xEF from it.  Entries 12 on '
     '(SeqChan_Map_*) are not part of that table.'),
    ('naka_debug_proc_names.s', 'DbgStr_NakaProcName_Table',
     'DbgStr_NakaProcName_Table: entries 1-45 of the NAME table of ApFunction slot 0x427 '
     '(0xE2031C, 46 entries), registered by InitializeYoko with RegObjTabl 0x1600002, '
     'ApFunctionProc, 0x2E, 0xE2031C, 0x427 (sequencer/sequencer_ui.s) -- the names of the '
     '46 procedures of the parallel ApFunction table, slot 0x127.  The label sits one entry '
     'into the table: entry 0 (-> "PartSelLangCheck", DbgStr_PartSelLangCheck below) is '
     'the LAST 4 bytes of sepaout_config.bin (ui/sepaout_config.s), whose C blob runs 4 '
     'bytes into this table.  The strings follow in reverse order; entry 45 is the empty '
     'string (DbgStr_EmptyProc).  The DbgStr_ prefix is historical: nothing here is '
     'debug-only.'),
    ('naka_debug_proc_names.s', 'DbgStr_EmptyProc',
     'Name strings of the ApFunction name table above (slot 0x427, InitializeYoko), '
     'entries 45 down to 0, each NUL-terminated and 0xFF-padded to even length '
     '(aligned_string).'),
]


def apply_label_notes(v, apply):
    by = {}
    for f, lab, text in LABEL_NOTES:
        by.setdefault(f, []).append((lab, text))
    for f, notes in by.items():
        path = os.path.join(ui(v), f)
        raw = open(path, 'rb').read()
        lines = raw.decode('latin-1').split('\n')
        for lab, text in notes:
            idx = [i for i, l in enumerate(lines) if re.match(r'^%s:' % re.escape(lab), l)]
            if len(idx) != 1:
                raise SystemExit('%s: label %s found %d times' % (path, lab, len(idx)))
            i = idx[0]
            j = i
            while j > 0 and lines[j - 1].startswith(CMARK):
                j -= 1
            lines[j:i] = [lower_hex(CMARK + w)
                          for w in textwrap.wrap(text, width=96 - len(CMARK),
                                                 break_long_words=False, break_on_hyphens=False)]
        out = '\n'.join(lines).encode('latin-1')
        print('%s %s: label notes %+d bytes' % (v, f, len(out) - len(raw)))
        if apply and out != raw:
            open(path, 'wb').write(out)


def apply_text_fixes(v, apply):
    for sname, old, new in TEXT_FIXES:
        path = os.path.join(ui(v), sname)
        b = open(path, 'rb').read()
        if new.encode() in b:
            continue
        if b.count(old.encode()) != 1:
            raise SystemExit('%s: text fix anchor found %d times' % (path, b.count(old.encode())))
        print('%s %s: comment correction applied' % (v, sname))
        if apply:
            open(path, 'wb').write(b.replace(old.encode(), new.encode()))


def apply_style_ui_params(v, apply):
    """style_ui_params.s: evidence lines above each ParamBlock / ScreenData
    label and the pointer table (the blobs are typed in style_ui/*.c, another
    lane's files; this is the .s side only)."""
    path = os.path.join(ui(v), 'style_ui_params.s')
    raw = open(path, 'rb').read()
    lines = raw.decode('latin-1').split('\n')
    lines = [l for l in lines if not l.startswith(CMARK)]
    R = refs(v)
    T = R.sym['StyleUI_ParamBlockPtrTable']
    rom = R.rom
    entries = [int.from_bytes(rom[T - 0xE00000 + 4 * i:T - 0xE00000 + 4 * i + 4], 'little')
               for i in range(76)]
    by_target = {}
    for i, e in enumerate(entries):
        by_target.setdefault(e, []).append(i)
    names = {v_: n for n, v_ in R.sym.items() if n.startswith('StyleUI_')}
    out = []
    for l in lines:
        m = re.match(r'^(StyleUI_\w+):', l)
        if m:
            lab = m.group(1)
            a = R.sym[lab]
            if lab == 'StyleUI_ParamBlockPtrTable':
                text = ('StyleUI_ParamBlockPtrTable: 4 tables x 19 pointers (76 entries). '
                        'Scoop_InitPartDisplay and Scoop_SelectModeTable_2Part scale a mode '
                        'index by 4 (`sla hl, 2`), load xiy from +0x00 and xix from +0x4C -- '
                        'or from +0x98 and +0xE4 when the byte at 0x0D65 is 2 -- and hand the '
                        'pair to UIRender_TwoTableGeneral; Scoop_InitDisplayFull reads it '
                        'too.  Every entry is one of the ParamBlock / ScreenData objects of '
                        'this file (the .long lines below).')
            else:
                idx = by_target.get(a, [])
                direct = sorted({u[5] for u in R.in_range(a, a + 1)
                                 if u[5] and u[5] != 'StyleUI_ParamBlockPtrTable'})
                kind = 'ParamBlock' if 'ParamBlock' in lab else 'ScreenData'
                src = ('style_ui/paramblock/%s.c' % lab.split('_')[-1].lower() if kind == 'ParamBlock'
                       else 'style_ui/%s.c' % lab.split('_')[-1].lower())
                text = ('%s: Style-UI ScreenData bytecode -- the sd_* commands of '
                        'style_ui/screendata_types.h (lines, rects, labelled refs, strings), '
                        'typed in %s -- drawn by UIRender_TwoTableGeneral, which hands its '
                        'xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  '
                        'Reached through %s%s.' % (
                            lab, src,
                            ('StyleUI_ParamBlockPtrTable entries %s' % _ranges(idx)) if idx
                            else 'no StyleUI_ParamBlockPtrTable entry',
                            ('; loaded directly by %s' % ', '.join(direct[:6])) if direct else ''))
            wrapped = textwrap.wrap(text, width=96 - len(CMARK), break_long_words=False,
                                    break_on_hyphens=False)
            out += [lower_hex(CMARK + w)
                    for w in wrapped]
        out.append(l)
    new = '\n'.join(out).encode('latin-1')
    print('%s style_ui_params.s: %+d bytes' % (v, len(new) - len(raw)))
    if apply and new != raw:
        open(path, 'wb').write(new)


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
        apply_text_fixes(v, args.apply)
        apply_label_notes(v, args.apply)
        apply_objruns(v, args.apply)
        apply_style_ui_params(v, args.apply)


if __name__ == '__main__':
    main()
