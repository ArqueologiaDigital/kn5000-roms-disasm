#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_template_clusters.py -- how many DISTINCT program templates do the 86 named effects
reduce to?  (Generalises the reverb result to the whole catalogue.)

DECODE-by-correlation sect. 2 showed the WSA1R's 13 reverb NAMES are only 4 distinct
programs + coefficient presets. This asks the same of ALL 86 effect programs of both
products: cluster them by structural fingerprint and count the templates an emulator must
actually implement. Two groupings:

  * EXACT template  -- identical idiom SEQUENCE (same instructions, same order). These are
    the same algorithm to the word; any difference is streamed C-RAM (coefficients/taps).
  * NEAR family     -- idiom-sequence LCS ratio >= 0.85 (longest common subsequence / longer
    length). Same algorithm, minor edits (a band added, a tap moved, a curve changed).

idiom key:  M coeff-MAC  z biquad z^-1/z^-2  C C-format value-load  R/W delay-DRAM read/write
            a route  s store  l load  t table  b biquad-latch(ld.ta/mac.tb)  . other

    python3 dsp/tools/dsp_template_clusters.py

MEASURED 2026-09-08 (both products' committed .dsm):
  86 named programs -> 78 EXACT idiom-sequence templates (only the reverb 1/2 variants and
  DISTORTION==FUZZ are word-identical) -> ~52 NEAR families at LCS>=0.85. The families expose
  cross-NAME algorithmic identities the names hide:
    EXCITER == OVERDRIVE       (waveshaper + post tone biquad; differ in curve+tuning)
    AUTO WAH == PEDAL WAH      (a swept filter; auto=LFO-swept vs pedal=manual, same DSP)
    MANUAL DELAY == SINGLE DELAY;  SLOW ATTACKER == NO OPERATION (a stub, confirmed)
    FLANGER ~ VIBRATO          (in the S.DELAY+ / PEQ+ combos: LFO-swept delay)
  and every KN5000<->WSA1R same-name pair clusters (cross-product structural validation).

Reads the committed .dsm of both products (effect bodies only). stdlib + dsp_disasm; read-only.
"""
import collections
import glob
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                              # noqa: E402

WORD = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\b")
NAMELINE = re.compile(r"program -- (.+?)\s*$")
TREES = [(os.path.join(HERE, "..", "disasm"), "KN5000"),
         (os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm"), "WSA1R")]


def idi(w):
    if D.c_format(w):
        return "C"
    if D.lo_act(w) in (0x0D, 0x0E):
        return "z"
    if D.lo_act(w) in (0x13, 0x14):
        return "b"                                  # DF-I biquad state latch
    c = D.class4(w)
    if c == 1 and (D.hi12(w) & 0x800):
        return "W" if (D.addr8(w) & 0x40) else "R"
    if c & 8:
        return "M"
    if c == 2 and (D.lo12(w) & 0x10):
        return "s"
    if c == 2:
        return "a"
    if c == 0:
        return "l"
    if c == 6:
        return "t"
    return "."


def load_bodies():
    progs = []
    for tree, prod in TREES:
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
                progs.append((prod, nm, "".join(idi(w) for w in ws)))
    return progs


def lcs_ratio(a, b):
    """longest common subsequence length / longer length -- similarity of two idiom seqs."""
    la, lb = len(a), len(b)
    if not la or not lb:
        return 0.0
    prev = [0] * (lb + 1)
    for i in range(1, la + 1):
        cur = [0] * (lb + 1)
        ai = a[i - 1]
        for j in range(1, lb + 1):
            cur[j] = prev[j - 1] + 1 if ai == b[j - 1] else max(prev[j], cur[j - 1])
        prev = cur
    return prev[lb] / max(la, lb)


def main():
    progs = load_bodies()
    print("%d effect-body programs (KN5000 + WSA1R)\n" % len(progs))

    # 1. EXACT idiom-sequence templates
    exact = collections.defaultdict(list)
    for prod, nm, seq in progs:
        exact[seq].append("%s:%s" % (prod, nm))
    print("=== EXACT structural templates (identical idiom sequence): %d ===" % len(exact))
    for seq, members in sorted(exact.items(), key=lambda kv: -len(kv[1])):
        if len(members) > 1:
            print("  [%2d progs, %d words] %s" % (len(members), len(seq), ", ".join(members)))
    singles = sum(1 for m in exact.values() if len(m) == 1)
    print("  (+ %d singleton templates)" % singles)

    # 2. NEAR families by idiom-sequence LCS ratio >= 0.85 (union-find)
    TH = 0.85
    seqs = [s for _, _, s in progs]
    parent = list(range(len(progs)))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for i in range(len(progs)):
        for j in range(i + 1, len(progs)):
            if lcs_ratio(seqs[i], seqs[j]) >= TH:
                parent[find(i)] = find(j)
    fam = collections.defaultdict(list)
    for i, (prod, nm, _) in enumerate(progs):
        fam[find(i)].append("%s:%s" % (prod, nm))
    fams = sorted(fam.values(), key=lambda m: -len(m))
    print("\n=== NEAR families (idiom-sequence LCS >= %.2f): %d ===" % (TH, len(fams)))
    for members in fams:
        if len(members) > 1:
            print("  [%2d] %s" % (len(members), ", ".join(sorted(members))))
    fsing = sum(1 for m in fams if len(m) == 1)
    print("  (+ %d singleton families)" % fsing)

    print("\nSUMMARY: %d named programs -> %d exact templates -> %d near-families."
          % (len(progs), len(exact), len(fams)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
