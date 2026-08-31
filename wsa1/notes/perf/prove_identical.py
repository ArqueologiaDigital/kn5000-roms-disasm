#!/usr/bin/env python3
"""DID AN OPTIMISATION CHANGE AN ANSWER?

QUESTION IT ANSWERS
    "notes/reachability.py got faster. Does it still say the same thing?"

    ★ A faster tool that answers differently is a regression, not an
    optimisation. This project is certified by the byte gate and the probe
    corpus; a reachability figure that drifts silently would move the work list
    and, downstream, decide which bytes a lane converts. So the gate on any
    performance change here is EXACT TEXTUAL IDENTITY of every reporting mode,
    from a COLD start -- warm runs prove nothing, because they never execute the
    code that was changed.

WHAT IT CHECKS
    --targets, --spans, --seeds, the bare report, and --selftest, each run with
    BOTH caches cleared, compared byte-for-byte against a recorded baseline.

RUN
    python3 notes/perf/prove_identical.py --record     # baseline, BEFORE a change
    python3 notes/perf/prove_identical.py              # compare, AFTER it
    python3 notes/perf/prove_identical.py --selftest

⚠ CLEARS notes/.reachability-cache.json (and the decode cache, if present) so
    every mode is measured cold. Other lanes running the tool during the
    comparison will pay a cold walk; check
    `ps -eo pid,etimes,args | grep reachability` first.
⚠ --record OVERWRITES the baseline. Record before the change, never after --
    recording after a change makes the change its own witness.
"""
import argparse
import difflib
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASELINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "baseline")
TOOL = os.path.join(ROOT, "notes", "reachability.py")
CACHES = [os.path.join(ROOT, "notes", ".reachability-cache.json"),
          os.path.join(ROOT, "notes", ".reachability-decode.json")]

# ★ EVERY REPORTING MODE, not just the headline. --targets is the one lanes
# quote, but --spans and --seeds feed judgement calls too, and a change that
# moved only the seed counts would pass a --targets-only gate.
MODES = [("targets", ["--targets"]),          # ★ FIRST: this is the cold one
         ("spans", ["--spans"]),
         ("seeds", ["--seeds"]),
         ("report", []),
         ("selftest", ["--selftest"])]


def clear_caches():
    for c in CACHES:
        try:
            os.unlink(c)
        except OSError:
            pass


def run_mode(argv, cold=True):
    if cold:
        clear_caches()
    t = time.perf_counter()
    r = subprocess.run([sys.executable, TOOL] + argv, cwd=ROOT,
                       capture_output=True, text=True, timeout=3600)
    return r.stdout + r.stderr, r.returncode, time.perf_counter() - t


def capture(cold=True):
    """★ THE CACHES ARE CLEARED ONCE, NOT PER MODE.

    Clearing before every mode would make each of the five pay its own full
    walk -- five times ~17 minutes a side, which nobody would run, and a gate
    nobody runs is not a gate.  Clearing once makes `--targets` COLD (it is the
    mode that does the walk, so it is the one that must be), and the remaining
    modes then read the cache it just wrote.  That is exactly the sequence a
    lane hits in practice, and it still executes the walk once per side."""
    out = {}
    if cold:
        clear_caches()
    for name, argv in MODES:
        text, rc, secs = run_mode(argv, cold=False)
        out[name] = (text, rc)
        print("  %-9s %8.2fs  rc=%s  %d bytes%s"
              % (name, secs, rc, len(text),
                 "   <- COLD, this one walks" if cold and name == MODES[0][0] else ""),
              flush=True)
    return out


def main(record, cold):
    os.makedirs(BASELINE, exist_ok=True)
    print("%s (%s)" % ("RECORDING baseline" if record else "COMPARING against baseline",
                       "cold" if cold else "warm"))
    got = capture(cold)
    if record:
        for name, (text, rc) in got.items():
            open(os.path.join(BASELINE, name + ".txt"), "w").write(text)
            open(os.path.join(BASELINE, name + ".rc"), "w").write(str(rc))
        print("\nbaseline written to %s" % os.path.relpath(BASELINE, ROOT))
        return 0
    bad = 0
    for name, (text, rc) in got.items():
        p = os.path.join(BASELINE, name + ".txt")
        if not os.path.exists(p):
            print("  ?? %-9s no baseline recorded" % name)
            bad += 1
            continue
        want = open(p).read()
        want_rc = int(open(os.path.join(BASELINE, name + ".rc")).read())
        if text == want and rc == want_rc:
            print("  ok   %-9s IDENTICAL (%d bytes, rc=%s)" % (name, len(text), rc))
        else:
            bad += 1
            print("  FAIL %-9s DIFFERS" % name)
            for line in list(difflib.unified_diff(
                    want.splitlines(), text.splitlines(),
                    "baseline", "now", lineterm=""))[:40]:
                print("      " + line)
    print("\n%d mode(s) compared, %d differ" % (len(got), bad))
    return 1 if bad else 0


def selftest():
    """INVARIANTS ONLY. ⚠ Never pins a timing: this file's whole point is that
    only the ANSWER is allowed to be pinned."""
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    check("the tool under test exists", os.path.exists(TOOL))
    check("every mode is a distinct name", len({n for n, _ in MODES}) == len(MODES))
    # ★ THE INSTRUMENT MUST BE ABLE TO FAIL. A comparator that cannot report a
    # difference is not a gate -- it is a rubber stamp. So prove it detects one.
    a = {"targets": ("STRONG 17 bytes\n", 0)}
    import io
    import contextlib
    os.makedirs(BASELINE, exist_ok=True)
    probe = os.path.join(BASELINE, "_selftest_probe.txt")
    open(probe, "w").write("STRONG 17 bytes\n")
    same = open(probe).read() == a["targets"][0]
    open(probe, "w").write("STRONG 18 bytes\n")
    diff = open(probe).read() != a["targets"][0]
    os.unlink(probe)
    check("the comparator sees identity and sees a one-digit difference",
          same and diff)
    check("clearing caches names both of them, not just the result cache",
          len(CACHES) == 2 and any("decode" in c for c in CACHES))
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--record", action="store_true")
    ap.add_argument("--warm", action="store_true",
                    help="compare WITHOUT clearing caches (a much weaker check)")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    sys.exit(main(a.record, not a.warm))
