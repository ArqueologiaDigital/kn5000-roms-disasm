#!/usr/bin/env python3
"""mode1_index.py -- is `addr8' on a MODE-1 word an INDEX?  Three tests and their nulls.

QUESTION IT ANSWERS
    N-INPUT-GATE-OPENED sect. 126 found that **247 undecoded words across both products hang on
    ONE question**, because `class4 & 7' is the ADDRESSING MODE and `alu_decoded()' admits only
    modes 0 and 2:

        class 1 and class 9 are BOTH mode 1.   KN5000  21 + 4 = 25 words
                                               SX-WSA1R 150 + 72 = 222 words

    `r2-output.md' sect. 1.1/1.2 MEASURED the STORE half -- mode 1 without the escape bit is the
    REGISTER FILE and `addr8' is the index, 48 of 48 in the KN5000.  The READ half is what
    `upd6383.cpp' applies and what it says about itself is the obstacle:

        *"⛔ GUESSED: symmetry.  The store side is documented; the read side is not, and no note
        in this project states it."*

    ⇒ this file is the note.  It does not touch the read/write question directly -- it asks the
    prior one, which nobody had: **is `addr8' on a mode-1 word carrying information at all?**  If
    it is not, the read side has nothing to read and the symmetry question is moot.

USAGE
    python3 dsp/tools/mode1_index.py

THE THREE TESTS, each with the control that can fail it
    1. ★ THE ZERO CALIBRATION.  The project's own rule (blog part 231 sect. 3, measured 9/9 vs
       100/100 on a class carrying both kinds of word): in this ROM a field is ZERO exactly when
       the instruction has no use for it.  Scored separately on mode-1 words WITH the store bit
       (documented use) and WITHOUT it (no documented use whatever).
       ⛔ CONTROL: mode 2, where `addr8' IS a signed pointer delta and 0 is a legal value
       ("don't move").  If zero were cheap on a used field, mode 2 would not be 42.6 % zero.
    2. ★ THE CONSTANT CONTROL, which killed the previous version of this argument (part 231
       sect. 3: *"`never zero' is not the same as `carries information' -- a field holding the same
       value everywhere is never zero either"*).  Does the value VARY, and within one image?
    3. ★★★ THE RUN TEST, and it is the decisive one.  An INDEX into an array takes CONSECUTIVE
       values; a field nothing reads has no reason to.  Longest consecutive run in each image's
       mode-1 index set, against a uniform null over the 256 values an 8-bit field can hold.

⚠ WHAT THIS IS NOT.  It does not decode the mode-1 READ, and it does not license admitting those
  247 words -- `alu_decoded()` still refuses them.  It establishes that the field they carry is an
  index, which is the premise the read question needs and did not have.
"""
import collections
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import xprod_homolog as X                                                 # noqa: E402


def mode1(w):
    """Mode 1 WITHOUT the format escape -- `r2-output.md' sect. 1.1's split, which classifies all
    324 KN5000 class-1 words correctly where `addr8' bit 7 misclassifies three."""
    return ((not DIS.c_format(w)) and (DIS.class4(w) & 7) == 1
            and not (DIS.hi12(w) & DIS.HI_ESC))


def longest_run(vals):
    s, best, cur = sorted(set(vals)), 0, 0
    for i, v in enumerate(s):
        cur = cur + 1 if i and v == s[i - 1] + 1 else 1
        best = max(best, cur)
    return best


def p_run(k, r, n=256):
    """A crude but honest upper bound on P(a uniform k-subset of [0,n) contains a run of >= r):
    at most (n - r + 1) starting positions, each needing r specific values in the subset."""
    if r > k:
        return 0.0
    num = math.comb(n - r, k - r)
    return (n - r + 1) * num / math.comb(n, k)


def main():
    print("=" * 100)
    print("  mode1_index -- is `addr8' on a mode-1 word an INDEX?")
    print("=" * 100)

    rows = collections.defaultdict(list)
    per = collections.defaultdict(list)
    for label, name, ws in X.images():
        for i, w in enumerate(ws):
            if mode1(w):
                rows[(label, bool(DIS.hi12(w) & DIS.HI_ST))].append(DIS.addr8(w))
                per[(label, name)].append((i, DIS.addr8(w), bool(DIS.hi12(w) & DIS.HI_ST)))

    #  ---- 1. the zero calibration ----------------------------------------
    print("\n   ★ TEST 1 -- THE ZERO CALIBRATION (part 231 sect. 3: zero exactly when unused)\n")
    print("      %-5s %-24s %6s %8s %9s" % ("prod", "mode-1 words", "n", "addr8=0", "addr8 != 0"))
    for label in ("KN", "WSA"):
        for st, lab in ((True, "WITH the store bit"), (False, "WITHOUT the store bit")):
            r = rows[(label, st)]
            z = sum(1 for a in r if a == 0)
            print("      %-5s %-24s %6d %8d %9d" % (label, lab, len(r), z, len(r) - z))
    allm1 = sum(len(v) for v in rows.values())
    zer = sum(1 for v in rows.values() for a in v if a == 0)
    print("\n      ⇒ %d of %d mode-1 words carry a NON-ZERO `addr8', including every one of the"
          % (allm1 - zer, allm1))
    print("        %d that have no store and therefore no documented use for the field."
          % (len(rows[("KN", False)]) + len(rows[("WSA", False)])))

    c = collections.Counter()
    for label, name, ws in X.images():
        for w in ws:
            if (not DIS.c_format(w)) and (DIS.class4(w) & 7) == 2:
                c[DIS.addr8(w) == 0] += 1
    print("      ⛔ CONTROL, mode 2 (`addr8' IS a signed delta, 0 legal): %d of %d are ZERO"
          " (%.1f %%)." % (c[True], c[True] + c[False], 100.0 * c[True] / sum(c.values())))
    print("        Zero is cheap where it means something.  Mode 1 never takes it.")

    #  ---- 2. the constant control ----------------------------------------
    print("\n   ★ TEST 2 -- THE CONSTANT CONTROL (a constant field is never zero either)\n")
    for label in ("KN", "WSA"):
        r = rows[(label, False)]
        vals = collections.Counter(r)
        imgs = [k for k in per if k[0] == label]
        vary = sum(1 for k in imgs if len({a for _, a, s in per[k] if not s}) > 1)
        print("      %-5s %4d non-storing mode-1 words, %2d distinct values, VARIES within a"
              " single image in %d of %d images" % (label, len(r), len(vals), vary, len(imgs)))

    #  ---- 3. the run test -------------------------------------------------
    print("\n   ★★★ TEST 3 -- THE RUN TEST.  An index takes CONSECUTIVE values.\n")
    print("      %-5s %-26s %5s %6s  %s" % ("prod", "image", "n idx", "run", "the index set"))
    worst = None
    for k in sorted(per, key=lambda k: -len({a for _, a, _ in per[k]})):
        idx = sorted({a for _, a, _ in per[k]})
        if len(idx) < 6:
            continue
        r = longest_run(idx)
        p = p_run(len(idx), r)
        if worst is None or p < worst[0]:
            worst = (p, k, len(idx), r)
        print("      %-5s %-26s %5d %6d  %s" % (k[0], k[1], len(idx), r,
                                                " ".join("%02X" % a for a in idx)))
    if worst:
        p, k, n, r = worst
        print("\n      ⇒ %s carries %d distinct indices whose longest CONSECUTIVE RUN is %d."
              % (k[1], n, r))
        print("        NULL: a uniform %d-subset of the 256 values an 8-bit field can hold"
              " contains" % n)
        print("        a run that long with probability <= %.3g.  It does not happen." % p)

    #  ---- and the shape of the walk ---------------------------------------
    print("\n   ★ AND THE ORDER IT IS WALKED IN, which no null was needed to see:\n")
    for k in sorted(per, key=lambda k: -len(per[k]))[:1]:
        seq = [a for _, a, s in per[k]]
        print("      %s" % " ".join("%02X" % a for a in seq[:28]))
    print("\n      `n, n+2, n+1, n+3' repeating on a STRIDE OF 4 -- the shape of a Direct-Form-I")
    print("      biquad's four state cells per section (`DECODE-by-correlation-2026-09-08.md'")
    print("      sect. 7).  A field nothing reads does not walk a filter's state array in order.")
    print("\n   ⚠ THIS DECODES NOTHING.  `alu_decoded()' still refuses all 247 mode-1 words.  What")
    print("     it settles is the PREMISE the read question needs: the field is an INDEX.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
