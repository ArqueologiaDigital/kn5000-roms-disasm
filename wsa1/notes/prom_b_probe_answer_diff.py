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

RUN
    python3 notes/prom_b_probe_answer_diff.py --base <rev>
    python3 notes/prom_b_probe_answer_diff.py --base <rev> --only <substr>
Exit status is non-zero if any probe's answer changed.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REL = "prom_b/wsa1_prom_b.s"
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


def main():
    base = sys.argv[sys.argv.index("--base") + 1] if "--base" in sys.argv else "HEAD~1"
    only = sys.argv[sys.argv.index("--only") + 1] if "--only" in sys.argv else None
    tmp = tempfile.mkdtemp(prefix="probediff-")
    alt = os.path.join(tmp, "tree")
    subprocess.run(["cp", "-a", ROOT, alt], check=True)
    old = subprocess.run(["git", "-C", ROOT, "show", f"{base}:{REL}"],
                         capture_output=True, check=True).stdout
    with open(os.path.join(alt, REL), "wb") as f:
        f.write(old)
    for d in (ROOT, alt):
        shutil.rmtree(os.path.join(d, "notes", "__pycache__"), ignore_errors=True)

    same = changed = 0
    bad = []
    ps = [p for p in probes() if not only or only in p]
    for p in ps:
        a, b = run(ROOT, p), run(alt, p)
        a, b = a.replace(ROOT, "@"), b.replace(alt, "@").replace(ROOT, "@")
        if a == b:
            same += 1
            print(f"  same     {p}")
        else:
            changed += 1
            bad.append(p)
            print(f"  CHANGED  {p}")
    print(f"\n{same} unchanged, {changed} changed, base {base}")
    for p in bad:
        print("  " + p)
    shutil.rmtree(tmp, ignore_errors=True)
    return 1 if changed else 0


if __name__ == "__main__":
    sys.exit(main())
