#!/usr/bin/env python3
"""Which KN5000 sub-CPU routine names apply to WSA1 addresses, by byte identity?

28,916 bytes of WSA1 prom_c are byte-identical to the KN5000 sub-CPU payload
(kn5000_shared_runs.py; shuffle null 0 B), and ../kn5000-roms-disasm has 4,790 named
labels for it. This maps them across so identical code carries the same name in both trees.

⚠⚠ RETRACTION, 2026-08-24. The first version of this script emitted EIGHT proposals and
ALL EIGHT NAMED THE WRONG OBJECT. It matched against original_ROMs/kn5000_subprogram_v142.rom
and then converted offsets with `addr = 0x400 + offset`. That file is NOT the linked image:
the sibling Makefile (lines 635-641) builds it as `full[0:256] + full[60416:]`, so every
offset past the first 256 bytes was short by 60160 = 0xEB00. `EGEnv_ValueCurve_Simple`
actually landed inside the keybed TOUCH curve. The names were thematically plausible, which
is exactly why nothing caught them by eye.

TWO CHANGES SO IT CANNOT RECUR:

  1. The splice is removed from the pipeline. This script now matches against the ELF's
     own unspliced binary, where `addr = 0x400 + offset` holds at every offset. There is no
     correction constant to get wrong, because there is no correction.

  2. EVERY emitted proposal is byte-verified. For each one the script compares the bytes at
     the KN5000 address against the bytes at the WSA1 address and DROPS any that differ.
     The original failure would have produced zero output instead of eight wrong names.

Still true, and still the reason this file is proposals and not renames: byte identity
establishes the CODE is the same, not that the surrounding machine is. And the byte gate is
blind to names -- a wrong name here would never fail a build.

Run:  python3 scripts/analysis/transplant_kn5000_labels.py [--min-run N] [--out FILE]
      python3 scripts/analysis/transplant_kn5000_labels.py --selftest
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SIB = "/home/fsanches/compartilhado/kn5000-roms-disasm"
ELF = os.path.join(SIB, "rebuilt_ROMs", "kn5000_subprogram_v142.llvm.elf")
BIN = "/home/fsanches/compartilhado/llvm-project/build/bin"
NM, OBJCOPY = os.path.join(BIN, "llvm-nm"), os.path.join(BIN, "llvm-objcopy")
LINK_BASE = 0x0400
MIN_RUN = 48
SPLICED_ROM = os.path.join(SIB, "original_ROMs", "kn5000_subprogram_v142.rom")


def full_image():
    """The LINKED image, not the spliced ROM. addr = LINK_BASE + offset holds throughout."""
    tmp = os.path.join("/tmp", "kn5000_v142_full.bin")
    subprocess.run([OBJCOPY, "-O", "binary", ELF, tmp], check=True)
    return open(tmp, "rb").read()


def selftest():
    """Prove the spliced ROM is NOT the linked image, so the old mapping was wrong."""
    full, rom = full_image(), open(SPLICED_ROM, "rb").read()
    ok = full[:256] == rom[:256]
    shift_ok = full[60416:60416 + 64] == rom[256:256 + 64]
    naive_ok = full[256:256 + 64] == rom[256:256 + 64]
    print(f"  full[0:256]      == rom[0:256]        : {ok}")
    print(f"  full[60416:+64]  == rom[256:+64]      : {shift_ok}   <- the real relation")
    print(f"  full[256:+64]    == rom[256:+64]      : {naive_ok}   <- what the old code assumed")
    print(f"  correction the old code omitted: {60416 - 256} = 0x{60416 - 256:X}")
    return 0 if (ok and shift_ok and not naive_ok) else 1


def payload_symbols():
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
    return sorted(syms)


def main():
    if "--selftest" in sys.argv:
        return selftest()
    min_run = int(sys.argv[sys.argv.index("--min-run") + 1]) if "--min-run" in sys.argv else MIN_RUN
    out_path = (sys.argv[sys.argv.index("--out") + 1] if "--out" in sys.argv
                else os.path.join(ROOT, "notes", "kn5000-label-transplant-generated.md"))

    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import kn5000_shared_runs as ksr

    full = full_image()
    idx = ksr.index(full, 16)
    syms = payload_symbols()

    rows, dropped = [], 0
    for name, fn, base in ksr.IMAGES:
        buf = open(os.path.join(ROOT, "original_ROMs", fn), "rb").read()
        for off, poff, L in ksr.find_runs(buf, idx, 16):
            if L < min_run or ksr.low_entropy(buf[off:off + L]):
                continue
            lo, hi = LINK_BASE + poff, LINK_BASE + poff + L
            for addr, sym in syms:
                if lo <= addr < hi:
                    d = addr - lo
                    n = min(32, L - d)
                    # GUARD: the bytes must actually agree, or the proposal is dropped.
                    if full[poff + d:poff + d + n] != buf[off + d:off + d + n]:
                        dropped += 1
                        continue
                    rows.append((name, base + off + d, sym, L, addr))

    rows.sort(key=lambda r: (-r[3], r[1]))
    with open(out_path, "w") as f:
        f.write("# KN5000 sub-CPU labels that transplant onto WSA1 addresses\n\n")
        f.write("GENERATED by `scripts/analysis/transplant_kn5000_labels.py` -- do not hand-edit;\n")
        f.write("it is overwritten on every run. Read that script's docstring, including the\n")
        f.write("2026-08-24 retraction, before applying any of these.\n\n")
        f.write(f"Every row below was byte-verified at emission. {dropped} candidate(s) were dropped\n")
        f.write(f"because their bytes did not agree. Runs shorter than {min_run} bytes are withheld.\n\n")
        f.write(f"**{len(rows)} proposals**, longest-backing-run first.\n\n")
        f.write("| WSA1 image | WSA1 addr | proposed name | run len | KN5000 subcpu addr |\n|---|---|---|---:|---|\n")
        for img, waddr, sym, L, kaddr in rows:
            f.write(f"| {img} | `0x{waddr:06X}` | `{sym}` | {L} | `0x{kaddr:04X}` |\n")
    print(f"wrote {out_path}: {len(rows)} proposals, {dropped} dropped by the byte check")
    for img, waddr, sym, L, kaddr in rows[:20]:
        print(f"  {img:7s} 0x{waddr:06X}  {sym:<46s} run={L:5d}  kn5000=0x{kaddr:04X}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
