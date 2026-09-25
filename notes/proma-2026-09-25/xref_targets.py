#!/usr/bin/env python3
r"""Who names an address inside each prom_a research target -- in EITHER image's source?

QUESTION THIS ANSWERS
    The data census (scripts/analysis/data_range_census.py) lists prom_a
    regions whose headers admit their reader is unknown.  Several of those
    admissions were written after a search of prom_a's own text for HEX
    spellings -- but prom_b's source spells most 32-bit immediates in DECIMAL
    (`ld xiy, 16531456` for 0x00FC4000), so a hex grep over both images is blind
    to every prom_b reader.  This lists, per target, every statement in
    wsa1/prom_a/wsa1_prom_a.s and wsa1/prom_b/wsa1_prom_b.s whose OPERAND holds a
    number (hex or decimal) inside [lo, hi), plus -- separately, because it is
    noisier -- numbers in [lo-0x100, lo), the `TABLE - 4*k` dispatcher idiom the
    lane brief warns about.

    Forms searched: an operand literal of an instruction, and a `.long` value.
    NOT searched: pointers assembled from two 16-bit halves, a base computed in a
    register from another base, a pointer stored in RAM -- a negative from this
    tool is only a negative for the forms listed here.

RUN
    python3 scripts/analysis/data_range_census.py --images prom_a --json /tmp/x.json
    python3 notes/proma-2026-09-25/xref_targets.py --census /tmp/x.json [--min 64]
"""
import argparse
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRCS = {"prom_a": os.path.join(ROOT, "wsa1/prom_a/wsa1_prom_a.s"),
        "prom_b": os.path.join(ROOT, "wsa1/prom_b/wsa1_prom_b.s")}
NUM = re.compile(r'(?<![\w.$])(0x[0-9a-fA-F]+|\d{7,8})(?![\w])')
ADDR = re.compile(r';\s*([0-9A-F]{6})\b')


def refs():
    out = []
    for img, p in SRCS.items():
        for i, l in enumerate(open(p, encoding="latin-1").read().split("\n")):
            code = l.split(";")[0]
            s = code.strip()
            if not s or s.startswith((".byte", ".ascii", ".fill", ".zero", ".space", ".short", ".word")):
                continue
            m = ADDR.search(l)
            site = int(m.group(1), 16) if m else None
            for mm in NUM.finditer(code):
                v = int(mm.group(1), 0)
                if 0xF80000 <= v <= 0xFFFFFF:
                    out.append((v, img, i + 1, site, s[:70]))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--census", required=True)
    ap.add_argument("--min", type=int, default=0)
    a = ap.parse_args()
    regs = json.load(open(a.census))["regions"]
    tg = [r for r in regs if r["image"] == "prom_a" and r["rel"] == "prom_a/wsa1_prom_a.s"
          and r["grade"] != "CODE" and (r["grade"] == "UNKNOWN" or r.get("admits")
                                        or r.get("embedded_in_code")) and r["size"] >= a.min]
    tg.sort(key=lambda r: -r["size"])
    R = refs()
    for r in tg:
        lo = 0xF80000 + r["lo"]
        hi = 0xF80000 + r["hi"]
        inside = [x for x in R if lo <= x[0] < hi and not (x[1] == "prom_a" and x[3] is not None
                                                          and lo <= x[3] < hi)]
        below = [x for x in R if lo - 0x100 <= x[0] < lo and x[1] != "prom_a" or
                 (lo - 0x100 <= x[0] < lo and x[1] == "prom_a" and "add" in x[4])]
        print("%06X-%06X %5d %-34s inside:%d below:%d" % (lo, hi, r["size"], r["label"],
                                                           len(inside), len(below)))
        for v, img, ln, site, s in inside[:12]:
            print("      %-6s %06X  %s:%d  %s" % (img, v, img, ln, s))
        if len(inside) > 12:
            print("      ... %d more" % (len(inside) - 12))


if __name__ == "__main__":
    main()
