
; Direct Play, Medley, Step Record, Track Assign & Demo screen widgets (216 widgets, 12250 bytes)
; Source: maincpu/ui_widgets/naka_direct_play.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_direct_play
; How these pieces were identified
; (scripts/analysis/nakarest_objtab_map.py): every RegObjTabl
; registration in the v10, v9 and v7 sources (the macro, and v7's
; written-out form) was parsed, each registered table was read out of
; the original ROM dump, and every address those tables point at is an
; object START: a Viewable table points at NAKA widget records, a
; ResName table (slot = Viewable slot + 0x300) at the name string of
; each element, an ApFunction / Function / MainFunction table (slot
; 0x1xx) at procedures and its slot + 0x300 twin at their names. Each
; piece below starts at one such run of objects or at a label that
; already existed. A widget record starts TT 00 6x 01 (TT = type byte);
; +4 parent, +6 first child, +8 next sibling, +10 previous sibling are
; element indices of the same table (0xffff = none), checked against
; each other for every table (the Links result per table). Name strings
; are NUL-terminated and 0xff-padded to even length. The first word of a
; widget record is its CLASS ID 0x016S_KKKK: ClassProc
; (ui/ui_widget_defs.s) takes (id >> 16) & 0xfff as a registry slot --
; the Class table that RegObjTable 0x1600004 put there -- and 0x18 * (id
; & 0xffff) into it. Each class definition gives the instance size (+8
; allsize), and all 3,340 in-ROM widget records of v10 resolve to a
; class and are at least that far apart (THE CLASS SYSTEM,
; scripts/analysis/nakarest_objtab_map.py).
;
; Tables with objects in this file:
;
; Viewable slot 0x6f: RegObjTabl 0x1600010, ViewableProc, 0x2b,
; 0xe240ac, 0x6f in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 43, table} at 0x27ed2 +
; 14*0x6f. Element 0 is named "DpSmf" in ResName slot 0x36f. Links: all
; 43 records consistent.
;
; Viewable slot 0x70: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe2415c,
; 0x70 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x70. Element 0 is named "DpDoc" in ResName slot 0x370. Links: all
; 12 records consistent.
;
; Viewable slot 0x71: RegObjTabl 0x1600010, ViewableProc, 0xb, 0xe24190,
; 0x71 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 11, table} at 0x27ed2 +
; 14*0x71. Element 0 is named "DpPd" in ResName slot 0x371. Links: all
; 11 records consistent.
;
; Viewable slot 0x72: RegObjTabl 0x1600010, ViewableProc, 0x7, 0xe241c0,
; 0x72 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0x72. Element 0 is named "DpSmfLyr" in ResName slot 0x372. Links:
; all 7 records consistent.
;
; Viewable slot 0x73: RegObjTabl 0x1600010, ViewableProc, 0x10,
; 0xe241e0, 0x73 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0x73. Element 0 is named "DpMdlySmf" in ResName slot 0x373. Links:
; all 16 records consistent.
;
; Viewable slot 0x74: RegObjTabl 0x1600010, ViewableProc, 0xf, 0xe24224,
; 0x74 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 15, table} at 0x27ed2 +
; 14*0x74. Element 0 is named "" in ResName slot 0x374. Links: all 15
; records consistent.
;
; Viewable slot 0x75: RegObjTabl 0x1600010, ViewableProc, 0xd, 0xe24264,
; 0x75 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 13, table} at 0x27ed2 +
; 14*0x75. Element 0 is named "DpMdlyPd" in ResName slot 0x375. Links:
; all 13 records consistent.
;
; Viewable slot 0x76: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe2429c,
; 0x76 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x76. Element 0 is named "DpMdlySmfLyr" in ResName slot 0x376.
; Links: all 8 records consistent.
;
; Viewable slot 0x78: RegObjTabl 0x1600010, ViewableProc, 0x1e,
; 0xe242c0, 0x78 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 30, table} at 0x27ed2 +
; 14*0x78. Element 0 is named "DkMdlyPly" in ResName slot 0x378. Links:
; all 30 records consistent.
;
; Viewable slot 0x7a: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe2433c,
; 0x7a in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x7a. Element 0 is named "SqMdlyPly" in ResName slot 0x37a. Links:
; all 12 records consistent.
;
; Viewable slot 0x89: RegObjTabl 0x1600010, ViewableProc, 0x5, 0xe24370,
; 0x89 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 5, table} at 0x27ed2 +
; 14*0x89. Element 0 is named "SqTrSel" in ResName slot 0x389. Links:
; all 5 records consistent.
;
; Viewable slot 0x8a: RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe24388,
; 0x8a in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 1, table} at 0x27ed2 +
; 14*0x8a. Element 0 is named "" in ResName slot 0x38a. Links: all 1
; records consistent.
;
; Viewable slot 0x8b: RegObjTabl 0x1600010, ViewableProc, 0x16,
; 0xe24390, 0x8b in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 22, table} at 0x27ed2 +
; 14*0x8b. Element 0 is named "SqTrAs" in ResName slot 0x38b. Links: 6
; of 22 records have a disagreeing link (elements 2-4, 8-10); elements
; 3, 9 point outside the program ROM (RAM records).
;
; Viewable slot 0x8c: RegObjTabl 0x1600010, ViewableProc, 0x1c,
; 0xe243ec, 0x8c in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 28, table} at 0x27ed2 +
; 14*0x8c. Element 0 is named "SqTrAsPs" in ResName slot 0x38c. Links:
; all 28 records consistent.
;
; Viewable slot 0x8e: RegObjTabl 0x1600010, ViewableProc, 0x5, 0xe24460,
; 0x8e in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 5, table} at 0x27ed2 +
; 14*0x8e. Element 0 is named "SqSngSel" in ResName slot 0x38e. Links:
; all 5 records consistent.
;
; Viewable slot 0x8f: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe24478,
; 0x8f in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0x8f. Element 0 is named "SqNameing" in ResName slot 0x38f. Links:
; all 6 records consistent.
;
; Viewable slot 0x92: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe24494,
; 0x92 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x92. Element 0 is named "AfterTouchSet" in ResName slot 0x392.
; Links: all 4 records consistent.
;
; Viewable slot 0xa9: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe244ac,
; 0xa9 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0xa9. Element 0 is named "StepPartBal" in ResName slot 0x3a9.
; Links: all 6 records consistent.
;
; Viewable slot 0xe0: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe244c8,
; 0xe0 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0xe0. Element 0 is named "DemoMenu" in ResName slot 0x3e0. Links:
; all 4 records consistent.
;
; Viewable slot 0xe1: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe244dc,
; 0xe1 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0xe1. Element 0 is named "DemoStyle" in ResName slot 0x3e1. Links:
; all 12 records consistent.
;
; Viewable slot 0xe2: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe24510,
; 0xe2 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0xe2. Element 0 is named "DemoSound" in ResName slot 0x3e2. Links:
; all 12 records consistent.
;
; Viewable slot 0xe3: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe24544,
; 0xe3 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0xe3. Element 0 is named "DemoRhy" in ResName slot 0x3e3. Links:
; all 12 records consistent.
;
; Function slot 0x407: RegObjTabl 0x1600001, FunctionProc, 0x1,
; 0xe21074, 0x407 in InitializeYoko (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 1, table} at 0x27ed2 +
; 14*0x407.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaBoxData_PsSongSelBox
; NakaBoxData_PsSongSelBox  --  naka_direct_play +0x0..+0x2 (ROM 0xe2107c..0xe2107e), 2 bytes
; No RegObjTabl-registered table points at the start of these 2 bytes
; (0xe2107c..0xe2107e); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaBoxData_PsSongSelBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x0, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_direct_play+0x2
; naka_direct_play+0x2  --  naka_direct_play +0x2..+0x14 (ROM 0xe2107e..0xe21090), 18 bytes
; Name strings of element 0 of Function slot 0x407 (table 0xe21074, 1
; entries, InitializeYoko), names for Function slot 0x107:
; "PsSongSelBoxProc".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_direct_play.bin", 0x2, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_direct_play+0x14
; naka_direct_play+0x14  --  naka_direct_play +0x14..+0x50 (ROM 0xe21090..0xe210cc), 60 bytes
; Widget records of element 0 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: TtlScreen (42 B,
; id 0x01600034).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_direct_play.bin", 0x14, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpContainer
; NakaWidget_SmfDpContainer  --  naka_direct_play +0x50..+0x74 (ROM 0xe210cc..0xe210f0), 36 bytes
; Widget records of element 1 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcTempoBox (36
; B, id 0x01600014).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x50, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpVolume
; NakaWidget_SmfDpVolume  --  naka_direct_play +0x74..+0xb2 (ROM 0xe210f0..0xe2112e), 62 bytes
; Widget records of element 2 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcTitleMenu (54
; B, id 0x0160001d).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0x74, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpGroup
; NakaWidget_SmfDpGroup  --  naka_direct_play +0xb2..+0xcc (ROM 0xe2112e..0xe21148), 26 bytes
; Widget records of element 3 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: Box (26 B, id
; 0x01600031).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0xB2, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteRow0
; NakaWidget_SmfDpMuteRow0  --  naka_direct_play +0xcc..+0xf0 (ROM 0xe21148..0xe2116c), 36 bytes
; Widget records of element 4 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcSmfFileNameBox
; (36 B, id 0x01670008).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0xCC, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteRow1
; NakaWidget_SmfDpMuteRow1  --  naka_direct_play +0xf0..+0x114 (ROM 0xe2116c..0xe21190), 36 bytes
; Widget records of element 5 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcSmfSongNameBox
; (36 B, id 0x0167000b).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0xF0, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpLyricsToggle
; NakaWidget_SmfDpLyricsToggle  --  naka_direct_play +0x114..+0x13c (ROM 0xe21190..0xe211b8), 40 bytes
; Widget records of element 6 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcIndexEditSw
; (40 B, id 0x0160001f).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpLyricsToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x114, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteToggle
; NakaWidget_SmfDpMuteToggle  --  naka_direct_play +0x13c..+0x178 (ROM 0xe211b8..0xe211f4), 60 bytes
; Widget records of element 7 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcRamEditBox (58
; B, id 0x0160001b).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x13C, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMeasureBox
; NakaWidget_SmfDpMeasureBox  --  naka_direct_play +0x178..+0x192 (ROM 0xe211f4..0xe2120e), 26 bytes
; Widget records of element 8 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: IvMainEditSw (26
; B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x178, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpFileSelector
; NakaWidget_SmfDpFileSelector  --  naka_direct_play +0x192..+0x1ac (ROM 0xe2120e..0xe21228), 26 bytes
; Widget records of element 9 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: IvFixWin (26 B,
; id 0x0160004a).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpFileSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0x192, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpFileList
; NakaWidget_SmfDpFileList  --  naka_direct_play +0x1ac..+0x1e0 (ROM 0xe21228..0xe2125c), 52 bytes
; Widget records of element 10 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcMuteToggleBox
; (44 B, id 0x0167000f).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AC, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMixer
; NakaWidget_SmfDpMixer  --  naka_direct_play +0x1e0..+0x218 (ROM 0xe2125c..0xe21294), 56 bytes
; Widget records of element 11 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: VwMenuBox (50 B,
; id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E0, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMic
; NakaWidget_SmfDpMic  --  naka_direct_play +0x218..+0x24e (ROM 0xe21294..0xe212ca), 54 bytes
; Widget records of element 12 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: VwMenuBox (50 B,
; id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMic:
	.incbin "includes/generated/naka_direct_play.bin", 0x218, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteChLabel
; NakaWidget_SmfDpMuteChLabel  --  naka_direct_play +0x24e..+0x278 (ROM 0xe212ca..0xe212f4), 42 bytes
; Widget records of element 13 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: Label (32 B, id
; 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteChLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x24E, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteChPanel
; NakaWidget_SmfDpMuteChPanel  --  naka_direct_play +0x278..+0x2b0 (ROM 0xe212f4..0xe2132c), 56 bytes
; Widget records of element 14 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: TtlScreen (42 B,
; id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteChPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x278, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMedleyItem
; NakaWidget_SmfMedleyItem  --  naka_direct_play +0x2b0..+0x2ec (ROM 0xe2132c..0xe21368), 60 bytes
; Widget records of element 15 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcTitleMenu (54
; B, id 0x0160001d).
; -----------------------------------------------------------------------------
NakaWidget_SmfMedleyItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x2B0, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMixerItem
; NakaWidget_SmfMixerItem  --  naka_direct_play +0x2ec..+0x326 (ROM 0xe21368..0xe213a2), 58 bytes
; Widget records of element 16 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcTitleMenu (54
; B, id 0x0160001d).
; -----------------------------------------------------------------------------
NakaWidget_SmfMixerItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x2EC, 0x3A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfLyricsItem
; NakaWidget_SmfLyricsItem  --  naka_direct_play +0x326..+0x364 (ROM 0xe213a2..0xe213e0), 62 bytes
; Widget records of element 17 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcTitleMenu (54
; B, id 0x0160001d).
; -----------------------------------------------------------------------------
NakaWidget_SmfLyricsItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x326, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpSubPanel
; NakaWidget_SmfDpSubPanel  --  naka_direct_play +0x364..+0x388 (ROM 0xe213e0..0xe21404), 36 bytes
; Widget records of element 18 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcTempoBox (36
; B, id 0x01600014).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpSubPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x364, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpDisplayMode
; NakaWidget_SmfDpDisplayMode  --  naka_direct_play +0x388..+0x3b4 (ROM 0xe21404..0xe21430), 44 bytes
; Widget records of element 19 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcFuncEditSw (44
; B, id 0x01600020).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpDisplayMode:
	.incbin "includes/generated/naka_direct_play.bin", 0x388, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpSkipLabel
; NakaWidget_SmfDpSkipLabel  --  naka_direct_play +0x3b4..+0x3da (ROM 0xe21430..0xe21456), 38 bytes
; Widget records of element 20 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: Label (32 B, id
; 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpSkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x3B4, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpLyricsToggle2
; NakaWidget_SmfDpLyricsToggle2  --  naka_direct_play +0x3da..+0x402 (ROM 0xe21456..0xe2147e), 40 bytes
; Widget records of element 21 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcIndexEditSw
; (40 B, id 0x0160001f).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpLyricsToggle2:
	.incbin "includes/generated/naka_direct_play.bin", 0x3DA, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpChLabel
; NakaWidget_SmfDpChLabel  --  naka_direct_play +0x402..+0x426 (ROM 0xe2147e..0xe214a2), 36 bytes
; Widget records of element 22 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: Label (32 B, id
; 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpChLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x402, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteGroup
; NakaWidget_SmfDpMuteGroup  --  naka_direct_play +0x426..+0x440 (ROM 0xe214a2..0xe214bc), 26 bytes
; Widget records of element 23 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: Box (26 B, id
; 0x01600031).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x426, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteSel1
; NakaWidget_SmfDpMuteSel1  --  naka_direct_play +0x440..+0x464 (ROM 0xe214bc..0xe214e0), 36 bytes
; Widget records of element 24 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: Window (36 B, id
; 0x01600035).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteSel1:
	.incbin "includes/generated/naka_direct_play.bin", 0x440, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteSel2
; NakaWidget_SmfDpMuteSel2  --  naka_direct_play +0x464..+0x492 (ROM 0xe214e0..0xe2150e), 46 bytes
; Widget records of element 25 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: VwEditSwBox (44
; B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteSel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x464, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteCtrl1
; NakaWidget_SmfDpMuteCtrl1  --  naka_direct_play +0x492..+0x4ac (ROM 0xe2150e..0xe21528), 26 bytes
; Widget records of element 26 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: Bitmap (26 B, id
; 0x0160002c).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteCtrl1:
	.incbin "includes/generated/naka_direct_play.bin", 0x492, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteSel3
; NakaWidget_SmfDpMuteSel3  --  naka_direct_play +0x4ac..+0x4da (ROM 0xe21528..0xe21556), 46 bytes
; Widget records of element 27 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: VwEditSwBox (44
; B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteSel3:
	.incbin "includes/generated/naka_direct_play.bin", 0x4AC, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteCtrl2
; NakaWidget_SmfDpMuteCtrl2  --  naka_direct_play +0x4da..+0x4f4 (ROM 0xe21556..0xe21570), 26 bytes
; Widget records of element 28 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: Bitmap (26 B, id
; 0x0160002c).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteCtrl2:
	.incbin "includes/generated/naka_direct_play.bin", 0x4DA, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteSel4
; NakaWidget_SmfDpMuteSel4  --  naka_direct_play +0x4f4..+0x522 (ROM 0xe21570..0xe2159e), 46 bytes
; Widget records of element 29 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: VwEditSwBox (44
; B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteSel4:
	.incbin "includes/generated/naka_direct_play.bin", 0x4F4, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteCtrl3
; NakaWidget_SmfDpMuteCtrl3  --  naka_direct_play +0x522..+0x53c (ROM 0xe2159e..0xe215b8), 26 bytes
; Widget records of element 30 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: Bitmap (26 B, id
; 0x0160002c).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteCtrl3:
	.incbin "includes/generated/naka_direct_play.bin", 0x522, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteSel5
; NakaWidget_SmfDpMuteSel5  --  naka_direct_play +0x53c..+0x56a (ROM 0xe215b8..0xe215e6), 46 bytes
; Widget records of element 31 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: VwEditSwBox (44
; B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteSel5:
	.incbin "includes/generated/naka_direct_play.bin", 0x53C, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteCtrl4
; NakaWidget_SmfDpMuteCtrl4  --  naka_direct_play +0x56a..+0x584 (ROM 0xe215e6..0xe21600), 26 bytes
; Widget records of element 32 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: Bitmap (26 B, id
; 0x0160002c).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteCtrl4:
	.incbin "includes/generated/naka_direct_play.bin", 0x56A, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteSel6
; NakaWidget_SmfDpMuteSel6  --  naka_direct_play +0x584..+0x5b2 (ROM 0xe21600..0xe2162e), 46 bytes
; Widget records of element 33 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: VwEditSwBox (44
; B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteSel6:
	.incbin "includes/generated/naka_direct_play.bin", 0x584, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteCtrl5
; NakaWidget_SmfDpMuteCtrl5  --  naka_direct_play +0x5b2..+0x5cc (ROM 0xe2162e..0xe21648), 26 bytes
; Widget records of element 34 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: Bitmap (26 B, id
; 0x0160002c).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteCtrl5:
	.incbin "includes/generated/naka_direct_play.bin", 0x5B2, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMeasure
; NakaWidget_SmfDpMeasure  --  naka_direct_play +0x5cc..+0x5e6 (ROM 0xe21648..0xe21662), 26 bytes
; Widget records of element 35 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: IvMainEditSw (26
; B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0x5CC, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpRT1Selector
; NakaWidget_SmfDpRT1Selector  --  naka_direct_play +0x5e6..+0x612 (ROM 0xe21662..0xe2168e), 44 bytes
; Widget records of element 36 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcRamBox (44 B,
; id 0x0160004f).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpRT1Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x5E6, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpRT2Selector
; NakaWidget_SmfDpRT2Selector  --  naka_direct_play +0x612..+0x63e (ROM 0xe2168e..0xe216ba), 44 bytes
; Widget records of element 37 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: AcRamBox (44 B,
; id 0x0160004f).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpRT2Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x612, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpOrchSel
; NakaWidget_SmfDpOrchSel  --  naka_direct_play +0x63e..+0x662 (ROM 0xe216ba..0xe216de), 36 bytes
; Widget records of element 38 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: Window (36 B, id
; 0x01600035).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpOrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x63E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpRT1Display
; NakaWidget_SmfDpRT1Display  --  naka_direct_play +0x662..+0x68a (ROM 0xe216de..0xe21706), 40 bytes
; Widget records of element 39 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: LyricsBox (40 B,
; id 0x01670010).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpRT1Display:
	.incbin "includes/generated/naka_direct_play.bin", 0x662, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteSwRow0
; NakaWidget_SmfDpMuteSwRow0  --  naka_direct_play +0x68a..+0x6a6 (ROM 0xe21706..0xe21722), 28 bytes
; Widget records of element 40 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: VwBox (28 B, id
; 0x01600011).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteSwRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0x68A, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteSwRow1
; NakaWidget_SmfDpMuteSwRow1  --  naka_direct_play +0x6a6..+0x6cc (ROM 0xe21722..0xe21748), 38 bytes
; Widget records of element 41 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: SongNameBox (38
; B, id 0x01670011).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteSwRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0x6A6, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfDpMuteSwRow2
; NakaWidget_SmfDpMuteSwRow2  --  naka_direct_play +0x6cc..+0x6f2 (ROM 0xe21748..0xe2176e), 38 bytes
; Widget records of element 42 of Viewable slot 0x6f (table 0xe240ac, 43
; entries, InitializeYoko), element 0 "DpSmf"; classes: ComporserNameBox
; (38 B, id 0x01670012).
; -----------------------------------------------------------------------------
NakaWidget_SmfDpMuteSwRow2:
	.incbin "includes/generated/naka_direct_play.bin", 0x6CC, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_direct_play+0x6f2
; naka_direct_play+0x6f2  --  naka_direct_play +0x6f2..+0x72e (ROM 0xe2176e..0xe217aa), 60 bytes
; Widget records of element 0 of Viewable slot 0x70 (table 0xe2415c, 12
; entries, InitializeYoko), element 0 "DpDoc"; classes: TtlScreen (42 B,
; id 0x01600034).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_direct_play.bin", 0x6F2, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocDpContainer
; NakaWidget_DocDpContainer  --  naka_direct_play +0x72e..+0x752 (ROM 0xe217aa..0xe217ce), 36 bytes
; Widget records of element 1 of Viewable slot 0x70 (table 0xe2415c, 12
; entries, InitializeYoko), element 0 "DpDoc"; classes: AcTempoBox (36
; B, id 0x01600014).
; -----------------------------------------------------------------------------
NakaWidget_DocDpContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x72E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocDpVolume
; NakaWidget_DocDpVolume  --  naka_direct_play +0x752..+0x76c (ROM 0xe217ce..0xe217e8), 26 bytes
; Widget records of element 2 of Viewable slot 0x70 (table 0xe2415c, 12
; entries, InitializeYoko), element 0 "DpDoc"; classes: Box (26 B, id
; 0x01600031).
; -----------------------------------------------------------------------------
NakaWidget_DocDpVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0x752, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocDpGroup
; NakaWidget_DocDpGroup  --  naka_direct_play +0x76c..+0x790 (ROM 0xe217e8..0xe2180c), 36 bytes
; Widget records of element 3 of Viewable slot 0x70 (table 0xe2415c, 12
; entries, InitializeYoko), element 0 "DpDoc"; classes: AcDocSongNameBox
; (36 B, id 0x0167000c).
; -----------------------------------------------------------------------------
NakaWidget_DocDpGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x76C, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocDpMuteRow0
; NakaWidget_DocDpMuteRow0  --  naka_direct_play +0x790..+0x7b4 (ROM 0xe2180c..0xe21830), 36 bytes
; Widget records of element 4 of Viewable slot 0x70 (table 0xe2415c, 12
; entries, InitializeYoko), element 0 "DpDoc"; classes: AcDocFileNoBox
; (36 B, id 0x01670009).
; -----------------------------------------------------------------------------
NakaWidget_DocDpMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0x790, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocDpMeasure
; NakaWidget_DocDpMeasure  --  naka_direct_play +0x7b4..+0x7ce (ROM 0xe21830..0xe2184a), 26 bytes
; Widget records of element 5 of Viewable slot 0x70 (table 0xe2415c, 12
; entries, InitializeYoko), element 0 "DpDoc"; classes: IvMainEditSw (26
; B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_DocDpMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0x7B4, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocDpFileSelector
; NakaWidget_DocDpFileSelector  --  naka_direct_play +0x7ce..+0x7e8 (ROM 0xe2184a..0xe21864), 26 bytes
; Widget records of element 6 of Viewable slot 0x70 (table 0xe2415c, 12
; entries, InitializeYoko), element 0 "DpDoc"; classes: IvFixWin (26 B,
; id 0x0160004a).
; -----------------------------------------------------------------------------
NakaWidget_DocDpFileSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0x7CE, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocDpFileList
; NakaWidget_DocDpFileList  --  naka_direct_play +0x7e8..+0x81c (ROM 0xe21864..0xe21898), 52 bytes
; Widget records of element 7 of Viewable slot 0x70 (table 0xe2415c, 12
; entries, InitializeYoko), element 0 "DpDoc"; classes: AcMuteToggleBox
; (44 B, id 0x0167000f).
; -----------------------------------------------------------------------------
NakaWidget_DocDpFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x7E8, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocDpRT2Selector
; NakaWidget_DocDpRT2Selector  --  naka_direct_play +0x81c..+0x850 (ROM 0xe21898..0xe218cc), 52 bytes
; Widget records of element 8 of Viewable slot 0x70 (table 0xe2415c, 12
; entries, InitializeYoko), element 0 "DpDoc"; classes: AcMuteToggleBox
; (44 B, id 0x0167000f).
; -----------------------------------------------------------------------------
NakaWidget_DocDpRT2Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x81C, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocDpOrchSelector
; NakaWidget_DocDpOrchSelector  --  naka_direct_play +0x850..+0x888 (ROM 0xe218cc..0xe21904), 56 bytes
; Widget records of element 9 of Viewable slot 0x70 (table 0xe2415c, 12
; entries, InitializeYoko), element 0 "DpDoc"; classes: AcMuteToggleBox
; (44 B, id 0x0167000f).
; -----------------------------------------------------------------------------
NakaWidget_DocDpOrchSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0x850, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocDpMixer
; NakaWidget_DocDpMixer  --  naka_direct_play +0x888..+0x8c0 (ROM 0xe21904..0xe2193c), 56 bytes
; Widget records of element 10 of Viewable slot 0x70 (table 0xe2415c, 12
; entries, InitializeYoko), element 0 "DpDoc"; classes: VwMenuBox (50 B,
; id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_DocDpMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x888, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocDpMic
; NakaWidget_DocDpMic  --  naka_direct_play +0x8c0..+0x8f6 (ROM 0xe2193c..0xe21972), 54 bytes
; Widget records of element 11 of Viewable slot 0x70 (table 0xe2415c, 12
; entries, InitializeYoko), element 0 "DpDoc"; classes: VwMenuBox (50 B,
; id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_DocDpMic:
	.incbin "includes/generated/naka_direct_play.bin", 0x8C0, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdDpContainer
; NakaWidget_PdDpContainer  --  naka_direct_play +0x8f6..+0x93c (ROM 0xe21972..0xe219b8), 70 bytes
; Widget records of element 0 of Viewable slot 0x71 (table 0xe24190, 11
; entries, InitializeYoko), element 0 "DpPd"; classes: TtlScreen (42 B,
; id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_PdDpContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x8F6, 0x46
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdDpVolume
; NakaWidget_PdDpVolume  --  naka_direct_play +0x93c..+0x960 (ROM 0xe219b8..0xe219dc), 36 bytes
; Widget records of element 1 of Viewable slot 0x71 (table 0xe24190, 11
; entries, InitializeYoko), element 0 "DpPd"; classes: AcTempoBox (36 B,
; id 0x01600014).
; -----------------------------------------------------------------------------
NakaWidget_PdDpVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0x93C, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdDpGroup
; NakaWidget_PdDpGroup  --  naka_direct_play +0x960..+0x97a (ROM 0xe219dc..0xe219f6), 26 bytes
; Widget records of element 2 of Viewable slot 0x71 (table 0xe24190, 11
; entries, InitializeYoko), element 0 "DpPd"; classes: Box (26 B, id
; 0x01600031).
; -----------------------------------------------------------------------------
NakaWidget_PdDpGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x960, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdDpMuteRow0
; NakaWidget_PdDpMuteRow0  --  naka_direct_play +0x97a..+0x99e (ROM 0xe219f6..0xe21a1a), 36 bytes
; Widget records of element 3 of Viewable slot 0x71 (table 0xe24190, 11
; entries, InitializeYoko), element 0 "DpPd"; classes: AcPDSongNameBox
; (36 B, id 0x0167000d).
; -----------------------------------------------------------------------------
NakaWidget_PdDpMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0x97A, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdDpMuteRow1
; NakaWidget_PdDpMuteRow1  --  naka_direct_play +0x99e..+0x9c2 (ROM 0xe21a1a..0xe21a3e), 36 bytes
; Widget records of element 4 of Viewable slot 0x71 (table 0xe24190, 11
; entries, InitializeYoko), element 0 "DpPd"; classes: AcPDFileNoBox (36
; B, id 0x0167000a).
; -----------------------------------------------------------------------------
NakaWidget_PdDpMuteRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0x99E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdDpMeasure
; NakaWidget_PdDpMeasure  --  naka_direct_play +0x9c2..+0x9dc (ROM 0xe21a3e..0xe21a58), 26 bytes
; Widget records of element 5 of Viewable slot 0x71 (table 0xe24190, 11
; entries, InitializeYoko), element 0 "DpPd"; classes: IvMainEditSw (26
; B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_PdDpMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0x9C2, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdDpFileSelector
; NakaWidget_PdDpFileSelector  --  naka_direct_play +0x9dc..+0x9f6 (ROM 0xe21a58..0xe21a72), 26 bytes
; Widget records of element 6 of Viewable slot 0x71 (table 0xe24190, 11
; entries, InitializeYoko), element 0 "DpPd"; classes: IvFixWin (26 B,
; id 0x0160004a).
; -----------------------------------------------------------------------------
NakaWidget_PdDpFileSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0x9DC, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdDpFileList
; NakaWidget_PdDpFileList  --  naka_direct_play +0x9f6..+0xa2a (ROM 0xe21a72..0xe21aa6), 52 bytes
; Widget records of element 7 of Viewable slot 0x71 (table 0xe24190, 11
; entries, InitializeYoko), element 0 "DpPd"; classes: AcMuteToggleBox
; (44 B, id 0x0167000f).
; -----------------------------------------------------------------------------
NakaWidget_PdDpFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x9F6, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdDpOrchSelector
; NakaWidget_PdDpOrchSelector  --  naka_direct_play +0xa2a..+0xa62 (ROM 0xe21aa6..0xe21ade), 56 bytes
; Widget records of element 8 of Viewable slot 0x71 (table 0xe24190, 11
; entries, InitializeYoko), element 0 "DpPd"; classes: AcMuteToggleBox
; (44 B, id 0x0167000f).
; -----------------------------------------------------------------------------
NakaWidget_PdDpOrchSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0xA2A, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdDpMixer
; NakaWidget_PdDpMixer  --  naka_direct_play +0xa62..+0xa9a (ROM 0xe21ade..0xe21b16), 56 bytes
; Widget records of element 9 of Viewable slot 0x71 (table 0xe24190, 11
; entries, InitializeYoko), element 0 "DpPd"; classes: VwMenuBox (50 B,
; id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_PdDpMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0xA62, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdDpMic
; NakaWidget_PdDpMic  --  naka_direct_play +0xa9a..+0xad0 (ROM 0xe21b16..0xe21b4c), 54 bytes
; Widget records of element 10 of Viewable slot 0x71 (table 0xe24190, 11
; entries, InitializeYoko), element 0 "DpPd"; classes: VwMenuBox (50 B,
; id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_PdDpMic:
	.incbin "includes/generated/naka_direct_play.bin", 0xA9A, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyContainer
; NakaWidget_SmfMdlyContainer  --  naka_direct_play +0xad0..+0xb0c (ROM 0xe21b4c..0xe21b88), 60 bytes
; Widget records of element 0 of Viewable slot 0x72 (table 0xe241c0, 7
; entries, InitializeYoko), element 0 "DpSmfLyr"; classes: TtlScreen (42
; B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0xAD0, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyVolume
; NakaWidget_SmfMdlyVolume  --  naka_direct_play +0xb0c..+0xb30 (ROM 0xe21b88..0xe21bac), 36 bytes
; Widget records of element 1 of Viewable slot 0x72 (table 0xe241c0, 7
; entries, InitializeYoko), element 0 "DpSmfLyr"; classes: AcTempoBox
; (36 B, id 0x01600014).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0xB0C, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyMeasure
; NakaWidget_SmfMdlyMeasure  --  naka_direct_play +0xb30..+0xb4a (ROM 0xe21bac..0xe21bc6), 26 bytes
; Widget records of element 2 of Viewable slot 0x72 (table 0xe241c0, 7
; entries, InitializeYoko), element 0 "DpSmfLyr"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0xB30, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyFileSelector
; NakaWidget_SmfMdlyFileSelector  --  naka_direct_play +0xb4a..+0xb64 (ROM 0xe21bc6..0xe21be0), 26 bytes
; Widget records of element 3 of Viewable slot 0x72 (table 0xe241c0, 7
; entries, InitializeYoko), element 0 "DpSmfLyr"; classes: IvFixWin (26
; B, id 0x0160004a).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyFileSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0xB4A, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyMicWidget
; NakaWidget_SmfMdlyMicWidget  --  naka_direct_play +0xb64..+0xb9a (ROM 0xe21be0..0xe21c16), 54 bytes
; Widget records of element 4 of Viewable slot 0x72 (table 0xe241c0, 7
; entries, InitializeYoko), element 0 "DpSmfLyr"; classes: VwMenuBox (50
; B, id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyMicWidget:
	.incbin "includes/generated/naka_direct_play.bin", 0xB64, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyOrchSel
; NakaWidget_SmfMdlyOrchSel  --  naka_direct_play +0xb9a..+0xbb4 (ROM 0xe21c16..0xe21c30), 26 bytes
; Widget records of element 5 of Viewable slot 0x72 (table 0xe241c0, 7
; entries, InitializeYoko), element 0 "DpSmfLyr"; classes: IvFixWin (26
; B, id 0x0160004a).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyOrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0xB9A, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyOrchRow
; NakaWidget_SmfMdlyOrchRow  --  naka_direct_play +0xbb4..+0xbca (ROM 0xe21c30..0xe21c46), 22 bytes
; Widget records of element 6 of Viewable slot 0x72 (table 0xe241c0, 7
; entries, InitializeYoko), element 0 "DpSmfLyr"; classes: LyeicsBoxFunc
; (22 B, id 0x01670013).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyOrchRow:
	.incbin "includes/generated/naka_direct_play.bin", 0xBB4, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyContainer2
; NakaWidget_SmfMdlyContainer2  --  naka_direct_play +0xbca..+0xc00 (ROM 0xe21c46..0xe21c7c), 54 bytes
; Widget records of element 0 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes: TtlScreen
; (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyContainer2:
	.incbin "includes/generated/naka_direct_play.bin", 0xBCA, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyLyricsItem
; NakaWidget_SmfMdlyLyricsItem  --  naka_direct_play +0xc00..+0xc3e (ROM 0xe21c7c..0xe21cba), 62 bytes
; Widget records of element 1 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes: AcTitleMenu
; (54 B, id 0x0160001d).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyLyricsItem:
	.incbin "includes/generated/naka_direct_play.bin", 0xC00, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlySubPanel
; NakaWidget_SmfMdlySubPanel  --  naka_direct_play +0xc3e..+0xc62 (ROM 0xe21cba..0xe21cde), 36 bytes
; Widget records of element 2 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes: AcTempoBox
; (36 B, id 0x01600014).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlySubPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0xC3E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyLyricsToggle
; NakaWidget_SmfMdlyLyricsToggle  --  naka_direct_play +0xc62..+0xc8a (ROM 0xe21cde..0xe21d06), 40 bytes
; Widget records of element 3 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes:
; AcIndexEditSw (40 B, id 0x0160001f).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyLyricsToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0xC62, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyGroup
; NakaWidget_SmfMdlyGroup  --  naka_direct_play +0xc8a..+0xca4 (ROM 0xe21d06..0xe21d20), 26 bytes
; Widget records of element 4 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes: Box (26 B,
; id 0x01600031).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0xC8A, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyMuteRow0
; NakaWidget_SmfMdlyMuteRow0  --  naka_direct_play +0xca4..+0xcc8 (ROM 0xe21d20..0xe21d44), 36 bytes
; Widget records of element 5 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes:
; AcSmfSongNameBox (36 B, id 0x0167000b).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0xCA4, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyMuteRow1
; NakaWidget_SmfMdlyMuteRow1  --  naka_direct_play +0xcc8..+0xcec (ROM 0xe21d44..0xe21d68), 36 bytes
; Widget records of element 6 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes:
; AcSmfFileNameBox (36 B, id 0x01670008).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyMuteRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0xCC8, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyMuteToggle
; NakaWidget_SmfMdlyMuteToggle  --  naka_direct_play +0xcec..+0xd1a (ROM 0xe21d68..0xe21d96), 46 bytes
; Widget records of element 7 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyMuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0xCEC, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlySkipLabel
; NakaWidget_SmfMdlySkipLabel  --  naka_direct_play +0xd1a..+0xd40 (ROM 0xe21d96..0xe21dbc), 38 bytes
; Widget records of element 8 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlySkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0xD1A, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyMutePanel
; NakaWidget_SmfMdlyMutePanel  --  naka_direct_play +0xd40..+0xd7c (ROM 0xe21dbc..0xe21df8), 60 bytes
; Widget records of element 9 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes: AcRamEditBox
; (58 B, id 0x0160001b).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyMutePanel:
	.incbin "includes/generated/naka_direct_play.bin", 0xD40, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyMeasureBox
; NakaWidget_SmfMdlyMeasureBox  --  naka_direct_play +0xd7c..+0xd96 (ROM 0xe21df8..0xe21e12), 26 bytes
; Widget records of element 10 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0xD7C, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyOffOnSel
; NakaWidget_SmfMdlyOffOnSel  --  naka_direct_play +0xd96..+0xdac (ROM 0xe21e12..0xe21e28), 22 bytes
; Widget records of element 11 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes: IvExit (22
; B, id 0x01600047).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyOffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0xD96, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyOffOnList
; NakaWidget_SmfMdlyOffOnList  --  naka_direct_play +0xdac..+0xde0 (ROM 0xe21e28..0xe21e5c), 52 bytes
; Widget records of element 12 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes:
; AcMuteToggleBox (44 B, id 0x0167000f).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyOffOnList:
	.incbin "includes/generated/naka_direct_play.bin", 0xDAC, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyMixerWidget
; NakaWidget_SmfMdlyMixerWidget  --  naka_direct_play +0xde0..+0xe18 (ROM 0xe21e5c..0xe21e94), 56 bytes
; Widget records of element 13 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes: VwMenuBox
; (50 B, id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyMixerWidget:
	.incbin "includes/generated/naka_direct_play.bin", 0xDE0, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyMicWidget2
; NakaWidget_SmfMdlyMicWidget2  --  naka_direct_play +0xe18..+0xe4e (ROM 0xe21e94..0xe21eca), 54 bytes
; Widget records of element 14 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes: VwMenuBox
; (50 B, id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyMicWidget2:
	.incbin "includes/generated/naka_direct_play.bin", 0xE18, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyMuteChLabel
; NakaWidget_SmfMdlyMuteChLabel  --  naka_direct_play +0xe4e..+0xe78 (ROM 0xe21eca..0xe21ef4), 42 bytes
; Widget records of element 15 of Viewable slot 0x73 (table 0xe241e0, 16
; entries, InitializeYoko), element 0 "DpMdlySmf"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyMuteChLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0xE4E, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_direct_play+0xe78
; naka_direct_play+0xe78  --  naka_direct_play +0xe78..+0xeae (ROM 0xe21ef4..0xe21f2a), 54 bytes
; Widget records of element 0 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_direct_play.bin", 0xE78, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdlyRootContainer
; NakaWidget_SmfMdlyRootContainer  --  naka_direct_play +0xeae..+0xee4 (ROM 0xe21f2a..0xe21f60), 54 bytes
; Widget records of element 1 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdlyRootContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0xEAE, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlyContainer
; NakaWidget_DocMdlyContainer  --  naka_direct_play +0xee4..+0xefe (ROM 0xe21f60..0xe21f7a), 26 bytes
; Widget records of element 2 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: Box (26 B, id 0x01600031).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlyContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0xEE4, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlyGroup
; NakaWidget_DocMdlyGroup  --  naka_direct_play +0xefe..+0xf22 (ROM 0xe21f7a..0xe21f9e), 36 bytes
; Widget records of element 3 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: AcDocSongNameBox (36 B, id
; 0x0167000c).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlyGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0xEFE, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlyMuteRow0
; NakaWidget_DocMdlyMuteRow0  --  naka_direct_play +0xf22..+0xf46 (ROM 0xe21f9e..0xe21fc2), 36 bytes
; Widget records of element 4 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: AcDocFileNoBox (36 B, id
; 0x01670009).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlyMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0xF22, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlySubPanel
; NakaWidget_DocMdlySubPanel  --  naka_direct_play +0xf46..+0xf6a (ROM 0xe21fc2..0xe21fe6), 36 bytes
; Widget records of element 5 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: AcTempoBox (36 B, id 0x01600014).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlySubPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0xF46, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlyMuteToggle
; NakaWidget_DocMdlyMuteToggle  --  naka_direct_play +0xf6a..+0xf98 (ROM 0xe21fe6..0xe22014), 46 bytes
; Widget records of element 6 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: VwEditSwBox (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlyMuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0xF6A, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlySkipLabel
; NakaWidget_DocMdlySkipLabel  --  naka_direct_play +0xf98..+0xfbe (ROM 0xe22014..0xe2203a), 38 bytes
; Widget records of element 7 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: Label (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlySkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0xF98, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlyMeasureBox
; NakaWidget_DocMdlyMeasureBox  --  naka_direct_play +0xfbe..+0xfd8 (ROM 0xe2203a..0xe22054), 26 bytes
; Widget records of element 8 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: IvMainEditSw (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlyMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0xFBE, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlyOffOnSel
; NakaWidget_DocMdlyOffOnSel  --  naka_direct_play +0xfd8..+0xfee (ROM 0xe22054..0xe2206a), 22 bytes
; Widget records of element 9 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: IvExit (22 B, id 0x01600047).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlyOffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0xFD8, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlyOffOnList
; NakaWidget_DocMdlyOffOnList  --  naka_direct_play +0xfee..+0x1022 (ROM 0xe2206a..0xe2209e), 52 bytes
; Widget records of element 10 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: AcMuteToggleBox (44 B, id
; 0x0167000f).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlyOffOnList:
	.incbin "includes/generated/naka_direct_play.bin", 0xFEE, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlyRT2Sel
; NakaWidget_DocMdlyRT2Sel  --  naka_direct_play +0x1022..+0x1056 (ROM 0xe2209e..0xe220d2), 52 bytes
; Widget records of element 11 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: AcMuteToggleBox (44 B, id
; 0x0167000f).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlyRT2Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1022, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlyOrchSel
; NakaWidget_DocMdlyOrchSel  --  naka_direct_play +0x1056..+0x108e (ROM 0xe220d2..0xe2210a), 56 bytes
; Widget records of element 12 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: AcMuteToggleBox (44 B, id
; 0x0167000f).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlyOrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1056, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlyMixer
; NakaWidget_DocMdlyMixer  --  naka_direct_play +0x108e..+0x10c6 (ROM 0xe2210a..0xe22142), 56 bytes
; Widget records of element 13 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: VwMenuBox (50 B, id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlyMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x108E, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DocMdlyMic
; NakaWidget_DocMdlyMic  --  naka_direct_play +0x10c6..+0x10fc (ROM 0xe22142..0xe22178), 54 bytes
; Widget records of element 14 of Viewable slot 0x74 (table 0xe24224, 15
; entries, InitializeYoko); classes: VwMenuBox (50 B, id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_DocMdlyMic:
	.incbin "includes/generated/naka_direct_play.bin", 0x10C6, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_direct_play+0x10fc
; naka_direct_play+0x10fc  --  naka_direct_play +0x10fc..+0x113c (ROM 0xe22178..0xe221b8), 64 bytes
; Widget records of element 0 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes: TtlScreen (42
; B, id 0x01600034).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_direct_play.bin", 0x10FC, 0x40
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdMdlyContainer
; NakaWidget_PdMdlyContainer  --  naka_direct_play +0x113c..+0x1160 (ROM 0xe221b8..0xe221dc), 36 bytes
; Widget records of element 1 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes: AcTempoBox
; (36 B, id 0x01600014).
; -----------------------------------------------------------------------------
NakaWidget_PdMdlyContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x113C, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdMdlyGroup
; NakaWidget_PdMdlyGroup  --  naka_direct_play +0x1160..+0x117a (ROM 0xe221dc..0xe221f6), 26 bytes
; Widget records of element 2 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes: Box (26 B, id
; 0x01600031).
; -----------------------------------------------------------------------------
NakaWidget_PdMdlyGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x1160, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdMdlyMuteRow0
; NakaWidget_PdMdlyMuteRow0  --  naka_direct_play +0x117a..+0x119e (ROM 0xe221f6..0xe2221a), 36 bytes
; Widget records of element 3 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes:
; AcPDSongNameBox (36 B, id 0x0167000d).
; -----------------------------------------------------------------------------
NakaWidget_PdMdlyMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0x117A, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdMdlyMuteRow1
; NakaWidget_PdMdlyMuteRow1  --  naka_direct_play +0x119e..+0x11c2 (ROM 0xe2221a..0xe2223e), 36 bytes
; Widget records of element 4 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes: AcPDFileNoBox
; (36 B, id 0x0167000a).
; -----------------------------------------------------------------------------
NakaWidget_PdMdlyMuteRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0x119E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdMdlyMuteToggle
; NakaWidget_PdMdlyMuteToggle  --  naka_direct_play +0x11c2..+0x11f0 (ROM 0xe2223e..0xe2226c), 46 bytes
; Widget records of element 5 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_PdMdlyMuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x11C2, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdMdlySkipLabel
; NakaWidget_PdMdlySkipLabel  --  naka_direct_play +0x11f0..+0x1216 (ROM 0xe2226c..0xe22292), 38 bytes
; Widget records of element 6 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_PdMdlySkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x11F0, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdMdlyMeasureBox
; NakaWidget_PdMdlyMeasureBox  --  naka_direct_play +0x1216..+0x1230 (ROM 0xe22292..0xe222ac), 26 bytes
; Widget records of element 7 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_PdMdlyMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x1216, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdMdlyOffOnSel
; NakaWidget_PdMdlyOffOnSel  --  naka_direct_play +0x1230..+0x1246 (ROM 0xe222ac..0xe222c2), 22 bytes
; Widget records of element 8 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes: IvExit (22 B,
; id 0x01600047).
; -----------------------------------------------------------------------------
NakaWidget_PdMdlyOffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1230, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdMdlyOffOnList
; NakaWidget_PdMdlyOffOnList  --  naka_direct_play +0x1246..+0x127a (ROM 0xe222c2..0xe222f6), 52 bytes
; Widget records of element 9 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes:
; AcMuteToggleBox (44 B, id 0x0167000f).
; -----------------------------------------------------------------------------
NakaWidget_PdMdlyOffOnList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1246, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdMdlyRT2Sel
; NakaWidget_PdMdlyRT2Sel  --  naka_direct_play +0x127a..+0x12b2 (ROM 0xe222f6..0xe2232e), 56 bytes
; Widget records of element 10 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes:
; AcMuteToggleBox (44 B, id 0x0167000f).
; -----------------------------------------------------------------------------
NakaWidget_PdMdlyRT2Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x127A, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdMdlyMixer
; NakaWidget_PdMdlyMixer  --  naka_direct_play +0x12b2..+0x12ea (ROM 0xe2232e..0xe22366), 56 bytes
; Widget records of element 11 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes: VwMenuBox (50
; B, id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_PdMdlyMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x12B2, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PdMdlyMic
; NakaWidget_PdMdlyMic  --  naka_direct_play +0x12ea..+0x1320 (ROM 0xe22366..0xe2239c), 54 bytes
; Widget records of element 12 of Viewable slot 0x75 (table 0xe24264, 13
; entries, InitializeYoko), element 0 "DpMdlyPd"; classes: VwMenuBox (50
; B, id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_PdMdlyMic:
	.incbin "includes/generated/naka_direct_play.bin", 0x12EA, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_direct_play+0x1320
; naka_direct_play+0x1320  --  naka_direct_play +0x1320..+0x1356 (ROM 0xe2239c..0xe223d2), 54 bytes
; Widget records of element 0 of Viewable slot 0x76 (table 0xe2429c, 8
; entries, InitializeYoko), element 0 "DpMdlySmfLyr"; classes: TtlScreen
; (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_direct_play.bin", 0x1320, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdly2Container
; NakaWidget_SmfMdly2Container  --  naka_direct_play +0x1356..+0x137a (ROM 0xe223d2..0xe223f6), 36 bytes
; Widget records of element 1 of Viewable slot 0x76 (table 0xe2429c, 8
; entries, InitializeYoko), element 0 "DpMdlySmfLyr"; classes:
; AcTempoBox (36 B, id 0x01600014).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdly2Container:
	.incbin "includes/generated/naka_direct_play.bin", 0x1356, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdly2MuteToggle
; NakaWidget_SmfMdly2MuteToggle  --  naka_direct_play +0x137a..+0x13a8 (ROM 0xe223f6..0xe22424), 46 bytes
; Widget records of element 2 of Viewable slot 0x76 (table 0xe2429c, 8
; entries, InitializeYoko), element 0 "DpMdlySmfLyr"; classes:
; VwEditSwBox (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdly2MuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x137A, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdly2SkipLabel
; NakaWidget_SmfMdly2SkipLabel  --  naka_direct_play +0x13a8..+0x13ce (ROM 0xe22424..0xe2244a), 38 bytes
; Widget records of element 3 of Viewable slot 0x76 (table 0xe2429c, 8
; entries, InitializeYoko), element 0 "DpMdlySmfLyr"; classes: Label (32
; B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdly2SkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x13A8, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdly2MeasureBox
; NakaWidget_SmfMdly2MeasureBox  --  naka_direct_play +0x13ce..+0x13e8 (ROM 0xe2244a..0xe22464), 26 bytes
; Widget records of element 4 of Viewable slot 0x76 (table 0xe2429c, 8
; entries, InitializeYoko), element 0 "DpMdlySmfLyr"; classes:
; IvMainEditSw (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdly2MeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x13CE, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdly2OffOnSel
; NakaWidget_SmfMdly2OffOnSel  --  naka_direct_play +0x13e8..+0x13fe (ROM 0xe22464..0xe2247a), 22 bytes
; Widget records of element 5 of Viewable slot 0x76 (table 0xe2429c, 8
; entries, InitializeYoko), element 0 "DpMdlySmfLyr"; classes: IvExit
; (22 B, id 0x01600047).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdly2OffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x13E8, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdly2MicWidget
; NakaWidget_SmfMdly2MicWidget  --  naka_direct_play +0x13fe..+0x1434 (ROM 0xe2247a..0xe224b0), 54 bytes
; Widget records of element 6 of Viewable slot 0x76 (table 0xe2429c, 8
; entries, InitializeYoko), element 0 "DpMdlySmfLyr"; classes: VwMenuBox
; (50 B, id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdly2MicWidget:
	.incbin "includes/generated/naka_direct_play.bin", 0x13FE, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SmfMdly2OrchSel
; NakaWidget_SmfMdly2OrchSel  --  naka_direct_play +0x1434..+0x144e (ROM 0xe224b0..0xe224ca), 26 bytes
; Widget records of element 7 of Viewable slot 0x76 (table 0xe2429c, 8
; entries, InitializeYoko), element 0 "DpMdlySmfLyr"; classes: IvFixWin
; (26 B, id 0x0160004a).
; -----------------------------------------------------------------------------
NakaWidget_SmfMdly2OrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1434, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlyContainer
; NakaWidget_SongMdlyContainer  --  naka_direct_play +0x144e..+0x148c (ROM 0xe224ca..0xe22508), 62 bytes
; Widget records of element 0 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes: TtlScreen
; (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlyContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x144E, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlyGroup
; NakaWidget_SongMdlyGroup  --  naka_direct_play +0x148c..+0x14a6 (ROM 0xe22508..0xe22522), 26 bytes
; Widget records of element 1 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes: Box (26 B,
; id 0x01600031).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlyGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x148C, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlyVolume
; NakaWidget_SongMdlyVolume  --  naka_direct_play +0x14a6..+0x14ca (ROM 0xe22522..0xe22546), 36 bytes
; Widget records of element 2 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes: AcTempoBox
; (36 B, id 0x01600014).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlyVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0x14A6, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel
; NakaWidget_SongMdlySongSel  --  naka_direct_play +0x14ca..+0x14ee (ROM 0xe22546..0xe2256a), 36 bytes
; Widget records of element 3 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; TrTransposeBox (36 B, id 0x01600067).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x14CA, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongList
; NakaWidget_SongMdlySongList  --  naka_direct_play +0x14ee..+0x150c (ROM 0xe2256a..0xe22588), 30 bytes
; Widget records of element 4 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes: MeasureBox
; (30 B, id 0x0167000e).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongList:
	.incbin "includes/generated/naka_direct_play.bin", 0x14EE, 0x1E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlyRT1Sel
; NakaWidget_SongMdlyRT1Sel  --  naka_direct_play +0x150c..+0x153a (ROM 0xe22588..0xe225b6), 46 bytes
; Widget records of element 5 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlyRT1Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x150C, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlyMeasureBox
; NakaWidget_SongMdlyMeasureBox  --  naka_direct_play +0x153a..+0x1554 (ROM 0xe225b6..0xe225d0), 26 bytes
; Widget records of element 6 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlyMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x153A, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlyFileList
; NakaWidget_SongMdlyFileList  --  naka_direct_play +0x1554..+0x1578 (ROM 0xe225d0..0xe225f4), 36 bytes
; Widget records of element 7 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcCurSongNameBox (36 B, id 0x01670005).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlyFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1554, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlyMutePanel
; NakaWidget_SongMdlyMutePanel  --  naka_direct_play +0x1578..+0x158e (ROM 0xe225f4..0xe2260a), 22 bytes
; Widget records of element 8 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; IvTrackSwitch (22 B, id 0x0160005b).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlyMutePanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1578, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlyMuteList
; NakaWidget_SongMdlyMuteList  --  naka_direct_play +0x158e..+0x15b2 (ROM 0xe2260a..0xe2262e), 36 bytes
; Widget records of element 9 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcDiskFileNameBox (36 B, id 0x01670007).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlyMuteList:
	.incbin "includes/generated/naka_direct_play.bin", 0x158E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySkipLabel
; NakaWidget_SongMdlySkipLabel  --  naka_direct_play +0x15b2..+0x15d8 (ROM 0xe2262e..0xe22654), 38 bytes
; Widget records of element 10 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x15B2, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlyOffOnSel
; NakaWidget_SongMdlyOffOnSel  --  naka_direct_play +0x15d8..+0x15ee (ROM 0xe22654..0xe2266a), 22 bytes
; Widget records of element 11 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes: IvExit (22
; B, id 0x01600047).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlyOffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x15D8, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlyMixer
; NakaWidget_SongMdlyMixer  --  naka_direct_play +0x15ee..+0x1626 (ROM 0xe2266a..0xe226a2), 56 bytes
; Widget records of element 12 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes: VwMenuBox
; (50 B, id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlyMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x15EE, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlyOrchSel
; NakaWidget_SongMdlyOrchSel  --  naka_direct_play +0x1626..+0x164a (ROM 0xe226a2..0xe226c6), 36 bytes
; Widget records of element 13 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes: Window (36
; B, id 0x01600035).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlyOrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1626, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel1
; NakaWidget_SongMdlySongSel1  --  naka_direct_play +0x164a..+0x166e (ROM 0xe226c6..0xe226ea), 36 bytes
; Widget records of element 14 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel1:
	.incbin "includes/generated/naka_direct_play.bin", 0x164A, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel2
; NakaWidget_SongMdlySongSel2  --  naka_direct_play +0x166e..+0x1692 (ROM 0xe226ea..0xe2270e), 36 bytes
; Widget records of element 15 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x166E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel3
; NakaWidget_SongMdlySongSel3  --  naka_direct_play +0x1692..+0x16b6 (ROM 0xe2270e..0xe22732), 36 bytes
; Widget records of element 16 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel3:
	.incbin "includes/generated/naka_direct_play.bin", 0x1692, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel4
; NakaWidget_SongMdlySongSel4  --  naka_direct_play +0x16b6..+0x16da (ROM 0xe22732..0xe22756), 36 bytes
; Widget records of element 17 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel4:
	.incbin "includes/generated/naka_direct_play.bin", 0x16B6, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel5
; NakaWidget_SongMdlySongSel5  --  naka_direct_play +0x16da..+0x16fe (ROM 0xe22756..0xe2277a), 36 bytes
; Widget records of element 18 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel5:
	.incbin "includes/generated/naka_direct_play.bin", 0x16DA, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel6
; NakaWidget_SongMdlySongSel6  --  naka_direct_play +0x16fe..+0x1722 (ROM 0xe2277a..0xe2279e), 36 bytes
; Widget records of element 19 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel6:
	.incbin "includes/generated/naka_direct_play.bin", 0x16FE, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel7
; NakaWidget_SongMdlySongSel7  --  naka_direct_play +0x1722..+0x1746 (ROM 0xe2279e..0xe227c2), 36 bytes
; Widget records of element 20 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel7:
	.incbin "includes/generated/naka_direct_play.bin", 0x1722, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel8
; NakaWidget_SongMdlySongSel8  --  naka_direct_play +0x1746..+0x176a (ROM 0xe227c2..0xe227e6), 36 bytes
; Widget records of element 21 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel8:
	.incbin "includes/generated/naka_direct_play.bin", 0x1746, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel9
; NakaWidget_SongMdlySongSel9  --  naka_direct_play +0x176a..+0x178e (ROM 0xe227e6..0xe2280a), 36 bytes
; Widget records of element 22 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel9:
	.incbin "includes/generated/naka_direct_play.bin", 0x176A, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel10
; NakaWidget_SongMdlySongSel10  --  naka_direct_play +0x178e..+0x17b2 (ROM 0xe2280a..0xe2282e), 36 bytes
; Widget records of element 23 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel10:
	.incbin "includes/generated/naka_direct_play.bin", 0x178E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel11
; NakaWidget_SongMdlySongSel11  --  naka_direct_play +0x17b2..+0x17d6 (ROM 0xe2282e..0xe22852), 36 bytes
; Widget records of element 24 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel11:
	.incbin "includes/generated/naka_direct_play.bin", 0x17B2, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel12
; NakaWidget_SongMdlySongSel12  --  naka_direct_play +0x17d6..+0x17fa (ROM 0xe22852..0xe22876), 36 bytes
; Widget records of element 25 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel12:
	.incbin "includes/generated/naka_direct_play.bin", 0x17D6, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel13
; NakaWidget_SongMdlySongSel13  --  naka_direct_play +0x17fa..+0x181e (ROM 0xe22876..0xe2289a), 36 bytes
; Widget records of element 26 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel13:
	.incbin "includes/generated/naka_direct_play.bin", 0x17FA, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel14
; NakaWidget_SongMdlySongSel14  --  naka_direct_play +0x181e..+0x1842 (ROM 0xe2289a..0xe228be), 36 bytes
; Widget records of element 27 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel14:
	.incbin "includes/generated/naka_direct_play.bin", 0x181E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel15
; NakaWidget_SongMdlySongSel15  --  naka_direct_play +0x1842..+0x1866 (ROM 0xe228be..0xe228e2), 36 bytes
; Widget records of element 28 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel15:
	.incbin "includes/generated/naka_direct_play.bin", 0x1842, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdlySongSel16
; NakaWidget_SongMdlySongSel16  --  naka_direct_play +0x1866..+0x188a (ROM 0xe228e2..0xe22906), 36 bytes
; Widget records of element 29 of Viewable slot 0x78 (table 0xe242c0, 30
; entries, InitializeYoko), element 0 "DkMdlyPly"; classes:
; AcTrackSwitch (36 B, id 0x01600059).
; -----------------------------------------------------------------------------
NakaWidget_SongMdlySongSel16:
	.incbin "includes/generated/naka_direct_play.bin", 0x1866, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_direct_play+0x188a
; naka_direct_play+0x188a  --  naka_direct_play +0x188a..+0x18c0 (ROM 0xe22906..0xe2293c), 54 bytes
; Widget records of element 0 of Viewable slot 0x7a (table 0xe2433c, 12
; entries, InitializeYoko), element 0 "SqMdlyPly"; classes: TtlScreen
; (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_direct_play.bin", 0x188A, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdly2Group
; NakaWidget_SongMdly2Group  --  naka_direct_play +0x18c0..+0x18da (ROM 0xe2293c..0xe22956), 26 bytes
; Widget records of element 1 of Viewable slot 0x7a (table 0xe2433c, 12
; entries, InitializeYoko), element 0 "SqMdlyPly"; classes: Box (26 B,
; id 0x01600031).
; -----------------------------------------------------------------------------
NakaWidget_SongMdly2Group:
	.incbin "includes/generated/naka_direct_play.bin", 0x18C0, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdly2Volume
; NakaWidget_SongMdly2Volume  --  naka_direct_play +0x18da..+0x18fe (ROM 0xe22956..0xe2297a), 36 bytes
; Widget records of element 2 of Viewable slot 0x7a (table 0xe2433c, 12
; entries, InitializeYoko), element 0 "SqMdlyPly"; classes: AcTempoBox
; (36 B, id 0x01600014).
; -----------------------------------------------------------------------------
NakaWidget_SongMdly2Volume:
	.incbin "includes/generated/naka_direct_play.bin", 0x18DA, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdly2SongList
; NakaWidget_SongMdly2SongList  --  naka_direct_play +0x18fe..+0x191c (ROM 0xe2297a..0xe22998), 30 bytes
; Widget records of element 3 of Viewable slot 0x7a (table 0xe2433c, 12
; entries, InitializeYoko), element 0 "SqMdlyPly"; classes: MeasureBox
; (30 B, id 0x0167000e).
; -----------------------------------------------------------------------------
NakaWidget_SongMdly2SongList:
	.incbin "includes/generated/naka_direct_play.bin", 0x18FE, 0x1E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdly2SongSel
; NakaWidget_SongMdly2SongSel  --  naka_direct_play +0x191c..+0x1940 (ROM 0xe22998..0xe229bc), 36 bytes
; Widget records of element 4 of Viewable slot 0x7a (table 0xe2433c, 12
; entries, InitializeYoko), element 0 "SqMdlyPly"; classes:
; TrTransposeBox (36 B, id 0x01600067).
; -----------------------------------------------------------------------------
NakaWidget_SongMdly2SongSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x191C, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdly2RT1Sel
; NakaWidget_SongMdly2RT1Sel  --  naka_direct_play +0x1940..+0x196e (ROM 0xe229bc..0xe229ea), 46 bytes
; Widget records of element 5 of Viewable slot 0x7a (table 0xe2433c, 12
; entries, InitializeYoko), element 0 "SqMdlyPly"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_SongMdly2RT1Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1940, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdly2SkipLabel
; NakaWidget_SongMdly2SkipLabel  --  naka_direct_play +0x196e..+0x1994 (ROM 0xe229ea..0xe22a10), 38 bytes
; Widget records of element 6 of Viewable slot 0x7a (table 0xe2433c, 12
; entries, InitializeYoko), element 0 "SqMdlyPly"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_SongMdly2SkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x196E, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdly2MeasureBox
; NakaWidget_SongMdly2MeasureBox  --  naka_direct_play +0x1994..+0x19ae (ROM 0xe22a10..0xe22a2a), 26 bytes
; Widget records of element 7 of Viewable slot 0x7a (table 0xe2433c, 12
; entries, InitializeYoko), element 0 "SqMdlyPly"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_SongMdly2MeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x1994, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdly2FileList
; NakaWidget_SongMdly2FileList  --  naka_direct_play +0x19ae..+0x19d2 (ROM 0xe22a2a..0xe22a4e), 36 bytes
; Widget records of element 8 of Viewable slot 0x7a (table 0xe2433c, 12
; entries, InitializeYoko), element 0 "SqMdlyPly"; classes:
; AcCurSongNameBox (36 B, id 0x01670005).
; -----------------------------------------------------------------------------
NakaWidget_SongMdly2FileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x19AE, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdly2MutePanel
; NakaWidget_SongMdly2MutePanel  --  naka_direct_play +0x19d2..+0x19e8 (ROM 0xe22a4e..0xe22a64), 22 bytes
; Widget records of element 9 of Viewable slot 0x7a (table 0xe2433c, 12
; entries, InitializeYoko), element 0 "SqMdlyPly"; classes:
; IvTrackSwitch (22 B, id 0x0160005b).
; -----------------------------------------------------------------------------
NakaWidget_SongMdly2MutePanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x19D2, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdly2OffOnSel
; NakaWidget_SongMdly2OffOnSel  --  naka_direct_play +0x19e8..+0x19fe (ROM 0xe22a64..0xe22a7a), 22 bytes
; Widget records of element 10 of Viewable slot 0x7a (table 0xe2433c, 12
; entries, InitializeYoko), element 0 "SqMdlyPly"; classes: IvExit (22
; B, id 0x01600047).
; -----------------------------------------------------------------------------
NakaWidget_SongMdly2OffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x19E8, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongMdly2Mixer
; NakaWidget_SongMdly2Mixer  --  naka_direct_play +0x19fe..+0x1a36 (ROM 0xe22a7a..0xe22ab2), 56 bytes
; Widget records of element 11 of Viewable slot 0x7a (table 0xe2433c, 12
; entries, InitializeYoko), element 0 "SqMdlyPly"; classes: VwMenuBox
; (50 B, id 0x0160003d).
; -----------------------------------------------------------------------------
NakaWidget_SongMdly2Mixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x19FE, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_StepRecContainer
; NakaWidget_StepRecContainer  --  naka_direct_play +0x1a36..+0x1a74 (ROM 0xe22ab2..0xe22af0), 62 bytes
; Widget records of element 0 of Viewable slot 0x89 (table 0xe24370, 5
; entries, InitializeYoko), element 0 "SqTrSel"; classes: TtlScreen (42
; B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_StepRecContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x1A36, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_StepRecPartLabel
; NakaWidget_StepRecPartLabel  --  naka_direct_play +0x1a74..+0x1aa2 (ROM 0xe22af0..0xe22b1e), 46 bytes
; Widget records of element 1 of Viewable slot 0x89 (table 0xe24370, 5
; entries, InitializeYoko), element 0 "SqTrSel"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_StepRecPartLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1A74, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_StepRecPartPanel
; NakaWidget_StepRecPartPanel  --  naka_direct_play +0x1aa2..+0x1ab8 (ROM 0xe22b1e..0xe22b34), 22 bytes
; Widget records of element 2 of Viewable slot 0x89 (table 0xe24370, 5
; entries, InitializeYoko), element 0 "SqTrSel"; classes: IvTrackSwitch
; (22 B, id 0x0160005b).
; -----------------------------------------------------------------------------
NakaWidget_StepRecPartPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AA2, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_StepRecPartList
; NakaWidget_StepRecPartList  --  naka_direct_play +0x1ab8..+0x1ae2 (ROM 0xe22b34..0xe22b5e), 42 bytes
; Widget records of element 3 of Viewable slot 0x89 (table 0xe24370, 5
; entries, InitializeYoko), element 0 "SqTrSel"; classes: AcLanguageText
; (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaWidget_StepRecPartList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AB8, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_StepRecOrchRow
; NakaWidget_StepRecOrchRow  --  naka_direct_play +0x1ae2..+0x1af8 (ROM 0xe22b5e..0xe22b74), 22 bytes
; Widget records of element 4 of Viewable slot 0x89 (table 0xe24370, 5
; entries, InitializeYoko), element 0 "SqTrSel"; classes:
; IvExitModeTrSel (22 B, id 0x01670015).
; -----------------------------------------------------------------------------
NakaWidget_StepRecOrchRow:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AE2, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_StepRecSubPanel
; NakaWidget_StepRecSubPanel  --  naka_direct_play +0x1af8..+0x1b1a (ROM 0xe22b74..0xe22b96), 34 bytes
; Widget records of element 0 of Viewable slot 0x8a (table 0xe24388, 1
; entries, InitializeYoko); classes: IvDirmdScreen (34 B, id
; 0x0160005a).
; -----------------------------------------------------------------------------
NakaWidget_StepRecSubPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AF8, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsContainer
; NakaWidget_TrAsContainer  --  naka_direct_play +0x1b1a..+0x1b54 (ROM 0xe22b96..0xe22bd0), 58 bytes
; Widget records of element 0 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: TtlScreen (42
; B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_TrAsContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x1B1A, 0x3A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetItem
; NakaWidget_TrAsPresetItem  --  naka_direct_play +0x1b54..+0x1b92 (ROM 0xe22bd0..0xe22c0e), 62 bytes
; Widget records of element 1 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: AcTitleMenu (54
; B, id 0x0160001d).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x1B54, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsFileList
; NakaWidget_TrAsFileList  --  naka_direct_play +0x1b92..+0x1bb8 (ROM 0xe22c0e..0xe22c34), 38 bytes
; Widget records of element 2 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes:
; AcCurrentSongBox (36 B, id 0x01670004).
; -----------------------------------------------------------------------------
NakaWidget_TrAsFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1B92, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsGridDisplay
; NakaWidget_TrAsGridDisplay  --  naka_direct_play +0x1bb8..+0x1c3e (ROM 0xe22c34..0xe22cba), 134 bytes
; Widget records of element 4 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: AcTrAsGridBox
; (74 B, id 0x01670006).
; -----------------------------------------------------------------------------
NakaWidget_TrAsGridDisplay:
	.incbin "includes/generated/naka_direct_play.bin", 0x1BB8, 0x86
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsTrackAssign
; NakaWidget_TrAsTrackAssign  --  naka_direct_play +0x1c3e..+0x1c76 (ROM 0xe22cba..0xe22cf2), 56 bytes
; Widget records of element 5 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: TextBox (40 B,
; id 0x01600036).
; -----------------------------------------------------------------------------
NakaWidget_TrAsTrackAssign:
	.incbin "includes/generated/naka_direct_play.bin", 0x1C3E, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsLocalCont
; NakaWidget_TrAsLocalCont  --  naka_direct_play +0x1c76..+0x1cac (ROM 0xe22cf2..0xe22d28), 54 bytes
; Widget records of element 6 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: TextBox (40 B,
; id 0x01600036).
; -----------------------------------------------------------------------------
NakaWidget_TrAsLocalCont:
	.incbin "includes/generated/naka_direct_play.bin", 0x1C76, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsMidiOut
; NakaWidget_TrAsMidiOut  --  naka_direct_play +0x1cac..+0x1ce0 (ROM 0xe22d28..0xe22d5c), 52 bytes
; Widget records of element 7 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: TextBox (40 B,
; id 0x01600036).
; -----------------------------------------------------------------------------
NakaWidget_TrAsMidiOut:
	.incbin "includes/generated/naka_direct_play.bin", 0x1CAC, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsMatrix
; NakaWidget_TrAsMatrix  --  naka_direct_play +0x1ce0..+0x1d0a (ROM 0xe22d5c..0xe22d86), 42 bytes
; Widget records of element 8 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: AcIndexWideES
; (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
NakaWidget_TrAsMatrix:
	.incbin "includes/generated/naka_direct_play.bin", 0x1CE0, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsRT1Toggle
; NakaWidget_TrAsRT1Toggle  --  naka_direct_play +0x1d0a..+0x1d32 (ROM 0xe22d86..0xe22dae), 40 bytes
; Widget records of element 10 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: AcIndexEditSw
; (40 B, id 0x0160001f).
; -----------------------------------------------------------------------------
NakaWidget_TrAsRT1Toggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x1D0A, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsRT2Toggle
; NakaWidget_TrAsRT2Toggle  --  naka_direct_play +0x1d32..+0x1d5a (ROM 0xe22dae..0xe22dd6), 40 bytes
; Widget records of element 11 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: AcIndexEditSw
; (40 B, id 0x0160001f).
; -----------------------------------------------------------------------------
NakaWidget_TrAsRT2Toggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x1D32, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsMeasureBox
; NakaWidget_TrAsMeasureBox  --  naka_direct_play +0x1d5a..+0x1d74 (ROM 0xe22dd6..0xe22df0), 26 bytes
; Widget records of element 12 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_TrAsMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x1D5A, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsSubContainer
; NakaWidget_TrAsSubContainer  --  naka_direct_play +0x1d74..+0x1dac (ROM 0xe22df0..0xe22e28), 56 bytes
; Widget records of element 13 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: TtlScreen (42
; B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_TrAsSubContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x1D74, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsGroup
; NakaWidget_TrAsGroup  --  naka_direct_play +0x1dac..+0x1dc6 (ROM 0xe22e28..0xe22e42), 26 bytes
; Widget records of element 14 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: Box (26 B, id
; 0x01600031).
; -----------------------------------------------------------------------------
NakaWidget_TrAsGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x1DAC, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPartList0
; NakaWidget_TrAsPartList0  --  naka_direct_play +0x1dc6..+0x1df0 (ROM 0xe22e42..0xe22e6c), 42 bytes
; Widget records of element 15 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: AcLanguageText
; (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPartList0:
	.incbin "includes/generated/naka_direct_play.bin", 0x1DC6, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPartList1
; NakaWidget_TrAsPartList1  --  naka_direct_play +0x1df0..+0x1e1a (ROM 0xe22e6c..0xe22e96), 42 bytes
; Widget records of element 16 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: AcLanguageText
; (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPartList1:
	.incbin "includes/generated/naka_direct_play.bin", 0x1DF0, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPartList2
; NakaWidget_TrAsPartList2  --  naka_direct_play +0x1e1a..+0x1e44 (ROM 0xe22e96..0xe22ec0), 42 bytes
; Widget records of element 17 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: AcLanguageText
; (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPartList2:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E1A, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsMeasureBox2
; NakaWidget_TrAsMeasureBox2  --  naka_direct_play +0x1e44..+0x1e5e (ROM 0xe22ec0..0xe22eda), 26 bytes
; Widget records of element 18 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_TrAsMeasureBox2:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E44, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsRT1Selector
; NakaWidget_TrAsRT1Selector  --  naka_direct_play +0x1e5e..+0x1e8c (ROM 0xe22eda..0xe22f08), 46 bytes
; Widget records of element 19 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: VwEditSwBox (44
; B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_TrAsRT1Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E5E, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsRT2Selector
; NakaWidget_TrAsRT2Selector  --  naka_direct_play +0x1e8c..+0x1eba (ROM 0xe22f08..0xe22f36), 46 bytes
; Widget records of element 20 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: VwEditSwBox (44
; B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_TrAsRT2Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E8C, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetSel
; NakaWidget_TrAsPresetSel  --  naka_direct_play +0x1eba..+0x1ed4 (ROM 0xe22f36..0xe22f50), 26 bytes
; Widget records of element 21 of Viewable slot 0x8b (table 0xe24390, 22
; entries, InitializeYoko), element 0 "SqTrAs"; classes: IvExitScreen
; (26 B, id 0x01600049).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1EBA, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_direct_play+0x1ed4
; naka_direct_play+0x1ed4  --  naka_direct_play +0x1ed4..+0x1f12 (ROM 0xe22f50..0xe22f8e), 62 bytes
; Widget records of element 0 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: TtlScreen (42
; B, id 0x01600034).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_direct_play.bin", 0x1ED4, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetSong
; NakaWidget_TrAsPresetSong  --  naka_direct_play +0x1f12..+0x1f38 (ROM 0xe22f8e..0xe22fb4), 38 bytes
; Widget records of element 1 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetSong:
	.incbin "includes/generated/naka_direct_play.bin", 0x1F12, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetMatrix
; NakaWidget_TrAsPresetMatrix  --  naka_direct_play +0x1f38..+0x1f62 (ROM 0xe22fb4..0xe22fde), 42 bytes
; Widget records of element 2 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: AcIndexWideES
; (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetMatrix:
	.incbin "includes/generated/naka_direct_play.bin", 0x1F38, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetPanel
; NakaWidget_TrAsPresetPanel  --  naka_direct_play +0x1f62..+0x1fa6 (ROM 0xe22fde..0xe23022), 68 bytes
; Widget records of element 3 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: AcRamEditBox
; (58 B, id 0x0160001b).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1F62, 0x44
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetInit
; NakaWidget_TrAsPresetInit  --  naka_direct_play +0x1fa6..+0x1fe2 (ROM 0xe23022..0xe2305e), 60 bytes
; Widget records of element 4 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: AcModeSelBox
; (52 B, id 0x01670002).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetInit:
	.incbin "includes/generated/naka_direct_play.bin", 0x1FA6, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetGmRec
; NakaWidget_TrAsPresetGmRec  --  naka_direct_play +0x1fe2..+0x2030 (ROM 0xe2305e..0xe230ac), 78 bytes
; Widget records of element 5 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: AcModeSelBox
; (52 B, id 0x01670002).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetGmRec:
	.incbin "includes/generated/naka_direct_play.bin", 0x1FE2, 0x4E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetMeasure
; NakaWidget_TrAsPresetMeasure  --  naka_direct_play +0x2030..+0x2078 (ROM 0xe230ac..0xe230f4), 72 bytes
; Widget records of element 6 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: AcModeSelBox
; (52 B, id 0x01670002).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0x2030, 0x48
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetRT2Sel
; NakaWidget_TrAsPresetRT2Sel  --  naka_direct_play +0x2078..+0x2092 (ROM 0xe230f4..0xe2310e), 26 bytes
; Widget records of element 7 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetRT2Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2078, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetList
; NakaWidget_TrAsPresetList  --  naka_direct_play +0x2092..+0x20c0 (ROM 0xe2310e..0xe2313c), 46 bytes
; Widget records of element 8 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetList:
	.incbin "includes/generated/naka_direct_play.bin", 0x2092, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetGroup
; NakaWidget_TrAsPresetGroup  --  naka_direct_play +0x20c0..+0x20ea (ROM 0xe2313c..0xe23166), 42 bytes
; Widget records of element 9 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x20C0, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetContainer
; NakaWidget_TrAsPresetContainer  --  naka_direct_play +0x20ea..+0x2128 (ROM 0xe23166..0xe231a4), 62 bytes
; Widget records of element 10 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: TtlScreen (42
; B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x20EA, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetMeasure2
; NakaWidget_TrAsPresetMeasure2  --  naka_direct_play +0x2128..+0x2142 (ROM 0xe231a4..0xe231be), 26 bytes
; Widget records of element 11 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetMeasure2:
	.incbin "includes/generated/naka_direct_play.bin", 0x2128, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetRT1Sel
; NakaWidget_TrAsPresetRT1Sel  --  naka_direct_play +0x2142..+0x2170 (ROM 0xe231be..0xe231ec), 46 bytes
; Widget records of element 12 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetRT1Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2142, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetRT2Sel2
; NakaWidget_TrAsPresetRT2Sel2  --  naka_direct_play +0x2170..+0x219e (ROM 0xe231ec..0xe2321a), 46 bytes
; Widget records of element 13 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetRT2Sel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x2170, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetGroup2
; NakaWidget_TrAsPresetGroup2  --  naka_direct_play +0x219e..+0x21b8 (ROM 0xe2321a..0xe23234), 26 bytes
; Widget records of element 14 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: Box (26 B, id
; 0x01600031).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetGroup2:
	.incbin "includes/generated/naka_direct_play.bin", 0x219E, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetTypeSel
; NakaWidget_TrAsPresetTypeSel  --  naka_direct_play +0x21b8..+0x21d2 (ROM 0xe23234..0xe2324e), 26 bytes
; Widget records of element 15 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: IvExitScreen
; (26 B, id 0x01600049).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetTypeSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x21B8, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetList2
; NakaWidget_TrAsPresetList2  --  naka_direct_play +0x21d2..+0x21fc (ROM 0xe2324e..0xe23278), 42 bytes
; Widget records of element 16 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetList2:
	.incbin "includes/generated/naka_direct_play.bin", 0x21D2, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetList3
; NakaWidget_TrAsPresetList3  --  naka_direct_play +0x21fc..+0x2226 (ROM 0xe23278..0xe232a2), 42 bytes
; Widget records of element 17 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetList3:
	.incbin "includes/generated/naka_direct_play.bin", 0x21FC, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetList4
; NakaWidget_TrAsPresetList4  --  naka_direct_play +0x2226..+0x2250 (ROM 0xe232a2..0xe232cc), 42 bytes
; Widget records of element 18 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetList4:
	.incbin "includes/generated/naka_direct_play.bin", 0x2226, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetContainer2
; NakaWidget_TrAsPresetContainer2  --  naka_direct_play +0x2250..+0x228e (ROM 0xe232cc..0xe2330a), 62 bytes
; Widget records of element 19 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: TtlScreen (42
; B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetContainer2:
	.incbin "includes/generated/naka_direct_play.bin", 0x2250, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetGroup3
; NakaWidget_TrAsPresetGroup3  --  naka_direct_play +0x228e..+0x22a8 (ROM 0xe2330a..0xe23324), 26 bytes
; Widget records of element 20 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: Box (26 B, id
; 0x01600031).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetGroup3:
	.incbin "includes/generated/naka_direct_play.bin", 0x228E, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetTypeSel2
; NakaWidget_TrAsPresetTypeSel2  --  naka_direct_play +0x22a8..+0x22c2 (ROM 0xe23324..0xe2333e), 26 bytes
; Widget records of element 21 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: IvExitScreen
; (26 B, id 0x01600049).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetTypeSel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x22A8, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetList5
; NakaWidget_TrAsPresetList5  --  naka_direct_play +0x22c2..+0x22ec (ROM 0xe2333e..0xe23368), 42 bytes
; Widget records of element 22 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetList5:
	.incbin "includes/generated/naka_direct_play.bin", 0x22C2, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetList6
; NakaWidget_TrAsPresetList6  --  naka_direct_play +0x22ec..+0x2316 (ROM 0xe23368..0xe23392), 42 bytes
; Widget records of element 23 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetList6:
	.incbin "includes/generated/naka_direct_play.bin", 0x22EC, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetList7
; NakaWidget_TrAsPresetList7  --  naka_direct_play +0x2316..+0x2340 (ROM 0xe23392..0xe233bc), 42 bytes
; Widget records of element 24 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetList7:
	.incbin "includes/generated/naka_direct_play.bin", 0x2316, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetMeasure3
; NakaWidget_TrAsPresetMeasure3  --  naka_direct_play +0x2340..+0x235a (ROM 0xe233bc..0xe233d6), 26 bytes
; Widget records of element 25 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetMeasure3:
	.incbin "includes/generated/naka_direct_play.bin", 0x2340, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetRT1Sel2
; NakaWidget_TrAsPresetRT1Sel2  --  naka_direct_play +0x235a..+0x2388 (ROM 0xe233d6..0xe23404), 46 bytes
; Widget records of element 26 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetRT1Sel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x235A, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_TrAsPresetRT2Sel3
; NakaWidget_TrAsPresetRT2Sel3  --  naka_direct_play +0x2388..+0x23b6 (ROM 0xe23404..0xe23432), 46 bytes
; Widget records of element 27 of Viewable slot 0x8c (table 0xe243ec, 28
; entries, InitializeYoko), element 0 "SqTrAsPs"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
NakaWidget_TrAsPresetRT2Sel3:
	.incbin "includes/generated/naka_direct_play.bin", 0x2388, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongSelNamContainer
; NakaWidget_SongSelNamContainer  --  naka_direct_play +0x23b6..+0x23f4 (ROM 0xe23432..0xe23470), 62 bytes
; Widget records of element 0 of Viewable slot 0x8e (table 0xe24460, 5
; entries, InitializeYoko), element 0 "SqSngSel"; classes: TtlScreen (42
; B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_SongSelNamContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x23B6, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongSelNamNameItem
; NakaWidget_SongSelNamNameItem  --  naka_direct_play +0x23f4..+0x2432 (ROM 0xe23470..0xe234ae), 62 bytes
; Widget records of element 1 of Viewable slot 0x8e (table 0xe24460, 5
; entries, InitializeYoko), element 0 "SqSngSel"; classes: AcTitleMenu
; (54 B, id 0x0160001d).
; -----------------------------------------------------------------------------
NakaWidget_SongSelNamNameItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x23F4, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongSelNamSongSel
; NakaWidget_SongSelNamSongSel  --  naka_direct_play +0x2432..+0x2464 (ROM 0xe234ae..0xe234e0), 50 bytes
; Widget records of element 2 of Viewable slot 0x8e (table 0xe24460, 5
; entries, InitializeYoko), element 0 "SqSngSel"; classes: PsSongSelBox
; (50 B, id 0x01670001).
; -----------------------------------------------------------------------------
NakaWidget_SongSelNamSongSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2432, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongSelNamNameEdit
; NakaWidget_SongSelNamNameEdit  --  naka_direct_play +0x2464..+0x2496 (ROM 0xe234e0..0xe23512), 50 bytes
; Widget records of element 3 of Viewable slot 0x8e (table 0xe24460, 5
; entries, InitializeYoko), element 0 "SqSngSel"; classes: PsSongSelBox
; (50 B, id 0x01670001).
; -----------------------------------------------------------------------------
NakaWidget_SongSelNamNameEdit:
	.incbin "includes/generated/naka_direct_play.bin", 0x2464, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SongSelNamDuration
; NakaWidget_SongSelNamDuration  --  naka_direct_play +0x2496..+0x24c0 (ROM 0xe23512..0xe2353c), 42 bytes
; Widget records of element 4 of Viewable slot 0x8e (table 0xe24460, 5
; entries, InitializeYoko), element 0 "SqSngSel"; classes: AcIndexWideES
; (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
NakaWidget_SongSelNamDuration:
	.incbin "includes/generated/naka_direct_play.bin", 0x2496, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_NamingContainer
; NakaWidget_NamingContainer  --  naka_direct_play +0x24c0..+0x24f2 (ROM 0xe2353c..0xe2356e), 50 bytes
; Widget records of element 0 of Viewable slot 0x8f (table 0xe24478, 6
; entries, InitializeYoko), element 0 "SqNameing"; classes: TtlScreen
; (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_NamingContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x24C0, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_NamingCharSel
; NakaWidget_NamingCharSel  --  naka_direct_play +0x24f2..+0x2516 (ROM 0xe2356e..0xe23592), 36 bytes
; Widget records of element 1 of Viewable slot 0x8f (table 0xe24478, 6
; entries, InitializeYoko), element 0 "SqNameing"; classes:
; AcCurrentSongBox (36 B, id 0x01670004).
; -----------------------------------------------------------------------------
NakaWidget_NamingCharSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x24F2, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_NamingSeqLabel
; NakaWidget_NamingSeqLabel  --  naka_direct_play +0x2516..+0x2548 (ROM 0xe23592..0xe235c4), 50 bytes
; Widget records of element 2 of Viewable slot 0x8f (table 0xe24478, 6
; entries, InitializeYoko), element 0 "SqNameing"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaWidget_NamingSeqLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2516, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_NamingMeasureBox
; NakaWidget_NamingMeasureBox  --  naka_direct_play +0x2548..+0x2562 (ROM 0xe235c4..0xe235de), 26 bytes
; Widget records of element 3 of Viewable slot 0x8f (table 0xe24478, 6
; entries, InitializeYoko), element 0 "SqNameing"; classes: IvNaming (26
; B, id 0x0160004d).
; -----------------------------------------------------------------------------
NakaWidget_NamingMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x2548, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_NamingDisplayMode
; NakaWidget_NamingDisplayMode  --  naka_direct_play +0x2562..+0x258e (ROM 0xe235de..0xe2360a), 44 bytes
; Widget records of element 4 of Viewable slot 0x8f (table 0xe24478, 6
; entries, InitializeYoko), element 0 "SqNameing"; classes: AcFuncEditSw
; (44 B, id 0x01600020).
; -----------------------------------------------------------------------------
NakaWidget_NamingDisplayMode:
	.incbin "includes/generated/naka_direct_play.bin", 0x2562, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_NamingOrchRow
; NakaWidget_NamingOrchRow  --  naka_direct_play +0x258e..+0x25a4 (ROM 0xe2360a..0xe23620), 22 bytes
; Widget records of element 5 of Viewable slot 0x8f (table 0xe24478, 6
; entries, InitializeYoko), element 0 "SqNameing"; classes: IvNamingExit
; (22 B, id 0x01670000).
; -----------------------------------------------------------------------------
NakaWidget_NamingOrchRow:
	.incbin "includes/generated/naka_direct_play.bin", 0x258E, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_direct_play+0x25a4
; naka_direct_play+0x25a4  --  naka_direct_play +0x25a4..+0x25e2 (ROM 0xe23620..0xe2365e), 62 bytes
; Widget records of element 0 of Viewable slot 0x92 (table 0xe24494, 4
; entries, InitializeYoko), element 0 "AfterTouchSet"; classes:
; TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_direct_play.bin", 0x25A4, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_AftTouchDuration
; NakaWidget_AftTouchDuration  --  naka_direct_play +0x25e2..+0x260c (ROM 0xe2365e..0xe23688), 42 bytes
; Widget records of element 1 of Viewable slot 0x92 (table 0xe24494, 4
; entries, InitializeYoko), element 0 "AfterTouchSet"; classes:
; AcIndexWideES (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
NakaWidget_AftTouchDuration:
	.incbin "includes/generated/naka_direct_play.bin", 0x25E2, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_AftTouchChSel
; NakaWidget_AftTouchChSel  --  naka_direct_play +0x260c..+0x265e (ROM 0xe23688..0xe236da), 82 bytes
; Widget records of element 2 of Viewable slot 0x92 (table 0xe24494, 4
; entries, InitializeYoko), element 0 "AfterTouchSet"; classes:
; AcBitEditBox (58 B, id 0x01600043).
; -----------------------------------------------------------------------------
NakaWidget_AftTouchChSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x260C, 0x52
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_AftTouchList
; NakaWidget_AftTouchList  --  naka_direct_play +0x265e..+0x2688 (ROM 0xe236da..0xe23704), 42 bytes
; Widget records of element 3 of Viewable slot 0x92 (table 0xe24494, 4
; entries, InitializeYoko), element 0 "AfterTouchSet"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaWidget_AftTouchList:
	.incbin "includes/generated/naka_direct_play.bin", 0x265E, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_direct_play+0x2688
; naka_direct_play+0x2688  --  naka_direct_play +0x2688..+0x26c0 (ROM 0xe23704..0xe2373c), 56 bytes
; Widget records of element 0 of Viewable slot 0xa9 (table 0xe244ac, 6
; entries, InitializeYoko), element 0 "StepPartBal"; classes: TtlScreen
; (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_direct_play.bin", 0x2688, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PartBal0
; NakaWidget_PartBal0  --  naka_direct_play +0x26c0..+0x26e0 (ROM 0xe2373c..0xe2375c), 32 bytes
; Widget records of element 1 of Viewable slot 0xa9 (table 0xe244ac, 6
; entries, InitializeYoko), element 0 "StepPartBal"; classes: AcMixerVol
; (32 B, id 0x0160003c).
; -----------------------------------------------------------------------------
NakaWidget_PartBal0:
	.incbin "includes/generated/naka_direct_play.bin", 0x26C0, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PartBal1
; NakaWidget_PartBal1  --  naka_direct_play +0x26e0..+0x2700 (ROM 0xe2375c..0xe2377c), 32 bytes
; Widget records of element 2 of Viewable slot 0xa9 (table 0xe244ac, 6
; entries, InitializeYoko), element 0 "StepPartBal"; classes: AcMixerVol
; (32 B, id 0x0160003c).
; -----------------------------------------------------------------------------
NakaWidget_PartBal1:
	.incbin "includes/generated/naka_direct_play.bin", 0x26E0, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PartBal2
; NakaWidget_PartBal2  --  naka_direct_play +0x2700..+0x2720 (ROM 0xe2377c..0xe2379c), 32 bytes
; Widget records of element 3 of Viewable slot 0xa9 (table 0xe244ac, 6
; entries, InitializeYoko), element 0 "StepPartBal"; classes: AcMixerVol
; (32 B, id 0x0160003c).
; -----------------------------------------------------------------------------
NakaWidget_PartBal2:
	.incbin "includes/generated/naka_direct_play.bin", 0x2700, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PartBal3
; NakaWidget_PartBal3  --  naka_direct_play +0x2720..+0x2740 (ROM 0xe2379c..0xe237bc), 32 bytes
; Widget records of element 4 of Viewable slot 0xa9 (table 0xe244ac, 6
; entries, InitializeYoko), element 0 "StepPartBal"; classes: AcMixerVol
; (32 B, id 0x0160003c).
; -----------------------------------------------------------------------------
NakaWidget_PartBal3:
	.incbin "includes/generated/naka_direct_play.bin", 0x2720, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PartBal4
; NakaWidget_PartBal4  --  naka_direct_play +0x2740..+0x2760 (ROM 0xe237bc..0xe237dc), 32 bytes
; Widget records of element 5 of Viewable slot 0xa9 (table 0xe244ac, 6
; entries, InitializeYoko), element 0 "StepPartBal"; classes: AcMixerVol
; (32 B, id 0x0160003c).
; -----------------------------------------------------------------------------
NakaWidget_PartBal4:
	.incbin "includes/generated/naka_direct_play.bin", 0x2740, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DemoContainer
; NakaWidget_DemoContainer  --  naka_direct_play +0x2760..+0x2798 (ROM 0xe237dc..0xe23814), 56 bytes
; Widget records of element 0 of Viewable slot 0xe0 (table 0xe244c8, 4
; entries, InitializeYoko), element 0 "DemoMenu"; classes: TtlScreen (42
; B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_DemoContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x2760, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DemoPerfItem
; NakaWidget_DemoPerfItem  --  naka_direct_play +0x2798..+0x27dc (ROM 0xe23814..0xe23858), 68 bytes
; Widget records of element 1 of Viewable slot 0xe0 (table 0xe244c8, 4
; entries, InitializeYoko), element 0 "DemoMenu"; classes: AcTitleMenu
; (54 B, id 0x0160001d).
; -----------------------------------------------------------------------------
NakaWidget_DemoPerfItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x2798, 0x44
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DemoFeatPresItem
; NakaWidget_DemoFeatPresItem  --  naka_direct_play +0x27dc..+0x2828 (ROM 0xe23858..0xe238a4), 76 bytes
; Widget records of element 2 of Viewable slot 0xe0 (table 0xe244c8, 4
; entries, InitializeYoko), element 0 "DemoMenu"; classes: AcTitleMenu
; (54 B, id 0x0160001d).
; -----------------------------------------------------------------------------
NakaWidget_DemoFeatPresItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x27DC, 0x4C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_DemoMeasureBox
; NakaWidget_DemoMeasureBox  --  naka_direct_play +0x2828..+0x2842 (ROM 0xe238a4..0xe238be), 26 bytes
; Widget records of element 3 of Viewable slot 0xe0 (table 0xe244c8, 4
; entries, InitializeYoko), element 0 "DemoMenu"; classes: IvExitMode
; (26 B, id 0x01600048).
; -----------------------------------------------------------------------------
NakaWidget_DemoMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x2828, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_direct_play+0x2842
; naka_direct_play+0x2842  --  naka_direct_play +0x2842..+0x287a (ROM 0xe238be..0xe238f6), 56 bytes
; Widget records of element 0 of Viewable slot 0xe1 (table 0xe244dc, 12
; entries, InitializeYoko), element 0 "DemoStyle"; classes: TtlScreen
; (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_direct_play.bin", 0x2842, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PerfMainMedley
; NakaWidget_PerfMainMedley  --  naka_direct_play +0x287a..+0x28bc (ROM 0xe238f6..0xe23938), 66 bytes
; Widget records of element 1 of Viewable slot 0xe1 (table 0xe244dc, 12
; entries, InitializeYoko), element 0 "DemoStyle"; classes:
; AcDemoSongBox (54 B, id 0x01670003).
; -----------------------------------------------------------------------------
NakaWidget_PerfMainMedley:
	.incbin "includes/generated/naka_direct_play.bin", 0x287A, 0x42
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PerfAccordionMedley
; NakaWidget_PerfAccordionMedley  --  naka_direct_play +0x28bc..+0x2904 (ROM 0xe23938..0xe23980), 72 bytes
; Widget records of element 2 of Viewable slot 0xe1 (table 0xe244dc, 12
; entries, InitializeYoko), element 0 "DemoStyle"; classes:
; AcDemoSongBox (54 B, id 0x01670003).
; -----------------------------------------------------------------------------
NakaWidget_PerfAccordionMedley:
	.incbin "includes/generated/naka_direct_play.bin", 0x28BC, 0x48
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PerfFolkMedley
; NakaWidget_PerfFolkMedley  --  naka_direct_play +0x2904..+0x2946 (ROM 0xe23980..0xe239c2), 66 bytes
; Widget records of element 3 of Viewable slot 0xe1 (table 0xe244dc, 12
; entries, InitializeYoko), element 0 "DemoStyle"; classes:
; AcDemoSongBox (54 B, id 0x01670003).
; -----------------------------------------------------------------------------
NakaWidget_PerfFolkMedley:
	.incbin "includes/generated/naka_direct_play.bin", 0x2904, 0x42
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PerfClassical
; NakaWidget_PerfClassical  --  naka_direct_play +0x2946..+0x2986 (ROM 0xe239c2..0xe23a02), 64 bytes
; Widget records of element 4 of Viewable slot 0xe1 (table 0xe244dc, 12
; entries, InitializeYoko), element 0 "DemoStyle"; classes:
; AcDemoSongBox (54 B, id 0x01670003).
; -----------------------------------------------------------------------------
NakaWidget_PerfClassical:
	.incbin "includes/generated/naka_direct_play.bin", 0x2946, 0x40
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PerfShow
; NakaWidget_PerfShow  --  naka_direct_play +0x2986..+0x29c2 (ROM 0xe23a02..0xe23a3e), 60 bytes
; Widget records of element 5 of Viewable slot 0xe1 (table 0xe244dc, 12
; entries, InitializeYoko), element 0 "DemoStyle"; classes:
; AcDemoSongBox (54 B, id 0x01670003).
; -----------------------------------------------------------------------------
NakaWidget_PerfShow:
	.incbin "includes/generated/naka_direct_play.bin", 0x2986, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PerfContemporary
; NakaWidget_PerfContemporary  --  naka_direct_play +0x29c2..+0x2a06 (ROM 0xe23a3e..0xe23a82), 68 bytes
; Widget records of element 6 of Viewable slot 0xe1 (table 0xe244dc, 12
; entries, InitializeYoko), element 0 "DemoStyle"; classes:
; AcDemoSongBox (54 B, id 0x01670003).
; -----------------------------------------------------------------------------
NakaWidget_PerfContemporary:
	.incbin "includes/generated/naka_direct_play.bin", 0x29C2, 0x44
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PerfStyleSel
; NakaWidget_PerfStyleSel  --  naka_direct_play +0x2a06..+0x2a3c (ROM 0xe23a82..0xe23ab8), 54 bytes
; Widget records of element 7 of Viewable slot 0xe1 (table 0xe244dc, 12
; entries, InitializeYoko), element 0 "DemoStyle"; classes: PsWideToggle
; (42 B, id 0x01600045).
; -----------------------------------------------------------------------------
NakaWidget_PerfStyleSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2A06, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PerfSoundSel
; NakaWidget_PerfSoundSel  --  naka_direct_play +0x2a3c..+0x2a72 (ROM 0xe23ab8..0xe23aee), 54 bytes
; Widget records of element 8 of Viewable slot 0xe1 (table 0xe244dc, 12
; entries, InitializeYoko), element 0 "DemoStyle"; classes: PsWideToggle
; (42 B, id 0x01600045).
; -----------------------------------------------------------------------------
NakaWidget_PerfSoundSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2A3C, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PerfRhythmSel
; NakaWidget_PerfRhythmSel  --  naka_direct_play +0x2a72..+0x2aac (ROM 0xe23aee..0xe23b28), 58 bytes
; Widget records of element 9 of Viewable slot 0xe1 (table 0xe244dc, 12
; entries, InitializeYoko), element 0 "DemoStyle"; classes: PsWideToggle
; (42 B, id 0x01600045).
; -----------------------------------------------------------------------------
NakaWidget_PerfRhythmSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2A72, 0x3A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PerfMeasureBox
; NakaWidget_PerfMeasureBox  --  naka_direct_play +0x2aac..+0x2ac6 (ROM 0xe23b28..0xe23b42), 26 bytes
; Widget records of element 10 of Viewable slot 0xe1 (table 0xe244dc, 12
; entries, InitializeYoko), element 0 "DemoStyle"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_PerfMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x2AAC, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_PerfFileList
; NakaWidget_PerfFileList  --  naka_direct_play +0x2ac6..+0x2aea (ROM 0xe23b42..0xe23b66), 36 bytes
; Widget records of element 11 of Viewable slot 0xe1 (table 0xe244dc, 12
; entries, InitializeYoko), element 0 "DemoStyle"; classes:
; AcDemoMedleyDispBox (36 B, id 0x01670014).
; -----------------------------------------------------------------------------
NakaWidget_PerfFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x2AC6, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf2Container
; NakaWidget_Perf2Container  --  naka_direct_play +0x2aea..+0x2b22 (ROM 0xe23b66..0xe23b9e), 56 bytes
; Widget records of element 0 of Viewable slot 0xe2 (table 0xe24510, 12
; entries, InitializeYoko), element 0 "DemoSound"; classes: TtlScreen
; (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaWidget_Perf2Container:
	.incbin "includes/generated/naka_direct_play.bin", 0x2AEA, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf2Strings
; NakaWidget_Perf2Strings  --  naka_direct_play +0x2b22..+0x2b60 (ROM 0xe23b9e..0xe23bdc), 62 bytes
; Widget records of element 1 of Viewable slot 0xe2 (table 0xe24510, 12
; entries, InitializeYoko), element 0 "DemoSound"; classes:
; AcDemoSongBox (54 B, id 0x01670003).
; -----------------------------------------------------------------------------
NakaWidget_Perf2Strings:
	.incbin "includes/generated/naka_direct_play.bin", 0x2B22, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf2Gamelan
; NakaWidget_Perf2Gamelan  --  naka_direct_play +0x2b60..+0x2bdc (ROM 0xe23bdc..0xe23c58), 124 bytes
; Widget records of elements 2-3 of Viewable slot 0xe2 (table 0xe24510,
; 12 entries, InitializeYoko), element 0 "DemoSound"; classes:
; AcDemoSongBox (54 B, id 0x01670003) x2.
; -----------------------------------------------------------------------------
NakaWidget_Perf2Gamelan:
	.incbin "includes/generated/naka_direct_play.bin", 0x2B60, 0x7C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf2Guitar
; NakaWidget_Perf2Guitar  --  naka_direct_play +0x2bdc..+0x2c18 (ROM 0xe23c58..0xe23c94), 60 bytes
; Widget records of element 4 of Viewable slot 0xe2 (table 0xe24510, 12
; entries, InitializeYoko), element 0 "DemoSound"; classes:
; AcDemoSongBox (54 B, id 0x01670003).
; -----------------------------------------------------------------------------
NakaWidget_Perf2Guitar:
	.incbin "includes/generated/naka_direct_play.bin", 0x2BDC, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf2SaxBrass
; NakaWidget_Perf2SaxBrass  --  naka_direct_play +0x2c18..+0x2c94 (ROM 0xe23c94..0xe23d10), 124 bytes
; Widget records of elements 5-6 of Viewable slot 0xe2 (table 0xe24510,
; 12 entries, InitializeYoko), element 0 "DemoSound"; classes:
; AcDemoSongBox (54 B, id 0x01670003) x2.
; -----------------------------------------------------------------------------
NakaWidget_Perf2SaxBrass:
	.incbin "includes/generated/naka_direct_play.bin", 0x2C18, 0x7C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf2StyleSel
; NakaWidget_Perf2StyleSel  --  naka_direct_play +0x2c94..+0x2cca (ROM 0xe23d10..0xe23d46), 54 bytes
; Widget records of element 7 of Viewable slot 0xe2 (table 0xe24510, 12
; entries, InitializeYoko), element 0 "DemoSound"; classes: PsWideToggle
; (42 B, id 0x01600045).
; -----------------------------------------------------------------------------
NakaWidget_Perf2StyleSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2C94, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf2SoundSel
; NakaWidget_Perf2SoundSel  --  naka_direct_play +0x2cca..+0x2d00 (ROM 0xe23d46..0xe23d7c), 54 bytes
; Widget records of element 8 of Viewable slot 0xe2 (table 0xe24510, 12
; entries, InitializeYoko), element 0 "DemoSound"; classes: PsWideToggle
; (42 B, id 0x01600045).
; -----------------------------------------------------------------------------
NakaWidget_Perf2SoundSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2CCA, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf2RhythmSel
; NakaWidget_Perf2RhythmSel  --  naka_direct_play +0x2d00..+0x2d3a (ROM 0xe23d7c..0xe23db6), 58 bytes
; Widget records of element 9 of Viewable slot 0xe2 (table 0xe24510, 12
; entries, InitializeYoko), element 0 "DemoSound"; classes: PsWideToggle
; (42 B, id 0x01600045).
; -----------------------------------------------------------------------------
NakaWidget_Perf2RhythmSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2D00, 0x3A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf2MeasureBox
; NakaWidget_Perf2MeasureBox  --  naka_direct_play +0x2d3a..+0x2d54 (ROM 0xe23db6..0xe23dd0), 26 bytes
; Widget records of element 10 of Viewable slot 0xe2 (table 0xe24510, 12
; entries, InitializeYoko), element 0 "DemoSound"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
NakaWidget_Perf2MeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x2D3A, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf2FileList
; NakaWidget_Perf2FileList  --  naka_direct_play +0x2d54..+0x2d78 (ROM 0xe23dd0..0xe23df4), 36 bytes
; Widget records of element 11 of Viewable slot 0xe2 (table 0xe24510, 12
; entries, InitializeYoko), element 0 "DemoSound"; classes:
; AcDemoMedleyDispBox (36 B, id 0x01670014).
; -----------------------------------------------------------------------------
NakaWidget_Perf2FileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x2D54, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_direct_play+0x2d78
; naka_direct_play+0x2d78  --  naka_direct_play +0x2d78..+0x2db0 (ROM 0xe23df4..0xe23e2c), 56 bytes
; Widget records of element 0 of Viewable slot 0xe3 (table 0xe24544, 12
; entries, InitializeYoko), element 0 "DemoRhy"; classes: TtlScreen (42
; B, id 0x01600034).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_direct_play.bin", 0x2D78, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf3HokieDance
; NakaWidget_Perf3HokieDance  --  naka_direct_play +0x2db0..+0x2f04 (ROM 0xe23e2c..0xe23f80), 340 bytes
; Widget records of elements 1-5 of Viewable slot 0xe3 (table 0xe24544,
; 12 entries, InitializeYoko), element 0 "DemoRhy"; classes:
; AcDemoSongBox (54 B, id 0x01670003) x5.
; -----------------------------------------------------------------------------
NakaWidget_Perf3HokieDance:
	.incbin "includes/generated/naka_direct_play.bin", 0x2DB0, 0x154
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf3ModernBluegrass
; NakaWidget_Perf3ModernBluegrass  --  naka_direct_play +0x2f04..+0x2f4c (ROM 0xe23f80..0xe23fc8), 72 bytes
; Widget records of element 6 of Viewable slot 0xe3 (table 0xe24544, 12
; entries, InitializeYoko), element 0 "DemoRhy"; classes: AcDemoSongBox
; (54 B, id 0x01670003).
; -----------------------------------------------------------------------------
NakaWidget_Perf3ModernBluegrass:
	.incbin "includes/generated/naka_direct_play.bin", 0x2F04, 0x48
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf3StyleSel
; NakaWidget_Perf3StyleSel  --  naka_direct_play +0x2f4c..+0x2f82 (ROM 0xe23fc8..0xe23ffe), 54 bytes
; Widget records of element 7 of Viewable slot 0xe3 (table 0xe24544, 12
; entries, InitializeYoko), element 0 "DemoRhy"; classes: PsWideToggle
; (42 B, id 0x01600045).
; -----------------------------------------------------------------------------
NakaWidget_Perf3StyleSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2F4C, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf3SoundSel
; NakaWidget_Perf3SoundSel  --  naka_direct_play +0x2f82..+0x2fb8 (ROM 0xe23ffe..0xe24034), 54 bytes
; Widget records of element 8 of Viewable slot 0xe3 (table 0xe24544, 12
; entries, InitializeYoko), element 0 "DemoRhy"; classes: PsWideToggle
; (42 B, id 0x01600045).
; -----------------------------------------------------------------------------
NakaWidget_Perf3SoundSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2F82, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_Perf3RhythmSel
; NakaWidget_Perf3RhythmSel  --  naka_direct_play +0x2fb8..+0x2fda (ROM 0xe24034..0xe24056), 34 bytes
; Widget records of element 9 of Viewable slot 0xe3 (table 0xe24544, 12
; entries, InitializeYoko), element 0 "DemoRhy"; classes: PsWideToggle
; (42 B, id 0x01600045).
; -----------------------------------------------------------------------------
NakaWidget_Perf3RhythmSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2FB8, 0x22
; External label offsets within the binary blob above.
