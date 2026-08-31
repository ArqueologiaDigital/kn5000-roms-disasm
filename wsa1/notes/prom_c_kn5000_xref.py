#!/usr/bin/env python3
"""Where does a prom_c address live in the KN5000 sub-CPU payload, and what is it called there?

WHY THIS EXISTS -- and why it is not `transplant_kn5000_labels.py`.

`scripts/analysis/kn5000_shared_runs.py` reports matches as a PAYLOAD FILE OFFSET.
`scripts/analysis/transplant_kn5000_labels.py` turned that offset into a sibling address
with `addr = 0x400 + offset`.  THAT FORMULA IS WRONG, and every one of the 8 rows in
notes/kn5000-label-transplant.md is wrong because of it.

The sibling's ROM file is NOT a contiguous image of its link map.  Its Makefile
(../kn5000-roms-disasm/Makefile:635-641) builds the ROM as

    rom = full[0:256] + full[60416:]           # full[] starts at address 0x0400

so the file has a 60,160-byte hole in it.  The correct mapping is therefore

    payload offset  <  0x100 :  address = 0x0400 + offset
    payload offset >= 0x100 :  address = 0xEF00 + offset

PROOF (run --selftest): payload offset 0x1A64 holds 00 00 01 00 02 00 04 00 08 00 ...
which is verbatim `EGEnv_ValueCurve_Simple` (../kn5000-roms-disasm/v142/subcpu/
subcpu_data_tables.s:1360), and the symbol table puts that label at 0x010964
= 0x1A64 + 0xEF00.  Under the old formula the same label would have to sit at
payload offset 0x10564, where the bytes are B8 B7 B6 B5 ... -- a different table
entirely.

WHAT IT DOES
  --map                 every maximal exact-match run >= MINRUN between prom_c and the
                        payload, printed with the constant delta that aligns them, so
                        contiguous transplantable blocks are visible as one delta.
  --at ADDR [N]         for one prom_c CPU address: the aligned payload offset, the
                        sibling address, and every sibling label inside the matched span.
  --labels LO HI        sibling labels in a sibling address range, with source file:line.
  --selftest            re-proves the offset mapping above from the bytes.

Run:  python3 notes/prom_c_kn5000_xref.py --map
      python3 notes/prom_c_kn5000_xref.py --at 0xFDD5AB
"""
import bisect
import os
import re
import subprocess
import sys

ROOT = "/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1"
SIB = "/home/fsanches/compartilhado/kn5000-roms-disasm"
PROM_C = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
PAYLOAD = os.path.join(SIB, "original_ROMs", "kn5000_subprogram_v142.rom")
SYMS = os.path.join(SIB, "symbols", "subcpu_symbols_reference.txt")
BASE_C = 0xF80000
MINRUN = 48
HOLE = 60160          # bytes the sibling Makefile's dd skips, = 60416 - 256


def poff_to_addr(poff):
    """KN5000 sub-CPU link address of a byte at payload-file offset `poff`."""
    return 0x0400 + poff if poff < 0x100 else 0xEF00 + poff


def addr_to_poff(addr):
    return addr - 0x0400 if addr < 0x0500 else addr - 0xEF00


def load_symbols():
    rows = []
    for ln in open(SYMS):
        ln = ln.strip()
        if not ln or ln.startswith("#"):
            continue
        name, a = ln.rsplit(" ", 1)
        rows.append((int(a, 16), name))
    rows.sort()
    return rows


def sym_source(name):
    """file:line where the sibling defines `name` (grep, so it is citable)."""
    try:
        out = subprocess.run(["grep", "-rn", f"^{name}:", f"{SIB}/v142/subcpu/"],
                             capture_output=True, text=True).stdout.strip().splitlines()
        if out:
            f, l, _ = out[0].split(":", 2)
            return f"{os.path.relpath(f, SIB)}:{l}"
    except Exception:
        pass
    return "?"


def index(buf, k):
    idx = {}
    for i in range(len(buf) - k + 1):
        idx.setdefault(buf[i:i + k], []).append(i)
    return idx


def runs(hay, payload, idx, minrun):
    out, i, n = [], 0, len(hay)
    while i <= n - minrun:
        key = hay[i:i + minrun]
        if key in idx:
            best = None
            for j in idx[key]:
                L = minrun
                while i + L < n and j + L < len(payload) and hay[i + L] == payload[j + L]:
                    L += 1
                # also grow backwards, so a run reports its true start
                B = 0
                while i - B - 1 >= 0 and j - B - 1 >= 0 and hay[i - B - 1] == payload[j - B - 1]:
                    B += 1
                if best is None or L + B > best[2]:
                    best = (i - B, j - B, L + B)
            out.append(best)
            i = best[0] + best[2]
        else:
            i += 1
    return out


def main():
    a = sys.argv[1:]
    syms = load_symbols()
    saddr = [s[0] for s in syms]

    if "--selftest" in a:
        p = open(PAYLOAD, "rb").read()
        want = bytes([0x00, 0x00, 0x01, 0x00, 0x02, 0x00, 0x04, 0x00, 0x08, 0x00])
        got = p[0x1A64:0x1A64 + 10]
        ok = got == want
        print(f"  payload[0x1A64:+10] = {got.hex(' ')}")
        print(f"  EGEnv_ValueCurve_Simple first 5 u16 = {want.hex(' ')}   match={ok}")
        print(f"  poff_to_addr(0x1A64) = 0x{poff_to_addr(0x1A64):06X}   "
              f"symbol table says 0x010964")
        print(f"  OLD (wrong) formula 0x400+0x1A64 = 0x{0x400 + 0x1A64:06X}")
        return 0 if ok and poff_to_addr(0x1A64) == 0x10964 else 1

    if "--labels" in a:
        i = a.index("--labels")
        lo, hi = int(a[i + 1], 16), int(a[i + 2], 16)
        for ad, n in syms:
            if lo <= ad <= hi:
                print(f"  {ad:06X}  {n}")
        return 0

    hay = open(PROM_C, "rb").read()
    payload = open(PAYLOAD, "rb").read()
    idx = index(payload, MINRUN)

    if "--at" in a:
        i = a.index("--at")
        addr = int(a[i + 1], 16)
        off = addr - BASE_C
        # find the run covering this offset
        for (o, p, L) in runs(hay, payload, idx, MINRUN):
            if o <= off < o + L:
                d = off - o
                pa = poff_to_addr(p + d)
                print(f"  prom_c 0x{addr:06X} is {d} B into a {L}-byte identical run")
                print(f"    prom_c 0x{BASE_C + o:06X}..0x{BASE_C + o + L - 1:06X}")
                print(f"    kn5000 0x{poff_to_addr(p):06X}..0x{poff_to_addr(p + L - 1):06X}"
                      f"   (payload 0x{p:05X})")
                print(f"    this address == kn5000 0x{pa:06X}")
                print("    labels inside the run:")
                for ad, n in syms:
                    if poff_to_addr(p) <= ad <= poff_to_addr(p + L - 1):
                        print(f"      {ad:06X} (prom_c 0x{BASE_C + o + (addr_to_poff(ad) - p):06X})"
                              f"  {n:44s} {sym_source(n)}")
                return 0
        print("  no run >= 48 B covers that address")
        return 1

    # --map (default)
    rr = runs(hay, payload, idx, MINRUN)
    rr = [r for r in rr if r[2] >= MINRUN]
    print(f"  prom_c vs KN5000 sub-CPU payload: {len(rr)} exact runs >= {MINRUN} B\n")
    print(f"  {'prom_c range':>25s}  {'len':>6s}  {'kn5000 range':>21s}  first label")
    total = 0
    for (o, p, L) in sorted(rr, key=lambda r: -r[2]):
        total += L
        lo, hi = poff_to_addr(p), poff_to_addr(p + L - 1)
        k = bisect.bisect_left(saddr, lo)
        lab = syms[k][1] if k < len(syms) and syms[k][0] <= hi else "-"
        print(f"  0x{BASE_C + o:06X}..0x{BASE_C + o + L - 1:06X}  {L:6d}  "
              f"0x{lo:06X}..0x{hi:06X}  {lab}")
    print(f"\n  total {total:,} B in runs >= {MINRUN} B")
    return 0


if __name__ == "__main__":
    sys.exit(main())
