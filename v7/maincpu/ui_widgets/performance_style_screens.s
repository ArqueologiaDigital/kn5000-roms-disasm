
; Performance & Style screen widgets (477 widgets, 29164 bytes)
; Source: maincpu/ui_widgets/naka_perf_style.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_perf_style
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
; Viewable slot 0xfd: RegObjTabl 0x1600010, ViewableProc, 0x1de,
; 0xe1344e, 0xfd in InitializeNaka (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 478, table} at 0x27ed2 +
; 14*0xfd. Element 0 is named "ftdemo01" in ResName slot 0x3fd. Links:
; all 478 records consistent.
;
; MainFunction slot 0x14b: RegObjTabl 0x1600003, MainFunctionProc, 0x0,
; 0xe14824, 0x14b in InitializeNaka (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 0, table} at 0x27ed2 +
; 14*0x14b.
;
; ResName slot 0x3fd: RegObjTabl 0x160000f, ResNameProc, 0x1de,
; 0xe13bca, 0x3fd in InitializeNaka (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 478, table} at 0x27ed2 +
; 14*0x3fd.
;
; MainFunction slot 0x44b: RegObjTabl 0x1600003, MainFunctionProc, 0x0,
; 0xe14828, 0x44b in InitializeNaka (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 0, table} at 0x27ed2 +
; 14*0x44b.
; -----------------------------------------------------------------------------

; [nakarest] NAKA_PerfReg_Container_Root  +0x0..+0x4ada (0xe0e974, 19162 B)
; [nakarest] widget record, element 0 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): ""
; [nakarest] (TtlScreen.title of element 0). widget record, element 1 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): VwUserBitmapByName (26
; [nakarest] B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "FTBMP01" (VwUserBitmapByName.file of element 1). widget record,
; [nakarest] element 2 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): TtlScreen (42 B). text the records point at, in Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka): "" (TtlScreen.title of element 2).
; [nakarest] widget records, elements 3-5 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Box (26 B) x2, Label (32 B). text the records point
; [nakarest] at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "200
; [nakarest] Preset" (Label.str of element 5). widget record, element 6 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Performance" (Label.str of element 6). widget records, elements
; [nakarest] 7-8 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Box (26 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "20 Custom" (Label.str of
; [nakarest] element 8). widget records, elements 9-10 of Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "3 Composer" (Label.str of element 10). widget record, element 11
; [nakarest] of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Back-up" (Label.str of element 11). widget records,
; [nakarest] elements 12-15 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Line (26 B) x3, Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~81" (Label.str of
; [nakarest] element 15). widget records, elements 16-18 of Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B) x2, Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "~7f" (Label.str of element 18). widget records, elements 19-26 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line
; [nakarest] (26 B) x7, Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "~85" (Label.str of element 26). widget
; [nakarest] records, elements 27-29 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Box (26 B) x2, Label (32 B). text the records point
; [nakarest] at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "FD"
; [nakarest] (Label.str of element 29). widget record, element 30 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "~7f" (Label.str of element 30). widget records, elements 31-33 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B) x2,
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "~80" (Label.str of element 33). widget record, element
; [nakarest] 34 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Volatile" (Label.str of element 34).
; [nakarest] widget record, element 35 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Non Volatile" (Label.str
; [nakarest] of element 35). widget record, element 36 of Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Play Only"
; [nakarest] (Label.str of element 36). widget record, element 37 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "~7f" (Label.str of element 37). widget records, elements 38-65 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B) x27,
; [nakarest] TtlScreen (42 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka): "" (TtlScreen.title of element 65). widget records,
; [nakarest] elements 66-67 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Box (26 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Style Data" (Label.str of
; [nakarest] element 67). widget records, elements 68-69 of Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "20 Custom" (Label.str of element 69). widget records, elements
; [nakarest] 70-71 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Box (26 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "3 Composer" (Label.str of
; [nakarest] element 71). widget record, element 72 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~7f" (Label.str
; [nakarest] of element 72). widget records, elements 73-82 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B) x9, Label (32 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Style Convert" (Label.str of element 82). widget records,
; [nakarest] elements 83-89 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Line (26 B) x2, Box (26 B) x4, Label (32 B). text the records point
; [nakarest] at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~7f"
; [nakarest] (Label.str of element 89). widget records, elements 90-94 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B) x4, Label
; [nakarest] (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "~7f" (Label.str of element 94). widget records, elements
; [nakarest] 95-99 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Box (26 B) x4, Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~7f" (Label.str of
; [nakarest] element 99). widget records, elements 100-102 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B) x2, Label (32 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "FD" (Label.str of element 102). widget records, elements 103-105
; [nakarest] of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Box (26 B) x2, Label (32 B). text the records point at, in Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka): "~80" (Label.str of element 105).
; [nakarest] widget record, element 106 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~7f" (Label.str of
; [nakarest] element 106). widget record, element 107 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Convert from"
; [nakarest] (Label.str of element 107). widget record, element 108 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "various instruments !" (Label.str of element 108). widget record, element 109 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] TtlScreen (42 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka): "" (TtlScreen.title of element 109). widget record,
; [nakarest] element 110 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): VwUserBitmapByName (26 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "FTBMP02"
; [nakarest] (VwUserBitmapByName.file of element 110). widget records, elements 111-115 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] AcLanguageText (42 B) x3, Box (26 B), TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): ""
; [nakarest] (TtlScreen.title of element 115). widget records, elements 116-118 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): AcLanguageText (42
; [nakarest] B) x2, TtlScreen (42 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "" (TtlScreen.title of element 118). widget
; [nakarest] records, elements 119-120 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): AcLanguageText (42 B), VwUserBitmapByName (26 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "FTBMP03" (VwUserBitmapByName.file of element 120). widget record,
; [nakarest] element 121 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): TtlScreen (42 B). text the records point at, in Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka): "" (TtlScreen.title of element 121).
; [nakarest] widget record, element 122 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): VwUserBitmapByName (26 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "FTBMP04"
; [nakarest] (VwUserBitmapByName.file of element 122). widget records, elements 123-124 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] AcLanguageText (42 B), TtlScreen (42 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "" (TtlScreen.title of
; [nakarest] element 124). widget records, elements 125-126 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): AcLanguageText (42 B),
; [nakarest] TtlScreen (42 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka): "" (TtlScreen.title of element 126). widget records,
; [nakarest] elements 127-129 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): AcLanguageText (42 B) x2, TtlScreen (42 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "" (TtlScreen.title of element 129). widget records, elements
; [nakarest] 130-132 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): AcLanguageText (42 B) x2, TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): ""
; [nakarest] (TtlScreen.title of element 132). widget records, elements 133-135 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): AcLanguageText (42
; [nakarest] B) x2, VwUserBitmapByName (26 B). text the records point at, in Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka): "FTBMP05" (VwUserBitmapByName.file
; [nakarest] of element 135). widget record, element 136 of Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka) ("ftdemo01"): TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): ""
; [nakarest] (TtlScreen.title of element 136). widget records, elements 137-138 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): AcLanguageText (42
; [nakarest] B), TtlScreen (42 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "BANK VIEW" (TtlScreen.title of element
; [nakarest] 138). widget records, elements 139-140 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Box (26 B), Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "BANK 1:For Dinner Show" (Label.str of element 140). widget records, elements
; [nakarest] 141-142 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): PsEditSwBox (38 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~9b" (Label.str
; [nakarest] of element 142). widget record, element 143 of Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~98"
; [nakarest] (Label.str of element 143). widget record, element 144 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): EditSw (40 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "~80" (EditSw.str of element 144). widget record, element 145 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] EditSw (40 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka): "~80" (EditSw.str of element 145). widget record,
; [nakarest] element 146 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "BANK" (Label.str of element 146). widget
; [nakarest] record, element 147 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "NAMING" (Label.str of
; [nakarest] element 147). widget record, element 148 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "MEMORY"
; [nakarest] (Label.str of element 148). widget record, element 149 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "NAMING" (Label.str of element 149). widget records, elements 150-151 of Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "8:Curtain Call !!" (Label.str of element 151). widget
; [nakarest] record, element 152 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "3:Hotel Combo" (Label.str
; [nakarest] of element 152). widget record, element 153 of Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "7:Pub Sing
; [nakarest] Along" (Label.str of element 153). widget record, element 154 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "6:Solo Romance" (Label.str of element 154). widget record,
; [nakarest] element 155 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "5:Casino Lights" (Label.str of element
; [nakarest] 155). widget record, element 156 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "4:Laid Back
; [nakarest] Octave" (Label.str of element 156). widget record, element 157 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "1:Overture" (Label.str of element 157). widget record, element
; [nakarest] 158 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "2:Late At Night" (Label.str of element
; [nakarest] 158). widget record, element 159 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "BANK" (Label.str
; [nakarest] of element 159). widget records, elements 160-161 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "PAGE 2/2" (Label.str of element 161). widget record, element 162
; [nakarest] of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] TtlScreen (42 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka): "SMF DIRECT PLAY " (TtlScreen.title of element 162).
; [nakarest] widget record, element 163 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~aa=115" (Label.str of
; [nakarest] element 163). widget record, element 164 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~7f" (Label.str
; [nakarest] of element 164). widget record, element 165 of Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "MIC"
; [nakarest] (Label.str of element 165). widget records, elements 166-167 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B), Label (32
; [nakarest] B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Oh,I want to be in that num" (Label.str of element 167). widget
; [nakarest] record, element 168 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "ber." (Label.str of
; [nakarest] element 168). widget record, element 169 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Oh,When the
; [nakarest] Saints" (Label.str of element 169). widget record, element 170 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "When the Saints go marchin'in." (Label.str of element 170).
; [nakarest] widget record, element 171 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "go marchin'in."
; [nakarest] (Label.str of element 171). widget record, element 172 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "When The Saints" (Label.str of element 172). widget record, element 173 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "" (Label.str of element 173). widget record, element 174
; [nakarest] of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "PLAY" (Label.str of element 174). widget record, element
; [nakarest] 175 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): VwEditSwBox (44 B). text the records point at, in Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka): "" (VwEditSwBox.str of element 175).
; [nakarest] widget records, elements 176-181 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Bitmap (26 B) x3, PsEditSwBox (38 B) x2,
; [nakarest] VwEditSwBox (44 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "" (VwEditSwBox.str of element 181). widget
; [nakarest] records, elements 182-183 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Bitmap (26 B), VwEditSwBox (44 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): ""
; [nakarest] (VwEditSwBox.str of element 183). widget records, elements 184-185 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Bitmap (26 B),
; [nakarest] TtlScreen (42 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka): "ENTERTAINER" (TtlScreen.title of element 185).
; [nakarest] widget records, elements 186-188 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Box (26 B), Line (26 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "MIC BALANCE : 100" (Label.str of element 188). widget record,
; [nakarest] element 189 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "VOCAL REVERB" (Label.str of element 189).
; [nakarest] widget record, element 190 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "REVERB TIME: 2.00s"
; [nakarest] (Label.str of element 190). widget record, element 191 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "TYPE :" (Label.str of element 191). widget record, element 192 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "ON/OFF : ON" (Label.str of element 192). widget record, element
; [nakarest] 193 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "EXCITER FC : 1kHz" (Label.str of element
; [nakarest] 193). widget record, element 194 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "EXCITER G : +
; [nakarest] 2.0" (Label.str of element 194). widget record, element 195 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "VOLUME : 84" (Label.str of element 195). widget records, elements
; [nakarest] 196-197 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Box (26 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "STAGE" (Label.str of element
; [nakarest] 197). widget record, element 198 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~7f" (Label.str
; [nakarest] of element 198). widget record, element 199 of Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~7f"
; [nakarest] (Label.str of element 199). widget record, element 200 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "~7f" (Label.str of element 200). widget record, element 201 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "~7f" (Label.str of element 201). widget record, element 202 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "~7f" (Label.str of element 202). widget record, element
; [nakarest] 203 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "VOCALIST" (Label.str of element 203).
; [nakarest] widget record, element 204 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "WORKSTATION" (Label.str
; [nakarest] of element 204). widget record, element 205 of Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "FADE IN/OUT"
; [nakarest] (Label.str of element 205). widget record, element 206 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "SETTING" (Label.str of element 206). widget record, element 207 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "MIXER" (Label.str of element 207). widget record, element 208 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "DISK LOAD" (Label.str of element 208). widget records,
; [nakarest] elements 209-210 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Box (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "MUTE
; [nakarest] KEYS:OFF" (Label.str of element 210). widget records, elements 211-212 of Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "PANIC" (Label.str of element 212). widget records,
; [nakarest] elements 213-214 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Box (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~85"
; [nakarest] (Label.str of element 214). widget records, elements 215-216 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B), Label (32
; [nakarest] B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "~81" (Label.str of element 216). widget records, elements 217-218
; [nakarest] of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Box (26 B), Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "~9b" (Label.str of element 218). widget
; [nakarest] records, elements 219-220 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Line (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~98"
; [nakarest] (Label.str of element 220). widget record, element 221 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "ITEM" (Label.str of element 221). widget record, element 222 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "VALUE" (Label.str of element 222). widget records, elements
; [nakarest] 223-224 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Frame (28 B), TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): ""
; [nakarest] (TtlScreen.title of element 224). widget record, element 225 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): VwUserBitmapByName (26
; [nakarest] B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "FTBMP06" (VwUserBitmapByName.file of element 225). widget record,
; [nakarest] element 226 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): TtlScreen (42 B). text the records point at, in Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka): "FADE IN/OUT SETTING"
; [nakarest] (TtlScreen.title of element 226). widget records, elements 227-228 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B), Label
; [nakarest] (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "FADE IN" (Label.str of element 228). widget record,
; [nakarest] element 229 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Time :" (Label.str of element 229). widget
; [nakarest] record, element 230 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "FADE OUT" (Label.str of
; [nakarest] element 230). widget record, element 231 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Time : 4
; [nakarest] measure" (Label.str of element 231). widget record, element 232 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Auto reset : ON" (Label.str of element 232). widget record,
; [nakarest] element 233 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Auto stop Rhythm : ON" (Label.str of
; [nakarest] element 233). widget record, element 234 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Auto stop Seq :
; [nakarest] ON" (Label.str of element 234). widget records, elements 235-237 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Frame (28 B), Box
; [nakarest] (26 B), Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "2 measure" (Label.str of element 237).
; [nakarest] widget records, elements 238-239 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): PsEditSwBox (38 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "~9b" (Label.str of element 239). widget record, element 240 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "~98" (Label.str of element 240). widget records,
; [nakarest] elements 241-243 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Line (26 B), PsEditSwBox (38 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "~85" (Label.str of element 243). widget record, element 244 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "~81" (Label.str of element 244). widget records,
; [nakarest] elements 245-246 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Line (26 B), TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): ""
; [nakarest] (TtlScreen.title of element 246). widget records, elements 247-249 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B) x2,
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Music Stylist" (Label.str of element 249). widget
; [nakarest] record, element 250 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "> 1000 Styles of World
; [nakarest] wide Music !" (Label.str of element 250). widget record, element 251 of Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "> Style explorer by Genre" (Label.str of element 251). widget
; [nakarest] record, element 252 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "> Alphabetical style
; [nakarest] select" (Label.str of element 252). widget record, element 253 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): TtlScreen (42 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "STYLE EXPLORER" (TtlScreen.title of element 253). widget records,
; [nakarest] elements 254-255 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Box (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Easy
; [nakarest] Listening" (Label.str of element 255). widget record, element 256 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Rock & Pop" (Label.str of element 256). widget record, element
; [nakarest] 257 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Party Music" (Label.str of element 257).
; [nakarest] widget record, element 258 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Dance Pop" (Label.str of
; [nakarest] element 258). widget record, element 259 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Gospel/Blues/R&B" (Label.str of element 259). widget record, element 260 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Jazz & Swing" (Label.str of element 260). widget record,
; [nakarest] element 261 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Show/Trad Dance" (Label.str of element
; [nakarest] 261). widget record, element 262 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Trad / Folk"
; [nakarest] (Label.str of element 262). widget record, element 263 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Country" (Label.str of element 263). widget record, element 264 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Latin / World" (Label.str of element 264). widget records,
; [nakarest] elements 265-267 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Frame (28 B), PsEditSwBox (38 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "OK" (Label.str of element 267). widget records, elements 268-269
; [nakarest] of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] PsEditSwBox (38 B), Label (32 B). text the records point at, in Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka): "~85" (Label.str of element 269).
; [nakarest] widget record, element 270 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~81" (Label.str of
; [nakarest] element 270). widget records, elements 271-273 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B), PsEditSwBox (38
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka): "~85" (Label.str of element 273). widget record,
; [nakarest] element 274 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "~81" (Label.str of element 274). widget
; [nakarest] records, elements 275-276 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Line (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "MAIN
; [nakarest] CATEGORY" (Label.str of element 276). widget records, elements 277-278 of Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Glamrock Piano" (Label.str of element 278). widget
; [nakarest] record, element 279 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "70's Hits" (Label.str of
; [nakarest] element 279). widget record, element 280 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Euro Pop
; [nakarest] Shuffle" (Label.str of element 280). widget record, element 281 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "70's Power Rock" (Label.str of element 281). widget record,
; [nakarest] element 282 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "80's Love Songs" (Label.str of element
; [nakarest] 282). widget record, element 283 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "In The Eighties"
; [nakarest] (Label.str of element 283). widget record, element 284 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Pop
; [nakarest] Beat" (Label.str of element 284). widget record, element 285 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "8 Beat Groove" (Label.str of element 285). widget record, element
; [nakarest] 286 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "80's Pop Ballads" (Label.str of element
; [nakarest] 286). widget record, element 287 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Rock Gig"
; [nakarest] (Label.str of element 287). widget records, elements 288-289 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Frame (28 B), Label (32
; [nakarest] B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "SUB CATEGORY" (Label.str of element 289). widget record, element
; [nakarest] 290 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "2/4" (Label.str of element 290). widget
; [nakarest] record, element 291 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "STYLE EXPLORER"
; [nakarest] (TtlScreen.title of element 291). widget records, elements 292-293 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B), Label
; [nakarest] (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Easy Listening" (Label.str of element 293). widget
; [nakarest] record, element 294 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Rock & Pop" (Label.str of
; [nakarest] element 294). widget record, element 295 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Party Music"
; [nakarest] (Label.str of element 295). widget record, element 296 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Dance Pop" (Label.str of element 296). widget record, element 297 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Gospel/Blues/R&B" (Label.str of element 297). widget record,
; [nakarest] element 298 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Jazz & Swing" (Label.str of element 298).
; [nakarest] widget record, element 299 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Show/Trad Dance"
; [nakarest] (Label.str of element 299). widget record, element 300 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Trad / Folk" (Label.str of element 300). widget record, element 301 of Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Country" (Label.str of element 301). widget record, element 302
; [nakarest] of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Latin / World" (Label.str of element 302). widget
; [nakarest] records, elements 303-305 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Frame (28 B), PsEditSwBox (38 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "OK" (Label.str of element 305). widget records, elements 306-307
; [nakarest] of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] PsEditSwBox (38 B), Label (32 B). text the records point at, in Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka): "~85" (Label.str of element 307).
; [nakarest] widget record, element 308 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~81" (Label.str of
; [nakarest] element 308). widget records, elements 309-311 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B), PsEditSwBox (38
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka): "~85" (Label.str of element 311). widget record,
; [nakarest] element 312 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "~81" (Label.str of element 312). widget
; [nakarest] records, elements 313-314 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Line (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "MAIN
; [nakarest] CATEGORY" (Label.str of element 314). widget records, elements 315-316 of Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Glamrock Piano" (Label.str of element 316). widget
; [nakarest] record, element 317 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "70's Hits" (Label.str of
; [nakarest] element 317). widget record, element 318 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Euro Pop
; [nakarest] Shuffle" (Label.str of element 318). widget record, element 319 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "70's Power Rock" (Label.str of element 319). widget record,
; [nakarest] element 320 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "80's Love Songs" (Label.str of element
; [nakarest] 320). widget record, element 321 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "In The Eighties"
; [nakarest] (Label.str of element 321). widget record, element 322 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Pop
; [nakarest] Beat" (Label.str of element 322). widget record, element 323 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "8 Beat Groove" (Label.str of element 323). widget record, element
; [nakarest] 324 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "80's Pop Ballads" (Label.str of element
; [nakarest] 324). widget record, element 325 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Rock Gig"
; [nakarest] (Label.str of element 325). widget records, elements 326-327 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Frame (28 B), Label (32
; [nakarest] B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "SUB CATEGORY" (Label.str of element 327). widget record, element
; [nakarest] 328 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "2/4" (Label.str of element 328). widget
; [nakarest] record, element 329 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "STYLE EXPLORER"
; [nakarest] (TtlScreen.title of element 329). widget records, elements 330-331 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B), Label
; [nakarest] (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Euro Pop Shuffle: TEMPO" (Label.str of element 331).
; [nakarest] widget record, element 332 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Shuffle Synth 144"
; [nakarest] (Label.str of element 332). widget record, element 333 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Jump Brass 144" (Label.str of element 333). widget record, element 334 of Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Pop Leader 144" (Label.str of element 334). widget record,
; [nakarest] element 335 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Shuffle Organ 144" (Label.str of element
; [nakarest] 335). widget record, element 336 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "80's Love Songs
; [nakarest] : TEMPO" (Label.str of element 336). widget record, element 337 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Analogue Ballad 106" (Label.str of element 337). widget record,
; [nakarest] element 338 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Don't Fret! 106" (Label.str of element
; [nakarest] 338). widget record, element 339 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "EP Of The 80's
; [nakarest] 106" (Label.str of element 339). widget record, element 340 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Sax Production 106" (Label.str of element 340). widget records,
; [nakarest] elements 341-343 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Frame (28 B), PsEditSwBox (38 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "SKIP" (Label.str of element 343). widget record, element 344 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "~9b" (Label.str of element 344). widget record, element
; [nakarest] 345 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "~98" (Label.str of element 345). widget
; [nakarest] records, elements 346-348 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Line (26 B), PsEditSwBox (38 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "~85" (Label.str of element 348). widget record, element 349 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "~81" (Label.str of element 349). widget records,
; [nakarest] elements 350-351 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Line (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "CATEGORY :
; [nakarest] Rock & Pop" (Label.str of element 351). widget record, element 352 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): TtlScreen (42 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "STYLE EXPLORER" (TtlScreen.title of element 352). widget records,
; [nakarest] elements 353-354 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Box (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Euro Pop
; [nakarest] Shuffle: TEMPO" (Label.str of element 354). widget record, element 355 of Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Shuffle Synth 144" (Label.str of element 355). widget record,
; [nakarest] element 356 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Jump Brass 144" (Label.str of element
; [nakarest] 356). widget record, element 357 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Pop Leader 144"
; [nakarest] (Label.str of element 357). widget record, element 358 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Shuffle Organ 144" (Label.str of element 358). widget record, element 359 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "80's Love Songs : TEMPO" (Label.str of element 359).
; [nakarest] widget record, element 360 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Analogue Ballad 106"
; [nakarest] (Label.str of element 360). widget record, element 361 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Don't Fret! 106" (Label.str of element 361). widget record, element 362 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "EP Of The 80's 106" (Label.str of element 362). widget
; [nakarest] record, element 363 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Sax Production 106"
; [nakarest] (Label.str of element 363). widget records, elements 364-366 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Frame (28 B),
; [nakarest] PsEditSwBox (38 B), Label (32 B). text the records point at, in Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka): "SKIP" (Label.str of element 366).
; [nakarest] widget record, element 367 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~9b" (Label.str of
; [nakarest] element 367). widget record, element 368 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~98" (Label.str
; [nakarest] of element 368). widget records, elements 369-371 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B), PsEditSwBox (38
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka): "~85" (Label.str of element 371). widget record,
; [nakarest] element 372 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "~81" (Label.str of element 372). widget
; [nakarest] records, elements 373-374 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Line (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "CATEGORY :
; [nakarest] Rock & Pop" (Label.str of element 374). widget record, element 375 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): TtlScreen (42 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "ALPHABETICAL EXPLORER" (TtlScreen.title of element 375). widget
; [nakarest] records, elements 376-377 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Box (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "B: TEMPO"
; [nakarest] (Label.str of element 377). widget records, elements 378-379 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Frame (28 B), Label (32
; [nakarest] B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Ballroom Fiddle 101" (Label.str of element 379). widget record,
; [nakarest] element 380 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Bebop Solo 121" (Label.str of element
; [nakarest] 380). widget record, element 381 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Barbar Shop 86"
; [nakarest] (Label.str of element 381). widget record, element 382 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Benson Frets 147" (Label.str of element 382). widget record, element 383 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Big Stage 98" (Label.str of element 383). widget record,
; [nakarest] element 384 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Billy's E.P 132" (Label.str of element
; [nakarest] 384). widget record, element 385 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Bonjour Paris !
; [nakarest] 106" (Label.str of element 385). widget record, element 386 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Breathy Night 112" (Label.str of element 386). widget record,
; [nakarest] element 387 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Bridge Too Far 128" (Label.str of element
; [nakarest] 387). widget records, elements 388-389 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): PsEditSwBox (38 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "~9b" (Label.str of element 389). widget record, element 390 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "~98" (Label.str of element 390). widget record, element
; [nakarest] 391 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "~98" (Label.str of element 391). widget
; [nakarest] records, elements 392-394 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Line (26 B), PsEditSwBox (38 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "SKIP" (Label.str of element 394). widget record, element 395 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "~9b" (Label.str of element 395). widget record, element
; [nakarest] 396 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "~98" (Label.str of element 396). widget
; [nakarest] records, elements 397-398 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Line (26 B), TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "ALPHABETICAL EXPLORER" (TtlScreen.title of element 398). widget records, elements
; [nakarest] 399-400 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Box (26 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "C: TEMPO" (Label.str of
; [nakarest] element 400). widget record, element 401 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Cafe Jazz 76"
; [nakarest] (Label.str of element 401). widget record, element 402 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Charming Waltz 88" (Label.str of element 402). widget record, element 403 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Casino Show 130" (Label.str of element 403). widget
; [nakarest] record, element 404 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Chubby's Solo 147"
; [nakarest] (Label.str of element 404). widget record, element 405 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Click Piano 104" (Label.str of element 405). widget record, element 406 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Crystal Dance 130" (Label.str of element 406). widget
; [nakarest] record, element 407 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Curtain Up! 116"
; [nakarest] (Label.str of element 407). widget records, elements 408-410 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Frame (28 B),
; [nakarest] PsEditSwBox (38 B), Label (32 B). text the records point at, in Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka): "~9b" (Label.str of element 410).
; [nakarest] widget record, element 411 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~98" (Label.str of
; [nakarest] element 411). widget record, element 412 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~98" (Label.str
; [nakarest] of element 412). widget records, elements 413-415 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B), PsEditSwBox (38
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka): "SKIP" (Label.str of element 415). widget record,
; [nakarest] element 416 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "~9b" (Label.str of element 416). widget
; [nakarest] record, element 417 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~98" (Label.str of
; [nakarest] element 417). widget records, elements 418-419 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B), TtlScreen (42 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "ALPHABETICAL EXPLORER" (TtlScreen.title of element 419). widget
; [nakarest] records, elements 420-421 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Box (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "C: TEMPO"
; [nakarest] (Label.str of element 421). widget record, element 422 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Cafe Jazz 76" (Label.str of element 422). widget record, element 423 of Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Charming Waltz 88" (Label.str of element 423). widget record,
; [nakarest] element 424 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Casino Show 130" (Label.str of element
; [nakarest] 424). widget record, element 425 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Chubby's Solo
; [nakarest] 147" (Label.str of element 425). widget record, element 426 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Click Piano 104" (Label.str of element 426). widget record,
; [nakarest] element 427 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Crystal Dance 130" (Label.str of element
; [nakarest] 427). widget record, element 428 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Curtain Up! 116"
; [nakarest] (Label.str of element 428). widget records, elements 429-431 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Frame (28 B),
; [nakarest] PsEditSwBox (38 B), Label (32 B). text the records point at, in Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka): "~9b" (Label.str of element 431).
; [nakarest] widget record, element 432 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~98" (Label.str of
; [nakarest] element 432). widget record, element 433 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~98" (Label.str
; [nakarest] of element 433). widget records, elements 434-436 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B), PsEditSwBox (38
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka): "SKIP" (Label.str of element 436). widget record,
; [nakarest] element 437 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "~9b" (Label.str of element 437). widget
; [nakarest] record, element 438 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~98" (Label.str of
; [nakarest] element 438). widget records, elements 439-440 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B), TtlScreen (42 B).
; [nakarest] text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "STYLE EXPLORER" (TtlScreen.title of element 440). widget records,
; [nakarest] elements 441-442 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Box (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Easy
; [nakarest] Listening" (Label.str of element 442). widget record, element 443 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Rock & Pop" (Label.str of element 443). widget record, element
; [nakarest] 444 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Party Music" (Label.str of element 444).
; [nakarest] widget record, element 445 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Dance Pop" (Label.str of
; [nakarest] element 445). widget record, element 446 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Gospel/Blues/R&B" (Label.str of element 446). widget record, element 447 of
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Jazz & Swing" (Label.str of element 447). widget record,
; [nakarest] element 448 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "Show/Trad Dance" (Label.str of element
; [nakarest] 448). widget record, element 449 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Trad / Folk"
; [nakarest] (Label.str of element 449). widget record, element 450 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka):
; [nakarest] "Country" (Label.str of element 450). widget record, element 451 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "Latin / World" (Label.str of element 451). widget records,
; [nakarest] elements 452-454 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Frame (28 B), PsEditSwBox (38 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "OK" (Label.str of element 454). widget records, elements 455-456
; [nakarest] of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"):
; [nakarest] PsEditSwBox (38 B), Label (32 B). text the records point at, in Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka): "~85" (Label.str of element 456).
; [nakarest] widget record, element 457 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "~81" (Label.str of
; [nakarest] element 457). widget records, elements 458-460 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Line (26 B), PsEditSwBox (38
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e,
; [nakarest] 478 entries, InitializeNaka): "~85" (Label.str of element 460). widget record,
; [nakarest] element 461 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "~81" (Label.str of element 461). widget
; [nakarest] records, elements 462-463 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Line (26 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "MAIN
; [nakarest] CATEGORY" (Label.str of element 463). widget records, elements 464-465 of Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Box (26 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka): "Glamrock Piano" (Label.str of element 465). widget
; [nakarest] record, element 466 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "70's Hits" (Label.str of
; [nakarest] element 466). widget record, element 467 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Euro Pop
; [nakarest] Shuffle" (Label.str of element 467). widget record, element 468 of Viewable slot
; [nakarest] 0xfd (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "70's Power Rock" (Label.str of element 468). widget record,
; [nakarest] element 469 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "80's Love Songs" (Label.str of element
; [nakarest] 469). widget record, element 470 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "In The Eighties"
; [nakarest] (Label.str of element 470). widget record, element 471 of Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Pop
; [nakarest] Beat" (Label.str of element 471). widget record, element 472 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "8 Beat Groove" (Label.str of element 472). widget record, element
; [nakarest] 473 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "80's Pop Ballads" (Label.str of element
; [nakarest] 473). widget record, element 474 of Viewable slot 0xfd (table 0xe1344e, 478
; [nakarest] entries, InitializeNaka) ("ftdemo01"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka): "Rock Gig"
; [nakarest] (Label.str of element 474). widget records, elements 475-476 of Viewable slot 0xfd
; [nakarest] (table 0xe1344e, 478 entries, InitializeNaka) ("ftdemo01"): Frame (28 B), Label (32
; [nakarest] B). text the records point at, in Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka): "SUB CATEGORY" (Label.str of element 476). widget record, element
; [nakarest] 477 of Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka)
; [nakarest] ("ftdemo01"): Label (32 B). text the records point at, in Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka): "2/4" (Label.str of element 477).
NAKA_PerfReg_Container_Root:
	.incbin "includes/generated/naka_perf_style.bin", 0x0, 0x4ADA
; [nakarest] NAKA_UIObjectTable  +0x4ada..+0x5256 (0xe1344e, 1916 B)
; [nakarest] the table itself: Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka),
; [nakarest] 478 entry pointers x 4 bytes.
NAKA_UIObjectTable:
	.incbin "includes/generated/naka_perf_style.bin", 0x4ADA, 0x77C
; [nakarest] naka_perf_style+0x5256  +0x5256..+0x59d4 (0xe13bca, 1918 B)
; [nakarest] the table itself: ResName slot 0x3fd (table 0xe13bca, 478 entries, InitializeNaka),
; [nakarest] 478 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_perf_style.bin", 0x5256, 0x77E
; [nakarest] naka_perf_style+0x59d4  +0x59d4..+0x5eb0 (0xe14348, 1244 B)
; [nakarest] name strings, entries 0-477 of ResName slot 0x3fd (table 0xe13bca, 478 entries,
; [nakarest] InitializeNaka) (names for Viewable slot 0xfd): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_perf_style.bin", 0x59D4, 0x4DC
; [nakarest] naka_perf_style+0x5eb0  +0x5eb0..+0x5eb4 (0xe14824, 4 B)
; [nakarest] the table itself: MainFunction slot 0x14b (table 0xe14824, 0 entries,
; [nakarest] InitializeNaka), 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_perf_style.bin", 0x5EB0, 0x4
; [nakarest] naka_perf_style+0x5eb4  +0x5eb4..+0x71ec (0xe14828, 4920 B)
; [nakarest] the table itself: MainFunction slot 0x44b (table 0xe14828, 0 entries,
; [nakarest] InitializeNaka), 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_perf_style.bin", 0x5EB4, 0x1338
; NAKA_UIObjectTable is at offset 0x4ada within the binary blob above.
; Referenced from flash_floppy_handlers.s (RegisterObjectTable call).
