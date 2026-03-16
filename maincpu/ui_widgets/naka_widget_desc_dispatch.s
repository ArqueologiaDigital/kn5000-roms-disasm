// Widget descriptor dispatch data
// Extracted from kn5000_v10_program.s
// Contains: NAKA dispatch widgets (AcPmemOutLGridBox, AcPcgOutGridBox, etc.),
// MidiMenu_MsgType_Table, MidiMenu_NakaProcName_Table, and instance name strings.

	jr	gt, 0x00
	aligned_string "AcPmemOutLGridBox"
	pop xwa
	pop xwa
	jr	gt, 0
	aligned_string "AcPcgOutGridBox"
	pop xwa
	pop xwa
	jr	gt, 0
	aligned_string "AcParaLoadOptGridBox"
	pop xwa
	pop xwa
	jr	gt, 0
	aligned_string "AcInOutGridBox"
	pop xwa
	pop xwa
	jr	gt, 0x00
	aligned_string "AcVocalGridBox"
	pop xwa
	pop xwa
	jr	gt, 0
	aligned_string "AcFadeSetGridBox"
	aligned_string "nXXFB"
	aligned_string "AcLswFuncBox"
	aligned_string "nXXFB"
	aligned_string "AcLswFuncEditBox"
	nop
	swi	7
	aligned_string "AcGMOnOffBox"
	aligned_string "fjXn"
	aligned_string "AcSendEditSw"
	.byte 0x41, 0x74, 0x74, 0x00
	aligned_string "IvMpstPageControl"
	nop
	swi	7
	aligned_string "AcVocalistListBox"
	nop
	swi	7
	aligned_string "PsHarmOnOffBox"
	rcf
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0xa0, 0x5d, 0xe5, 0x00


MidiMenu_MsgType_Table:
	.long MsgType_ExcSend
	.long MsgType_DrawKey
	.long MsgType_MpstLoad
	.long MsgType_MpstWrite
	.long MsgType_FlashWrite
	.long MsgType_FlashLoad
	.long MsgType_VstPstOk
	.long MsgType_VstSendOk
	.long MsgType_RevLoad
	.long MsgType_EqLoad
	.long MsgType_RevEqLoad
	nop
	nop
	nop
	nop
MsgType_RevEqLoad:	aligned_string "MT_REVEQLOAD"
MsgType_EqLoad:		aligned_string "MT_EQLOAD"
MsgType_RevLoad:	aligned_string "MT_REVLOAD"
MsgType_VstSendOk:	aligned_string "MT_VST_SEND_OK"
MsgType_VstPstOk:	aligned_string "MT_VST_PST_OK"
MsgType_FlashLoad:	aligned_string "MT_FLASHLOAD"
MsgType_FlashWrite:	aligned_string "MT_FLASHWRITE"
MsgType_MpstWrite:	aligned_string "MT_MPSTWRITE"
MsgType_MpstLoad:	aligned_string "MT_MPSTLOAD"
MsgType_DrawKey:	aligned_string "MT_DRAWKEY"
MsgType_ExcSend:	aligned_string "MT_EXCSEND"
	aligned_string "MT_PCGSEND"
	incf
	nop
	.byte 0xb5, 0x3f
	ldx
	nop
	pop_f
	ld	xwa, 1647706359
	.byte 0xf7
	nop
	.byte 0xf5, 0x7d, 0xf7
	nop
	rcf
	ld	xsp, 1301020919
	.byte 0xf7
	nop
	muls	xsp, xsp
	ldx
	nop
	pushw bc
	.byte 0x52
	ldx
	nop
	ld	xde, 1510012726
	.byte 0x57
	ldx
	nop
	pop xiz
	jr	po, 16777207
	nop
	.byte 0xda, 0x73
	ldx
	nop
	pushw bc
	cp	l, (xhl)
	nop
	jrl	po, 16775046
	nop
	.byte 0xdc, 0x9a
	ldx
	nop
	.byte 0xf4, 0xa1, 0xf7
	nop
	nop
	nop
	nop
	nop
MidiMenu_NakaProcName_Table:
	.long NakaInst_AcVocalistListBoxProc
	.long NakaInst_PsHarmOnOffBoxProc
	.long NakaInst_IvMpstPageControlProc
	.long NakaInst_AcSendEditSwProc
	.long NakaInst_AcGMOnOffBoxProc
	.long NakaInst_AcLswFuncBoxProc
	.long NakaInst_AcLswFuncEditBoxProc
	.long NakaInst_AcFadeSetGridBoxProc
	.long NakaInst_AcVocalGridBoxProc
	.long NakaInst_AcInOutGridBoxProc
	.long NakaInst_AcParaLoadOptGridBoxProc
	.long NakaInst_AcPcgOutGridBoxProc
	.long NakaInst_AcPmemOutLGridBoxProc
	.long NakaInst_AcPmemOutRGridBoxProc
	.long NakaInst_AcCtlMsgGridBoxProc
	.long NakaInst_AcMidiPartGridBoxProc
	.long NakaProc_NullEntry
NakaProc_NullEntry:
	.byte 0x00, 0xff
