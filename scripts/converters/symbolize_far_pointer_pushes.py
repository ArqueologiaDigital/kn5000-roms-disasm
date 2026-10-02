#!/usr/bin/env python3
"""symbolize_far_pointer_pushes.py -- `pushw 0x00e4 / pushw 0x5126` -> `pushw Sym@hi16 / pushw Sym@lo16`.

QUESTION THIS ANSWERS / JOB IT DOES
  The firmware's C compiler passes a 32-bit far pointer argument as two word pushes, high half
  first: `pushw 0xe4` then `pushw 0x5126` is the pointer 0xe45126 (a string literal of
  PathInfo_BuildAndOpen, here).  Each half is below the ROM range, so neither
  symbolize_kn5000_rom_operands.py nor the dashboard's numaddr column ever saw them -- yet they
  are the commonest numeric ROM reference left in the C-compiled code (about 800 per KN5000
  maincpu version).  The assembler takes `sym@hi16` / `sym@lo16` since llvm-project
  TLCS900 UPDATE 20 (R_TLCS900_HI16 / R_TLCS900_LO16, folded for an absolute symbol).

  For each ADJACENT pair of numeric `pushw HI` / `pushw LO` lines with HI <= 0xff, the pointer
  (HI << 16) | LO is looked up in the image's OWN linked ELF (a pair that does not qualify moves
  the window by ONE line: the compiler often pushes `3, hi, lo`, and stepping by two put every
  later pair of such a run out of phase -- the first pass of 2026-10-02 missed them):
    * only inside the image's own ROM range (other ROMs' addresses and RAM are reported, not
      touched);
    * EXACT symbol only -- same pick order as symbolize_kn5000_rom_operands.py: a column-0
      label beats a `.set`/`.equ` alias, a non-structural name beats a structural one, then the
      shortest, then alphabetical;
    * a pointer INSIDE an object (no symbol at the address) is reported as `inside Parent+0xN`
      -- those need the object split or typed first, which is a reading job, not this tool's.
  The same lookup names the numeric ROM-address ARGUMENTS of the NAKA registration macros
  (REG_ADDR_ARGS: `RegObjTabl 0x1600003, MainFunctionProc, 7, 0xe5ad8c, 0x143` ->
  `..., East_MainFuncTable_143, ...`), and RegMode/RegTitle, which took the pointer as two
  numbers (`RegTitle 0x3, 0xe5, 0xac98, ...`), are respelled to take one address
  (`RegTitle 0x3, InitializeEast_Str_TT_REVEQMENU, ...`) with their definitions; a call whose
  pointer has no symbol keeps the two numbers through a `RegTitleHiLo` copy of the old macro.
  A label at the same address changes no byte, so `make gate-all` proves every substitution.

USAGE
  make all                                     (the ELFs must match the tree)
  python3 scripts/converters/symbolize_far_pointer_pushes.py --image v10 [--apply] [--report OUT]
  images: v10 v9 v7 hdae5000 tabledata prom_a prom_b prom_c
"""
import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
IMAGES = {  # image: (ELF, source glob, own ROM range)
    "v10": ("rebuilt_ROMs/kn5000_v10_program.llvm.elf", "v10/maincpu", (0xE00000, 0xFFFFFF)),
    "v9": ("rebuilt_ROMs/kn5000_v9_program.llvm.elf", "v9/maincpu", (0xE00000, 0xFFFFFF)),
    "v7": ("rebuilt_ROMs/kn5000_v7_program.llvm.elf", "v7/maincpu", (0xE00000, 0xFFFFFF)),
    "hdae5000": ("rebuilt_ROMs/hd-ae5000_v2_06i.llvm.elf", "hdae5000", (0x280000, 0x2FFFFF)),
    "tabledata": ("rebuilt_ROMs/kn5000_table_data.llvm.elf", "table_data", (0x800000, 0x9FFFFF)),
    "prom_a": ("wsa1/rebuilt_ROMs/wsa1_prom_a.llvm.elf", "wsa1/prom_a", (0xF80000, 0xFFFFFF)),
    "prom_b": ("wsa1/rebuilt_ROMs/wsa1_prom_b.llvm.elf", "wsa1/prom_b", (0xF00000, 0xF7FFFF)),
    "prom_c": ("wsa1/rebuilt_ROMs/wsa1_prom_c.llvm.elf", "wsa1/prom_c", (0xF80000, 0xFFFFFF)),
}
# NAKA registration macros (display/scoop_display.s, factory_test/test_init.s): which
# arguments are ROM addresses.  RegMode/RegTitle took the far pointer as two numbers
# (ParamBhi, ParamBlow) until 2026-10-02; with `@hi16`/`@lo16` they take one address.
REG_MACRO = re.compile(r'^(\s+)(RegObjTable|RegObjTabl|RegModeHiLo|RegTitleHiLo|RegMode|RegTitle|'
                       r'RegObjTableHama|RegObjTablHama|RegTitleHama)(\s+)([^;]*?)(\s*(?:;.*)?)$')
REG_ADDR_ARGS = {"RegObjTable": (1, 2, 3), "RegObjTabl": (1, 3), "RegObjTableHama": (1, 2, 3),
                 "RegModeHiLo": (1,), "RegTitleHiLo": (1,),
                 "RegObjTablHama": (1, 3), "RegTitleHama": (1,), "RegMode": (1,), "RegTitle": (1,)}
REG_HILO = ("RegMode", "RegTitle", "RegModeHiLo", "RegTitleHiLo")   # 6 arguments = (hi, lo)
# what each address argument IS (RegisterObjectTable / RegisterTitle / RegisterMode):
REG_ROLE = {"RegObjTable": {1: "proc", 2: "count", 3: "table"}, "RegObjTabl": {1: "proc", 3: "table"},
            "RegObjTableHama": {1: "proc", 2: "count", 3: "table"},
            "RegObjTablHama": {1: "proc", 3: "table"}, "RegTitleHama": {1: "title"},
            "RegMode": {1: "title"}, "RegTitle": {1: "title"}, "RegModeHiLo": {1: "title"},
            "RegTitleHiLo": {1: "title"}}
HILO_DEF = re.compile(r'^\.macro (RegMode|RegTitle) ParamA, ParamBhi, ParamBlow, ParamC, ParamD, ParamE\s*$')
HILO_COPY = re.compile(r'^\.macro (RegModeHiLo|RegTitleHiLo) ')


def reg_macro_addresses(line):
    """[(arg index, value)] for the numeric address arguments of a Reg* macro line; a
    (hi, lo) pair of the old RegMode/RegTitle spelling is reported once, at index 1."""
    m = REG_MACRO.match(line)
    if not m:
        return None, []
    args = [x.strip() for x in m.group(4).split(",")]
    out = []
    num = re.compile(r'^(0x[0-9a-fA-F]+|\d+)$')
    if m.group(2) in REG_HILO and len(args) == 6:
        if num.match(args[1]) and num.match(args[2]):
            out.append((1, (int(args[1], 0) << 16) | int(args[2], 0)))
        return m, out
    for k in REG_ADDR_ARGS[m.group(2)]:
        if k < len(args) and num.match(args[k]):
            out.append((k, int(args[k], 0)))
    return m, out


PUSH = re.compile(r'^(\s*(?:[A-Za-z_.$][\w.$]*:)?\s*pushw\s+)(0x[0-9a-fA-F]+|\d+)(\s*(?:;.*)?)$')
STRUCT = re.compile(r'_(Skip|Join|Loop|Return|Helper|Epilogue|Entry|Sub|Tail|Next|Done|Exit|'
                    r'End|Data|Block|Bytes|Code)\d*$|_0x[0-9A-Fa-f]+$|^LABEL_|^sub_|^loc_', re.I)


def elf_symbols(elf):
    out = subprocess.run([NM, "--defined-only", "-n", os.path.join(REPO, elf)],
                         capture_output=True, text=True, check=True).stdout
    by = collections.defaultdict(list)
    for l in out.splitlines():
        a, t, n = l.split()
        if n.startswith(".L") or t.lower() not in ("t", "a"):
            continue
        by[int(a, 16)].append(n)
    return by


def col0_labels(files):
    lab = set()
    for f in files:
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = re.match(r'^([A-Za-z_][\w.$]*):', l)
            if m:
                lab.add(m.group(1))
    return lab


def pick(names, col0):
    return sorted(names, key=lambda n: (n not in col0, bool(STRUCT.search(n)), len(n), n))[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, choices=sorted(IMAGES))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    a = ap.parse_args()
    elf, tree, (lo, hi) = IMAGES[a.image]
    files = sorted(glob.glob(os.path.join(REPO, tree, "**", "*.s"), recursive=True))
    syms = elf_symbols(elf)
    addrs = sorted(syms)
    col0 = col0_labels(files)
    import bisect
    stats, rows, changed = collections.Counter(), [], 0
    hilo_left = collections.Counter()
    for f in files:
        L = open(f, "rb").read().decode("latin-1").split("\n")
        dirty = False
        i = 0
        while i < len(L) - 1:
            m1, m2 = PUSH.match(L[i]), PUSH.match(L[i + 1])
            if not (m1 and m2):
                i += 1
                continue
            h, l = int(m1.group(2), 0), int(m2.group(2), 0)
            if h > 0xff or l > 0xffff:
                i += 1
                continue
            v = (h << 16) | l
            rel = os.path.relpath(f, REPO)
            if not lo <= v <= hi:
                stats["outside-own-rom"] += 1
                i += 1              # `pushw 3 / pushw 0xe5 / pushw 0xac98`: the pair may start here
                continue
            names = syms.get(v)
            if not names:
                k = bisect.bisect_right(addrs, v) - 1
                parent = "%s+0x%x" % (pick(syms[addrs[k]], col0), v - addrs[k]) if k >= 0 else "?"
                stats["inside-an-object"] += 1
                rows.append({"file": rel, "line": i + 1, "value": hex(v), "result": "inside " + parent})
                i += 1
                continue
            n = pick(names, col0)
            stats["replaced"] += 1
            rows.append({"file": rel, "line": i + 1, "value": hex(v), "result": n,
                         "candidates": names if len(names) > 1 else None})
            L[i] = m1.group(1) + n + "@hi16" + m1.group(3)
            L[i + 1] = m2.group(1) + n + "@lo16" + m2.group(3)
            dirty = True
            i += 2
        for i, line in enumerate(L):                    # Reg* macro address arguments
            m, found = reg_macro_addresses(line)
            if not m:
                continue
            name = m.group(2).replace("HiLo", "")
            args = [x.strip() for x in m.group(4).split(",")]
            hilo = name in REG_HILO and len(args) == 6
            for k, v in found:
                rel = os.path.relpath(f, REPO)
                names = syms.get(v) if lo <= v <= hi else None
                if not names:
                    stats["macro-arg-unresolved"] += 1
                    rows.append({"file": rel, "line": i + 1, "value": hex(v), "result": "macro arg, no symbol"})
                    continue
                n = pick(names, col0)
                stats["macro-arg-replaced"] += 1
                rows.append({"file": rel, "line": i + 1, "value": hex(v), "result": n})
                if hilo:
                    args[1:3] = [n]
                    hilo = False
                else:
                    args[k] = n
            if name in REG_HILO and hilo:
                name += "HiLo"                          # left in the old two-number spelling
                hilo_left[name] += 1
            new = m.group(1) + name + m.group(3) + ", ".join(args) + m.group(5)
            if new != line:
                L[i] = new
                dirty = True
        if dirty:
            changed += 1
            if a.apply:
                open(f, "wb").write("\n".join(L).encode("latin-1"))
    # RegMode/RegTitle take one address now; a HiLo copy is kept only while a call needs it
    for f in files:
        L = open(f, "rb").read().decode("latin-1").split("\n")
        out, i, dirty = [], 0, False
        while i < len(L):
            m = HILO_COPY.match(L[i])
            if m and not hilo_left.get(m.group(1)):        # the last two-number call is gone
                while not L[i].startswith(".endm"):
                    i += 1
                i += 1
                while out and (out[-1] == "" or out[-1].startswith("; %s with the pointer as two"
                                                                  % m.group(1)[:-4])):
                    out.pop()
                dirty = True
                stats["hilo-copies-dropped"] += 1
                continue
            m = HILO_DEF.match(L[i])
            if not m:
                out.append(L[i]); i += 1; continue
            j = i
            while not L[j].startswith(".endm"):
                j += 1
            body = L[i:j + 1]
            new = ["; The far pointer is ONE address (TOOLCHAIN_VERSION UPDATE 20: `@hi16`/`@lo16`);",
                   "; the compiled call pushes ParamA, then its high and low halves."]
            new += [b.replace("ParamBhi, ParamBlow", "ParamB")
                     .replace("pushw \\ParamBhi", "pushw \\ParamB\\()@hi16")
                     .replace("pushw \\ParamBlow", "pushw \\ParamB\\()@lo16") for b in body]
            if hilo_left.get(m.group(1) + "HiLo"):
                new += ["", "; %s with the pointer as two numbers, for a call whose target has no label yet."
                        % m.group(1)] + [body[0].replace(m.group(1), m.group(1) + "HiLo", 1)] + body[1:]
            out += new
            i = j + 1
            dirty = True
            stats["macro-definitions-respelled"] += 1
        if dirty and a.apply:
            open(f, "wb").write("\n".join(out).encode("latin-1"))
    print("image %s: %s; files %d%s" % (a.image, dict(stats), changed,
                                        "" if a.apply else " (dry run)"))
    if a.report:
        json.dump(rows, open(a.report, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
