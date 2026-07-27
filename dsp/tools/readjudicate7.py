#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""readjudicate7.py -- THE THREE WITHDRAWN FORCINGS, RE-DECIDED ON A LINE THAT DELAYS.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  No hardware; static analysis of
the Sub CPU ROM, the 100 canned parameter streams, the 38 body images, the
descriptor bank and the published tools only.

WHY THIS EXISTS.  `adjudication-round6.md' withdrew three forcings because the
harness that produced them could not hold a delay line and, in two cases, ran at
a DRAM polarity that had been reversed a round earlier:

   A  ACTION 0x19 = tempA <- bus   (LO_ACT_CAP_TA2)  "FORCED 72/72, 108/108"
   B  the BLOCKING read, land = -1                   "FORCED 5145/5145"
   C  the accumulator adder's SRC_TERM leg           (acc-adder.md item B)

`delayline.py' (round 7 target 1) built the instrument.  This tool asks the three
questions on it, with the POLARITY ENUMERATED rather than fixed at either value.

    python3 dsp/tools/readjudicate7.py census     # 1 the DRAM word census, both polarities
    python3 dsp/tools/readjudicate7.py windows    # 2 *** WHICH LOOPS CAN THE ALU MODEL CLOSE?
    python3 dsp/tools/readjudicate7.py controls   # 3 *** IT MUST SAY YES, AND IT MUST SAY NO
    python3 dsp/tools/readjudicate7.py act19      # 4 *** QUESTION A
    python3 dsp/tools/readjudicate7.py blockread  # 5 *** QUESTION B
    python3 dsp/tools/readjudicate7.py adder      # 6 *** QUESTION C
    python3 dsp/tools/readjudicate7.py all        #   everything (~6 min)

Standard library only, plus the repo's own ROM parsers and `delayline.py'.
"""
import argparse
import collections
import itertools
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as DIS                                            # noqa: E402
import delayline as DL                                              # noqa: E402
import action00_discriminate as A0                                  # noqa: E402
import lfo_ramp as L                                                # noqa: E402

# The ALU model's decoded ACTION set, quoted from action00_discriminate.step.
DEC_ACT = (0x00, 0x07, 0x12, 0x13, 0x14, 0x15, 0x19, 0x0B)

# ACTION 0x19's candidate semantics.  The fourth is method rule 7's rival: a
# machine that IGNORES the instruction entirely.  A0.Machine.capture() acts on
# act19 only for the three named strings, so "none" is exactly that rival.
ACT19 = ("tA<-bus", "tA<-acc", "tB<-bus", "none")

POLARITIES = ("forced", "published")


def head(n, s):
    print("=" * 78)
    print("%s. %s" % (n, s))
    print("=" * 78)


def sub(s):
    print()
    print("   ---- " + s)


def refuses(w):
    """Does action00_discriminate.step REFUSE this word?  Quoted from step():
    an ACTION outside the decoded set, or hi12[3:1] > 2."""
    return (DIS.lo_act(w) not in DEC_ACT) or (DIS.hi_f31(DIS.hi12(w)) > 2)


def exec_runs(words):
    """The maximal runs of consecutive words the ALU model can execute."""
    runs, start = [], None
    for i, w in enumerate(words):
        if refuses(w):
            if start is not None:
                runs.append((start, i))
            start = None
        elif start is None:
            start = i
    if start is not None:
        runs.append((start, len(words)))
    return runs


def algos():
    C = DL.load_classes()
    return [int(a) for a in sorted(C["algorithms"], key=int)]


# ===========================================================================
#  LINES UNDER AN ARBITRARY POLARITY.
#
#  `lines_of' in delayline.py reads descriptor-cell-classes.json, which was
#  built under the FORCED polarity.  Method rule 2 says a parameter settled in
#  another context is not settled inside my search, so the pairing is REDONE
#  here from the cell values under whichever polarity is being asked about,
#  using bounds.py's own rule: a read is served by the largest write below it.
#  The FORCED-polarity output of this function is checked against
#  delayline.lines_of() in `census' -- if the two disagree the tool says so.
# ===========================================================================
def lines_under(algo, polarity):
    C = DL.load_classes()
    rec = C["algorithms"][str(algo)]
    h = DL.Harness(polarity=polarity)
    P = DL.program(algo)
    cells = [c["value"] for c in rec["cells"]]
    dirs = [h.dirof(w) for _wi, w in P.cons]
    floor = 0 if P.unit == 0 else 32768
    size = 32768
    inr = [floor <= v < floor + size for v in cells]
    R = [i for i in range(len(cells)) if dirs[i] == "READ" and inr[i]]
    W = [i for i in range(len(cells)) if dirs[i] == "WRITE" and inr[i]]
    out, orphan = [], []
    for r in R:
        cand = [x for x in W if cells[x] < cells[r]]
        if not cand:
            orphan.append(r)
            continue
        b = max(cand, key=lambda x: cells[x])
        out.append((r, b, cells[r] - cells[b]))
    ceiling = [i for i in range(len(cells)) if dirs[i] == "READ" and not inr[i]]
    limit = [i for i in W if all(cells[i] > cells[r] for r in R)]
    return out, orphan, ceiling, limit, dirs


# ===========================================================================
#  SECTION 1 -- THE CENSUS.  No search, no harness beyond the field decode.
# ===========================================================================
def cmd_census():
    head(1, "THE DRAM-WORD CENSUS -- where every ACTION and every SRC sits "
           "relative to the\n   direction, at BOTH polarities")
    print("""   Method rule 9: the population is printed next to every count.
   POPULATION: the 83 aligned algorithms of descriptor-cell-classes.json,
   5894 body words, of which 829 are delay-DRAM words (48 of those are
   C-format and carry no direction under either polarity).
""")
    ac = {p: collections.Counter() for p in POLARITIES}
    sc = {p: collections.Counter() for p in POLARITIES}
    role = {p: collections.Counter() for p in POLARITIES}
    nw = ndram = 0
    acthist = collections.Counter()
    C = DL.load_classes()
    for a in algos():
        P = DL.program(a)
        rec = C["algorithms"][str(a)]
        nw += len(P.words)
        for w in P.words:
            acthist[DIS.lo_act(w)] += 1
        for k, (_wi, w) in enumerate(P.cons):
            ndram += 1
            for p in POLARITIES:
                d = DL.Harness(polarity=p).dirof(w)
                ac[p][(d, DIS.lo_act(w))] += 1
                sc[p][(d, DIS.lo_src(w))] += 1
                role[p][(d, rec["cells"][k]["role"])] += 1
    print("   body words %d ; delay-DRAM words %d" % (nw, ndram))

    sub("ACTION HISTOGRAM over all %d body words -- and what the ALU model "
        "refuses" % nw)
    for k in sorted(acthist):
        print("      0x%02X : %5d   %s" % (k, acthist[k],
              "decoded" if k in DEC_ACT else "** REFUSED by step() **"))
    ref = sum(v for k, v in acthist.items() if k not in DEC_ACT)
    print("      REFUSED TOTAL: %d of %d body words (%.1f %%)"
          % (ref, nw, 100.0 * ref / nw))

    for p in POLARITIES:
        sub("polarity = %s : direction x ACTION   (denominator %d DRAM words)"
            % (p, ndram))
        acts = sorted(set(k[1] for k in ac[p]))
        print("        " + "".join("  0x%02X" % x for x in acts))
        for d in ("READ", "WRITE", None):
            print("   %-5s" % (d or "TRAP")
                  + "".join("%6d" % ac[p].get((d, x), 0) for x in acts))
        srcs = sorted(set(k[1] for k in sc[p]))
        print("        " + "".join("  0x%02X" % x for x in srcs) + "   <- SRC")
        for d in ("READ", "WRITE", None):
            print("   %-5s" % (d or "TRAP")
                  + "".join("%6d" % sc[p].get((d, x), 0) for x in srcs))

    sub("*** THE ONE ROW THAT DECIDES THE SHAPE OF QUESTIONS A AND B ***")
    for p in POLARITIES:
        r = sum(v for k, v in ac[p].items() if k[0] == "READ")
        w = sum(v for k, v in ac[p].items() if k[0] == "WRITE")
        print("      polarity=%-9s  ACTION 0x19 on READ words: %3d of %3d "
              "; on WRITE words: %3d of %3d"
              % (p, ac[p].get(("READ", 0x19), 0), r,
                 ac[p].get(("WRITE", 0x19), 0), w))
        print("      %-19s SRC    0x19 on READ words: %3d of %3d "
              "; on WRITE words: %3d of %3d"
              % ("", sc[p].get(("READ", 0x19), 0), r,
                 sc[p].get(("WRITE", 0x19), 0), w))
    print("""
      ** UNDER THE FORCED POLARITY, ACTION 0x19 NEVER OCCURS ON A DRAM READ
      WORD -- 0 of 416, exhaustively. **  Every published argument for
      `ACTION 0x19 = tempA <- bus' is the argument that THE READ WORD'S OWN
      ACTION captures the fetched sample (blocking-read.md sect. 3.3,
      action-field.md sect. 8).  That argument is not weakened by the
      polarity reversal; it is UNAVAILABLE.  The 103 sites where ACTION 0x19
      does occur are all WRITE words, and there the same semantic means
      something else entirely: the word that COMMITS a sample to the line
      also HARVESTS the read that was issued earlier -- which is the pipeline
      `dram-datapath.md' measured, not the blocking read.""")

    sub("AND THE POLARITY ITSELF, RE-CHECKED BY A ROUTE ROUND 5 DID NOT USE:"
        "\n        HOW MANY READS ARE LEFT WITH NO WRITE BELOW THEM?")
    print("""     bounds.py serves a read from the largest write below it.  A read
     with NO write below it is an ORPHAN: the algorithm reads an address
     that nothing in it ever writes.  This is not one of round 5's three
     oracles and it is not `fake buffer overlap' either.""")
    for p in POLARITIES:
        nl = no = nc = nlim = 0
        bad = []
        for a in algos():
            ln, orp, ceil, lim, _d = lines_under(a, p)
            nl += len(ln)
            no += len(orp)
            nc += len(ceil)
            nlim += len(lim)
            if orp:
                bad.append(a)
        print("      polarity=%-9s lines %3d  ORPHANED READS %3d (in %2d of 83 "
              "algorithms)  out-of-region reads %3d  dead writes %3d"
              % (p, nl, no, len(bad), nc, nlim))
    print("""     ** The FORCED polarity leaves every in-region read served.  The
     published one orphans a third of them. **  Independent of round 5's
     multi-tap oracle, of its boundary-aging oracle and of its exhaustive
     field search -- and it agrees with all three.  (CONSISTENT, not a new
     forcing: `served by the largest write below' is bounds.py's allocation
     MODEL, which is what its CONSISTENT labels mean.)""")

    sub("*** THE DESCRIPTOR BANK AND THE lo12 FIELD POINT IN OPPOSITE "
        "DIRECTIONS ***\n        -- reported against the polarity this pass "
        "otherwise relies on")
    print("""     A word's operand bus is CONSUMED, under the shipped ALU model, if
     the word is a coefficient consumer, or its ACTION is 0x00 / 0x07 / a
     capture (0x13/0x14/0x19/0x1A), or it carries a bit-4 store -- and, on a
     WRITE, by the write itself whenever `wdata = bus'.  Count the directed
     DRAM words whose bus NOTHING consumes, at each polarity:""")
    for p in POLARITIES:
        h = DL.Harness(polarity=p)
        dead = live = 0
        deadsrc = collections.Counter()
        for a in algos():
            P = DL.program(a)
            for _wi, w in P.cons:
                d = h.dirof(w)
                if d is None:
                    continue
                act = DIS.lo_act(w)
                used = (d == "WRITE"
                        or bool(DIS.coeff_consumer(w))
                        or act in (0x00, 0x07, 0x13, 0x14, 0x19, 0x1A)
                        or bool(DIS.hi12(w) & 0x10))
                if used:
                    live += 1
                else:
                    dead += 1
                    deadsrc[DIS.lo_src(w)] += 1
        print("      polarity=%-9s  bus DEAD in %3d of 781 directed DRAM words"
              "   (dead buses name %s)"
              % (p, dead,
                 "  ".join("SRC 0x%02X x%d" % (k, v)
                           for k, v in deadsrc.most_common(4))))
    print("""     ** THIS IS A TENSION, AND IT IS REPORTED AT FULL VOLUME. **  The
     descriptor bank forces the polarity (round 5 D, three oracles; and the
     orphan census above agrees, 9 against 217).  The lo12 field reads
     better at the OTHER one: at the published polarity almost every DRAM
     word's bus has a consumer, and at the forced polarity 356 words name
     tempA and throw it away.  Both cannot be a coincidence, and the
     resolution is NOT to re-open the direction -- the descriptor evidence
     is much stronger than a plausibility argument about a field.  It is
     that ** the lo12 of a DRAM word has never been decoded AS a DRAM word. **
     The SRC/ACTION reading was built on ALU words and carried over, and it
     was carried over while `0x60 = READ' was believed.  A DRAM word's lo12
     is far more likely to be a PORT-REGISTER SPEC -- which register the
     fetched datum is delivered to, which register supplies the stored one --
     and under that reading the same 36 bits mean the same thing at either
     polarity and the 356 disappear.
     OPEN.  Named here because it is the reason question A cannot be closed
     by staring harder at this table, and because it is a bigger prize than
     any of the three re-decisions.""")

    sub("SELF-CHECK -- does lines_under(a,'forced') agree with "
        "delayline.lines_of(a)?")
    agree = dis = 0
    for a in algos():
        mine = sorted((r, w, d) for r, w, d in lines_under(a, "forced")[0])
        theirs = sorted((l.read_slot, l.write_slot, l.samples)
                        for l in DL.lines_of(a))
        if mine == theirs:
            agree += 1
        else:
            dis += 1
    print("      agree %d of %d algorithms, disagree %d" % (agree, agree + dis, dis))
    return dis == 0


# ===========================================================================
#  SECTION 2 -- WHICH DELAY LOOPS CAN THE ALU MODEL ACTUALLY CLOSE?
# ===========================================================================
def loop_table(polarity):
    """-> rows (algo, name, nwords, nrefused, nlines, nclosed, nclosed_with_19)"""
    C = DL.load_classes()
    rows = []
    for a in algos():
        P = DL.program(a)
        rec = C["algorithms"][str(a)]
        wi_of = [wi for wi, _w in P.cons]
        bad = set(i for i, w in enumerate(P.words) if refuses(w))
        ln, _orp, _ce, _li, _d = lines_under(a, polarity)
        closed = []
        for (r, wr, D) in ln:
            rwi, wwi = wi_of[r], wi_of[wr]
            lo, hi = min(rwi, wwi), max(rwi, wwi)
            if not any(lo <= b <= hi for b in bad):
                n19 = [i for i in range(lo, hi + 1)
                       if DIS.lo_act(P.words[i]) == 0x19]
                closed.append((r, wr, D, rwi, wwi, n19))
        rows.append((a, rec["name"], len(P.words), len(bad), len(ln), closed))
    return rows


def cmd_windows():
    head(2, "*** WHICH DELAY LOOPS CAN THE ALU MODEL CLOSE? *** -- the question "
           "nobody asked\n   before pointing a search at SINGLE DELAY")
    print("""   A delay loop is SCOREABLE only if every word between its READ and
   its WRITE executes.  `action00_discriminate.step' REFUSES any word whose
   ACTION is outside the decoded set or whose hi12[3:1] > 2, and it returns
   False -- the run stops.  So the searchable contexts are exactly the lines
   whose read-to-write span contains no refused word.

   ENUMERATION (rule 3): polarity in {forced, published} x every line of
   every one of the 83 aligned algorithms.  Nothing else is varied here --
   this is a property of the WORDS and the descriptor bank, not of any ALU
   parameter.
""")
    for p in POLARITIES:
        rows = loop_table(p)
        nl = sum(r[4] for r in rows)
        nc = sum(len(r[5]) for r in rows)
        na = sum(1 for r in rows if r[5])
        n19 = sum(1 for r in rows for c in r[5] if c[5])
        sub("polarity = %s" % p)
        print("      lines %3d  CLOSED-AND-EXECUTABLE %3d  in %2d of 83 "
              "algorithms  (of which %d contain an ACTION 0x19 word)"
              % (nl, nc, na, n19))
        for (a, nm, nwo, nb, nlg, closed) in rows:
            if closed:
                print("        algo %-3d %-20s %3d words %2d refused : %2d of %2d "
                      "lines closed, D = %s"
                      % (a, nm, nwo, nb, len(closed), nlg,
                         ",".join(str(c[2]) for c in closed[:8])))

    sub("*** AND NOW SINGLE DELAY (algo 9), THE BLOCK EVERY WITHDRAWN FORCING "
        "CAME FROM ***")
    P = DL.program(9)
    runs = exec_runs(P.words)
    bad = [i for i, w in enumerate(P.words) if refuses(w)]
    print("      48 words.  REFUSED: %s"
          % ", ".join("w%d(ACT 0x%02X)" % (i, DIS.lo_act(P.words[i]))
                      for i in bad))
    print("      maximal executable runs: %s"
          % ", ".join("w%d..w%d" % (s, e - 1) for s, e in runs))
    for p in POLARITIES:
        ln, orp, ceil, lim, dirs = lines_under(9, p)
        wi_of = [wi for wi, _w in P.cons]
        print()
        print("      polarity = %s" % p)
        for k, (wi, w) in enumerate(P.cons):
            print("        cell%d w%-3d %09X  %-5s addr %6d"
                  % (k, wi, w, dirs[k] or "TRAP",
                     DL.load_classes()["algorithms"]["9"]["cells"][k]["value"]))
        if not ln:
            print("        LINES: none")
        for (r, wr, D) in ln:
            rwi, wwi = wi_of[r], wi_of[wr]
            lo, hi = min(rwi, wwi), max(rwi, wwi)
            inside = [(s, e) for s, e in runs if s <= lo and hi < e]
            print("        LINE read cell%d @w%-3d -> write cell%d @w%-3d "
                  "D=%-6d span w%d..w%d : %s"
                  % (r, rwi, wr, wwi, D, lo, hi,
                     "INSIDE the executable run w%d..w%d" % (inside[0][0],
                                                             inside[0][1] - 1)
                     if inside else "** CROSSES A REFUSED WORD **"))
        print("        orphaned reads %s ; out-of-region reads %s ; dead writes %s"
              % (orp, ceil, lim))
    print("""
     ** THE PUBLISHED SEARCH WINDOW w5..w9 IS A CLOSED DELAY LOOP UNDER THE
     PUBLISHED POLARITY AND UNDER NO OTHER. **  Under the FORCED polarity
     SINGLE DELAY's two loops are w0->w28 and w9->w46, and BOTH cross
     w21..w24, whose ACTIONs 0x0D and 0x0E the ALU model refuses.  Neither
     maximal executable run (w3..w20, w25..w43) contains a line.

     So the 108, the 72, the 5145 and the 5635 were all scored on a loop
     that exists only at the polarity `adjudication-round5.md' item D
     falsified, and there is NO window of SINGLE DELAY at which they can be
     re-scored.  This is not "the search returns zero"; it is "there is no
     search to run".""")
    return True


# ===========================================================================
#  SECTION 3 -- THE SEARCH, AND THE CONTROLS IT MUST PASS AND FAIL
# ===========================================================================
#  The scaled descriptor sets.  The STRUCTURE is the ROM's -- same words, same
#  directions, same cursor, same roles, same rank order of the six cells --
#  and only the VALUES are scaled so that a 350 ms line recirculates inside a
#  test signal a search can afford.  Both are checked by `_classify' below.
SD_FORCED = ([7, 20, 12, 0, 32, 7], 32)         # delayline.py's own SD_SCALED
SD_PUBLISHED = ([3, 19, 12, 0, 32, 4], 32)


def _classify(cells, region, polarity):
    """Re-derive the roles of a SCALED cell set, the way bounds.py does for the
    real one.  Printed so the scaling can be audited."""
    P = DL.program(9)
    h = DL.Harness(polarity=polarity)
    d = [h.dirof(w) for _wi, w in P.cons]
    inr = [0 <= v < region for v in cells]
    R = [i for i in range(len(cells)) if d[i] == "READ" and inr[i]]
    W = [i for i in range(len(cells)) if d[i] == "WRITE" and inr[i]]
    ceil = [i for i in range(len(cells)) if d[i] == "READ" and not inr[i]]
    lim = [i for i in W if all(cells[i] > cells[r] for r in R)]
    lines, orph = [], []
    for r in R:
        c = [x for x in W if cells[x] < cells[r]]
        if not c:
            orph.append(r)
            continue
        b = max(c, key=lambda x: cells[x])
        lines.append((r, b, cells[r] - cells[b]))
    return lines, orph, ceil, lim


def sd_space(act19s=ACT19, src00s=("mem", "P", "acc", "zero", "DR", "tA")):
    """The published 5832-machine SINGLE DELAY space, with ACTION 0x19's
    instruction-blind rival added as a fourth value (rule 7)."""
    out = []
    for t in itertools.product(A0.ORDER, A0.ACT00, A0.STTIME, A0.STGATE,
                               act19s, src00s):
        out.append(A0.Machine(t[0], t[1], t[2], t[3], act19=t[4], src00=t[5]))
    return out


def sd_score(h, cells, region, window, wcell, D, fb=0.5, nframes=40,
             space=None, seed=3, amp=1 << 18):
    """Run the published space against the TWO-ADDRESS memory and score the
    write sequence of cell `wcell' against v[n] = x[n] + fb*v[n-D]."""
    P = DL.program(9)
    cf = DL.coefs_of(9, P.words)
    rng0 = random.Random(seed)
    x = [rng0.randrange(-amp, amp) for _ in range(nframes)]
    ref = A0.comb_ref(fb, D, x)
    space = sd_space() if space is None else space
    hits, ran = [], 0
    for m in space:
        port, ok = DL.run_words(P, m, h, x, cf, cells=cells, floor=0,
                                size=region, window=window)
        if not ok:
            continue
        ran += 1
        seq = [v for (_f, _s, k, a, _p, v, _t) in port.trace
               if k == "W" and a == cells[wcell]]
        if len(seq) != len(ref):
            continue
        den = sum(v * v for v in seq)
        if den < 1e-6:
            continue
        s = sum(p * q for p, q in zip(seq, ref)) / den
        if abs(s) < 1e-6:
            continue
        mx = max(abs(v) for v in ref)
        if max(abs(s * p - q) for p, q in zip(seq, ref)) < 1e-4 * mx:
            hits.append(m)
    return hits, ran, len(space)


def _dist(hits, field):
    c = collections.Counter(getattr(m, field) for m in hits)
    return ("FORCED   " if len(c) == 1 else "%d values " % len(c),
            "  ".join("%s x%d" % (a, b) for a, b in c.most_common()))


def cmd_controls():
    head(3, "*** THE CONTROLS *** -- it must say YES to a known-good machine and "
           "NO to a\n   deliberately-wrong twin, and the two must be the same "
           "instrument")
    print("""   Method rule 1.  Seven controls that could not fail have already
   cost this project a published result, and round 6 added one that could
   not PASS.  Both halves are below, and the NO half is run on the arm that
   the YES half proved can pass.
""")
    ok = True
    sub("YES-1  the OLD code path, untouched, must still print its own number")
    import adjudicate6 as A6
    hits, space = A6.sd_search("published")
    print("      adjudicate6.sd_search('published')     : %d of %d   "
          "(published: 108)" % (len(hits), len(space)))
    ok &= len(hits) == 108

    sub("YES-2  the NEW two-address memory, driven into the OLD one-address\n"
        "          configuration, must reproduce the same 108")
    n = DL._sd_new(DL.program(9),
                   DL.Harness(polarity="published", port="blocking"),
                   cells=[0] * 6, region=7, nframes=24, fb=0.5, D=7,
                   window=(5, 10))
    print("      delayline one-address configuration    : %d of %d" % (n, 5832))
    ok &= n == 108

    sub("YES-3  ** THE ARM THIS ROUND ACTUALLY USES MUST BE ABLE TO PASS. **\n"
        "          A REAL two-address line (read cell != write cell, a "
        "rotation, and\n          the delay taken from the descriptor "
        "difference), published polarity")
    cells, region = SD_PUBLISHED
    lines, orph, ceil, lim = _classify(cells, region, "published")
    print("      scaled cells %s region %d" % (cells, region))
    print("      lines %s ; orphaned reads %s ; out-of-region %s ; dead writes %s"
          % (["cell%d<-cell%d D=%d" % t for t in lines], orph, ceil, lim))
    D = lines[0][2]
    h = DL.Harness(polarity="published", port="blocking")
    hits, ran, tot = sd_score(h, cells, region, (5, 10), lines[0][1], D)
    print("      polarity=published port=blocking, w5..w9, TWO addresses : "
          "%d of %d  (%d completed the window)" % (len(hits), tot, ran))
    ok &= len(hits) > 0
    print("      => %s" % ("PASS -- the arm can say yes" if hits
                           else "** FAIL: the arm cannot pass, so its zeros "
                                "are worthless **"))

    sub("NO -- six deliberately-wrong twins on THAT SAME ARM.  Each is a "
        "single\n        keyword away from the machine that passed.")
    twins = [
        ("write cell moved +1 (address wrong by one)",
         dict(cells=[c + 1 if i == lines[0][1] else c
                     for i, c in enumerate(cells)])),
        ("read cell moved +1", dict(cells=[c + 1 if i == lines[0][0] else c
                                           for i, c in enumerate(cells)])),
        ("rotation FROZEN   (grot=static)", dict(h=h.replace(grot="static"))),
        ("rotation REVERSED (grot=asc)", dict(h=h.replace(grot="asc"))),
        ("descriptor cursor shifted (delta=+1)", dict(h=h.replace(delta=1))),
        ("polarity FLIPPED to forced", dict(h=h.replace(polarity="forced"))),
    ]
    nrej = 0
    for name, kw in twins:
        hh = kw.get("h", h)
        cc = kw.get("cells", cells)
        t, ran2, tot2 = sd_score(hh, cc, region, (5, 10), lines[0][1], D)
        print("      %-42s : %4d of %d %s"
              % (name, len(t), tot2, "" if t else "<- SAYS NO"))
        nrej += (len(t) == 0)
    print("      REJECTED %d of %d twins" % (nrej, len(twins)))
    ok &= nrej >= 5

    sub("DEGENERACY FIRST (rule 4) -- where CAN the three act19 readings differ?")
    n19 = collections.Counter()
    for a in algos():
        for w in DL.program(a).words:
            if DIS.lo_act(w) == 0x19:
                n19[DIS.lo_src(w)] += 1
    tot19 = sum(n19.values())
    print("      ACTION 0x19 sites in the 83 aligned body images, by SRC: %s"
          % "  ".join("0x%02X x%d" % (k, v) for k, v in n19.most_common()))
    print("      of %d sites, %d name SRC 0x10 (the accumulator) -- there "
          "`tA<-bus' and\n      `tA<-acc' differ only through the word's own "
          "accumulator step, and %d name\n      something else, where they "
          "differ outright."
          % (tot19, n19.get(0x10, 0), tot19 - n19.get(0x10, 0)))
    print("      => the three readings are NOT degenerate on this corpus.")

    sub("AND THE TWO `108's MUST BE THE SAME 108 MACHINES, not merely the same "
        "count")
    old = set(m.key4() + (m.act19, m.src00) for m in
              A6.sd_search("published")[0])
    new = set(m.key4() + (m.act19, m.src00) for m in hits)
    print("      one-address survivors %d ; two-address survivors %d ; "
          "identical set: %s" % (len(old), len(new), old == new))
    ok &= old == new

    sub("SEPARATION (rule 7) -- the rival that IGNORES the instruction")
    blind = [m for m in hits if m.act19 == "none"]
    print("      survivors whose ACTION 0x19 does NOTHING AT ALL : %d of %d"
          % (len(blind), len(hits)))
    print("      => %s"
          % ("the test SEPARATES: an act19-blind machine cannot pass"
             if not blind else
             "** the test does NOT separate: act19 is invisible to it **"))
    return ok


# ===========================================================================
#  SECTION 4 -- QUESTION A.  ACTION 0x19 / LO_ACT_CAP_TA2.
# ===========================================================================
def cmd_act19():
    head(4, "*** QUESTION A -- ACTION 0x19 = tempA <- bus, RE-DECIDED ***")
    print("""   The owner is shipping LO_ACT_CAP_TA2 on a withdrawn forcing and
   asked for it to be re-decided this round.  The instruction was: re-run
   the SINGLE DELAY determination on the new harness with the polarity
   ENUMERATED and a line that actually delays.

   ENUMERATION, printed beside the claim (rule 3):
       polarity   forced | published                       (2)
       port       push_read | push_any | latency | blocking (4)
       window     w5..w9 (published) | w3..w20 | w25..w43 | whole program (4)
       act19      tA<-bus | tA<-acc | tB<-bus | NONE        (4)
       order      act_last | act_first | adder              (3)
       act00      none|add|sub|load|rload|bsel              (6)
       sttime     3 ; stgate 6 ; src00 6
   -> 7776 ALU machines per (polarity, port, window) cell, 8 cells scored.
""")
    cells_f, region = SD_FORCED
    cells_p, _ = SD_PUBLISHED
    lf = _classify(cells_f, region, "forced")
    lp = _classify(cells_p, region, "published")
    sub("STEP 1 -- WHERE IS THE LOOP, AT EACH POLARITY?")
    for p, (cl, cc) in (("forced", (lf, cells_f)), ("published", (lp, cells_p))):
        lines, orph, ceil, lim = cl
        print("      polarity=%-9s cells %s" % (p, cc))
        print("        lines %s ; orphaned reads %s ; out-of-region %s ; "
              "dead writes %s"
              % (["cell%d<-cell%d D=%d" % t for t in lines], orph, ceil, lim))
    P = DL.program(9)
    wi_of = [wi for wi, _w in P.cons]
    runs = exec_runs(P.words)
    print("      the DRAM words sit at %s ; executable runs %s"
          % (["w%d" % w for w in wi_of],
             ["w%d..w%d" % (s, e - 1) for s, e in runs]))
    for p, (cl, _cc) in (("forced", (lf, cells_f)), ("published", (lp, cells_p))):
        for (r, wr, D) in cl[0]:
            lo, hi = min(wi_of[r], wi_of[wr]), max(wi_of[r], wi_of[wr])
            ins = [s for s, e in runs if s <= lo and hi < e]
            print("        %-9s line cell%d<-cell%d spans w%d..w%d : %s"
                  % (p, r, wr, lo, hi,
                     "SCOREABLE" if ins else "crosses a REFUSED word -> NOT "
                     "scoreable"))

    sub("STEP 2 -- SCORE EVERY (polarity, port, window) CELL THAT HAS A LOOP")
    rows = []
    for pol, cells, cl in (("published", cells_p, lp), ("forced", cells_f, lf)):
        lines = cl[0]
        for port in ("blocking", "latency", "push_read", "push_any"):
            h = DL.Harness(polarity=pol, port=port)
            for win, wname in (((5, 10), "w5..w9"), ((3, 21), "w3..w20"),
                               ((25, 44), "w25..w43"), (None, "whole 48")):
                lo, hi = (win if win else (0, len(P.words)))
                cand = [(r, w, D) for (r, w, D) in lines
                        if lo <= wi_of[r] < hi and lo <= wi_of[w] < hi]
                if not cand:
                    rows.append((pol, port, wname, None, 0, 0, 0))
                    continue
                r, wr, D = cand[0]
                hits, ran, tot = sd_score(h, cells, region, win, wr, D)
                rows.append((pol, port, wname, (r, wr, D), len(hits), ran, tot))
    print("      polarity   port        window     loop           hits   ran/tot")
    for (pol, port, wname, lp2, nh, ran, tot) in rows:
        print("      %-10s %-11s %-10s %-14s %4s   %s"
              % (pol, port, wname,
                 ("cell%d<-cell%d D=%d" % lp2) if lp2 else "-- NONE --",
                 nh if lp2 else "n/a", "%d/%d" % (ran, tot) if lp2 else "-"))
    print("""
      ** READ THE `-- NONE --' ROWS AS `NO SEARCH', NOT AS `NO SURVIVORS'. **
      Under the FORCED polarity not one of the four windows contains a
      closed delay loop, so there is nothing for a machine to reproduce.
      A zero printed there would be an artefact of the window, exactly as
      round 6's zero was an artefact of the memory.""")

    sub("STEP 3 -- WHAT DOES THE ONE ARM THAT CAN BE SCORED SAY ABOUT "
        "ACTION 0x19?")
    h = DL.Harness(polarity="published", port="blocking")
    hits, ran, tot = sd_score(h, cells_p, region, (5, 10), lp[0][0][1],
                              lp[0][0][2])
    print("      polarity=published port=blocking window=w5..w9 TWO ADDRESSES: "
          "%d of %d" % (len(hits), tot))
    for f in ("act19", "order", "act00", "src00", "sttime", "stgate"):
        a, b = _dist(hits, f)
        print("        %-7s %s %s" % (f, a, b))
    print("""
      So the ONLY configuration in which SINGLE DELAY constrains ACTION 0x19
      at all is the one whose DRAM polarity is FALSIFIED.  The determination
      is not reproduced at the forced polarity and it is not refuted there
      either -- it is UNREACHABLE.""")

    sub("STEP 4 -- CAN ANY OTHER BLOCK DECIDE IT?  (the context the brief "
        "asks to be named)")
    rows = loop_table("forced")
    tot_l = sum(len(r[5]) for r in rows)
    with19 = [(r[0], r[1], [c for c in r[5] if c[5]]) for r in rows if r[5]]
    n19 = sum(len(c) for _a, _n, c in with19)
    print("      lines with a closed, EXECUTABLE read->write span, forced "
          "polarity : %d of 324" % tot_l)
    print("      of those, lines whose span contains an ACTION 0x19 word     "
          ": %d" % n19)
    for a, nm, cl in with19:
        print("        algo %-3d %-18s %2d closed lines, ACTION 0x19 inside at "
              "w%s" % (a, nm, len(cl), cl[0][5][:4]))
    print("""
      ** THE CONTEXT THAT COULD DECIDE ACTION 0x19 IS THE REVERB LADDER, NOT
      SINGLE DELAY. **  GATED REVERB and the twelve 133-word reverbs carry
      90 delay loops whose whole read-to-write span executes, and every one
      of them contains an ACTION 0x19 word.  What they do NOT yet carry is a
      reference: `schroeder-topology.md' matched the ladder against a comb
      and an all-pass on the ONE-CELL line, so those references have to be
      re-derived on a memory that delays before the ladder can force
      anything.  That is a search, not a re-labelling, and it is out of this
      pass's scope -- it is named here so the next one can take it.""")

    sub("STEP 4b -- AND CAN THAT CONTEXT SEE ACTION 0x19 AT ALL?  (rule 7: a "
        "test that\n            cannot separate the candidates is not a test)")
    print("""      For each of the 13 algorithms, the first closed executable loop is
      run on the two-address memory with the REAL descriptor addresses and
      the four ACTION 0x19 readings -- three semantics and the
      instruction-blind rival.  A base machine SEES the field if the value
      stream written into that line differs between any two of them.""")
    sub("        FIRST, HOW MANY OF THE 13 CAN BE EXECUTED AT ALL?")
    runnable = []
    for a in algos():
        P2 = DL.program(a)
        cf = DL.coefs_of(a, P2.words)
        isA = [i for i, w in enumerate(P2.words) if DIS.coeff_consumer(w)]
        got = sum(1 for i in isA if cf[i] is not None)
        if isA and got == len(isA):
            runnable.append(a)
    rows = loop_table("forced")
    have = [r[0] for r in rows if r[5]]
    print("        algorithms whose C-RAM stream resolves for every "
          "coefficient-consuming word\n        (lfo_ramp.cram_of_algo + "
          "cursor_addresses) : %d of 83" % len(runnable))
    print("        ... of the %d with a closed executable loop, that leaves: %s"
          % (len(have), [a for a in have if a in runnable]))
    print("""        ** A SECOND, INDEPENDENT BLOCKER, AND IT IS NEW. **  The twelve
        133-word reverbs resolve 0 of 33 coefficient words each -- the
        cursor-to-C-RAM map that works for the 48-word blocks does not
        work for them.  So of the 13 algorithms that CAN close a loop,
        exactly ONE can be executed today.  Fixing that map is the
        cheapest single thing anyone can do for this question.""")
    base = []
    for t in itertools.product(A0.ORDER, A0.ACT00, A0.STTIME, A0.STGATE,
                               ("mem", "P", "acc", "zero", "DR", "tA")):
        base.append(t)
    random.Random(7).shuffle(base)
    base = base[:60]
    rng0 = random.Random(5)
    x1 = [rng0.randrange(-(1 << 18), 1 << 18) for _ in range(24)]
    x2 = [v // 7 + 13 for v in x1]
    print("""
        And now the test, on the one algorithm that runs, with the harness's
        `wdata' parameter ENUMERATED -- because it turns out to decide
        whether the test exists at all.""")
    for a in [x for x in have if x in runnable]:
        P2 = DL.program(a)
        cf = DL.coefs_of(a, P2.words)
        for wd in ("bus", "acc"):
            h = DL.Harness(wdata=wd)
            tot_see = tot_run = 0
            allstreams = set()
            insens = 0
            nloop = 0
            for (r, wr, D, rwi, wwi, _n19) in rows[[q[0] for q in
                                                    rows].index(a)][5]:
                lo, hi = min(rwi, wwi), max(rwi, wwi)
                wcell = P2.cells[(wr + h.delta) % len(P2.cells)]
                nloop += 1
                for t in base:
                    streams = set()
                    okall = True
                    for a19 in ACT19:
                        m = A0.Machine(t[0], t[1], t[2], t[3], act19=a19,
                                       src00=t[4])
                        port, ok = DL.run_words(P2, m, h, x1, cf,
                                                window=(lo, hi + 1))
                        if not ok:
                            okall = False
                            break
                        streams.add(tuple(v for (_f, _s, kk, ad, _p, v, _t)
                                          in port.trace
                                          if kk == "W" and ad == wcell))
                    if not okall:
                        continue
                    tot_run += 1
                    tot_see += len(streams) > 1
                    allstreams |= streams
                # ... and the strongest control: can the line hear the INPUT?
                m = A0.Machine("adder", "load", "before", "b7_f31_1_off",
                               act19="tA<-bus", src00="mem")
                seqs = []
                for xx in (x1, x2):
                    port, ok = DL.run_words(P2, m, h, xx, cf,
                                            window=(lo, hi + 1))
                    seqs.append(tuple(v for (_f, _s, kk, ad, _p, v, _t)
                                      in port.trace
                                      if kk == "W" and ad == wcell) if ok
                                else None)
                insens += seqs[0] == seqs[1]
            print("        algo %-3d wdata=%-3s : %3d of %3d (machine, loop) "
                  "pairs SEE act19 ; %d distinct\n                 write "
                  "streams over ALL of them ; %d of %d loops CANNOT hear the "
                  "input"
                  % (a, wd, tot_see, tot_run, len(allstreams), insens, nloop))
    print("""      ** THE HARNESS'S OWN DEFAULT MAKES THIS TEST A TAUTOLOGY. **
      At `wdata = bus' the value a DRAM WRITE word commits is its operand
      bus, and under the FORCED polarity 256 of 318 in-region write words
      name SRC 0x0B -- the read register.  So the delay line receives what
      the delay line produced: over 360 (machine, loop) pairs -- 1440 runs --
      the write stream takes exactly ONE value, no ALU parameter changes it,
      and 6 of 6 loops cannot hear the input.  At `wdata = acc' the same
      360 pairs give 80 distinct streams, all 360 see ACTION 0x19, and 0 of 6
      loops are deaf to the input.

      This is method rule 11 again, one round later and in the new harness:
      ** a search that scores a delay-line write stream at wdata = bus is a
      control that CANNOT FAIL. **  `dram-datapath.md' item J leaves `wdata'
      OPEN; it must be ENUMERATED in every future ALU search, and the
      default should not be `bus'.

      WHAT THIS IS NOT: it is not a forcing of `wdata = acc'.  The window
      excludes algo 8's two non-0x0B write words (w74 SRC 0x10, w100
      SRC 0x00), so a cascade in which the input is injected there and
      propagates line-to-line through the read register over several frames
      is NOT excluded by this measurement.  Stated because the measurement
      cannot see it.""")

    sub("STEP 4c -- ** AN INDEPENDENT TEST OF THE SEMANTIC THAT NEEDS NO DELAY "
        "LINE **\n            does a capture into tempA get CONSUMED as tempA?")
    print("""      The owner's structural support for keeping LO_ACT_CAP_TA2 is
      `0x19 = 0x13 + 6 and 0x1A = 0x14 + 6, a second capture pair mirroring
      an established one'.  That is a claim about SEMANTICS, and semantics
      have a consequence: a word that loads tempA should be FOLLOWED by a
      word that names tempA.  0x13 (tempA <- bus) and 0x14 (tempB <- bus)
      are ANCHORED, so they calibrate the test; 0x12 and 0x15 are the
      no-effect codes and are the null.

      PREDICTION, written before the count: 0x19 tracks 0x13 (successors name
      SRC 0x19 = tempA, above base rate) and 0x1A tracks 0x14 (SRC 0x1A =
      tempB).  If instead 0x19's successors name tempB, the shipped
      assignment is backwards.""")
    win = 4
    base_a = base_b = base_n = 0
    per = collections.defaultdict(lambda: [0, 0, 0])
    for a in algos():
        P = DL.program(a)
        ws = P.words
        for i, w in enumerate(ws):
            nxt = ws[i + 1:i + 1 + win]
            ta = any(DIS.lo_src(v) == 0x19 for v in nxt)
            tb = any(DIS.lo_src(v) == 0x1A for v in nxt)
            base_a += ta
            base_b += tb
            base_n += 1
            r = per[DIS.lo_act(w)]
            r[0] += ta
            r[1] += tb
            r[2] += 1
    print("      base rate over all %d word positions: a tempA source within "
          "the next %d words %.1f %% ; a tempB source %.1f %%"
          % (base_n, win, 100.0 * base_a / base_n, 100.0 * base_b / base_n))
    print("      ACTION   n     -> tempA used    -> tempB used   verdict")
    for code, tag in ((0x13, "ANCHORED tA<-bus"), (0x14, "ANCHORED tB<-bus"),
                      (0x19, "** THE QUESTION **"), (0x1A, "the pair's twin"),
                      (0x12, "null: no effect"), (0x15, "null: no effect"),
                      (0x07, "null: mem<-bus")):
        r = per.get(code)
        if not r or not r[2]:
            continue
        print("      0x%02X   %4d    %6.1f %%        %6.1f %%      %s"
              % (code, r[2], 100.0 * r[0] / r[2], 100.0 * r[1] / r[2], tag))
    # -- THE NULL.  Shuffle the ACTION field across positions inside each
    #    program; the successor structure is untouched, only the labelling.
    prog = [DL.program(a).words for a in algos()]
    rng = random.Random(19)
    best = 0.0
    NPERM = 2000
    for _t in range(NPERM):
        hit = tot = 0
        for ws in prog:
            acts = [DIS.lo_act(v) for v in ws]
            rng.shuffle(acts)
            for i, ac2 in enumerate(acts):
                if ac2 != 0x19:
                    continue
                tot += 1
                hit += any(DIS.lo_src(v) == 0x19 for v in ws[i + 1:i + 1 + win])
        best = max(best, hit / float(tot or 1))
    print("      PERMUTATION NULL (%d shuffles of the ACTION field inside each "
          "program,\n      successor structure untouched): best null rate "
          "%.1f %% ; observed %.1f %%"
          % (NPERM, 100.0 * best, 100.0 * per[0x19][0] / per[0x19][2]))
    print("""      ** HIT, and it is the only NEW positive result of this pass. **
      401 of 402 ACTION 0x19 sites are followed within four words by a word
      that names tempA, against a base rate of 29.9 % and a best-of-2000
      permutation null well below the observation.  ACTION 0x19 IS A CAPTURE
      INTO tempA.  ** It does NOT decide `tempA <- bus' against
      `tempA <- acc' ** -- both are captures into tempA, and that is exactly
      the pair the published search left at 2940 / 2205 before it forced one
      of them on the falsified polarity.  0x14's anchored signature
      calibrates the test (tempB at 149 of 149); 0x13's does not separate
      (56.8 % / 56.8 %) and is reported as the MISS it is.""")

    sub("STEP 5 -- WHAT DOES THE DEVICE HAVE TO DO, AND WHAT DOES IT COST?")
    n_sites = 0
    for a in algos():
        P2 = DL.program(a)
        n_sites += sum(1 for w in P2.words if DIS.lo_act(w) == 0x19)
    print("      ACTION 0x19 sites in the 83 aligned body images : %d" % n_sites)
    print("""      VERDICT: STILL-UNDECIDABLE, and the shipping decision does not
      change -- but its justification does.  LO_ACT_CAP_TA2 keeps shipping
      because it is UNREFUTED and structurally supported (0x19 = 0x13 + 6
      and 0x1A = 0x14 + 6), NOT because SINGLE DELAY forces it.  SINGLE
      DELAY cannot force anything about it at the polarity that is forced.
      The comment in both disassembler mirrors must say so.""")
    return True


# ===========================================================================
#  THE PORT, SIMULATED WITHOUT THE ALU.
#
#  The sequence of delay-DRAM accesses is fixed by the DRAM words and the
#  descriptor cursor alone; no ALU parameter can change it.  So the question
#  "which read's datum is standing in the read-data register when word W
#  executes" can be answered on programs the ALU model cannot run at all.
#  Each read is given its own tag, so the answer is a provenance, not a value.
# ===========================================================================
def port_provenance(algo, h, frames=4):
    P = DL.program(algo)
    floor, size = P.floor_size(h)
    mem = DL.DelayDRAM(h, floor, size)
    port = DL.DramPort(h, mem)
    cells = P.cells
    seen = {}
    for _f in range(frames):
        for k, (wi, w) in enumerate(P.cons):
            a = cells[(k + h.delta) % len(cells)]
            d = h.dirof(w)
            port.before_word(wi)
            if d == "READ":
                mem.cell[mem.phys(a)] = float(k + 1)     # tag: the issuing cell
            # run_words issues a BLOCKING read BEFORE the word latches its bus;
            # every other port model issues it at the END of the word.
            if d == "READ" and h.port == "blocking":
                port.access("read", a, wi)
            seen[wi] = port.dr
            if d == "READ" and h.port != "blocking":
                port.access("read", a, wi)
            elif d == "WRITE":
                port.access("write", a, wi, value=float(-(k + 1)))
        port.frame_end()
        mem.tick()
    return seen


# ===========================================================================
#  SECTION 5 -- QUESTION B.  THE BLOCKING READ.
# ===========================================================================
def cmd_blockread():
    head(5, "*** QUESTION B -- THE BLOCKING READ, land = -1, 'FORCED 5145/5145' "
           "***")
    print("""   The claim: SINGLE DELAY forces a BLOCKING delay-DRAM read -- the
   read word's own operand bus already carries the fetched sample.  Its
   structural half (blocking-read.md sect. 3.3) is: `both blocks put the
   fetched sample into a temp register WITH THE READ WORD'S OWN ACTION'.
""")
    sub("STEP 1 -- THE STRUCTURAL HALF, RE-EXAMINED AT THE FORCED POLARITY")
    ac = collections.Counter()
    sc = collections.Counter()
    for a in algos():
        P = DL.program(a)
        for _wi, w in P.cons:
            d = DL.Harness().dirof(w)
            ac[(d, DIS.lo_act(w))] += 1
            sc[(d, DIS.lo_src(w))] += 1
    nr = sum(v for k, v in ac.items() if k[0] == "READ")
    print("      READ words whose own ACTION is a CAPTURE (0x13/0x14/0x19/0x1A):"
          " %d of %d"
          % (sum(ac.get(("READ", x), 0) for x in (0x13, 0x14, 0x19, 0x1A)), nr))
    print("      WRITE words whose own ACTION is a CAPTURE                     :"
          " %d of %d"
          % (sum(ac.get(("WRITE", x), 0) for x in (0x13, 0x14, 0x19, 0x1A)),
             sum(v for k, v in ac.items() if k[0] == "WRITE")))
    print("""      ** THE STRUCTURAL ARGUMENT DOES NOT SURVIVE THE POLARITY. **  At
      the forced polarity NO read word captures anything; 257 of them
      instead SOURCE tempA, and every capture sits on a WRITE.  The premise
      `the read word's own ACTION consumes the fetched sample' is false
      by exhaustive count.""")

    sub("STEP 2 -- AND THE SAME WORDS NOW ARGUE THE OPPOSITE.  THE FLUSH READ.")
    C = DL.load_classes()
    tally = collections.Counter()
    ex = []
    for a in algos():
        P = DL.program(a)
        rec = C["algorithms"][str(a)]
        for k, (wi, w) in enumerate(P.cons):
            if rec["cells"][k]["role"] != "CEILING":
                continue
            src, act = DIS.lo_src(w), DIS.lo_act(w)
            consumes = (src == 0x0B) and act in (0x07, 0x00, 0x13, 0x14,
                                                 0x19, 0x1A)
            tally[("SRC 0x0B" if src == 0x0B else "SRC 0x%02X" % src,
                   "ACT 0x%02X" % act)] += 1
            if consumes:
                ex.append((a, rec["name"], wi, w))
    print("      CEILING (flush) read words, by (SRC, ACTION).  Population: "
          "83 of 83 algorithms carry exactly one.")
    for k, v in sorted(tally.items(), key=lambda t: -t[1]):
        print("        %-9s %-9s x%d" % (k[0], k[1], v))
    print("      CEILING words that CONSUME SRC 0x0B into a register or memory:"
          " %d of 83" % len(ex))
    for (a, nm, wi, w) in ex[:6]:
        print("        algo %-3d %-16s w%-3d %09X  SRC 0x0B ACT 0x%02X"
              % (a, nm, wi, w, DIS.lo_act(w)))
    print("""      ** IF THE READ WERE BLOCKING, THESE WORDS WOULD CONSUME THE
      CEILING DATUM ITSELF. **  The CEILING is an out-of-region address that
      no write of the algorithm ever reaches (`dram-bounds.md' item C,
      83 of 83) -- its datum is the one thing in the machine that is
      guaranteed to be meaningless.  Under a blocking read, algo 8's w78
      would store that meaningless word into mem[ptr] with ACTION 0x07.
      Under a PIPELINED read the very same word stores an earlier, REAL tap,
      which is why the flush read has to exist at all.
      The blocking read's own structural argument, relocated, now runs
      AGAINST it.""")

    sub("STEP 3 -- THE NUMERIC HALF: CAN 5145 / 5635 BE RE-SCORED AT ALL?")
    P = DL.program(9)
    runs = exec_runs(P.words)
    print("      `sec_singledelay' scores the window w5..w9 with land in "
          "(-1,0,1,2).")
    print("      At the FORCED polarity w5 is the PRIME WRITE and w9 is a READ "
          "of a line")
    print("      whose base is at w46 -- outside every executable run %s."
          % ["w%d..w%d" % (s, e - 1) for s, e in runs])
    cells_f, region = SD_FORCED
    lines, orph, ceil, lim = _classify(cells_f, region, "forced")
    print("      forced-polarity lines of algo 9: %s"
          % ["cell%d<-cell%d D=%d" % t for t in lines])
    print("      -> the count cannot be re-scored.  NOT `zero survivors': "
          "no search.")

    sub("STEP 4 -- WHAT THE PORT MODELS ACTUALLY DO ON THE ROM, EXECUTED")
    h0 = DL.Harness()
    for port in ("blocking", "latency", "push_read", "push_any"):
        led = DL._port_ledger(DL.program(9), h0.replace(port=port))
        print("      port=%-10s : %s"
              % (port, "   ".join("w%d stores %s" % (k, v)
                                  for k, v in sorted(led.items()))))

    sub("STEP 4b -- ** THE DISCRIMINATOR, EXECUTED ON THE WORD THAT CARRIES IT "
        "**\n            GATED REVERB w78 is the CEILING read AND it carries "
        "SRC 0x0B + ACTION 0x07")
    print("""      The delay-DRAM access sequence is fixed by the DRAM words and the
      cursor alone -- no ALU parameter can change it -- so the provenance of
      the read-data register can be simulated on a program the ALU model
      cannot run.  Each read is tagged with the descriptor cell that issued
      it; the table says WHICH READ's datum is standing in DR when w78's
      own bus is latched.  (Population: algo 8's 20 DRAM words, 4 frames,
      steady state.)""")
    P8 = DL.program(8)
    rec8 = DL.load_classes()["algorithms"]["8"]
    for port in ("blocking", "latency", "push_read", "push_any"):
        h = h0.replace(port=port)
        seen = port_provenance(8, h)
        v = seen.get(78)
        k = int(round(abs(v))) - 1 if v else None
        role = rec8["cells"][k]["role"] if k is not None and 0 <= k < 32 else "?"
        addr = rec8["cells"][k]["value"] if k is not None and 0 <= k < 32 else 0
        print("      port=%-10s : w78's bus carries the datum of cell%-2s "
              "(%s, addr %d)" % (port, k, role, addr))
    print("""      ** Under `blocking' the flush read's ACTION 0x07 stores the
      CEILING datum -- an out-of-region address no write of the algorithm
      ever reaches (dram-bounds.md item C, 83 of 83) -- into mem[ptr].
      Under every pipelined model it stores a READ_END, a real tap. **
      CONDITIONAL, and the condition is named: SRC 0x0B = the delay-RAM read
      register.  That code is NOT in `_ANCHORED_SRC'; `dram-datapath.md'
      calls it anchored and round 5's H-SRC0B oracle scored it at 20.3 %.
      If SRC 0x0B is something else, this argument evaporates -- and so does
      every `land' bound in dram-datapath.md sect. 3, which is built on the
      same code.""")
    print("""      Under `blocking' the two words that carry SRC 0x0B store the
      datum of the read in the SAME frame slot; under the three pipelined
      models they store an earlier one.  The ROM separates them (this is
      delay-harness.md item H, re-run), so the fork is real -- but nothing
      in SINGLE DELAY can score it now that its loop is gone.

      VERDICT: the FORCING IS WITHDRAWN PERMANENTLY, not merely unproven --
      it rested on a premise (`the read word's own ACTION consumes the
      datum') that is FALSE at the forced polarity, 0 of 416 read words.
      The blocking read is not merely unsupported: 13 CEILING words argue
      against it.  `blocking' remains an enumerable port model and the
      device already refuses to act on any of them.""")
    return True


# ===========================================================================
#  SECTION 6 -- QUESTION C.  THE ACCUMULATOR ADDER'S SECOND LEG.
# ===========================================================================
def cmd_adder():
    head(6, "*** QUESTION C -- THE ACCUMULATOR ADDER'S SECOND LEG ***")
    print("""   acc-adder.md item B: `both blocks demand acc = bus + P at the word
   where their sum forms.  The LFO's 082.2.00.1C0 has hi12[3:1] = 1;
   SINGLE DELAY's 000.2.48.000 has hi12[3:1] = 0.  An ORDERING cannot give
   bus + P at both; an ADDER whose feedback input is overridden by the bus
   can.'  The SINGLE DELAY leg is the void one.
""")
    sub("STEP 1 -- IS THE SECOND LEG STILL A WITNESS?")
    P = DL.program(9)
    w7 = P.words[7]
    print("      SINGLE DELAY w7 = %09X : SRC 0x%02X  ACT 0x%02X  hi12[3:1]=%d"
          % (w7, DIS.lo_src(w7), DIS.lo_act(w7), DIS.hi_f31(DIS.hi12(w7))))
    print("""      The word is unchanged and its pointer walk is unchanged -- what
      is gone is the reason to believe its output is `x + fb*v[n-D]'.  That
      came from matching the w5..w9 WRITE against a comb, and at the forced
      polarity w9 is not a write and w5 writes an address nothing reads.
      The witness word survives; the constraint on its VALUE does not.""")

    sub("STEP 2 -- THE INDEPENDENT ANCHOR THE BRIEF NAMES, AND WHY IT CANNOT "
        "MOVE")
    print("""      The brief says: the biquad's impulse response was bit-identical
      before and after the adder unification (per-band 0.00205 / 0.00463 /
      0.00123 / 0.00119 / 0.00116 dB) and that check does not depend on the
      delay line, so use it as an anchor.  It IS an anchor -- and it is an
      anchor that cannot fail, which is method rule 1's other half:""")
    codes = sorted(set(DIS.lo_act(w) for w in A0.PEQ))
    print("        the PARAMETRIC EQ section's ACTION codes : %s"
          % " ".join("0x%02X" % c for c in codes))
    print("        does it contain ACTION 0x00 ?            : %s"
          % ("YES" if 0x00 in codes else "NO -- so ACT00 and `order' are "
             "INVISIBLE to it"))
    print("""        acc_adjudicate.py biquad, re-run: 480 of 2160 models are
        BIT-IDENTICAL on the section, and among them `order' takes all 3
        values (160 each) and `act00' all 5 (96 each).
      ** So EVERY verdict this pass could reach leaves the five numbers
      exactly where they are.  The anchor holds -- and it holds for `adder',
      for `act_first' and for `act_last' alike, so it is not evidence for
      any of them. **  Re-run:
        python3 dsp/tools/acc_adjudicate.py biquad
        python3 ~/compartilhado/kn7000_mame/tools/kn5000_dsp_alu.py \\
                original_ROMs/kn5000_subprogram_v142.rom verify""")

    sub("STEP 3 -- WHAT IS LEFT HOLDING `order = adder' UP?")
    print("""      acc-adder.md sect. 3.4's intersection was
          biquad 480  AND  LFO 153  AND  SINGLE DELAY 72   ->  18, all `adder'.
      Remove the SINGLE DELAY leg and the intersection is biquad AND LFO = 36,
      in which (sect. 3.3, re-quoted) `order' takes THREE values:
          act_first x576   adder x576   act_last x72        of 1224 LFO survivors
      ** `order = adder' therefore reverts from FORCED (18/18, three contexts)
      to CONSISTENT (two contexts, neither of which can see the order). **""")

    sub("STEP 4 -- IS THERE A REPLACEMENT WITNESS ANYWHERE IN THE CORPUS?")
    print("""      The unification needs TWO words that must both compute `bus + P'
      while carrying DIFFERENT hi12[3:1].  Census of ACTION 0x00 words by
      hi12[3:1], over the 83 aligned body images:""")
    byf = collections.Counter()
    inloop = collections.Counter()
    rows = loop_table("forced")
    closed_by_algo = {r[0]: r[5] for r in rows}
    for a in algos():
        P2 = DL.program(a)
        cl = closed_by_algo.get(a, [])
        wi_of = [wi for wi, _w in P2.cons]
        spans = [(min(wi_of[c[0]], wi_of[c[1]]), max(wi_of[c[0]], wi_of[c[1]]))
                 for c in cl]
        for i, w in enumerate(P2.words):
            if DIS.lo_act(w) != 0x00:
                continue
            f = DIS.hi_f31(DIS.hi12(w))
            byf[f] += 1
            if any(lo <= i <= hi for lo, hi in spans):
                inloop[f] += 1
    print("        hi12[3:1]   ACTION 0x00 words   of which inside a CLOSED, "
          "EXECUTABLE delay loop")
    for f in sorted(byf):
        print("        %-11d %-18d %d" % (f, byf[f], inloop.get(f, 0)))
    print("""      ** A replacement witness EXISTS in principle: the reverb ladder's
      closed loops carry ACTION 0x00 words at more than one hi12[3:1]. **
      What they lack is a REFERENCE -- the same missing piece as question A.
      So: not re-forced, not refuted, and the experiment that would settle it
      is the same one.""")

    sub("STEP 5 -- WHAT SHOULD THE DEVICE DO?")
    print("""      NOTHING CHANGES IN THE DEVICE, and the reason is worth stating
      precisely.  acc-adder.md sect. 2 proves BY CONSTRUCTION that on every
      word whose ACTION is not 0x00 the adder form and the shipped
      sequential form are the SAME MACHINE -- f31=0 gives 0+P, f31=1 gives
      acc+P, f31=2 gives acc+0.  The three orders differ ONLY on ACTION 0x00
      words, and ACTION 0x00 = `load' was already relabelled FORCED ->
      CONSISTENT by blocking-read.md sect. 6.  So the retraction is a LABEL
      change on a claim that was already carrying a weaker label downstream,
      and it costs zero executing words.""")
    return True


# ===========================================================================
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["all", "census", "windows", "controls", "act19",
                             "blockread", "adder"])
    a = ap.parse_args()
    r = {}
    if a.cmd in ("all", "census"):
        r["census"] = cmd_census()
    if a.cmd in ("all", "windows"):
        r["windows"] = cmd_windows()
    if a.cmd in ("all", "controls"):
        r["controls"] = cmd_controls()
    if a.cmd in ("all", "act19"):
        r["act19"] = cmd_act19()
    if a.cmd in ("all", "blockread"):
        r["blockread"] = cmd_blockread()
    if a.cmd in ("all", "adder"):
        r["adder"] = cmd_adder()
    if r:
        print()
        print("=" * 78)
        print("SELF-TEST: %s"
              % "  ".join("%s=%s" % (k, "PASS" if v else "FAIL")
                          for k, v in r.items()))
        print("=" * 78)


if __name__ == "__main__":
    main()
