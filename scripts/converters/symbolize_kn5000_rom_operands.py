#!/usr/bin/env python3
"""symbolize_kn5000_rom_operands.py -- numeric main-CPU ROM addresses in KN5000 operands -> labels.

QUESTION THIS ANSWERS / JOB IT DOES
  CLAUDE.md's Symbolic Cross-Referencing policy: an operand that is an address names what it
  points at.  `semantic_debt_dashboard.py` (column numaddr) counts the numeric ones still in
  the KN5000 main-CPU trees -- `lda xix, (0xeda62c:24)`, `ld xiy, 16165950` -- and on
  2026-10-02 found most of v7's 1,782 to be addresses where v7's OWN linked ELF already has a
  symbol: text ported from another version that kept the number (the Wave 2 review's
  "v7 ports emit numeric absolute operands even where a v7 label exists").
  This replaces such an operand literal with that symbol -- EXACT matches only:

    * only non-branch instruction operands (branches are symbolize_numeric_branches.py's);
    * only values in the image's own ROM range (main CPU 0xE00000..0xFFFFFF, HD-AE5000
      0x280000..0x2FFFFF since 2026-10-02);
    * only when the image's linked ELF defines a non-local symbol AT that address; with several,
      a column-0 label beats a `.set`/`.equ` alias, a non-structural name beats a structural
      one (`_Skip`, `_Join`, `_Loop`, `_Return`, `_Helper`, `_Epilogue`, `_Data`, `_0x..`),
      then the shortest, then alphabetical -- deterministic, and reported.
  A label at the address changes no byte, so `make gate-all` proves every substitution (a
  form whose encoding depended on the constant would turn the gate red).  Everything else --
  addresses inside an object, other ROMs' addresses (table data 0x8xxxxx), values with no
  symbol -- is reported, not touched.

USAGE
  make rebuilt_ROMs/kn5000_<v>_program.llvm.elf          (the ELF must match the tree)
  python3 scripts/converters/symbolize_kn5000_rom_operands.py --image v7 [--apply] [--report OUT]
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
INSN = re.compile(r'^(\s*(?:[A-Za-z_.$][\w.$@]*:)?\s*)(?!jr\b|jrl\b|calr\b|call\b|jp\b|djnz\b|\.)'
                  r'([a-z_][a-z0-9_]*)(\s+)([^;\n]*?)(\s*(?:;.*)?)$')
LIT = re.compile(r'(?<![\w.$])(0x[0-9a-fA-F]+|\d{7,})(?![\w.$])')
STRUCT = re.compile(r'_(Skip|Join|Loop|Return|Helper|Epilogue|Entry|Sub|Tail|Next|Done|Exit|'
                    r'End|Data|Block|Bytes|Code)\d*$|_0x[0-9A-Fa-f]+$|^LABEL_|^sub_|^loc_', re.I)


IMAGES = {"v10": ("rebuilt_ROMs/kn5000_v10_program.llvm.elf", "v10/maincpu", (0xE00000, 0xFFFFFF)),
          "v9": ("rebuilt_ROMs/kn5000_v9_program.llvm.elf", "v9/maincpu", (0xE00000, 0xFFFFFF)),
          "v7": ("rebuilt_ROMs/kn5000_v7_program.llvm.elf", "v7/maincpu", (0xE00000, 0xFFFFFF)),
          "hdae5000": ("rebuilt_ROMs/hd-ae5000_v2_06i.llvm.elf", "hdae5000", (0x280000, 0x2FFFFF)),
          # SX-WSA1R (2026-10-03): each image's own subdirectory and own range
          "prom_a": ("wsa1/rebuilt_ROMs/wsa1_prom_a.llvm.elf", "wsa1/prom_a", (0xF80000, 0xFFFFFF)),
          "prom_b": ("wsa1/rebuilt_ROMs/wsa1_prom_b.llvm.elf", "wsa1/prom_b", (0xF00000, 0xF7FFFF)),
          "prom_c": ("wsa1/rebuilt_ROMs/wsa1_prom_c.llvm.elf", "wsa1/prom_c", (0xF80000, 0xFFFFFF))}


def elf_symbols(image):
    elf = os.path.join(REPO, IMAGES[image][0])
    out = subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True,
                         check=True).stdout
    by = collections.defaultdict(list)
    for l in out.splitlines():
        a, t, n = l.split()
        if n.startswith(".L") or t.lower() not in ("t", "a"):
            continue
        by[int(a, 16)].append(n)
    return by


def labels_in_source(files):
    lab = set()
    for f in files:
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = re.match(r'^([A-Za-z_][\w.$@]*):', l)
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
    files = sorted(glob.glob(os.path.join(REPO, IMAGES[a.image][1], "**", "*.s"), recursive=True))
    lo, hi = IMAGES[a.image][2]
    syms = elf_symbols(a.image)
    col0 = labels_in_source(files)
    stats, rows = collections.Counter(), []
    changed_files = 0
    # a macro may split its argument into bytes (`.byte (X) & 0xFF` in WSA1's m_cp_mi16 / m_jp_cc),
    # which only a constant survives: macro invocations are never touched (2026-10-03, after
    # 2ad61128 broke prom_a's build that way)
    macros = set()
    for f in sorted(sum((glob.glob(os.path.join(REPO, IMAGES[a.image][1].split("/")[0], "**", g), recursive=True)
                         for g in ("*.s", "*.inc")), [])):
        macros |= set(m.lower() for m in re.findall(r'^\s*\.macro\s+(\w+)', open(f, "rb").read().decode("latin-1"), re.M))
    for f in files:
        L = open(f, "rb").read().decode("latin-1").split("\n")
        dirty = False
        for i, line in enumerate(L):
            m = INSN.match(line)
            if not m:
                continue
            head, mn, ws, ops, tail = m.groups()
            if "\\" in ops or mn.lower() in macros:
                continue

            def sub(mm):
                v = int(mm.group(1), 0)
                if not lo <= v <= hi:
                    return mm.group(0)
                names = syms.get(v)
                rel = os.path.relpath(f, REPO)
                if not names:
                    stats["no-symbol-at-address"] += 1
                    rows.append({"file": rel, "line": i + 1, "value": hex(v), "result": "no-symbol"})
                    return mm.group(0)
                n = pick(names, col0)
                stats["replaced"] += 1
                if len(names) > 1:
                    stats["chosen-among-several"] += 1
                rows.append({"file": rel, "line": i + 1, "value": hex(v), "result": n,
                             "candidates": names if len(names) > 1 else None})
                return n
            new_ops = LIT.sub(sub, ops)
            if new_ops != ops:
                L[i] = head + mn + ws + new_ops + tail
                dirty = True
        if dirty:
            changed_files += 1
            if a.apply:
                open(f, "wb").write("\n".join(L).encode("latin-1"))
    print("image %s: %s; files %d%s" % (a.image, dict(stats), changed_files,
                                        "" if a.apply else " (dry run)"))
    if a.report:
        json.dump(rows, open(a.report, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
