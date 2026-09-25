#!/usr/bin/env python3
"""Which comments did an edit drop?  A linear-time companion to
scripts/analysis/assert_comments_preserved.py.

QUESTION THIS ANSWERS
    assert_comments_preserved.py asks whether the base revision's comment
    sequence survives as a subsequence of the new file, and reports losses with
    difflib.SequenceMatcher(autojunk=False).  On style_records.s (1000
    records, the same eight comment strings repeated 1000 times, ~29,000
    comments) that matcher is quadratic and ran for more than ten minutes
    without finishing.  This script answers the same question for such files:

      * LOST = the multiset difference base - new, printed with counts, so an
        intended drop (say, "; +0x4d" x1000) is visible as ONE line;
      * the subsequence verdict is recomputed with the greedy two-pointer test
        (exact for "is A a subsequence of B"), after removing the lost ones --
        so a comment that survived but moved out of order still FAILS.

    Comments are extracted with the same rule as the original tool (first `;`
    outside a double-quoted string, whole remainder of the line).

RUN
    python3 notes/tonedb-2026-09-25/comments_lost.py --base <rev> <file> [...]
    Exit status 0 when nothing was lost and the order is preserved, 1 otherwise
    (the listing is then the review item: every lost line must be intended).
"""
import argparse
import collections
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


def comments(text):
    out = []
    for line in text.split("\n"):
        q = False
        for i, ch in enumerate(line):
            if ch == '"':
                q = not q
            elif ch == ";" and not q:
                out.append(line[i:].rstrip())
                break
    return out


def is_subsequence(a, b):
    it = iter(b)
    return all(any(x == y for y in it) for x in a)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="HEAD")
    ap.add_argument("paths", nargs="+")
    a = ap.parse_args()
    bad = 0
    for p in a.paths:
        rel = pathlib.Path(p).resolve().relative_to(ROOT)
        base = subprocess.run(["git", "show", "%s:%s" % (a.base, rel)], cwd=ROOT,
                              capture_output=True, check=True).stdout.decode("latin-1")
        new = (ROOT / rel).read_bytes().decode("latin-1")
        cb, cn = comments(base), comments(new)
        lost = collections.Counter(cb) - collections.Counter(cn)
        kept = collections.Counter(cb) - lost
        # drop the lost instances (from the end, arbitrarily) and test order
        need = dict(kept)
        cb_kept = []
        for c in cb:
            if need.get(c, 0):
                cb_kept.append(c)
                need[c] -= 1
        order_ok = is_subsequence(cb_kept, cn)
        print("%s: %d comments -> %d; lost %d (%d distinct); order of the rest %s"
              % (rel, len(cb), len(cn), sum(lost.values()), len(lost),
                 "PRESERVED" if order_ok else "BROKEN"))
        for c, n in sorted(lost.items(), key=lambda kv: -kv[1]):
            print("   x%-5d %s" % (n, c[:150]))
        if lost or not order_ok:
            bad = 1
    sys.exit(bad)


if __name__ == "__main__":
    main()
