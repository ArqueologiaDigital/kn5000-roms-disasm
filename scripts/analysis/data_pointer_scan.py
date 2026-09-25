#!/usr/bin/env python3
r"""WHICH 32-BIT LITTLE-ENDIAN WORDS IN THE ROM POINT INTO [LO, HI)?  (maincpu v10/v9/v7)

QUESTION ANSWERED
    The data-to-data half of "who reads this object": pointer tables and
    records elsewhere that hold the address of something in the range.  Every
    byte offset of original_ROMs/kn5000_<v>_program.rom is tried (so misaligned
    and inside-instruction hits appear too -- a `ld xbc, imm32` operand is also
    reported here; data_readers_profile.py names those as instructions).  Each
    hit is shown with the nearest preceding ELF symbol of the word's own address.

RUN
    python3 scripts/analysis/data_pointer_scan.py --image v10 0xEE8C7E 0xEEAE08
"""
import argparse
import bisect
import os
import struct
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
B = 0xE00000


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", default="v10")
    ap.add_argument("lo")
    ap.add_argument("hi")
    a = ap.parse_args()
    lo, hi = int(a.lo, 16), int(a.hi, 16)
    d = open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % a.image), "rb").read()
    out = subprocess.run([NM, "--defined-only",
                          os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % a.image)],
                         capture_output=True, text=True).stdout
    syms = sorted((int(p[0], 16), p[2]) for p in (l.split() for l in out.splitlines())
                  if len(p) == 3 and B <= int(p[0], 16) < 0x1000000)
    addrs = [s[0] for s in syms]

    def owner(x):
        i = bisect.bisect_right(addrs, x) - 1
        return "%s+0x%x" % (syms[i][1], x - syms[i][0]) if i >= 0 else "?"
    hits = {}
    for i in range(len(d) - 3):
        t = struct.unpack_from("<I", d, i)[0]
        if lo <= t < hi:
            hits.setdefault(t, []).append(B + i)
    for t in sorted(hits):
        print("0x%06X %3d  %s" % (t, len(hits[t]), " ".join(
            "%06X(%s)" % (x, owner(x)) for x in hits[t][:6])))


if __name__ == "__main__":
    main()
