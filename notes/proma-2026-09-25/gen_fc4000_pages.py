#!/usr/bin/env python3
r"""Frame prom_a 0xFC4000-0xFC52F7 (4,856 B) by its readers -- which are in prom_b.

QUESTION THIS ANSWERS
    prom_a's header for this span said "Read by: STILL NOT ESTABLISHED ...
    no reader is identified in prom_a's own control-flow graph", and framed it as
    one display-list blob, a 13 x 13 name table, 12 unclassified bytes and a
    2,580-byte "172 rows x 15 bytes" bitmap.  The readers are in PROM_B, whose
    source spells its immediates in decimal (`ld xiy, 16531456` = 0x00FC4000),
    which is why a hex search never found them:

      SoundEditDigitalEffect_Paint        prom_b 0xF099F5
      SoundEditDigitalEffect_RepaintField prom_b 0xF09AA5
      sub_F09AF1 + PtrTable_F09B7B        prom_b 0xF09AF1 (the eight widgets)
      SoundEditCopy_Paint                 prom_b 0xF09B9B
      SoundEditCopy_RepaintField          prom_b 0xF09C08
      sub_F09CA9 (DispatchTable_F5B9F8[0]) prom_b 0xF09CA9, and 0xF5BF6D
      sub_F5CADD                          prom_b 0xF5CBAD
    plus, INSIDE this span, interpreter-B records whose +7 long points at the
    name/rectangle tables (op 02 = string table, entry width at +0x0B; op 03 =
    8-byte entries; FINDINGS-ui-display-list-interpreter-b.md's handler table).

    This script lists every object with its reader, asserts that each display
    list's length bytes walk EXACTLY from its start to its end, that every
    pointer in every array lands on an object or record start of this framing,
    that every name table's width is the one its record states, and that the
    objects tile 0xFC4000..0xFC52F8 -- and with --apply writes the typed source.

RUN
    make gate-wsa1        # builds the ELF srcmap.py reads
    python3 notes/proma-2026-09-25/gen_fc4000_pages.py           # check + summary
    python3 notes/proma-2026-09-25/gen_fc4000_pages.py --apply   # rewrite wsa1_prom_a.s
    make gate-wsa1 && make -C wsa1 images-check
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
PROM_B = open(os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
LO, HI = 0xFC4000, 0xFC52F8
B = srcmap.BASE
HTAB_A, HTAB_B = 0xF31D21, 0xF31DB1


def hand(tab, n):
    o = tab - 0xF00000
    return [int.from_bytes(PROM_B[o + 4 * k:o + 4 * k + 4], "little") for k in range(n)]


HA, HB = hand(HTAB_A, 36), hand(HTAB_B, 15)

# ------------------------------------------------------------------ the objects
# ("list", start, end, interp, name, reader-text, extra-entry-points)
# ("pairs"|"ptrs", start, count, name, reader-text)
# ("names", start, count, width, name, reader-text)
# ("rects", start, count, name, reader-text)
# ("widgets", start, count)
DE = "SoundEditDigitalEffect_Paint (prom_b 0xF099F5)"
DER = "SoundEditDigitalEffect_RepaintField (prom_b 0xF09AA5)"
CP = "SoundEditCopy_Paint (prom_b 0xF09B9B)"
CPR = "SoundEditCopy_RepaintField (prom_b 0xF09C08)"
PG0 = "sub_F09CA9 (prom_b 0xF09CA9, DispatchTable_F5B9F8[0])"
OBJ = [
    ("list", 0xFC4000, 0xFC40B4, "A", "DigitalEffect_Frame",
     DE + " at 0xF09A33: XIY = this, XIX = DigitalEffect_FrameEnds[type]; so a PREFIX "
     "of this list is drawn, ending at one of the four inner labels", [0xFC405A, 0xFC4078, 0xFC4096]),
    ("list", 0xFC40B4, 0xFC40F0, "A", "DigitalEffect_ValueFrames",
     DE + " at 0xF09A5F (type != 10) / 0xF09A58 (type 10: from the inner label), to 0xFC40F0",
     [0xFC40D2]),
    ("list", 0xFC40F0, 0xFC420F, "A", "DigitalEffect_Header",
     DE + " at 0xF09A0C (type != 10) / 0xF09A05 (type 10: from the inner label), to 0xFC420F; "
     "text INTENSITY, DIGITAL EFFECT, SOUND EDIT, TYPE, REVERB DEPTH", [0xFC410F]),
]
for s, e in [(0xFC420F, 0xFC4292), (0xFC4292, 0xFC4332), (0xFC4332, 0xFC4398), (0xFC4398, 0xFC4404),
             (0xFC4404, 0xFC4470), (0xFC4470, 0xFC44DC), (0xFC44DC, 0xFC4532)]:
    OBJ.append(("list", s, e, "A", "DigitalEffect_ParamLabels_%06X" % s,
                DE + " at 0xF09A2F, through DigitalEffect_ParamLabelLists[type]", []))
OBJ += [
    ("pairs", 0xFC4532, 12, "DigitalEffect_ParamLabelLists",
     DE + " at 0xF09A23: `ld A,(0x27B6) / sla 3,WA / ld XIZ,0x00FC4532 / add XIZ,XWA / "
     "ld XIY,(XIZ) / ld XIX,(XIZ+4) / call T_DisplayList_Run`"),
    ("list", 0xFC4592, 0xFC45D5, "B", "DigitalEffect_Values",
     DE + " at 0xF09A6D, to 0xFC45D5 (type != 10) or 0xFC45CA (type 10); " + DER +
     " runs the inner record 0xFC45A1..0xFC45BF alone (field 0)", [0xFC45A1, 0xFC45B0, 0xFC45BF, 0xFC45CA]),
    ("pairs", 0xFC45D5, 12, "DigitalEffect_ParamValueLists",
     DE + " at 0xF09A94: the same shape as DigitalEffect_ParamLabelLists, run by interpreter B"),
]
for s, e, p, n in [(0xFC4635, 0xFC4668, 0xFC4668, 6), (0xFC4680, 0xFC46BD, 0xFC46BD, 9),
                   (0xFC46E1, 0xFC470E, 0xFC470E, 5), (0xFC4722, 0xFC474A, 0xFC474A, 5),
                   (0xFC475E, 0xFC4788, 0xFC4788, 5), (0xFC479C, 0xFC47BF, 0xFC47BF, 4)]:
    OBJ.append(("list", s, e, "B", "DigitalEffect_ParamValues_%06X" % s,
                DE + " at 0xF09AA0, through DigitalEffect_ParamValueLists[type]", []))
    OBJ.append(("ptrs", p, n, "DigitalEffect_FieldRecords_%06X" % p,
                DER + " at 0xF09ABB (fields 1-6: `ld XIZ,0x00FC47CF / ld XIY,(XIZ+4*type)`) or 0xF09AD2 "
                "(field >= 7: 0xFC46BD), then RunDisplayListBFromPointerArray (prom_b 0xF09AE1): "
                "record [field] drawn alone"))
OBJ += [
    ("ptrs", 0xFC47CF, 12, "DigitalEffect_FieldRecordArrays",
     DER + " at 0xF09AAF: `ld XIZ,0x00FC47CF / ld C,(0x27B6) / sla 2,BC / ld XIY,(XIZ+BC)`"),
    ("ptrs", 0xFC47FF, 12, "DigitalEffect_FrameEnds",
     DE + " at 0xF09A3A: `ld XIZ,0x00FC47FF / ld C,(0x27B6) / sla 2,BC / ld XIX,(XIZ+BC)`, the END "
     "of the DigitalEffect_Frame prefix"),
    ("names", 0xFC482F, 12, 13, "DigitalEffect_TypeNames",
     "the interpreter-B op-02 record DigitalEffect_Values (0xFC4592): variable 0x27A6, mask 0x0F, "
     "+7 = this table, +0x0B entry width 13"),
    ("names", 0xFC48CB, 2, 6, "DigitalEffect_OutputNames",
     "the op-02 record at 0xFC45B0: variable 0x27A6, mask 0x40, shift 6, +7 = this table, width 6"),
    ("widgets", 0xFC48D7, 8),
    ("list", 0xFC4BA7, 0xFC4D77, "A", "SoundEditCopy_Frame", CP + " at 0xF09BA0; text COPY, SOUND EDIT, FROM, TO, TONE:, OPTION", []),
    ("list", 0xFC4D77, 0xFC4DEB, "A", "SoundEditCopy_ToneLabels", CP + " at 0xF09BBA when (0x27F5) != 1; text BANK:, 1st..4th TONE, SOUND:", []),
    ("list", 0xFC4DEB, 0xFC4E54, "A", "SoundEditCopy_DrumLabels", CP + " at 0xF09BE2 when (0x27F5) == 1; text DRUM KIT:, 1st/2nd TONE, DRUM SOUND:", []),
    ("list", 0xFC4E54, 0xFC4E8C, "B", "SoundEditCopy_ToneValues", CP + " at 0xF09BCD", []),
    ("list", 0xFC4E8C, 0xFC4EC4, "B", "SoundEditCopy_DrumValues", CP + " at 0xF09BF5", []),
    ("list", 0xFC4EC4, 0xFC4EE2, "B", "SoundEditCopy_Field5Values", CPR + " at 0xF09C36 (field 5)", []),
    ("list", 0xFC4EE2, 0xFC4EEC, "A", "SoundEditCopy_Field2Box", CPR + " at 0xF09C19 (field 2, layer 1)", []),
    ("rects", 0xFC4EEC, 5, "SoundEditCopy_ToneOptionRects",
     "the interpreter-B op-03 record at 0xFC4E81 (SoundEditCopy_ToneValues): variable 0x27A8, mask 0x0F, "
     "+7 = this table of 8-byte entries"),
    ("rects", 0xFC4F14, 3, "SoundEditCopy_DrumOptionRects",
     "the op-03 record at 0xFC4EB9 (SoundEditCopy_DrumValues): variable 0x27A8, +7 = this table"),
    ("names", 0xFC4F2C, 7, 10, "SoundEditCopy_OptionNames",
     "the op-02 records at 0xFC4E54 and 0xFC4E8C: variable 0x27A6, mask 0x0F, width 10"),
    ("names", 0xFC4F72, 4, 4, "SoundEditCopy_ToneBankNames",
     "the op-02 record at 0xFC4E72: variable 0x27A9, mask 0x0F, width 4"),
    ("names", 0xFC4F82, 3, 4, "SoundEditCopy_DrumBankNames",
     "the op-02 record at 0xFC4EAA: variable 0x27A9, mask 0x03, width 4"),
    ("names", 0xFC4F8E, 5, 3, "SoundEditCopy_ToneOrdinals",
     "the op-02 record at 0xFC4E63: variable 0x27A7, mask 0x0F, width 3"),
    ("names", 0xFC4F9D, 3, 3, "SoundEditCopy_DrumOrdinals",
     "the op-02 record at 0xFC4E9B: variable 0x27A7, mask 0x0F, width 3"),
    ("ptrs", 0xFC4FA6, 4, "SoundEditCopy_ToneFieldRecords",
     CPR + " at 0xF09C4D when (0x27F5) != 1, then RunDisplayListBFromPointerArray (prom_b 0xF09AE1)"),
    ("ptrs", 0xFC4FB6, 4, "SoundEditCopy_DrumFieldRecords",
     CPR + " at 0xF09C54 when (0x27F5) == 1, then RunDisplayListBFromPointerArray"),
]
_SEG = [0xFC4FC6 + 30 * k for k in range(12)]
for k, s in enumerate(_SEG):
    OBJ.append(("list", s, s + 30, "A", "DisplayList_%06X" % s,
                "sub_F5CADD (prom_b) at 0xF5CBAD: `ld XIX,0x00FC512E / ld XIZ,(XIX+4*(A-20)) / "
                "ld XIY,(XIZ) / ld XIX,(XIZ+4*B) / call T_DisplayList_Run`, B from (0x27D6+A-20); "
                "so a run of 1-3 consecutive 30-byte segments is drawn", []))
OBJ += [
    ("ptrs", 0xFC512E, 4, "SegmentArrays_FC512E",
     "sub_F5CADD (prom_b) at 0xF5CBAD, indexed by A-20 (see DisplayList_FC4FC6)"),
    ("ptrs", 0xFC513E, 4, "SegmentBounds_FC513E", "SegmentArrays_FC512E[0]: (XIZ) is the start, (XIZ+4*B) the end"),
    ("ptrs", 0xFC514E, 4, "SegmentBounds_FC514E", "SegmentArrays_FC512E[1]"),
    ("ptrs", 0xFC515E, 4, "SegmentBounds_FC515E", "SegmentArrays_FC512E[2]"),
    ("ptrs", 0xFC516E, 4, "SegmentBounds_FC516E", "SegmentArrays_FC512E[3]"),
    ("list", 0xFC517E, 0xFC527A, "B", "DisplayList_FC517E",
     PG0 + " at 0xF09D07 and 0xF09D69, and prom_b 0xF5BF6D, whole; its inner sub-lists "
     "0xFC51B1-0xFC51D3 (0xF09D28), 0xFC51F9-0xFC521B (0xF09D3D), 0xFC524D-0xFC526F (0xF09CD1)",
     [0xFC51B1, 0xFC51D3, 0xFC51F9, 0xFC521B, 0xFC524D, 0xFC526F]),
    ("list", 0xFC527A, 0xFC5292, "B", "DisplayRecords_FC527A",
     "DisplayRecordPtrs_FC52B4[12..14] only (two op-09 records, each drawn alone)", [0xFC5286]),
    ("rects", 0xFC5292, 3, "Rects_FC5292",
     "the interpreter-B op-03 record at 0xFC526F: variable 0x27A6, mask 0x03, +7 = this table"),
    ("list", 0xFC52AA, 0xFC52B4, "A", "DisplayList_FC52AA", PG0 + " at 0xF09CEB and 0xF09D52 (layer 1)", []),
    ("ptrs", 0xFC52B4, 17, "DisplayRecordPtrs_FC52B4",
     PG0 + " at 0xF09CFB and 0xF09D82, prom_b 0xF09E11 and 0xF09E76: XIY = this, then "
     "RunDisplayListBFromPointerArray / 0xF09AB0 with A = the field"),
]


def rd(a, n=1):
    return srcmap.load.__self__ if False else ROM[a - B:a - B + n]


ROM = open(srcmap.ROM, "rb").read()


def walk(s, e):
    recs, p = [], s
    while p < e:
        op, ln = ROM[p - B], ROM[p - B + 1]
        assert ln >= 2 and p + ln <= e, "list 0x%06X-0x%06X: record at 0x%06X overruns" % (s, e, p)
        recs.append((p, op, ln))
        p += ln
    assert p == e, "list 0x%06X-0x%06X does not walk exactly" % (s, e)
    return recs


def size(o):
    k = o[0]
    if k == "list":
        return o[2] - o[1]
    if k == "pairs":
        return 8 * o[2]
    if k == "ptrs":
        return 4 * o[2]
    if k == "names":
        return o[2] * o[3]
    if k == "rects":
        return 8 * o[2]
    if k == "widgets":
        return 90 * o[2]


def u32(a):
    return int.from_bytes(ROM[a - B:a - B + 4], "little")


def check():
    cur = LO
    starts = {}          # address -> label
    recstarts = set()
    for o in OBJ:
        assert o[1] == cur, "gap/overlap at 0x%06X (object starts 0x%06X)" % (cur, o[1])
        cur += size(o)
        if o[0] == "list":
            recs = walk(o[1], o[2])
            for p, op, ln in recs:
                recstarts.add(p)
            starts[o[1]] = o[4]
            for x in o[6]:
                assert x in {r[0] for r in recs} or x == o[2], "inner 0x%06X is not a record start" % x
        elif o[0] == "widgets":
            for k in range(o[2]):
                starts[o[1] + 90 * k] = "Widget_%06X" % (o[1] + 90 * k)
        else:
            starts[o[1]] = o[-2] if o[0] in ("names",) else o[3] if o[0] in ("pairs", "ptrs", "rects") else None
    assert cur == HI, "tiling ends at 0x%06X" % cur
    # names objects: label is index 4
    for o in OBJ:
        if o[0] == "names":
            starts[o[1]] = o[4]
    # every array target is an object start, a record start, or a list end
    ends = {o[2] for o in OBJ if o[0] == "list"}
    for o in OBJ:
        if o[0] in ("pairs", "ptrs"):
            n = o[2] * (2 if o[0] == "pairs" else 1)
            for k in range(n):
                v = u32(o[1] + 4 * k)
                assert v in starts or v in recstarts or v in ends, \
                    "%s[%d] = 0x%06X is not a boundary of this framing" % (o[3], k, v)
    # every B op-02/03 record that points into the span points at an object start, and
    # op-02's width field equals the names table's width
    widths = {o[1]: o[3] for o in OBJ if o[0] == "names"}
    for o in OBJ:
        if o[0] == "list" and o[3] == "B":
            for p, op, ln in walk(o[1], o[2]):
                if op in (2, 3) and ln >= 11:
                    v = u32(p + 7)
                    if LO <= v < HI:
                        assert v in starts, "record 0x%06X points at 0x%06X, not an object" % (p, v)
                        if op == 2:
                            w = ROM[p - B + 0x0B] | ROM[p - B + 0x0C] << 8
                            assert widths.get(v) == w, "record 0x%06X width %d != table's %s" % (
                                p, w, widths.get(v))
    return starts, recstarts


def esc(t):
    return t.replace("\\", "\\\\").replace('"', '\\"')


def emit(starts, recstarts):
    lab = dict(starts)
    for o in OBJ:
        if o[0] == "list":
            for x in o[6]:
                lab.setdefault(x, "DLRec_%06X" % x)
    # record starts that arrays point at get a label too
    for o in OBJ:
        if o[0] in ("pairs", "ptrs"):
            n = o[2] * (2 if o[0] == "pairs" else 1)
            for k in range(n):
                v = u32(o[1] + 4 * k)
                lab.setdefault(v, "DLRec_%06X" % v)

    endof = {o[2]: o[4] for o in OBJ if o[0] == "list"}
    refs = {}                      # address -> ["Array[k]", ...] for inner-record headers
    for o in OBJ:
        if o[0] in ("pairs", "ptrs"):
            n = o[2] * (2 if o[0] == "pairs" else 1)
            for k in range(n):
                v = u32(o[1] + 4 * k)
                refs.setdefault(v, []).append("%s[%d]" % (o[3], k // 2 if o[0] == "pairs" else k))
        if o[0] == "list" and o[3] == "B":
            for p, op, ln in walk(o[1], o[2]):
                if op in (2, 3) and ln >= 11 and LO <= u32(p + 7) < HI:
                    pass
    for v in list(refs):
        uniq = []
        for x in refs[v]:
            if x not in uniq:
                uniq.append(x)
        refs[v] = ["pointed at by " + ", ".join(uniq[:6]) + (" +%d more" % (len(uniq) - 6) if len(uniq) > 6 else "")]
    for o in OBJ:
        if o[0] == "list":
            for x in o[6]:
                if x not in refs:
                    refs[x] = ["an inner entry point or end named in the list's Read-by line"]

    def L(v):
        return lab[v]

    def LE(v):
        """a list END: the list's own `_End` symbol when a list ends there"""
        return endof[v] + "_End" if v in endof else lab[v]

    O = []
    O += """; ==============================================================================
; 0xFC4000-0xFC52F7 -- THE SOUND EDIT "DIGITAL EFFECT" AND "COPY" PAGES' SCREEN
; DATA: display lists, their bound/record arrays, name tables, eight widgets
; ==============================================================================
;
; ★ READ BY PROM_B.  This span's header used to record its reader as an open
; question, because prom_a's own control-flow graph reaches none of it.  Its
; readers are prom_b routines, whose source writes these addresses as
; DECIMAL immediates (`ld xiy, 16531456` is `ld XIY,0x00FC4000`) -- so no hex
; search could find them:
;   SoundEditDigitalEffect_Paint 0xF099F5, SoundEditDigitalEffect_RepaintField
;   0xF09AA5, sub_F09AF1 0xF09AF1 (via PtrTable_F09B7B), SoundEditCopy_Paint
;   0xF09B9B, SoundEditCopy_RepaintField 0xF09C08, sub_F09CA9 0xF09CA9
;   (DispatchTable_F5B9F8[0]) with prom_b 0xF5BF6D, and sub_F5CADD at 0xF5CBAD.
; The DIGITAL EFFECT type is (0x27B6) = (0x27A6) & 0x0F; every per-type array
; below is indexed by it, and 12 entries is the extent every one of them shares.
; Inside the span, interpreter-B records point at the name and rectangle
; tables (op 02: +2 variable, +4 mask, +5 shift, +7 long -> string table,
; +0x0B entry width; op 03: +7 long -> 8-byte entries -- the handler table in
; wsa1/notes/FINDINGS-ui-display-list-interpreter-b.md), and those pointers are
; `.long <label>` here, so the byte gate now checks every table's position.
; Interpreter A is DisplayList_Run (prom_b 0xF31A09, thunk T_DisplayList_Run
; 0xF417F0), B is 0xF31AF0 (T_DisplayListB_Run 0xF417F4).
;
; ⚠ CORRECTIONS to the framing this replaces (notes/gen_prom_a_fc4000_module.py):
;   * the "13 entries x 13 bytes" name table is 12 x 13 (DigitalEffect_TypeNames,
;     width 13 from its record) + 2 x 6 ("MONO  " / "STEREO", width 6 from a
;     second record) -- 168 bytes, so it ends at 0xFC48D6, the byte before
;     Widget_FC48D7, and the one-byte overlap the two framings had is gone;
;   * "Unclassified_FC48D8" was bytes 1-12 of Widget_FC48D7;
;   * "Bitmap1bpp_FC48E4, 172 rows x 15 bytes" was the other seven widgets and,
;     from 0xFC4BA7, the COPY page's display lists and tables.  Lane IMAGE had
;     already shown the widget half (images/Widget_FC48D7.png ..); the rest is
;     named here by its prom_b readers.
; ⚠ What is NOT claimed: which field or effect parameter each record draws
; beyond the text the records carry; prom_b's PtrTable_F006CD / PtrArray_F00C4E
; words that land inside DigitalEffect_Frame (0xFC4082, 0xFC4097, 0xFC4480 ...)
; are not record starts of this framing and are not explained here.
; Regenerate / re-check: notes/proma-2026-09-25/gen_fc4000_pages.py (repo root).
; ==============================================================================""".split("\n")
    for o in OBJ:
        k = o[0]
        O.append("")
        if k == "list":
            _, s, e, it, name, rdr, inner = o
            recs = walk(s, e)
            O += ["; %s -- display list, %d record(s), %d bytes, interpreter %s" % (name, len(recs), e - s, it),
                  "; Read by: " + rdr + ".",
                  "; Framing: the length bytes walk from 0x%06X and land exactly on 0x%06X." % (s, e)]
            if s == LO:
                O.append("; (was `DisplayList_FC4000`, the label of this whole span until 2026-09-25)")
            O.append("%s:" % name)
            H = HA if it == "A" else HB
            for p, op, ln in recs:
                if p != s and p in lab:
                    O.append("; %s -- a record (op %02X, %d bytes) inside %s," % (lab[p], op, ln, name))
                    O.append(";          %s" % "; ".join(refs.get(p, ["an entry point of it named in its header"])))
                    O.append("%s:" % lab[p])
                raw = ROM[p - B:p - B + ln]
                hd = H[op] if op < len(H) else None
                O.append("\t.byte 0x%02X, 0x%02X%s; %06X  op %02X, %d bytes%s" % (
                    op, ln, " " * 29, p, op, ln, ", handler 0x%06X" % hd if hd else ""))
                if it == "B" and op in (2, 3) and ln in (15, 11) and LO <= u32(p + 7) < HI:
                    O.append("\t.short 0x%04X%s; %06X  variable" % (raw[2] | raw[3] << 8, " " * 30, p + 2))
                    O.append("\t.byte 0x%02X, 0x%02X, 0x%02X%s; %06X  mask, shift, +6" % (
                        raw[4], raw[5], raw[6], " " * 21, p + 4))
                    O.append("\t.long %-38s; %06X  %s" % (L(u32(p + 7)), p + 7,
                                                           "string table" if op == 2 else "8-byte entries"))
                    if op == 2:
                        O.append("\t.short %d, 0x%04X%s; %06X  entry width, +0x0D" % (
                            raw[11] | raw[12] << 8, raw[13] | raw[14] << 8, " " * 24, p + 11))
                    continue
                i = 2
                while i < ln:
                    j = i
                    if 0x20 <= raw[i] <= 0x7E:
                        while j < ln and 0x20 <= raw[j] <= 0x7E:
                            j += 1
                        if j - i >= 2:
                            O.append('\t.ascii "%s"%s; %06X' % (esc(raw[i:j].decode("ascii")),
                                                               " " * max(1, 33 - (j - i)), p + i))
                            i = j
                            continue
                        j = i + 1
                    while j < ln and not (0x20 <= raw[j] <= 0x7E and j + 1 < ln and 0x20 <= raw[j + 1] <= 0x7E):
                        j += 1
                    O.append("\t.byte %s%s; %06X" % (", ".join("0x%02X" % c for c in raw[i:j]),
                                                     " " * max(1, 36 - 6 * (j - i)), p + i))
                    i = j
            O.append("\t.set %s_End, .%s; %06X  end marker: the byte after the last record" % (
                name, " " * max(1, 30 - len(name)), e))
        elif k in ("pairs", "ptrs"):
            _, s, n, name, rdr = o
            what = "(start, end) display-list bounds" if k == "pairs" else "pointers"
            O += ["; %s -- %d %s, %d bytes" % (name, n, what, size(o)),
                  "; Read by: " + rdr + ".",
                  "; COUNT %d is the extent to the next object of this framing; every entry lands" % n,
                  "; on a list or record boundary (gen_fc4000_pages.py checks each one)."]
            O.append("%s:" % name)
            for j in range(n):
                if k == "pairs":
                    a, b2 = u32(s + 8 * j), u32(s + 8 * j + 4)
                    O.append("\t.long %s, %s%s; %06X  [%2d]" % (L(a), LE(b2), " " * max(1, 36 - len(L(a)) - len(LE(b2))),
                                                               s + 8 * j, j))
                else:
                    v = u32(s + 4 * j)
                    isend = name == "DigitalEffect_FrameEnds" or (name.startswith("SegmentBounds_") and j > 0)
                    O.append("\t.long %-38s; %06X  [%2d]" % (LE(v) if isend else L(v), s + 4 * j, j))
        elif k == "names":
            _, s, n, w, name, rdr = o
            O += ["; %s -- %d names x %d characters, fixed width, no terminator" % (name, n, w),
                  "; Read by: " + rdr + ".",
                  "; COUNT %d is the extent to the next object (the mask bounds the index only" % n,
                  "; loosely); the width is the record's own +0x0B field, checked by the generator."]
            O.append("%s:" % name)
            for j in range(n):
                t = ROM[s + w * j - B:s + w * j + w - B].decode("ascii")
                O.append('\t.ascii "%s"%s; %06X  [%d]' % (esc(t), " " * max(1, 34 - w), s + w * j, j))
        elif k == "rects":
            _, s, n, name, rdr = o
            O += ["; %s -- %d x 8-byte entries, four LE16 each (x0, y0, x1, y1 pixel" % (name, n),
                  "; coordinates, by their values: x in 0xCD..0x123, y ascending)",
                  "; Read by: " + rdr + "; the handler indexes it with `sla 3,HL`.",
                  "; COUNT %d is the extent to the next object." % n]
            O.append("%s:" % name)
            for j in range(n):
                ws = [ROM[s + 8 * j + 2 * q - B] | ROM[s + 8 * j + 2 * q + 1 - B] << 8 for q in range(4)]
                O.append("\t.short 0x%04X, 0x%04X, 0x%04X, 0x%04X%s; %06X  [%d]" % (
                    tuple(ws) + (" " * 6, s + 8 * j, j)))
        elif k == "widgets":
            _, s, n = o
            O += ["; Widget_FC48D7 .. Widget_FC4B4D -- EIGHT 48x15 1-bpp pictograms, 90 bytes each",
                  "; Read by: sub_F09AF1 (prom_b 0xF09AF1): `ld XBC,0x00F09B7B / ld XIY,(XBC+D)` then",
                  ";   `ld A,3 / ld BC,6 / ld HL,0x0F / swi 7` -- SWI7 service 3,",
                  ";   LCD_Svc_03_BlitColumns (0xF8EDB4): 6 columns of 15 bytes, column-major.",
                  ";   PtrTable_F09B7B holds exactly these eight addresses, stride 90 = 6*15;",
                  ";   the index comes through IndexMap_F09B3B, whose largest value is 7.",
                  "; The `.byte` rows are checked against images/Widget_*.png by",
                  "; `python3 scripts/build/wsa1_bitmaps.py check` (lane IMAGE, 2026-09-02, which",
                  "; first showed this; see notes/FINDINGS-image-files.md section 4).  One row",
                  "; per 15-byte column below."]
            O += ["; Drawn, they are (lane IMAGE's reading): a flat bar, a cylinder, tapered",
                  "; wedges, a parallelogram, a spool, an arrow, a bolt."]
            for w in range(n):
                a = s + 90 * w
                O.append("; Widget_%06X -- widget %d: read through PtrTable_F09B7B[%d] (prom_b 0xF09B7B)," % (a, w, w))
                O.append(";          48x15 pixels, 6 columns x 15 bytes; images/Widget_%06X.png" % a)
                O.append("Widget_%06X:" % a)
                for c in range(6):
                    r = ROM[a + 15 * c - B:a + 15 * c + 15 - B]
                    O.append("\t.byte %s  ; %06X" % (", ".join("0x%02x" % x for x in r), a + 15 * c))
    return O


def u8(x):
    return x.encode("utf-8").decode("latin-1")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    starts, recstarts = check()
    print("tiling 0x%06X-0x%06X: OK, %d objects; every list walks exactly; every array entry "
          "and every op-02/03 table pointer lands on a boundary; op-02 widths match" % (LO, HI, len(OBJ)))
    for o in OBJ:
        print("  0x%06X %-7s %5d B  %s" % (o[1], o[0], size(o),
                                          o[4] if o[0] in ("list", "names") else
                                          ("Widget_*" if o[0] == "widgets" else o[3])))
    if not a.apply:
        return
    O = [u8(x) for x in emit(starts, recstarts)]
    m = srcmap.load()
    Ls = m.lines
    h = next(i for i, l in enumerate(Ls) if l.startswith("; 0xFC4000-0xFC52F7 -- DSP-effect / SOUND EDIT"))
    assert Ls[h - 1].startswith("; -----")
    e = next(i for i in range(h, len(Ls)) if Ls[i].startswith("; 0xFC52F8-0xFC53FF -- 264 bytes of 0x0E"))
    new = Ls[:h - 1] + O + [""] + Ls[e:]
    open(srcmap.SRC, "w", encoding="latin-1").write("\n".join(new))
    print("applied: %d lines -> %d" % (e - h + 1, len(O)))


if __name__ == "__main__":
    main()
