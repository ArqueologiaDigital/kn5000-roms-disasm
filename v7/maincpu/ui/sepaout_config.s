; =============================================================================
; SepaOut Config & Resource Info Handler Offsets
; RESOURCE_INFO_HANDLER_OFFSETS dispatch table and SepaOut_* layout/config data
; Extracted from kn5000_v10_program.s
; =============================================================================

RESOURCE_INFO_HANDLER_OFFSETS:
	; Precomputed relative offsets (identical in v7 and v9)
	.byte 0x00, 0x00, 0x18, 0x00, 0x31, 0x00, 0x73, 0x00, 0x83, 0x00
	.byte 0x9c, 0x00, 0x4a, 0x00, 0xb5, 0x00, 0xce, 0x00, 0x63, 0x00

; SepaOut configuration data (826 bytes, compiled from sepaout_config.c)
SepaOut_Config_0:
	.incbin "includes/generated/sepaout_config.bin", 0x0, 0x4
SetSepaOutMode_Data:				.incbin "includes/generated/sepaout_config.bin", 0x4, 0x4
SetSepaOutMode_Data_2:				.incbin "includes/generated/sepaout_config.bin", 0x8, 0x4
SetSepaOutMode_Data_3:				.incbin "includes/generated/sepaout_config.bin", 0xC, 0x4
SetSepaOutMode_Data_4:				.incbin "includes/generated/sepaout_config.bin", 0x10, 0x4
SqSngSelTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x14, 0xC
SqSngNameTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x20, 0x5
CDlikeSwTtl_SetRecordAndNotify_Data_3:		.incbin "includes/generated/sepaout_config.bin", 0x25, 0x7
SqTrAsTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x2C, 0xC
SqTrAsPsTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x38, 0xC
SetWall_ReturnZero_Data:			.incbin "includes/generated/sepaout_config.bin", 0x44, 0xE
SetWall_ReturnZero_Data_2:			.incbin "includes/generated/sepaout_config.bin", 0x52, 0x4
SqMdlyPlyTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x56, 0xC
DkMdlyPlyTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x62, 0xC
DkMdlyPly_SendAudioCmd_Data:			.incbin "includes/generated/sepaout_config.bin", 0x6E, 0x20
DkMdlyPly_HandleResult_Data:			.incbin "includes/generated/sepaout_config.bin", 0x8E, 0x40
DisplayMode_DispatchEvents_Data:		.incbin "includes/generated/sepaout_config.bin", 0xCE, 0xE
DpMdlyDocTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0xDC, 0xC
DpMdlyPdTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0xE8, 0xC
DpMdlySmfTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0xF4, 0xC
DpMdlySmfLyrTtlFunc_Data:			.incbin "includes/generated/sepaout_config.bin", 0x100, 0xC
NameGetFuncCall_Dispatch_Str_Fmt2d_Fmts:	.incbin "includes/generated/sepaout_config.bin", 0x10C, 0xA
NameGetFuncCall_Dispatch_Str_FILE_Fmt2d_Fmts:	.incbin "includes/generated/sepaout_config.bin", 0x116, 0xC
NameGetFuncCall_Dispatch_Str_Fmt3d_Fmts:	.incbin "includes/generated/sepaout_config.bin", 0x122, 0x8
NameGetFuncCall_Dispatch_Str_Fmt2d_Fmts_2:	.incbin "includes/generated/sepaout_config.bin", 0x12A, 0x8
NameGetFuncCall_Dispatch_Str_Fmt2d_Fmts_3:	.incbin "includes/generated/sepaout_config.bin", 0x132, 0x8
NameGetFuncCall_Data:				.incbin "includes/generated/sepaout_config.bin", 0x13A, 0x1C
DpDocTtl_Dispatch_Data:				.incbin "includes/generated/sepaout_config.bin", 0x156, 0x14
DpDocTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x16A, 0xC
DpPdTtl_Dispatch_Data:				.incbin "includes/generated/sepaout_config.bin", 0x176, 0x14
DpPdTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x18A, 0xC
DpSmfTtl_Dispatch_Data:				.incbin "includes/generated/sepaout_config.bin", 0x196, 0x14
DpSmfTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x1AA, 0xC
DpSmfLyrTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x1B6, 0xC
SqTrSelTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x1C2, 0xC
SqStepTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x1CE, 0x10
DemoStyleTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x1DE, 0xC
DemoSoundTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x1EA, 0xC
DemoRhyTtlFunc_Data:				.incbin "includes/generated/sepaout_config.bin", 0x1F6, 0xC
MiddleFuncCall_Data:				.incbin "includes/generated/sepaout_config.bin", 0x202, 0x1A
SongBankLookup_BuildAudioCmd_Str_Fmt3d_FmtPct:	.incbin "includes/generated/sepaout_config.bin", 0x21C, 0x6
SeqInit_LookupDispatchEntry_Data:		.incbin "includes/generated/sepaout_config.bin", 0x222, 0x48
PlayMode_SendStopEvent_Data:			.incbin "includes/generated/sepaout_config.bin", 0x26A, 0x10
Yoko_ApFunctionTable_127:			.incbin "includes/generated/sepaout_config.bin", 0x27A, 0xBC
Yoko_ApFunctionTable_427:			.incbin "includes/generated/sepaout_config.bin", 0x336, 0x4

; SepaOut_FormatData_Tail is at offset 263 within the C data blob
; (referenced by extensions/extension_data.s)
.set SepaOut_FormatData_Tail, SepaOut_Config_0 + 263
