#!/usr/bin/env python3
"""kn1500_twins.py -- does the third product complete any MINIMAL PAIR the other two lack?

QUESTION IT ANSWERS
    sect. 208 tested the obvious use of a third corpus -- relocation -- and it failed: 87 % of the
    KN1500's words already sit in the pool, only 1 of 31 blocks matches a known program above
    0.90, and that one true twin is 111 of 116 words identical with ZERO single-field
    differences.  Nothing was relocated, so nothing was isolated.

    But relocation is not the only thing a corpus can give.  `class_twins.bit7_twins' studies a
    different instrument: two words IDENTICAL IN EVERY FIELD BUT ONE, which isolates that field
    without needing them to be the same program at two offsets.  The KN1500 contributes 175
    distinct words present in NO other product -- and a new word can COMPLETE a pair whose other
    half was already in the pool but had no partner.

    So this asks, per field:

      * how many single-field twin pairs the KN1500 corpus contains
      * which of them are NEW -- absent from the pooled KN5000 + SX-WSA1R corpus
      * of the new ones, which have exactly ONE undecoded member, because those are the pairs
        that could isolate an axis that is actually open
      * and the NULL: how many such pairs a shuffle of the same words produces, so "we found
        some" has something to be measured against

USAGE
    python3 dsp/tools/kn1500_twins.py

WHAT IT IS NOT
    ⚠ A twin is NOT a relocation and does not by itself decode anything: it says "these two words
    differ only in field F", not what F means.  It is a lead generator.  And a pair drawn from
    two DIFFERENT programs is weaker than one inside a single program, because different programs
    legitimately differ -- sect. 208 records 32 such pairs generated before I noticed that, and
    they proved nothing.  Pairs sharing a block are marked.

    ⚠ The KN1500 corpus is SCAN-DERIVED (93 % block recall, 95 % precision) and its words are
    selected for vocabulary match.  Nothing here may be turned into a coverage rate.
"""
import collections
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import kn1500_corpus as K                                                 # noqa: E402
import acc_blind as AB                                                    # noqa: E402

#  Each axis: a name, a key function returning "everything except this field", a function that
#  extracts the field, one that rebuilds a word with a new field value, and whether varying the
#  field ISOLATES a modifier.
#
#  ⚠⚠ `lo12' IS NOT AN ISOLATING AXIS and v1 treated it as one.  `lo12' carries the SRC and the
#  ACTION -- it is the operation selector -- so two words "differing only in lo12" are simply two
#  DIFFERENT INSTRUCTIONS that happen to share an address and an ALU half.  That is not a minimal
#  pair in any useful sense, and the 12 "pairs isolating an open axis" v1 reported on it isolate
#  nothing.  Kept in the table as a COUNT, excluded from the conclusion.
AXES = (
    ("hi12 bit 7", lambda w: (DIS.hi12(w) & ~DIS.HI_B7, DIS.class4(w), (w >> 12) & 0xff,
                              DIS.lo12(w)),
     lambda w: (DIS.hi12(w) >> 7) & 1, 7, 1, True),
    ("hi12 bit 4 (store)", lambda w: (DIS.hi12(w) & ~DIS.HI_ST, DIS.class4(w), (w >> 12) & 0xff,
                                      DIS.lo12(w)),
     lambda w: (DIS.hi12(w) >> 4) & 1, 4, 1, True),
    ("f31 (hi12[3:1])", lambda w: (DIS.hi12(w) & ~0x00E, DIS.class4(w), (w >> 12) & 0xff,
                                   DIS.lo12(w)),
     lambda w: (DIS.hi12(w) >> 1) & 7, 1, 3, True),
    ("class4", lambda w: (DIS.hi12(w), (w >> 12) & 0xff, DIS.lo12(w)),
     lambda w: DIS.class4(w), 20, 4, True),
    ("addr8", lambda w: (DIS.hi12(w), DIS.class4(w), DIS.lo12(w)),
     lambda w: (w >> 12) & 0xff, 12, 8, True),
    ("lo12 (NOT isolating)", lambda w: (DIS.hi12(w), DIS.class4(w), (w >> 12) & 0xff),
     lambda w: DIS.lo12(w), 0, 12, False),
)


def pairs_over(words, keyf):
    """Every unordered pair of DISTINCT words sharing the key -- i.e. differing only here."""
    g = collections.defaultdict(set)
    for w in words:
        g[keyf(w)].add(w)
    out = []
    for k, v in g.items():
        v = sorted(v)
        for i in range(len(v)):
            for j in range(i + 1, len(v)):
                out.append((v[i], v[j]))
    return out


def main():
    kw = K.words()
    kd = sorted(set(kw))
    known = K.known_words()
    #  which KN1500 block(s) each word appears in, for the same-program marking
    where = collections.defaultdict(set)
    for idx, (a, ws) in enumerate(K.blocks()):
        for w in ws:
            where[w].add(idx)

    print("=" * 96)
    print("  kn1500_twins -- does the third product complete a minimal pair the other two lack?")
    print("=" * 96)
    print("\n  KN1500 distinct words %d (%d new to the project) | pooled corpus %d words"
          % (len(kd), sum(1 for w in kd if w not in known), len(known)))

    known_sorted = sorted(known)
    rng = random.Random(20260914)
    print("\n  axis                  pairs   NEW   NEW & exactly one member UNDECODED    null")
    interesting = []
    for name, keyf, getf, shift, width, isolating in AXES:
        pk = pairs_over(kd, keyf)
        pnset = set(pairs_over(known_sorted, keyf))
        new = [p for p in pk if p not in pnset]
        useful = [p for p in new
                  if (not DIS.decoded(p[0])) != (not DIS.decoded(p[1]))]
        #  ⚠⚠ THE NULL.  v1's "shuffle" was `(w & ~0xFFFFFFFFF) | ...', and `w & ~0xFFFFFFFFF' is
        #  ZERO for a 36-bit word, so it returned the corpus unchanged and the null reproduced
        #  the observation EXACTLY -- 7.0 against 7, 39.0 against 39.  A null that equals its
        #  observation is the same number computed twice.  This one really does resample the
        #  varying field, from the corpus's own marginal distribution, keeping every other field.
        vals = [getf(w) for w in kd]
        mask = ((1 << width) - 1) << shift
        nulls = []
        for _ in range(30):
            shuf = {(w & ~mask) | ((vals[rng.randrange(len(vals))] << shift) & mask)
                    for w in kd}
            nulls.append(len([p for p in pairs_over(sorted(shuf), keyf) if p not in pnset]))
        mu = sum(nulls) / float(len(nulls))
        print("  %-21s %5d %5d %38d   %6.1f%s"
              % (name, len(pk), len(new), len(useful), mu,
                 "" if isolating else "   <- not a minimal pair"))
        if isolating:
            interesting.extend((name, p) for p in useful)

    print("\n" + "=" * 96)
    print("  THE PAIRS THAT COULD ISOLATE AN OPEN AXIS")
    print("=" * 96)
    if not interesting:
        print("\n  NONE on any ISOLATING axis.  Every new single-field pair over bit 7, the")
        print("  store bit, `f31', `class4' or `addr8' has both members already decoded or both")
        print("  undecoded -- so none isolates an axis that is open.  The `lo12' column is")
        print("  excluded by construction: `lo12' carries SRC and ACTION, so words differing")
        print("  only there are different INSTRUCTIONS, not a minimal pair.")
        print("  ⇒ the third corpus contributes no usable new minimal pair, and sect. 208's")
        print("    verdict extends from RELOCATION to TWINS.")
        ngrams()
        return 0
    return 0


def ngrams():
    """★ The OTHER static instrument the option named: are the KN1500's instruction SEQUENCES
    novel, and do the novel ones contain anything undecoded?  A new IDIOM would be a lead even
    where a new WORD is not, because the project's two paying decodes both came from recognising
    a recurring sequence (`C63 | class-6 | class-4', the delay escape)."""
    import class_twins as CT2                                            # noqa: E402
    ks = {}
    for n in (2, 3):
        s2 = set()
        for _l, _i, _sl, ws in CT2.images():
            for i in range(len(ws) - n + 1):
                s2.add(tuple(ws[i:i + n]))
        ks[n] = s2
    kn = K.known_words()
    print("\n" + "=" * 96)
    print("  n-GRAM NOVELTY -- do the KN1500's SEQUENCES differ, even where its words do not?")
    print("=" * 96 + "\n")
    for n in (2, 3):
        seen, novel = set(), []
        for a, ws in K.blocks():
            for i in range(len(ws) - n + 1):
                g = tuple(ws[i:i + n])
                if g in seen:
                    continue
                seen.add(g)
                if g not in ks[n]:
                    novel.append(g)
        und = [g for g in novel if any(not DIS.decoded(w) for w in g)]
        reorder = [g for g in novel if all(w in kn for w in g)]
        print("  %d-grams: %4d distinct, %4d NOVEL (%2.0f %%) | containing an UNDECODED word %3d"
              % (n, len(seen), len(novel), 100.0 * len(novel) / len(seen), len(und)))
        print("            of the novel, made ENTIRELY of words already in the pool -- a novel")
        print("            ORDER rather than novel material: %d (%.0f %% of the novel)"
              % (len(reorder), 100.0 * len(reorder) / max(len(novel), 1)))
    print("\n  ⚠ Novel ORDER is the weakest kind of novelty: the same instructions in a new")
    print("    sequence tell you the product does something different, not what any field MEANS.")
    print("    And a novel n-gram containing an undecoded word is only a lead if the OTHER")
    print("    members pin it down -- which is what `lut_idiom.py' tested for the C63 idiom and")
    print("    what sect. 195 then showed cannot work while the idiom's first word is unexecuted.")


def show(interesting):
    show(interesting)
    ngrams()
    return 0


def _unused(interesting):
    for name, (a, b) in interesting:
        und, dec = (a, b) if not DIS.decoded(a) else (b, a)
        shared = sorted(where[a] & where[b])
        print("\n  axis %s" % name)
        print("    UNDECODED %09X  open: %s" % (und, ", ".join(AB.open_axes(und)) or "(none)"))
        print("    DECODED   %09X" % dec)
        print("    same KN1500 block: %s" % ("YES, block %s" % shared if shared
                                             else "no -- WEAKER, different programs differ legitimately"))


if __name__ == "__main__":
    sys.exit(main())
