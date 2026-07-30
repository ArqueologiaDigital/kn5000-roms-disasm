#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""f31hi_census.py -- is `hi12[3:1]' one 3-bit field, or two fields aliased?

NEC uPD6383GF (Technics SX-KN5000, IC311).  `f31 = hi12[3:1]' is decoded for
values 0/1/2 and REFUSED for 3..7.  `analysis/f31-high.md' delivered a lead and
an enumerable parameter but not a decode; SPECULATIVE-APPLIED-REGISTER sect. 139
then showed the previous instruments were blind BY POPULATION -- essentially no
f31 in {4,5} word executes at cold boot, and the ones that do are the
operand-free NOP form.

This tool asks the question the execution instruments could not: what does the
CORPUS say about the ENCODING?  Not "what does f31=4 compute", but "is f31=4 a
free choice the designer made, or is it forced by the rest of the word?"

    python3 dsp/tools/f31hi_census.py pop        # the population, and its defect
    python3 dsp/tools/f31hi_census.py census     # the per-value census tables
    python3 dsp/tools/f31hi_census.py mi         # ★ contingency / mutual information
    python3 dsp/tools/f31hi_census.py pairs      # ★ minimal pairs
    python3 dsp/tools/f31hi_census.py bit5       # sect. 140 S1: is bit 5 the family?
    python3 dsp/tools/f31hi_census.py all

POPULATION (rule 9).  The IC311 population is *91 algorithm slots / 38 distinct
body images / 2974 words* (gen_dsp_disasm.py: streams 79/88/89/90/91 are IC310
MN19413 programs and 57..60 parse to nothing).  Every published f31 count so far
was taken over `delayline.ctx()', which carries 96 slots / 40 images / 3154
words -- i.e. it INCLUDES the IC310 images.  `pop' quantifies the difference.

See ../analysis/data/F31_HIGH_findings.md.
"""
import collections
import itertools
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as DIS                                            # noqa: E402
import lfo_ramp as L                                                # noqa: E402

HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
DSP2_MISPARSED = {79, 88, 89, 90, 91}       # IC310 (MN19413), NOT this chip

fmt = L.fmt


def hdr(t):
    print("\n" + "=" * 78 + "\n== %s\n" % t + "=" * 78)


# --------------------------------------------------------------------------
#  the corpus
# --------------------------------------------------------------------------
def _blk(addr):
    recs = L.parse_stream(addr, limit=40)
    for (op, _c, _ia, pl) in recs:
        if op == 3:
            return L.words5(pl)
    raise KeyError(addr)


def corpus(ic311_only=True):
    """[(region, key, name, index, nwords, word)] over the whole machine.

    region in {kernel, epilogue, body}.  `key' is the representative algo slot
    for a body image, or the region name.  Bodies are the DISTINCT images (one
    entry per image, not per slot) so no image is weighted by how many effect
    slots happen to share it.
    """
    rows = []
    for nm, addr in (("kernel", HEADER_ROM), ("epilogue", EPILOGUE_ROM)):
        ws = _blk(addr)
        for i, w in enumerate(ws):
            rows.append((nm, nm, nm, i, len(ws), w))
    a2i = L.algo_to_image()
    seen = {}
    for a in sorted(a2i):
        if ic311_only and a in DSP2_MISPARSED:
            continue
        ws = tuple(a2i[a][2])
        seen.setdefault(ws, a)
    for ws, a in sorted(seen.items(), key=lambda kv: kv[1]):
        nm = _name(a)
        for i, w in enumerate(ws):
            rows.append(("body", a, nm, i, len(ws), w))
    return rows


_NAMES = {0: "NO OPERATION", 1: "CHORUS", 2: "MODULATED CHORUS", 3: "ENHANCER",
          4: "FLANGER", 5: "PHASER", 6: "ENSEMBLE", 8: "GATED REVERB",
          9: "SINGLE DELAY", 10: "MULTI TAP DELAY", 15: "ROCK ROTARY",
          16: "ROOM REVERB 1", 32: "DISTORTION", 33: "OVERDRIVE", 34: "FUZZ",
          35: "EXCITER", 36: "COMPRESSOR", 39: "PARAMETRIC EQ", 48: "AUTO PAN",
          50: "VIBRATO", 52: "AUTO WAH", 54: "RING MODULATOR", 56: "MIX UP",
          64: "S.DELAY+CHORUS", 65: "S.DELAY x2", 66: "S.DELAY+FLANGER",
          67: "S.DELAY+VIBRATO", 68: "S.DELAY+PHASER", 70: "AUTO WAH+S.DELAY",
          71: "PEQ+CHORUS", 72: "PEQ+S.DELAY", 73: "PEQ+FLANGER",
          74: "PEQ+VIBRATO", 75: "PEQ+COMPRESSOR", 96: "PEQ+COMPR+DIST",
          97: "PEQ+COMPR+OVER", 98: "PEQ+DIST+DELAY", 99: "PEQ+OVER+DELAY",
          79: "[IC310] 79", 88: "[IC310] 88", 89: "[IC310] 89",
          90: "[IC310] 90", 91: "[IC310] 91"}


def _name(a):
    return _NAMES.get(a, "algo %d" % a)


# --------------------------------------------------------------------------
#  field hygiene -- sect. 139 sect. 2: f31 is NOT a field in the two alternate
#  formats.  C-format (hi12[11:8]==0xC) makes bits[24:12] one immediate that
#  reaches into hi12; the bit-11 escape repurposes bits[10:0].
# --------------------------------------------------------------------------
def plain(w):
    return not DIS.c_format(w) and not (DIS.hi12(w) & DIS.HI_ESC)


def f31(w):
    return DIS.hi_f31(DIS.hi12(w))


def f98(w):
    return DIS.hi_f98(DIS.hi12(w))


def bits(w):
    h = DIS.hi12(w)
    return {"b11esc": (h >> 11) & 1, "b10end": (h >> 10) & 1,
            "b9": (h >> 9) & 1, "b8": (h >> 8) & 1, "b7": (h >> 7) & 1,
            "b6": (h >> 6) & 1, "b5": (h >> 5) & 1, "b4st": (h >> 4) & 1,
            "b0": h & 1}


# --------------------------------------------------------------------------
#  pop -- the population and its defect
# --------------------------------------------------------------------------
def _published_basis():
    """`delayline.ctx()' -- the 40 images / 3154 words every published f31
    number was taken over.  It parses 96 slots, so it keeps the IC310 images
    that `lfo_ramp.algo_to_image()' (91 slots) drops."""
    import delayline as DL
    C = DL.ctx()
    seen = {}
    for a in sorted(C.imgs):
        seen.setdefault(tuple(C.imgs[a]), a)
    return {a: list(k) for k, a in seen.items()}


def cmd_pop():
    hdr("POPULATION -- and the defect in every published f31 count")
    pub = _published_basis()
    a2i = L.algo_to_image()
    seen = {}
    for a in sorted(a2i):
        seen.setdefault(tuple(a2i[a][2]), a)      # LOWEST slot, as pub does
    ic311 = {a: list(ws) for ws, a in seen.items()}
    keep = set(seen.values())
    extra = {a: ws for a, ws in pub.items() if a not in keep}
    for nm, d in (("PUBLISHED basis  (delayline.ctx, 96 slots)", pub),
                  ("IC311 ONLY       (algo_to_image, 91 slots)", ic311)):
        allw = [w for ws in d.values() for w in ws]
        c = collections.Counter(f31(w) for w in allw)
        cp = collections.Counter(f31(w) for w in allw if plain(w))
        print("\n  %s" % nm)
        print("     body images %2d   body words %4d" % (len(d), len(allw)))
        print("     f31>2 body words        : %3d  (plain %3d)"
              % (sum(v for k, v in c.items() if k > 2),
                 sum(v for k, v in cp.items() if k > 2)))
        print("     f31 histogram (all)     : %s" % [c[i] for i in range(8)])
        print("     f31 histogram (plain)   : %s" % [cp[i] for i in range(8)])
    print("\n  ★ the images the published basis adds -- IC310 (MN19413), "
          "NOT this chip:")
    tot = 0
    for a, ws in sorted(extra.items()):
        c = collections.Counter(f31(w) for w in ws)
        n = sum(v for k, v in c.items() if k > 2)
        tot += n
        print("     algo %-3d  %3d words  f31>2 = %-3d  histogram %s"
              % (a, len(ws), n, [c[i] for i in range(8)]))
    print("     ------------------------------------------------")
    print("     IC310 contribution to the published f31>2 count : %d" % tot)
    print("\n  ★ THE SHAPE ARGUMENT (f31-high.md item B/C) RE-RUN ON BOTH "
          "BASES -- body only,\n    all words, exactly as f31_high.py "
          "`shape' computes it:")
    for nm, d in (("PUBLISHED", pub), ("IC311 ONLY", ic311)):
        c = collections.Counter(f31(w) for ws in d.values() for w in ws)
        lo, hi = [c[i] for i in range(4)], [c[i] for i in range(4, 8)]
        exp = [v * sum(hi) / sum(lo) for v in lo]
        chi = sum((o - e) ** 2 / e for o, e in zip(hi, exp) if e)
        print("\n    %-11s bit2=0 %-24s  norm %s"
              % (nm, lo, ["%.3f" % (v / lo[0]) for v in lo]))
        print("    %-11s bit2=1 %-24s  norm %s"
              % ("", hi, ["%.3f" % (v / hi[0]) for v in hi]))
        print("    %-11s expected bit2=1 %-19s  chi2 = %.1f (3 df)"
              % ("", ["%.1f" % e for e in exp], chi))

    print("\n  kernel / epilogue (the same 83 words on both bases):")
    for nm, addr in (("kernel", HEADER_ROM), ("epilogue", EPILOGUE_ROM)):
        ws = _blk(addr)
        c = collections.Counter(f31(w) for w in ws)
        cp = collections.Counter(f31(w) for w in ws if plain(w))
        print("     %-9s %2d words  all %s  plain %s"
              % (nm, len(ws), [c[i] for i in range(8)],
                 [cp[i] for i in range(8)]))
    print("""
  Every f31 number in f31-high.md and sect. 139 was taken over the PUBLISHED
  basis, which mixes two different chips' instruction streams.  The IC311
  answer is the second row.""")


# --------------------------------------------------------------------------
#  census
# --------------------------------------------------------------------------
def _top(counter, n=6):
    return " ".join("%s:%d" % (k, v) for k, v in counter.most_common(n))


def cmd_census(rows=None):
    hdr("PER-VALUE CENSUS -- all 8 f31 values, IC311 population")
    rows = rows or corpus()
    print("  PLAIN words only (f31 is not a field inside C-format or the "
          "bit-11 escape).\n")
    print("  %-3s %6s %6s  %-22s %-20s %-20s"
          % ("f31", "plain", "imgs", "class4", "SRC", "ACT"))
    print("  " + "-" * 92)
    for f in range(8):
        sel = [r for r in rows if plain(r[5]) and f31(r[5]) == f]
        if not sel:
            print("  %-3d %6d" % (f, 0))
            continue
        print("  %-3d %6d %6d  %-22s %-20s %-20s"
              % (f, len(sel), len({r[1] for r in sel}),
                 _top(collections.Counter("%X" % DIS.class4(r[5]) for r in sel), 5),
                 _top(collections.Counter("%02X" % DIS.lo_src(r[5]) for r in sel), 4),
                 _top(collections.Counter("%02X" % DIS.lo_act(r[5]) for r in sel), 4)))

    print("\n  flags, per value (fraction of the plain population):")
    print("  %-3s %6s  %6s %6s %6s %6s %6s %6s  %7s %7s"
          % ("f31", "plain", "b10END", "b7", "b6", "b5", "b4ST", "b0",
             "meanpos", "distHi"))
    print("  " + "-" * 92)
    for f in range(8):
        sel = [r for r in rows if plain(r[5]) and f31(r[5]) == f]
        if not sel:
            continue
        n = len(sel)
        bb = [bits(r[5]) for r in sel]
        pos = [r[3] / max(1, r[4] - 1) for r in sel]
        print("  %-3d %6d  %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f  %7.3f %7d"
              % (f, n,
                 sum(b["b10end"] for b in bb) / n, sum(b["b7"] for b in bb) / n,
                 sum(b["b6"] for b in bb) / n, sum(b["b5"] for b in bb) / n,
                 sum(b["b4st"] for b in bb) / n, sum(b["b0"] for b in bb) / n,
                 sum(pos) / n, len({DIS.hi12(r[5]) for r in sel})))

    print("\n  region split (plain words):")
    print("  %-3s %8s %8s %10s   %s" % ("f31", "kernel", "epilogue", "body",
                                        "non-plain (C-fmt / ESC) same f-bits"))
    print("  " + "-" * 92)
    for f in range(8):
        sel = [r for r in rows if plain(r[5]) and f31(r[5]) == f]
        np_ = [r for r in rows if not plain(r[5]) and f31(r[5]) == f]
        rc = collections.Counter(r[0] for r in sel)
        print("  %-3d %8d %8d %10d   %d"
              % (f, rc["kernel"], rc["epilogue"], rc["body"], len(np_)))

    print("\n  ★ f31 > 2: every distinct WORD, with the images that carry it")
    print("  " + "-" * 92)
    shapes = collections.defaultdict(list)
    for r in rows:
        if plain(r[5]) and f31(r[5]) > 2:
            shapes[r[5]].append(r)
    for w in sorted(shapes, key=lambda w: (-len(shapes[w]), w)):
        sel = shapes[w]
        names = sorted({r[2] for r in sel})
        print("  %s  f31=%d  n=%-3d  %s"
              % (fmt(w), f31(w), len(sel),
                 (", ".join(names))[:70] + (" ..." if len(", ".join(names)) > 70 else "")))
    print("\n  distinct f31>2 word shapes: %d over %d words"
          % (len(shapes), sum(len(v) for v in shapes.values())))
    return rows


# --------------------------------------------------------------------------
#  mi -- the aliasing test
# --------------------------------------------------------------------------
def _H(counter):
    n = sum(counter.values())
    return -sum(v / n * math.log2(v / n) for v in counter.values() if v)


def _mi(pairs):
    """I(X;Y), H(X), H(Y), H(X|Y) over a list of (x, y)."""
    n = len(pairs)
    cx, cy, cxy = collections.Counter(), collections.Counter(), collections.Counter()
    for x, y in pairs:
        cx[x] += 1
        cy[y] += 1
        cxy[(x, y)] += 1
    hx, hy, hxy = _H(cx), _H(cy), _H(cxy)
    return hx + hy - hxy, hx, hy, hxy - hy


def cmd_mi(rows=None):
    hdr("★ CONTINGENCY / MUTUAL INFORMATION -- is f31 free, or forced?")
    rows = rows or corpus()
    P = [r for r in rows if plain(r[5])]
    print("""  NULL-A (f31 is a genuine free opcode field): knowing the rest of the
  word should NOT predict it, so H(f31|Y) stays near H(f31).
  NULL-B / ALIASING (f31's high bit is a family marker set by something else):
  some single other field predicts it almost perfectly, H(f31|Y) -> small.

  Shuffled null: I is biased upward by finite samples; `Inull' is the mean of
  20 label-shuffles, so `I - Inull' is the honest excess.
""")
    import random
    F = [f31(r[5]) for r in P]
    feats = {
        "class4": [DIS.class4(r[5]) for r in P],
        "addr8": [DIS.addr8(r[5]) for r in P],
        "lo12": [DIS.lo12(r[5]) for r in P],
        "SRC": [DIS.lo_src(r[5]) for r in P],
        "ACT": [DIS.lo_act(r[5]) for r in P],
        "f98": [f98(r[5]) for r in P],
        "hi12 b10END": [bits(r[5])["b10end"] for r in P],
        "hi12 b7": [bits(r[5])["b7"] for r in P],
        "hi12 b6": [bits(r[5])["b6"] for r in P],
        "★ hi12 b5": [bits(r[5])["b5"] for r in P],
        "hi12 b4ST": [bits(r[5])["b4st"] for r in P],
        "hi12 b0": [bits(r[5])["b0"] for r in P],
        "hi12 non-f31 bits": [DIS.hi12(r[5]) & ~0x00E for r in P],
        "image": [r[1] for r in P],
        "(class4,SRC,ACT)": [(DIS.class4(r[5]), DIS.lo_src(r[5]),
                              DIS.lo_act(r[5])) for r in P],
    }
    hf = _H(collections.Counter(F))
    print("  H(f31) = %.4f bits over %d plain words\n" % (hf, len(P)))
    print("  %-22s %8s %8s %9s %9s %7s"
          % ("Y", "H(Y)", "I(f31;Y)", "I-Inull", "H(f31|Y)", "NMI"))
    print("  " + "-" * 78)
    out = {}
    for nm, ys in feats.items():
        pr = list(zip(F, ys))
        i, hx, hy, hxgy = _mi(pr)
        nulls = []
        for _k in range(20):
            sh = F[:]
            random.Random(_k).shuffle(sh)
            nulls.append(_mi(list(zip(sh, ys)))[0])
        inull = sum(nulls) / len(nulls)
        nmi = i / min(hx, hy) if min(hx, hy) > 0 else 0.0
        out[nm] = (i, inull, hxgy, nmi)
        print("  %-22s %8.4f %8.4f %9.4f %9.4f %7.3f"
              % (nm, hy, i, i - inull, hxgy, nmi))

    print("\n  ★ THE ALIASING QUESTION, stated as a 2x2: does some bit predict "
          "f31>2?")
    print("  %-14s %10s %10s %10s %10s %8s"
          % ("bit", "0 & f<=2", "0 & f>2", "1 & f<=2", "1 & f>2", "NMI"))
    print("  " + "-" * 78)
    for nm in ("hi12 b10END", "hi12 b7", "hi12 b6", "★ hi12 b5",
               "hi12 b4ST", "hi12 b0"):
        ys = feats[nm]
        t = collections.Counter(zip(ys, [f > 2 for f in F]))
        pr = list(zip([f > 2 for f in F], ys))
        i, hx, hy, _ = _mi(pr)
        nmi = i / min(hx, hy) if min(hx, hy) > 0 else 0.0
        print("  %-14s %10d %10d %10d %10d %8.3f"
              % (nm, t[(0, False)], t[(0, True)], t[(1, False)], t[(1, True)],
                 nmi))
    return out


# --------------------------------------------------------------------------
#  pairs -- the minimal pairs
# --------------------------------------------------------------------------
def cmd_pairs(rows=None):
    hdr("★ MINIMAL PAIRS -- words identical everywhere except f31")
    rows = rows or corpus()
    P = [r for r in rows if plain(r[5])]
    ctx = collections.defaultdict(dict)          # key -> {f31: [rows]}
    for r in P:
        w = r[5]
        key = (DIS.hi12(w) & ~0x00E, DIS.class4(w), DIS.addr8(w), DIS.lo12(w))
        ctx[key].setdefault(f31(w), []).append(r)
    hits = {k: v for k, v in ctx.items() if len(v) > 1}
    print("""  A pair is two corpus words with the SAME class4, addr8, lo12 and the
  SAME hi12 outside bits [3:1].  If f31 is a real operation select, such
  pairs are the designer choosing a different operation on an otherwise
  identical word -- the highest-value evidence in a static corpus.
""")
    print("  contexts with >1 distinct f31 : %d of %d" % (len(hits), len(ctx)))
    involving_hi = {k: v for k, v in hits.items() if any(f > 2 for f in v)}
    print("  ... of which at least one arm has f31 > 2 : %d\n"
          % len(involving_hi))
    for k in sorted(hits, key=lambda k: (-max(f for f in hits[k]), k)):
        v = hits[k]
        star = "★ " if any(f > 2 for f in v) else "  "
        arms = []
        for f in sorted(v):
            ws = v[f]
            arms.append("f31=%d %s x%d [%s]"
                        % (f, fmt(ws[0][5]), len(ws),
                           ",".join(sorted({str(r[1]) for r in ws}))[:38]))
        print("  %s%s" % (star, "\n      ".join(arms)))
        print()

    print("  ★ RELAXED: same class4/addr8/lo12, hi12 free (a WEAKER pair --")
    print("    other hi12 bits may also differ; used only to bound the search)")
    ctx2 = collections.defaultdict(set)
    for r in P:
        w = r[5]
        ctx2[(DIS.class4(w), DIS.addr8(w), DIS.lo12(w))].add(f31(w))
    rel = {k: v for k, v in ctx2.items() if len(v) > 1 and any(f > 2 for f in v)}
    print("    relaxed contexts mixing f31>2 with anything else : %d" % len(rel))
    for k in sorted(rel)[:20]:
        print("      class %X addr %02X lo %03X : f31 %s"
              % (k[0], k[1], k[2], sorted(rel[k])))
    return hits


# --------------------------------------------------------------------------
#  bit5 -- sect. 140 S1
# --------------------------------------------------------------------------
def cmd_bit5(rows=None):
    hdr("sect.140 S1 -- is hi12 bit 5 the family marker that redefines f31?")
    rows = rows or corpus()
    P = [r for r in rows if plain(r[5])]
    for b in (0, 1):
        sel = [r for r in P if bits(r[5])["b5"] == b]
        c = collections.Counter(f31(r[5]) for r in sel)
        hi = sum(v for k, v in c.items() if k > 2)
        print("\n  bit5=%d : %4d words   f31>2 = %3d (%.2f%%)"
              % (b, len(sel), hi, 100.0 * hi / max(1, len(sel))))
        print("     f31 histogram: %s" % [c[i] for i in range(8)])
        print("     class4       : %s"
              % _top(collections.Counter("%X" % DIS.class4(r[5]) for r in sel), 6))
        print("     distinct hi12: %d" % len({DIS.hi12(r[5]) for r in sel}))
    print("""
  S1 kill-criterion (sect. 140): find ONE bit-5-CLEAR word whose behaviour
  matches a bit-5-SET word of the same f31.  Statically the nearest thing is a
  minimal pair across bit 5 at equal f31 -- listed below.""")
    ctx = collections.defaultdict(set)
    for r in P:
        w = r[5]
        ctx[(DIS.hi12(w) & ~0x020, DIS.class4(w), DIS.addr8(w),
             DIS.lo12(w))].add(bits(w)["b5"])
    b5pairs = [k for k, v in ctx.items() if len(v) > 1]
    print("\n  byte-identical-except-bit-5 contexts : %d" % len(b5pairs))
    for k in sorted(b5pairs):
        print("     hi12 %03X/%03X  class %X addr %02X lo %03X  (f31=%d)"
              % (k[0], k[0] | 0x20, k[1], k[2], k[3], (k[0] >> 1) & 7))


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "all"
    rows = corpus()
    if cmd in ("all", "pop"):
        cmd_pop()
    if cmd in ("all", "census"):
        cmd_census(rows)
    if cmd in ("all", "mi"):
        cmd_mi(rows)
    if cmd in ("all", "pairs"):
        cmd_pairs(rows)
    if cmd in ("all", "bit5"):
        cmd_bit5(rows)


if __name__ == "__main__":
    main()
