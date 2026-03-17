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
SepaOut_Config_0:
	.incbin "includes/generated/sepaout_config.bin"

; SepaOut_FormatData_Tail is at offset 263 within the C data blob
; (referenced by extensions/extension_data.s)
.set SepaOut_FormatData_Tail, SepaOut_Config_0 + 263
