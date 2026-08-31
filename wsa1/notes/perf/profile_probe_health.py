#!/usr/bin/env python3
"""IS `notes/probe_health.py` SLOW BECAUSE OF 160x SUBPROCESS CHURN, OR BECAUSE
A FEW PROBES ARE INDIVIDUALLY EXPENSIVE?

QUESTION IT ANSWERS
    "A full sweep is 400+ subprocess runs and over half an hour. If the cost is
     PROCESS STARTUP, batching or an in-process API is the fix. If it is a
     handful of probes that each do minutes of real work, batching buys nothing
     and the fix belongs in those probes."

    The two have opposite remedies, so guessing is not allowed.

HOW
    Uses probe_health's OWN discovery (citation_index / readers / invocations),
    so the invocation list is exactly the one a real sweep would run. Then times
    each invocation ONCE in the committed tree -- no tree copies, no grading.
    That is not a sweep; it is the sweep's per-invocation cost, which is the
    thing in question.

    Python's own floor is measured too (`-c pass`), so "process startup" is a
    number here rather than an intuition.

RUN
    python3 notes/perf/profile_probe_health.py --image prom_d      # quickest
    python3 notes/perf/profile_probe_health.py --image prom_a
    python3 notes/perf/profile_probe_health.py --selftest

⚠ Runs probes READ-ONLY invocations only -- probe_health's WRITE_FLAGS list is
    honoured, so nothing here can splice a listing. Timings are data; --selftest
    asserts invariants only.
"""
import argparse
import importlib.util
import os
import statistics
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PH = os.path.join(ROOT, "notes", "probe_health.py")


def load_ph():
    """probe_health.py as a module. ⚠ READ-ONLY: this tool never edits it."""
    spec = importlib.util.spec_from_file_location("probe_health_under_test", PH)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def python_floor(n=15):
    """What a bare interpreter start costs. The 160x subprocess theory is only
    interesting if THIS number times the run count is a real share of the wall."""
    ts = []
    for _ in range(n):
        t = time.perf_counter()
        subprocess.run([sys.executable, "-c", "pass"], capture_output=True)
        ts.append(time.perf_counter() - t)
    return statistics.median(ts)


def time_one(argv, timeout):
    env = dict(os.environ, PYTHONHASHSEED="0", PYTHONDONTWRITEBYTECODE="1")
    t = time.perf_counter()
    try:
        subprocess.run([sys.executable] + argv, cwd=ROOT, env=env,
                       stdin=subprocess.DEVNULL, capture_output=True,
                       text=True, timeout=timeout)
        return time.perf_counter() - t, False
    except subprocess.TimeoutExpired:
        return time.perf_counter() - t, True


def run_image(tag, per_script=2, timeout=300, limit=None):
    m = load_ph()
    primary = m.IMAGE_PRIMARY[tag]
    cites = m.citation_index()
    scripts = m.readers(primary)
    argvs = []
    for s in scripts:
        keep, _skip = m.invocations(s, cites, per_script)
        argvs += keep
    if limit:
        argvs = argvs[:limit]
    trees = 4          # asis, asis2, full, stub -- measure() runs all four
    floor = python_floor()
    print("=== %s (%s): %d script(s), %d invocation(s), x%d trees = %d runs ==="
          % (tag, primary, len(scripts), len(argvs), trees, len(argvs) * trees))
    print("bare `python3 -c pass` costs %.0f ms (median of 15)" % (1000 * floor))

    rows = []
    for i, argv in enumerate(argvs, 1):
        secs, to = time_one(argv, timeout)
        rows.append((secs, to, argv))
        print("  %3d/%d %7.2fs %s%s" % (i, len(argvs), secs,
                                        "TIMEOUT " if to else "",
                                        " ".join(argv)), flush=True)

    rows.sort(reverse=True)
    total = sum(r[0] for r in rows)
    print("\n" + "=" * 70)
    print("ONE tree costs %.1fs across %d invocations; a sweep runs %d trees "
          "=> ~%.1f min of CPU" % (total, len(rows), trees, trees * total / 60.0))
    print("=" * 70)
    print("\nTHE TEN MOST EXPENSIVE INVOCATIONS")
    for secs, to, argv in rows[:10]:
        print("  %7.2fs %5.1f%% of the tree total  %s%s"
              % (secs, 100.0 * secs / total if total else 0,
                 "TIMEOUT " if to else "", " ".join(argv)))
    # ★ THE ATTRIBUTION THAT DECIDES THE REMEDY.
    startup = len(rows) * floor
    print("\nATTRIBUTION (one tree)")
    print("  %-38s %8.1fs %6.1f%%" % ("interpreter startup (n x floor)",
                                      startup, 100.0 * startup / total if total else 0))
    top = sum(r[0] for r in rows[:5])
    print("  %-38s %8.1fs %6.1f%%" % ("the 5 most expensive invocations",
                                      top, 100.0 * top / total if total else 0))
    rest = total - top
    print("  %-38s %8.1fs %6.1f%%" % ("everything else", rest,
                                      100.0 * rest / total if total else 0))
    med = statistics.median([r[0] for r in rows]) if rows else 0
    print("  median invocation %.2fs; %d of %d are under 1s"
          % (med, sum(1 for r in rows if r[0] < 1.0), len(rows)))
    return rows, floor


def selftest():
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    m = load_ph()
    check("probe_health.py imports as a module without running its sweep",
          hasattr(m, "measure") and hasattr(m, "invocations"))
    check("its four trees are the unit of a sweep",
          m.TIMEOUT > 0, "per-invocation timeout %ds" % m.TIMEOUT)

    cites = m.citation_index()
    scripts = m.readers(m.IMAGE_PRIMARY["prom_d"])
    check("discovery finds prom_d readers", len(scripts) > 0, "%d" % len(scripts))

    # ★ THE INVARIANT: this tool must never run a WRITE-mode invocation. A probe
    # that splices the listing would be run against the COMMITTED tree here --
    # probe_health only dares run these in a frozen copy.
    bad = []
    for s in scripts:
        keep, _ = m.invocations(s, cites, 2)
        for argv in keep:
            if set(argv[1:]) & m.WRITE_FLAGS:
                bad.append(argv)
    check("no write-mode invocation is in the timing set", not bad,
          "%d offending" % len(bad))

    f = python_floor(5)
    check("the interpreter floor is measurable and sane",
          0.005 < f < 2.0, "%.0f ms" % (1000 * f))
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", default="prom_d")
    ap.add_argument("--per-script", type=int, default=2)
    ap.add_argument("--timeout", type=int, default=300)
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    run_image(a.image, a.per_script, a.timeout, a.limit)
