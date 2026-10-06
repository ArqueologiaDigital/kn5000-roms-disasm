#!/usr/bin/env python3
"""unsymbolize_semenu_clearrect_pairs.py -- two SeMenu_ClearRect word pairs were spelled as far pointers (v10/v9/v7).

QUESTION IT ANSWERS
  SeMenu_ClearRect takes four word arguments.  In SeMenu_ApplyPartEdit (audio/semenu_routines.s) two calls push
      pushw 171 / pushw 232 / pushw 118 / pushw 67        and        pushw 130 / pushw 232 / pushw 77 / pushw 67
  The far-pointer pass of 2026-10-02/03 (notes/far-pointers-2026-10-02/) read the middle pairs as the pointers
  0xE80076 and 0xE8004D and labelled them SeMenu_ApplyPartEdit_AltStore_Data_2 / _Data.  Those addresses fall inside
  two C-typed objects of naka_widget_tables_2.c: +6 of NakaInst_GM[8] (" GM   \\0\\xff") and +3 of
  ComSetGridCheck_JumpTable_Str[6] (" OFF \\0").  The pass split the objects' .s slices to hold the labels.  Nothing
  else reads either label.  The first call's 171/67 and the second's 130/67 frame them as rectangle words, the same
  shape as the `pushw 121 / 254 / 73 / 48` call that the far-pointer notes already record as word arguments.
  This script:
    - asserts both labels' addresses from each tree's ELF (0xE80076 and 0xE8004D);
    - writes the pushes back as `pushw 232` / `pushw 118` and `pushw 232` / `pushw 77`;
    - removes the two labels and gives their bytes back to the slices they were cut from.
  The byte gate checks the result.

RUN (repository root, built tree)
  python3 scripts/tools/unsymbolize_semenu_clearrect_pairs.py [--apply]
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
TREES = {"v10": "kn5000_v10_program", "v9": "kn5000_v9_program", "v7": "kn5000_v7_program"}
PAIRS = {"SeMenu_ApplyPartEdit_AltStore_Data_2": (0xE80076, "NakaInst_GM", 0x25CD2, 0x6, 0x2),
         "SeMenu_ApplyPartEdit_AltStore_Data": (0xE8004D, "ComSetGridCheck_JumpTable_Str", 0x25CAC, 0x3, 0x3)}
NOTE = "\t; four word arguments, not a far pointer"


def rw(p, L):
    data = "\n".join(L).encode("latin-1")
    with open(p + ".tmp", "wb") as fh:
        fh.write(data)
    os.replace(p + ".tmp", p)


def main():
    apply = "--apply" in sys.argv
    for tree, stem in TREES.items():
        syms = {}
        for ln in subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs", stem + ".llvm.elf")],
                                 capture_output=True, text=True, check=True).stdout.split("\n"):
            f = ln.split()
            if len(f) == 3:
                syms.setdefault(f[2], int(f[0], 16))
        sp = os.path.join(ROOT, tree, "maincpu", "audio", "semenu_routines.s")
        tp = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "naka_widget_tables_2.s")
        S = open(sp, "rb").read().decode("latin-1").split("\n")
        T = open(tp, "rb").read().decode("latin-1").split("\n")
        for lab, (addr, prev, off, size, extra) in PAIRS.items():
            assert syms[lab] == addr, (tree, lab, hex(syms[lab]))
            hi = [i for i, x in enumerate(S) if re.match(r'^\s*pushw\s+%s@hi16\s*$' % lab, x)]
            assert len(hi) == 1 and re.match(r'^\s*pushw\s+%s@lo16\s*$' % lab, S[hi[0] + 1]), (tree, lab)
            S[hi[0]] = "\tpushw\t%d%s" % (addr >> 16, NOTE)
            S[hi[0] + 1] = "\tpushw\t%d" % (addr & 0xFFFF)
            k = next(i for i, x in enumerate(T) if x.startswith(lab + ":"))
            want = '"includes/generated/naka_widget_tables_2.bin", 0x%X, 0x%X' % (off + size, extra)
            assert want in T[k] and T[k - 1].startswith(prev + ":"), (tree, T[k - 1], T[k])
            assert ('"includes/generated/naka_widget_tables_2.bin", 0x%X, 0x%X' % (off, size)) in T[k - 1]
            T[k - 1] = T[k - 1].replace("0x%X, 0x%X" % (off, size), "0x%X, 0x%X" % (off, size + extra))
            del T[k]
            print("%s: %s 0x%06X -> pushw %d / pushw %d; %s slice 0x%X+0x%X" % (
                tree, lab, addr, addr >> 16, addr & 0xFFFF, prev, off, size + extra))
        if apply:
            rw(sp, S)
            rw(tp, T)


if __name__ == "__main__":
    main()
