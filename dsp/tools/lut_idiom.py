#!/usr/bin/env python3
"""lut_idiom.py -- the table-lookup idiom and the ALTERNATE lo12 ENCODING, asked with BOTH
products' corpora pooled.

QUESTION IT ANSWERS
    `bit11-family.md' sect. 9 proved -- on the KN5000 alone -- that `lo12' bit 11 selects a SECOND
    lo12 encoding with no SRC and no ACTION field, and closed with sect. 11 item 1: *"The alternate
    `lo12' encoding is the object now.  80 words, 5 shapes ... the question is now `what does the
    alternate form encode'."*  That pass had one product and one shape per question.  The SX-WSA1R
    runs the same ISA (`class_twins.py'), and pooling it doubles the family and -- more usefully --
    supplies MINIMAL PAIRS the KN5000 does not contain (`C62' beside `C63', `F22' beside `822').

    This file asks five things the single-product pass could not, and computes the null or the
    per-category control for each, because a criterion that cannot fail is not a criterion.

USAGE
    python3 dsp/tools/lut_idiom.py                # everything
    python3 dsp/tools/lut_idiom.py --census       # 1. the pooled alternate-encoding census
    python3 dsp/tools/lut_idiom.py --flag         # 2. ★ hi12 bit 6, and the control that can fail
    python3 dsp/tools/lut_idiom.py --idiom        # 3. ★ the C63 idiom, pooled and exceptionless
    python3 dsp/tools/lut_idiom.py --modes        # 4. addr8 by addressing MODE, with mode 0/2 nulls
    python3 dsp/tools/lut_idiom.py --classgate    # 5. what the CLASS TEST alone refuses

WHAT IT ESTABLISHES

  1. THE CENSUS.  187 pooled alternate-encoding words (KN 90 / WSA 97), 24 distinct word shapes,
     11 distinct `lo12'.  The KN5000's 90 reproduce `bit11-family.md' sect. 0 item C's
     distinct-image count exactly (53 `C63' + 24 `8BC' + ... = 80 body sites, plus the 10 header
     and output-stage register-loads).

  2. ★★★ `hi12' BIT 6 IS A THIRD BIT OF THE SAME FLAG -- and it lives in the OTHER HALF of the
     microword, which is where sect. 9 was not looking.  Over the 6441 pooled ESC-clear
     non-C-format words:

         (hi12 bit 6  AND NOT  hi12 bit 5)   <=>   lo12 bit 11        0 exceptions in 6441

     sect. 9.1 had `lo12' bits 11 and 5 co-varying 80 of 80 in one product; this is a bit in `hi12'
     doing the same thing, pooled, and it explains the 14 words that would otherwise be
     counterexamples -- `16E.8.00.000' x12 and `16E.8.00.655' x2, WSA1R-only, which carry bit 6
     WITH bit 5.
     ⚠ THE CONTROL, AND IT DISCRIMINATES.  All 144 plain (hi12 bit, lo12 bit) biconditionals and
     all 1584 masked ones are swept.  SIX masked combinations reach zero exceptions and they are
     the SAME finding six times (bit 6, masked by any of bits 2/3/5 -- all three are set on the
     `16E' words, so the corpus cannot separate them -- against `lo12' bit 5 or 11, which sect. 9.1
     already showed are one flag).  The next-best `hi12' bit misses by 119; the worst pair by 4343.
     ⛔ So the MASK is NOT identified: "bit 6, with the two `16E' shapes excluded" is the honest
     statement, not "bit 6 and not bit 5".

  3. ★★★ THE C63 IDIOM, POOLED: 99 sites, and EVERY ONE is followed by a class-6 word and then a
     class-4 word.  Two further exceptionless couplings the single-product pass could not see:

         C63 hi12 = 040 (f31 = 0, LOAD)  <->  class-6 lo12 4CD        99 of 99
         C63 hi12 = 142 (f31 = 1, ADD)   <->  class-6 lo12 407

     and the class-6 word's `addr8' takes FIVE values in the whole pooled corpus -- 0x18, 0x1A,
     0x1E, 0x20, 0x28 -- with the two products agreeing on all five:

         addr8 = 0x18 = 24   LFO family      KN 29 / WSA 24    <- the PROVEN 24-entry sine
         addr8 = 0x28 = 40   waveshaper      KN 17 / WSA 17    <- ★ so the CLIP CURVE HAS 40 ENTRIES
         addr8 = 0x1A/1E/20  the `407' variant  KN 7 / WSA 5

     `upd6383.cpp's C6LUT arm already reads `addr8' as the entry count, citing sect. 160's
     *"addr8 = 0x18 = 24 at every LFO site"* -- one product, one role.  NEW here: the WAVESHAPER
     half (34 sites, 0x28 = 40), the cross-product replication, and the two couplings.
     ⚠ 24 is the ONE anchored value: `N-DISTORTION-NOT-UNDUMPED-2026-09-12.md' proves the LFO table
     is a 24-entry host-uploaded sine (1 LSB).  40 is read off the same field on the same idiom in
     a second product; it is NOT independently anchored, and no table of 40 entries has been found.

  4. ★★★ THE POINTER-DELTA READING OF `addr8' IS EXCLUDED FOR CLASS 6 -- and with it three of
     `closure_pointer.py's twelve walk variants, on a ground the closure test cannot supply.

     sect. 98 put classes 4, 6 and 8 into that table on this inference: *"`addr8' is NEVER ZERO on
     classes 4, 6 and 8 -- 53 of 53, 53 of 53, 44 of 44 ... So the field is load-bearing there.
     One of the two live readings is that it is the SAME pointer delta classes 2 and A carry."*
     ⛔ "Never zero" licenses "load-bearing"; it does NOT license "pointer delta", and CLASS 6 IS
     THE COUNTEREXAMPLE SITTING INSIDE THE SAME SENTENCE.  Class 6's `addr8' is never zero (99 of
     99 pooled) and is load-bearing -- item 3 shows it is the table ENTRY COUNT, anchored at 24 by
     a table independently proven to have 24 entries.  It is therefore provably NOT a displacement.

     And the walk measures exactly that incoherence.  `closure_pointer.py variants' reports V0
     (baseline) residue +121 and V8 (class 6 post-increments) +177 -- a delta of **+56**, which is
     **24 + 32**, the two class-6 table lengths CHORUS carries at w30 and w34.  So V8 advances the
     D-RAM operand pointer by a sine table's entry count.
     ⇒ V8, V10 and V12 are excluded on the MEANING of the field.  That matters because NO variant
     closes, so the closure criterion by itself excludes nothing.

     WHAT SURVIVES: V7 (class 4 alone; residue +123, 8 -> 10 nets, i.e. exactly the 2 class-4 words
     a frame executes, each +1) and V9 (class 8).  And `addr8' cannot separate V7 from `no move':
     MEASURED pooled, class 4 carries the SINGLE value 0x01 in 99 of 99 words across both products,
     so under the delta reading the field expresses one displacement in eight bits, and under `no
     move' it expresses nothing.  A constant field is uninformative either way.
     ⚠ The 7 words with `addr8 = 0' that share mode 4 are CLASS C, not class 4 -- a different class
     (cursor-fetch set).  Read the mode table below by `class4 & 7'; the per-class split is in
     item 5.
     ⛔ NOT A DECODE and not promoted: mode 4's pointer behaviour stays OPEN, and this narrows the
     field rather than closing it.

  5. ★ WHAT THE CLASS TEST ALONE REFUSES.  139 pooled words in 9 distinct shapes are undecoded
     while `_alu_half_anchored()' already passes -- i.e. the only thing standing between them and
     `decoded()' is `alu_decoded()'s `cl not in (2, 8, 0xA)'.  99 of the 139 are ONE shape,
     `0124011CE', the idiom's third word.  That is the measured size of the sect. 90 / sect. 112 /
     sect. 128 opportunity -- "the class test is what refuses it, and the word's own form explains
     the class" -- and it is the reason item 4's open axis matters.

⛔ WHAT THIS FILE IS NOT.  It decodes nothing and it changes no predicate.  `dsp_disasm.decoded()'
  is untouched.  Items 2 and 3 are ENCODING facts (which bits select the form, which fields are
  coupled); item 3's `40' is a constraint on a table nobody has located; items 4 and 5 are a
  measurement of an open axis and of what closing it would be worth.
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import class_twins as CT                                                  # noqa: E402

KN, WSA = (c[0] for c in CT.CORPORA)

#  `closure_pointer.py --unit0' defaults to this algorithm, so it is the body whose class-6 words
#  the V8 row's residue delta is made of.  Not retyped as a number in the prose below.
CHORUS = 1


def chorus_c6_addr8():
    """The class-6 `addr8' values of the image `closure_pointer.py' walks by default, in order.
    Read from the .dsm tree rather than asserted, so the +56 in item 4 is self-checking."""
    for label, img, slots, ws in CT.images():
        if label != KN or not img.startswith("prog%02d_" % CHORUS):
            continue
        return [DIS.addr8(w) for w in ws
                if not DIS.c_format(w) and DIS.class4(w) == 6]
    return []


def rows():
    """(product, image, slot, word) for the whole pooled corpus."""
    for label, img, slots, ws in CT.images():
        for sl, w in zip(slots, ws):
            yield label, img, sl, w


def by_image():
    return {(l, i): dict(zip(sl, ws)) for l, i, sl, ws in CT.images()}


def alt(w):
    """The alternate-encoding words: `alt_lo12()' with the format escape CLEAR.  The ESC-set
    members are the register-load family, whose `lo12' is selector + flag for a DIFFERENT reason
    (k3-pointers.md item A, PROVEN BY CONSTRUCTION)."""
    return DIS.alt_lo12(w) and not (DIS.hi12(w) & DIS.HI_ESC)


# ---------------------------------------------------------------- 1. census
def show_census():
    rs = [r for r in rows() if DIS.alt_lo12(r[3])]
    kn = sum(1 for r in rs if r[0] == KN)
    print("\n   ★ POOLED ALTERNATE-ENCODING CENSUS -- %d words (KN5000 %d / SX-WSA1R %d)\n"
          % (len(rs), kn, len(rs) - kn))
    print("      %-10s %-4s %-2s %-4s %-4s %-3s %-4s %6s %6s %6s  %s"
          % ("word", "hi12", "c4", "ad8", "lo12", "ESC", "f31", "KN", "WSA", "total", "images"))
    c = collections.Counter(r[3] for r in rs)
    for w, n in sorted(c.items(), key=lambda kv: (-kv[1], kv[0])):
        sub = [r for r in rs if r[3] == w]
        k = sum(1 for r in sub if r[0] == KN)
        hi = DIS.hi12(w)
        print("      %09X  %03X  %X  %02X   %03X  %-3s %-4d %6d %6d %6d  %d"
              % (w, hi, DIS.class4(w), DIS.addr8(w), DIS.lo12(w),
                 "Y" if hi & DIS.HI_ESC else ".", DIS.hi_f31(hi),
                 k, n - k, n, len({(r[0], r[1]) for r in sub})))
    e0 = [r for r in rs if not (DIS.hi12(r[3]) & DIS.HI_ESC)]
    z = sum(1 for r in e0 if DIS.addr8(r[3]) == 0)
    print("\n      ★ every ESC-clear alternate word carries addr8 == 0 and class4 == 0: %d of %d"
          % (z, len(e0)))
    non = [r for r in rows() if not DIS.c_format(r[3])]
    nn = [r for r in non if not DIS.alt_lo12(r[3]) and not (DIS.hi12(r[3]) & DIS.HI_ESC)]
    nz = sum(1 for r in nn if DIS.addr8(r[3]) == 0)
    print("        NULL -- the same rate among ESC-clear words that are NOT alternate: %d/%d = %.1f %%"
          % (nz, len(nn), 100.0 * nz / max(1, len(nn))))
    print("        ⇒ the family has no addr8 field; the base rate says that is not automatic.")


# ------------------------------------------------------------------ 2. flag
def show_flag():
    pop = [r[3] for r in rows()
           if not DIS.c_format(r[3]) and not (DIS.hi12(r[3]) & DIS.HI_ESC)]
    n = len(pop)
    print("\n   ★★★ `hi12' BIT 6 -- A THIRD BIT OF THE ALTERNATE-ENCODING FLAG\n")
    print("      population: %d pooled ESC-clear non-C-format words\n" % n)
    t = collections.Counter()
    for w in pop:
        hi = DIS.hi12(w)
        t[(bool(hi & 0x40) and not (hi & 0x20), bool(DIS.lo12(w) & 0x800))] += 1
    print("      (hi12 bit 6 AND NOT bit 5)      lo12 bit11 SET   lo12 bit11 CLEAR")
    print("         TRUE                         %10d   %14d" % (t[(True, True)], t[(True, False)]))
    print("         FALSE                        %10d   %14d" % (t[(False, True)], t[(False, False)]))
    print("      ⇒ EXCEPTIONS: %d of %d" % (t[(True, False)] + t[(False, True)], n))

    print("\n      ⚠ THE CONTROL -- the same test on every other bit pair, so it CAN fail:\n")
    plain = []
    for hb in range(12):
        for lb in range(12):
            ex = sum(1 for w in pop if bool(DIS.hi12(w) >> hb & 1) != bool(DIS.lo12(w) >> lb & 1))
            plain.append((ex, hb, lb))
    plain.sort()
    print("        plain hi12[b] <=> lo12[b'], all 144 pairs -- fewest exceptions first:")
    for ex, hb, lb in plain[:4]:
        print("           hi12 bit %-2d <=> lo12 bit %-2d   exceptions %5d" % (hb, lb, ex))
    print("           ... worst pair: %d exceptions" % plain[-1][0])
    zero = []
    for hb in range(12):
        for hb2 in range(12):
            if hb2 == hb:
                continue
            for lb in range(12):
                ex = sum(1 for w in pop
                         if (bool(DIS.hi12(w) >> hb & 1) and not (DIS.hi12(w) >> hb2 & 1))
                         != bool(DIS.lo12(w) >> lb & 1))
                if ex == 0:
                    zero.append((hb, hb2, lb))
    print("\n        masked (hi12[b] AND NOT hi12[b2]) <=> lo12[b'], all 1584 combos:")
    print("           combos with ZERO exceptions: %d of 1584" % len(zero))
    for hb, hb2, lb in zero:
        print("             hi12 bit %d AND NOT bit %d  <=>  lo12 bit %d" % (hb, hb2, lb))
    print("        ⛔ the MASK is not identified -- bits 2, 3 and 5 are all set on the two `16E'")
    print("           shapes, so the corpus cannot tell them apart, and `lo12' bits 5 and 11 are")
    print("           one flag already (bit11-family sect. 9.1).  Honest form: `hi12' bit 6 agrees")
    print("           with `lo12' bit 11 on %d of %d words, the exceptions being TWO shapes."
          % (n - 14, n))

    ex14 = [r for r in rows()
            if not DIS.c_format(r[3]) and not (DIS.hi12(r[3]) & DIS.HI_ESC)
            and (DIS.hi12(r[3]) & 0x40) and not (DIS.lo12(r[3]) & 0x800)]
    print("\n      the exceptions, in full (%d words, %d shapes -- SX-WSA1R only):"
          % (len(ex14), len({r[3] for r in ex14})))
    for w, k in collections.Counter(r[3] for r in ex14).most_common():
        print("         %09X x%-3d  hi12=%03X (bits 2,3,5 all SET)  images: %s"
              % (w, k, DIS.hi12(w),
                 " ".join(sorted({r[1][:20] for r in ex14 if r[3] == w}))[:60]))


# ----------------------------------------------------------------- 3. idiom
def idiom_sites():
    imgs = by_image()
    out = []
    for (l, i), d in sorted(imgs.items()):
        for s, w in sorted(d.items()):
            if alt(w) and DIS.lo12(w) == 0xC63 and (s + 1) in d and (s + 2) in d:
                out.append((l, i, s, w, d[s + 1], d[s + 2]))
    return out


def show_idiom():
    sites = idiom_sites()
    kn = sum(1 for r in sites if r[0] == KN)
    print("\n   ★★★ THE C63 TABLE-LOOKUP IDIOM, POOLED -- %d sites (KN %d / WSA %d)\n"
          % (len(sites), kn, len(sites) - kn))
    shape = collections.Counter(((DIS.class4(r[4]) & 7), (DIS.class4(r[5]) & 7)) for r in sites)
    print("      the two words that FOLLOW every C63, by addressing mode:")
    for k, n in shape.most_common():
        print("         mode %d then mode %d : %d of %d" % (k[0], k[1], n, len(sites)))
    ok = sum(1 for r in sites if (DIS.hi12(r[3]) == 0x040) == (DIS.lo12(r[4]) == 0x4CD))
    print("\n      ★ HEAD f31 <-> class-6 `lo12', exceptionless:  %d of %d" % (ok, len(sites)))
    print("         hi12 040 (f31 = 0 LOAD) <-> class-6 lo12 4CD")
    print("         hi12 142 (f31 = 1 ADD)  <-> class-6 lo12 407")
    print("\n      ★ the class-6 word's `addr8' -- the ENTRY COUNT the C6LUT arm already uses:\n")
    print("         %-12s %-8s %6s %6s %7s   role" % ("addr8", "c6 lo12", "KN", "WSA", "images"))
    agg = collections.defaultdict(lambda: [0, 0, set()])
    for l, i, s, w, n1, n2 in sites:
        a = agg[(DIS.addr8(n1), DIS.lo12(n1))]
        a[0 if l == KN else 1] += 1
        a[2].add((l, i))
    ROLE = {0x18: "★ the PROVEN 24-entry LFO sine (N-DISTORTION, 1 LSB)",
            0x28: "★ the WAVESHAPER -- so the clip curve has 40 entries",
            0x1A: "the `407' variant", 0x1E: "the `407' variant", 0x20: "the `407' variant"}
    for (tt, lo), (k, ws_, im) in sorted(agg.items()):
        print("         0x%02X = %-5d %-8s %6d %6d %7d   %s"
              % (tt, tt, "%03X" % lo, k, ws_, len(im), ROLE.get(tt, "")))
    print("\n      ⇒ FIVE values in the whole pooled corpus, and the two products agree on all five.")
    print("      ⚠ 24 is the one ANCHORED value.  40 is read off the same field of the same idiom")
    print("        in a second product; no 40-entry table has been located, and C-RAM cell 0x28 is")
    print("        written by NEITHER the preset streams NOR the boot blob (0x50..0x8B) -- so")
    print("        `addr8' is a COUNT, not a C-RAM address, which is what the C6LUT arm assumes.")


# ----------------------------------------------------------------- 4. modes
def show_modes():
    non = [r[3] for r in rows() if not DIS.c_format(r[3])]
    print("\n   ★ `addr8' BY ADDRESSING MODE (class4 & 7), pooled -- with the two PROVEN modes")
    print("     as the null: mode 2 post-increments by s8(addr8); mode 0 does not move.\n")
    print("      %-5s %6s %14s %12s %9s  %s"
          % ("mode", "n", "addr8 == 0", "|d| <= 8", "distinct", "most common"))
    for md in range(8):
        sub = [w for w in non if (DIS.class4(w) & 7) == md]
        if not sub:
            continue
        a = [DIS.addr8(w) for w in sub]
        s8 = [abs(x - 256 if x >= 128 else x) for x in a]
        c = collections.Counter(a)
        print("      %-5d %6d %8d %4.0f%% %8d %3.0f%% %9d  %s"
              % (md, len(sub), sum(1 for x in a if x == 0),
                 100.0 * sum(1 for x in a if x == 0) / len(sub),
                 sum(1 for x in s8 if x <= 8), 100.0 * sum(1 for x in s8 if x <= 8) / len(sub),
                 len(c), " ".join("%02X:%d" % kv for kv in c.most_common(4))))
    print("\n      per EXACT class4 (the mode rows above merge class 4 with C, and 6 with E):\n")
    for cl in (0x3, 0x4, 0x5, 0x6, 0x8, 0xC, 0xD):
        sub = [(l, w) for l, i, s, w in rows() if not DIS.c_format(w) and DIS.class4(w) == cl]
        if not sub:
            continue
        k = sum(1 for l, w in sub if l == KN)
        c = collections.Counter(DIS.addr8(w) for l, w in sub)
        print("        class %X: %4d words (KN %3d / WSA %3d)  addr8==0: %-3d  values: %s"
              % (cl, len(sub), k, len(sub) - k, c.get(0, 0),
                 " ".join("%02X:%d" % kv for kv in c.most_common(6))))

    print("\n      ★★★ THE POINTER-DELTA READING IS EXCLUDED FOR CLASS 6.")
    print("        sect. 98 put classes 4/6/8 into `closure_pointer.py's variant table because")
    print("        `addr8' is never zero on them, hence `load-bearing', hence possibly the same")
    print("        delta classes 2 and A carry.  Class 6 refutes the last step from inside: its")
    print("        `addr8' is never zero AND load-bearing AND provably not a displacement -- it is")
    print("        the table ENTRY COUNT, anchored at 24 (item 3).")
    print("        MEASURED in `closure_pointer.py variants': V0 residue +121, V8 (class 6 moves)")
    print("        +177 -- a delta of +56.  Not an arithmetic coincidence: it is read off the")
    print("        walked image.  `closure_pointer.py' walks algo %d at I-RAM 84 by default," % CHORUS)
    tts = chorus_c6_addr8()
    if tts:
        print("        and that image's class-6 words carry addr8 = %s, summing to %d."
              % (" and ".join(str(t) for t in tts), sum(tts)))
    print("        ⇒ V8, V10 and V12 advance the D-RAM pointer by a sine table's length.  Excluded")
    print("          on the MEANING of the field -- which the closure test cannot do, since NO")
    print("          variant closes and so closure by itself excludes nothing.")
    print("\n      ⛔ STILL OPEN: V7 (class 4 alone, residue +123, 8 -> 10 nets) and V9 (class 8).")
    print("        `addr8' cannot separate V7 from `no move': class 4 carries the SINGLE value")
    print("        0x01 in 99 of 99 words in BOTH products, so the field expresses one")
    print("        displacement in eight bits under one reading and nothing under the other.")


# ------------------------------------------------------------- 5. class gate
def show_classgate():
    non = [w for l, i, s, w in rows() if not DIS.c_format(w)]
    t = collections.defaultdict(lambda: [0, 0, 0])
    for w in non:
        cl = DIS.class4(w)
        d = DIS.decoded(w)
        t[cl][0 if d else 1] += 1
        if not d and DIS._alu_half_anchored(w):
            t[cl][2] += 1
    print("\n   ★ WHAT THE CLASS TEST ALONE REFUSES\n")
    print("      %-6s %8s %10s   %s" % ("class", "decoded", "undecoded", "of which ALU-HALF ANCHORED"))
    for cl in sorted(t):
        d, u, a = t[cl]
        print("      0x%X    %8d %10d   %6d%s" % (cl, d, u, a, "   <- ★" if a >= 12 else ""))
    sh = collections.Counter(w for w in non if not DIS.decoded(w) and DIS._alu_half_anchored(w))
    tot = sum(sh.values())
    print("\n      ⇒ %d pooled words in %d distinct shapes are undecoded with an ANCHORED ALU half."
          % (tot, len(sh)))
    print("        The only thing refusing them is `alu_decoded()'s `cl not in (2, 8, 0xA)'.\n")
    for w, n in sh.most_common():
        print("         %09X x%-4d cl=%X ad8=%02X SRC %02X ACT %02X f31=%d%s"
              % (w, n, DIS.class4(w), DIS.addr8(w), DIS.lo_src(w), DIS.lo_act(w),
                 DIS.hi_f31(DIS.hi12(w)),
                 "   <- the idiom's third word" if w == 0x124011CE else ""))
    print("\n      ⛔ NOT PROMOTED: `decoded()' is unchanged.  sect. 112's standard is `the")
    print("        ADDRESSING is explained AND the ALU half is anchored', and for mode 4 the")
    print("        addressing has the open axis item 4 measures.")


def main():
    argv = sys.argv[1:]
    allof = not argv or "--all" in argv
    print("=" * 100)
    print("  lut_idiom -- the alternate lo12 encoding and the table-lookup idiom, pooled")
    print("=" * 100)
    if allof or "--census" in argv:
        show_census()
    if allof or "--flag" in argv:
        show_flag()
    if allof or "--idiom" in argv:
        show_idiom()
    if allof or "--modes" in argv:
        show_modes()
    if allof or "--classgate" in argv:
        show_classgate()
    return 0


if __name__ == "__main__":
    sys.exit(main())
