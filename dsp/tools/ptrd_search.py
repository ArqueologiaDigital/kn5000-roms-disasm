#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""ptrd_search.py -- enumerative search for the uPD6383GF pointer-DELTA rule.

NEC uPD6383GF (Technics SX-KN5000 IC311).  Static, offline, ROM-only, stdlib-only.

`addr8` is a signed post-increment on the data pointer (MEASURED,
kn7000_mame/notes/kn5000-dsp-pointer.md sect. 8 item 2).  WHICH words carry one
is NOT established.  The rule in force is "class4 in {2, 0xA}", and the owning
note sect. 6 shows it wrong on four producer/consumer pairs that must resolve to
the same cell:

    C1  a05 PHASER          chain READS {0x76}   modulator WRITES {0x7B}   +5
    C2  a68 S.DELAY+PHASER  chain READS {0x76}   modulator WRITES {0x77}   +1
    C3  a03 ENHANCER        READS {0x7E,0x7F}    WRITES {0x7B,0x7C}        -3
    C4  a01 CHORUS          w28 (202.A.07.1D5) must read the cell w5/w6/w7 write  -2

    P1  the 3-word all-pass sections are net-zero  (30 of 38 under the current rule)
    P1s all 20 of a05's chain reads land on ONE cell
    P2  a39 PARAMETRIC EQ walks +4 per band  (8 gaps)
    P3  8 of 9 a16 reverb diffusers stationary

Every constraint is a DIFFERENCE of two pointer values inside one image, so the
per-unit origin cancels identically.  This tool never uses an origin.

    section 1  the CONTROL -- reproduce the current rule's stated behaviour
    section 2  the search space and its size
    section 3  exhaustive enumeration, full score distribution vs the NULL
    section 3b TIER 3 -- independent gates for class 2 and class 0xA
    section 4  the survivors, with per-image arithmetic
    section 5  header validation of every surviving gate

Exactness note: a class whose gated delta is zero at every word of every probe
image cannot change any pointer, so all 2^(16-|A|) subsets that differ only in
such classes behave identically.  The tool enumerates the |A| ACTIVE classes and
multiplies the counts back up -- the reported distribution is over the FULL
2 x 65536 x |G| space, exactly, with no sampling.

Usage:  python3 dsp/tools/ptrd_search.py [--quick]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pat_corpus as PC                                       # noqa: E402

F = PC.F


def s8(v):
    return v - 256 if v & 0x80 else v


PROBE = ["a01 CHORUS", "a03 ENHANCER", "a05 PHASER",
         "a68 S.DELAY+PHASER", "a39 PARAMETRIC EQ", "a16 ROOM REVERB 1"]

APMARK = 0x104200000                    # a16's all-pass marker word
BANDMARK = (0x102, 2, 0xFF, 0x687)      # a39's biquad band marker
CRIT = ["C1", "C2", "C3", "C4", "P1", "P2", "P3"]

# ---------------------------------------------------------------------------
#  N -- NON-DEGENERACY.  Not pre-registered: added after the first run, which
#  showed C1-C4 can all be satisfied VACUOUSLY by a rule under which the
#  pointer never moves in those images (0 == 0).  "A criterion that cannot fail
#  is not a test" (LEDGER rule 8), so the score-7 bucket had to be re-audited.
#
#  Grounding: an n-section all-pass chain needs n DISTINCT one-sample state
#  cells; a03/a05/a68 have 8/20/10 sections (the P1 population, 38 total).  A
#  rule that gives the phaser fewer distinct pointer values than it has
#  sections cannot be describing the machine.
# ---------------------------------------------------------------------------
NDEG = {"a03 ENHANCER": 8, "a05 PHASER": 20, "a68 S.DELAY+PHASER": 10}


def reads(ws):
    return [i for i, w in enumerate(ws)
            if F(w).hi12 == 0x102 and F(w).class4 == 2 and F(w).lo12 == 0x1CD]


def writes(ws):
    return [i for i, w in enumerate(ws)
            if F(w).hi12 == 0x212 and F(w).class4 == 0xA and F(w).lo12 == 0x1D5]


def ap_sections(ws):
    r = set(reads(ws))
    return sorted(i for i in r if i + 2 < len(ws) and F(ws[i + 1]).hi12 == 0x212)


def band_marks(ws):
    return [i for i, w in enumerate(ws)
            if (F(w).hi12, F(w).class4, F(w).addr8, F(w).lo12) == BANDMARK]


def ap_marks(ws):
    return [i for i, w in enumerate(ws) if w == APMARK]


# ---------------------------------------------------------------------------
#  gates -- built mechanically from the decoded fields
# ---------------------------------------------------------------------------
def build_gates(fields_by_prog):
    acts, srcs, lo12s = set(), set(), set()
    for fl in fields_by_prog.values():
        for f in fl:
            acts.add(f.act)
            srcs.add(f.src)
            lo12s.add(f.lo12)
    G = [("ALL", lambda f: True)]
    for nm, fn in (("cfmt", lambda f: f.cfmt),
                   ("b11", lambda f: bool(f.b11)),
                   ("b10", lambda f: bool(f.b10)),
                   ("b7", lambda f: bool(f.b7)),
                   ("b4", lambda f: bool(f.b4))):
        G.append((nm, fn))
        G.append(("!" + nm, (lambda g: lambda f: not g(f))(fn)))
    for k in range(4):
        G.append(("f98==%d" % k, (lambda v: lambda f: f.f98 == v)(k)))
        G.append(("f98!=%d" % k, (lambda v: lambda f: f.f98 != v)(k)))
    for k in range(8):
        G.append(("f31==%d" % k, (lambda v: lambda f: f.f31 == v)(k)))
        G.append(("f31!=%d" % k, (lambda v: lambda f: f.f31 != v)(k)))
    for v in sorted(acts):
        G.append(("ACT==%02X" % v, (lambda u: lambda f: f.act == u)(v)))
        G.append(("ACT!=%02X" % v, (lambda u: lambda f: f.act != u)(v)))
    for v in sorted(srcs):
        G.append(("SRC==%02X" % v, (lambda u: lambda f: f.src == u)(v)))
        G.append(("SRC!=%02X" % v, (lambda u: lambda f: f.src != u)(v)))
    for v in sorted(lo12s):
        G.append(("lo12==%03X" % v, (lambda u: lambda f: f.lo12 == u)(v)))
        G.append(("lo12!=%03X" % v, (lambda u: lambda f: f.lo12 != u)(v)))
    return G


# ---------------------------------------------------------------------------
class Scorer:
    def __init__(self, progs):
        self.progs = {k: progs[k] for k in PROBE}
        self.fields = {k: [F(w) for w in v] for k, v in self.progs.items()}
        self.idx = {}
        cur = 0
        for k in PROBE:
            ws = self.progs[k]
            need = set(reads(ws)) | set(writes(ws))
            for i in ap_sections(ws):
                need |= {i, i + 3}
            bm = set(band_marks(ws))
            for i in bm:
                need |= {i, i + 9}
            for i in ap_marks(ws):
                need |= {i, i + 5}
            if k == "a01 CHORUS":
                need |= {5, 28}                 # C4: producer block / consumer
            if k in NDEG:
                need |= set(range(len(ws)))     # N: distinct-cell count
            need = sorted(i for i in need if i <= len(ws))
            self.idx[k] = {i: cur + n for n, i in enumerate(need)}
            cur += len(need)
        self.ncol = cur
        # the constraint plans, resolved to column numbers once
        self.plan_read = {}
        self.plan_write = {}
        for tag, prog in (("C1", "a05 PHASER"), ("C2", "a68 S.DELAY+PHASER"),
                          ("C3", "a03 ENHANCER")):
            ws = self.progs[prog]
            self.plan_read[tag] = [self.idx[prog][i] for i in reads(ws)]
            self.plan_write[tag] = [self.idx[prog][i] for i in writes(ws)]
        p = "a01 CHORUS"
        self.c4 = (self.idx[p][28], self.idx[p][5])
        self.p1 = []
        for prog in ("a03 ENHANCER", "a05 PHASER", "a68 S.DELAY+PHASER"):
            ws = self.progs[prog]
            for i in ap_sections(ws):
                self.p1.append((self.idx[prog][i], self.idx[prog][i + 3]))
        self.p1s = self.plan_read["C1"]
        prog = "a39 PARAMETRIC EQ"
        ws = self.progs[prog]
        bm = set(band_marks(ws))
        self.p2 = [(self.idx[prog][m], self.idx[prog][m + 9])
                   for m in sorted(bm) if (m + 9) in bm]
        prog = "a16 ROOM REVERB 1"
        ws = self.progs[prog]
        self.p3 = [(self.idx[prog][m], self.idx[prog][m + 5]) for m in ap_marks(ws)]
        self.ndeg = [([self.idx[p][i] for i in range(len(self.progs[p]))], n)
                     for p, n in sorted(NDEG.items())]

    # ----------------------------------------------------------------
    def columns(self, gate_fn, signed=True):
        """-> {class4: [ptr contribution at each probe column]} for ACTIVE classes."""
        cols = {}
        for k in PROBE:
            fl = self.fields[k]
            n = len(fl)
            per = {}
            for i, f in enumerate(fl):
                if not gate_fn(f):
                    continue
                d = s8(f.addr8) if signed else f.addr8
                if d:
                    per.setdefault(f.class4, []).append((i, d))
            for cls, evs in per.items():
                if cls not in cols:
                    cols[cls] = [0] * self.ncol
                # pointer at word i = sum of deltas of words strictly before i
                run = [0] * (n + 1)
                acc = 0
                j = 0
                evs.sort()
                for i in range(n + 1):
                    while j < len(evs) and evs[j][0] < i:
                        acc += evs[j][1]
                        j += 1
                    run[i] = acc
                for i, col in self.idx[k].items():
                    cols[cls][col] = run[min(i, n)]
        return cols

    # ----------------------------------------------------------------
    def evaluate(self, P):
        """P = list of pointer values at every probe column. -> (dict, extras)"""
        res = {}
        for tag in ("C1", "C2", "C3"):
            r = {P[c] for c in self.plan_read[tag]}
            w = {P[c] for c in self.plan_write[tag]}
            res[tag] = (r == w)
        res["C4"] = (P[self.c4[0]] == P[self.c4[1]])
        n1 = 0
        for a, b in self.p1:
            if P[b] - P[a] == 0:
                n1 += 1
        res["P1"] = (n1 >= 30)
        vals = {P[c] for c in self.p1s}
        p1s = (len(vals) == 1)
        ok2 = all(P[b] - P[a] == 4 for a, b in self.p2)
        res["P2"] = ok2
        n3 = sum(1 for a, b in self.p3 if P[b] - P[a] == 0)
        res["P3"] = (n3 >= 8)
        nd = True
        cells = []
        for colset, need in self.ndeg:
            d = len({P[c] for c in colset})
            cells.append(d)
            if d < need:
                nd = False
        return res, (n1, p1s, n3, nd, cells)


def name_subset(mask):
    return "{" + ",".join("%X" % c for c in range(16) if (mask >> c) & 1) + "}"


def combine(cols, classes):
    """Pointer vector for the subset `classes` (an iterable of class4 values)."""
    it = iter(classes)
    try:
        first = next(it)
    except StopIteration:
        return None
    P = list(cols[first])
    for c in it:
        cc = cols[c]
        for i in range(len(P)):
            P[i] += cc[i]
    return P


# ---------------------------------------------------------------------------
def sect1_control(sc):
    print("=" * 78)
    print("1. CONTROL -- reproduce the CURRENT rule (class4 in {2,A}, signed)")
    print("=" * 78)
    cols = sc.columns(lambda f: True, signed=True)
    P = combine(cols, [c for c in (2, 0xA) if c in cols]) or [0] * sc.ncol
    res, (n1, p1s, n3, nd, cells) = sc.evaluate(P)
    print()
    for tag, prog in (("C1", "a05 PHASER"), ("C2", "a68 S.DELAY+PHASER"),
                      ("C3", "a03 ENHANCER")):
        r = sorted({P[c] for c in sc.plan_read[tag]})
        w = sorted({P[c] for c in sc.plan_write[tag]})
        print("  %s  %-20s READS %-12s WRITES %-12s  miss %+d   [abs under the"
              " note's own origin 0x70: %s vs %s]"
              % (tag, prog, r, w, w[0] - r[0],
                 ",".join("%02X" % (0x70 + v) for v in r),
                 ",".join("%02X" % (0x70 + v) for v in w)))
    a, b = P[sc.c4[0]], P[sc.c4[1]]
    print("  C4  %-20s consumer w28 at %+d   producer w5/6/7 at %+d   miss %+d"
          % ("a01 CHORUS", a, b, a - b))
    print()
    print("  P1  3-word all-pass sections net-zero : %d of %d" % (n1, len(sc.p1)))
    print("  P1s a05's 20 chain reads on ONE cell  : %s  (%d reads)"
          % (p1s, len(sc.p1s)))
    print("  P2  a39 bands advancing exactly +4    : %s  (%d gaps)"
          % (res["P2"], len(sc.p2)))
    print("  P3  a16 diffusers stationary          : %d of %d" % (n3, len(sc.p3)))
    print("  N   distinct pointer cells a03/a05/a68: %s  (need >= 8/20/10)  -> %s"
          % (cells, nd))
    score = sum(1 for c in CRIT if res[c])
    print("\n  CONTROL SCORE %d/7   (%s)"
          % (score, " ".join("%s=%s" % (c, "Y" if res[c] else "n") for c in CRIT)))
    ok = (n1 == 30 and n3 == 8 and res["P2"] and p1s and
          not res["C1"] and not res["C2"] and not res["C3"] and not res["C4"])
    print("\n  R3 (known-answer control): %s" % ("PASS" if ok else "*** FAIL ***"))
    return ok


def sect2_space(gates):
    print()
    print("=" * 78)
    print("2. THE SEARCH SPACE")
    print("=" * 78)
    ng = len(gates)
    print("""
  A candidate is (sign, S, g):
      sign in {signed, unsigned}                                          2
      S    subset of the 16 class4 values that carry a delta          65536
      g    one gate -- an extra necessary condition on the word      %6d
  --------------------------------------------------------------------------
  TIER 1   sign x S, gate = ALL                                     %8d
  TIER 2   sign x S x g   (TIER 1 is the g = ALL slice)             %8d
  TIER 3   independent gate for class 2 and class A, others off     %8d
""" % (ng, 2 * 65536, 2 * 65536 * ng, (ng + 1) ** 2))
    return ng


def enumerate_tiers(sc, gates, quick=False):
    print("=" * 78)
    print("3. EXHAUSTIVE ENUMERATION, AND THE NULL")
    print("=" * 78)
    tally = {1: [0] * 8, 2: [0] * 8}
    tallyN = {1: [0] * 8, 2: [0] * 8}
    ndtot = {1: 0, 2: 0}
    percrit = {1: dict.fromkeys(CRIT, 0), 2: dict.fromkeys(CRIT, 0)}
    percritN = {1: dict.fromkeys(CRIT, 0), 2: dict.fromkeys(CRIT, 0)}
    combos = {}                      # which subsets of C1..C4 are jointly reachable
    ppp = {1: [0, 0], 2: [0, 0]}     # [rules with P1&P2&P3 & N, of which also C4]
    survivors = []
    best_nd = []
    glist = gates[:1] if quick else gates
    for gi, (gname, gfn) in enumerate(glist):
        for signed in (True, False):
            cols = sc.columns(gfn, signed=signed)
            active = sorted(cols)
            free = 16 - len(active)
            mult = 1 << free
            na = len(active)
            for m in range(1 << na):
                chosen = [active[k] for k in range(na) if (m >> k) & 1]
                P = combine(cols, chosen)
                if P is None:
                    P = [0] * sc.ncol
                res, extra = sc.evaluate(P)
                nd = extra[3]
                sk = sum(1 for c in CRIT if res[c])
                mask = 0
                for c in chosen:
                    mask |= 1 << c
                for tier in ((1, 2) if gname == "ALL" else (2,)):
                    tally[tier][sk] += mult
                    for c in CRIT:
                        if res[c]:
                            percrit[tier][c] += mult
                    if nd:
                        ndtot[tier] += mult
                        if res["P1"] and res["P2"] and res["P3"]:
                            ppp[tier][0] += mult
                            if res["C4"]:
                                ppp[tier][1] += mult
                        tallyN[tier][sk] += mult
                        for c in CRIT:
                            if res[c]:
                                percritN[tier][c] += mult
                if nd:
                    key = tuple(c for c in ("C1", "C2", "C3", "C4") if res[c])
                    rec = (sk, gname, "signed" if signed else "unsigned", mask,
                           free, dict(res), extra)
                    if key not in combos or sk > combos[key][0]:
                        combos[key] = rec
                    if sk >= 4:
                        best_nd.append(rec)
                if sk >= 6:
                    survivors.append((sk, gname, "signed" if signed else "unsigned",
                                      mask, free, dict(res), extra))
        if not quick and (gi + 1) % 40 == 0:
            print("    ... %d/%d gates" % (gi + 1, len(glist)))
    return (tally, tallyN, ndtot, percrit, percritN, survivors, best_nd, combos, ppp)


def sect3_report(tally, tallyN, ndtot, percrit, percritN, ngates):
    tot1 = 2 * 65536
    tot2 = 2 * 65536 * ngates
    print()
    print("  SCORE DISTRIBUTION -- a rule scores 0..7 over C1 C2 C3 C4 P1 P2 P3")
    print("  (exact counts over the whole space; no sampling)")
    print()
    print("    score |  TIER 1 = %d rules   |  TIER 1+2 = %d rules" % (tot1, tot2))
    print("    ------+-------------------------+---------------------------------")
    for k in range(8):
        a, b = tally[1][k], tally[2][k]
        print("      %d   | %10d  %8.4f%%  | %13d  %9.5f%%"
              % (k, a, 100.0 * a / tot1, b, 100.0 * b / max(tot2, 1)))
    print()
    print("  ★ THE SAME DISTRIBUTION, RESTRICTED TO **NON-DEGENERATE** RULES (N)")
    print("    N = the phaser images get at least as many distinct pointer cells as")
    print("    they have all-pass sections (8/20/10).  Without N, C1-C4 are all")
    print("    satisfiable VACUOUSLY by freezing the pointer -- 0 == 0.")
    print()
    print("    non-degenerate rules: tier1 %d of %d (%.4f%%),  tier1+2 %d of %d (%.4f%%)"
          % (ndtot[1], tot1, 100.0 * ndtot[1] / tot1,
             ndtot[2], tot2, 100.0 * ndtot[2] / max(tot2, 1)))
    print()
    print("    score |  TIER 1 & N              |  TIER 1+2 & N")
    print("    ------+-------------------------+---------------------------------")
    for k in range(8):
        a, b = tallyN[1][k], tallyN[2][k]
        print("      %d   | %10d  %8.4f%%  | %13d  %9.5f%%"
              % (k, a, 100.0 * a / max(ndtot[1], 1), b,
                 100.0 * b / max(ndtot[2], 1)))
    print()
    print("  PER-CRITERION HIT RATE  -- this IS the per-criterion null")
    print()
    for c in CRIT:
        print("    %-3s  all: t1 %8d = %7.3f%%  t1+2 %10d = %7.4f%%   |  "
              "N-only: t1 %7d = %7.3f%%  t1+2 %9d = %7.4f%%"
              % (c, percrit[1][c], 100.0 * percrit[1][c] / tot1,
                 percrit[2][c], 100.0 * percrit[2][c] / max(tot2, 1),
                 percritN[1][c], 100.0 * percritN[1][c] / max(ndtot[1], 1),
                 percritN[2][c], 100.0 * percritN[2][c] / max(ndtot[2], 1)))


def sect3c_combos(combos):
    print()
    print("  ★ WHICH SUBSETS OF {C1,C2,C3,C4} ARE JOINTLY REACHABLE AT ALL,")
    print("    over the whole space, by a NON-DEGENERATE rule:")
    print()
    for key in sorted(combos, key=lambda k: (-len(k), k)):
        sk, gname, sign, mask, free, res, extra = combos[key]
        print("    %-16s  best example: classes %-16s gate %-14s %s  "
              "(score %d/7, P1 %d, P2 %s, P3 %d)"
              % ("{" + ",".join(key) + "}" if key else "{}",
                 name_subset(mask), gname, sign, sk, extra[0], res["P2"], extra[2]))
    got = {len(k) for k in combos}
    print("\n    largest jointly-reachable subset of C1..C4 under N: %d of 4"
          % (max(got) if got else 0))


def per_image_arithmetic(sc, mask, gfn, signed):
    cols = sc.columns(gfn, signed=signed)
    chosen = [c for c in range(16) if (mask >> c) & 1 and c in cols]
    P = combine(cols, chosen) or [0] * sc.ncol
    res, (n1, p1s, n3, nd, cells) = sc.evaluate(P)
    out = []
    for tag, prog in (("C1", "a05 PHASER"), ("C2", "a68 S.DELAY+PHASER"),
                      ("C3", "a03 ENHANCER")):
        r = sorted({P[c] for c in sc.plan_read[tag]})
        w = sorted({P[c] for c in sc.plan_write[tag]})
        out.append("      %s %-20s READS %-18s WRITES %-18s %s"
                   % (tag, prog, r, w, "OK" if r == w else "MISS"))
    a, b = P[sc.c4[0]], P[sc.c4[1]]
    out.append("      C4 %-20s consumer %+d  producer %+d   %s"
               % ("a01 CHORUS", a, b, "OK" if a == b else "MISS %+d" % (a - b)))
    out.append("      P1 %d/%d   P1s(one cell) %s   P2 %s   P3 %d/%d   "
               "N cells %s -> %s"
               % (n1, len(sc.p1), p1s, res["P2"], n3, len(sc.p3), cells,
                  "NON-DEGENERATE" if nd else "*** DEGENERATE ***"))
    return "\n".join(out)


def sect4_detail(sc, survivors, gmap, title, limit=14):
    print()
    print("=" * 78)
    print("4. %s" % title)
    print("=" * 78)
    if not survivors:
        print("\n  NONE.")
        return
    survivors = sorted(survivors, key=lambda r: (-r[0], r[1]))
    seen = set()
    shown = 0
    for sk, gname, sign, mask, free, res, extra in survivors:
        key = (sk, gname, sign, mask)
        if key in seen:
            continue
        seen.add(key)
        shown += 1
        if shown > limit:
            print("\n  ... %d more" % (len(survivors) - limit))
            break
        print("\n  [%d] score %d/7   classes %s (+%d inert classes free)  gate %s  %s"
              % (shown - 1, sk, name_subset(mask), free, gname, sign))
        print("      " + " ".join("%s=%s" % (c, "Y" if res[c] else "n") for c in CRIT))
        print(per_image_arithmetic(sc, mask, gmap[gname], sign == "signed"))


def tier3(sc, gates):
    print()
    print("=" * 78)
    print("3b. TIER 3 -- INDEPENDENT gates for class 2 and class 0xA, others off")
    print("=" * 78)
    G = [("OFF", None)] + list(gates)
    n = len(G)
    colcache = {}
    for cls in (2, 0xA):
        for gi, (gname, gfn) in enumerate(G):
            if gfn is None:
                colcache[(cls, gi)] = [0] * sc.ncol
            else:
                c = sc.columns(gfn, signed=True)
                colcache[(cls, gi)] = c.get(cls, [0] * sc.ncol)
    tally = [0] * 8
    tallyN = [0] * 8
    ndn = 0
    hits = []
    hitsN = []
    for i2 in range(n):
        A = colcache[(2, i2)]
        for iA in range(n):
            Bc = colcache[(0xA, iA)]
            P = [A[i] + Bc[i] for i in range(sc.ncol)]
            res, extra = sc.evaluate(P)
            sk = sum(1 for c in CRIT if res[c])
            tally[sk] += 1
            if extra[3]:
                ndn += 1
                tallyN[sk] += 1
                if sk >= 5:
                    hitsN.append((sk, G[i2][0], G[iA][0], dict(res), extra))
            if sk >= 6:
                hits.append((sk, G[i2][0], G[iA][0], dict(res), extra))
    print()
    print("    score |   count  | fraction |  count & N | fraction & N   (N = %d of %d)"
          % (ndn, n * n))
    for k in range(8):
        print("      %d   | %8d | %7.4f%% | %8d   | %7.4f%%"
              % (k, tally[k], 100.0 * tally[k] / (n * n), tallyN[k],
                 100.0 * tallyN[k] / max(ndn, 1)))
    print("\n  rules scoring >= 6 (ANY):            %d" % len(hits))
    print("  rules scoring >= 5 AND NON-DEGENERATE: %d" % len(hitsN))
    print("\n  -- the >= 6, degeneracy shown --")
    for sk, g2, gA, res, extra in sorted(hits, key=lambda r: -r[0])[:12]:
        print("    score %d/7  cls2 %-13s clsA %-13s %s  cells %s %s"
              % (sk, g2, gA,
                 " ".join("%s=%s" % (c, "Y" if res[c] else "n") for c in CRIT),
                 extra[4], "OK" if extra[3] else "*** DEGENERATE ***"))
    print("\n  -- the NON-DEGENERATE leaders --")
    for sk, g2, gA, res, extra in sorted(hitsN, key=lambda r: -r[0])[:20]:
        print("    score %d/7  cls2 %-13s clsA %-13s %s  cells %s"
              % (sk, g2, gA,
                 " ".join("%s=%s" % (c, "Y" if res[c] else "n") for c in CRIT),
                 extra[4]))
    return tally, hits


def tier4(sc, gates):
    """mode-2 classes {2,A} with a CONJUNCTION of two gates."""
    print()
    print("=" * 78)
    print("3c. TIER 4 -- classes {2,A} with a CONJUNCTION of two gates")
    print("=" * 78)
    n = len(gates)
    tally = [0] * 8
    tallyN = [0] * 8
    ndn = 0
    hits = []
    tot = 0
    for i in range(n):
        gi = gates[i][1]
        for j in range(i, n):
            gj = gates[j][1]
            fn = (lambda a, b: lambda f: a(f) and b(f))(gi, gj)
            cols = sc.columns(fn, signed=True)
            P = combine(cols, [c for c in (2, 0xA) if c in cols]) or [0] * sc.ncol
            res, extra = sc.evaluate(P)
            sk = sum(1 for c in CRIT if res[c])
            tot += 1
            tally[sk] += 1
            if extra[3]:
                ndn += 1
                tallyN[sk] += 1
                if sk >= 5:
                    hits.append((sk, gates[i][0], gates[j][0], dict(res), extra))
    print()
    print("    %d conjunctions;  %d of them non-degenerate" % (tot, ndn))
    print("    score |   count  | fraction |  count & N | fraction & N")
    for k in range(8):
        print("      %d   | %8d | %7.4f%% | %8d   | %7.4f%%"
              % (k, tally[k], 100.0 * tally[k] / max(tot, 1), tallyN[k],
                 100.0 * tallyN[k] / max(ndn, 1)))
    print("\n  non-degenerate rules scoring >= 5 : %d" % len(hits))
    for sk, ga, gb, res, extra in sorted(hits, key=lambda r: -r[0])[:20]:
        print("    score %d/7  %-14s AND %-14s  %s  cells %s"
              % (sk, ga, gb,
                 " ".join("%s=%s" % (c, "Y" if res[c] else "n") for c in CRIT),
                 extra[4]))
    return tally, hits


def sect6_localise(sc):
    """Where each miss is MADE.  This is the part that generalises."""
    print()
    print("=" * 78)
    print("6. LOCALISATION -- which words actually make each miss")
    print("=" * 78)
    for tag, nm in (("C1", "a05 PHASER"), ("C2", "a68 S.DELAY+PHASER"),
                    ("C3", "a03 ENHANCER")):
        ws = sc.progs[nm]
        p = [0] * (len(ws) + 1)
        for i, w in enumerate(ws):
            f = F(w)
            p[i + 1] = p[i] + (s8(f.addr8) if f.class4 in (2, 0xA) else 0)
        rd, wr, secs = reads(ws), writes(ws), ap_sections(ws)
        bad = [i for i in secs if p[i + 3] - p[i] != 0]
        print("\n  %s  %-20s  reads %s  writes %s" %
              (tag, nm, sorted({p[i] for i in rd}), sorted({p[i] for i in wr})))
        print("      P1: %d sections, %d NON-ZERO, at words %s with nets %s"
              % (len(secs), len(bad), bad, [p[i + 3] - p[i] for i in bad]))
        for i in bad:
            for k in range(i, i + 3):
                f = F(ws[k])
                d = s8(f.addr8) if f.class4 in (2, 0xA) else 0
                if d:
                    print("         w%-3d %s  %+4d" % (k, f.txt(), d))
        for j in wr:
            prev = max([i for i in rd if i < j], default=None)
            if prev is None:
                continue
            tot = sum(s8(F(ws[k]).addr8) if F(ws[k]).class4 in (2, 0xA) else 0
                      for k in range(prev, j))
            print("      write w%-3d at %+d ; last preceding read w%-3d at %+d ;"
                  " span %+d" % (j, p[j], prev, p[prev], tot))
            for k in range(prev, j):
                f = F(ws[k])
                d = s8(f.addr8) if f.class4 in (2, 0xA) else 0
                if d:
                    print("         w%-3d %s  %+4d" % (k, f.txt(), d))
    print("""
  ★ THE TWO-LINE IMPOSSIBILITY PROOF FOR C3, which needs no search at all.
    a03's SECOND bank runs from its last chain read (w79) to its modulator
    write (w84) over five words, and only two of them have a non-zero addr8:

        w79  102.2.4D.1CD   +77      x = does this FORM carry a delta?
        w80  212.A.B0.412   -80      y = does this FORM carry a delta?
        w81  104.2.00.000     0
        w82  026.2.00.000     0
        w83  000.A.00.415     0

    C3 requires  77x - 80y = 0  with x, y in {0,1}.  gcd(77,80) = 1, so the
    ONLY solution is x = y = 0 -- the phaser's chain-read form and its
    bank-exit form must BOTH be inert.  a03's FIRST bank gives 67x - 70y = 0,
    same conclusion.  Any rule that decides from the word's fields must treat
    the four occurrences of each form alike, and the difference between the
    banks is carried by the addr8 VALUES (67/70 vs 77/80), which such a rule
    cannot see.  The exhaustive search then confirms that no rule with
    x = y = 0 satisfies C3 either, non-degenerately.""")


def sect5_header(progs, gates_used):
    print()
    print("=" * 78)
    print("5. HEADER VALIDATION")
    print("   (owning note sect. 5: a bit meaning measured 38/38 on the BODIES was")
    print("    false as a bit meaning -- the 83 header/stub words nobody searched")
    print("    carry it 14 times.  Any hi12-conditioned rule must be shown here.)")
    print("=" * 78)
    print()
    for gname, gfn in gates_used:
        row = []
        for reg in ("KERNEL", "EPILOGUE"):
            fl = [F(w) for w in progs[reg]]
            on = sum(1 for f in fl if gfn(f))
            nz = sum(1 for f in fl if gfn(f) and s8(f.addr8))
            row.append("%s %d/%d pass, %d with nonzero addr8" % (reg, on, len(fl), nz))
        print("    gate %-16s  %s   |   %s" % (gname, row[0], row[1]))


def main():
    quick = "--quick" in sys.argv
    progs, meta = PC.load()
    sc = Scorer(progs)
    gates = build_gates(sc.fields)
    gmap = dict(gates)

    if not sect1_control(sc):
        print("\n*** CONTROL FAILED -- the constraints as stated are wrong. STOP. ***")
        return 1
    ng = sect2_space(gates)

    (tally, tallyN, ndtot, percrit, percritN,
     survivors, best_nd, combos, ppp) = enumerate_tiers(sc, gates, quick=quick)
    sect3_report(tally, tallyN, ndtot, percrit, percritN, 1 if quick else ng)
    print()
    print("  ★ THE NULL THAT MATTERS FOR THE WINNER.  The control already has")
    print("    P1 & P2 & P3; the only thing a candidate adds is C4.  So the right")
    print("    null is: among NON-DEGENERATE rules that keep P1 & P2 & P3, how many")
    print("    also satisfy C4?")
    for t in (1, 2):
        a, b = ppp[t][0], ppp[t][1]
        print("      tier %d:  %d keep P1&P2&P3 & N;  %d of them also satisfy C4  = %.4f%%"
              % (t, a, b, 100.0 * b / max(a, 1)))
    sect3c_combos(combos)
    sect4_detail(sc, survivors, gmap,
                 "THE SURVIVORS (score >= 6, degeneracy shown)")
    sect4_detail(sc, best_nd, gmap,
                 "THE NON-DEGENERATE LEADERS (score >= 4 AND N)", limit=40)

    t3tally, t3hits = tier3(sc, gates)
    tier4(sc, gates)

    used = [("ALL", gmap["ALL"])]
    for rec in survivors[:10]:
        used.append((rec[1], gmap[rec[1]]))
    for rec in t3hits[:10]:
        for gn in (rec[1], rec[2]):
            if gn in gmap:
                used.append((gn, gmap[gn]))
    seen, uniq = set(), []
    for gn, gf in used:
        if gn not in seen:
            seen.add(gn)
            uniq.append((gn, gf))
    sect6_localise(sc)
    sect5_header(progs, uniq[:14])
    return 0


if __name__ == "__main__":
    sys.exit(main())
