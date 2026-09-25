#!/usr/bin/env python3
r"""scoop_lane_measure.py -- per-file before/after figures for lane `scoop`.

QUESTION ANSWERED
-----------------
"For each display/*.s file of v10, v9 and v7, how many bytes does the census
grade CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER, how many are RESEARCH
TARGETS, how many data-as-code markers and numeric branch operands does the
source carry, and how many bytes still arrive through a v7 romslice?"

The census half reads a JSON written by scripts/analysis/data_range_census.py
and applies EXACTLY the research-target rule of
scripts/analysis/lane_worklists.py (grade UNKNOWN, or a self-admitted gap, or
data embedded in code; never CODE).  The source half re-derives the marker
count with lane_worklists.py's ABS regex (halt/incf/decf/ldf/normal/max/min/
swi, `jr cc,0`, never-taken `jr f`, nop-nop), counts branch instructions whose
operand is a bare number, and sums the sizes of `.incbin` romslices.

RUN (repo root)
    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json /tmp/x.json
    python3 scripts/analysis/scoop_lane_measure.py --census /tmp/x.json
    python3 scripts/analysis/scoop_lane_measure.py --census after.json --base before.json
"""
import argparse
import collections
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FILES = ["display/scoop_display.s", "display/scoop_editor_data.s", "display/graphics_text_vga.s"]
IMGS = ["v10", "v9", "v7"]
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')
NUMBR = re.compile(r'^\s*(?:[\w.$]+:\s*)?(call|jp|jr|jrl|calr|djnz)\s+(?:[a-z]+\s*,\s*)?'
                   r'(?:x?[a-z]{1,3}\s*,\s*)?(-?(?:0x[0-9a-fA-F]+|\d+))\s*(?:;.*)?$', re.I)


def census(path):
    tot = collections.defaultdict(collections.Counter)
    for r in json.load(open(path))["regions"]:
        if r["image"] not in IMGS or r["rel"] not in FILES:
            continue
        k = (r["image"], r["rel"])
        g = r["grade"]
        tot[k][g] += r["size"]
        if (g == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code")) and g != "CODE":
            tot[k]["RESEARCH"] += r["size"]
    return tot


def source(img, rel):
    p = os.path.join(ROOT, img, "maincpu", rel)
    L = open(p, encoding="latin-1").read().split("\n")
    prev, nabs, nnum, slices = "", 0, 0, 0
    for ln in L:
        c = ln.split(";")[0]
        m = re.search(r'\.incbin\s+"(includes/romslices/[^"]+)"', c)
        if m:
            f = os.path.join(ROOT, img, "maincpu", m.group(1))
            slices += os.path.getsize(f) if os.path.exists(f) else 0
        if NUMBR.match(c):
            nnum += 1
        cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
        if not cc or cc.startswith("."):
            prev = ""
            continue
        if ABS.match(cc) or (cc == "nop" and prev == "nop"):
            nabs += 1
        prev = cc
    return nabs, nnum, slices


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--census", required=True)
    ap.add_argument("--base", help="an earlier census JSON to diff against")
    a = ap.parse_args()
    now = census(a.census)
    base = census(a.base) if a.base else None
    cols = ["CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "RESEARCH"]
    print("%-4s %-24s " % ("img", "file") + " ".join("%9s" % c for c in cols) +
          " %7s %7s %8s" % ("markers", "numbr", "romslice"))
    grand = collections.Counter()
    for img in IMGS:
        for rel in FILES:
            t = now[(img, rel)]
            nabs, nnum, sl = source(img, rel)
            row = " ".join("%9d" % t[c] for c in cols)
            if base:
                b = base[(img, rel)]
                row = " ".join("%9s" % ("%+d" % (t[c] - b[c]) if t[c] != b[c] else ".") for c in cols) \
                    + "  (delta)\n%-29s " % "" + " ".join("%9d" % t[c] for c in cols)
            print("%-4s %-24s %s %7d %7d %8d" % (img, rel, row, nabs, nnum, sl))
            for c in cols:
                grand[c] += t[c]
            grand["markers"] += nabs
            grand["numbr"] += nnum
            grand["romslice"] += sl
    print("TOTAL " + " ".join("%s=%d" % (k, grand[k]) for k in cols + ["markers", "numbr", "romslice"]))


if __name__ == "__main__":
    main()
