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

ROW = re.compile(r"^\s+w(\d+)\s+([0-9A-F]{10})\s")


def reasons(w):
    """every axis on which alu_decoded() refuses w, as (axis, value) labels."""
    out = []
    if D.c_format(w):
        out.append(("format", "C-format"))
    cl = D.class4(w)
    if cl not in (2, 8, 0xA):
        out.append(("class", "class %X" % cl))
    if D.lo12(w) & 0x800:
        out.append(("bit11", "lo12 bit 11"))
    if D.lo_ptrmode(w):
        out.append(("ptrmode", "pointer mode %d" % D.lo_ptrmode(w)))
    if D.lo_src(w) not in D._ANCHORED_SRC:
        out.append(("SRC", "SRC 0x%02X" % D.lo_src(w)))
    if D.lo_act(w) not in D._ANCHORED_ACT:
        out.append(("ACT", "ACT 0x%02X" % D.lo_act(w)))
    hi = D.hi12(w)
    if (hi & D.HI_ST) and (cl & 7) != 2:
        out.append(("store", "bit-4 store on class %X" % cl))
    if D.lo_act(w) == D.LO_ACT_ST_BUS and (cl & 7) != 2:
        out.append(("store", "ACT 0x07 store on class %X" % cl))
    if (hi & D.HI_ST) and (hi & D.HI_B7) and D.hi_f31(hi) != 2:
        out.append(("storegate", "store+bit7 with f31 %d" % D.hi_f31(hi)))
    f = D.hi_f31(hi)
    if f not in (D.HI_ACC_LOAD, D.HI_ACC_ADD) and not (f == D.HI_ACC_HOLD and cl == 8):
        out.append(("f31", "f31 %d%s" % (f, " off class 8" if f == D.HI_ACC_HOLD else "")))
    return out


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
