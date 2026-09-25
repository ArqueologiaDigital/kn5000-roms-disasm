#!/usr/bin/env python3
r"""Reader-derived headers for five small prom_a tables the census flags as embedded in code.

QUESTION THIS ANSWERS
    BitMask16ByIndex, BitMask32ByIndex, MidiIn_SystemSubTable,
    MidiIn_ChannelStatusTable and IndexTable_F96151 sit between two code runs
    with no header of their own, which is the census's EMBEDDED-IN-CODE shape
    (undecoded code under a table name).  Each one's reader is located and its
    bytes asserted here; the header written says what the table is, its index,
    its count and how the count is pinned.

CHECKS (against wsa1/original_ROMs)
    H1  IndexToBitMask16 (0xF8A944): `cp E,0x10` / `sla 1,E` / `ld XIX,0xF8A95B` /
        `ld DE,(XIX+E)`; IndexToBitMask32 (0xF8A97D): `cp E,0x20` / `sla 2,E` /
        `ld XIX,0xF8A994` / `ld XDE,(XIX+E)`; the tables hold 1 << (k-1), 0 first
    H2  MidiIn_SystemMessage (0xFA614B): `ld L,(0x1940) / and L,0x0F / sla 2,L /
        ld XIZ,0xFA6164 / ld XIZ,(XIZ+HL) / call (XIZ)`
    H3  0xFA6225: `ld L,(0x1940) / and L,0x70 / srl 2,HL / ld XIX,0xFA6242 /
        ld XIX,(XIX+HL) / call (XIX)`
    H4  0xF960FE: `ld XHL,0xF96151` then `ld W,(XHL+) / cp W,D / jr z / cp W,0xFF /
        jr nz`; the table is 0x00..0x1F then 0xFF

RUN
    python3 notes/proma-2026-09-25/gen_small_headers.py          # checks
    python3 notes/proma-2026-09-25/gen_small_headers.py --apply  # ran once
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE


def at(r, a, h):
    return r[a - B:a - B + len(bytes.fromhex(h))] == bytes.fromhex(h)


def checks(r):
    assert at(r, 0xF8A945, "cdcf10") and at(r, 0xF8A94C, "cdec01") and at(r, 0xF8A94F, "445ba9f800")
    assert at(r, 0xF8A954, "d303f0e822")
    assert at(r, 0xF8A97E, "cdcf20") and at(r, 0xF8A985, "cdec02") and at(r, 0xF8A988, "4494a9f800")
    assert at(r, 0xF8A98D, "e303f0e822")
    t16 = [int.from_bytes(r[0xF8A95B - B + 2 * k:0xF8A95B - B + 2 * k + 2], "little") for k in range(17)]
    t32 = [int.from_bytes(r[0xF8A994 - B + 4 * k:0xF8A994 - B + 4 * k + 4], "little") for k in range(33)]
    assert t16 == [0] + [1 << k for k in range(16)] and t32 == [0] + [1 << k for k in range(32)]
    print("H1 ok: the 16/32-bit one-hot tables and their readers")
    assert at(r, 0xFA614B, "c14019 27cfcc0fcfec02db12466461fa00e307f8ec26b6e8".replace(" ", ""))
    print("H2 ok: MidiIn_SystemMessage indexes by the status byte's low nibble")
    assert at(r, 0xFA6225, "c1401927cfcc70dbef024442 62fa00e307f0ec24b4e8".replace(" ", ""))
    print("H3 ok: 0xFA6225 indexes by the status byte's bits 4-6")
    assert at(r, 0xF960FE, "435161f900832 0eb61ccf06607c8cfff6ef3".replace(" ", ""))
    assert r[0xF96151 - B:0xF96172 - B] == bytes(range(32)) + b"\xff"
    print("H4 ok: 0xF960FE scans IndexTable_F96151 (0x00..0x1F, 0xFF) for D")


HDR = {
    "BitMask16ByIndex": [
        "; BitMask16ByIndex -- 17 x u16: 0, then 1<<0 .. 1<<15 (entry k = 1 << (k-1)).",
        "; Read by: IndexToBitMask16 (0xF8A944): `cp E,0x10 / jr ule / xor E,E /",
        ";          sla 1,E / ld XIX,<this> / ld DE,(XIX+E)`.  COUNT 17 = that",
        ";          bound + 1.  (notes/proma-2026-09-25/gen_small_headers.py, H1)",
    ],
    "BitMask32ByIndex": [
        "; BitMask32ByIndex -- 33 x u32: 0, then 1<<0 .. 1<<31 (entry k = 1 << (k-1)).",
        "; Read by: IndexToBitMask32 (0xF8A97D): `cp E,0x20 / jr ule / xor E,E /",
        ";          sla 2,E / ld XIX,<this> / ld XDE,(XIX+E)`.  COUNT 33 = that",
        ";          bound + 1.  Also copied at BitMask32ByIndex_Copy and",
        ";          BitMask32ByIndex_DeadCopy.  (gen_small_headers.py, H1)",
    ],
    "MidiIn_SystemSubTable": [
        "; MidiIn_SystemSubTable -- 16 LE32 handlers, one per MIDI SYSTEM status",
        ";          0xF0-0xFF.",
        "; Read by: MidiIn_SystemMessage (0xFA614B, MidiIn_StatusClassTable[7]):",
        ";          `ld L,(0x1940) / and L,0x0F / sla 2,L / ld XIZ,<this> /",
        ";          ld XIZ,(XIZ+HL) / call (XIZ)` -- the status byte's low nibble,",
        ";          hence COUNT 16.  [2] 0xF2 Song Position and [3] 0xF3 Song Select",
        ";          are handled; the rest are MidiIn_SystemIgnore.",
        ";          (notes/proma-2026-09-25/gen_small_headers.py, H2)",
    ],
    "MidiIn_ChannelStatusTable": [
        "; MidiIn_ChannelStatusTable -- 8 LE32 handlers, one per CHANNEL message kind",
        ";          0x80-0xF0 (status bits 4-6).",
        "; Read by: 0xFA6225 `ld L,(0x1940) / and L,0x70 / srl 2,HL / ld XIX,<this> /",
        ";          ld XIX,(XIX+HL) / call (XIX)` -- (status & 0x70) / 4, hence",
        ";          COUNT 8.  [3] 0xB0 Control Change, [4] 0xC0 Program Change,",
        ";          [5] 0xD0 Channel Pressure, [6] 0xE0 Pitch Bend; note on/off,",
        ";          polyphonic aftertouch and [7] are MidiIn_ChannelIgnore.",
        ";          (notes/proma-2026-09-25/gen_small_headers.py, H3)",
    ],
    "IndexTable_F96151": [
        "; IndexTable_F96151 -- the byte list 0x00..0x1F, then an 0xFF terminator.",
        "; Read by: the loop at 0xF960FE: `ld XHL,<this>`, then `ld W,(XHL) / inc XHL",
        ";          / cp W,D / jr z` -> sub_F96172, else `cp W,0xFF / jr nz` -- a",
        ";          membership test of D.  A D not in the list is stored with E and",
        ";          A straight into the 0x2C00 queue (0xF96117-0xF96121), so the list",
        ";          names the 32 values that get sub_F96172 instead -- the part",
        ";          numbers, when D is a parameter number as in that queue.",
        ";          COUNT 33 = 32 values + the terminator the loop stops on.",
        ";          (notes/proma-2026-09-25/gen_small_headers.py, H4)",
    ],
}


def apply():
    m = srcmap.load()
    L = m.lines
    dash = "; ---------------------------------------------------------------------"
    for name, hdr in HDR.items():
        i = next(k for k, l in enumerate(L) if re.match(r"^%s:" % name, l))
        assert L[i - 1] != dash, name
        L[i:i] = [dash] + hdr + [dash]
    open(srcmap.SRC, "wb").write("\n".join(L).encode("latin-1"))
    print("applied")


if __name__ == "__main__":
    checks(open(srcmap.ROM, "rb").read())
    if "--apply" in sys.argv:
        apply()
