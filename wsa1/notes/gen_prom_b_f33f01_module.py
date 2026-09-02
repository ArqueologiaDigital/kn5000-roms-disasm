#!/usr/bin/env python3
"""What is the 693-byte "Data_F33F01 + .incbin" object right before the
already call-verified DL_F341B6?

QUESTION IT ANSWERS
    `notes/gen_prom_b_cover_round1.py` measured 0xF33F01-0xF341B5 as 693 bytes,
    1 of them reachable (a single `.byte 0x0E` at 0xF33F01, named only because
    code elsewhere loads its address as a 32-bit immediate) and the rest
    `.incbin`. ⚠ THE TRAP this project's brief warns about is right here: a
    naive length-directed walk from 0xF33F01 decodes 44 records of `[op 0x0E,
    len 14]` -- indistinguishable from the ROM's own 0x0E `ret`-padding, which
    is exactly what this is; op 0x0E happens to also be a valid opcode, so the
    walk "succeeds" on pure filler and would have been reported as 44 bogus
    display-list records covering 616 bytes of nothing.

    The real shape, found by measuring runs of the single byte value 0x0E
    directly rather than trusting the op/len walk:
      * 0xF33F01-0xF34000 (255 bytes): a plain 0x0E fill run -- the "Data_F33F01"
        byte plus 254 more identical bytes.  0% of this is display-list content.
      * 0xF34000-0xF341B5 (438 bytes): NOT fill (the run stops dead at 0xF34000),
        and DL.walk() from exactly there frames 27 records with ZERO DRIFT onto
        0xF341B6, the ALREADY CALL-VERIFIED start of DL_F341B6 (see the .s file's
        own "entered at: 0xF341B6" line, several hundred lines below).  Every
        opcode resolves to a documented interpreter-A handler.
    1 + 254 + 438 = 693, matching the cover-round-1 header's own byte count.

VERIFICATION
    --selftest: the fill run's length and the display list's zero-drift framing
    onto the independently-established 0xF341B6 are both recomputed from the
    ROM, not asserted; every opcode is checked against the documented handler
    table.  The byte gate (`make gate-wsa1`) is what actually certifies the
    emitted bytes.

RUN
    python3 notes/gen_prom_b_f33f01_module.py --selftest
    python3 notes/gen_prom_b_f33f01_module.py --show
    python3 notes/gen_prom_b_f33f01_module.py --splice
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL           # noqa: E402
from asm_source import write_part           # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"

FILL_START, FILL_LEN = 0xF33F01, 255
DL_START, DL_END = 0xF34000, 0xF341B6
OLD_INCBIN = '\t.incbin "%s", 0x033F02, 0x0002B4' % ROM

# The block this script replaces: from the Data_F33F01 header comment through
# the old .incbin line, i.e. everything between the COVER-R1 marker and the
# END marker.
BLOCK_START_MARKER = "; === COVER-R1 0xF33F01-0xF341B6 ==="
BLOCK_END_MARKER = "; === END COVER-R1 0xF33F01-0xF341B6 ==="

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-16s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def build_text(b):
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    recs = DL.walk(b, DL_START, DL_END)
    if recs is None:
        raise SystemExit("display list does not frame end to end")
    out = ["; --- 0x%06X-0x%06X: %d bytes of 0x0E fill (ret padding), not a\n"
           "; display list -- a naive op/len walk from here decodes as 44 bogus\n"
           "; [op 0x0E, len 14] records because 0x0E happens to be a valid\n"
           "; opcode; measuring the run of the single repeated byte instead\n"
           "; shows it is pure filler.  notes/gen_prom_b_f33f01_module.py\n"
           % (FILL_START, DL_START - 1, FILL_LEN),
           "\t.fill %d, 1, 0x0E\n\n" % FILL_LEN,
           "; ------------------------------------------------------------------\n",
           "; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter A\n"
           "; the fill run above stops dead here; DL.walk() lands with ZERO\n"
           "; DRIFT on 0x%06X, the ALREADY CALL-VERIFIED start of DL_F341B6\n"
           "; (see its own header below: \"entered at: 0x%06X\").\n"
           % (DL_START, DL_END - 1, len(recs), DL_END - DL_START, DL_END, DL_END),
           "; ------------------------------------------------------------------\n"]
    out.append("DL_%06X:\n" % DL_START)
    out += DL.render(b, recs, hta, set())
    return out, recs


def splice(new_lines):
    path = os.path.join(ROOT, S_FILE)
    text = open(path, encoding="utf-8").read()
    si = text.find(BLOCK_START_MARKER)
    ei = text.find(BLOCK_END_MARKER)
    if si < 0 or ei < 0 or ei < si:
        raise SystemExit("REFUSING: could not locate the COVER-R1 block markers")
    ei_end = ei + len(BLOCK_END_MARKER)
    old_block = text[si:ei_end]
    if OLD_INCBIN not in old_block:
        raise SystemExit("REFUSING: expected .incbin directive not found inside the block")
    new_block = "".join(new_lines).rstrip("\n")
    new_text = text[:si] + new_block + text[ei_end:]
    write_part(path, new_text, root=ROOT, allow_growth=True)


def main():
    a, b = DL.load()

    if "--selftest" in sys.argv:
        print("gen_prom_b_f33f01_module.py --selftest")
        text = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
        check("COVER-R1 block markers present", BLOCK_START_MARKER in text and BLOCK_END_MARKER in text, True)
        check("target .incbin directive present verbatim", OLD_INCBIN in text, True)

        fill_bytes = b[FILL_START - B_BASE: DL_START - B_BASE]
        check("the %d bytes before the display list are all 0x0E" % FILL_LEN,
              all(x == 0x0E for x in fill_bytes), True)
        check("fill run length matches the declared span", len(fill_bytes), FILL_LEN)
        check("the byte right after the fill run is NOT 0x0E (run really stops)",
              b[DL_START - B_BASE] != 0x0E, True)

        recs = DL.walk(b, DL_START, DL_END)
        check("display list frames end-to-end with zero drift", recs is not None, True)
        if recs:
            check("record count", len(recs), 27)
            consumed = sum(ln for _p, _op, ln in recs)
            check("consumed bytes == DL_END - DL_START", consumed, DL_END - DL_START)
            hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
            all_known = all(hta[op] in DL.HANDLERS for _p, op, _ln in recs)
            check("every opcode resolves to a documented interpreter-A handler", all_known, True)
        check("DL_END equals DL_F341B6's already call-verified start", DL_END, 0xF341B6)
        check("total accounted bytes == the cover-round-1 header's own count",
              FILL_LEN + (DL_END - DL_START), 693)
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--show" in sys.argv:
        lines, _ = build_text(b)
        sys.stdout.write("".join(lines))
        return 0

    if "--splice" in sys.argv:
        lines, recs = build_text(b)
        splice(lines)
        print("spliced %d fill bytes + %d records (%d bytes) replacing the whole "
              "0xF33F01-0xF341B5 cover-round-1 block" % (FILL_LEN, len(recs), DL_END - DL_START))
        return 0

    print("usage: --selftest | --show | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
