#!/usr/bin/env python3
"""Screen 0x0E is STEP RECORD: rename the Screen0E* labels and the screen's numbered methods.

QUESTION IT ANSWERS
  The tree called screen id 0x0E by number (Screen0ESub00_ButtonTable, SoftKeyCol1_Screen0ESub00,
  ScreenCode0E_Handler, ...) because notes/prom_b_screen0e_button_names.py named its button tables
  before anything said what the screen shows.  Its paint says it:
    * prom_a 0xF81ACB returns at once unless (UI_ScreenId) = 0x0E; otherwise it runs the header list
      DL_F3CF09 = "STEP RECORD:" / "TRACK:", or DL_F3CF32 = "MASTER STEP RECORD" when (0x0E63) = 2
      (0x0E63 is 1 for song tracks 0..31 and 2 for track 0x20, through Map_0E63_F6ACA7), and then the
      page list StepSelectAddrTable_F3D089 picks for UI_Screen0E_SubScreen.  Those 19 page lists are
      the step editor's fields and soft keys: "MEAS NOTE VEL LENGTH PHRS CURSOR", "MIX ERS CTL REST",
      "VALUE", "TIME SIG.", "TEMPO", "REP END", "TRACK CLR"; sub-screen 18 is DL_StepRecordTrackTrackClrMeas
      / DL_MasterTrackClearAttention ("MASTER TRACK CLEAR ... Are You Sure?").
    * its +8 BUTTON method (T_F43168 -> ScreenButton_Code0E) calls T_F42EC8 = prom_b 0xF675CC, which
      selects by (0x0E63) & 3 from DispatchTable_F675F3: kind 0 a no-op, kinds 1 and 2 0xF676B6, kind 3
      0xF6776F.  Those two index the 19-entry tables DispatchTable_F67723 / _F67789 by
      UI_Screen0E_SubScreen -- the tables whose entries round 12 named Screen0ESub<NN>_ButtonDispatch.
  (Names as they were before this script ran, 2026-10-04.)  So: Screen0E -> StepRecord in every label, UI_Screen0E_SubScreen -> UI_StepRecord_SubScreen (an
  equate, renamed by the sed this script writes with --sed), and the routines above by role.
  The sub-screen NUMBER stays in the names (StepRecordSub<NN>): what distinguishes pages that draw
  the same list (9 and 10; 12-15) is not established here.
  NOT renamed: screen 0x15's methods.  ScreenCode15_Handler / ScreenLeave_Code15 / ScreenButton_Code15
  have exactly 0x0E's bodies, but no immediate anywhere requests screen 0x15 and the paint returns
  unless the screen is 0x0E, so nothing says what 0x15 shows.  The shared bodies' headers say so.

RUN
  python3 notes/prom_ab_step_record_screen_names.py          # the plan
  python3 notes/prom_ab_step_record_screen_names.py --args   # 'old=new|header' for the rename helper
  python3 notes/prom_ab_step_record_screen_names.py --sed    # the equate rename, as sed rules
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = [os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")]
EQUATES = [("UI_Screen0E_SubScreen", "UI_StepRecord_SubScreen")]
SHARED15 = "  Screen 0x15's method has the same body; nothing requests screen 0x15 (prom_ab_step_record_screen_names.py)."
EXPLICIT = [
    ("ScreenCode0E_Handler", "ScreenEnter_StepRecord", ""),
    ("ScreenLeave_Code0E", "ScreenLeave_StepRecord", ""),
    ("ScreenButton_Code0E", "ScreenButton_StepRecord", ""),
    ("sub_F8101E", "ScreenEnterBody_StepRecord",
     "ScreenEnterBody_StepRecord: the body of STEP RECORD's +0 ENTER method -- restarts callback task 2,\\n"
     "  and runs prom_b 0xF6A9CA (T_F42EC0) between LCD_ScreenRedraw_Begin / _End.\\n" + SHARED15),
    ("sub_F81039", "ScreenLeaveBody_StepRecord",
     "ScreenLeaveBody_StepRecord: the body of STEP RECORD's +4 LEAVE method -- runs prom_b 0xF6AE4B (T_F42EC4).\\n" + SHARED15),
    ("sub_F6A9CA", "StepRecord_OnEnter",
     "StepRecord_OnEnter: the prom_b part of STEP RECORD's ENTER -- reached only from ScreenEnterBody_StepRecord, through T_F42EC0."),
    ("sub_F6AE4B", "StepRecord_OnLeave",
     "StepRecord_OnLeave: the prom_b part of STEP RECORD's LEAVE -- reached only from ScreenLeaveBody_StepRecord, through T_F42EC4."),
    ("sub_F81ACB", "Paint_StepRecord",
     "Paint_StepRecord: returns unless (UI_ScreenId) = 0x0E; draws \"STEP RECORD:\" / \"TRACK:\" (or\\n"
     "  \"MASTER STEP RECORD\" when (0x0E63) = 2) and the page list StepSelectAddrTable_F3D089 gives for\\n"
     "  UI_StepRecord_SubScreen (sub-screen 18: the MASTER TRACK CLEAR / TRACK CLR confirmation)."),
    ("sub_F675CC", "StepRecord_ButtonByTrackKind",
     "StepRecord_ButtonByTrackKind: STEP RECORD's button handling (T_F42EC8, called by the +8 method with the\\n"
     "  panel code in BC, saved at (0x0D10)); selects by (0x0E63) & 3 from StepRecord_TrackKindButtonTable --\\n"
     "  (0x0E63) is 1 for a song track and 2 for the master track (Map_0E63_F6ACA7).\\n" + SHARED15),
    ("DispatchTable_F675F3", "StepRecord_TrackKindButtonTable", ""),
    ("DispatchTable_F675F3_Nop0", "StepRecord_TrackKindButtonTable_Nop0", ""),
    ("sub_F676B6", "StepRecord_ButtonBySubScreen",
     "StepRecord_ButtonBySubScreen: track kinds 1 and 2 -- calls StepRecord_SubScreenButtonTable[UI_StepRecord_SubScreen]."),
    ("DispatchTable_F67723", "StepRecord_SubScreenButtonTable", ""),
    ("sub_F6776F", "StepRecord_ButtonBySubScreen_Kind3",
     "StepRecord_ButtonBySubScreen_Kind3: track kind 3 -- StepRecord_SubScreenButtonTable_Kind3[UI_StepRecord_SubScreen].\\n"
     "  The one writer of (0x0E63), prom_b 0xF6ACA2, stores 1 or 2 (Map_0E63_F6ACA7), so kind 3 is not seen set."),
    ("DispatchTable_F67789", "StepRecord_SubScreenButtonTable_Kind3", ""),
]


def plan():
    text = "\n".join(open(p, "rb").read().decode("latin-1") for p in FILES)
    labels = set(re.findall(r'^([A-Za-z_][\w$]*):', text, re.M))
    rows = [(o, n, h) for o, n, h in EXPLICIT if o in labels]
    for lab in sorted(labels):
        if "Screen0E" in lab:
            rows.append((lab, lab.replace("Screen0E", "StepRecord"), ""))
    return rows


def main():
    if "--sed" in sys.argv:
        for o, n in EQUATES:
            print("s/\\b%s\\b/%s/g" % (o, n))
        return
    rows = plan()
    names = [n for _o, n, _h in rows]
    dup = {n for n in names if names.count(n) > 1}
    for o, n, h in rows:
        if "--args" in sys.argv:
            if n not in dup:
                print("%s=%s%s" % (o, n, ("|" + h) if h else ""))
        else:
            print("%-36s -> %s%s" % (o, n, "  DUPLICATE" if n in dup else ""))
    if "--args" not in sys.argv:
        print("renames %d, duplicates %d (and %d equate)" % (len(rows), len(dup), len(EQUATES)))


if __name__ == "__main__":
    main()
