#!/usr/bin/env python3
"""Emit prom_a 0xFEF746-0xFF3800 -- the SCREEN-DRAW module -- as assembly.

QUESTION IT ANSWERS
  "What is the last big .incbin in prom_a, and where exactly does its code stop
  and its data start?"

  It is the module that draws screens.  Its routines are almost all the same
  three instructions --

      ld (0x2540),<layer> ; ld XIY,<list start> ; ld XIX,<list end>
      call 0xF417F0                                  ; DisplayList_Run
      ret
      <the list itself, inline, immediately after the `ret`>

  -- so the module is CODE WITH ITS DATA WOVEN THROUGH IT, and a linear decode
  cannot frame it.  What makes the split checkable rather than a guess is that
  the call site names BOTH ENDS of every list, in immediates the assembler
  cannot lie about.

★ THE FRAMING TEST, and it is the whole reason this file is not guesswork
  A display-list record is `+0 opcode, +1 LENGTH OF THE WHOLE RECORD`, and the
  interpreter advances by that length byte
  (notes/FINDINGS-ui-display-list.md).  So walking the length bytes from the
  <start> immediate must land EXACTLY on the <end> immediate.  It does, for
  **56 of 56** spans in this module.  The script REFUSES to emit anything if a
  single span fails, so the number cannot go stale.
  (For comparison, prom_b's 244 spans came in at 243.)

★ THE SECOND TEST: after the 56 lists and the 13 tables below are removed, a
  linear disassembly of everything left produces **ZERO undecodable bytes**.
  That is also checked here, and also refuses.  It is what says the tables are
  the RIGHT tables: guess one boundary wrong and the decode desynchronises and
  starts printing `db`.

THE 13 TABLES, and why each is a table
  Every one is named by an `ld XIX/XIY,imm32` in this module, and every extent
  ends where the following bytes decode cleanly again.
    0xFEF999  13 x 1   "0123456789***", drawn by SWI7 service 0x17 with BC=1
    0xFEF9FA  12 x u32 pointers into this module -- a screen-drawer table,
              indexed by E and called with `call T,XIY` at 0xFEF9E0
    0xFEFA2A   9 x u32 the same, the arm taken when (0x601F70) bit 0 is set
    0xFEFDE4   1 byte  a single glyph, 0x12
    0xFEFE58   1 byte  a single glyph, 0xAF
    0xFEFFDD  11 x u16 read `ld A,(XIX+) / ld W,(XIX)` at 0xFEFFD7
    0xFF0058  29 x u16 descending 0xA3,0x9F,0x9B... -- Y coordinates, two zero
              terminators; the reader writes the value to (0x2532)
    0xFF00D1  14 x u16 the same shape, 0x9B,0x91,0x87... step 10
    0xFF047F  the KIT-CATEGORY LEGENDS.  See its own header below.
    0xFF0B08  13 x 2   the chromatic NOTE NAMES
    0xFF0B22  12 x 2   the OCTAVE LABELS, "-2".."9 "
    0xFF0D65  99 x 2   TICK/NOTE-VALUE labels; see its header
    0xFF17E2  2,695 bytes of period-8 data whose purpose is NOT established

RUN
  python3 notes/gen_prom_a_screens.py 0xFEF746 0xFF3800 > /tmp/region.s
  python3 prom_a/insert_region.py 0xFEF746 0xFF3800 /tmp/region.s
  python3 scripts/analysis/assert_byte_identical.py
  python3 notes/gen_prom_a_screens.py --check      # the two tests, no output
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import roundtrip as RT                                          # noqa: E402
import prom_a_ringbuf_map as MAP                                # noqa: E402
from gen_prom_a_block import (bytes_block, longs_block, fill,   # noqa: E402
                              decode_region, emit, load_headers)

BASE = 0xF80000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
PROM_B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
LO, HI = 0xFEF746, 0xFF3800
CODE_END = 0xFF226A            # 0xFF226A-0xFF37FF is uniform 0x0E padding
RUN_A, RUN_B = 0xF417F0, 0xF417F4
HTAB_A, HTAB_B = 0xF31D21, 0xF31DB1     # the two handler tables, in prom_b


def rd(a, n=1):
    return ROM[a - BASE:a - BASE + n]


def call_sites():
    """(start, end, interpreter) from `ld XIY,imm32 ... ld XIX,imm32 ... call`.

    Both images are scanned: a list that lives in prom_a can be run from
    prom_b.  The two loads are not always adjacent, so the scan looks back up
    to 32 bytes from the call for the most recent of each.
    """
    out = set()
    for img, base in ((ROM, BASE), (PROM_B, 0xF00000)):
        for i in range(len(img) - 4):
            t = (img[i] == 0x1D and
                 (img[i + 1] | img[i + 2] << 8 | img[i + 3] << 16))
            if t not in (RUN_A, RUN_B):
                continue
            y = x = None
            for j in range(max(0, i - 32), i):
                if img[j] == 0x45 and j + 5 <= i and img[j + 4] == 0x00:
                    y = img[j + 1] | img[j + 2] << 8 | img[j + 3] << 16
                if img[j] == 0x44 and j + 5 <= i and img[j + 4] == 0x00:
                    x = img[j + 1] | img[j + 2] << 8 | img[j + 3] << 16
            if y is not None and x is not None and LO <= y < x <= CODE_END:
                out.add((y, x, t))
    return out


def walk(s, e):
    """Records in [s,e), or None if the length bytes do not land exactly on e."""
    recs, p = [], s
    while p < e:
        op, ln = rd(p)[0], rd(p + 1)[0]
        if ln < 2 or p + ln > e:
            return None
        recs.append((p, op, ln))
        p += ln
    return recs if p == e else None


def handlers(tab, n):
    o = tab - 0xF00000
    return [int.from_bytes(PROM_B[o + 4 * k:o + 4 * k + 4], "little")
            for k in range(n)]


HA, HB = handlers(HTAB_A, 36), handlers(HTAB_B, 16)


def esc(t):
    return t.replace("\\", "\\\\").replace('"', '\\"')


def dl_block(s, e, which):
    """One display list, rendered as its own records."""
    recs = walk(s, e)
    out = ["",
           "; DisplayList_%06X -- %d record(s), %d bytes.  Run by interpreter "
           "%s" % (s, len(recs), e - s, "A (0xF31A09)" if which == RUN_A
                   else "B (0xF31AF0)"),
           "; The length bytes walk from 0x%06X and land exactly on 0x%06X."
           % (s, e),
           "DisplayList_%06X:" % s]
    for p, op, ln in recs:
        raw = rd(p, ln)
        h = None
        if which == RUN_A and op < len(HA):
            h = HA[op]
        elif which == RUN_B and op < len(HB):
            h = HB[op]
        out.append("\t.byte 0x%02X, 0x%02X%s ; %06X  op %02X, %d bytes%s"
                   % (op, ln, " " * 30, p, op, ln,
                      ", handler 0x%06X" % h if h else ""))
        i = 2
        while i < ln:
            j = i
            if 0x20 <= raw[i] <= 0x7E:
                while j < ln and 0x20 <= raw[j] <= 0x7E:
                    j += 1
                if j - i >= 2:
                    out.append('\t.ascii "%s"%s ; %06X'
                               % (esc(raw[i:j].decode("ascii")),
                                  " " * max(1, 34 - (j - i)), p + i))
                    i = j
                    continue
                j = i + 1
            while j < ln and not (0x20 <= raw[j] <= 0x7E and j + 1 < ln
                                  and 0x20 <= raw[j + 1] <= 0x7E):
                j += 1
            out.append("\t.byte %s%s ; %06X"
                       % (", ".join("0x%02X" % c for c in raw[i:j]),
                          " " * max(1, 30 - 6 * (j - i)), p + i))
            i = j
    return out


H = "; ---------------------------------------------------------------------\n"

TABLES = [
    (0xFEF999, 0xFEF9A6, "byte", "Digits_FEF999", H +
     "; Digits_FEF999 -- 13 single characters, \"0123456789\" then three '*'\n"
     "; Read by: 0xFEF973 `ld XIY,0x00FEF999`, then `ld BC,0x0001` and SWI7\n"
     ";          service 0x17 at 0xFEF980 -- BC is the WIDTH, so the entry\n"
     ";          stride is 1 and HL, incremented at 0xFEF984, is the index.\n"
     "; ENTRY COUNT 13 is the extent: code resumes at 0xFEF9A6 and a linear\n"
     ";          decode from there is clean to the next table.\n"
     "; Unknown: what the three '*' entries stand for.\n" + H),
    (0xFEF9FA, 0xFEFA2A, "long", "ScreenDrawPtrs_FEF9FA", H +
     "; ScreenDrawPtrs_FEF9FA -- 12 pointers to screen-drawing routines\n"
     "; Read by: 0xFEF9BD `ld XIY,0x00FEF9FA`, then `XWA = E; XWA <<= 2;\n"
     ";          XIY += XWA; XIY = (XIY); call T,XIY` at 0xFEF9D0-0xFEF9E0.\n"
     ";          E is bounded against (0x601F75) at 0xFEF9F2.\n"
     "; ENTRY COUNT 12 is the extent between this base and the sibling table\n"
     ";          the other arm loads, 0xFEFA2A.  LAST-ENTRY TEST: entry 11 is\n"
     ";          0x00FEFA4E, the same routine as entry 0, and 0xFEFA4E is where\n"
     ";          code resumes after the sibling table -- so the array stops\n"
     ";          exactly where the next object starts.\n"
     "; Evidence: all 12 values are inside this module.\n" + H),
    (0xFEFA2A, 0xFEFA4E, "long", "ScreenDrawPtrs_FEFA2A", H +
     "; ScreenDrawPtrs_FEFA2A -- 9 pointers, the other arm of the same read\n"
     "; Called from: 0xFEF9C9 `ld XIY,0x00FEFA2A`, taken when bit 0 of\n"
     ";          (0x601F70) is SET (tested at 0xFEF9C2).  The 0xFEF9FA table is\n"
     ";          the clear arm.  So (0x601F70) bit 0 picks between two screen\n"
     ";          layouts -- the same bit the whole module tests, 20 times.\n"
     "; ENTRY COUNT 9 is the extent: 0xFEFA4E is an instruction boundary and\n"
     ";          is itself entry 8 of this table and entry 0 of the other.\n" + H),
    (0xFEFDE4, 0xFEFDE5, "byte", "Glyph_FEFDE4", H +
     "; Glyph_FEFDE4 -- ONE character, 0x12, drawn at (0x2530)=x, (0x2532)=0x22\n"
     "; Read by: 0xFEFDD6, with HL = 0 and BC = 1, through SWI7 service 0x17.\n"
     "; Unknown: which glyph 0x12 is.  It is below 0x20, so it is a custom\n"
     ";          cell of the font rather than ASCII.\n" + H),
    (0xFEFE58, 0xFEFE59, "byte", "Glyph_FEFE58", H +
     "; Glyph_FEFE58 -- ONE character, 0xAF, the same shape as Glyph_FEFDE4\n"
     "; Read by: 0xFEFE4A, HL = 0, BC = 1, SWI7 service 0x17, at y = 0x21.\n" + H),
    (0xFEFFDD, 0xFEFFF3, "byte", "WordTable_FEFFDD", H +
     "; WordTable_FEFFDD -- 11 little-endian 16-bit words\n"
     "; Read by: 0xFEFFC6 `ld XIX,0x00FEFFDD`, indexed by (0x601F53) with\n"
     ";          `sll 1,WA` -- a stride of 2 -- then `ld A,(XIX+) / ld W,(XIX)`,\n"
     ";          which returns the two bytes as a PAIR in WA rather than as one\n"
     ";          number.  So `.byte` is the honest emission here, not `.short`.\n"
     "; ENTRY COUNT 11 is the extent to 0xFEFFF3, where code resumes.\n"
     "; Unknown: what the pairs are.  They are not monotonic.\n" + H),
    (0xFF0058, 0xFF0092, "byte", "CoordTable_FF0058", H +
     "; CoordTable_FF0058 -- 29 little-endian 16-bit values, then two zeros\n"
     "; Read by: 0xFF0034 `ld XIX,0x00FF0058`, indexed by (0x601F3A) at a\n"
     ";          stride of 2, and the value goes straight to (0x2532) -- the\n"
     ";          Y COORDINATE cell every SWI7 text call in this module writes.\n"
     "; Evidence that they are coordinates: 0xA3, 0x9F, 0x9B, 0x93 ... 0x2B,\n"
     ";          strictly descending, and the caller adds 3 to get (0x2536).\n"
     "; ENTRY COUNT 29 is the extent to 0xFF0092, where code resumes; the last\n"
     ";          two words are 0x0000 and read as a terminator, but nothing\n"
     ";          tests for zero, so that is a description, not a claim.\n" + H),
    (0xFF00D1, 0xFF00ED, "byte", "CoordTable_FF00D1", H +
     "; CoordTable_FF00D1 -- 14 words of the same kind, step 10 rather than 4\n"
     "; Read by: 0xFF00AD `ld XIX,0x00FF00D1`, same indexed read.\n"
     "; ENTRY COUNT 14 is the extent to 0xFF00ED.  Values 0x9B, 0x91, 0x87 ...\n"
     ";          0x2D, then two zeros.\n" + H),
    (0xFF047F, 0xFF07C5, "byte", "KitCategoryLegends", H +
     "; KitCategoryLegends -- the six-character legends the drum screens show\n"
     ";\n"
     "; ★ FOUR BASES, ONE TABLE, and the routine at 0xFF03E9 picks between them\n"
     ";   by the TYPE BYTE of a RecordPtrs_RAM76A2 record:\n"
     ";     type 0x20  -> 0xFF0485, indexed by the record's +0x00 byte\n"
     ";     type 0x28  -> 0xFF079D  \"user1 \"\n"
     ";     type 0x29  -> 0xFF07AB  \"user2 \"\n"
     ";     type 0x30  -> 0xFF07B9  \"ext   \"\n"
     ";     anything else -> 0xFF047F, six spaces\n"
     ";   -- the same five-way switch on the same +0x01 type byte that\n"
     ";   0xFEB2E3 uses to choose a drum-NAME block, so the two tables are\n"
     ";   indexed by the same object.\n"
     ";\n"
     "; HOW IT IS DRAWN, and where the width comes from: 0xFF03D1 writes\n"
     ";   (0x2530) = 0x00D5 and (0x2532) = 0x0006, calls 0xFF043C for the index\n"
     ";   in HL and 0xFF03E9 for the base in XIY, then `ld BC,0x0006 / ld A,0x17\n"
     ";   / swi 7`.  BC = 6 is the entry WIDTH.\n"
     ";\n"
     "; ★ THE INDEX IS THE DRUM PROGRAM NUMBER, ZERO-BASED, and the legends are the\n"
     ";   General MIDI drum-kit map.  From base 0xFF0485, index 0 is STANDR, 8 ROOM,\n"
     ";   16 POWER, 24 ELEC, 32 JAZZ, 40 BRUSH, 48 GMOrch -- which is GM's\n"
     ";   Standard/Room/Power/Electronic/Jazz/Brush/Orchestra kits at MIDI programs\n"
     ";   1, 9, 17, 25, 33, 41, 49 MINUS ONE.  Technics fills the gaps (9 LIGHT,\n"
     ";   10 FUNK, 25 SOUL, 26 DANCE, 27 HOUSE, 29 SYNTH, 30 MODEL, 33 TRAD,\n"
     ";   112 ORCH, 120 SE) and everything else is blank.\n"
     ";   ★ The test is a KEYWORD test WITH A NEGATIVE CONTROL, in\n"
     ";   `python3 notes/gen_prom_a_screens.py --check`: 7/7 of the GM kits land on\n"
     ";   their own index and 0/7 land one either side.  A first draft used the\n"
     ";   1-based numbers against base 0xFF047F and scored 0/7 and 7/7 at shift -1,\n"
     ";   which is exactly what an off-by-one looks like when the control is there.\n"
     ";   LAST-ENTRY TEST: the highest non-blank entry is 120, \"SE    \", at 0xFF0755.\n"
     ";\n"
     ";   ⚠ RETRACTED 2026-08-25 (round-2 audit F2).  This header said: \"130\n"
     ";   entries x 6 = 780 bytes from 0xFF047F ends at 0xFF078B, and 130 is exactly\n"
     ";   the entry count of DrumKitNameBlockPtrs (0xFEB3BC) -- two tables written\n"
     ";   independently agreeing on the program count.\"  BOTH halves were wrong.\n"
     ";   (a) OFF BY ONE ENTRY.  The arithmetic starts from 0xFF047F, the six-space\n"
     ";   DEFAULT entry the switch hands back for an unrecognised type, which is one\n"
     ";   entry BELOW index 0.  Index 0 is 0xFF0485, and from there 130 x 6 = 780\n"
     ";   bytes end at 0xFF0791 -- which is what this lane's own generator has always\n"
     ";   printed (\"entry 130 would start at 0xFF0791\"): the shipped comment and the\n"
     ";   shipped check script disagreed by a whole entry.\n"
     ";   (b) NOT TWO WITNESSES.  This table's own bytes show no 130 boundary at all:\n"
     ";   entries 121 through 131 are ALL SPACES, and (0xFF079D - 0xFF0485)/6 = 132\n"
     ";   whole entries fit before the next base with no remainder.  The 130 comes\n"
     ";   only from DrumKitNameBlockPtrs, whose own header (see 0xFEB3BC) says its\n"
     ";   count is EXTENT-derived with \"no bound in the reader\".  One extent quoted\n"
     ";   twice is not two tables agreeing.\n"
     ";   ★ WHAT SURVIVES: the base (0xFF0485), the 6-byte stride, the GM mapping\n"
     ";   with its negative control, and the highest labelled entry (120).  The entry\n"
     ";   COUNT is not established by this table -- 130 is a floor from the pointer\n"
     ";   table and 132 is the ceiling this region admits.  Re-derived by\n"
     ";   `python3 notes/prom_a_round3_checks.py` (section KitCategoryLegends).\n"
     ";\n"
     "; ⚠ The last 52 bytes, 0xFF0791-0xFF07C4, are NOT on that 6-byte grid.  The\n"
     ";   run ENDS at 0xFF07C4: 0xFF07C5 is the first byte of sub_FF07C5, so an\n"
     ";   inclusive range written \"-0xFF07C5\" would end on an instruction.\n"
     ";   Twelve blank bytes, then the three literal legends the type switch points\n"
     ";   at -- 0xFF079D \"user1 \", 0xFF07AB \"user2 \", 0xFF07B9 \"ext   \" -- on a\n"
     ";   14-byte stride, and each of the three is stored TWICE:\n"
     ";   \"user1  user1  \", \"user2  user2  \", \"ext   ext   \" (the third pair is 12\n"
     ";   bytes, not 14, because it runs into sub_FF07C5).\n"
     ";   ⚠ Unknown: why the duplicate.  It is NOT a second reader -- a 24-bit and\n"
     ";   32-bit little-endian immediate scan of ALL FOUR ROM images finds the three\n"
     ";   switch bases exactly once each -- as the OPERAND of the `ld XIY` at\n"
     ";   0xFF042A, 0xFF0430 and 0xFF0436, one byte into each instruction -- and finds\n"
     ";   the second copies 0xFF07A4, 0xFF07B2, 0xFF07BF ZERO times.\n"
     ";   They are emitted in the same block because the region is contiguous and the\n"
     ";   ROM gives no boundary; the bases are in the switch, above.\n" + H),
    (0xFF0B08, 0xFF0B22, "byte", "NoteNames", H +
     "; NoteNames -- 13 two-character chromatic note names\n"
     "; \" C\" \"D<88>\" \" D\" \"E<88>\" \" E\" \" F\" \"F<8C>\" \" G\" \"A<88>\" \" A\"\n"
     "; \"B<88>\" \" B\" \" C\"  -- 0x88 is the FLAT glyph and 0x8C the SHARP one,\n"
     "; both below 0x20-and-above-0x7E, i.e. custom font cells.\n"
     "; ENTRY COUNT 13, not 12: the twelfth entry is \" B\" and a THIRTEENTH\n"
     "; repeats \" C\", which is what a note-plus-octave formatter needs when the\n"
     "; index runs one past B.\n"
     "; ⚠ Its reader is not located: nothing in either image spells 0xFF0B08 as\n"
     "; an immediate, because the display list that ends at 0xFF0B08 supplies\n"
     "; the address as its own end.  The framing is from the CONTENT and from\n"
     "; the fact that OctaveNames follows it exactly.\n" + H),
    (0xFF0B22, 0xFF0B3A, "byte", "OctaveNames", H +
     "; OctaveNames -- 12 two-character octave labels, \"-2\" \"-1\" \"0 \" ... \"9 \"\n"
     "; ⚠ CORRECTED 2026-08-25 (round-2 audit F10): this said \"-2 to 9 is twelve\n"
     "; octaves, which is the range a 128-note MIDI keyboard spans when C-2 is note\n"
     "; 0\".  It does not.  With C-2 = note 0, note 127 is G8: MIDI reaches octave 8\n"
     "; and never 9, so eleven of the twelve rows cover the whole note-number range\n"
     "; and the twelfth, \"9 \", is unreachable from one.  What the twelfth row is for\n"
     "; is NOT established.  Code resumes at 0xFF0B3A.\n" + H),
    (0xFF0D65, 0xFF0E2B, "byte", "TickLabels", H +
     "; TickLabels -- 99 two-character cells; 0..96 are labelled, 97 and 98 are blank\n"
     ";\n"
     "; ★ Seven entries are NOT digits, and which seven is the decode: 8, 12,\n"
     ";   16, 24, 32, 48 and 96 carry two bytes below 0x20 instead --\n"
     ";     8 -> 18 1F   12 -> 18 20   16 -> 17 1F   24 -> 17 20\n"
     ";    32 -> 16 1F   48 -> 16 20   96 -> 15 20\n"
     ";   ⚠ CORRECTED 2026-08-25 (round-2 audit F3): this said \"exactly the\n"
     ";   divisors of 96\", which is FALSE -- 1, 2, 3, 4 and 6 divide 96 too and all\n"
     ";   five carry ordinary digits (\" 1\" \" 2\" \" 3\" \" 4\" \" 6\", read from ROM).  The\n"
     ";   rule is \"the divisors of 96 that are >= 8\".  (A softer form, \"the divisors\n"
     ";   that matter musically\", was in notes/FINDINGS-prom_a-screen-module.md and is\n"
     ";   also gone: it cannot fail.)  96 ticks is one beat, so\n"
     ";   the seven are NOTE-VALUE GLYPHS (96th, 48th, 32nd, 24th = 16th\n"
     ";   triplet, 16th, 12th = 8th triplet, 8th) drawn as a note symbol\n"
     ";   instead of a number.  The glyph pairs step 0x18, 0x17, 0x16, 0x15 as\n"
     ";   the note gets longer, with the second byte 0x1F/0x20 alternating --\n"
     ";   a two-cell symbol, stem and head.\n"
     "; ENTRY COUNT 99 is the EXTENT: 0xFF0E2B, where the table stops, is the\n"
     ";   start of a display list named by an immediate.\n"
     ";   ⚠ LAST-ENTRY TEST (round-2 audit F3): entries 97 (0xFF0E27) and 98\n"
     ";   (0xFF0E29) are `20 20`, BLANK.  The highest labelled value is 96, the\n"
     ";   whole-beat glyph at 0xFF0E25.  So the extent is 99 cells and the labelled\n"
     ";   range is 0..96; \"labels for a tick count, 0 to 98\" over-stated it by two.\n"
     ";   Re-derived by `python3 notes/prom_a_round3_checks.py` (section TickLabels).\n"
     "; ⚠ WHAT IS NOT ESTABLISHED: that a beat is 96 ticks HERE.  The divisor\n"
     ";   set is the evidence for it, and nothing in this module states a\n"
     ";   resolution.\n" + H),
    (0xFF17E2, 0xFF2269, "byte", "Data_FF17E2", H +
     "; Data_FF17E2 -- 2,695 bytes of period-8 data.  NOT DECODED.\n"
     "; It is here because it is data, not because it is understood: a linear\n"
     "; disassembly of it is nonsense and the bytes repeat on an 8-byte period\n"
     "; (`FF 00 00 00 00 00 FC FC`, `FF 01 01 01 01 01 01 01`, ...).\n"
     "; What names it: 0xFE83D2 `ld XIX,0x00FF17E2` -- it is the END immediate\n"
     "; of the display list that starts at 0xFF158A, so the byte after the last\n"
     "; record is where this begins.  Nothing else in either image names any\n"
     "; address inside it.\n"
     "; Unknown: everything else.  A bitmap, an envelope table and a per-step\n"
     "; pattern grid all fit the shape; none is claimed.\n" + H),
]

NAMES = {}          # semantic labels for code addresses
HEADERS = {}


def check():
    sites = call_sites()
    spans = sorted({(s, e) for s, e, t in sites})
    bad = [(s, e) for s, e in spans if walk(s, e) is None]
    if bad:
        sys.exit("REFUSED: %d display-list span(s) fail the length walk: %s"
                 % (len(bad), ["%06X-%06X" % x for x in bad]))
    data = sorted(spans + [(a, b) for a, b, *_ in TABLES])
    for i in range(1, len(data)):
        if data[i][0] < data[i - 1][1]:
            sys.exit("REFUSED: overlapping data regions %r %r"
                     % (data[i - 1], data[i]))
    # every code gap must decode with no undecodable byte
    gaps, cur = [], LO
    for a, b in data:
        if a > cur:
            gaps.append((cur, a))
        cur = max(cur, b)
    if cur < CODE_END:
        gaps.append((cur, CODE_END))
    badbytes = []
    for a, b in gaps:
        for addr, bs, text, why, u in RT.convert(a, b)[0]:
            if why == "byte":
                badbytes.append(addr)
    return spans, data, gaps, badbytes


def main():
    spans, data, gaps, badbytes = check()
    if "--check" in sys.argv:
        nrec = sum(len(walk(s, e)) for s, e in spans)
        print("display-list spans: %d, %d records, all pass the length walk"
              % (len(spans), nrec))
        print("tables: %d, %d bytes"
              % (len(TABLES), sum(b - a for a, b, *_ in TABLES)))
        print("code gaps: %d, %d bytes" % (len(gaps), sum(b - a for a, b in gaps)))
        print("bytes roundtrip could not spell as an instruction: %d %s"
              % (len(badbytes), ["%06X" % a for a in badbytes[:8]]))
        # ---- the kit-category legends really are the General MIDI kit map ----
        # 130 entries of 6 characters from 0xFF0485.  A KEYWORD test with a
        # NEGATIVE CONTROL, the same shape as
        # notes/prom_a_drumnames_checks.py section 6b: if the shifted tests
        # passed too, the test would be measuring "these words are in the
        # table", not "they are at the GM program number".
        # ⚠ 0-BASED.  General MIDI numbers its drum kits 1, 9, 17, 25, 33, 41,
        # 49; this table's index is the MIDI program number MINUS ONE, so they
        # land at 0, 8, 16, 24, 32, 40, 48.  A first draft used the 1-based
        # numbers against base 0xFF047F and scored 0/7 aligned and 7/7 at
        # shift -1, which is what an off-by-one looks like when the control is
        # there to show it.
        GM = {0: "STANDR", 8: "ROOM", 16: "POWER", 24: "ELEC", 32: "JAZZ",
              40: "BRUSH", 48: "GMOrch"}
        base = 0xFF0485

        def leg(k, shift=0):
            return rd(base + (k + shift) * 6, 6).decode("latin1")

        def hits(shift):
            return sum(1 for k, v in GM.items() if leg(k, shift).strip() == v)
        ok = (hits(0), hits(1), hits(-1))
        print("kit-category legends at their General MIDI program number: "
              "%d/%d aligned, %d and %d one either side"
              % (ok[0], len(GM), ok[1], ok[2]))
        if ok[0] != len(GM) or ok[1] or ok[2]:
            sys.exit("REFUSED: the GM alignment test did not separate")
        # LAST-ENTRY TEST.  ⚠ CORRECTED 2026-08-25 (round-2 audit F2): the
        # comment here used to say "entry 121 is the last NON-BLANK one" while
        # the assertion below tested 120 -- 120 is right.  And the printed line
        # said the 6-byte grid "stops matching" at entry 130; it does not.  The
        # grid runs on, all blank, to entry 131, and entry 132 lands exactly on
        # 0xFF079D, the next base.  What entry 130 marks is the end of the
        # extent DrumKitNameBlockPtrs implies, nothing this table shows.
        last = max(k for k in range(132) if leg(k).strip())
        print("highest non-blank entry: %d (%r); entry 130 would start at "
              "0x%06X; entries 121..131 are all blank and entry 132 is 0x%06X, "
              "the next switch base"
              % (last, leg(last), base + 130 * 6, base + 132 * 6))
        if any(leg(k).strip() for k in range(121, 132)):
            sys.exit("REFUSED: an entry between 121 and 131 is not blank")
        if base + 132 * 6 != 0xFF079D:
            sys.exit("REFUSED: entry 132 is not the next switch base")
        if last != 120 or leg(120).strip() != "SE":
            sys.exit("REFUSED: the last non-blank legend is not 120 'SE'")
        return 0

    which = {}
    for s, e, t in call_sites():
        which[(s, e)] = t
    hdr, semantic, _ = load_headers()
    refs = MAP.all_refs()
    thunks = MAP.thunk_targets()
    named = {t for t, sites in refs.items()
             if LO <= t < CODE_END
             and any(k in ("call", "jp", "calr") for k, _ in sites)}
    named |= {t for t in thunks if LO <= t < CODE_END}
    named.add(LO)
    labels = {a: semantic.get(a, "sub_%06X" % a) for a in named}
    emitted = set()
    for a, b in gaps:
        emitted |= decode_region(a, b)[1]
    labels = {a: n for a, n in labels.items() if a in emitted}

    out, at = [], LO
    regions = sorted([(a, b, "dl", None, None) for a, b in spans] +
                     [(a, b, k, nm, h) for a, b, k, nm, h in TABLES])
    for a, b, kind, nm, h in regions:
        if a > at:
            out += emit(at, a, labels, hdr)[0]
        if kind == "dl":
            out += dl_block(a, b, which.get((a, b), RUN_A))
        elif kind == "long":
            out += longs_block(a, b, nm, h)
        else:
            out += bytes_block(a, b, nm, h)
        at = b
    if at < CODE_END:
        out += emit(at, CODE_END, labels, hdr)[0]
    out += fill(CODE_END, HI)
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
