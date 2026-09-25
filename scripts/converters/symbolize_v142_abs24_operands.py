#!/usr/bin/env python3
r"""symbolize_v142_abs24_operands.py -- numeric `(0xNNNNNN:24)` operands in the v1.42 sub-CPU
code that name an address INSIDE the payload image become `(Label:24)` / `(Label+N:24)`.
(Also the decimal spelling `(63191:24)` and the 16-bit absolute form `(61462:16)`, added
2026-09-25 after the first pass: same rules, the `:24`/`:16` width is kept.)

QUESTION THIS ANSWERS
    How many absolute 24-bit memory operands in kn5000_subprogram_v142.s / subcpu_fp_math.s
    still spell a payload address as a number (policy: every cross-reference symbolic), and
    which label does each one name?  With --apply, rewrite them.

WHY THESE ARE PROVEN ADDRESSES (the lane brief warns that in v142 the ROM range overlaps
small constants, so only proven addresses may be symbolised)
    * Only the ABSOLUTE MEMORY-OPERAND syntax `(value:24)` is touched -- `ld r,(m)`, `ld (m),r`,
      `lda r,(m)`, `jp (m)` ... .  The CPU uses that field as an effective address by
      definition of the addressing mode; plain immediates (`ld xwa, 0x12345`) are never
      touched, because those can be constants.
    * The value must lie inside the linked payload image (0x00F000 .. end of .text); RAM
      addresses (0x04xxxx and up, the vast majority) are left numeric -- they have no labels.
    * EXACT mode (default): a label must be defined at exactly that address in the linked ELF.
      INTERIOR mode (--interior): the value lies inside a labelled DATA object (the nearest label
      below it is defined in subcpu_data_tables.s) and the operand becomes `(Label+N:24)`.
    * The byte gate then proves the rewrite: the operand bytes are encoded in the instruction,
      so a label that resolves anywhere else changes the ROM.

HOW THE LABEL ADDRESSES ARE READ
    From `llvm-nm` of a FRESH link of the current tree (built into a temp dir by this script),
    and the linked image is asserted byte-identical to original_ROMs/kn5000_subprogram_v142.rom
    first, so the map describes THIS tree (stale-map guard).  Symbols starting with `.L`,
    `__` or containing `$` are never used.

RUN
    python3 scripts/converters/symbolize_v142_abs24_operands.py              # dry: counts
    python3 scripts/converters/symbolize_v142_abs24_operands.py --list       # every site
    python3 scripts/converters/symbolize_v142_abs24_operands.py --apply      # rewrite
    python3 scripts/converters/symbolize_v142_abs24_operands.py --interior --apply
  then `make gate`.
"""
import argparse
import bisect
import collections
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TREE = os.path.join(ROOT, "v142/subcpu")
ROM = os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom")
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
FILES = ["kn5000_subprogram_v142.s", "subcpu_fp_math.s"]
OPER = re.compile(r"\((0x[0-9a-fA-F]+|[0-9]+):(24|16)\)")


def build():
    d = tempfile.mkdtemp(prefix="v142abs24_")
    o, e, b = (os.path.join(d, x) for x in ("m.o", "m.elf", "m.bin"))
    subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-filetype=obj", "-I", TREE, "-o", o,
                    os.path.join(TREE, "kn5000_subprogram_v142.s")], check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-T", os.path.join(TREE, "subcpu.ld"), "-o", e, o],
                   check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", e, b], check=True)
    full = open(b, "rb").read()
    if full[:256] + full[60416:] != open(ROM, "rb").read():
        sys.exit("fresh link of this tree is NOT byte-identical to the dump -- refusing to map")
    nm = subprocess.run([os.path.join(LLVM, "llvm-nm"), "-n", e], check=True, capture_output=True,
                        text=True).stdout
    hdr = subprocess.run([os.path.join(LLVM, "llvm-objdump"), "-h", e], check=True, capture_output=True,
                         text=True).stdout
    end = None
    for ln in hdr.splitlines():
        p = ln.split()
        if len(p) >= 4 and p[1] == ".text":
            end = int(p[3], 16) + int(p[2], 16)
    at = collections.defaultdict(list)
    for ln in nm.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] in "tT" and not p[2].startswith((".L", "__")) and "$" not in p[2]:
            at[int(p[0], 16)].append(p[2])
    return at, end


def data_labels():
    out = set()
    for ln in open(os.path.join(TREE, "subcpu_data_tables.s"), "rb").read().decode("latin-1").split("\n"):
        m = re.match(r"^([A-Za-z_][\w]*):", ln)
        if m:
            out.add(m.group(1))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--interior", action="store_true")
    a = ap.parse_args()
    at, end = build()
    addrs = sorted(at)
    dlab = data_labels()
    st = collections.Counter()
    for f in FILES:
        p = os.path.join(TREE, f)
        L = open(p, "rb").read().decode("latin-1").split("\n")
        changed = 0
        for i, ln in enumerate(L):
            code, sep, com = ln.partition(";")

            def sub(m):
                nonlocal changed
                v = int(m.group(1), 0)
                w = m.group(2)
                if not (0xF000 <= v < end):
                    st["outside image (left numeric)"] += 1
                    return m.group(0)
                if v in at:
                    if len(at[v]) > 1:
                        st["exact, several labels (left numeric)"] += 1
                        return m.group(0)
                    new = "(%s:%s)" % (at[v][0], w)
                    st["exact label"] += 1
                else:
                    j = bisect.bisect_right(addrs, v) - 1
                    par = at[addrs[j]]
                    if not (a.interior and len(par) == 1 and par[0] in dlab):
                        st["interior (%s)" % ("data object" if par[0] in dlab else "not data")] += 1
                        return m.group(0)
                    new = "(%s+%d:%s)" % (par[0], v - addrs[j], w)
                    st["interior of a data object"] += 1
                if a.list:
                    print("%s:%d  %s -> %s" % (f, i + 1, m.group(0), new))
                changed += 1
                return new

            nc = OPER.sub(sub, code)
            if nc != code:
                L[i] = nc + sep + com
        if a.apply and changed:
            open(p, "wb").write("\n".join(L).encode("latin-1"))
            print("rewrote %s (%d operands)" % (f, changed))
    for k, v in sorted(st.items()):
        print("  %-40s %5d" % (k, v))


if __name__ == "__main__":
    main()
