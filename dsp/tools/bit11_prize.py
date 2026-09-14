#!/usr/bin/env python3
"""bit11_prize.py -- how much coverage is the bit-11 alternate encoding worth?

QUESTION IT ANSWERS
    sect. 195 retargeted the class-6 work: the C63 idiom's index is computed by `C63' itself, a
    word carrying `lo12' bit 11, and the device executes NOTHING for such a word -- sect. 97's
    swallow census counts `lo12 C63' leaving `exec_alu()' 3 150 504 times in one chorus run with
    no SOURCE and no ACTION decode.  Six index arms failed because the producer is not modelled.

    So before anyone builds a seventh arm, or a decoder for one alternate opcode: HOW BIG IS THE
    FAMILY, and how much of the undecoded corpus does it actually gate?  This counts it, pooled
    over both products and RULE-9 de-duplicated, and splits the answer three ways:

      A  words that ARE bit-11 words                      -- the family itself
      B  undecoded words whose only open axes are closed by class 6 / SRC 0x13
         (sect. 177's +90), which bit-11 gates INDIRECTLY through the idiom
      C  the `lo12' shapes the family actually uses, with occurrence counts, so the next pass
         attacks the shapes that pay rather than the one that happens to be in front of it

USAGE
    python3 dsp/tools/bit11_prize.py

WHAT IT IS NOT
    It does not decode anything.  It is a SIZING tool: the output is an upper bound on what
    closing the family could buy, and the per-shape table is the work queue.

    (RULE 9: rates are quoted over DISTINCT images.  The SX-WSA1R tree carries byte-identical
    duplicates -- 60 records, 52 distinct -- and they are reverbs, better decoded than average,
    so counting them inflates every figure.)
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import class_twins as CT                                                  # noqa: E402


def distinct_words():
    """Every word of every DISTINCT image, with its product label.  RULE 9."""
    seen, out = set(), []
    for label, img, _slots, ws in CT.images():
        k = (label, tuple(ws))
        if k in seen:
            continue
        seen.add(k)
        out.extend((label, w) for w in ws)
    return out


def main():
    words = distinct_words()
    tot = len(words)
    und = [(l, w) for l, w in words if not DIS.decoded(w)]

    #  A -- the family itself.  `lo12' bit 11 is the alternate-encoding flag (bit11-family.md
    #  sect. 9): such a word has NO SRC and NO ACTION field, which is why the device swallows it.
    fam = [(l, w) for l, w in words if (w & 0xfff) & 0x800]
    fam_und = [(l, w) for l, w in fam if not DIS.decoded(w)]

    print("=" * 92)
    print("  bit11_prize -- how much is the alternate encoding worth?  (RULE 9 de-duplicated)")
    print("=" * 92)
    print("\n  pooled DISTINCT corpus: %d words, %d undecoded (%.1f %% decoded)"
          % (tot, len(und), 100.0 * (tot - len(und)) / tot))
    print("\n  A  bit-11 words (lo12 bit 11 set): %d total, %d UNDECODED"
          % (len(fam), len(fam_und)))
    if fam:
        print("     closing the family outright would move coverage %.1f %% -> %.1f %%"
              % (100.0 * (tot - len(und)) / tot,
                 100.0 * (tot - len(und) + len(fam_und)) / tot))

    #  C -- the shapes, so the queue is ranked by what pays.
    sh = collections.Counter()
    shu = collections.Counter()
    per_prod = collections.defaultdict(collections.Counter)
    for l, w in fam:
        s = w & 0xfff
        sh[s] += 1
        per_prod[s][l] += 1
        if not DIS.decoded(w):
            shu[s] += 1
    print("\n  C  the shapes the family uses, ranked by UNDECODED occurrences:\n")
    print("     lo12   total  undec   by product")
    cum = 0
    for s, _n in sorted(sh.items(), key=lambda kv: -shu[kv[0]]):
        if not shu[s]:
            continue
        cum += shu[s]
        by = " ".join("%s:%d" % (k, v) for k, v in sorted(per_prod[s].items()))
        print("     %03X  %6d %6d   %s" % (s, sh[s], shu[s], by))
    print("\n     %d undecoded occurrences over %d distinct shapes"
          % (cum, sum(1 for s in shu if shu[s])))

    #  B -- what the family gates INDIRECTLY.  The C63 idiom's class-6 word is not itself a
    #  bit-11 word, but sect. 195 shows its index comes from one, so those words cannot be
    #  decoded until the family is.  Count them the way sect. 177 did: undecoded words whose
    #  open axes are exactly the class-6 pair.
    #  ⚠ `open_axes()' takes the WORD AS AN INT.  v1 passed "%09X" % w and wrapped the call in a
    #  bare `except: continue', so every call raised, every counter stayed 0, and B printed a
    #  confident "0" over an empty table.  That is `cfmt_opcode.py' sect. 0's defect exactly -- a
    #  column of zeros looks like a real absence.  No try/except here: if it breaks, it shouts.
    import acc_blind as AB
    gated = 0
    axes = collections.Counter()
    for _l, w in und:
        a = tuple(sorted(AB.open_axes(w)))
        axes[a] += 1
        if a and all(("class 6" in x) or ("0x13" in x) for x in a):
            gated += 1
    assert sum(axes.values()) == len(und), "open_axes() skipped words -- do not read the table"
    print("\n  B  undecoded words whose every open axis is a class-6 / SRC-0x13 one: %d" % gated)
    print("     (sect. 177 counted 90 of these; they are gated by the family INDIRECTLY --")
    print("      the class-6 word is decodable only once its index producer executes)")
    print("\n     the commonest open-axis sets among ALL %d undecoded words:" % len(und))
    for a, n in axes.most_common(10):
        print("       %4d  %s" % (n, ", ".join(a) if a else "(none -- check decoded())"))

    #  D -- DO THESE WORDS CARRY AN OPERAND?  A bit-11 word has no SRC and no ACTION field, so
    #  what is left is `hi12', `class4' and `addr8'.  If a shape's full 36-bit word is IDENTICAL
    #  everywhere it occurs, it is a bare opcode and its meaning has to come from CONTEXT; if the
    #  other fields vary, they are its operand and the variation is the thing to explain.  This is
    #  the cheapest question in the family and it decides how the next pass is even shaped.
    print("\n  D  do the family's words carry an OPERAND?  (fields outside lo12, per shape)\n")
    print("     lo12   distinct full words   varying fields")
    byshape = collections.defaultdict(collections.Counter)
    for _l, w in fam:
        byshape[w & 0xfff][w] += 1
    for sp in sorted(byshape, key=lambda x: -shu[x]):
        forms = byshape[sp]
        his = {(w >> 24) & 0xfff for w in forms}
        cls = {(w >> 20) & 0xf for w in forms}
        ads = {(w >> 12) & 0xff for w in forms}
        vary = []
        if len(his) > 1:
            vary.append("hi12(%d)" % len(his))
        if len(cls) > 1:
            vary.append("class4(%d)" % len(cls))
        if len(ads) > 1:
            vary.append("addr8(%d)" % len(ads))
        print("     %03X   %-19d %s" % (sp, len(forms),
              ", ".join(vary) if vary else "NONE -- a bare opcode, meaning comes from context"))
        for w, n in forms.most_common(4):
            print("            %09X x%-4d  hi12=%03X class4=%X addr8=%02X"
                  % (w, n, (w >> 24) & 0xfff, (w >> 20) & 0xf, (w >> 12) & 0xff))

    print("\n  ⇒ A + B is the upper bound on what the bit-11 pass can buy.  Neither number is a")
    print("    promise: a shape still has to be DECODED, and sect. 195 only says where to look.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
