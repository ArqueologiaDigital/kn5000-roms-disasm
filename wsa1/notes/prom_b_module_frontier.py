#!/usr/bin/env python3
"""Which whole THUNK MODULE should prom_b convert next?

QUESTION IT ANSWERS
    notes/prom_b_call_graph.py ranks individual thunk SLOTS; notes/
    prom_b_thunk_modules.py groups slots into RUNS.  Neither says which run is
    the best next unit of work, because a run's value depends on how much of
    its target range is still `.incbin`.  This joins the two:

      for every run of the thunk table, keep the slots whose target is in
      prom_b (0xF00000-0xF7FFFF), and report
        * how many of those slots are still unconverted (i.e. their target
          address is inside an `.incbin` of prom_b/wsa1_prom_b.s),
        * the unconverted target range [min,max] and its byte extent,
        * how many of those bytes are inside one single `.incbin` span
          (a run whose targets straddle several spans is fragmented work),
        * the summed reference upper bound of its unconverted slots.

    Ranked by CONTIGUOUS unconverted bytes, because the wave-3 lesson is that
    large contiguous blocks close `.incbin` spans instead of fragmenting them.

WHAT IS EXACT AND WHAT IS NOT
    EXACT: the run decomposition (imported from prom_b_thunk_modules, which
    imports its slot classifier from the committed
    scripts/analysis/prom_b_thunk_table.py), the converted/unconverted split
    (parsed from the .s's own `.incbin` directives, which the build gate
    re-checks byte for byte), and the target addresses.
    NOT EXACT: the reference counts, which are the byte-window upper bound
    prom_b_call_graph.py computes.  They rank; they are not call counts.
    The byte extent of a run is max-min over its own targets -- it is what the
    run's slots NAME, not a measurement of where the module's code ends.

RUN
    python3 notes/prom_b_module_frontier.py               # ranked runs
    python3 notes/prom_b_module_frontier.py --n 25
    python3 notes/prom_b_module_frontier.py --at 0xF428B0 # one run, every slot
    python3 notes/prom_b_module_frontier.py --selftest
Exit status is non-zero if a self-check fails.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_thunk_modules as TM                                 # noqa: E402
import prom_b_call_graph as CG                                    # noqa: E402

B_LO, B_HI = 0xF00000, 0xF80000
FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-58s %-22s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def spans():
    """[(lo_addr, hi_addr)] still-.incbin ADDRESS ranges of prom_b."""
    return [(B_LO + lo, B_LO + hi) for lo, hi in CG.incbin_ranges()]


def span_of(addr, sp):
    for lo, hi in sp:
        if lo <= addr < hi:
            return (lo, hi)
    return None


def refcounts():
    a, b = CG.load()
    return CG.refcounts(a, b)


def survey():
    sp = spans()
    rc = refcounts()
    out = []
    for run in TM.runs():
        slots = [(s, t) for s, k, t in run if t is not None and B_LO <= t < B_HI]
        unc = [(s, t) for s, t in slots if span_of(t, sp) is not None]
        if not unc:
            continue
        tg = [t for _, t in unc]
        # bytes of the unconverted target range that lie in ONE incbin span
        by_span = {}
        for t in tg:
            by_span.setdefault(span_of(t, sp), []).append(t)
        best = max(by_span.items(), key=lambda kv: max(kv[1]) - min(kv[1]))
        out.append(dict(
            first=run[0][0], last=run[-1][0], n=len(run),
            nb=len(slots), nunc=len(unc),
            lo=min(tg), hi=max(tg), extent=max(tg) - min(tg),
            nspans=len(by_span),
            cspan=best[0], cextent=max(best[1]) - min(best[1]),
            cslots=len(best[1]),
            refs=sum(rc.get(s, 0) for s, _ in unc),
            slots=unc))
    return out


def main():
    argv = sys.argv[1:]
    if "--selftest" in argv:
        return selftest()
    rows = survey()
    if "--at" in argv:
        a = int(argv[argv.index("--at") + 1], 16)
        rows = [r for r in rows if r["first"] <= a <= r["last"]]
        for r in rows:
            print("run T_%06X-T_%06X  %d slots, %d into prom_b, %d unconverted"
                  % (r["first"], r["last"], r["n"], r["nb"], r["nunc"]))
            print("  unconverted targets span 0x%06X-0x%06X (%d bytes) across %d .incbin span(s)"
                  % (r["lo"], r["hi"], r["extent"], r["nspans"]))
            for s, t in r["slots"]:
                print("    T_%06X -> 0x%06X  x%d" % (s, t, refcounts().get(s, 0)))
        return 0
    n = int(argv[argv.index("--n") + 1]) if "--n" in argv else 20
    rows.sort(key=lambda r: (-r["cextent"], -r["nunc"]))
    print("prom_b thunk RUNS with unconverted prom_b targets: %d" % len(rows))
    print("ranked by contiguous unconverted target extent")
    print("  %-22s %5s %5s %9s %8s %6s %6s" %
          ("run", "slots", "unc", "extent", "1span", "spans", "refs"))
    for r in rows[:n]:
        print("  T_%06X-T_%06X %5d %5d %9d %8d %6d %6d   0x%06X-0x%06X"
              % (r["first"], r["last"], r["n"], r["nunc"], r["extent"],
                 r["cextent"], r["nspans"], r["refs"], r["lo"], r["hi"]))
    return 0


def selftest():
    """Asserts on the LAST element of every list it builds, not the first, and
    on invariants that survive a conversion -- an earlier draft hard-coded the
    then-top run (T_F428B0) and would have started FAILING the moment that run
    was converted, which is the opposite of what a self-test is for."""
    sp = spans()
    rows = survey()
    rows.sort(key=lambda r: (-r["cextent"], -r["nunc"]))
    check("runs with unconverted prom_b targets", len(rows) > 0, True)
    top = rows[0]
    # everything about the top run is re-derived from the ROM, not typed
    d = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    o = top["last"] - B_LO
    check("top run's LAST slot is a `jp nnn` (opcode 0x1B)", d[o], 0x1B)
    check("its target matches what survey() reported",
          int.from_bytes(d[o + 1:o + 4], "little"), top["slots"][-1][1])
    check("that target is inside an .incbin", span_of(top["slots"][-1][1], sp) is not None,
          True)
    check("every unconverted slot of the top run is inside an .incbin",
          all(span_of(t, sp) is not None for _, t in top["slots"]), True)
    check("nunc never exceeds the run's prom_b-targeting slot count",
          [r["first"] for r in rows if r["nunc"] > r["nb"]], [])
    check("cextent never exceeds extent",
          [r["first"] for r in rows if r["cextent"] > r["extent"]], [])
    # runs this tree has already converted must be GONE from the frontier
    for run, what in ((0xF42770, "the block store, 0xF62C00"),
                      (0xF428B0, "the song-store commands, 0xF7AA00"),
                      (0xF42880, "the block-store allocator, 0xF7A400"),
                      (0xF40B40, "0xF47800, round 3"),
                      (0xF40BC0, "0xF49800, round 3"),
                      (0xF40C50, "0xF4D000, round 3"),
                      (0xF40CB0, "0xF4E000, round 3"),
                      (0xF40CE0, "0xF4EC00, round 3"),
                      (0xF40D60, "0xF4E32A, round 3"),
                      (0xF414B0, "0xF4C800, round 3"),
                      (0xF434E0, "0xF4C3F2, round 3")):
        check("converted run T_%06X (%s) is absent" % (run, what),
              [r["first"] for r in rows if r["first"] == run], [])
    # ...and a run that IS unconverted must be PRESENT.
    # ⚠ DERIVED, never typed.  The previous draft named T_F40C50 here and started
    # FAILING the moment round 3 converted it -- the same defect the docstring
    # above says an earlier draft already had with T_F428B0.  A self-test that
    # breaks on success is the opposite of one, so this now takes the LAST `jp`
    # slot in table order whose target is still inside an `.incbin` and asserts
    # that survey() reports the run owning it.  It can only stop discriminating
    # when the frontier is empty, and the first check above catches that.
    last_unc = None
    for run in TM.runs():
        for sl, k, t in run:
            if t is not None and B_LO <= t < B_HI and span_of(t, sp) is not None:
                last_unc = (run[0][0], sl, t)
    check("an unconverted slot still exists to test with", last_unc is not None, True)
    if last_unc:
        first, sl, t = last_unc
        check("the run owning the LAST unconverted slot (T_%06X -> 0x%06X) is "
              "present" % (sl, t),
              [("0x%06X" % r["first"]) for r in rows if r["first"] == first],
              ["0x%06X" % first])
    print("SELFTEST", "FAIL" if FAIL else "PASS")
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
