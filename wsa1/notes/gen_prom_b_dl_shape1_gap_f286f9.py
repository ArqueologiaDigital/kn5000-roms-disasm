#!/usr/bin/env python3
"""Splice the one remaining shape-1 display-list site prom_b_dl_call_shapes.py
found still `.incbin`: 0xF286F9-0xF28724 (44 bytes), called from prom_a site
0xF90FBB.

QUESTION IT ANSWERS
    `notes/prom_b_dl_call_shapes.py --sites` lists exactly one shape-1
    (`ld XIY,<start> / ld XIX,<end> / call 0xF417F0/0xF417F4`) site whose
    (start, end) FRAMES and is still `.incbin`: site 0xF90FBB in prom_a names
    0xF286F9-0xF28724.  Every other shape-1 site is either already converted
    or does not frame.  This is the emitter for that one site: four ordinary
    interpreter-A records (op 0x03, handler 0xF31ABE, the same handler already
    committed elsewhere in this file), nothing new.

VERIFICATION
    --selftest re-derives the site from prom_a's own bytes (not typed in by
    hand), confirms it frames to exactly 44 bytes in 4 records, and round-trips
    every record's (op, len) against the ROM.  The byte gate (make gate-wsa1)
    is the real certification.

RUN
    python3 notes/gen_prom_b_dl_shape1_gap_f286f9.py --selftest
    python3 notes/gen_prom_b_dl_shape1_gap_f286f9.py --splice
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_b_display_lists as DL      # noqa: E402
from asm_source import write_part      # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"
SITE = 0xF90FBB          # the prom_a call site (RUN_A: ld XIY,s / ld XIX,e / call 0xF417F4)
S, E = 0xF286F9, 0xF28725

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-56s %-14s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def main():
    a, b = DL.load()
    sites = DL.call_sites(a, b)
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]

    if "--selftest" in sys.argv:
        print("gen_prom_b_dl_shape1_gap_f286f9.py --selftest")
        check("site (S, E, *) is a real committed-scanner call site",
              any(s == S and e == E for s, e, _t in sites), True)
        recs = DL.walk(b, S, E)
        check("frames exactly", recs is not None, True)
        check("record count", len(recs), 4)
        check("total bytes", sum(ln for _p, _op, ln in recs), E - S)
        for p, op, ln in recs:
            raw = b[p - B_BASE:p - B_BASE + ln]
            check("  0x%06X (op,len) round-trips" % p, (raw[0], raw[1]), (op, ln))
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    recs = DL.walk(b, S, E)
    text = DL.render(b, recs, hta, {S})

    if "--splice" in sys.argv:
        path = os.path.join(ROOT, S_FILE)
        lines = open(path, encoding="utf-8").read().split("\n")
        target = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, 0x0286CC, 0x000136)
        idx = [i for i, ln in enumerate(lines) if ln.strip() == target.strip()]
        if len(idx) != 1:
            raise SystemExit("expected exactly one directive matching the span, found %d" % len(idx))
        i = idx[0]
        pre_off, pre_size = 0x0286CC, S - B_BASE - 0x0286CC
        post_off, post_size = E - B_BASE, (0x0286CC + 0x000136) - (E - B_BASE)
        block = []
        if pre_size:
            block.append('\t.incbin "%s", 0x%06X, 0x%06X\n' % (ROM, pre_off, pre_size))
        block.append("\n; ------------------------------------------------------------------\n")
        block.append("; 0x%06X-0x%06X -- 4 display-list records, 44 bytes -- interpreter A\n"
                     "; the one remaining shape-1 site notes/prom_b_dl_call_shapes.py found\n"
                     "; still `.incbin` (site 0x%06X in prom_a).  Regenerate:\n"
                     "; python3 notes/gen_prom_b_dl_shape1_gap_f286f9.py --splice\n"
                     % (S, E - 1, SITE))
        block.append("; ------------------------------------------------------------------\n")
        block += text
        if post_size:
            block.append('\n\t.incbin "%s", 0x%06X, 0x%06X\n' % (ROM, post_off, post_size))
        before_ctx = lines[:i] + lines[i + 1:]
        new_block = "".join(block).rstrip("\n").split("\n")
        out_lines = lines[:i] + new_block + lines[i + 1:]
        after_ctx = out_lines[:i] + out_lines[i + len(new_block):]
        if after_ctx != before_ctx:
            raise SystemExit("REFUSING TO SPLICE: context outside the target directive moved")
        write_part(path, "\n".join(out_lines), root=ROOT, allow_growth=True)
        print("spliced 4 records, 44 bytes into %s" % S_FILE)
        return 0

    print("usage: --selftest | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
