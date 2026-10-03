#!/usr/bin/env python3
"""label_regobjtable_args.py -- the numeric ROM addresses RegObjTable / RegObjTabl register get <Module>_<Kind>Table/Count_<SLOT> labels.

QUESTION THIS ANSWERS / JOB IT DOES
  `RegObjTable class, proc, COUNT_ADDR, TABLE, slot` registers a table whose entry count is the WORD
  at COUNT_ADDR; `RegObjTabl class, proc, count, TABLE, slot` takes the count as a number
  (scripts/analysis/nakarest_objtab_map.py).  Where TABLE or COUNT_ADDR is still a number with no
  label, symbolize_far_pointer_pushes.py reports "macro arg, no symbol" (11-12 per maincpu tree on
  2026-10-03).  The tree's own names for these objects are `<Module>_<Kind>Table_<SLOT>` and
  `<Module>_<Kind>Count_<SLOT>` (Scoop_ResEventTable_1C6, Yoko_ClassCount_167): Kind is the class
  (NAKA_CLASS_<Kind>), SLOT the registry slot in upper-case hex, and Module the module whose
  `Initialize<Module>` routine holds the registration (InitializeScoop registers 0x166, 0x1C6,
  0x1E6, 0x126/0x426, 0x106/0x406 ...; InitializeKubo 0x168 ... 0x108/0x408 -- checked 2026-10-03:
  the Class/Res*/*Function slots carry the module's low digit, the Viewable/ResName slots do NOT,
  which is why the routine and not the slot names the module).  This places those labels with
  scripts/tools/place_labels.py; RAM addresses (the tables Yoko registers at 0x3DF10 / 0x3DF14,
  inside the work-RAM image) are reported, not labelled.  Then run
  symbolize_far_pointer_pushes.py --apply (after `make`) to spell the macro arguments.

USAGE
  python3 scripts/tools/label_regobjtable_args.py --tree v10 [--apply]
"""
import argparse
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
import place_labels  # noqa: E402
import symbolize_far_pointer_pushes as fp  # noqa: E402

REG = re.compile(r'^\s*(RegObjTable|RegObjTabl)\s+NAKA_CLASS_(\w+)\s*,\s*(\w+)\s*,\s*([^,]+?)\s*,'
                 r'\s*([^,]+?)\s*,\s*(0x[0-9a-fA-F]+)\s*(?:;.*)?$')
NUM = re.compile(r'^(0x[0-9a-fA-F]+|\d+)$')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=["v10", "v9", "v7"])
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    elf, src, (lo, hi) = fp.IMAGES[a.tree]
    syms = fp.elf_symbols(elf)
    taken = set(n for ns in syms.values() for n in ns)
    planner = place_labels.Planner(a.tree)
    want, notes = {}, []
    for root, _, fs in os.walk(os.path.join(REPO, src)):
        for fn in sorted(fs):
            if not fn.endswith(".s"):
                continue
            p = os.path.join(root, fn)
            init = None
            for k, l in enumerate(open(p, "rb").read().decode("latin-1").split("\n")):
                mi = re.match(r'^Initialize(\w+):', l)
                if mi:
                    init = mi.group(1)
                m = REG.match(l)
                if not m:
                    continue
                macro, kind, _, cnt, table, slot = m.groups()
                s = int(slot, 16)
                mod = init
                pairs = [(table, "%s_%sTable_%X" % (mod, kind, s))]
                if macro == "RegObjTable":
                    pairs.append((cnt, "%s_%sCount_%X" % (mod, kind, s)))
                for arg, name in pairs:
                    if not NUM.match(arg) or not mod:
                        continue
                    v = int(arg, 0)
                    if v in syms:
                        continue
                    if not lo <= v <= hi:
                        notes.append("%s:%d %s=0x%x is not in this ROM (RAM?): not labelled" % (fn, k + 1, name, v))
                        continue
                    want.setdefault(v, name)
    for v, name in sorted(want.items()):
        nm, n = name, 2
        while nm in taken:
            nm, n = "%s_%d" % (name, n), n + 1
        how = planner.add(v, nm)
        taken.add(nm)
        print("  0x%06x %-32s %s" % (v, nm, how))
    for x in notes:
        print("  " + x)
    print("%s: %d labels%s" % (a.tree, len(want), "" if a.apply else " (dry run)"))
    if a.apply:
        planner.apply()
    return 0


if __name__ == "__main__":
    sys.exit(main())
