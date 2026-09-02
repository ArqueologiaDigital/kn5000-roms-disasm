#!/usr/bin/env python3
"""Convert lane res02f's two `.incbin` spans in prom_b -- 88 of the last 481
verbatim bytes -- to typed data, with the extents taken from the records that
NAME each object rather than from the shape of the bytes.

QUESTION IT ANSWERS
    Two of the sixteen spans notes/FINDINGS-prom_b-last-481-bytes.md lists are

        0xF02FFE  44 B   "pointer + LE16 coordinate quads"
        0xF13D34  44 B   "glyph/bitmap -- only SEVEN distinct byte values"

    What are they, and what is the ROW/ENTRY WIDTH?  The shape of the bytes
    suggests answers to both and that document is explicit that a stride read
    off the bytes of a span known to start mid-record is NOT a layout to emit:
    any framing of the right bytes reproduces the ROM, so the byte gate cannot
    object to a wrong one.  So both widths here come from a display-list record
    that points at the object and from the handler that consumes that pointer.

    Answers:

    * 0xF02FFE is the last four bytes of ONE interpreter-B record plus a
      5-entry array of 8-byte entries.  Not a coordinate quad table in its own
      right -- the array is the OPERAND array of the record at 0xF02FF7, whose
      first 7 bytes the round-1 pass already typed as `Data_F02FF7`.  The
      `.incbin` starts at the record's +7 field, i.e. INSIDE the record.
    * 0xF13D34 is the tail of a 24-byte BITMAP at 0xF13D30 plus a whole 24-byte
      bitmap at 0xF13D48.  Four such bitmaps tile 0xF13D00-0xF13D5F.

WHERE EACH WIDTH COMES FROM -- the point of this script
    0xF03002: the record at 0xF02FF7 is `03 0B`, and interpreter B's handler
        table HTBL_B (0xF31DB1) sends opcode 3 to 0xF31B57, which does
            calr 0xF31CC5 / ld HL,WA / sla 0x03,HL / extz XHL
            ld A,(XIY+6) / ld XIX,(XIY+7) / add XIX,XHL
            ld BC,(XIX) -> (0x2530) ... ld BC,(XIX+6) -> (0x2536) / swi 7
        `sla 0x03,HL` scales the extracted field by EIGHT, so the entries are
        8 bytes, and the four words of the selected entry are X0, Y0, X1, Y1
        (notes/FINDINGS-display-controller.md establishes those four addresses
        from the clamp constants 319 and 239).  The COUNT is the extent: the
        array starts where the +7 pointer lands, 0xF03002, and ends on
        0xF0302A, the first byte of the interpreter-B display list below --
        40 bytes, 5 entries.  The record's own (mask >> shift) + 1 = 16 is an
        upper bound and is NOT the count.

    0xF13D30 / 0xF13D48: six interpreter-A records, all `03 0C` -> handler
        0xF31ABE, carry +2 = a pointer into 0xF13D00-0xF13D48, +8 = BC = 2 and
        +0x0A = HL = 12.  BC is bytes per column and HL is rows, so each object
        is BC * HL = 24 bytes (the rule lane promB5 proved for the op-0x03
        bitmaps at 0xF283A7 and 0xF2843D).  Four objects at 0xF13D00, 0xF13D18,
        0xF13D30, 0xF13D48 tile 0xF13D00-0xF13D5F, and the last ends EXACTLY on
        0xF13D60.  ⚠ 0xF13D60 is NOT a call-site start -- nothing in the image
        passes it to an interpreter, as the source's own header for that list
        says.  Its anchor is the op/len walk: 45 records from 0xF13D60, every
        length byte equal to its handler's implied length, landing on 0xF13F1E
        with zero drift -- and the same walk started at 0xF13D34, 0xF13D38,
        0xF13D48 or 0xF13D5C fails on its FIRST record.  That is the null.

    ⚠ AND THE NULL FOR THE POINTER SCAN.  Six 32-bit words in prom_b land in
        0xF13D00-0xF13D5F and all six are the +2 field of one of those records.
        Widen the window sixteen bytes DOWN and six more appear -- all in
        prom_a, all reading 0xF13CFF, and every one straddling three
        instructions (`link XIZ,0xffee` = `ee 0c ee ff`, `push XIX` = `3c`,
        `lda_d16 XIX,(0x2900)` = `f1 00 29 34`).  A raw 4-byte scan over code
        DOES produce false positives at that rate, which is why the test used
        here is the record test -- opcode < 0x24, handler == 0xF31ABE, length
        byte == 12 -- and never the pointer value on its own.

BYTE ORDER OF THE BITMAPS -- an inference, and it changes no byte
    Read COLUMN-major (byte column c, row r at +c*12+r) the object at 0xF13D00
    draws a closed circle; read row-major it is noise.  Quantified as
    4-neighbour edge density, column-major against row-major, for the four:
    0.258/0.292, 0.275/0.312, 0.149/0.208, 0.112/0.152 -- column-major is lower
    on all four.  The handler's own instructions were not traced for the
    ordering, so this is an inference; it affects only the picture in the
    comment.

WHAT THIS LANE REFUSED, AND THE MEASUREMENT THAT DE-RISKS IT
    The span at 0xF13D34 starts FOUR BYTES INSIDE the bitmap at 0xF13D30.
    Those four bytes are the tail of the `.byte` run of `Data_F139AB`, which
    notes/gen_prom_b_f0ea9f_module.py emits from `("data", 0xF139AB, 0x0389)`
    and whose `--checks` asserts its LAYOUT covers 0xF0EA9F-0xF13D33 exactly
    (`LO, HI` in notes/prom_b_f0ea9f_layout.py).  So the bitmap at 0xF13D30 is
    emitted here as its span-visible TAIL, with the whole picture in the header.

    ⚠ The reason is NOT that the shift is dangerous to that module's code walk.
    That was measured, and it is not: notes/res02f_f0ea9f_hi_shift_probe.py
    emits the module twice, once with `LY.HI = 0xF13D34` and once with
    0xF13D30, and the two differ in exactly SIX lines, all six being the four
    bytes themselves (21141 -> 21137, `Data_F139AB` 905 -> 901, its printable
    preview, and the last `.byte` line).  Both emissions have 81 segments and
    23 unsplit `.byte` runs; not one label, instruction or boundary moves.

    What stopped this lane is narrower and is stated so it can be closed:
    `prom_b_f0ea9f_layout` is imported by FOUR other modules
    (gen_prom_b_f6d002_module, prom_b_f067a6_layout, prom_b_f4f000_layout,
    prom_b_f4f000_verify), and the probe bypasses `--checks`.  Those two things
    were not measured, and neither belongs to this lane.

RUN
    python3 notes/gen_res02f_spans.py --selftest  # every claim above, re-derived
    python3 notes/gen_res02f_spans.py --census    # .incbin bytes left in the 2 spans
    python3 notes/gen_res02f_spans.py --render    # the bitmaps, both orderings
    python3 notes/gen_res02f_spans.py --asm       # the text, to stdout
    python3 notes/gen_res02f_spans.py --splice    # write it into prom_b/wsa1_prom_b.s
    python3 notes/gen_res02f_spans.py --falsify   # the gate must go RED, then restore
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_b_display_lists as DL                      # noqa: E402
import gen_prom_b_display_lists_v2 as V2               # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"
HTBL_B = 0x31DB1                                       # interpreter B's handler table
BITMAP_H = 0xF31ABE                                    # interpreter A's draw-bitmap handler

# The two `.incbin` directives this pass consumes: (file offset, length).
INCBINS = [(0x002FFE, 0x00002C), (0x013D34, 0x00002C)]

# The four bitmaps that tile 0xF13D00-0xF13D5F.  Addresses only: the sizes are
# re-derived from the records that name them, never written down here.
BITMAPS = [0xF13D00, 0xF13D18, 0xF13D30, 0xF13D48]
BITMAP_END = 0xF13D60          # anchored by the op/len walk, NOT by a call site

REC1 = 0xF02FF7                # the interpreter-B record whose +7 field the span cuts
TAB1 = 0xF03002                # the array it names
TAB1_END = 0xF0302A            # a proven interpreter-B display-list start

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-66s %-20s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


# --------------------------------------------------------------------------
def load():
    b = DL.load()[1]
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    htb = [int.from_bytes(b[HTBL_B + i * 4:HTBL_B + i * 4 + 4], "little") for i in range(15)]
    return b, hta, htb


def w16(b, a):
    return int.from_bytes(b[a - B_BASE:a - B_BASE + 2], "little")


def w32(b, a):
    return int.from_bytes(b[a - B_BASE:a - B_BASE + 4], "little")


def implied_len(h):
    """The record length interpreter B's handler `h` implies: one past the last
    byte any of its own instructions reads (V2.B_LAYOUT is the disassembly of
    each handler -- notes/FINDINGS-ui-display-list-interpreter-b.md)."""
    fields, _note = V2.B_LAYOUT[h]
    return max((off + w) for off, w, _n in fields) if fields else None


def a_bitmap_refs(b, hta, target):
    """Every interpreter-A op-0x03 record (handler 0xF31ABE, fixed 12 B) whose
    +2 pointer is `target`; returns (record address, BC, HL)."""
    out, pat = [], target.to_bytes(4, "little")
    o = 0
    while True:
        o = b.find(pat, o)
        if o < 0:
            break
        p = o - 2
        if p >= 0 and b[p] < 0x24 and hta[b[p]] == BITMAP_H and b[p + 1] == 12:
            out.append((B_BASE + p, int.from_bytes(b[p + 8:p + 10], "little"),
                        int.from_bytes(b[p + 10:p + 12], "little")))
        o += 1
    return out


def a_walk(b, hta, start, end):
    """A plain interpreter-A op/len walk from `start`: return (lands exactly on
    `end`, records consumed).  A record is accepted only if its opcode is in
    range AND its length byte equals its handler's implied length, so this is
    the length rule of notes/prom_b_dl_length_audit.py, not merely `op < bound`."""
    p, n = start, 0
    while p < end:
        op, ln = b[p - B_BASE], b[p - B_BASE + 1]
        if op >= 0x24 or ln == 0:
            return False, n
        fields, text_at = DL.HANDLERS[hta[op]]
        if text_at is None and fields and ln != max(o + w for o, w in fields):
            return False, n
        p += ln
        n += 1
    return p == end, n


def ptrs_into(lo, hi):
    """Every 32-bit little-endian word in ANY of the four WSA1R images whose
    value lands in [lo, hi).  The null for "nothing else names this object"."""
    out = []
    d = os.path.join(ROOT, "original_ROMs")
    for f in ("wsa1_prom_a.ic12", "wsa1_prom_b.ic13", "wsa1_prom_c.ic28", "wsa1_prom_d.bin"):
        raw = open(os.path.join(d, f), "rb").read()
        for o in range(len(raw) - 3):
            v = int.from_bytes(raw[o:o + 4], "little")
            if lo <= v < hi:
                out.append((f, o, v))
    return out


# --------------------------------------------------------------------------
def bitmap_rows(b, addr, w, h, column_major=True):
    o = addr - B_BASE
    rows = []
    for r in range(h):
        line = ""
        for c in range(w):
            by = b[o + (c * h + r if column_major else r * w + c)]
            line += "".join("#" if by >> (7 - k) & 1 else "." for k in range(8))
        rows.append(line)
    return rows


def edge_density(b, addr, w, h, column_major):
    o = addr - B_BASE
    g = [[(b[o + (c * h + r if column_major else r * w + c)] >> (7 - k)) & 1
          for c in range(w) for k in range(8)] for r in range(h)]
    n = t = 0
    for r in range(h):
        for c in range(w * 8):
            if c + 1 < w * 8:
                t += 1
                n += g[r][c] != g[r][c + 1]
            if r + 1 < h:
                t += 1
                n += g[r][c] != g[r + 1][c]
    return n / t


# --------------------------------------------------------------------------
def render_span1(b, htb):
    """0xF02FF7: the whole interpreter-B record, then its 5 x 8-byte array."""
    o = REC1 - B_BASE
    op, ln = b[o], b[o + 1]
    esz, n = 8, (TAB1_END - TAB1) // 8
    cap = (b[o + 4] >> (b[o + 5] & 7)) + 1
    out = []
    out.append("\n; ------------------------------------------------------------------\n")
    out.append("; DL_F02FF7 -- ONE interpreter-B display-list record, %d bytes, and the\n"
               "; %d-byte operand array it names.  Together they tile 0x%06X-0x%06X and\n"
               "; end on 0x%06X, the first byte of the interpreter-B display list below.\n"
               % (ln, TAB1_END - TAB1, REC1, TAB1_END - 1, TAB1_END))
    out.append(";\n")
    out.append("; ⚠ SUPERSEDES the round-1 header kept above, which gave this object 7\n"
               ";   bytes and said \"the extent is the reachability walk's, not the\n"
               ";   object's\".  The extent IS the object's.  Round 1 stopped at +0x07 --\n"
               ";   the record's own pointer FIELD -- so four bytes of the record went\n"
               ";   into the `.incbin` with the array behind it.  Its \"a linear decode\n"
               ";   runs 3 instructions and ends `retd 0x0500`\" was a decode of a record\n"
               ";   header; nothing calls or branches here.\n"
               ";   (lane res02f, 2026-09-02, notes/gen_res02f_spans.py)\n")
    out.append(";\n")
    out.append("; HOW THIS RECORD IS RUN.  0xF5BB93-0xF5BBA9 in UiPaint_Ordinals is\n"
               ";     ld XIY,0x00F02FED / ld XIX,0x00F02FF7 / call 0xF417F0  <- interpreter A\n"
               ";     ld XIY,0x00F02FF7 / call 0xF4181C                      <- THIS record\n"
               "; and T_F4181C is `jp 0xF31B57`, a jump straight into the op-0x03 handler,\n"
               "; so the record is handed to its handler with no opcode dispatch at all.\n"
               "; That also answers what UiPaint_Ordinals' own header records as open:\n"
               "; \"what thunk T_F4181C does with 0xF02FF7 after the last paint\".\n")
    out.append("; ------------------------------------------------------------------\n")
    out.append("DL_F02FF7:\t\t; renamed from Data_F02FF7 -- nothing referenced that label\n")
    out += V2.render_b(b, REC1, op, ln, htb)
    out.append("\n; ------------------------------------------------------------------\n")
    out.append("; DLTable_F03002 -- %d entries of %d bytes (%d bytes).\n"
               "; Referenced by the display-list record 0x%06X directly above, whose +0x07\n"
               "; pointer lands here and whose handler fixes the entry size: 0xF31B57 does\n"
               "; `sla 0x03,HL` on the extracted bit-field before `add XIX,XHL`, so the\n"
               "; entries are 8 bytes.  %d entries is the EXTENT (%d / %d); the record's\n"
               "; (mask >> shift) + 1 = %d is only an upper bound on the index.\n"
               % (n, esz, TAB1_END - TAB1, REC1, n, TAB1_END - TAB1, esz, cap))
    out.append("; The four words of the selected entry go to (0x2530), (0x2532), (0x2534),\n"
               "; (0x2536) = X0, Y0, X1, Y1 -- those four addresses are established in\n"
               "; notes/FINDINGS-display-controller.md by the clamp constants 319 and 239 --\n"
               "; and then `swi 7` runs with A = the record's +0x06 = 0x05.\n")
    out.append("; So X0 and X1 are the constant columns and Y0/Y1 are the stepping ones:\n"
               "; five extents 26 wide and 13 tall, 37 rows apart, all in the SAME x range\n"
               "; 8..34 that DL_F02FED (op 0x1B = LCD_Svc_1B_EraseRect, named in prom_a --\n"
               "; notes/FINDINGS-prom_b-graphics-veneers.md) clears over the whole y range\n"
               "; 0x49..0xC5 immediately before this record runs.  ⚠ What service 0x05\n"
               "; itself draws into that extent is NOT asserted here; the tree records it\n"
               "; as \"a rectangle is the obvious reading and is not asserted\"\n"
               "; (notes/FINDINGS-ui-display-list.md).  Entries [0] and [1] are identical,\n"
               "; exactly as in the sibling 5 x 8 arrays DLTable_F031C9/F031F1/F03219,\n"
               "; which three byte-identical op-0x03 records name from the list at\n"
               "; 0xF030E6.\n")
    out.append("; ------------------------------------------------------------------\n")
    out.append("DLTable_F03002:\n")
    for i in range(n):
        words = [w16(b, TAB1 + i * esz + j * 2) for j in range(4)]
        out.append("\t.short %s\t; [%d] X0=%d Y0=%d X1=%d Y1=%d\n"
                   % (", ".join("0x%04X" % x for x in words), i,
                      words[0], words[1], words[2], words[3]))
    return out


def render_span2(b, hta):
    """0xF13D34: the tail of the bitmap at 0xF13D30, then the one at 0xF13D48."""
    refs = {a: a_bitmap_refs(b, hta, a) for a in BITMAPS}
    out = []
    out.append("\n; ------------------------------------------------------------------\n")
    out.append("; 0x%06X-0x%06X -- the TAIL of the bitmap at 0x%06X and the WHOLE bitmap\n"
               "; at 0x%06X.  Four 16 x 12 bitmaps sit here back to back and tile\n"
               "; 0x%06X-0x%06X:\n"
               % (0xF13D34, 0xF13D5F, 0xF13D30, 0xF13D48, BITMAPS[0], BITMAP_END - 1))
    out.append(";\n")
    for a in BITMAPS:
        out.append(";   0x%06X  BC=%d HL=%d -> %d bytes, named by the op-0x03 record%s %s\n"
                   % (a, refs[a][0][1], refs[a][0][2], refs[a][0][1] * refs[a][0][2],
                      "" if len(refs[a]) == 1 else "s",
                      " ".join("0x%06X" % p for p, _c, _h in refs[a])))
    out.append(";\n")
    out.append("; Every one of those six records is `03 0C` -> handler 0xF31ABE, which\n"
               "; takes +2 = the pointer, +8 = BC = bytes per column and +0x0A = HL = rows\n"
               "; and issues `swi 7` fn 3 = draw bitmap, so each object is BC * HL bytes --\n"
               "; the rule lane promB5 proved for the op-0x03 bitmaps at 0xF283A7/0xF2843D.\n"
               "; All four are BC=2, HL=12 = 24 bytes; four of them land EXACTLY on\n"
               "; 0x%06X, the first byte of the interpreter-A display list below.\n" % BITMAP_END)
    out.append(";\n")
    out.append("; ⚠ 0x%06X IS NOT A CALL-SITE START -- nothing in the image passes it to\n"
               ";   an interpreter, as that list's own header says.  Its anchor is the\n"
               ";   op/len walk: 45 records from 0x%06X, every length byte equal to its\n"
               ";   handler's implied length, landing on 0xF13F1E with zero drift.  The\n"
               ";   same walk started at 0xF13D34, 0xF13D38, 0xF13D48 or 0xF13D5C fails on\n"
               ";   its FIRST record, which is the null for that anchor.\n"
               % (BITMAP_END, BITMAP_END))
    out.append(";\n")
    out.append("; ⚠ AND THE NULL FOR THE POINTER SCAN.  Six 32-bit words in prom_b land in\n"
               ";   0x%06X-0x%06X and all six are the +2 field of one of those records.\n"
               ";   Widen the window sixteen bytes DOWN and six MORE appear -- all in\n"
               ";   prom_a, all reading 0xF13CFF, and every one straddling three\n"
               ";   instructions (`link XIZ,0xffee` = `ee 0c ee ff`, `push XIX` = `3c`,\n"
               ";   `lda_d16 XIX,(0x2900)` = `f1 00 29 34`).  So a raw 4-byte pointer scan\n"
               ";   over code produces false positives at that rate, and the test used\n"
               ";   here is the RECORD test -- opcode < 0x24, handler 0xF31ABE, length\n"
               ";   byte 12 -- never the pointer value on its own.\n"
               % (BITMAPS[0], BITMAP_END - 1))
    out.append(";\n")
    out.append("; ⚠ SUPERSEDES the round-1 refusal kept above -- \"decodes as neither\n"
               ";   interpreter's records and is not a uniform fill\".  Both halves are\n"
               ";   true and neither is the point: these bytes are not records, they are\n"
               ";   the PICTURES that records draw.\n")
    out.append(";\n")
    out.append("; ⚠ THE SPAN STARTS FOUR BYTES INSIDE THE 0xF13D30 BITMAP, and this lane\n"
               ";   did NOT move that boundary.  0xF13D30-0xF13D33 is the last four bytes\n"
               ";   of the `.byte` run of Data_F139AB above, which\n"
               ";   notes/gen_prom_b_f0ea9f_module.py emits from its LAYOUT entry\n"
               ";   `(\"data\", 0xF139AB, 0x0389)` and whose `--checks` asserts that LAYOUT\n"
               ";   covers 0xF0EA9F-0xF13D33 exactly.  Closing the bitmap is a one-line\n"
               ";   change -- `LO, HI = 0xF0EA9F, 0xF13D34` in\n"
               ";   notes/prom_b_f0ea9f_layout.py becomes 0xF13D30, and that module's last\n"
               ";   LAYOUT size 0x0389 becomes 0x0385.\n")
    out.append(";\n")
    out.append(";   ⚠ AND THE FEAR THAT IT RE-RUNS THAT MODULE'S CODE WALK WAS MEASURED\n"
               ";     AND IS UNFOUNDED.  notes/res02f_f0ea9f_hi_shift_probe.py emits the\n"
               ";     module twice, with HI at 0xF13D34 and at 0xF13D30, and the two\n"
               ";     differ in exactly SIX lines -- all six being the four bytes\n"
               ";     themselves (21141 -> 21137 bytes, Data_F139AB 905 -> 901, its\n"
               ";     printable preview, and the last `.byte` line).  81 segments and 23\n"
               ";     unsplit `.byte` runs BOTH ways; not one label, instruction or\n"
               ";     boundary moves.  What is still unmeasured, and is the actual reason\n"
               ";     this stayed undone, is the FOUR other modules that import\n"
               ";     prom_b_f0ea9f_layout, and the module's own `--checks`, which the\n"
               ";     probe bypasses.  Neither is this lane's to change.\n")
    out.append(";\n")
    out.append("; BYTE ORDER: COLUMN-major, byte column c and row r at +c*12+r.  An\n"
               "; INFERENCE, and it changes no byte: the emitted bytes are the ROM's, in\n"
               "; ROM order, either way.  It is quantified as 4-neighbour edge density,\n"
               "; column-major against row-major:\n")
    for a in BITMAPS:
        bc, hl = refs[a][0][1], refs[a][0][2]
        out.append(";   0x%06X  %.3f column-major   %.3f row-major\n"
                   % (a, edge_density(b, a, bc, hl, True), edge_density(b, a, bc, hl, False)))
    out.append("; and column-major is the reading in which 0x%06X draws a closed circle.\n"
               % BITMAPS[0])
    out.append(";\n")
    out.append("; The four pictures, column-major.  The first two are outside this span\n"
               "; (they are inside Data_F139AB's `.byte` run above) and are drawn here\n"
               "; because they are the same object family and fix the reading:\n")
    for a in BITMAPS:
        bc, hl = refs[a][0][1], refs[a][0][2]
        out.append(";\n;   0x%06X:\n" % a)
        for line in bitmap_rows(b, a, bc, hl):
            out.append(";     %s\n" % line)
    out.append("; ------------------------------------------------------------------\n")

    # the 20 span-visible bytes of the 0xF13D30 bitmap: column 0 rows 4..11,
    # then the whole of column 1
    o = 0xF13D34 - B_BASE
    out.append("; 0xF13D30's column 0, rows 4..11 -- rows 0..3 are the last four bytes of\n"
               "; the `.byte` run above and are NOT relabelled here (see the ⚠ above).\n")
    out.append("\t.byte\t%s\t; F13D34  column 0, rows 4..11\n"
               % ", ".join("0x%02X" % x for x in b[o:o + 8]))
    out.append("\t.byte\t%s\t; F13D3C  column 1, rows 0..11\n"
               % ", ".join("0x%02X" % x for x in b[o + 8:o + 20]))
    out.append("Data_F13D48:\t\t; the 2 x 12 bitmap the record at 0x%06X draws\n"
               % refs[0xF13D48][0][0])
    o = 0xF13D48 - B_BASE
    out.append("\t.byte\t%s\t; F13D48  column 0, rows 0..11\n"
               % ", ".join("0x%02X" % x for x in b[o:o + 12]))
    out.append("\t.byte\t%s\t; F13D54  column 1, rows 0..11\n"
               % ", ".join("0x%02X" % x for x in b[o + 12:o + 24]))
    return out


# --------------------------------------------------------------------------
DIR_RE = re.compile(r'^\t\.(byte|short|long|ascii)\s+(.*?)(?:\t;.*)?$')


def assemble(text):
    """Re-read the generated directives back into bytes.  A cheap emitter check
    that runs before the real one (`make gate-wsa1`) and catches a wrong field
    width or a dropped operand at the point it is introduced."""
    out = bytearray()
    for ln in text.split("\n"):
        if ln.lstrip().startswith(";") or not ln.strip():
            continue
        m = DIR_RE.match(ln)
        if not m:
            if ln.split(";")[0].rstrip().endswith(":"):
                continue
            raise AssertionError("assemble(): cannot read %r" % ln)
        kind, body = m.group(1), m.group(2).strip()
        if kind == "ascii":
            lit = body[body.index('"') + 1:body.rindex('"')]
            out += lit.replace("\\\\", "\\").replace('\\"', '"').encode("latin-1")
        else:
            w = {"byte": 1, "short": 2, "long": 4}[kind]
            for tok in body.split(","):
                out += int(tok.strip(), 0).to_bytes(w, "little")
    return bytes(out)


# --------------------------------------------------------------------------
def census(path=None):
    """How many bytes inside the two spans are still `.incbin`?"""
    path = path or os.path.join(ROOT, S_FILE)
    src = open(path, "rb").read().decode("utf-8")
    pat = re.compile(r'^\t\.incbin "%s", (0x[0-9A-Fa-f]+), (0x[0-9A-Fa-f]+)$' % re.escape(ROM), re.M)
    got = {}
    for m in pat.finditer(src):
        off, ln = int(m.group(1), 0), int(m.group(2), 0)
        for lo, n in INCBINS:
            a1, b1 = max(off, lo), min(off + ln, lo + n)
            if b1 > a1:
                got[lo] = got.get(lo, 0) + (b1 - a1)
    return got


# --------------------------------------------------------------------------
def selftest(b, hta, htb):
    print("gen_res02f_spans.py --selftest")

    print(" span 1: the .incbin cuts an interpreter-B record at its +0x07 field")
    o = REC1 - B_BASE
    check("0x%06X opcode" % REC1, b[o], 3)
    check("0x%06X length byte" % REC1, b[o + 1], 11)
    check("HTBL_B[3] is the 8-byte-entry handler", "0x%06X" % htb[3], "0xF31B57")
    check("the length byte is the handler's implied length", b[o + 1], implied_len(htb[3]))
    check("the record's +0x07 pointer", "0x%06X" % w32(b, REC1 + 7), "0x%06X" % TAB1)
    check("the array starts where the record ends", REC1 + b[o + 1], TAB1)
    check("the `.incbin` starts at the record's +0x07", B_BASE + INCBINS[0][0], REC1 + 7)

    print(" span 1: the extent is 5 entries of 8 bytes, not the record's cap of 16")
    check("array extent", TAB1_END - TAB1, 40)
    check("extent is a whole number of 8-byte entries", (TAB1_END - TAB1) % 8, 0)
    check("(mask >> shift) + 1 allows at least 5", (b[o + 4] >> (b[o + 5] & 7)) + 1 >= 5, True)
    sites = DL.call_sites(*DL.load())
    starts = {s for s, _e, _t in sites}
    check("0x%06X is a proven display-list start" % TAB1_END, TAB1_END in starts, True)
    check("[0] and [1] are identical, as in DLTable_F031C9",
          b[TAB1 - B_BASE:TAB1 - B_BASE + 8], b[TAB1 - B_BASE + 8:TAB1 - B_BASE + 16])
    check("the sibling array 0xF031C9 is also 5 x 8 from an identical record",
          b[0xF030E6 - B_BASE:0xF030E6 - B_BASE + 7],
          b[REC1 - B_BASE:REC1 - B_BASE + 7])

    print(" span 2: four bitmaps, extent = BC*HL, and every record naming them agrees")
    prev = None
    for a in BITMAPS:
        refs = a_bitmap_refs(b, hta, a)
        check("0x%06X: at least one op-0x03 record names it" % a, len(refs) > 0, True)
        check("0x%06X: one (BC,HL) across all %d records" % (a, len(refs)),
              len({(c, h) for _p, c, h in refs}), 1)
        bc, hl = refs[0][1], refs[0][2]
        check("0x%06X: BC*HL" % a, bc * hl, 24)
        if prev is not None:
            check("0x%06X follows 0x%06X exactly" % (a, prev), prev + 24, a)
        prev = a
    check("the four tile up to 0x%06X" % BITMAP_END, BITMAPS[0] + 4 * 24, BITMAP_END)
    check("the `.incbin` starts 4 bytes inside the 0x%06X bitmap" % BITMAPS[2],
          B_BASE + INCBINS[1][0] - BITMAPS[2], 4)
    check("the `.incbin` ends on 0x%06X" % BITMAP_END,
          B_BASE + INCBINS[1][0] + INCBINS[1][1], BITMAP_END)

    print(" span 2: 0x%06X is where the display list below starts -- and it is the"
          % BITMAP_END)
    print("         ONLY start in the span for which that is true (the null)")
    # ⚠ 0xF13D60 is NOT a call-site start: nothing in the image passes it to an
    # interpreter (the source's own header says so).  Its anchor is the op/len
    # walk -- 45 records, every length byte equal to its handler's implied
    # length, landing on 0xF13F1E with zero drift -- and no other start in the
    # span produces a walk at all.
    check("0x%06X is NOT reached by any known call shape" % BITMAP_END,
          BITMAP_END in starts, False)
    check("op/len walk 0x%06X -> 0xF13F1E" % BITMAP_END, a_walk(b, hta, BITMAP_END, 0xF13F1E),
          (True, 45))
    for s in (0xF13D34, 0xF13D38, 0xF13D48, 0xF13D5C):
        check("  ... and NOT from 0x%06X" % s, a_walk(b, hta, s, 0xF13F1E)[0], False)

    print(" span 2: NOTHING else in any of the four images names these four objects")
    named = {p for a in BITMAPS for p, _c, _h in a_bitmap_refs(b, hta, a)}
    found = ptrs_into(BITMAPS[0], BITMAP_END)
    check("32-bit words landing in 0x%06X-0x%06X" % (BITMAPS[0], BITMAP_END - 1),
          len(found), len(named))
    check("all of them are the +2 field of one of those records",
          sorted({B_BASE + o - 2 for f, o, _v in found if f == "wsa1_prom_b.ic13"}),
          sorted(named))
    # ⚠ THE NULL FOR THE SCAN ITSELF.  Widen the window by sixteen bytes below
    # the first bitmap and six MORE words appear, all in prom_a and all reading
    # 0xF13CFF -- one byte below 0xF13D00.  Every one straddles three
    # instructions (`link XIZ,0xffee` = `ee 0c ee ff`, `push XIX` = `3c`,
    # `lda_d16 XIX,(0x2900)` = `f1 00 29 34`), so a raw 4-byte scan over code
    # DOES produce false positives at this rate.  That is why the test above is
    # the record test -- opcode < 0x24, handler == 0xF31ABE, length byte == 12 --
    # and not the pointer value alone.
    wide = ptrs_into(0xF13CF0, BITMAP_END)
    check("widening the window 16 B down adds prom_a false positives",
          len(wide) - len(found), 6)
    check("  ... and every one of them reads 0xF13CFF, not a bitmap address",
          sorted({v for f, _o, v in wide if f == "wsa1_prom_a.ic12"}), [0xF13CFF])

    print(" span 2: column-major is the lower-edge-density reading, on all four")
    for a in BITMAPS:
        refs = a_bitmap_refs(b, hta, a)
        bc, hl = refs[0][1], refs[0][2]
        check("0x%06X: col-major %.3f < row-major %.3f"
              % (a, edge_density(b, a, bc, hl, True), edge_density(b, a, bc, hl, False)),
              edge_density(b, a, bc, hl, True) < edge_density(b, a, bc, hl, False), True)

    print(" the emitted text re-assembles to the ROM's own bytes")
    t1 = "".join(render_span1(b, htb))
    check("0x%06X-0x%06X round-trips" % (REC1, TAB1_END - 1), assemble(t1),
          b[REC1 - B_BASE:TAB1_END - B_BASE])
    t2 = "".join(render_span2(b, hta))
    check("0x%06X-0x%06X round-trips" % (0xF13D34, BITMAP_END - 1), assemble(t2),
          b[0xF13D34 - B_BASE:BITMAP_END - B_BASE])

    print(" no byte of either span is emitted as an instruction")
    bad = [ln for ln in (t1 + t2).split("\n")
           if ln.startswith("\t") and not ln.lstrip().startswith(".")]
    check("non-directive lines in the emitted text", len(bad), 0)

    print("FAILURES: %d" % len(FAIL))
    return 1 if FAIL else 0


# --------------------------------------------------------------------------
def splice(b, hta, htb):
    path = os.path.join(ROOT, S_FILE)
    # ⚠ prom_b/wsa1_prom_b.s is UTF-8, not latin-1: it already carries ⚠ and ★ in
    # its headers.  Checked, not assumed -- selftest asserts it decodes as UTF-8.
    src = open(path, "rb").read().decode("utf-8")
    lines = src.split("\n")

    # --- span 1 -----------------------------------------------------------
    # The round-1 header is WRONG about the extent, but it is not deleted: it
    # is kept verbatim, fenced and quoted with "; |", and superseded below.
    anchor = "; Data_F02FF7 -- 7 bytes, EMITTED AS DATA (not promoted to code)."
    h = [i for i, t in enumerate(lines) if t == anchor]
    if len(h) != 1:
        raise SystemExit("span 1: expected 1 round-1 header, found %d" % len(h))
    start = h[0] - 1
    if not lines[start].startswith("; ----"):
        raise SystemExit("span 1: header does not open with a divider")
    target = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, INCBINS[0][0], INCBINS[0][1])
    idx = [i for i, t in enumerate(lines) if t == target]
    if len(idx) != 1:
        raise SystemExit("span 1: expected 1 matching .incbin, found %d" % len(idx))
    end = idx[0]
    old = [t for t in lines[start:end] if t.strip()]
    block = ([""] +
             ["; ==== round-1 header, KEPT VERBATIM and SUPERSEDED below "
              "(lane res02f, 2026-09-02) ===="] +
             ["; | %s" % t.rstrip() for t in old] +
             ["; ==== end of the superseded round-1 header ===="] +
             "".join(render_span1(b, htb)).rstrip("\n").split("\n"))
    lines = lines[:start] + block + lines[end + 1:]

    # --- span 2 -----------------------------------------------------------
    target = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, INCBINS[1][0], INCBINS[1][1])
    idx = [i for i, t in enumerate(lines) if t == target]
    if len(idx) != 1:
        raise SystemExit("span 2: expected 1 matching .incbin, found %d" % len(idx))
    lines = (lines[:idx[0]] +
             "".join(render_span2(b, hta)).rstrip("\n").split("\n") +
             lines[idx[0] + 1:])

    # --- the stale round-1 markers ---------------------------------------
    # Three "not converted" markers name spans that start at 0xF13D34.  All
    # three are now false: the only `.incbin` between 0xF13D34 and 0xF147AB was
    # the one this pass consumed.  They are amended in place, not deleted.
    MARKERS = {
        "; --- 0xF13D34-0xF13D5F: not converted -- decodes as neither interpreter's "
        "records and is not a uniform fill ---":
            "; --- 0xF13D34-0xF13D5F: CONVERTED 2026-09-02, lane res02f "
            "(notes/gen_res02f_spans.py).  The round-1 reason -- \"decodes as neither\n"
            "; interpreter's records and is not a uniform fill\" -- was true and beside "
            "the point: these are the PICTURES records draw. ---",
        "; --- 0xF13D34-0xF13F1D: not converted ---":
            "; --- 0xF13D34-0xF13F1D: CONVERTED.  0xF13D34-0xF13D5F by lane res02f "
            "2026-09-02\n; (notes/gen_res02f_spans.py); 0xF13D60-0xF13F1D was already "
            "the display list below. ---",
        "; --- 0xF13D34-0xF147AB: not converted ---":
            "; --- 0xF13D34-0xF147AB: CONVERTED.  0xF13D34-0xF13D5F by lane res02f "
            "2026-09-02\n; (notes/gen_res02f_spans.py) was the last `.incbin` anywhere "
            "in this range. ---",
    }
    for stale, new in MARKERS.items():
        n = sum(1 for t in lines if t == stale)
        if n != 1:
            raise SystemExit("expected 1 %r, found %d" % (stale[:60], n))
        lines = [x for t in lines for x in (new.split("\n") if t == stale else [t])]

    # --- the COVER-R1 band header over span 1 -----------------------------
    anchor = "; === COVER-R1 0xF02FF7-0xF0302A ==="
    i = [k for k, t in enumerate(lines) if t == anchor]
    if len(i) != 1:
        raise SystemExit("expected 1 %r, found %d" % (anchor, len(i)))
    note = ("; ⚠ AMENDED 2026-09-02 (lane res02f, notes/gen_res02f_spans.py).  The 44 B\n"
            "; this band left `.incbin` are now typed data: four of them are the +0x07\n"
            "; POINTER FIELD of the record round 1 typed as Data_F02FF7, and the other 40\n"
            "; are the 5 x 8-byte operand array that pointer names.  Round 1 reached the\n"
            "; record's first byte and stopped 4 bytes short of its end; the handler that\n"
            "; consumes the pointer, 0xF31B57, fixes both the record's length and the\n"
            "; array's entry size.  This band is now at ZERO `.incbin` bytes.")
    lines = lines[:i[0] + 1] + note.split("\n") + lines[i[0] + 1:]

    out = "\n".join(lines)
    tmp = path + ".tmp%d" % os.getpid()
    with open(tmp, "wb") as fh:
        fh.write(out.encode("utf-8"))
    os.replace(tmp, path)
    print("spliced; %d -> %d characters of source" % (len(src), len(out)))
    return 0


# --------------------------------------------------------------------------
# The gate-visibility proof, reproducible.  A gate that was never shown to fail
# on this lane's own bytes certifies nothing, so this perturbs ONE byte each
# lane emitted -- one per span -- rebuilds, and expects `assert_byte_identical`
# to name that exact address.  It restores the source whatever happens.
FALSIFY = [
    # (line as emitted, line with one byte changed, the address the gate must name)
    ("\t.short 0x0008, 0x006E, 0x0022, 0x007B\t; [2] X0=8 Y0=110 X1=34 Y1=123",
     "\t.short 0x0008, 0x006F, 0x0022, 0x007B\t; [2] X0=8 Y0=110 X1=34 Y1=123",
     0x003014),
    ("\t.byte\t0x00, 0x00, 0x00, 0x00, 0x1C, 0xFF, 0x1C, 0x00, 0x00, 0x00, 0x00, 0x00"
     "\t; F13D54  column 1, rows 0..11",
     "\t.byte\t0x00, 0x00, 0x00, 0x00, 0x1C, 0xFE, 0x1C, 0x00, 0x00, 0x00, 0x00, 0x00"
     "\t; F13D54  column 1, rows 0..11",
     0x013D59),
]


def falsify():
    import subprocess
    path = os.path.join(ROOT, S_FILE)
    orig = open(path, "rb").read()
    rc = 0
    try:
        for good, bad, addr in FALSIFY:
            src = orig.decode("utf-8")
            if src.count(good) != 1:
                print("  SKIP: %d matches for the emitted line at 0x%06X"
                      % (src.count(good), addr))
                rc = 1
                continue
            open(path, "wb").write(src.replace(good, bad).encode("utf-8"))
            out = subprocess.run(["make", "-C", os.path.dirname(ROOT), "gate-wsa1"],
                                 capture_output=True, text=True).stdout
            want = "first at 0x%X" % addr
            ok = want in out
            print("  perturb -> gate names %s : %s" % (want, "RED, OK" if ok else "NOT SEEN"))
            if not ok:
                print(out)
                rc = 1
    finally:
        open(path, "wb").write(orig)
        print("  source restored (%d bytes)" % len(orig))
    return rc


# --------------------------------------------------------------------------
def main():
    b, hta, htb = load()
    if "--selftest" in sys.argv:
        return selftest(b, hta, htb)
    if "--census" in sys.argv:
        j = sys.argv.index("--census")
        path = sys.argv[j + 1] if len(sys.argv) > j + 1 else None
        got, tot = census(path), 0
        for lo, n in INCBINS:
            got_n = got.get(lo, 0)
            tot += got_n
            print("  0x%06X-0x%06X  %3d B span, %3d B still .incbin"
                  % (B_BASE + lo, B_BASE + lo + n - 1, n, got_n))
        print("  TOTAL still .incbin in lane res02f's two spans: %d B" % tot)
        return 0
    if "--render" in sys.argv:
        for a in BITMAPS:
            refs = a_bitmap_refs(b, hta, a)
            bc, hl = refs[0][1], refs[0][2]
            print("=== 0x%06X  BC=%d HL=%d  col-major ed=%.3f  row-major ed=%.3f"
                  % (a, bc, hl, edge_density(b, a, bc, hl, True),
                     edge_density(b, a, bc, hl, False)))
            cm, rm = bitmap_rows(b, a, bc, hl, True), bitmap_rows(b, a, bc, hl, False)
            for i in range(hl):
                print("   %s    %s" % (cm[i], rm[i]))
        return 0
    if "--asm" in sys.argv:
        sys.stdout.write("".join(render_span1(b, htb)))
        sys.stdout.write("".join(render_span2(b, hta)))
        return 0
    if "--splice" in sys.argv:
        return splice(b, hta, htb)
    if "--falsify" in sys.argv:
        return falsify()
    print(__doc__.strip().split("RUN")[-1])
    return 1


if __name__ == "__main__":
    sys.exit(main())
