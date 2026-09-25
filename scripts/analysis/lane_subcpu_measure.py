#!/usr/bin/env python3
r"""lane_subcpu_measure.py -- the before/after figures of the 2026-09-25 `subcpu` lane.

QUESTION THIS ANSWERS
    For the files the `subcpu` lane owns (v142/subcpu/*.s and subcpu/boot/*.s), how many
    bytes does the census put in each bucket (CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER),
    how many are RESEARCH TARGETS (UNKNOWN, self-admitted, or embedded-in-code, as
    scripts/analysis/lane_worklists.py defines them), how many numeric branch operands are
    left (scripts/converters/symbolize_numeric_branches.py --report), and how many
    data-as-code markers remain (lane_worklists.py's ABS regex + nop-nop pairs)?

    It also re-checks one fact quoted in subcpu_fp_math.s: every `*_Pad` byte in that file is
    0xFF at an ODD address (so it 2-aligns the routine after it).

HOW TO GET A "BEFORE" FIGURE
    Point --root at an extracted copy of an older revision, e.g.
        git archive 3958235e v142 subcpu scripts original_ROMs | tar -x -C /tmp/base
        python3 scripts/analysis/lane_subcpu_measure.py --root /tmp/base
    The census, symboliser and ROMs are then THAT revision's own, so the instrument is
    whatever it was then (it did not change for this lane's run).

RUN
    python3 scripts/analysis/lane_subcpu_measure.py              # this tree
    python3 scripts/analysis/lane_subcpu_measure.py --root DIR   # another tree
"""
import argparse
import collections
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$'
                 r'|^(jr|jrl)\s+f\s*,')
IMG_ROOT = {"v142": "v142/subcpu/", "subboot": "subcpu/boot/"}


def census(root, tmp):
    out = os.path.join(tmp, "census.json")
    subprocess.run([sys.executable, os.path.join(root, "scripts/analysis/data_range_census.py"),
                    "--images", "v142,subboot", "--json", out], cwd=root, check=True,
                   capture_output=True)
    return json.load(open(out))["regions"]


def numeric(root, tmp):
    tot = collections.Counter()
    for img in ("v142", "subboot"):
        rep = os.path.join(tmp, img + ".json")
        r = subprocess.run([sys.executable, os.path.join(root, "scripts/converters/symbolize_numeric_branches.py"),
                            "--image", img, "--report", rep], cwd=root, capture_output=True, text=True)
        for ln in r.stdout.splitlines():
            m = re.match(r"^\s+(numeric_\w+)\s+(\d+)$", ln)
            if m:
                tot[(img, m.group(1))] += int(m.group(2))
    return tot


def markers(root):
    res = {}
    for base in IMG_ROOT.values():
        d = os.path.join(root, base)
        for f in sorted(os.listdir(d)):
            if not f.endswith(".s"):
                continue
            L = open(os.path.join(d, f), encoding="latin-1").read().split("\n")
            prev, n = "", 0
            for ln in L:
                c = ln.split(";")[0]
                cc = re.sub(r'^[\w.$]+:\s*', '', c.strip()).lower()
                if not cc or cc.startswith("."):
                    prev = ""
                    continue
                if ABS.match(cc) or (cc == "nop" and prev == "nop"):
                    n += 1
                prev = cc
            res[base + f] = n
    return res


def pad_parity(root):
    """Every *_Pad label in subcpu_fp_math.s: byte value and address parity, from a build."""
    llvm = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
    d = tempfile.mkdtemp(prefix="lanesub_")
    o, e = os.path.join(d, "v.o"), os.path.join(d, "v.elf")
    subprocess.run([os.path.join(llvm, "llvm-mc"), "-triple=tlcs900", "-filetype=obj", "-I", "v142/subcpu",
                    "-o", o, "v142/subcpu/kn5000_subprogram_v142.s"], cwd=root, check=True, capture_output=True)
    subprocess.run([os.path.join(llvm, "ld.lld"), "-T", "v142/subcpu/subcpu.ld", "-o", e, o], cwd=root,
                   check=True, capture_output=True)
    nm = subprocess.run([os.path.join(llvm, "llvm-nm"), e], check=True, capture_output=True, text=True).stdout
    rom = open(os.path.join(root, "original_ROMs/kn5000_subprogram_v142.rom"), "rb").read()
    rows = []
    for ln in nm.splitlines():
        p = ln.split()
        if len(p) == 3 and p[2].endswith("_Pad") and p[2] != "FP_Library_End_Pad":
            a = int(p[0], 16)
            if 0x03D000 <= a < 0x03F000:
                rows.append((p[2], a, rom[a - 0xF000 + 0x100]))
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=HERE)
    a = ap.parse_args()
    root = os.path.abspath(a.root)
    tmp = tempfile.mkdtemp(prefix="lanesub_")
    regs = census(root, tmp)
    per = collections.defaultdict(collections.Counter)
    for r in regs:
        f = IMG_ROOT[r["image"]] + r["rel"]
        g = r["grade"]
        per[f][g] += r["size"]
        if g != "CODE" and (g == "UNKNOWN" or r.get("admits") or r.get("embedded_in_code")):
            per[f]["RESEARCH"] += r["size"]
    cols = ("CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER", "RESEARCH")
    print("census bytes per owned file (root %s)" % root)
    print("  %-40s" % "file" + "".join("%10s" % c for c in cols))
    tot = collections.Counter()
    for f in sorted(per):
        print("  %-40s" % f + "".join("%10d" % per[f][c] for c in cols))
        tot.update(per[f])
    print("  %-40s" % "TOTAL" + "".join("%10d" % tot[c] for c in cols))
    num = numeric(root, tmp)
    print("numeric branch operands:", dict(num), "total", sum(num.values()))
    mk = markers(root)
    print("data-as-code markers (halt/incf/decf/ldf/normal/max/min/swi/jr cc,0/jr f/nop-nop):")
    for f, n in sorted(mk.items()):
        print("  %-40s %5d" % (f, n))
    pads = pad_parity(root)
    odd = sum(1 for _, a, b in pads if a & 1 and b == 0xFF)
    print("subcpu_fp_math.s *_Pad bytes: %d, of which 0xFF at an odd address: %d" % (len(pads), odd))


if __name__ == "__main__":
    main()
