#!/usr/bin/env python3
"""decoded_selfcheck.py -- is `decoded()' consistent with its own clauses, in BOTH directions?

QUESTION IT ANSWERS
    `decoded()' is a chain of format-explaining clauses, each gated on `_alu_half_anchored()'.  It
    has grown one clause at a time -- the delay escape (sect. 90), the block terminator (sect. 112),
    the C-format word (sect. 115/122), mode 1 (sect. 128), mode 4 (sect. 161, RETRACTED in sect. 162
    and kept only with a store guard).  Every one of those was added under time pressure with a
    result in hand, and two of them turned out to be wrong in ways the clause ORDER could hide:

      * a clause placed after one that already claims the word never fires, and its coverage
        contribution is silently zero;
      * a clause placed before one that should have claimed the word admits it on the WRONG
        grounds, and the listing then prints an operand the word does not have -- which is exactly
        what sect. 162 caught (`mac (p) ; mem[p]<-acc' on a mode-4 word, asserting the mode-2 store
        target that `r2-output.md' falsified).

    So this asks the invariant directly, over the pooled corpus:

      FORWARD   no word that `decoded()' REFUSES may satisfy any clause on its own.
      REVERSE   no word that `decoded()' ACCEPTS may fail every clause.

USAGE
    python3 dsp/tools/decoded_selfcheck.py          # exits non-zero if either direction fails

WHAT IT IS NOT
    ⛔ It does not check that the clauses are RIGHT -- that is what the notes, the nulls and the
    two-sided emulator runs are for, and sect. 162/sect. 164 are what happens when those are done
    badly.  It checks only that the predicate agrees with the reasons the project believes it holds,
    which is the cheap half and the half that silently rots when a clause is added or withdrawn.

    ⚠ Keep the REVERSE list in step with `decoded()' by hand.  A clause added there and forgotten
    here makes this file report a false failure; a clause REMOVED there and forgotten here makes it
    report a false pass, which is the dangerous direction.  It is duplicated on purpose: an
    invariant that imports the thing it checks checks nothing.

MEASURED 2026-09-14, pooled over the KN5000 + SX-WSA1R corpora:
    forward inconsistencies 0, reverse 0.  Every undecoded word is blocked on SEMANTICS -- an
    unanchored SRC/ACT, an unknown `f31', or an unexplained store target -- and not one of them is
    blocked by a bug in the predicate.

    ★★ AND THE PUBLISHED RATE IS INFLATED (sect. 176).  The SX-WSA1R tree carries BYTE-IDENTICAL
    duplicate images: 60 records resolve to 52 distinct programs, so 730 of the 8003 pooled words
    are replicas.  RULE 9 says de-duplicate before quoting a rate.  Honest figure:

        as published      8003 words   1501 undecoded   81.2 %
        DISTINCT images   7273 words   1413 undecoded   80.6 %   <- use this one

    The duplicates are REVERBS and are better decoded than the corpus average (11 of 91 open, 12 %
    against 18.8 %), so correcting this LOWERS the headline.  Reported anyway -- a correction that
    only ever flatters is not a correction.
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import class_twins as CT                                                  # noqa: E402


def clauses(w):
    """Every reason `decoded()' has for admitting a word, evaluated independently of order.
    Mirrors dsp_disasm.decoded() -- DUPLICATED DELIBERATELY (see the module docstring)."""
    hi, cl, ad, lo = DIS.fields(w)
    out = []
    if hi == 0x000 and cl == 2 and ad == 0x00 and lo == 0x000:
        out.append("nop")
    if DIS.is_ldptr(w) or DIS.is_rstcur(w) or DIS.is_ldptrd(w):
        out.append("regload")
    if DIS.is_setvec(w):
        out.append("setvec")
    if DIS.c_format(w):
        out.append("c-format")
    if DIS.is_terminator(w) and DIS._alu_half_anchored(w):
        out.append("terminator")
    if DIS.is_mode1(w) and DIS._alu_half_anchored(w):
        out.append("mode1")
    if DIS.is_mode4(w) and DIS._alu_half_anchored(w) and not (hi & DIS.HI_ST):
        out.append("mode4")
    if DIS.is_dram(w) and DIS.dram_dir(w) and DIS._alu_half_anchored(w):
        out.append("dram")
    if DIS.alu_decoded(w):
        out.append("alu")
    return out


def main():
    words = [w for _l, _i, _s, ws in CT.images() for w in ws]
    fwd = collections.Counter()
    rev = 0
    for w in words:
        cs = clauses(w)
        if DIS.decoded(w):
            if not cs:
                rev += 1
        else:
            for c in cs:
                fwd[c] += 1

    print("=" * 92)
    print("  decoded_selfcheck -- does `decoded()' agree with its own clauses?")
    print("=" * 92)
    und = sum(1 for w in words if not DIS.decoded(w))
    print("\n  pooled corpus: %d words, %d decoded, %d undecoded\n"
          % (len(words), len(words) - und, und))
    print("  FORWARD  refused by decoded() but satisfying a clause : %d %s"
          % (sum(fwd.values()), dict(fwd) if fwd else ""))
    print("  REVERSE  accepted by decoded() but satisfying none    : %d" % rev)

    #  a clause that never fires is not an error, but it IS worth seeing: sect. 162 left `mode4'
    #  admitting nothing, and a silent zero is how that would be forgotten.
    fired = collections.Counter()
    for w in words:
        if DIS.decoded(w):
            for c in clauses(w):
                fired[c] += 1
    print("\n  clause coverage (a word may satisfy more than one):")
    for c in ("nop", "regload", "setvec", "c-format", "terminator", "mode1", "mode4", "dram", "alu"):
        n = fired.get(c, 0)
        print("     %-12s %6d%s" % (c, n, "   <- admits NOTHING today" if n == 0 else ""))

    #  ★★ RULE 9 (2026-09-14, sect. 176): DE-DUPLICATE BEFORE QUOTING A RATE.  The SX-WSA1R tree
    #  carries BYTE-IDENTICAL duplicate images -- 60 records resolve to 52 distinct programs -- and
    #  the duplicates are REVERBS, which are better decoded than average, so counting them inflates
    #  the published figure.  Same defect `bit11-family.md' sect. 0 item C caught on the KN5000
    #  side, where one image replicated 42-fold turned 123 raw sites into 80 real ones.
    seen, dd, nimg, ndup = set(), [], 0, 0
    for label, img, slots, ws in CT.images():
        nimg += 1
        k = (label, tuple(ws))
        if k in seen:
            ndup += 1
            continue
        seen.add(k)
        dd.extend(ws)
    if ndup:
        du = sum(1 for w in dd if not DIS.decoded(w))
        print("\n  ★★ RULE 9 -- byte-identical duplicate images are inflating the rate:")
        print("     as published    %5d words  %5d undecoded  %5.1f %% decoded"
              % (len(words), und, 100.0 * (len(words) - und) / len(words)))
        print("     DISTINCT images %5d words  %5d undecoded  %5.1f %% decoded   <- the honest one"
              % (len(dd), du, 100.0 * (len(dd) - du) / len(dd)))
        print("     %d words in %d redundant images of %d.  They are REVERBS and are BETTER decoded"
              % (len(words) - len(dd), ndup, nimg))
        print("     than average, so de-duplicating LOWERS the headline rather than raising it.")

    ok = not fwd and not rev
    print("\n  %s" % ("★ CONSISTENT in both directions."
                      if ok else "⛔ INCONSISTENT -- see the counts above."))
    if ok:
        print("    ⇒ every one of the %d undecoded words is blocked on SEMANTICS (an unanchored" % und)
        print("      SRC/ACT, an unknown f31, or an unexplained store target), not on a defect in")
        print("      the predicate.  There is no coverage to be had by fixing `decoded()' itself.")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
