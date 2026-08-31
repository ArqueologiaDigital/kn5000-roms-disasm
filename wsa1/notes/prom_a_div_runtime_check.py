#!/usr/bin/env python3
"""Where exactly do prom_a's 64-bit divide runtime and the KN5000 sub-CPU's agree,
and which KN5000 symbol name belongs at which prom_a address?

QUESTION IT ANSWERS.  Round-2 audit F4 and F5 are both address claims about the
region 0xFE68F3-0xFE69BE:

  F5  the header says "the two images DIVERGE at 0xFE699B" two paragraphs after
      saying "0xFE68F2-0xFE699B is 170 bytes byte-identical".  Both cannot hold.
  F4  the tree writes `FP_UnsignedDiv_ShiftLoop` at 0xFE69AB, but llvm-nm puts
      that KN5000 symbol at 0x3DCBB, which under this block's own anchor is
      prom_a 0xFE699A -- 17 bytes earlier, where the tree instead writes
      `FP_UnsignedDiv_ScaleLoop` with no note that it renamed anything.

It reads both ROMs, so nothing here is quoted from a header.

MAPPING.  The KN5000 sub-CPU payload .rom is a splice: the first 0x100 bytes of
the image, then everything from image offset 0xEC00 on, so for rom offset >=
0x100 the sub-CPU ADDRESS is 0xEF00 + offset (prom_a/kn5000_run_offsets.py).
prom_a is a straight 512 KiB image based at 0xF80000.

    python3 notes/prom_a_div_runtime_check.py
    python3 notes/prom_a_div_runtime_check.py --selftest   # negative controls

Exits non-zero if any check fails.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SIB = os.path.expanduser("~/compartilhado/kn5000-roms-disasm")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")

A_ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
A_BASE = 0xF80000
K_ROM = os.path.join(SIB, "original_ROMs", "kn5000_subprogram_v142.rom")
K_ELF = os.path.join(SIB, "rebuilt_ROMs", "kn5000_subprogram_v142.llvm.elf")

# the anchor this block's header states: prom_a 0xFE68F3 <-> KN5000 0x3DC14
ANCHOR_A = 0xFE68F3
ANCHOR_K = 0x3DC14

fails = []
CHECKS = [0]


def check(name, got, want):
    CHECKS[0] += 1
    ok = got == want
    print(("  ok   " if ok else "  FAIL ") + name + ": " + repr(got) +
          ("" if ok else "   expected " + repr(want)))
    if not ok:
        fails.append(name)
    return ok


def a_bytes():
    with open(A_ROM, "rb") as f:
        return f.read()


def k_bytes():
    with open(K_ROM, "rb") as f:
        return f.read()


def k_off(addr):
    """sub-CPU address -> payload .rom file offset."""
    if addr < 0x500:
        return addr - 0x400
    return addr - 0xEF00


def k_syms():
    out = subprocess.run([NM, K_ELF], capture_output=True, text=True).stdout
    d = {}
    for line in out.splitlines():
        p = line.split()
        if len(p) == 3:
            d[p[2]] = int(p[0], 16)
    return d


def main(argv):
    selftest = "--selftest" in argv
    A = a_bytes()
    K = k_bytes()
    S = k_syms()

    print("F5 -- where the identical run really ends")
    # maximal forward run from the anchor pair, and maximal backward run
    fwd = 0
    while A[ANCHOR_A - A_BASE + fwd] == K[k_off(ANCHOR_K) + fwd]:
        fwd += 1
    back = 0
    while A[ANCHOR_A - A_BASE - back - 1] == K[k_off(ANCHOR_K) - back - 1]:
        back += 1
    check("maximal forward run from the anchor (bytes)", fwd, 169)
    check("maximal backward run from the anchor (bytes)", back, 1)
    run_lo = ANCHOR_A - back
    run_hi = ANCHOR_A + fwd - 1
    check("run low address", hex(run_lo), hex(0xFE68F2))
    check("LAST IDENTICAL byte", hex(run_hi), hex(0xFE699B))
    check("run length", run_hi - run_lo + 1, 170)
    first_diff = run_hi + 1
    check("FIRST DIFFERING byte", hex(first_diff), hex(0xFE699C))
    check("prom_a byte there", hex(A[first_diff - A_BASE]), hex(0x66))
    check("KN5000 byte there",
          hex(K[k_off(ANCHOR_K) + (first_diff - ANCHOR_A)]), hex(0x67))

    print("\nF4 -- which prom_a address each KN5000 symbol maps to")
    for sym, want_a in [("FP_UnsignedDiv_General", 0xFE6998),
                        ("FP_UnsignedDiv_ShiftLoop", 0xFE699A)]:
        k = S[sym]
        mapped = ANCHOR_A + (k - ANCHOR_K)
        check("%s KN5000 0x%05X -> prom_a" % (sym, k), hex(mapped), hex(want_a))
    check("0xFE699A is INSIDE the identical run", run_lo <= 0xFE699A <= run_hi, True)
    check("0xFE69AB is OUTSIDE it", 0xFE69AB > run_hi, True)
    check("gap between the two addresses (bytes)", 0xFE69AB - 0xFE699A, 17)

    print("\nA SECOND identical run, in the diverged tail")
    # prom_a 0xFE69A9..0xFE69BE vs KN5000 FP_UnsignedDiv_Subtract..end
    k = S["FP_UnsignedDiv_Subtract"]
    check("KN5000 FP_UnsignedDiv_Subtract", hex(k), hex(0x3DCD0))
    n = 0
    while (A[0xFE69A9 - A_BASE + n] == K[k_off(k) + n]) and n < 0x40:
        n += 1
    check("prom_a 0xFE69A9 == KN5000 0x3DCD0 for n bytes", n, 22)
    check("which reaches the routine's last byte", hex(0xFE69A9 + n - 1), hex(0xFE69BE))
    b = 0
    while A[0xFE69A9 - A_BASE - b - 1] == K[k_off(k) - b - 1]:
        b += 1
    check("...and how far back it extends before a byte differs", b, 1)
    check("so the SECOND identical run is", (hex(0xFE69A9 - b), hex(0xFE69BE),
                                             0xFE69BE - (0xFE69A9 - b) + 1),
          ('0xfe69a8', '0xfe69be', 23))
    # the three-instruction tail the KN5000 has and prom_a does not
    check("KN5000 ShiftLoopDone -> Subtract span (bytes)",
          S["FP_UnsignedDiv_Subtract"] - S["FP_UnsignedDiv_ShiftLoopDone"], 3)
    check("prom_a's equivalent span (0xFE69A6..0xFE69A9)", 0xFE69A9 - 0xFE69A6, 3)

    print("\nSHAPE of the two scaling loops (why the bytes differ at all)")
    check("prom_a 0xFE699C is `jr z,`", hex(A[0xFE699C - A_BASE]), hex(0x66))
    check("KN5000 0x3DCBD is `jr c,`",
          hex(K[k_off(0x3DCBD)]), hex(0x67))
    check("prom_a 0xFE69A6 is `sra xbc,1` (e9 ed 01)",
          A[0xFE69A6 - A_BASE:0xFE69A9 - A_BASE].hex(), "e9ed01")
    check("KN5000 ShiftLoopDone is `srl xbc,1` (e9 ef 01)",
          K[k_off(S["FP_UnsignedDiv_ShiftLoopDone"]):
            k_off(S["FP_UnsignedDiv_ShiftLoopDone"]) + 3].hex(), "e9ef01")

    if selftest:
        print("\nNEGATIVE CONTROLS")
        # the claim the header used to make must FAIL against the bytes
        bad = A[0xFE699B - A_BASE] != K[k_off(ANCHOR_K) + (0xFE699B - ANCHOR_A)]
        check("`diverge at 0xFE699B` is refuted (byte there is EQUAL)", bad, False)
        # one byte late on the anchor must not reproduce the run
        n = 0
        while A[ANCHOR_A - A_BASE + 1 + n] == K[k_off(ANCHOR_K) + n]:
            n += 1
        check("anchor shifted +1 gives a run shorter than 170", n < 170, True)
        # the symbol really is not at 0xFE69AB under any of the two mappings
        k = S["FP_UnsignedDiv_ShiftLoop"]
        check("0x400+off mapping also does not give 0xFE69AB",
              ANCHOR_A + (k - ANCHOR_K) != 0xFE69AB, True)

    print("\n%d checks, %d failed" % (CHECKS[0], len(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
