#!/usr/bin/env python3
"""respell_c_slice_tables_as_long.py -- code-pointer tables held as a compiled-C .incbin slice -> `.long Label` lines.

QUESTION IT ANSWERS
  Some compiled-C blobs are built without a link script: tonegen_param_table.c and gui_display_struct_data.c are
  `clang -c` + objcopy, with no NAKA_ADDR.  So a code-pointer table inside them can only be numbers in C, and the
  dispatch census grades its entries `numeric`.  After the census's C-SLICE detector found such tables
  (dispatch-census-2026-10-06-29) and their targets were labelled (place_kn5000_labels.py), the remaining
  blocker was that spelling.  As name_semenu_switch_handlers.py did for 14 such slices, this script replaces each
  listed table's `.incbin` slice with one `.long` per word, spelled by the label at that address.  It uses the
  tree's symbol file and prefers non-local names.  It asserts that:
    - the slice length is a multiple of 4;
    - every word is 0 or the address of a label.
  The C object keeps its bytes, which are simply no longer included by this slice.  The byte gate is the proof.

RUN (repository root; symbol files regenerated from a built tree)
  python3 scripts/tools/respell_c_slice_tables_as_long.py [--apply]
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TABLES = ["Naka_ApFuncTable_12B", "GUI_DisplayStructData_0x1100"]
SYMS = {"v10": "symbols/maincpu_symbols_reference.txt", "v9": "symbols/maincpu_v9_symbols_reference.txt",
        "v7": "symbols/maincpu_v7_symbols_reference.txt"}
CONT = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Done|Next|Exit|Cont|End|Default|Resume|Nop)\d*$')
INC = re.compile(r'^(\w+):(\s*)\.incbin\s+"([^"]+)",\s*(0x[0-9A-Fa-f]+|\d+),\s*(0x[0-9A-Fa-f]+|\d+)\s*$')


def main():
    apply = "--apply" in sys.argv
    for tree, sf in SYMS.items():
        best, addr_of = {}, {}
        for ln in open(os.path.join(ROOT, sf), encoding="latin-1"):
            f = ln.split()
            if len(f) != 2 or ln.startswith("#") or f[0].startswith("."):
                continue
            a = int(f[1], 16)
            addr_of[f[0]] = a
            rank = (bool(CONT.search(f[0])), len(f[0]))
            if a not in best or rank < best[a][0]:
                best[a] = (rank, f[0])
        rom = open(os.path.join(ROOT, "original_ROMs", "kn5000_%s_program.rom" % tree), "rb").read()
        for p in sorted(glob.glob(os.path.join(ROOT, tree, "maincpu", "**", "*.s"), recursive=True)):
            L = open(p, "rb").read().decode("latin-1").split("\n")
            changed = False
            for i, x in enumerate(L):
                m = INC.match(x)
                if not m or m.group(1) not in TABLES:
                    continue
                lab, size = m.group(1), int(m.group(5), 0)
                assert size % 4 == 0, (tree, lab, size)
                a = addr_of[lab] - 0xE00000
                words = [int.from_bytes(rom[a + 4 * k:a + 4 * k + 4], "little") for k in range(size // 4)]
                bad = [hex(w) for w in words if w and w not in best]
                assert not bad, (tree, lab, bad)
                names = ["0" if w == 0 else best[w][1] for w in words]
                L[i:i + 1] = ["%s:%s.long %s" % (lab, m.group(2), names[0])] + ["\t.long %s" % n for n in names[1:]]
                changed = True
                print("%s: %s -> %d .long lines" % (tree, lab, len(names)))
            if changed and apply:
                data = "\n".join(L).encode("latin-1")
                with open(p + ".tmp", "wb") as fh:
                    fh.write(data)
                os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
