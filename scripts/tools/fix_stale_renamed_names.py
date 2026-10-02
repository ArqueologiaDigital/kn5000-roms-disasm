#!/usr/bin/env python3
"""fix_stale_renamed_names.py -- comments that still use a name a committed rename retired.

QUESTION THIS ANSWERS / WHY IT EXISTS
  `scripts/analysis/claims_lint.py stale-names` reports a token in a comment that is defined
  nowhere; its STALE-RENAMED rows are tokens on the OLD side of a committed rename
  (scripts/renaming/*.sed / *.map / *.py) whose NEW name IS defined -- the comment was simply
  missed by a whole-word sed (the independent precision check measured this kind at 22/22).
  This replaces, on each reported line, the OLD token with the NEW name -- word-bounded (so a
  still-defined `TrAsGrid_ByteData1_Table` is never touched when `TrAsGrid_ByteData1` is
  renamed), inside the comment part only, and never on a line whose comment speaks of the name
  historically ("was", "formerly", "renamed", "is now", "updated", "->" ...).

USAGE
  python3 scripts/analysis/claims_lint.py stale-names --out DIR
  python3 scripts/tools/fix_stale_renamed_names.py DIR/stale-names.tsv [--apply]
  Comment-only: `make gate-all` must stay 13/13.
"""
import argparse
import collections
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
ROW = re.compile(r'^STALE-RENAMED (\S+); RENAMED by .*?: (\S+) -> (\S+) \(defined\)')
HIST = re.compile(r'\b(was|were|formerly|renamed|old name|previously|used to be|is now|are now|'
                  r'now named|became|updated|replaced|retired)\b|->|=>|\u2192', re.I)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tsv")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    todo = collections.defaultdict(list)
    for r in [l.rstrip("\n").split("\t") for l in open(a.tsv, encoding="utf-8")][1:]:
        if len(r) < 5:
            continue
        m = ROW.match(r[4])
        if m and m.group(1) == m.group(2):
            todo[r[1]].append((int(r[2]), m.group(2), m.group(3)))
    done = skipped = 0
    for f, items in sorted(todo.items()):
        path = os.path.join(REPO, f)
        L = open(path, "rb").read().decode("latin-1").split("\n")
        for ln, old, new in items:
            line = L[ln - 1]
            sep = "//" if f.endswith((".c", ".h")) and "//" in line else (";" if ";" in line else None)
            if f.endswith((".c", ".h")) and sep is None:
                sep = "*" if "/*" in line or line.lstrip().startswith("*") else None
            if sep is None:
                print("SKIP %s:%d no comment part" % (f, ln)); skipped += 1
                continue
            ci = line.find("/*") if sep == "*" and "/*" in line else (0 if sep == "*" else line.find(sep))
            code, com = line[:ci], line[ci:]
            if HIST.search(com):
                print("SKIP %s:%d historical wording" % (f, ln)); skipped += 1
                continue
            pat = re.compile(r'(?<![A-Za-z0-9_])%s(?![A-Za-z0-9_])' % re.escape(old))
            com2, k = pat.subn(new, com)
            if not k:
                print("SKIP %s:%d %s not found in the comment" % (f, ln, old)); skipped += 1
                continue
            L[ln - 1] = code + com2
            done += k
        if a.apply:
            open(path, "wb").write("\n".join(L).encode("latin-1"))
    print("%s %d occurrence(s) in %d file(s); skipped %d line(s)" %
          ("replaced" if a.apply else "would replace", done, len(todo), skipped))
    return 0


if __name__ == "__main__":
    sys.exit(main())
