#!/usr/bin/env python3
r"""lane_accomp_retype.py -- re-type DATA that the tree spells as instructions
(data-as-code) in the accompaniment-engine sources, from the ROM bytes, for all
three maincpu versions at once.

QUESTION ANSWERED
-----------------
"This region is data -- a named reader copies or indexes it -- but the tree
disassembled it as instructions.  What is its byte-exact typed source?"

The tool never reads the existing directives.  It turns a LABEL RANGE into an
ADDRESS RANGE with a fresh `lane_line_map.py` map (proven inert), reads the
bytes from `original_ROMs/`, and emits the layout written in REGIONS below.
The byte gate therefore checks the LAYOUT (segment widths add up), and the
values come from the dump by construction.

Each REGIONS entry names its reader(s) by label; the evidence itself is in the
emitted header (see the entry's `header`), which is what a reader of the source
sees.  Every comment that sat inside the replaced range is carried over, in
order, below the new header.

RUN
    for v in v10 v9 v7; do python3 scripts/analysis/lane_line_map.py --image $v \
        --files sequencer/accompaniment_engine.s --json /tmp/claude-1000/lane-accomp/map_$v.json; done
    python3 scripts/converters/lane_accomp_retype.py --region Demo_StyleRhythmData \
        --mapdir /tmp/claude-1000/lane-accomp [--apply]
"""
import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASE = 0xE00000
LABEL_RE = re.compile(r'^([A-Za-z_.$][\w.$@]*):')


def comment_of(line):
    q = None
    for i, ch in enumerate(line):
        if q:
            if ch == q:
                q = None
            continue
        if ch == '"':
            q = ch
        elif ch == ";":
            return line[i:].rstrip()
    return None


def asc(chunk):
    """printable ASCII -> .ascii literal text, else None."""
    if all(0x20 <= c < 0x7f and c not in (0x22, 0x5c) for c in chunk):
        return '"%s"' % chunk.decode("ascii")
    return None


def bytes_lines(chunk, per=16, note=None):
    out = []
    for k in range(0, len(chunk), per):
        c = chunk[k:k + per]
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in c))
    return out


def shorts_lines(chunk, per=8):
    assert len(chunk) % 2 == 0
    v = [chunk[k] | chunk[k + 1] << 8 for k in range(0, len(chunk), 2)]
    return ["\t.short " + ", ".join("0x%04x" % x for x in v[k:k + per])
            for k in range(0, len(v), per)]


def zero_or_bytes(chunk, per=16):
    if chunk and not any(chunk):
        return ["\t.zero %d" % len(chunk)]
    return bytes_lines(chunk, per)


# ------------------------------------------------------------------ regions
def demo_style(blob):
    """Demo_StyleRhythmData: 0x674 bytes, layout pinned by its six copy loops."""
    assert len(blob) == 0x674, "Demo_StyleRhythmData is 0x%X bytes, layout expects 0x674" % len(blob)
    o = []
    o.append("; +0x000  0x60 B  -- AccDemo_LoadRhythm copies all 0x60 bytes to 0x94800+0x0000.")
    o += bytes_lines(blob[0x000:0x060])
    o.append("; +0x060  30 x 16 B  section names, one per accompaniment section in the")
    o.append(";                 order of AccScreen's section-name table (A/B/C variation 1-4,")
    o.append(";                 then intro/fill/ending per variation).  AccDemo_LoadVariation")
    o.append(";                 copies entry a*16 (a = 0..29) into each section record.")
    for k in range(30):
        c = blob[0x60 + 16 * k:0x70 + 16 * k]
        s = asc(c)
        o.append("\t.ascii " + s if s else bytes_lines(c)[0])
    o.append("; +0x240  0x34 B  per-section record body -- AccDemo_LoadVariation copies these")
    o.append(";                 52 bytes into every one of the 30 section records.")
    o += bytes_lines(blob[0x240:0x274], 13)
    o.append("; +0x274  5 x 32 B  chord-map records -- AccDemo_LoadVariation_DataBlock copies")
    o.append(";                 these 160 bytes to 0x94800+2976.  Each record: index byte (0..4),")
    o.append(";                 three 0xFF, twelve zero bytes, a 16-character name.")
    for k in range(5):
        c = blob[0x274 + 32 * k:0x294 + 32 * k]
        o += bytes_lines(c[0:4])
        o += zero_or_bytes(c[4:16])
        s_ = asc(c[16:32])
        o.append("\t.ascii " + s_ if s_ else bytes_lines(c[16:32])[0])
    o.append("; +0x314  32 B    eight 4-byte groups 00 00 06 00.  None of the six copy loops")
    o.append(";                 covers these bytes: reader not established.")
    o += bytes_lines(blob[0x314:0x334], 4)
    o.append("; +0x334  0x40 B  -- AccDemo_LoadFillIn copies all 64 bytes to 0x94800+0x13C0.")
    o += bytes_lines(blob[0x334:0x374])
    o.append("; +0x374  0x100 B -- Demo_LoadVariationData copies it once per section (30x),")
    o.append(";                 the first of five 0x100-byte copies per section from 0x94800+0x1400.")
    o += run_lines(blob[0x374:0x474])
    o.append("; +0x474  0x100 B -- Demo_LoadVariationData_Inner copies it 4x after each copy of")
    o.append(";                 the block above (1 + 4 = 5 x 0x100 per section).")
    o += run_lines(blob[0x474:0x574])
    o.append("; +0x574  0x100 B -- Demo_LoadVariationC_Loop copies it 0xBE (190) times to")
    o.append(";                 0x94800+0xAA00.  AccDemo_LoadVariation also reads 16 bytes of it")
    o.append(";                 at +0x57C (Demo_StyleRhythmData_0x57C) into every section record.")
    o += run_lines(blob[0x574:0x674])
    return o


def run_lines(chunk):
    """bytes, compressing runs of >= 16 identical bytes into .fill/.zero."""
    out, k = [], 0
    pend = bytearray()

    def flush():
        if pend:
            out.extend(bytes_lines(bytes(pend)))
            pend.clear()
    while k < len(chunk):
        m = k
        while m < len(chunk) and chunk[m] == chunk[k]:
            m += 1
        if m - k >= 16:
            flush()
            out.append("\t.zero %d" % (m - k) if chunk[k] == 0 else
                       "\t.fill %d, 1, 0x%02x" % (m - k, chunk[k]))
        else:
            pend.extend(chunk[k:m])
        k = m
    flush()
    return out


def layout(spec):
    """spec: list of (length, kind, comment-or-None).  kind: 'bN' (.byte, N per
    line), 'hN' (.short, N per line), 'lN' (.long, N per line), 'a' (.ascii,
    asserted printable), 'z' (.zero, asserted zero), 'r' (bytes with >=16-byte
    runs folded into .zero/.fill).  length '*' = the rest."""
    def fn(blob):
        out, off = [], 0
        for ln_, kind, note in spec:
            n = len(blob) - off if ln_ == "*" else ln_
            c = blob[off:off + n]
            assert len(c) == n, "layout runs past the region"
            if note:
                out += ["; " + x if x else ";" for x in note.split("\n")]
            if kind[0] == "b":
                out += bytes_lines(c, int(kind[1:] or 16))
            elif kind[0] == "h":
                per = int(kind[1:] or 8)
                v = [c[k] | c[k + 1] << 8 for k in range(0, n, 2)]
                out += ["\t.short " + ", ".join("0x%04x" % x for x in v[k:k + per])
                        for k in range(0, len(v), per)]
            elif kind[0] == "d":           # decimal .short
                per = int(kind[1:] or 8)
                v = [c[k] | c[k + 1] << 8 for k in range(0, n, 2)]
                out += ["\t.short " + ", ".join("%d" % x for x in v[k:k + per])
                        for k in range(0, len(v), per)]
            elif kind[0] == "u":           # decimal .byte
                per = int(kind[1:] or 16)
                out += ["\t.byte " + ", ".join("%d" % x for x in c[k:k + per])
                        for k in range(0, n, per)]
            elif kind[0] == "l":
                per = int(kind[1:] or 4)
                v = [int.from_bytes(c[k:k + 4], "little") for k in range(0, n, 4)]
                out += ["\t.long " + ", ".join("0x%08x" % x for x in v[k:k + per])
                        for k in range(0, len(v), per)]
            elif kind == "a":
                t = asc(c)
                assert t, "not printable: %r" % c
                out.append("\t.ascii " + t)
            elif kind == "z":
                assert not any(c), "not zero"
                out.append("\t.zero %d" % n)
            elif kind == "r":
                out += run_lines(c)
            else:
                raise ValueError(kind)
            off += n
        assert off == len(blob), "layout covers %d of %d bytes" % (off, len(blob))
        return out
    return fn



def drum_param_tables(blob, base_label="DrumParam_PointerTableAndData", base_addr=None):
    """+0x00 2 B; +0x02 8 x LE32 pointers into this block; then the arrays they
    point at, each emitted from its own offset.  The pointers are written as
    `.long <label> + 0xNN` so they relocate with the block."""
    assert base_addr is not None
    ptrs = [int.from_bytes(blob[2 + 4 * k:6 + 4 * k], "little") for k in range(8)]
    offs = [p - base_addr for p in ptrs]
    assert all(34 <= o < len(blob) for o in offs), [hex(o) for o in offs]
    o = []
    o += ["; +0x00  2 B, not addressed by the reader"]
    o += bytes_lines(blob[0:2])
    o += ["; +0x02  8 x LE32 -- the address of array k, k = W & 7"]
    for k, off in enumerate(offs):
        o.append("\t.long %s + 0x%x\t; array %d" % (base_label, off, k))
    starts = sorted(set(offs + [34]))
    for i, st in enumerate(starts):
        en = starts[i + 1] if i + 1 < len(starts) else len(blob)
        who = [str(k) for k, off in enumerate(offs) if off == st]
        o.append("; +0x%03x  %d B%s" % (st, en - st, (" -- array " + ", ".join(who)) if who
                                         else " -- not pointed at by the table"))
        o += run_lines(blob[st:en])
    return o


def key_value_tables(blob, ntables=2, pad=2):
    """`pad` bytes, then consecutive tables of 3-byte records {LE16 key, u8
    value}; a table ends at its first key-0xFFFF record, and every further
    key-0xFFFF record right after it is emitted with it (the tables here carry
    two)."""
    o, off = [], 0
    if pad:
        o.append("; +0x%02x  %d B between the routine's `ret` and the first table" % (0x44, pad))
        o += bytes_lines(blob[:pad])
        off = pad
    for t in range(ntables):
        start = off
        while True:
            assert off + 3 <= len(blob), "table %d has no 0xFFFF terminator" % t
            key = blob[off] | blob[off + 1] << 8
            off += 3
            if key == 0xFFFF:
                break
        while off + 3 <= len(blob) and (blob[off] | blob[off + 1] << 8) == 0xFFFF:
            off += 3
        n = (off - start) // 3
        o.append("; +0x%02x  table %d: %d records {LE16 key, u8 value} ending in key-0xFFFF records"
                 % (0x44 + start, t, n))
        for k in range(start, off, 3):
            key = blob[k] | blob[k + 1] << 8
            o.append("\t.byte 0x%02x, 0x%02x, 0x%02x\t; key 0x%04x -> %d" % (
                blob[k], blob[k + 1], blob[k + 2], key, blob[k + 2]))
    if off < len(blob):
        o.append("; %d B after the last table" % (len(blob) - off))
        o += bytes_lines(blob[off:])
    return o


REGIONS = {
    "AccStyle_InlinedBlock_ByteTable_v7": dict(
        images=("v7",), file="sequencer/accompaniment_engine.s", start="AccStyle_InlinedBlock",
        offset=0x1A0, size=96,
        fn=layout([(64, "b16", "+0x1A0  64 x u8 -- nonzero only at indices 2, 4, 8, 16, 32 (-> 1, 0x10, 8, 4, 2).\n"
                               "         No reader found: no instruction holds this address (3-byte search\n"
                               "         over the ROM), and no positional label names it."),
                   (32, "b16", "+0x1E0  32 x u8 -- AccStyle_InlinedBlock_0x1E0: one-hot index -> part code;\n"
                               "         1 -> 0x14, 2 -> 0x13, 4 -> 0x10, 8 -> 0x11, 16 -> 0x12, else 0")]),
        header=[
            "; AccStyle_InlinedBlock +0x1A0..+0x1FF -- two u8 tables; the 0x1A0 bytes above",
            "; them are the block's code, still spelled as .byte in v7 (they were one",
            "; island with these tables, which the re-framer refuses as a whole).",
            "; ** RE-TYPED 2026-09-25 (lane accomp), as in v9/v10, where the readers are",
            "; cited: AccStyle_IndexedLookup and AccVoiceState_DispatchChange read the",
            "; +0x1E0 table with the one-hot index (0x338e) & 0x1f.",
        ]),

    "AccVoice_CopyFromROM_KeyTables": dict(
        file="sequencer/accompaniment_engine.s", start="AccVoice_CopyFromROM_Skip2",
        keep=2, end="__NEXT__", fn=key_value_tables,
        header=[
            "; AccVoice_CopyFromROM_DataBlock +0x46.. -- two key/value tables searched by",
            "; the routine above (AccVoice_CopyFromROM_DataBlock):",
            ";     ld xiy, AccVoice_CopyFromROM_DataBlock_0x46  (or _0x6D, chosen by carry)",
            ";  l: ld wa,(xiy) / ld c,(xiy+2) / cp wa,0xffff / jr z,<none> / cp wa,hl /",
            ";     jr z,<found> / add iy,3 / jr l",
            "; so each record is {LE16 key, u8 value}, the key compared with HL and the",
            "; value (C) tested for zero on a match; a key of 0xFFFF ends a table.",
            "; ** RE-TYPED 2026-09-25 (lane accomp): was nop/`pop sr`/max/`push sr`",
            "; mnemonics (data-as-code).  Each table ends with two key-0xFFFF records",
            "; (the reader stops at the first); the second table then starts at +0x6D,",
            "; exactly the reader's other base.",
        ]),
    "AccStyle_InlinedBlock_ByteTable": dict(
        file="sequencer/accompaniment_engine.s", start="AccStyle_InlinedBlock_Return",
        keep=1, end="__NEXT__",
        fn=layout([(64, "b16", "+0x1A0  64 x u8 -- nonzero only at indices 2, 4, 8, 16, 32 (-> 1, 0x10, 8, 4, 2).\n"
                               "         No reader found: no instruction holds this address (3-byte search\n"
                               "         over the ROM), and no positional label names it."),
                   (32, "b16", "+0x1E0  32 x u8 -- AccStyle_InlinedBlock_0x1E0: one-hot index -> part code;\n"
                               "         1 -> 0x14, 2 -> 0x13, 4 -> 0x10, 8 -> 0x11, 16 -> 0x12, else 0")]),
        header=[
            "; AccStyle_InlinedBlock +0x1A0..+0x1FF -- two u8 tables after the routine above.",
            "; ** RE-TYPED 2026-09-25 (lane accomp): was nop/rcf/`ld (0:8),0:io`/push_a",
            "; mnemonics (data-as-code).  The +0x1E0 table is read twice:",
            ";   AccStyle_IndexedLookup (\"Routine 2\" above): l = (0x338e) & 0x1f /",
            ";       ld xwa, AccStyle_InlinedBlock_0x1E0 / ld_rrb a, xwa, hl /",
            ";       cp (0x8d3a), a",
            ";   AccVoiceState_DispatchChange: ld xwa, AccStyle_InlinedBlock_0x1E0 /",
            ";       ldb_sri E, 0x03, 0xe0, 0xec (c3 03 e0 ec 25 = ld e,(xwa+l)); E goes",
            ";       to (0x90f7) before PartCtrl_WriteProgramChange",
            "; so it maps the one-hot selector (0x338e) to the same 0x10..0x14 part codes",
            "; AccPatch_PartNumberTable produces into (0x8d3a) -- in a different order.",
            "; 32 entries: the `and l, 0x1f` of the first reader, ending at",
            "; AccVoiceReg_WritePart3.",
        ]),
    "DrumParam_PointerTableAndData": dict(
        file="sequencer/accompaniment_engine.s", start="DrumParam_PointerTableAndData",
        end="__NEXT__", needs_addr=True, fn=drum_param_tables,
        header=[
            "; DrumParam_PointerTableAndData -- eight per-parameter byte arrays and the",
            "; table of their addresses.  ** RE-TYPED 2026-09-25 (lane accomp): was",
            "; `ld xsp, 0x49db00f6` / `jrl nc, 32639` / swi ... (data-as-code) plus .fill",
            "; runs.  Read by DrumParam_Lookup:",
            ";     and w,7 / sll w,2 / ld l,w / add xhl, DrumParam_PointerTableAndData_0x2 /",
            ";     ld xhl,(xhl) / ... / add xhl,xwa (xwa = A zero-extended) / ld a,(xhl)",
            "; i.e. array W&7, element A.  Every pointer lands inside this block, so the",
            "; eight addresses below are written relative to the label and the arrays are",
            "; emitted at the offsets they point to.  Array lengths are the distances",
            "; between consecutive targets (the last runs to the block's end); the",
            "; element meaning per array is not established here.",
        ]),

    "TimeSig_DisplayStrings": dict(
        file="sequencer/accompaniment_engine.s", start="TimeSig_DisplayStrings",
        size=200, fn=layout([(9, "a", None), (1, "u1", None)] * 20),
        header=[
            "; TimeSig_DisplayStrings +0x00..+0xC7 -- 20 time-signature records of 10 bytes:",
            "; a 9-character display name \"(n/d)+0 \" and one byte that is the bar length in",
            "; quarter notes (2/2 -> 4, 3/4 -> 3, 6/8 -> 3, 14/8 -> 7, 16/8 -> 8 ...).",
            "; ** RE-TYPED 2026-09-25 (lane accomp): the names were .ascii already but the",
            "; length bytes and \"(4/2)\" \"(8/4)\" \"(8/8)\" \"(16/8)\" names were spelled as",
            "; push sr / max / reti / `pushw wa`.. (data-as-code).  The 10-byte stride and",
            "; the 20-record count are read off the bytes: 20 records end exactly where",
            "; the code at +0xC8 (call ...) begins.  READER NOT ESTABLISHED for this",
            "; stride: the only direct readers found (`ld xbc, TimeSig_DisplayStrings /",
            "; add xbc,7` after `sll hl,3`, in the code that follows DrumVoice_Handler7)",
            "; index it with stride 8 at +7, which does not fit 10-byte records; the",
            "; positional labels TimeSig_DisplayStrings_0x21B.. point far past this table",
            "; into the code and data that follow.",
        ]),

    "MultiVoice_Setup_Done": dict(
        file="sequencer/accompaniment_engine.s", start="MultiVoice_Setup_Done",
        end="DrumParam_ReadVoiceCount",
        fn=layout([(33, "b11", None)]),
        header=[
            "; MultiVoice_Setup_Done -- NOT a code label: a 33-entry u8 table that turns a",
            "; one-hot bit into its position.  ** RE-TYPED 2026-09-25 (lane accomp): was",
            "; nop/normal/`push sr`/max/halt mnemonics (data-as-code).  Read by",
            "; Rhythm_MapChannelToDrumIndex:",
            ";     ld c,(0x37c9) / srl c,1 / add xbc, MultiVoice_Setup_Done / ld c,(xbc) /",
            ";     cp c,6 / jr le,... / ld c,0",
            "; so the index is (0x37c9) >> 1.  Only indices 1, 2, 4, 8, 16 and 32 are",
            "; non-zero and they hold 1..6 (bit position + 1); every other byte is 0.",
            "; 33 entries (0..32): the table ends where DrumParam_ReadVoiceCount begins.",
        ]),

    "__pad_F62002": dict(
        file="sequencer/accompaniment_engine.s", start="__pad_F62002",
        end="AccPlayback_ProcessOngoingEvents",
        fn=layout([(2, "b16", "+0x00  2 B, not addressed by either reader"),
                   (12, "b12", "+0x02  12 x u8, flag byte per index (bit 0 tested)"),
                   (36, "b3", "+0x0E  12 x 3-byte records {(0x3431), (0x3432), (0x3433)}")]),
        header=[
            "; __pad_F62002 -- NOT padding; the name is historical (it is also the base of",
            "; the __pad_F62002_0x* symbols in shared/positional_labels.s, so it is kept).",
            "; ** RE-TYPED 2026-09-25 (lane accomp): was nop/normal/scf mnemonics",
            "; (data-as-code).  The same two tables as AccPatch_TransposeNoteTable, read",
            "; by the playback path instead of the patch path:",
            ";   AccPlayback_TrackPosition: ld xix, __pad_F62002_0x2 / ldb_sri a,(xix+wa)",
            ";       with A = a byte of Display_FontPalette_Table_0x12EA; bit 0 set ->",
            ";       the note index is incremented.",
            ";   ToneGen_LoadRhythmPatternParams: c = a, then sla a,1 / add c,a (3a) /",
            ";       ld xix, __pad_F62002_0xE / add xix,xbc; (xix), (xix+1), (xix+2) are",
            ";       stored to (0x3431), (0x3432), (0x3433).",
            "; Sizes as in AccPatch_TransposeNoteTable: 12 flag bytes between the two",
            "; reader offsets, then 12 three-byte records ending at",
            "; AccPlayback_ProcessOngoingEvents.",
        ]),
    "__pad_F62230": dict(
        file="sequencer/accompaniment_engine.s", start="__pad_F62230",
        end="ToneGen_SearchVoiceBuffer",
        fn=layout([(2, "b16", "+0x00  2 B, not addressed by the reader"),
                   (68, "l4", "+0x02  17 x LE32 -> (0x3548)"),
                   (68, "l4", "+0x46  17 x LE32 -> (0x354c)")]),
        header=[
            "; __pad_F62230 -- NOT padding; the name is historical (base of the",
            "; __pad_F62230_0x* symbols in shared/positional_labels.s, so it is kept).",
            "; ** RE-TYPED 2026-09-25 (lane accomp): was `.byte 0x9d` / `ldw de,0` / nop",
            "; runs (data-as-code).  Two parallel 17-entry tables of RAM pointers, indexed",
            "; by the one-hot selector (0x379b) & 0x1F -- the playback-side twin of",
            "; AccPatch_AdvPlayPos_DataBlock.  Read by ToneGen_InitPlaybackState:",
            ";     ld a,(0x379b) / and a,0x1f (0 becomes 0x10) / sla a,2 / ld l,a /",
            ";     ld xix, __pad_F62230_0x2 / ld_sril3 xix,(xix+hl) / ld (0x3548),xix",
            ";     ld xix, __pad_F62230_0x46 / ld_sril3 xix,(xix+hl) / ld (0x354c),xix",
            "; and the two pointers are then dereferenced as words into (0x3441) and",
            "; (0x3534).  Only the one-hot entries 1, 2, 4, 8 and 16 are non-zero, and they",
            "; are the same ten pointers as AccPatch_AdvPlayPos_DataBlock's (checked on the",
            "; v10 bytes).",
            "; 17 entries each: 0x46 - 0x02 = 68 = 17*4, and 17*4 more bytes end exactly",
            "; at ToneGen_SearchVoiceBuffer.",
        ]),
    "AccStyle_ParamOffsetTables": dict(
        file="sequencer/accompaniment_engine.s", start="AccStyle_ReadParamOffset_Return",
        keep=1, end="AccVoice_ComputeParamAddr",
        fn=layout([(80, "h10", "+0x5C  40 x LE16: 0..19, then 0x400..0x413"),
                   (16, "h8", "+0xAC  8 x LE16: 0, 2, 4 ... 14"),
                   (16, "h8", "+0xBC  8 x LE16: 0x400, 0x402 ... 0x40E")]),
        header=[
            "; AccStyle_ByteDataBlock +0x5C..+0xCB -- three tables of LE16 byte offsets into",
            "; a style record (the offsets below are relative to AccStyle_ByteDataBlock,",
            "; whose first 0x5C bytes are the routine above).",
            "; ** RE-TYPED 2026-09-25 (lane accomp): was nop/max/normal/`retd 4096`...",
            "; mnemonics (data-as-code).  Readers:",
            ";   AccStyle_ReadParamOffset: ld xhl, AccStyle_ByteDataBlock_0x5C / sla w,1 /",
            ";       ldw_sri hl,(xhl+w) / extz xhl / add xhl,xiy -- entry W, a 16-bit",
            ";       offset added to the style pointer XIY (the routine at",
            ";       AccStyle_ByteDataBlock does the same with A).",
            ";   AccPart_LookupBoundVoiceParam: xhl = AccStyle_ByteDataBlock_0xAC when",
            ";       A < 0x14, else AccStyle_ByteDataBlock_0xBC; sla w,1 / ldw_sri hl,(xhl+w).",
            "; The +0x5C table holds 0..19 and then 0x400..0x413 (a second bank 1 KB",
            "; further on); +0xAC and +0xBC are the same two banks at stride 2.  Sizes:",
            "; the reader offsets pin +0x5C at 40 entries and +0xAC at 8; +0xBC is the 16",
            "; bytes up to AccVoice_ComputeParamAddr.",
        ]),

    "AccStyle_ParamOffsetTables_v7": dict(
        file="sequencer/accompaniment_engine.s", start="AccStyle_ReadParamOff_Part16_Code_Return",
        keep=1, end="AccVoice_ComputeParamAddr",
        fn=layout([(80, "h10", "+0x5C  40 x LE16: 0..19, then 0x400..0x413"),
                   (16, "h8", "+0xAC  8 x LE16: 0, 2, 4 ... 14"),
                   (16, "h8", "+0xBC  8 x LE16: 0x400, 0x402 ... 0x40E")]),
        header=[
            "; (v7: the routine's final `ret` carries the label AccStyle_ReadParamOff_Part16_Code_Return.)",
            "; AccStyle_ByteDataBlock +0x5C..+0xCB -- three tables of LE16 byte offsets into",
            "; a style record (the offsets below are relative to AccStyle_ByteDataBlock,",
            "; whose first 0x5C bytes are the routine above).",
            "; ** RE-TYPED 2026-09-25 (lane accomp): was nop/max/normal/`retd 4096`...",
            "; mnemonics (data-as-code).  Readers:",
            ";   AccStyle_ReadParamOffset: ld xhl, AccStyle_ByteDataBlock_0x5C / sla w,1 /",
            ";       ldw_sri hl,(xhl+w) / extz xhl / add xhl,xiy -- entry W, a 16-bit",
            ";       offset added to the style pointer XIY (the routine at",
            ";       AccStyle_ByteDataBlock does the same with A).",
            ";   AccPart_LookupBoundVoiceParam: xhl = AccStyle_ByteDataBlock_0xAC when",
            ";       A < 0x14, else AccStyle_ByteDataBlock_0xBC; sla w,1 / ldw_sri hl,(xhl+w).",
            "; The +0x5C table holds 0..19 and then 0x400..0x413 (a second bank 1 KB",
            "; further on); +0xAC and +0xBC are the same two banks at stride 2.  Sizes:",
            "; the reader offsets pin +0x5C at 40 entries and +0xAC at 8; +0xBC is the 16",
            "; bytes up to AccVoice_ComputeParamAddr.",
        ]),

    "AccTuning_ValueTable": dict(
        file="sequencer/accompaniment_engine.s", start="AccTuning_ValueTable",
        end="AccVoice_ProcessAllSixParts",
        fn=layout([(40, "u10", None)]),
        header=[
            "; AccTuning_ValueTable -- 40 x u8, value = 5 * (index / 5): five 0s, five 5s, ...",
            "; five 35s.  ** RE-TYPED 2026-09-25 (lane accomp): was nop/halt/`ldw (10:8)`...",
            "; mnemonics (data-as-code).  Read by AccTuning_FetchValue:",
            ";     ld xhl, AccTuning_ValueTable / ld_rr8b a, xhl, a (= ld a,(xhl+a)) / ret",
            "; i.e. entry A, returned in A.  Callers: AccTuning_SetAllFromLookup (stores it",
            "; to the six bytes 0x32a3..0x32a8) and two more `call AccTuning_FetchValue`.",
            "; 40 entries: the table ends where AccVoice_ProcessAllSixParts begins (its",
            "; first byte, 0x1E, is a `calr`), and the step-of-5 pattern is complete at 40.",
        ]),
    "AccTiming_SlotOffsetTables": dict(
        file="sequencer/accompaniment_engine.s", start="AccTiming_SlotOffsetTables",
        end="AccDir_Entry",
        fn=layout([(32, "l4", "+0x00  8 x LE32 = 0, 6, 12 ... 42 (stride 6) -- keyboard-timing slots"),
                   (32, "l4", "+0x20  8 x LE32 = 0, 9, 18 ... 63 (stride 9) -- accompaniment-timing slots")]),
        header=[
            "; AccTiming_SlotOffsetTables -- two tables of 8 x LE32 slot offsets.",
            "; ** RE-TYPED 2026-09-25 (lane accomp): was nop/`ei 0`/incf/`calr 0`/`jp 0`",
            "; mnemonics plus a 16-byte .byte tail (data-as-code).  Readers:",
            ";   AccKbdTiming_SlotOverflow:  xor xwa,xwa / ld a,(0x3384) / sla xwa,2 /",
            ";       add xwa, AccTiming_SlotOffsetTables / ld iz,(xwa)",
            ";   AccAccTiming_SlotOverflow:  the same, from AccTiming_SlotOffsetTables_0x20",
            "; so entry (0x3384) (stride 4, low 16 bits used) becomes IZ, the byte offset",
            "; of a note slot that the code then reads and writes through the SRI (xix+iz)",
            "; forms.  The first table steps by 6 and the second by 9 -- consistent with",
            "; the per-slot stride the two free-slot scans add (`add iz, (0x337c:16)`).",
            "; Size: the +0x20 reader pins the first table at 8 entries; the second is",
            "; the 32 bytes up to AccDir_Entry.",
        ]),
    "AccPatch_PartNumberTable": dict(
        file="sequencer/accompaniment_engine.s", start="AccPatch_PartNumberTable",
        end="AccPatch_UpdateAllChains",
        fn=layout([(32, "b16", None)]),
        header=[
            "; AccPatch_PartNumberTable -- 32 x u8, indexed by the one-hot selector",
            "; (0x379b) & 0x1F.  ** RE-TYPED 2026-09-25 (lane accomp): was",
            "; nop/rcf/scf/ccf/zcf/push_a mnemonics (data-as-code).  Read by",
            "; AccPatch_PartChanges_MapLookup:",
            ";     ld a,(0x379b) / and a,0x1f / ld l,a / add xhl, <this> / ld a,(xhl) /",
            ";     ld (0x8d3a),a",
            "; Only the five one-hot indices are non-zero: 1->0x10, 2->0x11, 4->0x12,",
            "; 8->0x13, 16->0x14, i.e. it turns the selected bit into 0x10+bit.  32",
            "; entries: pinned by `and a, 0x1f`, and the table ends exactly where",
            "; AccPatch_UpdateAllChains begins.",
        ]),
    "AccPatch_TransposeNoteTable": dict(
        file="sequencer/accompaniment_engine.s", start="AccPatch_TransposeNoteTable",
        end="AccPatch_ReadTransposeAmount",
        fn=layout([(2, "b16", "+0x00  2 B, not addressed by either reader"),
                   (12, "b12", "+0x02  12 x u8, flag byte per index (bit 0 tested)"),
                   (36, "b3", "+0x0E  12 x 3-byte records {(0x3431), (0x36f0), (0x36f1)}")]),
        header=[
            "; AccPatch_TransposeNoteTable -- two small tables read by the transpose path.",
            "; ** RE-TYPED 2026-09-25 (lane accomp): was nop/normal/scf mnemonics plus",
            "; .zero/.byte fragments (data-as-code).  Readers:",
            ";   AccPatch_Transpose_LookupTable: A = byte (0x36ec) of",
            ";       Display_FontPalette_Table_0x12EA, then ld l,a / add xhl,",
            ";       AccPatch_TransposeNoteTable_0x2 / ld l,(xhl) / bit 0,l -- when set, A",
            ";       and (0x36ec) are incremented by one.",
            ";   AccPatch_StoreDrumParams: ld l,a / sll a,1 / add l,a (l = 3a) / add xhl,",
            ";       AccPatch_TransposeNoteTable_0xE, then (xhl), (xhl+1), (xhl+2) are",
            ";       stored to (0x3431), (0x36f0), (0x36f1); bit 0 of (0x3431) then selects",
            ";       `ld (0x36ea), 145`.",
            "; Sizes: the +0x0E records are 3 bytes (the `3a` index) and 12 of them end",
            "; exactly at AccPatch_ReadTransposeAmount; the flag table is the 12 bytes",
            "; between the two reader offsets.  Only index 3 of the flag table and",
            "; records 3, 4 and 11 are non-zero.",
        ]),
    "AccPatch_AdvPlayPos_DataBlock": dict(
        file="sequencer/accompaniment_engine.s", start="AccPatch_AdvPlayPos_DataBlock",
        end="AccPatch_AdvanceAllSteps",
        fn=layout([(7, "b16", "+0x00  7 zero bytes, not addressed by the reader"),
                   (68, "l4", "+0x07  17 x LE32 -> XIY (RAM addresses)"),
                   (68, "l4", "+0x4B  17 x LE32 -> XIX (RAM addresses)")]),
        header=[
            "; AccPatch_AdvPlayPos_DataBlock -- two parallel 17-entry tables of RAM",
            "; pointers, indexed by the one-hot selector (0x379b).",
            "; ** RE-TYPED 2026-09-25 (lane accomp): was `.byte 0x9d` / `ldw de, 0` / nop",
            "; runs (data-as-code).  Read by AccPatch_LoadTablePointers:",
            ";     ld c,(0x379b) / sll bc,2 / add xbc, AccPatch_AdvPlayPos_DataBlock_0x4B /",
            ";     ld xix,(xbc) ... ld xiy, AccPatch_AdvPlayPos_DataBlock_0x7 / add xiy,xbc /",
            ";     ld xiy,(xiy)",
            "; so entry (0x379b) of each table is a 32-bit pointer.  Only the one-hot",
            "; entries 1, 2, 4, 8 and 16 are non-zero (v9/v10: +0x07 gives 0x329D, 0x329F,",
            "; 0x32A1, 0x329B, 0x3297 and +0x4B gives 0x328D, 0x328F, 0x3291, 0x328B,",
            "; 0x3287) -- word variables two bytes apart, which AccPatch_AdjustTableEntryPos and its",
            "; siblings then read and update through (xix)/(xiy).  17 entries each: the",
            "; +0x4B reader offset minus +0x07 is 68 = 17*4, and 17*4 more bytes end",
            "; exactly at AccPatch_AdvanceAllSteps.",
        ]),

    "Demo_StyleRhythmData": dict(
        file="sequencer/accompaniment_engine.s", start="Demo_StyleRhythmData",
        end="AccTone_LookupByProgram", fn=demo_style,
        header=[
            "; Demo_StyleRhythmData -- the built-in DEMO/DEFAULT STYLE image, 0x674 (1,652) bytes.",
            "; ** RE-TYPED 2026-09-25 (lane accomp): was disassembled as instructions",
            "; (popw/nop/pop xde/push sr/swi 7/`jr f,0`/cpd ... -- 69 data-as-code markers in",
            "; v10 alone).  It is DATA: nothing branches into it, and six copy loops read it",
            "; with fixed offsets and lengths, which pin every segment below:",
            ";   AccDemo_LoadRhythm           +0x000, 0x60 B      -> 0x94800+0x0000",
            ";   AccDemo_LoadVariation        +0x060 + a*16, 16 B -> section record a (a=0..29)",
            ";                                +0x240, 0x34 B      -> every section record",
            ";                                +0x57C, 16 B        -> every section record",
            ";   AccDemo_LoadVariation_DataBlock +0x274, 160 B    -> 0x94800+2976",
            ";   AccDemo_LoadFillIn           +0x334, 0x40 B      -> 0x94800+0x13C0",
            ";   Demo_LoadVariationData       +0x374, 0x100 B x30 and +0x474, 0x100 B x4 x30",
            ";                                                    -> 0x94800+0x1400..",
            ";   Demo_LoadVariationC_Data     +0x574, 0x100 B x190 -> 0x94800+0xAA00",
            "; 0x94800 is also the base AccPatch_InitSlotChain_WithAddr stores to (0x39ae), so",
            "; this is the style image the AccDemo_* loaders build in that RAM area.  The",
            "; interior offsets are the Demo_StyleRhythmData_0x* symbols in",
            "; shared/positional_labels.s.",
            "; 30 section names: AccDemo_LoadVariation's loop bound is `cp a, 0x1e`, and the",
            "; order (A/B/C variation 1-4, then intro/fill-in/ending 1-2 per variation) is the",
            "; order of the 30 seven-byte section-name cells in AccScreen_UIDataBlock.",
        ]),
}


READERS = {'Demo_StyleRhythmData': ['AccDemo_LoadRhythm', 'AccDemo_LoadVariation', 'AccDemo_LoadVariation_DataBlock', 'AccDemo_LoadFillIn', 'Demo_LoadVariationData', 'Demo_LoadVariationC_Data'], '__pad_F62230': ['ToneGen_InitPlaybackState'], 'AccPatch_AdvPlayPos_DataBlock': ['AccPatch_LoadTablePointers'], 'AccStyle_ParamOffsetTables': ['AccStyle_ReadParamOffset', 'AccPart_LookupBoundVoiceParam'], 'AccStyle_ParamOffsetTables_v7': ['AccStyle_ReadParamOffset', 'AccPart_LookupBoundVoiceParam'], 'AccTiming_SlotOffsetTables': ['AccKbdTiming_SlotOverflow', 'AccAccTiming_SlotOverflow'], '__pad_F62002': ['AccPlayback_TrackPosition', 'ToneGen_LoadRhythmPatternParams'], 'AccPatch_TransposeNoteTable': ['AccPatch_Transpose_LookupTable', 'AccPatch_StoreDrumParams'], 'AccTuning_ValueTable': ['AccTuning_FetchValue'], 'MultiVoice_Setup_Done': ['Rhythm_MapChannelToDrumIndex'], 'AccPatch_PartNumberTable': ['AccPatch_PartChanges_MapLookup'], 'DrumParam_PointerTableAndData': ['DrumParam_Lookup'], 'AccVoice_CopyFromROM_KeyTables': ['AccVoice_CopyFromROM_DataBlock'], 'AccStyle_InlinedBlock_ByteTable': ['AccVoiceState_DispatchChange']}


def readers_line(name, image, mapdir):
    """'; readers in this image (address from the linked ELF): X 0x..., ...'"""
    names = READERS.get(name)
    if not names:
        return None
    syms = json.load(open(os.path.join(mapdir, "map_%s.json" % image)))["symbols"]
    parts = ["%s 0x%06X" % (n, syms[n]) for n in names if n in syms]
    if not parts:
        return None
    # v9 and v10 link this file at the same addresses (checked: every reader
    # address below was identical in both), so they share one wording
    tag = "v9/v10" if image in ("v9", "v10") else image
    out, cur = [], "; readers in %s (address from the linked ELF):" % tag
    for p_ in parts:
        if len(cur) + len(p_) + 2 > 88:
            out.append(cur)
            cur = ";    "
        cur += " " + p_ + ","
    out.append(cur.rstrip(","))
    return out


def load_map(mapdir, image, rel):
    mp = json.load(open(os.path.join(mapdir, "map_%s.json" % image)))
    assert mp["image"] == image
    return mp["files"][rel]


def plan(image, spec, mapdir):
    rel = spec["file"]
    rows = load_map(mapdir, image, rel)
    path = os.path.join(ROOT, image, "maincpu", rel)
    L = open(path, encoding="latin-1").read().split("\n")
    for ln, addr, size, text in rows:
        if L[ln - 1] != text:
            sys.exit("STALE MAP for %s:%d" % (image, ln))
    lab = {}
    for ln, addr, size, text in rows:
        m = LABEL_RE.match(text.strip())
        if m:
            lab[m.group(1)] = (ln, addr)
    s_ln, s_ad = lab[spec["start"]]
    # the region's own label is normally alone on its line; when the label
    # shares its line with the first directive, that line is replaced too and
    # the label is re-emitted on a line of its own
    own_line = L[s_ln - 1].strip() == spec["start"] + ":"
    if spec.get("offset"):
        # region starts `offset` bytes into the labelled object, at a line start
        s_ad += spec["offset"]
        cand = [ln for ln, a, sz, t in rows if ln > s_ln and a == s_ad and sz]
        if not cand:
            raise KeyError("no line starts at 0x%06X" % s_ad)
        s_ln = cand[0] - 1
        own_line = True
    if spec.get("end") == "__NEXT__":
        nxt = sorted((ln, a) for (ln, a) in lab.values() if ln > s_ln)
        e_ln, e_ad = nxt[0]
    elif "end" in spec:
        e_ln, e_ad = lab[spec["end"]]
    else:
        e_ad = s_ad + spec["size"]
        cand = [ln for ln, a, sz, t in rows if ln > s_ln and a == e_ad]
        if not cand:
            raise KeyError("no line starts at 0x%06X" % e_ad)
        e_ln = cand[0]
    # optionally keep the first `keep` emitting lines after the label (e.g. a
    # routine's final `ret` that carries the label) and start after them
    keep = spec.get("keep", 0)
    if keep:
        emit = [(ln, a, sz) for ln, a, sz, t in rows if s_ln < ln < e_ln and sz]
        s_ln, s_ad = emit[keep - 1][0], emit[keep][1]
    # no label strictly inside the range (they would be lost / moved)
    inner = [(ln, t) for ln, a, sz, t in rows if s_ln < ln < e_ln and LABEL_RE.match(t.strip())]
    # preceding blank lines before the end label stay; replace s_ln+1 .. last emitting line
    last = max(ln for ln, a, sz, t in rows if s_ln < ln < e_ln)
    if not own_line and not keep:
        s_ln -= 1          # replace the label line itself as well
    rom = open(os.path.join(ROOT, "original_ROMs", "kn5000_%s_program.rom" % image), "rb").read()
    blob = rom[s_ad - BASE:e_ad - BASE]
    comments = [comment_of(L[i - 1]) for i in range(s_ln + 1, last + 1)]
    comments = [c for c in comments if c]
    body = spec["fn"](blob, base_addr=s_ad) if spec.get("needs_addr") else spec["fn"](blob)
    return dict(path=path, L=L, s_ln=s_ln, last=last, inner=inner, blob=blob,
                comments=comments, body=body, s_ad=s_ad, e_ad=e_ad,
                relabel=(spec["start"] + ":") if (not own_line and not keep) else None)


def emitted_size(lines):
    """byte count of the emitted lines (for the self-check)."""
    n = 0
    for t in lines:
        c = t.split(";")[0].strip() if not t.lstrip().startswith(".ascii") else t.strip()
        if c.startswith(".byte"):
            n += len(c[5:].split(","))
        elif c.startswith(".short"):
            n += 2 * len(c[6:].split(","))
        elif c.startswith(".long"):
            n += 4 * len(c[5:].split(","))
        elif c.startswith(".zero"):
            n += int(c.split()[1])
        elif c.startswith(".fill"):
            n += int(c.split()[1].rstrip(","))
        elif c.startswith(".ascii"):
            s = c[c.index('"') + 1:c.rindex('"')]
            n += len(s)
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--region", required=True, help="comma-separated REGIONS keys, or 'all'")
    ap.add_argument("--images", default="v10,v9,v7")
    ap.add_argument("--mapdir", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--annotate", action="store_true",
                    help="add the reader-address line to regions typed earlier")
    a = ap.parse_args()
    names = list(REGIONS) if a.region == "all" else a.region.split(",")
    if a.annotate:
        for image in a.images.split(","):
            for name in names:
                spec = REGIONS[name]
                if image not in spec.get("images", (image,)):
                    continue
                path = os.path.join(ROOT, image, "maincpu", spec["file"])
                L = open(path, encoding="latin-1").read().split("\n")
                h0 = spec["header"][0]
                idx = [i for i, x in enumerate(L) if x == h0]
                if len(idx) != 1:
                    print("%s %s: header not found once (%d), skipped" % (image, name, len(idx)))
                    continue
                i = idx[0]
                j = i + len(spec["header"])
                if L[i:j] != spec["header"]:
                    print("%s %s: header text differs, skipped" % (image, name))
                    continue
                if j < len(L) and L[j].startswith("; readers in "):
                    continue
                rl = readers_line(name, image, a.mapdir)
                if not rl:
                    continue
                L[j:j] = rl
                tmp = path + ".tmp"
                open(tmp, "w", encoding="latin-1").write("\n".join(L))
                os.replace(tmp, path)
                print("%s %s: +%d reader line(s)" % (image, name, len(rl)))
        return
    for image in a.images.split(","):
        plans = []
        for name in names:
            spec = REGIONS[name]
            if image not in spec.get("images", (image,)):
                continue
            try:
                p = plan(image, spec, a.mapdir)
            except KeyError as e:
                print("%s: %s -- label %s not in this image, skipped" % (image, name, e))
                continue
            if p["inner"]:
                sys.exit("%s: %s: labels inside the range: %s" % (image, name, p["inner"]))
            n = emitted_size(p["body"])
            if n != len(p["blob"]):
                sys.exit("%s: %s: layout emits %d B, region is %d B" % (image, name, n, len(p["blob"])))
            print("%s: %s 0x%06X..0x%06X (%d B), lines %d-%d -> %d lines, %d comments carried" % (
                image, name, p["s_ad"], p["e_ad"], len(p["blob"]), p["s_ln"] + 1, p["last"],
                len(p["body"]), len(p["comments"])))
            plans.append((name, spec, p))
        if not a.apply or not plans:
            continue
        by_file = {}
        for name, spec, p in plans:
            by_file.setdefault(p["path"], []).append((name, spec, p))
        for path, items in by_file.items():
            L = open(path, encoding="latin-1").read().split("\n")
            for name, spec, p in sorted(items, key=lambda x: -x[2]["s_ln"]):
                new = ([p["relabel"]] if p["relabel"] else []) + list(spec["header"])
                rl = readers_line(name, image, a.mapdir)
                if rl:
                    new += rl
                if image == "v7":
                    new.append("; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10")
                    new.append("; ones; v7's RAM layout differs -- read them off the reader named above.)")
                if p["comments"]:
                    new.append("; -- comments that sat inside this range before the re-type, in order:")
                    new += ["\t" + c for c in p["comments"]]
                new += p["body"]
                L[p["s_ln"]:p["last"]] = new
            tmp = path + ".tmp"
            open(tmp, "w", encoding="latin-1").write("\n".join(L))
            os.replace(tmp, path)
            print("%s: wrote %d regions to %s" % (image, len(items), path))


if __name__ == "__main__":
    main()
