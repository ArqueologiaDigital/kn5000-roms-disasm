#!/usr/bin/env python3
"""Convert prom_b's 0xF3D5E5-0xF3DA6E span (1,162 B), wave 1's SECOND
resistant spot -- and show it is a FIXED-STRIDE array, not a length-prefixed
record stream, so the "opening opcode 0x2B" that stopped the naive walk was
never an opcode at all.

QUESTION IT ANSWERS
    Wave 1 (notes/gen_prom_b_stepselect_module.py) found this span opens with
    a byte (0x2B) that is not a legal opcode for either known interpreter
    (A: bound 0x24, B: bound 0x0F) and filed it as "a third record format
    this file does not claim to know". Is there a third format, or is the
    length-prefixed framing simply the wrong model for this span?

ANSWER: wrong model, not a new format. Every "op 0x02" record in this whole
    (and the neighbouring, already-converted) region shares one physical
    layout:
        +00 0x02              constant tag (matches interpreter A/B's op 2)
        +01 byte              NOT a length -- see below
        +02 word              source-variable address (all in 0x2648-0x2658,
                               the SAME range the already-converted records
                               immediately before this span use)
        +04 byte               AND mask
        +05 byte               right shift
        +06 byte               swi 7 function (always 0x06 here)
        +07 long (LE, 0-padded) -> pointer, ALWAYS one of three addresses
                                   inside this very span's tail: 0xF3D9A7,
                                   0xF3D9C7, 0xF3DA67 (see TABLES below)
        +0x0B word              entry width for that pointer's table
        +0x0D word              screen position (same role as "-> IX"
                                 elsewhere in this file)
    -- 15 BYTES, ALWAYS, regardless of what "+01" holds.

    notes/gen_prom_b_f3c947_module.py already proved the +07/+0x0B pair names
    a string table and its entry width for a DIFFERENT span (0xF3C947); this
    span is the same mechanism at larger scale: THREE tables, all inside the
    span itself, addressed a total of 64 times.

    THE PROOF THAT LENGTH IS NOT SELF-DESCRIBING: byte +01 is 0x0F for 63 of
    the 64 records and 0x14 (20) for exactly one (0xF3D7E5) -- yet walking
    every record at a FIXED stride of 15 bytes from 0xF3D5E7 lands EXACTLY on
    0xF3D9A7 (64*15 = 960 = 0xF3D9A7-0xF3D5E7), which is independently the
    first pointer target above. A length-directed walk would desync at
    0xF3D7E5; the fixed-stride walk does not, at any of the 64 steps. So
    "+01" is a data byte this module does not further interpret (transcribed
    byte-exact regardless), not a length -- and 0x2B was never an opcode: it
    is simply the tail of the byte pair 2 bytes BEFORE this table (see below).

WHAT PRECEDES THE TABLE: 0xF3D5E5-0xF3D5E6 (2 bytes, value 0x082B). The
    already-converted record ending at 0xF3D5E5 is proven flush (byte-exact
    string match against wsa1_prom_b.s) and the fixed-stride table is proven
    to start at 0xF3D5E7, so these 2 bytes belong to NEITHER neighbour. Their
    value, 0x082B, is IDENTICAL to the first table record's own +0x0D screen
    position -- almost certainly a cached copy of that position read by code
    elsewhere before the loop over the table begins. Emitted as an honestly
    unlabelled 2-byte value, not folded into either neighbour.

TABLES (all three addressed only by the +07/+0x0B fields above -- this is
    what closes the span, not guesswork about their contents):
    0xF3D9A7, width 2, 16 entries (32 B): note letters with two glyph bytes
        (0x88, 0x8C) standing in for accidentals -- "C ", "D<0x88>", "D ",
        "E<0x88>", "E ", "F ", "F<0x8C>", "G ", "A<0x88>", "A ", "B<0x88>",
        "B ", and 4 blank entries. A 12-note chromatic scale plus 4 pad slots.
    0xF3D9C7, width 5, 32 entries (160 B): chord-quality suffixes -- "Maj7",
        "aug", "min", "min7", "dim", "m7<0x88>5", "mM7", "7sus4", "6",
        "aug7", "13", ... -- standard chord-symbol vocabulary, some entries
        blank.
    0xF3DA67, width 2, 4 entries (8 B): "  ", "_ ", "7 ", "6 ".
    32 + 160 + 8 = 200 bytes, exactly the span's remainder after the table
    (1162 - 2 - 960 = 200) -- the byte accounting closes with no slack.

    The two glyph bytes (0x88, 0x8C) are not ASCII and are not decoded
    further here (semantic labelling is deferred this wave); they are
    transcribed as `.byte` with a comment, exactly like this file's existing
    "character codes below 0x20" convention for the OTHER out-of-ASCII-range
    glyphs the display lists already use.

RUN
    python3 notes/gen_prom_b_f3d5e5_module.py             # print the asm
    python3 notes/gen_prom_b_f3d5e5_module.py --selftest  # verify all checks
    python3 notes/gen_prom_b_f3d5e5_module.py --apply     # patch wsa1_prom_b.s
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
B_BASE = 0xF00000

SPAN_START, SPAN_END = 0xF3D5E5, 0xF3DA6F   # END exclusive; old header said
                                             # "0xF3D5E5-0xF3DA6E" (inclusive)
LEAD_START, LEAD_END = 0xF3D5E5, 0xF3D5E7   # the orphan 2 bytes
TAB_START = 0xF3D5E7                        # 64 fixed 15-byte records
STRIDE, COUNT = 15, 64
TABLES_START = TAB_START + STRIDE * COUNT   # 0xF3D9A7
PTR_NOTE, PTR_CHORD, PTR_TAIL = 0xF3D9A7, 0xF3D9C7, 0xF3DA67
NOTE_W, NOTE_N = 2, 16
CHORD_W, CHORD_N = 5, 32
TAIL_W, TAIL_N = 2, 4

OLD_INCBIN = (
    '; --- 0xF3D5E5-0xF3DA6E: not converted ---\n'
    '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03D5E5, 0x00048A\n'
)


def load():
    return open(ROM, "rb").read()


def records(b):
    out = []
    for i in range(COUNT):
        p = TAB_START + i * STRIDE
        raw = b[p - B_BASE:p - B_BASE + STRIDE]
        assert raw[0] == 0x02, "record %d at %06X: expected tag 0x02, got 0x%02X" % (i, p, raw[0])
        f1 = raw[1]
        srcvar = int.from_bytes(raw[2:4], "little")
        mask, shift, swi = raw[4], raw[5], raw[6]
        ptr = int.from_bytes(raw[7:11], "little")
        width = int.from_bytes(raw[11:13], "little")
        pos = int.from_bytes(raw[13:15], "little")
        assert ptr in (PTR_NOTE, PTR_CHORD, PTR_TAIL), \
            "record %d at %06X: pointer %06X is not one of this span's own tables" % (i, p, ptr)
        out.append((p, f1, srcvar, mask, shift, swi, ptr, width, pos))
    assert TABLES_START == PTR_NOTE, \
        "fixed-stride walk should land exactly on the note table: got %06X, expected %06X" % (TABLES_START, PTR_NOTE)
    return out


def table_entries(b, start, width, n):
    off = start - B_BASE
    return [bytes(b[off + i * width: off + i * width + width]) for i in range(n)]


def check_tables(b):
    notes = table_entries(b, PTR_NOTE, NOTE_W, NOTE_N)
    chords = table_entries(b, PTR_CHORD, CHORD_W, CHORD_N)
    tails = table_entries(b, PTR_TAIL, TAIL_W, TAIL_N)
    assert PTR_NOTE + NOTE_W * NOTE_N == PTR_CHORD, "note table does not abut the chord table"
    assert PTR_CHORD + CHORD_W * CHORD_N == PTR_TAIL, "chord table does not abut the tail table"
    assert PTR_TAIL + TAIL_W * TAIL_N == SPAN_END, \
        "tail table does not end exactly at the span end: %06X vs %06X" % (PTR_TAIL + TAIL_W * TAIL_N, SPAN_END)
    return notes, chords, tails


def fmt_entry(raw):
    """A fixed-width entry as either `.ascii` (pure printable) or `.byte`
    with a best-effort comment for the non-ASCII glyph bytes this table
    also carries (0x88, 0x8C -- not decoded further, see module docstring)."""
    if all(0x20 <= c <= 0x7E for c in raw):
        return '\t.ascii "%s"' % raw.decode("ascii").replace("\\", "\\\\").replace('"', '\\"')
    text = "".join(chr(c) if 0x20 <= c <= 0x7E else "<0x%02X>" % c for c in raw)
    return "\t.byte %s\t; %s" % (", ".join("0x%02X" % c for c in raw), text)


def emit(b):
    recs = records(b)
    notes, chords, tails = check_tables(b)

    out = []
    out.append("; ------------------------------------------------------------------\n")
    out.append("; 0x%06X-0x%06X -- 2 unlabelled bytes then a 64-entry FIXED-STRIDE\n"
                "; array (15 bytes/entry, 960 bytes) of the SAME field-and-pointer\n"
                "; record already used just above this span, plus the three small\n"
                "; string tables its own pointer fields name.  The array's per-entry\n"
                "; +01 byte is NOT a length (proved by the fixed-stride walk landing\n"
                "; exactly on the first table despite one entry's +01 reading 0x14\n"
                "; instead of the usual 0x0F) -- wave 1's length-directed walk read\n"
                "; that byte as an opcode and stopped here.  Full proof in\n"
                "; notes/gen_prom_b_f3d5e5_module.py.\n"
                % (SPAN_START, SPAN_END - 1))
    out.append("; ------------------------------------------------------------------\n")

    lead = b[LEAD_START - B_BASE:LEAD_END - B_BASE]
    lead_val = int.from_bytes(lead, "little")
    out.append("Data_F3D5E5:\n")
    out.append("\t.short 0x%04X\t; == record[0]'s own +0x0D screen position below; role undetermined\n" % lead_val)

    out.append("\n")
    out.append("StepRecordChordFieldArray_F3D5E7:\n")
    for p, f1, srcvar, mask, shift, swi, ptr, width, pos in recs:
        out.append("\t.byte 0x02, 0x%02X\t; tag 0x02; +0x01 (NOT a length here, see header)\n" % f1)
        out.append("\t.short 0x%04X\t; +0x02 source variable, 16-bit address\n" % srcvar)
        out.append("\t.byte 0x%02X\t; +0x04 AND mask\n" % mask)
        out.append("\t.byte 0x%02X\t; +0x05 right shift\n" % shift)
        out.append("\t.byte 0x%02X\t; +0x06 swi 7 function\n" % swi)
        out.append("\t.long 0x%08X\t; +0x07 -> one of this span's own tables, below\n" % ptr)
        out.append("\t.short 0x%04X\t; +0x0B entry width of that table\n" % width)
        out.append("\t.short 0x%04X\t; +0x0D screen position\n" % pos)

    out.append("\n")
    out.append("; NoteNameTable_F3D9A7 -- %d entries, %d bytes each, named by the +0x07/\n"
                "; +0x0B fields above (0x%06X).  0x88/0x8C are non-ASCII glyph bytes\n"
                "; this table shares with the display-list text renderer's own\n"
                "; below-0x20 glyphs; not decoded further this wave.\n" % (NOTE_N, NOTE_W, PTR_NOTE))
    out.append("NoteNameTable_F3D9A7:\n")
    for i, e in enumerate(notes):
        out.append("%s\t; [%d]\n" % (fmt_entry(e), i))

    out.append("\n")
    out.append("; ChordQualityTable_F3D9C7 -- %d entries, %d bytes each, named by the\n"
                "; +0x07/+0x0B fields above (0x%06X).\n" % (CHORD_N, CHORD_W, PTR_CHORD))
    out.append("ChordQualityTable_F3D9C7:\n")
    for i, e in enumerate(chords):
        out.append("%s\t; [%d]\n" % (fmt_entry(e), i))

    out.append("\n")
    out.append("; ChordTailTable_F3DA67 -- %d entries, %d bytes each, named by the\n"
                "; +0x07/+0x0B fields above (0x%06X).  Ends the span exactly at\n"
                "; 0x%06X.\n" % (TAIL_N, TAIL_W, PTR_TAIL, SPAN_END - 1))
    out.append("ChordTailTable_F3DA67:\n")
    for i, e in enumerate(tails):
        out.append("%s\t; [%d]\n" % (fmt_entry(e), i))

    return "".join(out)


def selftest():
    b = load()
    recs = records(b)
    notes, chords, tails = check_tables(b)
    f1s = sorted(set(r[1] for r in recs))
    print("64 records at fixed stride 15, tag 0x02 always, +0x01 values seen: %s"
          % ", ".join("0x%02X" % x for x in f1s))
    print("pointers used: %s" % sorted(set("0x%06X" % r[6] for r in recs)))
    print("note table:", [e.hex() for e in notes])
    print("chord table:", [e for e in chords])
    print("tail table:", [e for e in tails])
    print("OK: fixed-stride walk from 0x%06X lands exactly on 0x%06X after %d records; "
          "3 tables abut with no gap and the last ends exactly at 0x%06X"
          % (TAB_START, TABLES_START, COUNT, SPAN_END - 1))
    return 0


def apply():
    b = load()
    asm = emit(b)
    src = open(SRC).read()
    assert src.count(OLD_INCBIN) == 1, "expected exactly one copy of the old incbin block"
    src = src.replace(OLD_INCBIN, asm)
    open(SRC, "w").write(src)
    print("applied: replaced 1162-byte .incbin at 0x%06X with %d lines of assembly"
          % (SPAN_START, asm.count("\n")))
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    if "--apply" in sys.argv:
        return apply()
    sys.stdout.write(emit(load()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
