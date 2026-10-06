#!/usr/bin/env python3
"""respell_hdae_sll_pair.py -- `.byte 0xe9, 0xee` + `.long SeqCh_SystemHandlerData` is `sll xbc, 16` twice (v10/v9/v7).

QUESTION IT ANSWERS
  At the end of HDAE5000_TableData_Write (boot/system_handlers.s) the source held
      .byte 0xe9, 0xee
      .long SeqCh_SystemHandlerData
  SeqCh_SystemHandlerData is at 0x00EEE900 in every tree, so the 6 bytes are e9 ee 00 e9 ee 00: two
  `sll xbc, 16` instructions (llvm-mc: `sll xbc, 16` -> e9 ee 00).  That makes the "reference" to
  SeqCh_SystemHandlerData a coincidence of code bytes: the round-2 triage of the nakarest slices
  (analysis/nakarest-slices/, r2b3) found that nothing reads that work-RAM-image slice through this line.
  The script asserts the 6 ROM bytes at the line's address, from each tree's ELF, then writes the two
  instructions.  The byte gate checks the encoding.

RUN (repository root, built tree)
  python3 scripts/tools/respell_hdae_sll_pair.py [--apply]
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
OBJDUMP = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-objdump")
TREES = {"v10": "kn5000_v10_program", "v9": "kn5000_v9_program", "v7": "kn5000_v7_program"}


def main():
    apply = "--apply" in sys.argv
    for tree, stem in TREES.items():
        elf = os.path.join(ROOT, "rebuilt_ROMs", stem + ".llvm.elf")
        syms = {}
        for ln in subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True, check=True).stdout.split("\n"):
            f = ln.split()
            if len(f) == 3:
                syms.setdefault(f[2], int(f[0], 16))
        assert syms["SeqCh_SystemHandlerData"] == 0xEEE900, tree
        rom = open(os.path.join(ROOT, "original_ROMs", stem + ".rom"), "rb").read()
        p = os.path.join(ROOT, tree, "maincpu", "boot", "system_handlers.s")
        L = open(p, "rb").read().decode("latin-1").split("\n")
        norm = [" ".join(x.split()) for x in L]
        k = next(i for i, x in enumerate(norm) if x == ".byte 0xe9, 0xee" and norm[i + 1] == ".long SeqCh_SystemHandlerData")
        # the line follows `ei` / `ld xwa, imm32` / `ldw ix, imm16` / `extz xix` after HDAE5000_TableData_Write_Skip6:
        # the 6 bytes are found within 20 bytes of that label, exactly once
        s = syms["HDAE5000_TableData_Write_Skip6"]
        assert [x.split()[0] for x in L[k - 4:k]] == ["ei", "ld", "ldw", "extz"], (tree, L[k - 4:k])
        win = rom[s - 0xE00000:s - 0xE00000 + 20]
        assert win.count(bytes.fromhex("e9ee00e9ee00")) == 1, (tree, win.hex())
        a = s + win.index(bytes.fromhex("e9ee00e9ee00"))
        print("%s: 0x%06X e9 ee 00 e9 ee 00 = sll xbc, 16 / sll xbc, 16" % (tree, a))
        if apply:
            L[k:k + 2] = ["\tsll\txbc, 16", "\tsll\txbc, 16"]
            data = "\n".join(L).encode("latin-1")
            with open(p + ".tmp", "wb") as fh:
                fh.write(data)
            os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
