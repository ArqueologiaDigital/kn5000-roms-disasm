#!/usr/bin/env python3
"""Is prom_b 0xF6F530-0xF6F7xx a STANDARD MIDI FILE header parser?  Yes -- and
this is the evidence, re-derived from the ROM on every run.

QUESTION IT ANSWERS
  Round 6 converted 0xF6D002-0xF77FFF and left every routine in it `sub_XXXXXX`,
  which is this lane's rule.  But one object in it is identified beyond argument
  and the identification is worth writing down separately from the names: the
  block reads a **Standard MIDI File**, and it does the SMF specification's own
  header validation, field by field.

  Every assertion below is checked against the ROM.  Nothing is typed twice: the
  addresses are the script's data and the decode is unidasm's.

WHAT IS ESTABLISHED (each is a check; `--list` prints them all)
  1. 0xF6F528 holds the eight bytes `MThdMTrk` -- the SMF header-chunk tag
     followed by the track-chunk tag, 4 + 4, used as two compare templates.
  2. A 1,024-byte sliding window at 0x60A700-0x60AAFF is the input buffer.  Its
     cursor is the 32-bit RAM word (0x1088); 0xF7138F is the byte fetch
     (`ld XIX,(0x1088) / ld A,(XIX+)`) and it refills through 0xF765D4 when the
     cursor passes 0x60AAFF.
  3. The `MThd` compare: `ld BC,0x0004` / `ld XIY,0x00f6f528` / fetch /
     `cp A,(XIY+)` / `djnz BC`.  On the first mismatch the reader RETRIES ONCE at
     0x60A700 + 0x80; on the second it stops with 0x31 in (0x2880).
  4. The six header fields land in six RAM bytes, big-endian pairs:
       format   (0x1079) high, (0x1078) low
       ntrks    (0x107B) high, (0x107A) low
       division (0x107D) high, (0x107C) low
  5. The SMF spec's own three rejections are all implemented:
       * `bit 0x07,A` on the division HIGH byte, `jrl NZ` to the error path --
         a negative division is SMPTE timecode, which this reader refuses;
       * division low word == 0 -> error 0x30 in (0x2880);
       * format must be 0 or 1 -- `cp (0x1078),0x0000` accepts, then
         `cp (0x1078),0x0001` and `jrl NZ` to the error path.
  6. `ld XIY,0x00f6f52c` -- 0xF6F528 + 4, i.e. `MTrk` -- starts the track-chunk
     tag compare, same 4-byte shape.
  7. 0xF7661E-0xF7662C writes 0x4D 0x49 0x44 -- `M` `I` `D` -- into
     (0x21D0),(0x21D1),(0x21D2), an 8.3 filename EXTENSION field.

WHAT IS **NOT** ESTABLISHED, AND IS NOT CLAIMED
  * WHERE the bytes come from.  The refill path leaves prom_b through
    T_F425A8/T_F425B0/T_F425E8 -> prom_a 0xFE1C3A/0xFE1C55/0xFE1CB3, all of which
    are `sub_` in prom_a.  The floppy is the obvious candidate and this script
    does not assert it.
  * WHOSE buffer 0x60A700 is.  It lies inside the 0x60A000 region prom_a's
    block/remote reader passes as a destination (`lda_24 XBC,(0x60a000)` at 14
    sites in prom_a).  That is an ADJACENCY, not a proof that the same transfer
    fills it.
  * What (0x2880) is besides a place three different byte values are written.

RUN
    python3 notes/prom_b_smf_reader.py            # the checks
    python3 notes/prom_b_smf_reader.py --list     # every check, passing or not
Exit status is non-zero if any check fails.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_module_trace as MT                                   # noqa: E402

IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
B_BASE = 0xF00000
ROM = open(IMG, "rb").read()
FAIL = []

# (address, exact MAME text the instruction there must decode to)
INSTRUCTIONS = [
    (0xF6F58F, "ld XWA,0x0060a700"),        # window base -> cursor
    (0xF6F594, "ld (0x1088),XWA"),
    (0xF6F598, "ld BC,0x0004"),             # four bytes of `MThd`
    (0xF6F59B, "ld XIY,0x00f6f528"),
    (0xF6F5A2, "calr 0xf7138f"),            # fetch one byte
    (0xF6F5A7, "cp A,(XIY+)"),
    (0xF6F5D0, "djnz BC,0xf6f5a0"),
    (0xF6F5B7, "ld XWA,0x0060a700"),        # the single retry, at +0x80
    (0xF6F5BC, "add XWA,0x00000080"),
    (0xF6F5C8, "ld (0x2880),0x31"),         # give up
    (0xF6F5D3, "ld BC,0x0005"),             # skip the 4-byte length, keep byte 5
    (0xF6F5DE, "ld (0x1079),A"),            # format high
    (0xF6F5E5, "ld (0x1078),A"),            # format low
    (0xF6F5EC, "ld (0x107b),A"),            # ntrks high
    (0xF6F5F3, "ld (0x107a),A"),            # ntrks low
    (0xF6F5FA, "ld (0x107d),A"),            # division high
    (0xF6F5FE, "bit 0x07,A"),               # ... and reject SMPTE
    (0xF6F601, "jrl NZ,0xf6f7d8"),
    (0xF6F607, "ld (0x107c),A"),            # division low
    (0xF6F60B, "cp (0x107c),0x0000"),
    (0xF6F613, "ld (0x2880),0x30"),         # division 0 -> error
    (0xF6F61E, "cp (0x1078),0x0000"),       # format 0 ok
    (0xF6F626, "cp (0x1078),0x0001"),       # format 1 ok
    (0xF6F62C, "jrl NZ,0xf6f7d8"),          # anything else -> error
    (0xF6F655, "ld BC,0x0004"),             # four bytes of `MTrk`
    (0xF6F658, "ld XIY,0x00f6f52c"),
    (0xF7138F, "push XIX"),                 # the byte fetch
    (0xF71390, "ld XIX,(0x1088)"),
    (0xF71394, "ld A,(XIX+)"),
    (0xF7139C, "cp XIX,0x0060aaff"),        # window top
    (0xF713A7, "calr 0xf765d4"),            # refill
    (0xF6FD96, "ld XIX,(0x1088)"),          # the other bound check
    (0xF6FD9E, "cp XIX,0x0060aaff"),
    (0xF7661E, "ld (0x21d0),0x4d"),         # 'M'
    (0xF76623, "ld (0x21d1),0x49"),         # 'I'
    (0xF76628, "ld (0x21d2),0x44"),         # 'D'
]


def c(name, got, want):
    ok = got == want
    if not ok:
        FAIL.append(name)
    if not ok or "--list" in sys.argv:
        print("  %-62s %s" % (name, "PASS" if ok else "FAIL got=%r want=%r"
                              % (got, want)))
    return ok


def main():
    c("0xF6F528 holds the eight bytes `MThdMTrk`",
      ROM[0xF6F528 - B_BASE:0xF6F530 - B_BASE], b"MThdMTrk")
    c("  and 0xF6F52C, the second compare template, is `MTrk`",
      ROM[0xF6F52C - B_BASE:0xF6F530 - B_BASE], b"MTrk")
    c("the window is 0x60A700-0x60AAFF, i.e. 1024 bytes",
      0x60AAFF - 0x60A700 + 1, 0x400)
    for a, want in INSTRUCTIONS:
        dec = MT.decode_at(a)
        c("0x%06X decodes to `%s`" % (a, want),
          dec[1].strip() if dec else None, want)
    # LAST-ELEMENT TEST: the final citation in the list is checked and named, so
    # "the checks passed" cannot mean "the loop stopped early".
    a, want = INSTRUCTIONS[-1]
    dec = MT.decode_at(a)
    c("LAST citation (0x%06X `%s`) checked" % (a, want),
      dec[1].strip() if dec else None, want)
    print("\n%s (%d of %d failed)"
          % ("SMF CHECKS PASS" if not FAIL else "SMF CHECKS FAIL",
             len(FAIL), len(INSTRUCTIONS) + 4))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
