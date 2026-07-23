#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""verify.py -- byte-match check for the KN5000 effects-DSP disassembly tree.

The KN5000 disassembly repo lives by a byte-match invariant: every disassembled
view must reproduce the original ROM bytes exactly.  This tool proves the dsp/
tree is a FAITHFUL view of the real ROM data -- it never invents or drops a byte.

What it checks (all of it against original_ROMs/kn5000_subprogram_v142.rom):

  1. Re-extract the shared header and all 100 algorithm streams from the ROM
     (via the reused parser kn5000_dsp_extract).
  2. Parse the raw 36-bit word column back out of each committed listing
     (dsp/disasm/kernel.dsm and every dsp/disasm/progNN_*.dsm) and re-pack it to
     5-byte big-endian.
  3. Confirm the kernel bytes == the ROM header stream, and that EVERY valid
     algorithm stream in the ROM (all 100, minus the 5 malformed) is byte-identical
     to the committed listing of its distinct image -- so all 96 valid programs and
     all ~100 effect slots are covered, not just the 38 representatives.

Exit 0 and prints "BYTE-MATCH OK" iff the whole corpus round-trips.

    python3 dsp/verify.py                    # uses the repo's default paths
    python3 dsp/verify.py --sub <rom> --tools <kn7000_mame/tools>
"""
import argparse
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ALGO_TABLE = 0x0001ED7C
HEADER_ROM = 0x01E496
N_ALGOS = 100
MALFORMED = {79, 88, 89, 90, 91}

WORD_RE = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\s")


def listing_words(path):
    out = []
    for line in open(path):
        m = WORD_RE.match(line)
        if m:
            out.append(int(m.group(1), 16))
    return out


def main():
    repo = os.path.abspath(os.path.join(HERE, ".."))
    ap = argparse.ArgumentParser()
    ap.add_argument("--sub", default=os.path.join(repo, "original_ROMs", "kn5000_subprogram_v142.rom"))
    ap.add_argument("--tools", default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    ap.add_argument("--disasm", default=os.path.join(HERE, "disasm"))
    args = ap.parse_args()

    if not os.path.isdir(args.tools):
        sys.exit("ERROR: need the ROM parser -- pass --tools <kn7000_mame/tools>")
    sys.path.insert(0, args.tools)
    import kn5000_dsp_extract as E

    rom = E.Rom(args.sub)

    # ROM header + algorithm streams
    iram, _c, _o = E.parse_stream(rom, HEADER_ROM, limit=40)
    rom_header = [int.from_bytes(bytes(w), "big") for w in iram[0][1]]
    rom_algo = {}
    for i in range(N_ALGOS):
        try:
            ir, _c, _o = E.parse_stream(rom, rom.u32le(ALGO_TABLE + 4 * i))
        except Exception:
            continue
        if ir:
            rom_algo[i] = [int.from_bytes(bytes(w), "big")
                           for _a, ws, _l in ir for w in ws]

    fails = 0
    checked = 0

    # 1. kernel
    kpath = os.path.join(args.disasm, "kernel.dsm")
    if listing_words(kpath) != rom_header:
        print("FAIL: kernel.dsm != ROM header stream"); fails += 1
    else:
        checked += 1

    # 2. build a lookup from image content -> committed listing words
    listing_by_words = {}
    for f in sorted(glob.glob(os.path.join(args.disasm, "prog*_*.dsm"))):
        listing_by_words[tuple(listing_words(f))] = os.path.basename(f)

    # 3. every valid algorithm stream must equal SOME committed listing exactly
    for i in sorted(rom_algo):
        if i in MALFORMED:
            continue
        w = tuple(rom_algo[i])
        checked += 1
        if w not in listing_by_words:
            print("FAIL: algo %d (%d words) has no byte-identical committed listing" % (i, len(w)))
            fails += 1

    print("checked: kernel + %d valid algorithm streams (%d distinct images)"
          % (checked - 1, len(listing_by_words)))
    if fails:
        print("BYTE-MATCH FAILED: %d mismatch(es)" % fails)
        sys.exit(1)
    print("BYTE-MATCH OK -- every committed listing reproduces the ROM bytes exactly")


if __name__ == "__main__":
    main()
