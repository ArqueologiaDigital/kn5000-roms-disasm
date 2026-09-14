#!/usr/bin/env python3
"""class_space.py -- which `class4' values EXIST?  The KN5000's answer is not the ISA's.

QUESTION IT ANSWERS
    Two notes fix the class space, and both are quoted as ISA facts:

      `r2-output.md' sect. 1:      *"class 3 and class B do not exist.  All 31 words with
                                   `class4 & 7 == 3' are C-FORMAT words whose `class4' field is
                                   immediate data.  Same for classes 7/E/F: absent."*
      `isa-adjudication.md' 2:     *"The single apparent class-3 word in the entire 3057-word
                                   corpus is `C04.3.12.820' -- a header word of the pointer-load
                                   `lo12 = 0x820' family, which cannot be a `class 3'.  Wide, the
                                   class space is exactly {0,1,2,4,5,6,8,9,A,C,D}."*

    Both are correct **about the KN5000**, and both say "the corpus" meaning that one.  The
    SX-WSA1R runs the same ISA.

    ⇒ THE SECOND PRODUCT CARRIES THREE DISTINCT **NON-C-FORMAT** CLASS-3 WORDS:

        104.3.40.1CE  x6   WSA1R kernel              SRC 07  ACT 0E  f31 2
        104.3.40.1D5  x6   WSA1R kernel              SRC 07  ACT 15  f31 2
        182.3.10.419  x2   WSA1R eff54_pitch_shifter SRC 10  ACT 19  f31 1

    `hi12' is 0x104 / 0x182, nowhere near the `0xC00' C-format mask, so `class4' is NOT immediate
    data on them.  **`class 3' exists**, and the class space is wider than `{0,1,2,4,5,6,8,9,A,C,D}'.

USAGE
    python3 dsp/tools/class_space.py

⛔ WHAT THIS DOES NOT DO.  It does not decode mode 3.  Those 14 occurrences are blocked by the
  CLASS TEST ALONE -- their SRC, ACT and f31 are all anchored -- so they would fall out the moment
  mode 3's ADDRESSING were documented, which is the condition sect. 128 admitted mode 1 on.  It is
  not documented: `class4 & 7 == 3' is `mode 2 | mode 1' bitwise, which SUGGESTS pointer AND
  register-file addressing together, and a suggestion is not a reading.  There is also NO CLASS
  TWIN for any of the three (`class_twins.py`'s instrument finds none at their (hi12, addr8, lo12)),
  so the pooled corpus offers no minimal pair either.  Recorded as a precisely-bounded queue entry.
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import xprod_homolog as X                                                 # noqa: E402

PUBLISHED = {0, 1, 2, 4, 5, 6, 8, 9, 0xA, 0xC, 0xD}


def main():
    print("=" * 100)
    print("  class_space -- which `class4' values exist, per product")
    print("=" * 100 + "\n")

    seen = collections.defaultdict(lambda: collections.Counter())
    nonc = collections.defaultdict(lambda: collections.Counter())
    words = collections.defaultdict(collections.Counter)
    where = collections.defaultdict(set)
    for label, name, ws in X.images():
        for w in ws:
            c = DIS.class4(w)
            seen[label][c] += 1
            if not DIS.c_format(w):
                nonc[label][c] += 1
                words[c][w] += 1
                where[w].add(label + ":" + name)

    print("   %-5s %s" % ("prod", "class4 values on NON-C-FORMAT words (the ones that are a class)"))
    for label in ("KN", "WSA"):
        print("   %-5s %s" % (label, " ".join("%X(x%d)" % kv for kv in sorted(nonc[label].items()))))
    pooled = set(nonc["KN"]) | set(nonc["WSA"])
    print("\n   published class space (isa-adjudication item 2): %s"
          % " ".join("%X" % c for c in sorted(PUBLISHED)))
    print("   POOLED, measured                                : %s"
          % " ".join("%X" % c for c in sorted(pooled)))
    extra = sorted(pooled - PUBLISHED)
    missing = sorted(PUBLISHED - pooled)
    print("\n   ⇒ beyond the published space: %s"
          % (" ".join("%X" % c for c in extra) if extra else "nothing"))
    print("   ⇒ published but absent even pooled: %s"
          % (" ".join("%X" % c for c in missing) if missing else "nothing"))

    for c in extra:
        print("\n   ★ CLASS %X -- every distinct word, with the product that carries it\n" % c)
        for w, n in words[c].most_common():
            print("      %03X.%X.%02X.%03X  x%-3d  SRC %02X  ACT %02X  f31 %d  ESC %d  %-8s  %s"
                  % (DIS.hi12(w), DIS.class4(w), DIS.addr8(w), DIS.lo12(w), n,
                     DIS.lo_src(w), DIS.lo_act(w), DIS.hi_f31(DIS.hi12(w)),
                     1 if DIS.hi12(w) & DIS.HI_ESC else 0,
                     "DECODED" if DIS.decoded(w) else "traps", sorted(where[w])[0]))
        kn = sum(n for w, n in words[c].items() if any(s.startswith("KN") for s in where[w]))
        print("\n      KN5000 occurrences: %d   ⇒ the published claim is %s"
              % (kn, "KN5000-LOCAL, not an ISA fact" if kn == 0 else "WRONG IN ITS OWN PRODUCT"))
    print("\n   ⛔ NOT DECODED.  These are blocked by the CLASS TEST ALONE -- SRC, ACT and f31 all")
    print("     anchored -- so they fall out the moment mode 3's ADDRESSING is documented, which")
    print("     is what sect. 128 admitted mode 1 on.  It is not documented, and there is no class")
    print("     twin at their (hi12, addr8, lo12) either, so the corpus offers no minimal pair.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
