#!/usr/bin/env python3
"""decode_leverage.py -- WHY does alu_decoded() refuse each word, and what would ONE decision buy?

QUESTION IT ANSWERS
    The coverage number is NOT a count of unknown instructions -- it is a count of OPEN AXES.
    `alu_decoded()' requires EVERY axis of a word (format, class, the bit-11 modifier, the pointer
    mode, an anchored SRC, an anchored ACT, the store's class/gate rules, and `f31').  A word with
    seven settled axes and one open one counts exactly like a word nobody understands at all.

    So this asks the predicate itself, per undecoded occurrence:
      * WHICH axes does it refuse on?  (the refusal-reason histogram)
      * How many occurrences are refused for EXACTLY ONE reason?  (those are one decision away)
      * ★ THE LEVERAGE TABLE: for each axis-value, how many occurrences would decode if that ONE
        thing were anchored and nothing else changed?

    That converts "decode 351 words" into a RANKED list of well-posed questions, each of the form
    "what does this one code name?".

USAGE
    python3 dsp/tools/decode_leverage.py [--top N] [dsp/disasm/*.dsm]

⚠ "Unblocks" means THE PREDICATE WOULD STOP REFUSING IT -- not that we know what the code does.
  Anchoring a code is a claim about the chip and needs evidence (the bytecode, or the HLE oracle).
  This tool ranks the QUESTIONS; it never answers one.
⚠ It imports the live `dsp_disasm', so it always reflects the predicate as it stands TODAY.  Re-run
  it after every anchoring -- the table reorders as axes close.
"""
import collections
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as D                                                   # noqa: E402
#   ⚠⚠ THE AXIS ENUMERATION LIVES IN `acc_blind.py' NOW, and this tool used to have its own.
#   Its copy ran the `alu_decoded()' guards UNCONDITIONALLY, which printed FICTIONAL axes on two
#   whole families: a C-format word has no class4/addr8 at all (bits [24:12] are one 13-bit
#   immediate), and a bit-11 word's lo12 is not the SRC/mode/ACTION route -- so the table was
#   charging 29 C-format words to "class 3 + SRC 0x11 + ACT 0x0C" and 76 bit-11 words to
#   "pointer mode 1 + SRC 0x11 + ACT 0x03", none of which are fields of those words.  It also
#   charged the class-1 DELAY ESCAPES to "class 1" although `_alu_half_anchored()' has no class
#   test.  The corrected table moves `ACT 0x0B' from 12 sole occurrences to 62 and makes
#   `C-format' and `bit-11 encoding' single axes -- i.e. it reorders the queue this tool exists
#   to steer.  Two copies of a decode table is a second thing to keep in step, and this project
#   has paid for that before (dsp_coverage.py's form table).
from acc_blind import open_axes                                          # noqa: E402

ROW = re.compile(r"^\s+w(\d+)\s+([0-9A-F]{10})\s")


def reasons(w):
    """every axis on which decoded() refuses w, as (axis, value) labels.  One axis per FIELD THAT
    EXISTS on the word -- see the import note above for the two families this used to invent."""
    return [(lab.split()[0].rstrip(","), lab) for lab in open_axes(w)]


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    top = 14
    if "--top" in sys.argv:
        top = int(sys.argv[sys.argv.index("--top") + 1])
    files = args or sorted(glob.glob(os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "disasm", "*.dsm")))
    words = []
    for f in files:
        if os.path.basename(f) in ("index.dsm",):
            continue
        for ln in open(f, errors="replace"):
            m = ROW.match(ln)
            if m:
                words.append(int(m.group(2), 16))

    #   ⚠ THE DENOMINATOR MUST BE `decoded()', NOT `alu_decoded()'.  The coverage number counts
    #   `decoded()' -- which also admits the nop, the pointer forms, setvec and (since 2026-09-13)
    #   the class-1 DELAY ESCAPE.  Measuring `alu_decoded()' here made the table keep charging the
    #   delay words to "class 1" long after they were executable, i.e. the leverage tool disagreed
    #   with the very number it was meant to steer.  Reasons are still enumerated against the ALU
    #   predicate, because that is what refuses the remainder.
    undec = [w for w in words if not D.decoded(w)]
    nreas = collections.Counter()
    sole = collections.Counter()
    appears = collections.Counter()
    axis_tot = collections.Counter()
    for w in undec:
        r = reasons(w)
        nreas[len(r)] += 1
        for _, lab in r:
            appears[lab] += 1
        for ax, _ in r:
            axis_tot[ax] += 1
        if len(r) == 1:
            sole[r[0][1]] += 1

    print("=== alu_decoded() REFUSAL ANALYSIS -- %d words, %d undecoded occurrences ==="
          % (len(words), len(undec)))
    print("\n-- how many AXES is each undecoded occurrence short of?")
    for k in sorted(nreas):
        print("   refused for %d reason%-2s : %5d  %5.1f %%%s"
              % (k, "" if k == 1 else "s", nreas[k], 100.0 * nreas[k] / len(undec),
                 "   ★ ONE DECISION AWAY" if k == 1 else
                 "   ⚠ would decode -- blocked elsewhere" if k == 0 else ""))

    print("\n-- refusals by AXIS (an occurrence can be short on several)")
    for ax, n in axis_tot.most_common():
        print("   %-10s %5d" % (ax, n))

    print("\n-- ★ THE LEVERAGE TABLE: anchor ONE thing, nothing else changes")
    print("   %-26s %8s %8s" % ("decision", "unblocks", "appears"))
    for lab, n in sole.most_common(top):
        print("   %-26s %8d %8d" % (lab, n, appears[lab]))
    cum = sum(n for _, n in sole.most_common(top))
    print("   %-26s %8d  = %.0f %% of the undecoded mass"
          % ("TOP %d TOGETHER" % top, cum, 100.0 * cum / len(undec)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
