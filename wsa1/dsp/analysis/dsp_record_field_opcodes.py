#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_record_field_opcodes.py -- which PoolDir_Records field is the I-RAM program body?

Each of the 56 PoolDir_Records (0xFDBFD9, 25-byte stride) carries four stream pointers
at offsets +0/+4/+8/+12. This resolves them (little-endian 16-bit into the 0xFD bank)
and reads the opcode nibble of each target, answering which field feeds the DSP's I-RAM
(opcode 3 = program) versus C-RAM (opcode 0 = coefficient).

MEASURED 2026-09-07 (this tool):
  field +0  -> opcode 0 in 52/56   (coefficient stream -> C-RAM)
  field +4  -> opcode 0 in 52/56   (coefficient stream -> C-RAM)
  field +8  -> opcode 0 in 53/56   (coefficient stream -> C-RAM)
  field +12 -> opcode 3 in 48/56   (the I-RAM PROGRAM body)

So the effect's I-RAM microcode body is field +12 (not +0/+4/+8, which are all
coefficient streams). This corrects the loose "fields +0 and +4 = coefficient/algorithm
bytecode pair" reading: only +12 is the program. sub_FA3A3C (prom_c/p7/p7_module.s
:16560) emits it via P7Stream_Run(field+12) at 0xFA3B9C. (Confirms the RE agent's trace
in FINDINGS-dsp-runtime-effect-uploads.md.) The 8 records whose +12 is not opcode 3 are
coefficient-only effects with no distinct program body.

    python3 dsp_record_field_opcodes.py

stdlib + the sibling wsa1_dsp_isa_crossval module. Read-only.
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import wsa1_dsp_isa_crossval as X                                    # noqa: E402

REC = 0xFDBFD9          # PoolDir_Records base
STRIDE = 0x19           # 25 bytes/record
N = 56


def opcode_at(addr):
    return (X.POOL.D[addr - X.POOL.BASE] >> 4) & 0xF


def main():
    per = {off: collections.Counter() for off in (0, 4, 8, 12)}
    for i in range(N):
        base = REC + STRIDE * i
        for off in (0, 4, 8, 12):
            b = X.POOL.D[base + off - X.POOL.BASE: base + off + 2 - X.POOL.BASE]
            addr = 0xFD0000 | (b[0] | (b[1] << 8))       # little-endian, 0xFD bank
            per[off][opcode_at(addr)] += 1
    role = {0: "coeff->C-RAM", 4: "coeff->C-RAM", 8: "coeff->C-RAM", 12: "PROGRAM->I-RAM"}
    for off in (0, 4, 8, 12):
        top = per[off].most_common(1)[0]
        print("field +%-2d : opcode %d in %2d/%d  (%s)   full=%s"
              % (off, top[0], top[1], N, role[off], dict(per[off])))
    prog = per[12][3]
    print("\n=> field +12 is the opcode-3 I-RAM program body for %d/%d effects; +0/+4/+8 "
          "are coefficient streams. The %d effects whose +12 is not op3 are coefficient-"
          "only." % (prog, N, N - prog))
    return 0 if prog >= 40 else 1


if __name__ == "__main__":
    sys.exit(main())
