
; Style Bitmaps, Presentation Data & UI Dispatch (2 widgets, 101962 bytes)
; Source: maincpu/ui_widgets/naka_style_bitmaps.c (raw byte array)
; [nakarest] NakaData_StyleBitmaps  +0x0..+0xa (0xeb71be, 10 B)
; [nakarest] Text (10 B at 0xeb71be), first string "iduToshi"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaProp_Frame_Chain (at 0xeb7108).
NakaData_StyleBitmaps:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x0, 0xA
; [nakarest] NakaInst_iduMurai  +0xa..+0x14 (0xeb71c8, 10 B)
; [nakarest] Text (10 B at 0xeb71c8), first string "iduMurai"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaProp_Frame_Chain (at 0xeb7100).
NakaInst_iduMurai:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xA, 0xA
; [nakarest] NakaInst_iduRoot  +0x14..+0x1c (0xeb71d2, 8 B)
; [nakarest] Text (8 B at 0xeb71d2), first string "iduRoot"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaProp_Frame_Chain (at 0xeb70f8).
NakaInst_iduRoot:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14, 0x8
; [nakarest] NakaInst_False_EB71DA  +0x1c..+0x4a (0xeb71da, 46 B)
; [nakarest] purpose not established: layout of 46 B at 0xeb71da not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb78a8, 0xeb78b4), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaInst_False_EB71DA:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1C, 0x2E
; [nakarest] NakaInst_pSword_EmptyStr  +0x4a..+0x4c (0xeb7208, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeb7208 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_False_EB71DA (at 0xeb7200).
NakaInst_pSword_EmptyStr:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4A, 0x2
; [nakarest] NakaInst_pUword_FormatData  +0x4c..+0x60 (0xeb720a, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb720a not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb78c0, 0xeb78cc), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaInst_pUword_FormatData:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4C, 0x14
; [nakarest] NakaInst_pUchar_FormatData  +0x60..+0x72 (0xeb721e, 18 B)
; [nakarest] purpose not established: layout of 18 B at 0xeb721e not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb78d8, 0xeb78e4), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaInst_pUchar_FormatData:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x60, 0x12
; [nakarest] NakaInst_pSlong_EmptyStr  +0x72..+0x74 (0xeb7230, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeb7230 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_pUchar_FormatData (at 0xeb7228).
NakaInst_pSlong_EmptyStr:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x72, 0x2
; [nakarest] NakaInst_pUlong_FormatData  +0x74..+0x88 (0xeb7232, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb7232 not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb78f0, 0xeb78fc), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaInst_pUlong_FormatData:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x74, 0x14
; [nakarest] NakaInst_PartID_EnumTable  +0x88..+0x33a (0xeb7246, 690 B)
; [nakarest] purpose not established: layout of 690 B at 0xeb7246 not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_WindowID_Cont (at 0xeb7908, 0xeb7914), which is
; [nakarest] read by FileIO_ByteBlock_DemoProc1_Skip16 (demo/file_demo_proc.s: `.long
; [nakarest] NakaInst_WindowID_Cont`).
NakaInst_PartID_EnumTable:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x88, 0x2B2
; [nakarest] NakaInst_TrackID_EmptyStr  +0x33a..+0x33c (0xeb74f8, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeb74f8 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_PartID_EnumTable (at 0xeb74f0).
NakaInst_TrackID_EmptyStr:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x33A, 0x2
; [nakarest] NakaInst_TR_All  +0x33c..+0x344 (0xeb74fa, 8 B)
; [nakarest] Text (8 B at 0xeb74fa), first string "TR_All"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74e8).
NakaInst_TR_All:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x33C, 0x8
; [nakarest] NakaInst_TR_Track16  +0x344..+0x350 (0xeb7502, 12 B)
; [nakarest] Text (12 B at 0xeb7502), first string "TR_Track16"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74e0).
NakaInst_TR_Track16:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x344, 0xC
; [nakarest] NakaInst_TR_Track15  +0x350..+0x35c (0xeb750e, 12 B)
; [nakarest] Text (12 B at 0xeb750e), first string "TR_Track15"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74d8).
NakaInst_TR_Track15:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x350, 0xC
; [nakarest] NakaInst_TR_Track14  +0x35c..+0x368 (0xeb751a, 12 B)
; [nakarest] Text (12 B at 0xeb751a), first string "TR_Track14"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74d0).
NakaInst_TR_Track14:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x35C, 0xC
; [nakarest] NakaInst_TR_Track13  +0x368..+0x374 (0xeb7526, 12 B)
; [nakarest] Text (12 B at 0xeb7526), first string "TR_Track13"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74c8).
NakaInst_TR_Track13:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x368, 0xC
; [nakarest] NakaInst_TR_Track12  +0x374..+0x380 (0xeb7532, 12 B)
; [nakarest] Text (12 B at 0xeb7532), first string "TR_Track12"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74c0).
NakaInst_TR_Track12:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x374, 0xC
; [nakarest] NakaInst_TR_Track11  +0x380..+0x38c (0xeb753e, 12 B)
; [nakarest] Text (12 B at 0xeb753e), first string "TR_Track11"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74b8).
NakaInst_TR_Track11:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x380, 0xC
; [nakarest] NakaInst_TR_Track10  +0x38c..+0x398 (0xeb754a, 12 B)
; [nakarest] Text (12 B at 0xeb754a), first string "TR_Track10"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74b0).
NakaInst_TR_Track10:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x38C, 0xC
; [nakarest] NakaInst_TR_Track9  +0x398..+0x3a2 (0xeb7556, 10 B)
; [nakarest] Text (10 B at 0xeb7556), first string "TR_Track9"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74a8).
NakaInst_TR_Track9:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x398, 0xA
; [nakarest] NakaInst_TR_Track8  +0x3a2..+0x3ac (0xeb7560, 10 B)
; [nakarest] Text (10 B at 0xeb7560), first string "TR_Track8"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb74a0).
NakaInst_TR_Track8:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3A2, 0xA
; [nakarest] NakaInst_TR_Track7  +0x3ac..+0x3b6 (0xeb756a, 10 B)
; [nakarest] Text (10 B at 0xeb756a), first string "TR_Track7"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7498).
NakaInst_TR_Track7:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3AC, 0xA
; [nakarest] NakaInst_TR_Track6  +0x3b6..+0x3c0 (0xeb7574, 10 B)
; [nakarest] Text (10 B at 0xeb7574), first string "TR_Track6"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7490).
NakaInst_TR_Track6:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3B6, 0xA
; [nakarest] NakaInst_TR_Track5  +0x3c0..+0x3ca (0xeb757e, 10 B)
; [nakarest] Text (10 B at 0xeb757e), first string "TR_Track5"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7488).
NakaInst_TR_Track5:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3C0, 0xA
; [nakarest] NakaInst_TR_Track4  +0x3ca..+0x3d4 (0xeb7588, 10 B)
; [nakarest] Text (10 B at 0xeb7588), first string "TR_Track4"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7480).
NakaInst_TR_Track4:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3CA, 0xA
; [nakarest] NakaInst_TR_Track3  +0x3d4..+0x3de (0xeb7592, 10 B)
; [nakarest] Text (10 B at 0xeb7592), first string "TR_Track3"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7478).
NakaInst_TR_Track3:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3D4, 0xA
; [nakarest] NakaInst_TR_Track2  +0x3de..+0x3e8 (0xeb759c, 10 B)
; [nakarest] Text (10 B at 0xeb759c), first string "TR_Track2"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7470).
NakaInst_TR_Track2:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3DE, 0xA
; [nakarest] NakaInst_TR_Track1  +0x3e8..+0x3f2 (0xeb75a6, 10 B)
; [nakarest] Text (10 B at 0xeb75a6), first string "TR_Track1"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_PartID_EnumTable (at 0xeb7468).
NakaInst_TR_Track1:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3E8, 0xA
; [nakarest] NakaInst_IntTimeID_EnumTable  +0x3f2..+0x462 (0xeb75b0, 112 B)
; [nakarest] purpose not established: layout of 112 B at 0xeb75b0 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_WindowID_Cont (at 0xeb7920), which is read by
; [nakarest] FileIO_ByteBlock_DemoProc1_Skip16 (demo/file_demo_proc.s: `.long
; [nakarest] NakaInst_WindowID_Cont`).
NakaInst_IntTimeID_EnumTable:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x3F2, 0x70
; [nakarest] NakaInst_IntTimeID_EmptyStr  +0x462..+0x464 (0xeb7620, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeb7620 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb7618).
NakaInst_IntTimeID_EmptyStr:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x462, 0x2
; [nakarest] NakaInst_IT_10Sec  +0x464..+0x46e (0xeb7622, 10 B)
; [nakarest] Text (10 B at 0xeb7622), first string "IT_10Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb7610).
NakaInst_IT_10Sec:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x464, 0xA
; [nakarest] NakaInst_IT_9Sec  +0x46e..+0x476 (0xeb762c, 8 B)
; [nakarest] Text (8 B at 0xeb762c), first string "IT_9Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb7608).
NakaInst_IT_9Sec:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x46E, 0x8
; [nakarest] NakaInst_IT_8Sec  +0x476..+0x47e (0xeb7634, 8 B)
; [nakarest] Text (8 B at 0xeb7634), first string "IT_8Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb7600).
NakaInst_IT_8Sec:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x476, 0x8
; [nakarest] NakaInst_IT_7Sec  +0x47e..+0x486 (0xeb763c, 8 B)
; [nakarest] Text (8 B at 0xeb763c), first string "IT_7Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75f8).
NakaInst_IT_7Sec:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x47E, 0x8
; [nakarest] NakaInst_IT_6Sec  +0x486..+0x48e (0xeb7644, 8 B)
; [nakarest] Text (8 B at 0xeb7644), first string "IT_6Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75f0).
NakaInst_IT_6Sec:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x486, 0x8
; [nakarest] NakaInst_IT_5Sec  +0x48e..+0x496 (0xeb764c, 8 B)
; [nakarest] Text (8 B at 0xeb764c), first string "IT_5Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75e8).
NakaInst_IT_5Sec:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x48E, 0x8
; [nakarest] NakaInst_IT_4Sec  +0x496..+0x49e (0xeb7654, 8 B)
; [nakarest] Text (8 B at 0xeb7654), first string "IT_4Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75e0).
NakaInst_IT_4Sec:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x496, 0x8
; [nakarest] NakaInst_IT_3Sec  +0x49e..+0x4a6 (0xeb765c, 8 B)
; [nakarest] Text (8 B at 0xeb765c), first string "IT_3Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75d8).
NakaInst_IT_3Sec:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x49E, 0x8
; [nakarest] NakaInst_IT_2Sec  +0x4a6..+0x4ae (0xeb7664, 8 B)
; [nakarest] Text (8 B at 0xeb7664), first string "IT_2Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75d0).
NakaInst_IT_2Sec:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4A6, 0x8
; [nakarest] NakaInst_IT_1Sec  +0x4ae..+0x4b6 (0xeb766c, 8 B)
; [nakarest] Text (8 B at 0xeb766c), first string "IT_1Sec"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75c8).
NakaInst_IT_1Sec:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4AE, 0x8
; [nakarest] NakaInst_IT_Hold  +0x4b6..+0x4be (0xeb7674, 8 B)
; [nakarest] Text (8 B at 0xeb7674), first string "IT_Hold"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75c0).
NakaInst_IT_Hold:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4B6, 0x8
; [nakarest] NakaInst_IT_Default  +0x4be..+0x4ca (0xeb767c, 12 B)
; [nakarest] Text (12 B at 0xeb767c), first string "IT_Default"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in NakaInst_IntTimeID_EnumTable (at 0xeb75b8).
NakaInst_IT_Default:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4BE, 0xC
; [nakarest] NakaInst_IT_Off  +0x4ca..+0x741 (0xeb7688, 631 B)
; [nakarest] purpose not established: layout of 631 B at 0xeb7688 not derived; readers below
; [nakarest] Readers: source references ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (NakaInst_IT_Off_0x8:24)`); 1 data word in NakaInst_IntTimeID_EnumTable (at
; [nakarest] 0xeb75b0).
NakaInst_IT_Off:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4CA, 0x277
; [nakarest] NakaInst_WindowID_Cont  +0x741..+0x774 (0xeb78ff, 51 B)
; [nakarest] purpose not established: layout of 51 B at 0xeb78ff not derived; readers below
; [nakarest] Readers: source references FileIO_ByteBlock_DemoProc1_Skip16
; [nakarest] (demo/file_demo_proc.s: `.long NakaInst_WindowID_Cont`).
NakaInst_WindowID_Cont:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x741, 0x33
; [nakarest] WidgetStyleDataTable  +0x774..+0xeb4 (0xeb7932, 1856 B)
; [nakarest] purpose not established: layout of 1856 B at 0xeb7932 not derived; readers below
; [nakarest] Readers: source references BitMapOut_CopyPreset9_Execute (ui/bitmap_out_routines.s:
; [nakarest] `lda xbc, (WidgetStyleDataTable_0x10:24)`), BitMapOut_CopyROMToWorkspace
; [nakarest] (ui/bitmap_out_routines.s: `lda xbc, (WidgetStyleDataTable_0x10:24)`),
; [nakarest] BitMapOut_DeltaEncode_Type90Final (ui/bitmap_out_routines.s: `ld xde,
; [nakarest] WidgetStyleDataTable_0x154`), BitMapOut_RestoreFullVoice (ui/bitmap_out_routines.s:
; [nakarest] `lda xbc, (WidgetStyleDataTable_0x10:24)`), 20 more; 1 data word in
; [nakarest] SystemConfig_PointerTable (at 0xee8c9e), which is read by ScreenGroup_WidgetLoop
; [nakarest] (boot/screen_group_dispatch.s: `ld xbc, SystemConfig_PointerTable`),
; [nakarest] VoiceInit_Dispatch (boot/screen_group_dispatch.s: `ld xbc,
; [nakarest] SystemConfig_PointerTable`).
WidgetStyleDataTable:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x774, 0x740
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
Bitmap_FadeInPicture:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEB4, 0xAF0
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
Bitmap_FadeInText:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x19A4, 0x5A0
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
Bitmap_FadeOutPicture:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1F44, 0xB22
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
Bitmap_FadeOutText:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x2A66, 0x870
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
; underflow reads entry 999 through StyleSong_MasterTable_0x176a (=
; +999*6, .set in shared/positional_labels.s), which is how the count is
; pinned. The cell-select paths of MasterSetup and
; MstStyleAlp_EventDispatch load the u16 at +4 of entry 9*(page-1) +
; scroll + row (StyleSong_MasterTable_0x4, 9 rows per page) and hand it
; to MainFuncCall with 0x142000d / 0x1e20018. Checked here: the 1000
; title pointers are exactly the 1000 entries of StyleSong_Titles (entry
; k of this table -> title 999-k), and the ids are 0..999, each once.
; What the id selects on the 0x142000d side was not traced.
;
; Typed in naka_style_bitmaps.c as mst_title_ref_t
; StyleSong_MasterTable[1000] (a local typedef).
; -----------------------------------------------------------------------------
StyleSong_MasterTable:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x32D6, 0x1770
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
StyleSong_Titles:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x4A46, 0x84D0
; [nakarest] StyleVar_GermanSchlager  +0xcf16..+0xcf56 (0xec40d4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec40d4 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_ModernDance_Table (at 0xece2f4).
StyleVar_GermanSchlager:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xCF16, 0x40
; [nakarest] NakaInst_Orchestral_Eight_108  +0xcf56..+0xcfbc (0xec4114, 102 B)
; [nakarest] Text (102 B at 0xec4114), first string "Orchestral Eight 108"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_GermanSchlager (at
; [nakarest] 0xec40e0, 0xec40da, 0xec40d4).
NakaInst_Orchestral_Eight_108:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xCF56, 0x66
; [nakarest] StyleVar_EasyPlay8Beat  +0xcfbc..+0xd01e (0xec417a, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec417a not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_ModernDance_Table (at 0xece2fc).
StyleVar_EasyPlay8Beat:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xCFBC, 0x62
; [nakarest] NakaInst_Easy_EP_90  +0xd01e..+0xd062 (0xec41dc, 68 B)
; [nakarest] Text (68 B at 0xec41dc), first string "Easy EP! 90"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_EasyPlay8Beat (at
; [nakarest] 0xec4180, 0xec417a).
NakaInst_Easy_EP_90:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD01E, 0x44
; [nakarest] StyleVar_RockAfterEight  +0xd062..+0xd0e6 (0xec4220, 132 B)
; [nakarest] Text (132 B at 0xec4220), first string "\xA4B\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece304).
StyleVar_RockAfterEight:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD062, 0x84
; [nakarest] NakaInst_Vocal_Beats_108  +0xd0e6..+0xd108 (0xec42a4, 34 B)
; [nakarest] Text (34 B at 0xec42a4), first string "Vocal Beats 108"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_RockAfterEight (at
; [nakarest] 0xec4220).
NakaInst_Vocal_Beats_108:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD0E6, 0x22
; [nakarest] StyleVar_OrchestralBeat  +0xd108..+0xd126 (0xec42c6, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec42c6 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_ModernDance_Table (at 0xece30c).
StyleVar_OrchestralBeat:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD108, 0x1E
; [nakarest] NakaInst_Cool_Rock_106  +0xd126..+0xd1ae (0xec42e4, 136 B)
; [nakarest] Text (136 B at 0xec42e4), first string "Cool Rock 106"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in StyleVar_OrchestralBeat (at
; [nakarest] 0xec42d8, 0xec42d2, 0xec42cc).
NakaInst_Cool_Rock_106:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD126, 0x88
; [nakarest] StyleVar_SmoothRock  +0xd1ae..+0xd1ee (0xec436c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec436c not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_ModernDance_Table (at 0xece314).
StyleVar_SmoothRock:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD1AE, 0x40
; [nakarest] NakaInst_Dream_Beat_114  +0xd1ee..+0xd254 (0xec43ac, 102 B)
; [nakarest] Text (102 B at 0xec43ac), first string "Dream Beat 114"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_SmoothRock (at 0xec4378,
; [nakarest] 0xec4372, 0xec436c).
NakaInst_Dream_Beat_114:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD1EE, 0x66
; [nakarest] StyleVar_GreatestHits  +0xd254..+0xd2b6 (0xec4412, 98 B)
; [nakarest] Text (98 B at 0xec4412), first string "\x96D\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece31c).
StyleVar_GreatestHits:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD254, 0x62
; [nakarest] NakaInst_Paradise_Keys_90  +0xd2b6..+0xd2fa (0xec4474, 68 B)
; [nakarest] Text (68 B at 0xec4474), first string "Paradise Keys 90"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_GreatestHits (at 0xec4418,
; [nakarest] 0xec4412).
NakaInst_Paradise_Keys_90:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD2B6, 0x44
; [nakarest] StyleVar_Studio8Beat  +0xd2fa..+0xd37e (0xec44b8, 132 B)
; [nakarest] Text (132 B at 0xec44b8), first string "<E\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece324).
StyleVar_Studio8Beat:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD2FA, 0x84
; [nakarest] NakaInst_Acoustic_Effects_86  +0xd37e..+0xd3a0 (0xec453c, 34 B)
; [nakarest] Text (34 B at 0xec453c), first string "Acoustic Effects 86"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_Studio8Beat (at
; [nakarest] 0xec44b8).
NakaInst_Acoustic_Effects_86:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD37E, 0x22
; [nakarest] StyleVar_BalladProducer  +0xd3a0..+0xd3be (0xec455e, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec455e not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_ModernDance_Table (at 0xece32c).
StyleVar_BalladProducer:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD3A0, 0x1E
; [nakarest] NakaInst_Sax_For_Whitney_84  +0xd3be..+0xd446 (0xec457c, 136 B)
; [nakarest] Text (136 B at 0xec457c), first string "Sax For Whitney 84"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_BalladProducer (at
; [nakarest] 0xec4570, 0xec456a, 0xec4564).
NakaInst_Sax_For_Whitney_84:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD3BE, 0x88
; [nakarest] StyleVar_LoveSongs  +0xd446..+0xd486 (0xec4604, 64 B)
; [nakarest] Text (64 B at 0xec4604), first string "\x88F\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece334).
StyleVar_LoveSongs:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD446, 0x40
; [nakarest] NakaInst_Warm_Horn_Duet_72  +0xd486..+0xd4ec (0xec4644, 102 B)
; [nakarest] Text (102 B at 0xec4644), first string "Warm Horn Duet 72"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_LoveSongs (at
; [nakarest] 0xec4610, 0xec460a, 0xec4604).
NakaInst_Warm_Horn_Duet_72:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD486, 0x66
; [nakarest] StyleVar_16BeatGroove  +0xd4ec..+0xd54e (0xec46aa, 98 B)
; [nakarest] Text (98 B at 0xec46aa), first string ".G\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece33c).
StyleVar_16BeatGroove:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD4EC, 0x62
; [nakarest] NakaInst_New_Muzak_82  +0xd54e..+0xd592 (0xec470c, 68 B)
; [nakarest] Text (68 B at 0xec470c), first string "New Muzak 82"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_16BeatGroove (at 0xec46b0,
; [nakarest] 0xec46aa).
NakaInst_New_Muzak_82:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD54E, 0x44
; [nakarest] StyleVar_EasyPlay16Beat  +0xd592..+0xd616 (0xec4750, 132 B)
; [nakarest] Text (132 B at 0xec4750), first string "\xD4G\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece344).
StyleVar_EasyPlay16Beat:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD592, 0x84
; [nakarest] NakaInst_Solid_Sixteen_74  +0xd616..+0xd638 (0xec47d4, 34 B)
; [nakarest] Text (34 B at 0xec47d4), first string "Solid Sixteen 74"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_EasyPlay16Beat (at
; [nakarest] 0xec4750).
NakaInst_Solid_Sixteen_74:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD616, 0x22
; [nakarest] StyleVar_EPMoments  +0xd638..+0xd656 (0xec47f6, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec47f6 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_ModernDance_Table (at 0xece34c).
StyleVar_EPMoments:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD638, 0x1E
; [nakarest] NakaInst_The_Way_It_Is_70  +0xd656..+0xd6de (0xec4814, 136 B)
; [nakarest] Text (136 B at 0xec4814), first string "The Way It Is 70"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in StyleVar_EPMoments (at 0xec4808,
; [nakarest] 0xec4802, 0xec47fc).
NakaInst_The_Way_It_Is_70:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD656, 0x88
; [nakarest] StyleVar_Gentle16Beat  +0xd6de..+0xd71e (0xec489c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec489c not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_ModernDance_Table (at 0xece354).
StyleVar_Gentle16Beat:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD6DE, 0x40
; [nakarest] NakaInst_Orchestral_16_82  +0xd71e..+0xd784 (0xec48dc, 102 B)
; [nakarest] Text (102 B at 0xec48dc), first string "Orchestral 16 82"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_Gentle16Beat (at 0xec48a8,
; [nakarest] 0xec48a2, 0xec489c).
NakaInst_Orchestral_16_82:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD71E, 0x66
; [nakarest] StyleVar_Atmospheric16  +0xd784..+0xd7e6 (0xec4942, 98 B)
; [nakarest] Text (98 B at 0xec4942), first string "\xC6I\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece35c).
StyleVar_Atmospheric16:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD784, 0x62
; [nakarest] NakaInst_Ballad_Romance_67_EC49A4  +0xd7e6..+0xd82a (0xec49a4, 68 B)
; [nakarest] Text (68 B at 0xec49a4), first string "Ballad Romance 67"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_Atmospheric16 (at
; [nakarest] 0xec4948, 0xec4942).
NakaInst_Ballad_Romance_67_EC49A4:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD7E6, 0x44
; [nakarest] StyleVar_SynthBallad  +0xd82a..+0xd8ae (0xec49e8, 132 B)
; [nakarest] Text (132 B at 0xec49e8), first string "lJ\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece364).
StyleVar_SynthBallad:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD82A, 0x84
; [nakarest] NakaInst_Gentle_Ballad_75_EC4A6C  +0xd8ae..+0xd8d0 (0xec4a6c, 34 B)
; [nakarest] Text (34 B at 0xec4a6c), first string "Gentle Ballad 75"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_SynthBallad (at 0xec49e8).
NakaInst_Gentle_Ballad_75_EC4A6C:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD8AE, 0x22
; [nakarest] StyleVar_GrandsOnStage  +0xd8d0..+0xd8ee (0xec4a8e, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec4a8e not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_ModernDance_Table (at 0xece36c).
StyleVar_GrandsOnStage:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD8D0, 0x1E
; [nakarest] NakaInst_Clavier_Francais_80  +0xd8ee..+0xd976 (0xec4aac, 136 B)
; [nakarest] Text (136 B at 0xec4aac), first string "Clavier Francais 80"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_GrandsOnStage (at
; [nakarest] 0xec4aa0, 0xec4a9a, 0xec4a94).
NakaInst_Clavier_Francais_80:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD8EE, 0x88
; [nakarest] StyleVar_ModernBallads  +0xd976..+0xd9b6 (0xec4b34, 64 B)
; [nakarest] Text (64 B at 0xec4b34), first string "\xB8K\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece374).
StyleVar_ModernBallads:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD976, 0x40
; [nakarest] NakaInst_Synth_Love_Song_84  +0xd9b6..+0xda1c (0xec4b74, 102 B)
; [nakarest] Text (102 B at 0xec4b74), first string "Synth Love Song 84"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_ModernBallads (at
; [nakarest] 0xec4b40, 0xec4b3a, 0xec4b34).
NakaInst_Synth_Love_Song_84:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xD9B6, 0x66
; [nakarest] StyleVar_NightClubDance  +0xda1c..+0xda7e (0xec4bda, 98 B)
; [nakarest] Text (98 B at 0xec4bda), first string "^L\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece37c).
StyleVar_NightClubDance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDA1C, 0x62
; [nakarest] NakaInst_String_Romance_72  +0xda7e..+0xdac2 (0xec4c3c, 68 B)
; [nakarest] Text (68 B at 0xec4c3c), first string "String Romance 72"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_NightClubDance (at
; [nakarest] 0xec4be0, 0xec4bda).
NakaInst_String_Romance_72:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDA7E, 0x44
; [nakarest] StyleVar_50sLoveSongs  +0xdac2..+0xdb46 (0xec4c80, 132 B)
; [nakarest] Text (132 B at 0xec4c80), first string "M\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece384).
StyleVar_50sLoveSongs:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDAC2, 0x84
; [nakarest] NakaInst_Shuffle_Chanson_100  +0xdb46..+0xdb68 (0xec4d04, 34 B)
; [nakarest] Text (34 B at 0xec4d04), first string "Shuffle Chanson 100"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_50sLoveSongs (at
; [nakarest] 0xec4c80).
NakaInst_Shuffle_Chanson_100:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDB46, 0x22
; [nakarest] StyleVar_OldieBallads  +0xdb68..+0xdb86 (0xec4d26, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec4d26 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_ModernDance_Table (at 0xece38c).
StyleVar_OldieBallads:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDB68, 0x1E
; [nakarest] NakaInst_Flute_Nocturne_63  +0xdb86..+0xdc0e (0xec4d44, 136 B)
; [nakarest] Text (136 B at 0xec4d44), first string "Flute Nocturne 63"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_OldieBallads (at
; [nakarest] 0xec4d38, 0xec4d32, 0xec4d2c).
NakaInst_Flute_Nocturne_63:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDB86, 0x88
; [nakarest] StyleVar_SoftSchlager  +0xdc0e..+0xdc4e (0xec4dcc, 64 B)
; [nakarest] Text (64 B at 0xec4dcc), first string "PN\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece394).
StyleVar_SoftSchlager:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDC0E, 0x40
; [nakarest] NakaInst_Spacy_Ballad_64  +0xdc4e..+0xdcb4 (0xec4e0c, 102 B)
; [nakarest] Text (102 B at 0xec4e0c), first string "Spacy Ballad 64"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_SoftSchlager (at 0xec4dd8,
; [nakarest] 0xec4dd2, 0xec4dcc).
NakaInst_Spacy_Ballad_64:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDC4E, 0x66
; [nakarest] StyleVar_OldieDrawbars  +0xdcb4..+0xdd16 (0xec4e72, 98 B)
; [nakarest] Text (98 B at 0xec4e72), first string "\xF6N\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece39c).
StyleVar_OldieDrawbars:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDCB4, 0x62
; [nakarest] NakaInst_Oldie_s_Parade_125  +0xdd16..+0xdd5a (0xec4ed4, 68 B)
; [nakarest] Text (68 B at 0xec4ed4), first string "Oldie's Parade 125"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_OldieDrawbars (at
; [nakarest] 0xec4e78, 0xec4e72).
NakaInst_Oldie_s_Parade_125:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDD16, 0x44
; [nakarest] StyleVar_EuroBallads  +0xdd5a..+0xddde (0xec4f18, 132 B)
; [nakarest] Text (132 B at 0xec4f18), first string "\x9CO\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece3a4).
StyleVar_EuroBallads:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDD5A, 0x84
; [nakarest] NakaInst_Dreamy_Harmonica_68  +0xddde..+0xde00 (0xec4f9c, 34 B)
; [nakarest] Text (34 B at 0xec4f9c), first string "Dreamy Harmonica 68"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_EuroBallads (at
; [nakarest] 0xec4f18).
NakaInst_Dreamy_Harmonica_68:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDDDE, 0x22
; [nakarest] StyleVar_RomanticBand  +0xde00..+0xde1e (0xec4fbe, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec4fbe not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_ModernDance_Table (at 0xece3ac).
StyleVar_RomanticBand:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDE00, 0x1E
; [nakarest] NakaInst_Late_Night_Tenor_117  +0xde1e..+0xdea6 (0xec4fdc, 136 B)
; [nakarest] Text (136 B at 0xec4fdc), first string "Late Night Tenor 117"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_RomanticBand (at
; [nakarest] 0xec4fd0, 0xec4fca, 0xec4fc4).
NakaInst_Late_Night_Tenor_117:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDE1E, 0x88
; [nakarest] StyleVar_JazzSerenade  +0xdea6..+0xdee6 (0xec5064, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec5064 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_ModernDance_Table (at 0xece3b4).
StyleVar_JazzSerenade:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDEA6, 0x40
; [nakarest] NakaInst_Mellow_Mood_83  +0xdee6..+0xdf4c (0xec50a4, 102 B)
; [nakarest] Text (102 B at 0xec50a4), first string "Mellow Mood 83"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_JazzSerenade (at 0xec5070,
; [nakarest] 0xec506a, 0xec5064).
NakaInst_Mellow_Mood_83:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDEE6, 0x66
; [nakarest] StyleVar_NatsBallads  +0xdf4c..+0xdfae (0xec510a, 98 B)
; [nakarest] Text (98 B at 0xec510a), first string "\x8EQ\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece3bc).
StyleVar_NatsBallads:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDF4C, 0x62
; [nakarest] NakaInst_Sweet_Swing_90  +0xdfae..+0xdff2 (0xec516c, 68 B)
; [nakarest] Text (68 B at 0xec516c), first string "Sweet Swing 90"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_NatsBallads (at 0xec5110,
; [nakarest] 0xec510a).
NakaInst_Sweet_Swing_90:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDFAE, 0x44
; [nakarest] StyleVar_DrawbarCombo  +0xdff2..+0xe076 (0xec51b0, 132 B)
; [nakarest] Text (132 B at 0xec51b0), first string "4R\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece3c4).
StyleVar_DrawbarCombo:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xDFF2, 0x84
; [nakarest] NakaInst_Wunderlich_Combo_180  +0xe076..+0xe098 (0xec5234, 34 B)
; [nakarest] Text (34 B at 0xec5234), first string "Wunderlich Combo 180"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_DrawbarCombo (at
; [nakarest] 0xec51b0).
NakaInst_Wunderlich_Combo_180:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE076, 0x22
; [nakarest] StyleVar_ParisRomance  +0xe098..+0xe0b6 (0xec5256, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec5256 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_ModernDance_Table (at 0xece3cc).
StyleVar_ParisRomance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE098, 0x1E
; [nakarest] NakaInst_French_Clavier_92  +0xe0b6..+0xe13e (0xec5274, 136 B)
; [nakarest] Text (136 B at 0xec5274), first string "French Clavier 92"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_ParisRomance (at
; [nakarest] 0xec5268, 0xec5262, 0xec525c).
NakaInst_French_Clavier_92:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE0B6, 0x88
; [nakarest] StyleVar_EasyPlayWaltz  +0xe13e..+0xe17e (0xec52fc, 64 B)
; [nakarest] Text (64 B at 0xec52fc), first string "\x80S\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece3d4).
StyleVar_EasyPlayWaltz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE13E, 0x40
; [nakarest] NakaInst_Three_Four_Vibes_110  +0xe17e..+0xe1e4 (0xec533c, 102 B)
; [nakarest] Text (102 B at 0xec533c), first string "Three Four Vibes 110"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_EasyPlayWaltz (at
; [nakarest] 0xec5308, 0xec5302, 0xec52fc).
NakaInst_Three_Four_Vibes_110:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE17E, 0x66
; [nakarest] StyleVar_ParisianNights  +0xe1e4..+0xe246 (0xec53a2, 98 B)
; [nakarest] Text (98 B at 0xec53a2), first string "&T\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece3dc).
StyleVar_ParisianNights:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE1E4, 0x62
; [nakarest] NakaInst_Cafe_Atmosphere_175  +0xe246..+0xe28a (0xec5404, 68 B)
; [nakarest] Text (68 B at 0xec5404), first string "Cafe Atmosphere 175"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_ParisianNights (at
; [nakarest] 0xec53a8, 0xec53a2).
NakaInst_Cafe_Atmosphere_175:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE246, 0x44
; [nakarest] StyleVar_EasyJazzWaltz  +0xe28a..+0xe30e (0xec5448, 132 B)
; [nakarest] Text (132 B at 0xec5448), first string "\xCCT\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_ModernDance_Table (at 0xece3e4).
StyleVar_EasyJazzWaltz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE28A, 0x84
; [nakarest] NakaInst_Suited_To_Jazz_150  +0xe30e..+0xe34e (0xec54cc, 64 B)
; [nakarest] Text (64 B at 0xec54cc), first string "Suited To Jazz! 150"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_EasyJazzWaltz (at
; [nakarest] 0xec5448); 1 data word in StyleGroup_RockPop_PairTable (at 0xece622).
NakaInst_Suited_To_Jazz_150:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE30E, 0x40
; [nakarest] NakaInst_Rock_Fall_155  +0xe34e..+0xe416 (0xec550c, 200 B)
; [nakarest] Text (200 B at 0xec550c), first string "Rock & Fall! 155"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in NakaInst_Suited_To_Jazz_150 (at
; [nakarest] 0xec5500, 0xec54fa, 0xec54f4); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece62a).
NakaInst_Rock_Fall_155:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE34E, 0xC8
; [nakarest] NakaInst_Hard_Blown_R_R_150  +0xe416..+0xe4de (0xec55d4, 200 B)
; [nakarest] Text (200 B at 0xec55d4), first string "Hard Blown R&R 150"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaInst_Rock_Fall_155 (at
; [nakarest] 0xec55a0, 0xec559a, 0xec5594); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece632).
NakaInst_Hard_Blown_R_R_150:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE416, 0xC8
; [nakarest] NakaInst_Boogie_Band_154  +0xe4de..+0xe5a6 (0xec569c, 200 B)
; [nakarest] Text (200 B at 0xec569c), first string "Boogie Band 154"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in NakaInst_Hard_Blown_R_R_150 (at
; [nakarest] 0xec5640, 0xec563a); 1 data word in StyleGroup_RockPop_PairTable (at 0xece63a).
NakaInst_Boogie_Band_154:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE4DE, 0xC8
; [nakarest] NakaInst_Don_t_Do_It_158  +0xe5a6..+0xe5e6 (0xec5764, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec5764 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Boogie_Band_154 (at 0xec56e0); 1 data word in
; [nakarest] StyleGroup_RockPop_PairTable (at 0xece642).
NakaInst_Don_t_Do_It_158:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE5A6, 0x40
; [nakarest] NakaInst_Barry_s_Boogie_150  +0xe5e6..+0xe6ae (0xec57a4, 200 B)
; [nakarest] Text (200 B at 0xec57a4), first string "Barry's Boogie 150"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Don_t_Do_It_158 (at
; [nakarest] 0xec5798, 0xec5792, 0xec578c); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece64a).
NakaInst_Barry_s_Boogie_150:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE5E6, 0xC8
; [nakarest] NakaInst_Twin_E_P_Ballad_67  +0xe6ae..+0xe776 (0xec586c, 200 B)
; [nakarest] Text (200 B at 0xec586c), first string "Twin E.P.Ballad 67"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaInst_Barry_s_Boogie_150
; [nakarest] (at 0xec5838, 0xec5832, 0xec582c); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece652).
NakaInst_Twin_E_P_Ballad_67:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE6AE, 0xC8
; [nakarest] NakaInst_Solid_Surfin_144  +0xe776..+0xe83e (0xec5934, 200 B)
; [nakarest] Text (200 B at 0xec5934), first string "Solid Surfin' 144"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in NakaInst_Twin_E_P_Ballad_67
; [nakarest] (at 0xec58d8, 0xec58d2); 1 data word in StyleGroup_RockPop_PairTable (at 0xece65a).
NakaInst_Solid_Surfin_144:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE776, 0xC8
; [nakarest] NakaInst_Monkeying_About_154  +0xe83e..+0xe87e (0xec59fc, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec59fc not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Solid_Surfin_144 (at 0xec5978); 1 data word in
; [nakarest] StyleGroup_RockPop_PairTable (at 0xece662).
NakaInst_Monkeying_About_154:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE83E, 0x40
; [nakarest] NakaInst_I_Want_To_B3_150  +0xe87e..+0xe946 (0xec5a3c, 200 B)
; [nakarest] Text (200 B at 0xec5a3c), first string "I Want To B3 150"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in NakaInst_Monkeying_About_154 (at
; [nakarest] 0xec5a30, 0xec5a2a, 0xec5a24); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece66a).
NakaInst_I_Want_To_B3_150:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE87E, 0xC8
; [nakarest] NakaInst_Santa_Monica_Way_150  +0xe946..+0xea0e (0xec5b04, 200 B)
; [nakarest] Text (200 B at 0xec5b04), first string "Santa Monica Way 150"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaInst_I_Want_To_B3_150 (at
; [nakarest] 0xec5ad0, 0xec5aca, 0xec5ac4); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece672).
NakaInst_Santa_Monica_Way_150:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xE946, 0xC8
; [nakarest] NakaInst_Handbag_Dance_129  +0xea0e..+0xead6 (0xec5bcc, 200 B)
; [nakarest] Text (200 B at 0xec5bcc), first string "Handbag Dance! 129"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in NakaInst_Santa_Monica_Way_150
; [nakarest] (at 0xec5b70, 0xec5b6a); 1 data word in StyleGroup_RockPop_PairTable (at 0xece67a).
NakaInst_Handbag_Dance_129:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEA0E, 0xC8
; [nakarest] NakaInst_Elton_s_Piano_136  +0xead6..+0xeb16 (0xec5c94, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec5c94 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Handbag_Dance_129 (at 0xec5c10); 1 data word in
; [nakarest] StyleGroup_RockPop_PairTable (at 0xece682).
NakaInst_Elton_s_Piano_136:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEAD6, 0x40
; [nakarest] NakaInst_Dire_Strats_138_EC5CD4  +0xeb16..+0xebde (0xec5cd4, 200 B)
; [nakarest] Text (200 B at 0xec5cd4), first string "Dire Strats 138"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in NakaInst_Elton_s_Piano_136 (at
; [nakarest] 0xec5cc8, 0xec5cc2, 0xec5cbc); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece68a).
NakaInst_Dire_Strats_138_EC5CD4:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEB16, 0xC8
; [nakarest] NakaInst_C_P_On_Stage_145  +0xebde..+0xeca6 (0xec5d9c, 200 B)
; [nakarest] Text (200 B at 0xec5d9c), first string "C.P. On Stage 145"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in
; [nakarest] NakaInst_Dire_Strats_138_EC5CD4 (at 0xec5d68, 0xec5d62, 0xec5d5c); 1 data word in
; [nakarest] StyleGroup_RockPop_PairTable (at 0xece692).
NakaInst_C_P_On_Stage_145:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEBDE, 0xC8
; [nakarest] NakaInst_Pop_Leader_144  +0xeca6..+0xed6e (0xec5e64, 200 B)
; [nakarest] Text (200 B at 0xec5e64), first string "Pop Leader 144"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in NakaInst_C_P_On_Stage_145 (at
; [nakarest] 0xec5e08, 0xec5e02); 1 data word in StyleGroup_RockPop_PairTable (at 0xece69a).
NakaInst_Pop_Leader_144:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xECA6, 0xC8
; [nakarest] NakaInst_Analogue_Ballad_106  +0xed6e..+0xedae (0xec5f2c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec5f2c not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Pop_Leader_144 (at 0xec5ea8); 1 data word in
; [nakarest] StyleGroup_RockPop_PairTable (at 0xece6a2).
NakaInst_Analogue_Ballad_106:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xED6E, 0x40
; [nakarest] NakaInst_Italy_Pop_Organ_118  +0xedae..+0xee76 (0xec5f6c, 200 B)
; [nakarest] Text (200 B at 0xec5f6c), first string "Italy Pop Organ 118"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Analogue_Ballad_106
; [nakarest] (at 0xec5f60, 0xec5f5a, 0xec5f54); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece6aa).
NakaInst_Italy_Pop_Organ_118:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEDAE, 0xC8
; [nakarest] NakaInst_Pop_Horns_111  +0xee76..+0xef3e (0xec6034, 200 B)
; [nakarest] Text (200 B at 0xec6034), first string "Pop Horns 111"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in NakaInst_Italy_Pop_Organ_118 (at
; [nakarest] 0xec6000, 0xec5ffa, 0xec5ff4); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece6b2).
NakaInst_Pop_Horns_111:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEE76, 0xC8
; [nakarest] NakaInst_Sax_Rock_116  +0xef3e..+0xf006 (0xec60fc, 200 B)
; [nakarest] Text (200 B at 0xec60fc), first string "Sax Rock 116"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in NakaInst_Pop_Horns_111 (at
; [nakarest] 0xec60a0, 0xec609a); 1 data word in StyleGroup_RockPop_PairTable (at 0xece6ba).
NakaInst_Sax_Rock_116:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xEF3E, 0xC8
; [nakarest] NakaInst_Ballad_Warmth_78  +0xf006..+0xf046 (0xec61c4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec61c4 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Sax_Rock_116 (at 0xec6140); 1 data word in
; [nakarest] StyleGroup_RockPop_PairTable (at 0xece6c2).
NakaInst_Ballad_Warmth_78:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF006, 0x40
; [nakarest] NakaInst_Everybody_Rock_131  +0xf046..+0xf10e (0xec6204, 200 B)
; [nakarest] Text (200 B at 0xec6204), first string "Everybody Rock! 131"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Ballad_Warmth_78 (at
; [nakarest] 0xec61f8, 0xec61f2, 0xec61ec); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece6ca).
NakaInst_Everybody_Rock_131:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF046, 0xC8
; [nakarest] NakaInst_Deep_Hammond_142  +0xf10e..+0xf1d6 (0xec62cc, 200 B)
; [nakarest] Text (200 B at 0xec62cc), first string "Deep Hammond 142"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in NakaInst_Everybody_Rock_131 (at
; [nakarest] 0xec6298, 0xec6292, 0xec628c); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece6d2).
NakaInst_Deep_Hammond_142:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF10E, 0xC8
; [nakarest] NakaInst_Hard_Analogue_148_EC6394  +0xf1d6..+0xf29e (0xec6394, 200 B)
; [nakarest] Text (200 B at 0xec6394), first string "Hard Analogue 148"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in NakaInst_Deep_Hammond_142 (at
; [nakarest] 0xec6338, 0xec6332); 1 data word in StyleGroup_RockPop_PairTable (at 0xece6da).
NakaInst_Hard_Analogue_148_EC6394:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF1D6, 0xC8
; [nakarest] NakaInst_Heavy_Harmonica_74_EC645C  +0xf29e..+0xf2de (0xec645c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec645c not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Hard_Analogue_148_EC6394 (at 0xec63d8); 1 data
; [nakarest] word in StyleGroup_RockPop_PairTable (at 0xece6e2).
NakaInst_Heavy_Harmonica_74_EC645C:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF29E, 0x40
; [nakarest] NakaInst_Digital_Swing_92  +0xf2de..+0xf3a6 (0xec649c, 200 B)
; [nakarest] Text (200 B at 0xec649c), first string "Digital Swing 92"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in NakaInst_Heavy_Harmonica_74_EC645C
; [nakarest] (at 0xec6490, 0xec648a, 0xec6484); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece6ea).
NakaInst_Digital_Swing_92:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF2DE, 0xC8
; [nakarest] NakaInst_Blues_Harp_Swing_62  +0xf3a6..+0xf42a (0xec6564, 132 B)
; [nakarest] Text (132 B at 0xec6564), first string "Blues Harp Swing 62"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaInst_Digital_Swing_92 (at
; [nakarest] 0xec6530, 0xec652a, 0xec6524); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece6f2).
NakaInst_Blues_Harp_Swing_62:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF3A6, 0x84
; [nakarest] NakaInst_L_A_Strings_92  +0xf42a..+0xf46e (0xec65e8, 68 B)
; [nakarest] Text (68 B at 0xec65e8), first string "L.A. Strings 92"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in NakaInst_Blues_Harp_Swing_62 (at
; [nakarest] 0xec65dc, 0xec65d6).
NakaInst_L_A_Strings_92:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF42A, 0x44
; [nakarest] NakaInst_Synth_Guitar_Pop_92  +0xf46e..+0xf4f2 (0xec662c, 132 B)
; [nakarest] Text (132 B at 0xec662c), first string "Synth Guitar Pop 92"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in NakaInst_Blues_Harp_Swing_62
; [nakarest] (at 0xec65d0, 0xec65ca); 1 data word in StyleGroup_RockPop_PairTable (at 0xece6fa).
NakaInst_Synth_Guitar_Pop_92:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF46E, 0x84
; [nakarest] NakaInst_Wide_Hornsection_100  +0xf4f2..+0xf536 (0xec66b0, 68 B)
; [nakarest] Text (68 B at 0xec66b0), first string "Wide Hornsection 100"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in NakaInst_Synth_Guitar_Pop_92
; [nakarest] (at 0xec667c, 0xec6676).
NakaInst_Wide_Hornsection_100:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF4F2, 0x44
; [nakarest] NakaInst_Mad_Tabs_100  +0xf536..+0xf576 (0xec66f4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec66f4 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Synth_Guitar_Pop_92 (at 0xec6670); 1 data word in
; [nakarest] StyleGroup_RockPop_PairTable (at 0xece702).
NakaInst_Mad_Tabs_100:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF536, 0x40
; [nakarest] NakaInst_Key_Grooves_102  +0xf576..+0xf5ba (0xec6734, 68 B)
; [nakarest] Text (68 B at 0xec6734), first string "Key Grooves 102"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in NakaInst_Mad_Tabs_100 (at 0xec6728,
; [nakarest] 0xec6722).
NakaInst_Key_Grooves_102:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF576, 0x44
; [nakarest] NakaInst_George_B_Unison_102  +0xf5ba..+0xf63e (0xec6778, 132 B)
; [nakarest] Text (132 B at 0xec6778), first string "George B Unison 102"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in NakaInst_Mad_Tabs_100 (at
; [nakarest] 0xec671c, 0xec6716); 1 data word in StyleGroup_RockPop_PairTable (at 0xece70a).
NakaInst_George_B_Unison_102:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF5BA, 0x84
; [nakarest] NakaInst_L_A_Synth_85  +0xf63e..+0xf706 (0xec67fc, 200 B)
; [nakarest] Text (200 B at 0xec67fc), first string "L.A. Synth 85"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in NakaInst_George_B_Unison_102 (at
; [nakarest] 0xec67c8, 0xec67c2, 0xec67bc); 1 data word in StyleGroup_RockPop_PairTable (at
; [nakarest] 0xece712).
NakaInst_L_A_Synth_85:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF63E, 0xC8
; [nakarest] NakaInst_Funk_Keys_96  +0xf706..+0xf7ce (0xec68c4, 200 B)
; [nakarest] Text (200 B at 0xec68c4), first string "Funk Keys 96"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in NakaInst_L_A_Synth_85 (at 0xec6868,
; [nakarest] 0xec6862); 1 data word in StyleGroup_RockPop_PairTable (at 0xece71a).
NakaInst_Funk_Keys_96:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF706, 0xC8
; [nakarest] NakaInst_Yuppie_Keys_97  +0xf7ce..+0xf80e (0xec698c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec698c not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Funk_Keys_96 (at 0xec6908); 1 data word in
; [nakarest] StyleGroup_RockPop_PairTable (at 0xece722).
NakaInst_Yuppie_Keys_97:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF7CE, 0x40
; [nakarest] NakaInst_Sweeping_Bridge_110  +0xf80e..+0xf896 (0xec69cc, 136 B)
; [nakarest] Text (136 B at 0xec69cc), first string "Sweeping Bridge 110"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Yuppie_Keys_97 (at
; [nakarest] 0xec69c0, 0xec69ba, 0xec69b4).
NakaInst_Sweeping_Bridge_110:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF80E, 0x88
; [nakarest] StyleVar_FunkyTalk  +0xf896..+0xf8d6 (0xec6a54, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec6a54 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece984).
StyleVar_FunkyTalk:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF896, 0x40
; [nakarest] NakaInst_Retro_Groove_127  +0xf8d6..+0xf93c (0xec6a94, 102 B)
; [nakarest] Text (102 B at 0xec6a94), first string "Retro Groove 127"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_FunkyTalk (at 0xec6a60,
; [nakarest] 0xec6a5a, 0xec6a54).
NakaInst_Retro_Groove_127:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF8D6, 0x66
; [nakarest] StyleVar_OldDanceHit  +0xf93c..+0xf99e (0xec6afa, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec6afa not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece98c).
StyleVar_OldDanceHit:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF93C, 0x62
; [nakarest] NakaInst_Metalic_Dance_121  +0xf99e..+0xf9e2 (0xec6b5c, 68 B)
; [nakarest] Text (68 B at 0xec6b5c), first string "Metalic Dance 121"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_OldDanceHit (at 0xec6b00,
; [nakarest] 0xec6afa).
NakaInst_Metalic_Dance_121:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF99E, 0x44
; [nakarest] StyleVar_PolyDance  +0xf9e2..+0xfa66 (0xec6ba0, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec6ba0 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece994).
StyleVar_PolyDance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xF9E2, 0x84
; [nakarest] NakaInst_House_Piano_125  +0xfa66..+0xfa88 (0xec6c24, 34 B)
; [nakarest] Text (34 B at 0xec6c24), first string "House Piano 125"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_PolyDance (at 0xec6ba0).
NakaInst_House_Piano_125:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFA66, 0x22
; [nakarest] StyleVar_DanceSquares  +0xfa88..+0xfaa6 (0xec6c46, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec6c46 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece99c).
StyleVar_DanceSquares:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFA88, 0x1E
; [nakarest] NakaInst_Techno_Angle_146  +0xfaa6..+0xfb2e (0xec6c64, 136 B)
; [nakarest] Text (136 B at 0xec6c64), first string "Techno Angle 146"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in StyleVar_DanceSquares (at 0xec6c58,
; [nakarest] 0xec6c52, 0xec6c4c).
NakaInst_Techno_Angle_146:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFAA6, 0x88
; [nakarest] StyleVar_DiscoTechni  +0xfb2e..+0xfb6e (0xec6cec, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec6cec not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece9a4).
StyleVar_DiscoTechni:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFB2E, 0x40
; [nakarest] NakaInst_Disco_Techni_118_EC6D2C  +0xfb6e..+0xfbd4 (0xec6d2c, 102 B)
; [nakarest] Text (102 B at 0xec6d2c), first string "Disco-Techni 118"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_DiscoTechni (at 0xec6cf8,
; [nakarest] 0xec6cf2, 0xec6cec).
NakaInst_Disco_Techni_118_EC6D2C:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFB6E, 0x66
; [nakarest] StyleVar_EuroDiscoHit  +0xfbd4..+0xfc36 (0xec6d92, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec6d92 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece9ac).
StyleVar_EuroDiscoHit:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFBD4, 0x62
; [nakarest] NakaInst_New_York_Disco_115  +0xfc36..+0xfc7a (0xec6df4, 68 B)
; [nakarest] Text (68 B at 0xec6df4), first string "New York Disco 115"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_EuroDiscoHit (at
; [nakarest] 0xec6d98, 0xec6d92).
NakaInst_New_York_Disco_115:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFC36, 0x44
; [nakarest] StyleVar_DiscoTalk  +0xfc7a..+0xfcfe (0xec6e38, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec6e38 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece9b4).
StyleVar_DiscoTalk:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFC7A, 0x84
; [nakarest] NakaInst_Disco_Agogo_121  +0xfcfe..+0xfd20 (0xec6ebc, 34 B)
; [nakarest] Text (34 B at 0xec6ebc), first string "Disco Agogo 121"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_DiscoTalk (at 0xec6e38).
NakaInst_Disco_Agogo_121:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFCFE, 0x22
; [nakarest] StyleVar_70sDanceHit  +0xfd20..+0xfd3e (0xec6ede, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec6ede not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece9bc).
StyleVar_70sDanceHit:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFD20, 0x1E
; [nakarest] NakaInst_Disco_Metal_124_EC6EFC  +0xfd3e..+0xfdc6 (0xec6efc, 136 B)
; [nakarest] Text (136 B at 0xec6efc), first string "Disco Metal 124"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in StyleVar_70sDanceHit (at 0xec6ef0,
; [nakarest] 0xec6eea, 0xec6ee4).
NakaInst_Disco_Metal_124_EC6EFC:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFD3E, 0x88
; [nakarest] StyleVar_DiscoRanger  +0xfdc6..+0xfe06 (0xec6f84, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec6f84 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece9c4).
StyleVar_DiscoRanger:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFDC6, 0x40
; [nakarest] NakaInst_Hip_Hop_Echoes_108  +0xfe06..+0xfe6c (0xec6fc4, 102 B)
; [nakarest] Text (102 B at 0xec6fc4), first string "Hip-Hop-Echoes 108"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_DiscoRanger (at
; [nakarest] 0xec6f90, 0xec6f8a, 0xec6f84).
NakaInst_Hip_Hop_Echoes_108:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFE06, 0x66
; [nakarest] StyleVar_GloryDisco  +0xfe6c..+0xfece (0xec702a, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec702a not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece9cc).
StyleVar_GloryDisco:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFE6C, 0x62
; [nakarest] NakaInst_Synth_of_The_90s_108  +0xfece..+0xff12 (0xec708c, 68 B)
; [nakarest] Text (68 B at 0xec708c), first string "Synth of The 90s 108"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_GloryDisco (at
; [nakarest] 0xec7030, 0xec702a).
NakaInst_Synth_of_The_90s_108:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFECE, 0x44
; [nakarest] StyleVar_NYRap  +0xff12..+0xff96 (0xec70d0, 132 B)
; [nakarest] Text (132 B at 0xec70d0), first string "Tq\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_PopBallad_Table (at 0xece9d4).
StyleVar_NYRap:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFF12, 0x84
; [nakarest] NakaInst_Pump_The_Bass_96  +0xff96..+0xffb8 (0xec7154, 34 B)
; [nakarest] Text (34 B at 0xec7154), first string "Pump The Bass 96"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_NYRap (at 0xec70d0).
NakaInst_Pump_The_Bass_96:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFF96, 0x22
; [nakarest] StyleVar_HipHop  +0xffb8..+0xffd6 (0xec7176, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec7176 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece9dc).
StyleVar_HipHop:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFFB8, 0x1E
; [nakarest] NakaInst_Dance_Island_104_EC7194  +0xffd6..+0x1005e (0xec7194, 136 B)
; [nakarest] Text (136 B at 0xec7194), first string "Dance Island 104"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in StyleVar_HipHop (at 0xec7188,
; [nakarest] 0xec7182, 0xec717c).
NakaInst_Dance_Island_104_EC7194:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0xFFD6, 0x88
; [nakarest] StyleVar_ReggaeHit  +0x1005e..+0x1009e (0xec721c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec721c not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece9e4).
StyleVar_ReggaeHit:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1005E, 0x40
; [nakarest] NakaInst_Rasta_Jambo_101  +0x1009e..+0x10104 (0xec725c, 102 B)
; [nakarest] Text (102 B at 0xec725c), first string "Rasta Jambo 101"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_ReggaeHit (at 0xec7228,
; [nakarest] 0xec7222, 0xec721c).
NakaInst_Rasta_Jambo_101:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1009E, 0x66
; [nakarest] StyleVar_RioGosDisco  +0x10104..+0x10166 (0xec72c2, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec72c2 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece9ec).
StyleVar_RioGosDisco:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10104, 0x62
; [nakarest] NakaInst_Dancing_Flutes_125_EC7324  +0x10166..+0x101aa (0xec7324, 68 B)
; [nakarest] Text (68 B at 0xec7324), first string "Dancing Flutes 125"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_RioGosDisco (at
; [nakarest] 0xec72c8, 0xec72c2).
NakaInst_Dancing_Flutes_125_EC7324:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10166, 0x44
; [nakarest] StyleVar_JamboDance  +0x101aa..+0x1022e (0xec7368, 132 B)
; [nakarest] Text (132 B at 0xec7368), first string "\xECs\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_PopBallad_Table (at 0xece9f4).
StyleVar_JamboDance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x101AA, 0x84
; [nakarest] NakaInst_Reggae_Dance_Hit_101  +0x1022e..+0x10250 (0xec73ec, 34 B)
; [nakarest] Text (34 B at 0xec73ec), first string "Reggae Dance Hit 101"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_JamboDance (at
; [nakarest] 0xec7368).
NakaInst_Reggae_Dance_Hit_101:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1022E, 0x22
; [nakarest] StyleVar_SambaParty  +0x10250..+0x1026e (0xec740e, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec740e not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xece9fc).
StyleVar_SambaParty:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10250, 0x1E
; [nakarest] NakaInst_Festival_Amigos_116_EC742C  +0x1026e..+0x102f6 (0xec742c, 136 B)
; [nakarest] Text (136 B at 0xec742c), first string "Festival Amigos 116"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_SambaParty (at
; [nakarest] 0xec7420, 0xec741a, 0xec7414).
NakaInst_Festival_Amigos_116_EC742C:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1026E, 0x88
; [nakarest] StyleVar_LatinFestival  +0x102f6..+0x10336 (0xec74b4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec74b4 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_PopBallad_Table (at 0xecea04).
StyleVar_LatinFestival:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x102F6, 0x40
; [nakarest] NakaInst_Dance_Surround_124_EC74F4  +0x10336..+0x103fe (0xec74f4, 200 B)
; [nakarest] Text (200 B at 0xec74f4), first string "Dance Surround 124"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_LatinFestival (at
; [nakarest] 0xec74c0, 0xec74ba, 0xec74b4); 1 data word in StyleGroup_PartyMusic_PairTable (at
; [nakarest] 0xeceb46).
NakaInst_Dance_Surround_124_EC74F4:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10336, 0xC8
; [nakarest] NakaInst_Last_Starparade_120  +0x103fe..+0x104c6 (0xec75bc, 200 B)
; [nakarest] Text (200 B at 0xec75bc), first string "Last Starparade! 120"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in
; [nakarest] NakaInst_Dance_Surround_124_EC74F4 (at 0xec7560, 0xec755a); 1 data word in
; [nakarest] StyleGroup_PartyMusic_PairTable (at 0xeceb4e).
NakaInst_Last_Starparade_120:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x103FE, 0xC8
; [nakarest] NakaInst_Party_Flautist_111  +0x104c6..+0x10506 (0xec7684, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec7684 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Last_Starparade_120 (at 0xec7600); 1 data word in
; [nakarest] StyleGroup_PartyMusic_PairTable (at 0xeceb56).
NakaInst_Party_Flautist_111:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x104C6, 0x40
; [nakarest] NakaInst_German_HitParade_120  +0x10506..+0x105ce (0xec76c4, 200 B)
; [nakarest] Text (200 B at 0xec76c4), first string "German-HitParade 120"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Party_Flautist_111
; [nakarest] (at 0xec76b8, 0xec76b2, 0xec76ac); 1 data word in StyleGroup_PartyMusic_PairTable
; [nakarest] (at 0xeceb5e).
NakaInst_German_HitParade_120:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10506, 0xC8
; [nakarest] NakaInst_Ady_s_PartyOrgan_125_EC778C  +0x105ce..+0x10696 (0xec778c, 200 B)
; [nakarest] Text (200 B at 0xec778c), first string "Ady's PartyOrgan 125"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaInst_German_HitParade_120
; [nakarest] (at 0xec7758, 0xec7752, 0xec774c); 1 data word in StyleGroup_PartyMusic_PairTable
; [nakarest] (at 0xeceb66).
NakaInst_Ady_s_PartyOrgan_125_EC778C:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x105CE, 0xC8
; [nakarest] NakaInst_Pop_Of_The_Bells_125  +0x10696..+0x1075e (0xec7854, 200 B)
; [nakarest] Text (200 B at 0xec7854), first string "Pop Of The Bells 125"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in
; [nakarest] NakaInst_Ady_s_PartyOrgan_125_EC778C (at 0xec77f8, 0xec77f2); 1 data word in
; [nakarest] StyleGroup_PartyMusic_PairTable (at 0xeceb6e).
NakaInst_Pop_Of_The_Bells_125:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10696, 0xC8
; [nakarest] NakaInst_Puppet_March_116  +0x1075e..+0x1079e (0xec791c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec791c not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Pop_Of_The_Bells_125 (at 0xec7898); 1 data word in
; [nakarest] StyleGroup_PartyMusic_PairTable (at 0xeceb76).
NakaInst_Puppet_March_116:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1075E, 0x40
; [nakarest] NakaInst_Party_Space_120  +0x1079e..+0x10866 (0xec795c, 200 B)
; [nakarest] Text (200 B at 0xec795c), first string "Party Space 120"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in NakaInst_Puppet_March_116 (at
; [nakarest] 0xec7950, 0xec794a, 0xec7944); 1 data word in StyleGroup_PartyMusic_PairTable (at
; [nakarest] 0xeceb7e).
NakaInst_Party_Space_120:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1079E, 0xC8
; [nakarest] NakaInst_Orgel_Pops_111  +0x10866..+0x1092e (0xec7a24, 200 B)
; [nakarest] Text (200 B at 0xec7a24), first string "Orgel Pops 111"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in NakaInst_Party_Space_120 (at
; [nakarest] 0xec79f0, 0xec79ea, 0xec79e4); 1 data word in StyleGroup_PartyMusic_PairTable (at
; [nakarest] 0xeceb86).
NakaInst_Orgel_Pops_111:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10866, 0xC8
; [nakarest] NakaInst_Anka_Rock_133  +0x1092e..+0x109f6 (0xec7aec, 200 B)
; [nakarest] Text (200 B at 0xec7aec), first string "Anka Rock 133"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in NakaInst_Orgel_Pops_111 (at
; [nakarest] 0xec7a90, 0xec7a8a); 1 data word in StyleGroup_PartyMusic_PairTable (at 0xeceb8e).
NakaInst_Anka_Rock_133:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1092E, 0xC8
; [nakarest] NakaInst_Party_Register_115  +0x109f6..+0x10a36 (0xec7bb4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec7bb4 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Anka_Rock_133 (at 0xec7b30); 1 data word in
; [nakarest] StyleGroup_PartyMusic_PairTable (at 0xeceb96).
NakaInst_Party_Register_115:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x109F6, 0x40
; [nakarest] NakaInst_Shake_It_All_162  +0x10a36..+0x10afe (0xec7bf4, 200 B)
; [nakarest] Text (200 B at 0xec7bf4), first string "Shake It All.... 162"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Party_Register_115
; [nakarest] (at 0xec7be8, 0xec7be2, 0xec7bdc); 1 data word in StyleGroup_PartyMusic_PairTable
; [nakarest] (at 0xeceb9e).
NakaInst_Shake_It_All_162:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10A36, 0xC8
; [nakarest] NakaInst_Chords_Birds_100  +0x10afe..+0x10bc6 (0xec7cbc, 200 B)
; [nakarest] Text (200 B at 0xec7cbc), first string "Chords & Birds 100"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaInst_Shake_It_All_162 (at
; [nakarest] 0xec7c88, 0xec7c82, 0xec7c7c); 1 data word in StyleGroup_PartyMusic_PairTable (at
; [nakarest] 0xeceba6).
NakaInst_Chords_Birds_100:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10AFE, 0xC8
; [nakarest] NakaInst_Banjo_Sing_Song_134  +0x10bc6..+0x10c8e (0xec7d84, 200 B)
; [nakarest] Text (200 B at 0xec7d84), first string "Banjo Sing Song 134"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in NakaInst_Chords_Birds_100 (at
; [nakarest] 0xec7d28, 0xec7d22); 1 data word in StyleGroup_PartyMusic_PairTable (at 0xecebae).
NakaInst_Banjo_Sing_Song_134:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10BC6, 0xC8
; [nakarest] NakaInst_Fiddle_Dance_132  +0x10c8e..+0x10cce (0xec7e4c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec7e4c not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Banjo_Sing_Song_134 (at 0xec7dc8); 1 data word in
; [nakarest] StyleGroup_PartyMusic_PairTable (at 0xecebb6).
NakaInst_Fiddle_Dance_132:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10C8E, 0x40
; [nakarest] NakaInst_Symphony_Hoedown_206  +0x10cce..+0x10d96 (0xec7e8c, 200 B)
; [nakarest] Text (200 B at 0xec7e8c), first string "Symphony Hoedown 206"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Fiddle_Dance_132 (at
; [nakarest] 0xec7e80, 0xec7e7a, 0xec7e74); 1 data word in StyleGroup_PartyMusic_PairTable (at
; [nakarest] 0xecebbe).
NakaInst_Symphony_Hoedown_206:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10CCE, 0xC8
; [nakarest] NakaInst_Techno_Ranger_138  +0x10d96..+0x10e5e (0xec7f54, 200 B)
; [nakarest] Text (200 B at 0xec7f54), first string "Techno Ranger 138"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaInst_Symphony_Hoedown_206
; [nakarest] (at 0xec7f20, 0xec7f1a, 0xec7f14); 1 data word in StyleGroup_PartyMusic_PairTable
; [nakarest] (at 0xecebc6).
NakaInst_Techno_Ranger_138:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10D96, 0xC8
; [nakarest] NakaInst_The_Zillertaler_150  +0x10e5e..+0x10f26 (0xec801c, 200 B)
; [nakarest] Text (200 B at 0xec801c), first string "The Zillertaler 150"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in NakaInst_Techno_Ranger_138
; [nakarest] (at 0xec7fc0, 0xec7fba); 1 data word in StyleGroup_PartyMusic_PairTable (at
; [nakarest] 0xecebce).
NakaInst_The_Zillertaler_150:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10E5E, 0xC8
; [nakarest] NakaInst_Sepp_s_Clarinet_195  +0x10f26..+0x10f66 (0xec80e4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec80e4 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_The_Zillertaler_150 (at 0xec8060); 1 data word in
; [nakarest] StyleGroup_PartyMusic_PairTable (at 0xecebd6).
NakaInst_Sepp_s_Clarinet_195:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10F26, 0x40
; [nakarest] NakaInst_Miseltoe_Melody_75  +0x10f66..+0x10fee (0xec8124, 136 B)
; [nakarest] Text (136 B at 0xec8124), first string "Miseltoe Melody 75"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Sepp_s_Clarinet_195
; [nakarest] (at 0xec8118, 0xec8112, 0xec810c).
NakaInst_Miseltoe_Melody_75:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10F66, 0x88
; [nakarest] StyleVar_KingOfSoul  +0x10fee..+0x1102e (0xec81ac, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec81ac not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xeced3c).
StyleVar_KingOfSoul:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x10FEE, 0x40
; [nakarest] NakaInst_Bad_Soul_Bars_140  +0x1102e..+0x11094 (0xec81ec, 102 B)
; [nakarest] Text (102 B at 0xec81ec), first string "Bad Soul Bars 140"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_KingOfSoul (at
; [nakarest] 0xec81b8, 0xec81b2, 0xec81ac).
NakaInst_Bad_Soul_Bars_140:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1102E, 0x66
; [nakarest] StyleVar_DetroitPop  +0x11094..+0x110f6 (0xec8252, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec8252 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xeced44).
StyleVar_DetroitPop:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11094, 0x62
; [nakarest] NakaInst_Ross_Vocals_142  +0x110f6..+0x1113a (0xec82b4, 68 B)
; [nakarest] Text (68 B at 0xec82b4), first string "Ross Vocals 142"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_DetroitPop (at 0xec8258,
; [nakarest] 0xec8252).
NakaInst_Ross_Vocals_142:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x110F6, 0x44
; [nakarest] StyleVar_SoftSoul  +0x1113a..+0x111be (0xec82f8, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec82f8 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xeced4c).
StyleVar_SoftSoul:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1113A, 0x84
; [nakarest] NakaInst_A_Case_Of_Soul_114_EC837C  +0x111be..+0x111e0 (0xec837c, 34 B)
; [nakarest] Text (34 B at 0xec837c), first string "A Case Of Soul 114"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_SoftSoul (at
; [nakarest] 0xec82f8).
NakaInst_A_Case_Of_Soul_114_EC837C:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x111BE, 0x22
; [nakarest] StyleVar_NewSoulBallad  +0x111e0..+0x111fe (0xec839e, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec839e not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xeced54).
StyleVar_NewSoulBallad:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x111E0, 0x1E
; [nakarest] NakaInst_Soul_Suitcase_70  +0x111fe..+0x11286 (0xec83bc, 136 B)
; [nakarest] Text (136 B at 0xec83bc), first string "Soul Suitcase 70"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in StyleVar_NewSoulBallad (at
; [nakarest] 0xec83b0, 0xec83aa, 0xec83a4).
NakaInst_Soul_Suitcase_70:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x111FE, 0x88
; [nakarest] StyleVar_SoulToSun  +0x11286..+0x112c6 (0xec8444, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec8444 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xeced5c).
StyleVar_SoulToSun:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11286, 0x40
; [nakarest] NakaInst_Keys_To_Soul_88  +0x112c6..+0x1132c (0xec8484, 102 B)
; [nakarest] Text (102 B at 0xec8484), first string "Keys To Soul 88"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_SoulToSun (at 0xec8450,
; [nakarest] 0xec844a, 0xec8444).
NakaInst_Keys_To_Soul_88:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x112C6, 0x66
; [nakarest] StyleVar_MellowSoul  +0x1132c..+0x1138e (0xec84ea, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec84ea not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xeced64).
StyleVar_MellowSoul:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1132C, 0x62
; [nakarest] NakaInst_Sweet_16_Sax_66  +0x1138e..+0x113d2 (0xec854c, 68 B)
; [nakarest] Text (68 B at 0xec854c), first string "Sweet 16 Sax 66"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_MellowSoul (at 0xec84f0,
; [nakarest] 0xec84ea).
NakaInst_Sweet_16_Sax_66:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1138E, 0x44
; [nakarest] StyleVar_SlowSoulMood  +0x113d2..+0x11456 (0xec8590, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec8590 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xeced6c).
StyleVar_SlowSoulMood:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x113D2, 0x84
; [nakarest] NakaInst_Soul_On_My_Mind_64  +0x11456..+0x11478 (0xec8614, 34 B)
; [nakarest] Text (34 B at 0xec8614), first string "Soul On My Mind 64"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_SlowSoulMood (at
; [nakarest] 0xec8590).
NakaInst_Soul_On_My_Mind_64:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11456, 0x22
; [nakarest] StyleVar_RBGroove  +0x11478..+0x11496 (0xec8636, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec8636 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xeced74).
StyleVar_RBGroove:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11478, 0x1E
; [nakarest] NakaInst_Blues_Horns_112  +0x11496..+0x1151e (0xec8654, 136 B)
; [nakarest] Text (136 B at 0xec8654), first string "Blues Horns 112"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in StyleVar_RBGroove (at 0xec8648,
; [nakarest] 0xec8642, 0xec863c).
NakaInst_Blues_Horns_112:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11496, 0x88
; [nakarest] StyleVar_DownDirtyBlues  +0x1151e..+0x1155e (0xec86dc, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec86dc not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xeced7c).
StyleVar_DownDirtyBlues:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1151E, 0x40
; [nakarest] NakaInst_Solid_Blues_78  +0x1155e..+0x115c4 (0xec871c, 102 B)
; [nakarest] Text (102 B at 0xec871c), first string "Solid Blues 78"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_DownDirtyBlues (at
; [nakarest] 0xec86e8, 0xec86e2, 0xec86dc).
NakaInst_Solid_Blues_78:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1155E, 0x66
; [nakarest] StyleVar_RockBlues  +0x115c4..+0x11626 (0xec8782, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec8782 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xeced84).
StyleVar_RockBlues:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x115C4, 0x62
; [nakarest] NakaInst_Hard_Sax_Blues_124_EC87E4  +0x11626..+0x1166a (0xec87e4, 68 B)
; [nakarest] Text (68 B at 0xec87e4), first string "Hard Sax Blues 124"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_RockBlues (at
; [nakarest] 0xec8788, 0xec8782).
NakaInst_Hard_Sax_Blues_124_EC87E4:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11626, 0x44
; [nakarest] StyleVar_PlayTheBlues  +0x1166a..+0x116ee (0xec8828, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec8828 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xeced8c).
StyleVar_PlayTheBlues:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1166A, 0x84
; [nakarest] NakaInst_I_Got_The_Blues_83_EC88AC  +0x116ee..+0x11710 (0xec88ac, 34 B)
; [nakarest] Text (34 B at 0xec88ac), first string "I Got The Blues 83"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_PlayTheBlues (at
; [nakarest] 0xec8828).
NakaInst_I_Got_The_Blues_83_EC88AC:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x116EE, 0x22
; [nakarest] StyleVar_BluesAlley  +0x11710..+0x11902 (0xec88ce, 498 B)
; [nakarest] purpose not established: layout of 498 B at 0xec88ce not derived; readers below
; [nakarest] Readers: 3 data words in StyleGroup_Swing_Table (at 0xeced94, 0xeced9c, 0xeceda4).
StyleVar_BluesAlley:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11710, 0x1F2
; [nakarest] StyleVar_DayOfRest  +0x11902..+0x11986 (0xec8ac0, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec8ac0 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xecedac).
StyleVar_DayOfRest:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11902, 0x84
; [nakarest] NakaInst_Gospel_Standard_124  +0x11986..+0x119a8 (0xec8b44, 34 B)
; [nakarest] Text (34 B at 0xec8b44), first string "Gospel Standard 124"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_DayOfRest (at
; [nakarest] 0xec8ac0).
NakaInst_Gospel_Standard_124:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11986, 0x22
; [nakarest] StyleVar_PowerGospel  +0x119a8..+0x119c6 (0xec8b66, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec8b66 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xecedb4).
StyleVar_PowerGospel:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x119A8, 0x1E
; [nakarest] NakaInst_Congregation_151  +0x119c6..+0x11a4e (0xec8b84, 136 B)
; [nakarest] Text (136 B at 0xec8b84), first string "Congregation! 151"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_PowerGospel (at
; [nakarest] 0xec8b78, 0xec8b72, 0xec8b6c).
NakaInst_Congregation_151:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x119C6, 0x88
; [nakarest] StyleVar_GospelBlues  +0x11a4e..+0x11a8e (0xec8c0c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec8c0c not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xecedbc).
StyleVar_GospelBlues:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11A4E, 0x40
; [nakarest] NakaInst_Drawbar_Service_66  +0x11a8e..+0x11af4 (0xec8c4c, 102 B)
; [nakarest] Text (102 B at 0xec8c4c), first string "Drawbar Service 66"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_GospelBlues (at
; [nakarest] 0xec8c18, 0xec8c12, 0xec8c0c).
NakaInst_Drawbar_Service_66:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11A8E, 0x66
; [nakarest] StyleVar_GospelInThrees  +0x11af4..+0x11b56 (0xec8cb2, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec8cb2 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_Swing_Table (at 0xecedc4).
StyleVar_GospelInThrees:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11AF4, 0x62
; [nakarest] NakaInst_Sing_It_Play_It_92  +0x11b56..+0x11b9a (0xec8d14, 68 B)
; [nakarest] Text (68 B at 0xec8d14), first string "Sing It, Play It 92"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_GospelInThrees (at
; [nakarest] 0xec8cb8, 0xec8cb2).
NakaInst_Sing_It_Play_It_92:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11B56, 0x44
; [nakarest] StyleVar_UpTempoBigband  +0x11b9a..+0x11c1e (0xec8d58, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec8d58 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef18).
StyleVar_UpTempoBigband:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11B9A, 0x84
; [nakarest] NakaInst_The_Duke_s_Piano_170  +0x11c1e..+0x11c40 (0xec8ddc, 34 B)
; [nakarest] Text (34 B at 0xec8ddc), first string "The Duke's Piano 170"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_UpTempoBigband (at
; [nakarest] 0xec8d58).
NakaInst_The_Duke_s_Piano_170:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11C1E, 0x22
; [nakarest] StyleVar_SteadySwingband  +0x11c40..+0x11c5e (0xec8dfe, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec8dfe not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef20).
StyleVar_SteadySwingband:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11C40, 0x1E
; [nakarest] NakaInst_Reeds_in_Unison_110  +0x11c5e..+0x11ce6 (0xec8e1c, 136 B)
; [nakarest] Text (136 B at 0xec8e1c), first string "Reeds in Unison 110"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_SteadySwingband (at
; [nakarest] 0xec8e10, 0xec8e0a, 0xec8e04).
NakaInst_Reeds_in_Unison_110:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11C5E, 0x88
; [nakarest] StyleVar_AllAboard  +0x11ce6..+0x11d26 (0xec8ea4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec8ea4 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef28).
StyleVar_AllAboard:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11CE6, 0x40
; [nakarest] NakaInst_Main_Line_Brass_150  +0x11d26..+0x11d8c (0xec8ee4, 102 B)
; [nakarest] Text (102 B at 0xec8ee4), first string "Main Line Brass 150"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_AllAboard (at
; [nakarest] 0xec8eb0, 0xec8eaa, 0xec8ea4).
NakaInst_Main_Line_Brass_150:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11D26, 0x66
; [nakarest] StyleVar_40sDanceBand  +0x11d8c..+0x11dee (0xec8f4a, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec8f4a not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef30).
StyleVar_40sDanceBand:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11D8C, 0x62
; [nakarest] NakaInst_Miller_Reeds_86  +0x11dee..+0x11e32 (0xec8fac, 68 B)
; [nakarest] Text (68 B at 0xec8fac), first string "Miller Reeds 86"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_40sDanceBand (at 0xec8f50,
; [nakarest] 0xec8f4a).
NakaInst_Miller_Reeds_86:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11DEE, 0x44
; [nakarest] StyleVar_SentimentalBand  +0x11e32..+0x11eb6 (0xec8ff0, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec8ff0 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef38).
StyleVar_SentimentalBand:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11E32, 0x84
; [nakarest] NakaInst_Acker_s_Solo_90  +0x11eb6..+0x11ed8 (0xec9074, 34 B)
; [nakarest] Text (34 B at 0xec9074), first string "Acker's Solo 90"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_SentimentalBand (at
; [nakarest] 0xec8ff0).
NakaInst_Acker_s_Solo_90:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11EB6, 0x22
; [nakarest] StyleVar_MoonlightDance  +0x11ed8..+0x11ef6 (0xec9096, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec9096 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef40).
StyleVar_MoonlightDance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11ED8, 0x1E
; [nakarest] NakaInst_Glenn_s_Big_Band_90  +0x11ef6..+0x11f7e (0xec90b4, 136 B)
; [nakarest] Text (136 B at 0xec90b4), first string "Glenn's Big Band 90"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_MoonlightDance (at
; [nakarest] 0xec90a8, 0xec90a2, 0xec909c).
NakaInst_Glenn_s_Big_Band_90:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11EF6, 0x88
; [nakarest] StyleVar_40sLoveSongs  +0x11f7e..+0x11fbe (0xec913c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec913c not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef48).
StyleVar_40sLoveSongs:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11F7E, 0x40
; [nakarest] NakaInst_Big_Band_Sound_92  +0x11fbe..+0x12024 (0xec917c, 102 B)
; [nakarest] Text (102 B at 0xec917c), first string "Big Band Sound 92"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_40sLoveSongs (at
; [nakarest] 0xec9148, 0xec9142, 0xec913c).
NakaInst_Big_Band_Sound_92:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x11FBE, 0x66
; [nakarest] StyleVar_MidSwingband  +0x12024..+0x12086 (0xec91e2, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec91e2 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef50).
StyleVar_MidSwingband:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12024, 0x62
; [nakarest] NakaInst_Reed_It_Mute_It_127  +0x12086..+0x120ca (0xec9244, 68 B)
; [nakarest] Text (68 B at 0xec9244), first string "Reed It, Mute It 127"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_MidSwingband (at
; [nakarest] 0xec91e8, 0xec91e2).
NakaInst_Reed_It_Mute_It_127:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12086, 0x44
; [nakarest] StyleVar_SwingOrchestra  +0x120ca..+0x1214e (0xec9288, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec9288 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef58).
StyleVar_SwingOrchestra:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x120CA, 0x84
; [nakarest] NakaInst_Swingin_Frets_142  +0x1214e..+0x12170 (0xec930c, 34 B)
; [nakarest] Text (34 B at 0xec930c), first string "Swingin' Frets 142"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_SwingOrchestra (at
; [nakarest] 0xec9288).
NakaInst_Swingin_Frets_142:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1214E, 0x22
; [nakarest] StyleVar_NightClubCombo  +0x12170..+0x1218e (0xec932e, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec932e not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef60).
StyleVar_NightClubCombo:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12170, 0x1E
; [nakarest] NakaInst_Swing_Unison_158  +0x1218e..+0x12216 (0xec934c, 136 B)
; [nakarest] Text (136 B at 0xec934c), first string "Swing Unison 158"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in StyleVar_NightClubCombo (at
; [nakarest] 0xec9340, 0xec933a, 0xec9334).
NakaInst_Swing_Unison_158:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1218E, 0x88
; [nakarest] StyleVar_EasyPlaySwing  +0x12216..+0x12256 (0xec93d4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec93d4 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef68).
StyleVar_EasyPlaySwing:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12216, 0x40
; [nakarest] NakaInst_Swing_Sparkle_140  +0x12256..+0x122bc (0xec9414, 102 B)
; [nakarest] Text (102 B at 0xec9414), first string "Swing Sparkle 140"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_EasyPlaySwing (at
; [nakarest] 0xec93e0, 0xec93da, 0xec93d4).
NakaInst_Swing_Sparkle_140:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12256, 0x66
; [nakarest] StyleVar_JazzClub  +0x122bc..+0x1231e (0xec947a, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec947a not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef70).
StyleVar_JazzClub:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x122BC, 0x62
; [nakarest] NakaInst_Club_Duet_146  +0x1231e..+0x12362 (0xec94dc, 68 B)
; [nakarest] Text (68 B at 0xec94dc), first string "Club Duet 146"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_JazzClub (at 0xec9480,
; [nakarest] 0xec947a).
NakaInst_Club_Duet_146:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1231E, 0x44
; [nakarest] StyleVar_UpTempoCombo  +0x12362..+0x123e6 (0xec9520, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec9520 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef78).
StyleVar_UpTempoCombo:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12362, 0x84
; [nakarest] NakaInst_Acoustic_Jazz_174  +0x123e6..+0x12408 (0xec95a4, 34 B)
; [nakarest] Text (34 B at 0xec95a4), first string "Acoustic Jazz 174"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_UpTempoCombo (at 0xec9520).
NakaInst_Acoustic_Jazz_174:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x123E6, 0x22
; [nakarest] StyleVar_SimpleJazz  +0x12408..+0x12426 (0xec95c6, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec95c6 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef80).
StyleVar_SimpleJazz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12408, 0x1E
; [nakarest] NakaInst_Wild_Side_Organ_200  +0x12426..+0x124ae (0xec95e4, 136 B)
; [nakarest] Text (136 B at 0xec95e4), first string "Wild Side Organ 200"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_SimpleJazz (at
; [nakarest] 0xec95d8, 0xec95d2, 0xec95cc).
NakaInst_Wild_Side_Organ_200:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12426, 0x88
; [nakarest] StyleVar_40sBoogie  +0x124ae..+0x124ee (0xec966c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec966c not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef88).
StyleVar_40sBoogie:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x124AE, 0x40
; [nakarest] NakaInst_Boogie_Dance_160_EC96AC  +0x124ee..+0x12554 (0xec96ac, 102 B)
; [nakarest] Text (102 B at 0xec96ac), first string "Boogie Dance 160"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_40sBoogie (at 0xec9678,
; [nakarest] 0xec9672, 0xec966c).
NakaInst_Boogie_Dance_160_EC96AC:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x124EE, 0x66
; [nakarest] StyleVar_JazzStandards  +0x12554..+0x125b6 (0xec9712, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec9712 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef90).
StyleVar_JazzStandards:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12554, 0x62
; [nakarest] NakaInst_Saxy_Jazz_145  +0x125b6..+0x125fa (0xec9774, 68 B)
; [nakarest] Text (68 B at 0xec9774), first string "Saxy Jazz 145"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_JazzStandards (at
; [nakarest] 0xec9718, 0xec9712).
NakaInst_Saxy_Jazz_145:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x125B6, 0x44
; [nakarest] StyleVar_ComboDrawbars  +0x125fa..+0x1267e (0xec97b8, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec97b8 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecef98).
StyleVar_ComboDrawbars:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x125FA, 0x84
; [nakarest] NakaInst_Even_Jazz_170  +0x1267e..+0x126a0 (0xec983c, 34 B)
; [nakarest] Text (34 B at 0xec983c), first string "Even Jazz 170"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_ComboDrawbars (at
; [nakarest] 0xec97b8).
NakaInst_Even_Jazz_170:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1267E, 0x22
; [nakarest] StyleVar_GentleJazz  +0x126a0..+0x126be (0xec985e, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec985e not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecefa0).
StyleVar_GentleJazz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x126A0, 0x1E
; [nakarest] NakaInst_Combo_Soloists_126  +0x126be..+0x12746 (0xec987c, 136 B)
; [nakarest] Text (136 B at 0xec987c), first string "Combo Soloists 126"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_GentleJazz (at
; [nakarest] 0xec9870, 0xec986a, 0xec9864).
NakaInst_Combo_Soloists_126:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x126BE, 0x88
; [nakarest] StyleVar_GypsyJazzers  +0x12746..+0x12786 (0xec9904, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec9904 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecefa8).
StyleVar_GypsyJazzers:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12746, 0x40
; [nakarest] NakaInst_Stephane_Django_210  +0x12786..+0x127ec (0xec9944, 102 B)
; [nakarest] Text (102 B at 0xec9944), first string "Stephane&Django 210"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_GypsyJazzers (at
; [nakarest] 0xec9910, 0xec990a, 0xec9904).
NakaInst_Stephane_Django_210:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12786, 0x66
; [nakarest] StyleVar_JazzAccordion  +0x127ec..+0x1284e (0xec99aa, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec99aa not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecefb0).
StyleVar_JazzAccordion:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x127EC, 0x62
; [nakarest] NakaInst_Let_It_Register_158  +0x1284e..+0x12892 (0xec9a0c, 68 B)
; [nakarest] Text (68 B at 0xec9a0c), first string "Let It Register! 158"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_JazzAccordion (at
; [nakarest] 0xec99b0, 0xec99aa).
NakaInst_Let_It_Register_158:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1284E, 0x44
; [nakarest] StyleVar_SpeakeasyJazz  +0x12892..+0x12916 (0xec9a50, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec9a50 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecefb8).
StyleVar_SpeakeasyJazz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12892, 0x84
; [nakarest] NakaInst_Chicago_Piano_184  +0x12916..+0x12938 (0xec9ad4, 34 B)
; [nakarest] Text (34 B at 0xec9ad4), first string "Chicago Piano 184"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_SpeakeasyJazz (at
; [nakarest] 0xec9a50).
NakaInst_Chicago_Piano_184:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12916, 0x22
; [nakarest] StyleVar_JazzFrancais  +0x12938..+0x12956 (0xec9af6, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec9af6 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecefc0).
StyleVar_JazzFrancais:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12938, 0x1E
; [nakarest] NakaInst_Squeeze_Box_Jazz_190  +0x12956..+0x129de (0xec9b14, 136 B)
; [nakarest] Text (136 B at 0xec9b14), first string "Squeeze Box Jazz 190"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_JazzFrancais (at
; [nakarest] 0xec9b08, 0xec9b02, 0xec9afc).
NakaInst_Squeeze_Box_Jazz_190:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12956, 0x88
; [nakarest] StyleVar_VanDammeJazz  +0x129de..+0x12a1e (0xec9b9c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec9b9c not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecefc8).
StyleVar_VanDammeJazz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x129DE, 0x40
; [nakarest] NakaInst_Deuringer_Swing_190_EC9BDC  +0x12a1e..+0x12a84 (0xec9bdc, 102 B)
; [nakarest] Text (102 B at 0xec9bdc), first string "Deuringer Swing 190"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_VanDammeJazz (at
; [nakarest] 0xec9ba8, 0xec9ba2, 0xec9b9c).
NakaInst_Deuringer_Swing_190_EC9BDC:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12A1E, 0x66
; [nakarest] StyleVar_EuroJazz  +0x12a84..+0x12ae6 (0xec9c42, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec9c42 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecefd0).
StyleVar_EuroJazz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12A84, 0x62
; [nakarest] NakaInst_Duelling_Reeds_147  +0x12ae6..+0x12b2a (0xec9ca4, 68 B)
; [nakarest] Text (68 B at 0xec9ca4), first string "Duelling Reeds 147"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_EuroJazz (at
; [nakarest] 0xec9c48, 0xec9c42).
NakaInst_Duelling_Reeds_147:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12AE6, 0x44
; [nakarest] StyleVar_SmokeyJazzClub  +0x12b2a..+0x12bae (0xec9ce8, 132 B)
; [nakarest] Text (132 B at 0xec9ce8), first string "l\x9D\xEC"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at 0xecefd8).
StyleVar_SmokeyJazzClub:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12B2A, 0x84
; [nakarest] NakaInst_Slide_Scale_Jazz_70  +0x12bae..+0x12bd0 (0xec9d6c, 34 B)
; [nakarest] Text (34 B at 0xec9d6c), first string "Slide Scale Jazz 70"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_SmokeyJazzClub (at
; [nakarest] 0xec9ce8).
NakaInst_Slide_Scale_Jazz_70:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12BAE, 0x22
; [nakarest] StyleVar_JazzAt3am  +0x12bd0..+0x12bee (0xec9d8e, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xec9d8e not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecefe0).
StyleVar_JazzAt3am:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12BD0, 0x1E
; [nakarest] NakaInst_Unwind_To_This_72  +0x12bee..+0x12c76 (0xec9dac, 136 B)
; [nakarest] Text (136 B at 0xec9dac), first string "Unwind To This 72"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_JazzAt3am (at
; [nakarest] 0xec9da0, 0xec9d9a, 0xec9d94).
NakaInst_Unwind_To_This_72:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12BEE, 0x88
; [nakarest] StyleVar_SteadyJazz34  +0x12c76..+0x12cb6 (0xec9e34, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xec9e34 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecefe8).
StyleVar_SteadyJazz34:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12C76, 0x40
; [nakarest] NakaInst_Do_You_Reed_It_158  +0x12cb6..+0x12d1c (0xec9e74, 102 B)
; [nakarest] Text (102 B at 0xec9e74), first string "Do You Reed It? 158"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_SteadyJazz34 (at
; [nakarest] 0xec9e40, 0xec9e3a, 0xec9e34).
NakaInst_Do_You_Reed_It_158:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12CB6, 0x66
; [nakarest] StyleVar_SlowJazz34  +0x12d1c..+0x12d7e (0xec9eda, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xec9eda not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xeceff0).
StyleVar_SlowJazz34:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12D1C, 0x62
; [nakarest] NakaInst_Toots_Trick_150  +0x12d7e..+0x12dc2 (0xec9f3c, 68 B)
; [nakarest] Text (68 B at 0xec9f3c), first string "Toots' Trick! 150"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_SlowJazz34 (at 0xec9ee0,
; [nakarest] 0xec9eda).
NakaInst_Toots_Trick_150:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12D7E, 0x44
; [nakarest] StyleVar_TheGroove  +0x12dc2..+0x12e46 (0xec9f80, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xec9f80 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xeceff8).
StyleVar_TheGroove:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12DC2, 0x84
; [nakarest] NakaInst_Soprano_Groove_180  +0x12e46..+0x12e68 (0xeca004, 34 B)
; [nakarest] Text (34 B at 0xeca004), first string "Soprano Groove 180"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_TheGroove (at
; [nakarest] 0xec9f80).
NakaInst_Soprano_Groove_180:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12E46, 0x22
; [nakarest] StyleVar_LAFusion  +0x12e68..+0x12e86 (0xeca026, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xeca026 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_FunkFusion_Table (at 0xecf000).
StyleVar_LAFusion:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12E68, 0x1E
; [nakarest] NakaInst_Fusion_Tines_98_ECA044  +0x12e86..+0x12f0e (0xeca044, 136 B)
; [nakarest] Text (136 B at 0xeca044), first string "Fusion Tines 98"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in StyleVar_LAFusion (at 0xeca038,
; [nakarest] 0xeca032, 0xeca02c).
NakaInst_Fusion_Tines_98_ECA044:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12E86, 0x88
; [nakarest] StyleVar_MusicalOverture  +0x12f0e..+0x12f4e (0xeca0cc, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xeca0cc not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf22c).
StyleVar_MusicalOverture:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12F0E, 0x40
; [nakarest] NakaInst_In_The_Limelight_132  +0x12f4e..+0x12fb4 (0xeca10c, 102 B)
; [nakarest] Text (102 B at 0xeca10c), first string "In The Limelight 132"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_MusicalOverture (at
; [nakarest] 0xeca0d8, 0xeca0d2, 0xeca0cc).
NakaInst_In_The_Limelight_132:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12F4E, 0x66
; [nakarest] StyleVar_Tinseltown  +0x12fb4..+0x13016 (0xeca172, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xeca172 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf234).
StyleVar_Tinseltown:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x12FB4, 0x62
; [nakarest] NakaInst_Fred_Ginger_120  +0x13016..+0x1305a (0xeca1d4, 68 B)
; [nakarest] Text (68 B at 0xeca1d4), first string "Fred & Ginger 120"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_Tinseltown (at 0xeca178,
; [nakarest] 0xeca172).
NakaInst_Fred_Ginger_120:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13016, 0x44
; [nakarest] StyleVar_Showband  +0x1305a..+0x130de (0xeca218, 132 B)
; [nakarest] Text (132 B at 0xeca218), first string "\x9C\xA2\xEC"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf23c).
StyleVar_Showband:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1305A, 0x84
; [nakarest] NakaInst_Mallets_On_Stage_135  +0x130de..+0x13100 (0xeca29c, 34 B)
; [nakarest] Text (34 B at 0xeca29c), first string "Mallets On Stage 135"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_Showband (at
; [nakarest] 0xeca218).
NakaInst_Mallets_On_Stage_135:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x130DE, 0x22
; [nakarest] StyleVar_TheatreStride  +0x13100..+0x1311e (0xeca2be, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xeca2be not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf244).
StyleVar_TheatreStride:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13100, 0x1E
; [nakarest] NakaInst_Vaudeville_Bones_124  +0x1311e..+0x131a6 (0xeca2dc, 136 B)
; [nakarest] Text (136 B at 0xeca2dc), first string "Vaudeville Bones 124"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_TheatreStride (at
; [nakarest] 0xeca2d0, 0xeca2ca, 0xeca2c4).
NakaInst_Vaudeville_Bones_124:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1311E, 0x88
; [nakarest] StyleVar_VaudevilleAct  +0x131a6..+0x131e6 (0xeca364, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xeca364 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf24c).
StyleVar_VaudevilleAct:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x131A6, 0x40
; [nakarest] NakaInst_Skeleton_Dance_165  +0x131e6..+0x1324c (0xeca3a4, 102 B)
; [nakarest] Text (102 B at 0xeca3a4), first string "Skeleton Dance 165"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_VaudevilleAct (at
; [nakarest] 0xeca370, 0xeca36a, 0xeca364).
NakaInst_Skeleton_Dance_165:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x131E6, 0x66
; [nakarest] StyleVar_TapDancer  +0x1324c..+0x132ae (0xeca40a, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xeca40a not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf254).
StyleVar_TapDancer:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1324C, 0x62
; [nakarest] NakaInst_Yankee_Doodle_It_182  +0x132ae..+0x132f2 (0xeca46c, 68 B)
; [nakarest] Text (68 B at 0xeca46c), first string "Yankee Doodle It 182"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_TapDancer (at
; [nakarest] 0xeca410, 0xeca40a).
NakaInst_Yankee_Doodle_It_182:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x132AE, 0x44
; [nakarest] StyleVar_ParisClub  +0x132f2..+0x13376 (0xeca4b0, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xeca4b0 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf25c).
StyleVar_ParisClub:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x132F2, 0x84
; [nakarest] NakaInst_Take_Your_Seat_118  +0x13376..+0x13398 (0xeca534, 34 B)
; [nakarest] Text (34 B at 0xeca534), first string "Take Your Seat! 118"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_ParisClub (at
; [nakarest] 0xeca4b0).
NakaInst_Take_Your_Seat_118:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13376, 0x22
; [nakarest] StyleVar_CabaretBand  +0x13398..+0x133b6 (0xeca556, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xeca556 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf264).
StyleVar_CabaretBand:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13398, 0x1E
; [nakarest] NakaInst_Midnight_Soloist_162  +0x133b6..+0x1343e (0xeca574, 136 B)
; [nakarest] Text (136 B at 0xeca574), first string "Midnight Soloist 162"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_CabaretBand (at
; [nakarest] 0xeca568, 0xeca562, 0xeca55c).
NakaInst_Midnight_Soloist_162:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x133B6, 0x88
; [nakarest] StyleVar_VivaLasVegas  +0x1343e..+0x1347e (0xeca5fc, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xeca5fc not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf26c).
StyleVar_VivaLasVegas:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1343E, 0x40
; [nakarest] NakaInst_Vegas_Showman_75  +0x1347e..+0x134e4 (0xeca63c, 102 B)
; [nakarest] Text (102 B at 0xeca63c), first string "Vegas Showman 75"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_VivaLasVegas (at 0xeca608,
; [nakarest] 0xeca602, 0xeca5fc).
NakaInst_Vegas_Showman_75:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1347E, 0x66
; [nakarest] StyleVar_MagicBallroom  +0x134e4..+0x13546 (0xeca6a2, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xeca6a2 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf274).
StyleVar_MagicBallroom:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x134E4, 0x62
; [nakarest] NakaInst_Strasser_More_120  +0x13546..+0x1358a (0xeca704, 68 B)
; [nakarest] Text (68 B at 0xeca704), first string "Strasser & More 120"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_MagicBallroom (at
; [nakarest] 0xeca6a8, 0xeca6a2).
NakaInst_Strasser_More_120:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13546, 0x44
; [nakarest] StyleVar_GentleFoxtrot  +0x1358a..+0x1360e (0xeca748, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xeca748 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf27c).
StyleVar_GentleFoxtrot:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1358A, 0x84
; [nakarest] NakaInst_Foxy_Squeezebox_154_ECA7CC  +0x1360e..+0x13630 (0xeca7cc, 34 B)
; [nakarest] Text (34 B at 0xeca7cc), first string "Foxy Squeezebox 154"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_GentleFoxtrot (at
; [nakarest] 0xeca748).
NakaInst_Foxy_Squeezebox_154_ECA7CC:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1360E, 0x22
; [nakarest] StyleVar_OrganistsDance  +0x13630..+0x1364e (0xeca7ee, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xeca7ee not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf284).
StyleVar_OrganistsDance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13630, 0x1E
; [nakarest] NakaInst_Old_Wheels_Dance_190  +0x1364e..+0x136d6 (0xeca80c, 136 B)
; [nakarest] Text (136 B at 0xeca80c), first string "Old Wheels Dance 190"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_OrganistsDance (at
; [nakarest] 0xeca800, 0xeca7fa, 0xeca7f4).
NakaInst_Old_Wheels_Dance_190:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1364E, 0x88
; [nakarest] StyleVar_UpTempoFoxtrot  +0x136d6..+0x13716 (0xeca894, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xeca894 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf28c).
StyleVar_UpTempoFoxtrot:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x136D6, 0x40
; [nakarest] NakaInst_Foxy_Brassy_170  +0x13716..+0x1377c (0xeca8d4, 102 B)
; [nakarest] Text (102 B at 0xeca8d4), first string "Foxy & Brassy 170"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_UpTempoFoxtrot (at
; [nakarest] 0xeca8a0, 0xeca89a, 0xeca894).
NakaInst_Foxy_Brassy_170:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13716, 0x66
; [nakarest] StyleVar_StrictlyFoxtrot  +0x1377c..+0x137de (0xeca93a, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xeca93a not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf294).
StyleVar_StrictlyFoxtrot:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1377C, 0x62
; [nakarest] NakaInst_Come_Dancing_120  +0x137de..+0x13822 (0xeca99c, 68 B)
; [nakarest] Text (68 B at 0xeca99c), first string "Come Dancing! 120"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_StrictlyFoxtrot (at
; [nakarest] 0xeca940, 0xeca93a).
NakaInst_Come_Dancing_120:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x137DE, 0x44
; [nakarest] StyleVar_RadioFoxtrot  +0x13822..+0x138a6 (0xeca9e0, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xeca9e0 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf29c).
StyleVar_RadioFoxtrot:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13822, 0x84
; [nakarest] NakaInst_Wunder_Fox_168  +0x138a6..+0x138c8 (0xecaa64, 34 B)
; [nakarest] Text (34 B at 0xecaa64), first string "Wunder-Fox 168"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_RadioFoxtrot (at 0xeca9e0).
NakaInst_Wunder_Fox_168:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x138A6, 0x22
; [nakarest] StyleVar_StrictlyQuick  +0x138c8..+0x138e6 (0xecaa86, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xecaa86 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf2a4).
StyleVar_StrictlyQuick:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x138C8, 0x1E
; [nakarest] NakaInst_Organ_Quickstep_200  +0x138e6..+0x1396e (0xecaaa4, 136 B)
; [nakarest] Text (136 B at 0xecaaa4), first string "Organ Quickstep 200"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_StrictlyQuick (at
; [nakarest] 0xecaa98, 0xecaa92, 0xecaa8c).
NakaInst_Organ_Quickstep_200:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x138E6, 0x88
; [nakarest] StyleVar_LetsTwist  +0x1396e..+0x139ae (0xecab2c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecab2c not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf2ac).
StyleVar_LetsTwist:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1396E, 0x40
; [nakarest] NakaInst_Solid_Twist_168  +0x139ae..+0x13a14 (0xecab6c, 102 B)
; [nakarest] Text (102 B at 0xecab6c), first string "Solid Twist 168"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_LetsTwist (at 0xecab38,
; [nakarest] 0xecab32, 0xecab2c).
NakaInst_Solid_Twist_168:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x139AE, 0x66
; [nakarest] StyleVar_JiveDance  +0x13a14..+0x13a76 (0xecabd2, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xecabd2 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf2b4).
StyleVar_JiveDance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13A14, 0x62
; [nakarest] NakaInst_Dance_Band_Jive_176_ECAC34  +0x13a76..+0x13aba (0xecac34, 68 B)
; [nakarest] Text (68 B at 0xecac34), first string "Dance Band Jive 176"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_JiveDance (at
; [nakarest] 0xecabd8, 0xecabd2).
NakaInst_Dance_Band_Jive_176_ECAC34:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13A76, 0x44
; [nakarest] StyleVar_DoTheTwist  +0x13aba..+0x13b3e (0xecac78, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xecac78 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf2bc).
StyleVar_DoTheTwist:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13ABA, 0x84
; [nakarest] NakaInst_Bari_Twist_155  +0x13b3e..+0x13b60 (0xecacfc, 34 B)
; [nakarest] Text (34 B at 0xecacfc), first string "Bari-Twist 155"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_DoTheTwist (at 0xecac78).
NakaInst_Bari_Twist_155:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13B3E, 0x22
; [nakarest] StyleVar_12ChaChaCha  +0x13b60..+0x13b7e (0xecad1e, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xecad1e not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf2c4).
StyleVar_12ChaChaCha:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13B60, 0x1E
; [nakarest] NakaInst_Sequin_Dance_128  +0x13b7e..+0x13c06 (0xecad3c, 136 B)
; [nakarest] Text (136 B at 0xecad3c), first string "Sequin Dance 128"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in StyleVar_12ChaChaCha (at 0xecad30,
; [nakarest] 0xecad2a, 0xecad24).
NakaInst_Sequin_Dance_128:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13B7E, 0x88
; [nakarest] StyleVar_LetsBeguine  +0x13c06..+0x13c46 (0xecadc4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecadc4 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf2cc).
StyleVar_LetsBeguine:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13C06, 0x40
; [nakarest] NakaInst_Beguine_Romance_118  +0x13c46..+0x13cac (0xecae04, 102 B)
; [nakarest] Text (102 B at 0xecae04), first string "Beguine Romance 118"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_LetsBeguine (at
; [nakarest] 0xecadd0, 0xecadca, 0xecadc4).
NakaInst_Beguine_Romance_118:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13C46, 0x66
; [nakarest] StyleVar_SambaFelicidade  +0x13cac..+0x13d0e (0xecae6a, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xecae6a not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf2d4).
StyleVar_SambaFelicidade:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13CAC, 0x62
; [nakarest] NakaInst_Samba_Testamento_115  +0x13d0e..+0x13d52 (0xecaecc, 68 B)
; [nakarest] Text (68 B at 0xecaecc), first string "Samba Testamento 115"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_SambaFelicidade (at
; [nakarest] 0xecae70, 0xecae6a).
NakaInst_Samba_Testamento_115:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13D0E, 0x44
; [nakarest] StyleVar_VivaPasodoble  +0x13d52..+0x13dd6 (0xecaf10, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xecaf10 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf2dc).
StyleVar_VivaPasodoble:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13D52, 0x84
; [nakarest] NakaInst_Espana_Two_Step_118  +0x13dd6..+0x13df8 (0xecaf94, 34 B)
; [nakarest] Text (34 B at 0xecaf94), first string "Espana Two Step 118"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_VivaPasodoble (at
; [nakarest] 0xecaf10).
NakaInst_Espana_Two_Step_118:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13DD6, 0x22
; [nakarest] StyleVar_StrictTango  +0x13df8..+0x13e16 (0xecafb6, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xecafb6 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf2e4).
StyleVar_StrictTango:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13DF8, 0x1E
; [nakarest] NakaInst_Tango_Marcato_120  +0x13e16..+0x13e9e (0xecafd4, 136 B)
; [nakarest] Text (136 B at 0xecafd4), first string "Tango Marcato 120"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_StrictTango (at
; [nakarest] 0xecafc8, 0xecafc2, 0xecafbc).
NakaInst_Tango_Marcato_120:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13E16, 0x88
; [nakarest] StyleVar_TangoDAmour  +0x13e9e..+0x13fea (0xecb05c, 332 B)
; [nakarest] purpose not established: layout of 332 B at 0xecb05c not derived; readers below
; [nakarest] Readers: 2 data words in StyleGroup_JazzCombo_Table (at 0xecf2ec, 0xecf2f4).
StyleVar_TangoDAmour:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13E9E, 0x14C
; [nakarest] StyleVar_LastDanceWaltz  +0x13fea..+0x1406e (0xecb1a8, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xecb1a8 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf2fc).
StyleVar_LastDanceWaltz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x13FEA, 0x84
; [nakarest] NakaInst_Concertina_Waltz_96  +0x1406e..+0x14090 (0xecb22c, 34 B)
; [nakarest] Text (34 B at 0xecb22c), first string "Concertina Waltz 96"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_LastDanceWaltz (at
; [nakarest] 0xecb1a8).
NakaInst_Concertina_Waltz_96:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1406E, 0x22
; [nakarest] StyleVar_QuickWaltz  +0x14090..+0x14282 (0xecb24e, 498 B)
; [nakarest] purpose not established: layout of 498 B at 0xecb24e not derived; readers below
; [nakarest] Readers: 3 data words in StyleGroup_JazzCombo_Table (at 0xecf304, 0xecf30c,
; [nakarest] 0xecf314).
StyleVar_QuickWaltz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14090, 0x1F2
; [nakarest] StyleVar_PartyVienna  +0x14282..+0x14306 (0xecb440, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xecb440 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_JazzCombo_Table (at 0xecf31c).
StyleVar_PartyVienna:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14282, 0x84
; [nakarest] NakaInst_Ball_Gown_Waltz_171  +0x14306..+0x14346 (0xecb4c4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecb4c4 not derived; readers below
; [nakarest] Readers: 1 data word in StyleVar_PartyVienna (at 0xecb440); 1 data word in
; [nakarest] StyleGroup_TradFolk_PairTable (at 0xecf55a).
NakaInst_Ball_Gown_Waltz_171:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14306, 0x40
; [nakarest] NakaInst_Full_Brass_Band_115_ECB504  +0x14346..+0x1440e (0xecb504, 200 B)
; [nakarest] Text (200 B at 0xecb504), first string "Full Brass Band 115"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Ball_Gown_Waltz_171
; [nakarest] (at 0xecb4f8, 0xecb4f2, 0xecb4ec); 1 data word in StyleGroup_TradFolk_PairTable (at
; [nakarest] 0xecf562).
NakaInst_Full_Brass_Band_115_ECB504:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14346, 0xC8
; [nakarest] NakaInst_Alto_Marchpast_115  +0x1440e..+0x144d6 (0xecb5cc, 200 B)
; [nakarest] Text (200 B at 0xecb5cc), first string "Alto Marchpast 115"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in
; [nakarest] NakaInst_Full_Brass_Band_115_ECB504 (at 0xecb598, 0xecb592, 0xecb58c); 1 data word
; [nakarest] in StyleGroup_TradFolk_PairTable (at 0xecf56a).
NakaInst_Alto_Marchpast_115:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1440E, 0xC8
; [nakarest] NakaInst_OktoberFest_109  +0x144d6..+0x1459e (0xecb694, 200 B)
; [nakarest] Text (200 B at 0xecb694), first string "OktoberFest 109"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in NakaInst_Alto_Marchpast_115 (at
; [nakarest] 0xecb638, 0xecb632); 1 data word in StyleGroup_TradFolk_PairTable (at 0xecf572).
NakaInst_OktoberFest_109:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x144D6, 0xC8
; [nakarest] NakaInst_At_The_Eger_120_ECB75C  +0x1459e..+0x145de (0xecb75c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecb75c not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_OktoberFest_109 (at 0xecb6d8); 1 data word in
; [nakarest] StyleGroup_TradFolk_PairTable (at 0xecf57a).
NakaInst_At_The_Eger_120_ECB75C:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1459E, 0x40
; [nakarest] NakaInst_Marching_Polka_124  +0x145de..+0x146a6 (0xecb79c, 200 B)
; [nakarest] Text (200 B at 0xecb79c), first string "Marching Polka 124"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in
; [nakarest] NakaInst_At_The_Eger_120_ECB75C (at 0xecb790, 0xecb78a, 0xecb784); 1 data word in
; [nakarest] StyleGroup_TradFolk_PairTable (at 0xecf582).
NakaInst_Marching_Polka_124:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x145DE, 0xC8
; [nakarest] NakaInst_Wedding_Party_135  +0x146a6..+0x1476e (0xecb864, 200 B)
; [nakarest] Text (200 B at 0xecb864), first string "Wedding Party 135"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaInst_Marching_Polka_124
; [nakarest] (at 0xecb830, 0xecb82a, 0xecb824); 1 data word in StyleGroup_TradFolk_PairTable (at
; [nakarest] 0xecf58a).
NakaInst_Wedding_Party_135:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x146A6, 0xC8
; [nakarest] NakaInst_Alpine_Combo_125_ECB92C  +0x1476e..+0x14836 (0xecb92c, 200 B)
; [nakarest] Text (200 B at 0xecb92c), first string "Alpine Combo 125"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in NakaInst_Wedding_Party_135 (at
; [nakarest] 0xecb8d0, 0xecb8ca); 1 data word in StyleGroup_TradFolk_PairTable (at 0xecf592).
NakaInst_Alpine_Combo_125_ECB92C:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1476E, 0xC8
; [nakarest] NakaInst_Emerald_Flute_120  +0x14836..+0x14876 (0xecb9f4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecb9f4 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Alpine_Combo_125_ECB92C (at 0xecb970); 1 data word
; [nakarest] in StyleGroup_TradFolk_PairTable (at 0xecf59a).
NakaInst_Emerald_Flute_120:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14836, 0x40
; [nakarest] NakaInst_Scottish_Band_172  +0x14876..+0x1493e (0xecba34, 200 B)
; [nakarest] Text (200 B at 0xecba34), first string "Scottish Band 172"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Emerald_Flute_120
; [nakarest] (at 0xecba28, 0xecba22, 0xecba1c); 1 data word in StyleGroup_TradFolk_PairTable (at
; [nakarest] 0xecf5a2).
NakaInst_Scottish_Band_172:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14876, 0xC8
; [nakarest] NakaInst_Waltzing_Concert_169  +0x1493e..+0x14a06 (0xecbafc, 200 B)
; [nakarest] Text (200 B at 0xecbafc), first string "Waltzing Concert 169"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaInst_Scottish_Band_172
; [nakarest] (at 0xecbac8, 0xecbac2, 0xecbabc); 1 data word in StyleGroup_TradFolk_PairTable (at
; [nakarest] 0xecf5aa).
NakaInst_Waltzing_Concert_169:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1493E, 0xC8
; [nakarest] NakaInst_Matterhorn_Waltz_197  +0x14a06..+0x14ace (0xecbbc4, 200 B)
; [nakarest] Text (200 B at 0xecbbc4), first string "Matterhorn Waltz 197"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in NakaInst_Waltzing_Concert_169
; [nakarest] (at 0xecbb68, 0xecbb62); 1 data word in StyleGroup_TradFolk_PairTable (at
; [nakarest] 0xecf5b2).
NakaInst_Matterhorn_Waltz_197:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14A06, 0xC8
; [nakarest] NakaInst_Mazurka_Clarinet_150  +0x14ace..+0x14b0e (0xecbc8c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecbc8c not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Matterhorn_Waltz_197 (at 0xecbc08); 1 data word in
; [nakarest] StyleGroup_TradFolk_PairTable (at 0xecf5ba).
NakaInst_Mazurka_Clarinet_150:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14ACE, 0x40
; [nakarest] NakaInst_Tiroler_Harp_190  +0x14b0e..+0x14bd6 (0xecbccc, 200 B)
; [nakarest] Text (200 B at 0xecbccc), first string "Tiroler Harp 190"; no registered NAKA table
; [nakarest] points into it; reached through 4 data words in NakaInst_Mazurka_Clarinet_150 (at
; [nakarest] 0xecbcc0, 0xecbcba, 0xecbcb4); 1 data word in StyleGroup_TradFolk_PairTable (at
; [nakarest] 0xecf5c2).
NakaInst_Tiroler_Harp_190:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14B0E, 0xC8
; [nakarest] NakaInst_Waikiki_Voices_101  +0x14bd6..+0x14c9e (0xecbd94, 200 B)
; [nakarest] Text (200 B at 0xecbd94), first string "Waikiki Voices 101"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaInst_Tiroler_Harp_190 (at
; [nakarest] 0xecbd60, 0xecbd5a, 0xecbd54); 1 data word in StyleGroup_TradFolk_PairTable (at
; [nakarest] 0xecf5ca).
NakaInst_Waikiki_Voices_101:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14BD6, 0xC8
; [nakarest] NakaInst_Hula_Dance_130  +0x14c9e..+0x14d66 (0xecbe5c, 200 B)
; [nakarest] Text (200 B at 0xecbe5c), first string "Hula Dance 130"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in NakaInst_Waikiki_Voices_101 (at
; [nakarest] 0xecbe00, 0xecbdfa); 1 data word in StyleGroup_TradFolk_PairTable (at 0xecf5d2).
NakaInst_Hula_Dance_130:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14C9E, 0xC8
; [nakarest] NakaInst_Syncopated_Wood_130  +0x14d66..+0x14da6 (0xecbf24, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecbf24 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Hula_Dance_130 (at 0xecbea0); 1 data word in
; [nakarest] StyleGroup_TradFolk_PairTable (at 0xecf5da).
NakaInst_Syncopated_Wood_130:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14D66, 0x40
; [nakarest] NakaInst_Maple_Leaf_Piano_180  +0x14da6..+0x14e6e (0xecbf64, 200 B)
; [nakarest] Text (200 B at 0xecbf64), first string "Maple Leaf Piano 180"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Syncopated_Wood_130
; [nakarest] (at 0xecbf58, 0xecbf52, 0xecbf4c); 1 data word in StyleGroup_TradFolk_PairTable (at
; [nakarest] 0xecf5e2).
NakaInst_Maple_Leaf_Piano_180:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14DA6, 0xC8
; [nakarest] NakaInst_Barber_Shop_Jazz_196_ECC02C  +0x14e6e..+0x14f36 (0xecc02c, 200 B)
; [nakarest] Text (200 B at 0xecc02c), first string "Barber Shop Jazz 196"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaInst_Maple_Leaf_Piano_180
; [nakarest] (at 0xecbff8, 0xecbff2, 0xecbfec); 1 data word in StyleGroup_TradFolk_PairTable (at
; [nakarest] 0xecf5ea).
NakaInst_Barber_Shop_Jazz_196_ECC02C:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14E6E, 0xC8
; [nakarest] NakaInst_Liquorice_Dixie_185  +0x14f36..+0x14ffe (0xecc0f4, 200 B)
; [nakarest] Text (200 B at 0xecc0f4), first string "Liquorice Dixie 185"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in
; [nakarest] NakaInst_Barber_Shop_Jazz_196_ECC02C (at 0xecc098, 0xecc092); 1 data word in
; [nakarest] StyleGroup_TradFolk_PairTable (at 0xecf5f2).
NakaInst_Liquorice_Dixie_185:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14F36, 0xC8
; [nakarest] NakaInst_Never_On_A_120  +0x14ffe..+0x1503e (0xecc1bc, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecc1bc not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Liquorice_Dixie_185 (at 0xecc138); 1 data word in
; [nakarest] StyleGroup_TradFolk_PairTable (at 0xecf5fa).
NakaInst_Never_On_A_120:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x14FFE, 0x40
; [nakarest] NakaInst_Cossack_Strings_141  +0x1503e..+0x15106 (0xecc1fc, 200 B)
; [nakarest] Text (200 B at 0xecc1fc), first string "Cossack Strings 141"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Never_On_A_120 (at
; [nakarest] 0xecc1f0, 0xecc1ea, 0xecc1e4); 1 data word in StyleGroup_TradFolk_PairTable (at
; [nakarest] 0xecf602).
NakaInst_Cossack_Strings_141:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1503E, 0xC8
; [nakarest] NakaInst_Hungarian_Duet_115  +0x15106..+0x151ce (0xecc2c4, 200 B)
; [nakarest] Text (200 B at 0xecc2c4), first string "Hungarian Duet 115"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaInst_Cossack_Strings_141
; [nakarest] (at 0xecc290, 0xecc28a, 0xecc284); 1 data word in StyleGroup_TradFolk_PairTable (at
; [nakarest] 0xecf60a).
NakaInst_Hungarian_Duet_115:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15106, 0xC8
; [nakarest] NakaInst_Spider_Dance_128  +0x151ce..+0x15296 (0xecc38c, 200 B)
; [nakarest] Text (200 B at 0xecc38c), first string "Spider Dance 128"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in NakaInst_Hungarian_Duet_115 (at
; [nakarest] 0xecc330, 0xecc32a); 1 data word in StyleGroup_TradFolk_PairTable (at 0xecf612).
NakaInst_Spider_Dance_128:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x151CE, 0xC8
; [nakarest] NakaInst_Jalapeno_Bellows_112  +0x15296..+0x152d6 (0xecc454, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecc454 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_Spider_Dance_128 (at 0xecc3d0); 1 data word in
; [nakarest] StyleGroup_TradFolk_PairTable (at 0xecf61a).
NakaInst_Jalapeno_Bellows_112:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15296, 0x40
; [nakarest] NakaInst_Solid_Distortion_122  +0x152d6..+0x1535e (0xecc494, 136 B)
; [nakarest] Text (136 B at 0xecc494), first string "Solid Distortion 122"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in NakaInst_Jalapeno_Bellows_112
; [nakarest] (at 0xecc488, 0xecc482, 0xecc47c).
NakaInst_Solid_Distortion_122:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x152D6, 0x88
; [nakarest] StyleVar_BluegrassTime  +0x1535e..+0x1539e (0xecc51c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecc51c not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf7ec).
StyleVar_BluegrassTime:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1535E, 0x40
; [nakarest] NakaInst_Cajun_Hoedown_124  +0x1539e..+0x15404 (0xecc55c, 102 B)
; [nakarest] Text (102 B at 0xecc55c), first string "Cajun Hoedown 124"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_BluegrassTime (at
; [nakarest] 0xecc528, 0xecc522, 0xecc51c).
NakaInst_Cajun_Hoedown_124:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1539E, 0x66
; [nakarest] StyleVar_ModernHoedown  +0x15404..+0x15466 (0xecc5c2, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xecc5c2 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf7f4).
StyleVar_ModernHoedown:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15404, 0x62
; [nakarest] NakaInst_Country_Licks_235_ECC624  +0x15466..+0x154aa (0xecc624, 68 B)
; [nakarest] Text (68 B at 0xecc624), first string "Country Licks 235"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in StyleVar_ModernHoedown (at
; [nakarest] 0xecc5c8, 0xecc5c2).
NakaInst_Country_Licks_235_ECC624:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15466, 0x44
; [nakarest] StyleVar_KentuckyBlue  +0x154aa..+0x1552e (0xecc668, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xecc668 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf7fc).
StyleVar_KentuckyBlue:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x154AA, 0x84
; [nakarest] NakaInst_Country_Fiddle_123  +0x1552e..+0x15550 (0xecc6ec, 34 B)
; [nakarest] Text (34 B at 0xecc6ec), first string "Country Fiddle 123"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_KentuckyBlue (at
; [nakarest] 0xecc668).
NakaInst_Country_Fiddle_123:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1552E, 0x22
; [nakarest] StyleVar_TruckerCountry  +0x15550..+0x1556e (0xecc70e, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xecc70e not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf804).
StyleVar_TruckerCountry:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15550, 0x1E
; [nakarest] NakaInst_Fogerty_s_Stomp_206_ECC72C  +0x1556e..+0x155f6 (0xecc72c, 136 B)
; [nakarest] Text (136 B at 0xecc72c), first string "Fogerty's Stomp 206"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_TruckerCountry (at
; [nakarest] 0xecc720, 0xecc71a, 0xecc714).
NakaInst_Fogerty_s_Stomp_206_ECC72C:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1556E, 0x88
; [nakarest] StyleVar_CountryDance  +0x155f6..+0x15636 (0xecc7b4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecc7b4 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf80c).
StyleVar_CountryDance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x155F6, 0x40
; [nakarest] NakaInst_Nashville_Dance_147  +0x15636..+0x1569c (0xecc7f4, 102 B)
; [nakarest] Text (102 B at 0xecc7f4), first string "Nashville Dance 147"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_CountryDance (at
; [nakarest] 0xecc7c0, 0xecc7ba, 0xecc7b4).
NakaInst_Nashville_Dance_147:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15636, 0x66
; [nakarest] StyleVar_HillbillyBlues  +0x1569c..+0x156fe (0xecc85a, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xecc85a not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf814).
StyleVar_HillbillyBlues:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1569C, 0x62
; [nakarest] NakaInst_Steel_City_Blues_128  +0x156fe..+0x15742 (0xecc8bc, 68 B)
; [nakarest] Text (68 B at 0xecc8bc), first string "Steel City Blues 128"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_HillbillyBlues (at
; [nakarest] 0xecc860, 0xecc85a).
NakaInst_Steel_City_Blues_128:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x156FE, 0x44
; [nakarest] StyleVar_70sCountryPop  +0x15742..+0x157c6 (0xecc900, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xecc900 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf81c).
StyleVar_70sCountryPop:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15742, 0x84
; [nakarest] NakaInst_Karen_s_Country_173  +0x157c6..+0x157e8 (0xecc984, 34 B)
; [nakarest] Text (34 B at 0xecc984), first string "Karen's Country 173"; no registered NAKA
; [nakarest] table points into it; reached through 1 data word in StyleVar_70sCountryPop (at
; [nakarest] 0xecc900).
NakaInst_Karen_s_Country_173:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x157C6, 0x22
; [nakarest] StyleVar_CountryRomance  +0x157e8..+0x15806 (0xecc9a6, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xecc9a6 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf824).
StyleVar_CountryRomance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x157E8, 0x1E
; [nakarest] NakaInst_Kentucky_Vocals_88  +0x15806..+0x1588e (0xecc9c4, 136 B)
; [nakarest] Text (136 B at 0xecc9c4), first string "Kentucky Vocals 88"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_CountryRomance (at
; [nakarest] 0xecc9b8, 0xecc9b2, 0xecc9ac).
NakaInst_Kentucky_Vocals_88:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15806, 0x88
; [nakarest] StyleVar_WesternBallads  +0x1588e..+0x158ce (0xecca4c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecca4c not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf82c).
StyleVar_WesternBallads:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1588E, 0x40
; [nakarest] NakaInst_Cowboy_Saxes_85  +0x158ce..+0x15934 (0xecca8c, 102 B)
; [nakarest] Text (102 B at 0xecca8c), first string "Cowboy Saxes 85"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_WesternBallads (at
; [nakarest] 0xecca58, 0xecca52, 0xecca4c).
NakaInst_Cowboy_Saxes_85:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x158CE, 0x66
; [nakarest] StyleVar_CountryFolks  +0x15934..+0x15996 (0xeccaf2, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xeccaf2 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf834).
StyleVar_CountryFolks:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15934, 0x62
; [nakarest] NakaInst_South_Concertina_170  +0x15996..+0x159da (0xeccb54, 68 B)
; [nakarest] Text (68 B at 0xeccb54), first string "South Concertina 170"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_CountryFolks (at
; [nakarest] 0xeccaf8, 0xeccaf2).
NakaInst_South_Concertina_170:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15996, 0x44
; [nakarest] StyleVar_Country88  +0x159da..+0x15a5e (0xeccb98, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xeccb98 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf83c).
StyleVar_Country88:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x159DA, 0x84
; [nakarest] NakaInst_Wandrin_Keys_75  +0x15a5e..+0x15a80 (0xeccc1c, 34 B)
; [nakarest] Text (34 B at 0xeccc1c), first string "Wandrin' Keys 75"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_Country88 (at 0xeccb98).
NakaInst_Wandrin_Keys_75:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15A5E, 0x22
; [nakarest] StyleVar_CountryLove  +0x15a80..+0x15a9e (0xeccc3e, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xeccc3e not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf844).
StyleVar_CountryLove:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15A80, 0x1E
; [nakarest] NakaInst_Tennessee_Guitar_88  +0x15a9e..+0x15b26 (0xeccc5c, 136 B)
; [nakarest] Text (136 B at 0xeccc5c), first string "Tennessee Guitar 88"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_CountryLove (at
; [nakarest] 0xeccc50, 0xeccc4a, 0xeccc44).
NakaInst_Tennessee_Guitar_88:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15A9E, 0x88
; [nakarest] StyleVar_ModernCountry  +0x15b26..+0x15b66 (0xeccce4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xeccce4 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf84c).
StyleVar_ModernCountry:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15B26, 0x40
; [nakarest] NakaInst_Nashville_Steel_116  +0x15b66..+0x15bcc (0xeccd24, 102 B)
; [nakarest] Text (102 B at 0xeccd24), first string "Nashville Steel 116"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in StyleVar_ModernCountry (at
; [nakarest] 0xecccf0, 0xecccea, 0xeccce4).
NakaInst_Nashville_Steel_116:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15B66, 0x66
; [nakarest] StyleVar_EZCountryRock  +0x15bcc..+0x15c2e (0xeccd8a, 98 B)
; [nakarest] purpose not established: layout of 98 B at 0xeccd8a not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf854).
StyleVar_EZCountryRock:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15BCC, 0x62
; [nakarest] NakaInst_Ricky_s_Guitar_128  +0x15c2e..+0x15c72 (0xeccdec, 68 B)
; [nakarest] Text (68 B at 0xeccdec), first string "Ricky's Guitar 128"; no registered NAKA
; [nakarest] table points into it; reached through 2 data words in StyleVar_EZCountryRock (at
; [nakarest] 0xeccd90, 0xeccd8a).
NakaInst_Ricky_s_Guitar_128:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15C2E, 0x44
; [nakarest] StyleVar_OldCountryHits  +0x15c72..+0x15cf6 (0xecce30, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xecce30 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf85c).
StyleVar_OldCountryHits:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15C72, 0x84
; [nakarest] NakaInst_Geetar_Man_113  +0x15cf6..+0x15d18 (0xecceb4, 34 B)
; [nakarest] Text (34 B at 0xecceb4), first string "Geetar Man 113"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleVar_OldCountryHits (at
; [nakarest] 0xecce30).
NakaInst_Geetar_Man_113:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15CF6, 0x22
; [nakarest] StyleVar_NewCountryRock  +0x15d18..+0x15d36 (0xecced6, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xecced6 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf864).
StyleVar_NewCountryRock:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15D18, 0x1E
; [nakarest] NakaInst_Country_Horns_115  +0x15d36..+0x15dbe (0xeccef4, 136 B)
; [nakarest] Text (136 B at 0xeccef4), first string "Country Horns 115"; no registered NAKA
; [nakarest] table points into it; reached through 4 data words in StyleVar_NewCountryRock (at
; [nakarest] 0xeccee8, 0xeccee2, 0xeccedc).
NakaInst_Country_Horns_115:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15D36, 0x88
; [nakarest] StyleVar_CountryHits  +0x15dbe..+0x15dfe (0xeccf7c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xeccf7c not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_WorldMusic_Table (at 0xecf86c).
StyleVar_CountryHits:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15DBE, 0x40
; [nakarest] NakaInst_Hard_Country_160  +0x15dfe..+0x15ec6 (0xeccfbc, 200 B)
; [nakarest] Text (200 B at 0xeccfbc), first string "Hard Country 160"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in StyleVar_CountryHits (at 0xeccf88,
; [nakarest] 0xeccf82, 0xeccf7c); 1 data word in StyleGroup_LatinWorld_PairTable (at 0xecf9ae).
NakaInst_Hard_Country_160:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15DFE, 0xC8
; [nakarest] NakaInst_Ham_Bossa_66  +0x15ec6..+0x15f8e (0xecd084, 200 B)
; [nakarest] Text (200 B at 0xecd084), first string "Ham & Bossa 66"; no registered NAKA table
; [nakarest] points into it; reached through 2 data words in NakaInst_Hard_Country_160 (at
; [nakarest] 0xecd028, 0xecd022); 1 data word in StyleGroup_LatinWorld_PairTable (at 0xecf9b6).
NakaInst_Ham_Bossa_66:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15EC6, 0xC8
; [nakarest] NakaInst_Latin_Tines_68  +0x15f8e..+0x15fce (0xecd14c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecd14c not derived; readers below
; [nakarest] Readers: source references EmbeddedPtrTable_v10_naka_style_bitmaps_018800
; [nakarest] (ui_widgets/style_bitmaps.s: `.long 0x00ecd16e`); 1 data word in
; [nakarest] NakaInst_Ham_Bossa_66 (at 0xecd0c8); 1 data word in
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at 0xecf9be).
NakaInst_Latin_Tines_68:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15F8E, 0x40
; [nakarest] NakaInst_Modern_Bossa_74  +0x15fce..+0x16096 (0xecd18c, 200 B)
; [nakarest] Text (200 B at 0xecd18c), first string "Modern Bossa 74"; no registered NAKA table
; [nakarest] points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecd214`); 4 data words in NakaInst_Latin_Tines_68 (at 0xecd180, 0xecd17a,
; [nakarest] 0xecd174); 1 data word in EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at
; [nakarest] 0xecf9c6).
NakaInst_Modern_Bossa_74:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x15FCE, 0xC8
; [nakarest] NakaInst_Julio_s_Romance_119  +0x16096..+0x1615e (0xecd254, 200 B)
; [nakarest] Text (200 B at 0xecd254), first string "Julio's Romance 119"; no registered NAKA
; [nakarest] table points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecd2ba`); 3 data words in NakaInst_Modern_Bossa_74 (at 0xecd220, 0xecd21a,
; [nakarest] 0xecd214); 1 data word in EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at
; [nakarest] 0xecf9ce).
NakaInst_Julio_s_Romance_119:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16096, 0xC8
; [nakarest] NakaInst_Besame_Strings_120_ECD31C  +0x1615e..+0x16226 (0xecd31c, 200 B)
; [nakarest] Text (200 B at 0xecd31c), first string "Besame Strings 120"; no registered NAKA
; [nakarest] table points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecd360`); 2 data words in NakaInst_Julio_s_Romance_119 (at 0xecd2c0, 0xecd2ba);
; [nakarest] 1 data word in EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at 0xecf9d6).
NakaInst_Besame_Strings_120_ECD31C:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1615E, 0xC8
; [nakarest] NakaInst_Amor_Reed_117_ECD3E4  +0x16226..+0x16266 (0xecd3e4, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecd3e4 not derived; readers below
; [nakarest] Readers: source references EmbeddedPtrTable_v10_naka_style_bitmaps_018800
; [nakarest] (ui_widgets/style_bitmaps.s: `.long 0x00ecd406`); 1 data word in
; [nakarest] NakaInst_Besame_Strings_120_ECD31C (at 0xecd360); 1 data word in
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at 0xecf9de).
NakaInst_Amor_Reed_117_ECD3E4:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16226, 0x40
; [nakarest] NakaInst_Bolero_Orchestra_120_ECD424  +0x16266..+0x1632e (0xecd424, 200 B)
; [nakarest] Text (200 B at 0xecd424), first string "Bolero Orchestra 120"; no registered NAKA
; [nakarest] table points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecd4ac`); 4 data words in NakaInst_Amor_Reed_117_ECD3E4 (at 0xecd418, 0xecd412,
; [nakarest] 0xecd40c); 1 data word in EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at
; [nakarest] 0xecf9e6).
NakaInst_Bolero_Orchestra_120_ECD424:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16266, 0xC8
; [nakarest] NakaInst_Holiday_Rhumba_115  +0x1632e..+0x163f6 (0xecd4ec, 200 B)
; [nakarest] Text (200 B at 0xecd4ec), first string "Holiday Rhumba 115"; no registered NAKA
; [nakarest] table points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecd552`); 3 data words in NakaInst_Bolero_Orchestra_120_ECD424 (at 0xecd4b8,
; [nakarest] 0xecd4b2, 0xecd4ac); 1 data word in EmbeddedPtrTable_v10_naka_style_bitmaps_018800
; [nakarest] (at 0xecf9ee).
NakaInst_Holiday_Rhumba_115:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1632E, 0xC8
; [nakarest] NakaInst_Pepito_For_Pepe_130  +0x163f6..+0x164be (0xecd5b4, 200 B)
; [nakarest] Text (200 B at 0xecd5b4), first string "Pepito For Pepe 130"; no registered NAKA
; [nakarest] table points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecd5f8`); 2 data words in NakaInst_Holiday_Rhumba_115 (at 0xecd558, 0xecd552);
; [nakarest] 1 data word in EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at 0xecf9f6).
NakaInst_Pepito_For_Pepe_130:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x163F6, 0xC8
; [nakarest] NakaInst_Mambo_Bravisimo_129  +0x164be..+0x164fe (0xecd67c, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecd67c not derived; readers below
; [nakarest] Readers: source references EmbeddedPtrTable_v10_naka_style_bitmaps_018800
; [nakarest] (ui_widgets/style_bitmaps.s: `.long 0x00ecd69e`); 1 data word in
; [nakarest] NakaInst_Pepito_For_Pepe_130 (at 0xecd5f8); 1 data word in
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at 0xecf9fe).
NakaInst_Mambo_Bravisimo_129:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x164BE, 0x40
; [nakarest] NakaInst_Modern_Ballroom_134  +0x164fe..+0x165c6 (0xecd6bc, 200 B)
; [nakarest] Text (200 B at 0xecd6bc), first string "Modern Ballroom 134"; no registered NAKA
; [nakarest] table points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecd744`); 4 data words in NakaInst_Mambo_Bravisimo_129 (at 0xecd6b0, 0xecd6aa,
; [nakarest] 0xecd6a4); 1 data word in EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at
; [nakarest] 0xecfa06).
NakaInst_Modern_Ballroom_134:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x164FE, 0xC8
; [nakarest] NakaInst_Saxy_Mambo_132  +0x165c6..+0x1668e (0xecd784, 200 B)
; [nakarest] Text (200 B at 0xecd784), first string "Saxy Mambo 132"; no registered NAKA table
; [nakarest] points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecd7ea`); 3 data words in NakaInst_Modern_Ballroom_134 (at 0xecd750, 0xecd74a,
; [nakarest] 0xecd744); 1 data word in EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at
; [nakarest] 0xecfa0e).
NakaInst_Saxy_Mambo_132:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x165C6, 0xC8
; [nakarest] NakaInst_Cumbia_Sol_90  +0x1668e..+0x16756 (0xecd84c, 200 B)
; [nakarest] Text (200 B at 0xecd84c), first string "Cumbia Sol 90"; no registered NAKA table
; [nakarest] points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecd890`); 2 data words in NakaInst_Saxy_Mambo_132 (at 0xecd7f0, 0xecd7ea); 1
; [nakarest] data word in EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at 0xecfa16).
NakaInst_Cumbia_Sol_90:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1668E, 0xC8
; [nakarest] NakaInst_Caribbean_Flute_83  +0x16756..+0x16796 (0xecd914, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecd914 not derived; readers below
; [nakarest] Readers: source references EmbeddedPtrTable_v10_naka_style_bitmaps_018800
; [nakarest] (ui_widgets/style_bitmaps.s: `.long 0x00ecd936`); 1 data word in
; [nakarest] NakaInst_Cumbia_Sol_90 (at 0xecd890); 1 data word in
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at 0xecfa1e).
NakaInst_Caribbean_Flute_83:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16756, 0x40
; [nakarest] NakaInst_Brazil_Fanfare_114  +0x16796..+0x1685e (0xecd954, 200 B)
; [nakarest] Text (200 B at 0xecd954), first string "Brazil Fanfare 114"; no registered NAKA
; [nakarest] table points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecd9dc`); 4 data words in NakaInst_Caribbean_Flute_83 (at 0xecd948, 0xecd942,
; [nakarest] 0xecd93c); 1 data word in EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at
; [nakarest] 0xecfa26).
NakaInst_Brazil_Fanfare_114:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16796, 0xC8
; [nakarest] NakaInst_Sunshine_Sax_120  +0x1685e..+0x16926 (0xecda1c, 200 B)
; [nakarest] Text (200 B at 0xecda1c), first string "Sunshine Sax 120"; no registered NAKA table
; [nakarest] points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecda82`); 3 data words in NakaInst_Brazil_Fanfare_114 (at 0xecd9e8, 0xecd9e2,
; [nakarest] 0xecd9dc); 1 data word in EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at
; [nakarest] 0xecfa2e).
NakaInst_Sunshine_Sax_120:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1685E, 0xC8
; [nakarest] NakaInst_12_String_Samba_108  +0x16926..+0x169ee (0xecdae4, 200 B)
; [nakarest] Text (200 B at 0xecdae4), first string "12 String Samba 108"; no registered NAKA
; [nakarest] table points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecdb28`); 2 data words in NakaInst_Sunshine_Sax_120 (at 0xecda88, 0xecda82); 1
; [nakarest] data word in EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at 0xecfa36).
NakaInst_12_String_Samba_108:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x16926, 0xC8
; [nakarest] NakaInst_Torero_s_Trumpet_125  +0x169ee..+0x17132 (0xecdbac, 1860 B)
; [nakarest] purpose not established: layout of 1860 B at 0xecdbac not derived; readers below
; [nakarest] Readers: source references EmbeddedPtrTable_v10_naka_style_bitmaps_018800
; [nakarest] (ui_widgets/style_bitmaps.s: `.long 0x00ecdbce`); 1 data word in
; [nakarest] NakaInst_12_String_Samba_108 (at 0xecdb28); 11 data words in
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at 0xecfa3e, 0xecfa46, 0xecfa4e).
NakaInst_Torero_s_Trumpet_125:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x169EE, 0x744
; [nakarest] StyleGroup_ModernDance_Table  +0x17132..+0x17232 (0xece2f0, 256 B)
; [nakarest] purpose not established: layout of 256 B at 0xece2f0 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_LatinDance_Table (at 0xecfca8), which is read by
; [nakarest] MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
StyleGroup_ModernDance_Table:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17132, 0x100
; [nakarest] NakaInst_Easy_Jazz_Waltz  +0x17232..+0x17244 (0xece3f0, 18 B)
; [nakarest] Text (18 B at 0xece3f0), first string "Easy Jazz Waltz "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece3e0).
NakaInst_Easy_Jazz_Waltz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17232, 0x12
; [nakarest] NakaInst_Parisian_Nights  +0x17244..+0x17256 (0xece402, 18 B)
; [nakarest] Text (18 B at 0xece402), first string "Parisian Nights "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece3d8).
NakaInst_Parisian_Nights:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17244, 0x12
; [nakarest] NakaInst_Easy_Play_Waltz  +0x17256..+0x17268 (0xece414, 18 B)
; [nakarest] Text (18 B at 0xece414), first string "Easy Play Waltz "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece3d0).
NakaInst_Easy_Play_Waltz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17256, 0x12
; [nakarest] NakaInst_Paris_Romance  +0x17268..+0x1727a (0xece426, 18 B)
; [nakarest] Text (18 B at 0xece426), first string "Paris Romance "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece3c8).
NakaInst_Paris_Romance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17268, 0x12
; [nakarest] NakaInst_Drawbar_Combo  +0x1727a..+0x1728c (0xece438, 18 B)
; [nakarest] Text (18 B at 0xece438), first string "Drawbar Combo "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece3c0).
NakaInst_Drawbar_Combo:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1727A, 0x12
; [nakarest] NakaInst_Nat_s_Ballads  +0x1728c..+0x1729e (0xece44a, 18 B)
; [nakarest] Text (18 B at 0xece44a), first string "Nat's Ballads "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece3b8).
NakaInst_Nat_s_Ballads:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1728C, 0x12
; [nakarest] NakaInst_Jazz_Serenade  +0x1729e..+0x172b0 (0xece45c, 18 B)
; [nakarest] Text (18 B at 0xece45c), first string "Jazz Serenade "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece3b0).
NakaInst_Jazz_Serenade:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1729E, 0x12
; [nakarest] NakaInst_Romantic_Band  +0x172b0..+0x172c2 (0xece46e, 18 B)
; [nakarest] Text (18 B at 0xece46e), first string "Romantic Band "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece3a8).
NakaInst_Romantic_Band:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x172B0, 0x12
; [nakarest] NakaInst_Euro_Ballads  +0x172c2..+0x172d4 (0xece480, 18 B)
; [nakarest] Text (18 B at 0xece480), first string "Euro Ballads "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece3a0).
NakaInst_Euro_Ballads:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x172C2, 0x12
; [nakarest] NakaInst_Oldie_Drawbars  +0x172d4..+0x172e6 (0xece492, 18 B)
; [nakarest] Text (18 B at 0xece492), first string "Oldie Drawbars "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece398).
NakaInst_Oldie_Drawbars:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x172D4, 0x12
; [nakarest] NakaInst_Soft_Schlager  +0x172e6..+0x172f8 (0xece4a4, 18 B)
; [nakarest] Text (18 B at 0xece4a4), first string "Soft Schlager "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece390).
NakaInst_Soft_Schlager:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x172E6, 0x12
; [nakarest] NakaInst_Oldie_Ballads  +0x172f8..+0x1730a (0xece4b6, 18 B)
; [nakarest] Text (18 B at 0xece4b6), first string "Oldie Ballads "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece388).
NakaInst_Oldie_Ballads:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x172F8, 0x12
; [nakarest] NakaInst_50_s_Love_Songs  +0x1730a..+0x1731c (0xece4c8, 18 B)
; [nakarest] Text (18 B at 0xece4c8), first string "50's Love Songs "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece380).
NakaInst_50_s_Love_Songs:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1730A, 0x12
; [nakarest] NakaInst_Night_Club_Dance  +0x1731c..+0x1732e (0xece4da, 18 B)
; [nakarest] Text (18 B at 0xece4da), first string "Night Club Dance"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece378).
NakaInst_Night_Club_Dance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1731C, 0x12
; [nakarest] NakaInst_Modern_Ballads  +0x1732e..+0x17340 (0xece4ec, 18 B)
; [nakarest] Text (18 B at 0xece4ec), first string "Modern Ballads "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece370).
NakaInst_Modern_Ballads:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1732E, 0x12
; [nakarest] NakaInst_Grands_on_Stage  +0x17340..+0x17352 (0xece4fe, 18 B)
; [nakarest] Text (18 B at 0xece4fe), first string "Grands on Stage "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece368).
NakaInst_Grands_on_Stage:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17340, 0x12
; [nakarest] NakaInst_Synth_Ballad  +0x17352..+0x17364 (0xece510, 18 B)
; [nakarest] Text (18 B at 0xece510), first string "Synth Ballad "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece360).
NakaInst_Synth_Ballad:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17352, 0x12
; [nakarest] NakaInst_Atmospheric_16  +0x17364..+0x17376 (0xece522, 18 B)
; [nakarest] Text (18 B at 0xece522), first string "Atmospheric 16 "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece358).
NakaInst_Atmospheric_16:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17364, 0x12
; [nakarest] NakaInst_Gentle_16_Beat  +0x17376..+0x17388 (0xece534, 18 B)
; [nakarest] Text (18 B at 0xece534), first string "Gentle 16 Beat "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece350).
NakaInst_Gentle_16_Beat:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17376, 0x12
; [nakarest] NakaInst_E_P_Moments  +0x17388..+0x1739a (0xece546, 18 B)
; [nakarest] Text (18 B at 0xece546), first string "E.P. Moments "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece348).
NakaInst_E_P_Moments:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17388, 0x12
; [nakarest] NakaInst_Easy_Play_16Beat  +0x1739a..+0x173ac (0xece558, 18 B)
; [nakarest] Text (18 B at 0xece558), first string "Easy Play 16Beat"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece340).
NakaInst_Easy_Play_16Beat:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1739A, 0x12
; [nakarest] NakaInst_16_Beat_Groove  +0x173ac..+0x173be (0xece56a, 18 B)
; [nakarest] Text (18 B at 0xece56a), first string "16 Beat Groove "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece338).
NakaInst_16_Beat_Groove:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x173AC, 0x12
; [nakarest] NakaInst_Love_Songs  +0x173be..+0x173d0 (0xece57c, 18 B)
; [nakarest] Text (18 B at 0xece57c), first string "Love Songs "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece330).
NakaInst_Love_Songs:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x173BE, 0x12
; [nakarest] NakaInst_Ballad_Producer  +0x173d0..+0x173e2 (0xece58e, 18 B)
; [nakarest] Text (18 B at 0xece58e), first string "Ballad Producer "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece328).
NakaInst_Ballad_Producer:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x173D0, 0x12
; [nakarest] NakaInst_Studio_8_Beat  +0x173e2..+0x173f4 (0xece5a0, 18 B)
; [nakarest] Text (18 B at 0xece5a0), first string "Studio 8 Beat "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece320).
NakaInst_Studio_8_Beat:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x173E2, 0x12
; [nakarest] NakaInst_Greatest_Hits  +0x173f4..+0x17406 (0xece5b2, 18 B)
; [nakarest] Text (18 B at 0xece5b2), first string "Greatest Hits "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece318).
NakaInst_Greatest_Hits:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x173F4, 0x12
; [nakarest] NakaInst_Smooth_Rock  +0x17406..+0x17418 (0xece5c4, 18 B)
; [nakarest] Text (18 B at 0xece5c4), first string "Smooth Rock "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece310).
NakaInst_Smooth_Rock:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17406, 0x12
; [nakarest] NakaInst_Orchestral_Beat  +0x17418..+0x1742a (0xece5d6, 18 B)
; [nakarest] Text (18 B at 0xece5d6), first string "Orchestral Beat "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece308).
NakaInst_Orchestral_Beat:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17418, 0x12
; [nakarest] NakaInst_Rock_After_Eight  +0x1742a..+0x1743c (0xece5e8, 18 B)
; [nakarest] Text (18 B at 0xece5e8), first string "Rock After Eight"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece300).
NakaInst_Rock_After_Eight:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1742A, 0x12
; [nakarest] NakaInst_Easy_Play_8_Beat  +0x1743c..+0x1744e (0xece5fa, 18 B)
; [nakarest] Text (18 B at 0xece5fa), first string "Easy Play 8 Beat"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece2f8).
NakaInst_Easy_Play_8_Beat:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1743C, 0x12
; [nakarest] NakaInst_German_Schlager  +0x1744e..+0x17460 (0xece60c, 18 B)
; [nakarest] Text (18 B at 0xece60c), first string "German Schlager "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_ModernDance_Table (at
; [nakarest] 0xece2f0).
NakaInst_German_Schlager:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1744E, 0x12
; [nakarest] StyleGroup_RockPop_PairTable  +0x17460..+0x17662 (0xece61e, 514 B)
; [nakarest] purpose not established: layout of 514 B at 0xece61e not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_LatinDance_Table (at 0xecfcb0), which is read by
; [nakarest] MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more; 1
; [nakarest] data word in ToneParam_HandlerTable_BC_Code_Loop9 (at 0xef860e), which is read by
; [nakarest] ToneParam_HandlerTable_BC_Code_Loop9 (display/scoop_display.s: `jp
; [nakarest] ToneParam_HandlerTable_BC_0x41c`).
StyleGroup_RockPop_PairTable:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17460, 0x202
; [nakarest] NakaInst_Ballads  +0x17662..+0x177c2 (0xece820, 352 B)
; [nakarest] Text (352 B at 0xece820), first string " Ballads"; no registered NAKA table points
; [nakarest] into it; reached through source references ColorBlit2_LargeCodeBlock_Join20
; [nakarest] (ui/ui_window_procs.s: `.long NakaInst_Ballads`); 19 data words in
; [nakarest] StyleGroup_RockPop_PairTable (at 0xece6ae, 0xece6a6, 0xece69e).
NakaInst_Ballads:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17662, 0x160
; [nakarest] StyleGroup_PopBallad_Table  +0x177c2..+0x17852 (0xece980, 144 B)
; [nakarest] purpose not established: layout of 144 B at 0xece980 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_LatinDance_Table (at 0xecfcb8), which is read by
; [nakarest] MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
StyleGroup_PopBallad_Table:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x177C2, 0x90
; [nakarest] NakaInst_Western_Techno  +0x17852..+0x17864 (0xecea10, 18 B)
; [nakarest] Text (18 B at 0xecea10), first string "Western Techno "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xecea00).
NakaInst_Western_Techno:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17852, 0x12
; [nakarest] NakaInst_Samba_Party  +0x17864..+0x17876 (0xecea22, 18 B)
; [nakarest] Text (18 B at 0xecea22), first string "Samba Party "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece9f8).
NakaInst_Samba_Party:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17864, 0x12
; [nakarest] NakaInst_Jambo_Dance  +0x17876..+0x17888 (0xecea34, 18 B)
; [nakarest] Text (18 B at 0xecea34), first string "Jambo Dance "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece9f0).
NakaInst_Jambo_Dance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17876, 0x12
; [nakarest] NakaInst_Rio_Goes_Disco  +0x17888..+0x1789a (0xecea46, 18 B)
; [nakarest] Text (18 B at 0xecea46), first string "Rio Goes Disco "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece9e8).
NakaInst_Rio_Goes_Disco:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17888, 0x12
; [nakarest] NakaInst_Reggae_Hit  +0x1789a..+0x178ac (0xecea58, 18 B)
; [nakarest] Text (18 B at 0xecea58), first string "Reggae Hit "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece9e0).
NakaInst_Reggae_Hit:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1789A, 0x12
; [nakarest] NakaInst_The_Big_Hit  +0x178ac..+0x178be (0xecea6a, 18 B)
; [nakarest] Text (18 B at 0xecea6a), first string "The Big Hit "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece9d8).
NakaInst_The_Big_Hit:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x178AC, 0x12
; [nakarest] NakaInst_N_Y_Rap  +0x178be..+0x178d0 (0xecea7c, 18 B)
; [nakarest] Text (18 B at 0xecea7c), first string "N.Y. Rap "; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_PopBallad_Table (at 0xece9d0).
NakaInst_N_Y_Rap:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x178BE, 0x12
; [nakarest] NakaInst_80_s_90_s  +0x178d0..+0x178e2 (0xecea8e, 18 B)
; [nakarest] Text (18 B at 0xecea8e), first string "80's & 90's "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece9c8).
NakaInst_80_s_90_s:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x178D0, 0x12
; [nakarest] NakaInst_Hip_Hop  +0x178e2..+0x178f4 (0xeceaa0, 18 B)
; [nakarest] Text (18 B at 0xeceaa0), first string "Hip Hop "; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_PopBallad_Table (at 0xece9c0).
NakaInst_Hip_Hop:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x178E2, 0x12
; [nakarest] NakaInst_70_s_Dance_Craze  +0x178f4..+0x17906 (0xeceab2, 18 B)
; [nakarest] Text (18 B at 0xeceab2), first string "70's Dance Craze"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece9b8).
NakaInst_70_s_Dance_Craze:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x178F4, 0x12
; [nakarest] NakaInst_Dance_Floor  +0x17906..+0x17918 (0xeceac4, 18 B)
; [nakarest] Text (18 B at 0xeceac4), first string "Dance Floor "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece9b0).
NakaInst_Dance_Floor:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17906, 0x12
; [nakarest] NakaInst_80_s_Disco  +0x17918..+0x1792a (0xecead6, 18 B)
; [nakarest] Text (18 B at 0xecead6), first string "80's Disco "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece9a8).
NakaInst_80_s_Disco:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17918, 0x12
; [nakarest] NakaInst_Glory_Disco  +0x1792a..+0x1793c (0xeceae8, 18 B)
; [nakarest] Text (18 B at 0xeceae8), first string "Glory Disco "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece9a0).
NakaInst_Glory_Disco:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1792A, 0x12
; [nakarest] NakaInst_Techno_World  +0x1793c..+0x1794e (0xeceafa, 18 B)
; [nakarest] Text (18 B at 0xeceafa), first string "Techno World "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece998).
NakaInst_Techno_World:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1793C, 0x12
; [nakarest] NakaInst_House_Party  +0x1794e..+0x17960 (0xeceb0c, 18 B)
; [nakarest] Text (18 B at 0xeceb0c), first string "House Party "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece990); 1 data word in LZ_Decompress_ReadSizeField (at 0xef4e5b), which is read
; [nakarest] by LZ_Decompress_ReadSizeField (boot/system_handlers.s: `jr c,
; [nakarest] LZ_Decompress_ReadSizeField`).
NakaInst_House_Party:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1794E, 0x12
; [nakarest] NakaInst_Straight_Dance  +0x17960..+0x17972 (0xeceb1e, 18 B)
; [nakarest] Text (18 B at 0xeceb1e), first string "Straight Dance "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece988).
NakaInst_Straight_Dance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17960, 0x12
; [nakarest] NakaInst_British_DancePop  +0x17972..+0x17984 (0xeceb30, 18 B)
; [nakarest] Text (18 B at 0xeceb30), first string "British DancePop"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_PopBallad_Table (at
; [nakarest] 0xece980).
NakaInst_British_DancePop:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17972, 0x12
; [nakarest] StyleGroup_PartyMusic_PairTable  +0x17984..+0x17b7a (0xeceb42, 502 B)
; [nakarest] purpose not established: layout of 502 B at 0xeceb42 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_LatinDance_Table (at 0xecfcc0), which is read by
; [nakarest] MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
StyleGroup_PartyMusic_PairTable:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17984, 0x1F6
; [nakarest] StyleGroup_Swing_Table  +0x17b7a..+0x17c12 (0xeced38, 152 B)
; [nakarest] purpose not established: layout of 152 B at 0xeced38 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_LatinDance_Table (at 0xecfcc8), which is read by
; [nakarest] MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
StyleGroup_Swing_Table:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17B7A, 0x98
; [nakarest] NakaInst_Gospel_In_Threes  +0x17c12..+0x17c24 (0xecedd0, 18 B)
; [nakarest] Text (18 B at 0xecedd0), first string "Gospel In Threes"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xecedc0).
NakaInst_Gospel_In_Threes:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C12, 0x12
; [nakarest] NakaInst_Gospel_Blues  +0x17c24..+0x17c36 (0xecede2, 18 B)
; [nakarest] Text (18 B at 0xecede2), first string "Gospel Blues "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xecedb8).
NakaInst_Gospel_Blues:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C24, 0x12
; [nakarest] NakaInst_Power_Gospel  +0x17c36..+0x17c48 (0xecedf4, 18 B)
; [nakarest] Text (18 B at 0xecedf4), first string "Power Gospel "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xecedb0).
NakaInst_Power_Gospel:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C36, 0x12
; [nakarest] NakaInst_Day_Of_Rest  +0x17c48..+0x17c5a (0xecee06, 18 B)
; [nakarest] Text (18 B at 0xecee06), first string "Day Of Rest "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeceda8).
NakaInst_Day_Of_Rest:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C48, 0x12
; [nakarest] NakaInst_Lift_Your_Soul  +0x17c5a..+0x17c6c (0xecee18, 18 B)
; [nakarest] Text (18 B at 0xecee18), first string "Lift Your Soul "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeceda0).
NakaInst_Lift_Your_Soul:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C5A, 0x12
; [nakarest] NakaInst_Sunday_Service  +0x17c6c..+0x17c7e (0xecee2a, 18 B)
; [nakarest] Text (18 B at 0xecee2a), first string "Sunday Service "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeced98).
NakaInst_Sunday_Service:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C6C, 0x12
; [nakarest] NakaInst_Play_The_Blues  +0x17c7e..+0x17c90 (0xecee3c, 18 B)
; [nakarest] Text (18 B at 0xecee3c), first string "Play The Blues "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeced90).
NakaInst_Play_The_Blues:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C7E, 0x12
; [nakarest] NakaInst_Blues_Alley  +0x17c90..+0x17ca2 (0xecee4e, 18 B)
; [nakarest] Text (18 B at 0xecee4e), first string "Blues Alley "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeced88).
NakaInst_Blues_Alley:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17C90, 0x12
; [nakarest] NakaInst_Rock_Blues  +0x17ca2..+0x17cb4 (0xecee60, 18 B)
; [nakarest] Text (18 B at 0xecee60), first string "Rock Blues "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeced80).
NakaInst_Rock_Blues:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17CA2, 0x12
; [nakarest] NakaInst_Down_Dirty_Blues  +0x17cb4..+0x17cc6 (0xecee72, 18 B)
; [nakarest] Text (18 B at 0xecee72), first string "Down&Dirty Blues"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeced78).
NakaInst_Down_Dirty_Blues:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17CB4, 0x12
; [nakarest] NakaInst_R_B_Groove  +0x17cc6..+0x17cd8 (0xecee84, 18 B)
; [nakarest] Text (18 B at 0xecee84), first string "R&B Groove "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeced70).
NakaInst_R_B_Groove:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17CC6, 0x12
; [nakarest] NakaInst_Slow_Soul_Mood  +0x17cd8..+0x17cea (0xecee96, 18 B)
; [nakarest] Text (18 B at 0xecee96), first string "Slow Soul Mood "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeced68).
NakaInst_Slow_Soul_Mood:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17CD8, 0x12
; [nakarest] NakaInst_Mellow_Soul  +0x17cea..+0x17cfc (0xeceea8, 18 B)
; [nakarest] Text (18 B at 0xeceea8), first string "Mellow Soul "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeced60).
NakaInst_Mellow_Soul:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17CEA, 0x12
; [nakarest] NakaInst_Soul_To_Sun  +0x17cfc..+0x17d0e (0xeceeba, 18 B)
; [nakarest] Text (18 B at 0xeceeba), first string "Soul To Sun "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeced58).
NakaInst_Soul_To_Sun:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17CFC, 0x12
; [nakarest] NakaInst_New_Soul_Ballad  +0x17d0e..+0x17d20 (0xeceecc, 18 B)
; [nakarest] Text (18 B at 0xeceecc), first string "New Soul Ballad "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeced50).
NakaInst_New_Soul_Ballad:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17D0E, 0x12
; [nakarest] NakaInst_Soft_Soul  +0x17d20..+0x17d32 (0xeceede, 18 B)
; [nakarest] Text (18 B at 0xeceede), first string "Soft Soul "; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_Swing_Table (at 0xeced48).
NakaInst_Soft_Soul:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17D20, 0x12
; [nakarest] NakaInst_Detroit_Pop  +0x17d32..+0x17d44 (0xeceef0, 18 B)
; [nakarest] Text (18 B at 0xeceef0), first string "Detroit Pop "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeced40).
NakaInst_Detroit_Pop:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17D32, 0x12
; [nakarest] NakaInst_King_Of_Soul  +0x17d44..+0x17d56 (0xecef02, 18 B)
; [nakarest] Text (18 B at 0xecef02), first string "King Of Soul "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_Swing_Table (at
; [nakarest] 0xeced38).
NakaInst_King_Of_Soul:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17D44, 0x12
; [nakarest] StyleGroup_FunkFusion_Separator  +0x17d56..+0x17d5a (0xecef14, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xecef14 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_LatinDance_Table (at 0xecfcd0), which is read by
; [nakarest] MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
StyleGroup_FunkFusion_Separator:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17D56, 0x4
; [nakarest] StyleGroup_FunkFusion_Table  +0x17d5a..+0x17e49 (0xecef18, 239 B)
; [nakarest] purpose not established: 239 B at 0xecef18 that no registered NAKA table, symbol, 24/32-bit literal or data word points into
StyleGroup_FunkFusion_Table:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17D5A, 0xEF
; [nakarest] StyleGroup_FunkFusion_Pad  +0x17e49..+0x17e4e (0xecf007, 5 B)
; [nakarest] purpose not established: layout of 5 B at 0xecf007 not derived; readers below
; [nakarest] Readers: source references Not_sure_maybe_SOFT_VERSION_related_Code_Helper3
; [nakarest] (sequencer/accompaniment_engine.s: `.long StyleGroup_FunkFusion_Pad`),
; [nakarest] Not_sure_maybe_SOFT_VERSION_related_Code_Return3 (sequencer/accompaniment_engine.s:
; [nakarest] `.long StyleGroup_FunkFusion_Pad`); 1 data word in TempoRingBuf_BytecodeSnippet (at
; [nakarest] 0xef16ba).
StyleGroup_FunkFusion_Pad:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17E49, 0x5
; [nakarest] NakaInst_L_A_Fusion  +0x17e4e..+0x17e60 (0xecf00c, 18 B)
; [nakarest] Text (18 B at 0xecf00c), first string "L.A. Fusion "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xeceffc).
NakaInst_L_A_Fusion:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17E4E, 0x12
; [nakarest] NakaInst_The_Groove  +0x17e60..+0x17e72 (0xecf01e, 18 B)
; [nakarest] Text (18 B at 0xecf01e), first string "The Groove "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xeceff4).
NakaInst_The_Groove:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17E60, 0x12
; [nakarest] NakaInst_Slow_Jazz_3_4  +0x17e72..+0x17e84 (0xecf030, 18 B)
; [nakarest] Text (18 B at 0xecf030), first string "Slow Jazz 3/4 "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecefec).
NakaInst_Slow_Jazz_3_4:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17E72, 0x12
; [nakarest] NakaInst_Steady_Jazz_3_4  +0x17e84..+0x17e96 (0xecf042, 18 B)
; [nakarest] Text (18 B at 0xecf042), first string "Steady Jazz 3/4 "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecefe4).
NakaInst_Steady_Jazz_3_4:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17E84, 0x12
; [nakarest] NakaInst_Jazz_At_3_00am  +0x17e96..+0x17ea8 (0xecf054, 18 B)
; [nakarest] Text (18 B at 0xecf054), first string "Jazz At 3:00am "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecefdc).
NakaInst_Jazz_At_3_00am:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17E96, 0x12
; [nakarest] NakaInst_Smokey_Jazz_Club  +0x17ea8..+0x17eba (0xecf066, 18 B)
; [nakarest] Text (18 B at 0xecf066), first string "Smokey Jazz Club"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecefd4).
NakaInst_Smokey_Jazz_Club:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17EA8, 0x12
; [nakarest] NakaInst_Euro_Jazz  +0x17eba..+0x17ecc (0xecf078, 18 B)
; [nakarest] Text (18 B at 0xecf078), first string "Euro Jazz "; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at 0xecefcc).
NakaInst_Euro_Jazz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17EBA, 0x12
; [nakarest] NakaInst_Van_Damme_Jazz  +0x17ecc..+0x17ede (0xecf08a, 18 B)
; [nakarest] Text (18 B at 0xecf08a), first string "Van Damme Jazz "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecefc4).
NakaInst_Van_Damme_Jazz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17ECC, 0x12
; [nakarest] NakaInst_Jazz_Francais  +0x17ede..+0x17ef0 (0xecf09c, 18 B)
; [nakarest] Text (18 B at 0xecf09c), first string "Jazz Francais "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecefbc).
NakaInst_Jazz_Francais:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17EDE, 0x12
; [nakarest] NakaInst_Speakeasy_Jazz  +0x17ef0..+0x17f02 (0xecf0ae, 18 B)
; [nakarest] Text (18 B at 0xecf0ae), first string "Speakeasy Jazz "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecefb4).
NakaInst_Speakeasy_Jazz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17EF0, 0x12
; [nakarest] NakaInst_Jazz_Accordion  +0x17f02..+0x17f14 (0xecf0c0, 18 B)
; [nakarest] Text (18 B at 0xecf0c0), first string "Jazz Accordion "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecefac).
NakaInst_Jazz_Accordion:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F02, 0x12
; [nakarest] NakaInst_Gypsy_Jazzers  +0x17f14..+0x17f26 (0xecf0d2, 18 B)
; [nakarest] Text (18 B at 0xecf0d2), first string "Gypsy Jazzers "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecefa4).
NakaInst_Gypsy_Jazzers:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F14, 0x12
; [nakarest] NakaInst_Gentle_Jazz  +0x17f26..+0x17f38 (0xecf0e4, 18 B)
; [nakarest] Text (18 B at 0xecf0e4), first string "Gentle Jazz "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef9c).
NakaInst_Gentle_Jazz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F26, 0x12
; [nakarest] NakaInst_Combo_Drawbars  +0x17f38..+0x17f4a (0xecf0f6, 18 B)
; [nakarest] Text (18 B at 0xecf0f6), first string "Combo Drawbars "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef94).
NakaInst_Combo_Drawbars:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F38, 0x12
; [nakarest] NakaInst_Jazz_Standards  +0x17f4a..+0x17f5c (0xecf108, 18 B)
; [nakarest] Text (18 B at 0xecf108), first string "Jazz Standards "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef8c).
NakaInst_Jazz_Standards:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F4A, 0x12
; [nakarest] NakaInst_40_s_Boogie  +0x17f5c..+0x17f6e (0xecf11a, 18 B)
; [nakarest] Text (18 B at 0xecf11a), first string "40's Boogie "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef84).
NakaInst_40_s_Boogie:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F5C, 0x12
; [nakarest] NakaInst_Simple_Jazz  +0x17f6e..+0x17f80 (0xecf12c, 18 B)
; [nakarest] Text (18 B at 0xecf12c), first string "Simple Jazz "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef7c).
NakaInst_Simple_Jazz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F6E, 0x12
; [nakarest] NakaInst_Up_Tempo_Combo  +0x17f80..+0x17f92 (0xecf13e, 18 B)
; [nakarest] Text (18 B at 0xecf13e), first string "Up Tempo Combo "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef74).
NakaInst_Up_Tempo_Combo:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F80, 0x12
; [nakarest] NakaInst_Jazz_Club  +0x17f92..+0x17fa4 (0xecf150, 18 B)
; [nakarest] Text (18 B at 0xecf150), first string "Jazz Club "; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at 0xecef6c).
NakaInst_Jazz_Club:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17F92, 0x12
; [nakarest] NakaInst_Easy_Play_Swing  +0x17fa4..+0x17fb6 (0xecf162, 18 B)
; [nakarest] Text (18 B at 0xecf162), first string "Easy Play Swing "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef64).
NakaInst_Easy_Play_Swing:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17FA4, 0x12
; [nakarest] NakaInst_Night_Club_Combo  +0x17fb6..+0x17fc8 (0xecf174, 18 B)
; [nakarest] Text (18 B at 0xecf174), first string "Night Club Combo"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef5c).
NakaInst_Night_Club_Combo:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17FB6, 0x12
; [nakarest] NakaInst_Swing_Orchestra  +0x17fc8..+0x17fda (0xecf186, 18 B)
; [nakarest] Text (18 B at 0xecf186), first string "Swing Orchestra "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef54).
NakaInst_Swing_Orchestra:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17FC8, 0x12
; [nakarest] NakaInst_Mid_Swingband  +0x17fda..+0x17fec (0xecf198, 18 B)
; [nakarest] Text (18 B at 0xecf198), first string "Mid Swingband "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef4c).
NakaInst_Mid_Swingband:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17FDA, 0x12
; [nakarest] NakaInst_40_s_Love_Songs  +0x17fec..+0x17ffe (0xecf1aa, 18 B)
; [nakarest] Text (18 B at 0xecf1aa), first string "40's Love Songs "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef44).
NakaInst_40_s_Love_Songs:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17FEC, 0x12
; [nakarest] NakaInst_Moonlight_Dance  +0x17ffe..+0x18010 (0xecf1bc, 18 B)
; [nakarest] Text (18 B at 0xecf1bc), first string "Moonlight Dance "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef3c).
NakaInst_Moonlight_Dance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x17FFE, 0x12
; [nakarest] NakaInst_Sentimental_Band  +0x18010..+0x18022 (0xecf1ce, 18 B)
; [nakarest] Text (18 B at 0xecf1ce), first string "Sentimental Band"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef34).
NakaInst_Sentimental_Band:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18010, 0x12
; [nakarest] NakaInst_40_s_Dance_Band  +0x18022..+0x18034 (0xecf1e0, 18 B)
; [nakarest] Text (18 B at 0xecf1e0), first string "40's Dance Band "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef2c).
NakaInst_40_s_Dance_Band:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18022, 0x12
; [nakarest] NakaInst_All_Aboard  +0x18034..+0x18046 (0xecf1f2, 18 B)
; [nakarest] Text (18 B at 0xecf1f2), first string "All Aboard! "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef24).
NakaInst_All_Aboard:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18034, 0x12
; [nakarest] NakaInst_Steady_Swingband  +0x18046..+0x1806a (0xecf204, 36 B)
; [nakarest] Text (36 B at 0xecf204), first string "Steady Swingband"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_FunkFusion_Table (at
; [nakarest] 0xecef1c); 1 data word in StyleGroup_FunkFusion_Separator (at 0xecef14).
NakaInst_Steady_Swingband:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18046, 0x24
; [nakarest] StyleGroup_JazzCombo_Table  +0x1806a..+0x1816a (0xecf228, 256 B)
; [nakarest] purpose not established: layout of 256 B at 0xecf228 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_LatinDance_Table (at 0xecfcd8), which is read by
; [nakarest] MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
StyleGroup_JazzCombo_Table:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1806A, 0x100
; [nakarest] NakaInst_Party_Vienna  +0x1816a..+0x1817c (0xecf328, 18 B)
; [nakarest] Text (18 B at 0xecf328), first string "Party Vienna "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf318).
NakaInst_Party_Vienna:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1816A, 0x12
; [nakarest] NakaInst_Walzer_Time  +0x1817c..+0x1818e (0xecf33a, 18 B)
; [nakarest] Text (18 B at 0xecf33a), first string "Walzer-Time "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf310).
NakaInst_Walzer_Time:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1817C, 0x12
; [nakarest] NakaInst_Austrian_Waltz  +0x1818e..+0x181a0 (0xecf34c, 18 B)
; [nakarest] Text (18 B at 0xecf34c), first string "Austrian Waltz "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf308).
NakaInst_Austrian_Waltz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1818E, 0x12
; [nakarest] NakaInst_Quick_Waltz  +0x181a0..+0x181b2 (0xecf35e, 18 B)
; [nakarest] Text (18 B at 0xecf35e), first string "Quick Waltz "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf300).
NakaInst_Quick_Waltz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x181A0, 0x12
; [nakarest] NakaInst_Last_Dance_Waltz  +0x181b2..+0x181c4 (0xecf370, 18 B)
; [nakarest] Text (18 B at 0xecf370), first string "Last Dance Waltz"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf2f8).
NakaInst_Last_Dance_Waltz:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x181B2, 0x12
; [nakarest] NakaInst_Tango_Pianist  +0x181c4..+0x181d6 (0xecf382, 18 B)
; [nakarest] Text (18 B at 0xecf382), first string "Tango Pianist "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf2f0).
NakaInst_Tango_Pianist:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x181C4, 0x12
; [nakarest] NakaInst_Tango_D_Amour  +0x181d6..+0x181e8 (0xecf394, 18 B)
; [nakarest] Text (18 B at 0xecf394), first string "Tango D'Amour "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf2e8).
NakaInst_Tango_D_Amour:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x181D6, 0x12
; [nakarest] NakaInst_Strict_Tango  +0x181e8..+0x181fa (0xecf3a6, 18 B)
; [nakarest] Text (18 B at 0xecf3a6), first string "Strict Tango "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf2e0).
NakaInst_Strict_Tango:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x181E8, 0x12
; [nakarest] NakaInst_Viva_Pasodoble  +0x181fa..+0x1820c (0xecf3b8, 18 B)
; [nakarest] Text (18 B at 0xecf3b8), first string "Viva Pasodoble! "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf2d8).
NakaInst_Viva_Pasodoble:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x181FA, 0x12
; [nakarest] NakaInst_Samba_Felicidade  +0x1820c..+0x1821e (0xecf3ca, 18 B)
; [nakarest] Text (18 B at 0xecf3ca), first string "Samba Felicidade"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf2d0).
NakaInst_Samba_Felicidade:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1820C, 0x12
; [nakarest] NakaInst_Let_s_Beguine  +0x1821e..+0x18230 (0xecf3dc, 18 B)
; [nakarest] Text (18 B at 0xecf3dc), first string "Let's Beguine! "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf2c8).
NakaInst_Let_s_Beguine:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1821E, 0x12
; [nakarest] NakaInst_1_2_Cha_Cha_Cha  +0x18230..+0x18242 (0xecf3ee, 18 B)
; [nakarest] Text (18 B at 0xecf3ee), first string "1,2,Cha Cha Cha "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf2c0).
NakaInst_1_2_Cha_Cha_Cha:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18230, 0x12
; [nakarest] NakaInst_Do_The_Twist  +0x18242..+0x18254 (0xecf400, 18 B)
; [nakarest] Text (18 B at 0xecf400), first string "Do The Twist! "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf2b8); 1 data word in TempoRingBuf_Write (at 0xef1125), which is read by
; [nakarest] INTTR4_CheckAltSeqEnable (boot/system_handlers.s: `calr TempoRingBuf_Write`),
; [nakarest] INTTR4_CheckSeqEnable (boot/system_handlers.s: `calr TempoRingBuf_Write`), 1 more.
NakaInst_Do_The_Twist:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18242, 0x12
; [nakarest] NakaInst_Jive_Dance  +0x18254..+0x18266 (0xecf412, 18 B)
; [nakarest] Text (18 B at 0xecf412), first string "Jive Dance "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf2b0).
NakaInst_Jive_Dance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18254, 0x12
; [nakarest] NakaInst_Let_s_Twist  +0x18266..+0x18278 (0xecf424, 18 B)
; [nakarest] Text (18 B at 0xecf424), first string "Let's Twist "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf2a8).
NakaInst_Let_s_Twist:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18266, 0x12
; [nakarest] NakaInst_Strictly_Quick  +0x18278..+0x1828a (0xecf436, 18 B)
; [nakarest] Text (18 B at 0xecf436), first string "Strictly Quick! "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf2a0).
NakaInst_Strictly_Quick:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18278, 0x12
; [nakarest] NakaInst_Radio_Foxtrot  +0x1828a..+0x1829c (0xecf448, 18 B)
; [nakarest] Text (18 B at 0xecf448), first string "Radio Foxtrot "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf298).
NakaInst_Radio_Foxtrot:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1828A, 0x12
; [nakarest] NakaInst_Strictly_Foxtrot  +0x1829c..+0x182ae (0xecf45a, 18 B)
; [nakarest] Text (18 B at 0xecf45a), first string "Strictly Foxtrot"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf290).
NakaInst_Strictly_Foxtrot:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1829C, 0x12
; [nakarest] NakaInst_Up_Tempo_Foxtrot  +0x182ae..+0x182c0 (0xecf46c, 18 B)
; [nakarest] Text (18 B at 0xecf46c), first string "Up Tempo Foxtrot"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf288).
NakaInst_Up_Tempo_Foxtrot:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x182AE, 0x12
; [nakarest] NakaInst_Organist_s_Dance  +0x182c0..+0x182d2 (0xecf47e, 18 B)
; [nakarest] Text (18 B at 0xecf47e), first string "Organist's Dance"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf280).
NakaInst_Organist_s_Dance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x182C0, 0x12
; [nakarest] NakaInst_Gentle_Foxtrot  +0x182d2..+0x182e4 (0xecf490, 18 B)
; [nakarest] Text (18 B at 0xecf490), first string "Gentle Foxtrot "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf278).
NakaInst_Gentle_Foxtrot:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x182D2, 0x12
; [nakarest] NakaInst_Magic_Ballroom  +0x182e4..+0x182f6 (0xecf4a2, 18 B)
; [nakarest] Text (18 B at 0xecf4a2), first string "Magic Ballroom "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf270).
NakaInst_Magic_Ballroom:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x182E4, 0x12
; [nakarest] NakaInst_Viva_Las_Vegas  +0x182f6..+0x18308 (0xecf4b4, 18 B)
; [nakarest] Text (18 B at 0xecf4b4), first string "Viva Las Vegas "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf268).
NakaInst_Viva_Las_Vegas:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x182F6, 0x12
; [nakarest] NakaInst_Cabaret_Band  +0x18308..+0x1831a (0xecf4c6, 18 B)
; [nakarest] Text (18 B at 0xecf4c6), first string "Cabaret Band "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf260).
NakaInst_Cabaret_Band:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18308, 0x12
; [nakarest] NakaInst_Paris_Club  +0x1831a..+0x1832c (0xecf4d8, 18 B)
; [nakarest] Text (18 B at 0xecf4d8), first string "Paris Club "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf258).
NakaInst_Paris_Club:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1831A, 0x12
; [nakarest] NakaInst_Tap_Dancer  +0x1832c..+0x1833e (0xecf4ea, 18 B)
; [nakarest] Text (18 B at 0xecf4ea), first string "Tap Dancer "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf250).
NakaInst_Tap_Dancer:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1832C, 0x12
; [nakarest] NakaInst_Vaudeville_Act  +0x1833e..+0x18350 (0xecf4fc, 18 B)
; [nakarest] Text (18 B at 0xecf4fc), first string "Vaudeville Act "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf248).
NakaInst_Vaudeville_Act:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1833E, 0x12
; [nakarest] NakaInst_Theatre_Stride  +0x18350..+0x18362 (0xecf50e, 18 B)
; [nakarest] Text (18 B at 0xecf50e), first string "Theatre Stride "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf240).
NakaInst_Theatre_Stride:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18350, 0x12
; [nakarest] NakaInst_Showband  +0x18362..+0x18374 (0xecf520, 18 B)
; [nakarest] Text (18 B at 0xecf520), first string "Showband "; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at 0xecf238).
NakaInst_Showband:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18362, 0x12
; [nakarest] NakaInst_Tinseltown  +0x18374..+0x18386 (0xecf532, 18 B)
; [nakarest] Text (18 B at 0xecf532), first string "Tinseltown "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf230).
NakaInst_Tinseltown:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18374, 0x12
; [nakarest] NakaInst_Musical_Overture  +0x18386..+0x18398 (0xecf544, 18 B)
; [nakarest] Text (18 B at 0xecf544), first string "Musical Overture"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_JazzCombo_Table (at
; [nakarest] 0xecf228).
NakaInst_Musical_Overture:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18386, 0x12
; [nakarest] StyleGroup_TradFolk_PairTable  +0x18398..+0x1862a (0xecf556, 658 B)
; [nakarest] purpose not established: layout of 658 B at 0xecf556 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_LatinDance_Table (at 0xecfce0), which is read by
; [nakarest] MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
StyleGroup_TradFolk_PairTable:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18398, 0x292
; [nakarest] StyleGroup_WorldMusic_Table  +0x1862a..+0x186ba (0xecf7e8, 144 B)
; [nakarest] purpose not established: layout of 144 B at 0xecf7e8 not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_LatinDance_Table (at 0xecfce8), which is read by
; [nakarest] MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
StyleGroup_WorldMusic_Table:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1862A, 0x90
; [nakarest] NakaInst_Country_Hits  +0x186ba..+0x186cc (0xecf878, 18 B)
; [nakarest] Text (18 B at 0xecf878), first string "Country Hits "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf868).
NakaInst_Country_Hits:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x186BA, 0x12
; [nakarest] NakaInst_New_Country_Rock  +0x186cc..+0x186de (0xecf88a, 18 B)
; [nakarest] Text (18 B at 0xecf88a), first string "New Country Rock"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf860).
NakaInst_New_Country_Rock:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x186CC, 0x12
; [nakarest] NakaInst_Old_Country_Hits  +0x186de..+0x186f0 (0xecf89c, 18 B)
; [nakarest] Text (18 B at 0xecf89c), first string "Old Country Hits"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf858).
NakaInst_Old_Country_Hits:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x186DE, 0x12
; [nakarest] NakaInst_EZ_Country_Rock  +0x186f0..+0x18702 (0xecf8ae, 18 B)
; [nakarest] Text (18 B at 0xecf8ae), first string "EZ Country Rock "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf850).
NakaInst_EZ_Country_Rock:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x186F0, 0x12
; [nakarest] NakaInst_Modern_Country  +0x18702..+0x18714 (0xecf8c0, 18 B)
; [nakarest] Text (18 B at 0xecf8c0), first string "Modern Country "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf848).
NakaInst_Modern_Country:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18702, 0x12
; [nakarest] NakaInst_Country_Love  +0x18714..+0x18726 (0xecf8d2, 18 B)
; [nakarest] Text (18 B at 0xecf8d2), first string "Country Love "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf840).
NakaInst_Country_Love:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18714, 0x12
; [nakarest] NakaInst_Country_88  +0x18726..+0x18738 (0xecf8e4, 18 B)
; [nakarest] Text (18 B at 0xecf8e4), first string "Country 88 "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf838).
NakaInst_Country_88:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18726, 0x12
; [nakarest] NakaInst_Country_Folks  +0x18738..+0x1874a (0xecf8f6, 18 B)
; [nakarest] Text (18 B at 0xecf8f6), first string "Country Folks "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf830).
NakaInst_Country_Folks:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18738, 0x12
; [nakarest] NakaInst_Western_Ballads  +0x1874a..+0x1875c (0xecf908, 18 B)
; [nakarest] Text (18 B at 0xecf908), first string "Western Ballads "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf828).
NakaInst_Western_Ballads:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1874A, 0x12
; [nakarest] NakaInst_Country_Romance  +0x1875c..+0x1876e (0xecf91a, 18 B)
; [nakarest] Text (18 B at 0xecf91a), first string "Country Romance "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf820).
NakaInst_Country_Romance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1875C, 0x12
; [nakarest] NakaInst_70_s_Country_Pop  +0x1876e..+0x18780 (0xecf92c, 18 B)
; [nakarest] Text (18 B at 0xecf92c), first string "70's Country Pop"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf818).
NakaInst_70_s_Country_Pop:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x1876E, 0x12
; [nakarest] NakaInst_Hillbilly_Blues  +0x18780..+0x18792 (0xecf93e, 18 B)
; [nakarest] Text (18 B at 0xecf93e), first string "Hillbilly Blues "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf810).
NakaInst_Hillbilly_Blues:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18780, 0x12
; [nakarest] NakaInst_Country_Dance  +0x18792..+0x187a4 (0xecf950, 18 B)
; [nakarest] Text (18 B at 0xecf950), first string "Country Dance "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf808).
NakaInst_Country_Dance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18792, 0x12
; [nakarest] NakaInst_Trucker_Country  +0x187a4..+0x187b6 (0xecf962, 18 B)
; [nakarest] Text (18 B at 0xecf962), first string "Trucker Country "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf800).
NakaInst_Trucker_Country:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x187A4, 0x12
; [nakarest] NakaInst_Kentucky_Blue  +0x187b6..+0x187c8 (0xecf974, 18 B)
; [nakarest] Text (18 B at 0xecf974), first string "Kentucky Blue "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf7f8).
NakaInst_Kentucky_Blue:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x187B6, 0x12
; [nakarest] NakaInst_Modern_Hoedown  +0x187c8..+0x187da (0xecf986, 18 B)
; [nakarest] Text (18 B at 0xecf986), first string "Modern Hoedown "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf7f0).
NakaInst_Modern_Hoedown:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x187C8, 0x12
; [nakarest] NakaInst_Bluegrass_Time  +0x187da..+0x187ec (0xecf998, 18 B)
; [nakarest] Text (18 B at 0xecf998), first string "Bluegrass Time "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_WorldMusic_Table (at
; [nakarest] 0xecf7e8).
NakaInst_Bluegrass_Time:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x187DA, 0x12
; [nakarest] StyleGroup_LatinWorld_PairTable  +0x187ec..+0x18800 (0xecf9aa, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xecf9aa not derived; readers below
; [nakarest] Readers: 1 data word in StyleGroup_LatinDance_Table (at 0xecfcf0), which is read by
; [nakarest] MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
StyleGroup_LatinWorld_PairTable:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x187EC, 0x14
EmbeddedPtrTable_v10_naka_style_bitmaps_018800:
	.long 0x00ECD16E
	.long 0x00ECFC5C
	.long 0x00ECD214
	.long 0x00ECFC4A
	.long 0x00ECD2BA
	.long 0x00ECFC38
	.long 0x00ECD360
	.long 0x00ECFC26
	.long 0x00ECD406
	.long 0x00ECFC14
	.long 0x00ECD4AC
	.long 0x00ECFC02
	.long 0x00ECD552
	.long 0x00ECFBF0
	.long 0x00ECD5F8
	.long 0x00ECFBDE
	.long 0x00ECD69E
	.long 0x00ECFBCC
	.long 0x00ECD744
	.long 0x00ECFBBA
	.long 0x00ECD7EA
	.long 0x00ECFBA8
	.long 0x00ECD890
	.long 0x00ECFB96
	.long 0x00ECD936
	.long 0x00ECFB84
	.long 0x00ECD9DC
	.long 0x00ECFB72
	.long 0x00ECDA82
	.long 0x00ECFB60
	.long 0x00ECDB28
	.long 0x00ECFB4E
	.long 0x00ECDBCE
	.long 0x00ECFB3C
	.long 0x00ECDC74
	.long 0x00ECFB2A
	.long 0x00ECDD1A
	.long 0x00ECFB18
	.long 0x00ECDDC0
	.long 0x00ECFB06
	.long 0x00ECDE66
	.long 0x00ECFAF4
	.long 0x00ECDF0C
	.long 0x00ECFAE2
	.long 0x00ECDFB2
	.long 0x00ECFAD0
	.long 0x00ECE058
	.long 0x00ECFABE
	.long 0x00ECE0FE
	.long 0x00ECFAAC
	.long 0x00ECE1A4
	.long 0x00ECFA9A
	.long 0x00ECE24A
	.long 0x00000000
	.long 0x00000000
; [nakarest] naka_style_bitmaps+0x188dc  +0x188dc..+0x18aea (0xecfa9a, 526 B)
; [nakarest] Text (526 B at 0xecfa9a), first string "Jamaican Swing "; no registered NAKA table
; [nakarest] points into it; reached through source references
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (ui_widgets/style_bitmaps.s: `.long
; [nakarest] 0x00ecfa9a`), MstStyle1Grid_CellSelect (ui/ui_mode_handlers.s: `lda xwa,
; [nakarest] (StyleGroup_LatinWorld_PairTable_0x2fa:24)`), MstStyle1Grid_PadLeft_Check
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinWorld_PairTable_0x2fa:24)`),
; [nakarest] MstStyle1Grid_PadLeft_CheckB (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinWorld_PairTable_0x2fa:24)`), 1 more; 26 data words in
; [nakarest] EmbeddedPtrTable_v10_naka_style_bitmaps_018800 (at 0xecfa8a, 0xecfa82, 0xecfa7a); 3
; [nakarest] data words in StyleGroup_LatinWorld_PairTable (at 0xecf9ba, 0xecf9b2, 0xecf9aa).
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x188DC, 0x20E
; [nakarest] StyleGroup_LatinDance_Table  +0x18aea..+0x18b36 (0xecfca8, 76 B)
; [nakarest] purpose not established: layout of 76 B at 0xecfca8 not derived; readers below
; [nakarest] Readers: source references MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda
; [nakarest] xbc, (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`),
; [nakarest] MstStyle1_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`).
StyleGroup_LatinDance_Table:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18AEA, 0x4C
; [nakarest] NakaInst_Latin_World  +0x18b36..+0x18b48 (0xecfcf4, 18 B)
; [nakarest] Text (18 B at 0xecfcf4), first string "Latin / World "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_LatinDance_Table (at
; [nakarest] 0xecfcec), which is read by MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s:
; [nakarest] `lda xbc, (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
NakaInst_Latin_World:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18B36, 0x12
; [nakarest] NakaInst_Country  +0x18b48..+0x18b5a (0xecfd06, 18 B)
; [nakarest] Text (18 B at 0xecfd06), first string "Country "; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_LatinDance_Table (at 0xecfce4),
; [nakarest] which is read by MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
NakaInst_Country:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18B48, 0x12
; [nakarest] NakaInst_Trad_Folk  +0x18b5a..+0x18b6c (0xecfd18, 18 B)
; [nakarest] Text (18 B at 0xecfd18), first string "Trad & Folk "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_LatinDance_Table (at
; [nakarest] 0xecfcdc), which is read by MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s:
; [nakarest] `lda xbc, (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
NakaInst_Trad_Folk:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18B5A, 0x12
; [nakarest] NakaInst_Show_Trad_Dance  +0x18b6c..+0x18b7e (0xecfd2a, 18 B)
; [nakarest] Text (18 B at 0xecfd2a), first string "Show/Trad Dance "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_LatinDance_Table (at
; [nakarest] 0xecfcd4), which is read by MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s:
; [nakarest] `lda xbc, (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
NakaInst_Show_Trad_Dance:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18B6C, 0x12
; [nakarest] NakaInst_Jazz_Swing  +0x18b7e..+0x18b90 (0xecfd3c, 18 B)
; [nakarest] Text (18 B at 0xecfd3c), first string "Jazz & Swing "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_LatinDance_Table (at
; [nakarest] 0xecfccc), which is read by MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s:
; [nakarest] `lda xbc, (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
NakaInst_Jazz_Swing:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18B7E, 0x12
; [nakarest] NakaInst_Gospel_Blues_R_B  +0x18b90..+0x18ba2 (0xecfd4e, 18 B)
; [nakarest] Text (18 B at 0xecfd4e), first string "Gospel/Blues/R&B"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_LatinDance_Table (at
; [nakarest] 0xecfcc4), which is read by MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s:
; [nakarest] `lda xbc, (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
NakaInst_Gospel_Blues_R_B:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18B90, 0x12
; [nakarest] NakaInst_Party_Music  +0x18ba2..+0x18bb4 (0xecfd60, 18 B)
; [nakarest] Text (18 B at 0xecfd60), first string "Party Music "; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in StyleGroup_LatinDance_Table (at
; [nakarest] 0xecfcbc), which is read by MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s:
; [nakarest] `lda xbc, (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
NakaInst_Party_Music:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18BA2, 0x12
; [nakarest] NakaInst_Dance_Pop  +0x18bb4..+0x18bc6 (0xecfd72, 18 B)
; [nakarest] Text (18 B at 0xecfd72), first string "Dance Pop "; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in StyleGroup_LatinDance_Table (at 0xecfcb4),
; [nakarest] which is read by MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more.
NakaInst_Dance_Pop:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18BB4, 0x12
; [nakarest] NakaInst_Rock_Pop  +0x18bc6..+0x18bf8 (0xecfd84, 50 B)
; [nakarest] purpose not established: layout of 50 B at 0xecfd84 not derived; readers below
; [nakarest] Readers: source references MsaMode_Select (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (NakaInst_Rock_Pop_0x2c:24)`), MsaMode_Select_DrawHighlight1
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (NakaInst_Rock_Pop_0x2c:24)`), PmemMode_Select
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (NakaInst_Rock_Pop_0x30:24)`),
; [nakarest] PmemMode_Select_DrawHighlight1 (ui/ui_mode_handlers.s: `lda xbc,
; [nakarest] (NakaInst_Rock_Pop_0x30:24)`), 5 more; 1 data word in StyleGroup_LatinDance_Table
; [nakarest] (at 0xecfcac), which is read by MstStyle1Page_EventDispatch (ui/ui_mode_handlers.s:
; [nakarest] `lda xbc, (StyleGroup_LatinDance_Table:24)`), MstStyle1Sub_HandleSubSelect
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinDance_Table:24)`), 1 more; 1
; [nakarest] data word in StyleGroup_LatinWorld_PairTable_0x2fa (at 0xecfca4), which is read by
; [nakarest] MstStyle1Grid_CellSelect (ui/ui_mode_handlers.s: `lda xwa,
; [nakarest] (StyleGroup_LatinWorld_PairTable_0x2fa:24)`), MstStyle1Grid_PadLeft_Check
; [nakarest] (ui/ui_mode_handlers.s: `lda xbc, (StyleGroup_LatinWorld_PairTable_0x2fa:24)`), 2
; [nakarest] more.
NakaInst_Rock_Pop:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18BC6, 0x32
; [nakarest] SeqChan_Map_10ch  +0x18bf8..+0x18c02 (0xecfdb6, 10 B)
; [nakarest] purpose not established: layout of 10 B at 0xecfdb6 not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long SeqChan_Map_10ch`),
; [nakarest] PmBank_BankChanged_Lookup (display/graphics_text_vga.s: `lda xbc,
; [nakarest] (SeqChan_Map_10ch:24)`), PmBank_Select (display/graphics_text_vga.s: `lda xbc,
; [nakarest] (SeqChan_Map_10ch:24)`), PmBank_Select_DrawFirstRow (display/graphics_text_vga.s:
; [nakarest] `lda xbc, (SeqChan_Map_10ch:24)`); 1 data word in Naka_DrawbarReg_Table (at
; [nakarest] 0xeef5c8).
SeqChan_Map_10ch:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18BF8, 0xA
; [nakarest] SeqChan_Map_8ch  +0x18c02..+0x18c0a (0xecfdc0, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xecfdc0 not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long SeqChan_Map_8ch`); 1 data word
; [nakarest] in Naka_DrawbarReg_Table (at 0xeef5c4).
SeqChan_Map_8ch:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C02, 0x8
; [nakarest] SeqChan_Map_6ch  +0x18c0a..+0x18c10 (0xecfdc8, 6 B)
; [nakarest] purpose not established: layout of 6 B at 0xecfdc8 not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long SeqChan_Map_6ch`); 1 data word
; [nakarest] in Naka_DrawbarReg_Table (at 0xeef5c0).
SeqChan_Map_6ch:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C0A, 0x6
; [nakarest] SeqChan_Map_4ch  +0x18c10..+0x18c14 (0xecfdce, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xecfdce not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long SeqChan_Map_4ch`); 1 data word
; [nakarest] in Naka_DrawbarReg_Table (at 0xeef5bc).
SeqChan_Map_4ch:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C10, 0x4
; [nakarest] SeqChan_Map_2ch  +0x18c14..+0x18c22 (0xecfdd2, 14 B)
; [nakarest] purpose not established: layout of 14 B at 0xecfdd2 not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long SeqChan_Map_2ch`),
; [nakarest] RVari_Confirm_TypeF_SubItems (ui/rvari_routines.s: `lda xhl,
; [nakarest] (SeqChan_Map_2ch_0x2:24)`), RVari_Select_CheckSameBank (ui/ui_mode_handlers.s: `lda
; [nakarest] xhl, (SeqChan_Map_2ch_0x2:24)`); 1 data word in Naka_DrawbarReg_Table (at
; [nakarest] 0xeef5b8).
SeqChan_Map_2ch:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C14, 0xE
; [nakarest] NakaInst_MEMORY_C_ECFDE0  +0x18c22..+0x18c2c (0xecfde0, 10 B)
; [nakarest] Text (10 B at 0xecfde0), first string "MEMORY-C"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in SeqChan_Map_2ch_0x2 (at 0xecfddc), which is
; [nakarest] read by RVari_Confirm_TypeF_SubItems (ui/rvari_routines.s: `lda xhl,
; [nakarest] (SeqChan_Map_2ch_0x2:24)`), RVari_Select_CheckSameBank (ui/ui_mode_handlers.s: `lda
; [nakarest] xhl, (SeqChan_Map_2ch_0x2:24)`).
NakaInst_MEMORY_C_ECFDE0:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C22, 0xA
; [nakarest] NakaInst_MEMORY_B_ECFDEA  +0x18c2c..+0x18c36 (0xecfdea, 10 B)
; [nakarest] Text (10 B at 0xecfdea), first string "MEMORY-B"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in SeqChan_Map_2ch_0x2 (at 0xecfdd8), which is
; [nakarest] read by RVari_Confirm_TypeF_SubItems (ui/rvari_routines.s: `lda xhl,
; [nakarest] (SeqChan_Map_2ch_0x2:24)`), RVari_Select_CheckSameBank (ui/ui_mode_handlers.s: `lda
; [nakarest] xhl, (SeqChan_Map_2ch_0x2:24)`).
NakaInst_MEMORY_B_ECFDEA:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C2C, 0xA
; [nakarest] NakaInst_MEMORY_A_ECFDF4  +0x18c36..+0x18d22 (0xecfdf4, 236 B)
; [nakarest] Text (236 B at 0xecfdf4), first string "MEMORY-A"; no registered NAKA table points
; [nakarest] into it; reached through source references VariScreen_HandlePaint
; [nakarest] (ui/ui_mode_handlers.s: `lda xhl, (NakaInst_MEMORY_A_ECFDF4_0xa:24)`); 1 data word
; [nakarest] in SeqChan_Map_2ch_0x2 (at 0xecfdd4), which is read by RVari_Confirm_TypeF_SubItems
; [nakarest] (ui/rvari_routines.s: `lda xhl, (SeqChan_Map_2ch_0x2:24)`),
; [nakarest] RVari_Select_CheckSameBank (ui/ui_mode_handlers.s: `lda xhl,
; [nakarest] (SeqChan_Map_2ch_0x2:24)`).
NakaInst_MEMORY_A_ECFDF4:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18C36, 0xEC
; [nakarest] Naka_MemoryC_Screens  +0x18d22..+0x18d62 (0xecfee0, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xecfee0 not derived; readers below
; [nakarest] Readers: source references MainChordPre (kn5000_v10_program.s: `lda xbc,
; [nakarest] (Naka_MemoryC_Screens:24)`).
Naka_MemoryC_Screens:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D22, 0x40
; [nakarest] MemScreen_Space1  +0x18d62..+0x18d66 (0xecff20, 4 B)
; [nakarest] Text (4 B at 0xecff20), first string " "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecff1c), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_Space1:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D62, 0x4
; [nakarest] MemScreen_Space2  +0x18d66..+0x18d6a (0xecff24, 4 B)
; [nakarest] Text (4 B at 0xecff24), first string " "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecff18), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_Space2:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D66, 0x4
; [nakarest] MemScreen_Space3  +0x18d6a..+0x18d6e (0xecff28, 4 B)
; [nakarest] Text (4 B at 0xecff28), first string " "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecff14), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_Space3:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D6A, 0x4
; [nakarest] MemScreen_NoteB  +0x18d6e..+0x18d72 (0xecff2c, 4 B)
; [nakarest] Text (4 B at 0xecff2c), first string "B "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecff10), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteB:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D6E, 0x4
; [nakarest] NakaInst_B_a0  +0x18d72..+0x18d78 (0xecff30, 6 B)
; [nakarest] Text (6 B at 0xecff30), first string "B~a0"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_MemoryC_Screens (at 0xecff0c), which is
; [nakarest] read by MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
NakaInst_B_a0:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D72, 0x6
; [nakarest] MemScreen_NoteA_Str  +0x18d78..+0x18d7c (0xecff36, 4 B)
; [nakarest] Text (4 B at 0xecff36), first string "A "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecff08), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteA_Str:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D78, 0x4
; [nakarest] NakaInst_A_a0  +0x18d7c..+0x18d82 (0xecff3a, 6 B)
; [nakarest] Text (6 B at 0xecff3a), first string "A~a0"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_MemoryC_Screens (at 0xecff04), which is
; [nakarest] read by MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
NakaInst_A_a0:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D7C, 0x6
; [nakarest] MemScreen_NoteG  +0x18d82..+0x18d86 (0xecff40, 4 B)
; [nakarest] Text (4 B at 0xecff40), first string "G "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecff00), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteG:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D82, 0x4
; [nakarest] NakaInst_F_9e_ECFF44  +0x18d86..+0x18d8c (0xecff44, 6 B)
; [nakarest] Text (6 B at 0xecff44), first string "F~9e"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_MemoryC_Screens (at 0xecfefc), which is
; [nakarest] read by MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
NakaInst_F_9e_ECFF44:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D86, 0x6
; [nakarest] MemScreen_NoteF  +0x18d8c..+0x18d90 (0xecff4a, 4 B)
; [nakarest] Text (4 B at 0xecff4a), first string "F "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecfef8), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteF:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D8C, 0x4
; [nakarest] MemScreen_NoteE_Str  +0x18d90..+0x18d94 (0xecff4e, 4 B)
; [nakarest] Text (4 B at 0xecff4e), first string "E "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecfef4), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteE_Str:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D90, 0x4
; [nakarest] NakaInst_E_a0_ECFF52  +0x18d94..+0x18d9a (0xecff52, 6 B)
; [nakarest] Text (6 B at 0xecff52), first string "E~a0"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_MemoryC_Screens (at 0xecfef0), which is
; [nakarest] read by MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
NakaInst_E_a0_ECFF52:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D94, 0x6
; [nakarest] MemScreen_NoteD  +0x18d9a..+0x18d9e (0xecff58, 4 B)
; [nakarest] Text (4 B at 0xecff58), first string "D "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecfeec), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteD:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D9A, 0x4
; [nakarest] NakaInst_D_a0_ECFF5C  +0x18d9e..+0x18da4 (0xecff5c, 6 B)
; [nakarest] Text (6 B at 0xecff5c), first string "D~a0"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_MemoryC_Screens (at 0xecfee8), which is
; [nakarest] read by MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
NakaInst_D_a0_ECFF5C:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18D9E, 0x6
; [nakarest] MemScreen_NoteC  +0x18da4..+0x18da8 (0xecff62, 4 B)
; [nakarest] Text (4 B at 0xecff62), first string "C "; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in Naka_MemoryC_Screens (at 0xecfee4), which is read by
; [nakarest] MainChordPre (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`).
MemScreen_NoteC:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18DA4, 0x4
; [nakarest] MemScreen_Blank  +0x18da8..+0x18e4a (0xecff66, 162 B)
; [nakarest] purpose not established: layout of 162 B at 0xecff66 not derived; readers below
; [nakarest] Readers: source references InitializeSuna (storage/flash_floppy_handlers.s:
; [nakarest] `RegTitle 0x4, 0xe1, 0xca64, 0xed, 0x1200000, 0xed0000`), MainChordPre
; [nakarest] (kn5000_v10_program.s: `lda xbc, (0xecff6a:24)`); 1 data word in
; [nakarest] Naka_MemoryC_Screens (at 0xecfee0), which is read by MainChordPre
; [nakarest] (kn5000_v10_program.s: `lda xbc, (Naka_MemoryC_Screens:24)`); 1 data word in
; [nakarest] Bitmap_DigitD_0x22 (at 0xe9e514), which is read by AcWelcomScreenProc
; [nakarest] (ui/drawbar_panel_ui.s: `ld xwa, Bitmap_DigitD_0x22`); 1 data word in
; [nakarest] Bitmap_DigitD_0x8da (at 0xe9edcc), which is read by AcWelcomScreenProc
; [nakarest] (ui/drawbar_panel_ui.s: `ld xwa, Bitmap_DigitD_0x8da`); words in 1 more objects.
MemScreen_Blank:
	.incbin "includes/generated/naka_style_bitmaps.bin", 0x18DA8, 0xA2
; External label offsets within the binary blob above.
.include "extensions/extension_data.s"
