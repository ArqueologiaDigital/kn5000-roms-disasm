
; Sound Menu / Drawbar Screens widget data (8 widgets, 2314 bytes)
; Source: maincpu/ui_widgets/naka_sound_menu_drawbar.c (C struct with named fields)
NakaData_SoundMenuDrawbar:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin"

; External label offsets within the binary blob above.
	.equ Naka_EventDispatch_Table, NakaData_SoundMenuDrawbar + 0x0306
	.equ Naka_Event_Table3, NakaData_SoundMenuDrawbar + 0x03C4
	.equ Naka_Event_Table2, NakaData_SoundMenuDrawbar + 0x05AE
	.equ NakaInst_EmptyString, NakaData_SoundMenuDrawbar + 0x0642
	.equ NakaInst_IvSdpartProc, NakaData_SoundMenuDrawbar + 0x08C0
	.equ NakaContainer_SoundMenu_Root, NakaData_SoundMenuDrawbar + 0x08CE
	.equ NakaDesc_SOUND_MENU, NakaData_SoundMenuDrawbar + 0x08F8
	.equ NakaWidget_SoundMenu_PageButton, NakaData_SoundMenuDrawbar + 0x0904
