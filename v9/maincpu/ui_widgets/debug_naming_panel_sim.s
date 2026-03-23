
; Debug/Naming Panel Simulator screen widgets (55 widgets, 18112 bytes)
; Source: maincpu/ui_widgets/naka_debug_naming.c (C struct with named fields)
NakaDbg_PanelSimTitle:
	.incbin "includes/generated/naka_debug_naming.bin"

; External label offsets within the binary blob above.
	.equ NakaDbg_LowerCaseChars, NakaDbg_PanelSimTitle + 0x037C
	.equ NakaDbg_LowerCaseChars2, NakaDbg_PanelSimTitle + 0x0380
	.equ Palette_8bit_RGBA, NakaDbg_PanelSimTitle + 0x0CE0
	.equ NakaColor_Palette1, NakaDbg_PanelSimTitle + 0x10E0
	.equ NakaColor_Palette2, NakaDbg_PanelSimTitle + 0x14E0
	.equ NakaColor_Palette3, NakaDbg_PanelSimTitle + 0x18E0
	.equ NakaColor_Palette4, NakaDbg_PanelSimTitle + 0x1CE0
	.equ NakaColor_Palette5, NakaDbg_PanelSimTitle + 0x20E0
	.equ NakaColor_Palette6, NakaDbg_PanelSimTitle + 0x24E0
	.equ NakaColor_Palette7, NakaDbg_PanelSimTitle + 0x28E0
	.equ NakaColor_Palette8, NakaDbg_PanelSimTitle + 0x2CE0
	.equ NakaColor_Palette9, NakaDbg_PanelSimTitle + 0x30E0
	.equ NakaColor_Palette10, NakaDbg_PanelSimTitle + 0x34E0
	.equ NakaColor_PaletteBlank, NakaDbg_PanelSimTitle + 0x38E0
	.equ NakaProp_FontEntry0, NakaDbg_PanelSimTitle + 0x3CE0
	.equ NakaProp_FontEntry1, NakaDbg_PanelSimTitle + 0x3CF4
	.equ NakaProp_FontEntry2, NakaDbg_PanelSimTitle + 0x3D08
	.equ NakaInst_False, NakaDbg_PanelSimTitle + 0x3D1C
	.equ NakaProp_BoolEntry1, NakaDbg_PanelSimTitle + 0x3D4C
	.equ NakaProp_BoolEntry2, NakaDbg_PanelSimTitle + 0x3D60
	.equ NakaProp_BoolEntry3, NakaDbg_PanelSimTitle + 0x3D74
	.equ NakaProp_BoolEntry4, NakaDbg_PanelSimTitle + 0x3D88
	.equ NakaProp_BoolEntry5, NakaDbg_PanelSimTitle + 0x3D9C
	.equ NakaProp_BoolEntry6, NakaDbg_PanelSimTitle + 0x3DB0
	.equ NakaProp_BoolEntry7, NakaDbg_PanelSimTitle + 0x3DC4
	.equ NakaProp_BoolEntry8, NakaDbg_PanelSimTitle + 0x3DD8
	.equ NakaProp_CFlagEntry, NakaDbg_PanelSimTitle + 0x3DEC
	.equ NakaProp_VisFlag_Header, NakaDbg_PanelSimTitle + 0x3E24
	.equ NakaProp_VisFlag_Chain, NakaDbg_PanelSimTitle + 0x3E2E
	.equ NakaProp_BorderDefs, NakaDbg_PanelSimTitle + 0x40D2
	.equ NakaProp_Align_Header, NakaDbg_PanelSimTitle + 0x426E
	.equ NakaProp_Align_PtrEntry, NakaDbg_PanelSimTitle + 0x4282
	.equ NakaProp_EditSwitch_Chain, NakaDbg_PanelSimTitle + 0x42D8
	.equ NakaInst_LM_RightDown, NakaDbg_PanelSimTitle + 0x457C
	.equ NakaProp_Frame_Header, NakaDbg_PanelSimTitle + 0x45DC
	.equ NakaProp_Frame_Chain, NakaDbg_PanelSimTitle + 0x45F0
