#!/usr/bin/env python3
r"""Lane `proma` instrument: what is left to understand in wsa1/prom_a/wsa1_prom_a.s.

QUESTION THIS ANSWERS
    For the one source file lane `proma` owns (the SX-WSA1R CPU-1 program image,
    TMP95C061), how many bytes does the data census grade CODE / KNOWN-A /
    KNOWN-B / UNKNOWN / FILLER, how many of them are RESEARCH TARGETS, how many
    data-as-code markers remain, and how many branch / ROM-address operands are
    still NUMERIC?  Every figure lane `proma` quotes in its report and commit
    messages comes from this script.

DEFINITIONS (copied, not re-invented)
    * grades and `research target` -- exactly scripts/analysis/lane_worklists.py:
      a region is a target when grade == UNKNOWN or it self-admits or it is
      embedded-in-code, and it is not CODE.  Only regions whose `rel` is
      prom_a/wsa1_prom_a.s count (the image also includes kernel/, dsp/ and
      maincpu/shared/, which other lanes own).
    * data-as-code markers -- lane_worklists.py's ABS regex plus nop-after-nop,
      over the file's statement lines.
    * numeric branches -- symbolize_numeric_branches.py's BRANCH_RE (a jr / jrl /
      calr / call / jp whose operand is a number).  Absolute `call`/`jp` targets
      are split by destination: prom_b (0xF00000-0xF7FFFF, a separately linked
      image), prom_a itself (0xF80000-0xFFFFFF), other.
    * numeric ROM immediates -- a statement whose operand text holds a hex
      number in 0x00F00000-0x00FFFFFF written with at least six digits (the way
      the disassembler emitted 24-bit addresses), split prom_a / prom_b.

RUN
    python3 notes/proma-2026-09-25/measure_proma.py                 # runs the census (~15 s)
    python3 notes/proma-2026-09-25/measure_proma.py --load X.json   # reuse a census --json
    python3 notes/proma-2026-09-25/measure_proma.py --rev <git-rev> # measure a revision
      (--rev checks the revision's file out into a temporary worktree first)
"""
import argparse
import collections
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
REL = "prom_a/wsa1_prom_a.s"
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')
BRANCH = re.compile(
    r'^\s*(?:[A-Za-z_.$][\w.$@]*:\s*)?(jr|jrl|calr|call|jp)\s+(?:([a-z]+)\s*,\s*)?'
    r'(-?0x[0-9a-fA-F]+|-?\d+|\(\s*0x[0-9a-fA-F]+\s*-\s*0x[0-9a-fA-F]+\s*\))\s*(?:;.*)?$')
IMM = re.compile(r'0x(00)?(f[0-9a-f]{5})\b', re.I)


def census(root, load):
    if load:
        return json.load(open(load))["regions"]
    with tempfile.TemporaryDirectory() as td:
        out = os.path.join(td, "c.json")
        subprocess.run([sys.executable, os.path.join(root, "scripts/analysis/data_range_census.py"),
                        "--images", "prom_a", "--json", out], cwd=root, check=True,
                       stdout=subprocess.DEVNULL)
        return json.load(open(out))["regions"]


def source_counts(path):
    L = open(path, encoding="latin-1").read().split("\n")
    prev, nabs = "", 0
    br = collections.Counter()
    imm = collections.Counter()
    for ln in L:
        c = ln.split(";")[0]
        cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
        if not cc or cc.startswith("."):
            prev = ""
            continue
        if ABS.match(cc) or (cc == "nop" and prev == "nop"):
            nabs += 1
        prev = cc
        m = BRANCH.match(c)
        if m:
            mn, num = m.group(1), m.group(3)
            if mn in ("call", "jp"):
                v = int(num, 0)
                dest = ("prom_b" if 0xF00000 <= v < 0xF80000 else
                        "prom_a" if 0xF80000 <= v <= 0xFFFFFF else "other")
                br[mn + "->" + dest] += 1
            else:
                br[mn] += 1
            continue
        for mm in IMM.finditer(cc):
            v = int(mm.group(2), 16)
            imm["prom_b" if v < 0xF80000 else "prom_a"] += 1
    return nabs, br, imm


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--load")
    ap.add_argument("--rev")
    a = ap.parse_args()
    root = ROOT
    tmp = None
    if a.rev:
        tmp = tempfile.mkdtemp(prefix="proma-rev-")
        subprocess.run(["git", "worktree", "add", "--detach", tmp, a.rev], cwd=ROOT, check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        root = tmp
    try:
        regs = [r for r in census(root, a.load) if r["image"] == "prom_a" and r["rel"] == REL]
        tot = collections.Counter()
        for r in regs:
            tot[r["grade"]] += r["size"]
            tgt = r["grade"] == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code")
            if tgt and r["grade"] != "CODE":
                tot["RESEARCH"] += r["size"]
        nabs, br, imm = source_counts(os.path.join(root, "wsa1", REL))
    finally:
        if tmp:
            subprocess.run(["git", "worktree", "remove", "--force", tmp], cwd=ROOT,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("wsa1/%s%s" % (REL, "  @ " + a.rev if a.rev else ""))
    for g in ("CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "RESEARCH"):
        print("  %-9s %8d B" % (g, tot[g]))
    print("  data-as-code markers        %6d" % nabs)
    print("  numeric branches            %6d  %s" % (sum(br.values()), dict(sorted(br.items()))))
    print("  numeric ROM-range immediates %5d  %s" % (sum(imm.values()), dict(sorted(imm.items()))))


if __name__ == "__main__":
    main()
