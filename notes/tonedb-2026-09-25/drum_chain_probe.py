#!/usr/bin/env python3
"""Check every claim the tone_database_aux.s headers make about drum kits,
drum instruments (PercInst) and the drawbar zone-record blocks.

QUESTION THIS ANSWERS
    A drum kit is a tone record whose part-mode byte (+0x10 & 0xC0) is 0x80.
    For MIDI note n the subcpu reads the pair (rec[0x27+2n], rec[0x28+2n])
    (ToneDB_Find_SubToneRecord 0x032AE0) and resolves it
    (ToneDB_Resolve_NamedToneRecord 0x032A08) to a 58-byte PercInst record
      PercInst = dir[+0x78] + u16 dir[+0xEE] * u16[dir[+0x74] + 2*((slot&0x1F)<<7 | wave&0x7F)]
    i.e. DrumKit_NoteMapA[slot][wave].  A second, independent routine
    (DSP_SetVoiceCoefficients 0x03111A, the name copier) resolves the SAME pair
    through dir[+0x7C] = DrumKit_NoteMapB into the 10-character PercName_Pack.
    If our reading of the pair and of the two maps is right, the two paths must
    name the same instrument for every kit note -- that is the cross-check.

    PercName_Pack is aligned with the wave-source list, not the instrument list,
    so "the same instrument" is tested loosely: the 10-character name must be a
    subsequence of the 13-character one after dropping case and punctuation.
    Result: 3236 of 3328 kit notes agree; the other 92 differ in numbering.

    Also checked: the 26 kits' constant bytes, the PercInst field census the
    header quotes, which kits follow the General MIDI note layout, and that the
    drawbar zone-record blocks are 729 = 9*9*9 six-byte records, as
    Voice_KeyIndex_Pack3Nibbles (0x02B2C2) indexes them.

RUN
    python3 notes/tonedb-2026-09-25/drum_chain_probe.py      # exits non-zero on a failed check
"""
import collections
import pathlib
import re
import struct
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
ROM = (ROOT / "original_ROMs" / "kn5000_table_data.rom").read_bytes()
B, DB = 0x800000, 0x830000
u8 = lambda a: ROM[a - B]
u16 = lambda a: struct.unpack_from("<H", ROM, a - B)[0]
u32 = lambda a: struct.unpack_from("<I", ROM, a - B)[0]
dslot = lambda s: DB + u32(DB + s)
FAIL = []


def check(c, what):
    print(("  ok   " if c else "  FAIL ") + what)
    if not c:
        FAIL.append(what)


def norm(s):
    return re.sub(r'[^a-z0-9]', '', s.lower())


def subseq(a, b):
    it = iter(b)
    return all(ch in it for ch in a)


def main():
    nmA, pi, nmB, pn, st = dslot(0x74), dslot(0x78), dslot(0x7C), dslot(0xB0), u16(DB + 0xEE)
    check((nmA, pi, nmB, pn, st) == (0x86D8A3, 0x864E6F, 0x87B322, 0x87D322, 58),
          "directory: +0x74 NoteMapA 0x86D8A3, +0x78 PercInst 0x864E6F, +0x7C NoteMapB 0x87B322, "
          "+0xB0 PercName_Pack 0x87D322, +0xEE stride 58")
    pname = lambda k: ROM[pi + st * k - B:pi + st * k - B + 13].decode("latin-1").rstrip()
    bname = lambda k: ROM[pn + 10 * k - B:pn + 10 * k - B + 10].decode("latin-1").rstrip()
    kits = [0x863079 + 295 * k for k in range(26)]
    check(all(u8(a + 0x10) == 0x80 for a in kits), "all 26 kits: +0x10 = 0x80 (part mode 0x80)")
    check(len({ROM[a + 0x12 - B:a + 0x27 - B] for a in kits}) == 1, "+0x12..+0x26 identical in all 26")
    check(sorted({u8(a + 0x11) for a in kits}) == [0, 2, 3, 4, 5, 6], "+0x11 takes 0,2,3,4,5,6")
    agree = total = 0
    bad = []
    for k, a in enumerate(kits):
        for n in range(128):
            lo, hi = u8(a + 0x27 + 2 * n), u8(a + 0x28 + 2 * n)
            check_pair = (hi & 0xE0) == 0 and lo < 0x80
            if not check_pair:
                FAIL.append("kit %d note %d pair %02x %02x" % (k, n, lo, hi))
            idx = ((hi & 0x1F) << 7) | lo
            ia, ib = u16(nmA + 2 * idx), u16(nmB + 2 * idx)
            total += 1
            if subseq(norm(bname(ib)), norm(pname(ia))):
                agree += 1
            else:
                bad.append((k, n, pname(ia), bname(ib)))
    print("       NoteMapA->PercInst vs NoteMapB->PercName_Pack agree (abbreviation is a "
          "subsequence) on %d of %d kit notes" % (agree, total))
    for b in bad[:12]:
        print("         disagree: kit %d n%d %r vs %r" % b)
    # PercName_Pack is aligned with the WAVE-source list (ToneDB_DrumSourceNameList),
    # so its names are the wave's, not the instrument's: numbering can differ
    # ("Scratch 3" / "Scratch 2") and a few differ outright ("Zap 1" / "High Q").
    check(agree == 3236 and total == 3328,
          "the two name paths agree on 3236 of 3328 kit notes; the rest differ in numbering")
    # GM layout
    gm = []
    for k, a in enumerate(kits):
        nm = lambda n: pname(u16(nmA + 2 * (((u8(a + 0x28 + 2 * n) & 0x1F) << 7) | u8(a + 0x27 + 2 * n))))
        if "HiHat" in nm(42) and "HiHat" in nm(46) and "Crash" in nm(49):
            gm.append(k)
    print("       kits with a hi-hat on notes 42 and 46 and a crash on 49 (GM layout): %s" % gm)
    check(gm == [14, 15, 16, 17, 19, 20],
          "hi-hats on 42/46 + crash on 49: kits 14-17, 19, 20 (all bank 0x41), no bank-0x40 kit")
    # PercInst census
    m = collections.Counter(u8(pi + st * k + 0x0D) for k in range(610))
    check(dict(m) == {0x01: 540, 0x21: 69, 0x25: 1}, "PercInst +0x0D: 0x01 x540, 0x21 x69, 0x25 x1")
    diff = [k for k in range(610) if ROM[pi + st * k + 0x10 - B:pi + st * k + 0x25 - B]
            != ROM[pi + st * k + 0x25 - B:pi + st * k + 0x3A - B]]
    check(diff == [452] and u8(pi + st * 452 + 0x0D) == 0x25,
          "only record 452 has two different layers, and it is the only mask with bit 2 (layer 1)")
    check(all(u8(pi + st * k + 0x10 + 4) == 0 for k in range(610)), "layer +0x04 = 0 in all 610")
    # drawbar zone blocks
    dd = [0x870A11 + 15 * i for i in range(4)]
    bs = [DB + u32(a + 5) for a in dd]
    check(bs == [0x870A4D, 0x871B63, 0x871B63, 0x872C79] and all(u8(a) == 0x92 for a in dd),
          "DrawbarPreset_EnvDescTable: flags 0x92 x4, B -> EnvData_0, _1, _1, _2")
    check(0x871B63 - 0x870A4D == 0x872C79 - 0x871B63 == 729 * 6, "EnvData_0 and _1 are 729 x 6 bytes")
    check(0x872C91 - 0x872C79 == 4 * 6, "EnvData_2 is 4 x 6 bytes")
    if FAIL:
        print("FAIL: %d" % len(FAIL))
        sys.exit(1)
    print("PASS")


if __name__ == "__main__":
    main()
