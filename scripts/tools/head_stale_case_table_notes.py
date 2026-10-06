#!/usr/bin/env python3
"""head_stale_case_table_notes.py -- replace stale "[nakarest] purpose not established" notes above case-offset tables.

QUESTION IT ANSWERS
  The [nakarest] pass left "purpose not established: layout of N B ... not derived" above some slices.  Later
  work turned many of them into the offset tables of compiled `switch` statements:
  - spelled `.short <Case> - <Base>` by scripts/converters/naka_case_tables_retype.py;
  - named <Reader>_CaseTable by scripts/renaming/gen_case_table_names.py;
  - typed in C.
  The dispatch census's D detector reads them from their `jp t, (xR+rr)` sites, so the notes are stale.
  For every such note, this script replaces the [nakarest] block with a one-line header.  It acts only when all of
  these hold:
    - the next non-comment line is a bare `Label:`;
    - the lines after it are one unbroken run of `.short A - B` lines that all share one B;
    - the note names a reader ("source references X").
  The header says what the table is: "<Label> -- N x int16: the case offsets of <Reader>'s compiled switch,
  relative to <B>".  N and B come from the lines, and Reader from the note.

RUN (repository root)
  python3 scripts/tools/head_stale_case_table_notes.py [--apply]
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SHORT = re.compile(r'^\t\.short\t([A-Za-z_.$][\w.$]*)\s*-\s*([A-Za-z_.$][\w.$]*)\s*(;.*)?$')


def main():
    apply = "--apply" in sys.argv
    for tree in ("v10", "v9", "v7"):
        n = 0
        for p in sorted(glob.glob(os.path.join(ROOT, tree, "maincpu", "**", "*.s"), recursive=True)):
            L = open(p, "rb").read().decode("latin-1").split("\n")
            out, i, changed = [], 0, 0
            while i < len(L):
                if L[i].startswith("; [nakarest]") and (i == 0 or not L[i - 1].startswith("; [nakarest]")):
                    j = i
                    while L[j].startswith("; [nakarest]"):
                        j += 1
                    blk = L[i:j]
                    m = re.match(r'^([A-Za-z_]\w*):\s*$', L[j])
                    shorts = []
                    k = j + 1
                    while k < len(L) and SHORT.match(L[k]):
                        shorts.append(SHORT.match(L[k]))
                        k += 1
                    rd = re.search(r'source references (\w+)', " ".join(blk))
                    if (m and any("purpose not established" in b for b in blk) and shorts and rd
                            and len({s.group(2) for s in shorts}) == 1):
                        out.append("; %s -- %d x int16: the case offsets of %s's compiled switch, relative to %s"
                                   % (m.group(1), len(shorts), rd.group(1), shorts[0].group(2)))
                        i = j
                        changed += 1
                        continue
                out.append(L[i])
                i += 1
            if changed:
                n += changed
                if apply:
                    data = "\n".join(out).encode("latin-1")
                    open(p + ".tmp", "wb").write(data)
                    os.replace(p + ".tmp", p)
        print("%s: %d stale notes %s" % (tree, n, "replaced" if apply else "to replace"))


if __name__ == "__main__":
    main()
