; =============================================================================
; Flash & Floppy Handlers
; =============================================================================
;
; Flash memory sector write routines, floppy disk note event
; loading, and FDC format UI. Bridges storage hardware to the
; file I/O subsystem.
; =============================================================================

FlashWrite_BlockHandler_Table:
	.long FlashWrite_BlockData_Type0
	.long FlashWrite_BlockData_Type1
	.long FlashWrite_BlockData_Type0
	.long FlashWrite_BlockData_Type1
	.long FlashWrite_BlockData_Type0
	.long FlashWrite_BlockData_Type1
	.long FlashWrite_BlockData_Type0
	.long FlashWrite_BlockData_Type1
	.long FlashWrite_BlockData_Type2
	.long FlashRead_BlockHandler_Table
	.long FlashWrite_BlockData_Type2
	.long FlashRead_BlockHandler_Table
	.long FlashWrite_BlockData_Type3
	.long FlashWrite_BlockRef_Type3
	.long FlashWrite_BlockData_Type4
	.long FlashWrite_BlockRef_Type4
	.long FlashWrite_BlockData_Type5
	.long FlashWrite_BlockRef_Type5
	.long FlashWrite_BlockData_Type4
	.long FlashWrite_BlockRef_Type4
	.long FlashWrite_BlockData_Type6
	.long FlashWrite_BlockRef_Type6
	.long FlashWrite_BlockData_Type6
	.long FlashWrite_BlockRef_Type6
FlashWrite_BlockData_Type0:
	nop
	ldwio	97, 0xff06
	nop
	ldb	w, 12
	pushw	2
	ldwio	98, 0xff06
	nop
	ldb	w, 100
	decf
	push	sr
	halt
	pushw	1635
	swi	7
	nop
	ldb	w, 187
	retd	2
	nop
	ldwio	100, 0xff06
	nop
	ldb	w, 20
	ccf
	push	sr
	nop
	ldwio	101, 0xff06
	nop
	ldb	w, 107
	push_a
	pop	sr
FlashWrite_BlockData_Type1:
	.incbin "includes/generated/v7_transplant_FlashWrite_BlockData_Type1.bin"
FlashWrite_BlockData_Type2:
	nop
	ldwio	97, 0xff06
	nop
	ldb	w, 12
	.byte 0x0b
	push	sr
FlashRead_BlockData_Field2:
	nop
	ldwio	98, 0xff06
	nop
	ldb	w, 100
	decf
	push	sr
FlashRead_BlockData_Field3:
	nop
	ldwio	99, 0xff06
	nop
	ldb	w, 188
	.byte 0x0f
	push	sr
FlashRead_BlockData_Field4:
	nop
	ldwio	100, 0xff06
	nop
	ldb	w, 20
	ccf
	push	sr
FlashRead_BlockData_Field5:
	halt
	pushw	1637
	swi	7
	nop
	ldb	w, 107
	push_a
	push	sr
	nop
FlashRead_BlockData_Field6:
	nop
	.byte 0x0a
	.long 0x00ff0666	; TmFlashWrite_Block3 (data record pointer)
	ldb	w, 196
	ex_ff
	push	sr
FlashRead_BlockHandler_Table:
	.long FlashWrite_BlockData_Type2
	.long FlashWrite_BlockData_Type2
	.long FlashRead_BlockData_Field2
	.long FlashRead_BlockData_Field3
	.long FlashRead_BlockData_Field4
	.long FlashRead_BlockData_Field5
	.long FlashRead_BlockData_Field6
	.long FlashRead_BlockData_Field7
	.long FlashRead_BlockData_Field8
FlashWrite_BlockData_Type3:
	.incbin "includes/generated/v7_transplant_FlashWrite_BlockData_Type3.bin"
FlashWrite_BlockRef_Type3:
	.incbin "includes/generated/v7_transplant_FlashWrite_BlockRef_Type3.bin"
FlashWrite_BlockData_Type4:
	nop
	ldwio	97, 0xff06
	nop
	ldb	w, 12
	pushw	2
	ldwio	98, 0xff06
	nop
	ldb	w, 100
	decf
	push	sr
	nop
	ldwio	99, 0xff06
	nop
	ldb	w, 188
	retd	2
	ldwio	100, 0xff06
	nop
	ldb	w, 20
	ccf
	push	sr
FlashWrite_BlockRef_Type4:
	.incbin "includes/generated/v7_transplant_FlashWrite_BlockRef_Type4.bin"
FlashWrite_BlockData_Type5:
	nop
	ldwio	97, 0xff06
	nop
	ldb	w, 12
	pushw	1282
	pushw	1634
	swi	7
	nop
	ldb	w, 99
	decf
	push	sr
	nop
	halt
	pushw	1635
	swi	7
	nop
	ldb	w, 187
	retd	2
	nop
	ldwio	100, 0xff06
	nop
	ldb	w, 19
	ccf
	pop	sr
FlashWrite_BlockRef_Type5:
	.incbin "includes/generated/v7_transplant_FlashWrite_BlockRef_Type5.bin"
FlashWrite_BlockData_Type6:
	.incbin "includes/generated/v7_transplant_FlashWrite_BlockData_Type6.bin"
FlashWrite_BlockRef_Type6:
	.incbin "includes/generated/v7_transplant_FlashWrite_BlockRef_Type6.bin"
DrumDetailEdit_Menu_Table:
	.long DrumDetailEdit_Entry_01
	.long DrumDetailEdit_Entry_01
	.long DrumDetailEdit_Entry_03
	.long DrumDetailEdit_Entry_07
	.long DrumDetailEdit_Entry_04
	.long DrumDetailEdit_Entry_08
	.long DrumDetailEdit_Entry_05
	.long DrumDetailEdit_Entry_09
	.long Data_Dispatch_Entry
	.long Data_Dispatch_Entry
	.long Data_Dispatch_Entry
	.long Data_Dispatch_Entry_0x39
	.long Data_Dispatch_Entry_0x39
	.long Data_Dispatch_Entry_0x45
	.long DrumDetailEdit_Entry_02
	.long DrumDetailEdit_Entry_06
	.byte 0x23, 0x05, 0x10, 0x7f, 0x00, 0x23, 0x05, 0x63
	.byte 0xa3, 0x0a, 0x23, 0x05, 0x61, 0xc2, 0x0a, 0x23
	.byte 0x05, 0x21, 0xbb, 0x10, 0x23, 0x05, 0x5f, 0xda
	.byte 0x10, 0x1c, 0x16, 0x58, 0x00, 0x08, 0x00, 0x44
	.ascii "RUM DETAIL EDIT"
	.byte 0x06
	.byte 0x08, 0x7c, 0x0b
	.byte 0x54, 0x30, 0x4e, 0x45
	.byte 0x06
	.byte 0x0c, 0x81, 0x0b
	ld	xix, 0x4d414e59
	.byte 0x49, 0x43, 0x53, 0x06, 0x0d, 0x97, 0x0b, 0x41
	.ascii "MPLITUDE"
	.byte 0x06, 0x05, 0xb8, 0x0b, 0x10, 0x06, 0x05, 0xdf
	.byte 0x0b, 0x11, 0x17, 0x19, 0x8e, 0x00, 0x65, 0x00
	.ascii "TOTAL KIT PARAMETER"
	.byte 0x06, 0x05, 0xa8, 0x11, 0x10
	.byte 0x06, 0x05, 0xcf, 0x11, 0x11, 0x06, 0x0e, 0xbe
	.byte 0x11
	.ascii "C0NTR0LLER"
	.byte 0x06, 0x0a, 0xd7, 0x11, 0x46
	.byte 0x49, 0x4c, 0x54, 0x45, 0x52
	.byte 0x06, 0x17, 0x15
	.byte 0x1e
	.ascii "DRUM S0UND NAMING "
	.byte 0x11, 0x09, 0x0a, 0x0f, 0x00
	.byte 0x37, 0x00, 0x31, 0x01, 0x8f, 0x00, 0x09, 0x0a
	.byte 0xa3, 0x00, 0xba, 0x00, 0x35, 0x01, 0xcf, 0x00
	.byte 0x09, 0x0a, 0xa5, 0x00, 0xbc, 0x00, 0x33, 0x01
	.byte 0xcd, 0x00, 0x17, 0x0b, 0x3b, 0x00, 0x3e, 0x00
	.byte 0x54, 0x4f, 0x55, 0x43, 0x48
	.byte 0x17, 0x0b, 0x6b
	.byte 0x00, 0x3e, 0x00
	ld	xhl, 0x45565255
	.byte 0x17, 0x0b, 0x54, 0x00, 0xd1, 0x00, 0x54, 0x4f
	.byte 0x55, 0x43, 0x48, 0x17, 0x0b, 0x7d, 0x00, 0xd1
	.byte 0x00
	ld	xhl, 0x45565255
	.byte 0x06, 0x05
	.byte 0x1c, 0x22, 0x8d, 0x06, 0x05, 0x21, 0x22, 0x8d
	.byte 0x06, 0x05, 0xac, 0x23, 0x8e, 0x06, 0x05, 0xb1
	.byte 0x23, 0x8e, 0x22, 0x0a, 0x0b, 0x00, 0x38, 0x00
	.byte 0x9c, 0x00, 0x8a, 0x00, 0x22, 0x0a, 0x59, 0x00
	.byte 0xda, 0x00, 0x6e, 0x00, 0xee, 0x00, 0x22, 0x0a
	.byte 0x81, 0x00, 0xda, 0x00, 0x96, 0x00, 0xee, 0x00
	.byte 0x01, 0x0a, 0x0b, 0x00, 0x4a, 0x00, 0x9c, 0x00
	.byte 0x4a, 0x00, 0x01, 0x0a, 0x0b, 0x00, 0x6a, 0x00
	.byte 0x9c, 0x00, 0x6a, 0x00, 0x01, 0x0a, 0x59, 0x00
	.byte 0xe4, 0x00, 0x6e, 0x00, 0xe4, 0x00, 0x01, 0x0a
	.long Pad_NakaExternal_Block4
	.long NakaData_ExternalPadBlock_A
	.byte 0x02, 0x0a, 0x2e, 0x00, 0x38, 0x00, 0x2e, 0x00
	.byte 0x8a, 0x00, 0x05, 0x0a, 0x16, 0x01, 0x43, 0x00
	.byte 0x32, 0x01, 0x5c, 0x00, 0x06, 0x13, 0x60, 0x1d
	.byte 0x10
	.ascii "KEY OFF MODE :"
	.byte 0x17
	.byte 0x0b, 0x18, 0x01, 0xc2, 0x00, 0x54, 0x4f, 0x55
	.byte 0x43, 0x48, 0x17, 0x09, 0x09, 0x00, 0xcf, 0x00
	.byte 0x41, 0x54, 0x4b, 0x17, 0x0c, 0x27, 0x00, 0xcf
	.byte 0x00
	.ascii "DECAY1"
	.byte 0x17
	.byte 0x0b, 0x51, 0x00, 0xcf, 0x00, 0x53, 0x55, 0x53
	.byte 0x54, 0x31, 0x17, 0x0c, 0x7b, 0x00, 0xcf, 0x00
	.ascii "DECAY2"
	.byte 0x17, 0x0b
	.byte 0xa5, 0x00, 0xcf, 0x00
	.byte 0x53, 0x55, 0x53, 0x54
	.byte 0x32, 0x17, 0x0d, 0xcf, 0x00, 0xcf, 0x00, 0x52
	.ascii "ELEASE"
	.byte 0x17, 0x0c
	.byte 0x18, 0x01, 0xcf, 0x00
	.byte 0x41, 0x54, 0x54, 0x41
	.byte 0x43, 0x4b, 0x07, 0x05, 0x1a, 0x24, 0x12, 0x07
	.byte 0x05, 0x1f, 0x24, 0x12, 0x07, 0x05, 0x24, 0x24
	.byte 0x12, 0x07, 0x05, 0x29, 0x24, 0x12, 0x07, 0x05
	.byte 0x2e, 0x24, 0x12, 0x07, 0x05, 0x34, 0x24, 0x12
	.byte 0x07, 0x05, 0x3e, 0x24, 0x12, 0x09, 0x0a, 0x03
	.byte 0x00, 0xcb, 0x00, 0xfd, 0x00, 0xe8, 0x00, 0x09
	.byte 0x0a, 0x14, 0x01, 0xcb, 0x00, 0x3f, 0x01, 0xe8
	.byte 0x00, 0x01, 0x0a, 0x03, 0x00, 0xd9, 0x00, 0xfd
	.byte 0x00, 0xd9, 0x00, 0x01, 0x0a, 0x14, 0x01, 0xd9
	.byte 0x00, 0x3f, 0x01, 0xd9, 0x00, 0x05, 0x0a, 0x16
	.byte 0x01, 0x27, 0x00, 0x32, 0x01, 0x34, 0x00, 0x05
	.byte 0x0a, 0x04, 0x00, 0xda, 0x00, 0xfc, 0x00, 0xe7
	.byte 0x00, 0x05, 0x0a, 0x15, 0x01, 0xda, 0x00, 0x3e
	.byte 0x01, 0xe7, 0x00
; se_apply_confirm: 55 bytes (5 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_apply_confirm.c)
	.incbin "includes/generated/se_apply_confirm.bin"
	.byte 0xd6, 0x63, 0xf1, 0x00, 0xaa, 0x63
	.byte 0xf1, 0x00, 0xb5, 0x63, 0xf1, 0x00, 0xc0, 0x63
	.byte 0xf1, 0x00, 0xcb, 0x63, 0xf1, 0x00, 0x1b, 0x0a
	.byte 0x0d, 0x00, 0x4c, 0x00, 0x9a, 0x00, 0x88, 0x00
	.byte 0x0d, 0x00, 0x4c, 0x00, 0x9a, 0x00, 0x68, 0x00
	.byte 0x0d, 0x00, 0x4c, 0x00, 0x9a, 0x00, 0x68, 0x00
	.byte 0x0d, 0x00, 0x6c, 0x00, 0x9a, 0x00, 0x88, 0x00
	.byte 0x02, 0x0f, 0x60, 0x06, 0x20, 0x05, 0x20, 0xd1
	.byte 0x14, 0xf1, 0x00, 0x03, 0x00, 0x70, 0x1d, 0x00
	.byte 0x0a, 0x61, 0x06, 0x7f, 0x00, 0x20, 0x61, 0x22
	.byte 0x03, 0x00, 0x0a, 0x62, 0x06, 0x7f, 0x00, 0x20
	.byte 0x65, 0x22, 0x03, 0x00, 0x0a, 0x63, 0x06, 0x7f
	.byte 0x00, 0x20, 0x6a, 0x22, 0x03, 0x00, 0x0a, 0x64
	.byte 0x06, 0x7f, 0x00, 0x20, 0x6f, 0x22, 0x03, 0x05
	.byte 0x0b, 0x67, 0x06, 0xff, 0x00, 0x20, 0x84, 0x22
	.byte 0x02, 0x00, 0x17, 0x64, 0xf1, 0x00, 0x26, 0x64
	.byte 0xf1, 0x00, 0x30, 0x64, 0xf1, 0x00, 0x3a, 0x64
	.byte 0xf1, 0x00, 0x44, 0x64, 0xf1, 0x00, 0x79, 0x64
	.byte 0xf1, 0x00, 0x83, 0x64, 0xf1, 0x00, 0x4e, 0x64
	.byte 0xf1, 0x00, 0x00, 0x0a, 0x65, 0x06, 0x7f, 0x00
	.byte 0x20, 0x74, 0x22, 0x03, 0x00, 0x0a, 0x66, 0x06
	.byte 0x7f, 0x00, 0x20, 0x7a, 0x22, 0x03, 0x20, 0x07
	.ascii "t\" -- "
	.byte 0x07, 0x7a
	.ascii "\" --"
	.byte 0x05, 0x0b, 0x61, 0x06
	.byte 0xff, 0x00, 0x20, 0xb0, 0x0a, 0x02, 0x00, 0x02
	.byte 0x0f, 0x62, 0x06, 0x1f, 0x00, 0x20, 0xa9, 0x65
	.byte 0xf1, 0x00, 0x03, 0x00, 0xc8, 0x10, 0x05, 0x0b
	.byte 0x63, 0x06, 0xff, 0x00, 0x20, 0x30, 0x17, 0x02
	.byte 0x00, 0x05, 0x0b, 0x64, 0x06, 0xff, 0x00, 0x20
	.byte 0x70, 0x1d, 0x02, 0x00, 0x05, 0x0b, 0x69, 0x06
	.byte 0x0f, 0x00, 0x20, 0x9b, 0x0a, 0x02, 0x08, 0x05
	.byte 0x0b, 0x66, 0x06, 0xff, 0x00, 0x20, 0xb3, 0x10
	.byte 0x02, 0x00, 0x05, 0x0b, 0x67, 0x06, 0xff, 0x00
	.byte 0x20, 0x1b, 0x17, 0x02, 0x00, 0x03, 0x0b, 0x60
	.byte 0x06, 0x0f, 0x00, 0x05, 0x57, 0x65, 0xf1, 0x00
	.byte 0x02, 0x0f, 0x6a, 0x06, 0x0f, 0x00, 0x20, 0x01
	.byte 0x5b, 0xf1, 0x00, 0x0d, 0x00, 0x8e, 0x1e, 0x02
	.byte 0x0f, 0x6a, 0x06, 0x80, 0x07, 0x20, 0x15, 0x65
	.byte 0xf1, 0x00, 0x0d, 0x00, 0x8e, 0x1e, 0x4f, 0x46
	.ascii "F          OFF          "
EffectParam_Edit_Table:
	.long EffectParamEdit_Entry_08
	.long EffectParamEdit_Entry_01
	.long EffectParamEdit_Entry_02
	.long EffectParamEdit_Entry_03
	.long EffectParamEdit_Entry_04
	.long EffectParamEdit_Entry_04
	.long EffectParamEdit_Entry_06
	.long EffectParamEdit_Entry_07
	.long EffectParamEdit_Entry_07
	.long EffectParamEdit_Entry_05
	.byte 0x0c, 0x00, 0x3b, 0x00, 0x9b, 0x00, 0x58, 0x00
	.byte 0x0c, 0x00, 0x3b, 0x00, 0x9b, 0x00, 0x58, 0x00
	.byte 0x0c, 0x00, 0x62, 0x00, 0x9b, 0x00, 0x7f, 0x00
	.byte 0x0c, 0x00, 0x8a, 0x00, 0x9b, 0x00, 0xa7, 0x00
	.byte 0x0c, 0x00, 0xb3, 0x00, 0x9b, 0x00, 0xd0, 0x00
	.byte 0xa4, 0x00, 0x3a, 0x00, 0x33, 0x01, 0x58, 0x00
	.byte 0xa4, 0x00, 0x62, 0x00, 0x33, 0x01, 0x7f, 0x00
	.byte 0xa4, 0x00, 0x8a, 0x00, 0x33, 0x01, 0xa7, 0x00
	.byte 0xa4, 0x00, 0xb3, 0x00, 0x33, 0x01, 0xd0, 0x00
	.byte 0x1b, 0x0a, 0x0c, 0x00, 0x3b, 0x00, 0x33, 0x01
	.byte 0xd0, 0x00
	.ascii "OFF-10- 9- 8- 7- 6- 5- 4- 3- 2- 1  0+ 1+ 2+ 3+ 4+ 5+ 6+ 7+ 8+ 9+10"

InitializeNaka:
	.incbin "includes/generated/v7_transplant_InitializeNaka.bin"
NAKA_InitDataBlock:
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x13E0)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x1452)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x1492)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x1684)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x16FC)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x186C)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x19FE)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x1B8A)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x1D6E)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x1DF2)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x1F94)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x2004)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x2166)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x21E0)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x2342)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x24B2)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x2512)
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, (NAKA_UIObjectTable_0x2572)
	ret
	lds32	xhl, 0
	ret
	calr	371
	calr	56
	lds	wa, 1
	calr	2205
	calr	48
	lds	wa, 2
	calr	2197
	calr	40
	lds	wa, 3
	calr	2189
	calr	32
	lds	wa, 4
	calr	2181
	calr	24
	lds	wa, 5
	calr	2173
	calr	16
	lds	wa, 6
	calr	2165
	calr	8
	lds	wa, 7
	calr	2157
	jrl	5626

NoteEvent_LoadSoundGenParams:
	stb_dri L, 0xfd, 0x94, 0xfe
	push xiz
	ld xiy, NAKA_UIObjectTable_0x26D2
	stb_dri D, 0xfd, 0x10, 0x01
	ldw bc, 0x30
	ldirw
	ld xiy, NAKA_UIObjectTable_0x25D2
	lda xix, (xsp + 16)
	ldw bc, 0x80
	ldirw
	ldda32 xix, (3186)
	ld xiy, MSP_Default_Signature1
	ldw bc, 0x30
	ldirw
	ldda32 xwa, (3186)
	ld xiy, MSP_Default_VoiceEnable
	stb_dri D, 0xe1, 0xc0, 0x13
	ldw bc, 0x20
	ldirw
	ldda32 xbc, (3186)
	ld xwa, 0xba0
	add xbc, xwa
	ld xwa, xbc
	stb_dri B, 0xe5, 0x80, 0x00

NoteEvent_CopyVoiceParamsLoop:
	ld xiy, MSP_Default_SoundReserved_0x30
	ld xix, xwa
	ldw bc, 0x10
	ldirw
	lda xwa, (xwa + 32)
	cp xwa, xde
	jr ule, NoteEvent_CopyVoiceParamsLoop
	ldda32 xwa, (3186)
	stb_dri W, 0xe1, 0x40, 0x0c
	ld xde, xwa
	stb_dri W, 0xe1, 0xe0, 0x06
	ld (xsp + 12), xwa

NoteEvent_CopyExtParamsOuter:
	ld xwa, xde
	stb_dri C, 0xe9, 0x80, 0x00

NoteEvent_CopyExtParamsInner:
	ld xiy, MSP_Default_SoundReserved_0x50
	ld xix, xwa
	ldw bc, 0x10
	ldirw
	lda xwa, (xwa + 32)
	cp xwa, xhl
	jr ule, NoteEvent_CopyExtParamsInner
	stb_dri B, 0xe9, 0xa0, 0x00
	cp xde, (xsp + 12)
	jr ule, NoteEvent_CopyExtParamsOuter
	stb_dri W, 0xfd, 0x10, 0x01
	ld (xsp + 4), xwa
	lda xbc, (xwa + 4)
	ld (xsp + 8), xbc
	lda xiz, (xwa + 6)
	lda xbc, (xwa + 8)
	ld (xsp + 12), xbc
	lda xhl, (xwa + 10)
	ldda32 xwa, (3186)
	lda xwa, (xwa + 96)
	lds de, 4

NoteEvent_WriteRegOffsets_Loop:
	ld ix, de
	add ix, 0xfffc
	ld xbc, (xsp + 4)
	ld (xbc), ix
	ld ix, de
	add ix, 0xfffd
	ld xbc, (xsp + 8)
	ld (xbc), ix
	ld bc, de
	add bc, 0xfffe
	ld (xiz), bc
	ld ix, de
	add ix, 0xffff
	ld xbc, (xsp + 12)
	ld (xbc), ix
	ld (xhl), de
	stb_dri E, 0xfd, 0x10, 0x01
	ld xix, xwa
	ldw bc, 0x30
	ldirw
	inc 5, de
	lda xwa, (xwa + 96)
	cp de, 0x95
	jr ule, NoteEvent_WriteRegOffsets_Loop
	lds de, 0
	ld xwa, 0x1400

NoteEvent_CopySlotData_Loop:
	cp de, 0x96
	jr c, NoteEvent_CopySlotData_Body
	ld (xsp + 16), 0x0

NoteEvent_CopySlotData_Body:
	ld xix, xwa
	addda32 xix, 3186
	lda xiy, (xsp + 16)
	ldw bc, 0x80
	ldirw
	inc 1, de
	add xwa, 0x100
	cp de, 0x153
	jr ule, NoteEvent_CopySlotData_Loop
	pop xiz
	stb_dri L, 0xfd, 0x6c, 0x01
	ret

Flash_InitExtMemAddrs:
	lda_24 xwa, (0x300000)
	stda32 3190, xwa
	ld xbc, xwa
	add xbc, 0x19800
	stda32 3194, xbc
	ld xbc, xwa
	add xbc, 0x30000
	stda32 3198, xbc
	ld xbc, xwa
	add xbc, 0x49800
	stda32 3202, xbc
	ld xbc, xwa
	add xbc, 0x60000
	stda32 3206, xbc
	ld xbc, xwa
	add xbc, 0x79800
	stda32 3210, xbc
	ld xbc, xwa
	add xbc, 0x90000
	stda32 3214, xbc
	ld xbc, xwa
	add xbc, 0xb0000
	stda32 3218, xbc
	lda_24 xwa, (0x094800)
	stda32 3182, xwa
	lda_24 xwa, (0x069800)
	stda32 3186, xwa
	stda32 3222, xwa
	ret

Flash_InitBytecodeBlock:
	.incbin "includes/generated/v7_transplant_Flash_InitBytecodeBlock.bin"
PartGrid_ColumnDispatch:
	ldda32 xhl, (3182)
	ldda32 xbc, (3186)
	cp a, 0x1e
	jr nc, PartGrid_CopyHLtoBC
	cp a, 0xa
	ret c
	sub a, 0xa
	extz wa
	div a, 0x3
	extz wa
	cps wa, 0
	jr mi, PartGrid_CopyHLtoBC
	cps wa, 6
	jr gt, PartGrid_CopyHLtoBC
	add wa, wa
	lda_24 xix, (MSP_Default_GroupOffsetA)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (PartGrid_ColumnJumpTable)
	jp_ind 8, 0x07, 0xf0, 0xe0

PartGrid_ColumnJumpTable:
	ldda32	xhl, (3190)
	jr	38
	ldda32	xhl, (3194)
	jr	32
	ldda32	xhl, (3198)
	jr	26
	ldda32	xhl, (3202)
	jr	20
	ldda32	xhl, (3206)
	jr	14
	ldda32	xhl, (3210)
	jr	8
	ldda32	xhl, (3214)
	jr	t, 0x02

PartGrid_CopyHLtoBC:
	ld xhl, xbc
	ret

Util_FrameSetup10:
	lda xsp, (xsp - 10)
	ld (xsp + 4), e
	ld (xsp + 6), c
	ld (xsp + 8), a
	ld a, (xsp + 8)
	extz wa
	calr PartGrid_ColumnDispatch
	ld (xsp), xhl
	cp (xsp + 8), 0x1e
	jr c, FrameSetup_AdjustGE1E
	submi8 (xsp + 8), 0x1e
	jr FrameSetup_ComputeGridIndex

FrameSetup_AdjustGE1E:
	cp (xsp + 8), 0xa
	jr c, FrameSetup_ComputeGridIndex
	submi8 (xsp + 8), 0xa
	ld a, (xsp + 8)
	extz wa
	div a, 0x3
	ld (xsp + 8), w

FrameSetup_ComputeGridIndex:
	ld c, (xsp + 8)
	extz bc
	ld a, (xsp + 6)
	extz wa
	muls wa, 0x3
	add wa, bc
	lda_24 xbc, (MSP_Default_ChannelMap)
	ldb_sri A, 0x07, 0xe4, 0xe0
	ld e, (xsp + 4)
	cp (xsp + 4), 0x4
	jr z, FrameSetup_SpecialCase4
	extz wa
	muls wa, 0x60
	ld bc, wa
	add bc, 0x60
	ld xwa, (xsp)
	exts xbc
	add xbc, xwa
	cps e, 3
	jr z, FrameSetup_RowOffset3
	cps e, 2
	jr z, FrameSetup_RowOffset2
	cps e, 1
	jr z, FrameSetup_RowOffset1
	cps e, 0
	jr nz, FrameSetup_PackResult
	ld l, (xbc + 24)
	ld xwa, 0x19
	jr PartGrid_ByteOffsetLoop

FrameSetup_RowOffset1:
	ld l, (xbc + 32)
	ld xwa, 0x21
	jr PartGrid_ByteOffsetLoop

FrameSetup_RowOffset2:
	ld l, (xbc + 40)
	ld xwa, 0x29
	jr PartGrid_ByteOffsetLoop

FrameSetup_RowOffset3:
	ld l, (xbc + 48)
	ld xwa, 0x31

PartGrid_ByteOffsetLoop:
	add xbc, xwa
	ld a, (xbc)
	jr FrameSetup_PackResult

FrameSetup_SpecialCase4:
	extz wa
	muls wa, 0x60
	ld bc, wa
	add bc, 0x60
	ld xwa, (xsp)
	stb_dri W, 0x07, 0xe0, 0xe4
	ld l, (xwa + 56)
	ld a, (xwa + 57)

FrameSetup_PackResult:
	ld c, l
	extz bc
	extz wa
	sll wa, 8
	or wa, bc
	ld hl, wa
	lda xsp, (xsp + 10)
	ret

PartGrid_OperationsBlock:
	lda	xsp, (xsp-14)
	ld	(xsp+8), e
	ld	(xsp+10), c
	ld	(xsp+12), a
	ld	a, (xsp+12)
	extz	wa
	calr	65203
	ld	(xsp+4), xhl
	cp	(xsp+12), 30
	jr	c, 6
	.byte 0x8f
	incf
	push	xde
	.byte 0x1e
	jr	21
	cp	(xsp+12), 10
	jr	c, 15
	.byte 0x8f
	incf
	push	xde
	.byte 0x0a
	ld	a, (xsp+12)
	extz	wa
	div	a, 3
	ld	(xsp+12), w
	ld	c, (xsp+12)
	extz	bc
	ld	a, (xsp+10)
	extz	wa
	muls	wa, 3
	add	wa, bc
	lda_24	xbc, (MSP_Default_ChannelMap)
	ld_rrb	a, xbc, wa
	ld	(xsp+2), a
	ld	bc, (xsp+18)
	ld	de, bc
	ldb	d, 0
	srl	bc, 8
	ld	(xsp), c
	ld	a, (xsp+2)
	extz	wa
	muls	wa, 96
	ld	bc, wa
	add	bc, 96
	ld	xwa, (xsp+4)
	exts	xbc
	add	xbc, xwa
	cp	(xsp+8), 4
	jr	z, 64
	cp	(xsp+8), 3
	jr	z, 48
	cp	(xsp+8), 2
	jr	z, 32
	cp	(xsp+8), 1
	jr	z, 16
	cp	(xsp+8), 0
	jr	nz, 54
	ld	(xbc+24), e
	ld	xwa, 25
	jr	38
	.byte 0xb9
	.asciz " E@!"
	nop
	nop
	jr	28
	.byte 0xb9
	.asciz "(E@)"
	nop
	nop
	jr	18
	ld	(xbc+48), e
	ld	xwa, 49
	jr	8
	ld	(xbc+56), e
	ld	xwa, 57
	add	xbc, xwa
	ld	a, (xsp)
	ld	(xbc), a
	lda	xsp, (xsp+14)
	retd	2

; PartGrid column dispatch end
PartGrid_ColumnDispatch_End:
	lds wa, 0
	jr PartGrid_ColumnDispatch_Default

; PartGrid column dispatch default case
PartGrid_ColumnDispatch_Default:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ldiw_erp 0xfa, 0

PartGrid_DefaultLoop_Outer:
	stw_erp WA, 0xfa
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 5
	add xbc, 0x60
	addda32 xbc, 3186
	ld wa, (xbc)
	ld c, (xsp + 4)
	extz bc
	calr Pack12BitValueWithBank
	ld wa, hl
	stw_erp BC, 0xfa
	extz xbc
	ld xde, xbc
	add xde, xde
	add xde, xbc
	sll xde, 5
	add xde, 0x60
	addda32 xde, 3186
	ld (xde), wa
	lds iz, 2

PartGrid_DefaultLoop_Inner:
	ld bc, iz
	extz xbc
	add xbc, xbc
	stw_erp WA, 0xfa
	extz xwa
	ld xde, xwa
	add xde, xde
	add xde, xwa
	sll xde, 5
	add xde, xbc
	addda32 xde, 3186
	ld wa, (xde + 96)
	ld c, (xsp + 4)
	extz bc
	calr Pack12BitValueWithBank
	ld wa, hl
	ld de, iz
	extz xde
	add xde, xde
	stw_erp BC, 0xfa
	extz xbc
	ld xhl, xbc
	add xhl, xhl
	add xhl, xbc
	sll xhl, 5
	add xhl, xde
	addda32 xhl, 3186
	ld (xhl + 96), wa
	inc 1, iz
	cps iz, 5
	jr ule, PartGrid_DefaultLoop_Inner
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x1d, 0x00
	jrl ule, PartGrid_DefaultLoop_Outer
	ldiw_erp 0xfa, 0

; NoteEventBuffer CopyToSlot dispatch (7-entry, table 0xe16128)
NoteEvent_CopyToSlot:
	stw_erp WA, 0xfa
	extz xwa
	sll xwa, 8
	add xwa, 0x1400
	addda32 xwa, 3186
	ld wa, (xwa + 1)
	ld c, (xsp + 4)
	extz bc
	calr Pack12BitValueWithBank
	ld wa, hl
	stw_erp BC, 0xfa
	extz xbc
	sll xbc, 8
	add xbc, 0x1400
	ld xde, xbc
	addda32 xde, 3186
	ld (xde + 1), wa
	addda32 xbc, 3186
	ld wa, (xbc + 3)
	ld c, (xsp + 4)
	extz bc
	calr Pack12BitValueWithBank
	ld wa, hl
	stw_erp BC, 0xfa
	extz xbc
	sll xbc, 8
	add xbc, 0x1400
	addda32 xbc, 3186
	ld (xbc + 3), wa
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x53, 0x01
	jr ule, NoteEvent_CopyToSlot
	pop xiz
	inc 2, xsp
	ret

Pack12BitValueWithBank:
	ld hl, wa
	cp hl, 0xffff
	ret z
	and hl, 0xfff
	extz bc
	sll bc, 12
	or hl, bc
	ret

; NoteEventBuffer Store dispatch (7-entry, table 0xe16136)
NoteEvent_Store:
	extz wa
	lda_24 xbc, (MSP_Default_ChannelMap_0x1E)
	ldb_sri L, 0x07, 0xe4, 0xe0
	ret

NoteEventBuffer_CopyToSlot:
	ld c, a
	ldda32 xwa, (3186)
	extz bc
	dec 1, bc
	cps bc, 0
	jr lt, NoteEvent_CopyCommon
	cps bc, 6
	jr gt, NoteEvent_CopyCommon
	add bc, bc
	lda_24 xix, (MSP_Default_GroupOffsetB)
	ldw_sri BC, 0x07, 0xf0, 0xe4
	lda_24 xix, (NOTE_EVENT_DISPATCH_1)
	jp_ind 8, 0x07, 0xf0, 0xe4
; Note event buffer copy dispatch - 7 cases (BC 0-6)
; Selects destination buffer pointer based on case, then copies 46080 bytes
; Offset table at 0xe16128
NOTE_EVENT_DISPATCH_1:
	ldda32 xbc, (3190); Case 0: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ldda32 xbc, (3194); Case 1: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ldda32 xbc, (3198); Case 2: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ldda32 xbc, (3202); Case 3: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ldda32 xbc, (3206); Case 4: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ldda32 xbc, (3210); Case 5: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ldda32 xbc, (3214); Case 6: Load dest pointer (falls through)
NOTE_EVENT_COPY_COMMON:	; F1717D - Common handler
	ld xiy, xbc	; XIY = destination pointer
	ld xix, xwa	; XIX = source pointer
	ldw bc, 0xb400	; BC = 0xb400 byte count
	ldirw	; Block copy words

; NoteEventBuffer copy common handler
NoteEvent_CopyCommon:
	jrl PartGrid_ColumnDispatch_End

NoteEventBuffer_Store:
	lda xsp, (xsp - 10)
	ld (xsp + 8), a
	ld a, (xsp + 8)
	extz wa
	calr PartGrid_ColumnDispatch_Default
	ldda32 xwa, (3186)
	ld (xsp), xwa
	ld a, (xsp + 8)
	extz wa
	dec 1, wa
	cps wa, 0
	jrl lt, NoteEvent_StoreCommon
	cps wa, 6
	jrl gt, NoteEvent_StoreCommon
	add wa, wa
	lda_24 xix, (MSP_Default_VarSize)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (NOTE_EVENT_DISPATCH_2)
	jp_ind 8, 0x07, 0xf0, 0xe0
; Note event dispatch table 2
; 7 cases (WA 0-6), offset table at 0xe16136
NOTE_EVENT_DISPATCH_2:
	ldda32 xwa, (3190)
	ld (xsp + 4), xwa
	jrl Flash_WriteSectorWithMirrorCopy
NOTE_EVENT_DISPATCH_2b:
	ldda32 xwa, (3194)
	ld (xsp + 4), xwa

Flash_SectorWriteExecute:
	ld xwa, (xsp)
	stb_dri A, 0xe1, 0x00, 0x68
	ld xwa, (xsp + 4)
	stb_dri B, 0xe1, 0x00, 0x68
	lds wa, 1
	call Flash_EraseSectorAndWrite
	ld xiy, (xsp + 4)
	sub xiy, 0x9800
	ld xwa, (xsp)
	stb_dri B, 0xe1, 0x00, 0x68
	ld xix, xde
	ldw bc, 0x8000
	ldirw
	ld xbc, (xsp)

Flash_CopyMirrorLoop:
	ld xhl, xbc
	add xhl, 0x10000
	ldb_spi A, 0xe4
	ld (xhl), a
	cp xbc, xde
	jr c, Flash_CopyMirrorLoop
	ld xwa, (xsp)
	stb_dri A, 0xe1, 0x00, 0x68
	ld xde, (xsp + 4)
	sub xde, 0x9800
	lds wa, 1
	jr Flash_EraseAndWriteFinal
	ldda32 xwa, (3198)
	ld (xsp + 4), xwa
	jr Flash_WriteSectorWithMirrorCopy
	ldda32 xwa, (3202)
	ld (xsp + 4), xwa
	jr Flash_SectorWriteExecute
	ldda32 xwa, (3206)
	ld (xsp + 4), xwa
	jr Flash_WriteSectorWithMirrorCopy
	ldda32 xwa, (3210)
	ld (xsp + 4), xwa
	jr Flash_SectorWriteExecute
	ldda32 xwa, (3214)
	ld (xsp + 4), xwa
	jr Flash_WriteSectorWithMirrorCopy

; NoteEventBuffer store common handler
NoteEvent_StoreCommon:
	cps a, 0
	jrl nz, Flash_SectorWriteExecute

Flash_WriteSectorWithMirrorCopy:
	lds wa, 1
	ld xbc, (xsp)
	ld xde, (xsp + 4)
	call Flash_EraseSectorAndWrite
	ld xiy, (xsp + 4)
	add xiy, 0x10000
	ld xwa, (xsp)
	ld xix, xwa
	ldw bc, 0x8000
	ldirw
	ld xwa, (xsp)
	add xwa, 0x10000
	ld xbc, xwa
	stb_dri B, 0xe1, 0x00, 0x68

Flash_CopyReverseMirrorLoop:
	ld xhl, xbc
	add xhl, 0xffff0000
	ldb_spi A, 0xe4
	ld (xhl), a
	cp xbc, xde
	jr c, Flash_CopyReverseMirrorLoop
	ld xde, (xsp + 4)
	add xde, 0x10000
	lds wa, 1
	ld xbc, (xsp)

Flash_EraseAndWriteFinal:
	call Flash_EraseSectorAndWrite
	lda xsp, (xsp + 10)
	ret

Flash_StoreBaseAndInitAccPatch:
	.incbin "includes/generated/v7_transplant_Flash_StoreBaseAndInitAccPatch.bin"
Flash_ExtendedOpsBlock:
	.incbin "includes/generated/v7_transplant_Flash_ExtendedOpsBlock.bin"
VoiceParam_ComputeOffset:
	ld e, a
	cp e, 0x28
	jr nc, VoiceParam_SubtractBase
	ld xhl, 0x10
	jr VoiceParam_AddOffset

VoiceParam_SubtractBase:
	sub e, 0x28
	ld xhl, 0x50

VoiceParam_AddOffset:
	extz de
	add hl, de
	ldda32 xwa, (3222)
	lda_dri XHL, 0x07, 0xe0, 0xec
	ret

DualVoice_ScanAllColumns:
	dec 2, xsp
	pushw_erp 0xfa
	ld (xsp + 2), a
	calr SlotTable_InitBank1748
	ldib_erp 0xfb, 0

DualVoice_ScanColumnLoop:
	ld a, (xsp + 2)
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 0
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0x700
	cp bc, 0x600
	jr z, DualVoice_StoreBankMatch
	cp bc, 0x500
	jr nz, DualVoice_ScanRow1

DualVoice_StoreBankMatch:
	stda16 (1748), xwa

DualVoice_ScanRow1:
	ld a, (xsp + 2)
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 1
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1748
	ld a, (xsp + 2)
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 2
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1748
	ld a, (xsp + 2)
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1748
	ld a, (xsp + 2)
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 4
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1748
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jrl c, DualVoice_ScanColumnLoop
	popw_erp 0xfa
	inc 2, xsp
	ret

DualVoice_ScanAllColumnsAlt:
	dec 2, xsp
	pushw_erp 0xfa
	ld (xsp + 2), a
	calr SlotTable_InitBank1850
	ldib_erp 0xfb, 0

DualVoice_ScanColumnLoopAlt:
	ld a, (xsp + 2)
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 0
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0x700
	cp bc, 0x600
	jr z, DualVoice_StoreBankMatchAlt
	cp bc, 0x500
	jr nz, DualVoice_ScanRow1Alt

DualVoice_StoreBankMatchAlt:
	stda16 (1850), xwa

DualVoice_ScanRow1Alt:
	ld a, (xsp + 2)
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 1
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1850
	ld a, (xsp + 2)
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 2
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1850
	ld a, (xsp + 2)
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1850
	ld a, (xsp + 2)
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 4
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1850
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jrl c, DualVoice_ScanColumnLoopAlt
	popw_erp 0xfa
	inc 2, xsp
	ret

SlotTable_InitBank1748:
	lda_d16 xbc, (1748)
	ldw (xbc), 0xffff
	ldb l, 0x0
	lds wa, 0

SlotTable_InitBank1748_Loop:
	ld de, wa
	inc 2, de
	stiw_ind 0x07, 0xe4, 0xe8, 0xff, 0xff
	inc 1, l
	inc 2, wa
	cp l, 0x32
	jr c, SlotTable_InitBank1748_Loop
	ret

SlotTable_InitBank1850:
	lda_d16 xbc, (1850)
	ldw (xbc), 0xffff
	ldb l, 0x0
	lds wa, 0

SlotTable_InitBank1850_Loop:
	ld de, wa
	inc 2, de
	stiw_ind 0x07, 0xe4, 0xe8, 0xff, 0xff
	inc 1, l
	inc 2, wa
	cp l, 0x32
	jr c, SlotTable_InitBank1850_Loop
	ret

SlotTable_ExtendedOpsBlock:
	lda_d16	xde, (1952)
	.byte 0xb2
	push	sr
	swi	7
	swi	7
	.byte 0xba
	push	sr
	push	sr
	swi	7
	swi	7
	lda	xbc, (xde+6)
	ld	xwa, xbc
	inc	4, xde
	.byte 0xf3, 0xe5, 0xc8
	nop
	ldw	bc, 0xeaf5
	push	sr
	swi	7
	swi	7
	.byte 0xf5, 0xe2
	push	sr
	swi	7
	swi	7
	cp	xwa, xbc
	jr	c, -14
	ret
	lda_d16	xde, (2156)
	.byte 0xb2
	push	sr
	swi	7
	swi	7
	.byte 0xba
	push	sr
	push	sr
	swi	7
	swi	7
	lda	xbc, (xde+6)
	ld	xwa, xbc
	inc	4, xde
	.byte 0xf3, 0xe5, 0xc8
	nop
	ldw	bc, 0xeaf5
	push	sr
	swi	7
	swi	7
	.byte 0xf5, 0xe2
	push	sr
	swi	7
	swi	7
	cp	xwa, xbc
	jr	c, -14
	ret
	lda_d16	xix, (2360)
	.byte 0xb4
	push	sr
	swi	7
	swi	7
	.byte 0xbc
	push	sr
	push	sr
	swi	7
	swi	7
	.byte 0xbc, 0x04
	push	sr
	swi	7
	swi	7
	lda	xbc, (xix+108)
	ld	xwa, xbc
	lda	xde, (xix+106)
	lds	hl, 0
	.byte 0xf3, 0xe5, 0xc8
	nop
	ldw	bc, 0x8ddb
	inc	6, iy
	.byte 0xf3
	reti
	.byte 0xf0, 0xf4
	push	sr
	swi	7
	swi	7
	.byte 0xf5, 0xea
	push	sr
	swi	7
	swi	7
	.byte 0xf5, 0xe2
	push	sr
	swi	7
	swi	7
	inc	2, hl
	cp	xwa, xbc
	jr	c, -27
	ret
	lda_d16	xix, (2666)
	.byte 0xb4
	push	sr
	swi	7
	swi	7
	.byte 0xbc
	push	sr
	push	sr
	swi	7
	swi	7
	.byte 0xbc, 0x04
	push	sr
	swi	7
	swi	7
	lda	xbc, (xix+108)
	ld	xwa, xbc
	lda	xde, (xix+106)
	lds	hl, 0
	lda	xbc, (xbc+200)
	ld	iy, hl
	inc	6, iy
	.byte 0xf3
	reti
	.byte 0xf0, 0xf4
	push	sr
	swi	7
	swi	7
	.byte 0xf5, 0xea
	push	sr
	swi	7
	swi	7
	.byte 0xf5, 0xe2
	push	sr
	swi	7
	swi	7
	inc	2, hl
	cp	xwa, xbc
	jr	c, -27
	ret
	lda_d16	xbc, (3074)
	.byte 0xb1
	push	sr
	swi	7
	swi	7
	ldb	l, 0
	lds	wa, 0
	ld	de, wa
	inc	2, de
	.byte 0xf3
	reti
	.byte 0xe4, 0xe8
	push	sr
	swi	7
	swi	7
	inc	1, l
	inc	2, wa
	cp	l, 50
	jr	c, -20
	ret
	lda_d16	xbc, (2972)
	.byte 0xb1
	push	sr
	swi	7
	swi	7
	ldb	l, 0
	lds	wa, 0
	ld	de, wa
	inc	2, de
	.byte 0xf3
	reti
	.byte 0xe4, 0xe8
	push	sr
	swi	7
	swi	7
	inc	1, l
	inc	2, wa
	cp	l, 50
	jr	c, -20
	ret

SlotTable_Insert1748:
	ldib_erp 0xe2, 0
	lda_d16 xhl, (1748)

SlotTable_Insert1748_Loop:
	stb_erp C, 0xe2
	extz bc
	add bc, bc
	inc 2, bc
	stb_dri B, 0x07, 0xec, 0xe4
	ld bc, (xde)
	cp bc, wa
	ret z
	cp bc, 0xffff
	jr nz, SlotTable_Insert1748_Next
	ld (xde), wa
	ret

SlotTable_Insert1748_Next:
	inc1b_erp 0xe2
	cp_erpb 0xe2, 0x32
	jr c, SlotTable_Insert1748_Loop
	ret

SlotTable_Insert1850:
	ldib_erp 0xe2, 0
	lda_d16 xhl, (1850)

SlotTable_Insert1850_Loop:
	stb_erp C, 0xe2
	extz bc
	add bc, bc
	inc 2, bc
	stb_dri B, 0x07, 0xec, 0xe4
	ld bc, (xde)
	cp bc, wa
	ret z
	cp bc, 0xffff
	jr nz, SlotTable_Insert1850_Next
	ld (xde), wa
	ret

SlotTable_Insert1850_Next:
	inc1b_erp 0xe2
	cp_erpb 0xe2, 0x32
	jr c, SlotTable_Insert1850_Loop
	ret

Flash_WriteBackSlotTable:
	pushw_erp 0xfa
	ldda32 xix, (3222)
	ldda32 xiy, (3218)
	ldw bc, 0x8000
	ldirw
	lda_d16 xwa, (1850)
	cpw (xwa), 0xffff
	jr z, Flash_WriteBackSlot_StartLoop
	ld wa, (xwa)
	ldb w, 0x0
	add a, 0x28
	extz wa
	lds bc, 0
	calr VoiceParam_ComputeOffset

Flash_WriteBackSlot_StartLoop:
	ldib_erp 0xfb, 0

Flash_WriteBackSlot_Loop:
	stb_erp A, 0xfb
	extz wa
	add wa, wa
	inc 2, wa
	lda_d16 xbc, (1850)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	cp wa, 0xffff
	jr z, Flash_WriteBackSlot_Erase
	and wa, 0x7f
	extz wa
	lds bc, 0
	calr VoiceParam_ComputeOffset
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x32
	jr c, Flash_WriteBackSlot_Loop

Flash_WriteBackSlot_Erase:
	ldda32 xbc, (3222)
	ldda32 xde, (3218)
	lds wa, 1
	call Flash_EraseSectorAndWrite
	popw_erp 0xfa
	ret

Flash_SlotUpdateOpsBlock:
	.incbin "includes/generated/v7_transplant_Flash_SlotUpdateOpsBlock.bin"
FloppyDisk_LoadNoteEvents:
	.incbin "includes/generated/v7_transplant_FloppyDisk_LoadNoteEvents.bin"
FloppyCtrl_LoadIzAndContinue:
	ld hl, iz
	jr FloppyCtrl_PopIzStoreHL

Floppy_SetHLFF9A_RetZero:
	ldw hl, 0xff9a

FloppyCtrl_PopIzStoreHL:
	popw iz
	stb_dri L, 0xfd, 0x08, 0x04
	ret

; Floppy disk compute tone parameters and validate
FloppyDisk_ComputeToneParams:
	stb_dri L, 0xfd, 0xe8, 0xfb
	push xiz
	stl_dri XDE, 0xfd, 0x10, 0x04
	stl_dri XBC, 0xfd, 0x14, 0x04
	stl_dri XWA, 0xfd, 0x18, 0x04
	calr Flash_InitExtMemAddrs
	ld xiy, MSP_Default_Signature3
	lda xix, (xsp + 16)
	ldw bc, 0x200
	ldirw
	ldda32 xbc, (3190)
	lds32 xhl, 0
	ld l, (xbc + 46)
	ld a, (xbc + 47)
	lds32 xix, 0
	ldb_erp A, 0xf0
	lda xbc, (xsp + 16)
	lda xwa, (xbc + 68)
	ld (xsp + 12), xwa
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld xwa, (xsp + 12)
	ld (xwa), xix
	ldda32 xde, (3194)
	lds32 xhl, 0
	ld l, (xde + 46)
	ld a, (xde + 47)
	lds32 xix, 0
	ldb_erp A, 0xf0
	lda xwa, (xbc + 72)
	ld (xsp + 8), xwa
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld xwa, (xsp + 8)
	ld (xwa), xix
	ldda32 xde, (3198)
	lds32 xhl, 0
	ld l, (xde + 46)
	ld a, (xde + 47)
	lds32 xix, 0
	ldb_erp A, 0xf0
	lda xwa, (xbc + 76)
	ld (xsp + 4), xwa
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld xwa, (xsp + 4)
	ld (xwa), xix
	ldda32 xde, (3202)
	lds32 xhl, 0
	ld l, (xde + 46)
	ld a, (xde + 47)
	lds32 xix, 0
	ldb_erp A, 0xf0
	lda xde, (xbc + 80)
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld (xde), xix
	ldda32 xix, (3206)
	lds32 xhl, 0
	ld l, (xix + 46)
	ld a, (xix + 47)
	lds32 xix, 0
	ldb_erp A, 0xf0
	lda xiy, (xbc + 84)
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld (xiy), xix
	ldda32 xix, (3210)
	lds32 xhl, 0
	ld l, (xix + 46)
	ld a, (xix + 47)
	lds32 xix, 0
	ldb_erp A, 0xf0
	lda xiz, (xbc + 88)
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld (xiz), xix
	ldda32 xix, (3214)
	lds32 xhl, 0
	ld l, (xix + 46)
	ld a, (xix + 47)
	lds32 xix, 0
	ldb_erp A, 0xf0
	sll xix, 8
	add xix, xhl
	ld xhl, xix
	sll xhl, 4
	ld (xbc + 92), xhl
	ld xwa, (xsp + 12)
	ld xix, (xwa)
	add xix, (xbc + 64)
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	add xwa, xix
	ld xix, (xsp + 4)
	ld xix, (xix)
	add xix, xwa
	ld xwa, (xde)
	add xwa, xix
	ld xde, (xiy)
	add xde, xwa
	ld xwa, (xiz)
	add xwa, xde
	add xhl, xwa
	ld xwa, (xbc + 96)
	add xwa, xhl
	ld (xbc + 28), xwa
	ld xiz, xwa
	ld_sril XIX, (xsp + 0x0418)
	call (xix)
	cp xhl, xiz
	jr ge, FloppyDisk_CopyNoteBuffers
	ldw hl, 0xff9b
	jrl FloppyCtrl_PopIzStoreRet

; Floppy disk copy note buffers to slots and write tone data
FloppyDisk_CopyNoteBuffers:
	lda xwa, (xsp + 16)
	ld_sril XIX, (xsp + 0x0414)
	ld xbc, 0x400
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jrl lt, FloppyCtrl_PopIzStoreRet
	lds wa, 1
	calr NoteEventBuffer_CopyToSlot
	ldda32 xwa, (3186)
	lds32 xde, 0
	ld e, (xwa + 46)
	lds32 xbc, 0
	ld c, (xwa + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jrl lt, FloppyCtrl_PopIzStoreRet
	lds wa, 2
	calr NoteEventBuffer_CopyToSlot
	ldda32 xwa, (3186)
	lds32 xde, 0
	ld e, (xwa + 46)
	lds32 xbc, 0
	ld c, (xwa + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jrl lt, FloppyCtrl_PopIzStoreRet
	lds wa, 3
	calr NoteEventBuffer_CopyToSlot
	ldda32 xwa, (3186)
	lds32 xde, 0
	ld e, (xwa + 46)
	lds32 xbc, 0
	ld c, (xwa + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jrl lt, FloppyCtrl_PopIzStoreRet
	lds wa, 4
	calr NoteEventBuffer_CopyToSlot
	ldda32 xwa, (3186)
	lds32 xde, 0
	ld e, (xwa + 46)
	lds32 xbc, 0
	ld c, (xwa + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jrl lt, FloppyCtrl_PopIzStoreRet
	lds wa, 5
	calr NoteEventBuffer_CopyToSlot
	ldda32 xhl, (3186)
	lds32 xde, 0
	ld e, (xhl + 46)
	lds32 xbc, 0
	ld c, (xhl + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	ld xwa, xhl
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jr lt, FloppyCtrl_PopIzStoreRet
	lds wa, 6
	calr NoteEventBuffer_CopyToSlot
	ldda32 xhl, (3186)
	lds32 xde, 0
	ld e, (xhl + 46)
	lds32 xbc, 0
	ld c, (xhl + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	ld xwa, xhl
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jr lt, FloppyCtrl_PopIzStoreRet
	lds wa, 7
	calr NoteEventBuffer_CopyToSlot
	ldda32 xhl, (3186)
	lds32 xde, 0
	ld e, (xhl + 46)
	lds32 xbc, 0
	ld c, (xhl + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	ld xwa, xhl
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jr lt, FloppyCtrl_PopIzStoreRet
	ldda32 xwa, (3218)
	ld_sril XIX, (xsp + 0x0414)
	ld xbc, 0xf400
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)

FloppyCtrl_PopIzStoreRet:
	pop xiz
	stb_dri L, 0xfd, 0x18, 0x04
	ret

ToneParam_ExtendedOpsBlock:
	.incbin "includes/generated/v7_transplant_ToneParam_ExtendedOpsBlock.bin"
DualVoice_LoadAndScan:
	.incbin "includes/generated/v7_transplant_DualVoice_LoadAndScan.bin"
DualVoice_AccPatchLoop:
	.incbin "includes/generated/v7_transplant_DualVoice_AccPatchLoop.bin"
DualVoice_ParamCompareLoop:
	.incbin "includes/generated/v7_transplant_DualVoice_ParamCompareLoop.bin"
DualVoice_SetLoadFlag:
	ld (xsp + 4), 0x1

DualVoice_LoadDoneRetVal:
	ld l, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 12)
	ret

DualVoice_LoopCheckNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr c, DualVoice_ParamCompareLoop
	cp (xsp + 10), 0x0
	jr nz, DualVoice_SetLoadFlag
	calr Flash_StoreBaseAndInitAccPatch
	ld a, (xsp + 6)
	extz wa
	calr NoteEventBuffer_Store
	lda_d16 xwa, (1850)
	cpw (xwa), 0xffff
	jr nz, DualVoice_WriteBackSlots
	cpw (xwa + 2), 0xffff
	jr z, DualVoice_LoadDoneRetVal

DualVoice_WriteBackSlots:
	calr Flash_WriteBackSlotTable
	jr DualVoice_LoadDoneRetVal
	pushw iz
	call msp_ld_mae
	lda_24 xwa, (0x1e8800)
	ld xde, xwa
	lda_24 xbc, (0x1ec400)
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	calr FileHdr_ValidateSignature
	ld wa, iz
	call msp_ld_ato
	ld hl, iz
	popw iz
	ret

FileHdr_ValidateSignature:
	calr FileHdr_InitBasePointer
	ldda32 xwa, (3226)
	ld l, (xwa)
	ld e, (xwa + 1)
	ld c, (xwa + 2)
	cp l, 0x47
	jr nz, FileHdr_CheckLKE
	cps e, 0
	jr nz, FileHdr_CheckLKE
	cp c, 0x4b
	jr z, FileHdr_SignatureMatch

FileHdr_CheckLKE:
	cp l, 0x4c
	jr nz, FileHdr_CheckMKB
	cp e, 0x4b
	jr nz, FileHdr_CheckMKB
	cp c, 0x45
	jr z, FileHdr_SignatureMatch

FileHdr_CheckMKB:
	cp l, 0x4d
	ret nz
	cp e, 0x4b
	ret nz
	cp c, 0x42
	ret nz

FileHdr_SignatureMatch:
	stb_dri W, 0xe1, 0xff, 0x27
	ld xbc, xwa
	stb_dri B, 0xe1, 0x01, 0xd9

FileHdr_CopyDataLoop:
	ld a, (xbc)
	lda_dri XBC, 0xe5, 0x00, 0x02
	dec 1, xbc
	cp xbc, xde
	jr nc, FileHdr_CopyDataLoop
	calr ToneData_SetupCopyPointers
	ret

FileHdr_InitBasePointer:
	lda_24 xwa, (0x1e8800)
	stda32 3226, xwa
	ret

ToneData_SetupCopyPointers:
	ldda32 xbc, (3226)
	stb_dri A, 0xe5, 0x00, 0x01
	ld xwa, xbc
	stb_dri A, 0xe5, 0x00, 0x02

ToneData_ZeroFillLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, ToneData_ZeroFillLoop

	lda_24 xwa, (Composer_SettingsBlock)
	ld xbc, xwa
	ldda32 xde, (3226)
	lda xhl, (xwa + 6)

ToneData_CopyBlock1_Loop:
	ldb_spi A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, ToneData_CopyBlock1_Loop
	lda_24 xhl, (Composer_SettingsBlock_0x60)
	ld xbc, xhl
	ldda32 xwa, (3226)
	lda xde, (xwa + 16)
	lda xhl, (xhl + 16)

ToneData_CopyBlock2_Loop:
	ldb_spi A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, ToneData_CopyBlock2_Loop
	lda_24 xhl, (MSP_Default_PartBankMap)
	ld xbc, xhl
	ldda32 xwa, (3226)
	stb_dri B, 0xe1, 0x00, 0x02
	lda xhl, (xhl + 64)

ToneData_CopyBlock3_Loop:
	ldb_spi A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, ToneData_CopyBlock3_Loop
	lda_24 xhl, (Composer_SettingsBlock_0x80)
	ld xbc, xhl
	ldda32 xwa, (3226)
	stb_dri B, 0xe1, 0x40, 0x02
	lda xhl, (xhl + 64)

ToneData_CopyBlock4_Loop:
	ldb_spi A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, ToneData_CopyBlock4_Loop
	lda_24 xhl, (Composer_SettingsBlock_0xC0)
	ld xbc, xhl
	ldda32 xwa, (3226)
	stb_dri B, 0xe1, 0x80, 0x02
	lda xhl, (xhl + 64)

ToneData_CopyBlock5_Loop:
	ldb_spi A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, ToneData_CopyBlock5_Loop
	ldda32 xwa, (3226)
	lda xbc, (xwa + 32)
	lds32 xde, 0

ToneData_ScanRegionLoop:
	cp (xbc), 0x0
	jr nz, ToneData_AdvanceRegion
	lda_24 xiy, (Composer_SettingsBlock_0x70)
	ld xhl, xiy
	ldda32 xwa, (3226)
	lda xwa, (xwa + 32)
	ld xix, xde
	add xix, xwa
	lda xiy, (xiy + 16)

ToneData_CopyRegion_Inner:
	ldb_spi A, 0xec
	lda_dpi XBC, 0xf0
	cp xhl, xiy
	jr c, ToneData_CopyRegion_Inner

ToneData_AdvanceRegion:
	add xde, 0x10
	lda xbc, (xbc + 16)
	cp xde, 0xc0
	jr c, ToneData_ScanRegionLoop
	ret

InitializeSuna:
	.incbin "includes/generated/v7_transplant_InitializeSuna.bin"
CmpBndRngFunc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e0003f
	jr z, CmpBndRng_ReturnOne
	cp xbc, 0x1e0003e
	jr z, CmpBndRng_ReturnOne
	cp xbc, 0x1e00041
	jr z, CmpBndRng_ReturnThree
	cp xbc, 0x1e00040
	jr z, CmpBndRng_ReturnSizeConst
	cp xbc, 0x1e00042
	jr z, CmpBndRng_BoundCase
	lds32 xhl, 0
	jr CmpBndRng_PopIzRet

CmpBndRng_BoundCase:
	ld bc, (xde + 4)
	ld xwa, (xde + 8)
	cps bc, 0
	jr lt, CmpBndRng_DefaultString
	cp bc, 0xc
	jr gt, CmpBndRng_DefaultString
	sla bc, 2
	lda_24 xde, (0x03d992)
	ld_sril3 XBC, 0x07, 0xe8, 0xe4
	push xbc
	jr CmpBndRng_CallStrcpy

CmpBndRng_DefaultString:
	pushw 0xe1
	pushw 0xce12

CmpBndRng_CallStrcpy:
	.incbin "includes/generated/v7_transplant_CmpBndRng_CallStrcpy.bin"
CmpBndRng_ReturnSizeConst:
	ld xhl, 0x28403
	jr CmpBndRng_PopIzRet

CmpBndRng_ReturnThree:
	lds32 xhl, 3
	jr CmpBndRng_PopIzRet

CmpBndRng_ReturnOne:
	lds32 xhl, 1

CmpBndRng_PopIzRet:
	pop xiz
	ret
CmpBndRng_End:

AcCmpMdBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1e0004d
	jrl z, CmpSetP1_TtlDispatch
	cp xbc, 0x1c0001d
	jr z, AcCmpMdBox_HandleLswUpdate
	cp xbc, 0x1c0000c
	jr z, AcCmpMdBox_InheritAndRefresh
	cp xbc, 0x1c0000b
	jr z, AcCmpMdBox_InheritAndRefresh
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl CmpSetP1_TtlDispatch_End

AcCmpMdBox_InheritAndRefresh:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, 0x94810
	lds bc, 1
	call MainRamGet
	jr GridBoxProc_Return

AcCmpMdBox_HandleLswUpdate:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xix, (xsp + 4)
	ld xbc, (xix)
	lda_24 xwa, (0x094810)
	lda xde, (xhl + 46)
	cp xwa, xbc
	jr nz, GridBoxProc_Return
	ld l, (xhl + 50)
	extz hl
	extz xhl
	ld xbc, (xde)
	cp xhl, (xix + 14)
	jr nz, AcCmpMdBox_SetValueZero
	ldw (xbc), 0x1
	jr AcCmpMdBox_SendChangeEvent

AcCmpMdBox_SetValueZero:
	ldw (xbc), 0x0

AcCmpMdBox_SendChangeEvent:
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, xiz
	ld xbc, 0x1c0000e
	call SendEvent
	jr GridBoxProc_Return

; CmpSetP1 title dispatch
CmpSetP1_TtlDispatch:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	cp xwa, 0x1
	jr nz, GridBoxProc_Return
	ld xwa, xiz
	call GetViewInstance
	ld a, (xhl + 50)
	stb_da (0x094810), a

GridBoxProc_Return:
	lds32 xhl, 0

; CmpSetP1 title dispatch end
CmpSetP1_TtlDispatch_End:
	pop xiz
	inc 4, xsp
	ret
; CmpSetP1 title dispatch default
CmpSetP1_TtlDispatch_Default:
AcCmpSetGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1e0008d
	jrl z, CmpSetP1_GridCheck_Case3
	ld xwa, (xsp + 16)
	cp xwa, 0x1e0008b
	jrl z, CmpSetP1_GridCheck_Case1
	cp xwa, 0x1e0008a
	jrl z, CmpSetP1_GridCheckDispatch
	cp xwa, 0x1c00001
	jr z, CmpSetP1_DialGrid
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, CmpSetP1_GridCheck_Case4
	cp xbc, 0x6
	jrl gt, CmpSetP1_GridCheck_Case4
	add xbc, xbc
	add xbc, NoteStepDisplayData_0x5C
	ld bc, (xbc)
	lda_24 xix, (CmpSetP1_DialGrid)
	jp_ind 8, 0x07, 0xf0, 0xe4

; CmpSetP1 dial grid dispatch (7-entry, table 0xe1ce3a)
CmpSetP1_DialGrid:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jrl CmpSetP1_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, CmpSetP1_SendAndApplyFunc
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, (NoteStepDisplayData_0x38)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	sub hl, wa
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl CmpSetP1_ReturnZeroJmp

CmpSetP1_SendAndApplyFunc:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, CmpSetP1_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl CmpSetP1_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, CmpSetP1_DialDownSendApply
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, (NoteStepDisplayData_0x4A)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	add wa, hl
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl CmpSetP1_ReturnZeroJmp

CmpSetP1_DialDownSendApply:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, CmpSetP1_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

CmpSetP1_SetDialEnable:
	call SetDialEnable
	jr CmpSetP1_ReturnZeroJmp

; CmpSetP1 grid check dispatch
CmpSetP1_GridCheckDispatch:
	ld xwa, xiz
	ld xiz, 0x3e
	jr CmpSetP1_GridCheck_Case2

; CmpSetP1 grid check case 1
CmpSetP1_GridCheck_Case1:
	ld xwa, xiz
	ld xiz, 0x42

; CmpSetP1 grid check case 2
CmpSetP1_GridCheck_Case2:
	.incbin "includes/generated/v7_transplant_CmpSetP1_GridCheck_Case2.bin"
CmpSetP1_GridCheck_Case3:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall

CmpSetP1_ReturnZeroJmp:
	lds32 xhl, 0
	jr CmpSetP1_GridCheck_Case5

; CmpSetP1 grid check case 4
CmpSetP1_GridCheck_Case4:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

; CmpSetP1 grid check case 5
CmpSetP1_GridCheck_Case5:
	pop xiz
	lda xsp, (xsp + 16)
	ret

CmpSetP1GridCheck:
	lda xsp, (xsp - 28)
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, CmpSetP1_GridCheck_Return
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, Widget_PostEvtReturnZero
	cp xwa, 0x6
	jrl gt, Widget_PostEvtReturnZero
	add xwa, xwa
	add xwa, StrTimeSig_1_2_0x20
	ld wa, (xwa)
	lda_24 xix, (CmpSetP1_GridCheck_EventEnc)
	jp_ind 8, 0x07, 0xf0, 0xe0

; CmpSetP1 grid check event encoding dispatch
CmpSetP1_GridCheck_EventEnc:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	cps	wa, 1
	jrl	nz, 328
	exts	xde
	ld	xwa, 0x144000d
	ld	xbc, 0x1e4000e
	jr	54
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	cps	wa, 1
	jrl	nz, 272
	exts	xde
	ld	xwa, 0x144000d
	ld	xbc, 0x1e4000f
	call	MainFuncCall
	jrl	253

; CmpSetP1 grid check return
CmpSetP1_GridCheck_Return:
	lda xbc, (xsp + 20)
	ld xwa, xde
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld (xwa), de
	lda xde, (xsp)
	ld (xbc + 4), xde
	ld wa, (xwa)
	lda_24 xhl, (0x03da06)
	dec 1, wa
	cps wa, 0
	jrl lt, WidgetHandler_PostEventAndReturnZero
	cps wa, 7
	jrl gt, WidgetHandler_PostEventAndReturnZero
	add wa, wa
	lda_24 xix, (StrTimeSig_1_2_0x10)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (UI_COMPONENT_DISPATCH)
	jp_ind 8, 0x07, 0xf0, 0xe0
; UI component dispatch table - handles cases 0-7 for grid/focus handling
; Offset table at 0xe1cef0 selects which handler to run based on WA value
UI_COMPONENT_DISPATCH:
	.incbin "includes/generated/v7_transplant_UI_COMPONENT_DISPATCH.bin"
UI_COMPONENT_DISPATCH_CASE1:
	.incbin "includes/generated/v7_transplant_UI_COMPONENT_DISPATCH_CASE1.bin"
UI_COMPONENT_DISPATCH_CASE2:
	.incbin "includes/generated/v7_transplant_UI_COMPONENT_DISPATCH_CASE2.bin"
UI_COMPONENT_DISPATCH_CASE3:
	.incbin "includes/generated/v7_transplant_UI_COMPONENT_DISPATCH_CASE3.bin"
UI_COMPONENT_DISPATCH_CASE2_COMMON:
	extz bc	; Zero-extend C to BC
	sla bc, 2	; Shift left by 2 (multiply by 4)
	ld_sril3 XWA, 0x07, 0xe0, 0xe4	; Load entry from table
	push xwa	; Push parameter
	jr UI_COMPONENT_DISPATCH_PUSH_CALL	; Jump to push and call
UI_COMPONENT_DISPATCH_CASE4:
	lds wa, 6	; Load 6
	jr UI_COMPONENT_DISPATCH_CASE5_COMMON	; Jump to common code
UI_COMPONENT_DISPATCH_CASE5:
	lds wa, 5	; Load 5
UI_COMPONENT_DISPATCH_CASE5_COMMON:
	.incbin "includes/generated/v7_transplant_UI_COMPONENT_DISPATCH_CASE5_COMMON.bin"
UI_COMPONENT_DISPATCH_CASE5_SKIP:
	and c, 0x1	; Mask C to get bit 0
	extz bc	; Zero-extend C to BC
	sla bc, 2	; Shift left by 2 (multiply by 4)
	ld_sril3 XWA, 0x07, 0xec, 0xe4	; Load entry from table
	push xwa	; Push parameter
UI_COMPONENT_DISPATCH_PUSH_CALL:
	.incbin "includes/generated/v7_transplant_UI_COMPONENT_DISPATCH_PUSH_CALL.bin"
WidgetHandler_PostEventAndReturnZero:
	cpw (xsp + 22), 0x4
	jr z, Widget_PostEvtReturnZero
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, 0x1e0008c
	call SendEvent

Widget_PostEvtReturnZero:
	lds32 xhl, 0
	lda xsp, (xsp + 28)
	ret

CmpSetGridCheck:
	lda xsp, (xsp - 18)
	push xiz
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, CmpSet_GridCheck_Dispatch
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, GridCheck_ReturnZero
	cp xwa, 0x6
	jrl gt, GridCheck_ReturnZero
	add xwa, xwa
	add xwa, StrPanLeft64_0xA
	ld wa, (xwa)
	lda_24 xix, (GridCheck_Handler0)
	jp_ind 8, 0x07, 0xf0, 0xe0

; =============================================================================
; GridCheck_Handler0 - Grid/Check widget handler for cases 0 and 2
; Called via jump table when event code is 0x1c00017 + (0 or 2)
; Queries UI object state and sends appropriate event (0x01e40008 or 0x01e4000a)
; =============================================================================
GridCheck_Handler0:
	call GetFocusObject	; Get UI object
	ld xwa, xhl	; Save result in XWA
	ld xbc, 0x1e0008f	; Event code for query
	lds32 xde, 0	; Parameter = 0
	call SendEvent	; Query object state
	ld xde, xhl	; Result in XDE
	lda xwa, (xsp + 14)	; Get local var pointer
	ld xbc, xde	; Copy result to XBC
	srl xbc, 0	; SRL 0, XBC (clear carry)
	ldiw_erp 0xe6, 0	; LD QBC, 0 (clear high bits)
	ld (xwa), bc	; Store low word
	ld (xwa + 2), de	; Store high word
	ld wa, (xwa)	; Load state value
	exts xde	; Sign extend DE
	cps wa, 2	; Check if state == 2
	jr z, GridCheck_Handler0_State2
	cps wa, 1	; Check if state == 1
	jrl nz, GridCheck_ReturnZero	; If neither, exit
	ld xwa, 0x144000d	; Widget ID
	ld xbc, 0x1e40008	; Event: grid check state 1 (case 0)
	jr GridCheck_SendEvent
GridCheck_Handler0_State2:
	ld xwa, 0x144000d	; Widget ID
	ld xbc, 0x1e4000a	; Event: grid check state 2 (case 0)
	jr GridCheck_SendEvent

; =============================================================================
; GridCheck_Handler1 - Grid/Check widget handler for cases 1 and 3
; Called via jump table when event code is 0x1c00017 + (1 or 3)
; Queries UI object state and sends appropriate event (0x01e40009 or 0x01e4000b)
; =============================================================================
GridCheck_Handler1:
	call GetFocusObject	; Get UI object
	ld xwa, xhl	; Save result in XWA
	ld xbc, 0x1e0008f	; Event code for query
	lds32 xde, 0	; Parameter = 0
	call SendEvent	; Query object state
	ld xde, xhl	; Result in XDE
	lda xwa, (xsp + 14)	; Get local var pointer
	ld xbc, xde	; Copy result to XBC
	srl xbc, 0	; SRL 0, XBC (clear carry)
	ldiw_erp 0xe6, 0	; LD QBC, 0 (clear high bits)
	ld (xwa), bc	; Store low word
	ld (xwa + 2), de	; Store high word
	ld wa, (xwa)	; Load state value
	exts xde	; Sign extend DE
	cps wa, 2	; Check if state == 2
	jr z, GridCheck_Handler1_State2
	cps wa, 1	; Check if state == 1
	jr nz, GridCheck_ReturnZero	; If neither, exit
	ld xwa, 0x144000d	; Widget ID
	ld xbc, 0x1e40009	; Event: grid check state 1 (case 1)
	jr GridCheck_SendEvent
GridCheck_Handler1_State2:
	ld xwa, 0x144000d	; Widget ID
	ld xbc, 0x1e4000b	; Event: grid check state 2 (case 1)
	; Fall through to GridCheck_SendEvent

; =============================================================================
; GridCheck_SendEvent - Common epilogue for grid/check handlers
; Sends the event in XBC with widget ID in XWA
; =============================================================================
GridCheck_SendEvent:
	call MainFuncCall	; Send event
	jr GridCheck_ReturnZero	; Return to caller

; CmpSet grid check dispatch (7-entry, table 0xe1d40e)
CmpSet_GridCheck_Dispatch:
	lda xbc, (xsp + 14)
	ld xwa, xde
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld (xwa), de
	lda xde, (xsp + 4)
	ld (xbc + 4), xde
	ld de, (xbc)
	ld bc, (xwa)
	exts xbc
	cps de, 2
	jr z, GridCheck_SetMode1
	cps de, 1
	jr nz, GridCheck_GetFocusAndSend
	lds wa, 0
	ld xiz, 0x3da4e
	jr GridCheck_LookupAndSend

GridCheck_SetMode1:
	lds wa, 1
	ld xiz, 0x3d9c6

GridCheck_LookupAndSend:
	.incbin "includes/generated/v7_transplant_GridCheck_LookupAndSend.bin"
GridCheck_GetFocusAndSend:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1e0008c
	call SendEvent

GridCheck_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 18)
	ret

GridCheck_LookupSndParam:
	.incbin "includes/generated/v7_transplant_GridCheck_LookupSndParam.bin"
GridCheck_ClampParamAlt:
	ld l, (xbc + 5)
	cp l, 0xb
	ret ule
	ldb l, 0xb

GridCheck_ClampDone:
	ret

CmpSetPageFunc:
	cp xbc, 0x1c0000c
	jr z, CmpSetPage_ReturnZero
	cp xbc, 0x1c0000b
	jr z, CmpSetPage_ReturnZero
	cp xbc, 0x1c00002
	jr z, CmpSetPage_ReturnZero
	cp xbc, 0x1c00001
	jr nz, CmpSetPage_ReturnZero
	or xde, xde
	jr nz, CmpSetPage_ReturnZero
	ld xwa, 0xb40002
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xb4000e
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002
	call SendEvent

CmpSetPage_ReturnZero:
	lds32 xhl, 0
	ret
AcApcToggle_End:

AcApcToggleProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1c0001c
	jrl z, AcApcToggle_HandleLswMsg
	cp xiz, 0x1c00001
	jr z, AcApcToggle_HandleOpen
	cp xiz, 0x1c00007
	jr z, AcApcToggle_HandleClose
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jr AcApcToggle_CallInherited

AcApcToggle_HandleClose:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1e00053
	ld xde, (xsp + 8)
	call SendEvent
	cps hl, 0
	jr z, AcApcToggle_Fallthrough
	ld xwa, (xsp + 12)
	ld xbc, 0x1e0006c
	lds32 xde, 0
	call SendEvent
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 34)
	ld de, (xwa)
	exts xde
	ld xwa, (xbc + 40)
	ld xbc, 0x1e0003b
	call ApFuncCall
	jrl EventHandler_Return

AcApcToggle_Fallthrough:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)

AcApcToggle_CallInherited:
	call InheritedProc
	jrl AcApcToggle_PopReturn

AcApcToggle_HandleOpen:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xbc, (xiz + 44)
	cp xbc, 0x1
	jr z, AcApcToggle_SetParam83
	or xbc, xbc
	jr nz, AcApcToggle_ReadSndParam
	ld xwa, 0x28081
	jr AcApcToggle_ReadSndParam

AcApcToggle_SetParam83:
	ld xwa, 0x28083

AcApcToggle_ReadSndParam:
	.incbin "includes/generated/v7_transplant_AcApcToggle_ReadSndParam.bin"
AcApcToggle_SetOne:
	ldw (xwa), 0x1

AcApcToggle_SendUpdate:
	ld xwa, (xbc)
	ld de, (xwa)
	exts xde
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	jrl AcApcToggle_SendEvent

AcApcToggle_HandleLswMsg:
	.incbin "includes/generated/v7_transplant_AcApcToggle_HandleLswMsg.bin"
AcApcToggle_SendZero:
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jr AcApcToggle_SendEvent

AcApcToggle_Check83Match:
	ld xwa, (xwa)
	cp xwa, 0x1
	jr nz, EventHandler_Return
	ld xwa, (xsp + 8)
	cpw (xwa + 4), 0x1
	jr nz, AcApcToggle_Send83Zero
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	jr AcApcToggle_SendEvent

AcApcToggle_Send83Zero:
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 0

AcApcToggle_SendEvent:
	call SendEvent

EventHandler_Return:
	lds32 xhl, 0

AcApcToggle_PopReturn:
	pop xiz
	lda xsp, (xsp + 12)
	ret

ApcOnOffFunc:
	cp xbc, 0x1e0003b
	jr nz, ApcOnOff_ReturnZero
	ld xwa, 0x28081
	lds bc, 1
	lds de, 4
	call MainLswPut

ApcOnOff_ReturnZero:
	lds32 xhl, 0
	ret

ApcOnBasFunc:
	cp xbc, 0x1e0003b
	jr nz, ApcOnBas_ReturnZero
	ld xwa, 0x28083
	lds bc, 1
	lds de, 4
	call MainLswPut

ApcOnBas_ReturnZero:
	lds32 xhl, 0
	ret
ApcOnBas_End:

AcApcMdBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1e0004d
	jrl z, AcApcMdBox_HandleTitleDisp
	cp xbc, 0x1c0001c
	jr z, AcApcMdBox_HandleLswUpdate
	cp xbc, 0x1c0000c
	jr z, AcApcMdBox_GetLswValue
	cp xbc, 0x1c0000b
	jr z, AcApcMdBox_GetLswValue
	cp xbc, 0x1c00002
	jr z, AcApcMdBox_ResetFilter
	cp xbc, 0x1c00001
	jrl nz, AcApcMdBox_DefaultInherited
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, xiz
	ld xbc, 0x28080
	call SetLswFilter
	lds wa, 0
	jrl AcApcMdBox_SetDialEnable

AcApcMdBox_ResetFilter:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, xiz
	ld xbc, 0x28080
	call ResetLswFilter
	jrl AcS2cMem_ReturnZeroJmp

AcApcMdBox_GetLswValue:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, 0x28080
	call MainLswGet
	jrl AcS2cMem_ReturnZeroJmp

AcApcMdBox_HandleLswUpdate:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xiy, (xsp + 4)
	ld xwa, (xiy)
	cp xwa, 0x28080
	jr nz, AcS2cMem_ReturnZeroJmp
	ld a, (xhl + 50)
	ldb_erp A, 0xf0
	extz ix
	lda xde, (xhl + 46)
	ld xbc, (xde)
	cp ix, (xiy + 4)
	jr nz, AcApcMdBox_SetValueZero
	ldw (xbc), 0x1
	jr AcApcMdBox_SendChangeEvent

AcApcMdBox_SetValueZero:
	ldw (xbc), 0x0

AcApcMdBox_SendChangeEvent:
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, xiz
	ld xbc, 0x1c0000e
	call SendEvent
	jr AcS2cMem_ReturnZeroJmp

AcApcMdBox_HandleTitleDisp:
	.incbin "includes/generated/v7_transplant_AcApcMdBox_HandleTitleDisp.bin"
AcApcMdBox_SetDialEnable:
	call SetDialEnable

AcS2cMem_ReturnZeroJmp:
	lds32 xhl, 0
	jr AcApcMdBox_PopReturn

AcApcMdBox_DefaultInherited:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc

AcApcMdBox_PopReturn:
	pop xiz
	inc 4, xsp
	ret
AcApcMdBox_End:

AcS2cMemNoBoxProc:
	stb_dri L, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, S2cMemNoBox_HandleScroll
	cp xbc, 0x1c0000b
	jr z, S2cMemNoBox_HandleScroll
	cp xbc, 0x1c00002
	jr z, S2cMemNoBox_HandleClose
	cp xbc, 0x1c00001
	jr z, S2cMemNoBox_HandleOpen
	ld xwa, xiz
	call InheritedProc
	jr S2cMemNoBox_PopReturn

S2cMemNoBox_HandleOpen:
	ld xwa, xiz
	jr S2cMemNoBox_CallInherited

S2cMemNoBox_HandleClose:
	ld xwa, xiz

S2cMemNoBox_CallInherited:
	call InheritedProc
	jr S2cMemNoBox_ReturnZero

S2cMemNoBox_HandleScroll:
	.incbin "includes/generated/v7_transplant_S2cMemNoBox_HandleScroll.bin"
S2cMemNoBox_ReturnZero:
	lds32 xhl, 0

S2cMemNoBox_PopReturn:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x01
	ret
S2cMemNoBox_End:

PsS2cFmeasBoxProc:
	stb_dri L, 0xfd, 0xfc, 0xfe
	push xiz
	stl_dri XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c0000c
	jr z, PsS2cFmeas_HandleScroll
	cp xbc, 0x1c0000b
	jr z, PsS2cFmeas_HandleScroll
	ld_sril XWA, (xsp + 0x0104)
	call InheritedProc
	jr PsS2cFmeas_PopReturn

PsS2cFmeas_HandleScroll:
	.incbin "includes/generated/v7_transplant_PsS2cFmeas_HandleScroll.bin"
PsS2cFmeas_SetActive:
	ldw (xwa), 0xff
	ldw (xbc), 0xf5

PsS2cFmeas_SendUpdateEvents:
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	call SendEvent
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent
	lds32 xhl, 0

PsS2cFmeas_PopReturn:
	pop xiz
	stb_dri L, 0xfd, 0x04, 0x01
	ret
PsS2cFmeas_End:

PsS2cLmeasBoxProc:
	stb_dri L, 0xfd, 0xfc, 0xfe
	push xiz
	stl_dri XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c0000c
	jr z, PsS2cLmeas_HandleScroll
	cp xbc, 0x1c0000b
	jr z, PsS2cLmeas_HandleScroll
	ld_sril XWA, (xsp + 0x0104)
	call InheritedProc
	jr PsS2cLmeas_PopReturn

PsS2cLmeas_HandleScroll:
	.incbin "includes/generated/v7_transplant_PsS2cLmeas_HandleScroll.bin"
PsS2cLmeas_SetActive:
	ldw (xwa), 0xff
	ldw (xbc), 0xf5

PsS2cLmeas_SendUpdateEvents:
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	call SendEvent
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent
	lds32 xhl, 0

PsS2cLmeas_PopReturn:
	pop xiz
	stb_dri L, 0xfd, 0x04, 0x01
	ret
PsS2cLmeas_End:

PsSeqSongNoBoxProc:
	stb_dri L, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, PsSeqSongNo_HandleScroll
	cp xbc, 0x1c0000b
	jr z, PsSeqSongNo_HandleScroll
	ld xwa, xiz
	call InheritedProc
	jr PsSeqSongNo_PopReturn

PsSeqSongNo_HandleScroll:
	.incbin "includes/generated/v7_transplant_PsSeqSongNo_HandleScroll.bin"
PsSeqSongNo_PopReturn:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x01
	ret
PsSeqSongNo_End:

PsS2cTransBoxProc:
	stb_dri L, 0xfd, 0xfc, 0xfe
	push xiz
	stl_dri XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c0000c
	jr z, PsS2cTrans_HandleScroll
	cp xbc, 0x1c0000b
	jr z, PsS2cTrans_HandleScroll
	ld_sril XWA, (xsp + 0x0104)
	call InheritedProc
	jr SndArg_GridBnk_Case2

PsS2cTrans_HandleScroll:
	.incbin "includes/generated/v7_transplant_PsS2cTrans_HandleScroll.bin"
SndArg_GridBnk_Case0:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

; SndArgGridBnk case 1
SndArg_GridBnk_Case1:
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	call SendEvent
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent
	lds32 xhl, 0

; SndArgGridBnk case 2
SndArg_GridBnk_Case2:
	pop xiz
	stb_dri L, 0xfd, 0x04, 0x01
	ret
; SndArgGridBnk case 3
SndArg_GridBnk_Case3:
S2cGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld xiz, xbc
	ld (xsp + 16), xwa
	ld xwa, xiz
	cp xiz, 0x1e40031
	jrl z, FdcFormat_GridCheck_Case3
	cp xiz, 0x1e0008d
	jrl z, FdcFormat_GridCheck_Case2
	cp xiz, 0x1e0008b
	jrl z, FdcFormat_GridCheck_Case1
	cp xiz, 0x1e0008a
	jrl z, FdcFormat_GridCheck
	cp xiz, 0x1c00001
	jr z, FdcFormat_DialGrid
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, FdcFormat_GridCheck_Case4
	cp xwa, 0x6
	jrl gt, FdcFormat_GridCheck_Case4
	add xwa, xwa
	add xwa, StrTranspose_Minus25_0x4
	ld wa, (xwa)
	lda_24 xix, (FdcFormat_DialGrid)
	jp_ind 8, 0x07, 0xf0, 0xe0

; FdcFormat dial grid dispatch (7-entry, table 0xe1d728)
FdcFormat_DialGrid:
	.incbin "includes/generated/v7_transplant_FdcFormat_DialGrid.bin"
S2cGrid_DialDownSendApply:
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, FdcFormat_ReturnZeroJmp
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00019
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl S2cGrid_SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, S2cGrid_DialUpSendApply
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0001a
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl FdcFormat_ReturnZeroJmp

S2cGrid_DialUpSendApply:
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, FdcFormat_ReturnZeroJmp
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0001a
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

S2cGrid_SetDialEnable:
	call SetDialEnable
	jr FdcFormat_ReturnZeroJmp

; FdcFormat grid check dispatch
FdcFormat_GridCheck:
	ld xwa, (xsp + 16)
	ld xiz, 0x3e
	jr S2cGrid_GetViewAndCopy

; FdcFormat grid check case 1
FdcFormat_GridCheck_Case1:
	ld xwa, (xsp + 16)
	ld xiz, 0x42

S2cGrid_GetViewAndCopy:
	.incbin "includes/generated/v7_transplant_S2cGrid_GetViewAndCopy.bin"
FdcFormat_GridCheck_Case2:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall
	jr FdcFormat_ReturnZeroJmp

; FdcFormat grid check case 3
FdcFormat_GridCheck_Case3:
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 12), xhl
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008d
	ld xde, (xsp + 12)
	call SendEvent

FdcFormat_ReturnZeroJmp:
	lds32 xhl, 0
	jr FdcFormat_GridCheck_Case5

; FdcFormat grid check case 4
FdcFormat_GridCheck_Case4:
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call InheritedProc

; FdcFormat grid check case 5
FdcFormat_GridCheck_Case5:
	pop xiz
	lda xsp, (xsp + 16)
	ret

