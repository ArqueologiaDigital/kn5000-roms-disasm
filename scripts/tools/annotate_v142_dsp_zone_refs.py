#!/usr/bin/env python3
r"""annotate_v142_dsp_zone_refs.py -- give every DSP-zone object its READER line.

QUESTION THIS ANSWERS
    For each bytecode stream / parameter record table in the v1.42 sub-CPU DSP
    effect zone (0x0147B3-0x01E17E, subcpu_data_tables.s), WHICH effect numbers
    reach it and through WHICH reader?  The zone header explains the four
    100-entry pointer arrays and their readers once, 6,000 lines above most of
    the objects; per object there was only "N instructions: ..." -- so a reader
    looking at DSP_Eff64_Coef_Bytecode could not tell from the object itself who
    uploads it, or that e.g. DSP_Eff00_* is shared by 42 effect numbers.

HOW
    Reads the four pointer arrays out of the ROM (EFF_AlgoProgram_PtrTable
    0x01ED7C, EFF_CoefProgram_PtrTable 0x01EF0C, DSP_Param_Block_Ptrs_A 0x01F09C,
    DSP_Param_Block_Ptrs_B 0x01F22C -- in the source they are `.long <label>`
    arrays, so the byte gate already pins every link), builds the ELF of the
    current tree to map each target address to its source label, and inserts ONE
    comment line directly above each target label:

        ; Reached via EFF_CoefProgram_PtrTable[64] (effect 64): uploaded by ...

    Lines it wrote carry the prefix "; Reached via " and are replaced on re-run,
    so the script is idempotent.  It never touches any other line.  Byte gate
    unaffected (comments only); run assert_comments_preserved.py after it.

RUN
    python3 scripts/tools/annotate_v142_dsp_zone_refs.py           # dry: counts
    python3 scripts/tools/annotate_v142_dsp_zone_refs.py --apply
"""
import argparse
import os
import re
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "v142/subcpu/subcpu_data_tables.s")
ROM = os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom")
LLVM = os.path.join(os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado")),
                    "llvm-project", "build", "bin")
ZONE = (0x0147B3, 0x01E17F)
PREFIX = "; Reached via "

ARRAYS = [  # base, name, reader text
    (0x01ED7C, "EFF_AlgoProgram_PtrTable",
     "algorithm program, uploaded by EFF_Change_WithDebug (0x0380EC) via DSP_WriteEFFConfig (0x03C161)"),
    (0x01EF0C, "EFF_CoefProgram_PtrTable",
     "coefficient program, uploaded by EFF_Change_WithDebug (0x0380EC) / EFF_DataChange_WithDebug "
     "(0x0381BC) via DSP_WriteEFFConfig"),
    (0x01F09C, "DSP_Param_Block_Ptrs_A",
     "value records, pushed by DSP_WriteParam_Generic (0x03C20E) for DSP_ParameterWriteEngine (0x03C9E6)"),
    (0x01F22C, "DSP_Param_Block_Ptrs_B",
     "descriptor records, passed in XDE by DSP_WriteParam_Generic (0x03C20E) to DSP_ParameterWriteEngine"),
]


def off(a):
    return a - 0xF000 + 0x100


def build_labels():
    d = tempfile.mkdtemp(prefix="annot_zone_")
    o, e = os.path.join(d, "v.o"), os.path.join(d, "v.elf")
    subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-filetype=obj", "-I",
                    "v142/subcpu", "-o", o, "v142/subcpu/kn5000_subprogram_v142.s"],
                   cwd=ROOT, check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-T", "v142/subcpu/subcpu.ld", "-o", e, o],
                   cwd=ROOT, check=True, capture_output=True)
    nm = subprocess.run([os.path.join(LLVM, "llvm-nm"), "-n", e], check=True,
                        capture_output=True, text=True).stdout
    lab = {}
    for ln in nm.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] == "t":
            lab.setdefault(int(p[0], 16), []).append(p[2])
    return lab


def ranges(nums):
    nums = sorted(nums)
    out, i = [], 0
    while i < len(nums):
        j = i
        while j + 1 < len(nums) and nums[j + 1] == nums[j] + 1:
            j += 1
        out.append(str(nums[i]) if i == j else "%d-%d" % (nums[i], nums[j]))
        i = j + 1
    return " ".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    rom = open(ROM, "rb").read()
    refs = {}
    for base, name, reader in ARRAYS:
        for i in range(100):
            t = struct.unpack("<I", rom[off(base + 4 * i):off(base + 4 * i) + 4])[0]
            if ZONE[0] <= t < ZONE[1]:
                refs.setdefault(t, {}).setdefault(name, []).append(i)
    labels = build_labels()
    by_label = {}
    for addr, arrs in refs.items():
        cand = [l for l in labels.get(addr, []) if not l.startswith("__")]
        if not cand:
            sys.exit("no label at 0x%06X" % addr)
        by_label[cand[0]] = (addr, arrs)
    raw = open(SRC, "rb").read().decode("latin-1")
    lines = raw.split("\n")
    out, n_new, n_same, seen = [], 0, 0, set()
    for ln in lines:
        m = re.match(r"^([A-Za-z_][\w]*):\s*$", ln)
        if m and m.group(1) in by_label:
            addr, arrs = by_label[m.group(1)]
            # drop our own previous line(s) directly above
            old = []
            while out and out[-1].startswith(PREFIX):
                old.insert(0, out.pop())
            new = []
            for base, name, reader in ARRAYS:
                if name in arrs:
                    idx = arrs[name]
                    what = ("effect %d" % idx[0]) if len(idx) == 1 else \
                           ("%d effects: %s" % (len(idx), ranges(idx)))
                    new.append("%s%s[%s] (%s): %s." % (PREFIX, name,
                               idx[0] if len(idx) == 1 else "..", what, reader))
            out += new
            n_same += old == new
            n_new += old != new
            seen.add(m.group(1))
        out.append(ln)
    missing = set(by_label) - seen
    if missing:
        sys.exit("labels not found in source: %s" % sorted(missing)[:5])
    print("zone objects reached by the four arrays: %d (changed %d, unchanged %d)" %
          (len(by_label), n_new, n_same))
    if a.apply and n_new:
        open(SRC, "wb").write("\n".join(out).encode("latin-1"))
        print("rewrote", os.path.relpath(SRC, ROOT))


if __name__ == "__main__":
    main()
