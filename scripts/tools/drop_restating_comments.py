#!/usr/bin/env python3
"""drop_restating_comments.py -- comments that only repeat their instruction go (CLAUDE.md Comment Quality).

QUESTION THIS ANSWERS / JOB IT DOES
  The ASL-era conversion left the original listing's instruction text as a trailing comment:
  `calr Boot_WaitFDCReady ; CALR Boot_WaitFDCReady`, `ld xbc, 0x800000 ; LD XBC, 0x00800000 -
  dest`.  CLAUDE.md's Comment Quality policy (STRICT): no comment that restates the line.  A
  trailing comment whose text -- or whose part before ` - ` -- is the line's own instruction
  (case, blanks, `h`-suffix hex and leading zeros ignored) is dropped, keeping what follows the
  ` - ` when there is something: `; dest`.  Comments only: no byte changes.  On 2026-10-02:
  hdae5000 1,830, table_data 853, v10/v9 48, v7 49, v142 24, subcpu boot 4, wsa1 4.

USAGE
  python3 scripts/tools/drop_restating_comments.py DIR [DIR ...] [--apply]
"""
import glob
import os
import re
import sys


def norm(s):
    s = s.strip().lower()
    s = re.sub(r'\b([0-9a-f]+)h\b', lambda m: "0x" + m.group(1), s)
    s = re.sub(r'0x0*([0-9a-f]+)', lambda m: "0x" + m.group(1), s)
    return re.sub(r'\s+', '', s)


def main():
    apply = "--apply" in sys.argv
    for d in [x for x in sys.argv[1:] if x != "--apply"]:
        n = 0
        for f in sorted(glob.glob(os.path.join(d, "**", "*.s"), recursive=True)):
            L = open(f, "rb").read().decode("latin-1").split("\n")
            changed = False
            for i, l in enumerate(L):
                if ";" not in l or l.lstrip().startswith(";") or '"' in l:
                    continue
                k = l.index(";")
                code, cm = l[:k], l[k + 1:]
                insn = re.sub(r'^[A-Za-z_][\w.$]*:', '', code).strip()
                if not insn or insn.startswith("."):
                    continue
                parts = re.split(r'\s+-\s+', cm.strip(), maxsplit=1)
                if norm(parts[0]) != norm(insn):
                    continue
                rest = parts[1].strip() if len(parts) > 1 else ""
                L[i] = code.rstrip() + ("\t; " + rest if rest else "")
                changed = True
                n += 1
            if changed and apply:
                open(f, "wb").write("\n".join(L).encode("latin-1"))
        print("%s: %d comments%s" % (d, n, "" if apply else " (dry run)"))


if __name__ == "__main__":
    main()
