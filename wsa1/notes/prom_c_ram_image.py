#!/usr/bin/env python3
"""What does CPU 2's variable block hold at power-on?  Answered from the boot copy itself.

QUESTION ANSWERED
  prom_c is full of bare addresses like 0x00F32A and 0x00E2E3 whose meaning is guessed
  from the code that touches them.  A large slab of them is not uninitialised at all:
  RESET calls a routine that block-copies 4,312 bytes of ROM into 0x00E2DF, so the
  POWER-ON VALUE of every one of those variables is readable out of the ROM.  Knowing
  the default is often what decides between two readings of a variable -- the touch
  offset at 0x00F32B, for instance, is read as `value - 0x50`, and its boot value is
  exactly 0x50, which is what "centred control" means and what a wrong reading would
  not produce.

  This script re-derives the copy's three parameters FROM THE INSTRUCTION BYTES rather
  than from a comment, so the note that quotes it cannot drift away from the ROM.

  ⚠ It proves where the bytes come from.  It does not prove that a variable is never
  written again before first use, and it says nothing about the 0x000080-0x00E2DE and
  0x00F3B7-0x01007F parts of work DRAM, which this copy does not reach.

RUN
  python3 notes/prom_c_ram_image.py                 # the copy, verified, plus known variables
  python3 notes/prom_c_ram_image.py 0x00F32A 0x00F2F3:4
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000
COPY_ROUTINE = 0xF989EF

# The instruction bytes the copy is read out of.  If any of these change, everything
# below is wrong, and the script says so instead of printing stale numbers.
EXPECT = [
    (0xF989EF, bytes([0xF2, 0xEA, 0xB4, 0xFC, 0x35]), "lda XIY,0xFCB4EA   (source)"),
    (0xF989F4, bytes([0xF2, 0xDF, 0xE2, 0x00, 0x34]), "lda XIX,0x00E2DF   (destination)"),
    (0xF989F9, bytes([0x41, 0xD8, 0x10, 0x00, 0x00]), "ld  XBC,0x000010D8 (count -> BC)"),
    (0xF989FE, bytes([0x85, 0x11]),                   "ldir               ((XIY+) -> (XIX+))"),
]

# Variables this tree has named or argued about, with the width they are read at.
KNOWN = [
    (0x00E2E3, 1, "INTT1 six-phase scheduler counter (INTT1_HANDLER)"),
    (0x00E2E4, 1, "one-shot countdown guarding sub_F9915C"),
    (0x00E2DF, 2, "counter the main loop steps 0..12 (0xF98C22)"),
    (0x00F2F3, 4, "INTT1 tick counter (the serial ISRs timestamp with it)"),
    (0x00F2F7, 1, "INTES0 shadow byte (Serial0_Init)"),
    (0x00F2F9, 2, "serial-0 state byte written by INTTX0_HANDLER and Serial0_Init"),
    (0x00F32A, 1, "touch curve MODE, index into ToneGen_VelCurve_ModeParams"),
    (0x00F32B, 1, "touch OFFSET control, consumed as (value - 0x50)"),
    (0x00F35F, 1, "the two-valued latch sub_F9915C writes"),
    (0x00F2F1, 2, "main-loop countdown at 0xF98C40"),
]


def main():
    data = open(ROM, "rb").read()
    ok = True
    print(f"the copy, as read from prom_c 0x{COPY_ROUTINE:06X}:")
    for addr, want, what in EXPECT:
        got = data[addr - BASE:addr - BASE + len(want)]
        good = got == want
        ok &= good
        print(f"  0x{addr:06X}  {' '.join('%02x' % b for b in got):<16}"
              f"{'OK  ' if good else 'FAIL'}  {what}")
    if not ok:
        print("\nFAIL: the copy instructions are not what this script expects; nothing below "
              "is trustworthy.")
        return 1
    src, dst, n = 0xFCB4EA, 0x00E2DF, 0x10D8
    print(f"\n  ROM 0x{src:06X}..0x{src + n - 1:06X}  ->  RAM 0x{dst:06X}..0x{dst + n - 1:06X}"
          f"   ({n} = 0x{n:X} bytes)")
    print("  ⚠ destination XIX, source XIY: MAME's op_80 sets p1 (the LDIR destination) from"
          "\n    opcode-1 and p2 from the opcode, so 0x85 gives dest = XIX, src = XIY"
          "\n    (mame/src/devices/cpu/tlcs900/900tbl.hxx:5435-5437 and op_LDIR at :2495).")

    def boot(a, w):
        off = a - dst
        if not (0 <= off and off + w <= n):
            return None
        return data[src - BASE + off:src - BASE + off + w]

    args = sys.argv[1:]
    rows = []
    if args:
        for a in args:
            addr, _, wd = a.partition(":")
            rows.append((int(addr, 0), int(wd) if wd else 1, ""))
    else:
        rows = KNOWN
    print(f"\n  {'RAM':<10} {'w':>2}  {'from ROM':<10} {'boot value':<14} what")
    for a, w, what in sorted(rows):
        b = boot(a, w)
        if b is None:
            print(f"  0x{a:06X}  {w:>2}  -- outside the copied block --")
            continue
        le = int.from_bytes(b, "little")
        print(f"  0x{a:06X}  {w:>2}  0x{src + (a - dst):06X}   "
              f"{' '.join('%02x' % x for x in b):<10} = {le:<5} {what}")
    print("\nPASS: the copy instructions are byte-for-byte as expected.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
