
; Multilingual Disk Operation Warning Strings (30 widgets, 16430 bytes)
; Source: maincpu/ui_widgets/naka_disk_warning.c (C struct with named fields)
DiskWarning_ConfirmStrings:
	.incbin "includes/generated/naka_disk_warning.bin"

; External label offsets within the binary blob above.
	.equ Data_SoundEditorCharsLayout, DiskWarning_ConfirmStrings + 0x1226
	.equ NakaInst_OK, DiskWarning_ConfirmStrings + 0x164E
	.equ Str_No, DiskWarning_ConfirmStrings + 0x166A
	.equ Data_CharMapFormatBlock, DiskWarning_ConfirmStrings + 0x24F4
