#!/usr/bin/env python3
"""Where could a COND field hide?  -- the DARK-CODEPOINT census.

QUESTION THIS ANSWERS
  The CDJ-500 pin table says every uPD6383GF instruction has a COND field that
  tests RQ1-RQ3.  No shipped effect program branches, so if COND=0 means
  "unconditional", the field must read ZERO in essentially every corpus word.
  This script ranks the places it can be hiding, by measuring, over the whole
  disassembly tree:

    (a) per-bit "ones" counts  -- a bit that is never set is a dark BIT;
    (b) the hi12[7:5] and hi12[6:5] value histograms -- a value that never
        occurs is a dark CODEPOINT even when each of its bits is used;
    (c) the class4 histogram over non-C-format words -- same, for addressing
        classes.

  A dark CODEPOINT is the target: the corpus exercises every one of the 36
  bits, so "find an unused bit" is already known to fail (measured below).

MEASURED 2026-09-14, BOTH TREES (KN5000 3057 words / 2989 non-C-format;
WSA1R 4946 / 4569):
  * no bit of the 36 is unused in either corpus -- "find an unused bit" is
    already dead, which is why the target must be a dark CODEPOINT;
  * hi12[7:5] values 6 and 7 are dark in BOTH products (0/2989 and 0/4569),
    i.e. hi12 bit 7 AND bit 6 set together never occurs anywhere.  ⚠ the
    KN5000-only reading "hi12[6:5]==3 is dark" does NOT survive the WSA1R,
    which has 14 such words -- always cross-check the two corpora;
  * class4 values 7, B, E and F are dark in both (KN5000 also has 3, D
    empty; the WSA1R populates class 3 with 14 words);
  * hi12 bit 0 is rare but live: 15/2989 KN5000, 27/4569 WSA1R.
  => candidate ranking for an active COND search, cross-validated:
     hi12[7:6]==3, then class4 in {7,B,E,F}, then hi12 bit 0.

USAGE
  python3 dsp/tools/dark_codepoint_census.py [disasm_dir ...]
  (default: dsp/disasm and wsa1/dsp/disasm, relative to the repo root)

PASS/FAIL has no meaning here -- it is a census.  What matters is that the
numbers quoted in any COND-search design are REPRODUCED by this script.
"""
import collections
import glob
import os
import re
import sys

HI = lambda w: (w >> 24) & 0xfff
CLASS4 = lambda w: (w >> 20) & 0xf
CFMT = lambda w: (HI(w) & 0xf00) == 0xc00      # the C-format: no class4, no addr8

FIELD_NAME = ["lo12 bit %d" % b for b in range(12)] + \
             ["addr8 bit %d" % b for b in range(8)] + \
             ["class4 bit %d" % b for b in range(4)] + \
             ["hi12 bit %d" % b for b in range(12)]


def load(dirs):
    words = []
    for d in dirs:
        for f in sorted(glob.glob(os.path.join(d, "*.dsm"))):
            with open(f) as fh:
                words += [int(m, 16) for m in re.findall(r"\b([0-9A-F]{10})\b", fh.read())]
    return words


def census(name, words):
    alu = [w for w in words if not CFMT(w)]
    print("== %s: %d words (%d distinct), %d non-C-format" %
          (name, len(words), len(set(words)), len(alu)))

    ones = [sum(1 for w in words if w >> b & 1) for b in range(36)]
    dark = [b for b in range(36) if ones[b] == 0]
    print("  dark BITS (never set anywhere): %s" % (dark if dark else "NONE"))

    print("  hi12[7:5] value histogram (non-C-format):")
    h = collections.Counter((HI(w) >> 5) & 7 for w in alu)
    for v in range(8):
        print("     %d: %5d%s" % (v, h.get(v, 0), "   <-- DARK CODEPOINT" if not h.get(v) else ""))

    print("  hi12 bit 0: set in %d / %d" % (sum(1 for w in alu if HI(w) & 1), len(alu)))

    print("  class4 histogram (non-C-format):")
    c = collections.Counter(CLASS4(w) for w in alu)
    darkc = [k for k in range(16) if not c.get(k)]
    for k in range(16):
        print("     %X: %5d%s" % (k, c.get(k, 0), "   <-- DARK" if not c.get(k) else ""))
    print("  dark CLASSES: %s" % ", ".join("%X" % k for k in darkc))
    print()


if __name__ == "__main__":
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    dirs = sys.argv[1:] or [os.path.join(root, "dsp", "disasm"),
                            os.path.join(root, "wsa1", "dsp", "disasm")]
    for d in dirs:
        census(os.path.relpath(d, root), load([d]))
