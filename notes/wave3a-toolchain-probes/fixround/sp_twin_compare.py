#!/usr/bin/env python3
"""sp_twin_compare.py -- after `REG=sp` and `REG=wa` runs of sp_asm_check.py:
is any instance good with WA in the GR16 operand and bad with SP?  (= a defect
of SP alone.)  Pairs the twins by def + text with the register masked out.

Run:  python3 sp_twin_compare.py        (reads $OUTDIR/sp_asm_check_{sp,wa}.tsv)
Signal: the (good-with-WA, bad-with-SP) count -- 0 means SP encodes as MAME
reads it wherever WA does.  Exit 1 if it is not 0.
"""
import collections, csv, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import v1a_sweep as V


def load(reg):
    rows = list(csv.reader(open(os.path.join(V.OUT, "sp_asm_check_%s.tsv" % reg)),
                           delimiter="\t"))[1:]
    mask = re.compile(r'(?<![a-z0-9_])%s(?![a-z0-9_])' % reg)
    return {(r[2], mask.sub("@", r[3])): r for r in rows}


sp, wa = load("sp"), load("wa")
good = lambda r: r[0] in ("OK", "PSEUDO_OK") and r[1] == "True"
c = collections.Counter()
bad = []
for k, x in sp.items():
    y = wa.get(k)
    if y is None:
        c["no twin"] += 1
        continue
    c[(good(y), good(x))] += 1
    if good(y) and not good(x):
        bad.append((x[2], x[3], x[4], x[5], "| wa twin:", y[3], y[4], y[5]))
print("(good with WA, good with SP): count")
for k, n in sorted(c.items(), key=str):
    print("  %-20s %6d" % (k, n))
for b in bad[:40]:
    print("  SP-ONLY DEFECT", *b)
sys.exit(1 if bad else 0)
