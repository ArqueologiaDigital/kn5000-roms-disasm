#!/usr/bin/env python3
"""symbolize_conditional_calls.py -- `call cc, (0xADDR:24)` with a numeric target -> the label at that address (v10/v9/v7).

QUESTION IT ANSWERS
  Conditional calls were left with numeric 24-bit targets: v10 had 24, e.g. `call nz, (0xf5e6eb:24)` eight times.
  They were found by the KN5000 helper-naming triage (analysis/kn5000-naming/, batch d).  The assembler takes a
  symbol in this form, as `call nz, (UI_PostRefreshEvent:24)` shows.  For every such line, this script looks the
  address up in the tree's symbol file (symbols/maincpu*_symbols_reference.txt).  It prefers a name that is not a
  local and not a continuation label, and writes `(Label:24)`.  A target with no label is reported and left as it
  is.  The byte gate checks the encodings.

RESULT (2026-10-06)
  First run: v10 22, v9 22, v7 25 symbolized; 2 / 2 / 1 targets had no label (v10 0xFC9A6C, 0xF5E768).  Those got
  the labels MidiCC_ClearReceivedBankSelects and AccPedal_ProcessAllChanges_Wrap in all three trees; the second run
  symbolized 2 / 2 / 1 more and left 0 numeric.

RUN (repository root; symbol files regenerated from a built tree)
  python3 scripts/tools/symbolize_conditional_calls.py [--apply]
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SYMS = {"v10": "symbols/maincpu_symbols_reference.txt", "v9": "symbols/maincpu_v9_symbols_reference.txt",
        "v7": "symbols/maincpu_v7_symbols_reference.txt"}
CALL = re.compile(r'^(\s*call\s+[a-z]+,\s*)\((0x[0-9a-fA-F]+):24\)(.*)$')
CONT = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Done|Next|Exit|Cont|End|Default|Resume|Nop)\d*$')


def main():
    apply = "--apply" in sys.argv
    for tree, sf in SYMS.items():
        best = {}
        for ln in open(os.path.join(ROOT, sf), encoding="latin-1"):
            f = ln.split()
            if len(f) != 2 or ln.startswith("#"):
                continue
            a, n = int(f[1], 16), f[0]
            rank = (n.startswith("."), bool(CONT.search(n)), len(n))
            if a not in best or rank < best[a][0]:
                best[a] = (rank, n)
        done, left = 0, []
        for p in sorted(glob.glob(os.path.join(ROOT, tree, "maincpu", "**", "*.s"), recursive=True)):
            L = open(p, "rb").read().decode("latin-1").split("\n")
            changed = False
            for i, x in enumerate(L):
                m = CALL.match(x)
                if not m:
                    continue
                a = int(m.group(2), 16)
                if a not in best or best[a][1].startswith("."):
                    left.append((os.path.relpath(p, ROOT), i + 1, m.group(2)))
                    continue
                L[i] = "%s(%s:24)%s" % (m.group(1), best[a][1], m.group(3))
                done += 1
                changed = True
            if changed and apply:
                data = "\n".join(L).encode("latin-1")
                open(p + ".tmp", "wb").write(data)
                os.replace(p + ".tmp", p)
        print("%s: %d conditional calls symbolized, %d left numeric" % (tree, done, len(left)))
        for x in left:
            print("    left %s:%d %s" % x)


if __name__ == "__main__":
    main()
