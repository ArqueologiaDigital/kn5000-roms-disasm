#!/usr/bin/env python3
"""lane_nakarest_measure.py -- per-file census figures for the `nakarest` lane.

QUESTION ANSWERED
    "Over the files lane `nakarest` owns (maincpu ui_widgets/* minus the
    nakabig / uimisc exceptions, in v10, v9 and v7), how many bytes does
    data_range_census.py grade KNOWN-A, KNOWN-B, UNKNOWN, CODE, FILLER, and how
    many are research targets?"

INPUT
    A JSON written by  python3 scripts/analysis/data_range_census.py
                          --images v10,v9,v7 --json OUT.json
    (the tree must be built first: `make all`, or the census cannot assemble).

RUN
    python3 scripts/analysis/lane_nakarest_measure.py OUT.json [--per-file]
    python3 scripts/analysis/lane_nakarest_measure.py BEFORE.json AFTER.json

Ownership is read from notes/lanes/ROSTER-2026-09-25.json with the roster's own
precedence rule (the most specific glob wins), so the figure is over exactly the
files the integrator will hold this lane to.
"""
import fnmatch
import json
import os
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
LANE = "nakarest"


def specificity(glob):
    if "*" not in glob:
        return 3
    if "/" in glob and not glob.endswith("/*"):
        return 2
    if "/" in glob:
        return 1
    return 0


def owner_of(rel, roster):
    best = None
    for lane in roster["lanes"]:
        for g in lane.get("maincpu", []):
            if fnmatch.fnmatch(rel, g):
                s = specificity(g)
                if best is None or s > best[0]:
                    best = (s, lane["id"])
    return best[1] if best else None


def mine(rel, roster):
    return owner_of(rel, roster) == LANE


def aggregate(path, roster):
    d = json.load(open(path))
    per = defaultdict(lambda: defaultdict(int))
    tot = defaultdict(int)
    for r in d["regions"]:
        if r["image"] not in ("v10", "v9", "v7"):
            continue
        if not mine(r["rel"], roster):
            continue
        g = r["grade"]
        key = {"A": "KNOWN-A", "B": "KNOWN-B", "C": "UNKNOWN"}.get(g, g)
        per[(r["image"], r["rel"])][key] += r["size"]
        tot[key] += r["size"]
        if r.get("admits") or r.get("embedded_in_code") or g == "C":
            per[(r["image"], r["rel"])]["research"] += r["size"]
            tot["research"] += r["size"]
    return per, tot


COLS = ("CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "research")


def main():
    roster = json.load(open(os.path.join(ROOT, "notes/lanes/ROSTER-2026-09-25.json")))
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    per_file = "--per-file" in sys.argv
    runs = [aggregate(p, roster) for p in args]
    print("%-10s " % "" + " ".join("%10s" % c for c in COLS))
    for p, (per, tot) in zip(args, runs):
        print("%-10s " % os.path.basename(p)[:10] + " ".join("%10d" % tot[c] for c in COLS))
    if per_file:
        per = runs[-1][0]
        before = runs[0][0] if len(runs) > 1 else None
        for k in sorted(per, key=lambda k: -per[k]["KNOWN-B"]):
            row = per[k]
            extra = ""
            if before is not None:
                extra = "   (B before %d)" % before.get(k, {}).get("KNOWN-B", 0)
            print("%-4s %-48s A=%8d B=%8d U=%6d%s" % (k[0], k[1], row["KNOWN-A"],
                                                      row["KNOWN-B"], row["UNKNOWN"], extra))


if __name__ == "__main__":
    main()
