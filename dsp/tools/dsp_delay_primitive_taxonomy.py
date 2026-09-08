#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_delay_primitive_taxonomy.py -- classify every program's delay stages (R..W spans)
into the textbook DSP building blocks, and correlate with the effect name.

A delay stage is the span from an external-DRAM READ to the next WRITE.  What sits between
them says which primitive it is:

  all-pass (1st order)  : exactly 1 multiply, >=2 route ops, no biquad state (RMaaW, RaMaaW)
                          -- one coefficient used +g/-g = a first-order all-pass diffuser.
  comb + damping        : >=2 multiplies AND a biquad z-pair (RMMzzW ...) -- feedback gain
                          plus a one-pole damper in the loop = a lossy comb / FDN stage.
  tapped / FIR          : >=3 multiplies, no z-pair (RMMMW, RMMMaMMaW) -- several coefficient
                          taps read from one delay line = a multi-tap / FIR-in-delay.
  plain comb / gain     : 1-2 multiplies, no z-pair, <2 routes (RMW, RMsMW) -- a gain in a
                          feedback/feedforward delay.
  damped / one-pole     : a z-pair with <=1 multiply (RzzaW, RasMzzW) -- state-dominated.
  complex               : long mixed spans that are not one clean primitive.

A delay stage is SHORT (read, a few ops, write).  A long R..W span is not a delay stage --
it is the whole algorithm bracketed by an input read and an output write (an EQ reads the
input, runs its entire biquad chain, writes the output = one long span).  So the classifier
below counts only SHORT spans (<=10 ops); the span LENGTH profile is reported separately and
is itself a discriminator: a delay network is many short stages, a signal chain is one long
span.

    python3 dsp/tools/dsp_delay_primitive_taxonomy.py

MEASURED 2026-09-08 (both products' effect .dsm).  Extends sect. 4/5 (reverb-only) to the
whole catalogue:
  * span-length profile -- reverb: mean 7.8 ops, 63 short / 5 long (a TANK of stages);
    eq: mean 27.4, and dyn/dist: mean 32.2 with 0 short spans (ONE long span = no delay line).
  * short-span primitives -- reverb = all-pass + comb+damp + tapped (its tank); delay = combs
    + taps + damped; modulation = a few short stages (one swept delay per voice); eq/dist have
    essentially none (their work is the long span, not a delay stage).
Graded structural correlation; stdlib + dsp_disasm; read-only.
"""
import collections
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                              # noqa: E402

WORD = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\b")
NAMELINE = re.compile(r"program -- (.+?)\s*$")
TREES = [os.path.join(HERE, "..", "disasm"),
         os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm")]


def idi(w):
    if D.c_format(w):
        return "C"
    if D.lo_act(w) in (0x0D, 0x0E):
        return "z"
    c = D.class4(w)
    if c == 1 and (D.hi12(w) & 0x800):
        return "W" if (D.addr8(w) & 0x40) else "R"
    if c & 8:
        return "M"
    if c == 2 and (D.lo12(w) & 0x10):
        return "s"
    if c == 2:
        return "a"
    if c == 6:
        return "t"
    return "."


def family(n):
    n = n.upper()
    if "EQ" in n:                                              return "eq"
    if any(k in n for k in ("REVERB", "HAAS", "GATED")):      return "reverb"
    if "DELAY" in n:                                          return "delay"
    if any(k in n for k in ("CHORUS", "FLANGER", "PHASER", "VIBRATO",
                            "ENSEMBLE", "PAN", "RING", "ROTARY", "MIX")): return "modulation"
    if any(k in n for k in ("DIST", "FUZZ", "OVERDR", "EXCITER",
                            "WAH", "COMPRESS")):                return "dyn/dist"
    if "PITCH" in n:                                          return "pitch"
    return "other"


def classify(span):
    M = span.count("M"); z = span.count("z"); a = span.count("a")
    zp = z // 2                                     # biquad z-pairs
    if M == 1 and a >= 2 and zp == 0:
        return "all-pass"
    if M >= 2 and zp >= 1:
        return "comb+damp"
    if M >= 3 and zp == 0:
        return "tapped/FIR"
    if zp >= 1 and M <= 1:
        return "damped/1-pole"
    if 1 <= M <= 2 and zp == 0 and a < 2:
        return "plain-comb/gain"
    return "complex"


def spans_of(seq):
    out = []
    i = 0
    while i < len(seq):
        if seq[i] == "R":
            j = i + 1
            while j < len(seq) and seq[j] not in ("W", "R"):
                j += 1
            if j < len(seq) and seq[j] == "W":
                out.append(seq[i:j + 1])
            i = j
        else:
            i += 1
    return out


def load():
    progs = []
    for tree in TREES:
        for p in sorted(glob.glob(os.path.join(tree, "*.dsm"))):
            b = os.path.basename(p)
            if not b.startswith(("prog", "eff")):
                continue
            nm, ws = None, []
            for ln in open(p):
                m = NAMELINE.search(ln)
                if m:
                    nm = m.group(1)
                m = WORD.match(ln)
                if m:
                    ws.append(int(m.group(1), 16))
            if nm and ws:
                progs.append((family(nm), nm, "".join(idi(w) for w in ws)))
    return progs


SHORT = 10   # a real delay stage is at most this many ops; longer = whole-algorithm span


def main():
    progs = load()

    # 1. span-LENGTH profile -- many-short (delay network) vs one-long (signal chain)
    import statistics
    lenf = collections.defaultdict(list)
    for f, nm, seq in progs:
        lenf[f].extend(len(s) for s in spans_of(seq))
    print("R..W span-length profile (a delay network is many SHORT stages;")
    print("a signal chain brackets its whole algorithm in one LONG span)\n")
    print("family       spans  mean-len  short(<=%d)  long(>%d)" % (SHORT, SHORT))
    for f in ("reverb", "delay", "modulation", "eq", "dyn/dist", "pitch", "other"):
        L = lenf[f]
        if not L:
            continue
        s = sum(1 for x in L if x <= SHORT)
        print("%-11s  %5d   %6.1f     %5d       %5d" % (f, len(L), statistics.mean(L), s, len(L) - s))

    # 2. primitives on SHORT spans only (real delay stages)
    fam_prim = collections.defaultdict(collections.Counter)
    for f, nm, seq in progs:
        for sp in spans_of(seq):
            if len(sp) <= SHORT:
                fam_prim[f][classify(sp)] += 1
    prims = ["all-pass", "comb+damp", "tapped/FIR", "plain-comb/gain", "damped/1-pole", "complex"]
    print("\nprimitives on SHORT (<=%d) spans = real delay stages\n" % SHORT)
    print("family       " + " ".join("%-10s" % p[:10] for p in prims))
    for f in ("reverb", "delay", "modulation", "eq", "dyn/dist", "pitch", "other"):
        c = fam_prim[f]
        if not sum(c.values()):
            print("%-11s  (none)" % f)
            continue
        print("%-11s  " % f + " ".join("%-10d" % c.get(p, 0) for p in prims))

    print("\nreading (matches the textbook algorithm each name promises):")
    print("  reverb -> a TANK of short stages: all-pass ladders (KN5000) + comb+damp (WSA1R)")
    print("  delay  -> combs + taps + damped feedback stages")
    print("  modulation -> a few short stages (one swept delay per voice), not a tank")
    print("  eq / dist -> ~no delay stages; their work is ONE long input->output span")
    return 0


if __name__ == "__main__":
    sys.exit(main())
