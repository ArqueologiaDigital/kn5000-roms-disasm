#!/usr/bin/env python3
"""Where do the v7 label OFFSETS come from?  Compare them to v9/v10 spacing.

v7's source tree was seeded from v9's (scripts/build/v7_incbin_transplant.py:
"The v7 build reuses v9 source code ... the .incbin size must equal the assembled
size of the source range being replaced ... determined by the ELF address of the
NEXT label in the SAME SOURCE FILE").  If that is what placed these labels, the
GAP between two consecutive v7 labels equals the gap between the same two names
in v9 -- so the v7 address carries v9's instruction lengths, not v7's.
"""
import json, os, pickle, subprocess, sys, collections
ROOT = "/home/fsanches/compartilhado/kn5000-roms-disasm"; S = os.environ["SCRATCH"]
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
BASE = 0xE00000


def syms(elf):
    out = {}
    for ln in subprocess.run([NM, "--no-sort", os.path.join(ROOT, elf)],
                             capture_output=True, text=True).stdout.splitlines():
        p = ln.split()
        if len(p) == 3:
            try: a = int(p[0], 16)
            except ValueError: continue
            if BASE <= a < 0x1000000 and p[2] not in out: out[p[2]] = a
    return out


s7 = syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
s9 = syms("rebuilt_ROMs/kn5000_v9_program.llvm.elf")
s10 = syms("rebuilt_ROMs/kn5000_v10_program.llvm.elf")
cases = sorted(pickle.load(open(os.path.join(S, "cases.pkl"), "rb"))["cases"], key=lambda c: c["entry"])

same = diff = miss = 0
rows = []
for c in cases:
    names = [b[0] for b in c["blocks"] if b[0]]
    addrs = [b[1] for b in c["blocks"] if b[0]]
    for i in range(len(names) - 1):
        n0, n1 = names[i], names[i + 1]
        g7 = addrs[i + 1] - addrs[i]
        got = None
        for tag, sx in (("v9", s9), ("v10", s10)):
            if n0 in sx and n1 in sx:
                got = (tag, sx[n1] - sx[n0]); break
        if got is None:
            miss += 1; rows.append((c["entry"], n0, n1, g7, None, None)); continue
        rows.append((c["entry"], n0, n1, g7, got[0], got[1]))
        if got[1] == g7: same += 1
        else: diff += 1
print(f"consecutive label pairs inside the 33 refused ranges: {same+diff+miss}")
print(f"   v7 gap == sibling gap : {same}   <- the offset IS the sibling's, replayed")
print(f"   v7 gap != sibling gap : {diff}")
print(f"   name absent in v9/v10 : {miss}")
print()
for e, n0, n1, g7, tag, gx in rows:
    mark = "SAME" if gx == g7 else ("----" if gx is None else f"v7 {g7} vs {tag} {gx}")
    print(f"  0x{e:06X}  {n0[:38]:40} -> {n1[:38]:40} gap {g7:4}  {mark}")
