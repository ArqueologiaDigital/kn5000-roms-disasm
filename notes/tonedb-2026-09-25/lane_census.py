#!/usr/bin/env python3
"""Census grades aggregated over the tonedb lane's four files.

QUESTION THIS ANSWERS
    How many bytes of table_data/style_records.s and table_data/tone_database_*.s
    does scripts/analysis/data_range_census.py grade KNOWN-A / KNOWN-B /
    UNKNOWN / FILLER, and how many are research targets (self-admitted,
    embedded-in-code, or unexplained)?  It is the before/after instrument quoted
    in this lane's commits and report.

RUN
    python3 scripts/analysis/data_range_census.py --images tabledata --json X.json
    python3 notes/tonedb-2026-09-25/lane_census.py X.json [Y.json]
    With two files it prints both and the difference.  Needs a built tree
    (the census assembles the image).
"""
import collections
import json
import sys

FILES = ["style_records.s", "tone_database_aux.s", "tone_database_directory.s",
         "tone_database_records.s"]
COLS = ["KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "CODE", "research"]


def agg(path):
    d = json.load(open(path))
    out = {f: collections.Counter() for f in FILES}
    for r in d["regions"]:
        f = r["rel"].rsplit("/", 1)[-1]
        if f not in out:
            continue
        out[f][r["grade"]] += r["size"]
        if r.get("admits") or r.get("embedded_in_code") or r["grade"] == "UNKNOWN":
            out[f]["research"] += r["size"]
    out["TOTAL"] = sum(out.values(), collections.Counter())
    return out


def show(title, a):
    print(title)
    print("  %-28s" % "file" + "".join("%10s" % c for c in COLS))
    for f in FILES + ["TOTAL"]:
        print("  %-28s" % f + "".join("%10d" % a[f][c] for c in COLS))


def main():
    runs = [agg(p) for p in sys.argv[1:]]
    for p, a in zip(sys.argv[1:], runs):
        show(p, a)
    if len(runs) == 2:
        b, a = runs
        print("delta (second - first)")
        for f in FILES + ["TOTAL"]:
            print("  %-28s" % f + "".join("%+10d" % (a[f][c] - b[f][c]) for c in COLS))


if __name__ == "__main__":
    main()
