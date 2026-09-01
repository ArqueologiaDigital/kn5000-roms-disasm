#!/usr/bin/env python3
"""Convert prom_b's 0xF3C947-0xF3C991 span (75 B), one of wave 1's three
resistant spots -- and show it is NOT a third record format.

QUESTION IT ANSWERS
    Wave 1 (notes/gen_prom_b_stepselect_module.py and the lane brief that
    followed it) flagged this span as unconverted because a naive
    interpreter-A length walk from 0xF3C947 does not land on a byte boundary
    -- it runs into the ASCII 'C' of "CHORD" and treats 0x43 as a bogus
    opcode (0x43 >= 0x24, interpreter A's bound).  Is that a genuinely new
    framing, or does an already-documented format explain it?

ANSWER: it is interpreter B, already fully documented in this same file at
    wsa1_prom_b.s:52290-52347 (the opcode/length/handler table put there by an
    earlier round).  This span is not a third format; it is interpreter A's
    op 0x0E four times, then ONE interpreter-B op 0x02 record, then the
    string table that record's own +7 field points at.

THE WALK, PROVEN NOT GUESSED
    prom_b bytes at 0xF3C947 (offsets relative to 0xF3C947):
        +00  0E 08 B0 04 22 00 0E 00   interpreter-A op 0E, len 8 -> handler
        +08  0E 08 B8 0B 22 00 06 00     0xF31A9F (IY,BC,HL fields) -- FOUR
        +10  0E 08 C0 12 19 00 06 00     of these, all 8 bytes, none touch
        +18  0E 08 C8 19 22 00 06 00     text so none can run into "CHORD"
        +20  02 0F FC 12 FF 00 07 76 C9 F3 00 07 00 3F 00
                 interpreter-B op 02, len 15 -> handler 0xF31B21
                 (wsa1_prom_b.s:52326 "02  0xF31B21  15  long -> string
                 table, +0x0B = entry width"), fields:
                   +02 word   0x12FC   source-variable address
                   +04 byte   0xFF     AND mask
                   +05 byte   0x00     right shift
                   +06 byte   0x07     swi 7 function
                   +07 long   0x00F3C976   -> XIY: string table  <-- see below
                   +0B word   0x0007   -> BC: bytes per entry
                   +0D word   0x003F   -> IX
        +2F  end of record 5, exactly 0xF3C976 -- so the 5-record walk is
             self-checking: 4*8 + 15 = 47 = 0xF3C976 - 0xF3C947.

    The record's OWN +7 field names 0x00F3C976 as a string table, and that is
    EXACTLY the address the record walk stops at -- the same evidentiary shape
    already used for DL_OriginalStringCylinderCone (wsa1_prom_b.s:3376,
    "+0x07 -> XIY: string table" naming DLTable_OriginalStringCylinder right
    where its own record list ends).  The entry width the record names, 7, is
    the SAME width that divides the remaining 28 bytes (0xF3C976-0xF3C991)
    into exactly four whole entries -- 28 / 7 = 4, no remainder, no fudge.

    Those four 7-byte entries decode as ASCII with no non-printable byte:
        "CHORD  " "MELODY " "CONTROL" "RHYTHM "
    -- the four track kinds a KN/WSA1-family sequencer step-records into,
    which matches the "STEP RECORD: PART SELECT" screen text immediately
    above this span (DL_StepRecordPartSelectPressTheUpDownButton, ends at
    0xF3C947, the address this span starts at).

WHY THIS IS NOT DEBT-AS-.BYTE
    Every byte is spelled through the SAME handler-field template already
    proven correct and in production use elsewhere in this file (the interp-A
    HANDLERS table in scripts/analysis/prom_b_display_lists.py for op 0x0E,
    and the interpreter-B opcode table at wsa1_prom_b.s:52290 for op 0x02).
    Nothing here is a bare `.byte` run standing in for undecoded code.

RUN
    python3 notes/gen_prom_b_f3c947_module.py            # print the asm
    python3 notes/gen_prom_b_f3c947_module.py --selftest # verify the walk only
    python3 notes/gen_prom_b_f3c947_module.py --apply    # patch wsa1_prom_b.s
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
B_BASE = 0xF00000

START, END = 0xF3C947, 0xF3C992          # END is EXCLUSIVE (the old header's
                                          # "0xF3C947-0xF3C991" names the
                                          # INCLUSIVE last byte, 0x4B = 75 B)
DL_END = 0xF3C976                        # where the 5 framed records stop
TAB_START, TAB_END = 0xF3C976, 0xF3C992  # the string table the last record
                                          # names, immediately following

OLD_INCBIN = (
    '; --- 0xF3C947-0xF3C991: not converted ---\n'
    '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03C947, 0x00004B\n'
)


def load():
    return open(ROM, "rb").read()


def walk_records(b):
    """Interpreter-A op 0x0E (x4) then interpreter-B op 0x02 (x1).  Returns
    the list of (addr, op, len) or raises if any check fails."""
    recs = []
    p = START
    for _ in range(4):
        off = p - B_BASE
        op, ln = b[off], b[off + 1]
        assert op == 0x0E and ln == 8, "expected interp-A op 0E len 8 at %06X, got %02X/%02X" % (p, op, ln)
        recs.append((p, op, ln))
        p += ln
    off = p - B_BASE
    op, ln = b[off], b[off + 1]
    assert op == 0x02 and ln == 0x0F, "expected interp-B op 02 len 15 at %06X, got %02X/%02X" % (p, op, ln)
    recs.append((p, op, ln))
    p += ln
    assert p == DL_END, "record walk stopped at %06X, expected %06X" % (p, DL_END)
    return recs


def check_b_record_pointer(b):
    """The op-02 record's own +7/+0x0B fields must name the string table and
    its entry width -- proving the tail is what the record says it is, not
    an assumption."""
    off = DL_END - 0x0F - B_BASE           # start of the op-02 record
    ptr = int.from_bytes(b[off + 7:off + 11], "little")
    width = int.from_bytes(b[off + 11:off + 13], "little")
    assert ptr == TAB_START, "record's +7 pointer is %06X, expected %06X" % (ptr, TAB_START)
    assert width > 0 and (TAB_END - TAB_START) % width == 0, \
        "table span %d not a whole multiple of entry width %d" % (TAB_END - TAB_START, width)
    return width


def table_entries(b, width):
    off = TAB_START - B_BASE
    n = (TAB_END - TAB_START) // width
    out = []
    for i in range(n):
        raw = b[off + i * width: off + i * width + width]
        assert all(0x20 <= c <= 0x7E for c in raw), "entry %d not printable ASCII: %r" % (i, raw)
        out.append(raw.decode("ascii"))
    return out


def esc(t):
    return t.replace("\\", "\\\\").replace('"', '\\"')


def emit(b):
    recs = walk_records(b)
    width = check_b_record_pointer(b)
    entries = table_entries(b, width)

    out = []
    out.append("; ------------------------------------------------------------------\n")
    out.append("; 0x%06X-0x%06X -- 5 display-list records, 47 bytes -- interpreter A\n"
                "; (4 records) then interpreter B (1 record); the B record's own +7\n"
                "; field points at, and its +0x0B field gives the entry width of, the\n"
                "; %d-byte string table that follows.  Wave 1's naive interp-A length\n"
                "; walk misread this as unconverted because it does not know\n"
                "; interpreter B's opcode 0x02 -- that opcode/length/handler table is\n"
                "; already documented at wsa1_prom_b.s:52290.  See\n"
                "; notes/gen_prom_b_f3c947_module.py for the full proof.\n"
                % (START, DL_END - 1, TAB_END - TAB_START))
    out.append("; ------------------------------------------------------------------\n")
    out.append("DL_F3C947:\n")
    for p, op, ln in recs[:4]:
        off = p - B_BASE
        raw = b[off:off + ln]
        iy = int.from_bytes(raw[2:4], "little")
        bc = int.from_bytes(raw[4:6], "little")
        hl = int.from_bytes(raw[6:8], "little")
        out.append("\t.byte 0x%02X, 0x%02X\t; op %02X, %d bytes -> handler 0xF31A9F\n" % (op, ln, op, ln))
        out.append("\t.short 0x%04X\n" % iy)
        out.append("\t.short 0x%04X\n" % bc)
        out.append("\t.short 0x%04X\n" % hl)

    p, op, ln = recs[4]
    off = p - B_BASE
    raw = b[off:off + ln]
    srcvar = int.from_bytes(raw[2:4], "little")
    mask = raw[4]
    shift = raw[5]
    swi = raw[6]
    ptr = int.from_bytes(raw[7:11], "little")
    width_f = int.from_bytes(raw[11:13], "little")
    ix = int.from_bytes(raw[13:15], "little")
    out.append("\t.byte 0x%02X, 0x%02X\t; B op %02X, %d bytes -> handler 0xF31B21 -- "
                "string-table readout: HL = extracted value = entry index\n" % (op, ln, op, ln))
    out.append("\t.short 0x%04X\t; +0x02 source variable, 16-bit address\n" % srcvar)
    out.append("\t.byte 0x%02X\t; +0x04 AND mask\n" % mask)
    out.append("\t.byte 0x%02X\t; +0x05 right shift, low 3 bits\n" % shift)
    out.append("\t.byte 0x%02X\t; +0x06 swi 7 function\n" % swi)
    out.append("\t.long 0x%08X\t; +0x07 -> XIY: string table\n" % ptr)
    out.append("\t.short 0x%04X\t; +0x0B -> BC: bytes per entry\n" % width_f)
    out.append("\t.short 0x%04X\t; +0x0D -> IX\n" % ix)

    out.append("\n")
    out.append("; StringTable_F3C976 -- %d entries, %d bytes each, named by the record\n"
                "; above (DL_F3C947's op-02 record: +0x07 -> here, +0x0B = %d).  The\n"
                "; object's own content is these four words; the name is neutral\n"
                "; (address-based) because semantic labelling is deferred this wave --\n"
                "; see notes/gen_prom_b_f3c947_module.py.\n" % (len(entries), width, width))
    out.append("StringTable_F3C976:\n")
    for i, e in enumerate(entries):
        out.append('\t.ascii "%s"\t; [%d]\n' % (esc(e), i))
    return "".join(out)


def selftest():
    b = load()
    recs = walk_records(b)
    width = check_b_record_pointer(b)
    entries = table_entries(b, width)
    print("records:", [(hex(p), hex(op), ln) for p, op, ln in recs])
    print("string table @ 0x%06X, width %d, entries %r" % (TAB_START, width, entries))
    print("OK: 47-byte record walk lands exactly on 0x%06X, "
          "and 28-byte tail is exactly %d whole %d-byte entries"
          % (DL_END, len(entries), width))
    return 0


def apply():
    b = load()
    asm = emit(b)
    src = open(SRC).read()
    assert src.count(OLD_INCBIN) == 1, "expected exactly one copy of the old incbin block"
    src = src.replace(OLD_INCBIN, asm)
    open(SRC, "w").write(src)
    print("applied: replaced 75-byte .incbin at 0x%06X with %d lines of assembly"
          % (START, asm.count("\n")))
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
