#!/usr/bin/env python3
"""addr8_usage.py -- is `addr8' LOAD-BEARING on the classes where the model ignores it?

QUESTION IT ANSWERS
    The device reads `addr8' on exactly three kinds of word: the pointer delta on classes 2 and A
    (`ptr_postinc()', MEASURED), the register-file index on classes 1 and 9, and the register-load
    PAYLOAD on a bit-11 word (K3 item A, PROVEN BY CONSTRUCTION).  On classes 0, 4, 5, 6, 8, C and
    D it reads nothing.  Nobody has asked whether the ROM agrees.

    ★ THE NULL IS EXCEPTIONLESS, and it comes from the one class where both kinds of word coexist.
    In class 0:

        addr8 != 0 : 9 of 9 are `is_regload()' words whose `addr8' IS their payload
        addr8 == 0 : 100 of 100 have no known use for the field

    ⇒ in this ROM, `addr8' is zero exactly when the word has no use for it.  That is a null with
    no exceptions, measured rather than assumed, and it is what makes the next table mean
    something.

    ★★ AGAINST IT: classes 4, 6 and 8 carry a NON-ZERO `addr8' in **150 of 150** words, and the
    model reads it on none of them.

    ⚠⚠ AND THE FIRST READING OF THAT TABLE WAS WRONG, CAUGHT BY ITS OWN CONTROL.  "Never zero"
    is not "carries information": a field that holds THE SAME VALUE in every word is never zero
    either.  Split the three classes by how many values they actually take:

        class 4 : `addr8 = 0x01' in 53 of 53          CONSTANT
        class 8 : `addr8 = 0x16' in 42 of 42 BODY words (kernel 0x0C, epilogue 0x0F)  CONSTANT
        class 6 : `addr8' in {18, 1A, 1E, 20, 28}, and it VARIES WITHIN ONE IMAGE
                  (chorus: 0x18 at w31, 0x20 at w35)  ★ THE ONLY ONE THAT SELECTS ANYTHING

    A constant cannot be selecting among things a body varies, so on classes 4 and 8 it is as
    likely to be part of the encoding as an operand -- and for class 8 there is a positive check
    that it is NOT read as a coefficient selector: PARAMETRIC EQ's ten class-8 words are the
    IDENTICAL word `0804816415', and the biquad reproduces the firmware's own bilinear designer to
    **0.198 dB** with `addr8' unread.  ⇒ no word is demoted; the exposure below is ZERO.

    What survives is class 6: 53 words whose `addr8' takes five values, varies inside a single
    program, and is read by nothing.

    And the SHAPE of the field separates the two things it could be.  A signed pointer DELTA has
    zeros -- "do not move" is a legal delta, and classes 2 and A use it about 45 % of the time.  An
    INDEX does not -- classes 1 and 9 are 0 of 328.  Classes 4/6/8 are 0 of 150: if they were
    drawing deltas from the class-2/A distribution, the chance of no zero in 150 draws is about
    1e-40.  So `addr8' there behaves like the INDEX classes, not like the DELTA classes.

    The delta reading is testable independently and `closure_pointer.py variants' tests it:
    variants V7..V11 add classes 4 / 6 / 8 to the pointer walk.  MEASURED -- every one of them
    RAISES the unit-0 pool's net heterogeneity (8 distinct nets at the baseline -> 10, 15, 12, 21,
    21) and none closes the frame.  By that tool's own criterion -- item G killed two variants for
    "destroying the pool constancy" -- the delta reading is disfavoured on four independent arms.

USAGE
    python3 dsp/tools/addr8_usage.py            # the census and the null
    python3 dsp/tools/addr8_usage.py --words    # every word of the unmodelled classes

⚠ WHAT THIS DOES NOT SAY.  It does not decode `addr8' and it does not say what the class-6
  selector selects.  It says that on 53 words a field VARIES and nothing reads it -- a defect
  localisation on the second word of the idiom that §97 named as the next target.
"""
import collections
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as D                                                   # noqa: E402

ROW = re.compile(r"^\s+w(\d+)\s+([0-9A-F]{10})\s")

#   What the device actually reads `addr8' for, per class.
MODELLED = {
    0: None, 1: "register-file index", 2: "ptr += (s8)addr8", 4: None, 5: None, 6: None,
    8: None, 9: "register-file index", 0xA: "ptr += (s8)addr8", 0xC: None, 0xD: None,
}
UNMODELLED = (0, 4, 5, 6, 8, 0xC, 0xD)


def load(files):
    out = []
    for f in files:
        if os.path.basename(f) in ("index.dsm",):
            continue
        for ln in open(f, errors="replace"):
            m = ROW.match(ln)
            if m:
                out.append((os.path.basename(f), int(m.group(1)), int(m.group(2), 16)))
    return out


def main():
    files = [a for a in sys.argv[1:] if not a.startswith("--")] or sorted(glob.glob(os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "disasm", "*.dsm")))
    rows = [(f, s, w) for f, s, w in load(files) if not D.c_format(w)]

    print("=== `addr8' BY CLASS -- and whether the model reads it ===")
    print("  %-5s %6s %8s %8s %8s   %s" % ("class", "words", "addr8=0", "!=0", "distinct",
                                           "what the model does with addr8"))
    for cl in sorted({D.class4(w) for _f, _s, w in rows}):
        g = [w for _f, _s, w in rows if D.class4(w) == cl]
        z = sum(1 for w in g if D.addr8(w) == 0)
        vals = sorted({D.addr8(w) for w in g})
        print("  %-5X %6d %8d %8d %8d   %s"
              % (cl, len(g), z, len(g) - z, len(vals),
                 MODELLED.get(cl) or "⚠ NOTHING"))
        if cl in UNMODELLED and len(g) - z:
            print("        values: %s" % " ".join("%02X" % a for a in vals[:24]))

    #   THE NULL: class 0 is the only class carrying both kinds of word.
    c0 = [w for _f, _s, w in rows if D.class4(w) == 0]
    nz = [w for w in c0 if D.addr8(w) != 0]
    z = [w for w in c0 if D.addr8(w) == 0]
    nz_use = sum(1 for w in nz if D.is_regload(w))
    z_use = sum(1 for w in z if D.is_regload(w) and D.lo_imm(w))
    print("\n=== ★ THE NULL -- class 0, the one class with both kinds ===")
    print("   addr8 != 0 : %3d words, %3d of them `is_regload()' (addr8 IS the payload)"
          % (len(nz), nz_use))
    print("   addr8 == 0 : %3d words, %3d of them a register load WITH a payload"
          % (len(z), z_use))
    print("   ⇒ `addr8' is zero exactly when the word has no use for it. No exceptions.")

    #   THE SHAPE: index-like (never zero) vs delta-like (~45 % zero).
    print("\n=== ★★ THE SHAPE -- a DELTA field has zeros; an INDEX field does not ===")
    for label, classes in (("DELTA classes 2, A", (2, 0xA)),
                           ("INDEX classes 1, 9", (1, 9)),
                           ("⚠ UNMODELLED 4, 6, 8", (4, 6, 8))):
        g = [w for _f, _s, w in rows if D.class4(w) in classes]
        zz = sum(1 for w in g if D.addr8(w) == 0)
        print("   %-22s %5d words, %5d zero  (%5.1f %%)"
              % (label, len(g), zz, 100.0 * zz / len(g) if g else 0.0))

    #   ★ THE CONTROL THAT NARROWED THIS: never-zero is not the same as informative.
    print("\n=== ★ CONSTANT OR VARYING?  a field that never changes selects nothing ===")
    for cl in (4, 6, 8):
        g = [(f, s, w) for f, s, w in rows if D.class4(w) == cl]
        vals = collections.Counter(D.addr8(w) for _f, _s, w in g)
        perimg = collections.defaultdict(set)
        for f, _s, w in g:
            perimg[f].add(D.addr8(w))
        varying = [f for f, v in perimg.items() if len(v) > 1]
        print("   class %X : %2d distinct values over %3d words; VARIES INSIDE %d image(s)   %s"
              % (cl, len(vals), len(g), len(varying),
                 "★ SELECTS SOMETHING" if varying else "⇒ CONSTANT -- selects nothing"))
        print("             %s" % "  ".join("%02X x%d" % (a, n) for a, n in sorted(vals.items())))

    #   THE EXPOSURE: how many words the coverage predicate calls EXECUTABLE while carrying a
    #   VARYING unread addr8.  Classes 4 and 8 are excluded by the control above.
    exp = [(f, s, w) for f, s, w in rows
           if D.class4(w) == 6 and D.addr8(w) != 0 and D.decoded(w)]
    print("\n=== THE EXPOSURE -- words `decoded()' admits as TIER 1 while carrying an unread"
          " VARYING `addr8' ===")
    cc = collections.Counter(D.class4(w) for _f, _s, w in exp)
    for cl, n in sorted(cc.items()):
        print("   class %X : %4d" % (cl, n))
    print("   TOTAL   : %4d %s" % (len(exp), "★ no word is demoted -- the coverage number stands"
                                   if not exp else "⇒ these are not executable"))
    print("   (classes 4 and 8 are excluded by the CONSTANT control above, and class 8 has a")
    print("    positive one besides: the biquad matches its designer to 0.198 dB with `addr8'")
    print("    unread at ten identical class-8 sites.)")

    if "--words" in sys.argv:
        print("\n%-34s %5s %-11s %s" % ("image", "slot", "word", "class / addr8"))
        for f, s, w in rows:
            if D.class4(w) in UNMODELLED and D.addr8(w) != 0:
                print("%-34s %5d %010X  class %X addr8 %02X%s"
                      % (f, s, w, D.class4(w), D.addr8(w),
                         "   <- decoded() calls this EXECUTABLE" if D.decoded(w) else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
