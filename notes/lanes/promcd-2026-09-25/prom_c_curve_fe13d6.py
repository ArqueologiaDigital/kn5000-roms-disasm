#!/usr/bin/env python3
r"""Pin the entry count of prom_c's Curve_FE13D6 from its reader, and say how it is used.

QUESTION THIS ANSWERS
    wsa1/prom_c/data_tables/tail_data_zone.s said of Curve_FE13D6 (0xFE13D6,
    202 bytes): "101 entries is the extent between two cited bases; no reader
    clamp was located".  The clamp is in its one reader, sub_FC35DB (prom_c
    0xFC35DB, in prom_c/field_accessors.s), 26 bytes before the table access:

        0xFC363A  ld XBC,(XDE+0x17)      a record pointer from voice +0x17
        0xFC363D  ld A,(XBC+0x29)        its byte +0x29
        0xFC3645  ld C,(XIX+0x09)        + a signed byte of the record at (0xDF05 + 4*voice[0])
        0xFC364E  cp HL,0x0064 / jr LE    > 100 -> 100   (0xFC3654 ld HL,0x0064)
        0xFC3657  cp HL,0 / jr GE         < 0   -> 0     (0xFC365B ld HL,0x0000)
        0xFC365E  ld BC,2 / muls XBC,HL   2 bytes an entry
        0xFC3663  add XBC,0x00fe13d6      + this table
    so the index runs 0..100: 101 u16, exactly the extent.  The value read is
    then multiplied (Multiply32, 0xFC3676) by the INTT1 ticks elapsed since a
    stored timestamp (0x00F2F3 minus record +0x12, clamped to 0x7FFF at
    0xFC3616-0xFC3635), shifted right 10 (0xFC367C), and subtracted from the
    voice's word +0x0D (0xFC3696) -- or, if the product exceeds 0xFFF
    (0xFC3681), +0x0D is set to 0xC000 (0xFC368B).  So entry k is a RATE per
    tick for setting k of a 0..100 parameter: 0xFFFF (fastest) for k <= 3,
    falling to 1 at k = 100.

    This script asserts every cited encoding against wsa1/original_ROMs and
    that the table is monotone non-increasing, and --apply corrects the header.

RUN
    python3 notes/lanes/promcd-2026-09-25/prom_c_curve_fe13d6.py [--apply]
"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
C = open(os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
SRC = os.path.join(ROOT, "wsa1", "prom_c", "data_tables", "tail_data_zone.s")
CODE = [(0xFC363A, "aa 17 21"), (0xFC363D, "89 29 21"), (0xFC3645, "8c 09 23"),
        (0xFC364E, "db cf 64 00"), (0xFC3654, "33 64 00"), (0xFC3657, "db d8"),
        (0xFC365B, "33 00 00"), (0xFC365E, "31 02 00"), (0xFC3661, "db 49"),
        (0xFC3663, "e9 c8 d6 13 fe 00"), (0xFC3676, "1d 1b b1 fc"), (0xFC367C, "ed ef 0a"),
        (0xFC3681, "ed cf ff 0f 00 00"), (0xFC368B, "ba 0d 02 00 c0"), (0xFC3696, "9a 0d a9"),
        (0xFC3619, "e2 f3 f2 00 20")]
OLD = "; ⚠ 101 entries is the extent between two cited bases; no reader clamp was located.\n"
NEW = ("; COUNT 101, from the reader's clamp (corrected 2026-09-25, lane promcd: this line\n"
       "; said the clamp had not been located).  sub_FC35DB (0xFC35DB) forms the index as\n"
       "; byte +0x29 of the record at voice+0x17 (0xFC363A/0xFC363D) plus a signed byte\n"
       "; (0xFC3645), clamps it to 0..100 (`cp HL,0x0064` 0xFC364E, `cp HL,0` 0xFC3657),\n"
       "; and reads T[index] (0xFC365E-0xFC3663).  It multiplies T by the INTT1 ticks since\n"
       "; a stored timestamp (0x00F2F3, 0xFC3619; Multiply32 at 0xFC3676), shifts right 10\n"
       "; (0xFC367C) and subtracts the result from voice word +0x0D (0xFC3696), or sets it to\n"
       "; 0xC000 when the result exceeds 0xFFF (0xFC3681/0xFC368B).  So T[k] is a RATE per\n"
       "; tick for setting k of a 0..100 parameter, fastest at k <= 3.  (The KN5000's\n"
       "; transplant table names this offset Voice_Portamento_Rate_Table; that is its name\n"
       "; there, not a finding here.)  notes/lanes/promcd-2026-09-25/prom_c_curve_fe13d6.py\n")

if __name__ == "__main__":
    for a, enc in CODE:
        want = bytes.fromhex(enc.replace(" ", ""))
        got = C[a - 0xF80000:a - 0xF80000 + len(want)]
        assert got == want, "0x%06X %s want %s" % (a, got.hex(" "), enc)
    t = struct.unpack_from("<101H", C, 0xFE13D6 - 0xF80000)
    assert all(t[i] >= t[i + 1] for i in range(100)) and t[:4] == (0xFFFF,) * 4 and t[100] == 1
    print("  %d cited encodings hold; 101 entries, non-increasing, 0xFFFF x4 .. 1" % len(CODE))
    print("ALL CHECKS HOLD")
    if "--apply" in sys.argv:
        s = open(SRC, "rb").read().decode("utf-8")
        assert s.count(OLD) == 1
        open(SRC, "wb").write(s.replace(OLD, NEW).encode("utf-8"))
        print("applied")
