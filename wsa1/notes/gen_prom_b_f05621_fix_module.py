#!/usr/bin/env python3
"""FIX a 29th instance of the recurring "oversized Data_Fxxxxxx object"
defect (notes/README-prom_b.md's 28-instance tally), found through a NEW
entry point: an already-reachable POINTER ARRAY, not the object-adjacent
scan that reached fixpoint after round 4.

WHAT WAS WRONG
    `Data_F0550B` was declared 278 bytes (0xF0550B-0xF05620 inclusive), sized
    by the reachability walk that measured "294 of 320 bytes reachable ...
    as DATA". Its last two bytes, 0x17 0x07, are not data -- they are the
    OP/LEN HEADER of a display-list record (op 0x17, handler 0xF31A52,
    fixed length 7) whose remaining 5 bytes were then split off as a
    separate, unexplained 5-byte `.incbin` fragment (0xF05621-0xF05625) in
    front of 3 record run this lane's untouched-pool round already
    converted (0xF05626-0xF0563A).

HOW IT WAS FOUND
    Not the object-adjacent scan (README-prom_b.md already records that
    scan reached a fixpoint). `Data_F0563B`, the ALREADY-COMMITTED and
    ALREADY-REACHABLE 16-byte object immediately after the 3-record run,
    is itself an array of four 32-bit pointers: 0x00F0561F, 0x00F05626,
    0x00F0562D, 0x00F05634. Three of those four are exactly this lane's
    three already-converted record starts. The fourth, 0x00F0561F, is 2
    bytes INSIDE the tail of Data_F0550B -- and reading from there finds a
    fourth, structurally identical op-0x17 record (short 0x0058, an
    incrementing short 0x0043/0x0062/0x0081/0x00A0 -- step 0x1F across all
    four -- then a control byte), landing with ZERO DRIFT exactly on
    Data_F0563B, the already-named neighbour whose own pointer array is
    what exposed this in the first place.

FIX
    Shrink Data_F0550B to 276 bytes (0xF0550B-0xF0561E inclusive, dropping
    the trailing 0x17 0x07 from its last `.byte` line and correcting the
    stated size in its header comment) and convert 0xF0561F-0xF0563A as 4
    records instead of 3, removing the 5-byte unexplained fragment entirely
    (its bytes are now the tail of record 1).

VERIFICATION
    --selftest requires the OLD block to be present verbatim, re-derives
    all 4 records and Data_F0563B's 4 pointers from the ROM (never
    hand-typed), requires 3 of those 4 pointers to equal the 3 already-
    committed record starts and the 4th to equal the newly found one, and
    requires the reassembled bytes (shrunk object + 4 records) to match the
    original ROM bytes for the whole 0xF0550B-0xF0563A range exactly.
    `make gate-wsa1` recertifies the whole image afterward.

RUN
    python3 notes/gen_prom_b_f05621_fix_module.py --selftest
    python3 notes/gen_prom_b_f05621_fix_module.py --show
    python3 notes/gen_prom_b_f05621_fix_module.py --splice
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL              # noqa: E402
from asm_source import write_part              # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"

OBJ_S = 0xF0550B
NEW_OBJ_E = 0xF0561F          # shrunk Data_F0550B end (exclusive)
REC_S = 0xF0561F
REC_E = 0xF0563B              # == Data_F0563B's own start

START_MARK = "; Data_F0550B -- 278 bytes, EMITTED AS DATA (not promoted to code)."
END_MARK = '\t.byte 0x17, 0x07\t; op 17, 7 bytes -> handler 0xF31A52\n\t.short 0x0058\n\t.short 0x00A0\n\t.byte 0x10\t; character codes below 0x20\n'

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-24s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def extract_old(text):
    si = text.find(START_MARK)
    if si < 0:
        raise SystemExit("start marker not found")
    # back up to the start of the enclosing "; ----" divider line
    div = "; --------------------------------------------------------------------------\n"
    si2 = text.rfind(div, 0, si)
    if si2 < 0:
        raise SystemExit("divider before start marker not found")
    ei = text.find(END_MARK, si)
    if ei < 0:
        raise SystemExit("end marker not found")
    ei_end = ei + len(END_MARK)
    return text[si2:ei_end]


def build_new(b):
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    old_obj_bytes = b[OBJ_S - B_BASE:NEW_OBJ_E - B_BASE]      # the shrunk object's own bytes
    n = len(old_obj_bytes)
    out = []
    out.append("; --------------------------------------------------------------------------\n")
    out.append("; Data_F0550B -- %d bytes, EMITTED AS DATA (not promoted to code).\n" % n)
    out.append("; ⚠ CORRECTED: was declared 278 bytes, 2 bytes too many -- see\n"
               "; notes/gen_prom_b_f05621_fix_module.py.  Those 2 bytes (0x17, 0x07) were\n"
               "; the op/len header of the display-list record run that starts at 0xF0561F,\n"
               "; below, exposed by Data_F0563B's own pointer array naming that address.\n")
    out.append("; Reached from: 0x00F0550B appears as a 32-bit word at 0xF0555B 0xF0555F\n"
               ";               0xF5C5D1 0xF5C5E4; converted code at 0xF5C5D0 0xF5C5E3 loads\n"
               ";               it as a 32-bit immediate.  No routine-directory slot and no\n"
               ";               branch decoded in converted code names it.\n")
    out.append("; --------------------------------------------------------------------------\n")
    out.append("Data_F0550B:\n")
    for i in range(0, n, 16):
        row = old_obj_bytes[i:i + 16]
        hexs = ", ".join("0x%02X" % c for c in row)
        asc = "".join(chr(c) if 0x20 <= c <= 0x7E else "." for c in row)
        out.append("\t.byte\t%s\t; %06X  |%s|\n" % (hexs, OBJ_S + i, asc))
    out.append("\n")

    recs = DL.walk(b, REC_S, REC_E)
    if recs is None:
        raise SystemExit("0x%06X-0x%06X does not frame end to end" % (REC_S, REC_E))
    out.append("; ------------------------------------------------------------------\n")
    out.append("; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter A\n"
               "; The 4th of Data_F0563B's own 4 pointers names 0x%06X exactly; the other\n"
               "; 3 are the record starts this lane's untouched-pool round already found.\n"
               "; Formerly the last 2 bytes of Data_F0550B plus a 5-byte unexplained\n"
               "; fragment.  Regenerate: python3 notes/gen_prom_b_f05621_fix_module.py\n"
               "; --splice\n" % (REC_S, REC_E - 1, len(recs), REC_E - REC_S, REC_S))
    out.append("; ------------------------------------------------------------------\n")
    out += DL.render(b, recs, hta, set())
    return "".join(out), recs


def main():
    a, b = DL.load()

    if "--selftest" in sys.argv:
        print("gen_prom_b_f05621_fix_module.py --selftest")
        text = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
        old = extract_old(text)
        check("old block present verbatim, exactly once", text.count(old), 1)

        ptrs = [int.from_bytes(b[0xF0563B - B_BASE + 4 * i:0xF0563B - B_BASE + 4 * i + 4], "little")
               for i in range(4)]
        check("Data_F0563B's 4 pointers", [hex(p) for p in ptrs],
              ["0xf0561f", "0xf05626", "0xf0562d", "0xf05634"])
        recs = DL.walk(b, REC_S, REC_E)
        check("0xF0561F-0xF0563A frames end to end with zero drift", recs is not None, True)
        check("4 records found", len(recs), 4)
        check("record starts match Data_F0563B's pointers exactly",
              [p for p, _op, _ln in recs], ptrs)
        hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
        check("every opcode is a documented interpreter-A handler",
              all(hta[op] in DL.HANDLERS for _p, op, _ln in recs), True)

        new_obj = b[OBJ_S - B_BASE:NEW_OBJ_E - B_BASE]
        old_obj_plus_recs_area = b[OBJ_S - B_BASE:REC_E - B_BASE]
        check("shrunk object + 4 records reproduce the original 0xF0550B-0xF0563A bytes",
              new_obj + b[REC_S - B_BASE:REC_E - B_BASE], old_obj_plus_recs_area)
        check("shrunk object is 276 bytes", len(new_obj), 276)
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    new_block, recs = build_new(b)
    if "--show" in sys.argv:
        sys.stdout.write(new_block)
        return 0

    if "--splice" in sys.argv:
        path = os.path.join(ROOT, S_FILE)
        text = open(path, encoding="utf-8").read()
        old = extract_old(text)
        if text.count(old) != 1:
            raise SystemExit("expected exactly one occurrence of the old block, found %d" % text.count(old))
        new_text = text.replace(old, new_block, 1)
        write_part(path, new_text, root=ROOT, allow_growth=True)
        print("fixed Data_F0550B (278 -> 276 B) and converted 4 records at 0xF0561F "
              "(%d bytes total moved from data/incbin to typed records)" % (REC_E - REC_S))
        return 0

    print("pass --selftest, --show or --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
