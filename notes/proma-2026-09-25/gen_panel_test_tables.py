#!/usr/bin/env python3
r"""Retype two code-framed panel tables of prom_a as the data their readers say they are.

QUESTION THIS ANSWERS
    Two stretches of wsa1_prom_a.s were framed as instructions and are tables:

    A. 0xF8C8AC-0xF8C8C1 (22 B, framed `m_and_rm ... / xor D,0 / nop / and
       (0xc9c2),b / ...`): PanelLedWireMap_Variant1/2.  Reader: the code after
       sub_F8C842 / sub_F8C846 (prom_b directory entries), at 0xF8C851:
           ld XIX,0x00F8C8AC ; if (0xC4) != 1: ld XIX,0x00F8C8B7
           ld W,(XIX+W)                   ; `mx8_ld_rm MXB,ra_IX,rb_W,r0`
       then .LF8C86A stores W and then A into the ring at RAM 0x2BA0.  The
       entries are wire codes 0xC0.. -- the first byte of a panel packet, the
       same numbering PanelWireGroupMap_Variant1/2 map FROM.
    B. 0xF94ED8-0xF95117 (576 B, framed as `ld W,0x20` x64, `push SR / reti` x40
       ...): the TEST MODE's switch-to-LED tables.  Reader: TestMode_PanelSwitchesToLeds, in the
       service-test module (Paint_PanelSwLedCheck & co.), which drains the panel
       queue at RAM 0x2B40 and for each packet (wire, mask):
           L = (wire & 0x1F) | ((wire & 0xC0) >> 1)          ; 0xF94E35-0xF94E3E
           W = map[L]  (0xF94ED8 variant 1, 0xF95008 else)   ; 0xF94E42-0xF94E52
           if W == 0x20: next                                ; 0xF94E80
           XHL = rows + 16*W (0xF94F58 / 0xF95088)            ; 0xF94E88-0xF94E9F
           A = BitMask_LowestSetBitOrdinal(mask) = 1 + index of its lowest set bit (0 if none)
           WA = word[XHL + 2*(A-1)]  ; call T_F40670 -> sub_F8C846   (0xF94EBD)
       i.e. the switch pressed lights LED (PanelLedWireMap[W>>8], bit mask).
       The maps are the same index function and 0x20 "no group" convention as
       PanelWireGroupMap_Variant1/2 (0xF8A109/0xF8A189) restricted to the button
       wires; the row counts are 1 + the largest group each map holds (0x0A -> 11,
       0x08 -> 9), and the four tables tile 0xF94ED8..0xF95118 exactly, ending on
       BitMask_LowestSetBitOrdinal's first instruction.

    Checks (refuses to write otherwise): the reader instructions are at the
    cited addresses with the cited immediates; the tilings; the maps' values
    are group numbers or 0x20; no label other than the orphan `sub_F94FAE`
    (referenced by nothing in either image) lies inside, and no branch targets
    inside either span.

RUN
    make gate-wsa1
    python3 notes/proma-2026-09-25/gen_panel_test_tables.py [--apply]
    make gate-wsa1
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE


def u8(x):
    return x.encode("utf-8").decode("latin-1")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    m = srcmap.load()
    R = m.rom
    g = lambda ad, n=1: R[ad - B:ad - B + n]  # noqa: E731
    # readers, byte-exact
    assert g(0xF8C851, 5) == bytes([0x44, 0xAC, 0xC8, 0xF8, 0x00])
    assert g(0xF8C85C, 5) == bytes([0x44, 0xB7, 0xC8, 0xF8, 0x00])
    assert g(0xF94E42, 5) == bytes([0x45, 0xD8, 0x4E, 0xF9, 0x00])
    assert g(0xF94E4D, 5) == bytes([0x45, 0x08, 0x50, 0xF9, 0x00])
    assert g(0xF94E88, 5) == bytes([0x45, 0x58, 0x4F, 0xF9, 0x00])
    assert g(0xF94E93, 5) == bytes([0x45, 0x88, 0x50, 0xF9, 0x00])
    assert g(0xF94E9C, 3) == bytes([0xEB, 0xEE, 0x04])          # sll 4,XHL: 16-byte rows
    m1, m2 = g(0xF94ED8, 128), g(0xF95008, 128)
    for mp in (m1, m2):
        assert all(x == 0x20 or x <= 0x0A for x in mp)
    n1 = max(x for x in m1 if x != 0x20) + 1
    n2 = max(x for x in m2 if x != 0x20) + 1
    assert (n1, n2) == (11, 9)
    assert 0xF94ED8 + 128 + 16 * n1 == 0xF95008 and 0xF95008 + 128 + 16 * n2 == 0xF95118
    labs = [(hex(ad), n) for ad, ns in m.by_addr.items() for n in ns
            if (0xF8C8AC <= ad < 0xF8C8C2 or 0xF94ED8 <= ad < 0xF95118) and not n.startswith(".L")]
    orphans = ["sub_F94FAE", "sub_F95101", "sub_F9510F"]
    assert sorted(n for _, n in labs) == orphans, labs
    for p in (srcmap.SRC, os.path.join(os.path.dirname(srcmap.WSA1), "wsa1/prom_b/wsa1_prom_b.s")):
        t = open(p, encoding="latin-1").read()
        for o in orphans:
            assert o not in t.replace(o + ":", ""), o
    for f in ("wsa1_prom_a.ic12", "wsa1_prom_b.ic13"):     # nor as a raw 24-bit address
        d = open(os.path.join(srcmap.WSA1, "original_ROMs", f), "rb").read()
        for o in orphans:
            assert int(o[4:], 16).to_bytes(3, "little") not in d, o
    print("readers, tilings (11 + 9 rows), map values, labels: OK")
    if not a.apply:
        return
    L = m.lines
    addr_of = {i: ad for ad, i in m.line_at.items()}

    def span(lo, hi):
        idx = [i for i, ad in addr_of.items() if lo <= ad < hi]
        i0, i1 = min(idx), max(idx)
        for i in range(i0, i1 + 1):
            mm = re.search(r';\s*([0-9A-F]{6})\b', L[i])
            s = L[i].split(";")[0].strip()
            assert not s or s.endswith(":") or (mm and lo <= int(mm.group(1), 16) < hi), (i, L[i])
        return i0, i1

    rows = lambda base, n: ["\t.short %s  ; %06X  group 0x%02X" % (  # noqa: E731
        ", ".join("0x%04X" % int.from_bytes(g(base + 16 * r + 2 * k, 2), "little") for k in range(8)),
        base + 16 * r, r) for r in range(n)]
    maprows = lambda base: ["\t.byte %s  ; %06X  index 0x%02X" % (  # noqa: E731
        ", ".join("0x%02x" % x for x in g(base + 16 * r, 16)), base + 16 * r, 16 * r) for r in range(8)]
    B_TXT = ["; ---------------------------------------------------------------------",
             "; THE SERVICE TEST MODE'S SWITCH-TO-LED TABLES, 0xF94ED8-0xF95117 (576 B)",
             ";",
             "; Read by TestMode_PanelSwitchesToLeds, which drains the panel queue at RAM 0x2B40 and, for each",
             "; packet (wire, mask), computes L = (wire & 0x1F) | ((wire & 0xC0) >> 1)",
             "; (0xF94E35-0xF94E3E), W = map[L] (0xF94E42 / 0xF94E4D by the strap (0xC4)),",
             "; skips W == 0x20, then reads the word at rows + 16*W + 2*(A-1) with A =",
             "; BitMask_LowestSetBitOrdinal(mask), 1 + the index of the mask's lowest set bit (0xF94E88-",
             "; 0xF94EB5), and passes it in WA to T_F40670 -> sub_F8C846 (0xF94EBD), which",
             "; queues (PanelLedWireMap[W], A) to the panel: the switch pressed lights one",
             "; LED.  The maps use PanelWireGroupMap_Variant1/2's index function and 0x20",
             "; convention, restricted to the button wires 0xC0-0xCA; the row counts are",
             "; 1 + the largest group each map holds (0x0A -> 11, 0x08 -> 9); the four",
             "; tables tile the span, which ends on BitMask_LowestSetBitOrdinal's first instruction.",
             "; Was framed as code (`ld W,0x20` x64, `push SR / reti` pairs, `normal`,",
             "; `max`, `halt` ...) under an orphan label sub_F94FAE that nothing in either",
             "; image references.  notes/proma-2026-09-25/gen_panel_test_tables.py checks",
             "; the readers' bytes, the tiling and the map values.",
             "; ---------------------------------------------------------------------"]
    Bnew = (B_TXT + ["TestMode_PanelWireGroupMap_Variant1:"] + maprows(0xF94ED8) +
            ["", "; TestMode_SwitchLedCodes_Variant1 -- 11 groups x 8 LE16 (hi = LED map index W,",
             "; lo = LED bit mask), one per bit of the switch mask; read at 0xF94E88.",
             "TestMode_SwitchLedCodes_Variant1:"] + rows(0xF94F58, 11) +
            ["", "; TestMode_PanelWireGroupMap_Variant2 -- the (0xC4) != 1 map, read at 0xF94E4D;",
             "; 128 entries, 0x20 = no group.",
             "TestMode_PanelWireGroupMap_Variant2:"] + maprows(0xF95008) +
            ["", "; TestMode_SwitchLedCodes_Variant2 -- 9 groups x 8 LE16, read at 0xF94E93.",
             "; Rows 6-8 end in 0x0000 words: bits those groups do not have.",
             "TestMode_SwitchLedCodes_Variant2:"] + rows(0xF95088, 9))
    A_TXT = ["; ---------------------------------------------------------------------",
             "; PanelLedWireMap_Variant1 / _Variant2 -- 11 bytes each: LED index W -> the",
             "; panel wire code (0xC0 | segment) a LED packet is addressed to.",
             "; Read by the code after sub_F8C842 / sub_F8C846 (prom_b directory entries):",
             "; 0xF8C851 `ld XIX,0x00F8C8AC` (0xF8C85C `ld XIX,0x00F8C8B7` when (0xC4) != 1),",
             "; 0xF8C861 `ld W,(XIX+W)`, then .LF8C86A stores W and A into the ring at RAM",
             "; 0x2BA0 -- the packet [wire][mask] (FINDINGS-prom_a-for-the-mame-driver.md 3).",
             "; COUNT 11 is the extent between the two reader-named bases, and after the",
             "; second one sub_F8C8C2 begins; the unused tail entries are 0x00.",
             "; Was framed as code (`m_and_rm`, `xor D,0`, `and (0xc9c2),b`, `nop`s).",
             "; ---------------------------------------------------------------------",
             "PanelLedWireMap_Variant1:",
             "\t.byte %s  ; F8C8AC" % ", ".join("0x%02x" % x for x in g(0xF8C8AC, 11)),
             "PanelLedWireMap_Variant2:",
             "\t.byte %s  ; F8C8B7" % ", ".join("0x%02x" % x for x in g(0xF8C8B7, 11))]
    out = list(L)
    for (lo, hi, new) in sorted([(0xF8C8AC, 0xF8C8C2, A_TXT), (0xF94ED8, 0xF95118, Bnew)], reverse=True):
        i0, i1 = span(lo, hi)
        out[i0:i1 + 1] = [u8(x) for x in new]
    txt = "\n".join(out)
    for old, lab in (("ld XIX,0x00f8c8ac", "PanelLedWireMap_Variant1"), ("ld XIX,0x00f8c8b7", "PanelLedWireMap_Variant2"),
                     ("ld XIY,0x00f94ed8", "TestMode_PanelWireGroupMap_Variant1"),
                     ("ld XIY,0x00f95008", "TestMode_PanelWireGroupMap_Variant2"),
                     ("ld XIY,0x00f94f58", "TestMode_SwitchLedCodes_Variant1"),
                     ("ld XIY,0x00f95088", "TestMode_SwitchLedCodes_Variant2")):
        pat = re.compile(r"\t" + re.escape(old) + r"( +)")
        assert len(pat.findall(txt)) == 1, old
        txt = pat.sub(lambda mm: "\t%-52s " % ("ld %s,%s" % (old.split()[1].split(",")[0], lab)), txt)
    open(srcmap.SRC, "w", encoding="latin-1").write(txt)
    print("applied")


if __name__ == "__main__":
    main()
