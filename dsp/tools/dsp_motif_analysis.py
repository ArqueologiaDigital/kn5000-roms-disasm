#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_motif_analysis.py -- find the recurring instruction MOTIFS (the algorithm building
blocks) across the uPD6383GF effect programs, and read the OPEN words' roles from them.

DSP effects are built from a few primitives -- a coefficient run (biquad), a delay stage
(comb / all-pass), a two-state filter update. Those primitives show up as recurring idiom
n-grams. Mining them (a) names the building blocks and (b) pins the OPEN words by their
position inside a recognised primitive.

idiom key:  M coeff-MAC   z biquad state   C C-format load   R/W delay-DRAM read/write
            a route   s store   l load   t table   . other

    python3 dsp/tools/dsp_motif_analysis.py

MEASURED 2026-09-08 (both products' committed .dsm):
  * MMM/MMMM (302/164): coefficient runs -- biquad / filter sections.
  * zz (the biquad z^-1/z^-2 pair): 155 `zza`, always adjacent (see dsp_context_analysis).
  * WC / WCWC (124-127): a delay-tap WRITE immediately followed by a C-format load of 480
    to register lo12=0x000 -- in ALL 11 reverbs. So the reverb is a uniform comb: write a
    tap, (re)load the delay parameter (0x000 = a stride/length, constant 480), write the
    next. Confirms 0x000 is a delay-memory parameter (dsp_cformat_analysis).
  * delay STAGES (R..W spans): RMaaW (comb), RMMzzW (comb with a biquad damping filter in
    the feedback -- the reverb tank), RMsMW, etc.

Graded structural evidence, not proof. stdlib + dsp_disasm; read-only.
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


def load_all():
    progs = {}
    for tree in TREES:
        for p in glob.glob(os.path.join(tree, "*.dsm")):
            if os.path.basename(p) == "index.dsm":
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
                progs[nm] = ws
    return progs


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
    if c == 0:
        return "l"
    if c == 6:
        return "t"
    return "."


def main():
    progs = load_all()
    seqs = {nm: [idi(w) for w in ws] for nm, ws in progs.items()}

    for N in (3, 4):
        ng = collections.Counter()
        for s in seqs.values():
            for i in range(len(s) - N + 1):
                ng["".join(s[i:i + N])] += 1
        print("=== top idiom %d-grams (building blocks) ===" % N)
        for motif, c in ng.most_common(10):
            print("  %-6s %4d" % (motif, c))
        print()

    print("=== delay STAGES: R..W spans (comb / all-pass; a biquad 'zz' inside = damping) ===")
    spans = collections.Counter()
    for s in seqs.values():
        i = 0
        while i < len(s):
            if s[i] == "R":
                j = i + 1
                while j < len(s) and s[j] not in ("W", "R"):
                    j += 1
                if j < len(s) and s[j] == "W":
                    spans["".join(s[i:j + 1])] += 1
                i = j
            else:
                i += 1
    for span, c in spans.most_common(10):
        note = "  (comb + biquad damping)" if "zz" in span else ""
        print("  %-16s %4d%s" % (span, c, note))

    print("\n=== the reverb comb-write motif: which register a tap-WRITE reloads ===")
    dest = collections.Counter()
    val = collections.Counter()
    effs = set()
    for nm, ws in progs.items():
        s = seqs[nm]
        for i in range(len(s) - 1):
            if s[i] == "W" and s[i + 1] == "C":
                dest[D.lo12(ws[i + 1])] += 1
                im = D.c_imm13(ws[i + 1])
                val[im - 0x2000 if im & 0x1000 else im] += 1
                effs.add(nm)
    print("  a delay WRITE is followed by a C-format load to: %s"
          % dict(("0x%03X" % k, v) for k, v in dest.most_common(3)))
    print("  loaded value(s): %s   in %d programs (%s...)"
          % (dict(val.most_common(3)), len(effs), ", ".join(sorted(effs)[:4])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
