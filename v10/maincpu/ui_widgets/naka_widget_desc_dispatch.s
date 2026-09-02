// Widget descriptor dispatch data
// Extracted from kn5000_v10_program.s
// Contains: NAKA dispatch widgets (AcPmemOutLGridBox, AcPcgOutGridBox, etc.),
// MidiMenu_MsgType_Table, MidiMenu_NakaProcName_Table, and instance name strings.

	.byte 0x6a, 0x00
	aligned_string "AcPmemOutLGridBox"
	.byte 0x58, 0x58, 0x6a, 0x00
	aligned_string "AcPcgOutGridBox"
	.byte 0x58, 0x58, 0x6a, 0x00
	aligned_string "AcParaLoadOptGridBox"
	.byte 0x58, 0x58, 0x6a, 0x00
	aligned_string "AcInOutGridBox"
	.byte 0x58, 0x58, 0x6a, 0x00
	aligned_string "AcVocalGridBox"
	.byte 0x58, 0x58, 0x6a, 0x00
	aligned_string "AcFadeSetGridBox"
	aligned_string "nXXFB"
	aligned_string "AcLswFuncBox"
	aligned_string "nXXFB"
	aligned_string "AcLswFuncEditBox"
	.byte 0x00			; padding
	.byte 0xff			; padding
	aligned_string "AcGMOnOffBox"
	aligned_string "fjXn"
	aligned_string "AcSendEditSw"
	.byte 0x41, 0x74, 0x74, 0x00
	aligned_string "IvMpstPageControl"
	.byte 0x00			; padding
	.byte 0xff			; padding
	aligned_string "AcVocalistListBox"
	.byte 0x00			; padding
	.byte 0xff			; padding
	aligned_string "PsHarmOnOffBox"
	.byte 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xa0, 0x5d, 0xe5, 0x00		; padding


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
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
	.byte 0x00			; padding
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
	.byte 0x0c, 0x00, 0xb5, 0x3f, 0xf7, 0x00, 0x19, 0x40, 0xf7, 0x00, 0x36, 0x62, 0xf7, 0x00, 0xf5, 0x7d		; padding
	.byte 0xf7, 0x00, 0x10, 0x47, 0xf7, 0x00, 0x8c, 0x4d, 0xf7, 0x00, 0xdf, 0x4f, 0xf7, 0x00, 0x29, 0x52		; padding
	.byte 0xf7, 0x00, 0x42, 0x36, 0xf7, 0x00, 0x5a, 0x57, 0xf7, 0x00, 0x5e, 0x6c, 0xf7, 0x00, 0xda, 0x73		; padding
	.byte 0xf7, 0x00, 0x29, 0x83, 0xf7, 0x00, 0x7c, 0x86, 0xf7, 0x00, 0xdc, 0x9a, 0xf7, 0x00, 0xf4, 0xa1		; padding
	.byte 0xf7, 0x00, 0x00, 0x00, 0x00, 0x00		; padding
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
