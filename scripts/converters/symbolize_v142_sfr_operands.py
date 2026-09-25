#!/usr/bin/env python3
r"""symbolize_v142_sfr_operands.py -- SFR operands of the sub-CPU v1.42 code by their TMP94C241 names.

QUESTION THIS ANSWERS / WHAT IT DOES
    v142/subcpu/shared/sfr_tmp94c241.s defines the TMP94C241 special-function registers
    (`.equ P6, 0x18`, `.equ T8RUN, 0x80`, `.equ INTES1, 0xEB` ...) and the payload's comments
    cite it ("SFR 0x18 is PORT 6 (shared/sfr_tmp94c241.s: `.equ P6, 0x18`)"), but the payload
    never included it, so every SFR access spells the number: `res_dd8 7, 0x18`,
    `ld (0xEB:8), 0xDD:io`.  This script
      * includes the SFR file at the top of kn5000_subprogram_v142.s (it only defines .equ
        symbols -- no bytes -- and none of its 185 names collides with a payload symbol);
      * rewrites the 8-bit-direct SFR operands to the register name: the address operand of the
        `*_dd8` bit instructions (set/res/bit/stcf/ldcf/xorcf/chg) and every `(addr:8)` memory
        operand, whenever the address has exactly one name in the SFR file -- except names the
        assembler parses as registers (PC = port C, 0x30, would read as the PC register).
    The byte gate proves every rewrite (the address is encoded in the instruction).

RUN
    python3 scripts/converters/symbolize_v142_sfr_operands.py --apply ; make gate
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TREE = os.path.join(ROOT, "v142/subcpu")
FILES = ["kn5000_subprogram_v142.s", "subcpu_fp_math.s", "subcpu_data_tables.s", "subcpu_vectors.s"]


def main():
    names = {}
    for ln in open(os.path.join(TREE, "shared/sfr_tmp94c241.s"), encoding="latin-1"):
        m = re.match(r"\s*\.equ\s+(\w+)\s*,\s*(0x[0-9A-Fa-f]+|\d+)", ln)
        if m:
            names.setdefault(int(m.group(2), 0), []).append(m.group(1))
    # names the assembler reads as registers (`(PC:8)` parses as the PC register) are skipped
    RESERVED = {"PC", "SR", "SP", "A", "W", "B", "C", "D", "E", "H", "L", "WA", "BC", "DE", "HL",
                "IX", "IY", "IZ", "XWA", "XBC", "XDE", "XHL", "XIX", "XIY", "XIZ", "XSP", "F"}
    uniq = {v: n[0] for v, n in names.items() if len(n) == 1 and n[0].upper() not in RESERVED}
    DD8 = re.compile(r"^(\s*(?:set|res|bit|stcf|ldcf|xorcf|chg)_dd8\s+\d+\s*,\s*)(0x[0-9A-Fa-f]+|\d+)(\s*)$", re.I)
    MEM8 = re.compile(r"\((0x[0-9A-Fa-f]+|\d+):8\)")
    total = 0
    for f in FILES:
        p = os.path.join(TREE, f)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        n = 0
        for i, ln in enumerate(L):
            code, sep, com = ln.partition(";")
            m = DD8.match(code)
            if m and int(m.group(2), 0) in uniq:
                code = m.group(1) + uniq[int(m.group(2), 0)] + m.group(3)
                n += 1

            def sub(mm):
                nonlocal n
                v = int(mm.group(1), 0)
                if v in uniq:
                    n += 1
                    return "(%s:8)" % uniq[v]
                return mm.group(0)
            code = MEM8.sub(sub, code)
            L[i] = code + sep + com
        txt = "\n".join(L)
        if f == "kn5000_subprogram_v142.s":
            anchor = "; --- Interrupt Vector Table & Handlers ---\n"
            inc = ("; --- TMP94C241 special-function register names (.equ only, no bytes) ---\n"
                   "\t.include \"shared/sfr_tmp94c241.s\"\n\n")
            if inc not in txt:
                assert txt.count(anchor) == 1
                txt = txt.replace(anchor, inc + anchor)
        print("%-28s %4d operands" % (f, n))
        total += n
        if "--apply" in sys.argv:
            open(p, "wb").write(txt.encode("latin-1"))
    print("total", total)


if __name__ == "__main__":
    main()
