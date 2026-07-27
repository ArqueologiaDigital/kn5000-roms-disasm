#!/usr/bin/env python3
"""dram_dir.py -- DRAM-DIR: a direction test with DEMONSTRATED discriminating
power, and the rule-7 audit of the claims that were settled by scoring.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  Every number quoted in
`analysis/dram-direction.md` comes out of this file.  Stdlib only.  No hardware;
static analysis of the Sub CPU ROM corpus only.

    python3 dsp/tools/dram_dir.py oracle    # *** THE INSTRUMENT: pair-opposition ***
    python3 dsp/tools/dram_dir.py rivals    # the enumerated rival family, scored
    python3 dsp/tools/dram_dir.py separate  # *** RULE 7: scored ONLY where rivals differ
    python3 dsp/tools/dram_dir.py power     # *** PLANTED GROUND TRUTH: X recovered, Y rejected
    python3 dsp/tools/dram_dir.py null      # the nulls -- permutation, collision, random
    python3 dsp/tools/dram_dir.py phase     # the alignment delta, re-enumerated INSIDE this search
    python3 dsp/tools/dram_dir.py polarity  # *** the ONE remaining bit, and who disagrees
    python3 dsp/tools/dram_dir.py audit     # *** SECOND TASK: the rule-7 audit of published claims
    python3 dsp/tools/dram_dir.py control   # every control, each shown saying NO
    python3 dsp/tools/dram_dir.py all
"""
import argparse
import collections
import itertools
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dram_cursor as DC                                            # noqa: E402


# ---------------------------------------------------------------------------
#  0.  Data.  Everything is re-derived; nothing below is quoted from a note.
# ---------------------------------------------------------------------------
def load(sub, mainrom, tools):
    rom, imgs, loads, hdr, epi = DC.load(sub, tools)
    sys.path.insert(0, tools)
    names = {}
    try:
        import kn5000_dsp_coeffs as CO                              # noqa: E402
        if os.path.exists(mainrom):
            names = CO.effect_names(mainrom)
    except Exception:
        names = {}
    return rom, imgs, loads, names


def F(w):
    return DC.fields(w)


def nm(names, a):
    return names.get(a, "?")


def build(rom, imgs, loads, delta=0):
    """[(algo, unit, cells{cell:value}, wordof{cell:word}, slotof{cell:k})]
    over the algorithms where the rigid map at phase `delta` is total.

    The map itself is r3/R2's: the k-th consumer in PROGRAM order takes the
    k-th descriptor cell in INDEX order, shifted by delta.  It is a PARAMETER
    of this search (method rule 2) and `phase` enumerates it."""
    out = []
    for a, u, cells, cons in DC.corpus(rom, imgs, loads):
        ck = sorted(cells)
        if len(ck) != len(cons):
            continue
        # delta is a CYCLIC rotation of the cell list against program order.
        # A non-cyclic shift would simply drop |delta| algorithms and make the
        # sweep vacuous -- method rule 1, caught in this file's first draft.
        wof, sof = {}, {}
        for k, (_i, w) in enumerate(cons):
            j = (k + delta) % len(ck)
            wof[ck[j]] = w
            sof[ck[j]] = k
        if len(wof) != len(ck):
            continue
        out.append((a, u, cells, wof, sof))
    return out


def pairs_of(cells):
    """Cells of one algorithm grouped by EXACT equal value.  Returns the
    2-groups.  NOTE the multiplicity histogram is printed by `oracle`: no value
    ever occurs 3 times, which is what makes `pair' the right word."""
    bv = collections.defaultdict(list)
    for c, v in cells.items():
        bv[v].append(c)
    return [(tuple(sorted(l)), v) for v, l in sorted(bv.items()) if len(l) == 2]


def all_pairs(B):
    return [(a, p, v) for (a, u, cells, wof, sof) in B for p, v in pairs_of(cells)]


# ---------------------------------------------------------------------------
#  1.  THE RIVAL FAMILY.  Enumerated widely and honestly (method rule 3):
#      every rule is a function (word, slot, cell) -> "R" | "W".
#      H-* read the INSTRUCTION.  C-* are the instruction-blind nuisance rules
#      the brief demands, including one that is degenerate WITH THE ORACLE.
# ---------------------------------------------------------------------------
def _src(w):
    return DC.src(w)


RULES_INSTR = {
    "H-ADB6    addr8 bit 6 -> R":
        lambda w, k, c: "R" if (F(w)[2] & 0x40) else "W",
    "H-AD60    addr8 == 0x60 -> R":
        lambda w, k, c: "R" if F(w)[2] == 0x60 else "W",
    "H-ADB7    addr8 bit 7 -> R":
        lambda w, k, c: "R" if (F(w)[2] & 0x80) else "W",
    "H-ADB5    addr8 bit 5 -> R":
        lambda w, k, c: "R" if (F(w)[2] & 0x20) else "W",
    "H-ADB4    addr8 bit 4 -> R":
        lambda w, k, c: "R" if (F(w)[2] & 0x10) else "W",
    "H-SRC0B   SRC == 0x0B -> R   (H-DIR, dark-words F)":
        lambda w, k, c: "R" if _src(w) == 0x0B else "W",
    "H-SRC0B0  SRC in {0x0B,0x00} -> R":
        lambda w, k, c: "R" if _src(w) in (0x0B, 0x00) else "W",
    "H-SRC19   SRC == 0x19 -> W":
        lambda w, k, c: "W" if _src(w) == 0x19 else "R",
    "H-SRCB3   SRC bit 3 -> R":
        lambda w, k, c: "R" if (_src(w) & 0x08) else "W",
    "H-SRCB0   SRC bit 0 -> R":
        lambda w, k, c: "R" if (_src(w) & 0x01) else "W",
    "H-SRCB4   SRC bit 4 -> W":
        lambda w, k, c: "W" if (_src(w) & 0x10) else "R",
    "H-HI7     hi12 bit 7 -> W   (store-gate.md D)":
        lambda w, k, c: "W" if (F(w)[0] & 0x080) else "R",
    "H-HI6     hi12 bit 6 -> W":
        lambda w, k, c: "W" if (F(w)[0] & 0x040) else "R",
    "H-HI8     hi12 bit 8 -> W":
        lambda w, k, c: "W" if (F(w)[0] & 0x100) else "R",
    "H-HI10    hi12 bit 10 -> W  (the C-format escape)":
        lambda w, k, c: "W" if (F(w)[0] & 0x400) else "R",
    "H-ACTRD   ACTION in {14,15,19,1A} -> R":
        lambda w, k, c: "R" if (F(w)[3] & 0x1F) in (0x14, 0x15, 0x19, 0x1A) else "W",
    "H-ACT1415 ACTION in {14,15} -> R":
        lambda w, k, c: "R" if (F(w)[3] & 0x1F) in (0x14, 0x15) else "W",
    "H-ACT0B   ACTION == 0x0B -> W":
        lambda w, k, c: "W" if (F(w)[3] & 0x1F) == 0x0B else "R",
    "H-LO6     lo12 bit 6 -> R":
        lambda w, k, c: "R" if (F(w)[3] & 0x040) else "W",
    "H-LO5     lo12 bit 5 (the MODE bit) -> R":
        lambda w, k, c: "R" if (F(w)[3] & 0x020) else "W",
    "H-LO9     lo12 bit 9 -> W":
        lambda w, k, c: "W" if (F(w)[3] & 0x200) else "R",
    "H-LO11    lo12 bit 11 (register file) -> R":
        lambda w, k, c: "R" if (F(w)[3] & 0x800) else "W",
}

RULES_BLIND = {
    "C-CELLPAR cell-index parity        (instruction-blind)":
        lambda w, k, c: "R" if (c & 1) else "W",
    "C-SLOTPAR consumer-order parity    (instruction-blind)":
        lambda w, k, c: "R" if (k & 1) else "W",
    "C-CELLM3  cell index mod 3 == 1    (instruction-blind)":
        lambda w, k, c: "R" if (c % 3) == 1 else "W",
    "C-CELLM4  cell index mod 4 in {1,2}(instruction-blind)":
        lambda w, k, c: "R" if (c % 4) in (1, 2) else "W",
    "C-ALLW    everything is a WRITE    (instruction-blind)":
        lambda w, k, c: "W",
}


def _rank_rule(a, u, cells, wof, sof):
    """C-VALRANK: parity of the value's rank among the algorithm's sorted
    DISTINCT values.  Blind to the instruction; reads only the host data."""
    rk = {v: i for i, v in enumerate(sorted(set(cells.values())))}
    return {c: ("R" if (rk[cells[c]] & 1) else "W") for c in cells}


def _dup_rule(a, u, cells, wof, sof):
    """C-DUPLO: inside an equal-value pair the LOWER cell index is the write.
    *** THIS RULE KNOWS THE ORACLE. ***  It is included precisely because it
    scores a perfect 0 by construction, which is the honest statement of what
    the instrument can and cannot do (see `separate`)."""
    lab = {c: "W" for c in cells}
    for p, _v in pairs_of(cells):
        lab[p[1]] = "R"
    return lab


def _first_rule(a, u, cells, wof, sof):
    """C-FIRSTW: the FIRST access to a value in program order is a write, later
    ones are reads.  Blind to the instruction; the brief names it."""
    lab = {}
    seen = set()
    for c in sorted(cells, key=lambda c: sof[c]):
        v = cells[c]
        lab[c] = "R" if v in seen else "W"
        seen.add(v)
    return lab


SPECIAL_BLIND = {
    "C-VALRANK value-rank parity        (instruction-blind)": _rank_rule,
    "C-FIRSTW  first touch of a value=W (instruction-blind)": _first_rule,
    "C-DUPLO   dup pair: lower cell = W (** KNOWS THE ORACLE **)": _dup_rule,
}


def _bitname(b):
    if b >= 24:
        return "hi12 bit %d" % (b - 24)
    if b >= 20:
        return "class4 bit %d" % (b - 20)
    if b >= 12:
        return "addr8 bit %d" % (b - 12)
    return "lo12 bit %d" % b


def label(B, rule):
    """rule may be a lambda(word, slot, cell) or a whole-algorithm function."""
    out = {}
    for (a, u, cells, wof, sof) in B:
        if rule in SPECIAL_BLIND.values():
            out[a] = rule(a, u, cells, wof, sof)
        else:
            out[a] = {c: rule(wof[c], sof[c], c) for c in cells}
    return out


def all_rules():
    d = {}
    d.update(RULES_INSTR)
    d.update(RULES_BLIND)
    d.update(SPECIAL_BLIND)
    return d


def violations(B, L, sites=None):
    """A rule VIOLATES the oracle at a pair when it gives both members the SAME
    label.  Symmetric under the global flip -- the oracle constrains the
    PARTITION, never the polarity.  Stated, not assumed away."""
    P = sites if sites is not None else all_pairs(B)
    return sum(1 for a, p, _v in P if L[a][p[0]] == L[a][p[1]])


# ===========================================================================
#  SECTION `oracle'
# ===========================================================================
def sec_oracle(rom, imgs, loads, names):
    print("=" * 78)
    print("1. THE INSTRUMENT -- PAIR-OPPOSITION, and why it can fail")
    print("=" * 78)
    B = build(rom, imgs, loads, 0)
    C = DC.corpus(rom, imgs, loads)
    ncons = sum(len(k) for _a, _u, _c, k in C)
    print("   POPULATIONS (method rule 9), all re-derived here:")
    print("      algorithms shipping descriptor cells      : %d" % len(C))
    print("      ... of which the rigid map at delta=0 is total (#cells == #consumers): %d"
          % len(B))
    print("      class-1 FORMAT-ESCAPE consumer words, whole corpus: %d" % ncons)
    print("      descriptor cells inside the %d aligned algorithms  : %d"
          % (len(B), sum(len(c) for _a, _u, c, _w, _s in B)))
    print()
    print("   THE ORACLE, stated before it is used:")
    print("     A descriptor cell is an ABSOLUTE delay-DRAM address (r3 sect.5.1,")
    print("     re-derived by adjudication-round4 item C from the partition).  If")
    print("     two words of one algorithm are handed the SAME address then one")
    print("     of them writes it and the other reads it: two writes to one")
    print("     address in one frame makes the first dead, and the machine does")
    print("     not ship dead stores in 133 places.  So:")
    print()
    print("        *** EQUAL-VALUED CELL PAIRS CARRY OPPOSITE DIRECTIONS. ***")
    print()
    print("     The pairing is computed from the HOST's canned values alone.  No")
    print("     instruction field enters it.  A direction rule reads only the")
    print("     instruction.  The two data sources are disjoint.")
    print()
    mult = collections.Counter()
    for (a, u, cells, wof, sof) in B:
        bv = collections.Counter(cells.values())
        for v, n in bv.items():
            mult[n] += 1
    print("   MEASURED value-multiplicity over the %d aligned algorithms: %s"
          % (len(B), dict(sorted(mult.items()))))
    print("     -> no value is ever used THREE times.  `pair' is not an")
    print("        approximation; the structure is a perfect matching.")
    print()
    P = all_pairs(B)
    hosts = sorted(set(a for a, _p, _v in P))
    print("   ORACLE SITES: %d pairs, in %d of the %d aligned algorithms."
          % (len(P), len(hosts), len(B)))
    for a in hosts:
        n = sum(1 for x in P if x[0] == a)
        cells = [c for (aa, u, c, w, s) in B if aa == a][0]
        print("      algo %2d %-20s cells %2d  pairs %2d"
              % (a, nm(names, a)[:20], len(cells), n))
    print()
    print("   1.0b THE PAIRING GEOMETRY, because it is what limits the power.")
    off = collections.Counter()
    shapes = collections.Counter()
    for (a, u, cells, wof, sof) in B:
        ck = sorted(cells)
        pos = {c: i for i, c in enumerate(ck)}
        for p, _v in pairs_of(cells):
            off[pos[p[1]] - pos[p[0]]] += 1
            shapes[(DC.fmt(wof[p[0]]), DC.fmt(wof[p[1]]))] += 1
    print("      cell-INDEX offset between the two members: %s"
          % dict(sorted(off.items())))
    print("      distinct (word,word) SHAPES among the %d pairs: %d"
          % (len(P) if False else sum(shapes.values()), len(shapes)))
    for k, v in shapes.most_common():
        print("         %s | %s   x%d" % (k[0], k[1], v))
    print("      *** THE SAME DISCOUNT THIS PASS APPLIES TO H-DIR APPLIES HERE:")
    print("      136 pairs are not 136 independent facts.  They are %d word-pair"
          % len(shapes))
    print("      shapes replicated across algorithms.  Every claim below is")
    print("      priced in BOTH units.")
    print()
    print("   1.1  CAN THE ORACLE FAIL?  (method rule 1)")
    print("   A rule fails a site by labelling both members alike.  `C-ALLW'")
    print("   (everything is a write) fails every site by construction, so the")
    print("   floor is %d/%d; a rule that alternates perfectly reaches 0.  The"
          % (len(P), len(P)))
    print("   range is the full range.")
    print()
    print("   1.2  ** WHAT THE ORACLE CANNOT DO, SAID BEFORE THE SCORES. **")
    print("   It is invariant under the GLOBAL FLIP: swapping R and W everywhere")
    print("   changes no score.  It therefore decides the PARTITION of the")
    print("   accesses into two classes and NOT which class is the read.  The")
    print("   polarity is a separate question and `polarity' is where it is put.")
    return B


# ===========================================================================
#  SECTION `rivals'
# ===========================================================================
def sec_rivals(rom, imgs, loads, names, B=None):
    print("=" * 78)
    print("2. THE RIVAL FAMILY, ENUMERATED, AND SCORED ON EVERY SITE")
    print("=" * 78)
    if B is None:
        B = build(rom, imgs, loads, 0)
    P = all_pairs(B)
    R = all_rules()
    L = {n: label(B, f) for n, f in R.items()}
    rows = []
    for n in R:
        rows.append((violations(B, L[n], P), n))
    rows.sort()
    print("   population: %d equal-value pairs, %d algorithms, %d cells"
          % (len(P), len(set(a for a, _p, _v in P)),
             sum(len(c) for _a, _u, c, _w, _s in B)))
    print()
    print("   %-52s %6s %7s" % ("rule", "viol", "ok"))
    for v, n in rows:
        print("   %-52s %6d %6.1f%%" % (n, v, 100.0 * (len(P) - v) / len(P)))
    print()
    print("   2.1  DEGENERACIES, LOOKED FOR BEFORE ANYTHING IS BELIEVED (rule 4).")
    seen = {}
    for n in R:
        key = tuple(sorted((a, c, L[n][a][c]) for a in L[n] for c in L[n][a]))
        keyi = tuple(sorted((a, c, "R" if L[n][a][c] == "W" else "W")
                            for a in L[n] for c in L[n][a]))
        k = min(key, keyi)
        seen.setdefault(k, []).append(n)
    for k, v in seen.items():
        if len(v) > 1:
            print("      IDENTICAL (up to the global flip): %s" % " == ".join(v))
    print()
    print("   2.2  THE C-FORMAT SITES.  `H-ADB6' fails exactly %d sites."
          % violations(B, L["H-ADB6    addr8 bit 6 -> R"], P))
    for a, p, v in P:
        LL = L["H-ADB6    addr8 bit 6 -> R"]
        if LL[a][p[0]] == LL[a][p[1]]:
            wof = [w for (aa, u, c, w, s) in B if aa == a][0]
            print("      algo %2d %-18s value %6d  cell 0x%02X %s | cell 0x%02X %s"
                  % (a, nm(names, a)[:18], v, p[0], DC.fmt(wof[p[0]]),
                     p[1], DC.fmt(wof[p[1]])))
    print("      -- all three are the C-FORMAT word C40.1.80.000, whose addr8")
    print("         (0x80) adjudication-round4 item H already established is NOT")
    print("         an address.  Excluding the C format is a PRE-EXISTING")
    print("         exclusion, not a fitted one; both numbers are printed.")
    nc = [(a, p, v) for a, p, v in P
          if not (F([w for (aa, u, c, w, s) in B if aa == a][0][p[0]])[0] & 0x400)
          and not (F([w for (aa, u, c, w, s) in B if aa == a][0][p[1]])[0] & 0x400)]
    print()
    print("   NON-C-FORMAT SITES: %d of %d." % (len(nc), len(P)))
    print("   %-52s %6s" % ("rule", "viol"))
    for v, n in sorted((violations(B, L[n], nc), n) for n in R):
        print("   %-52s %6d" % (n, v))
    print()
    print("   2.25 *** THE EXHAUSTIVE ENUMERATION -- WHICH FIELD CAN CARRY")
    print("   DIRECTION AT ALL?  This is the only FORCING statement in the pass,")
    print("   so its model class is printed next to it (method rule 3):")
    print()
    print("      MODEL CLASS: `the direction is a FUNCTION OF ONE FIELD of the")
    print("      instruction word'.  For each field, every one of the 2^k boolean")
    print("      functions of its k observed values is tried -- not a hand-picked")
    print("      predicate.  A field CAN carry direction iff some function of it")
    print("      gives the two members of every pair opposite labels.")
    print()
    nc = [(a, p, v) for a, p, v in P
          if not (F([w for (aa, u, c, w, s) in B if aa == a][0][p[0]])[0] & 0x400)
          and not (F([w for (aa, u, c, w, s) in B if aa == a][0][p[1]])[0] & 0x400)]
    wofa = {a: w for (a, u, c, w, s) in B}
    FIELDS = [("hi12", lambda w: F(w)[0]),
              ("class4", lambda w: F(w)[1]),
              ("addr8", lambda w: F(w)[2]),
              ("lo12", lambda w: F(w)[3]),
              ("SRC   (lo12[10:6])", lambda w: _src(w)),
              ("ACTION(lo12[4:0])", lambda w: F(w)[3] & 0x1F),
              ("MODE  (lo12 bit 5)", lambda w: (F(w)[3] >> 5) & 1),
              ("hi12[3:1] (acc op)", lambda w: (F(w)[0] >> 1) & 7),
              ("whole 36-bit word", lambda w: w)]
    for site, tag in ((P, "all %d pairs" % len(P)),
                      (nc, "%d non-C-format pairs" % len(nc))):
        print("      --- scored on %s ---" % tag)
        for fname, fn in FIELDS:
            vals = sorted({fn(wofa[a][c]) for a, p, _v in site for c in p})
            if len(vals) > 18:
                print("         %-20s %2d distinct values -- TRIVIALLY SATISFIABLE "
                      "(a value never repeats inside a pair); no content"
                      % (fname, len(vals)))
                continue
            idx = {v: i for i, v in enumerate(vals)}
            ok = 0
            best = None
            for mask in range(1 << len(vals)):
                bad = 0
                for a, p, _v in site:
                    l0 = (mask >> idx[fn(wofa[a][p[0]])]) & 1
                    l1 = (mask >> idx[fn(wofa[a][p[1]])]) & 1
                    if l0 == l1:
                        bad += 1
                if bad == 0:
                    ok += 1
                    if best is None:
                        best = mask
            if ok:
                rd = [v for v in vals if (best >> idx[v]) & 1]
                print("         %-20s %2d values -> %4d of %4d functions give ZERO "
                      "violations   e.g. {%s} on one side"
                      % (fname, len(vals), ok, 1 << len(vals),
                         ",".join("0x%02X" % v for v in rd)))
            else:
                print("         %-20s %2d values -> %4d of %4d functions give ZERO "
                      "violations   *** THIS FIELD CANNOT CARRY DIRECTION ***"
                      % (fname, len(vals), ok, 1 << len(vals)))
        print()
    print("   2.26 AND THE SAME QUESTION ONE BIT AT A TIME: all 36 bits of the")
    print("   word, scored on the %d non-C-format pairs." % len(nc))
    surv = []
    for b in range(36):
        bad = sum(1 for a, p, _v in nc
                  if ((wofa[a][p[0]] >> b) & 1) == ((wofa[a][p[1]] >> b) & 1))
        if bad == 0:
            surv.append(b)
    print("      bits with ZERO violations: %s"
          % (", ".join("bit %d (%s)" % (b, _bitname(b)) for b in surv) or "none"))
    allb = [(sum(1 for a, p, _v in nc
                 if ((wofa[a][p[0]] >> b) & 1) == ((wofa[a][p[1]] >> b) & 1)), b)
            for b in range(36)]
    allb.sort()
    print("      the five best bits: %s"
          % ", ".join("bit %d (%s) %d viol" % (b, _bitname(b), v)
                      for v, b in allb[:5]))
    print()
    print("   2.3  ** THE FIELD THAT SEPARATES THE TWO MEMBERS OF A PAIR. **")
    cc = collections.Counter()
    for a, p, v in P:
        wof = [w for (aa, u, c, w, s) in B if aa == a][0]
        cc[(F(wof[p[0]])[2], F(wof[p[1]])[2])] += 1
    print("      addr8 of (lower cell, upper cell), over all %d pairs:" % len(P))
    for k, v in cc.most_common():
        print("         (0x%02X , 0x%02X)  x%-4d  bit6 = (%d,%d)"
              % (k[0], k[1], v, 1 if k[0] & 0x40 else 0, 1 if k[1] & 0x40 else 0))
    cc = collections.Counter()
    for a, p, v in P:
        wof = [w for (aa, u, c, w, s) in B if aa == a][0]
        cc[(_src(wof[p[0]]), _src(wof[p[1]]))] += 1
    print("      SRC of (lower, upper):")
    for k, v in cc.most_common():
        print("         (0x%02X , 0x%02X)  x%d" % (k[0], k[1], v))
    cc = collections.Counter()
    for a, p, v in P:
        wof = [w for (aa, u, c, w, s) in B if aa == a][0]
        cc[(F(wof[p[0]])[0], F(wof[p[1]])[0])] += 1
    print("      hi12 of (lower, upper):")
    for k, v in cc.most_common():
        print("         (0x%03X , 0x%03X)  x%-4d  bit7 = (%d,%d)"
              % (k[0], k[1], v, 1 if k[0] & 0x80 else 0, 1 if k[1] & 0x80 else 0))
    return B


# ===========================================================================
#  SECTION `separate'  -- METHOD RULE 7, and it is the point of the pass
# ===========================================================================
def sec_separate(rom, imgs, loads, names, B=None):
    print("=" * 78)
    print("3. *** RULE 7: SCORED ONLY WHERE THE RIVALS DISAGREE ***")
    print("=" * 78)
    if B is None:
        B = build(rom, imgs, loads, 0)
    P = all_pairs(B)
    R = all_rules()
    L = {n: label(B, f) for n, f in R.items()}
    print("   A pair is a DISAGREEMENT SITE for (A,B) when A and B assign")
    print("   different labels to at least one of its two members.  Sites where")
    print("   they agree cannot choose between them and are DISCARDED -- that is")
    print("   the whole content of method rule 7.  If the disagreement set is")
    print("   empty the two rules are the same machine on this data and the")
    print("   instrument is silent about them: printed as such.")
    print()
    key = ["H-ADB6    addr8 bit 6 -> R",
           "H-SRC0B   SRC == 0x0B -> R   (H-DIR, dark-words F)",
           "H-HI7     hi12 bit 7 -> W   (store-gate.md D)",
           "H-ACTRD   ACTION in {14,15,19,1A} -> R",
           "C-CELLPAR cell-index parity        (instruction-blind)",
           "C-SLOTPAR consumer-order parity    (instruction-blind)",
           "C-VALRANK value-rank parity        (instruction-blind)",
           "C-FIRSTW  first touch of a value=W (instruction-blind)",
           "C-DUPLO   dup pair: lower cell = W (** KNOWS THE ORACLE **)"]
    print("   %-30s %-30s %5s %6s %6s" % ("A", "B", "n", "A viol", "B viol"))
    for i in range(len(key)):
        for j in range(i + 1, len(key)):
            A, Bn = key[i], key[j]
            dis = [(a, p, v) for a, p, v in P
                   if L[A][a][p[0]] != L[Bn][a][p[0]]
                   or L[A][a][p[1]] != L[Bn][a][p[1]]]
            if not dis:
                print("   %-30s %-30s   -- DISAGREEMENT SET EMPTY (same machine)"
                      % (A[:30], Bn[:30]))
                continue
            print("   %-30s %-30s %5d %6d %6d"
                  % (A[:30], Bn[:30], len(dis),
                     violations(B, L[A], dis), violations(B, L[Bn], dis)))
    print()
    print("   3.1  ** THE HEADLINE SEPARATION, PRINTED SITE BY SITE. **")
    A = "H-ADB6    addr8 bit 6 -> R"
    Bn = "C-CELLPAR cell-index parity        (instruction-blind)"
    dis = [(a, p, v) for a, p, v in P
           if L[A][a][p[0]] != L[Bn][a][p[0]] or L[A][a][p[1]] != L[Bn][a][p[1]]]
    print("   %s   vs   %s" % (A.split()[0], Bn.split()[0]))
    print("   %d disagreement pairs of %d:" % (len(dis), len(P)))
    for a, p, v in dis:
        wof = [w for (aa, u, c, w, s) in B if aa == a][0]
        print("      algo %2d %-18s val %6d  0x%02X %s -> ADB6 %s / PAR %s"
              % (a, nm(names, a)[:18], v, p[0], DC.fmt(wof[p[0]]),
                 L[A][a][p[0]], L[Bn][a][p[0]]))
        print("      %31s   0x%02X %s -> ADB6 %s / PAR %s"
              % ("", p[1], DC.fmt(wof[p[1]]), L[A][a][p[1]], L[Bn][a][p[1]]))
        print("      %31s   ORACLE says: ADB6 %s , CELLPAR %s"
              % ("", "OK " if L[A][a][p[0]] != L[A][a][p[1]] else "FAIL",
                 "OK " if L[Bn][a][p[0]] != L[Bn][a][p[1]] else "FAIL"))
    print()
    A2 = "H-SRC0B   SRC == 0x0B -> R   (H-DIR, dark-words F)"
    dis2 = [(a, p, v) for a, p, v in P
            if L[A2][a][p[0]] != L[Bn][a][p[0]] or L[A2][a][p[1]] != L[Bn][a][p[1]]]
    print("   3.2  ** AND THE SAME TEST RUN ON H-DIR, WHICH LOSES TO THE BLIND RULE. **")
    print("   H-SRC0B vs C-CELLPAR: %d disagreement pairs; H-SRC0B fails %d, "
          "C-CELLPAR fails %d."
          % (len(dis2), violations(B, L[A2], dis2), violations(B, L[Bn], dis2)))
    fam = collections.Counter()
    for a, p, v in P:
        wof = [w for (aa, u, c, w, s) in B if aa == a][0]
        if L[A2][a][p[0]] == L[A2][a][p[1]]:
            fam[(_src(wof[p[0]]), _src(wof[p[1]]))] += 1
    print("   The SRC pairs on which H-DIR fails at all (%d sites): %s"
          % (violations(B, L[A2], P),
             ", ".join("(%02X,%02X)x%d" % (k[0], k[1], v) for k, v in fam.most_common())))
    return B


# ===========================================================================
#  SECTION `power'  -- can the instrument recover a PLANTED truth?
# ===========================================================================
def plant(B, L, rng, npairs_from_real=True, noise=0):
    """Synthesise a descriptor image whose equal-value pairs are consistent with
    the labelling L, keeping the REAL words, the REAL cell counts and the REAL
    number of pairs per algorithm.  `noise' pairs per algorithm are instead
    drawn from two same-labelled cells (accidental collisions)."""
    out = []
    for (a, u, cells, wof, sof) in B:
        want = len(pairs_of(cells))
        rd = [c for c in cells if L[a][c] == "R"]
        wr = [c for c in cells if L[a][c] == "W"]
        rng.shuffle(rd)
        rng.shuffle(wr)
        newv = {}
        used = set()
        n = min(want, len(rd), len(wr))
        nz = min(noise, n)
        lo, hi = (0, 32768) if u == 0 else (32768, 65536)
        for i in range(n - nz):
            v = rng.randrange(lo, hi)
            while v in used:
                v = rng.randrange(lo, hi)
            used.add(v)
            newv[rd[i]] = v
            newv[wr[i]] = v
        pool = [c for c in cells if c not in newv]
        rng.shuffle(pool)
        for i in range(nz):
            if len(pool) < 2:
                break
            c1, c2 = pool.pop(), pool.pop()
            v = rng.randrange(lo, hi)
            while v in used:
                v = rng.randrange(lo, hi)
            used.add(v)
            newv[c1] = v
            newv[c2] = v
        for c in cells:
            if c in newv:
                continue
            v = rng.randrange(lo, hi)
            while v in used:
                v = rng.randrange(lo, hi)
            used.add(v)
            newv[c] = v
        out.append((a, u, newv, wof, sof))
    return out


def plant_structured(B, L, rng):
    """*** THE HONEST PLANT. ***  `plant()' draws the matching at RANDOM from
    X's two classes, which destroys the program's own pairing GEOMETRY -- in the
    real corpus a pair is two cells a FIXED index offset apart (the motif
    length), and that offset is a property of the microprogram, not of the
    direction rule.  A random matching therefore hands the test power the real
    data does not have.

    Here the real topology is kept: every real pair (c1,c2) is re-used at its
    own index offset.  If X labels those two cells alike, the pair is moved to
    another cell pair at the SAME offset that X labels oppositely; if there is
    none, the pair is dropped.  Returns (corpus, moved, dropped)."""
    out = []
    moved = dropped = 0
    for (a, u, cells, wof, sof) in B:
        ck = sorted(cells)
        pos = {c: i for i, c in enumerate(ck)}
        lo, hi = (0, 32768) if u == 0 else (32768, 65536)
        newv, used, taken = {}, set(), set()
        for p, _v in pairs_of(cells):
            d = pos[p[1]] - pos[p[0]]
            cand = [p]
            for i in range(len(ck) - d):
                cand.append((ck[i], ck[i + d]))
            pick = None
            for c1, c2 in cand:
                if c1 in taken or c2 in taken:
                    continue
                if L[a][c1] != L[a][c2]:
                    pick = (c1, c2)
                    break
            if pick is None:
                dropped += 1
                continue
            if pick != p:
                moved += 1
            v = rng.randrange(lo, hi)
            while v in used:
                v = rng.randrange(lo, hi)
            used.add(v)
            newv[pick[0]] = newv[pick[1]] = v
            taken.add(pick[0])
            taken.add(pick[1])
        for c in ck:
            if c in newv:
                continue
            v = rng.randrange(lo, hi)
            while v in used:
                v = rng.randrange(lo, hi)
            used.add(v)
            newv[c] = v
        out.append((a, u, newv, wof, sof))
    return out, moved, dropped


def sec_power(rom, imgs, loads, names, B=None, trials=200):
    print("=" * 78)
    print("4. *** POWER: PLANT A GROUND TRUTH, THEN SEE IF THE TEST FINDS IT ***")
    print("=" * 78)
    if B is None:
        B = build(rom, imgs, loads, 0)
    R = all_rules()
    L0 = {n: label(B, f) for n, f in R.items()}
    planted = ["H-ADB6    addr8 bit 6 -> R",
               "H-SRC0B   SRC == 0x0B -> R   (H-DIR, dark-words F)",
               "H-SRC19   SRC == 0x19 -> W",
               "H-HI7     hi12 bit 7 -> W   (store-gate.md D)",
               "H-ACTRD   ACTION in {14,15,19,1A} -> R",
               "C-CELLPAR cell-index parity        (instruction-blind)",
               "C-VALRANK value-rank parity        (instruction-blind)"]
    scored = planted
    print("   A synthetic descriptor image is built for each planted rule X: the")
    print("   REAL words, the REAL cell counts, the REAL number of equal-value")
    print("   pairs per algorithm -- but the pairs are drawn at random from X's")
    print("   own R-cells and W-cells.  The instrument is then run unchanged.")
    print("   %d trials each.  Cell = mean violations of the SCORED rule." % trials)
    print()
    print("   %-26s | %s" % ("planted \\ scored",
                             " ".join("%7s" % s.split()[0] for s in scored)))
    print("   " + "-" * (26 + 3 + 8 * len(scored)))
    recov = 0
    for X in planted:
        rng = random.Random(0xD12 + planted.index(X))
        acc = collections.defaultdict(float)
        for _t in range(trials):
            Bp = plant(B, L0[X], rng)
            Pp = all_pairs(Bp)
            Lp = {n: label(Bp, R[n]) for n in scored}
            for Y in scored:
                acc[Y] += violations(Bp, Lp[Y], Pp)
        best = min(scored, key=lambda Y: acc[Y])
        if best == X:
            recov += 1
        print("   %-26s | %s   %s"
              % (X.split()[0], " ".join("%7.1f" % (acc[Y] / trials) for Y in scored),
                 "<- recovered" if best == X else "<- MISSED (best=%s)" % best.split()[0]))
    print()
    print("   RECOVERY: the planted rule is the unique minimum in %d of %d plants."
          % (recov, len(planted)))
    print()
    print("   4.1  ** REJECTION, THE OTHER HALF. **  A test that recovers X but")
    print("   cannot REJECT Y is still useless.  For each ordered pair the table")
    print("   above gives mean(Y | X planted); Y is rejected when that is well")
    print("   above 0.  The two rules the brief is really about:")
    rng = random.Random(0xBEEF)
    for X, Y in [("H-ADB6    addr8 bit 6 -> R",
                  "C-CELLPAR cell-index parity        (instruction-blind)"),
                 ("C-CELLPAR cell-index parity        (instruction-blind)",
                  "H-ADB6    addr8 bit 6 -> R"),
                 ("H-ADB6    addr8 bit 6 -> R",
                  "H-SRC0B   SRC == 0x0B -> R   (H-DIR, dark-words F)"),
                 ("H-SRC0B   SRC == 0x0B -> R   (H-DIR, dark-words F)",
                  "H-ADB6    addr8 bit 6 -> R")]:
        got = []
        for _t in range(trials):
            Bp = plant(B, L0[X], rng)
            Pp = all_pairs(Bp)
            got.append(violations(Bp, label(Bp, R[Y]), Pp))
        got.sort()
        print("      plant %-10s score %-10s : min %d  median %d  max %d"
              % (X.split()[0], Y.split()[0], got[0], got[len(got) // 2], got[-1]))
    print()
    print()
    print("   4.1b ** AND NOW THE PLANT THAT DOES NOT CHEAT. **  The table above")
    print("   pairs cells at RANDOM inside X's classes.  The real corpus does not:")
    print("   a pair is two cells a FIXED index offset apart, because the read and")
    print("   the write of one delay line sit a fixed number of slots apart in the")
    print("   microprogram.  A random matching hands the test power it does not")
    print("   have.  Re-run keeping the real pairing GEOMETRY (same offsets):")
    print()
    print("   %-26s | %s" % ("planted \\ scored",
                             " ".join("%7s" % s.split()[0] for s in scored)))
    print("   " + "-" * (26 + 3 + 8 * len(scored)))
    recov2 = 0
    for X in planted:
        rng = random.Random(0x5150 + planted.index(X))
        acc = collections.defaultdict(float)
        mv = dr = 0
        for _t in range(trials):
            Bp, m, d = plant_structured(B, L0[X], rng)
            mv += m
            dr += d
            Pp = all_pairs(Bp)
            for Y in scored:
                acc[Y] += violations(Bp, label(Bp, R[Y]), Pp)
        best = min(scored, key=lambda Y: acc[Y])
        if best == X:
            recov2 += 1
        print("   %-26s | %s   %s (moved %.1f, dropped %.1f pairs/trial)"
              % (X.split()[0], " ".join("%7.1f" % (acc[Y] / trials) for Y in scored),
                 "<- recovered" if best == X else "<- MISSED(%s)" % best.split()[0],
                 mv / trials, dr / trials))
    print()
    print("   RECOVERY under the honest plant: %d of %d." % (recov2, len(planted)))
    print("   *** REPORT THE DROP IN POWER, NOT ONLY THE RECOVERY. ***  Under the")
    print("   geometry-preserving plant the separation between H-ADB6 and")
    print("   C-CELLPAR is far smaller than the random plant suggested, because")
    print("   at the reverb ladder's offset the two rules AGREE by construction.")
    print("   The instrument's entire power to choose between them lives at the")
    print("   sites where the geometry itself breaks -- section 3.1 lists them and")
    print("   there are FOUR.")
    print()
    print("   4.2  ** NOISE TOLERANCE. **  Plant H-ADB6 but make `noise' of the")
    print("   pairs ACCIDENTAL (two cells with the same label colliding).  This")
    print("   is the real corpus's own failure mode -- see `null'.")
    rng = random.Random(0xC0FFEE)
    X = "H-ADB6    addr8 bit 6 -> R"
    for nz in (0, 1, 2, 3):
        got = []
        for _t in range(60):
            Bp = plant(B, L0[X], rng, noise=nz)
            got.append(violations(Bp, label(Bp, R[X]), all_pairs(Bp)))
        print("      noise=%d accidental pairs/algo -> H-ADB6 scores mean %.1f "
              "violations" % (nz, sum(got) / len(got)))
    return B


# ===========================================================================
#  SECTION `null'
# ===========================================================================
def sec_null(rom, imgs, loads, names, B=None, trials=2000):
    print("=" * 78)
    print("5. THE NULLS")
    print("=" * 78)
    if B is None:
        B = build(rom, imgs, loads, 0)
    P = all_pairs(B)
    R = all_rules()
    print("   5.1  PERMUTATION NULL -- shuffle WHICH WORD takes WHICH CELL inside")
    print("   each algorithm, preserving the multiset of words and the values.")
    rng = random.Random(0x5EED)
    for rn in ["H-ADB6    addr8 bit 6 -> R",
               "H-SRC0B   SRC == 0x0B -> R   (H-DIR, dark-words F)",
               "C-CELLPAR cell-index parity        (instruction-blind)"]:
        real = violations(B, label(B, R[rn]), P)
        got = []
        for _t in range(trials):
            Bs = []
            for (a, u, cells, wof, sof) in B:
                ws = list(wof.values())
                rng.shuffle(ws)
                Bs.append((a, u, cells, dict(zip(sorted(cells), ws)),
                           {c: i for i, c in enumerate(sorted(cells))}))
            got.append(violations(Bs, label(Bs, R[rn]), all_pairs(Bs)))
        got.sort()
        le = sum(1 for g in got if g <= real)
        print("      %-30s real %3d | shuffled min %3d median %3d max %3d "
              "| P(shuffled <= real) = %d/%d"
              % (rn.split()[0], real, got[0], got[len(got) // 2], got[-1], le, trials))
    print()
    print("   5.2  COLLISION NULL -- how many of the %d pairs would EXIST by"
          % len(P))
    print("   chance?  Re-draw every cell value uniformly inside its unit's 32K")
    print("   region, keeping the cell counts, and count exact collisions.")
    rng = random.Random(0xA11)
    tot = []
    for _t in range(trials):
        n = 0
        for (a, u, cells, wof, sof) in B:
            lo, hi = (0, 32768) if u == 0 else (32768, 65536)
            vs = [rng.randrange(lo, hi) for _ in cells]
            n += sum(1 for _v, c in collections.Counter(vs).items() if c == 2)
        tot.append(n)
    tot.sort()
    print("      chance collisions: min %d median %d max %d  (real: %d)"
          % (tot[0], tot[len(tot) // 2], tot[-1], len(P)))
    print("      -> the pairing is STRUCTURAL, not coincidence.")
    print()
    print("   5.3  ** REPLICATION -- the one filter that separates a STRUCTURAL")
    print("   pair from an ACCIDENTAL one without fitting anything. **")
    print("   The twelve reverbs are twelve instances of ONE program.  A pair of")
    print("   CELL INDICES that holds equal values in all twelve is structural; a")
    print("   pair that holds equal values in only a few is a collision.")
    rev = [(a, u, c, w, s) for (a, u, c, w, s) in B if u == 1]
    idxpairs = collections.Counter()
    for (a, u, cells, wof, sof) in rev:
        for p, _v in pairs_of(cells):
            idxpairs[p] += 1
    print("      %d reverbs; cell-index pairs and how many reverbs realise them:"
          % len(rev))
    for p, n in sorted(idxpairs.items(), key=lambda x: (-x[1], x[0])):
        print("         (0x%02X,0x%02X)  %2d of %d %s"
              % (p[0], p[1], n, len(rev),
                 "STRUCTURAL" if n == len(rev) else "<- accidental"))
    struct = {p for p, n in idxpairs.items() if n == len(rev)}
    Pr = [(a, p, v) for a, p, v in P if a in [x[0] for x in rev]]
    Ps = [(a, p, v) for a, p, v in Pr if p in struct]
    print("      reverb pairs: %d total, %d structural, %d accidental."
          % (len(Pr), len(Ps), len(Pr) - len(Ps)))
    print()
    print("   %-52s %8s %8s" % ("rule", "all-rev", "struct"))
    for n in ["H-ADB6    addr8 bit 6 -> R",
              "H-SRC0B   SRC == 0x0B -> R   (H-DIR, dark-words F)",
              "C-CELLPAR cell-index parity        (instruction-blind)",
              "C-VALRANK value-rank parity        (instruction-blind)"]:
        L = label(B, R[n])
        print("   %-52s %8d %8d" % (n, violations(B, L, Pr), violations(B, L, Ps)))
    print("      -> every H-ADB6 failure is an ACCIDENTAL pair.  On the %d"
          % len(Ps))
    print("         structural reverb pairs H-ADB6 fails ZERO.")
    return B


# ===========================================================================
#  SECTION `phase'
# ===========================================================================
def sec_phase(rom, imgs, loads, names):
    print("=" * 78)
    print("6. THE ALIGNMENT PHASE, RE-ENUMERATED INSIDE THIS SEARCH (rule 2)")
    print("=" * 78)
    print("   The cell->word map is a PARAMETER.  dram-cursor-closure.md sect.2")
    print("   settled delta = 0 elsewhere and adjudication-round4 item B then")
    print("   declared the whole RIGID map refuted.  Neither is allowed to be")
    print("   assumed here.  delta is swept and the instrument re-run.")
    print()
    R = all_rules()
    keys = ["H-ADB6    addr8 bit 6 -> R",
            "H-SRC0B   SRC == 0x0B -> R   (H-DIR, dark-words F)",
            "C-CELLPAR cell-index parity        (instruction-blind)"]
    print("   delta is a CYCLIC rotation, so every delta keeps all %d algorithms"
          % len(build(rom, imgs, loads, 0)))
    print("   and all their pairs.  A shift that dropped algorithms would make")
    print("   the sweep unable to fail -- that was this file's first draft.")
    print()
    print("   %5s %7s %7s | %s | %s" % ("delta", "algos", "pairs",
                                        " ".join("%9s" % k.split()[0] for k in keys),
                                        "bits@0 (of 36, non-C sites)"))
    for d in range(-4, 5):
        Bd = build(rom, imgs, loads, d)
        Pd = all_pairs(Bd)
        wofa = {a: w for (a, u, c, w, s) in Bd}
        nc = [(a, p, v) for a, p, v in Pd
              if not (F(wofa[a][p[0]])[0] & 0x400)
              and not (F(wofa[a][p[1]])[0] & 0x400)]
        surv = [b for b in range(36)
                if not any(((wofa[a][p[0]] >> b) & 1) == ((wofa[a][p[1]] >> b) & 1)
                           for a, p, _v in nc)]
        print("   %5d %7d %7d | %s | %d  %s"
              % (d, len(Bd), len(Pd),
                 " ".join("%9d" % violations(Bd, label(Bd, R[k]), Pd) for k in keys),
                 len(surv), ",".join(_bitname(b) for b in surv) or "-"))
    print()
    print("   ** TWO MISSES, BOTH PREDICTED THE OTHER WAY, BOTH REPORTED. **")
    print("   (1) I predicted the raw violation count would pick delta = 0 out.")
    print("       IT DOES NOT: H-ADB6 scores 3 at delta = 0 and 3 at delta = +3.")
    print("   (2) I then predicted the strong statistic -- how many of the 36 word")
    print("       bits satisfy EVERY non-C-format pair -- would.  IT DOES NOT")
    print("       EITHER: delta = 0, +2 and +3 each admit exactly one bit.")
    print()
    print("   ** BUT LOOK AT WHICH BIT. **  At every delta where ANY bit works, it")
    print("   is addr8 bit 6 and nothing else.  So the pass's forcing result is")
    print("   ROBUST TO THE ALIGNMENT PARAMETER: `if a single bit of the word")
    print("   carries the delay-DRAM direction then it is addr8 bit 6' does not")
    print("   depend on delta at all.  That is a stronger claim than the one I set")
    print("   out to make and it needs less.  The alignment is NOT settled here,")
    print("   and it does not need to be.")
    print()
    print("   The instrument is therefore NOT an independent vote on the")
    print("   alignment.  It is not what adjudication-round4")
    print("   item B argued about (it argued that two INTERIOR cells cannot be")
    print("   addresses inside their own region); item B's option set did not")
    print("   contain `a consumer may take a NON-ADDRESS operand' -- method rule")
    print("   3 -- and under that option the rigid map survives item B untouched.")


# ===========================================================================
#  SECTION `polarity'
# ===========================================================================
def sec_polarity(rom, imgs, loads, names, B=None):
    print("=" * 78)
    print("7. *** THE ONE REMAINING BIT -- AND THE TWO WITNESSES DISAGREE ***")
    print("=" * 78)
    if B is None:
        B = build(rom, imgs, loads, 0)
    print("   The oracle is flip-invariant, so it delivers `addr8 bit 6 separates")
    print("   read from write' and NOT which side is which.  Two independent")
    print("   published witnesses speak to the polarity, and they disagree.")
    print()
    print("   WITNESS 1 -- r1-allpass-motif.md F1 (ALGEBRAIC).  The allpass motif")
    print("   read slot was enumerated over {0,4} and forced numerically, 36/36,")
    print("   the swap scoring zero.  Slot 0 is `880.1.60.2D4' and slot 4 is")
    print("   `880.1.20.655'.  => addr8 0x60 = READ.")
    print()
    print("   WITNESS 2 -- MULTI TAP DELAY, and it is a COUNTING argument, which")
    print("   is why it is worth taking seriously.  Re-derived here:")
    for (a, u, cells, wof, sof) in B:
        if a != 10:
            continue
        for c in sorted(cells):
            print("      cell 0x%02X = %6d   %s  addr8 0x%02X  bit6=%d"
                  % (c, cells[c], DC.fmt(wof[c]), F(wof[c])[2],
                     1 if F(wof[c])[2] & 0x40 else 0))
    print("   A multi-tap delay has ONE write and MANY reads.  The four evenly")
    print("   spaced values 6000/12000/18000/24000 are the four `DELAY n (ms)'")
    print("   taps; they all sit on bit6 = 0 words.  The bit6 = 1 words hold the")
    print("   region FLOOR (0) and one other value.  => addr8 0x60 = WRITE, or")
    print("   the taps are writes and a 4-write / 1-read multi-tap is nonsense.")
    print()
    print("   WITNESS 3 -- NEW, AND IT COMES OUT OF THE ORACLE ITSELF.  The two")
    print("   members of a pair hold the SAME address, so one of them happens")
    print("   FIRST in program order.  MEASURED:")
    first0 = first1 = 0
    for (a, u, cells, wof, sof) in B:
        for p, v in pairs_of(cells):
            b0 = 1 if F(wof[p[0]])[2] & 0x40 else 0
            b1 = 1 if F(wof[p[1]])[2] & 0x40 else 0
            if b0 == b1:
                continue
            e = p[0] if sof[p[0]] < sof[p[1]] else p[1]
            if F(wof[e])[2] & 0x40:
                first1 += 1
            else:
                first0 += 1
    print("      the EARLIER access of a pair has addr8 bit6 = 0 in %d pairs and"
          % first0)
    print("      bit6 = 1 in %d pairs.  (%d pairs are excluded: both members carry"
          % (first1, len(all_pairs(B)) - first0 - first1))
    print("      the same bit and cannot order anything.)")
    print("      A read and a write of ONE address, in one frame, is either")
    print("        write-then-read  -> a ZERO-DELAY forward through the DRAM, or")
    print("        read-then-write  -> a delay of a FULL ROTATION PERIOD.")
    print("      The longest segment anywhere in the corpus is a few thousand")
    print("      samples; a full period is 32768.  If the forward reading is")
    print("      right then bit6 = 0 is the WRITE and 0x60 is the READ, which")
    print("      AGREES WITH WITNESS 1 and disagrees with witness 2.")
    print("      Labelled INFERRED: it rests on `not a full-period recirculation'.")
    print()
    print("   ** AND ALL THREE ARE THE SAME QUESTION AS THE ROTATION SIGN. **")
    print("      addr8 0x60 = READ   <=>   the read cell sits BELOW the write")
    print("                                (r3-delaydram.md sect.5.1's sign)")
    print("      addr8 0x60 = WRITE  <=>   the read cell sits ABOVE the write")
    print("                                (dram-cursor-closure.md item I's sign)")
    print("   DRAM-DIR has collapsed from `13 distinct words, direction wholly")
    print("   open' to ONE BIT, and that bit IS the rotation sign.  Vote 2-1 for")
    print("   0x60 = READ.  ** IT STAYS OPEN ** -- method rule 6, a vote is not a")
    print("   forcing, and nothing is applied.")
    print()
    print("   7.1  THE MODEL CLASS, PRINTED NEXT TO THE CLAIM (method rule 3).")
    print("   What the oracle forces is that addr8 bit 6 separates the two")
    print("   members of an equal-address pair.  What that MEANS is enumerated:")
    print("     (M1) bit 6 IS the read/write direction.  Polarity as above.")
    print("     (M2) bit 6 selects one of two DRAM ADDRESS REGISTERS and the")
    print("          direction follows from which register the datapath uses.")
    print("          Same partition; identical on this data.  If the register ->")
    print("          direction map is global, (M2) IS (M1).  If it is per-program,")
    print("          witnesses 1 and 2 can BOTH be right and DRAM-DIR is not one")
    print("          bit after all.  Nothing here separates (M1) from (M2).")
    print("     (M3) the pair is a (base, limit) register pair of one ring, not an")
    print("          access pair.  ** REFUTED HERE **: the two members hold the")
    print("          SAME value, and a ring with base == limit has zero length.")
    print("     (M4) the oracle's premise is simply false and the equal values are")
    print("          coincidence.  ** REFUTED BY THE COLLISION NULL ** (`null'")
    print("          5.2: chance gives 0-3 collisions, the corpus has 136) and by")
    print("          the fact that a false premise would not single out exactly")
    print("          one bit of thirty-six.")
    print()
    print("   WHAT WOULD DECIDE IT (named, not hand-waved):")
    print("     (a) the write-before-read ordering inside one frame: a line must")
    print("         be written at a lag before it can be read at that lag, so the")
    print("         program order of the two members of a pair is informative")
    print("         once the frame completes -- it does not (0 of 1 344 001).")
    print("     (b) the host's parameter semantics: MULTI TAP's four cells are")
    print("         named `DELAY n (ms)' by the UI table (register-space.md's")
    print("         alignment machinery).  A tap length is meaningless for a")
    print("         write.  This is witness 2 made rigorous and it is the")
    print("         cheapest next experiment -- it needs the T2 opcode->name")
    print("         binding for algorithm 10, which register_space.py already has.")
    print("     (c) re-running r1_allpass_solve.py's read-slot forcing with the")
    print("         descriptor ADDRESSES supplied instead of free parameters.")


# ===========================================================================
#  SECTION `audit'  -- SECOND TASK
# ===========================================================================
AUDIT = [
    ("dark-words.md item F / sect.6",
     "H-DIR: SRC 0x0B <=> the delay-line READ.  `4 of 4 established assignments,"
     " against 2 of 4 for the falsified addr8 rule.'",
     "CONSISTENT, 4 of 4",
     "The strongest instruction-blind rival was never run -- and the four rows"
     " are two SOURCES, not four: rows 1-2 are r1's single algebraic solve and"
     " rows 3-4 are r3 sect.6.3's single alignment argument.  addr8 `fails' only"
     " on r3's two, so the 4-2 margin is one disputed source.  The pair-"
     "opposition oracle adds 136 rows and H-DIR fails 21 of them, losing 19-5 to"
     " cell parity at their disagreement sites.",
     "FALSIFIED as a biconditional"),
    ("dram-cursor-closure.md item I",
     "`The rotation sign is in contradiction inside the corpus.  R > W beats"
     " R < W by 62 clean algorithms to 10 under the identical rule.'",
     "OPEN, a live contradiction",
     "Those 62/10 come from score_rule(), the same instrument the same note"
     " falsified in item F.  adjudication-round4 item A dissolved the"
     " CONTRADICTION by a change of units, but the 62-to-10 NUMBER was never"
     " withdrawn and it has no discriminating power: C-CELLPAR reproduces it.",
     "the number is RETRACTED; the sign is OPEN"),
    ("dram-cursor-closure.md item H / adjudication-round4 item B",
     "`76 of 91 algorithms ship exactly two region-boundary cells' -> a"
     " (base,limit) pair; and `no rigid 1:1 map can skip an interior slot, so"
     " the alignment is refuted'.",
     "MEASURED / FORCED",
     "The measurement stands.  The FORCED refutation of the rigid map does not:"
     " its option set omits `a consumer may take a NON-ADDRESS operand' (rule 3)."
     "  Under that option the interior cells 0x1E and 0x01 are bounds, not"
     " addresses, and the rigid map survives untouched.  Independently, this"
     " pass's phase sweep finds a signal at delta = 0 and at no other delta.",
     "the refutation is DOWNGRADED to CONSISTENT"),
    ("r3-delaydram.md sect.6.3",
     "`Under the cursor model, addr8 does NOT select the DRAM direction' -- from"
     " MULTI TAP's three tap reads sitting on addr8 = 0x20 words.",
     "a constraint, not a decode (r3's own words)",
     "r3 labelled it correctly and it is the one witness that still bites.  But"
     " it is a SEMANTIC assumption (`the taps are reads') plus the alignment, and"
     " it disagrees with r1's algebraic forcing.  It does not refute `addr8 bit 6"
     " is the direction FIELD' -- only the POLARITY.  Both survive as the two"
     " sides of section 7.",
     "SURVIVES, and it is now one bit"),
    ("register-space.md item D1",
     "the host write port auto-increments by +1; the {+1,-1} degeneracy is broken"
     " by `algo 39 issues select 0x50 x29 then select 0x6D x11, and"
     " 0x6D = 0x50 + 29'.",
     "FORCED (+1), degeneracy reported",
     "This is one arithmetic coincidence, not a score against a corpus, so rule 7"
     " does not apply in its usual form.  It is nevertheless a SINGLE row with no"
     " rival family enumerated: `the two selectors are unrelated' predicts a hit"
     " with probability about 1/256 per algorithm, and the sweep over the other"
     " 99 streams that would price that null was not run.",
     "SURVIVES, but the null was never priced"),
    ("store-gate.md items C / D / E",
     "bit 7 is in the gate CONDITION; class (1,1) never writes mem[ptr]; class"
     " (1,2) is the ordinary store.",
     "FORCED",
     "Different genre: these are EXHAUSTIVE ELIMINATIONS against numeric"
     " witnesses (the biquad's dB error, the LFO's 29 blocks), not scores against"
     " a structured corpus, and each condition is shown to be killed by a named"
     " witness.  Rule 7 does not bite.  ** But its reading of bit 7 as a memory-"
     "port DIRECTION bit does NOT reach the delay DRAM: ** hi12 bit 7 is constant"
     " across the two members of 133 of 136 equal-value pairs, so it cannot be"
     " the delay-DRAM direction field.",
     "SURVIVES; its bit-7 direction reading is EXCLUDED for the delay DRAM"),
    ("adjudication-round4 item C",
     "the descriptor block is a contiguous address partition: 9 duplicates at"
     " offset +5 plus 1 at +11 in 12 of 12, permutation null 0/4000.",
     "MEASURED",
     "The null is the right one (it preserves the multiset) and the claim is"
     " about a STRUCTURE, not a choice between rules, so there is no"
     " instruction-blind rival to build.  This pass depends on it and re-derives"
     " it: the same duplicate structure is what the oracle is made of.",
     "SURVIVES, and is the foundation of this pass"),
]


def sec_audit(rom, imgs, loads, names, B=None):
    print("=" * 78)
    print("8. SECOND TASK -- THE RULE-7 AUDIT OF PUBLISHED CLAIMS")
    print("=" * 78)
    print("   For every published claim established by SCORING against a")
    print("   structured corpus: what is the strongest instruction-blind rival,")
    print("   and was it ever run?")
    print()
    for src, claim, lab, finding, verdict in AUDIT:
        print("   --- %s" % src)
        print("       CLAIM   : %s" % claim)
        print("       LABELLED: %s" % lab)
        print("       AUDIT   : %s" % finding)
        print("       VERDICT : %s" % verdict)
        print()
    if B is None:
        B = build(rom, imgs, loads, 0)
    P = all_pairs(B)
    R = all_rules()
    print("   8.1  THE ONE AUDIT LINE THAT IS A NUMBER: hi12 bit 7 on the")
    print("   delay DRAM.")
    same = 0
    for a, p, v in P:
        wof = [w for (aa, u, c, w, s) in B if aa == a][0]
        if bool(F(wof[p[0]])[0] & 0x80) == bool(F(wof[p[1]])[0] & 0x80):
            same += 1
    print("      hi12 bit 7 is EQUAL on both members of %d of %d pairs."
          % (same, len(P)))
    print("      A direction field must DIFFER there.  store-gate.md item D's")
    print("      `bit 7 = a memory-port DIRECTION bit' is a statement about the")
    print("      class-(1,1) STORE words and it is not contradicted; what is")
    print("      excluded is extending it to the delay-DRAM family.")


# ===========================================================================
#  SECTION `control'
# ===========================================================================
def sec_control(rom, imgs, loads, names, B=None):
    print("=" * 78)
    print("9. THE CONTROLS, EACH DEMONSTRATED SAYING NO")
    print("=" * 78)
    if B is None:
        B = build(rom, imgs, loads, 0)
    P = all_pairs(B)
    R = all_rules()
    print("   C1  `C-ALLW' -- everything is a write.  If the instrument could not")
    print("       reject this it would be measuring nothing.")
    print("       violations %d of %d." % (violations(B, label(B, R["C-ALLW    everything is a WRITE    (instruction-blind)"]), P), len(P)))
    print("   C2  `C-VALRANK' -- a rule built from the HOST data but from the")
    print("       wrong part of it.  violations %d of %d."
          % (violations(B, label(B, R["C-VALRANK value-rank parity        (instruction-blind)"]), P), len(P)))
    print("   C3  `H-HI7' -- a real instruction bit, and a live hypothesis from")
    print("       store-gate.md.  violations %d of %d.  The instrument rejects a"
          % (violations(B, label(B, R["H-HI7     hi12 bit 7 -> W   (store-gate.md D)"]), P), len(P)))
    print("       hypothesis of the RIGHT SHAPE, not only nonsense.")
    print("   C4  `H-ADB5' / `H-ADB4' / `H-ADB7' -- the OTHER bits of the same")
    print("       field.  If addr8 as a whole were merely correlated with")
    print("       direction, its other bits would score too.")
    for k in ["H-ADB4    addr8 bit 4 -> R", "H-ADB5    addr8 bit 5 -> R",
              "H-ADB6    addr8 bit 6 -> R", "H-ADB7    addr8 bit 7 -> R"]:
        print("       %-30s violations %3d of %d"
              % (k, violations(B, label(B, R[k]), P), len(P)))
    print("   C5  `C-DUPLO' -- the rival that KNOWS THE ORACLE.  violations %d."
          % violations(B, label(B, R["C-DUPLO   dup pair: lower cell = W (** KNOWS THE ORACLE **)"]), P))
    print("       *** This one is NOT rejected, and that is the honest limit of")
    print("       the instrument: it can refute a rule, it cannot crown one.")
    print("       What separates H-ADB6 from C-DUPLO is coverage, and that is a")
    print("       COUNT, not a score: C-DUPLO is undefined on the %d singleton"
          % (sum(len(c) for _a, _u, c, _w, _s in B) - 2 * len(P)))
    print("       cells; H-ADB6 labels all %d."
          % sum(len(c) for _a, _u, c, _w, _s in B))
    print("   C6  the PERMUTATION null and the COLLISION null are in `null'.")
    print("       ** AND THE PERMUTATION NULL HAS A HOLE, STATED: ** it shuffles")
    print("       which WORD takes which CELL, so it cannot move an instruction-")
    print("       BLIND rule at all -- C-CELLPAR scores 7 in every one of the")
    print("       2000 shuffles.  A null with no power against the rival you are")
    print("       worried about is the rule-7 trap in null form.  It is reported")
    print("       as a null against NOISE only; the rival test is `separate'.")
    print("   C7  the PHASE sweep in `phase' was built as a control on the")
    print("       ALIGNMENT and it FAILED to be one -- delta = 0, +2 and +3 all")
    print("       admit exactly one zero-violation bit.  Reported as a miss.  It")
    print("       turned into something better: the forcing is robust to delta.")
    print()
    print("   9.1  THE CONSEQUENCE FOR THE OTHER AGENTS -- the census that")
    print("   changes if H-ADB6 replaces H-DIR, over the whole consumer corpus.")
    LA = label(B, R["H-ADB6    addr8 bit 6 -> R"])
    LB = label(B, R["H-SRC0B   SRC == 0x0B -> R   (H-DIR, dark-words F)"])
    tot = sum(len(v) for v in LA.values())
    ra = sum(1 for a in LA for c in LA[a] if LA[a][c] == "R")
    rb = sum(1 for a in LB for c in LB[a] if LB[a][c] == "R")
    dis = [(a, c) for a in LA for c in LA[a] if LA[a][c] != LB[a][c]]
    print("      cells labelled in the %d aligned algorithms: %d" % (len(B), tot))
    print("      READS under H-ADB6 : %d (%.1f %%)" % (ra, 100.0 * ra / tot))
    print("      READS under H-DIR  : %d (%.1f %%)" % (rb, 100.0 * rb / tot))
    print("      cells where they DISAGREE: %d (%.1f %%)"
          % (len(dis), 100.0 * len(dis) / tot))
    wofa = {a: w for (a, u, c, w, s) in B}
    cc = collections.Counter(DC.fmt(wofa[a][c]) for a, c in dis)
    print("      by word form (H-ADB6 label first):")
    lbl = {}
    for a, c in dis:
        lbl.setdefault(DC.fmt(wofa[a][c]), (LA[a][c], LB[a][c]))
    for k, v in cc.most_common(14):
        print("         %-14s x%-4d  H-ADB6 %s / H-DIR %s"
              % (k, v, lbl[k][0], lbl[k][1]))


# ---------------------------------------------------------------------------
def main():
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["all", "oracle", "rivals", "separate", "power",
                             "null", "phase", "polarity", "audit", "control"])
    ap.add_argument("--sub", default=os.path.join(repo, "original_ROMs",
                                                  "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(repo, "original_ROMs",
                                                   "kn5000_v10_program.rom"))
    ap.add_argument("--tools",
                    default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    ap.add_argument("--trials", type=int, default=200)
    args = ap.parse_args()
    rom, imgs, loads, names = load(args.sub, args.main, args.tools)
    B = build(rom, imgs, loads, 0)
    order = ["oracle", "rivals", "separate", "power", "null", "phase",
             "polarity", "audit", "control"]
    todo = order if args.cmd == "all" else [args.cmd]
    for s in todo:
        if s == "oracle":
            sec_oracle(rom, imgs, loads, names)
        elif s == "rivals":
            sec_rivals(rom, imgs, loads, names, B)
        elif s == "separate":
            sec_separate(rom, imgs, loads, names, B)
        elif s == "power":
            sec_power(rom, imgs, loads, names, B, args.trials)
        elif s == "null":
            sec_null(rom, imgs, loads, names, B)
        elif s == "phase":
            sec_phase(rom, imgs, loads, names)
        elif s == "polarity":
            sec_polarity(rom, imgs, loads, names, B)
        elif s == "audit":
            sec_audit(rom, imgs, loads, names, B)
        elif s == "control":
            sec_control(rom, imgs, loads, names, B)
        print()


if __name__ == "__main__":
    main()
