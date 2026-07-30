#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""pat_struct.py -- STRUCTURAL ANALOGIES between uPD6383GF effect programs.

Question: are the S.DELAY+X / PEQ+X combination programs literally their
component programs concatenated, i.e. is the microcode assembled from a library
of macros?  Three measurements, each with its null:

    lcr(A,B)     longest common CONTIGUOUS run of words
    cov(B|A)     LCS(A,B) / len(B) -- the fraction of B recoverable, IN ORDER,
                 inside A.  1.0 means B is a subsequence of A.
    split(C)     best two-part decomposition of a combi C into
                 prefix<-base1, suffix<-base2

NULL for every claim: the same statistic against every NON-component body in
the corpus (the "wrong base" control), and against within-program shuffles.

    python3 dsp/tools/pat_struct.py [combi|matrix|period|all]

stdlib only.  Findings: dsp/analysis/data/SPECULATIVE_PATTERNS.md
"""
import argparse
import collections
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pat_corpus import load, fmt, decode_str                        # noqa: E402
from pat_ngram import KEYS                                          # noqa: E402


# the DECLARED components, straight off the effect names in programs.tsv.
# Nothing here is inferred from the words -- that is the point.
COMPONENTS = {
    "a64 S.DELAY+CHORUS":    ["a09 SINGLE DELAY", "a01 CHORUS"],
    "a65 S.DELAY+S.DELAY":   ["a09 SINGLE DELAY", "a09 SINGLE DELAY"],
    "a66 S.DELAY+FLANGER":   ["a09 SINGLE DELAY", "a04 FLANGER"],
    "a67 S.DELAY+VIBRATO":   ["a09 SINGLE DELAY", "a50 VIBRATO"],
    "a68 S.DELAY+PHASER":    ["a09 SINGLE DELAY", "a05 PHASER"],
    "a70 AUTO WAH+S.DELAY":  ["a52 AUTO WAH", "a09 SINGLE DELAY"],
    "a71 PEQ+CHORUS":        ["a39 PARAMETRIC EQ", "a01 CHORUS"],
    "a72 PEQ+S.DELAY":       ["a39 PARAMETRIC EQ", "a09 SINGLE DELAY"],
    "a73 PEQ+FLANGER":       ["a39 PARAMETRIC EQ", "a04 FLANGER"],
    "a74 PEQ+VIBRATO":       ["a39 PARAMETRIC EQ", "a50 VIBRATO"],
    "a75 PEQ+COMPRESSOR":    ["a39 PARAMETRIC EQ", "a36 COMPRESSOR"],
    "a96 PEQ+COMPR+DIST":    ["a39 PARAMETRIC EQ", "a36 COMPRESSOR",
                              "a32 DISTORTION"],
    "a97 PEQ+COMPR+OVERDR":  ["a39 PARAMETRIC EQ", "a36 COMPRESSOR",
                              "a33 OVERDRIVE"],
    "a98 PEQ+DIST+DELAY":    ["a39 PARAMETRIC EQ", "a32 DISTORTION",
                              "a09 SINGLE DELAY"],
    "a99 PEQ+OVERDR+DELAY":  ["a39 PARAMETRIC EQ", "a33 OVERDRIVE",
                              "a09 SINGLE DELAY"],
}


# --------------------------------------------------------------------------
def lcs_len(a, b):
    if not a or not b:
        return 0
    prev = [0] * (len(b) + 1)
    for x in a:
        cur = [0]
        for j, y in enumerate(b):
            cur.append(prev[j] + 1 if x == y else max(cur[j], prev[j + 1]))
        prev = cur
    return prev[-1]


def lcr_len(a, b):
    """longest common contiguous run"""
    if not a or not b:
        return 0
    prev = [0] * (len(b) + 1)
    best = 0
    for x in a:
        cur = [0] * (len(b) + 1)
        for j, y in enumerate(b):
            if x == y:
                cur[j + 1] = prev[j] + 1
                if cur[j + 1] > best:
                    best = cur[j + 1]
        prev = cur
    return best


def cov(a, b):
    """fraction of B recoverable IN ORDER inside A"""
    return lcs_len(a, b) / len(b) if b else 0.0


# --------------------------------------------------------------------------
def cmd_combi(progs, meta, args):
    kind = args.key
    kf = KEYS[kind]
    K = {nm: [kf(w) for w in ws] for nm, ws in progs.items()}
    bodies = [n for n in progs if n not in ("KERNEL", "EPILOGUE")]
    print("=" * 78)
    print("STRUCTURAL ANALOGY -- does a combi CONTAIN its declared bases?")
    print("key=%s.  cov(B|C) = LCS/len(B); 1.000 = B is a subsequence of C." % kind)
    print("=" * 78)
    print("%-24s %-20s %6s %6s | %-20s %6s"
          % ("combi", "declared base", "cov", "lcr", "best NON-component",
             "cov"))
    print("-" * 78)
    decl, ctrl = [], []
    for c in sorted(COMPONENTS):
        if c not in K:
            continue
        comps = COMPONENTS[c]
        others = [b for b in bodies if b != c and b not in comps]
        best_o = max(others, key=lambda b: cov(K[c], K[b]))
        for b in comps:
            if b not in K:
                continue
            v = cov(K[c], K[b])
            r = lcr_len(K[c], K[b])
            decl.append(v)
            print("%-24s %-20s %6.3f %6d | %-20s %6.3f"
                  % (c[:24], b[:20], v, r, best_o[:20], cov(K[c], K[best_o])))
        ctrl.append(cov(K[c], K[best_o]))
        # every non-component, for the full null
        for b in others:
            pass
    print("-" * 78)
    md = sum(decl) / len(decl)
    mc = sum(ctrl) / len(ctrl)
    print("mean cov, DECLARED components : %.3f  (n=%d)" % (md, len(decl)))
    print("mean cov, BEST non-component  : %.3f  (n=%d)  <- the control"
          % (mc, len(ctrl)))
    # full non-component distribution
    allo = []
    for c in sorted(COMPONENTS):
        if c not in K:
            continue
        for b in bodies:
            if b == c or b in COMPONENTS[c]:
                continue
            allo.append(cov(K[c], K[b]))
    m = sum(allo) / len(allo)
    sd = math.sqrt(sum((x - m) ** 2 for x in allo) / len(allo))
    print("mean cov, ALL non-components  : %.3f +- %.3f (n=%d)"
          % (m, sd, len(allo)))
    print("z of the declared mean against that null: %+.1f"
          % ((md - m) / (sd / math.sqrt(len(decl)))))


def cmd_split(progs, meta, args):
    """Is a two-component combi a CONCATENATION?  Find the split point k that
    maximises cov(base1 | C[:k]) + cov(base2 | C[k:])."""
    kind = args.key
    kf = KEYS[kind]
    K = {nm: [kf(w) for w in ws] for nm, ws in progs.items()}
    print("=" * 78)
    print("CONCATENATION TEST -- best prefix/suffix split of each 2-part combi")
    print("=" * 78)
    print("%-24s %4s %4s | %-18s %5s | %-18s %5s"
          % ("combi", "len", "k*", "base1 in prefix", "cov", "base2 in suffix",
             "cov"))
    for c in sorted(COMPONENTS):
        comps = COMPONENTS[c]
        if len(comps) != 2 or c not in K:
            continue
        b1, b2 = comps
        if b1 not in K or b2 not in K:
            continue
        best = None
        C = K[c]
        for k in range(len(C) + 1):
            s = cov(C[:k], K[b1]) + cov(C[k:], K[b2])
            if best is None or s > best[0]:
                best = (s, k)
        _s, k = best
        print("%-24s %4d %4d | %-18s %5.3f | %-18s %5.3f"
              % (c[:24], len(C), k, b1[:18], cov(C[:k], K[b1]),
                 b2[:18], cov(C[k:], K[b2])))


def cmd_matrix(progs, meta, args):
    kind = args.key
    kf = KEYS[kind]
    K = {nm: [kf(w) for w in ws] for nm, ws in progs.items()}
    names = [n for n in progs]
    print("=" * 78)
    print("PAIRWISE longest common CONTIGUOUS run (key=%s), top pairs" % kind)
    print("=" * 78)
    rows = []
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            rows.append((lcr_len(K[a], K[b]), a, b))
    rows.sort(reverse=True)
    for r, a, b in rows[:args.top]:
        print("  %4d   %-26s  %-26s" % (r, a, b))
    # null: shuffled
    rng = random.Random(3)
    sh = {}
    for nm, ws in progs.items():
        s = [kf(w) for w in ws]
        rng.shuffle(s)
        sh[nm] = s
    nl = []
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            nl.append(lcr_len(sh[a], sh[b]))
    print("\nobserved lcr: mean %.2f  max %d" %
          (sum(r[0] for r in rows) / len(rows), rows[0][0]))
    print("shuffled lcr: mean %.2f  max %d" % (sum(nl) / len(nl), max(nl)))


def cmd_period(progs, meta, args):
    """HAND-UNROLLED LOOPS: for every program find the (period, run length)
    pairs where words[i] == words[i+p] over a long stretch.  instruction-set.md
    records two by hand (algo 16 period 8, algo 39 period 9); this enumerates
    them all."""
    kind = args.key
    kf = KEYS[kind]
    print("=" * 78)
    print("PERIODIC (HAND-UNROLLED) STRETCHES  key=%s  min run %d words"
          % (kind, args.minrun))
    print("=" * 78)
    for nm, ws in progs.items():
        ks = [kf(w) for w in ws]
        found = []
        for p in range(1, len(ks) // 2 + 1):
            i = 0
            while i + p < len(ks):
                j = i
                while j + p < len(ks) and ks[j] == ks[j + p]:
                    j += 1
                run = j - i + p
                # require at least TWO full repetitions -- otherwise "period p,
                # run p+1" is satisfied by a single matching pair
                if j > i and run >= max(args.minrun, 2 * p):
                    found.append((run, p, i))
                    i = j + 1
                else:
                    i += 1
        if not found:
            continue
        found.sort(reverse=True)
        seen = []
        for run, p, i in found:
            if any(i >= s and i + run <= e and p % q == 0
                   for q, s, e in seen):
                continue
            seen.append((p, i, i + run))
            print("  %-26s period %3d  run %3d words  at w%d..w%d  (%d reps)"
                  % (nm, p, run, i, i + run - 1, run // p))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["combi", "split", "matrix", "period", "all"])
    ap.add_argument("--key", default="m8", choices=["exact", "m8"])
    ap.add_argument("--top", type=int, default=25)
    ap.add_argument("--minrun", type=int, default=12)
    args = ap.parse_args()
    progs, meta = load()
    if args.cmd in ("combi", "all"):
        cmd_combi(progs, meta, args)
    if args.cmd in ("split", "all"):
        print()
        cmd_split(progs, meta, args)
    if args.cmd in ("matrix", "all"):
        print()
        cmd_matrix(progs, meta, args)
    if args.cmd in ("period", "all"):
        print()
        cmd_period(progs, meta, args)


if __name__ == "__main__":
    main()
