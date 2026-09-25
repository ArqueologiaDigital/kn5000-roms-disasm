#!/usr/bin/env python3
r"""lane_file_figures.py -- census buckets, research targets and data-as-code markers for NAMED files.

QUESTION ANSWERED
-----------------
"For these source files (all versions), how many bytes are CODE / KNOWN-A /
KNOWN-B / UNKNOWN / FILLER, how many bytes are research targets, how many
`.incbin` romslice bytes remain, and how many absurd data-as-code markers do
the files hold?"  -- the before/after figures a lane of the 2026-09-25 semantic
push must report (notes/lanes/BRIEF-2026-09-25-semantic.md).

INPUTS
  * a census JSON from `scripts/analysis/data_range_census.py --json` (regions
    carry image, rel, grade, size, admits, embedded_in_code);
  * the source files themselves for the marker count.  The marker rule is the
    one `scripts/analysis/lane_worklists.py` uses (ABS regex below, copied, plus
    `nop` directly after `nop`), so the numbers are comparable with the
    worklists; a research target is `data_range_census.is_target`: grade
    UNKNOWN, or self-admitted, or embedded-in-code.

RUN
    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json C.json
    python3 scripts/analysis/lane_file_figures.py --census C.json \
        --files extensions/extension_data.s,extensions/extension_init.s
  (file paths are relative to <ver>/maincpu and counted for v10, v9 and v7)
"""
import argparse
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')
GRADES = ("CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER")


def markers(path):
    L = open(path, encoding="latin-1").read().split("\n")
    prev, n, romslice = "", 0, 0
    for ln in L:
        c = ln.split(";")[0]
        m = re.search(r'\.incbin\s+"(includes/romslices/[^"]+)"', c)
        if m:
            full = os.path.join(os.path.dirname(path).rsplit("/maincpu", 1)[0], "maincpu", m.group(1))
            romslice += os.path.getsize(full) if os.path.exists(full) else 0
        cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
        if not cc or cc.startswith("."):
            prev = ""
            continue
        if ABS.match(cc) or (cc == "nop" and prev == "nop"):
            n += 1
        prev = cc
    return n, romslice


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--census", required=True)
    ap.add_argument("--files", required=True)
    ap.add_argument("--versions", default="v10,v9,v7")
    a = ap.parse_args()
    files = [f.strip() for f in a.files.split(",") if f.strip()]
    vers = [v.strip() for v in a.versions.split(",")]
    d = json.load(open(a.census))
    regs = d["regions"]
    tot = {}
    print("%-5s %-32s %8s %8s %8s %8s %7s %9s %8s %8s" % (
        "ver", "file", "CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "research", "markers", "romslice"))
    for v in vers:
        for f in files:
            row = dict.fromkeys(GRADES + ("RESEARCH",), 0)
            for r in regs:
                if r["image"] == v and r["rel"] == f:
                    g = r["grade"]
                    row[g] = row.get(g, 0) + r["size"]
                    if g == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code"):
                        row["RESEARCH"] += r["size"]
            p = os.path.join(ROOT, v, "maincpu", f)
            mk, rs = markers(p) if os.path.exists(p) else (0, 0)
            row["markers"], row["romslice"] = mk, rs
            print("%-5s %-32s %8d %8d %8d %8d %7d %9d %8d %8d" % (
                v, f, row["CODE"], row["KNOWN-A"], row["KNOWN-B"], row["UNKNOWN"],
                row["FILLER"], row["RESEARCH"], mk, rs))
            for k, x in row.items():
                tot[k] = tot.get(k, 0) + x
    print("%-5s %-32s %8d %8d %8d %8d %7d %9d %8d %8d" % (
        "ALL", "", tot["CODE"], tot["KNOWN-A"], tot["KNOWN-B"], tot["UNKNOWN"],
        tot["FILLER"], tot["RESEARCH"], tot["markers"], tot["romslice"]))


if __name__ == "__main__":
    main()
