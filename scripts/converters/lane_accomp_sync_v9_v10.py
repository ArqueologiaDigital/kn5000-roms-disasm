#!/usr/bin/env python3
r"""lane_accomp_sync_v9_v10.py -- make v9's and v10's accompaniment_engine.s ONE text.

QUESTION ANSWERED
-----------------
v9 and v10 assemble this file to the same addresses, and their ROM bytes over
it differ in 49 bytes only (0xF55000-0xF72000, measured 2026-09-25), every one
of which is an operand the source spells symbolically.  Yet the two texts
differ in ~50 hunks, because past lanes improved one copy and not the other.
Which copy is right in each hunk, and what is the single text both should
carry?

Measured by reading every hunk (the `--list` output):
  * in all but one region v10 is the better copy: typed tables with evidence
    headers where v9 still spells the same bytes as mnemonics (halt / reti /
    `jrl nc,127` ...), or `.byte` runs carrying a data-as-code note where v9
    has the dead mnemonics;
  * the exception is the AccDraw_Secondary cluster: there v10 re-typed
    0xF6A38B-0xF6A39D (18 B) as data with the note "unreached CODE-territory",
    and that claim is FALSE -- the bytes are two 9-byte wrappers
    (`push xwa / ld xwa,xiy / call <draw routine> / pop xwa / ret`) and v10
    itself still calls the second one numerically (`calr 65411`,
    `calr 64663`), which v9 spells `calr AccDraw_Secondary_Helper`.  v9's text
    is taken for every hunk of that cluster EXCEPT the three bit-mask tables
    (0x08000000, 0x10000000, ... as LE32) that v10 typed and v9 did not.

  * and the head of AccScreen_UIDataBlock: v10 typed all 698 bytes of its
    first record run as data ("EVERY one [of the 23 positional labels] is used
    as `ld xiy/xix`").  True of the labels, but the first 51 bytes are three
    routines, and two of them ARE branch targets: AccDraw_Secondary calls
    +0x11 and +0x1A (v9: `calr AccDraw_Secondary_Helper13/14`; v10 had the same
    calls numerically, `calr 1402` / `calr 1492`).  They decode cleanly, call
    Display_DeferOrDrawWall / Display_DeferOrUpdateScreen, and v7's copy of
    the block differs from v10's in exactly their call operands (-0x40D, the
    v7 code-relocation delta).  HEAD_FIX below re-spells those 51 bytes as
    v9 does and keeps the other 13 bytes of the fourth row as data.

The merged text is written to BOTH files.  Lines equal up to whitespace take
v10's spelling.  No v9 comment is lost: v9 has none that v10 lacks (checked
here, and again by scripts/analysis/assert_comments_preserved.py).

RUN
    python3 scripts/converters/lane_accomp_sync_v9_v10.py --list
    python3 scripts/converters/lane_accomp_sync_v9_v10.py --apply
"""
import argparse
import difflib
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REL = "maincpu/sequencer/accompaniment_engine.s"
V9_FROM = "AccDraw_Secondary:"          # cluster where v9 is right ...
V9_TO = "AccScreen_UIDataBlock:"         # ... up to (not including) this label
KEEP_V10_MARK = "near AccScreen_DataBlock_0x18C"   # the three typed bit-mask tables


def norm(s):
    return re.sub(r'[ \t]+', ' ', s).strip()


HEAD_CODE = [
    "; ** CORRECTED 2026-09-25 (lane accomp): bytes +0x00..+0x32 of this block are",
    "; NOT data.  They are three routines (51 B) and AccDraw_Secondary CALLS the",
    "; second and third (calr AccDraw_Secondary_Helper13 / _Helper14), so the",
    "; \"never a branch target\" reading above holds for the 23 positional labels",
    "; only.  The records begin at +0x33 = AccScreen_UIDataBlock_0x33, the first",
    "; positional label.  Evidence: clean llvm-mc/unidasm decode ending on `ret` at",
    "; +0x32; the calls land on Display_DeferOrDrawWall / Display_DeferOrUpdateScreen;",
    "; and v7's copy of this block differs from v10's here in exactly those two call",
    "; operands (by -0x40D, v7's code-relocation delta for that range) and in one",
    "; RAM operand -- scripts/converters/lane_accomp_v7_uidatablock.py --diff.",
    "; The four 16-byte .byte rows these 51 bytes were spelled as carried these",
    "; ascii renderings:",
    "; |......#.!.!..6..|",
    "; |.#.!.._.......7!|",
    "; |...f....g..ah...|",
    "; |9@.#.4-.....STEP|",
    "\tld\t(0x03efa8:24), 0",
    "\tld\tc, 0:opc",
    "\tld\ta, 12:opc",
    "\tld\ta, 16:opc",
    "\tcall\tDisplay_DeferOrDrawWall",
    "\tret",
    "AccDraw_Secondary_Helper13:",
    "\tld\tc, 7:opc",
    "\tld\ta, 12:opc",
    "\tcall\tDisplay_DeferOrUpdateScreen",
    "\tret",
    "; W = index of the lowest set bit of ((0x379b) & 31), 0 when none is set;",
    "; stored to (0x39b8).",
    "AccDraw_Secondary_Helper14:",
    "\txor\twa, wa",
    "\tld\ta, (0x379b:16)",
    "\tand\ta, 31",
    "\tjr\tz, 9",
    "\tsrl\ta, 1",
    "\tjr\tc, 4",
    "\tinc\t1, w",
    "\tjr\t-9",
    "\tld\t(0x39b8:16), w",
    "\tret",
    "; +0x33: the records",
    "\t.byte 0x23, 0x05, 0x34, 0x2d, 0x00, 0x07, 0x12, 0x84, 0x00, 0x53, 0x54, 0x45, 0x50\t; |#.4-.....STEP|",
]
HEAD_ROWS = [
    "\t.byte 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00, 0x23, 0x00, 0x21, 0x0c, 0x21, 0x10, 0x1d, 0x36, 0x15, 0xfb\t; |......#.!.!..6..|",
    "\t.byte 0x0e, 0x23, 0x07, 0x21, 0x0c, 0x1d, 0x5f, 0x15, 0xfb, 0x0e, 0xd8, 0xd0, 0xc1, 0x9b, 0x37, 0x21\t; |.#.!.._.......7!|",
    "\t.byte 0xc9, 0xcc, 0x1f, 0x66, 0x09, 0xc9, 0xef, 0x01, 0x67, 0x04, 0xc8, 0x61, 0x68, 0xf7, 0xf1, 0xb8\t; |...f....g..ah...|",
    "\t.byte 0x39, 0x40, 0x0e, 0x23, 0x05, 0x34, 0x2d, 0x00, 0x07, 0x12, 0x84, 0x00, 0x53, 0x54, 0x45, 0x50\t; |9@.#.4-.....STEP|",
]


def head_fix(out):
    """Replace the four .byte rows at the head of AccScreen_UIDataBlock."""
    i = out.index(V9_TO)
    for k in range(i, i + 30):
        if out[k:k + 4] == HEAD_ROWS:
            return out[:k] + HEAD_CODE + out[k + 4:]
    sys.exit("head_fix: the four head rows were not found verbatim")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    p10, p9 = (os.path.join(ROOT, v, REL) for v in ("v10", "v9"))
    L10 = open(p10, encoding="latin-1").read().split("\n")
    L9 = open(p9, encoding="latin-1").read().split("\n")
    lo = L10.index(V9_FROM)
    hi = L10.index(V9_TO)
    sm = difflib.SequenceMatcher(None, [norm(x) for x in L10], [norm(x) for x in L9], autojunk=False)
    out, n9, n10 = [], 0, 0
    v9only_comments = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            out += L10[i1:i2]
            continue
        a10, a9 = L10[i1:i2], L9[j1:j2]
        take9 = lo <= i1 < hi and not any(KEEP_V10_MARK in x for x in a10)
        c10 = {x[x.index(";"):].strip() for x in a10 if ";" in x}
        for x in a9:
            if ";" in x and x[x.index(";"):].strip() not in c10 and not take9:
                v9only_comments.append((j1, x))
        if a.list:
            print("%s v10 %d-%d (%d)  v9 %d-%d (%d)  -> %s" % (
                tag, i1 + 1, i2, i2 - i1, j1 + 1, j2, j2 - j1, "v9" if take9 else "v10"))
        if take9:
            out += a9
            n9 += 1
        else:
            out += a10
            n10 += 1
    print("hunks: %d taken from v10, %d from v9" % (n10, n9))
    if v9only_comments:
        print("REFUSED: v9 comments that the merged text would drop:")
        for j, x in v9only_comments[:20]:
            print("  v9:%d %s" % (j + 1, x))
        sys.exit(1)
    out = head_fix(out)
    if a.apply:
        data = "\n".join(out)
        for p in (p10, p9):
            tmp = p + ".tmp"
            open(tmp, "w", encoding="latin-1").write(data)
            os.replace(tmp, p)
        print("wrote the merged text (%d lines) to v10 and v9" % len(out))


if __name__ == "__main__":
    main()
