#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""act0d0e_corpus.py -- the STATIC half of the `ACT 0x0D' / `ACT 0x0E' question.

NEC uPD6383GF (Technics SX-KN5000, IC311).  BUILD-LANE-QUEUE item 0 as filed
by 233 sect. 4.2.  Read-only: corpus only, no build, no MAME run.

THE QUESTION IT ANSWERS
  `ACT 0x0D' (+124 corpus words) and `ACT 0x0E' (+110) are the two largest OPEN
  codes left after 233 decided `SRC 0x00'.  `upd6383.cpp' resolves both through
  133's 3-bit destination selector -- shipped pair (1, 7) = `acc <- bus' and
  `P <- bus at the multiply's scale' -- validated in ONE context (PARAMETRIC EQ,
  in the device) and never anchored.  Before any harness runs (rule 13): what
  does the ENCODING say?  Where do the two codes sit, what do they read, what
  is executed immediately after them, and does any of that SEPARATE the seven
  readings of 133's selector?

  ⚠ The answer to the last question is NO, and this tool says so with numbers
  rather than leaving it to a harness to discover: the strongest structural
  fact -- 0x0D is followed by 0x0E on the next word at 4 of a09's 4 sites and
  both of a39's -- is equally consistent with every reading in which 0x0E's
  operand is independent of what 0x0D wrote.  What the corpus DOES supply is
  the list of sites a harness has to reach, and the pairing structure that
  makes the two codes one question.

  ⚠ Every count excludes C-format words (rule 6, ninth occurrence avoided):
  a C-format word has no `src'/`act' field.

    python3 dsp/tools/act0d0e_corpus.py

stdlib only (plus the research tree's own loader).
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pat_corpus import load, F                            # noqa: E402

#  RULE 20 SELF-TEST: published figures this census must reproduce or fail.
#  All from 232's `routing_census.py' section C, an INDEPENDENT tool.
PUB = {
    "corpus words": 3057,
    "ACT 0x0D words": 203, "ACT 0x0D distinct encodings": 79,
    "ACT 0x0D images": 39, "ACT 0x0D coefficient fetches": 1,
    "ACT 0x0E words": 227, "ACT 0x0E distinct encodings": 53,
    "ACT 0x0E images": 40, "ACT 0x0E coefficient fetches": 3,
}
PUB_SRC = {0x0D: {0x07: 152, 0x13: 46, 0x11: 3, 0x08: 1, 0x19: 1},
           0x0E: {0x07: 144, 0x10: 82, 0x1B: 1}}

ANCHORED_ACT = {0x00: "acc<-bus (adder)", 0x07: "mem[ptr]<-bus",
                0x12: "(none)", 0x13: "tempA<-bus", 0x14: "tempB<-bus",
                0x15: "(none)", 0x19: "tempA<-bus"}
SRCN = {0x07: "mem[ptr]", 0x10: "acc", 0x19: "tA", 0x1A: "tB", 0x0B: "DR",
        0x00: "src00", 0x08: "src08", 0x11: "src11", 0x13: "src13",
        0x1B: "src1B"}


def sites(progs, code):
    return [(nm, i, F(w)) for nm, ws in progs.items()
            for i, w in enumerate(ws) if not F(w).cfmt and F(w).act == code]


def nxt(progs, nm, i):
    ws = progs[nm]
    return F(ws[i + 1]) if i + 1 < len(ws) else None


def main():
    progs, _meta = load()
    tot = sum(len(v) for v in progs.values())
    res = {"corpus words": tot}
    S = {c: sites(progs, c) for c in (0x0D, 0x0E)}
    for c, tag in ((0x0D, "ACT 0x0D"), (0x0E, "ACT 0x0E")):
        res[tag + " words"] = len(S[c])
        res[tag + " distinct encodings"] = len({f.w for _n, _i, f in S[c]})
        res[tag + " images"] = len({nm for nm, _i, _f in S[c]})
        res[tag + " coefficient fetches"] = sum(1 for _n, _i, f in S[c]
                                                if f.class4 & 8)

    print("== RULE 20 SELF-TEST (against 232's routing_census.py, an INDEPENDENT tool)")
    okall = True
    for k in PUB:
        ok = (res[k] == PUB[k])
        okall &= ok
        print("   %-32s %4d   published %4d   %s" % (k, res[k], PUB[k],
                                                      "PASS" if ok else "FAIL"))
    for c in (0x0D, 0x0E):
        got = dict(collections.Counter(f.src for _n, _i, f in S[c]))
        ok = (got == PUB_SRC[c])
        okall &= ok
        print("   ACT 0x%02X SRC profile %-13s %s   %s"
              % (c, "", " ".join("%02X x%d" % kv for kv in sorted(got.items())),
                 "PASS" if ok else "FAIL (published %s)" % PUB_SRC[c]))
    print("   SELF-TEST: %s" % ("PASS" if okall else "⛔ FAIL -- nothing below is graded"))

    #  ------------------------------------------------------------------
    print("\n== A. WHERE THE TWO CODES SIT")
    for c in (0x0D, 0x0E):
        per = collections.Counter(nm for nm, _i, _f in S[c])
        print("   ACT 0x%02X in %d images; top: %s" % (
            c, len(per), ", ".join("%s x%d" % kv for kv in per.most_common(8))))
    for want in ("KERNEL", "EPILOGUE", "a39 PARAMETRIC EQ", "a09 SINGLE DELAY"):
        rows = sorted([(i, c, f) for c in (0x0D, 0x0E)
                       for nm, i, f in S[c] if nm == want])
        print("   %-20s %s" % (want, ", ".join(
            "w%d %s(%02X<-%s)" % (i, "0D" if c == 0x0D else "0E", c,
                                  SRCN.get(f.src, "%02X" % f.src))
            for i, c, f in rows) or "-"))

    #  ------------------------------------------------------------------
    print("\n== B. THE FIELD PROFILE, per code (non-C-format)")
    for c in (0x0D, 0x0E):
        fs = [f for _n, _i, f in S[c]]
        print("   ACT 0x%02X  f31 %s | store bit %s | class4 %s | ptr-mode %s"
              % (c, dict(collections.Counter(f.f31 for f in fs)),
                 dict(collections.Counter(f.b4 for f in fs)),
                 dict(collections.Counter(f.class4 for f in fs)),
                 dict(collections.Counter((f.lo12 >> 5) & 1 for f in fs))))

    #  ------------------------------------------------------------------
    print("\n== C. THE PAIRING MOTIF -- what is executed on the NEXT word")
    print("   (the null is the same statistic for every ANCHORED action, so a")
    print("    motif that every code shows is code density, not semantics)")
    base_next = collections.Counter()
    per_act_next = collections.defaultdict(collections.Counter)
    n_act = collections.Counter()
    for nm, ws in progs.items():
        for i, w in enumerate(ws[:-1]):
            f, g = F(w), F(ws[i + 1])
            if f.cfmt or g.cfmt:
                continue
            n_act[f.act] += 1
            per_act_next[f.act]["act %02X" % g.act] += 1
            per_act_next[f.act]["src %02X" % g.src] += 1
            base_next["src %02X" % g.src] += 1
            base_next["act %02X" % g.act] += 1
    nbase = sum(n_act.values())

    def row(a, key):
        n = n_act[a]
        k = per_act_next[a][key]
        b = base_next[key] / float(nbase)
        return "%3d/%3d = %5.1f %%  (x%.2f vs base %4.1f %%)" % (
            k, n, 100.0 * k / n if n else 0, (k / float(n)) / b if (n and b) else 0,
            100 * b)

    print("   next word is ACT 0x0E:")
    for a in (0x0D, 0x0E, 0x00, 0x07, 0x13, 0x14, 0x19, 0x15):
        print("      after ACT 0x%02X %-18s %s"
              % (a, ANCHORED_ACT.get(a, "?"), row(a, "act 0E")))
    print("   next word reads the ACCUMULATOR (SRC 0x10):")
    for a in (0x0D, 0x0E, 0x00, 0x07, 0x13, 0x14, 0x19, 0x15):
        print("      after ACT 0x%02X %-18s %s"
              % (a, ANCHORED_ACT.get(a, "?"), row(a, "src 10")))
    print("   next word reads mem[ptr] (SRC 0x07):")
    for a in (0x0D, 0x0E, 0x00, 0x07, 0x13, 0x14, 0x19, 0x15):
        print("      after ACT 0x%02X %-18s %s"
              % (a, ANCHORED_ACT.get(a, "?"), row(a, "src 07")))
    print("   next word reads tempA (SRC 0x19):")
    for a in (0x0D, 0x0E, 0x00, 0x07, 0x13, 0x14, 0x19, 0x15):
        print("      after ACT 0x%02X %-18s %s"
              % (a, ANCHORED_ACT.get(a, "?"), row(a, "src 19")))

    #  the 0D->0E pair, and what the 0E half reads
    pairs = [(nm, i, f, nxt(progs, nm, i)) for nm, i, f in S[0x0D]]
    pairs = [(nm, i, f, g) for nm, i, f, g in pairs if g is not None and not g.cfmt]
    de = [(nm, i, f, g) for nm, i, f, g in pairs if g.act == 0x0E]
    print("\n   ★ ACT 0x0D immediately followed by ACT 0x0E: %d of %d 0x0D words"
          " (%.1f %%)" % (len(de), len(pairs), 100.0 * len(de) / len(pairs)))
    print("      the 0x0E half's SRC in those pairs : %s"
          % dict(collections.Counter(g.src for _n, _i, _f, g in de)))
    print("      the 0x0D half's SRC in those pairs : %s"
          % dict(collections.Counter(f.src for _n, _i, f, _g in de)))
    print("      the 0x0D half's f31                : %s"
          % dict(collections.Counter(f.f31 for _n, _i, f, _g in de)))
    ed = [(nm, i, f) for nm, i, f in S[0x0E]
          if i > 0 and not F(progs[nm][i - 1]).cfmt
          and F(progs[nm][i - 1]).act == 0x0D]
    print("   ★ ACT 0x0E immediately preceded by ACT 0x0D: %d of %d 0x0E words"
          % (len(ed), len(S[0x0E])))

    #  ------------------------------------------------------------------
    #  D'. THE CONSUMER CENSUS, WITH ITS NULL FIRST.  For each candidate
    #  destination, walk forward from the site and ask whether the destination
    #  is READ before it is REWRITTEN (a static, single-pass scan over the
    #  program image; a delay port, a CALL or a frame boundary is not modelled).
    #  The null is the same scan applied to the ANCHORED codes whose destination
    #  IS known: if the known destination does not score distinctly above the
    #  wrong ones there, the statistic has no power (three-codes.md sect. 5
    #  found exactly that for the mem[ptr] test) and nothing may be read off it.
    #  ------------------------------------------------------------------
    def reads(f, dest):
        if dest == "acc":
            return f.src == 0x10 or f.f31 in (1, 2)
        if dest == "P":
            return f.f31 in (0, 1)
        if dest == "tA":
            return f.src == 0x19
        if dest == "tB":
            return f.src == 0x1A
        if dest == "mem":
            return f.src in (0x07, 0x00)
        return False

    def writes(f, dest):
        if dest == "acc":
            return f.f31 in (0, 1) or f.act == 0x00
        if dest == "P":
            return bool(f.class4 & 8)
        if dest == "tA":
            return f.act in (0x13, 0x19)
        if dest == "tB":
            return f.act == 0x14
        if dest == "mem":
            return f.act == 0x07 or f.b4
        return False

    def consumed(ws, i, dest, horizon=6):
        for j in range(i + 1, min(len(ws), i + 1 + horizon)):
            g = F(ws[j])
            if g.cfmt:
                continue
            if reads(g, dest):
                return True
            if writes(g, dest):
                return False
        return False

    DESTS = ("acc", "P", "tA", "tB", "mem")
    print("\n== D'. THE CONSUMER CENSUS -- is the destination READ before it is")
    print("       REWRITTEN, within 6 words?  NULL FIRST: anchored codes whose")
    print("       destination is KNOWN (the known one is marked *)")
    known = {0x00: "acc", 0x07: "mem", 0x13: "tA", 0x14: "tB", 0x19: "tA"}
    print("   %-26s %s" % ("after", "  ".join("%6s" % d for d in DESTS)))
    for a in (0x00, 0x07, 0x13, 0x14, 0x19, 0x0D, 0x0E):
        rows = [(nm, i) for nm, ws in progs.items() for i, w in enumerate(ws)
                if not F(w).cfmt and F(w).act == a]
        pct = []
        for d in DESTS:
            k = sum(1 for nm, i in rows if consumed(progs[nm], i, d))
            pct.append("%5.1f%%%s" % (100.0 * k / len(rows),
                                      "*" if known.get(a) == d else " "))
        print("   ACT 0x%02X %-17s %s   (n=%d)"
              % (a, ANCHORED_ACT.get(a, "?"), "  ".join(pct), len(rows)))
    print("""   ⇒ read the NULL rows before the two under test: `acc' and `P' are read
      within 6 words after EVERY code (a MAC program reads its accumulator and
      its product constantly), so a high `acc'/`P' score after 0x0D/0x0E is
      what any word gets.  Only tA/tB/mem separate the anchored codes, and
      0x0D/0x0E score at or below base on all three.  The census cannot pick
      a destination for either code; it is printed so that nobody re-runs it.""")

    #  ------------------------------------------------------------------
    print("\n== D. DOES THE CORPUS SEPARATE THE SEVEN READINGS?  NO -- and why")
    print("""   133's selector: 0 nop | 1 acc<-bus | 2 tA | 3 tB | 4 mem[ptr] | 5 P raw
                   | 6 acc+=bus | 7 P<<16.   Shipped: 0x0D = 1, 0x0E = 7.
   * the dominant motif -- 0x0D reads mem[ptr], the next word is 0x0E and reads
     the ACCUMULATOR -- is what 133 built its reading on.  But 0x0E's SRC 0x10
     read is a fact about 0x0E's OPERAND, not about 0x0D's DESTINATION: under
     `nop' the accumulator 0x0E reads is the one f31 = 0 just loaded from P,
     under `acc<-bus' it is 0x0D's operand.  Both are consistent with the motif.
   * three-codes.md item E stands: 0x0D has no minimal pair against any
     anchored ACTION, so no word-shape argument reaches it; 0x0E's 8 shared
     shapes with 0x07 (mem[ptr]<-bus) are a distributional argument only.
   * the consumer census (D') has no power: its null rows show `acc' and `P'
     are read within 6 words of EVERY code, and on the three destinations that
     do separate the anchored codes 0x0D/0x0E score at base.  The corpus cannot
     say which read is the consumer.  That is a question for a context whose ARITHMETIC
     is known -- which is where sd_rerun.py act0d0e and gate_settle.py act0d0e
     go next, and why they are the second step and not the first.""")
    return okall


if __name__ == "__main__":
    main()
