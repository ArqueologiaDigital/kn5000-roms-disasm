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


def main():
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
