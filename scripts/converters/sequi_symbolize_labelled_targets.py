#!/usr/bin/env python3
r"""sequi_symbolize_labelled_targets.py -- convert branch sites the symboliser
REFUSED on a heuristic (R1/R3) when the target already carries a label.

QUESTION THIS ANSWERS
    symbolize_numeric_branches.py refuses some sites on neighbourhood
    heuristics (R1 "incoherent small block", R3 "absurd neighbourhood") that
    exist to stop it from minting labels for PHANTOM branches inside
    misframed code.  After a file has been re-framed and reviewed, a refused
    site whose target address already has a label in the linked ELF can be
    written symbolically without minting anything.  Which sites, and do they
    rebuild byte-identical?

RUN
    python3 scripts/converters/symbolize_numeric_branches.py --image v7 \
        --only sequencer/sequencer_ui.s --report R.json
    python3 scripts/converters/sequi_symbolize_labelled_targets.py --image v7 \
        --report R.json --kinds R1,R3 --file sequencer/sequencer_ui.s [--apply]

    --apply rewrites the operands (latin-1 I/O), rebuilds the image with make
    and compares it with the dump; restores the file on any difference.
    Only sites in --file are touched; only reported kinds in --kinds.
"""
import argparse
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
BR = re.compile(r'^(\s*(?:jr|jrl|calr|call|jp)\s+(?:[a-z]+\s*,\s*)?)(-?0x[0-9a-fA-F]+|-?\d+)(\s*(?:;.*)?)$')


def labels(image):
    out = subprocess.run([NM, "--defined-only",
                          os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % image)],
                         capture_output=True, text=True, check=True).stdout
    best = {}
    for ln in out.split("\n"):
        p = ln.split()
        if len(p) == 3 and p[1] in "tT" and not p[2].startswith(("__", ".L")):
            a = int(p[0], 16)
            pos = bool(re.search(r"_0x[0-9A-Fa-f]+$", p[2]))
            if a not in best or (best[a][1] and not pos):
                best[a] = (p[2], pos)
    return {a: n for a, (n, _) in best.items()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--report", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--kinds", default="R1,R3")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    rep = json.load(open(a.report))["report"]
    lab = labels(a.image)
    path = os.path.join(ROOT, a.image, "maincpu", a.file)
    L = open(path, encoding="latin-1").read().split("\n")
    done = 0
    for kind in a.kinds.split(","):
        for x in rep.get(kind, []):
            rel, line = x["src"].rsplit(":", 1)
            if rel != a.file:
                continue
            tgt = int(x["target"], 16)
            if tgt not in lab:
                print("  %s %s -> 0x%06X: no label, left numeric" % (kind, x["src"], tgt))
                continue
            i = int(line) - 1
            m = BR.match(L[i])
            if not m:
                print("  %s %s: line shape not recognised: %r" % (kind, x["src"], L[i]))
                continue
            L[i] = m.group(1) + lab[tgt] + m.group(3)
            done += 1
            print("  %s %s -> %s" % (kind, x["src"], lab[tgt]))
    print("%d site(s)" % done)
    if not a.apply or not done:
        return
    orig = open(path, encoding="latin-1").read()
    open(path, "w", encoding="latin-1").write("\n".join(L))
    r = subprocess.run(["make", "rebuilt_ROMs/kn5000_%s_program.llvm.rom" % a.image], cwd=ROOT,
                       capture_output=True, text=True)
    ok = r.returncode == 0 and open(os.path.join(
        ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.rom" % a.image), "rb").read() == open(
        os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % a.image), "rb").read()
    if not ok:
        open(path, "w", encoding="latin-1").write(orig)
        sys.exit("REJECTED: image differs or build failed; file restored")
    print("VERIFIED: %s byte-identical" % a.image)


if __name__ == "__main__":
    main()
