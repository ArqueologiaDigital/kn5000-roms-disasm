#!/usr/bin/env python3
"""Name the SYSTEM menu's still-numbered screens 0x6A, 0x65 and 0x64 from the menu's own text.

QUESTION IT ANSWERS
  Screen_System_Button's header lists the screen each LCD-row key opens, left / right
  (PanelEvent_Flags bit 0 set = left): 0x62 TUNE & SCALE / 0x6A, 0x65 / 0x6C RE-MAP EDIT,
  0x64 / 0x6D SOUND/COMBI MANAGER, 0xB7 / 0x67 DRUMS MAP, 0x66 DSP EFFECT / 0x6B MAIN OUT EQUALIZER.
  Three left/right slots had no name.  The menu's display list DL_TestSystemTuneScaleInitial (interpreter A,
  run by the SYSTEM screen's paint callback 0xFA0020) holds the item text as records
  `20 len lo hi text` -- the 16-bit VRAM offset lo|hi at 40 bytes a row (`06` the same, one other font).
  Decoded from the ROM below, rows and columns:
      row 36  col 5 TUNE & SCALE       col 24 INITIAL
      row 68  col 5 C0NTR0LLER (82: ASSIGN)    row 75 col 24 RE-MAP EDIT
      row 115 col 5 TEST  / rows 107-121 col 5 0VERALL T0UCH SENSITIVITY (DL_0verallT0uchSensitivity)
                                       col 24 S0UND/C0MBI MANAGER
      row 153 col 5 MIXER              col 24 DRUMS MAP
      row 192 col 5 DSP EFFECT         rows 185-199 col 24 MAIN OUT EQUALIZER
  so 0x6A = INITIAL, 0x65 = CONTROLLER ASSIGN, and 0x64 = the third-row left item, which depends on the
  model: 0xFA0020 runs 0xFA1F2E-0xFA2070 (no TEST, with FA204B's OVERALL TOUCH SENSITIVITY) when
  Variant_Flag = 1, and 0xFA1F21-0xFA204B (TEST, no touch sensitivity) otherwise; Screen_TouchSensitivityOrTest_Enter
  branches on the same Variant_Flag = 1.  Variant 2 is the SX-WSA1R (wave7_panel_names_round11 --variant).
  Named in the existing Screen_<Name>_Enter / _Leave / _Button spelling.

RUN
  python3 notes/prom_a_system_menu_screens.py          # the decoded menu and the plan
  python3 notes/prom_a_system_menu_screens.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
BASE = 0xF80000
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
SCREENS = {0x6A: ("Initial", "INITIAL"), 0x65: ("ControllerAssign", "C0NTR0LLER ASSIGN"),
           0x64: ("TouchSensitivityOrTest", "0VERALL T0UCH SENSITIVITY (variant 1, SX-WSA1) / TEST (variant 2, SX-WSA1R)")}


def menu(lo, hi):
    out, a = [], lo
    while a < hi:
        op, ln = ROM[a - BASE], ROM[a - BASE + 1]
        if ln == 0:
            break
        p = ROM[a - BASE + 2:a - BASE + ln]
        if op in (0x20, 0x06) and len(p) > 2:
            pos = p[0] | (p[1] << 8)
            out.append((pos // 40, pos % 40, p[2:].decode("latin-1")))
        a += ln
    return out


def plan():
    items = menu(0xFA1F21, 0xFA204B) + menu(0xFA204B, 0xFA2070)
    have = {t for _r, _c, t in items}
    for need in ("INITIAL", "C0NTR0LLER", "ASSIGN", "TEST", "0VERALL T0UCH", "SENSITIVITY"):
        assert need in have, need
    rows = []
    for sid, (nm, text) in SCREENS.items():
        for old, meth in (("ScreenCode%02X_Handler" % sid, "Enter"), ("ScreenLeave_Code%02X" % sid, "Leave"),
                          ("ScreenButton_Code%02X" % sid, "Button")):
            if re.search(r'^%s:' % old, A, re.M):
                new = "Screen_%s_%s" % (nm, meth)
                rows.append((old, new, "%s: the %s method of screen 0x%02X, the SYSTEM menu item %s\\n"
                             "  (notes/prom_a_system_menu_screens.py decodes the menu text and pairs it with Screen_System_Button)." % (
                                 new, meth.upper(), sid, text)))
    return items, rows


def main():
    items, rows = plan()
    if "--args" in sys.argv:
        for o, n, h in rows:
            print("%s=%s|%s" % (o, n, h))
        return
    for r, c, t in sorted(items):
        print("row %3d col %2d  %s" % (r, c, t))
    for o, n, _h in rows:
        print("%-22s -> %s" % (o, n))
    print("rename %d" % len(rows))


if __name__ == "__main__":
    main()
