
; Sequencer Channel Containers + Drawbar/Mixer Data (13 widgets, 7936 bytes)
; Source: maincpu/ui_widgets/naka_sequencer_channels.c (C struct with named fields)
NakaData_SeqChannels:
	.incbin "includes/generated/naka_sequencer_channels.bin"

; External label offsets within the binary blob above.
	.equ Naka_DrawbarOrgan_Screens, NakaData_SeqChannels + 0x06A0
	.equ SeqCh_FeatureDemoCallbackData, NakaData_SeqChannels + 0x07A8
	.equ SeqCh_SystemHandlerData, NakaData_SeqChannels + 0x0888
	.equ MixerPart_NamePtrTable, NakaData_SeqChannels + 0x0C48
	.equ Naka_DrawbarControl_Table, NakaData_SeqChannels + 0x0CCC
	.equ MidiPart_ConfigNameTable, NakaData_SeqChannels + 0x0D5C
	.equ Naka_DrawbarSlider_Resources, NakaData_SeqChannels + 0x0F48
	.equ Naka_DrawbarDisplay_Table1, NakaData_SeqChannels + 0x12D8
	.equ Naka_DrawbarDisplay_Table2, NakaData_SeqChannels + 0x1358
	.equ Naka_DrawbarReg_Table, NakaData_SeqChannels + 0x1510
	.equ Palette_8bit_RGBA_2_Data, NakaData_SeqChannels + 0x1A78
