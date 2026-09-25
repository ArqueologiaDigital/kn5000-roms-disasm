#!/usr/bin/env python3
r"""Correct the P7 value tables' "layout NOT established" lines from their reader.

QUESTION THIS ANSWERS
    The seven data objects in prom_c's P7 pool (0xFD06FA, 0xFD28C7, 0xFD3B60,
    0xFD4E13, 0xFDA4E7/0xFDA554/0xFDA5C1) each said "Its internal layout is NOT
    established" (and 0xFD06FA that its ELEMENT SIZE "is not proved by any
    instruction").  Their reader is P7Unit_SendValueTable (prom_c 0xF9F765),
    decoded in prom_c/p7/p7_module.s: byte 0 is a BASE INDEX (`ld A,(XBC)` at
    0xF9F7D5), the rest 24-bit big-endian values read by Stream_ReadU24BE
    (`calr` at 0xF9F84F), four per pass (`divs WA,0x000c` at 0xF9F7F9), the
    first sent to device index base + 4*pass.  This script asserts those
    encodings and rewrites the stale lines (--apply).

RUN
    python3 notes/lanes/promcd-2026-09-25/p7_value_tables.py [--apply]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
C = open(os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
SRC = os.path.join(ROOT, "wsa1", "prom_c", "p7", "p7_stream_pool.s")
CODE = [(0xF9F7D5, "81 21"), (0xF9F7F9, "d8 0b 0c 00"), (0xF9F84F, "1e ce e7")]
NEW = (";      Layout (corrected 2026-09-25, lane promcd -- this line said it was not\n"
       ";      established): a P7 VALUE TABLE.  Byte 0 is a base device index and the rest\n"
       ";      24-bit big-endian values; P7Unit_SendValueTable (0xF9F765) sends them four\n"
       ";      per pass (`divs WA,0x000c` 0xF9F7F9, Stream_ReadU24BE 0xF9F84F), the first of\n"
       ";      each four to index base + 4*pass.  See P7ValueTable in the banner at the top.\n")
OLD1 = ";      Its internal layout is NOT established.\n"
OLD2 = (";      step and the symmetry are in the bytes; the ELEMENT SIZE is not proved by\n"
        ";      any instruction, so this is an observation, not a decode.\n")
NEW2 = (";      step and the symmetry are in the bytes.  (Corrected 2026-09-25, lane promcd:\n"
        ";      this said the ELEMENT SIZE was not proved by any instruction.  It is three\n"
        ";      bytes, the width P7Unit_SendValueTable reads with Stream_ReadU24BE at\n"
        ";      0xF9F84F -- see the Layout line below.)\n" + NEW)

OLD3 = "\t;           A second entry point into this object; its own extent is not established.\n"
NEW3 = ("\t;           A second entry point into this object.  Its extent is 109 bytes, 1 + the\n"
        "\t;           0x6C length P7Unit_SelectStreamsForRecord installs beside the pointer --\n"
        "\t;           the three 109-byte tables tile the 327-byte object exactly (banner at the\n"
        "\t;           top, P7ValueTable).  Corrected 2026-09-25, lane promcd: this line said the\n"
        "\t;           extent was not established.\n")


if __name__ == "__main__":
    for a, enc in CODE:
        want = bytes.fromhex(enc.replace(" ", ""))
        assert C[a - 0xF80000:a - 0xF80000 + len(want)] == want, hex(a)
    print("  %d cited encodings hold" % len(CODE))
    if "--apply" in sys.argv:
        s = open(SRC, "rb").read().decode("latin-1")
        if s.count(OLD1) == 4 and s.count(OLD2) == 1:
            s = s.replace(OLD1, NEW).replace(OLD2, NEW2)
        # second pass (added the same session): the two inner entry points
        if s.count(OLD3) == 2:
            s = s.replace(OLD3, NEW3)
        data = s.encode("latin-1")
        open(SRC, "wb").write(data)
        print("applied: 5 objects")
