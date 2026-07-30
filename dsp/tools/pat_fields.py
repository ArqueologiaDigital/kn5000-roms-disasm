#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""pat_fields.py -- FIELD REGULARITIES in the uPD6383GF corpus.

Three questions, each with its null computed FIRST:

  `addr8`   Which addr8 values occur with which class4?  Is addr8 a SIGNED
            displacement in some classes and an ABSOLUTE address in others, and
            where is the boundary?  The signedness statistic is the share of
            values in the small-signed band |s8| <= 32 -- 65/256 = 25.4 % under a
            uniform null, which is the number every row is compared against.

  `family`  Which (field, value) pairs occur in only ONE effect family?  Ranked
            by how sharp the split is, against a null that PERMUTES the family
            labels over images (so a value present in k images gets the purity
            a random k-image set would get).

  `closure` Does the signed-addr8 pointer walk of a program return to where it
            started?  Per program and per repeated idiom.

    python3 dsp/tools/pat_fields.py [addr8|family|closure|cooc|all]

stdlib only.  Findings: dsp/analysis/data/SPECULATIVE_PATTERNS.md
"""
import argparse
import collections
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pat_corpus import load, fmt, decode_str, F                     # noqa: E402


def s8(v):
    return v - 256 if v >= 0x80 else v


# --------------------------------------------------------------------------
#  3.  addr8 x class4
# --------------------------------------------------------------------------
def cmd_addr8(progs, meta, args):
    rows = collections.defaultdict(list)          # bucket -> [F]
    for nm, ws in progs.items():
        for w in ws:
            f = F(w)
            if f.cfmt:
                rows["C-format (addr8 is immediate)"].append(f)
                continue
            if f.class4 == 1 and f.b11:
                rows["cls1 +ESC  (delay-DRAM)"].append(f)
            elif f.class4 == 1 and f.b10:
                rows["cls1 +END  (unit tag)"].append(f)
            elif f.class4 == 1:
                rows["cls1 plain (register file)"].append(f)
            else:
                rows["cls%X %s" % (f.class4,
                                   {0: "(mode0)", 2: "(mode2 ptr+)", 4: "(mode4)",
                                    5: "(mode5)", 6: "(mode6)", 8: "(mode0,cur)",
                                    9: "(mode1,cur)", 0xA: "(mode2,cur+)",
                                    0xC: "(mode4,cur)", 0xD: "(mode5,cur)"}
                                   .get(f.class4, ""))].append(f)
    print("=" * 78)
    print("addr8 x class4.  'small |s8|<=32' NULL under uniform addr8 = 25.4 %")
    print("=" * 78)
    print("%-30s %5s %6s %7s %7s %7s %7s"
          % ("bucket", "n", "distinct", "|s8|<=32", "zero", ">=0x80", "mean|s8|"))
    order = sorted(rows, key=lambda k: -len(rows[k]))
    for k in order:
        fs = rows[k]
        n = len(fs)
        vals = [f.addr8 for f in fs]
        small = sum(1 for v in vals if abs(s8(v)) <= 32) / n
        zero = sum(1 for v in vals if v == 0) / n
        neg = sum(1 for v in vals if v >= 0x80) / n
        mabs = sum(abs(s8(v)) for v in vals) / n
        print("%-30s %5d %6d %7.1f%% %6.1f%% %6.1f%% %7.1f"
              % (k, n, len(set(vals)), 100 * small, 100 * zero, 100 * neg, mabs))
    print()
    print("SIGNED-vs-ABSOLUTE discriminator: a SIGNED displacement clusters at")
    print("small |s8| and straddles 0x80; an ABSOLUTE address does not.")
    print()
    print("--- addr8 value histograms, per bucket (top 12) ---")
    for k in order:
        vals = collections.Counter(f.addr8 for f in rows[k])
        print("  %-30s %s" % (k, "  ".join(
            "%02X:%d" % (v, c) for v, c in vals.most_common(12))))


def cmd_closure(progs, meta, args):
    """Sum of signed addr8 over the pointer-moving words (mode 2) of a program.
    A body that hands the pointer back where it found it sums to 0 (mod 256)."""
    print("=" * 78)
    print("POINTER CLOSURE -- sum of signed addr8 over mode-2 words, per program")
    print("=" * 78)
    tot0 = 0
    disp = []
    for nm, ws in progs.items():
        s = 0
        n = 0
        for w in ws:
            f = F(w)
            if f.cfmt:
                continue
            if (f.class4 & 7) == 2:
                s += s8(f.addr8)
                n += 1
        disp.append(s)
        if s % 256 == 0:
            tot0 += 1
        print("  %-28s  n=%3d   net %+6d   mod256 %3d%s"
              % (nm, n, s, s % 256, "   <- CLOSES" if s % 256 == 0 else ""))
    print("\n%d of %d programs close mod 256." % (tot0, len(progs)))
    # NULL: random signed values with the same marginal distribution
    pool = []
    for ws in progs.values():
        for w in ws:
            f = F(w)
            if not f.cfmt and (f.class4 & 7) == 2:
                pool.append(s8(f.addr8))
    rng = random.Random(5)
    hits = []
    counts = [sum(1 for w in ws
                  if not F(w).cfmt and (F(w).class4 & 7) == 2)
              for ws in progs.values()]
    for _b in range(args.B):
        h = 0
        for c in counts:
            if sum(rng.choice(pool) for _ in range(c)) % 256 == 0:
                h += 1
        hits.append(h)
    m = sum(hits) / len(hits)
    sd = math.sqrt(sum((x - m) ** 2 for x in hits) / len(hits))
    print("NULL (resampled from the pooled addr8 marginal): %.2f +- %.2f"
          % (m, sd))


# --------------------------------------------------------------------------
#  4.  field/value x effect family
# --------------------------------------------------------------------------
def fields_of(w):
    f = F(w)
    out = {"class4": f.class4, "hi12": f.hi12, "lo12": f.lo12,
           "addr8": f.addr8, "f98": f.f98, "f31": f.f31,
           "b4": f.b4, "b7": f.b7, "b10": f.b10, "b11": f.b11}
    if not f.cfmt:
        out["SRC"] = f.src
        out["ACT"] = f.act
        out["mode"] = f.class4 & 7
        out["(class4,SRC)"] = (f.class4, f.src)
        out["(f31,ACT)"] = (f.f31, f.act)
        out["(f98,f31)"] = (f.f98, f.f31)
    else:
        out["cfmt_lo12"] = f.lo12
        out["cfmt_A"] = f.imm13 >> 5
    return out


def cmd_family(progs, meta, args):
    bodies = [n for n in progs if n not in ("KERNEL", "EPILOGUE")]
    fam = {n: meta[n]["family"] for n in bodies}
    # (field, value) -> set of images
    where = collections.defaultdict(set)
    occ = collections.Counter()
    for nm in bodies:
        for w in progs[nm]:
            for k, v in fields_of(w).items():
                where[(k, v)].add(nm)
                occ[(k, v)] += 1
    famsizes = collections.Counter(fam.values())
    rng = random.Random(13)
    famlist = [fam[n] for n in bodies]

    def purity(S):
        c = collections.Counter(fam[n] for n in S)
        f, k = c.most_common(1)[0]
        return k / len(S), f

    # null: for each set size, the distribution of purity over random subsets
    nulls = {}
    for size in range(args.mink, len(bodies) + 1):
        vals = []
        for _b in range(args.B):
            S = rng.sample(bodies, size)
            vals.append(purity(S)[0])
        vals.sort()
        nulls[size] = (sum(vals) / len(vals), vals[int(0.99 * len(vals)) - 1])

    rows = []
    for key, S in where.items():
        if len(S) < args.mink:
            continue
        p, f = purity(S)
        mu, p99 = nulls[len(S)]
        rows.append((p - mu, p, mu, p99, f, len(S), occ[key], key))
    rows.sort(reverse=True)
    print("=" * 78)
    print("FIELD/VALUE x EFFECT FAMILY -- values that live in ONE family")
    print("images >= %d; purity = largest family's share of the images that" % args.mink)
    print("carry the value.  NULL = purity of a RANDOM image set of that size.")
    print("=" * 78)
    print("%-16s %-10s %5s %5s %6s %6s %6s  %s"
          % ("field", "value", "imgs", "occ", "purity", "null", "p99",
             "family"))
    shown = 0
    for d, p, mu, p99, f, k, o, key in rows:
        if p < args.minpurity or p <= p99:
            continue
        fld, val = key
        vs = ("%X" % val) if isinstance(val, int) else str(val)
        print("%-16s %-10s %5d %5d %6.2f %6.2f %6.2f  %s"
              % (fld, vs, k, o, p, mu, p99, f))
        shown += 1
        if shown >= args.top:
            break
    print("\nRows above the p99 of their own size-matched null are printed;")
    print("everything else matched its base rate and is NOT reported.")
    print("family sizes: %s" % dict(famsizes))


def cmd_cooc(progs, meta, args):
    """(field,value) pairs whose CO-OCCURRENCE with another field is
    exceptionless -- the sharpest kind of functional-selector candidate."""
    words = []
    for nm, ws in progs.items():
        for w in ws:
            words.append((nm, w))
    plain = [(nm, F(w)) for nm, w in words if not F(w).cfmt]
    print("=" * 78)
    print("EXCEPTIONLESS FIELD IMPLICATIONS over the %d plain words" % len(plain))
    print("A => B with support >= %d and 0 exceptions.  NULL: the same rule on"
          % args.minsup)
    print("column-shuffled words (each field resampled from its own marginal).")
    print("=" * 78)
    names = ["class4", "SRC", "ACT", "f98", "f31", "b4", "b7", "b10", "b11",
             "mode"]

    def build(rows):
        cols = {n: [] for n in names}
        for _nm, f in rows:
            d = {"class4": f.class4, "SRC": f.src, "ACT": f.act, "f98": f.f98,
                 "f31": f.f31, "b4": f.b4, "b7": f.b7, "b10": f.b10,
                 "b11": f.b11, "mode": f.class4 & 7}
            for n in names:
                cols[n].append(d[n])
        return cols

    def rules(cols, n):
        out = []
        for a in names:
            for b in names:
                if a == b:
                    continue
                m = collections.defaultdict(collections.Counter)
                for i in range(n):
                    m[cols[a][i]][cols[b][i]] += 1
                for av, c in m.items():
                    tot = sum(c.values())
                    if tot < args.minsup:
                        continue
                    if len(c) == 1:
                        bv = next(iter(c))
                        out.append((tot, a, av, b, bv))
        return out

    cols = build(plain)
    n = len(plain)
    obs = rules(cols, n)
    obs.sort(reverse=True)
    rng = random.Random(17)
    nl = []
    for _b in range(args.B):
        sh = {k: rng.sample(v, len(v)) for k, v in cols.items()}
        nl.append(len(rules(sh, n)))
    m = sum(nl) / len(nl)
    sd = math.sqrt(sum((x - m) ** 2 for x in nl) / len(nl))
    print("observed exceptionless rules: %d    NULL: %.1f +- %.1f (max %d)"
          % (len(obs), m, sd, max(nl)))
    for tot, a, av, b, bv in obs[:args.top]:
        print("   n=%-5d  %s == %X   =>   %s == %X" % (tot, a, av, b, bv))


def cmd_pos(progs, meta, args):
    """POSITIONAL structure: what does a body start and end with?  A macro
    assembler would emit a fixed prologue/epilogue."""
    bodies = {n: ws for n, ws in progs.items()
              if n not in ("KERNEL", "EPILOGUE")}
    print("=" * 78)
    print("BODY PROLOGUE / EPILOGUE -- the k-th word from each end")
    print("=" * 78)
    for tag, idx in (("FIRST", range(0, 5)), ("LAST", range(-1, -6, -1))):
        for k in idx:
            c = collections.Counter(fmt(ws[k]) for ws in bodies.values()
                                    if len(ws) > abs(k))
            top = c.most_common(4)
            print("  %-5s w%-4d %s" % (tag, k, "   ".join(
                "%s x%d" % (a, b) for a, b in top)))
    print()
    print("mean normalised POSITION of each word form (>=8 occurrences):")
    pos = collections.defaultdict(list)
    for nm, ws in bodies.items():
        for i, w in enumerate(ws):
            pos[fmt(w)].append(i / max(1, len(ws) - 1))
    rows = [(sum(v) / len(v), len(v), k) for k, v in pos.items()
            if len(v) >= args.minsup]
    rows.sort()
    print("   --- earliest ---")
    for m, n, k in rows[:8]:
        print("     %.3f  x%-4d %s" % (m, n, k))
    print("   --- latest ---")
    for m, n, k in rows[-8:]:
        print("     %.3f  x%-4d %s" % (m, n, k))


def cmd_traits(progs, meta, args):
    """The tsv `family` column puts 14 of 38 images in one bucket, `combi`,
    which swamps any family test.  This re-runs the family test on TRAITS
    derived from the effect NAME only (never from the words)."""
    bodies = [n for n in progs if n not in ("KERNEL", "EPILOGUE")]

    def traits(n):
        u = n.upper()
        t = set()
        for key, tr in (("CHORUS", "MOD"), ("FLANGER", "MOD"),
                        ("PHASER", "MOD"), ("VIBRATO", "MOD"),
                        ("ENSEMBLE", "MOD"), ("MIX UP", "MOD"),
                        ("ROTARY", "MOD"), ("PAN", "MOD"), ("RING", "MOD"),
                        ("DISTORTION", "DRIVE"), ("OVERDR", "DRIVE"),
                        ("FUZZ", "DRIVE"), ("DIST", "DRIVE"),
                        ("EXCITER", "DRIVE"),
                        ("COMPR", "DYN"), ("REVERB", "REVERB"),
                        ("DELAY", "DELAY"), ("PEQ", "EQ"),
                        ("PARAMETRIC EQ", "EQ"), ("WAH", "FILT"),
                        ("ENHANCER", "FILT")):
            if key in u:
                t.add(tr)
        return t or {"NONE"}

    T = {n: traits(n) for n in bodies}
    where = collections.defaultdict(set)
    occ = collections.Counter()
    for nm in bodies:
        for w in progs[nm]:
            for k, v in fields_of(w).items():
                where[(k, v)].add(nm)
                occ[(k, v)] += 1
    alltr = sorted({t for s in T.values() for t in s})
    rng = random.Random(23)
    print("=" * 78)
    print("FIELD/VALUE x TRAIT (traits read off the effect NAME, never the words)")
    print("images carrying a value >= %d; a value is reported when EVERY image"
          % args.mink)
    print("carrying it has trait X, and that is above the p99 of a size-matched")
    print("random-subset null.")
    print("=" * 78)
    hits = []
    for tr in alltr:
        have = [n for n in bodies if tr in T[n]]
        base = len(have) / len(bodies)
        # null: P(a random k-subset is entirely inside `have`)
        for key, S in where.items():
            if len(S) < args.mink:
                continue
            if not all(tr in T[n] for n in S):
                continue
            k = len(S)
            null = 1.0
            for j in range(k):
                null *= (len(have) - j) / (len(bodies) - j)
            hits.append((null, tr, key, k, occ[key], base))
    hits.sort()
    print("%-8s %-14s %-10s %5s %5s %9s" %
          ("trait", "field", "value", "imgs", "occ", "P(null)"))
    seen = set()
    for null, tr, key, k, o, base in hits[:args.top]:
        fld, val = key
        vs = ("%X" % val) if isinstance(val, int) else str(val)
        if (fld, vs) in seen:
            continue
        seen.add((fld, vs))
        print("%-8s %-14s %-10s %5d %5d %9.2e" % (tr, fld, vs, k, o, null))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["addr8", "family", "closure", "cooc", "pos",
                             "traits", "all"])
    ap.add_argument("-B", type=int, default=400)
    ap.add_argument("--top", type=int, default=40)
    ap.add_argument("--mink", type=int, default=3)
    ap.add_argument("--minpurity", type=float, default=0.8)
    ap.add_argument("--minsup", type=int, default=20)
    args = ap.parse_args()
    progs, meta = load()
    if args.cmd in ("addr8", "all"):
        cmd_addr8(progs, meta, args)
    if args.cmd in ("closure", "all"):
        print()
        cmd_closure(progs, meta, args)
    if args.cmd in ("family", "all"):
        print()
        cmd_family(progs, meta, args)
    if args.cmd in ("cooc", "all"):
        print()
        cmd_cooc(progs, meta, args)
    if args.cmd in ("pos", "all"):
        print()
        cmd_pos(progs, meta, args)
    if args.cmd in ("traits", "all"):
        print()
        cmd_traits(progs, meta, args)


if __name__ == "__main__":
    main()
