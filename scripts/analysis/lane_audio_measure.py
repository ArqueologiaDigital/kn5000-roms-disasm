#!/usr/bin/env python3
r"""Per-file before/after figures for lane `audio` of the 2026-09-25 semantic push.

QUESTION THIS ANSWERS
    For every source file the roster (notes/lanes/ROSTER-2026-09-25.json)
    gives to lane `audio`, how many bytes does the data census grade CODE /
    KNOWN-A / KNOWN-B / UNKNOWN / FILLER, how many are RESEARCH TARGETS
    (UNKNOWN, self-admitted, or embedded-in-code -- the same rule
    lane_worklists.py uses), how many data-as-code markers remain
    (halt/incf/decf/ldf/normal/max/min/swi/`jr cc,0`/`jr f`/nop-nop, the
    lane_worklists.py ABS regex), how many numeric branch operands remain
    (`jr/jrl/jp/call/calr/djnz` whose operand is a bare number), and how
    many bytes still enter through v7 romslices.

RUN
    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json X.json
    python3 scripts/analysis/lane_audio_measure.py --census X.json [--lane audio]
    python3 scripts/analysis/lane_audio_measure.py --census AFTER.json --before BEFORE.json \
        --before-rev <commit the BEFORE census was taken at>

    With --before, prints before -> after per file and totals.  The census JSON
    is the input; this script only aggregates it, so the figures are exactly
    as good as the census heuristic (see data_range_census.py's docstring).
"""
import argparse
import collections
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import lane_worklists as lw  # noqa: E402

NUMBR = re.compile(r'^(jr|jrl|jp|call|calr|djnz)\s+(?:[a-z]+\s*,\s*)?(?:[a-z]+\s*,\s*)?(-?(?:0x)?[0-9a-f]+)\s*$')
KEYS = ("CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "RESEARCH", "markers", "numbr", "romslice")


def text_figures(path, rev=None):
    if rev:
        r = subprocess.run(["git", "show", "%s:%s" % (rev, path)], cwd=ROOT, capture_output=True)
        if r.returncode != 0:
            return 0, 0, 0
        L = r.stdout.decode("latin-1").split("\n")
    else:
        L = open(os.path.join(ROOT, path), encoding="latin-1").read().split("\n")
    prev, nabs, nnum, rs = "", 0, 0, 0
    for ln in L:
        c = ln.split(";")[0]
        m = re.search(r'\.incbin\s+"(includes/romslices/[^"]+)"', c)
        if m:
            full = os.path.join(ROOT, "v7/maincpu", m.group(1))
            rs += os.path.getsize(full) if os.path.exists(full) else 0
        cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
        if not cc or cc.startswith("."):
            prev = ""
            continue
        if lw.ABS.match(cc) or (cc == "nop" and prev == "nop"):
            nabs += 1
        if NUMBR.match(cc):
            nnum += 1
        prev = cc
    return nabs, nnum, rs


def figures(census, lane, rev=None):
    lanes = json.load(open(lw.ROSTER))["lanes"]
    own = {p: lw.owner(p, lanes) for p in lw.tracked()}
    mine = sorted(p for p, o in own.items() if o == lane)
    per = collections.defaultdict(collections.Counter)
    for r in json.load(open(census))["regions"]:
        path = lw.IMG_ROOT[r["image"]] + r["rel"]
        if own.get(path) != lane:
            continue
        g = r["grade"]
        per[path][g] += r["size"]
        if (g == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code")) and g != "CODE":
            per[path]["RESEARCH"] += r["size"]
    for p in mine:
        if p.endswith(".s"):
            a, n, rs = text_figures(p, rev)
            per[p]["markers"] += a
            per[p]["numbr"] += n
            per[p]["romslice"] += rs
    return mine, per


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--census", required=True)
    ap.add_argument("--before")
    ap.add_argument("--lane", default="audio")
    ap.add_argument("--before-rev", help="git revision whose sources give the BEFORE text figures")
    a = ap.parse_args()
    mine, after = figures(a.census, a.lane)
    before = figures(a.before, a.lane, a.before_rev)[1] if a.before else None
    print("%-48s " % "file" + " ".join("%10s" % k for k in KEYS))
    tot_a, tot_b = collections.Counter(), collections.Counter()
    for p in mine:
        if not any(after[p].values()) and not (before and any(before[p].values())):
            continue
        tot_a.update(after[p])
        if before:
            tot_b.update(before[p])
            print("%-48s " % p + " ".join("%10s" % ("%d>%d" % (before[p][k], after[p][k])
                                                    if before[p][k] != after[p][k] else after[p][k])
                                          for k in KEYS))
        else:
            print("%-48s " % p + " ".join("%10d" % after[p][k] for k in KEYS))
    print("%-48s " % "TOTAL" + " ".join("%10s" % (("%d>%d" % (tot_b[k], tot_a[k])) if before else tot_a[k])
                                        for k in KEYS))


if __name__ == "__main__":
    main()
