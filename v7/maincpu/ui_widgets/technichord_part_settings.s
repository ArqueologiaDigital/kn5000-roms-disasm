
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

; [nakarest] NakaInst_TECHNI_CHORD  +0x0..+0xe (0xe81cce, 14 B)
; [nakarest] text the records point at, in Viewable slot 0x2 (table 0xe85470, 20 entries,
; [nakarest] InitializeMurai): "TECHNI-CHORD" (AcTitleMenu.str of element 19).
NakaInst_TECHNI_CHORD:
	.incbin "includes/generated/naka_technichord_part.bin", 0x0, 0xE
; [nakarest] naka_technichord_part+0xe  +0xe..+0x1064 (0xe81cdc, 4182 B)
; [nakarest] widget record, element 0 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "SOUND PART
; [nakarest] SETTING" (TtlScreen.title of element 0). widget records, elements 1-9 of Viewable
; [nakarest] slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): AcIndexEditSw
; [nakarest] (40 B) x2, Line (26 B) x6, Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "PART SELECT :" (Label.str
; [nakarest] of element 9). widget records, elements 10-12 of Viewable slot 0x3 (table 0xe854c4,
; [nakarest] 84 entries, InitializeMurai) ("Sdpart"): PsParaBox (36 B) x2, AcStrRadioBox (48 B).
; [nakarest] text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai): "VOL" (AcStrRadioBox.str of element 12). widget record, element
; [nakarest] 13 of Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"):
; [nakarest] AcStrRadioBox (48 B). text the records point at, in Viewable slot 0x3 (table
; [nakarest] 0xe854c4, 84 entries, InitializeMurai): "PAN" (AcStrRadioBox.str of element 13).
; [nakarest] widget record, element 14 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): AcStrRadioBox (48 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "EFF"
; [nakarest] (AcStrRadioBox.str of element 14). widget record, element 15 of Viewable slot 0x3
; [nakarest] (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): AcStrRadioBox (48 B).
; [nakarest] text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai): "SUS" (AcStrRadioBox.str of element 15). widget record, element
; [nakarest] 16 of Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"):
; [nakarest] AcStrRadioBox (48 B). text the records point at, in Viewable slot 0x3 (table
; [nakarest] 0xe854c4, 84 entries, InitializeMurai): "KEY" (AcStrRadioBox.str of element 16).
; [nakarest] widget record, element 17 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): AcStrRadioBox (48 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "TUN"
; [nakarest] (AcStrRadioBox.str of element 17). widget record, element 18 of Viewable slot 0x3
; [nakarest] (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): AcStrRadioBox (48 B).
; [nakarest] text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai): "BND" (AcStrRadioBox.str of element 18). widget record, element
; [nakarest] 19 of Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"):
; [nakarest] AcStrRadioBox (48 B). text the records point at, in Viewable slot 0x3 (table
; [nakarest] 0xe854c4, 84 entries, InitializeMurai): "OTH" (AcStrRadioBox.str of element 19).
; [nakarest] widget record, element 20 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): VwEditSwBox (44 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): ""
; [nakarest] (VwEditSwBox.str of element 20). widget record, element 21 of Viewable slot 0x3
; [nakarest] (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): VwEditSwBox (44 B). text
; [nakarest] the records point at, in Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai): "" (VwEditSwBox.str of element 21). widget record, element 22 of
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"):
; [nakarest] VwEditSwBox (44 B). text the records point at, in Viewable slot 0x3 (table
; [nakarest] 0xe854c4, 84 entries, InitializeMurai): "" (VwEditSwBox.str of element 22). widget
; [nakarest] record, element 23 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): VwEditSwBox (44 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): ""
; [nakarest] (VwEditSwBox.str of element 23). widget record, element 24 of Viewable slot 0x3
; [nakarest] (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): VwEditSwBox (44 B). text
; [nakarest] the records point at, in Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai): "" (VwEditSwBox.str of element 24). widget record, element 25 of
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"):
; [nakarest] VwEditSwBox (44 B). text the records point at, in Viewable slot 0x3 (table
; [nakarest] 0xe854c4, 84 entries, InitializeMurai): "" (VwEditSwBox.str of element 25). widget
; [nakarest] record, element 26 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): VwEditSwBox (44 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): ""
; [nakarest] (VwEditSwBox.str of element 26). widget record, element 27 of Viewable slot 0x3
; [nakarest] (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): VwEditSwBox (44 B). text
; [nakarest] the records point at, in Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai): "" (VwEditSwBox.str of element 27). widget records, elements
; [nakarest] 28-30 of Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai)
; [nakarest] ("Sdpart"): IvSdpart (22 B), Window (36 B), AcLswPartEditBox (58 B). text the
; [nakarest] records point at, in Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai): "PAN :" (AcLswPartEditBox.caption of element 30). widget record,
; [nakarest] element 31 of Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai)
; [nakarest] ("Sdpart"): AcLswPartEditBox (58 B). text the records point at, in Viewable slot
; [nakarest] 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "REV. DEPTH :"
; [nakarest] (AcLswPartEditBox.caption of element 31). widget record, element 32 of Viewable
; [nakarest] slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): AcLswPartEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai): "DSP EFFECT :" (AcLswPartEditBox.caption of element 32).
; [nakarest] widget record, element 33 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): AcLswPartEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "DIG.EFFECT :"
; [nakarest] (AcLswPartEditBox.caption of element 33). widget record, element 34 of Viewable
; [nakarest] slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): AcLswPartEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai): "SUSTAIN :" (AcLswPartEditBox.caption of element 34).
; [nakarest] widget records, elements 35-36 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): VwBox (28 B), AcLswPartEditBox (58 B). text the
; [nakarest] records point at, in Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai): "SUS LENGTH :" (AcLswPartEditBox.caption of element 36). widget
; [nakarest] record, element 37 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): AcLswPartEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "KEY SHIFT :"
; [nakarest] (AcLswPartEditBox.caption of element 37). widget record, element 38 of Viewable
; [nakarest] slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): AcLswPartEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai): "TUNING :" (AcLswPartEditBox.caption of element 38).
; [nakarest] widget record, element 39 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): AcLswPartEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "BEND RANGE :"
; [nakarest] (AcLswPartEditBox.caption of element 39). widget record, element 40 of Viewable
; [nakarest] slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): AcLswPartEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai): "GLIDE PEDAL:" (AcLswPartEditBox.caption of element 40).
; [nakarest] widget record, element 41 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): AcLswPartEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "SUST.PEDAL :"
; [nakarest] (AcLswPartEditBox.caption of element 41). widget record, element 42 of Viewable
; [nakarest] slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): AcVolPartEditBox
; [nakarest] (62 B). text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai): "VOLUME :" (AcVolPartEditBox.caption of element 42).
; [nakarest] widget records, elements 43-46 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): Window (36 B), AcIndexEditSw (40 B), VwBox (28 B),
; [nakarest] AcVolPartEditBox (62 B). text the records point at, in Viewable slot 0x3 (table
; [nakarest] 0xe854c4, 84 entries, InitializeMurai): "VOLUME :" (AcVolPartEditBox.caption of
; [nakarest] element 46). widget records, elements 47-49 of Viewable slot 0x3 (table 0xe854c4,
; [nakarest] 84 entries, InitializeMurai) ("Sdpart"): Window (36 B), VwBox (28 B),
; [nakarest] AcLswPartEditBox (58 B). text the records point at, in Viewable slot 0x3 (table
; [nakarest] 0xe854c4, 84 entries, InitializeMurai): "PAN =" (AcLswPartEditBox.caption of
; [nakarest] element 49). widget record, element 50 of Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai) ("Sdpart"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "LEFT CENTER
; [nakarest] RIGHT" (Label.str of element 50). widget records, elements 51-55 of Viewable slot
; [nakarest] 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): AcLswPartPan (36 B),
; [nakarest] AcIndexEditSw (40 B), VwBox (28 B), Window (36 B), AcLswPartEditBox (58 B). text
; [nakarest] the records point at, in Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai): "REVERB DEPTH:" (AcLswPartEditBox.caption of element 55). widget
; [nakarest] record, element 56 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): AcLswPartEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "DSP EFFECT :"
; [nakarest] (AcLswPartEditBox.caption of element 56). widget record, element 57 of Viewable
; [nakarest] slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): AcLswPartEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai): "DIGITAL EFF.:" (AcLswPartEditBox.caption of element
; [nakarest] 57). widget records, elements 58-62 of Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai) ("Sdpart"): AcIndexEditSw (40 B) x2, VwBox (28 B), Window
; [nakarest] (36 B), AcLswPartEditBox (58 B). text the records point at, in Viewable slot 0x3
; [nakarest] (table 0xe854c4, 84 entries, InitializeMurai): "SUSTAIN ON/OFF :"
; [nakarest] (AcLswPartEditBox.caption of element 62). widget record, element 63 of Viewable
; [nakarest] slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): AcLswPartEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai): "SUSTAIN LENGTH :" (AcLswPartEditBox.caption of element
; [nakarest] 63). widget records, elements 64-66 of Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai) ("Sdpart"): VwBox (28 B), Window (36 B), AcLswPartEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai): "KEY SHIFT :" (AcLswPartEditBox.caption of element 66).
; [nakarest] widget records, elements 67-70 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): AcIndexEditSw (40 B), VwBox (28 B), Window (36 B),
; [nakarest] AcLswPartEditBox (58 B). text the records point at, in Viewable slot 0x3 (table
; [nakarest] 0xe854c4, 84 entries, InitializeMurai): "TUNING :" (AcLswPartEditBox.caption of
; [nakarest] element 70). widget records, elements 71-74 of Viewable slot 0x3 (table 0xe854c4,
; [nakarest] 84 entries, InitializeMurai) ("Sdpart"): AcIndexEditSw (40 B), VwBox (28 B), Window
; [nakarest] (36 B), AcLswPartEditBox (58 B). text the records point at, in Viewable slot 0x3
; [nakarest] (table 0xe854c4, 84 entries, InitializeMurai): "PITCH BEND RANGE :"
; [nakarest] (AcLswPartEditBox.caption of element 74). widget records, elements 75-78 of
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"):
; [nakarest] AcIndexEditSw (40 B), VwBox (28 B), Window (36 B), AcLswPartEditBox (58 B). text
; [nakarest] the records point at, in Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai): "GLIDE PEDAL :" (AcLswPartEditBox.caption of element 78). widget
; [nakarest] record, element 79 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): AcLswPartEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "SUSTAIN PDL :"
; [nakarest] (AcLswPartEditBox.caption of element 79). widget record, element 80 of Viewable
; [nakarest] slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai) ("Sdpart"): AcLswPartEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai): "AFTER TOUCH :" (AcLswPartEditBox.caption of element
; [nakarest] 80). widget records, elements 81-82 of Viewable slot 0x3 (table 0xe854c4, 84
; [nakarest] entries, InitializeMurai) ("Sdpart"): AcIndexEditSw (40 B), AcLswPartEditBox (58
; [nakarest] B). text the records point at, in Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai): "KEY SCALING :" (AcLswPartEditBox.caption of element 82). widget
; [nakarest] record, element 83 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): AcLswPartEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai): "PART EXP PDL:"
; [nakarest] (AcLswPartEditBox.caption of element 83).
	.incbin "includes/generated/naka_technichord_part.bin", 0xE, 0x1056
; [nakarest] naka_technichord_part+0x1064  +0x1064..+0x1132 (0xe82d32, 206 B)
; [nakarest] widget record, element 0 of Viewable slot 0x4 (table 0xe85618, 4 entries,
; [nakarest] InitializeMurai) ("Sdmtune"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x4 (table 0xe85618, 4 entries, InitializeMurai): "MASTER TUNING"
; [nakarest] (TtlScreen.title of element 0). widget record, element 1 of Viewable slot 0x4
; [nakarest] (table 0xe85618, 4 entries, InitializeMurai) ("Sdmtune"): AcLswEditBox (58 B). text
; [nakarest] the records point at, in Viewable slot 0x4 (table 0xe85618, 4 entries,
; [nakarest] InitializeMurai): "MASTER TUNING :" (AcLswEditBox.caption of element 1). widget
; [nakarest] record, element 2 of Viewable slot 0x4 (table 0xe85618, 4 entries, InitializeMurai)
; [nakarest] ("Sdmtune"): Label (32 B). text the records point at, in Viewable slot 0x4 (table
; [nakarest] 0xe85618, 4 entries, InitializeMurai): "Hz" (Label.str of element 2). widget
; [nakarest] record, element 3 of Viewable slot 0x4 (table 0xe85618, 4 entries, InitializeMurai)
; [nakarest] ("Sdmtune"): AcIndexWideES (42 B).
	.incbin "includes/generated/naka_technichord_part.bin", 0x1064, 0xCE
; [nakarest] Naka_KeyScaling_NavTrail  +0x1132..+0x1136 (0xe82e00, 4 B)
; [nakarest] Continues widget record, element 3 of Viewable slot 0x4 (table 0xe85618, 4 entries,
; [nakarest] InitializeMurai) ("Sdmtune"): AcIndexWideES (42 B) (starts 0xe82dda, 4 of its 42
; [nakarest] bytes are here or later).
Naka_KeyScaling_NavTrail:
	.incbin "includes/generated/naka_technichord_part.bin", 0x1132, 0x4
; [nakarest] naka_technichord_part+0x1136  +0x1136..+0x1996 (0xe82e04, 2144 B)
; [nakarest] widget record, element 0 of Viewable slot 0x5 (table 0xe8562c, 54 entries,
; [nakarest] InitializeMurai) ("Sdscltyp"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai): "KEY SCALING"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-7 of Viewable slot 0x5
; [nakarest] (table 0xe8562c, 54 entries, InitializeMurai) ("Sdscltyp"): AcWindowPage (36 B),
; [nakarest] IvPageControl (28 B) x2, IvShowHide (26 B), Window (36 B), AcIndexWideES (42 B),
; [nakarest] AcLswEditBox (58 B). text the records point at, in Viewable slot 0x5 (table
; [nakarest] 0xe8562c, 54 entries, InitializeMurai): "SCALING TYPE :" (AcLswEditBox.caption of
; [nakarest] element 7). widget record, element 8 of Viewable slot 0x5 (table 0xe8562c, 54
; [nakarest] entries, InitializeMurai) ("Sdscltyp"): AcLswEditBox (58 B). text the records point
; [nakarest] at, in Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai): "SCALING
; [nakarest] SHIFT :" (AcLswEditBox.caption of element 8). widget records, elements 9-10 of
; [nakarest] Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai) ("Sdscltyp"):
; [nakarest] AcLswBox (44 B), AcLswEditBox (58 B). text the records point at, in Viewable slot
; [nakarest] 0x5 (table 0xe8562c, 54 entries, InitializeMurai): "SCALING MODE :"
; [nakarest] (AcLswEditBox.caption of element 10). widget records, elements 11-12 of Viewable
; [nakarest] slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai) ("Sdscltyp"): Window (36 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x5 (table 0xe8562c, 54
; [nakarest] entries, InitializeMurai): "USER KEY SCALING" (Label.str of element 12). widget
; [nakarest] records, elements 13-17 of Viewable slot 0x5 (table 0xe8562c, 54 entries,
; [nakarest] InitializeMurai) ("Sdscltyp"): Icon (26 B), AcIndexWideES (42 B) x3, AcLswEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0x5 (table 0xe8562c, 54
; [nakarest] entries, InitializeMurai): "" (AcLswEditBox.caption of element 17). widget record,
; [nakarest] element 18 of Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai)
; [nakarest] ("Sdscltyp"): AcLswEditBox (58 B). text the records point at, in Viewable slot 0x5
; [nakarest] (table 0xe8562c, 54 entries, InitializeMurai): "" (AcLswEditBox.caption of element
; [nakarest] 18). widget record, element 19 of Viewable slot 0x5 (table 0xe8562c, 54 entries,
; [nakarest] InitializeMurai) ("Sdscltyp"): AcLswEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai): ""
; [nakarest] (AcLswEditBox.caption of element 19). widget record, element 20 of Viewable slot
; [nakarest] 0x5 (table 0xe8562c, 54 entries, InitializeMurai) ("Sdscltyp"): AcLswEditBox (58
; [nakarest] B). text the records point at, in Viewable slot 0x5 (table 0xe8562c, 54 entries,
; [nakarest] InitializeMurai): "" (AcLswEditBox.caption of element 20). widget record, element
; [nakarest] 21 of Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai) ("Sdscltyp"):
; [nakarest] AcLswEditBox (58 B). text the records point at, in Viewable slot 0x5 (table
; [nakarest] 0xe8562c, 54 entries, InitializeMurai): "" (AcLswEditBox.caption of element 21).
; [nakarest] widget record, element 22 of Viewable slot 0x5 (table 0xe8562c, 54 entries,
; [nakarest] InitializeMurai) ("Sdscltyp"): AcLswEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai): ""
; [nakarest] (AcLswEditBox.caption of element 22). widget record, element 23 of Viewable slot
; [nakarest] 0x5 (table 0xe8562c, 54 entries, InitializeMurai) ("Sdscltyp"): AcLswEditBox (58
; [nakarest] B). text the records point at, in Viewable slot 0x5 (table 0xe8562c, 54 entries,
; [nakarest] InitializeMurai): "" (AcLswEditBox.caption of element 23). widget record, element
; [nakarest] 24 of Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai) ("Sdscltyp"):
; [nakarest] AcLswEditBox (58 B). text the records point at, in Viewable slot 0x5 (table
; [nakarest] 0xe8562c, 54 entries, InitializeMurai): "" (AcLswEditBox.caption of element 24).
; [nakarest] widget record, element 25 of Viewable slot 0x5 (table 0xe8562c, 54 entries,
; [nakarest] InitializeMurai) ("Sdscltyp"): AcLswEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai): ""
; [nakarest] (AcLswEditBox.caption of element 25). widget record, element 26 of Viewable slot
; [nakarest] 0x5 (table 0xe8562c, 54 entries, InitializeMurai) ("Sdscltyp"): AcLswEditBox (58
; [nakarest] B). text the records point at, in Viewable slot 0x5 (table 0xe8562c, 54 entries,
; [nakarest] InitializeMurai): "" (AcLswEditBox.caption of element 26). widget record, element
; [nakarest] 27 of Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai) ("Sdscltyp"):
; [nakarest] AcLswEditBox (58 B). text the records point at, in Viewable slot 0x5 (table
; [nakarest] 0xe8562c, 54 entries, InitializeMurai): "" (AcLswEditBox.caption of element 27).
; [nakarest] widget record, element 28 of Viewable slot 0x5 (table 0xe8562c, 54 entries,
; [nakarest] InitializeMurai) ("Sdscltyp"): AcLswEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai): ""
; [nakarest] (AcLswEditBox.caption of element 28). widget records, elements 29-53 of Viewable
; [nakarest] slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai) ("Sdscltyp"): VwBox (28 B)
; [nakarest] x12, Line (26 B) x12, IvSdscltyp2 (22 B).
	.incbin "includes/generated/naka_technichord_part.bin", 0x1136, 0x860
; [nakarest] naka_technichord_part+0x1996  +0x1996..+0x1a48 (0xe83664, 178 B)
; [nakarest] widget record, element 0 of Viewable slot 0x7 (table 0xe85708, 3 entries,
; [nakarest] InitializeMurai) ("Sdlfthld"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x7 (table 0xe85708, 3 entries, InitializeMurai): "LEFT HOLD SETTING"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-2 of Viewable slot 0x7
; [nakarest] (table 0xe85708, 3 entries, InitializeMurai) ("Sdlfthld"): AcIndexWideES (42 B),
; [nakarest] AcLswEditBox (58 B). text the records point at, in Viewable slot 0x7 (table
; [nakarest] 0xe85708, 3 entries, InitializeMurai): "LEFT HOLD :" (AcLswEditBox.caption of
; [nakarest] element 2).
	.incbin "includes/generated/naka_technichord_part.bin", 0x1996, 0xB2
; [nakarest] naka_technichord_part+0x1a48  +0x1a48..+0x1ad6 (0xe83716, 142 B)
; [nakarest] widget record, element 0 of Viewable slot 0x8 (table 0xe85718, 4 entries,
; [nakarest] InitializeMurai) ("Sdmixer"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x8 (table 0xe85718, 4 entries, InitializeMurai): "MIXER"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-3 of Viewable slot 0x8
; [nakarest] (table 0xe85718, 4 entries, InitializeMurai) ("Sdmixer"): AcResetPage (36 B),
; [nakarest] AcPartMixer (36 B), IvExit (22 B).
	.incbin "includes/generated/naka_technichord_part.bin", 0x1A48, 0x8E
; [nakarest] naka_technichord_part+0x1ad6  +0x1ad6..+0x2026 (0xe837a4, 1360 B)
; [nakarest] widget record, element 0 of Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai) ("Sdtecd"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai): "TECHNI-CHORD"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-10 of Viewable slot 0xd
; [nakarest] (table 0xe8572c, 29 entries, InitializeMurai) ("Sdtecd"): AcWindowPage (36 B),
; [nakarest] IvPageControl (28 B) x2, IvSdtecd (22 B), IvIntEasySet (24 B), Window (36 B),
; [nakarest] AcIndexWideES (42 B), AcIndexEditSw (40 B) x2, PsLabelBox (48 B). text the records
; [nakarest] point at, in Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai):
; [nakarest] "CLOSE" (PsLabelBox.str of element 10). widget record, element 11 of Viewable slot
; [nakarest] 0xd (table 0xe8572c, 29 entries, InitializeMurai) ("Sdtecd"): PsLabelBox (48 B).
; [nakarest] text the records point at, in Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai): "OPEN 1" (PsLabelBox.str of element 11). widget record, element
; [nakarest] 12 of Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai) ("Sdtecd"):
; [nakarest] PsLabelBox (48 B). text the records point at, in Viewable slot 0xd (table 0xe8572c,
; [nakarest] 29 entries, InitializeMurai): "OPEN 2" (PsLabelBox.str of element 12). widget
; [nakarest] record, element 13 of Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai) ("Sdtecd"): PsLabelBox (48 B). text the records point at, in
; [nakarest] Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai): "DUET 1"
; [nakarest] (PsLabelBox.str of element 13). widget record, element 14 of Viewable slot 0xd
; [nakarest] (table 0xe8572c, 29 entries, InitializeMurai) ("Sdtecd"): PsLabelBox (48 B). text
; [nakarest] the records point at, in Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai): "DUET 2" (PsLabelBox.str of element 14). widget record, element
; [nakarest] 15 of Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai) ("Sdtecd"):
; [nakarest] PsLabelBox (48 B). text the records point at, in Viewable slot 0xd (table 0xe8572c,
; [nakarest] 29 entries, InitializeMurai): "COUNTRY" (PsLabelBox.str of element 15). widget
; [nakarest] record, element 16 of Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai) ("Sdtecd"): PsLabelBox (48 B). text the records point at, in
; [nakarest] Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai): "THEATRE"
; [nakarest] (PsLabelBox.str of element 16). widget record, element 17 of Viewable slot 0xd
; [nakarest] (table 0xe8572c, 29 entries, InitializeMurai) ("Sdtecd"): PsLabelBox (48 B). text
; [nakarest] the records point at, in Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai): "HYMN" (PsLabelBox.str of element 17). widget record, element 18
; [nakarest] of Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai) ("Sdtecd"):
; [nakarest] PsLabelBox (48 B). text the records point at, in Viewable slot 0xd (table 0xe8572c,
; [nakarest] 29 entries, InitializeMurai): "BIG BAND BRASS" (PsLabelBox.str of element 18).
; [nakarest] widget record, element 19 of Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai) ("Sdtecd"): PsLabelBox (48 B). text the records point at, in
; [nakarest] Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai): "BIG BAND REEDS"
; [nakarest] (PsLabelBox.str of element 19). widget record, element 20 of Viewable slot 0xd
; [nakarest] (table 0xe8572c, 29 entries, InitializeMurai) ("Sdtecd"): PsLabelBox (48 B). text
; [nakarest] the records point at, in Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai): "OCTAVE" (PsLabelBox.str of element 20). widget record, element
; [nakarest] 21 of Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai) ("Sdtecd"):
; [nakarest] PsLabelBox (48 B). text the records point at, in Viewable slot 0xd (table 0xe8572c,
; [nakarest] 29 entries, InitializeMurai): "BLOCK" (PsLabelBox.str of element 21). widget
; [nakarest] record, element 22 of Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai) ("Sdtecd"): PsLabelBox (48 B). text the records point at, in
; [nakarest] Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai): "HARD ROCK"
; [nakarest] (PsLabelBox.str of element 22). widget record, element 23 of Viewable slot 0xd
; [nakarest] (table 0xe8572c, 29 entries, InitializeMurai) ("Sdtecd"): PsLabelBox (48 B). text
; [nakarest] the records point at, in Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai): "FANFARE" (PsLabelBox.str of element 23). widget records,
; [nakarest] elements 24-27 of Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai)
; [nakarest] ("Sdtecd"): IvSdtecd1 (22 B), Window (36 B), AcIndexWideES (42 B), AcLswEditBox (58
; [nakarest] B). text the records point at, in Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai): "ORCHESTRATOR :" (AcLswEditBox.caption of element 27). widget
; [nakarest] record, element 28 of Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai) ("Sdtecd"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xd (table 0xe8572c, 29 entries, InitializeMurai): "VALUE" (Label.str of
; [nakarest] element 28).
	.incbin "includes/generated/naka_technichord_part.bin", 0x1AD6, 0x550
; [nakarest] naka_technichord_part+0x2026  +0x2026..+0x20ba (0xe83cf4, 148 B)
; [nakarest] widget record, element 0 of Viewable slot 0xa5 (table 0xe857a4, 4 entries,
; [nakarest] InitializeMurai) ("Sqmixer"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xa5 (table 0xe857a4, 4 entries, InitializeMurai): "TRACK MIXER"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-3 of Viewable slot 0xa5
; [nakarest] (table 0xe857a4, 4 entries, InitializeMurai) ("Sqmixer"): AcResetPage (36 B),
; [nakarest] AcTrackMixer (36 B), IvExit (22 B).
	.incbin "includes/generated/naka_technichord_part.bin", 0x2026, 0x94
; [nakarest] naka_technichord_part+0x20ba  +0x20ba..+0x2338 (0xe83d88, 638 B)
; [nakarest] widget record, element 0 of Viewable slot 0xe4 (table 0xe857b8, 15 entries,
; [nakarest] InitializeMurai) ("Demofeature"): AcFdemoScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0xe4 (table 0xe857b8, 15 entries, InitializeMurai): "FEATURE
; [nakarest] PRESENTATION" (AcFdemoScreen.title of element 0). widget record, element 1 of
; [nakarest] Viewable slot 0xe4 (table 0xe857b8, 15 entries, InitializeMurai) ("Demofeature"):
; [nakarest] AcPresentationBox (48 B). text the records point at, in Viewable slot 0xe4 (table
; [nakarest] 0xe857b8, 15 entries, InitializeMurai): "Start the internal DEMO"
; [nakarest] (AcPresentationBox.str of element 1). widget records, elements 2-7 of Viewable slot
; [nakarest] 0xe4 (table 0xe857b8, 15 entries, InitializeMurai) ("Demofeature"): Window (36 B)
; [nakarest] x2, IvDemofeature1 (22 B), AcLanguageText (42 B), IvDemofeature2 (22 B),
; [nakarest] AcPresentationBox (48 B). text the records point at, in Viewable slot 0xe4 (table
; [nakarest] 0xe857b8, 15 entries, InitializeMurai): "Start the loaded DEMO"
; [nakarest] (AcPresentationBox.str of element 7). widget records, elements 8-11 of Viewable
; [nakarest] slot 0xe4 (table 0xe857b8, 15 entries, InitializeMurai) ("Demofeature"): PsParaBox
; [nakarest] (36 B), Screen (34 B), AcPresentationControl (36 B), Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xe4 (table 0xe857b8, 15 entries, InitializeMurai):
; [nakarest] "Presentation Mode" (Label.str of element 11). widget records, elements 12-13 of
; [nakarest] Viewable slot 0xe4 (table 0xe857b8, 15 entries, InitializeMurai) ("Demofeature"):
; [nakarest] Screen (34 B), Label (32 B). text the records point at, in Viewable slot 0xe4
; [nakarest] (table 0xe857b8, 15 entries, InitializeMurai): "Loading Now...." (Label.str of
; [nakarest] element 13). widget record, element 14 of Viewable slot 0xe4 (table 0xe857b8, 15
; [nakarest] entries, InitializeMurai) ("Demofeature"): PsParaBox (36 B).
	.incbin "includes/generated/naka_technichord_part.bin", 0x20BA, 0x27E
; [nakarest] naka_technichord_part+0x2338  +0x2338..+0x2a16 (0xe84006, 1758 B)
; [nakarest] widget record, element 0 of Viewable slot 0xea (table 0xe857f8, 44 entries,
; [nakarest] InitializeMurai) ("Drawbar"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai): ""
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-2 of Viewable slot 0xea
; [nakarest] (table 0xe857f8, 44 entries, InitializeMurai) ("Drawbar"): IvIntVari (24 B),
; [nakarest] AcIndexToggle (44 B). text the records point at, in Viewable slot 0xea (table
; [nakarest] 0xe857f8, 44 entries, InitializeMurai): " 4'" (AcIndexToggle.stroff of element 2);
; [nakarest] " 4'" (AcIndexToggle.stron of element 2). widget record, element 3 of Viewable slot
; [nakarest] 0xea (table 0xe857f8, 44 entries, InitializeMurai) ("Drawbar"): AcIndexToggle (44
; [nakarest] B). text the records point at, in Viewable slot 0xea (table 0xe857f8, 44 entries,
; [nakarest] InitializeMurai): "2 '" (AcIndexToggle.stroff of element 3); "2 '"
; [nakarest] (AcIndexToggle.stron of element 3). widget record, element 4 of Viewable slot 0xea
; [nakarest] (table 0xe857f8, 44 entries, InitializeMurai) ("Drawbar"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xea (table 0xe857f8, 44 entries,
; [nakarest] InitializeMurai): "2/3" (Label.str of element 4). widget record, element 5 of
; [nakarest] Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai) ("Drawbar"): Label
; [nakarest] (32 B). text the records point at, in Viewable slot 0xea (table 0xe857f8, 44
; [nakarest] entries, InitializeMurai): "2/3" (Label.str of element 5). widget record, element 6
; [nakarest] of Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai) ("Drawbar"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xea (table 0xe857f8, 44
; [nakarest] entries, InitializeMurai): "PERCUSSIVE" (Label.str of element 6). widget records,
; [nakarest] elements 7-8 of Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai)
; [nakarest] ("Drawbar"): IvExit (22 B), Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xea (table 0xe857f8, 44 entries, InitializeMurai): "TONE" (Label.str of
; [nakarest] element 8). widget records, elements 9-12 of Viewable slot 0xea (table 0xe857f8, 44
; [nakarest] entries, InitializeMurai) ("Drawbar"): IvPageOverWrite (28 B) x2, IvDrawbar (22 B),
; [nakarest] AcDrawSetting (44 B). text the records point at, in Viewable slot 0xea (table
; [nakarest] 0xe857f8, 44 entries, InitializeMurai): "DRAWBAR SETTING" (AcDrawSetting.stroff of
; [nakarest] element 12); "DRAWBAR SETTING" (AcDrawSetting.stron of element 12). widget records,
; [nakarest] elements 13-15 of Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai)
; [nakarest] ("Drawbar"): Window (36 B), VwBox (28 B), StringBox (38 B). text the records point
; [nakarest] at, in Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai): "16' 5 '
; [nakarest] 8' 4' 2 ' 2' 1 '1 ' 1'" (StringBox.str of element 15). widget record, element 16 of
; [nakarest] Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai) ("Drawbar"): Label
; [nakarest] (32 B). text the records point at, in Viewable slot 0xea (table 0xe857f8, 44
; [nakarest] entries, InitializeMurai): "1/3" (Label.str of element 16). widget record, element
; [nakarest] 17 of Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai) ("Drawbar"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xea (table 0xe857f8, 44
; [nakarest] entries, InitializeMurai): "2/3" (Label.str of element 17). widget record, element
; [nakarest] 18 of Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai) ("Drawbar"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xea (table 0xe857f8, 44
; [nakarest] entries, InitializeMurai): "3/5" (Label.str of element 18). widget record, element
; [nakarest] 19 of Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai) ("Drawbar"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xea (table 0xe857f8, 44
; [nakarest] entries, InitializeMurai): "1/3" (Label.str of element 19). widget records,
; [nakarest] elements 20-23 of Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai)
; [nakarest] ("Drawbar"): IvDrawbar1 (22 B), VwUserBitmapSp (26 B), Window (36 B), AcDrawEditBox
; [nakarest] (58 B). text the records point at, in Viewable slot 0xea (table 0xe857f8, 44
; [nakarest] entries, InitializeMurai): "DECAY :" (AcDrawEditBox.caption of element 23). widget
; [nakarest] record, element 24 of Viewable slot 0xea (table 0xe857f8, 44 entries,
; [nakarest] InitializeMurai) ("Drawbar"): AcDrawEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai): "LEVEL :"
; [nakarest] (AcDrawEditBox.caption of element 24). widget record, element 25 of Viewable slot
; [nakarest] 0xea (table 0xe857f8, 44 entries, InitializeMurai) ("Drawbar"): AcDrawEditBox (58
; [nakarest] B). text the records point at, in Viewable slot 0xea (table 0xe857f8, 44 entries,
; [nakarest] InitializeMurai): "ATTACK TIME :" (AcDrawEditBox.caption of element 25). widget
; [nakarest] record, element 26 of Viewable slot 0xea (table 0xe857f8, 44 entries,
; [nakarest] InitializeMurai) ("Drawbar"): AcDrawEditBox (58 B). text the records point at, in
; [nakarest] Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai): "RELEASE TIME :"
; [nakarest] (AcDrawEditBox.caption of element 26). widget records, elements 27-32 of Viewable
; [nakarest] slot 0xea (table 0xe857f8, 44 entries, InitializeMurai) ("Drawbar"): AcIndexWideES
; [nakarest] (42 B), IvDrawbar2 (22 B), AcDrawbarName (40 B), Window (36 B), PsParaBox (36 B),
; [nakarest] AcIndexToggle (44 B). text the records point at, in Viewable slot 0xea (table
; [nakarest] 0xe857f8, 44 entries, InitializeMurai): "SLOW" (AcIndexToggle.stroff of element
; [nakarest] 32); "FAST" (AcIndexToggle.stron of element 32). widget record, element 33 of
; [nakarest] Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai) ("Drawbar"): Label
; [nakarest] (32 B). text the records point at, in Viewable slot 0xea (table 0xe857f8, 44
; [nakarest] entries, InitializeMurai): "TREMOLO" (Label.str of element 33). widget records,
; [nakarest] elements 34-37 of Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai)
; [nakarest] ("Drawbar"): IvDrawbarNorm (22 B), VwBox (28 B), Icon (26 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xea (table 0xe857f8, 44 entries,
; [nakarest] InitializeMurai): "DRAWBAR" (Label.str of element 37). widget records, elements
; [nakarest] 38-40 of Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai)
; [nakarest] ("Drawbar"): Window (36 B), IvDrawbarSndE (22 B), AcTitleMenu (54 B). text the
; [nakarest] records point at, in Viewable slot 0xea (table 0xe857f8, 44 entries,
; [nakarest] InitializeMurai): "WRITE" (AcTitleMenu.str of element 40). widget records, elements
; [nakarest] 41-43 of Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai)
; [nakarest] ("Drawbar"): VwBox (28 B), Icon (26 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai): "DRAWBAR EDIT"
; [nakarest] (Label.str of element 43).
	.incbin "includes/generated/naka_technichord_part.bin", 0x2338, 0x6DE
; [nakarest] naka_technichord_part+0x2a16  +0x2a16..+0x3182 (0xe846e4, 1900 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0xeb (table 0xe858ac, 37 entries,
; [nakarest] InitializeMurai) ("Accordion"): Screen (34 B), Icon (26 B), IvIntVari (24 B), Label
; [nakarest] (32 B). text the records point at, in Viewable slot 0xeb (table 0xe858ac, 37
; [nakarest] entries, InitializeMurai): "ACCORDION REGISTER" (Label.str of element 3). widget
; [nakarest] records, elements 4-6 of Viewable slot 0xeb (table 0xe858ac, 37 entries,
; [nakarest] InitializeMurai) ("Accordion"): AcIndexEditSw (40 B) x2, Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xeb (table 0xe858ac, 37 entries,
; [nakarest] InitializeMurai): "TYPE" (Label.str of element 6). widget records, elements 7-10 of
; [nakarest] Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"):
; [nakarest] PsParaBox (36 B), IvAccordion (22 B), Window (36 B), Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai):
; [nakarest] "TYPE : GERMAN" (Label.str of element 10). widget records, elements 11-12 of
; [nakarest] Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"):
; [nakarest] VwUserBitmapSp (26 B), AcIndexToggle (44 B). text the records point at, in Viewable
; [nakarest] slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai): "BASS1"
; [nakarest] (AcIndexToggle.stroff of element 12); "BASS1" (AcIndexToggle.stron of element 12).
; [nakarest] widget record, element 13 of Viewable slot 0xeb (table 0xe858ac, 37 entries,
; [nakarest] InitializeMurai) ("Accordion"): AcIndexToggle (44 B). text the records point at, in
; [nakarest] Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai): "BASS2"
; [nakarest] (AcIndexToggle.stroff of element 13); "BASS2" (AcIndexToggle.stron of element 13).
; [nakarest] widget record, element 14 of Viewable slot 0xeb (table 0xe858ac, 37 entries,
; [nakarest] InitializeMurai) ("Accordion"): AcAccordionTab (52 B). text the records point at,
; [nakarest] in Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai): "~95"
; [nakarest] (AcAccordionTab.str3 of element 14); "~95" (AcAccordionTab.str1 of element 14);
; [nakarest] "~95" (AcAccordionTab.stroff of element 14); "~95" (AcAccordionTab.stron of element
; [nakarest] 14). widget record, element 15 of Viewable slot 0xeb (table 0xe858ac, 37 entries,
; [nakarest] InitializeMurai) ("Accordion"): AcAccordionTab (52 B). text the records point at,
; [nakarest] in Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai): "~95"
; [nakarest] (AcAccordionTab.str3 of element 15); "" (AcAccordionTab.str1 of element 15); "~95"
; [nakarest] (AcAccordionTab.stroff of element 15); "~95" (AcAccordionTab.stron of element 15).
; [nakarest] widget record, element 16 of Viewable slot 0xeb (table 0xe858ac, 37 entries,
; [nakarest] InitializeMurai) ("Accordion"): AcAccordionTab (52 B). text the records point at,
; [nakarest] in Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai): "~95"
; [nakarest] (AcAccordionTab.str3 of element 16); "~95" (AcAccordionTab.str1 of element 16); ""
; [nakarest] (AcAccordionTab.stroff of element 16); "" (AcAccordionTab.stron of element 16).
; [nakarest] widget record, element 17 of Viewable slot 0xeb (table 0xe858ac, 37 entries,
; [nakarest] InitializeMurai) ("Accordion"): AcAccordionTab (52 B). text the records point at,
; [nakarest] in Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai): "~95"
; [nakarest] (AcAccordionTab.str3 of element 17); "~95" (AcAccordionTab.str1 of element 17);
; [nakarest] "~95~95~95" (AcAccordionTab.stroff of element 17); "~95~95~95"
; [nakarest] (AcAccordionTab.stron of element 17). widget record, element 18 of Viewable slot
; [nakarest] 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"): AcAccordionTab
; [nakarest] (52 B). text the records point at, in Viewable slot 0xeb (table 0xe858ac, 37
; [nakarest] entries, InitializeMurai): "" (AcAccordionTab.str3 of element 18); "~95"
; [nakarest] (AcAccordionTab.str1 of element 18); "~95 ~95" (AcAccordionTab.stroff of element
; [nakarest] 18); "~95 ~95" (AcAccordionTab.stron of element 18). widget record, element 19 of
; [nakarest] Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"):
; [nakarest] AcAccordionTab (52 B). text the records point at, in Viewable slot 0xeb (table
; [nakarest] 0xe858ac, 37 entries, InitializeMurai): "" (AcAccordionTab.str3 of element 19); ""
; [nakarest] (AcAccordionTab.str1 of element 19); "~95~95~95" (AcAccordionTab.stroff of element
; [nakarest] 19); "~95~95~95" (AcAccordionTab.stron of element 19). widget record, element 20 of
; [nakarest] Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"):
; [nakarest] AcAccordionTab (52 B). text the records point at, in Viewable slot 0xeb (table
; [nakarest] 0xe858ac, 37 entries, InitializeMurai): "" (AcAccordionTab.str3 of element 20);
; [nakarest] "~95" (AcAccordionTab.str1 of element 20); "~95" (AcAccordionTab.stroff of element
; [nakarest] 20); "~95" (AcAccordionTab.stron of element 20). widget record, element 21 of
; [nakarest] Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"):
; [nakarest] AcAccordionTab (52 B). text the records point at, in Viewable slot 0xeb (table
; [nakarest] 0xe858ac, 37 entries, InitializeMurai): "" (AcAccordionTab.str3 of element 21); ""
; [nakarest] (AcAccordionTab.str1 of element 21); "~95" (AcAccordionTab.stroff of element 21);
; [nakarest] "~95" (AcAccordionTab.stron of element 21). widget records, elements 22-24 of
; [nakarest] Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"):
; [nakarest] IvAccordionX (22 B), Window (36 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai): "TYPE : ITALIAN"
; [nakarest] (Label.str of element 24). widget records, elements 25-26 of Viewable slot 0xeb
; [nakarest] (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"): VwUserBitmapSp (26 B),
; [nakarest] AcIndexToggle (44 B). text the records point at, in Viewable slot 0xeb (table
; [nakarest] 0xe858ac, 37 entries, InitializeMurai): "BASS1" (AcIndexToggle.stroff of element
; [nakarest] 26); "BASS1" (AcIndexToggle.stron of element 26). widget record, element 27 of
; [nakarest] Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"):
; [nakarest] AcIndexToggle (44 B). text the records point at, in Viewable slot 0xeb (table
; [nakarest] 0xe858ac, 37 entries, InitializeMurai): "BASS2" (AcIndexToggle.stroff of element
; [nakarest] 27); "BASS2" (AcIndexToggle.stron of element 27). widget record, element 28 of
; [nakarest] Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"):
; [nakarest] AcAccordionTab (52 B). text the records point at, in Viewable slot 0xeb (table
; [nakarest] 0xe858ac, 37 entries, InitializeMurai): "~95" (AcAccordionTab.str3 of element 28);
; [nakarest] "" (AcAccordionTab.str1 of element 28); "~95" (AcAccordionTab.stroff of element
; [nakarest] 28); "~95" (AcAccordionTab.stron of element 28). widget record, element 29 of
; [nakarest] Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"):
; [nakarest] AcAccordionTab (52 B). text the records point at, in Viewable slot 0xeb (table
; [nakarest] 0xe858ac, 37 entries, InitializeMurai): "~95" (AcAccordionTab.str3 of element 29);
; [nakarest] "" (AcAccordionTab.str1 of element 29); "" (AcAccordionTab.stroff of element 29);
; [nakarest] "" (AcAccordionTab.stron of element 29). widget record, element 30 of Viewable slot
; [nakarest] 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"): AcAccordionTab
; [nakarest] (52 B). text the records point at, in Viewable slot 0xeb (table 0xe858ac, 37
; [nakarest] entries, InitializeMurai): "~95" (AcAccordionTab.str3 of element 30); "~95"
; [nakarest] (AcAccordionTab.str1 of element 30); "" (AcAccordionTab.stroff of element 30); ""
; [nakarest] (AcAccordionTab.stron of element 30). widget record, element 31 of Viewable slot
; [nakarest] 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"): AcAccordionTab
; [nakarest] (52 B). text the records point at, in Viewable slot 0xeb (table 0xe858ac, 37
; [nakarest] entries, InitializeMurai): "~95" (AcAccordionTab.str3 of element 31); "~95"
; [nakarest] (AcAccordionTab.str1 of element 31); "~95 ~95" (AcAccordionTab.stroff of element
; [nakarest] 31); "~95 ~95" (AcAccordionTab.stron of element 31). widget record, element 32 of
; [nakarest] Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai) ("Accordion"):
; [nakarest] AcAccordionTab (52 B). text the records point at, in Viewable slot 0xeb (table
; [nakarest] 0xe858ac, 37 entries, InitializeMurai): "" (AcAccordionTab.str3 of element 32);
; [nakarest] "~95" (AcAccordionTab.str1 of element 32); "~95 ~95" (AcAccordionTab.stroff of
; [nakarest] element 32); "~95 ~95" (AcAccordionTab.stron of element 32). widget record, element
; [nakarest] 33 of Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai)
; [nakarest] ("Accordion"): AcAccordionTab (52 B). text the records point at, in Viewable slot
; [nakarest] 0xeb (table 0xe858ac, 37 entries, InitializeMurai): "" (AcAccordionTab.str3 of
; [nakarest] element 33); "" (AcAccordionTab.str1 of element 33); "~95 ~95"
; [nakarest] (AcAccordionTab.stroff of element 33); "~95 ~95" (AcAccordionTab.stron of element
; [nakarest] 33). widget record, element 34 of Viewable slot 0xeb (table 0xe858ac, 37 entries,
; [nakarest] InitializeMurai) ("Accordion"): AcAccordionTab (52 B). text the records point at,
; [nakarest] in Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai): ""
; [nakarest] (AcAccordionTab.str3 of element 34); "~95" (AcAccordionTab.str1 of element 34);
; [nakarest] "~95" (AcAccordionTab.stroff of element 34); "~95" (AcAccordionTab.stron of element
; [nakarest] 34). widget record, element 35 of Viewable slot 0xeb (table 0xe858ac, 37 entries,
; [nakarest] InitializeMurai) ("Accordion"): AcAccordionTab (52 B). text the records point at,
; [nakarest] in Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai): ""
; [nakarest] (AcAccordionTab.str3 of element 35); "" (AcAccordionTab.str1 of element 35); "~95"
; [nakarest] (AcAccordionTab.stroff of element 35); "~95" (AcAccordionTab.stron of element 35).
; [nakarest] widget record, element 36 of Viewable slot 0xeb (table 0xe858ac, 37 entries,
; [nakarest] InitializeMurai) ("Accordion"): IvAccordionX (22 B).
	.incbin "includes/generated/naka_technichord_part.bin", 0x2A16, 0x76C
; [nakarest] naka_technichord_part+0x3182  +0x3182..+0x34fa (0xe84e50, 888 B)
; [nakarest] widget records, elements 0-16 of Viewable slot 0xee (table 0xe85944, 24 entries,
; [nakarest] InitializeMurai) ("Mesage"): IvScreen (34 B), IvMesage (22 B), Window (36 B) x5,
; [nakarest] AcLanguageText (42 B) x6, IvIntComplete (24 B), IvIntReminder (24 B), IvIntError
; [nakarest] (24 B), EditSw (40 B). text the records point at, in Viewable slot 0xee (table
; [nakarest] 0xe85944, 24 entries, InitializeMurai): "~81" (EditSw.str of element 16). widget
; [nakarest] records, elements 17-19 of Viewable slot 0xee (table 0xe85944, 24 entries,
; [nakarest] InitializeMurai) ("Mesage"): AcRamBox (44 B) x2, EditSw (40 B). text the records
; [nakarest] point at, in Viewable slot 0xee (table 0xe85944, 24 entries, InitializeMurai):
; [nakarest] "~81" (EditSw.str of element 19). widget records, elements 20-23 of Viewable slot
; [nakarest] 0xee (table 0xe85944, 24 entries, InitializeMurai) ("Mesage"): Window (36 B) x2,
; [nakarest] AcRamBox (44 B), AcPleaseWait (36 B).
	.incbin "includes/generated/naka_technichord_part.bin", 0x3182, 0x378
; [nakarest] naka_technichord_part+0x34fa  +0x34fa..+0x364c (0xe851c8, 338 B)
; [nakarest] widget records, elements 0-5 of Viewable slot 0xef (table 0xe859a8, 11 entries,
; [nakarest] InitializeMurai) ("Welcom"): AcWelcomScreen (34 B), IvIntWelcome (24 B),
; [nakarest] VwUserBitmapSp (26 B) x2, Screen (34 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xef (table 0xe859a8, 11 entries, InitializeMurai): "ALL INITIAL
; [nakarest] SETTING!" (Label.str of element 5). widget records, elements 6-10 of Viewable slot
; [nakarest] 0xef (table 0xe859a8, 11 entries, InitializeMurai) ("Welcom"): IvIntWelcome (24 B)
; [nakarest] x2, Screen (34 B), IvMPver (22 B), PsParaBox (36 B).
	.incbin "includes/generated/naka_technichord_part.bin", 0x34FA, 0x152
; [nakarest] naka_technichord_part+0x364c  +0x364c..+0x37a2 (0xe8531a, 342 B)
; [nakarest] widget record, element 0 of Viewable slot 0xf0 (table 0xe859d8, 6 entries,
; [nakarest] InitializeMurai) ("Softver"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xf0 (table 0xe859d8, 6 entries, InitializeMurai): "SOFT VERSION"
; [nakarest] (TtlScreen.title of element 0). widget record, element 1 of Viewable slot 0xf0
; [nakarest] (table 0xe859d8, 6 entries, InitializeMurai) ("Softver"): PsEditBox (50 B). text
; [nakarest] the records point at, in Viewable slot 0xf0 (table 0xe859d8, 6 entries,
; [nakarest] InitializeMurai): "MAIN PROGRAM :" (PsEditBox.caption of element 1). widget record,
; [nakarest] element 2 of Viewable slot 0xf0 (table 0xe859d8, 6 entries, InitializeMurai)
; [nakarest] ("Softver"): PsEditBox (50 B). text the records point at, in Viewable slot 0xf0
; [nakarest] (table 0xe859d8, 6 entries, InitializeMurai): "MAIN TABLE :" (PsEditBox.caption of
; [nakarest] element 2). widget record, element 3 of Viewable slot 0xf0 (table 0xe859d8, 6
; [nakarest] entries, InitializeMurai) ("Softver"): PsEditBox (50 B). text the records point at,
; [nakarest] in Viewable slot 0xf0 (table 0xe859d8, 6 entries, InitializeMurai): "SUB PROGRAM :"
; [nakarest] (PsEditBox.caption of element 3). widget record, element 4 of Viewable slot 0xf0
; [nakarest] (table 0xe859d8, 6 entries, InitializeMurai) ("Softver"): PsEditBox (50 B). text
; [nakarest] the records point at, in Viewable slot 0xf0 (table 0xe859d8, 6 entries,
; [nakarest] InitializeMurai): "SOUND TABLE :" (PsEditBox.caption of element 4). widget record,
; [nakarest] element 5 of Viewable slot 0xf0 (table 0xe859d8, 6 entries, InitializeMurai)
; [nakarest] ("Softver"): IvSoftver (22 B).
	.incbin "includes/generated/naka_technichord_part.bin", 0x364C, 0x156
; [nakarest] naka_technichord_part+0x37a2  +0x37a2..+0x37f6 (0xe85470, 84 B)
; [nakarest] the table itself: Viewable slot 0x2 (table 0xe85470, 20 entries, InitializeMurai),
; [nakarest] 20 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x37A2, 0x54
; [nakarest] naka_technichord_part+0x37f6  +0x37f6..+0x394a (0xe854c4, 340 B)
; [nakarest] the table itself: Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai),
; [nakarest] 84 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x37F6, 0x154
; [nakarest] naka_technichord_part+0x394a  +0x394a..+0x395e (0xe85618, 20 B)
; [nakarest] the table itself: Viewable slot 0x4 (table 0xe85618, 4 entries, InitializeMurai), 4
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x394A, 0x14
; [nakarest] naka_technichord_part+0x395e  +0x395e..+0x3a3a (0xe8562c, 220 B)
; [nakarest] the table itself: Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai),
; [nakarest] 54 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x395E, 0xDC
; [nakarest] naka_technichord_part+0x3a3a  +0x3a3a..+0x3a4a (0xe85708, 16 B)
; [nakarest] the table itself: Viewable slot 0x7 (table 0xe85708, 3 entries, InitializeMurai), 3
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x3A3A, 0x10
; [nakarest] naka_technichord_part+0x3a4a  +0x3a4a..+0x3a5e (0xe85718, 20 B)
; [nakarest] the table itself: Viewable slot 0x8 (table 0xe85718, 4 entries, InitializeMurai), 4
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x3A4A, 0x14
; [nakarest] naka_technichord_part+0x3a5e  +0x3a5e..+0x3ad6 (0xe8572c, 120 B)
; [nakarest] the table itself: Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai),
; [nakarest] 29 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x3A5E, 0x78
; [nakarest] naka_technichord_part+0x3ad6  +0x3ad6..+0x3aea (0xe857a4, 20 B)
; [nakarest] the table itself: Viewable slot 0xa5 (table 0xe857a4, 4 entries, InitializeMurai),
; [nakarest] 4 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x3AD6, 0x14
; [nakarest] naka_technichord_part+0x3aea  +0x3aea..+0x3b2a (0xe857b8, 64 B)
; [nakarest] the table itself: Viewable slot 0xe4 (table 0xe857b8, 15 entries, InitializeMurai),
; [nakarest] 15 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x3AEA, 0x40
; [nakarest] naka_technichord_part+0x3b2a  +0x3b2a..+0x3bde (0xe857f8, 180 B)
; [nakarest] the table itself: Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai),
; [nakarest] 44 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x3B2A, 0xB4
; [nakarest] naka_technichord_part+0x3bde  +0x3bde..+0x3c76 (0xe858ac, 152 B)
; [nakarest] the table itself: Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai),
; [nakarest] 37 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x3BDE, 0x98
; [nakarest] naka_technichord_part+0x3c76  +0x3c76..+0x3cda (0xe85944, 100 B)
; [nakarest] the table itself: Viewable slot 0xee (table 0xe85944, 24 entries, InitializeMurai),
; [nakarest] 24 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x3C76, 0x64
; [nakarest] naka_technichord_part+0x3cda  +0x3cda..+0x3d0a (0xe859a8, 48 B)
; [nakarest] the table itself: Viewable slot 0xef (table 0xe859a8, 11 entries, InitializeMurai),
; [nakarest] 11 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x3CDA, 0x30
; [nakarest] naka_technichord_part+0x3d0a  +0x3d0a..+0x3d26 (0xe859d8, 28 B)
; [nakarest] the table itself: Viewable slot 0xf0 (table 0xe859d8, 6 entries, InitializeMurai),
; [nakarest] 6 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x3D0A, 0x1C
; [nakarest] naka_technichord_part+0x3d26  +0x3d26..+0x3d7c (0xe859f4, 86 B)
; [nakarest] the table itself: ResName slot 0x302 (table 0xe859f4, 20 entries, InitializeMurai),
; [nakarest] 20 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x3D26, 0x56
; [nakarest] naka_technichord_part+0x3d7c  +0x3d7c..+0x3dc0 (0xe85a4a, 68 B)
; [nakarest] name strings, entries 0-19 of ResName slot 0x302 (table 0xe859f4, 20 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0x2): "", "", "Sdmenu2", "", "", "", ....
	.incbin "includes/generated/naka_technichord_part.bin", 0x3D7C, 0x44
; [nakarest] naka_technichord_part+0x3dc0  +0x3dc0..+0x3e00 (0xe85a8e, 64 B)
; [nakarest] the table itself: ResName slot 0x303 (table 0xe85a8e, 84 entries, InitializeMurai),
; [nakarest] 84 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x3DC0, 0x40
EmbeddedPtrTable_v7_naka_technichord_part_003E00:
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
; [nakarest] naka_technichord_part+0x3f00  +0x3f00..+0x3f16 (0xe85bce, 22 B)
; [nakarest] purpose not established: 6 bytes at 0xe85bde that no registered NAKA table points into
; [nakarest] Continues the table itself: ResName slot 0x303 (table 0xe85a8e, 84 entries,
; [nakarest] InitializeMurai), 84 entry pointers x 4 bytes (starts 0xe85a8e, 16 of its 336 bytes
; [nakarest] are here or later).
	.incbin "includes/generated/naka_technichord_part.bin", 0x3F00, 0x16
; [nakarest] naka_technichord_part+0x3f16  +0x3f16..+0x4022 (0xe85be4, 268 B)
; [nakarest] name strings, entries 0-83 of ResName slot 0x303 (table 0xe85a8e, 84 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0x3): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_technichord_part.bin", 0x3F16, 0x10C
; [nakarest] naka_technichord_part+0x4022  +0x4022..+0x4038 (0xe85cf0, 22 B)
; [nakarest] the table itself: ResName slot 0x304 (table 0xe85cf0, 4 entries, InitializeMurai),
; [nakarest] 4 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x4022, 0x16
; [nakarest] naka_technichord_part+0x4038  +0x4038..+0x4046 (0xe85d06, 14 B)
; [nakarest] name strings, entries 0-3 of ResName slot 0x304 (table 0xe85cf0, 4 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0x4): "", "", "", "Sdmtune".
	.incbin "includes/generated/naka_technichord_part.bin", 0x4038, 0xE
; [nakarest] naka_technichord_part+0x4046  +0x4046..+0x4124 (0xe85d14, 222 B)
; [nakarest] the table itself: ResName slot 0x305 (table 0xe85d14, 54 entries, InitializeMurai),
; [nakarest] 54 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x4046, 0xDE
; [nakarest] naka_technichord_part+0x4124  +0x4124..+0x423c (0xe85df2, 280 B)
; [nakarest] name strings, entries 0-53 of ResName slot 0x305 (table 0xe85d14, 54 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0x5): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_technichord_part.bin", 0x4124, 0x118
; [nakarest] naka_technichord_part+0x423c  +0x423c..+0x424e (0xe85f0a, 18 B)
; [nakarest] the table itself: ResName slot 0x307 (table 0xe85f0a, 3 entries, InitializeMurai),
; [nakarest] 3 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x423C, 0x12
; [nakarest] naka_technichord_part+0x424e  +0x424e..+0x425c (0xe85f1c, 14 B)
; [nakarest] name strings, entries 0-2 of ResName slot 0x307 (table 0xe85f0a, 3 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0x7): "", "", "Sdlfthld".
	.incbin "includes/generated/naka_technichord_part.bin", 0x424E, 0xE
; [nakarest] naka_technichord_part+0x425c  +0x425c..+0x4272 (0xe85f2a, 22 B)
; [nakarest] the table itself: ResName slot 0x308 (table 0xe85f2a, 4 entries, InitializeMurai),
; [nakarest] 4 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_part.bin", 0x425C, 0x16
; [nakarest] naka_technichord_part+0x4272  +0x4272..+0x4280 (0xe85f40, 14 B)
; [nakarest] name strings, entries 0-3 of ResName slot 0x308 (table 0xe85f2a, 4 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0x8): "", "", "", "Sdmixer".
	.incbin "includes/generated/naka_technichord_part.bin", 0x4272, 0xE

; External label offsets within the binary blob above.
