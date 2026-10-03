#!/usr/bin/env python3
"""Name NOTE EDIT's keyboard-ruler drawers: ScreenDispatch_FE8D6B's entries and their reader.

QUESTION IT ANSWERS
  0xFE8D3C, in NOTE EDIT (EditScreen_Mode bit 0 clear), selects LCD layer 2 and calls
  ScreenDispatch_FE8D6B[(0x601F53)]; in DRUM EDIT it only runs 0xFEAFB7, which sets
  (0x601F44) = (0x601F71) + (0x601F73) and draws nothing.  Entry k (k = 0..9; 10 and 11 repeat 9) runs
  one interpreter-A record whose bitmap is KeyboardRuler_Strip<k>.  (0x601F53) runs 0..9:
  NoteEdit_LcdKeyRow2 adds 1 below 9, NoteEdit_LcdKeyRow3 subtracts 1 above 0, and both then call
  0xFE8D3C -- so it is the ruler's scroll position and the LCD row 2 / 3 keys scroll it
  (notes/wsa1_601f_census.py lists every use).  Named: entry k KeyboardRuler_DrawStrip<k> (checked
  against the bitmap its list draws), the reader NoteEdit_DrawKeyboardRuler.

RUN
  python3 notes/prom_a_note_edit_keyboard_ruler.py          # the plan and the check
  python3 notes/prom_a_note_edit_keyboard_ruler.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1").split("\n")
IDX = {m.group(1): i for i, l in enumerate(A) for m in [re.match(r'^([A-Za-z_][\w$]*):', l)] if m}


def plan():
    rows, bad, seen = [], [], set()
    for l in A[IDX["ScreenDispatch_FE8D6B"] + 1:IDX["ScreenDispatch_FE8D6B"] + 14]:
        m = re.match(r'^\s*\.long\s+(\w+)\s*;\s*\w+\s+\[\s*(\d+)\]', l)
        if not m or m.group(1) in seen:
            continue
        t, k = m.group(1), int(m.group(2))
        seen.add(t)
        dl = [mm.group(1) for x in A[IDX[t] + 1:IDX[t] + 6] for mm in [re.search(r'ld XIY,(\w+)', x)] if mm][0]
        bm = [mm.group(1) for x in A[IDX[dl] + 1:IDX[dl] + 4] for mm in [re.search(r'\.long\s+(\w+)', x)] if mm][0]
        if bm != "KeyboardRuler_Strip%d" % k:
            bad.append("%s (entry %d) draws %s" % (t, k, bm))
            continue
        if t.startswith("sub_"):
            rows.append((t, "KeyboardRuler_DrawStrip%d" % k, "KeyboardRuler_DrawStrip%d: NOTE EDIT's keyboard ruler at scroll position %d --\\n"
                         "  ScreenDispatch_FE8D6B[%d]%s; draws %s (notes/prom_a_note_edit_keyboard_ruler.py)." % (
                             k, k, k, " (and [10], [11])" if k == 9 else "", bm)))
    if "sub_FE8D3C" in IDX:               # (applied 2026-10-04)
        rows.append(("sub_FE8D3C", "NoteEdit_DrawKeyboardRuler",
                     "NoteEdit_DrawKeyboardRuler: NOTE EDIT: layer 2, ScreenDispatch_FE8D6B[(0x601F53)], (0x601F53) being the ruler's\\n"
                     "  scroll position 0..9 that NoteEdit_LcdKeyRow2 / _LcdKeyRow3 step; DRUM EDIT: only 0xFEAFB7."))
    return rows, bad


def main():
    rows, bad = plan()
    for b in bad:
        print("CHECK FAILED", b)
    for o, n, h in rows:
        print(("%s=%s|%s" % (o, n, h)) if "--args" in sys.argv else "%-11s -> %s" % (o, n))
    if "--args" not in sys.argv:
        print("rename %d, failed checks %d" % (len(rows), len(bad)))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
