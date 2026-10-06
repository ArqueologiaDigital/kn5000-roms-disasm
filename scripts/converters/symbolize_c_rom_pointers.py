#!/usr/bin/env python3
"""symbolize_c_rom_pointers.py -- numeric ROM pointers in the compiled-C blobs -> NAKA_ADDR(Label) (v10, v9, v7).

QUESTION IT ANSWERS
  The C sources of the main-CPU blobs (v10/maincpu/**/naka_*.c and friends) still hold many 32-bit initializer
  values that are ROM addresses spelled as numbers, e.g. `.CmpStepTitleFunc_ProcTable = { 0x00F6A2FF, ... }` or
  `.Suna_ViewableTable_010 = { 0x00E176F6, ... }`.  The .s side and the census see only the bytes, so a number here
  is invisible debt: the dispatch census reads a C table as symbolic only when its entries are names in the blob's
  link script.
  For every C file with a `<stem>_link.ld` beside it, this script finds each initializer element that is a lone
  8-hex-digit literal 0x00E00000..0x00FFFFFF (an element between `{` / `,` / `=` and `,` / `}`).  When that value
  is the address of a label in the tree's symbol file (symbols/maincpu*_symbols_reference.txt), it writes
  `NAKA_ADDR(Label)`.  It prefers a label that is not a local continuation (_Skip/_Join/_Loop/...).  It adds
  `extern const char Label;` to the C file and `Label = 0x00XXXXXX;` to its link script when they are missing.
  - Only code segments change.  Comments and strings are never touched, so the C comment gate stays exact.
  - A value with no label stays a number and is counted.
  - The DrawString colour pairs (0x00FF00F5, ...) are never converted, even when one equals a label address.
  The value does not change, so the compiled bytes do not change.  The byte gate is the proof.
  v7 (`--trees v7`) follows the v7 C flow.  v7's C files carry v10's values, which v7_c_divergence.json relocates,
  so a v7 literal is looked up in v10's symbol file and its link script gets the v10 address.  The compiled bytes
  stay the same.  Then scripts/generators/generate_v7_naka_link_scripts.py --apply moves each new symbol to its v7
  address where v7's own bytes agree, and scripts/build/regenerate_v7_c_divergence.py --apply re-derives the
  patches (it certifies every patched bin), BEFORE make.

RUN (repository root; symbol files regenerated from a built tree)
  python3 scripts/converters/symbolize_c_rom_pointers.py [--apply] [--trees v10,v9]
  python3 scripts/converters/symbolize_c_rom_pointers.py --trees v7 --apply; generate_v7_naka_link_scripts.py --apply;
      regenerate_v7_c_divergence.py --apply; make all; make gate-all
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts/converters"))
from name_resname_strings import segments   # noqa: E402

SYMS = {"v10": "symbols/maincpu_symbols_reference.txt", "v9": "symbols/maincpu_v9_symbols_reference.txt"}
CONT = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Done|Next|Exit|Cont|End|Default|Resume|Nop)\d*$')
LIT = re.compile(r'(?<=[{,=\s])(\s*)0x00([EeFf][0-9A-Fa-f]{5})(?=\s*[,}])')
COLOUR = {0x00FF0008, 0x00FF00F2, 0x00FF00F5, 0x00FF00F7, 0x00FB00F5, 0x00FB00F7, 0x00F400F7}


def load_syms(tree):
    best = {}
    for ln in open(os.path.join(ROOT, SYMS[tree]), encoding="latin-1"):
        f = ln.split()
        if len(f) != 2 or ln.startswith("#") or f[0].startswith("."):
            continue
        a, n = int(f[1], 16), f[0]
        rank = (bool(CONT.search(n)), len(n))
        if a not in best or rank < best[a][0]:
            best[a] = (rank, n)
    return {a: n for a, (r, n) in best.items()}


def main():
    apply = "--apply" in sys.argv
    trees = ["v10", "v9"]
    if "--trees" in sys.argv:
        trees = sys.argv[sys.argv.index("--trees") + 1].split(",")
    for tree in trees:
        syms = load_syms("v10" if tree == "v7" else tree)   # v7's C holds v10's values (see the docstring)
        tot = left = 0
        for pc in sorted(glob.glob(os.path.join(ROOT, tree, "maincpu", "**", "*.c"), recursive=True)):
            pl = pc[:-2] + "_link.ld"
            if not os.path.exists(pl):
                continue
            C = open(pc, "rb").read().decode("latin-1")
            LD = open(pl, "rb").read().decode("latin-1")
            lddef = dict((m.group(1), int(m.group(2), 16)) for m in re.finditer(r'^(\w+)\s*=\s*0x([0-9A-Fa-f]+);', LD, re.M))
            used, n, nl = set(), 0, 0

            def sub(m):
                nonlocal n, nl
                a = int(m.group(2), 16)
                name = syms.get(a)
                if a in COLOUR or not name or (name in lddef and lddef[name] != a):
                    nl += 1
                    return m.group(0)
                used.add(name)
                n += 1
                return "%sNAKA_ADDR(%s)" % (m.group(1), name)
            C2 = "".join(LIT.sub(sub, s) if k == "code" else s for k, s in segments(C))
            if not n:
                left += nl
                continue
            ext = set(re.findall(r'^extern const char (\w+);', C2, re.M))
            new_ext = sorted(used - ext)
            if new_ext:
                last = [m.end() for m in re.finditer(r'^extern const char \w+;\n', C2, re.M)]
                at = last[-1] if last else C2.index('#include "naka_types.h"\n') + len('#include "naka_types.h"\n')
                C2 = C2[:at] + "".join("extern const char %s;\n" % x for x in new_ext) + C2[at:]
            new_ld = sorted(x for x in used if x not in lddef)
            if new_ld:
                LD = LD.rstrip("\n") + "\n" + "".join("%s = 0x%08X;\n" % (x, next(a for a, v in syms.items() if v == x))
                                                    for x in new_ld)
            print("  %-48s %4d symbolized, %4d left numeric, +%d externs" % (os.path.relpath(pc, ROOT), n, nl, len(new_ext)))
            tot += n
            left += nl
            if apply:
                for p, s in ((pc, C2), (pl, LD)):
                    data = s.encode("latin-1")
                    with open(p + ".tmp", "wb") as fh:
                        fh.write(data)
                    os.replace(p + ".tmp", p)
        print("%s: %d ROM pointers symbolized, %d ROM-range literals left numeric" % (tree, tot, left))


if __name__ == "__main__":
    main()
