#!/usr/bin/env python3
"""Emit prom_a 0xFEB330-0xFEF746 -- the drum-kit NAME TABLE and its two pointer
tables -- as readable assembly.

QUESTION IT ANSWERS
  "This region is 17,430 bytes of data.  How do I put it in the source so a
  reader can SEE it rather than see 1,090 rows of `.byte`?"
  notes/gen_prom_a_block.py's `@@DATA` renders any data region as `.byte`, which
  is honest but opaque: source_coverage.py's own warning is that a region
  emitted as `.byte` counts as converted "while telling you nothing".  A table
  of fixed-width ASCII names should be `.ascii`, one line per name, with its kit
  and its index in the comment.

  Everything it prints is checked against the ROM before it is printed: the
  script refuses if any name is not exactly 10 printable ASCII bytes with no
  character that would need an escape, and refuses if the three regions do not
  tile the range exactly.

RUN
  python3 notes/gen_prom_a_drumnames.py > /tmp/region.s
  python3 prom_a/insert_region.py 0xFEB330 0xFEF746 /tmp/region.s
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
BASE = 0xF80000

PART_PTRS = (0xFEB330, 35)          # LE32 RAM record pointers
KIT_PTRS = (0xFEB3BC, 130)          # LE32 pointers into the name table
NAMES = (0xFEB5C4, 13, 129, 10)     # base, kits, names per kit, name width


def long_at(a):
    return int.from_bytes(ROM[a - BASE:a - BASE + 4], "little")


def main():
    a, n = PART_PTRS
    b, m = KIT_PTRS
    nb, kits, per, w = NAMES
    if a + 4 * n != b or b + 4 * m != nb:
        sys.exit("REFUSED: the three regions do not tile")
    end = nb + kits * per * w
    if end != 0xFEF746:
        sys.exit("REFUSED: the name table ends at 0x%06X, not 0xFEF746" % end)

    out = []
    out.append(HEADER)
    out.append("RecordPtrs_RAM76A2:")
    for k in range(n):
        v = long_at(a + 4 * k)
        out.append("\t.long 0x%08x%s ; %06X  [%2d] RAM record %d"
                   % (v, " " * 30, a + 4 * k, k,
                      (v - 0x76A2) // 0x40 if v >= 0x76A2 else -1))

    out.append("")
    out.append(KITPTR_HEADER)
    out.append("DrumKitNameBlockPtrs:")
    for k in range(m):
        v = long_at(b + 4 * k)
        blk = (v - nb) // (per * w)
        out.append("\t.long 0x%08x%s ; %06X  [%3d] name block %d"
                   % (v, " " * 30, b + 4 * k, k, blk))

    out.append("")
    out.append(NAMES_HEADER)
    out.append("DrumKitNames:")
    for kit in range(kits):
        blank = sum(1 for j in range(per)
                    if not ROM[nb - BASE + (kit * per + j) * w:
                               nb - BASE + (kit * per + j) * w + w].strip())
        out.append("")
        out.append("; ---- name block %d, 0x%06X: %d of %d names are blank ----"
                   % (kit, nb + kit * per * w, blank, per))
        for j in range(per):
            at = nb + (kit * per + j) * w
            s = ROM[at - BASE:at - BASE + w]
            if len(s) != w or any(not (0x20 <= c < 0x7F) for c in s):
                sys.exit("REFUSED: 0x%06X is not %d printable ASCII bytes" % (at, w))
            if b'"' in s or b"\\" in s:
                sys.exit("REFUSED: 0x%06X needs an escape" % at)
            out.append('\t.ascii "%s"%s ; %06X  [%3d][%3d]'
                       % (s.decode("ascii"), " " * 28, at, kit, j))
    print("\n".join(out))


HEADER = '''; ==============================================================================
; 0xFEB330-0xFEF746 -- the DRUM-KIT NAME TABLE and its two pointer tables
; ==============================================================================
;
; Converted 2026-08-25 by notes/gen_prom_a_drumnames.py, which refuses to emit
; anything it has not first checked against the ROM.  Verified by
; notes/prom_a_drumnames_checks.py.
;
; Three regions that tile the range exactly:
;   0xFEB330  RecordPtrs_RAM76A2          35 x LE32 -> RAM
;   0xFEB3BC  DrumKitNameBlockPtrs   130 x LE32 -> into the name table
;   0xFEB5C4  DrumKitNames           13 blocks x 129 names x 10 characters
;
; ---------------------------------------------------------------------
; RecordPtrs_RAM76A2 -- 35 pointers to 64-byte RAM records
;
; Read by: 0xFEB2E3 -- `ld XIY,0x00FEB330 / xor W,W / sll WA,2 /
;          ld XIX,(XIY+A)`, i.e. indexed by a byte in A at a stride of 4.
;          The record it yields is then read at +0x00 and +0x01.
; ENTRY COUNT 35 is from the EXTENT between this base and the next
;          reader-named base (0xFEB3BC), 140 bytes; ⚠ the reader carries NO
;          bound on A, so this count is weaker than the other two here and is
;          stated as such.
; Evidence that these are RAM records and not code: every value is below
;          0x8000, they step by 0x40 -- except once, 0x7862 -> 0x78E2, which is
;          0x80 -- and the last three repeat entry 0 rather than continuing.
; ★ THE SAME RECORD ARRAY APPEARS IN ANOTHER MODULE.  `PtrTable_FF4251`
;          (0xFF4251) holds sixteen pointers 0x76AF ... 0x7AAF: the same base
;          plus 13, the same 0x40 stride, AND THE SAME SINGLE 0x80 STEP in the
;          same place.  Two modules, written independently, agree on the layout
;          of a 64-byte record array at RAM 0x76A2.
; ★ WHAT A RECORD'S +0x01 BYTE SELECTS, read off the five arms at
;          0xFEB2F5-0xFEB309 (targets from prom_a/roundtrip.py --block, not
;          from arithmetic done by hand):
;            0x20        -> 0xFEB30B: XIY = DrumKitNameBlockPtrs[record+0x00],
;                           i.e. THIS record is a drum part and 0x20 is the
;                           type that reaches the name table;
;            0x28, 0x29  -> 0xFEB31E: XIY = RAM 0x00603FF6;
;            0x30        -> 0xFEB324: XIY = RAM 0x00603FF6 (a second, identical
;                           arm -- the compiler did not merge them);
;            anything else -> 0xFEB32A: XIY = 0xFEB5C4, name BLOCK 0, which is
;                           129 blank names.  So an unrecognised type displays
;                           blanks rather than garbage.
; Unknown:  what types 0x28, 0x29 and 0x30 are, and what lives at RAM
;          0x00603FF6.
; ---------------------------------------------------------------------'''

KITPTR_HEADER = '''; ---------------------------------------------------------------------
; DrumKitNameBlockPtrs -- 130 pointers, one per drum program
;
; Read by: 0xFEB30E -- `ld XIX,0x00FEB3BC / xor W,W / sll WA,2 /
;          ld XIY,(XIX+WA)`, indexed by the record's +0x00 byte.
; ENTRY COUNT 130 is from the EXTENT to the name table's own reader-named base
;          0xFEB5C4 (520 bytes); ⚠ again there is no bound in the reader, and
;          again that is weaker than a bound would be.
; ★ WHAT MAKES THE FRAMING CERTAIN ANYWAY: every one of the 130 values is
;          0xFEB5C4 + 1290*k for an integer k in 0..6 -- exactly on a name-block
;          boundary, never one byte off.  A misframed table would not do that.
; Distribution: 123 of the 130 name block 1; the seven exceptions are programs
;          24, 26 and 29 -> block 2, 40 -> block 3, 48 -> block 5,
;          112 -> block 4, 120 -> block 6.  Blocks 0 and 7-12 are never named
;          by this table.
; ---------------------------------------------------------------------'''

NAMES_HEADER = '''; ---------------------------------------------------------------------
; DrumKitNames -- 13 blocks x 129 names x 10 characters, 16,770 bytes
;
; Fixed-width, space-padded, NO terminator: name j of block k is the ten bytes
; at 0xFEB5C4 + (129*k + j)*10.
;
; ★ HOW THE FRAMING WAS ESTABLISHED, and it is not the string content:
;   1. the region is 16,770 bytes = 13 x 129 x 10 EXACTLY, with no remainder;
;   2. all 130 pointers of DrumKitNameBlockPtrs land on a multiple of 1290 from
;      the base -- so 1290 = 129 x 10 is the block stride the ROM itself uses;
;   3. within a block every name begins on a multiple of 10 and the words read
;      as words ("Bass Dr 1 ", "Crash Cym1") at that offset and at no other.
;   Point 2 is the load-bearing one: it comes from a different table.
;
; The names are General-MIDI percussion legends -- "Bass Dr 1", "Hand Claps",
; "Ride Cym 1", "Cowbell 2", "Vibraslap" -- so a name's INDEX is a MIDI note
; number offset. ⚠ WHICH note index 0 is, is NOT established here: nothing in
; this region states the offset, and it is not guessed.
;
; Block 0 is 129 BLANK names.  It is never named by the pointer table; it is
; what 0xFEB32A -- the FALL-THROUGH arm, for a record type that is none of
; 0x20/0x28/0x29/0x30 -- loads directly, so it is the "nothing to show" block.
; Blocks 7-12 are populated but are not named by DrumKitNameBlockPtrs either --
; some other reader must reach them, and it is NOT located: neither
; notes/prom_a_xref.py nor a raw scan for their addresses finds a site.
; ---------------------------------------------------------------------'''

if __name__ == "__main__":
    main()
