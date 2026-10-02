#!/usr/bin/env python3
"""drop_unused_positional_aliases.py -- delete `.set Base_0xNN, ...` aliases that nothing mentions.

QUESTION THIS ANSWERS / JOB IT DOES
  shared/positional_labels.s (and a few other files) define thousands of positional aliases,
  `.set Str_No_0x38, Str_No + 56`: a second, address-only name for a byte inside an object.
  They were generated for every intra-object reference an early pass met; later passes named
  or retired most of their uses, and on 2026-10-02 400 of v10's 2,483 were used by no line
  of code at all.  An alias nobody uses is pure debt (semantic_debt_dashboard.py `posalias`).

  An alias is dropped only when its name appears NOWHERE else: no code, no comment, no other
  `.set`, in any .s/.c/.h of the tree, nor in docs/, notes/ or ../technics-docs -- so no text
  is left quoting a name that no longer exists.  Its definition line is deleted; nothing
  else changes.  `make gate-all` proves it (an alias emits no byte).

USAGE
  python3 scripts/tools/drop_unused_positional_aliases.py --tree v10 [--apply]
"""
import argparse
import collections
import glob
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
SET = re.compile(r'^\s*\.set\s+(\w+_0x[0-9A-Fa-f]+)\s*,')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    files = [f for ext in ("s", "c", "h") for f in glob.glob(os.path.join(REPO, a.tree, "maincpu", "**", "*." + ext), recursive=True)]
    texts = {f: open(f, "rb").read().decode("latin-1") for f in files}
    defs = {}
    for f, t in texts.items():
        for i, l in enumerate(t.split("\n")):
            m = SET.match(l)
            if m:
                defs[m.group(1)] = (f, i)
    words = collections.Counter()
    for f, t in texts.items():
        words.update(re.findall(r'[A-Za-z_]\w*', t))
    extra = []
    for d in (os.path.join(REPO, "docs"), os.path.join(REPO, "notes"), os.path.join(REPO, "..", "technics-docs")):
        for f in glob.glob(os.path.join(d, "**", "*"), recursive=True):
            if f.endswith((".md", ".json", ".txt", ".py", ".tsv")) and os.path.isfile(f) and "/_site/" not in f:
                extra.append(open(f, "rb").read().decode("latin-1"))
    elsewhere = collections.Counter()
    for t in extra:
        elsewhere.update(w for w in re.findall(r'[A-Za-z_]\w*', t) if w in defs)
    drop = {n for n in defs if words[n] == 1 and elsewhere[n] == 0}
    by_file = collections.defaultdict(set)
    for n in drop:
        by_file[defs[n][0]].add(defs[n][1])
    if a.apply:
        for f, lines in by_file.items():
            L = texts[f].split("\n")
            L = [l for i, l in enumerate(L) if i not in lines]
            open(f, "wb").write("\n".join(L).encode("latin-1"))
    print("%s: %d positional aliases, %d mentioned nowhere else -> %s" %
          (a.tree, len(defs), len(drop), "dropped" if a.apply else "would drop"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
