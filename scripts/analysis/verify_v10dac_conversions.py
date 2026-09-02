#!/usr/bin/env python3
"""Verify lane V10DAC's data-as-code conversions (2026-09-02).

Question this answers: for the 120 spans (3,390 B) that lane V10DAC converted
from mis-disassembled instruction mnemonics back to typed `.byte` data (per
`notes/v10-data-as-code/v10dac_conversion_manifest.json`), do the CURRENT
source lines still emit exactly the ORIGINAL ROM's bytes at the claimed
address? This is independent of, and a finer-grained check than, the whole-
ROM `cmp` gate -- it pins down that byte-identity to the specific converted
regions, not just to the ROM as a whole (which could stay byte-identical
even if a later, unrelated edit clobbered one of these regions and something
else in the same file happened to shift bytes back into place -- vanishingly
unlikely, but this check makes it checkable rather than assumed).

Method: each converted span was written with a comment header of the exact
form

    ; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xAAAAAA-0xBBBBBB (N B), ...

immediately followed by one or more `.byte ...` lines totalling exactly N
bytes. This script greps every v10/maincpu/*.s file for that header pattern,
parses the address range, collects the following `.byte` lines' values, and
compares them against the real ROM at that address. It does NOT re-run the
assembler -- it is a fast, static cross-check; the authoritative gate is
still `make rebuilt_ROMs/kn5000_v10_program.llvm.rom` + `cmp` against
`original_ROMs/kn5000_v10_program.rom` (see notes/lanes/BRIEF-2026-09-01.md).

Usage:
    python3 scripts/analysis/verify_v10dac_conversions.py
"""
import glob, json, os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASE = 0xE00000
ROM_PATH = os.path.join(REPO, "original_ROMs", "kn5000_v10_program.rom")
MANIFEST = os.path.join(REPO, "notes", "v10-data-as-code", "v10dac_conversion_manifest.json")
SRC_ROOT = os.path.join(REPO, "v10", "maincpu")

HEADER_RE = re.compile(
    r';\s*data-as-code \(v10_data_as_code_census\.py, STRICT rule\):\s*'
    r'0x([0-9A-Fa-f]+)-0x([0-9A-Fa-f]+)\s*\((\d+)\s*B\)')
BYTE_RE = re.compile(r'\.byte\s+(.+)$')


def find_headers():
    """Yields (file, lo, hi, size, byte_values) for every converted-span
    header found in the current v10/maincpu tree."""
    for fn in sorted(glob.glob(os.path.join(SRC_ROOT, "**/*.s"), recursive=True)):
        lines = open(fn, encoding="utf-8", errors="surrogateescape").read().split("\n")
        for i, line in enumerate(lines):
            m = HEADER_RE.search(line)
            if not m:
                continue
            lo, hi, size = int(m.group(1), 16), int(m.group(2), 16), int(m.group(3))
            vals = []
            j = i + 1
            # Stop as soon as we have exactly `size` bytes (the header's own
            # declared count) -- do NOT keep consuming into whatever
            # unrelated .byte line originally followed this block.
            while j < len(lines) and len(vals) < size:
                bm = BYTE_RE.search(lines[j].split(";", 1)[0])
                if not bm:
                    break
                for tok in bm.group(1).split(","):
                    tok = tok.strip()
                    if not tok:
                        continue
                    vals.append(int(tok, 0))
                j += 1
            yield fn, lo, hi, size, vals


def main():
    rom = open(ROM_PATH, "rb").read()
    manifest = json.load(open(MANIFEST)) if os.path.exists(MANIFEST) else None

    found = list(find_headers())
    print(f"{len(found)} converted-span headers found in the current tree")

    ok = 0
    bad = []
    total_bytes = 0
    for fn, lo, hi, size, vals in found:
        total_bytes += size
        claim_ok = (hi - lo == size) and (len(vals) == size)
        rom_bytes = list(rom[lo - BASE:hi - BASE])
        if claim_ok and vals == rom_bytes:
            ok += 1
        else:
            bad.append((fn, lo, hi, size, len(vals), vals == rom_bytes if len(vals) == len(rom_bytes) else None))

    print(f"  {ok}/{len(found)} match the original ROM bytes exactly, "
          f"{total_bytes:,} B total")
    if bad:
        print(f"  {len(bad)} MISMATCHES:")
        for fn, lo, hi, size, nvals, byteeq in bad:
            print(f"    0x{lo:06X}-0x{hi:06X} ({size} B) in {os.path.relpath(fn, REPO)}: "
                  f"{nvals} .byte values parsed, byte-match={byteeq}")

    if manifest:
        want = manifest["converted"]
        got_ranges = {(lo, hi) for _, lo, hi, _, _ in found}
        want_ranges = {(int(e["addr_lo"], 16), int(e["addr_hi"], 16)) for e in want}
        missing = want_ranges - got_ranges
        extra = got_ranges - want_ranges
        print(f"  manifest cross-check: {len(want_ranges)} expected spans, "
              f"{len(missing)} missing from the tree, {len(extra)} present but "
              f"not in the manifest")
        if missing:
            for lo, hi in sorted(missing):
                print(f"    MISSING (in manifest, not found as a header): 0x{lo:06X}-0x{hi:06X}")

    if bad or (manifest and missing):
        sys.exit(1)
    print("ALL CONVERTED SPANS VERIFIED BYTE-IDENTICAL TO THE ORIGINAL ROM.")


if __name__ == "__main__":
    main()
