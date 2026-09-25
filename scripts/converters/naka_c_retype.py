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


_NM = {}


def _nm(v):
    """name -> address from rebuilt_ROMs/kn5000_<v>_program.llvm.elf (llvm-nm),
    for names the ADDR table does not pin."""
    if v not in _NM:
        import subprocess
        nm = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-nm')
        elf = os.path.join(ROOT, 'rebuilt_ROMs', 'kn5000_%s_program.llvm.elf' % v)
        out = subprocess.run([nm, '--defined-only', elf], capture_output=True,
                             text=True, check=True).stdout
        d = {}
        for ln in out.split('\n'):
            f = ln.split()
            if len(f) == 3 and f[1] in 'tT':
                d.setdefault(f[2], '0x%06X' % int(f[0], 16))
        _NM[v] = d
    return _NM[v]


def a(name):
    v = ADDR.get(name)
    if v is None:
        v = tuple(_nm(ver).get(name) for ver in ('v10', 'v9', 'v7'))
        if v[0] is None:
            raise SystemExit('cannot resolve %s in the v10 ELF' % name)
        ADDR[name] = v
    if v[2] is None:
        return '%s (v10 %s, v9 %s, not labelled in v7)' % (name, v[0], v[1])
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


# ---------------------------------------------------------------------------
# Non-bitmap objects.  Each builder receives the parsed blob, the compiled
# bytes and the blob offset of its anchor label, asserts what it relies on
# about the bytes, and returns (start, end, new_members, reexpressed) where
# `reexpressed` names old members whose symbolic initializer the new typing
# carries (so the model does not report it as dropped).
# ---------------------------------------------------------------------------

def _hexbytes(bs, per=16, indent='        '):
    return '\n'.join(indent + ', '.join('0x%02X' % b for b in bs[i:i + per]) + ','
                     for i in range(0, len(bs), per))


def _barr(name, bs, pre=(), tail=''):
    return M.NewMember('uint8_t', name, '[%d]' % len(bs), len(bs),
                       '{\n' + _hexbytes(bs) + '\n    }', pre, tail)


def _u32arr(name, vals, pre=(), tail=''):
    body = '\n'.join('        %s,' % v for v in vals)
    return M.NewMember('uint32_t', name, '[%d]' % len(vals), 4 * len(vals),
                       '{\n' + body + '\n    }', pre, tail)


def _astr(name, bs, pre=(), tail=''):
    """A NUL-terminated string padded with 0xFF to even length, as
    ALIGNED_STRING() writes it."""
    n = len(bs)
    text = bs.split(b'\0')[0]
    if bs == text + b'\0':
        expr = M.c_string(text)
    elif bs == text + b'\0\xff':
        expr = 'ALIGNED_STRING(%s)' % M.c_string(text)
    else:
        raise SystemExit('%s: %r is not an aligned string' % (name, bs))
    return M.NewMember('char', name, '[%d]' % n, n, expr, pre, tail)


def build_accseq_region(cb, data, off0):
    """NakaInst_OFF_Str's slice (0xE4C0D2..0xE55260) is not one string: it is
    "OFF", 208 B of constants that routines in sequencer/accompaniment_engine.s
    copy or pass by address, the 78-record AccompSeq style-data table, and the
    103 event streams those records point at.  (The last 80 B, the head of the
    ApFunction table, are typed by build_apfunction_tables.)"""
    base = cb.base()
    u32 = lambda o: int.from_bytes(data[o:o + 4], 'little')
    assert data[off0:off0 + 4] == b'OFF\0'
    c = off0 + 4                               # 0x1B276 -- the constants
    T = off0 + 0xD4                            # 0x1B346 -- the record table
    first_stream = u32(T + 1) - base
    nrec = (first_stream - T) // 32
    assert (first_stream - T) % 32 == 0 and nrec == 78, (hex(first_stream), nrec)
    parts, starts = [], set()
    for i in range(nrec):
        for h in (0, 16):
            r = T + 32 * i + h
            p1, p2 = u32(r + 1), u32(r + 5)
            parts.append((i, h // 16, r, p1, p2))
            if p1:
                starts.add(p1 - base)
    starts = sorted(starts)
    end = off0 + 0x913E                        # 0x243B0 -- ApFunction table
    assert all(first_stream <= s < end for s in starts)
    for s_ in starts:
        assert data[s_:s_ + 6] == bytes.fromhex('80ffffffff87'), hex(s_)
    owner = {}
    for i, part, r, p1, p2 in parts:
        if p1:
            owner[p1 - base] = 'AccompSeq_Stream_%02d_%s' % (i, 'ab'[part])
    bounds = starts + [end]
    streams = [(owner[a], a, b) for a, b in zip(bounds, bounds[1:])]

    def ptr(v):
        if v == 0:
            return '0'
        o = v - base
        for nm, a, b in streams:
            if a <= o < b:
                return 'SELF(%s)' % nm if o == a else 'SELF(%s[%d])' % (nm, o - a)
        raise SystemExit('record pointer 0x%X outside the streams' % v)

    rodata = [
        ('SndArgNmGet_Bytes5', 'u8', 6,
         '{SndArgNmGet}: ld xiy,<this>; ld bc,2; ldirw; ldi -- copies the\n'
         'first 5 bytes to its frame; the 6th is 0xFF padding.'),
        ('SndArgNmGet_RamPtrsA', 'u32', 20,
         '{SndArgNmGet}: ldirw 10 words to its frame.  Five RAM addresses,\n'
         '0x39F8 + 0x11*k (v7 applies -0x9C through v7_c_divergence.json).'),
        ('SndArgNmGet_RamPtrsB', 'u32', 20,
         '{SndArgNmGet}: ldirw 10 words.  Five RAM addresses 0x39E4 + 4*k.'),
        ('CmpStepTitleFunc_ProcTable', 'u32', 16,
         '{CmpStepTitleFunc}: ldirw 8 words to its frame and passes the\n'
         'copy to {DirmdEmulator_Entry}.  Four code addresses inside\n'
         'CmpStepTitleFunc\'s own region (0xF6A2FF = CmpStep_DataBlock,\n'
         '0xF6A32C, 0xF6A339, 0xF6A346 in v10/v9; v7 relocates them by -0x404\n'
         'through v7_c_divergence.json) -- code entry points that the\n'
         'accompaniment_engine.s framing does not yet show as code.'),
        ('AccBankData_SlotOrder', 'u8', 30,
         '{AccBankData_SlotScan_Loop}: lda xwa,<this> and indexes it with\n'
         '3*slot + bank.  Entries 0-11 are 0,4,8,1,5,9,2,6,10,3,7,11 and\n'
         '12-29 are 12,18,24,13,19,25,...: a column-major renumbering.'),
        ('StylCnvModl_CnvFilter', 'u8', 12,
         '{StylCnvModlTtlFunc}: ld xwa,<this>; call {ControlState_ProcessCommand}.\n'
         'u16 2, then "*.CNV,***" -- a file-selector filter.'),
        ('StylCnvModl_VerFilter', 'u8', 12,
         '{StylCnvModl_ClearDisplayBuf}: ld xwa,<this>; call\n'
         'ControlState_ProcessCommand.  u16 2, then "*.VER,***".'),
        ('StylCnv_ModeRb_Select', 'str', 4,
         '{StylCnvModl_OK_SelectItem}: ld xbc,<this>; call\n'
         '{FileIO_OpenWithBuiltPath} -- the fopen-style mode "rb".'),
        ('StylCnv_Str_Stars', 'str', 4,
         '"***": no reader found (searched: label and 24-bit operand forms of\n'
         '0xE4C14E across the v10 ROM).'),
        ('StylCnv_ModeRb_Type3', 'str', 4, '{StylCnv_Type3_LoadFileLoop}: mode "rb" for FileIO_OpenWithBuiltPath.'),
        ('StylCnv_ModeRb_Type4', 'str', 4, '{StylCnv_Type4_OpenFile}: mode "rb" for {FileIO_OpenWithMode}.'),
        ('StylCnv_ModeRb_Type6', 'str', 4, '{StylCnv_Type6_AppendName}: mode "rb".'),
        ('StylCnv_ModeRb_Type6b', 'str', 4, '{StylCnv_Type6_Case1_CopyName}: mode "rb".'),
        ('StylCnv_ModeRb_Single', 'str', 4, '{StylCnv_Single_WriteTMExtension}: mode "rb".'),
        ('StylCnv_ModeRb_LSW', 'str', 4, '{StylCnv_LSW_WriteExtension}: mode "rb".'),
        ('AccStyle_SlotOrderA', 'u8', 30,
         'Byte-identical to AccBankData_SlotOrder.  The code after\n'
         '{AccStyle_TableDataEntry_Skip12} adds <this> to (a - 30) and\n'
         '{AccStyle_TableDataEntry_Skip15} loads it with lda.'),
        ('AccStyle_SlotOrderB', 'u8', 30,
         '{AccStyle_TableDataEntry_Join}: ld xiy,<this>; ldirw 15 words to\n'
         'its frame.  Rows of ten: {0..3, 12..17}, {4..7, 18..23},\n'
         '{8..11, 24..29} -- the same slots grouped the other way.'),
    ]
    new = []
    new.append(_astr('NakaInst_OFF_Str', data[off0:off0 + 4], pre=M.comment_block(wrap(
        'NakaInst_OFF_Str -- "OFF".  With "ON " just before it, the pair is '
        'pointed at by the 2-entry table at NakaInst_DashDash+4 that '
        'SndArgNmGet copies to its frame.  Everything after it up to the '
        'ApFunction table (0xE55210) was part of this label\'s .s slice and is '
        'typed below.'))))
    o = c
    lines = []
    for nm, kind, n, why in rodata:
        bs = data[o:o + n]
        pre = M.comment_block(wrap('%s (+0x%02X, ROM 0x%06X): %s'
                                   % (nm, o - off0, base + o, fmt(why))))
        if kind == 'u8':
            new.append(_barr(nm, bs, pre))
        elif kind == 'u32':
            new.append(_u32arr(nm, ['0x%08X' % int.from_bytes(bs[k:k + 4], 'little')
                                    for k in range(0, n, 4)], pre))
        else:
            new.append(_astr(nm, bs, pre))
        o += n
    assert o == T, hex(o)
    assert data[c + 0x3E:c + 0x5C] == data[c + 0x94:c + 0xB2]   # SlotOrder == SlotOrderA
    # the record table
    recs = []
    for i in range(nrec):
        pp = []
        for h in (0, 16):
            r = T + 32 * i + h
            f = data[r:r + 16]
            pp.append('{ 0x%02X, %s, %s, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X }'
                      % (f[0], ptr(u32(r + 1)), ptr(u32(r + 5)), f[9], f[10], f[11], f[12],
                         f[13], f[14], f[15]))
        recs.append('        /* %2d */ { {\n            %s,\n            %s } },' % (i, pp[0], pp[1]))
    assert all(data[T + 32 * i + h + 11] == 0x7F and data[T + 32 * i + h + 15] == 0
               for i in range(nrec) for h in (0, 16))
    tab_hdr = wrap(
        'AccompSeq_StyleDataTable (ROM 0x%06X) -- %d records x 32 bytes, each two '
        'accseq_part_t (naka_types.h, where every field is tied to the code '
        'that reads it).\n\n'
        'Reader: %s multiplies an index below 0x80 (from %s, which maps a '
        'program/bank pair through Voice_NoteChannelTable2) by 0x20 and adds '
        'this table; %s, %s and %s read the fields.  An index of 0x80 or more '
        'takes the other branch (0x1E8800 + ...), not this table.\n\n'
        'Count: the table runs from here to the first stream it points at, '
        '0x%06X: 0x%X bytes = %d records; every one of the %d non-null stream '
        'pointers lands inside the stream block that follows, and every '
        'stream starts with 80 FF FF FF FF 87.'
        % (base + T, nrec, a('AccompSeq_LookupStyle_Internal'), a('Voice_DecodeNoteChannel2'),
           a('AccompSeq_LoadParams'), a('AccompSeq_InitMidiEvents'), a('AccompSeq_CompareChord'),
           base + first_stream, first_stream - T, nrec, len(starts)))
    new.append(M.NewMember('accseq_record_t', 'AccompSeq_StyleDataTable', '[%d]' % nrec,
                           32 * nrec, '{\n' + '\n'.join(recs) + '\n    }',
                           M.comment_block(tab_hdr)))
    st_hdr = wrap(
        'AccompSeq_Stream_RR_P -- the %d event streams of AccompSeq_StyleDataTable, '
        'one per used part (RR = record, P = a for part 1, b for part 2), in '
        'record order, back to back, 0x%06X..0x%06X.  Boundaries are the stream '
        'pointers themselves; no two parts share a stream.  Every stream begins '
        'with the 6 bytes 80 FF FF FF FF 87, which AccompSeq_LoadParams skips '
        '(`add xwa, 6`).\n\n'
        'NOT ESTABLISHED: the event encoding after the header.  The player that '
        'walks the cursors at 0x7E2C/0x7E2E and 0x7E30/0x7E32 was not read for '
        'this; the streams are kept as bytes.'
        % (len(streams), base + first_stream, base + end))
    first = True
    for nm, a_, b_ in streams:
        new.append(_barr(nm, data[a_:b_], M.comment_block(st_hdr) if first else ()))
        first = False
    reexp = [mb.name for mb in cb.members if off0 <= mb.offset < end and
             M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr)]
    return off0, end, new, reexp


def build_apfunction_tables(cb, data, off0):
    """0xE55210 (blob +0x243B0): 60 procedure addresses + a 0, then 60 name
    pointers + a pointer to "" -- the two object tables InitializeEast
    registers with RegObjTabl (count 0x3C, ids 0x123 and 0x423)."""
    k = cb.by_name['ptrs_37']
    mb = cb.members[k]
    assert mb.offset == off0 and mb.dims == '[122]', (hex(mb.offset), mb.dims)
    el = cb.elements('ptrs_37')
    assert len(el) == 122 and el[60] == '0x00000000', (len(el), el[60])
    h1 = wrap(
        'MidiMenu_ApFunctionTable (ROM 0xE55210) -- 60 procedure addresses and a '
        '0 terminator.  %s registers it: RegObjTabl 0x1600002, ApFunctionProc, '
        '0x3C, 0xE55210, 0x123 (class 0x1600002, 60 objects, ids from 0x123).  '
        'The procedures are the MIDI-menu title and field functions (TtMdmenu, '
        'MdPcgModeFunc, ... RevEqOnOffFunc).' % a('InitializeEast'))
    h2 = wrap(
        'MidiMenu_ApFunctionNameTable (ROM 0xE55304) -- the 60 procedures\' names, '
        'in the same order, and a pointer to "" as terminator.  Registered by the '
        'next line of %s: RegObjTabl 0x1600002, ApFunctionProc, 0x3C, 0xE55304, '
        '0x423.  The strings themselves follow, stored in reverse order.'
        % a('InitializeEast'))
    new = [_u32arr('MidiMenu_ApFunctionTable', el[:61], M.comment_block(h1)),
           _u32arr('MidiMenu_ApFunctionNameTable', el[61:], M.comment_block(h2))]
    return off0, off0 + 488, new, ['ptrs_37']


ASEQ_LEN = {0x90: 6, 0x91: 8, 0xC0: 6, 0xD1: 3, 0xD2: 3, 0xD3: 3, 0xD4: 3,
            0xD5: 3, 0xD7: 3, 0x81: 1, 0x83: 1, 0x84: 1, 0x87: 1}
ASEQ_HDR = bytes.fromhex('80ffffffff87')


def aseq_events(bs):
    """Split an AccompSeq stream into macro calls (naka_types.h ASEQ_*).
    Refuses (SystemExit) unless the grammar consumes every byte."""
    if bs[:6] != ASEQ_HDR:
        raise SystemExit('stream without the 80 FF FF FF FF 87 header')
    out, i, ended = ['ASEQ_HEADER'], 6, False
    while i < len(bs):
        op = bs[i]
        n = ASEQ_LEN.get(op)
        if n is None or i + n > len(bs):
            raise SystemExit('stream byte 0x%02X at +%d is not in the grammar' % (op, i))
        f = bs[i + 1:i + n]
        if ended and op not in (0x81, 0x83, 0x87):
            raise SystemExit('event after the end mark at +%d' % i)
        if op == 0x90:
            out.append('ASEQ_EV6(%d, %d, %d, %d, %d)' % tuple(f))
        elif op == 0x91:
            out.append('ASEQ_EV8(%d, %d, %d, %d, %d, %d, %d)' % tuple(f))
        elif op == 0xC0:
            out.append('ASEQ_PROG(%d, %d, 0x%02X, 0x%02X, 0x%02X)' % tuple(f))
        elif op & 0xF0 == 0xD0:
            out.append('ASEQ_CTL(%d, %d, %d)' % ((op & 0xF,) + tuple(f)))
        else:
            out.append({0x81: 'ASEQ_UNIT', 0x83: 'ASEQ_END', 0x84: 'ASEQ_LOOP',
                        0x87: 'ASEQ_BLOCK_END'}[op])
            ended = ended or op == 0x83
        i += n
    return out


def render_accseq_streams(cb, data):
    """Re-express every AccompSeq_Stream_* initializer as ASEQ_* events
    (same bytes; the layout is untouched)."""
    n = 0
    for mb, e in zip(cb.members, cb.entries):
        if not mb.name.startswith('AccompSeq_Stream_'):
            continue
        ev = aseq_events(data[mb.offset:mb.offset + mb.size])
        lines, cur = [], []
        for x in ev:
            cur.append(x)
            if x in ('ASEQ_UNIT', 'ASEQ_HEADER'):     # one line per 96-tick unit
                lines.append(', '.join(cur))
                cur = []
        if cur:
            lines.append(', '.join(cur))
        e.expr = '{\n' + '\n'.join('        %s,' % l for l in lines) + '\n    }'
        n += 1
    return n


ACCSEQ_STREAM_HDR = (
    'AccompSeq_Stream_RR_P -- the {n} event streams of AccompSeq_StyleDataTable, '
    'one per used part (RR = record, P = a for part 1, b for part 2), in record '
    'order, back to back, 0x{lo:06X}..0x{hi:06X}.  Boundaries are the stream '
    'pointers themselves; no two parts share a stream.\n\n'
    'Format (the ASEQ_* macros in naka_types.h, where each opcode is tied to '
    'the code that reads it): the header 80 FF FF FF FF 87, which '
    'AccompSeq_LoadParams skips (`add xwa, 6`), then events -- 0x90 (6 B) and '
    '0x91 (8 B) timed events, 0xC0 program (6 B), 0xDn controller n (3 B), 0x81 '
    'end of a 96-tick unit -- and 0x83 end of stream, 0x87 block end.  '
    'Readers: {r1}, {r2} and {r3}.\n\n'
    'Proof of the framing: that grammar consumes every byte of all {n} streams '
    '({ev6} x 0x90, {ev8} x 0x91, {units} x 0x81, {ctl} x 0xDn, {prog} x 0xC0), '
    'each ending 83 87 (one ends 83 81 83 87, the last 83 87 87 87 87 87 87 87 up '
    'to the ApFunction table); naka_c_retype.py refuses to write a stream the '
    'grammar does not consume exactly.  What the 4/6 parameter bytes of the 0x90 '
    '/ 0x91 events mean musically is not named here: the consumers copy them to '
    'the output buffer unchanged except p1 (tested against 0x78) and p3 (0 -> 1).')


def update_accseq_stream_header(cb, data):
    import collections
    k = cb.by_name['AccompSeq_Stream_00_a']
    streams = [mb for mb in cb.members if mb.name.startswith('AccompSeq_Stream_')]
    ops = collections.Counter()
    for mb in streams:
        for ev in aseq_events(data[mb.offset:mb.offset + mb.size]):
            ops[ev.split('(')[0]] += 1
    base = cb.base()
    text = wrap(ACCSEQ_STREAM_HDR.format(
        n=len(streams), lo=base + streams[0].offset,
        hi=base + streams[-1].offset + streams[-1].size,
        r1=a('AccompSeq_ParseEvents'), r2=a('AccompSeq_InitEventDispatch'),
        r3=a('AccompSeq_ParseSequenceData'), ev6=ops['ASEQ_EV6'], ev8=ops['ASEQ_EV8'],
        units=ops['ASEQ_UNIT'], ctl=ops['ASEQ_CTL'], prog=ops['ASEQ_PROG']))
    block = M.comment_block(text)
    block[1:1] = ['     * [typed] by build_accseq_region']
    mb = cb.members[k]
    # replace the previous header block (the last comment block in `pre`)
    pre = mb.pre
    end = max(i for i, l in enumerate(pre) if l.rstrip().endswith('*/'))
    start = max(i for i in range(end + 1) if pre[i].lstrip().startswith('/*'))
    mb.pre = pre[:start] + block + pre[end + 1:]


CUSTOM = [
    # (blob, anchor label, builder)
    ('naka_widget_descriptors', 'NakaInst_OFF_Str', build_accseq_region),
]
def build_seq_rodata(cb, data, off0):
    """The sequencer constant data at +0x13618..+0x1B1E4 -- see
    naka_seq_rodata.py for the partition and its evidence."""
    import naka_seq_rodata as SR
    new, reexp = SR.new_members(cb, data, fmt)
    return SR.LO, SR.HI, new, reexp


CUSTOM_AT = [
    # (blob, blob offset, builder) -- for objects whose .s label does not
    # exist yet (it is written by naka_s_headers.py)
    ('naka_widget_descriptors', 0x243B0, build_apfunction_tables),
    ('naka_widget_descriptors', 0x13618, build_seq_rodata),
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
        for cblob, anchor_label, fn in CUSTOM:
            if cblob == blob:
                run_custom(cb, data, sl[anchor_label][0], fn)
        for cblob, off, fn in CUSTOM_AT:
            if cblob == blob:
                run_custom(cb, data, off, fn)
        if blob == 'naka_widget_descriptors':
            print('   %d AccompSeq streams rendered as ASEQ_* events'
                  % render_accseq_streams(cb, data))
            update_accseq_stream_header(cb, data)
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


def run_custom(cb, data, off, fn):
    k = cb.index_at(off)
    if cb.members[k].offset == off and cb.members[k].pre and any(
            '[typed]' in l for l in cb.members[k].pre):
        print('   %s: already typed' % fn.__name__)
        return
    start, end, new, reexp = fn(cb, data, off)
    new[0].pre_lines = new[0].pre_lines[:1] + ['     * [typed] by %s' % fn.__name__] + \
        new[0].pre_lines[1:]
    dropped, remap = cb.retype(start, end, new, data, false_pointers=reexp)
    print('   %s: +0x%05X..+0x%05X, %d members, %d symbolic initializers re-expressed, '
          'SELF remaps %d' % (fn.__name__, start, end, len(new), len(dropped), len(remap)))


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
