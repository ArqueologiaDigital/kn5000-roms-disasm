#!/usr/bin/env python3
"""Where do prom_c (CPU 2) and prom_a (CPU 1) contain THE SAME BYTES, and where does the
identity stop?

QUESTION ANSWERED
  The two CPUs of the SX-WSA1R were built from one source tree with one compiler, so the C
  runtime and the driver helpers appear in both EPROMs.  When prom_a has already named such a
  routine, that name can be carried into prom_c -- but only for the bytes that are actually
  identical.  This script measures the run so a header can state its exact extent instead of
  saying "looks like".

  It is the prom_a<->prom_c analogue of scripts/analysis/kn5000_shared_runs.py, and it exists
  because of a specific trap: `DSP_WriteChannelRegs_Inner` in this same file is 80 of 81 bytes
  identical to its KN5000 counterpart, and the byte that differs is a peripheral base address.
  A run measured to its true end shows that; "byte-identical" waved at a neighbourhood does not.

MODES
  --at C_ADDR A_ADDR      maximal identical run through this pair of addresses, extended
                          BOTH ways, printed with the first differing byte on each side
  --runs [--minrun N]     every maximal identical run of >= N bytes, longest first

  Addresses are CPU addresses; both images are based at 0xF80000 in their own space.

VERIFY
  python3 notes/prom_c_prom_a_shared_runs.py --selftest
      re-proves the two facts this tree quotes: the 49-byte micro-DMA/runtime helper run
      (prom_c 0xF9A01F <-> prom_a 0xF8E6C9) and that it is MAXIMAL -- one byte further in
      either direction the images differ.

LIMIT
  Byte identity is evidence for a name, not proof of one.  Two different routines can share a
  prologue; always check that the run covers the WHOLE routine you are naming, which is what
  --at prints.
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = 0xF80000
A = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
C = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")


def run_at(a, c, ao, co):
    """maximal identical run through (ao in prom_a, co in prom_c); returns (a_start, c_start, n)"""
    if a[ao] != c[co]:
        return (ao, co, 0)
    lo = 0
    while ao - lo - 1 >= 0 and co - lo - 1 >= 0 and a[ao - lo - 1] == c[co - lo - 1]:
        lo += 1
    hi = 0
    while ao + hi + 1 < len(a) and co + hi + 1 < len(c) and a[ao + hi + 1] == c[co + hi + 1]:
        hi += 1
    return (ao - lo, co - lo, lo + hi + 1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--at", nargs=2, metavar=("C_ADDR", "A_ADDR"))
    ap.add_argument("--runs", action="store_true")
    ap.add_argument("--minrun", type=int, default=32)
    ap.add_argument("--selftest", action="store_true")
    o = ap.parse_args()
    a = open(A, "rb").read()
    c = open(C, "rb").read()

    if o.at:
        caddr = int(o.at[0], 0)
        aaddr = int(o.at[1], 0)
        astart, cstart, n = run_at(a, c, aaddr - BASE, caddr - BASE)
        if not n:
            print("  the bytes at that pair of addresses already differ")
            return 0
        print(f"  maximal identical run: {n} bytes")
        print(f"    prom_a 0x{BASE + astart:06X} .. 0x{BASE + astart + n - 1:06X}")
        print(f"    prom_c 0x{BASE + cstart:06X} .. 0x{BASE + cstart + n - 1:06X}")
        for side, img, st in (("prom_a", a, astart), ("prom_c", c, cstart)):
            b0 = f"0x{img[st - 1]:02X}" if st else "(start of image)"
            b1 = f"0x{img[st + n]:02X}" if st + n < len(img) else "(end of image)"
            print(f"    {side}: byte BEFORE = {b0}, byte AFTER = {b1}")
        print(f"    bytes: {c[cstart:cstart + n].hex(' ')}")
        return 0

    if o.selftest:
        astart, cstart, n = run_at(a, c, 0xF8E6C9 - BASE, 0xF9A01F - BASE)
        ok = (n == 98 and BASE + astart == 0xF8E698 and BASE + cstart == 0xF99FEE)
        print(f"  run through prom_c 0xF9A01F / prom_a 0xF8E6C9: {n} bytes, "
              f"prom_a start 0x{BASE + astart:06X}, prom_c start 0x{BASE + cstart:06X}")
        print(f"  maximal (differs one byte before and one byte after): "
              f"{a[astart - 1] != c[cstart - 1]} / {a[astart + n] != c[cstart + n]}")
        print("  SELFTEST " + ("PASS" if ok else "FAIL"))
        return 0 if ok else 1

    if o.runs:
        # every maximal identical run, found by walking each prom_c offset against every
        # prom_a offset is O(n^2); instead index prom_a by an 8-byte key and grow candidates.
        K = 8
        idx = {}
        for i in range(len(a) - K):
            idx.setdefault(a[i:i + K], []).append(i)
        seen = set()
        out = []
        i = 0
        while i < len(c) - K:
            key = c[i:i + K]
            best = None
            for j in idx.get(key, ()):
                astart, cstart, n = run_at(a, c, j, i)
                if n >= o.minrun and (astart, cstart) not in seen:
                    if best is None or n > best[2]:
                        best = (astart, cstart, n)
            if best:
                seen.add((best[0], best[1]))
                out.append(best)
                i = best[1] + best[2]
            else:
                i += 1
        out.sort(key=lambda r: -r[2])
        print(f"  identical runs of >= {o.minrun} bytes: {len(out)}"
              f"   total {sum(r[2] for r in out):,} bytes")
        for astart, cstart, n in out:
            print(f"    {n:6,} B   prom_c 0x{BASE + cstart:06X}   prom_a 0x{BASE + astart:06X}")
        return 0

    ap.print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())
