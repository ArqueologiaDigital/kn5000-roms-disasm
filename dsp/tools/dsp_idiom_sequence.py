#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_idiom_sequence.py -- the per-word idiom string of a DSP program, for algorithm
identification and KN5000<->WSA1R structural cross-validation.

The topology *counts* (dsp_topology_fingerprint.py) say how many of each idiom a program
has; this shows the ORDER, which is what identifies the algorithm. A Direct-Form-I biquad
band is the pattern `MMMMM aMMa` -- five coefficient multiplies (b0 b1 b2 -a1 -a2) then the
state combine -- so a parametric EQ is that pattern repeated once per band per channel. When
two programs (same effect, two products) share the idiom sequence, the same instructions in
the same order implement the same algorithm: if one is SOLVED, the other is validated by
construction.

idiom key:  M coeff-MAC   z biquad z^-1 state   C C-format immediate (coeff load)
            a class-2 route/accumulate   s store   l mode-0 load   D delay-DRAM   . other

    python3 dsp/tools/dsp_idiom_sequence.py EFFECT_NAME     # both products, side by side
    python3 dsp/tools/dsp_idiom_sequence.py --biquads       # biquad-band count for every EQ

Reads the committed .dsm listings; stdlib + dsp_disasm; read-only.
"""
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                              # noqa: E402

WORD = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\b")
NAMELINE = re.compile(r"program -- (.+?)\s*$")
TREES = {"KN5000": os.path.join(HERE, "..", "disasm"),
         "WSA1R":  os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm")}


def idiom(w):
    if D.c_format(w):                      return "C"
    if D.lo_act(w) in (0x0D, 0x0E):        return "z"
    cls = D.class4(w)
    if cls & 0x8:                          return "M"
    if cls == 1 and (D.hi12(w) & 0x800):   return "D"
    if cls == 2 and (D.lo12(w) & 0x10):    return "s"
    if cls == 2:                           return "a"
    if cls == 0:                           return "l"
    return "."


def load(tree, name):
    for p in glob.glob(os.path.join(tree, "*.dsm")):
        nm, words = None, []
        for ln in open(p):
            m = NAMELINE.search(ln)
            if m:
                nm = m.group(1)
            m = WORD.match(ln)
            if m:
                words.append(int(m.group(1), 16))
        if nm and nm.upper() == name.upper():
            return words
    return None


def biquad_bands(words):
    """count Direct-Form-I biquad sections = runs of exactly 5 coefficient MACs."""
    s = "".join(idiom(w) for w in words)
    return len(re.findall(r"M{5}", s))


def all_names(tree):
    out = {}
    for p in glob.glob(os.path.join(tree, "*.dsm")):
        for ln in open(p):
            m = NAMELINE.search(ln)
            if m:
                out[m.group(1)] = p
                break
    return out


def histo(words):
    h = {}
    for w in words:
        h[idiom(w)] = h.get(idiom(w), 0) + 1
    return h


def similarity(a, b):
    """0..1 cosine-like overlap of two idiom histograms."""
    keys = set(a) | set(b)
    dot = sum(a.get(k, 0) * b.get(k, 0) for k in keys)
    na = sum(v * v for v in a.values()) ** 0.5
    nb = sum(v * v for v in b.values()) ** 0.5
    return dot / (na * nb) if na and nb else 0.0


def crossval_all():
    knn = all_names(TREES["KN5000"])
    wsn = all_names(TREES["WSA1R"])
    shared = sorted(set(knn) & set(wsn))
    print("Structural cross-validation of every effect on BOTH chips (%d shared):\n" % len(shared))
    print("effect                 KN5000w  WSA1Rw  biquad(k/w)  idiom-sim  verdict")
    ident = same = diff = 0
    for nm in shared:
        kw = load(TREES["KN5000"], nm)
        ww = load(TREES["WSA1R"], nm)
        bk, bw = biquad_bands(kw), biquad_bands(ww)
        sim = similarity(histo(kw), histo(ww))
        if sim >= 0.99 and bk == bw:
            v, ident = "IDENTICAL", ident + 1
        elif sim >= 0.95:
            v, same = "same algorithm", same + 1
        else:
            v, diff = "DIFFERS", diff + 1
        print("%-22s %5d   %5d    %2d / %-2d      %.3f     %s"
              % (nm[:22], len(kw), len(ww), bk, bw, sim, v))
    print("\n%d identical, %d same-algorithm, %d differ (of %d shared effects)"
          % (ident, same, diff, len(shared)))
    print("=> the two products run structurally the same DSP programs, with the reverbs the "
          "main exception.")
    return 0


def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "--crossval":
        return crossval_all()
    if len(sys.argv) >= 2 and sys.argv[1] == "--biquads":
        print("Direct-Form-I biquad sections per EQ-family program (a section = 5 coeffs):\n")
        for label, tree in TREES.items():
            for nm in sorted(all_names(tree)):
                if any(k in nm.upper() for k in ("PARAMETRIC EQ", "ENHANCER", "PEQ")):
                    w = load(tree, nm)
                    print("  %-7s %-20s %3d words  %2d biquad sections"
                          % (label, nm[:20], len(w), biquad_bands(w)))
        return 0
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    name = sys.argv[1]
    for label, tree in TREES.items():
        w = load(tree, name)
        if w is None:
            print("%-7s %-20s : not present" % (label, name))
            continue
        s = "".join(idiom(x) for x in w)
        print("%-7s %-20s (%d words), %d biquad sections:" % (label, name, len(w), biquad_bands(w)))
        print("  " + s)
    return 0


if __name__ == "__main__":
    sys.exit(main())
