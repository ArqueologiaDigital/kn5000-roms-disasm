#!/usr/bin/env python3
"""Question answered: how many raw `.byte` operand bytes did each file of
`v10/maincpu/midi/` and `v10/maincpu/display/` carry before this lane, and how
many now -- and did the independent mis-framing statistic move the same way?

This is the script behind the two tables in notes/lanes/v10midi-LEDGER.md. It
reads the BEFORE state out of git rather than a copy, so the comparison cannot
drift, and it materialises the before tree into a scratch directory so that
byte_run_start_enrichment.py (which takes directory roots) can be pointed at
both states in turn.

⚠ Read the enrichment RAW COUNTS, not the ratio: the control population in
these two directories is 0-2 runs, and a zero control makes the ratio infinite
regardless of the blind count.

Exact command (from the repo root):

    python3 scripts/analysis/v10midi_before_after.py --base a99564a6

Add --enrichment <path to byte_run_start_enrichment.py> to also print the
before/after mis-framing counts; that script lives on main (`3309e94e`) and can
be extracted with
    git show 3309e94e:scripts/analysis/byte_run_start_enrichment.py > /tmp/e.py
"""
import argparse
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DIRS = ["v10/maincpu/midi", "v10/maincpu/display"]


def byte_operands(text):
    n = 0
    for line in text.split("\n"):
        s = line.strip()
        if s.startswith(".byte"):
            n += len(s[5:].split(","))
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="a99564a6",
                    help="commit the lane branched from")
    ap.add_argument("--enrichment", default=None)
    ap.add_argument("--scratch", default="/tmp/v10midi_before")
    args = ap.parse_args()

    tot = [0, 0]
    print("%-38s %8s %8s" % (".byte operand bytes", "before", "after"))
    for d in DIRS:
        for f in sorted(os.listdir(os.path.join(ROOT, d))):
            if not f.endswith(".s"):
                continue
            rel = os.path.join(d, f)
            before = subprocess.run(["git", "show", "%s:%s" % (args.base, rel)],
                                    cwd=ROOT, capture_output=True).stdout.decode("latin-1")
            after = open(os.path.join(ROOT, rel), encoding="latin-1").read()
            b, a = byte_operands(before), byte_operands(after)
            tot[0] += b
            tot[1] += a
            print("%-38s %8d %8d" % (rel[len("v10/maincpu/"):], b, a))
    print("%-38s %8d %8d" % ("TOTAL", tot[0], tot[1]))

    if not args.enrichment:
        return
    if os.path.exists(args.scratch):
        shutil.rmtree(args.scratch)
    for d in DIRS:
        os.makedirs(os.path.join(args.scratch, os.path.basename(d)))
        for f in os.listdir(os.path.join(ROOT, d)):
            if not f.endswith(".s"):
                continue
            rel = os.path.join(d, f)
            data = subprocess.run(["git", "show", "%s:%s" % (args.base, rel)],
                                  cwd=ROOT, capture_output=True).stdout
            open(os.path.join(args.scratch, os.path.basename(d), f), "wb").write(data)
    for label, roots in (("BEFORE", [os.path.join(args.scratch, os.path.basename(d))
                                     for d in DIRS]),
                         ("AFTER", [os.path.join(ROOT, d) for d in DIRS])):
        print("\n=== %s (read the raw counts, not the ratio) ===" % label)
        subprocess.run([sys.executable, args.enrichment] + roots, cwd=ROOT)


if __name__ == "__main__":
    main()
