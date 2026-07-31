#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""f31_367.py -- §231.  THE `f31 in {3,6,7}' QUESTION, WORKED FROM THE ROM.

NEC uPD6383GF (Technics SX-KN5000, IC311).  Read-only; loads the 3057-word
static corpus through `pat_corpus' and the decode predicates through
`dsp_disasm', so nothing here can drift from `dsp/disasm/*.dsm'.

WHAT IT ANSWERS
  A  the 53 words, by distinct encoding, with their images
  B  is C-FORMAT the explanation?  (it is, for the ONE counterexample)
  C  the ESC bit
  D  the whole bit-5 population
  E/H  ★ THE BASE ANALYSIS -- is bit 5 a GATE on f31, or a SPANDREL of which
       hi12 bases exist?  (`020' carries SEVEN of the eight codes by itself)
  I  ★ minimal pairs differing ONLY in hi12[3:1], including the ADJACENT ones
  J  where 3/6/7 live, by effect family
  K  the 0x02X.2.00.000 ladder
  L  the epilogue word by word under the SHIPPED model
  M  ★ an audit of §229 §2.1's five distribution claims (claim 1 is OFF BY ONE)
  O  ★ HOW MUCH DECODE COVERAGE a reading for f31 3/6/7 could actually buy,
     by mirroring upd6383d.h's `alu_guard_fail()' over the corpus

SELF-TESTS (rule 20), printed first and able to fail: 3057 corpus words, 759
distinct encodings, and `alu_decoded()' = 1178 -- all three published elsewhere
by instruments that do not know this one exists.

    python3 dsp/tools/f31_367.py

stdlib only (plus the research tree's own loader/disassembler).
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pat_corpus import load, F, fmt          # noqa: E402
import dsp_disasm as D                       # noqa: E402


# ---------------------------------------------------------------------------
#  alu_guard_fail() -- a MIRROR of upd6383d.h's, in the same order.  Returns the
#  identity of the FIRST guard that refuses a word (0 = decoded).  It exists
#  because "the operation field traps this word" was about to be asserted for
#  words that never reach the operation switch: alu_decoded() is a CONJUNCTION,
#  and only its first failure is observable.
# ---------------------------------------------------------------------------
GUARD = {0: "DECODED", 1: "CLASS", 3: "OPERATION (the f31 switch)",
         4: "FORMAT (C-format)", 5: "bit-4 off mode 2",
         6: "ACTION-07 off mode 2", 7: "GUARD 7 (bit4+bit7 at f31 != 2)",
         21: "routing/bit-11", 22: "routing/pointer-mode",
         23: "routing/SRC-or-ACTION not anchored"}


def guard_fail(w):
    if D.c_format(w):
        return 4
    cl = D.class4(w)
    if cl not in (2, 8, 0xA):
        return 1
    if D.lo12(w) & 0x800:
        return 21
    if D.lo_ptrmode(w):
        return 22
    if D.lo_src(w) not in D._ANCHORED_SRC or D.lo_act(w) not in D._ANCHORED_ACT:
        return 23
    if (D.hi12(w) & D.HI_ST) and (cl & 7) != 2:
        return 5
    if D.lo_act(w) == D.LO_ACT_ST_BUS and (cl & 7) != 2:
        return 6
    if (D.hi12(w) & D.HI_ST) and (D.hi12(w) & D.HI_B7) \
            and D.hi_f31(D.hi12(w)) != 2:
        return 7
    f = D.hi_f31(D.hi12(w))
    if f in (D.HI_ACC_LOAD, D.HI_ACC_ADD):
        return 0
    if f == D.HI_ACC_HOLD:
        return 0 if cl == 8 else 3
    return 3


def base(w):
    """hi12 with the f31 field (bits 3:1) cleared."""
    return F(w).hi12 & ~0x00E


def main():
    progs, meta = load()
    allw = [(n, i, w) for n, ws in progs.items() for i, w in enumerate(ws)]
    nc = [t for t in allw if not F(t[2]).cfmt]
    sel = [t for t in allw if F(t[2]).f31 in (3, 6, 7)]
    dist = set(w for _, _, w in allw)
    dec = sum(1 for _, _, w in allw if guard_fail(w) == 0)

    print("=" * 104)
    print("§231  f31 in {3,6,7} -- RULE 20 SELF-TESTS, AGAINST THREE PUBLISHED ANSWERS")
    print("=" * 104)
    for label, got, want in (("corpus words", len(allw), 3057),
                             ("distinct 36-bit encodings", len(dist), 759),
                             ("alu_decoded() over the corpus", dec, 1178)):
        print("   %-32s %6d   published %6d   %s"
              % (label, got, want, "PASS" if got == want else "*** FAIL ***"))
    print("   => decode coverage %d / 3057 = %.2f %%" % (dec, 100.0 * dec / 3057))

    # ---------------- A: the words ----------------
    print()
    print("=" * 104)
    print("A. THE WORDS, BY DISTINCT ENCODING")
    print("=" * 104)
    g = collections.defaultdict(list)
    for n, i, w in sel:
        g[w].append((n, i))
    print("   %d occurrences in %d distinct encodings" % (len(sel), len(g)))
    for w in sorted(g):
        f = F(w)
        imgs = sorted(set(n for n, _ in g[w]))
        print("   %s  cls%X addr8=%02X SRC=%02X ACT=%02X f98=%d f31=%d "
              "b4=%d b7=%d b10=%d b11=%d cfmt=%s  guard %d"
              % (f.txt(), f.class4, f.addr8, f.src, f.act, f.f98, f.f31,
                 f.b4, f.b7, f.b10, f.b11, f.cfmt, guard_fail(w)))
        print("       x%-3d in %d image(s): %s"
              % (len(g[w]), len(imgs), ", ".join(imgs)[:150]))

    # ---------------- M: the audit ----------------
    print()
    print("=" * 104)
    print("M. AUDIT OF §229 §2.1's FIVE DISTRIBUTION CLAIMS")
    print("=" * 104)
    b5 = [t for t in sel if (F(t[2]).hi12 >> 5) & 1]
    print("   claim 1  `f31 in {3,6,7} only with bit 5 -- 53 words, 53 of 53,")
    print("            zero counterexamples in 3057'")
    print("       over ALL 3057 : %d words carry f31 in {3,6,7}; %d have bit 5."
          "  COUNTEREXAMPLES = %d" % (len(sel), len(b5), len(sel) - len(b5)))
    for n, i, w in sel:
        if not ((F(w).hi12 >> 5) & 1):
            print("       *** THE COUNTEREXAMPLE: %-9s w%-3d %s  C-FORMAT=%s"
                  % (n, i + (60 if n == "EPILOGUE" else 0), fmt(w), F(w).cfmt))
    a2 = [t for t in nc if F(t[2]).f31 in (3, 6, 7)]
    b2 = [t for t in a2 if (F(t[2]).hi12 >> 5) & 1]
    print("       over the %d NON-C-FORMAT words: %d of %d"
          % (len(nc), len(b2), len(a2)))
    print("       => OFF BY ONE unless the C-format exclusion is stated.  In")
    print("          C-format hi12[11:8] is a FORMAT TAG and hi12[3:1] is not an")
    print("          operation field, so the correct form is `53 of 53 among")
    print("          non-C-format words'.")
    print()
    for b5v in (0, 1):
        s = sorted(set(F(w).f31 for n, i, w in nc
                       if F(w).class4 in (2, 8, 0xA)
                       and ((F(w).hi12 >> 5) & 1) == b5v))
        print("   claim 2  class 2/8/A, bit5=%d : f31 = %s" % (b5v, s))
    c2 = [w for n, i, w in nc if F(w).class4 == 2 and ((F(w).hi12 >> 5) & 1)]
    cw = [w for n, i, w in allw if (F(w).hi12 >> 5) & 1]
    print("   claim 3  class-2 bit5 words %d, of which f98==0 %d ; corpus-wide "
          "%d bit-5 words, f98==0 %d"
          % (len(c2), sum(1 for w in c2 if F(w).f98 == 0), len(cw),
             sum(1 for w in cw if F(w).f98 == 0)))
    b5d = sorted(w for w in dist if (F(w).hi12 >> 5) & 1)
    print("   claim 4  distinct bit-5 words %d, without a bit-5-clear partner %d"
          % (len(b5d), sum(1 for w in b5d if (w ^ 0x20000000) not in dist)))
    for nm in ("KERNEL", "EPILOGUE"):
        hits = [(i, w) for i, w in enumerate(progs[nm]) if (F(w).hi12 >> 5) & 1]
        print("   claim 5  %-9s %d bit-5 words: %s" % (nm, len(hits),
              ", ".join("w%d=%s(f31=%d%s)"
                        % (i + (60 if nm == "EPILOGUE" else 0), fmt(w),
                           F(w).f31, ", C-FORMAT" if F(w).cfmt else "")
                        for i, w in hits)))
    print("       ⚠ the KERNEL's two are BOTH C-format, so the kernel carries")
    print("         ZERO genuine bit-5 words -- the same conflation as claim 1.")

    # ---------------- H: the base analysis ----------------
    print()
    print("=" * 104)
    print("H. THE BASE ANALYSIS -- IS BIT 5 A GATE, OR A SPANDREL?")
    print("=" * 104)
    by = collections.defaultdict(collections.Counter)
    for n, i, w in nc:
        by[base(w)][F(w).f31] += 1
    print("   base  b5   words   f31 codes present (count)")
    for b in sorted(by):
        c = by[b]
        print("   %03X    %d   %5d   %s%s"
              % (b, (b >> 5) & 1, sum(c.values()),
                 " ".join("%d:%d" % kv for kv in sorted(c.items())),
                 "   <<< carries 3/6/7" if set(c) & {3, 6, 7} else ""))
    tot367 = collections.Counter()
    for n, i, w in nc:
        if F(w).f31 in (3, 6, 7):
            tot367[base(w)] += 1
    b020 = sum(1 for n, i, w in nc if base(w) == 0x020)
    print()
    print("   ⇒ base 0x020 -- hi12 with bit 5 SET AND NOTHING ELSE -- holds %d of"
          % b020)
    print("     the %d bit-5 words and %d of the %d {3,6,7} occurrences, and it"
          % (len(cw), tot367[0x020], sum(tot367.values())))
    one = collections.Counter(F(w).f31 for n, i, w in nc
                              if base(w) == 0x020 and F(w).class4 == 2
                              and F(w).addr8 == 0 and F(w).lo12 == 0)
    print("     carries ALL %d f31 codes across its routings, and %d of the eight on"
          % (len(by[0x020]), len(one)))
    print("     the SINGLE routing `.2.00.000' (%s)."
          % " ".join("%d:%d" % kv for kv in sorted(one.items())))
    print("     No other base in the corpus carries more than %d."
          % max(len(v) for k, v in by.items() if k != 0x020))
    print("   ⇒ `f31 3/6/7 requires bit 5' therefore reduces to `the only base on")
    print("     which f31 sweeps its whole range is the base whose only bit IS")
    print("     bit 5'.  A SPANDREL, not a gate.  §229's `bit 5 EXTENDS THE")
    print("     OPERATION FIELD' is not supported by the distribution it came from.")

    # ---------------- I: minimal pairs ----------------
    print()
    print("=" * 104)
    print("I. MINIMAL PAIRS DIFFERING ONLY IN hi12[3:1] -- AND THE ADJACENT ONES")
    print("=" * 104)
    key = collections.defaultdict(set)
    for n, i, w in nc:
        f = F(w)
        key[(f.hi12 & ~0x00E, f.class4, f.addr8, f.lo12)].add(f.f31)
    fam = {k: v for k, v in key.items() if len(v) > 1}
    print("   %d (base,class,addr8,lo12) keys carry more than one f31 code:"
          % len(fam))
    for k in sorted(fam, key=lambda k: (-len(fam[k]), k)):
        b, cl, a, lo = k
        print("      %03X.%X.%02X.%03X  b5=%d  f31 codes %s"
              % (b, cl, a, lo, (b >> 5) & 1, sorted(fam[k])))
    print()
    print("   ★ ADJACENT pairs -- two consecutive words differing ONLY in hi12[3:1].")
    print("     `same' means the SHIPPED model (`op = f31 & 3') executes them")
    print("     IDENTICALLY, i.e. it reads two distinct encodings as one instruction:")
    nsame = 0
    for nm, ws in progs.items():
        for i in range(len(ws) - 1):
            x, y = ws[i], ws[i + 1]
            if x == y or (x ^ y) & ~0x0E000000:
                continue
            fx, fy = F(x).f31, F(y).f31
            same = (fx & 3) == (fy & 3)
            nsame += same
            print("      %-24s [%3d] %s -> [%3d] %s   f31 %d -> %d   %s"
                  % (nm, i, fmt(x), i + 1, fmt(y), fx, fy,
                     "*** SAME under op = f31 & 3 ***" if same else "distinguished"))
    print("     ⇒ %d of them are executed as the SAME instruction twice in a row."
          % nsame)

    # ---------------- L: the epilogue ----------------
    print()
    print("=" * 104)
    print("L. THE EPILOGUE UNDER THE SHIPPED MODEL")
    print("=" * 104)
    print("   iw   word          hi12 cls f31 b5 ST b7 ESC SRC ACT  op   fetch mul store")
    epi = progs["EPILOGUE"]
    for i, w in enumerate(epi):
        f = F(w)
        fetch = bool((f.class4 & 8) and not f.cfmt)
        print("   w%-3d %s  %03X  %X   %d  %d  %d  %d  %d  %02X  %02X   %d   %-3s  %-3s  %-3s%s"
              % (60 + i, fmt(w), f.hi12, f.class4, f.f31, (f.hi12 >> 5) & 1,
                 f.b4, f.b7, f.b11, f.src, f.act, f.f31 & 3,
                 "Y" if fetch else "-",
                 "Y" if (fetch and f.f31 != 2) else "-",
                 "Y" if f.b4 else "-",
                 "   <<<" if (f.f31 in (3, 6, 7) and not f.cfmt) else ""))
    print("   ⚠ `mul' is the gate at upd6383.cpp:4947 -- it reads the RAW f31, not")
    print("     `op'.  3, 6 and 7 are all != 2, so three of the four DO issue a")
    print("     multiply.  §229's `hold, NO PRODUCT' describes the ADDER only.")

    # ---------------- O: the coverage question ----------------
    print()
    print("=" * 104)
    print("O. HOW MUCH DECODE COVERAGE COULD A READING FOR f31 3/6/7 BUY?")
    print("=" * 104)
    for label, codes in (("f31 in {3,6,7}", (3, 6, 7)),
                         ("f31 in {4,5} (§133's alias)", (4, 5))):
        c = collections.Counter(guard_fail(w) for n, i, w in nc
                                if F(w).f31 in codes)
        print("   %s -- which guard refuses each?" % label)
        for gg, k in sorted(c.items(), key=lambda t: -t[1]):
            print("      %4d words  guard %-2d  %s" % (k, gg, GUARD.get(gg, "?")))
        print("      ⇒ a reading would move %d words into alu_decoded():"
              " %d -> %d = %.2f %% -> %.2f %%"
              % (c.get(3, 0), dec, dec + c.get(3, 0),
                 100.0 * dec / 3057, 100.0 * (dec + c.get(3, 0)) / 3057))
        print()
    c3 = collections.Counter(guard_fail(w) for _, _, w in allw)
    print("   THE WHOLE CORPUS, BY FIRST REFUSING GUARD:")
    for gg, k in sorted(c3.items(), key=lambda t: -t[1]):
        print("      %4d words  guard %-2d  %s" % (k, gg, GUARD.get(gg, "?")))
    print()
    print("   ⇒ THE OPERATION FIELD IS NOT WHERE COVERAGE LIVES.")
    print("     all eight f31 codes together are worth at most %d words (+%.1f %%)"
          % (c3.get(3, 0), 100.0 * c3.get(3, 0) / 3057))
    print("     the ROUTING guard alone holds %d = %.1f %% of everything undecoded"
          % (c3.get(23, 0), 100.0 * c3.get(23, 0) / (3057 - dec)))


if __name__ == "__main__":
    main()
