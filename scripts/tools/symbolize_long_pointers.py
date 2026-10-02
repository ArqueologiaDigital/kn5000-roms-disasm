#!/usr/bin/env python3
"""symbolize_long_pointers.py -- numeric ROM addresses in `.long` data become the labels that are there.

QUESTION THIS ANSWERS / JOB IT DOES
  A pointer table written `.long 0x00EB2A16` says nothing and breaks the moment the target
  moves.  For every numeric value on a `.long` / `.4byte` line of a tree that lies in the
  tree's own ROM range and has a column-0 label in the linked ELF at exactly that address,
  the number is replaced by the label (symbolize_far_pointer_pushes.pick: a column-0,
  non-structural, shortest name first).  Values with no label there are counted, not touched
  (notes/data-pointer-symbolization-2026-10-02/long_pointer_census.py says where they point).
  A symbol resolves to the same 32 bits: `make gate-all` proves it.

USAGE
  make all
  python3 scripts/tools/symbolize_long_pointers.py --tree v10 [--apply]
  trees: v10 v9 v7 hdae5000 tabledata prom_a prom_b prom_c (symbolize_far_pointer_pushes.IMAGES)
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
import symbolize_far_pointer_pushes as fp     # noqa: E402

LONG = re.compile(r'^(?P<pre>(?:[A-Za-z_][\w.$]*:)?\s*\.(?:long|4byte)\s+)(?P<items>[^;]*?)(?P<post>\s*(?:;.*)?)$')
NUM = re.compile(r'^(0x[0-9a-fA-F]+|\d+)$')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=sorted(fp.IMAGES))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    elf, src_glob, (lo, hi) = fp.IMAGES[a.tree]
    files = sorted(glob.glob(os.path.join(REPO, src_glob, "**", "*.s"), recursive=True))
    col0 = fp.col0_labels(files)
    syms = fp.elf_symbols(elf)
    best = {ad: fp.pick([n for n in ns if n in col0], col0) for ad, ns in syms.items()
            if lo <= ad <= hi and any(n in col0 for n in ns)}
    st = collections.Counter()
    for f in files:
        t = open(f, "rb").read().decode("latin-1")
        out = []
        for l in t.split("\n"):
            m = LONG.match(l)
            if m:
                its = m.group("items").split(",")
                for i, it in enumerate(its):
                    s = it.strip()
                    if NUM.match(s) and lo <= int(s, 0) <= hi:
                        if int(s, 0) in best:
                            its[i] = it.replace(s, best[int(s, 0)])
                            st["symbolized"] += 1
                        else:
                            st["no label there"] += 1
                l = m.group("pre") + ",".join(its) + m.group("post")
            out.append(l)
        t2 = "\n".join(out)
        if a.apply and t2 != t:
            open(f, "wb").write(t2.encode("latin-1"))
    print("%s: %s%s" % (a.tree, dict(st), "" if a.apply else " (dry run)"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
