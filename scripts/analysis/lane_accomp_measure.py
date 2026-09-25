#!/usr/bin/env python3
r"""lane_accomp_measure.py -- before/after figures for lane `accomp`'s files.

QUESTION ANSWERED
-----------------
For the six accompaniment sources (accompaniment_engine.s and
accompseq_routines.s in v10, v9 and v7), how many
  * data-as-code MARKERS (the rule of scripts/analysis/lane_worklists.py:
    halt/incf/decf/ldf/normal/max/min/swi, `jr cc,0`, never-taken `jr f,`,
    nop-nop),
  * NUMERIC branch operands (the regex of
    scripts/converters/README-symbolize-branches.md, djnz included),
  * `.byte` directive BYTES and `.incbin` romslice bytes,
are there -- measured from the SOURCE TEXT of the working tree or of a git
revision -- and, given a census JSON from scripts/analysis/data_range_census.py,
how many CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER / research-target bytes
the census puts in them.

RUN
    python3 scripts/analysis/lane_accomp_measure.py [--rev REV] [--census X.json]
"""
import argparse
import json
import os
import re
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FILES = ["%s/maincpu/sequencer/%s" % (v, f) for v in ("v10", "v9", "v7")
         for f in ("accompaniment_engine.s", "accompseq_routines.s")]
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')
NUM = re.compile(r'^\s*(\S+:)?\s*(jr|jrl|calr|call|jp|djnz)\s+([a-z]+,\s*)?(-?[0-9]+|0x[0-9a-fA-F]+)\s*(;.*)?$')


def text_of(path, rev):
    if rev:
        r = subprocess.run(["git", "show", "%s:%s" % (rev, path)], cwd=ROOT, capture_output=True)
        return r.stdout.decode("latin-1")
    return open(os.path.join(ROOT, path), encoding="latin-1").read()


def measure(txt, path):
    L = txt.split("\n")
    prev, nabs, nnum, nbyte, ninc = "", 0, 0, 0, 0
    for ln in L:
        if NUM.match(ln):
            nnum += 1
        c = ln.split(";")[0]
        m = re.search(r'\.incbin\s+"(includes/romslices/[^"]+)"', c)
        if m:
            f = os.path.join(ROOT, path.split("/")[0], "maincpu", m.group(1))
            ninc += os.path.getsize(f) if os.path.exists(f) else 0
        s = c.strip()
        s2 = re.sub(r'^[\w.$]+:\s*', '', s)
        if s2.startswith(".byte"):
            nbyte += len([x for x in s2[5:].split(",") if x.strip()])
        cc = s2.lower()
        if not cc or cc.startswith("."):
            prev = ""
            continue
        if ABS.match(cc) or (cc == "nop" and prev == "nop"):
            nabs += 1
        prev = cc
    return nabs, nnum, nbyte, ninc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rev")
    ap.add_argument("--census")
    a = ap.parse_args()
    print("%-45s %8s %8s %8s %9s" % ("file", "markers", "numeric", ".byte B", "romslice"))
    tot = [0, 0, 0, 0]
    for p in FILES:
        m = measure(text_of(p, a.rev), p)
        tot = [x + y for x, y in zip(tot, m)]
        print("%-45s %8d %8d %8d %9d" % ((p,) + m))
    print("%-45s %8d %8d %8d %9d" % (("TOTAL",) + tuple(tot)))
    if a.census:
        d = json.load(open(a.census))
        regs = d["regions"] if isinstance(d, dict) and "regions" in d else d
        agg = {}
        for r in regs:
            path = "%s/maincpu/%s" % (r["image"], r["rel"])
            if path not in FILES:
                continue
            g = agg.setdefault(path, dict(CODE=0, **{"KNOWN-A": 0, "KNOWN-B": 0}, UNKNOWN=0, FILLER=0, target=0))
            g[r["grade"]] = g.get(r["grade"], 0) + r["size"]
            if r["grade"] == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code"):
                g["target"] += r["size"]
        print()
        print("%-45s %8s %8s %8s %8s %8s %8s" % ("file", "CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "targets"))
        T = dict(CODE=0, **{"KNOWN-A": 0, "KNOWN-B": 0}, UNKNOWN=0, FILLER=0, target=0)
        for p in FILES:
            g = agg.get(p, {})
            for k in T:
                T[k] += g.get(k, 0)
            print("%-45s %8d %8d %8d %8d %8d %8d" % (p, g.get("CODE", 0), g.get("KNOWN-A", 0),
                  g.get("KNOWN-B", 0), g.get("UNKNOWN", 0), g.get("FILLER", 0), g.get("target", 0)))
        print("%-45s %8d %8d %8d %8d %8d %8d" % ("TOTAL", T["CODE"], T["KNOWN-A"], T["KNOWN-B"],
              T["UNKNOWN"], T["FILLER"], T["target"]))


if __name__ == "__main__":
    main()
