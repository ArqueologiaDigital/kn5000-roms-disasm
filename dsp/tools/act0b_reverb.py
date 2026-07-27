#!/usr/bin/env python3
"""ACTION 0x0B at the reverb's own sites -- the first discriminator it has had.

`target4.py act0b' found the first minimal pair for ACTION 0x0B and said what it
could not do: *"WHAT IT DOES NOT SETTLE: what ACTION 0x0B writes, because
nothing downstream in either program has been shown to read a register the two
versions would differ in."*  The reverb now supplies that reader -- it became
runnable when `cram-unit-base.md' fixed the per-unit C-RAM base.

    python3 dsp/tools/act0b_reverb.py           # everything
    python3 dsp/tools/act0b_reverb.py census    # the 82 corpus sites
    python3 dsp/tools/act0b_reverb.py wdata     # ★ the control that cannot fail
    python3 dsp/tools/act0b_reverb.py partition # how the six readings separate

See ../analysis/act0b-reverb.md.
"""
import collections
import itertools
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import action00_discriminate as A0    # noqa: E402
import delayline as DL                # noqa: E402
import dsp_disasm as DIS              # noqa: E402

ALGO = 16                 # ROOM REVERB 1, the image algos 16..27 share
WIN = (12, 59)            # w012..w058: the largest runnable window, BLOCK A x5
NFRAMES = 96
NMACH = 150
ACT19 = ("tA<-bus", "tA<-acc", "tB<-bus")
SRC00 = ("mem", "P", "acc", "zero", "DR", "tA")


def hdr(t):
    print("\n" + "=" * 78 + "\n== %s\n" % t + "=" * 78)


def space():
    s = list(itertools.product(A0.ORDER, A0.ACT00, A0.STTIME, A0.STGATE,
                               ACT19, SRC00))
    random.Random(11).shuffle(s)
    return s[:NMACH]


def setup():
    P = DL.program(ALGO)
    cf = DL.coefs_of(ALGO, P.words)
    rng0 = random.Random(3)
    amp = 1 << 18
    x = [rng0.randrange(-amp, amp) for _ in range(NFRAMES)]
    return P, cf, x


def run(P, cf, x, m, h):
    port, ok = DL.run_words(P, m, h, x, cf, window=WIN)
    if not ok:
        return None
    return tuple((k, a, v) for (_f, _s, k, a, _p, v, _t) in port.trace)


def cmd_census():
    hdr("THE 82 CORPUS SITES -- and a degeneracy that is ARITHMETIC")
    C = DL.ctx()
    seen = {}
    for a in sorted(C.imgs):
        seen.setdefault(tuple(C.imgs[a]), a)
    imgs = {a: list(k) for k, a in seen.items()}
    by, n, dram = collections.Counter(), 0, 0
    for ws in imgs.values():
        for w in ws:
            if DIS.lo_act(w) != 0x0B:
                continue
            n += 1
            port = DIS.class4(w) == 1 and DIS.addr8(w) in (0x20, 0x30, 0x60)
            dram += port
            by[(DIS.lo_src(w), port)] += 1
    print("  POPULATION (rule 9): %d ACTION 0x0B words over %d DISTINCT images"
          % (n, len(imgs)))
    print("     delay-DRAM PORT words (blocked by the PORT, not the ACTION): %d"
          % dram)
    print("     non-port                                                  : %d\n"
          % (n - dram))
    print("     SRC     port?   count")
    for (s, p), c in sorted(by.items(), key=lambda kv: -kv[1]):
        print("     0x%02X    %-5s   %4d%s"
              % (s, "PORT" if p else "-", c,
                 "   <-- SRC IS tempA" if s == DIS.LO_SRC_TA else ""))
    ta = sum(c for (s, _p), c in by.items() if s == DIS.LO_SRC_TA)
    tan = sum(c for (s, p), c in by.items() if s == DIS.LO_SRC_TA and not p)
    print("""
  ★★ A DECIDABILITY LEMMA, PROVEN BY CONSTRUCTION -- NOT MEASURED.
  %d of the %d sites (%d of them non-port) have SRC = 0x19 = tempA.  At
  every one of those, the reading "ACTION 0x0B captures the bus into
  tempA" writes tempA INTO ITSELF:

        bus    = s24(st.ta)
        st.ta  = bus & MASK24   ==   st.ta          <- identity

  so `tA<-bus' and `no side effect' are THE SAME MACHINE there.  No
  experiment at such a site can ever separate them, however long it runs.

  THE GENERAL FORM, worth carrying: A CAPTURE INTO THE REGISTER THE WORD
  IS ALREADY SOURCING IS INVISIBLE, EVERYWHERE.  That is the same shape as
  `action00-discriminator.md's census -- where `load' and `add' coincide
  at hi12[3:1] == 0 -- and it should be checked BEFORE any ACTION search,
  not after.""" % (ta, n, tan))
    return {"n": n, "dram": dram, "ta": ta}


def cmd_wdata():
    hdr("★ THE CONTROL THAT CANNOT FAIL -- and it is the harness DEFAULT")
    P, cf, x = setup()
    sp = space()
    print("""  The observable is the delay-port write stream.  Under the harness
  default `wdata = "bus"' a DRAM write stores the OPERAND BUS, which at
  these sites is the delay-read register -- an unmultiplied line copy.
  The ALU cannot reach it, so NOTHING about any ACTION is observable.
  `adjudication-round8.md' flagged exactly this; the default is still
  `bus', so an experiment that does not override it measures nothing.

  The control varies `act19', which is KNOWN to change the machine.
""")
    rows = []
    for wd in ("bus", "acc"):
        h = DL.Harness().replace(wdata=wd)
        ran = diff = cran = cdiff = 0
        for t in sp:
            o = {}
            for a in A0.ACT0B:
                r = run(P, cf, x, A0.Machine(t[0], t[1], t[2], t[3],
                                             act19=t[4], src00=t[5],
                                             act0b=a), h)
                if r is None:
                    o = None
                    break
                o[a] = r
            if o:
                ran += 1
                diff += len(set(o.values())) > 1
            c = {}
            for a19 in ACT19:
                r = run(P, cf, x, A0.Machine(t[0], t[1], t[2], t[3],
                                             act19=a19, src00=t[5],
                                             act0b="none"), h)
                if r is None:
                    c = None
                    break
                c[a19] = r
            if c:
                cran += 1
                cdiff += len(set(c.values())) > 1
        rows.append((wd, diff, ran, cdiff, cran))
        print("  wdata=%-4s  TARGET act0b seen by %3d/%3d   |  CONTROL act19 "
              "seen by %3d/%3d   %s"
              % (wd, diff, ran, cdiff, cran,
                 "<-- CONTROL IS BLIND, any result here is VOID"
                 if cdiff == 0 else "(control OK)"))
    print("""
  ★ So the reverb CAN see ACTION 0x0B -- but only in the regime where the
  ALU reaches the delay line at all.  My own first run of this experiment
  used the default and returned a clean-looking 0 of 200, which the
  control then voided.  Printed rather than deleted: it is the eleventh
  such catch on this chip and the second in two passes.""")
    return rows


def cmd_partition():
    hdr("HOW THE SIX READINGS SEPARATE (wdata = acc)")
    P, cf, x = setup()
    h = DL.Harness().replace(wdata="acc")
    same, ran = collections.Counter(), 0
    part = collections.Counter()
    for t in space():
        o = {}
        for a in A0.ACT0B:
            r = run(P, cf, x, A0.Machine(t[0], t[1], t[2], t[3], act19=t[4],
                                         src00=t[5], act0b=a), h)
            if r is None:
                o = None
                break
            o[a] = r
        if not o:
            continue
        ran += 1
        g = collections.defaultdict(list)
        for k, v in o.items():
            g[v].append(k)
        part[tuple(sorted(tuple(sorted(q)) for q in g.values()))] += 1
        for a, b in itertools.combinations(A0.ACT0B, 2):
            if o[a] == o[b]:
                same[(a, b)] += 1
    print("  machines run: %d\n" % ran)
    print("  pairs INDISTINGUISHABLE in every machine:")
    for (a, b), c in sorted(same.items(), key=lambda kv: -kv[1]):
        if c == ran:
            print("     %-9s == %-9s  %d/%d" % (a, b, c, ran))
    print("\n  pairs that DO separate:")
    for (a, b), c in sorted(same.items(), key=lambda kv: -kv[1]):
        if c < ran:
            print("     %-9s vs %-9s  differ in %3d/%3d" % (a, b, ran - c, ran))
    print("\n  partitions observed:")
    for p, c in part.most_common(6):
        print("     %3dx  %s"
              % (c, " | ".join("{" + ",".join(q) + "}" for q in p)))
    print("""
  ★ THE SIX COLLAPSE TO THREE.  {none, tA<-bus, tB<-bus, tB<-acc} are
  indistinguishable in every machine; only `mem<-bus' and `tA<-acc'
  separate from them and from each other.  One of those four collapses is
  ARITHMETIC (see `census': SRC is tempA here, so tA<-bus is the identity)
  and the other two are measured.

  So the live question is THREE-WAY -- none / mem<-bus / tA<-acc -- and
  the shipped silent `none' is safe against three of its five rivals at
  these sites.  Picking the winner needs known mathematics, which the
  reverb does not yet supply: the diffuser gains are known but there is no
  reference response to match.  NOT APPLIED.""")
    return {"ran": ran}


W_0B = 0x002A24B00B     # algos 98/99 w001 -- ACTION 0x0B
W_00 = 0x002A24B000     # algo  96   w001 -- ACTION 0x00, identical otherwise


def cmd_pair():
    hdr("★ THE MINIMAL PAIR CANNOT BE EXECUTED -- and not because of the ACTION")
    print("""  `target4.py act0b' offers the pair below as "a bounded, well-posed
  next experiment": two words identical in hi12, class4, addr8 and SRC,
  differing in the ACTION field alone, each sitting immediately before a
  BYTE-IDENTICAL copy of PARAMETRIC EQ's solved biquad.  Structurally it is
  everything one could ask for.  It still cannot decide anything:
""")
    for w, nm in ((W_0B, "algos 98/99 w001"), (W_00, "algo 96 w001")):
        hi = DIS.hi12(w)
        print("     %010X  %-18s hi12=%03X  class4=%d  addr8=%02X  SRC=%02X  "
              "ACT=%02X   hi12[3:1]=%d %s"
              % (w, nm, hi, DIS.class4(w), DIS.addr8(w), DIS.lo_src(w),
                 DIS.lo_act(w), DIS.hi_f31(hi),
                 "<-- REFUSED" if DIS.hi_f31(hi) > 2 else ""))
    print("""
  ★ BOTH members carry hi12[3:1] = 5, and `step()' refuses every word with
  hi12[3:1] > 2 -- the accumulator-operation field is decoded for values
  0, 1 and 2 and undecoded for 3..7.  So the twins trap for a reason that
  has NOTHING TO DO with the ACTION field being compared, and prepending
  either to the biquad returns TRAPPED rather than a decibel figure.

  ★★ THIS INVERTS `target4.py act0b's OWN CONCLUSION.  That section ends
  "The reverb, which owns 9 of the 35 non-DRAM sites, is NOT where it will
  be settled."  The reverb sites carry hi12[3:1] = 1 and DO execute; the
  composite sites carry 5 and do not.  The reverb is the only place ACTION
  0x0B can currently be examined at all.""")
    C = DL.ctx()
    seen = {}
    for a in sorted(C.imgs):
        seen.setdefault(tuple(C.imgs[a]), a)
    imgs = [list(k) for k in seen]
    n = ref = anch = 0
    c = collections.Counter()
    for ws in imgs:
        for w in ws:
            n += 1
            f = DIS.hi_f31(DIS.hi12(w))
            c[f] += 1
            if f > 2:
                ref += 1
                if DIS.lo_act(w) in DIS._ANCHORED_ACT and \
                        DIS.lo_src(w) in DIS._ANCHORED_SRC:
                    anch += 1
    print("\n  THE FIELD, SIZED (population %d words / %d DISTINCT images):" % (n, len(imgs)))
    for f in range(8):
        print("     hi12[3:1] = %d : %5d  %5.1f%%   %s"
              % (f, c[f], 100.0 * c[f] / n,
                 "modelled" if f <= 2 else "UNDECODED"))
    print("""
  ★ %d of %d words (%.1f%%) are refused on hi12[3:1] > 2, and %d of those
  have BOTH their SRC and their ACTION anchored -- they trap for this
  reason ALONE.  Five undecoded values (3..7) of a field that is otherwise
  the accumulator's whole operation select.""" % (ref, n, 100.0 * ref / n, anch))
    return {"refused": ref, "anchored": anch}


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "all"
    if cmd in ("all", "census"):
        cmd_census()
    if cmd in ("all", "wdata"):
        cmd_wdata()
    if cmd in ("all", "partition"):
        cmd_partition()
    if cmd in ("all", "pair"):
        cmd_pair()


if __name__ == "__main__":
    main()
