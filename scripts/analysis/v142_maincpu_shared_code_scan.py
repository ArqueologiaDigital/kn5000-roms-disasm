#!/usr/bin/env python3
r"""v142_maincpu_shared_code_scan.py -- which sub-CPU v1.42 routines/tables are byte twins of main-CPU v10 ones?

QUESTION THIS ANSWERS
    The two CPUs run firmware built from partly shared sources (task scheduler, message
    queues, ring buffers, integer/FP helpers, DSP parameter data...).  Where a run of bytes in
    the sub-CPU payload also occurs verbatim in the main-CPU v10 ROM, the two copies are the
    same code/data, and their NAMES in the two disassemblies can be cross-checked -- a name
    that is well-founded on one side is evidence for the other, and a disagreement flags a
    misname.  This script lists every such twin run and the symbol it falls in on each side.

HOW
    Windows of 16 bytes (>= 6 distinct values) are taken every 4 bytes over the payload image
    0x00F000..0x03EF00 and searched in the v10 ROM; a hit is extended byte by byte.  Each run
    is reported with the enclosing symbol + offset on both sides, from llvm-nm of the two
    linked ELFs (build them first: `make gate` or `make all`).  ALIGNED means the run starts
    at the same offset from both enclosing symbols -- the strongest sign that the two symbols
    name the same routine or object.  Position-dependent bytes (absolute addresses, calr
    displacements to non-twin callees) end a run, so one routine may show several runs.

RUN
    python3 scripts/analysis/v142_maincpu_shared_code_scan.py            # all runs
    python3 scripts/analysis/v142_maincpu_shared_code_scan.py --min 24   # longer runs only
"""
import argparse
import bisect
import os
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
SUB = os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom")
MAIN = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
SUB_ELF = os.path.join(ROOT, "rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf")
MAIN_ELF = os.path.join(ROOT, "rebuilt_ROMs/kn5000_v10_program.llvm.elf")


def syms(elf):
    out = subprocess.run([NM, "-n", elf], capture_output=True, text=True, check=True).stdout
    rows = []
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] in "tT" and not p[2].startswith((".L", "__")):
            rows.append((int(p[0], 16), p[2]))
    return rows


def enclosing(rows, keys, a):
    i = bisect.bisect_right(keys, a) - 1
    return rows[i][1], a - rows[i][0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--min", type=int, default=16)
    a = ap.parse_args()
    s = open(SUB, "rb").read()
    m = open(MAIN, "rb").read()
    S, M = syms(SUB_ELF), syms(MAIN_ELF)
    sk, mk = [x for x, _ in S], [x for x, _ in M]
    off = lambda ad: ad - 0xEF00          # noqa: E731  payload address -> ROM offset (>= 0xF000)
    ad, runs = 0xF000, []
    while ad < 0x3EF00 - 16:
        w = s[off(ad):off(ad) + 16]
        if len(set(w)) >= 6:
            j = m.find(w)
            if j >= 0:
                n = 16
                while off(ad) + n < len(s) and s[off(ad):off(ad) + n + 1] == m[j:j + n + 1]:
                    n += 1
                runs.append((ad, n, j + 0xE00000))
                ad += n
                continue
        ad += 4
    print("%-8s %5s  %-44s %-8s %-44s %s" % ("sub", "len", "sub symbol+off", "main", "main symbol+off", "aligned"))
    for ad, n, mj in runs:
        if n < a.min:
            continue
        sn, so = enclosing(S, sk, ad)
        mn, mo = enclosing(M, mk, mj)
        print("%06X %5d  %-44s %06X %-44s %s" % (ad, n, "%s+%d" % (sn, so), mj, "%s+%d" % (mn, mo),
                                                "ALIGNED" if so == mo else ""))
    print("\n%d runs >= %d bytes, %d bytes in all" % (sum(1 for r in runs if r[1] >= a.min), a.min,
                                                       sum(r[1] for r in runs if r[1] >= a.min)))


if __name__ == "__main__":
    main()
