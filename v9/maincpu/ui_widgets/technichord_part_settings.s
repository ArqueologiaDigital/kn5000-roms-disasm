
; Technichord Part Settings screen widgets (221 widgets, 17024 bytes)
; Source: maincpu/ui_widgets/naka_technichord_part.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_technichord_part
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
; Viewable slot 0x2: RegObjTabl 0x1600010, ViewableProc, 0x14, 0xe85470,
; 0x2 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 20, table} at 0x27ed2 +
; 14*0x2. Element 0 is named "Sdmenu" in ResName slot 0x302. Links: all
; 20 records consistent.
;
; Viewable slot 0x3: RegObjTabl 0x1600010, ViewableProc, 0x54, 0xe854c4,
; 0x3 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 84, table} at 0x27ed2 +
; 14*0x3. Element 0 is named "Sdpart" in ResName slot 0x303. Links: all
; 84 records consistent.
;
; Viewable slot 0x4: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe85618,
; 0x4 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x4. Element 0 is named "Sdmtune" in ResName slot 0x304. Links: all
; 4 records consistent.
;
; Viewable slot 0x5: RegObjTabl 0x1600010, ViewableProc, 0x36, 0xe8562c,
; 0x5 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 54, table} at 0x27ed2 +
; 14*0x5. Element 0 is named "Sdscltyp" in ResName slot 0x305. Links:
; all 54 records consistent.
;
; Viewable slot 0x7: RegObjTabl 0x1600010, ViewableProc, 0x3, 0xe85708,
; 0x7 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 3, table} at 0x27ed2 +
; 14*0x7. Element 0 is named "Sdlfthld" in ResName slot 0x307. Links:
; all 3 records consistent.
;
; Viewable slot 0x8: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe85718,
; 0x8 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x8. Element 0 is named "Sdmixer" in ResName slot 0x308. Links: all
; 4 records consistent.
;
; Viewable slot 0xd: RegObjTabl 0x1600010, ViewableProc, 0x1d, 0xe8572c,
; 0xd in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 29, table} at 0x27ed2 +
; 14*0xd. Element 0 is named "Sdtecd" in ResName slot 0x30d. Links: all
; 29 records consistent.
;
; Viewable slot 0xa5: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe857a4,
; 0xa5 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0xa5. Element 0 is named "Sqmixer" in ResName slot 0x3a5. Links:
; all 4 records consistent.
;
; Viewable slot 0xe4: RegObjTabl 0x1600010, ViewableProc, 0xf, 0xe857b8,
; 0xe4 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 15, table} at 0x27ed2 +
; 14*0xe4. Element 0 is named "Demofeature" in ResName slot 0x3e4.
; Links: all 15 records consistent.
;
; Viewable slot 0xea: RegObjTabl 0x1600010, ViewableProc, 0x2c,
; 0xe857f8, 0xea in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 44, table} at 0x27ed2 +
; 14*0xea. Element 0 is named "Drawbar" in ResName slot 0x3ea. Links:
; all 44 records consistent.
;
; Viewable slot 0xeb: RegObjTabl 0x1600010, ViewableProc, 0x25,
; 0xe858ac, 0xeb in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 37, table} at 0x27ed2 +
; 14*0xeb. Element 0 is named "Accordion" in ResName slot 0x3eb. Links:
; all 37 records consistent.
;
; Viewable slot 0xee: RegObjTabl 0x1600010, ViewableProc, 0x18,
; 0xe85944, 0xee in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 24, table} at 0x27ed2 +
; 14*0xee. Element 0 is named "Mesage" in ResName slot 0x3ee. Links: all
; 24 records consistent.
;
; Viewable slot 0xef: RegObjTabl 0x1600010, ViewableProc, 0xb, 0xe859a8,
; 0xef in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 11, table} at 0x27ed2 +
; 14*0xef. Element 0 is named "Welcom" in ResName slot 0x3ef. Links: all
; 11 records consistent.
;
; Viewable slot 0xf0: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe859d8,
; 0xf0 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0xf0. Element 0 is named "Softver" in ResName slot 0x3f0. Links:
; all 6 records consistent.
;
; ResName slot 0x302: RegObjTabl 0x160000f, ResNameProc, 0x14, 0xe859f4,
; 0x302 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 20, table} at 0x27ed2 +
; 14*0x302.
;
; ResName slot 0x303: RegObjTabl 0x160000f, ResNameProc, 0x54, 0xe85a8e,
; 0x303 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 84, table} at 0x27ed2 +
; 14*0x303.
;
; ResName slot 0x304: RegObjTabl 0x160000f, ResNameProc, 0x4, 0xe85cf0,
; 0x304 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x304.
;
; ResName slot 0x305: RegObjTabl 0x160000f, ResNameProc, 0x36, 0xe85d14,
; 0x305 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 54, table} at 0x27ed2 +
; 14*0x305.
;
; ResName slot 0x307: RegObjTabl 0x160000f, ResNameProc, 0x3, 0xe85f0a,
; 0x307 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 3, table} at 0x27ed2 +
; 14*0x307.
;
; ResName slot 0x308: RegObjTabl 0x160000f, ResNameProc, 0x4, 0xe85f2a,
; 0x308 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x308.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_TECHNI_CHORD
; NakaInst_TECHNI_CHORD  --  naka_technichord_part +0x0..+0xe (ROM 0xe81cce..0xe81cdc), 14 bytes
; No RegObjTabl-registered table points at the start of these 14 bytes
; (0xe81cce..0xe81cdc); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaInst_TECHNI_CHORD:
	.incbin "includes/generated/naka_technichord_part.bin", 0x0, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0xe
; naka_technichord_part+0xe  --  naka_technichord_part +0xe..+0x1064 (ROM 0xe81cdc..0xe82d32), 4182 bytes
; Widget records of elements 0-83 of Viewable slot 0x3 (table 0xe854c4,
; 84 entries, InitializeMurai), element 0 "Sdpart"; classes: TtlScreen
; (42 B, id 0x01600034), AcIndexEditSw (40 B, id 0x0160001f) x10, Line
; (26 B, id 0x0160002e) x6, Label (32 B, id 0x0160002b) x2, PsParaBox
; (36 B, id 0x01600012) x2, AcStrRadioBox (48 B, id 0x01600051) x8,
; VwEditSwBox (44 B, id 0x0160003e) x8, IvSdpart (22 B, id 0x01610000),
; Window (36 B, id 0x01600035) x9, AcLswPartEditBox (58 B, id
; 0x01610001) x25, VwBox (28 B, id 0x01600011) x9, AcVolPartEditBox (62
; B, id 0x01610002) x2, AcLswPartPan (36 B, id 0x0161001c).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0xE, 0x1056
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x1064
; naka_technichord_part+0x1064  --  naka_technichord_part +0x1064..+0x1132 (ROM 0xe82d32..0xe82e00), 206 bytes
; Widget records of elements 0-3 of Viewable slot 0x4 (table 0xe85618, 4
; entries, InitializeMurai), element 0 "Sdmtune"; classes: TtlScreen (42
; B, id 0x01600034), AcLswEditBox (58 B, id 0x0160001a), Label (32 B, id
; 0x0160002b), AcIndexWideES (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x1064, 0xCE
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_KeyScaling_NavTrail
; Naka_KeyScaling_NavTrail  --  naka_technichord_part +0x1132..+0x1136 (ROM 0xe82e00..0xe82e04), 4 bytes
; No RegObjTabl-registered table points at the start of these 4 bytes
; (0xe82e00..0xe82e04); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_KeyScaling_NavTrail:
	.incbin "includes/generated/naka_technichord_part.bin", 0x1132, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x1136
; naka_technichord_part+0x1136  --  naka_technichord_part +0x1136..+0x1996 (ROM 0xe82e04..0xe83664), 2144 bytes
; Widget records of elements 0-53 of Viewable slot 0x5 (table 0xe8562c,
; 54 entries, InitializeMurai), element 0 "Sdscltyp"; classes: TtlScreen
; (42 B, id 0x01600034), AcWindowPage (36 B, id 0x01600025),
; IvPageControl (28 B, id 0x01600028) x2, IvShowHide (26 B, id
; 0x01600064), Window (36 B, id 0x01600035) x2, AcIndexWideES (42 B, id
; 0x01600022) x4, AcLswEditBox (58 B, id 0x0160001a) x15, AcLswBox (44
; B, id 0x01600013), Label (32 B, id 0x0160002b), Icon (26 B, id
; 0x0160002d), VwBox (28 B, id 0x01600011) x12, Line (26 B, id
; 0x0160002e) x12, IvSdscltyp2 (22 B, id 0x0161000a).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x1136, 0x860
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x1996
; naka_technichord_part+0x1996  --  naka_technichord_part +0x1996..+0x1a48 (ROM 0xe83664..0xe83716), 178 bytes
; Widget records of elements 0-2 of Viewable slot 0x7 (table 0xe85708, 3
; entries, InitializeMurai), element 0 "Sdlfthld"; classes: TtlScreen
; (42 B, id 0x01600034), AcIndexWideES (42 B, id 0x01600022),
; AcLswEditBox (58 B, id 0x0160001a).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x1996, 0xB2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x1a48
; naka_technichord_part+0x1a48  --  naka_technichord_part +0x1a48..+0x1ad6 (ROM 0xe83716..0xe837a4), 142 bytes
; Widget records of elements 0-3 of Viewable slot 0x8 (table 0xe85718, 4
; entries, InitializeMurai), element 0 "Sdmixer"; classes: TtlScreen (42
; B, id 0x01600034), AcResetPage (36 B, id 0x01610016), AcPartMixer (36
; B, id 0x0161000d), IvExit (22 B, id 0x01600047).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x1A48, 0x8E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x1ad6
; naka_technichord_part+0x1ad6  --  naka_technichord_part +0x1ad6..+0x2026 (ROM 0xe837a4..0xe83cf4), 1360 bytes
; Widget records of elements 0-28 of Viewable slot 0xd (table 0xe8572c,
; 29 entries, InitializeMurai), element 0 "Sdtecd"; classes: TtlScreen
; (42 B, id 0x01600034), AcWindowPage (36 B, id 0x01600025),
; IvPageControl (28 B, id 0x01600028) x2, IvSdtecd (22 B, id
; 0x01610008), IvIntEasySet (24 B, id 0x01600063), Window (36 B, id
; 0x01600035) x2, AcIndexWideES (42 B, id 0x01600022) x2, AcIndexEditSw
; (40 B, id 0x0160001f) x2, PsLabelBox (48 B, id 0x01610007) x14,
; IvSdtecd1 (22 B, id 0x01610009), AcLswEditBox (58 B, id 0x0160001a),
; Label (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x1AD6, 0x550
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x2026
; naka_technichord_part+0x2026  --  naka_technichord_part +0x2026..+0x20ba (ROM 0xe83cf4..0xe83d88), 148 bytes
; Widget records of elements 0-3 of Viewable slot 0xa5 (table 0xe857a4,
; 4 entries, InitializeMurai), element 0 "Sqmixer"; classes: TtlScreen
; (42 B, id 0x01600034), AcResetPage (36 B, id 0x01610016), AcTrackMixer
; (36 B, id 0x0161000e), IvExit (22 B, id 0x01600047).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x2026, 0x94
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x20ba
; naka_technichord_part+0x20ba  --  naka_technichord_part +0x20ba..+0x2338 (ROM 0xe83d88..0xe84006), 638 bytes
; Widget records of elements 0-14 of Viewable slot 0xe4 (table 0xe857b8,
; 15 entries, InitializeMurai), element 0 "Demofeature"; classes:
; AcFdemoScreen (42 B, id 0x0161001f), AcPresentationBox (48 B, id
; 0x0161001d) x2, Window (36 B, id 0x01600035) x2, IvDemofeature1 (22 B,
; id 0x01610019), AcLanguageText (42 B, id 0x01600066), IvDemofeature2
; (22 B, id 0x0161001a), PsParaBox (36 B, id 0x01600012) x2, Screen (34
; B, id 0x01600033) x2, AcPresentationControl (36 B, id 0x01610018),
; Label (32 B, id 0x0160002b) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x20BA, 0x27E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x2338
; naka_technichord_part+0x2338  --  naka_technichord_part +0x2338..+0x2a16 (ROM 0xe84006..0xe846e4), 1758 bytes
; Widget records of elements 0-43 of Viewable slot 0xea (table 0xe857f8,
; 44 entries, InitializeMurai), element 0 "Drawbar"; classes: TtlScreen
; (42 B, id 0x01600034), IvIntVari (24 B, id 0x01600062), AcIndexToggle
; (44 B, id 0x0160004e) x3, Label (32 B, id 0x0160002b) x11, IvExit (22
; B, id 0x01600047), IvPageOverWrite (28 B, id 0x01610010) x2, IvDrawbar
; (22 B, id 0x01610011), AcDrawSetting (44 B, id 0x01610022), Window (36
; B, id 0x01600035) x4, VwBox (28 B, id 0x01600011) x3, StringBox (38 B,
; id 0x01600037), IvDrawbar1 (22 B, id 0x01610012), VwUserBitmapSp (26
; B, id 0x0161001e), AcDrawEditBox (58 B, id 0x0161001b) x4,
; AcIndexWideES (42 B, id 0x01600022), IvDrawbar2 (22 B, id 0x01610013),
; AcDrawbarName (40 B, id 0x01610023), PsParaBox (36 B, id 0x01600012),
; IvDrawbarNorm (22 B, id 0x01610014), Icon (26 B, id 0x0160002d) x2,
; IvDrawbarSndE (22 B, id 0x01610015), AcTitleMenu (54 B, id
; 0x0160001d).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x2338, 0x6DE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x2a16
; naka_technichord_part+0x2a16  --  naka_technichord_part +0x2a16..+0x3182 (ROM 0xe846e4..0xe84e50), 1900 bytes
; Widget records of elements 0-36 of Viewable slot 0xeb (table 0xe858ac,
; 37 entries, InitializeMurai), element 0 "Accordion"; classes: Screen
; (34 B, id 0x01600033), Icon (26 B, id 0x0160002d), IvIntVari (24 B, id
; 0x01600062), Label (32 B, id 0x0160002b) x4, AcIndexEditSw (40 B, id
; 0x0160001f) x2, PsParaBox (36 B, id 0x01600012), IvAccordion (22 B, id
; 0x01610004), Window (36 B, id 0x01600035) x2, VwUserBitmapSp (26 B, id
; 0x0161001e) x2, AcIndexToggle (44 B, id 0x0160004e) x4, AcAccordionTab
; (52 B, id 0x01610006) x16, IvAccordionX (22 B, id 0x01610005) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x2A16, 0x76C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3182
; naka_technichord_part+0x3182  --  naka_technichord_part +0x3182..+0x34fa (ROM 0xe84e50..0xe851c8), 888 bytes
; Widget records of elements 0-23 of Viewable slot 0xee (table 0xe85944,
; 24 entries, InitializeMurai), element 0 "Mesage"; classes: IvScreen
; (34 B, id 0x0160006a), IvMesage (22 B, id 0x01610003), Window (36 B,
; id 0x01600035) x7, AcLanguageText (42 B, id 0x01600066) x6,
; IvIntComplete (24 B, id 0x01600061), IvIntReminder (24 B, id
; 0x0160005f), IvIntError (24 B, id 0x01600060), EditSw (40 B, id
; 0x01600030) x2, AcRamBox (44 B, id 0x0160004f) x3, AcPleaseWait (36 B,
; id 0x01610021).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3182, 0x378
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x34fa
; naka_technichord_part+0x34fa  --  naka_technichord_part +0x34fa..+0x364c (ROM 0xe851c8..0xe8531a), 338 bytes
; Widget records of elements 0-10 of Viewable slot 0xef (table 0xe859a8,
; 11 entries, InitializeMurai), element 0 "Welcom"; classes:
; AcWelcomScreen (34 B, id 0x0161000b), IvIntWelcome (24 B, id
; 0x0160006b) x3, VwUserBitmapSp (26 B, id 0x0161001e) x2, Screen (34 B,
; id 0x01600033) x2, Label (32 B, id 0x0160002b), IvMPver (22 B, id
; 0x01610024), PsParaBox (36 B, id 0x01600012).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x34FA, 0x152
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x364c
; naka_technichord_part+0x364c  --  naka_technichord_part +0x364c..+0x37a2 (ROM 0xe8531a..0xe85470), 342 bytes
; Widget records of elements 0-5 of Viewable slot 0xf0 (table 0xe859d8,
; 6 entries, InitializeMurai), element 0 "Softver"; classes: TtlScreen
; (42 B, id 0x01600034), PsEditBox (50 B, id 0x01600015) x4, IvSoftver
; (22 B, id 0x0161000f).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x364C, 0x156
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x37a2
; naka_technichord_part+0x37a2  --  naka_technichord_part +0x37a2..+0x37f6 (ROM 0xe85470..0xe854c4), 84 bytes
; The table itself: Viewable slot 0x2 (table 0xe85470, 20 entries,
; InitializeMurai) -- 20 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x37A2, 0x54
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x37f6
; naka_technichord_part+0x37f6  --  naka_technichord_part +0x37f6..+0x394a (ROM 0xe854c4..0xe85618), 340 bytes
; The table itself: Viewable slot 0x3 (table 0xe854c4, 84 entries,
; InitializeMurai) -- 84 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x37F6, 0x154
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x394a
; naka_technichord_part+0x394a  --  naka_technichord_part +0x394a..+0x395e (ROM 0xe85618..0xe8562c), 20 bytes
; The table itself: Viewable slot 0x4 (table 0xe85618, 4 entries,
; InitializeMurai) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x394A, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x395e
; naka_technichord_part+0x395e  --  naka_technichord_part +0x395e..+0x3a3a (ROM 0xe8562c..0xe85708), 220 bytes
; The table itself: Viewable slot 0x5 (table 0xe8562c, 54 entries,
; InitializeMurai) -- 54 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x395E, 0xDC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3a3a
; naka_technichord_part+0x3a3a  --  naka_technichord_part +0x3a3a..+0x3a4a (ROM 0xe85708..0xe85718), 16 bytes
; The table itself: Viewable slot 0x7 (table 0xe85708, 3 entries,
; InitializeMurai) -- 3 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3A3A, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3a4a
; naka_technichord_part+0x3a4a  --  naka_technichord_part +0x3a4a..+0x3a5e (ROM 0xe85718..0xe8572c), 20 bytes
; The table itself: Viewable slot 0x8 (table 0xe85718, 4 entries,
; InitializeMurai) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3A4A, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3a5e
; naka_technichord_part+0x3a5e  --  naka_technichord_part +0x3a5e..+0x3ad6 (ROM 0xe8572c..0xe857a4), 120 bytes
; The table itself: Viewable slot 0xd (table 0xe8572c, 29 entries,
; InitializeMurai) -- 29 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3A5E, 0x78
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3ad6
; naka_technichord_part+0x3ad6  --  naka_technichord_part +0x3ad6..+0x3aea (ROM 0xe857a4..0xe857b8), 20 bytes
; The table itself: Viewable slot 0xa5 (table 0xe857a4, 4 entries,
; InitializeMurai) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3AD6, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3aea
; naka_technichord_part+0x3aea  --  naka_technichord_part +0x3aea..+0x3b2a (ROM 0xe857b8..0xe857f8), 64 bytes
; The table itself: Viewable slot 0xe4 (table 0xe857b8, 15 entries,
; InitializeMurai) -- 15 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3AEA, 0x40
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3b2a
; naka_technichord_part+0x3b2a  --  naka_technichord_part +0x3b2a..+0x3bde (ROM 0xe857f8..0xe858ac), 180 bytes
; The table itself: Viewable slot 0xea (table 0xe857f8, 44 entries,
; InitializeMurai) -- 44 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3B2A, 0xB4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3bde
; naka_technichord_part+0x3bde  --  naka_technichord_part +0x3bde..+0x3c76 (ROM 0xe858ac..0xe85944), 152 bytes
; The table itself: Viewable slot 0xeb (table 0xe858ac, 37 entries,
; InitializeMurai) -- 37 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3BDE, 0x98
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3c76
; naka_technichord_part+0x3c76  --  naka_technichord_part +0x3c76..+0x3cda (ROM 0xe85944..0xe859a8), 100 bytes
; The table itself: Viewable slot 0xee (table 0xe85944, 24 entries,
; InitializeMurai) -- 24 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3C76, 0x64
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3cda
; naka_technichord_part+0x3cda  --  naka_technichord_part +0x3cda..+0x3d0a (ROM 0xe859a8..0xe859d8), 48 bytes
; The table itself: Viewable slot 0xef (table 0xe859a8, 11 entries,
; InitializeMurai) -- 11 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3CDA, 0x30
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3d0a
; naka_technichord_part+0x3d0a  --  naka_technichord_part +0x3d0a..+0x3d26 (ROM 0xe859d8..0xe859f4), 28 bytes
; The table itself: Viewable slot 0xf0 (table 0xe859d8, 6 entries,
; InitializeMurai) -- 6 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3D0A, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3d26
; naka_technichord_part+0x3d26  --  naka_technichord_part +0x3d26..+0x3d7c (ROM 0xe859f4..0xe85a4a), 86 bytes
; The table itself: ResName slot 0x302 (table 0xe859f4, 20 entries,
; InitializeMurai) -- 20 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3D26, 0x56
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3d7c
; naka_technichord_part+0x3d7c  --  naka_technichord_part +0x3d7c..+0x3dc0 (ROM 0xe85a4a..0xe85a8e), 68 bytes
; Name strings of elements 0-19 of ResName slot 0x302 (table 0xe859f4,
; 20 entries, InitializeMurai), names for Viewable slot 0x2: "", "",
; "Sdmenu2", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3D7C, 0x44
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3dc0
; naka_technichord_part+0x3dc0  --  naka_technichord_part +0x3dc0..+0x3e00 (ROM 0xe85a8e..0xe85ace), 64 bytes
; The table itself: ResName slot 0x303 (table 0xe85a8e, 84 entries,
; InitializeMurai) -- 84 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3DC0, 0x40
EmbeddedPtrTable_v9_naka_technichord_part_003E00:
	.long 0x00E85CB4
	.long 0x00E85CB2
	.long 0x00E85CB0
	.long 0x00E85CAE
	.long 0x00E85CAC
	.long 0x00E85CAA
	.long 0x00E85CA8
	.long 0x00E85CA6
	.long 0x00E85CA4
	.long 0x00E85CA2
	.long 0x00E85CA0
	.long 0x00E85C9E
	.long 0x00E85C9C
	.long 0x00E85C90
	.long 0x00E85C8E
	.long 0x00E85C8C
	.long 0x00E85C8A
	.long 0x00E85C88
	.long 0x00E85C86
	.long 0x00E85C84
	.long 0x00E85C82
	.long 0x00E85C80
	.long 0x00E85C7E
	.long 0x00E85C7C
	.long 0x00E85C7A
	.long 0x00E85C78
	.long 0x00E85C76
	.long 0x00E85C6C
	.long 0x00E85C6A
	.long 0x00E85C68
	.long 0x00E85C66
	.long 0x00E85C5C
	.long 0x00E85C5A
	.long 0x00E85C58
	.long 0x00E85C56
	.long 0x00E85C54
	.long 0x00E85C52
	.long 0x00E85C50
	.long 0x00E85C46
	.long 0x00E85C44
	.long 0x00E85C42
	.long 0x00E85C40
	.long 0x00E85C3E
	.long 0x00E85C3C
	.long 0x00E85C32
	.long 0x00E85C30
	.long 0x00E85C2E
	.long 0x00E85C2C
	.long 0x00E85C2A
	.long 0x00E85C20
	.long 0x00E85C1E
	.long 0x00E85C1C
	.long 0x00E85C1A
	.long 0x00E85C10
	.long 0x00E85C0E
	.long 0x00E85C0C
	.long 0x00E85C0A
	.long 0x00E85C00
	.long 0x00E85BFE
	.long 0x00E85BFC
	.long 0x00E85BFA
	.long 0x00E85BF0
	.long 0x00E85BEE
	.long 0x00E85BEC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3f00
; naka_technichord_part+0x3f00  --  naka_technichord_part +0x3f00..+0x3f16 (ROM 0xe85bce..0xe85be4), 22 bytes
; No RegObjTabl-registered table points at the start of these 22 bytes
; (0xe85bce..0xe85be4); purpose not established by that route.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3F00, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x3f16
; naka_technichord_part+0x3f16  --  naka_technichord_part +0x3f16..+0x4022 (ROM 0xe85be4..0xe85cf0), 268 bytes
; Name strings of elements 0-83 of ResName slot 0x303 (table 0xe85a8e,
; 84 entries, InitializeMurai), names for Viewable slot 0x3: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x3F16, 0x10C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x4022
; naka_technichord_part+0x4022  --  naka_technichord_part +0x4022..+0x4038 (ROM 0xe85cf0..0xe85d06), 22 bytes
; The table itself: ResName slot 0x304 (table 0xe85cf0, 4 entries,
; InitializeMurai) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x4022, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x4038
; naka_technichord_part+0x4038  --  naka_technichord_part +0x4038..+0x4046 (ROM 0xe85d06..0xe85d14), 14 bytes
; Name strings of elements 0-3 of ResName slot 0x304 (table 0xe85cf0, 4
; entries, InitializeMurai), names for Viewable slot 0x4: "", "", "",
; "Sdmtune".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x4038, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x4046
; naka_technichord_part+0x4046  --  naka_technichord_part +0x4046..+0x4124 (ROM 0xe85d14..0xe85df2), 222 bytes
; The table itself: ResName slot 0x305 (table 0xe85d14, 54 entries,
; InitializeMurai) -- 54 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x4046, 0xDE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x4124
; naka_technichord_part+0x4124  --  naka_technichord_part +0x4124..+0x423c (ROM 0xe85df2..0xe85f0a), 280 bytes
; Name strings of elements 0-53 of ResName slot 0x305 (table 0xe85d14,
; 54 entries, InitializeMurai), names for Viewable slot 0x5: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x4124, 0x118
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x423c
; naka_technichord_part+0x423c  --  naka_technichord_part +0x423c..+0x424e (ROM 0xe85f0a..0xe85f1c), 18 bytes
; The table itself: ResName slot 0x307 (table 0xe85f0a, 3 entries,
; InitializeMurai) -- 3 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x423C, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x424e
; naka_technichord_part+0x424e  --  naka_technichord_part +0x424e..+0x425c (ROM 0xe85f1c..0xe85f2a), 14 bytes
; Name strings of elements 0-2 of ResName slot 0x307 (table 0xe85f0a, 3
; entries, InitializeMurai), names for Viewable slot 0x7: "", "",
; "Sdlfthld".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x424E, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x425c
; naka_technichord_part+0x425c  --  naka_technichord_part +0x425c..+0x4272 (ROM 0xe85f2a..0xe85f40), 22 bytes
; The table itself: ResName slot 0x308 (table 0xe85f2a, 4 entries,
; InitializeMurai) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x425C, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_technichord_part+0x4272
; naka_technichord_part+0x4272  --  naka_technichord_part +0x4272..+0x4280 (ROM 0xe85f40..0xe85f4e), 14 bytes
; Name strings of elements 0-3 of ResName slot 0x308 (table 0xe85f2a, 4
; entries, InitializeMurai), names for Viewable slot 0x8: "", "", "",
; "Sdmixer".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_part.bin", 0x4272, 0xE

; External label offsets within the binary blob above.
