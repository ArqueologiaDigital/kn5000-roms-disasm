# Lane uiproc 2026-09-25: `<X>_JumpTable` labels in ui/drawbar_panel_ui.s and
# ui/ui_widget_defs.s are not tables: each is the first CASE of a computed jump
# (`lda xix,(<X>_JumpTable:24) / jp T,(XIX+reg)`), whose offsets live in Naka
# data, and also the base those offsets are relative to.  Named after the event
# that selects the case (index 0 of the table, read from the ROM by
# scripts/analysis/lane_uiproc_dispatch_tables.py).
s/\bComSetGridCheck_JumpTable\b/ComSetGridCheck_Evt1C00017/g
s/\bPmemOutLGridCheck_JumpTable\b/PmemOutLGridCheck_Evt1C00017/g
s/\bCtlMsgGridCheck_JumpTable\b/CtlMsgGridCheck_Evt1C00017/g
s/\bMidiPartGridCheck_JumpTable\b/MidiPartGridCheck_Evt1C00017/g
s/\bCommonIDProc_JumpTable\b/CommonIDProc_Evt1E0000D/g
