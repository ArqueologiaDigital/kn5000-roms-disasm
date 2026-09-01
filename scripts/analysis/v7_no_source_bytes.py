#!/usr/bin/env python3
"""v7_no_source_bytes.py -- exactly how many v7 maincpu ROM bytes have NO source at all?

QUESTION ANSWERED
-----------------
Lane brief 2026-09-01 asked lane v7 to check whether the build still "reads its own
ROM" -- the defect fixed in 1528605e ("v7: de-circularised") and documented in
analysis/v7-provenance-audit/README.md as of 2026-08-21 (288 slices, 136,775 B; 23
C-divergent bins, 5,118 B; honest figure 93.2%). This answers the SAME question, fresh,
in this worktree, on 2026-09-01, two mechanisms at a time -- not a simulation of the
retired extract_v7_bins.py, but a direct count of what v7/maincpu/kn5000_v7_program.s
ACTUALLY assembles today:

  1. committed romslices/ .bin files LIVE-REFERENCED by a v7/maincpu/**/*.s .incbin
     (a pure ROM byte transplant with no C source of any kind), plus
  2. the raw-byte entries (not the pointer-relocation entries) inside
     v7/maincpu/includes/v7_c_divergence.json -- bytes where the committed, compiled
     C is patched with a literal value because no formula was found.

Pointer relocations in v7_c_divergence.json are NOT counted here: `apply_v7_c_divergence.py`
computes each of those from a documented address-range delta, applied by the build, so the
byte comes from a rule, not a blob. That is the same standard the .incbin/of-which-C table
above this in kn5000_source_coverage.py applies to "generated/ + a Makefile clang rule".

WHY NOT scripts/build/extract_v7_bins.py's stage-1 heuristic (as re-run inside
kn5000_source_coverage.py)? That code is DEAD -- removed from the Makefile in 1528605e --
and simulating it answers a different, looser question: "how much would be WRONG if v7
reused v9's committed bin verbatim", not "how much of v7's ACTUAL committed tree has no
source". It also had a real bug (fixed in the same commit as this script): it ignored
`.incbin "path", off, len` and took the WHOLE shared blob's size for every labelled slice
into it, so a file .incbin'd 842 times (technichord_string_data.s) counted 842x its own
size. That produced 31,758,150 B on a 2,097,152 B ROM before the fix, and gives a
mechanism-accurate but different number (a v9-vs-v7 naive-reuse delta) after it. Use
THIS script for "how much of v7 has no source"; use the fixed simulation only for "how
wrong would naive v9 reuse be".

RUN:  python3 scripts/analysis/v7_no_source_bytes.py
"""
import glob
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(REPO)

INC = re.compile(r'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*(?:,\s*([0-9a-fA-Fx]+))?)?')


def referenced_romslice_bytes():
    """Live .incbin references from v7/maincpu into includes/romslices/ -- pure ROM
    transplants with no C source at all. Sums the SLICE length actually .incbin'd
    (respecting off/len), not the committed file's size, and counts each referenced
    file once even if reachable from more than one .incbin line."""
    seen = {}
    for f in glob.glob('v7/maincpu/**/*.s', recursive=True):
        txt = open(f, encoding='latin-1').read()
        base = os.path.dirname(f)
        for path, off, ln in INC.findall(txt):
            if 'romslices/' not in path:
                continue
            real = next((c for c in (os.path.join(base, path), os.path.join('v7/maincpu', path), path)
                         if os.path.exists(c)), None)
            if not real:
                continue
            real = os.path.abspath(real)
            fsz = os.path.getsize(real)
            size = int(ln, 0) if ln else (fsz - int(off, 0) if off else fsz)
            # A slice file is referenced by exactly one .incbin in a byte-exact tree
            # (two different-sized reads of the same file would already fail the gate);
            # keep the largest if we ever see more than one, and never double-count size.
            seen[real] = max(seen.get(real, 0), size)
    return seen


def divergence_raw_bytes():
    """The literal-value patch entries in v7_c_divergence.json: real, committed C output
    exists for these bins, but these specific byte offsets are overridden because no
    pointer-relocation formula reproduces them. Distinct from `reloc` entries, which are
    a documented arithmetic RULE, not a blob."""
    p = 'v7/maincpu/includes/v7_c_divergence.json'
    if not os.path.exists(p):
        return {}
    patch = json.loads(open(p).read())
    return {name: len(ent.get('raw', {})) for name, ent in patch.items() if ent.get('raw')}


def main():
    slices = referenced_romslice_bytes()
    raws = divergence_raw_bytes()
    slice_total = sum(slices.values())
    raw_total = sum(raws.values())
    total = slice_total + raw_total
    rom_size = 2097152

    print(f"v7 maincpu: {rom_size:,} B ROM")
    print(f"  {len(slices):4d} live-referenced romslices/*.bin, pure ROM transplant, "
          f"{slice_total:,} B")
    print(f"  {len(raws):4d} v7_c_divergence.json bins with raw-byte patches, "
          f"{raw_total:,} B")
    for name, n in sorted(raws.items(), key=lambda kv: -kv[1]):
        print(f"      {name:45s} {n:,} B raw")
    print(f"\n  TOTAL genuinely reproduced by NO source: {total:,} B "
          f"({100 * total / rom_size:.2f}% of the ROM)")
    print(f"  real source (assembly, typed data, or clang -target tlcs900 C, "
          f"incl. patched relocations): {rom_size - total:,} B "
          f"({100 * (rom_size - total) / rom_size:.2f}%)")


if __name__ == '__main__':
    sys.exit(main())
