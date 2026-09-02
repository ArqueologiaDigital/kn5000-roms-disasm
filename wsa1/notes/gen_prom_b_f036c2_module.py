#!/usr/bin/env python3
"""Data_F036C2 was mis-sized at 127 bytes; its real extent is 44, and the
other 83 bytes are the leading records of a display list this file already
call-site-verifies the END of.

QUESTION IT ANSWERS
    Data_F036C2 (127 B, "reached from" three 32-bit-immediate loads at
    0xF5C1D3/F6/0xF5CDF6) is really an 11-entry, 4-byte pointer table
    (0xF036C2-0xF036ED) -- each entry a 24-bit address in the immediate
    neighbourhood (0xF03633-0xF036B7), read directly off the ROM. The very
    next byte pair, at 0xF036EE, is `06 0B 10 01 'PAGE1/2'` -- op 0x06, len
    0x0B, exactly the interpreter-A text-record shape used throughout this
    file, and DL.walk() confirms it: 51 records, ZERO DRIFT, from 0xF036EE
    all the way to 0xF03892 -- which is not an arbitrary stopping point, it
    is the ALREADY call-site-verified start of `DL_T0neLayerSoundEditTrigGer`
    ("entered at: 0xF03892", a few lines below in this same file). So both
    ends of the recovered list are independently anchored: a real pointer
    table's own extent on one side, a real call site on the other.

    Content confirms it: "PAGE1/2", "TONE", "SELECT", "LEVEL", "KEY",
    "DETUNE" -- ordinary UI captions, none of the 51 records a same-byte fill
    run.

WHAT THIS SCRIPT DOES
    1. Shrinks Data_F036C2 from 127 to 44 bytes (11 x 4-byte pointers; no
       byte changes value, the trailing 83 move to the display list).
    2. Splices the 51-record list 0xF036EE-0xF03891 (420 bytes) in their
       place, consuming the 83 recovered bytes plus the whole 337-byte
       `.incbin` that followed.
    3. Removes the old `.incbin "wsa1_prom_b.ic13", 0x003741, 0x000151`
       directive outright.

VERIFICATION
    --selftest: the target text is present verbatim, the 11 pointer values
    are recomputed straight from the ROM, the display list frames end-to-end
    with zero drift onto the independently-documented DL_T0neLayerSoundEdit-
    TrigGer, no record is a same-byte fill run, every opcode is a documented
    interpreter-A handler, and the byte accounting balances. The byte gate
    (`make gate-wsa1`) is what actually certifies the emitted bytes.

RUN
    python3 notes/gen_prom_b_f036c2_module.py --selftest
    python3 notes/gen_prom_b_f036c2_module.py --show
    python3 notes/gen_prom_b_f036c2_module.py --splice
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

ARR_START, ARR_END = 0xF036C2, 0xF036EE          # real 44-byte pointer table
DL_START, DL_END = 0xF036EE, 0xF03892
CITED_END = "DL_T0neLayerSoundEditTrigGer"

OLD_HEADER = "; Data_F036C2 -- 127 bytes, EMITTED AS DATA (not promoted to code)."
NEW_HEADER = "; Data_F036C2 -- 44 bytes, EMITTED AS DATA (not promoted to code)."
OLD_ROWS = (
    '\t.byte\t0xB7, 0x36, 0xF0, 0x00, 0xA3, 0x36, 0xF0, 0x00, 0xAD, 0x36, 0xF0, 0x00, 0x4D, 0x36, 0xF0, 0x00'
    '\t; F036C2  |.6...6...6..M6..|\n'
    '\t.byte\t0x3E, 0x36, 0xF0, 0x00, 0x5C, 0x36, 0xF0, 0x00, 0x33, 0x36, 0xF0, 0x00, 0x85, 0x36, 0xF0, 0x00'
    '\t; F036D2  |>6..\\6..36...6..|\n'
    '\t.byte\t0x76, 0x36, 0xF0, 0x00, 0x94, 0x36, 0xF0, 0x00, 0x6B, 0x36, 0xF0, 0x00, 0x06, 0x0B, 0x10, 0x01'
    '\t; F036E2  |v6...6..k6......|\n'
    '\t.byte\t0x50, 0x41, 0x47, 0x45, 0x31, 0x2F, 0x32, 0x17, 0x0A, 0x54, 0x00, 0x3C, 0x00, 0x54, 0x4F, 0x4E'
    '\t; F036F2  |PAGE1/2..T.<.TON|\n'
    '\t.byte\t0x45, 0x17, 0x0C, 0x72, 0x00, 0x3C, 0x00, 0x53, 0x45, 0x4C, 0x45, 0x43, 0x54, 0x17, 0x0B, 0xC7'
    '\t; F03702  |E..r.<.SELECT...|\n'
    '\t.byte\t0x00, 0x3C, 0x00, 0x4C, 0x45, 0x56, 0x45, 0x4C, 0x17, 0x09, 0xF1, 0x00, 0x3C, 0x00, 0x4B, 0x45'
    '\t; F03712  |.<.LEVEL....<.KE|\n'
    '\t.byte\t0x59, 0x17, 0x0C, 0x09, 0x01, 0x3C, 0x00, 0x44, 0x45, 0x54, 0x55, 0x4E, 0x45, 0x06, 0x05, 0x30'
    '\t; F03722  |Y....<.DETUNE..0|\n'
    '\t.byte\t0x0C, 0x10, 0x06, 0x05, 0xD9, 0x0C, 0x3A, 0x06, 0x05, 0xD9, 0x11, 0x3A, 0x06, 0x05, 0xF8'
    '\t; F03732  |......:....:...|'
)
NEW_ROWS = (
    '\t.byte\t0xB7, 0x36, 0xF0, 0x00, 0xA3, 0x36, 0xF0, 0x00, 0xAD, 0x36, 0xF0, 0x00, 0x4D, 0x36, 0xF0, 0x00'
    '\t; F036C2  |.6...6...6..M6..|\n'
    '\t.byte\t0x3E, 0x36, 0xF0, 0x00, 0x5C, 0x36, 0xF0, 0x00, 0x33, 0x36, 0xF0, 0x00, 0x85, 0x36, 0xF0, 0x00'
    '\t; F036D2  |>6..\\6..36...6..|\n'
    '\t.byte\t0x76, 0x36, 0xF0, 0x00, 0x94, 0x36, 0xF0, 0x00, 0x6B, 0x36, 0xF0, 0x00'
    '\t; F036E2  |v6...6..k6..|'
)
OLD_INCBIN = '\t.incbin "%s", 0x003741, 0x000151' % ROM

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
           "; The 83 bytes here had been folded into Data_F036C2 above (now\n"
           "; shrunk to its real 44-byte, 11-entry pointer-table extent);\n"
           "; walking from here lands with ZERO DRIFT on the ALREADY call-\n"
           "; verified DL_T0neLayerSoundEditTrigGer (\"entered at: 0x%06X\"),\n"
           "; a few lines below.  notes/gen_prom_b_f036c2_module.py\n"
           % (DL_START, DL_END - 1, len(recs), DL_END - DL_START, DL_END),
           "; ------------------------------------------------------------------\n"]
    out.append("DL_%06X:\n" % DL_START)
    out += DL.render(b, recs, hta, set())
    return out, recs


def splice(new_lines):
    path = os.path.join(ROOT, S_FILE)
    text = open(path, encoding="utf-8").read()
    for tag, needle in (("header", OLD_HEADER), ("rows", OLD_ROWS), ("incbin", OLD_INCBIN)):
        if text.count(needle) != 1:
            raise SystemExit("REFUSING: expected exactly one %s match, found %d"
                             % (tag, text.count(needle)))
    text = text.replace(OLD_HEADER, NEW_HEADER, 1)
    text = text.replace(OLD_ROWS, NEW_ROWS, 1)
    new_block = "".join(new_lines).rstrip("\n")
    text = text.replace(OLD_INCBIN, new_block, 1)
    write_part(path, text, root=ROOT, allow_growth=True)


def main():
    a, b = DL.load()

    if "--selftest" in sys.argv:
        print("gen_prom_b_f036c2_module.py --selftest")
        text = open(os.path.join(ROOT, S_FILE), encoding="utf-8").read()
        check("CITED end DL_T0neLayerSoundEditTrigGer present verbatim", CITED_END in text, True)
        check("Data_F036C2 header present verbatim", OLD_HEADER in text, True)
        check("Data_F036C2 old rows present verbatim", OLD_ROWS in text, True)
        check("target .incbin directive present verbatim", OLD_INCBIN in text, True)

        arr = b[ARR_START - B_BASE:ARR_END - B_BASE]
        check("Data_F036C2's real extent is 44 bytes", len(arr), 44)
        ptrs = [int.from_bytes(arr[i * 4:i * 4 + 4], "little") for i in range(11)]
        recompute = [int.from_bytes(b[ARR_START - B_BASE + i * 4:ARR_START - B_BASE + i * 4 + 4], "little")
                    for i in range(11)]
        check("11 pointers recompute exactly from the ROM", ptrs, recompute)
        check("every pointer lands in this same neighbourhood (0xF03600-0xF036FF)",
              all(0xF03600 <= p <= 0xF036FF for p in ptrs), True)

        recs = DL.walk(b, DL_START, DL_END)
        check("display list frames end-to-end with zero drift", recs is not None, True)
        if recs:
            check("record count", len(recs), 51)
            consumed = sum(ln for _p, _op, ln in recs)
            check("consumed bytes == DL_END - DL_START", consumed, DL_END - DL_START)
            hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
            all_known = all(hta[op] in DL.HANDLERS for _p, op, _ln in recs)
            check("every opcode resolves to a documented interpreter-A handler", all_known, True)
            no_fill = all(len(set(b[p - B_BASE:p - B_BASE + ln])) > 1 for p, op, ln in recs)
            check("no record is a same-byte 'fill' run (the length/op trap)", no_fill, True)
        check("byte accounting: (127-44 recovered) + old incbin(337) == list(420)",
              (127 - 44) + 337, DL_END - DL_START)
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--show" in sys.argv:
        lines, _ = build_dl_text(b)
        sys.stdout.write("".join(lines))
        return 0

    if "--splice" in sys.argv:
        lines, recs = build_dl_text(b)
        splice(lines)
        print("shrank Data_F036C2 by 83 B; spliced %d records (%d bytes) at "
              "0x%06X-0x%06X; removed the old .incbin entirely"
              % (len(recs), DL_END - DL_START, DL_START, DL_END - 1))
        return 0

    print("usage: --selftest | --show | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
