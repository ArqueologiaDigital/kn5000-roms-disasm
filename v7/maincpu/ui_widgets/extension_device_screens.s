
; Extension Device Diagnostic & Config screens (106 widgets, 14740 bytes)
; Source: maincpu/ui_widgets/naka_extension_device.c (C struct with named fields)
NakaInst_ExtDevice_Screens:
	.incbin "includes/generated/naka_extension_device.bin", 0, 0x3552
SoundParam_EncoderMappingData:
	.incbin "includes/generated/naka_extension_device.bin", 0x3552, 0x30E
EffectMode_DispatchTable:
	.incbin "includes/generated/naka_extension_device.bin", 0x3860, 0x90
ENCODER_HANDLER_TABLE:
	.incbin "includes/generated/naka_extension_device.bin", 0x38F0, 0x80
ENCODER_LUT_MODWHEEL:
	.incbin "includes/generated/naka_extension_device.bin", 0x3970, 0x24
; External label offsets within the binary blob above.
