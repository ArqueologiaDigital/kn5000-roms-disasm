#!/usr/bin/env python3
"""link_prom_a_to_prom_b.py -- prom_a's numeric branches into prom_b name the prom_b routine, through the linker.

QUESTION THIS ANSWERS / JOB IT DOES
  prom_a (CPU 1, 0xF80000-) calls routines of prom_b (0xF00000-0xF7FFFF) by number, many of them
  PC-relatively: `calr 0xf23b` at 0xF80007 lands at 0xF7F245, prom_b's sub_F7F245.  70 such
  sites on 2026-10-03.  The Inter-ROM policy wants the other ROM's label.  A `.set NAME, 0xF7F245`
  cannot serve a calr: llvm-mc folds an absolute symbol into the 16-bit displacement field and
  rejects it.  A symbol the LINKER SCRIPT defines (`NAME = 0xF7F245;`) can: the assembler emits
  a PC-relative relocation and ld.lld resolves it -- checked: `calr` assembles to the ROM's
  `1e 3b f2`.  So, for every numeric call/calr/jp/jr/jrl in prom_a whose target is a prom_b
  address with an ELF symbol there:
    * the name is prom_b's (a `sub_` name last), prefixed `PromB_` where prom_a has its OWN
      routine of that name (LCD_ScreenRedraw_Begin exists in both ROMs);
    * it is defined in prom_a/prom_a.ld, in a cross-ROM block -- and an existing `.set` of the
      same name in prom_a (T_F40034 ...) moves there, so the name keeps one definition;
    * the numeric operand becomes the name (the trailing address/bytes comment stays: wsa1
      tools read it).
  The relocation reproduces the same bytes: `make gate-all`.

USAGE
  make all
  python3 scripts/tools/link_prom_a_to_prom_b.py [--apply]
"""
import argparse
import collections
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
SRC = os.path.join(REPO, "wsa1/prom_a/wsa1_prom_a.s")
LD = os.path.join(REPO, "wsa1/prom_a/prom_a.ld")
RX = re.compile(r'^(?P<pre>\s*(?:\w+:)?\s*(?P<mn>call|calr|jp|jr|jrl)\s+(?:(?P<cc>[a-z]+)\s*,\s*)?)(?P<num>0x[0-9a-fA-F]+|[0-9]+)(?P<post>\s*;\s*(?P<site>[0-9A-F]{6})\s+(?P<by>(?:[0-9a-f]{2}\s?)+).*)$')


def syms(elf):
    by, kinds = collections.defaultdict(list), {}
    for l in subprocess.run([NM, "--defined-only", os.path.join(REPO, elf)], capture_output=True, text=True,
                            check=True).stdout.splitlines():
        a, t, n = l.split()
        kinds[n] = t
        if t in "tT" and not n.startswith(".L"):
            by[int(a, 16)].append(n)
    return by, kinds


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    B, _ = syms("wsa1/rebuilt_ROMs/wsa1_prom_b.llvm.elf")
    _, Ak = syms("wsa1/rebuilt_ROMs/wsa1_prom_a.llvm.elf")
    L = open(SRC, "rb").read().decode("latin-1").split("\n")
    sets = {}
    for i, l in enumerate(L):
        m = re.match(r'^\s*\.set\s+(\w+)\s*,\s*(0x[0-9a-fA-F]+)\s*$', l)
        if m:
            sets[m.group(1)] = (i, int(m.group(2), 16))
    names, sites = {}, []
    for i, l in enumerate(L):
        m = RX.match(l)
        if not m:
            continue
        mn, v, site, n = m.group("mn"), int(m.group("num"), 0), int(m.group("site"), 16), len(m.group("by").split())
        if mn in ("calr", "jrl"):
            tgt = site + n + (v - 0x10000 if v >= 0x8000 else v)
        elif mn == "jr":
            tgt = site + n + (v - 0x100 if v >= 0x80 else v)
        else:
            tgt = v
        if not (0xF00000 <= tgt < 0xF80000) or tgt not in B:
            continue
        if tgt not in names:
            nm = sorted(B[tgt], key=lambda x: (x.startswith("sub_"), len(x)))[0]
            own = Ak.get(nm) in ("t", "T") and nm not in sets
            names[tgt] = ("PromB_" + nm) if own else nm
        sites.append((i, m, names[tgt]))
    moved = [nm for nm in set(names.values()) if nm in sets]
    print("prom_a: %d numeric branches into prom_b, %d targets; %d existing .set constants move to the linker script%s"
          % (len(sites), len(names), len(moved), "" if a.apply else " (dry run)"))
    if not a.apply:
        return 0
    for i, m, nm in sites:
        L[i] = m.group("pre") + nm + m.group("post")
    for nm in moved:
        L[sets[nm][0]] = None
    open(SRC, "wb").write("\n".join(x for x in L if x is not None).encode("latin-1"))
    ld = open(LD, encoding="latin-1").read()
    block = ["", "/* Cross-ROM: prom_b routines prom_a reaches by number, several PC-relatively (calr / jr).",
             " * A `.set` constant would be folded into the 16-bit displacement and rejected; a symbol",
             " * defined here is relocated by ld.lld instead (scripts/tools/link_prom_a_to_prom_b.py,",
             " * 2026-10-03).  Cross-ref: wsa1/prom_b/wsa1_prom_b.s. */"]
    for tgt, nm in sorted(names.items()):
        block.append("%s = 0x%06X;" % (nm, tgt))
    open(LD, "w", encoding="latin-1").write(ld.rstrip("\n") + "\n" + "\n".join(block) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
