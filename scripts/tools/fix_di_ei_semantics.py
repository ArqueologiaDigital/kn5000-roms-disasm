#!/usr/bin/env python3
r"""Retire the `di` mnemonic from every source: it assembles to the OPPOSITE of DI.

QUESTION THIS ANSWERS / DEFECT IT FIXES
---------------------------------------
The pinned llvm-mc (tlcs900_backend@4d7fa4f6b37c, binary a7ee33d5) encodes `di` as
[0x06,0x00] -- the same bytes as `ei 0` -- and prints 06 00 back as `di`:

    printf 'di\nei 0\nei 7\n' | llvm-mc -triple=tlcs900 -show-encoding
      di     ; encoding: [0x06,0x00]
      di     ; encoding: [0x06,0x00]      <- `ei 0` printed back as `di`
      ei 7   ; encoding: [0x06,0x07]

On the TLCS-900, `EI n` loads the interrupt mask IFF with n, and an interrupt is
accepted when its level is >= IFF (MAME tlcs900 `op_EI`:
`m_sr.b.h = (m_sr.b.h & 0x8f) | ((imm & 7) << 4)`).  So 06 00 sets IFF=0 and
ACCEPTS EVERY LEVEL; the real DI is `EI 7` = 06 07 (TMP94C241 instruction
reference: "DI ; IFF=7 (disable all maskable interrupts)").  Every `di` in
these sources therefore reads as the opposite of what the CPU does -- found by
the prom_b judge of the 2026-09-25 branch-symbolisation verification panel.

The ROM bytes at every such site are 06 00 (the byte gate is exact), so the
honest spelling is `ei 0`, which assembles to the same bytes.  This script:
  1. rewrites every instruction `di` as `ei 0` (bytes unchanged);
  2. corrects a SAME-LINE comment on `di`/`ei 0` that says "disable
     interrupts", and one on `ei 7` that says "enable interrupts" -- both
     state the opposite of the effect;
and leaves every other comment alone.

RUN
    python3 scripts/tools/fix_di_ei_semantics.py            # dry run: counts per file
    python3 scripts/tools/fix_di_ei_semantics.py --apply
then `make gate-all` (must stay 13/13 byte-identical: `ei 0` == 06 00 == old `di`).

Measured 2026-09-25 before --apply: `di` in v10 36, v9 68, v7 54, v142 2,
hdae5000 26, wsa1 27 (all instruction lines, all encoding 06 00).
"""
import re
import subprocess
import sys

LBL = r'(?:[A-Za-z_.$][\w.$@]*:\s*)?'
DI = re.compile(r'^(\s*' + LBL + r')di(\s*)(;.*)?$')
EI0 = re.compile(r'^(\s*' + LBL + r')ei\s+(?:0|0x00)\s*(;.*)?$')
EI7 = re.compile(r'^(\s*' + LBL + r')ei\s+(?:7|0x07)\s*(;.*)?$')
C_ACCEPT = "; IFF=0: accepts every interrupt level (06 00; was mis-spelled `di`)"
C_MASK = "; IFF=7: masks every maskable level -- this IS the real DI (06 07)"


def fix_line(ln):
    body = ln.rstrip("\r")
    cr = ln[len(body):]
    m = DI.match(body)
    if m:
        pre, ws, com = m.group(1), m.group(2), m.group(3)
        if com and re.search(r'disable\s+(maskable\s+)?interrupt', com, re.I):
            com = C_ACCEPT
        return "%sei\t0%s%s%s" % (pre, ws if com else "", com or "", cr), "di"
    m = EI0.match(body)
    if m and m.group(2) and re.search(r'disable\s+(maskable\s+)?interrupt', m.group(2), re.I):
        return body[:body.index(";")] + C_ACCEPT + cr, "ei0-comment"
    m = EI7.match(body)
    if m and m.group(2) and re.search(r'(?<!dis)enable\s+(maskable\s+)?interrupt', m.group(2), re.I):
        return body[:body.index(";")] + C_MASK + cr, "ei7-comment"
    return ln, None


def main():
    apply = "--apply" in sys.argv
    files = subprocess.run(["git", "ls-files", "*.s"], capture_output=True,
                           text=True).stdout.split()
    total = {}
    for f in files:
        raw = open(f, "rb").read().decode("latin-1")
        lines = raw.split("\n")
        changed = {}
        for i, ln in enumerate(lines):
            new, kind = fix_line(ln)
            if kind:
                changed[kind] = changed.get(kind, 0) + 1
                lines[i] = new
        if changed:
            print("%-55s %s" % (f, changed))
            for k, v in changed.items():
                total[k] = total.get(k, 0) + v
            if apply:
                open(f, "wb").write("\n".join(lines).encode("latin-1"))
    print("TOTAL", total, "(applied)" if apply else "(dry run)")


if __name__ == "__main__":
    main()
