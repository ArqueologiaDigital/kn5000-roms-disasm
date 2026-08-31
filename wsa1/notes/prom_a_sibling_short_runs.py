#!/usr/bin/env python3
"""Small KN5000 sub-CPU routines hiding in prom_a -- the runs the transplant misses.

QUESTION IT ANSWERS
    "Which prom_a byte runs are identical to the KN5000 sub-CPU payload, START
     exactly at a KN5000 symbol, and END at or before that symbol's successor --
     i.e. which whole SMALL routines does prom_a share with the sibling?"

WHY IT EXISTS (audit round 1, finding F1)
    scripts/analysis/transplant_kn5000_labels.py has MIN_RUN = 48.  The runtime
    multiply at prom_a 0xFE68DD is 22 bytes long, so the transplant tool was
    silent about it -- and the routine header in prom_a/wsa1_prom_a.s turned that
    silence into a positive claim, "these 22 bytes have NO counterpart in the
    KN5000 sub-CPU".  They do: KN5000 0x3D8CA, `FP_MulAccum64`.  A searched
    negative is only as strong as the search, and a 48-byte floor cannot see a
    22-byte routine.

    This script drops the floor to 12 and adds the two conditions that make a
    short run mean something instead of being noise:
      * the run must begin exactly at a defined KN5000 symbol, and
      * the symbol's whole extent (up to the next symbol) must be inside the run,
    so what is reported is a COMPLETE sibling routine, not a fragment that
    happens to coincide.  A distinct-byte-count guard drops fill and padding.

    ⚠ Byte identity says the CODE is the same.  It does not say the surrounding
    machine is, and the byte gate is blind to names.  Output is proposals.

USAGE
    python3 notes/prom_a_sibling_short_runs.py               # prom_a
    python3 notes/prom_a_sibling_short_runs.py --min-run 16
    python3 notes/prom_a_sibling_short_runs.py --image c     # any WSA1 image
    python3 notes/prom_a_sibling_short_runs.py --selftest    # must find FP_MulAccum64
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIB = "/home/fsanches/compartilhado/kn5000-roms-disasm"
ELF = os.path.join(SIB, "rebuilt_ROMs", "kn5000_subprogram_v142.llvm.elf")
BIN = "/home/fsanches/compartilhado/llvm-project/build/bin"
NM, OBJCOPY = os.path.join(BIN, "llvm-nm"), os.path.join(BIN, "llvm-objcopy")
LINK_BASE = 0x0400           # addr = LINK_BASE + offset in the UNSPLICED image
MIN_RUN = 12
MIN_DISTINCT = 6             # a run of <6 distinct byte values is fill, not code

IMGS = {
    "a": (os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), 0xF80000),
    "b": (os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), 0xF00000),
    "c": (os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), 0xF80000),
    "d": (os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin"), 0x000000),
}


def kn5000_image():
    """The LINKED image, not original_ROMs/kn5000_subprogram_v142.rom -- that file
    is a SPLICE and using it is what produced the eight retracted transplants
    (see transplant_kn5000_labels.py's retraction notice)."""
    tmp = os.path.join(os.environ.get("TMPDIR", "/tmp"), "kn5000_v142_full.bin")
    subprocess.run([OBJCOPY, "-O", "binary", ELF, tmp], check=True)
    return open(tmp, "rb").read()


def kn5000_symbols():
    out = subprocess.run([NM, "--numeric-sort", "--defined-only", ELF],
                         capture_output=True, text=True).stdout
    syms = []
    for line in out.splitlines():
        p = line.split()
        if len(p) != 3:
            continue
        addr, typ, name = p
        if typ.lower() == 'a' or name.startswith('.L') or name.startswith('$'):
            continue
        syms.append((int(addr, 16), name))
    syms.sort()
    return syms


def runs_at_symbols(w, k, syms, min_run):
    """For every KN5000 symbol, does its whole extent appear verbatim in w?

    Anchored on the symbols rather than on every k-mer of the image: the
    question is about whole sibling ROUTINES, so the only alignment worth
    testing is the one that starts at a symbol.  That is also what makes the
    scan cheap -- an all-k-mer index spends all its time inside 0xFF fill.

    Yields (w_off, sym_addr, sym_name, extent, maximal_run_len).
    """
    symaddr = [s[0] for s in syms]
    for n, (kaddr, name) in enumerate(syms):
        koff = kaddr - LINK_BASE
        nxt = symaddr[n + 1] if n + 1 < len(symaddr) else LINK_BASE + len(k)
        extent = nxt - kaddr
        if extent < min_run or koff < 0 or koff + extent > len(k):
            continue
        probe = k[koff:koff + extent]
        if len(set(probe)) < MIN_DISTINCT:
            continue
        i = w.find(probe)
        while i >= 0:
            lo = 0
            while (i - lo - 1 >= 0 and koff - lo - 1 >= 0
                   and w[i - lo - 1] == k[koff - lo - 1]):
                lo += 1
            hi = 0
            while (i + extent + hi < len(w) and koff + extent + hi < len(k)
                   and w[i + extent + hi] == k[koff + extent + hi]):
                hi += 1
            yield (i, kaddr, name, extent, lo + extent + hi)
            i = w.find(probe, i + 1)


def main():
    args = sys.argv[1:]
    selftest = "--selftest" in args
    img = "a"
    min_run = MIN_RUN
    it = iter(args)
    for a in it:
        if a == "--image":
            img = next(it)
        elif a == "--min-run":
            min_run = int(next(it))
    path, base = IMGS[img]
    w = open(path, "rb").read()
    k = kn5000_image()
    syms = kn5000_symbols()
    symaddr = [s[0] for s in syms]
    byaddr = dict(syms)
    rows = []
    for woff, kaddr, name, extent, runlen in runs_at_symbols(w, k, syms, min_run):
        assert w[woff:woff + extent] == k[kaddr - LINK_BASE:kaddr - LINK_BASE + extent]
        rows.append((base + woff, extent, kaddr, runlen, name))
    rows.sort()

    if selftest:
        want = (0xFE68DD, 22, 0x3D8CA, 22, "FP_MulAccum64")
        hit = [r for r in rows if r[0] == 0xFE68DD]
        print("  looking for prom_a 0xFE68DD ...")
        for r in hit:
            print("    got  0x%06X  %d B  <- KN5000 0x%05X  maximal run %d B  %s" % r)
        okk = bool(hit) and hit[0] == want
        print("PASS" if okk else "FAIL")
        return 0 if okk else 1

    print("prom_%s: %d complete sibling routines of >= %d bytes appear verbatim"
          % (img, len(rows), min_run))
    print("  %-9s %6s  %-9s %8s  %s"
          % ("WSA1", "extent", "KN5000", "max run", "sibling symbol"))
    for waddr, extent, kaddr, runlen, name in rows:
        print("  0x%06X %6d  0x%05X %8d  %s" % (waddr, extent, kaddr, runlen, name))
    return 0


if __name__ == "__main__":
    sys.exit(main())
