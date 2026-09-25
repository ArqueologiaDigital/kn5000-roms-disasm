// Widget descriptor dispatch data
// Extracted from kn5000_v10_program.s
// Contains: NAKA dispatch widgets (AcPmemOutLGridBox, AcPcgOutGridBox, etc.),
// MidiMenu_MsgType_Table, MidiMenu_NakaProcName_Table, and instance name strings.

; MIDI-menu object tables that InitializeEast (sequencer/seq_event_playback.s)
; registers with RegObjTable/RegObjTabl -- see each block below.  Regenerate with
; scripts/generators/gen_midimenu_registration_data.py (--probe checks it).
; Strings of the 16 widget records (24 bytes each, naka_dispatch_t) at 0xE559EA,
; which `RegObjTable 0x1600004, ClassProc, 0xe55cd4, 0xe559ea, 0x163` registers:
; record +12 points at an instance-code string ("XXj", "nXXFB", "fjXn", "Att"
; or "") and +8 at the name after it.  The first two bytes end "XXj", which
; starts at 0xE55BC6 in the previous file.
	.byte 0x6a, 0x00
	aligned_string "AcPmemOutLGridBox"
	aligned_string "XXj"
	aligned_string "AcPcgOutGridBox"
	aligned_string "XXj"
	aligned_string "AcParaLoadOptGridBox"
	aligned_string "XXj"
	aligned_string "AcInOutGridBox"
	aligned_string "XXj"
	aligned_string "AcVocalGridBox"
	aligned_string "XXj"
	aligned_string "AcFadeSetGridBox"
	aligned_string "nXXFB"
	aligned_string "AcLswFuncBox"
	aligned_string "nXXFB"
	aligned_string "AcLswFuncEditBox"
	aligned_string ""
	aligned_string "AcGMOnOffBox"
	aligned_string "fjXn"
	aligned_string "AcSendEditSw"
	aligned_string "Att"
	aligned_string "IvMpstPageControl"
	aligned_string ""
	aligned_string "AcVocalistListBox"
	aligned_string ""
	aligned_string "PsHarmOnOffBox"
; u16 16: number of widget records at 0xE559EA, read by that RegObjTable
; (`ldw_da xwa,(0xe55cd4)`).
MidiMenu_WidgetCount:
	.short 16
; Empty table (one zero word) and its count 0, registered by
; `RegObjTable 0x160000c, ResEventProc, 0xe55cda, 0xe55cd6, 0x1c3`.
MidiMenu_ResEventTable:
	.long 0
MidiMenu_ResEventCount:
	.short 0
; 12 message-type string pointers + NULL, registered by
; `RegObjTable 0x160000d, ResMethodProc, 0xe55dac, 0xe55cdc, 0x1e3` (count:
; MidiMenu_MsgTypeCount).  The first entry, MT_PCGSEND, used to be written as
; "padding" with this label one entry later.
MidiMenu_MsgType_Table:
	.long MsgType_PcgSend
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
	.long 0
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
MsgType_PcgSend:	aligned_string "MT_PCGSEND"
; u16 12: entries of MidiMenu_MsgType_Table, read by that RegObjTable
; (`ldw_da xwa,(0xe55dac)`).
MidiMenu_MsgTypeCount:
	.short 12
; 16 routine pointers + NULL, registered with count 16 by
; `RegObjTabl 0x1600001, FunctionProc, 0x10, 0xe55dae, 0x103`.  Entry k is the
; routine named by the string MidiMenu_NakaProcName_Table entry k points at (the
; next RegObjTabl, id 0x403).
MidiMenu_ProcTable:
	.long AcVocalistListBoxProc
	.long PsHarmOnOffBoxProc
	.long IvMpstPageControlProc
	.long AcSendEditSwProc
	.long AcGMOnOffBoxProc
	.long AcLswFuncBoxProc
	.long AcLswFuncEditBoxProc
	.long AcFadeSetGridBoxProc
	.long AcVocalGridBoxProc
	.long AcInOutGridBoxProc
	.long AcParaLoadOptGridBoxProc
	.long AcPcgOutGridBoxProc
	.long AcPmemOutLGridBoxProc
	.long AcPmemOutRGridBoxProc
	.long AcCtlMsgGridBoxProc
	.long AcMidiPartGridBoxProc
	.long 0
; 16 name-string pointers + a pointer to the empty string NakaProc_NullEntry,
; registered by `RegObjTabl 0x1600001, FunctionProc, 0x10,
; MidiMenu_NakaProcName_Table, 0x403`; entry k names MidiMenu_ProcTable entry k.
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
