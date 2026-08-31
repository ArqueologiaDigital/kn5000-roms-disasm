#!/usr/bin/env python3
"""Does a KN5000 payload FILE OFFSET equal its sub-CPU ADDRESS minus 0x400?

QUESTION IT ANSWERS, and why it matters: notes/kn5000-label-transplant.md maps a
byte run found at payload file offset `poff` onto the KN5000 label whose ADDRESS
falls in [0x400+poff, 0x400+poff+len).  That is the mapping
scripts/analysis/transplant_kn5000_labels.py uses (PAYLOAD_BASE = 0x400).  This
script tests it against the payload's own build recipe and against real symbols.

WHAT THE RECIPE SAYS.  ../kn5000-roms-disasm/Makefile:635-640 does not objcopy
the payload straight out:

    llvm-objcopy -O binary <elf> $@.full
    dd if=$@.full of=$@.part_a bs=1 count=256
    dd if=$@.full of=$@.part_b bs=1 skip=60416
    cat $@.part_a $@.part_b > $@

and the ELF's .text is at address 0x400 with file offset 0x400
(llvm-readelf: [1] .text PROGBITS 00000400 000400 03eb00).  So the .rom holds the
first 0x100 bytes of the image, then a 0xEB00-byte HOLE, then the rest:

    rom offset < 0x100 :  address = 0x400  + offset
    rom offset >= 0x100:  address = 0xEF00 + offset

The second line is the one the transplant script does not know about, and it is
where all but 256 bytes of the payload live.

    python3 prom_a/kn5000_run_offsets.py

Prints, for a set of named symbols, the bytes the two candidate mappings land on
and which one reproduces the disassembly the sibling source shows.  Exits
non-zero if the 0xEF00 mapping ever fails.
"""
import os
import subprocess
import sys

SIB = os.path.expanduser("~/compartilhado/kn5000-roms-disasm")
ROM = os.path.join(SIB, "original_ROMs", "kn5000_subprogram_v142.rom")
ELF = os.path.join(SIB, "rebuilt_ROMs", "kn5000_subprogram_v142.llvm.elf")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")

# (symbol, the first instruction the sibling source shows at it, in llvm-mc syntax)
PROBES = [
    ("Int_SignedDiv",      "ldb e, 0x0"),
    ("FP_UnsignedDiv",     "cp XBC,0x00000001"),
    ("DSP_EffParam_Copy_V4", "extz wa"),
    ("DSP_EffParam_Copy_V5", "extz wa"),
]


def encode(text):
    r = subprocess.run([MC, "--triple=tlcs900", "--show-encoding"],
                       input="\t.text\n\t" + text + "\n", capture_output=True, text=True)
    import re
    m = re.search(r"[;#] encoding: \[([^\]]+)\]", r.stdout)
    return bytes(int(h, 16) for h in m.group(1).split(",")) if m else None


def symbols():
    out = subprocess.run([NM, "--numeric-sort", "--defined-only", ELF],
                         capture_output=True, text=True).stdout
    d = {}
    for line in out.splitlines():
        p = line.split()
        if len(p) == 3 and p[1].lower() != "a":
            d[p[2]] = int(p[0], 16)
    return d


def proposals(min_run=48):
    """Re-run the transplant with the corrected mapping and print the proposals."""
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(
        os.path.abspath(__file__))), "scripts", "analysis"))
    import kn5000_shared_runs as ksr
    ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    payload = open(ksr.PAYLOAD, "rb").read()
    idx = ksr.index(payload, 16)
    syms = sorted((v, k) for k, v in symbols().items())
    rows = []
    for name, fn, base in ksr.IMAGES:
        buf = open(os.path.join(ROOT, "original_ROMs", fn), "rb").read()
        for off, poff, L in ksr.find_runs(buf, idx, 16):
            if L < min_run or ksr.low_entropy(buf[off:off + L]):
                continue
            # CORRECTED: address = 0xEF00 + offset above the first 256 bytes
            delta = 0x400 if poff < 0x100 else 0xEF00
            lo, hi = delta + poff, delta + poff + L
            for addr, sym in syms:
                if lo <= addr < hi:
                    rows.append((name, base + off + (addr - lo), sym, L, addr))
    rows.sort(key=lambda r: (-r[3], r[1]))
    print("| WSA1 image | WSA1 addr | KN5000 name | run len | KN5000 subcpu addr |")
    print("|---|---|---|---:|---|")
    for img, waddr, sym, L, kaddr in rows:
        print("| %s | `0x%06X` | `%s` | %d | `0x%05X` |" % (img, waddr, sym, L, kaddr))
    print("\n%d proposals" % len(rows))
    return 0


def main():
    if "--proposals" in sys.argv:
        return proposals()
    rom = open(ROM, "rb").read()
    syms = symbols()
    bad = 0
    print("symbol                     addr     -0x400 lands on   -0xEF00 lands on   expected")
    for name, first in PROBES:
        if name not in syms:
            print("  %-24s MISSING FROM THE ELF" % name)
            bad += 1
            continue
        a = syms[name]
        want = encode(first)
        n = len(want)
        old = rom[a - 0x400:a - 0x400 + n]
        new = rom[a - 0xEF00:a - 0xEF00 + n]
        print("  %-24s 0x%05X  %-18s %-18s %s%s" %
              (name, a, old.hex(" "), new.hex(" "), want.hex(" "),
               "" if new == want else "   <-- 0xEF00 MAPPING FAILED"))
        if new != want:
            bad += 1
        if old == want:
            print("      !! the 0x400 mapping ALSO matched here -- the test is inconclusive")
            bad += 1
    if bad:
        print("\nFAIL")
        return 1
    print("\nPASS: payload address = rom offset + 0xEF00 (above the first 256 bytes);\n"
          "      the 0x400 mapping is wrong by 0xEB00.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
