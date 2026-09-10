#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""ceiling_partition.py -- partition the whole uPD6383GF corpus into STRICT-decodable /
SPECULATIVELY-decodable / genuinely-DARK, and for every dark word say WHY.

This retires the unanchored "~93.3% ceiling" folklore with a number derived from the current
tools: it reuses the SAME predicates spec_coverage.py does (dsp_disasm.alu_decoded strict /
alu_decoded_spec speculative, the mirror of upd6383d.cpp) and, for each remaining word, names the
reason it is not (yet) decoded -- so the ceiling is a sum of accounted-for buckets, not a guess.

Reason buckets for dark words:
  * MN19413 (not this chip) -- the DSP2-misparsed streams {79,88,89,90,91} target IC310, so any
    statistic that mixes them is mixing two chips (dsp2-mn19413.md).
  * C-format immediate -- in the hi12[11:8]==0xC family lo12 is an immediate, not a routing field
    (upd6383d.h:49), so there is no SRC/ACT to decode; these are DATA, not open ISA.
  * open field: SRC 0xNN / ACT 0xNN / f31=N / class N -- a genuinely still-open ISA field, the
    real decode frontier (the same UNK_* sets coverage_report.py uses).

    python3 dsp/tools/ceiling_partition.py
"""
import collections
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pat_corpus import load                                          # noqa: E402
import dsp_disasm as D                                               # noqa: E402

DSP2_MISPARSED = {79, 88, 89, 90, 91}   # target the MN19413 (IC310), not this chip

# the still-open ISA fields (mirror of coverage_report.py's UNK_* sets)
UNK_ACT = {0x0b, 0x0c, 0x0d, 0x0e, 0x1c}
UNK_SRC = {0x00, 0x02, 0x03, 0x04, 0x05, 0x06, 0x0a, 0x13, 0x1b, 0x1d}
UNK_CLASS = {0, 4, 5, 6}


def fields(w):
    return (w >> 24) & 0xFFF, (w >> 20) & 0xF, (w >> 12) & 0xFF, w & 0xFFF


def dark_reason(w):
    """Why is this (non-strict, non-spec) word dark?  Returns a short bucket label."""
    hi, c, a, lo = fields(w)
    if D.c_format(w):
        return "C-format immediate (no routing field)"
    f31 = (hi >> 1) & 7
    src, act = (lo >> 6) & 0x1F, lo & 0x1F
    if f31 > 2:
        return "open f31=%d" % f31
    if act in UNK_ACT:
        return "open ACT 0x%02X" % act
    if src in UNK_SRC:
        return "open SRC 0x%02X" % src
    if c in UNK_CLASS:
        return "open class %d" % c
    return "other (no named open field -- inspect)"


def main():
    progs, _ = load()
    tot = strict = spec = 0
    dark = collections.Counter()
    mn19413 = 0
    for pid, ws in progs.items():
        is_dsp2 = pid in DSP2_MISPARSED
        for w in ws:
            tot += 1
            if is_dsp2:
                mn19413 += 1                       # count separately: not this chip at all
                continue
            if D.alu_decoded(w):
                strict += 1
            elif D.alu_decoded_spec(w):
                spec += 1
            else:
                dark[dark_reason(w)] += 1

    on_chip = tot - mn19413
    dark_tot = sum(dark.values())
    pc = lambda n, d: (100.0 * n / d) if d else 0.0
    print("uPD6383GF corpus ceiling partition (%d words total)\n" % tot)
    print("  MN19413 (IC310, NOT this chip -- excluded)      %5d  (%.1f%% of corpus)"
          % (mn19413, pc(mn19413, tot)))
    print("  --- of the %d ON-CHIP words: ---" % on_chip)
    print("  STRICT-decodable (rigorous, alu_decoded)        %5d  (%.1f%%)" % (strict, pc(strict, on_chip)))
    print("  +SPECULATIVE reading (alu_decoded_spec only)    %5d  (%.1f%%)" % (spec, pc(spec, on_chip)))
    print("  = has some decode                               %5d  (%.1f%%)"
          % (strict + spec, pc(strict + spec, on_chip)))
    print("  DARK (no decode)                                %5d  (%.1f%%)" % (dark_tot, pc(dark_tot, on_chip)))
    print("\n  dark words by reason:")
    cfmt = sum(n for r, n in dark.items() if r.startswith("C-format"))
    openf = dark_tot - cfmt
    for r, n in dark.most_common():
        print("    %-42s %5d" % (r, n))
    print("\n  ⇒ THE HONEST CEILING (on-chip words):")
    print("     C-format immediates are DATA, not open ISA (%d words) -- not decodable as opcodes."
          % cfmt)
    print("     Genuinely-open ISA frontier = %d words (%.1f%% of on-chip)." % (openf, pc(openf, on_chip)))
    reachable = strict + spec + cfmt
    print("     Accounted-for ceiling (strict + spec + C-format-as-data) = %d / %d = %.1f%%."
          % (reachable, on_chip, pc(reachable, on_chip)))
    print("     Remaining truly-open = %.1f%% -- the decode frontier, itemised above (not a folklore number)."
          % pc(openf, on_chip))
    return 0


if __name__ == "__main__":
    sys.exit(main())
