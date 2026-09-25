
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
; already existed. A widget record begins with the Viewable fields (the
; firmware's own names): +0 class (class id), +4 super, +6 sub, +8 next,
; +10 prev (element indices of the same table, 0xffff = none -- parent,
; first child, next and previous sibling, checked against each other for
; every table: the Links result per table), +12 flag, +14 rect (x1, y1,
; x2, y2). Name strings are NUL-terminated and 0xff-padded to even
; length. Strings a record's `X` field (str, title, caption, name)
; points at are indexed too, so the bytes after a record are accounted
; for (in v10, 4 of the 3,340 records are followed by bytes nothing
; indexed starts at). The first word of a widget record is its CLASS ID
; 0x016S_KKKK: ClassProc (ui/ui_widget_defs.s) takes (id >> 16) & 0xfff
; as a registry slot -- the Class table that RegObjTable 0x1600004 put
; there -- and 0x18 * (id & 0xffff) into it. Each class definition gives
; the instance size (+8 allsize), and all 3,340 in-ROM widget records of
; v10 resolve to a class and are at least that far apart (THE CLASS
; SYSTEM, scripts/analysis/nakarest_objtab_map.py).
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

; [nakarest] NakaBoxData_PsSongSelBox  +0x0..+0x2 (0xe2107c, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xe2107c not derived; readers below
; [nakarest] Readers: source references MtName_SongNameSet
; [nakarest] (ui_widgets/naka_direct_play_dispatch.s: `.long NakaBoxData_PsSongSelBox`); 1 data
; [nakarest] word in MtName_SongNameSet (at 0xe21078), which is read by MtName_PtrTable
; [nakarest] (ui_widgets/naka_direct_play_dispatch.s: `.long MtName_SongNameSet`).
NakaBoxData_PsSongSelBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x0, 0x2
; [nakarest] naka_direct_play+0x2  +0x2..+0x14 (0xe2107e, 18 B)
; [nakarest] name string, entry 0 of Function slot 0x407 (table 0xe21074, 1 entries,
; [nakarest] InitializeYoko) (names for Function slot 0x107): "PsSongSelBoxProc".
	.incbin "includes/generated/naka_direct_play.bin", 0x2, 0x12
; [nakarest] naka_direct_play+0x14  +0x14..+0x50 (0xe21090, 60 B)
; [nakarest] widget record, element 0 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): TtlScreen (42 B). 1 text the records point at (Viewable
; [nakarest] slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): "SMF DIRECT PLAY "
; [nakarest] (TtlScreen.title of element 0).
	.incbin "includes/generated/naka_direct_play.bin", 0x14, 0x3C
; [nakarest] NakaWidget_SmfDpContainer  +0x50..+0x74 (0xe210cc, 36 B)
; [nakarest] widget record, element 1 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcTempoBox (36 B).
NakaWidget_SmfDpContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x50, 0x24
; [nakarest] NakaWidget_SmfDpVolume  +0x74..+0xb2 (0xe210f0, 62 B)
; [nakarest] widget record, element 2 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcTitleMenu (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): "LYRICS"
; [nakarest] (AcTitleMenu.str of element 2).
NakaWidget_SmfDpVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0x74, 0x3E
; [nakarest] NakaWidget_SmfDpGroup  +0xb2..+0xcc (0xe2112e, 26 B)
; [nakarest] widget record, element 3 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): Box (26 B).
NakaWidget_SmfDpGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0xB2, 0x1A
; [nakarest] NakaWidget_SmfDpMuteRow0  +0xcc..+0xf0 (0xe21148, 36 B)
; [nakarest] widget record, element 4 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcSmfFileNameBox (36 B).
NakaWidget_SmfDpMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0xCC, 0x24
; [nakarest] NakaWidget_SmfDpMuteRow1  +0xf0..+0x114 (0xe2116c, 36 B)
; [nakarest] widget record, element 5 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcSmfSongNameBox (36 B).
NakaWidget_SmfDpMuteRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0xF0, 0x24
; [nakarest] NakaWidget_SmfDpLyricsToggle  +0x114..+0x13c (0xe21190, 40 B)
; [nakarest] widget record, element 6 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcIndexEditSw (40 B).
NakaWidget_SmfDpLyricsToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x114, 0x28
; [nakarest] NakaWidget_SmfDpMuteToggle  +0x13c..+0x178 (0xe211b8, 60 B)
; [nakarest] widget record, element 7 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcRamEditBox (58 B). 1 text the records point at
; [nakarest] (Viewable slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): " "
; [nakarest] (AcRamEditBox.caption of element 7).
NakaWidget_SmfDpMuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x13C, 0x3C
; [nakarest] NakaWidget_SmfDpMeasureBox  +0x178..+0x192 (0xe211f4, 26 B)
; [nakarest] widget record, element 8 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): IvMainEditSw (26 B).
NakaWidget_SmfDpMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x178, 0x1A
; [nakarest] NakaWidget_SmfDpFileSelector  +0x192..+0x1ac (0xe2120e, 26 B)
; [nakarest] widget record, element 9 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): IvFixWin (26 B).
NakaWidget_SmfDpFileSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0x192, 0x1A
; [nakarest] NakaWidget_SmfDpFileList  +0x1ac..+0x1e0 (0xe21228, 52 B)
; [nakarest] widget record, element 10 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcMuteToggleBox (44 B). 2 texts the records point at
; [nakarest] (Viewable slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): "OFF"
; [nakarest] (AcMuteToggleBox.stroff of element 10); "ON" (AcMuteToggleBox.stron of element 10).
NakaWidget_SmfDpFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AC, 0x34
; [nakarest] NakaWidget_SmfDpMixer  +0x1e0..+0x218 (0xe2125c, 56 B)
; [nakarest] widget record, element 11 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): VwMenuBox (50 B). 1 text the records point at (Viewable
; [nakarest] slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): "MIXER" (VwMenuBox.str of
; [nakarest] element 11).
NakaWidget_SmfDpMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E0, 0x38
; [nakarest] NakaWidget_SmfDpMic  +0x218..+0x24e (0xe21294, 54 B)
; [nakarest] widget record, element 12 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): VwMenuBox (50 B). 1 text the records point at (Viewable
; [nakarest] slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): "MIC" (VwMenuBox.str of
; [nakarest] element 12).
NakaWidget_SmfDpMic:
	.incbin "includes/generated/naka_direct_play.bin", 0x218, 0x36
; [nakarest] NakaWidget_SmfDpMuteChLabel  +0x24e..+0x278 (0xe212ca, 42 B)
; [nakarest] widget record, element 13 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): Label (32 B). 1 text the records point at (Viewable slot
; [nakarest] 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): "-MUTE CH-" (Label.str of
; [nakarest] element 13).
NakaWidget_SmfDpMuteChLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x24E, 0x2A
; [nakarest] NakaWidget_SmfDpMuteChPanel  +0x278..+0x2b0 (0xe212f4, 56 B)
; [nakarest] widget record, element 14 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): TtlScreen (42 B). 1 text the records point at (Viewable
; [nakarest] slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): "SMF MEDLEY "
; [nakarest] (TtlScreen.title of element 14).
NakaWidget_SmfDpMuteChPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x278, 0x38
; [nakarest] NakaWidget_SmfMedleyItem  +0x2b0..+0x2ec (0xe2132c, 60 B)
; [nakarest] widget record, element 15 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcTitleMenu (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): "MIXER"
; [nakarest] (AcTitleMenu.str of element 15).
NakaWidget_SmfMedleyItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x2B0, 0x3C
; [nakarest] NakaWidget_SmfMixerItem  +0x2ec..+0x326 (0xe21368, 58 B)
; [nakarest] widget record, element 16 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcTitleMenu (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): "MIC"
; [nakarest] (AcTitleMenu.str of element 16).
NakaWidget_SmfMixerItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x2EC, 0x3A
; [nakarest] NakaWidget_SmfLyricsItem  +0x326..+0x364 (0xe213a2, 62 B)
; [nakarest] widget record, element 17 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcTitleMenu (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): "LYRICS"
; [nakarest] (AcTitleMenu.str of element 17).
NakaWidget_SmfLyricsItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x326, 0x3E
; [nakarest] NakaWidget_SmfDpSubPanel  +0x364..+0x388 (0xe213e0, 36 B)
; [nakarest] widget record, element 18 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcTempoBox (36 B).
NakaWidget_SmfDpSubPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x364, 0x24
; [nakarest] NakaWidget_SmfDpDisplayMode  +0x388..+0x3b4 (0xe21404, 44 B)
; [nakarest] widget record, element 19 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcFuncEditSw (44 B).
NakaWidget_SmfDpDisplayMode:
	.incbin "includes/generated/naka_direct_play.bin", 0x388, 0x2C
; [nakarest] NakaWidget_SmfDpSkipLabel  +0x3b4..+0x3da (0xe21430, 38 B)
; [nakarest] widget record, element 20 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): Label (32 B). 1 text the records point at (Viewable slot
; [nakarest] 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): "SKIP" (Label.str of element
; [nakarest] 20).
NakaWidget_SmfDpSkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x3B4, 0x26
; [nakarest] NakaWidget_SmfDpLyricsToggle2  +0x3da..+0x402 (0xe21456, 40 B)
; [nakarest] widget record, element 21 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcIndexEditSw (40 B).
NakaWidget_SmfDpLyricsToggle2:
	.incbin "includes/generated/naka_direct_play.bin", 0x3DA, 0x28
; [nakarest] NakaWidget_SmfDpChLabel  +0x402..+0x426 (0xe2147e, 36 B)
; [nakarest] widget record, element 22 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): Label (32 B). 1 text the records point at (Viewable slot
; [nakarest] 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): "CH" (Label.str of element 22).
NakaWidget_SmfDpChLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x402, 0x24
; [nakarest] NakaWidget_SmfDpMuteGroup  +0x426..+0x440 (0xe214a2, 26 B)
; [nakarest] widget record, element 23 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): Box (26 B).
NakaWidget_SmfDpMuteGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x426, 0x1A
; [nakarest] NakaWidget_SmfDpMuteSel1  +0x440..+0x464 (0xe214bc, 36 B)
; [nakarest] widget record, element 24 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): Window (36 B).
NakaWidget_SmfDpMuteSel1:
	.incbin "includes/generated/naka_direct_play.bin", 0x440, 0x24
; [nakarest] NakaWidget_SmfDpMuteSel2  +0x464..+0x492 (0xe214e0, 46 B)
; [nakarest] widget record, element 25 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 25).
NakaWidget_SmfDpMuteSel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x464, 0x2E
; [nakarest] NakaWidget_SmfDpMuteCtrl1  +0x492..+0x4ac (0xe2150e, 26 B)
; [nakarest] widget record, element 26 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): Bitmap (26 B).
NakaWidget_SmfDpMuteCtrl1:
	.incbin "includes/generated/naka_direct_play.bin", 0x492, 0x1A
; [nakarest] NakaWidget_SmfDpMuteSel3  +0x4ac..+0x4da (0xe21528, 46 B)
; [nakarest] widget record, element 27 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 27).
NakaWidget_SmfDpMuteSel3:
	.incbin "includes/generated/naka_direct_play.bin", 0x4AC, 0x2E
; [nakarest] NakaWidget_SmfDpMuteCtrl2  +0x4da..+0x4f4 (0xe21556, 26 B)
; [nakarest] widget record, element 28 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): Bitmap (26 B).
NakaWidget_SmfDpMuteCtrl2:
	.incbin "includes/generated/naka_direct_play.bin", 0x4DA, 0x1A
; [nakarest] NakaWidget_SmfDpMuteSel4  +0x4f4..+0x522 (0xe21570, 46 B)
; [nakarest] widget record, element 29 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 29).
NakaWidget_SmfDpMuteSel4:
	.incbin "includes/generated/naka_direct_play.bin", 0x4F4, 0x2E
; [nakarest] NakaWidget_SmfDpMuteCtrl3  +0x522..+0x53c (0xe2159e, 26 B)
; [nakarest] widget record, element 30 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): Bitmap (26 B).
NakaWidget_SmfDpMuteCtrl3:
	.incbin "includes/generated/naka_direct_play.bin", 0x522, 0x1A
; [nakarest] NakaWidget_SmfDpMuteSel5  +0x53c..+0x56a (0xe215b8, 46 B)
; [nakarest] widget record, element 31 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 31).
NakaWidget_SmfDpMuteSel5:
	.incbin "includes/generated/naka_direct_play.bin", 0x53C, 0x2E
; [nakarest] NakaWidget_SmfDpMuteCtrl4  +0x56a..+0x584 (0xe215e6, 26 B)
; [nakarest] widget record, element 32 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): Bitmap (26 B).
NakaWidget_SmfDpMuteCtrl4:
	.incbin "includes/generated/naka_direct_play.bin", 0x56A, 0x1A
; [nakarest] NakaWidget_SmfDpMuteSel6  +0x584..+0x5b2 (0xe21600, 46 B)
; [nakarest] widget record, element 33 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x6f (table 0xe240ac, 43 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 33).
NakaWidget_SmfDpMuteSel6:
	.incbin "includes/generated/naka_direct_play.bin", 0x584, 0x2E
; [nakarest] NakaWidget_SmfDpMuteCtrl5  +0x5b2..+0x5cc (0xe2162e, 26 B)
; [nakarest] widget record, element 34 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): Bitmap (26 B).
NakaWidget_SmfDpMuteCtrl5:
	.incbin "includes/generated/naka_direct_play.bin", 0x5B2, 0x1A
; [nakarest] NakaWidget_SmfDpMeasure  +0x5cc..+0x5e6 (0xe21648, 26 B)
; [nakarest] widget record, element 35 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): IvMainEditSw (26 B).
NakaWidget_SmfDpMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0x5CC, 0x1A
; [nakarest] NakaWidget_SmfDpRT1Selector  +0x5e6..+0x612 (0xe21662, 44 B)
; [nakarest] widget record, element 36 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcRamBox (44 B).
NakaWidget_SmfDpRT1Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x5E6, 0x2C
; [nakarest] NakaWidget_SmfDpRT2Selector  +0x612..+0x63e (0xe2168e, 44 B)
; [nakarest] widget record, element 37 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): AcRamBox (44 B).
NakaWidget_SmfDpRT2Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x612, 0x2C
; [nakarest] NakaWidget_SmfDpOrchSel  +0x63e..+0x662 (0xe216ba, 36 B)
; [nakarest] widget record, element 38 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): Window (36 B).
NakaWidget_SmfDpOrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x63E, 0x24
; [nakarest] NakaWidget_SmfDpRT1Display  +0x662..+0x68a (0xe216de, 40 B)
; [nakarest] widget record, element 39 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): LyricsBox (40 B).
NakaWidget_SmfDpRT1Display:
	.incbin "includes/generated/naka_direct_play.bin", 0x662, 0x28
; [nakarest] NakaWidget_SmfDpMuteSwRow0  +0x68a..+0x6a6 (0xe21706, 28 B)
; [nakarest] widget record, element 40 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): VwBox (28 B).
NakaWidget_SmfDpMuteSwRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0x68A, 0x1C
; [nakarest] NakaWidget_SmfDpMuteSwRow1  +0x6a6..+0x6cc (0xe21722, 38 B)
; [nakarest] widget record, element 41 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): SongNameBox (38 B).
NakaWidget_SmfDpMuteSwRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0x6A6, 0x26
; [nakarest] NakaWidget_SmfDpMuteSwRow2  +0x6cc..+0x6f2 (0xe21748, 38 B)
; [nakarest] widget record, element 42 of Viewable slot 0x6f (table 0xe240ac, 43 entries,
; [nakarest] InitializeYoko) ("DpSmf"): ComporserNameBox (38 B).
NakaWidget_SmfDpMuteSwRow2:
	.incbin "includes/generated/naka_direct_play.bin", 0x6CC, 0x26
; [nakarest] naka_direct_play+0x6f2  +0x6f2..+0x72e (0xe2176e, 60 B)
; [nakarest] widget record, element 0 of Viewable slot 0x70 (table 0xe2415c, 12 entries,
; [nakarest] InitializeYoko) ("DpDoc"): TtlScreen (42 B). 1 text the records point at (Viewable
; [nakarest] slot 0x70 (table 0xe2415c, 12 entries, InitializeYoko)): "DOC DIRECT PLAY "
; [nakarest] (TtlScreen.title of element 0).
	.incbin "includes/generated/naka_direct_play.bin", 0x6F2, 0x3C
; [nakarest] NakaWidget_DocDpContainer  +0x72e..+0x752 (0xe217aa, 36 B)
; [nakarest] widget record, element 1 of Viewable slot 0x70 (table 0xe2415c, 12 entries,
; [nakarest] InitializeYoko) ("DpDoc"): AcTempoBox (36 B).
NakaWidget_DocDpContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x72E, 0x24
; [nakarest] NakaWidget_DocDpVolume  +0x752..+0x76c (0xe217ce, 26 B)
; [nakarest] widget record, element 2 of Viewable slot 0x70 (table 0xe2415c, 12 entries,
; [nakarest] InitializeYoko) ("DpDoc"): Box (26 B).
NakaWidget_DocDpVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0x752, 0x1A
; [nakarest] NakaWidget_DocDpGroup  +0x76c..+0x790 (0xe217e8, 36 B)
; [nakarest] widget record, element 3 of Viewable slot 0x70 (table 0xe2415c, 12 entries,
; [nakarest] InitializeYoko) ("DpDoc"): AcDocSongNameBox (36 B).
NakaWidget_DocDpGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x76C, 0x24
; [nakarest] NakaWidget_DocDpMuteRow0  +0x790..+0x7b4 (0xe2180c, 36 B)
; [nakarest] widget record, element 4 of Viewable slot 0x70 (table 0xe2415c, 12 entries,
; [nakarest] InitializeYoko) ("DpDoc"): AcDocFileNoBox (36 B).
NakaWidget_DocDpMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0x790, 0x24
; [nakarest] NakaWidget_DocDpMeasure  +0x7b4..+0x7ce (0xe21830, 26 B)
; [nakarest] widget record, element 5 of Viewable slot 0x70 (table 0xe2415c, 12 entries,
; [nakarest] InitializeYoko) ("DpDoc"): IvMainEditSw (26 B).
NakaWidget_DocDpMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0x7B4, 0x1A
; [nakarest] NakaWidget_DocDpFileSelector  +0x7ce..+0x7e8 (0xe2184a, 26 B)
; [nakarest] widget record, element 6 of Viewable slot 0x70 (table 0xe2415c, 12 entries,
; [nakarest] InitializeYoko) ("DpDoc"): IvFixWin (26 B).
NakaWidget_DocDpFileSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0x7CE, 0x1A
; [nakarest] NakaWidget_DocDpFileList  +0x7e8..+0x81c (0xe21864, 52 B)
; [nakarest] widget record, element 7 of Viewable slot 0x70 (table 0xe2415c, 12 entries,
; [nakarest] InitializeYoko) ("DpDoc"): AcMuteToggleBox (44 B). 2 texts the records point at
; [nakarest] (Viewable slot 0x70 (table 0xe2415c, 12 entries, InitializeYoko)): "RT1"
; [nakarest] (AcMuteToggleBox.stroff of element 7); "RT1" (AcMuteToggleBox.stron of element 7).
NakaWidget_DocDpFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x7E8, 0x34
; [nakarest] NakaWidget_DocDpRT2Selector  +0x81c..+0x850 (0xe21898, 52 B)
; [nakarest] widget record, element 8 of Viewable slot 0x70 (table 0xe2415c, 12 entries,
; [nakarest] InitializeYoko) ("DpDoc"): AcMuteToggleBox (44 B). 2 texts the records point at
; [nakarest] (Viewable slot 0x70 (table 0xe2415c, 12 entries, InitializeYoko)): "RT2"
; [nakarest] (AcMuteToggleBox.stroff of element 8); "RT2" (AcMuteToggleBox.stron of element 8).
NakaWidget_DocDpRT2Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x81C, 0x34
; [nakarest] NakaWidget_DocDpOrchSelector  +0x850..+0x888 (0xe218cc, 56 B)
; [nakarest] widget record, element 9 of Viewable slot 0x70 (table 0xe2415c, 12 entries,
; [nakarest] InitializeYoko) ("DpDoc"): AcMuteToggleBox (44 B). 2 texts the records point at
; [nakarest] (Viewable slot 0x70 (table 0xe2415c, 12 entries, InitializeYoko)): "ORCH"
; [nakarest] (AcMuteToggleBox.stroff of element 9); "ORCH" (AcMuteToggleBox.stron of element 9).
NakaWidget_DocDpOrchSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0x850, 0x38
; [nakarest] NakaWidget_DocDpMixer  +0x888..+0x8c0 (0xe21904, 56 B)
; [nakarest] widget record, element 10 of Viewable slot 0x70 (table 0xe2415c, 12 entries,
; [nakarest] InitializeYoko) ("DpDoc"): VwMenuBox (50 B). 1 text the records point at (Viewable
; [nakarest] slot 0x70 (table 0xe2415c, 12 entries, InitializeYoko)): "MIXER" (VwMenuBox.str of
; [nakarest] element 10).
NakaWidget_DocDpMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x888, 0x38
; [nakarest] NakaWidget_DocDpMic  +0x8c0..+0x8f6 (0xe2193c, 54 B)
; [nakarest] widget record, element 11 of Viewable slot 0x70 (table 0xe2415c, 12 entries,
; [nakarest] InitializeYoko) ("DpDoc"): VwMenuBox (50 B). 1 text the records point at (Viewable
; [nakarest] slot 0x70 (table 0xe2415c, 12 entries, InitializeYoko)): "MIC" (VwMenuBox.str of
; [nakarest] element 11).
NakaWidget_DocDpMic:
	.incbin "includes/generated/naka_direct_play.bin", 0x8C0, 0x36
; [nakarest] NakaWidget_PdDpContainer  +0x8f6..+0x93c (0xe21972, 70 B)
; [nakarest] widget record, element 0 of Viewable slot 0x71 (table 0xe24190, 11 entries,
; [nakarest] InitializeYoko) ("DpPd"): TtlScreen (42 B). 1 text the records point at (Viewable
; [nakarest] slot 0x71 (table 0xe24190, 11 entries, InitializeYoko)): "PIANO DISC DIRECT PLAY "
; [nakarest] (TtlScreen.title of element 0).
NakaWidget_PdDpContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x8F6, 0x46
; [nakarest] NakaWidget_PdDpVolume  +0x93c..+0x960 (0xe219b8, 36 B)
; [nakarest] widget record, element 1 of Viewable slot 0x71 (table 0xe24190, 11 entries,
; [nakarest] InitializeYoko) ("DpPd"): AcTempoBox (36 B).
NakaWidget_PdDpVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0x93C, 0x24
; [nakarest] NakaWidget_PdDpGroup  +0x960..+0x97a (0xe219dc, 26 B)
; [nakarest] widget record, element 2 of Viewable slot 0x71 (table 0xe24190, 11 entries,
; [nakarest] InitializeYoko) ("DpPd"): Box (26 B).
NakaWidget_PdDpGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x960, 0x1A
; [nakarest] NakaWidget_PdDpMuteRow0  +0x97a..+0x99e (0xe219f6, 36 B)
; [nakarest] widget record, element 3 of Viewable slot 0x71 (table 0xe24190, 11 entries,
; [nakarest] InitializeYoko) ("DpPd"): AcPDSongNameBox (36 B).
NakaWidget_PdDpMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0x97A, 0x24
; [nakarest] NakaWidget_PdDpMuteRow1  +0x99e..+0x9c2 (0xe21a1a, 36 B)
; [nakarest] widget record, element 4 of Viewable slot 0x71 (table 0xe24190, 11 entries,
; [nakarest] InitializeYoko) ("DpPd"): AcPDFileNoBox (36 B).
NakaWidget_PdDpMuteRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0x99E, 0x24
; [nakarest] NakaWidget_PdDpMeasure  +0x9c2..+0x9dc (0xe21a3e, 26 B)
; [nakarest] widget record, element 5 of Viewable slot 0x71 (table 0xe24190, 11 entries,
; [nakarest] InitializeYoko) ("DpPd"): IvMainEditSw (26 B).
NakaWidget_PdDpMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0x9C2, 0x1A
; [nakarest] NakaWidget_PdDpFileSelector  +0x9dc..+0x9f6 (0xe21a58, 26 B)
; [nakarest] widget record, element 6 of Viewable slot 0x71 (table 0xe24190, 11 entries,
; [nakarest] InitializeYoko) ("DpPd"): IvFixWin (26 B).
NakaWidget_PdDpFileSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0x9DC, 0x1A
; [nakarest] NakaWidget_PdDpFileList  +0x9f6..+0xa2a (0xe21a72, 52 B)
; [nakarest] widget record, element 7 of Viewable slot 0x71 (table 0xe24190, 11 entries,
; [nakarest] InitializeYoko) ("DpPd"): AcMuteToggleBox (44 B). 2 texts the records point at
; [nakarest] (Viewable slot 0x71 (table 0xe24190, 11 entries, InitializeYoko)): "RT1"
; [nakarest] (AcMuteToggleBox.stroff of element 7); "RT1" (AcMuteToggleBox.stron of element 7).
NakaWidget_PdDpFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x9F6, 0x34
; [nakarest] NakaWidget_PdDpOrchSelector  +0xa2a..+0xa62 (0xe21aa6, 56 B)
; [nakarest] widget record, element 8 of Viewable slot 0x71 (table 0xe24190, 11 entries,
; [nakarest] InitializeYoko) ("DpPd"): AcMuteToggleBox (44 B). 2 texts the records point at
; [nakarest] (Viewable slot 0x71 (table 0xe24190, 11 entries, InitializeYoko)): "ORCH"
; [nakarest] (AcMuteToggleBox.stroff of element 8); "ORCH" (AcMuteToggleBox.stron of element 8).
NakaWidget_PdDpOrchSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0xA2A, 0x38
; [nakarest] NakaWidget_PdDpMixer  +0xa62..+0xa9a (0xe21ade, 56 B)
; [nakarest] widget record, element 9 of Viewable slot 0x71 (table 0xe24190, 11 entries,
; [nakarest] InitializeYoko) ("DpPd"): VwMenuBox (50 B). 1 text the records point at (Viewable
; [nakarest] slot 0x71 (table 0xe24190, 11 entries, InitializeYoko)): "MIXER" (VwMenuBox.str of
; [nakarest] element 9).
NakaWidget_PdDpMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0xA62, 0x38
; [nakarest] NakaWidget_PdDpMic  +0xa9a..+0xad0 (0xe21b16, 54 B)
; [nakarest] widget record, element 10 of Viewable slot 0x71 (table 0xe24190, 11 entries,
; [nakarest] InitializeYoko) ("DpPd"): VwMenuBox (50 B). 1 text the records point at (Viewable
; [nakarest] slot 0x71 (table 0xe24190, 11 entries, InitializeYoko)): "MIC" (VwMenuBox.str of
; [nakarest] element 10).
NakaWidget_PdDpMic:
	.incbin "includes/generated/naka_direct_play.bin", 0xA9A, 0x36
; [nakarest] NakaWidget_SmfMdlyContainer  +0xad0..+0xb0c (0xe21b4c, 60 B)
; [nakarest] widget record, element 0 of Viewable slot 0x72 (table 0xe241c0, 7 entries,
; [nakarest] InitializeYoko) ("DpSmfLyr"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x72 (table 0xe241c0, 7 entries, InitializeYoko)): "SMF DIRECT PLAY
; [nakarest] " (TtlScreen.title of element 0).
NakaWidget_SmfMdlyContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0xAD0, 0x3C
; [nakarest] NakaWidget_SmfMdlyVolume  +0xb0c..+0xb30 (0xe21b88, 36 B)
; [nakarest] widget record, element 1 of Viewable slot 0x72 (table 0xe241c0, 7 entries,
; [nakarest] InitializeYoko) ("DpSmfLyr"): AcTempoBox (36 B).
NakaWidget_SmfMdlyVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0xB0C, 0x24
; [nakarest] NakaWidget_SmfMdlyMeasure  +0xb30..+0xb4a (0xe21bac, 26 B)
; [nakarest] widget record, element 2 of Viewable slot 0x72 (table 0xe241c0, 7 entries,
; [nakarest] InitializeYoko) ("DpSmfLyr"): IvMainEditSw (26 B).
NakaWidget_SmfMdlyMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0xB30, 0x1A
; [nakarest] NakaWidget_SmfMdlyFileSelector  +0xb4a..+0xb64 (0xe21bc6, 26 B)
; [nakarest] widget record, element 3 of Viewable slot 0x72 (table 0xe241c0, 7 entries,
; [nakarest] InitializeYoko) ("DpSmfLyr"): IvFixWin (26 B).
NakaWidget_SmfMdlyFileSelector:
	.incbin "includes/generated/naka_direct_play.bin", 0xB4A, 0x1A
; [nakarest] NakaWidget_SmfMdlyMicWidget  +0xb64..+0xb9a (0xe21be0, 54 B)
; [nakarest] widget record, element 4 of Viewable slot 0x72 (table 0xe241c0, 7 entries,
; [nakarest] InitializeYoko) ("DpSmfLyr"): VwMenuBox (50 B). 1 text the records point at
; [nakarest] (Viewable slot 0x72 (table 0xe241c0, 7 entries, InitializeYoko)): "MIC"
; [nakarest] (VwMenuBox.str of element 4).
NakaWidget_SmfMdlyMicWidget:
	.incbin "includes/generated/naka_direct_play.bin", 0xB64, 0x36
; [nakarest] NakaWidget_SmfMdlyOrchSel  +0xb9a..+0xbb4 (0xe21c16, 26 B)
; [nakarest] widget record, element 5 of Viewable slot 0x72 (table 0xe241c0, 7 entries,
; [nakarest] InitializeYoko) ("DpSmfLyr"): IvFixWin (26 B).
NakaWidget_SmfMdlyOrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0xB9A, 0x1A
; [nakarest] NakaWidget_SmfMdlyOrchRow  +0xbb4..+0xbca (0xe21c30, 22 B)
; [nakarest] widget record, element 6 of Viewable slot 0x72 (table 0xe241c0, 7 entries,
; [nakarest] InitializeYoko) ("DpSmfLyr"): LyeicsBoxFunc (22 B).
NakaWidget_SmfMdlyOrchRow:
	.incbin "includes/generated/naka_direct_play.bin", 0xBB4, 0x16
; [nakarest] NakaWidget_SmfMdlyContainer2  +0xbca..+0xc00 (0xe21c46, 54 B)
; [nakarest] widget record, element 0 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x73 (table 0xe241e0, 16 entries, InitializeYoko)): "SMF MEDLEY"
; [nakarest] (TtlScreen.title of element 0).
NakaWidget_SmfMdlyContainer2:
	.incbin "includes/generated/naka_direct_play.bin", 0xBCA, 0x36
; [nakarest] NakaWidget_SmfMdlyLyricsItem  +0xc00..+0xc3e (0xe21c7c, 62 B)
; [nakarest] widget record, element 1 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): AcTitleMenu (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0x73 (table 0xe241e0, 16 entries, InitializeYoko)): "LYRICS"
; [nakarest] (AcTitleMenu.str of element 1).
NakaWidget_SmfMdlyLyricsItem:
	.incbin "includes/generated/naka_direct_play.bin", 0xC00, 0x3E
; [nakarest] NakaWidget_SmfMdlySubPanel  +0xc3e..+0xc62 (0xe21cba, 36 B)
; [nakarest] widget record, element 2 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): AcTempoBox (36 B).
NakaWidget_SmfMdlySubPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0xC3E, 0x24
; [nakarest] NakaWidget_SmfMdlyLyricsToggle  +0xc62..+0xc8a (0xe21cde, 40 B)
; [nakarest] widget record, element 3 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): AcIndexEditSw (40 B).
NakaWidget_SmfMdlyLyricsToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0xC62, 0x28
; [nakarest] NakaWidget_SmfMdlyGroup  +0xc8a..+0xca4 (0xe21d06, 26 B)
; [nakarest] widget record, element 4 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): Box (26 B).
NakaWidget_SmfMdlyGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0xC8A, 0x1A
; [nakarest] NakaWidget_SmfMdlyMuteRow0  +0xca4..+0xcc8 (0xe21d20, 36 B)
; [nakarest] widget record, element 5 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): AcSmfSongNameBox (36 B).
NakaWidget_SmfMdlyMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0xCA4, 0x24
; [nakarest] NakaWidget_SmfMdlyMuteRow1  +0xcc8..+0xcec (0xe21d44, 36 B)
; [nakarest] widget record, element 6 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): AcSmfFileNameBox (36 B).
NakaWidget_SmfMdlyMuteRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0xCC8, 0x24
; [nakarest] NakaWidget_SmfMdlyMuteToggle  +0xcec..+0xd1a (0xe21d68, 46 B)
; [nakarest] widget record, element 7 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x73 (table 0xe241e0, 16 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 7).
NakaWidget_SmfMdlyMuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0xCEC, 0x2E
; [nakarest] NakaWidget_SmfMdlySkipLabel  +0xd1a..+0xd40 (0xe21d96, 38 B)
; [nakarest] widget record, element 8 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0x73 (table 0xe241e0, 16 entries, InitializeYoko)): "SKIP" (Label.str of
; [nakarest] element 8).
NakaWidget_SmfMdlySkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0xD1A, 0x26
; [nakarest] NakaWidget_SmfMdlyMutePanel  +0xd40..+0xd7c (0xe21dbc, 60 B)
; [nakarest] widget record, element 9 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): AcRamEditBox (58 B). 1 text the records point at
; [nakarest] (Viewable slot 0x73 (table 0xe241e0, 16 entries, InitializeYoko)): " "
; [nakarest] (AcRamEditBox.caption of element 9).
NakaWidget_SmfMdlyMutePanel:
	.incbin "includes/generated/naka_direct_play.bin", 0xD40, 0x3C
; [nakarest] NakaWidget_SmfMdlyMeasureBox  +0xd7c..+0xd96 (0xe21df8, 26 B)
; [nakarest] widget record, element 10 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): IvMainEditSw (26 B).
NakaWidget_SmfMdlyMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0xD7C, 0x1A
; [nakarest] NakaWidget_SmfMdlyOffOnSel  +0xd96..+0xdac (0xe21e12, 22 B)
; [nakarest] widget record, element 11 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): IvExit (22 B).
NakaWidget_SmfMdlyOffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0xD96, 0x16
; [nakarest] NakaWidget_SmfMdlyOffOnList  +0xdac..+0xde0 (0xe21e28, 52 B)
; [nakarest] widget record, element 12 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): AcMuteToggleBox (44 B). 2 texts the records point at
; [nakarest] (Viewable slot 0x73 (table 0xe241e0, 16 entries, InitializeYoko)): "OFF"
; [nakarest] (AcMuteToggleBox.stroff of element 12); "ON" (AcMuteToggleBox.stron of element 12).
NakaWidget_SmfMdlyOffOnList:
	.incbin "includes/generated/naka_direct_play.bin", 0xDAC, 0x34
; [nakarest] NakaWidget_SmfMdlyMixerWidget  +0xde0..+0xe18 (0xe21e5c, 56 B)
; [nakarest] widget record, element 13 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): VwMenuBox (50 B). 1 text the records point at
; [nakarest] (Viewable slot 0x73 (table 0xe241e0, 16 entries, InitializeYoko)): "MIXER"
; [nakarest] (VwMenuBox.str of element 13).
NakaWidget_SmfMdlyMixerWidget:
	.incbin "includes/generated/naka_direct_play.bin", 0xDE0, 0x38
; [nakarest] NakaWidget_SmfMdlyMicWidget2  +0xe18..+0xe4e (0xe21e94, 54 B)
; [nakarest] widget record, element 14 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): VwMenuBox (50 B). 1 text the records point at
; [nakarest] (Viewable slot 0x73 (table 0xe241e0, 16 entries, InitializeYoko)): "MIC"
; [nakarest] (VwMenuBox.str of element 14).
NakaWidget_SmfMdlyMicWidget2:
	.incbin "includes/generated/naka_direct_play.bin", 0xE18, 0x36
; [nakarest] NakaWidget_SmfMdlyMuteChLabel  +0xe4e..+0xe78 (0xe21eca, 42 B)
; [nakarest] widget record, element 15 of Viewable slot 0x73 (table 0xe241e0, 16 entries,
; [nakarest] InitializeYoko) ("DpMdlySmf"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0x73 (table 0xe241e0, 16 entries, InitializeYoko)): "-MUTE CH-" (Label.str of
; [nakarest] element 15).
NakaWidget_SmfMdlyMuteChLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0xE4E, 0x2A
; [nakarest] naka_direct_play+0xe78  +0xe78..+0xeae (0xe21ef4, 54 B)
; [nakarest] widget record, element 0 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): TtlScreen (42 B). 1 text the records point at (Viewable slot 0x74
; [nakarest] (table 0xe24224, 15 entries, InitializeYoko)): "SMF MEDLEY" (TtlScreen.title of
; [nakarest] element 0).
	.incbin "includes/generated/naka_direct_play.bin", 0xE78, 0x36
; [nakarest] NakaWidget_SmfMdlyRootContainer  +0xeae..+0xee4 (0xe21f2a, 54 B)
; [nakarest] widget record, element 1 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): TtlScreen (42 B). 1 text the records point at (Viewable slot 0x74
; [nakarest] (table 0xe24224, 15 entries, InitializeYoko)): "DOC MEDLEY" (TtlScreen.title of
; [nakarest] element 1).
NakaWidget_SmfMdlyRootContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0xEAE, 0x36
; [nakarest] NakaWidget_DocMdlyContainer  +0xee4..+0xefe (0xe21f60, 26 B)
; [nakarest] widget record, element 2 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): Box (26 B).
NakaWidget_DocMdlyContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0xEE4, 0x1A
; [nakarest] NakaWidget_DocMdlyGroup  +0xefe..+0xf22 (0xe21f7a, 36 B)
; [nakarest] widget record, element 3 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): AcDocSongNameBox (36 B).
NakaWidget_DocMdlyGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0xEFE, 0x24
; [nakarest] NakaWidget_DocMdlyMuteRow0  +0xf22..+0xf46 (0xe21f9e, 36 B)
; [nakarest] widget record, element 4 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): AcDocFileNoBox (36 B).
NakaWidget_DocMdlyMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0xF22, 0x24
; [nakarest] NakaWidget_DocMdlySubPanel  +0xf46..+0xf6a (0xe21fc2, 36 B)
; [nakarest] widget record, element 5 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): AcTempoBox (36 B).
NakaWidget_DocMdlySubPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0xF46, 0x24
; [nakarest] NakaWidget_DocMdlyMuteToggle  +0xf6a..+0xf98 (0xe21fe6, 46 B)
; [nakarest] widget record, element 6 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): VwEditSwBox (44 B). 1 text the records point at (Viewable slot
; [nakarest] 0x74 (table 0xe24224, 15 entries, InitializeYoko)): "" (VwEditSwBox.str of element
; [nakarest] 6).
NakaWidget_DocMdlyMuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0xF6A, 0x2E
; [nakarest] NakaWidget_DocMdlySkipLabel  +0xf98..+0xfbe (0xe22014, 38 B)
; [nakarest] widget record, element 7 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): Label (32 B). 1 text the records point at (Viewable slot 0x74
; [nakarest] (table 0xe24224, 15 entries, InitializeYoko)): "SKIP" (Label.str of element 7).
NakaWidget_DocMdlySkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0xF98, 0x26
; [nakarest] NakaWidget_DocMdlyMeasureBox  +0xfbe..+0xfd8 (0xe2203a, 26 B)
; [nakarest] widget record, element 8 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): IvMainEditSw (26 B).
NakaWidget_DocMdlyMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0xFBE, 0x1A
; [nakarest] NakaWidget_DocMdlyOffOnSel  +0xfd8..+0xfee (0xe22054, 22 B)
; [nakarest] widget record, element 9 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): IvExit (22 B).
NakaWidget_DocMdlyOffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0xFD8, 0x16
; [nakarest] NakaWidget_DocMdlyOffOnList  +0xfee..+0x1022 (0xe2206a, 52 B)
; [nakarest] widget record, element 10 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): AcMuteToggleBox (44 B). 2 texts the records point at (Viewable
; [nakarest] slot 0x74 (table 0xe24224, 15 entries, InitializeYoko)): "RT1"
; [nakarest] (AcMuteToggleBox.stroff of element 10); "RT1" (AcMuteToggleBox.stron of element
; [nakarest] 10).
NakaWidget_DocMdlyOffOnList:
	.incbin "includes/generated/naka_direct_play.bin", 0xFEE, 0x34
; [nakarest] NakaWidget_DocMdlyRT2Sel  +0x1022..+0x1056 (0xe2209e, 52 B)
; [nakarest] widget record, element 11 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): AcMuteToggleBox (44 B). 2 texts the records point at (Viewable
; [nakarest] slot 0x74 (table 0xe24224, 15 entries, InitializeYoko)): "RT2"
; [nakarest] (AcMuteToggleBox.stroff of element 11); "RT2" (AcMuteToggleBox.stron of element
; [nakarest] 11).
NakaWidget_DocMdlyRT2Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1022, 0x34
; [nakarest] NakaWidget_DocMdlyOrchSel  +0x1056..+0x108e (0xe220d2, 56 B)
; [nakarest] widget record, element 12 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): AcMuteToggleBox (44 B). 2 texts the records point at (Viewable
; [nakarest] slot 0x74 (table 0xe24224, 15 entries, InitializeYoko)): "ORCH"
; [nakarest] (AcMuteToggleBox.stroff of element 12); "ORCH" (AcMuteToggleBox.stron of element
; [nakarest] 12).
NakaWidget_DocMdlyOrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1056, 0x38
; [nakarest] NakaWidget_DocMdlyMixer  +0x108e..+0x10c6 (0xe2210a, 56 B)
; [nakarest] widget record, element 13 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): VwMenuBox (50 B). 1 text the records point at (Viewable slot 0x74
; [nakarest] (table 0xe24224, 15 entries, InitializeYoko)): "MIXER" (VwMenuBox.str of element
; [nakarest] 13).
NakaWidget_DocMdlyMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x108E, 0x38
; [nakarest] NakaWidget_DocMdlyMic  +0x10c6..+0x10fc (0xe22142, 54 B)
; [nakarest] widget record, element 14 of Viewable slot 0x74 (table 0xe24224, 15 entries,
; [nakarest] InitializeYoko): VwMenuBox (50 B). 1 text the records point at (Viewable slot 0x74
; [nakarest] (table 0xe24224, 15 entries, InitializeYoko)): "MIC" (VwMenuBox.str of element 14).
NakaWidget_DocMdlyMic:
	.incbin "includes/generated/naka_direct_play.bin", 0x10C6, 0x36
; [nakarest] naka_direct_play+0x10fc  +0x10fc..+0x113c (0xe22178, 64 B)
; [nakarest] widget record, element 0 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x75 (table 0xe24264, 13 entries, InitializeYoko)): "PIANO DISC
; [nakarest] MEDLEY " (TtlScreen.title of element 0).
	.incbin "includes/generated/naka_direct_play.bin", 0x10FC, 0x40
; [nakarest] NakaWidget_PdMdlyContainer  +0x113c..+0x1160 (0xe221b8, 36 B)
; [nakarest] widget record, element 1 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): AcTempoBox (36 B).
NakaWidget_PdMdlyContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x113C, 0x24
; [nakarest] NakaWidget_PdMdlyGroup  +0x1160..+0x117a (0xe221dc, 26 B)
; [nakarest] widget record, element 2 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): Box (26 B).
NakaWidget_PdMdlyGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x1160, 0x1A
; [nakarest] NakaWidget_PdMdlyMuteRow0  +0x117a..+0x119e (0xe221f6, 36 B)
; [nakarest] widget record, element 3 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): AcPDSongNameBox (36 B).
NakaWidget_PdMdlyMuteRow0:
	.incbin "includes/generated/naka_direct_play.bin", 0x117A, 0x24
; [nakarest] NakaWidget_PdMdlyMuteRow1  +0x119e..+0x11c2 (0xe2221a, 36 B)
; [nakarest] widget record, element 4 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): AcPDFileNoBox (36 B).
NakaWidget_PdMdlyMuteRow1:
	.incbin "includes/generated/naka_direct_play.bin", 0x119E, 0x24
; [nakarest] NakaWidget_PdMdlyMuteToggle  +0x11c2..+0x11f0 (0xe2223e, 46 B)
; [nakarest] widget record, element 5 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x75 (table 0xe24264, 13 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 5).
NakaWidget_PdMdlyMuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x11C2, 0x2E
; [nakarest] NakaWidget_PdMdlySkipLabel  +0x11f0..+0x1216 (0xe2226c, 38 B)
; [nakarest] widget record, element 6 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0x75 (table 0xe24264, 13 entries, InitializeYoko)): "SKIP" (Label.str of
; [nakarest] element 6).
NakaWidget_PdMdlySkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x11F0, 0x26
; [nakarest] NakaWidget_PdMdlyMeasureBox  +0x1216..+0x1230 (0xe22292, 26 B)
; [nakarest] widget record, element 7 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): IvMainEditSw (26 B).
NakaWidget_PdMdlyMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x1216, 0x1A
; [nakarest] NakaWidget_PdMdlyOffOnSel  +0x1230..+0x1246 (0xe222ac, 22 B)
; [nakarest] widget record, element 8 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): IvExit (22 B).
NakaWidget_PdMdlyOffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1230, 0x16
; [nakarest] NakaWidget_PdMdlyOffOnList  +0x1246..+0x127a (0xe222c2, 52 B)
; [nakarest] widget record, element 9 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): AcMuteToggleBox (44 B). 2 texts the records point at
; [nakarest] (Viewable slot 0x75 (table 0xe24264, 13 entries, InitializeYoko)): "RT1"
; [nakarest] (AcMuteToggleBox.stroff of element 9); "RT1" (AcMuteToggleBox.stron of element 9).
NakaWidget_PdMdlyOffOnList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1246, 0x34
; [nakarest] NakaWidget_PdMdlyRT2Sel  +0x127a..+0x12b2 (0xe222f6, 56 B)
; [nakarest] widget record, element 10 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): AcMuteToggleBox (44 B). 2 texts the records point at
; [nakarest] (Viewable slot 0x75 (table 0xe24264, 13 entries, InitializeYoko)): "ORCH"
; [nakarest] (AcMuteToggleBox.stroff of element 10); "ORCH" (AcMuteToggleBox.stron of element
; [nakarest] 10).
NakaWidget_PdMdlyRT2Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x127A, 0x38
; [nakarest] NakaWidget_PdMdlyMixer  +0x12b2..+0x12ea (0xe2232e, 56 B)
; [nakarest] widget record, element 11 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): VwMenuBox (50 B). 1 text the records point at
; [nakarest] (Viewable slot 0x75 (table 0xe24264, 13 entries, InitializeYoko)): "MIXER"
; [nakarest] (VwMenuBox.str of element 11).
NakaWidget_PdMdlyMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x12B2, 0x38
; [nakarest] NakaWidget_PdMdlyMic  +0x12ea..+0x1320 (0xe22366, 54 B)
; [nakarest] widget record, element 12 of Viewable slot 0x75 (table 0xe24264, 13 entries,
; [nakarest] InitializeYoko) ("DpMdlyPd"): VwMenuBox (50 B). 1 text the records point at
; [nakarest] (Viewable slot 0x75 (table 0xe24264, 13 entries, InitializeYoko)): "MIC"
; [nakarest] (VwMenuBox.str of element 12).
NakaWidget_PdMdlyMic:
	.incbin "includes/generated/naka_direct_play.bin", 0x12EA, 0x36
; [nakarest] naka_direct_play+0x1320  +0x1320..+0x1356 (0xe2239c, 54 B)
; [nakarest] widget record, element 0 of Viewable slot 0x76 (table 0xe2429c, 8 entries,
; [nakarest] InitializeYoko) ("DpMdlySmfLyr"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x76 (table 0xe2429c, 8 entries, InitializeYoko)): "SMF MEDLEY"
; [nakarest] (TtlScreen.title of element 0).
	.incbin "includes/generated/naka_direct_play.bin", 0x1320, 0x36
; [nakarest] NakaWidget_SmfMdly2Container  +0x1356..+0x137a (0xe223d2, 36 B)
; [nakarest] widget record, element 1 of Viewable slot 0x76 (table 0xe2429c, 8 entries,
; [nakarest] InitializeYoko) ("DpMdlySmfLyr"): AcTempoBox (36 B).
NakaWidget_SmfMdly2Container:
	.incbin "includes/generated/naka_direct_play.bin", 0x1356, 0x24
; [nakarest] NakaWidget_SmfMdly2MuteToggle  +0x137a..+0x13a8 (0xe223f6, 46 B)
; [nakarest] widget record, element 2 of Viewable slot 0x76 (table 0xe2429c, 8 entries,
; [nakarest] InitializeYoko) ("DpMdlySmfLyr"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x76 (table 0xe2429c, 8 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 2).
NakaWidget_SmfMdly2MuteToggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x137A, 0x2E
; [nakarest] NakaWidget_SmfMdly2SkipLabel  +0x13a8..+0x13ce (0xe22424, 38 B)
; [nakarest] widget record, element 3 of Viewable slot 0x76 (table 0xe2429c, 8 entries,
; [nakarest] InitializeYoko) ("DpMdlySmfLyr"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0x76 (table 0xe2429c, 8 entries, InitializeYoko)): "SKIP" (Label.str
; [nakarest] of element 3).
NakaWidget_SmfMdly2SkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x13A8, 0x26
; [nakarest] NakaWidget_SmfMdly2MeasureBox  +0x13ce..+0x13e8 (0xe2244a, 26 B)
; [nakarest] widget record, element 4 of Viewable slot 0x76 (table 0xe2429c, 8 entries,
; [nakarest] InitializeYoko) ("DpMdlySmfLyr"): IvMainEditSw (26 B).
NakaWidget_SmfMdly2MeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x13CE, 0x1A
; [nakarest] NakaWidget_SmfMdly2OffOnSel  +0x13e8..+0x13fe (0xe22464, 22 B)
; [nakarest] widget record, element 5 of Viewable slot 0x76 (table 0xe2429c, 8 entries,
; [nakarest] InitializeYoko) ("DpMdlySmfLyr"): IvExit (22 B).
NakaWidget_SmfMdly2OffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x13E8, 0x16
; [nakarest] NakaWidget_SmfMdly2MicWidget  +0x13fe..+0x1434 (0xe2247a, 54 B)
; [nakarest] widget record, element 6 of Viewable slot 0x76 (table 0xe2429c, 8 entries,
; [nakarest] InitializeYoko) ("DpMdlySmfLyr"): VwMenuBox (50 B). 1 text the records point at
; [nakarest] (Viewable slot 0x76 (table 0xe2429c, 8 entries, InitializeYoko)): "MIC"
; [nakarest] (VwMenuBox.str of element 6).
NakaWidget_SmfMdly2MicWidget:
	.incbin "includes/generated/naka_direct_play.bin", 0x13FE, 0x36
; [nakarest] NakaWidget_SmfMdly2OrchSel  +0x1434..+0x144e (0xe224b0, 26 B)
; [nakarest] widget record, element 7 of Viewable slot 0x76 (table 0xe2429c, 8 entries,
; [nakarest] InitializeYoko) ("DpMdlySmfLyr"): IvFixWin (26 B).
NakaWidget_SmfMdly2OrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1434, 0x1A
; [nakarest] NakaWidget_SongMdlyContainer  +0x144e..+0x148c (0xe224ca, 62 B)
; [nakarest] widget record, element 0 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x78 (table 0xe242c0, 30 entries, InitializeYoko)): "SONG MEDLEY "
; [nakarest] (TtlScreen.title of element 0).
NakaWidget_SongMdlyContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x144E, 0x3E
; [nakarest] NakaWidget_SongMdlyGroup  +0x148c..+0x14a6 (0xe22508, 26 B)
; [nakarest] widget record, element 1 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): Box (26 B).
NakaWidget_SongMdlyGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x148C, 0x1A
; [nakarest] NakaWidget_SongMdlyVolume  +0x14a6..+0x14ca (0xe22522, 36 B)
; [nakarest] widget record, element 2 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTempoBox (36 B).
NakaWidget_SongMdlyVolume:
	.incbin "includes/generated/naka_direct_play.bin", 0x14A6, 0x24
; [nakarest] NakaWidget_SongMdlySongSel  +0x14ca..+0x14ee (0xe22546, 36 B)
; [nakarest] widget record, element 3 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): TrTransposeBox (36 B).
NakaWidget_SongMdlySongSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x14CA, 0x24
; [nakarest] NakaWidget_SongMdlySongList  +0x14ee..+0x150c (0xe2256a, 30 B)
; [nakarest] widget record, element 4 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): MeasureBox (30 B).
NakaWidget_SongMdlySongList:
	.incbin "includes/generated/naka_direct_play.bin", 0x14EE, 0x1E
; [nakarest] NakaWidget_SongMdlyRT1Sel  +0x150c..+0x153a (0xe22588, 46 B)
; [nakarest] widget record, element 5 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x78 (table 0xe242c0, 30 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 5).
NakaWidget_SongMdlyRT1Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x150C, 0x2E
; [nakarest] NakaWidget_SongMdlyMeasureBox  +0x153a..+0x1554 (0xe225b6, 26 B)
; [nakarest] widget record, element 6 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): IvMainEditSw (26 B).
NakaWidget_SongMdlyMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x153A, 0x1A
; [nakarest] NakaWidget_SongMdlyFileList  +0x1554..+0x1578 (0xe225d0, 36 B)
; [nakarest] widget record, element 7 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcCurSongNameBox (36 B).
NakaWidget_SongMdlyFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1554, 0x24
; [nakarest] NakaWidget_SongMdlyMutePanel  +0x1578..+0x158e (0xe225f4, 22 B)
; [nakarest] widget record, element 8 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): IvTrackSwitch (22 B).
NakaWidget_SongMdlyMutePanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1578, 0x16
; [nakarest] NakaWidget_SongMdlyMuteList  +0x158e..+0x15b2 (0xe2260a, 36 B)
; [nakarest] widget record, element 9 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcDiskFileNameBox (36 B).
NakaWidget_SongMdlyMuteList:
	.incbin "includes/generated/naka_direct_play.bin", 0x158E, 0x24
; [nakarest] NakaWidget_SongMdlySkipLabel  +0x15b2..+0x15d8 (0xe2262e, 38 B)
; [nakarest] widget record, element 10 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0x78 (table 0xe242c0, 30 entries, InitializeYoko)): "SKIP" (Label.str of
; [nakarest] element 10).
NakaWidget_SongMdlySkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x15B2, 0x26
; [nakarest] NakaWidget_SongMdlyOffOnSel  +0x15d8..+0x15ee (0xe22654, 22 B)
; [nakarest] widget record, element 11 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): IvExit (22 B).
NakaWidget_SongMdlyOffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x15D8, 0x16
; [nakarest] NakaWidget_SongMdlyMixer  +0x15ee..+0x1626 (0xe2266a, 56 B)
; [nakarest] widget record, element 12 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): VwMenuBox (50 B). 1 text the records point at
; [nakarest] (Viewable slot 0x78 (table 0xe242c0, 30 entries, InitializeYoko)): "MIXER"
; [nakarest] (VwMenuBox.str of element 12).
NakaWidget_SongMdlyMixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x15EE, 0x38
; [nakarest] NakaWidget_SongMdlyOrchSel  +0x1626..+0x164a (0xe226a2, 36 B)
; [nakarest] widget record, element 13 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): Window (36 B).
NakaWidget_SongMdlyOrchSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1626, 0x24
; [nakarest] NakaWidget_SongMdlySongSel1  +0x164a..+0x166e (0xe226c6, 36 B)
; [nakarest] widget record, element 14 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel1:
	.incbin "includes/generated/naka_direct_play.bin", 0x164A, 0x24
; [nakarest] NakaWidget_SongMdlySongSel2  +0x166e..+0x1692 (0xe226ea, 36 B)
; [nakarest] widget record, element 15 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x166E, 0x24
; [nakarest] NakaWidget_SongMdlySongSel3  +0x1692..+0x16b6 (0xe2270e, 36 B)
; [nakarest] widget record, element 16 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel3:
	.incbin "includes/generated/naka_direct_play.bin", 0x1692, 0x24
; [nakarest] NakaWidget_SongMdlySongSel4  +0x16b6..+0x16da (0xe22732, 36 B)
; [nakarest] widget record, element 17 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel4:
	.incbin "includes/generated/naka_direct_play.bin", 0x16B6, 0x24
; [nakarest] NakaWidget_SongMdlySongSel5  +0x16da..+0x16fe (0xe22756, 36 B)
; [nakarest] widget record, element 18 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel5:
	.incbin "includes/generated/naka_direct_play.bin", 0x16DA, 0x24
; [nakarest] NakaWidget_SongMdlySongSel6  +0x16fe..+0x1722 (0xe2277a, 36 B)
; [nakarest] widget record, element 19 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel6:
	.incbin "includes/generated/naka_direct_play.bin", 0x16FE, 0x24
; [nakarest] NakaWidget_SongMdlySongSel7  +0x1722..+0x1746 (0xe2279e, 36 B)
; [nakarest] widget record, element 20 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel7:
	.incbin "includes/generated/naka_direct_play.bin", 0x1722, 0x24
; [nakarest] NakaWidget_SongMdlySongSel8  +0x1746..+0x176a (0xe227c2, 36 B)
; [nakarest] widget record, element 21 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel8:
	.incbin "includes/generated/naka_direct_play.bin", 0x1746, 0x24
; [nakarest] NakaWidget_SongMdlySongSel9  +0x176a..+0x178e (0xe227e6, 36 B)
; [nakarest] widget record, element 22 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel9:
	.incbin "includes/generated/naka_direct_play.bin", 0x176A, 0x24
; [nakarest] NakaWidget_SongMdlySongSel10  +0x178e..+0x17b2 (0xe2280a, 36 B)
; [nakarest] widget record, element 23 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel10:
	.incbin "includes/generated/naka_direct_play.bin", 0x178E, 0x24
; [nakarest] NakaWidget_SongMdlySongSel11  +0x17b2..+0x17d6 (0xe2282e, 36 B)
; [nakarest] widget record, element 24 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel11:
	.incbin "includes/generated/naka_direct_play.bin", 0x17B2, 0x24
; [nakarest] NakaWidget_SongMdlySongSel12  +0x17d6..+0x17fa (0xe22852, 36 B)
; [nakarest] widget record, element 25 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel12:
	.incbin "includes/generated/naka_direct_play.bin", 0x17D6, 0x24
; [nakarest] NakaWidget_SongMdlySongSel13  +0x17fa..+0x181e (0xe22876, 36 B)
; [nakarest] widget record, element 26 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel13:
	.incbin "includes/generated/naka_direct_play.bin", 0x17FA, 0x24
; [nakarest] NakaWidget_SongMdlySongSel14  +0x181e..+0x1842 (0xe2289a, 36 B)
; [nakarest] widget record, element 27 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel14:
	.incbin "includes/generated/naka_direct_play.bin", 0x181E, 0x24
; [nakarest] NakaWidget_SongMdlySongSel15  +0x1842..+0x1866 (0xe228be, 36 B)
; [nakarest] widget record, element 28 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel15:
	.incbin "includes/generated/naka_direct_play.bin", 0x1842, 0x24
; [nakarest] NakaWidget_SongMdlySongSel16  +0x1866..+0x188a (0xe228e2, 36 B)
; [nakarest] widget record, element 29 of Viewable slot 0x78 (table 0xe242c0, 30 entries,
; [nakarest] InitializeYoko) ("DkMdlyPly"): AcTrackSwitch (36 B).
NakaWidget_SongMdlySongSel16:
	.incbin "includes/generated/naka_direct_play.bin", 0x1866, 0x24
; [nakarest] naka_direct_play+0x188a  +0x188a..+0x18c0 (0xe22906, 54 B)
; [nakarest] widget record, element 0 of Viewable slot 0x7a (table 0xe2433c, 12 entries,
; [nakarest] InitializeYoko) ("SqMdlyPly"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x7a (table 0xe2433c, 12 entries, InitializeYoko)): "SONG MEDLEY"
; [nakarest] (TtlScreen.title of element 0).
	.incbin "includes/generated/naka_direct_play.bin", 0x188A, 0x36
; [nakarest] NakaWidget_SongMdly2Group  +0x18c0..+0x18da (0xe2293c, 26 B)
; [nakarest] widget record, element 1 of Viewable slot 0x7a (table 0xe2433c, 12 entries,
; [nakarest] InitializeYoko) ("SqMdlyPly"): Box (26 B).
NakaWidget_SongMdly2Group:
	.incbin "includes/generated/naka_direct_play.bin", 0x18C0, 0x1A
; [nakarest] NakaWidget_SongMdly2Volume  +0x18da..+0x18fe (0xe22956, 36 B)
; [nakarest] widget record, element 2 of Viewable slot 0x7a (table 0xe2433c, 12 entries,
; [nakarest] InitializeYoko) ("SqMdlyPly"): AcTempoBox (36 B).
NakaWidget_SongMdly2Volume:
	.incbin "includes/generated/naka_direct_play.bin", 0x18DA, 0x24
; [nakarest] NakaWidget_SongMdly2SongList  +0x18fe..+0x191c (0xe2297a, 30 B)
; [nakarest] widget record, element 3 of Viewable slot 0x7a (table 0xe2433c, 12 entries,
; [nakarest] InitializeYoko) ("SqMdlyPly"): MeasureBox (30 B).
NakaWidget_SongMdly2SongList:
	.incbin "includes/generated/naka_direct_play.bin", 0x18FE, 0x1E
; [nakarest] NakaWidget_SongMdly2SongSel  +0x191c..+0x1940 (0xe22998, 36 B)
; [nakarest] widget record, element 4 of Viewable slot 0x7a (table 0xe2433c, 12 entries,
; [nakarest] InitializeYoko) ("SqMdlyPly"): TrTransposeBox (36 B).
NakaWidget_SongMdly2SongSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x191C, 0x24
; [nakarest] NakaWidget_SongMdly2RT1Sel  +0x1940..+0x196e (0xe229bc, 46 B)
; [nakarest] widget record, element 5 of Viewable slot 0x7a (table 0xe2433c, 12 entries,
; [nakarest] InitializeYoko) ("SqMdlyPly"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x7a (table 0xe2433c, 12 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 5).
NakaWidget_SongMdly2RT1Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1940, 0x2E
; [nakarest] NakaWidget_SongMdly2SkipLabel  +0x196e..+0x1994 (0xe229ea, 38 B)
; [nakarest] widget record, element 6 of Viewable slot 0x7a (table 0xe2433c, 12 entries,
; [nakarest] InitializeYoko) ("SqMdlyPly"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0x7a (table 0xe2433c, 12 entries, InitializeYoko)): "SKIP" (Label.str of
; [nakarest] element 6).
NakaWidget_SongMdly2SkipLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x196E, 0x26
; [nakarest] NakaWidget_SongMdly2MeasureBox  +0x1994..+0x19ae (0xe22a10, 26 B)
; [nakarest] widget record, element 7 of Viewable slot 0x7a (table 0xe2433c, 12 entries,
; [nakarest] InitializeYoko) ("SqMdlyPly"): IvMainEditSw (26 B).
NakaWidget_SongMdly2MeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x1994, 0x1A
; [nakarest] NakaWidget_SongMdly2FileList  +0x19ae..+0x19d2 (0xe22a2a, 36 B)
; [nakarest] widget record, element 8 of Viewable slot 0x7a (table 0xe2433c, 12 entries,
; [nakarest] InitializeYoko) ("SqMdlyPly"): AcCurSongNameBox (36 B).
NakaWidget_SongMdly2FileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x19AE, 0x24
; [nakarest] NakaWidget_SongMdly2MutePanel  +0x19d2..+0x19e8 (0xe22a4e, 22 B)
; [nakarest] widget record, element 9 of Viewable slot 0x7a (table 0xe2433c, 12 entries,
; [nakarest] InitializeYoko) ("SqMdlyPly"): IvTrackSwitch (22 B).
NakaWidget_SongMdly2MutePanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x19D2, 0x16
; [nakarest] NakaWidget_SongMdly2OffOnSel  +0x19e8..+0x19fe (0xe22a64, 22 B)
; [nakarest] widget record, element 10 of Viewable slot 0x7a (table 0xe2433c, 12 entries,
; [nakarest] InitializeYoko) ("SqMdlyPly"): IvExit (22 B).
NakaWidget_SongMdly2OffOnSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x19E8, 0x16
; [nakarest] NakaWidget_SongMdly2Mixer  +0x19fe..+0x1a36 (0xe22a7a, 56 B)
; [nakarest] widget record, element 11 of Viewable slot 0x7a (table 0xe2433c, 12 entries,
; [nakarest] InitializeYoko) ("SqMdlyPly"): VwMenuBox (50 B). 1 text the records point at
; [nakarest] (Viewable slot 0x7a (table 0xe2433c, 12 entries, InitializeYoko)): "MIXER"
; [nakarest] (VwMenuBox.str of element 11).
NakaWidget_SongMdly2Mixer:
	.incbin "includes/generated/naka_direct_play.bin", 0x19FE, 0x38
; [nakarest] NakaWidget_StepRecContainer  +0x1a36..+0x1a74 (0xe22ab2, 62 B)
; [nakarest] widget record, element 0 of Viewable slot 0x89 (table 0xe24370, 5 entries,
; [nakarest] InitializeYoko) ("SqTrSel"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x89 (table 0xe24370, 5 entries, InitializeYoko)): "STEP RECORD "
; [nakarest] (TtlScreen.title of element 0).
NakaWidget_StepRecContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x1A36, 0x3E
; [nakarest] NakaWidget_StepRecPartLabel  +0x1a74..+0x1aa2 (0xe22af0, 46 B)
; [nakarest] widget record, element 1 of Viewable slot 0x89 (table 0xe24370, 5 entries,
; [nakarest] InitializeYoko) ("SqTrSel"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0x89 (table 0xe24370, 5 entries, InitializeYoko)): ": PART SELECT" (Label.str
; [nakarest] of element 1).
NakaWidget_StepRecPartLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1A74, 0x2E
; [nakarest] NakaWidget_StepRecPartPanel  +0x1aa2..+0x1ab8 (0xe22b1e, 22 B)
; [nakarest] widget record, element 2 of Viewable slot 0x89 (table 0xe24370, 5 entries,
; [nakarest] InitializeYoko) ("SqTrSel"): IvTrackSwitch (22 B).
NakaWidget_StepRecPartPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AA2, 0x16
; [nakarest] NakaWidget_StepRecPartList  +0x1ab8..+0x1ae2 (0xe22b34, 42 B)
; [nakarest] widget record, element 3 of Viewable slot 0x89 (table 0xe24370, 5 entries,
; [nakarest] InitializeYoko) ("SqTrSel"): AcLanguageText (42 B).
NakaWidget_StepRecPartList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AB8, 0x2A
; [nakarest] NakaWidget_StepRecOrchRow  +0x1ae2..+0x1af8 (0xe22b5e, 22 B)
; [nakarest] widget record, element 4 of Viewable slot 0x89 (table 0xe24370, 5 entries,
; [nakarest] InitializeYoko) ("SqTrSel"): IvExitModeTrSel (22 B).
NakaWidget_StepRecOrchRow:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AE2, 0x16
; [nakarest] NakaWidget_StepRecSubPanel  +0x1af8..+0x1b1a (0xe22b74, 34 B)
; [nakarest] widget record, element 0 of Viewable slot 0x8a (table 0xe24388, 1 entries,
; [nakarest] InitializeYoko): IvDirmdScreen (34 B).
NakaWidget_StepRecSubPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1AF8, 0x22
; [nakarest] NakaWidget_TrAsContainer  +0x1b1a..+0x1b54 (0xe22b96, 58 B)
; [nakarest] widget record, element 0 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): TtlScreen (42 B). 1 text the records point at (Viewable
; [nakarest] slot 0x8b (table 0xe24390, 22 entries, InitializeYoko)): "TRACK ASSIGN "
; [nakarest] (TtlScreen.title of element 0).
NakaWidget_TrAsContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x1B1A, 0x3A
; [nakarest] NakaWidget_TrAsPresetItem  +0x1b54..+0x1b92 (0xe22bd0, 62 B)
; [nakarest] widget record, element 1 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): AcTitleMenu (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8b (table 0xe24390, 22 entries, InitializeYoko)): "PRESET"
; [nakarest] (AcTitleMenu.str of element 1).
NakaWidget_TrAsPresetItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x1B54, 0x3E
; [nakarest] NakaWidget_TrAsFileList  +0x1b92..+0x1bb8 (0xe22c0e, 38 B)
; [nakarest] widget record, element 2 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): AcCurrentSongBox (36 B).
NakaWidget_TrAsFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x1B92, 0x26
; [nakarest] NakaWidget_TrAsGridDisplay  +0x1bb8..+0x1c3e (0xe22c34, 134 B)
; [nakarest] widget record, element 4 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): AcTrAsGridBox (74 B). 2 texts the records point at
; [nakarest] (Viewable slot 0x8b (table 0xe24390, 22 entries, InitializeYoko)): "|-|TR 1|TR 2|TR
; [nakarest] 3|TR 4|TR 5|TR 6|TR 7|TR 8" (AcTrAsGridBox.fixedrow of element 4); " | | | "
; [nakarest] (AcTrAsGridBox.fixedcol of element 4).
NakaWidget_TrAsGridDisplay:
	.incbin "includes/generated/naka_direct_play.bin", 0x1BB8, 0x86
; [nakarest] NakaWidget_TrAsTrackAssign  +0x1c3e..+0x1c76 (0xe22cba, 56 B)
; [nakarest] widget record, element 5 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): TextBox (40 B). 1 text the records point at (Viewable
; [nakarest] slot 0x8b (table 0xe24390, 22 entries, InitializeYoko)): "TRACK~0DASSIGN"
; [nakarest] (TextBox.text of element 5).
NakaWidget_TrAsTrackAssign:
	.incbin "includes/generated/naka_direct_play.bin", 0x1C3E, 0x38
; [nakarest] NakaWidget_TrAsLocalCont  +0x1c76..+0x1cac (0xe22cf2, 54 B)
; [nakarest] widget record, element 6 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): TextBox (40 B). 1 text the records point at (Viewable
; [nakarest] slot 0x8b (table 0xe24390, 22 entries, InitializeYoko)): "LOCAL~0DCONT."
; [nakarest] (TextBox.text of element 6).
NakaWidget_TrAsLocalCont:
	.incbin "includes/generated/naka_direct_play.bin", 0x1C76, 0x36
; [nakarest] NakaWidget_TrAsMidiOut  +0x1cac..+0x1ce0 (0xe22d28, 52 B)
; [nakarest] widget record, element 7 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): TextBox (40 B). 1 text the records point at (Viewable
; [nakarest] slot 0x8b (table 0xe24390, 22 entries, InitializeYoko)): "MIDI~0DOUT" (TextBox.text
; [nakarest] of element 7).
NakaWidget_TrAsMidiOut:
	.incbin "includes/generated/naka_direct_play.bin", 0x1CAC, 0x34
; [nakarest] NakaWidget_TrAsMatrix  +0x1ce0..+0x1d0a (0xe22d5c, 42 B)
; [nakarest] widget record, element 8 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): AcIndexWideES (42 B).
NakaWidget_TrAsMatrix:
	.incbin "includes/generated/naka_direct_play.bin", 0x1CE0, 0x2A
; [nakarest] NakaWidget_TrAsRT1Toggle  +0x1d0a..+0x1d32 (0xe22d86, 40 B)
; [nakarest] widget record, element 10 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): AcIndexEditSw (40 B).
NakaWidget_TrAsRT1Toggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x1D0A, 0x28
; [nakarest] NakaWidget_TrAsRT2Toggle  +0x1d32..+0x1d5a (0xe22dae, 40 B)
; [nakarest] widget record, element 11 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): AcIndexEditSw (40 B).
NakaWidget_TrAsRT2Toggle:
	.incbin "includes/generated/naka_direct_play.bin", 0x1D32, 0x28
; [nakarest] NakaWidget_TrAsMeasureBox  +0x1d5a..+0x1d74 (0xe22dd6, 26 B)
; [nakarest] widget record, element 12 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): IvMainEditSw (26 B).
NakaWidget_TrAsMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x1D5A, 0x1A
; [nakarest] NakaWidget_TrAsSubContainer  +0x1d74..+0x1dac (0xe22df0, 56 B)
; [nakarest] widget record, element 13 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): TtlScreen (42 B). 1 text the records point at (Viewable
; [nakarest] slot 0x8b (table 0xe24390, 22 entries, InitializeYoko)): "TRACK ASSIGN"
; [nakarest] (TtlScreen.title of element 13).
NakaWidget_TrAsSubContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x1D74, 0x38
; [nakarest] NakaWidget_TrAsGroup  +0x1dac..+0x1dc6 (0xe22e28, 26 B)
; [nakarest] widget record, element 14 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): Box (26 B).
NakaWidget_TrAsGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x1DAC, 0x1A
; [nakarest] NakaWidget_TrAsPartList0  +0x1dc6..+0x1df0 (0xe22e42, 42 B)
; [nakarest] widget record, element 15 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): AcLanguageText (42 B).
NakaWidget_TrAsPartList0:
	.incbin "includes/generated/naka_direct_play.bin", 0x1DC6, 0x2A
; [nakarest] NakaWidget_TrAsPartList1  +0x1df0..+0x1e1a (0xe22e6c, 42 B)
; [nakarest] widget record, element 16 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): AcLanguageText (42 B).
NakaWidget_TrAsPartList1:
	.incbin "includes/generated/naka_direct_play.bin", 0x1DF0, 0x2A
; [nakarest] NakaWidget_TrAsPartList2  +0x1e1a..+0x1e44 (0xe22e96, 42 B)
; [nakarest] widget record, element 17 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): AcLanguageText (42 B).
NakaWidget_TrAsPartList2:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E1A, 0x2A
; [nakarest] NakaWidget_TrAsMeasureBox2  +0x1e44..+0x1e5e (0xe22ec0, 26 B)
; [nakarest] widget record, element 18 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): IvMainEditSw (26 B).
NakaWidget_TrAsMeasureBox2:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E44, 0x1A
; [nakarest] NakaWidget_TrAsRT1Selector  +0x1e5e..+0x1e8c (0xe22eda, 46 B)
; [nakarest] widget record, element 19 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8b (table 0xe24390, 22 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 19).
NakaWidget_TrAsRT1Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E5E, 0x2E
; [nakarest] NakaWidget_TrAsRT2Selector  +0x1e8c..+0x1eba (0xe22f08, 46 B)
; [nakarest] widget record, element 20 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8b (table 0xe24390, 22 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 20).
NakaWidget_TrAsRT2Selector:
	.incbin "includes/generated/naka_direct_play.bin", 0x1E8C, 0x2E
; [nakarest] NakaWidget_TrAsPresetSel  +0x1eba..+0x1ed4 (0xe22f36, 26 B)
; [nakarest] widget record, element 21 of Viewable slot 0x8b (table 0xe24390, 22 entries,
; [nakarest] InitializeYoko) ("SqTrAs"): IvExitScreen (26 B).
NakaWidget_TrAsPresetSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1EBA, 0x1A
; [nakarest] naka_direct_play+0x1ed4  +0x1ed4..+0x1f12 (0xe22f50, 62 B)
; [nakarest] widget record, element 0 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): "TRACK ASSIGN
; [nakarest] PRESET" (TtlScreen.title of element 0).
	.incbin "includes/generated/naka_direct_play.bin", 0x1ED4, 0x3E
; [nakarest] NakaWidget_TrAsPresetSong  +0x1f12..+0x1f38 (0xe22f8e, 38 B)
; [nakarest] widget record, element 1 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): "SONG" (Label.str of
; [nakarest] element 1).
NakaWidget_TrAsPresetSong:
	.incbin "includes/generated/naka_direct_play.bin", 0x1F12, 0x26
; [nakarest] NakaWidget_TrAsPresetMatrix  +0x1f38..+0x1f62 (0xe22fb4, 42 B)
; [nakarest] widget record, element 2 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): AcIndexWideES (42 B).
NakaWidget_TrAsPresetMatrix:
	.incbin "includes/generated/naka_direct_play.bin", 0x1F38, 0x2A
; [nakarest] NakaWidget_TrAsPresetPanel  +0x1f62..+0x1fa6 (0xe22fde, 68 B)
; [nakarest] widget record, element 3 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): AcRamEditBox (58 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): "SONG : "
; [nakarest] (AcRamEditBox.caption of element 3).
NakaWidget_TrAsPresetPanel:
	.incbin "includes/generated/naka_direct_play.bin", 0x1F62, 0x44
; [nakarest] NakaWidget_TrAsPresetInit  +0x1fa6..+0x1fe2 (0xe23022, 60 B)
; [nakarest] widget record, element 4 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): AcModeSelBox (52 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): "INITIAL"
; [nakarest] (AcModeSelBox.caption of element 4).
NakaWidget_TrAsPresetInit:
	.incbin "includes/generated/naka_direct_play.bin", 0x1FA6, 0x3C
; [nakarest] NakaWidget_TrAsPresetGmRec  +0x1fe2..+0x2030 (0xe2305e, 78 B)
; [nakarest] widget record, element 5 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): AcModeSelBox (52 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): "TECHNICS MULTI
; [nakarest] RECORDING" (AcModeSelBox.caption of element 5).
NakaWidget_TrAsPresetGmRec:
	.incbin "includes/generated/naka_direct_play.bin", 0x1FE2, 0x4E
; [nakarest] NakaWidget_TrAsPresetMeasure  +0x2030..+0x2078 (0xe230ac, 72 B)
; [nakarest] widget record, element 6 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): AcModeSelBox (52 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): "GM MULTI
; [nakarest] RECORDING" (AcModeSelBox.caption of element 6).
NakaWidget_TrAsPresetMeasure:
	.incbin "includes/generated/naka_direct_play.bin", 0x2030, 0x48
; [nakarest] NakaWidget_TrAsPresetRT2Sel  +0x2078..+0x2092 (0xe230f4, 26 B)
; [nakarest] widget record, element 7 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): IvMainEditSw (26 B).
NakaWidget_TrAsPresetRT2Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2078, 0x1A
; [nakarest] NakaWidget_TrAsPresetList  +0x2092..+0x20c0 (0xe2310e, 46 B)
; [nakarest] widget record, element 8 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 8).
NakaWidget_TrAsPresetList:
	.incbin "includes/generated/naka_direct_play.bin", 0x2092, 0x2E
; [nakarest] NakaWidget_TrAsPresetGroup  +0x20c0..+0x20ea (0xe2313c, 42 B)
; [nakarest] widget record, element 9 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): AcLanguageText (42 B).
NakaWidget_TrAsPresetGroup:
	.incbin "includes/generated/naka_direct_play.bin", 0x20C0, 0x2A
; [nakarest] NakaWidget_TrAsPresetContainer  +0x20ea..+0x2128 (0xe23166, 62 B)
; [nakarest] widget record, element 10 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): "TRACK ASSIGN
; [nakarest] PRESET" (TtlScreen.title of element 10).
NakaWidget_TrAsPresetContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x20EA, 0x3E
; [nakarest] NakaWidget_TrAsPresetMeasure2  +0x2128..+0x2142 (0xe231a4, 26 B)
; [nakarest] widget record, element 11 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): IvMainEditSw (26 B).
NakaWidget_TrAsPresetMeasure2:
	.incbin "includes/generated/naka_direct_play.bin", 0x2128, 0x1A
; [nakarest] NakaWidget_TrAsPresetRT1Sel  +0x2142..+0x2170 (0xe231be, 46 B)
; [nakarest] widget record, element 12 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 12).
NakaWidget_TrAsPresetRT1Sel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2142, 0x2E
; [nakarest] NakaWidget_TrAsPresetRT2Sel2  +0x2170..+0x219e (0xe231ec, 46 B)
; [nakarest] widget record, element 13 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 13).
NakaWidget_TrAsPresetRT2Sel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x2170, 0x2E
; [nakarest] NakaWidget_TrAsPresetGroup2  +0x219e..+0x21b8 (0xe2321a, 26 B)
; [nakarest] widget record, element 14 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): Box (26 B).
NakaWidget_TrAsPresetGroup2:
	.incbin "includes/generated/naka_direct_play.bin", 0x219E, 0x1A
; [nakarest] NakaWidget_TrAsPresetTypeSel  +0x21b8..+0x21d2 (0xe23234, 26 B)
; [nakarest] widget record, element 15 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): IvExitScreen (26 B).
NakaWidget_TrAsPresetTypeSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x21B8, 0x1A
; [nakarest] NakaWidget_TrAsPresetList2  +0x21d2..+0x21fc (0xe2324e, 42 B)
; [nakarest] widget record, element 16 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): AcLanguageText (42 B).
NakaWidget_TrAsPresetList2:
	.incbin "includes/generated/naka_direct_play.bin", 0x21D2, 0x2A
; [nakarest] NakaWidget_TrAsPresetList3  +0x21fc..+0x2226 (0xe23278, 42 B)
; [nakarest] widget record, element 17 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): AcLanguageText (42 B).
NakaWidget_TrAsPresetList3:
	.incbin "includes/generated/naka_direct_play.bin", 0x21FC, 0x2A
; [nakarest] NakaWidget_TrAsPresetList4  +0x2226..+0x2250 (0xe232a2, 42 B)
; [nakarest] widget record, element 18 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): AcLanguageText (42 B).
NakaWidget_TrAsPresetList4:
	.incbin "includes/generated/naka_direct_play.bin", 0x2226, 0x2A
; [nakarest] NakaWidget_TrAsPresetContainer2  +0x2250..+0x228e (0xe232cc, 62 B)
; [nakarest] widget record, element 19 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): "TRACK ASSIGN
; [nakarest] PRESET" (TtlScreen.title of element 19).
NakaWidget_TrAsPresetContainer2:
	.incbin "includes/generated/naka_direct_play.bin", 0x2250, 0x3E
; [nakarest] NakaWidget_TrAsPresetGroup3  +0x228e..+0x22a8 (0xe2330a, 26 B)
; [nakarest] widget record, element 20 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): Box (26 B).
NakaWidget_TrAsPresetGroup3:
	.incbin "includes/generated/naka_direct_play.bin", 0x228E, 0x1A
; [nakarest] NakaWidget_TrAsPresetTypeSel2  +0x22a8..+0x22c2 (0xe23324, 26 B)
; [nakarest] widget record, element 21 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): IvExitScreen (26 B).
NakaWidget_TrAsPresetTypeSel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x22A8, 0x1A
; [nakarest] NakaWidget_TrAsPresetList5  +0x22c2..+0x22ec (0xe2333e, 42 B)
; [nakarest] widget record, element 22 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): AcLanguageText (42 B).
NakaWidget_TrAsPresetList5:
	.incbin "includes/generated/naka_direct_play.bin", 0x22C2, 0x2A
; [nakarest] NakaWidget_TrAsPresetList6  +0x22ec..+0x2316 (0xe23368, 42 B)
; [nakarest] widget record, element 23 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): AcLanguageText (42 B).
NakaWidget_TrAsPresetList6:
	.incbin "includes/generated/naka_direct_play.bin", 0x22EC, 0x2A
; [nakarest] NakaWidget_TrAsPresetList7  +0x2316..+0x2340 (0xe23392, 42 B)
; [nakarest] widget record, element 24 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): AcLanguageText (42 B).
NakaWidget_TrAsPresetList7:
	.incbin "includes/generated/naka_direct_play.bin", 0x2316, 0x2A
; [nakarest] NakaWidget_TrAsPresetMeasure3  +0x2340..+0x235a (0xe233bc, 26 B)
; [nakarest] widget record, element 25 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): IvMainEditSw (26 B).
NakaWidget_TrAsPresetMeasure3:
	.incbin "includes/generated/naka_direct_play.bin", 0x2340, 0x1A
; [nakarest] NakaWidget_TrAsPresetRT1Sel2  +0x235a..+0x2388 (0xe233d6, 46 B)
; [nakarest] widget record, element 26 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 26).
NakaWidget_TrAsPresetRT1Sel2:
	.incbin "includes/generated/naka_direct_play.bin", 0x235A, 0x2E
; [nakarest] NakaWidget_TrAsPresetRT2Sel3  +0x2388..+0x23b6 (0xe23404, 46 B)
; [nakarest] widget record, element 27 of Viewable slot 0x8c (table 0xe243ec, 28 entries,
; [nakarest] InitializeYoko) ("SqTrAsPs"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8c (table 0xe243ec, 28 entries, InitializeYoko)): ""
; [nakarest] (VwEditSwBox.str of element 27).
NakaWidget_TrAsPresetRT2Sel3:
	.incbin "includes/generated/naka_direct_play.bin", 0x2388, 0x2E
; [nakarest] NakaWidget_SongSelNamContainer  +0x23b6..+0x23f4 (0xe23432, 62 B)
; [nakarest] widget record, element 0 of Viewable slot 0x8e (table 0xe24460, 5 entries,
; [nakarest] InitializeYoko) ("SqSngSel"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8e (table 0xe24460, 5 entries, InitializeYoko)): "SONG
; [nakarest] SELECT/NAMING" (TtlScreen.title of element 0).
NakaWidget_SongSelNamContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x23B6, 0x3E
; [nakarest] NakaWidget_SongSelNamNameItem  +0x23f4..+0x2432 (0xe23470, 62 B)
; [nakarest] widget record, element 1 of Viewable slot 0x8e (table 0xe24460, 5 entries,
; [nakarest] InitializeYoko) ("SqSngSel"): AcTitleMenu (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8e (table 0xe24460, 5 entries, InitializeYoko)): "NAMING"
; [nakarest] (AcTitleMenu.str of element 1).
NakaWidget_SongSelNamNameItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x23F4, 0x3E
; [nakarest] NakaWidget_SongSelNamSongSel  +0x2432..+0x2464 (0xe234ae, 50 B)
; [nakarest] widget record, element 2 of Viewable slot 0x8e (table 0xe24460, 5 entries,
; [nakarest] InitializeYoko) ("SqSngSel"): PsSongSelBox (50 B).
NakaWidget_SongSelNamSongSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2432, 0x32
; [nakarest] NakaWidget_SongSelNamNameEdit  +0x2464..+0x2496 (0xe234e0, 50 B)
; [nakarest] widget record, element 3 of Viewable slot 0x8e (table 0xe24460, 5 entries,
; [nakarest] InitializeYoko) ("SqSngSel"): PsSongSelBox (50 B).
NakaWidget_SongSelNamNameEdit:
	.incbin "includes/generated/naka_direct_play.bin", 0x2464, 0x32
; [nakarest] NakaWidget_SongSelNamDuration  +0x2496..+0x24c0 (0xe23512, 42 B)
; [nakarest] widget record, element 4 of Viewable slot 0x8e (table 0xe24460, 5 entries,
; [nakarest] InitializeYoko) ("SqSngSel"): AcIndexWideES (42 B).
NakaWidget_SongSelNamDuration:
	.incbin "includes/generated/naka_direct_play.bin", 0x2496, 0x2A
; [nakarest] NakaWidget_NamingContainer  +0x24c0..+0x24f2 (0xe2353c, 50 B)
; [nakarest] widget record, element 0 of Viewable slot 0x8f (table 0xe24478, 6 entries,
; [nakarest] InitializeYoko) ("SqNameing"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x8f (table 0xe24478, 6 entries, InitializeYoko)): "NAMING"
; [nakarest] (TtlScreen.title of element 0).
NakaWidget_NamingContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x24C0, 0x32
; [nakarest] NakaWidget_NamingCharSel  +0x24f2..+0x2516 (0xe2356e, 36 B)
; [nakarest] widget record, element 1 of Viewable slot 0x8f (table 0xe24478, 6 entries,
; [nakarest] InitializeYoko) ("SqNameing"): AcCurrentSongBox (36 B).
NakaWidget_NamingCharSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x24F2, 0x24
; [nakarest] NakaWidget_NamingSeqLabel  +0x2516..+0x2548 (0xe23592, 50 B)
; [nakarest] widget record, element 2 of Viewable slot 0x8f (table 0xe24478, 6 entries,
; [nakarest] InitializeYoko) ("SqNameing"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0x8f (table 0xe24478, 6 entries, InitializeYoko)): "SEQUENCER :" (Label.str of
; [nakarest] element 2).
NakaWidget_NamingSeqLabel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2516, 0x32
; [nakarest] NakaWidget_NamingMeasureBox  +0x2548..+0x2562 (0xe235c4, 26 B)
; [nakarest] widget record, element 3 of Viewable slot 0x8f (table 0xe24478, 6 entries,
; [nakarest] InitializeYoko) ("SqNameing"): IvNaming (26 B).
NakaWidget_NamingMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x2548, 0x1A
; [nakarest] NakaWidget_NamingDisplayMode  +0x2562..+0x258e (0xe235de, 44 B)
; [nakarest] widget record, element 4 of Viewable slot 0x8f (table 0xe24478, 6 entries,
; [nakarest] InitializeYoko) ("SqNameing"): AcFuncEditSw (44 B).
NakaWidget_NamingDisplayMode:
	.incbin "includes/generated/naka_direct_play.bin", 0x2562, 0x2C
; [nakarest] NakaWidget_NamingOrchRow  +0x258e..+0x25a4 (0xe2360a, 22 B)
; [nakarest] widget record, element 5 of Viewable slot 0x8f (table 0xe24478, 6 entries,
; [nakarest] InitializeYoko) ("SqNameing"): IvNamingExit (22 B).
NakaWidget_NamingOrchRow:
	.incbin "includes/generated/naka_direct_play.bin", 0x258E, 0x16
; [nakarest] naka_direct_play+0x25a4  +0x25a4..+0x25e2 (0xe23620, 62 B)
; [nakarest] widget record, element 0 of Viewable slot 0x92 (table 0xe24494, 4 entries,
; [nakarest] InitializeYoko) ("AfterTouchSet"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0x92 (table 0xe24494, 4 entries, InitializeYoko)): "AFTER TOUCH
; [nakarest] SETTING" (TtlScreen.title of element 0).
	.incbin "includes/generated/naka_direct_play.bin", 0x25A4, 0x3E
; [nakarest] NakaWidget_AftTouchDuration  +0x25e2..+0x260c (0xe2365e, 42 B)
; [nakarest] widget record, element 1 of Viewable slot 0x92 (table 0xe24494, 4 entries,
; [nakarest] InitializeYoko) ("AfterTouchSet"): AcIndexWideES (42 B).
NakaWidget_AftTouchDuration:
	.incbin "includes/generated/naka_direct_play.bin", 0x25E2, 0x2A
; [nakarest] NakaWidget_AftTouchChSel  +0x260c..+0x265e (0xe23688, 82 B)
; [nakarest] widget record, element 2 of Viewable slot 0x92 (table 0xe24494, 4 entries,
; [nakarest] InitializeYoko) ("AfterTouchSet"): AcBitEditBox (58 B). 1 text the records point at
; [nakarest] (Viewable slot 0x92 (table 0xe24494, 4 entries, InitializeYoko)): " AFTER TOUCH
; [nakarest] RECORD :" (AcBitEditBox.caption of element 2).
NakaWidget_AftTouchChSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x260C, 0x52
; [nakarest] NakaWidget_AftTouchList  +0x265e..+0x2688 (0xe236da, 42 B)
; [nakarest] widget record, element 3 of Viewable slot 0x92 (table 0xe24494, 4 entries,
; [nakarest] InitializeYoko) ("AfterTouchSet"): AcLanguageText (42 B).
NakaWidget_AftTouchList:
	.incbin "includes/generated/naka_direct_play.bin", 0x265E, 0x2A
; [nakarest] naka_direct_play+0x2688  +0x2688..+0x26c0 (0xe23704, 56 B)
; [nakarest] widget record, element 0 of Viewable slot 0xa9 (table 0xe244ac, 6 entries,
; [nakarest] InitializeYoko) ("StepPartBal"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xa9 (table 0xe244ac, 6 entries, InitializeYoko)): "PART BALANCE"
; [nakarest] (TtlScreen.title of element 0).
	.incbin "includes/generated/naka_direct_play.bin", 0x2688, 0x38
; [nakarest] NakaWidget_PartBal0  +0x26c0..+0x26e0 (0xe2373c, 32 B)
; [nakarest] widget record, element 1 of Viewable slot 0xa9 (table 0xe244ac, 6 entries,
; [nakarest] InitializeYoko) ("StepPartBal"): AcMixerVol (32 B).
NakaWidget_PartBal0:
	.incbin "includes/generated/naka_direct_play.bin", 0x26C0, 0x20
; [nakarest] NakaWidget_PartBal1  +0x26e0..+0x2700 (0xe2375c, 32 B)
; [nakarest] widget record, element 2 of Viewable slot 0xa9 (table 0xe244ac, 6 entries,
; [nakarest] InitializeYoko) ("StepPartBal"): AcMixerVol (32 B).
NakaWidget_PartBal1:
	.incbin "includes/generated/naka_direct_play.bin", 0x26E0, 0x20
; [nakarest] NakaWidget_PartBal2  +0x2700..+0x2720 (0xe2377c, 32 B)
; [nakarest] widget record, element 3 of Viewable slot 0xa9 (table 0xe244ac, 6 entries,
; [nakarest] InitializeYoko) ("StepPartBal"): AcMixerVol (32 B).
NakaWidget_PartBal2:
	.incbin "includes/generated/naka_direct_play.bin", 0x2700, 0x20
; [nakarest] NakaWidget_PartBal3  +0x2720..+0x2740 (0xe2379c, 32 B)
; [nakarest] widget record, element 4 of Viewable slot 0xa9 (table 0xe244ac, 6 entries,
; [nakarest] InitializeYoko) ("StepPartBal"): AcMixerVol (32 B).
NakaWidget_PartBal3:
	.incbin "includes/generated/naka_direct_play.bin", 0x2720, 0x20
; [nakarest] NakaWidget_PartBal4  +0x2740..+0x2760 (0xe237bc, 32 B)
; [nakarest] widget record, element 5 of Viewable slot 0xa9 (table 0xe244ac, 6 entries,
; [nakarest] InitializeYoko) ("StepPartBal"): AcMixerVol (32 B).
NakaWidget_PartBal4:
	.incbin "includes/generated/naka_direct_play.bin", 0x2740, 0x20
; [nakarest] NakaWidget_DemoContainer  +0x2760..+0x2798 (0xe237dc, 56 B)
; [nakarest] widget record, element 0 of Viewable slot 0xe0 (table 0xe244c8, 4 entries,
; [nakarest] InitializeYoko) ("DemoMenu"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe0 (table 0xe244c8, 4 entries, InitializeYoko)): "DEMONSTRATION"
; [nakarest] (TtlScreen.title of element 0).
NakaWidget_DemoContainer:
	.incbin "includes/generated/naka_direct_play.bin", 0x2760, 0x38
; [nakarest] NakaWidget_DemoPerfItem  +0x2798..+0x27dc (0xe23814, 68 B)
; [nakarest] widget record, element 1 of Viewable slot 0xe0 (table 0xe244c8, 4 entries,
; [nakarest] InitializeYoko) ("DemoMenu"): AcTitleMenu (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe0 (table 0xe244c8, 4 entries, InitializeYoko)): "PERFORMANCES"
; [nakarest] (AcTitleMenu.str of element 1).
NakaWidget_DemoPerfItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x2798, 0x44
; [nakarest] NakaWidget_DemoFeatPresItem  +0x27dc..+0x2828 (0xe23858, 76 B)
; [nakarest] widget record, element 2 of Viewable slot 0xe0 (table 0xe244c8, 4 entries,
; [nakarest] InitializeYoko) ("DemoMenu"): AcTitleMenu (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe0 (table 0xe244c8, 4 entries, InitializeYoko)): "FEATURE
; [nakarest] PRESENTATION" (AcTitleMenu.str of element 2).
NakaWidget_DemoFeatPresItem:
	.incbin "includes/generated/naka_direct_play.bin", 0x27DC, 0x4C
; [nakarest] NakaWidget_DemoMeasureBox  +0x2828..+0x2842 (0xe238a4, 26 B)
; [nakarest] widget record, element 3 of Viewable slot 0xe0 (table 0xe244c8, 4 entries,
; [nakarest] InitializeYoko) ("DemoMenu"): IvExitMode (26 B).
NakaWidget_DemoMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x2828, 0x1A
; [nakarest] naka_direct_play+0x2842  +0x2842..+0x287a (0xe238be, 56 B)
; [nakarest] widget record, element 0 of Viewable slot 0xe1 (table 0xe244dc, 12 entries,
; [nakarest] InitializeYoko) ("DemoStyle"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe1 (table 0xe244dc, 12 entries, InitializeYoko)): "PERFORMANCES"
; [nakarest] (TtlScreen.title of element 0).
	.incbin "includes/generated/naka_direct_play.bin", 0x2842, 0x38
; [nakarest] NakaWidget_PerfMainMedley  +0x287a..+0x28bc (0xe238f6, 66 B)
; [nakarest] widget record, element 1 of Viewable slot 0xe1 (table 0xe244dc, 12 entries,
; [nakarest] InitializeYoko) ("DemoStyle"): AcDemoSongBox (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe1 (table 0xe244dc, 12 entries, InitializeYoko)): "Main Medley"
; [nakarest] (AcDemoSongBox.caption of element 1).
NakaWidget_PerfMainMedley:
	.incbin "includes/generated/naka_direct_play.bin", 0x287A, 0x42
; [nakarest] NakaWidget_PerfAccordionMedley  +0x28bc..+0x2904 (0xe23938, 72 B)
; [nakarest] widget record, element 2 of Viewable slot 0xe1 (table 0xe244dc, 12 entries,
; [nakarest] InitializeYoko) ("DemoStyle"): AcDemoSongBox (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe1 (table 0xe244dc, 12 entries, InitializeYoko)): "Accordion
; [nakarest] Medley" (AcDemoSongBox.caption of element 2).
NakaWidget_PerfAccordionMedley:
	.incbin "includes/generated/naka_direct_play.bin", 0x28BC, 0x48
; [nakarest] NakaWidget_PerfFolkMedley  +0x2904..+0x2946 (0xe23980, 66 B)
; [nakarest] widget record, element 3 of Viewable slot 0xe1 (table 0xe244dc, 12 entries,
; [nakarest] InitializeYoko) ("DemoStyle"): AcDemoSongBox (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe1 (table 0xe244dc, 12 entries, InitializeYoko)): "Folk Medley"
; [nakarest] (AcDemoSongBox.caption of element 3).
NakaWidget_PerfFolkMedley:
	.incbin "includes/generated/naka_direct_play.bin", 0x2904, 0x42
; [nakarest] NakaWidget_PerfClassical  +0x2946..+0x2986 (0xe239c2, 64 B)
; [nakarest] widget record, element 4 of Viewable slot 0xe1 (table 0xe244dc, 12 entries,
; [nakarest] InitializeYoko) ("DemoStyle"): AcDemoSongBox (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe1 (table 0xe244dc, 12 entries, InitializeYoko)): "Classical"
; [nakarest] (AcDemoSongBox.caption of element 4).
NakaWidget_PerfClassical:
	.incbin "includes/generated/naka_direct_play.bin", 0x2946, 0x40
; [nakarest] NakaWidget_PerfShow  +0x2986..+0x29c2 (0xe23a02, 60 B)
; [nakarest] widget record, element 5 of Viewable slot 0xe1 (table 0xe244dc, 12 entries,
; [nakarest] InitializeYoko) ("DemoStyle"): AcDemoSongBox (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe1 (table 0xe244dc, 12 entries, InitializeYoko)): "Show"
; [nakarest] (AcDemoSongBox.caption of element 5).
NakaWidget_PerfShow:
	.incbin "includes/generated/naka_direct_play.bin", 0x2986, 0x3C
; [nakarest] NakaWidget_PerfContemporary  +0x29c2..+0x2a06 (0xe23a3e, 68 B)
; [nakarest] widget record, element 6 of Viewable slot 0xe1 (table 0xe244dc, 12 entries,
; [nakarest] InitializeYoko) ("DemoStyle"): AcDemoSongBox (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe1 (table 0xe244dc, 12 entries, InitializeYoko)): "Contemporary"
; [nakarest] (AcDemoSongBox.caption of element 6).
NakaWidget_PerfContemporary:
	.incbin "includes/generated/naka_direct_play.bin", 0x29C2, 0x44
; [nakarest] NakaWidget_PerfStyleSel  +0x2a06..+0x2a3c (0xe23a82, 54 B)
; [nakarest] widget record, element 7 of Viewable slot 0xe1 (table 0xe244dc, 12 entries,
; [nakarest] InitializeYoko) ("DemoStyle"): PsWideToggle (42 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xe1 (table 0xe244dc, 12 entries, InitializeYoko)): "STYLE"
; [nakarest] (PsWideToggle.stroff of element 7); "STYLE" (PsWideToggle.stron of element 7).
NakaWidget_PerfStyleSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2A06, 0x36
; [nakarest] NakaWidget_PerfSoundSel  +0x2a3c..+0x2a72 (0xe23ab8, 54 B)
; [nakarest] widget record, element 8 of Viewable slot 0xe1 (table 0xe244dc, 12 entries,
; [nakarest] InitializeYoko) ("DemoStyle"): PsWideToggle (42 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xe1 (table 0xe244dc, 12 entries, InitializeYoko)): "SOUND"
; [nakarest] (PsWideToggle.stroff of element 8); "SOUND" (PsWideToggle.stron of element 8).
NakaWidget_PerfSoundSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2A3C, 0x36
; [nakarest] NakaWidget_PerfRhythmSel  +0x2a72..+0x2aac (0xe23aee, 58 B)
; [nakarest] widget record, element 9 of Viewable slot 0xe1 (table 0xe244dc, 12 entries,
; [nakarest] InitializeYoko) ("DemoStyle"): PsWideToggle (42 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xe1 (table 0xe244dc, 12 entries, InitializeYoko)): "RHYTHM"
; [nakarest] (PsWideToggle.stroff of element 9); "RHYTHM" (PsWideToggle.stron of element 9).
NakaWidget_PerfRhythmSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2A72, 0x3A
; [nakarest] NakaWidget_PerfMeasureBox  +0x2aac..+0x2ac6 (0xe23b28, 26 B)
; [nakarest] widget record, element 10 of Viewable slot 0xe1 (table 0xe244dc, 12 entries,
; [nakarest] InitializeYoko) ("DemoStyle"): IvMainEditSw (26 B).
NakaWidget_PerfMeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x2AAC, 0x1A
; [nakarest] NakaWidget_PerfFileList  +0x2ac6..+0x2aea (0xe23b42, 36 B)
; [nakarest] widget record, element 11 of Viewable slot 0xe1 (table 0xe244dc, 12 entries,
; [nakarest] InitializeYoko) ("DemoStyle"): AcDemoMedleyDispBox (36 B).
NakaWidget_PerfFileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x2AC6, 0x24
; [nakarest] NakaWidget_Perf2Container  +0x2aea..+0x2b22 (0xe23b66, 56 B)
; [nakarest] widget record, element 0 of Viewable slot 0xe2 (table 0xe24510, 12 entries,
; [nakarest] InitializeYoko) ("DemoSound"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe2 (table 0xe24510, 12 entries, InitializeYoko)): "PERFORMANCES"
; [nakarest] (TtlScreen.title of element 0).
NakaWidget_Perf2Container:
	.incbin "includes/generated/naka_direct_play.bin", 0x2AEA, 0x38
; [nakarest] NakaWidget_Perf2Strings  +0x2b22..+0x2b60 (0xe23b9e, 62 B)
; [nakarest] widget record, element 1 of Viewable slot 0xe2 (table 0xe24510, 12 entries,
; [nakarest] InitializeYoko) ("DemoSound"): AcDemoSongBox (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe2 (table 0xe24510, 12 entries, InitializeYoko)): "Strings"
; [nakarest] (AcDemoSongBox.caption of element 1).
NakaWidget_Perf2Strings:
	.incbin "includes/generated/naka_direct_play.bin", 0x2B22, 0x3E
; [nakarest] NakaWidget_Perf2Gamelan  +0x2b60..+0x2bdc (0xe23bdc, 124 B)
; [nakarest] widget records, elements 2-3 of Viewable slot 0xe2 (table 0xe24510, 12 entries,
; [nakarest] InitializeYoko) ("DemoSound"): AcDemoSongBox (54 B) x2. 2 texts the records point
; [nakarest] at (Viewable slot 0xe2 (table 0xe24510, 12 entries, InitializeYoko)): "Gamelan"
; [nakarest] (AcDemoSongBox.caption of element 2); "Guitar" (AcDemoSongBox.caption of element
; [nakarest] 3).
NakaWidget_Perf2Gamelan:
	.incbin "includes/generated/naka_direct_play.bin", 0x2B60, 0x7C
; [nakarest] NakaWidget_Perf2Guitar  +0x2bdc..+0x2c18 (0xe23c58, 60 B)
; [nakarest] widget record, element 4 of Viewable slot 0xe2 (table 0xe24510, 12 entries,
; [nakarest] InitializeYoko) ("DemoSound"): AcDemoSongBox (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe2 (table 0xe24510, 12 entries, InitializeYoko)): "Piano"
; [nakarest] (AcDemoSongBox.caption of element 4).
NakaWidget_Perf2Guitar:
	.incbin "includes/generated/naka_direct_play.bin", 0x2BDC, 0x3C
; [nakarest] NakaWidget_Perf2SaxBrass  +0x2c18..+0x2c94 (0xe23c94, 124 B)
; [nakarest] widget records, elements 5-6 of Viewable slot 0xe2 (table 0xe24510, 12 entries,
; [nakarest] InitializeYoko) ("DemoSound"): AcDemoSongBox (54 B) x2. 2 texts the records point
; [nakarest] at (Viewable slot 0xe2 (table 0xe24510, 12 entries, InitializeYoko)): "Sax&Brass"
; [nakarest] (AcDemoSongBox.caption of element 5); "Organ" (AcDemoSongBox.caption of element 6).
NakaWidget_Perf2SaxBrass:
	.incbin "includes/generated/naka_direct_play.bin", 0x2C18, 0x7C
; [nakarest] NakaWidget_Perf2StyleSel  +0x2c94..+0x2cca (0xe23d10, 54 B)
; [nakarest] widget record, element 7 of Viewable slot 0xe2 (table 0xe24510, 12 entries,
; [nakarest] InitializeYoko) ("DemoSound"): PsWideToggle (42 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xe2 (table 0xe24510, 12 entries, InitializeYoko)): "STYLE"
; [nakarest] (PsWideToggle.stroff of element 7); "STYLE" (PsWideToggle.stron of element 7).
NakaWidget_Perf2StyleSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2C94, 0x36
; [nakarest] NakaWidget_Perf2SoundSel  +0x2cca..+0x2d00 (0xe23d46, 54 B)
; [nakarest] widget record, element 8 of Viewable slot 0xe2 (table 0xe24510, 12 entries,
; [nakarest] InitializeYoko) ("DemoSound"): PsWideToggle (42 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xe2 (table 0xe24510, 12 entries, InitializeYoko)): "SOUND"
; [nakarest] (PsWideToggle.stroff of element 8); "SOUND" (PsWideToggle.stron of element 8).
NakaWidget_Perf2SoundSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2CCA, 0x36
; [nakarest] NakaWidget_Perf2RhythmSel  +0x2d00..+0x2d3a (0xe23d7c, 58 B)
; [nakarest] widget record, element 9 of Viewable slot 0xe2 (table 0xe24510, 12 entries,
; [nakarest] InitializeYoko) ("DemoSound"): PsWideToggle (42 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xe2 (table 0xe24510, 12 entries, InitializeYoko)): "RHYTHM"
; [nakarest] (PsWideToggle.stroff of element 9); "RHYTHM" (PsWideToggle.stron of element 9).
NakaWidget_Perf2RhythmSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2D00, 0x3A
; [nakarest] NakaWidget_Perf2MeasureBox  +0x2d3a..+0x2d54 (0xe23db6, 26 B)
; [nakarest] widget record, element 10 of Viewable slot 0xe2 (table 0xe24510, 12 entries,
; [nakarest] InitializeYoko) ("DemoSound"): IvMainEditSw (26 B).
NakaWidget_Perf2MeasureBox:
	.incbin "includes/generated/naka_direct_play.bin", 0x2D3A, 0x1A
; [nakarest] NakaWidget_Perf2FileList  +0x2d54..+0x2d78 (0xe23dd0, 36 B)
; [nakarest] widget record, element 11 of Viewable slot 0xe2 (table 0xe24510, 12 entries,
; [nakarest] InitializeYoko) ("DemoSound"): AcDemoMedleyDispBox (36 B).
NakaWidget_Perf2FileList:
	.incbin "includes/generated/naka_direct_play.bin", 0x2D54, 0x24
; [nakarest] naka_direct_play+0x2d78  +0x2d78..+0x2db0 (0xe23df4, 56 B)
; [nakarest] widget record, element 0 of Viewable slot 0xe3 (table 0xe24544, 12 entries,
; [nakarest] InitializeYoko) ("DemoRhy"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe3 (table 0xe24544, 12 entries, InitializeYoko)): "PERFORMANCES"
; [nakarest] (TtlScreen.title of element 0).
	.incbin "includes/generated/naka_direct_play.bin", 0x2D78, 0x38
; [nakarest] NakaWidget_Perf3HokieDance  +0x2db0..+0x2f04 (0xe23e2c, 340 B)
; [nakarest] widget records, elements 1-5 of Viewable slot 0xe3 (table 0xe24544, 12 entries,
; [nakarest] InitializeYoko) ("DemoRhy"): AcDemoSongBox (54 B) x5. 5 texts the records point at
; [nakarest] (Viewable slot 0xe3 (table 0xe24544, 12 entries, InitializeYoko)): "Hokie Dance"
; [nakarest] (AcDemoSongBox.caption of element 1); "Gospel Revival" (AcDemoSongBox.caption of
; [nakarest] element 2); "Organ Combo" (AcDemoSongBox.caption of element 3); "Big Band Mid"
; [nakarest] (AcDemoSongBox.caption of element 4); ....
NakaWidget_Perf3HokieDance:
	.incbin "includes/generated/naka_direct_play.bin", 0x2DB0, 0x154
; [nakarest] NakaWidget_Perf3ModernBluegrass  +0x2f04..+0x2f4c (0xe23f80, 72 B)
; [nakarest] widget record, element 6 of Viewable slot 0xe3 (table 0xe24544, 12 entries,
; [nakarest] InitializeYoko) ("DemoRhy"): AcDemoSongBox (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xe3 (table 0xe24544, 12 entries, InitializeYoko)): "Modern
; [nakarest] Bluegrass" (AcDemoSongBox.caption of element 6).
NakaWidget_Perf3ModernBluegrass:
	.incbin "includes/generated/naka_direct_play.bin", 0x2F04, 0x48
; [nakarest] NakaWidget_Perf3StyleSel  +0x2f4c..+0x2f82 (0xe23fc8, 54 B)
; [nakarest] widget record, element 7 of Viewable slot 0xe3 (table 0xe24544, 12 entries,
; [nakarest] InitializeYoko) ("DemoRhy"): PsWideToggle (42 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xe3 (table 0xe24544, 12 entries, InitializeYoko)): "STYLE"
; [nakarest] (PsWideToggle.stroff of element 7); "STYLE" (PsWideToggle.stron of element 7).
NakaWidget_Perf3StyleSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2F4C, 0x36
; [nakarest] NakaWidget_Perf3SoundSel  +0x2f82..+0x2fb8 (0xe23ffe, 54 B)
; [nakarest] widget record, element 8 of Viewable slot 0xe3 (table 0xe24544, 12 entries,
; [nakarest] InitializeYoko) ("DemoRhy"): PsWideToggle (42 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xe3 (table 0xe24544, 12 entries, InitializeYoko)): "SOUND"
; [nakarest] (PsWideToggle.stroff of element 8); "SOUND" (PsWideToggle.stron of element 8).
NakaWidget_Perf3SoundSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2F82, 0x36
; [nakarest] NakaWidget_Perf3RhythmSel  +0x2fb8..+0x2fda (0xe24034, 34 B)
; [nakarest] widget record, element 9 of Viewable slot 0xe3 (table 0xe24544, 12 entries,
; [nakarest] InitializeYoko) ("DemoRhy"): PsWideToggle (42 B).
NakaWidget_Perf3RhythmSel:
	.incbin "includes/generated/naka_direct_play.bin", 0x2FB8, 0x22
; External label offsets within the binary blob above.
