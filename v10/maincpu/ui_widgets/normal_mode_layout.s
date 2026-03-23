
; Normal Mode screen layout (14 widgets, 1168 bytes)
; Source: maincpu/ui_widgets/naka_normal_mode.c (C struct with named fields)
NakaInst_TEST6FUNC:
	.incbin "includes/generated/naka_normal_mode.bin"

; External label offsets within the binary blob above.
	.equ NakaInst_TEST4FUNC, NakaInst_TEST6FUNC + 0x000a
	.equ NakaInst_TEST3FUNC, NakaInst_TEST6FUNC + 0x0014
	.equ NakaInst_TEST2FUNC, NakaInst_TEST6FUNC + 0x001e
	.equ NakaInst_MainWallSetFlashFunc, NakaInst_TEST6FUNC + 0x0028
	.equ NakaInst_MainTimeFlashFunc, NakaInst_TEST6FUNC + 0x003e
	.equ NakaInst_MainMssSetUp, NakaInst_TEST6FUNC + 0x0050
	.equ NakaInst_FswAsIniFunc, NakaInst_TEST6FUNC + 0x005e
	.equ NakaInst_CntIniFunc, NakaInst_TEST6FUNC + 0x006c
	.equ NakaInst_MainSysControl, NakaInst_TEST6FUNC + 0x0078
	.equ NakaInst_OneTchFUNC, NakaInst_TEST6FUNC + 0x0088
	.equ NakaInst_MainPmGet, NakaInst_TEST6FUNC + 0x0094
	.equ NakaInst_MainChordPre, NakaInst_TEST6FUNC + 0x009e
	.equ NakaInst_MainGetRhyGrpName, NakaInst_TEST6FUNC + 0x00ac
	.equ NakaInst_MainGetSndGrpName, NakaInst_TEST6FUNC + 0x00be
	.equ NakaInst_MainGetRhyName, NakaInst_TEST6FUNC + 0x00d0
	.equ NakaInst_MainRvariIni, NakaInst_TEST6FUNC + 0x00e0
	.equ NakaInst_MainGetSndName, NakaInst_TEST6FUNC + 0x00ee
	.equ NakaInst_MainSvariIni, NakaInst_TEST6FUNC + 0x00fe
	.equ NakaInst_MainVariSet, NakaInst_TEST6FUNC + 0x010c
