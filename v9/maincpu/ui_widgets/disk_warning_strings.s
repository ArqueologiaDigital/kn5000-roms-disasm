
; Multilingual Disk Operation Warning Strings (30 widgets, 16430 bytes)
; Source: maincpu/ui_widgets/naka_disk_warning.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_disk_warning
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
; ApFunction slot 0x120: RegObjTabl 0x1600002, ApFunctionProc, 0xc,
; 0xeab2b4, 0x120 in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x120.
;
; Class slot 0x160: RegObjTable 0x1600004, ClassProc, 0xeada92,
; 0xeac9ee, 0x160 in InitializeRoot (display/graphics_text_vga.s) -- the
; count, 109, is the word at 0xeada92; RegisterObjectTable stores
; {class, proc, count, table} at 0x27ed2 + 14*0x160.
;
; ApFunction slot 0x420: RegObjTabl 0x1600002, ApFunctionProc, 0xc,
; 0xeab2e8, 0x420 in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x420.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; [nakarest_retype] DiskWarning_ConfirmStrings
; DiskWarning_ConfirmStrings  --  naka_disk_warning +0x0..+0x1226 (ROM 0xea8cac..0xea9ed2), 4646 bytes
; No RegObjTabl-registered table points at the start of these 4646 bytes
; (0xea8cac..0xea9ed2); purpose not established by that route.
; -----------------------------------------------------------------------------
DiskWarning_ConfirmStrings:
	.incbin "includes/generated/naka_disk_warning.bin", 0x0, 0x1226
; -----------------------------------------------------------------------------
; [nakarest_retype] Data_SoundEditorCharsLayout
; Data_SoundEditorCharsLayout  --  naka_disk_warning +0x1226..+0x164e (ROM 0xea9ed2..0xeaa2fa), 1064 bytes
; No RegObjTabl-registered table points at the start of these 1064 bytes
; (0xea9ed2..0xeaa2fa); purpose not established by that route.
; -----------------------------------------------------------------------------
Data_SoundEditorCharsLayout:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1226, 0x428
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_OK
; NakaInst_OK  --  naka_disk_warning +0x164e..+0x166a (ROM 0xeaa2fa..0xeaa316), 28 bytes
; No RegObjTabl-registered table points at the start of these 28 bytes
; (0xeaa2fa..0xeaa316); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaInst_OK:
	.incbin "includes/generated/naka_disk_warning.bin", 0x164E, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] Str_No
; Str_No  --  naka_disk_warning +0x166a..+0x24f4 (ROM 0xeaa316..0xeab1a0), 3722 bytes
; No RegObjTabl-registered table points at the start of these 3722 bytes
; (0xeaa316..0xeab1a0); purpose not established by that route.
; -----------------------------------------------------------------------------
Str_No:
	.incbin "includes/generated/naka_disk_warning.bin", 0x166A, 0xE8A
; -----------------------------------------------------------------------------
; [nakarest_retype] Data_CharMapFormatBlock
; Data_CharMapFormatBlock  --  naka_disk_warning +0x24f4..+0x2608 (ROM 0xeab1a0..0xeab2b4), 276 bytes
; No RegObjTabl-registered table points at the start of these 276 bytes
; (0xeab1a0..0xeab2b4); purpose not established by that route.
; -----------------------------------------------------------------------------
Data_CharMapFormatBlock:
	.incbin "includes/generated/naka_disk_warning.bin", 0x24F4, 0x114
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_warning+0x2608
; naka_disk_warning+0x2608  --  naka_disk_warning +0x2608..+0x263c (ROM 0xeab2b4..0xeab2e8), 52 bytes
; The table itself: ApFunction slot 0x120 (table 0xeab2b4, 12 entries,
; InitializeRoot) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_warning.bin", 0x2608, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_warning+0x263c
; naka_disk_warning+0x263c  --  naka_disk_warning +0x263c..+0x2672 (ROM 0xeab2e8..0xeab31e), 54 bytes
; The table itself: ApFunction slot 0x420 (table 0xeab2e8, 12 entries,
; InitializeRoot) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_warning.bin", 0x263C, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_warning+0x2672
; naka_disk_warning+0x2672  --  naka_disk_warning +0x2672..+0x31e8 (ROM 0xeab31e..0xeabe94), 2934 bytes
; Name strings of elements 0-11 of ApFunction slot 0x420 (table
; 0xeab2e8, 12 entries, InitializeRoot), names for ApFunction slot
; 0x120: "ApTaskControl", "CaptureLcdCheck", "UserBitmapCheck",
; "LanguageCheck", "GridCheck", "DefaultClassProc", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_warning.bin", 0x2672, 0xB76
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_warning+0x31e8
; naka_disk_warning+0x31e8  --  naka_disk_warning +0x31e8..+0x3d42 (ROM 0xeabe94..0xeac9ee), 2906 bytes
; propname blocks (the +20 of classes 0-108 of Class slot 0x160 (table
; 0xeac9ee, 109 entries, InitializeRoot)): len(propdata) + 1 pointers --
; one per own field, the last to an empty string -- then the field-name
; strings; e.g. Object {}; Function {func}; ApFunction {}; MainFunction
; {}; ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_warning.bin", 0x31E8, 0xB5A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_warning+0x3d42
; naka_disk_warning+0x3d42  --  naka_disk_warning +0x3d42..+0x402e (ROM 0xeac9ee..0xeaccda), 748 bytes
; The table itself: Class slot 0x160 (table 0xeac9ee, 109 entries,
; InitializeRoot) -- 109 class definitions of 24 bytes. Class
; definitions 0-31 of Class slot 0x160 (table 0xeac9ee, 109 entries,
; InitializeRoot): Object, Function, ApFunction, MainFunction, Class,
; SupportClass, Mode, Title, ResBitmap, ResFrame, .... 24 bytes each: +0
; proc, +4 parent (class id), +8 allsize, +10 selfsize, +12 name, +16
; propdata, +20 propname -- the firmware's own field names, from the
; propname table of the root class "Class".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_warning.bin", 0x3D42, 0x2EC
; External label offsets within the binary blob above.
