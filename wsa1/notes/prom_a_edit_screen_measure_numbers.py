#!/usr/bin/env python3
"""Name the NOTE / DRUM EDIT measure-number drawers behind ScreenDrawPtrs_FEF9FA / _FEFA2A.

QUESTION IT ANSWERS
  FINDINGS-prom_a-screen-module.md section 8: EditScreen_Mode bit 0 picks ScreenDrawPtrs_FEF9FA (NOTE EDIT)
  or _FEFA2A (DRUM EDIT), "the note-edit and drum-edit layouts of one editor".  Their one reader,
  0xFEF9A6, walks E = 0 .. (0x601F75) over the byte table at 0x601F5F (the per-measure beat counts
  EditCursor_BeatsInMeasure reads) with BC starting at (0x601F5D); for each non-zero entry it stores BC
  in (0x26B0), calls table[E], and steps BC by one.  Every routine the two tables hold has one shape
  (checked below): if (0x26B0) > 999 it is cleared and one display list runs, otherwise another, through
  interpreter B -- it draws the number in (0x26B0) at its own fixed place.  So 0xFEF9A6 draws the
  measure numbers of the measures the editor shows, and each table routine is one PLACE on the screen.
  The two layouts share places (DRUM slot 1 is NOTE slot 4, ...), so a place is named by its rank in
  address order, not by a layout's slot: EditScreen_MeasureNumberAt<k>, k = 0..11, and the reader
  EditScreen_DrawMeasureNumbers.  What (0x601F75) counts and why NOTE EDIT's entry 11 repeats entry 0
  are not established here.

RUN
  python3 notes/prom_a_edit_screen_measure_numbers.py          # the plan and the shape check
  python3 notes/prom_a_edit_screen_measure_numbers.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
L = A.split("\n")
IDX = {m.group(1): i for i, l in enumerate(L) for m in [re.match(r'^([A-Za-z_][\w$]*):', l)] if m}
SHAPE = [r'm_cp_mi16 MW16, 0x26b0, 0x03e7', r'jr ule, \.L\w+', r'ldw \(0x26b0:16\), 0x00', r'ld XIY,\w+', r'ld XIX,\w+',
         r'call T_DisplayListB_Run', r'ret', r'ld XIY,\w+', r'ld XIX,\w+', r'call T_DisplayListB_Run', r'ret']


def entries(tab):
    out = []
    for l in L[IDX[tab] + 1:IDX[tab] + 20]:
        m = re.match(r'^\s*\.long\s+(\w+)\s*;\s*[0-9A-F]{6}\s+\[\s*(\d+)\]', l)
        if not m:
            break
        out.append((int(m.group(2)), m.group(1)))
    return out


def body(lab):
    out = []
    for l in L[IDX[lab] + 1:IDX[lab] + 20]:
        m = re.match(r'^([A-Za-z_][\w$]*):', l)
        if m:
            break
        c = re.sub(r'\s+', ' ', l.split(";")[0]).strip()
        if c and not c.startswith(".L"):
            out.append(c)
    return out


def addr(lab):
    for l in L[IDX[lab]:IDX[lab] + 4]:
        m = re.search(r';\s*(F[0-9A-F]{5})\b', l)
        if m and not l.startswith(";"):
            return int(m.group(1), 16)


def plan():
    note, drum = entries("ScreenDrawPtrs_FEF9FA"), entries("ScreenDrawPtrs_FEFA2A")
    assert len(note) == 12 and len(drum) == 9, (len(note), len(drum))
    targets = sorted({t for _k, t in note + drum}, key=addr)
    bad = [t for t in targets if len(body(t)) != len(SHAPE) or not all(re.fullmatch(p, b) for p, b in zip(SHAPE, body(t)))]
    rows = []
    for k, t in enumerate(targets):
        if not t.startswith("sub_"):
            continue
        new = "EditScreen_MeasureNumberAt%d" % k
        where = ", ".join(["NOTE EDIT slot %d" % s for s, x in note if x == t] + ["DRUM EDIT slot %d" % s for s, x in drum if x == t])
        rows.append((t, new, "%s: draws the measure number in (0x26B0) -- cleared if above 999 -- at one fixed place of the\\n"
                     "  edit screen; place %d of 12 in address order; %s (notes/prom_a_edit_screen_measure_numbers.py)." % (new, k, where)))
    if "sub_FEF9A6" in IDX:               # (applied 2026-10-04: now EditScreen_DrawMeasureNumbers)
        rows.append(("sub_FEF9A6", "EditScreen_DrawMeasureNumbers",
                     "EditScreen_DrawMeasureNumbers: for E = 0..(0x601F75) and each non-zero beat count at 0x601F5F[E], draws\\n"
                     "  measure number BC (from (0x601F5D), +1 each) through ScreenDrawPtrs_FEF9FA[E] (NOTE EDIT) or _FEFA2A[E]\\n"
                     "  (DRUM EDIT, EditScreen_Mode bit 0)."))
    return rows, bad


def main():
    rows, bad = plan()
    if bad:
        print("SHAPE CHECK FAILED:", ", ".join(bad))
        sys.exit(1)
    for o, n, h in rows:
        print(("%s=%s|%s" % (o, n, h)) if "--args" in sys.argv else "%-11s -> %s" % (o, n))
    if "--args" not in sys.argv:
        print("rename %d; shape check passed on all 12 places" % len(rows))


if __name__ == "__main__":
    main()
