#!/usr/bin/env python3
"""Name the NOTE EDIT / DRUM EDIT / EDIT PART SELECT screens' panel-button tables and handlers (prom_a 0xFE8000).

QUESTION IT ANSWERS
  Three prom_a 32-entry tables are read by a screen object's +8 BUTTON method with the shape
  `cp HL,0x001F / jr gt / ld XIX,<table> / sll hl,2 / add XIX,XHL / ld XIX,(XIX) / call (xix)`.
  PanelButton_Route (0xF86205-0xF8622C) enters that method with the panel event code in HL (it
  also pushes it), so the slot is the panel code -- the same index round 11 proved for prom_b's
  32-entry tables:
      NoteEdit_ButtonTable  read by ScreenButton_NoteEdit, screen 0x25, whose Enter is
                             EditScreen_EnterNoteEdit (clears EditScreen_Mode bit 0: NOTE EDIT,
                             FINDINGS-prom_a-screen-module.md section 8)            -> NoteEdit
      DrumEdit_ButtonTable  read by ScreenButton_DrumEdit, screen 0x28, Enter EditScreen_EnterDrumEdit -> DrumEdit
      EditPartSelect_ButtonTable  read by ScreenButton_EditPartSelect, the +8 slot of BOTH thunk triples that start
                             T_ShowScreen_NoteEditPartSelect and T_ShowScreen_DrumEditPartSelect
                                                                              -> EditPartSelect
  Slot -> control is round 11's (wave7_panel_names_round11.CONTROL), with its rules: slots
  0x11-0x18 fold onto their base; 0x0D, 0x0E, 0x19 refused; a routine whose slots fold to two
  controls refused; a routine found ONLY at already-held slots is <Screen>_Button<slot>, NOT
  NAMED, as prom_b's MeasureDelete_StageZero_Button21.  A routine that NOTE EDIT and DRUM EDIT
  share under one control is <Control>_EditScreen.  Also proposed: the readers ScreenButton_NoteEdit / _DrumEdit /
  _EditPartSelect, the leaves ScreenLeave_NoteEdit / _DrumEdit (screens 0x25 / 0x28), and the
  tables <Screen>_ButtonTable.

RUN
  python3 notes/prom_a_edit_screen_button_names.py          # the plan and the refusals
  python3 notes/prom_a_edit_screen_button_names.py --args   # 'old=new|header' for the rename helper
"""
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import wave7_panel_names_round11 as R11  # noqa: E402

A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
SPELL = {"Exit": "ExitKey", "NumberPad": "NumberPadKey", "Page": "PageKey"}
TABLES = [("NoteEdit_ButtonTable", "NoteEdit"), ("DrumEdit_ButtonTable", "DrumEdit"),
          ("EditPartSelect_ButtonTable", "EditPartSelect")]
FIXED = [("NoteEdit_ButtonTable", "NoteEdit_ButtonTable"), ("DrumEdit_ButtonTable", "DrumEdit_ButtonTable"),
         ("EditPartSelect_ButtonTable", "EditPartSelect_ButtonTable"),
         ("ScreenButton_NoteEdit", "ScreenButton_NoteEdit"), ("ScreenButton_DrumEdit", "ScreenButton_DrumEdit"),
         ("ScreenLeave_NoteEdit", "ScreenLeave_NoteEdit"), ("ScreenLeave_DrumEdit", "ScreenLeave_DrumEdit"),
         ("ScreenButton_EditPartSelect", "ScreenButton_EditPartSelect")]


def entries(tab):
    L = A.split("\n")
    i = L.index(tab + ":")
    out = []
    for l in L[i + 1:i + 40]:
        m = re.match(r'^\s*\.long\s+(\S+)\s*;\s*[0-9A-F]{6}\s+\[\s*(\d+)\]', l)
        if not m:
            break
        out.append((int(m.group(2)), m.group(1)))
    assert len(out) == 32, (tab, len(out))
    return out


def control_of(slot):
    base = slot - 0x11 if 0x11 <= slot <= 0x18 else slot
    if base in R11.REFUSE_SLOT or base not in R11.CONTROL:
        return None
    ctl, gloss = R11.CONTROL[base]
    return SPELL.get(ctl, ctl), gloss


def plan():
    uses = collections.OrderedDict()
    for tab, scr in TABLES:
        for slot, tgt in entries(tab):
            if re.match(r'^sub_F[89A-F][0-9A-F]{4}$', tgt):
                uses.setdefault(tgt, []).append((scr, slot))
    rows, refused = [], []
    for tgt, us in uses.items():
        ctls = {control_of(s) for _scr, s in us}
        scrs = sorted({u[0] for u in us})
        where = "; ".join("%s_ButtonTable slot 0x%02X" % u for u in us)
        if None in ctls or len(ctls) != 1:
            refused.append((tgt, where + ": no single control"))
            continue
        if scrs == ["DrumEdit", "NoteEdit"]:
            scr = "EditScreen"
        elif len(scrs) == 1:
            scr = scrs[0]
        else:
            refused.append((tgt, where + ": screens " + ", ".join(scrs)))
            continue
        (ctl, gloss), = ctls
        if all(0x11 <= s <= 0x18 for _scr, s in us):
            # only the variant-1 already-held slot: round 11 / prom_b's precedent (MeasureDelete_StageZero_Button21)
            s0 = min(s for _scr, s in us)
            name = "%s_Button%d" % (scr, s0)
            rows.append((tgt, name, "%s -- %s, NOT NAMED: slot 0x%02X is only the VARIANT-1 already-held rewrite of base code 0x%02X\\n"
                         "  (%s); the SX-WSA1R is variant 2, so the slot is never delivered here (wave7_panel_names_round11)."
                         % (name, where, s0, s0 - 0x11, ctl)))
            continue
        name = "%s_%s" % (ctl, scr)
        rows.append((tgt, name, "%s: %s; %s.  Slot -> control: wave7_panel_names_round11.CONTROL." % (name, gloss, where)))
    return rows, refused


def main():
    rows, refused = plan()
    fixed = [(o, n, "") for o, n in FIXED if o != n and re.search(r'^%s:' % o, A, re.M)]
    allr = fixed + rows
    cnt = collections.Counter(r[1] for r in allr)
    dup = {n for n, c in cnt.items() if c > 1}
    if "--args" in sys.argv:
        for o, n, h in allr:
            if n not in dup:
                print("%s=%s%s" % (o, n, ("|" + h) if h else ""))
        return
    for o, n, _h in allr:
        print("%-24s -> %s%s" % (o, n, "  DUPLICATE" if n in dup else ""))
    for t, why in refused:
        print("REFUSED %s: %s" % (t, why))
    print("rename %d (duplicates withheld %d), refused %d" % (len([r for r in allr if r[1] not in dup]),
                                                             len([r for r in allr if r[1] in dup]), len(refused)))


if __name__ == "__main__":
    main()
