
; Sound Menu / Drawbar Screens widget data (8 widgets, 2314 bytes)
; Source: maincpu/ui_widgets/naka_sound_menu_drawbar.c (C struct with named fields)
NakaData_SoundMenuDrawbar:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0, 0x306
Naka_EventDispatch_Table:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x306, 0xBE
Naka_Event_Table3:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x3C4, 0x1EA
Naka_Event_Table2:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x5AE, 0x94
NakaInst_EmptyString:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x642, 0x27E
NakaInst_IvSdpartProc:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x8C0, 0xE
NakaContainer_SoundMenu_Root:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x8CE, 0x2A
NakaDesc_SOUND_MENU:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x8F8, 0xC
NakaWidget_SoundMenu_PageButton:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x904, 0x6
; External label offsets within the binary blob above.
