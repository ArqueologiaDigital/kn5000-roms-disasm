#!/usr/bin/env python3
"""Name the seven sequencer screens' vtable methods and the entries of their 32-slot button tables.

QUESTION IT ANSWERS
  prom_b 0xF5553F's block header: "SEVEN tables of 32 32-bit routine pointers ... What the 32 selectors are ...
  is NOT KNOWN".  They are screens' BUTTON tables.  Each is reached only from a veneer
  `ld XIX,<table> / call T_PanelButton_CallTableEntry / ret`, and PanelButton_CallTableEntry's header says it
  calls "entry HL of a screen's 32-entry button-handler table (XIX)" with HL = the button code PanelButton_Route
  passes.  Each veneer is the +8 BUTTON slot of a thunk triple in PanelScreen_VtableTable_ViewB.  The triple's +0
  ENTER posts the painter that names the screen, and the block's own StageValues routines already carry those
  names:
      ViewB 0x06  T_ScreenEnter_RealtimeRecordScreen_Fwd  enter posts Draw_RealtimeRecordSong...        RealtimeRecordScreen
      ViewB 0x08  T_ScreenEnter_CycleRecordScreen_Fwd  Draw_CycleRecordCurrentMeasure                CycleRecordScreen
      ViewB 0x0C  T_ScreenEnter_MetronomeBalanceScreen_Fwd  Draw_MetronomeBalance (DL_MetronomeBalance)   MetronomeBalanceScreen
      ViewB 0x12  T_ScreenEnter_SeqPlayScreen_Fwd  Draw_SequencerPlayS0ngCycleMeasure            SeqPlayScreen
      ViewB 0x14  T_ScreenEnter_CyclePlayScreen_Fwd  Draw_CyclePlayCurrentMeasureCycle             CyclePlayScreen
      ViewB 0x26  T_F40DE0  Draw_CyclePlayCurrentMeasureEdit              CyclePlayEditScreen
      ViewB 0x29  T_ScreenEnter_CyclePlayEditScreen29_Fwd  enter = Fwd_F57410 -> the 0x26 enter routine;
                            leave the 0x26 leave routine; own button table CyclePlayEditScreen29
  Names: the table ButtonTable_<Screen> (prom_b's convention for the 32 other screens' tables); the veneer
  ScreenButton_<Screen>; the enter and leave routines ScreenEnter_ / ScreenLeave_<Screen> (their one-line
  forwarders Fwd_* get the same name + _Fwd).  An entry at slot k gets <Control>_<Screen> from the CONTROL
  map (notes/wave7_panel_names_round11.py: slots 0-7 SoftKeyCol1-8, 8-12 LcdKeyRow1-5, 0x0F ExitKey, 0x10 PageKey)
  when it is framed (sub_ / _FXXXXX) and sits in no other table.  The tables are ScreenButtons_<Screen>, not ButtonTable_<Screen>:
  notes/prom_b_panel_names_round12.py finds ITS 32 tables by scanning ButtonTable_* labels in file order (2026-10-04).  REFUSED: slots 0x11-0x18 (the variant-1
  already-held forms, refused the same way by round 11), a routine in two tables, a bare `ret` stub, and a
  name that is already taken.

RUN
  python3 notes/prom_b_sequencer_screen_buttons.py          # the plan and the refusals
  python3 notes/prom_b_sequencer_screen_buttons.py --args   # 'old=new|header' for the rename helper
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
CONTROL = {**{k: "SoftKeyCol%d" % (k + 1) for k in range(8)}, **{8 + k: "LcdKeyRow%d" % (k + 1) for k in range(5)},
           0x0F: "ExitKey", 0x10: "PageKey"}
# table base -> (screen, view-B id, thunk triple base)
SCREENS = {0xF558AE: ("RealtimeRecordScreen", 0x06, 0xF40DC0), 0xF5592E: ("MetronomeBalanceScreen", 0x0C, 0xF40E00),
           0xF559AE: ("CycleRecordScreen", 0x08, 0xF40DD0), 0xF55A2E: ("SeqPlayScreen", 0x12, 0xF40DA0),
           0xF55AAE: ("CyclePlayScreen", 0x14, 0xF40DB0), 0xF55B2E: ("CyclePlayEditScreen", 0x26, 0xF40DE0),
           0xF55BAE: ("CyclePlayEditScreen29", 0x29, 0xF40DF0)}
FRAMED = re.compile(r'^(sub_F[0-9A-F]{5}|\w+_F[0-9A-F]{5})$')


def thunk(addr):
    m = re.search(r'^(T_\w+):\s*jp\s+(\w+)\s*;\s*.*?$', "\n".join(l for l in B.split("\n") if l.startswith("T_F4%04X" % (addr & 0xFFFF)) or ("(was T_F4%04X)" % (addr & 0xFFFF)) in l), re.M)
    return m.group(2) if m else None


def table(base):
    # found by ADDRESS, so the plan re-runs after it was applied (the label is SelectorRoutines_F<addr> before,
    # ScreenButtons_<Screen> after)
    L = B.split("\n")
    i = next(k for k, l in enumerate(L) if re.match(r'^\s*\.long\s+\w+\s*;\s*F%05X\s+\[\s*0\]' % (base & 0xFFFFF), l)) - 1
    while not re.match(r'^[A-Za-z_][\w$]*:', L[i]):
        i -= 1
    lab = L[i].split(":")[0]
    out = []
    for l in L[i + 1:i + 40]:
        m = re.match(r'^\s*\.long\s+(\w+)', l)
        if m:
            out.append(m.group(1))
        if len(out) == 32:
            break
    return lab, out


def body_first(name):
    m = re.search(r'^%s:[^\n]*\n((?:\s*;[^\n]*\n)*)\s*([^\n;]+)' % re.escape(name), B, re.M)
    return m.group(2).strip() if m else ""


def plan():
    rows, refused = [], []
    tabs = {b: table(b) for b in SCREENS}
    where = collections.defaultdict(set)
    for b, (lab, ents) in tabs.items():
        for k, e in enumerate(ents):
            where[e].add(b)
    for b, (screen, vid, tri) in sorted(SCREENS.items()):
        lab, ents = tabs[b]
        rows.append((lab, "ScreenButtons_" + screen, "ScreenButtons_%s: the 32-slot button table of %s (view-B screen 0x%02X), indexed by panel\\n"
                     "  button code through T_PanelButton_CallTableEntry (notes/prom_b_sequencer_screen_buttons.py)." % (screen, screen, vid)))
        enter, leave, button = thunk(tri), thunk(tri + 4), thunk(tri + 8)
        if button and button.startswith("CallSelectorTable_"):
            rows.append((button, "ScreenButton_" + screen, "ScreenButton_%s: the +8 BUTTON method of screen 0x%02X -- ScreenButtons_%s entry HL." % (screen, vid, screen)))
        for kind, f in (("Enter", enter), ("Leave", leave)):
            if not f or not f.startswith("Fwd_"):
                continue
            tgt = re.match(r'calr\s+(\w+)', body_first(f))
            if screen == "CyclePlayEditScreen29":
                rows.append((f, "Screen%s_%s_Fwd" % (kind, screen), "Screen%s_%s_Fwd: the +%d %s slot of screen 0x29 -- forwards to %s, the routine screen 0x26\\n"
                             "  (CyclePlayEditScreen) uses too." % (kind, screen, 0 if kind == "Enter" else 4, kind.upper(), tgt.group(1) if tgt else "?")))
                continue
            rows.append((f, "Screen%s_%s_Fwd" % (kind, screen), ""))
            if tgt and re.match(r'^(sub_F[0-9A-F]{5}|Fwd_F[0-9A-F]{5})$', tgt.group(1)):
                rows.append((tgt.group(1), "Screen%s_%s" % (kind, screen), "Screen%s_%s: the +%d %s method of screen 0x%02X (thunk T_F%05X).%s" % (
                    kind, screen, 0 if kind == "Enter" else 4, kind.upper(), vid, (tri + (0 if kind == "Enter" else 4)) & 0xFFFFF,
                    "  Its painter names the screen." if kind == "Enter" else "")))
        for k, e in enumerate(ents):
            if k not in CONTROL:
                continue
            if not FRAMED.match(e) or e.startswith("Nop_Ret_"):
                continue
            if len(where[e]) > 1:
                refused.append((e, "in %d tables" % len(where[e])))
                continue
            if body_first(e) == "ret":
                refused.append((e, "a bare ret"))
                continue
            rows.append((e, "%s_%s" % (CONTROL[k], screen), "%s_%s: ScreenButtons_%s[%d] -- the %s handler of %s (notes/prom_b_sequencer_screen_buttons.py)." % (
                CONTROL[k], screen, screen, k, CONTROL[k], screen)))
    return rows, refused


def main():
    rows, refused = plan()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', A + B))
    names = [n for _o, n, _h in rows]
    for o, n, h in rows:
        bad = names.count(n) > 1 or n in taken
        if "--args" in sys.argv:
            if not bad:
                print("%s=%s|%s" % (o, n, h) if h else "%s=%s" % (o, n))
        else:
            print("%-32s -> %s%s" % (o, n, "  WITHHELD" if bad else ""))
    if "--args" not in sys.argv:
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("rename %d, refused %d" % (sum(1 for _o, n, _h in rows if not (names.count(n) > 1 or n in taken)), len(refused)))


if __name__ == "__main__":
    main()
