#!/usr/bin/env python3
"""How is the SEQUENCER bulk-dump block arranged?

QUESTION IT ANSWERS
  The SEQUENCER category is three blocks: LOCATION (3072 bytes), HEADER (30720)
  and PERFORMANCE (variable).  Their addresses and lengths are confirmed twice
  over -- decoded from the program and printed in Technics' published SIZ table
  -- but no capture available here contains a SEQUENCER transfer, because the
  capture came from a rack and a rack refuses that category.  So the reference
  said the arrangement of the blocks was unknown.

  It is not.  A capture is needed to see the DATA; the ARRANGEMENT is in the
  program, and one routine gives it away.

  `SongName_ResetToUnderscores` (prom_a 0xF818EA) blanks a song's six-character
  name in three places at once, and its three destinations are literal:

      0x006034CA                                   the LOCATION block  + 0xCA
      0x00610000 + song*3072 + 0xCA                the HEADER block, song n
      0x000012F6                                   a third working copy

  The multiply is written as two shifts, `sla xwa,0x0b` then `sla xiy,0x0a`,
  added -- n*2048 + n*1024 = n*3072.  So:

    * the HEADER block is TEN SONG RECORDS OF 3072 BYTES (10 * 3072 = 30720,
      the block's whole length, and the manual says the sequencer holds ten
      songs);
    * a song's NAME is six characters at offset 0xCA of its record;
    * the LOCATION block is 3072 bytes and carries the name at the SAME offset
      0xCA, so it has a song record's layout -- it is the working copy of the
      song being edited, in the same shape as the stored ones.

  That is the top-level arrangement of two of the three blocks, established
  without a capture.

WHAT IS STILL NOT SETTLED
  What the other 3066 bytes of a song record hold, and how PERFORMANCE -- the
  variable-length block that carries the recorded notes -- is arranged.  Those
  would need either a SEQUENCER transfer or a decode of the recorder itself.

SIGNAL BEING READ
  prom_a, loaded at 0xF80000.  Every assertion below is on literal instruction
  bytes.

RUN
  python3 wsa1/notes/sysex-probes/sysex_sequencer_layout.py

PASS CRITERION
  The routine's bytes are as expected, the arithmetic closes, and OK.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.abspath(os.path.join(HERE, "..", "..", "original_ROMs"))
A = open(os.path.join(ROMS, "wsa1_prom_a.ic12"), "rb").read()
A_BASE = 0xF80000

LOCATION_AT, LOCATION_LEN = 0x603400, 0x0C00      # 3072
HEADER_AT, HEADER_LEN = 0x610000, 0x7800          # 30720
NAME_OFF, NAME_LEN = 0xCA, 6
SONGS = 10
ROUTINE = 0xF818EA


def a(addr, n=1):
    return A[addr - A_BASE:addr - A_BASE + n]


def main():
    assert a(0xF80000, 2) != b"\x00\x00", "prom_a did not load"

    print("\nSEQUENCER BLOCK ARRANGEMENT")
    print("  LOCATION   0x%06X, %5d bytes" % (LOCATION_AT, LOCATION_LEN))
    print("  HEADER     0x%06X, %5d bytes" % (HEADER_AT, HEADER_LEN))

    # 1. ten songs, exactly
    assert HEADER_LEN % LOCATION_LEN == 0, "HEADER is not a whole number of records"
    songs = HEADER_LEN // LOCATION_LEN
    assert songs == SONGS, "HEADER holds %d records, expected %d" % (songs, SONGS)
    print("  HEADER / LOCATION = %d, and the manual states ten songs" % songs)

    # 2. the routine, byte for byte
    assert a(ROUTINE, 5) == bytes([0x44, 0xCA, 0x34, 0x60, 0x00]), \
        "0x%06X no longer loads XIX with 0x%06X" % (ROUTINE, LOCATION_AT + NAME_OFF)
    assert a(ROUTINE + 5, 5) == bytes([0x45, 0x48, 0x19, 0xF8, 0x00]), \
        "the six-character source moved"
    assert a(ROUTINE + 10, 3) == bytes([0x31, 0x06, 0x00]), \
        "the copy length is not %d" % NAME_LEN
    assert a(ROUTINE + 13, 2) == bytes([0x85, 0x11]), "not an ldir"
    print("\n  0x%06X copies %d bytes to 0x%06X   (LOCATION + 0x%02X)"
          % (ROUTINE, NAME_LEN, LOCATION_AT + NAME_OFF, NAME_OFF))

    # 3. the song index, shifted by 11 and by 10, added: n * 3072
    assert a(0xF818FB, 4) == bytes([0xC1, 0x0A, 0x36, 0x21]), \
        "the song number no longer comes from (0x360A)"
    assert a(0xF81901, 3) == bytes([0xE8, 0xEC, 0x0B]), "not `sla xwa,0x0b`"
    assert a(0xF81904, 3) == bytes([0xED, 0xEC, 0x0A]), "not `sla xiy,0x0a`"
    assert a(0xF81907, 2) == bytes([0xED, 0x80]), "the two shifts are not added"
    assert (1 << 0x0B) + (1 << 0x0A) == LOCATION_LEN, \
        "2^11 + 2^10 is not %d" % LOCATION_LEN
    assert a(0xF81909, 5) == bytes([0x44, 0x00, 0x00, 0x61, 0x00]), \
        "the HEADER base is no longer 0x%06X" % HEADER_AT
    assert a(0xF81910, 5) == bytes([0x40, 0xCA, 0x00, 0x00, 0x00]), \
        "the name offset is no longer 0x%02X" % NAME_OFF
    print("  then to 0x%06X + song*(2^11 + 2^10) + 0x%02X = HEADER + song*%d + 0x%02X"
          % (HEADER_AT, NAME_OFF, LOCATION_LEN, NAME_OFF))
    print("  song number read from (0x360A)")

    print("\n  so the HEADER block is %d song records of %d bytes," % (songs, LOCATION_LEN))
    print("  a song's name is %d characters at +0x%02X of its record," % (NAME_LEN, NAME_OFF))
    print("  and LOCATION carries the name at the same offset, so it is a song")
    print("  record too -- the working copy of the one being edited")
    print("\n  NOT settled: the other %d bytes of a record, and PERFORMANCE"
          % (LOCATION_LEN - NAME_LEN))
    print("OK")


if __name__ == "__main__":
    main()
