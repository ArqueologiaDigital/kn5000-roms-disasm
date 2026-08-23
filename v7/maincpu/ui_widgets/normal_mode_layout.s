
; Normal Mode screen layout (14 widgets, 1168 bytes)
; Source: maincpu/ui_widgets/naka_normal_mode.c (C struct with named fields)
NakaInst_TEST6FUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0, 0xA
NakaInst_TEST4FUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0xA, 0xA
NakaInst_TEST3FUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0x14, 0xA
NakaInst_TEST2FUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0x1E, 0xA
NakaInst_MainWallSetFlashFunc:
	.incbin "includes/generated/naka_normal_mode.bin", 0x28, 0x16
NakaInst_MainTimeFlashFunc:
	.incbin "includes/generated/naka_normal_mode.bin", 0x3E, 0x12
NakaInst_MainMssSetUp:
	.incbin "includes/generated/naka_normal_mode.bin", 0x50, 0xE
NakaInst_FswAsIniFunc:
	.incbin "includes/generated/naka_normal_mode.bin", 0x5E, 0xE
NakaInst_CntIniFunc:
	.incbin "includes/generated/naka_normal_mode.bin", 0x6C, 0xC
NakaInst_MainSysControl:
	.incbin "includes/generated/naka_normal_mode.bin", 0x78, 0x10
NakaInst_OneTchFUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0x88, 0xC
NakaInst_MainPmGet:
	.incbin "includes/generated/naka_normal_mode.bin", 0x94, 0xA
NakaInst_MainChordPre:
	.incbin "includes/generated/naka_normal_mode.bin", 0x9E, 0xE
NakaInst_MainGetRhyGrpName:
	.incbin "includes/generated/naka_normal_mode.bin", 0xAC, 0x12
NakaInst_MainGetSndGrpName:
	.incbin "includes/generated/naka_normal_mode.bin", 0xBE, 0x12
NakaInst_MainGetRhyName:
	.incbin "includes/generated/naka_normal_mode.bin", 0xD0, 0x10
NakaInst_MainRvariIni:
	.incbin "includes/generated/naka_normal_mode.bin", 0xE0, 0xE
NakaInst_MainGetSndName:
	.incbin "includes/generated/naka_normal_mode.bin", 0xEE, 0x10
NakaInst_MainSvariIni:
	.incbin "includes/generated/naka_normal_mode.bin", 0xFE, 0xE
NakaInst_MainVariSet:
	.incbin "includes/generated/naka_normal_mode.bin", 0x10C, 0x384
; External label offsets within the binary blob above.
