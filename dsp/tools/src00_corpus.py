#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""src00_corpus.py -- the STATIC half of the `SRC 0x00' discrimination.

NEC uPD6383GF (Technics SX-KN5000, IC311).  BUILD-LANE-QUEUE item 0 as replaced
by 232 sect. 7.2.  Read-only: corpus only, no build, no MAME run.

THE QUESTION IT ANSWERS
  `SRC 0x00' is +348 corpus words = 46 % of the whole routing ceiling (232), and
  `upd6383.cpp' reads it as `mem[ptr]' on a reading its own comment grades
  "1 of 6 enumerated, no independent support".  Before any run (standing rule 13,
  and 232 sect. 7.2 pre-registers CORPUS DISCRIMINATION FIRST): what does the
  ENCODING itself say -- how many SRC-0x00 words are there, which programs hold
  them, which ACTIONs do they pair with, and which classes?

  The rival this census is aimed at is the NULL-ROUTING reading: `lo12 == 0x000'
  is not "source 0 + action 0", it is the encoding for a plain MAC with NO bus
  term.  `upd6383.cpp' calls that reading "attractive and WRONG" and cites
  `action00-discriminator.md' item I -- which `adjudication-round6.md' sect. 14
  VOIDED (the SINGLE DELAY leg it rests on is one of the void ones).  So the
  refutation on record does not currently stand up, and the corpus statistic is
  the cheapest thing that can speak to it.

    python3 dsp/tools/src00_corpus.py

stdlib only (plus the research tree's own loader).
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pat_corpus import load, F                            # noqa: E402

#  RULE 20 SELF-TEST: published figures this census must reproduce or fail.
PUB_WORDS = 3057                       # 231/232, the whole static corpus


def main():
    progs, _meta = load()
    tot = sum(len(v) for v in progs.values())
    s0 = [(nm, i, F(w)) for nm, ws in progs.items()
          for i, w in enumerate(ws) if not F(w).cfmt and F(w).src == 0x00]

    print("== RULE 20 SELF-TEST")
    print("   corpus words                 %4d   published %4d   %s"
          % (tot, PUB_WORDS, "PASS" if tot == PUB_WORDS else "FAIL"))

    print("\n== SRC 0x00, non-C-format, over the whole corpus")
    print("   words                        %4d" % len(s0))
    print("   ACTION pairing               %s"
          % dict(collections.Counter(f.act for _n, _i, f in s0).most_common()))
    print("   class4                       %s"
          % dict(collections.Counter(f.class4 for _n, _i, f in s0).most_common()))
    print("   lo12 (top 10)                %s"
          % collections.Counter(f.lo12 for _n, _i, f in s0).most_common(10))
    print("   lo12 bit 5 (pointer-mode)    %s"
          % dict(collections.Counter((f.lo12 >> 5) & 1 for _n, _i, f in s0)))
    print("\n   per program:")
    per = collections.Counter(nm for nm, _i, _f in s0)
    for nm in progs:
        if per[nm]:
            print("      %-24s %3d / %3d words" % (nm, per[nm], len(progs[nm])))

    #  The two known-mathematics programs, named because 232 sect. 7.2 makes
    #  their harnesses LIVE falsifiers for any change to this code.
    print("\n== THE TWO KNOWN-MATHEMATICS PROGRAMS (232 sect. 7.2's live falsifiers)")
    for want in ("a39 PARAMETRIC EQ", "a09 SINGLE DELAY"):
        rows = [(i, f) for nm, i, f in s0 if nm == want]
        print("   %-20s %d SRC-0x00 words: %s"
              % (want, len(rows),
                 ", ".join("w%d %s" % (i, f.txt()) for i, f in rows)))


if __name__ == "__main__":
    main()
