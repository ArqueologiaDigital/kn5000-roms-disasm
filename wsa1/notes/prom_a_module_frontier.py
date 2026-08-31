#!/usr/bin/env python3
"""Which whole THUNK MODULE should prom_a convert next?

QUESTION IT ANSWERS
    notes/prom_a_call_graph.py ranks individual thunk SLOTS by reference count.
    That is the wrong unit of work: wave 4 established in prom_b (see
    notes/prom_b_module_frontier.py, which this file is the prom_a twin of) that
    the cheap conversion is a whole CONTIGUOUS RUN of the directory, because one
    span of source closes one `.incbin` instead of fragmenting several.

    For every run of consecutive `jp` slots in prom_b's 0xF40000 thunk table,
    keep the slots whose target is in prom_a (0xF80000-0xFFFFFF) and report
      * how many of those are still unconverted (target inside an `.incbin` of
        prom_a/wsa1_prom_a.s),
      * the unconverted target range and its byte extent,
      * how many of those bytes lie inside ONE `.incbin` span -- a run whose
        targets straddle several spans is fragmented work,
      * the summed reference upper bound of its unconverted slots.
    Ranked by CONTIGUOUS unconverted extent.

WHAT IS EXACT AND WHAT IS NOT
    EXACT: the run decomposition and the slot targets (bytes of the ROM, via
    scripts/analysis/prom_b_thunk_table.py's classifier), and the
    converted/unconverted split (parsed from the .s's own `.incbin` directives,
    which the byte gate re-checks).
    NOT EXACT: the reference counts, which are prom_a_call_graph.py's
    opcode-anchored UPPER BOUND -- they rank, they do not count calls.  And the
    extent of a run is max-min over the addresses its slots NAME: it is what the
    directory publishes, not a measurement of where the module's code ends.
    ⚠ A run's targets can also be the ONLY thing the directory knows about a
    module; a module with no thunk slots at all is invisible here.  Use
    notes/prom_a_codemap.py and the `.incbin` list itself for those.

RUN
    python3 notes/prom_a_module_frontier.py             # ranked runs
    python3 notes/prom_a_module_frontier.py --n 30
    python3 notes/prom_a_module_frontier.py --at 0xF4088C   # one run, every slot
    python3 notes/prom_a_module_frontier.py --spans        # the .incbin ledger
    python3 notes/prom_a_module_frontier.py --selftest
Exit status is non-zero if a self-check fails.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_a_call_graph as CG                                    # noqa: E402

A_LO, A_HI = 0xF80000, 0x1000000
FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-62s %-20s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def spans():
    """[(lo_addr, hi_addr)] still-.incbin ADDRESS ranges of prom_a."""
    return [(A_LO + lo, A_LO + hi) for lo, hi in CG.incbin_ranges()]


def span_of(addr, sp):
    for lo, hi in sp:
        if lo <= addr < hi:
            return (lo, hi)
    return None


def survey():
    a, b = CG.load()
    sp = spans()
    rc = CG.refcounts(a, b)
    slots = CG.jp_slots(b)
    out = []
    for run in CG.modules(slots):
        mine = [(s, slots[s]) for s in run if A_LO <= slots[s] < A_HI]
        unc = [(s, t) for s, t in mine if span_of(t, sp) is not None]
        if not unc:
            continue
        tg = [t for _, t in unc]
        by_span = {}
        for t in tg:
            by_span.setdefault(span_of(t, sp), []).append(t)
        best = max(by_span.items(), key=lambda kv: max(kv[1]) - min(kv[1]))
        out.append(dict(
            first=run[0], last=run[-1], n=len(run), na=len(mine), nunc=len(unc),
            lo=min(tg), hi=max(tg), extent=max(tg) - min(tg),
            nspans=len(by_span), cspan=best[0],
            cextent=max(best[1]) - min(best[1]), cslots=len(best[1]),
            refs=sum(rc.get(s, 0) for s, _ in unc), slots=unc))
    return out


def main():
    argv = sys.argv[1:]
    if "--selftest" in argv:
        return selftest()
    if "--spans" in argv:
        tot = 0
        print("prom_a .incbin spans, largest first")
        for lo, hi in sorted(spans(), key=lambda r: r[0] - r[1]):
            print("  0x%06X-0x%06X  %7d bytes" % (lo, hi, hi - lo))
            tot += hi - lo
        print("  %d span(s), %d bytes" % (len(spans()), tot))
        return 0
    rows = survey()
    if "--at" in argv:
        a, b = CG.load()
        rc = CG.refcounts(a, b)
        at = int(argv[argv.index("--at") + 1], 16)
        for r in [x for x in rows if x["first"] <= at <= x["last"]]:
            print("run T_%06X-T_%06X  %d slots, %d into prom_a, %d unconverted"
                  % (r["first"], r["last"], r["n"], r["na"], r["nunc"]))
            print("  unconverted targets span 0x%06X-0x%06X (%d bytes) across "
                  "%d .incbin span(s)" % (r["lo"], r["hi"], r["extent"], r["nspans"]))
            for s, t in r["slots"]:
                print("    T_%06X -> 0x%06X  x%d" % (s, t, rc.get(s, 0)))
        return 0
    n = int(argv[argv.index("--n") + 1]) if "--n" in argv else 20
    rows.sort(key=lambda r: (-r["cextent"], -r["nunc"]))
    print("prom_a thunk RUNS with unconverted prom_a targets: %d" % len(rows))
    print("ranked by contiguous unconverted target extent")
    print("  %-22s %5s %5s %9s %8s %6s %6s" %
          ("run", "slots", "unc", "extent", "1span", "spans", "refs"))
    for r in rows[:n]:
        print("  T_%06X-T_%06X %5d %5d %9d %8d %6d %6d   0x%06X-0x%06X"
              % (r["first"], r["last"], r["n"], r["nunc"], r["extent"],
                 r["cextent"], r["nspans"], r["refs"], r["lo"], r["hi"]))
    return 0


def selftest():
    """Asserts only things that survive a conversion, and always on the LAST
    element of a list -- the trap notes/prom_b_module_frontier.py's docstring
    records is a self-test that hard-codes today's top run and starts failing the
    moment that run is converted."""
    a, b = CG.load()
    sp = spans()
    rows = survey()
    rows.sort(key=lambda r: (-r["cextent"], -r["nunc"]))
    check("runs with unconverted prom_a targets exist", len(rows) > 0, True)
    if not rows:
        print("SELFTEST FAIL")
        return 1
    top = rows[0]
    o = top["last"] - 0xF00000
    check("top run's LAST slot is a `jp nnn` (opcode 0x1B)", b[o], 0x1B)
    check("its target matches what survey() reported",
          int.from_bytes(b[o + 1:o + 4], "little"), top["slots"][-1][1])
    check("that target is inside an .incbin",
          span_of(top["slots"][-1][1], sp) is not None, True)
    check("every unconverted slot of the top run is inside an .incbin",
          all(span_of(t, sp) is not None for _, t in top["slots"]), True)
    check("nunc never exceeds the run's prom_a-targeting slot count",
          [r["first"] for r in rows if r["nunc"] > r["na"]], [])
    check("cextent never exceeds extent",
          [r["first"] for r in rows if r["cextent"] > r["extent"]], [])
    check("no reported target lies below 0xF80000",
          [t for r in rows for _, t in r["slots"] if t < A_LO], [])
    # the LAST unconverted slot in table order must belong to a reported run
    last = None
    slots = CG.jp_slots(b)
    for run in CG.modules(slots):
        for s in run:
            t = slots[s]
            if A_LO <= t < A_HI and span_of(t, sp) is not None:
                last = (run[0], s, t)
    check("an unconverted slot still exists to test with", last is not None, True)
    if last:
        first, s, t = last
        check("the run owning the LAST unconverted slot (T_%06X -> 0x%06X) is "
              "reported" % (s, t),
              ["0x%06X" % r["first"] for r in rows if r["first"] == first],
              ["0x%06X" % first])
    # cross-check the .incbin ledger against the INDEPENDENT parser in
    # scripts/analysis/source_coverage.py.  (An earlier draft compared the total
    # against itself -- a check that cannot fail, which is not a check.)
    import subprocess
    out = subprocess.run([sys.executable,
                          os.path.join(ROOT, "scripts", "analysis",
                                       "source_coverage.py")],
                         capture_output=True, text=True).stdout
    want = None
    for line in out.split("\n"):
        f = line.split()
        if f[:1] == ["prom_a"]:
            want = int(f[f.index("incbin") - 1].replace(",", ""))
    check("summed .incbin length agrees with source_coverage.py",
          sum(hi - lo for lo, hi in CG.incbin_ranges()), want)
    print("SELFTEST", "FAIL" if FAIL else "PASS")
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
