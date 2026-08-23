#!/usr/bin/env python3
"""Scan the SUB-CPU payload ROM IMAGE for tone-generator register writes.

QUESTION THIS ANSWERS
---------------------
Same as tg_register_census.py -- "which IC303 registers does the firmware write,
and with what data" -- but read out of the ROM BYTES instead of the .s sources.
That matters because parts of the payload are still carried as `.byte` blobs in
the disassembly (the MISLABELLED-AS-DATA stretches at 0x0280FE-0x028838 and
0x028F75-0x029E30 both contain real register writers), so a source-level grep
UNDERCOUNTS.  Run both; the source scan gives you routine names, this one gives
you the true totals.

THE BYTE PATTERNS (TLCS-900/H, 32-bit direct addressing = the 0xF2 prefix)
-------------------------------------------------------------------------
    F2 00 00 10 50            ld  (0x100000), WA        address latch <- WA
    F2 00 00 10 02 lo hi      ldw (0x100000), #imm16    address latch <- imm
    F2 02 00 10 50            ld  (0x100002), WA        data port    <- WA
    F2 02 00 10 02 lo hi      ldw (0x100002), #imm16    data port    <- imm
    D8 C8 lo hi               add WA, #imm16            the register BANK
    D2 00 00 10 2r            ld  rr, (0x100000)        the status read (word size,
                                                        0xD2 prefix, not 0xF2)

A write is only counted when the address-latch store is followed, within a short
window, by a store to the data port -- the two halves are always emitted as one
pair with a `nop` and the P6.7 (SFR 0x18 bit 7) strobe between them.  Requiring
the pair is what keeps stray F2 00 00 10 bytes inside tables from being counted.

ADDRESS MAP OF THE .rom FILE
----------------------------
kn5000_subprogram_v142.rom is what the MAIN CPU ships to the sub-CPU; the main
CPU's own SubCPU_Send_Payload (v7/maincpu/kn5000_v7_program.s:313) states the
destinations, so file offset -> sub-CPU address is:
    off 0x000000..0x0000FF  ->  0x000400   (the entry stub)
    off 0x000100..0x0100FF  ->  0x00F000
    off 0x010100..0x0200FF  ->  0x01F000
    off 0x020100..0x02FFFF  ->  0x02F000
i.e. for everything above the stub, addr = off + 0xEF00.

USAGE
-----
    python3 analysis/tonegen-register-interface/tg_rom_opcode_scan.py
    python3 analysis/tonegen-register-interface/tg_rom_opcode_scan.py --sites

Run from the repository root.
"""

import argparse
import collections
import os
import sys

ROM = "original_ROMs/kn5000_subprogram_v142.rom"

LATCH_WA = b"\xf2\x00\x00\x10\x50"
LATCH_IMM = b"\xf2\x00\x00\x10\x02"
DATA_WA = b"\xf2\x02\x00\x10\x50"
DATA_IMM = b"\xf2\x02\x00\x10\x02"
READ_LATCH = b"\xf2\x00\x00\x10"          # opcode byte checked separately
ADD_WA_IMM = b"\xd8\xc8"


def addr_of(off):
    return off + 0x400 if off < 0x100 else off + 0xEF00


def u16(d, i):
    return d[i] | (d[i + 1] << 8)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sites", action="store_true")
    args = ap.parse_args()
    if not os.path.exists(ROM):
        sys.exit("run from the repository root; %s not found" % ROM)
    d = open(ROM, "rb").read()

    sites = []
    i = 0
    while i < len(d) - 8:
        if d[i:i + 4] != b"\xf2\x00\x00\x10":
            i += 1
            continue
        op = d[i + 4]
        if op == 0x50:
            latch_src, latch_imm, end = "WA", None, i + 5
        elif op == 0x02:
            latch_src, latch_imm, end = "imm", u16(d, i + 5), i + 7
        else:
            i += 1
            continue

        # The data half must follow inside the strobe window (nop + set 7,(0x18)
        # is 4 bytes; allow generous slack without reaching the next pair).
        win = d[end:end + 24]
        pos_wa = win.find(DATA_WA)
        pos_imm = win.find(DATA_IMM)
        if pos_wa < 0 and pos_imm < 0:
            i += 1
            continue
        if pos_imm >= 0 and (pos_wa < 0 or pos_imm < pos_wa):
            data = "imm 0x%04X" % u16(d, end + pos_imm + 5)
        else:
            data = "WA"

        # The bank: the nearest `add WA,#imm16` in the 8 bytes before the latch store.
        back = d[max(0, i - 8):i]
        j = back.rfind(ADD_WA_IMM)
        if latch_imm is not None:
            latch = "0x%04X (absolute)" % latch_imm
            reg = latch_imm >> 6
        elif j >= 0:
            bank = u16(back, j + 2)
            latch = "0x%03X + ch" % bank
            reg = bank >> 6
        else:
            latch = "0x000 + ch (bare channel)"
            reg = 0
        sites.append(dict(off=i, addr=addr_of(i), latch=latch, reg=reg, data=data))
        i = end

    reads = []
    i = 0
    while i < len(d) - 5:
        if d[i:i + 4] == b"\xd2\x00\x00\x10" and 0x20 <= d[i + 4] <= 0x27:
            reads.append(dict(off=i, addr=addr_of(i), op=d[i + 4]))
        i += 1

    print("%s  (%d bytes)" % (ROM, len(d)))
    print("paired register writes found: %d" % len(sites))
    print("register-window reads found : %d" % len(reads))
    for r in reads:
        print("   read at sub-CPU 0x%06X (file 0x%06X), dest opcode 0x%02X"
              % (r["addr"], r["off"], r["op"]))

    hist = collections.Counter(s["latch"] for s in sites)
    print("\n--- address-latch values, by write count ---")
    for latch, n in sorted(hist.items()):
        reg = [s["reg"] for s in sites if s["latch"] == latch][0]
        print("   %-26s reg 0x%02X   %3d writes" % (latch, reg, n))

    if args.sites:
        print("\n--- every site ---")
        for s in sites:
            print("   sub-CPU 0x%06X  %-26s reg 0x%02X <- %s"
                  % (s["addr"], s["latch"], s["reg"], s["data"]))


if __name__ == "__main__":
    main()
