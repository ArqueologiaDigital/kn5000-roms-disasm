
; MIDI/Reverb/Presets screen widgets (267 widgets, 17766 bytes)
; Source: maincpu/ui_widgets/naka_midi_reverb.c (C struct with named fields)
NakaInst_AcMidiPartGridBoxProc:
	.incbin "includes/generated/naka_midi_reverb.bin"

; External label offsets within the binary blob above.
	.equ NakaInst_95_Bass_Pedals_95_Ext_Sequencer_95, NakaInst_AcMidiPartGridBoxProc + 0x1a28
	.equ NakaInst_AcCtlMsgGridBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x0016
	.equ NakaInst_AcFadeSetGridBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x00ac
	.equ NakaInst_AcGMOnOffBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x00ea
	.equ NakaInst_AcInOutGridBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x0084
	.equ NakaInst_AcLswFuncBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x00d8
	.equ NakaInst_AcLswFuncEditBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x00c2
	.equ NakaInst_AcParaLoadOptGridBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x006a
	.equ NakaInst_AcPcgOutGridBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x0056
	.equ NakaInst_AcPmemOutLGridBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x0040
	.equ NakaInst_AcPmemOutRGridBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x002a
	.equ NakaInst_AcSendEditSwProc, NakaInst_AcMidiPartGridBoxProc + 0x00fc
	.equ NakaInst_AcVocalGridBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x0098
	.equ NakaInst_AcVocalistListBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x0138
	.equ NakaInst_IvMpstPageControlProc, NakaInst_AcMidiPartGridBoxProc + 0x010e
	.equ NakaInst_PsHarmOnOffBoxProc, NakaInst_AcMidiPartGridBoxProc + 0x0124
