#!/usr/bin/env python3
"""cfmt_opcode.py -- the C-format OPCODE field, asked with BOTH products' corpora pooled.

QUESTION IT ANSWERS
    N-INPUT-GATE-OPENED sect. 120 localised the LFO rate defect AND the audio input path to **one
    word** -- kernel `iw40 = 0C4A1C0820' -- and asked *"what does `w40' DRIVE `P' with?"*.  The
    word is C-format, `lo12 = 0x820` (register selector `0x20`, `register-space.md' item B3), and
    carries **C-format opcode 0x625**.

    `output-stage-decode.md' item K is the reason the opcode is worth asking about at all:

        *"The C-FORMAT word has an OPCODE, and the tree has never rendered it.  `bits[35:25]';
        eight distinct values over the 68 C-format words.  `is_c40()' -- the payload rule
        `(hi12 & 0xFFE) == 0xC40' -- IS exactly `opcode == 0x620' ... And the five `lo12 = 0x820'
        words are NOT a family: they carry FOUR different opcodes and share only a destination."*

    ⇒ so the five words `closure-pointer.md' item H searched as one family are FOUR instructions
    writing ONE register, and sect. 120 says only ONE of them touches `P'.  If the opcode is what
    separates them, the opcode census is the first thing to look at -- and the KN5000's 68
    C-format words are a thin sample for an 11-bit field.  The SX-WSA1R runs the same ISA
    (`class_twins.py') and adds its own.

USAGE
    python3 dsp/tools/cfmt_opcode.py              # the pooled opcode census + the 0x820 five
    python3 dsp/tools/cfmt_opcode.py --twins      # minimal pairs across the opcode field
    python3 dsp/tools/cfmt_opcode.py --control    # ★ the control, run it before believing a row

WHAT IT MEASURES
    1. Every distinct C-format opcode, its count in each product, and which `lo12' destinations it
       is seen with.  A destination that takes SEVERAL opcodes is where the opcode is doing work.
    2. The five `lo12 = 0x820' words side by side, with `iw40' marked.
    3. `--twins': (lo12, addr8, class4, and every `hi12' bit BELOW the opcode) held fixed, opcode
       varying.  That is the same instrument `class_twins.py' pointed at `class4' and at bit 7.
    4. ★ `--control': the census run against a field that is KNOWN not to be the opcode -- the
       `imm13' payload, whose value is the instruction's data.  If the "several opcodes per
       destination" shape shows up there too, the shape is an artefact of the corpus and not
       evidence about the opcode.  A criterion that cannot fail is not a criterion (rule 15).

⚠ WHAT THIS IS NOT.  It decodes nothing.  It reports which C-format opcodes exist, how they are
  distributed, and whether the pooled ROM offers a minimal pair on that field.  Every conclusion
  drawn from it has to be made to fire in the emulator before it is worth anything -- sect. 100's
  three runs and sect. 97's swallow census are what that costs.
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import class_twins as CT                                                  # noqa: E402

#  The kernel slots of the five `lo12 = 0x820' words (closure-pointer.md sect. 8).
FIVE = (15, 22, 29, 31, 40)
#  sect. 120: clearing the one-slot product at THIS slot, and at no other kernel C-format slot,
#  fixes the chorus LFO to the ROM's 114/frame and empties the hand-off cell 0x05.
SECT120 = 40


def cwords():
    """Yield (product, image, slot, word) for every C-format word in the pooled corpus."""
    for label, img, slots, ws in CT.images():
        for sl, w in zip(slots, ws):
            if DIS.c_format(w):
                yield label, img, sl, w


def census():
    per = collections.defaultdict(lambda: collections.Counter())
    dest = collections.defaultdict(collections.Counter)
    for label, img, sl, w in cwords():
        op = DIS.c_opcode(w)
        per[op][label] += 1
        dest[op][DIS.lo12(w)] += 1
    return per, dest


def show_census():
    per, dest = census()
    tot = sum(sum(c.values()) for c in per.values())
    print("   ★ POOLED C-FORMAT OPCODE CENSUS -- %d words, %d distinct opcodes\n"
          % (tot, len(per)))
    print("      %-7s %6s %6s %6s   %s" % ("opcode", "KN5000", "WSA1R", "total", "lo12 destinations"))
    for op in sorted(per):
        c = per[op]
        d = dest[op]
        tag = "  <- is_c40 (the payload rule)" if op == 0x620 else ""
        print("      0x%03X   %6d %6d %6d   %s%s"
              % (op, c.get("KN5000", 0), c.get("WSA1R", 0), sum(c.values()),
                 " ".join("%03X x%d" % (k, v) for k, v in sorted(d.items())), tag))

    #  ---- which destinations take MORE THAN ONE opcode --------------------
    bydest = collections.defaultdict(collections.Counter)
    for op, d in dest.items():
        for lo, n in d.items():
            bydest[lo][op] += n
    multi = {lo: ops for lo, ops in bydest.items() if len(ops) > 1}
    print("\n   ★ DESTINATIONS TAKING MORE THAN ONE OPCODE -- where the opcode does work\n")
    for lo in sorted(multi):
        ops = multi[lo]
        print("      lo12 %03X   %d opcodes:  %s"
              % (lo, len(ops), "  ".join("0x%03X x%d" % (o, n) for o, n in sorted(ops.items()))))
    if not multi:
        print("      NONE -- every destination takes exactly one opcode, so the two fields are")
        print("      not separable in this corpus and no row above is evidence about the opcode.")
    return multi


def show_five():
    print("\n   ★ THE FIVE `lo12 = 0x820' WORDS -- four opcodes, one destination"
          " (output-stage-decode item K)\n")
    seen = []
    for label, img, sl, w in cwords():
        if DIS.lo12(w) == 0x820:
            seen.append((label, img, sl, w))
    kern = [r for r in seen if r[2] in FIVE and r[0] == "KN5000"]
    shown = set()
    for label, img, sl, w in sorted(kern, key=lambda r: r[2]):
        if sl in shown:
            continue
        shown.add(sl)
        mark = "  ★★★ sect. 120: THE ONE" if sl == SECT120 else ""
        print("      iw%-3d %010X  opcode 0x%03X  A=%-3d B=%-3d imm13=%-5d class %X  addr8 %02X%s"
              % (sl, w, DIS.c_opcode(w), DIS.c_a(w), DIS.c_b(w), DIS.c_imm13(w),
                 DIS.class4(w), DIS.addr8(w), mark))
    other = [r for r in seen if r[0] != "KN5000" or r[2] not in FIVE]
    print("\n      elsewhere in the pooled corpus: %d more `lo12 = 0x820' words" % len(other))
    for label, img, sl, w in sorted(other)[:12]:
        print("        %-7s %-28s iw%-3d %010X  opcode 0x%03X"
              % (label, img, sl, w, DIS.c_opcode(w)))
    #  ★ the question sect. 120 asks: is iw40's opcode UNIQUE, or does the pool repeat it?
    op40 = [(l, i, s, w) for l, i, s, w in cwords() if DIS.c_opcode(w) == 0x625]
    print("\n   ★★ EVERY OCCURRENCE OF `iw40's OPCODE 0x625 IN EITHER PRODUCT: %d\n" % len(op40))
    for label, img, sl, w in sorted(op40)[:24]:
        print("        %-7s %-28s iw%-3d %010X  lo12 %03X  imm13 %d"
              % (label, img, sl, w, DIS.lo12(w), DIS.c_imm13(w)))
    if len({(w, DIS.lo12(w)) for _, _, _, w in op40}) == 1:
        print("\n      ⇒ ONE distinct word.  The opcode and the destination cannot be separated")
        print("        for 0x625 in this corpus: every occurrence is the same 36 bits.")


def show_twins():
    """(lo12, addr8, class4, hi12 below the opcode) fixed; opcode varying."""
    #  the C-format opcode is bits[35:25] = hi12[11:1] together with class4 and addr8's top bits;
    #  the honest key is therefore "the whole word EXCEPT the opcode bits".
    key = collections.defaultdict(set)
    where = collections.defaultdict(list)
    for label, img, sl, w in cwords():
        k = w & ~(0x7FF << 25)
        key[k].add(DIS.c_opcode(w))
        where[(k, DIS.c_opcode(w))].append((label, img, sl))
    pairs = {k: v for k, v in key.items() if len(v) > 1}
    print("\n   ★ MINIMAL PAIRS ACROSS THE C-FORMAT OPCODE -- everything else in the 36-bit word"
          " identical\n")
    if not pairs:
        print("      NONE in the pooled corpus.  The opcode never varies with the rest of the word")
        print("      held fixed, so there is no twin to read it off -- which is itself the answer")
        print("      to `is the twin method available here': it is NOT, unlike class4 and bit 7.")
        return 0
    for k in sorted(pairs):
        ops = sorted(pairs[k])
        print("      rest %010X   opcodes %s" % (k, " ".join("0x%03X" % o for o in ops)))
        for o in ops:
            w = k | (o << 25)
            sites = where[(k, o)]
            print("        0x%03X  %010X  x%-3d  %s  %s"
                  % (o, w, len(sites), "DECODED" if DIS.decoded(w) else "traps  ",
                     ", ".join("%s/%s@%d" % s for s in sites[:3])))
    return len(pairs)


def show_control():
    """The control: the same 'several values per destination' shape, measured on a field that is
    KNOWN to be data.  If it appears there too, the census shape is an artefact."""
    print("\n   ★ CONTROL (rule 15) -- the same shape measured on the IMM13 PAYLOAD, which is data\n")
    bydest = collections.defaultdict(collections.Counter)
    for label, img, sl, w in cwords():
        bydest[DIS.lo12(w)][DIS.c_imm13(w)] += 1
    multi = {lo: v for lo, v in bydest.items() if len(v) > 1}
    print("      destinations taking more than one IMM13 value: %d of %d"
          % (len(multi), len(bydest)))
    print("      ⇒ a destination taking several values of a field is the NULL, not a finding.")
    print("        What separates the opcode census from this control is that the payload is")
    print("        expected to vary and the opcode is not -- so the row that matters is the one")
    print("        where a destination takes several OPCODES with the SAME payload.\n")
    same = collections.defaultdict(set)
    for label, img, sl, w in cwords():
        same[(DIS.lo12(w), DIS.c_imm13(w))].add(DIS.c_opcode(w))
    hits = {k: v for k, v in same.items() if len(v) > 1}
    print("      (lo12, imm13) pairs seen with MORE THAN ONE opcode: %d" % len(hits))
    for k in sorted(hits):
        print("        lo12 %03X imm13 %-5d  opcodes %s"
              % (k[0], k[1], " ".join("0x%03X" % o for o in sorted(hits[k]))))
    if not hits:
        print("        NONE.  ⇒ in this corpus the opcode is a FUNCTION of (destination, payload),")
        print("        and no measurement here can separate it from them.  That is a null with")
        print("        power: it says the static corpus cannot answer sect. 120's question, and")
        print("        the answer has to come from the machine.")
    return hits


def main():
    print("=" * 100)
    print("  cfmt_opcode -- the C-format opcode field, pooled over KN5000 + SX-WSA1R")
    print("=" * 100 + "\n")
    show_census()
    show_five()
    if "--twins" in sys.argv or "--all" in sys.argv:
        show_twins()
    if "--control" in sys.argv or "--all" in sys.argv:
        show_control()
    return 0


if __name__ == "__main__":
    sys.exit(main())
