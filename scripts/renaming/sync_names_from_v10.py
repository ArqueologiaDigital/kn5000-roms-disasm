#!/usr/bin/env python3
"""sync_names_from_v10.py -- give v9/v7 labels v10's name where both name the same unmoved bytes.

QUESTION THIS ANSWERS / JOB IT DOES
  The multi-version sync policy says a rename in one version is made in all.  Some were not: at
  the same address, over the same bytes, v10 and v9 (or v7) carry different labels, and neither
  name exists in the other tree -- e.g. v10 ColorBlit_WithPaletteSave_Skip vs v9
  ColorBlit_Variant_ByteData_Skip at 0xFB2556.  This finds every such pair from the linked ELFs:
    * the same address in both trees;
    * the same first 16 ROM bytes there (the same object, not a coincidence of addresses);
    * no shared name at that address;
    * the v10 name is absent from the other tree, and the other name is absent from v10 (so the
      rename cannot collide).
  It then writes scripts/renaming/sync_names_<tree>_from_v10.sed (word-boundary rules), and with
  --apply runs it over the tree's .s/.c/.h/.ld files.  Labels emit no byte: make gate-all.

USAGE
  make all
  python3 scripts/renaming/sync_names_from_v10.py --tree v9 [--apply]
"""
import argparse
import collections
import glob
import os
import re
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")


def table(t):
    by, names = collections.defaultdict(set), {}
    elf = os.path.join(REPO, "rebuilt_ROMs", "kn5000_%s_program.llvm.elf" % t)
    for l in subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True, check=True).stdout.split("\n"):
        p = l.split()
        if len(p) == 3 and p[1] in "tT":
            by[int(p[0], 16)].add(p[2])
            names[p[2]] = int(p[0], 16)
    return by, names


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    a10, n10 = table("v10")
    ao, no = table(a.tree)
    r10 = open(os.path.join(REPO, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    ro = open(os.path.join(REPO, "original_ROMs/kn5000_%s_program.rom" % a.tree), "rb").read()
    pairs = []
    for addr, s10 in sorted(a10.items()):
        so = ao.get(addr)
        if not so or s10 & so or len(s10) != 1 or len(so) != 1:
            continue
        o = addr - 0xE00000
        if r10[o:o + 16] != ro[o:o + 16]:
            continue
        x, y = next(iter(s10)), next(iter(so))
        if x not in no and y not in n10:
            pairs.append((addr, y, x))
    sed = os.path.join(REPO, "scripts", "renaming", "sync_names_%s_from_v10.sed" % a.tree)
    lines = ["# %s labels renamed to v10's name for the same unmoved bytes (scripts/renaming/sync_names_from_v10.py)" % a.tree]
    for addr, y, x in sorted(pairs, key=lambda p: -len(p[1])):     # longest first: no prefix shadowing
        lines.append("s/\\b%s\\b/%s/g\t# 0x%06X" % (y, x, addr))
    print("%s: %d pairs" % (a.tree, len(pairs)))
    for addr, y, x in pairs[:6]:
        print("   0x%06X  %s -> %s" % (addr, y, x))
    if not a.apply:
        return 0
    with open(sed, "w") as fh:
        fh.write("\n".join(lines) + "\n")
    files = sorted(sum((glob.glob(os.path.join(REPO, a.tree, "maincpu", "**", g), recursive=True)
                        for g in ("*.s", "*.c", "*.h", "*.ld")), []))
    subprocess.run(["sed", "-i", "-E", "-f", sed] + files, check=True)
    print("applied %s to %d files" % (os.path.relpath(sed, REPO), len(files)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
