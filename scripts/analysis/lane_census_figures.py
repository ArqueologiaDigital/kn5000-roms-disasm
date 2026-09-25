#!/usr/bin/env python3
r"""Census figures for ONE lane's files, before vs after.

QUESTION ANSWERED
    How many bytes of a lane's owned files are CODE / KNOWN-A / KNOWN-B /
    UNKNOWN / FILLER, and how many are research targets (UNKNOWN, self-admitted
    or embedded-in-code -- data_range_census.is_target), per file and in total?
    Given two census JSONs (before, after) it prints both and the delta, plus the
    data-as-code marker count (the same ABS regex as lane_worklists.py) of the
    CURRENT tree for the lane's .s files.

    Ownership comes from notes/lanes/ROSTER-2026-09-25.json via
    scripts/analysis/lane_worklists.py (most specific glob wins), so the file
    set is exactly the one the lane's worklist was generated from.

RUN
    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json A.json   # on the base tree
    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json B.json   # on the lane tree
    python3 scripts/analysis/lane_census_figures.py --lane uimisc --before A.json --after B.json [--per-file]
    python3 scripts/analysis/lane_census_figures.py --lane uimisc --before A.json --tree <base tree>
      (--tree picks the tree whose .s files the data-as-code marker count reads)
"""
import argparse
import collections
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lane_worklists as lw  # noqa: E402

GRADES = ("CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER")


def is_target(r):
    return r["grade"] == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code")


def load(path, lane, lanes):
    j = json.load(open(path))
    per = collections.defaultdict(lambda: collections.Counter())
    for r in j["regions"]:
        root = lw.IMG_ROOT.get(r["image"])
        if not root:
            continue
        full = root + r["rel"]
        if lw.owner(full, lanes) != lane:
            continue
        c = per[full]
        c[r["grade"]] += r["size"]
        if is_target(r):
            c["target"] += r["size"]
    return per


def absurd(lane, lanes, tree):
    out = {}
    for p in lw.tracked():
        if not p.endswith(".s") or lw.owner(p, lanes) != lane:
            continue
        if not os.path.exists(os.path.join(tree, p)):
            continue
        n = 0
        for ln in open(os.path.join(tree, p), encoding="latin-1"):
            s = ln.split(";", 1)[0].strip()
            while re.match(r'^[\w.$]+:', s):
                s = s.split(":", 1)[1].strip()
            if lw.ABS.match(s):
                n += 1
        out[p] = n
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lane", required=True)
    ap.add_argument("--before", required=True)
    ap.add_argument("--after")
    ap.add_argument("--per-file", action="store_true")
    ap.add_argument("--tree", default=lw.ROOT,
                    help="source tree whose .s files the marker count reads (default: this repo)")
    a = ap.parse_args()
    lanes = json.load(open(lw.ROSTER))["lanes"]
    b = load(a.before, a.lane, lanes)
    af = load(a.after, a.lane, lanes) if a.after else None
    cols = GRADES + ("target",)

    def tot(per):
        t = collections.Counter()
        for c in per.values():
            t.update(c)
        return t
    print("%-58s %s" % ("", " ".join("%9s" % c for c in cols)))
    tb = tot(b)
    print("%-58s %s" % ("BEFORE total", " ".join("%9d" % tb[c] for c in cols)))
    if af is not None:
        ta = tot(af)
        print("%-58s %s" % ("AFTER total", " ".join("%9d" % ta[c] for c in cols)))
        print("%-58s %s" % ("delta", " ".join("%+9d" % (ta[c] - tb[c]) for c in cols)))
    if a.per_file:
        for f in sorted(set(b) | set(af or {})):
            cb = b.get(f, collections.Counter())
            line = "%-58s %s" % (f[-58:], " ".join("%9d" % cb[c] for c in cols))
            print(line)
            if af is not None:
                ca = af.get(f, collections.Counter())
                if ca != cb:
                    print("%-58s %s" % ("   -> after", " ".join("%9d" % ca[c] for c in cols)))
    ab = absurd(a.lane, lanes, a.tree)
    print("data-as-code markers (%s, lane .s files): %d" % (a.tree, sum(ab.values())))
    if a.per_file:
        for p, n in sorted(ab.items(), key=lambda t: -t[1]):
            if n:
                print("   %5d %s" % (n, p))


if __name__ == "__main__":
    main()
