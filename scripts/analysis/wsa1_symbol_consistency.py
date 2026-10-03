#!/usr/bin/env python3
"""wsa1_symbol_consistency.py -- two silent symbol faults the byte gate does not always catch.

QUESTIONS THIS ANSWERS
  1. Does any WSA1 assembly unit define one name both as a label and as a `.set` / `.equ`, or
     define one label twice?  llvm-mc takes a duplicate `.equ` without an error: 2026-10-03 the RAM
     name SeqEvt_ShadowModulation (0x60F5B0) replaced the routine of the same name in the jump table
     at 0xFAF16C (make gate-all caught it, 36 bytes off).  A clash on a name nothing references
     changes no byte, and only this check catches that.
  2. prom_a and prom_b are separate links on one CPU.  Each spells the other's routines with a
     `.set NAME, 0x...`.  Does every such value equal the address the other image's ELF gives the
     label of that name?  A wrong value is still byte-exact, but the name is then wrong.

  Units are followed through their `.include` directives.  Exit 1 on any finding.

USAGE
  make wsa1
  python3 scripts/analysis/wsa1_symbol_consistency.py
"""
import collections
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
W = os.path.join(REPO, "wsa1")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
LAB = re.compile(r'^([A-Za-z_.$][\w.$]*):')
SET = re.compile(r'^\s*\.(?:set|equ)\s+([A-Za-z_.$][\w.$]*)\s*,')
INC = re.compile(r'^\s*\.include\s+"([^"]+)"')
UNITS = ["prom_a/wsa1_prom_a.s", "prom_b/wsa1_prom_b.s", "prom_c/wsa1_prom_c.s", "prom_d/wsa1_prom_d.s"]


def lines(f):
    return open(f, "rb").read().decode("latin-1").split("\n")


def unit_files(top):
    top = os.path.join(W, top)
    files, todo = [], [top]
    while todo:
        f = todo.pop()
        if f in files:
            continue
        files.append(f)
        for l in lines(f):
            m = INC.match(l)
            if m:
                for c in (os.path.join(os.path.dirname(f), m.group(1)),
                          os.path.join(os.path.dirname(top), m.group(1)), os.path.join(W, m.group(1))):
                    if os.path.exists(c):
                        todo.append(os.path.normpath(c))
                        break
    return files


def elf_labels(img):
    out = subprocess.run([NM, "--defined-only", os.path.join(W, "rebuilt_ROMs", "wsa1_%s.llvm.elf" % img)],
                         capture_output=True, text=True, check=True).stdout
    return {p[2]: int(p[0], 16) for p in (l.split() for l in out.split("\n")) if len(p) == 3 and p[1] in "tT"}


def main():
    bad = 0
    for top in UNITS:
        labs, sets = collections.defaultdict(list), collections.defaultdict(list)
        for f in unit_files(top):
            for k, l in enumerate(lines(f)):
                where = "%s:%d" % (os.path.relpath(f, REPO), k + 1)
                m = LAB.match(l)
                if m:
                    labs[m.group(1)].append(where)
                m = SET.match(l)
                if m:
                    sets[m.group(1)].append(where)
        both = sorted(set(labs) & set(sets))
        dup = sorted(n for n, v in labs.items() if len(v) > 1)
        for n in both:
            print("  label and .set/.equ: %s  %s / %s" % (n, labs[n][0], sets[n][0]))
        for n in dup:
            print("  label defined twice: %s  %s" % (n, " ".join(labs[n])))
        bad += len(both) + len(dup)
        print("%-24s label+set clashes %d, duplicate labels %d" % (top, len(both), len(dup)))
    A, B = elf_labels("prom_a"), elf_labels("prom_b")
    for me, mine, other in (("prom_a", A, B), ("prom_b", B, A)):
        n = wrong = 0
        for l in lines(os.path.join(W, me, "wsa1_%s.s" % me)):
            m = SET.match(l)
            if m and m.group(1) in other:
                n += 1
                # the .set is absolute, so llvm-nm lists it as `a`, not `t`: read it from the full table
                if VALUES[me].get(m.group(1)) != other[m.group(1)]:
                    wrong += 1
                    print("  %s .set %s = %s, the other image's label is at 0x%x" %
                          (me, m.group(1), VALUES[me].get(m.group(1)), other[m.group(1)]))
        bad += wrong
        print("%-24s .set names of the other image's labels %d, disagree %d" % (me, n, wrong))
    return 1 if bad else 0


def all_values(img):
    out = subprocess.run([NM, "--defined-only", os.path.join(W, "rebuilt_ROMs", "wsa1_%s.llvm.elf" % img)],
                         capture_output=True, text=True, check=True).stdout
    return {p[2]: int(p[0], 16) for p in (l.split() for l in out.split("\n")) if len(p) == 3}


VALUES = {"prom_a": all_values("prom_a"), "prom_b": all_values("prom_b")}

if __name__ == "__main__":
    sys.exit(main())
