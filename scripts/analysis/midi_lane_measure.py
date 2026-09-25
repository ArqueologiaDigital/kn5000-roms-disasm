#!/usr/bin/env python3
r"""Per-file before/after figures for the midi lane (2026-09-25 semantic push).

QUESTION ANSWERED
-----------------
For the 27 files the `midi` lane owns (`{v10,v9,v7}/maincpu/midi/*.s`), how many
bytes does the data census put in each grade (CODE / KNOWN-A / KNOWN-B /
UNKNOWN / research target), how many data-as-code MARKERS remain, and how many
NUMERIC branch operands remain?

  * grades and research targets come from a census JSON written by
    `scripts/analysis/data_range_census.py --images v10,v9,v7 --json X.json`
    (field `grade`; a research target is what that script's `is_target()` says);
  * markers use the exact regex of `scripts/analysis/lane_worklists.py`
    (halt/incf/decf/ldf/normal/max/min/swi, `jr cc,0`, `jr f,`, nop-nop);
  * numeric branches use the one-liner of
    `scripts/converters/README-symbolize-branches.md`.

RUN
    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json /tmp/x.json
    python3 scripts/analysis/midi_lane_measure.py --census /tmp/x.json
"""
import argparse
import collections
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)

ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')
NUMBR = re.compile(r'^\s*(\S+:)?\s*(jr|jrl|calr|call|jp|djnz)\s+([a-z]+,\s*)?(-?[0-9]+|0x[0-9a-fA-F]+)\s*(;.*)?$')


def markers(path):
    L = open(path, encoding="latin-1").read().split("\n")
    prev, n, nb = "", 0, 0
    for ln in L:
        if NUMBR.match(ln):
            nb += 1
        c = ln.split(";")[0]
        cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
        if not cc or cc.startswith("."):
            prev = ""
            continue
        if ABS.match(cc) or (cc == "nop" and prev == "nop"):
            n += 1
        prev = cc
    return n, nb


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--census")
    a = ap.parse_args()
    files = sorted(glob.glob(os.path.join(ROOT, "v*/maincpu/midi/*.s")))
    grades = collections.defaultdict(collections.Counter)
    if a.census:
        import data_range_census as drc
        d = json.load(open(a.census))
        recs = d["regions"] if isinstance(d, dict) and "regions" in d else d
        keymap = {"v10": "v10/maincpu/", "v9": "v9/maincpu/", "v7": "v7/maincpu/"}
        for r in recs:
            if r.get("image") not in keymap or not r["rel"].startswith("midi/"):
                continue
            p = keymap[r["image"]] + r["rel"]
            grades[p][r["grade"]] += r["size"]
            if drc.is_target(r):
                grades[p]["RESEARCH"] += r["size"]
    cols = ["CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "RESEARCH"]
    print("%-46s %7s %7s %7s %7s %7s %7s %7s %7s" % (("file",) + tuple(cols) + ("markers", "numbr")))
    tot = collections.Counter()
    for f in files:
        rel = os.path.relpath(f, ROOT)
        m, nb = markers(f)
        g = grades[rel]
        print("%-46s %7d %7d %7d %7d %7d %7d %7d %7d" % ((rel,) + tuple(g[c] for c in cols) + (m, nb)))
        for c in cols:
            tot[c] += g[c]
        tot["markers"] += m
        tot["numbr"] += nb
    print("%-46s %7d %7d %7d %7d %7d %7d %7d %7d" % (("TOTAL",) + tuple(tot[c] for c in cols + ["markers", "numbr"])))


if __name__ == "__main__":
    main()
