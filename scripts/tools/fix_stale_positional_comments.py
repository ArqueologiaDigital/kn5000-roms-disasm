#!/usr/bin/env python3
"""fix_stale_positional_comments.py -- comments that still cite a retired positional alias cite the label now there.

QUESTION THIS ANSWERS / JOB IT DOES
  The passes of 2026-10-02 retired most positional aliases (`.set X_0x1C, X + 28`) into real
  labels and renamed their uses -- but headers written earlier quote the alias in prose
  ("`ld xix, Display_FontPalette_Table_0x12ea`"), and a name with no definition sends a reader
  nowhere: ~394 such mentions per KN5000 maincpu tree.  For every `Base_0xN` in a comment that
  the linked ELF does not define, where Base IS defined: the address is Base + N, and when a
  column-0 label sits exactly there the mention becomes that label (symbolize_far_pointer_pushes
  .pick).  Others are counted and left.  C / header comments (/* */, //) get the same rewrite
  (2026-10-03).  Comments only: no byte changes.

USAGE
  make all
  python3 scripts/tools/fix_stale_positional_comments.py --tree v10 [--apply]
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

POS = re.compile(r'\b([A-Za-z_]\w*?)_0x([0-9A-Fa-f]+)\b')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=sorted(fp.IMAGES))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    elf, src, _ = fp.IMAGES[a.tree]
    files = sorted(glob.glob(os.path.join(REPO, src, "**", "*.s"), recursive=True))
    col0 = fp.col0_labels(files)
    syms = fp.elf_symbols(elf)
    addr = {n: ad for ad, ns in syms.items() for n in ns}
    st = collections.Counter()

    def fix(m):
        full, base, off = m.group(0), m.group(1), int(m.group(2), 16)
        if full in addr:
            return full
        if base not in addr:
            st["base unknown: left"] += 1
            return full
        here = [n for n in syms.get(addr[base] + off, []) if n in col0]
        if not here:
            st["no label at the address: left"] += 1
            return full
        st["replaced"] += 1
        return fp.pick(here, col0)
    for f in files:
        t = open(f, "rb").read().decode("latin-1")
        out = []
        for l in t.split("\n"):
            if ";" in l:
                k = l.index(";")
                l = l[:k] + POS.sub(fix, l[k:])
            out.append(l)
        t2 = "\n".join(out)
        if a.apply and t2 != t:
            open(f, "wb").write(t2.encode("latin-1"))
    # C sources quote instructions in their comments too ("used by NoteEditBox_EventDispatch2 (`ld
    # xwa, ExtDevice_ModeDispatch_Table_0x140`)"): the same rewrite inside /* */ and // spans
    for f in sorted(glob.glob(os.path.join(REPO, src, "**", "*.[ch]"), recursive=True)):
        t = open(f, "rb").read().decode("latin-1")
        t2 = re.sub(r'/\*.*?\*/|//[^\n]*', lambda c: POS.sub(fix, c.group(0)), t, flags=re.S)
        if a.apply and t2 != t:
            open(f, "wb").write(t2.encode("latin-1"))
    print("%s: %s%s" % (a.tree, dict(st), "" if a.apply else " (dry run)"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
