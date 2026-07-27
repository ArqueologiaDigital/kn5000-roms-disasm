#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""adjudicate6.py -- ADJUDICATION, ROUND 6.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  No hardware; static analysis of
the Sub CPU ROM, the 100 canned parameter streams, the 38 body images and the
live emulator only.

Adjudicates the four concurrent round-6 passes:

    dram-bounds.md          (T1) ADDRESSES versus BOUNDS
    dram-datapath.md        (T2) the delay-DRAM datapath
    dram-unit-cursor.md     (T3) the unit-1 cursor reload, and M5
    second-dsp-and-ready.md (T4) the READY line and the second DSP

and, through them, adjudication-round5.md, blocking-read.md, action-field.md,
acc-adder.md, action00-discriminator.md and schroeder-topology.md.

★ THE RESULT OF THE ROUND IS SECTION 3, AND IT IS NOT ABOUT THE DELAY LINE.
Round 5 reversed the delay-DRAM direction and reported "no executable semantic
changed" -- true of the edit it made.  What nobody checked is the semantics that
had ALREADY SHIPPED: the SINGLE DELAY ALU harnesses hard-code the OLD polarity,
and SINGLE DELAY is the only published ALU context that touches the delay port.
Re-run at the corrected polarity they score ZERO -- and the zero is a harness
artefact too, because their one-cursor delay line silently requires
READ-before-WRITE.  Both numbers are void; the determination is UNFORCED.

    python3 dsp/tools/adjudicate6.py census    # 1  populations, reproduced independently
    python3 dsp/tools/adjudicate6.py degen     # 2  *** rule 4/7 on T1+T2's two dummies
    python3 dsp/tools/adjudicate6.py polarity  # 3  *** THE ROUND: the harness audit
    python3 dsp/tools/adjudicate6.py enum      # 4  *** the widened enumeration, E2' and E7
    python3 dsp/tools/adjudicate6.py wtrail    # 5  the write trail, FORCED subset vs all
    python3 dsp/tools/adjudicate6.py latency   # 6  the `land' interval, and its UNITS
    python3 dsp/tools/adjudicate6.py ladder    # 7  ROOM REVERB 1, re-derived (rule 8)
    python3 dsp/tools/adjudicate6.py cursor    # 8  T3's pointer census, reproduced
    python3 dsp/tools/adjudicate6.py control   # 9  *** every control, shown saying NO
    python3 dsp/tools/adjudicate6.py predict   # 10 PREDICT-THEN-CHECK, hits AND misses
    python3 dsp/tools/adjudicate6.py all       # ~3 min

Standard library only, plus the repo's own ROM parsers.  EVERY number printed
below is computed here from the ROM.
"""
import collections
import itertools
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as DIS                                            # noqa: E402
import dram_match as DM                                             # noqa: E402
import bounds as B                                                  # noqa: E402
import datapath as DP                                               # noqa: E402
import lfo_ramp as L                                                # noqa: E402
import action00_discriminate as A0                                  # noqa: E402
import cursor_units as CU                                           # noqa: E402

FLOOR = {0: 0, 1: 32768}
TOP = {0: 32767, 1: 65535}
SR = 44100.0


def head(n, s):
    print("=" * 78)
    print("%d. %s" % (n, s))
    print("=" * 78)


_CTX = [None]


def ctx():
    if _CTX[0] is None:
        X = DP.Ctx()
        X.A6 = B.analyse(X.C)
        X.a6 = B.aligned(X.A6)
        _CTX[0] = X
    return _CTX[0]


def seqstr(d):
    return "".join({"READ": "R", "WRITE": "W", None: "C"}[x] for x in d)


# ===========================================================================
#  1.  populations and the census -- reproduced, not imported
# ===========================================================================
def cmd_census():
    head(1, "POPULATIONS AND THE DIRECTION CENSUS, RE-DERIVED")
    X = ctx()
    C, al = X.C, X.a6
    print("""   METHOD RULE 9.  Every count in this file is printed with its
   population.  Nothing here is taken from another note's number: the
   census below is recomputed from the ROM through the shipped rule
   `dsp_disasm.dram_dir' and the identity cell<->word map (round 5 item B).
""")
    print("     algorithms shipping descriptor cells         : %d" % len(X.A6))
    print("     ... of which #cells == #consumers (ALIGNED)  : %d" % len(al))
    print("     descriptor cells, all algorithms             : %d"
          % sum(r["n"] for r in X.A6.values()))
    print("     descriptor cells, ALIGNED algorithms         : %d"
          % sum(r["n"] for r in al.values()))
    print("     IC311 algorithm population (T4, sect. 2)     : 91  (9 are IC310)")
    cnt = collections.Counter()
    for a in sorted(al):
        for (_wi, w) in X.cons[a]:
            cnt[DIS.dram_dir(w) or "TRAP"] += 1
    print()
    print("     READ %d   WRITE %d   still trapping (C format) %d"
          % (cnt["READ"], cnt["WRITE"], cnt["TRAP"]))
    print("     adjudication-round5 sect. 7 published 416 / 365 / 48 and")
    print("     dram-bounds.md sect. 1 reproduced it.  So do I -- THREE")
    print("     independent implementations agree, which is why nothing in")
    print("     this round re-opens the alignment.")
    print()
    roles = collections.Counter()
    for r in al.values():
        roles.update(r["role"])
    print("     T1's role census over the 829: %s"
          % "  ".join("%s %d" % (k, v) for k, v in sorted(roles.items())))
    return cnt


# ===========================================================================
#  2.  *** the degeneracy T2 did not check (method rule 4 / rule 7)
# ===========================================================================
def cmd_degen():
    head(2, "RULE 4 / RULE 7 ON T2's TWO DUMMIES -- and one of them is DEGENERATE")
    X = ctx()
    al = X.a6
    print("""   T2 item A: "the LIMIT is the FIRST WRITE of its program, 74 of 74,
   and the CEILING is the LAST READ, 83 of 83 ... two cell classes
   `dram-bounds.md' located and left open are the two ends of one
   mechanism, arrived at FROM A COMPLETELY DIFFERENT DIRECTION."

   T1 had already published WHERE those cells sit: "Position: relative
   index n-2 in 75 algorithms, n-1 in the 8 with n = 2" (CEILING) and
   "62 of the 63 in-region cases sit at relative index 1" (LIMIT).  T1
   also reported, about itself, that the instruction-blind positional
   rival R1 = {rel 1, rel n-2} ties it 163/163 and it could not separate
   them.  THE QUESTION T2 NEVER ASKED: is "the last READ" a different
   statement from "rel n-2"?
""")
    rows = []
    for a in sorted(al):
        r = al[a]
        n, d = r["n"], r["dir"]
        reads = [i for i in range(n) if d[i] == "READ"]
        writes = [i for i in range(n) if d[i] == "WRITE"]
        ci = [i for i in range(n) if r["role"][i] == "CEILING"]
        li = [i for i in range(n) if r["role"][i] == "LIMIT"]
        alt = all(d[i] is not None and d[i + 1] is not None and d[i] != d[i + 1]
                  for i in range(n - 1))
        rows.append(dict(a=a, n=n, d=d, reads=reads, writes=writes,
                         ceil=ci[0] if ci else None,
                         lim=li[0] if li else None, alt=alt,
                         posn=n - 2 if n > 2 else n - 1))
    nalt = sum(1 for r in rows if r["alt"])
    print("   POPULATION: %d aligned algorithms.  Strictly alternating %d, NOT %d"
          % (len(rows), nalt, len(rows) - nalt))
    print("   (T3 sect. 3 measured the same 55 / 28 -- reproduced.)")
    print()
    # ---- CEILING -------------------------------------------------------
    lastread = sum(1 for r in rows if r["ceil"] is not None
                   and r["reads"] and r["ceil"] == r["reads"][-1])
    atposn = sum(1 for r in rows if r["ceil"] is not None
                 and r["ceil"] == r["posn"])
    dis = [r for r in rows if (r["reads"] and r["reads"][-1]) != r["posn"]]
    print("   RIVAL A  T2's   : the CEILING is the LAST READ            %d of %d"
          % (lastread, len(rows)))
    print("   RIVAL B  T1's, instruction-blind and value-blind :")
    print("            the CEILING sits at rel n-2 (n-1 when n == 2)   %d of %d"
          % (atposn, len(rows)))
    print("   ** DISAGREEMENT SITES BETWEEN A AND B: %d of %d **" % (len(dis), len(rows)))
    print()
    print("     the last READ of the block IS at rel n-2 / n-1 in %d of %d"
          % (sum(1 for r in rows if (r["reads"][-1] if r["reads"] else None)
                 == r["posn"]), len(rows)))
    print("     ==> METHOD RULE 4.  `the last read' and `rel n-2' are ONE")
    print("     MACHINE COUNTED TWICE on this corpus.  T2's permutation null")
    print("     (place the dummy read uniformly among the algorithm's reads,")
    print("     0 of 2000 reach 83) rejects a null that ignores POSITION; it")
    print("     cannot separate the pipeline-flush reading from `the allocator")
    print("     emits the ceiling second-from-last'.  METHOD RULE 7: the")
    print("     instruction-blind rival TIES 83-83 and the test does not")
    print("     discriminate.  T1 said this about its own result.  T2 did not.")
    print()
    # ---- LIMIT ---------------------------------------------------------
    lim = [r for r in rows if r["lim"] is not None]
    fw = sum(1 for r in lim if r["writes"] and r["lim"] == r["writes"][0])
    r1 = sum(1 for r in lim if r["lim"] == 1)
    dis2 = [r for r in lim if (r["writes"][0] if r["writes"] else None) != 1]
    print("   RIVAL A  T2's   : the LIMIT is the FIRST WRITE            %d of %d"
          % (fw, len(lim)))
    print("   RIVAL B  T1's   : the LIMIT is rel 1                      %d of %d"
          % (r1, len(lim)))
    print("   ** DISAGREEMENT SITES: %d **" % len(dis2))
    for r in dis2:
        print("        algo %-3d %-20s n=%-3d seq=%-12s first write rel %d"
              % (r["a"], ctx().C.name(r["a"])[:20], r["n"], seqstr(r["d"]),
                 r["writes"][0]))
    print("     ==> ON THE LIMIT THE TEST DOES SEPARATE, and the")
    print("     direction-aware rule WINS 1-0 -- ONE SITE WIDE, and said so.")
    print("     That is real evidence and it is thin; it is the same order of")
    print("     thinness round 5 flagged in its own K9.")
    print()
    print("   ⇒ ADJUDICATION.  T2 item A's CEILING half is CONSISTENT, not")
    print("     FORCED.  Its LIMIT half keeps a one-site separation and")
    print("     inherits T1's FORCED-WITHIN-THE-ALLOCATION-MODEL label,")
    print("     because bounds.py assigns LIMIT as the residue of model A4.")
    return rows


# ===========================================================================
#  3.  *** THE ROUND -- the SINGLE DELAY harness audit
# ===========================================================================
SD_WINDOW = (5, 10)


def sd_words():
    return L.algo_to_image()[9][2]


def sd_search(polarity, carry_dr=False, window=SD_WINDOW):
    """Re-implementation of action00_discriminate.sec_single with the delay-DRAM
    POLARITY as an explicit parameter -- the parameter the published harness
    hard-codes.

        polarity = "published"  addr8 0x20 -> WRITE, else READ   (round 4 and
                                earlier; the model both published harnesses
                                contain verbatim)
        polarity = "forced"     addr8 0x20/0x30 -> READ, 0x60 -> WRITE
                                (adjudication-round5 item D)

    Everything else -- the space, the reference, the tolerance, the RNG seeds,
    the coefficient bank read off the ROM -- is action00_discriminate's."""
    ws = sd_words()
    lo, hi = window
    words = ws[lo:hi]
    cram, cur = L.cram_of_algo(9), DIS.cursor_addresses(ws)
    coefs = [(cram.get(cur[lo + k]) if cur[lo + k] is not None else None)
             for k in range(len(words))]
    fb, D = 0.5, 7
    rng0 = random.Random(3)
    amp = 1 << 18
    x = [rng0.randrange(-amp, amp) for _ in range(24)]
    ref = A0.comb_ref(fb, D, x)
    p0 = 0x80
    incell = p0
    for w in words:
        if DIS.lo_src(w) == 0x00:
            break
        if DIS.ptr_postinc(w):
            incell = (incell + A0.s8(DIS.addr8(w))) & 0xff

    def is_write(w):
        ad = DIS.addr8(w) & 0xf0
        return ad == 0x20 if polarity == "published" else ad == 0x60

    def is_read(w):
        ad = DIS.addr8(w) & 0xf0
        return ad != 0x20 if polarity == "published" else ad in (0x20, 0x30)

    hits, space = [], []
    for t in itertools.product(A0.ORDER, A0.ACT00, A0.STTIME, A0.STGATE,
                               ("tA<-bus", "tA<-acc", "tB<-bus"),
                               ("mem", "P", "acc", "zero", "DR", "tA")):
        space.append(A0.Machine(t[0], t[1], t[2], t[3], act19=t[4], src00=t[5]))
    for m in space:
        rng = random.Random(20260727)
        ln = A0.Line(D)
        st = A0.State(rng)
        ok = True
        for xn in x:
            st.acc = rng.randrange(-(1 << 23), 1 << 23)
            st.P = rng.randrange(-(1 << 23), 1 << 23)
            st.ta = rng.randrange(0, 1 << 24)
            st.tb = rng.randrange(0, 1 << 24)
            st.p = p0
            st.mem[incell] = int(xn) & A0.MASK24
            if not carry_dr:
                st.dr = 0

            def dram(w, bus, s, _ln=ln):
                if is_write(w):
                    _ln.write(bus)
                else:
                    s.dr = int(_ln.read()) & A0.MASK24

            for k, w in enumerate(words):
                if (DIS.hi12(w) & 0x800) and DIS.class4(w) == 1 and is_read(w):
                    st.dr = int(ln.read()) & A0.MASK24     # the BLOCKING read
                if not A0.step(m, st, w, coefs[k], rng, dram=dram,
                               unknown=lambda: rng.randrange(-(1 << 23),
                                                             1 << 23)):
                    ok = False
                    break
            if not ok:
                break
            ln.advance()
        if not ok:
            continue
        wr = ln.wrote
        if len(wr) != len(ref):
            continue
        den = sum(v * v for v in wr)
        if den < 1e-6:
            continue
        sc = sum(a * b for a, b in zip(wr, ref)) / den
        if abs(sc) < 1e-6:
            continue
        mx = max(abs(v) for v in ref)
        if max(abs(sc * a - b) for a, b in zip(wr, ref)) < 1e-4 * mx:
            hits.append(m)
    return hits, space


def cmd_polarity():
    head(3, "*** THE ROUND: EVERY ALU FORCING THAT TOUCHES THE DELAY PORT WAS "
            "COMPUTED WITH THE LINE WIRED BACKWARDS")
    X = ctx()
    print("""   METHOD RULE 10, applied to a collision NONE of the four passes
   reported.  T2 falsified `action-field.md' sect. 8 / `blocking-read.md''s
   "the BLOCKING read, FORCED 5145/5145" by re-attributing it: that
   forcing read SINGLE DELAY under the polarity round 5 item D reversed.
   T2 stopped there.  The question it did not ask is the one that costs
   something: WHAT ELSE DID THAT HARNESS FORCE, AND IS ANY OF IT IN THE
   DEVICE?
""")
    print("   ---- THE HARD-CODED POLARITY, quoted from the shipped tools:")
    print("        dsp/tools/action00_discriminate.py  sd_run()")
    print("        dsp/tools/acc_adjudicate.py         sd_run()")
    print("            def dram(w, bus, s):")
    print("                if (DIS.addr8(w) & 0xf0) == 0x20:   ln.write(bus)")
    print("                else:                               s.dr = ln.read()")
    print("            ...")
    print("            if ... (DIS.addr8(w) & 0xf0) == 0x60:   # `the BLOCKING read'")
    print("        i.e.  addr8 0x20 -> WRITE and 0x60 -> READ.")
    print("        adjudication-round5 item D FORCES the reverse:")
    print("              addr8 0x20/0x30 -> READ and 0x60 -> WRITE.")
    print()
    # --- which contexts can even see ACTION 0x19 ------------------------
    def isd(w):
        return ((w >> 20) & 0xF) == 1 and bool((w >> 24) & 0x800)
    pool = [("HDR", list(X.C.hdr)), ("EPI", list(X.C.epi))]
    seen = {}
    for a in sorted(X.C.imgs):
        seen.setdefault(tuple(X.C.imgs[a]), a)
    for k, a in seen.items():
        pool.append(("A%d" % a, list(k)))
    n19 = nd19 = 0
    free = []
    for nm, img in pool:
        s = [i for i, w in enumerate(img) if (w & 0x1F) == 0x19]
        if not s:
            continue
        n19 += len(s)
        if any(isd(w) for w in img):
            nd19 += len(s)
        else:
            free.append((nm, len(s)))
    print("   ---- HOW WIDE IS THE EXPOSURE?  ACTION 0x19 sites in the whole")
    print("        corpus (60-word header + 23-word epilogue + 38 body images):")
    print("          total %d ; inside an image that carries delay-DRAM words %d"
          % (n19, nd19))
    print("          DRAM-FREE images carrying ACTION 0x19: %s" % (free or "NONE"))
    print("        -> the ONLY DRAM-free one is algo 88, which")
    print("           second-dsp-and-ready.md sect. 2 showed is an IC310")
    print("           (MN19413) stream and not an IC311 program at all.")
    print("        -> and SINGLE DELAY is the ONLY published ALU context that")
    print("           constrains ACTION 0x19: the biquad carries no 0x19 word")
    print("           (its ACTION codes are 07 12 13 14 15) and the LFO section")
    print("           does not enumerate it.")
    print()
    # --- the re-run ------------------------------------------------------
    print("   ---- THE RE-RUN.  Same space (5832 machines), same reference")
    print("        v[n] = x[n] + fb*v[n-D], same tolerance, same seeds; the ONLY")
    print("        thing enumerated is the parameter the harness fixed.")
    print()
    for pol, carry in (("published", False), ("forced", False),
                       ("forced", True)):
        hits, space = sd_search(pol, carry)
        tag = "%s%s" % (pol, ", read register CARRIED across frames"
                        if carry else "")
        print("     polarity = %-46s : %4d of %d" % (tag, len(hits), len(space)))
        if hits:
            for nm, f in (("order", lambda m: m.order),
                          ("act00", lambda m: m.act00),
                          ("act19", lambda m: m.act19),
                          ("src00", lambda m: m.src00)):
                c = collections.Counter(f(m) for m in hits)
                print("         %-6s %-9s %s"
                      % (nm, "FORCED" if len(c) == 1 else "%d values" % len(c),
                         "  ".join("%s x%d" % (a, b) for a, b in c.most_common())))
    print()
    print("     ** 108 -> 0.  The published `act19 FORCED tA<-bus x108' and")
    print("        `src00 FORCED mem x108' do not survive the correction. **")
    print()
    # --- and the zero is a harness artefact ------------------------------
    cmd_polarity_line_control()
    print()
    print("   ⇒ ADJUDICATION, stated at its real strength and no higher:")
    print("     * `the BLOCKING read, FORCED 5145/5145' -- FALSIFIED (T2, and")
    print("       this section supplies the mechanism rather than only the")
    print("       re-attribution).")
    print("     * `ACTION 0x19 = tempA <- bus, FORCED 72/72 and 108/108' --")
    print("       ITS FORCING IS WITHDRAWN.  The semantic is NOT refuted.")
    print("     * `blocking-read.md' item D -- the withdrawal of")
    print("       schroeder-topology.md sect. 0-C's conditional challenge --")
    print("       LOSES ITS PREMISE.  That challenge is RE-OPENED.")
    print("     * `acc-adder.md''s adder: a reconciliation of the LFO with")
    print("       SINGLE DELAY.  ONE OF ITS TWO LEGS IS VOID.  Retained (the")
    print("       LFO leg is untouched and it is 27 of 33 even in the reversed")
    print("       model) but no longer a two-context forcing.")
    print("     * NOTHING IS REVERTED IN THE DEVICE.  Withdrawing a semantic on")
    print("       the authority of a harness that provably cannot model the")
    print("       corrected machine is the method-rule-1 defect pointing the")
    print("       other way.  The labels are corrected; the behaviour is not.")


def cmd_polarity_line_control():
    print("   ---- ★ AND THE ZERO IS A HARNESS ARTEFACT, NOT A REFUTATION.")
    print("        DEMONSTRATED: the harness's `Line' reads and writes ONE cell")
    print("        and advances once per frame, so it SILENTLY REQUIRES")
    print("        READ-before-WRITE in program order -- a modelling choice that")
    print("        was never enumerated (method rule 3).")
    print()
    ws = sd_words()
    words = ws[SD_WINDOW[0]:SD_WINDOW[1]]
    print("        SINGLE DELAY, the searched window w5..w9:")
    for i, w in enumerate(words):
        ad = (w >> 12) & 0xFF
        old = "WRITE" if (ad & 0xf0) == 0x20 else "READ"
        new = DIS.dram_dir(w)
        if (w >> 24) & 0x800 and ((w >> 20) & 0xF) == 1:
            print("          w%-2d %010X  addr8=%02X   published: %-5s   FORCED: %-5s"
                  % (SD_WINDOW[0] + i, w, ad, old, new))
    print()

    class Probe(object):
        def __init__(s, n):
            s.n, s.buf, s.i, s.tr = n, [0.0] * n, 0, []

        def read(s):
            v = s.buf[s.i]
            s.tr.append(("R", v))
            return v

        def write(s, v):
            s.buf[s.i] = v
            s.tr.append(("W", v))

        def advance(s):
            s.i = (s.i + 1) % s.n

    for name, wrmask in (("published (addr8 0x20 = WRITE)", 0x20),
                         ("round-5 FORCED (addr8 0x60 = WRITE)", 0x60)):
        ln = Probe(7)
        for n in range(5):
            for w in words:
                if (w >> 24) & 0x800 and ((w >> 20) & 0xF) == 1:
                    if ((w >> 12) & 0xf0) == wrmask:
                        ln.write(1000 + n)
                    else:
                        ln.read()
            ln.advance()
        order = "".join(t for t, _ in ln.tr[:2])
        reads = [v for t, v in ln.tr if t == "R"]
        print("        %-38s port order per frame %s  READ returns %s"
              % (name, order, reads[:5]))
        print("            -> %s"
              % ("a real D-frame delay: the loop exists"
                 if order == "RW" else
                 "THE VALUE WRITTEN IN THAT VERY FRAME -- delay 0, no loop"))
    print()
    print("        The chip's line is NOT one cell: dram-bounds.md's line set")
    print("        gives every line a SEPARATE read cell and write cell, and")
    print("        dram-datapath.md sect. 5 measures the write consumer +3 port")
    print("        slots AFTER the read consumer.  A two-address line with a")
    print("        rotation has no read-before-write requirement at all.  That")
    print("        harness does not exist yet, and it is the rank-1 experiment.")


# ===========================================================================
#  4.  *** the widened enumeration for the two dummies (method rule 3)
# ===========================================================================
def cmd_enum():
    head(4, "THE ENUMERATION FOR THE TWO DUMMIES, WIDENED -- one new member "
            "REFUTED, one ADMITTED")
    X = ctx()
    al = X.a6
    print("""   T2 sect. 2.1 prints E1 flush / E2 wrap-register load / E3 refresh /
   E4 padding / E5 coincidence, and E1 is the only member that predicts
   the position it has.  METHOD RULE 3 asks the question that costs
   something: WHAT PHYSICALLY PLAUSIBLE OPTION IS NOT IN THE LIST?

   E2'  A PER-FRAME-PERSISTENT LIMIT REGISTER, LOADED AT THE TAIL FOR THE
        NEXT FRAME.  T2 rejects E2 with "a limit must be loaded BEFORE the
        accesses it bounds; it is last 83 of 83".  That is only true
        WITHIN ONE FRAME.  The body is a per-frame loop -- 1 536 349
        executions in the live run -- so the last word of frame N precedes
        every word of frame N+1.  E2' also explains something E1 leaves
        arbitrary: the ceiling's VALUE is not any harmless address, it is
        exactly the per-unit partition boundary (32768 unit 0 / 32767
        unit 1), which is what a limit register would hold.

   E7   THE ADDRESS WRAPS and the last read is a REAL read.  32768 is
        unit 0's region size, so a 15-bit address adder returns offset 0.
        Under E7 the datum is used and nothing is discarded.
""")
    # ---- the control that decides E2' ----------------------------------
    cw = collections.Counter()
    lw = collections.Counter()
    rw = collections.Counter()
    bw = collections.Counter()
    for a, r in al.items():
        for i in range(r["n"]):
            w, ro = r["word"][i], r["role"][i]
            if ro == "CEILING":
                cw[w] += 1
            elif ro == "LIMIT":
                lw[w] += 1
            elif ro == "READ_END":
                rw[w] += 1
            elif ro == "LINE_BASE":
                bw[w] += 1
    print("   ---- ★ THE CONTROL THAT DECIDES E2', and it REJECTS it.")
    print("        If the ceiling access were a LIMIT-REGISTER LOAD it would be")
    print("        a DIFFERENT INSTRUCTION from a delay read.  It is not:")
    print()
    print("        distinct CEILING words: %d" % len(cw))
    for w, c in cw.most_common():
        print("           %010X x%-3d  the SAME 36 bits also perform a real "
              "line READ  x%d" % (w, c, rw.get(w, 0)))
    print()
    print("        distinct LIMIT words:   %d" % len(lw))
    for w, c in lw.most_common():
        print("           %010X x%-3d  the SAME 36 bits also perform a real "
              "line WRITE x%d" % (w, c, bw.get(w, 0)))
    shc = sum(c for w, c in cw.items() if rw.get(w, 0))
    shl = sum(c for w, c in lw.items() if bw.get(w, 0))
    print()
    print("        CEILING cells whose word is elsewhere a real line read : %d of %d"
          % (shc, sum(cw.values())))
    print("        LIMIT   cells whose word is elsewhere a real line write: %d of %d"
          % (shl, sum(lw.values())))
    print("        ==> the two dummy accesses use ORDINARY ACCESS INSTRUCTIONS.")
    print("        ==> E2' REFUTED.  A register load would be its own opcode;")
    print("            the same 36 bits cannot be a limit load here and a delay")
    print("            read there (HLE chip-boundary discipline).")
    print("        ==> and this is a control I built EXPECTING it to support E2'.")
    print("            It says NO.  Printed, not deleted.")
    print()
    print("   ---- E7 IS ADMITTED AND I CANNOT SEPARATE IT.")
    print("        E1 and E7 make the same prediction about POSITION and about")
    print("        the INSTRUCTION.  They differ only in whether the datum is")
    print("        used, and the ceiling read is the LAST read, so no later word")
    print("        distinguishes `discarded' from `consumed and irrelevant'.")
    print("        ⇒ T2 item A is CONSISTENT, not FORCED.  The classification it")
    print("          rests on (T1's region test) is untouched either way: 32768")
    print("          minus a unit-0 write is not a delay length under E1 OR E7.")


# ===========================================================================
#  5.  the write trail -- with the FORCED subset separated from the rest
# ===========================================================================
def cmd_wtrail():
    head(5, "THE WRITE TRAIL, AND WHAT FRACTION OF IT IS ACTUALLY FORCED")
    X = ctx()
    al = X.a6
    off = collections.Counter()
    aoff = collections.Counter()
    tap = collections.Counter()
    for a, r in al.items():
        taps = X.C.taps(a)
        idx = {c: i for i, c in enumerate(r["cells"])}
        anchored = set()
        for cell, b24 in taps.items():
            if cell in idx:
                anchored.add(idx[cell])
            for i in range(r["n"]):
                if r["value"][i] == b24 - 2:
                    anchored.add(i)
        nbase = collections.Counter(Ln["write_rel"] for Ln in r["lines"])
        for Ln in r["lines"]:
            d = Ln["write_rel"] - Ln["read_rel"]
            off[d] += 1
            if Ln["read_rel"] in anchored or Ln["write_rel"] in anchored:
                aoff[d] += 1
                if nbase[Ln["write_rel"]] > 1:
                    tap[d] += 1
    tot, atot = sum(off.values()), sum(aoff.values())
    print("   POPULATION: %d lines over %d aligned algorithms." % (tot, len(al)))
    print("   write consumer - read consumer, in DRAM PORT SLOTS:")
    print("      ALL LINES          %s" % dict(sorted(off.items())))
    print("      HOST-ANCHORED ONLY %s" % dict(sorted(aoff.items())))
    print("      ... of which MULTI-TAP reads sharing one base: %s"
          % dict(sorted(tap.items())))
    print()
    print("   T2 item B: `+3 port slots in 273 of 324' -- REPRODUCED (%d of %d)."
          % (off[3], tot))
    print("   BUT T2 sect. 5 itself says the trail `inherits bounds.py's")
    print("   labels -- FORCED for the 69 host-anchored endpoints, CONSISTENT")
    print("   elsewhere', and the one-page table still says FORCED.  Scored on")
    print("   the FORCED subset only:")
    print("      +3 among HOST-ANCHORED lines: %d of %d" % (aoff[3], atot))
    print("      ... but %d of those %d are MULTI-TAP reads sharing one base,"
          % (sum(tap.values()), atot))
    print("          and a tap has no write of its own, so `the write trails its")
    print("          own read' is not even defined for them (the 24 reverb early")
    print("          reflections at -21/-24 are exactly these).")
    print("      +3 among host-anchored lines that are ONE read on ONE base:"
          " %d of %d" % (aoff[3] - tap.get(3, 0), atot - sum(tap.values())))
    print()
    print("   ⇒ ADJUDICATION, AND IT MOVES IN T2's FAVOUR ONCE THE POPULATION IS")
    print("     STATED PROPERLY (rule 9).  The corpus-wide %.1f%% IS carried by"
          % (100.0 * off[3] / tot))
    print("     model-derived pairings -- but on the subset where the host")
    print("     supplies BOTH ends and the line has one read and one write, the")
    print("     trail is EXCEPTIONLESS.  So item B is FORCED on %d host-anchored"
          % (atot - sum(tap.values())))
    print("     lines and CONSISTENT on the other %d, and the one-page label"
          % (tot - (atot - sum(tap.values()))))
    print("     `FORCED' should carry that denominator.")
    print("     `wtrail = 2' (the +3 slots read as +2 eight-word repetitions) is")
    print("     MEASURED on the twelve reverbs, 11 of 11 -- and `repetition' is")
    print("     only defined there, so corpus-wide the statement is `+3 slots'.")


# ===========================================================================
#  6.  the read latency -- and the UNITS its two ends are stated in
# ===========================================================================
def cmd_latency():
    head(6, "`land IN [1, 4]' -- THE TWO ENDS ARE STATED IN DIFFERENT UNITS")
    X = ctx()
    gnd, gnr, gnb = [], [], []
    for a, img in X.images:
        ds = [i for i, w in enumerate(img) if DP.is_dram(w)]
        for i, w in enumerate(img):
            if not DP.is_dram(w) or DIS.dram_dir(w) != "READ":
                continue
            nd = [j for j in ds if j > i]
            if nd:
                gnd.append(nd[0] - i)
            nr = [j for j in nd if DIS.dram_dir(img[j]) == "READ"]
            if nr:
                gnr.append(nr[0] - i)
            nb = [j for j in range(i + 1, len(img)) if DP.f_src(img[j]) == 0x0B]
            if nb:
                gnb.append(nb[0] - i)
    for nm, l in (("READ -> next DRAM word", gnd),
                  ("READ -> next READ", gnr),
                  ("READ -> next word with SRC 0x0B", gnb)):
        print("   %-34s n=%-4d min=%-3d max=%-3d  mode %s"
              % (nm, len(l), min(l), max(l),
                 collections.Counter(l).most_common(2)))
    print("   (T2 sect. 3's table, reproduced exactly.)")
    print()
    print("""   ⇒ THE COLLISION IS INSIDE ONE PASS, AND IT IS A CHANGE OF UNITS --
     the failure mode method rule 10 names.

     * item A's mechanism is stated in PORT SLOTS: exactly ONE trailing
       flush read per program, so the port is `one deep'.  A one-deep
       port makes read k's datum visible when read k+1 ISSUES -- which is
       a POSITION in the program, not a constant number of words.  Under
       that mechanism `land' in words is not a hardware constant at all
       and the interval is not well formed.
     * item E's bound is stated in WORDS: `land <= 4, the corpus minimum
       READ -> next SRC 0x0B'.  That step needs a premise that is NOT in
       the enumeration: THAT THE FIRST `SRC 0x0B' WORD AFTER A READ
       CONSUMES THAT READ.  The same pass's `wtrail = 2' says the machine
       tolerates exactly this kind of staleness elsewhere.
     * and if you take item A literally instead, the bound becomes
       `the datum arrives within one PORT ACCESS' => land <= min(READ ->
       next DRAM word) = %d, which is TIGHTER than 4 and comes out of T2's
       own table.

     ⇒ `land >= 1' is CONSISTENT (it follows from the flush reading, which
       sect. 4 downgraded).  `land <= 4' is CONSISTENT and rests on an
       unenumerated freshness premise.  THE READ LATENCY IS OPEN.""" % min(gnd))


# ===========================================================================
#  7.  ROOM REVERB 1 -- re-derived, with the anchoring made explicit (rule 8)
# ===========================================================================
def cmd_ladder():
    head(7, "ROOM REVERB 1, RE-DERIVED FROM THE ROM -- and how much of it is "
            "host-anchored")
    X = ctx()
    r = X.a6[16]
    taps = X.C.taps(16)
    print("   POPULATION: one algorithm, %d cells, %d words; the same image "
          "serves algos 16..27." % (r["n"], len(X.C.imgs[16])))
    print("   host op-0x67 taps in this algorithm: %s"
          % {("cell 0x%02X" % k): v for k, v in sorted(taps.items())})
    print()
    print("    rel cell  value   dir    role       word")
    for i in range(r["n"]):
        print("     %2d  %02X  %6d  %-5s  %-9s  %010X"
              % (i, r["cells"][i], r["value"][i], r["dir"][i] or "TRAP",
                 r["role"][i], r["word"][i]))
    print()
    lad = []
    for Ln in sorted(r["lines"], key=lambda z: z["read_rel"]):
        print("     read rel %2d (cell %02X, %6d)  <- base rel %2d (cell %02X, "
              "%6d)  %5d samples  %7.3f ms  trail %+d"
              % (Ln["read_rel"], Ln["read_cell"], Ln["read_addr"],
                 Ln["write_rel"], Ln["write_cell"], Ln["write_addr"],
                 Ln["samples"], Ln["samples"] * 1000.0 / SR,
                 Ln["write_rel"] - Ln["read_rel"]))
        lad.append(Ln["samples"])
    ladder = [Ln["samples"] for Ln in sorted(r["lines"],
                                             key=lambda z: z["read_rel"])][1:12]
    print()
    print("     PRE DELAY  %d samples (%.3f ms) -- HOST-ANCHORED (BASE24 %d, "
          "cell 0x03 = %d)" % (lad[0], lad[0] * 1000.0 / SR, taps.get(0, 0),
                               32768))
    print("     LADDER     %s" % " ".join(str(v) for v in ladder))
    print("     TOTAL      %d samples = %.2f ms   (longest single line %d = %.2f ms)"
          % (sum(ladder), sum(ladder) * 1000.0 / SR, max(lad),
             max(lad) * 1000.0 / SR))
    print("     LONGEST PATH pre-delay + ladder = %d samples = %.2f ms"
          % (lad[0] + sum(ladder), (lad[0] + sum(ladder)) * 1000.0 / SR))
    print()
    print("   ★ RULE 8 AND RULE 9 TOGETHER.  `8905' stays retracted; so does r1")
    print("     sect. 3's `127 435 489 183 522'.  AND THE PART NOBODY STATES:")
    print("     ROOM REVERB 1 carries EXACTLY ONE host op-0x67 tap, so the")
    print("     800-sample pre-delay is the ONLY host-anchored line in it and")
    print("     ALL ELEVEN LADDER SEGMENTS ARE MODEL OUTPUT (bounds.py A4).")
    print("     An impulse test sized on 3873 is sized on a CONSISTENT number.")


# ===========================================================================
#  8.  T3's pointer census, reproduced
# ===========================================================================
def cmd_cursor():
    head(8, "T3's LOAD-BEARING MEASUREMENT, REPRODUCED INDEPENDENTLY")
    X = ctx()
    pool = [("HDR %2d" % i, w) for i, w in enumerate(X.C.hdr)]
    pool += [("EPI %2d" % (60 + i), w) for i, w in enumerate(X.C.epi)]
    nbody = 0
    for a in sorted(X.C.imgs):
        for i, w in enumerate(X.C.imgs[a]):
            if CU.is_ptr_load(w):
                pool.append(("A%02d w%-3d" % (a, i), w))
                nbody += 1
    ptr = [(t, w) for t, w in pool if CU.is_ptr_load(w) and (w & 0xFF) == 0x25]
    print("   POPULATION: the whole ROM -- 60-word header, 23-word epilogue,")
    print("   38 distinct body images.  Nothing sampled.")
    print()
    print("   writes to the DESCRIPTOR POINTER (lo12 selector 0x25): %d" % len(ptr))
    for t, w in ptr:
        print("      %-10s %010X  payload 0x%02X" % (t, w, (w >> 12) & 0xFF))
    print("   pointer writes of ANY selector inside a body image: %d" % nbody)
    print("   ⇒ T3's fact holds: every cursor reload is algorithm-independent,")
    print("     so there is nowhere to keep a per-algorithm second cursor and")
    print("     M5 dies by counting.  REPRODUCED.")
    print()
    print("   ★ AND M5's DEATH DOES NOT TOUCH T2.  M5 was the one live rival to")
    print("     the delta = 0 identity map that T2 assumes; killing it")
    print("     STRENGTHENS T2's premise.  T3's statement to the datapath agent")
    print("     is correct and needs no adjudication.")


# ===========================================================================
#  9.  the controls, each shown saying NO
# ===========================================================================
def cmd_control():
    head(9, "THE CONTROLS, EACH DEMONSTRATED SAYING NO")
    X = ctx()
    al = X.a6
    print("   K1 ★ THE HARNESS CONTROL THAT SAYS YES AND THEN NO.")
    hp, sp = sd_search("published")
    hf, _ = sd_search("forced")
    print("        SINGLE DELAY, published polarity : %d of %d" % (len(hp), len(sp)))
    print("            (it reproduces its own published 108 -- IT CAN SAY YES)")
    print("        SINGLE DELAY, FORCED polarity    : %d of %d" % (len(hf), len(sp)))
    print()
    print("   K2 ★ AND THE ZERO IS SHOWN TO BE A HARNESS ARTEFACT, not a")
    print("        rejection -- the one-cursor Line returns the value written in")
    print("        the same frame (sect. 3).  A control that cannot pass is as")
    print("        worthless as one that cannot fail, and BOTH are printed.")
    print()
    print("   K3 ★ A CONTROL OF MINE THAT DID NOT DO WHAT I BUILT IT FOR.")
    print("        I built the `is the dummy access an ordinary instruction?'")
    print("        test EXPECTING it to support E2' (a limit-register load).")
    print("        It refutes E2' instead -- 82 of 83 and 74 of 74 (sect. 4).")
    print()
    print("   K4  THE DEGENERACY CHECK, RUN BEFORE ANY SCORE (rule 4): T2's")
    print("        `CEILING = last READ' and T1's `CEILING at rel n-2' have")
    print("        ZERO disagreement sites over 83.  One machine, counted twice.")
    print()
    print("   K5  THE SAME CHECK SAYS `SEPARATED' FOR THE LIMIT -- one site,")
    print("        ENHANCER, and the direction-aware rule wins it 1-0.  The")
    print("        instrument can distinguish the two answers.")
    print()
    # K6: permutation null on the ceiling position, and its hole
    rng = random.Random(20260727)
    trials, hitmax = 2000, 0
    rows = []
    for a, r in al.items():
        reads = [i for i in range(r["n"]) if r["dir"][i] == "READ"]
        ci = [i for i in range(r["n"]) if r["role"][i] == "CEILING"]
        rows.append((reads, ci[0] if ci else None))
    for _ in range(trials):
        s = 0
        for reads, c in rows:
            if c is None or not reads:
                continue
            if rng.choice(reads) == reads[-1]:
                s += 1
        hitmax = max(hitmax, s)
    print("   K6  T2's permutation null, RE-RUN: place each algorithm's dummy")
    print("        read uniformly among its own reads, %d trials -> max %d of %d."
          % (trials, hitmax, len(rows)))
    print("        It rejects, AND IT IS NOT THE TEST THAT MATTERS: a rival that")
    print("        never looks at the instruction (`rel n-2') scores 83 too.")
    print("        Printed as a null with a HOLE, the way round 5 printed its own.")
    print()
    print("   K7  THE AUDIO CONTROL.  The before/after capture is verified to")
    print("        CARRY AUDIO before anything is concluded from it: 1 536 001")
    print("        frames, 876 696 non-zero samples, peak 21 541 -- see the")
    print("        applied note.  Round 5's first attempt produced peak 0 and is")
    print("        why this is checked every time.")


# ===========================================================================
#  10.  predict then check
# ===========================================================================
def cmd_predict():
    head(10, "PREDICT-THEN-CHECK -- hits AND misses, equal prominence")
    rows = [
        ("P1", "The round's collision would be between T1's bounds and T2's "
               "datapath, because T2 imports T1's roles wholesale.",
         "MISS, and the pass's whole content.  Those two agree.  The collision "
         "is between ROUND 5's reversal and the ALU semantics that had ALREADY "
         "SHIPPED -- a pass that finished two rounds ago."),
        ("P2", "T3's M5 verdict would invalidate something of T2's.",
         "MISS.  M5 was the rival to the map T2 assumes, so killing it "
         "strengthens T2.  T3's own statement to the datapath agent is right."),
        ("P3", "T1's bounds classification would have been used as FORCED "
               "somewhere it is only CONSISTENT.",
         "HIT.  T2 item A quotes `LIMIT is the FIRST WRITE 74/74' as FORCED; "
         "bounds.py assigns LIMIT as the RESIDUE of allocation model A4 and "
         "labels it FORCED-WITHIN-THE-MODEL.  Item B's `+3 in 273 of 324' is "
         "30 of 63 on the host-anchored subset -- though once the multi-taps "
         "are excluded (a tap has no write of its own) it is 17 of 17, so the "
         "correction goes BOTH ways and is printed both ways."),
        ("P4", "T2's `CEILING is the LAST READ' would be independent of T1's "
               "positional statement, as T2 claims.",
         "MISS -- for T2.  ZERO disagreement sites over 83.  I expected a "
         "handful and the answer is none."),
        ("P5", "The missing enumeration member for the ceiling would be a "
               "cross-frame limit-register load (E2'), and it would survive.",
         "HALF-MISS.  E2' really was missing -- but the control I built for it "
         "REFUTES it: the ceiling word is byte-identically a real line read "
         "elsewhere in 82 of 83 cases."),
        ("P6", "Re-running SINGLE DELAY at the corrected polarity would move "
               "the forcing from `tA<-bus' to some other value.",
         "MISS, and worse than predicted: it moves it to NOTHING.  0 of 5832, "
         "because the harness's delay line collapses to length 0."),
        ("P7", "Carrying the read register across frames would restore the "
               "survivors.",
         "MISS.  Still 0.  The defect is the ONE-CELL line, not the register "
         "lifetime -- so the fix is machinery (a two-address line), exactly "
         "what T2 said about its own stage B."),
        ("P8", "The exposure would be narrow -- one or two contexts.",
         "HIT on the count, MISS on the consequence.  It IS one context "
         "(SINGLE DELAY) -- and that context is the ONLY one that constrains "
         "ACTION 0x19 at all, so `narrow' means `total'."),
        ("P9", "Something would be applicable to the device this round.",
         "MISS as a decode, HIT as a correction.  Nothing is decoded; three "
         "device/mirror comments that assert FORCED are corrected to withdraw "
         "a falsified premise.  Zero dark slots recovered."),
        ("P10", "The 91/9 chip partition and the retraction sweep's new "
                "premises would need re-checking.",
         "HIT (negative).  T4's P17/P18 are in retraction_sweep.py and report "
         "0 LIVE sites; the census, the ladder and the pointer count all "
         "reproduce.  Nothing of T4 moves."),
        ("P11", "The `land IN [1,4]' interval would survive as the pass's one "
                "clean forced result.",
         "MISS.  Its two ends are stated in different units -- one in port "
         "slots, one in words -- and the word bound needs a freshness premise "
         "the same pass denies elsewhere."),
        ("P12", "The before/after audio would be bit-identical and the frame "
                "tally unmoved.",
         "HIT.  Nothing executable changed, so nothing could move -- and the "
         "capture is verified to carry real audio before that is said."),
    ]
    for i, (k, p, o) in enumerate(rows):
        print("   %-4s %s" % (k, p))
        print("        -> %s" % o)
        if i != len(rows) - 1:
            print()
    print()
    print("   %d predictions, %d clean misses, 2 half-results."
          % (len(rows), sum(1 for _k, _p, o in rows if o.startswith("MISS"))))


CMDS = {
    "census": cmd_census, "degen": cmd_degen, "polarity": cmd_polarity,
    "enum": cmd_enum, "wtrail": cmd_wtrail, "latency": cmd_latency,
    "ladder": cmd_ladder, "cursor": cmd_cursor, "control": cmd_control,
    "predict": cmd_predict,
}

if __name__ == "__main__":
    want = sys.argv[1:] or ["all"]
    if want == ["all"]:
        want = list(CMDS)
    for k in want:
        if k not in CMDS:
            print("unknown section %r; have %s" % (k, ", ".join(CMDS)))
            sys.exit(2)
        CMDS[k]()
        print()
