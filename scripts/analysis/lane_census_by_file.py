#!/usr/bin/env python3
r"""Per-file census totals for ONE lane of the 2026-09-25 semantic push.

QUESTION THIS ANSWERS
    "How many bytes of the files my lane owns are CODE / KNOWN-A / KNOWN-B /
    UNKNOWN / FILLER, and how many are research targets?" -- the before/after
    figure a lane report must quote, per file and summed.

    Input is a JSON written by scripts/analysis/data_range_census.py --json.
    Ownership is decided by the SAME function the roster check uses
    (scripts/analysis/lane_worklists.py owner()), so a file is counted for a
    lane exactly when the integrator would attribute it to that lane.
    A research target is what lane_worklists.py calls one: grade UNKNOWN, or a
    self-admitting header, or data embedded between two code regions (CODE
    regions excluded).

RUN
    python3 scripts/analysis/data_range_census.py --images tabledata --json X.json
    python3 scripts/analysis/lane_census_by_file.py --json X.json --lane tdata
    python3 scripts/analysis/lane_census_by_file.py --json X.json --lane tdata --knownb 512
        (also list the KNOWN-B objects >= 512 B still left in the lane's files)
"""
import argparse
import collections
import importlib.util
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("lw", os.path.join(HERE, "lane_worklists.py"))
lw = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lw)

GRADES = ("CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", required=True)
    ap.add_argument("--lane", required=True)
    ap.add_argument("--knownb", type=int, default=0,
                    help="also list KNOWN-B regions of at least this many bytes")
    a = ap.parse_args()
    lanes = json.load(open(lw.ROSTER))["lanes"]
    regions = json.load(open(a.json))["regions"]
    per = collections.defaultdict(collections.Counter)
    left = []
    for r in regions:
        path = lw.IMG_ROOT[r["image"]] + r["rel"]
        if lw.owner(path, lanes) != a.lane:
            continue
        g = r["grade"]
        per[path][g] += r["size"]
        if g != "CODE" and (g == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code")):
            per[path]["RESEARCH"] += r["size"]
        if a.knownb and g == "KNOWN-B" and r["size"] >= a.knownb:
            left.append(r)
    cols = GRADES + ("RESEARCH",)
    print("%-52s" % "file" + "".join("%10s" % c for c in cols))
    tot = collections.Counter()
    for path in sorted(per):
        tot.update(per[path])
        print("%-52s" % path + "".join("%10d" % per[path][c] for c in cols))
    print("%-52s" % "TOTAL" + "".join("%10d" % tot[c] for c in cols))
    if a.knownb:
        left.sort(key=lambda r: -r["size"])
        print("\nKNOWN-B regions >= %d B: %d, %d B" % (a.knownb, len(left), sum(r["size"] for r in left)))
        for r in left:
            print("  %-26s:%-6d 0x%06X %7d  %s" % (r["rel"], r["line"] + 1, r["addr"], r["size"], r["label"]))


if __name__ == "__main__":
    main()
