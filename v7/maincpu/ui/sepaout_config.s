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
	.incbin "includes/generated/sepaout_config.bin"

; SepaOut_FormatData_Tail is at offset 263 within the C data blob
; (referenced by extensions/extension_data.s)
.set SepaOut_FormatData_Tail, SepaOut_Config_0 + 263
