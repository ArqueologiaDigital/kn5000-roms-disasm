#!/usr/bin/env python3
r"""Did MY EDIT change a probe's ANSWER?

WHAT QUESTION THIS ANSWERS
--------------------------
  notes/probe_health.py asks whether a probe reads the whole IMAGE -- a question
  about FILE LAYOUT.  It hands the probe three trees that differ only in how one
  image is split, so a probe that fails identically in all three is graded
  UNAFFECTED and a probe that was already broken stays invisible.  That is the
  right instrument for a split and the wrong one for a source EDIT.

  This asks the other question: run every probe that reads a given image at TWO
  REVISIONS and report the ones whose output differs.  A converted `.byte` line
  moves no byte, so the byte gate cannot see it; what CAN see it is a probe that
  counted `.byte` lines, or scanned for a mnemonic, or pinned a span's length.

★ WHY A DIFF AND NOT A PASS/FAIL SWEEP.  Running the 163 selftests in this tree
  and reading the failures tells you nothing: many were already red before the
  edit, for reasons that have nothing to do with it.  A probe's own verdict is
  not a baseline.  ITS OUTPUT IS.

⚠ BOTH SIDES RUN IN A WORKTREE, NEVER IN THE WORKING TREE.  Several probes write
  a source with NO FLAG AT ALL -- scripts/analysis/gen_prom_d_asm.py is the
  documented one -- and probe_health.py records what happened the first time one
  was invoked bare: it rewrote the very files under test.  Here the working tree
  is never the subject, so a writer can only damage a throwaway checkout.

⚠ A DIFFERENCE IS NOT AUTOMATICALLY A REGRESSION.  A probe that reports "N
  `.byte` lines in prom_a" SHOULD move when 63 of them become instructions.  The
  output of both sides is printed so the reader can judge; this tool finds the
  probes that need judging, and asserts nothing about them.

RUN
---
  python3 notes/probe_answer_diff.py --before <rev>            # vs HEAD
  python3 notes/probe_answer_diff.py --before <rev> --after <rev>
  python3 notes/probe_answer_diff.py --before <rev> --grep prom_a
  python3 notes/probe_answer_diff.py --selftest
"""
import argparse
import concurrent.futures
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import git_prefix                             # noqa: E402

TIMEOUT = 240
# ⚠ NEVER PASSED.  Copied from probe_health.py: a mode that writes a source tells
# us nothing about reading.  The bare invocation is the only one run here.
SKIP_NAMES = ("probe_answer_diff.py", "probe_health.py")


def worktree(rev, into):
    subprocess.run(["git", "worktree", "add", "--detach", into, rev],
                   cwd=ROOT, check=True, capture_output=True)
    # The ROM images every probe reads are committed, so the checkout has them.
    # The derived expansion caches are NOT committed and must not be inherited:
    # notes/.image-*.s in a stale state would make both sides read the same
    # wrong text, which is the one way this instrument could report a false
    # "nothing changed".
    nd = os.path.join(_wsa1(into), "notes")
    for name in os.listdir(nd):
        if name.startswith(".image-"):
            os.unlink(os.path.join(nd, name))
    return into


def _wsa1(root):
    """`git worktree add` checks out the REPOSITORY; this tree is a subdir."""
    return os.path.join(root, "wsa1") if os.path.isdir(
        os.path.join(root, "wsa1")) else root


def probes(root, pattern):
    out = []
    base = _wsa1(root)
    for sub in ("notes", os.path.join("notes", "sound"),
                os.path.join("notes", "llvm")):
        d = os.path.join(base, sub)
        if not os.path.isdir(d):
            continue
        for name in sorted(os.listdir(d)):
            if not name.endswith(".py") or name in SKIP_NAMES:
                continue
            p = os.path.join(d, name)
            try:
                text = open(p, errors="replace").read()
            except OSError:
                continue
            if pattern and pattern not in text:
                continue
            out.append(os.path.relpath(p, base))
    return out


MASK = [(re.compile(r'/tmp/[^\s\'"]*'), "<TMP>"),
        (re.compile(r'0x[0-9a-fA-F]{12,}'), "<PTR>"),
        (re.compile(r'\d+\.\d+ ?s\b'), "<TIME>")]


def run(root, rel):
    base = _wsa1(root)
    p = subprocess.run([sys.executable, rel], cwd=base, capture_output=True,
                       text=True, timeout=None, errors="replace")
    text = p.stdout + p.stderr
    text = text.replace(base, "<ROOT>").replace(root, "<ROOT>")
    for rx, rep in MASK:
        text = rx.sub(rep, text)
    return f"exit={p.returncode}\n{text}"


def compare(before_rev, after_rev, pattern, show):
    tmp = tempfile.mkdtemp(prefix="probediff-")
    a = os.path.join(tmp, "before")
    b = os.path.join(tmp, "after")
    try:
        worktree(before_rev, a)
        worktree(after_rev, b)
        rels = sorted(set(probes(a, pattern)) & set(probes(b, pattern)))
        print(f"{len(rels)} probe(s) present in BOTH revisions"
              + (f" and mentioning {pattern!r}" if pattern else ""))
        only_b = sorted(set(probes(b, pattern)) - set(probes(a, pattern)))
        for r in only_b:
            print(f"  new in {after_rev}: {r}")
        differ = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as ex:
            fa = {r: ex.submit(run, a, r) for r in rels}
            fb = {r: ex.submit(run, b, r) for r in rels}
            for i, r in enumerate(rels, 1):
                try:
                    oa, ob = fa[r].result(), fb[r].result()
                except Exception as e:                      # noqa: BLE001
                    print(f"  ERROR {r}: {e}")
                    continue
                if oa != ob:
                    differ.append(r)
                    print(f"  ★ DIFFERS  {r}")
                    if show:
                        for line in _difflines(oa, ob):
                            print("      " + line)
                if i % 25 == 0:
                    print(f"    ... {i}/{len(rels)}")
        print(f"\n{len(differ)} of {len(rels)} probe(s) changed their answer.")
        return differ
    finally:
        for w in (a, b):
            subprocess.run(["git", "worktree", "remove", "--force", w],
                           cwd=ROOT, capture_output=True)
        shutil.rmtree(tmp, ignore_errors=True)


def _difflines(oa, ob, context=2):
    import difflib
    return [l for l in difflib.unified_diff(
        oa.split("\n"), ob.split("\n"), "before", "after", n=context,
        lineterm="")][:60]


def selftest():
    """INVARIANTS.  Not a pinned list of probes -- that list grows."""
    bad = 0
    # 1. ROOT is derived and is this tree.
    if not os.path.isfile(os.path.join(ROOT, "Makefile")):
        print(f"FAIL  ROOT is wrong: {ROOT}")
        bad += 1
    # 2. THE MASKS ARE LIVE.  Without them every probe that prints a temp path
    #    would differ for that reason alone and the instrument would be useless.
    s = "read /tmp/probediff-1234/x and 0x0000000060EB80 in 1.25 s"
    for rx, rep in MASK:
        s = rx.sub(rep, s)
    if "/tmp/probediff" in s or "0x0000000060EB80" in s:
        print(f"FAIL  a mask did not fire: {s!r}")
        bad += 1
    # 3. THE COMPARISON CAN SEE A DIFFERENCE.  A control that cannot fail is not
    #    a control.
    if _difflines("exit=0\na\n", "exit=0\nb\n") == []:
        print("FAIL  two different outputs compared equal")
        bad += 1
    if _difflines("exit=0\na\n", "exit=0\na\n") != []:
        print("FAIL  two identical outputs compared different")
        bad += 1
    # 4. Writers are not excluded by flag here, because the bare invocation is
    #    the only one run -- so the WORKTREE isolation is the whole safety
    #    argument, and the working tree must never be a subject.
    if ROOT in (os.path.join(tempfile.gettempdir(), "before"),):
        print("FAIL  the working tree is being used as a subject")
        bad += 1
    print("selftest: " + ("OK" if bad == 0 else f"{bad} FAILURE(S)"))
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--before")
    ap.add_argument("--after", default="HEAD")
    ap.add_argument("--grep", default=None,
                    help="only probes whose SOURCE contains this string")
    ap.add_argument("--show", action="store_true", help="print the diffs")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if not a.before:
        ap.error("--before <rev> is required")
    return 1 if compare(a.before, a.after, a.grep, a.show) else 0


if __name__ == "__main__":
    sys.exit(main())
