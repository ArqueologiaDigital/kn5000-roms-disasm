#!/usr/bin/env python3
r"""Lane `promb` (2026-09-25 semantic push): the before/after instrument for prom_b.

QUESTION THIS ANSWERS
    For the files lane `promb` owns (wsa1/prom_b/*), what are, right now:
      * the data-census byte buckets -- CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER --
        and the RESEARCH-TARGET bytes, with exactly the rule
        scripts/analysis/lane_worklists.py uses (grade UNKNOWN, or a header that
        admits ignorance, or undocumented data embedded in code; never CODE);
      * the data-as-code marker count (the same ABS regex lane_worklists.py uses);
      * numeric branch operands, counted with symbolize_numeric_branches.py's
        own BRANCH_RE (jr / jrl / calr / call / jp with a number);
      * the numeric ROM-address operands still in the source, by mnemonic and by
        which image the value lands in (prom_b 0xF00000-0xF7FFFF, prom_a
        0xF80000-0xFFFFFF);
      * the label population: structural names the branch symboliser created
        (_Skip/_Join/_Loop/_Return/_Epilogue/_Entry/_Sub/_Helper), `sub_XXXXXX`,
        other address-derived names, and the rest;
      * optionally, from a symbolize_numeric_branches.py --report JSON, the
        refused sites split by whether the target is INSIDE prom_b or in prom_a
        (see FINDINGS-promb-2026-09-25.md: every prom_a target is reported as
        `mid-line-code` by that tool, which is an artefact, not a misframe).

RUN
    python3 scripts/analysis/data_range_census.py --images prom_b --json X.json
    python3 scripts/converters/symbolize_numeric_branches.py --image prom_b --report R.json
    python3 notes/promb-2026-09-25/measure_promb.py --census X.json [--symbr R.json]

    Without --census only the source-text counts are printed (fast, no build).
"""
import argparse
import collections
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
OWN_REL = ("prom_b/",)          # census `rel` is relative to wsa1/
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')
STRUCT = re.compile(r'_(Skip|Join|Loop|Sub|Return|Epilogue|Entry|Helper)\d*$')
LABEL = re.compile(r'^([A-Za-z_.$][\w.$@]*):')
NUM = re.compile(r'(?<![\w.])(0x[0-9a-fA-F]+|\d+)(?![\w])')


def census(path):
    d = json.load(open(path))["regions"]
    tot = collections.Counter()
    for r in d:
        if r["image"] != "prom_b" or not r["rel"].startswith(OWN_REL):
            continue
        g = r["grade"]
        tot[g] += r["size"]
        tgt = g == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code")
        if tgt and g != "CODE":
            tot["RESEARCH"] += r["size"]
            tot["RESEARCH_n"] += 1
    print("census bytes (prom_b files):")
    for k in ("CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "RESEARCH"):
        print("  %-10s %8d" % (k, tot[k]))
    print("  research regions %d" % tot["RESEARCH_n"])


def text_counts():
    L = open(SRC, encoding="latin-1").read().split("\n")
    nabs, prev = 0, ""
    labels = collections.Counter()
    nums = collections.Counter()
    for ln in L:
        m = LABEL.match(ln)
        if m:
            n = m.group(1)
            if STRUCT.search(n):
                labels["structural"] += 1
            elif n.startswith("sub_"):
                labels["sub_XXXXXX"] += 1
            elif re.search(r'[0-9A-F]{6}', n):
                labels["other address-derived"] += 1
            else:
                labels["semantic (no address in name)"] += 1
        c = ln.split(";")[0]
        cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
        # absurd markers: exactly lane_worklists.py's loop
        if not cc or cc.startswith("."):
            prev = ""
        else:
            if ABS.match(cc) or (cc == "nop" and prev == "nop"):
                nabs += 1
            prev = cc
        if not cc:
            continue
        mm = re.match(r'^(\.?\w+)\s*(.*)$', cc)
        if not mm:
            continue
        mn, ops = mm.group(1), mm.group(2)
        if mn.startswith(".") and mn != ".long":
            continue
        for t in NUM.findall(ops):
            v = int(t, 16) if t.lower().startswith("0x") else int(t)
            if 0xF00000 <= v <= 0xFFFFFF:
                nums[(mn, "prom_b" if v < 0xF80000 else "prom_a")] += 1
    print("data-as-code markers: %d" % nabs)
    # numeric branch operands, with the branch symboliser's own line regex
    import sys as _s
    _s.path.insert(0, os.path.join(ROOT, "scripts", "converters"))
    _s.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
    import symbolize_numeric_branches as snb
    nb = collections.Counter()
    for ln in L:
        m = snb.BRANCH_RE.match(ln)
        if m:
            nb[m.group("mn")] += 1
    print("numeric branch operands (symboliser regex): %d  %s" % (
        sum(nb.values()), " ".join("%s %d" % kv for kv in sorted(nb.items()))))
    print("labels:")
    for k, v in sorted(labels.items()):
        print("  %-32s %6d" % (k, v))
    print("  %-32s %6d" % ("TOTAL", sum(labels.values())))
    print("numeric ROM-address operands (value in 0xF00000-0xFFFFFF):")
    for (mn, img), v in sorted(nums.items(), key=lambda kv: -kv[1]):
        print("  %-10s -> %-6s %6d" % (mn, img, v))
    print("  %-20s %6d" % ("TOTAL", sum(nums.values())))


def symbr(path):
    rep = json.load(open(path))["report"]
    c = collections.Counter()
    for k, rows in rep.items():
        for x in rows:
            t = int(x.get("target", "0"), 16)
            c[(k, "in prom_b" if 0xF00000 <= t < 0xF80000 else
               "prom_a" if t >= 0xF80000 else "outside")] += 1
    print("symboliser refusals by target image:")
    for k, v in sorted(c.items()):
        print("  %-16s %-10s %6d" % (k[0], k[1], v))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--census")
    ap.add_argument("--symbr")
    a = ap.parse_args()
    if a.census:
        census(a.census)
    text_counts()
    if a.symbr:
        symbr(a.symbr)


if __name__ == "__main__":
    main()
