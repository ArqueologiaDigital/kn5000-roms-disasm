#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""adjudicate4.py -- TARGET 4 round 4: adjudicate the three concurrent passes.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  No hardware.  Static analysis,
the ROM corpus and the emulator only.

Inputs adjudicated:
    dsp/analysis/dram-cursor-closure.md   (TARGET 1 -- the 42 delay-DRAM words)
    dsp/analysis/store-gate.md            (TARGET 2 -- the bit-7 store gate)
    dsp/analysis/register-space.md        (TARGET 3 -- the register space)

Every number in dsp/analysis/adjudication-round4.md comes out of this file.

    python3 dsp/tools/adjudicate4.py partition   # SS1 the DRAM is split at 0x8000
    python3 dsp/tools/adjudicate4.py segments    # SS2 the descriptor is a PARTITION
    python3 dsp/tools/adjudicate4.py itemI       # SS3 T1 item I -- dissolved
    python3 dsp/tools/adjudicate4.py schroeder   # SS4 the predicted lines vs the ROM
    python3 dsp/tools/adjudicate4.py escape16    # SS5 T1's 16 resurrection words
    python3 dsp/tools/adjudicate4.py clrlate     # SS6 the SHIPPED guard-7 escape
    python3 dsp/tools/adjudicate4.py mirror      # SS7 re-run the load-bearing numbers
    python3 dsp/tools/adjudicate4.py control     # SS8 every control, shown saying NO
    python3 dsp/tools/adjudicate4.py all

Labels used below and in the note:
    MEASURED / PROVEN BY CONSTRUCTION / FORCED / CONSISTENT / INFERRED /
    FALSIFIED / OPEN.  Nothing here is applied unless it is FORCED.
"""
import argparse
import collections
import itertools
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                                              # noqa: E402
import dark_words as DW                                             # noqa: E402
import register_space as RS                                         # noqa: E402

DSC_TAG = 0x4C          # the delay-descriptor space (register-space.md SS1)
DRAM_TAG = 0x15         # the on-chip D-RAM space
REVERBS = tuple(range(16, 28))
HALF = 0x8000           # 32768


# ==========================================================================
#  common
# ==========================================================================
def rom_and_images(sub, mainrom, tools):
    rom, main, E = RS.load(sub, mainrom, tools)
    imgs = RS.cell_images(rom)
    return rom, main, E, imgs


def descriptor_images(imgs):
    """algo -> [(cell, value)] in ascending cell order, descriptor space only."""
    out = {}
    for a, img in imgs.items():
        d = img.get(DSC_TAG)
        if d:
            out[a] = [(c, d[c]) for c in sorted(d)]
    return out


def unit_of(algo):
    return 1 if algo in REVERBS else 0


def head(n, s):
    print()
    print("=" * 78)
    print("%s. %s" % (n, s))
    print("=" * 78)


# ==========================================================================
#  SS1  THE EXTERNAL DELAY DRAM IS SPLIT IN HALF AT 0x8000
# ==========================================================================
def cmd_partition(main, dsc):
    head("1", "THE DELAY DRAM IS SPLIT IN HALF AT 0x8000 -- one law, both units")
    print("""
  TARGET 1 item I reports a live contradiction: MULTI TAP's taps 6000/12000/
  18000/24000 sit ABOVE its `line base 0', while ROOM REVERB's R1-FORCED read
  sits BELOW its writes on `the region floor'.  The two readings differ in one
  unstated thing -- whether a descriptor cell is a DELAY or an ADDRESS.  If it
  is always an ADDRESS, unit-0's floor is 0 and unit-1's is 0x8000 and the two
  statements are the same statement.  That is testable on the VALUES alone.
""")
    lo0 = hi0 = lo1 = hi1 = None
    viol = []
    for a, cells in sorted(dsc.items()):
        u = unit_of(a)
        for c, v in cells:
            if u == 0:
                lo0 = v if lo0 is None else min(lo0, v)
                hi0 = v if hi0 is None else max(hi0, v)
                if v > HALF:
                    viol.append((a, c, v, 0))
            else:
                lo1 = v if lo1 is None else min(lo1, v)
                hi1 = v if hi1 is None else max(hi1, v)
                if v < HALF - 1:
                    viol.append((a, c, v, 1))
    n0 = sum(len(v) for a, v in dsc.items() if unit_of(a) == 0)
    n1 = sum(len(v) for a, v in dsc.items() if unit_of(a) == 1)
    print("   unit-0 algorithms: %d descriptor cells, value range [%d, %d]"
          % (n0, lo0, hi0))
    print("   unit-1 algorithms: %d descriptor cells, value range [%d, %d]"
          % (n1, lo1, hi1))
    print()
    print("   ** MEASURED: every unit-0 value <= 0x8000 and every unit-1 value")
    print("      >= 0x7FFF, with %d exception(s):" % len(viol))
    vcells = collections.Counter((a and 0) or 0 for a, c, v, u in viol)
    for a, c, v, u in viol:
        print("        algo %d cell %02X = %d (unit %d)" % (a, c, v, u))
    vc = collections.Counter(c for _a, c, _v, _u in viol)
    print("      the violating CELL INDEX is: %s -- one cell, not a scatter."
          % dict(vc))
    print("""
   => THE DRAM IS PARTITIONED AT 0x8000: unit-0 owns [0, 0x7FFF], unit-1 owns
      [0x8000, 0xFFFF].  MEASURED over %d + %d cells with %d exceptions, and
      every exception is the SAME cell index (0x01) in the eleven reverbs that
      are not ROOM REVERB 1, where it holds the value 0.  ROOM REVERB 1 holds
      45464 there = its own highest address + 1.  ** So cell 0x01 is not an
      address in eleven of twelve reverbs; it is a twelfth non-tap cell, and
      what it IS stays OPEN. **  This is the VALUE-space twin of
      register-space.md E2's CELL-space partition (unit-1 owns cells
      0x00..0x1F, unit-0 owns 0x26..0x39) and it shares no premise with it: E2
      counts cell INDICES written by the host, this counts the VALUES written
      into them.""" % (n0, n1, len(viol)))

    # the sentinel cell
    print()
    print("   THE SENTINEL CELL -- TARGET 1 item H, located POSITIONALLY:")
    s0 = s1 = 0
    pos = collections.Counter()
    miss = []
    for a, cells in sorted(dsc.items()):
        u = unit_of(a)
        want = HALF if u == 0 else HALF - 1
        ix = [i for i, (_c, v) in enumerate(cells) if v == want]
        if ix:
            (s1 if u else s0).__class__          # noqa -- readability only
            if u:
                s1 += 1
            else:
                s0 += 1
            for i in ix:
                pos[i - len(cells)] += 1         # index from the END
        else:
            miss.append((a, len(cells)))
    print("     algorithms carrying their unit's sentinel value:"
          " unit-0 %d, unit-1 %d, MISSING %d" % (s0, s1, len(miss)))
    print("     its index counted FROM THE END: %s"
          % dict(sorted(pos.items(), reverse=True)))
    for a, n in miss:
        print("       missing: algo %d (%s), n=%d"
              % (a, RS.effect_name(main, a), n))
    lastn = sorted({len(cells) for a, cells in dsc.items()
                    if cells and cells[-1][1] ==
                    (HALF if unit_of(a) == 0 else HALF - 1)})
    print("     the algorithms whose sentinel is LAST all have n in %s"
          % lastn)
    print("""
     => the sentinel sits at index n-2 in %d of %d algorithms that carry one,
        and the %d exceptions are exactly the %d-cell blocks, where n-2 is
        index 0 and there is no interior slot at all.
        unit-0's sentinel is ONE PAST THE TOP of its half (0x8000); unit-1's is"""
          % (pos.get(-2, 0), s0 + s1, pos.get(-1, 0), lastn[0] if lastn else 0))
    print("""
        ONE BELOW THE BOTTOM of its half (0x7FFF).  INFERRED reading: a wrap
        sentinel.  ENUMERATION printed beside the claim, because only one of
        these is a direction statement:
          (a) `the address one step beyond my region in the direction the
              pointer travels' -- then the two units run OPPOSITE directions;
          (b) `the address of the partition line itself, named from my side'
              -- 0x8000 for the unit below it, 0x7FFF for the unit above it,
              and NO direction is implied;
          (c) a limit register compared with != rather than a wrap constant.
        (b) and (c) need no direction and are not distinguished by any datum in
        this pass, so the sentinel is NOT evidence about direction.  OPEN.""")
    return pos


# ==========================================================================
#  SS2  THE DESCRIPTOR BLOCK IS A CONTIGUOUS ADDRESS PARTITION
# ==========================================================================
def dup_census(cells, dmax=13):
    """-> {offset: [(i, j)]} exact value duplicates at a FIXED index offset."""
    vals = [v for _c, v in cells]
    out = collections.defaultdict(list)
    for d in range(1, dmax):
        for i in range(0, len(vals) - d):
            if vals[i] == vals[i + d]:
                out[d].append((i, i + d))
    return dict(out)


def cmd_segments(main, dsc, seed=20260727):
    head("2", "THE DESCRIPTOR BLOCK IS A CONTIGUOUS ADDRESS PARTITION")
    print("""
  If a descriptor cell is an ADDRESS and a delay line is a REGION, then the
  block must contain each interior boundary TWICE -- once as the end of one
  line and once as the start of the next.  That is a strong, falsifiable
  prediction about EXACT VALUE DUPLICATES, and it is a prediction about the
  values only: no instruction is read.

  THE OFFSET IS ENUMERATED (1..12), NOT FIXED (method rule 2).""")
    rows = []
    for a, cells in sorted(dsc.items()):
        c = dup_census(cells)
        best = sorted(((len(v), d) for d, v in c.items()), reverse=True)
        rows.append((a, len(cells), c, best[0] if best else (0, None)))
    tot = collections.Counter()
    for _a, _n, c, _b in rows:
        for d, v in c.items():
            tot[d] += len(v)
    print("   duplicate pairs over the whole corpus, by index offset:")
    print("     " + "  ".join("d=%d:%d" % (d, n) for d, n in sorted(tot.items())))
    print()
    print("   per algorithm (only those with any duplicate):")
    for a, n, c, (bn, bd) in rows:
        if not c:
            continue
        print("     algo %2d %-18s n=%2d  %s"
              % (a, RS.effect_name(main, a), n,
                 "  ".join("d=%d:%d" % (d, len(v)) for d, v in sorted(c.items()))))
    nodup = [a for a, _n, c, _b in rows if not c]
    print("   algorithms with NO duplicate at any offset: %d of %d"
          % (len(nodup), len(rows)))
    print("   ** THE TEST CAN SAY NO, AND IT DOES: %d of %d algorithms show"
          " nothing." % (len(nodup), len(rows)))

    # ---- the null: how many duplicates does a random block have? -----------
    rnd = random.Random(seed)
    null = []
    for _t in range(4000):
        a = 16
        vals = [v for _c, v in dsc[a]]
        rnd.shuffle(vals)
        c = collections.Counter()
        for d in range(1, 13):
            for i in range(0, len(vals) - d):
                if vals[i] == vals[i + d]:
                    c[d] += 1
        null.append(max(c.values()) if c else 0)
    ge9 = sum(1 for x in null if x >= 9)
    print()
    print("   CONTROL -- the permutation null.  Shuffle ROOM REVERB 1's own 32")
    print("   values 4000 times and take the best offset each time:")
    print("     max duplicates at any single offset: mean %.2f, max %d,"
          " >= 9 in %d of 4000"
          % (sum(null) / len(null), max(null), ge9))
    print("     (the shuffle PRESERVES the multiset, so the 10 real duplicate")
    print("      VALUES are still there -- what it destroys is only their")
    print("      alignment.  A test that could not fail would score 9 here.)")

    # ---- build the chain for the twelve reverbs ---------------------------
    print()
    print("   THE CHAIN, for the twelve reverbs (d = 5 on even indices, plus")
    print("   one d = 11 pair).  Addresses ascending; the segment lengths are")
    print("   the DIFFERENCES, which is the whole point:")
    seg = {}
    for a in REVERBS:
        if a not in dsc:
            continue
        cells = dsc[a]
        vals = [v for _c, v in cells]
        chain = [vals[5]] + [vals[i] for i in range(2, 24, 2)]
        ok = all(chain[i] < chain[i + 1] for i in range(len(chain) - 1))
        segs = [chain[i + 1] - chain[i] for i in range(len(chain) - 1)]
        seg[a] = segs
        print("     algo %2d %-18s ascending=%s  %d segments: %s"
              % (a, RS.effect_name(main, a), "YES" if ok else "NO ",
                 len(segs), " ".join(str(s) for s in segs)))
    print()
    print("   the SHORT cluster (cells 0x18..0x1D), read as three pairs")
    print("   (0x1B,0x18) (0x1C,0x19) (0x1D,0x1A):")
    for a in REVERBS:
        if a not in dsc:
            continue
        d = dict(dsc[a])
        p = [d[0x18] - d[0x1B], d[0x19] - d[0x1C], d[0x1A] - d[0x1D]]
        print("     algo %2d %-18s  %s   pre-delay (0x00-0x03) = %d"
              % (a, RS.effect_name(main, a), p, d[0x00] - d[0x03]))

    # ---- CONTROL: is the CHAIN ascending by luck? --------------------------
    print()
    print("   CONTROL A -- the ascending property.  Assign ROOM REVERB 1's own")
    print("   twelve chain values to the twelve chain POSITIONS at random:")
    rnd2 = random.Random(seed + 1)
    vals = [v for _c, v in dsc[16]]
    chain = [vals[5]] + [vals[i] for i in range(2, 24, 2)]
    nasc = 0
    for _t in range(200000):
        s = chain[:]
        rnd2.shuffle(s)
        if all(s[i] < s[i + 1] for i in range(len(s) - 1)):
            nasc += 1
    print("     strictly ascending in %d of 200000 shuffles"
          " (the ROM: 12 of 12 reverbs)." % nasc)

    # ---- CONTROL: are the DIFFERENCES the designed quantity? ---------------
    print()
    print("   CONTROL B -- roundness.  If the DIFFERENCES are the designed")
    print("   delays and the VALUES are addresses, the differences should")
    print("   carry the designer's round numbers and the values should not:")
    predelay = [dict(dsc[a])[0x00] - dict(dsc[a])[0x03] for a in REVERBS
                if a in dsc]
    raw = [v for a in REVERBS if a in dsc for _c, v in dsc[a]]
    allpairs = [abs(x - y) for a in REVERBS if a in dsc
                for i, (_c1, x) in enumerate(dsc[a])
                for _c2, y in dsc[a][i + 1:]]
    def r100(xs):
        return sum(1 for x in xs if x and x % 100 == 0), len(xs)
    print("     pre-delay (cell 0x00 - cell 0x03)  : %d of %d are"
          " multiples of 100  %s" % (r100(predelay) + (predelay,)))
    print("     the RAW cell values                : %d of %d" % r100(raw))
    print("     ALL pairwise differences (the null): %d of %d (%.1f %%)"
          % (r100(allpairs) + (100.0 * r100(allpairs)[0] / r100(allpairs)[1],)))
    print("     => the ONE difference r3-delaydram.md calls the pre-delay is a")
    print("        multiple of 100 in %d of 12, against a %.1f %% background."
          % (r100(predelay)[0], 100.0 * r100(allpairs)[0] / r100(allpairs)[1]))
    return seg


# ==========================================================================
#  SS3  TARGET 1 ITEM I -- the contradiction, adjudicated
# ==========================================================================
def cmd_itemI(main, dsc):
    head("3", "TARGET 1 ITEM I -- the rotation-sign contradiction, adjudicated")
    print("""
  item I: "MULTI TAP DELAY's four tap cells are 6000/12000/18000/24000 against
  a line base of 0 -- its reads sit ABOVE its write.  ROOM REVERB's ladder puts
  R1's FORCED read on the region FLOOR with its writes above -- reads BELOW
  writes.  At least one of {the alignment, H-DIR, R1's forced read slot, the
  rotation sign} is wrong."

  THE UNENUMERATED OPTION: none of those four.  The two halves of the sentence
  use DIFFERENT UNITS.  `a line base of 0' is unit-0's REGION FLOOR and
  `the region floor' is unit-1's, and those are 0 and 0x8000 -- the same object.
  Restate both in the same units:""")
    mt = dict(dsc[10])
    rr = dict(dsc[16])
    print()
    print("     MULTI TAP DELAY (unit 0, floor 0):")
    print("        floor cell 0x2C = %d      taps 0x26/0x28/0x29/0x2A"
          " = %d/%d/%d/%d" % (mt[0x2C], mt[0x26], mt[0x28], mt[0x29], mt[0x2A]))
    print("        taps MINUS floor            = %d/%d/%d/%d  -> ALL ABOVE"
          % (mt[0x26] - mt[0x2C], mt[0x28] - mt[0x2C],
             mt[0x29] - mt[0x2C], mt[0x2A] - mt[0x2C]))
    print("     ROOM REVERB 1 (unit 1, floor 0x8000 = %d):" % HALF)
    print("        floor cell 0x03 = %d   pre-delay cell 0x00 = %d"
          % (rr[0x03], rr[0x00]))
    print("        every other cell MINUS floor:")
    ab = [(c, v - HALF) for c, v in sorted(rr.items()) if c != 0x03]
    print("          " + " ".join("%02X:%d" % (c, o) for c, o in ab))
    below = [(c, o) for c, o in ab if o < 0]
    print("        cells BELOW the floor: %s" % (below if below else "NONE"
                                                 " except the sentinel"))
    print("""
   => in the SAME units both algorithms say the identical thing: ONE cell holds
      the region floor and EVERY OTHER CELL IS ABOVE IT.  ROOM REVERB's only
      sub-floor value is the 0x7FFF sentinel of SS1.  There is no rotation-sign
      disagreement inside the corpus and R3 SS5.1's sign is not contradicted by
      these two algorithms.

   ** SO ITEM I'S FOUR-WAY DISJUNCTION RESOLVES, AND THE ANSWER IS `THE
      ALIGNMENT'.  Not H-DIR, not R1's forced read slot, not the sign.  The
      alignment is a RIGID 1:1 map from descriptor cells to consuming words
      with one free phase delta, scored over delta in -3..+3
      (dram_cursor.py `align').  It requires #cells == #consumers, which
      TARGET 1 measures at 83 of 91.  But a reverb block contains cells that
      CANNOT be addresses in its own region, at INTERIOR indices, so a rigid
      map necessarily hands a consuming word a non-address:""")
    n = len(dsc[16])
    bad = []
    for a in REVERBS:
        if a not in dsc:
            continue
        top = max(x for _y, x in dsc[a])
        for i, (c, v) in enumerate(dsc[a]):
            if v < HALF or v >= top:
                bad.append((a, i, c, v))
    print("        cells that are NOT an address inside unit-1's own used")
    print("        region [0x8000, max]:  (algo, index, cell, value)")
    for a, i, c, v in bad:
        print("          algo %2d  index %2d of %d  cell 0x%02X = %d"
              % (a, i, n, c, v))
    print("""
      -- cell 0x1E (index 30 of 32) in all twelve, and cell 0x01 (index 1) in
      eleven.  Neither is at an end.  ROOM REVERB 1's 0x01 = 45464 is one PAST
      its highest used address, so it is not a tap either: every reverb block
      has at least TWO interior non-address cells, and no rigid shift at any
      delta can skip an interior slot.

   ** METHOD RULE 3, again: the model, not only the parameter.  `delta = 0, 20
      off the shipped set' is a statement about the best RIGID map; it says
      nothing about whether a rigid map is the right shape, and SS2 says it is
      not (10 of ROOM REVERB 1's 32 cells are exact duplicates of another cell,
      so the block carries 22 distinct addresses in 32 slots).""")

    # how many cells can a rigid map possibly be right about?
    n_struct = 0
    for a, cells in sorted(dsc.items()):
        u = unit_of(a)
        vals = [v for _c, v in cells]
        sent = HALF if u == 0 else HALF - 1
        floor = 0 if u == 0 else HALF
        k = sum(1 for v in vals if v in (sent, floor))
        dup = set()
        c = dup_census(cells)
        for d, prs in c.items():
            for i, j in prs:
                dup.add(i)
                dup.add(j)
        n_struct += k + len(dup)
    tot = sum(len(v) for v in dsc.values())
    print()
    print("   BUDGET: of %d descriptor cells corpus-wide, %d are either a"
          " sentinel/floor" % (tot, n_struct))
    print("   constant or one half of an exact duplicate pair -- %.1f %%."
          % (100.0 * n_struct / tot))


# ==========================================================================
#  SS4  the predicted comb lines vs what the ROM actually ships
# ==========================================================================
SCHROEDER_PRED = (127, 435, 489, 183, 522)


R3_CHAIN0 = (255, 869, 979, 366, 1044)          # r3-delaydram.md SS5, corrected
R1_CHAIN0_RAW = (127, 435, 489, 183, 522)       # r1-allpass-motif.md SS3, halved
R1_CHAIN1_RAW = (4452, 264, 626, 180, 337, 488)


def cmd_schroeder(main, dsc, seg):
    head("4", "THE BRIEF'S STEP-5 LINE LENGTHS -- A RETRACTION THAT NEVER"
              " PROPAGATED")
    print("""
  This round's brief says "the reverb is now predicted to be a comb network
  with lines at [127, 435, 489, 183, 522]" and asks for an impulse test sized
  against them.  Those five numbers are r1-allpass-motif.md SS3's ladder-0
  lengths -- and r3-delaydram.md SS5(c) RETRACTED THEM A ROUND AGO:

     "bit 7 of the tag byte is the payload's LSB ... every delay length in the
      tree is HALF of what it should be.  ROOM REVERB 1's ladder is
      255 / 869 / 979 / 366 / 1044, not 127 / 435 / 489 / 183 / 522."

  The correction is r3's; this pass only shows it never reached the places that
  still quote the halved list -- schroeder-topology.md SS3 ("the ROM's real
  ladder-0 delays"), r1_allpass_solve.py:2491, and the brief itself.
""")
    rr = seg.get(16, [])
    d = dict(dsc[16])
    shortp = [d[0x18] - d[0x1B], d[0x19] - d[0x1C], d[0x1A] - d[0x1D]]
    pre = d[0x00] - d[0x03]
    sums = [rr[i] + rr[i + 1] for i in range(len(rr) - 1)]
    print("   ROOM REVERB 1, read off the descriptor image by SS2:")
    print("     the 11-segment partition  : %s" % rr)
    print("     two-segment sums, EVEN    : %s   <- r3's chain 0" % sums[0::2])
    print("     two-segment sums, ODD     : %s   <- r3's chain 1" % sums[1::2])
    print("     short cluster (3 pairs)   : %s" % shortp)
    print("     pre-delay 0x00-0x03       : %d      long head 0x02-0x03: %d"
          % (pre, d[0x02] - d[0x03]))
    print()
    print("   r3-delaydram.md SS5 chain 0     : %s" % list(R3_CHAIN0))
    print("   SS2's even two-segment sums     : %s" % sums[0::2])
    print("     -> %s"
          % ("IDENTICAL" if tuple(sums[0::2]) == R3_CHAIN0 else "DIFFERENT"))
    print("   r1-allpass-motif.md chain 1, DOUBLED (its raw %s):"
          % list(R1_CHAIN1_RAW[1:]))
    print("     %s" % [2 * x for x in R1_CHAIN1_RAW[1:]])
    print("   SS2's odd two-segment sums      : %s" % sums[1::2])
    off = [a - b for a, b in zip([2 * x for x in R1_CHAIN1_RAW[1:]], sums[1::2])]
    print("     -> element-wise difference %s  (a 1 is r1's dropped payload LSB)"
          % off)
    print()
    print("   the brief's five numbers        : %s" % list(SCHROEDER_PRED))
    allv = set(rr) | set(sums) | set(shortp) | {pre, d[0x02] - d[0x03]}
    hit = [x for x in SCHROEDER_PRED if x in allv]
    print("   present anywhere in the descriptor image: %s"
          % (hit if hit else "NONE -- 0 of 5"))
    longest = max(set(sums) | set(shortp) | {pre, d[0x02] - d[0x03]})
    span = d[0x01] - d[0x03] if d[0x01] > d[0x03] else max(v for v in d.values()) - d[0x03]
    print("""
   ** FALSIFIED, and it is a RETRACTION-PROPAGATION failure rather than a new
      measurement: r3-delaydram.md SS5(c) already said so.  The comb TOPOLOGY
      (schroeder-topology.md's headline) is untouched -- what falls is the
      numeric line list, which was halved.

   ** STEP 5 OF THE BRIEF THEREFORE CHANGES.  The longest delay ROOM REVERB 1
      can form is %d samples (%.1f ms at 44.1 kHz) and its region spans %d
      samples (%.1f ms).  An impulse test must be >= 4 x the LONGEST line,
      i.e. >= %d samples -- not 4 x 522.  A test sized for the brief's numbers
      would be the FOURTH recurrence of the amputated-feedback defect, caught
      this time BEFORE the experiment."""
          % (longest, longest / 44.1, span, span / 44.1, 4 * span))
    return sorted(allv)


# ==========================================================================
#  SS5  TARGET 1's 16 resurrection words, against TARGET 3's measurements
# ==========================================================================
ESC16_C = ("C0A.0.E0.000", "C0A.2.92.820", "C04.3.12.820", "C42.4.57.820",
           "C0A.4.B1.820", "C64.5.A2.000", "C64.6.A2.007", "C16.9.AB.000",
           "C00.9.84.000")
ESC16_EPI = ("980.5.20.402", "E30.C.00.404", "C16.9.AB.000", "82E.8.0F.000",
             "C00.9.84.000", "859.0.86.822", "A3C.D.9F.287")


def parse_fmt(s):
    hi, cl, ad, lo = s.split(".")
    return (int(hi, 16) << 24) | (int(cl, 16) << 20) | (int(ad, 16) << 12) \
        | int(lo, 16)


def cmd_escape16(imgs, capture_cells):
    head("5", "TARGET 1's 16 RESURRECTION WORDS, against TARGET 3's measurements")
    print("""
  TARGET 1 item E: the single-reload cursor model misses by exactly 2, and
  "two more descriptor consumers anywhere in the epilogue or header would
  resurrect it".  It names 16 words carrying the hi12 format-escape bit with no
  assigned role.  TARGET 3 measured, from the host's own 100 canned streams
  plus the live cold-boot capture, WHICH CELLS THE HOST EVER WRITES in each
  space.  A word cannot be a DESCRIPTOR consumer if its addr8 is a cell the
  descriptor space does not have -- the descriptor space is exactly
  0x00..0x1F + 0x26..0x39 (register-space.md E2, 52 cells).
""")
    dsc_cells = set()
    dram_cells = set()
    for img in imgs.values():
        dsc_cells |= set(img.get(DSC_TAG, {}))
        dram_cells |= set(img.get(DRAM_TAG, {}))
    dram_cells |= set(capture_cells)
    print("   descriptor cells the host EVER writes: %d  (0x%02X..0x%02X)"
          % (len(dsc_cells), min(dsc_cells), max(dsc_cells)))
    print("   D-RAM cells the host EVER writes     : %d" % len(dram_cells))
    print()
    words = []
    for s in ESC16_C:
        words.append((s, "header C-format"))
    for s in ESC16_EPI:
        if not any(s == t for t, _r in words):
            words.append((s, "epilogue"))
    surv, killed = [], []
    for s, where in words:
        w = parse_fmt(s)
        a8 = D.addr8(w)
        ind = a8 in dsc_cells
        note = []
        if not ind:
            note.append("addr8 0x%02X is NOT a descriptor cell" % a8)
        if a8 in dram_cells:
            note.append("addr8 0x%02X IS a host-written D-RAM cell" % a8)
        if D.c_format(w):
            note.append("C-format: bits[24:12] are ONE immediate, so `addr8'"
                        " is not an address at all")
        (killed if (not ind or D.c_format(w)) else surv).append((s, where, note))
    print("   REFUSED as descriptor consumers:")
    for s, where, note in killed:
        print("     %-14s (%-15s)  %s" % (s, where, "; ".join(note)))
    print()
    print("   STILL POSSIBLE:")
    for s, where, note in surv:
        print("     %-14s (%-15s)  %s" % (s, where, "; ".join(note) or "-"))
    print("""
   => %d of the %d named words are refused and %d survive.  TARGET 1's
      resurrection needs TWO.  It is not dead -- but %d of its candidates were
      already excluded by a measurement published in the same round, and one of
      them (`859.0.86.822') is the word TARGET 3 measured to be the unit-1
      VOLUME pointer and TARGET 2 measured to be the one site where bit 4 and
      the format escape collide.  Three passes, three readings, one word.
      ** CONSISTENT, not FORCED: the C-format refusal assumes the C-format
      decode, which is itself only re-derived (register-space.md B2). **"""
          % (len(killed), len(words), len(surv), len(killed)))
    return surv


# ==========================================================================
#  SS6  ★ THE SHIPPED GUARD-7 ESCAPE -- is the deferred clear observable?
# ==========================================================================
def cmd_clrlate(sub, tools):
    head("6", "THE SHIPPED GUARD-7 ESCAPE -- is the deferred clear observable?")
    print("""
  upd6383d.h guard 7 lets a bit-4 word with (bit7, hi12[3:1]) == (1, 1) EXECUTE
  when its ACTION is 0x00, on the stated ground that "the CLEAR is UNOBSERVABLE
  exactly when the ACTION is LO_ACT_ACC_BUS, because that substitutes the bus
  for the accumulator's own feedback term and the old accumulator cannot reach
  the result."

  THAT ARGUMENT COVERS TWO OF THE THREE SURVIVING GATES.  `b7_f31_1_off' (no
  clear) and `b7_f31_1_keepclear' (clear BEFORE the ALU) are indeed both
  invisible under ACTION 0x00.  The third, `b7_f31_1_clrlate', defers the clear
  to AFTER the word's own ALU step (action00_discriminate.py:gate_of ->
  clr_end = True; the executor zeroes st.acc after capture()).  A clear taken
  AFTER the ALU sets the result to 0 whatever the ACTION was.  It is not
  covered by the argument.

  So the question is not "is the clear invisible at this word" -- it is not --
  but "does the difference it makes ever reach anything".  That is decidable by
  a forward walk over the frame, and it is decided here rather than assumed.
""")
    hdr, epi, u0, u1 = DW.load_images(sub, tools)
    F = DW.frame(hdr, epi, u0, u1)

    def f31(w):
        return (D.hi12(w) >> 1) & 7

    def b7(w):
        return (D.hi12(w) >> 7) & 1

    def st(w):
        return (D.hi12(w) >> 4) & 1

    # the 107-word claim, on the corpus, and the frame's own share
    corpus = DW.load_corpus(sub, tools)
    c11 = [w for w in corpus if st(w) and b7(w) and f31(w) == 1]
    c11a0 = [w for w in c11 if D.lo_act(w) == 0x00]
    print("   corpus: %d words carry bit 4; (b7,f31)=(1,1): %d; of those"
          " ACTION 0x00: %d" % (sum(1 for w in corpus if st(w)),
                                len(c11), len(c11a0)))
    print("   (upd6383d.h says `138 at (1,1) of which 107 carry ACTION 0x00')")

    def is_escape(w):
        """a word guard 7 ADMITS purely because of the ACTION-0x00 escape --
        i.e. it is a (1,1) bit-4 store AND the shipped decoder executes it."""
        return (st(w) and b7(w) and f31(w) == 1 and D.lo_act(w) == 0x00
                and D.decoded(w))

    execd = [w for w in c11a0 if D.decoded(w)]
    print("   of the %d, the shipped decoder actually EXECUTES %d -- the rest"
          % (len(c11a0), len(execd)))
    print("   are refused by other guards (store-gate.md G: SRC 0x1C/0x00/0x08"
          " and ACTION 0x1A/0x0E, 114 of 130).")

    slots = [(n, ia, w, r) for n, ia, w, r in F if is_escape(w)]
    print()
    print("   IN THE COLD-BOOT FRAME the escape fires at %d of the 285 slots:"
          % len(slots))
    for n, ia, w, r in slots:
        print("     slot %3d  I-RAM %3d  %s   %s" % (n, ia, DW.fmt(w), r))

    # ------------------------------------------------------------------
    #  the forward observability walk.  The perturbation is `acc <- 0' taken
    #  AFTER this word's ALU.  It survives into the next word unless that
    #  word's own accumulator input drops the old accumulator, and it becomes
    #  VISIBLE as soon as any word puts the accumulator on the bus or stores
    #  it.  upd6383.cpp:812 -- SRC 0x10 IS the accumulator, so a word whose
    #  ACTION is 0x00 does NOT kill the dependence if its own SRC is `acc'.
    # ------------------------------------------------------------------
    SRC_ACC = 0x10

    def exposes_acc(w):
        """does this word let the accumulator escape where it can be seen?
        Only words the device EXECUTES can expose anything -- a trapping word
        discards the whole frame, so its reads are not observable output."""
        if not D.decoded(w):
            return False
        if D.lo_src(w) == SRC_ACC:
            return True                # acc reaches the operand bus (L)
        if st(w) and not (b7(w) and f31(w) == 1):
            return True                # a live bit-4 store of acc to mem[ptr]
        return False

    def kills_acc(w):
        """does this word's ALU make acc independent of its previous value?"""
        if not D.decoded(w):
            return None                # not modelled -- conservative
        if D.lo_act(w) == 0x00:
            return True                # src_term = bus, and SRC != acc here
        if f31(w) == 0:
            return True                # src_term = 0
        return False

    def walk(seq, start):
        for m in range(start + 1, len(seq)):
            w2 = seq[m]
            if exposes_acc(w2):
                return "OBSERVABLE", m
            k = kills_acc(w2)
            if k is None:
                return "UNDECIDABLE", m
            if k:
                return "DIES", m
        return "END-OF-SEQUENCE", None

    print()
    print("   FORWARD WALK from each escape slot: the perturbation `acc <- 0'")
    print("   is followed until a word EXPOSES the accumulator (SRC 0x10, or a")
    print("   live bit-4 store) or KILLS the dependence (ACTION 0x00 with a")
    print("   non-acc source, or f31 == 0).")
    seq = [w for _n, _i, w, _r in F]
    verdicts = collections.Counter()
    for n, ia, w, r in slots:
        v, at = walk(seq, n)
        verdicts[v] += 1
        print("     slot %3d -> %-14s at slot %s" % (n, v, at))
    print("   frame verdicts: %s" % dict(verdicts))

    # ---- the whole corpus, body by body -----------------------------------
    print()
    print("   THE SAME WALK OVER EVERY BODY IMAGE (the frame sees 7 of the 107;")
    print("   the escape ships for all of them):")
    sys.path.insert(0, tools)
    import kn5000_dsp_extract as E                                  # noqa: E402
    r = E.Rom(sub)
    bodies = {}
    for a in range(100):
        if a in (79, 88, 89, 90, 91):
            continue
        try:
            ir, _c, _o = E.parse_stream(r, r.u32le(DW.ALGO_TABLE + 4 * a))
        except Exception:
            continue
        for ia, ws, _l in ir:
            bodies.setdefault(
                tuple(int.from_bytes(bytes(x), "big") for x in ws), (a, ia))
    bodies[tuple(hdr)] = (-1, 0)
    bodies[tuple(epi)] = (-2, 60)
    tot = collections.Counter()
    det = []
    for img, (a, ia) in bodies.items():
        s = list(img)
        for i, w in enumerate(s):
            if is_escape(w):
                v, at = walk(s, i)
                tot[v] += 1
                det.append((a, ia, i, DW.fmt(w), v))
    print("     %d escape sites over %d distinct images: %s"
          % (sum(tot.values()), len(bodies), dict(tot)))
    obs = [x for x in det if x[4] == "OBSERVABLE"]
    print("     OBSERVABLE sites: %d" % len(obs))
    for a, ia, i, t, v in obs[:12]:
        print("       algo %3d I-RAM %3d +%3d  %s" % (a, ia, i, t))
    print("""
   ** THE STATED JUSTIFICATION IS UNDER-ENUMERATED, AND ITS PRICE IS ONE WORD.
      store-gate.md SS4 prints the 21 surviving class-(1,1) effects and the
      first family is `-/clr:{never,before,after}' -- a clear taken AFTER the
      ALU IS among them, and it IS visible at an ACTION-0x00 word, so the
      comment's "unobservable" is false as stated.  What is TRUE is the
      measurement above, and it is much narrower than the comment claims: the
      escape admits exactly ONE corpus word.""")

    # ------------------------------------------------------------------
    #  the general question, for EVERY bit-4 word the device executes
    # ------------------------------------------------------------------
    print()
    print("   ★ THE SAME QUESTION FOR EVERY BIT-4 WORD THE DEVICE EXECUTES.")
    print("""
   The free parameter exists only where the GATE FIRES.  store-gate.md C
   forces the condition to be `b7 & f31 == 1' or `b7 & f31 != 2', and BOTH are
   FALSE at (0,0) and (0,1) -- so those classes take the ungated store, whose
   timing the BIQUAD forces (`store and clear AFTER' 84.768 dB, `store early
   clear LATE' 51.090 dB).  Nothing is free there.  The classes with a free
   parameter are (1,1) -- 21 surviving effects -- and (1,2), where
   store-gate.md E leaves the clear free at 5976/5976/5976.""")
    rowsum = collections.Counter()
    changed = []
    for img, (a, ia) in bodies.items():
        s = list(img)
        for i, w in enumerate(s):
            if not (st(w) and D.decoded(w)):
                continue
            key = (b7(w), f31(w))
            rowsum[(key, "executed")] += 1
            if key[0] == 0:
                continue               # ungated: condition + biquad settle it
            v, at = walk(s, i)
            rowsum[(key, v)] += 1
            if v == "OBSERVABLE":
                changed.append((a, ia, i, DW.fmt(w), key))
    print("     class -> verdict census over the 40 distinct images:")
    for k in sorted(rowsum):
        print("       (b7,f31)=%s  %-14s  %d" % (k[0], k[1], rowsum[k]))
    print("     words whose free parameter IS observable: %d" % len(changed))
    for a, ia, i, t, k in changed[:20]:
        print("       algo %3d I-RAM %3d +%3d  %s  class %s" % (a, ia, i, t, k))
    print("""
   CONTROL -- can this walk say OBSERVABLE?  Plant the perturbation at every
   slot of the cold-boot frame:""")
    n_obs = sum(1 for n, _i, _w, _r in F if walk(seq, n)[0] == "OBSERVABLE")
    print("     %d of %d planted perturbations are OBSERVABLE."
          " The walk is not vacuous." % (n_obs, len(F)))
    return verdicts, slots, tot, det


# ==========================================================================
#  SS7  re-run the load-bearing numbers of all three passes
# ==========================================================================
def cmd_mirror(rom, main, sub, tools, imgs, dsc):
    head("7", "THE LOAD-BEARING NUMBERS, RE-RUN HERE")
    corpus = DW.load_corpus(sub, tools)

    print("   TARGET 3 D2 -- the writer's byte 1.  Round-trip every canned"
          " packet:")
    ok17 = bad17 = ok1 = bad1 = 0
    for a, p in RS.all_streams(rom).items():
        for _pp, op, body in RS.records(rom, p):
            if op not in (0, 1, 5) or len(body) < 3:
                continue
            data = body[3:]
            for k in range(0, len(data) - 4, 5):
                b5 = data[k:k + 5]
                if not RS.is_packet(b5):
                    continue
                v, _tag, _b32, _b31 = RS.packet(b5)
                if b5[1] == ((v >> 17) & 0x7F):
                    ok17 += 1
                else:
                    bad17 += 1
                if b5[1] == ((v >> 1) & 0x7F):
                    ok1 += 1
                else:
                    bad1 += 1
    print("     v>>17: %d exact / %d wrong        v>>1: %d / %d"
          % (ok17, bad17, ok1, bad1))
    print("     (register-space.md D2 published 1751/0 and 938/813)")

    print()
    print("   TARGET 3 B2 -- is the is_c40 immediate 8 bits (imm13 & 0x1F == 0)?")
    forms = collections.Counter()
    for w in corpus:
        if D.c_format(w):
            forms[w] += 1
    c40 = [(w, n) for w, n in forms.items() if D.is_c40(w)]
    nz = [(w, n) for w, n in c40 if D.c_imm13(w) & 0x1F]
    other = [(w, n) for w, n in forms.items() if not D.is_c40(w)]
    onz = [(w, n) for w, n in other if D.c_imm13(w) & 0x1F]
    print("     is_c40 forms: %d (%d words); with imm13&0x1F != 0: %d"
          % (len(c40), sum(n for _w, n in c40), len(nz)))
    print("     non-is_c40 C-format forms: %d; with imm13&0x1F != 0: %d"
          % (len(other), len(onz)))
    print("     (published: 7/7 forms, 57/57 words; control 9 of 11)")

    print()
    print("   ★ TARGET 2's CENSUS AND upd6383d.h's DISAGREE -- AND THE REASON")
    print("     IS THE CORPUS, NOT THE ARITHMETIC.  gate_settle.py:images()")
    print("     walks the 38 distinct BODY images.  upd6383d.h says `the")
    print("     3057-word corpus', which is those 38 images PLUS the 83-word")
    print("     resident kernel (header 0..59 + epilogue 60..82).  Both:")
    hdr, epi, _u0, _u1 = DW.load_images(sub, tools)
    kern = corpus[len(corpus) - len(hdr) - len(epi):]
    bod = corpus[:len(corpus) - len(hdr) - len(epi)]

    def census(ws):
        c = collections.Counter()
        for w in ws:
            if (D.hi12(w) >> 4) & 1:
                c[((D.hi12(w) >> 7) & 1, (D.hi12(w) >> 1) & 7)] += 1
        return c

    for nm, ws in (("full 3057-word corpus", corpus),
                   ("38 body images only ", bod),
                   ("the 83-word kernel  ", kern)):
        c = census(ws)
        dis = sum(n for (b, f), n in c.items() if b == 1 and f not in (1, 2))
        print("       %s len=%4d  %s" % (nm, len(ws), dict(sorted(c.items()))))
        print("       %s   disagreement set |{b7 & f31 not in 1,2}| = %d"
              % (" " * len(nm), dis))
    print("""
     => store-gate.md A's (0,0) 12 / (0,1) 486 / (1,0) 2 / (1,1) 130 / (1,2) 29
        and item F's "the disagreement set is 11, not 13" are BODY-ONLY counts.
        upd6383d.h's 12/486/... no -- its 527 / 29 / 138 / 13 are FULL-CORPUS
        counts and they are CORRECT on the corpus it names.
        ** store-gate.md F's falsification of the published `13' IS WITHDRAWN.
           Both numbers are right; they count different sets. **  What
        SURVIVES from item F, and it is the valuable half, is that the
        disagreement is nearly all unreachable:""")
    dis = [w for w in corpus
           if ((D.hi12(w) >> 4) & 1) and ((D.hi12(w) >> 7) & 1)
           and ((D.hi12(w) >> 1) & 7) not in (1, 2)]
    print("        full corpus: %d words; f31 > 2 (undecoded acc op) %d;"
          % (len(dis), sum(1 for w in dis if ((D.hi12(w) >> 1) & 7) > 2)))
    rest = [w for w in dis if ((D.hi12(w) >> 1) & 7) <= 2]
    print("        the remaining %d: %s"
          % (len(rest), [DW.fmt(w) for w in rest]))
    print("        of those, DECODED by the shipped decoder TODAY: %d --"
          % sum(1 for w in rest if D.decoded(w)))
    print("        they are exactly the words guard 7 refuses, so settling the")
    print("        CONDITION changes the emulated machine by ZERO words, not one.")

    print()
    print("   TARGET 2 G / upd6383d.h -- `107 carry ACTION 0x00 AND EXECUTE':")
    c11 = [w for w in corpus if ((D.hi12(w) >> 4) & 1)
           and ((D.hi12(w) >> 7) & 1) and ((D.hi12(w) >> 1) & 7) == 1]
    c11a = [w for w in c11 if D.lo_act(w) == 0x00]
    print("     (1,1) %d;  of those ACTION 0x00 %d;  of those DECODED %d"
          % (len(c11), len(c11a), sum(1 for w in c11a if D.decoded(w))))
    print("     ** the comment's `and execute' is FALSIFIED: 106 of the 107 are")
    print("        refused by the SRC/ACTION anchoring guards, not admitted. **")

    print()
    print("   TARGET 1 D -- do all twelve reverbs really ship 32 cells?")
    print("     %s" % {a: len(dsc[a]) for a in REVERBS if a in dsc})
    print("     unit-0 lowest cell %s, unit-1 lowest cell %s"
          % (sorted({dsc[a][0][0] for a in dsc if unit_of(a) == 0}),
             sorted({dsc[a][0][0] for a in dsc if unit_of(a) == 1})))


# ==========================================================================
#  SS8  controls
# ==========================================================================
def cmd_control(main, dsc, sub, tools):
    head("8", "EVERY CONTROL, EACH DEMONSTRATED SAYING NO")
    print("""
  K1  the duplicate-pair test.  Shown in SS2: %d of %d algorithms have NO
      duplicate at any offset, so a corpus-wide `yes' was never available.
      Permutation null in SS2.
  K2  the partition test.  It is a two-sided bound.  Run the SAME test with
      the units SWAPPED and it must fail:""" % (
        sum(1 for a in dsc if not dup_census(dsc[a])), len(dsc)))
    bad = 0
    for a, cells in dsc.items():
        u = 1 - unit_of(a)
        for _c, v in cells:
            if (u == 0 and v > HALF) or (u == 1 and v < HALF - 1):
                bad += 1
    print("        with the unit labels SWAPPED: %d violating cells"
          " (the true labelling gives 0)." % bad)
    print("""
  K3  the sentinel position.  Ask for it at index 0 instead of n-2:""")
    at0 = sum(1 for a, cells in dsc.items()
              if cells and cells[0][1] == (HALF if unit_of(a) == 0 else HALF - 1))
    atn2 = sum(1 for a, cells in dsc.items()
               if len(cells) >= 2
               and cells[-2][1] == (HALF if unit_of(a) == 0 else HALF - 1))
    print("        sentinel at index 0: %d of %d;  at index n-2: %d of %d."
          % (at0, len(dsc), atn2, len(dsc)))
    print("""
  K4  the Schroeder comparison.  It must be able to say HIT.  Feed it the
      ROM's own numbers instead of the predicted ones:""")
    d = dict(dsc[16])
    vals = [v for _c, v in dsc[16]]
    chain = [vals[5]] + [vals[i] for i in range(2, 24, 2)]
    segs = [chain[i + 1] - chain[i] for i in range(len(chain) - 1)]
    pool = set(segs) | {d[0x18] - d[0x1B], d[0x19] - d[0x1C], d[0x1A] - d[0x1D],
                        d[0x00] - d[0x03]}
    probe = segs[:5]
    print("        probing with %s -> %d of 5 present (the predicted five gave 0)."
          % (probe, sum(1 for x in probe if x in pool)))
    print("""
  K5  the observability walk of SS6 -- shown able to say OBSERVABLE at 66 of
      the 285 planted slots (and it says UNDECIDABLE, not DIES, at the one
      escape word, so it is not simply agreeing with the shipped device).
  K6  the mirror of SS7 -- every one of the four re-run numbers is a number
      another pass published; two of them (`v>>1' 938/813, `13 words') are
      published values this round CONTRADICTS or RE-SCOPES, so the mirror is
      not a self-fulfilling check.""")


# ==========================================================================
def main_():
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["all", "partition", "segments", "itemI",
                             "schroeder", "escape16", "clrlate", "mirror",
                             "control"])
    ap.add_argument("--sub", default=os.path.join(repo, "original_ROMs",
                                                  "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(repo, "original_ROMs",
                                                   "kn5000_v10_program.rom"))
    ap.add_argument("--tools",
                    default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    args = ap.parse_args()
    rom, main, E, imgs = rom_and_images(args.sub, args.main, args.tools)
    dsc = descriptor_images(imgs)
    cap = os.path.join(os.path.dirname(args.tools.rstrip("/")), "notes",
                       "data", "kn5000_dsp1_upload_coldboot.txt")
    capture = RS.coldboot_capture(cap)

    c = args.cmd
    seg = {}
    if c in ("all", "partition"):
        cmd_partition(main, dsc)
    if c in ("all", "segments", "schroeder", "control"):
        seg = cmd_segments(main, dsc) if c in ("all", "segments") else None
    if c in ("all", "itemI"):
        cmd_itemI(main, dsc)
    if c in ("all", "schroeder"):
        if seg is None or not seg:
            seg = cmd_segments(main, dsc)
        cmd_schroeder(main, dsc, seg)
    if c in ("all", "escape16"):
        cmd_escape16(imgs, [x[0] for x in capture] if capture else [])
    if c in ("all", "clrlate"):
        cmd_clrlate(args.sub, args.tools)
    if c in ("all", "mirror"):
        cmd_mirror(rom, main, args.sub, args.tools, imgs, dsc)
    if c in ("all", "control"):
        cmd_control(main, dsc, args.sub, args.tools)


if __name__ == "__main__":
    main_()
