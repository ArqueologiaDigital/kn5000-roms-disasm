#!/usr/bin/env python3
"""kn5000_source_coverage.py -- the KN5000 analogue of kn7000's coverage_score.py.

QUESTION ANSWERED: for each KN5000 ROM, how many bytes enter the byte-exact build
as REAL source (assembly, typed data, or C compiled by clang -target tlcs900) and
how many are handed back verbatim through `.incbin`?

Byte-match is 100.00% on all 15 sections and always will be -- it says nothing
about understanding. This does.

Three classes of `.incbin` byte are distinguished, because they are NOT equal:

  * generated/ + a Makefile clang rule  -> HONEST (C source recompiled byte-exact)
  * generated/ written by scripts/build/extract_v7_bins.py -> ROM SLICE at build
    time. The v7 tree rebuilds byte-perfectly partly because the build copies the
    v7 ROM into its own "source". Measured separately.
  * a committed .bin with no rule       -> raw blob (documented or not)

Run from the kn5000-roms-disasm checkout:
    python3 kn5000_source_coverage.py
"""
import glob
import os
import re
import subprocess
import sys

REPO = sys.argv[1] if len(sys.argv) > 1 else "/home/fsanches/compartilhado/kn5000-roms-disasm"
os.chdir(REPO)

ROMS = {
    "v10/maincpu": ("maincpu v10", 2097152),
    "v9/maincpu": ("maincpu v9", 2097152),
    "v7/maincpu": ("maincpu v7", 2097152),
    "v142/subcpu": ("subcpu payload v142", 196608),
    "subcpu/boot": ("subcpu boot (IC30)", 131072),
    "table_data": ("table data", 2097152),
    "custom_data": ("custom data (IC19)", 1048576),
    "hdae5000": ("HD-AE5000", 524288),
}
INC = re.compile(r'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*(?:,\s*([0-9a-fA-Fx]+))?)?')

print(f"{'component':22s} {'ROM':>9s} {'incbin':>9s} {'of which C':>10s} {'source':>9s}  source%")
for root, (label, total) in ROMS.items():
    inc = gen = 0
    for f in glob.glob(root + "/**/*.s", recursive=True):
        txt = open(f, encoding="latin-1").read()
        for path, off, ln in INC.findall(txt):
            real = next((c for c in (os.path.join(os.path.dirname(f), path),
                                     os.path.join(root, path), path) if os.path.exists(c)), None)
            if not real:
                continue
            fsz = os.path.getsize(real)
            size = int(ln, 0) if ln else (fsz - int(off, 0) if off else fsz)
            inc += size
            if "generated/" in path:
                gen += size
    print(f"{label:22s} {total:9,d} {inc:9,d} {gen:10,d} {total - inc:9,d}  "
          f"{100 * (total - inc) / total:5.1f}%")

# --- the v7 circularity, measured ------------------------------------------
# extract_v7_bins.py stage 1 overwrites a C-compiled bin with a raw slice of the
# v7 ROM whenever the block at the v9 label address is >50% similar.
#
# ⚠ FIXED 2026-09-01 (lane v7): this used to ignore the `.incbin "path", off, len`
# form and take os.path.getsize(v9p) -- the WHOLE shared blob -- as the size of
# EVERY labelled slice into it. v9/maincpu/ui_widgets/technichord_string_data.s
# alone .incbin's naka_technichord_strings.bin (111,742 B) 842 TIMES, each a few
# bytes of it at a different offset; the old code counted 842 * 111,742 B for
# that one file. That is how a 2,097,152-byte ROM produced a "31,758,150 B"
# result: the total was never bounded by the ROM size because it wasn't
# measuring the ROM, it was measuring (occurrences * shared-file-size). Now it
# reads the same off/len the assembler would and slices both ROMs by LEN, not
# by the whole file -- see scripts/analysis/README-v7-no-source-bytes.md for
# the standalone, ROM-size-bounded replacement (v7_no_source_bytes.py), which
# is the one to trust for the headline number.
LLVM_NM = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm"
ROM_BASE = 0xE00000
INC2 = re.compile(rb'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*(?:,\s*([0-9a-fA-Fx]+))?)?')
try:
    v7rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()

    def syms(p):
        d = {}
        for line in subprocess.run([LLVM_NM, "--no-sort", p], capture_output=True,
                                   text=True).stdout.split("\n"):
            parts = line.split()
            if len(parts) >= 3:
                try:
                    d[parts[2]] = int(parts[0], 16)
                except ValueError:
                    pass
        return d

    v7s = syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
    v9s = syms("rebuilt_ROMs/kn5000_v9_program.llvm.elf")
    incmap = {}
    for fp in sorted(glob.glob("v9/maincpu/**/*.s", recursive=True)):
        last = None
        for lineno, line in enumerate(open(fp, "rb").readlines()):
            s = line.strip()
            m = re.match(rb"^(\w+):", s)
            if m and not s.startswith(b".") and not s.startswith(b";"):
                last = m.group(1).decode("latin-1")
            mm = INC2.search(s) if b".incbin" in s and b"generated/" in s else None
            if mm:
                rel = mm.group(1).decode("latin-1")
                off = int(mm.group(2), 0) if mm.group(2) else 0
                ln = int(mm.group(3), 0) if mm.group(3) else None
                a = v7s.get(last, v9s.get(last)) if last else None
                if a is not None:
                    # A label on THIS line names byte 0 of the slice, so its
                    # ROM address does not move with `off`. A label on an
                    # EARLIER line (last) still refers to the start of ITS OWN
                    # slice -- but successive .incbin lines under one label
                    # each describe a DIFFERENT sub-region, so key on the
                    # (label, file-line) pair, not (label, path), or repeats
                    # under the same label collide again.
                    incmap[(last, fp, lineno)] = (a, "v9/maincpu/" + rel, off, ln)
    ov = ovb = keep = keepb = differ = differb = 0
    for (lab, _, _), (addr, v9p, off, ln) in incmap.items():
        if not os.path.exists(v9p):
            continue
        fsz = os.path.getsize(v9p)
        n = ln if ln is not None else (fsz - off)
        if n <= 0:
            continue
        d7 = v7rom[addr - ROM_BASE: addr - ROM_BASE + n]
        with open(v9p, "rb") as fh:
            fh.seek(off)
            d9 = fh.read(n)
        if len(d7) != n or len(d9) != n:
            continue
        pct = sum(1 for a, b in zip(d7, d9) if a == b) / n if n else 0
        if pct > 0.5:
            ov += 1
            ovb += n
            if d7 != d9:
                differ += 1
                differb += n
        else:
            keep += 1
            keepb += n
    print(f"\nextract_v7_bins.py: overwrites {ov} C-compiled slices with raw v7 ROM bytes "
          f"({ovb:,d} B); keeps C output for {keep} slices ({keepb:,d} B)")
    print(f"  of the overwritten, {differ} slices / {differb:,d} B genuinely DIFFER from the "
          f"C output -- i.e. that many bytes of the v7 ROM are reproduced by NO source.")
    print(f"  (fixed 2026-09-01: this used to ignore .incbin off/len and count "
          f"occurrences * whole-file-size, giving 31,758,150 B on a 2,097,152 B ROM.)")
except FileNotFoundError as e:
    print("\n(v7 circularity check skipped:", e, ")")
