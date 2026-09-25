#!/usr/bin/env python3
r"""Ten UI tables whose headers left "the selector" open are indexed by the BUTTON CODE.

QUESTION THIS ANSWERS
    DisplayListPtrs_F92C66 ("Unknown: what the 32 slots select between"),
    JumpTable_F99F96 ("Unknown: the selector") and eight tables whose headers say
    "Evidence / Unknown: as" one of those two.  For each, the routine that reads
    it is the +8 BUTTON method of a screen object in PanelScreen_VtableTable,
    and PanelButton_Route (0xF8621E-0xF8622C) calls that method as
    `add XBC,8 / ld A,W / push WA / push HL / call (XBC)` -- the button code in
    HL and on the stack at (XIZ+8).  The readers index with exactly that:
      * jump-table readers: `ld L,(XIZ+0x08)` ... `ld C,L / cp BC,0x1F /
        sll 2,BC / add XBC,<table> / ld XBC,(XBC) / jp (XBC)`;
      * the others: `ld XIX,<table> / call T_F41B08`, and T_F41B08 is
        `jp 0xF8BDC5`, which does `cp HL,0x1F` and calls (XIX + 4*L).
    So the selector is the panel button code; Dispatch_FF3D39's CONTROL LEGEND
    says which physical button each code is.

CHECKS (against wsa1/original_ROMs)
    B1  every reader routine R is `jp R` at vtable[k] + 8 for some entry k of
        PanelScreen_VtableTable (0xF86EC1, 256 LE32)
    B2  PanelButton_Route's call: `add XBC,8 / ld A,W / push WA / push HL /
        call (XBC)` at 0xF8621E-0xF8622C
    B3  the per-reader index shape above; T_F41B08 = `jp 0xF8BDC5`, and
        0xF8BDC5 starts `cp HL,0x001F` and ends `ld XIX,(XIX+L) / call (XIX)`

RUN
    python3 notes/proma-2026-09-25/gen_button_selectors.py          # checks
    python3 notes/proma-2026-09-25/gen_button_selectors.py --apply  # ran once
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
# table -> (reader routine address, kind, new name or None)
TABLES = {
    "DisplayListPtrs_F90CD8": (0xF90CCA, "b08", None),
    "DisplayListPtrs_F92C66": (0xF92C58, "b08", "ScreenButtonHandlers_GroupSoundDisplayHold"),
    "DisplayListPtrs_F93557": (0xF93549, "b08", "ScreenButtonHandlers_CombinationGroupMenu"),
    "DisplayListPtrs_F93839": (0xF9382B, "b08", "ScreenButtonHandlers_GroupCombiDisplayHold"),
    "DisplayListPtrs_F9408E": (0xF94080, "b08", None),
    "JumpTable_F99F96": (0xF99F5E, "jt", None),
    "JumpTable_F9A2A7": (0xF9A26F, "jt", "ScreenButtonHandlers_MidiTotalMode"),
    "JumpTable_F9A78E": (0xF9A756, "jt", "ScreenButtonHandlers_MidiRealtimeMessages"),
    "JumpTable_F9AA89": (0xF9AA51, "jt", "ScreenButtonHandlers_MidiInputOutputFilter"),
    "JumpTable_F9B098": (0xF9B060, "jt", "ScreenButtonHandlers_MidiOutProgramChange"),
}


def checks(m):
    r = m.rom
    rb = open(os.path.join(srcmap.WSA1, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    vt = [int.from_bytes(r[0xF86EC1 - B + 4 * k:0xF86EC1 - B + 4 * k + 4], "little") for k in range(256)]
    slot = {}
    for k, p in enumerate(vt):
        s = p + 8
        if 0xF00000 <= s < 0xF80000 and rb[s - 0xF00000] == 0x1B:
            slot.setdefault(int.from_bytes(rb[s - 0xF00000 + 1:s - 0xF00000 + 4], "little"), (k, s))
    info = {}
    for t, (R, kind, _) in TABLES.items():
        assert R in slot, (t, hex(R))
        info[t] = slot[R]
    print("B1 ok: all ten readers are +8 BUTTON methods of PanelScreen_VtableTable objects")
    assert r[0xF8621E - B:0xF8622E - B] == bytes.fromhex("e9c808000000f1b42061c889282bb1e8")
    print("B2 ok: PanelButton_Route calls +8 with the code in HL and pushed")
    assert rb[0xF41B08 - 0xF00000:0xF41B0C - 0xF00000] == bytes.fromhex("1bc5bdf8")
    assert r[0xF8BDC5 - B:0xF8BDC9 - B] == bytes.fromhex("dbcf1f00")
    assert r[0xF8BDF0 - B:0xF8BDF7 - B] == bytes.fromhex("e303f0ec24b4e8")
    for t, (R, kind, nn) in TABLES.items():
        a = [x for x, ns in m.by_addr.items() if t in ns or nn in ns][0]   # before / after --apply
        body = r[R - B:R - B + 0x40]
        if kind == "b08":
            assert body[:9] == b"\x44" + a.to_bytes(4, "little") + bytes.fromhex("1d081bf4"), t
        else:
            assert bytes.fromhex("8e0827") in body, t                           # ld L,(XIZ+8)
            assert (bytes.fromhex("cf8bd912e912d9cf1f00") in body), t           # ld C,L .. cp BC,0x1F
            assert (b"\xe9\xc8" + a.to_bytes(4, "little") + bytes.fromhex("a121b1d8")) in body, t
    print("B3 ok: each reader indexes by the stacked/HL button code")
    return info


def apply(m, info):
    L = m.lines
    u8 = lambda s: s.encode("utf-8").decode("latin-1")  # noqa: E731
    for t, (R, kind, new) in TABLES.items():
        k, s = info[t]
        Rname = [n for n in m.labels_at(R) if not n.startswith(".")][0]
        i = L.index(t + ":")
        j = i - 1
        while not L[j].strip():
            j -= 1
        while L[j].startswith(";") and not re.match(r"^; (Unknown:  |Evidence / Unknown: as )", L[j]):
            j -= 1
        assert re.match(r"^; (Unknown:  |Evidence / Unknown: as )", L[j]), t
        old = L[j]
        how = (["`ld XIX,<this> / call T_F41B08`, and T_F41B08 = 0xF8BDC5 calls",
                "(this + 4*L) after `cp HL,0x001F`."] if kind == "b08" else
               ["`ld L,(XIZ+0x08)` ... `ld C,L / cp BC,0x001F / sll 2,BC /",
                "add XBC,<this> / ld XBC,(XBC) / jp (XBC)`."])
        rest = ""
        if old.startswith("; Unknown:  the selector.  "):
            rest = old[len("; Unknown:  the selector.  "):]
        elif old.startswith("; Evidence / Unknown: as "):
            m2 = re.match(r"^; Evidence / Unknown: as (\w+)\.\s*(.*)$", old)
            rest = ("Evidence: as %s.  %s" % (m2.group(1), m2.group(2))).strip()
        new_lines = [
            "; Selector: the panel BUTTON CODE.  %s (0x%06X) is the +8" % (Rname, R),
            ";          BUTTON method of PanelScreen_VtableTable entry 0x%02X (prom_b" % k,
            ";          slot 0x%06X); PanelButton_Route calls it with the code in HL" % s,
            ";          and at (XIZ+8), and it indexes this table with it:",
        ] + [";          " + h for h in how] + [
            ";          Dispatch_FF3D39's CONTROL LEGEND names each code.",
            ";          (notes/proma-2026-09-25/gen_button_selectors.py, B1-B3)",
            u8("; ★ 2026-09-25 (lane proma): the selector was recorded as open here."),
        ]
        if rest:
            new_lines.append("; " + rest)          # already latin-1 text (from the file)
        L[j:j + 1] = new_lines
    txt = "\n".join(L)
    for t, (R, kind, new) in TABLES.items():
        if new:
            txt, n = re.subn(r"(?<![\w.$])%s(?![\w$])" % t, new, txt)
            assert n >= 2, (t, n)
    open(srcmap.SRC, "wb").write(txt.encode("latin-1"))
    print("applied")


if __name__ == "__main__":
    M = srcmap.load()
    I = checks(M)
    if "--apply" in sys.argv:
        apply(M, I)
