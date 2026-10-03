#!/usr/bin/env python3
"""drop_codeless_positional_aliases.py -- positional aliases no code or data uses are deleted.

QUESTION THIS ANSWERS / JOB IT DOES
  drop_unused_positional_aliases.py keeps an alias (`.set Base_0x1C, Base + 28`) while ANY text
  mentions it -- a dated report under notes/ included -- so after the 2026-10-02 passes v10 still
  carried 117 aliases that no instruction, data directive, C source or link script uses: their
  only mentions were source comments and records of past states.  This deletes the `.set` of every
  alias no non-comment text of the tree (.s/.c/.h/.ld) uses; follow with
  scripts/tools/fix_stale_positional_comments.py, which turns the comment mentions into the label
  now at that address.  Dated notes keep the names they recorded.  A `.set` that nothing uses
  emits nothing: `make gate-all`.

USAGE
  python3 scripts/tools/drop_codeless_positional_aliases.py --tree v10 [--apply]
"""
import argparse
import glob
import re
import sys

SET = re.compile(r'^\s*\.(?:set|equ)\s+(\w+_0x[0-9A-Fa-f]+)\s*,\s*[A-Za-z_][\w.$]*\s*\+\s*(?:0x[0-9a-fA-F]+|\d+)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    files = [f for g in ("*.s", "*.c", "*.h", "*.ld") for f in glob.glob("%s/maincpu/**/%s" % (a.tree, g), recursive=True)]
    txt = {f: open(f, "rb").read().decode("latin-1").split("\n") for f in files}
    al = set(SET.match(l).group(1) for L in txt.values() for l in L if SET.match(l))
    pat = re.compile(r'(?<![\w.$])(%s)(?![\w$])' % "|".join(map(re.escape, sorted(al, key=len, reverse=True))))
    used = set()
    for f, L in txt.items():
        if f.endswith((".c", ".h", ".ld")):
            # C and link-script COMMENTS are comments too (2026-10-03: v7 kept 61 aliases whose
            # only "use" was a `* xwa, Name_0x140` line inside a /* ... */ block)
            body = re.sub(r'/\*.*?\*/', ' ', "\n".join(L), flags=re.S)
            body = re.sub(r'//[^\n]*', ' ', body)
            used |= set(m.group(1) for m in pat.finditer(body))
            continue
        for l in L:
            if SET.match(l):
                continue
            used |= set(m.group(1) for m in pat.finditer(l.split(";", 1)[0]))
    drop = al - used
    print("%s: %d positional aliases, %d used by nothing but comments -> %s" % (a.tree, len(al), len(drop), "deleted" if a.apply else "would delete"))
    if a.apply:
        for f, L in txt.items():
            out = [l for l in L if not (SET.match(l) and SET.match(l).group(1) in drop)]
            if len(out) != len(L):
                open(f, "wb").write("\n".join(out).encode("latin-1"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
