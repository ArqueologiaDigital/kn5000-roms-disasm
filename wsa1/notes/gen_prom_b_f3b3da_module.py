#!/usr/bin/env python3
"""Splice DL_F3B3DA -- the "TRACK ASSIGN" screen's display list -- which this
file ALREADY NAMES AND CITES (round 7's entrypoints work, prom_b/wsa1_prom_b.s
around "Screen object F43140") but never converted, because the citation names
the display list's START without ever closing the `.incbin` that held it --
and because the trailing 13 bytes of it had been mis-typed as part of the
DATA object right before it.

QUESTION IT ANSWERS
    The .s file already says, several hundred lines away: "That routine draws
    display list 0xF3B3DA, whose leading op-0x1C records spell 'TRACK
    ASSIGN'" -- backed by a real `ld XIY,0x00F3B3DA` immediate decoded from
    the ROM (inside 0xF7E440, itself still `.incbin`). But 0xF3B3DA falls
    INSIDE the committed `Data_F3B3B2` object (53 bytes, 0xF3B3B2-0xF3B3E6),
    and the `.incbin` right after it starts at 0xF3B3E7 -- 13 bytes further
    on. Neither boundary is where the display list actually starts.

    Data_F3B3B2's REAL extent is 40 bytes, 0xF3B3B2-0xF3B3D9: an 8-byte header
    (0x0000,0x0000,0x0001,0x0001) followed by 4 clean 8-byte (x1,y1,x2,y2)
    coordinate entries (x1=0x0B, x2=0xDF constant; y1/y2 stepping by 0x24) --
    the same idiom as Data_F0D061 and the 0xF29BC6 module's part 3, both
    closed earlier this round. The 13 bytes after that (0xF3B3DA-0xF3B3E6,
    folded into Data_F3B3B2 by a previous round) are in fact the first record
    of the display list ("SONG") plus the leading 5 bytes of its second.

    Walking from 0xF3B3DA with DL.walk(): 53 records, ZERO DRIFT, landing on
    0xF3B5A9 -- the start of the already-committed `Data_F3B5A9` (itself more
    display-list content, left untouched here). Zero of the 53 records is a
    same-byte "fill" record (the trap the lane brief warns about); the text
    reads as ordinary UI captions throughout: "SONG", "TRACK ASSIGN", "TRACK
    L0CAL   MIDI", "ASSIGN  CONTROL OUT CH", "TRACK".

WHAT THIS SCRIPT DOES
    1. Shrinks Data_F3B3B2 from 53 to 40 bytes (drops its trailing 13 bytes,
       which move into the display list below -- a correction, not a
       reinterpretation: no byte changes value).
    2. Splices the 53-record list 0xF3B3DA-0xF3B5A8 (463 bytes) in their
       place, consuming the entire old `.incbin` (450 bytes) plus the 13
       bytes recovered from Data_F3B3B2.
    3. Removes the old `.incbin "wsa1_prom_b.ic13", 0x03B3E7, 0x0001C2`
       directive outright -- nothing is left over; the list runs exactly to
       Data_F3B5A9.

VERIFICATION
    --selftest: the citation text and both target objects are present
    verbatim (so this script breaks loudly if either drifts), Data_F3B3B2's
    real 40-byte extent is a header plus 4 recomputed coordinate entries, the
    walk from 0xF3B3DA frames end-to-end with zero drift onto Data_F3B5A9, no
    record is a same-byte run, every opcode is a documented interpreter-A
    handler, and the byte arithmetic (shrink + list == old incbin + shrink)
    balances. The byte gate (`make gate-wsa1`) is what actually certifies the
    emitted bytes.

RUN
    python3 notes/gen_prom_b_f3b3da_module.py --selftest
    python3 notes/gen_prom_b_f3b3da_module.py --show
    python3 notes/gen_prom_b_f3b3da_module.py --splice
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL           # noqa: E402
from asm_source import write_part           # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"

CITATION = "That routine draws display list 0xF3B3DA, whose leading"
ARR_START, ARR_END = 0xF3B3B2, 0xF3B3DA          # real 40-byte Data_F3B3B2
DL_START, DL_END = 0xF3B3DA, 0xF3B5A9

OLD_HEADER = "; Data_F3B3B2 -- 53 bytes, EMITTED AS DATA (not promoted to code)."
NEW_HEADER = "; Data_F3B3B2 -- 40 bytes, EMITTED AS DATA (not promoted to code)."
OLD_ROW3 = ('\t.byte\t0x0B, 0x00, 0x8C, 0x00, 0xDF, 0x00, 0xAB, 0x00, 0x06, 0x08, 0xC0, 0x00, 0x53, 0x4F, 0x4E, 0x47'
            '\t; F3B3D2  |............SONG|')
NEW_ROW3 = ('\t.byte\t0x0B, 0x00, 0x8C, 0x00, 0xDF, 0x00, 0xAB, 0x00'
            '\t; F3B3D2  |....|')
OLD_ROW4 = '\t.byte\t0x1C, 0x12, 0x60, 0x00, 0x05\t; F3B3E2  |..`..|'
OLD_INCBIN = '\t.incbin "%s", 0x03B3E7, 0x0001C2' % ROM

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-16s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def build_dl_text(b):
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    recs = DL.walk(b, DL_START, DL_END)
    if recs is None:
        raise SystemExit("display list does not frame end to end")
    out = ["\n; ------------------------------------------------------------------\n",
           "; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter A\n"
           "; DL_F3B3DA, the \"TRACK ASSIGN\" screen -- ALREADY NAMED AND CITED\n"
           "; elsewhere in this file (search \"draws display list 0xF3B3DA\"),\n"
           "; from a real `ld XIY,0x00F3B3DA` immediate inside 0xF7E440 (still\n"
           "; .incbin).  Its first 13 bytes had been folded into Data_F3B3B2\n"
           "; above (now shrunk to its real 40-byte extent); walking from here\n"
           "; lands with ZERO DRIFT on Data_F3B5A9, already committed below.\n"
           "; notes/gen_prom_b_f3b3da_module.py\n"
           % (DL_START, DL_END - 1, len(recs), DL_END - DL_START),
           "; ------------------------------------------------------------------\n"]
    out.append("DL_F3B3DA:\n")
    out += DL.render(b, recs, hta, set())
    return out, recs


def splice(new_lines):
    path = os.path.join(ROOT, S_FILE)
    text = open(path, encoding="utf-8").read()
    for tag, needle in (("header", OLD_HEADER), ("row3", OLD_ROW3),
                        ("row4", OLD_ROW4), ("incbin", OLD_INCBIN)):
        if text.count(needle) != 1:
            raise SystemExit("REFUSING: expected exactly one %s match, found %d"
                             % (tag, text.count(needle)))
    text = text.replace(OLD_HEADER, NEW_HEADER, 1)
    text = text.replace(OLD_ROW3, NEW_ROW3, 1)
    text = text.replace("\n" + OLD_ROW4, "", 1)
    new_block = "".join(new_lines).rstrip("\n")
    text = text.replace(OLD_INCBIN, new_block, 1)
    write_part(path, text, root=ROOT, allow_growth=True)


def main():
    a, b = DL.load()

    if "--selftest" in sys.argv:
        print("gen_prom_b_f3b3da_module.py --selftest")
        text = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
        check("the round-7 citation is still present verbatim", CITATION in text, True)
        check("Data_F3B3B2 header present verbatim", OLD_HEADER in text, True)
        check("Data_F3B3B2 row 3 present verbatim", OLD_ROW3 in text, True)
        check("Data_F3B3B2 row 4 present verbatim", OLD_ROW4 in text, True)
        check("target .incbin directive present verbatim", OLD_INCBIN in text, True)

        arr = b[ARR_START - B_BASE:ARR_END - B_BASE]
        check("Data_F3B3B2's real extent is 40 bytes", len(arr), 40)
        header = struct.unpack_from("<4H", arr, 0)
        check("its header is (0,0,1,1)", header, (0, 0, 1, 1))
        ents = [struct.unpack_from("<4H", arr, 8 + i * 8) for i in range(4)]
        check("4 coordinate entries share x1=0x0B, x2=0xDF",
              [(e[0], e[2]) for e in ents], [(0x0B, 0xDF)] * 4)
        check("y1 steps by 0x24 across the 4 entries",
              [ents[i][1] - ents[i - 1][1] for i in range(1, 4)], [0x24] * 3)
        check("y2 steps by 0x24 across the 4 entries",
              [ents[i][3] - ents[i - 1][3] for i in range(1, 4)], [0x24] * 3)

        recs = DL.walk(b, DL_START, DL_END)
        check("display list frames end-to-end with zero drift", recs is not None, True)
        if recs:
            check("record count", len(recs), 53)
            consumed = sum(ln for _p, _op, ln in recs)
            check("consumed bytes == DL_END - DL_START", consumed, DL_END - DL_START)
            hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
            all_known = all(hta[op] in DL.HANDLERS for _p, op, _ln in recs)
            check("every opcode resolves to a documented interpreter-A handler", all_known, True)
            no_fill = all(len(set(b[p - B_BASE:p - B_BASE + ln])) > 1 for p, op, ln in recs)
            check("no record is a same-byte 'fill' run (the length/op trap)", no_fill, True)
        check("DL_END lands exactly on Data_F3B5A9, already committed", DL_END, 0xF3B5A9)
        check("byte accounting: (53-40 recovered) + old incbin(450) == list(463)",
              (53 - 40) + 450, DL_END - DL_START)
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--show" in sys.argv:
        lines, _ = build_dl_text(b)
        sys.stdout.write("".join(lines))
        return 0

    if "--splice" in sys.argv:
        lines, recs = build_dl_text(b)
        splice(lines)
        print("shrank Data_F3B3B2 by 13 B; spliced %d records (%d bytes) at "
              "0x%06X-0x%06X; removed the old .incbin entirely"
              % (len(recs), DL_END - DL_START, DL_START, DL_END - 1))
        return 0

    print("usage: --selftest | --show | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
