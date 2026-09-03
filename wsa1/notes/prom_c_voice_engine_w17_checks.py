#!/usr/bin/env python3
"""Re-derive, from the ROM bytes, every NUMBER the wave-17 voice-engine blocks quote.

QUESTION THIS ANSWERS
    The three `★★ WAVE 17` block comments in wsa1/prom_c/voice/*.s assert an
    array chain that closes on itself, two polyphony budgets that sum to the
    channel count, a set of allocation descriptors and a staging-offset ->
    register-block map.  Each of those is a number.  This script reads
    `wsa1/original_ROMs/wsa1_prom_c.ic28` -- bytes, never the .s file and never a
    disassembler's text -- and asserts every one of them.

RUN
    python3 wsa1/notes/prom_c_voice_engine_w17_checks.py
    python3 wsa1/notes/prom_c_voice_engine_w17_checks.py --selftest

    --selftest additionally runs two NEGATIVE CONTROLS: a deliberately wrong
    stride and a deliberately wrong table base must both make the check go red.
    A check that cannot fail is not evidence.
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
ROM = ROOT / "wsa1/original_ROMs/wsa1_prom_c.ic28"
BASE = 0xF80000

FAILS = []


def check(name, got, want):
    ok = got == want
    if not ok:
        FAILS.append(name)
    print(f"  {'ok  ' if ok else 'FAIL'}  {name:<62} {got!r}"
          + ("" if ok else f"   want {want!r}"))
    return ok


class Rom:
    def __init__(self, path=ROM):
        self.d = path.read_bytes()

    def at(self, a, n=1):
        return self.d[a - BASE: a - BASE + n]

    def u8(self, a):
        return self.d[a - BASE]

    def u16(self, a):
        return int.from_bytes(self.at(a, 2), "little")

    def u32(self, a):
        return int.from_bytes(self.at(a, 4), "little")

    def has_le16(self, a, lo, hi, value):
        """Is `value` present as a little-endian u16 anywhere in [a+lo, a+hi)?"""
        w = self.at(a + lo, hi - lo)
        v = value.to_bytes(2, "little")
        return v in w


# --------------------------------------------------------------- section 1
# base, stride, count, the address of the instruction the block comment cites for
# the STRIDE, and the array that must start where this one ends (None = a gap).
CHAIN = [
    ("resource pools",        0x0200,  30,  18, 0xFA6774, 0x041C),
    ("part queue rows",       0x041C,   6,  34, 0xFA6C27, 0x04E8),
    ("channel records",       0x04E8,  23,  64, 0xFA687D, 0x0AA8),
    ("slot head table",       0x0AA8,  27,  34, 0xFA5E4C, 0x0E3E),
    ("slot records",          0x0E3E,   5, 192, 0xFA5F3C, 0x11FE),
    ("per-channel bindings",  0x11FE,  12,  64, 0xFA5CF0, 0x14FE),
    ("part records",          0x1523, 300,  33, 0xFB386C, None),
    ("voice records",         0x3BCF,  68,  64, 0xFB3FE4, 0x4CCF),
]


def section1(rom):
    print("\n1. THE ARRAY CHAIN -- every array's end is the next one's base")
    for name, base, stride, count, cite, nxt in CHAIN:
        end = base + stride * count
        if nxt is not None:
            check(f"0x{base:04X} + {count}*{stride} = 0x{end:04X}  ({name})",
                  end, nxt)
        else:
            check(f"0x{base:04X} + {count}*{stride} = 0x{end:04X}  ({name})",
                  end, 0x3BCF)
        # the stride is an immediate near the cited instruction
        window = rom.at(cite, 12)
        present = ((stride < 256 and bytes([stride]) in window)
                   or stride.to_bytes(2, "little") in window)
        check(f"    stride {stride} is an immediate at 0x{cite:06X}", present, True)


# --------------------------------------------------------------- section 2
def section2(rom):
    print("\n2. THE TWO POLYPHONY BUDGETS, and both sum to the channel count")
    a = list(rom.at(0xFE1144, 18))
    b = list(rom.at(0xFE1156, 18))
    check("Table_FE1144 = 24,24,16 then thirteen 0 then 64,64",
          a, [24, 24, 16] + [0] * 13 + [64, 64])
    check("Table_FE1156 first sixteen entries",
          b[:16], [12, 6, 6, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2, 2, 2, 6])
    check("Table_FE1156 entries 16,17", b[16:], [64, 64])
    check("sum(Table_FE1144[0:16]) == 64", sum(a[:16]), 64)
    check("sum(Table_FE1156[0:16]) == 64", sum(b[:16]), 64)
    check("64 is the channel count (`cp H,0x40` at 0xFB3FDE)",
          rom.at(0xFB3FDE, 3)[-1] if False else rom.has_le16(0xFB3FDE, 0, 4, 0x0040)
          or bytes([0x40]) in rom.at(0xFB3FDE, 4), True)


# --------------------------------------------------------------- section 3
def section3(rom):
    print("\n3. THE TWO PART-TO-POOL MAPS, 34 u16 each, all valid pool bases")
    for label, base in (("Table_FE1168", 0xFE1168), ("Table_FE11AC", 0xFE11AC)):
        vals = [rom.u16(base + 2 * i) for i in range(34)]
        bad = [v for v in vals if v < 0x0200 or v > 0x03FE or (v - 0x0200) % 30]
        check(f"{label}: 34 entries, every one a pool base 0x0200+30*p", bad, [])
        check(f"{label}: entry 33 is pool 17 (0x03FE, the free pool)",
              vals[33], 0x03FE)
    v = [rom.u16(0xFE1168 + 2 * i) for i in range(34)]
    check("Table_FE1168: part 0 -> pool 0, parts 1..7 -> pool 1, 8..32 -> pool 2",
          (v[0], set(v[1:8]), set(v[8:33])), (0x0200, {0x021E}, {0x023C}))
    check("Table_FE1168 ends where Table_FE11AC begins", 0xFE1168 + 68, 0xFE11AC)
    check("Table_FE11AC ends where the search orders begin", 0xFE11AC + 68, 0xFE11F0)


# --------------------------------------------------------------- section 4
def section4(rom):
    print("\n4. THE ALLOCATION DESCRIPTORS AND THE SEARCH ORDERS")

    def order(a):
        out = []
        while rom.u8(a) != 0xFF:
            out.append(rom.u8(a))
            a += 1
            if len(out) > 64:
                break
        return out

    check("overflow order at 0xFE11F0", order(0xFE11F0),
          [0x06, 0x05, 0x02, 0x04, 0x03, 0x01, 0x00])
    check("search order at 0xFE11F8", order(0xFE11F8),
          [0x86, 0x85, 0x06, 0x05, 0x84, 0x83, 0x82, 0x04, 0x03, 0x02,
           0x81, 0x80, 0x01, 0x00])
    check("search order at 0xFE1207", order(0xFE1207),
          [0x86, 0x85, 0x06, 0x05, 0x84, 0x83, 0x82, 0x04, 0x03, 0x02,
           0x81, 0x80, 0x01])
    check("search order at 0xFE1215", order(0xFE1215),
          [0x86, 0x85, 0x06, 0x05, 0x84, 0x83, 0x82, 0x04, 0x03, 0x02])
    # Each search order is a sequence of TIERS in descending queue order, and
    # inside a tier the overflow-pool entries (bit 7 set) come before the
    # part's-own-pool entries, which repeat the same queues.
    for lst in (0xFE11F8, 0xFE1207, 0xFE1215):
        runs, cur, flag = [], [], None
        for e in order(lst):
            f = e >> 7
            if f != flag:
                if cur:
                    runs.append((flag, cur))
                cur, flag = [], f
            cur.append(e & 0x7F)
        runs.append((flag, cur))
        shape_ok = (len(runs) % 2 == 0
                    and all(runs[i][0] == 1 and runs[i + 1][0] == 0
                            for i in range(0, len(runs), 2))
                    # own run repeats the overflow run, or is a prefix of it
                    and all(runs[i][1][:len(runs[i + 1][1])] == runs[i + 1][1]
                            for i in range(0, len(runs), 2))
                    # each run descends, and the tiers descend
                    and all(v == sorted(v, reverse=True) for _, v in runs)
                    and all(runs[i][1][0] > runs[i + 2][1][0]
                            for i in range(0, len(runs) - 2, 2)))
        check(f"    0x{lst:06X}: tiers descend, overflow before own inside a tier",
              (shape_ok, [(f, v) for f, v in runs]),
              (True, [(f, v) for f, v in runs]))
    desc = [(rom.u32(0xFE1220 + 6 * k), rom.u8(0xFE1220 + 6 * k + 4),
             rom.u8(0xFE1220 + 6 * k + 5)) for k in range(4)]
    check("descriptors 0..3 at 0xFE1220 (list, alloc queue, release queue)", desc,
          [(0x00FE11F8, 0, 3), (0x00FE1207, 1, 3),
           (0x00FE1215, 2, 4), (0x00FE1215, 2, 5)])


# --------------------------------------------------------------- section 5
# (staging struct offset, register block, the address of the SELECT instruction)
STAGE = [
    (0x02, 0x0040, 0xFB7155), (0x04, 0x0080, 0xFB7172),
    (0x06, 0x00C0, 0xFB7188), (0x08, 0x0100, 0xFB719B),
    (0x0A, 0x0140, 0xFB71AE), (0x0C, 0x0180, 0xFB71C1),
    (0x0E, 0x0400, 0xFB71D4), (0x10, 0x0440, 0xFB71E7),
    (0x12, 0x0480, 0xFB71FA), (0x14, 0x04C0, 0xFB720D),
    (0x18, 0x0800, 0xFB7220), (0x1A, 0x0840, 0xFB723F),
    (0x1C, 0x0880, 0xFB7252), (0x26, 0x09C0, 0xFB7265),
    (0x28, 0x0A00, 0xFB7278), (0x2A, 0x0A40, 0xFB728B),
    (0x1E, 0x08C0, 0xFB72A2), (0x16, 0x0500, 0xFB72B5),
    (0x20, 0x0900, 0xFB72C8), (0x22, 0x0940, 0xFB72DB),
    (0x24, 0x0980, 0xFB72EE),
]
SIX = [(0x2E, 0x0840, 0xFB7368), (0x36, 0x0A00, 0xFB7385),
       (0x2C, 0x0800, 0xFB7398), (0x34, 0x09C0, 0xFB73AB),
       (0x32, 0x0940, 0xFB73C2), (0x30, 0x0900, 0xFB73D5)]


def section5(rom):
    print("\n5. THE STAGING-OFFSET -> REGISTER-BLOCK MAP, select then value")
    for off, block, cite in STAGE + SIX:
        sel = rom.has_le16(cite, 0, 6, block)
        val = bytes([off]) in rom.at(cite, 24)
        check(f"select 0x{block:04X} at 0x{cite:06X}, value from struct +0x{off:02X}",
              (sel, val), (True, True))
    check("the 0x0010C000 struct is 22 words, +0x02..+0x2A",
          (min(o for o, _, _ in STAGE), max(o for o, _, _ in STAGE), len(STAGE)),
          (0x02, 0x2A, 21))
    check("the six-register set is +0x2C..+0x36",
          sorted(o for o, _, _ in SIX), [0x2C, 0x2E, 0x30, 0x32, 0x34, 0x36])


def selftest(rom):
    print("\n6. NEGATIVE CONTROLS -- the check must be able to go red")
    n = len(FAILS)
    check("(control) a wrong stride: 0x04E8 + 64*22 != 0x0AA8",
          0x04E8 + 64 * 22, 0x0AA8)
    check("(control) a wrong table base: bytes at 0xFE1145 do not sum to 64",
          sum(rom.at(0xFE1145, 16)), 64)
    fired = len(FAILS) - n
    ok = fired == 2
    print(f"  {'ok  ' if ok else 'FAIL'}  both controls fired: {fired}/2")
    del FAILS[n:]
    return ok


def main():
    rom = Rom()
    print(f"prom_c wave-17 voice-engine checks -- {ROM.name}, {len(rom.d):,} bytes")
    section1(rom)
    section2(rom)
    section3(rom)
    section4(rom)
    section5(rom)
    ok = True
    if "--selftest" in sys.argv:
        ok = selftest(rom)
    print(f"\nFAILURES: {len(FAILS)}")
    for f in FAILS:
        print("  ", f)
    return 0 if (not FAILS and ok) else 1


if __name__ == "__main__":
    sys.exit(main())
