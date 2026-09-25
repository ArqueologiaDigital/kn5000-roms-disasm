#!/usr/bin/env python3
r"""seqeng_measure.py -- per-file figures for lane `seqeng`'s 15 files.

QUESTION ANSWERED
-----------------
"For each sequencer file this lane owns (v10/v9/v7 copies of five paths),
how many bytes does the census grade CODE / KNOWN-A / KNOWN-B / UNKNOWN /
FILLER, how many are research targets, how many data-as-code markers and
numeric branch operands remain, and how many bytes are still v7 romslices?"

The research-target rule and the absurd-marker regex are copied from
scripts/analysis/lane_worklists.py (the generator of the lane worklists), so
the figures are comparable with the worklist's own table.

RUN
    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json X.json
    python3 scripts/analysis/seqeng_measure.py X.json
    python3 scripts/analysis/seqeng_measure.py BEFORE.json AFTER.json   # before/after
       (source-text counts -- markers, numeric branches, romslices -- are always
        taken from the CURRENT tree; run it on the before-commit to get before)
"""
import collections
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FILES = ["sequencer/sequencer_engine.s", "sequencer/seq_event_playback.s",
         "sequencer/smf_event_processor.s", "sequencer/smf_tonegen_core.s",
         "sequencer/smf_playback.s"]
VERS = ["v10", "v9", "v7"]
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')
NUMBR = re.compile(r'^(jr|jrl|calr|call|jp|djnz)\b[^;]*?(?:,\s*|\s)(-?\d+|0x[0-9a-f]+)\s*$', re.I)


def census(path):
    tot = collections.defaultdict(collections.Counter)
    for r in json.load(open(path))["regions"]:
        if r["image"] not in VERS or r["rel"] not in FILES:
            continue
        k = (r["image"], r["rel"])
        g = r["grade"]
        tot[k][g] += r["size"]
        if (g == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code")) and g != "CODE":
            tot[k]["RESEARCH"] += r["size"]
    return tot


def text_counts(v, rel):
    p = os.path.join(ROOT, v, "maincpu", rel)
    L = open(p, encoding="latin-1").read().split("\n")
    prev, nabs, nnum, rs = "", 0, 0, 0
    for ln in L:
        c = ln.split(";")[0]
        m = re.search(r'\.incbin\s+"(includes/romslices/[^"]+)"', c)
        if m:
            f = os.path.join(ROOT, v, "maincpu", m.group(1))
            rs += os.path.getsize(f) if os.path.exists(f) else 0
        cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
        if not cc or cc.startswith("."):
            prev = ""
            continue
        if ABS.match(cc) or (cc == "nop" and prev == "nop"):
            nabs += 1
        if NUMBR.match(cc):
            nnum += 1
        prev = cc
    return nabs, nnum, rs


def main():
    cs = [census(p) for p in sys.argv[1:]]
    cols = ["CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "RESEARCH"]
    hdr = "%-4s %-26s " % ("ver", "file") + " ".join("%9s" % c for c in cols) + "  absurd  numbr  romslc"
    print(hdr)
    grand = [collections.Counter() for _ in cs]
    gt = collections.Counter()
    for v in VERS:
        for rel in FILES:
            nabs, nnum, rs = text_counts(v, rel)
            gt["absurd"] += nabs
            gt["numbr"] += nnum
            gt["romslc"] += rs
            for i, c in enumerate(cs):
                t = c[(v, rel)]
                grand[i].update(t)
                tag = "" if len(cs) == 1 else ("before" if i == 0 else "after ")
                print("%-4s %-26s " % (v, rel.split("/")[-1][:26]) +
                      " ".join("%9d" % t[x] for x in cols) +
                      ("  %6d %6d %7d" % (nabs, nnum, rs) if i == len(cs) - 1 else "") +
                      ("  " + tag if tag else ""))
    for i, g in enumerate(grand):
        print("%-31s " % ("TOTAL" + ("" if len(cs) == 1 else (" before" if i == 0 else " after"))) +
              " ".join("%9d" % g[x] for x in cols))
    print("source-text totals (current tree): absurd=%d numeric-branch=%d romslice-bytes=%d"
          % (gt["absurd"], gt["numbr"], gt["romslc"]))


if __name__ == "__main__":
    main()
