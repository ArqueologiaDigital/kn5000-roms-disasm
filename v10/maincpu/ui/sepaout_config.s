; =============================================================================
; SepaOut Config & Resource Info Handler Offsets
; RESOURCE_INFO_HANDLER_OFFSETS dispatch table and SepaOut_* layout/config data
; Extracted from kn5000_v10_program.s
; =============================================================================

RESOURCE_INFO_HANDLER_OFFSETS:
	.short RESOURCE_INFO_HANDLERS - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetSRAMBankRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetUserAreaRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetSndParamRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetVoiceBankRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetToneGenRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetFlashBankRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetMspSettingsRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetResourceListPtr - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetTableDataInfo - RESOURCE_INFO_HANDLERS

; SepaOut configuration data (826 bytes, compiled from sepaout_config.c)
SepaOut_Config_0:	.incbin "includes/generated/sepaout_config.bin", 0x0, 0x4
; SepaOut_Msg_CC9B_Value32: 4-byte sub-CPU control-change template B0 <part> 9B 20 (status, part placeholder,
;   controller 0x9B, value 0x20 = 32); SetSepaOutMode patches the part to 0x14/0x13/0x16 and sends it with sendCOMM.
;   Basis: readers + bytes -- used for part 0x14 in modes 1-3 and for all three parts in modes 2-3; mode 0 sends
;   SepaOut_Config_0 (B0 xx 9B 01) instead.
SepaOut_Msg_CC9B_Value32:	.incbin "includes/generated/sepaout_config.bin", 0x4, 0x4
; SepaOut_Msg_CC9D_Value0: 4-byte sub-CPU control-change template B0 <part> 9D 00 (controller 0x9D, value 0);
;   SetSepaOutMode sends it for parts 0x14, 0x13 and 0x16 in modes 0, 1 and 2. Basis: readers + bytes.
SepaOut_Msg_CC9D_Value0:	.incbin "includes/generated/sepaout_config.bin", 0x8, 0x4
; SepaOut_Msg_CC9D_Value1: 4-byte sub-CPU control-change template B0 <part> 9D 01 (controller 0x9D, value 1);
;   SetSepaOutMode sends it only in mode 3, for parts 0x13 and 0x16. Basis: readers + bytes.
SepaOut_Msg_CC9D_Value1:	.incbin "includes/generated/sepaout_config.bin", 0xC, 0x4
; SepaOut_Msg_CC9D_Value2: 4-byte sub-CPU control-change template B0 <part> 9D 02 (controller 0x9D, value 2);
;   SetSepaOutMode sends it only in mode 3, for part 0x14. Basis: readers + bytes.
SepaOut_Msg_CC9D_Value2:	.incbin "includes/generated/sepaout_config.bin", 0x10, 0x4
SqSngSelTtlFunc_CaseTable:
	.short	SqTrAs_CondCheck - SqTrAs_CondCheck
	.short	SqSngSelTtlFunc_OnTitleOld - SqTrAs_CondCheck
	.short	SqSngName_ReturnZero - SqTrAs_CondCheck
	.short	SqSngName_ReturnZero - SqTrAs_CondCheck
	.short	SqSngName_ReturnZero - SqTrAs_CondCheck
	.short	SqSngName_ReturnZero - SqTrAs_CondCheck
SqSngNameTtlFunc_CaseTable:
	.short	SQTR_DISPATCH_TABLE_1 - SQTR_DISPATCH_TABLE_1
	.short	SqSngNameTtlFunc_OnTitleOld - SQTR_DISPATCH_TABLE_1
	.short	SqTrAs_ReturnZero - SQTR_DISPATCH_TABLE_1
	.short	SqTrAs_ReturnZero - SQTR_DISPATCH_TABLE_1
	.short	SqTrAs_ReturnZero - SQTR_DISPATCH_TABLE_1
	.short	SqTrAs_ReturnZero - SQTR_DISPATCH_TABLE_1
SqTrAsTtlFunc_CaseTable:
	.short	SQTR_DISPATCH_TABLE_2 - SQTR_DISPATCH_TABLE_2
	.short	SQTR_DISPATCH_TABLE_2_CASE1 - SQTR_DISPATCH_TABLE_2
	.short	CDlikeSwTtl_ReturnZero2 - SQTR_DISPATCH_TABLE_2
	.short	SQTR_DISPATCH_TABLE_2_CASE2 - SQTR_DISPATCH_TABLE_2
	.short	CDlikeSwTtl_ReturnZero2 - SQTR_DISPATCH_TABLE_2
	.short	CDlikeSwTtl_ReturnZero2 - SQTR_DISPATCH_TABLE_2
SqTrAsPsTtlFunc_CaseTable:
	.short	SqTrAsPsTtl_Dispatch - SqTrAsPsTtl_Dispatch
	.short	SqTrAsPsTtlFunc_OnTitleOld - SqTrAsPsTtl_Dispatch
	.short	SqTrAsPsTtl_ReturnZero - SqTrAsPsTtl_Dispatch
	.short	SqTrAsPsTtl_ReturnZero - SqTrAsPsTtl_Dispatch
	.short	SqTrAsPsTtl_ReturnZero - SqTrAsPsTtl_Dispatch
	.short	SqTrAsPsTtl_ReturnZero - SqTrAsPsTtl_Dispatch
; CDlike_KeepTitleCaseMap: 14-byte case map of CDlike_ExitModeUnlessKeepTitle, indexed by CURRENT_TITLE - 108: 0 =
;   keep the CD-like play mode (titles 108-111, 114, 115, 118, 119, 121), 1 = CDlike_ExitModeAndRestore (112, 113,
;   116, 117, 120). Basis: readers + bytes.
CDlike_KeepTitleCaseMap:			.incbin "includes/generated/sepaout_config.bin", 0x44, 0xE
SqTrAsPsTtl_CaseF_CaseTable:
	.short	CDlike_ExitModeUnlessKeepTitle_OnKeepTitle - CDlike_ExitModeUnlessKeepTitle_Skip
	.short	CDlike_ExitModeUnlessKeepTitle_Skip - CDlike_ExitModeUnlessKeepTitle_Skip
SqMdlyPlyTtlFunc_CaseTable:
	.short	SqMdlyPlyTtl_Dispatch - SqMdlyPlyTtl_Dispatch
	.short	SqMdlyPlyTtlFunc_OnTitleOld - SqMdlyPlyTtl_Dispatch
	.short	SqMdlyPly_ReturnZero - SqMdlyPlyTtl_Dispatch
	.short	SqMdlyPly_ReturnZero - SqMdlyPlyTtl_Dispatch
	.short	SqMdlyPly_ReturnZero - SqMdlyPlyTtl_Dispatch
	.short	SqMdlyPly_ReturnZero - SqMdlyPlyTtl_Dispatch
DkMdlyPlyTtlFunc_CaseTable:
	.short	DkMdlyPlyTtl_Dispatch - DkMdlyPlyTtl_Dispatch
	.short	DkMdlyPlyTtlFunc_OnTitleOld - DkMdlyPlyTtl_Dispatch
	.short	DkMdlyPly_ReturnZero - DkMdlyPlyTtl_Dispatch
	.short	DkMdlyPly_ReturnZero - DkMdlyPlyTtl_Dispatch
	.short	DkMdlyPly_ReturnZero - DkMdlyPlyTtl_Dispatch
	.short	DkMdlyPly_ReturnZero - DkMdlyPlyTtl_Dispatch
; DkMdlyPly_BitMaskByIndex: 16 x u16 single-bit masks, entry n = 1 << n; DkMdlyPly_SendAudioCmd ANDs each with WA and
;   returns HL = the index of the lowest set bit of WA (16 when none). Basis: readers + bytes.
DkMdlyPly_BitMaskByIndex:			.incbin "includes/generated/sepaout_config.bin", 0x6E, 0x20
; DkMdlyPly_PartIndexTable: 32 x u16 part numbers 0..31 (entry i = i) through which DkMdlyPly_CheckState walks the
;   parts: the entry is passed to SndParam_LookupViaEncode with BC = 0x401 and, on a match with the lowest set bit of
;   the mask (DkMdlyPly_SendAudioCmd), written to PART_SELECT. Basis: readers + bytes.
DkMdlyPly_PartIndexTable:			.incbin "includes/generated/sepaout_config.bin", 0x8E, 0x40
DisplayMode_DispatchEvents_CaseTable:
	.short	DisplayMode_BatchEventSend - DisplayMode_BatchEventSend
	.short	DisplayMode_DispatchEvents_OnTitleDpdoc - DisplayMode_BatchEventSend
	.short	DisplayMode_DispatchEvents_OnTitleDppd - DisplayMode_BatchEventSend
	.short	DisplayMode_DispatchEvents_OnTitleDpsmflyr - DisplayMode_BatchEventSend
	.short	DisplayMode_DispatchEvents_OnTitleDpmdlysmf - DisplayMode_BatchEventSend
	.short	DisplayMode_DispatchEvents_OnTitleDpmdlydoc - DisplayMode_BatchEventSend
	.short	DisplayMode_DispatchEvents_OnTitleDpmdlypd - DisplayMode_BatchEventSend
DpMdlyDocTtlFunc_CaseTable:
	.short	DpMdlyDocTtl_Dispatch - DpMdlyDocTtl_Dispatch
	.short	DpMdlyDocTtlFunc_OnTitleOld - DpMdlyDocTtl_Dispatch
	.short	DpMdlyDoc_ReturnZero - DpMdlyDocTtl_Dispatch
	.short	DpMdlyDoc_ReturnZero - DpMdlyDocTtl_Dispatch
	.short	DpMdlyDoc_ReturnZero - DpMdlyDocTtl_Dispatch
	.short	DpMdlyDoc_ReturnZero - DpMdlyDocTtl_Dispatch
DpMdlyPdTtlFunc_CaseTable:
	.short	DpMdlyPdTtl_Dispatch - DpMdlyPdTtl_Dispatch
	.short	DpMdlyPdTtlFunc_OnTitleOld - DpMdlyPdTtl_Dispatch
	.short	DpMdlyPd_ReturnZero - DpMdlyPdTtl_Dispatch
	.short	DpMdlyPd_ReturnZero - DpMdlyPdTtl_Dispatch
	.short	DpMdlyPd_ReturnZero - DpMdlyPdTtl_Dispatch
	.short	DpMdlyPd_ReturnZero - DpMdlyPdTtl_Dispatch
DpMdlySmfTtlFunc_CaseTable:
	.short	DpMdlySmfTtl_Dispatch - DpMdlySmfTtl_Dispatch
	.short	DpMdlySmfTtlFunc_OnTitleOld - DpMdlySmfTtl_Dispatch
	.short	DpMdlySmf_ReturnZero - DpMdlySmfTtl_Dispatch
	.short	DpMdlySmf_ReturnZero - DpMdlySmfTtl_Dispatch
	.short	DpMdlySmf_ReturnZero - DpMdlySmfTtl_Dispatch
	.short	DpMdlySmf_ReturnZero - DpMdlySmfTtl_Dispatch
DpMdlySmfLyrTtlFunc_CaseTable:
	.short	DpMdlySmfLyrTtl_Dispatch - DpMdlySmfLyrTtl_Dispatch
	.short	DpMdlySmfLyrTtlFunc_OnTitleOld - DpMdlySmfLyrTtl_Dispatch
	.short	DpMdlySmfLyr_ReturnZero - DpMdlySmfLyrTtl_Dispatch
	.short	DpMdlySmfLyrTtlFunc_OnTitleActivate - DpMdlySmfLyrTtl_Dispatch
	.short	DpMdlySmfLyr_ReturnZero - DpMdlySmfLyrTtl_Dispatch
	.short	DpMdlySmfLyr_ReturnZero - DpMdlySmfLyrTtl_Dispatch
NameGetFuncCall_Dispatch_Str_Fmt2d_Fmts:	.incbin "includes/generated/sepaout_config.bin", 0x10C, 0xA
NameGetFuncCall_Dispatch_Str_FILE_Fmt2d_Fmts:	.incbin "includes/generated/sepaout_config.bin", 0x116, 0xC
NameGetFuncCall_Dispatch_Str_Fmt3d_Fmts:	.incbin "includes/generated/sepaout_config.bin", 0x122, 0x8
NameGetFuncCall_Dispatch_Str_Fmt2d_Fmts_2:	.incbin "includes/generated/sepaout_config.bin", 0x12A, 0x8
NameGetFuncCall_Dispatch_Str_Fmt2d_Fmts_3:	.incbin "includes/generated/sepaout_config.bin", 0x132, 0x8
NameGetFuncCall_CaseTable:
	.short	NameGetFuncCall_Dispatch - NameGetFuncCall_Dispatch
	.short	NameGetFuncCall_OnGetDiskFileName - NameGetFuncCall_Dispatch
	.short	NameGetFuncCall_OnGetSmfFileName - NameGetFuncCall_Dispatch
	.short	NameGetFuncCall_OnGetSmfSongName - NameGetFuncCall_Dispatch
	.short	NameGetFunc_Entry - NameGetFuncCall_Dispatch
	.short	NameGetFuncCall_OnGetDocSongName - NameGetFuncCall_Dispatch
	.short	NameGetFuncCall_OnGetDocFileNo - NameGetFuncCall_Dispatch
	.short	NameGetFuncCall_OnGetPdSongName - NameGetFuncCall_Dispatch
	.short	NameGetFuncCall_OnGetPdFileNo - NameGetFuncCall_Dispatch
	.short	NameGetFunc_Entry - NameGetFuncCall_Dispatch
	.short	NameGetFunc_Entry - NameGetFuncCall_Dispatch
	.short	NameGetFunc_Entry - NameGetFuncCall_Dispatch
	.short	NameGetFuncCall_OnGetLyricsSongName - NameGetFuncCall_Dispatch
	.short	NameGetFuncCall_OnGetComposerName - NameGetFuncCall_Dispatch
DpDoc_CaseA_CaseTable:
	.short	DpDoc_CaseB - DpDoc_CaseB
	.short	DpDoc_CaseC - DpDoc_CaseB
	.short	DpDoc_CaseD - DpDoc_CaseB
	.short	DpDocTtl_ReturnZero - DpDoc_CaseB
	.short	DpDoc_CaseE - DpDoc_CaseB
	.short	DpDocTtl_ReturnZero - DpDoc_CaseB
	.short	DpDocTtl_ReturnZero - DpDoc_CaseB
	.short	DpDocTtl_ReturnZero - DpDoc_CaseB
	.short	DpDocTtlFunc_OnMic - DpDoc_CaseB
	.short	DpDocTtlFunc_OnMixer - DpDoc_CaseB
DpDocTtlFunc_CaseTable:
	.short	DpDocTtl_Dispatch - DpDocTtl_Dispatch
	.short	DpDocTtlFunc_OnTitleOld - DpDocTtl_Dispatch
	.short	DpDocTtl_ReturnZero - DpDocTtl_Dispatch
	.short	DpDocTtl_ReturnZero - DpDocTtl_Dispatch
	.short	DpDocTtl_ReturnZero - DpDocTtl_Dispatch
	.short	DpDocTtl_ReturnZero - DpDocTtl_Dispatch
DpPd_CaseA_CaseTable:
	.short	DpPd_CaseB - DpPd_CaseB
	.short	DpPd_CaseC - DpPd_CaseB
	.short	DpPd_CaseD - DpPd_CaseB
	.short	DpPdTtl_ReturnZero - DpPd_CaseB
	.short	DpPd_CaseE - DpPd_CaseB
	.short	DpPdTtl_ReturnZero - DpPd_CaseB
	.short	DpPdTtl_ReturnZero - DpPd_CaseB
	.short	DpPdTtl_ReturnZero - DpPd_CaseB
	.short	DpPdTtlFunc_OnMic - DpPd_CaseB
	.short	DpPdTtlFunc_OnMixer - DpPd_CaseB
DpPdTtlFunc_CaseTable:
	.short	DpPdTtl_Dispatch - DpPdTtl_Dispatch
	.short	DpPdTtlFunc_OnTitleOld - DpPdTtl_Dispatch
	.short	DpPdTtl_ReturnZero - DpPdTtl_Dispatch
	.short	DpPdTtl_ReturnZero - DpPdTtl_Dispatch
	.short	DpPdTtl_ReturnZero - DpPdTtl_Dispatch
	.short	DpPdTtl_ReturnZero - DpPdTtl_Dispatch
DpSmf_CaseA_CaseTable:
	.short	DpSmf_CaseB - DpSmf_CaseB
	.short	DpSmf_CaseC - DpSmf_CaseB
	.short	DpSmf_CaseD - DpSmf_CaseB
	.short	DpSmfTtl_ReturnZero - DpSmf_CaseB
	.short	DpSmf_CaseE - DpSmf_CaseB
	.short	DpSmfTtl_ReturnZero - DpSmf_CaseB
	.short	DpSmfTtl_ReturnZero - DpSmf_CaseB
	.short	DpSmfTtl_ReturnZero - DpSmf_CaseB
	.short	DpSmfTtlFunc_OnMic - DpSmf_CaseB
	.short	DpSmfTtlFunc_OnMixer - DpSmf_CaseB
DpSmfTtlFunc_CaseTable:
	.short	DpSmfTtl_Dispatch - DpSmfTtl_Dispatch
	.short	DpSmfTtlFunc_OnTitleOld - DpSmfTtl_Dispatch
	.short	DpSmfTtl_ReturnZero - DpSmfTtl_Dispatch
	.short	DpSmfTtl_ReturnZero - DpSmfTtl_Dispatch
	.short	DpSmfTtl_ReturnZero - DpSmfTtl_Dispatch
	.short	DpSmfTtl_ReturnZero - DpSmfTtl_Dispatch
DpSmfLyrTtlFunc_CaseTable:
	.short	DpSmfLyrTtl_Dispatch - DpSmfLyrTtl_Dispatch
	.short	DpSmfLyrTtlFunc_OnTitleOld - DpSmfLyrTtl_Dispatch
	.short	SeqStep_ReturnZero - DpSmfLyrTtl_Dispatch
	.short	DpSmfLyrTtlFunc_OnTitleActivate - DpSmfLyrTtl_Dispatch
	.short	SeqStep_ReturnZero - DpSmfLyrTtl_Dispatch
	.short	SeqStep_ReturnZero - DpSmfLyrTtl_Dispatch
SqTrSelTtlFunc_CaseTable:
	.short	SqTrSelTtl_Dispatch - SqTrSelTtl_Dispatch
	.short	SqTrSelTtlFunc_OnTitleOld - SqTrSelTtl_Dispatch
	.short	SqTrSelTtl_ReturnZero - SqTrSelTtl_Dispatch
	.short	SqTrSelTtl_ReturnZero - SqTrSelTtl_Dispatch
	.short	SqTrSelTtl_ReturnZero - SqTrSelTtl_Dispatch
	.short	SqTrSelTtl_ReturnZero - SqTrSelTtl_Dispatch
; SqStepTtlFunc_Methods: The TT_SQSTEP title's 4-entry DirmdEmulator method vector: [0] Display_InitGraphicsAndScreen
;   (draw), [1] Display_CallConditionalCompare (EVT_HIDE), [2] Display_CallPollAudioUpdate, [3] SqTrSel_CaseA. Basis:
;   readers + bytes -- SqStepTtlFunc copies it to the stack and calls DirmdEmulator, like SeMenuTitleFunc_Methods /
;   DirmdTitle_EmulatorMethods.
SqStepTtlFunc_Methods:				.incbin "includes/generated/sepaout_config.bin", 0x1CE, 0x10
DemoStyleTtlFunc_CaseTable:
	.short	DemoStyle_DispatchTable - DemoStyle_DispatchTable
	.short	DemoStyleTtlFunc_Exit - DemoStyle_DispatchTable
	.short	DemoStyleTtlFunc_Exit - DemoStyle_DispatchTable
	.short	DemoStyleTtlFunc_Exit - DemoStyle_DispatchTable
	.short	DemoStyleTtlFunc_Exit - DemoStyle_DispatchTable
	.short	DemoStyleTtlFunc_Exit - DemoStyle_DispatchTable
DemoSoundTtlFunc_CaseTable:
	.short	DemoSound_DispatchTable - DemoSound_DispatchTable
	.short	DemoSoundTtlFunc_Exit - DemoSound_DispatchTable
	.short	DemoSoundTtlFunc_Exit - DemoSound_DispatchTable
	.short	DemoSoundTtlFunc_Exit - DemoSound_DispatchTable
	.short	DemoSoundTtlFunc_Exit - DemoSound_DispatchTable
	.short	DemoSoundTtlFunc_Exit - DemoSound_DispatchTable
DemoRhyTtlFunc_CaseTable:
	.short	DemoRhythm_DispatchTable - DemoRhythm_DispatchTable
	.short	DemoRhyTtlFunc_Exit - DemoRhythm_DispatchTable
	.short	DemoRhyTtlFunc_Exit - DemoRhythm_DispatchTable
	.short	DemoRhyTtlFunc_Exit - DemoRhythm_DispatchTable
	.short	DemoRhyTtlFunc_Exit - DemoRhythm_DispatchTable
	.short	DemoRhyTtlFunc_Exit - DemoRhythm_DispatchTable
MiddleFuncCall_CaseTable:
	.short	MiddleFuncCall_DispatchData - MiddleFuncCall_DispatchData
	.short	MiddleFuncCall_OnSongNameSet - MiddleFuncCall_DispatchData
	.short	SqTrSel_CaseC - MiddleFuncCall_DispatchData
	.short	SqTrSel_CaseC - MiddleFuncCall_DispatchData
	.short	MiddleFuncCall_OnTrAsTrackInc - MiddleFuncCall_DispatchData
	.short	MiddleFuncCall_OnTrAsTrackDec - MiddleFuncCall_DispatchData
	.short	MiddleFuncCall_OnTrAsPartInc - MiddleFuncCall_DispatchData
	.short	MiddleFuncCall_OnTrAsPartDec - MiddleFuncCall_DispatchData
	.short	MiddleFuncCall_OnTrAsPageInc - MiddleFuncCall_DispatchData
	.short	MiddleFuncCall_OnTrAsPageDec - MiddleFuncCall_DispatchData
	.short	MiddleFuncCall_OnAmdCall - MiddleFuncCall_DispatchData
	.short	MiddleFuncCall_OnDirectPlayMute - MiddleFuncCall_DispatchData
	.short	MiddleFuncCall_OnTrackMidiCall - MiddleFuncCall_DispatchData
SongBankLookup_BuildAudioCmd_Str_Fmt3d_FmtPct:	.incbin "includes/generated/sepaout_config.bin", 0x21C, 0x6
; Demo_SongViewIdTable: 18 x u32 NAKA view ids of the demo song selectors DemoSong0..DemoSong17 (0xE10001-0xE10006,
;   0xE20001-0xE20006, 0xE30001-0xE30006), indexed by DEMO_ACTIVE_ENTRY; SeqInit_PostDispatchEvent sends
;   EVT_SET_SELECTED 1 to the entry's view. Basis: readers + bytes.
Demo_SongViewIdTable:		.incbin "includes/generated/sepaout_config.bin", 0x222, 0x48
SqTrSel_CaseG_CaseTable:
	.short	SqTrSel_CaseG_JumpTable - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_OnTitleDpdoc - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_OnTitleDppd - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_JumpTable - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_OnTitleDpMdlySmf - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_OnTitleDpMdlyDoc - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_OnTitleDpMdlyPd - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_OnTitleDpMdlySmfLyr - SqTrSel_CaseG_JumpTable
Yoko_ApFunctionTable_127:			.incbin "includes/generated/sepaout_config.bin", 0x27A, 0xBC
Yoko_ApFunctionTable_427:			.incbin "includes/generated/sepaout_config.bin", 0x336, 0x4

; SepaOut_FormatData_Tail is at offset 263 within the C data blob
; (referenced by extensions/extension_data.s)
.set SepaOut_FormatData_Tail, SepaOut_Config_0 + 263
