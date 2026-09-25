#!/usr/bin/env python3
r"""Address <-> line map of wsa1/prom_a/wsa1_prom_a.s, built from the LINKED ELF.

QUESTION THIS ANSWERS
    "Which label (if any) is defined at prom_a address X, and on which source
    line does the statement at X start?"  Every lane-proma edit script uses it
    to find its anchor lines and to decide whether a pointer can be written as
    `.long <label>`.

HOW, and why not from the `; ADDR` comments
    The address comments are prose; the brief records a stale map producing 13
    wrong conversions.  So label ADDRESSES come from `llvm-nm` over the freshly
    built wsa1/rebuilt_ROMs/wsa1_prom_a.llvm.elf (run `make gate-wsa1` first),
    and a statement's address comment is trusted only where its trailing hex
    bytes, if present, equal the ROM bytes at that address (`guarded`).

    import srcmap; m = srcmap.load()
    m.labels_at(0xFD2903)  -> ['sub_FD2903']      (from the ELF)
    m.line_of(0xFD2903)    -> source line index or None (from guarded comments)
"""
import bisect
import os
import re
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
WSA1 = os.path.join(ROOT, "wsa1")
SRC = os.path.join(WSA1, "prom_a", "wsa1_prom_a.s")
ELF = os.path.join(WSA1, "rebuilt_ROMs", "wsa1_prom_a.llvm.elf")
ROM = os.path.join(WSA1, "original_ROMs", "wsa1_prom_a.ic12")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
BASE = 0xF80000
ADDR = re.compile(r';\s*([0-9A-F]{6})\b((?:\s+[0-9a-f]{2})*)')


class Map:
    def __init__(self):
        self.rom = open(ROM, "rb").read()
        self.lines = open(SRC, encoding="latin-1").read().split("\n")
        self.by_addr = {}
        out = subprocess.run([NM, "--defined-only", ELF], capture_output=True, text=True,
                             check=True).stdout
        for ln in out.split("\n"):
            p = ln.split()
            if len(p) == 3 and p[1] in "tTdD":
                a = int(p[0], 16)
                if BASE <= a < BASE + 0x80000:
                    self.by_addr.setdefault(a, []).append(p[2])
        self.line_at = {}
        for i, l in enumerate(self.lines):
            m = ADDR.search(l)
            if not m:
                continue
            a = int(m.group(1), 16)
            bs = m.group(2).split()
            if bs and bytes(int(x, 16) for x in bs) != self.rom[a - BASE:a - BASE + len(bs)]:
                continue
            self.line_at.setdefault(a, i)
        self.sorted = sorted(self.line_at)

    def labels_at(self, a):
        return self.by_addr.get(a, [])

    def line_of(self, a):
        return self.line_at.get(a)

    def best_label(self, a):
        """a non-local label at a, preferring descriptive names over sub_/.L."""
        c = [x for x in self.labels_at(a) if not x.startswith(".L") and not x.startswith("__")]
        c.sort(key=lambda x: (x.startswith("sub_"), len(x)))
        return c[0] if c else None


def load():
    return Map()
