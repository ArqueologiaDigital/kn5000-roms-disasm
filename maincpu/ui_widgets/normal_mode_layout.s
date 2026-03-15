
; Normal Mode screen layout (14 widgets, 1168 bytes)
; Source: maincpu/ui_widgets/naka_normal_mode.c (C struct with named fields)
NakaInst_TEST6FUNC:
	.incbin "includes/generated/naka_normal_mode.bin"

; External label offsets within the binary blob above.
	.equ NakaInst_TEST4FUNC, NakaInst_TEST6FUNC + 0x000A
	.equ NakaInst_TEST3FUNC, NakaInst_TEST6FUNC + 0x0014
	.equ NakaInst_TEST2FUNC, NakaInst_TEST6FUNC + 0x001E
	.equ NakaInst_MainWallSetFlashFunc, NakaInst_TEST6FUNC + 0x0028
	.equ NakaInst_MainTimeFlashFunc, NakaInst_TEST6FUNC + 0x003E
	.equ NakaInst_MainMssSetUp, NakaInst_TEST6FUNC + 0x0050
	.equ NakaInst_FswAsIniFunc, NakaInst_TEST6FUNC + 0x005E
	.equ NakaInst_CntIniFunc, NakaInst_TEST6FUNC + 0x006C
	.equ NakaInst_MainSysControl, NakaInst_TEST6FUNC + 0x0078
	.equ NakaInst_OneTchFUNC, NakaInst_TEST6FUNC + 0x0088
	.equ NakaInst_MainPmGet, NakaInst_TEST6FUNC + 0x0094
	.equ NakaInst_MainChordPre, NakaInst_TEST6FUNC + 0x009E
	.equ NakaInst_MainGetRhyGrpName, NakaInst_TEST6FUNC + 0x00AC
	.equ NakaInst_MainGetSndGrpName, NakaInst_TEST6FUNC + 0x00BE
	.equ NakaInst_MainGetRhyName, NakaInst_TEST6FUNC + 0x00D0
	.equ NakaInst_MainRvariIni, NakaInst_TEST6FUNC + 0x00E0
	.equ NakaInst_MainGetSndName, NakaInst_TEST6FUNC + 0x00EE
	.equ NakaInst_MainSvariIni, NakaInst_TEST6FUNC + 0x00FE
	.equ NakaInst_MainVariSet, NakaInst_TEST6FUNC + 0x010C
