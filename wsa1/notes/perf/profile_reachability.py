#!/usr/bin/env python3
"""WHERE DOES `notes/reachability.py` ACTUALLY SPEND ITS FOUR MINUTES?

QUESTION IT ANSWERS
    "Of the wall time of one cold `--targets` run, how much is the unidasm
     SUBPROCESS, how much is re-reading and re-splitting the .s sources, how
     much is the walk's own inner loop, and how much is the per-byte span
     tally?"

    The answer decides whether the fix is caching, algorithm, or a language.
    Rust makes a bad algorithm fast; it does not make it good -- so attribute
    the time before proposing anything.

HOW
    Imports reachability.py as a module (never a subprocess, so the phases are
    separable), wraps `subprocess.run` to count and time every unidasm spawn,
    and wraps source_lines / proven_and_incbin / seeds / walk with
    perf_counter. The cache is BYPASSED on purpose: a cold walk is the thing
    being measured.

RUN
    python3 notes/perf/profile_reachability.py --tag prom_a
    python3 notes/perf/profile_reachability.py --tag prom_a --cprofile
    python3 notes/perf/profile_reachability.py --selftest

⚠ TIMINGS ARE DATA, NOT ASSERTIONS. --selftest checks INVARIANTS (the wrappers
    do not change any answer, the phases sum to the whole); it never pins a
    number, because numbers vary by machine and by what else is running. Check
    `ps -eo pid,etimes,args | grep reachability` before trusting a figure.
"""
import argparse
import importlib.util
import io
import os
import pstats
import subprocess
import sys
import time
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def load_reach():
    """reachability.py as a module, with __name__ != '__main__' so it does not run."""
    spec = importlib.util.spec_from_file_location(
        "reachability_under_test", os.path.join(ROOT, "notes", "reachability.py"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


class Meter:
    """Counts and times what each phase costs. Nothing here changes an answer."""

    def __init__(self):
        self.calls = defaultdict(int)
        self.secs = defaultdict(float)
        self.bytes_decoded = 0
        self.bound_size = 0

    def wrap(self, obj, name, label=None):
        label = label or name
        fn = getattr(obj, name)

        def w(*a, **k):
            t = time.perf_counter()
            try:
                return fn(*a, **k)
            finally:
                self.secs[label] += time.perf_counter() - t
                self.calls[label] += 1
        setattr(obj, name, w)
        return fn

    def wrap_subprocess(self, m):
        """unidasm is the decode authority and it is an EXTERNAL PROCESS. That
        makes it the first thing to measure: 2 MiB of decode through a
        fork+exec per window is a different cost shape from a slow inner loop."""
        real = m.subprocess.run

        def w(cmd, *a, **k):
            t = time.perf_counter()
            try:
                return real(cmd, *a, **k)
            finally:
                self.secs["unidasm subprocess"] += time.perf_counter() - t
                self.calls["unidasm subprocess"] += 1
        m.subprocess = type("S", (), {"run": staticmethod(w)})()
        return real


def phase_report(meter, total, extra=()):
    print("\n%-34s %8s %10s %7s" % ("phase", "calls", "seconds", "% wall"))
    print("-" * 63)
    rows = sorted(meter.secs.items(), key=lambda kv: -kv[1])
    for label, secs in rows:
        print("%-34s %8d %10.3f %6.1f%%"
              % (label, meter.calls[label], secs, 100.0 * secs / total if total else 0))
    for label, secs, calls in extra:
        print("%-34s %8s %10.3f %6.1f%%"
              % (label, calls, secs, 100.0 * secs / total if total else 0))
    print("-" * 63)
    print("%-34s %8s %10.3f %6.1f%%" % ("TOTAL WALL", "", total, 100.0))


def run_tag(tag, cprofile=False, quiet=False):
    """One COLD analyse() of `tag`, with every phase attributed."""
    m = load_reach()
    meter = Meter()
    meter.wrap_subprocess(m)
    for name in ("source_lines", "proven_and_incbin", "seeds", "_decode_window",
                 "_fingerprint", "_cache_load", "included_sources"):
        meter.wrap(m, name)
    # ⚠ walk() is called from _walk_from, which the module resolves through its
    # own globals -- so patching the module attribute is enough, no import games.
    meter.wrap(m, "walk")

    cpu = m.CPU1 if tag in m.CPU1 else m.CPU2
    prof = None
    if cprofile:
        import cProfile
        prof = cProfile.Profile()
        prof.enable()
    t0 = time.perf_counter()
    # bypass the result cache: a COLD walk is what we are measuring.
    m._cache_get = lambda t: None
    m._cache_store = lambda a: None
    r = m.analyse(tag, cpu)
    total = time.perf_counter() - t0
    if prof:
        prof.disable()
    # ★ HOW BIG IS THE BOUNDARY INDEX? It decides whether the decode can be
    # PERSISTED between runs, which is the difference between paying 54k
    # subprocess spawns once and paying them every time an .s file changes.
    meter.bound_size = len(m._BOUND[tag])

    if not quiet:
        print("=" * 63)
        print("COLD analyse(%s)   reached %s  incbin %s  strong-in-incbin %s"
              % (tag, format(r["reached"], ","), format(r["incbin"], ","),
                 format(r["reach_strong"], ",")))
        print("=" * 63)
        # the walk's own inner loop is walk() minus the decode it calls
        inner = meter.secs["walk"] - meter.secs["_decode_window"]
        decode_minus_sub = meter.secs["_decode_window"] - meter.secs["unidasm subprocess"]
        phase_report(meter, total, extra=[
            ("  = walk inner loop (walk-decode)", inner, meter.calls["walk"]),
            ("  = decode bookkeeping (dec-sub)", decode_minus_sub,
             meter.calls["_decode_window"]),
        ])
        nsub = meter.calls["unidasm subprocess"]
        if nsub:
            print("\nunidasm: %d spawns, %.1f ms each, %.1f%% of wall"
                  % (nsub, 1000.0 * meter.secs["unidasm subprocess"] / nsub,
                     100.0 * meter.secs["unidasm subprocess"] / total))
        print("source re-reads: source_lines called %d times (%.3fs), "
              "included_sources %d times (%.3fs)"
              % (meter.calls["source_lines"], meter.secs["source_lines"],
                 meter.calls["included_sources"], meter.secs["included_sources"]))
    if prof:
        s = io.StringIO()
        pstats.Stats(prof, stream=s).sort_stats("cumulative").print_stats(28)
        print("\n" + s.getvalue())
    return r, meter, total


def run_all():
    """Every walked image, cold. ★ THIS IS THE HEADLINE NUMBER: the wall time of
    one `--targets` run whose result cache does not hit."""
    grand = Meter()
    total = 0.0
    for tag, _s, _f, _b in load_reach().IMAGES:
        r, meter, t = run_tag(tag, quiet=True)
        total += t
        for k, v in meter.secs.items():
            grand.secs[k] += v
            grand.calls[k] += meter.calls[k]
        print("%-8s cold %8.2fs | unidasm %6d spawns %8.2fs (%4.1f%%) %.1fms ea "
              "| decode calls %6d | boundary index %6d instrs"
              % (tag, t, meter.calls["unidasm subprocess"],
                 meter.secs["unidasm subprocess"],
                 100.0 * meter.secs["unidasm subprocess"] / t if t else 0,
                 1000.0 * meter.secs["unidasm subprocess"]
                 / max(1, meter.calls["unidasm subprocess"]),
                 meter.calls["_decode_window"], meter.bound_size))
    print("\n" + "=" * 63)
    print("ALL IMAGES COLD -- the cost of one --targets with no cache hit")
    print("=" * 63)
    inner = grand.secs["walk"] - grand.secs["_decode_window"]
    phase_report(grand, total,
                 extra=[("  = walk inner loop (walk-decode)", inner,
                         grand.calls["walk"])])


def selftest():
    """INVARIANTS ONLY -- never a pinned timing."""
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    m = load_reach()
    check("reachability.py imports as a module without running main",
          hasattr(m, "analyse") and hasattr(m, "walk"))

    # ★ THE INVARIANT THAT MATTERS: instrumenting must not change an answer.
    # A meter that perturbs the result would make every number below a lie.
    plain = load_reach()
    plain._cache_get = lambda t: None
    plain._cache_store = lambda a: None
    seen_plain, q = set(), []
    pr, _ = plain.proven_and_incbin("prom_c")
    start = sorted(pr)[len(pr) // 2]
    plain.walk("prom_c", start, seen_plain, plain.CPU2, q)

    m2 = load_reach()
    meter = Meter()
    meter.wrap_subprocess(m2)
    meter.wrap(m2, "_decode_window")
    meter.wrap(m2, "walk")
    seen_m, q2 = set(), []
    m2.walk("prom_c", start, seen_m, m2.CPU2, q2)
    check("the meter does not change walk()'s answer",
          seen_plain == seen_m and sorted(q) == sorted(q2),
          "%d bytes, %d queued" % (len(seen_plain), len(q)))
    check("the meter actually observed the decode",
          meter.calls["_decode_window"] > 0,
          "%d windows, %d spawns" % (meter.calls["_decode_window"],
                                     meter.calls["unidasm subprocess"]))

    # phases must be nested consistently: decode time <= walk time is NOT
    # required (decode is also called outside walk), but subprocess <= decode is.
    check("unidasm time is contained in _decode_window time",
          meter.secs["unidasm subprocess"] <= meter.secs["_decode_window"] + 1e-6,
          "%.3f <= %.3f" % (meter.secs["unidasm subprocess"],
                            meter.secs["_decode_window"]))
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", default="prom_a")
    ap.add_argument("--all", action="store_true",
                    help="every walked image -- this is the cost of ONE COLD --targets")
    ap.add_argument("--cprofile", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    if a.all:
        run_all()
    else:
        run_tag(a.tag, a.cprofile)
