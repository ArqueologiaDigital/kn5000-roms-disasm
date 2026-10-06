#!/usr/bin/env python3
"""respell_accpatch_channel_index_table.py -- AccPatch_SlotScanByteData_Code is a byte table, not code (v10/v9/v7).

QUESTION IT ANSWERS
  AccPatch_StoreMeasureCursor (sequencer/accompaniment_engine.s) computes
      ld c, (0x379b:16) / and c, 31 / srl c, 1 / add xbc, AccPatch_SlotScanByteData_Code / ld e, (xbc)
  so the label is a byte table indexed by (one-hot channel & 31) >> 1.  The source spelled its 9 bytes
  02 03 04 00 01 00 00 00 00 as `push sr / pop sr / max / nop / normal / nop x4`.  Nothing jumps there; the KN5000
  helper-naming triage (analysis/kn5000-naming/proposals-2026-10-06-helpers-c.json) reported it.
  The table maps the channel bits 0, 1, 2, 3 and 4 (indices 0, 1, 2, 4 and 8) to the channel indices 2, 3, 4, 1 and 0.
  The script:
    - asserts the 9 ROM bytes at the label (from each tree's ELF);
    - writes them as `.byte` under the name AccPatch_ChannelBitToIndex;
    - renames the reference and the routine header's mention.
  The byte gate checks the result.

RUN (repository root, built tree)
  python3 scripts/tools/respell_accpatch_channel_index_table.py [--apply]
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
TREES = {"v10": "kn5000_v10_program", "v9": "kn5000_v9_program", "v7": "kn5000_v7_program"}
OLD, NEW = "AccPatch_SlotScanByteData_Code", "AccPatch_ChannelBitToIndex"
INSNS = ["push\tsr", "pop\tsr", "max", "nop", "normal", "nop", "nop", "nop", "nop"]
BYTES = bytes([2, 3, 4, 0, 1, 0, 0, 0, 0])
TABLE = ["; AccPatch_ChannelBitToIndex: channel index by (one-hot channel 0x379B & 31) >> 1, read by",
         ";   AccPatch_StoreMeasureCursor: bits 0, 1, 2, 3, 4 (indices 0, 1, 2, 4, 8) -> 2, 3, 4, 1, 0.",
         NEW + ":\t.byte 2, 3, 4, 0, 1, 0, 0, 0, 0"]


def main():
    apply = "--apply" in sys.argv
    for tree, stem in TREES.items():
        syms = {}
        for ln in subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs", stem + ".llvm.elf")],
                                 capture_output=True, text=True, check=True).stdout.split("\n"):
            f = ln.split()
            if len(f) == 3:
                syms.setdefault(f[2], int(f[0], 16))
        rom = open(os.path.join(ROOT, "original_ROMs", stem + ".rom"), "rb").read()
        a = syms[OLD]
        assert rom[a - 0xE00000:a - 0xE00000 + 9] == BYTES, (tree, rom[a - 0xE00000:a - 0xE00000 + 9].hex())
        p = os.path.join(ROOT, tree, "maincpu", "sequencer", "accompaniment_engine.s")
        L = open(p, "rb").read().decode("latin-1").split("\n")
        k = L.index(OLD + ":")
        assert [" ".join(x.split()) for x in L[k + 1:k + 10]] == [" ".join(x.split()) for x in INSNS], (tree, L[k + 1:k + 10])
        L[k:k + 10] = TABLE
        refs = [i for i, x in enumerate(L) if OLD in x]
        for i in refs:
            L[i] = L[i].replace(OLD, NEW)
        print("%s: 0x%06X %s -> %s (.byte), %d references renamed" % (tree, a, OLD, NEW, len(refs)))
        if apply:
            data = "\n".join(L).encode("latin-1")
            with open(p + ".tmp", "wb") as fh:
                fh.write(data)
            os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
