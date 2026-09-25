#!/usr/bin/env python3
r"""Evidence for the headers in <image>/maincpu/audio/sound_data.s.

QUESTION THIS ANSWERS
    What are the sixteen tables hanging off the sound-data descriptor at
    0xE023A0 (SOUND_DATA_SECTION_PTRS, slots +0x10..+0x4C), and are the
    reader-derived layouts written in sound_data.s consistent with the data?
    The layouts come from reading the readers (v10 0xFEE43F..0xFEEBE6); this
    script checks the data against them and against each other, so that a
    wrong stride, a wrong field order or a wrong pairing fails loudly.

RUN
    python3 scripts/analysis/sound_data_map_proof.py            # all three dumps
    python3 scripts/analysis/sound_data_map_proof.py --selftest # the checks can fail

WHAT IT PRINTS / ASSERTS (per image v10, v9, v7)
  * the 0xE02380..0xE0B4ED region is byte-identical in v10, v9 and v7;
  * the descriptor pointer cell: `ld xr,(0xe14e)` = bytes e1 4e e1 occurs
    14 times in v10/v9, `e1 b2 e0` (RAM 0xE0B2) 14 times in v7, and each v7
    site is the v10 site - 0x7CF (the same 14 readers, shifted);
  * slot +0x14 grid -> (program, bank) -> slot +0x10 map -> (category, slot)
    round-trips for every populated grid cell (368), likewise +0x24 -> +0x20
    in mode 1 (136);
  * slot +0x1C list -> (program, bank) -> slot +0x18 map -> voice index
    round-trips for all 128 indices, likewise +0x2C -> +0x28;
  * slot +0x3C (last-slot index per category, normal parts) sums to the +0x14
    populated count (368); +0x48 (mode 1) sums to 128, and +0x48 plus the
    drum-kit byte of +0x4C sums to the +0x24 populated count (136);
  * slots +0x1C and +0x2C: 128 pointers, 128 distinct 3-byte records
    {program, bank, 0xFF}, tiling their region exactly with nothing left.

SIGNALS
  record field order is the READERS': ApplyProgramChangeAs_LoadDRAM2 takes the
  bank from record+4 and the program from record+3 and stores the low bytes of
  record words +0/+2 into record+0/+1; FetchOscTableEntry_Prologue reads
  record+0/+1 and writes table bytes e[0]/e[1] to record+3/+4;
  SndParam_LookupOscEnvelope writes list bytes +0/+1 to record+3/+4.
"""
import argparse
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASE = 0xE00000
DESC = 0xE023A0
REGION = (0xE02380, 0xE0B4ED)
V10_READERS_CELL = bytes([0xe1, 0x4e, 0xe1])
V7_READERS_CELL = bytes([0xe1, 0xb2, 0xe0])


class Img:
    def __init__(self, rom):
        self.rom = rom

    def d(self, a, n):
        return self.rom[a - BASE:a - BASE + n]

    def ptr(self, a):
        return struct.unpack("<I", self.d(a, 4))[0]

    def slot(self, off):
        return self.ptr(DESC + off)


def bankmap(img, off, stride, bank, prog):
    """ApplyProgramChangeAs_LoadDRAM2 / ApplyProgramChange_LoadDRAM addressing."""
    base = img.slot(off)
    blk = img.d(base, 128)[bank]
    rec = img.d(base + 0x80 + blk * stride + prog * 4, 4)
    return rec[0], rec[2]


def grid(img, off, cat, slot):
    """FetchOscTableEntry_Prologue addressing: 2*(cat*40 + slot)."""
    e = img.d(img.slot(off) + 2 * (cat * 40 + slot), 2)
    return e[0], e[1]


def grid_roundtrip(img, goff, moff, stride):
    ok, bad = 0, []
    for cat in range(18):
        for s in range(40):
            p, b = grid(img, goff, cat, s)
            if (p, b) == (0, 0) and (cat, s) != (0, 0):
                continue
            if b >= 128 or bankmap(img, moff, stride, b, p) != (cat, s):
                bad.append((cat, s, p, b))
            else:
                ok += 1
    return ok, bad


def lists(img, off):
    """-> list of 128 (program, bank) from the 3-byte records, asserting the
    SndParam_LookupOscEnvelope framing and exact tiling."""
    tab = img.slot(off)
    ptrs = [img.ptr(tab + 4 * i) for i in range(128)]
    assert len(set(ptrs)) == 128, "duplicate pointers"
    pos = tab + 512
    out = {}
    for p in sorted(ptrs):
        assert p == pos, ("gap/overlap", hex(pos), hex(p))
        t = img.d(p, 3)
        assert t[2] == 0xFF, ("record without 0xFF limit", hex(p))
        out[p] = (t[0], t[1])
        pos = p + 3
    return [out[p] for p in ptrs], pos


def list_roundtrip(img, loff, moff, stride):
    pairs, end = lists(img, loff)
    ok = sum(1 for i, (p, b) in enumerate(pairs)
             if b < 128 and bankmap(img, moff, stride, b, p) == (i, 0))
    return ok, end


def last_index_sum(img, off, cats=range(18)):
    t = img.d(img.slot(off), 18)
    return sum(t[c] + 1 for c in cats if t[c] != 0xFF)


def check(img, name):
    res = {}
    res["grid+14"] = grid_roundtrip(img, 0x14, 0x10, 0x400)
    res["grid+24"] = grid_roundtrip(img, 0x24, 0x20, 0x200)
    res["list+1C"] = list_roundtrip(img, 0x1C, 0x18, 0x400)
    res["list+2C"] = list_roundtrip(img, 0x2C, 0x28, 0x200)
    res["sum+3C"] = last_index_sum(img, 0x3C)
    res["sum+48"] = last_index_sum(img, 0x48)
    res["kits+4C"] = last_index_sum(img, 0x4C)
    g14, g24 = res["grid+14"], res["grid+24"]
    assert not g14[1] and not g24[1], (name, g14[1][:4], g24[1][:4])
    assert res["list+1C"][0] == 128 and res["list+2C"][0] == 128, name
    assert res["list+1C"][1] == img.slot(0x20), "+0x1C records do not end at the next table"
    assert res["list+2C"][1] == img.slot(0x30), "+0x2C records do not end at the next table"
    assert res["sum+3C"] == g14[0], (name, res["sum+3C"], g14[0])
    assert res["sum+48"] + res["kits+4C"] == g24[0], (name, res["sum+48"], res["kits+4C"], g24[0])
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    roms = {v: open(os.path.join(ROOT, "original_ROMs", "kn5000_%s_program.rom" % v), "rb").read()
            for v in ("v10", "v9", "v7")}
    lo, hi = REGION[0] - BASE, REGION[1] - BASE
    same = {v: roms[v][lo:hi] == roms["v10"][lo:hi] for v in roms}
    print("region 0x%06X-0x%06X identical to v10:" % REGION, same)
    assert all(same.values())

    def sites(rom, pat):
        return [m.start() + BASE for m in re.finditer(re.escape(pat), rom)]
    s10, s9, s7 = sites(roms["v10"], V10_READERS_CELL), sites(roms["v9"], V10_READERS_CELL), \
        sites(roms["v7"], V7_READERS_CELL)
    print("descriptor-cell readers: v10 %d, v9 %d, v7 %d; v10-v7 deltas %s"
          % (len(s10), len(s9), len(s7), sorted(set(x - y for x, y in zip(s10, s7)))))
    assert len(s10) == len(s7) == len(s9) == 14 and s9 == s10
    assert len(set(x - y for x, y in zip(s10, s7))) == 1

    if a.selftest:
        # A corrupted grid cell must break the round trip; a shifted list must
        # break the tiling.  Built on a COPY, so the corpus stays a corpus.
        bad = bytearray(roms["v10"])
        g = Img(bytes(bad)).slot(0x14) - BASE
        bad[g] ^= 0x01
        try:
            check(Img(bytes(bad)), "corrupt-grid")
            print("SELFTEST FAIL: corrupted grid passed")
            return 1
        except AssertionError:
            pass
        bad = bytearray(roms["v10"])
        rec = Img(bytes(bad)).ptr(Img(bytes(bad)).slot(0x1C)) - BASE
        bad[rec + 2] = 0x00
        try:
            check(Img(bytes(bad)), "corrupt-list")
            print("SELFTEST FAIL: corrupted list passed")
            return 1
        except AssertionError:
            pass
        print("SELFTEST PASS: both corruptions detected")
        return 0

    for v, rom in roms.items():
        r = check(Img(rom), v)
        print("%-4s grid+0x14->+0x10 %d ok; grid+0x24->+0x20 %d ok; list+0x1C->+0x18 %d/128; "
              "list+0x2C->+0x28 %d/128; sum(+0x3C)=%d sum(+0x48)=%d kits(+0x4C)=%d"
              % (v, r["grid+14"][0], r["grid+24"][0], r["list+1C"][0], r["list+2C"][0],
                 r["sum+3C"], r["sum+48"], r["kits+4C"]))
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
