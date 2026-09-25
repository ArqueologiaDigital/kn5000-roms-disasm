#!/usr/bin/env python3
r"""Retire prom_a's two big `nop`-run "code" regions as the data they are.

QUESTION THIS ANSWERS
    2,623 of wsa1_prom_a.s's 2,932 data-as-code markers (the lane worklist's
    count) are `nop` following `nop`, and 1,872 of those sit in two runs:

      0xFE7A86-0xFE7FB0  1,323 bytes of 0x00 after the `ret` at 0xFE7A85, up to
                         the module's 0x0E pad (0xFE7FB1-0xFE7FFF)
      0xFF79EA-0xFF7C64  100 bytes of display-list-shaped records, then 535
                         bytes of 0x00, up to the `ret` byte at 0xFF7C65 and the
                         0x0E pad after it

    Are they code?  This checks, and refuses to write if any check fails:
      * the byte before each run is a `ret` (0x0E) the source already frames;
      * no label of the linked ELF lies inside either run;
      * no branch in the source (symbolic, or numeric computed from its guarded
        address) targets an address inside either run;
      * no 32-bit immediate or `.long` in prom_a or prom_b source (hex or
        decimal spelling) names an address inside either run;
      * the zero stretches are exactly 0x00 byte for byte.
    With --apply it rewrites the two runs as `.fill` / `.byte` with a header
    stating what was searched.

RUN
    make gate-wsa1
    python3 notes/proma-2026-09-25/retire_zero_runs.py [--apply]
    make gate-wsa1
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
B = srcmap.BASE
RUNS = [  # (lo, hi_exclusive, [(sublo, subhi, kind)])
    (0xFE7A86, 0xFE7FB1, [(0xFE7A86, 0xFE7FB1, "zero")]),
    (0xFF79EA, 0xFF7C65, [(0xFF79EA, 0xFF7A4E, "bytes"), (0xFF7A4E, 0xFF7C65, "zero")]),
]
BR = re.compile(r'^\s*(?:[A-Za-z_.$][\w.$@]*:\s*)?(jr|jrl|calr|call|jp)\s+(?:([a-z]+)\s*,\s*)?'
                r'(-?0x[0-9a-fA-F]+|-?\d+)\s*$')
SZ = {"jr": 2, "jrl": 3, "calr": 3, "call": 4, "jp": 4}
NUM = re.compile(r'(?<![\w.$])(0x[0-9a-fA-F]+|\d{7,8})(?![\w])')


def check(m):
    rom = m.rom
    addr_of = {i: a for a, i in m.line_at.items()}
    inside = lambda t: any(lo <= t < hi for lo, hi, _ in RUNS)  # noqa: E731
    for lo, hi, subs in RUNS:
        assert rom[lo - 1 - B] == 0x0E, "byte before 0x%06X is not a ret" % lo
        for s, e, k in subs:
            if k == "zero":
                assert set(rom[s - B:e - B]) == {0}, "0x%06X-0x%06X is not all 0x00" % (s, e)
    labs = [(a, n) for a, ns in m.by_addr.items() for n in ns if inside(a)]
    assert not labs, "labels inside: %s" % labs
    for i, l in enumerate(m.lines):
        c = l.split(";")[0]
        mm = BR.match(c)
        if mm and i in addr_of:
            mn, _, num = mm.groups()
            v, a = int(num, 0), addr_of[i]
            if mn in ("call", "jp"):
                t = v
            else:
                if mn == "jr" and v > 127:
                    v -= 256
                if mn in ("jrl", "calr") and v > 32767:
                    v -= 65536
                t = a + SZ[mn] + v
            assert not inside(t), "branch at 0x%06X targets 0x%06X" % (a, t)
    for p in (srcmap.SRC, os.path.join(ROOT, "wsa1/prom_b/wsa1_prom_b.s")):
        for i, l in enumerate(open(p, encoding="latin-1").read().split("\n")):
            code = l.split(";")[0]
            for mm in NUM.finditer(code):
                v = int(mm.group(1), 0)
                assert not inside(v), "%s:%d names 0x%06X" % (p, i + 1, v)


def u8(x):
    return x.encode("utf-8").decode("latin-1")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    m = srcmap.load()
    check(m)
    print("both runs: preceded by ret, no label, no branch target, no immediate/.long in either "
          "image names them, zero stretches exact -- OK")
    if not a.apply:
        return
    rom = m.rom
    L = m.lines
    addr_of = {i: a for a, i in m.line_at.items()}
    out = list(L)
    for lo, hi, subs in reversed(RUNS):
        idx = [i for i, ad in addr_of.items() if lo <= ad < hi]
        i0, i1 = min(idx), max(idx)
        for i in range(i0, i1 + 1):          # every line in the span is a statement of it
            mm = re.search(r';\s*([0-9A-F]{6})\b', L[i])
            assert not L[i].strip() or (mm and lo <= int(mm.group(1), 16) < hi), (i, L[i])
        new = []
        if lo == 0xFE7A86:
            new += ["; ---------------------------------------------------------------------",
                    "; 0xFE7A86-0xFE7FB0 -- 1,323 bytes of 0x00 after this module's last `ret`",
                    ";",
                    "; Was framed as 1,323 `nop` instructions.  It is not code: the byte before",
                    "; it is the `ret` of sub_FE7A73, no label lies inside it, no branch in this",
                    "; source reaches it, and no 32-bit immediate or `.long` in prom_a or prom_b",
                    "; (hex or decimal) names an address in it.  It runs up to the module's 0x0E",
                    "; pad at 0xFE7FB1.  Checked byte by byte: notes/proma-2026-09-25/",
                    "; retire_zero_runs.py (repo root) refuses unless every byte is 0x00.",
                    "; ⚠ Whether it is a zero-initialised table something reaches through a",
                    ";   computed pointer, or linker slack, is not established; no reader is known.",
                    "; ---------------------------------------------------------------------",
                    "\t.fill 1323, 1, 0x00%s; FE7A86" % (" " * 32)]
        else:
            new += ["; ---------------------------------------------------------------------",
                    "; 0xFF79EA-0xFF7C64 -- 100 bytes of display-list-shaped records, then 535",
                    "; bytes of 0x00, after sub_FF79DB's `ret`",
                    ";",
                    "; Was framed as code (`ld W,0x3A / ei 8 / swi 4 / call 0x20208E / ... /",
                    "; normal / normal`, then 535 `nop`).  It is not code: the byte before it is",
                    "; sub_FF79DB's `ret`, no label lies inside, no branch in this source reaches",
                    "; it, and no 32-bit immediate or `.long` in prom_a or prom_b (hex or decimal)",
                    "; names an address in it (notes/proma-2026-09-25/retire_zero_runs.py).",
                    "; The first 100 bytes walk as display-list records -- `06 08`, `0a 0a` x2,",
                    "; `09 0a` x6, `02 0a` from 0xFF79EC, or `20 3a` then `09 0a` x2, `02 0a`",
                    "; from 0xFF79EA -- and both walks land exactly on 0xFF7A4E, where the",
                    "; zeros begin; which start is real is not established, so they stay `.byte`.",
                    "; ⚠ No reader is known for any of it.",
                    "; ---------------------------------------------------------------------"]
            for r in range(0xFF79EA, 0xFF7A4E, 16):
                n = min(16, 0xFF7A4E - r)
                new.append("\t.byte %s  ; %06X" % (", ".join("0x%02x" % x for x in rom[r - B:r - B + n]), r))
            new.append("\t.fill 535, 1, 0x00%s; FF7A4E" % (" " * 33))
        out[i0:i1 + 1] = [u8(x) for x in new]
    open(srcmap.SRC, "w", encoding="latin-1").write("\n".join(out))
    print("applied")


if __name__ == "__main__":
    main()
