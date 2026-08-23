#!/usr/bin/env python3
"""Check that the MAME driver's "ROOT" really is the sub-CPU's tone database.

QUESTION THIS ANSWERS
---------------------
kn5000.cpp's build_pitch_constants() walks a structure it locates at offset
0x30000 of the `table_data` mask ROM and calls that ROOT.  Is that the same
structure the SUB-CPU firmware calls ToneDB_RootPtr?  If it is, then reading it
from the main CPU's ROM is reading a copy of what the sub-CPU legitimately holds
in its own DRAM -- and the question of whether the TONE GENERATOR may read it is
a separate (and negative) one.

THE CHAIN, all of it checkable
------------------------------
1. v7/maincpu/kn5000_v7_program.s:313 SubCPU_Send_Payload ships, over the E1
   inter-CPU latch protocol:

       main bus 0x830000 + 0x10000*k  ->  sub-CPU 0x050000 + 0x10000*k,  k = 0..4

   i.e. 5 x 64 KB = 320 KB of table_data land at sub-CPU 0x050000..0x09FFFF.
   `table_data` is mapped at main bus 0x800000, so main 0x830000 = file 0x30000.

2. v142/subcpu/kn5000_subprogram_v142.s DSP_System_Init installs

       (0x045310) ToneDB_RelBase = 0x00050000
       (0x045314) ToneDB_RootPtr = 0x00050000

   so the firmware's ToneDB root IS sub-CPU 0x050000 = table_data file 0x30000
   = the driver's ROOT.  Every pointer the firmware reads out of the root is
   added to RelBase, i.e. it is an offset relative to that same base.

3. This script prints the root's pointer fields and asserts they are all inside
   the 0x50000-byte block that was transferred.  A field pointing outside it
   would falsify the identification.

WHAT PASSES
-----------
All Root->+0x04..+0xB0 pointer fields < 0x50000, and

    n_sets = (min(Root+0x24, Root+0x28, Root+0x2C) - Root+0x30) / u16(Root+0xEC)

comes out a whole number -- it is 487, the multisample SET count the driver logs.

USAGE
-----
    python3 analysis/tonegen-register-interface/tonedb_root_check.py \
        [--roms DIR]     # default ~/compartilhado/kn5000_original_roms/kn5000

The two dumps are interleaved exactly as MAME's ROM_LOAD32_WORD does it
(kn5000.cpp: even.ic3 at +0, odd.ic1 at +2, stride 4).  Expected SHA1s, from the
same ROM_LOAD lines:
    kn5000_table_data_rom_even.ic3  1fd2604236b8d12ea7281fad64d72746eb00c525
    kn5000_table_data_rom_odd.ic1   bedf09d606d476f3e6d03e590709715304cf7ea5
"""

import argparse
import hashlib
import os
import sys

DEFAULT_ROMS = os.path.expanduser("~/compartilhado/kn5000_original_roms/kn5000")
EVEN = "kn5000_table_data_rom_even.ic3"
ODD = "kn5000_table_data_rom_odd.ic1"
SHA1 = {EVEN: "1fd2604236b8d12ea7281fad64d72746eb00c525",
        ODD: "bedf09d606d476f3e6d03e590709715304cf7ea5"}

ROOT = 0x30000                 # main bus 0x830000 == sub-CPU 0x050000
BLOCK = 0x50000                # bytes SubCPU_Send_Payload transfers to 0x050000

PTR_FIELDS = [
    (0x04, "preset bank table (ToneDB_Find_PatchRecord_Preset)"),
    (0x08, "bank table"),
    (0x0C, "table"),
    (0x24, "SET index table, family 0x00/0xC0"),
    (0x28, "SET index table, family 0x80"),
    (0x2C, "SET index table, family 0x40"),
    (0x30, "SET descriptor array, family 0x00/0xC0   <-- the driver's set_base"),
    (0x34, "SET descriptor array, family 0x80"),
    (0x38, "SET descriptor array, family 0x40"),
    (0x6C, "bank table (ToneDB_Find_ToneRecord_CoeffPath)"),
    (0x70, "portamento-target base (Voice_PortamentoTarget_ComputePitch)"),
    (0x7C, "sub-tone index table"),
    (0x80, "coefficient row block, 16-byte stride"),
    (0x9C, "alt SET index table, family 0x00/0xC0 (global flag 0x041343 bit 2)"),
    (0xA0, "alt SET index table, family 0x80"),
    (0xA4, "alt SET index table, family 0x40"),
    (0xB0, "sub-tone record array, 10-byte stride"),
]
U16_FIELDS = [
    (0xEA, "record length used by a copy"),
    (0xEC, "SET descriptor STRIDE, families 0x00/0xC0 and 0x80  <-- the driver's stride"),
    (0xEE, "record length used by a copy"),
    (0xF0, "record length used by a copy"),
    (0xF2, "SET descriptor STRIDE, family 0x40"),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--roms", default=DEFAULT_ROMS)
    args = ap.parse_args()

    parts = {}
    for name in (EVEN, ODD):
        p = os.path.join(args.roms, name)
        if not os.path.exists(p):
            sys.exit("missing %s -- pass --roms DIR" % p)
        parts[name] = open(p, "rb").read()
        got = hashlib.sha1(parts[name]).hexdigest()
        print("%-32s %d bytes  sha1 %s  %s"
              % (name, len(parts[name]), got, "OK" if got == SHA1[name] else "MISMATCH"))

    img = bytearray(0x200000)
    e, o = parts[EVEN], parts[ODD]
    for i in range(0, len(e), 2):
        img[i * 2:i * 2 + 2] = e[i:i + 2]
        img[i * 2 + 2:i * 2 + 4] = o[i:i + 2]

    def u16(a):
        return img[a] | (img[a + 1] << 8)

    def u32(a):
        return u16(a) | (u16(a + 2) << 16)

    print("\nToneDB root at table_data 0x%05X = main bus 0x%06X = sub-CPU 0x050000"
          % (ROOT, 0x800000 + ROOT))
    bad = 0
    for off, what in PTR_FIELDS:
        v = u32(ROOT + off)
        inside = v < BLOCK
        bad += 0 if inside else 1
        print("  Root+0x%02X = 0x%08X  %-6s %s"
              % (off, v, "" if inside else "OUTSIDE", what))
    for off, what in U16_FIELDS:
        print("  Root+0x%02X = 0x%04X      u16    %s" % (off, u16(ROOT + off), what))

    stride = u16(ROOT + 0xEC)
    base = u32(ROOT + 0x30)
    limit = min(u32(ROOT + 0x24), u32(ROOT + 0x28), u32(ROOT + 0x2C))
    span = limit - base
    print("\n  SET array: base 0x%05X .. 0x%05X, stride %d  ->  %d descriptors%s"
          % (base, limit, stride, span // stride,
             "" if span % stride == 0 else "  (NOT a whole number -- suspicious)"))
    print("\n  pointer fields outside the transferred 0x%05X-byte block: %d" % (BLOCK, bad))
    print("  VERDICT: %s" % ("the driver's ROOT is the sub-CPU's ToneDB root"
                             if bad == 0 and span % stride == 0 else "identification FAILS"))


if __name__ == "__main__":
    main()
