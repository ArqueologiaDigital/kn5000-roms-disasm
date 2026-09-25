#!/usr/bin/env python3
r"""prom_b 0xF124A6-0xF12F23: the EQ-graph display-list template and the DSP-effect descriptor pool.

QUESTION THIS ANSWERS
    wsa1/prom_b/wsa1_prom_b.s carried 0xF124A6-0xF12F23 (2,686 bytes) as eleven
    objects a content classifier had cut out -- `Data_F124A6`, `Data_F12582`,
    `Data_F1284A` ("Unknown: everything about it except its bytes") and eight
    `RamPtrTable_*` / `Data_*` fragments whose "RAM addresses" are runs of the
    4-byte group 00 00 FF FF.  This script re-derives, from the ROM bytes alone,
    what the span really is, and (with --apply) writes it back typed:

      1. 0xF124A6-0xF124EB (70 bytes) is the template sub_F0FF3F copies onto its
         stack with `ldirw` (BC = 35 words) before running it with
         T_DisplayList_Run_Stack(start, start+70): seven interpreter-A records
         of 10 bytes, `op, 0x0A, x0, y0, x1, y1`.  Checked: the ROM holds
         `ld BC,0x0023` / `lda XIY,0xF124A6` / `ldirw` at 0xF0FF4A-0xF0FF55, and
         each record's length byte is 0x0A; records 0-1 are op 0x12 (prom_a
         LCD_Svc_12_DrawVLineDashed) and 2-6 op 0x00 (LCD_Svc_00_DrawLine).
      2. 0xF124EC-0xF12F23 tiles EXACTLY into 57 descriptor records, one per
         distinct entry of EffectParamDescriptors_F12F24 (0xF12F24, 128 pointers
         indexed by the effect-algorithm number): each record is N >= 8 groups
         of four bytes, then the group FF FF FF FF, then the word 0xFFFF, then
         a word W -- and the next record starts right after W.  Checked: the
         walk from 0xF124EC meets every one of the 57 pointer targets exactly,
         no record starts anywhere else, and the last record ends at 0xF12F24.
      3. per group: byte 0 is a row of EffectParamNames_F15024 (< 100), byte 1
         the value type (< 32, the units column's size), byte 2 the parameter's
         slot or 0xFF, byte 3 the group's OWN INDEX or 0xFF.  Every group before the
         terminator is either LIVE (slot != 0xFF) or the padding group
         00 00 FF FF, and padding only follows live groups.
      4. W equals (highest live slot + 1) in all 57 records.  No reader of W is
         claimed: see the header this script writes.

RUN
    python3 notes/promb-2026-09-25/effect_descriptor_pool.py            # checks + table
    python3 notes/promb-2026-09-25/effect_descriptor_pool.py --emit     # print the asm
    python3 notes/promb-2026-09-25/effect_descriptor_pool.py --apply    # write it into the source
Always follow --apply with `make gate-wsa1`.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
BASE = 0xF00000
TEMPLATE, POOL, TABLE = 0xF124A6, 0xF124EC, 0xF12F24
NAMES, PNAMES, UNITS = 0xF147AC, 0xF15024, 0xF156C8
TEMPLATE_LABEL = "EqGraph_DisplayListTemplate"
OLD_TEMPLATE_LABEL = "Data_F124A6"
FAIL = []


OLD_DRAW, NEW_DRAW = "sub_F0FF3F", "EqGraph_Draw"
OLD_DRAW_UNKNOWN = """;                    the address.
; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated,
;          per this tree's rule that a stated gap beats a plausible guess.
; --------------------------------------------------------------------------
sub_F0FF3F:"""
DRAW_NAME_BLOCK = """;                    the address.
; Name:    EqGraph_Draw -- named 2026-09-25 (lane promb).
; Evidence: it copies EqGraph_DisplayListTemplate (35 words, `ldirw` at
;          0xF0FF55) into a 70-byte frame and patches the copy from the four
;          bytes (0x2640) (0x2641) (0x2642) (0x2643): x = 6*v+67 for the first
;          two, y = 135-v for the last two (the offsets are in the template's
;          header).  With (0x2540) = 2 it then runs DL_F14297 -- op 0x1B,
;          LCD_Svc_1B_EraseRect over (63,85)-(228,138), the graph box.  If
;          IndexedTable_GetByte(23, (0x2797)+97) returns 0, or (0x207C) is
;          0x6B, it runs DL_F1428D -- op 0x11, the line (63,111)-(228,111),
;          which is y = 135-24 and entry 24 of the gain strings is "  0.0" --
;          and then the patched frame through T_DisplayList_Run_Stack;
;          otherwise it runs DL_F13F32, whose first record prints "BYPASS".
;          Both callers (sub_F0FED6 via 0xF0FF30, sub_F123F4 via 0xF1244B)
;          fill (0x2640)-(0x2643) first and run DL_F1465F, which prints
;          (0x2640)/(0x2641) through DLBTable_1k125k16k2k25k315k4k (frequency
;          strings) and (0x2642)/(0x2643) through DLBTable_F15C93 (-12.0 ..
;          +12.0 dB in 0.5 dB steps).  So the four bytes are two frequencies
;          and two gains, and this draws a two-band EQ response.  Which EQ
;          each caller edits is not decoded here.
;          python3 notes/promb-2026-09-25/effect_descriptor_pool.py checks
;          the template, the captions, the box, the 0 dB line and the call
;          order.
; ⚠ CORRECTED 2026-09-25: this header used to end `Unknown: what the routine
;          is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's
;          rule that a stated gap beats a plausible guess.`
; --------------------------------------------------------------------------
sub_F0FF3F:"""


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def camel(s):
    toks = re.findall(r'[A-Za-z0-9]+', s)
    return "".join(t[:1].upper() + t[1:].lower() for t in toks)


class Rom:
    def __init__(self):
        self.b = open(ROMB, "rb").read()

    def at(self, a, n=1):
        return self.b[a - BASE:a - BASE + n]

    def w(self, a):
        return int.from_bytes(self.at(a, 2), "little")

    def l(self, a):
        return int.from_bytes(self.at(a, 4), "little")


def derive(rom, quiet=False):
    say = (lambda *a: None) if quiet else print
    # 1. the template's copier
    raw = rom.at(0xF0FF4A, 13).hex()
    check("0xF0FF4A: 31 23 00 f2 a6 24 f1 35 be ba 34 95 11 = `ld BC,0x0023 / lda XIY,0xF124A6 /"
          " lda XIX,XIZ-0x46 / ldirw`", raw == "312300f2a624f135beba349511")
    run = rom.at(0xF10069, 14).hex()
    check("0xF10069: ec 89 e9 c8 46 00 00 00 39 3c 1d 00 2e f4 = `ld XBC,XIX / add XBC,0x46 /"
          " push XBC / push XIX / call 0xF42E00` (T_DisplayList_Run_Stack)",
          run == "ec89e9c84600000039 3c1d002ef4".replace(" ", ""))
    recs = []
    for k in range(7):
        a = TEMPLATE + 10 * k
        op, ln = rom.at(a, 2)
        words = [rom.w(a + 2 + 2 * i) for i in range(4)]
        recs.append((a, op, ln, words))
    check("template: 7 records, every length byte 0x0A", all(r[2] == 0x0A for r in recs))
    check("template: ops are 12 12 00 00 00 00 00",
          [r[1] for r in recs] == [0x12, 0x12, 0, 0, 0, 0, 0])
    check("template ends exactly where the pool begins (0xF124A6 + 70 = 0xF124EC)",
          TEMPLATE + 70 == POOL)

    # 1b. why "EQ": the captions, the box, the 0 dB line, the BYPASS branch
    cap = [rom.at(0xF1465F + 15 * k, 15) for k in range(4)]
    check("DL_F1465F: four interpreter-B op-02 records reading (0x2640) (0x2641) through "
          "0xF15A7C and (0x2642) (0x2643) through 0xF15C93, 5-byte entries",
          [(c[0], c[1], int.from_bytes(c[2:4], "little"), int.from_bytes(c[7:11], "little"),
            int.from_bytes(c[11:13], "little")) for c in cap] ==
          [(2, 15, 0x2640, 0xF15A7C, 5), (2, 15, 0x2641, 0xF15A7C, 5),
           (2, 15, 0x2642, 0xF15C93, 5), (2, 15, 0x2643, 0xF15C93, 5)])
    gains = [rom.at(0xF15C93 + 5 * k, 5).decode("latin-1") for k in range(49)]
    check("DLBTable_F15C93 entries 0..48 are -12.0 .. +12.0 in 0.5 dB steps, entry 24 '  0.0'",
          [g.replace(" ", "") for g in gains] ==
          [("%+.1f" % (x / 2)).replace("+0.0", "0.0") for x in range(-24, 25)]
          and gains[24] == "  0.0")
    check("DL_F14297 = 1B 0A (63,85)-(228,138): op 0x1B (LCD_Svc_1B_EraseRect), the graph box",
          rom.at(0xF14297, 10).hex() == "1b0a3f005500e4008a00")
    check("DL_F1428D = 11 0A (63,111)-(228,111): op 0x11 (LCD_Svc_11_DrawHLineDither), y 111 = 135-24",
          rom.at(0xF1428D, 10).hex() == "110a3f006f00e4006f00")
    check("DL_F13F32's first record is op 0x20, text 'BYPASS'",
          rom.at(0xF13F32, 10) == b"\x20\x0a\xc7\x10BYPASS")
    body = rom.at(0xF10031, 0xF1008E - 0xF10031).hex()
    seq = [body.find(x) for x in ("f29742f131", "1d082ef4", "0b1700", "d1972721", "d9c86100",
                                  "c17c203f6b", "f28d42f131", "1d002ef4", "f2323ff131")]
    check("EqGraph_Draw 0xF10031-0xF1008D: lda DL_F14297 / call RunOne / push 23 / (0x2797) / +0x61 /"
          " cp (0x207C),0x6B / lda DL_F1428D / call Run_Stack(frame) / else lda DL_F13F32, in order",
          all(x >= 0 for x in seq) and seq == sorted(seq))

    # 2. the pool
    ptrs = [rom.l(TABLE + 4 * k) for k in range(128)]
    targets = sorted(set(ptrs))
    names = [rom.at(NAMES + 16 * k, 16).decode("latin-1").strip() for k in range(128)]
    pn = [rom.at(PNAMES + 17 * k, 17).decode("latin-1").strip().rstrip(":").strip()
          for k in range(113)]
    units = [rom.at(UNITS + 7 * k, 7).decode("latin-1").strip() for k in range(32)]
    check("EffectParamDescriptors_F12F24 has 57 distinct targets", len(targets) == 57)
    users = {}
    for k, p in enumerate(ptrs):
        users.setdefault(p, []).append(k)
    records = []
    a = POOL
    ok_groups = True
    ok_pad = True
    while a < TABLE:
        start = a
        groups = []
        while True:
            g = rom.at(a, 4)
            a += 4
            if g == b"\xff\xff\xff\xff":
                break
            groups.append(tuple(g))
            if len(groups) > 40:
                break
        ffff = rom.w(a)
        wv = rom.w(a + 2)
        a += 4
        records.append(dict(start=start, groups=groups, ffff=ffff, w=wv, end=a))
        live = [g for g in groups if g[2] != 0xFF]
        pad = [g for g in groups if g[2] == 0xFF]
        for i, g in enumerate(groups):
            if g[2] != 0xFF:
                ok_groups &= g[0] < 100 and g[1] < 32 and g[3] in (i, 0xFF)
            else:
                ok_pad &= g == (0, 0, 0xFF, 0xFF)
        # padding only after the live groups
        idx = [i for i, g in enumerate(groups) if g[2] == 0xFF]
        ok_pad &= (not idx) or idx == list(range(idx[0], len(groups)))
    check("the walk from 0xF124EC ends exactly at 0xF12F24", a == TABLE)
    check("the walk makes exactly 57 records", len(records) == 57)
    check("every record start is a pointer-table target, and every target a record start",
          [r["start"] for r in records] == targets)
    check("every record has >= 8 groups before FF FF FF FF",
          all(len(r["groups"]) >= 8 for r in records))
    check("every record's terminator is followed by the word 0xFFFF",
          all(r["ffff"] == 0xFFFF for r in records))
    check("live groups: byte0 < 100, byte1 < 32, byte3 == the group's own index or 0xFF",
          ok_groups)
    nl = sum(1 for r in records for g in r["groups"] if g[2] != 0xFF)
    ni = sum(1 for r in records for i, g in enumerate(r["groups"]) if g[2] != 0xFF and g[3] == i)
    say("  (%d live groups: %d carry their own index at +3, %d carry 0xFF)" % (nl, ni, nl - ni))
    check("non-live groups are exactly 00 00 FF FF, and only after the live ones", ok_pad)
    wrule = all(r["w"] == max([g[2] for g in r["groups"] if g[2] != 0xFF] + [0]) + 1
                for r in records)
    check("W == highest live slot + 1 in all 57 records", wrule)
    for r in records:
        ks = users[r["start"]]
        if len(ks) > 1 and r["start"] != ptrs[0]:
            r["label"] = "EffectDesc_Unused"
            r["what"] = "the %d algorithm numbers whose EffectNames_F147AC entry is the " \
                        "`----------` placeholder" % len(ks)
        else:
            r["label"] = "EffectDesc_" + camel(names[ks[0]])
            r["what"] = "algorithm %d, `%s`" % (ks[0], names[ks[0]])
        r["users"] = ks
    labs = [r["label"] for r in records]
    check("the 57 labels are distinct", len(set(labs)) == 57)
    unused = [r for r in records if r["label"] == "EffectDesc_Unused"]
    check("exactly one record serves the placeholder slots, and its users are the 72 "
          "`----------` names", len(unused) == 1 and len(unused[0]["users"]) == 72 and
          all(names[k] == "----------" for k in unused[0]["users"]))
    if not quiet:
        for r in records:
            live = [g for g in r["groups"] if g[2] != 0xFF]
            say("  0x%06X %-28s %2d live + %d pad, W=%2d  users %s" % (
                r["start"], r["label"], len(live), len(r["groups"]) - len(live), r["w"],
                r["users"][:6] + (["..."] if len(r["users"]) > 6 else [])))
    return dict(recs=recs, records=records, ptrs=ptrs, names=names, pn=pn, units=units)


TEMPLATE_HEADER = r"""; --------------------------------------------------------------------------
; EqGraph_DisplayListTemplate -- 0xF124A6-0xF124EB, 70 bytes: an interpreter-A
;   display list of SEVEN 10-byte records that is never run in place.  It is
;   the template of the two-band EQ response graph.
; Read by: EqGraph_Draw (0xF0FF3F) only -- `ldw bc,35` / `lda xiy,(this:24)` /
;   `lda xix,(xiz-70)` / `ldirw` at 0xF0FF4A copies all 35 words onto the
;   routine's stack frame, the code patches the copy, and
;   T_DisplayList_Run_Stack(frame, frame+70) at 0xF10073 runs it.
; Record layout (the interpreter's own, DLHandler_4Words): op, length 0x0A,
;   then four words x0, y0, x1, y1 handed to `swi 7` service `op`.  Records 0-1
;   are op 0x12 = prom_a LCD_Svc_12_DrawVLineDashed, records 2-6 op 0x00 =
;   LCD_Svc_00_DrawLine.
; What is patched, from EqGraph_Draw's stores (offsets into the 70 bytes):
;   XL = 6*(0x2640)+67 at +2 +6 +26 +32;  XH = 6*(0x2641)+67 at +12 +16 +56 +62;
;   XL+12 (clamped to 228) at +36 +42;  XH-12 (clamped to 63) at +46 +52, both
;   replaced by their midpoint when (0x2640) >= (0x2641)-3;
;   YL = 135-(0x2642) at +24 +28 +34;  YH = 135-(0x2643) at +58 +64 +68.
;   So records 0-1 are dashed vertical markers at the two frequencies
;   (y 85..138), and records 2-6 the polyline
;   (63,YL)-(XL,YL)-(XL+12,111)-(XH-12,111)-(XH,YH)-(228,YH).
; Why "EQ": the same caller draws the four values with DL_F1465F, whose
;   records read (0x2640)/(0x2641) through DLBTable_1k125k16k2k25k315k4k (the
;   frequency strings) and (0x2642)/(0x2643) through DLBTable_F15C93, 49
;   entries "-12.0" .. "+12.0" in 0.5 dB steps -- whose entry 24, "  0.0",
;   gives y = 135-24 = 111, exactly the line DL_F1428D draws from (63,111) to
;   (228,111) with op 0x11.  DL_F14297 (op 0x1B, EraseRect) clears
;   (63,85)-(228,138), the graph's box, before the template runs.
; Pre-patch words are the template's own defaults and are kept as they are.
; Re-derived by python3 notes/promb-2026-09-25/effect_descriptor_pool.py
;   (it also wrote this block).
; --------------------------------------------------------------------------"""

POOL_HEADER = r"""; --------------------------------------------------------------------------
; EffectDesc_* -- 0xF124EC-0xF12F23, 2,616 bytes: the DSP-EFFECT PARAMETER
;   DESCRIPTORS, 57 variable-length records, one per distinct entry of
;   EffectParamDescriptors_F12F24 (below), which is indexed by the effect
;   ALGORITHM number (0x2796).  The 57 records tile the span exactly: the
;   walk from 0xF124EC meets every pointer target and nothing else, and ends
;   at 0xF12F24.
; Record: N >= 8 four-byte PARAMETER GROUPS, then the group FF FF FF FF, then
;   the word 0xFFFF, then a word W.  A group is
;     +0  name   row of EffectParamNames_F15024 (17-char rows); read by
;                DspEffect_LoadParamNames (0xF10FF1), EIGHT groups from
;                4*(0x2792) unconditionally -- which is why every record has
;                at least eight groups: an unused line reads row 0, the blank.
;     +1  type   value type 0x01-0x1E: DspEffect_PaintParamEditor (0xF11057)
;                stores it to (0x2640) to pick the units string
;                (DLTable_HzHzHzHzHzSSSSMsMsMs via DLB_Records_F157A8) and
;                indexes ScreenTable_F13264 / ScreenDisplayLists_F132E4 with
;                4*type; sub_F1069A (0xF1069A) indexes ScreenTable_F131E4 with
;                it (the editor).
;     +2  slot   the parameter's slot, 1-based; a 16-bit parameter takes two
;                (DELAY L = 2, DELAY R = 4).  0xFF ends the list: sub_F105B8
;                (0xF105B8) stops scrolling at the first group whose +2 is
;                0xFF, and sub_F116C4's loop (0xF116E3) stops on it too.
;     +3  mark   the group's OWN INDEX, or 0xFF -- in all 435 live groups,
;                235 and 200 of them.  DspEffect_PaintParamEditor compares it
;                with IndexedTable_GetByte(22, (0x2797)+97) and paints
;                Font_Svc06 glyph 0x11 (a filled right-pointing triangle) on
;                a match, 0x91 (a centred dot) on a mismatch and a blank for
;                0xFF -- via the second group of DLB_Records_F157A8, whose
;                string table at 0xF15898 is ' ', 0x11, 0x91.  So 0xFF marks
;                a parameter that can never be the selected one, and the
;                stored byte is a PARAMETER INDEX of this list.  OPEN
;                QUESTION, about that RAM byte and not about these records:
;                what the selection it holds is used for.
;   A group whose +2 is 0xFF is padding and is always exactly 00 00 FF FF.
; W: in all 57 records W = (highest live slot) + 1, i.e. one past the last
;   slot the descriptor names.  NO READER OF W IS CLAIMED.  The 13 sites that
;   index this pool (all in prom_b, 0xF1060F-0xF11F6C: prom_a and prom_c
;   spell 0xF12F24 nowhere, at offsets -32..+32 too) all read 4*i+0..3 from a
;   record start and stop at the first +2 == 0xFF, which every record supplies
;   before its tail.  Shapes searched: base+4*i+{0,1,2,3}; the table address
;   and base minus 4*k for k = -8..8 as a 24-bit operand in all three images.
; Names below are the effect's EffectNames_F147AC entry; each group's comment
;   gives the parameter name (its EffectParamNames_F15024 row) and, where the
;   units column has one, the unit.
; Re-derived by python3 notes/promb-2026-09-25/effect_descriptor_pool.py
;   (checks, the per-effect table, and this block); the reader shapes by
;   notes/promb-2026-09-25/effect_descriptor_probe.py.
; ⚠ REPLACES eleven objects a content classifier cut this span into --
;   Data_F124A6 (72 B), RamPtrTable_F124EE, Data_F1250A, RamPtrTable_F12522,
;   Data_F12532, RamPtrTable_F1254A, Data_F1255A, RamPtrTable_F12572,
;   Data_F12582 (452 B), RamPtrTable_F12746, Data_F12766 (200 B),
;   RamPtrTable_F1282E and Data_F1284A (1,754 B).  Their headers said
;   "Unknown: everything about it except its bytes"; the "RAM addresses"
;   were runs of the padding group 00 00 FF FF read as 32-bit words.
; --------------------------------------------------------------------------"""


def fmt_group(g):
    b0, b1, b2, b3 = g
    return "%d, 0x%02x, %s, %s" % (b0, b1, ("%d" % b2) if b2 != 0xFF else "0xff",
                                   ("%d" % b3) if b3 != 0xFF else "0xff")


def emit(d):
    out = [TEMPLATE_HEADER, TEMPLATE_LABEL + ":"]
    for (a, op, ln, words) in d["recs"]:
        svc = {0x12: "LCD_Svc_12_DrawVLineDashed", 0x00: "LCD_Svc_00_DrawLine"}[op]
        out.append("\t.byte\t0x%02x, 0x%02x\t; %06X  op %02X, 10 bytes -> %s" % (op, ln, a, op, svc))
        out.append("\t.short\t%s\t; %06X  x0, y0, x1, y1 (template defaults)"
                   % (", ".join("%d" % w for w in words), a + 2))
    out.append("")
    out.append("")
    out.append(POOL_HEADER)
    for r in d["records"]:
        live = [g for g in r["groups"] if g[2] != 0xFF]
        out.append("; %s -- %s: %d parameter%s, W = %d" % (
            r["label"], r["what"], len(live), "" if len(live) == 1 else "s", r["w"]))
        out.append(r["label"] + ":")
        a = r["start"]
        for i, g in enumerate(r["groups"]):
            if g[2] == 0xFF:
                desc = "padding (blank line)"
            else:
                u = d["units"][g[1]]
                desc = "%-17s type 0x%02X%s" % (d["pn"][g[0]], g[1], (" " + u) if u else "")
            out.append("\t.byte\t%s\t; %06X  [%d] %s" % (fmt_group(g), a, i, desc))
            a += 4
        out.append("\t.byte\t0xff, 0xff, 0xff, 0xff\t; %06X  end of groups" % a)
        out.append("\t.short\t0xffff, %d\t; %06X  0xFFFF, W" % (r["w"], a + 4))
    out.append("")
    out.append("")
    return "\n".join(out) + "\n"


def block_start(L, i):
    """First line of the comment/blank block directly above line i."""
    j = i
    while j > 0 and (L[j - 1].startswith(";") or not L[j - 1].strip()):
        j -= 1
    # keep one separating blank line above, as the file does
    while j < i and not L[j].strip():
        j += 1
    return j


def apply(d):
    raw = open(SRC, "rb").read()
    L = raw.decode("latin-1").split("\n")
    lab_i = [i for i, t in enumerate(L)
             if t.startswith(OLD_TEMPLATE_LABEL + ":") or t.startswith(TEMPLATE_LABEL + ":")]
    tab_i = [i for i, t in enumerate(L) if t.startswith("EffectParamDescriptors_F12F24:")]
    assert len(lab_i) == 1 and len(tab_i) == 1, (lab_i, tab_i)
    s, e = block_start(L, lab_i[0]), block_start(L, tab_i[0])
    new = emit(d).encode("utf-8").decode("latin-1").rstrip("\n").split("\n") + ["", ""]
    L2 = L[:s] + new + L[e:]
    # the 128 pointers
    t = [i for i, x in enumerate(L2) if x.startswith("EffectParamDescriptors_F12F24:")][0]
    lab_of = {r["start"]: r["label"] for r in d["records"]}
    k = 0
    i = t + 1
    pat = re.compile(r'^(\t\.long\t)([^;]*?)(\t; ([0-9A-F]{6})  \[(\d+)\].*)$')
    while k < 128:
        m = pat.match(L2[i])
        assert m, (i, L2[i])
        assert int(m.group(4), 16) == TABLE + 4 * k and int(m.group(5)) == k, L2[i]
        tgt = d["ptrs"][k]
        name = d["names"][k]
        L2[i] = "%s%s\t; %06X  [%d] -> 0x%06X  %s" % (m.group(1), lab_of[tgt], TABLE + 4 * k, k,
                                                       tgt, name)
        k += 1
        i += 1
    txt = "\n".join(L2)
    txt = re.sub(r'\b%s\b' % OLD_TEMPLATE_LABEL, TEMPLATE_LABEL, txt)
    # the routine that runs the template: name it and say why
    if OLD_DRAW + ":" in txt:
        assert OLD_DRAW_UNKNOWN in txt
        txt = txt.replace(OLD_DRAW_UNKNOWN,
                          DRAW_NAME_BLOCK.encode("utf-8").decode("latin-1"), 1)
        txt = re.sub(r'\b%s(\w*)\b' % OLD_DRAW, lambda m: NEW_DRAW + m.group(1), txt)
    data = txt.encode("latin-1")        # encode BEFORE opening: a failed encode must not truncate
    open(SRC, "wb").write(data)
    print("wrote %s: replaced lines %d-%d with %d lines" % (SRC, s + 1, e, len(new)))


def main():
    rom = Rom()
    quiet = "--emit" in sys.argv
    d = derive(rom, quiet=quiet)
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--emit" in sys.argv:
        sys.stdout.write(emit(d))
    elif "--apply" in sys.argv:
        apply(d)
    else:
        print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
