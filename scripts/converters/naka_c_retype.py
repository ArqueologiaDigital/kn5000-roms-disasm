#!/usr/bin/env python3
r"""naka_c_retype.py -- give the objects inside the big NAKA blob C sources real C types.

QUESTION ANSWERED
-----------------
`naka_widget_descriptors.c`, `naka_widget_tables_1.c` and `naka_widget_tables_2.c`
(v10, v9 and v7 carry identical copies) were generated with one anonymous
`uint16_t field_XXXX` per word across whole blobs -- including 8bpp bitmaps of
up to 32 KB, fill runs and text.  This driver re-expresses each object listed
in OBJECTS below as a typed member (a bitmap as `uint8_t name[height][stride]`,
a fill run as an explicit fill array, text as `char[]`), with a header comment
naming the code that reads it, and leaves every other member untouched.

The values are taken from the blob as it compiles TODAY
(`v10/maincpu/includes/generated/<blob>.bin`, which must be built first), so
the new source is derived from the bytes and cannot drift from them; `make
gate` certifies the result.  The .s slice labels are not touched here -- their
evidence headers are written by `naka_s_headers.py`.

Each OBJECTS entry is pinned by the `.s` slice label that already names the
object (`Label: .incbin "includes/generated/<blob>.bin", off, len`), so the
offset is read from the tree, not typed in; the entry states the dimensions
and they are checked against the slice length (w_stride * h must equal len).

RUN
    python3 scripts/converters/naka_c_retype.py                 # dry run, v10
    python3 scripts/converters/naka_c_retype.py --apply         # v10 C, then
                                                                #  copied to v9/v7
    python3 scripts/converters/naka_c_retype.py --render DIR    # PNGs of every
                                                                #  bitmap (palette
                                                                #  v10/maincpu/images/
                                                                #  Palette_8bit_RGBA.bin)
    make gate                                                   # certify

The PNG render is how the dimensions were checked by eye: a wrong width shears
the picture diagonally, a right one shows the drawing.
"""
import argparse
import os
import re
import shutil
import textwrap
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import naka_c_model as M  # noqa: E402

UI = 'v10/maincpu/ui_widgets'
GEN = 'v10/maincpu/includes/generated'
S_FOR = {
    'naka_widget_descriptors': 'widget_descriptors.s',
    'naka_widget_tables_1': 'naka_widget_tables_1.s',
    'naka_widget_tables_2': 'naka_widget_tables_2.s',
}

# Per-version addresses are quoted in every header so the text is identical
# across v10/v9/v7 (the blobs are byte-identical there; only the readers move).
# Resolved from rebuilt_ROMs/kn5000_<v>_program.llvm.elf on 2026-09-25.
ADDR = {
    'DrawBitmapSPFast':      ('0xFAC3DB', '0xFAC3DB', '0xFABFCE'),
    'DrawBitmapSPFast_Impl': ('0xFAC457', '0xFAC457', '0xFAC04A'),
    'VwUserBitmapProc':      ('0xF9C54C', '0xF9C54C', '0xF9C13F'),
    'MdCmptCnctFunc':        ('0xF74B40', '0xF74B40', '0xF7473C'),
    'SplitPointFunc':        ('0xF748B7', '0xF748B7', '0xF744B3'),
    'BitmapBmphk':           ('0xF73580', '0xF73580', '0xF7317C'),
    'BitmapNtedt0k':         ('0xF35D62', '0xF35D62', '0xF35D38'),
    'BitmapNtedt0d':         ('0xF35D8F', '0xF35D8F', '0xF35D65'),
    'BitmapDredt0k':         ('0xF35DBC', '0xF35DBC', '0xF35D92'),
    'BitmapDredt0d':         ('0xF35DE9', '0xF35DE9', '0xF35DBF'),
}


def a(name):
    v = ADDR[name]
    if v[0] == v[1] == v[2]:
        return '%s (%s in v10/v9/v7)' % (name, v[0])
    if v[0] == v[1]:
        return '%s (v10/v9 %s, v7 %s)' % (name, v[0], v[2])
    return '%s (v10 %s, v9 %s, v7 %s)' % (name, v[0], v[1], v[2])


DRAW_8BPP = (
    "Pixel format, from {impl}: 8 bpp, one palette index per byte\n"
    "(palette: Palette_8bit_RGBA), rows top to bottom.  The routine copies\n"
    "`width` bytes per row to VRAM 0x43C00 + 320*y + x with Mem_Copy and then\n"
    "advances the source by (width + 1) & ~1, so a row occupies the width\n"
    "rounded up to even; the pad byte of an odd-width row is never drawn.")

USERBITMAP = (
    "Drawn by the UserBitmap view class: {VwUserBitmapProc}, on paint\n"
    "(0x1C0000D), calls the instance's function with 0x1E000A1 (address),\n"
    "0x1E000A2 (width) and 0x1E000A3 (height) and hands the three to\n"
    "{DrawBitmapSPFast}.")


def bitmap(label, w, h, blob, who, shows):
    stride = (w + 1) & ~1
    return dict(kind='bitmap', blob=blob, label=label, w=w, h=h, stride=stride,
                who=who, shows=shows)


NOTE_NAME = {'C': 'C', 'Db': 'D flat', 'D': 'D', 'Eb': 'E flat', 'E': 'E',
             'F': 'F', 'Gb': 'G flat', 'G': 'G', 'Ab': 'A flat', 'A': 'A',
             'Bb': 'B flat', 'B': 'B'}

MIDICONN = (
    "{MdCmptCnctFunc}, on message 0x1E00042 (paint), reads the mode word\n"
    "at +4 of the message's parameter block (the xde argument), Strcpy's a\n"
    "caption into the buffer whose pointer is at +8, and draws %s:\n"
    "pushw 0x6C (height 108), ldw de,0x128 (width 296),\n"
    "ld xbc,<this bitmap>, call {DrawBitmapSPFast}.")

SPLITPOINT = (
    "{SplitPointFunc} draws a 5-octave keyboard strip one octave at a\n"
    "time at x += 0x38 (56, so neighbours overlap by one column): pushw 0x34\n"
    "(height 52), ldw de,0x39 (width 57), call {DrawBitmapSPFast}.\n"
    "Octaves wholly below the split octave use Bitmap_SplitPoint_B, the\n"
    "split octave uses entry 1 + (split note mod 12) of the 13-entry table at\n"
    "SplitPoint_NoteEntry_C_Code+4 (entry 0 = Bitmap_SplitPoint_no_split,\n"
    "entries 1..12 = C..B), and the octaves above use\n"
    "Bitmap_SplitPoint_no_split.")

OBJECTS = [
    # ------------------------------------------------ naka_widget_tables_2
    bitmap('Bitmap_MIDIConnections_1', 296, 108, 'naka_widget_tables_2',
           MIDICONN % ("this bitmap for mode 0 (caption \"NORMAL\" at 0xE7F848) and "
                    "for any mode other than 0/1/2 (caption \"Error!\" at 0xE7F896)"),
           "MIDI routing diagram for the COMPUTER-port setting: boxes PC,\n"
           "MASTER KEYBOARD, EXTERNAL MODULE above a KN5000 panel with the\n"
           "COMPUTER, MIDI IN and MIDI OUT sockets.  Variant 1: PC <-> COMPUTER,\n"
           "the PC stream also routed to MIDI OUT; MIDI IN unused."),
    bitmap('Bitmap_MIDIConnections_2', 296, 108, 'naka_widget_tables_2',
           MIDICONN % "this bitmap for mode 1 (caption \"KN as master\" at 0xE7F862)",
           "The same diagram, variant 2: the PC stream goes to MIDI OUT\n"
           "only (no arrow into the KN5000), KN5000 -> PC."),
    bitmap('Bitmap_MIDIConnections_3', 296, 108, 'naka_widget_tables_2',
           MIDICONN % "this bitmap for mode 2 (caption \"KN as slave\" at 0xE7F87C)",
           "The same diagram, variant 3: MASTER KEYBOARD -> MIDI IN, routed\n"
           "on to the PC through COMPUTER; PC -> KN5000 and MIDI OUT."),
    bitmap('Bitmap_Bmphk', 100, 120, 'naka_widget_tables_2',
           "{BitmapBmphk} answers 0x1E000A1 with this address,\n"
           "0x1E000A2 with 0x64 (width 100) and 0x1E000A3 with 0x78 (height 120).\n"
           + USERBITMAP,
           "A picture of the KN5000 itself (keyboard, display, panel) on a\n"
           "teal background.  BitmapBmphk sits in the MIDI-menu entry table\n"
           "EmbeddedPtrTable_*_naka_widget_descriptors_024400, between the\n"
           "MIDI preset functions and TtMdGm."),
] + [
    bitmap('Bitmap_SplitPoint_' + n, 57, 52, 'naka_widget_tables_2', SPLITPOINT,
           ("One octave of keys, C to B, none tinted: an octave wholly\n"
            "above the split point.") if n == 'no_split' else
           ("One octave of keys, C to B, with the keys from C up to and\n"
            "including %s tinted (white keys cyan, black keys blue): the\n"
            "octave that contains a split point at %s%s.")
           % (NOTE_NAME[n], NOTE_NAME[n],
              '; also drawn for every octave wholly below the split'
              if n == 'B' else ''))
    for n in ('no_split', 'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A',
              'Bb', 'B')
] + [
    # ------------------------------------------------ naka_widget_descriptors
    bitmap('Bitmap_Ntedt0k', 16, 127, 'naka_widget_descriptors',
           "{BitmapNtedt0k} answers 0x1E000A1 with this address,\n"
           "0x1E000A2 with 0x10 (width 16) and 0x1E000A3 with 0x7F (height 127).\n"
           + USERBITMAP,
           "A vertical piano-key strip (black keys pointing left): the key\n"
           "column beside the note grid Bitmap_Ntedt0d.  Both procs sit in\n"
           "sequencer/sequencer_ui.s just before bmdredit_routines.s."),
    bitmap('Bitmap_Ntedt0d', 240, 127, 'naka_widget_descriptors',
           "{BitmapNtedt0d} answers 0x1E000A1 with this address,\n"
           "0x1E000A2 with 0xF0 (width 240) and 0x1E000A3 with 0x7F (height 127).\n"
           + USERBITMAP,
           "An empty dotted grid, 10 columns: the background the note grid\n"
           "is drawn on, beside the key strip Bitmap_Ntedt0k."),
    bitmap('Bitmap_Dredt0k', 88, 119, 'naka_widget_descriptors',
           "{BitmapDredt0k} answers 0x1E000A1 with this address,\n"
           "0x1E000A2 with 0x58 (width 88) and 0x1E000A3 with 0x77 (height 119).\n"
           + USERBITMAP,
           "A ruled column (horizontal rules, right-hand border): the row-name\n"
           "column beside the dotted grid Bitmap_Dredt0d."),
    bitmap('Bitmap_Dredt0d', 168, 119, 'naka_widget_descriptors',
           "{BitmapDredt0d} answers 0x1E000A1 with this address,\n"
           "0x1E000A2 with 0xA8 (width 168) and 0x1E000A3 with 0x77 (height 119).\n"
           + USERBITMAP,
           "An empty dotted grid, 7 columns, beside the ruled name column\n"
           "Bitmap_Dredt0k.  Its procs sit in sequencer/sequencer_ui.s directly\n"
           "before `.include \"sequencer/bmdredit_routines.s\"`."),
]


def s_slices(sfile, blob):
    """label -> (off, len) from `Label:` + `.incbin ".../<blob>.bin", off, len`."""
    txt = open(sfile, encoding='latin-1').read()
    rx = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*\n\s*\.incbin\s+"includes/generated/'
                    + re.escape(blob) + r'\.bin",\s*(0x[0-9A-Fa-f]+|\d+),\s*(0x[0-9A-Fa-f]+|\d+)',
                    re.M)
    return {m.group(1): (int(m.group(2), 0), int(m.group(3), 0)) for m in rx.finditer(txt)}


def fmt(text):
    return re.sub(r'\{([A-Za-z_0-9]+)\}', lambda m: a(m.group(1)), text)


def wrap(text, width=70):
    """Re-flow each blank-line-separated paragraph to `width` columns."""
    out = []
    for para in text.split('\n\n'):
        out.append(textwrap.fill(' '.join(para.split()), width=width,
                                 break_long_words=False, break_on_hyphens=False))
    return '\n\n'.join(out)


def bitmap_header(o):
    title = ('%s  --  %d x %d bitmap, 8 bpp, row stride %d, %d bytes'
             % (o['label'], o['w'], o['h'], o['stride'], o['stride'] * o['h']))
    body = '\n\n'.join([
        'What it shows (render): ' + o['shows'],
        'Reader: ' + fmt(o['who']),
        fmt(DRAW_8BPP.replace('{impl}', '{DrawBitmapSPFast_Impl}')),
        "Dimensions pinned twice: the reader's own width/height constants, "
        "and width-rounded-to-even x height == the slice length.  A PNG render "
        "(scripts/converters/naka_c_retype.py --render DIR) shows the drawing "
        "upright; a wrong width would shear it.",
    ])
    return title + '\n\n' + wrap(body)


def build(apply, render_dir):
    blobs = {}
    for o in OBJECTS:
        blobs.setdefault(o['blob'], []).append(o)
    for blob, objs in blobs.items():
        cpath = os.path.join(ROOT, UI, blob + '.c')
        bpath = os.path.join(ROOT, GEN, blob + '.bin')
        data = open(bpath, 'rb').read()
        sl = s_slices(os.path.join(ROOT, UI, S_FOR[blob]), blob)
        cb = M.CBlob(cpath)
        if len(data) != cb.size:
            raise SystemExit('%s: bin is %d B, struct %d B -- rebuild first' % (blob, len(data), cb.size))
        # contiguous objects are retyped as ONE run, so only the run's outer
        # edges need to fall on (or be split to) member boundaries
        runs = []
        for o in sorted(objs, key=lambda o: sl[o['label']][0]):
            off, ln = sl[o['label']]
            k = cb.by_name.get(o['label'])
            if k is not None and cb.members[k].offset == off and cb.members[k].size == ln:
                print('%-26s %-28s already typed' % (blob, o['label']))
                continue
            if runs and runs[-1][1] == off:
                runs[-1][1] = off + ln
                runs[-1][2].append(o)
            else:
                runs.append([off, off + ln, [o]])
        if not runs and not apply:
            continue
        for start, end, run in runs:
            new = []
            for o in run:
                off, ln = sl[o['label']]
                if o['kind'] == 'bitmap':
                    if o['stride'] * o['h'] != ln:
                        raise SystemExit('%s: %d x %d (stride %d) != slice %d B'
                                         % (o['label'], o['w'], o['h'], o['stride'], ln))
                    pix = data[off:off + ln]
                    if render_dir:
                        render(render_dir, o, pix)
                    new.append(M.bitmap_member(o['label'], pix, o['w'], o['h'], o['stride'],
                                               pre=M.comment_block(bitmap_header(o)),
                                               per_line=24))
                print('%-26s %-28s +0x%05X %6d B  %s'
                      % (blob, o['label'], off, ln,
                         '%dx%d stride %d' % (o['w'], o['h'], o['stride'])
                         if o['kind'] == 'bitmap' else o['kind']))
            # every symbolic initializer inside a BITMAP run is a false pointer:
            # pixel bytes such as FF FF FF 00 that the generator read as
            # NAKA_ADDR(NakaData_RomEnd) = 0x00FFFFFF.  They are listed, and the
            # bytes are kept exactly (they come from the blob).
            allbmp = all(o['kind'] == 'bitmap' for o in run)
            fps = []
            if allbmp:
                for mb in cb.members:
                    if start <= mb.offset < end and \
                            M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr):
                        fps.append(mb.name)
            dropped, remap = cb.retype(start, end, new, data, false_pointers=fps)
            syms = sorted(set(re.findall(r'NAKA_ADDR\((\w+)\)', ' '.join(
                e.expr for e in []))))
            print('   run +0x%05X..+0x%05X: %d false pointers dropped, SELF remaps %s'
                  % (start, end, len(dropped), remap or '-'))
        bm = [o['label'] for o in objs if o['kind'] == 'bitmap']
        n = cb.symbolize_self_pointers(bm)
        print('   %d numeric pointers to these objects made SELF(...)' % n)
        if apply:
            before = open(cpath, encoding='latin-1').read()
            cb.write()
            pruned = prune_externs(cpath, before)
            if pruned:
                print('   externs no longer referenced (false pointers retired): %s' % pruned)
            for v in ('v9', 'v7'):
                for src in (cpath, cpath[:-2] + '_link.ld'):
                    shutil.copyfile(src, src.replace(os.path.join(ROOT, 'v10'),
                                                     os.path.join(ROOT, v)))
            print('wrote %s (+ _link.ld, + v9, v7 copies)' % os.path.relpath(cpath, ROOT))


def prune_externs(cpath, before):
    """Symbols that the source used as NAKA_ADDR(...) before this pass and no
    longer uses at all were false pointers inside the retyped objects (e.g.
    NakaData_RomEnd = 0x00FFFFFF read out of FF FF FF 00 pixels).  Drop their
    `extern` declaration and their linker-script definition, so the file stops
    asserting that the blob points at them."""
    after = open(cpath, encoding='latin-1').read()
    ldpath = cpath[:-2] + '_link.ld'
    ld = open(ldpath, encoding='latin-1').read()
    gone = []
    for sym in re.findall(r'^extern const char ([A-Za-z0-9_]+);$', after, re.M):
        was = before.count('NAKA_ADDR(%s)' % sym)
        now = len(re.findall(r'\b%s\b' % re.escape(sym), after)) - 1   # minus the extern
        if was and now == 0:
            gone.append(sym)
            after = re.sub(r'^extern const char %s;\n' % re.escape(sym), '', after, flags=re.M)
            ld = re.sub(r'^%s = 0x[0-9A-Fa-f]+;\n' % re.escape(sym), '', ld, flags=re.M)
    if gone:
        open(cpath, 'w', encoding='latin-1', newline='').write(after)
        open(ldpath, 'w', encoding='latin-1', newline='').write(ld)
    return gone


def render(d, o, pix):
    from PIL import Image
    os.makedirs(d, exist_ok=True)
    p = open(os.path.join(ROOT, 'v10/maincpu/images/Palette_8bit_RGBA.bin'), 'rb').read()
    pal = b''.join(p[i:i + 3] for i in range(0, 1024, 4))
    w, h, st = o['w'], o['h'], o['stride']
    img = Image.new('P', (w, h))
    img.frombytes(b''.join(pix[y * st:y * st + w] for y in range(h)))
    img.putpalette(pal)
    img = img.convert('RGB').resize((w * 2, h * 2), Image.NEAREST)
    img.save(os.path.join(d, o['label'] + '.png'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--render', metavar='DIR')
    args = ap.parse_args()
    for v in ('v9', 'v7'):
        for blob in S_FOR:
            p1 = os.path.join(ROOT, UI, blob + '.c')
            p2 = p1.replace(os.path.join(ROOT, 'v10'), os.path.join(ROOT, v))
            if open(p1, 'rb').read() != open(p2, 'rb').read():
                raise SystemExit('%s differs from v10 -- this driver assumes identical copies' % p2)
    build(args.apply, args.render)


if __name__ == '__main__':
    main()
