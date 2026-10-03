#!/usr/bin/env python3
"""Name the still-unnamed ENTER / LEAVE / BUTTON methods of the screen objects, from PanelScreen_VtableTable.

QUESTION IT ANSWERS
  PanelScreen_VtableTable (prom_a 0xF86EC1) is 256 LE32 pointers; each live one points at three
  consecutive `jp` slots of prom_b's thunk directory: +0 Enter, +4 Leave, +8 Button (the table's own
  header, checks V1-V6).  PanelButton_Route reads it through PanelScreen_VtableTable_ViewB, which is
  entry 32 used as a second base, so SCREEN ID n is MAIN ENTRY n + 32 -- the number the tree already
  spells ScreenCode<XX> (ScreenEnter_SoundEditPitchTune is main entry 0xA7's +0 target; ScreenButton_SoundEditDigitalEffect,
  main entry 0xBA's +8).  This names every remaining `sub_XXXXXX` method target of a main entry >= 32
  the way commit 2c92a241 (notes/prom_a_screen_methods_wave29.py) named the first 56:
      +0 Enter  -> ScreenCode<XX>_Handler      +4 Leave -> ScreenLeave_Code<XX>
      +8 Button -> ScreenButton_Code<XX>       (XX = main entry - 32, the screen id)
  REFUSED: a routine reached from two different (screen, slot) pairs -- one routine, several roles;
  entries below 32, which only view A reaches (indexed by (0x2078)/(0x2079), not by screen id).
  Targets in either image are named (the thunk's `jp` operand is the label).

RUN
  python3 notes/prom_ab_screen_vtable_methods.py          # the plan and the refusals
  python3 notes/prom_ab_screen_vtable_methods.py --args   # 'old=new|header' lines for the rename helper
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")
SLOT = [(0, "Enter", "ScreenCode%02X_Handler"), (4, "Leave", "ScreenLeave_Code%02X"), (8, "Button", "ScreenButton_Code%02X")]


def thunks():
    """{slot address: (thunk label, jp target)} of prom_b's directory."""
    return {int(m.group(1)[2:8], 16): (m.group(1), m.group(2))
            for m in re.finditer(r'^(T_F4[0-9A-F]{4}\w*):\s*jp\s+(\S+)', B, re.M)}


def vtable():
    """[(main entry index, pointer operand)] by POSITION from PanelScreen_VtableTable."""
    L = A.split("\n")
    i = L.index("PanelScreen_VtableTable:")
    out = []
    for l in L[i + 1:i + 400]:
        m = re.match(r'^\s*\.long\s+(\S+)\s*;\s*F8[67][0-9A-F]{3}', l)
        if m:
            out.append((len(out), m.group(1)))
        if len(out) == 256:
            break
    assert len(out) == 256
    return out


def plan():
    th = thunks()
    byname = {v[0]: k for k, v in th.items()}
    equ = {m.group(1): int(m.group(2), 16)
           for m in re.finditer(r'^\s*\.set\s+(T_F4\w+),\s*0x00(F4[0-9A-F]{4})', A, re.M)}
    uses = collections.defaultdict(list)          # target -> [(screen id, slot index, triple base)]
    for k, ptr in vtable():
        if k < 32:
            continue
        base = byname.get(ptr, equ.get(ptr))
        if base is None:
            continue
        for j, (off, _role, _fmt) in enumerate(SLOT):
            t = th.get(base + off)
            if t and re.match(r'^sub_F[0-9A-F]{5}$', t[1]):
                uses[t[1]].append((k - 32, j, base, t[0]))
    rows, refused = [], []
    for tgt, us in sorted(uses.items()):
        if len({(u[0], u[1]) for u in us}) != 1:
            refused.append((tgt, ", ".join("screen 0x%02X %s" % (u[0], SLOT[u[1]][1]) for u in us)))
            continue
        sid, j, base, tname = us[0]
        off, role, fmt = SLOT[j]
        new = fmt % sid
        rows.append((tgt, new, "%s: the +%d %s method of the screen object for screen id 0x%02X -- PanelScreen_VtableTable entry 0x%02X\\n"
                     "  (ViewB entry 0x%02X) points at the thunk triple 0x%06X, and slot %s jumps here." % (new, off, role.upper(), sid, sid + 32, sid, base, tname)))
    return rows, refused


def main():
    rows, refused = plan()
    names = collections.Counter(r[1] for r in rows)
    dup = {n for n, c in names.items() if c > 1}
    if "--args" in sys.argv:
        for old, new, hdr in rows:
            if new not in dup and new not in A and new not in B:
                print("%s=%s|%s" % (old, new, hdr))
        return
    for old, new, _ in rows:
        flag = "  DUPLICATE" if new in dup else ("  NAME TAKEN" if (new in A or new in B) else "")
        print("%-12s -> %s%s" % (old, new, flag))
    for t, why in refused:
        print("REFUSED %s: %s" % (t, why))
    print("rename %d, refused %d" % (len(rows), len(refused)))


if __name__ == "__main__":
    main()
