#!/usr/bin/env python3
"""label_long_targets.py -- the target of a numeric `.long` table entry gets a label named after its table.

QUESTION THIS ANSWERS / JOB IT DOES
  After the NAKA record / name / style-browser passes, a few numeric own-ROM `.long` values per
  tree still point where no label is (v10 18 on 2026-10-02): handler tables pointing at code
  (`.long 0x00EF013F`), and odd data.  For each, the table is the nearest column-0 label above
  the `.long` line and k the entry's index counted from it; the target gets
  `<Table>_Target<k>` when a code line starts there (the house style for dispatch targets:
  UIState_EventTable_Target6), `<Table>_Str_<Text>` when a NUL-terminated ASCII string starts
  there, else `<Table>_Data<k>` -- placed by scripts/tools/place_labels.py (in front of the
  line, or by cutting the slice / list).  Then scripts/tools/symbolize_long_pointers.py spells
  the entries.  A label emits no byte: `make gate-all`.

USAGE
  make all
  python3 scripts/tools/label_long_targets.py --tree v10 [--apply]
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
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import place_labels                           # noqa: E402
import split_blobs_at_far_pointers as sb      # noqa: E402
import symbolize_far_pointer_pushes as fp     # noqa: E402

COL0 = re.compile(r'^([A-Za-z_][\w.$]*):')
LONG = re.compile(r'^(?:[A-Za-z_][\w.$]*:)?\s*\.(?:long|4byte)\s+([^;]*)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7", "hdae5000", "prom_a", "prom_b", "prom_c"))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    elf, src, (lo, hi) = fp.IMAGES[a.tree]
    syms = fp.elf_symbols(elf)
    taken = set(n for ns in syms.values() for n in ns)
    rom_path, base = sb.ROM[a.tree]
    rom = open(os.path.join(REPO, rom_path), "rb").read()
    p = place_labels.Planner(a.tree)
    own = place_labels.snb.own_prefix(p.img)          # WSA1 images share one source root
    rels = [r for r in (os.path.relpath(f, p.srcroot) for f in glob.glob(os.path.join(p.srcroot, "**", "*.s"), recursive=True))
            if r.startswith(own)]
    want, st = {}, collections.Counter()
    for rel in sorted(rels):
        table, k = None, 0
        for l in p.lines(rel):
            m = COL0.match(l)
            if m:
                table, k = m.group(1), 0
            ml = LONG.match(l)
            if not ml:
                continue
            for it in ml.group(1).split(","):
                s = it.strip()
                if re.match(r'^(0x[0-9a-fA-F]+|\d+)$', s) and lo <= int(s, 0) <= hi and int(s, 0) not in syms \
                        and table and int(s, 0) not in want:
                    v = int(s, 0)
                    w = p.where(v)
                    code = bool(w) and w[0] == v and \
                        place_labels.snb.drc.classify_line(p.lines(w[1])[w[2]], p.macros)[0] == "code"
                    st_ = sb.c_string_at(rom, base, v)
                    if code:
                        want[v] = "%s_Target%d" % (table, k)
                    elif st_ is not None and len(st_) >= 2 and rom[v - base - 1] in (0, 0xff):
                        want[v] = "%s_Str_%s" % (table, sb.text_token(st_))
                    else:
                        want[v] = "%s_Data%d" % (table, k)
                k += 1
    for v, nm in sorted(want.items()):
        b, n = nm, 2
        while nm in taken:
            nm, n = "%s_%d" % (b, n), n + 1
        how = p.add(v, nm)
        if how in ("line-start", "incbin", "list"):
            taken.add(nm)
        st["placed: " + how] += 1
    print("%s: %d targets; %s%s" % (a.tree, len(want), dict(st), "" if a.apply else " (dry run)"))
    if a.apply:
        p.apply()
    return 0


if __name__ == "__main__":
    sys.exit(main())
