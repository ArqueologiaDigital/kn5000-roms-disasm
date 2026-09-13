#!/usr/bin/env python3
"""detector_idiom.py -- the 2/pi LEVEL-DETECTOR idiom, and what heads it.

QUESTION IT ANSWERS
    N-INPUT-GATE-OPENED §66 measured a very strong PROGRAM-level association between `hi12' bit 5
    and the decoded dynamics families (the eight pure delay/modulation networks carry ZERO bit-5
    words where uniformity predicts 33), and then REFUTED the obvious site-level mechanism: bit-5
    words sit two to three times FURTHER from the control bus (`SRC 0x1C') than an average word.
    That left the association unexplained at site level.

    `SPECULATIVE-APPLIED-REGISTER.md' §3 already had the answer.  `0x517CC1' = floor(2/pi x 2^23)
    EXACTLY -- and 2/pi is the mean of a RECTIFIED sine, i.e. `programs.tsv`'s "2/pi env" level
    detector, named in the ROM's own role table.  It sits in a byte-identical idiom:

        <head>                 <- the word under test
        018.A.00.1D5           C-RAM = 0x517CC1 = 2/pi
        104.A.00.1D5           C-RAM = 0x400000 = 0.5, pointer FROZEN
        C40.2.C0.000           C-format immediate
        182.A.00.000           one-pole smoothers, 4.712 ms and 11.764 ms

    This finds every occurrence of the idiom's unambiguous two-word core and reports the word
    immediately before it.  If the head is a bit-5 word, the program-level association has a
    site-level mechanism: the bit-5 word is part of the detector itself.

USAGE
    python3 dsp/tools/detector_idiom.py [dsp/disasm/*.dsm]

⚠ What it CANNOT show: what the head word DOES.  That the detector needs a rectifier, and that the
  head is the only slot in the idiom not already accounted for by a named coefficient, is an
  INFERENCE -- a strong one, and not a measurement.  Rival: the rectification could live in the
  source encoding, or upstream of the idiom entirely.
"""
import collections
import glob
import os
import re
import sys

ROW = re.compile(r"^\s+w(\d+)\s+([0-9A-F]{10})\s")
CORE = (0x0018A001D5, 0x0104A001D5)          # 2/pi, then 0.5 with the pointer frozen


def hi12(w):
    return (w >> 24) & 0xfff


def main():
    files = sys.argv[1:] or sorted(glob.glob(os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "disasm", "*.dsm")))
    prog = {}
    for f in files:
        v = [(int(m.group(1)), int(m.group(2), 16))
             for ln in open(f, errors="replace") if (m := ROW.match(ln))]
        if v:
            prog[os.path.basename(f)[:-4]] = v

    sites = []
    for p, v in prog.items():
        for k in range(len(v) - 1):
            if v[k][1] == CORE[0] and v[k + 1][1] == CORE[1]:
                sites.append((p, v[k][0], v[k - 1][1] if k else None,
                              [v[k + j][1] for j in range(4) if k + j < len(v)]))

    b5 = sum(1 for _, _, pre, _ in sites if pre is not None and hi12(pre) & 0x20)
    withpre = sum(1 for _, _, pre, _ in sites if pre is not None)
    print("=== 2/pi LEVEL-DETECTOR IDIOM: %d sites in %d of %d images ==="
          % (len(sites), len({p for p, _, _, _ in sites}), len(prog)))
    print("  ★ the word BEFORE the idiom has hi12 bit 5 : %d of %d" % (b5, withpre))
    print("    its f31 codes                            : %s"
          % dict(collections.Counter((hi12(pre) >> 1) & 7
                                     for _, _, pre, _ in sites if pre is not None)))
    for p, i, pre, seq in sorted(sites):
        print("   %-26s w%-3d  head=%s bit5=%-5s f31=%s | %s"
              % (p, i, "%010X" % pre if pre is not None else "(none)",
                 bool(hi12(pre) & 0x20) if pre is not None else "-",
                 (hi12(pre) >> 1) & 7 if pre is not None else "-",
                 " ".join("%010X" % w for w in seq)))
    tot = sum(1 for v in prog.values() for _, w in v if hi12(w) & 0x20)
    print("\n⇒ idiom heads are %d of the corpus's %d bit-5 words (%.0f%%) -- a FOOTHOLD, not the"
          " whole population." % (b5, tot, 100.0 * b5 / tot))
    return 0


if __name__ == "__main__":
    sys.exit(main())
