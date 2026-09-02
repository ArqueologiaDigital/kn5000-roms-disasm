; =============================================================================
; file_io/composer_filters.asm - Composer Load and Filter Operations
; =============================================================================
; Composer file loading and load/save filter routines.
;
; Key routines:
;   FmmComposerLoadFunc              - Composer file loading
;   FmmLoadFilterFunc                - Load filter settings
;   FmmSaveFilterFunc                - Save filter settings
; =============================================================================

FmmComposerLoadFunc:
	.byte 0xef, 0x6a, 0x2e, 0xe9, 0xcf, 0x18, 0x00, 0xc0
	.byte 0x01, 0x76, 0x01, 0x02, 0xe9, 0xcf, 0x17, 0x00
	.byte 0xc0, 0x01, 0x76, 0xf8, 0x01, 0xe9, 0xcf, 0x0b
	.byte 0x00, 0xc0, 0x01, 0x76, 0x7a, 0x01, 0xe9, 0xcf
	.byte 0x04, 0x00, 0xe5, 0x01, 0x76, 0x3d, 0x01, 0xe9
	.byte 0xcf, 0x13, 0x00, 0xc0, 0x01, 0x7e, 0x27, 0x03
	.byte 0xea, 0xcf, 0x03, 0x00, 0x00, 0x00, 0x76, 0x25
	.byte 0x01, 0xea, 0xcf, 0x02, 0x00, 0x00, 0x00, 0x7e
	.byte 0x15, 0x03, 0xf1, 0x62, 0x84, 0x00, 0x00, 0xd8
	.byte 0xa9, 0x1e, 0x45, 0xe0, 0x40, 0x26, 0x00, 0x60
	.byte 0x00, 0x41, 0x01, 0x00, 0xc0, 0x01, 0xea, 0xad
	.byte 0x1d, 0x4b, 0x99, 0xfa, 0xd1, 0x64, 0x84, 0x3f
	.byte 0x00, 0x00, 0x69, 0x0d, 0x1d, 0x13, 0x91, 0xf8
	.byte 0xdb, 0x12, 0xf1, 0x64, 0x84, 0x53, 0x1e, 0x7c
	.byte 0xe0
CompLoad_DispatchState:
	.byte 0xd1, 0x64, 0x84, 0x20, 0xd8, 0xd9, 0x76, 0x9c
	.byte 0x00, 0xd8, 0xd8, 0x66, 0x7e, 0xd8, 0xdd, 0x66
	.byte 0x3a, 0xd1, 0x66, 0x84, 0x3f, 0x00, 0x00, 0x69
	.byte 0x13, 0x1d, 0x70, 0x94, 0xf8, 0xf1, 0x66, 0x84
	.byte 0x53, 0x1d, 0x80, 0x91, 0xf8, 0x1d, 0x2e, 0x91
	.byte 0xf8, 0x1e, 0x50, 0xe0
CompLoad_ContinueWait:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	jrl CompLoad_DispatchWidget

CompLoad_HandleCancel:
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
	ld	(32422:16), 0
	ldw	wa, 238
	jr	91
CompLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	call UI_PostModeChangeEvent
	jrl CompLoad_Return

CompLoad_HandleSuccess:
	calr	57104
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
	ld	(32422:16), 2
	ldw	wa, 238
CompLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jrl CompLoad_Return

CompLoad_HandleAbort:
	calr CancelOperationCleanup
	jrl CompLoad_Return

CompLoad_HandleSelection:
	ld	(32480:16), xde
	call	16290274
	ld	(32484:16), hl
	cps	hl, 0
	jr	lt, 16
	exts	xhl
	ld	xwa, (32480:16)
	ld	xbc, 31784962
	ld	xde, xhl
	jrl	463
CompLoad_Selection_Negative:
	ldw	(32484:16), 0
	ld	xwa, (32480:16)
	ld	xbc, 31784962
	lds32	xde, 0
	jrl	443
CompLoad_HandleShow:
	lds iz, 0

CompLoad_DrawItemLoop:
	ld	wa, iz
	ld	hl, wa
	sll	hl, 5
	lda	xde, (33904:16)
	extz	xhl
	add	xhl, xde
	stb_erp	c, 248
	ld	(xhl), c
	lds	bc, 3
	call	16289787
	cps	l, 0
	jr	z, 10
	ld	wa, iz
	call	16290326
	ld	xbc, xhl
	jr	5
CompLoad_DrawItem_Empty:
	lda xbc, (DiskOp_ChannelCfgTable_0x80:24)

CompLoad_DrawItem_Continue:
	ld	de, iz
	ld	wa, de
	sll	wa, 5
	lds	hl, 1
	add	hl, wa
	lda	xix, (33904:16)
	extz	xhl
	add	xhl, xix
	inc	1, de
	pushw	6
	pushw	0
	ld	xwa, xhl
	call	16289232
	ld	de, iz
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (32480:16)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cp	iz, 20
	jr	lt, -112
	jrl	330
CompLoad_HandleScroll:
	ld	wa, (32484:16)
	ld	(xsp+2), wa
	or	xde, xde
	jr	nz, 37
	cp	xbc, 29360152
	jr	nz, 11
	cp	wa, 19
	jrl	ge, 217
	inc	1, wa
	jr	64
CompLoad_ScrollUp:
	cp xbc, 0x1c00017
	jrl nz, CompLoad_GetSelection
	cps wa, 0
	jrl le, CompLoad_GetSelection
	dec 1, wa
	jr CompLoad_StorePosition

CompLoad_PageScroll:
	cp xde, 0x1
	jr nz, CompLoad_PageDown
	cp wa, 0xa
	jrl lt, CompLoad_GetSelection
	sub wa, 0xa
	jr CompLoad_StorePosition

CompLoad_PageDown:
	cp xde, 0x2
	jr nz, CompLoad_OpLoad
	ld bc, wa
	add bc, 0xa
	cp bc, 0x13
	jrl gt, CompLoad_GetSelection
	add wa, 0xa

CompLoad_StorePosition:
	ld	(32484:16), wa
	jrl	146
CompLoad_OpLoad:
	cp xde, 0x3
	jrl nz, CompLoad_GetSelection
	call CheckFileSystemStatus
	cps hl, 0
	jr z, CompLoad_GetSelection
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds iz, 0
CompLoad_HideButtons_Loop:
	stb_erp	a, 248
	extz	wa
	call	16289576
	inc	1, iz
	cp	iz, 8
	jr	lt, -17
	lds	wa, 3
	call	16289556
	lds	wa, 0
	calr	-8736
	call	16283131
	ld	wa, hl
	lds	bc, 1
	calr	-8097
	ld	(32422:16), l
	calr	-8662
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
	call	16355504
CompLoad_GetSelection:
	ld	wa, (32484:16)
CompLoad_UpdateDisplay:
	cp	(xsp+2), wa
	jr	z, 78
	call	16290296
	ld	de, (32484:16)
	exts	xde
	ld	xwa, (32480:16)
	ld	xbc, 31784962
	call	16423243
	ld	de, (xsp+2)
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (32480:16)
	ld	xbc, 29360143
	call	16423243
	ld	de, (32484:16)
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (32480:16)
	ld	xbc, 29360143
CompLoad_DispatchWidget:
	call ApPostEvent

CompLoad_Return:
	lds32 xhl, 0
	popw iz
	inc 2, xsp
	ret

RenderFilterDisplay:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ld c, (xsp)
	lda_dpi XHL, 0xe0
	ld (xsp + 2), xwa
	cp (xsp), 0x0
	jr nz, RenderFilter_CheckType1
	call GetCurrentFileType
	cps l, 0
	jr z, RenderFilter_CheckType1
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0x82
	jrl RenderFilter_CopyAndReturn

RenderFilter_CheckType1:
	cp (xsp), 0x1
	jr nz, RenderFilter_CheckGeneric
	call GetCurrentFileType
	cps l, 0
	jr z, RenderFilter_CheckGeneric
	lds wa, 0
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, RenderFilter_Type1_Unavail
	lds wa, 0
	call FileIO_WriteRecordName_Done
	cps l, 0
	jr z, RenderFilter_Type1_Restricted
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0x88
	jrl RenderFilter_CopyAndReturn

RenderFilter_Type1_Restricted:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0x8E
	jr RenderFilter_CopyAndReturn

RenderFilter_Type1_Unavail:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0x94
	jr RenderFilter_CopyAndReturn

RenderFilter_CheckGeneric:
	ld a, (xsp)
	extz wa
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, RenderFilter_CheckType2
	ld a, (xsp)
	extz wa
	call FileIO_WriteRecordName_Done
	cps l, 0
	jr z, RenderFilter_Generic_Restricted
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0x9A
	jr RenderFilter_CopyAndReturn

RenderFilter_Generic_Restricted:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xA0
	jr RenderFilter_CopyAndReturn

RenderFilter_CheckType2:
	cp (xsp), 0x2
	jr nz, RenderFilter_Default
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, RenderFilter_Default
	ldw wa, 0x9
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, RenderFilter_Default
	ld a, (xsp)
	extz wa
	call FileIO_WriteRecordName_Done
	cps l, 0
	jr z, RenderFilter_Type2_Restricted
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xA6
	jr RenderFilter_CopyAndReturn

RenderFilter_Type2_Restricted:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xAC
	jr RenderFilter_CopyAndReturn

RenderFilter_Default:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xB2

RenderFilter_CopyAndReturn:
	call FileIO_CopyString
	inc 6, xsp
	ret

FmmLoadFilterFunc:
	dec	6, xsp
	ld	(xsp+2), xde
	cp	xbc, 29360152
	jr	z, 96
	cp	xbc, 29360151
	jr	z, 88
	cp	xbc, 29360139
	jr	z, 19
	cp	xbc, 31784964
	jrl	nz, 425
	ld	xwa, (xsp+2)
	ld	(32486:16), xwa
	jrl	415
LoadFilter_HandleShow:
	ldw (xsp), 0x0

LoadFilter_DrawLoop:
	.byte 0x97, 0x20, 0xd8, 0xee, 0x04, 0xf1, 0xea, 0x7e
	.byte 0x31, 0xe8, 0x12, 0xe9, 0x80, 0x97, 0x21, 0xd9
	.byte 0x12, 0x1e, 0xd8, 0xfe, 0x97, 0x22, 0xda, 0xee
	.byte 0x04, 0xf1, 0xea, 0x7e, 0x31, 0xea, 0x12, 0xe9
	.byte 0x82, 0xe1, 0xe6, 0x7e, 0x20, 0x41, 0x0f, 0x00
	.byte 0xc0, 0x01, 0x1d, 0x4b, 0x99, 0xfa, 0x97, 0x61
	.byte 0x97, 0x3f, 0x08, 0x00, 0x61, 0xca, 0x78, 0x62
	.byte 0x01
LoadFilter_HandleScroll:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jrl nc, LoadFilter_OpLoad
	cp xbc, 0x1c00017
	jr nz, LoadFilter_ScrollDown
	cp xwa, 0x1
	jr nz, LoadFilter_ScrollUp_CheckZero
	call GetCurrentFileType
	cps l, 0
	jr z, LoadFilter_ScrollUp_CheckZero
	lds wa, 0
	jr LoadFilter_ShowButton

LoadFilter_ScrollUp_CheckZero:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LoadFilter_ScrollUp_Restore
	call GetCurrentFileType
	cps l, 0
	jr nz, LoadFilter_UpdateDisplay

LoadFilter_ScrollUp_Restore:
	ld xwa, (xsp + 2)
	extz wa

LoadFilter_ShowButton:
	call FileIO_FormatName_Loop
	jr LoadFilter_UpdateDisplay

LoadFilter_ScrollDown:
	ld xwa, (xsp + 2)
	cp xwa, 0x1
	jr nz, LoadFilter_ScrollDown_CheckZero
	call GetCurrentFileType
	cps l, 0
	jr z, LoadFilter_ScrollDown_CheckZero
	lds wa, 0
	jr LoadFilter_HideButton

LoadFilter_ScrollDown_CheckZero:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LoadFilter_ScrollDown_Restore
	call GetCurrentFileType
	cps l, 0
	jr nz, LoadFilter_UpdateDisplay

LoadFilter_ScrollDown_Restore:
	ld xwa, (xsp + 2)
	extz wa

LoadFilter_HideButton:
	call FileIO_FormatName_Copy

LoadFilter_UpdateDisplay:
	ld	xwa, (xsp+2)
	ld	c, a
	extz	bc
	ld	wa, bc
	sla	wa, 4
	lda	xde, (32490:16)
	exts	xwa
	add	xwa, xde
	calr	-469
	ld	xwa, (xsp+2)
	extz	wa
	sla	wa, 4
	lda	xbc, (32490:16)
	lda_rr	xde, xbc, wa
	ld	xwa, (32486:16)
	ld	xbc, 29360143
	call	16423243
	jrl	185
LoadFilter_OpLoad:
	ld XWA,(XSP+0x02)
	cp XWA,0x0000000a
	jrl nz, LoadFilter_Return
	call CheckFileSystemStatus
	cps hl, 0
	jrl z, LoadFilter_Return
	call FileIO_WriteRecordName_Loop
	cps hl, 0
	jrl z, LoadFilter_Return
	ld XWA,0x00600026
	ld XBC,0x01c00001
	lds32 xde, 5
	call ApPostEvent
	call GetCurrentFileIndex
	extz HL
	ld WA,HL
	calr FileIO_MidiOutSendByte
	lds wa, 0
	calr InitializeOperationState
	call FileIO_ParseDirectoryEntry
	ld WA,HL
	lds bc, 1
	calr FileIO_ValidateSignedValue
	ld (0x7ea6:16), l
	calr SignalProgressUpdate
	ld XWA,0x00600026
	ld XBC,0x01c00002
	lds32 xde, 0
	call ApPostEvent
	ld XWA,0xffffffff
	ld XBC,0x01e0009e
	lds32 xde, 1
	call ApPostEvent
	cpdi16 (0xf19e), 0x0000
	jr z, LoadFilter_Load_ShowCode1
	lds wa, 2
	call FileIO_WriteRecordName_Done
	cps l, 0
	jr z, LoadFilter_Load_ShowCode1
	lds wa, 2
	call FileIO_CheckRecordValid
	cps l, 0
	jr nz, LoadFilter_Load_ShowCodeA
	ldw WA, 0x0008
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, LoadFilter_Load_ShowCode1
LoadFilter_Load_ShowCodeA:
	ldw wa, 0xa
	jr LoadFilter_Load_CallHandler

LoadFilter_Load_ShowCode1:
	lds wa, 1

LoadFilter_Load_CallHandler:
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	call SoundCtrl_SendCommand

LoadFilter_Return:
	lds32 xhl, 0
	inc 6, xsp
	ret

RenderSaveFilterDisplay:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ld c, (xsp)
	lda_dpi XHL, 0xe0
	ld (xsp + 2), xwa
	ld a, c
	extz wa
	call FileIO_FormatName_Return
	cps l, 0
	jr z, RenderSaveFilter_Unavail
	cp (xsp), 0x1
	jr nz, RenderSaveFilter_Available
	call FileIO_GetRecordAttr_Check
	cps l, 0
	jr z, RenderSaveFilter_Available
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xB8
	jr RenderSaveFilter_CopyAndReturn

RenderSaveFilter_Available:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xBE
	jr RenderSaveFilter_CopyAndReturn

RenderSaveFilter_Unavail:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xC4

RenderSaveFilter_CopyAndReturn:
	call FileIO_CopyString
	inc 6, xsp
	ret

FmmSaveFilterFunc:
	dec	6, xsp
	ld	(xsp+2), xde
	cp	xbc, 29360152
	jr	z, 96
	cp	xbc, 29360151
	jr	z, 88
	cp	xbc, 29360139
	jr	z, 19
	cp	xbc, 31784964
	jrl	nz, 848
	ld	xwa, (xsp+2)
	ld	(32618:16), xwa
	jrl	838
SaveFilter_HandleShow:
	ldw (xsp), 0x0

SaveFilter_DrawLoop:
	.byte 0x97, 0x20, 0xd8, 0xee, 0x04, 0xf1, 0x6e, 0x7f
	.byte 0x31, 0xe8, 0x12, 0xe9, 0x80, 0x97, 0x21, 0xd9
	.byte 0x12, 0x1e, 0x6a, 0xff, 0x97, 0x22, 0xda, 0xee
	.byte 0x04, 0xf1, 0x6e, 0x7f, 0x31, 0xea, 0x12, 0xe9
	.byte 0x82, 0xe1, 0x6a, 0x7f, 0x20, 0x41, 0x0f, 0x00
	.byte 0xc0, 0x01, 0x1d, 0x4b, 0x99, 0xfa, 0x97, 0x61
	.byte 0x97, 0x3f, 0x08, 0x00, 0x61, 0xca, 0x78, 0x09
	.byte 0x03
SaveFilter_HandleScroll:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jrl nc, SaveFilter_SelectAll
	cp xwa, 0x1
	jr nz, SaveFilter_ScrollOther
	cp xbc, 0x1c00017
	jr nz, SaveFilter_ScrollDown
	call FileIO_GetRecordAttr_Check
	cps l, 0
	jr z, SaveFilter_ScrollUp_Unavail
	call FileIO_SetModeFlag_Reading
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_UnlockFilter

SaveFilter_ScrollUp_Unavail:
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_LockFilter

SaveFilter_ScrollDown:
	ld xwa, (xsp + 2)
	extz wa
	call FileIO_FormatName_Return
	cps l, 0
	jr z, SaveFilter_ScrollDown_Unlock
	call FileIO_GetRecordAttr_Check
	cps l, 0
	jr nz, SaveFilter_UpdateDisplay
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_UnlockFilter

SaveFilter_ScrollDown_Unlock:
	call FileIO_GetRecordAttr_Check
	cps l, 0
	jr nz, SaveFilter_UpdateDisplay
	call FileIO_SetModeFlag_Writing
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_LockFilter

SaveFilter_ScrollOther:
	ld xwa, (xsp + 2)
	extz wa
	cp xbc, 0x1c00017
	jr nz, SaveFilter_UnlockFilter

SaveFilter_LockFilter:
	call FileIO_BuildRecordPath_Done
	jr SaveFilter_UpdateDisplay

SaveFilter_UnlockFilter:
	call FileIO_BuildRecordPath_Return

SaveFilter_UpdateDisplay:
	ld	xwa, (xsp+2)
	ld	c, a
	extz	bc
	ld	wa, bc
	sla	wa, 4
	lda	xde, (32622:16)
	exts	xwa
	add	xwa, xde
	calr	-334
	ld	xwa, (xsp+2)
	extz	wa
	sla	wa, 4
	lda	xbc, (32622:16)
	lda_rr	xde, xbc, wa
	ld	xwa, (32618:16)
	ld	xbc, 29360143
	jrl	270
SaveFilter_SelectAll:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jr nz, SaveFilter_DeselectAll
	call FileIO_SetModeFlag_Reading
	ldw (xsp), 0x0

SaveFilter_SelectAll_Loop:
	ld wa, (xsp)
	extz wa
	cpw (xsp), 0x6
	jr ge, SaveFilter_SelectAll_Unlock
	call FileIO_BuildRecordPath_Done
	jr SaveFilter_SelectAll_Update

SaveFilter_SelectAll_Unlock:
	call FileIO_BuildRecordPath_Return

SaveFilter_SelectAll_Update:
	.byte 0x97, 0x20, 0xd8, 0xee, 0x04, 0xf1, 0x6e, 0x7f
	.byte 0x31, 0xe8, 0x12, 0xe9, 0x80, 0x97, 0x21, 0xd9
	.byte 0x12, 0x1e, 0x5a, 0xfe, 0x97, 0x22, 0xda, 0xee
	.byte 0x04, 0xf1, 0x6e, 0x7f, 0x31, 0xea, 0x12, 0xe9
	.byte 0x82, 0xe1, 0x6a, 0x7f, 0x20, 0x41, 0x0f, 0x00
	.byte 0xc0, 0x01, 0x1d, 0x4b, 0x99, 0xfa, 0x97, 0x61
	.byte 0x97, 0x3f, 0x08, 0x00, 0x61, 0xb6, 0x78, 0xf9
	.byte 0x01
SaveFilter_DeselectAll:
	ld xwa, (xsp + 2)
	cp xwa, 0x9
	jr nz, SaveFilter_OpSave
	call FileIO_SetModeFlag_Reading
	ldw (xsp), 0x0
SaveFilter_DeselectAll_Loop:
	ld	wa, (xsp)
	extz	wa
	call	16289650
	ld	wa, (xsp)
	sll	wa, 4
	lda	xbc, (32622:16)
	extz	xwa
	add	xwa, xbc
	ld	bc, (xsp)
	extz	bc
	calr	-506
	ld	de, (xsp)
	sll	de, 4
	lda	xbc, (32622:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (32618:16)
	ld	xbc, 29360143
	call	16423243
	incw	1, (xsp)
	.byte 0x97, 0x3f, 0x08, 0x00
	jr	lt, -62
	jrl	421
SaveFilter_OpSave:
	ld	xwa, (xsp+2)
	cp	xwa, 10
	jrl	nz, 199
	call	16289600
	cps	hl, 0
	jrl	z, 190
	calr	61681
	cps	hl, 0
	jr	z, 18
	lds32	xde, 0
	ld	e, (35184:16)
	ld	xwa, 4294967295
	ld	xbc, 29687812
	jr	44
SaveFilter_Save_NoPwd:
	call CheckFileSystemStatus
	cps hl, 0
	jr z, SaveFilter_Save_Execute
	cpib_da (0x0340ea), 0x00
	jr z, SaveFilter_Save_Execute
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, 0x1c00001
	lds32 xde, 0

SaveFilter_DispatchWidget:
	call ApPostEvent
	jrl SaveFilter_Return

SaveFilter_Save_Execute:
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	55275
	call	16284320
	ld	wa, hl
	lds	bc, 5
	calr	55914
	ld	(32422:16), l
	call	16290139
	call	16290094
	call	16290928
	ld	(33894:16), hl
	calr	55333
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
	jr	123
SaveFilter_OpFormat:
	ld	xwa, (xsp+2)
	cp	xwa, 50
	jr	nz, 118
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	55150
	call	16284320
	ld	wa, hl
	lds	bc, 5
	calr	55789
	ld	(32422:16), l
	call	16290139
	call	16290094
	call	16290928
	ld	(33894:16), hl
	calr	55208
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
SaveFilter_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jr SaveFilter_Return

SaveFilter_ResetAll:
	ld xwa, (xsp + 2)
	cp xwa, 0xb
	jr nz, SaveFilter_Return
	call FileIO_SetModeFlag_Reading
	ldw (xsp), 0x0

SaveFilter_ResetAll_Loop:
	.byte 0x97, 0x20, 0xd8, 0x12, 0x1d, 0x86, 0x8f, 0xf8
	.byte 0x97, 0x20, 0xd8, 0xee, 0x04, 0xf1, 0x6e, 0x7f
	.byte 0x31, 0xe8, 0x12, 0xe9, 0x80, 0x97, 0x21, 0xd9
	.byte 0x12, 0x1e, 0x5e, 0xfc, 0x97, 0x22, 0xda, 0xee
	.byte 0x04, 0xf1, 0x6e, 0x7f, 0x31, 0xea, 0x12, 0xe9
	.byte 0x82, 0xe1, 0x6a, 0x7f, 0x20, 0x41, 0x0f, 0x00
	.byte 0xc0, 0x01, 0x1d, 0x4b, 0x99, 0xfa, 0x97, 0x61
	.byte 0x97, 0x3f, 0x08, 0x00, 0x61, 0xc2
SaveFilter_Return:
	lds32 xhl, 0
	inc 6, xsp
	ret

