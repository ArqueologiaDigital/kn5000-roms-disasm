#!/usr/bin/env python3
"""The 126 v7 names whose only ROM pointer is at `address - 0x41A`.

`check_0x41A_contradiction.py` establishes the population: of 1,043 symbols in
the six affected families, 534 have a 32-bit ROM word at their CURRENT address,
126 have one ONLY at `address - 0x41A`, 2 have both, against a 0.9% control.

This lists those 126 WITH THEIR EVIDENCE so they can be settled one at a time.

⚠ WHY NOT A BULK MOVE. 981 label "repairs" were committed on a cross-revision
heuristic earlier in this project and had to be reverted: moving a label changes
every `.long <symbol>` that references it, and a wrong move corrupts the ROM
silently until the byte gate runs. The evidence here is much stronger -- a
pointer the firmware dereferences, not a resemblance to another revision -- but
the failure mode is identical, so this emits a QUEUE rather than a patch.

For each name it prints:
  * the current address and the candidate (`- 0x41A`);
  * how many distinct ROM words point at each;
  * whether the bytes at the candidate look like a FUNCTION ENTRY (a frame
    prologue), which is what a routine name should sit on.

⚠ The prologue test is a weak confirmation, not a verdict: plenty of leaf
routines open with `ld` or `cp`. It is printed so a human can rank the queue, not
so a script can act on it.

Run:  python3 tools/spelling-probes/list_0x41A_suspects.py [--limit N]
"""
import argparse, importlib.util, os, struct, sys, collections

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
os.chdir(REPO); sys.path.insert(0, REPO)
SHIFT, BASE = 0x41A, 0xE00000

_c = importlib.util.spec_from_file_location(
    "cc", os.path.join(REPO, "scripts/converters/convert_corroborated_blocks.py"))
cc = importlib.util.module_from_spec(_c); _c.loader.exec_module(cc)

rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")

count = collections.Counter()
for i in range(0, len(rom) - 3):
    count[struct.unpack("<I", rom[i:i + 4])[0]] += 1

PREFIX = ("SndParam_", "MidiPkt_", "UIState_", "SoundFX_Handler_",
          "HdaeRom_", "CharMap_")
PROLOGUE = (b"\xbf", b"\x3e", b"\xef")      # lda XSP,XSP+.. / push XIZ / dec n,XSP


def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--limit", type=int, default=200)
    a = ap.parse_args()
    rows = []
    for ad, nm in syms.items():
        if not nm.startswith(PREFIX):
            continue
        if ad in count or (ad - SHIFT) not in count:
            continue
        o = ad - SHIFT - BASE
        pro = 0 <= o < len(rom) and rom[o:o + 1] in PROLOGUE
        rows.append((ad, nm, count[ad - SHIFT], pro))
    rows.sort()
    print(f"  suspects (ROM word ONLY at address - 0x41A): {len(rows)}")
    print(f"  of those, the candidate opens with a frame prologue: "
          f"{sum(1 for r in rows if r[3])}")
    print()
    print(f"  {'current':>9} {'candidate':>10} {'ptrs':>5} pro  name")
    for ad, nm, n, pro in rows[:a.limit]:
        print(f"  0x{ad:06X}  0x{ad-SHIFT:06X} {n:5}  {'Y' if pro else ' '}   {nm}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
