#!/usr/bin/env python3
"""Is every quantified sentence in prom_a 0xFC8000-0xFCEFFF's headers still true?

QUESTION IT ANSWERS.  The byte gate proves prom_a/wsa1_prom_a.s rebuilds the ROM
and is blind to what a comment claims.  This is the complement for the RAM-0x3800
module: each check is named after the sentence it backs, reads the ROM (and
prom_b, for the directory and the reference counts) and fails loudly.

  python3 notes/prom_a_fc8000_module_check.py
  python3 notes/prom_a_fc8000_module_check.py -v
  python3 notes/prom_a_fc8000_module_check.py --selftest

Exit status is non-zero if any check fails.  It prints its own check count as
its LAST line; that is the only figure to quote.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
import prom_a_linear_decode_check as LD                       # noqa: E402
import prom_a_ringbuf_map as MAP                              # noqa: E402

A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
A_BASE, B_BASE = 0xF80000, 0xF00000
LO, HI = 0xFC8000, 0xFCC87F          # code+data; the .fill runs on to 0xFCF000

FAILED, N = [], [0]
VERBOSE = "-v" in sys.argv


def check(name, got, want):
    N[0] += 1
    ok = got == want
    if not ok:
        FAILED.append(name)
    if VERBOSE or not ok:
        print(("  ok   " if ok else "  FAIL ") + name + ": " + repr(got) +
              ("" if ok else "   expected " + repr(want)))
    return ok


def a(x, n=1):
    return A[x - A_BASE:x - A_BASE + n]


def u32(x):
    return int.from_bytes(a(x, 4), "little")


_rows = None


def rows():
    global _rows
    if _rows is None:
        spans = [(0xFC8000, 0xFC8DB2), (0xFC8DD6, 0xFCB3D3), (0xFCC06B, 0xFCC87F)]
        _rows = []
        for lo, hi in spans:
            _rows += [r for r in LD.decode(lo, hi) if r[0] < hi]
    return _rows


def boundaries():
    return {r[0] for r in rows()}


def text_at(addr):
    for x, n, t in rows():
        if x == addr:
            return t
    return None


def thunk_slots():
    out = {}
    for off in range(0x40000, 0x44018, 4):
        if B[off] == 0x1B:
            out.setdefault(int.from_bytes(B[off + 1:off + 4], "little"),
                           []).append(0xF00000 + off)
    return out


def imm_sites(text):
    return sorted(x for x, n, t in rows() if t == text)


# =========================================================================== 1
def sec_bounds():
    print("1  MODULE BOUNDS")
    check("0xFC7000-0xFC7FFF is 4096 bytes of 0x0E",
          (set(A[0xFC7000 - A_BASE:0xFC8000 - A_BASE]), 0x1000), ({0x0E}, 4096))
    check("0xFCC87E-0xFCEFFF is 10114 bytes of 0x0E",
          (set(A[0xFCC87E - A_BASE:0xFCF000 - A_BASE]), 0xFCF000 - 0xFCC87E),
          ({0x0E}, 10114))
    check("0xFCC87D is not 0x0E", A[0xFCC87D - A_BASE] == 0x0E, False)
    check("substantive extent of the module (bytes)", HI - LO, 18559)
    check("the three CODE spans the listing declares contain no undecodable byte",
          [hex(x) for x, n, t in rows() if t == "db"], [])
    check("...so 0xFCC06A is the only one in the module outside declared data",
          [hex(x) for x, n, t in LD.decode(0xFCC06A, 0xFCC87F) if t == "db"],
          ['0xfcc06a'])


# =========================================================================== 2
def sec_init():
    print("2  THE C-RUNTIME INITIALISER -- every immediate, not a summary")
    blocks = [
        # (guard `ld XBC`, its value, source `lda XIY` or None, dest, kind)
        (0xFC8020, 0x0B66, 0xFC8029, 0xFCB3D3, 0xFC802E, 0x003800, "ldir"),
        (0xFC8035, 0x0000, None,     None,     0xFC803E, 0x000000, "zero"),
        (0xFC804E, 0x00A0, 0xFC8057, 0xFCBF39, 0xFC805C, 0x602054, "ldir"),
        (0xFC8063, 0x0054, None,     None,     0xFC806C, 0x602000, "zero"),
    ]
    for g, v, s, sv, d, dv, kind in blocks:
        check("0x%06X loads XBC = 0x%X" % (g, v), text_at(g),
              "ld XBC,0x%08x" % v)
        check("  ...guarded by `and XBC,XBC` / `jr Z`",
              (text_at(g + 5), text_at(g + 7)[:5]), ("and XBC,XBC", "jr Z,"))
        if s is not None:
            check("  ...source `lda XIY,0x%06X`" % sv, text_at(s),
                  "lda XIY,0x%x" % sv)
        check("  ...destination `lda XIX` = 0x%06X" % dv, text_at(d),
              {0x003800: "lda XIX,0x003800", 0x000000: "lda XIX,0x000000",
               0x602054: "lda XIX,0x602054", 0x602000: "lda XIX,0x602000"}[dv])
    check("the .data blocks end with `ldir`",
          [text_at(0xFC8033), text_at(0xFC8061)], ["ldir", "ldir"])
    check("the .bss blocks are a byte store and a decrement loop",
          [text_at(0xFC8045), text_at(0xFC8048), text_at(0xFC804C)],
          ["ld (XIX+),A", "sub BC,0x0001", "jr NZ,0xfc8045"])
    check("Ram3800_InitAll ends at 0xFC807C with `ret`", text_at(0xFC807C), "ret")

    print("   the published SHORT copy at 0xFC807D")
    check("byte-identical to Ram3800_InitAll over 46 bytes",
          a(0xFC8020, 46) == a(0xFC807D, 46), True)
    check("...and 46 is maximal: byte 47 differs",
          (a(0xFC8020 + 46, 1).hex(), a(0xFC807D + 46, 1).hex()), ("41", "0e"))
    check("the short copy is published as T_F413D0 -- NOT T_F413B4",
          [hex(s) for s in thunk_slots().get(0xFC807D, [])], ['0xf413d0'])
    check("...and T_F413B4, the module's first slot, targets 0xFC80E2",
          hex(int.from_bytes(B[0x413B4 + 1:0x413B4 + 4], "little")), hex(0xFC80E2))
    check("the full initialiser is published by NO slot",
          thunk_slots().get(0xFC8020, []), [])
    check("Ram3800_Start is `calr / call / ret`", a(0xFC8018, 8).hex(),
          "1e0500" "1de180fc" "0e")
    check("0xFC8000 is `jp 0xFC8018`", a(0xFC8000, 4).hex(), "1b1880fc")
    check("the other five entry slots are `ret` + three 0x00",
          [a(x, 4).hex() for x in (0xFC8004, 0xFC8008, 0xFC800C, 0xFC8010,
                                   0xFC8014)], ["0e000000"] * 5)
    check("exactly two sites in prom_a+prom_b form 0xFCB3D3",
          imm_sites("lda XIY,0xfcb3d3"), [0xFC8029, 0xFC8086])
    check("exactly one forms 0xFCBF39", imm_sites("lda XIY,0xfcbf39"),
          [0xFC8057])


# =========================================================================== 3
def sec_images():
    print("3  THE TWO DATA IMAGES ABUT")
    check("0xFCB3D3 + 0x0B66", hex(0xFCB3D3 + 0x0B66), hex(0xFCBF39))
    check("0xFCBF39 + 0x00A0", hex(0xFCBF39 + 0x00A0), hex(0xFCBFD9))
    check("the last 25 bytes of the second image are 0x80",
          set(a(0xFCBFC0, 25)), {0x80})
    check("the byte at its end is 0xFF", a(0xFCBFD9, 1).hex(), "ff")
    check("Ram3800_Sentinels, 17 bytes", a(0xFCBFD9, 17).hex(),
          "ffffffff" "0000000000" "0001020304050607")
    for t in (0xFCBFD9, 0xFCBFE2, 0xFCBFEA):
        refs = [k for k, s in MAP.all_refs().get(t, []) if k not in ("jr", "jrl")]
        check("no call/jp/lda/pointer site names 0x%06X" % t, refs, [])


# =========================================================================== 4
def sec_ptrtable():
    print("4  Ram3800_RecordPtrTable -- 32 entries, and how it differs from the "
          "0xFC1162 copy")
    v = [u32(0xFCBFEA + 4 * k) for k in range(32)]
    check("entry 0", hex(v[0]), hex(0x76A2))
    check("entry 24, the last of the ladder", hex(v[24]), hex(0x7CE2))
    check("entries 25..31 are all the first record",
          {hex(x) for x in v[25:]}, {'0x76a2'})
    steps = [v[k + 1] - v[k] for k in range(24)]
    check("steps of the ladder that are not 0x40",
          [(k, hex(s)) for k, s in enumerate(steps) if s != 0x40], [(7, '0x80')])
    check("the address it skips, the same one the other copy skips",
          hex(v[7] + 0x40), hex(0x78A2))
    check("a 33rd entry would read 0xF69E02EE", hex(u32(0xFCBFEA + 4 * 32)),
          hex(0xF69E02EE))
    # the two copies agree over the ladder they share
    check("entries 0..24 equal the other copy's entries 0..24",
          v[:25], [u32(0xFC1162 + 4 * k) for k in range(25)])
    check("...and the other copy does NOT stop there: its entry 25 is 0x7D22",
          hex(u32(0xFC1162 + 4 * 25)), hex(0x7D22))


# =========================================================================== 5
def sec_jumptable():
    print("5  JumpTable_FC8DB2 -- 9 entries, count from the reader")
    check("the reader's bound", text_at(0xFC8D9E), "cp BC,0x0008")
    check("...and its out-of-range jump", text_at(0xFC8DA2), "jrl UGT,0xfc8e5e")
    check("...4 bytes per entry", text_at(0xFC8DA5), "sll 0x02,BC")
    check("...the table base", text_at(0xFC8DA8), "add XBC,0x00fc8db2")
    check("...the fetch and the jump",
          [text_at(0xFC8DAE), text_at(0xFC8DB0)], ["ld XBC,(XBC)", "jp T,XBC"])
    check("9 entries end at 0xFC8DD6", hex(0xFC8DB2 + 9 * 4), hex(0xFC8DD6))
    check("...which is the VALUE of entry 0 -- the last-entry test",
          hex(u32(0xFC8DB2)), hex(0xFC8DD6))
    check("all 9 entries are instruction boundaries of this module",
          sorted({hex(u32(0xFC8DB2 + 4 * k)) for k in range(9)}
                 - {hex(x) for x in boundaries()}), [])
    check("the 9 entries", [hex(u32(0xFC8DB2 + 4 * k)) for k in range(9)],
          ['0xfc8dd6', '0xfc8de6', '0xfc8df5', '0xfc8e04', '0xfc8e13',
           '0xfc8e22', '0xfc8e31', '0xfc8e40', '0xfc8e4f'])
    check("the default arm is an instruction boundary too",
          0xFC8E5E in boundaries(), True)


# =========================================================================== 6
def sec_clients():
    print("6  WHAT THE MODULE CALLS")
    ext = {}
    for x, n, t in rows():
        m = re.match(r"^call 0x(f4[0-9a-f]{4})$", t)
        if m:
            ext[int(m.group(1), 16)] = ext.get(int(m.group(1), 16), 0) + 1
    want = {0xF40ED4: 10, 0xF41D78: 5, 0xF41E1C: 3, 0xF41DF8: 3, 0xF41DE4: 3,
            0xF41DC0: 3, 0xF40730: 3, 0xF40724: 3, 0xF41E5C: 2, 0xF41DE0: 1,
            0xF41DBC: 1, 0xF41D8C: 1, 0xF41D74: 1, 0xF41044: 1, 0xF40F3C: 1,
            0xF40A24: 1, 0xF40024: 1}
    check("every directory slot this module calls, with its call count",
          {hex(k): v for k, v in sorted(ext.items())},
          {hex(k): v for k, v in sorted(want.items())})
    def slot_target(s):
        off = s - 0xF00000
        return int.from_bytes(B[off + 1:off + 4], "little") if B[off] == 0x1B else None
    check("the seven ring slots resolve to the seven ring routines",
          [hex(slot_target(s)) for s in (0xF41D74, 0xF41D78, 0xF41D8C, 0xF41DBC,
                                         0xF41DC0, 0xF41DE0, 0xF41DE4, 0xF41DF8,
                                         0xF41E1C, 0xF41E5C)],
          ['0xf845d6', '0xf845e3', '0xf84633', '0xf8471c', '0xf84729',
           '0xf847bf', '0xf847cc', '0xf8481c', '0xf848bf', '0xf84b26'])
    check("T_F40724 resolves to MIDI_PostSendWork's address",
          hex(slot_target(0xF40724)), hex(0xFA590F))
    check("T_F40ED4 resolves to the link block sender",
          hex(slot_target(0xF40ED4)), hex(0xF8E02C))
    check("distinct ring OBJECTS touched",
          len({0xF845D6 // 1, }) and len({0x60080A, 0x600A14, 0x600C1E,
                                          0x601028, 0x601432, 0x60153C,
                                          0x601850}), 7)


# =========================================================================== 7
def sec_gap():
    print("7  THE ONE UNACCOUNTED BYTE")
    check("0xFCC06A is 0xEE and 0xFCC06B is 0x02", a(0xFCC06A, 2).hex(), "ee02")
    bad = [x for x, n, t in LD.decode(0xFCC06A, 0xFCC87F) if t == "db"]
    check("a decode begun AT it has exactly one undecodable byte, itself",
          [hex(x) for x in bad], ['0xfcc06a'])
    for st in (0xFCC06B, 0xFCC06C, 0xFCC06E, 0xFCC070):
        d = LD.decode(st, 0xFCC87F)
        b = {x for x, n, t in d}
        check("  a decode from 0x%06X is clean and resynchronises" % st,
              ([x for x, n, t in d if t == "db"],
               {0xFCC16C, 0xFCC17A, 0xFCC255, 0xFCC263, 0xFCC502, 0xFCC573} <= b),
              ([], True))
    outside = sorted((hex(t), k, hex(s)) for t, ss in MAP.all_refs().items()
                     if 0xFCC06A <= t < 0xFCC880 for k, s in ss
                     if k not in ("jr", "jrl") and not (0xFCC06A <= s < 0xFCC880))
    check("sites OUTSIDE the range that name an address in it",
          outside, [('0xfcc1fb', 'calr', '0xfc61c4')])
    check("...and that one site is not an instruction: 0xFC61C3 is a 5-byte "
          "`ldw_da bc,(0x60341e)` so 0xFC61C4 is its second byte",
          A[0xFC61C3 - A_BASE:0xFC61C3 - A_BASE + 5].hex(), "d21e346021")
    check("...and the in-span ones are four `call`s to two addresses",
          sorted((hex(t), hex(s)) for t, ss in MAP.all_refs().items()
                 if 0xFCC06A <= t < 0xFCC880 for k, s in ss if k == "call"),
          [('0xfcc502', '0xfcc16c'), ('0xfcc502', '0xfcc255'),
           ('0xfcc573', '0xfcc17a'), ('0xfcc573', '0xfcc263')])


def selftest():
    print("\nNEGATIVE CONTROLS")
    def ctl(name, ok):
        N[0] += 1
        print(("  ok   " if ok else "  FAIL ") + name)
        if not ok:
            FAILED.append(name)
    # the short copy really is SHORTER, not equal
    ctl("Ram3800_InitDataImage is not simply equal to Ram3800_InitAll",
        a(0xFC8020, 93) != a(0xFC807D, 93))
    # a 10th jump-table entry must not be an address in the module
    v = u32(0xFC8DB2 + 4 * 9)
    ctl("a 10th jump-table entry (0x%08X) is not a module address" % v,
        not (LO <= v < HI))
    # the ladder must fail if read one word early
    ctl("the record ladder does not also start one word early",
        u32(0xFCBFEA - 4) != 0x76A2 - 0x40)
    # the two record tables must not be byte-identical
    ctl("the two record tables are NOT byte-identical",
        a(0xFCBFEA, 128) != a(0xFC1162, 128))


def main():
    sec_bounds()
    sec_init()
    sec_images()
    sec_ptrtable()
    sec_jumptable()
    sec_clients()
    sec_gap()
    if "--selftest" in sys.argv:
        selftest()
    print("\n%d checks, %d failed" % (N[0], len(FAILED)))
    for f in FAILED:
        print("   - " + f)
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
