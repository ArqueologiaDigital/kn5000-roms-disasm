#!/usr/bin/env python3
"""respell_v7_pointer_run.py -- a v7 `.byte` run that holds u32 pointers, written as `.long Name` from v10's table.

QUESTION IT ANSWERS / WHAT IT DOES
  Some v7 tables are still `.byte` rows although v10 spells the same table as `.long Name` lines.  Example: v7
  InitializeHama_Data_8, the 85-word code-pointer table of Hama object 0x109, which v10 calls HamaObj_109_Data.
  scripts/lanes/sys/port_islands.py cannot align them: pointer values differ between the versions, so the byte
  diff finds no anchor.  This script takes the run by position instead.
  For word k of the v7 run (value v), the name is v10's word-k name if v7 defines that name at exactly v.
  Otherwise it is a v7 label at v (a local branch label is the last choice), else the number, which is
  reported.  The rows must be `.byte` and tile the run; a row that runs past the end keeps its tail as
  `.byte`.  With --label, the run's first row takes that label (v10's name).

RUN (repository root; built tree; census maps of this tree state: scripts/analysis/dispatch_table_census/build_maps.py)
  python3 scripts/tools/respell_v7_pointer_run.py --v7 InitializeHama_Data_8 --v10 HamaObj_109_Data --count 85 \
      [--label HamaObj_109_Data] [--apply]
"""
import argparse
import collections
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts/analysis/dispatch_table_census"))
ap = argparse.ArgumentParser()
ap.add_argument("--v7", required=True)
ap.add_argument("--v10", required=True)
ap.add_argument("--count", type=int, required=True)
ap.add_argument("--label")
ap.add_argument("--apply", action="store_true")
A = ap.parse_args()
sys.argv = sys.argv[:1]
import census  # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
LOCAL = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Prologue|Case|Done|Next|Exit)\d*$')


def syms(tree):
    out = subprocess.run([NM, "--defined-only", os.path.join(REPO, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % tree)],
                         capture_output=True, text=True, check=True).stdout
    at, by = collections.defaultdict(list), {}
    for line in out.splitlines():
        f = line.split()
        if len(f) == 3 and f[1] in "tT":
            at[int(f[0], 16)].append(f[2])
            by[f[2]] = int(f[0], 16)
    return at, by


def main():
    m7, m10 = census.load("v7"), census.load("v10")
    at7, by7 = syms("v7")
    a7, a10 = by7[A.v7], m10["byname"][A.v10]
    lines, numeric = [], 0
    for k in range(A.count):
        v = census.le(m7, a7 + 4 * k, 4)
        w = census.le(m10, a10 + 4 * k, 4)
        n10 = [n for n in m10["byname"] if m10["byname"][n] == w] if w else []
        nm = next((n for n in n10 if by7.get(n) == v), None)
        if nm is None and at7.get(v):
            nm = sorted(at7[v], key=lambda n: (bool(LOCAL.search(n)), len(n)))[0]
        if nm is None:
            nm = "0x%08x" % v
            numeric += 1 if v else 0
        lines.append("\t.long\t" + nm)
    end = a7 + 4 * A.count
    r = census.find(m7, a7)
    assert r[0] == a7, hex(a7)
    k0 = m7["los"].index(a7)
    rows = []
    k = k0
    while m7["rows"][k][0] < end:
        rows.append(m7["rows"][k])
        k += 1
    assert all(x[5] == ".byte" for x in rows), [x[5] for x in rows]
    assert rows[-1][3] - rows[0][3] + 1 == len(rows) and len({x[2] for x in rows}) == 1
    tail = []
    if rows[-1][1] > end:                           # the last row runs past the table: keep its tail
        raw = m7["raw"][end - m7["base"]:rows[-1][1] - m7["base"]]
        tail = ["\t.byte\t" + ", ".join("0x%02x" % b for b in raw)]
    print("v7 %s 0x%06X: %d words, %d left numeric; %d rows replaced%s"
          % (A.v7, a7, A.count, numeric, len(rows), ", tail kept" if tail else ""))
    for x in lines[:6]:
        print("  " + x.strip())
    if not A.apply:
        return
    p = os.path.join(REPO, "v7/maincpu", rows[0][2])
    L = open(p, "rb").read().decode("latin-1").split("\n")
    i = rows[0][3]
    first = L[i]
    mm = re.match(r'^([A-Za-z_]\w*):', first)
    head = []
    if mm:
        head = [(A.label or mm.group(1)) + ":"]
    elif A.label:
        head = [A.label + ":"]
    L[i:i + len(rows)] = head + lines + tail
    data = "\n".join(L).encode("latin-1")
    open(p + ".tmp", "wb").write(data)
    os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
