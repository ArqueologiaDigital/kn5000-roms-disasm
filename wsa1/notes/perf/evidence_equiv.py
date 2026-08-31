#!/usr/bin/env python3
"""DOES THE FALL-THROUGH INDEX ANSWER WHAT THE PER-RUN SCAN ANSWERED?

QUESTION IT ANSWERS
    --evidence grades every reachable run by asking "does anything POSITIVELY
    say execution enters here": a graded seed names it, or a proven instruction
    ENDS exactly here. The second half used to be a scan of the whole proven set
    per run -- 257,759 addresses across the tree, each a _decode_window() call --
    which made the mode cost more than the walk it depends on. It is now one
    dict, built once (reachability.fallthrough_index).

    A refactor of a grading rule is only safe if it GRADES THE SAME. So this
    file keeps the OLD algorithm as an ORACLE and runs both over every run the
    tool actually grades, on the real tree.

    ⚠ THE ORACLE IS DELIBERATELY THE SLOW CODE. It is a copy of what
    start_evidence() did before the change, kept here precisely because it is no
    longer in the tool -- so the comparison is against what was, not against a
    tidied-up memory of it.

RUN
    python3 notes/perf/evidence_equiv.py             # ★ every graded run, both ways
    python3 notes/perf/evidence_equiv.py --tag prom_b
    python3 notes/perf/evidence_equiv.py --shared-cache   # the unlink fix
    python3 notes/perf/evidence_equiv.py --selftest

SIGNAL BEING READ
    * the VERDICT string start_evidence() returns for a run start: a seed class,
      "fallthrough", or None. Equality of those strings, run for run, is the
      whole claim.
    * for --shared-cache: the INODE of notes/.reachability-cache.json across an
      --evidence run. The old code os.unlink()ed it -- every lane's copy -- to
      get an in-memory effect; a rewrite in place keeps the inode, an unlink
      does not.
"""
import argparse
import importlib.util
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def load_reach():
    spec = importlib.util.spec_from_file_location(
        "reach_for_evidence_equiv", os.path.join(ROOT, "notes", "reachability.py"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def oracle(m, tag, addr, sd, proven):
    """★ THE PRE-P5 start_evidence(), verbatim in behaviour: seed classes first,
    then a linear scan of the proven set calling _decode_window() per address."""
    for cls in list(m.STRONG) + list(m.WEAK):
        if addr in sd.get(cls, ()):
            return cls
    for a in proven:
        if a < addr:
            rows = m._decode_window(tag, a)
            if rows and rows[0][0] == a and a + rows[0][1] == addr:
                return "fallthrough"
    return None


def compare(tags):
    m = load_reach()
    m.FORCE_WALK = True                    # --evidence's own path: it needs `seen`
    bad = total = 0
    for tag, _s, _f, _b in m.IMAGES:
        if tags and tag not in tags:
            continue
        cpu = m.CPU1 if tag in m.CPU1 else m.CPU2
        r = m.analyse(tag, cpu)
        sd = m.seeds(tag, cpu)
        proven, _ = m.proven_and_incbin(tag)
        pset = set(proven)
        fall = m.fallthrough_index(tag, pset)
        n = 0
        for lo, hi in r["spans"]:
            for a, _b2 in m.runs_of(r["seen"], lo, hi):
                new = m.start_evidence(tag, cpu, a, sd, pset, fall)
                old = oracle(m, tag, a, sd, pset)
                n += 1
                total += 1
                if new != old:
                    bad += 1
                    print("  ✗ %s 0x%06X: index says %r, the per-run scan says %r"
                          % (tag, a, new, old))
        print("%-8s %4d graded runs, index == scan on all of them"
              % (tag, n) if not bad else "%-8s %4d graded runs, %d DISAGREE" % (tag, n, bad))
    print("\n%d run(s) compared, %d disagreement(s)" % (total, bad))
    return 1 if bad else 0


def shared_cache():
    """★ --evidence MUST NOT DELETE THE SHARED RESULT CACHE. It used to, to force
    a re-walk in its own process; every other lane paid a 17-minute miss for it."""
    m = load_reach()
    subprocess.run([sys.executable, os.path.join(ROOT, "notes", "reachability.py")],
                   cwd=ROOT, capture_output=True, timeout=3600)
    before = os.stat(m.RESULT_CACHE)
    subprocess.run([sys.executable, os.path.join(ROOT, "notes", "reachability.py"),
                    "--evidence"], cwd=ROOT, capture_output=True, timeout=3600)
    after = os.stat(m.RESULT_CACHE)
    ok = before.st_ino == after.st_ino
    print("result cache inode before --evidence: %d, after: %d  -> %s"
          % (before.st_ino, after.st_ino, "SURVIVED" if ok else "REPLACED"))
    return 0 if ok else 1


def selftest():
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    m = load_reach()
    check("the tool has a fall-through index and start_evidence takes it",
          hasattr(m, "fallthrough_index")
          and "fall" in m.start_evidence.__code__.co_varnames)
    check("--evidence no longer unlinks the result cache",
          "os.unlink(RESULT_CACHE)" not in open(
              os.path.join(ROOT, "notes", "reachability.py")).read())
    check("...and gets its re-walk from a module flag instead",
          hasattr(m, "FORCE_WALK") and m.FORCE_WALK is False)

    # ★ THE ORACLE MUST BE ABLE TO DISAGREE, or this file proves nothing.
    tag = "prom_c"
    cpu = m.CPU2
    proven, _ = m.proven_and_incbin(tag)
    pl = sorted(proven)
    m._decode_load(tag)
    fall = m.fallthrough_index(tag, set(pl))
    hits = [a for a in pl[:4000] if a in fall]
    check("the index knows a real fall-through when there is one",
          bool(hits), "%d of the first 4,000 proven addresses" % len(hits))
    fake = {}
    check("...and says no when the index is empty",
          m.start_evidence(tag, cpu, hits[0] if hits else pl[0], {}, set(), fake) is None)
    # and the two agree on a sample, cheaply
    sample = hits[:5] + pl[len(pl) // 2:len(pl) // 2 + 3]
    agree = sum(1 for a in sample
                if m.start_evidence(tag, cpu, a, {}, set(pl), fall) == oracle(m, tag, a, {}, set(pl)))
    check("index and per-run scan agree on a sample of %d addresses" % len(sample),
          agree == len(sample), "%d agree" % agree)
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", action="append")
    ap.add_argument("--shared-cache", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    if a.shared_cache:
        sys.exit(shared_cache())
    sys.exit(compare(a.tag))
