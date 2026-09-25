#!/usr/bin/env python3
r"""Correct the names and headers reframe_panel_tables.py gave the eleven panel tables.

QUESTION THIS ANSWERS
    reframe_panel_tables.py typed eleven tables in the panel-event modules, but
    its headers had three things wrong, all found by reading the ACTION-LIST
    POOL that dispatches the handlers (PanelGroupActionListPool, 0xF8B812):

    * it called 0xF8AB08/0xF8AB42 "the dead-copy handler" -- they are LIVE:
      10 and 8 pool records point at them;  the handlers at 0xF8A666/0xF8A68F
      that read the byte-identical twins are the dead ones (no pool record, no
      24-bit reference, no relative branch from outside 0xF8A44B-0xF8A7FF);
    * it said every reader ends `ld D,0xFF / jp sub_F8A500`: only the two dead
      handlers do; the live ones commit through sub_F8A90B, and the two 17-byte
      tables are read by the numeric-KEYPAD handlers, which do something else;
    * it named the dead module's three bit-mask routines as if they were new
      (BitMask*_FromOrdinal) when they are byte twins, 0x40B lower, of the live
      IndexToBitMask8/16/32 -- differing only in their table-address operands.

    This script asserts every fact the new headers state, against the ROM
    images, then with --apply renames the labels and rewrites the headers.

CHECKS (all against wsa1/original_ROMs, nothing against the source's prose)
    C1  the pool's handler for each (variant, group, mask) record, by walking
        PanelGroupActionTable_Variant1/2 (0xF8B74A / 0xF8B7AE, 25 LE32 heads,
        6-byte records group,mask,LE32 handler, 0xFF 0xFF ends a list)
    C2  the event-list records (class, code, shift, mask) of the groups those
        handlers serve, from PanelGroupEventLists_Variant1/2 (0xF8B446/0xF8B4B2)
    C3  0xF8A500-0xF8A60C equals 0xF8A90B-0xF8AA17 except the three table
        operands; 0xF8BE36-0xF8BED0 equals 0xF8A97D-0xF8AA17 except one
    C4  no 24-bit value in 0xF8A44B-0xF8A7FF occurs in prom_a outside that
        range, nor anywhere in prom_b; no `calr`/`jrl` outside it targets the
        dead handlers or routines
    C5  twin tables byte-identical (F8A686=F8AB39, F8A6AF=F8AB67)

RUN
    python3 notes/proma-2026-09-25/retitle_panel_tables.py          # checks only
    python3 notes/proma-2026-09-25/retitle_panel_tables.py --apply  # + rewrite
    (--apply ran ONCE, on the tree reframe_panel_tables.py left; it renames the
    names that script wrote, so it is not re-runnable -- the checks are.)
    make gate-wsa1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "wsa1", "prom_a", "wsa1_prom_a.s")
ROMA = open(os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
ROMB = open(os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
B = 0xF80000
DEAD = (0xF8A44B, 0xF8A800)


def seg(a, n):
    return ROMA[a - B:a - B + n]


def l32(a):
    return int.from_bytes(seg(a, 4), "little")


def pool():
    """C1: handler -> sorted list of 'vN gGG mMM'."""
    h = {}
    for v, t in ((1, 0xF8B74A), (2, 0xF8B7AE)):
        for g in range(25):
            p = l32(t + 4 * g)
            while seg(p, 2) != b"\xff\xff":
                r = seg(p, 6)
                h.setdefault(int.from_bytes(r[2:], "little"), []).append(
                    "v%d g%02X m%02X" % (v, r[0], r[1]))
                p += 6
    return h


def events(v, g):
    """C2: the event-list records of variant v, group g."""
    p = l32((0xF8B446, 0xF8B4B2)[v - 1] + 4 * g)
    out = []
    while seg(p, 1)[0] != 0xFF:
        out.append(seg(p, 4).hex())
        p += 4
    return out


def checks():
    H = pool()
    want = {
        0xF8AB08: "v1 g07 m01,v1 g07 m02,v1 g07 m04,v1 g07 m08,v1 g07 m10,v1 g07 m20,"
                  "v2 g06 m01,v2 g06 m02,v2 g06 m04,v2 g06 m08",
        0xF8AB42: "v1 g00 m01,v1 g00 m02,v1 g00 m04,v1 g00 m08,"
                  "v2 g00 m01,v2 g00 m02,v2 g00 m04,v2 g00 m08",
        0xF8ACE8: "v1 g01 mFF,v1 g02 mFF",
        0xF8ADDE: "v2 g01 mFF,v2 g02 m0F",
        0xF8AFD0: "v1 g0B m7F,v1 g0D m7F,v1 g10 m7F,v1 g11 m7F,v1 g13 m7F,v1 g14 m7F,"
                  "v1 g15 m7F,v2 g14 m7F,v2 g15 m7F",
        0xF8B08B: "v1 g16 m01,v1 g17 m01",
    }
    for a, w in want.items():
        assert ",".join(H[a]) == w, (hex(a), H[a])
    for dead in (0xF8A666, 0xF8A68F, 0xF8A60D, 0xF8A619, 0xF8A64C, 0xF8A6B8, 0xF8A726, 0xF8A7DB):
        assert dead not in H, hex(dead)
    print("C1 ok: pool handlers as stated; no pool record names a dead-module handler")
    assert events(1, 7)[:6] == ["a92000%02x" % (1 << k) for k in range(6)]
    assert events(2, 6) == ["a92000%02x" % (1 << k) for k in range(4)]
    assert events(1, 0)[:4] == events(2, 0)[:4] == ["a92000%02x" % (1 << k) for k in range(4)]
    assert events(1, 1) == events(1, 2) == ["a80800ff"]
    assert events(2, 1) == ["a91b00ff"] and events(2, 2)[0] == "a91b000f"
    print("C2 ok: v1 g07 / v2 g06 / v1+v2 g00 are class A9 code 20, shift 0, one bit each;"
          " keypad groups are A8/08 (v1) and A9/1B (v2)")
    d = [hex(0xF8A500 + i) for i in range(0x10D) if seg(0xF8A500 + i, 1) != seg(0xF8A90B + i, 1)]
    assert d == ["0xf8a525", "0xf8a526", "0xf8a545", "0xf8a546", "0xf8a57e", "0xf8a57f"], d
    d = [hex(0xF8BE36 + i) for i in range(0x9B) if seg(0xF8BE36 + i, 1) != seg(0xF8A97D + i, 1)]
    assert d == ["0xf8be42", "0xf8be43"], d
    print("C3 ok: dead 0xF8A500-0xF8A60C = live 0xF8A90B-0xF8AA17 but 3 table operands;"
          " 0xF8BE36-0xF8BED0 = 0xF8A97D-0xF8AA17 but its table operand")
    lo, hi = DEAD
    for name, rom, base in (("prom_a", ROMA, B), ("prom_b", ROMB, 0xF00000)):
        for i in range(len(rom) - 2):
            v = int.from_bytes(rom[i:i + 3], "little")
            if lo <= v < hi and not (name == "prom_a" and lo <= base + i < hi):
                # the one known coincidence: `calr sub_FB6219` bytes at 0xFB696F
                assert (name, base + i) == ("prom_a", 0xFB696F), (name, hex(base + i), hex(v))
    tg = {0xF8A51C, 0xF8A539, 0xF8A572, 0xF8A60D, 0xF8A619, 0xF8A64C, 0xF8A666, 0xF8A68F,
          0xF8A6B8, 0xF8A726, 0xF8A7DB}
    for i in range(len(ROMA) - 3):
        if ROMA[i] in (0x1E, 0x78) and not (lo <= B + i < hi):
            t = B + i + 3 + int.from_bytes(ROMA[i + 1:i + 3], "little", signed=True)
            assert t not in tg, (hex(B + i), hex(t))
    print("C4 ok: nothing outside 0xF8A44B-0xF8A7FF names an address inside it"
          " (24-bit, both ROMs; calr/jrl, prom_a)")
    for i in range(len(ROMA) - 3):
        if ROMA[i] in (0x1E, 0x78):
            t = B + i + 3 + int.from_bytes(ROMA[i + 1:i + 3], "little", signed=True)
            assert t not in (0xF8A539, 0xF8A572), (hex(B + i), hex(t))
    print("C4b ok: no calr/jrl anywhere in prom_a targets 0xF8A539 or 0xF8A572")
    assert seg(0xF8A686, 9) == seg(0xF8AB39, 9) and seg(0xF8A6AF, 9) == seg(0xF8AB67, 9)
    print("C5 ok: twin tables identical")
    d = [hex(0xF8AD54 + i) for i in range(0x79) if seg(0xF8AD54 + i, 1) != seg(0xF8ADDE + i, 1)]
    assert d == ["0xf8ad68", "0xf8ad77", "0xf8ad78"], d
    for c in (0xF8AD67, 0xF8ADF1):        # the one calr each: same target, own displacement
        assert seg(c, 1) == b"\x1e"
        assert c + 3 + int.from_bytes(seg(c + 1, 2), "little", signed=True) == 0xF8A913, hex(c)
    print("C6 ok: V2 keypad handler 0xF8ADDE-0xF8AE56 = V1 keypad path 0xF8AD54-0xF8ADCC"
          " but its table operand and one calr displacement (both calls reach"
          " LowestSetBitIndex1Based, 0xF8A913)")


RENAME = [  # intermediate names (never committed) -> final; longest first
    ("BitMask32_FromOrdinal_Copy", "IndexToBitMask32_Copy"),
    ("BitMask32_ByOrdinal_Copy", "BitMask32ByIndex_Copy"),
    ("BitMask8_FromOrdinal", "IndexToBitMask8_DeadCopy"),
    ("BitMask16_FromOrdinal", "IndexToBitMask16_DeadCopy"),
    ("BitMask32_FromOrdinal", "IndexToBitMask32_DeadCopy"),
    ("BitMask8_ByOrdinal", "BitMask8ByIndex_DeadCopy"),
    ("BitMask16_ByOrdinal", "BitMask16ByIndex_DeadCopy"),
    ("BitMask32_ByOrdinal", "BitMask32ByIndex_DeadCopy"),
    ("PanelBitToEvent_F8A686", "PanelOrdinalToEventValue_A_DeadCopy"),
    ("PanelBitToEvent_F8A6AF", "PanelOrdinalToEventValue_B_DeadCopy"),
    ("PanelBitToEvent_F8AB39", "PanelOrdinalToEventValue_A"),
    ("PanelBitToEvent_F8AB67", "PanelOrdinalToEventValue_B"),
    ("PanelBitToEvent_F8ADCD", "PanelKeypad_OrdinalToKey_V1"),
    ("PanelBitToEvent_F8AE57", "PanelKeypad_OrdinalToKey_V2"),
    ("ControlIndexMap_F8B07E", "PanelGroupToRam7F12Slot"),
]

DASH = "; ---------------------------------------------------------------------"
SRCNOTE = "; (was framed as code; notes/proma-2026-09-25/reframe_panel_tables.py,"
SRCNOTE2 = ";  headers from notes/proma-2026-09-25/retitle_panel_tables.py)"
DEADNOTE = [
    "; ⚠ DEAD: 0xF8A44B-0xF8A7FF is unreachable -- nothing outside it names an",
    ";          address in it (check C4); see PanelGroupQueue_ExpandToEvents_DeadCopy.",
]

TABLE_HDR = {
    "BitMask8ByIndex_DeadCopy": [
        "; BitMask8ByIndex_DeadCopy -- 9 x u8: 0, then 1<<0 .. 1<<7 (entry k = 1 << (k-1)).",
        "; Read by: IndexToBitMask8_DeadCopy (0xF8A51C) -- `cp E,0x08 / jr ule / xor E,E /",
        ";          ld XIX,<this> / ld E,(XIX+E)`: any E above 8 reads entry 0.",
        "; COUNT 9 = that bound + 1; IndexToBitMask16_DeadCopy starts right after.",
        "; Byte-identical to BitMask8ByIndex (0xF8A93B), 0x40B higher (check C3).",
    ] + DEADNOTE,
    "BitMask16ByIndex_DeadCopy": [
        "; BitMask16ByIndex_DeadCopy -- 17 x u16: 0, then 1<<0 .. 1<<15 (entry k = 1 << (k-1)).",
        "; Read by: IndexToBitMask16_DeadCopy (0xF8A539) -- `cp E,0x10 / jr ule / xor E,E /",
        ";          sla 1,E / ld XIX,<this> / ld DE,(XIX+E)`: any E above 16 reads entry 0.",
        "; COUNT 17 = that bound + 1; IndexToBitMask32_DeadCopy starts right after.",
        "; Byte-identical to BitMask16ByIndex (0xF8A95B), 0x40B higher (check C3).",
    ] + DEADNOTE,
    "BitMask32ByIndex_DeadCopy": [
        "; BitMask32ByIndex_DeadCopy -- 33 x u32: 0, then 1<<0 .. 1<<31 (entry k = 1 << (k-1)).",
        "; Read by: IndexToBitMask32_DeadCopy (0xF8A572) -- `cp E,0x20 / jr ule / xor E,E /",
        ";          sla 2,E / ld XIX,<this> / ld XDE,(XIX+E)`: any E above 32 reads entry 0.",
        "; COUNT 33 = that bound + 1; the dead handler at 0xF8A60D starts right after.",
        "; Byte-identical to BitMask32ByIndex (0xF8A994), 0x40B higher (check C3).",
    ] + DEADNOTE,
    "BitMask32ByIndex_Copy": [
        "; BitMask32ByIndex_Copy -- 33 x u32: 0, then 1<<0 .. 1<<31 (entry k = 1 << (k-1)).",
        "; Read by: IndexToBitMask32_Copy (0xF8BE36) -- `cp E,0x20 / jr ule / xor E,E /",
        ";          sla 2,E / ld XIX,<this> / ld XDE,(XIX+E)`: any E above 32 reads entry 0.",
        "; COUNT 33 = that bound + 1; sub_F8BED1 starts right after.",
        "; Byte-identical to BitMask32ByIndex (0xF8A994).  This copy is LIVE: its",
        ";          routine is called by sub_F8BDC5 (0xF8BDCF) and sub_F8BDF8 (0xF8BE04).",
    ],
    "PanelOrdinalToEventValue_A": [
        "; PanelOrdinalToEventValue_A -- 9 bytes: switch ordinal -> event VALUE byte.",
        "; Read by: the action handler at 0xF8AB08 -- `add XDE,<this> / ld E,(XDE)` at",
        ";          0xF8AB16 -- which 10 PanelGroupActionListPool records dispatch:",
        ";          v1 group 0x07 masks 01..20 and v2 group 0x06 masks 01..08 (check C1).",
        ";          Those groups' event-list records are all class 0xA9 code 0x20,",
        ";          shift 0, one bit each (check C2), so E arrives as that single",
        ";          bit and LowestSetBitIndex1Based makes it the ordinal 1..8.",
        ";          The handler runs only while (0x2806) is 0, sets D = 0xFF, turns",
        ";          a value of 3 into 8 when bit 0 of (0x3614) is set, clears that",
        ";          bit, and commits DE through sub_F8A90B (`ld (XIX+),DE`).",
        "; So every switch in those groups raises the SAME event (A9,20) and this",
        ";          table's byte is what tells them apart.",
        "; COUNT 9 = ordinals 0..8; the records reach 1..6 (v1) and 1..4 (v2).",
        "; ⚠ What the values 0x09 0x0A 0x12 0x15 0x08 0x03 denote is not established.",
    ],
    "PanelOrdinalToEventValue_B": [
        "; PanelOrdinalToEventValue_B -- 9 bytes: switch ordinal -> event VALUE byte.",
        "; Read by: the action handler at 0xF8AB42 -- `add XDE,<this> / ld E,(XDE)` at",
        ";          0xF8AB50 -- which 8 PanelGroupActionListPool records dispatch: v1",
        ";          and v2 group 0x00 masks 01..08 (check C1).  Those event-list",
        ";          records are class 0xA9 code 0x20, shift 0, one bit each (check C2),",
        ";          the same event PanelOrdinalToEventValue_A feeds.  The handler",
        ";          runs only while (0x2806) is 0, sets D = 0xFF, clears bit 0 of",
        ";          (0x3614) and commits DE through sub_F8A90B.",
        "; COUNT 9 = ordinals 0..8; the records reach 1..4.",
        "; ⚠ What the values 0x01 0x02 0x17 0x16 denote is not established.",
    ],
    "PanelOrdinalToEventValue_A_DeadCopy": [
        "; PanelOrdinalToEventValue_A_DeadCopy -- 9 bytes, identical to",
        ";          PanelOrdinalToEventValue_A (0xF8AB39) (check C5).",
        "; Read by: the unlabelled handler at 0xF8A666 -- `add XDE,<this> / ld E,(XDE)`",
        ";          at 0xF8A674, then `ld D,0xFF / jp sub_F8A500`, the dead module's",
        ";          `ld (XIX+),DE`.  It is an OLDER form of the live handler 0xF8AB08:",
        ";          it lacks the value-3 / (0x3614) bit-0 case.  No pool record names",
        ";          0xF8A666 (check C1).",
        "; COUNT 9 = ordinals 0..8, as its live twin.",
    ] + DEADNOTE,
    "PanelOrdinalToEventValue_B_DeadCopy": [
        "; PanelOrdinalToEventValue_B_DeadCopy -- 9 bytes, identical to",
        ";          PanelOrdinalToEventValue_B (0xF8AB67) (check C5).",
        "; Read by: the unlabelled handler at 0xF8A68F -- `add XDE,<this> / ld E,(XDE)`",
        ";          at 0xF8A69D, then `ld D,0xFF / jp sub_F8A500`.  An OLDER form of",
        ";          the live handler 0xF8AB42, which also clears bit 0 of (0x3614).",
        ";          No pool record names 0xF8A68F (check C1).",
        "; COUNT 9 = ordinals 0..8, as its live twin.",
    ] + DEADNOTE,
    "PanelKeypad_OrdinalToKey_V1": [
        "; PanelKeypad_OrdinalToKey_V1 -- 17 bytes: keypad switch ordinal -> key.",
        "; Read by: `add XDE,<this> / ld E,(XDE)` at 0xF8AD75, in the keypad path",
        ";          (0xF8AD54, taken when bit 1 of (0x2075) is set) of the action",
        ";          handler at 0xF8ACE8, which the pool dispatches for v1 groups",
        ";          0x01 and 0x02, mask FF (check C1).  The path first rewrites the",
        ";          event's class/code word to 0x1BA9 -- the (A9,1B) that v2's",
        ";          keypad groups carry natively (check C2); E = 0 commits",
        ";          DE = 0x0200; otherwise E = LowestSetBitIndex1Based(E), plus 8",
        ";          unless the group (A) is 1, so group 1 gives ordinals 1-8 and",
        ";          group 2 ordinals 9-16.",
        "; What the handler does with the byte read (0xF8AD7D-0xF8ADC9):",
        ";   0..9  a DIGIT: stored to (0x2267); the bytes at 0x2822-0x2823 move",
        ";         down to 0x2821-0x2822 and `E + 0x30` (its ASCII) goes to 0x2823;",
        ";   0x80  stored to (0x2267); (0x2820) toggles between '+' (0x2B) and",
        ";         '-' (0x2D);",
        ";   0x0F  stored to (0x2267) -- unless (0x2823) holds 0x20 (a space),",
        ";         in which case the event is dropped;",
        ";   0xFF  above 9 and not special: dropped (`jp sub_F8A90F`).",
        ";         So 0x2820-0x2823 is a sign and three ASCII digits.",
        "; Here: ordinals 1-9 -> digits 1-9, 10 -> 0, 11 -> 0x80, 12 -> 0x0F,",
        ";          0 and 13-16 -> 0xFF.  COUNT 17 = ordinals 0..16.",
        "; ⚠ What 0x0F commits (an ENTER?) is not established from this code.",
    ],
    "PanelKeypad_OrdinalToKey_V2": [
        "; PanelKeypad_OrdinalToKey_V2 -- 17 bytes: keypad switch ordinal -> key.",
        "; Read by: `add XDE,<this> / ld E,(XDE)` at 0xF8ADFF in the action handler",
        ";          at 0xF8ADDE, which the pool dispatches for v2 group 0x01 mask FF",
        ";          and v2 group 0x02 mask 0F (check C1): 8 + 4 = 12 switches, event",
        ";          (A9,1B) (check C2).  The handler is the V1 keypad path",
        ";          (PanelKeypad_OrdinalToKey_V1) instruction for instruction but",
        ";          for this table (check C6): the same digit / 0x80 / 0x0F / 0xFF",
        ";          actions on the same RAM.",
        "; Here: ordinals 1-10 -> digits 0-9, 11 -> 0x80, 12 -> 0x0F, 0 and 13-16 -> 0xFF.",
        ";          COUNT 17 = ordinals 0..16 (v2's masks reach only 1..12).",
    ],
    "PanelGroupToRam7F12Slot": [
        "; PanelGroupToRam7F12Slot -- 13 bytes: panel group 0x0B..0x17 -> slot in the",
        ";          RAM byte array at 0x7F12 (index = group - 0x0B).",
        "; Read by: the action handler at 0xF8AFD0 (pool: v1 groups 0x0B 0x0D 0x10",
        ";          0x11 0x13 0x14 0x15, v2 groups 0x14 0x15, all mask 7F -- 7-bit",
        ";          controller values, event classes B2 BC BA BB BD B8 B9) and the",
        ";          one at 0xF8B08B (v1 groups 0x16 0x17, mask 01) (check C1):",
        ";          `sub A,0x0B / add XWA,<this> / ld A,(XWA)` at 0xF8AFD7 and",
        ";          0xF8B099, then both read the byte at 0x7F12 + that slot.",
        ";          0xF8AFD0 turns that byte into the event's CLASS (1->B2, 2->BC,",
        ";          4->BD, 0x0B->B3, 0x10->B8, 0x11->B9, 0x12->BA, 0x13->BB,",
        ";          0x40->B5, 0x81->B4, anything else drops the event); with",
        ";          (0xC4) = 2 it lets only slots 0x15/0x16 through.  0xF8B08B",
        ";          branches on it (0x40, 0x88, 0x89, ...).",
        "; So the RAM bytes at 0x7F12 + slot hold an ASSIGNMENT per controller.",
        "; COUNT 13 = groups 0x0B..0x17; the unused slots (groups 0x0C 0x0E 0x0F",
        ";          0x12, which the pool never sends here) are 0.",
        "; ⚠ Which physical controllers the groups are is not established here.",
    ],
}

ROUTINE_HDR = {
    "IndexToBitMask8_DeadCopy": [
        "; IndexToBitMask8_DeadCopy -- E (0..8) -> E = one-hot mask.  The dead",
        ";          module's twin of IndexToBitMask8 (0xF8A927), 0x40B lower and",
        ";          identical but for its table operand (check C3).",
        "; Called by: the dead handler at 0xF8A619 (`calr` at 0xF8A620).",
    ],
    "IndexToBitMask16_DeadCopy": [
        "; IndexToBitMask16_DeadCopy -- E (0..16) -> DE = one-hot mask; twin of",
        ";          IndexToBitMask16 (0xF8A944), identical but for its table operand.",
        "; Called by: nothing found -- no 24-bit reference in either ROM (C4) and",
        ";          no calr/jrl in prom_a lands on it (C4b).",
    ] + [x for x in DEADNOTE],
    "IndexToBitMask32_DeadCopy": [
        "; IndexToBitMask32_DeadCopy -- E (0..32) -> XDE = one-hot mask; twin of",
        ";          IndexToBitMask32 (0xF8A97D), identical but for its table operand.",
        "; Called by: nothing found (as IndexToBitMask16_DeadCopy).",
    ] + [x for x in DEADNOTE],
    "IndexToBitMask32_Copy": [
        "; IndexToBitMask32_Copy -- E (0..32) -> XDE = one-hot 32-bit mask, a LIVE",
        ";          second copy of IndexToBitMask32 (0xF8A97D): identical but for its",
        ";          table operand (check C3).  Renamed from sub_F8BE36.",
        "; Called by: sub_F8BDC5 (`calr` at 0xF8BDCF) and sub_F8BDF8 (0xF8BE04),",
        ";          each with E = L + 1.",
    ],
}


def u8(s):
    """prose is UTF-8 inside a file handled as latin-1: store its UTF-8 bytes"""
    return s.encode("utf-8").decode("latin-1")


def apply():
    txt = open(SRC, encoding="latin-1").read()
    for old, new in RENAME:
        txt, n = re.subn(r"(?<![\w.$])%s(?![\w$])" % re.escape(old), new, txt)
        assert n >= 1, old
    # the dead copy's stale operand: back to the numeric form it had at base --
    # a label expression would claim it points at the keypad table, which it does not
    old = "\tld XIX,PanelKeypad_OrdinalToKey_V1+0x10                   ; F8A44C"
    assert txt.count(old) == 1
    txt = txt.replace(old, "\tld XIX,0x00f8addd                                    ; F8A44C")
    L = txt.split("\n")
    for name, hdr in TABLE_HDR.items():
        i = L.index(name + ":")
        j = i - 1
        assert L[j] == DASH, (name, L[j])
        j -= 1
        while L[j] != DASH:
            assert L[j].startswith(";"), (name, L[j])
            j -= 1
        L[j:i] = [u8(x) for x in [DASH] + hdr + [SRCNOTE, SRCNOTE2, DASH]]
    for name, hdr in ROUTINE_HDR.items():
        i = L.index(name + ":")
        j = i
        if L[i - 1].startswith(";"):      # replace the short block reframe wrote
            j = i - 1
            while L[j - 1].startswith(";"):
                j -= 1
            assert not any(DASH == x for x in L[j:i]), name
        L[j:i] = [u8(x) for x in [DASH] + hdr + [DASH]]
    open(SRC, "w", encoding="latin-1", newline="").write("\n".join(L))
    print("applied")


if __name__ == "__main__":
    checks()
    if "--apply" in sys.argv:
        apply()
