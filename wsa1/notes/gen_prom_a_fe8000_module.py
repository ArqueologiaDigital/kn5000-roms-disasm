#!/usr/bin/env python3
"""Emit prom_a 0xFE8000-0xFEB32F -- the CPU-1 SCREEN/DISPATCH module -- as assembly.

QUESTION IT ANSWERS
  "0xFE8000-0xFEB32F is the last .incbin of prom_a's 0xFE0000 half.  Where does
   its code stop and its data start, and what does the source text look like?"

  It is a UI module built the same way as the 0xFEF746 screen module: routines
  that load a DISPLAY LIST and a data table into XIY/XIX and call the
  interpreter veneer, plus six POINTER-DISPATCH tables read with one idiom.

★ THE FRAMING TEST, and it is the whole reason this file is not guesswork
  A display-list record is `+0 opcode, +1 LENGTH OF THE WHOLE RECORD` and the
  interpreter advances by that length byte (notes/FINDINGS-ui-display-list.md).
  Every list in this module is named by BOTH ENDS, in `ld XIY,<start>` and
  `ld XIX,<end>` immediates the assembler cannot lie about, so walking the
  length bytes from <start> must land EXACTLY on <end>.  It does, for **35 of
  35** spans.  This script REFUSES to emit anything if one fails.

★ THE SECOND TEST: with those 35 lists and the 8 tables below removed, a linear
  disassembly of everything left produces no address that has to be abandoned:
  every byte gets an instruction, and the 22 rows llvm-mc cannot spell keep
  unidasm's own text in a trailing comment (they are all the memory-operand
  `sub (nn),#imm` / `or (nn),#imm16` forms the prelude has no macro for).
  Both counts are printed by --check, which refuses if the walk count changes.

THE 8 TABLES, and why each is a table
  Six are POINTER DISPATCH tables, every one named by a single `ld XIX,imm32`
  and read with the identical five-instruction idiom
      ld XIX,<base> / <index> << 2 / add XIX,XWA / ld XIX,(XIX) / call (XIX)
  so the entry width 4 is the READER's, not a guess:
    0xFE8077  32 x u32  reader 0xFE8060, index HL, BOUNDED `cp HL,0x1F`
    0xFE857C  32 x u32  reader 0xFE8565, index HL, BOUNDED `cp HL,0x1F`
    0xFE8D6B  12 x u32  reader 0xFE8D48, index (0x601F53), NO bound -- extent
    0xFE9311   7 x u32  reader 0xFE92FB, index (0x601F59), NO bound -- extent
    0xFE9A4A  32 x u32  reader 0xFE9A33, index HL, BOUNDED `cp HL,0x1F`
    0xFE9BA4  32 x u32  reader 0xFE9B8D, index HL, BOUNDED `cp HL,0x1F`
  Two are byte tables:
    0xFE84F5  37 x 3    "P 1".."P32" then five more "P 1"
    0xFE87B8  37 x 1    0x00..0x1F then five 0x00
RUN
  python3 notes/gen_prom_a_fe8000_module.py > /tmp/region.s
  python3 prom_a/insert_region.py 0xFE8000 0xFEB330 /tmp/region.s
  python3 scripts/analysis/assert_byte_identical.py
  python3 notes/gen_prom_a_fe8000_module.py --check
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import roundtrip as RT                                          # noqa: E402
import prom_a_ringbuf_map as MAP                                # noqa: E402
from gen_prom_a_block import (bytes_block, longs_block,          # noqa: E402
                              decode_region, emit, load_headers)
import gen_prom_a_screens as GS                                  # noqa: E402

BASE = 0xF80000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
LO, HI = 0xFE8000, 0xFEB330


def rd(a, n=1):
    return ROM[a - BASE:a - BASE + n]


def call_sites():
    """The display-list spans of THIS module.

    GS.call_sites() is the tested implementation -- it scans both images for
    `ld XIY,imm32 ... ld XIX,imm32 ... call 0xF417F0/0xF417F4` and it is what
    found all 56 spans of the 0xFEF746 module.  It filters by GS.LO/GS.CODE_END,
    which are that module's bounds, so this rebinds them for the call rather
    than keeping a second copy of the scanner that could drift from it.
    """
    lo, hi = GS.LO, GS.CODE_END
    GS.LO, GS.CODE_END = LO, HI
    try:
        return GS.call_sites()
    finally:
        GS.LO, GS.CODE_END = lo, hi


H = "; ---------------------------------------------------------------------\n"

TABLES = [
    (0xFE8077, 0xFE80F7, "long", "ScreenDispatch_FE8077", H +
     "; ScreenDispatch_FE8077 -- 32 pointers to routines in this module\n"
     "; Read by: 0xFE8060 -- `cp HL,0x001F / jr ugt,<skip> / ld XIX,0x00FE8077 /\n"
     ";          sll HL,2 / extz XHL / add XIX,XHL / ld XIX,(XIX) / call (XIX)`.\n"
     "; ENTRY COUNT 32 is the READER'S OWN BOUND, not an extent: `cp HL,0x001F`\n"
     ";          followed by an unsigned-greater-than branch admits indices\n"
     ";          0..31 and no more.  The extent agrees -- 32 x 4 = 128 bytes\n"
     ";          ends at 0xFE80F7, where code resumes -- but the bound is what\n"
     ";          establishes it.\n"
     "; Evidence: all 32 values are inside this module, the lowest 0xFE8165 and the\n"
     ";          highest 0xFE81E5, and\n"
     ";          the entry WIDTH 4 is the reader's `sll HL,2`.\n"
     "; Unknown:  what the index in HL selects.  Entries 0..7 are all one routine\n"
     ";          (0xFE8165) and entries 16..31 are all another (0xFE81E5), so\n"
     ";          24 of the 32 slots carry two values; the eight in between hold\n"
     ";          seven more (13 and 14 are the same), NINE distinct targets in\n"
     ";          all.  Counted by `--check`, not by eye.\n" + H),
    (0xFE84F5, 0xFE8564, "byte", "PartLabels_FE84F5", H +
     "; PartLabels_FE84F5 -- 37 three-character labels, \"P 1\" .. \"P32\"\n"
     "; Read by: the display list at 0xFE8405, whose 16 records all carry this\n"
     ";          address as their SOURCE field and 0x20/0x0003 as their COUNT\n"
     ";          and STRIDE -- see DisplayList_FE8405 below.  So 32 entries and\n"
     ";          a 3-byte stride are the READER'S, in a field the interpreter\n"
     ";          reads, not an extent.\n"
     "; ENTRY COUNT 37 is 32 from the reader plus an EXTENT of five more: the\n"
     ";          table runs to 0xFE8564, where the next routine's 0x0E begins,\n"
     ";          and those five extra entries all read \"P 1\".\n"
     "; ★ CORROBORATION, and it is a different object: IndexMap_FE87B8 is also\n"
     ";          37 entries and is 0x00..0x1F followed by five 0x00 -- five\n"
     ";          slots that alias slot 0, exactly where this table has five\n"
     ";          slots that alias \"P 1\".  Two tables, two readers, the same\n"
     ";          37-with-5-aliases shape.\n"
     ";          ⚠ That is corroboration of the FRAMING, not of the count: both\n"
     ";          37s are extents.  What is bounded is the 32.\n"
     "; Unknown:  what P stands for.  \"Part\" is the obvious reading and is NOT\n"
     ";          claimed here -- nothing in either image spells the word next to\n"
     ";          this table.\n" + H),
    (0xFE857C, 0xFE85FC, "long", "EditPartSelect_ButtonTable", H +
     "; EditPartSelect_ButtonTable -- 32 pointers, the same shape as 0xFE8077\n"
     "; Read by: 0xFE8565 -- `cp HL,0x001F / jr ugt / ld XIX,0x00FE857C / ...`,\n"
     ";          instruction for instruction the same idiom.\n"
     "; ENTRY COUNT 32 is the reader's bound `cp HL,0x001F`.\n"
     "; Evidence: all 32 values are inside this module, the lowest 0xFE8621 and\n"
     ";          the highest 0xFE8772.\n" + H),
    (0xFE85FF, 0xFE8621, "byte", "EditPartSelect_PartBitMask", H +
     "; EditPartSelect_PartBitMask -- 17 little-endian words, 1 << p for p = 0..15, then 0x0001\n"
     "; Read by: EditPartSelect_OpenEditor (0xFE8778 `ld XIX,0x00FE85FF`, `sll bc,1`, a word load)\n"
     ";          with the part number its SoftKeyCol<n>_EditPartSelect caller passes.\n"
     "; Added 2026-10-03: this generator used to DECODE it (`normal`, `push SR`, `max` ...);\n"
     ";          the source writes it as .short.\n" + H),
    (0xFE87B8, 0xFE87DD, "byte", "IndexMap_FE87B8", H +
     "; IndexMap_FE87B8 -- 37 bytes: 0x00..0x1F, then five 0x00\n"
     "; Read by: 0xFE8811 `ld XIX,0x00FE87B8` then `ld A,(XIX+IY)` (0xFE8816),\n"
     ";          where IY is itself a byte fetched from a RAM table two\n"
     ";          instructions earlier; the result is stored to (0x2250).\n"
     ";          So it is a TRANSLATION table indexed by another table's output.\n"
     "; ENTRY COUNT 37 is the EXTENT -- the reader has no bound, and code\n"
     ";          resumes at 0xFE87DD.  The first 32 entries are the identity.\n"
     "; ★ See PartLabels_FE84F5: that table is also 37 entries with its last\n"
     ";          five aliased onto entry 0, which is what these five 0x00 do.\n"
     "; Unknown:  what the index means, and therefore what the identity is FOR.\n" + H),
    (0xFE8D6B, 0xFE8D9B, "long", "ScreenDispatch_FE8D6B", H +
     "; ScreenDispatch_FE8D6B -- 12 pointers, indexed by (0x601F53)\n"
     "; Read by: 0xFE8D48 -- `ld XIX,0x00FE8D6B / xor XWA,XWA /\n"
     ";          ld A,(0x601F53) / sll WA,2 / add XIX,XWA / ld XIX,(XIX) /\n"
     ";          call (XIX)`.\n"
     "; ⚠ ENTRY COUNT 12 is the EXTENT, not a bound: there is NO compare on the\n"
     ";          index, so a value above 11 would run off the end of the table.\n"
     ";          12 is where the next object starts (0xFE8D9B, an instruction\n"
     ";          that loads the display list at 0xFE8E31).  That is weaker than\n"
     ";          a bound and is stated as such.\n"
     "; Evidence: all 12 values are inside this module, the lowest 0xFE8D9B and\n"
     ";          the highest 0xFE8E22.\n" + H),
    (0xFE9311, 0xFE932D, "long", "ScreenDispatch_FE9311", H +
     "; ScreenDispatch_FE9311 -- 7 pointers, indexed by (0x601F59)\n"
     "; Read by: 0xFE92FB -- the same idiom as 0xFE8D6B, with `sll XWA,2`.\n"
     "; ⚠ ENTRY COUNT 7 is the EXTENT.  There is no bound on (0x601F59) here\n"
     ";          either, and 7 is not a round number, so this is the weakest\n"
     ";          framing of the six dispatch tables.  What supports it: all 7\n"
     ";          values are inside prom_a's 0xFE0000 half, the lowest\n"
     ";          0xFE933F and the highest 0xFEAFF1,\n"
     ";          and the byte at 0xFE932D starts a clean decode.\n" + H),
    (0xFE9A4A, 0xFE9ACA, "long", "NoteEdit_ButtonTable", H +
     "; NoteEdit_ButtonTable -- 32 pointers, bounded reader\n"
     "; Read by: 0xFE9A33 -- `cp HL,0x001F / jr ugt / ld XIX,0x00FE9A4A / ...`.\n"
     "; ENTRY COUNT 32 is the reader's bound.\n"
     "; Evidence: all 32 values are inside this module, the lowest 0xFE9ACA and\n"
     ";          the highest 0xFE9B8C.\n" + H),
    (0xFE9BA4, 0xFE9C24, "long", "DrumEdit_ButtonTable", H +
     "; DrumEdit_ButtonTable -- 32 pointers, bounded reader\n"
     "; Read by: 0xFE9B8D -- `cp HL,0x001F / jr ugt / ld XIX,0x00FE9BA4 / ...`.\n"
     "; ENTRY COUNT 32 is the reader's bound.\n"
     "; Evidence: all 32 values are inside this module, the lowest 0xFE9C24 and\n"
     ";          the highest 0xFE9CD9.\n" + H),
]

MODULE_BANNER = """
; ==============================================================================
; 0xFE8000-0xFEB32F -- CPU 1's SCREEN AND DISPATCH module
; ==============================================================================
;
; The last .incbin of prom_a's 0xFE0000 half, and the neighbour of the
; block-device layer at 0xFE0000-0xFE54B5 and the floppy driver at
; 0xFE54B6-0xFE68F2.  It is built like the 0xFEF746 screen module: routines that
; load a DISPLAY LIST into XIY and a data table into XIX and call the
; interpreter veneer at 0xF417F0/0xF417F4, plus six POINTER DISPATCH tables read
; with one five-instruction idiom.
;
; WHAT IS ESTABLISHED
;   * 35 display lists, every one named by BOTH ends in immediates, and every
;     one passing the record-length walk -- 35/35, checked by
;     `python3 notes/gen_prom_a_fe8000_module.py --check`.
;   * 8 data tables, each named by exactly one `ld XIX,imm32`; four of the six
;     pointer tables have their entry count from the READER'S OWN BOUND.
;   * The module is reached from prom_b: 27 slots of the thunk directory run
;     T_F402A4-T_F4030C name targets from 0xFE8000 up to 0xFE9B8D
;     (`python3 notes/prom_a_module_frontier.py`).
;
; ⚠ WHAT IS NOT
;   Almost every routine here is `sub_XXXXXX`.  This pass CONVERTED the module
;   and framed its data; it did not work out what the screens are.  Names are
;   only on the objects whose reader or whose literal text says what they are.
; ==============================================================================
"""


def main():
    spans = sorted((s, e) for s, e, _t in call_sites())
    which = {(s, e): t for s, e, t in call_sites()}
    for s, e in spans:
        if GS.walk(s, e) is None:
            sys.exit("REFUSED: the length walk from 0x%06X does not land on "
                     "0x%06X" % (s, e))
    regions = sorted([(a, b, "dl", None, None) for a, b in spans] +
                     [(a, b, k, nm, h) for a, b, k, nm, h in TABLES])
    for i in range(1, len(regions)):
        if regions[i][0] < regions[i - 1][1]:
            sys.exit("REFUSED: overlapping non-code regions %r %r"
                     % (regions[i - 1][:3], regions[i][:3]))
    gaps, at = [], LO
    for a, b, *_ in regions:
        if a > at:
            gaps.append((at, a))
        at = b
    if at < HI:
        gaps.append((at, HI))

    if "--check" in sys.argv:
        nrec = sum(len(GS.walk(s, e)) for s, e in spans)
        print("display-list spans: %d, %d records, all pass the length walk"
              % (len(spans), nrec))
        if len(spans) != 35:
            sys.exit("REFUSED: expected 35 display-list spans, found %d"
                     % len(spans))
        print("tables: %d, %d bytes"
              % (len(TABLES), sum(b - a for a, b, *_ in TABLES)))
        print("code gaps: %d, %d bytes" % (len(gaps), sum(b - a for a, b in gaps)))
        bad = []
        for a, b in gaps:
            bad += [r[0] for r in RT.convert(a, b)[0] if r[3] == "byte"]
        print("rows llvm-mc could not spell (kept as .byte with unidasm's "
              "text): %d %s" % (len(bad), ["%06X" % a for a in bad[:6]]))
        # the six dispatch tables really do point into this half of prom_a
        for base, end in ((0xFE8077, 0xFE80F7), (0xFE857C, 0xFE85FC),
                          (0xFE8D6B, 0xFE8D9B), (0xFE9311, 0xFE932D),
                          (0xFE9A4A, 0xFE9ACA), (0xFE9BA4, 0xFE9C24)):
            vals = [int.from_bytes(rd(a, 4), "little")
                    for a in range(base, end, 4)]
            if not all(0xFE0000 <= v <= 0xFEFFFF for v in vals):
                sys.exit("REFUSED: 0x%06X has a value outside prom_a's "
                         "0xFE0000 half" % base)
            runs = {v: vals.count(v) for v in set(vals)}
            print("  0x%06X  %2d entries, %06X-%06X, last entry 0x%08X, "
                  "%d distinct, biggest repeat %d"
                  % (base, len(vals), min(vals), max(vals), vals[-1],
                     len(runs), max(runs.values())))
        d8077 = [int.from_bytes(rd(a, 4), "little")
                 for a in range(0xFE8077, 0xFE80F7, 4)]
        if (d8077[:8] != [0x00FE8165] * 8 or d8077[16:] != [0x00FE81E5] * 16
                or len(set(d8077)) != 9):
            sys.exit("REFUSED: ScreenDispatch_FE8077 is not 8 x 0xFE8165 + "
                     "16 x 0xFE81E5 + 9 distinct targets in all")
        print("ScreenDispatch_FE8077: entries 0..7 = 0x%06X, 16..31 = 0x%06X, "
              "%d distinct targets in all"
              % (d8077[0], d8077[16], len(set(d8077))))
        # the two 37-entry tables, and their five aliases
        lab = [rd(0xFE84F5 + 3 * k, 3).decode("latin1") for k in range(37)]
        idx = list(rd(0xFE87B8, 37))
        if lab[:32] != ["P%2d" % (k + 1) for k in range(32)]:
            sys.exit("REFUSED: PartLabels' first 32 entries are not P 1..P32")
        if lab[32:] != ["P 1"] * 5 or idx[:32] != list(range(32)) or idx[32:] != [0] * 5:
            sys.exit("REFUSED: the five alias entries are not as documented")
        print("PartLabels_FE84F5: %r ... %r, then %d x %r"
              % (lab[0], lab[31], len(lab) - 32, lab[32]))
        print("IndexMap_FE87B8:   identity 0..%d, then %d x 0x00"
              % (idx[31], len(idx) - 32))
        return 0

    hdr, semantic, _ = load_headers()
    refs = MAP.all_refs()
    thunks = MAP.thunk_targets()
    named = {t for t, sites in refs.items()
             if LO <= t < HI
             and any(k in ("call", "jp", "calr") for k, _ in sites)}
    named |= {t for t in thunks if LO <= t < HI}
    named.add(LO)
    labels = {a: semantic.get(a, "sub_%06X" % a) for a in named}
    emitted = set()
    for a, b in gaps:
        emitted |= decode_region(a, b)[1]
    labels = {a: n for a, n in labels.items() if a in emitted}

    out, at = [MODULE_BANNER], LO
    for a, b, kind, nm, h in regions:
        if a > at:
            out += emit(at, a, labels, hdr)[0]
        if kind == "dl":
            out += GS.dl_block(a, b, which[(a, b)])
        elif kind == "long":
            out += longs_block(a, b, nm, h)
        else:
            out += bytes_block(a, b, nm, h)
        at = b
    if at < HI:
        out += emit(at, HI, labels, hdr)[0]
    text = "\n".join(out)
    used = set(re.findall(r"\b(sub_[0-9A-F]{6})\b", text))
    defined = set(re.findall(r"^(sub_[0-9A-F]{6}):", text, re.M))
    if used - defined:
        sys.exit("REFUSED: %d label(s) referenced but never defined: %s"
                 % (len(used - defined), ", ".join(sorted(used - defined))))
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
