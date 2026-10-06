; =============================================================================
; SepaOut Config & Resource Info Handler Offsets
; RESOURCE_INFO_HANDLER_OFFSETS dispatch table and SepaOut_* layout/config data
; Extracted from kn5000_v10_program.s
; =============================================================================

RESOURCE_INFO_HANDLER_OFFSETS:
	; Precomputed relative offsets (identical in v7 and v9)
	.short	RESOURCE_INFO_HANDLERS - RESOURCE_INFO_HANDLERS
	.short	ResInfo_GetSRAMBankRange - RESOURCE_INFO_HANDLERS
	.short	ResInfo_GetUserAreaRange - RESOURCE_INFO_HANDLERS
	.short	ResInfo_GetSndParamRange - RESOURCE_INFO_HANDLERS
	.short	ResInfo_GetVoiceBankRange - RESOURCE_INFO_HANDLERS
	.short	ResInfo_GetToneGenRange - RESOURCE_INFO_HANDLERS
	.short	ResInfo_GetFlashBankRange - RESOURCE_INFO_HANDLERS
	.short	ResInfo_GetMspSettingsRange - RESOURCE_INFO_HANDLERS
	.short	ResInfo_GetResourceListPtr - RESOURCE_INFO_HANDLERS
	.short	ResInfo_GetTableDataInfo - RESOURCE_INFO_HANDLERS

; SepaOut configuration data (826 bytes, compiled from sepaout_config.c)
SepaOut_Config_0:
	.incbin "includes/generated/sepaout_config.bin", 0x0, 0x4
SetSepaOutMode_Data:				.incbin "includes/generated/sepaout_config.bin", 0x4, 0x4
SetSepaOutMode_Data_2:				.incbin "includes/generated/sepaout_config.bin", 0x8, 0x4
SetSepaOutMode_Data_3:				.incbin "includes/generated/sepaout_config.bin", 0xC, 0x4
SetSepaOutMode_Data_4:				.incbin "includes/generated/sepaout_config.bin", 0x10, 0x4
SqSngSelTtlFunc_Data:
	.short	SqTrAs_CondCheck - SqTrAs_CondCheck
	.short	SqSngSelTtlFunc_Case3 - SqTrAs_CondCheck
	.short	SqSngName_ReturnZero - SqTrAs_CondCheck
	.short	SqSngName_ReturnZero - SqTrAs_CondCheck
	.short	SqSngName_ReturnZero - SqTrAs_CondCheck
	.short	SqSngName_ReturnZero - SqTrAs_CondCheck
SqSngNameTtlFunc_Data:
	.short	SQTR_DISPATCH_TABLE_1 - SQTR_DISPATCH_TABLE_1
	.short	SqSngNameTtlFunc_Case3 - SQTR_DISPATCH_TABLE_1
	.short	SqTrAs_ReturnZero - SQTR_DISPATCH_TABLE_1
	.short	SqTrAs_ReturnZero - SQTR_DISPATCH_TABLE_1
	.short	SqTrAs_ReturnZero - SQTR_DISPATCH_TABLE_1
	.short	SqTrAs_ReturnZero - SQTR_DISPATCH_TABLE_1
SqTrAsTtlFunc_Data:
	.short	SQTR_DISPATCH_TABLE_2 - SQTR_DISPATCH_TABLE_2
	.short	SQTR_DISPATCH_TABLE_2_CASE1 - SQTR_DISPATCH_TABLE_2
	.short	CDlikeSwTtl_ReturnZero2 - SQTR_DISPATCH_TABLE_2
	.short	SQTR_DISPATCH_TABLE_2_CASE2 - SQTR_DISPATCH_TABLE_2
	.short	CDlikeSwTtl_ReturnZero2 - SQTR_DISPATCH_TABLE_2
	.short	CDlikeSwTtl_ReturnZero2 - SQTR_DISPATCH_TABLE_2
SqTrAsPsTtlFunc_Data:
	.short	SqTrAsPsTtl_Dispatch - SqTrAsPsTtl_Dispatch
	.short	SqTrAsPsTtlFunc_Case3 - SqTrAsPsTtl_Dispatch
	.short	SqTrAsPsTtl_ReturnZero - SqTrAsPsTtl_Dispatch
	.short	SqTrAsPsTtl_ReturnZero - SqTrAsPsTtl_Dispatch
	.short	SqTrAsPsTtl_ReturnZero - SqTrAsPsTtl_Dispatch
	.short	SqTrAsPsTtl_ReturnZero - SqTrAsPsTtl_Dispatch
SetWall_ReturnZero_Data:			.incbin "includes/generated/sepaout_config.bin", 0x44, 0xE
SetWall_ReturnZero_Data_2:
	.short	SqTrAsPsTtl_CaseF_Case0 - SqTrAsPsTtl_CaseF_Skip
	.short	SqTrAsPsTtl_CaseF_Skip - SqTrAsPsTtl_CaseF_Skip
SqMdlyPlyTtlFunc_Data:
	.short	SqMdlyPlyTtl_Dispatch - SqMdlyPlyTtl_Dispatch
	.short	SqMdlyPlyTtlFunc_Case3 - SqMdlyPlyTtl_Dispatch
	.short	SqMdlyPly_ReturnZero - SqMdlyPlyTtl_Dispatch
	.short	SqMdlyPly_ReturnZero - SqMdlyPlyTtl_Dispatch
	.short	SqMdlyPly_ReturnZero - SqMdlyPlyTtl_Dispatch
	.short	SqMdlyPly_ReturnZero - SqMdlyPlyTtl_Dispatch
DkMdlyPlyTtlFunc_Data:
	.short	DkMdlyPlyTtl_Dispatch - DkMdlyPlyTtl_Dispatch
	.short	DkMdlyPlyTtlFunc_Case3 - DkMdlyPlyTtl_Dispatch
	.short	DkMdlyPly_ReturnZero - DkMdlyPlyTtl_Dispatch
	.short	DkMdlyPly_ReturnZero - DkMdlyPlyTtl_Dispatch
	.short	DkMdlyPly_ReturnZero - DkMdlyPlyTtl_Dispatch
	.short	DkMdlyPly_ReturnZero - DkMdlyPlyTtl_Dispatch
DkMdlyPly_SendAudioCmd_Data:			.incbin "includes/generated/sepaout_config.bin", 0x6E, 0x20
DkMdlyPly_HandleResult_Data:			.incbin "includes/generated/sepaout_config.bin", 0x8E, 0x40
DisplayMode_DispatchEvents_Data:
	.short	DisplayMode_BatchEventSend - DisplayMode_BatchEventSend
	.short	DisplayMode_DispatchEvents_Case112 - DisplayMode_BatchEventSend
	.short	DisplayMode_DispatchEvents_Case113 - DisplayMode_BatchEventSend
	.short	DisplayMode_DispatchEvents_Case114 - DisplayMode_BatchEventSend
	.short	DisplayMode_DispatchEvents_Case115 - DisplayMode_BatchEventSend
	.short	DisplayMode_DispatchEvents_Case116 - DisplayMode_BatchEventSend
	.short	DisplayMode_DispatchEvents_Case117 - DisplayMode_BatchEventSend
DpMdlyDocTtlFunc_Data:
	.short	DpMdlyDocTtl_Dispatch - DpMdlyDocTtl_Dispatch
	.short	DpMdlyDocTtlFunc_Case3 - DpMdlyDocTtl_Dispatch
	.short	DpMdlyDoc_ReturnZero - DpMdlyDocTtl_Dispatch
	.short	DpMdlyDoc_ReturnZero - DpMdlyDocTtl_Dispatch
	.short	DpMdlyDoc_ReturnZero - DpMdlyDocTtl_Dispatch
	.short	DpMdlyDoc_ReturnZero - DpMdlyDocTtl_Dispatch
DpMdlyPdTtlFunc_Data:
	.short	DpMdlyPdTtl_Dispatch - DpMdlyPdTtl_Dispatch
	.short	DpMdlyPdTtlFunc_Case3 - DpMdlyPdTtl_Dispatch
	.short	DpMdlyPd_ReturnZero - DpMdlyPdTtl_Dispatch
	.short	DpMdlyPd_ReturnZero - DpMdlyPdTtl_Dispatch
	.short	DpMdlyPd_ReturnZero - DpMdlyPdTtl_Dispatch
	.short	DpMdlyPd_ReturnZero - DpMdlyPdTtl_Dispatch
DpMdlySmfTtlFunc_Data:
	.short	DpMdlySmfTtl_Dispatch - DpMdlySmfTtl_Dispatch
	.short	DpMdlySmfTtlFunc_Case3 - DpMdlySmfTtl_Dispatch
	.short	DpMdlySmf_ReturnZero - DpMdlySmfTtl_Dispatch
	.short	DpMdlySmf_ReturnZero - DpMdlySmfTtl_Dispatch
	.short	DpMdlySmf_ReturnZero - DpMdlySmfTtl_Dispatch
	.short	DpMdlySmf_ReturnZero - DpMdlySmfTtl_Dispatch
DpMdlySmfLyrTtlFunc_Data:
	.short	DpMdlySmfLyrTtl_Dispatch - DpMdlySmfLyrTtl_Dispatch
	.short	DpMdlySmfLyrTtlFunc_Case3 - DpMdlySmfLyrTtl_Dispatch
	.short	DpMdlySmfLyr_ReturnZero - DpMdlySmfLyrTtl_Dispatch
	.short	DpMdlySmfLyrTtlFunc_Case5 - DpMdlySmfLyrTtl_Dispatch
	.short	DpMdlySmfLyr_ReturnZero - DpMdlySmfLyrTtl_Dispatch
	.short	DpMdlySmfLyr_ReturnZero - DpMdlySmfLyrTtl_Dispatch
NameGetFuncCall_Dispatch_Str_Fmt2d_Fmts:	.incbin "includes/generated/sepaout_config.bin", 0x10C, 0xA
NameGetFuncCall_Dispatch_Str_FILE_Fmt2d_Fmts:	.incbin "includes/generated/sepaout_config.bin", 0x116, 0xC
NameGetFuncCall_Dispatch_Str_Fmt3d_Fmts:	.incbin "includes/generated/sepaout_config.bin", 0x122, 0x8
NameGetFuncCall_Dispatch_Str_Fmt2d_Fmts_2:	.incbin "includes/generated/sepaout_config.bin", 0x12A, 0x8
NameGetFuncCall_Dispatch_Str_Fmt2d_Fmts_3:	.incbin "includes/generated/sepaout_config.bin", 0x132, 0x8
NameGetFuncCall_Data:
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
DpDocTtl_Dispatch_Data:
	.short	DpDoc_CaseB - DpDoc_CaseB
	.short	DpDoc_CaseC - DpDoc_CaseB
	.short	DpDoc_CaseD - DpDoc_CaseB
	.short	DpDocTtl_ReturnZero - DpDoc_CaseB
	.short	DpDoc_CaseE - DpDoc_CaseB
	.short	DpDocTtl_ReturnZero - DpDoc_CaseB
	.short	DpDocTtl_ReturnZero - DpDoc_CaseB
	.short	DpDocTtl_ReturnZero - DpDoc_CaseB
	.short	DpDocTtlFunc_Switch2_Case137 - DpDoc_CaseB
	.short	DpDocTtlFunc_Switch2_Case138 - DpDoc_CaseB
DpDocTtlFunc_Data:
	.short	DpDocTtl_Dispatch - DpDocTtl_Dispatch
	.short	DpDocTtlFunc_Case3 - DpDocTtl_Dispatch
	.short	DpDocTtl_ReturnZero - DpDocTtl_Dispatch
	.short	DpDocTtl_ReturnZero - DpDocTtl_Dispatch
	.short	DpDocTtl_ReturnZero - DpDocTtl_Dispatch
	.short	DpDocTtl_ReturnZero - DpDocTtl_Dispatch
DpPdTtl_Dispatch_Data:
	.short	DpPd_CaseB - DpPd_CaseB
	.short	DpPd_CaseC - DpPd_CaseB
	.short	DpPd_CaseD - DpPd_CaseB
	.short	DpPdTtl_ReturnZero - DpPd_CaseB
	.short	DpPd_CaseE - DpPd_CaseB
	.short	DpPdTtl_ReturnZero - DpPd_CaseB
	.short	DpPdTtl_ReturnZero - DpPd_CaseB
	.short	DpPdTtl_ReturnZero - DpPd_CaseB
	.short	DpPdTtlFunc_Switch2_Case137 - DpPd_CaseB
	.short	DpPdTtlFunc_Switch2_Case138 - DpPd_CaseB
DpPdTtlFunc_Data:
	.short	DpPdTtl_Dispatch - DpPdTtl_Dispatch
	.short	DpPdTtlFunc_Case3 - DpPdTtl_Dispatch
	.short	DpPdTtl_ReturnZero - DpPdTtl_Dispatch
	.short	DpPdTtl_ReturnZero - DpPdTtl_Dispatch
	.short	DpPdTtl_ReturnZero - DpPdTtl_Dispatch
	.short	DpPdTtl_ReturnZero - DpPdTtl_Dispatch
DpSmfTtl_Dispatch_Data:
	.short	DpSmf_CaseB - DpSmf_CaseB
	.short	DpSmf_CaseC - DpSmf_CaseB
	.short	DpSmf_CaseD - DpSmf_CaseB
	.short	DpSmfTtl_ReturnZero - DpSmf_CaseB
	.short	DpSmf_CaseE - DpSmf_CaseB
	.short	DpSmfTtl_ReturnZero - DpSmf_CaseB
	.short	DpSmfTtl_ReturnZero - DpSmf_CaseB
	.short	DpSmfTtl_ReturnZero - DpSmf_CaseB
	.short	DpSmfTtlFunc_Switch2_Case137 - DpSmf_CaseB
	.short	DpSmfTtlFunc_Switch2_Case138 - DpSmf_CaseB
DpSmfTtlFunc_Data:
	.short	DpSmfTtl_Dispatch - DpSmfTtl_Dispatch
	.short	DpSmfTtlFunc_Case3 - DpSmfTtl_Dispatch
	.short	DpSmfTtl_ReturnZero - DpSmfTtl_Dispatch
	.short	DpSmfTtl_ReturnZero - DpSmfTtl_Dispatch
	.short	DpSmfTtl_ReturnZero - DpSmfTtl_Dispatch
	.short	DpSmfTtl_ReturnZero - DpSmfTtl_Dispatch
DpSmfLyrTtlFunc_Data:
	.short	DpSmfLyrTtl_Dispatch - DpSmfLyrTtl_Dispatch
	.short	DpSmfLyrTtlFunc_Case3 - DpSmfLyrTtl_Dispatch
	.short	SeqStep_ReturnZero - DpSmfLyrTtl_Dispatch
	.short	DpSmfLyrTtlFunc_Case5 - DpSmfLyrTtl_Dispatch
	.short	SeqStep_ReturnZero - DpSmfLyrTtl_Dispatch
	.short	SeqStep_ReturnZero - DpSmfLyrTtl_Dispatch
SqTrSelTtlFunc_Data:
	.short	SqTrSelTtl_Dispatch - SqTrSelTtl_Dispatch
	.short	SqTrSelTtlFunc_Case3 - SqTrSelTtl_Dispatch
	.short	SqTrSelTtl_ReturnZero - SqTrSelTtl_Dispatch
	.short	SqTrSelTtl_ReturnZero - SqTrSelTtl_Dispatch
	.short	SqTrSelTtl_ReturnZero - SqTrSelTtl_Dispatch
	.short	SqTrSelTtl_ReturnZero - SqTrSelTtl_Dispatch
SqStepTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x1CE, 0x10
DemoStyleTtlFunc_Data:
	.short	DemoStyle_DispatchTable - DemoStyle_DispatchTable
	.short	DemoStyleTtlFunc_Exit - DemoStyle_DispatchTable
	.short	DemoStyleTtlFunc_Exit - DemoStyle_DispatchTable
	.short	DemoStyleTtlFunc_Exit - DemoStyle_DispatchTable
	.short	DemoStyleTtlFunc_Exit - DemoStyle_DispatchTable
	.short	DemoStyleTtlFunc_Exit - DemoStyle_DispatchTable
DemoSoundTtlFunc_Data:
	.short	DemoSound_DispatchTable - DemoSound_DispatchTable
	.short	DemoSoundTtlFunc_Exit - DemoSound_DispatchTable
	.short	DemoSoundTtlFunc_Exit - DemoSound_DispatchTable
	.short	DemoSoundTtlFunc_Exit - DemoSound_DispatchTable
	.short	DemoSoundTtlFunc_Exit - DemoSound_DispatchTable
	.short	DemoSoundTtlFunc_Exit - DemoSound_DispatchTable
DemoRhyTtlFunc_Data:
	.short	DemoRhythm_DispatchTable - DemoRhythm_DispatchTable
	.short	DemoRhyTtlFunc_Exit - DemoRhythm_DispatchTable
	.short	DemoRhyTtlFunc_Exit - DemoRhythm_DispatchTable
	.short	DemoRhyTtlFunc_Exit - DemoRhythm_DispatchTable
	.short	DemoRhyTtlFunc_Exit - DemoRhythm_DispatchTable
	.short	DemoRhyTtlFunc_Exit - DemoRhythm_DispatchTable
MiddleFuncCall_Data:
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
SeqInit_LookupDispatchEntry_Data:		.incbin "includes/generated/sepaout_config.bin", 0x222, 0x48
PlayMode_SendStopEvent_Data:
	.short	SqTrSel_CaseG_JumpTable - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_Case112 - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_Case113 - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_JumpTable - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_Thunk1 - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_Thunk3 - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_Thunk4 - SqTrSel_CaseG_JumpTable
	.short	SqTrSel_CaseG_Thunk2 - SqTrSel_CaseG_JumpTable
Yoko_ApFunctionTable_127:			.incbin "includes/generated/sepaout_config.bin", 0x27A, 0xBC
Yoko_ApFunctionTable_427:			.incbin "includes/generated/sepaout_config.bin", 0x336, 0x4

; SepaOut_FormatData_Tail is at offset 263 within the C data blob
; (referenced by extensions/extension_data.s)
.set SepaOut_FormatData_Tail, SepaOut_Config_0 + 263
