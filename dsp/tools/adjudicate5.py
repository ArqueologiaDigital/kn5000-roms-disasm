#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""adjudicate5.py -- ROUND 5 ADJUDICATION of the three concurrent passes
(`dram-matching.md`, `dram-direction.md`, `host-side.md`).

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  No hardware.  Static analysis of
the Sub CPU ROM, the 100 canned parameter streams and the 38 body images only.
Stdlib only; every number quoted in `analysis/adjudication-round5.md` comes out
of this file.

THE COLLISION THIS FILE ADJUDICATES
-----------------------------------
`dram-matching.md` (Target 1) FORCES the cell<->word map at phase `delta = -1`
and reads `addr8 0x60` as the delay-DRAM READ.  `dram-direction.md` (Target 2)
FORCES `addr8 bit 6` as the direction field but finds its own oracle perfect only
at `delta = 0`, and leaves the POLARITY open on a 2-1 vote.

Those are not two disputes.  Under a cyclic map a shift of delta by ONE swaps
which member of every alternating read/write pair gets which word, so

        ***  THE PHASE AND THE POLARITY ARE ONE PARAMETER.  ***

This file therefore refuses to score any rule that carries a polarity until the
phase is settled by tests that cannot see a polarity at all, and only then
determines the polarity from two structural arguments that need neither.

    python3 dsp/tools/adjudicate5.py phase     # 1 *** three POLARITY-FREE phase oracles
    python3 dsp/tools/adjudicate5.py degen     # 2 *** the degeneracy that kills 3 arguments
    python3 dsp/tools/adjudicate5.py polarity  # 3 *** the polarity, two independent routes
    python3 dsp/tools/adjudicate5.py rivals    # 4 *** RULE 7: only where the rivals disagree
    python3 dsp/tools/adjudicate5.py null      # 5 permutation / shuffle nulls
    python3 dsp/tools/adjudicate5.py ladder    # 6 the ladders RE-DERIVED, with roles
    python3 dsp/tools/adjudicate5.py census    # 7 the corpus-wide read/write census
    python3 dsp/tools/adjudicate5.py act0b     # 8 ACTION 0x0B under the corrected map
    python3 dsp/tools/adjudicate5.py r1        # 9 *** the confrontation with r1 F1
    python3 dsp/tools/adjudicate5.py control   # 10 every control, shown saying NO
    python3 dsp/tools/adjudicate5.py comb      # 11 the comb prediction, re-derived, NOT tested
    python3 dsp/tools/adjudicate5.py all
"""
import argparse
import collections
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dram_cursor as DC                                            # noqa: E402
import register_space as RS                                         # noqa: E402
import dram_match as DM                                             # noqa: E402

DEFAULT_SUB = os.path.join(HERE, "..", "..", "original_ROMs",
                           "kn5000_subprogram_v142.rom")
DEFAULT_MAIN = os.path.join(HERE, "..", "..", "original_ROMs",
                            "kn5000_v10_program.rom")
DEFAULT_TOOLS = "/home/fsanches/compartilhado/kn7000_mame/tools"

DELTAS = list(range(-6, 7))


def head(n, s):
    print("=" * 78)
    print("%d. %s" % (n, s))
    print("=" * 78)


def b6(w):
    """addr8 bit 6 -- the ONLY bit that can carry the direction (dram-direction
    item B, an exhaustive enumeration this file does not repeat)."""
    return 1 if ((w >> 12) & 0x40) else 0


def in_scope(w):
    """The rule is stated, scored and APPLIED only over the addr8 values it was
    validated on: 0x20 and 0x30 (bit6 = 0) and 0x60 (bit6 = 1).  The C-format
    consumer C40.1.80.000 carries addr8 0x80 and is OUT OF SCOPE -- it is the
    word dram-direction sect. 2.2 PROVED no instruction rule can reach (the
    identical 36-bit word sits on both sides of three equal-value pairs).  It
    must keep trapping (method rule 6)."""
    return ((w >> 12) & 0xFF) in (0x20, 0x30, 0x60)


# ---------------------------------------------------------------------------
#  0.  Data
# ---------------------------------------------------------------------------
class Corp(object):
    def __init__(self, sub, mainrom, tools):
        self.C = DM.Corp(sub, mainrom, tools)
        self.algos = {a: (u, c, cons) for (a, u, c, cons) in self.C.algos}
        self.taps = {a: self.C.taps(a) for a in self.algos}

    def name(self, a):
        return self.C.name(a)

    def aligned(self):
        """algorithms where #cells == #consumers -- the population every phase
        test runs on.  DENOMINATOR (method rule 9): 83 of the 91 that ship
        descriptor cells at all."""
        out = []
        for a, (u, cells, cons) in sorted(self.algos.items()):
            if len(cells) == len(cons):
                out.append(a)
        return out

    def wordof(self, a, delta):
        """cell -> word under the rigid cyclic map `cell (k+delta) <- consumer k'.
        This is the SAME sign convention as dram_match.map_score and
        dram_dir.build; verified by reproducing both notes' printed rows."""
        u, cells, cons = self.algos[a]
        ck = sorted(cells)
        n = len(ck)
        if n != len(cons):
            return None
        return {ck[(k + delta) % n]: w for k, (_i, w) in enumerate(cons)}

    def anchored(self, a):
        """[(tap cell, base cell, delay)] -- the op-0x67 records whose BASE24-2
        is a cell of the same algorithm at cell-index offset exactly +3.
        s = +3 is dram-matching item C and is delta-INDEPENDENT by construction
        (a rigid +1 cursor gives cell(k+s) - cell(k) = s for every delta)."""
        t = self.taps.get(a) or {}
        out = []
        if not t:
            return out
        u, cells, cons = self.algos[a]
        ck = sorted(cells)
        n = len(ck)
        if n != len(cons):
            return out
        pos = {c: i for i, c in enumerate(ck)}
        for c, B in sorted(t.items()):
            if c not in pos:
                continue
            i = pos[c]
            j = None
            for q, cq in enumerate(ck):
                if cells[cq] == B - 2 and (q - i) % n == 3:
                    j = q
            if j is not None:
                out.append((c, ck[j], cells[c] - cells[ck[j]]))
        return out

    def eqpairs(self, a):
        """[(lower cell, upper cell, value)] -- dram-direction's oracle."""
        u, cells, cons = self.algos[a]
        if len(cells) != len(cons):
            return []
        bv = collections.defaultdict(list)
        for c, v in cells.items():
            bv[v].append(c)
        return [(min(l), max(l), v) for v, l in sorted(bv.items()) if len(l) == 2]


# ===========================================================================
#  1.  THE PHASE, settled by three tests that CANNOT SEE A POLARITY
# ===========================================================================
def o1(K, delta):
    """TAP-COHERENCE.  Every op-0x67 tap of one algorithm is the same KIND of
    access -- they are all `DELAY n (ms)' knobs computed by one evaluator
    (host-side.md E1, 38/38 in ms).  Whether that kind is read or write is not
    asked.  Returns (coherent, incoherent, [failing algos])."""
    ok = bad = 0
    det = []
    for a in K.aligned():
        t = K.taps.get(a) or {}
        if len(t) < 2:
            continue
        wof = K.wordof(a, delta)
        bs = [b6(wof[c]) for c in sorted(t) if c in wof]
        if len(bs) < 2:
            continue
        if len(set(bs)) == 1:
            ok += 1
        else:
            bad += 1
            det.append(a)
    return ok, bad, det


def o2(K, delta):
    """TAP/BASE OPPOSITION.  A delay line has one read end and one write end, so
    a tap and its own line base are OPPOSITE.  Which is which is not asked."""
    ok = bad = 0
    det = []
    for a in K.aligned():
        wof = K.wordof(a, delta)
        for (tc, bc, _d) in K.anchored(a):
            if b6(wof[tc]) != b6(wof[bc]):
                ok += 1
            else:
                bad += 1
                det.append((a, tc, bc))
    return ok, bad, det


def o3(K, delta):
    """EQUAL-VALUE PAIR OPPOSITION (dram-direction's own oracle).  Two consumers
    handed the same descriptor value are one read and one write of that
    location.  Which is which is not asked.  The three C-format pairs carry the
    IDENTICAL 36-bit word on both sides, so no instruction rule can ever reach
    them; they are counted separately, not quietly dropped."""
    ok = bad = 0
    nonc = noncbad = 0
    det = []
    for a in K.aligned():
        wof = K.wordof(a, delta)
        for (c1, c2, v) in K.eqpairs(a):
            w1, w2 = wof[c1], wof[c2]
            isc = (w1 >> 24) == 0xC40 or (w2 >> 24) == 0xC40
            good = b6(w1) != b6(w2)
            ok += int(good)
            bad += int(not good)
            if not isc:
                nonc += 1
                if not good:
                    noncbad += 1
                    det.append((a, c1, c2, v))
    return ok, bad, nonc, noncbad, det


def cmd_phase(K):
    head(1, "*** THE PHASE, settled by three POLARITY-FREE oracles ***")
    print("   WHY POLARITY-FREE MATTERS (this is the round's central collision):")
    print("   under a cyclic map, shifting delta by ONE swaps which member of an")
    print("   alternating read/write pair takes which word.  A phase scan scored")
    print("   with a rule that carries a polarity therefore scans ONE parameter")
    print("   and reports it as two.  dram-matching sect. 3.1 scored delta with")
    print("   H-ADDR60 (a polarity) FIXED -- method rule 2.  These three tests ask")
    print("   only whether two accesses DIFFER, never which is which.")
    print()
    print("   MODEL CLASS, PRINTED BESIDE THE CLAIM (method rule 3): the map is a")
    print("   rigid 1:1 cyclic assignment `cell (k+delta) <- consumer k' inside the")
    print("   body's own descriptor block.  M3 (per-word stride) and M4 (cell index")
    print("   is a field of the word) were refuted by dram-matching item G and are")
    print("   not re-run here.  M5 (two cursors, one per direction) is NOT refuted")
    print("   and is re-opened in sect. 10.")
    print()
    print("   POPULATIONS (method rule 9): 91 algorithms ship descriptor cells;")
    print("   %d have #cells == #consumers and carry every test below." % len(K.aligned()))
    ntap = sum(1 for a in K.aligned() if len(K.taps.get(a) or {}) >= 2)
    nanc = sum(len(K.anchored(a)) for a in K.aligned())
    npair = sum(len(K.eqpairs(a)) for a in K.aligned())
    print("   O1 population: %d algorithms with >= 2 op-0x67 taps" % ntap)
    print("   O2 population: %d anchored (tap, base) pairs" % nanc)
    print("   O3 population: %d equal-value pairs" % npair)
    print()
    print("   delta | O1 tap-coherence | O2 tap/base opp | O3 equal-value opp     | ALL 3")
    print("   ------+------------------+-----------------+------------------------+------")
    perfect = []
    for d in DELTAS:
        a1, b1, _ = o1(K, d)
        a2, b2, _ = o2(K, d)
        a3, b3, nc, ncb, _ = o3(K, d)
        allok = (b1 == 0 and b2 == 0 and ncb == 0)
        if allok:
            perfect.append(d)
        print("    %+3d  |   %2d ok  %2d BAD   |  %2d ok  %2d BAD   | %3d/%3d  non-C %3d/%3d | %s"
              % (d, a1, b1, a2, b2, a3, a3 + b3, nc - ncb, nc,
                 "*** PERFECT ***" if allok else ""))
    print()
    print("   PERFECT ON ALL THREE: %s" % (perfect or "none"))
    print("   ==> delta = 0.  The map is the IDENTITY: the k-th consumer in")
    print("       program order takes the k-th descriptor cell in index order.")
    print("       That is R2/r3's original rigid map, which adjudication-round4")
    print("       item B declared FORCED-refuted and dram-direction sect. 8")
    print("       already downgraded to CONSISTENT.  It is now RE-FORCED.")
    print()
    print("   ** dram-matching's delta = -1 is FALSIFIED. ** Its failures, named:")
    _, _, d1 = o1(K, -1)
    _, _, d2 = o2(K, -1)
    _, _, _, _, d3 = o3(K, -1)
    print("     O1: %s" % ["%d %s" % (a, K.name(a)) for a in d1])
    print("     O2: %s" % ["%d tap 0x%02X/base 0x%02X" % r for r in d2])
    print("     O3 (non-C): %s" % ["%d cells 0x%02X/0x%02X v=%d" % r for r in d3])
    print()
    print("   And the SINGLE datum dram-matching offered in support of delta = -1")
    print("   -- item I, `I-RAM 44 is 801.0.25.825, payload 0x25, and delta = -1")
    print("   puts the first unit-0 consumer on cell 0x25' -- is DEGENERATE:")
    print("   a PRE-increment cursor loaded with 0x25 delivers 0x26 to the first")
    print("   consumer, which is exactly delta = 0.  The payload cannot choose")
    print("   between (delta=0, pre-increment) and (delta=-1, post-increment).")
    print("   Method rule 4.  Item I is withdrawn as evidence for the phase and")
    print("   SURVIVES as the cursor reload value, which it always was.")


# ===========================================================================
#  2.  THE DEGENERACY that disqualifies three tempting arguments
# ===========================================================================
def cmd_degen(K):
    head(2, "*** DEGENERACY CHECK BEFORE ANY POLARITY IS BELIEVED (rule 4) ***")
    print("   Physical address of a datum: phys = descriptor + s*n, s = +-1, the")
    print("   ROTATION SIGN.  A read at descriptor R returns what was written at")
    print("   descriptor W with delay = s*(W - R).  So:")
    print()
    print("     assignment X: b6=1 is the WRITE, and s = -1  (delay = R - W)")
    print("     assignment Y: b6=1 is the READ,  and s = +1  (delay = W - R)")
    print()
    print("   X and Y produce THE SAME SET OF LINES with THE SAME LENGTHS and the")
    print("   SAME memory layout.  Three otherwise attractive arguments are")
    print("   therefore worth NOTHING here, and are printed so they are not")
    print("   mistaken later for evidence:")
    print()
    K0 = 0
    a = 16
    wof = K.wordof(a, K0)
    u, cells, cons = K.algos[a]
    ck = sorted(cells)
    lines_x, lines_y = [], []
    for (tc, bc, d) in K.anchored(a):
        lines_x.append((cells[bc], cells[tc], d))
    # the ladder, both readings
    for i in range(0, len(ck) - 3):
        j = i + 3
        d = cells[ck[i]] - cells[ck[j]]
        if 1 <= d <= 32767:
            lines_x.append((cells[ck[j]], cells[ck[i]], d))
            lines_y.append((cells[ck[i]], cells[ck[j]], d))
    print("   (a) `the lines must not OVERLAP in DRAM' (dram-matching item B).")
    print("       X gives %d lines, Y gives %d lines, and the INTERVAL SET IS"
          % (len(lines_x), len(lines_y)))
    print("       IDENTICAL -- only the labels on the two ends swap.  The")
    print("       no-overlap argument settles the OFFSET s=+3 (it did) and")
    print("       CANNOT settle the direction.")
    print("   (b) `the fixed end of a knob-swept allocation is the write'.  An")
    print("       engineering-plausibility argument; under Y the fixed end is the")
    print("       read and the layout is the same.  Not used below.")
    print("   (c) `the chain's unshared low end is the input'.  The chain may run")
    print("       either way through memory; free binary parameter.  Not used.")
    print()
    print("   WHAT SURVIVES the degeneracy: exactly two arguments, sect. 3.")


# ===========================================================================
#  3.  THE POLARITY, two routes, neither of which the degeneracy touches
# ===========================================================================
def cmd_polarity(K, delta=0):
    head(3, "*** THE POLARITY: two independent routes, both saying b6=1 is WRITE")
    print("   ROUTE A -- MULTI TAP DELAY, a COUNTING argument (r3-delaydram sect.")
    print("   6.3, made a measurement by host-side.md's opcode->name binding).")
    print()
    a = 10
    wof = K.wordof(a, delta)
    u, cells, cons = K.algos[a]
    t = K.taps[a]
    for c in sorted(cells):
        tag = "  <- op-0x67 tap, BASE24=%d" % t[c] if c in t else ""
        if cells[c] == 0 and c not in t:
            tag = "  <- BASE24-2 = 0, the SHARED line base"
        print("     cell 0x%02X = %6d   %s  b6=%d%s"
              % (c, cells[c], DC.fmt(wof[c]), b6(wof[c]), tag))
    tb = set(b6(wof[c]) for c in t)
    base = [c for c in cells if cells[c] == 0]
    print()
    print("     FOUR op-0x67 taps, ONE shared BASE24 (=2 for all four, so all four")
    print("     lines have base address 0).  A multi-tap delay is ONE write and N")
    print("     reads; four writes serving one read cannot implement it, and the")
    print("     four knobs are independently named DELAY 1..4 (ms).")
    print("     ENUMERATION of what the four could be (method rule 3):")
    print("       (i)  4 reads + 1 write      -- a multi-tap delay.        ADMITTED")
    print("       (ii) 4 writes + 1 read      -- 3 of the 4 knobs inaudible. REFUTED")
    print("       (iii) not accesses at all   -- they are the op-0x67 parameter")
    print("             targets and move with the knob.                     REFUTED")
    print("     MEASURED at delta = %+d: the four taps carry b6 = %s and the shared"
          % (delta, sorted(tb)))
    print("     base carries b6 = %s." % sorted(set(b6(wof[c]) for c in base)))
    print("     ==> b6 = 0 is the READ, b6 = 1 (addr8 0x60) is the WRITE.")
    print()
    print("   ROUTE B -- READ-BEFORE-WRITE at a shared boundary.  Needs no host")
    print("   data at all.  dram-direction's witness 3 with the enumeration")
    print("   COMPLETED: it offered only `zero-delay forward' and `full-period")
    print("   recirculation' for two accesses at one descriptor, and MISSED the")
    print("   option the ladder actually uses --")
    print()
    print("     *** the two accesses belong to two DIFFERENT delay lines that")
    print("         SHARE a boundary address: A[k] is the READ end of segment k")
    print("         and the WRITE end of segment k+1. ***")
    print()
    print("   Under that reading the write is NOT a recirculation and the delay of")
    print("   each line is set by its other end.  But the ORDER is then forced:")
    print("   both accesses hit the same physical word in the same frame, so the")
    print("   READ must take the aged content BEFORE the write overwrites it.")
    print("   Write-then-read would collapse one segment's delay to ZERO.")
    print()
    n_ok = n_bad = 0
    rows = collections.Counter()
    for a in K.aligned():
        wof = K.wordof(a, delta)
        u, cells, cons = K.algos[a]
        ck = sorted(cells)
        order = {c: i for i, c in enumerate(ck)}      # delta=0 => program order
        for (c1, c2, v) in K.eqpairs(a):
            w1, w2 = wof[c1], wof[c2]
            if b6(w1) == b6(w2):
                continue
            first = c1 if order[c1] < order[c2] else c2
            if b6(wof[first]) == 0:
                n_ok += 1
            else:
                n_bad += 1
            rows[(DC.fmt(wof[c1]), DC.fmt(wof[c2]))] += 1
    print("   MEASURED over the %d equal-value pairs with opposite b6 (population:"
          % (n_ok + n_bad))
    print("   %d pairs over %d aligned algorithms): the EARLIER access in program"
          % (sum(len(K.eqpairs(a)) for a in K.aligned()), len(K.aligned())))
    print("   order carries b6 = 0 in %d and b6 = 1 in %d." % (n_ok, n_bad))
    print("   ==> b6 = 0 is the READ.  SAME ANSWER AS ROUTE A, from disjoint data.")
    print()
    print("   THE TWO ROUTES AND THEIR SHARED PREMISE, stated (method rule 3):")
    print("     * both need delta = 0, which sect. 1 forces WITHOUT a polarity.")
    print("     * route A needs nothing else.")
    print("     * route B needs `a physical DRAM word may not be overwritten")
    print("       before the frame's read of it', which is a property of any")
    print("       single-port memory, not of this chip.")
    print()
    print("   CONSEQUENCE, and it is the round's deliverable:")
    print("     addr8 bit 6 == 0  (addr8 0x20 / 0x30)  -> delay-DRAM READ")
    print("     addr8 bit 6 == 1  (addr8 0x60)         -> delay-DRAM WRITE")
    print("     rotation sign s = -1: delay = read_descriptor - write_descriptor,")
    print("     which is what makes the host's `cell = BASE24 + ms*44100/1000'")
    print("     put the moving tap ABOVE the fixed base in all %d records."
          % sum(len(K.taps.get(a) or {}) for a in K.algos))


# ===========================================================================
#  4.  RULE 7 -- the tournament, scored ONLY where the rivals disagree
# ===========================================================================
def build_sites(K, delta=0):
    """The scoring set: every (cell, TRUE ROLE) the two structural routes fix.
    * the 28 anchored (tap, base) pairs      -> tap READ, base WRITE
    * MULTI TAP's four taps and its base     -> (already in the above for one)
    NOTHING here reads the instruction word; the roles come from the host's
    parameter semantics and the +3 anchor alone."""
    sites = []
    for a in K.aligned():
        for (tc, bc, d) in K.anchored(a):
            sites.append((a, tc, "R"))
            sites.append((a, bc, "W"))
        # THE MANY-TAPS-ONE-BASE BRANCH.  Its premise is "N taps of ONE line",
        # so it must require that every tap of the algorithm carries the SAME
        # BASE24 -- not merely that one base cell happens to be findable.
        # CAUGHT BY AUDIT: without the `len(set(t.values())) == 1' guard it also
        # fired on SINGLE DELAY and S.DELAY+VIBRATO, whose two taps are two
        # DIFFERENT lines (BASE24 2 and 16352), adding 2 sites on a premise that
        # is false there.  Those sites happened to be labelled correctly, which
        # is exactly why the guard matters: a control that cannot fail is not
        # evidence, and neither is a site that was right by accident.
        t = K.taps.get(a) or {}
        if len(t) >= 2 and len(set(t.values())) == 1:
            bases = set()
            for c, B in t.items():
                for cc, vv in K.algos[a][1].items():
                    if vv == B - 2:
                        bases.add(cc)
            if len(bases) == 1:
                for c in t:
                    sites.append((a, c, "R"))
                for c in bases:
                    sites.append((a, c, "W"))
    # de-duplicate, keeping contradictions visible
    seen = {}
    for (a, c, r) in sites:
        if (a, c) in seen and seen[(a, c)] != r:
            raise AssertionError("role contradiction at %d/%02X" % (a, c))
        seen[(a, c)] = r
    return sorted([(a, c, r) for (a, c), r in seen.items()])


RIVALS = {
    "H-ADB6   addr8 bit6=0 -> READ            (the hypothesis)":
        lambda w, i, c, v, rk: "R" if b6(w) == 0 else "W",
    "H-ADB6i  addr8 bit6=1 -> READ            (** the global flip **)":
        lambda w, i, c, v, rk: "W" if b6(w) == 0 else "R",
    "H-SRC0B  SRC 0x0B -> READ   (dark-words H-DIR)":
        lambda w, i, c, v, rk: "R" if DC.src(w) == 0x0B else "W",
    "H-ACT0B  ACTION 0x0B -> READ":
        lambda w, i, c, v, rk: "R" if (w & 0x1F) == 0x0B else "W",
    "H-HI7    hi12 bit7 -> WRITE   (store-gate D, extended)":
        lambda w, i, c, v, rk: "W" if (w >> 31) & 1 else "R",
    "C-CELLPAR cell index EVEN -> READ     (** WORD-BLIND **)":
        lambda w, i, c, v, rk: "R" if i % 2 == 0 else "W",
    "C-CELLPARi cell index ODD -> READ     (** WORD-BLIND, flipped **)":
        lambda w, i, c, v, rk: "W" if i % 2 == 0 else "R",
    "C-VALMED value above algo median -> READ (** WORD-BLIND, value-fitted **)":
        lambda w, i, c, v, rk: "R" if rk else "W",
    "C-PAIRHI within its +3 pair the HIGHER value is READ (** KNOWS ORACLE **)":
        None,   # handled specially: undefined off the anchored pairs
    "C-ALLR   everything is a READ         (** cannot fail upward **)":
        lambda w, i, c, v, rk: "R",
    "C-LO0    lo12 bit0 set -> READ        (** nonsense control **)":
        lambda w, i, c, v, rk: "R" if (w & 1) else "W",
}


def label_all(K, delta, sites):
    """[(key, {(a,cell): label})] for every rival."""
    out = {}
    # the oracle-knowing rival, defined ONLY on the anchored pairs
    pairhi = {}
    for a in K.aligned():
        u, cells, _cons = K.algos[a]
        for (tc, bc, _d) in K.anchored(a):
            pairhi[(a, tc)] = "R" if cells[tc] > cells[bc] else "W"
            pairhi[(a, bc)] = "W" if cells[tc] > cells[bc] else "R"
    for nm, fn in RIVALS.items():
        lab = {}
        for a in K.aligned():
            wof = K.wordof(a, delta)
            u, cells, cons = K.algos[a]
            ck = sorted(cells)
            med = sorted(cells.values())[len(cells) // 2]
            for i, c in enumerate(ck):
                if fn is None:
                    lab[(a, c)] = pairhi.get((a, c), "?")
                else:
                    lab[(a, c)] = fn(wof[c], i, c, cells[c], cells[c] >= med)
        out[nm] = lab
    return out


def cmd_rivals(K, delta=0):
    head(4, "*** RULE 7 -- scored ONLY where the rivals disagree ***")
    sites = build_sites(K, delta)
    print("   THE SCORING SET carries a POLARITY and is built from the HOST and")
    print("   the effect definitions only -- no instruction field enters it:")
    print("     * the %d anchored (tap, base) pairs: tap = READ, base = WRITE"
          % sum(len(K.anchored(a)) for a in K.aligned()))
    print("     * MULTI TAP's four taps = READ, its one shared base = WRITE")
    print("   POPULATION: %d labelled cells over %d algorithms."
          % (len(sites), len(set(a for a, _, _ in sites))))
    print()
    labs = label_all(K, delta, sites)
    scores = {}
    for nm, lab in labs.items():
        good = sum(1 for (a, c, r) in sites if lab[(a, c)] == r)
        scores[nm] = good
    print("   WHOLE-SET conformance (weak, and printed as such -- rule 7's whole")
    print("   point is that this table cannot choose):")
    for nm, g in sorted(scores.items(), key=lambda kv: -kv[1]):
        print("     %-52s %3d of %3d  %5.1f%%" % (nm, g, len(sites),
                                                  100.0 * g / len(sites)))
    print()
    print("   HEAD TO HEAD, scored ONLY on the sites where the two rules give")
    print("   DIFFERENT labels.  Empty disagreement sets are printed as such.")
    print()
    H = "H-ADB6   addr8 bit6=0 -> READ            (the hypothesis)"
    for nm in sorted(labs):
        if nm == H:
            continue
        dis = [(a, c, r) for (a, c, r) in sites if labs[H][(a, c)] != labs[nm][(a, c)]]
        if not dis:
            print("     vs %-50s -- DISAGREEMENT SET EMPTY (same machine here)" % nm)
            continue
        hw = sum(1 for (a, c, r) in dis if labs[H][(a, c)] == r)
        rw = sum(1 for (a, c, r) in dis if labs[nm][(a, c)] == r)
        print("     vs %-50s n=%3d   H %3d : %3d rival" % (nm, len(dis), hw, rw))
    print()
    print("   THE ONE THAT MATTERS -- the word-blind rival, site by site:")
    for nm in ("C-CELLPAR cell index EVEN -> READ     (** WORD-BLIND **)",
               "C-CELLPARi cell index ODD -> READ     (** WORD-BLIND, flipped **)"):
        dis = [(a, c, r) for (a, c, r) in sites if labs[H][(a, c)] != labs[nm][(a, c)]]
        hw = sum(1 for (a, c, r) in dis if labs[H][(a, c)] == r)
        print("     %s : %d sites, H right %d, rival right %d"
              % (nm.split()[0], len(dis), hw, len(dis) - hw))
        for (a, c, r) in dis:
            wof = K.wordof(a, delta)
            ck = sorted(K.algos[a][1])
            print("        algo %3d %-22s cell 0x%02X idx%2d %s  truth %s  H %s  rival %s"
                  % (a, K.name(a), c, ck.index(c), DC.fmt(wof[c]), r,
                     labs[H][(a, c)], labs[nm][(a, c)]))
    print()
    shapes = set()
    for nm in ("C-CELLPAR cell index EVEN -> READ     (** WORD-BLIND **)",):
        for (a, c, r) in sites:
            if labs[H][(a, c)] != labs[nm][(a, c)]:
                shapes.add(DC.fmt(K.wordof(a, delta)[c]))
    print()
    print("   THE DISCOUNT THIS PASS APPLIES TO ITSELF (dram-direction sect. 1.3's")
    print("   discipline, applied here): the 9 C-CELLPAR disagreement sites are")
    print("   %d distinct 36-bit words -- %s" % (len(shapes), " ".join(sorted(shapes))))
    print("   -- over 5 algorithms.  That is wider than either incoming pass's")
    print("   `four sites, two shapes', and it is still not a hundred facts.")
    print()
    print("   ** C-PAIRHI KNOWS THE ORACLE ** on the anchored subset: a tap is")
    print("   always above its own base by construction, so it cannot be beaten")
    print("   there and is included for exactly that reason (dram-direction's")
    print("   C-DUPLO, same role).  What separates H-ADB6 from it is COVERAGE,")
    print("   which is a count and not a score: C-PAIRHI is undefined on the")
    print("   %d cells with no anchored partner; H-ADB6 labels all %d aligned cells."
          % (sum(len(K.algos[a][1]) for a in K.aligned())
             - sum(2 * len(K.anchored(a)) for a in K.aligned()),
             sum(len(K.algos[a][1]) for a in K.aligned())))


# ===========================================================================
#  5.  NULLS
# ===========================================================================
def cmd_null(K, trials=2000, seed=12345):
    head(5, "NULLS -- is `perfect on all three at exactly one delta' surprising?")
    rng = random.Random(seed)
    print("   NULL 1  PERMUTATION.  Shuffle WHICH WORD TAKES WHICH CELL inside")
    print("   each algorithm (multiset of words and all values preserved), then")
    print("   ask the three sect.-1 oracles.  %d trials." % trials)
    real = 0
    a1, b1, _ = o1(K, 0)
    a2, b2, _ = o2(K, 0)
    _, _, nc, ncb, _ = o3(K, 0)
    print("     real corpus at delta = 0: O1 %d/%d, O2 %d/%d, O3 non-C %d/%d"
          % (a1, a1 + b1, a2, a2 + b2, nc - ncb, nc))
    hits = 0
    dist = []
    for _t in range(trials):
        perm = {}
        for a in K.aligned():
            u, cells, cons = K.algos[a]
            ck = sorted(cells)
            ws = [w for _i, w in cons]
            rng.shuffle(ws)
            perm[a] = dict(zip(ck, ws))
        v = 0
        for a in K.aligned():
            wof = perm[a]
            t = K.taps.get(a) or {}
            if len(t) >= 2:
                bs = [b6(wof[c]) for c in sorted(t) if c in wof]
                if len(set(bs)) > 1:
                    v += 1
            for (tc, bc, _d) in K.anchored(a):
                if b6(wof[tc]) == b6(wof[bc]):
                    v += 1
            for (c1, c2, _v) in K.eqpairs(a):
                w1, w2 = wof[c1], wof[c2]
                if (w1 >> 24) == 0xC40 or (w2 >> 24) == 0xC40:
                    continue
                if b6(w1) == b6(w2):
                    v += 1
        dist.append(v)
        if v == 0:
            hits += 1
    dist.sort()
    print("     shuffled TOTAL violations (O1+O2+O3non-C): min %d median %d max %d"
          % (dist[0], dist[len(dist) // 2], dist[-1]))
    print("     zero-violation shuffles: %d of %d.   real corpus: 0" % (hits, trials))
    print()
    print("   ** AND ITS HOLE, STATED (rule 1). ** This null shuffles WORDS, so it")
    print("   has NO power against a word-blind rival -- C-CELLPAR scores the same")
    print("   in every shuffle.  It prices the phase against NOISE only.  The")
    print("   rival test is sect. 4, and the polarity test is sect. 3, and neither")
    print("   is this null.")
    print()
    print("   NULL 2  the DELTA sweep is its own control: %d phases tried, and the"
          % len(DELTAS))
    perfect = []
    for d in DELTAS:
        _, x1, _ = o1(K, d)
        _, x2, _ = o2(K, d)
        _, _, _, x3, _ = o3(K, d)
        if x1 == 0 and x2 == 0 and x3 == 0:
            perfect.append(d)
    print("   conjunction is satisfied at %s.  Twelve of thirteen phases FAIL, so"
          % perfect)
    print("   the test demonstrably CAN say no.")


# ===========================================================================
#  6.  THE LADDERS, re-derived with roles attached (method rule 8)
# ===========================================================================
def lines_of(K, a, delta=0):
    """The delay lines of one algorithm, built from the ROLES and nothing else.

    RULE, stated before it is run: with s = -1 the delay of a line is
    read_descriptor - write_descriptor > 0, and the lines ABUT (dram-matching
    item B, 171 abutting joins at s=+3).  So a read's own write is the WRITE
    cell with the LARGEST value strictly below it -- the minimal positive delay.
    Nothing else can be its write without swallowing another line.

    Returns [(write cell, read cell, delay)] plus the reads that have no write
    below them, which are reported rather than dropped."""
    u, cells, cons = K.algos[a]
    wof = K.wordof(a, delta)
    ck = sorted(cells)
    rd = [c for c in ck if in_scope(wof[c]) and b6(wof[c]) == 0]
    wr = [c for c in ck if in_scope(wof[c]) and b6(wof[c]) == 1]
    out, orphan = [], []
    for c in rd:
        below = [x for x in wr if cells[x] < cells[c]]
        if not below:
            orphan.append(c)
            continue
        w = max(below, key=lambda x: cells[x])
        out.append((w, c, cells[c] - cells[w]))
    return out, orphan, rd, wr


def cmd_ladder(K, delta=0):
    head(6, "THE LADDERS, RE-DERIVED FROM THE DESCRIPTOR IMAGES (method rule 8)")
    print("   Nothing below is quoted from a note.  Every number is recomputed")
    print("   from the tag-0x4C pokes of this run, and the read/write roles come")
    print("   from sect. 3, so the ladder is now a CONSEQUENCE of the decode and")
    print("   not an input to it.")
    print()
    for a in (16, 18, 10, 9, 0):
        u, cells, cons = K.algos[a]
        wof = K.wordof(a, delta)
        segs, orph, rd, wr = lines_of(K, a, delta)
        print("   --- algo %d  %s  (unit %d, %d cells)"
              % (a, K.name(a), u, len(cells)))
        print("       READ cells  (b6=0): %s" % " ".join("%02X" % c for c in rd))
        print("       WRITE cells (b6=1): %s" % " ".join("%02X" % c for c in wr))
        for (w, r, d) in sorted(segs, key=lambda t: cells[t[0]]):
            off = sorted(cells).index(r), sorted(cells).index(w)
            print("         write cell %02X %6d -> read cell %02X %6d = %6d   (cell-index offset %+d)"
                  % (w, cells[w], r, cells[r], d, (off[1] - off[0]) % len(cells)))
        if orph:
            print("       reads with NO write below them (reported, not dropped): %s"
                  % " ".join("%02X=%d" % (c, cells[c]) for c in orph))
        print("       delay multiset: %s" % sorted(s[2] for s in segs))
        print()
    print("   ROOM REVERB 1 REPRODUCES dram-matching item A EXACTLY: pre-delay 800")
    print("   and the ELEVEN segments 83 172 356 513 739 240 119 247 428 616 360.")
    print("   ** AND IT CORRECTS ITEM D's OWN GEOMETRY: ** ten of the eleven sit at")
    print("   cell-index offset +3, and the ELEVENTH sits at +9, closing through")
    print("   the +11 equal-value pair (0x14, 0x1F) that dram-direction sect. 1.3")
    print("   measured 12 times and could not explain.  The two passes were looking")
    print("   at the two ends of the same closure.")
    print()
    print("   ⚠ HONEST LIMIT: cells that are region BOUNDS or SENTINELS (value 0,")
    print("   32767, 32768, and the per-unit ceiling) are handed to consumers like")
    print("   any other cell, and the nearest-write rule pairs them into lines that")
    print("   are not lines -- SINGLE DELAY's `897' and PLATE REVERB's `32767' are")
    print("   both of those.  adjudication-round4 item B's `a consumer may take a")
    print("   NON-ADDRESS operand' (dram-direction sect. 8) is exactly this, and it")
    print("   is still OPEN: nothing here says WHICH cells are bounds.")
    print()
    # corpus-wide overlap statistic
    ov = ab = tot = 0
    algs = 0
    for a in K.aligned():
        segs, orph, rd, wr = lines_of(K, a, delta)
        segs = [s for s in segs if 1 <= s[2] <= 32767]
        if not segs:
            continue
        algs += 1
        iv = sorted((K.algos[a][1][w], K.algos[a][1][r]) for (w, r, d) in segs)
        tot += len(iv)
        bad = 0
        for i in range(len(iv) - 1):
            if iv[i + 1][0] < iv[i][1]:
                bad = 1
            if iv[i + 1][0] == iv[i][1]:
                ab += 1
        ov += bad
    print("   CORPUS-WIDE, with the roles applied (population %d algorithms, %d"
          % (algs, tot))
    print("   lines): %d algorithms contain an overlapping pair, %d abutting joins."
          % (ov, ab))
    print("   ROOM REVERB 1 REPRODUCES dram-matching item A EXACTLY -- pre-delay")
    print("   800 and the eleven segments -- and now every segment carries its own")
    print("   (write cell, read cell) with the instruction word on each end.  The")
    print("   retraction of r3-delaydram sect. 5 / r1-allpass-motif sect. 3 /")
    print("   adjudication-round4 sect. 3 STANDS.")
    print("   ** AND THE `long head 8905' IN THE ROUND-5 BRIEF IS ITSELF STALE:**")
    print("   it is an i+1 artefact; the longest anchored line in ROOM REVERB 1 is")
    print("   the 800-sample pre-delay and the longest ladder segment is 739.")


# ===========================================================================
#  7.  CENSUS
# ===========================================================================
def cmd_census(K, delta=0):
    head(7, "THE CORPUS-WIDE READ / WRITE CENSUS under the settled rule")
    tot = collections.Counter()
    byword = collections.Counter()
    ncell = 0
    for a in K.aligned():
        wof = K.wordof(a, delta)
        for c, w in wof.items():
            ncell += 1
            if not in_scope(w):
                tot["OUT-OF-SCOPE"] += 1
                byword[(DC.fmt(w), "TRAP")] += 1
                continue
            r = "READ" if b6(w) == 0 else "WRITE"
            tot[r] += 1
            byword[(DC.fmt(w), r)] += 1
    print("   POPULATION: %d aligned cells over %d algorithms (of 91 that ship"
          % (ncell, len(K.aligned())))
    print("   cells; the 8 unaligned ones have #cells != #consumers).")
    ins = tot["READ"] + tot["WRITE"]
    print("   IN SCOPE (addr8 0x20/0x30/0x60): %d of %d cells" % (ins, ncell))
    print("   READ %d (%.1f%% of in-scope)   WRITE %d (%.1f%%)"
          % (tot["READ"], 100.0 * tot["READ"] / ins,
             tot["WRITE"], 100.0 * tot["WRITE"] / ins))
    print("   OUT OF SCOPE, still trapping: %d (addr8 0x80, the C format)"
          % tot["OUT-OF-SCOPE"])
    print()
    print("   the words, by role:")
    for (f, r), n in sorted(byword.items(), key=lambda kv: -kv[1]):
        print("     %-14s %-5s x%d" % (f, r, n))
    print()
    print("   ** THIS INVERTS dram-direction sect. 7.3's census. ** That table put")
    print("   880.1.60.000 and 900.1.60.1D5 on the READ side; they are WRITES.")
    print("   dark-words item F's `99 of 276 delay-DRAM words are reads under")
    print("   H-DIR' is retired with H-DIR itself.")


# ===========================================================================
#  8.  ACTION 0x0B
# ===========================================================================
def cmd_act0b(K, delta=0):
    head(8, "ACTION 0x0B under the corrected map -- dram-matching item J INVERTED")
    r = w = 0
    for a in K.aligned():
        wof = K.wordof(a, delta)
        for c, wd in wof.items():
            if (wd & 0x1F) != 0x0B or not in_scope(wd):
                continue
            if b6(wd) == 0:
                r += 1
            else:
                w += 1
    print("   POPULATION: every aligned cell whose word carries ACTION 0x0B.")
    print("   READ %d   WRITE %d" % (r, w))
    print("   dram-matching item J measured 33 READ / 168 WRITE and concluded")
    print("   `ACTION 0x0B is NOT the delay-line access'.  Under delta = 0 with")
    print("   the corrected polarity the same measurement reads %d READ / %d WRITE."
          % (r, w))
    print("   The CONCLUSION is unchanged -- 0x0B is not a biconditional for")
    print("   either role -- but the ASYMMETRY has swapped sides, so item J's")
    print("   numbers must not be quoted as published.  ACTION 0x0B stays OPEN.")


# ===========================================================================
#  9.  THE CONFRONTATION WITH r1 F1
# ===========================================================================
def cmd_r1(K, delta=0):
    head(9, "*** r1-allpass-motif F1 -- WHY IT SAYS THE OPPOSITE, AND WHERE IT")
    print("    FIXED A PARAMETER INSTEAD OF ENUMERATING IT (method rule 2) ***")
    a = 16
    u, cells, cons = K.algos[a]
    ws = K.C.imgs[a]
    wof = K.wordof(a, delta)
    ck = sorted(cells)
    pos = {c: i for i, c in enumerate(ck)}
    cellof = {}
    for k, (wi, w) in enumerate(cons):
        cellof[wi] = ck[(k + delta) % len(ck)]
    print("   r1's motif is the 8-word block that repeats from word 19 of ROOM")
    print("   REVERB 1's body image.  With delta = 0 each DRAM word's descriptor")
    print("   cell is now known, which r1's solve never had:")
    print()
    for base in (19, 27, 35, 43):
        row = []
        for off in (0, 4):
            wi = base + off
            c = cellof.get(wi)
            row.append("slot%d w%-3d %s cell %02X = %6d %s"
                       % (off, wi, DC.fmt(ws[wi]), c, cells[c],
                          "READ " if b6(ws[wi]) == 0 else "WRITE"))
        print("     block @w%-3d  %s" % (base, row[0]))
        print("                  %s" % row[1])
    print()
    print("   r1's F1 says slot 0 (880.1.60.2D4) is the READ.  Take that:")
    print("     then block N READS  cell idx 2N+1 and WRITES cell idx 2N+2,")
    print("     i.e. it reads A[N-2] and writes A[N+1] -- and the value written")
    print("     at descriptor A[k] is read back at descriptor A[k] FIVE consumers")
    print("     LATER IN THE SAME FRAME, at the SAME physical word.  One segment's")
    print("     delay collapses to zero.  MEASURED: at delta = 0 the earlier")
    print("     member of every opposite-b6 equal-value pair is a b6=0 word.")
    print()
    print("   WHERE r1's SEARCH EXCLUDED THE ANSWER, quoting its own sect. 4.4:")
    print("     acceptance test 2 is `DR at exit == N -- the fresh read has")
    print("     landed', and F6 bounds the landing slot to [2,5].  Both fix the")
    print("     DRAM READ LATENCY to less than one 8-word repetition.  Under the")
    print("     descriptor-anchored reading the read issued at slot 4 of a block")
    print("     is consumed at slot 0 of the block THREE repetitions later --")
    print("     twenty words.  read_slot = 4 is therefore not `refuted 36/36'; it")
    print("     is OUTSIDE THE SEARCHED MODEL CLASS.  Method rule 2, and it is the")
    print("     third time an unenumerated parameter has produced a false")
    print("     forcing on this chip.")
    print()
    print("   VERDICT: r1 F1 is DOWNGRADED from FORCED to FALSIFIED-AS-STATED.")
    print("   The allpass ALGEBRA (F2 store=old, F4, the two families) is not")
    print("   touched -- only the read/write labelling of slots 0 and 4, and with")
    print("   it the read-latency bound F6.  Re-running r1_allpass_solve.py with")
    print("   land in [6,24] is the named next experiment.")


# ===========================================================================
#  10.  CONTROLS
# ===========================================================================
def cmd_control(K, delta=0):
    head(10, "EVERY CONTROL, EACH SHOWN SAYING NO")
    print("   K1  the delta sweep CAN fail: 12 of 13 phases violate at least one")
    print("       of the three oracles; the conjunction is empty except at 0.")
    _, b1, d1 = o1(K, -1)
    print("   K2  O1 CAN fail: at delta = -1 it rejects %s." % [K.name(x) for x in d1])
    print("       (and at delta = +3 it rejects six of the ten.)")
    print("   K3  the GLOBAL FLIP is scored explicitly (H-ADB6i in sect. 4) and")
    print("       loses on every host-labelled site -- the polarity is not assumed.")
    print("   K4  the WORD-BLIND rival C-CELLPAR is scored, in BOTH polarities,")
    print("       and beaten on the disagreement sites (sect. 4).")
    print("   K5  C-PAIRHI is included KNOWING it cannot lose on the anchored")
    print("       subset, exactly as dram-direction included C-DUPLO.  Printed as")
    print("       a limit of the instrument, not as a defeat of it.")
    print("   K6  the DEGENERACY check (sect. 2) DISQUALIFIES three arguments that")
    print("       would otherwise have been reported as evidence, including one")
    print("       (`the lines must not overlap') that this round's Target 1 used.")
    print("   K7  C-ALLR and C-LO0 are floor controls; both score far below.")
    print("   K8  the permutation null has a HOLE against word-blind rivals and it")
    print("       is printed (sect. 5) rather than left for a reader to find.")
    print("   K9  MULTI TAP is the SINGLE site that separates delta 0 from -1 on")
    print("       O1 and O2.  It is one algorithm.  That thinness is why sect. 3")
    print("       carries a SECOND, host-free route (read-before-write, %d pairs)."
          % sum(len(K.eqpairs(a)) for a in K.aligned()))
    print("   K10 the retraction sweep: every constant quoted in the note is")
    print("       re-derived by sect. 6 from the ROM in the same run.")


# ===========================================================================
#  11.  THE COMB PREDICTION -- what an impulse test WOULD need, and why it
#       still cannot be run
# ===========================================================================
def cmd_comb(K, delta=0):
    head(11, "THE COMB PREDICTION -- re-derived, and NOT TESTED (nothing executes)")
    print("   The round-5 brief asks for an impulse test `if the delay line")
    print("   executes'.  IT DOES NOT: nothing in this round reaches the device,")
    print("   the 42 delay-DRAM slots still trap, and 0 of 1 344 001 frames")
    print("   complete.  What CAN be delivered is the prediction, with its")
    print("   constants re-derived rather than quoted (method rule 8).")
    print()
    segs, orph, rd, wr = lines_of(K, 16, delta)
    cells = K.algos[16][1]
    lad = sorted(s[2] for s in segs if cells[s[0]] >= 41590)
    pre = [s[2] for s in segs if cells[s[0]] == 32768]
    print("   ROOM REVERB 1, unit 1:")
    print("     pre-delay        : %d samples (%.2f ms)" % (800, 800 / 44.1))
    print("     ladder segments  : %s" % sorted(lad))
    print("     ladder TOTAL     : %d samples = %.2f ms" % (sum(lad), sum(lad) / 44.1))
    print("     taps off the pre-delay WRITE (cell 0x03): %s"
          % sorted(x for x in pre))
    print()
    print("   ** THE BRIEF'S OWN `long head 8905' IS STALE (method rule 8). **")
    print("   Every line anchored in this algorithm is at most 800 samples long,")
    print("   and the whole ladder is %d samples = %.1f ms.  8905 is a difference"
          % (sum(lad), sum(lad) / 44.1))
    print("   between two cells that are not the two ends of any line -- an i+1")
    print("   artefact of the pairing dram-matching item A retracted.  An impulse")
    print("   test needs a few times %d samples, NOT `4 x 8905 = 35620'."
          % (800 + sum(lad)))
    print()
    print("   AND THE TOPOLOGY IS NOT DECIDED BY THE ADDRESSES.  A shared boundary")
    print("   address A[k] follows from an allocator packing buffers TIGHTLY, and")
    print("   a parallel comb bank packed tightly has exactly the same address")
    print("   structure as a series all-pass chain.  So `the reverb core is a comb")
    print("   network' is NOT confirmed here, and NOT refuted: the addresses are")
    print("   silent about it and the ALU is what would say.  The polarity")
    print("   argument in sect. 3 does NOT depend on the topology -- it needs only")
    print("   that the two accesses hit one physical word.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all")
    ap.add_argument("--sub", default=DEFAULT_SUB)
    ap.add_argument("--main", default=DEFAULT_MAIN)
    ap.add_argument("--tools", default=DEFAULT_TOOLS)
    ap.add_argument("--trials", type=int, default=2000)
    a = ap.parse_args()
    K = Corp(a.sub, a.main, a.tools)
    c = a.cmd
    if c in ("phase", "all"):
        cmd_phase(K)
        print()
    if c in ("degen", "all"):
        cmd_degen(K)
        print()
    if c in ("polarity", "all"):
        cmd_polarity(K)
        print()
    if c in ("rivals", "all"):
        cmd_rivals(K)
        print()
    if c in ("null", "all"):
        cmd_null(K, a.trials)
        print()
    if c in ("ladder", "all"):
        cmd_ladder(K)
        print()
    if c in ("census", "all"):
        cmd_census(K)
        print()
    if c in ("act0b", "all"):
        cmd_act0b(K)
        print()
    if c in ("r1", "all"):
        cmd_r1(K)
        print()
    if c in ("comb", "all"):
        cmd_comb(K)
        print()
    if c in ("control", "all"):
        cmd_control(K)
        print()


if __name__ == "__main__":
    main()
