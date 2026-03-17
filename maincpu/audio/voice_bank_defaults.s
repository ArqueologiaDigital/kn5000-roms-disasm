; =============================================================================
; Voice Bank Default Data - Header, slot templates, bank name strings
; =============================================================================
; Used by Voice_InitBankTables and Voice_InitBankData to initialize
; voice bank SRAM with factory defaults.

Voice_BankHeaderDefaults:
	.byte 0x48, 0x00, 0x4b, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x5a, 0x5a, 0x5a, 0x00, 0x00
	.byte 0x20, 0x00, 0x10, 0x00, 0x1e, 0x00, 0x00, 0x01
	.byte 0x39, 0x00, 0x0c, 0x00, 0xc0, 0x03, 0xc0, 0x03

Voice_BankSlotZeroInit:
	.zero 16

Voice_SlotTemplate:
	nop
	.long 0xFFFFFFFF
	.byte 0x87
	.zero 248
	.byte 0x00, 0x87

BLOCK_OF_64_ZEROES:
	.zero 64

HEADER__COMPILE_BANKS:
	.ascii " Compile Bank 1  Compile Bank 2                                 "

HEADER__USER_BANKS:
	.ascii "  User Bank 1     User Bank 2                                   "

