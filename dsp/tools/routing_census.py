#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""routing_census.py -- §232.  THE UNANCHORED `SRC'/`ACTION' CENSUS.

NEC uPD6383GF (Technics SX-KN5000, IC311).  BUILD-LANE-QUEUE item 0, filed by
§231.  Read-only: it loads the 3057-word static corpus through `pat_corpus' and
re-implements the decode conjunction INDEPENDENTLY of `dsp_disasm', so the
guard breakdown it prints is a second opinion rather than a restatement.

THE QUESTION IT ANSWERS
  §231 measured that `alu_decoded()' -- a CONJUNCTION, so only its FIRST failure
  is observable -- refuses 1139 of the 3057 corpus words at the ROUTING guard
  (`SRC or ACTION not anchored'), against 106 for the whole operation field.
  That is 60.6 % of everything undecoded, and it is the SAME population §229's
  fabricated-zero census counts (28.492 % of the epilogue's operands).

  So: PER UNANCHORED CODE -- its SITES, its INDEX RANGE, its CONSUMER.

  ⛔ CENSUS ONLY.  Dead end 4 / standing rule 4 forbid implementing a consumer
  whose index is measured CONSTANT, so a constant index CLOSES a code rather
  than opening it -- exactly as it already closed `SRC 0x13'
  (`acc 0..0 | m_dp 12..12 | cursor 9..9', §162).

  ⚠ The INDEX RANGE is a DYNAMIC quantity and this tool cannot invent it: it is
  measured by the device's `§232 ROUTING CENSUS' instrument and parsed back in
  by `--log'.  Without a log this tool prints the static half only and says so.

SECTIONS
  0  RULE 20 SELF-TESTS -- six published numbers, reproduced by an INDEPENDENT
     mirror of the conjunction: 3057 corpus words, and §231's whole breakdown
     DECODED 1178 / ROUTING 1139 / CLASS 546 / OPERATION 106 / FORMAT 68 /
     GUARD7 20.  Any one of them can fail.
  A  the guard breakdown, and the ROUTING population by responsible field
  B  ★ THE PER-CODE PRICE: how many words would newly DECODE if this one code
     were anchored and nothing else changed (the honest coverage payoff), and
     the joint ceiling if ALL of them were
  C  per code: sites (images, slots, distinct encodings), and its CONSUMER
     profile -- for a SRC code the ACTIONs it is paired with and whether the
     word fetches a coefficient; for an ACTION code the SRCs it consumes
  D  ★ THE VERDICT TABLE: per code, the disposition -- CLOSED (index constant),
     OPEN, or UNREACHABLE in the measured vehicle

    python3 dsp/tools/routing_census.py                    # static half only
    python3 dsp/tools/routing_census.py --log <arm.log.gz> # + the index ranges

stdlib only (plus the research tree's own loader).
"""
import collections
import gzip
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pat_corpus import load, F                            # noqa: E402

# ---------------------------------------------------------------------------
#  THE DECODE CONJUNCTION, RE-IMPLEMENTED FROM upd6383d.h's `alu_guard_fail()'.
#  ⚠ DELIBERATELY NOT imported from dsp_disasm: §231's numbers came through
#  that module, so reproducing them with it would be a tautology (rule 20 --
#  "internal consistency that is TRUE BY CONSTRUCTION is not a self-test").
#  The constants below are written out here so a divergence shows up as a
#  FAILED self-test rather than as agreement.
# ---------------------------------------------------------------------------
ANCHORED_SRC = frozenset((0x07, 0x10, 0x19, 0x1A))   # mem[ptr], acc, tempA, tempB
ANCHORED_ACT = frozenset((0x00, 0x07, 0x12, 0x13, 0x14, 0x15, 0x19))
SRC_NAME = {0x07: "mem[ptr]", 0x10: "acc", 0x19: "tempA", 0x1A: "tempB"}
ACT_NAME = {0x00: "acc<-bus", 0x07: "mem[ptr]<-bus", 0x12: "(none)",
            0x13: "tempA<-bus", 0x14: "tempB<-bus", 0x15: "(none)",
            0x19: "tempA<-?"}
G_DECODED, G_CLASS, G_OP, G_FMT, G_B4, G_A07, G_G7 = 0, 1, 3, 4, 5, 6, 7
G_B11, G_PTRMODE, G_ROUTING = 21, 22, 23
GUARD = {G_DECODED: "DECODED", G_CLASS: "CLASS", G_OP: "OPERATION",
         G_FMT: "FORMAT (C-format)", G_B4: "bit-4 off mode 2",
         G_A07: "ACTION-07 off mode 2", G_G7: "GUARD 7",
         G_B11: "routing/bit-11", G_PTRMODE: "routing/pointer-mode",
         G_ROUTING: "ROUTING (SRC-or-ACTION not anchored)"}
#  §231's published whole-corpus breakdown, by first refusing guard.
PUBLISHED = {G_DECODED: 1178, G_ROUTING: 1139, G_CLASS: 546, G_OP: 106,
             G_FMT: 68, G_G7: 20}


def guard_fail(w, src_ok=ANCHORED_SRC, act_ok=ANCHORED_ACT):
    """Identity of the FIRST guard that refuses `w'; 0 = decoded.

    `src_ok'/`act_ok' are parameters so section B can ask the counterfactual
    "what if THIS code were anchored" without touching anything else.
    """
    hi12 = (w >> 24) & 0xFFF
    if (hi12 & 0xF00) == 0xC00:
        return G_FMT
    cl = (w >> 20) & 0xF
    if cl not in (2, 8, 0xA):
        return G_CLASS
    lo12 = w & 0xFFF
    if lo12 & 0x800:
        return G_B11
    if (lo12 >> 5) & 1:
        return G_PTRMODE
    src, act = (lo12 >> 6) & 0x1F, lo12 & 0x1F
    if src not in src_ok or act not in act_ok:
        return G_ROUTING
    st, b7 = (hi12 >> 4) & 1, (hi12 >> 7) & 1
    f31 = (hi12 >> 1) & 7
    if st and (cl & 7) != 2:
        return G_B4
    if act == 0x07 and (cl & 7) != 2:
        return G_A07
    if st and b7 and f31 != 2:
        return G_G7
    if f31 in (0, 1):
        return G_DECODED
    if f31 == 2:
        return G_DECODED if cl == 8 else G_OP
    return G_OP


def coeff_fetch(w):
    """class4 bit 3 -- the word fetches a coefficient, so it multiplies."""
    return bool(((w >> 20) & 0xF) & 8)


# ---------------------------------------------------------------------------
#  the DYNAMIC half: parse the device's `§232 ROUTING CENSUS' block back in
# ---------------------------------------------------------------------------
ROW = re.compile(
    r"(SRC|ACT) 0x([0-9A-F]{2})\s+iw(\d+)\s+(quiet|loud)\s+n=(\d+)\s+\|"
    r"\s+dp\s+(\d+)\.\.(\d+)\s+\|\s+cur\s+(\d+)\.\.(\d+)\s+\|"
    r"\s+dsc\s+(\d+)\.\.(\d+)\s+\|\s+acc\s+(-?\d+)\.\.(-?\d+)\s+\|"
    r"\s+addr8=([0-9A-F]{2})\s+\|\s+consumer=(\S+)")


def read_log(path):
    """-> {(kind, code): {iw: {bucket: dict}}}, and the overflow line."""
    op = gzip.open if path.endswith(".gz") else open
    out, over = collections.defaultdict(lambda: collections.defaultdict(dict)), None
    with op(path, "rt", errors="replace") as fh:
        for line in fh:
            m = ROW.search(line)
            if m:
                kind, code, iw, b = m.group(1), int(m.group(2), 16), int(m.group(3)), m.group(4)
                out[(kind, code)][iw][b] = dict(
                    n=int(m.group(5)),
                    dp=(int(m.group(6)), int(m.group(7))),
                    cur=(int(m.group(8)), int(m.group(9))),
                    dsc=(int(m.group(10)), int(m.group(11))),
                    acc=(int(m.group(12)), int(m.group(13))),
                    addr8=int(m.group(14), 16), consumer=m.group(15))
            elif "§232 ROUTING CENSUS" in line and "overflow" in line:
                over = line.strip()
    return out, over


def _span(rows, key):
    lo = min(r[key][0] for r in rows)
    hi = max(r[key][1] for r in rows)
    return lo, hi


def main():
    logpath = None
    if "--log" in sys.argv:
        logpath = sys.argv[sys.argv.index("--log") + 1]

    progs, meta = load()
    allw = [(n, i, w) for n, ws in progs.items() for i, w in enumerate(ws)]

    # ---------------- 0: rule-20 self-tests ----------------
    fails = 0
    print("=" * 100)
    print("§232  THE UNANCHORED SRC/ACTION CENSUS -- RULE 20 SELF-TESTS, PRINTED FIRST")
    print("=" * 100)
    print("   an INDEPENDENT mirror of alu_guard_fail(), against §231's published breakdown")
    by_guard = collections.Counter(guard_fail(w) for _, _, w in allw)
    checks = [("corpus words", len(allw), 3057)]
    for g, want in sorted(PUBLISHED.items(), key=lambda kv: -kv[1]):
        checks.append(("guard %-34s" % GUARD[g], by_guard[g], want))
    for label, got, want in checks:
        ok = got == want
        fails += 0 if ok else 1
        print("   %-44s %6d   published %6d   %s"
              % (label, got, want, "PASS" if ok else "*** FAIL ***"))
    print("   %-44s %6s   %s" % ("SELF-TEST TOTAL", "",
                                 "PASS %d of %d" % (len(checks) - fails, len(checks))))
    if fails:
        print("   ⛔ A SELF-TEST FAILED -- EVERY NUMBER BELOW IS VOID.")

    # ---------------- A: the routing population, by responsible field ----------------
    print()
    print("=" * 100)
    print("A. THE ROUTING POPULATION, BY WHICH FIELD IS UNANCHORED")
    print("=" * 100)
    routed = [(n, i, w) for n, i, w in allw if guard_fail(w) == G_ROUTING]
    both = src_only = act_only = 0
    for _, _, w in routed:
        s, a = (w >> 6) & 0x1F, w & 0x1F
        if s not in ANCHORED_SRC and a not in ANCHORED_ACT:
            both += 1
        elif s not in ANCHORED_SRC:
            src_only += 1
        else:
            act_only += 1
    print("   %d words refused FIRST by the routing guard" % len(routed))
    print("      SRC unanchored only     %5d" % src_only)
    print("      ACTION unanchored only  %5d" % act_only)
    print("      BOTH unanchored         %5d   <- anchoring ONE of the two frees nothing"
          % both)
    print("   ⚠ `both' is the reason a per-code payoff is NOT additive: see B.")

    # ---------------- B: the per-code price ----------------
    print()
    print("=" * 100)
    print("B. ★ THE PER-CODE PRICE -- words that would NEWLY DECODE if this one code")
    print("   were anchored and NOTHING ELSE changed.  The honest coverage payoff.")
    print("=" * 100)
    base = by_guard[G_DECODED]
    usrc = sorted(set((w >> 6) & 0x1F for _, _, w in allw) - ANCHORED_SRC)
    uact = sorted(set(w & 0x1F for _, _, w in allw) - ANCHORED_ACT)
    price = {}
    for kind, codes in (("SRC", usrc), ("ACT", uact)):
        for c in codes:
            so = ANCHORED_SRC | {c} if kind == "SRC" else ANCHORED_SRC
            ao = ANCHORED_ACT | {c} if kind == "ACT" else ANCHORED_ACT
            price[(kind, c)] = sum(1 for _, _, w in allw
                                   if guard_fail(w, so, ao) == G_DECODED) - base
    allsrc = ANCHORED_SRC | set(usrc)
    allact = ANCHORED_ACT | set(uact)
    ceil_all = sum(1 for _, _, w in allw if guard_fail(w, allsrc, allact) == G_DECODED)
    ceil_src = sum(1 for _, _, w in allw if guard_fail(w, allsrc, ANCHORED_ACT) == G_DECODED)
    ceil_act = sum(1 for _, _, w in allw if guard_fail(w, ANCHORED_SRC, allact) == G_DECODED)
    print("   BASELINE decoded                      %5d / 3057 = %.2f %%"
          % (base, 100.0 * base / 3057))
    print("   CEILING, every SRC code anchored      %5d / 3057 = %.2f %%   (+%d)"
          % (ceil_src, 100.0 * ceil_src / 3057, ceil_src - base))
    print("   CEILING, every ACTION code anchored   %5d / 3057 = %.2f %%   (+%d)"
          % (ceil_act, 100.0 * ceil_act / 3057, ceil_act - base))
    print("   CEILING, ALL routing anchored         %5d / 3057 = %.2f %%   (+%d)"
          % (ceil_all, 100.0 * ceil_all / 3057, ceil_all - base))
    print("   ⚠ %d of the %d routing-refused words do NOT reach DECODED even then --"
          % (len(routed) - (ceil_all - base), len(routed)))
    print("     a later guard (bit-4/ACTION-07/GUARD 7/OPERATION) takes them.")
    print("   ⚠ Compare with §231: the WHOLE operation field is worth at most 106.")
    #  ★★ §229's six FABRICATED-ZERO codes, priced AS A GROUP.  §231 said the routing
    #  guard's population "is the SAME set of codes" as the fabricated-zero census's.
    #  It is a SUBSET, and this is what that subset is worth.
    fz = {0x01, 0x05, 0x06, 0x0A, 0x13, 0x1C}
    fzc = sum(1 for _, _, w in allw if ((w >> 6) & 0x1F) in fz)
    fzp = sum(1 for _, _, w in allw
              if guard_fail(w, ANCHORED_SRC | fz, ANCHORED_ACT) == G_DECODED) - base
    print("   ★★ §229's SIX FABRICATED-ZERO SRC CODES {01,05,06,0A,13,1C} AS A GROUP:")
    print("      %d corpus words, and anchoring ALL SIX together is worth %d NEWLY DECODED WORDS."
          % (fzc, fzp))
    for tag, so_, ao_ in (("before", ANCHORED_SRC, ANCHORED_ACT),
                          ("after ", ANCHORED_SRC | fz, ANCHORED_ACT)):
        bg = collections.Counter(guard_fail(w, so_, ao_) for _, _, w in allw
                                 if ((w >> 6) & 0x1F) in fz)
        print("      %s : %s" % (tag, " | ".join("%s %d" % (GUARD[g], n)
                                                 for g, n in sorted(bg.items()))))
    print("      ⇒ §231's *\"the routing guard's population is the SAME set of codes as §229's")
    print("      fabricated-zero census\"* is HALF RIGHT: it is a SUBSET, and it is the HALF")
    print("      WITH NO COVERAGE IN IT.  The silence population and the coverage population")
    print("      overlap in NAME and are DISJOINT IN VALUE.")
    print()
    print("   %-9s %7s %7s   %s" % ("code", "words", "PRICE", "sole-blocker payoff"))
    for kind, codes in (("SRC", usrc), ("ACT", uact)):
        for c in sorted(codes, key=lambda c: -price[(kind, c)]):
            nw = sum(1 for _, _, w in allw
                     if (((w >> 6) & 0x1F) if kind == "SRC" else (w & 0x1F)) == c)
            bar = "#" * min(60, price[(kind, c)] // 4)
            print("   %s 0x%02X %7d %7d   %s" % (kind, c, nw, price[(kind, c)], bar))

    # ---------------- C: sites and consumers ----------------
    print()
    print("=" * 100)
    print("C. SITES AND CONSUMER PROFILE, PER UNANCHORED CODE")
    print("=" * 100)
    for kind, codes in (("SRC", usrc), ("ACT", uact)):
        for c in codes:
            hits = [(n, i, w) for n, i, w in allw
                    if (((w >> 6) & 0x1F) if kind == "SRC" else (w & 0x1F)) == c]
            imgs = sorted(set(n for n, _, _ in hits))
            enc = sorted(set(w for _, _, w in hits))
            firstref = collections.Counter(guard_fail(w) for _, _, w in hits)
            if kind == "SRC":
                pair = collections.Counter(w & 0x1F for _, _, w in hits)
                plabel = "ACTIONs it is paired with"
            else:
                pair = collections.Counter((w >> 6) & 0x1F for _, _, w in hits)
                plabel = "SRCs it consumes"
            nfetch = sum(1 for _, _, w in hits if coeff_fetch(w))
            print()
            print("   %s 0x%02X -- %d words, %d distinct encodings, %d images, price %d"
                  % (kind, c, len(hits), len(enc), len(imgs), price[(kind, c)]))
            print("      first refusal : %s"
                  % "  ".join("%s=%d" % (GUARD[g], n) for g, n in firstref.most_common()))
            print("      %-22s: %s" % (plabel,
                  "  ".join("%02X x%d" % (k, v) for k, v in pair.most_common(8))))
            print("      coefficient fetch (multiplies) : %d of %d" % (nfetch, len(hits)))
            print("      images  : %s%s"
                  % (", ".join(imgs[:6]), " ..." if len(imgs) > 6 else ""))
            ep = [i for n, i, _ in hits if n == "EPILOGUE"]
            kn = [i for n, i, _ in hits if n == "KERNEL"]
            print("      resident: KERNEL slots %s | EPILOGUE slots %s"
                  % (kn if kn else "-", ep if ep else "-"))

    # ---------------- D: the verdict ----------------
    print()
    print("=" * 100)
    print("D. ★ THE VERDICT -- a code whose every INDEX candidate is CONSTANT is CLOSED")
    print("=" * 100)
    if not logpath:
        print("   ⚠ NO --log GIVEN.  The index range is a DYNAMIC quantity: it comes from the")
        print("   device's `§232 ROUTING CENSUS' instrument, not from the ROM.  Static half only.")
        print("   Re-run as:  python3 dsp/tools/routing_census.py --log dsp/analysis/data/<arm>.log.gz")
        return 1 if fails else 0
    live, over = read_log(logpath)
    print("   log: %s" % logpath)
    if over:
        print("   %s" % over)
    if not live:
        print("   ⛔ THE LOG CARRIES NO §232 ROUTING CENSUS BLOCK.  Nothing is graded.")
        return 1

    # ---- RULE 20: EXTERNAL controls -- answers already on record, produced by
    # ---- OTHER instruments, reproduced by this one.  Printed before the finding.
    print()
    print("   ★ RULE 20 -- EXTERNAL CONTROLS: four answers already on record, each")
    print("   produced by a DIFFERENT instrument, re-derived from this census's own rows.")
    ext = []
    #  E1: §229's fabricated-zero census named the sites of its six SRC codes, from
    #      the `default:' arm of the SRC switch.  This census's hook is elsewhere
    #      (`m_last_l'), so agreement is not by construction.
    E229 = {0x01: [61], 0x05: [60], 0x06: [68], 0x0A: [78],
            0x13: [99, 108, 140, 149], 0x1C: [111]}
    for c, want in sorted(E229.items()):
        got = sorted(live.get(("SRC", c), {}))
        ext.append(("§229 fabricated-zero sites, SRC 0x%02X" % c,
                    "iw" + ",".join(map(str, want)),
                    "iw" + ",".join(map(str, got)), got == want))
    #  E2: §231 item G -- "w78's ACTION is 0x07, not 0x00", so the fabricated SRC
    #      0x0A operand reaches the STORE and never the accumulator's bus term.
    r = live.get(("SRC", 0x0A), {}).get(78, {})
    cons = sorted(set(v["consumer"] for v in r.values())) if r else []
    ext.append(("§231 item G: SRC 0x0A@iw78 consumer", "store-mem",
                ",".join(cons) or "(absent)", cons == ["store-mem"]))
    #  E3: §224/§225's ladder -- iw33's product is C-RAM[0x9B]^2 >> 6 = 6 039 795
    #      = 0.720 x FS, a coefficient SQUARED and not a sample.  A third
    #      instrument (`§S3', a D-RAM store recorder) published that literal.
    r = live.get(("SRC", 0x08), {}).get(33, {})
    accs = sorted(set(v["acc"] for v in r.values())) if r else []
    ext.append(("§224 ladder: SRC 0x08@iw33 acc", "6039795..6039795",
                " ".join("%d..%d" % a for a in accs) or "(absent)",
                accs == [(6039795, 6039795)]))
    #  E4: §162 closed SRC 0x13 on `acc 0..0' at the class-6 word.
    r = live.get(("SRC", 0x13), {})
    ok = bool(r) and all(v["acc"] == (0, 0) for iw in r for v in r[iw].values())
    ext.append(("§162: SRC 0x13 acc at every class-6 site", "0..0",
                "0..0" if ok else "NOT 0..0", ok))
    nfail = 0
    for label, want, got, ok in ext:
        nfail += 0 if ok else 1
        print("      %-42s want %-22s got %-22s %s"
              % (label, want, got, "PASS" if ok else "*** FAIL ***"))
    print("      EXTERNAL CONTROL: %s %d of %d"
          % ("PASS" if not nfail else "✘ FAILED", len(ext) - nfail, len(ext)))
    if nfail:
        print("      ⛔ AN EXTERNAL CONTROL FAILED -- the verdicts below are VOID.")
    print()
    print("   ⚠⚠ THE VERDICT IS PER *SITE*, THEN ROLLED UP -- NEVER POOLED.  Standing rule 10:")
    print("   pooling 36 M firings across sites instead of keying them cost a whole pass.  Four")
    print("   sites each holding a DIFFERENT constant index pool into a range, and a pooled range")
    print("   reads exactly like a varying one.  `SRC 0x13' is the worked example: pooled it")
    print("   prints `dp 80..83 | cur 3..16' and looks OPEN; per site it is dp 80/81/82/83 and")
    print("   cur 3/5/14/16, every one DEGENERATE IN BOTH BUCKETS -- which is what §162 CLOSED it")
    print("   on.  A constant index per site is what dead end 4 forbids implementing.")
    print()
    print("   %-8s %5s %-30s %-30s %s"
          % ("code", "sites", "PER-SITE INDEX (dp|cur|dsc|acc)", "consumer", "verdict"))
    closed = openc = 0
    closed_l, open_l = [], []
    for kind, codes in (("SRC", usrc), ("ACT", uact)):
        for c in codes:
            rec = live.get((kind, c))
            if not rec:
                continue
            varying = []
            per = []
            for iw in sorted(rec):
                rows = list(rec[iw].values())
                dp, cur, dsc, acc = (_span(rows, k) for k in ("dp", "cur", "dsc", "acc"))
                sconst = all(a == b for a, b in (dp, cur, dsc, acc))
                if not sconst:
                    varying.append(iw)
                per.append((iw, dp, cur, dsc, acc, sconst))
            const = not varying
            cons = sorted(set(r["consumer"] for iw in rec for r in rec[iw].values()))
            verdict = ("★ CLOSED -- every site's index CONSTANT in both buckets" if const
                       else "OPEN -- index VARIES within %d of %d sites"
                            % (len(varying), len(rec)))
            (closed_l if const else open_l).append("%s 0x%02X" % (kind, c))
            closed += 1 if const else 0
            openc += 0 if const else 1
            print("   %s 0x%02X %5d %-30s %-30s %s"
                  % (kind, c, len(rec),
                     ("%d|%d|%d|%d" % (per[0][1][0], per[0][2][0], per[0][3][0], per[0][4][0])
                      + (" ..." if len(per) > 1 else "")),
                     ",".join(cons), verdict))
            for iw, dp, cur, dsc, acc, sconst in per:
                print("        iw%-4d dp %d..%d | cur %d..%d | dsc %d..%d | acc %d..%d  %s"
                      % (iw, dp[0], dp[1], cur[0], cur[1], dsc[0], dsc[1], acc[0], acc[1],
                         "constant" if sconst else "★ VARIES"))
    print()
    print("   RESIDENT AND GRADED : %d codes   CLOSED %d   OPEN %d"
          % (closed + openc, closed, openc))
    print("   CLOSED: %s" % ", ".join(closed_l))
    print("   OPEN  : %s" % ", ".join(open_l))
    print()
    print("   ★★ AND THE DISPOSITION, PRICED.  What each group is worth in corpus words:")
    def _grp(names):
        tot = 0
        for nm in names:
            k, h = nm.split()
            tot += price[(k, int(h, 16))]
        return tot
    resident = closed_l + open_l
    notres = ["%s 0x%02X" % (k, c) for k, cs in (("SRC", usrc), ("ACT", uact))
              for c in cs if not live.get((k, c))]
    print("      CLOSED by this census   %2d codes   %4d words  (a constant index; dead end 4)"
          % (len(closed_l), _grp(closed_l)))
    print("      OPEN                    %2d codes   %4d words  (an index VARIES at >= 1 site)"
          % (len(open_l), _grp(open_l)))
    print("      NOT RESIDENT here       %2d codes   %4d words  (UNMEASURED, not measured-zero)"
          % (len(notres), _grp(notres)))
    print("      ⚠ NOT ADDITIVE and not a partition of the %d-word ceiling: %d routing-refused"
          % (ceil_all - base, both))
    print("      words carry an unanchored SRC *and* an unanchored ACTION, so anchoring either")
    print("      one alone frees none of them.  Read each figure as a per-group LOWER BOUND.")
    print("      NOT RESIDENT: %s" % ", ".join(notres))
    ncodes = len(usrc) + len(uact)
    print("   NOT RESIDENT in this vehicle: %d of %d codes -- rule 4 forbids implementing"
          % (ncodes - closed - openc, ncodes))
    print("   them from here either, and they are UNMEASURED, not measured-constant.")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
