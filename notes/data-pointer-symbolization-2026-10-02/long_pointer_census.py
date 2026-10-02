#!/usr/bin/env python3
"""long_pointer_census.py -- where do the numeric own-ROM `.long` values of a tree point?

QUESTION THIS ANSWERS
  semantic_debt_dashboard.py's numaddr counts numeric ROM addresses in INSTRUCTION operands
  only.  Data tables hold them too -- `.long 0x00EB2AAE` in IconBitmapNamePtrTable -- about
  990 lines per KN5000 maincpu tree, and nothing measures them.  For every numeric value
  inside the tree's own ROM range on a `.long` / `.4byte` / `.word` line this says what is at
  that address, by the census marker mirror (symbolize_numeric_branches.build_map, refused
  unless it reproduces the dump):
    labelled    an ELF symbol is defined there already (the number can simply become it)
    line-start  a source line starts there with no label        (code / data, by the census)
    in-incbin   inside an `.incbin` slice                         (the slice must be cut)
    in-list     inside a `.byte` / `.short` / `.long` list         (on or off an element boundary)
    mid-code    inside an instruction line                        (not a pointer to code, or a wrong value)

USAGE
  make all
  python3 notes/data-pointer-symbolization-2026-10-02/long_pointer_census.py --tree v10 [--rows OUT.json]
"""
import argparse
import bisect
import collections
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
import symbolize_numeric_branches as snb      # noqa: E402
import symbolize_far_pointer_pushes as fp     # noqa: E402

LONG = re.compile(r'^(?P<pre>(?:[A-Za-z_][\w.$]*:)?\s*)\.(?:long|4byte|word)\s+(?P<items>[^;]*)', re.I)
NUMV = re.compile(r'^(0x[0-9a-fA-F]+|\d+)$')
INCBIN = re.compile(r'\.incbin\s')
LIST = re.compile(r'\.(byte|short|hword|2byte|long|word|4byte)\s')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True)
    ap.add_argument("--rows")
    a = ap.parse_args()
    elf, tree, (lo, hi) = fp.IMAGES[a.tree]
    syms = fp.elf_symbols(elf)
    img = snb.image_by_key(a.tree)
    srcroot = os.path.join(REPO, img["mirror"])
    marks, addrs, spans, rom_ok, src, macros = snb.build_map(img, srcroot)
    if not rom_ok:
        sys.exit("marker mirror does not reproduce the dump: refusing")
    starts = [s[0] for s in spans]
    st, rows = collections.Counter(), []
    for rel in sorted(set(s[2] for s in spans)):
        if snb.own_prefix(img) and not rel.startswith(snb.own_prefix(img)):
            continue
        L = open(os.path.join(srcroot, rel), "rb").read().decode("latin-1").split("\n")
        for i, l in enumerate(L):
            m = LONG.match(l)
            if not m:
                continue
            for it in m.group("items").split(","):
                it = it.strip()
                if not NUMV.match(it):
                    continue
                v = int(it, 0)
                if not lo <= v <= hi:
                    continue
                if v in syms:
                    kind = "labelled"
                else:
                    k = bisect.bisect_right(starts, v) - 1
                    sa, se, trel, tli = spans[k]
                    tl = src.text(trel, tli)
                    cls = snb.drc.classify_line(tl, macros)[0]
                    if v == sa:
                        kind = "line-start-" + cls
                    elif INCBIN.search(tl.split(";")[0]):
                        kind = "in-incbin"
                    elif LIST.search(tl.split(";")[0]):
                        kind = "in-list"
                    elif cls == "code":
                        kind = "mid-code"
                    else:
                        kind = "inside-" + cls
                st[kind] += 1
                rows.append({"at": "%s:%d" % (rel, i + 1), "value": "0x%06X" % v, "kind": kind})
    print("%s: %d numeric own-ROM .long values: %s" % (a.tree, sum(st.values()), dict(st.most_common())))
    if a.rows:
        json.dump(rows, open(a.rows, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
