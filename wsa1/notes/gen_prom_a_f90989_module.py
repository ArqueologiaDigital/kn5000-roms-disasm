#!/usr/bin/env python3
"""Emit prom_a 0xF90989-0xF92C61 -- the UI FIELD-REDRAW module -- as assembly.

QUESTION IT ANSWERS
  "0xF90989-0xF92C61 is the .incbin between SWI7's packed text services and the
   converted screen code at 0xF92C62.  Where is its code and where are its
   tables?"

  It is the neighbour, and the same kind of thing, as 0xF92C62-0xF96017: UI code
  that hands 32-entry pointer tables to the directory slot T_F41B08.  What is
  new here is a second dispatch shape -- a BITMASK dispatcher, `sub_F917F4`,
  which walks bits 0..7 of A and calls `(XIY + 4*bit)` for each bit that is set.

★ HOW THE TABLES ARE FRAMED, and why the pointer-shape detector is not enough
  `python3 notes/prom_a_ptr_tables.py 0xF90989 0xF92C62` reports FOUR runs.  Two
  of them are wrong as reported, and the reader is what corrects them:
    * its 64-entry run at 0xF914FB is TWO 32-entry tables.  0xF914E1 loads
      0xF914FB and 0xF914ED loads 0xF9157B -- the two arms of one `cp
      (0x2687),0x00` -- and 0xF9157B - 0xF914FB = 0x80 = 32 entries.
    * its 32-entry run at 0xF91865 is FOUR 8-entry tables.  0xF91734, 0xF91746,
      0xF91758 and 0xF9176A load 0xF91865, 0xF91885, 0xF918A5 and 0xF918C5,
      32 bytes apart, and each is handed to `sub_F917F4`, which reads exactly
      eight slots (bit 0 -> (XIY+0x00) ... bit 7 -> (XIY+0x1C)).
  ⚠ That is the wave-5 lesson repeating: a run detector measures SHAPE, and only
  the reader measures EXTENT.  Both corrections are asserted by --check.

★ AND ONE PAIR THE DETECTOR MISSES ENTIRELY: the byte tables at 0xF92618 and
  0xF92623 are not pointer-shaped, so nothing flagged them; they showed up as
  the two `.byte` rows a linear decode could not spell (`jp 0x0100`,
  `jp 0x50c1`).  Their reader searches them linearly and then clamps against a
  MAXIMUM INDEX it loads as an immediate -- 0x0A for the first, 0x09 for the
  second -- so their counts, 11 and 10, are the reader's own bound.

THE 10 TABLES
    0xF90CD8  32 x u32  reader 0xF90CCA -> T_F41B08 -> 0xF8BDC5 `cp HL,0x1F`
    0xF914FB  32 x u32  reader 0xF914E1, the (0x2687) != 0 arm, same callee
    0xF9157B  32 x u32  reader 0xF914ED, the (0x2687) == 0 arm, same callee
    0xF91865   8 x u32  reader 0xF91734 -> sub_F917F4, bits 0..7
    0xF91885   8 x u32  reader 0xF91746 -> sub_F917F4
    0xF918A5   8 x u32  reader 0xF91758 -> sub_F917F4
    0xF918C5   8 x u32  reader 0xF9176A -> sub_F917F4
    0xF92618  11 x u8   reader 0xF924CC/0xF9250D, max index 0x0A
    0xF92623  10 x u8   reader 0xF924D7/0xF92518, max index 0x09
    0xF92726  32 x u32  reader 0xF92718 -> T_F41B08 -> 0xF8BDC5

RUN
  python3 notes/gen_prom_a_f90989_module.py > /tmp/region.s
  python3 prom_a/insert_region.py 0xF90989 0xF92C62 /tmp/region.s
  python3 scripts/analysis/assert_byte_identical.py
  python3 notes/gen_prom_a_f90989_module.py --check
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

BASE = 0xF80000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
LO, HI = 0xF90989, 0xF92C62


def rd(a, n=1):
    return ROM[a - BASE:a - BASE + n]


H = "; ---------------------------------------------------------------------\n"


def bitmask_table(base, site):
    return (base, base + 0x20, "long", "FieldRedrawPtrs_%06X" % base, H +
            "; FieldRedrawPtrs_%06X -- 8 routine pointers, one per BIT\n" % base +
            "; Read by: 0x%06X `ld XIY,0x00%06X`, handed to sub_F917F4.\n"
            % (site, base) +
            "; ENTRY COUNT 8 is the READER'S: sub_F917F4 tests bit 0 through\n"
            ";          bit 7 of A and, for each set bit k, calls the pointer at\n"
            ";          (XIY + 4*k) -- 0x00, 0x04, 0x08, 0x0C, 0x10, 0x14, 0x18,\n"
            ";          0x1C, and no ninth offset exists in it.  So both the\n"
            ";          count and the 4-byte stride are read off the reader.\n"
            "; ⚠ notes/prom_a_ptr_tables.py reports 0xF91865 as ONE 32-entry\n"
            ";          run.  It is four 8-entry tables: 0xF91865, 0xF91885,\n"
            ";          0xF918A5 and 0xF918C5 are each loaded by their own\n"
            ";          `ld XIY` and are exactly 0x20 apart.\n"
            "; Evidence: all 8 values are inside this module.\n" + H)


TABLES = [
    (0xF90CD8, 0xF90D58, "long", "DisplayListPtrs_F90CD8", H +
     "; DisplayListPtrs_F90CD8 -- 32 LE32 pointers\n"
     "; Read by: ONE site, 0xF90CCA `ld XIX,0x00F90CD8 / call T_F41B08`.\n"
     "; ENTRY COUNT 32 comes from the CALLEE'S bound, the same way the seven\n"
     ";          tables of the 0xF92C62 module get theirs: T_F41B08 resolves to\n"
     ";          prom_a 0xF8BDC5, whose first instruction is\n"
     ";          `cp HL,0x001F / jr ugt` -- index 0x1F is the last one it lets\n"
     ";          through.  The shape run measured by notes/prom_a_ptr_tables.py\n"
     ";          agrees: 32 entries, 0 nulls.\n"
     "; Unknown:  what the 32 slots select between.\n" + H),
    (0xF914FB, 0xF9157B, "long", "DisplayListPtrs_F914FB", H +
     "; DisplayListPtrs_F914FB -- 32 LE32 pointers, the (0x2687) != 0 arm\n"
     "; Read by: 0xF914E1 `ld XIX,0x00F914FB`, then `cp (0x2687),0x00 / jr z,\n"
     ";          <load the other table> / call T_F41B08`.  So this table is the\n"
     ";          arm taken when (0x2687) is NON-zero and 0xF9157B is the zero\n"
     ";          arm -- one byte of state picks between two 32-entry tables.\n"
     "; ENTRY COUNT 32 is the callee's bound (0xF8BDC5 `cp HL,0x001F`), and it\n"
     ";          is corroborated by the sibling: 0xF9157B - 0xF914FB = 0x80.\n"
     "; ⚠ notes/prom_a_ptr_tables.py reports ONE 64-entry run here.  It is two\n"
     ";          32-entry tables; the run detector cannot see the second base\n"
     ";          because nothing separates them in the bytes.\n" + H),
    (0xF9157B, 0xF915FB, "long", "DisplayListPtrs_F9157B", H +
     "; DisplayListPtrs_F9157B -- 32 LE32 pointers, the (0x2687) == 0 arm\n"
     "; Read by: 0xF914ED `ld XIX,0x00F9157B`, the taken arm of the `jr z` at\n"
     ";          0xF914EB.  Same callee, same bound of 32.\n" + H),
    bitmask_table(0xF91865, 0xF91734),
    bitmask_table(0xF91885, 0xF91746),
    bitmask_table(0xF918A5, 0xF91758),
    bitmask_table(0xF918C5, 0xF9176A),
    (0xF92618, 0xF92623, "byte", "ValueList_F92618", H +
     "; ValueList_F92618 -- 11 bytes: 00 01 08 09 10 20 28 29 18 19 1A\n"
     "; Read by: 0xF924CC and 0xF9250D, both `ld XIX,0x00F92618`, each the\n"
     ";          bit-SET arm of `bit 0,(0x08EC)`; the clear arm loads\n"
     ";          ValueList_F92623.  The search is\n"
     ";          `L = (0x2682) / DE = 0 / cp L,(XIX+DE) / jr z / inc DE / loop`,\n"
     ";          i.e. FIND THE INDEX of the current value in this list.\n"
     "; ENTRY COUNT 11 is the READER'S BOUND, not the extent: having found the\n"
     ";          index, 0xF924EF loads `IX = 0x000A` on this arm (0x0009 on the\n"
     ";          other) and calls sub_F945B0, which CLAMPS its result to\n"
     ";          [IY, IX] -- so 0x0A is the last legal index and the list has\n"
     ";          eleven entries.  The extent agrees: 0xF92623 is the other\n"
     ";          list's base.\n"
     "; Unknown:  what the values mean.  They are not an index space -- 0x00,\n"
     ";          0x01, 0x08, 0x09, 0x10, 0x20, 0x28, 0x29, 0x18, 0x19, 0x1A --\n"
     ";          and (0x2682) is written back with the chosen one at 0xF92522.\n" + H),
    (0xF92623, 0xF9262D, "byte", "ValueList_F92623", H +
     "; ValueList_F92623 -- 10 bytes: 00 01 08 09 20 28 29 18 19 1A\n"
     "; Read by: 0xF924D7 and 0xF92518, the `bit 0,(0x08EC)` CLEAR arm.\n"
     "; ENTRY COUNT 10 is the reader's bound: the same call site loads\n"
     ";          `IX = 0x0009` on this arm.\n"
     "; ★ It is ValueList_F92618 with 0x10 removed -- one value that the\n"
     ";          (0x08EC) bit 0 state does not offer.  That is what the two\n"
     ";          lists differ by, byte for byte, and --check asserts it.\n" + H),
    (0xF92726, 0xF927A6, "long", "DisplayListPtrs_F92726", H +
     "; DisplayListPtrs_F92726 -- 32 LE32 pointers\n"
     "; Read by: ONE site, 0xF92718 `ld XIX,0x00F92726 / call T_F41B08`.\n"
     "; ENTRY COUNT 32 is the callee's bound (0xF8BDC5 `cp HL,0x001F`).\n" + H),
]

MODULE_BANNER = """
; ==============================================================================
; 0xF90989-0xF92C61 -- UI code, four pointer-table dispatches and a BITMASK one
; ==============================================================================
;
; Between SWI7's two packed text services (0xF90118-0xF90988) and the UI screen
; code at 0xF92C62-0xF96017, and the same kind of thing as the latter: routines
; that hand a 32-entry pointer table to the directory slot T_F41B08.  It is the
; single biggest consumer of that directory in prom_a -- 177 of its `call`s go
; to a 0xF41xxx slot.
;
; ★ WHAT IS NEW HERE: sub_F917F4, a BITMASK dispatcher.  It takes a mask in A
;   and a table of eight routine pointers in XIY and calls, in bit order, the
;   entry for every bit that is set.  Four tables are handed to it, and the
;   masks come from (0x2679), (0x267A) and their neighbours.  That is the shape
;   of a "redraw every field whose dirty bit is set" pass, which is why the four
;   tables are named FieldRedrawPtrs_* -- ⚠ named for the SHAPE of the reader,
;   since what the eight fields ARE is not established.
;
; ⚠ WHAT THIS PASS DID NOT DO
;   It did not name the routines.  Every one is `sub_XXXXXX` except the two the
;   readers define.  It answers no emulation gap; it was chosen because it is a
;   whole .incbin span that the frontier ranks second (22 unconverted directory
;   slots, 8,280 bytes of contiguous target extent) and because closing it
;   leaves this quarter of prom_a unbroken from 0xF8E800 to 0xF96017.
; ==============================================================================
"""


def main():
    regions = sorted(TABLES)
    for i in range(1, len(regions)):
        if regions[i][0] < regions[i - 1][1]:
            sys.exit("REFUSED: overlapping data regions")
    gaps, at = [], LO
    for a, b, *_ in regions:
        if a > at:
            gaps.append((at, a))
        at = b
    if at < HI:
        gaps.append((at, HI))

    if "--check" in sys.argv:
        print("tables: %d, %d bytes"
              % (len(TABLES), sum(b - a for a, b, *_ in TABLES)))
        print("code gaps: %d, %d bytes" % (len(gaps), sum(b - a for a, b in gaps)))
        bad = []
        for a, b in gaps:
            bad += [r[0] for r in RT.convert(a, b)[0] if r[3] == "byte"]
        print("rows llvm-mc could not spell (kept as .byte with unidasm's "
              "text): %d %s" % (len(bad), ["%06X" % a for a in bad]))
        # the two run-detector corrections
        if rd(0xF914E1, 5) != b"\x44\xfb\x14\xf9\x00" or \
           rd(0xF914ED, 5) != b"\x44\x7b\x15\xf9\x00":
            sys.exit("REFUSED: 0xF914FB/0xF9157B are not both `ld XIX` operands")
        for k, site in enumerate((0xF91734, 0xF91746, 0xF91758, 0xF9176A)):
            want = (0xF91865 + 0x20 * k).to_bytes(4, "little")
            if rd(site, 5) != b"\x45" + want:
                sys.exit("REFUSED: 0x%06X is not `ld XIY,0x%06X`"
                         % (site, 0xF91865 + 0x20 * k))
        print("run-detector corrections hold: 0xF914FB is two 32-entry tables, "
              "0xF91865 is four 8-entry tables")
        # sub_F917F4 really reads eight slots and no more
        offs = [rd(a, 3) for a in (0xF917F9, 0xF91807, 0xF91815, 0xF91823,
                                   0xF91831, 0xF9183F, 0xF9184D, 0xF9185B)]
        if [o[1] for o in offs] != [0x00, 0x04, 0x08, 0x0C, 0x10, 0x14, 0x18, 0x1C] \
           or any(o[0] != 0xAD or o[2] != 0x24 for o in offs) \
           or rd(0xF91864) != b"\x0e":
            sys.exit("REFUSED: sub_F917F4 is not eight `ld XIX,(XIY+4k)` then ret")
        print("sub_F917F4: bits 0..7 -> (XIY+0x00 .. XIY+0x1C), `ret` at "
              "0xF91864, so the tables it reads are 8 entries")
        # the two value lists
        v1, v2 = list(rd(0xF92618, 11)), list(rd(0xF92623, 10))
        if v1 != [0x00, 0x01, 0x08, 0x09, 0x10, 0x20, 0x28, 0x29, 0x18, 0x19, 0x1A] \
           or v2 != [x for x in v1 if x != 0x10]:
            sys.exit("REFUSED: the two value lists are not v1 and v1-minus-0x10")
        if rd(0xF924EF, 3) != b"\x34\x0a\x00" or rd(0xF924F8, 3) != b"\x34\x09\x00":
            sys.exit("REFUSED: the max-index immediates are not 0x0A and 0x09")
        print("ValueList_F92618 %s" % v1)
        print("ValueList_F92623 %s -- the same list without 0x10" % v2)
        print("max-index immediates at 0xF924EF/0xF924F8: 0x0A and 0x09, i.e. "
              "11 and 10 entries")
        # the 32-entry tables' callee bound
        if rd(0xF8BDC5, 6) != b"\xdb\xcf\x1f\x00\x6b\x2c":
            sys.exit("REFUSED: 0xF8BDC5 is not `cp HL,0x001F / jr ugt`")
        print("T_F41B08's callee 0xF8BDC5 opens `cp HL,0x001F / jr ugt` -- the "
              "bound the four 32-entry tables get their count from")
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
        out += (longs_block if kind == "long" else bytes_block)(a, b, nm, h)
        at = b
    if at < HI:
        out += emit(at, HI, labels, hdr)[0]
    text = "\n".join(out)
    used = set(re.findall(r"\b(sub_[0-9A-F]{6})\b", text))
    defined = set(re.findall(r"^(sub_[0-9A-F]{6}):", text, re.M))
    # ⚠ `used` is a text scan, so it also catches a name MENTIONED IN PROSE --
    # the ValueList_F92618 header names sub_F945B0, which lives at 0xF945B0,
    # outside this region and already defined in the source.  A name the source
    # already defines is not an undefined symbol, so subtract those too; the
    # linker is the backstop and the byte gate runs it.
    defined |= set(re.findall(r"^(sub_[0-9A-F]{6}):",
                              open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"),
                                   encoding="utf-8").read(), re.M))
    if used - defined:
        sys.exit("REFUSED: %d label(s) referenced but never defined: %s"
                 % (len(used - defined), ", ".join(sorted(used - defined))))
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
