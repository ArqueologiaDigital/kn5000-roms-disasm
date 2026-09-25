#!/usr/bin/env python3
r"""Correct the remaining "no reader" / "no field identified" claims in prom_d.

QUESTION THIS ANSWERS
    After the index maps (prom_d_index_maps.py) and descriptor arrays
    (prom_d_descriptors.py), which prom_d banners still assert an absence the
    firmware contradicts, and what is the evidence for each correction?

      * ToneDB_MixerDefaultTable (+0x18) and ToneDB_PercMixerDefaultTable
        (+0x20): "Readers: NONE", "NOTHING in the WSA1 firmware confirms it",
        "NO reader was found for THIS array".  The reader is
        ToneDB_ResolveWaveSelectRecord (prom_c 0xFB82C3): `ld XIY,(XBC+0x18)`
        at 0xFB836F, `(XBC+0x1c)` at 0xFB83CC, `(XBC+0x20)` at 0xFB839E, the
        stride words +0xEA / +0xF0 at 0xFB837A / 0xFB83A9.
      * ToneDB_Directory: "13 of the 39 filled primary slots have no reader at
        all" and "no FIELD inside any record these slots point at is
        identified by anything".  The 13 are +0x0C +0x10 +0x14 +0x18 +0x1C
        +0x20 +0x24 +0x28 +0x2C +0x30 +0x34 +0x38 (the two resolvers) and
        +0x48 / +0x5C (0xFC0435 / 0xFC05C3); fields are named by the wave-17
        block of prom_d/wsa1_prom_d.s.
      * PercInst (+0x78) and PercInst_Template_Silent (+0xB4): "+0x0D 137 B
        parameters, unidentified", and the 504 per-record lines "137 bytes of
        parameters, none identified".  prom_c copies 0x40 bytes of the record
        (`push 0x0040` 0xFB85F4) and then two 43-byte wave-select records from
        +0x40 + 43*j, j < 2 (`add XWA,0x000004a1` 0xFB868F against the 0x461
        base, `cp (XIZ+0xf3),0x02` 0xFB897D); 64 + 2*43 = 150.

    Every cited encoding is asserted; --apply makes the edits.

RUN
    python3 notes/lanes/promcd-2026-09-25/prom_d_reader_corrections.py          # checks
    python3 notes/lanes/promcd-2026-09-25/prom_d_reader_corrections.py --apply  # + edit
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
W = os.path.join(ROOT, "wsa1")
C = open(os.path.join(W, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
AUX = os.path.join(W, "prom_d", "tone_database_aux.s")
DIRF = os.path.join(W, "prom_d", "tone_database_directory.s")

CODE = [(0xFB836F, "a9 18 25"), (0xFB83CC, "a9 1c 25"), (0xFB839E, "a9 20 25"),
        (0xFB837A, "d3 e5 ea 00 20"), (0xFB83A9, "d3 e5 f0 00 20"),
        (0xFC0435, "a9 48 20"), (0xFC05C3, "a9 5c 20"),
        (0xFB85F4, "0b 40 00"), (0xFB868F, "e8 c8 a1 04 00 00"), (0xFB897D, "8e f3 3f 02")]


def none_para(slot):
    return ("; ⚠ Readers: NONE IN THE CENSUS.  notes/prom_d_documentation_round3.py\n"
            "; walks every load of prom_d's base (0x00F00000, RAM 0x00D7ED /\n"
            "; 0x00D7F1) in prom_c and every directory slot read through it -- 99\n"
            "; reads over 33 slots -- and directory slot +0x%02X is not among them.\n"
            "; The census is a LOWER BOUND: by its own rule it does not follow a\n"
            "; base parked in a frame slot.\n"
            "; So this region's NAME is still the KN5000 transplant and NOTHING in\n"
            "; the WSA1 firmware confirms it.\n"
            "; \n"
            "; ⚠ NO reader was found for THIS array.  What follows is about the\n"
            "; array at slot +0x3C, which has the same record shape, and is quoted\n"
            "; as corroboration for the 43 -- not as evidence about this block.\n" % slot)


def new_para(slot, sites):
    return ("; ★ READER (corrected 2026-09-25, lane promcd -- this paragraph said there\n"
            "; was none, that nothing confirmed the name, and that it lacked a reader).\n"
            "; ToneDB_ResolveWaveSelectRecord (prom_c 0xFB82C3) reads this slot %s,\n"
            "; multiplies the index-map value by the stride word and adds the base: this\n"
            "; array's record n is the wave-select record a wave selector resolves to (see\n"
            "; ToneDB_ToneIndexMapA's banner).  Round 3's base-load census missed it\n"
            "; because that routine parks the base in a frame slot first.\n"
            "; What follows is about the array at slot +0x3C, which has the same record\n"
            "; shape, and is quoted as further corroboration for the 43.\n" % sites)


DIR_OLD = ("; ⚠ WHAT IS STILL NOT ESTABLISHED: 13 of the 39 filled primary slots have no\n"
           "; reader at all -- they are named on each banner, and every one of them\n"
           "; keeps its transplanted name on that basis.  And no FIELD inside any\n"
           "; record these slots point at is identified by anything.\n")
DIR_NEW = ("; ★ CORRECTED 2026-09-25 (lane promcd).  This paragraph said 13 of the 39\n"
           "; filled primary slots lacked any reader and that no field of any record\n"
           "; had been read.  All 13 have one now: +0x0C/+0x10/+0x14 and +0x18/+0x1C/+0x20\n"
           "; ToneDB_ResolveWaveSelectRecord (prom_c 0xFB82C3), +0x24/+0x28/+0x2C and\n"
           "; +0x30/+0x34/+0x38 ToneDB_ResolveEnvDescriptor (0xFB45C0), +0x48 at 0xFC0435\n"
           "; and +0x5C at 0xFC05C3 (ToneQuery_ReplySourceName1/2_ViaIndexMap) -- each\n"
           "; banner cites its own.  Fields read by the firmware are listed, with the\n"
           "; instruction for each, in prom_d/wsa1_prom_d.s's wave-17 block; most other\n"
           "; bytes still carry no name.\n")
LAYOUT_OLD = ";     +0x0D 137 B   parameters, unidentified\n"
LAYOUT_NEW = (";     +0x0D  51 B   head, no field named\n"
              ";     +0x40  43 B   wave-select record 0 \\ prom_c copies 0x40 bytes of head\n"
              ";     +0x6B  43 B   wave-select record 1 / (0xFB85F4), then 43*j, j < 2\n"
              ";                   (0xFB868F, 0xFB897D); 64 + 2*43 = 150.  Corrected\n"
              ";                   2026-09-25, lane promcd: this gave 137 undivided bytes.\n")
REC_OLD = "; 150 B: 13-byte name then 137 bytes of parameters, none identified.\n"
REC_NEW = "; 150 B: 13-byte name, 51 unnamed bytes, two 43-byte wave-select records at +0x40/+0x6B.\n"


def check():
    for a, enc in CODE:
        want = bytes.fromhex(enc.replace(" ", ""))
        got = C[a - 0xF80000:a - 0xF80000 + len(want)]
        assert got == want, "prom_c 0x%06X: %s want %s" % (a, got.hex(" "), enc)
    print("  %d cited encodings hold" % len(CODE))


def apply():
    src = open(AUX, "rb").read().decode("utf-8")
    if "READER (corrected 2026-09-25, lane promcd" in src:
        sys.exit("already applied")
    for slot, sites in ((0x18, "with `ld XIY,(XBC+0x18)` at 0xFB836F (its +0x1C alias at\n; 0xFB83CC), stride +0xEA at 0xFB837A"),
                        (0x20, "with `ld XIY,(XBC+0x20)` at 0xFB839E, stride +0xF0 at\n; 0xFB83A9")):
        old = none_para(slot)
        assert src.count(old) == 1, hex(slot)
        src = src.replace(old, new_para(slot, sites))
    assert src.count(LAYOUT_OLD) == 2
    src = src.replace(LAYOUT_OLD, LAYOUT_NEW)
    assert src.count(REC_OLD) == 504
    src = src.replace(REC_OLD, REC_NEW)
    open(AUX, "wb").write(src.encode("utf-8"))
    d = open(DIRF, "rb").read().decode("utf-8")
    assert d.count(DIR_OLD) == 1
    open(DIRF, "wb").write(d.replace(DIR_OLD, DIR_NEW).encode("utf-8"))
    print("applied: 2 array banners, 2 layout tables, 504 record lines, the directory banner")


if __name__ == "__main__":
    check()
    print("ALL CHECKS HOLD")
    if "--apply" in sys.argv:
        apply()
