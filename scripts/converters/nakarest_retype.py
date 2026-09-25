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

VERSIONS = ('v10', 'v9', 'v7')
LLVM = os.path.expanduser('~/compartilhado/llvm-project/build/bin')
S_FOR = {
    'naka_technichord_strings': 'technichord_string_data.s',
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
    "data, custom data or HD-AE5000 images (searched 2026-09-25), so how -- or "
    "whether -- they are reached is not established.  The three bitmaps are "
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


def build_c(v, apply, render_dir):
    blobs = {}
    for o in OBJECTS:
        blobs.setdefault(o['blob'], []).append(o)
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--render', metavar='DIR')
    ap.add_argument('--only-s', action='store_true', help='write only the .s headers')
    args = ap.parse_args()
    for v in VERSIONS:
        if not args.only_s:
            build_c(v, args.apply, args.render)
        apply_s(v, args.apply)


if __name__ == '__main__':
    main()
