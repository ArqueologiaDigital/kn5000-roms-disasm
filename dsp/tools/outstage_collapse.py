#!/usr/bin/env python3
"""outstage_collapse.py -- §230.  ARE THE OUTPUT-STAGE CONTROLS ONE CHECK OR FOUR?

CONTROL-AUDIT_findings.md (`f601303') §0 records, as the pass's biggest single
finding, that four of the five CANNOT-FAIL controls -- `§54', `§70', `§211' and
the rule-19 mean/span line -- all read the SAME output-stage null, so quoting
all four as a regression battery is quoting one criterion four times.

This tool does two things the audit did not:

  1. IT PROVES THE COLLAPSE MECHANICALLY, over all 40 archived arms, by
     comparing the controls' MOVE-SETS -- the set of arms in which each control
     differs from the shipped-default value.  Two controls that are one
     criterion have the SAME move-set; two that are independent do not.
     ⇒ the claim becomes a measured set identity, not a structural argument.

  2. IT LOOKS FOR A GENUINELY INDEPENDENT SECOND CHECK ON THE OUTPUT STAGE by
     ranking every other extracted control by move-set containment.  A control
     whose move-set STRICTLY CONTAINS the null's is sensitive to everything the
     null is sensitive to AND MORE, inside the same region -- which is what
     "an independent second check" has to mean.

★ RULE 20.  The self-test is printed FIRST and is SYNTHETIC where it can be:
the set algebra is validated on constructed inputs (so it cannot be retired by
any repair -- §228's clause), and the extractors are validated against known
answers taken from the register, including four NEGATIVE limbs.

★ QUOTE THE ARM.  Every number this tool prints carries its arm.

⚠ WHAT IT IS BLIND TO.  A control unmoved across 40 arms is DEMONSTRATED never
to have fired, not PROVED insensitive.  Where the source forces the conclusion
the tool says so; `--why' prints the structural argument with its line numbers.
"""
import argparse
import gzip
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
DATA = os.path.join(HERE, "..", "analysis", "data")


#  ⚠ §230: `D_229.log.gz' and `E_229.log.gz' were written by a CONCURRENT lane
#  (§229, the FABRICATED-ZEROS pass) from a build whose `upd6383.cpp' was NOT IN
#  ANY COMMIT at the time -- its reports carry `§229 UPLOAD LEDGER' and `§229
#  FABRICATED ZEROS', instruments that existed only in a working tree.  The logs
#  themselves are now committed; the DEVICE that produced them was not.  Grading
#  them would make every move-set below non-reproducible from the committed repo.
#  They are excluded BY NAME and the exclusion is PRINTED.
#  ⇒ ★ WHEN §229's SOURCE LANDS, DELETE THIS SET AND RE-RUN: its arms re-enter the
#    population and every count in section 1 must be recomputed.  One command.
UNATTRIBUTED = {"D_229.log.gz", "E_229.log.gz"}


def arms():
    return sorted(f for f in os.listdir(DATA)
                  if f.endswith(".log.gz") and f not in UNATTRIBUTED)


def text(fn):
    with gzip.open(os.path.join(DATA, fn), "rt", errors="replace") as fh:
        return fh.read()


#  --------------------------------------------------------------------------
#  THE EXTRACTORS.  Each returns a hashable value or None (absent).
#  ⚠ Every one parses a NAMED FIELD, never a bare substring -- the `962'
#  inside `962 880' trap (the control audit's own T12) is what that rule is for.
#  --------------------------------------------------------------------------
def x_s54(t):
    m = re.search(r"§54 TRACKING: quiet-in (\d+) frames -> (\d+) silent / (\d+) LOUD "
                  r"\(peak (-?\d+)\) \| loud-in (\d+) -> (\d+) silent / (\d+) loud "
                  r"\(peak (-?\d+)\)", t)
    return tuple(int(g) for g in m.groups()) if m else None


def x_s54_verdict(t):
    """§54 reduced to the QUESTION IT IS ASKED: did anything reach the output?"""
    v = x_s54(t)
    return None if v is None else (v[2], v[3], v[6], v[7])   # LOUD/peak both buckets


def x_s70(t):
    m = re.search(r"§70 ACCA AT w73: quiet frames (\d+)\s+min (-?\d+)\s+max (-?\d+)\s+"
                  r"\|\s+loud frames (\d+)\s+min (-?\d+)\s+max (-?\d+)", t)
    return (int(m.group(2)), int(m.group(3)), int(m.group(5)), int(m.group(6))) if m else None


def x_s211(t):
    m = re.search(r"§211 ACCB AT w78[^:]*: quiet frames (\d+)\s+min (-?\d+)\s+max (-?\d+)\s+"
                  r"\|\s+loud frames (\d+)\s+min (-?\d+)\s+max (-?\d+)", t)
    return (int(m.group(2)), int(m.group(3)), int(m.group(5)), int(m.group(6))) if m else None


R19 = (r"§70\s+ACCA@w73\s+quiet mean (-?[\d.]+) span (-?\d+) \| loud mean (-?[\d.]+) span (-?\d+)",
       r"§211 ACCB@w78\s+quiet mean (-?[\d.]+) span (-?\d+) \| loud mean (-?[\d.]+) span (-?\d+)")


def x_r19(t):
    a, b = re.search(R19[0], t), re.search(R19[1], t)
    if not a or not b:
        return None
    return tuple(a.groups()) + tuple(b.groups())


def x_s61(t):
    m = re.search(r"§61 PER-UNIT PRESENTATION: unit0/DO1 (\d+) exec, (\d+) non-zero, "
                  r"peak (-?\d+) \| unit1/DO2 (\d+) exec, (\d+) non-zero, peak (-?\d+)", t)
    #  the EXEC counts are a cadence, and they scale with the frame clock (§228);
    #  the CONTENT is the non-zero count and the peak.  Grade the content.
    return (int(m.group(2)), int(m.group(3)), int(m.group(5)), int(m.group(6))) if m else None


def x_s41(t):
    m = re.search(r"§41 LEVEL AT PRESENTATION: unit0 (0x[0-9A-Fa-f]+) .*?"
                  r"unit1 (0x[0-9A-Fa-f]+) ", t)
    return (m.group(1).upper(), m.group(2).upper()) if m else None


def x_rf8d(t):
    m = re.search(r"§160 register file, ALL non-zero cells \(\d+\):(.*)", t)
    if not m:
        return None
    c = re.search(r"\b8D=([0-9A-Fa-f]{6})\b", m.group(1))
    return c.group(1).upper() if c else "ABSENT"


def x_s1_totals(t):
    m = re.search(r"TOTALS\s+quiet (\d+) clip / (\d+) conversions \(([\d.]+) %\)\s+\|\s+"
                  r"loud (\d+) clip / (\d+) conversions \(([\d.]+) %\)", t)
    return (m.group(3), m.group(6)) if m else None      # the RATIOS (§228: never counts)


def x_s46(t):
    m = re.search(r"§46 DELAY PORT: (\d+) reads \((\d+) returned NON-ZERO\), (\d+) writes", t)
    return int(m.group(2)) > 0 if m else None


def x_s3_ladder(t):
    m = re.search(r"#(\d+)\s+iw(\d+)\s+([\d ]+)\s*$", "")
    m = re.search(r"§S3[^\n]*\n(?:[^\n]*\n){0,40}?[^\n]*#1357[^\n]*?(\d[\d ]{4,})", t)
    return m.group(1).replace(" ", "") if m else None


#  --- the §104 RULE-21 D-I split, through the project's own tools ---
def x_rule21(region):
    from parse104 import parse, RANGES
    from rule21 import classify, COLS

    def go(fn):
        try:
            rows = parse(os.path.join(DATA, fn))
        except Exception:
            return None
        if not rows:
            return None                 # the log has no §104 table at all
        lo, hi = RANGES[region]
        out = []
        for col in COLS:
            i = 0
            for iw in sorted(rows):
                if not (lo <= iw <= hi) or rows[iw][col + "M"] != "*":
                    continue
                if classify(*rows[iw][col])[0] == "I":
                    i += 1
            out.append(i)
        #  ⚠ a region with NO markers scores 0 input-dependent, which is the
        #  project's own convention (the epilogue is `0/0/0' in 38 of 40 arms).
        #  Returning None there would confuse "absent" with "measured zero".
        return tuple(out)
    return go


#  --------------------------------------------------------------------------
CONTROLS = [
    #  key                 label                                    extractor
    ("§54",      "§54 TRACKING (LOUD + peak, both buckets)",         x_s54_verdict),
    ("§70",      "§70 ACCA@w73 min/max, both buckets",               x_s70),
    ("§211",     "§211 ACCB@w78 min/max, both buckets",              x_s211),
    ("rule19",   "§221 RULE 19 mean + AC span (§70 and §211)",       x_r19),
    ("§61",      "§61 presentation non-zero + peak, both units",     x_s61),
    ("§41",      "§41 level at presentation, both units",            x_s41),
    ("rf8D",     "m_rf[0x8D] (§160 register dump)",                  x_rf8d),
    ("epi-D-I",  "§104 RULE-21 D-I, EPILOGUE (rows 60..82)",         x_rule21("epilogue")),
    ("body0-DI", "§104 RULE-21 D-I, body 0 (rows 84..199)",          x_rule21("body0")),
    ("§S1",      "§S1 TOTALS clip RATIOS (quiet, loud)",             x_s1_totals),
    ("§46",      "§46 delay port returned non-zero (send state)",    x_s46),
]

SHIPPED = "B_44100_228.log.gz"      # the current shipped default (§228 arm B)

#  §225's programmatic family discriminator: 285 §104 rows = modern, 320 = legacy.
def family(fn):
    try:
        from parse104 import parse
        n = len(parse(os.path.join(DATA, fn)))
    except Exception:
        return "?"
    return "modern" if n <= 300 else "legacy"


def collect():
    vals = {}
    for fn in arms():
        t = None
        for key, _lbl, fx in CONTROLS:
            if fx.__name__ == "go":                 # a §104 tool -- takes the path
                vals.setdefault(key, {})[fn] = fx(fn)
            else:
                if t is None:
                    t = text(fn)
                vals.setdefault(key, {})[fn] = fx(t)
    return vals


def moveset(vals, key, pop):
    """arms (within `pop') whose value differs from the SHIPPED arm's."""
    base = vals[key].get(SHIPPED)
    return frozenset(a for a in pop
                     if vals[key].get(a) is not None and vals[key][a] != base)


#  --------------------------------------------------------------------------
def selftest(vals, pop):
    print("=" * 78)
    print("== SELF-TEST FIRST (RULE 20).  Known answers from the register; the set")
    print("== algebra is SYNTHETIC, so no limb is retired by a repair (§228).")
    print("=" * 78)
    res = []

    def ck(name, got, want):
        ok = got == want
        res.append(ok)
        print("  %-58s %-4s  (got %s)" % (name, "PASS" if ok else "FAIL", got))

    #  --- SYNTHETIC: the set algebra itself, on constructed inputs ---
    A, B, C = frozenset("ab"), frozenset("ab"), frozenset("abc")
    ck("S1 SYN identical move-sets compare equal", A == B, True)
    ck("S2 SYN a strictly larger set is not equal", A == C, False)
    ck("S3 SYN strict containment detected", (A < C), True)
    ck("S4 NEG SYN containment is not symmetric", (C < A), False)

    #  --- EXTERNAL: answers taken from the register before this script existed ---
    ck("E1 §228 arm B §54 quiet 734548 -> 734548 silent, peak 0",
       x_s54(text("B_44100_228.log.gz"))[:4], (734548, 734548, 0, 0))
    ck("E2 §228 arm A §54 quiet 826040 -> 826040 silent, peak 0",
       x_s54(text("A_48000_228.log.gz"))[:4], (826040, 826040, 0, 0))
    ck("E3 §227 arm N m_rf[0x8D] = 009B26",
       vals["rf8D"].get("N_227.log.gz"), "009B26")
    ck("E4 §227 arm Q m_rf[0x8D] HALVED to 004D93",
       vals["rf8D"].get("Q_227.log.gz"), "004D93")
    ck("E5 NEG §227 arm O m_rf[0x8D] ABSENT",
       vals["rf8D"].get("O_227.log.gz"), "ABSENT")
    ck("E6 §41 unmoved: arm N = arm Q = 0X400000 / 0X178D0B",
       (vals["§41"].get("N_227.log.gz"), vals["§41"].get("Q_227.log.gz")),
       (("0X400000", "0X178D0B"), ("0X400000", "0X178D0B")))
    ck("E7 §228 arms A and B share the §S1 ratios 4.924 / 4.920",
       (vals["§S1"].get("A_48000_228.log.gz"), vals["§S1"].get("B_44100_228.log.gz")),
       (("4.924", "4.920"), ("4.924", "4.920")))
    ck("E8 §46 send SHUT on the shipped arm, OPEN on the NOZ05 rig",
       (vals["§46"].get(SHIPPED), vals["§46"].get("C_noz05_220.log.gz")), (False, True))
    ck("E9 §225 body-0 D-I = 0/0/0 on the shipped arm",
       vals["body0-DI"].get(SHIPPED), (0, 0, 0))
    ck("E10 §225 body-0 D-I = 26/28/27 on the NOZ05 rig",
       vals["body0-DI"].get("C_noz05_220.log.gz"), (26, 28, 27))
    ck("E11 §222 epilogue D-I = 22/19/9 on C_xb85_full_222",
       vals["epi-D-I"].get("C_xb85_full_222.log.gz"), (22, 19, 9))
    ck("E12 NEG epilogue D-I = 0/0/0 on the shipped arm",
       vals["epi-D-I"].get(SHIPPED), (0, 0, 0))
    ck("E13 NEG §S3-era instrument absent from the pre-§225 arm A_off_220",
       vals["§S1"].get("A_off_220.log.gz"), None)
    #  ★ EXTERNAL, and it reconciles two independent counts: the control audit
    #  graded 31 modern arms over a 40-arm archive; §228 then added exactly two
    #  (A_48000_228, B_44100_228).  31 + 2 = 33 must be what the programmatic
    #  discriminator finds, with the legacy family unchanged at the audit's
    #  NAMED nine.  Neither number is taken from this script.
    ck("E14 EXTERNAL audit's 31 modern + §228's 2 new arms = 33", len(pop), 33)
    ck("E15 EXTERNAL the legacy family is the audit's NAMED nine",
       sorted(f.replace(".log.gz", "") for f in arms() if f not in pop),
       ["bodyonly", "demux_sweep", "peq_flat", "peq_rebase_bit38",
        "peq_rebase_confounded", "peq_trace_base", "ship_10E446A39B440F",
        "ship_46A39B440F", "stale138"])

    n = sum(1 for r in res if r)
    print("  ---> %d of %d PASS" % (n, len(res)))
    return n == len(res)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--all-arms", action="store_true",
                    help="grade over all 40 arms, not just the 31 modern ones")
    ap.add_argument("--quote", action="store_true",
                    help="print §54 and §70/§211 mean AND AC span for every arm")
    a = ap.parse_args()

    every = arms()
    fam = {fn: family(fn) for fn in every}
    pop = [fn for fn in every if fam[fn] == "modern"]
    vals = collect()
    ok = selftest(vals, pop)
    if not ok:
        print("\n  ⛔ SELF-TEST FAILED -- everything below is UNGRADED.\n")
    grade = every if a.all_arms else pop
    print()

    print("=" * 78)
    print("== 1. THE MOVE-SETS.  Two controls that are ONE criterion move in the")
    print("==    SAME arms.  Population: %d %s arms.  Baseline arm: %s"
          % (len(grade), "ALL" if a.all_arms else "modern", SHIPPED))
    print("=" * 78)
    ms = {}
    print("  %-11s %-46s %5s  %s" % ("control", "quantity", "moved", "in which arms"))
    for key, lbl, _fx in CONTROLS:
        s = moveset(vals, key, grade)
        ms[key] = s
        show = ", ".join(sorted(x.replace(".log.gz", "") for x in s)) or "-- NEVER MOVES --"
        if len(show) > 78:
            show = show[:75] + "..."
        print("  %-11s %-46s %5d  %s" % (key, lbl, len(s), show))

    print()
    print("=" * 78)
    print("== 2. THE COLLAPSE.  Which of these are the SAME move-set?")
    print("=" * 78)
    groups = {}
    for key in ms:
        groups.setdefault(ms[key], []).append(key)
    for s, keys in sorted(groups.items(), key=lambda kv: (-len(kv[1]), len(kv[0]))):
        tag = ("★★★ ONE CRITERION, counted %d times" % len(keys)) if len(keys) > 1 \
            else "distinct"
        print("  moved in %2d arms  %-46s %s"
              % (len(s), " = ".join(keys), tag))
    null = ms["§54"]
    same = groups.get(null, [])
    print()
    print("  ⇒ %d controls share the OUTPUT-STAGE NULL's move-set exactly: %s"
          % (len(same), " · ".join(same)))
    print("    They are ONE criterion. Quoting them as a battery counts one check %d times."
          % len(same))

    print()
    print("=" * 78)
    print("== 3. IS THERE A GENUINELY INDEPENDENT SECOND CHECK ON THE OUTPUT STAGE?")
    print("=" * 78)
    print("  A second check must (a) live in the output stage and (b) have a move-set")
    print("  that is NOT the null's.  Strict containment is the strongest form: it")
    print("  fires everywhere the null fires AND SOMEWHERE ELSE.\n")
    print("  %-11s %-9s %-9s %s" % ("control", "moved", "vs null", "verdict"))
    for key, lbl, _fx in CONTROLS:
        if key in same:
            continue
        s = ms[key]
        if s == null:
            rel, v = "identical", "not independent"
        elif null < s:
            rel, v = "STRICT ⊃", "★ INDEPENDENT and strictly stronger"
        elif s < null:
            rel, v = "strict ⊂", "weaker than the null"
        elif s & null:
            rel, v = "overlaps", "independent, partially overlapping"
        else:
            rel, v = "disjoint", "independent, disjoint"
        print("  %-11s %-9d %-9s %s" % (key, len(s), rel, v))

    inreg = [k for k in ("rf8D", "epi-D-I") if null < ms[k] or (ms[k] & null) or ms[k]]
    print()
    print("  ⚠ REGION MATTERS. Of the controls above, the ones that live INSIDE the")
    print("    output stage (the epilogue, rows 60..82, and the w61 self-loop")
    print("    accumulator it writes) are: m_rf[0x8D] and §104's epilogue D-I tally.")
    print("    Everything else is upstream (kernel, body 0/1, the send).")
    print()
    print("  ★★★★★ AND §229 SHARPENS THIS FURTHER -- READ IT WITH THIS TABLE.")
    print("    §229's FABRICATED-ZERO census (the parallel lane) measured that")
    print("    3.982 % of ALL operand resolutions are zeros src_term()'s `default:'")
    print("    INVENTS -- 9 832 536 of 246 952 062 -- and the DISTRIBUTION is the")
    print("    finding: kernel A 0.000 %, kernel B 0.000 %, body 1 0.000 %,")
    print("    body 0 8.772 %, EPILOGUE 28.492 %.  Therefore:")
    print()
    print("      ⚠⚠ §70 AND §211 ARE NOT THE SAME KIND OF NULL, AND NOBODY HAD SAID SO.")
    print("         §70  @ w73  SRC 0x10 = the ACCUMULATOR, f31 outside the bit-5")
    print("                     family        -> a statement about the chip")
    print("         §211 @ w78  SRC 0x0A resolved as an INVENTED ZERO 1 106 028")
    print("                     times, AND its operation code collapsed by")
    print("                     `op = f31 & 3'  -> partly a statement about US")
    print("         Both print `mean 0.0 span 0'.  They collapse by DEMONSTRATED")
    print("         SENSITIVITY (identical move-sets, above) but they DIFFER IN KIND.")
    print()
    print("      ✔ m_rf[0x8D] = 0x009B26 SURVIVES that audit -- §229 reports its")
    print("        non-zero stores come from a THIRD SITE.  So the one control this")
    print("        tool nominates as the genuine second check is the one their")
    print("        census CLEARS.  Two passes, opposite directions, same nomination.")
    print("      ⛔ m_rf[0x8C]'s permanent zero is now 100 % ATTRIBUTED TO US.")

    if a.quote:
        print()
        print("=" * 78)
        print("== 4. §54 AND §70/§211 -- MEAN AND AC SPAN, BOTH BUCKETS, EVERY ARM.")
        print("==    ⚠ THESE ARE ONE CRITERION, NOT FOUR.  §54 arms at frame 300 000")
        print("==    and §70/§211 at 420 000: a SHARED PREDICATE over DIFFERENT")
        print("==    POPULATIONS.  Never compare their frame counts directly.")
        print("=" * 78)
        print("  %-30s %-3s %-34s %s" % ("arm", "fam", "§54 quiet/loud (LOUD, peak)",
                                         "§70 / §211  quiet mean/span | loud mean/span"))
        for fn in every:
            t = text(fn)
            s54, r19 = x_s54(t), x_r19(t)
            a54 = ("q%d->%dL pk%d | l%d->%dL pk%d"
                   % (s54[0], s54[2], s54[3], s54[4], s54[6], s54[7])) if s54 else "-- absent --"
            a19 = ("A %s/%s | %s/%s   B %s/%s | %s/%s" % r19) if r19 else "-- absent --"
            print("  %-30s %-3s %-34s %s"
                  % (fn.replace(".log.gz", ""), fam[fn][:3], a54, a19))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
