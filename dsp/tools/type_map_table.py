#!/usr/bin/env python3
"""type_map_table.py -- turn a type_map_rebuild.sh log into the TYPE map table.

Each row is MEASURED: the index was selected with the calibrated transport and the program was
identified from the machine's own upload capture, never from the panel text (which returns garbage
in this build) and never by deduplicating consecutive images (which is what broke the first map --
two adjacent slots sharing one program image collapsed into a single row and shifted every later
index).

★ The fingerprint CANNOT be ambiguous between distinct listings: all 38 body images are unique on
16 words (verified by construction). Several TYPE slots legitimately resolve to the SAME program --
the twelve named effects that ship an image byte-identical to NO OPERATION -- and that is a result,
not a collision: this method reports the program per index instead of collapsing the repeats.

    python3 dsp/tools/type_map_table.py rebuild.log > table.md
"""
import csv
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TSV = os.path.join(os.path.dirname(HERE), "programs.tsv")
LINE = re.compile(r"^TYPE\s+(\d+)\s+(✅|⚠|⛔)\s*(.*)$")


def names():
    out = {}
    with open(TSV) as f:
        for row in csv.reader((l for l in f if not l.startswith("#")), delimiter="\t"):
            if len(row) > 10 and row[10].endswith(".dsm"):
                out[row[10][:-4]] = row[1]
    return out


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    nm = names()
    print("| TYPE | program | effect |")
    print("|-----:|---|---|")
    n = 0
    for ln in open(sys.argv[1], errors="replace"):
        m = LINE.match(ln.strip())
        if not m:
            continue
        idx, mark, prog = int(m.group(1)), m.group(2), m.group(3).strip()
        n += 1
        if mark != "✅":
            print("| %d | %s **%s** | ⚠ unresolved |" % (idx, mark, prog))
        else:
            print("| %d | `%s` | %s |" % (idx, prog, nm.get(prog, "?")))
    print("\n%d indices, each MEASURED from the machine's own upload capture." % n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
