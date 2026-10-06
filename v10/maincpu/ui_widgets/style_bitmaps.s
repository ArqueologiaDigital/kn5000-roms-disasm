
; Style Bitmaps, Presentation Data & UI Dispatch (2 widgets, 101962 bytes)
; Source: maincpu/ui_widgets/naka_style_bitmaps.c (raw byte array)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_style_bitmaps
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
; the MstStyle browser tree (root 0xecfca4, 10 groups): not registered
; with RegObjTabl; found from its readers, named in each piece header
; below.
; -----------------------------------------------------------------------------

; [nakarest] NakaData_StyleBitmaps  +0x0..+0xa (0xeb71be, 10 B)
; [nakarest] Text (10 B at 0xeb71be), first string "iduToshi"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaProp_Frame_Chain (at 0xeb7108).
NakaData_StyleBitmaps:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x0, 0xA
; [nakarest] NakaInst_iduMurai  +0xa..+0x14 (0xeb71c8, 10 B)
; [nakarest] Text (10 B at 0xeb71c8), first string "iduMurai"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaProp_Frame_Chain (at 0xeb7100).
NakaInst_iduMurai:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xA, 0xA
; [nakarest] NakaInst_iduRoot  +0x14..+0x1c (0xeb71d2, 8 B)
; [nakarest] Text (8 B at 0xeb71d2), first string "iduRoot"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaProp_Frame_Chain (at 0xeb70f8).
NakaInst_iduRoot:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14, 0x8
; [nakarest] NakaInst_False_EB71DA  +0x1c..+0x4a (0xeb71da, 46 B)
; [nakarest] purpose not established: layout of 46 B at 0xeb71da not derived; readers below
; [nakarest] Readers: 2 data words in ExitWindow_OK_Data_2 (at 0xeb78a8, 0xeb78b4), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (ExitWindow_OK_Data_2:24)`).
NakaInst_False_EB71DA:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1C, 0x2E
; [nakarest] NakaInst_pSword_EmptyStr  +0x4a..+0x4c (0xeb7208, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeb7208 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_False_EB71DA (at 0xeb7200).
NakaInst_pSword_EmptyStr:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4A, 0x2
; [nakarest] NakaInst_pUword_FormatData  +0x4c..+0x60 (0xeb720a, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb720a not derived; readers below
; [nakarest] Readers: 2 data words in ExitWindow_OK_Data_2 (at 0xeb78c0, 0xeb78cc), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (ExitWindow_OK_Data_2:24)`).
NakaInst_pUword_FormatData:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4C, 0x14
; [nakarest] NakaInst_pUchar_FormatData  +0x60..+0x72 (0xeb721e, 18 B)
; [nakarest] purpose not established: layout of 18 B at 0xeb721e not derived; readers below
; [nakarest] Readers: 2 data words in ExitWindow_OK_Data_2 (at 0xeb78d8, 0xeb78e4), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (ExitWindow_OK_Data_2:24)`).
NakaInst_pUchar_FormatData:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x60, 0x12
; [nakarest] NakaInst_pSlong_EmptyStr  +0x72..+0x74 (0xeb7230, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeb7230 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_pUchar_FormatData (at 0xeb7228).
NakaInst_pSlong_EmptyStr:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x72, 0x2
; [nakarest] NakaInst_pUlong_FormatData  +0x74..+0x88 (0xeb7232, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb7232 not derived; readers below
; [nakarest] Readers: 2 data words in ExitWindow_OK_Data_2 (at 0xeb78f0, 0xeb78fc), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (ExitWindow_OK_Data_2:24)`).
NakaInst_pUlong_FormatData:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x74, 0x14
; [nakarest] NakaInst_PartID_EnumTable  +0x88..+0x33a (0xeb7246, 690 B)
; [nakarest] purpose not established: layout of 690 B at 0xeb7246 not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_WindowID_Cont (at 0xeb7908, 0xeb7914), which is
; [nakarest] read by FileIO_ByteBlock_DemoProc1_Skip16 (demo/file_demo_proc.s: `.long
; [nakarest] NakaInst_WindowID_Cont`).
NakaInst_PartID_EnumTable:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x88, 0x2B2
; [nakarest] NakaInst_TrackID_EmptyStr  +0x33a..+0x33c (0xeb74f8, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeb74f8 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_PartID_EnumTable (at 0xeb74f0).
NakaInst_TrackID_EmptyStr:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x33A, 0x2
; [nakarest] NakaInst_TR_All  +0x33c..+0x344 (0xeb74fa, 8 B)
; [nakarest] Text (8 B at 0xeb74fa), first string "TR_All"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74e8).
NakaInst_TR_All:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x33C, 0x8
; [nakarest] NakaInst_TR_Track16  +0x344..+0x350 (0xeb7502, 12 B)
; [nakarest] Text (12 B at 0xeb7502), first string "TR_Track16"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74e0).
NakaInst_TR_Track16:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x344, 0xC
; [nakarest] NakaInst_TR_Track15  +0x350..+0x35c (0xeb750e, 12 B)
; [nakarest] Text (12 B at 0xeb750e), first string "TR_Track15"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74d8).
NakaInst_TR_Track15:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x350, 0xC
; [nakarest] NakaInst_TR_Track14  +0x35c..+0x368 (0xeb751a, 12 B)
; [nakarest] Text (12 B at 0xeb751a), first string "TR_Track14"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74d0).
NakaInst_TR_Track14:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x35C, 0xC
; [nakarest] NakaInst_TR_Track13  +0x368..+0x374 (0xeb7526, 12 B)
; [nakarest] Text (12 B at 0xeb7526), first string "TR_Track13"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74c8).
NakaInst_TR_Track13:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x368, 0xC
; [nakarest] NakaInst_TR_Track12  +0x374..+0x380 (0xeb7532, 12 B)
; [nakarest] Text (12 B at 0xeb7532), first string "TR_Track12"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74c0).
NakaInst_TR_Track12:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x374, 0xC
; [nakarest] NakaInst_TR_Track11  +0x380..+0x38c (0xeb753e, 12 B)
; [nakarest] Text (12 B at 0xeb753e), first string "TR_Track11"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74b8).
NakaInst_TR_Track11:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x380, 0xC
; [nakarest] NakaInst_TR_Track10  +0x38c..+0x398 (0xeb754a, 12 B)
; [nakarest] Text (12 B at 0xeb754a), first string "TR_Track10"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74b0).
NakaInst_TR_Track10:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x38C, 0xC
; [nakarest] NakaInst_TR_Track9  +0x398..+0x3a2 (0xeb7556, 10 B)
; [nakarest] Text (10 B at 0xeb7556), first string "TR_Track9"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74a8).
NakaInst_TR_Track9:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x398, 0xA
; [nakarest] NakaInst_TR_Track8  +0x3a2..+0x3ac (0xeb7560, 10 B)
; [nakarest] Text (10 B at 0xeb7560), first string "TR_Track8"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74a0).
NakaInst_TR_Track8:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3A2, 0xA
; [nakarest] NakaInst_TR_Track7  +0x3ac..+0x3b6 (0xeb756a, 10 B)
; [nakarest] Text (10 B at 0xeb756a), first string "TR_Track7"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7498).
NakaInst_TR_Track7:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3AC, 0xA
; [nakarest] NakaInst_TR_Track6  +0x3b6..+0x3c0 (0xeb7574, 10 B)
; [nakarest] Text (10 B at 0xeb7574), first string "TR_Track6"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7490).
NakaInst_TR_Track6:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3B6, 0xA
; [nakarest] NakaInst_TR_Track5  +0x3c0..+0x3ca (0xeb757e, 10 B)
; [nakarest] Text (10 B at 0xeb757e), first string "TR_Track5"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7488).
NakaInst_TR_Track5:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3C0, 0xA
; [nakarest] NakaInst_TR_Track4  +0x3ca..+0x3d4 (0xeb7588, 10 B)
; [nakarest] Text (10 B at 0xeb7588), first string "TR_Track4"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7480).
NakaInst_TR_Track4:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3CA, 0xA
; [nakarest] NakaInst_TR_Track3  +0x3d4..+0x3de (0xeb7592, 10 B)
; [nakarest] Text (10 B at 0xeb7592), first string "TR_Track3"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7478).
NakaInst_TR_Track3:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3D4, 0xA
; [nakarest] NakaInst_TR_Track2  +0x3de..+0x3e8 (0xeb759c, 10 B)
; [nakarest] Text (10 B at 0xeb759c), first string "TR_Track2"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7470).
NakaInst_TR_Track2:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3DE, 0xA
; [nakarest] NakaInst_TR_Track1  +0x3e8..+0x3f2 (0xeb75a6, 10 B)
; [nakarest] Text (10 B at 0xeb75a6), first string "TR_Track1"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7468).
NakaInst_TR_Track1:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3E8, 0xA
; [nakarest] NakaInst_IntTimeID_EnumTable  +0x3f2..+0x462 (0xeb75b0, 112 B)
; [nakarest] purpose not established: layout of 112 B at 0xeb75b0 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_WindowID_Cont (at 0xeb7920), which is read by
; [nakarest] FileIO_ByteBlock_DemoProc1_Skip16 (demo/file_demo_proc.s: `.long
; [nakarest] NakaInst_WindowID_Cont`).
NakaInst_IntTimeID_EnumTable:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3F2, 0x70
; [nakarest] NakaInst_IntTimeID_EmptyStr  +0x462..+0x464 (0xeb7620, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeb7620 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb7618).
NakaInst_IntTimeID_EmptyStr:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x462, 0x2
; [nakarest] NakaInst_IT_10Sec  +0x464..+0x46e (0xeb7622, 10 B)
; [nakarest] Text (10 B at 0xeb7622), first string "IT_10Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb7610).
NakaInst_IT_10Sec:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x464, 0xA
; [nakarest] NakaInst_IT_9Sec  +0x46e..+0x476 (0xeb762c, 8 B)
; [nakarest] Text (8 B at 0xeb762c), first string "IT_9Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb7608).
NakaInst_IT_9Sec:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x46E, 0x8
; [nakarest] NakaInst_IT_8Sec  +0x476..+0x47e (0xeb7634, 8 B)
; [nakarest] Text (8 B at 0xeb7634), first string "IT_8Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb7600).
NakaInst_IT_8Sec:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x476, 0x8
; [nakarest] NakaInst_IT_7Sec  +0x47e..+0x486 (0xeb763c, 8 B)
; [nakarest] Text (8 B at 0xeb763c), first string "IT_7Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75f8).
NakaInst_IT_7Sec:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x47E, 0x8
; [nakarest] NakaInst_IT_6Sec  +0x486..+0x48e (0xeb7644, 8 B)
; [nakarest] Text (8 B at 0xeb7644), first string "IT_6Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75f0).
NakaInst_IT_6Sec:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x486, 0x8
; [nakarest] NakaInst_IT_5Sec  +0x48e..+0x496 (0xeb764c, 8 B)
; [nakarest] Text (8 B at 0xeb764c), first string "IT_5Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75e8).
NakaInst_IT_5Sec:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x48E, 0x8
; [nakarest] NakaInst_IT_4Sec  +0x496..+0x49e (0xeb7654, 8 B)
; [nakarest] Text (8 B at 0xeb7654), first string "IT_4Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75e0).
NakaInst_IT_4Sec:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x496, 0x8
; [nakarest] NakaInst_IT_3Sec  +0x49e..+0x4a6 (0xeb765c, 8 B)
; [nakarest] Text (8 B at 0xeb765c), first string "IT_3Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75d8).
NakaInst_IT_3Sec:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x49E, 0x8
; [nakarest] NakaInst_IT_2Sec  +0x4a6..+0x4ae (0xeb7664, 8 B)
; [nakarest] Text (8 B at 0xeb7664), first string "IT_2Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75d0).
NakaInst_IT_2Sec:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4A6, 0x8
; [nakarest] NakaInst_IT_1Sec  +0x4ae..+0x4b6 (0xeb766c, 8 B)
; [nakarest] Text (8 B at 0xeb766c), first string "IT_1Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75c8).
NakaInst_IT_1Sec:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4AE, 0x8
; [nakarest] NakaInst_IT_Hold  +0x4b6..+0x4be (0xeb7674, 8 B)
; [nakarest] Text (8 B at 0xeb7674), first string "IT_Hold"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75c0).
NakaInst_IT_Hold:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4B6, 0x8
; [nakarest] NakaInst_IT_Default  +0x4be..+0x4ca (0xeb767c, 12 B)
; [nakarest] Text (12 B at 0xeb767c), first string "IT_Default"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75b8).
NakaInst_IT_Default:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4BE, 0xC
; [nakarest] NakaInst_IT_Off  +0x4ca..+0x4d2 (0xeb7688, 8 B)
; [nakarest] Text (8 B at 0xeb7688), first string "IT_Off"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75b0).
NakaInst_IT_Off:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4CA, 0x8
; [nakarest] naka_style_bitmaps+0x4d2  +0x4d2..+0x741 (0xeb7690, 623 B)
; [nakarest] purpose not established: layout of 623 B at 0xeb7690 not derived; readers below
; [nakarest] Readers: source references ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (ExitWindow_OK_Data_2:24)`).
ExitWindow_OK_Data_2:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4D2, 0x26F
; [nakarest] NakaInst_WindowID_Cont  +0x741..+0x774 (0xeb78ff, 51 B)
; [nakarest] purpose not established: layout of 51 B at 0xeb78ff not derived; readers below
; [nakarest] Readers: source references FileIO_ByteBlock_DemoProc1_Skip16
; [nakarest] (demo/file_demo_proc.s: `.long NakaInst_WindowID_Cont`).
NakaInst_WindowID_Cont:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x741, 0x33
; [nakarest] WidgetStyleDataTable  +0x774..+0x784 (0xeb7932, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xeb7932 not derived; readers below
; [nakarest] Readers: source references SystemConfig_PointerTable (ui_widgets/widget_dispatch.s:
; [nakarest] `.long WidgetStyleDataTable`), Test_Video_RAM_IC207 (ui/ui_mode_handlers.s: `ld
; [nakarest] xhl, (WidgetStyleDataTable:24)`); 1 data word in SystemConfig_PointerTable (at
; [nakarest] 0xee8c9e), which is read by ScreenGroup_WidgetLoop (boot/screen_group_dispatch.s:
; [nakarest] `ld xbc, SystemConfig_PointerTable`), VoiceInit_Dispatch
; [nakarest] (boot/screen_group_dispatch.s: `ld xbc, SystemConfig_PointerTable`).
WidgetStyleDataTable:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x774, 0x10
; PanelMemory_SlotAddresses -- 81 u32 RAM addresses, one per panel-memory slot: 0..79 = the 80 panel
; memories at 0x1ED400 + 960*n, 80 = RAM 0x3C2C4, the Music Stylist record's mirror of the panel stream (slot
; code 0x80 is read as 80).  Indexed by slot by PanelMemory_Recall_Slot, PanelMemory_CopySlotToLivePanel,
; PanelMemory_RecallRecords and the other panel-memory readers in ui/bitmap_out_routines.s; typed in
; ui_widgets/naka_style_bitmaps.c (scripts/converters/panel_memory_slot_table_retype.py).
PanelMemory_SlotAddresses:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x784, 0x144
; [nakarest] naka_style_bitmaps+0x8c8  +0x8c8..+0x8d2 (0xeb7a86, 10 B)
; [nakarest] purpose not established: layout of 10 B at 0xeb7a86 not derived; readers below
; [nakarest] Readers: source references BitMapOut_DeltaEncode_Type90Final
; [nakarest] (ui/bitmap_out_routines.s: `ld xde, BitMapOut_DeltaEncode_Type90Final_Data`).
BitMapOut_DeltaEncode_Type90Final_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x8C8, 0xA
; [nakarest] naka_style_bitmaps+0x8d2  +0x8d2..+0xa1c (0xeb7a90, 330 B)
; [nakarest] purpose not established: layout of 330 B at 0xeb7a90 not derived; readers below
; [nakarest] Readers: source references BitMapOut_DeltaEncode_Type90Final
; [nakarest] (ui/bitmap_out_routines.s: `lda xhl, (BitMapOut_DeltaEncode_Type90Final_Data_2:24)`).
BitMapOut_DeltaEncode_Type90Final_Data_2:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x8D2, 0x138
BitMapOut_UpdateDisplayWidget_Str_Non_Panel_Memory:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xA0A, 0x12	; "Non Panel Memory"
; [nakarest] naka_style_bitmaps+0xa1c  +0xa1c..+0xad6 (0xeb7bda, 186 B)
; [nakarest] purpose not established: layout of 186 B at 0xeb7bda not derived; readers below
; [nakarest] Readers: source references EffectMode_UpdateBitFlags_Loop (ui/ui_mode_handlers.s:
; [nakarest] `ld xix, EffectMode_UpdateBitFlags_CheckCount_Data`).
EffectMode_UpdateBitFlags_CheckCount_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xA1C, 0xBA
; [nakarest] naka_style_bitmaps+0xad6  +0xad6..+0xae2 (0xeb7c94, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xeb7c94 not derived; readers below
; [nakarest] Readers: source references OneTchFUNC (ui/bitmap_out_routines.s: `add xde,
; [nakarest] OneTchFUNC_CaseTable`).
OneTchFUNC_CaseTable:
	.short	BitMapOut_ByteData_WidgetTable - BitMapOut_ByteData_WidgetTable
	.short	BitMapOut_ApplyWidgetPatch - BitMapOut_ByteData_WidgetTable
	.short	BitMapOut_ApplyWidgetPatch - BitMapOut_ByteData_WidgetTable
	.short	BitMapOut_ApplyWidgetPatch - BitMapOut_ByteData_WidgetTable
	.short	BitMapOut_ApplyWidgetPatch - BitMapOut_ByteData_WidgetTable
	.short	BitMapOut_ApplyWidgetPatch - BitMapOut_ByteData_WidgetTable
; [nakarest] naka_style_bitmaps+0xae2  +0xae2..+0xc6e (0xeb7ca0, 396 B)
; [nakarest] Text (396 B at 0xeb7ca0), first string "IModern Vibes Moscow Mandolins\xD5Sing
; [nakarest] It, P"; no registered NAKA table points into it; reached through source references
; [nakarest] EffectMode_SearchPresetTableC2C5 (ui/ui_mode_handlers.s: `lda xhl,
; [nakarest] (EffectMode_SearchPresetTableC2C5_Data:24)`).
EffectMode_SearchPresetTableC2C5_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xAE2, 0x18C
; [nakarest] naka_style_bitmaps+0xc6e  +0xc6e..+0xcc8 (0xeb7e2c, 90 B)
; [nakarest] purpose not established: layout of 90 B at 0xeb7e2c not derived; readers below
; [nakarest] Readers: source references EffectMode_SearchPresetTableC0 (ui/ui_mode_handlers.s:
; [nakarest] `lda xhl, (EffectMode_SearchPresetTableC0_Data:24)`).
EffectMode_SearchPresetTableC0_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xC6E, 0x5A
; [nakarest] naka_style_bitmaps+0xcc8  +0xcc8..+0xcce (0xeb7e86, 6 B)
; [nakarest] purpose not established: layout of 6 B at 0xeb7e86 not derived; readers below
; [nakarest] Readers: source references EffectMode_DiagSeq_AnimFrame (ui/ui_mode_handlers.s:
; [nakarest] `lda xbc, (EffectMode_DiagSeq_AnimFrame_Data:24)`).
EffectMode_DiagSeq_AnimFrame_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xCC8, 0x6
; PanelButton_LedMap -- [22 panel segments][8 button bits] x {LED row, LED pattern}.  EffectMode_MidiSetLEDs
; reads entry [segment][lowest set bit of the change mask] and calls Set_LEDs(row, pattern or 0); the row
; indexes Protocol_values_for_LED_rows.  {0x0E, 0x0F} (row 14, the four START/STOP beat LEDs) fills the
; buttons that have no LED of their own.  Typed in ui_widgets/naka_style_bitmaps.c
; (scripts/converters/panel_led_map_retype.py).
PanelButton_LedMap:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xCCE, 0x160
; [nakarest] naka_style_bitmaps+0xe2e  +0xe2e..+0xe4e (0xeb7fec, 32 B)
; [nakarest] purpose not established: layout of 32 B at 0xeb7fec not derived; readers below
; [nakarest] Readers: source references EffectMode_SetAllLEDs_Loop (ui/ui_mode_handlers.s: `lda
; [nakarest] xbc, (EffectMode_SetAllLEDs_SetOne_Data:24)`), LED_SetAll_BlankLoop
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (EffectMode_SetAllLEDs_SetOne_Data:24)`).
EffectMode_SetAllLEDs_SetOne_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE2E, 0x20
; [nakarest] naka_style_bitmaps+0xe4e  +0xe4e..+0xe70 (0xeb800c, 34 B)
; [nakarest] purpose not established: layout of 34 B at 0xeb800c not derived; readers below
; [nakarest] Readers: source references RhythmRomTest_Compare (ui/ui_mode_handlers.s: `lda xix,
; [nakarest] (RhythmRomTest_Compare_Data:24)`).
RhythmRomTest_Compare_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE4E, 0x22
; [nakarest] naka_style_bitmaps+0xe70  +0xe70..+0xe7a (0xeb802e, 10 B)
; [nakarest] purpose not established: layout of 10 B at 0xeb802e not derived; readers below
; [nakarest] Readers: source references DramTest_IC10IC9_NextChip (ui/ui_mode_handlers.s: `lda
; [nakarest] xbc, (DramTest_IC10IC9_NextChip_Data:24)`).
DramTest_IC10IC9_NextChip_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE70, 0xA
; [nakarest] naka_style_bitmaps+0xe7a  +0xe7a..+0xe84 (0xeb8038, 10 B)
; [nakarest] purpose not established: layout of 10 B at 0xeb8038 not derived; readers below
; [nakarest] Readers: source references SramTest_IC21_Loop (ui/ui_mode_handlers.s: `lda xde,
; [nakarest] (Test_SRAM_IC21_Data:24)`).
Test_SRAM_IC21_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE7A, 0xA
; [nakarest] naka_style_bitmaps+0xe84  +0xe84..+0xe90 (0xeb8042, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xeb8042 not derived; readers below
; [nakarest] Readers: source references TEST2FUNC (ui/ui_mode_handlers.s: `add xde,
; [nakarest] TEST2FUNC_CaseTable`).
TEST2FUNC_CaseTable:
	.short	TEST2FUNC_DispatchReturn - TEST2FUNC_DispatchReturn
	.short	TableDispatch_Return3 - TEST2FUNC_DispatchReturn
	.short	TableDispatch_Return3 - TEST2FUNC_DispatchReturn
	.short	TableDispatch_Return3 - TEST2FUNC_DispatchReturn
	.short	TableDispatch_Return3 - TEST2FUNC_DispatchReturn
	.short	TableDispatch_Return3 - TEST2FUNC_DispatchReturn
; [nakarest] naka_style_bitmaps+0xe90  +0xe90..+0xe9c (0xeb804e, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xeb804e not derived; readers below
; [nakarest] Readers: source references TEST3FUNC (ui/ui_mode_handlers.s: `add xde,
; [nakarest] TEST3FUNC_CaseTable`).
TEST3FUNC_CaseTable:
	.short	TEST3FUNC_DispatchReturn - TEST3FUNC_DispatchReturn
	.short	TableDispatch_Return4 - TEST3FUNC_DispatchReturn
	.short	TableDispatch_Return4 - TEST3FUNC_DispatchReturn
	.short	TableDispatch_Return4 - TEST3FUNC_DispatchReturn
	.short	TableDispatch_Return4 - TEST3FUNC_DispatchReturn
	.short	TableDispatch_Return4 - TEST3FUNC_DispatchReturn
; [nakarest] naka_style_bitmaps+0xe9c  +0xe9c..+0xea8 (0xeb805a, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xeb805a not derived; readers below
; [nakarest] Readers: source references TEST4FUNC (ui/ui_mode_handlers.s: `add xde,
; [nakarest] TEST4FUNC_CaseTable`).
TEST4FUNC_CaseTable:
	.short	TEST4FUNC_DispatchReturn - TEST4FUNC_DispatchReturn
	.short	TableDispatch_Return5 - TEST4FUNC_DispatchReturn
	.short	TableDispatch_Return5 - TEST4FUNC_DispatchReturn
	.short	TableDispatch_Return5 - TEST4FUNC_DispatchReturn
	.short	TableDispatch_Return5 - TEST4FUNC_DispatchReturn
	.short	TableDispatch_Return5 - TEST4FUNC_DispatchReturn
; [nakarest] naka_style_bitmaps+0xea8  +0xea8..+0xeb4 (0xeb8066, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xeb8066 not derived; readers below
; [nakarest] Readers: source references TEST6FUNC (ui/ui_mode_handlers.s: `add xde,
; [nakarest] TEST6FUNC_CaseTable`).
TEST6FUNC_CaseTable:
	.short	TEST6FUNC_DispatchReturn - TEST6FUNC_DispatchReturn
	.short	TableDispatch_Return - TEST6FUNC_DispatchReturn
	.short	TableDispatch_Return - TEST6FUNC_DispatchReturn
	.short	TableDispatch_Return - TEST6FUNC_DispatchReturn
	.short	TableDispatch_Return - TEST6FUNC_DispatchReturn
	.short	TableDispatch_Return - TEST6FUNC_DispatchReturn
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_FadeInPicture
; Bitmap_FadeInPicture  --  112 x 25 bitmap, 8 bpp, row stride 112, 2800 bytes
;
; What it shows (render): A horizontal wedge that widens from a point at
; the left to full height at the right (a crescendo shape), dark grey
; with a black outline on the mid-grey background.
;
; Reader: BitmapFinpic (v10/v9 0xfb7e4a, v7 0xfb7689) answers 0x1e000a1
; with this address, 0x1e000a2 with 0x70 (width 112) and 0x1e000a3 with
; 0x19 (height 25). The routine is entry 22 of the 42-entry ApFunction
; table that InitializeToshi (v10/v9 0xfc311a, v7 0xfc294f) registers
; with RegObjTabl 0x1600002, ApFunctionProc, 0x2a, 0xed1c9e, slot 0x122
; (extensions/extension_data.s, still raw bytes there); its name string
; "BitmapFinpic" is entry 22 of the parallel name table
; NoteNameStr_Table_5, slot 0x422. Drawn by the UserBitmap view class:
; VwUserBitmapProc (v10/v9 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d),
; calls the instance's function (+22 of the instance) with 0x1e000a1
; (address), 0x1e000a2 (width) and 0x1e000a3 (height) through ApFuncCall
; and hands the three to DrawBitmapSPFast (v10/v9 0xfac3db, v7
; 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/nakarest_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_style_bitmaps.c as uint8_t Bitmap_FadeInPicture[25][112]
; (rows of 112 bytes).
; -----------------------------------------------------------------------------
Bitmap_FadeInPicture:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEB4, 0xAF0
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_FadeInText
; Bitmap_FadeInText  --  80 x 18 bitmap, 8 bpp, row stride 80, 1440 bytes
;
; What it shows (render): 'FADE IN' in dark red italic capitals on grey.
;
; Reader: BitmapFinst (v10/v9 0xfb7e77, v7 0xfb76b6) answers 0x1e000a1
; with this address, 0x1e000a2 with 0x50 (width 80) and 0x1e000a3 with
; 0x12 (height 18). The routine is entry 23 of the 42-entry ApFunction
; table that InitializeToshi (v10/v9 0xfc311a, v7 0xfc294f) registers
; with RegObjTabl 0x1600002, ApFunctionProc, 0x2a, 0xed1c9e, slot 0x122
; (extensions/extension_data.s, still raw bytes there); its name string
; "BitmapFinst" is entry 23 of the parallel name table
; NoteNameStr_Table_5, slot 0x422. Drawn by the UserBitmap view class:
; VwUserBitmapProc (v10/v9 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d),
; calls the instance's function (+22 of the instance) with 0x1e000a1
; (address), 0x1e000a2 (width) and 0x1e000a3 (height) through ApFuncCall
; and hands the three to DrawBitmapSPFast (v10/v9 0xfac3db, v7
; 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/nakarest_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_style_bitmaps.c as uint8_t Bitmap_FadeInText[18][80]
; (rows of 80 bytes).
; -----------------------------------------------------------------------------
Bitmap_FadeInText:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x19A4, 0x5A0
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_FadeOutPicture
; Bitmap_FadeOutPicture  --  113 x 25 bitmap, 8 bpp, row stride 114, 2850 bytes
;
; What it shows (render): The mirror image of Bitmap_FadeInPicture: the
; wedge is full height at the left and narrows to a point at the right.
;
; Reader: BitmapFoutpic (v10/v9 0xfb7ea4, v7 0xfb76e3) answers 0x1e000a1
; with this address, 0x1e000a2 with 0x71 (width 113) and 0x1e000a3 with
; 0x19 (height 25). The routine is entry 24 of the 42-entry ApFunction
; table that InitializeToshi (v10/v9 0xfc311a, v7 0xfc294f) registers
; with RegObjTabl 0x1600002, ApFunctionProc, 0x2a, 0xed1c9e, slot 0x122
; (extensions/extension_data.s, still raw bytes there); its name string
; "BitmapFoutpic" is entry 24 of the parallel name table
; NoteNameStr_Table_5, slot 0x422. Drawn by the UserBitmap view class:
; VwUserBitmapProc (v10/v9 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d),
; calls the instance's function (+22 of the instance) with 0x1e000a1
; (address), 0x1e000a2 (width) and 0x1e000a3 (height) through ApFuncCall
; and hands the three to DrawBitmapSPFast (v10/v9 0xfac3db, v7
; 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/nakarest_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_style_bitmaps.c as uint8_t
; Bitmap_FadeOutPicture[25][114] (rows of 114 bytes).
; -----------------------------------------------------------------------------
Bitmap_FadeOutPicture:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1F44, 0xB22
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_FadeOutText
; Bitmap_FadeOutText  --  108 x 20 bitmap, 8 bpp, row stride 108, 2160 bytes
;
; What it shows (render): 'FADE OUT' in teal italic capitals on grey.
;
; Reader: BitmapFoutst (v10/v9 0xfb7ed1, v7 0xfb7710) answers 0x1e000a1
; with this address, 0x1e000a2 with 0x6c (width 108) and 0x1e000a3 with
; 0x14 (height 20). The routine is entry 25 of the 42-entry ApFunction
; table that InitializeToshi (v10/v9 0xfc311a, v7 0xfc294f) registers
; with RegObjTabl 0x1600002, ApFunctionProc, 0x2a, 0xed1c9e, slot 0x122
; (extensions/extension_data.s, still raw bytes there); its name string
; "BitmapFoutst" is entry 25 of the parallel name table
; NoteNameStr_Table_5, slot 0x422. Drawn by the UserBitmap view class:
; VwUserBitmapProc (v10/v9 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d),
; calls the instance's function (+22 of the instance) with 0x1e000a1
; (address), 0x1e000a2 (width) and 0x1e000a3 (height) through ApFuncCall
; and hands the three to DrawBitmapSPFast (v10/v9 0xfac3db, v7
; 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/nakarest_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_style_bitmaps.c as uint8_t Bitmap_FadeOutText[20][108]
; (rows of 108 bytes).
; -----------------------------------------------------------------------------
Bitmap_FadeOutText:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x2A66, 0x870
; -----------------------------------------------------------------------------
; [nakarest_retype] StyleSong_MasterTable
; StyleSong_MasterTable  --  1000 mst_title_ref_t records x 6 bytes = 6000 bytes
;
; An alphabetical list of 1000 titles, each with an id. Readers
; (ui/ui_mode_handlers.s): the MasterSetup dial handlers
; (MasterSetup_HandleDialTurn, MasterSetup_DialTurn_ScrollUp,
; MasterSetup_DialDown_*) index it with 6*k (`muls wa, 0x6`), load +0
; and Strcpy the title into the view, and search it with String_Compare;
; their bounds are 0x3e8 (1000) -- an index of 1000 wraps to 0 and an
; underflow reads entry 999 through MasterSetup_DialTurn_Underflow_Data (=
; +999*6, .set in shared/positional_labels.s), which is how the count is
; pinned. The cell-select paths of MasterSetup and
; MstStyleAlp_EventDispatch load the u16 at +4 of entry 9*(page-1) +
; scroll + row (MasterSetup_EventDispatch_Data, 9 rows per page) and hand it
; to MainFuncCall with 0x142000d / 0x1e20018. Checked here: the 1000
; title pointers are exactly the 1000 entries of StyleSong_Titles (entry
; k of this table -> title 999-k), and the ids are 0..999, each once.
; What the id selects on the 0x142000d side was not traced.
;
; Typed in naka_style_bitmaps.c as mst_title_ref_t
; StyleSong_MasterTable[1000] (a local typedef).
; -----------------------------------------------------------------------------
StyleSong_MasterTable:			.incbin "includes/generated/naka_style_bitmaps.bin", 0x32D6, 0x4
MasterSetup_EventDispatch_Data:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x32DA, 0x1766
MasterSetup_DialTurn_Underflow_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4A40, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] StyleSong_Titles
; StyleSong_Titles  --  1000 title strings x 34 bytes = 34000 bytes
;
; Each entry is 32 characters -- a 29-column name, then a right-aligned
; 3-digit number (e.g. "Zorba's Band ... 120"; no code that reads the
; number separately was traced; it reads like a tempo) -- then NUL and a
; 0xff pad byte, the ALIGNED_STRING layout. Only reached through
; StyleSong_MasterTable's +0 pointers (above); stored in REVERSE
; alphabetical order, so the table's entry k points at title 999-k. The
; old .s sliced this run into 130 NakaInst_<title> labels that cut
; across the 34-byte entries; none of them was referenced except three
; that naka_direct_play.c, naka_perf_style.c and naka_effects_seq.c used
; as false pointers (16-bit value pairs that happened to fall inside a
; title), which are numbers again in those files.
;
; Typed as char StyleSong_Titles[1000][34], one ALIGNED_STRING per
; entry.
; -----------------------------------------------------------------------------
StyleSong_Titles:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4A46, 0x84D0
; [nakarest] StyleVar_GermanSchlager  +0xcf16..+0xcf56 (0xec40d4, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "New Unison Eight 108".
StyleVar_GermanSchlager:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xCF16, 0x40
; [nakarest] NakaInst_Orchestral_Eight_108  +0xcf56..+0xcfbc (0xec4114, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Orchestral Eight 108"; "Flugel Pop 108"; "Acoustic Beat 108".
NakaInst_Orchestral_Eight_108:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xCF56, 0x66
; [nakarest] StyleVar_EasyPlay8Beat  +0xcfbc..+0xd01e (0xec417a, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Gentle Sax Eight 90"; "Reson-Eight 90".
StyleVar_EasyPlay8Beat:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xCFBC, 0x62
; [nakarest] NakaInst_Easy_EP_90  +0xd01e..+0xd062 (0xec41dc, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Easy
; [nakarest] EP! 90"; "88 Note 8 Beat 90".
NakaInst_Easy_EP_90:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD01E, 0x44
; [nakarest] StyleVar_RockAfterEight  +0xd062..+0xd0e6 (0xec4220, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Symphonic Rock 108"; "Soft Rock 108"; "Upright Rock
; [nakarest] 108".
StyleVar_RockAfterEight:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD062, 0x84
; [nakarest] NakaInst_Vocal_Beats_108  +0xd0e6..+0xd108 (0xec42a4, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Vocal
; [nakarest] Beats 108".
NakaInst_Vocal_Beats_108:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD0E6, 0x22
; [nakarest] StyleVar_OrchestralBeat  +0xd108..+0xd126 (0xec42c6, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_OrchestralBeat:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD108, 0x1E
; [nakarest] NakaInst_Cool_Rock_106  +0xd126..+0xd1ae (0xec42e4, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Cool
; [nakarest] Rock 106"; "Rock Symphony 106"; "Society Rock 106"; "Romantic Rock 106".
NakaInst_Cool_Rock_106:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD126, 0x88
; [nakarest] StyleVar_SmoothRock  +0xd1ae..+0xd1ee (0xec436c, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Tender Rock Sax 114".
StyleVar_SmoothRock:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD1AE, 0x40
; [nakarest] NakaInst_Dream_Beat_114  +0xd1ee..+0xd254 (0xec43ac, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Dream
; [nakarest] Beat 114"; "Warm Guitars 114"; "Gentle 8 Piano 114".
NakaInst_Dream_Beat_114:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD1EE, 0x66
; [nakarest] StyleVar_GreatestHits  +0xd254..+0xd2b6 (0xec4412, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Sweet Distortion 90"; "Fantasia Eight 90".
StyleVar_GreatestHits:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD254, 0x62
; [nakarest] NakaInst_Paradise_Keys_90  +0xd2b6..+0xd2fa (0xec4474, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Paradise Keys 90"; "Wonder Harmonica 90".
NakaInst_Paradise_Keys_90:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD2B6, 0x44
; [nakarest] StyleVar_Studio8Beat  +0xd2fa..+0xd37e (0xec44b8, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Stevie's Solo 86"; "Atmospheric 8 86"; "Breathless Sax
; [nakarest] 86".
StyleVar_Studio8Beat:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD2FA, 0x84
; [nakarest] NakaInst_Acoustic_Effects_86  +0xd37e..+0xd3a0 (0xec453c, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Acoustic Effects 86".
NakaInst_Acoustic_Effects_86:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD37E, 0x22
; [nakarest] StyleVar_BalladProducer  +0xd3a0..+0xd3be (0xec455e, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_BalladProducer:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD3A0, 0x1E
; [nakarest] NakaInst_Sax_For_Whitney_84  +0xd3be..+0xd446 (0xec457c, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Sax
; [nakarest] For Whitney 84"; "Movie Ballad 84"; "Southern Nights 84"; "Cosmic Ballad 84".
NakaInst_Sax_For_Whitney_84:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD3BE, 0x88
; [nakarest] StyleVar_LoveSongs  +0xd446..+0xd486 (0xec4604, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Romantic Voices 72".
StyleVar_LoveSongs:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD446, 0x40
; [nakarest] NakaInst_Warm_Horn_Duet_72  +0xd486..+0xd4ec (0xec4644, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Warm
; [nakarest] Horn Duet 72"; "Orchestral Keys 72"; "Oboe Ballad 72".
NakaInst_Warm_Horn_Duet_72:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD486, 0x66
; [nakarest] StyleVar_16BeatGroove  +0xd4ec..+0xd54e (0xec46aa, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Fantasy Beat 82"; "Digital Sixteen 82".
StyleVar_16BeatGroove:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD4EC, 0x62
; [nakarest] NakaInst_New_Muzak_82  +0xd54e..+0xd592 (0xec470c, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "New
; [nakarest] Muzak 82"; "16 Wheels 82".
NakaInst_New_Muzak_82:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD54E, 0x44
; [nakarest] StyleVar_EasyPlay16Beat  +0xd592..+0xd616 (0xec4750, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Easy Reeding 74"; "Benson Frets 74"; "Bright Keys 16
; [nakarest] 74".
StyleVar_EasyPlay16Beat:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD592, 0x84
; [nakarest] NakaInst_Solid_Sixteen_74  +0xd616..+0xd638 (0xec47d4, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Solid
; [nakarest] Sixteen 74".
NakaInst_Solid_Sixteen_74:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD616, 0x22
; [nakarest] StyleVar_EPMoments  +0xd638..+0xd656 (0xec47f6, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_EPMoments:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD638, 0x1E
; [nakarest] NakaInst_The_Way_It_Is_70  +0xd656..+0xd6de (0xec4814, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "The
; [nakarest] Way It Is 70"; "Symphony Ballad 70"; "E.P. Romance 70"; "Just The Flute 70".
NakaInst_The_Way_It_Is_70:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD656, 0x88
; [nakarest] StyleVar_Gentle16Beat  +0xd6de..+0xd71e (0xec489c, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "16 On Stage 82".
StyleVar_Gentle16Beat:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD6DE, 0x40
; [nakarest] NakaInst_Orchestral_16_82  +0xd71e..+0xd784 (0xec48dc, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Orchestral 16 82"; "Mangione Mood 82"; "E.P. Does It! 82".
NakaInst_Orchestral_16_82:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD71E, 0x66
; [nakarest] StyleVar_Atmospheric16  +0xd784..+0xd7e6 (0xec4942, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Dreamy Orchestra 67"; "Slow Ballad B3 67".
StyleVar_Atmospheric16:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD784, 0x62
; [nakarest] NakaInst_Ballad_Romance_67_EC49A4  +0xd7e6..+0xd82a (0xec49a4, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Ballad
; [nakarest] Romance 67"; "Ballad Frets 67".
NakaInst_Ballad_Romance_67_EC49A4:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD7E6, 0x44
; [nakarest] StyleVar_SynthBallad  +0xd82a..+0xd8ae (0xec49e8, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Ballad Bridge 75"; "80's Production 75"; "Sounds Of
; [nakarest] Quincy 75".
StyleVar_SynthBallad:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD82A, 0x84
; [nakarest] NakaInst_Gentle_Ballad_75_EC4A6C  +0xd8ae..+0xd8d0 (0xec4a6c, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Gentle
; [nakarest] Ballad 75".
NakaInst_Gentle_Ballad_75_EC4A6C:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD8AE, 0x22
; [nakarest] StyleVar_GrandsOnStage  +0xd8d0..+0xd8ee (0xec4a8e, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_GrandsOnStage:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD8D0, 0x1E
; [nakarest] NakaInst_Clavier_Francais_80  +0xd8ee..+0xd976 (0xec4aac, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Clavier Francais 80"; "Symphonic Pop 80"; "Pop Concerto 80"; "Clayder Piano 80".
NakaInst_Clavier_Francais_80:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD8EE, 0x88
; [nakarest] StyleVar_ModernBallads  +0xd976..+0xd9b6 (0xec4b34, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Ballad Orchestra 84".
StyleVar_ModernBallads:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD976, 0x40
; [nakarest] NakaInst_Synth_Love_Song_84  +0xd9b6..+0xda1c (0xec4b74, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Synth
; [nakarest] Love Song 84"; "Smooth & Saxy 84"; "Ballad Acoustics 84".
NakaInst_Synth_Love_Song_84:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD9B6, 0x66
; [nakarest] StyleVar_NightClubDance  +0xda1c..+0xda7e (0xec4bda, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Bows & Brass 72"; "Breathtaking 72".
StyleVar_NightClubDance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDA1C, 0x62
; [nakarest] NakaInst_String_Romance_72  +0xda7e..+0xdac2 (0xec4c3c, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "String
; [nakarest] Romance 72"; "Twilight Piano 72".
NakaInst_String_Romance_72:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDA7E, 0x44
; [nakarest] StyleVar_50sLoveSongs  +0xdac2..+0xdb46 (0xec4c80, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Old & New Ballad 100"; "Ensemble Ballad 100"; "Mellow
; [nakarest] Shuffle 100".
StyleVar_50sLoveSongs:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDAC2, 0x84
; [nakarest] NakaInst_Shuffle_Chanson_100  +0xdb46..+0xdb68 (0xec4d04, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Shuffle
; [nakarest] Chanson 100".
NakaInst_Shuffle_Chanson_100:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDB46, 0x22
; [nakarest] StyleVar_OldieBallads  +0xdb68..+0xdb86 (0xec4d26, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_OldieBallads:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDB68, 0x1E
; [nakarest] NakaInst_Flute_Nocturne_63  +0xdb86..+0xdc0e (0xec4d44, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Flute
; [nakarest] Nocturne 63"; "Like A Dream 63"; "Ballad Piano 63"; "Flugel Ballad 63".
NakaInst_Flute_Nocturne_63:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDB86, 0x88
; [nakarest] StyleVar_SoftSchlager  +0xdc0e..+0xdc4e (0xec4dcc, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Accordion Dream 64".
StyleVar_SoftSchlager:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDC0E, 0x40
; [nakarest] NakaInst_Spacy_Ballad_64  +0xdc4e..+0xdcb4 (0xec4e0c, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Spacy
; [nakarest] Ballad 64"; "Guitar Ballad 64"; "Pan Muzak 64".
NakaInst_Spacy_Ballad_64:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDC4E, 0x66
; [nakarest] StyleVar_OldieDrawbars  +0xdcb4..+0xdd16 (0xec4e72, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "German Oldies 125"; "Oldie's Jazz 125".
StyleVar_OldieDrawbars:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDCB4, 0x62
; [nakarest] NakaInst_Oldie_s_Parade_125  +0xdd16..+0xdd5a (0xec4ed4, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Oldie's Parade 125"; "Echoing Organ 125".
NakaInst_Oldie_s_Parade_125:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDD16, 0x44
; [nakarest] StyleVar_EuroBallads  +0xdd5a..+0xddde (0xec4f18, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Starlight Ballad 68"; "Ballad Glitter 68"; "Ricky's
; [nakarest] Ballad 68".
StyleVar_EuroBallads:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDD5A, 0x84
; [nakarest] NakaInst_Dreamy_Harmonica_68  +0xddde..+0xde00 (0xec4f9c, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Dreamy
; [nakarest] Harmonica 68".
NakaInst_Dreamy_Harmonica_68:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDDDE, 0x22
; [nakarest] StyleVar_RomanticBand  +0xde00..+0xde1e (0xec4fbe, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_RomanticBand:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDE00, 0x1E
; [nakarest] NakaInst_Late_Night_Tenor_117  +0xde1e..+0xdea6 (0xec4fdc, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Late
; [nakarest] Night Tenor 117"; "Swing Serenade 117"; "Romantic Duet 117"; "Swing Flautist 117".
NakaInst_Late_Night_Tenor_117:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDE1E, 0x88
; [nakarest] StyleVar_JazzSerenade  +0xdea6..+0xdee6 (0xec5064, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Smooth Lips 83".
StyleVar_JazzSerenade:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDEA6, 0x40
; [nakarest] NakaInst_Mellow_Mood_83  +0xdee6..+0xdf4c (0xec50a4, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Mellow
; [nakarest] Mood 83"; "Breathy Moments 83"; "Soprano Soloist 83".
NakaInst_Mellow_Mood_83:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDEE6, 0x66
; [nakarest] StyleVar_NatsBallads  +0xdf4c..+0xdfae (0xec510a, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Simply Romantic 90"; "Riddle Me This! 90".
StyleVar_NatsBallads:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDF4C, 0x62
; [nakarest] NakaInst_Sweet_Swing_90  +0xdfae..+0xdff2 (0xec516c, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Sweet
; [nakarest] Swing 90"; "Midnight Tunes 90".
NakaInst_Sweet_Swing_90:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDFAE, 0x44
; [nakarest] StyleVar_DrawbarCombo  +0xdff2..+0xe076 (0xec51b0, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "All Out Combo 180"; "Sine Of The Time 180"; "Relax With
; [nakarest] Klaus 180".
StyleVar_DrawbarCombo:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDFF2, 0x84
; [nakarest] NakaInst_Wunderlich_Combo_180  +0xe076..+0xe098 (0xec5234, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Wunderlich Combo 180".
NakaInst_Wunderlich_Combo_180:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE076, 0x22
; [nakarest] StyleVar_ParisRomance  +0xe098..+0xe0b6 (0xec5256, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_ParisRomance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE098, 0x1E
; [nakarest] NakaInst_French_Clavier_92  +0xe0b6..+0xe13e (0xec5274, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "French
; [nakarest] Clavier 92"; "Paris Singers 92"; "Musette Ballad 92"; "Cafe Serenade 92".
NakaInst_French_Clavier_92:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE0B6, 0x88
; [nakarest] StyleVar_EasyPlayWaltz  +0xe13e..+0xe17e (0xec52fc, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Waltzing Wheels 110".
StyleVar_EasyPlayWaltz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE13E, 0x40
; [nakarest] NakaInst_Three_Four_Vibes_110  +0xe17e..+0xe1e4 (0xec533c, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Three
; [nakarest] Four Vibes 110"; "One,Two,Three 110"; "Easy Threesy 110".
NakaInst_Three_Four_Vibes_110:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE17E, 0x66
; [nakarest] StyleVar_ParisianNights  +0xe1e4..+0xe246 (0xec53a2, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Musette Symphony 175"; "Vive La France! 175".
StyleVar_ParisianNights:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE1E4, 0x62
; [nakarest] NakaInst_Cafe_Atmosphere_175  +0xe246..+0xe28a (0xec5404, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Cafe
; [nakarest] Atmosphere 175"; "Simple Band 175".
NakaInst_Cafe_Atmosphere_175:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE246, 0x44
; [nakarest] StyleVar_EasyJazzWaltz  +0xe28a..+0xe30e (0xec5448, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Toots' Way 150"; "Mellow Jazz 3/4 150"; "Swing B3 Threes
; [nakarest] 150".
StyleVar_EasyJazzWaltz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE28A, 0x84
; [nakarest] NakaInst_Suited_To_Jazz_150  +0xe30e..+0xe34e (0xec54cc, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Suited
; [nakarest] To Jazz! 150". variation table of 1 style: {u32 title, u16 id} x n + an all-zero
; [nakarest] entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from
; [nakarest] 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Suited_To_Jazz_150:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE30E, 0x22
StyleVar_FiftiesRock:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xE330, 0x1E
; [nakarest] NakaInst_Rock_Fall_155  +0xe34e..+0xe416 (0xec550c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Rock &
; [nakarest] Fall! 155"; "Teddy Boy Brass 155"; "Skiffle Keys 155"; "Ham & Rock 155"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Rock_Fall_155:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE34E, 0x88
StyleVar_PianoRAndRoll:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE3D6, 0x40
; [nakarest] NakaInst_Hard_Blown_R_R_150  +0xe416..+0xe4de (0xec55d4, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Hard
; [nakarest] Blown R&R 150"; "Jerry Lee's Keys 150"; "Slap Back Rock 150"; "Modern Boogie 154";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Hard_Blown_R_R_150:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE416, 0x66
StyleVar_ItsBoogieTime:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xE47C, 0x62
; [nakarest] NakaInst_Boogie_Band_154  +0xe4de..+0xe5a6 (0xec569c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Boogie
; [nakarest] Band 154"; "Oh Boy Vocals 154"; "Jailhouse Brass 158"; "Blue Suede Rock 158"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Boogie_Band_154:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE4DE, 0x44
StyleVar_RockabillyBand:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE522, 0x84
; [nakarest] NakaInst_Don_t_Do_It_158  +0xe5a6..+0xe5e6 (0xec5764, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Don't
; [nakarest] Do It! 158". variation table of 1 style: {u32 title, u16 id} x n + an all-zero
; [nakarest] entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from
; [nakarest] 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Don_t_Do_It_158:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE5A6, 0x22
StyleVar_BoogieTime:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xE5C8, 0x1E
; [nakarest] NakaInst_Barry_s_Boogie_150  +0xe5e6..+0xe6ae (0xec57a4, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Barry's Boogie 150"; "Shuffle Horns 150"; "Accordion Rock 150"; "Alto Sax Shuffle
; [nakarest] 150"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Barry_s_Boogie_150:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE5E6, 0x88
StyleVar_SlowDance:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xE66E, 0x40
; [nakarest] NakaInst_Twin_E_P_Ballad_67  +0xe6ae..+0xe776 (0xec586c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Twin
; [nakarest] E.P.Ballad 67"; "Sweet Soprano 67"; "Ballad Guitar 67"; "Runaway Organ 144"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Twin_E_P_Ballad_67:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE6AE, 0x66
StyleVar_SwingingSixties:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE714, 0x62
; [nakarest] NakaInst_Solid_Surfin_144  +0xe776..+0xe83e (0xec5934, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Solid
; [nakarest] Surfin' 144"; "Ocean Vocals 144"; "Liverpool Roads 154"; "Mersey Beat 154"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Solid_Surfin_144:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE776, 0x44
StyleVar_LiverpoolBeat:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xE7BA, 0x84
; [nakarest] NakaInst_Monkeying_About_154  +0xe83e..+0xe87e (0xec59fc, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Monkeying About 154". variation table of 1 style: {u32 title, u16 id} x n + an
; [nakarest] all-zero entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a
; [nakarest] time from 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Monkeying_About_154:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE83E, 0x22
StyleVar_60sRock:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xE860, 0x1E
; [nakarest] NakaInst_I_Want_To_B3_150  +0xe87e..+0xe946 (0xec5a3c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "I Want
; [nakarest] To B3 150"; "Sax,Drums+R&Roll 150"; "Sixties Strat 150"; "Memphis Keys 150"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_I_Want_To_B3_150:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE87E, 0x88
StyleVar_CaliforniaPop:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xE906, 0x40
; [nakarest] NakaInst_Santa_Monica_Way_150  +0xe946..+0xea0e (0xec5b04, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Santa
; [nakarest] Monica Way 150"; "Easy Bacharach! 150"; "San Jose Route 150"; "70's Glamour 129";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Santa_Monica_Way_150:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE946, 0x66
StyleVar_70sFoxDance:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xE9AC, 0x62
; [nakarest] NakaInst_Handbag_Dance_129  +0xea0e..+0xead6 (0xec5bcc, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Handbag Dance! 129"; "Wunder Pops 129"; "70's Synth Rock 136"; "Platform Wheels
; [nakarest] 136"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Handbag_Dance_129:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEA0E, 0x44
StyleVar_GlamrockPiano:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xEA52, 0x84
; [nakarest] NakaInst_Elton_s_Piano_136  +0xead6..+0xeb16 (0xec5c94, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Elton's
; [nakarest] Piano 136". variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Elton_s_Piano_136:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEAD6, 0x22
StyleVar_70sHits:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xEAF8, 0x1E
; [nakarest] NakaInst_Dire_Strats_138_EC5CD4  +0xeb16..+0xebde (0xec5cd4, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Dire
; [nakarest] Strats 138"; "Knopfler Tribute 138"; "Ricky's Strat 138"; "70's Fantasy 138"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Dire_Strats_138_EC5CD4:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEB16, 0x88
StyleVar_70sPowerRock:			.incbin "includes/generated/naka_style_bitmaps.bin", 0xEB9E, 0x40
; [nakarest] NakaInst_C_P_On_Stage_145  +0xebde..+0xeca6 (0xec5d9c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "C.P.
; [nakarest] On Stage 145"; "Emerson Keys 145"; "Mellow & Shuffle 145"; "Shuffle Organ 144";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_C_P_On_Stage_145:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEBDE, 0x66
StyleVar_EuroPopShuffle:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEC44, 0x62
; [nakarest] NakaInst_Pop_Leader_144  +0xeca6..+0xed6e (0xec5e64, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Pop
; [nakarest] Leader 144"; "Shuffle Synth 144"; "Sax Production 106"; "EP Of The 80's 106"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Pop_Leader_144:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xECA6, 0x44
StyleVar_80sLoveSongs:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xECEA, 0x84
; [nakarest] NakaInst_Analogue_Ballad_106  +0xed6e..+0xedae (0xec5f2c, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Analogue Ballad 106". variation table of 1 style: {u32 title, u16 id} x n + an
; [nakarest] all-zero entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a
; [nakarest] time from 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Analogue_Ballad_106:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xED6E, 0x22
StyleVar_InTheEighties:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xED90, 0x1E
; [nakarest] NakaInst_Italy_Pop_Organ_118  +0xedae..+0xee76 (0xec5f6c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Italy
; [nakarest] Pop Organ 118"; "Pop Angel 118"; "80's Pop Sax 118"; "Fade Guitar Pop 118"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Italy_Pop_Organ_118:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEDAE, 0x88
StyleVar_PopBeat:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xEE36, 0x40
; [nakarest] NakaInst_Pop_Horns_111  +0xee76..+0xef3e (0xec6034, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Pop
; [nakarest] Horns 111"; "Driving Pop 111"; "Pop Guitar FX 111"; "Beat Brass 116"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Pop_Horns_111:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEE76, 0x66
StyleVar_8BeatGroove:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEEDC, 0x62
; [nakarest] NakaInst_Sax_Rock_116  +0xef3e..+0xf006 (0xec60fc, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Sax
; [nakarest] Rock 116"; "Groovy Keys 116"; "Pop Orchestra 78"; "Pop Starts 78"; .... variation
; [nakarest] table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record shape of
; [nakarest] StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the MstStyle2_*
; [nakarest] count loops.
NakaInst_Sax_Rock_116:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEF3E, 0x44
StyleVar_80sPopBallads:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEF82, 0x84
; [nakarest] NakaInst_Ballad_Warmth_78  +0xf006..+0xf046 (0xec61c4, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Ballad
; [nakarest] Warmth 78". variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Ballad_Warmth_78:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF006, 0x22
StyleVar_RockGig:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xF028, 0x1E
; [nakarest] NakaInst_Everybody_Rock_131  +0xf046..+0xf10e (0xec6204, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Everybody Rock! 131"; "Rolling Wheels 131"; "88 Rock Keys 131"; "Stage Rock Band
; [nakarest] 131"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Everybody_Rock_131:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF046, 0x88
StyleVar_HeavyMetal:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xF0CE, 0x40
; [nakarest] NakaInst_Deep_Hammond_142  +0xf10e..+0xf1d6 (0xec62cc, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Deep
; [nakarest] Hammond 142"; "Distort It! 142"; "Solid Feedback 142"; "Rock Fanfare 148"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Deep_Hammond_142:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF10E, 0x66
StyleVar_HeavyShuffle:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xF174, 0x62
; [nakarest] NakaInst_Hard_Analogue_148_EC6394  +0xf1d6..+0xf29e (0xec6394, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Hard
; [nakarest] Analogue 148"; "Clean Metal 148"; "Ballad Overdrive 74"; "Synth For Rock 74"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Hard_Analogue_148_EC6394:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF1D6, 0x44
StyleVar_PowerBallad:			.incbin "includes/generated/naka_style_bitmaps.bin", 0xF21A, 0x84
; [nakarest] NakaInst_Heavy_Harmonica_74_EC645C  +0xf29e..+0xf2de (0xec645c, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Heavy
; [nakarest] Harmonica 74". variation table of 1 style: {u32 title, u16 id} x n + an all-zero
; [nakarest] entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from
; [nakarest] 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Heavy_Harmonica_74_EC645C:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF29E, 0x22
StyleVar_LAPop:				.incbin "includes/generated/naka_style_bitmaps.bin", 0xF2C0, 0x1E
; [nakarest] NakaInst_Digital_Swing_92  +0xf2de..+0xf3a6 (0xec649c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Digital Swing 92"; "Cool Midi Grand 92"; "L.A. Warmth 92"; "Acoustic Groove 92";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Digital_Swing_92:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF2DE, 0x88
StyleVar_GentleSwingRock:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF366, 0x40
; [nakarest] NakaInst_Blues_Harp_Swing_62  +0xf3a6..+0xf42a (0xec6564, 132 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Blues
; [nakarest] Harp Swing 62"; "Like Sunday? 62"; "Mellow Groove 62". variation table of 1 style:
; [nakarest] {u32 title, u16 id} x n + an all-zero entry (the record shape of
; [nakarest] StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the MstStyle2_*
; [nakarest] count loops.
NakaInst_Blues_Harp_Swing_62:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF3A6, 0x66
StyleVar_CoolFusion:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xF40C, 0x1E
; [nakarest] NakaInst_L_A_Strings_92  +0xf42a..+0xf46e (0xec65e8, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "L.A.
; [nakarest] Strings 92"; "Fusion Talk 92".
NakaInst_L_A_Strings_92:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF42A, 0x44
; [nakarest] NakaInst_Synth_Guitar_Pop_92  +0xf46e..+0xf4f2 (0xec662c, 132 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Synth
; [nakarest] Guitar Pop 92"; "Al's Lead 92"; "Uptown Horns 100". variation table of 1 style:
; [nakarest] {u32 title, u16 id} x n + an all-zero entry (the record shape of
; [nakarest] StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the MstStyle2_*
; [nakarest] count loops.
NakaInst_Synth_Guitar_Pop_92:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF46E, 0x44
StyleVar_JazzPop:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xF4B2, 0x40
; [nakarest] NakaInst_Wide_Hornsection_100  +0xf4f2..+0xf536 (0xec66b0, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Wide
; [nakarest] Hornsection 100"; "Cool Guitar Duet 100".
NakaInst_Wide_Hornsection_100:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF4F2, 0x44
; [nakarest] NakaInst_Mad_Tabs_100  +0xf536..+0xf576 (0xec66f4, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Mad
; [nakarest] Tabs 100". variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Mad_Tabs_100:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF536, 0x22
StyleVar_PopFusion:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF558, 0x1E
; [nakarest] NakaInst_Key_Grooves_102  +0xf576..+0xf5ba (0xec6734, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Key
; [nakarest] Grooves 102"; "Cool Pop Guitar 102".
NakaInst_Key_Grooves_102:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF576, 0x44
; [nakarest] NakaInst_George_B_Unison_102  +0xf5ba..+0xf63e (0xec6778, 132 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "George
; [nakarest] B Unison 102"; "Groove Harp 102"; "Drawbar Funk 85". variation table of 1 style:
; [nakarest] {u32 title, u16 id} x n + an all-zero entry (the record shape of
; [nakarest] StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the MstStyle2_*
; [nakarest] count loops.
NakaInst_George_B_Unison_102:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF5BA, 0x44
StyleVar_EasyGroovin:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xF5FE, 0x40
; [nakarest] NakaInst_L_A_Synth_85  +0xf63e..+0xf706 (0xec67fc, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "L.A.
; [nakarest] Synth 85"; "West Coast Sax 85"; "Benson Groove 85"; "Old & New Funk 96"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_L_A_Synth_85:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF63E, 0x66
StyleVar_ChartFusion:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF6A4, 0x62
; [nakarest] NakaInst_Funk_Keys_96  +0xf706..+0xf7ce (0xec68c4, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Funk
; [nakarest] Keys 96"; "Al J's Synth 96"; "Groovin' Horns 97"; "80's Synth Funk 97"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Funk_Keys_96:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF706, 0x44
StyleVar_CoolFunk:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF74A, 0x84
; [nakarest] NakaInst_Yuppie_Keys_97  +0xf7ce..+0xf80e (0xec698c, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Yuppie
; [nakarest] Keys 97". variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Yuppie_Keys_97:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF7CE, 0x22
StyleVar_StraightFunk:		.incbin "includes/generated/naka_style_bitmaps.bin", 0xF7F0, 0x1E
; [nakarest] NakaInst_Sweeping_Bridge_110  +0xf80e..+0xf896 (0xec69cc, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Sweeping Bridge 110"; "Olympic Groove 110"; "Synth Funk 110"; "Funky Talk 110".
NakaInst_Sweeping_Bridge_110:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF80E, 0x88
; [nakarest] StyleVar_FunkyTalk  +0xf896..+0xf8d6 (0xec6a54, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Space Dance 127".
StyleVar_FunkyTalk:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF896, 0x40
; [nakarest] NakaInst_Retro_Groove_127  +0xf8d6..+0xf93c (0xec6a94, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Retro
; [nakarest] Groove 127"; "Dance Floor 127"; "London Scene 127".
NakaInst_Retro_Groove_127:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF8D6, 0x66
; [nakarest] StyleVar_OldDanceHit  +0xf93c..+0xf99e (0xec6afa, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Retro Dance 121"; "90's Synth Dance 121".
StyleVar_OldDanceHit:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF93C, 0x62
; [nakarest] NakaInst_Metalic_Dance_121  +0xf99e..+0xf9e2 (0xec6b5c, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Metalic Dance 121"; "Old Dance Hit 121".
NakaInst_Metalic_Dance_121:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF99E, 0x44
; [nakarest] StyleVar_PolyDance  +0xf9e2..+0xfa66 (0xec6ba0, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "House Keys 125"; "House & Garden 125"; "Poly Dance 125".
StyleVar_PolyDance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF9E2, 0x84
; [nakarest] NakaInst_House_Piano_125  +0xfa66..+0xfa88 (0xec6c24, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "House
; [nakarest] Piano 125".
NakaInst_House_Piano_125:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFA66, 0x22
; [nakarest] StyleVar_DanceSquares  +0xfa88..+0xfaa6 (0xec6c46, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_DanceSquares:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFA88, 0x1E
; [nakarest] NakaInst_Techno_Angle_146  +0xfaa6..+0xfb2e (0xec6c64, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Techno
; [nakarest] Angle 146"; "Rave Pad 146"; "Atmo Boom Boom 146"; "Dance Squares 146".
NakaInst_Techno_Angle_146:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFAA6, 0x88
; [nakarest] StyleVar_DiscoTechni  +0xfb2e..+0xfb6e (0xec6cec, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Mirrorball Dance 118".
StyleVar_DiscoTechni:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFB2E, 0x40
; [nakarest] NakaInst_Disco_Techni_118_EC6D2C  +0xfb6e..+0xfbd4 (0xec6d2c, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Disco-Techni 118"; "Disco Pads 118"; "80's Piano Disco 118".
NakaInst_Disco_Techni_118_EC6D2C:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFB6E, 0x66
; [nakarest] StyleVar_EuroDiscoHit  +0xfbd4..+0xfc36 (0xec6d92, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "80's Dancefloor 115"; "Travolta Dance 115".
StyleVar_EuroDiscoHit:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFBD4, 0x62
; [nakarest] NakaInst_New_York_Disco_115  +0xfc36..+0xfc7a (0xec6df4, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "New
; [nakarest] York Disco 115"; "Saturday Night 115".
NakaInst_New_York_Disco_115:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFC36, 0x44
; [nakarest] StyleVar_DiscoTalk  +0xfc7a..+0xfcfe (0xec6e38, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Disco Fever 121"; "Cool Disco Night 121"; "English Hits
; [nakarest] 121".
StyleVar_DiscoTalk:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFC7A, 0x84
; [nakarest] NakaInst_Disco_Agogo_121  +0xfcfe..+0xfd20 (0xec6ebc, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Disco
; [nakarest] Agogo 121".
NakaInst_Disco_Agogo_121:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFCFE, 0x22
; [nakarest] StyleVar_70sDanceHit  +0xfd20..+0xfd3e (0xec6ede, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_70sDanceHit:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFD20, 0x1E
; [nakarest] NakaInst_Disco_Metal_124_EC6EFC  +0xfd3e..+0xfdc6 (0xec6efc, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Disco
; [nakarest] Metal 124"; "Disco Synths 124"; "A Case For Dance 124"; "Funky Stuff 124".
NakaInst_Disco_Metal_124_EC6EFC:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFD3E, 0x88
; [nakarest] StyleVar_DiscoRanger  +0xfdc6..+0xfe06 (0xec6f84, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Voco-Dance 108".
StyleVar_DiscoRanger:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFDC6, 0x40
; [nakarest] NakaInst_Hip_Hop_Echoes_108  +0xfe06..+0xfe6c (0xec6fc4, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Hip-Hop-Echoes 108"; "Hip - Pad 108"; "Hip Keys 108".
NakaInst_Hip_Hop_Echoes_108:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFE06, 0x66
; [nakarest] StyleVar_GloryDisco  +0xfe6c..+0xfece (0xec702a, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Disco Horns 108"; "Digi Dancefloor 108".
StyleVar_GloryDisco:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFE6C, 0x62
; [nakarest] NakaInst_Synth_of_The_90s_108  +0xfece..+0xff12 (0xec708c, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Synth
; [nakarest] of The 90s 108"; "Brassy Dance 108".
NakaInst_Synth_of_The_90s_108:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFECE, 0x44
; [nakarest] StyleVar_NYRap  +0xff12..+0xff96 (0xec70d0, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Synth Rapper 96"; "Hit The Groove 96"; "Street Talk 96".
StyleVar_NYRap:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFF12, 0x84
; [nakarest] NakaInst_Pump_The_Bass_96  +0xff96..+0xffb8 (0xec7154, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Pump
; [nakarest] The Bass 96".
NakaInst_Pump_The_Bass_96:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFF96, 0x22
; [nakarest] StyleVar_HipHop  +0xffb8..+0xffd6 (0xec7176, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_HipHop:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFFB8, 0x1E
; [nakarest] NakaInst_Dance_Island_104_EC7194  +0xffd6..+0x1005e (0xec7194, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Dance
; [nakarest] Island 104"; "Caribbean Drive 104"; "Macadancer 104"; "Line Up Dance 104".
NakaInst_Dance_Island_104_EC7194:	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFFD6, 0x88
; [nakarest] StyleVar_ReggaeHit  +0x1005e..+0x1009e (0xec721c, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Olympic Dance 101".
StyleVar_ReggaeHit:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1005E, 0x40
; [nakarest] NakaInst_Rasta_Jambo_101  +0x1009e..+0x10104 (0xec725c, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Rasta
; [nakarest] Jambo 101"; "Daa Daa Dance 101"; "Coco Dance 101".
NakaInst_Rasta_Jambo_101:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1009E, 0x66
; [nakarest] StyleVar_RioGosDisco  +0x10104..+0x10166 (0xec72c2, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Aye Aye Caramba 125"; "Joao's Rio-Disco 125".
StyleVar_RioGosDisco:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10104, 0x62
; [nakarest] NakaInst_Dancing_Flutes_125_EC7324  +0x10166..+0x101aa (0xec7324, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Dancing Flutes 125"; "Disco Strings 125".
NakaInst_Dancing_Flutes_125_EC7324:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10166, 0x44
; [nakarest] StyleVar_JamboDance  +0x101aa..+0x1022e (0xec7368, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Dance Steel 101"; "Dance Vocals 101"; "Reggae Talk 101".
StyleVar_JamboDance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x101AA, 0x84
; [nakarest] NakaInst_Reggae_Dance_Hit_101  +0x1022e..+0x10250 (0xec73ec, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Reggae
; [nakarest] Dance Hit 101".
NakaInst_Reggae_Dance_Hit_101:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1022E, 0x22
; [nakarest] StyleVar_SambaParty  +0x10250..+0x1026e (0xec740e, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_SambaParty:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10250, 0x1E
; [nakarest] NakaInst_Festival_Amigos_116_EC742C  +0x1026e..+0x102f6 (0xec742c, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Festival Amigos 116"; "Piano Cabana 116"; "Party In Rio 116"; "Alto Samba 116".
NakaInst_Festival_Amigos_116_EC742C:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1026E, 0x88
; [nakarest] StyleVar_LatinFestival  +0x102f6..+0x10336 (0xec74b4, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Techno Fiddle 124".
StyleVar_LatinFestival:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x102F6, 0x40
; [nakarest] NakaInst_Dance_Surround_124_EC74F4  +0x10336..+0x103fe (0xec74f4, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Dance
; [nakarest] Surround 124"; "New Square Dance 124"; "Dance Leader 124"; "James At Last 120";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Dance_Surround_124_EC74F4:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10336, 0x66
StyleVar_JLastHitparade:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1039C, 0x62
; [nakarest] NakaInst_Last_Starparade_120  +0x103fe..+0x104c6 (0xec75bc, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Last
; [nakarest] Starparade! 120"; "Last At First 120"; "The Party Band 111"; "James' Orchestra
; [nakarest] 111"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Last_Starparade_120:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x103FE, 0x44
StyleVar_LastArrangement:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10442, 0x84
; [nakarest] NakaInst_Party_Flautist_111  +0x104c6..+0x10506 (0xec7684, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Party
; [nakarest] Flautist 111". variation table of 1 style: {u32 title, u16 id} x n + an all-zero
; [nakarest] entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from
; [nakarest] 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Party_Flautist_111:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x104C6, 0x22
StyleVar_GermanSchlager_2:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x104E8, 0x1E
; [nakarest] NakaInst_German_HitParade_120  +0x10506..+0x105ce (0xec76c4, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "German-HitParade 120"; "Flippers-Guitars 120"; "Ricky K.Pop 120"; "Ibo To Ibiza!
; [nakarest] 120"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_German_HitParade_120:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10506, 0x88
StyleVar_AllNightParty:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1058E, 0x40
; [nakarest] NakaInst_Ady_s_PartyOrgan_125_EC778C  +0x105ce..+0x10696 (0xec778c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Ady's
; [nakarest] PartyOrgan 125"; "German FolkParty 125"; "Happy Woodpecker 125"; "Fair Sea Organ
; [nakarest] 125"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Ady_s_PartyOrgan_125_EC778C:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x105CE, 0x66
StyleVar_PopOrganMarch:			.incbin "includes/generated/naka_style_bitmaps.bin", 0x10634, 0x62
; [nakarest] NakaInst_Pop_Of_The_Bells_125  +0x10696..+0x1075e (0xec7854, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Pop Of
; [nakarest] The Bells 125"; "Piccolo Pop 125"; "Bridge Party 116"; "No Lyrics Needed 116"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Pop_Of_The_Bells_125:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10696, 0x44
StyleVar_EurovisionHits:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x106DA, 0x84
; [nakarest] NakaInst_Puppet_March_116  +0x1075e..+0x1079e (0xec791c, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Puppet
; [nakarest] March 116". variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Puppet_March_116:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1075E, 0x22
StyleVar_EuroPartyPop:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x10780, 0x1E
; [nakarest] NakaInst_Party_Space_120  +0x1079e..+0x10866 (0xec795c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Party
; [nakarest] Space 120"; "String Pops 120"; "Party Accordion 120"; "Pop Accordion 120"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Party_Space_120:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1079E, 0x88
StyleVar_GermanOldies:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x10826, 0x40
; [nakarest] NakaInst_Orgel_Pops_111  +0x10866..+0x1092e (0xec7a24, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Orgel
; [nakarest] Pops 111"; "Party Pop Stack 111"; "Synth Party 111"; "50's Section 133"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Orgel_Pops_111:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10866, 0x66
StyleVar_GoldenOldies:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x108CC, 0x62
; [nakarest] NakaInst_Anka_Rock_133  +0x1092e..+0x109f6 (0xec7aec, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Anka
; [nakarest] Rock 133"; "The Old Bars 133"; "Party Partners 115"; "Alto Duet Party 115"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Anka_Rock_133:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1092E, 0x44
StyleVar_BeerBarrelPolka:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10972, 0x84
; [nakarest] NakaInst_Party_Register_115  +0x109f6..+0x10a36 (0xec7bb4, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Party
; [nakarest] Register 115". variation table of 1 style: {u32 title, u16 id} x n + an all-zero
; [nakarest] entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from
; [nakarest] 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Party_Register_115:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x109F6, 0x22
StyleVar_DoTheHokie:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x10A18, 0x1E
; [nakarest] NakaInst_Shake_It_All_162  +0x10a36..+0x10afe (0xec7bf4, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Shake
; [nakarest] It All.... 162"; "Dancing Bellows 162"; "Old Party Dance 162"; "Turn 162"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Shake_It_All_162:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10A36, 0x88
StyleVar_DancingBirdies:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10ABE, 0x40
; [nakarest] NakaInst_Chords_Birds_100  +0x10afe..+0x10bc6 (0xec7cbc, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Chords
; [nakarest] & Birds 100"; "Bird-Voices 100"; "Birdy-Accordion 100"; "London's Bigbone 134";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Chords_Birds_100:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10AFE, 0x66
StyleVar_PubSingalong:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x10B64, 0x62
; [nakarest] NakaInst_Banjo_Sing_Song_134  +0x10bc6..+0x10c8e (0xec7d84, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Banjo
; [nakarest] Sing Song 134"; "Cockney Clarinet 134"; "Dance Craze Sax 132"; "88 In Line! 132";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Banjo_Sing_Song_134:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10BC6, 0x44
StyleVar_LineDanceCraze:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10C0A, 0x84
; [nakarest] NakaInst_Fiddle_Dance_132  +0x10c8e..+0x10cce (0xec7e4c, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Fiddle
; [nakarest] Dance 132". variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Fiddle_Dance_132:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10C8E, 0x22
StyleVar_BarnDance:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x10CB0, 0x1E
; [nakarest] NakaInst_Symphony_Hoedown_206  +0x10cce..+0x10d96 (0xec7e8c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Symphony Hoedown 206"; "Hoedown Frets 206"; "Oklahoma Dance 206"; "Country Dance
; [nakarest] 206"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Symphony_Hoedown_206:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10CCE, 0x88
StyleVar_HillbillyJoe:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x10D56, 0x40
; [nakarest] NakaInst_Techno_Ranger_138  +0x10d96..+0x10e5e (0xec7f54, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Techno
; [nakarest] Ranger 138"; "Dance Cowboy 138"; "Banjo Dance 138"; "Oktober Party 150"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Techno_Ranger_138:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10D96, 0x66
StyleVar_BavarianParty:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x10DFC, 0x62
; [nakarest] NakaInst_The_Zillertaler_150  +0x10e5e..+0x10f26 (0xec801c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "The
; [nakarest] Zillertaler 150"; "Auf Gehts! 150"; "Bavaria To Tyrol 195"; "Munich Brass 195";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_The_Zillertaler_150:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10E5E, 0x44
StyleVar_MunichFestival:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10EA2, 0x84
; [nakarest] NakaInst_Sepp_s_Clarinet_195  +0x10f26..+0x10f66 (0xec80e4, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Sepp's
; [nakarest] Clarinet 195". variation table of 1 style: {u32 title, u16 id} x n + an all-zero
; [nakarest] entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from
; [nakarest] 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Sepp_s_Clarinet_195:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10F26, 0x22
StyleVar_MerryChristmas:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10F48, 0x1E
; [nakarest] NakaInst_Miseltoe_Melody_75  +0x10f66..+0x10fee (0xec8124, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Miseltoe Melody 75"; "Carol Singers 75"; "Yuletide Strings 75"; "Santa's Helpers
; [nakarest] 75".
NakaInst_Miseltoe_Melody_75:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10F66, 0x88
; [nakarest] StyleVar_KingOfSoul  +0x10fee..+0x1102e (0xec81ac, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Soulful Wha Wha 140".
StyleVar_KingOfSoul:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10FEE, 0x40
; [nakarest] NakaInst_Bad_Soul_Bars_140  +0x1102e..+0x11094 (0xec81ec, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Bad
; [nakarest] Soul Bars 140"; "Saxy Soul 140"; "Feelin' Good 140".
NakaInst_Bad_Soul_Bars_140:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1102E, 0x66
; [nakarest] StyleVar_DetroitPop  +0x11094..+0x110f6 (0xec8252, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Motor Town Brass 142"; "Detroit Strings 142".
StyleVar_DetroitPop:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11094, 0x62
; [nakarest] NakaInst_Ross_Vocals_142  +0x110f6..+0x1113a (0xec82b4, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Ross
; [nakarest] Vocals 142"; "Supreme Tenor 142".
NakaInst_Ross_Vocals_142:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x110F6, 0x44
; [nakarest] StyleVar_SoftSoul  +0x1113a..+0x111be (0xec82f8, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Synth Soul Horns 114"; "Soul Solo 114"; "A Few Soulbars
; [nakarest] 114".
StyleVar_SoftSoul:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1113A, 0x84
; [nakarest] NakaInst_A_Case_Of_Soul_114_EC837C  +0x111be..+0x111e0 (0xec837c, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "A Case
; [nakarest] Of Soul 114".
NakaInst_A_Case_Of_Soul_114_EC837C:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x111BE, 0x22
; [nakarest] StyleVar_NewSoulBallad  +0x111e0..+0x111fe (0xec839e, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_NewSoulBallad:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x111E0, 0x1E
; [nakarest] NakaInst_Soul_Suitcase_70  +0x111fe..+0x11286 (0xec83bc, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Soul
; [nakarest] Suitcase 70"; "Soul Drawbars 70"; "Soulful Sax 70"; "Synth For Soul 70".
NakaInst_Soul_Suitcase_70:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x111FE, 0x88
; [nakarest] StyleVar_SoulToSun  +0x11286..+0x112c6 (0xec8444, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Soulful Groove 88".
StyleVar_SoulToSun:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11286, 0x40
; [nakarest] NakaInst_Keys_To_Soul_88  +0x112c6..+0x1132c (0xec8484, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Keys
; [nakarest] To Soul 88"; "Soul Horn 88"; "Sweet Soul 88".
NakaInst_Keys_To_Soul_88:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x112C6, 0x66
; [nakarest] StyleVar_MellowSoul  +0x1132c..+0x1138e (0xec84ea, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Soul Vocal Duo 66"; "Cool Soul Frets 66".
StyleVar_MellowSoul:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1132C, 0x62
; [nakarest] NakaInst_Sweet_16_Sax_66  +0x1138e..+0x113d2 (0xec854c, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Sweet
; [nakarest] 16 Sax 66"; "Soulful Flute 66".
NakaInst_Sweet_16_Sax_66:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1138E, 0x44
; [nakarest] StyleVar_SlowSoulMood  +0x113d2..+0x11456 (0xec8590, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Georgia Brass 64"; "Moody Drawbars 64"; "Ray's Ballad
; [nakarest] 64".
StyleVar_SlowSoulMood:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x113D2, 0x84
; [nakarest] NakaInst_Soul_On_My_Mind_64  +0x11456..+0x11478 (0xec8614, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Soul On
; [nakarest] My Mind 64".
NakaInst_Soul_On_My_Mind_64:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11456, 0x22
; [nakarest] StyleVar_RBGroove  +0x11478..+0x11496 (0xec8636, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_RBGroove:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11478, 0x1E
; [nakarest] NakaInst_Blues_Horns_112  +0x11496..+0x1151e (0xec8654, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Blues
; [nakarest] Horns 112"; "Analogue Blues 112"; "Vintage R&B 112"; "Solid R&B 112".
NakaInst_Blues_Horns_112:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11496, 0x88
; [nakarest] StyleVar_DownDirtyBlues  +0x1151e..+0x1155e (0xec86dc, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Big Band Blues 78".
StyleVar_DownDirtyBlues:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1151E, 0x40
; [nakarest] NakaInst_Solid_Blues_78  +0x1155e..+0x115c4 (0xec871c, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Solid
; [nakarest] Blues 78"; "Bad B3 Blues 78"; "Satchmo's Blues 78".
NakaInst_Solid_Blues_78:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1155E, 0x66
; [nakarest] StyleVar_RockBlues  +0x115c4..+0x11626 (0xec8782, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Down & Dirty 124"; "Blues Alley 124".
StyleVar_RockBlues:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x115C4, 0x62
; [nakarest] NakaInst_Hard_Sax_Blues_124_EC87E4  +0x11626..+0x1166a (0xec87e4, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Hard
; [nakarest] Sax Blues 124"; "Blues Rock Keys 124".
NakaInst_Hard_Sax_Blues_124_EC87E4:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11626, 0x44
; [nakarest] StyleVar_PlayTheBlues  +0x1166a..+0x116ee (0xec8828, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Wah Wah Blues 83"; "Blues Bars 83"; "Blues Steel 83".
StyleVar_PlayTheBlues:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1166A, 0x84
; [nakarest] NakaInst_I_Got_The_Blues_83_EC88AC  +0x116ee..+0x11710 (0xec88ac, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "I Got
; [nakarest] The Blues 83".
NakaInst_I_Got_The_Blues_83_EC88AC:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x116EE, 0x22
; [nakarest] StyleVar_BluesAlley  +0x11710..+0x11902 (0xec88ce, 498 B)
; [nakarest] variation tables of 3 styles: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Mournful Tenor 120"; "Bad Blues Brass 120"; "Ham & Blues
; [nakarest] 120"; "Bluesy Alto 120"; ....
StyleVar_BluesAlley:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x11710, 0x1E
SoundName_MournfulTenor:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1172E, 0x88
StyleSound_BluesAlley_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x117B6, 0x40
SoundName_HymnBand:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x117F6, 0x66
StyleVar_LiftYourSoul:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1185C, 0x62
SoundName_PreachTheWord:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x118BE, 0x44
; [nakarest] StyleVar_DayOfRest  +0x11902..+0x11986 (0xec8ac0, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Reed The Word 124"; "Chapel Brass 124"; "Sing Hallelujah
; [nakarest] 124".
StyleVar_DayOfRest:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11902, 0x84
; [nakarest] NakaInst_Gospel_Standard_124  +0x11986..+0x119a8 (0xec8b44, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Gospel
; [nakarest] Standard 124".
NakaInst_Gospel_Standard_124:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11986, 0x22
; [nakarest] StyleVar_PowerGospel  +0x119a8..+0x119c6 (0xec8b66, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_PowerGospel:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x119A8, 0x1E
; [nakarest] NakaInst_Congregation_151  +0x119c6..+0x11a4e (0xec8b84, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Congregation! 151"; "Worship Groove 151"; "Gospel Drawbars 151"; "Soprano Prayer
; [nakarest] 151".
NakaInst_Congregation_151:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x119C6, 0x88
; [nakarest] StyleVar_GospelBlues  +0x11a4e..+0x11a8e (0xec8c0c, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Gospel Lead 66".
StyleVar_GospelBlues:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11A4E, 0x40
; [nakarest] NakaInst_Drawbar_Service_66  +0x11a8e..+0x11af4 (0xec8c4c, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Drawbar Service 66"; "Church Grand 66"; "Gospel Organ 66".
NakaInst_Drawbar_Service_66:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11A8E, 0x66
; [nakarest] StyleVar_GospelInThrees  +0x11af4..+0x11b56 (0xec8cb2, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Sing Praises 92"; "Modern Gospel 92".
StyleVar_GospelInThrees:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11AF4, 0x62
; [nakarest] NakaInst_Sing_It_Play_It_92  +0x11b56..+0x11b9a (0xec8d14, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Sing
; [nakarest] It, Play It 92"; "Amazing Waltz! 92".
NakaInst_Sing_It_Play_It_92:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11B56, 0x44
; [nakarest] StyleVar_UpTempoBigband  +0x11b9a..+0x11c1e (0xec8d58, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Bigband Shout 170"; "Fast Reeds 170"; "Swing Alto Solo
; [nakarest] 170".
StyleVar_UpTempoBigband:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11B9A, 0x84
; [nakarest] NakaInst_The_Duke_s_Piano_170  +0x11c1e..+0x11c40 (0xec8ddc, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "The
; [nakarest] Duke's Piano 170".
NakaInst_The_Duke_s_Piano_170:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11C1E, 0x22
; [nakarest] StyleVar_SteadySwingband  +0x11c40..+0x11c5e (0xec8dfe, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_SteadySwingband:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11C40, 0x1E
; [nakarest] NakaInst_Reeds_in_Unison_110  +0x11c5e..+0x11ce6 (0xec8e1c, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Reeds
; [nakarest] in Unison 110"; "Full Mute Brass 110"; "Dorsey Band 110"; "Father Time Solo 110".
NakaInst_Reeds_in_Unison_110:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11C5E, 0x88
; [nakarest] StyleVar_AllAboard  +0x11ce6..+0x11d26 (0xec8ea4, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Miller Station 150".
StyleVar_AllAboard:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11CE6, 0x40
; [nakarest] NakaInst_Main_Line_Brass_150  +0x11d26..+0x11d8c (0xec8ee4, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Main
; [nakarest] Line Brass 150"; "Sax Tracks 150"; "Getting Up Steam 150".
NakaInst_Main_Line_Brass_150:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11D26, 0x66
; [nakarest] StyleVar_40sDanceBand  +0x11d8c..+0x11dee (0xec8f4a, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Harry J.& Co. 86"; "Mellow Section 86".
StyleVar_40sDanceBand:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11D8C, 0x62
; [nakarest] NakaInst_Miller_Reeds_86  +0x11dee..+0x11e32 (0xec8fac, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Miller
; [nakarest] Reeds 86"; "Sentimental Solo 86".
NakaInst_Miller_Reeds_86:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11DEE, 0x44
; [nakarest] StyleVar_SentimentalBand  +0x11e32..+0x11eb6 (0xec8ff0, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "The Whole Band! 90"; "Count On It! 90"; "Mute Soloist
; [nakarest] 90".
StyleVar_SentimentalBand:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11E32, 0x84
; [nakarest] NakaInst_Acker_s_Solo_90  +0x11eb6..+0x11ed8 (0xec9074, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Acker's
; [nakarest] Solo 90".
NakaInst_Acker_s_Solo_90:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11EB6, 0x22
; [nakarest] StyleVar_MoonlightDance  +0x11ed8..+0x11ef6 (0xec9096, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_MoonlightDance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11ED8, 0x1E
; [nakarest] NakaInst_Glenn_s_Big_Band_90  +0x11ef6..+0x11f7e (0xec90b4, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Glenn's Big Band 90"; "Band Leader Solo 90"; "Full Dance Band 90"; "Swing
; [nakarest] Orchestra 90".
NakaInst_Glenn_s_Big_Band_90:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11EF6, 0x88
; [nakarest] StyleVar_40sLoveSongs  +0x11f7e..+0x11fbe (0xec913c, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Harry's Solo 92".
StyleVar_40sLoveSongs:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11F7E, 0x40
; [nakarest] NakaInst_Big_Band_Sound_92  +0x11fbe..+0x12024 (0xec917c, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Big
; [nakarest] Band Sound 92"; "Gentle Reeds 92"; "Muted Big Band 92".
NakaInst_Big_Band_Sound_92:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11FBE, 0x66
; [nakarest] StyleVar_MidSwingband  +0x12024..+0x12086 (0xec91e2, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Full Tilt Swing! 127"; "Power Sax Swing 127".
StyleVar_MidSwingband:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12024, 0x62
; [nakarest] NakaInst_Reed_It_Mute_It_127  +0x12086..+0x120ca (0xec9244, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Reed
; [nakarest] It, Mute It 127"; "Swing Reedle 127".
NakaInst_Reed_It_Mute_It_127:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12086, 0x44
; [nakarest] StyleVar_SwingOrchestra  +0x120ca..+0x1214e (0xec9288, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Lush Swing 142"; "Riddle Orchestra 142"; "Sinatra
; [nakarest] Strings 142".
StyleVar_SwingOrchestra:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x120CA, 0x84
; [nakarest] NakaInst_Swingin_Frets_142  +0x1214e..+0x12170 (0xec930c, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Swingin' Frets 142".
NakaInst_Swingin_Frets_142:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1214E, 0x22
; [nakarest] StyleVar_NightClubCombo  +0x12170..+0x1218e (0xec932e, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_NightClubCombo:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12170, 0x1E
; [nakarest] NakaInst_Swing_Unison_158  +0x1218e..+0x12216 (0xec934c, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Swing
; [nakarest] Unison 158"; "The Band Leader 158"; "Grand Swing! 158"; "Laid Back Jazz 158".
NakaInst_Swing_Unison_158:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1218E, 0x88
; [nakarest] StyleVar_EasyPlaySwing  +0x12216..+0x12256 (0xec93d4, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Reed It & Swing! 140".
StyleVar_EasyPlaySwing:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12216, 0x40
; [nakarest] NakaInst_Swing_Sparkle_140  +0x12256..+0x122bc (0xec9414, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Swing
; [nakarest] Sparkle 140"; "Organist's Swing 140"; "Swinging Keys 140".
NakaInst_Swing_Sparkle_140:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12256, 0x66
; [nakarest] StyleVar_JazzClub  +0x122bc..+0x1231e (0xec947a, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Jazz Bars 146"; "Combo Romance 146".
StyleVar_JazzClub:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x122BC, 0x62
; [nakarest] NakaInst_Club_Duet_146  +0x1231e..+0x12362 (0xec94dc, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Club
; [nakarest] Duet 146"; "Jazz Blocks 146".
NakaInst_Club_Duet_146:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1231E, 0x44
; [nakarest] StyleVar_UpTempoCombo  +0x12362..+0x123e6 (0xec9520, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Lionel Meets Wes 174"; "Jazz From Wes 174"; "Oscar's Gig
; [nakarest] 174".
StyleVar_UpTempoCombo:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12362, 0x84
; [nakarest] NakaInst_Acoustic_Jazz_174  +0x123e6..+0x12408 (0xec95a4, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Acoustic Jazz 174".
NakaInst_Acoustic_Jazz_174:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x123E6, 0x22
; [nakarest] StyleVar_SimpleJazz  +0x12408..+0x12426 (0xec95c6, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_SimpleJazz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12408, 0x1E
; [nakarest] NakaInst_Wild_Side_Organ_200  +0x12426..+0x124ae (0xec95e4, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Wild
; [nakarest] Side Organ 200"; "Simple Jimmy 200"; "Helmut & Strings 200"; "Zacharias Swing 200".
NakaInst_Wild_Side_Organ_200:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12426, 0x88
; [nakarest] StyleVar_40sBoogie  +0x124ae..+0x124ee (0xec966c, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Boogie Bugles 160".
StyleVar_40sBoogie:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x124AE, 0x40
; [nakarest] NakaInst_Boogie_Dance_160_EC96AC  +0x124ee..+0x12554 (0xec96ac, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Boogie
; [nakarest] Dance 160"; "12 Boogie Bars 160"; "Jitterbug Vocals 160".
NakaInst_Boogie_Dance_160_EC96AC:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x124EE, 0x66
; [nakarest] StyleVar_JazzStandards  +0x12554..+0x125b6 (0xec9712, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Partners in Jazz 145"; "Cool Jazz B3 145".
StyleVar_JazzStandards:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12554, 0x62
; [nakarest] NakaInst_Saxy_Jazz_145  +0x125b6..+0x125fa (0xec9774, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Saxy
; [nakarest] Jazz 145"; "Lionel's Jazz 145".
NakaInst_Saxy_Jazz_145:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x125B6, 0x44
; [nakarest] StyleVar_ComboDrawbars  +0x125fa..+0x1267e (0xec97b8, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "All Out Jazz 170"; "Slow Spin Groove 170"; "Classic
; [nakarest] Groove 170".
StyleVar_ComboDrawbars:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x125FA, 0x84
; [nakarest] NakaInst_Even_Jazz_170  +0x1267e..+0x126a0 (0xec983c, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Even
; [nakarest] Jazz 170".
NakaInst_Even_Jazz_170:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1267E, 0x22
; [nakarest] StyleVar_GentleJazz  +0x126a0..+0x126be (0xec985e, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_GentleJazz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x126A0, 0x1E
; [nakarest] NakaInst_Combo_Soloists_126  +0x126be..+0x12746 (0xec987c, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Combo
; [nakarest] Soloists 126"; "Late Night Sax 126"; "Shearing Combo 126"; "Nat's Piano 126".
NakaInst_Combo_Soloists_126:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x126BE, 0x88
; [nakarest] StyleVar_GypsyJazzers  +0x12746..+0x12786 (0xec9904, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Reinhardt's Solo 210".
StyleVar_GypsyJazzers:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12746, 0x40
; [nakarest] NakaInst_Stephane_Django_210  +0x12786..+0x127ec (0xec9944, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Stephane&Django 210"; "Fiddle For Jazz 210"; "Gypsy Jazz Frets 210".
NakaInst_Stephane_Django_210:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12786, 0x66
; [nakarest] StyleVar_JazzAccordion  +0x127ec..+0x1284e (0xec99aa, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Bellows & Blocks 158"; "Accordion & Co! 158".
StyleVar_JazzAccordion:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x127EC, 0x62
; [nakarest] NakaInst_Let_It_Register_158  +0x1284e..+0x12892 (0xec9a0c, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Let It
; [nakarest] Register! 158"; "Soft Squeeze 158".
NakaInst_Let_It_Register_158:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1284E, 0x44
; [nakarest] StyleVar_SpeakeasyJazz  +0x12892..+0x12916 (0xec9a50, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Moonshine Combo 184"; "Wall St. Jazz 184"; "Roaring
; [nakarest] Trumpet 184".
StyleVar_SpeakeasyJazz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12892, 0x84
; [nakarest] NakaInst_Chicago_Piano_184  +0x12916..+0x12938 (0xec9ad4, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Chicago
; [nakarest] Piano 184".
NakaInst_Chicago_Piano_184:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12916, 0x22
; [nakarest] StyleVar_JazzFrancais  +0x12938..+0x12956 (0xec9af6, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_JazzFrancais:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12938, 0x1E
; [nakarest] NakaInst_Squeeze_Box_Jazz_190  +0x12956..+0x129de (0xec9b14, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Squeeze Box Jazz 190"; "Paris Jazz Duet 190"; "Grapelli Jazz 190"; "Django's Solo
; [nakarest] 190".
NakaInst_Squeeze_Box_Jazz_190:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12956, 0x88
; [nakarest] StyleVar_VanDammeJazz  +0x129de..+0x12a1e (0xec9b9c, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Hubert & Klaus 190".
StyleVar_VanDammeJazz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x129DE, 0x40
; [nakarest] NakaInst_Deuringer_Swing_190_EC9BDC  +0x12a1e..+0x12a84 (0xec9bdc, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Deuringer Swing 190"; "Art Meets Lionel 190"; "Art's Swing Box 190".
NakaInst_Deuringer_Swing_190_EC9BDC:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12A1E, 0x66
; [nakarest] StyleVar_EuroJazz  +0x12a84..+0x12ae6 (0xec9c42, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Mellow Jazz Tabs 147"; "Euro Squeezebox 147".
StyleVar_EuroJazz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12A84, 0x62
; [nakarest] NakaInst_Duelling_Reeds_147  +0x12ae6..+0x12b2a (0xec9ca4, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Duelling Reeds 147"; "Boxing Jazzy 147".
NakaInst_Duelling_Reeds_147:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12AE6, 0x44
; [nakarest] StyleVar_SmokeyJazzClub  +0x12b2a..+0x12bae (0xec9ce8, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "New Jazz Ballad 70"; "B3 Blocks 70"; "Breathy Vibes 70".
StyleVar_SmokeyJazzClub:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12B2A, 0x84
; [nakarest] NakaInst_Slide_Scale_Jazz_70  +0x12bae..+0x12bd0 (0xec9d6c, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Slide
; [nakarest] Scale Jazz 70".
NakaInst_Slide_Scale_Jazz_70:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12BAE, 0x22
; [nakarest] StyleVar_JazzAt3am  +0x12bd0..+0x12bee (0xec9d8e, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_JazzAt3am:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12BD0, 0x1E
; [nakarest] NakaInst_Unwind_To_This_72  +0x12bee..+0x12c76 (0xec9dac, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Unwind
; [nakarest] To This 72"; "Chuck's Late Gig 72"; "Too Late For Sax 72"; "Late Night Frets 72".
NakaInst_Unwind_To_This_72:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12BEE, 0x88
; [nakarest] StyleVar_SteadyJazz34  +0x12c76..+0x12cb6 (0xec9e34, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "3/4 Sax Vibes 158".
StyleVar_SteadyJazz34:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12C76, 0x40
; [nakarest] NakaInst_Do_You_Reed_It_158  +0x12cb6..+0x12d1c (0xec9e74, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Do You
; [nakarest] Reed It? 158"; "3 Quarter Duo 158"; "Jazz Partners 158".
NakaInst_Do_You_Reed_It_158:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12CB6, 0x66
; [nakarest] StyleVar_SlowJazz34  +0x12d1c..+0x12d7e (0xec9eda, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Waltz Groove 150"; "3/4 Played by 4 150".
StyleVar_SlowJazz34:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12D1C, 0x62
; [nakarest] NakaInst_Toots_Trick_150  +0x12d7e..+0x12dc2 (0xec9f3c, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Toots'
; [nakarest] Trick! 150"; "Flautist's Jazz 150".
NakaInst_Toots_Trick_150:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12D7E, 0x44
; [nakarest] StyleVar_TheGroove  +0x12dc2..+0x12e46 (0xec9f80, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Smokin' B-3 Jazz 180"; "Jazz To The Bone 180"; "Modern
; [nakarest] Vibes 180".
StyleVar_TheGroove:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12DC2, 0x84
; [nakarest] NakaInst_Soprano_Groove_180  +0x12e46..+0x12e68 (0xeca004, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Soprano
; [nakarest] Groove 180".
NakaInst_Soprano_Groove_180:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12E46, 0x22
; [nakarest] StyleVar_LAFusion  +0x12e68..+0x12e86 (0xeca026, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_LAFusion:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12E68, 0x1E
; [nakarest] NakaInst_Fusion_Tines_98_ECA044  +0x12e86..+0x12f0e (0xeca044, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Fusion
; [nakarest] Tines 98"; "Cool Groove Sax 98"; "Sample Piano 98"; "West Coast Flute 98".
NakaInst_Fusion_Tines_98_ECA044:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12E86, 0x88
; [nakarest] StyleVar_MusicalOverture  +0x12f0e..+0x12f4e (0xeca0cc, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Grand Finale 132".
StyleVar_MusicalOverture:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12F0E, 0x40
; [nakarest] NakaInst_In_The_Limelight_132  +0x12f4e..+0x12fb4 (0xeca10c, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "In The
; [nakarest] Limelight 132"; "Show Stopper 132"; "Greasepaint Time 132".
NakaInst_In_The_Limelight_132:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12F4E, 0x66
; [nakarest] StyleVar_Tinseltown  +0x12fb4..+0x13016 (0xeca172, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Golden Movie Era 120"; "Cinema Magic 120".
StyleVar_Tinseltown:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12FB4, 0x62
; [nakarest] NakaInst_Fred_Ginger_120  +0x13016..+0x1305a (0xeca1d4, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Fred &
; [nakarest] Ginger 120"; "Gene's Dance 120".
NakaInst_Fred_Ginger_120:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13016, 0x44
; [nakarest] StyleVar_Showband  +0x1305a..+0x130de (0xeca218, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Theatre Band 135"; "Variety Reeds 135"; "Curtain Up!
; [nakarest] 135".
StyleVar_Showband:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1305A, 0x84
; [nakarest] NakaInst_Mallets_On_Stage_135  +0x130de..+0x13100 (0xeca29c, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Mallets
; [nakarest] On Stage 135".
NakaInst_Mallets_On_Stage_135:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x130DE, 0x22
; [nakarest] StyleVar_TheatreStride  +0x13100..+0x1311e (0xeca2be, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_TheatreStride:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13100, 0x1E
; [nakarest] NakaInst_Vaudeville_Bones_124  +0x1311e..+0x131a6 (0xeca2dc, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Vaudeville Bones 124"; "Tap Dance Mutes 124"; "Old Time Saloon 124"; "Simple
; [nakarest] Stride 124".
NakaInst_Vaudeville_Bones_124:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1311E, 0x88
; [nakarest] StyleVar_VaudevilleAct  +0x131a6..+0x131e6 (0xeca364, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Novelty Number 165".
StyleVar_VaudevilleAct:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x131A6, 0x40
; [nakarest] NakaInst_Skeleton_Dance_165  +0x131e6..+0x1324c (0xeca3a4, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Skeleton Dance 165"; "Variety Showband 165"; "Music Hall Piano 165".
NakaInst_Skeleton_Dance_165:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x131E6, 0x66
; [nakarest] StyleVar_TapDancer  +0x1324c..+0x132ae (0xeca40a, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Slapstick Show 182"; "Soft Da-Dance 182".
StyleVar_TapDancer:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1324C, 0x62
; [nakarest] NakaInst_Yankee_Doodle_It_182  +0x132ae..+0x132f2 (0xeca46c, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Yankee
; [nakarest] Doodle It 182"; "Sweet Georgia 182".
NakaInst_Yankee_Doodle_It_182:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x132AE, 0x44
; [nakarest] StyleVar_ParisClub  +0x132f2..+0x13376 (0xeca4b0, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Crazy Horse Show 118"; "Girls On Stage! 118"; "Musette
; [nakarest] Rouge 118".
StyleVar_ParisClub:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x132F2, 0x84
; [nakarest] NakaInst_Take_Your_Seat_118  +0x13376..+0x13398 (0xeca534, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Take
; [nakarest] Your Seat! 118".
NakaInst_Take_Your_Seat_118:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13376, 0x22
; [nakarest] StyleVar_CabaretBand  +0x13398..+0x133b6 (0xeca556, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_CabaretBand:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13398, 0x1E
; [nakarest] NakaInst_Midnight_Soloist_162  +0x133b6..+0x1343e (0xeca574, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Midnight Soloist 162"; "Cabaret Organ 162"; "Warm Up Act 162"; "Guitar Cocktail
; [nakarest] 162".
NakaInst_Midnight_Soloist_162:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x133B6, 0x88
; [nakarest] StyleVar_VivaLasVegas  +0x1343e..+0x1347e (0xeca5fc, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Lee's Finale 75".
StyleVar_VivaLasVegas:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1343E, 0x40
; [nakarest] NakaInst_Vegas_Showman_75  +0x1347e..+0x134e4 (0xeca63c, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Vegas
; [nakarest] Showman 75"; "Casino Sax 75"; "Candlelight Reed 75".
NakaInst_Vegas_Showman_75:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1347E, 0x66
; [nakarest] StyleVar_MagicBallroom  +0x134e4..+0x13546 (0xeca6a2, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Max's Orchestra 120"; "Greger Saxes 120".
StyleVar_MagicBallroom:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x134E4, 0x62
; [nakarest] NakaInst_Strasser_More_120  +0x13546..+0x1358a (0xeca704, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Strasser & More 120"; "Hugo's Revival 120".
NakaInst_Strasser_More_120:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13546, 0x44
; [nakarest] StyleVar_GentleFoxtrot  +0x1358a..+0x1360e (0xeca748, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Foxtrot Serenade 154"; "Foxy Reeds 154"; "Euro Ballroom
; [nakarest] 154".
StyleVar_GentleFoxtrot:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1358A, 0x84
; [nakarest] NakaInst_Foxy_Squeezebox_154_ECA7CC  +0x1360e..+0x13630 (0xeca7cc, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Foxy
; [nakarest] Squeezebox 154".
NakaInst_Foxy_Squeezebox_154_ECA7CC:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1360E, 0x22
; [nakarest] StyleVar_OrganistsDance  +0x13630..+0x1364e (0xeca7ee, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_OrganistsDance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13630, 0x1E
; [nakarest] NakaInst_Old_Wheels_Dance_190  +0x1364e..+0x136d6 (0xeca80c, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Old
; [nakarest] Wheels Dance 190"; "Mr.Wunderbar 190"; "Ham & T Dance 190"; "Harmonic Foxtrot 190".
NakaInst_Old_Wheels_Dance_190:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1364E, 0x88
; [nakarest] StyleVar_UpTempoFoxtrot  +0x136d6..+0x13716 (0xeca894, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Unison Fox Band 170".
StyleVar_UpTempoFoxtrot:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x136D6, 0x40
; [nakarest] NakaInst_Foxy_Brassy_170  +0x13716..+0x1377c (0xeca8d4, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Foxy &
; [nakarest] Brassy 170"; "Fox Accordingly 170"; "Quick Fox Keys 170".
NakaInst_Foxy_Brassy_170:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13716, 0x66
; [nakarest] StyleVar_StrictlyFoxtrot  +0x1377c..+0x137de (0xeca93a, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Ballroom Bars 120"; "Foxtrot Sparkle 120".
StyleVar_StrictlyFoxtrot:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1377C, 0x62
; [nakarest] NakaInst_Come_Dancing_120  +0x137de..+0x13822 (0xeca99c, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Come
; [nakarest] Dancing! 120"; "Foxy Combo 120".
NakaInst_Come_Dancing_120:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x137DE, 0x44
; [nakarest] StyleVar_RadioFoxtrot  +0x13822..+0x138a6 (0xeca9e0, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Radio Orchestra 168"; "Box Standards 168"; "Foxtrot
; [nakarest] Partners 168".
StyleVar_RadioFoxtrot:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13822, 0x84
; [nakarest] NakaInst_Wunder_Fox_168  +0x138a6..+0x138c8 (0xecaa64, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Wunder-Fox 168".
NakaInst_Wunder_Fox_168:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x138A6, 0x22
; [nakarest] StyleVar_StrictlyQuick  +0x138c8..+0x138e6 (0xecaa86, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_StrictlyQuick:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x138C8, 0x1E
; [nakarest] NakaInst_Organ_Quickstep_200  +0x138e6..+0x1396e (0xecaaa4, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Organ
; [nakarest] Quickstep 200"; "Holiday Dance 200"; "No Twirling! 200"; "Doo You Dance? 200".
NakaInst_Organ_Quickstep_200:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x138E6, 0x88
; [nakarest] StyleVar_LetsTwist  +0x1396e..+0x139ae (0xecab2c, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Chubby's Best 168".
StyleVar_LetsTwist:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1396E, 0x40
; [nakarest] NakaInst_Solid_Twist_168  +0x139ae..+0x13a14 (0xecab6c, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Solid
; [nakarest] Twist 168"; "Come On,Baby 168"; "Do The Twist 168".
NakaInst_Solid_Twist_168:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x139AE, 0x66
; [nakarest] StyleVar_JiveDance  +0x13a14..+0x13a76 (0xecabd2, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Top Brass Jive 176"; "Jive Reeds 176".
StyleVar_JiveDance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13A14, 0x62
; [nakarest] NakaInst_Dance_Band_Jive_176_ECAC34  +0x13a76..+0x13aba (0xecac34, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Dance
; [nakarest] Band Jive 176"; "Jive Ivories 176".
NakaInst_Dance_Band_Jive_176_ECAC34:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13A76, 0x44
; [nakarest] StyleVar_DoTheTwist  +0x13aba..+0x13b3e (0xecac78, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Twisting Guitars 155"; "Shakin' Saxes 155"; "Chubby's
; [nakarest] Octaves 155".
StyleVar_DoTheTwist:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13ABA, 0x84
; [nakarest] NakaInst_Bari_Twist_155  +0x13b3e..+0x13b60 (0xecacfc, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Bari-Twist 155".
NakaInst_Bari_Twist_155:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13B3E, 0x22
; [nakarest] StyleVar_12ChaChaCha  +0x13b60..+0x13b7e (0xecad1e, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_12ChaChaCha:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13B60, 0x1E
; [nakarest] NakaInst_Sequin_Dance_128  +0x13b7e..+0x13c06 (0xecad3c, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Sequin
; [nakarest] Dance 128"; "Brass For Two 128"; "Cha Cha Band 128"; "Latin Ballroom 128".
NakaInst_Sequin_Dance_128:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13B7E, 0x88
; [nakarest] StyleVar_LetsBeguine  +0x13c06..+0x13c46 (0xecadc4, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Latin Elegance 118".
StyleVar_LetsBeguine:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13C06, 0x40
; [nakarest] NakaInst_Beguine_Romance_118  +0x13c46..+0x13cac (0xecae04, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Beguine Romance 118"; "When They Begin? 118"; "Siesta Beguine 118".
NakaInst_Beguine_Romance_118:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13C46, 0x66
; [nakarest] StyleVar_SambaFelicidade  +0x13cac..+0x13d0e (0xecae6a, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Ogerman-Unisono 115"; "Wanderley Samba 115".
StyleVar_SambaFelicidade:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13CAC, 0x62
; [nakarest] NakaInst_Samba_Testamento_115  +0x13d0e..+0x13d52 (0xecaecc, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Samba
; [nakarest] Testamento 115"; "Organ De Janeiro 115".
NakaInst_Samba_Testamento_115:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13D0E, 0x44
; [nakarest] StyleVar_VivaPasodoble  +0x13d52..+0x13dd6 (0xecaf10, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Brassodoble 118"; "Sunny Spain Mood 118"; "Flamenco
; [nakarest] Dancers 118".
StyleVar_VivaPasodoble:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13D52, 0x84
; [nakarest] NakaInst_Espana_Two_Step_118  +0x13dd6..+0x13df8 (0xecaf94, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Espana
; [nakarest] Two Step 118".
NakaInst_Espana_Two_Step_118:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13DD6, 0x22
; [nakarest] StyleVar_StrictTango  +0x13df8..+0x13e16 (0xecafb6, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_StrictTango:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13DF8, 0x1E
; [nakarest] NakaInst_Tango_Marcato_120  +0x13e16..+0x13e9e (0xecafd4, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Tango
; [nakarest] Marcato 120"; "Spanish Moments 120"; "Octave Tango 120"; "Grand Tango 120".
NakaInst_Tango_Marcato_120:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13E16, 0x88
; [nakarest] StyleVar_TangoDAmour  +0x13e9e..+0x13fea (0xecb05c, 332 B)
; [nakarest] variation tables of 2 styles: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Tango Orchestra 130"; "Lush Tango 130"; "Holiday Tango
; [nakarest] 130"; "Italian Tango 130"; ....
StyleVar_TangoDAmour:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13E9E, 0x40
SoundName_LushTango:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13EDE, 0x66
StyleVar_TangoPianist:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13F44, 0x62
SoundName_AstorsTango:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13FA6, 0x44
; [nakarest] StyleVar_LastDanceWaltz  +0x13fea..+0x1406e (0xecb1a8, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Come Waltzing 96"; "Organist's Waltz 96"; "Orchestra
; [nakarest] Waltz 96".
StyleVar_LastDanceWaltz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13FEA, 0x84
; [nakarest] NakaInst_Concertina_Waltz_96  +0x1406e..+0x14090 (0xecb22c, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Concertina Waltz 96".
NakaInst_Concertina_Waltz_96:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1406E, 0x22
; [nakarest] StyleVar_QuickWaltz  +0x14090..+0x14282 (0xecb24e, 498 B)
; [nakarest] variation tables of 3 styles: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Symphonic Waltz 130"; "Jazz Flute Gtr 130"; "Waltzing
; [nakarest] Flugel 130"; "3/4 Romance 130"; ....
StyleVar_QuickWaltz:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x14090, 0x1E
SoundName_SymphonicWaltz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x140AE, 0x88
StyleSound_QuickWaltz_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14136, 0x40
SoundName_NotStrauss:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x14176, 0x66
StyleVar_WalzerTime:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x141DC, 0x62
SoundName_BavarianFlutes:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1423E, 0x44
; [nakarest] StyleVar_PartyVienna  +0x14282..+0x14306 (0xecb440, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Vienna Finale 171"; "Vienna Strings 171"; "Ballroom Keys
; [nakarest] 171".
StyleVar_PartyVienna:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14282, 0x84
; [nakarest] NakaInst_Ball_Gown_Waltz_171  +0x14306..+0x14346 (0xecb4c4, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Ball
; [nakarest] Gown Waltz 171". variation table of 1 style: {u32 title, u16 id} x n + an all-zero
; [nakarest] entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from
; [nakarest] 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Ball_Gown_Waltz_171:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14306, 0x22
StyleVar_StadiumEvents:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x14328, 0x1E
; [nakarest] NakaInst_Full_Brass_Band_115_ECB504  +0x14346..+0x1440e (0xecb504, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Full
; [nakarest] Brass Band 115"; "Marching Sax 115"; "Highschool Band 115"; "Fife & Drums 115";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Full_Brass_Band_115_ECB504:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14346, 0x88
StyleVar_SousaMarches:			.incbin "includes/generated/naka_style_bitmaps.bin", 0x143CE, 0x40
; [nakarest] NakaInst_Alto_Marchpast_115  +0x1440e..+0x144d6 (0xecb5cc, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Alto
; [nakarest] Marchpast 115"; "By The Left 115"; "Liberty March 115"; "Festive March 109"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Alto_Marchpast_115:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1440E, 0x66
StyleVar_GermanTradition:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14474, 0x62
; [nakarest] NakaInst_OktoberFest_109  +0x144d6..+0x1459e (0xecb694, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "OktoberFest 109"; "Munich Horns 109"; "Moik's Marchshow 120"; "Ernst & Friends
; [nakarest] 120"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_OktoberFest_109:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x144D6, 0x44
StyleVar_Musikantenstadl:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1451A, 0x84
; [nakarest] NakaInst_At_The_Eger_120_ECB75C  +0x1459e..+0x145de (0xecb75c, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "At The
; [nakarest] Eger 120". variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_At_The_Eger_120_ECB75C:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1459E, 0x22
StyleVar_StandardPolka:			.incbin "includes/generated/naka_style_bitmaps.bin", 0x145C0, 0x1E
; [nakarest] NakaInst_Marching_Polka_124  +0x145de..+0x146a6 (0xecb79c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Marching Polka 124"; "Lederhosen Dance 124"; "Folk Polka 124"; "Polka Partners
; [nakarest] 124"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Marching_Polka_124:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x145DE, 0x88
StyleVar_ModernPolka:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x14666, 0x40
; [nakarest] NakaInst_Wedding_Party_135  +0x146a6..+0x1476e (0xecb864, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Wedding Party 135"; "Bellow Shake Hit 135"; "Alpine Accordion 135"; "Harmonic
; [nakarest] Tirol 125"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero
; [nakarest] entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from
; [nakarest] 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Wedding_Party_135:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x146A6, 0x66
StyleVar_GermanPolka:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1470C, 0x62
; [nakarest] NakaInst_Alpine_Combo_125_ECB92C  +0x1476e..+0x14836 (0xecb92c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Alpine
; [nakarest] Combo 125"; "German Clarinet 125"; "Eire Squeezebox 120"; "Chieftain's Jig 120";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Alpine_Combo_125_ECB92C:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1476E, 0x44
StyleVar_CeilidhBand:			.incbin "includes/generated/naka_style_bitmaps.bin", 0x147B2, 0x84
; [nakarest] NakaInst_Emerald_Flute_120  +0x14836..+0x14876 (0xecb9f4, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Emerald
; [nakarest] Flute 120". variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Emerald_Flute_120:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14836, 0x22
StyleVar_HighlandDance:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x14858, 0x1E
; [nakarest] NakaInst_Scottish_Band_172  +0x14876..+0x1493e (0xecba34, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Scottish Band 172"; "Bonnie Whistles 172"; "Caber Dance! 172"; "Jimmy's Reel 172";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Scottish_Band_172:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14876, 0x88
StyleVar_34ConcertTime:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x148FE, 0x40
; [nakarest] NakaInst_Waltzing_Concert_169  +0x1493e..+0x14a06 (0xecbafc, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Waltzing Concert 169"; "Strauss & Co 169"; "Vienna Woods 169"; "Ski Lodge Waltz
; [nakarest] 197"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Waltzing_Concert_169:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1493E, 0x66
StyleVar_MunichWaltz:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x149A4, 0x62
; [nakarest] NakaInst_Matterhorn_Waltz_197  +0x14a06..+0x14ace (0xecbbc4, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Matterhorn Waltz 197"; "Alpine Guitar 197"; "Dance The Mazurka 150"; "Folk Waltz
; [nakarest] 150"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Matterhorn_Waltz_197:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14A06, 0x44
StyleVar_EastEuroWaltz:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x14A4A, 0x84
; [nakarest] NakaInst_Mazurka_Clarinet_150  +0x14ace..+0x14b0e (0xecbc8c, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Mazurka
; [nakarest] Clarinet 150". variation table of 1 style: {u32 title, u16 id} x n + an all-zero
; [nakarest] entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from
; [nakarest] 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Mazurka_Clarinet_150:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14ACE, 0x22
StyleVar_GermanWaltz:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x14AF0, 0x1E
; [nakarest] NakaInst_Tiroler_Harp_190  +0x14b0e..+0x14bd6 (0xecbccc, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Tiroler Harp 190"; "Bandoneon Waltz 190"; "Waltzer Band 190"; "Klarinette Waltz
; [nakarest] 190"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Tiroler_Harp_190:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14B0E, 0x88
StyleVar_IslandRomance:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x14B96, 0x40
; [nakarest] NakaInst_Waikiki_Voices_101  +0x14bd6..+0x14c9e (0xecbd94, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Waikiki Voices 101"; "Island Delight 101"; "Island Flute 101"; "Honolulu Strings
; [nakarest] 130"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Waikiki_Voices_101:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14BD6, 0x66
StyleVar_HawaiianDance:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x14C3C, 0x62
; [nakarest] NakaInst_Hula_Dance_130  +0x14c9e..+0x14d66 (0xecbe5c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Hula
; [nakarest] Dance 130"; "Island Whistle 130"; "Entertaining Rag 130"; "Play The Sting! 130";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Hula_Dance_130:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14C9E, 0x44
StyleVar_OldRagtime:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x14CE2, 0x84
; [nakarest] NakaInst_Syncopated_Wood_130  +0x14d66..+0x14da6 (0xecbf24, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Syncopated Wood 130". variation table of 1 style: {u32 title, u16 id} x n + an
; [nakarest] all-zero entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a
; [nakarest] time from 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Syncopated_Wood_130:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14D66, 0x22
StyleVar_RagtimeBand:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x14D88, 0x1E
; [nakarest] NakaInst_Maple_Leaf_Piano_180  +0x14da6..+0x14e6e (0xecbf64, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Maple
; [nakarest] Leaf Piano 180"; "Ragtime Duet 180"; "Ragedy Sax 180"; "Banjo Ragtime 180"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Maple_Leaf_Piano_180:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14DA6, 0x88
StyleVar_NewOrleansJazz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14E2E, 0x40
; [nakarest] NakaInst_Barber_Shop_Jazz_196_ECC02C  +0x14e6e..+0x14f36 (0xecc02c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Barber
; [nakarest] Shop Jazz 196"; "Bourbon Street 196"; "Trad Jazz Band 196"; "Alexander's Band 185";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Barber_Shop_Jazz_196_ECC02C:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14E6E, 0x66
StyleVar_SoundsOfDixie:			.incbin "includes/generated/naka_style_bitmaps.bin", 0x14ED4, 0x62
; [nakarest] NakaInst_Liquorice_Dixie_185  +0x14f36..+0x14ffe (0xecc0f4, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Liquorice Dixie 185"; "Dixie Bone 185"; "Bouzouki Masters 120"; "Zorba's Band
; [nakarest] 120"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Liquorice_Dixie_185:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14F36, 0x44
StyleVar_GreekDance:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x14F7A, 0x84
; [nakarest] NakaInst_Never_On_A_120  +0x14ffe..+0x1503e (0xecc1bc, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Never
; [nakarest] On A? 120". variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Never_On_A_120:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14FFE, 0x22
StyleVar_MoscowAtNight:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x15020, 0x1E
; [nakarest] NakaInst_Cossack_Strings_141  +0x1503e..+0x15106 (0xecc1fc, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Cossack Strings 141"; "Baltic Reeds 141"; "Moscow Mandolins 141"; "Vladivar
; [nakarest] Strings 141"; .... variation table of 1 style: {u32 title, u16 id} x n + an
; [nakarest] all-zero entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a
; [nakarest] time from 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Cossack_Strings_141:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1503E, 0x88
StyleVar_KingsOfGypsy:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x150C6, 0x40
; [nakarest] NakaInst_Hungarian_Duet_115  +0x15106..+0x151ce (0xecc2c4, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Hungarian Duet 115"; "Gypsy Melody 115"; "Goulash Dance 115"; "Great Accordions
; [nakarest] 128"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Hungarian_Duet_115:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15106, 0x66
StyleVar_SpanishFolklore:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1516C, 0x62
; [nakarest] NakaInst_Spider_Dance_128  +0x151ce..+0x15296 (0xecc38c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Spider
; [nakarest] Dance 128"; "Ole Guitar 128"; "Tex Mex Mix 112"; "Cucaracha Duo 112"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Spider_Dance_128:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x151CE, 0x44
StyleVar_MariachiBand:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x15212, 0x84
; [nakarest] NakaInst_Jalapeno_Bellows_112  +0x15296..+0x152d6 (0xecc454, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Jalapeno Bellows 112". variation table of 1 style: {u32 title, u16 id} x n + an
; [nakarest] all-zero entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a
; [nakarest] time from 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Jalapeno_Bellows_112:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15296, 0x22
StyleVar_70sFolkMusic:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x152B8, 0x1E
; [nakarest] NakaInst_Solid_Distortion_122  +0x152d6..+0x1535e (0xecc494, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Solid
; [nakarest] Distortion 122"; "Penny Folk Song 122"; "Steeleye Guitar 122"; "Folk Fiddles 122".
NakaInst_Solid_Distortion_122:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x152D6, 0x88
; [nakarest] StyleVar_BluegrassTime  +0x1535e..+0x1539e (0xecc51c, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Don't Fiddle It! 124".
StyleVar_BluegrassTime:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1535E, 0x40
; [nakarest] NakaInst_Cajun_Hoedown_124  +0x1539e..+0x15404 (0xecc55c, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Cajun
; [nakarest] Hoedown 124"; "Pedal Steel Duel 124"; "Bluegrass Harp 124".
NakaInst_Cajun_Hoedown_124:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1539E, 0x66
; [nakarest] StyleVar_ModernHoedown  +0x15404..+0x15466 (0xecc5c2, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Yee Ha Fiddles 235"; "Hard Country Sax 235".
StyleVar_ModernHoedown:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15404, 0x62
; [nakarest] NakaInst_Country_Licks_235_ECC624  +0x15466..+0x154aa (0xecc624, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Country Licks 235"; "Bluegrass Piano 235".
NakaInst_Country_Licks_235_ECC624:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15466, 0x44
; [nakarest] StyleVar_KentuckyBlue  +0x154aa..+0x1552e (0xecc668, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Hoedown Strings 123"; "Solid Bluegrass 123"; "Banjo
; [nakarest] Contest 123".
StyleVar_KentuckyBlue:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x154AA, 0x84
; [nakarest] NakaInst_Country_Fiddle_123  +0x1552e..+0x15550 (0xecc6ec, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Country
; [nakarest] Fiddle 123".
NakaInst_Country_Fiddle_123:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1552E, 0x22
; [nakarest] StyleVar_TruckerCountry  +0x15550..+0x1556e (0xecc70e, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_TruckerCountry:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15550, 0x1E
; [nakarest] NakaInst_Fogerty_s_Stomp_206_ECC72C  +0x1556e..+0x155f6 (0xecc72c, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Fogerty's Stomp 206"; "On The Highway 206"; "Convoy Bluegrass 206"; "Trucker's
; [nakarest] Stop 206".
NakaInst_Fogerty_s_Stomp_206_ECC72C:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1556E, 0x88
; [nakarest] StyleVar_CountryDance  +0x155f6..+0x15636 (0xecc7b4, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Barn Dance Band 147".
StyleVar_CountryDance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x155F6, 0x40
; [nakarest] NakaInst_Nashville_Dance_147  +0x15636..+0x1569c (0xecc7f4, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Nashville Dance 147"; "Two Step Duo 147"; "Yee Ha Geetar 147".
NakaInst_Nashville_Dance_147:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15636, 0x66
; [nakarest] StyleVar_HillbillyBlues  +0x1569c..+0x156fe (0xecc85a, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Southern Unison 128"; "Country Ivories 128".
StyleVar_HillbillyBlues:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1569C, 0x62
; [nakarest] NakaInst_Steel_City_Blues_128  +0x156fe..+0x15742 (0xecc8bc, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Steel
; [nakarest] City Blues 128"; "Blue Harmonies 128".
NakaInst_Steel_City_Blues_128:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x156FE, 0x44
; [nakarest] StyleVar_70sCountryPop  +0x15742..+0x157c6 (0xecc900, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Roads to Country 173"; "EZ Steel Country 173";
; [nakarest] "Carpenkeys 173".
StyleVar_70sCountryPop:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15742, 0x84
; [nakarest] NakaInst_Karen_s_Country_173  +0x157c6..+0x157e8 (0xecc984, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Karen's
; [nakarest] Country 173".
NakaInst_Karen_s_Country_173:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x157C6, 0x22
; [nakarest] StyleVar_CountryRomance  +0x157e8..+0x15806 (0xecc9a6, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_CountryRomance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x157E8, 0x1E
; [nakarest] NakaInst_Kentucky_Vocals_88  +0x15806..+0x1588e (0xecc9c4, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Kentucky Vocals 88"; "Nashville Ballad 88"; "Country Harp 88"; "Country Tenor 88".
NakaInst_Kentucky_Vocals_88:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15806, 0x88
; [nakarest] StyleVar_WesternBallads  +0x1588e..+0x158ce (0xecca4c, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Chet's Country 85".
StyleVar_WesternBallads:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1588E, 0x40
; [nakarest] NakaInst_Cowboy_Saxes_85  +0x158ce..+0x15934 (0xecca8c, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Cowboy
; [nakarest] Saxes 85"; "Blueberry Saxes 85"; "Kramer Country 85".
NakaInst_Cowboy_Saxes_85:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x158CE, 0x66
; [nakarest] StyleVar_CountryFolks  +0x15934..+0x15996 (0xeccaf2, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "In Daa Country 170"; "Country Radio 170".
StyleVar_CountryFolks:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15934, 0x62
; [nakarest] NakaInst_South_Concertina_170  +0x15996..+0x159da (0xeccb54, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "South
; [nakarest] Concertina 170"; "Southern Style 170".
NakaInst_South_Concertina_170:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15996, 0x44
; [nakarest] StyleVar_Country88  +0x159da..+0x15a5e (0xeccb98, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Rodeo Organ 75"; "Horseback Duo 75"; "Country Blues 75".
StyleVar_Country88:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x159DA, 0x84
; [nakarest] NakaInst_Wandrin_Keys_75  +0x15a5e..+0x15a80 (0xeccc1c, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Wandrin' Keys 75".
NakaInst_Wandrin_Keys_75:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15A5E, 0x22
; [nakarest] StyleVar_CountryLove  +0x15a80..+0x15a9e (0xeccc3e, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_CountryLove:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15A80, 0x1E
; [nakarest] NakaInst_Tennessee_Guitar_88  +0x15a9e..+0x15b26 (0xeccc5c, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Tennessee Guitar 88"; "Mellow Country 88"; "Country Keys 88"; "Harmonica Waltz
; [nakarest] 88".
NakaInst_Tennessee_Guitar_88:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15A9E, 0x88
; [nakarest] StyleVar_ModernCountry  +0x15b26..+0x15b66 (0xeccce4, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Country Rock 116".
StyleVar_ModernCountry:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15B26, 0x40
; [nakarest] NakaInst_Nashville_Steel_116  +0x15b66..+0x15bcc (0xeccd24, 102 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Nashville Steel 116"; "Duelling Guitars 116"; "Fiddle Rock 116".
NakaInst_Nashville_Steel_116:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15B66, 0x66
; [nakarest] StyleVar_EZCountryRock  +0x15bcc..+0x15c2e (0xeccd8a, 98 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Ranch Rock 128"; "Dolly's Strings 128".
StyleVar_EZCountryRock:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15BCC, 0x62
; [nakarest] NakaInst_Ricky_s_Guitar_128  +0x15c2e..+0x15c72 (0xeccdec, 68 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Ricky's Guitar 128"; "Cowboy Suite 128".
NakaInst_Ricky_s_Guitar_128:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15C2E, 0x44
; [nakarest] StyleVar_OldCountryHits  +0x15c72..+0x15cf6 (0xecce30, 132 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation titles (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Steel & Strings 113"; "Country Warmth 113"; "Let It
; [nakarest] Shine! 113".
StyleVar_OldCountryHits:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15C72, 0x84
; [nakarest] NakaInst_Geetar_Man_113  +0x15cf6..+0x15d18 (0xecceb4, 34 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Geetar
; [nakarest] Man 113".
NakaInst_Geetar_Man_113:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15CF6, 0x22
; [nakarest] StyleVar_NewCountryRock  +0x15d18..+0x15d36 (0xecced6, 30 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
StyleVar_NewCountryRock:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15D18, 0x1E
; [nakarest] NakaInst_Country_Horns_115  +0x15d36..+0x15dbe (0xeccef4, 136 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Country Horns 115"; "In Sax Country 115"; "Rockin' Country 115"; "Tennessee Rock
; [nakarest] 115".
NakaInst_Country_Horns_115:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15D36, 0x88
; [nakarest] StyleVar_CountryHits  +0x15dbe..+0x15dfe (0xeccf7c, 64 B)
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops. variation title (32 characters + NUL + 0xff, the
; [nakarest] StyleSong_Titles layout): "Muted Country 160".
StyleVar_CountryHits:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15DBE, 0x40
; [nakarest] NakaInst_Hard_Country_160  +0x15dfe..+0x15ec6 (0xeccfbc, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Hard
; [nakarest] Country 160"; "Clean Country 160"; "Western Keys 160"; "Jobim Strings 66"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Hard_Country_160:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15DFE, 0x66
StyleVar_RomanticBossa:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x15E64, 0x62
; [nakarest] NakaInst_Ham_Bossa_66  +0x15ec6..+0x15f8e (0xecd084, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Ham &
; [nakarest] Bossa 66"; "Siesta Guitars 66"; "Bossa Society 68"; "Getz Bossa 68"; .... variation
; [nakarest] table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record shape of
; [nakarest] StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the MstStyle2_*
; [nakarest] count loops.
NakaInst_Ham_Bossa_66:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15EC6, 0x44
StyleVar_BossaPianist:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15F0A, 0x84
; [nakarest] NakaInst_Latin_Tines_68  +0x15f8e..+0x15fce (0xecd14c, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Latin
; [nakarest] Tines 68". variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Latin_Tines_68:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15F8E, 0x22
StyleVar_MellowBossa:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x15FB0, 0x1E
; [nakarest] NakaInst_Modern_Bossa_74  +0x15fce..+0x16096 (0xecd18c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Modern
; [nakarest] Bossa 74"; "Bossa Duet 74"; "Meditating Sax 74"; "Ipenema Flute 74"; .... variation
; [nakarest] table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record shape of
; [nakarest] StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the MstStyle2_*
; [nakarest] count loops.
NakaInst_Modern_Bossa_74:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15FCE, 0x88
StyleVar_RhumbaEspana:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16056, 0x40
; [nakarest] NakaInst_Julio_s_Romance_119  +0x16096..+0x1615e (0xecd254, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Julio's Romance 119"; "Carmen's Octaves 119"; "Mellow Rhumba 119"; "Elegant Keys
; [nakarest] 120"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Julio_s_Romance_119:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16096, 0x66
StyleVar_CocktailPianist:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x160FC, 0x62
; [nakarest] NakaInst_Besame_Strings_120_ECD31C  +0x1615e..+0x16226 (0xecd31c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Besame
; [nakarest] Strings 120"; "Mediterranean! 120"; "Beguine Register 117"; "Besame Unison 117";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Besame_Strings_120_ECD31C:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1615E, 0x44
StyleVar_RomanticBeguine:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x161A2, 0x84
; [nakarest] NakaInst_Amor_Reed_117_ECD3E4  +0x16226..+0x16266 (0xecd3e4, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Amor
; [nakarest] Reed 117". variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Amor_Reed_117_ECD3E4:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16226, 0x22
StyleVar_RomanticDance:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16248, 0x1E
; [nakarest] NakaInst_Bolero_Orchestra_120_ECD424  +0x16266..+0x1632e (0xecd424, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Bolero
; [nakarest] Orchestra 120"; "Latin Love Song 120"; "Bolero Keys 120"; "Not Ravel's..... 120";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Bolero_Orchestra_120_ECD424:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16266, 0x88
StyleVar_LatinLoungeBar:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x162EE, 0x40
; [nakarest] NakaInst_Holiday_Rhumba_115  +0x1632e..+0x163f6 (0xecd4ec, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Holiday Rhumba 115"; "Fantasy Rhumba 115"; "Spanish Romance 115"; "Puente's
; [nakarest] Bigband 130"; .... variation table of 1 style: {u32 title, u16 id} x n + an
; [nakarest] all-zero entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a
; [nakarest] time from 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Holiday_Rhumba_115:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1632E, 0x66
StyleVar_TitosChaCha:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16394, 0x62
; [nakarest] NakaInst_Pepito_For_Pepe_130  +0x163f6..+0x164be (0xecd5b4, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Pepito
; [nakarest] For Pepe 130"; "Two Cups Of Cha! 130"; "Last Latin Brass 129"; "Ambros Saxes 129";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_Pepito_For_Pepe_130:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x163F6, 0x44
StyleVar_MamboBand:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1643A, 0x84
; [nakarest] NakaInst_Mambo_Bravisimo_129  +0x164be..+0x164fe (0xecd67c, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Mambo
; [nakarest] Bravisimo 129". variation table of 1 style: {u32 title, u16 id} x n + an all-zero
; [nakarest] entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from
; [nakarest] 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Mambo_Bravisimo_129:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x164BE, 0x22
StyleVar_NewMamboMood:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x164E0, 0x1E
; [nakarest] NakaInst_Modern_Ballroom_134  +0x164fe..+0x165c6 (0xecd6bc, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Modern
; [nakarest] Ballroom 134"; "Mambo Mania! 134"; "Do The Mambo! 134"; "Sax Mamboist 134"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Modern_Ballroom_134:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x164FE, 0x88
StyleVar_ItsMamboTime:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16586, 0x40
; [nakarest] NakaInst_Saxy_Mambo_132  +0x165c6..+0x1668e (0xecd784, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Saxy
; [nakarest] Mambo 132"; "Mambo Jambo! 132"; "Seville Octaves 132"; "Fall For Cumbia 90"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Saxy_Mambo_132:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x165C6, 0x66
StyleVar_CumbiaBand:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1662C, 0x62
; [nakarest] NakaInst_Cumbia_Sol_90  +0x1668e..+0x16756 (0xecd84c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Cumbia
; [nakarest] Sol 90"; "Sunshine Alto 90"; "Jamaican Voices 83"; "Island Duet 83"; .... variation
; [nakarest] table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record shape of
; [nakarest] StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the MstStyle2_*
; [nakarest] count loops.
NakaInst_Cumbia_Sol_90:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1668E, 0x44
StyleVar_HolidayMood:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x166D2, 0x84
; [nakarest] NakaInst_Caribbean_Flute_83  +0x16756..+0x16796 (0xecd914, 64 B)
; [nakarest] variation title (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Caribbean Flute 83". variation table of 1 style: {u32 title, u16 id} x n + an
; [nakarest] all-zero entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a
; [nakarest] time from 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Caribbean_Flute_83:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16756, 0x22
StyleVar_SambaParade:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16778, 0x1E
; [nakarest] NakaInst_Brazil_Fanfare_114  +0x16796..+0x1685e (0xecd954, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "Brazil
; [nakarest] Fanfare 114"; "Samba Soloist 114"; "Festival Horns 114"; "Rio De Samba 114"; ....
; [nakarest] variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the record
; [nakarest] shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by the
; [nakarest] MstStyle2_* count loops.
NakaInst_Brazil_Fanfare_114:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16796, 0x88
StyleVar_LatinFestival_2:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1681E, 0x40
; [nakarest] NakaInst_Sunshine_Sax_120  +0x1685e..+0x16926 (0xecda1c, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Sunshine Sax 120"; "Merengue Party 120"; "Time To Merengue 120"; "Tropical Bridge
; [nakarest] 108"; .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry
; [nakarest] (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6
; [nakarest] by the MstStyle2_* count loops.
NakaInst_Sunshine_Sax_120:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1685E, 0x66
StyleVar_ModernRio:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x168C4, 0x62
; [nakarest] NakaInst_12_String_Samba_108  +0x16926..+0x169ee (0xecdae4, 200 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout): "12
; [nakarest] String Samba 108"; "Deep in Brazil 108"; "Toreador Band 125"; "Gitarero-Ole!! 125";
; [nakarest] .... variation table of 1 style: {u32 title, u16 id} x n + an all-zero entry (the
; [nakarest] record shape of StyleSong_MasterTable), walked 6 bytes at a time from 0x0340d6 by
; [nakarest] the MstStyle2_* count loops.
NakaInst_12_String_Samba_108:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16926, 0x44
StyleVar_CastanetDance:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1696A, 0x84
; [nakarest] NakaInst_Torero_s_Trumpet_125  +0x169ee..+0x17132 (0xecdbac, 1860 B)
; [nakarest] variation titles (32 characters + NUL + 0xff, the StyleSong_Titles layout):
; [nakarest] "Torero's Trumpet 125"; "Beach Party Song 152"; "Coconut Frets 152"; "Calypso Steel
; [nakarest] 152"; .... variation tables of 11 styles: {u32 title, u16 id} x n + an all-zero
; [nakarest] entry (the record shape of StyleSong_MasterTable), walked 6 bytes at a time from
; [nakarest] 0x0340d6 by the MstStyle2_* count loops.
NakaInst_Torero_s_Trumpet_125:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x169EE, 0x22
StyleVar_CaribbeanNights:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16A10, 0x1E
SoundName_BeachPartySong:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16A2E, 0x88
StyleVar_SalsaPicante:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16AB6, 0x40
SoundName_CubanReeds:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16AF6, 0x66
StyleVar_SambaAmor:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16B5C, 0x62
SoundName_LatinoPiccolo:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16BBE, 0x44
StyleVar_ModernCaribbean:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16C02, 0x84
SoundName_JamaicanBars:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16C86, 0x22
StyleVar_ModernSamba:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16CA8, 0x1E
SoundName_SambaUnion:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16CC6, 0x88
StyleVar_SambaFusion:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16D4E, 0x40
SoundName_NewOrganSamba:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16D8E, 0x66
StyleVar_IndonesianFolk:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16DF4, 0x62
SoundName_NiceKeroncong:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16E56, 0x44
StyleVar_Dangdut:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16E9A, 0x84
SoundName_EasyDangdut:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16F1E, 0x22
StyleVar_Talempong:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16F40, 0x1E
SoundName_PadangBeat:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16F5E, 0x88
StyleVar_SynthReggae:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x16FE6, 0x40
SoundName_RastaVoice:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17026, 0x66
StyleVar_JamaicanSwing:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1708C, 0x62
SoundName_MarleysDrums:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x170EE, 0x44
; [nakarest] StyleGroup_ModernDance_Table  +0x17132..+0x17232 (0xece2f0, 256 B)
; [nakarest] group table of the MstStyle browser, group 0: {u32 style name, u32 variation table}
; [nakarest] x n + an all-zero entry; MstStyle*_CountEntries walk it 8 bytes at a time until +0
; [nakarest] is 0, the grid routines Strcpy +0 and pad it to 16 with Strncat, and +4 goes to
; [nakarest] 0x0340d6.
StyleGroup_ModernDance_Table:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17132, 0x100
; [nakarest] NakaInst_Easy_Jazz_Waltz  +0x17232..+0x17244 (0xece3f0, 18 B)
; [nakarest] style name string (16 characters): "Easy Jazz Waltz".
NakaInst_Easy_Jazz_Waltz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17232, 0x12
; [nakarest] NakaInst_Parisian_Nights  +0x17244..+0x17256 (0xece402, 18 B)
; [nakarest] style name string (16 characters): "Parisian Nights".
NakaInst_Parisian_Nights:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17244, 0x12
; [nakarest] NakaInst_Easy_Play_Waltz  +0x17256..+0x17268 (0xece414, 18 B)
; [nakarest] style name string (16 characters): "Easy Play Waltz".
NakaInst_Easy_Play_Waltz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17256, 0x12
; [nakarest] NakaInst_Paris_Romance  +0x17268..+0x1727a (0xece426, 18 B)
; [nakarest] style name string (16 characters): "Paris Romance".
NakaInst_Paris_Romance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17268, 0x12
; [nakarest] NakaInst_Drawbar_Combo  +0x1727a..+0x1728c (0xece438, 18 B)
; [nakarest] style name string (16 characters): "Drawbar Combo".
NakaInst_Drawbar_Combo:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1727A, 0x12
; [nakarest] NakaInst_Nat_s_Ballads  +0x1728c..+0x1729e (0xece44a, 18 B)
; [nakarest] style name string (16 characters): "Nat's Ballads".
NakaInst_Nat_s_Ballads:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1728C, 0x12
; [nakarest] NakaInst_Jazz_Serenade  +0x1729e..+0x172b0 (0xece45c, 18 B)
; [nakarest] style name string (16 characters): "Jazz Serenade".
NakaInst_Jazz_Serenade:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1729E, 0x12
; [nakarest] NakaInst_Romantic_Band  +0x172b0..+0x172c2 (0xece46e, 18 B)
; [nakarest] style name string (16 characters): "Romantic Band".
NakaInst_Romantic_Band:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x172B0, 0x12
; [nakarest] NakaInst_Euro_Ballads  +0x172c2..+0x172d4 (0xece480, 18 B)
; [nakarest] style name string (16 characters): "Euro Ballads".
NakaInst_Euro_Ballads:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x172C2, 0x12
; [nakarest] NakaInst_Oldie_Drawbars  +0x172d4..+0x172e6 (0xece492, 18 B)
; [nakarest] style name string (16 characters): "Oldie Drawbars".
NakaInst_Oldie_Drawbars:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x172D4, 0x12
; [nakarest] NakaInst_Soft_Schlager  +0x172e6..+0x172f8 (0xece4a4, 18 B)
; [nakarest] style name string (16 characters): "Soft Schlager".
NakaInst_Soft_Schlager:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x172E6, 0x12
; [nakarest] NakaInst_Oldie_Ballads  +0x172f8..+0x1730a (0xece4b6, 18 B)
; [nakarest] style name string (16 characters): "Oldie Ballads".
NakaInst_Oldie_Ballads:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x172F8, 0x12
; [nakarest] NakaInst_50_s_Love_Songs  +0x1730a..+0x1731c (0xece4c8, 18 B)
; [nakarest] style name string (16 characters): "50's Love Songs".
NakaInst_50_s_Love_Songs:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1730A, 0x12
; [nakarest] NakaInst_Night_Club_Dance  +0x1731c..+0x1732e (0xece4da, 18 B)
; [nakarest] style name string (16 characters): "Night Club Dance".
NakaInst_Night_Club_Dance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1731C, 0x12
; [nakarest] NakaInst_Modern_Ballads  +0x1732e..+0x17340 (0xece4ec, 18 B)
; [nakarest] style name string (16 characters): "Modern Ballads".
NakaInst_Modern_Ballads:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1732E, 0x12
; [nakarest] NakaInst_Grands_on_Stage  +0x17340..+0x17352 (0xece4fe, 18 B)
; [nakarest] style name string (16 characters): "Grands on Stage".
NakaInst_Grands_on_Stage:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17340, 0x12
; [nakarest] NakaInst_Synth_Ballad  +0x17352..+0x17364 (0xece510, 18 B)
; [nakarest] style name string (16 characters): "Synth Ballad".
NakaInst_Synth_Ballad:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17352, 0x12
; [nakarest] NakaInst_Atmospheric_16  +0x17364..+0x17376 (0xece522, 18 B)
; [nakarest] style name string (16 characters): "Atmospheric 16".
NakaInst_Atmospheric_16:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17364, 0x12
; [nakarest] NakaInst_Gentle_16_Beat  +0x17376..+0x17388 (0xece534, 18 B)
; [nakarest] style name string (16 characters): "Gentle 16 Beat".
NakaInst_Gentle_16_Beat:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17376, 0x12
; [nakarest] NakaInst_E_P_Moments  +0x17388..+0x1739a (0xece546, 18 B)
; [nakarest] style name string (16 characters): "E.P. Moments".
NakaInst_E_P_Moments:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17388, 0x12
; [nakarest] NakaInst_Easy_Play_16Beat  +0x1739a..+0x173ac (0xece558, 18 B)
; [nakarest] style name string (16 characters): "Easy Play 16Beat".
NakaInst_Easy_Play_16Beat:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1739A, 0x12
; [nakarest] NakaInst_16_Beat_Groove  +0x173ac..+0x173be (0xece56a, 18 B)
; [nakarest] style name string (16 characters): "16 Beat Groove".
NakaInst_16_Beat_Groove:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x173AC, 0x12
; [nakarest] NakaInst_Love_Songs  +0x173be..+0x173d0 (0xece57c, 18 B)
; [nakarest] style name string (16 characters): "Love Songs".
NakaInst_Love_Songs:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x173BE, 0x12
; [nakarest] NakaInst_Ballad_Producer  +0x173d0..+0x173e2 (0xece58e, 18 B)
; [nakarest] style name string (16 characters): "Ballad Producer".
NakaInst_Ballad_Producer:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x173D0, 0x12
; [nakarest] NakaInst_Studio_8_Beat  +0x173e2..+0x173f4 (0xece5a0, 18 B)
; [nakarest] style name string (16 characters): "Studio 8 Beat".
NakaInst_Studio_8_Beat:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x173E2, 0x12
; [nakarest] NakaInst_Greatest_Hits  +0x173f4..+0x17406 (0xece5b2, 18 B)
; [nakarest] style name string (16 characters): "Greatest Hits".
NakaInst_Greatest_Hits:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x173F4, 0x12
; [nakarest] NakaInst_Smooth_Rock  +0x17406..+0x17418 (0xece5c4, 18 B)
; [nakarest] style name string (16 characters): "Smooth Rock".
NakaInst_Smooth_Rock:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17406, 0x12
; [nakarest] NakaInst_Orchestral_Beat  +0x17418..+0x1742a (0xece5d6, 18 B)
; [nakarest] style name string (16 characters): "Orchestral Beat".
NakaInst_Orchestral_Beat:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17418, 0x12
; [nakarest] NakaInst_Rock_After_Eight  +0x1742a..+0x1743c (0xece5e8, 18 B)
; [nakarest] style name string (16 characters): "Rock After Eight".
NakaInst_Rock_After_Eight:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1742A, 0x12
; [nakarest] NakaInst_Easy_Play_8_Beat  +0x1743c..+0x1744e (0xece5fa, 18 B)
; [nakarest] style name string (16 characters): "Easy Play 8 Beat".
NakaInst_Easy_Play_8_Beat:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1743C, 0x12
; [nakarest] NakaInst_German_Schlager  +0x1744e..+0x17460 (0xece60c, 18 B)
; [nakarest] style name string (16 characters): "German Schlager".
NakaInst_German_Schlager:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1744E, 0x12
; [nakarest] StyleGroup_RockPop_PairTable  +0x17460..+0x17662 (0xece61e, 514 B)
; [nakarest] group table of the MstStyle browser, group 1: {u32 style name, u32 variation table}
; [nakarest] x n + an all-zero entry; MstStyle*_CountEntries walk it 8 bytes at a time until +0
; [nakarest] is 0, the grid routines Strcpy +0 and pad it to 16 with Strncat, and +4 goes to
; [nakarest] 0x0340d6. style name strings (16 characters): "Straight Funk", "Cool Funk", "Chart
; [nakarest] Fusion", "Easy Groovin'", "Pop Fusion", "Jazz Pop", ....
StyleGroup_RockPop_PairTable:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17460, 0x110
NakaInst_Straight_Funk:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17570, 0x12
NakaInst_Cool_Funk:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17582, 0x12
NakaInst_Chart_Fusion:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17594, 0x12
NakaInst_Easy_Groovin:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x175A6, 0x12
NakaInst_Pop_Fusion:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x175B8, 0x12
NakaInst_Jazz_Pop:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x175CA, 0x12
NakaInst_Cool_Fusion:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x175DC, 0x12
NakaInst_Gentle_SwingRock:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x175EE, 0x12
NakaInst_L_A_Pop:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17600, 0x12
NakaInst_Power_Ballad:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17612, 0x12
NakaInst_Heavy_Shuffle:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17624, 0x12
NakaInst_Heavy_Metal:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17636, 0x12
NakaInst_Rock_Gig:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17648, 0x12
NakaInst_80s_Pop_Ballads:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1765A, 0x8
; [nakarest] NakaInst_Ballads  +0x17662..+0x177c2 (0xece820, 352 B)
; [nakarest] Continues style name string (16 characters): "80's Pop Ballads" (starts 0xece818,
; [nakarest] 10 of its 18 bytes are here or later). style name strings (16 characters): "8 Beat
; [nakarest] Groove", "Pop Beat", "In The Eighties", "80's Love Songs", "Euro Pop Shuffle",
; [nakarest] "70's Power Rock", ....
NakaInst_Ballads:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17662, 0xA
NakaInst_8_Beat_Groove:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1766C, 0x12
NakaInst_Pop_Beat:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1767E, 0x12
NakaInst_In_The_Eighties:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17690, 0x12
NakaInst_80s_Love_Songs:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x176A2, 0x12
NakaInst_Euro_Pop_Shuffle:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x176B4, 0x12
NakaInst_70s_Power_Rock:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x176C6, 0x12
NakaInst_70s_Hits:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x176D8, 0x12
NakaInst_Glamrock_Piano:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x176EA, 0x12
NakaInst_70s_Fox_Dance:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x176FC, 0x12
NakaInst_California_Pop:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1770E, 0x12
NakaInst_60s_Rock:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17720, 0x12
NakaInst_Liverpool_Beat:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17732, 0x12
NakaInst_Swinging_Sixties:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17744, 0x12
NakaInst_Slow_Dance:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17756, 0x12
NakaInst_Boogie_Time:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17768, 0x12
NakaInst_Rockabilly_Band:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1777A, 0x12
NakaInst_Its_Boogie_Time:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1778C, 0x12
NakaInst_Piano_R_And_Roll:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1779E, 0x12
NakaInst_Fifties_Rock:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x177B0, 0x12
; [nakarest] StyleGroup_PopBallad_Table  +0x177c2..+0x17852 (0xece980, 144 B)
; [nakarest] group table of the MstStyle browser, group 2: {u32 style name, u32 variation table}
; [nakarest] x n + an all-zero entry; MstStyle*_CountEntries walk it 8 bytes at a time until +0
; [nakarest] is 0, the grid routines Strcpy +0 and pad it to 16 with Strncat, and +4 goes to
; [nakarest] 0x0340d6.
StyleGroup_PopBallad_Table:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x177C2, 0x90
; [nakarest] NakaInst_Western_Techno  +0x17852..+0x17864 (0xecea10, 18 B)
; [nakarest] style name string (16 characters): "Western Techno".
NakaInst_Western_Techno:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17852, 0x12
; [nakarest] NakaInst_Samba_Party  +0x17864..+0x17876 (0xecea22, 18 B)
; [nakarest] style name string (16 characters): "Samba Party".
NakaInst_Samba_Party:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17864, 0x12
; [nakarest] NakaInst_Jambo_Dance  +0x17876..+0x17888 (0xecea34, 18 B)
; [nakarest] style name string (16 characters): "Jambo Dance".
NakaInst_Jambo_Dance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17876, 0x12
; [nakarest] NakaInst_Rio_Goes_Disco  +0x17888..+0x1789a (0xecea46, 18 B)
; [nakarest] style name string (16 characters): "Rio Goes Disco".
NakaInst_Rio_Goes_Disco:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17888, 0x12
; [nakarest] NakaInst_Reggae_Hit  +0x1789a..+0x178ac (0xecea58, 18 B)
; [nakarest] style name string (16 characters): "Reggae Hit".
NakaInst_Reggae_Hit:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1789A, 0x12
; [nakarest] NakaInst_The_Big_Hit  +0x178ac..+0x178be (0xecea6a, 18 B)
; [nakarest] style name string (16 characters): "The Big Hit".
NakaInst_The_Big_Hit:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x178AC, 0x12
; [nakarest] NakaInst_N_Y_Rap  +0x178be..+0x178d0 (0xecea7c, 18 B)
; [nakarest] style name string (16 characters): "N.Y. Rap".
NakaInst_N_Y_Rap:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x178BE, 0x12
; [nakarest] NakaInst_80_s_90_s  +0x178d0..+0x178e2 (0xecea8e, 18 B)
; [nakarest] style name string (16 characters): "80's & 90's".
NakaInst_80_s_90_s:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x178D0, 0x12
; [nakarest] NakaInst_Hip_Hop  +0x178e2..+0x178f4 (0xeceaa0, 18 B)
; [nakarest] style name string (16 characters): "Hip Hop".
NakaInst_Hip_Hop:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x178E2, 0x12
; [nakarest] NakaInst_70_s_Dance_Craze  +0x178f4..+0x17906 (0xeceab2, 18 B)
; [nakarest] style name string (16 characters): "70's Dance Craze".
NakaInst_70_s_Dance_Craze:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x178F4, 0x12
; [nakarest] NakaInst_Dance_Floor  +0x17906..+0x17918 (0xeceac4, 18 B)
; [nakarest] style name string (16 characters): "Dance Floor".
NakaInst_Dance_Floor:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17906, 0x12
; [nakarest] NakaInst_80_s_Disco  +0x17918..+0x1792a (0xecead6, 18 B)
; [nakarest] style name string (16 characters): "80's Disco".
NakaInst_80_s_Disco:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17918, 0x12
; [nakarest] NakaInst_Glory_Disco  +0x1792a..+0x1793c (0xeceae8, 18 B)
; [nakarest] style name string (16 characters): "Glory Disco".
NakaInst_Glory_Disco:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1792A, 0x12
; [nakarest] NakaInst_Techno_World  +0x1793c..+0x1794e (0xeceafa, 18 B)
; [nakarest] style name string (16 characters): "Techno World".
NakaInst_Techno_World:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1793C, 0x12
; [nakarest] NakaInst_House_Party  +0x1794e..+0x17960 (0xeceb0c, 18 B)
; [nakarest] style name string (16 characters): "House Party".
NakaInst_House_Party:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1794E, 0x12
; [nakarest] NakaInst_Straight_Dance  +0x17960..+0x17972 (0xeceb1e, 18 B)
; [nakarest] style name string (16 characters): "Straight Dance".
NakaInst_Straight_Dance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17960, 0x12
; [nakarest] NakaInst_British_DancePop  +0x17972..+0x17984 (0xeceb30, 18 B)
; [nakarest] style name string (16 characters): "British DancePop".
NakaInst_British_DancePop:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17972, 0x12
; [nakarest] StyleGroup_PartyMusic_PairTable  +0x17984..+0x17b7a (0xeceb42, 502 B)
; [nakarest] group table of the MstStyle browser, group 3: {u32 style name, u32 variation table}
; [nakarest] x n + an all-zero entry; MstStyle*_CountEntries walk it 8 bytes at a time until +0
; [nakarest] is 0, the grid routines Strcpy +0 and pad it to 16 with Strncat, and +4 goes to
; [nakarest] 0x0340d6. style name strings (16 characters): "Merry Christmas!", "Munich
; [nakarest] Festival", "Bavarian Party", "Hillbilly Joe", "Barn Dance", "Line Dance Craze",
; [nakarest] ....
StyleGroup_PartyMusic_PairTable:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17984, 0xA0
NakaInst_Merry_Christmas:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17A24, 0x12
NakaInst_Munich_Festival:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17A36, 0x12
NakaInst_Bavarian_Party:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17A48, 0x12
NakaInst_Hillbilly_Joe:			.incbin "includes/generated/naka_style_bitmaps.bin", 0x17A5A, 0x12
NakaInst_Barn_Dance:			.incbin "includes/generated/naka_style_bitmaps.bin", 0x17A6C, 0x12
NakaInst_Line_Dance_Craze:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17A7E, 0x12
NakaInst_Pub_Singalong:			.incbin "includes/generated/naka_style_bitmaps.bin", 0x17A90, 0x12
NakaInst_Dancing_Birdies:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17AA2, 0x12
NakaInst_Do_The_Hokie:			.incbin "includes/generated/naka_style_bitmaps.bin", 0x17AB4, 0x12
NakaInst_BeerBarrel_Polka:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17AC6, 0x12
NakaInst_Golden_Oldies:			.incbin "includes/generated/naka_style_bitmaps.bin", 0x17AD8, 0x12
NakaInst_German_Oldies:			.incbin "includes/generated/naka_style_bitmaps.bin", 0x17AEA, 0x12
NakaInst_Euro_Party_Pop:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17AFC, 0x12
NakaInst_Eurovision_Hits:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17B0E, 0x12
NakaInst_Pop_Organ_March:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17B20, 0x12
NakaInst_All_Night_Party:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17B32, 0x12
NakaInst_German_Schlager_2:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17B44, 0x12
NakaInst_Last_Arrangement:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17B56, 0x12
NakaInst_J_Last_Hitparade:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x17B68, 0x12
; [nakarest] StyleGroup_Swing_Table  +0x17b7a..+0x17c12 (0xeced38, 152 B)
; [nakarest] group table of the MstStyle browser, group 4: {u32 style name, u32 variation table}
; [nakarest] x n + an all-zero entry; MstStyle*_CountEntries walk it 8 bytes at a time until +0
; [nakarest] is 0, the grid routines Strcpy +0 and pad it to 16 with Strncat, and +4 goes to
; [nakarest] 0x0340d6.
StyleGroup_Swing_Table:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17B7A, 0x98
; [nakarest] NakaInst_Gospel_In_Threes  +0x17c12..+0x17c24 (0xecedd0, 18 B)
; [nakarest] style name string (16 characters): "Gospel In Threes".
NakaInst_Gospel_In_Threes:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C12, 0x12
; [nakarest] NakaInst_Gospel_Blues  +0x17c24..+0x17c36 (0xecede2, 18 B)
; [nakarest] style name string (16 characters): "Gospel Blues".
NakaInst_Gospel_Blues:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C24, 0x12
; [nakarest] NakaInst_Power_Gospel  +0x17c36..+0x17c48 (0xecedf4, 18 B)
; [nakarest] style name string (16 characters): "Power Gospel".
NakaInst_Power_Gospel:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C36, 0x12
; [nakarest] NakaInst_Day_Of_Rest  +0x17c48..+0x17c5a (0xecee06, 18 B)
; [nakarest] style name string (16 characters): "Day Of Rest".
NakaInst_Day_Of_Rest:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C48, 0x12
; [nakarest] NakaInst_Lift_Your_Soul  +0x17c5a..+0x17c6c (0xecee18, 18 B)
; [nakarest] style name string (16 characters): "Lift Your Soul".
NakaInst_Lift_Your_Soul:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C5A, 0x12
; [nakarest] NakaInst_Sunday_Service  +0x17c6c..+0x17c7e (0xecee2a, 18 B)
; [nakarest] style name string (16 characters): "Sunday Service".
NakaInst_Sunday_Service:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C6C, 0x12
; [nakarest] NakaInst_Play_The_Blues  +0x17c7e..+0x17c90 (0xecee3c, 18 B)
; [nakarest] style name string (16 characters): "Play The Blues".
NakaInst_Play_The_Blues:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C7E, 0x12
; [nakarest] NakaInst_Blues_Alley  +0x17c90..+0x17ca2 (0xecee4e, 18 B)
; [nakarest] style name string (16 characters): "Blues Alley".
NakaInst_Blues_Alley:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C90, 0x12
; [nakarest] NakaInst_Rock_Blues  +0x17ca2..+0x17cb4 (0xecee60, 18 B)
; [nakarest] style name string (16 characters): "Rock Blues".
NakaInst_Rock_Blues:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17CA2, 0x12
; [nakarest] NakaInst_Down_Dirty_Blues  +0x17cb4..+0x17cc6 (0xecee72, 18 B)
; [nakarest] style name string (16 characters): "Down&Dirty Blues".
NakaInst_Down_Dirty_Blues:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17CB4, 0x12
; [nakarest] NakaInst_R_B_Groove  +0x17cc6..+0x17cd8 (0xecee84, 18 B)
; [nakarest] style name string (16 characters): "R&B Groove".
NakaInst_R_B_Groove:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17CC6, 0x12
; [nakarest] NakaInst_Slow_Soul_Mood  +0x17cd8..+0x17cea (0xecee96, 18 B)
; [nakarest] style name string (16 characters): "Slow Soul Mood".
NakaInst_Slow_Soul_Mood:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17CD8, 0x12
; [nakarest] NakaInst_Mellow_Soul  +0x17cea..+0x17cfc (0xeceea8, 18 B)
; [nakarest] style name string (16 characters): "Mellow Soul".
NakaInst_Mellow_Soul:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17CEA, 0x12
; [nakarest] NakaInst_Soul_To_Sun  +0x17cfc..+0x17d0e (0xeceeba, 18 B)
; [nakarest] style name string (16 characters): "Soul To Sun".
NakaInst_Soul_To_Sun:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17CFC, 0x12
; [nakarest] NakaInst_New_Soul_Ballad  +0x17d0e..+0x17d20 (0xeceecc, 18 B)
; [nakarest] style name string (16 characters): "New Soul Ballad".
NakaInst_New_Soul_Ballad:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17D0E, 0x12
; [nakarest] NakaInst_Soft_Soul  +0x17d20..+0x17d32 (0xeceede, 18 B)
; [nakarest] style name string (16 characters): "Soft Soul".
NakaInst_Soft_Soul:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17D20, 0x12
; [nakarest] NakaInst_Detroit_Pop  +0x17d32..+0x17d44 (0xeceef0, 18 B)
; [nakarest] style name string (16 characters): "Detroit Pop".
NakaInst_Detroit_Pop:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17D32, 0x12
; [nakarest] NakaInst_King_Of_Soul  +0x17d44..+0x17d56 (0xecef02, 18 B)
; [nakarest] style name string (16 characters): "King Of Soul".
NakaInst_King_Of_Soul:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17D44, 0x12
; [nakarest] StyleGroup_FunkFusion_Separator  +0x17d56..+0x17d5a (0xecef14, 4 B)
; [nakarest] group table of the MstStyle browser, group 5: {u32 style name, u32 variation table}
; [nakarest] x n + an all-zero entry; MstStyle*_CountEntries walk it 8 bytes at a time until +0
; [nakarest] is 0, the grid routines Strcpy +0 and pad it to 16 with Strncat, and +4 goes to
; [nakarest] 0x0340d6.
StyleGroup_FunkFusion_Separator:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17D56, 0x4
; [nakarest] StyleGroup_FunkFusion_Table  +0x17d5a..+0x17e49 (0xecef18, 239 B)
; [nakarest] Continues group table of the MstStyle browser, group 5: {u32 style name, u32
; [nakarest] variation table} x n + an all-zero entry; MstStyle*_CountEntries walk it 8 bytes at
; [nakarest] a time until +0 is 0, the grid routines Strcpy +0 and pad it to 16 with Strncat,
; [nakarest] and +4 goes to 0x0340d6 (starts 0xecef14, 244 of its 248 bytes are here or later).
StyleGroup_FunkFusion_Table:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17D5A, 0xEF
; [nakarest] StyleGroup_FunkFusion_Pad  +0x17e49..+0x17e4e (0xecf007, 5 B)
; [nakarest] Continues group table of the MstStyle browser, group 5: {u32 style name, u32
; [nakarest] variation table} x n + an all-zero entry; MstStyle*_CountEntries walk it 8 bytes at
; [nakarest] a time until +0 is 0, the grid routines Strcpy +0 and pad it to 16 with Strncat,
; [nakarest] and +4 goes to 0x0340d6 (starts 0xecef14, 5 of its 248 bytes are here or later).
StyleGroup_FunkFusion_Pad:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17E49, 0x5
; [nakarest] NakaInst_L_A_Fusion  +0x17e4e..+0x17e60 (0xecf00c, 18 B)
; [nakarest] style name string (16 characters): "L.A. Fusion".
NakaInst_L_A_Fusion:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17E4E, 0x12
; [nakarest] NakaInst_The_Groove  +0x17e60..+0x17e72 (0xecf01e, 18 B)
; [nakarest] style name string (16 characters): "The Groove".
NakaInst_The_Groove:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17E60, 0x12
; [nakarest] NakaInst_Slow_Jazz_3_4  +0x17e72..+0x17e84 (0xecf030, 18 B)
; [nakarest] style name string (16 characters): "Slow Jazz 3/4".
NakaInst_Slow_Jazz_3_4:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17E72, 0x12
; [nakarest] NakaInst_Steady_Jazz_3_4  +0x17e84..+0x17e96 (0xecf042, 18 B)
; [nakarest] style name string (16 characters): "Steady Jazz 3/4".
NakaInst_Steady_Jazz_3_4:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17E84, 0x12
; [nakarest] NakaInst_Jazz_At_3_00am  +0x17e96..+0x17ea8 (0xecf054, 18 B)
; [nakarest] style name string (16 characters): "Jazz At 3:00am".
NakaInst_Jazz_At_3_00am:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17E96, 0x12
; [nakarest] NakaInst_Smokey_Jazz_Club  +0x17ea8..+0x17eba (0xecf066, 18 B)
; [nakarest] style name string (16 characters): "Smokey Jazz Club".
NakaInst_Smokey_Jazz_Club:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17EA8, 0x12
; [nakarest] NakaInst_Euro_Jazz  +0x17eba..+0x17ecc (0xecf078, 18 B)
; [nakarest] style name string (16 characters): "Euro Jazz".
NakaInst_Euro_Jazz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17EBA, 0x12
; [nakarest] NakaInst_Van_Damme_Jazz  +0x17ecc..+0x17ede (0xecf08a, 18 B)
; [nakarest] style name string (16 characters): "Van Damme Jazz".
NakaInst_Van_Damme_Jazz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17ECC, 0x12
; [nakarest] NakaInst_Jazz_Francais  +0x17ede..+0x17ef0 (0xecf09c, 18 B)
; [nakarest] style name string (16 characters): "Jazz Francais".
NakaInst_Jazz_Francais:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17EDE, 0x12
; [nakarest] NakaInst_Speakeasy_Jazz  +0x17ef0..+0x17f02 (0xecf0ae, 18 B)
; [nakarest] style name string (16 characters): "Speakeasy Jazz".
NakaInst_Speakeasy_Jazz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17EF0, 0x12
; [nakarest] NakaInst_Jazz_Accordion  +0x17f02..+0x17f14 (0xecf0c0, 18 B)
; [nakarest] style name string (16 characters): "Jazz Accordion".
NakaInst_Jazz_Accordion:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F02, 0x12
; [nakarest] NakaInst_Gypsy_Jazzers  +0x17f14..+0x17f26 (0xecf0d2, 18 B)
; [nakarest] style name string (16 characters): "Gypsy Jazzers".
NakaInst_Gypsy_Jazzers:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F14, 0x12
; [nakarest] NakaInst_Gentle_Jazz  +0x17f26..+0x17f38 (0xecf0e4, 18 B)
; [nakarest] style name string (16 characters): "Gentle Jazz".
NakaInst_Gentle_Jazz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F26, 0x12
; [nakarest] NakaInst_Combo_Drawbars  +0x17f38..+0x17f4a (0xecf0f6, 18 B)
; [nakarest] style name string (16 characters): "Combo Drawbars".
NakaInst_Combo_Drawbars:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F38, 0x12
; [nakarest] NakaInst_Jazz_Standards  +0x17f4a..+0x17f5c (0xecf108, 18 B)
; [nakarest] style name string (16 characters): "Jazz Standards".
NakaInst_Jazz_Standards:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F4A, 0x12
; [nakarest] NakaInst_40_s_Boogie  +0x17f5c..+0x17f6e (0xecf11a, 18 B)
; [nakarest] style name string (16 characters): "40's Boogie".
NakaInst_40_s_Boogie:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F5C, 0x12
; [nakarest] NakaInst_Simple_Jazz  +0x17f6e..+0x17f80 (0xecf12c, 18 B)
; [nakarest] style name string (16 characters): "Simple Jazz".
NakaInst_Simple_Jazz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F6E, 0x12
; [nakarest] NakaInst_Up_Tempo_Combo  +0x17f80..+0x17f92 (0xecf13e, 18 B)
; [nakarest] style name string (16 characters): "Up Tempo Combo".
NakaInst_Up_Tempo_Combo:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F80, 0x12
; [nakarest] NakaInst_Jazz_Club  +0x17f92..+0x17fa4 (0xecf150, 18 B)
; [nakarest] style name string (16 characters): "Jazz Club".
NakaInst_Jazz_Club:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F92, 0x12
; [nakarest] NakaInst_Easy_Play_Swing  +0x17fa4..+0x17fb6 (0xecf162, 18 B)
; [nakarest] style name string (16 characters): "Easy Play Swing".
NakaInst_Easy_Play_Swing:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17FA4, 0x12
; [nakarest] NakaInst_Night_Club_Combo  +0x17fb6..+0x17fc8 (0xecf174, 18 B)
; [nakarest] style name string (16 characters): "Night Club Combo".
NakaInst_Night_Club_Combo:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17FB6, 0x12
; [nakarest] NakaInst_Swing_Orchestra  +0x17fc8..+0x17fda (0xecf186, 18 B)
; [nakarest] style name string (16 characters): "Swing Orchestra".
NakaInst_Swing_Orchestra:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17FC8, 0x12
; [nakarest] NakaInst_Mid_Swingband  +0x17fda..+0x17fec (0xecf198, 18 B)
; [nakarest] style name string (16 characters): "Mid Swingband".
NakaInst_Mid_Swingband:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17FDA, 0x12
; [nakarest] NakaInst_40_s_Love_Songs  +0x17fec..+0x17ffe (0xecf1aa, 18 B)
; [nakarest] style name string (16 characters): "40's Love Songs".
NakaInst_40_s_Love_Songs:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17FEC, 0x12
; [nakarest] NakaInst_Moonlight_Dance  +0x17ffe..+0x18010 (0xecf1bc, 18 B)
; [nakarest] style name string (16 characters): "Moonlight Dance".
NakaInst_Moonlight_Dance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17FFE, 0x12
; [nakarest] NakaInst_Sentimental_Band  +0x18010..+0x18022 (0xecf1ce, 18 B)
; [nakarest] style name string (16 characters): "Sentimental Band".
NakaInst_Sentimental_Band:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18010, 0x12
; [nakarest] NakaInst_40_s_Dance_Band  +0x18022..+0x18034 (0xecf1e0, 18 B)
; [nakarest] style name string (16 characters): "40's Dance Band".
NakaInst_40_s_Dance_Band:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18022, 0x12
; [nakarest] NakaInst_All_Aboard  +0x18034..+0x18046 (0xecf1f2, 18 B)
; [nakarest] style name string (16 characters): "All Aboard!".
NakaInst_All_Aboard:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18034, 0x12
; [nakarest] NakaInst_Steady_Swingband  +0x18046..+0x1806a (0xecf204, 36 B)
; [nakarest] style name strings (16 characters): "Steady Swingband", "Up Tempo Bigband".
NakaInst_Steady_Swingband:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18046, 0x12
NakaInst_Up_Tempo_Bigband:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18058, 0x12
; [nakarest] StyleGroup_JazzCombo_Table  +0x1806a..+0x1816a (0xecf228, 256 B)
; [nakarest] group table of the MstStyle browser, group 6: {u32 style name, u32 variation table}
; [nakarest] x n + an all-zero entry; MstStyle*_CountEntries walk it 8 bytes at a time until +0
; [nakarest] is 0, the grid routines Strcpy +0 and pad it to 16 with Strncat, and +4 goes to
; [nakarest] 0x0340d6.
StyleGroup_JazzCombo_Table:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1806A, 0x100
; [nakarest] NakaInst_Party_Vienna  +0x1816a..+0x1817c (0xecf328, 18 B)
; [nakarest] style name string (16 characters): "Party Vienna".
NakaInst_Party_Vienna:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1816A, 0x12
; [nakarest] NakaInst_Walzer_Time  +0x1817c..+0x1818e (0xecf33a, 18 B)
; [nakarest] style name string (16 characters): "Walzer-Time".
NakaInst_Walzer_Time:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1817C, 0x12
; [nakarest] NakaInst_Austrian_Waltz  +0x1818e..+0x181a0 (0xecf34c, 18 B)
; [nakarest] style name string (16 characters): "Austrian Waltz".
NakaInst_Austrian_Waltz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1818E, 0x12
; [nakarest] NakaInst_Quick_Waltz  +0x181a0..+0x181b2 (0xecf35e, 18 B)
; [nakarest] style name string (16 characters): "Quick Waltz".
NakaInst_Quick_Waltz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x181A0, 0x12
; [nakarest] NakaInst_Last_Dance_Waltz  +0x181b2..+0x181c4 (0xecf370, 18 B)
; [nakarest] style name string (16 characters): "Last Dance Waltz".
NakaInst_Last_Dance_Waltz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x181B2, 0x12
; [nakarest] NakaInst_Tango_Pianist  +0x181c4..+0x181d6 (0xecf382, 18 B)
; [nakarest] style name string (16 characters): "Tango Pianist".
NakaInst_Tango_Pianist:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x181C4, 0x12
; [nakarest] NakaInst_Tango_D_Amour  +0x181d6..+0x181e8 (0xecf394, 18 B)
; [nakarest] style name string (16 characters): "Tango D'Amour".
NakaInst_Tango_D_Amour:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x181D6, 0x12
; [nakarest] NakaInst_Strict_Tango  +0x181e8..+0x181fa (0xecf3a6, 18 B)
; [nakarest] style name string (16 characters): "Strict Tango".
NakaInst_Strict_Tango:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x181E8, 0x12
; [nakarest] NakaInst_Viva_Pasodoble  +0x181fa..+0x1820c (0xecf3b8, 18 B)
; [nakarest] style name string (16 characters): "Viva Pasodoble!".
NakaInst_Viva_Pasodoble:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x181FA, 0x12
; [nakarest] NakaInst_Samba_Felicidade  +0x1820c..+0x1821e (0xecf3ca, 18 B)
; [nakarest] style name string (16 characters): "Samba Felicidade".
NakaInst_Samba_Felicidade:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1820C, 0x12
; [nakarest] NakaInst_Let_s_Beguine  +0x1821e..+0x18230 (0xecf3dc, 18 B)
; [nakarest] style name string (16 characters): "Let's Beguine!".
NakaInst_Let_s_Beguine:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1821E, 0x12
; [nakarest] NakaInst_1_2_Cha_Cha_Cha  +0x18230..+0x18242 (0xecf3ee, 18 B)
; [nakarest] style name string (16 characters): "1,2,Cha Cha Cha".
NakaInst_1_2_Cha_Cha_Cha:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18230, 0x12
; [nakarest] NakaInst_Do_The_Twist  +0x18242..+0x18254 (0xecf400, 18 B)
; [nakarest] style name string (16 characters): "Do The Twist!".
NakaInst_Do_The_Twist:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18242, 0x12
; [nakarest] NakaInst_Jive_Dance  +0x18254..+0x18266 (0xecf412, 18 B)
; [nakarest] style name string (16 characters): "Jive Dance".
NakaInst_Jive_Dance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18254, 0x12
; [nakarest] NakaInst_Let_s_Twist  +0x18266..+0x18278 (0xecf424, 18 B)
; [nakarest] style name string (16 characters): "Let's Twist".
NakaInst_Let_s_Twist:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18266, 0x12
; [nakarest] NakaInst_Strictly_Quick  +0x18278..+0x1828a (0xecf436, 18 B)
; [nakarest] style name string (16 characters): "Strictly Quick!".
NakaInst_Strictly_Quick:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18278, 0x12
; [nakarest] NakaInst_Radio_Foxtrot  +0x1828a..+0x1829c (0xecf448, 18 B)
; [nakarest] style name string (16 characters): "Radio Foxtrot".
NakaInst_Radio_Foxtrot:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1828A, 0x12
; [nakarest] NakaInst_Strictly_Foxtrot  +0x1829c..+0x182ae (0xecf45a, 18 B)
; [nakarest] style name string (16 characters): "Strictly Foxtrot".
NakaInst_Strictly_Foxtrot:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1829C, 0x12
; [nakarest] NakaInst_Up_Tempo_Foxtrot  +0x182ae..+0x182c0 (0xecf46c, 18 B)
; [nakarest] style name string (16 characters): "Up Tempo Foxtrot".
NakaInst_Up_Tempo_Foxtrot:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x182AE, 0x12
; [nakarest] NakaInst_Organist_s_Dance  +0x182c0..+0x182d2 (0xecf47e, 18 B)
; [nakarest] style name string (16 characters): "Organist's Dance".
NakaInst_Organist_s_Dance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x182C0, 0x12
; [nakarest] NakaInst_Gentle_Foxtrot  +0x182d2..+0x182e4 (0xecf490, 18 B)
; [nakarest] style name string (16 characters): "Gentle Foxtrot".
NakaInst_Gentle_Foxtrot:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x182D2, 0x12
; [nakarest] NakaInst_Magic_Ballroom  +0x182e4..+0x182f6 (0xecf4a2, 18 B)
; [nakarest] style name string (16 characters): "Magic Ballroom".
NakaInst_Magic_Ballroom:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x182E4, 0x12
; [nakarest] NakaInst_Viva_Las_Vegas  +0x182f6..+0x18308 (0xecf4b4, 18 B)
; [nakarest] style name string (16 characters): "Viva Las Vegas".
NakaInst_Viva_Las_Vegas:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x182F6, 0x12
; [nakarest] NakaInst_Cabaret_Band  +0x18308..+0x1831a (0xecf4c6, 18 B)
; [nakarest] style name string (16 characters): "Cabaret Band".
NakaInst_Cabaret_Band:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18308, 0x12
; [nakarest] NakaInst_Paris_Club  +0x1831a..+0x1832c (0xecf4d8, 18 B)
; [nakarest] style name string (16 characters): "Paris Club".
NakaInst_Paris_Club:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1831A, 0x12
; [nakarest] NakaInst_Tap_Dancer  +0x1832c..+0x1833e (0xecf4ea, 18 B)
; [nakarest] style name string (16 characters): "Tap Dancer".
NakaInst_Tap_Dancer:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1832C, 0x12
; [nakarest] NakaInst_Vaudeville_Act  +0x1833e..+0x18350 (0xecf4fc, 18 B)
; [nakarest] style name string (16 characters): "Vaudeville Act".
NakaInst_Vaudeville_Act:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1833E, 0x12
; [nakarest] NakaInst_Theatre_Stride  +0x18350..+0x18362 (0xecf50e, 18 B)
; [nakarest] style name string (16 characters): "Theatre Stride".
NakaInst_Theatre_Stride:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18350, 0x12
; [nakarest] NakaInst_Showband  +0x18362..+0x18374 (0xecf520, 18 B)
; [nakarest] style name string (16 characters): "Showband".
NakaInst_Showband:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18362, 0x12
; [nakarest] NakaInst_Tinseltown  +0x18374..+0x18386 (0xecf532, 18 B)
; [nakarest] style name string (16 characters): "Tinseltown".
NakaInst_Tinseltown:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18374, 0x12
; [nakarest] NakaInst_Musical_Overture  +0x18386..+0x18398 (0xecf544, 18 B)
; [nakarest] style name string (16 characters): "Musical Overture".
NakaInst_Musical_Overture:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18386, 0x12
; [nakarest] StyleGroup_TradFolk_PairTable  +0x18398..+0x1862a (0xecf556, 658 B)
; [nakarest] group table of the MstStyle browser, group 7: {u32 style name, u32 variation table}
; [nakarest] x n + an all-zero entry; MstStyle*_CountEntries walk it 8 bytes at a time until +0
; [nakarest] is 0, the grid routines Strcpy +0 and pad it to 16 with Strncat, and +4 goes to
; [nakarest] 0x0340d6. style name strings (16 characters): "70's Folk Music", "Mariachi band",
; [nakarest] "Spanish Folklore", "Kings of Gypsy", "Moscow At Night", "Greek Dance", ....
StyleGroup_TradFolk_PairTable:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18398, 0xD0
NakaInst_70s_Folk_Music:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18468, 0x12
NakaInst_Mariachi_band:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1847A, 0x12
NakaInst_Spanish_Folklore:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1848C, 0x12
NakaInst_Kings_of_Gypsy:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1849E, 0x12
NakaInst_Moscow_At_Night:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x184B0, 0x12
NakaInst_Greek_Dance:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x184C2, 0x12
NakaInst_Sounds_of_Dixie:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x184D4, 0x12
NakaInst_New_Orleans_Jazz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x184E6, 0x12
NakaInst_Ragtime_Band:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x184F8, 0x12
NakaInst_Old_Ragtime:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1850A, 0x12
NakaInst_Hawaiian_Dance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1851C, 0x12
NakaInst_Island_Romance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1852E, 0x12
NakaInst_German_Waltz:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x18540, 0x12
NakaInst_East_Euro_Waltz:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18552, 0x12
NakaInst_Munich_Waltz:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x18564, 0x12
NakaInst_3_4_Concert_Time:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18576, 0x12
NakaInst_Highland_Dance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18588, 0x12
NakaInst_Ceilidh_Band:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1859A, 0x12
NakaInst_German_Polka:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x185AC, 0x12
NakaInst_Modern_Polka:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x185BE, 0x12
NakaInst_Standard_Polka:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x185D0, 0x12
NakaInst_Musikantenstadl:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x185E2, 0x12
NakaInst_German_Tradition:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x185F4, 0x12
NakaInst_Sousa_Marches:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x18606, 0x12
NakaInst_Stadium_Events:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18618, 0x12
; [nakarest] StyleGroup_WorldMusic_Table  +0x1862a..+0x186ba (0xecf7e8, 144 B)
; [nakarest] group table of the MstStyle browser, group 8: {u32 style name, u32 variation table}
; [nakarest] x n + an all-zero entry; MstStyle*_CountEntries walk it 8 bytes at a time until +0
; [nakarest] is 0, the grid routines Strcpy +0 and pad it to 16 with Strncat, and +4 goes to
; [nakarest] 0x0340d6.
StyleGroup_WorldMusic_Table:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1862A, 0x90
; [nakarest] NakaInst_Country_Hits  +0x186ba..+0x186cc (0xecf878, 18 B)
; [nakarest] style name string (16 characters): "Country Hits".
NakaInst_Country_Hits:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x186BA, 0x12
; [nakarest] NakaInst_New_Country_Rock  +0x186cc..+0x186de (0xecf88a, 18 B)
; [nakarest] style name string (16 characters): "New Country Rock".
NakaInst_New_Country_Rock:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x186CC, 0x12
; [nakarest] NakaInst_Old_Country_Hits  +0x186de..+0x186f0 (0xecf89c, 18 B)
; [nakarest] style name string (16 characters): "Old Country Hits".
NakaInst_Old_Country_Hits:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x186DE, 0x12
; [nakarest] NakaInst_EZ_Country_Rock  +0x186f0..+0x18702 (0xecf8ae, 18 B)
; [nakarest] style name string (16 characters): "EZ Country Rock".
NakaInst_EZ_Country_Rock:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x186F0, 0x12
; [nakarest] NakaInst_Modern_Country  +0x18702..+0x18714 (0xecf8c0, 18 B)
; [nakarest] style name string (16 characters): "Modern Country".
NakaInst_Modern_Country:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18702, 0x12
; [nakarest] NakaInst_Country_Love  +0x18714..+0x18726 (0xecf8d2, 18 B)
; [nakarest] style name string (16 characters): "Country Love".
NakaInst_Country_Love:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18714, 0x12
; [nakarest] NakaInst_Country_88  +0x18726..+0x18738 (0xecf8e4, 18 B)
; [nakarest] style name string (16 characters): "Country 88".
NakaInst_Country_88:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18726, 0x12
; [nakarest] NakaInst_Country_Folks  +0x18738..+0x1874a (0xecf8f6, 18 B)
; [nakarest] style name string (16 characters): "Country Folks".
NakaInst_Country_Folks:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18738, 0x12
; [nakarest] NakaInst_Western_Ballads  +0x1874a..+0x1875c (0xecf908, 18 B)
; [nakarest] style name string (16 characters): "Western Ballads".
NakaInst_Western_Ballads:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1874A, 0x12
; [nakarest] NakaInst_Country_Romance  +0x1875c..+0x1876e (0xecf91a, 18 B)
; [nakarest] style name string (16 characters): "Country Romance".
NakaInst_Country_Romance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1875C, 0x12
; [nakarest] NakaInst_70_s_Country_Pop  +0x1876e..+0x18780 (0xecf92c, 18 B)
; [nakarest] style name string (16 characters): "70's Country Pop".
NakaInst_70_s_Country_Pop:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1876E, 0x12
; [nakarest] NakaInst_Hillbilly_Blues  +0x18780..+0x18792 (0xecf93e, 18 B)
; [nakarest] style name string (16 characters): "Hillbilly Blues".
NakaInst_Hillbilly_Blues:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18780, 0x12
; [nakarest] NakaInst_Country_Dance  +0x18792..+0x187a4 (0xecf950, 18 B)
; [nakarest] style name string (16 characters): "Country Dance".
NakaInst_Country_Dance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18792, 0x12
; [nakarest] NakaInst_Trucker_Country  +0x187a4..+0x187b6 (0xecf962, 18 B)
; [nakarest] style name string (16 characters): "Trucker Country".
NakaInst_Trucker_Country:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x187A4, 0x12
; [nakarest] NakaInst_Kentucky_Blue  +0x187b6..+0x187c8 (0xecf974, 18 B)
; [nakarest] style name string (16 characters): "Kentucky Blue".
NakaInst_Kentucky_Blue:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x187B6, 0x12
; [nakarest] NakaInst_Modern_Hoedown  +0x187c8..+0x187da (0xecf986, 18 B)
; [nakarest] style name string (16 characters): "Modern Hoedown".
NakaInst_Modern_Hoedown:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x187C8, 0x12
; [nakarest] NakaInst_Bluegrass_Time  +0x187da..+0x187ec (0xecf998, 18 B)
; [nakarest] style name string (16 characters): "Bluegrass Time".
NakaInst_Bluegrass_Time:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x187DA, 0x12
; [nakarest] StyleGroup_LatinWorld_PairTable  +0x187ec..+0x18800 (0xecf9aa, 20 B)
; [nakarest] group table of the MstStyle browser, group 9: {u32 style name, u32 variation table}
; [nakarest] x n + an all-zero entry; MstStyle*_CountEntries walk it 8 bytes at a time until +0
; [nakarest] is 0, the grid routines Strcpy +0 and pad it to 16 with Strncat, and +4 goes to
; [nakarest] 0x0340d6.
StyleGroup_LatinWorld_PairTable:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x187EC, 0x14
	.long StyleVar_MellowBossa
	.long NakaInst_Rhumba_Espana
	.long StyleVar_RhumbaEspana
	.long NakaInst_Cocktail_Pianist
	.long StyleVar_CocktailPianist
	.long NakaInst_Romantic_Beguine
	.long StyleVar_RomanticBeguine
	.long NakaInst_Romantic_Dance
	.long StyleVar_RomanticDance
	.long NakaInst_Latin_Lounge_Bar
	.long StyleVar_LatinLoungeBar
	.long NakaInst_Titos_Cha_Cha
	.long StyleVar_TitosChaCha
	.long NakaInst_Mambo_Band
	.long StyleVar_MamboBand
	.long NakaInst_New_Mambo_Mood
	.long StyleVar_NewMamboMood
	.long NakaInst_Its_Mambo_Time
	.long StyleVar_ItsMamboTime
	.long NakaInst_Cumbia_Band
	.long StyleVar_CumbiaBand
	.long NakaInst_Holiday_Mood
	.long StyleVar_HolidayMood
	.long NakaInst_Samba_Parade
	.long StyleVar_SambaParade
	.long NakaInst_Latin_Festival
	.long StyleVar_LatinFestival_2
	.long NakaInst_Modern_Rio
	.long StyleVar_ModernRio
	.long NakaInst_Castanet_Dance
	.long StyleVar_CastanetDance
	.long NakaInst_Caribbean_Nights
	.long StyleVar_CaribbeanNights
	.long NakaInst_Salsa_Picante
	.long StyleVar_SalsaPicante
	.long NakaInst_Samba_Amor
	.long StyleVar_SambaAmor
	.long NakaInst_Modern_Caribbean
	.long StyleVar_ModernCaribbean
	.long NakaInst_Modern_Samba
	.long StyleVar_ModernSamba
	.long NakaInst_Samba_Fusion
	.long StyleVar_SambaFusion
	.long NakaInst_Indonesian_Folk
	.long StyleVar_IndonesianFolk
	.long NakaInst_Dangdut
	.long StyleVar_Dangdut
	.long NakaInst_Talempong
	.long StyleVar_Talempong
	.long NakaInst_Synth_Reggae
	.long StyleVar_SynthReggae
	.long NakaInst_Jamaican_Swing
	.long StyleVar_JamaicanSwing
	.long 0x00000000
	.long 0x00000000
; [nakarest] naka_style_bitmaps+0x188dc  +0x188dc..+0x18ae6 (0xecfa9a, 522 B)
; [nakarest] style name strings (16 characters): "Jamaican Swing", "Synth Reggae", "Talempong",
; [nakarest] "Dangdut", "Indonesian Folk", "Samba Fusion", ....
NakaInst_Jamaican_Swing:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x188DC, 0x12
NakaInst_Synth_Reggae:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x188EE, 0x12
NakaInst_Talempong:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x18900, 0x12
NakaInst_Dangdut:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x18912, 0x12
NakaInst_Indonesian_Folk:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18924, 0x12
NakaInst_Samba_Fusion:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x18936, 0x12
NakaInst_Modern_Samba:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x18948, 0x12
NakaInst_Modern_Caribbean:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1895A, 0x12
NakaInst_Samba_Amor:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1896C, 0x12
NakaInst_Salsa_Picante:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x1897E, 0x12
NakaInst_Caribbean_Nights:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18990, 0x12
NakaInst_Castanet_Dance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x189A2, 0x12
NakaInst_Modern_Rio:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x189B4, 0x12
NakaInst_Latin_Festival:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x189C6, 0x12
NakaInst_Samba_Parade:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x189D8, 0x12
NakaInst_Holiday_Mood:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x189EA, 0x12
NakaInst_Cumbia_Band:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x189FC, 0x12
NakaInst_Its_Mambo_Time:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18A0E, 0x12
NakaInst_New_Mambo_Mood:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18A20, 0x12
NakaInst_Mambo_Band:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x18A32, 0x12
NakaInst_Titos_Cha_Cha:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x18A44, 0x12
NakaInst_Latin_Lounge_Bar:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18A56, 0x12
NakaInst_Romantic_Dance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18A68, 0x12
NakaInst_Romantic_Beguine:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18A7A, 0x12
NakaInst_Cocktail_Pianist:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18A8C, 0x12
NakaInst_Rhumba_Espana:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x18A9E, 0x12
NakaInst_Mellow_Bossa:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x18AB0, 0x12
NakaInst_Bossa_Pianist:		.incbin "includes/generated/naka_style_bitmaps.bin", 0x18AC2, 0x12
NakaInst_Romantic_Bossa:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18AD4, 0x12
; [nakarest] naka_style_bitmaps+0x18ae6  +0x18ae6..+0x18aea (0xecfca4, 4 B)
; [nakarest] the root of the MstStyle browser tree (0xecfca4): 10 x {u32 group name, u32 group
; [nakarest] table}. MstStyle1_EventDispatch, MstStyle1Sub_HandleSubSelect and
; [nakarest] MstStyle1Page_EventDispatch load (index*8)+4 -- the group table -- through the
; [nakarest] label 4 bytes into it (StyleGroup_LatinDance_Table) and store it at 0x0340d2;
; [nakarest] MstStyle1Grid_CellSelect and MstStyle2_NameB_Render load +0, the name, through
; [nakarest] MstStyle1Grid_CellSelect_Data (= this address).
MstStyle1Grid_CellSelect_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18AE6, 0x4
; [nakarest] StyleGroup_LatinDance_Table  +0x18aea..+0x18b36 (0xecfca8, 76 B)
; [nakarest] Continues the root of the MstStyle browser tree (0xecfca4): 10 x {u32 group name,
; [nakarest] u32 group table}. MstStyle1_EventDispatch, MstStyle1Sub_HandleSubSelect and
; [nakarest] MstStyle1Page_EventDispatch load (index*8)+4 -- the group table -- through the
; [nakarest] label 4 bytes into it (StyleGroup_LatinDance_Table) and store it at 0x0340d2;
; [nakarest] MstStyle1Grid_CellSelect and MstStyle2_NameB_Render load +0, the name, through
; [nakarest] MstStyle1Grid_CellSelect_Data (= this address) (starts 0xecfca4, 76 of its
; [nakarest] 80 bytes are here or later).
StyleGroup_LatinDance_Table:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18AEA, 0x4C
; [nakarest] NakaInst_Latin_World  +0x18b36..+0x18b48 (0xecfcf4, 18 B)
; [nakarest] group name string (16 characters): "Latin / World".
NakaInst_Latin_World:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18B36, 0x12
; [nakarest] NakaInst_Country  +0x18b48..+0x18b5a (0xecfd06, 18 B)
; [nakarest] group name string (16 characters): "Country".
NakaInst_Country:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18B48, 0x12
; [nakarest] NakaInst_Trad_Folk  +0x18b5a..+0x18b6c (0xecfd18, 18 B)
; [nakarest] group name string (16 characters): "Trad & Folk".
NakaInst_Trad_Folk:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18B5A, 0x12
; [nakarest] NakaInst_Show_Trad_Dance  +0x18b6c..+0x18b7e (0xecfd2a, 18 B)
; [nakarest] group name string (16 characters): "Show/Trad Dance".
NakaInst_Show_Trad_Dance:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18B6C, 0x12
; [nakarest] NakaInst_Jazz_Swing  +0x18b7e..+0x18b90 (0xecfd3c, 18 B)
; [nakarest] group name string (16 characters): "Jazz & Swing".
NakaInst_Jazz_Swing:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18B7E, 0x12
; [nakarest] NakaInst_Gospel_Blues_R_B  +0x18b90..+0x18ba2 (0xecfd4e, 18 B)
; [nakarest] group name string (16 characters): "Gospel/Blues/R&B".
NakaInst_Gospel_Blues_R_B:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18B90, 0x12
; [nakarest] NakaInst_Party_Music  +0x18ba2..+0x18bb4 (0xecfd60, 18 B)
; [nakarest] group name string (16 characters): "Party Music".
NakaInst_Party_Music:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18BA2, 0x12
; [nakarest] NakaInst_Dance_Pop  +0x18bb4..+0x18bc6 (0xecfd72, 18 B)
; [nakarest] group name string (16 characters): "Dance Pop".
NakaInst_Dance_Pop:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18BB4, 0x12
; [nakarest] NakaInst_Rock_Pop  +0x18bc6..+0x18bea (0xecfd84, 36 B)
; [nakarest] group name strings (16 characters): "Rock & Pop", "Easy Listening".
NakaInst_Rock_Pop:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18BC6, 0x24
; [nakarest] naka_style_bitmaps+0x18bea  +0x18bea..+0x18bee (0xecfda8, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xecfda8 not derived; readers below
; [nakarest] Readers: source references RVari_ConfirmF_CheckSelected (ui/rvari_routines.s: `lda
; [nakarest] xbc, (RVari_Select_Data:24)`), RVari_EnumNotifyF_CheckSelected
; [nakarest] (ui/rvari_routines.s: `lda xbc, (RVari_Select_Data:24)`), RVari_Select
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (RVari_Select_Data:24)`),
; [nakarest] RVari_Select_CheckSameBank (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (RVari_Select_Data:24)`).
RVari_Select_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18BEA, 0x4
; [nakarest] naka_style_bitmaps+0x18bee  +0x18bee..+0x18bf2 (0xecfdac, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xecfdac not derived; readers below
; [nakarest] Readers: source references RVari_Confirm_TypeF_SubItems (ui/rvari_routines.s: `lda
; [nakarest] xbc, (RVari_Select_CheckSameBank_Data:24)`), RVari_Select_CheckSameBank
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (RVari_Select_CheckSameBank_Data:24)`).
RVari_Select_CheckSameBank_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18BEE, 0x4
; [nakarest] naka_style_bitmaps+0x18bf2  +0x18bf2..+0x18bf6 (0xecfdb0, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xecfdb0 not derived; readers below
; [nakarest] Readers: source references MsaMode_Select (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (MsaMode_Select_Data:24)`), MsaMode_Select_DrawHighlight1
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (MsaMode_Select_Data:24)`).
MsaMode_Select_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18BF2, 0x4
; [nakarest] naka_style_bitmaps+0x18bf6  +0x18bf6..+0x18bf8 (0xecfdb4, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xecfdb4 not derived; readers below
; [nakarest] Readers: source references PmemMode_Select (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (PmemMode_Select_Data:24)`), PmemMode_Select_DrawHighlight1
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (PmemMode_Select_Data:24)`).
PmemMode_Select_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18BF6, 0x2
; [nakarest] SeqChan_Map_10ch  +0x18bf8..+0x18c02 (0xecfdb6, 10 B)
; [nakarest] purpose not established: layout of 10 B at 0xecfdb6 not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long SeqChan_Map_10ch`),
; [nakarest] PmBank_BankChanged_Lookup (display/graphics_text_vga.s: `lda xbc,
; [nakarest] (SeqChan_Map_10ch:24)`), PmBank_Select (display/graphics_text_vga.s: `lda xbc,
; [nakarest] (SeqChan_Map_10ch:24)`), PmBank_Select_DrawFirstRow (display/graphics_text_vga.s:
; [nakarest] `lda xbc, (SeqChan_Map_10ch:24)`); 1 data word in Naka_DrawbarReg_Table (at
; [nakarest] 0xeef5c8).
SeqChan_Map_10ch:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18BF8, 0xA
; [nakarest] SeqChan_Map_8ch  +0x18c02..+0x18c0a (0xecfdc0, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xecfdc0 not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long SeqChan_Map_8ch`); 1 data word
; [nakarest] in Naka_DrawbarReg_Table (at 0xeef5c4).
SeqChan_Map_8ch:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C02, 0x8
; [nakarest] SeqChan_Map_6ch  +0x18c0a..+0x18c10 (0xecfdc8, 6 B)
; [nakarest] purpose not established: layout of 6 B at 0xecfdc8 not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long SeqChan_Map_6ch`); 1 data word
; [nakarest] in Naka_DrawbarReg_Table (at 0xeef5c0).
SeqChan_Map_6ch:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C0A, 0x6
; [nakarest] SeqChan_Map_4ch  +0x18c10..+0x18c14 (0xecfdce, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xecfdce not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long SeqChan_Map_4ch`); 1 data word
; [nakarest] in Naka_DrawbarReg_Table (at 0xeef5bc).
SeqChan_Map_4ch:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C10, 0x4
; [nakarest] SeqChan_Map_2ch  +0x18c14..+0x18c16 (0xecfdd2, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xecfdd2 not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long SeqChan_Map_2ch`); 1 data word
; [nakarest] in Naka_DrawbarReg_Table (at 0xeef5b8).
SeqChan_Map_2ch:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C14, 0x2
; [nakarest] naka_style_bitmaps+0x18c16  +0x18c16..+0x18c22 (0xecfdd4, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xecfdd4 not derived; readers below
; [nakarest] Readers: source references RVari_Confirm_TypeF_SubItems (ui/rvari_routines.s: `lda
; [nakarest] xhl, (RVari_Select_CheckSameBank_PtrTable:24)`), RVari_Select_CheckSameBank (ui/ui_mode_handlers.s:
; [nakarest] `lda xhl, (RVari_Select_CheckSameBank_PtrTable:24)`).
RVari_Select_CheckSameBank_PtrTable:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C16, 0xC	; 3 x 32-bit pointer
; [nakarest] NakaInst_MEMORY_C_ECFDE0  +0x18c22..+0x18c2c (0xecfde0, 10 B)
; [nakarest] Text (10 B at 0xecfde0), first string "MEMORY-C"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in RVari_Select_CheckSameBank_PtrTable (at 0xecfddc), which is
; [nakarest] read by RVari_Confirm_TypeF_SubItems (ui/rvari_routines.s: `lda xhl,
; [nakarest] (RVari_Select_CheckSameBank_PtrTable:24)`), RVari_Select_CheckSameBank (ui/ui_mode_handlers.s: `lda
; [nakarest] xhl, (RVari_Select_CheckSameBank_PtrTable:24)`).
NakaInst_MEMORY_C_ECFDE0:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C22, 0xA
; [nakarest] NakaInst_MEMORY_B_ECFDEA  +0x18c2c..+0x18c36 (0xecfdea, 10 B)
; [nakarest] Text (10 B at 0xecfdea), first string "MEMORY-B"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in RVari_Select_CheckSameBank_PtrTable (at 0xecfdd8), which is
; [nakarest] read by RVari_Confirm_TypeF_SubItems (ui/rvari_routines.s: `lda xhl,
; [nakarest] (RVari_Select_CheckSameBank_PtrTable:24)`), RVari_Select_CheckSameBank (ui/ui_mode_handlers.s: `lda
; [nakarest] xhl, (RVari_Select_CheckSameBank_PtrTable:24)`).
NakaInst_MEMORY_B_ECFDEA:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C2C, 0xA
; [nakarest] NakaInst_MEMORY_A_ECFDF4  +0x18c36..+0x18c40 (0xecfdf4, 10 B)
; [nakarest] Text (10 B at 0xecfdf4), first string "MEMORY-A"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in RVari_Select_CheckSameBank_PtrTable (at 0xecfdd4), which is
; [nakarest] read by RVari_Confirm_TypeF_SubItems (ui/rvari_routines.s: `lda xhl,
; [nakarest] (RVari_Select_CheckSameBank_PtrTable:24)`), RVari_Select_CheckSameBank (ui/ui_mode_handlers.s: `lda
; [nakarest] xhl, (RVari_Select_CheckSameBank_PtrTable:24)`).
NakaInst_MEMORY_A_ECFDF4:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C36, 0xA
; [nakarest] naka_style_bitmaps+0x18c40  +0x18c40..+0x18d22 (0xecfdfe, 226 B)
; [nakarest] Text (226 B at 0xecfdfe), first string "RIGHT1 RIGHT2 LEFT PART4 PART5 PART6 PART7
; [nakarest] "; no registered NAKA table points into it; reached through source references
; [nakarest] VariScreenProc_OnDraw (ui/ui_mode_handlers.s: `lda xhl,
; [nakarest] (VariScreen_HandlePaint_Data:24)`).
VariScreen_HandlePaint_Data:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C40, 0xE2
; [nakarest] Naka_MemoryC_Screens  +0x18d22..+0x18d62 (0xecfee0, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecfee0 not derived; readers below
; [nakarest] Readers: source references MainChordPre (kn5000_v10_program.s: `lda xbc,
; [nakarest] (Naka_MemoryC_Screens:24)`).
Naka_MemoryC_Screens:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D22, 0x40
; [nakarest] MemScreen_Space1  +0x18d62..+0x18d66 (0xecff20, 4 B)
; [nakarest] Text (4 B at 0xecff20), first string " "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecff1c), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_Space1:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D62, 0x4
; [nakarest] MemScreen_Space2  +0x18d66..+0x18d6a (0xecff24, 4 B)
; [nakarest] Text (4 B at 0xecff24), first string " "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecff18), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_Space2:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D66, 0x4
; [nakarest] MemScreen_Space3  +0x18d6a..+0x18d6e (0xecff28, 4 B)
; [nakarest] Text (4 B at 0xecff28), first string " "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecff14), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_Space3:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D6A, 0x4
; [nakarest] MemScreen_NoteB  +0x18d6e..+0x18d72 (0xecff2c, 4 B)
; [nakarest] Text (4 B at 0xecff2c), first string "B "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecff10), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteB:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D6E, 0x4
; [nakarest] NakaInst_B_a0  +0x18d72..+0x18d78 (0xecff30, 6 B)
; [nakarest] Text (6 B at 0xecff30), first string "B~a0"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_MemoryC_Screens (at 0xecff0c), which is
; [nakarest] read by MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
NakaInst_B_a0:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D72, 0x6
; [nakarest] MemScreen_NoteA_Str  +0x18d78..+0x18d7c (0xecff36, 4 B)
; [nakarest] Text (4 B at 0xecff36), first string "A "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecff08), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteA_Str:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D78, 0x4
; [nakarest] NakaInst_A_a0  +0x18d7c..+0x18d82 (0xecff3a, 6 B)
; [nakarest] Text (6 B at 0xecff3a), first string "A~a0"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_MemoryC_Screens (at 0xecff04), which is
; [nakarest] read by MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
NakaInst_A_a0:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D7C, 0x6
; [nakarest] MemScreen_NoteG  +0x18d82..+0x18d86 (0xecff40, 4 B)
; [nakarest] Text (4 B at 0xecff40), first string "G "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecff00), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteG:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D82, 0x4
; [nakarest] NakaInst_F_9e_ECFF44  +0x18d86..+0x18d8c (0xecff44, 6 B)
; [nakarest] Text (6 B at 0xecff44), first string "F~9e"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_MemoryC_Screens (at 0xecfefc), which is
; [nakarest] read by MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
NakaInst_F_9e_ECFF44:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D86, 0x6
; [nakarest] MemScreen_NoteF  +0x18d8c..+0x18d90 (0xecff4a, 4 B)
; [nakarest] Text (4 B at 0xecff4a), first string "F "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecfef8), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteF:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D8C, 0x4
; [nakarest] MemScreen_NoteE_Str  +0x18d90..+0x18d94 (0xecff4e, 4 B)
; [nakarest] Text (4 B at 0xecff4e), first string "E "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecfef4), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteE_Str:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D90, 0x4
; [nakarest] NakaInst_E_a0_ECFF52  +0x18d94..+0x18d9a (0xecff52, 6 B)
; [nakarest] Text (6 B at 0xecff52), first string "E~a0"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_MemoryC_Screens (at 0xecfef0), which is
; [nakarest] read by MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
NakaInst_E_a0_ECFF52:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D94, 0x6
; [nakarest] MemScreen_NoteD  +0x18d9a..+0x18d9e (0xecff58, 4 B)
; [nakarest] Text (4 B at 0xecff58), first string "D "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecfeec), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteD:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D9A, 0x4
; [nakarest] NakaInst_D_a0_ECFF5C  +0x18d9e..+0x18da4 (0xecff5c, 6 B)
; [nakarest] Text (6 B at 0xecff5c), first string "D~a0"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_MemoryC_Screens (at 0xecfee8), which is
; [nakarest] read by MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
NakaInst_D_a0_ECFF5C:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D9E, 0x6
; [nakarest] MemScreen_NoteC  +0x18da4..+0x18da8 (0xecff62, 4 B)
; [nakarest] Text (4 B at 0xecff62), first string "C "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecfee4), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteC:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18DA4, 0x4
; [nakarest] MemScreen_Blank  +0x18da8..+0x18dac (0xecff66, 4 B)
; [nakarest] Text (4 B at 0xecff66), first string " "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecfee0), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_Blank:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18DA8, 0x4
; [nakarest] naka_style_bitmaps+0x18dac  +0x18dac..+0x18e42 (0xecff6a, 150 B)
; [nakarest] purpose not established: layout of 150 B at 0xecff6a not derived; readers below
; [nakarest] Readers: source references MainChordPre (kn5000_v10_program.s: `lda xbc,
; [nakarest] (0xecff6a:24)`).
MainChordPre_PtrTable:	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18DAC, 0x96	; 64 x 32-bit pointer
; [nakarest] naka_style_bitmaps+0x18e42  +0x18e42..+0x18e4a (0xed0000, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xed0000 not derived; readers below
; [nakarest] Readers: source references InitializeSuna (storage/flash_floppy_handlers.s:
; [nakarest] `RegTitle 0x4, 0xe1, 0xca64, 0xed, 0x1200000, 0xed0000`); 1 data word in
; [nakarest] AcWelcomScreenProc_Data (at 0xe9e514), which is read by AcWelcomScreenProc
; [nakarest] (ui/drawbar_panel_ui.s: `ld xwa, AcWelcomScreenProc_Data`); 1 data word in
; [nakarest] AcWelcomScreenProc_Data_2 (at 0xe9edcc), which is read by AcWelcomScreenProc
; [nakarest] (ui/drawbar_panel_ui.s: `ld xwa, AcWelcomScreenProc_Data_2`); 2 data words in
; [nakarest] Naka_KeyScaling_NavTrail (at 0xe8303c, 0xe846c6), which is read by
; [nakarest] CharMap_ValueData_B (ui_widgets/widget_dispatch.s: `.long
; [nakarest] Naka_KeyScaling_NavTrail`).
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18E42, 0x8
; External label offsets within the binary blob above.
.include "extensions/extension_data.s"
