#!/usr/bin/env python3
"""Did a NAME change move any prom_b probe's ANSWER?

WHAT QUESTION THIS ANSWERS
    A round that only renames labels and edits comments cannot move a byte, and
    the byte gate cannot see it.  What it CAN move is a probe: one that cites a
    label by name, or counts labels, lines or comment lines, will answer
    differently and say nothing about it.

    This runs every committed prom_b probe TWICE -- once against the current
    prom_b/wsa1_prom_b.s and once against a BASE revision of that one file,
    with everything else in the tree identical -- and diffs the two outputs.
    A probe whose output is identical is unaffected by the round, and that is
    the claim the round needs.

    ★ It is the cheap, targeted complement to notes/probe_health.py.  That tool
    asks "would a per-subject SPLIT break this probe" and builds three trees to
    do it; this asks "did THIS round's edit break it" and changes one file.

⚠⚠ IT RUNS EVERY OTHER PROBE, TWICE, SO IT MUST NEVER RUN UNDER A HARNESS THAT
RUNS PROBES.  notes/probe_health.py discovers its candidates by grepping every
committed .py for the image's filename and then executing the commands each
docstring cites.  If this script were one of them it would re-enter the whole
probe corpus inside each of three trees.  It therefore REFUSES to do anything
unless `--base` is given an explicit revision: a bare run, or `--base` with no
value, prints one line and exits 0.

RUN
    python3 notes/prom_b_probe_answer_diff.py --base HEAD~1
    python3 notes/prom_b_probe_answer_diff.py --base HEAD~1 --only msgline
    python3 notes/prom_b_probe_answer_diff.py --base HEAD~1 --jobs 6

⚠ IT COPIES THE WHOLE TREE, about 250 MB, and on this machine /tmp is a tmpfs --
so a killed run used to leave a quarter-gigabyte of RAM behind, and five of them
took 1.3 GB.  The copy is now removed by an atexit hook as well as at the end.

⚠ 93 probes, run twice each, several of them minutes long: budget hours at
`--jobs 1`.  The two runs of one probe are independent, so `--jobs` parallelises
across probes; a probe's own pair always runs in the same worker, so it is never
compared against a different probe's environment.
Exit status is non-zero if any probe's answer changed.

★ IT REPLACES THE WHOLE IMAGE, NOT ONE FILE.  The base copy gets the primary
and, recursively, every `.include` it names at that revision, so a future
per-subject split of prom_b does not silently reduce this to a partial swap.
"""
import os
import re
import atexit
import concurrent.futures
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REL = "prom_b/wsa1_prom_b.s"
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import git_show  # noqa: E402  (git paths are repo-relative)
TIMEOUT = 900


def probes():
    """Committed notes/ + scripts/analysis/ scripts whose name mentions prom_b."""
    out = subprocess.run(["git", "-C", ROOT, "ls-files", "notes", "scripts"],
                         capture_output=True, text=True, check=True).stdout.split()
    return sorted(p for p in out
                  if p.endswith(".py") and "prom_b" in os.path.basename(p)
                  and "apply" not in p and "answer_diff" not in p)


def run(cwd, script):
    try:
        r = subprocess.run([sys.executable, script], cwd=cwd, capture_output=True,
                           text=True, timeout=TIMEOUT,
                           env={**os.environ, "PYTHONHASHSEED": "0"})
        return f"rc={r.returncode}\n{r.stdout}{r.stderr}"
    except subprocess.TimeoutExpired:
        return "TIMEOUT"


INCLUDE = re.compile(r'^\s*\.include\s+"([^"]+)"')


def swap_image(alt, base):
    """Put the BASE revision of the whole image into `alt`. -> files replaced."""
    want, done = [REL], set()
    while want:
        rel = want.pop()
        if rel in done:
            continue
        done.add(rel)
        # ⚠ A MISS RAISES.  This used to `continue`, so a base revision that
        # spelled a path differently -- every revision from before the 2026-09-01
        # move into wsa1/ does -- produced an EMPTY alt tree, and the answer-diff
        # then compared the working tree with itself and reported no differences.
        try:
            txt = git_show(rel, base)
        except FileNotFoundError as e:
            if rel == REL:
                raise SystemExit("cannot materialise %s at %s: %s" % (rel, base, e))
            raise
        dst = os.path.join(alt, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, "w", encoding="utf-8") as f:
            f.write(txt)
        for ln in txt.splitlines():
            m = INCLUDE.match(ln)
            if m and m.group(1).endswith(".s"):
                inc = m.group(1)
                want.append(inc if "/" in inc else os.path.join(os.path.dirname(rel), inc))
    return sorted(done)


def main():
    if "--base" not in sys.argv or sys.argv.index("--base") + 1 >= len(sys.argv):
        print("prom_b_probe_answer_diff: needs an explicit `--base <rev>`; "
              "it runs every prom_b probe twice and will not do that by accident.")
        return 0
    base = sys.argv[sys.argv.index("--base") + 1]
    only = sys.argv[sys.argv.index("--only") + 1] if "--only" in sys.argv else None
    tmp = tempfile.mkdtemp(prefix="probediff-")
    atexit.register(shutil.rmtree, tmp, True)   # a killed run must not leak 250 MB
    alt = os.path.join(tmp, "tree")
    subprocess.run(["cp", "-a", ROOT, alt], check=True)
    swapped = swap_image(alt, base)
    print(f"base {base}: replaced {len(swapped)} file(s) of the image -- "
          + ", ".join(swapped))
    for d in (ROOT, alt):
        shutil.rmtree(os.path.join(d, "notes", "__pycache__"), ignore_errors=True)

    jobs = int(sys.argv[sys.argv.index("--jobs") + 1]) if "--jobs" in sys.argv else 4
    same = changed = 0
    bad = []
    ps = [p for p in probes() if not only or only in p]

    def one(p):
        a, b = run(ROOT, p), run(alt, p)
        return p, a.replace(ROOT, "@"), b.replace(alt, "@").replace(ROOT, "@")

    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as ex:
        for p, a, b in ex.map(one, ps):
            if a == b:
                same += 1
                print(f"  same     {p}", flush=True)
            else:
                changed += 1
                bad.append(p)
                print(f"  CHANGED  {p}", flush=True)
    print(f"\n{same} unchanged, {changed} changed, base {base}")
    for p in bad:
        print("  " + p)
    shutil.rmtree(tmp, ignore_errors=True)
    return 1 if changed else 0


if __name__ == "__main__":
    sys.exit(main())
