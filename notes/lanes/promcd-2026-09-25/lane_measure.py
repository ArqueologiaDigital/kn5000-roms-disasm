#!/usr/bin/env python3
r"""Per-file census figures for ONE lane of the 2026-09-25 semantic push.

QUESTION THIS ANSWERS
    For the files a lane owns (notes/lanes/ROSTER-2026-09-25.json), how many
    bytes does scripts/analysis/data_range_census.py grade CODE / KNOWN-A /
    KNOWN-B / UNKNOWN / FILLER, how many are RESEARCH TARGETS (UNKNOWN, or
    self-admitted, or embedded-in-code, and not CODE -- the same rule as
    scripts/analysis/lane_worklists.py), and how many data-as-code markers
    (halt/incf/decf/ldf/normal/max/min/swi, jr cc,0, jr f, nop-nop -- the same
    regex as lane_worklists.py) does each file contain?

    Given two census JSONs it prints a before/after table per file.

RUN
    python3 scripts/analysis/data_range_census.py --images prom_a,prom_c,prom_d --json B.json
    ... edit ...
    python3 scripts/analysis/data_range_census.py --images prom_a,prom_c,prom_d --json A.json
    python3 notes/lanes/promcd-2026-09-25/lane_measure.py --lane promcd B.json [A.json]

    Shared files (wsa1/kernel/kernel.s, wsa1/dsp/dsp_channel_regs.s) are
    counted once PER IMAGE that includes them, as the census reports them.
"""
import argparse
import collections
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import lane_worklists as LW  # noqa: E402

GRADES = ("CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "RESEARCH")


def per_file(census, lane, own):
    tot = collections.defaultdict(collections.Counter)
    for r in json.load(open(census))["regions"]:
        path = LW.IMG_ROOT[r["image"]] + r["rel"]
        if own.get(path) != lane:
            continue
        g = r["grade"]
        tot[path][g] += r["size"]
        tgt = g == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code")
        if tgt and g != "CODE":
            tot[path]["RESEARCH"] += r["size"]
    return tot


def markers(path):
    L = open(os.path.join(ROOT, path), encoding="latin-1").read().split("\n")
    prev, n = "", 0
    for ln in L:
        c = ln.split(";")[0]
        cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
        if not cc or cc.startswith("."):
            prev = ""
            continue
        if LW.ABS.match(cc) or (cc == "nop" and prev == "nop"):
            n += 1
        prev = cc
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lane", required=True)
    ap.add_argument("census", nargs="+")
    a = ap.parse_args()
    lanes = json.load(open(LW.ROSTER))["lanes"]
    own = {p: LW.owner(p, lanes) for p in LW.tracked()}
    runs = [per_file(c, a.lane, own) for c in a.census]
    files = sorted(set().union(*[set(r) for r in runs]))
    hdr = "%-52s" % "file" + "".join("%12s" % g for g in GRADES)
    for i, r in enumerate(runs):
        print("== %s" % a.census[i])
        print(hdr)
        tot = collections.Counter()
        for f in files:
            print("%-52s" % f[5:] + "".join("%12d" % r[f][g] for g in GRADES))
            tot.update(r[f])
        print("%-52s" % "TOTAL" + "".join("%12d" % tot[g] for g in GRADES))
    if len(runs) == 2:
        print("== delta (after - before), files that moved")
        print(hdr)
        for f in files:
            d = [runs[1][f][g] - runs[0][f][g] for g in GRADES]
            if any(d):
                print("%-52s" % f[5:] + "".join("%+12d" % x for x in d))
    print("== data-as-code markers (current tree)")
    mine = sorted(p for p, o in own.items() if o == a.lane and p.endswith(".s"))
    t = 0
    for p in mine:
        n = markers(p)
        t += n
        if n:
            print("  %-60s %5d" % (p, n))
    print("  %-60s %5d" % ("TOTAL", t))


if __name__ == "__main__":
    main()
