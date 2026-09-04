; =============================================================================
; file_io/filename_password.asm - Filename and Password UI
; =============================================================================
; Password entry and filename input routines.
;
; Key routines:
;   FmmPasswordFunc                  - Password entry dialog
;   FmmFileNameFunc                  - Filename input/display
; =============================================================================

FmmPasswordFunc:
	dec	4, xsp
	push	xiz
	ld	xiz, xde
	ld	(xsp+4), xwa
	ld	wa, iz
	cp	xbc, 31784976
	jrl	z, 339
	lda	xde, (35184:16)
	cp	xbc, 31784975
	jrl	z, 195
	cp	xbc, 31784974
	jr	z, 63
	cp	xbc, 31784973
	jrl	nz, 348
	call	16334389
	cps	l, 0
	jr	nz, 8
	call	16334421
	cps	l, 0
	jr	z, 15
Password_ShowError:
	ld	(32422:16), 10
	ldw	wa, 238
	call	16355504
	jrl	317
Password_ClearAndSetSlot:
	.byte 0xde, 0x88, 0x1d, 0x02, 0x3e, 0xf9, 0xde, 0x88
	.byte 0x1d, 0x3d, 0x3e, 0xf9, 0xf1, 0x71, 0x89, 0x30
	.byte 0xb0, 0xbf, 0xb0, 0xbe, 0x78, 0x26, 0x01
Password_HandleDeleteEvent:
	.byte 0x82, 0x3f, 0x03, 0x6e, 0x26, 0x1d, 0x29, 0x3e
	.byte 0xf9, 0xcf, 0xd8, 0x66, 0x1e, 0xde, 0x88, 0x1d
	.byte 0x49, 0x3e, 0xf9, 0xcf, 0xd8, 0x66, 0x14, 0xf1
	.byte 0x71, 0x89, 0x30, 0xb0, 0xbf, 0xb0, 0xbe, 0xaf
	.byte 0x04, 0x20, 0x41, 0x17, 0x00, 0xc0, 0x01, 0xea
	.byte 0xac, 0x68, 0x40
Password_Delete_CheckLoadOnly:
	.byte 0xc1, 0x70, 0x89, 0x3f, 0x01, 0x6e, 0x1a, 0xde
	.byte 0x88, 0x1d, 0x29, 0x3e, 0xf9, 0xcf, 0xd8, 0x66
	.byte 0x10, 0xf1, 0x71, 0x89, 0xbf, 0xaf, 0x04, 0x20
	.byte 0x41, 0x17, 0x00, 0xc0, 0x01, 0xea, 0xac, 0x68
	.byte 0x1f
Password_Delete_CheckSaveOnly:
	.byte 0xc1, 0x70, 0x89, 0x3f, 0x02, 0x6e, 0x1e, 0xde
	.byte 0x88, 0x1d, 0x49, 0x3e, 0xf9, 0xcf, 0xd8, 0x66
	.byte 0x14, 0xf1, 0x71, 0x89, 0xbe, 0xaf, 0x04, 0x20
	.byte 0x41, 0x17, 0x00, 0xc0, 0x01, 0xea, 0xac
Password_ForwardToFileName:
	calr FmmFileNameFunc
	jrl Password_Return

Password_ShowErrorStatus:
	ld	(32422:16), 11
	ldw	wa, 238
	jrl	166
Password_HandleSaveEvent:
	cp (XDE),0x03
	jr nz, .Lc_f8c61d
	call CheckSlotIsSelected
	cps l, 0
	jr z, .Lc_f8c61d
	ld WA,IZ
	call CheckIsCurrentSlot
	cps l, 0
	jr z, .Lc_f8c61d
	lda xwa, (0x8971:16)
	set 7,(XWA)
	set 6,(XWA)
	ld XWA,(XSP+0x04)
	ld XBC,0x01c00017
	ld XDE,0x0000000a
	jr t, Password_ForwardToSaveFilter
Password_Save_CheckLoadOnly:
.Lc_f8c61d:
	cp (0x8970:16), 0x01
	jr nz, .Lc_f8c641
	ld WA,IZ
	call CheckSlotIsSelected
	cps l, 0
	jr z, .Lc_f8c641
	set 7, (0x8971:16)
	ld XWA,(XSP+0x04)
	ld XBC,0x01c00017
	ld XDE,0x0000000a
	jr t, Password_ForwardToSaveFilter
Password_Save_CheckSaveOnly:
.Lc_f8c641:
	cp (0x8970:16), 0x02
	jr nz, Password_SaveErrorStatus
	ld WA,IZ
	call CheckIsCurrentSlot
	cps l, 0
	jr z, Password_SaveErrorStatus
	set 6, (0x8971:16)
	ld XWA,(XSP+0x04)
	ld XBC,0x01c00017
	ld XDE,0x0000000a
Password_ForwardToSaveFilter:
	calr FmmSaveFilterFunc
	jr Password_Return

Password_SaveErrorStatus:
	ld	(32422:16), 11
	ldw	wa, 238
	jr	35
Password_HandleLoadEvent:
	call CheckSlotIsSelected
	cps l, 0
	jr z, Password_LoadErrorStatus
	set 7, (0x8971:16)
	ld XWA,(XSP+0x04)
	ld XBC,0x01c00017
	lds32 xde, 4
	calr FmmSeqSongNameFunc
	jr t, Password_Return
Password_LoadErrorStatus:
	ld	(32422:16), 11
	ldw	wa, 238
Password_CallStatusDisplay:
	call SoundCtrl_SendCommand

Password_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

SelectPasswordMode:
	push XIZ
	lds_erpb 0xfb, 0
	lds_erpb 0xfa, 0
	lds wa, 2
	call FileIO_FormatName_Return
	cps l, 0
	jr z, .Lc_f8c6c1
	call CheckAnySlotHasData
	cps l, 0
	jr z, .Lc_f8c6c1
	bit 7, (0x8971:16)
	jr nz, .Lc_f8c6c1
	lds_erpb 0xfa, 1
SelectMode_CheckSaveAvail:
.Lc_f8c6c1:
	lds wa, 3
	call FileIO_FormatName_Return
	cps l, 0
	jr z, SelectMode_DetermineMode
	call CheckSlotIndexValid
	cps l, 0
	jr z, SelectMode_DetermineMode
	bit 6, (0x8971:16)
	jr nz, SelectMode_DetermineMode
	lds_erpb 0xfb, 1
SelectMode_DetermineMode:
	cpib_erp 0xfa, 0
	jr z, SelectMode_SingleMode
	cpib_erp 0xfb, 0
	jr z, SelectMode_SingleMode
	call GetCurrentSlotIndex
	ld iz, hl
	call FindFirstEmptySlot
	ldb a, 0x1
	cp hl, iz
	jr nz, SelectMode_SetBothMode
	ldb a, 0x3

SelectMode_SetBothMode:
	ld	(35184:16), a
	jr	25
SelectMode_SingleMode:
	lda	xbc, (35184:16)
	cpib_erp	250, 0
	jr	z, 5
	ld	(xbc), 1
	jr	11
SelectMode_CheckSaveOnlyMode:
	ldb a, 0x0
	cpib_erp 0xfb, 0
	jr z, SelectMode_StoreMode
	ldb a, 0x2

SelectMode_StoreMode:
	ld (xbc), a

SelectMode_Return:
	ld	l, (35184:16)
	extz	hl
	pop	xiz
	ret
FmmFileNameFunc:
	dec	8, xsp
	push	xiz
	ld	xiz, xde
	ld	(xsp+8), xbc
	ld	xbc, xiz
	ld	xwa, (xsp+8)
	cp	xwa, 31784960
	jrl	z, 1476
	cp	xwa, 29360152
	jrl	z, 193
	cp	xwa, 29360151
	jrl	z, 184
	cp	xwa, 29360139
	jr	z, 70
	cp	xwa, 31784964
	jrl	nz, 1544
	ld	(32470:16), xbc
	call	16290274
	ld	(32478:16), hl
	cps	hl, 0
	jr	lt, 15
	exts	xhl
	ld	xwa, (32470:16)
	ld	xbc, 31784962
	ld	xde, xhl
	jr	17
FileName_ListSelect_Negative:
	ldw	(32478:16), 0
	ld	xwa, (32470:16)
	ld	xbc, 31784962
	lds32	xde, 0
FileName_ListSelect_Forward:
	call	16423243
	lds32	xwa, 0
	ld	(32474:16), xwa
	jrl	1483
FileName_HandleShow:
	ldw (xsp + 6), 0x0
FileName_DrawItemLoop:
	ld	wa, (xsp+6)
	ld	hl, wa
	sll	hl, 5
	lda	xde, (33904:16)
	extz	xhl
	add	xhl, xde
	ld	bc, (xsp+6)
	ld	(xhl), c
	call	16290326
	ld	xbc, xhl
	ld	de, (xsp+6)
	ld	wa, de
	sll	wa, 5
	lds	hl, 1
	add	hl, wa
	lda	xix, (33904:16)
	extz	xhl
	add	xhl, xix
	inc	1, de
	pushw 6
	pushw 0
	ld	xwa, xhl
	call	16289232
	ld	de, (xsp+6)
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (32470:16)
	ld	xbc, 29360143
	call	16423243
	incw	1, (xsp+6)
	.byte 0x9f, 0x06, 0x3f, 0x14, 0x00
	jr	lt, -98
	jrl	1377
FileName_HandleScroll:
	.byte 0xbf, 0x06, 0x16, 0xde, 0x7e
	ld	wa, (xsp+6)
	ld	(xsp+4), wa
	or	xiz, xiz
	jr	nz, 46
	ld	xwa, (xsp+8)
	cp	xwa, 29360152
	jr	nz, 13
	.byte 0x9f, 0x06, 0x3f, 0x13, 0x00
	jrl	ge, 970
	incw	1, (xsp+6)
	jr	72
FileName_ScrollUp:
	cp xwa, 0x1c00017
	jrl nz, FileName_GetSelection
	cpw (xsp + 6), 0x0
	jrl le, FileName_GetSelection
	decm 1, (xsp + 6)
	jr FileName_ScrollApply

FileName_PageUp:
	cp xiz, 0x1
	jr nz, FileName_PageDown
	cpw (xsp + 6), 0xa
	jrl lt, FileName_GetSelection
	submi16 (xsp + 6), 0xa
	jr FileName_ScrollApply

FileName_PageDown:
	cp xiz, 0x2
	jr nz, FileName_OpSave
	ld wa, (xsp + 6)
	add wa, 0xa
	cp wa, 0x13
	jrl gt, FileName_GetSelection
	addiw_da (xsp + 6), 0xa

FileName_ScrollApply:
	.byte 0x9f, 0x06, 0x19, 0xde, 0x7e	; mrdw5 0x9f, 0x06, 0x19, 0x7a, 0x7f (v7 displacement)

	ld wa, (xsp + 6)
	jrl	886
FileName_OpSave:
	cp	xiz, 3
	jrl	nz, 170
	call	16289841
	cps	hl, 0
	jrl	z, 161
	call	16289506
	cps	hl, 0
	jrl	z, 152
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	ld	wa, (32478:16)
	extz	wa
	calr	-6531
	lds	wa, 0
	calr	-6843
	call	16283131
	ld	wa, hl
	lds	bc, 1
	calr	-6204
	ld	(32422:16), l
	calr	-6769
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	cpw	(61854:16), 0
	jr	z, 36
	lds	wa, 2
	call	16289512
	cps	l, 0
	jr	z, 26
	lds	wa, 2
	call	16289732
	cps	l, 0
	jr	nz, 11
	ldw	wa, 8
	call	16289732
	cps	l, 0
	jr	z, 5
FileName_OpSave_ShowCodeA:
	ldw wa, 0xa
	jr FileName_OpSave_CallHandler

FileName_OpSave_ShowCode1:
	lds wa, 1

FileName_OpSave_CallHandler:
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	jrl FileName_CallStatusDisplay

FileName_OpLoad:
	cp	xiz, 4
	jrl	nz, 197
	call	16289600
	cps	hl, 0
	jrl	z, 188
	calr	64862
	cps	hl, 0
	jr	z, 19
	lds32	xde, 0
	ld	e, (35184:16)
	ld	xwa, 4294967295
	ld	xbc, 29687812
	jrl	338
FileName_OpLoad_NoPwd:
	call CheckFileSystemStatus
	cps hl, 0
	jr z, FileName_OpLoad_Execute
	cp (0x0340ea:24), 0x00
	jr z, FileName_OpLoad_Execute
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, 0x1c00001
	lds32 xde, 0
	jrl FileName_OpDispatch

FileName_OpLoad_Execute:
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	58459
	call	16284320
	ld	wa, hl
	lds	bc, 5
	calr	59098
	ld	(32422:16), l
	call	16290139
	call	16290094
	call	16290928
	ld	(33894:16), hl
	calr	58517
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	lds	wa, 1
	call	16355414
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	jrl	493
FileName_OpFormat:
	cp	xiz, 50
	jr	nz, 115
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	58336
	call	16284320
	ld	wa, hl
	lds	bc, 5
	calr	58975
	ld	(32422:16), l
	call	16290139
	call	16290094
	call	16290928
	ld	(33894:16), hl
	calr	58394
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	lds	wa, 1
	call	16355414
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	jrl	370
FileName_OpDelete:
	cp xiz, 0x5
	jrl nz, FileName_OpFormatVariant
	call CheckFileSystemStatus
	cps hl, 0
	jr z, FileName_OpFormatVariant
	cp (0x0340ea:24), 0x00
	jr z, FileName_OpDelete_Execute
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0x7b0051
	ld xbc, 0x1c00001
	lds32 xde, 0

FileName_OpDispatch:
	call ApPostEvent
	jrl FileName_GetSelection

FileName_OpDelete_Execute:
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	58161
	call	16286496
	ld	wa, hl
	lds	bc, 5
	calr	58800
	ld	(32422:16), l
	calr	58235
	call	16290139
	call	16290094
	call	16290928
	ld	(33894:16), hl
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	jrl	233
FileName_OpFormatVariant:
	cp	xiz, 51
	jr	nz, 77
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	58076
	call	16286496
	ld	wa, hl
	lds	bc, 5
	calr	58715
	ld	(32422:16), l
	calr	58150
	call	16290139
	call	16290094
	call	16290928
	ld	(33894:16), hl
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	jrl	148
FileName_OpNavigate:
	cp	xiz, 6
	jrl	nz, 143
	call	16289841
	cps	hl, 0
	jrl	z, 134
	ld	xbc, (xsp+8)
	ld	wa, (32478:16)
	cp	xbc, 29360152
	jr	nz, 16
	ld	bc, wa
	cp	wa, 19
	jr	ge, 28
	inc	1, bc
	ld	(32478:16), bc
	jr	20
FileName_Navigate_ScrollUp:
	cp	xbc, 29360151
	jr	nz, 12
	ld	bc, wa
	cps	wa, 0
	jr	le, 6
	dec	1, bc
	ld	(32478:16), bc
FileName_Navigate_CheckChanged:
	ld	wa, (xsp+6)
	cp wa, (32478:16)
	jr	z, 74
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	-7615
	ld	wa, (32478:16)
	call	16286763
	ld	wa, hl
	lds	bc, 5
	calr	-6980
	ld	(32422:16), l
	calr	-7545
	call	16290928
	ld	(33894:16), hl
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
FileName_CallStatusDisplay:
	call SoundCtrl_SendCommand

FileName_GetSelection:
	ld	wa, (32478:16)
FileName_UpdateDisplay:
	cp	(xsp+4), wa
	jrl	z, 363	; -> 0xF8CD60
	call	NotifyUIOfSelectionChange
	ld	(35164:16), 4
	ld	de, (32478:16)
	exts	xde
	ld	xwa, (32470:16)
	ld	xbc, 31784962
	call	ApPostEvent
	ld	de, (xsp+4)
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (32470:16)
	ld	xbc, 29360143
	call	ApPostEvent
	ld	de, (32478:16)
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (32470:16)
	ld	xbc, 29360143
	call	ApPostEvent
	ldw	(xsp+6), 0
FileName_UpdateButtons_Loop:
	ld wa, (xsp + 6)
	extz wa
	call FileIO_CheckRecordValid
	ld wa, (xsp + 6)
	extz wa
	cps l, 0
	jr z, FileName_UpdateButtons_Hide
	call FileIO_FormatName_Loop
	jr FileName_UpdateButtons_Check

FileName_UpdateButtons_Hide:
	call FileIO_FormatName_Copy

FileName_UpdateButtons_Check:
	incw 1, (xsp + 6)
	cpw (xsp + 6), 0x8
	jr lt, FileName_UpdateButtons_Loop
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileName_CheckCallback
	ldw wa, 0x9
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileName_CheckCallback
	lds wa, 2
	call FileIO_FormatName_Loop

FileName_CheckCallback:
	ld	xwa, (32474:16)
	or	xwa, xwa
	jrl	z, 200
	cp	(35994:16), 103
	jr	z, 71
	call	16289841
	ld	iz, hl
	ldw	wa, 8
	call	16289732
	cps	l, 0
	jr	z, 14
	ldw	wa, 9
	call	16289732
	cps	l, 0
	jr	z, 3
	set	2, iz
FileName_Callback_SetFilter:
	call FileIO_WriteRecordName_Loop
	and iz, hl
	bit 0, iz
	jr z, FileName_Callback_Send
	call GetCurrentFileType
	cps l, 0
	jr z, FileName_Callback_Send
	res 0, iz
	set 1, iz

FileName_Callback_Send:
	ld	de, iz
	extz	xde
	ld	xwa, (32474:16)
	ld	xbc, 31784961
	jr	118
FileName_Callback_Simple:
	call	16289600
	extz	xhl
	ld	xwa, (32474:16)
	ld	xbc, 31784961
	ld	xde, xhl
	jr	99
FileName_HandleRegister:
	ld (0x7eda:16), xbc
	cp (0x8c9a:16), 0x67
	jr z, FileName_Register_Simple
	call CheckFileSystemStatus
	ld IZ,HL
	ldw WA, 0x0008
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileName_Register_SetFilter
	ldw WA, 0x0009
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileName_Register_SetFilter
	set 0x02,IZ
FileName_Register_SetFilter:
	call FileIO_WriteRecordName_Loop
	and iz, hl
	bit 0, iz
	jr z, FileName_Register_Send
	call GetCurrentFileType
	cps l, 0
	jr z, FileName_Register_Send
	res 0, iz
	set 1, iz

FileName_Register_Send:
	ld	de, iz
	extz	xde
	ld	xwa, (32474:16)
	ld	xbc, 31784961
	jr	17
FileName_Register_Simple:
	call	16289600
	extz	xhl
	ld	xwa, (32474:16)
	ld	xbc, 31784961
	ld	xde, xhl
FileName_DispatchWidget:
	call ApPostEvent

FileName_Return:
	lds32 xhl, 0
	pop xiz
	inc 8, xsp
	ret

