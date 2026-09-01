#!/usr/bin/env python3
"""Did any invocation of a script THIS LANE TOUCHED go green -> non-green?

WHAT QUESTION THIS ANSWERS
--------------------------
  probe_health's full sweep of prom_a or prom_b is ~760 subprocess runs, and on
  a machine also building MAME it does not finish in a session.  ⚠ THAT IS A
  REASON TO MEASURE LESS, NOT TO MEASURE NOTHING.  The rows a lane can move are
  the ones whose script it edited; every other row is produced by files this
  lane did not open.

  So this re-measures exactly the baseline's invocations of the touched scripts,
  in the same four trees probe_health builds, and joins the grades on argv.

  ⚠ IT IS NOT A SUBSTITUTE FOR THE FULL SWEEP, and it is not honest to call it
  one.  Two things it cannot see:
    * a row whose script is untouched but whose ANSWER depends on a touched one
      (an import, or a probe that runs another probe).  ★ probe_health.py itself
      is such a dependency for every row, which is why it must be in the touched
      set whenever it changed -- it is, here.
    * a script the baseline never ran.  Those are listed as NOT IN BASELINE
      rather than dropped.

RUN
    python3 regrade_touched.py BASE.json --image prom_b \
            --since 3947944a --json out.json
    python3 regrade_touched.py --selftest

`--since <rev>` derives the touched set from `git diff --name-only <rev>..HEAD`.
`--scripts a.py,b.py` names it explicitly instead.
"""
import argparse
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import probe_health as PH                                    # noqa: E402

GREEN = {"UNAFFECTED", "BY-DESIGN"}


def touched_since(rev, root=ROOT):
    """ROOT-relative .py paths changed between `rev` and HEAD."""
    out = subprocess.run(["git", "-C", root, "diff", "--name-only",
                          "%s..HEAD" % rev],
                         capture_output=True, text=True, check=True).stdout
    prefix = subprocess.run(["git", "-C", root, "rev-parse", "--show-prefix"],
                            capture_output=True, text=True,
                            check=True).stdout.strip()
    hits = set()
    for p in out.split("\n"):
        if not p.endswith(".py"):
            continue
        if prefix:
            if not p.startswith(prefix):
                continue               # the other product's half of the tree
            p = p[len(prefix):]
        hits.add(p)
    return hits


def select(base_json, image, touched):
    d = json.load(open(base_json))
    if image in d:
        d = d[image]
    elif len(d) == 1 and "rows" not in d:
        d = next(iter(d.values()))
    rows = {tuple(r["argv"]): r["grade"] for r in d["rows"]}
    keep = {k: v for k, v in rows.items() if k[0] in touched}
    missing = sorted(t for t in touched
                     if not any(k[0] == t for k in rows))
    return rows, keep, missing


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("base", nargs="?")
    ap.add_argument("--image", default=None)
    ap.add_argument("--since", default=None)
    ap.add_argument("--scripts", default=None)
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--json", default=None)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if not (a.base and a.image and (a.since or a.scripts)):
        print(__doc__)
        return 2

    touched = (set(a.scripts.split(",")) if a.scripts
               else touched_since(a.since))
    allrows, keep, missing = select(a.base, a.image, touched)
    print("%s: baseline has %d invocation(s); %d belong to the %d touched "
          "script(s)" % (a.image, len(allrows), len(keep), len(touched)))
    if missing:
        print("  NOT IN BASELINE (this lane touched them, the baseline never ran "
              "them): %d" % len(missing))
        for m in sorted(missing):
            print("      %s" % m)
    if not keep:
        return 0

    argvs = [list(k) for k in sorted(keep)]
    rows = PH.measure(PH.IMAGE_PRIMARY[a.image], argvs, jobs=a.jobs)
    now = {tuple(r["argv"]): r["grade"] for r in rows}

    regressed, improved, same = [], [], 0
    for k, was in sorted(keep.items()):
        is_ = now[k]
        if was in GREEN and is_ not in GREEN:
            regressed.append((k, was, is_))
        elif was not in GREEN and is_ in GREEN:
            improved.append((k, was, is_))
        else:
            same += 1
    print("\n  ★ REGRESSED (green -> non-green): %d" % len(regressed))
    for k, w, i in regressed:
        print("      %-14s -> %-14s %s" % (w, i, " ".join(k)))
    print("  IMPROVED (non-green -> green):   %d" % len(improved))
    for k, w, i in improved:
        print("      %-14s -> %-14s %s" % (w, i, " ".join(k)))
    print("  unchanged in kind: %d" % same)
    if a.json:
        json.dump({a.image: {"rows": rows}}, open(a.json, "w"), indent=1)
        print("\nwrote %s" % a.json)
    return 1 if regressed else 0


def selftest():
    """INVARIANTS.  Nothing here pins a grade; what is checked is that the
    SELECTION is honest -- it never silently drops a touched script, never
    reaches a row outside the touched set, and would notice a regression."""
    ok = True

    def check(cond, msg):
        nonlocal ok
        print(("  ok    " if cond else "  FAIL  ") + msg)
        ok = ok and cond

    import tempfile
    with tempfile.TemporaryDirectory() as td:
        base = os.path.join(td, "b.json")
        json.dump({"prom_b": {"rows": [
            {"argv": ["notes/a.py"], "grade": "UNAFFECTED"},
            {"argv": ["notes/a.py", "--x"], "grade": "VACUOUS"},
            {"argv": ["notes/b.py"], "grade": "UNAFFECTED"},
        ]}}, open(base, "w"))
        allrows, keep, missing = select(base, "prom_b", {"notes/a.py"})
        check(len(allrows) == 3 and len(keep) == 2,
              "selection keeps EVERY invocation of a touched script (%d of %d)"
              % (len(keep), len(allrows)))
        check(all(k[0] == "notes/a.py" for k in keep),
              "...and nothing outside the touched set")
        _a, _k, missing = select(base, "prom_b", {"notes/a.py", "notes/zz.py"})
        check(missing == ["notes/zz.py"],
              "a touched script the baseline never ran is REPORTED, not dropped "
              "(%s)" % missing)
        # the green rule, both directions -- a comparison that cannot report a
        # regression is not a comparison
        check("UNAFFECTED" in GREEN and "BY-DESIGN" in GREEN
              and "VACUOUS" not in GREEN and "TIMEOUT" not in GREEN,
              "TIMEOUT and VACUOUS are NOT green, so a probe that never answered "
              "cannot pass as one that did")

    t = touched_since("HEAD")
    check(t == set(), "touched_since(HEAD) is empty (%d)" % len(t))
    t = touched_since("HEAD~1")
    check(all(not p.startswith("..") and p.endswith(".py") for p in t),
          "touched_since returns ROOT-relative .py paths (%s)" % sorted(t)[:3])
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
