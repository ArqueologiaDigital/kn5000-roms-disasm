
; Debug/Naming Panel Simulator screen widgets (55 widgets, 18112 bytes)
; Source: maincpu/ui_widgets/naka_debug_naming.c (C struct with named fields)
NakaDbg_PanelSimTitle:
	.incbin "includes/generated/naka_debug_naming.bin"

; External label offsets within the binary blob above.
	.equ NakaDbg_LowerCaseChars, NakaDbg_PanelSimTitle + 0x037c
	.equ NakaDbg_LowerCaseChars2, NakaDbg_PanelSimTitle + 0x0380
	.equ Palette_8bit_RGBA, NakaDbg_PanelSimTitle + 0x0ce0
	.equ NakaColor_Palette1, NakaDbg_PanelSimTitle + 0x10e0
	.equ NakaColor_Palette2, NakaDbg_PanelSimTitle + 0x14e0
	.equ NakaColor_Palette3, NakaDbg_PanelSimTitle + 0x18e0
	.equ NakaColor_Palette4, NakaDbg_PanelSimTitle + 0x1ce0
	.equ NakaColor_Palette5, NakaDbg_PanelSimTitle + 0x20e0
	.equ NakaColor_Palette6, NakaDbg_PanelSimTitle + 0x24e0
	.equ NakaColor_Palette7, NakaDbg_PanelSimTitle + 0x28e0
	.equ NakaColor_Palette8, NakaDbg_PanelSimTitle + 0x2ce0
	.equ NakaColor_Palette9, NakaDbg_PanelSimTitle + 0x30e0
	.equ NakaColor_Palette10, NakaDbg_PanelSimTitle + 0x34e0
	.equ NakaColor_PaletteBlank, NakaDbg_PanelSimTitle + 0x38e0
	.equ NakaProp_FontEntry0, NakaDbg_PanelSimTitle + 0x3ce0
	.equ NakaProp_FontEntry1, NakaDbg_PanelSimTitle + 0x3cf4
	.equ NakaProp_FontEntry2, NakaDbg_PanelSimTitle + 0x3d08
	.equ NakaInst_False, NakaDbg_PanelSimTitle + 0x3d1c
	.equ NakaProp_BoolEntry1, NakaDbg_PanelSimTitle + 0x3d4c
	.equ NakaProp_BoolEntry2, NakaDbg_PanelSimTitle + 0x3d60
	.equ NakaProp_BoolEntry3, NakaDbg_PanelSimTitle + 0x3d74
	.equ NakaProp_BoolEntry4, NakaDbg_PanelSimTitle + 0x3d88
	.equ NakaProp_BoolEntry5, NakaDbg_PanelSimTitle + 0x3d9c
	.equ NakaProp_BoolEntry6, NakaDbg_PanelSimTitle + 0x3db0
	.equ NakaProp_BoolEntry7, NakaDbg_PanelSimTitle + 0x3dc4
	.equ NakaProp_BoolEntry8, NakaDbg_PanelSimTitle + 0x3dd8
	.equ NakaProp_CFlagEntry, NakaDbg_PanelSimTitle + 0x3dec
	.equ NakaProp_VisFlag_Header, NakaDbg_PanelSimTitle + 0x3e24
	.equ NakaProp_VisFlag_Chain, NakaDbg_PanelSimTitle + 0x3e2e
	.equ NakaProp_BorderDefs, NakaDbg_PanelSimTitle + 0x40d2
	.equ NakaProp_Align_Header, NakaDbg_PanelSimTitle + 0x426e
	.equ NakaProp_Align_PtrEntry, NakaDbg_PanelSimTitle + 0x4282
	.equ NakaProp_EditSwitch_Chain, NakaDbg_PanelSimTitle + 0x42d8
	.equ NakaInst_LM_RightDown, NakaDbg_PanelSimTitle + 0x457c
	.equ NakaProp_Frame_Header, NakaDbg_PanelSimTitle + 0x45dc
	.equ NakaProp_Frame_Chain, NakaDbg_PanelSimTitle + 0x45f0
