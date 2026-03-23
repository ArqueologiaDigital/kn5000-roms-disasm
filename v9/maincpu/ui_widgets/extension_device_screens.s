
; Extension Device Diagnostic & Config screens (106 widgets, 14740 bytes)
; Source: maincpu/ui_widgets/naka_extension_device.c (C struct with named fields)
NakaInst_ExtDevice_Screens:
	.incbin "includes/generated/naka_extension_device.bin"

; External label offsets within the binary blob above.
	.equ SoundParam_EncoderMappingData, NakaInst_ExtDevice_Screens + 0x3552
	.equ EffectMode_DispatchTable, NakaInst_ExtDevice_Screens + 0x3860
	.equ ENCODER_HANDLER_TABLE, NakaInst_ExtDevice_Screens + 0x38F0
	.equ ENCODER_LUT_MODWHEEL, NakaInst_ExtDevice_Screens + 0x3970
