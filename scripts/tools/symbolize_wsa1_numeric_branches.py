#!/usr/bin/env python3
"""symbolize_wsa1_numeric_branches.py -- a WSA1 branch whose target already HAS a label takes the label instead of a number.

QUESTION THIS ANSWERS / JOB IT DOES
  prom_a / prom_b still spell some branches by number -- `calr 65482` (prom_b, a 16-bit displacement
  in decimal), `jr -34`, `call 0xf85c89` -- although the target is labelled (`calr 65482` at 0xF001B0
  lands on sub_F0017D).  For each numeric call / calr / jp / jr / jrl / djnz in the ROM's own range:
  the target is the address the trailing comment's MAME text names (prom_b: `; F001B0  calr
  0xf0017d`), else it is computed from the operand and the instruction length the comment's bytes
  give (prom_a: `; F8A47F  1e 1f 00` -- relative for jr / jrl / calr / djnz, absolute otherwise);
  where the linked ELF has a label exactly there, the operand becomes that label (a non-`sub_`,
  non-`.L` name first, then the shortest).  Targets with no label are counted and left: placing one
  asserts an entry point, which is a reading job.  The comment stays.  Same bytes: assert_byte_identical.

USAGE
  cd wsa1 && make all && cd ..
  python3 scripts/tools/symbolize_wsa1_numeric_branches.py --rom prom_b [--apply]
"""
import argparse
import collections
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
ROMS = {"prom_a": (0xF80000, 0x1000000), "prom_b": (0xF00000, 0xF80000)}
RX = re.compile(r'^(?P<pre>\s*(?:[\w.$]+:)?\s*(?P<mn>call|calr|jp|jr|jrl|djnz)\s+(?:(?P<cc>[a-z]+)\s*,\s*)?'
                r'(?:(?P<reg>[a-z]+)\s*,\s*)?)(?P<num>-?0x[0-9a-fA-F]+|-?[0-9]+)(?P<post>\s*;\s*(?P<site>[0-9A-F]{6})\s+(?P<txt>.*))$',
                re.I)


def target(m):
    t = re.search(r'\b(?:call|calr|jp|jr|jrl|djnz)\b[^;]*?0x([0-9a-f]{5,6})\b', m.group("txt"), re.I)
    if t:
        return int(t.group(1), 16)
    by = re.match(r'((?:[0-9a-f]{2}\s)+)', m.group("txt") + " ")
    if not by:
        return None
    n, v, site, mn = len(by.group(1).split()), int(m.group("num"), 0), int(m.group("site"), 16), m.group("mn").lower()
    if mn in ("jr", "djnz"):
        return site + n + (v - 0x100 if 0x80 <= v < 0x100 else v)
    if mn in ("jrl", "calr"):
        return site + n + (v - 0x10000 if 0x8000 <= v < 0x10000 else v)
    return v


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", required=True, choices=sorted(ROMS))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    lo, hi = ROMS[a.rom]
    by = collections.defaultdict(list)
    for l in subprocess.run([NM, "--defined-only", os.path.join(REPO, "wsa1/rebuilt_ROMs/wsa1_%s.llvm.elf" % a.rom)],
                            capture_output=True, text=True, check=True).stdout.splitlines():
        v, t, n = l.split()
        if t in "tT":
            by[int(v, 16)].append(n)
    src = os.path.join(REPO, "wsa1", a.rom, "wsa1_%s.s" % a.rom)
    L = open(src, "rb").read().decode("latin-1").split("\n")
    st = collections.Counter()
    for i, l in enumerate(L):
        m = RX.match(l)
        if not m:
            continue
        t = target(m)
        if t is None:
            st["target unknown"] += 1
            continue
        if not lo <= t < hi:
            st["other ROM: left"] += 1
            continue
        names = by.get(t)
        if not names:
            st["no label at the target: left"] += 1
            continue
        nm = sorted(names, key=lambda x: (x.startswith(".L"), x.startswith("sub_"), len(x), x))[0]
        L[i] = m.group("pre") + nm + m.group("post")
        st["replaced"] += 1
    print("%s: %s%s" % (a.rom, dict(st), "" if a.apply else " (dry run)"))
    if a.apply:
        open(src, "wb").write("\n".join(L).encode("latin-1"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
