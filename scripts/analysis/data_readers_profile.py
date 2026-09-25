#!/usr/bin/env python3
r"""WHO READS THE DATA IN AN ADDRESS RANGE, AND HOW?  (maincpu v10 / v9 / v7)

QUESTION ANSWERED
    For every address in [LO, HI) that some INSTRUCTION names as an operand
    (hex or decimal immediate, `(addr)` operand, 24-bit `lda_24` form ...), list
    the instruction, the routine it sits in (nearest preceding ELF symbol) and
    the next N instructions -- which is where the element width (`ld_rrb` /
    `ld_rrw` / `ld_rrl`, `ldb_sri` ...), the stride (`muls`, `sla`) and the
    use (`call (xhl)`, `jp_rr` switch, `or a,0x90` ...) show up.

    The disassembly is `llvm-objdump -d` of rebuilt_ROMs/kn5000_<v>_program.llvm.elf
    (build it first).  Instructions located inside [LO, HI) itself and inside
    the widget-data bank 0xEE0000-0xEEFFFF are skipped so data decoded as code
    does not report itself.

⚠ WHAT THIS CANNOT SEE (state it beside any negative): a base held in RAM or
    passed in a register from far away, `TABLE - 4*k` constants (a table whose
    readers index from before its start), pointers stored in other data (use
    data_pointer_scan.py for those), and code the current tree misframes.

RUN
    python3 scripts/analysis/data_readers_profile.py --image v10 0xEE8C7E 0xEEAE08 [--next 7]
"""
import argparse
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OBJDUMP = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-objdump")
NUM = re.compile(r'(?<![\w+\-])(0x[0-9a-fA-F]+|\d+)\b')


def disassemble(image):
    elf = os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % image)
    out = subprocess.run([OBJDUMP, "-d", "--no-show-raw-insn", elf],
                         capture_output=True, text=True).stdout
    ins, cur = [], None
    for line in out.splitlines():
        m = re.match(r'^([0-9a-f]{8}) <(.*)>:', line)
        if m:
            cur = m.group(2)
            continue
        m = re.match(r'^\s+([0-9a-f]+):\s+(.*)$', line)
        if m:
            ins.append((int(m.group(1), 16), m.group(2).strip(), cur))
    return ins


def profile(ins, lo, hi):
    by = collections.defaultdict(list)
    for i, (a, t, f) in enumerate(ins):
        if lo <= a < hi or 0xEE0000 <= a < 0xEF0000:
            continue
        parts = t.split(None, 1)
        ops = parts[1] if len(parts) > 1 else ""
        for tok in NUM.findall(ops):
            v = int(tok, 16) if tok.startswith("0x") else int(tok)
            if lo <= v < hi:
                by[v].append(i)
    return by


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", default="v10")
    ap.add_argument("lo")
    ap.add_argument("hi")
    ap.add_argument("--next", type=int, default=6)
    ap.add_argument("--sites", type=int, default=3, help="sites shown per address")
    a = ap.parse_args()
    ins = disassemble(a.image)
    by = profile(ins, int(a.lo, 16), int(a.hi, 16))
    for v in sorted(by):
        print("=== 0x%06X  (%d refs)" % (v, len(by[v])))
        for i in by[v][:a.sites]:
            print("  [%s]" % ins[i][2])
            for j in range(i, min(i + a.next + 1, len(ins))):
                print("    %06x  %s" % (ins[j][0], ins[j][1]))


if __name__ == "__main__":
    main()
