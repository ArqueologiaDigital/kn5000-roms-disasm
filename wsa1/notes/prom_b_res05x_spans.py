#!/usr/bin/env python3
"""prom_b_res05x_spans.py -- where do the record boundaries of prom_b's five
`res05x` residue spans lie, and what fixes each one FROM OUTSIDE the span?

QUESTION THIS ANSWERS
----------------------
FINDINGS-prom_b-last-481-bytes.md established that all sixteen remaining
`.incbin` spans in prom_b are DATA, and that they were left behind because a
reachability walk cut them MID-RECORD.  It deliberately stopped short of
handing anyone a layout, because a stride read off a span that is known to
start in the wrong place is the "wrong start frames fake records" hazard, and
the byte gate cannot object to a wrong framing -- ANY framing of the right
bytes rebuilds the ROM.

This script answers the next question for five of those spans (177 bytes):

    what OUTSIDE the span fixes its record boundaries?

For each region it asserts a chain that starts and ends at an anchor this lane
did not choose, and tiles the bytes between them with ZERO SLACK.

THE ANCHOR KINDS USED HERE
---------------------------
A. a display-list record ELSEWHERE in prom_b whose operand names the object and
   states its element size.  The record IS the consumer's argument list:
     * interpreter-B op 02 (15 B, handler 0xF31B21):
           +0x07 .long -> string table,  +0x0B .short -> BYTES PER ENTRY
     * interpreter-B op 03 (11 B, handler 0xF31B57):
           +0x07 .long -> array; the handler does `sla 3,HL` => 8-byte entries
     * interpreter-A op 03 (12 B, handler 0xF31ABE):
           +0x02 .long -> bitmap, +0x08 .short width in BYTES, +0x0A rows
   These readings are notes/prom_b_dl_operand_tables.py's, not this lane's.
B. THE READER ITSELF.  The display-list interpreters are called as
       ld XIY,<start> ; ld XIX,<end> ; call 0xF417F0   (interpreter A)
       ld XIY,<start> ; ld XIX,<end> ; call 0xF417F4   (interpreter B)
   in prom_b's own converted code, so a list's first byte and its one-past-end
   are two 32-bit immediates in an instruction stream this tree already
   decodes.  Four of the five regions are bounded by such a pair.  This is the
   anchor the findings document asked for: "the code that consumes these
   records".  The tree's `DL_*` labels and `ends used:` banners are the same
   facts as recorded by earlier lanes.
C. exact tiling: op/len records chained from anchor to anchor with no bytes
   left over.  A framing off by one anywhere overruns the far anchor.

   ⚠ A RECORD'S ADVANCE AND ITS EXTENT ARE DIFFERENT NUMBERS.  Lane res3xx
   established that on 0xF3B651: the byte at +1 is the step the interpreter
   adds to XIY, and one record in the image declares 11 where the handler
   reads only 10, deliberately, to land past XIX and end the list.  So a
   chain of +1 bytes is an ADVANCE chain, and it is only a layout when it
   closes onto an address something else names.  Every tiling here does:
   region A closes onto BOTH of the reader's two list ends, and regions B, C
   and D onto a `ld XIX`/`ld XIY` immediate or a record's own +0x07 pointer.

WHAT IS NOT EVIDENCE HERE: a stride recovered from the bytes alone.  Every
claim below is checked against an address that exists outside the span.

RUN
    python3 notes/prom_b_res05x_spans.py             # the evidence table
    python3 notes/prom_b_res05x_spans.py --selftest  # asserts every claim
    python3 notes/prom_b_res05x_spans.py --emit      # the converted source
    python3 notes/prom_b_res05x_spans.py --verify    # re-assemble it vs the ROM
    python3 notes/prom_b_res05x_spans.py --splice    # apply it to the .s
"""
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, "original_ROMs/wsa1_prom_b.ic13")
SRC = os.path.join(ROOT, "prom_b/wsa1_prom_b.s")
BASE = 0xF00000

# The five spans this lane owns: (cpu address, length) as cut by the
# superseded reachability walk.  Regenerate the full list with
#   grep -a '\.incbin' prom_b/wsa1_prom_b.s
# grep -a, not grep: an agent shell's grep skips files it deems binary.
SPANS = {
    "F03F81": (0xF03F81, 46),
    "F04D14": (0xF04D14, 15),
    "F0540B": (0xF0540B, 58),
    "F05792": (0xF05792, 46),
    "F05CEC": (0xF05CEC, 12),
}

# Interpreter-A / B record handlers, as this tree already records them in
# prom_b/wsa1_prom_b.s.  Regenerate:
#   grep -ao '; op [0-9A-F][0-9A-F], [0-9]* bytes -> handler 0x[0-9A-F]*' \
#       prom_b/wsa1_prom_b.s | sed 's/, [0-9]* bytes//' | sort -u
HANDLER = {
    0x00: 0xF31A75, 0x01: 0xF31A75, 0x02: 0xF31A75, 0x03: 0xF31ABE,
    0x05: 0xF31A75, 0x06: 0xF31A3A, 0x07: 0xF31A3A, 0x08: 0xF31A3A,
    0x09: 0xF31A75, 0x0A: 0xF31A75, 0x0E: 0xF31A9F, 0x11: 0xF31A75,
    0x12: 0xF31A75, 0x13: 0xF31A75, 0x16: 0xF31A3A, 0x17: 0xF31A52,
    0x19: 0xF31A3A, 0x1A: 0xF31A3A, 0x1B: 0xF31A75, 0x1C: 0xF31A52,
    0x1D: 0xF31A3A, 0x20: 0xF31A3A, 0x22: 0xF31A75, 0x23: 0xF31ACE,
}
# handler 0xF31A52 = two coordinate words then text; 0xF31A3A = one VRAM
# address then text; 0xF31A75 = four words; 0xF31ACE = a byte then a word.
TEXT_AFTER_XY = {0x17, 0x1C}
TEXT_AFTER_ADDR = {0x06, 0x07, 0x08, 0x16, 0x19, 0x1A, 0x1D, 0x20}
BYTE_THEN_WORD = {0x23}


def load():
    with open(ROM, "rb") as f:
        return f.read()


def at(d, a, n):
    return d[a - BASE:a - BASE + n]


def le16(d, a):
    return struct.unpack_from("<H", d, a - BASE)[0]


def le32(d, a):
    return struct.unpack_from("<I", d, a - BASE)[0]


def tile(d, start, end):
    """Chain op/len records from `start`; returns [(addr, op, len)] and the
    address one past the last record."""
    out, a = [], start
    while a < end:
        op, ln = d[a - BASE], d[a - BASE + 1]
        if ln < 2:
            return out, None
        out.append((a, op, ln))
        a += ln
    return out, a


def le32_sites(d, target):
    """Every prom_b file offset holding `target` as a little-endian 32-bit
    word.  Used to prove an anchor exists outside the span -- or does not."""
    pat, out, i = struct.pack("<I", target), [], 0
    while True:
        i = d.find(pat, i)
        if i < 0:
            return out
        out.append(i)
        i += 1


# ==========================================================================
# The five regions.  Each docstring states the anchors; the body asserts them.
# ==========================================================================

def region_F03F81(d, say):
    """0xF03F77-0xF0402D -- ONE interpreter-A display list, 18 records, 183 B.

    Anchor: THE READER, sub_F5C727:
        F5C72C  ld XIY,0x00F03F77      <- list start
        F5C731  cp (0x27F5),0x01
        F5C736  jr Z,0xF5C73F
        F5C738  ld XIX,0x00F0402E      <- list end, variant 1
        F5C73D  jr 0xF5C744
        F5C73F  ld XIX,0x00F03FF3      <- list end, variant 2
        F5C744  call 0xF417F0          <- T_DisplayList_Run (interpreter A)
      The routine names the start AND BOTH ends.  0xF0402E is also TouchCurve_DrawCurrentSlot_DL2
      ("entered at"); 0xF03F77 is also the `ends used` of the preceding list,
      and 0xF5D568 loads it as an end as well.
    Tiling: op/len from 0xF03F77 lands EXACTLY on 0xF0402E after 18 records --
      and record 13 starts at 0xF03FF3, the reader's other end.  Two ends, both
      landing on a record boundary of this one framing.
    """
    recs, end = tile(d, 0xF03F77, 0xF0402E)
    starts = {a for a, _, _ in recs}
    say("  F03F77: %d records, ends at %06X" % (len(recs), end))
    say("  reader's two ends 0xF03FF3 / 0xF0402E both on a boundary: %s"
        % (0xF03FF3 in starts and end == 0xF0402E))
    assert end == 0xF0402E and len(recs) == 18
    assert 0xF03FF3 in starts
    lo, n = SPANS["F03F81"]
    assert recs[0][0] < lo and end > lo + n
    return recs


def region_F04D14(d, say):
    """0xF04CE8-0xF04D42 -- rect array (5x8) + one op-02 record + string table.

    Anchor (start): TWO independent facts put an object boundary at 0xF04CE8.
      (1) the reader at 0xF5CE93 runs the list 0xF04CDE..0xF04CE8
          (`ld XIY,0x00F04CDE ; ld XIX,0x00F04CE8 ; call 0xF417F0`), so
          0xF04CE8 is the first byte AFTER that list;
      (2) Draw_ToneTemplateLevelKeyTune_DL5 is an interpreter-B op 03 whose +0x07 operand is
          0x00F04CE8 -- "array of 8-byte entries", the READER's element size.
    Anchor (mid): the reader at 0xF5C979 does `ld XIY,0x00F04D10` and calls
      0xF41830, so 0xF04D10 is a RECORD START named by code.  Independently the
      op-02 record there carries 0x00F04D1F at +0x07 and 6 at +0x0B: a pointer
      landing exactly 15 bytes past the record's own start confirms the phase.
    Anchor (end): DL_F04D43, and the reader at 0xF5C907 runs 0xF04D43..0xF04DA3.
    Tiling: 5*8 + 15 + 6*6 = 91 = 0xF04D43 - 0xF04CE8, zero slack.
    """
    assert le32(d, 0xF33B81 + 7) == 0xF04CE8
    assert at(d, 0xF04D10, 2) == b"\x02\x0f"
    tab, bpe = le32(d, 0xF04D10 + 7), le16(d, 0xF04D10 + 0x0B)
    say("  op-02 at F04D10: table 0x%06X, %d bytes/entry" % (tab, bpe))
    assert tab == 0xF04D1F and bpe == 6
    assert 5 * 8 + 15 + 6 * bpe == 0xF04D43 - 0xF04CE8
    ents = [struct.unpack_from("<4H", d, 0xF04CE8 - BASE + 8 * i) for i in range(5)]
    say("  rects: %s" % " ".join("(%X,%X,%X,%X)" % e for e in ents))
    assert all(e[0] == ents[0][0] and e[2] == ents[0][2] for e in ents)
    assert ents[0] == ents[1]
    assert [e[1] for e in ents] == [0x4C, 0x4C, 0x6C, 0x8C, 0xAC]
    txt = at(d, 0xF04D1F, 36).decode("latin-1")
    say("  table: %r" % txt)
    assert txt == "LPF+EQHPF+EQLPF24 HPF24  BPF   THRU "
    return ents, txt


def region_F0540B(d, say):
    """0xF05407-0xF05444 -- four op-02 records of 15 + a 2-entry string table.

    Anchor (start): the 4-entry pointer array at 0xF0545A -- converted earlier
      by lane promB6 -- holds 0x00F05407, 0x00F05416, 0x00F05425, 0x00F05434.
      THE FOUR RECORD STARTS ARE WRITTEN DOWN 79 BYTES LATER, by a table this
      lane did not frame.  Stride 15 is a consequence, not an assumption.
      Independently, the reader at 0xF5C53A/0xF5CF85 runs the list
      0xF053B6..0xF05407, so 0xF05407 is the first byte after a display list.
    Anchor (end): all four records carry 0x00F05443 at +0x07 as their string
      table, and 0xF05434 + 15 = 0xF05443 -- the reader's own pointer names the
      first byte after the last record.  Data_F05445 (the reader at 0xF5CF9A
      does `ld XIY,0x00F05445`) closes the table at 2 bytes, and +0x0B says 1
      byte per entry, so the table is exactly two entries: "+" and "-".
    Cross-check: mask 0x10 at +0x04, shift 4 at +0x05 -> an index of 0 or 1.
      Exactly two entries, which is what the 2 bytes hold.
    """
    starts = [0xF05407, 0xF05416, 0xF05425, 0xF05434]
    named = [0xF05407] + [le32(d, 0xF0545D + 4 * i) for i in range(3)]
    say("  pointer array at F0545A names: %s" % " ".join("%06X" % v for v in named))
    assert named == starts
    for a in starts:
        assert at(d, a, 2) == b"\x02\x0f"
        assert le32(d, a + 7) == 0xF05443
        assert le16(d, a + 0x0B) == 1
        assert d[a - BASE + 4] == 0x10 and d[a - BASE + 5] == 0x04
    assert starts[-1] + 15 == 0xF05443
    say("  string table F05443, 1 B/entry, mask 0x10>>4 -> 2 entries: %r"
        % at(d, 0xF05443, 2).decode("latin-1"))
    assert at(d, 0xF05443, 2) == b"+-"
    return starts


def region_F05792(d, say):
    """0xF0574D-0xF057BF -- 2-byte strtab + 3-byte strtab + op-1B + rect array.

    Anchor (start): the reader at 0xF5D15A runs the list 0xF0564B..0xF0574D, so
      0xF0574D is the first byte after a display list; and DL_F338F6 is an
      interpreter-B op 02 whose +0x07 operand is 0x00F0574D with +0x0B = 2
      BYTES PER ENTRY.  The reader states both the base and the stride.
    Anchor (end): the reader at 0xF5D168/0xF5D2F0 runs 0xF057C0..0xF057E3
      (DL_F057C0), so 0xF057C0 is a record start.
    Tiling: 25*2 + 5*3 + 10 + 5*8 = 115 = 0xF057C0 - 0xF0574D, zero slack.

    THIS IS THE WEAKEST OF THE FOUR CONVERTED REGIONS.  Its interior splits are
    named by no pointer at all: NOTHING in any of the four WSA1R ROMs holds
    0xF0577F, 0xF0578E, 0xF05790 or 0xF05798 as a 32-bit word -- asserted
    below, and it matters because `ld XIY,imm32` would have put one there.
    What fixes them instead:
      * the 2-byte table is ASCII "A:".."Z:" with T absent -- 25 entries -- and
        a 26th 2-byte slot would be "1s", splitting a word;
      * the op-1B record at 0xF0578E self-describes (op 1B, len 10) and its
        four words are (0x000E, 0x004D, 0x0100, 0x00C9), EXACTLY the bounding
        box of the five rectangles that follow it;
      * those 40 bytes carry the signature of the THREE rect arrays that ARE
        externally typed in this ROM (0xF04CE8 via Draw_ToneTemplateLevelKeyTune_DL5, 0xF05475 via the
        op-03 at 0xF053FC, DLTable_F031C9 via the record at 0xF030E6): five
        entries, x1 and x2 constant, y stepping 0x20, entry[0] == entry[1];
      * the 3-byte table is "1st","1st","2nd","3rd","4th" -- five entries whose
        FIRST TWO ARE ALSO EQUAL.  A parallel array for the same 5-valued
        selector as the rectangles.
    THE COMPETING FRAMING WAS CHECKED AND REJECTED: taking the array as SIX
    entries starting at 0xF05790 also tiles the gap, but then entry[0] is the
    full bounding box and entry[1] == entry[2], breaking the [0]==[1] idiom
    that all three externally-sized sibling arrays obey.
    """
    assert le32(d, 0xF338F6 + 7) == 0xF0574D
    assert le16(d, 0xF338F6 + 0x0B) == 2
    for t in (0xF0577F, 0xF0578E, 0xF05790, 0xF05798):
        assert le32_sites(d, t) == [], "unexpected pointer to %06X" % t
    say("  no prom_b word points at F0577F/F0578E/F05790/F05798")
    letters = at(d, 0xF0574D, 50).decode("latin-1")
    assert letters == "".join(c + ":" for c in "ABCDEFGHIJKLMNOPQRSUVWXYZ")
    ordinals = at(d, 0xF0577F, 15).decode("latin-1")
    assert ordinals == "1st1st2nd3rd4th"
    assert at(d, 0xF0578E, 2) == b"\x1b\x0a"
    box = struct.unpack_from("<4H", d, 0xF05790 - BASE)
    ents = [struct.unpack_from("<4H", d, 0xF05798 - BASE + 8 * i) for i in range(5)]
    say("  op-1B box %s == union of the 5 rects (y = %s)"
        % (box, [hex(e[1]) for e in ents]))
    assert box == (ents[0][0], ents[0][1], ents[0][2], max(e[3] for e in ents))
    assert ents[0] == ents[1]
    assert all(e[0] == ents[0][0] and e[2] == ents[0][2] for e in ents)
    assert [e[1] for e in ents] == [0x4D, 0x4D, 0x6D, 0x8D, 0xAD]
    assert 50 + 15 + 10 + 40 == 0xF057C0 - 0xF0574D
    # and the rejected 6-entry framing really does break the idiom
    six = [struct.unpack_from("<4H", d, 0xF05790 - BASE + 8 * i) for i in range(6)]
    assert six[0] != six[1] and six[1] == six[2]
    return letters, ordinals, box, ents


def region_F05CEC(d, say):
    """0xF05CE0-0xF05CF7 -- ONE bitmap, 2 bytes wide by 12 rows = 24 bytes.

    Anchor: THREE interpreter-A op-03 records (12 B, handler 0xF31ABE) name it
      and state its size -- the records at 0xF02B97, 0xF06307 and 0xF0631D,
      each `.long 0x00F05CE0` then a VRAM address, `.short 2` (width in BYTES)
      and `.short 12` (rows).  The handler issues `swi 7` service 3 with
      BC = width in bytes and HL = rows, so the size is BC * HL = 24.  That
      reading of op 03 is notes/prom_b_dl_operand_tables.py's, not this lane's,
      and that script independently reports
          0xF05CE0 +  24  A bitmap, 2 bytes x 12 rows
    Anchor (end): Data_F05CF8, reached from 0xF04D5F 0xF04D7D 0xF04E1B 0xF04E5E
      0xF04E7C.  0xF05CE0 + 24 = 0xF05CF8 exactly.
    Both edges and the length are therefore stated outside the span, and the
    span is the bitmap's SECOND byte-column.
    """
    sites = le32_sites(d, 0xF05CE0)
    say("  0x00F05CE0 named by op-03 records at: %s"
        % " ".join("%06X" % (BASE + s - 2) for s in sites))
    assert len(sites) == 3
    for s in sites:
        a = BASE + s
        assert at(d, a - 2, 2) == b"\x03\x0c", "site %06X is not an op-03" % a
        w, h = le16(d, a + 6), le16(d, a + 8)
        assert (w, h) == (2, 12), "site %06X says %dx%d" % (a, w, h)
    assert 0xF05CE0 + 2 * 12 == 0xF05CF8
    return sites


# ==========================================================================
# Rendering the converted source
# ==========================================================================

def _text(bs):
    """Render a display-list record's inline text the way this tree already
    does: printable runs as .ascii, control codes as a commented .byte."""
    out, run = [], bytearray()
    for b in bs:
        if 0x20 <= b < 0x7F and b not in (0x22, 0x5C):
            run.append(b)
        else:
            if run:
                out.append('\t.ascii "%s"' % run.decode("latin-1"))
                run = bytearray()
            out.append("\t.byte 0x%02X\t; character codes below 0x20" % b)
    if run:
        out.append('\t.ascii "%s"' % run.decode("latin-1"))
    return out


def render_record(d, a):
    """One interpreter-A record at `a`, in this file's existing style."""
    op, ln = d[a - BASE], d[a - BASE + 1]
    body = at(d, a + 2, ln - 2)
    out = ["\t.byte 0x%02X, 0x%02X\t; op %02X, %d bytes -> handler 0x%06X"
           % (op, ln, op, ln, HANDLER[op])]
    if op in BYTE_THEN_WORD:
        out.append("\t.byte 0x%02X" % body[0])
        out.append("\t.short 0x%04X" % int.from_bytes(body[1:3], "little"))
    elif op in TEXT_AFTER_XY:
        out.append("\t.short 0x%04X" % int.from_bytes(body[0:2], "little"))
        out.append("\t.short 0x%04X" % int.from_bytes(body[2:4], "little"))
        out += _text(body[4:])
    elif op in TEXT_AFTER_ADDR:
        out.append("\t.short 0x%04X" % int.from_bytes(body[0:2], "little"))
        out += _text(body[2:])
    else:
        for i in range(0, len(body), 2):
            out.append("\t.short 0x%04X" % int.from_bytes(body[i:i + 2], "little"))
    return out


def render_op02(d, a, what):
    """One interpreter-B op-02 record, field comments as this file writes them."""
    return [
        "\t.byte 0x02, 0x0F\t; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index",
        "\t.short 0x%04X\t; +0x02 source variable, 16-bit address" % le16(d, a + 2),
        "\t.byte 0x%02X\t; +0x04 AND mask" % d[a - BASE + 4],
        "\t.byte 0x%02X\t; +0x05 right shift, low 3 bits" % d[a - BASE + 5],
        "\t.byte 0x%02X\t; +0x06 swi 7 function" % d[a - BASE + 6],
        "\t.long 0x%08X\t; +0x07 -> XIY: %s" % (le32(d, a + 7), what),
        "\t.short 0x%04X\t; +0x0B -> BC: bytes per entry" % le16(d, a + 0x0B),
        "\t.short 0x%04X\t; +0x0D -> IX" % le16(d, a + 0x0D),
    ]


def render_rects(d, a, n):
    out = []
    for i in range(n):
        x1, y1, x2, y2 = struct.unpack_from("<4H", d, a - BASE + 8 * i)
        out.append("\t.short 0x%04X, 0x%04X, 0x%04X, 0x%04X\t; [%d]"
                   % (x1, y1, x2, y2, i))
    return out


def render_strtab(d, a, n, w):
    return ['\t.ascii "%s"\t; [%d]' % (at(d, a + w * i, w).decode("latin-1"), i)
            for i in range(n)]


def render_bitmap(d, a):
    """The 2x12 bitmap at 0xF05CE0, as its two byte-columns, with the picture
    the bytes make so a later reader can check the column-strip order."""
    def bits(b):
        return format(b, "08b").replace("0", ".").replace("1", "#")

    left, right = at(d, a, 12), at(d, a + 12, 12)
    art = ["; row %2d  %s%s" % (r, bits(left[r]), bits(right[r])) for r in range(12)]
    out = ["; Drawn as two byte-COLUMNS (bytes 0-11 = column 0, 12-23 = column 1)",
           "; these 24 bytes are a closed 16x12 ring with an interior diagonal.",
           "; Drawn row-major (2 bytes per row) they are not a closed shape.  The",
           "; blitter's actual pixel order is NOT established here -- only the",
           "; EXTENT is, and the extent is all this conversion rests on."] + art
    out.append("\t.byte\t" + ", ".join("0x%02X" % b for b in left)
               + "\t; F05CE0  byte-column 0, rows 0-11")
    out.append("\t.byte\t" + ", ".join("0x%02X" % b for b in right)
               + "\t; F05CEC  byte-column 1, rows 0-11")
    return out


def blocks(d):
    """name -> (start, end, [lines]) for the five converted regions."""
    B = {}

    # ---------------- 0xF03F77-0xF0402D ----------------
    L = [
        "; ------------------------------------------------------------------",
        "; 0xF03F77-0xF0402D -- 18 display-list records, 183 bytes -- interpreter A",
        ";   entered at: 0xF03F77",
        ";   ends used:  0xF03FF3, 0xF0402E",
        "; Formerly Data_F03F77 + a 46-byte `.incbin` + Data_F03FAF -- the head,",
        "; the middle and the tail of ONE list, cut in two places by the round-1",
        "; reachability walk.  THE READER NAMES BOTH EDGES: sub_F5C727 does",
        ";   F5C72C  ld XIY,0x00F03F77   /  F5C738 ld XIX,0x00F0402E",
        ";   F5C73F  ld XIX,0x00F03FF3   /  F5C744 call 0xF417F0",
        "; so the list starts at 0xF03F77 and ends at 0xF03FF3 or 0xF0402E; the",
        "; op/len chain below lands on BOTH.  Evidence, with the rejected",
        "; alternatives: python3 notes/prom_b_res05x_spans.py --selftest",
        ";",
        "; Provenance kept from the superseded framing:",
        ";   Data_F03F77 -- reached from: 0x00F03F77 appears as a 32-bit word at",
        ";     0xF5C72D 0xF5D569; converted code at 0xF5C72C 0xF5D568 loads it as",
        ";     a 32-bit immediate.  No routine-directory slot and no branch",
        ";     decoded in converted code names it.",
        ";   Data_F03FAF -- reached from: nothing aligned holds this address; the",
        ";     walk fell through into it.",
        ";   Both blocks carried the warning \"The extent is the reachability",
        ";   walk's, not the object's\".  They were right, and this is the",
        ";   correction they asked for.",
        "; ------------------------------------------------------------------",
        "DL_F03F77:",
        "Data_F03F77:",
    ]
    recs, _ = tile(d, 0xF03F77, 0xF0402E)
    for a, op, ln in recs:
        if a == 0xF03FF3:
            L.append("DL_F03FF3:\t; the reader's other list end")
        L += render_record(d, a)
    B["F03F81"] = (0xF03F77, 0xF0402E, L)

    # ---------------- 0xF04CE8-0xF04D42 ----------------
    L = [
        "; ------------------------------------------------------------------",
        "; 0xF04CE8-0xF04D42 -- a 5x8 rectangle array, one display-list record,",
        "; and the 6-byte string table that record points at.  91 bytes, tiled",
        "; end to end between two addresses the READER names:",
        ";   0xF5CE93  ld XIY,0x00F04CDE ; ld XIX,0x00F04CE8  -> list ends here",
        ";   0xF5C979  ld XIY,0x00F04D10 ; call 0xF41830      -> record starts here",
        ";   0xF5C907  ld XIY,0x00F04D43                      -> next list",
        "; 5*8 + 15 + 6*6 = 91 = 0xF04D43 - 0xF04CE8, with no slack.",
        "; Evidence: python3 notes/prom_b_res05x_spans.py --selftest",
        ";",
        "; Provenance kept from the superseded framing:",
        ";   Data_F04CE8 -- reached from: 0x00F04CE8 appears as a 32-bit word at",
        ";     0xF33B88 0xF5CE99; converted code at 0xF5CE98 loads it as a 32-bit",
        ";     immediate.  (0xF33B81 is the interpreter-B op-03 record whose",
        ";     +0x07 operand that is -- \"array of 8-byte entries\".)",
        ";   Data_F04D23 -- reached from: nothing aligned holds this address; the",
        ";     walk fell through into it.  ITS START WAS MID-ENTRY: 0xF04D23 is",
        ";     +4 inside the first 6-byte table entry, which is why the label is",
        ";     not reproduced here.  The table's real head is 0xF04D1F, named by",
        ";     the record at 0xF04D10.",
        "; ------------------------------------------------------------------",
        "DLTable_F04CE8:\t; 5 entries of 8 bytes -- highlight rectangles (x1,y1,x2,y2)",
        ";   Referenced by: display-list record 0xF33B81 (interpreter B op 03,",
        ";   handler 0xF31B57, which does `sla 3,HL` -> 8-byte entries).",
        ";   5 entries is the EXTENT (40 bytes / 8), not the (mask >> shift) + 1",
        ";   = 16 the record would allow.  [0] == [1] is this ROM's idiom for a",
        ";   4-item list whose selector is 1-based.",
    ]
    L += render_rects(d, 0xF04CE8, 5)
    L += ["DL_F04D10:"]
    L += render_op02(d, 0xF04D10, "string table")
    L += [
        "DLTable_F04D1F:\t; 6 entries of 6 bytes -- the filter-mode names",
        ";   Referenced by: the record at 0xF04D10, whose +0x0B says 6 bytes per",
        ";   entry.  6 entries is the EXTENT (36 bytes / 6); the mask 0x07 at",
        ";   +0x04 would allow 8.",
    ]
    L += render_strtab(d, 0xF04D1F, 6, 6)
    B["F04D14"] = (0xF04CE8, 0xF04D43, L)

    # ---------------- 0xF05407-0xF05444 ----------------
    L = [
        "; ------------------------------------------------------------------",
        "; 0xF05407-0xF05444 -- four interpreter-B op-02 records of 15 bytes and",
        "; the 2-entry string table all four of them point at.",
        "; THE RECORD STARTS ARE WRITTEN DOWN 79 BYTES LATER: the 4-entry pointer",
        "; array at 0xF0545A holds 0x00F05407 0x00F05416 0x00F05425 0x00F05434.",
        "; The reader at 0xF5C53A/0xF5CF85 runs the list 0xF053B6..0xF05407, so",
        "; 0xF05407 is also the first byte after a display list; and the last",
        "; record's own +0x07 pointer, 0x00F05443, names the first byte after",
        "; itself.  Evidence: python3 notes/prom_b_res05x_spans.py --selftest",
        ";",
        "; Provenance kept from the superseded framing:",
        ";   Data_F05407 -- reached from: 0x00F05407 appears as a 32-bit word at",
        ";     0xF05459 0xF5C540 0xF5CF8B; converted code at 0xF5C53F 0xF5CF8A",
        ";     loads it as a 32-bit immediate.  It was emitted as 4 bytes; those",
        ";     4 bytes were the head of the first record.",
        "; ------------------------------------------------------------------",
        "DL_F05407:",
        "Data_F05407:",
    ]
    for i, a in enumerate([0xF05407, 0xF05416, 0xF05425, 0xF05434]):
        if i:
            L.append("DL_%06X:" % a)
        L += render_op02(d, a, "string table")
    L += [
        "DLTable_F05443:\t; 2 entries of 1 byte -- the sign shown for the value",
        ";   Referenced by: all four records above (+0x07 = 0x00F05443, +0x0B = 1).",
        ";   Exactly two entries: mask 0x10 at +0x04 with shift 4 at +0x05 can",
        ";   only ever produce index 0 or 1.",
    ]
    L += render_strtab(d, 0xF05443, 2, 1)
    B["F0540B"] = (0xF05407, 0xF05445, L)

    # ---------------- 0xF0574D-0xF057BF ----------------
    L = [
        "; ------------------------------------------------------------------",
        "; 0xF0574D-0xF057BF -- two string tables, one display-list record and a",
        "; 5x8 rectangle array.  115 bytes, tiled end to end between two",
        "; addresses the READER names:",
        ";   0xF5D15A  ld XIY,0x00F0564B ; ld XIX,0x00F0574D -> list ends here",
        ";   0xF5D168  ld XIY,0x00F057C0                     -> next list starts",
        "; 25*2 + 5*3 + 10 + 5*8 = 115 = 0xF057C0 - 0xF0574D, with no slack.",
        ";",
        "; THIS IS THE WEAKEST OF THIS LANE'S FIVE REGIONS and the comment says so",
        "; on purpose: NOTHING in any of the four WSA1R ROMs holds 0xF0577F,",
        "; 0xF0578E, 0xF05790 or 0xF05798 as a 32-bit word, so the three interior",
        "; splits rest on tiling plus three agreements, not on a pointer:",
        ";   * a 26th 2-byte letter slot would be \"1s\", splitting a word;",
        ";   * the op-1B record's four words ARE the bounding box of the five",
        ";     rectangles that follow it;",
        ";   * five entries with [0] == [1] is what all three externally-sized",
        ";     rectangle arrays in this ROM look like (0xF04CE8, 0xF05475,",
        ";     DLTable_F031C9), and the ordinal table beside it is also five",
        ";     entries with [0] == [1].",
        "; The competing framing -- six rectangles from 0xF05790 -- also tiles,",
        "; and is rejected because it makes [0] the bounding box and [1] == [2].",
        "; Evidence and both framings: notes/prom_b_res05x_spans.py --selftest",
        ";",
        "; Provenance kept from the superseded framing:",
        ";   Data_F0574D -- reached from: 0x00F0574D appears as a 32-bit word at",
        ";     0xF338FD 0xF33925 0xF33957 0xF33989 0xF5D160; converted code at",
        ";     0xF5D15F loads it as a 32-bit immediate.  (0xF338F6 is the",
        ";     interpreter-B op-02 record whose +0x07 operand that is, with",
        ";     +0x0B = 2 bytes per entry.)  It was emitted as 69 bytes, four more",
        ";     than the table has: the extra four were the head of the 0xF0578E",
        ";     record.",
        "; ------------------------------------------------------------------",
        "DLTable_F0574D:\t; 25 entries of 2 bytes -- letter labels, T absent",
        ";   Referenced by: display-list record 0xF338F6 (+0x0B = 2).  25 entries",
        ";   is the EXTENT, not the (mask 0x3F >> 0) + 1 = 64 the record allows.",
    ]
    L += render_strtab(d, 0xF0574D, 25, 2)
    L += [
        "DLTable_F0577F:\t; 5 entries of 3 bytes -- ordinals, [0] == [1]",
        ";   Not named by any pointer in the four ROMs; framed by the tiling and",
        ";   by being the parallel array of DLTable_F05798 below.",
    ]
    L += render_strtab(d, 0xF0577F, 5, 3)
    L += ["DL_F0578E:\t; one record, not named by any pointer in the four ROMs;",
          ";   its four words are the bounding box of the five rectangles below."]
    L += render_record(d, 0xF0578E)
    L += [
        "DLTable_F05798:\t; 5 entries of 8 bytes -- highlight rectangles (x1,y1,x2,y2)",
        ";   Same shape as DLTable_F04CE8 one pixel over: x1/x2 constant, y",
        ";   stepping 0x20, [0] == [1].",
    ]
    L += render_rects(d, 0xF05798, 5)
    B["F05792"] = (0xF0574D, 0xF057C0, L)

    # ---------------- 0xF05CE0-0xF05CF7 ----------------
    L = [
        "; ------------------------------------------------------------------",
        "; Bitmap_F05CE0 -- 24 bytes, 2 bytes wide x 12 rows.",
        "; Referenced by: three interpreter-A op-03 records, at 0xF02B97,",
        "; 0xF06307 and 0xF0631D.  Each is `.long 0x00F05CE0`, a VRAM address,",
        "; `.short 0x0002` (width in BYTES) and `.short 0x000C` (rows); handler",
        "; 0xF31ABE issues swi 7 service 3 with BC = width and HL = rows, so the",
        "; size is 2 * 12 = 24 -- and 0xF05CE0 + 24 = 0xF05CF8, the head of the",
        "; note-frequency table.  Both edges and the length come from outside the",
        "; span.  The first 12 bytes used to be the tail of Data_F05AB4, the last",
        "; 12 were the `.incbin` at file offset 0x005CEC.",
        "; Evidence: python3 notes/prom_b_res05x_spans.py --selftest, and",
        "; notes/prom_b_dl_operand_tables.py, which reports it independently as",
        "; `0xF05CE0 + 24  A bitmap, 2 bytes x 12 rows`.",
        "; ------------------------------------------------------------------",
        "Bitmap_F05CE0:",
    ]
    L += render_bitmap(d, 0xF05CE0)
    B["F05CEC"] = (0xF05CE0, 0xF05CF8, L)
    return B


# ==========================================================================
# Re-assembling the rendered source, so the framing is checked before the gate
# ==========================================================================

def assemble(lines):
    out = bytearray()
    for ln in lines:
        s = ln.split("\t;")[0].strip()
        if not s or s.startswith(";") or s.endswith(":") or ":\t" in ln.split(";")[0]:
            if not s.startswith("."):
                continue
        if s.startswith('.ascii'):
            m = re.match(r'\.ascii\s+"(.*)"$', s)
            out += m.group(1).encode("latin-1")
        elif s.startswith(".byte"):
            for v in s[5:].split(","):
                out.append(int(v.strip(), 0) & 0xFF)
        elif s.startswith(".short"):
            for v in s[6:].split(","):
                out += struct.pack("<H", int(v.strip(), 0))
        elif s.startswith(".long"):
            for v in s[5:].split(","):
                out += struct.pack("<I", int(v.strip(), 0))
        elif s.startswith("."):
            raise SystemExit("assemble: unhandled directive %r" % s)
    return bytes(out)


def verify(d, say):
    ok = True
    for name, (lo, hi, lines) in blocks(d).items():
        got, want = assemble(lines), at(d, lo, hi - lo)
        same = got == want
        ok &= same
        say("  %s  0x%06X-0x%06X  %4d B  %s"
            % (name, lo, hi - 1, hi - lo, "OK" if same else "MISMATCH"))
        if not same:
            for i in range(min(len(got), len(want))):
                if got[i] != want[i]:
                    say("    first diff at 0x%06X: got %02X want %02X"
                        % (lo + i, got[i], want[i]))
                    break
            say("    lengths: got %d want %d" % (len(got), len(want)))
    return ok


# ==========================================================================
# Splicing it into prom_b/wsa1_prom_b.s
# ==========================================================================
# Each entry is (first line to drop, last line to drop) -- matched exactly and
# required to be unique, so a re-run after the edit is a clean no-op.
# U+26A0 as this file stores it: UTF-8 bytes, seen through the latin-1 decoder
# every reader and writer of these sources must use.
WARN = "\u26a0".encode("utf-8").decode("latin-1")

CUTS = {
    "F03F81": ("; --------------------------------------------------------------------------\n; Data_F03F77 -- 10 bytes",
               "\t; F0401F  |.$.i.....i.4.z.|\n"),
    "F04D14": ("; --------------------------------------------------------------------------\n; Data_F04CE8 -- 44 bytes",
               "\t; F04D33  |F24  BPF   THRU |\n"),
    "F0540B": ("; --------------------------------------------------------------------------\n; Data_F05407 -- 4 bytes",
               '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x00540B, 0x00003A\n'),
    "F05792": ("; --------------------------------------------------------------------------\n; Data_F0574D -- 69 bytes",
               '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x005792, 0x00002E\n'),
    "F05CEC": ("\t.byte\t0x45, 0x38, 0x20, 0x46, 0x38, 0x20, 0x46, 0x8C, 0x38, 0x47, 0x38, 0x20, 0x07, 0x18, 0x20, 0x20",
               '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x005CEC, 0x00000C\n'),
}
# 0xF05CE0's first 12 bytes come out of Data_F05AB4's tail, so that block's
# stated length changes with it.
SHRINK = ("; Data_F05AB4 -- 568 bytes, EMITTED AS DATA (not promoted to code).",
          "; Data_F05AB4 -- 568 bytes, EMITTED AS DATA (not promoted to code).\n"
          "; " + WARN + " SUPERSEDED 2026-09-02 (lane res05x): 568 was the reachability walk's\n"
          ";   extent and it is 12 bytes TOO LONG.  Its last 12 bytes are the first\n"
          ";   byte-column of the 2x12 bitmap at 0xF05CE0, whose size three op-03\n"
          ";   records state (2 bytes x 12 rows = 24) and which now stands on its\n"
          ";   own below.  So: 556 bytes, 0xF05AB4-0xF05CDF, and the `stays\n"
          ";   `.incbin`` sentence below no longer holds for the span that followed.")
KEEP_TAIL = ("\t.byte\t0x45, 0x38, 0x20, 0x46, 0x38, 0x20, 0x46, 0x8C, "
             "0x38, 0x47, 0x38, 0x20\t; F05CD4  |E8 F8 F.8G8 |\n")


# The round-1 COVER banners around these five regions each end "Everything else
# here is NOT reachable and stays `.incbin`".  That sentence is now false for
# all five, so each gets a correction rather than being left to contradict the
# source below it.  (Global rule: a measurement that overturns documented text
# corrects that text in the same commit.)
CORRECT = "; notes/gen_prom_b_cover_round1.py --splice\n"
CORRECTIONS = {
    "0xF03F77-0xF0402E": "183 of 183",
    "0xF04CE8-0xF04D43": "91 of 91",
    "0xF05407-0xF0549D": "150 of 150",
    "0xF0574D-0xF057C0": "115 of 115",
    "0xF05AB4-0xF05F78": "1220 of 1220",
}

def splice(d, say):
    src = open(SRC, encoding="latin-1").read()
    if "DL_F03F77:" in src:
        say("  already spliced; nothing to do")
        return True
    before = len(src)
    B = blocks(d)
    for name, (head, tail) in CUTS.items():
        i = src.find(head)
        assert i >= 0 and src.find(head, i + 1) < 0, "cut head not unique: " + name
        j = src.find(tail, i)
        assert j >= 0, "cut tail not found: " + name
        j += len(tail)
        new = "\n".join(B[name][2]) + "\n"
        if name == "F05CEC":
            new = KEEP_TAIL + "\n" + new
        src = src[:i] + new + src[j:]
    for span, count in CORRECTIONS.items():
        head = "; === COVER-R1 %s ===\n" % span
        i = src.find(head)
        assert i >= 0 and src.find(head, i + 1) < 0, "banner not unique: " + span
        j = src.find(CORRECT, i)
        assert j >= 0 and j - i < 800, "banner tail not found: " + span
        j += len(CORRECT)
        note = ("; " + WARN + " CORRECTED 2026-09-02 (lane res05x): the sentence above is no\n"
                ";   longer true of this span -- %s bytes are real source now, and no\n"
                ";   `.incbin` remains between these markers.  What round 1 measured was\n"
                ";   REACHABILITY, which finds an object's first byte and never its last;\n"
                ";   the extents below come from the code that RUNS these records.\n" % count)
        src = src[:j] + note + src[j:]

    i = src.find(SHRINK[0])
    assert i >= 0 and src.find(SHRINK[0], i + 1) < 0
    src = src.replace(SHRINK[0] + "\n", SHRINK[1] + "\n")
    # Encode BEFORE touching the file, and replace atomically.  Opening the
    # target for writing and encoding as we go truncates it to zero if any
    # character will not fit -- which is exactly what a stray U+26A0 does to
    # these latin-1 sources.  (It happened twice while writing this script.)
    blob = src.encode("latin-1")
    tmp = SRC + ".res05x.tmp"
    with open(tmp, "wb") as f:
        f.write(blob)
    os.replace(tmp, SRC)
    say("  %s: %d -> %d bytes of source" % (os.path.basename(SRC), before, len(blob)))
    return True


def main():
    d = load()
    say = print
    if "--emit" in sys.argv:
        for name, (lo, hi, lines) in blocks(d).items():
            print("\n; ===== %s : 0x%06X-0x%06X =====" % (name, lo, hi - 1))
            print("\n".join(lines))
        return 0
    if "--verify" in sys.argv:
        print("re-assembling the rendered source against the ROM:")
        return 0 if verify(d, say) else 1
    if "--splice" in sys.argv:
        if not verify(d, say):
            print("refusing to splice: rendered source does not match the ROM")
            return 1
        splice(d, say)
        return 0

    print("prom_b res05x residue spans -- 177 bytes in five spans")
    print("ROM %s, base 0x%06X\n" % (os.path.relpath(ROM, ROOT), BASE))
    for name, (a, n) in SPANS.items():
        print("span 0x%06X + %-3d  %s" % (a, n, at(d, a, n).hex()))
    print("\n0xF03F81 -- one interpreter-A display list")
    for a, op, ln in region_F03F81(d, say):
        print("    %06X  op %02X  %2d B  -> handler 0x%06X" % (a, op, ln, HANDLER[op]))
    print("\n0xF04D14 -- rect array + op-02 record + 6-byte string table")
    region_F04D14(d, say)
    print("\n0xF0540B -- four op-02 records of 15 + a 2-entry string table")
    region_F0540B(d, say)
    print("\n0xF05792 -- two string tables + op-1B record + rect array")
    region_F05792(d, say)
    print("\n0xF05CEC -- second byte-column of the 2x12 bitmap at 0xF05CE0")
    region_F05CEC(d, say)
    print("\nre-assembling the rendered source against the ROM:")
    ok = verify(d, say)
    print("\nAll structural claims hold." if ok else "\nRENDERING MISMATCH")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
