#!/usr/bin/env python3
"""How well DOCUMENTED is this disassembly? The goal metric, per image.

QUESTION IT ANSWERS
    "The byte gate says the bytes are right. What says the disassembly is
     UNDERSTOOD -- how many routines carry a semantic name rather than
     sub_XXXXXX, how many carry an Evidence: line, and how many have a real
     header comment?"

WHY IT EXISTS
    The project goal is a perfectly byte-matching AND well-documented
    disassembly.  Byte-matching has a gate; documentation had no instrument at
    all, so every report reached for coverage instead -- the number that is easy
    to measure rather than the one that matters.  Worse, the two move in
    OPPOSITE directions: converting a span imports every routine inside it and
    none is born with a name.  Measured across wave 7:

        span 0xFAD800   18,432 B   84 labels,   0 semantic   -> sub_ +82
        span 0xFA5AEB   17,685 B  227 labels, 100 semantic   -> sub_ +18

    Same size of territory, a quarter of the damage, because the second lane
    named as it went.  That comparison is the argument for this script existing.

WHAT COUNTS AS WHAT
    * A label matching sub_[0-9A-F]{6} is UNNAMED. Anything else at column 0
      ending in ':' is a SEMANTIC name.  Compiler-local .L labels are excluded
      -- counting them was a real error in a wave-7 audit (they inflated a
      label count by 8,237).
    * An "Evidence:" line is a comment line stating why a name is what it is.
    * A HEADER is a comment block of >= 3 consecutive comment lines immediately
      above a label -- the house style used around DSP_ChanFreq_CurvePool.

RUN
    python3 notes/wave7_documentation_metrics.py
    python3 notes/wave7_documentation_metrics.py --range a 0xFA5AEB 0xFAA000
    python3 notes/wave7_documentation_metrics.py --selftest    # 14 checks
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMAGES = [("prom_a", "wsa1_prom_a.s", 0xF80000), ("prom_b", "wsa1_prom_b.s", 0xF00000),
          ("prom_c", "wsa1_prom_c.s", 0xF80000), ("prom_d", "wsa1_prom_d.s", 0x000000)]

EV_ADDRS = {}
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
UNNAMED = re.compile(r'^sub_[0-9A-Fa-f]{6}$')
ADDR_COMMENT = re.compile(r';\s*([0-9A-F]{6})\b')


def scan(path, want_ev=False):
    """Walk the source once, classifying every label and the comment block above it."""
    lines = open(os.path.join(ROOT, path)).read().split("\n")
    named, unnamed, with_header, with_evidence = [], [], 0, 0
    run = 0                      # consecutive comment lines immediately above
    last_addr = None
    ev_in_block = False
    for ln in lines:
        m = ADDR_COMMENT.search(ln)
        if m:
            last_addr = int(m.group(1), 16)
        if ln.startswith(";"):
            run += 1
            if "Evidence:" in ln:
                ev_in_block = True
            continue
        lm = LABEL.match(ln)
        if lm:
            name = lm.group(1)
            (unnamed if UNNAMED.match(name) else named).append((name, last_addr))
            if run >= 3:
                with_header += 1
            if ev_in_block:
                with_evidence += 1
                EV_ADDRS.setdefault(path, set()).add(last_addr)
        run, ev_in_block = 0, False
    return named, unnamed, with_header, with_evidence


def report(rng=None):
    tn = tu = th = te = 0
    print("%-8s %10s %10s %9s %9s %9s" % ("image", "semantic", "sub_XXXX", "named%", "headers", "evidence"))
    for tag, src, _base in IMAGES:
        named, unnamed, hdr, ev = scan(os.path.join(tag, src))
        n, u = len(named), len(unnamed)
        tn, tu, th, te = tn + n, tu + u, th + hdr, te + ev
        pct = (100.0 * n / (n + u)) if (n + u) else 0.0
        print("%-8s %10s %10s %8.1f%% %9s %9s"
              % (tag, format(n, ","), format(u, ","), pct, format(hdr, ","), format(ev, ",")))
    pct = (100.0 * tn / (tn + tu)) if (tn + tu) else 0.0
    print("%-8s %10s %10s %8.1f%% %9s %9s"
          % ("TOTAL", format(tn, ","), format(tu, ","), pct, format(th, ","), format(te, ",")))
    print("\n★ named%% is the goal metric. prom_a is the weak image at 26.2%%; prom_c is 91.8%%.")
    print("  prom_d is 100%% named but has ZERO Evidence: lines -- its labels are generated")
    print("  structure names, so 'named' there means 'framed', not 'understood'.")
    print("  ★ named%% is the goal metric. Coverage measures TERRITORY; this measures MEANING,")
    print("  and converting a span moves the two in OPPOSITE directions unless the lane names")
    print("  as it goes. The gate is blind to every number on this page.")


def in_range(tag, lo, hi):
    key = tag if tag.startswith("prom_") else "prom_" + tag
    src = dict((t, s) for t, s, _b in IMAGES)[key]
    named, unnamed, _h, _e = scan(os.path.join(key, src))
    n = [x for x in named if x[1] is not None and lo <= x[1] < hi]
    u = [x for x in unnamed if x[1] is not None and lo <= x[1] < hi]
    ev = len([a for a in EV_ADDRS.get(os.path.join(key, src), set())
              if a is not None and lo <= a < hi])
    print("prom_%s 0x%06X-0x%06X: %d labels, %d semantic, %d sub_XXXXXX, %d with an Evidence: line"
          % (key[-1], lo, hi, len(n) + len(u), len(n), len(u), ev))
    return len(n), len(u), ev


def selftest():
    ok = fail = 0

    def check(desc, cond):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc)
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    tot_u = 0
    for tag, src, _b in IMAGES:
        named, unnamed, hdr, ev = scan(os.path.join(tag, src))
        tot_u += len(unnamed)
        check("%s: every 'unnamed' really matches sub_ + 6 hex" % tag,
              all(UNNAMED.match(n) for n, _a in unnamed))
        check("%s: no semantic name is a sub_XXXXXX in disguise" % tag,
              not any(UNNAMED.match(n) for n, _a in named))
        check("%s: no .L compiler-local counted as a label (they inflated a count by 8,237)" % tag,
              not any(n.startswith(".L") for n, _a in named + unnamed))
    # agrees with the independent grep the handoff documents
    import subprocess
    g = subprocess.run("grep -rhoE '^sub_[0-9A-Fa-f]{6}:' prom_*/*.s | sort -u | wc -l",
                       shell=True, cwd=ROOT, capture_output=True, text=True).stdout.strip()
    # ⚠ The documented grep pipes through `sort -u`, so it counts DISTINCT NAMES.
    # prom_a and prom_c are BOTH based at 0xF80000, so the same sub_XXXXXX name can
    # legitimately exist in both files and is two different routines. This script
    # counts ROUTINES; the grep counts names. The difference is real and is checked
    # here rather than papered over -- quoting one number for the other would
    # undercount the work still to do.
    allnames = []
    for _t, _s, _b in IMAGES:
        allnames += [n for n, _a in scan(os.path.join(_t, _s))[1]]
    dupes = len(allnames) - len(set(allnames))
    check("routines (%d) minus cross-file duplicate NAMES (%d) equals the documented grep (%s)"
          % (tot_u, dupes, g), tot_u - dupes == int(g))
    check("every duplicate name is shared between prom_a and prom_c, which share base 0xF80000",
          all(sum(1 for _t, _s, _b in IMAGES
                  if n in [x for x, _a in scan(os.path.join(_t, _s))[1]]) <= 2
              for n in set(x for x in allnames if allnames.count(x) > 1)))
    # the two wave-7 conversions, checked on the LAST one as well as the first
    # ★ THE COMPARISON THIS SCRIPT EXISTS FOR. Two prom_a spans of near-identical
    # size, converted the same day by the same recipe, differing only in whether the
    # lane named as it went. NOTE the two criteria are different and both are real:
    # a SEMANTIC NAME is not the same as a name carrying an EVIDENCE line, and the
    # second is the stricter one. A wave-7 report quoted 100 for this span; that was
    # its evidence count, and its semantic count is 193.
    n1, u1, e1 = in_range("a", 0xFAD800, 0xFB2000)
    check("0xFAD800: 84 labels, 0 semantic, 0 evidenced -- the conversion that named nothing",
          (n1 + u1, n1, e1) == (84, 0, 0))
    n2, u2, e2 = in_range("a", 0xFA5AEB, 0xFAA000)
    check("0xFA5AEB: 227 labels, 193 semantic -- the conversion that named as it went",
          (n2 + u2, n2) == (227, 193))
    # ⚠ This script measures 103; the lane's own report said 100. The 3 are labels
    # whose Evidence line sits in a comment block this script attributes to a
    # neighbouring label. Recorded as a stated discrepancy rather than silently
    # adopting whichever number is convenient -- neither is wrong, they are
    # different attribution rules, and a reader deserves to know the tolerance.
    check("...of which 103 carry an Evidence: line by THIS script's attribution"
          " (the lane reported 100; the 3 are block-boundary attribution)", e2 == 103)
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if "--range" in sys.argv:
        i = sys.argv.index("--range")
        in_range(sys.argv[i + 1], int(sys.argv[i + 2], 16), int(sys.argv[i + 3], 16))
        sys.exit(0)
    report()
