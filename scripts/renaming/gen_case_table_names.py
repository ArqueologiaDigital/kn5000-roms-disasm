#!/usr/bin/env python3
"""gen_case_table_names.py -- name `X_Data` switch case-offset tables after the routine that reads them (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  A compiled `switch` reads a table of u16 case offsets (`.short Case - Base` lines) with `ld xix, <table>` /
  `add xwa, <table>` and jumps with `jp t, (xix+wa)`.  Earlier passes named many such tables `<something>_Data`,
  `_Data_2`, ...: generic names (semantic_score counts _Data as generic), and some of them named after
  whichever label happened to come before the table (SetWall_ReturnZero_Data_2 is read inside
  SqTrAsPsTtl_CaseF).  For every label of a .text symbol matching `_Data(\\d*|_\\d+)$` whose first statement is
  `.short A - B`, this script finds the one instruction that names the table and the routine it sits in.  That
  routine is the nearest label above the reader, with a continuation suffix (_Skip3, _Return ...) stripped.  The
  table is renamed `<routine>_CaseTable`, or `_CaseTable2`, `_CaseTable3` ... when the name is taken.  A table
  with no reader, or more than one, is left alone and listed.
  It writes scripts/renaming/rename_case_tables_<tree>.sed, one per tree.  Apply with
  `sed -i -f <sed> <files>` (--apply does that for every .s/.c/.ld file of the tree that holds an old name).
  Then: make all, make gate-all, l2_symbol_reference --regen/--check.

RUN (repository root; a built tree, for the ELF symbol list)
  python3 scripts/renaming/gen_case_table_names.py            # print the plan
  python3 scripts/renaming/gen_case_table_names.py --apply
"""
import glob
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
APPLY = "--apply" in sys.argv
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
ELF = {"v10": "rebuilt_ROMs/kn5000_v10_program.llvm.elf", "v9": "rebuilt_ROMs/kn5000_v9_program.llvm.elf",
       "v7": "rebuilt_ROMs/kn5000_v7_program.llvm.elf"}
CONT = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Done|Next|Exit|Cont|End|Default|Resume|Nop)\d*$')
LABEL = re.compile(r'^([A-Za-z_]\w*):')


def code(line):
    return line.split(";", 1)[0]


def plan(tree):
    out = subprocess.run([NM, "--defined-only", os.path.join(REPO, ELF[tree])], capture_output=True, text=True)
    assert out.returncode == 0, "build the tree first"
    syms = set()
    want = set()
    for line in out.stdout.split("\n"):
        f = line.split()
        if len(f) == 3:
            syms.add(f[2])
            if f[1] in "tT" and re.search(r'_Data(\d*|_\d+)$', f[2]):
                want.add(f[2])
    files = {}
    for p in glob.glob(os.path.join(REPO, tree, "maincpu", "**", "*.s"), recursive=True):
        files[p] = open(p, "rb").read().decode("latin-1").split("\n")
    tables = {}
    for p, L in files.items():
        for i, x in enumerate(L):
            m = LABEL.match(x)
            if not m or m.group(1) not in want:
                continue
            rest = code(x)[len(m.group(0)):].strip()
            j = i + 1
            while not rest and j < len(L):
                rest = code(L[j]).strip()
                j += 1
            if re.match(r'^\.short\s+\w+\s*-\s*\w+\s*$', rest):
                tables[m.group(1)] = (p, i)
    readers = {n: [] for n in tables}
    pat = re.compile(r'\b(%s)\b' % "|".join(re.escape(n) for n in tables)) if tables else None
    for p, L in files.items():
        for i, x in enumerate(L):
            c = code(x)
            if not pat or LABEL.match(c) and c.split(":", 1)[1].strip() == "":
                continue
            body = LABEL.sub("", c)
            if body.strip().startswith(".short"):
                continue
            for n in pat.findall(body):
                j = i
                while j >= 0 and not LABEL.match(L[j]):
                    j -= 1
                readers[n].append((p, i, body.strip(), LABEL.match(L[j]).group(1) if j >= 0 else None))
    taken = set(syms)
    rules, skipped = [], []
    for n in sorted(tables):
        r = readers[n]
        if len(r) != 1 or not r[0][3]:
            skipped.append((n, len(r)))
            continue
        routine = CONT.sub("", r[0][3])
        new = routine + "_CaseTable"
        k = 2
        while new in taken:
            new = "%s_CaseTable%d" % (routine, k)
            k += 1
        taken.add(new)
        rules.append((n, new, r[0][2], r[0][3]))
    return rules, skipped, files


def main():
    for tree in ("v10", "v9", "v7"):
        rules, skipped, files = plan(tree)
        sed = os.path.join(REPO, "scripts/renaming/rename_case_tables_%s.sed" % tree)
        print("%s: %d case tables renamed, %d left (readers != 1): %s" % (
            tree, len(rules), len(skipped), ", ".join("%s(%d)" % s for s in skipped)))
        if not APPLY:
            for old, new, reader, rlab in rules:
                print("  %-44s -> %-48s  [%s: %s]" % (old, new, rlab, reader))
            continue
        lines = ["# rename_case_tables_%s.sed -- written by scripts/renaming/gen_case_table_names.py" % tree,
                 "# `X_Data` switch case-offset tables -> <routine that reads them>_CaseTable"]
        lines += ["s/\\b%s\\b/%s/g" % (old, new) for old, new, _, _ in sorted(rules, key=lambda x: -len(x[0]))]
        open(sed, "w").write("\n".join(lines) + "\n")
        targets = []
        for p in glob.glob(os.path.join(REPO, tree, "maincpu", "**", "*"), recursive=True):
            if p.endswith((".s", ".c", ".ld", ".h")):
                s = open(p, "rb").read().decode("latin-1")
                if any(re.search(r'\b%s\b' % old, s) for old, _, _, _ in rules):
                    targets.append(p)
        if targets:
            subprocess.run(["sed", "-i", "-f", sed] + targets, check=True)
        print("  sed applied to %d files" % len(targets))


if __name__ == "__main__":
    main()
