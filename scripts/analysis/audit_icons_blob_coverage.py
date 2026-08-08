#!/usr/bin/env python3
"""Audit which bytes of table_data/includes/icons_to_strings.bin are still live.

The file is a verbatim slice of the factory Table Data dump: file offset 0 is
ROM 0x944D78 and the last byte is ROM 0x9F9FFF (742,024 bytes).  It predates
the source conversion, so most of the region it covers is now emitted from
real source and only a handful of sized `.incbin` slices still read from it.

This script rebuilds the coverage map from the tree instead of trusting a
hand-maintained list, and asserts the four invariants the comments in
table_data/kn5000_table_data.s claim:

  1. the blob is still byte-identical to original_ROMs/kn5000_table_data.rom
     over 0x944D78-0x9F9FFF (it is a dump slice, not an edited artifact);
  2. the archived ASL mirror bincludes exactly `0, 07F2D8h`, which is why the
     file must stay byte-identical on disk (see CLAUDE.md, blob policy);
  3. every LLVM-side slice lies inside that ASL extent -- nothing in the live
     build depends on a byte the ASL mirror does not also read;
  4. the dead tail (file 0x7F2D8-0xB5287 = ROM 0x9C4050-0x9F9FFF) is exactly
     the eighteen SLIDE4K demo-song preset blocks plus 0xFF alignment fill,
     i.e. a stale duplicate of data the Makefile now rebuilds from
     table_data/includes/demo_presets/midi/*.mid + sidecar/*.yaml.

Usage:  python3 scripts/analysis/audit_icons_blob_coverage.py [-v]
Exit status 0 = all invariants hold.
"""

import argparse
import hashlib
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(os.path.dirname(SCRIPT_DIR))

BLOB_PATH = os.path.join(PROJECT_DIR, "table_data", "includes",
                         "icons_to_strings.bin")
ROM_PATH = os.path.join(PROJECT_DIR, "original_ROMs", "kn5000_table_data.rom")
ASL_PATH = os.path.join(PROJECT_DIR, "archive", "asl", "table_data",
                        "kn5000_table_data.asm")
PRESET_REF_DIR = os.path.join(PROJECT_DIR, "original_ROMs")

ROM_BASE = 0x800000         # Table Data ROM load address
BLOB_BASE = 0x944D78        # blob file offset 0
BLOB_END = 0x9FA000         # one past the blob's last byte
ASL_EXTENT = 0x7F2D8        # length the ASL mirror bincludes, from offset 0
PRESET_TABLE = 0x9C4000     # DemoSongPreset_PointerTable
N_PRESETS_IN_TAIL = 18      # entries 0-17; entry 18 lives at 0x8E0000
SLIDE4K_MAGIC = b"SLIDE4K\x00"
SLIDE4K_HEADER = 11         # magic + 24-bit big-endian decompressed size

INCBIN_RE = re.compile(
    r'\.incbin\s+"[^"]*icons_to_strings\.bin"\s*,\s*'
    r'(0x[0-9a-fA-F]+|\d+)\s*,\s*(0x[0-9a-fA-F]+|\d+)')
BINCLUDE_RE = re.compile(
    r'binclude\s+"[^"]*icons_to_strings\.bin"\s*,\s*'
    r'([0-9a-fA-F]+h|0x[0-9a-fA-F]+|\d+)\s*,\s*'
    r'([0-9a-fA-F]+h|0x[0-9a-fA-F]+|\d+)')


def parse_num(text):
    """Accept LLVM (0x1f, 31) and ASL (01Fh, 31) integer spellings."""
    text = text.strip()
    if text.lower().endswith("h"):
        return int(text[:-1], 16)
    return int(text, 0)


def collect_llvm_slices():
    """Every `.incbin` of the blob in the LLVM sources, as (off, len, where)."""
    found = []
    for root, dirs, files in os.walk(PROJECT_DIR):
        dirs[:] = [d for d in dirs if d not in (".git", "archive")]
        for name in sorted(files):
            if not name.endswith(".s"):
                continue
            path = os.path.join(root, name)
            with open(path, errors="replace") as handle:
                for lineno, line in enumerate(handle, 1):
                    match = INCBIN_RE.search(line)
                    if match:
                        found.append((parse_num(match.group(1)),
                                      parse_num(match.group(2)),
                                      "%s:%d" % (os.path.relpath(path,
                                                                 PROJECT_DIR),
                                                 lineno)))
    found.sort()
    return found


def free_runs(size, slices):
    """Byte ranges of the blob that no slice in `slices` reads."""
    covered = bytearray(size)
    for off, length, _ in slices:
        covered[off:off + length] = b"\x01" * length
    runs, pos = [], 0
    while pos < size:
        if covered[pos]:
            pos += 1
            continue
        end = pos
        while end < size and not covered[end]:
            end += 1
        runs.append((pos, end - pos))
        pos = end
    return runs


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse
                                     .RawDescriptionHelpFormatter)
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="list every unreferenced run, not just the tail")
    args = parser.parse_args()

    blob = open(BLOB_PATH, "rb").read()
    rom = open(ROM_PATH, "rb").read()
    errors = []

    print("icons_to_strings.bin: %d bytes (0x%X), sha256 %s"
          % (len(blob), len(blob), hashlib.sha256(blob).hexdigest()))
    print("maps ROM 0x%06X-0x%06X" % (BLOB_BASE, BLOB_BASE + len(blob) - 1))

    # --- invariant 1: the blob is still a faithful slice of the dump ---------
    if len(blob) != BLOB_END - BLOB_BASE:
        # Everything below indexes the blob by ROM address, so a wrong length
        # would only produce noise -- stop here.
        print("\nFAIL:\n  - blob length %d != expected %d (the file must stay"
              " a verbatim 0x944D78-0x9F9FFF dump slice; it is never"
              " rewritten or truncated)"
              % (len(blob), BLOB_END - BLOB_BASE))
        return 1
    if blob != rom[BLOB_BASE - ROM_BASE:BLOB_END - ROM_BASE]:
        errors.append("blob differs from original_ROMs/kn5000_table_data.rom")
    else:
        print("  [ok] byte-identical to the factory dump over its whole extent")

    # --- invariant 2: the ASL mirror still bincludes 0, 0x7F2D8 -------------
    asl = open(ASL_PATH, errors="replace").read()
    asl_hits = [(parse_num(a), parse_num(b))
                for a, b in BINCLUDE_RE.findall(asl)]
    if asl_hits != [(0, ASL_EXTENT)]:
        errors.append("ASL mirror bincludes %r, expected [(0, 0x%X)]"
                      % (asl_hits, ASL_EXTENT))
    else:
        print("  [ok] ASL mirror bincludes 0, 0x%X (ROM 0x%06X-0x%06X)"
              % (ASL_EXTENT, BLOB_BASE, BLOB_BASE + ASL_EXTENT - 1))

    # --- invariant 3: the LLVM slices, and where they live ------------------
    slices = collect_llvm_slices()
    total = sum(length for _, length, _ in slices)
    print("\nLLVM slices: %d directives, %d bytes (%.1f%% of the file)"
          % (len(slices), total, 100.0 * total / len(blob)))
    for off, length, where in slices:
        print("  file 0x%05X-0x%05X  ROM 0x%06X-0x%06X  %7d B  %s"
              % (off, off + length - 1, BLOB_BASE + off,
                 BLOB_BASE + off + length - 1, length, where))
        if off + length > ASL_EXTENT:
            errors.append("slice at %s runs past the ASL extent 0x%X"
                          % (where, ASL_EXTENT))
    if slices and not any("past the ASL extent" in e for e in errors):
        print("  [ok] every slice lies inside the ASL extent")

    # --- invariant 4: the dead tail is the stale demo-preset duplicate ------
    runs = free_runs(len(blob), slices)
    unref = sum(length for _, length in runs)
    print("\nUnreferenced by the LLVM build: %d bytes in %d runs"
          % (unref, len(runs)))
    if args.verbose:
        for off, length in runs:
            # A run may straddle the ASL extent: below it the bytes are still
            # live for the ASL mirror, above it they are read by nothing.
            for start, stop in ((off, min(off + length, ASL_EXTENT)),
                                (max(off, ASL_EXTENT), off + length)):
                if start >= stop:
                    continue
                note = ("DEAD -- read by no build" if start >= ASL_EXTENT
                        else "source-built here, still blob-sourced by the ASL"
                             " mirror")
                print("  file 0x%05X-0x%05X  ROM 0x%06X-0x%06X  %7d B  %s"
                      % (start, stop - 1, BLOB_BASE + start,
                         BLOB_BASE + stop - 1, stop - start, note))

    tail_len = len(blob) - ASL_EXTENT
    print("\nDead tail: file 0x%05X-0x%05X = ROM 0x%06X-0x%06X, %d bytes"
          % (ASL_EXTENT, len(blob) - 1, BLOB_BASE + ASL_EXTENT,
             BLOB_BASE + len(blob) - 1, tail_len))
    if any(off < ASL_EXTENT < off + length for off, length, _ in slices):
        errors.append("a slice straddles the ASL extent boundary")

    pointers = [int.from_bytes(
        blob[PRESET_TABLE - BLOB_BASE + 4 * i:
             PRESET_TABLE - BLOB_BASE + 4 * i + 4], "little")
        for i in range(N_PRESETS_IN_TAIL)]
    accounted = 0
    for index, addr in enumerate(pointers):
        ref_path = os.path.join(PRESET_REF_DIR,
                                "demo_preset_%02d_compressed.original.bin"
                                % index)
        payload = open(ref_path, "rb").read()
        start = addr - BLOB_BASE
        header = blob[start:start + SLIDE4K_HEADER]
        body = blob[start + SLIDE4K_HEADER:
                    start + SLIDE4K_HEADER + len(payload)]
        end = (pointers[index + 1] if index + 1 < len(pointers) else BLOB_END)
        pad = blob[start + SLIDE4K_HEADER + len(payload):end - BLOB_BASE]
        if header[:8] != SLIDE4K_MAGIC:
            errors.append("preset %02d: no SLIDE4K header at 0x%06X"
                          % (index, addr))
        if body != payload:
            errors.append("preset %02d: tail copy differs from %s"
                          % (index, os.path.basename(ref_path)))
        if pad and set(pad) != {0xFF}:
            errors.append("preset %02d: %d non-0xFF bytes before the next block"
                          % (index, len(pad)))
        accounted += SLIDE4K_HEADER + len(payload) + len(pad)
        if args.verbose:
            print("  preset %02d  ROM 0x%06X  %6d B header+payload"
                  "  + %d B 0xFF pad" % (index, addr,
                                         SLIDE4K_HEADER + len(payload),
                                         len(pad)))
    if accounted != tail_len:
        errors.append("dead tail accounting: %d of %d bytes explained"
                      % (accounted, tail_len))
    else:
        print("  [ok] fully explained: 18 SLIDE4K blocks + 0xFF alignment fill,"
              " byte-identical to original_ROMs/demo_preset_NN_compressed"
              ".original.bin")
        print("  [ok] read by nothing -- the ROM's copy of these bytes comes"
              " from includes/demo_presets/, not from this file")

    if errors:
        print("\nFAIL:")
        for message in errors:
            print("  - %s" % message)
        return 1
    print("\nAll invariants hold.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
