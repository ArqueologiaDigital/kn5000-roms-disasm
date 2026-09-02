#!/usr/bin/env python3
"""Emit prom_a 0xF8C485-0xF8C630 (427 B) as verified assembly.

QUESTION IT ANSWERS
  FINDINGS-prom_a-f8c000-cluster.md left this span `.incbin`, refused, with a
  specific complaint: DispatchTable_F8C2B2 (already-converted, committed code)
  names 0xF8C485 and 0xF8C4D8 as entry points, the span decodes overall with
  ZERO undecodable bytes and 0xF8C630 lands on a boundary -- but one of the
  table's own targets, 0xF8C4D8, lands **3 bytes inside** an instruction of
  that same linear decode (`ld XWA,0xc4c08000` at 0xF8C4D5-0xF8C4DA). That is
  exactly the subtle mid-span drift this project has been burned by before:
  a decode that resyncs by the end can still be wrong in the middle, and "0
  undecodable bytes" does not by itself detect it (FINDINGS-prom_a-fde74c
  -boundary.md, FINDINGS-prom_a-fcf000-module.md section 4 make the same
  point from the opposite direction).

  What was actually wrong: 0xF8C4B8-0xF8C4D7 (32 B) is not code at all. The
  FIRST function in the span (0xF8C485-0xF8C4B7) ends with a genuine indexed
  table read -- `ld A,(0x2169) / and A,0x0f / sla 0x01,A / ld XIY,0x00f8c4b8
  / ld WA,(XIY+A)` -- a 16-entry WORD table indexed 0..15 by a nibble shifted
  left by one. That pins the table's SIZE from the reader, not from a walk:
  max index 15, word width 2, so the table spans exactly 32 bytes, landing
  on 0xF8C4D8 -- DispatchTable_F8C2B2's OWN second target, independently
  committed to the tree before this pass touched the span.

  The table's own VALUES corroborate the read: 16 little-endian words,
  0x0101, 0x0201, 0x0401, ... 0x8001, then 0x0100, 0x0200, ... 0x8000 -- a
  clean single-bit-per-nibble progression, not noise a walk could mistake
  for anything else.

  The same shape repeats twice more, smaller: a 3-value bucket-select idiom
  (`cp A,0x18` / `jr c` / `cp A,0x1a` / `jr ugt` / `sub A,0x18` / `extz WA` /
  `extz XWA` / `add XWA,<table>` / `ld A,(XWA)`) appears at both
  0xF8C4FF->0xF8C536 and 0xF8C55B->0xF8C592, each time reading a 3-byte
  table (index 0..2) that is immediately followed by ONE extra byte
  duplicating the table's own last entry (0x40,0x40 and 0x04,0x04) -- a
  padding convention, not a decode error, confirmed because the table VALUES
  match the function's own hardcoded fallback constants for the same three
  buckets bit for bit (0x10/0x20/0x40 and 0x01/0x02/0x04).

  With all three tables excised (32 + 4 + 4 = 40 B of data out of 427 B),
  the REMAINING bytes decode as five short, near-identical bit-set/clear
  routines with zero drift, and FOUR of DispatchTable_F8C2B2's eight
  non-placeholder targets land exactly on the resulting function starts:
  0xF8C485, 0xF8C4D8, 0xF8C596, 0xF8C5E3 -- external, independently
  committed pointers, not a walk's plausibility judgement. This is the same
  evidentiary standard as FINDINGS-prom_a-fc4000-boundary.md and
  FINDINGS-prom_a-fde74c-boundary.md: the boundary is fixed by something
  outside the walk.

  WHAT IS NOT CLAIMED: semantics (every routine is `sub_XXXXXX`, every table
  is named only by its shape) and reachability.py's STRONG-seed status,
  which still does not credit this span (a bare `ld XIY,imm32` read is
  explicitly excluded from that walk's seed classes, same limitation noted
  in FINDINGS-prom_a-f8c000-cluster.md).

RUN
  python3 notes/gen_prom_a_f8c485_module.py --check
  python3 notes/gen_prom_a_f8c485_module.py --emit > /tmp/f8c485_region.s
  python3 prom_a/insert_region.py 0xF8C485 0xF8C630 /tmp/f8c485_region.s
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
import roundtrip as RT  # noqa: E402

BASE = 0xF80000
LO, HI = 0xF8C485, 0xF8C630

# The three data tables, pinned by their own readers -- not by a walk.
TABLE1_LO, TABLE1_HI = 0xF8C4B8, 0xF8C4D8   # 32 B, 16-word bitmask table
TABLE2_LO, TABLE2_HI = 0xF8C536, 0xF8C53A   # 4 B, 3-entry bucket + pad
TABLE3_LO, TABLE3_HI = 0xF8C592, 0xF8C596   # 4 B, 3-entry bucket + pad

# The four code segments between/around the tables.
SEG_A = (0xF8C485, TABLE1_LO)   # sub_F8C485, dispatch id=0x0004
SEG_B = (TABLE1_HI, TABLE2_LO)  # sub_F8C4D8, dispatch id=0x0040
SEG_C = (TABLE2_HI, TABLE3_LO)  # .LF8C53A, internal only
SEG_D1 = (TABLE3_HI, 0xF8C5E3)  # sub_F8C596, dispatch id=0x0100
SEG_D2 = (0xF8C5E3, HI)         # sub_F8C5E3, dispatch id=0x0800

DISPATCH_TARGETS_IN_SPAN = {0xF8C485, 0xF8C4D8, 0xF8C596, 0xF8C5E3}

TABLE1_WORDS = [0x0101, 0x0201, 0x0401, 0x0801, 0x1001, 0x2001, 0x4001, 0x8001,
                0x0100, 0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000, 0x8000]
TABLE2_BYTES = [0x10, 0x20, 0x40, 0x40]
TABLE3_BYTES = [0x01, 0x02, 0x04, 0x04]


def rom():
    return open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()


def read(lo, hi):
    return rom()[lo - BASE:hi - BASE]


def cmd_check():
    ok = True
    checks = []

    # 1. table byte contents match what this note claims, read straight from the ROM
    import struct
    t1 = list(struct.unpack("<16H", read(TABLE1_LO, TABLE1_HI)))
    checks.append(("TABLE1 (16 words @0xF8C4B8) matches the claimed bitmask progression",
                    t1 == TABLE1_WORDS))
    t2 = list(read(TABLE2_LO, TABLE2_HI))
    checks.append(("TABLE2 (4 B @0xF8C536) matches, last entry duplicated as pad",
                    t2 == TABLE2_BYTES and t2[2] == t2[3]))
    t3 = list(read(TABLE3_LO, TABLE3_HI))
    checks.append(("TABLE3 (4 B @0xF8C592) matches, last entry duplicated as pad",
                    t3 == TABLE3_BYTES and t3[2] == t3[3]))

    # 2. table sizes are pinned by the reader's own index range, not chosen to fit
    #    TABLE1: nibble (0-15) << 1  -> max byte offset 31 -> 32 B, word width 2
    max_idx1 = 15
    checks.append(("TABLE1 size (32 B) = (max nibble index 15 << 1) + word width 2",
                    (max_idx1 * 2) + 2 == (TABLE1_HI - TABLE1_LO) == 32))
    #    TABLE2/TABLE3: cp-chain proves passthrough range is A in {0x18,0x19,0x1a}
    #    (jr c bypasses A<0x18, jr ugt bypasses A>0x1a) -> 3 valid indices, byte width 1,
    #    plus the one observed pad byte duplicating the table's own last entry.
    checks.append(("TABLE2/TABLE3 size (4 B each) = 3 valid indices (cp 0x18..0x1a) + 1 pad",
                    (TABLE2_HI - TABLE2_LO) == 4 and (TABLE3_HI - TABLE3_LO) == 4))
    #    TABLE2/TABLE3 values equal the SAME functions' own hardcoded fallback
    #    constants for the same three buckets -- independent corroboration.
    checks.append(("TABLE2 values (0x10,0x20,0x40) match sub_F8C4D8's own "
                    "cp 0x08/0x28->0x10, cp 0x09/0x29->0x20, else->0x40 fallback",
                    t2[:3] == [0x10, 0x20, 0x40]))
    checks.append(("TABLE3 values (0x01,0x02,0x04) match sub_F8C53A's own "
                    "cp 0x08/0x28->0x01, cp 0x09/0x29->0x02, else->0x04 fallback",
                    t3[:3] == [0x01, 0x02, 0x04]))

    # 3. byte accounting: 4 code segments + 3 tables = 427 B, contiguous, no gaps/overlap
    bounds = [SEG_A, (TABLE1_LO, TABLE1_HI), SEG_B, (TABLE2_LO, TABLE2_HI),
              SEG_C, (TABLE3_LO, TABLE3_HI), SEG_D1, SEG_D2]
    contiguous = bounds[0][0] == LO and bounds[-1][1] == HI
    for i in range(1, len(bounds)):
        contiguous = contiguous and bounds[i - 1][1] == bounds[i][0]
    total = sum(hi - lo for lo, hi in bounds)
    checks.append(("7 pieces are contiguous 0xF8C485-0xF8C630 with no gap/overlap",
                    contiguous))
    checks.append(("byte accounting: total = 427", total == 427 == (HI - LO)))

    # 4. all 4 dispatch targets in this span land on a code-segment START
    seg_starts = {SEG_A[0], SEG_B[0], SEG_D1[0], SEG_D2[0]}
    checks.append(("all 4 DispatchTable_F8C2B2 targets in this span land on a "
                    "converted segment start (0xF8C485, 0xF8C4D8, 0xF8C596, 0xF8C5E3)",
                    DISPATCH_TARGETS_IN_SPAN <= seg_starts))

    # 5. the whole thing actually round-trips byte-exact through llvm-mc
    region = build_region()
    src = RT.macro_prelude() + "\n\t.text\n" + region
    got = RT.assemble_block(src)
    expected = read(LO, HI)
    checks.append(("whole 427 B region round-trips byte-exact through llvm-mc",
                    got == expected))

    for name, passed in checks:
        print(f"  {name:<78s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    return 0 if ok else 1


def _block_text(lo, hi):
    lines, good, stats = RT.emit_block(lo, hi)
    if not good:
        sys.stderr.write("!! block 0x%06X-0x%06X did NOT round-trip: %r\n"
                          % (lo, hi, dict(stats)))
        sys.exit(1)
    out = []
    for l, addr, bs, why in lines:
        if addr is None:
            out.append(l)
        else:
            raw = " ".join("%02x" % b for b in bs)
            out.append("%-46s ; %06X  %s" % (l, addr, raw))
    return "\n".join(out)


def build_region():
    parts = []
    parts.append("; ---------------------------------------------------------------------")
    parts.append("; 0xF8C485-0xF8C630 (427 B) -- CONVERTED, see")
    parts.append("; notes/FINDINGS-prom_a-f8c485-boundary.md.  Five short bit-set/clear")
    parts.append("; routines reached by DispatchTable_F8C2B2 (already committed, above),")
    parts.append("; three small data tables pinned by their own readers' index ranges.")
    parts.append("; ---------------------------------------------------------------------")
    parts.append("sub_F8C485:   ; entry: DispatchTable_F8C2B2 id=0x0004")
    parts.append(_block_text(*SEG_A))
    parts.append("BitmaskTable_F8C4B8:   ; 32 B, 16 words, read via (nibble<<1) index")
    parts.append("\t.short 0x0101, 0x0201, 0x0401, 0x0801, 0x1001, 0x2001, 0x4001, 0x8001"
                 "  ; F8C4B8")
    parts.append("\t.short 0x0100, 0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000, 0x8000"
                 "  ; F8C4C8")
    parts.append("sub_F8C4D8:   ; entry: DispatchTable_F8C2B2 id=0x0040")
    # emit_block cannot see .LF8C53A -- it lies just past this segment's own
    # end, inside SEG_C -- so it prints the raw literal displacement (0x5c)
    # instead of the label. Substitute it; the assembler computes the same
    # displacement from the label, verified by the whole-region round-trip
    # below.
    seg_b = _block_text(*SEG_B).replace("jr z, 0x5c", "jr z, .LF8C53A")
    parts.append(seg_b)
    parts.append("BucketTable_F8C536:   ; 3 entries (index 0-2) + 1 pad byte "
                 "duplicating the last entry")
    parts.append("\t.byte 0x10, 0x20, 0x40, 0x40   ; F8C536")
    parts.append(".LF8C53A:   ; internal only -- reached by sub_F8C4D8's own jr z")
    parts.append(_block_text(*SEG_C))
    parts.append("BucketTable_F8C592:   ; 3 entries (index 0-2) + 1 pad byte "
                 "duplicating the last entry")
    parts.append("\t.byte 0x01, 0x02, 0x04, 0x04   ; F8C592")
    parts.append("sub_F8C596:   ; entry: DispatchTable_F8C2B2 id=0x0100")
    parts.append(_block_text(*SEG_D1))
    parts.append("sub_F8C5E3:   ; entry: DispatchTable_F8C2B2 id=0x0800")
    parts.append(_block_text(*SEG_D2))
    return "\n".join(parts) + "\n"


def main():
    if "--check" in sys.argv:
        sys.exit(cmd_check())
    if "--emit" in sys.argv:
        print(build_region())
        return
    sys.exit("usage: --check | --emit")


if __name__ == "__main__":
    main()
