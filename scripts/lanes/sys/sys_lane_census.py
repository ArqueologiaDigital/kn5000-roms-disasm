#!/usr/bin/env python3
r"""sys_lane_census.py -- lane `sys` before/after figures over ITS OWN files.

QUESTION THIS ANSWERS
    Of the bytes emitted by the source files lane `sys` owns (roster
    notes/lanes/ROSTER-2026-09-25.json), how many does the data census grade
    CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER, and how many are RESEARCH
    TARGETS (UNKNOWN, self-admitted, or embedded-in-code, non-CODE: the same
    rule scripts/analysis/lane_worklists.py uses)?  Per file and in total, and
    optionally the delta against a second census JSON.

    It also counts, straight from the sources, the data-as-code markers
    (lane_worklists.ABS regex) and the numeric branch operands
    (`jr/jrl/call/calr/jp <number>`) in the owned files.

RUN
    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json A.json
    python3 scripts/lanes/sys/sys_lane_census.py A.json [B.json] [--rev REV]
      (with B: prints A -> B per file where anything changed, and totals;
       --rev: count markers / numeric branches in the sources at git REV)
"""
import collections
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import lane_worklists as lw  # noqa: E402

LANE = "sys"
GRADES = ("CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER")
NUMBR = re.compile(r'^\s*(jr|jrl|call|calr|jp)\s+(?:[a-z]+\s*,\s*)?(?:0x[0-9a-fA-F]+|\d+)\s*(;.*)?$')


def owned():
    lanes = json.load(open(lw.ROSTER))["lanes"]
    return {p for p in lw.tracked() if lw.owner(p, lanes) == LANE}


def tally(census, files):
    per = collections.defaultdict(collections.Counter)
    for r in json.load(open(census))["regions"]:
        path = lw.IMG_ROOT[r["image"]] + r["rel"]
        if path not in files:
            continue
        g = r["grade"]
        per[path][g] += r["size"]
        if g != "CODE" and (g == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code")):
            per[path]["research"] += r["size"]
    return per


REV = None       # --rev REV: count markers/numeric branches at a git revision


def source_lines(p):
    if REV:
        import subprocess
        r = subprocess.run(["git", "show", "%s:%s" % (REV, p)], cwd=ROOT, capture_output=True)
        return r.stdout.decode("latin-1").split("\n") if r.returncode == 0 else []
    return open(os.path.join(ROOT, p), encoding="latin-1").read().split("\n")


def markers(files):
    out = {}
    for p in files:
        if not p.endswith(".s"):
            continue
        ab = nb = 0
        for ln in source_lines(p):
            s = ln.split(";")[0].strip()
            if not s or s.endswith(":"):
                continue
            if lw.ABS.search(s):
                ab += 1
            if NUMBR.match(ln):
                nb += 1
        out[p] = (ab, nb)
    return out


def row(c):
    return "".join("%9d" % c[g] for g in GRADES + ("research",))


def main():
    global REV
    if "--rev" in sys.argv:
        k = sys.argv.index("--rev")
        REV = sys.argv[k + 1]
        del sys.argv[k:k + 2]
    files = owned()
    a = tally(sys.argv[1], files)
    b = tally(sys.argv[2], files) if len(sys.argv) > 2 else None
    mk = markers(files)
    hdr = "%-52s" % "file" + "".join("%9s" % g for g in GRADES + ("research",))
    print(hdr)
    tot_a, tot_b = collections.Counter(), collections.Counter()
    for p in sorted(set(a) | set(b or {})):
        tot_a.update(a[p])
        if b is None:
            if a[p]["KNOWN-B"] or a[p]["UNKNOWN"] or a[p]["research"]:
                print("%-52s%s" % (p[:52], row(a[p])))
            continue
        tot_b.update(b[p])
        if a[p] != b[p]:
            print("%-52s%s" % (p[:52], row(a[p])))
            print("%-52s%s" % ("   -> after", row(b[p])))
    print("%-52s%s" % ("TOTAL (A)", row(tot_a)))
    if b is not None:
        print("%-52s%s" % ("TOTAL (B)", row(tot_b)))
    ab = sum(v[0] for v in mk.values())
    nb = sum(v[1] for v in mk.values())
    print("sources %s: data-as-code markers %d, numeric branch operands %d (%d owned .s files)"
          % (("at " + REV) if REV else "now", ab, nb, len(mk)))
    for v in ("v10", "v9", "v7"):
        print("   %s markers %d numeric %d" % (
            v, sum(x[0] for p, x in mk.items() if p.startswith(v + "/")),
            sum(x[1] for p, x in mk.items() if p.startswith(v + "/"))))


if __name__ == "__main__":
    main()
