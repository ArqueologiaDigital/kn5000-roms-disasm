#!/usr/bin/env python3
"""Close the five prom_b `.incbin` spans of lane promB4 as display-list RECORDS
and the OPERAND ARRAYS those records point at -- 1,139 B, all typed data.

QUESTION IT ANSWERS
  0x0396E7+70, 0x03A0E9+230, 0x03C47E+87, 0x03DA77+393 and 0x03DCBF+359 are
  five `.incbin` spans in the high half of prom_b.  What is in them, and what
  proves it?

  Answer: every one is either an interpreter-B display-list record or the
  fixed-stride operand array such a record's +0x07 pointer names.  Nothing
  here is disassembled into instructions -- these are typed data objects,
  which is what the evidence supports and no more.

WHY DATA AND NOT CODE, per object
  Each RECORD is licensed the way notes/gen_prom_b_tiny_records_batch.py
  licenses its six: its (op, length) satisfies EXACTLY ONE of the two
  interpreters' implied-length rules, read from the ROM's OWN handler tables
  HTBL_A (0xF31D21) / HTBL_B (0xF31DB1).  Never both, never neither.

  Each ARRAY is licensed the way notes/prom_b_dl_operand_tables.py licenses
  the 13 gaps it already closed: a record's +0x07 pointer lands on its first
  byte, the handler fixes the entry WIDTH (0xF31B57 `sla 3,HL` => 8 bytes;
  0xF31B86 `mul HL,6` => 6 bytes; 0xF31B21 takes the width from the record's
  own +0x0B), the extent is a whole number of entries, and the extent ends on
  a boundary established INDEPENDENTLY of this span -- a converted display-
  list header, or an address some other record already points at.

  ⚠ (mask >> shift) + 1 is an upper bound on the INDEX, not a measurement of
  the array.  Where it happens to equal the extent that is recorded as a
  bonus, never as the source of the size.

EXTERNAL CONFIRMATION (the part that is not self-referential)
  prom_a and prom_b both call the interpreter-B handlers DIRECTLY, with the
  record address in XIY, through the thunks

      T_DLB_Handler_Array8: jp 0xF31B57      (op 03 / op 08 -- 8-byte entries)
      T_DLB_Handler_Array8_2: jp 0xF31B57
      T_F41824: jp 0xF31B86      (op 04 -- 6-byte entries)

  and those call sites name three of the record starts this script asserts:

      prom_b 0xF7E966  ld XIY,0x00F396E2 ; call T_DLB_Handler_Array8   -> span 1's record
      prom_a 0xF81E93  ld XIY,0x00F3DA77 ; call T_DLB_Handler_Array8   -> span 4 record 1
      prom_a 0xF81EAE  ld XIY,0x00F3DAA2 ; call T_DLB_Handler_Array8   -> span 4 record 2
      prom_a 0xF81ECC  ld XIY,0x00F3DAED ; call T_DLB_Handler_Array8   -> span 4 record 3

  0xF396E2 is the important one: the tree currently swallows its first five
  bytes into the 398-byte `Data_F39559` string blob, whose own header warns
  "the extent is the reachability walk's, not the object's".  The walk
  overshot by exactly 5 bytes and this call site proves it.

WHAT IS NOT CLAIMED
  Span 5's 24 records are NOT reached by any call site this tree knows, and
  no 32-bit word anywhere in the four ROMs names 0xF3DCBB.  Their framing
  rests on a two-sided argument instead: walking 15-byte op-02 records
  BACKWARD from 0xF3DE23 (an address three other records at 0xF3D3C3,
  0xF3D3E1, 0xF3D3FF already point at) lands on 0xF3DCBB after exactly 24
  records and no further -- the byte before it is 0x2A, which is not a legal
  opcode (>= the 0x24 bound).  The run is maximal and self-terminating.
  See --check output line "span5 backward walk".

RUN
  python3 notes/gen_prom_b_promB4_operand_arrays.py --check
  python3 notes/gen_prom_b_promB4_operand_arrays.py --apply
  python3 scripts/analysis/assert_byte_identical.py
  python3 notes/gen_prom_b_promB4_operand_arrays.py --falsify   # gate must go RED
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
BASE = 0xF00000
HTBL_A, HTBL_B = 0x31D21, 0x31DB1

# handler -> (kind, n); copied from notes/prom_b_dl_length_audit.py so --check
# does not depend on that file being present.
IMPLIED_A = {
    0xF31A3A: ("min", 4), 0xF31A52: ("min", 6), 0xF31A75: ("fixed", 10),
    0xF31A9F: ("fixed", 8), 0xF31AAC: ("fixed", 6), 0xF31ABE: ("fixed", 12),
    0xF31ACE: ("fixed", 5), 0xF31AEB: ("min", 2),
}
IMPLIED_B = {
    0xF31BA1: ("fixed", 10), 0xF31B21: ("fixed", 15), 0xF31B39: ("fixed", 17),
    0xF31B57: ("fixed", 11), 0xF31B86: ("fixed", 11), 0xF31BD7: ("fixed", 11),
    0xF31C14: ("fixed", 12), 0xF31C56: ("fixed", 13), 0xF31C9E: ("fixed", 12),
    0xF31D20: ("min", 2),
}
# handler -> entry width the handler itself fixes (None = the record's +0x0B).
WIDTH = {0xF31B57: 8, 0xF31B86: 6, 0xF31B21: None}
HANDLER_NOTE = {
    0xF31B57: "four words of entry[value] -> (0x2530..0x2536)",
    0xF31B86: "entry[value] -> IY, BC, HL",
    0xF31B21: "string-table readout: HL = extracted value = entry index",
}
PTR_NOTE = {
    0xF31B57: "+0x07 -> XIX: array of 8-byte entries, indexed by the value",
    0xF31B86: "+0x07 -> XIX: array of 6-byte entries, indexed by the value",
    0xF31B21: "+0x07 -> XIY: string table",
}

# ---------------------------------------------------------------- the layout
# ("rec", addr)            -- an interpreter-B record; length read from the ROM
# ("tab", addr, n, width)  -- an operand array of n entries of `width` bytes
# Each span also declares the anchor that fixes its RIGHT edge and why.
SPANS = [
    dict(name="span1", incbin=(0x0396E7, 0x46), first=0xF396E2,
         objs=[("rec", 0xF396E2), ("tab", 0xF396ED, 8, 8)],
         end=0xF3972D,
         anchor="DL_F3972D, a converted interpreter-A op-1B record whose four "
                "words (0x0038, 0x003E, 0x0117, 0x00B5) are the bounding box "
                "of the 8 entries below"),
    dict(name="span2", incbin=(0x03A0E9, 0xE6), first=0xF3A0E4,
         objs=[("rec", 0xF3A0E4), ("tab", 0xF3A0EF, 16, 6), ("tab", 0xF3A14F, 16, 8)],
         end=0xF3A1CF,
         anchor="DL_F3A1CF, a converted display-list span header; and the "
                "6-byte array's end 0xF3A14F is named by the already-converted "
                "records at 0xF3A0D9, 0xF39000 and 0xF3900B"),
    dict(name="span3", incbin=(0x03C47E, 0x57), first=0xF3C37D,
         objs=[("tab", 0xF3C37D, 6, 8), ("tab", 0xF3C3AD, 37, 8)],
         end=0xF3C4D5,
         anchor="DL_ACurrentTrackWillBeClearedAutomaticaly at 0xF3C4D5, a "
                "converted display-list span header; both array starts are "
                "named by the converted records at 0xF3C367 and 0xF3C372"),
    dict(name="span4", incbin=(0x03DA77, 0x189), first=0xF3DA77,
         objs=[("rec", 0xF3DA77), ("tab", 0xF3DA82, 4, 8),
               ("rec", 0xF3DAA2), ("tab", 0xF3DAAD, 8, 8),
               ("rec", 0xF3DAED), ("tab", 0xF3DAF8, 33, 8)],
         end=0xF3DC00,
         anchor="DL_F3DC00, a converted display-list span header"),
    dict(name="span5", incbin=(0x03DCBF, 0x167), first=0xF3DCBB,
         objs=[("rec", 0xF3DCBB + 15 * i) for i in range(24)] +
              [("tab", 0xF3DE23, 3, 1)],
         end=0xF3DE26,
         anchor="Paint_StepRecord_DL3, a converted display-list span header; and the "
                "3-byte table start 0xF3DE23 is named by the converted records "
                "at 0xF3D3C3, 0xF3D3E1 and 0xF3D3FF as well as by all 24 "
                "records here"),
]


def rom():
    return open(ROM, "rb").read()


def tables(b):
    ta = [int.from_bytes(b[HTBL_A + i * 4:HTBL_A + i * 4 + 4], "little") for i in range(36)]
    tb = [int.from_bytes(b[HTBL_B + i * 4:HTBL_B + i * 4 + 4], "little") for i in range(15)]
    return ta, tb


def fits(op, ln, htab, implied):
    if op >= len(htab):
        return False, None
    h = htab[op]
    if h not in implied:
        return False, h
    kind, n = implied[h]
    return ((ln == n) if kind == "fixed" else (ln >= n)), h


def rec_info(b, addr):
    """(op, len, handler, ptr) for an interpreter-B record, asserting that
    exactly one interpreter's implied-length rule fits."""
    op, ln = b[addr - BASE], b[addr - BASE + 1]
    ta, tb = tables(b)
    ga, _ = fits(op, ln, ta, IMPLIED_A)
    gb, hb = fits(op, ln, tb, IMPLIED_B)
    ptr = int.from_bytes(b[addr - BASE + 7:addr - BASE + 11], "little")
    return op, ln, hb, ptr, ga, gb


# ------------------------------------------------------------------ rendering
def render_rec(b, addr):
    op, ln, h, ptr, _ga, _gb = rec_info(b, addr)
    d = b[addr - BASE:addr - BASE + ln]
    out = ["\t.byte 0x%02X, 0x%02X\t; B op %02X, %d bytes -> handler 0x%06X -- %s"
           % (op, ln, op, ln, h, HANDLER_NOTE[h])]
    out.append("\t.short 0x%04X\t; +0x02 source variable, 16-bit address"
               % int.from_bytes(d[2:4], "little"))
    out.append("\t.byte 0x%02X\t; +0x04 AND mask" % d[4])
    out.append("\t.byte 0x%02X\t; +0x05 right shift, low 3 bits" % d[5])
    out.append("\t.byte 0x%02X\t; +0x06 swi 7 function" % d[6])
    out.append("\t.long 0x%08X\t; %s" % (ptr, PTR_NOTE[h]))
    if ln == 15:
        out.append("\t.short 0x%04X\t; +0x0B -> BC: bytes per entry"
                   % int.from_bytes(d[11:13], "little"))
        out.append("\t.short 0x%04X\t; +0x0D -> IX" % int.from_bytes(d[13:15], "little"))
    return out


def render_tab(b, addr, n, width, refs, extra_label=None):
    lines = []
    lines.append("; ------------------------------------------------------------------")
    lines.append("; DLTable_%06X -- %d entries of %d bytes, 0x%06X-0x%06X"
                 % (addr, n, width, addr, addr + n * width - 1))
    lines.append("; Referenced by: display-list record%s %s"
                 % ("s" if len(refs) > 1 else "", ", ".join("0x%06X" % r for r in refs)))
    lines.append(";   Width is the HANDLER's (0xF31B57 `sla 3,HL` => 8; 0xF31B86")
    lines.append(";   `mul HL,6` => 6; 0xF31B21 takes it from the record's +0x0B).")
    lines.append(";   The COUNT is the extent divided by that width, and the extent")
    lines.append(";   is fixed by the anchors on both sides -- NOT by the record's")
    lines.append(";   AND mask, which bounds the index only.")
    lines.append("; ------------------------------------------------------------------")
    if extra_label:
        lines.append("%s:" % extra_label)
    lines.append("DLTable_%06X:" % addr)
    for i in range(n):
        d = b[addr - BASE + i * width:addr - BASE + (i + 1) * width]
        if width % 2 == 0:
            vals = ", ".join("0x%04X" % int.from_bytes(d[j:j + 2], "little")
                             for j in range(0, width, 2))
            lines.append("\t.short %s\t; [%d]" % (vals, i))
        else:
            vals = ", ".join("0x%02X" % x for x in d)
            txt = "".join(chr(x) if 32 <= x < 127 else "." for x in d)
            lines.append("\t.byte %s\t; [%d] |%s|" % (vals, i, txt))
    return lines


# --------------------------------------------------------------------- checks
def cmd_check(verbose=True):
    b = rom()
    ok = True
    total_incbin = 0
    for sp in SPANS:
        off, ln = sp["incbin"]
        total_incbin += ln
        start, end = BASE + off, BASE + off + ln
        cur = sp["first"]
        pieces = []
        for o in sp["objs"]:
            if o[0] == "rec":
                addr = o[1]
                op, rl, h, ptr, ga, gb = rec_info(b, addr)
                if addr != cur:
                    print("FAIL %s: record 0x%06X does not follow 0x%06X" % (sp["name"], addr, cur)); ok = False
                if not (gb and not ga):
                    print("FAIL %s: record 0x%06X op %02X len %d -- A fits=%s B fits=%s"
                          % (sp["name"], addr, op, rl, ga, gb)); ok = False
                pieces.append(("rec 0x%06X op %02X len %2d -> h 0x%06X ptr 0x%08X"
                               % (addr, op, rl, h, ptr), rl, addr))
                cur = addr + rl
            else:
                _, addr, n, w = o
                if addr != cur:
                    print("FAIL %s: table 0x%06X does not follow 0x%06X" % (sp["name"], addr, cur)); ok = False
                pieces.append(("tab 0x%06X %3d x %d" % (addr, n, w), n * w, addr))
                cur = addr + n * w
        if cur != sp["end"]:
            print("FAIL %s: chain ends 0x%06X, anchor is 0x%06X" % (sp["name"], cur, sp["end"])); ok = False
        # every table start must be named by some record's +7 pointer
        for o in sp["objs"]:
            if o[0] != "tab":
                continue
            if not refs_to(b, o[1]):
                print("FAIL %s: nothing points at table 0x%06X" % (sp["name"], o[1])); ok = False
        cleared = sum(sz for _t, sz, ad in pieces
                      for _ in [0]) - max(0, start - sp["first"])
        if cleared != ln:
            print("FAIL %s: objects cover %d B of the %d B .incbin" % (sp["name"], cleared, ln)); ok = False
        if verbose:
            print("%s  .incbin 0x%06X +%-4d  first object 0x%06X  ends 0x%06X"
                  % (sp["name"], off, ln, sp["first"], sp["end"]))
            for t, sz, _ad in pieces:
                print("        %-52s %4d B" % (t, sz))
            print("        %d B already typed before the .incbin + %d B of .incbin = %d B"
                  % (start - sp["first"], ln, cur - sp["first"]))
    # span 5's maximality argument
    p, n = 0xF3DE23, 0
    while True:
        q = p - 15
        if b[q - BASE] != 0x02 or b[q - BASE + 1] != 0x0F:
            break
        p, n = q, n + 1
    prev = b[p - BASE - 1]
    print("span5 backward walk: %d op-02/len-15 records back from 0xF3DE23 land on "
          "0x%06X; the byte before is 0x%02X (%s a legal opcode, bound 0x24)"
          % (n, p, prev, "NOT" if prev >= 0x24 else "IS"))
    if not (p == 0xF3DCBB and n == 24 and prev >= 0x24):
        print("FAIL span5 maximality"); ok = False
    print("lane promB4 .incbin bytes covered: %d" % total_incbin)
    print("CHECK: %s" % ("PASS" if ok else "FAIL"))
    return ok


def refs_to(b, addr):
    pat = addr.to_bytes(4, "little")
    out, i = [], b.find(pat)
    while i >= 0:
        out.append(BASE + i)
        i = b.find(pat, i + 1)
    return out


# ---------------------------------------------------------------------- apply
def read_src():
    return open(SRC, encoding="latin-1").read()


def write_src(t):
    """Byte-preserving, and ATOMIC: an encode failure must never truncate the
    source (it did, once, before the tmp+rename)."""
    tmp = SRC + ".tmp"
    with open(tmp, "wb") as f:
        f.write(t.encode("latin-1"))
    os.replace(tmp, SRC)


def byte_line(b, addr, n, indent="\t.byte\t"):
    d = b[addr - BASE:addr - BASE + n]
    txt = "".join(chr(x) if 32 <= x < 127 else "." for x in d)
    return "%s%s\t; %06X  |%s|" % (indent, ", ".join("0x%02X" % x for x in d), addr, txt)


def cmd_apply():
    if not cmd_check(verbose=False):
        print("refusing to apply: --check failed")
        return False
    b = rom()
    t = read_src()
    n0 = len(t)
    for old, new in edits(b):
        if t.count(old) != 1:
            print("refusing to apply: anchor found %d times:\n%s" % (t.count(old), old[:200]))
            return False
        t = t.replace(old, new)
    write_src(t)
    print("applied; source grew from %d to %d bytes" % (n0, len(t)))
    return True


def hdr(name, addr, end, anchor, extra=()):
    import textwrap
    L = ["; =================================================================="
         , "; 0x%06X-0x%06X -- display-list RECORDS and the OPERAND ARRAYS they"
         % (addr, end - 1),
         ";                    point at (%d bytes) -- converted 2026-09-02," % (end - addr),
         ";                    lane promB4, notes/gen_prom_b_promB4_operand_arrays.py",
         "; ==================================================================",
         ";"]
    L += ["; " + x for x in textwrap.wrap("Right edge anchored on %s." % anchor, 74)]
    L += [";"]
    for e in extra:
        L.append("; %s" % e)
    if extra:
        L.append(";")
    return L


def edits(b):
    out = []

    # ---- span 1 -----------------------------------------------------------
    old = (
        "\t.byte\t0x33, 0x31, 0x50, 0x41, 0x52, 0x54, 0x20, 0x33, 0x32, 0x03, 0x0B, 0x40, 0x26, 0xFF\t; F396D9  |31PART 32..@&.|\n"
        "\n"
        '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0396E7, 0x000046\n')
    new = [byte_line(b, 0xF396D9, 9), ""]
    new += hdr("span1", 0xF396E2, 0xF3972D, SPANS[0]["anchor"], extra=[
        "\xe2\x9a\xa0 THE 398-BYTE EXTENT OF Data_F39559 ABOVE OVERSHOT BY 5 BYTES, and its",
        "  own header said so: \"the extent is the reachability walk's, not the",
        "  object's\".  0xF396E2 is a record start -- prom_b 0xF7E966 does",
        "  `ld XIY,0x00F396E2` then calls T_DLB_Handler_Array8 (`jp 0xF31B57`, the",
        "  interpreter-B op-03 handler).  The string table above it is 32 entries",
        "  of 7 bytes, \"PART 1 \" .. \"PART 32\", ending exactly at 0xF396E2.",
        "  Data_F39559 is therefore 393 bytes, not 398.",
    ])
    new += ["Data_F396E2:"] + render_rec(b, 0xF396E2) + [""]
    new += render_tab(b, 0xF396ED, 8, 8, [0xF396E2])
    out.append((old, "\n".join(new) + "\n"))

    # ---- span 2 -----------------------------------------------------------
    old = ("Data_F3A0E4:\n"
           "\t.byte\t0x04, 0x0B, 0xF6, 0x12, 0xFF\t; F3A0E4  |.....|\n"
           "\n"
           '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03A0E9, 0x0000E6\n')
    new = hdr("span2", 0xF3A0E4, 0xF3A1CF, SPANS[1]["anchor"], extra=[
        "The 5 bytes previously typed here were the head of an 11-byte",
        "interpreter-B op-04 record; the .incbin held its remaining 6 bytes and",
        "the two arrays it and its neighbour 0xF3A0D9 name.",
    ])
    new += ["Data_F3A0E4:"] + render_rec(b, 0xF3A0E4) + [""]
    new += render_tab(b, 0xF3A0EF, 16, 6, [0xF3A0E4]) + [""]
    new += render_tab(b, 0xF3A14F, 16, 8, [0xF39000, 0xF3900B, 0xF3A0D9])
    out.append((old, "\n".join(new) + "\n"))

    # ---- span 3 -----------------------------------------------------------
    lines = [byte_line(b, 0xF3C37D + 16 * i, 16) for i in range(16)]
    old = ("Data_F3C37D:\n" + "\n".join(lines) + "\n"
           "\t.byte\t0xF8\t; F3C47D  |.|\n"
           "\n"
           '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03C47E, 0x000057\n')
    new = hdr("span3", 0xF3C37D, 0xF3C4D5, SPANS[2]["anchor"], extra=[
        "The 257-byte Data_F3C37D was two whole arrays plus the first byte of",
        "the 27th entry of the second one -- again \"the reachability walk's",
        "extent, not the object's\".  Retyped as the two arrays; the label",
        "Data_F3C37D is kept on the first of them, which starts at its address.",
    ])
    new += render_tab(b, 0xF3C37D, 6, 8, [0xF3C367], extra_label="Data_F3C37D") + [""]
    new += render_tab(b, 0xF3C3AD, 37, 8, [0xF3C372])
    out.append((old, "\n".join(new) + "\n"))

    # ---- span 4 -----------------------------------------------------------
    old = ("; --- 0xF3DA77-0xF3DBFF: not converted ---\n"
           '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03DA77, 0x000189\n')
    new = hdr("span4", 0xF3DA77, 0xF3DC00, SPANS[3]["anchor"], extra=[
        "All three records are named from prom_a, which calls the interpreter-B",
        "op-03 handler directly: 0xF81E93, 0xF81EE3 -> 0xF3DA77; 0xF81EAE ->",
        "0xF3DAA2; 0xF81ECC -> 0xF3DAED, each followed by `call T_DLB_Handler_Array8`",
        "(`jp 0xF31B57`).  The first record's own mask/shift (0x0C >> 2) + 1 = 4",
        "equals its array's extent exactly -- the one place in this lane where",
        "the index bound and the measured size agree.",
    ])
    new += ["Data_F3DA77:"] + render_rec(b, 0xF3DA77) + [""]
    new += render_tab(b, 0xF3DA82, 4, 8, [0xF3DA77]) + [""]
    new += ["Data_F3DAA2:"] + render_rec(b, 0xF3DAA2) + [""]
    new += render_tab(b, 0xF3DAAD, 8, 8, [0xF3DAA2]) + [""]
    new += ["Data_F3DAED:"] + render_rec(b, 0xF3DAED) + [""]
    new += render_tab(b, 0xF3DAF8, 33, 8, [0xF3DAED])
    out.append((old, "\n".join(new) + "\n"))

    # ---- span 5 -----------------------------------------------------------
    old = ("\t.byte\t0x2A, 0x2A, 0x91, 0x2A, 0x2A, 0x2A, 0x2A, 0x2A, 0x2A, 0x2A, 0x02, 0x0F, 0x58, 0x26\t; F3DCB1  |**.*******..X&|\n"
           "\n"
           '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03DCBF, 0x000167\n')
    new = [byte_line(b, 0xF3DCB1, 10), ""]
    new += hdr("span5", 0xF3DCBB, 0xF3DE26, SPANS[4]["anchor"], extra=[
        "\xe2\x9a\xa0 NO call site and no 32-bit word anywhere in the four ROMs names",
        "  0xF3DCBB, so these 24 records are framed from the RIGHT: walking",
        "  15-byte op-02 records backward from 0xF3DE23 lands here after exactly",
        "  24 of them and no further -- the byte before is 0x2A, past the 0x24",
        "  opcode bound.  The run is maximal and self-terminating, every record",
        "  has the identical shape, and the source variables (0x2658..0x265F,",
        "  0x1301..0x1310) and screen positions (0x0A51/0x1159/0x1861 + 4k) are",
        "  three clean arithmetic runs of eight.",
        "  Data_F3DC21 above shrinks from 158 to 154 bytes for the same reason",
        "  span 1's blob did: its last 4 bytes were this first record's head.",
    ])
    for i in range(24):
        a = 0xF3DCBB + 15 * i
        new += ["Data_%06X:" % a] + render_rec(b, a)
    new += [""]
    new += render_tab(b, 0xF3DE23, 3, 1, [0xF3D3C3, 0xF3D3E1, 0xF3D3FF, 0xF3DCBB])
    out.append((old, "\n".join(new) + "\n"))

    # ---- the headers this lane overturned ---------------------------------
    # Each is REWRITTEN, not deleted: the historical measurement stays, with
    # what it got wrong and why appended underneath it.
    for label, oldn, newn, why in HEADER_FIXES:
        out.append(header_fix(label, oldn, newn, why))
    for marker in COVER_MARKERS:
        out.append((marker, marker + COVER_NOTE))
    return out


# The four COVER-R1 block headers whose closing verdict -- "Everything else
# here is NOT reachable and stays `.incbin`" -- this lane falsified.  The
# verdict is left in place (it was true of the REACHABILITY WALK, which is what
# it claimed) and answered underneath.
COVER_MARKERS = [
    "; === COVER-R1 0xF39559-0xF3972D ===\n",
    "; === COVER-R1 0xF3A0D9-0xF3A1CF ===\n",
    "; === COVER-R1 0xF3C37D-0xF3C4D5 ===\n",
    "; === COVER-R1 0xF3DC21-0xF3DE26 ===\n",
]
COVER_NOTE = (
    "; \xe2\x9a\xa0 CLOSED 2026-09-02 (lane promB4).  The verdict below -- \"everything\n"
    ";   else is NOT reachable and stays `.incbin`\" -- was true of the round-1\n"
    ";   REACHABILITY WALK and false of the ROM: the remainder is display-list\n"
    ";   operand arrays, reached by pointer from records the walk never enters\n"
    ";   because nothing CALLS them.  0 bytes of this block are `.incbin` now.\n"
    ";   Evidence and regeneration: notes/gen_prom_b_promB4_operand_arrays.py\n")


# The four `Data_Fxxxxxx` headers whose byte count this lane overturned.  Their
# shared 3-line "the rest of this span ... stays `.incbin`" warning is left
# standing: it is the warning that was RIGHT, and following it is what found
# these objects.
HEADER_FIXES = [
    ("F39559", 398, 393,
     "The last 5 bytes were the head of the interpreter-B record at 0xF396E2, "
     "which prom_b 0xF7E966 loads into XIY before calling T_DLB_Handler_Array8.  The "
     "string table here is 32 entries of 7 bytes ending exactly at 0xF396E2."),
    ("F3A0E4", 5, 11,
     "This object was the first 5 bytes of an 11-byte interpreter-B op-04 "
     "record; the .incbin behind it held the rest of the record and the two "
     "operand arrays it and its neighbour 0xF3A0D9 name."),
    ("F3C37D", 257, 48,
     "The 257-byte extent ran through a whole SECOND operand array and one "
     "byte into its 27th entry.  Retyped as the two arrays the records at "
     "0xF3C367 and 0xF3C372 point at; this label stays on the first."),
    ("F3DC21", 158, 154,
     "The last 4 bytes were the head of the interpreter-B record at 0xF3DCBB, "
     "the first of 24 that run to 0xF3DE23."),
]


def header_fix(label, oldn, newn, why):
    """(old, new) for one Data_Fxxxxxx header line: correct the byte count and
    say underneath it what the old number counted and why it was wrong."""
    import textwrap
    old = "; Data_%s -- %d bytes, EMITTED AS DATA (not promoted to code)." % (label, oldn)
    new = "; Data_%s -- %d bytes, EMITTED AS DATA (not promoted to code).\n" % (label, newn)
    new += "; \xe2\x9a\xa0 CORRECTED 2026-09-02 (lane promB4): this header said %d bytes.\n" % oldn
    new += "\n".join(";   " + x for x in textwrap.wrap(why, 72))
    return (old, new)



# ------------------------------------------------------------------ falsify
FALSIFY_OLD = "\t.short 0x0100, 0x006F, 0x0108, 0x007B\t; [32]"
FALSIFY_NEW = "\t.short 0x0101, 0x006F, 0x0108, 0x007B\t; [32]"


def cmd_falsify():
    """Prove the byte gate can SEE an error in what this script emitted.

    Perturbs entry [32] of DLTable_F3DAF8 by one, rebuilds, runs the gate,
    and restores.  Expected: the gate reports
        DIFFERS  wsa1_prom_b.ic13: 1 byte(s), first at 0x3DBF8
    A conversion certified by a gate that cannot go red certifies nothing.
    """
    import subprocess
    t = read_src()
    if t.count(FALSIFY_OLD) != 1:
        print("cannot falsify: the perturbation anchor is not present exactly once")
        return False
    write_src(t.replace(FALSIFY_OLD, FALSIFY_NEW))
    try:
        subprocess.run(["make", "-C", ROOT, "all"], stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, check=False)
        r = subprocess.run([sys.executable,
                            os.path.join(ROOT, "scripts", "analysis",
                                         "assert_byte_identical.py")],
                           cwd=ROOT, capture_output=True, text=True)
        print(r.stdout.strip())
        red = r.returncode != 0
    finally:
        write_src(t)
        subprocess.run(["make", "-C", ROOT, "all"], stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, check=False)
    print("gate went RED on a one-byte perturbation: %s" % red)
    return red


# ------------------------------------------------------------------- filler
def cmd_filler(minrun=64):
    """Where does prom_b's uniform filler start, and is any promB4 span in it?

    The lane brief warns that a span inside or adjacent to the image's `.fill`
    filler is a different question from one in live code.  This reads the runs
    off the ROM itself rather than trusting the source's `.fill` directives.
    """
    b = rom()
    runs, i = [], 0
    while i < len(b):
        j = i
        while j + 1 < len(b) and b[j + 1] == b[i]:
            j += 1
        if j - i + 1 >= minrun:
            runs.append((i, j - i + 1, b[i]))
        i = j + 1
    print("runs of >= %d identical bytes in prom_b: %d, %d bytes total"
          % (minrun, len(runs), sum(n for _o, n, _v in runs)))
    first = runs[0]
    print("lowest such run: 0x%06X +%d of 0x%02X" % first)
    ok = True
    for sp in SPANS:
        off, ln = sp["incbin"]
        inside = [r for r in runs if r[0] < off + ln and off < r[0] + r[1]]
        near = [r for r in runs if abs(r[0] - (off + ln)) < 16 or abs(off - (r[0] + r[1])) < 16]
        print("  %s 0x%06X+%-4d  overlaps %d filler run(s), adjacent to %d"
              % (sp["name"], off, ln, len(inside), len(near)))
        if inside or near:
            ok = False
    print("FILLER: %s" % ("no promB4 span touches filler" if ok else "SOME SPAN TOUCHES FILLER"))
    return ok


if __name__ == "__main__":
    if "--apply" in sys.argv:
        sys.exit(0 if cmd_apply() else 1)
    if "--falsify" in sys.argv:
        sys.exit(0 if cmd_falsify() else 1)
    if "--filler" in sys.argv:
        sys.exit(0 if cmd_filler() else 1)
    sys.exit(0 if cmd_check() else 1)
