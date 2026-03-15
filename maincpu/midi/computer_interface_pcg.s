; =============================================================================
; computer_interface_pcg.asm - Computer Interface PCG Output
; =============================================================================
; This file contains PCG (Program Change) Output routines for the
; Computer Interface subsystem:
;   TtMdPcgOut            - PCG Output title handler
;   AcPcgOutGridBoxProc   - PCG Output grid box action processor
;   PcgOutGridCheck       - PCG Output grid validation
;   PcgOutSendFunc        - PCG Output send function handler
;   MainPcgOutSend        - Main PCG Output send dispatcher
;
; =============================================================================

TtMdPcgOut:
	cp xbc, 0x1C0000C
	jr z, TtMdPcgOut_Exit
	cp xbc, 0x1C0000B
	jr z, TtMdPcgOut_Exit
	cp xbc, 0x1C00002
	jr z, TtMdPcgOut_Exit
	cp xbc, 0x1C00001
	jr nz, TtMdPcgOut_Exit
	or xde, xde
	jr nz, TtMdPcgOut_Exit
	ld xwa, 0x590001
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x0
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1

TtMdPcgOut_Exit:
	lds32 xhl, 0
	ret

AcPcgOutGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1E0008D
	jrl z, PcgOutGrid_DispatchDelegate
	ld xwa, (xsp + 16)
	cp xwa, 0x1E0008B
	jrl z, PcgOutGrid_CopyStrBank1
	cp xwa, 0x1E0008A
	jrl z, PcgOutGrid_CopyStrBank0
	cp xwa, 0x1C00001
	jr z, PcgOutGridBoxEventDispatch
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, PcgOutGrid_DefaultHandler
	cp xbc, 0x6
	jrl gt, PcgOutGrid_DefaultHandler
	add xbc, xbc
	add xbc, 0xE7FF20
	ld bc, (xbc)
	lda_24 xix, 0xf7743b
	jp_dri 8, 0x07, 0xF0, 0xE4

PcgOutGridBoxEventDispatch:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00018
	call SetDialDown
	lds wa, 1
	jrl PcgOutGridDialConfirm
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, PcgOutGrid_CheckAltPrev
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl PcgOutGrid_ReturnZero

PcgOutGrid_CheckAltPrev:
	ld xwa, xiz
	ld xbc, 0x1E00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, PcgOutGrid_ReturnZero
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl PcgOutGridDialConfirm
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, PcgOutGrid_CheckAltNext
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	cps hl, 3
	jrl ge, PcgOutGrid_ReturnZero
	inc 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl PcgOutGrid_ReturnZero

PcgOutGrid_CheckAltNext:
	ld xwa, xiz
	ld xbc, 0x1E00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, PcgOutGrid_ReturnZero
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

PcgOutGridDialConfirm:
	call SetDialEnable
	jr PcgOutGrid_ReturnZero

PcgOutGrid_CopyStrBank0:
	ld xwa, xiz
	ld xiz, 0x3E
	jr PcgOutGrid_CopyStrCommon

PcgOutGrid_CopyStrBank1:
	ld xwa, xiz
	ld xiz, 0x42

PcgOutGrid_CopyStrCommon:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr PcgOutGrid_ReturnZero
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	jr PcgOutGrid_CallDelegate

PcgOutGrid_DispatchDelegate:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

PcgOutGrid_CallDelegate:
	call ApFuncCall

PcgOutGrid_ReturnZero:
	lds32 xhl, 0
	jr PcgOutGrid_Epilogue

PcgOutGrid_DefaultHandler:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

PcgOutGrid_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

PcgOutGridCheck:
	lda xsp, (xsp - 44)
	push xiz
	ld xiz, xde
	ld (xsp + 44), xbc
	ld xiy, 0xE7FF44
	lda xix, (xsp + 12)
	lds bc, 5
	ldirw
	ld xiy, 0xE7ED44
	lda xix, (xsp + 4)
	lds bc, 4
	ldirw
	ld xix, (xsp + 44)
	lda xiy, (xsp + 12)
	lda xhl, (xsp + 4)
	lda xbc, (xhl + 2)
	lda xde, (xhl + 4)
	ld xwa, (xsp + 44)
	cp xwa, 0x1E0008D
	jrl z, PcgOutCheckGridDataStructure
	ld xwa, xix
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, PcgOutGridCheckComplete
	cp xwa, 0x6
	jrl gt, PcgOutGridCheckComplete
	add xwa, xwa
	add xwa, 0xE7FFEE
	ld wa, (xwa)
	lda_24 xix, 0xf776bd
	jp_dri 8, 0x07, 0xF0, 0xE0

PcgOutGridCheckJumpTable:
	call	16401616
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	16422496
	ld	xiz, xhl
	lda	xwa, (xsp+4)
	ld	xbc, xiz
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	cpw	(xwa), 1
	jrl	nz, 1690
	ld	xde, (xsp+44)
	cps	bc, 3
	jrl	z, 163
	cps	bc, 2
	jr	z, 103
	cps	bc, 1
	jr	z, 52
	cps	bc, 0
	jrl	nz, 1669
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda_24	xbc, 149354
	ld	(xwa), xbc
	ld	xbc, 15
	ld	(xwa+6), xbc
	cp	xde, 29360153
	jr	nz, 5
	lds32	xbc, 4
	ld	(xwa+14), xbc
	jrl	481
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda_24	xbc, 149356
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	cp	xde, 29360153
	jr	nz, 5
	lds32	xbc, 4
	ld	(xwa+14), xbc
	jrl	434
	cpi8_24	149360, 255
	jrl	z, 1566
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda_24	xbc, 149358
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	cp	xde, 29360153
	jr	nz, 5
	lds32	xbc, 4
	ld	(xwa+14), xbc
	jrl	378
	.byte 0x45
	.long UserMemory_FormatStrings
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda_24	xbc, 149360
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	ld	(xwa+10), xbc
	cp	xde, 29360153
	jr	nz, 5
	lds32	xbc, 4
	ld	(xwa+14), xbc
	jrl	323
	call	16401616
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	16422496
	ld	xiz, xhl
	lda	xwa, (xsp+4)
	ld	xbc, xiz
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	cpw	(xwa), 1
	jrl	nz, 1420
	ld	xde, (xsp+44)
	cps	bc, 3
	jrl	z, 205
	cps	bc, 2
	jrl	z, 131
	cps	bc, 1
	jr	z, 66
	cps	bc, 0
	jrl	nz, 1398
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda_24	xbc, 149354
	ld	(xwa), xbc
	ld	xbc, 15
	ld	(xwa+6), xbc
	lda	xhl, (xwa+14)
	cp	xde, 29360154
	jr	nz, 9
	ld	xbc, 4294967292
	ld	(xhl), xbc
	jr	7
	ld	xbc, 4294967295
	ld	(xhl), xbc
	jrl	196
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda_24	xbc, 149356
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	lda	xhl, (xwa+14)
	cp	xde, 29360154
	jr	nz, 9
	ld	xbc, 4294967292
	ld	(xhl), xbc
	jr	7
	ld	xbc, 4294967295
	ld	(xhl), xbc
	jrl	135
	cpi8_24	149360, 255
	jrl	z, 1267
	ld	xiy, 15204142
	lda	xix, (xsp+22)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+22)
	lda_24	xbc, 149358
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	lda	xhl, (xwa+14)
	cp	xde, 29360154
	jr	nz, 9
	ld	xbc, 4294967292
	ld	(xhl), xbc
	jr	7
	ld	xbc, 4294967295
	.byte 0xb3
	.ascii "ahBE"
	.long UserMemory_FormatStrings
	.byte 0xbf, 0x16, 0x34, 0x31
	.byte 0x0b, 0x00, 0x95, 0x11, 0xbf, 0x16, 0x30, 0xf2
	.byte 0x70, 0x47, 0x02, 0x31, 0xb0, 0x61, 0x41, 0x7f
	.byte 0x00, 0x00, 0x00, 0xb8, 0x06, 0x61, 0x41, 0xff
	.byte 0xff, 0xff, 0xff, 0xb8, 0x0a, 0x61, 0xb8, 0x0e
	.byte 0x33, 0xea, 0xcf, 0x1a, 0x00, 0xc0, 0x01, 0x6e
	.byte 0x09, 0x41, 0xfc, 0xff, 0xff, 0xff, 0xb3, 0x61
	.byte 0x68, 0x07, 0x41, 0xff, 0xff, 0xff, 0xff, 0xb3
	.byte 0x61, 0x1d, 0x8a, 0xfe, 0xf9, 0x78, 0x6e, 0x04
	.byte 0xb3, 0x02, 0x01, 0x00, 0xed, 0x8b, 0xb2, 0x65
	.byte 0xf2, 0x6a, 0x47, 0x02, 0x32, 0xbe, 0x0e, 0x30
	.byte 0xa6, 0xf2, 0x6e, 0x28, 0xb1, 0x02, 0x00, 0x00
	.byte 0xa0, 0x20, 0xe8, 0x61, 0x38, 0x0b, 0xe7, 0x00
	.byte 0x0b, 0x4e, 0xff, 0x3b, 0x1d, 0x72, 0x0a, 0xff
	.byte 0xbf, 0x0c, 0x37, 0x1d, 0xd0, 0x44, 0xfa, 0xeb
	.byte 0x88, 0xbf, 0x04, 0x32, 0x41, 0x8c, 0x00, 0xe0
	.byte 0x01, 0x78, 0x2e, 0x04, 0xf2, 0x6c, 0x47, 0x02
	.byte 0x32, 0xa6, 0xf2, 0x6e, 0x28, 0xb1, 0x02, 0x01
	.byte 0x00, 0xa0, 0x20, 0xe8, 0x61, 0x38, 0x0b, 0xe7
	.byte 0x00, 0x0b, 0x54, 0xff, 0x3b, 0x1d, 0x72, 0x0a
	.byte 0xff, 0xbf, 0x0c, 0x37, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0xbf, 0x04, 0x32, 0x41, 0x8c, 0x00
	.byte 0xe0, 0x01, 0x78, 0xfd, 0x03, 0xf2, 0x6e, 0x47
	.byte 0x02, 0x32, 0xa6, 0xf2, 0x7e, 0xab, 0x00, 0xb1
	.byte 0x02, 0x02, 0x00, 0xc2, 0x70, 0x47, 0x02, 0x3f
	.byte 0xff, 0x6e, 0x45, 0x0b, 0xe7, 0x00, 0x0b, 0x5a
	.byte 0xff, 0x3b, 0x1d, 0x4d, 0x0f, 0xff, 0xef, 0x60
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x04
	.byte 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x1d, 0x60
	.byte 0x96, 0xfa, 0xbf, 0x06, 0x02, 0x04, 0x00, 0x0b
	.byte 0xe7, 0x00, 0x0b, 0x60, 0xff, 0xbf, 0x10, 0x30
	.byte 0x38, 0x1d, 0x4d, 0x0f, 0xff, 0xef, 0x60, 0x1d
	.byte 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x04, 0x32
	.byte 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0xa2, 0x03
	.byte 0xa0, 0x20, 0x38, 0x0b, 0xe7, 0x00, 0x0b, 0x68
	.byte 0xff, 0x3b, 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0c
	.byte 0x37, 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf
	.byte 0x04, 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x1d
	.byte 0x60, 0x96, 0xfa, 0xbf, 0x06, 0x02, 0x04, 0x00
	.byte 0xc2, 0x70, 0x47, 0x02, 0x23, 0xd9, 0x13, 0xae
	.byte 0x0e, 0x20, 0xd8, 0xee, 0x07, 0xd9, 0x80, 0x28
	.byte 0x0b, 0xe7, 0x00, 0x0b, 0x6e, 0xff, 0xbf, 0x12
	.byte 0x30, 0x38, 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0a
	.byte 0x37, 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf
	.byte 0x04, 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78
	.byte 0x48, 0x03, 0xf2, 0x70, 0x47, 0x02, 0x32, 0xa6
	.byte 0xf2, 0x7e, 0x42, 0x03, 0xb1, 0x02, 0x02, 0x00
	.byte 0xa0, 0x20, 0xe8, 0xcf, 0xff, 0xff, 0xff, 0xff
	.byte 0x6e, 0x6c, 0x0b, 0xe7, 0x00, 0x0b, 0x76, 0xff
	.byte 0x3b, 0x1d, 0x4d, 0x0f, 0xff, 0xef, 0x60, 0x1d
	.byte 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x04, 0x32
	.byte 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xbf, 0x06, 0x02, 0x03, 0x00, 0x0b, 0xe7
	.byte 0x00, 0x0b, 0x7c, 0xff, 0xbf, 0x10, 0x30, 0x38
	.byte 0x1d, 0x4d, 0x0f, 0xff, 0xef, 0x60, 0x1d, 0xd0
	.byte 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x04, 0x32, 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa
	.byte 0xbf, 0x06, 0x02, 0x04, 0x00, 0x0b, 0xe7, 0x00
	.byte 0x0b, 0x82, 0xff, 0xbf, 0x10, 0x30, 0x38, 0x1d
	.byte 0x4d, 0x0f, 0xff, 0xef, 0x60, 0x1d, 0xd0, 0x44
	.byte 0xfa, 0xeb, 0x88, 0xbf, 0x04, 0x32, 0x41, 0x8c
	.byte 0x00, 0xe0, 0x01, 0x78, 0xc4, 0x02, 0xc2, 0x6e
	.byte 0x47, 0x02, 0x21, 0xd8, 0x13, 0x28, 0x0b, 0xe7
	.byte 0x00, 0x0b, 0x8a, 0xff, 0x3b, 0x1d, 0x72, 0x0a
	.byte 0xff, 0xbf, 0x0a, 0x37, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0xbf, 0x04, 0x32, 0x41, 0x8c, 0x00
	.byte 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa, 0xbf, 0x06
	.byte 0x02, 0x03, 0x00, 0xae, 0x0e, 0x20, 0x38, 0x0b
	.byte 0xe7, 0x00, 0x0b, 0x90, 0xff, 0xbf, 0x14, 0x30
	.byte 0x38, 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0c, 0x37
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x04
	.byte 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x1d, 0x60
	.byte 0x96, 0xfa, 0xbf, 0x06, 0x02, 0x04, 0x00, 0xae
	.byte 0x0e, 0x21, 0xc2, 0x6e, 0x47, 0x02, 0x21, 0xd8
	.byte 0x13, 0xd8, 0xee, 0x07, 0xd9, 0x80, 0x28, 0x0b
	.byte 0xe7, 0x00, 0x0b, 0x96, 0xff, 0xbf, 0x12, 0x30
	.byte 0x38, 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0a, 0x37
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x04
	.byte 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x39
	.byte 0x02

PcgOutCheckGridDataStructure:
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xE2, 0
	ld (xhl), wa
	ld xwa, xbc
	ld ix, iz
	ld (xbc), ix
	ld xbc, xiy
	ld (xde), xiy
	cpw (xhl), 0x1
	jrl nz, PcgOutGridCheckComplete
	ld de, (xwa)
	cps de, 3
	jrl z, PcgOutCheck_SendPreset3
	cps de, 2
	jr z, PcgOutCheck_SendPreset2
	cps de, 1
	jr z, PcgOutCheck_SendPreset1
	cps de, 0
	jrl nz, PcgOutGridCheckComplete
	ld8_24 a, 0x02476a
	inc 1, a
	extz wa
	pushw wa
	pushw 0xE7
	pushw 0xFF9E
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C
	jrl PcgOutCheck_SetFinalProp

PcgOutCheck_SendPreset1:
	ld8_24 a, 0x02476c
	inc 1, a
	extz wa
	pushw wa
	pushw 0xE7
	pushw 0xFFA4
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C
	jrl PcgOutCheck_SetFinalProp

PcgOutCheck_SendPreset2:
	cpi8_24 0x024770, 0xff
	jr nz, PcgOutCheck_SendPreset2Named
	pushw 0xE7
	pushw 0xFFAA
	push xbc
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C
	call SendEvent
	ldw (xsp + 6), 0x4
	pushw 0xE7
	pushw 0xFFB0
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C
	jrl PcgOutCheck_SetFinalProp

PcgOutCheck_SendPreset2Named:
	ld8_24 a, 0x02476e
	exts wa
	pushw wa
	pushw 0xE7
	pushw 0xFFB8
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C
	call SendEvent
	ldw (xsp + 6), 0x4
	ld8_24 c, 0x024770
	exts bc
	ld8_24 a, 0x02476e
	exts wa
	sll wa, 7
	add wa, bc
	pushw wa
	pushw 0xE7
	pushw 0xFFBE
	lda xwa, (xsp + 18)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C
	jrl PcgOutCheck_SetFinalProp

PcgOutCheck_SendPreset3:
	ldw (xwa), 0x2
	cpi8_24 0x024770, 0xff
	jr nz, PcgOutCheck_SendPreset3Named
	pushw 0xE7
	pushw 0xFFC6
	push xbc
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C
	call SendEvent
	ldw (xsp + 6), 0x3
	pushw 0xE7
	pushw 0xFFCC
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C
	call SendEvent
	ldw (xsp + 6), 0x4
	pushw 0xE7
	pushw 0xFFD2
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C
	jrl PcgOutCheck_SetFinalProp

PcgOutCheck_SendPreset3Named:
	ld8_24 a, 0x02476e
	exts wa
	pushw wa
	pushw 0xE7
	pushw 0xFFDA
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C
	call SendEvent
	ldw (xsp + 6), 0x3
	ld8_24 a, 0x024770
	exts wa
	pushw wa
	pushw 0xE7
	pushw 0xFFE0
	lda xwa, (xsp + 18)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C
	call SendEvent
	ldw (xsp + 6), 0x4
	ld8_24 c, 0x024770
	exts bc
	ld8_24 a, 0x02476e
	exts wa
	sll wa, 7
	add wa, bc
	pushw wa
	pushw 0xE7
	pushw 0xFFE6
	lda xwa, (xsp + 18)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0008C

PcgOutCheck_SetFinalProp:
	call SendEvent

PcgOutGridCheckComplete:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 44)
	ret

PcgOutSendFunc:
	cp xbc, 0x1C00008
	jr nz, PcgOutSendFunc_Exit
	lda_24 xde, 0x024752
	ld8_24 a, 0x02476a
	ld (xde), a
	ld8_24 a, 0x02476c
	ld (xde + 1), a
	lda xbc, (xde + 2)
	ld8_24 l, 0x024770
	cp l, 0xFF
	jr nz, PcgOutSend_StoreBankIndex
	ldw (xbc), 0xFFFF
	jr PcgOutSend_TransmitMidi

PcgOutSend_StoreBankIndex:
	exts hl
	ld8_24 a, 0x02476e
	exts wa
	sla wa, 7
	add wa, hl
	ld (xbc), wa

PcgOutSend_TransmitMidi:
	ld xwa, 0x1430000
	ld xbc, 0x1E30000
	call MainFuncCall

PcgOutSendFunc_Exit:
	lds32 xhl, 0
	ret

MainPcgOutSend:
	cp xbc, 0x1E30000
	jr nz, MainPcgOutSend_Exit
	ld a, (xde)
	extz wa
	ld c, (xde + 1)
	extz bc
	ld de, (xde + 2)
	call MidiSysEx_BuildAndSend

MainPcgOutSend_Exit:
	lds32 xhl, 0
	ret

; End of Computer Interface PCG routines

