#!/usr/bin/env python3
"""op72_constants.py -- the compressor gain-computer's ROM constants, decoded.

QUESTION IT ANSWERS
    sect. 140 stopped on this: *"deriving the cell order by stability needs the per-coefficient
    SCALES, and they are solved for the EQ only"* -- the EQ's scales came out of a flatness
    identity that no other family has.  sect. 149 then measured that no anchored criterion can rank
    `f31 = 3`'s readings because the code lives in the dynamics/distortion families, where the
    reference models are graded rather than bit-exact.  The handover's top item became *"build a
    bit-exact reference for ONE dynamics program"*, with the compressor named because `op0x72[0]`
    (role gain-computer) is the family's only **PROVEN** cell<-opcode entry.

    ★ THIS IS STEP ONE, AND IT IS CHEAPER THAN EXPECTED.  `host_side.py laws` locates op 0x72's
    evaluator at `0x039ABD` with *"15 ROM data references, 0x012DB3..0x012E03"* and calls it
    table-driven.  Those 80 bytes are not a table: they are **IEEE-754 constants**, little-endian,
    and they include the DSP's fixed-point scales explicitly.

USAGE
    python3 dsp/tools/op72_constants.py

WHAT IT ESTABLISHES
    * the evaluator's arithmetic is FLOATING POINT, three doubles and eight floats;
    * the three doubles are **-0.0697, 10, 0.9999** and they appear TWICE, byte-identical -- two
      operands sharing one law (`op0x72` writes two cells in every carrier: `prog36` 0x04/0x0D,
      `prog75` 0x0A/0x19);
    * the floats are `2, 2, 1, 3` then **2^21, 2^23, 2^22, 2^21** -- FOUR DISTINCT POWER-OF-TWO
      SCALES, in the ROM, explicit.

★★ AND THE LAW ITSELF (sect. 153), read from the evaluator in the committed linear disassembly
    `original_ROMs/kn5000_subprogram_v142.rom.unidasm`.  The sequence is the same for both
    operands, and the SECOND one uses the DUPLICATED constants -- which is the code confirming
    "one law, two operands" rather than the byte pattern suggesting it:

        39b08  cp HL,0x59 / clamp          the user value, clamped to <= 89 (second: <= 88)
        39b1a  ld WA,0x63 ; sub WA,HL      x = 99 - user          (0x63 = 99, the 0..99 range)
        39b2a  call 0x03dd36               int -> double                    [INFERRED from use]
        39b31  lda XDE,0x012db3 ; 0x03e290 multiply by -0.0697              [INFERRED from use]
        39b47  push 0x012dbb ; 0x03d533    POW: 10 ^ (that)                 [INFERRED from use]
        39b61  lda XDE,0x012dc3 ; 0x03e290 multiply by 0.9999
        39b77  ld WA,0x63 ; sub WA,IZ      ... and the whole sequence again for the second cell,
        39b8e  lda XDE,0x012dcb            with 0x012dcb / 0x012dd3 -- the DUPLICATES.

    ⇒ **cell = 10 ^ ( -0.0697 x (99 - user) ) x 0.9999**, one law, two operands.

⛔ WHAT IS STILL NOT ESTABLISHED.  (a) The helper identities above are INFERRED FROM USE, not
  proven -- `0x03dd36`, `0x03e290`, `0x03d533` are read as int->double, double-multiply and pow
  from their operands and call shape.  (b) The eight FLOATS (`2, 2, 1, 3`, `2^21, 2^23, 2^22,
  2^21`) do NOT appear in the code read here; the scaling step is further on, past `0x039bbb`,
  and is UNREAD.  So the exponential law is read and the SCALE APPLICATION is not.
"""
import os
import struct
import sys

sys.path.insert(0, "/home/fsanches/compartilhado/kn7000_mame/tools")
import kn5000_dsp_params as P                                             # noqa: E402

SUB = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "..", "original_ROMs", "kn5000_subprogram_v142.rom")
LO, HI = 0x012DB3, 0x012E03          # host_side.py laws: op 0x72's ROM data span
DOUBLES_END = 0x30                   # measured: the first 0x30 bytes decode as doubles


def main():
    rom = P.Rom(SUB, P.SUB_BASE)
    b = bytes(rom.u8(a) for a in range(LO, HI))
    print("=" * 96)
    print("  op 0x72 -- the compressor's GAIN COMPUTER, the dynamics family's only PROVEN")
    print("  cell<-opcode entry.  Evaluator 0x039ABD; ROM data 0x%06X..0x%06X (%d bytes)."
          % (LO, HI, HI - LO))
    print("=" * 96)

    print("\n   ★ DOUBLES (IEEE-754, little-endian -- the CPU's byte order)\n")
    for i in range(0, DOUBLES_END, 8):
        v = struct.unpack("<d", b[i:i + 8])[0]
        print("      %06X  %s   = %.12g" % (LO + i, " ".join("%02X" % x for x in b[i:i + 8]), v))
    half = DOUBLES_END // 2
    print("\n      the two halves are byte-identical: %s"
          % ("★ YES -- one law, two operands" if b[:half] == b[half:DOUBLES_END] else "no"))
    print("      (and `op0x72` writes exactly TWO cells in every carrier: prog36 0x04/0x0D,")
    print("       prog75 0x0A/0x19 -- so `two operands' is what the cell map already said.)")

    print("\n   ★ FLOATS (IEEE-754, little-endian)\n")
    for i in range(DOUBLES_END, len(b), 4):
        v = struct.unpack("<f", b[i:i + 4])[0]
        note = ""
        for k in range(16, 26):
            if abs(v - float(1 << k)) < 1e-3:
                note = "   ★ = 2^%d" % k
        print("      %06X  %s   = %-14.10g%s"
              % (LO + i, " ".join("%02X" % x for x in b[i:i + 4]), v, note))

    print("\n   ⇒ FOUR DISTINCT POWER-OF-TWO SCALES, written down in the ROM.")
    print("     sect. 140 stopped because *\"the per-coefficient scales are solved for the EQ")
    print("     only\"* -- the EQ's came from a flatness IDENTITY this family has no analogue of.")
    print("     Here they need no solving at all.")
    print("\n   ⛔ The constants are NOT the law.  How they combine is in the evaluator's 203")
    print("     lines of TLCS-900, which this file does not read, so no formula is claimed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
