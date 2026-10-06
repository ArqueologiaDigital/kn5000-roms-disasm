#!/usr/bin/env python3
"""gen_prom_b_res3xx_spans.py -- convert five of prom_b's last sixteen
`.incbin` spans (106 bytes) into typed display-list source, and prove every
record boundary from OUTSIDE the bytes.

    python3 notes/gen_prom_b_res3xx_spans.py --selftest   # assert every claim
    python3 notes/gen_prom_b_res3xx_spans.py --emit       # print the assembly
    python3 notes/gen_prom_b_res3xx_spans.py --splice     # apply to the .s

Run from the `wsa1/` directory.

QUESTION THIS ANSWERS
----------------------
notes/FINDINGS-prom_b-last-481-bytes.md established that all sixteen residue
spans are DATA, and warned that typing them from a stride read off the bytes
is the "wrong start frames fake records" hazard: the byte gate cannot object,
because ANY framing of the right bytes rebuilds the ROM byte-for-byte.

So the question this script answers is not "what shape fits" but "what fixes
the boundary from outside the span". For each of the five spans the answer is
one of exactly three kinds of external fact, and the script asserts it against
the ROM:

  (1) a `ld XIY,imm32` / `ld XIX,imm32` in converted CODE that hands the
      address straight to the interpreter or to one handler;
  (2) a framed NEIGHBOURING record whose +7 pointer, +0x0B entry width and
      (mask >> shift) + 1 entry bound name the object and fix its size;
  (3) an already-framed display-list start on the far side, so the tiling has
      to close with no slack.

THE HANDLER-IMPLIED LENGTHS ARE READ OFF THE HANDLERS
-----------------------------------------------------
Interpreter B is 0xF31AF0. Its loop advances by the byte at record +1
(`ld A,(XIY+0x01)` at 0xF31B15, then `add XIY,XWA`), so +1 is the ADVANCE for
every opcode. The DATA EXTENT of a record is a separate thing: the highest
byte its handler touches, plus one. Both matter, and for one record in this
lane they disagree -- see SPAN 5.

    op 00/06  handler 0xF31BA1  extent 10   reads +2,+4,+5 (via 0xF31CC5),
                                            +6, +7..+8 (IX), +9 (digit count)
    op 02     handler 0xF31B21  extent 15   +7..+0x0A long, +0x0B width,
                                            +0x0D..+0x0E -> IX
    op 03/08  handler 0xF31B57  extent 11   +6, +7..+0x0A long; entries are
                                            8 bytes (`sla 0x03,HL`, then
                                            (XIX+0/2/4/6))
    op 07     handler 0xF31B39  extent 17   as op 02 plus +0x0F..+0x10

THE FIVE SPANS
---------------
SPAN 1  0xF286CC +45  ->  0xF286A2-0xF286F8, 3 records + 3 string tables
    The framed opcode-07 record at 0xF28468 carries `.long 0x00F28522`,
    width 3 and mask 0x7F: its table is 128 x 3 = 384 B and ends at
    0xF286A1. `Data_F28522` was declared 426 B -- 42 too many. The far end
    is ModeScreen_PaintDirtyFields2_DL1, an established list start. The 87 bytes between tile as
    17 + 24 + 17 + 6 + 17 + 6 with no slack, each record's +7 pointing at
    the byte immediately after itself.
    (Lane promB5 reported this as "one byte too long", measuring against the
    `.incbin` edge rather than against the table the record declares. The
    direction was right; the number is 42.)

SPAN 2  0xF32A00 +9   ->  0xF329FA-0xF32A08, 1 opcode-02 record
    Entries 1 and 2 of the LE32 pointer array at 0xF32A36 hold 0x00F329FA,
    and entry 3 holds 0x00F32A09 -- an already-framed record start. That
    array is indexed by 0xF09AE1, which does `XIY = (XIY + i*4)` and calls
    T_F41830 -> 0xF31AEC `DisplayListB_RunOne`, i.e. it runs exactly ONE
    record at the loaded address. So 0xF329FA is a record start named by
    code, and `Data_F32992` was 6 bytes too long.

SPAN 3  0xF34350 +17  ->  0xF3434C-0xF34360, 1 opcode-02 record + its table
    prom_b 0xF55CA6 and 0xF55D57 do `ld XIY,0x00f3434c` and reach
    T_F417F8 -> 0xF31B21, the opcode-02 handler, with that XIY. The record
    is therefore 15 bytes and its +7 table starts at 0xF3435B. The far end
    is RealtimeRecordScreen_DrawValues_DL, whose start is `ld XIY,0x00f34361` at 0xF55D45.

SPAN 4  0xF3A443 +30  ->  0xF3A43E-0xF3A460, 1 opcode-08 record + its table
    prom_b 0xF7E775 does `ld XIY,0x00f3a43e` / `call 0xf41820`, and
    T_DLB_Handler_Array8_2 is `jp 0xF31B57` -- the opcode-03/08 handler. Its neighbour
    0xF3A433 is handed to the same handler from 0xF7E77E. Both carry
    `.long 0x00F3A449`; the handler's entries are 8 bytes; the far end is
    DL_F3A461 (`ld XIY,0x00f3a461`, 7 sites), so the table is exactly 3
    entries.

SPAN 5  0xF3B656 +5   ->  0xF3B651-0xF3B65A, 1 opcode-00 record
    ⚠ THE OPEN QUESTION, SETTLED FROM THE HANDLER. Lane promB6 asked:
    either op 0x00 does not carry its length at +1, or DL_F3B65B's start is
    off by one. NEITHER. Op 0x00 does carry its advance at +1 -- the
    interpreter reads +1 for every opcode, unconditionally. And 0xF3B65B is
    not off by one: prom_b 0xF7E79E passes it as XIX, the list's exclusive
    end, in the same breath as `ld XIY,0x00f3b651`.
    The reconciliation is that ADVANCE and EXTENT are different numbers.
    Handler 0xF31BA1's highest read is +9, so this record's data extent is
    10 bytes, 0xF3B651-0xF3B65A. Its advance byte says 11. It is the only
    record in the image whose advance over-declares, and the over-
    declaration is inert: XIY lands on 0xF3B65C, past XIX = 0xF3B65B, and
    the loop test `cp XIX,XIY / jr ULE` ends the list. The machine draws the
    record and stops. Independently, 0xF3B651 is the XIX -- the exclusive
    end -- of the interpreter-A call at 0xF7E8C3, so both of this record's
    edges are immediates in code.

WHAT THE BYTE GATE DOES AND DOES NOT CERTIFY
---------------------------------------------
`make gate-wsa1` proves the emitted bytes equal the dump. It cannot tell a
true record boundary from a false one. Everything above is the part the gate
cannot check, which is why it is asserted here instead.
"""

import os
import sys

ROM = "original_ROMs/wsa1_prom_b.ic13"
SRC = "prom_b/wsa1_prom_b.s"
BASE = 0xF00000

# Interpreter-B handler -> (data extent, comment tail used in this tree)
HANDLER = {
    0x00: (0xF31BA1, 10, "decimal readout, unsigned (0xF8BCAF via T_F41AF0)"),
    0x02: (0xF31B21, 15, "string-table readout: HL = extracted value = entry index"),
    0x03: (0xF31B57, 11, "four words of entry[value] -> (0x2530..0x2536)"),
    0x07: (0xF31B39, 17, "string-table readout with two extra words"),
    0x08: (0xF31B57, 11, "four words of entry[value] -> (0x2530..0x2536)"),
}


def rom():
    with open(ROM, "rb") as f:
        return f.read()


def u16(d, a):
    return d[a - BASE] | (d[a - BASE + 1] << 8)


def u32(d, a):
    return u16(d, a) | (u16(d, a + 2) << 16)


def rec(d, a):
    """Decode one interpreter-B record header at CPU address `a`."""
    o = a - BASE
    return {
        "addr": a, "op": d[o], "adv": d[o + 1], "var": u16(d, a + 2),
        "mask": d[o + 4], "shift": d[o + 5], "func": d[o + 6],
        "ptr": u32(d, a + 7), "width": u16(d, a + 11),
    }


def emit_record(d, a, ptr_note):
    """Render one interpreter-B record as this tree renders them."""
    r = rec(d, a)
    handler, extent, tail = HANDLER[r["op"]]
    if r["adv"] == extent:
        size = "%d bytes" % extent
    else:
        # The interpreter advances by +1 regardless of opcode; the handler's
        # highest read is what the record actually OCCUPIES.  They differ once
        # in this image -- see SPAN 5 in the module docstring.
        size = "%d bytes of data, advance byte says %d" % (extent, r["adv"])
    out = ["\t.byte 0x%02X, 0x%02X\t; B op %02X, %s -> handler 0x%06X -- %s"
           % (r["op"], r["adv"], r["op"], size, handler, tail)]
    out.append("\t.short 0x%04X\t; +0x02 source variable, 16-bit address" % r["var"])
    out.append("\t.byte 0x%02X\t; +0x04 AND mask" % r["mask"])
    out.append("\t.byte 0x%02X\t; +0x05 right shift, low 3 bits" % r["shift"])
    out.append("\t.byte 0x%02X\t; +0x06 swi 7 function" % r["func"])
    if r["op"] == 0x00:
        out.append("\t.short 0x%04X\t; +0x07 -> IX" % u16(d, a + 7))
        out.append("\t.byte 0x%02X\t; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663"
                   % d[a - BASE + 9])
    elif r["op"] in (0x03, 0x08):
        out.append("\t.long 0x%08X\t; +0x07 -> XIX: %s" % (r["ptr"], ptr_note))
    else:
        out.append("\t.long 0x%08X\t; +0x07 -> XIY: %s" % (r["ptr"], ptr_note))
        out.append("\t.short 0x%04X\t; +0x0B -> BC: bytes per entry" % r["width"])
        if r["op"] == 0x02:
            out.append("\t.short 0x%04X\t; +0x0D -> IX" % u16(d, a + 13))
        else:
            out.append("\t.short 0x%04X\t; +0x0D -> (0x2530)" % u16(d, a + 13))
            out.append("\t.short 0x%04X\t; +0x0F -> (0x2532)" % u16(d, a + 15))
    return out


def emit_ascii_table(d, a, n, width, label, ref, why):
    out = ["; ------------------------------------------------------------------",
           "; %s -- %d entries of %d bytes (%d bytes)." % (label, n, width, n * width),
           "; Referenced by interpreter-B display-list record 0x%06X, whose +7" % ref,
           "; pointer lands here and whose handler fixes the entry size.  %s" % why,
           "; ------------------------------------------------------------------",
           "%s:" % label]
    for i in range(n):
        s = d[a - BASE + i * width: a - BASE + (i + 1) * width].decode("latin-1")
        assert all(0x20 <= ord(c) < 0x7F for c in s), (label, i, s)
        out.append('\t.ascii "%s"\t; [%d]' % (s, i))
    return out


def emit_word_table(d, a, n, per, label, ref, why):
    out = ["; ------------------------------------------------------------------",
           "; %s -- %d entries of %d bytes (%d bytes)." % (label, n, per * 2, n * per * 2),
           "; Referenced by interpreter-B display-list record 0x%06X, whose +7" % ref,
           "; pointer lands here and whose handler fixes the entry size.  %s" % why,
           "; ------------------------------------------------------------------",
           "%s:" % label]
    for i in range(n):
        ws = [u16(d, a + (i * per + j) * 2) for j in range(per)]
        out.append("\t.short " + ", ".join("0x%04X" % w for w in ws) + "\t; [%d]" % i)
    return out


# --------------------------------------------------------------------------
# The five blocks.  Each returns (old_text, new_text) for prom_b/wsa1_prom_b.s
# --------------------------------------------------------------------------

def block1(d):
    hdr = """
; ------------------------------------------------------------------
; 0xF286A2-0xF286F8 -- 3 display-list records and their 3 string tables,
; 87 bytes -- interpreter B.  Formerly the last 42 bytes of Data_F28522
; plus the 45-byte `.incbin` that followed it.
;
; BOTH ENDS ARE FIXED FROM OUTSIDE THE BYTES, not from a stride read off
; them:
;   * LEFT -- the framed opcode-07 record at 0xF28468 carries
;     `.long 0x00F28522`, `BC = 3` (bytes per entry) and mask 0x7F, so the
;     string table it names is 128 x 3 = 384 bytes and ENDS at 0xF286A1.
;   * RIGHT -- ModeScreen_PaintDirtyFields2_DL1 is an established display-list start (prom_a call
;     site 0xF90FBB, notes/prom_b_dl_call_shapes.py).
; In between, each record's own +7 pointer lands on the byte immediately
; after that record, and (mask >> shift) + 1 entries of the +0x0B width
; run exactly up to the next record:
;     0xF286A2 + 17 + 24 + 17 + 6 + 17 + 6 = 0xF286F9, no slack anywhere.
;
; This is the neighbourhood notes/FINDINGS-ui-display-list-interpreter-b.md
; already described as `record, its table, record, its table` while it was
; still `.incbin`.  The layout below is that description, emitted.
; Verify: python3 notes/gen_prom_b_res3xx_spans.py --selftest
; ------------------------------------------------------------------
C0mbinati0nM0de_RepaintPage1Fields_DL:"""
    out = hdr.split("\n")
    out += emit_record(d, 0xF286A2, "string table")
    out.append("")
    out += emit_ascii_table(d, 0xF286B3, 8, 3, "DLTable_F286B3", 0xF286A2,
                            "8 entries is both\n; the EXTENT (24 / 3) and the record's (mask >> shift) + 1 bound.")
    out.append("")
    out.append("DL_F286CB:")
    out += emit_record(d, 0xF286CB, "string table")
    out.append("")
    out += emit_ascii_table(d, 0xF286DC, 2, 3, "DLTable_F286DC", 0xF286CB,
                            "2 entries is both\n; the EXTENT (6 / 3) and the record's (mask >> shift) + 1 bound.")
    out.append("")
    out.append("DL_F286E2:")
    out += emit_record(d, 0xF286E2, "string table")
    out.append("")
    out += emit_ascii_table(d, 0xF286F3, 2, 3, "DLTable_F286F3", 0xF286E2,
                            "2 entries is both\n; the EXTENT (6 / 3) and the record's (mask >> shift) + 1 bound.")
    out.append("")

    old = ("\t.byte\t0x07, 0x11, 0x45, 0x26, 0x07, 0x00, 0x17, 0xB3, 0x86, 0xF2, "
           "0x00, 0x03, 0x00, 0x23, 0x01, 0xE2\t; F286A2  |..E&.........#..|\n"
           "\t.byte\t0x00, 0x50, 0x54, 0x31, 0x50, 0x54, 0x32, 0x50, 0x54, 0x33, "
           "0x50, 0x54, 0x34, 0x50, 0x54, 0x35\t; F286B2  |.PT1PT2PT3PT4PT5|\n"
           "\t.byte\t0x50, 0x54, 0x36, 0x50, 0x54, 0x37, 0x50, 0x54, 0x38, 0x07"
           "\t; F286C2  |PT6PT7PT8.|\n"
           "\n"
           '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0286CC, 0x00002D\n')
    return old, "\n".join(out) + "\n"


def block2(d):
    out = ["",
           "; ------------------------------------------------------------------",
           "; 0xF329FA-0xF32A08 -- 1 display-list record, 15 bytes -- interpreter B.",
           "; Formerly the last 6 bytes of Data_F32992 plus the 9-byte `.incbin`",
           "; that followed it.",
           ";",
           "; THE START IS NAMED BY CODE, not by a stride: entries 1 and 2 of the",
           "; LE32 pointer array at 0xF32A36 hold 0x00F329FA (entry 3 holds",
           "; 0x00F32A09, the record run framed just below).  0xF09AE1 indexes that",
           "; array -- `sla 0x02,WA / add XIY,XWA / ld XIY,(XIY)` -- and calls",
           "; T_F41830 -> 0xF31AEC DisplayListB_RunOne, which sets XIX = XIY + 1 and",
           "; so runs EXACTLY ONE record at the loaded address.  prom_b 0xF5D488",
           "; loads that array (`ld XIY,0x00f32a36`).",
           "; The record's 15-byte extent is handler 0xF31B21's, and it ends exactly",
           "; on 0xF32A09.  Verify: python3 notes/gen_prom_b_res3xx_spans.py --selftest",
           "; ------------------------------------------------------------------",
           "DL_F329FA:"]
    out += emit_record(d, 0xF329FA, "string table")
    out.append("")

    old = ("\t.byte\t0xA6, 0x29, 0xF3, 0x00, 0xB0, 0x29, 0xF3, 0x00, 0x02, 0x0F, "
           "0xA8, 0x27, 0x80, 0x07\t; F329F2  |.)...).....'..|\n"
           "\n"
           "\t\n"
           "; --- 0xF32A00-0xF32A08: not converted -- decodes as neither interpreter's "
           "records and is not a uniform fill ---\n"
           '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x032A00, 0x000009\n')
    new = ("\t.byte\t0xA6, 0x29, 0xF3, 0x00, 0xB0, 0x29, 0xF3, 0x00"
           "\t; F329F2  |.)...)..|\n" + "\n".join(out) + "\n")
    return old, new


def block3(d):
    out = ["",
           "; ------------------------------------------------------------------",
           "; 0xF3434C-0xF34360 -- 1 display-list record and its string table,",
           "; 21 bytes -- interpreter B.  Formerly Data_F3434C (4 bytes) plus the",
           "; 17-byte `.incbin` that followed it.",
           ";",
           "; THE START IS NAMED BY CODE: prom_b 0xF55CA6 and 0xF55D57 both do",
           "; `ld XIY,0x00f3434c`, then reach T_F417F8 -> 0xF31B21 -- the opcode-02",
           "; handler itself -- with that XIY (via SeqScreen_DrawCountInMeasure).  So this address is",
           "; a record start on the firmware's own say-so, and the handler fixes the",
           "; extent at 15 bytes.  Its +7 lands on 0xF3435B, the byte right after it.",
           "; THE END IS NAMED BY CODE TOO: RealtimeRecordScreen_DrawValues_DL is `ld XIY,0x00f34361` at",
           "; prom_b 0xF55D45, so the table is exactly 2 entries of 3 bytes.",
           "; Verify: python3 notes/gen_prom_b_res3xx_spans.py --selftest",
           "; ------------------------------------------------------------------",
           "DL_F3434C:"]
    out += emit_record(d, 0xF3434C, "string table")
    out.append("")
    out += emit_ascii_table(d, 0xF3435B, 2, 3, "DLTable_F3435B", 0xF3434C,
                            "2 entries is the\n; EXTENT (6 / 3), bounded by RealtimeRecordScreen_DrawValues_DL; the record's mask 0xFF would\n; allow up to 256.")
    out.append("")

    old = ("Data_F3434C:\n"
           "\t.byte\t0x02, 0x0F, 0xF6, 0x12\t; F3434C  |....|\n"
           "\n"
           '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x034350, 0x000011\n')
    return old, "\n".join(out) + "\n"


def block4(d):
    out = ["",
           "; ------------------------------------------------------------------",
           "; 0xF3A43E-0xF3A460 -- 1 display-list record and its parameter array,",
           "; 35 bytes -- interpreter B.  Formerly Data_F3A43E (5 bytes) plus the",
           "; 30-byte `.incbin` that followed it.",
           ";",
           "; THE START IS NAMED BY CODE: prom_b 0xF7E775 does",
           "; `ld XIY,0x00f3a43e` / `call 0xf41820`, and T_DLB_Handler_Array8_2 is `jp 0xF31B57`,",
           "; the opcode-03/08 handler -- the record is handed to its handler",
           "; directly, with no interpreter loop to mis-frame it.  Its neighbour",
           "; Data_F3A433 goes to the same handler from 0xF7E77E.",
           "; BOTH records carry `.long 0x00F3A449`; handler 0xF31B57 does",
           "; `sla 0x03,HL` and reads (XIX+0/2/4/6), so entries are 8 bytes.",
           "; THE END is DL_F3A461, a display-list start loaded by 7 `ld XIY`",
           "; sites, so the array is exactly 3 entries.",
           "; Verify: python3 notes/gen_prom_b_res3xx_spans.py --selftest",
           "; ------------------------------------------------------------------",
           "TrackAssignPresets_MoveFieldHighlight_DL:"]
    out += emit_record(d, 0xF3A43E, "array of 8-byte entries, indexed by the value")
    out.append("")
    out += emit_word_table(d, 0xF3A449, 3, 4, "DLTable_F3A449", 0xF3A43E,
                           "3 entries is the\n; EXTENT (24 / 8), bounded by DL_F3A461; the records' mask 0xFF would\n; allow up to 256.  Records 0xF3A433 and 0xF3A43E share this array.")
    out.append("")

    old = ("Data_F3A43E:\n"
           "\t.byte\t0x08, 0x0B, 0xF8, 0x12, 0xFF\t; F3A43E  |.....|\n"
           "\n"
           '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03A443, 0x00001E\n')
    return old, "\n".join(out) + "\n"


def block5(d):
    out = ["",
           "; ------------------------------------------------------------------",
           "; 0xF3B651-0xF3B65A -- 1 display-list record, 10 bytes -- interpreter B.",
           "; Formerly Data_F3B651 (5 bytes) plus the 5-byte `.incbin` after it.",
           ";",
           "; ⚠ THE ONE RECORD IN THE IMAGE WHOSE ADVANCE BYTE OVER-DECLARES.",
           "; Lane promB6 left the question: as op 0x00 with length 11 this record",
           "; would end at 0xF3B65C, yet the next record demonstrably starts at",
           "; 0xF3B65B.  So EITHER op 0x00 does not carry its length at +1, OR",
           "; DL_F3B65B's start is off by one.  It is NEITHER, and the handler",
           "; settles it:",
           ";   * op 0x00 DOES carry its advance at +1.  The interpreter reads +1",
           ";     for every opcode without looking at the opcode -- 0xF31B15",
           ";     `ld A,(XIY+0x01)` then `add XIY,XWA`.",
           ";   * DL_F3B65B is not off by one.  prom_b 0xF7E79E passes 0xF3B65B as",
           ";     XIX -- the list's exclusive end -- in the same breath as",
           ";     `ld XIY,0x00f3b651` at 0xF7E799.",
           "; ADVANCE and EXTENT are simply different numbers.  Handler 0xF31BA1's",
           "; highest read is +9 (`ld C,(XIY+0x09)`), so the DATA this record",
           "; occupies is 10 bytes, 0xF3B651-0xF3B65A.  The advance byte says 11.",
           "; The over-declaration is inert: XIY lands on 0xF3B65C, past XIX, and",
           "; the loop test `cp XIX,XIY / jr ULE` ends the list -- the machine draws",
           "; the record and stops.",
           "; The other edge is an immediate too: 0xF3B651 is the XIX of the",
           "; interpreter-A call at 0xF7E8C3, i.e. the exclusive end of Paint_TrackLabels9To16_DL.",
           "; Verify: python3 notes/gen_prom_b_res3xx_spans.py --selftest",
           "; ------------------------------------------------------------------",
           "TrackAssign_PaintTrackGroup_DL:"]
    out += emit_record(d, 0xF3B651, None)
    out.append("")

    old = ("Data_F3B651:\n"
           "\t.byte\t0x00, 0x0B, 0x40, 0x26, 0xFF\t; F3B651  |..@&.|\n"
           "\n"
           '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03B656, 0x000005\n')
    return old, "\n".join(out) + "\n"


BLOCKS = [block1, block2, block3, block4, block5]

# Header corrections: (anchor line, note appended after it)
HEADER_FIXES = [
    ("; Data_F28522 -- 426 bytes, EMITTED AS DATA (not promoted to code).",
     "; ⚠ SUPERSEDED 2026-09-02 (lane res3xx): 426 was the reachability walk's\n"
     ";   extent, and it is 42 bytes TOO LONG.  The record at 0xF28468 that\n"
     ";   names 0x00F28522 declares 3 bytes per entry and mask 0x7F, i.e. 128\n"
     ";   entries = 384 bytes, ending at 0xF286A1.  The 42 bytes that used to\n"
     ";   be tacked on here are a display-list record and its string table and\n"
     ";   are now framed as such below.  So: 384 bytes, and the `stays\n"
     ";   `.incbin`` sentence below no longer holds for this span."),
    ("; Data_F32992 -- 110 bytes, EMITTED AS DATA (not promoted to code).",
     "; ⚠ SUPERSEDED 2026-09-02 (lane res3xx): 110 is 6 bytes too long.  The\n"
     ";   last 6 bytes are the head of the opcode-02 record at 0xF329FA, which\n"
     ";   the pointer array at 0xF32A36 names and 0xF09AE1 runs; it is framed\n"
     ";   below.  So: 104 bytes, and the `stays `.incbin`` sentence below no\n"
     ";   longer holds for this span."),
]


def build(d):
    return [b(d) for b in BLOCKS]


def apply_to(src, d):
    for old, new in build(d):
        assert src.count(old) == 1, "anchor not unique/absent:\n" + old[:200]
        src = src.replace(old, new)
    for anchor, note in HEADER_FIXES:
        assert src.count(anchor) == 1, anchor
        src = src.replace(anchor, anchor + "\n" + note)
    return src


def selftest():
    d = rom()
    ok = []

    def chk(cond, msg):
        assert cond, "FAIL: " + msg
        ok.append(msg)

    # ---- external anchors: the exact `ld XIY/XIX,imm32` bytes in the ROM ----
    LD_XIY, LD_XIX = 0x45, 0x44
    for site, opc, target, what in [
        (0xF7E799, LD_XIY, 0xF3B651, "span 5 list start"),
        (0xF7E79E, LD_XIX, 0xF3B65B, "span 5 list END -> record is 10 bytes"),
        (0xF7E8BE, LD_XIY, 0xF3B611, "Paint_TrackLabels9To16_DL start"),
        (0xF7E8C3, LD_XIX, 0xF3B651, "span 5 start is also Paint_TrackLabels9To16_DL's end"),
        (0xF7E775, LD_XIY, 0xF3A43E, "span 4 record -> handler 0xF41820"),
        (0xF7E77E, LD_XIY, 0xF3A433, "span 4 neighbour -> handler 0xF4181C"),
        (0xF7E64C, LD_XIX, 0xF3A433, "0xF3A433 is a list end elsewhere"),
        (0xF55CA6, LD_XIY, 0xF3434C, "span 3 record start"),
        (0xF55D57, LD_XIY, 0xF3434C, "span 3 record start (2nd site)"),
        (0xF55D45, LD_XIY, 0xF34361, "span 3 far end RealtimeRecordScreen_DrawValues_DL"),
        (0xF5D488, LD_XIY, 0xF32A36, "span 2 pointer array is loaded by code"),
        (0xF7EE71, LD_XIY, 0xF3A461, "span 4 far end DL_F3A461"),
    ]:
        o = site - BASE
        chk(d[o] == opc and u32(d, site + 1) == target,
            "0x%06X is `ld %s,0x%08X`  (%s)"
            % (site, "XIY" if opc == LD_XIY else "XIX", target, what))

    # ---- span 1: the left anchor is a framed record's own declaration ----
    r = rec(d, 0xF28468)
    chk((r["op"], r["ptr"], r["width"], r["mask"], r["shift"]) == (0x07, 0xF28522, 3, 0x7F, 0),
        "0xF28468 is op 07 -> 0x00F28522, width 3, mask 0x7F")
    n = (r["mask"] >> r["shift"]) + 1
    chk(0xF28522 + n * r["width"] == 0xF286A2,
        "128 x 3 = 384 B ends at 0xF286A1, so 0xF286A2 starts a new object")

    a = 0xF286A2
    for exp_ptr, exp_n in ((0xF286B3, 8), (0xF286DC, 2), (0xF286F3, 2)):
        r = rec(d, a)
        chk(r["op"] == 0x07 and r["adv"] == 17, "0x%06X is op 07, advance 17" % a)
        chk(r["ptr"] == a + 17 == exp_ptr, "0x%06X +7 -> 0x%06X, the byte after it" % (a, r["ptr"]))
        chk(r["width"] == 3, "0x%06X entry width 3" % a)
        chk((r["mask"] >> r["shift"]) + 1 == exp_n,
            "0x%06X (mask>>shift)+1 = %d entries" % (a, exp_n))
        a = r["ptr"] + exp_n * 3
    chk(a == 0xF286F9, "span 1 tiles exactly onto ModeScreen_PaintDirtyFields2_DL1 (no slack)")

    # ---- span 2 ----
    chk(u32(d, 0xF32A3A) == 0xF329FA and u32(d, 0xF32A3E) == 0xF329FA,
        "pointer array 0xF32A36 entries 1,2 = 0x00F329FA")
    chk(u32(d, 0xF32A42) == 0xF32A09,
        "pointer array 0xF32A36 entry 3 = 0x00F32A09, an already-framed record")
    r = rec(d, 0xF329FA)
    chk(r["op"] == 0x02 and r["adv"] == 15, "0xF329FA is op 02, advance 15")
    chk(0xF329FA + 15 == 0xF32A09, "its 15-byte extent ends exactly on 0xF32A09")
    chk(r["ptr"] == 0xF32A6F, "its +7 -> 0x00F32A6F")

    # ---- span 3 ----
    r = rec(d, 0xF3434C)
    chk(r["op"] == 0x02 and r["adv"] == 15, "0xF3434C is op 02, advance 15")
    chk(r["ptr"] == 0xF3434C + 15 == 0xF3435B, "its +7 -> the byte right after it")
    chk(r["width"] == 3 and 0xF3435B + 2 * 3 == 0xF34361,
        "2 entries of 3 bytes reach exactly RealtimeRecordScreen_DrawValues_DL")
    chk(d[0xF3435B - BASE:0xF34361 - BASE] == b" -1 -2", 'the table reads " -1 -2"')

    # ---- span 4 ----
    for a in (0xF3A433, 0xF3A43E):
        r = rec(d, a)
        chk(r["op"] in (0x03, 0x08) and r["adv"] == 11, "0x%06X is op %02X, advance 11" % (a, r["op"]))
        chk(r["ptr"] == 0xF3A449, "0x%06X +7 -> 0x00F3A449" % a)
    chk(0xF3A433 + 11 == 0xF3A43E, "the two records abut")
    chk(0xF3A43E + 11 == 0xF3A449, "the array starts right after the second")
    chk(0xF3A449 + 3 * 8 == 0xF3A461, "3 entries of 8 bytes reach exactly DL_F3A461")

    # ---- span 5: the handler settles it ----
    r = rec(d, 0xF3B651)
    chk(r["op"] == 0x00, "0xF3B651 is op 00")
    chk(r["adv"] == 11, "its ADVANCE byte (+1) is 11")
    chk(HANDLER[0x00][1] == 10, "handler 0xF31BA1's highest read is +9 -> EXTENT 10")
    chk(0xF3B651 + r["adv"] == 0xF3B65C > 0xF3B65B,
        "advance lands XIY on 0xF3B65C, PAST XIX=0xF3B65B -> the loop ends")
    chk(0xF3B651 + 10 == 0xF3B65B, "the 10-byte extent ends exactly where DL_F3B65B starts")
    # and it is the only such record: every other op-00 record in the source says 0x0A
    src = open(SRC, encoding="utf-8").read()
    n0a = src.count("\t.byte 0x00, 0x0A\t; B op 00")
    n0b = src.count("\t.byte 0x00, 0x0B\t; B op 00")
    chk(n0a > 0 and n0b == 1,
        "in the committed source %d interpreter-B op-00 records declare advance 10 "
        "and exactly %d declares 11" % (n0a, n0b))

    # ---- the emitted assembly reproduces the ROM, and is in the source ----
    for old, new in build(d):
        chk(old not in src, "the pre-conversion text is gone from %s" % SRC)
        chk(new in src, "the emitted block is present verbatim in %s" % SRC)
    for lo, n in ((0x0286CC, 0x2D), (0x032A00, 9), (0x034350, 0x11),
                  (0x03A443, 0x1E), (0x03B656, 5)):
        chk('0x%06X, 0x%06X' % (lo, n) not in src,
            "no `.incbin` left for ROM offset 0x%06X (+%d)" % (lo, n))

    for line in ok:
        print("  ok  " + line)
    print("\n%d checks PASS" % len(ok))


def main():
    d = rom()
    if "--selftest" in sys.argv:
        selftest()
    elif "--emit" in sys.argv:
        for old, new in build(d):
            print(new)
    elif "--splice" in sys.argv:
        # ⚠ prom_b/wsa1_prom_b.s is UTF-8 (it carries ⚠ and ★ in comments) and
        #   contains no raw high bytes, so a UTF-8 round trip is byte-exact --
        #   asserted below rather than assumed.  And the new text is built and
        #   encoded BEFORE the file is touched, so a failure cannot truncate it,
        #   which is exactly what an in-place `open(..., "w")` did once here.
        raw = open(SRC, "rb").read()
        src = raw.decode("utf-8")
        assert src.encode("utf-8") == raw, "%s is not a clean UTF-8 round trip" % SRC
        out = apply_to(src, d).encode("utf-8")
        with open(SRC + ".tmp", "wb") as f:
            f.write(out)
        os.replace(SRC + ".tmp", SRC)
        print("spliced %s: %d -> %d bytes" % (SRC, len(raw), len(out)))
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
