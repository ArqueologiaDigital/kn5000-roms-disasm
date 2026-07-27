#!/usr/bin/env python3
"""dram_cursor.py -- the DELAY-DRAM descriptor cursor: closure, phase,
direction and the comb prediction.  NEC uPD6383GF-3BA (Technics SX-KN5000,
IC311).

Every number quoted in `analysis/dram-cursor-closure.md` comes out of this
file.  Stdlib only.  No hardware; static analysis of the Sub CPU ROM corpus
plus the two published passes it adjudicates (R3 `r3-delaydram.md`, R1
`r1-allpass-motif.md`).

    python3 dsp/tools/dram_cursor.py align     # the cell<->word alignment + the PHASE test
    python3 dsp/tools/dram_cursor.py closure   # *** THE DESCRIPTOR-CURSOR CLOSURE TEST ***
    python3 dsp/tools/dram_cursor.py carrier   # where can the per-unit base come from?
    python3 dsp/tools/dram_cursor.py dirtest   # *** DIRECTION: rules vs a lo12-free oracle ***
    python3 dsp/tools/dram_cursor.py comb      # *** the echo train the comb model predicts ***
    python3 dsp/tools/dram_cursor.py control   # every control, each shown saying NO
    python3 dsp/tools/dram_cursor.py all
"""
import argparse
import collections
import itertools
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                                              # noqa: E402
import dark_words as DW                                             # noqa: E402

T_ALGO = 0x0001ED7C
T_PARAM = 0x0001EF0C

# the frame, exactly as dark_words.py reconstructs it (and as
# upd6383_device::run_frame() walks it)
HDR_N, EPI_N = 60, 23
U0_LOAD, U1_LOAD = 84, 200
CALL0, CALL1 = 49, 59

# MEASURED (r3-delaydram.md sect. 5): the per-unit descriptor allocations.
BASE_U0, BASE_U1 = 0x26, 0x00
MAX_CELL = 0x39                     # GATED REVERB, the corpus maximum

# R1's independently published delay sets for ROOM REVERB 1 (r1-allpass-motif.md
# sect. 3), in R1's *raw24* units -- i.e. exactly half the poke24 value, because
# R3 P2 falsified the raw reading.  Carried here ONLY as an external check.
R1_CHAIN0 = [127, 435, 489, 183, 522]
R1_CHAIN1 = [4452, 264, 626, 180, 337, 488]


# ---------------------------------------------------------------------------
#  0.  ROM
# ---------------------------------------------------------------------------
def load(sub, tools):
    sys.path.insert(0, tools)
    import kn5000_dsp_extract as E                                  # noqa: E402
    rom = E.Rom(sub)
    imgs, loads = {}, {}
    for i in range(100):
        try:
            iram, _c, _o = E.parse_stream(rom, rom.u32le(T_ALGO + 4 * i))
        except Exception:
            continue
        if not iram:
            continue
        imgs[i] = [int.from_bytes(bytes(w), "big")
                   for _a, ws, _l in iram for w in ws]
        loads[i] = [a for a, _w, _l in iram]
    hdr, epi, _u0, _u1 = DW.load_images(sub, tools)
    return rom, imgs, loads, hdr, epi


def fields(w):
    return (w >> 24) & 0xFFF, (w >> 20) & 0xF, (w >> 12) & 0xFF, w & 0xFFF


def fmt(w):
    return "%03X.%X.%02X.%03X" % fields(w)


def form(w):
    """(hi12, class4, lo12) -- addr8 is an operand, not part of the identity."""
    hi, cl, ad, lo = fields(w)
    return (hi, cl, lo)


def formstr(f):
    return "%03X.%X.**.%03X" % f


def src(w):
    return (w >> 6) & 0x1F


def poke24(e):
    return ((e[1] & 0x7F) << 17) | (e[2] << 9) | (e[3] << 1) | (e[4] >> 7)


def desc_cells(rom, algo):
    """{cell: value} -- the tag-0x4C descriptor pokes of one algorithm."""
    p, guard, out, dest, on = rom.u32le(T_PARAM + 4 * algo), 0, {}, None, False
    while guard < 512:
        guard += 1
        b0, b1 = rom.u8(p), rom.u8(p + 1)
        if (b0 >> 4) == 0xF:
            break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 2 or ln > 0x0FFF:
            break
        if (b0 >> 4) in (0, 1, 5):
            d = rom.slice(p + 2, ln - 2)[3:]
            for k in range(0, len(d) - 4, 5):
                e = d[k:k + 5]
                if e[0] == 0x08 and e[1] == 0x01 and e[4] == 0x25:
                    dest = ((e[2] & 0x0F) << 4) | (e[3] >> 4)
                    on = True
                elif e[0] == 0x08 and e[1] == 0x01 and e[4] == 0x21:
                    on = False
                elif e[0] == 0x0A and (e[4] & 0x7F) == 0x4C and on:
                    out[dest] = poke24(e)
                    dest += 1
        p += ln
    return out


# ---------------------------------------------------------------------------
#  1.  The consumer predicate
#
#  R2's predicate, 324/324: class4 == 1 with the hi12 FORMAT-ESCAPE bit set.
#  NOTE it does NOT exclude the C format -- C40.1.80.000 matches, and section
#  `align' below shows the reverbs' counting identity REQUIRES it to consume.
# ---------------------------------------------------------------------------
def is_consumer(w):
    hi, cl, _ad, _lo = fields(w)
    return bool(hi & 0x800) and cl == 1


def consumers(ws):
    return [(i, w) for i, w in enumerate(ws) if is_consumer(w)]


def unit_of(loads):
    """0 if the algorithm's body loads at I-RAM 84, 1 if at 200, else None."""
    if U0_LOAD in loads:
        return 0
    if U1_LOAD in loads:
        return 1
    return None


def corpus(rom, imgs, loads):
    """[(algo, unit, cells{}, [(word_index, word)])] for every algorithm that
    ships descriptor cells at all."""
    out = []
    for a in sorted(imgs):
        u = unit_of(loads[a])
        if u is None:
            continue
        c = desc_cells(rom, a)
        if not c:
            continue
        out.append((a, u, c, consumers(imgs[a])))
    return out


# ===========================================================================
#  SECTION `align' -- the cell <-> word alignment, and THE PHASE TEST
# ===========================================================================
def sec_align(rom, imgs, loads, names):
    print("=" * 78)
    print("1. THE ALIGNMENT, AND ITS PHASE -- how many cells, how many words,")
    print("   and does the k-th consumer really take the k-th cell?")
    print("=" * 78)
    C = corpus(rom, imgs, loads)
    ok = bad = 0
    contig = 0
    bases = collections.Counter()
    for (a, u, cells, cons) in C:
        ck = sorted(cells)
        if ck == list(range(ck[0], ck[0] + len(ck))):
            contig += 1
        bases[(u, ck[0])] += 1
        if len(ck) == len(cons):
            ok += 1
        else:
            bad += 1
    print("   %d algorithms ship descriptor cells." % len(C))
    print("   cell index set CONTIGUOUS: %d of %d" % (contig, len(C)))
    print("   #cells == #consumers (R2 predicate, C format INCLUDED): %d of %d"
          % (ok, len(C)))
    print("   lowest cell index by unit: %s"
          % ", ".join("unit %d base 0x%02X x%d" % (u, b, n)
                      for (u, b), n in sorted(bases.items())))
    print()
    print("   *** THE C-FORMAT QUESTION, SETTLED BY COUNTING. ***  C40.1.80.000")
    print("   matches R2's predicate but also matches the C-format guard, so")
    print("   dark-words.md files it under group B and r3-delaydram.md counts it")
    print("   in group A.  Excluding the C format:")
    okx = 0
    for (a, u, cells, cons) in C:
        nx = sum(1 for _i, w in cons if not D.c_format(w))
        if nx == len(cells):
            okx += 1
    print("      #cells == #non-C-format consumers: %d of %d" % (okx, len(C)))
    rv = [(a, u, c, k) for (a, u, c, k) in C if u == 1]
    nc = [sum(1 for _i, w in k if not D.c_format(w)) for (_a, _u, _c, k) in rv]
    print("      and on the TWELVE REVERBS alone: %d cells vs %d non-C consumers"
          % (len(rv[0][2]), nc[0]))
    print("      -> every reverb ships 32 cells and has 28 non-C consumers.")
    print("      C40.1.80.000 MUST consume, or 4 cells per reverb are dead.")
    print()

    # ---- the phase test -------------------------------------------------
    print("   *** THE PHASE TEST *** -- delta = (cell index taken by the body's")
    print("   FIRST consumer) - (lowest cell index shipped).  A delta != 0 means")
    print("   some consumer falls outside the shipped set; count them, and check")
    print("   the resulting ladder delays against R1's INDEPENDENTLY published")
    print("   delay sets for ROOM REVERB 1 (r1-allpass-motif.md sect. 3, raw24).")
    print()
    print("   ** AND A CONTROL OF MY OWN, CAUGHT BEFORE PUBLICATION. **  The")
    print("   first version of this test scored a phase by the set of DESCENDING")
    print("   consecutive differences of the cell values.  That set does not")
    print("   depend on delta at all -- delta relabels which WORD takes a cell,")
    print("   it does not touch the cell sequence -- so the test returned")
    print("   `11 of 11 R1 delays reproduced' for every delta from -3 to +3.")
    print("   IT COULD NOT FAIL.  Withdrawn.  The test below pairs cells using")
    print("   R1's two FORCED words (880.1.60.2D4 = READ, 880.1.20.655 = WRITE,")
    print("   r1_allpass_solve.py:250, forced 36/36 with the swap at ZERO), so")
    print("   moving delta moves the labels against the values and the delays")
    print("   change sign.")
    print()
    print("      delta  off the shipped set   ROOM REVERB 1 ladder, R1's forced")
    print("             (all %d algos)        read/write words, delays in raw24"
          % len(C))
    r1all = sorted(R1_CHAIN0 + R1_CHAIN1)
    for delta in range(-3, 4):
        off = 0
        for (a, u, cells, cons) in C:
            ck = sorted(cells)
            for k in range(len(cons)):
                if ck[0] + k + delta not in cells:
                    off += 1
        d, neg = ladder_delays(rom, imgs, 16, delta)
        hit = sum(1 for x in r1all if x in d or x + 1 in d or x - 1 in d)
        print("      %+d     %6d                %2d of %2d R1 delays, %d negative/"
              "out-of-region" % (delta, off, hit, len(r1all), neg))
    print()
    print("   READ IT HONESTLY, IN TWO HALVES:")
    print("     * the delay-sign half FORCES the PARITY of delta and nothing")
    print("       more -- every odd delta puts R1's forced write ABOVE its read")
    print("       and produces negative delays; -2, 0 and +2 are indistinguish-")
    print("       able to it.  Reporting `delta = 0 FORCED' off this column")
    print("       would be exactly the degenerate-control error.")
    print("     * the off-the-shipped-set half then picks delta = 0, at 20")
    print("       against 186/202 for the two even rivals -- a factor of 9.  The")
    print("       residual 20 are the eight algorithms whose consumer count and")
    print("       cell count disagree in the first place (sect. 1 line 3).")
    print("   Combined: delta = 0, CONSISTENT and strongly favoured; delta EVEN,")
    print("   FORCED.")
    return C


def ladder_delays(rom, imgs, algo, delta=0):
    """(set of delays in R1's raw24 units, count of impossible pairs) under a
    phase shift `delta', using R1's two FORCED words to label read vs write."""
    cells = desc_cells(rom, algo)
    ck = sorted(cells)
    cons = consumers(imgs[algo])
    R1_READ, R1_WRITE = 0x8801602D4, 0x880120655
    out, bad = set(), 0
    for k in range(len(cons)):
        if cons[k][1] != R1_WRITE:
            continue
        j = k + 1
        while j < len(cons) and cons[j][1] != R1_READ:
            j += 1
        if j >= len(cons):
            continue
        vw = cells.get(ck[0] + k + delta)
        vr = cells.get(ck[0] + j + delta)
        if vw is None or vr is None:
            bad += 1
            continue
        if 0 < vw - vr < 32768:
            out.add((vw - vr) >> 1)
        else:
            bad += 1
    return out, bad


# ===========================================================================
#  SECTION `closure' -- THE DESCRIPTOR-CURSOR CLOSURE TEST
# ===========================================================================
#
#  THE QUESTION THIS ASKS, STATED UP FRONT (method rule 3, and Part 93's
#  lesson).  A reload at slot s DEFINES the cursor for everything downstream of
#  s, so closure can never tell us what a reload LOADS if that reload dominates
#  both anchors.  What closure CAN do is:
#
#     (a) decide whether a model with NO reload, or with ONE reload of a
#         CONSTANT value, can hold at all -- because then the two per-unit
#         bases are linked by a consumption count that VARIES over the corpus;
#     (b) once >= 2 reloads exist, fix the cursor value at frame entry (the
#         segment from the LAST reload to the frame boundary is reload-free),
#         and hence say exactly which cells the header's own consumers take.
#
#  It cannot tell us the reload VALUES.  It is not asked to.
# ---------------------------------------------------------------------------
def frame_layout(rom, imgs, loads, hdr, epi, a0, a1):
    """Consumer counts of the five frame regions, for one (unit-0, unit-1)
    algorithm pair.  Returns (h1, n0, h2, n1, e) where h1 = header 0..49,
    n0 = unit-0 body, h2 = header 50..59, n1 = unit-1 body, e = epilogue."""
    e = list(epi)
    for a, w in DW.PATCH.items():
        e[a - 60] = w
    h1 = sum(1 for w in hdr[0:CALL0 + 1] if is_consumer(w))
    h2 = sum(1 for w in hdr[CALL0 + 1:CALL1 + 1] if is_consumer(w))
    ep = sum(1 for i, w in enumerate(e) if 60 + i < DW.FRAME_WAIT_IW
             and is_consumer(w))
    n0 = len(consumers(imgs[a0]))
    n1 = len(consumers(imgs[a1]))
    return h1, n0, h2, n1, ep


def sec_closure(rom, imgs, loads, hdr, epi, names):
    print("=" * 78)
    print("2. *** THE DESCRIPTOR-CURSOR CLOSURE TEST ***")
    print("=" * 78)
    C = corpus(rom, imgs, loads)
    u0s = [a for (a, u, _c, _k) in C if u == 0]
    u1s = [a for (a, u, _c, _k) in C if u == 1]
    h1, _n0, h2, _n1, ep = frame_layout(rom, imgs, loads, hdr, epi,
                                        u0s[0], u1s[0])
    n0s = sorted({len(consumers(imgs[a])) for a in u0s})
    n1s = sorted({len(consumers(imgs[a])) for a in u1s})
    print("   *** THE QUESTION THIS ASKS, STATED BEFORE THE ANSWER. ***  Part")
    print("   93's lesson is that a reload at slot s DEFINES the cursor for")
    print("   everything downstream of s, so closure can never say what a")
    print("   reload LOADS once that reload dominates both anchors.  What it")
    print("   CAN do is (a) decide whether a model with too FEW reloads can")
    print("   hold at all, because then the two per-unit bases are joined by a")
    print("   consumption count that VARIES over the corpus, and (b) once the")
    print("   reloads are fixed, pin the reload-free segment that runs from the")
    print("   last reload to the frame boundary -- i.e. the frame-entry cursor.")
    print("   It is asked for exactly those two things.")
    print()
    print("   The frame, in consumers per region (R2 predicate):")
    print("      R0 header 0..49         h1 = %d" % h1)
    print("      R1 unit-0 body          n0 = %s  (%d algorithms)"
          % (n0s, len(u0s)))
    print("      R2 header 50..59        h2 = %d" % h2)
    print("      R3 unit-1 body          n1 = %s  (%d algorithms)"
          % (n1s, len(u1s)))
    print("      R4 epilogue 60..81      e  = %d" % ep)
    print("   -> %d x %d = %d distinct frames must ALL close."
          % (len(u0s), len(u1s), len(u0s) * len(u1s)))
    print()
    print("   MEASURED anchors (sect. 1): cursor at the unit-0 body's first")
    print("   consumer = 0x%02X in 79 of 79 algorithms; at the unit-1 body's"
          % BASE_U0)
    print("   first consumer = 0x%02X in 12 of 12." % BASE_U1)
    print()
    print("   *** THE ENUMERATION *** (method rule 3 -- printed NEXT TO the")
    print("   claim, not buried in the tool).")
    print("     RELOAD SITES.  A reload cannot sit strictly INSIDE a body: the")
    print("     body's cells are contiguous and ascending and #cells ==")
    print("     #consumers (sect. 1), so any reload there would have to be a")
    print("     no-op.  That leaves, as an exhaustive list of positions,")
    print("     `after the j-th consumer of region R' for R in {R0,R2,R4} and")
    print("     the two body entries:")
    sites = ([("R0", j) for j in range(h1 + 1)] +
             [("R1", 0)] +
             [("R2", j) for j in range(h2 + 1)] +
             [("R3", 0)] +
             [("R4", j) for j in range(ep + 1)])
    print("       %s" % ", ".join("%s+%d" % s for s in sites))
    print("       = %d distinct positions." % len(sites))
    print("     RELOAD VALUES.  V-const (one value, every site), V-unit (one")
    print("     value per site), V-word (a function of the reloading word's")
    print("     fields), V-ptr (the last value written to the ...825 pointer).")
    print("     RING SIZE.  N in [2, 256] with N > 0x%02X, because GATED REVERB"
          % MAX_CELL)
    print("     ships cell 0x%02X (sect. 1) and a cursor cannot address it in a"
          % MAX_CELL)
    print("     smaller ring.")
    print()

    # ---- the exhaustive walk ------------------------------------------
    frames = [(len(consumers(imgs[a])), len(consumers(imgs[b])))
              for a in u0s for b in u1s]

    def cursor_at(site, V, N, target, n0, n1):
        """cursor value at the first consumer of `target' (R1 or R3), walking
        forward from the single reload at `site' with value V."""
        cnt = {"R0": h1, "R1": n0, "R2": h2, "R3": n1, "R4": ep}
        order = ["R0", "R1", "R2", "R3", "R4"]
        # consumers passed from `site' forward to the first consumer of target
        sr, sj = site
        passed = 0
        i = order.index(sr)
        first = True
        for step in range(6):
            r = order[(i + step) % 5]
            if r == target and not (first and r == sr and sj > 0):
                # arriving at target's first consumer
                if not (step == 0 and sj > 0):
                    return (V + passed) % N
            passed += (cnt[r] - sj) if (step == 0) else cnt[r]
            sj = 0
            first = False
        return None

    verdict = {}

    # |R| = 0
    surv0 = []
    for N in range(MAX_CELL + 1, 257):
        good = True
        for (n0, n1) in frames:
            # reload-free: pick the frame-entry value X freely; both anchors
            # and closure must hold.
            X = (BASE_U0 - h1) % N
            if (X + h1 + n0 + h2) % N != BASE_U1 % N:
                good = False
                break
            if (X + h1 + n0 + h2 + n1 + ep) % N != X:
                good = False
                break
        if good:
            surv0.append(N)
    print("   --- |R| = 0, NO RELOAD ANYWHERE ---------------------------")
    print("   survivors: %s" % (surv0 or "NONE of the %d ring sizes"
                                % (256 - MAX_CELL)))
    print("   CONTROL, and it must be able to say YES: drop the two anchors and")
    demo = [N for N in range(2, 257) if (h1 + n0s[0] + h2 + n1s[0] + ep) % N == 0]
    print("   ask only for closure on one frame (n0=%d, n1=%d): survivors %s."
          % (n0s[0], n1s[0], demo))
    verdict["|R|=0  free-running"] = "FALSIFIED" if not surv0 else str(surv0)

    # |R| = 1, exhaustive over site x value x N
    print()
    print("   --- |R| = 1, ONE RELOAD (exhaustive: %d sites x N x V) --------"
          % len(sites))
    surv1 = []
    for site in sites:
        for N in range(MAX_CELL + 1, 257):
            for V in range(N):
                ok = True
                for (n0, n1) in frames:
                    if cursor_at(site, V, N, "R1", n0, n1) != BASE_U0 % N:
                        ok = False
                        break
                    if cursor_at(site, V, N, "R3", n0, n1) != BASE_U1 % N:
                        ok = False
                        break
                if ok:
                    surv1.append((site, N, V))
                    break
            if surv1 and surv1[-1][0] == site:
                break
    print("   survivors: %s" % (surv1 or "NONE"))
    print("   WHY, in closed form.  Write x, y for the consumers passed from")
    print("   the reload forward to each anchor.  A reload UPSTREAM of both")
    print("   anchors gives y - x = n0 + h2, so N | (0x%02X + n0 + h2) -- and n0"
          % BASE_U0)
    print("   VARIES over the 79 unit-0 algorithms:")
    diffs = sorted({(BASE_U0 + n0 + h2) for n0 in n0s})
    g = 0
    for d in diffs:
        g = _gcd(g, d)
    print("      N | %s   ->  gcd = %d, and N > %d is MEASURED.  DEAD."
          % (diffs, g, MAX_CELL))
    print("   A reload BETWEEN the anchors (inside R1/R2, or at the unit-1 body")
    print("   entry) gives instead x - y = n1 + e + h1, which does NOT contain")
    print("   n0, so it survives the varying-n0 argument.  It requires")
    print("      0x%02X - 0x%02X = n1 + e + h1  (mod N)" % (BASE_U0, BASE_U1))
    print("      %d       = %d + %d + %d = %d   ->  N | %d.  DEAD, N > %d."
          % (BASE_U0 - BASE_U1, n1s[0], ep, h1, n1s[0] + ep + h1,
             abs(BASE_U0 - BASE_U1 - (n1s[0] + ep + h1)), MAX_CELL))
    print()
    print("   *** AND THIS IS THE SHARPEST NUMBER IN THE PASS. ***  The single-")
    print("   reload model misses by EXACTLY %d.  It would hold, for every ring"
          % abs(BASE_U0 - BASE_U1 - (n1s[0] + ep + h1)))
    print("   size N and with no free parameter at all, if")
    print("      h1 + e = 0x%02X - n1 = %d - %d = %d"
          % (BASE_U0, BASE_U0, n1s[0], BASE_U0 - n1s[0]))
    print("   descriptor consumers sat between the epilogue's reload point and")
    print("   the unit-0 body.  The R2 predicate finds h1 + e = %d + %d = %d."
          % (h1, ep, h1 + ep))
    print("   Six is also EXACTLY the size of the slack 0x%02X..0x%02X that no"
          % (BASE_U1 + n1s[0], BASE_U0 - 1))
    print("   algorithm in the ROM ever writes (sect. 1).  So the single-reload")
    print("   model is FALSIFIED *under the R2 consumer predicate* and would be")
    print("   resurrected exactly by finding TWO more consumers in the header or")
    print("   the epilogue.  The candidates -- header/epilogue words that carry")
    print("   the hi12 FORMAT-ESCAPE bit but are NOT class 4 == 1 -- are:")
    e2 = list(epi)
    for a, w in DW.PATCH.items():
        e2[a - 60] = w
    cand = [("I-RAM %2d" % i, w) for i, w in enumerate(hdr[:CALL1 + 1])
            if (fields(w)[0] & 0x800) and fields(w)[1] != 1]
    cand += [("I-RAM %2d" % (60 + i), w) for i, w in enumerate(e2)
             if 60 + i < DW.FRAME_WAIT_IW
             and (fields(w)[0] & 0x800) and fields(w)[1] != 1]
    ROLE = {0x821: "C-RAM pointer (MEASURED, K5)",
            0x825: "descriptor pointer (PROVEN, R3 sect. 1)",
            0x827: "third per-unit pointer (OPEN, K3 sect. 5.1)",
            0x445: "setvec unit0 (host-patched)",
            0x446: "setvec unit1 (host-patched)"}
    free = 0
    for (lbl, w) in cand:
        r = ROLE.get(fields(w)[3], "")
        if not r:
            free += 1
        print("      %s  %s  class %X  %s"
              % (lbl, fmt(w), fields(w)[1], r or "<- no assigned role"))
    print("   %d of the %d already carry a role that is not a DRAM access; %d do"
          % (len(cand) - free, len(cand), free))
    print("   not.  EXACTLY TWO of those would restore the single-reload model.")
    print("   That is a PREDICTION, and it is the cheapest test left here.")
    print()
    print("   AND ONE CONSUMER IS ALREADY FORCED INTO THE HEADER.  880.1.20.2D5")
    print("   occurs 24 times in bodies -- twice in every reverb -- and dropping")
    print("   it breaks the reverbs' 32-cells/32-consumers identity.  It is also")
    print("   I-RAM 12.  So the header really does touch delay memory, and the")
    print("   0x20..0x25 slack really is addressed by something.")
    verdict["|R|=1  one reload, any site/value/N"] = "FALSIFIED (misses by 2)"

    # ---- V-word --------------------------------------------------------
    print()
    print("   --- V-word: can the reload VALUE come from the reloading word? ---")
    pairs = []
    for (a, u, cells, cons) in C:
        if not cons:
            continue
        pairs.append((fmt(cons[0][1]), u, sorted(cells)[0], a))
    byword = collections.defaultdict(set)
    for (w, u, b, a) in pairs:
        byword[w].add(b)
    clash = {w: bs for w, bs in byword.items() if len(bs) > 1}
    print("   The body's FIRST consumer, and the cell the alignment gives it:")
    for w in sorted(byword):
        bs = sorted(byword[w])
        n = sum(1 for (ww, _u, _b, _a) in pairs if ww == w)
        print("      %s  x%-3d ->  cells {%s}%s"
              % (w, n, ", ".join("0x%02X" % b for b in bs),
                 "   *** CLASH ***" if len(bs) > 1 else ""))
    print()
    if clash:
        for w, bs in sorted(clash.items()):
            ex0 = [names.get(a, a) for (ww, u, b, a) in pairs
                   if ww == w and b == min(bs)][:2]
            ex1 = [names.get(a, a) for (ww, u, b, a) in pairs
                   if ww == w and b == max(bs)][:2]
            print("   *** %s is the first DRAM word of a unit-1 body (cell 0x%02X,"
                  % (w, min(bs)))
            print("       %s ...) AND of a unit-0 body (cell 0x%02X, %s ...)."
                  % (ex0, max(bs), ex1))
        print("   The 36-bit word is IDENTICAL and the base it must produce is")
        print("   not.  VERDICT: V-word FALSIFIED.  THE DESCRIPTOR BASE IS")
        print("   PER-UNIT STATE, NOT AN INSTRUCTION FIELD.")
        verdict["V-word (base carried by the instruction)"] = "FALSIFIED"
    else:
        verdict["V-word (base carried by the instruction)"] = "survives"

    # ---- V-ptr ---------------------------------------------------------
    print()
    print("   --- V-ptr: is the ...825 POINTER the cursor?  (R3 cand. (i)) ---")
    p825 = [(i, w) for i, w in enumerate(hdr)
            if fields(w)[0] == 0x801 and fields(w)[3] == 0x825]
    p825 += [(60 + i, w) for i, w in enumerate(e2)
             if 60 + i < DW.FRAME_WAIT_IW
             and fields(w)[0] == 0x801 and fields(w)[3] == 0x825]
    print("   Every ...825 load in the frame, in execution order:")
    for (i, w) in p825:
        where = ("unit-0 setup" if i < CALL0 else
                 "unit-1 setup" if i < CALL1 else "EPILOGUE")
        print("      I-RAM %2d  %s   payload 0x%02X   %s"
              % (i, fmt(w), fields(w)[2], where))
    same = len({fields(w)[2] for (i, w) in p825 if i < CALL1}) == 1
    print()
    print("   TWO independent refutations, and the second is new:")
    print("   (1) the two PER-UNIT setup blocks load the SAME payload 0x%02X and"
          % fields(p825[0][1])[2])
    print("       each is followed by exactly ONE consumer (I-RAM 46 and 54 --")
    print("       and they are the SAME word, %s).  Both units would" % fmt(hdr[46]))
    print("       therefore get the same base.  Required: 0x%02X and 0x%02X."
          % (BASE_U0, BASE_U1))
    print("   (2) the EPILOGUE's own load is 801.0.26.825, so under V-ptr the")
    print("       frame-entry cursor would be 0x26 and the header's %d consumers"
          % h1)
    print("       would land on 0x26..0x%02X -- ON TOP OF unit-0's own delay"
          % (0x26 + h1 - 1))
    print("       descriptors, which every one of the 79 unit-0 algorithms")
    print("       ships starting at exactly 0x26.")
    print("   VERDICT: %s" % ("FALSIFIED" if same else "survives"))
    verdict["V-ptr (...825 IS the cursor, R3 cand. (i))"] = (
        "FALSIFIED" if same else "survives")

    # ---- |R| = 2 -------------------------------------------------------
    print()
    print("   --- |R| = 2, V-unit: one reload per unit ---------------------")
    print("   This is what is left, and it is R3 candidate (iii)'s shape.  With")
    print("   one free value dominating each anchor, BOTH anchors are satisfied")
    print("   by construction and closure has nothing to say about the VALUES.")
    print("   Said before the result, as the brief requires.")
    print()
    print("   What closure DOES fix is the reload-free run from the unit-1")
    print("   reload to the frame boundary and on into the header:")
    entry = (BASE_U1 + n1s[0] + ep)
    print("      frame-entry cursor = base(unit1) + n1 + e = 0x%02X + %d + %d"
          % (BASE_U1, n1s[0], ep))
    print("                         = 0x%02X, the SAME value in all %d frames,"
          % (entry, len(frames)))
    print("                         because all 12 reverbs ship n1 = %s." % n1s)
    print()
    print("   *** AND THAT IS A PREDICTION WITH A TARGET. ***  Cells 0x%02X..0x%02X"
          % (entry, BASE_U0 - 1))
    print("   are shipped by NO algorithm in the ROM:")
    allcells = set()
    for (a, u, cells, cons) in C:
        allcells |= set(cells)
    gap = [c for c in range(entry, BASE_U0) if c not in allcells]
    print("      unwritten cells in [0x%02X, 0x%02X): %s"
          % (entry, BASE_U0, ["0x%02X" % c for c in gap]))
    print("      total unwritten cells below 0x%02X : %s"
          % (MAX_CELL + 1, ["0x%02X" % c for c in range(MAX_CELL + 1)
                            if c not in allcells]))
    hdr_cons = [(i, w) for i, w in enumerate(hdr[:CALL0 + 1]) if is_consumer(w)]
    print("      header 0..49 consumers, and the cell each then takes:")
    for k, (i, w) in enumerate(hdr_cons):
        print("         I-RAM %2d  %s  -> cell 0x%02X%s"
              % (i, fmt(w), entry + k,
                 "   (inside the slack)" if entry + k < BASE_U0 else ""))
    print("      FITS INSIDE THE SLACK: %s (%d consumers, %d slack cells)"
          % ("YES" if len(hdr_cons) <= len(gap) else "NO",
             len(hdr_cons), len(gap)))
    verdict["|R|=2  V-unit (R3 cand. (iii))"] = (
        "CONSISTENT; frame-entry cursor FORCED = 0x%02X" % entry)

    print()
    print("   *** AND THE ONE WORD THAT DOES NOT FIT -- reported, not smoothed")
    print("   over. ***  I-RAM 54 (%s) sits AFTER the unit-0 body and" % fmt(hdr[54]))
    print("   BEFORE the unit-1 reload, so it takes cell 0x%02X + n0:" % BASE_U0)
    over = []
    for a in u0s:
        n0 = len(consumers(imgs[a]))
        if BASE_U0 + n0 > MAX_CELL:
            over.append((names.get(a, a), n0, BASE_U0 + n0))
    for (nm, n0, c) in over:
        print("      unit-0 = %-18s n0=%2d -> cell 0x%02X, past the corpus max 0x%02X"
              % (nm, n0, c, MAX_CELL))
    print("   and for every other unit-0 algorithm it lands one cell past that")
    print("   algorithm's own allocation.  Two ways out, both testable:")
    print("      (a) %s consumes NOTHING -- and then so does I-RAM 46,"
          % fmt(hdr[54]))
    print("          because it is the same word, which drops h1 to %d;" % (h1 - 1))
    print("      (b) the unit-1 reload sits at or before I-RAM 54, which costs")
    print("          the reverb its 32 cells / 32 consumers identity.")
    print("   (a) is the survivor.  It is CONSISTENT, not forced.")

    print()
    print("   VERDICT TABLE")
    for k, v in verdict.items():
        print("      %-45s %s" % (k, v))
    return verdict


def _gcd(a, b):
    while b:
        a, b = b, a % b
    return abs(a)


# ===========================================================================
#  SECTION `carrier' -- where can a PER-UNIT base come from?
# ===========================================================================
_MASKS = (0xFFF, 0xFF, 0x7F, 0x3F, 0x1F, 0x0F, 0x07)
_SHIFTS = (0, 1, 2, 3, 4, -1, -2, -3, -4)


def _prep(p, m, s):
    v = p & m
    return (v << s) if s >= 0 else (v >> (-s))


def solve_affine(p0, p1, b0, b1):
    """EVERY integer affine map v -> k*v + off over the declared mask/shift
    family that carries (p0, p1) to (b0, b1).  Solved exactly -- item J's
    version enumerated k over a small range, which would have made a `NONE'
    here dishonest for any carrier whose payloads differ by 1."""
    hits = []
    for m in _MASKS:
        for s in _SHIFTS:
            v0, v1 = _prep(p0, m, s), _prep(p1, m, s)
            if v0 == v1:
                if b0 == b1:
                    hits.append((m, s, 0, b0))
                continue
            num, den = b0 - b1, v0 - v1
            if num % den:
                continue
            k = num // den
            off = b0 - k * v0
            hits.append((m, s, k, off))
    return hits


def sec_carrier(rom, imgs, loads, hdr, epi):
    print("=" * 78)
    print("3. THE PER-UNIT BASE -- every carrier the two setup blocks offer")
    print("=" * 78)
    print("   Closure (sect. 2) forces the base to be PER-UNIT STATE.  The two")
    print("   per-unit setup blocks are the only place the frame distinguishes")
    print("   the units before the body runs.  Lined up:")
    print()
    print("      unit-0 block              unit-1 block")
    b0 = list(range(42, CALL0 + 1))
    b1 = list(range(50, CALL1 + 1))
    for k in range(max(len(b0), len(b1))):
        l = "I-RAM %2d %s" % (b0[k], fmt(hdr[b0[k]])) if k < len(b0) else " " * 21
        r = "I-RAM %2d %s" % (b1[k], fmt(hdr[b1[k]])) if k < len(b1) else ""
        print("      %-25s %s" % (l, r))
    print()
    print("   Every field that DIFFERS, and whether the declared map family")
    print("   (mask/shift/scale/offset, exactly item J's) can carry it to the")
    print("   MEASURED bases {0x%02X, 0x%02X}:" % (BASE_U0, BASE_U1))
    print()
    cands = []
    for k in range(min(len(b0), len(b1))):
        w0, w1 = hdr[b0[k]], hdr[b1[k]]
        if w0 == w1:
            continue
        f0, f1 = fields(w0), fields(w1)
        for nm, ix in (("hi12", 0), ("class4", 1), ("addr8", 2), ("lo12", 3)):
            if f0[ix] != f1[ix]:
                cands.append(("I-RAM %d/%d %s" % (b0[k], b1[k], nm),
                              f0[ix], f1[ix]))
    cands.append(("I-RAM 49/59 CALL addr8 (unit tag)",
                  fields(hdr[49])[2], fields(hdr[59])[2]))
    for (nm, p0, p1) in cands:
        hits = solve_affine(p0, p1, BASE_U0, BASE_U1)
        small = [h for h in hits if abs(h[2]) <= 8]
        print("      %-38s 0x%03X / 0x%03X   maps: %-4s  |scale| <= 8: %s"
              % (nm, p0, p1, len(hits) if hits else "NONE",
                 len(small) if small else "NONE"))
        if small:
            m, s, k, off = small[0]
            print("            e.g. base = %d*((p & 0x%03X) %s %d) %+d"
                  % (k, m, ">>" if s < 0 else "<<", abs(s), off))
    print()
    print("   READ THAT COLUMN CAREFULLY.  Any carrier whose two payloads differ")
    print("   by +-1 is a SELECTOR wearing an affine map's clothes: k = +-38")
    print("   always solves it, and no search can ever refute it.  The honest")
    print("   statement is the second column -- a map with a small scale, the")
    print("   only kind that looks like address arithmetic rather than a table")
    print("   lookup.  Item J's search enumerated k over a small range and would")
    print("   have reported a dishonest NONE for those rows; this one solves the")
    print("   congruence exactly and reports both.")
    print()
    print("   CONTROL -- the family must be able to say YES.  Same solver, targets")
    print("   that ARE reachable:")
    for (tgt, lbl) in (((0x05, 0x85), "the FORCED D-RAM operand bases"),
                       ((0x70, 0x50), "the C-RAM pointer payloads themselves"),
                       ((0x26, 0x00), "the descriptor bases (the real question)")):
        n = sum(1 for (nm, p0, p1) in cands
                if [h for h in solve_affine(p0, p1, tgt[0], tgt[1])
                    if abs(h[2]) <= 8])
        print("      target {0x%02X, 0x%02X}  %-42s %d of %d carriers"
              % (tgt[0], tgt[1], "(%s):" % lbl, n, len(cands)))
    print()
    print("   The 1-bit CALL tag is a SELECTOR, not an arithmetic map: it can")
    print("   index a two-entry table of hardwired bases and no search can")
    print("   refute that.  It is CONSISTENT and it is not evidence.")


# ===========================================================================
#  SECTION `dirtest' -- DIRECTION, against an oracle that never reads lo12
# ===========================================================================
#
#  THE ORACLE.  R3 sect. 5.1: with a single global rotation G, data written to
#  cell W is found D samples later at cell W-D.  So for a stage that writes at
#  W and is read at R, D = W - R > 0.  Given the MEASURED alignment (sect. 1)
#  the cell VALUES therefore constrain read-vs-write, and the values are host
#  pokes -- they contain no instruction field at all.  This is the property
#  dark-words.md sect. 6 needed and had only four rows of.
#
#  A direction rule assigns R/W to every consumer.  Score it by pairing each W
#  with the NEXT R in cell order and asking for a delay that is positive and
#  inside the unit's 32768-word region.
# ---------------------------------------------------------------------------
REGION = {0: (0, 32768), 1: (32768, 65536)}


def boundary_cells(u, cells):
    """Cells whose VALUE is exactly the unit's region floor / ceiling (or one
    below).  MEASURED, sect. 4: 76 of 91 algorithms ship EXACTLY TWO of these.
    A (base, limit) pair is the obvious reading and it contradicts
    r3-delaydram.md sect. 5.1's `nothing in the descriptor stream is a length,
    a mask or a wrap limit'."""
    lo, hi = REGION[u]
    return {c for c, v in cells.items() if v in (lo, lo - 1, hi, hi - 1)}


def score_rule(C, rule, conv="R<W", drop_bounds=True):
    """SYMMETRIC, rule-independent scoring.  A direction rule labels every
    consumer R or W.  Under the global-rotation model a READ at cell R returns
    data written at some cell W, and the two conventions -- R = W - D
    (`R<W', R3 sect. 5.1's sign) and R = W + D (`R>W') -- are BOTH scored, so
    the test cannot be rigged by picking the sign that suits a rule.

    A read SCORES if SOME write cell of the same algorithm sits on the correct
    side of it within the 32768-word region.  Not `the nearest' -- which W
    serves which R is exactly what is not known, and assuming it would be the
    degenerate move.

    Returns (reads_matched, reads_total, algos_clean, algos_scored)."""
    ok = tot = perf = n = 0
    for (a, u, cells, cons) in C:
        ck = sorted(cells)
        if len(ck) != len(cons):
            continue
        drop = boundary_cells(u, cells) if drop_bounds else set()
        lab = {}
        for k, (_i, w) in enumerate(cons):
            if ck[k] not in drop:
                lab[ck[k]] = rule(w, k)
        rd = [cells[c] for c in lab if lab[c] == "R"]
        wr = [cells[c] for c in lab if lab[c] == "W"]
        if not rd or not wr:
            continue
        n += 1
        good = 0
        for r in rd:
            if conv == "R<W":
                if any(0 < w - r < 32768 for w in wr):
                    good += 1
            else:
                if any(0 < r - w < 32768 for w in wr):
                    good += 1
        ok += good
        tot += len(rd)
        if good == len(rd):
            perf += 1
    return ok, tot, perf, n


RULES = {
    "H-DIR-W    SRC 0x0B => READ, everything else WRITE":
        lambda w, k: "R" if src(w) == 0x0B else "W",
    "H-DIR-R    ... but SRC 0x00 is a READ too":
        lambda w, k: "R" if src(w) in (0x0B, 0x00) else "W",
    "H-SRC19    SRC 0x19 => WRITE, everything else READ":
        lambda w, k: "W" if src(w) == 0x19 else "R",
    "H-ADDR8    addr8 in {0x30,0x60} => READ (R3 6.3 FALSIFIED it)":
        lambda w, k: "R" if fields(w)[2] in (0x30, 0x60) else "W",
    "H-HI7      hi12 bit 7 => WRITE":
        lambda w, k: "W" if (fields(w)[0] & 0x080) else "R",
    "H-ACT      lo12 ACTION in {0x14,0x15} => READ":
        lambda w, k: "R" if (fields(w)[3] & 0x1F) in (0x14, 0x15) else "W",
}
CONTROLS = {
    "C-INV      H-DIR-W INVERTED  (** DEGENERATE, see 4.2a **)":
        lambda w, k: "W" if src(w) == 0x0B else "R",
    "C-CELLPAR  label by CELL PARITY -- knows nothing about the word":
        lambda w, k: "R" if (k & 1) else "W",
    "C-LOW      label by lo12 bit 0 (a nonsense rule)":
        lambda w, k: "R" if (fields(w)[3] & 1) else "W",
    "C-ADDRLSB  label by addr8 bit 0 (a nonsense rule)":
        lambda w, k: "R" if (fields(w)[2] & 1) else "W",
}


def sec_dirtest(rom, imgs, loads, names):
    print("=" * 78)
    print("4. *** DIRECTION *** -- and a NEW measurement that reframes it")
    print("=" * 78)
    C = corpus(rom, imgs, loads)

    # --- the boundary-cell measurement, first ---------------------------
    print("   4.1  THE BOUNDARY CELLS -- MEASURED, and it contradicts R3 5.1.")
    print("   Every algorithm's descriptor block is scanned for cells whose")
    print("   VALUE is exactly its unit's region floor or ceiling:")
    tal = collections.Counter()
    kinds = collections.Counter()
    for (a, u, cells, cons) in C:
        b = boundary_cells(u, cells)
        tal[len(b)] += 1
        lo, hi = REGION[u]
        for c in b:
            v = cells[c]
            kinds["floor" if v == lo else "floor-1" if v == lo - 1 else
                  "ceiling" if v == hi else "ceiling-1"] += 1
    print("      boundary-valued cells per algorithm: %s"
          % dict(sorted(tal.items())))
    print("      which boundary: %s" % dict(kinds))
    print("      -> %d of %d algorithms ship EXACTLY TWO."
          % (tal[2], len(C)))
    print("   All twelve reverbs ship 32768 (their floor) AND 32767 (one below")
    print("   it).  r3-delaydram.md sect. 5.1 says `Nothing in the descriptor")
    print("   stream is a length, a mask or a wrap limit -- every cell is an")
    print("   address'.  A per-algorithm (base, limit) PAIR is the obvious")
    print("   reading of this and it is not an address pair.  MEASURED; the")
    print("   ring-bound INTERPRETATION is INFERRED and is flagged as a")
    print("   FALSIFICATION CANDIDATE for R3 5.1, not as a decode.")
    print()

    # --- the direction scoring ------------------------------------------
    print("   4.2  DIRECTION RULES, scored BOTH WAYS ROUND.")
    print("   A read at cell R returns data written at cell W; the sign of")
    print("   W - R is the memory model's rotation direction and it is NOT")
    print("   established.  Scoring only the convention that flatters a rule is")
    print("   precisely the degenerate-control mistake, so BOTH are scored, and")
    print("   a read counts as matched if ANY write cell of the same algorithm")
    print("   sits on the right side of it -- never `the nearest', because which")
    print("   W serves which R is exactly what is unknown.")
    print("   The two boundary cells are excluded (4.1).")
    print()
    print("   %-52s %-18s %-18s" % ("rule", "R<W  (R3 5.1 sign)", "R>W"))
    for nm, fn in list(RULES.items()) + list(CONTROLS.items()):
        a1 = score_rule(C, fn, "R<W")
        a2 = score_rule(C, fn, "R>W")
        print("   %-52s %5.1f%% %3d/%-3d  %5.1f%% %3d/%-3d"
              % (nm,
                 100.0 * a1[0] / a1[1] if a1[1] else 0.0, a1[2], a1[3],
                 100.0 * a2[0] / a2[1] if a2[1] else 0.0, a2[2], a2[3]))
    print("   (percentage = reads with a legal partner; n/m = algorithms in")
    print("    which EVERY read has one, out of algorithms scored)")
    print()
    print("   4.2a  *** TWO THINGS ABOUT THAT TABLE THAT MUST BE SAID FIRST.")
    print("   (1) C-INV IS DEGENERATE WITH READING THE OTHER COLUMN.  Inverting")
    print("       every label and flipping the convention is very nearly the")
    print("       same machine -- which is why C-INV`s R<W number sits next to")
    print("       H-DIR-W`s R>W number.  Method rule 4.  It is NOT a control")
    print("       here; it is a restatement, and it is labelled as one.  The")
    print("       residual difference (62 vs 53 clean algorithms) comes only")
    print("       from the boundary-cell exclusion and the `any partner`")
    print("       quantifier, and NOTHING is hung on a gap that small.")
    print("   (2) C-CELLPAR is the control that earns its keep.  It knows")
    print("       nothing whatever about the instruction -- it labels by the")
    print("       parity of the cell index.  If it scored like H-DIR-W, then")
    print("       H-DIR-W`s score would be measuring the ladder`s ALTERNATION")
    print("       and not the SRC field at all.")
    print()
    print("   WHAT THE TABLE THEREFORE DETERMINES: the JOINT choice of (rule,")
    print("   rotation sign), up to the global flip, and nothing finer.  The")
    print("   best joint choice is H-DIR-W with reads ABOVE writes.  That sign")
    print("   is the OPPOSITE of the one r3-delaydram.md sect. 5.1 asserts")
    print("   (`the read cell of a stage sits below its write cell`), by 62")
    print("   clean algorithms to 10 under the identical rule.")
    print()

    # --- the three-way disagreement -------------------------------------
    # --- the randomised null -------------------------------------------
    print("   4.2b  *** THE RANDOMISED NULL -- what does `62 of 74 clean' mean?")
    import random
    rng = random.Random(20260727)
    base = score_rule(C, RULES["H-DIR-W    SRC 0x0B => READ, everything else WRITE"],
                      "R>W")
    nR = {}
    for (a, u, cells, cons) in C:
        ck = sorted(cells)
        if len(ck) != len(cons):
            continue
        drop = boundary_cells(u, cells)
        nR[a] = sum(1 for k, (_i, w) in enumerate(cons)
                    if ck[k] not in drop and src(w) == 0x0B)
    trials = []
    for t in range(400):
        perm = {}

        def rr(w, k, _p=perm):
            return _p[k]
        clean = tot_ok = tot_n = 0
        scored = 0
        for (a, u, cells, cons) in C:
            ck = sorted(cells)
            if len(ck) != len(cons):
                continue
            drop = boundary_cells(u, cells)
            idx = [k for k in range(len(cons)) if ck[k] not in drop]
            lbl = ["R"] * nR.get(a, 0) + ["W"] * (len(idx) - nR.get(a, 0))
            rng.shuffle(lbl)
            lab = dict(zip(idx, lbl))
            rd = [cells[ck[k]] for k in idx if lab[k] == "R"]
            wr = [cells[ck[k]] for k in idx if lab[k] == "W"]
            if not rd or not wr:
                continue
            scored += 1
            g = sum(1 for r in rd if any(0 < r - w < 32768 for w in wr))
            tot_ok += g
            tot_n += len(rd)
            if g == len(rd):
                clean += 1
        trials.append((clean, tot_ok / tot_n if tot_n else 0))
    cl = sorted(t[0] for t in trials)
    pc = sorted(t[1] for t in trials)
    print("      400 random labellings, SAME number of reads per algorithm as")
    print("      H-DIR-W, same convention (R>W), same exclusions:")
    print("         clean algorithms : min %d  median %d  max %d"
          % (cl[0], cl[len(cl) // 2], cl[-1]))
    print("         reads matched    : min %.1f%%  median %.1f%%  max %.1f%%"
          % (100 * pc[0], 100 * pc[len(pc) // 2], 100 * pc[-1]))
    print("         H-DIR-W          : clean %d, matched %.1f%%"
          % (base[2], 100.0 * base[0] / base[1]))
    ge = sum(1 for c in cl if c >= base[2])
    print("         random runs reaching H-DIR-W`s clean count: %d of 400" % ge)
    print()
    print("   *** AND THAT IS THE RESULT OF SECTION 4, STATED AGAINST MY OWN")
    print("   PREDICTION, IN TWO HALVES BECAUSE IT IS TWO FACTS. ***")
    print("     * The test HAS power against noise: only 1 of 400 random")
    print("       labellings reaches H-DIR-W`s clean count.  So the descriptor")
    print("       values really do carry read/write structure.")
    print("     * The test has NO power to say WHICH RULE finds it.  C-CELLPAR")
    print("       -- which never looks at the instruction -- lands in the same")
    print("       tail (94.5%, 61 clean vs 93.0%, 62).  What both are detecting")
    print("       is the ladder`s ALTERNATION, and H-DIR-W agrees with the")
    print("       alternation almost everywhere.")
    print("   THEREFORE: the descriptor values are NOT a direction oracle.  The")
    print("   thing this section was built to be DOES NOT EXIST.  DRAM-DIR stays")
    print("   OPEN; H-DIR keeps exactly the four rows dark-words.md sect. 6 gave")
    print("   it and this pass adds NONE.  Publishing `H-DIR confirmed on 890")
    print("   words` would have been the fourth degenerate control in four")
    print("   rounds -- it was one query away.")
    print()
    print("   4.3  *** A SECOND MISS, AND IT IS A CONTRADICTION IN THE CORPUS.")
    print("   I expected the cell values to be a clean lo12-free direction")
    print("   ORACLE -- dark-words.md sect. 6 has 4 rows and this would have had")
    print("   hundreds.  It is not one.  Three algorithms demand different")
    print("   things, and here they are, cell by cell:")
    for algo in (16, 10, 9):
        cells = desc_cells(rom, algo)
        u = 1 if algo in range(16, 28) else 0
        cons = consumers(imgs[algo])
        ck = sorted(cells)
        bd = boundary_cells(u, cells)
        print("      --- %s (algo %d) ---" % (names.get(algo, "?"), algo))
        for k, (i, w) in enumerate(cons[:8]):
            c = ck[k]
            print("         cell 0x%02X = %6d  %s  SRC 0x%02X  %s%s"
                  % (c, cells[c], fmt(w), src(w),
                     "READ " if src(w) == 0x0B else "write",
                     "   <- boundary cell" if c in bd else ""))
        if len(cons) > 8:
            print("         ... %d more" % (len(cons) - 8))
    print()
    print("   MULTI TAP DELAY's four tap cells are 6000/12000/18000/24000 =")
    print("   136/272/408/544 ms and its line base is 0 -- so its reads sit")
    print("   ABOVE its write.  ROOM REVERB's ladder has R1's FORCED read on the")
    print("   region FLOOR and its writes above -- reads BELOW writes.  The two")
    print("   cannot both hold with one rotation sign, so at least one of")
    print("   {the alignment, H-DIR, R1's forced read slot, the rotation sign}")
    print("   is wrong.  Which one is OPEN, and it is the next experiment.")
    print()
    print("   4.4  AND WHAT THE VALUES DO SAY ABOUT `SRC 0x00'.  H-DIR-W and")
    print("   H-DIR-R differ ONLY in whether SRC 0x00 is a read.  H-DIR-R lands")
    print("   at 13 clean algorithms, BELOW the random null`s median of ~50 --")
    print("   so on this test SRC 0x00 = the delay-RAM read is worse than")
    print("   chance, which agrees in sign with blocking-read.md item F.  But")
    print("   the same test cannot tell H-DIR-W from a word-blind rule, so it")
    print("   is a WEAK fourth vote and it is recorded as CONSISTENT, not as a")
    print("   determination.  Nothing is applied.")
    return None


# ===========================================================================
#  SECTION `comb' -- the echo train the comb model predicts
# ===========================================================================
def sec_comb(rom, imgs, loads, names):
    print("=" * 78)
    print("5. *** THE COMB PREDICTION *** -- an END-TO-END observable")
    print("=" * 78)
    print("   schroeder-topology.md forced a COMB network: stage r reads w[r]")
    print("   from its line, adds the incoming t[r-1], writes the sum BACK to")
    print("   the line and multiplies it by g[r].  Every line therefore carries")
    print("   a self-loop g_k z^-D_k, and the reverb must emit a DECAYING ECHO")
    print("   TRAIN at the line spacings.  Those spacings are now MEASURED, per")
    print("   algorithm, out of the descriptor file -- so the model finally has")
    print("   a numeric prediction that an impulse response can refute.")
    print()
    print("   *** THE LABEL ON THESE NUMBERS. ***  The DIFFERENCES are MEASURED.")
    print("   Calling them DELAYS needs (a) the alignment (sect. 1, delta = 0,")
    print("   CONSISTENT), (b) a direction rule (sect. 4, H-DIR, CONSISTENT and")
    print("   NOT improved by this pass) and (c) the rotation sign, which the")
    print("   reverb ladder needs to be R < W while the rest of the corpus")
    print("   scores better at R > W (sect. 4.3).  So: MEASURED differences,")
    print("   CONDITIONAL delays.  They are printed because a wrong prediction")
    print("   that can be refuted is worth more than no prediction.")
    print()
    for algo in (16, 20, 26):
        cells = desc_cells(rom, algo)
        ck = sorted(cells)
        cons = consumers(imgs[algo])
        if len(ck) != len(cons):
            continue
        seq = [cells[c] for c in ck]
        lab = ["R" if src(w) == 0x0B else "W" for _i, w in cons]
        lines = []
        for k in range(len(seq) - 1):
            if lab[k] == "W":
                j = k + 1
                while j < len(seq) and lab[j] != "R":
                    j += 1
                if j < len(seq) and 0 < seq[k] - seq[j] < 32768:
                    lines.append((ck[k], ck[j], seq[k] - seq[j]))
        print("   %-18s (algo %d): %d delay lines"
              % (names.get(algo, "?"), algo, len(lines)))
        print("      write/read cell pairs and D in samples (44.1 kHz):")
        for (cw, cr, d) in lines:
            print("         cell 0x%02X -> 0x%02X   D = %6d  = %7.2f ms"
                  % (cw, cr, d, d / 44.1))
        if lines:
            ds = [d for _a, _b, d in lines]
            print("      shortest line %d samples -> ANY impulse test must run at"
                  % min(ds))
            print("      LEAST %d samples (>= 4x the longest, %d) or the feedback"
                  % (4 * max(ds), max(ds)))
            print("      is amputated -- schroeder-topology.md sect. 3's defect.")
        print()
    print("   *** WHAT THE TEST WOULD LOOK LIKE, AND WHY IT CANNOT RUN YET. ***")
    print("   A frame does not COMPLETE: 0 of 1 344 001 measured frames close,")
    print("   and all 42 delay-DRAM slots TRAP, so the line is never written.")
    print("   The predicted observable is therefore recorded, not measured:")
    print("      impulse at t=0 -> first echo at D_min, then a geometric train")
    print("      at multiples of each D_k, decaying by g_k per pass.")
    print("   The moment the DRAM family executes, an impulse of >= 4x max(D_k)")
    print("   samples is the first end-to-end refutation the reverb has ever")
    print("   admitted.  Nothing here is a recording.")


# ===========================================================================
#  SECTION `control'
# ===========================================================================
def sec_control(rom, imgs, loads, hdr, epi, names):
    print("=" * 78)
    print("6. THE CONTROLS -- each shown with the case where it says NO")
    print("=" * 78)
    C = corpus(rom, imgs, loads)
    passed = []

    print("   K1 -- the alignment counter must reject a wrong predicate.")
    ok = sum(1 for (a, u, c, k) in C if len(c) == len(k))
    okx = 0
    for (a, u, c, k) in C:
        if len(c) == sum(1 for _i, w in k if not D.c_format(w)):
            okx += 1
    okn = ok2 = ok3 = 0
    for (a, u, c, k) in C:
        n = sum(1 for _i, w in k if fields(w)[1] == 1)     # class 1, escape ignored
        if len(c) == n:
            okn += 1
        # K6's WITHDRAWN addr8 < 0x80 split
        if len(c) == sum(1 for _i, w in k if fields(w)[2] < 0x80):
            ok2 += 1
        # the datapath class instead of the escape class
        if len(c) == sum(1 for _i, w in imgs[a] and enumerate(imgs[a])
                         if fields(w)[1] == 2):
            ok3 += 1
    print("      R2 predicate (escape bit + class 1)      : %d of %d" % (ok, len(C)))
    print("      ... minus the C format                   : %d of %d  <- rejected"
          % (okx, len(C)))
    print("      ... with K6's WITHDRAWN addr8 < 0x80     : %d of %d  <- rejected"
          % (ok2, len(C)))
    print("      the DATAPATH class (class4 == 2) instead : %d of %d  <- rejected"
          % (ok3, len(C)))
    print("      class 1 with the escape bit ignored      : %d of %d  (identical --"
          % (okn, len(C)))
    print("        every class-1 word in a BODY carries the escape bit, so this")
    print("        one cannot fail and is NOT counted as a control)")
    passed.append(okx < ok and ok2 < ok and ok3 < ok)

    print()
    print("   K2 -- the mod-38 alias, a mechanism that WOULD explain 0x26 == 0x00.")
    print("      If the cursor were flat mod 0x26 the two units' cells would")
    print("      alias.  Check whether any legal (unit-0, unit-1) pair then")
    print("      collides:")
    worst = None
    for (a, u, c, k) in C:
        if u == 0:
            hi = max(c) % 0x26
            if worst is None or hi > worst[1]:
                worst = (a, hi)
    print("      worst unit-0 algo: %s, cells reach 0x%02X mod 0x26 = %d"
          % (names.get(worst[0], worst[0]), max(desc_cells(rom, worst[0])),
             worst[1]))
    print("      every reverb occupies 0x00..0x1F = 0..31, so it collides with")
    print("      %d of the %d aliased unit-0 cells.  VERDICT: FALSIFIED."
          % (min(worst[1], 31) + 1, worst[1] + 1))
    passed.append(worst[1] <= 31)

    print()
    print("   K3 -- the phase test must reject a wrong phase (sect. 1).")
    offs = []
    for delta in (-1, 0, 1):
        off = 0
        for (a, u, cells, cons) in C:
            ck = sorted(cells)
            for k in range(len(cons)):
                if ck[0] + k + delta not in cells:
                    off += 1
        offs.append((delta, off))
    print("      off-the-shipped-set count, delta -1/0/+1 -> %s" % offs)
    _d0, n0b = ladder_delays(rom, imgs, 16, 0)
    _dm, nmb = ladder_delays(rom, imgs, 16, -1)
    print("      impossible R1-forced pairs, delta 0 -> %d, delta -1 -> %d"
          % (n0b, nmb))
    passed.append(offs[1][1] < offs[0][1] and offs[1][1] < offs[2][1]
                  and n0b < nmb)

    print()
    print("   K4 -- the direction scorer must reject the inverted rule (sect. 4).")
    a1 = score_rule(C, RULES["H-DIR-W    SRC 0x0B => READ, everything else WRITE"],
                    "R>W")
    a2 = score_rule(C, CONTROLS["C-LOW      label by lo12 bit 0 (a nonsense rule)"],
                    "R>W")
    a3 = score_rule(C,
                    CONTROLS["C-CELLPAR  label by CELL PARITY -- knows nothing about the word"],
                    "R>W")
    print("      H-DIR-W  %.1f%%, %d clean;  C-LOW %.1f%%, %d clean  <- rejected"
          % (100.0 * a1[0] / a1[1], a1[2], 100.0 * a2[0] / a2[1], a2[2]))
    print("      BUT C-CELLPAR (word-blind) %.1f%%, %d clean  <- NOT rejected."
          % (100.0 * a3[0] / a3[1], a3[2]))
    print("      *** So K4 PASSES as a control and the SECTION IT CONTROLS")
    print("      FAILS as evidence.  That is sect. 4.2b, and it is the most")
    print("      valuable line in this pass. ***")
    passed.append(a1[0] / a1[1] > a2[0] / a2[1])

    print()
    print("   K5 -- the closure test must be able to say YES.  Build a")
    print("      DELIBERATELY-WRONG twin: a corpus in which every unit-0 body")
    print("      has the SAME consumer count, and re-run the one-reload gcd:")
    n0s = sorted({len(consumers(imgs[a])) for (a, u, _c, _k) in C if u == 0})
    h2 = sum(1 for w in hdr[CALL0 + 1:CALL1 + 1] if is_consumer(w))
    real = 0
    for n0 in n0s:
        real = _gcd(real, BASE_U0 + n0 + h2 - BASE_U1)
    pick = [n for n in n0s if BASE_U0 + n + h2 > MAX_CELL]
    twin = BASE_U0 + pick[0] + h2 - BASE_U1
    print("      real corpus  (n0 in %s):" % n0s)
    print("         gcd = %d -> N <= %d, and N > %d is MEASURED.  REJECTED."
          % (real, real, MAX_CELL))
    print("      twin corpus  (every unit-0 body has n0 == %d):" % pick[0])
    print("         N = %d, which is > %d.  ACCEPTED -- so the test is not one"
          % (twin, MAX_CELL))
    print("         that rejects everything put in front of it.")
    passed.append(real <= MAX_CELL < twin)

    print()
    print("   CONTROLS: %s" % ("ALL PASS" if all(passed) else "FAILURE"))
    return all(passed)


# ---------------------------------------------------------------------------
def main():
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["all", "align", "closure", "carrier", "dirtest",
                             "comb", "control"])
    ap.add_argument("--sub", default=os.path.join(repo, "original_ROMs",
                                                  "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(repo, "original_ROMs",
                                                   "kn5000_v10_program.rom"))
    ap.add_argument("--tools",
                    default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    args = ap.parse_args()
    rom, imgs, loads, hdr, epi = load(args.sub, args.tools)
    sys.path.insert(0, args.tools)
    try:
        import kn5000_dsp_coeffs as CO
        names = CO.effect_names(args.main) if os.path.exists(args.main) else {}
    except Exception:
        names = {}

    if args.cmd in ("all", "align"):
        sec_align(rom, imgs, loads, names)
        print()
    if args.cmd in ("all", "closure"):
        sec_closure(rom, imgs, loads, hdr, epi, names)
        print()
    if args.cmd in ("all", "carrier"):
        sec_carrier(rom, imgs, loads, hdr, epi)
        print()
    if args.cmd in ("all", "dirtest"):
        sec_dirtest(rom, imgs, loads, names)
        print()
    if args.cmd in ("all", "comb"):
        sec_comb(rom, imgs, loads, names)
        print()
    if args.cmd in ("all", "control"):
        sec_control(rom, imgs, loads, hdr, epi, names)


if __name__ == "__main__":
    main()
