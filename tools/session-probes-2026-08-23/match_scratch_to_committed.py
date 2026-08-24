#!/usr/bin/env python3
"""Which session-scratch scripts already have a committed counterpart?

Question answered: before declaring scratch scripts disposable, does an equivalent
actually exist in git? Run this instead of hand-checking a few and generalising --
that is the mistake this script was written to stop me repeating.

Method
------
For each scratch script, compare against every committed .py/.sh/.lua in the three
project repos with difflib.SequenceMatcher, and report the best match.

★ The metric choice is the whole point, so it is measured, not assumed:

  * quick_ratio() compares CHARACTER MULTISETS, not sequences. Two unrelated Python
    files share imports, keywords and punctuation, so they score high on it. Measured
    null over 328 random pairs of UNRELATED committed scripts: median 0.58, p90 0.81,
    max 0.89, and 11.3% clear 0.80. It CANNOT discriminate at any useful threshold.
  * ratio() is the real sequence match. Same null: median 0.02, p90 0.04, max 0.48,
    and 0 of 328 clear 0.80.

So the threshold is ratio() >= 0.80, with a measured false-positive rate of 0/328.
quick_ratio() is used only as a cheap prefilter to pick 25 candidates per script.

Pass criterion: none -- this is a census, not a test. What it produces is two lists.

Result 2026-08-23, over 54 scratch scripts vs 1,221 committed:
    REAL match (ratio >= 0.80) :  8
    no committed counterpart   : 46
Run with --null to reproduce the calibration figures above.

⚠ Walks the scratch dir RECURSIVELY. The first version of this script used os.listdir()
and so skipped every subdirectory -- which hid 12+ probes under adv/ and adv-ldmm/ and
made a sweep look complete when it was not. A census that silently ignores part of its
population is the same defect as a criterion that cannot fail.

Run:  python3 match_scratch_to_committed.py <scratch-dir> [--null]
"""

import difflib
import os
import random
import subprocess
import sys

REPOS = ["/home/fsanches/compartilhado/kn5000-roms-disasm",
         "/home/fsanches/compartilhado/KN7000",
         "/home/fsanches/compartilhado/kn7000_mame",
         "/home/fsanches/compartilhado/technics_roms"]  # added 2026-08-24: a script
         # committed HERE was still being reported as uncommitted, because the repo
         # holding it was not in this list. An incomplete corpus is the same defect as
         # the flat os.listdir() -- it can only ever under-report coverage.
EXT = ('.py', '.sh', '.lua')
THRESHOLD = 0.80


def committed():
    out = {}
    for r in REPOS:
        files = subprocess.run(["git", "-C", r, "ls-files"],
                               capture_output=True, text=True).stdout.split()
        for f in files:
            if f.endswith(EXT):
                p = os.path.join(r, f)
                try:
                    out[p] = open(p, encoding='utf-8', errors='replace').read()
                except OSError:
                    pass
    return out


def null(comm, n=400, seed=7):
    """Calibration: what do UNRELATED committed pairs score?"""
    paths = [p for p in comm if p.startswith(REPOS[0]) and p.endswith('.py')]
    random.seed(seed)
    qs, rs = [], []
    for _ in range(n):
        a, b = random.choice(paths), random.choice(paths)
        if a == b:
            continue
        A, B = comm[a], comm[b]
        if abs(len(A) - len(B)) / max(len(A), 1) > 3:
            continue
        m = difflib.SequenceMatcher(None, A, B)
        qs.append(m.quick_ratio())
        rs.append(m.ratio())
    qs.sort()
    rs.sort()
    k = len(qs)
    print(f"NULL over {k} unrelated committed pairs:")
    for name, v in (("quick_ratio", qs), ("ratio", rs)):
        print(f"  {name:11s} median={v[k//2]:.2f} p90={v[int(k*.9)]:.2f} "
              f"max={v[-1]:.2f}  >={THRESHOLD}: {sum(1 for x in v if x >= THRESHOLD)/k:.1%}")


def main():
    scratch_dir = sys.argv[1]
    comm = committed()
    print(f"committed scripts scanned: {len(comm)}")
    if "--null" in sys.argv:
        null(comm)
        return
    strong, weak = [], []
    scratch = []
    for root, _, files in os.walk(scratch_dir):      # RECURSIVE -- see note below
        for x in sorted(files):
            if x.endswith(EXT):
                scratch.append(os.path.join(root, x))
    for full in sorted(scratch):
        f = os.path.relpath(full, scratch_dir)
        src = open(full, encoding='utf-8', errors='replace').read()
        cands = []
        for p, c in comm.items():
            if abs(len(c) - len(src)) / max(len(src), 1) > 2:
                continue
            cands.append((difflib.SequenceMatcher(None, src, c).quick_ratio(), p))
        cands.sort(reverse=True)
        best = (0.0, None)
        for _, p in cands[:25]:
            r = difflib.SequenceMatcher(None, src, comm[p]).ratio()
            if r > best[0]:
                best = (r, p)
        (strong if best[0] >= THRESHOLD else weak).append((f, best[0], best[1]))
    for title, group in (("REAL match", strong), ("NO committed counterpart", weak)):
        print(f"\n=== {title}: {len(group)} ===")
        for f, r, p in sorted(group, key=lambda x: -x[1]):
            print(f"  {f:24s} {r:.2f} {p or '-'}")


if __name__ == "__main__":
    main()
