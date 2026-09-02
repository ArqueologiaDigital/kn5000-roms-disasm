#!/usr/bin/env python3
r"""ARE THERE MORE SCREEN-DATA BLOCKS IN THIS CORNER THAN THE TREE DESCRIBES?

QUESTION ANSWERED
-----------------
`scripts/generators/generate_all_screendata.py` turns ScreenData bytecode into
typed C structs, but only from a HAND-CURATED list of 31 block addresses.  This
tool asks whether the sound-editor corner contains further blocks that the list
never mentions, and generates descriptors for the ones that survive every check.

THE EVIDENCE REQUIRED OF A CANDIDATE -- all five, no exceptions
  1. REFERENCED AS AN ADDRESS.  Its address appears as a 24-bit immediate
     `0x00Fxxxxx` in the v10 assembly.  This is the project's standing data-seed
     rule: a value used as an address, never a branch target.
  2. PARSES.  ScreenDataParser consumes a non-empty command chain from it.
  3. DOES NOT OVERLAP a descriptor that already exists and already matches --
     an overlapping parse means the parser ran past a real block boundary, or
     the candidate is a sub-entry of a block already described.  Either way it
     is not a new block.
  4. COMPILES BYTE-EXACT.  The generated C, built with the Makefile's own
     toolchain invocation, must equal the ROM bytes at the candidate address,
     and its size must equal the parsed size.  This is the decisive check: a
     wrong reading cannot survive it.
  5. LIVES IN THIS LANE'S FILE, decided by the address->line map, not by an
     address range.  The two are not the same thing: storage/flash_floppy_
     handlers.s owns islands INSIDE sound_editor_ui.s's address span
     (0xF164F7 is one), and editing another lane's file is not this lane's job.

! WHY CHECK 4 CANNOT BE SKIPPED.  The parser is PERMISSIVE.
  se_blind_start_is_screendata.py measured its null: from 300 random addresses
  in these same two files, 5.3% parse a chain as long as the median real block.
  So "it parses" is worth very little on its own; "it parses AND a compiler
  re-emits exactly those ROM bytes from the resulting struct" is worth a lot.

Blocks are named `se_screen_<addr>` on purpose: semantic naming is DEFERRED on
this push, and an address is a name that cannot be wrong.

RUN
    python3 scripts/lanes/v10se/se_generate_new_screendata.py --amap /tmp/amap.json
    python3 scripts/lanes/v10se/se_generate_new_screendata.py --amap /tmp/amap.json --write
"""
import argparse
import bisect
import json
import os
import re
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "generators"))
sys.path.insert(0, HERE)
from screendata_parser import ScreenDataParser, ScreenDataCGenerator   # noqa: E402
import se_c_descriptor_vs_rom as cdesc                                 # noqa: E402

BASE = 0xE00000
ROM = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
IMM = re.compile(r"0x00([0-9a-fA-F]{6})")
# Prefilter only -- see check 5; --amap is what actually decides ownership.
LANE_LO, LANE_HI = 0xF0A110, 0xF1E146
LANE_FILE = "v10/maincpu/audio/sound_editor_ui.s"

# PRESERVATION OVERRIDES: stop a block short of where the parser would end it,
# so the descriptor does not swallow source another lane has already framed
# with its own evidence.
#
#   0xF129D1: the parser's last command is the 11-byte record at 0xF12AC9,
#   whose trailing LE32 is 0x00F12B53.  Lane B4 documented exactly that record
#   on 2026-08-30 ("0xF12AD0 + 4 (this record's LE32 pointer field)") and wrote
#   it as an explicit `.long` under a long comment block that describes the
#   whole following chain.  The two framings AGREE -- but absorbing the record
#   into an .incbin would detach B4's comment from the `.ascii` cells it goes
#   on to describe.  Stopping at 0xF12AC9 costs 11 bytes and keeps their work
#   exactly where they put it.
MAX_BYTES = {0xF129D1: 248}
DEFAULT_MAX = 500

# ...and the record itself is then REFUSED as a block of its own, for the same
# reason: it is already written as an explicit `.long` under lane B4's comment,
# and a descriptor for it would swallow that comment.  A typed `.long` with a
# documented record shape is not debt.
PRESERVE_AS_IS = {
    0xF12AC9: "already framed as an explicit .long under lane B4's "
              "2026-08-30 record-chain comment; typing it again would "
              "detach that comment from the cells it describes",
}


def existing_coverage(rom, tmp):
    cov = set()
    for f in sorted(os.listdir(cdesc.SEDIR)):
        if not f.endswith(".c"):
            continue
        p = os.path.join(cdesc.SEDIR, f)
        b = cdesc.header_base(p)
        blob, _ = cdesc.compile_bin(p, tmp)
        if blob and b and rom[b - BASE:b - BASE + len(blob)] == blob:
            cov.update(range(b, b + len(blob)))
    return cov


def address_immediates():
    hits = set()
    for dp, _, fs in os.walk(os.path.join(ROOT, "v10", "maincpu")):
        for f in fs:
            if not f.endswith(".s"):
                continue
            for m in IMM.finditer(open(os.path.join(dp, f),
                                       encoding="latin-1").read()):
                a = int(m.group(1), 16)
                if LANE_LO <= a <= LANE_HI:
                    hits.add(a)
    return sorted(hits)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--amap", required=True,
                    help="address->line map from scripts/analysis/"
                         "address_line_map.py --dump")
    args = ap.parse_args()

    rom = open(ROM, "rb").read()
    tmp = tempfile.mkdtemp(prefix="se-newblocks-")
    parser = ScreenDataParser(rom)

    ent = json.load(open(args.amap))
    oaddr = [e["addr"] for e in ent]

    def owner(a):
        return ent[bisect.bisect_right(oaddr, a) - 1]["src"]

    cov = existing_coverage(rom, tmp)
    print("existing byte-exact descriptor coverage: %d bytes" % len(cov))

    kept = []
    for a in address_immediates():
        cmds = parser.parse(a, MAX_BYTES.get(a, DEFAULT_MAX))
        n = sum(c.size for c in cmds)
        if not n:
            continue
        if set(range(a, a + n)) & cov:
            continue
        if a in PRESERVE_AS_IS:
            print("  %06X %4d B  REFUSED: %s" % (a, n, PRESERVE_AS_IS[a]))
            continue
        if owner(a) != LANE_FILE:
            print("  %06X %4d B  REFUSED: owned by %s, not this lane's file"
                  % (a, n, owner(a)))
            continue
        name = "se_screen_%06x" % a
        src = ScreenDataCGenerator(cmds, name, a).generate_c()
        p = os.path.join(tmp, name + ".c")
        open(p, "w").write(src)
        blob, err = cdesc.compile_bin(p, tmp)
        if blob is None:
            print("  %06X %4d B  REFUSED: does not compile" % (a, n))
            continue
        if len(blob) != n or rom[a - BASE:a - BASE + len(blob)] != blob:
            print("  %06X %4d B  REFUSED: compiled bytes differ from the ROM"
                  % (a, n))
            continue
        print("  %06X %4d B  MATCH  -> %s" % (a, n, name))
        kept.append((a, n, name, src))
        cov.update(range(a, a + n))

    print("\n%d new blocks, %d bytes" % (len(kept), sum(k[1] for k in kept)))
    if args.write:
        for a, n, name, src in kept:
            open(os.path.join(cdesc.SEDIR, name + ".c"), "w").write(src)
        print("wrote %d .c files into %s" % (len(kept), cdesc.SEDIR))


if __name__ == "__main__":
    main()
