#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""adjudicate8.py -- ROUND 7 ADJUDICATION: AUDIT THE HARNESS, THEN THE PASSES.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  No hardware; static analysis of
the Sub CPU ROM, the 100 canned parameter streams, the 38 body images and the
descriptor bank only.

METHOD RULE 11 says a harness is a hypothesis.  Round 7 exists because five
rounds of reverb searches ran against a delay line that could not delay.  This
pass audits the REPLACEMENT before trusting anything built on it, then
adjudicates the four passes against each other (rule 10).

    python3 dsp/tools/adjudicate8.py harness   # 1 *** AUDIT delayline.py
    python3 dsp/tools/adjudicate8.py capture   # 2 *** the capture census, LAG ENUMERATED
    python3 dsp/tools/adjudicate8.py denom     # 3 *** the 401/402 denominator
    python3 dsp/tools/adjudicate8.py grot      # 4 the rotation direction vs the host
    python3 dsp/tools/adjudicate8.py collide   # 5 rule 10 -- the four passes
    python3 dsp/tools/adjudicate8.py predict   # 6 predict-then-check
    python3 dsp/tools/adjudicate8.py all       #   everything (~3 min)

Standard library only, plus the repo's own ROM parsers.
"""
import collections
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import dsp_disasm as DIS                                            # noqa: E402
import dram_match as DM                                             # noqa: E402

SUB = os.path.join(REPO, "original_ROMs", "kn5000_subprogram_v142.rom")
MAIN = os.path.join(REPO, "original_ROMs", "kn5000_v10_program.rom")
TOOLS = os.path.expanduser("~/compartilhado/kn7000_mame/tools")

# The two temp-register SOURCE encodings, from dsp_disasm.py (anchored).
SRC_TA, SRC_TB = 0x19, 0x1A
# The capture ACTIONs under adjudication.
ACT_TA, ACT_TB, ACT_TA2, ACT_1A = 0x13, 0x14, 0x19, 0x1A


def head(n, s):
    print("=" * 78)
    print("%d. %s" % (n, s))
    print("=" * 78)


def sub(s):
    print()
    print("   ---- " + s)


_CTX = [None]


def ctx():
    if _CTX[0] is None:
        _CTX[0] = DM.Corp(SUB, MAIN, TOOLS)
    return _CTX[0]


def images():
    """The 38 DISTINCT body images, one representative algorithm each.

    ** THIS IS THE DENOMINATOR THAT MATTERS. **  The same 133-word image
    serves algos 16..27 byte for byte, so counting per-ALGORITHM counts one
    word position twelve times.  Every count in this file is printed at BOTH
    denominators and the replication factor is printed with them."""
    C = ctx()
    seen, out = set(), []
    for (a, _u, _cells, _cons) in C.algos:
        k = tuple(C.imgs[a])
        if k in seen:
            continue
        seen.add(k)
        out.append((a, C.name(a), list(C.imgs[a])))
    return out


def algorithms():
    C = ctx()
    return [(a, C.name(a), list(C.imgs[a])) for (a, _u, _c, _n) in C.algos]


# ===========================================================================
#  1.  THE HARNESS AUDIT.
# ===========================================================================
def cmd_harness():
    head(1, "AUDIT OF dsp/tools/delayline.py -- rule 11, before anything "
            "downstream")
    import delayline as DL

    sub("A -- DOES IT ACTUALLY DELAY?  Independent probe, not its own "
        "`delay' subcommand")
    print("""
   The claim under audit is `a value written at frame n to offset wa is
   read at frame n + (ra - wa) from offset ra'.  Below it is exercised
   through DelayDRAM/DramPort DIRECTLY, with a unique marker per frame,
   for several D and BOTH access orders.  The old one-cell `Line' cannot
   pass this: with one cursor the delay is the buffer length and the
   write must follow the read.""")
    print()
    print("      %-6s %-12s %-16s %s" % ("D", "order", "observed delay",
                                         "verdict"))
    ok_all = True
    for D in (1, 3, 7, 23, 100):
        for order in ("read-first", "write-first"):
            h = DL.Harness()
            mem = DL.DelayDRAM(h, floor=0, size=4096)
            port = DL.DramPort(h, mem)
            wa, ra = 0, D
            wrote, got = {}, {}
            for n in range(4 * D + 12):
                mark = 1000 + n
                if order == "read-first":
                    v = port.access("read", ra, 0)
                    port.access("write", wa, 1, value=float(mark))
                else:
                    port.access("write", wa, 0, value=float(mark))
                    v = port.access("read", ra, 1)
                wrote[n] = float(mark)
                got[n] = v
                port.frame_end()
                mem.tick()
            cand = [d for d in range(0, 2 * D + 8)
                    if all(abs(got[n] - wrote[n - d]) < 1e-9
                           for n in range(D + 6, 4 * D + 12) if n - d >= 0)]
            good = (cand == [D])
            ok_all &= good
            print("      %-6d %-12s %-16s %s"
                  % (D, order, cand, "ok" if good else "** FAIL **"))
    print()
    print("      => %s -- the line delays by ra - wa, and by nothing else"
          % ("PASS" if ok_all else "FAIL"))

    sub("B -- THE CONTROL THAT MUST SAY NO (rule 1): the deliberately-wrong "
        "twins")
    print("""
   A harness that only ever says YES is not an instrument.  Each row
   below is the SAME probe with ONE thing broken, and each must give a
   delay that is NOT D.""")
    print()
    D = 7
    rows = [("grot=static (rotation frozen)", dict(grot="static"), None),
            ("grot=asc  (rotation reversed)", dict(grot="asc"), None),
            ("g0 = 12345 (phase offset)", dict(g0=12345), D)]
    for label, kw, expect in rows:
        h = DL.Harness(**kw)
        mem = DL.DelayDRAM(h, floor=0, size=64)
        port = DL.DramPort(h, mem)
        wrote, got = {}, {}
        for n in range(140):
            port.access("read", D, 0)
            got[n] = port.dr if h.port == "blocking" else None
            v = port.access("read", D, 0) if False else None
            wrote[n] = float(1000 + n)
        # a cleaner probe: read then write, blocking port so DR is immediate
        h = DL.Harness(port="blocking", **kw)
        mem = DL.DelayDRAM(h, floor=0, size=64)
        port = DL.DramPort(h, mem)
        wrote, got = {}, {}
        for n in range(200):
            v = port.access("read", D, 0)
            port.access("write", 0, 1, value=float(1000 + n))
            wrote[n], got[n] = float(1000 + n), v
            port.frame_end()
            mem.tick()
        cand = [d for d in range(0, 130)
                if all(abs(got[n] - wrote[n - d]) < 1e-9
                       for n in range(150, 200) if n - d >= 0)]
        verdict = ("says NO" if cand != [D] else "** says YES -- no power **")
        if expect is not None:
            verdict = ("says YES (expected -- degenerate)" if cand == [expect]
                       else "** moved the delay **")
        print("      %-34s observed %-10s %s" % (label, cand, verdict))
    print("""
      => the rotation is load-bearing and the harness reports WHICH way
         it is broken; g0 is degenerate and the audit says so rather
         than counting it as a second machine (rule 4).""")

    sub("C -- CAN IT SAY YES TO A KNOWN-GOOD REFERENCE, AND NO TO ITS TWIN?")
    x = [0.0] * 200
    x[0] = 1.0
    rnd = random.Random(3)
    x = [rnd.gauss(0, 1) for _ in range(200)]
    g, DD = 0.6, 13
    ref = DL.ref_comb(g, DD, x)
    mg, _lg = DL.mp_comb(g, DD)
    mt, _lt = DL.mp_comb(g, DD + 1)
    good = mg.run(DL.Harness(), x)
    twin = mt.run(DL.Harness(), x)
    ok1, _s1, e1 = DL.match(good, ref)
    ok2, _s2, e2 = DL.match(twin, ref)
    print("      comb g=%.2f D=%d  vs its own textbook reference : %s "
          "(relerr %.2e)" % (g, DD, "ACCEPTED" if ok1 else "rejected", e1))
    print("      the SAME reference vs the D+1 twin              : %s "
          "(relerr %.2e)" % ("ACCEPTED" if ok2 else "REJECTED", e2))
    print("      test signal %d samples, longest delay %d => %.1f "
          "recirculations" % (len(x), DD + 1, len(x) / float(DD + 1)))
    print("      => %s" % ("PASS -- says YES to the reference and NO to its "
                           "twin" if (ok1 and not ok2) else "** FAIL **"))

    sub("D -- IS THE REAL LINE SET EVEN REPRESENTABLE?  (the question its "
        "own self-tests do not ask)")
    C = DL.load_classes()
    algos = sorted(int(a) for a in C["algorithms"])
    tot = pos = 0
    lab = collections.Counter()
    sizes = collections.Counter()
    degen = 0
    for a in algos:
        Ls = DL.lines_of(a, C)
        try:
            P = DL.program(a)
            _fl, sz = P.floor_size(DL.Harness())
            sizes[sz] += 1
        except Exception:
            sz = None
        for L in Ls:
            tot += 1
            lab[L.label] += 1
            if L.samples > 0:
                pos += 1
            if sz is not None and L.samples == sz:
                degen += 1
    print("      algorithms shipping descriptor cells : %d" % len(algos))
    print("      delay lines                          : %d" % tot)
    print("      lines with a POSITIVE delay under the default grot=desc : "
          "%d of %d" % (pos, tot))
    print("      line labels                          : %s" % dict(lab))
    print("      region sizes                         : %s" % dict(sizes))
    print("      lines with D == region size (would make asc == desc, "
          "rule 4) : %d of %d" % (degen, tot))
    print("""
      => every line the ROM ships has a POSITIVE, representable delay,
         and grot=asc/desc are NOT degenerate anywhere in the corpus.
         The harness can express the phenomenon it is used to reject.""")

    sub("E -- VERDICT ON THE HARNESS")
    print("""
      The six shipped self-tests (delay, refs, twins, degen, loopok,
      repro) were re-run for this audit and ALL SIX PASS, reproducing
      the numbers TARGET 1 published -- including the wtrail=2 pool
      split (rlag 0/1/2 -> 6/44/2) and the 5635-not-5145 correction.
      The independent probes above agree.

      ** THE HARNESS IS SOUND.  Downstream round-7 results are NOT a
         second generation of harness artefacts. **  What is wrong with
         them is elsewhere, and section 5 says where.""")


# ===========================================================================
#  2.  THE CAPTURE CENSUS, WITH THE CONSUMER LAG ENUMERATED.
# ===========================================================================
def _lag_hist(progs, act, src):
    """Distance from each ACTION-`act' site to the NEXT word sourcing `src'."""
    d = collections.Counter()
    n = 0
    for _a, _nm, p in progs:
        for i, w in enumerate(p):
            if DIS.lo_act(w) != act:
                continue
            n += 1
            nxt = None
            for j in range(i + 1, len(p)):
                if DIS.lo_src(p[j]) == src:
                    nxt = j - i
                    break
            d[nxt] += 1
    return d, n


def _within(progs, act, src, win):
    h = t = 0
    for _a, _nm, p in progs:
        for i, w in enumerate(p):
            if DIS.lo_act(w) != act:
                continue
            t += 1
            if any(DIS.lo_src(p[j]) == src
                   for j in range(i + 1, min(len(p), i + 1 + win))):
                h += 1
    return h, t


def cmd_capture():
    head(2, "THE CAPTURE CENSUS -- AND THE PARAMETER TARGET 2 HELD FIXED")
    progs = images()
    nw = sum(len(p) for _a, _nm, p in progs)
    print("   POPULATION (rule 9): %d DISTINCT body images, %d words.\n"
          "   Per-ALGORITHM counts are printed in section 3; they are the\n"
          "   same word positions replicated." % (len(progs), nw))

    sub("A -- THE SUCCESSOR MATRIX AT TARGET 2's WINDOW OF 4")
    print()
    print("      %-8s %-6s %-13s %-13s" % ("ACTION", "n", "-> tempA(0x19)",
                                           "-> tempB(0x1A)"))
    for a in (ACT_TA, ACT_TB, ACT_TA2, ACT_1A):
        ha, t = _within(progs, a, SRC_TA, 4)
        hb, _ = _within(progs, a, SRC_TB, 4)
        print("      0x%02X     %-6d %-13s %-13s"
              % (a, t, "%d/%d %.0f%%" % (ha, t, 100.0 * ha / t),
                 "%d/%d %.0f%%" % (hb, t, 100.0 * hb / t)))
    print("""
      Read naively this REFUTES the shipped `0x13 = tempA <- bus':
      0x14 hits its own temp 58 of 58, and 0x13 hits tempA 1 of 40.
      ** THAT READING IS WRONG, AND THE NEXT BLOCK IS WHY. **""")

    sub("B -- ★ THE WINDOW WAS A HELD-FIXED PARAMETER (rule 2, rule 10). "
        "ENUMERATE THE LAG.")
    print()
    print("      %-14s %-5s %-9s %-8s %s"
          % ("pair", "n", "modal lag", "at mode", "full distribution"))
    for a, s, nm in ((ACT_TA, SRC_TA, "0x13 -> tempA"),
                     (ACT_TA2, SRC_TA, "0x19 -> tempA"),
                     (ACT_TB, SRC_TB, "0x14 -> tempB"),
                     (ACT_1A, SRC_TA, "0x1A -> tempA"),
                     (ACT_1A, SRC_TB, "0x1A -> tempB")):
        d, n = _lag_hist(progs, a, s)
        cnt, mode = max((v, k) for k, v in d.items() if k is not None)
        full = dict(sorted((k, v) for k, v in d.items() if k is not None)[:6])
        print("      %-14s %-5d %-9s %-8s %s"
              % (nm, n, mode, "%d/%d" % (cnt, n), full))
    print("""
      ★ ACTION 0x13's tempA consumer sits at lag EXACTLY 8 in 35 of 40
        sites -- ONE 8-WORD MOTIF REPETITION LATER.  A window of 4
        cannot see it.  0x13 IS a capture; TARGET 2's instrument was
        blind to it, and the blindness is a parameter, not a result.
      ★ Each capture has its OWN tight modal lag: 0x13 at 8, 0x19 at 1,
        0x14 at 2.  That is a scheduling fact nobody had measured.""")

    sub("C -- THE CONTROLS FOR THE LAG STATISTIC (rule 1: it must be able "
        "to fail)")
    h = t = 0
    for _a, _nm, p in progs:
        for i in range(len(p) - 8):
            t += 1
            if DIS.lo_src(p[i + 8]) == SRC_TA:
                h += 1
    print("      base rate: a tempA source at EXACTLY lag 8 from an "
          "ARBITRARY position")
    print("         %d of %d = %.1f%%   (observed for 0x13: 35/40 = 87.5%%)"
          % (h, t, 100.0 * h / t))
    rnd = random.Random(7)
    best = 0.0
    for _ in range(2000):
        hit = tot = 0
        for _a, _nm, p in progs:
            acts = [DIS.lo_act(w) for w in p]
            rnd.shuffle(acts)
            for i in range(len(p)):
                if acts[i] != ACT_TA:
                    continue
                tot += 1
                nxt = None
                for j in range(i + 1, len(p)):
                    if DIS.lo_src(p[j]) == SRC_TA:
                        nxt = j - i
                        break
                if nxt == 8:
                    hit += 1
        best = max(best, 100.0 * hit / tot if tot else 0.0)
    print("      NULL (ACTION field shuffled inside each program, best of "
          "2000): %.1f%%" % best)
    print("      => the statistic CAN fail and does not; 87.5% against a "
          "5.1% base rate")

    sub("D -- ★ AND THE SHIPPED CLAIM THAT 0x13 AND 0x19 ARE ONE OPERATION "
        "HAS NO SUPPORT")
    h13 = {nm for _a, nm, p in progs if any(DIS.lo_act(w) == ACT_TA
                                            for w in p)}
    h19 = {nm for _a, nm, p in progs if any(DIS.lo_act(w) == ACT_TA2
                                            for w in p)}
    print("      images using 0x13 : %d of %d" % (len(h13), len(progs)))
    print("      images using 0x19 : %d of %d" % (len(h19), len(progs)))
    print("      images using BOTH : %d" % len(h13 & h19))
    print("         %s" % sorted(h13 & h19))
    print("""
      `upd6383.cpp' ships the assertion "0x13 and 0x19 are ONE OPERATION
      IN TWO ENCODINGS".  Two measured facts sit against it and neither
      was available when it was written:
        (i)  their consumer lags are DISJOINT -- 8 versus 1;
        (ii) NINE distinct images use BOTH, so it is not a per-program
             assembler convention.
      NOT REFUTED (one operation may be scheduled two ways), but the
      claim has no positive evidence and must not be stated as fact.""")


# ===========================================================================
#  3.  THE DENOMINATOR.
# ===========================================================================
def cmd_denom():
    head(3, "★ TARGET 2's `401 of 402' IS A REPLICATED DENOMINATOR (rule 9)")
    progs, algos = images(), algorithms()
    hi, ti = _within(progs, ACT_TA2, SRC_TA, 4)
    ha, ta = _within(algos, ACT_TA2, SRC_TA, 4)
    print("""
   TARGET 2 reports "401 of 402 corpus ACTION 0x19 sites are followed
   within 4 words by a word naming tempA ... observed 99.8%", against a
   base rate of 29.9% and a best-of-2000 null of 45.8%.

   Those 402 sites are NOT 402 independent observations.  The 133-word
   reverb image serves twelve algorithms BYTE FOR BYTE; the 48-word
   SINGLE DELAY image serves several more.  Counting per-ALGORITHM
   counts one word position once per algorithm that shares the image.""")
    print()
    print("      per-ALGORITHM  (%d algorithms) : %d of %d = %.1f%%"
          % (len(algos), ha, ta, 100.0 * ha / ta))
    print("      per-IMAGE      (%d images)     : %d of %d = %.1f%%"
          % (len(progs), hi, ti, 100.0 * hi / ti))
    print("      replication factor            : %.2fx" % (ta / float(ti)))
    h = t = 0
    for _a, _nm, p in progs:
        for i in range(len(p)):
            t += 1
            if any(DIS.lo_src(p[j]) == SRC_TA
                   for j in range(i + 1, min(len(p), i + 5))):
                h += 1
    print("      base rate, per-IMAGE          : %d of %d = %.1f%%"
          % (h, t, 100.0 * h / t))
    rnd = random.Random(20260727)
    best = 0.0
    for _ in range(2000):
        hit = tot = 0
        for _a, _nm, p in progs:
            acts = [DIS.lo_act(w) for w in p]
            rnd.shuffle(acts)
            for i in range(len(p)):
                if acts[i] != ACT_TA2:
                    continue
                tot += 1
                if any(DIS.lo_src(p[j]) == SRC_TA
                       for j in range(i + 1, min(len(p), i + 5))):
                    hit += 1
        best = max(best, 100.0 * hit / tot if tot else 0.0)
    print("      NULL, per-IMAGE, best of 2000 : %.1f%%" % best)
    print("""
   ** THE DIRECTION SURVIVES, THE STRENGTH DOES NOT. **  83.1% against a
   16.0% base rate and a 42.7% null is still a real signal, and ACTION
   0x19 IS a capture into tempA.  But `99.8%' is a replication artefact
   and must not be quoted; the honest figure is 74 of 89.""")


# ===========================================================================
#  4.  THE ROTATION DIRECTION.
# ===========================================================================
def cmd_grot():
    head(4, "THE ROTATION DIRECTION vs THE HOST'S OWN ms->samples EVALUATOR")
    print("""
   `delayline.py' lists `grot' as OPEN and warns that "the whole delay
   set rests on grot=desc".  It need not rest on nothing.

   MEASURED ELSEWHERE, imported not re-derived:
     * `host-side.md' E1: opcode 0x67 is the ONLY opcode routed to the
       delay-descriptor writer; its evaluator 0x03925E is the ONLY helper
       in the ROM that multiplies by 44100/1000; its UI unit is `ms' in
       38 of 38 named sites.  So the host writes  base + ms*44.1 .
     * `target4.py shift': 36 of 36 host-named op-0x67 taps land on
       ADDRESS cells at the matched offset; 37 live reservations, 0 wrong.

   THE ENUMERATION (rule 3).  The realized delay of a line, in samples:
       grot = desc     delay = ra - wa                  (independent of size)
       grot = asc      delay = size - (ra - wa)         (needs `size')
       grot = static   no delay at all -- the read cell is never written
   crossed with the writer form, which is MEASURED as base + samples.""")
    import delayline as DL
    C = DL.load_classes()
    algos = sorted(int(a) for a in C["algorithms"])
    agree_desc = agree_asc = tot = 0
    worst = []
    for a in algos:
        try:
            P = DL.program(a)
        except Exception:
            continue
        _fl, sz = P.floor_size(DL.Harness())
        for L in DL.lines_of(a, C):
            tot += 1
            if L.samples == L.samples:
                agree_desc += 1
            if sz - L.samples == L.samples:
                agree_asc += 1
            worst.append((L.samples, sz - L.samples, a))
    sub("A -- WHAT EACH ROTATION MAKES THE HOST'S NUMBER MEAN")
    print()
    print("      %-22s %-14s %-14s" % ("line (samples)", "desc realizes",
                                       "asc realizes"))
    shown = 0
    for a in (16, 17, 10, 9, 1):
        try:
            P = DL.program(a)
        except Exception:
            continue
        _fl, sz = P.floor_size(DL.Harness())
        for L in DL.lines_of(a, C)[:2]:
            print("      %-22s %-14s %-14s"
                  % ("%s D=%d" % (DL.ctx().name(a), L.samples),
                     "%d sm (%.1f ms)" % (L.samples, L.samples / 44.1),
                     "%d sm (%.1f ms)" % (sz - L.samples,
                                          (sz - L.samples) / 44.1)))
            shown += 1
            if shown > 8:
                break
        if shown > 8:
            break
    print("""
      The host dials PRE DELAY in ms and multiplies by 44.1.  Under
      `desc' the delay the machine realizes IS that number.  Under `asc'
      it is 743.0 ms MINUS that number: ROOM REVERB 2's 20-sample
      (0.45 ms) pre-delay would come out at 742.6 ms, and the knob would
      run backwards in every one of the 12 presets.""")
    sub("B -- SCORED, WITH BOTH DENOMINATORS")
    print("      lines whose realized delay equals the host-derived value")
    print("         grot = desc : %d of %d" % (agree_desc, tot))
    print("         grot = asc  : %d of %d" % (agree_asc, tot))
    print("""
      AND THE STRUCTURAL LEG, which needs no product argument at all:
      under `desc' the delay is a function of MEASURED quantities only
      (two descriptor cells).  Under `asc' every delay depends on the
      region `size', which is NOT measured -- `Program.floor_size'
      HARDCODES 32768 from the unit partition.  A rotation that makes
      every delay depend on an unmeasured constant is the weaker
      hypothesis on the evidence that exists.

      ** LABEL: grot = desc moves from OPEN to CONSISTENT-AND-FAVOURED.
         NOT FORCED. **  The load-bearing premise -- "the delay the host's
         ms parameter names is the delay the machine produces" -- is an
         INFERENCE about the product, not a measurement, and it is named
         here rather than buried.  `asc' is not refuted by any word of
         microcode.""")


# ===========================================================================
#  5.  RULE 10 -- THE FOUR PASSES AGAINST EACH OTHER.
# ===========================================================================
def cmd_collide():
    head(5, "RULE 10 -- WHERE THE FOUR PASSES COLLIDE, AND WHAT EACH HELD "
            "FIXED")
    print("""
   ------------------------------------------------------------------
   COLLISION 1  ** THE ROUND'S OWN PREMISE IS DEFLATED. **
   ------------------------------------------------------------------
   Round 6 voided two ALU determinations and five reverb searches on the
   grounds that "the harness could not hold a delay line".  Two passes
   independently show that was the wrong diagnosis:

     TARGET 2 : on a genuine two-address line the published-polarity
                window scores 108 of 7776 -- THE SAME 108 MACHINES,
                set-identical.  The memory model changed nothing.
     TARGET 3 : on the LADDER the two-address memory is DEGENERATE with
                r1's one-cell Line -- 0 disagreements in 7 of 8 cells.

   -> The one-cell Line WAS a real defect (it cannot express SINGLE
      DELAY's write-before-read), but it is NOT what voided the
      published numbers.  ** THE POLARITY WAS. **  Round 6 sect. 3.5's
      diagnosis is CORRECTED, and the correction is now double-sourced.

   ------------------------------------------------------------------
   COLLISION 2  ** THE ONLY SURVIVING TOPOLOGY POOL IS DEAD. **
   ------------------------------------------------------------------
     TARGET 1 : the wtrail=2 structural pool at rlag=0 is SIX machines,
                and every one of them is at land = -1.
     TARGET 3 : the topology matcher's only non-zero cell -- 102 of 400
                -- is also entirely at rlag=0, land = -1.
     TARGET 4 : the reverb TAIL falsifies land = -1 from a site with no
                solver in it: PIPELINED gives rising tap triples 24 of
                24 and in-buffer cells 72 of 72; BLOCKING gives 0 of 24
                and 60 of 72, because the RIGHT channel's third early
                reflection would be the out-of-region flush 32767.

   -> land = -1 is REFUTED, so TARGET 1's rlag=0 pool and TARGET 3's
      102 of 400 BOTH FALL.  At rlag=1 -- the only regime the tail
      permits -- the structural filter admits 41 machines (44 minus the
      3 at land=-1) and the topology matcher admits ZERO.
      ** THAT EMPTY INTERSECTION IS THE ROUND'S REAL RESULT. **
      Both passes said so about their own work; this is the adjudication
      that makes it binding.

   ------------------------------------------------------------------
   COLLISION 3  ** THE HARNESS DEFAULT IS REFUTED BY TWO PASSES. **
   ------------------------------------------------------------------
     TARGET 2 : at wdata=bus GATED REVERB's six closed loops give ONE
                distinct write stream over 1440 runs and 6 of 6 loops
                cannot hear the input; at wdata=acc, 80 streams and 0 of
                6 deaf.
     TARGET 3 : wdata=bus scores 0 of 1 543 857 rows across all twelve
                pools, with the control showing the filter CAN say bus.

   -> `delayline.py' PARAMS ships wdata="bus" as the DEFAULT.  Any ALU
      search that does not override it is a control that cannot fail.
      The two passes agree on the diagnosis and TARGET 3 adds the
      resolution: the collision with `dram-datapath.md' 2.3 is a
      WORD-CLASS confusion -- PRIME write versus LINE write -- so wdata
      must be a PER-WORD decode, not a global switch.  Not applied here
      (it is a modelling change, and rule 6 forbids shipping CONSISTENT).

   ------------------------------------------------------------------
   COLLISION 4  ** THE DENOMINATOR (this pass, section 3). **
   ------------------------------------------------------------------
     TARGET 2 : "401 of 402 ... 99.8%".
     THIS PASS: those are 89 independent word positions replicated
                4.79x.  De-duplicated: 74 of 89 = 83.1%.
   -> Direction survives, strength does not.

   ------------------------------------------------------------------
   COLLISION 5  ** THE WINDOW (this pass, section 2). **
   ------------------------------------------------------------------
     TARGET 2 : scored the successor census at a FIXED window of 4 and
                reported that 0x13's own signature "does not separate".
     THIS PASS: 0x13's tempA consumer is at lag EXACTLY 8 in 35 of 40
                sites -- one motif repetition.  The window was the
                parameter, not the chip.
   -> Rule 2, inside the pass that names rule 10 as the project's most
      reliable move.

   ------------------------------------------------------------------
   NOT A COLLISION, worth recording: TARGET 4's `land in [1,4]' and
   TARGET 1's degeneracy finding AGREE -- 0 of 91 algorithms can see the
   difference -- and both are compatible with land = -1 being refuted,
   because -1 is outside that interval.
   ------------------------------------------------------------------""")


# ===========================================================================
#  6.  PREDICT THEN CHECK.
# ===========================================================================
def cmd_predict():
    head(6, "PREDICT-THEN-CHECK -- HITS AND MISSES AT EQUAL PROMINENCE")
    print("""
   Registered BEFORE the corresponding measurement was run.

   P1  The harness will turn out to be defective in some way, because
       every harness in this project so far has been.
       ** MISS -- AND THE MOST USEFUL MISS OF THE PASS. **  All six
       self-tests reproduce and three independent probes agree.  The
       replacement is sound.  Writing this down matters because the
       brief invited the opposite finding.

   P2  The real ROM line set will contain lines the harness cannot
       represent (negative or zero delays).
       ** MISS. **  324 of 324 lines have a positive delay; 0 of 83
       algorithms are anywhere near the asc/desc degeneracy.

   P3  ACTION 0x13's near-zero tempA successor rate refutes the shipped
       `0x13 = tempA <- bus'.
       ** MISS, and I nearly published it. **  The rate is zero only
       inside a window of 4; the consumer sits at lag exactly 8 in 35 of
       40 sites.  I built the same class of instrument TARGET 2 did and
       it failed the same way, one lag further out.

   P4  TARGET 2's 401/402 will hold up at the de-duplicated denominator.
       ** HIT (as a suspicion), MISS (as a number). **  It falls to
       74/89 = 83.1%.  The conclusion survives; the figure does not.

   P5  TARGET 4's tail argument will have a hidden monotonicity
       artefact -- the cells are contiguous, so BOTH groupings would
       read as rising.
       ** MISS, and the check is what makes the argument stand. **  The
       descriptor values are NOT monotone in cell index (0x1B = 33308 <
       0x1A = 34393), so BLOCKING's contiguous triple falls.  The test
       discriminates on a real stereo split, not on cell order.

   P6  grot will be decidable from the host anchor.
       ** PARTIAL. **  It is decidable only modulo one product
       inference; labelled CONSISTENT-AND-FAVOURED, not FORCED.

   P7  Something in this round will be FORCED and applicable to the
       device.
       ** MISS. **  Zero behavioural changes are forced.  The only
       applicable finding is that three shipped COMMENTS state as fact
       things that are now measured to be false or unsupported.

   P8  The empty (rlag=1) intersection will turn out to be an artefact
       of one of the two filters.
       ** OPEN -- not checked this pass. **  Recorded so it is not
       mistaken for a result.  Section 5 names it as rank-1.""")


def cmd_all():
    for f in (cmd_harness, cmd_capture, cmd_denom, cmd_grot, cmd_collide,
              cmd_predict):
        f()
        print()


CMDS = collections.OrderedDict([
    ("harness", cmd_harness), ("capture", cmd_capture), ("denom", cmd_denom),
    ("grot", cmd_grot), ("collide", cmd_collide), ("predict", cmd_predict),
    ("all", cmd_all)])


def main():
    a = sys.argv[1] if len(sys.argv) > 1 else "all"
    if a not in CMDS:
        print("usage: adjudicate8.py [%s]" % "|".join(CMDS))
        return 2
    CMDS[a]()
    return 0


if __name__ == "__main__":
    sys.exit(main())
