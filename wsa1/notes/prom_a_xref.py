#!/usr/bin/env python3
"""Who reaches a prom_a address?  An opcode-anchored UPPER BOUND on callers.

QUESTION IT ANSWERS: "which sites in prom_a or prom_b name the address
0xF8xxxx -- as `call nnn` (0x1D), `jp nnn` (0x1B), `lda XRR,nnn` (0xF2 ... 0x3n)
or as a bare 32-bit little-endian pointer?"

⚠ THIS IS NOT AN INSTRUCTION-BOUNDARY SCAN.  It looks for the byte patterns at
EVERY offset, so a hit can be bytes inside another instruction or inside data.
Treat the output as candidates to confirm with unidasm, and never quote a count
from it as "the number of callers".  The one thing it is exact about is the
absence of a pattern: zero hits means no site spells that address that way.

Opcodes cited: dasm900.cpp:1267 (0x0E RET), and 0x1B/0x1D confirmed by
round-tripping ROM bytes (notes/FINDINGS-prom_b-thunk-table.md).

    python3 notes/prom_a_xref.py 0xF8E5F6 [0xF8E66D ...]
    python3 notes/prom_a_xref.py --thunks 0xF8E5F6   # only prom_b-thunk-table hits
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMGS = {
    "prom_a": (os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), 0xF80000),
    "prom_b": (os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), 0xF00000),
}
THUNK_LO, THUNK_HI = 0xF40000, 0xF44018


def scan(target, thunks_only=False):
    le = bytes([target & 0xFF, (target >> 8) & 0xFF, (target >> 16) & 0xFF])
    hits = []
    for name, (path, base) in IMGS.items():
        data = open(path, "rb").read()
        i = 0
        while True:
            i = data.find(le, i)
            if i < 0:
                break
            addr = base + i
            if i >= 1 and data[i - 1] in (0x1B, 0x1D):
                kind = "call" if data[i - 1] == 0x1D else "jp"
                hits.append((name, addr - 1, kind))
            if i >= 2 and data[i - 2] == 0xF2 and (data[i + 3] & 0xF0) == 0x30:
                hits.append((name, addr - 2, "lda XR%d" % (data[i + 3] & 0x0F)))
            if i >= 1 and data[i + 3] == 0x00 and (addr - 0) % 1 == 0:
                hits.append((name, addr, "ptr32"))
            i += 1
    out = []
    for name, addr, kind in hits:
        in_thunk = name == "prom_b" and THUNK_LO <= addr < THUNK_HI
        if thunks_only and not in_thunk:
            continue
        out.append((name, addr, kind, in_thunk))
    return out


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    thunks_only = "--thunks" in sys.argv
    for a in args:
        t = int(a, 16)
        print("=== 0x%06X ===" % t)
        for name, addr, kind, in_thunk in scan(t, thunks_only):
            print("  %-7s 0x%06X  %-9s%s" % (name, addr, kind,
                                             "  [thunk table]" if in_thunk else ""))


if __name__ == "__main__":
    main()
