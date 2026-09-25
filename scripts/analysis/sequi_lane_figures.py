#!/usr/bin/env python3
r"""sequi_lane_figures.py -- per-file census figures for lane `sequi`.

QUESTION THIS ANSWERS
    For the eight sequencer files lane `sequi` owns (all three maincpu
    versions), how many bytes are CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER,
    how many are RESEARCH TARGETS (UNKNOWN, self-admitted, or embedded-in-code
    data -- the same rule scripts/analysis/lane_worklists.py uses), how many
    data-as-code markers (the lane_worklists ABS rule) and how many numeric
    branch operands (`jr/jrl/jp/call/calr/djnz` with a numeric target) remain?

    Before/after pairs are two runs of this script over two census JSONs
    written by `scripts/analysis/data_range_census.py --json`.

RUN
    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json C.json
    python3 scripts/analysis/sequi_lane_figures.py C.json [C_v7.json ...]
      (several JSONs are merged per image: the LAST one that holds an image wins,
       so a baseline can combine per-image runs taken on a clean tree)

    The marker / numeric-branch columns are read from the CURRENT working tree,
    not from the JSON.
"""
import collections
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import lane_worklists as LW  # noqa: E402

FILES = ["sequencer/sequencer_ui.s", "sequencer/seq_audio_mode.s",
         "sequencer/smf_config_routines.s", "sequencer/seq_step_routines.s",
         "sequencer/rhythm_routines.s", "sequencer/bmdredit_routines.s",
         "sequencer/composer_msp_defaults.s", "sequencer/ssf_gate_states.s"]
IMAGES = ["v10", "v9", "v7"]
BR = re.compile(r'^(jr|jrl|jp|call|calr|djnz)\b(.*)$')
NUMTGT = re.compile(r'(^|,)\s*(0x[0-9a-fA-F]+|\d+)\s*$')


def tree_counts(path):
    L = open(os.path.join(ROOT, path), encoding="latin-1").read().split("\n")
    prev, nabs, nnum = "", 0, 0
    for ln in L:
        c = ln.split(";")[0]
        cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
        if not cc or cc.startswith("."):
            prev = ""
            continue
        if LW.ABS.match(cc) or (cc == "nop" and prev == "nop"):
            nabs += 1
        m = BR.match(cc)
        if m and NUMTGT.search(m.group(2)) and "(" not in m.group(2):
            nnum += 1
        prev = cc
    return nabs, nnum


def main():
    regions = {}
    for f in sys.argv[1:]:
        d = json.load(open(f))
        imgs = {r["key"] for r in d["results"]}
        for img in imgs:
            regions[img] = [r for r in d["regions"] if r["image"] == img]
    tot = collections.defaultdict(collections.Counter)
    for img in IMAGES:
        for r in regions.get(img, []):
            if r["rel"] not in FILES:
                continue
            k = (img, r["rel"])
            g = r["grade"]
            tot[k][g] += r["size"]
            tgt = g == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code")
            if tgt and g != "CODE":
                tot[k]["RESEARCH"] += r["size"]
                tot[k]["nRESEARCH"] += 1
    cols = ["CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "RESEARCH", "nRESEARCH"]
    print("%-5s %-34s " % ("img", "file") + " ".join("%8s" % c for c in cols)
          + " %7s %7s" % ("markers", "numbr"))
    grand = collections.Counter()
    for img in IMAGES:
        if img not in regions:
            continue
        for f in FILES:
            t = tot[(img, f)]
            nabs, nnum = tree_counts(os.path.join(img, "maincpu", f))
            grand.update(t)
            grand["markers"] += nabs
            grand["numbr"] += nnum
            print("%-5s %-34s " % (img, f) + " ".join("%8d" % t[c] for c in cols)
                  + " %7d %7d" % (nabs, nnum))
    print("%-5s %-34s " % ("ALL", "") + " ".join("%8d" % grand[c] for c in cols)
          + " %7d %7d" % (grand["markers"], grand["numbr"]))


if __name__ == "__main__":
    main()
