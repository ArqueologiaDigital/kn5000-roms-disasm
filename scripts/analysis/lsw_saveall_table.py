#!/usr/bin/env python3
"""Does the KN5000 firmware handle the .LSW file type? YES -- this proves it.

An earlier version of docs/kn-disk-file-formats.md asserted "The KN5000 firmware
never parses .LSW contents", on the strength of a search for the STRING "LSW".
That search was sound and the conclusion was wrong: the code never names the
type, it uses the INDEX 0 into SeqFileType_CodeTable. This script recovers the
table that does so.

FileIO_SaveAllRegions (v7 file_demo_proc.s) walks 8 records of 6 bytes:

    +0  u16  file-type index into SeqFileType_CodeTable  (0 = LSW)
    +2  u32  handler, reached via Resource_Region3_Start_0x12 and `call (xhl)`

Both field offsets are confirmed by the code, not inferred from the bytes:
_0x10 (=table+0) feeds the type index, _0x12 (=table+2) is loaded into xhl and
indirectly called.

Address derivation (no magic constants):
    SeqFileType_CodeTable     = NakaData_TechniChordStrings + 0x1a3f2 = 0xEA0340
    => NakaData_TechniChordStrings                                    = 0xE85F4E
    Resource_Region3_Start    = NakaData_TechniChordStrings + 0x1a2b2 = 0xEA0200
    Resource_Region3_Start_0x10 = +16                                 = 0xEA0210

Run:  python3 scripts/analysis/lsw_saveall_table.py
Exits non-zero if the table stops looking like 8 records covering types 0..7
with in-range handler pointers -- i.e. if this reading is ever falsified.
"""
import sys, glob, os

ROM_BASE = 0xE00000
TABLE    = 0xEA0210
NREC, STRIDE = 8, 6
EXT = ["LSW", "PMT", "SQT", "CMP", "TM ", "MSP", "RCM", "MD ", "SQF", "SEQ"]


def records(rom):
    off = TABLE - ROM_BASE
    for i in range(NREC):
        r = rom[off + i * STRIDE: off + (i + 1) * STRIDE]
        yield i, int.from_bytes(r[0:2], "little"), int.from_bytes(r[2:6], "little")


def main():
    roms = sorted(glob.glob(os.path.join(os.path.dirname(__file__),
                                         "../../original_ROMs/kn5000_v*_program.rom")))
    if not roms:
        sys.exit("no program ROMs found")
    ok = True
    for path in roms:
        rom = open(path, "rb").read()
        print(f"--- {os.path.basename(path)} ({len(rom):,} B)")
        seen = {}
        for i, typ, ptr in records(rom):
            name = EXT[typ] if typ < len(EXT) else f"?{typ}"
            inrange = ROM_BASE <= ptr < ROM_BASE + len(rom)
            print(f"   rec[{i}] type={typ} ({name})  handler=0x{ptr:08X}"
                  f"{'' if inrange else '   <-- OUT OF RANGE'}")
            seen[typ] = ptr
            ok &= inrange
        if set(seen) != set(range(NREC)):
            print(f"   FAIL: types are {sorted(seen)}, expected 0..{NREC-1}")
            ok = False
        elif 0 not in seen:
            ok = False
        else:
            print(f"   LSW (type 0) handler = 0x{seen[0]:08X}")
    print("\nPASS: .LSW is type 0 and has a handler in every revision." if ok
          else "\nFAIL: the save-all table no longer reads as documented.")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
