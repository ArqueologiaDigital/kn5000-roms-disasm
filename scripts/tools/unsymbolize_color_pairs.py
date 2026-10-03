#!/usr/bin/env python3
"""unsymbolize_color_pairs.py -- `pushw Sym@hi16 / pushw Sym@lo16` before a DrawString* call is a colour pair, not a pointer.

QUESTION THIS ANSWERS / JOB IT DOES
  The far-pointer passes (scripts/converters/symbolize_far_pointer_pushes.py and its pipeline)
  read any `pushw HI / pushw LO` pair with HI <= 0xff that lands in the own ROM as a C far
  pointer.  Before the DrawString family the pair is something else: the 32-bit argument the
  renderers take is a COLOUR pair -- the values are (0xff, 0xf5) 17 times, (0xfb, 0xf5) 6, (0xff,
  0xf7) 7, (0x00, 0x07) 4 in v10, palette indices, and DrawStringReverse is documented as
  drawing "with swapped fg/bg colors".  So `pushw PmBank_DrawRegionInfo_Data@hi16` (= 0xff00f7)
  named a code address that nothing points at.  This restores the numbers (hex) on every such
  pair -- the pushes within 6 lines of a call to DrawString, DrawStringCentered,
  DrawStringLeftJustify, DrawStringRightJustify, DrawStringAlignment or DrawStringReverse, and
  any pair whose value is one of the colour pairs those calls pass (it reaches the call through a
  label or a jump: `jr AcFileSfx_CallDrawString`) -- with a comment, and lists the labels the
  pairs named.  Same bytes: `make gate-all`.

USAGE
  make all
  python3 scripts/tools/unsymbolize_color_pairs.py --tree v10 [--apply]
"""
import argparse
import glob
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
CALLEES = ("DrawString", "DrawStringCentered", "DrawStringLeftJustify", "DrawStringRightJustify",
           "DrawStringAlignment", "DrawStringReverse")
# the 32-bit values pushed right before DrawString* calls in v10/v9/v7 (2026-10-03)
COLOUR_VALUES = {0x00FF0008, 0x00FF00F2, 0x00FF00F5, 0x00FF00F7, 0x00FB00F5, 0x00FB00F7, 0x00F400F7, 0x00000007}
P = re.compile(r'^(?P<pre>\s*(?:[A-Za-z_][\w.$]*:)?\s*pushw\s+)(?P<sym>\w+)@(?P<part>hi16|lo16)(?P<post>.*)$')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7", "hdae5000"))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    elf = {"hdae5000": "rebuilt_ROMs/hd-ae5000_v2_06i.llvm.elf"}.get(a.tree, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % a.tree)
    addr = {}
    for l in subprocess.run([NM, "--defined-only", os.path.join(REPO, elf)], capture_output=True, text=True,
                            check=True).stdout.splitlines():
        x, t, n = l.split()
        addr[n] = int(x, 16)
    src = a.tree if a.tree == "hdae5000" else os.path.join(a.tree, "maincpu")
    n, named = 0, set()
    for f in sorted(glob.glob(os.path.join(REPO, src, "**", "*.s"), recursive=True)):
        L = open(f, "rb").read().decode("latin-1").split("\n")
        changed = False
        for i in range(len(L) - 1):
            h, lo = P.match(L[i]), P.match(L[i + 1])
            if not (h and lo and h.group("part") == "hi16" and lo.group("part") == "lo16" and h.group("sym") == lo.group("sym")):
                continue
            nxt = " ".join(x.split(";")[0] for x in L[i + 2:i + 8])   # DrawStringReverse: 2 pairs + a label
            m = re.search(r'\bcall\s+(\w+)', nxt)
            if h.group("sym") not in addr:
                continue
            v = addr[h.group("sym")]
            if not (m and m.group(1) in CALLEES):
                # reached through a label or a jump (`jr AcFileSfx_CallDrawString`): the VALUE
                # gives it away -- one of the colour pairs the direct calls pass
                if v not in COLOUR_VALUES:
                    continue
                m = re.match(r'(.*)', "DrawString (by value)")
            named.add(h.group("sym"))
            L[i] = "%s0x%02x%s\t; colour pair for %s, not a pointer" % (h.group("pre"), v >> 16, h.group("post").rstrip(), m.group(1))
            L[i + 1] = "%s0x%02x%s" % (lo.group("pre"), v & 0xFFFF, lo.group("post"))
            n += 1
            changed = True
        if changed and a.apply:
            open(f, "wb").write("\n".join(L).encode("latin-1"))
    print("%s: %d colour pairs restored; labels they named: %s%s" % (a.tree, n, sorted(named), "" if a.apply else " (dry run)"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
