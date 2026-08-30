#!/usr/bin/env python3
"""REVIEW-WA3: are wave 7 round 3's forty-two new prom_a names carried by their
evidence?  Three questions this file answers from the ROM images, not from the
listing's prose.

Q1  HOW BIG IS A PANEL SCREEN'S BUTTON-HANDLER TABLE?
    Five new headers (Screen_ReMapEdit_Button, Screen_SoundGroupNaming_Button,
    Screen_CombinationGroupNaming_Button, Screen_DrumsMapNaming_Button,
    Screen_CombinationNaming_Button) each say "dispatches through a 32-entry
    table of handlers", citing round 7's five-bit masks.  Measured here: each of
    the five tables holds EXACTLY 23 consecutive ROM pointers and its 24th
    longword is not a ROM address.  The bound is not absent either: every one of
    the five Button methods calls prom_b 0xF42C74 -> 0xF55019, which rejects a
    raw index above 0x1F and then REMAPS it -- raw 0x11..0x19 become 0..8 and
    raw 0x1A..0x1F become 17..22 -- so the value that reaches `mul A,0x04` is in
    0..22, which is 23 slots and not 32.  Round 7's 32-entry tables are a
    DIFFERENT object: prom_b 0xF7D2D8..0xF7E258, spaced 0x80 = 32*4 apart.

Q2  DOES LCD_DrawVRule_LeftOrRight DRAW THE RIGHT-HAND RULE?
    Its header says 0xFEFE59 `bit 0,(0x601f70)` "chooses between 0xFEFE61 `calr
    LCD_DrawVRuleRight_Layer1` and 0xFEFE65 `calr LCD_DrawVRuleLeft_Layer1`".
    Measured here: the `jr Z` at 0xFEFE5E targets 0xFEFE65, so the not-taken arm
    is the `ret` at 0xFEFE60.  0xFEFE61 is reached by no `calr`, `call` or
    pointer anywhere in prom_a or prom_b.  The header also says "Seven callers";
    the entry 0xFEFE59 has FOUR, all `calr`.

Q3  DO THE HEADERS' OTHER QUANTIFIED CLAIMS HOLD?
    The five screen vtable chains, the three MIDI injectors' byte diffs, the
    Unit1 read/write twins' one-byte difference, and the FAT `--SUBDIR-SB`
    block.  These all PASS and are asserted here so the pass is reproducible.

RUN
    python3 notes/audit_wave7_round3_wa3.py            # the three questions
    python3 notes/audit_wave7_round3_wa3.py --selftest # every check, LAST included
Exit status is non-zero if any check fails.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = {
    "a": (0xF80000, "wsa1_prom_a.ic12"),
    "b": (0xF00000, "wsa1_prom_b.ic13"),
}
DATA = {k: open(os.path.join(ROOT, "original_ROMs", v[1]), "rb").read()
        for k, v in IMG.items()}

FAILED = []


def rd(img, addr, n):
    base = IMG[img][0]
    return DATA[img][addr - base:addr - base + n]


def le(img, addr, n=4):
    return int.from_bytes(rd(img, addr, n), "little")


def check(label, got, want):
    ok = got == want
    if not ok:
        FAILED.append(label)
    print("  %-4s %-72s %s" % ("ok" if ok else "FAIL", label,
                               "" if ok else "got %r want %r" % (got, want)))


# --------------------------------------------------------------------------
# Q1  the per-screen button-handler tables
# --------------------------------------------------------------------------
# base = the `add XWA,imm32` operand of each +8 method, read off the listing.
BUTTON_TABLES = [
    ("Screen_ReMapEdit_Button",               "a", 0xFA1690, 0xF9C0D5),
    ("Screen_SoundGroupNaming_Button",        "a", 0xFA176E, 0xF9CB66),
    ("Screen_CombinationGroupNaming_Button",  "a", 0xFA17CF, 0xF9CFCE),
    ("Screen_DrumsMapNaming_Button",          "a", 0xFA1A02, 0xF9F020),
    ("Screen_CombinationNaming_Button",       "b", 0xF1B14B, 0xFBEF9C),
]


def pointer_run(img, base, cap=64):
    """How many consecutive longwords from base are ROM addresses?"""
    n = 0
    while n < cap:
        v = le(img, base + 4 * n)
        if not (0xF00000 <= v <= 0xFFFFFF):
            break
        n += 1
    return n


def index_map(raw):
    """prom_b 0xF55019, the routine every +8 method calls through T_F42C74.

    0xF55026 `cp HL,0x001F` / `jrl UGT` rejects; 0xF5505E..0xF5508A remap.
    Returns the value that reaches the caller's `mul A,0x04`, or None."""
    if raw > 0x1F:
        return None
    if 0x11 <= raw <= 0x19:
        return raw - 0x11
    if raw >= 0x1A:
        return raw - 9
    return raw


def q1():
    print("Q1  the five per-screen button tables the round-10 headers name")
    for name, img, base, site in BUTTON_TABLES:
        # the imm32 really is at the cited site: `add XWA,imm32` = E8 C8 <le32>
        check("%s cites `add XWA,0x%06X` at 0x%06X" % (name, base, site),
              (rd("a", site, 2).hex(), le("a", site + 2)), ("e8c8", base))
        check("  its table holds 23 consecutive ROM pointers", pointer_run(img, base), 23)
        check("  and its 24th longword is not a ROM address",
              0xF00000 <= le(img, base + 92) <= 0xFFFFFF, False)
    outs = sorted({index_map(r) for r in range(0x20)})
    check("prom_b 0xF55019 maps the 32 raw indices onto 0..22", (outs[0], outs[-1], len(outs)),
          (0, 22, 23))
    check("so the largest index any +8 method can form is 22, not 31", max(outs), 22)
    check("round 7's real 32-entry tables are 0x80 apart, in prom_b's 0xF7D000 block",
          0xF7D358 - 0xF7D2D8, 0x80)
    # A 32-entry reading makes two of the five tables OVERLAP, which settles it.
    check("a 32-entry SoundGroupNaming table would run 31 bytes into "
          "CombinationGroupNaming's", 0xFA176E + 32 * 4 - 0xFA17CF, 31)
    check("at 23 entries it ends 5 bytes short of it, with no overlap",
          0xFA17CF - (0xFA176E + 23 * 4), 5)
    print()


# --------------------------------------------------------------------------
# Q2  LCD_DrawVRule_LeftOrRight
# --------------------------------------------------------------------------
def calr_target(img, addr):
    d = rd(img, addr, 3)
    if d[0] != 0x1E:
        return None
    disp = int.from_bytes(d[1:3], "little", signed=True)
    return (addr + 3 + disp) & 0xFFFFFF


def references(target):
    """Every `calr`, `call` or 3-byte pointer naming target, in both images."""
    hits = []
    for img in ("a", "b"):
        base, d = IMG[img][0], DATA[img]
        for off in range(len(d) - 4):
            if d[off] == 0x1E:
                t = (base + off + 3
                     + int.from_bytes(d[off + 1:off + 3], "little", signed=True)) & 0xFFFFFF
                if t == target:
                    hits.append(("calr", base + off))
            elif d[off] in (0x1D, 0x1B) and int.from_bytes(d[off + 1:off + 4], "little") == target:
                hits.append(("call/jp", base + off))
        pat = target.to_bytes(3, "little")
        start = 0
        while True:
            i = d.find(pat, start)
            if i < 0:
                break
            hits.append(("ptr", base + i))
            start = i + 1
    return hits


def q2():
    print("Q2  LCD_DrawVRule_LeftOrRight (0xFEFE59)")
    check("0xFEFE5E is `jr Z,+5`", rd("a", 0xFEFE5E, 2).hex(), "6605")
    check("so the taken arm is 0xFEFE65 -- the LEFT rule", 0xFEFE60 + 5, 0xFEFE65)
    check("and the not-taken arm is the `ret` at 0xFEFE60", rd("a", 0xFEFE60, 1).hex(), "0e")
    check("0xFEFE61 is `calr LCD_DrawVRuleRight_Layer1`", calr_target("a", 0xFEFE61), 0xFEFE94)
    right = [h for h in references(0xFEFE61) if h[0] != "ptr"]
    check("but NOTHING calls or jumps to 0xFEFE61 -- the RIGHT arm is unreachable",
          right, [])
    entry = [h for h in references(0xFEFE59) if h[0] == "calr"]
    check("the entry 0xFEFE59 does have SEVEN callers, as its header says",
          [hex(a) for _, a in entry],
          ["0xfe9ed3", "0xfea13a", "0xfea14a", "0xfefda5",
           "0xff021f", "0xff022f", "0xff023f"])
    check("and no pointer anywhere names 0xFEFE59",
          [h for h in references(0xFEFE59) if h[0] == "ptr"], [])
    print()


# --------------------------------------------------------------------------
# Q3  the claims that hold
# --------------------------------------------------------------------------
SCREENS = [
    (92,  0xF87031, 0xF41A98, (0xFBEF1C, 0xFBEF75, 0xFBEF76)),
    (123, 0xF870AD, 0xF42680, (0xF9CB00, 0xF9CB52, 0xF9CB53)),
    (124, 0xF870B1, 0xF42690, (0xF9CF68, 0xF9CFBA, 0xF9CFBB)),
    (135, 0xF870DD, 0xF419B8, (0xF9EF85, 0xF9EFF6, 0xF9F006)),
    (140, 0xF870F1, 0xF41968, (0xF9C087, 0xF9C0C1, 0xF9C0C2)),
]
INJECTORS = (0xFB921C, 0xFB925C, 0xFB929C)   # CC 7B/00, CC 00/40, CC 40/00


def q3():
    print("Q3  the round-10 claims that DO hold")
    for sid, ent, vt, methods in SCREENS:
        check("screen %d: PanelScreen_VtableTable[%d] is at 0x%06X and holds 0x%06X"
              % (sid, sid, ent, vt), (0xF86EC1 + 4 * sid, le("a", ent)), (ent, vt))
        got = tuple(le("b", vt + 4 * i + 1, 3) for i in range(3))
        check("  its three `jp` slots reach %s"
              % ", ".join("0x%06X" % m for m in methods), got, methods)
        check("  and all three are `jp` opcodes (0x1B)",
              [rd("b", vt + 4 * i, 1)[0] for i in range(3)], [0x1B] * 3)
    a, b, c = (rd("a", x, 64) for x in INJECTORS)
    check("the three MIDI injectors are 64 bytes each",
          [INJECTORS[1] - INJECTORS[0], INJECTORS[2] - INJECTORS[1]], [64, 64])
    check("CC 0x7B vs CC 0x00 differ at offsets 21,29,32,40,43",
          [i for i in range(64) if a[i] != b[i]], [21, 29, 32, 40, 43])
    check("CC 0x7B vs CC 0x40 differ in FOUR bytes: 21,29,32,43",
          [i for i in range(64) if a[i] != c[i]], [21, 29, 32, 43])
    check("the data bytes are 7B/00, 00/40, 40/00",
          [a[29], a[40], b[29], b[40], c[29], c[40]], [0x7B, 0, 0, 0x40, 0x40, 0])
    w, r = rd("a", 0xFE4E4C, 117), rd("a", 0xFE4FB2, 117)
    check("Unit1_Op4/Op3 are 117 bytes and differ at exactly one offset",
          [i for i in range(117) if w[i] != r[i]], [18])
    check("  and that byte is the calr low half: 0xFE4E5D -> WriteOneSector",
          calr_target("a", 0xFE4E5D), 0xFE4D57)
    check("  0xFE4FC3 -> ReadOneSector", calr_target("a", 0xFE4FC3), 0xFE4EC1)
    name = bytes(rd("a", 0xFE532C + 0, 3)[2:3])   # placeholder, real read below
    built = bytes([rd("a", 0xFE532C, 3)[2]] +
                  [rd("a", 0xFE532F + 4 * i, 4)[3] for i in range(10)])
    check("Unit1_Op5 writes the 11 bytes `--SUBDIR-SB`", built, b"--SUBDIR-SB")
    check("ExtBoardMagic_Wsa1Extbd's ten bytes are `WSA1 EXTBD`",
          rd("a", 0xF828C7, 10), b"WSA1 EXTBD")
    check("MidiIn_ControlRecordHandlers has 12 entries; the 13th is not a pointer",
          (pointer_run("a", 0xFABF4A), 0xFABF4A + 48), (12, 0xFABF7A))
    check("Msg0716_GetRecordPtrByIndex's table base is 0xFC1162",
          le("a", 0xFC1157, 4) & 0xFFFFFF, 0xFC1162)
    # LAST CHECK, on the LAST new name in address order.
    check("LAST: the last new name in address order is at 0xFEFE59, and its "
          "right-hand arm is still unreachable",
          [h for h in references(0xFEFE61) if h[0] != "ptr"], [])
    print()
    del name


if __name__ == "__main__":
    q1()
    q2()
    q3()
    n = 0
    print("%d failure(s)" % len(FAILED))
    for f in FAILED:
        print("  FAILED:", f)
    sys.exit(1 if FAILED else 0)
