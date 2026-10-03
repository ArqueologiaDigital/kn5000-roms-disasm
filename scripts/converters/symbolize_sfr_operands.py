#!/usr/bin/env python3
r"""symbolize_sfr_operands.py -- 8-bit-direct SFR operands by their TMP94C241 names, in any tree.

QUESTION THIS ANSWERS / WHAT IT DOES
    Each tree's shared/sfr_tmp94c241.s defines the special-function registers
    (`.equ PG, 0x40`, `.equ INTCLR, 0xF8` ...), but the code spells most SFR accesses as numbers.
    The native forms respell_raw_pseudos.py writes are `ld a, (0x40:8)` and `bit 2, (0x68:8)`.
    This is the tree-generic form of symbolize_v142_sfr_operands.py (v142 only, 2026-09-25), with
    the same rules:
      * every `(addr:8)` memory operand -- ld / bit / set / res / ldcf / lda / and ... -- and the
        address operand of the `*_dd8` bit pseudos is rewritten to the register name, whenever
        the address has EXACTLY ONE name in the tree's SFR file;
      * names the assembler would parse as a register are skipped (PC = port C, 0x30, would read
        as the program counter).
    An `:8` operand is an 8-bit direct address and encodes into the instruction, so the byte gate
    proves every rewrite.  A forward reference to an `.equ` assembles to the same byte through an
    FK_Data_1 fixup.

RUN
    python3 scripts/converters/symbolize_sfr_operands.py --tree v10/maincpu [--apply]
    make gate-all
"""
import argparse
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RESERVED = {"PC", "SR", "SP", "A", "W", "B", "C", "D", "E", "H", "L", "WA", "BC", "DE", "HL",
            "IX", "IY", "IZ", "XWA", "XBC", "XDE", "XHL", "XIX", "XIY", "XIZ", "XSP", "F"}
DD8 = re.compile(r"^(\s*(?:[A-Za-z_.$][\w.$]*:)?\s*(?:set|res|bit|stcf|ldcf|xorcf|chg)_dd8\s+\d+\s*,\s*)"
                 r"(0x[0-9A-Fa-f]+|\d+)(\s*)$", re.I)
MEM8 = re.compile(r"\((0x[0-9A-Fa-f]+|\d+):8\)")


def _write(path, data):
    tmp = path + ".tmp-symsfr"
    with open(tmp, "wb") as fh:
        fh.write(data)
    os.replace(tmp, path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True)
    ap.add_argument("--sfr", default="shared/sfr_tmp94c241.s", help="relative to --tree")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    tree = os.path.join(ROOT, a.tree)
    names = {}
    for ln in open(os.path.join(tree, a.sfr), encoding="latin-1"):
        m = re.match(r"\s*\.equ\s+(\w+)\s*,\s*(0x[0-9A-Fa-f]+|\d+)", ln)
        if m:
            names.setdefault(int(m.group(2), 0), []).append(m.group(1))
    uniq = {v: n[0] for v, n in names.items() if len(n) == 1 and n[0].upper() not in RESERVED}
    total, left = 0, 0
    for p in sorted(glob.glob(os.path.join(tree, "**", "*.s"), recursive=True)):
        L = open(p, "rb").read().decode("latin-1").split("\n")
        n = 0
        for i, ln in enumerate(L):
            code, sep, com = ln.partition(";")
            m = DD8.match(code)
            if m and int(m.group(2), 0) in uniq:
                code = m.group(1) + uniq[int(m.group(2), 0)] + m.group(3)
                n += 1

            def sub(mm):
                nonlocal n, left
                v = int(mm.group(1), 0)
                if v in uniq:
                    n += 1
                    return "(%s:8)" % uniq[v]
                left += 1
                return mm.group(0)
            code = MEM8.sub(sub, code)
            L[i] = code + sep + com
        if n:
            print("%-60s %4d operands" % (os.path.relpath(p, ROOT), n))
            total += n
            if a.apply:
                _write(p, "\n".join(L).encode("latin-1"))
    print("tree %s: %d operands named, %d numeric (addr:8) operands left (no unique SFR name)%s"
          % (a.tree, total, left, "" if a.apply else " (dry run)"))


if __name__ == "__main__":
    main()
