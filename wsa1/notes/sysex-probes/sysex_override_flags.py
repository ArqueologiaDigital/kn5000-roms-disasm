#!/usr/bin/env python3
"""What is byte +0x15 of a part's first record?

QUESTION IT ANSWERS
  A stored combination is a stream of the instrument's own parameter records,
  and chapter 6 of the reference names most of what they hold from the parameter
  tables.  A short list does not get named that way, because no parameter
  reaches those bytes and no menu screen captions them.  This names one of them.

  Part record `00`, payload `+0x15`, is a bit-field of SIX OVERRIDE FLAGS -- one
  per MIDI MULTIPLE MESSAGES OUTPUT parameter.  Each bit says whether the part
  sends its own value for that parameter or the internal one.

  The evidence is six sibling gates in prom_a, each a `bit n,(XIY+0x15)` whose
  taken branch chooses between a part's INTERNAL field and its override field:

      bit 0  0xF97459   PROGRAM CHANGE   internal +0x00  override +0x0E   20/60
      bit 1  0xF974DB   VOLUME           internal +0x03  override +0x11   20/63
      bit 2  0xF9750B   PANPOT           internal +0x08  override +0x12   20/64
      bit 3  0xF9753B   CHORUS DEPTH     internal +0x05  override +0x13   20/66
      bit 4  0xF9756B   REVERB DEPTH     internal +0x07  override +0x14   20/65
      bit 5  0xF97489   BANK SELECT      internal +0x01  override +0x10   20/61

  Six parameters, six bits, six gates, and the six are exactly the six the
  published tables call MIDI MULTIPLE MESSAGES OUTPUT.  Bits 6 and 7 are not
  named here.

WHY IT IS NOT A COINCIDENCE
  The pairing is not assigned by order: each gate is a distinct address whose
  displacement byte IS the bit number, and the six parameters are already
  independently known to be the six that have an override field at all --
  `sysex_param_addresses.py` flags exactly those as carrying a second write.

SIGNAL BEING READ
  prom_a, loaded at 0xF80000.  Every assertion is on literal instruction bytes.

RUN
  python3 wsa1/notes/sysex-probes/sysex_override_flags.py

PASS CRITERION
  All six sites are `bit n,(XIY+0x15)` at the stated bit, the six bits are
  distinct, and OK.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.abspath(os.path.join(HERE, "..", "..", "original_ROMs"))
A = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
A_BASE = 0xF80000
FLAG_OFFSET = 0x15

GATES = [
    (0xF97459, 0, "20/60", "PROGRAM CHANGE"),
    (0xF974DB, 1, "20/63", "VOLUME"),
    (0xF9750B, 2, "20/64", "PANPOT"),
    (0xF9753B, 3, "20/66", "CHORUS DEPTH"),
    (0xF9756B, 4, "20/65", "REVERB DEPTH"),
    (0xF97489, 5, "20/61", "BANK SELECT"),
]


def at(addr, n):
    return A[addr - A_BASE:addr - A_BASE + n]


def main():
    assert at(0xF80000, 2) != b"\x00\x00", "prom_a did not load"
    print("\nPART RECORD 00, PAYLOAD +0x%02X -- MIDI MULTIPLE MESSAGES OUTPUT overrides"
          % FLAG_OFFSET)
    print("  %-10s %-4s %-7s %s" % ("gate", "bit", "param", "parameter"))
    seen = set()
    for addr, bit, param, name in GATES:
        w = at(addr, 3)
        assert 0xBC <= w[0] <= 0xBF, \
            "0x%06X is not a bit-test (opcode %02X)" % (addr, w[0])
        assert w[1] == FLAG_OFFSET, \
            "0x%06X tests displacement %02X, not +%02X" % (addr, w[1], FLAG_OFFSET)
        assert 0xC8 <= w[2] <= 0xCF, "0x%06X has no bit selector" % addr
        got = w[2] - 0xC8
        assert got == bit, "0x%06X tests bit %d, expected %d" % (addr, got, bit)
        assert bit not in seen, "bit %d is claimed twice" % bit
        seen.add(bit)
        print("  0x%06X %-4d %-7s %s" % (addr, bit, param, name))

    assert len(seen) == 6, "expected six distinct bits, got %s" % sorted(seen)
    print("\n  six parameters, six distinct bits, six gates on the same byte")
    print("  bits %s are not named here" % [b for b in range(8) if b not in seen])
    print("OK")


if __name__ == "__main__":
    main()
