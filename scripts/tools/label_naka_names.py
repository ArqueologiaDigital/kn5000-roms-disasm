#!/usr/bin/env python3
"""label_naka_names.py -- the name strings the registered NAKA name tables point at get labels.

QUESTION THIS ANSWERS / JOB IT DOES
  Every Viewable table in registry slot S has a ResName table in slot S + 0x300: entry k points
  at the NAME string of element k ("SMFMuteSw", or "" for the 2,740 unnamed ones); every
  Function / ApFunction / MainFunction code table has a name table in slot + 0x300 likewise
  ("ApEditSyori").  Those strings sit inside `.incbin` slices with no label, so the tables are
  `.long 0x00EA754A` numbers (235 in v10 on 2026-10-02) or bytes.  Per entry k of every such
  name table (scripts/analysis/nakarest_objtab_map.py):
    * ResName entry k  -> `<label of record k>_Name` (the record labels of
      scripts/tools/label_naka_records.py, run first);
    * function name entry k -> `FuncName_<the string>` (CLAUDE.md's prefix for function-name
      strings), `_<Module>` when two modules register the same name;
    * the table's end marker (entry <count>, a pointer to the "" right after it) -> `<table
      label>_EndName`;
  placed with scripts/tools/place_labels.py (in front of the line, or by cutting the slice) --
  only where a numeric `.long` points at the string: a table still held as `.incbin` bytes
  references nothing symbolically, and labelling its 3,000-odd strings would only cut slices;
  a string that already has a column-0 label keeps it.  Follow with
  scripts/tools/symbolize_long_pointers.py (after `make`) to turn the `.long`s into the labels.
  Labels emit no byte: `make gate-all` proves it.

USAGE
  make all
  python3 scripts/tools/label_naka_names.py --tree v10 [--apply]
"""
import argparse
import collections
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import nakarest_objtab_map as nom             # noqa: E402
import place_labels                           # noqa: E402
import symbolize_far_pointer_pushes as fp     # noqa: E402

IDENT = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')
FUNCS = ("Function", "ApFunction", "MainFunction")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    m = nom.Map(a.tree)
    elf, src, _ = fp.IMAGES[a.tree]
    files = [os.path.join(dp, f) for dp, _, fs in os.walk(os.path.join(REPO, src)) for f in fs if f.endswith(".s")]
    col0 = fp.col0_labels(files)
    syms = fp.elf_symbols(elf)
    lab = {ad: fp.pick([n for n in ns if n in col0], col0) for ad, ns in syms.items() if any(n in col0 for n in ns)}
    taken = set(n for ns in syms.values() for n in ns)
    want = {}                                           # string address -> name
    fnames = collections.defaultdict(set)
    for r in m.regs:
        if nom.CLASS.get(r["cls"]) in FUNCS and r["slot"] >= 0x300 and m.inrom(r["table"]):
            for k in range(r["count"]):
                s = m.string_at(m.u32(r["table"] + 4 * k))
                if s and IDENT.match(s):
                    fnames[s].add(r["slot"])
    for r in sorted(m.regs, key=lambda r: r["slot"]):
        kind = nom.CLASS.get(r["cls"])
        if not m.inrom(r["table"]) or r["slot"] < 0x300 or kind not in ("ResName",) + FUNCS:
            continue
        tl = lab.get(r["table"])
        view = m.by_slot.get(r["slot"] - 0x300)
        for k in range(r["count"] + 1):
            p = m.u32(r["table"] + 4 * k)
            if not m.inrom(p) or p in want:
                continue
            s = m.string_at(p)
            if k == r["count"]:
                if s or not tl:
                    continue
                nm = tl + "_EndName"
            elif kind == "ResName":
                rec = m.u32(view["table"] + 4 * k) if view and k < view["count"] else None
                if rec is None or rec not in lab:
                    continue
                nm = lab[rec] + "_Name"
            else:
                if not (s and IDENT.match(s)):
                    continue
                nm = "FuncName_" + s
                if len(fnames[s]) > 1:
                    nm += "_" + (r["init"] or "Initialize?")[10:]
            want[p] = nm
    # only where a numeric `.long` points (CLAUDE.md: split a binary where something references
    # inside it); a table still held as bytes needs no label on its strings
    refd = set()
    for f in files:
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            mm = re.match(r'^(?:[A-Za-z_][\w.$]*:)?\s*\.(?:long|4byte)\s+([^;]*)', l)
            if mm:
                refd |= set(int(x.strip(), 0) for x in mm.group(1).split(",") if re.match(r'^\s*(0x[0-9a-fA-F]+|\d+)\s*$', x))
    planner = place_labels.Planner(a.tree)
    st = collections.Counter()
    for p, nm in sorted(want.items()):
        if p not in refd:
            st["no numeric reference"] += 1
            continue
        if p in lab:
            st["has a label"] += 1
            continue
        base, kk = nm, 2
        while nm in taken:
            nm, kk = "%s_%d" % (base, kk), kk + 1
        taken.add(nm)
        st["placed: " + planner.add(p, nm)] += 1
    print("%s: %d name strings; %s%s" % (a.tree, len(want), dict(st), "" if a.apply else " (dry run)"))
    if a.apply:
        planner.apply()
    return 0


if __name__ == "__main__":
    sys.exit(main())
