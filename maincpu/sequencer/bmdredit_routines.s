; =============================================================================
; Bitmap Drum Editor
; =============================================================================
;
; Bitmap drum editor: stream positioning, sequence display,
; and voice allocation UI. Provides the graphical drum pattern
; editing interface.
; =============================================================================

BmDrEdit_AdvanceStreamPos:
	ld16_24 xwa, 0x0210a6
	cp wa, 0xFF
	jr nc, BmDrEdit_AdvanceStreamWrap
	inc 1, wa
	st16_24 0x0210a6, xwa
	ret

BmDrEdit_AdvanceStreamWrap:
	ld16_24 xbc, 0x0210a4
	dec 1, bc
	extz xbc
	sll xbc, 8
	lda xwa, (xbc + 4)
	lda_24 xde, 0x0b0000
	ld xhl, xde
	add xhl, xwa
	ld l, (xhl)
	extz hl
	sll hl, 8
	lda xwa, (xbc + 3)
	add xde, xwa
	ld a, (xde)
	extz wa
	add wa, hl
	st16_24 0x0210a4, xwa
	sti16_24 0x0210a6, 0x0005
	ret

BmDrEdit_ScanForwardInit:
	pushw iz
	ldda16 xwa, 10238
	stda16 10230, xwa
	ldda16 xwa, 10240
	stda16 10232, xwa
	ldda16 xwa, 10242
	stda16 10234, xwa
	ldda16 xwa, 10244
	stda16 10236, xwa
	ldmmw_dd24 0xA0, 0x10, 0x02, 0xFE, 0x27
	ldmmw_dd24 0xA2, 0x10, 0x02, 0x00, 0x28
	ldmmw_dd24 0xA4, 0x10, 0x02, 0x02, 0x28
	ldmmw_dd24 0xA6, 0x10, 0x02, 0x04, 0x28
	ldmmb_dd24 0xA8, 0x10, 0x02, 0x22, 0x28
	ldmmb_dd24 0xAA, 0x10, 0x02, 0x24, 0x28
	lds iz, 0
	ldda8 a, 10100
	extz wa
	cps wa, 0
	jrl ule, BmDrEdit_ScanForward_Done

BmDrEdit_ScanForwardLoop:
	ld16_24 xbc, 0x0210a6
	extz xbc
	ld16_24 xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xB0000
	add xbc, xwa
	ld a, (xbc)
	cp a, 0x82
	jrl z, BmDrEdit_ScanForward_Done
	cp a, 0x84
	jrl z, BmDrEdit_ScanForward_Done
	cp a, 0x81
	jr nz, BmDrEdit_ScanForward_CheckNote
	inc 1, iz
	incdi16_24 1, 135328
	jr BmDrEdit_ScanForward_NextByte

BmDrEdit_ScanForward_CheckNote:
	and a, 0xF0
	cp a, 0x90
	jr nz, BmDrEdit_ScanForward_NextByte
	calr BmDrEdit_AdvanceStreamPos
	ld16_24 xbc, 0x0210a6
	extz xbc
	ld16_24 xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xB0000
	add xbc, xwa
	ld a, (xbc)
	extz wa
	st16_24 0x0210a2, xwa
	calr BmDrEdit_AdvanceStreamPos
	ld16_24 xbc, 0x0210a6
	extz xbc
	ld16_24 xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xB0000
	add xbc, xwa
	ld a, (xbc)
	stda8 10246, a
	cpda8_24 a, 135336
	jr c, BmDrEdit_ScanForward_NextByte
	cpda8_24 a, 135338
	call_24 ule, 0xF360BC

BmDrEdit_ScanForward_NextByte:
	calr BmDrEdit_AdvanceStreamPos
	ld16_24 xbc, 0x0210a6
	extz xbc
	ld16_24 xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xB0000
	add xbc, xwa
	ld a, (xbc)
	bit 7, a
	jr z, BmDrEdit_ScanForward_NextByte
	ldda8 a, 10100
	extz wa
	cp iz, wa
	jrl c, BmDrEdit_ScanForwardLoop

BmDrEdit_ScanForward_Done:
	popw iz
	ret

BmDrEdit_ScanBackwardInit:
	pushw iz
	ldmm16 10230, 10238
	ldmm16 10232, 10240
	ldmm16 10234, 10242
	ldmm16 10236, 10244
	ldmmw_dd24 0xA0, 0x10, 0x02, 0xFE, 0x27
	ldmmw_dd24 0xA2, 0x10, 0x02, 0x00, 0x28
	ldmmw_dd24 0xA4, 0x10, 0x02, 0x02, 0x28
	ldmmw_dd24 0xA6, 0x10, 0x02, 0x04, 0x28
	ldmmb_dd24 0xA8, 0x10, 0x02, 0x22, 0x28
	ldmmb_dd24 0xAA, 0x10, 0x02, 0x24, 0x28
	lds iz, 0
	ldda8 a, 10100
	extz wa
	cps wa, 0
	jrl ule, BmDrEdit_ScanBackward_Done

BmDrEdit_ScanBackwardLoop:
	ld16_24 xbc, 0x0210a6
	extz xbc
	ld16_24 xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xB0000
	add xbc, xwa
	ld a, (xbc)
	cp a, 0x82
	jrl z, BmDrEdit_ScanBackward_Done
	cp a, 0x84
	jrl z, BmDrEdit_ScanBackward_Done
	cp a, 0x81
	jr nz, BmDrEdit_ScanBackward_CheckNote
	inc 1, iz
	incdi16 1, 10238
	jr BmDrEdit_ScanBackward_NextByte

BmDrEdit_ScanBackward_CheckNote:
	and a, 0xF0
	cp a, 0x90
	jr nz, BmDrEdit_ScanBackward_NextByte
	ldda16 xwa, 10242
	cpda16 xwa, 10086
	jr nz, BmDrEdit_ScanBackward_ReadNoteParams
	ldda16 xwa, 10244
	cpda16 xwa, 10088
	jr z, BmDrEdit_ScanBackward_NextByte

BmDrEdit_ScanBackward_ReadNoteParams:
	calr BmDrEdit_AdvanceStreamPos
	ld16_24 xbc, 0x0210a6
	extz xbc
	ld16_24 xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xB0000
	add xbc, xwa
	ld a, (xbc)
	extz wa
	stda16 10240, xwa
	calr BmDrEdit_AdvanceStreamPos
	ld16_24 xbc, 0x0210a6
	extz xbc
	ld16_24 xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xB0000
	add xbc, xwa
	ld a, (xbc)
	stda8 10246, a
	cpda8_24 a, 135336
	jr c, BmDrEdit_ScanBackward_NextByte
	cpda8_24 a, 135338
	call_24 ule, 0xF360BC

BmDrEdit_ScanBackward_NextByte:
	calr BmDrEdit_AdvanceStreamPos
	ld16_24 xbc, 0x0210a6
	extz xbc
	ld16_24 xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xB0000
	add xbc, xwa
	ld a, (xbc)
	bit 7, a
	jr z, BmDrEdit_ScanBackward_NextByte
	ldda8 a, 10100
	extz wa
	cp iz, wa
	jrl c, BmDrEdit_ScanBackwardLoop

BmDrEdit_ScanBackward_Done:
	popw iz
	ret

BmDrEdit_RenderNoteBlock:
	dec 8, xsp
	calr BmDrEdit_CalcNotePosition
	call GetTitleNow
	cp xhl, 0x1A00095
	jr nz, BmDrEdit_RenderNoteBlock_Vertical
	calr BmDrEdit_RenderHorizontal
	jr BmDrEdit_RenderNoteBlock_StoreCoords

BmDrEdit_RenderNoteBlock_Vertical:
	calr BmDrEdit_RenderVertical

BmDrEdit_RenderNoteBlock_StoreCoords:
	lda xwa, (xsp)
	ldmw2 (xwa), 0x27BA
	ldmw2 (xwa + 4), 0x27BC
	ldmw2 (xwa + 2), 0x27BE
	ldmw2 (xwa + 6), 0x27C0
	lds bc, 0
	call DrawFrame
	inc 8, xsp
	ret

BmDrEdit_CalcNotePosition:
	push_werp 0xFA
	ld16_24 xbc, 0x0210a0
	mul bc, 0x60
	addda16_24 xbc, 135330
	ldda16 xwa, 10230
	mul wa, 0x60
	addda16 xwa, 10232
	sub bc, wa
	stda16 10248, xbc
	ld8_24 a, 0x0210a8
	subdm8 10246, a
	call GetTitleNow
	cp xhl, 0x1A00095
	jr nz, BmDrEdit_CalcNotePos_VerticalMode
	cpdi8 10136, 0
	jr nz, BmDrEdit_CalcNotePos_ReadFields
	incdi8 3, 10246
	jr BmDrEdit_CalcNotePos_ReadFields

BmDrEdit_CalcNotePos_VerticalMode:
	ldb a, 0xB
	subda8 a, 10246
	stda8 10246, a

BmDrEdit_CalcNotePos_ReadFields:
	calr BmDrEdit_AdvanceStreamPos
	calr BmDrEdit_AdvanceStreamPos
	ld16_24 xbc, 0x0210a6
	extz xbc
	ld16_24 xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xB0000
	add xbc, xwa
	ld a, (xbc)
	ldfr_berp A, 0xFB
	calr BmDrEdit_AdvanceStreamPos
	ld16_24 xbc, 0x0210a6
	extz xbc
	ld16_24 xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xB0000
	add xbc, xwa
	ld c, (xbc)
	res_erpb 0xFB, 0x07
	res 7, c
	extz bc
	mul bc, 0x60
	ldto_berp A, 0xFB
	extz wa
	add bc, wa
	stda16 10250, xbc
	ldda8 l, 10100
	mul l, 0x60
	dec 1, hl
	ldda16 xwa, 10248
	ld de, wa
	add de, bc
	cp de, hl
	jr ule, BmDrEdit_CalcNotePos_ClampSize
	sub hl, wa
	stda16 10250, xhl

BmDrEdit_CalcNotePos_ClampSize:
	pop_werp 0xFA
	ret

BmDrEdit_RenderHorizontal:
	ldda16 xwa, 10248
	srl wa, 2
	add wa, 0x16
	stda16 10170, xwa
	ldda16 xwa, 10250
	srl wa, 2
	addda16 xwa, 10170
	stda16 10172, xwa
	ldda8 a, 10246
	extz wa
	add wa, wa
	lda_24 xbc, 0xe33702
	ldmm_sriw 0x07, 0xE4, 0xE0, 0xBE, 0x27
	ldda16 xwa, 10174
	inc 3, wa
	stda16 10176, xwa
	ret

BmDrEdit_RenderVertical:
	ldda16 xwa, 10248
	srl wa, 2
	add wa, 0x5B
	stda16 10170, xwa
	ldda16 xwa, 10250
	srl wa, 2
	addda16 xwa, 10170
	stda16 10172, xwa
	ldda8 a, 10246
	extz wa
	add wa, wa
	lda_24 xbc, 0xe3373c
	ldmm_sriw 0x07, 0xE4, 0xE0, 0xBE, 0x27
	ldda16 xwa, 10174
	inc 3, wa
	stda16 10176, xwa
	ret

BmDrEdit_RenderSecondaryBlock:
	dec 8, xsp
	ldmmb_dd24 0xB0, 0x10, 0x02, 0x1C, 0x28
	ldmmw_dd24 0xB2, 0x10, 0x02, 0x20, 0x28
	calr BmDrEdit_CalcSecondaryPosition
	call GetTitleNow
	cp xhl, 0x1A00095
	jr nz, BmDrEdit_RenderSecondary_Vertical
	calr BmDrEdit_RenderSecondaryHoriz
	jr BmDrEdit_RenderSecondary_StoreCoords

BmDrEdit_RenderSecondary_Vertical:
	calr BmDrEdit_RenderSecondaryVert

BmDrEdit_RenderSecondary_StoreCoords:
	lda xwa, (xsp)
	ldmw2 (xwa), 0x27C2
	ldmw2 (xwa + 4), 0x27C4
	ldmw2 (xwa + 2), 0x27C6
	ldmw2 (xwa + 6), 0x27C8
	lds bc, 0
	lds de, 0
	call DrawDesignBox
	inc 8, xsp
	ret

BmDrEdit_RenderSecondaryHoriz:
	ldda16 xwa, 10270
	srl wa, 2
	add wa, 0x16
	stda16 10178, xwa
	ld16_24 xwa, 0x0210b2
	srl wa, 2
	addda16 xwa, 10178
	stda16 10180, xwa
	ld8_24 a, 0x0210b0
	extz wa
	add wa, wa
	lda_24 xbc, 0xe33702
	ldmm_sriw 0x07, 0xE4, 0xE0, 0xC6, 0x27
	ldda16 xwa, 10182
	inc 3, wa
	stda16 10184, xwa
	ret

BmDrEdit_RenderSecondaryVert:
	ldda16 xwa, 10270
	srl wa, 2
	add wa, 0x5B
	stda16 10178, xwa
	ld16_24 xwa, 0x0210b2
	srl wa, 2
	addda16 xwa, 10178
	stda16 10180, xwa
	ld8_24 a, 0x0210b0
	extz wa
	add wa, wa
	lda_24 xbc, 0xe3373c
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	stda16 10182, xwa
	inc 3, wa
	stda16 10184, xwa
	decdi16 2, 10182
	incdi16 2, 10184
	ret

BmDrEdit_CalcSecondaryPosition:
	ldda16 xbc, 10260
	mul bc, 0x60
	addda16 xbc, 10262
	ldda16 xwa, 10252
	mul wa, 0x60
	addda16 xwa, 10254
	sub bc, wa
	stda16 10270, xbc
	ldda8 a, 10278
	subdm8_24 135344, a
	call GetTitleNow
	cp xhl, 0x1A00095
	jr nz, BmDrEdit_CalcSecondaryPos_Vert
	cpdi8 10136, 0
	jr nz, BmDrEdit_CalcSecondaryPos_ClampSize
	incdi8_24 3, 135344
	jr BmDrEdit_CalcSecondaryPos_ClampSize

BmDrEdit_CalcSecondaryPos_Vert:
	ldb a, 0xB
	subda8_24 a, 135344
	st8_24 0x0210b0, a

BmDrEdit_CalcSecondaryPos_ClampSize:
	ldda8 e, 10100
	mul e, 0x60
	dec 1, de
	ldda16 xwa, 10270
	ld bc, wa
	addda16_24 xbc, 135346
	cp bc, de
	ret ule
	sub de, wa
	st16_24 0x0210b2, xde
	ret

BmDrEdit_InitDisplayParams:
	stdi16 10132, 48
	stdi16 10134, 48
	stdi16 10128, 38
	stdi8 10136, 5
	stdi16 10142, 40
	stdi16 10144, 5
	stdi8 10122, 100
	ret

BmDrEdit_TempoAnimTimer:
	ldda8 a, 58226
	cp a, 0x1E
	jr ule, BmDrEdit_TempoAnimTimer_Reset
	inc 1, a
	stda8 58226, a
	ret

BmDrEdit_TempoAnimTimer_Reset:
	stdi8 58226, 0
	calr BmDrEdit_CheckTempoData
	calr BmDrEdit_DecrementDelayA
	calr BmDrEdit_DelayAExpired
	calr BmDrEdit_DecrementDelayB
	calr BmDrEdit_DelayBExpired
	jrl BmDrEdit_DelayReturn

BmDrEdit_CheckTempoData:
	call TempoRingBuf_CheckEmpty
	cps hl, 0
	ret z
	ldda8 a, 36152
	cp a, 0x95
	jr z, BmDrEdit_CheckTempoData_ReadyToProcess
	cp a, 0x98
	ret nz

BmDrEdit_CheckTempoData_ReadyToProcess:
	bitda 7, 10588
	ret nz
	cpdi16 62001, 0
	jr z, BmDrEdit_ClearNoteAndRefresh
	call TempoRingBuf_CheckEmpty
	cps hl, 0
	ret z

BmDrEdit_ProcessTempoEvent:
	call TempoRingBuf_ReadByte
	bit 7, l
	jr z, BmDrEdit_TempoEventLoop
	and l, 0xF0
	cp l, 0x90
	jr nz, BmDrEdit_TempoEventLoop
	call TempoRingBuf_ReadByte
	call TempoRingBuf_ReadByte
	stda8 10592, l
	call TempoRingBuf_ReadByte
	stda8 10593, l
	call TempoRingBuf_ReadByte
	cpdi8 10593, 0
	jr z, BmDrEdit_ProcessTempoEvent_NoteOff
	calr BmDrEdit_AllocateNoteSlot
	jr BmDrEdit_TempoEventLoop

BmDrEdit_ProcessTempoEvent_NoteOff:
	calr BmDrEdit_FindNoteInSlots
	cp hl, 0xFF
	jr z, BmDrEdit_TempoEventLoop
	calr BmDrEdit_CheckSlotsAvailable
	cps hl, 0
	jr nz, BmDrEdit_TempoEventLoop
	resda 0, 10591
	ldmm8 10594, 10592
	calr BmDrEdit_AdjustScrollToView
	calr LABEL_F371A5
	calr BmDrEdit_CountMeasuresInit
	cpdi8 10362, 0
	jr z, BmDrEdit_ClearSlotAndRedraw

BmDrEdit_ClearNoteAndRefresh:
	resda 0, 10591
	jrl BmDrEdit_RefreshDisplayState

BmDrEdit_ClearSlotAndRedraw:
	calr BmDrEdit_ClearAllSlotsAlt
	calr BmDrEdit_RefreshAfterInsert

BmDrEdit_TempoEventLoop:
	call TempoRingBuf_CheckEmpty
	cps hl, 0
	jr nz, BmDrEdit_ProcessTempoEvent
	ret

BmDrEdit_DecrementDelayA:
	ldda8 a, 10588
	bit 7, a
	ret z
	cp a, 0x80
	ret z
	dec 1, a
	stda8 10588, a
	ret

BmDrEdit_DelayAExpired:
	cpdi8 10588, 128
	ret nz
	stdi8 10588, 0
	ldda8 a, 10589
	cps a, 5
	jrl z, LABEL_F37B1C
	cps a, 4
	jrl z, LABEL_F37511
	cps a, 3
	jrl z, LABEL_F374F4
	cps a, 2
	jrl z, LABEL_F374EB
	cps a, 1
	jrl nz, LABEL_F3726E
	jrl LABEL_F374C6

BmDrEdit_DecrementDelayB:
	ldda8 a, 10590
	bit 7, a
	ret z
	cp a, 0x80
	ret z
	dec 1, a
	stda8 10590, a
	ret

BmDrEdit_DelayBExpired:
	cpdi8 10590, 128
	ret nz
	stdi8 10590, 0
	jrl LABEL_F374F1

BmDrEdit_DelayReturn:
	ret

BmDrEdit_AllocateNoteSlot:
	ldw ix, 0x8
	bitda 0, 10050
	jr z, BmDrEdit_AllocateNote_Search
	lds ix, 1

BmDrEdit_AllocateNote_Search:
	lds iy, 0
	cps ix, 0
	ret ule
	ldada xde, 10054

BmDrEdit_AllocateNote_Loop:
	ld hl, iy
	mul hl, 0x3
	ld bc, hl
	extz xbc
	add xbc, xde
	ld a, (xbc)
	bit 7, a
	jr nz, BmDrEdit_AllocateNote_NextSlot
	set 7, a
	ld (xbc), a
	lds wa, 1
	add wa, hl
	extz xwa
	add xwa, xde
	ldmi16 (xwa), 0x2960
	lds wa, 2
	add wa, hl
	extz xwa
	add xwa, xde
	ldmi16 (xwa), 0x2961
	ret

BmDrEdit_AllocateNote_NextSlot:
	inc 1, iy
	cp iy, ix
	jr c, BmDrEdit_AllocateNote_Loop
	ret

BmDrEdit_RefreshDisplayState:
	resda 0, 36232
	ldw wa, 0xF
	call SoundCtrl_SaveAndSendCmd_EE
	setda 4, 10413
	ret

BmDrEdit_CheckNoteType:
	ld c, a
	extz bc
	lds wa, 0
	call Part_ReadVoiceByte
	cp l, 0xD
	jr z, BmDrEdit_CheckNoteType_IsDrum
	cp l, 0xF
	jr z, BmDrEdit_CheckNoteType_IsDrum
	cp l, 0x10
	jr nz, BmDrEdit_CheckNoteType_NotDrum

BmDrEdit_CheckNoteType_IsDrum:
	ldw hl, 0xFFFF
	ret

BmDrEdit_CheckNoteType_NotDrum:
	lds hl, 0
	ret

BmDrEdit_SaveSequencerState:
	bitda 0, 10050
	jr z, BmDrEdit_SaveSeqState_SetMode95
	ldw wa, 0x98
	jr BmDrEdit_SaveSeqState_Apply

BmDrEdit_SaveSeqState_SetMode95:
	ldw wa, 0x95

BmDrEdit_SaveSeqState_Apply:
	call UI_PostModeChangeEvent
	ldmm16 10595, 3407
	call SeqVoice_FindSingleActive
	ldmm8 7512, 36154
	ret

BmDrEdit_CheckScrollBusy:
	bitda 7, 10588
	jr z, BmDrEdit_ScrollRight
	cpdi8 10589, 0
	jr z, BmDrEdit_ScrollRight
	ldw hl, 0xFFFF
	ret

BmDrEdit_ScrollRight:
	ldda16 xwa, 10052
	cp wa, 0x3E7
	jr nc, BmDrEdit_ScrollRight_Done
	inc 1, wa
	stda16 10052, xwa
	calr BmDrEdit_ScrollReset

BmDrEdit_ScrollRight_Done:
	lds hl, 0
	ret

BmDrEdit_CheckScrollBusyAlt:
	bitda 7, 10588
	jr z, BmDrEdit_ScrollLeft
	cpdi8 10589, 0
	jr z, BmDrEdit_ScrollLeft
	ldw hl, 0xFFFF
	ret

BmDrEdit_ScrollLeft:
	ldda16 xwa, 10052
	cps wa, 1
	jr ule, BmDrEdit_ScrollLeft_Done
	dec 1, wa
	stda16 10052, xwa
	calr BmDrEdit_ScrollReset

BmDrEdit_ScrollLeft_Done:
	lds hl, 0
	ret

BmDrEdit_ScrollReset:
	call NoteEditSy_SendScrollCmd0
	stdi16 10138, 0
	stdi16 10114, 0
	stdi8 10116, 0
	stdi8 10588, 130
	stdi8 10589, 0
	ret

BmDrEdit_PitchScrollUp_Check:
	bitda 7, 10588
	jr z, BmDrEdit_PitchScrollUp
	cpdi8 10589, 1
	ret nz

BmDrEdit_PitchScrollUp:
	ldda8 a, 10116
	cp a, 0x5F
	jrl nc, LABEL_F37555
	inc 1, a
	stda8 10116, a
	call NoteEditSy_SendScrollCmd2
	calr NoteEditSy_CallFarRoutine
	calr LABEL_F3803E
	jrl BmDrEdit_SetFeedbackTimer

BmDrEdit_PitchScrollDown_Check:
	bitda 7, 10588
	jr z, BmDrEdit_PitchScrollDown
	cpdi8 10589, 1
	ret nz

BmDrEdit_PitchScrollDown:
	ldda8 a, 10116
	cps a, 0
	jrl z, BmDrEdit_PitchWrapToEnd
	dec 1, a
	stda8 10116, a
	call NoteEditSy_SendScrollCmd2
	calr NoteEditSy_CallFarRoutine
	calr LABEL_F3803E
	jrl BmDrEdit_SetFeedbackTimer

BmDrEdit_VelocityUp_Check:
	bitda 7, 10588
	jr z, BmDrEdit_VelocityUp_Dispatch
	cpdi8 10589, 2
	ret nz

BmDrEdit_VelocityUp_Dispatch:
	bitda 0, 10591
	ret z
	bitda 0, 10050
	jr nz, BmDrEdit_DecrementVelocity
	jr BmDrEdit_IncrementVelocity

BmDrEdit_VelocityDown_Check:
	bitda 7, 10588
	jr z, BmDrEdit_VelocityDown_Dispatch
	cpdi8 10589, 2
	ret nz

BmDrEdit_VelocityDown_Dispatch:
	bitda 0, 10591
	ret z
	bitda 0, 10050
	jr nz, BmDrEdit_IncrementVelocity
	jr BmDrEdit_DecrementVelocity

BmDrEdit_IncrementVelocity:
	ldda8 a, 10118
	cp a, 0x7F
	ret nc
	inc 1, a
	stda8 10118, a
	bitda 0, 10050
	call_24 nz, 0xF37A5F
	calr BmDrEdit_UpdateVelocityDisplay
	call NoteEditSy_SendScrollCmd3
	calr BmDrEdit_NullReturn
	stdi8 10588, 131
	stdi8 10589, 2
	ret

BmDrEdit_DecrementVelocity:
	ldda8 a, 10118
	cps a, 1
	ret z
	dec 1, a
	stda8 10118, a
	bitda 0, 10050
	call_24 nz, 0xF37AB6
	calr BmDrEdit_UpdateVelocityDisplay
	call NoteEditSy_SendScrollCmd3
	calr BmDrEdit_NullReturn
	stdi8 10588, 131
	stdi8 10589, 2
	ret

BmDrEdit_GateOrVelocityUp:
	bitda 7, 10588
	ret nz
	bitda 0, 10591
	jr nz, BmDrEdit_IncrementGateTime
	bitda 0, 10050
	ret z
	calr BmDrEdit_IncrementVelocityValue
	ret

BmDrEdit_GateOrVelocityDown:
	bitda 7, 10588
	ret nz
	bitda 0, 10591
	jr nz, BmDrEdit_DecrementGateTime
	bitda 0, 10050
	ret z
	calr BmDrEdit_DecrementVelocityValue
	ret

BmDrEdit_IncrementGateTime:
	ldda8 a, 10120
	cp a, 0x7F
	ret nc
	inc 1, a
	stda8 10120, a
	call NoteEditSy_SendGateCmd
	jrl BmDrEdit_UpdateGateDisplay

BmDrEdit_DecrementGateTime:
	ldda8 a, 10120
	cps a, 1
	ret z
	dec 1, a
	stda8 10120, a
	call NoteEditSy_SendGateCmd
	jrl BmDrEdit_UpdateGateDisplay

BmDrEdit_IncrementVelocityValue:
	ldda8 a, 10122
	cp a, 0x7F
	ret nc
	inc 1, a
	stda8 10122, a
	jp NoteEditSy_SendVelocityCmd

BmDrEdit_DecrementVelocityValue:
	ldda8 a, 10122
	cps a, 1
	ret z
	dec 1, a
	stda8 10122, a
	jp NoteEditSy_SendVelocityCmd

BmDrEdit_DurationUp_Check:
	bitda 7, 10588
	jr z, BmDrEdit_DurationUp_Dispatch
	cpdi8 10589, 3
	ret nz

BmDrEdit_DurationUp_Dispatch:
	jr BmDrEdit_IncrementDuration

BmDrEdit_DurationDown_Check:
	bitda 7, 10588
	jr z, BmDrEdit_DurationDown_Dispatch
	cpdi8 10589, 3
	ret nz

BmDrEdit_DurationDown_Dispatch:
	jr BmDrEdit_DecrementDuration

BmDrEdit_IncrementDuration:
	bitda 0, 10591
	jr z, BmDrEdit_IncrementDuration_Global
	ldda16 xwa, 10124
	cp wa, 0x2FFF
	ret nc
	inc 1, wa
	stda16 10124, xwa
	calr BmDrEdit_CalcDurationPosition
	call NoteEditSy_SendScrollCmd5
	calr BmDrEdit_NullReturn
	stdi8 10588, 131
	stdi8 10589, 3
	ret

BmDrEdit_IncrementDuration_Global:
	ldda16 xwa, 10126
	cp wa, 0x2FFF
	ret nc
	inc 1, wa
	stda16 10126, xwa
	jp NoteEditSy_SendScrollCmd8

BmDrEdit_DecrementDuration:
	bitda 0, 10591
	jr z, BmDrEdit_DecrementDuration_Global
	ldda16 xwa, 10124
	cps wa, 0
	jr nz, BmDrEdit_DecrementDuration_Clamp
	stdi16 10124, 1
	jr BmDrEdit_DecrementDuration_Update

BmDrEdit_DecrementDuration_Clamp:
	cps wa, 1
	ret ule
	dec 1, wa
	stda16 10124, xwa

BmDrEdit_DecrementDuration_Update:
	calr BmDrEdit_CalcDurationPosition
	call NoteEditSy_SendScrollCmd5
	calr BmDrEdit_NullReturn
	stdi8 10588, 131
	stdi8 10589, 3
	ret

BmDrEdit_DecrementDuration_Global:
	ldda16 xwa, 10126
	cps wa, 0
	jr nz, BmDrEdit_DecrementDuration_GlobalClamp
	stdi16 10126, 1
	jr BmDrEdit_DecrementDuration_Send

BmDrEdit_DecrementDuration_GlobalClamp:
	cps wa, 1
	ret z
	dec 1, wa
	stda16 10126, xwa

BmDrEdit_DecrementDuration_Send:
	jp NoteEditSy_SendScrollCmd8

BmDrEdit_ModeScrollUp:
	bitda 7, 10588
	ret nz
	ldda16 xwa, 10130
	cp wa, 0x60
	ret nc
	inc 1, wa
	stda16 10130, xwa
	jp NoteEditSy_SendModeScrollCmd

BmDrEdit_ModeScrollDown:
	bitda 7, 10588
	ret nz
	ldda16 xwa, 10130
	cps wa, 0
	jr nz, BmDrEdit_ModeScrollDown_Clamp
	stdi16 10130, 48
	jr BmDrEdit_ModeScrollDown_Send

BmDrEdit_ModeScrollDown_Clamp:
	cps wa, 1
	ret ule
	dec 1, wa
	stda16 10130, xwa

BmDrEdit_ModeScrollDown_Send:
	jp NoteEditSy_SendModeScrollCmd

BmDrEdit_SetFeedbackTimer:
	stdi8 10588, 133
	stdi8 10589, 1
	ret

BmDrEdit_SaveEditState:
	ldmm16 10082, 10078
	ldmm8 10084, 10080
	ldmm16 10086, 10415
	ldmm16 10088, 9830
	ret

BmDrEdit_RestoreEditState:
	ldmm16 10078, 10082
	ldmm8 10080, 10084
	ldmm16 10415, 10086
	ldmm16 9830, 10088
	ret

BmDrEdit_ClearAndScanToEnd:
	stdi8 10362, 0

BmDrEdit_ScanToEnd_Loop:
	ldda16 xwa, 9830
	cps wa, 5
	jr ule, BmDrEdit_ScanToEnd_CheckNextSong
	dec 1, wa
	stda16 9830, xwa
	jr BmDrEdit_ScanToEnd_CheckEndMark

BmDrEdit_ScanToEnd_CheckNextSong:
	ldda16 xwa, 10415
	call PartCtrl_ReadWord_Off1
	cps hl, 0
	jr nz, BmDrEdit_ScanToEnd_AdvanceSong
	stdi8 10362, 255
	ret

BmDrEdit_ScanToEnd_AdvanceSong:
	stda16 10415, xhl
	stdi16 9830, 255

BmDrEdit_ScanToEnd_CheckEndMark:
	call SeqData_ReadNextByte
	bit 7, l
	jr z, BmDrEdit_ScanToEnd_Loop
	ret

BmDrEdit_LoadAlternateState:
	ldmm16 10078, 10090
	ldmm8 10080, 10092
	ldmm16 10415, 10094
	ldda8 a, 10096
	extz wa
	stda16 9830, xwa
	ret

BmDrEdit_LoadAlternateAndCountNotes:
	calr BmDrEdit_LoadAlternateState
	stdi16 10098, 0

BmDrEdit_CountNotesLoop:
	call SeqData_ReadNextByte
	cp l, 0x82
	ret z
	cp l, 0x84
	ret z
	cp l, 0x81
	jr nz, BmDrEdit_CountNotesLoop_Retry
	ldda16 xbc, 10098
	inc 1, bc
	stda16 10098, xbc
	ldda8 a, 10100
	extz wa
	cp bc, wa
	ret ugt

BmDrEdit_CountNotesLoop_Retry:
	call SeqData_SkipToNextEvent
	jr BmDrEdit_CountNotesLoop

BmDrEdit_CheckChannelActive:
	ldb e, 0x0
	ldada xbc, 61856

BmDrEdit_CheckChannelActive_Loop:
	ld a, e
	extz wa
	extz xwa
	add xwa, xbc
	cp (xwa), 0x10
	jr nz, BmDrEdit_CheckChannelActive_Next
	lds bc, 1
	ld a, e
	and a, 0xF
	jr z, BmDrEdit_CheckChannelActive_TestBit
	slaa bc

BmDrEdit_CheckChannelActive_TestBit:
	andda16_24 xbc, 65516
	jr z, BmDrEdit_CheckChannelActive_None
	stdi8 10102, 1
	ret

BmDrEdit_CheckChannelActive_Next:
	inc 1, e
	cp e, 0x10
	jr c, BmDrEdit_CheckChannelActive_Loop

BmDrEdit_CheckChannelActive_None:
	stdi8 10102, 0
	ret

BmDrEdit_SelectActiveChannel:
	push_werp 0xFA
	ldi_berp 0xFB, 0
	ldada xbc, 61856

BmDrEdit_SelectChannel_Loop:
	ldto_berp A, 0xFB
	extz wa
	extz xwa
	add xwa, xbc
	cp (xwa), 0x10
	jr nz, BmDrEdit_SelectChannel_NextCh
	lds bc, 1
	ldto_berp A, 0xFB
	and a, 0xF
	jr z, BmDrEdit_SelectChannel_TestBit
	slaa bc

BmDrEdit_SelectChannel_TestBit:
	andda16_24 xbc, 65516
	jr z, BmDrEdit_SelectChannel_NotFound
	bitda 0, 10102
	jr z, BmDrEdit_SelectChannel_NotFound
	ldto_berp C, 0xFB
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, BmDrEdit_SelectChannel_NotFound
	ldto_berp A, 0xFB
	inc 1, a
	stda8 3414, a
	setda 0, 3412
	setda 2, 10363
	ldto_berp L, 0xFB
	inc 1, l
	jr BmDrEdit_SelectChannel_Done

BmDrEdit_SelectChannel_NextCh:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, BmDrEdit_SelectChannel_Loop

BmDrEdit_SelectChannel_NotFound:
	resda 0, 3412
	resda 2, 10363
	ldb l, 0x0

BmDrEdit_SelectChannel_Done:
	pop_werp 0xFA
	ret

BmDrEdit_AlignDisplayGrid:
	lds de, 0
	ldda16 xwa, 10138
	cps wa, 0
	jr c, BmDrEdit_AlignGrid_Store
	ldda16 xbc, 10130

BmDrEdit_AlignGrid_AccumLoop:
	add de, bc
	cp de, wa
	jr ule, BmDrEdit_AlignGrid_AccumLoop

BmDrEdit_AlignGrid_Store:
	stda16 10138, xde
	ret

BmDrEdit_CompareVelocity:
	push xiz
	bitda 0, 10050
	jr z, BmDrEdit_CompareVelocity_Equal
	ldda16 xiz, 10415
	ldda16 xwa, 9830
	ldfr_werp WA, 0xFA
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stda16 10415, xiz
	ldto_werp WA, 0xFA
	stda16 9830, xwa
	cpda8 l, 10118
	jr z, BmDrEdit_CompareVelocity_Equal
	ldb l, 0xFF
	jr BmDrEdit_CompareVelocity_Return

BmDrEdit_CompareVelocity_Equal:
	ldb l, 0x0

BmDrEdit_CompareVelocity_Return:
	pop xiz
	ret

BmDrEdit_SaveSongPosition:
	ldda8 a, 10597
	inc 1, a
	extz wa
	ldda16 xhl, 10415
	ldda16 xde, 9830
	dec 1, a
	extz wa
	sla wa, 2
	ldada xbc, 9184
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de
	ret

BmDrEdit_ReadEventAtPosition:
	push xiz
	ldda16 xiz, 10415
	ldda16 xwa, 9830
	ldfr_werp WA, 0xFA
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stda8 10080, l
	stda16 10415, xiz
	ldto_werp WA, 0xFA
	stda16 9830, xwa
	pop xiz
	ret

BmDrEdit_CheckNoteAtPosition:
	call SeqData_ReadNextByte
	and l, 0xF0
	cp l, 0x90
	ret nz
	calr BmDrEdit_CompareVelocity
	cps l, 0
	ret nz
	jr BmDrEdit_ReadEventAtPosition

BmDrEdit_WalkTrackForward:
	ldda8 a, 10591
	res 1, a
	res 4, a
	stda8 10591, a
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_WalkTrack_EndOfTrack
	cp l, 0x84
	jr z, BmDrEdit_WalkTrack_EndOfTrack
	cp l, 0x81
	jr nz, BmDrEdit_WalkTrack_ProcessEvent
	ldda16 xbc, 10078
	inc 1, bc
	stda16 10078, xbc
	ldda8 a, 10100
	extz wa
	subda16 xbc, 10090
	cp bc, wa
	jr nc, BmDrEdit_WalkTrack_CountExceeded

BmDrEdit_WalkTrack_ProcessEvent:
	call SeqData_SkipToNextEvent
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_WalkTrack_EndOfTrack
	cp l, 0x84
	jr nz, BmDrEdit_WalkTrack_CheckNoteCount

BmDrEdit_WalkTrack_EndOfTrack:
	setda 1, 10591
	stdi8 10080, 0
	ret

BmDrEdit_WalkTrack_CheckNoteCount:
	cp l, 0x81
	jr nz, BmDrEdit_WalkTrack_CheckNoteOn
	ldda16 xbc, 10078
	inc 1, bc
	stda16 10078, xbc
	ldda8 a, 10100
	extz wa
	subda16 xbc, 10090
	cp bc, wa
	jr c, BmDrEdit_WalkTrack_CheckNoteOn

BmDrEdit_WalkTrack_CountExceeded:
	setda 4, 10591
	ret

BmDrEdit_WalkTrack_CheckNoteOn:
	and l, 0xF0
	cp l, 0x90
	jr nz, BmDrEdit_WalkTrack_ProcessEvent
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr nz, BmDrEdit_WalkTrack_ProcessEvent
	jrl BmDrEdit_ReadEventAtPosition

BmDrEdit_SetupCoordinates:
	ld xde, xwa
	ldmw2 (xde), 0x275E
	ld xhl, xde
	ld wa, (xhl)
	mul wa, 0x60
	ld (xhl), wa
	ldda8 a, 10080
	extz wa
	add (xde), wa
	ldmw2 (xbc), 0x276A
	ld xde, xbc
	ld wa, (xde)
	mul wa, 0x60
	ld (xde), wa
	ldda8 a, 10092
	extz wa
	add (xbc), wa
	ret

BmDrEdit_SetupAndWalkToNote:
	dec 4, xsp
	push_werp 0xFA
	resda 0, 10591
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 2)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub (xsp + 4), wa
	ld wa, (xsp + 4)
	cpda16 xwa, 10138
	jr nz, BmDrEdit_SetupAndWalkDone
	call SeqData_ReadNextByte
	and l, 0xF0
	cp l, 0x90
	jr nz, BmDrEdit_SetupAndWalkDone
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr nz, BmDrEdit_SetupAndWalkDone
	setda 0, 10591
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stda8 10118, l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stda8 10120, l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ldfr_berp L, 0xFB
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	res 7, l
	res_erpb 0xFB, 0x07
	extz hl
	ld bc, hl
	mul bc, 0x60
	ld hl, bc
	ldto_berp A, 0xFB
	extz wa
	add hl, wa
	stda16 10124, xhl
	calr BmDrEdit_ClearAndScanToEnd
	ldmm8 10594, 10118
	calr BmDrEdit_AdjustScrollToView

BmDrEdit_SetupAndWalkDone:
	pop_werp 0xFA
	inc 4, xsp
	ret

BmDrEdit_SaveAndFindNote:
	calr BmDrEdit_SaveEditState

BmDrEdit_FindNote_Loop:
	call SeqData_ReadNextByte
	cp l, 0x81
	jr z, BmDrEdit_FindNote_EndOfTrack
	cp l, 0x82
	jr z, BmDrEdit_FindNote_EndOfTrack
	cp l, 0x84
	jr z, BmDrEdit_FindNote_EndOfTrack
	and l, 0xF0
	cp l, 0x90
	jr nz, BmDrEdit_FindNote_SkipNonNote
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr nz, BmDrEdit_FindNote_SkipNonNote
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cps l, 0
	jrl z, BmDrEdit_ClearAndScanToEnd

BmDrEdit_FindNote_EndOfTrack:
	jrl BmDrEdit_RestoreEditState

BmDrEdit_FindNote_SkipNonNote:
	call SeqData_SkipToNextEvent
	jr BmDrEdit_FindNote_Loop

BmDrEdit_ClearAllSlots:
	ldada xbc, 10054
	ld xwa, xbc
	lda xbc, (xbc + 24)

BmDrEdit_ClearSlots_Loop:
	ld (xwa), 0x0
	inc 3, xwa
	cp xwa, xbc
	jr c, BmDrEdit_ClearSlots_Loop
	ret

BmDrEdit_CheckAndSelectChannel:
	calr BmDrEdit_CheckChannelActive
	jrl BmDrEdit_SelectActiveChannel

BmDrEdit_FindNoteInSlots:
	pushw iz
	ldw iy, 0x8
	bitda 0, 10050
	jr z, BmDrEdit_FindNote_SetupLoop
	lds iy, 1

BmDrEdit_FindNote_SetupLoop:
	lds iz, 0
	cps iy, 0
	jr ule, BmDrEdit_FindNote_NotFound
	ldada xix, 10054

BmDrEdit_FindNote_SlotLoop:
	ld bc, iz
	mul bc, 0x3
	ld hl, bc
	extz xhl
	add xhl, xix
	ld a, (xhl)
	bit 7, a
	jr z, BmDrEdit_FindNote_NextSlot
	lds de, 1
	add de, bc
	extz xde
	add xde, xix
	ld c, (xde)
	cpda8 c, 10592
	jr nz, BmDrEdit_FindNote_NextSlot
	res 7, a
	ld (xhl), a
	ld l, (xde)
	extz hl
	jr BmDrEdit_FindNote_Return

BmDrEdit_FindNote_NextSlot:
	inc 1, iz
	cp iz, iy
	jr c, BmDrEdit_FindNote_SlotLoop

BmDrEdit_FindNote_NotFound:
	ldw hl, 0xFF

BmDrEdit_FindNote_Return:
	popw iz
	ret

BmDrEdit_ClearAllSlotsAlt:
	ldada xbc, 10055
	ld xwa, xbc
	lda xbc, (xbc + 24)

BmDrEdit_ClearSlotsAlt_Loop:
	ld (xwa), 0x0
	inc 3, xwa
	cp xwa, xbc
	jr c, BmDrEdit_ClearSlotsAlt_Loop
	ret

BmDrEdit_CheckSlotsAvailable:
	lds de, 0
	ldada xbc, 10054

BmDrEdit_CheckSlots_Loop:
	ld wa, de
	mul wa, 0x3
	extz xwa
	add xwa, xbc
	bitm 7, (xwa)
	jr z, BmDrEdit_CheckSlots_Next
	ldw hl, 0xFF
	ret

BmDrEdit_CheckSlots_Next:
	inc 1, de
	cp de, 0x8
	jr c, BmDrEdit_CheckSlots_Loop
	lds hl, 0
	ret

BmDrEdit_CalcBeatFromGridPos:
	ldda16 xwa, 10138
	extz xwa
	div wa, 0x60
	ldto_werp WA, 0xE2
	stda8 10080, a
	ldda16 xwa, 10138
	extz xwa
	div wa, 0x60
	stda16 10078, xwa
	ldda16 xwa, 10090
	adddm16 10078, xwa
	ret

BmDrEdit_ByteData_NoteCoordTable:
	.byte 0xd1, 0x5e, 0x27, 0x19, 0x78, 0x27, 0xc1, 0x60
	.byte 0x27, 0x19, 0x7a, 0x27, 0xd1, 0xaf, 0x28, 0x19
	.byte 0x7c, 0x27, 0xd1, 0x66, 0x26, 0x19, 0x7e, 0x27
	.byte 0x0e, 0xd1, 0x78, 0x27, 0x19, 0x5e, 0x27, 0xc1
	.byte 0x7a, 0x27, 0x19, 0x60, 0x27, 0xd1, 0x7c, 0x27
	.byte 0x19, 0xaf, 0x28, 0xd1, 0x7e, 0x27, 0x19, 0x66
	.byte 0x26, 0x0e, 0xf1, 0x5c, 0x29, 0xcf, 0xb0, 0xfe
	.byte 0xd1, 0x92, 0x27, 0x20, 0xd8, 0xcf, 0x60, 0x00
	.byte 0xb0, 0xff, 0xd8, 0x61, 0xf1, 0x92, 0x27, 0x50
	.byte 0x1b, 0xe1, 0x68, 0xf4, 0xf1, 0x5c, 0x29, 0xcf
	.byte 0xb0, 0xfe, 0xd1, 0x92, 0x27, 0x20, 0xd8, 0xd8
	.byte 0x6e, 0x08, 0xf1, 0x92, 0x27, 0x02, 0x30, 0x00
	.byte 0x68, 0x0a, 0xd8, 0xd9, 0xb0, 0xf3, 0xd8, 0x69
	.byte 0xf1, 0x92, 0x27, 0x50, 0x1d, 0xe1, 0x68, 0xf4
	.byte 0x0e

BmDrEdit_ChordScrollUp_Check:
	bitda 7, 10588
	jr z, BmDrEdit_ChordScrollUp
	cpdi8 10589, 4
	ret nz

BmDrEdit_ChordScrollUp:
	ldda8 a, 10136
	cp a, 0x9
	ret nc
	inc 1, a
	stda8 10136, a
	call NoteEditSy_UpdateChordDisplay
	stdi8 10588, 129
	stdi8 10589, 4
	ret

BmDrEdit_ChordScrollDown_Check:
	bitda 7, 10588
	jr z, BmDrEdit_ChordScrollDown
	cpdi8 10589, 4
	ret nz

BmDrEdit_ChordScrollDown:
	ldda8 a, 10136
	cps a, 0
	ret z
	dec 1, a
	stda8 10136, a
	call NoteEditSy_UpdateChordDisplay
	stdi8 10588, 129
	stdi8 10589, 4
	ret

BmDrEdit_NullReturn:
	ret

BmDrEdit_PitchWrapToEnd:
	ldda16 xwa, 10114
	cps wa, 0
	jr z, BmDrEdit_PitchWrapPrevPage
	stdi8 10116, 95
	ldda16 xwa, 10114
	dec 1, wa
	stda16 10114, xwa
	jr BmDrEdit_PitchWrap_UpdateDisplay

BmDrEdit_PitchWrapPrevPage:
	ldda16 xwa, 10052
	cpda16 xwa, 10162
	jr z, BmDrEdit_PitchWrap_CheckEnd
	calr LABEL_F384FC
	decdi16 1, 10052
	stdi8 10116, 95
	call NoteEditSy_SendScrollCmd0

BmDrEdit_PitchWrap_UpdateDisplay:
	call NoteEditSy_SendScrollCmd2
	call NoteEditSy_SendScrollCmd1
	calr NoteEditSy_CallFarRoutine
	jrl BmDrEdit_SetFeedbackTimer

BmDrEdit_PitchWrap_CheckEnd:
	bitda 0, 10591
	jrl z, BmDrEdit_NavigatePrevPage
	cps wa, 1
	ret z
	stdi8 10588, 0
	calr ReadSeqData_StoreParams
	jrl LABEL_F37462

BmDrEdit_CalcDurationPosition:
	calr BmDrEdit_SaveEditState
	call SeqData_ReadNextByte
	and l, 0xF0
	cp l, 0x90
	ret nz
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	ldda16 xwa, 10124
	extz xwa
	div wa, 0x60
	ldto_werp WA, 0xE2
	and wa, 0x7F
	extz wa
	call PartCtrl_WriteByte_Indexed
	call SeqData_AdvancePosition
	ldda16 xwa, 10124
	extz xwa
	div wa, 0x60
	and wa, 0x7F
	extz wa
	call PartCtrl_WriteByte_Indexed
	jrl BmDrEdit_RestoreEditState

BmDrEdit_UpdateGateDisplay:
	calr BmDrEdit_SaveEditState
	call SeqData_ReadNextByte
	and l, 0xF0
	cp l, 0x90
	ret nz
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	ldda8 l, 10120
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	calr BmDrEdit_RestoreEditState
	jrl BmDrEdit_SendMetronomeNoteOn

BmDrEdit_UpdateVelocityDisplay:
	calr BmDrEdit_SaveEditState
	call SeqData_ReadNextByte
	and l, 0xF0
	cp l, 0x90
	ret nz
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	ldda8 l, 10118
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	calr BmDrEdit_RestoreEditState
	jrl BmDrEdit_SendMetronomeNoteOn

BmDrEdit_InsertNoteEvent:
	resda 0, 10591
	calr BmDrEdit_CalcTrackPosition
	ldmm8 10592, 10118
	ldda8 a, 10122
	stda8 10593, a
	ldmm8 10120, 10122
	calr LABEL_F37B22
	calr BmDrEdit_WalkEventsOrSetError
	jr BmDrEdit_RefreshAfterInsert

BmDrEdit_SendWidgetCmd:
	bitda 0, 10050
	ret z
	jp NoteEditSy_SendWidgetCmdE

BmDrEdit_NavigatePrevPage:
	ldda16 xwa, 10052
	cps wa, 1
	ret ule
	dec 1, wa
	stda16 10052, xwa
	calr BmDrEdit_SelectChannelAndLoadPos
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_ScanChannelEvents
	incdi16 1, 10052
	stdi16 10114, 0
	stdi8 10116, 0
	calr BmDrEdit_LoadAlternatePosition
	calr BmDrEdit_BuildVoiceList
	calr BmDrEdit_SetupAndWalkToNote
	calr NoteEditSy_SendCompoundWidgetUpdate
	calr NoteEdit_UpdateScrollAndDisplay
	call NoteEditSy_SendWidgetCmd0
	jrl NoteEdit_SendScrollCmds

BmDrEdit_RefreshAfterInsert:
	calr BmDrEdit_AlignDisplayGrid
	calr BmDrEdit_InsertNoteSequence
	bitda 2, 10591
	jr z, BmDrEdit_RefreshAfterInsert_CheckFull
	ldw wa, 0xD0
	call SeqData_SetErrorCode
	jrl BmDrEdit_RefreshDisplayState

BmDrEdit_RefreshAfterInsert_CheckFull:
	ldda8 a, 10100
	mul a, 0x60
	cpdm16 10138, xwa
	jrl nc, BmDrEdit_NavigateAndLoadPosition
	calr BmDrEdit_CalcBeatMeasure
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	jrl NoteEdit_UpdateScrollAndDisplay

BmDrEdit_SetupScrollRegion:
	ld xde, xwa
	bitda 0, 10050
	jr z, BmDrEdit_SetupScrollRegion_MelodicMode
	ldda16 xwa, 10142
	ld (xde), a
	ldda16 xwa, 10142
	ld (xbc), a
	addmi8 (xbc), 0xB
	ret

BmDrEdit_SetupScrollRegion_MelodicMode:
	ldda8 a, 10136
	extz wa
	add wa, wa
	lda_24 xhl, 0xe44478
	ld_srib3 A, 0x07, 0xEC, 0xE0
	ld (xde), a
	ldda8 a, 10136
	extz wa
	add wa, wa
	inc 1, wa
	ld_srib3 A, 0x07, 0xEC, 0xE0
	ld (xbc), a
	ret

BmDrEdit_ByteData_ScrollParams:
	.byte 0xc1, 0x65, 0x29, 0x21, 0xd8, 0x12, 0xf1, 0xa0
	.byte 0xf1, 0x31, 0xe8, 0x12, 0xe9, 0x80, 0x80, 0x21
	.byte 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xf2, 0x8e, 0x44
	.byte 0xe4, 0x31, 0xe3, 0x07, 0xe4, 0xe0, 0x20, 0x80
	.byte 0x3f, 0xf0, 0x67, 0x03, 0xdb, 0xa8, 0x0e, 0x33
	.byte 0xff, 0xff, 0x0e

BmDrEdit_InitDrumMode:
	pushw 0x6A4
	call Malloc
	inc 2, xsp
	stda32 7504, xhl
	stda32 7508, xhl
	calr LABEL_F388A8
	stdi16 10126, 10
	ldmm16 10130, 10134
	setda 0, 10050
	stdi8 10100, 7
	stdi8 10146, 8
	jr BmDrEdit_InitCommon

BmDrEdit_InitMelodicMode:
	ldmm16 10130, 10132
	ldmm16 10126, 10128
	resda 0, 10050
	stdi8 10100, 10
	stdi8 10146, 11
	jr __jrt_nop_F36FA7
__jrt_nop_F36FA7:

BmDrEdit_InitCommon:
	pushw iz
	cpdi16 10130, 0
	jr nz, BmDrEdit_InitCommon_CheckSongActive
	stdi16 10130, 48

BmDrEdit_InitCommon_CheckSongActive:
	ldda8 a, 36150
	cpda8 a, 36151
	jr nz, BmDrEdit_InitCommon_SetupDisplay
	ldda8 a, 36152
	cpda8 a, 36153
	jr z, BmDrEdit_InitCommon_SetupDisplay
	bitda 4, 10413
	jr z, BmDrEdit_InitCommon_SetupDisplay
	lds wa, 1
	call UI_PostPartChangeEvent
	resda 4, 10413
	resda 0, 9834
	jrl LABEL_F37132

BmDrEdit_InitCommon_SetupDisplay:
	setda 0, 9834
	setda 0, 9954
	call AccWrap_PlayModeDispatch
	setda 2, 10407
	stdi8 10588, 0
	ldda16 xwa, 10595
	stda16 3407, xwa
	ldmm16 3409, 10595
	ldda8 a, 36153
	cp a, 0x96
	jr z, BmDrEdit_CopyStepCount
	cp a, 0x99
	jr z, BmDrEdit_CopyStepCount
	cp a, 0x94
	jr z, LABEL_F3701C
	cp a, 0x97
	jr nz, LABEL_F37022

LABEL_F3701C:
	setda 0, 36232
	jr LABEL_F3703A

LABEL_F37022:
	bitda 0, 10050
	jrl z, BmDrEdit_FlagDisplayUpdate
	ldda8 a, 10587
	bit 0, a
	jrl z, BmDrEdit_FlagDisplayUpdate
	res 0, a
	stda8 10587, a

LABEL_F3703A:
	ldda8 c, 10597
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, LABEL_F37055

BmDrEdit_CopyStepCount:
	ldmm16 10052, 9832
	jrl LABEL_F370D7

LABEL_F37055:
	stdi16 10052, 1
	cpdi16 62001, 0
	jrl z, LABEL_F37102
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	ld wa, iz
	lds bc, 1
	call PartCtrl_SetClearBit7
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	ldda8 c, 10597
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	ldda8 c, 10597
	inc 1, c
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteVoiceWord
	ldda8 c, 10597
	inc 1, c
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteWord_Indexed
	ldda8 c, 10597
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 5
	call Part_WriteByte_Indexed
	stda16 10415, xiz
	stdi16 9830, 5
	calr BmDrEdit_InsertStepEntry
	incdi16 1, 9830
	calr BmDrEdit_InsertStepEntry

LABEL_F370D7:
	calr Metronome_PlayClick
	call TempoRingBuf_Init
	call SeqBuf_Init
	calr BmDrEdit_ClearAllSlotsAlt
	calr BmDrEdit_ClearAllSlots
	calr BmDrEdit_SelectChannelAndLoadPos
	cpdi8 10362, 0
	jr z, BmDrEdit_ResetAndScanNotes
	stdi16 10052, 1
	calr BmDrEdit_SelectChannelAndLoadPos
	cpdi8 10362, 0
	jr z, BmDrEdit_ResetAndScanNotes

LABEL_F37102:
	calr BmDrEdit_RefreshDisplayState
	jr LABEL_F37132

BmDrEdit_ResetAndScanNotes:
	stdi16 10138, 0
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_CalcTrackPosition
	calr BmDrEdit_SaveAndFindNote
	calr BmDrEdit_CheckNoteAtPosition
	calr BmDrEdit_SetupAndWalkToNote
	stdi16 10114, 0
	stdi8 10116, 0
	calr BmDrEdit_ScanChannelEvents

BmDrEdit_FlagDisplayUpdate:
	call Audio_CheckSubsystemReady
	setda 0, 10160

LABEL_F37132:
	popw iz
	ret

LABEL_F37134:
	ldmm16 10134, 10130
	ldda32 xwa, 7504
	push xwa
	call Free
	inc 4, xsp
	cpdi8 36150, 152
	jr z, LABEL_F37154
	resda 0, 9954
	call PartSelect_UpdateDisplayState

LABEL_F37154:
	jr LABEL_F37173

LABEL_F37156:
	cpdi8 36150, 149
	jr z, LABEL_F37165
	resda 0, 9954
	call PartSelect_UpdateDisplayState

LABEL_F37165:
	ldmm16 10132, 10130
	ldmm16 10128, 10126
	jr __jrt_nop_F37173
__jrt_nop_F37173:

LABEL_F37173:
	resda 2, 10407
	stdi8 10588, 0
	ldda16 xwa, 3407
	ordm16_24 65516, xwa
	stdi16 3407, 0
	stdi16 3409, 0
	ldmm16 9832, 10052
	call Audio_CheckSubsystemReady
	resda 0, 10160
	calr BmDrEdit_ClearAllSlotsAlt
	jrl BmDrEdit_ClearAllSlots

LABEL_F371A5:
	pushw iz
	bitda 0, 10050
	jr z, LABEL_F371BD
	ldmm8 10592, 10118
	ldmm8 10593, 10056
	calr BmDrEdit_WalkEventsOrSetError
	jr LABEL_F37201

LABEL_F371BD:
	lds iz, 0

LABEL_F371BF:
	ld de, iz
	mul de, 0x3
	lds wa, 1
	add wa, de
	ldada xbc, 10054
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cps a, 0
	jr z, LABEL_F371F9
	stda8 10592, a
	lds wa, 2
	add wa, de
	extz xwa
	add xwa, xbc
	mrib4 0x80, 0x19, 0x61, 0x29
	calr BmDrEdit_PrepareAndInsertNote
	cpdi8 10362, 0
	jr z, LABEL_F371F6
	calr BmDrEdit_RefreshDisplayState
	jr LABEL_F37201

LABEL_F371F6:
	calr BmDrEdit_CalcBeatFromGridPos

LABEL_F371F9:
	inc 1, iz
	cp iz, 0x8
	jr c, LABEL_F371BF

LABEL_F37201:
	popw iz
	ret

BmDrEdit_WalkEventsOrSetError:
	calr BmDrEdit_PrepareAndInsertNote
	cpdi8 10362, 0
	jrl z, BmDrEdit_CalcBeatFromGridPos
	ldw wa, 0xCF
	call SeqData_SetErrorCode
	jrl BmDrEdit_RefreshDisplayState

LABEL_F37218:
	dec 4, xsp
	calr BmDrEdit_LoadAlternateState
	cpdi16 10138, 0
	jr nz, LABEL_F37246
	jr BmDrEdit_CleanupReturn

LABEL_F37227:
	cp l, 0x82
	jr z, BmDrEdit_CleanupReturn
	calr BmDrEdit_ReadEventAtPosition
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cpda16 xwa, 10138
	jr ugt, BmDrEdit_CleanupReturn

LABEL_F37242:
	call SeqData_SkipToNextEvent

LABEL_F37246:
	call SeqData_ReadNextByte
	cp l, 0x81
	jr nz, LABEL_F37227
	stdi8 10080, 0
	incdi16 1, 10078
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cpda16 xwa, 10138
	jr ule, LABEL_F37242

BmDrEdit_CleanupReturn:
	inc 4, xsp
	ret

LABEL_F3726E:
	calr Metronome_PlayClick
	calr BmDrEdit_SelectChannelAndLoadPos
	cpdi8 10362, 0
	jr z, LABEL_F37288
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jr nz, LABEL_F37298
	calr BmDrEdit_SelectChannelAndLoadPos

LABEL_F37288:
	calr BmDrEdit_ScanChannelEvents
	calr BmDrEdit_LoadAlternateState
	calr LABEL_F372B4
	cpdi8 10362, 0
	jr z, LABEL_F3729B

LABEL_F37298:
	jrl BmDrEdit_RefreshDisplayState

LABEL_F3729B:
	calr BmDrEdit_CalcTrackPosition
	calr BmDrEdit_SaveAndFindNote
	calr BmDrEdit_CheckNoteAtPosition
	calr BmDrEdit_SetupAndWalkToNote
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	calr NoteEditSy_SendCompoundWidgetUpdate
	jrl NoteEdit_UpdateScrollAndDisplay

LABEL_F372B4:
	stdi8 10362, 0
	calr BmDrEdit_SaveEditState
	cpdi8 10362, 0
	jr z, LABEL_F372CA
	ldw wa, 0xB6
	call SeqData_SetErrorCode

LABEL_F372CA:
	calr BmDrEdit_CountMeasuresAndValidate
	cpdi16 10098, 0
	ret nz
	stdi16 10098, 2

LABEL_F372DB:
	calr EditChannel_LoadVoiceParams
	calr BmDrEdit_InsertStepEntry
	cpdi8 10362, 0
	jr nz, LABEL_F372F6
	ldda16 xwa, 10098
	dec 1, wa
	stda16 10098, xwa
	cps wa, 0
	jr nz, LABEL_F372DB

LABEL_F372F6:
	jrl BmDrEdit_RestoreEditState

BmDrEdit_SeekToPartVoice:
	ldda8 c, 10597
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceWord
	cp hl, 0xFFFF
	ret z
	stda16 10415, xhl
	stdi16 9830, 5
	cpdi8 10362, 0
	jr z, LABEL_F37325
	ldw wa, 0xB7
	call SeqData_SetErrorCode

LABEL_F37325:
	calr BmDrEdit_CountMeasuresAndValidate
	calr LABEL_F38220
	cpdi8 10362, 0
	jr nz, LABEL_F3734D
	ldda16 xwa, 10114
	inc 2, wa
	stda16 10098, xwa
	cps wa, 0
	ret z

LABEL_F37340:
	calr EditChannel_LoadVoiceParams
	calr BmDrEdit_InsertStepEntry
	cpdi8 10362, 0
	jr z, LABEL_F37350

LABEL_F3734D:
	jrl BmDrEdit_RefreshDisplayState

LABEL_F37350:
	ldda16 xwa, 10098
	dec 1, wa
	stda16 10098, xwa
	cps wa, 0
	jr nz, LABEL_F37340
	ret

BmDrEdit_CalcTickPosition:
	calr LABEL_F38162
	ldda16 xbc, 10114
	mul bc, 0x60
	ldda8 a, 10116
	extz wa
	add bc, wa
	stda16 10138, xbc
	ret

LABEL_F37377:
	calr BmDrEdit_SelectChannelAndLoadPos
	cpdi8 10362, 0
	jr z, LABEL_F3738E
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jr nz, LABEL_F373A5
	calr BmDrEdit_SelectChannelAndLoadPos

LABEL_F3738E:
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_SkipToEventByCount
	cpdi8 10362, 0
	jr z, BmDrEdit_LoadAndDisplayNotes
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jr z, BmDrEdit_LoadAndDisplayNotes

LABEL_F373A5:
	jrl BmDrEdit_RefreshDisplayState

BmDrEdit_LoadAndDisplayNotes:
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_ScanChannelEvents
	calr BmDrEdit_SyncSeekCheck
	calr BmDrEdit_SetupAndWalkToNote
	calr NoteEditSy_SendCompoundWidgetUpdate
	calr NoteEdit_UpdateScrollAndDisplay
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	bitda 0, 10591
	ret z
	calr BmDrEdit_SendMetronomeNoteOn
	ret

BmDrEdit_NavigateAndLoadPosition:
	calr BmDrEdit_CalcTickPosition
	calr BmDrEdit_SelectChannelAndLoadPos
	cpdi8 10362, 0
	jr z, LABEL_F373E5
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jr nz, LABEL_F373FC
	calr BmDrEdit_SelectChannelAndLoadPos

LABEL_F373E5:
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_SkipToEventByCount
	cpdi8 10362, 0
	jr z, BmDrEdit_NavigateAndDisplayNotes
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jr z, BmDrEdit_NavigateAndDisplayNotes

LABEL_F373FC:
	jrl BmDrEdit_RefreshDisplayState

BmDrEdit_NavigateAndDisplayNotes:
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_ScanChannelEvents
	calr BmDrEdit_SyncSeekCheck
	calr BmDrEdit_SaveAndFindNote
	calr BmDrEdit_CheckNoteAtPosition
	calr BmDrEdit_SetupAndWalkToNote
	calr NoteEditSy_SendCompoundWidgetUpdate
	calr NoteEdit_UpdateScrollAndDisplay
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	bitda 0, 10591
	ret z
	calr BmDrEdit_SendMetronomeNoteOn
	ret

BmDrEdit_SkipToEventByCount:
	stdi8 10362, 0
	ldda16 xwa, 10114
	cps wa, 0
	ret z
	stda16 10098, xwa
	cps wa, 0
	ret z

LABEL_F3743D:
	call SeqData_ReadNextByte
	cp l, 0x81
	jr nz, LABEL_F37457
	decdi16 1, 10098

LABEL_F3744A:
	call SeqData_SkipToNextEvent
	cpdi16 10098, 0
	jr nz, LABEL_F3743D
	ret

LABEL_F37457:
	cp l, 0x82
	jr nz, LABEL_F3744A
	stdi8 10362, 255
	ret

LABEL_F37462:
	ldda16 xwa, 10052
	cps wa, 1
	ret ule
	dec 1, wa
	stda16 10052, xwa
	calr BmDrEdit_SelectChannelAndLoadPos
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_ScanChannelEvents
	incdi16 1, 10052
	stdi16 10114, 0
	stdi8 10116, 0
	calr BmDrEdit_LoadAlternatePosition
	calr BmDrEdit_BuildVoiceList
	calr BmDrEdit_SyncSeekCheck
	calr BmDrEdit_SetupAndWalkToNote
	calr NoteEditSy_SendCompoundWidgetUpdate
	calr NoteEdit_UpdateScrollAndDisplay
	call NoteEditSy_SendWidgetCmd0
	jrl NoteEdit_SendScrollCmds

EditChannel_LoadVoiceParams:
	ldda8 c, 10597
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadWord_Indexed
	stda16 10415, xhl
	ldda8 c, 10597
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadByte_Indexed
	stda16 9830, xhl
	ret

LABEL_F374C6:
	dec 4, xsp
	bitda 0, 10591
	jr z, LABEL_F374E5
	calr ReadSeqData_StoreParams
	calr BmDrEdit_SetupAndWalkToNote
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	stda16 10138, xwa

LABEL_F374E5:
	calr NoteEdit_UpdateScrollAndDisplay
	inc 4, xsp
	ret

LABEL_F374EB:
	calr BmDrEdit_SetupAndWalkToNote
	jrl NoteEdit_UpdateScrollAndDisplay

LABEL_F374F1:
	jrl Metronome_PlayClick

LABEL_F374F4:
	bitda 0, 10591
	jr z, LABEL_F3750E
	calr BmDrEdit_CountMeasuresInit
	cpdi8 10362, 0
	jr z, LABEL_F3750E
	ldw wa, 0xCC
	call SeqData_SetErrorCode
	jrl BmDrEdit_RefreshDisplayState

LABEL_F3750E:
	jrl NoteEdit_UpdateScrollAndDisplay

LABEL_F37511:
	jrl NoteEdit_UpdateScrollAndDisplay

LABEL_F37514:
	push_werp 0xFA
	cpdi8 10362, 0
	jr z, LABEL_F37525
	ldw wa, 0xB9
	call SeqData_SetErrorCode

LABEL_F37525:
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ldfr_berp L, 0xFB
	cpdi8 10362, 0
	jr z, LABEL_F3754E
	ldw wa, 0xBA
	call SeqData_SetErrorCode

LABEL_F3754E:
	ldto_berp L, 0xFB
	pop_werp 0xFA
	ret

LABEL_F37555:
	ldda8 c, 10100
	ld a, c
	extz wa
	mul wa, 0x60
	dec 1, wa
	cpdm16 10138, xwa
	jr c, LABEL_F37585
	mul c, 0x60
	stda16 10138, xbc
	bitda 0, 10591
	jrl z, BmDrEdit_NavigateAndLoadPosition
	calr BmDrEdit_CalcTickPosition
	stdi8 10588, 0
	calr ReadSeqData_StoreParams
	jrl LABEL_F37377

LABEL_F37585:
	calr LABEL_F3803F
	cp l, 0xFF
	jr z, LABEL_F37597
	extz hl
	ldda16 xwa, 10114
	cp wa, hl
	jr nc, LABEL_F375A2

LABEL_F37597:
	stdi8 10116, 0
	incdi16 1, 10114
	jr LABEL_F375B5

LABEL_F375A2:
	stdi16 10114, 0
	incdi16 1, 10052
	stdi8 10116, 0
	call NoteEditSy_SendScrollCmd0

LABEL_F375B5:
	call NoteEditSy_SendScrollCmd2
	call NoteEditSy_SendScrollCmd1
	calr NoteEditSy_CallFarRoutine
	calr BmDrEdit_SaveEditState
	calr BmDrEdit_SeekForwardToEvent
	calr BmDrEdit_RestoreEditState
	cpdi8 10362, 0
	jrl nz, BmDrEdit_RefreshDisplayState
	jrl BmDrEdit_SetFeedbackTimer

NoteEditSy_CallFarRoutine:
	jrl BmDrEdit_BuildVoiceList

LABEL_F375D7:
	dec 4, xsp
	bitda 7, 10588
	jrl nz, BmDrEdit_AdjustViewReturn
	calr BmDrEdit_SaveEditState
	ldmm16 10140, 10138
	calr BmDrEdit_AlignDisplayGrid
	ldda8 a, 10100
	mul a, 0x60
	cpdm16 10138, xwa
	call_24 c, 0xF38445
	bitda 0, 10591
	jr nz, BmDrEdit_WalkTrackLoop
	calr LABEL_F3767B
	call SeqData_ReadNextByte
	and l, 0xF0
	cp l, 0x90
	jr nz, BmDrEdit_WalkTrackLoop
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr nz, BmDrEdit_WalkTrackLoop
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cpda16 xwa, 10138
	jr ule, LABEL_F37675
	bitda 1, 10591
	jr z, BmDrEdit_WalkTrackLoop
	calr BmDrEdit_InsertNoteSequence
	bitda 2, 10591
	jr nz, LABEL_F37656
	jr BmDrEdit_AdjustViewPath

BmDrEdit_WalkTrackLoop:
	calr BmDrEdit_WalkTrackForward
	ldda8 a, 10591
	bit 4, a
	jr nz, BmDrEdit_AdjustViewPath
	bit 1, a
	jr z, LABEL_F3765B
	calr BmDrEdit_InsertNoteSequence
	bitda 2, 10591
	jr z, BmDrEdit_AdjustViewPath

LABEL_F37656:
	calr BmDrEdit_RefreshDisplayState
	jr BmDrEdit_AdjustViewReturn

LABEL_F3765B:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ldda16 xwa, 10138
	add (xsp), wa
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jr ule, LABEL_F37675

BmDrEdit_AdjustViewPath:
	calr BmDrEdit_AdjustViewToPosition
	jr BmDrEdit_AdjustViewReturn

LABEL_F37675:
	calr BmDrEdit_InitViewAndNavigate

BmDrEdit_AdjustViewReturn:
	inc 4, xsp
	ret

LABEL_F3767B:
	dec 4, xsp
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_CheckNoteAtPosition
	call SeqData_ReadNextByte
	and l, 0xF0
	cp l, 0x90
	jr nz, LABEL_F376A1
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr z, BmDrEdit_AdvanceToVisibleNote
	calr BmDrEdit_WalkTrackForward
	bitda 1, 10591
	jr z, BmDrEdit_AdvanceToVisibleNote
	jr BmDrEdit_WalkReturn

LABEL_F376A1:
	calr BmDrEdit_WalkTrackForward
	bitda 1, 10591
	jr nz, BmDrEdit_WalkReturn

BmDrEdit_AdvanceToVisibleNote:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cpda16 xwa, 10140
	jr ugt, BmDrEdit_WalkReturn
	calr BmDrEdit_WalkTrackForward
	bitda 1, 10591
	jr z, BmDrEdit_AdvanceToVisibleNote

BmDrEdit_WalkReturn:
	inc 4, xsp
	ret

BmDrEdit_InitViewAndNavigate:
	dec 4, xsp
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	stda16 10138, xwa
	ldda8 a, 10100
	mul a, 0x60
	cpdm16 10138, xwa
	jr c, LABEL_F376EE
	calr BmDrEdit_NavigateAndLoadPosition
	jr LABEL_F37701

LABEL_F376EE:
	calr BmDrEdit_CalcBeatMeasure
	calr BmDrEdit_SetupAndWalkToNote
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	calr NoteEdit_UpdateScrollAndDisplay
	calr BmDrEdit_SendMetronomeNoteOn

LABEL_F37701:
	inc 4, xsp
	ret

BmDrEdit_AdjustViewToPosition:
	ldda8 a, 10100
	mul a, 0x60
	cpdm16 10138, xwa
	jrl nc, BmDrEdit_NavigateAndLoadPosition
	resda 0, 10591
	calr BmDrEdit_RestoreEditState
	calr BmDrEdit_CalcBeatMeasure
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	jrl NoteEdit_UpdateScrollAndDisplay

BmDrEdit_SendMetronomeNoteOn:
	calr Metronome_PlayClick
	calr LABEL_F37740
	stdi8 10590, 134
	ret

BmDrEdit_SendMetronomeNoteOn_Alt:
	calr Metronome_PlayClick
	calr LABEL_F3776B
	stdi8 10590, 134
	ret

Metronome_PlayClick:
	jr LABEL_F37795

LABEL_F37740:
	dec 8, xsp
	lda xwa, (xsp)
	ld (xwa), 0x90
	ld (xwa + 1), 0x7E
	ldmi16 (xwa + 2), 0x2786
	ldmi16 (xwa + 3), 0x2788
	ldmi16 (xwa + 4), 0x2965
	ld (xwa + 5), 0x0
	lds bc, 5
	call SeqBuf_WriteMidiEvent
	call SeqBuf_FlushAndReinit_NoteEvents
	inc 8, xsp
	ret

LABEL_F3776B:
	dec 8, xsp
	lda xwa, (xsp)
	ld (xwa), 0x90
	ld (xwa + 1), 0x7E
	ldmi16 (xwa + 2), 0x2786
	ld (xwa + 3), 0x50
	ldmi16 (xwa + 4), 0x2965
	ld (xwa + 5), 0x0
	lds bc, 5
	call SeqBuf_WriteMidiEvent
	call SeqBuf_FlushAndReinit_NoteEvents
	inc 8, xsp
	ret

LABEL_F37795:
	ldda8 a, 10597
	inc 1, a
	extz wa
	jp SeqBuf_WriteNoteOffEntry

BmDrEdit_InsertNoteSequence:
	push xiz
	ldda16 xwa, 10415
	ldfr_werp WA, 0xFA
	ldda16 xiz, 9830
	resda 2, 10591
	calr LABEL_F37884
	ldda16 xbc, 10138
	extz xbc
	div bc, 0x60
	inc 1, bc
	ldda16 xwa, 10098
	cp bc, wa
	jr c, LABEL_F37804
	inc 1, bc
	sub bc, wa
	stda16 10098, xbc
	calr EditChannel_LoadVoiceParams
	cpdi16 10098, 0
	jr z, BmDrEdit_SavePositionAndReturn

LABEL_F377DB:
	calr BmDrEdit_InsertStepEntry
	cpdi8 10362, 0
	jr z, LABEL_F377EB
	setda 2, 10591
	jr BmDrEdit_SavePositionAndReturn

LABEL_F377EB:
	ldda16 xwa, 10098
	dec 1, wa
	stda16 10098, xwa
	cps wa, 0
	jr nz, LABEL_F377DB

BmDrEdit_SavePositionAndReturn:
	ldto_werp WA, 0xFA
	stda16 10415, xwa
	stda16 9830, xiz

LABEL_F37804:
	pop xiz
	ret

LABEL_F37806:
	dec 4, xsp
	resda 3, 10591
	cpdi16 10140, 0
	jr nz, LABEL_F37838
	call SeqData_ReadNextByte
	cp l, 0x81
	jr z, BmDrEdit_SetFlagReturn
	and l, 0xF0
	cp l, 0x90
	jr z, LABEL_F3782A
	calr BmDrEdit_WalkAndScanAfterEdit
	jr LABEL_F37860

LABEL_F3782A:
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr nz, BmDrEdit_SetFlagReturn
	cpdi8 10080, 0
	jr nz, BmDrEdit_SetFlagReturn

LABEL_F37838:
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_CheckNoteAtPosition

LABEL_F3783E:
	calr BmDrEdit_SaveEditState
	calr BmDrEdit_WalkTrackForward
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cpda16 xwa, 10140
	jr c, LABEL_F3783E
	calr BmDrEdit_RestoreEditState
	jr LABEL_F37860

BmDrEdit_SetFlagReturn:
	setda 3, 10591

LABEL_F37860:
	inc 4, xsp
	ret

LABEL_F37863:
	ldda16 xwa, 10138
	cps wa, 0
	ret z
	lds de, 0
	cps wa, 0
	jr ule, LABEL_F3787B
	ldda16 xbc, 10130

LABEL_F37875:
	add de, bc
	cp de, wa
	jr c, LABEL_F37875

LABEL_F3787B:
	subda16 xde, 10130
	stda16 10138, xde
	ret

LABEL_F37884:
	calr BmDrEdit_LoadAlternateState
	cpdi8 10362, 0
	jr z, LABEL_F37895
	ldw wa, 0xB8
	call SeqData_SetErrorCode

LABEL_F37895:
	jr __jrt_nop_F37897
__jrt_nop_F37897:

BmDrEdit_CountMeasuresAndValidate:
	cpdi8 10362, 0
	jr z, LABEL_F378A5
	ldw wa, 0xD1
	call SeqData_SetErrorCode

LABEL_F378A5:
	stdi16 10098, 0

LABEL_F378AB:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_CheckAndReportScanError
	cp l, 0x84
	jr z, BmDrEdit_CheckAndReportScanError
	cp l, 0x81
	jr nz, LABEL_F378C2
	incdi16 1, 10098

LABEL_F378C2:
	call SeqData_SkipToNextEvent
	jr LABEL_F378AB

BmDrEdit_CheckAndReportScanError:
	cpdi8 10362, 0
	ret z
	ldw wa, 0xCE
	call SeqData_SetErrorCode
	ret

LABEL_F378D7:
	dec 4, xsp
	bitda 7, 10588
	jrl nz, BmDrEdit_NavigateReturn
	calr BmDrEdit_SaveEditState
	ldmm16 10140, 10138
	calr LABEL_F37863
	calr BmDrEdit_CalcBeatMeasure
	bitda 0, 10591
	jr nz, BmDrEdit_NavigateAfterEdit
	calr LABEL_F37806
	bitda 3, 10591
	jr z, LABEL_F3791A
	cpdi16 10052, 1
	jr z, BmDrEdit_ResetToFirstEvent
	cpdi16 10140, 0
	jr z, BmDrEdit_GoToPrevPage

BmDrEdit_ResetToFirstEvent:
	calr BmDrEdit_AdjustViewToPosition
	jrl BmDrEdit_NavigateReturn

BmDrEdit_GoToPrevPage:
	calr BmDrEdit_NavigatePrevPage
	jrl BmDrEdit_NavigateReturn

LABEL_F3791A:
	ldda16 xwa, 10094
	cpda16 xwa, 10415
	jr nz, BmDrEdit_CheckCurrentNoteMatch
	ldda8 a, 10096
	extz wa
	cpda16 xwa, 9830
	jr nz, BmDrEdit_CheckCurrentNoteMatch
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cpdm16 10140, xwa
	jr ule, BmDrEdit_ResetToFirstEvent

BmDrEdit_CheckCurrentNoteMatch:
	call SeqData_ReadNextByte
	and l, 0xF0
	cp l, 0x90
	jr nz, BmDrEdit_NavigateAfterEdit
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr nz, BmDrEdit_NavigateAfterEdit
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cpda16 xwa, 10138
	jr nc, LABEL_F379A2

BmDrEdit_NavigateAfterEdit:
	calr BmDrEdit_WalkAndScanAfterEdit
	bitda 3, 10591
	jr z, LABEL_F37984
	cpdi16 10052, 1
	jr z, BmDrEdit_ResetToFirstEvent
	cpdi16 10140, 0
	jr z, BmDrEdit_GoToPrevPage
	jr BmDrEdit_ResetToFirstEvent

LABEL_F37984:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jrl c, BmDrEdit_ResetToFirstEvent
	ldda16 xwa, 10138
	add (xsp), wa
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jrl c, BmDrEdit_ResetToFirstEvent

LABEL_F379A2:
	calr BmDrEdit_InitViewAndNavigate

BmDrEdit_NavigateReturn:
	inc 4, xsp
	ret

BmDrEdit_WalkAndScanAfterEdit:
	dec 4, xsp
	resda 3, 10591
	call SeqData_ReadNextByte
	cp l, 0x81
	jr nz, BmDrEdit_ScanSequenceEnd
	ldda16 xwa, 10078
	cps wa, 0
	jr z, BmDrEdit_CheckVelocityMatch
	dec 1, wa
	stda16 10078, xwa
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jr c, BmDrEdit_CheckVelocityMatch

BmDrEdit_ScanSequenceEnd:
	calr BmDrEdit_ClearAndScanToEnd
	cpdi8 10362, 0
	jr z, LABEL_F379E9
	setda 3, 10591
	stdi8 10362, 0
	jr LABEL_F37A36

LABEL_F379E9:
	call SeqData_ReadNextByte
	cp l, 0x81
	jr nz, LABEL_F37A11
	ldda16 xwa, 10078
	cps wa, 0
	jr z, BmDrEdit_CheckVelocityMatch
	dec 1, wa
	stda16 10078, xwa
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jr nc, BmDrEdit_ScanSequenceEnd
	jr BmDrEdit_CheckVelocityMatch

LABEL_F37A11:
	and l, 0xF0
	cp l, 0x90
	jr nz, BmDrEdit_ScanSequenceEnd
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr nz, BmDrEdit_ScanSequenceEnd
	calr BmDrEdit_ReadEventAtPosition
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jr nc, LABEL_F37A36

BmDrEdit_CheckVelocityMatch:
	setda 3, 10591

LABEL_F37A36:
	inc 4, xsp
	ret

LABEL_F37A39:
	bitda 7, 10054
	ret nz
	bitda 7, 10588
	ret nz
	ldw wa, 0x96
	jp UI_PostModeChangeEvent

LABEL_F37A4C:
	bitda 7, 10588
	jr z, LABEL_F37A59
	cpdi8 10589, 5
	ret nz

LABEL_F37A59:
	resda 0, 10591
	jr __jrt_nop_F37A5F
__jrt_nop_F37A5F:

LABEL_F37A5F:
	bitda 7, 10054
	ret nz
	ldda16 xwa, 10144
	cp wa, 0xB
	jr c, LABEL_F37A81
	ldda16 xwa, 10142
	cp wa, 0x74
	ret nc
	inc 1, wa
	stda16 10142, xwa
	jr LABEL_F37A87

LABEL_F37A81:
	inc 1, wa
	stda16 10144, xwa

LABEL_F37A87:
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	call NoteEditSy_UpdateChordDisplay
	calr BmDrEdit_SendMetronomeNoteOn_Alt
	stdi8 10588, 131
	stdi8 10589, 5
	jp Audio_CheckSubsystemReady

LABEL_F37AA3:
	bitda 7, 10588
	jr z, LABEL_F37AB0
	cpdi8 10589, 5
	ret nz

LABEL_F37AB0:
	resda 0, 10591
	jr __jrt_nop_F37AB6
__jrt_nop_F37AB6:

LABEL_F37AB6:
	bitda 7, 10054
	ret nz
	ldda16 xwa, 10144
	cps wa, 0
	jr nz, LABEL_F37AD4
	ldda16 xwa, 10142
	cps wa, 1
	ret z
	dec 1, wa
	stda16 10142, xwa
	jr LABEL_F37ADA

LABEL_F37AD4:
	dec 1, wa
	stda16 10144, xwa

LABEL_F37ADA:
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	call NoteEditSy_UpdateChordDisplay
	calr BmDrEdit_SendMetronomeNoteOn_Alt
	stdi8 10588, 131
	stdi8 10589, 5
	jp Audio_CheckSubsystemReady

BmDrEdit_CalcTrackPosition:
	bitda 0, 10050
	ret z
	ldda16 xwa, 10142
	addda16 xwa, 10144
	stda8 10118, a
	ret

LABEL_F37B09:
	bitda 7, 10054
	ret nz
	bitda 7, 10588
	ret nz
	ldw wa, 0x99
	jp UI_PostModeChangeEvent

LABEL_F37B1C:
	calr BmDrEdit_SetupAndWalkToNote
	jrl NoteEdit_UpdateScrollAndDisplay

LABEL_F37B22:
	calr BmDrEdit_SendMetronomeNoteOn
	stdi8 10590, 134
	ret

BmDrEdit_ApplyVelocityChange:
	lda xsp, (xsp - 20)
	pushw iz
	ld (xsp + 14), de
	ld (xsp + 16), xbc
	ld (xsp + 20), a
	cpw (xsp + 14), 0x0
	jrl z, LABEL_F37C40
	cpw (xsp + 14), 0xFF
	jr ugt, LABEL_F37BA9
	ldmw2 (xsp + 2), 0x28AF
	ldmw2 (xsp + 4), 0x2666
	ld c, (xsp + 20)
	extz bc
	lds wa, 0
	call Part_ReadWord_Indexed
	ld (xsp + 12), hl
	ld c, (xsp + 20)
	extz bc
	lds wa, 0
	call Part_ReadByte_Indexed
	ld (xsp + 10), hl
	ld wa, (xsp + 12)
	ld (xsp + 8), wa
	ld wa, (xsp + 10)
	add wa, (xsp + 14)
	ld (xsp + 6), wa
	cpw (xsp + 6), 0xFF
	jr ule, LABEL_F37BB7
	ld wa, (xsp + 12)
	call PartCtrl_ReadWord
	ld (xsp + 8), hl
	cpw (xsp + 8), 0xFFFF
	jr nz, LABEL_F37BAF
	ld wa, (xsp + 12)
	call Part_LinkVoiceToChain
	ld (xsp + 8), hl
	cps hl, 0
	jr ge, LABEL_F37BAF
	ldw wa, 0xBB
	call SeqData_SetErrorCode

LABEL_F37BA9:
	ldw hl, 0xFFFF
	jrl LABEL_F37C42

LABEL_F37BAF:
	submi16 (xsp + 6), 0xFF
	incm 4, (xsp + 6)

LABEL_F37BB7:
	ld c, (xsp + 20)
	extz bc
	ld de, (xsp + 8)
	lds wa, 0
	call Part_WriteWord_Indexed
	ld c, (xsp + 20)
	extz bc
	ld wa, (xsp + 6)
	ld e, a
	extz de
	lds wa, 0
	call Part_WriteByte_Indexed

LABEL_F37BD7:
	ld wa, (xsp + 12)
	ld bc, (xsp + 10)
	calr PartCtrl_ReadByteExtended
	extz hl
	ld wa, (xsp + 8)
	ld bc, (xsp + 6)
	ld de, hl
	calr PartCtrl_WriteByte_ZeroExtended
	ldda16 xwa, 10415
	cp wa, (xsp + 12)
	jr nz, LABEL_F37BFF
	ldda16 xwa, 9830
	cp wa, (xsp + 10)
	jr z, LABEL_F37C13

LABEL_F37BFF:
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 10)
	calr BmDrEdit_DecrementAndValidateCounter
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 6)
	calr BmDrEdit_DecrementAndValidateCounter
	jr LABEL_F37BD7

LABEL_F37C13:
	lds iz, 0
	cpw (xsp + 14), 0x0
	jr ule, LABEL_F37C36

LABEL_F37C1C:
	ld wa, iz
	extz xwa
	add xwa, (xsp + 16)
	ld a, (xwa)
	extz wa
	call PartCtrl_WriteByte_Indexed
	call SeqData_AdvancePosition
	inc 1, iz
	cp iz, (xsp + 14)
	jr c, LABEL_F37C1C

LABEL_F37C36:
	mrdw5 0x9F, 0x02, 0x19, 0xAF, 0x28
	mrdw5 0x9F, 0x04, 0x19, 0x66, 0x26

LABEL_F37C40:
	lds hl, 0

LABEL_F37C42:
	popw iz
	lda xsp, (xsp + 20)
	ret

BmDrEdit_DecrementAndValidateCounter:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	ld xwa, (xsp + 4)
	decm 1, (xwa)
	cpw (xwa), 0x5
	jr nc, LABEL_F37C7B
	ld wa, (xiz)
	call PartCtrl_ReadWord_Off1
	ld (xiz), hl
	cpw (xiz), 0x4D8
	jr ule, LABEL_F37C74
	ldw wa, 0xA0
	call SeqData_SetErrorCode
	ldw hl, 0xFFFF
	jr LABEL_F37C7D

LABEL_F37C74:
	ld xwa, (xsp + 4)
	ldw (xwa), 0xFF

LABEL_F37C7B:
	lds hl, 0

LABEL_F37C7D:
	pop xiz
	inc 4, xsp
	ret

PartCtrl_ReadWordWithBoundsCheck:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	ld xwa, (xsp + 4)
	incm 1, (xwa)
	cpw (xwa), 0xFF
	jr ule, LABEL_F37CB5
	ld wa, (xiz)
	call PartCtrl_ReadWord
	ld (xiz), hl
	cpw (xiz), 0x4D8
	jr ule, LABEL_F37CAE
	ldw wa, 0xA1
	call SeqData_SetErrorCode
	ldw hl, 0xFFFF
	jr LABEL_F37CB7

LABEL_F37CAE:
	ld xwa, (xsp + 4)
	ldw (xwa), 0x5

LABEL_F37CB5:
	lds hl, 0

LABEL_F37CB7:
	pop xiz
	inc 4, xsp
	ret

PartCtrl_ReadByteExtended:
	extz bc
	jp PartCtrl_ReadByte

PartCtrl_WriteByte_ZeroExtended:
	extz bc
	extz de
	jp PartCtrl_WriteByteToBuf

BmDrEdit_InsertStepEntry:
	dec 2, xsp
	calr BmDrEdit_SaveSongPosition
	stdi8 10362, 0
	ld (xsp), 0x81
	ldda8 a, 10597
	inc 1, a
	extz wa
	lda xbc, (xsp)
	lds de, 1
	calr BmDrEdit_ApplyVelocityChange
	inc 2, xsp
	ret

BmDrEdit_PrepareAndInsertNote:
	calr LABEL_F37218
	stdi8 10599, 144
	ldda16 xwa, 10138
	extz xwa
	div wa, 0x60
	ldto_werp WA, 0xE2
	stda8 10600, a
	ldmm8 10601, 10592
	ldmm8 10602, 10593
	ldda16 xwa, 10126
	extz xwa
	div wa, 0x60
	ldto_werp WA, 0xE2
	res 7, a
	stda8 10603, a
	ldda16 xwa, 10126
	extz xwa
	div wa, 0x60
	res 7, a
	stda8 10604, a
	calr BmDrEdit_SaveSongPosition
	ldda8 a, 10597
	inc 1, a
	extz wa
	ld xbc, 0x2967
	lds de, 6
	jrl BmDrEdit_ApplyVelocityChange

BmDrEdit_ValidateAndProcessVoice:
	dec 8, xsp
	push xiz
	ld (xsp + 6), xde
	ld (xsp + 10), a
	stdi8 10362, 0
	stda8 10381, c
	call SeqVoice_SetDefaultParams
	ld a, (xsp + 10)
	extz wa
	call Part_ValidateVoiceChannel
	cpdi8 10362, 0
	jr z, LABEL_F37D71
	ldb l, 0xFF
	jr LABEL_F37DD5

LABEL_F37D71:
	ldda16 xiz, 10415
	ldda16 xwa, 9830
	ldfr_werp WA, 0xFA
	call SeqVoice_ValidateAndProcessState
	stda16 10415, xiz
	ldto_werp WA, 0xFA
	stda16 9830, xwa
	ldw (xsp + 4), 0x1
	ld xwa, (xsp + 6)
	ldw (xwa), 0x0
	cpdi16 10367, 1
	jr z, BmDrEdit_TrackValidateRet

LABEL_F37D9F:
	ldda8 a, 10382
	extz wa
	ld xbc, (xsp + 6)
	ld bc, (xbc)
	call SeqData_SkipSections
	ld xwa, (xsp + 6)
	ld (xwa), hl
	cpdi8 10362, 0
	jr nz, BmDrEdit_TrackValidateRet
	incm 1, (xsp + 4)
	call SeqTrack_ProcessControlBytes
	cpdi8 10362, 0
	jr nz, BmDrEdit_TrackValidateRet
	ld wa, (xsp + 4)
	cpda16 xwa, 10367
	jr nz, LABEL_F37D9F

BmDrEdit_TrackValidateRet:
	ldda8 l, 10382

LABEL_F37DD5:
	pop xiz
	inc 8, xsp
	ret

BmDrEdit_SyncChannelAndGetPos:
	dec 2, xsp
	ldmm16 10367, 10052
	calr BmDrEdit_CheckAndSelectChannel
	ldda8 a, 10597
	inc 1, a
	extz wa
	extz hl
	lda xde, (xsp)
	ld bc, hl
	calr BmDrEdit_ValidateAndProcessVoice
	ld hl, (xsp)
	inc 2, xsp
	ret

BmDrEdit_SelectChannelAndLoadPos:
	stdi8 10362, 0
	calr BmDrEdit_SyncChannelAndGetPos
	cpdi8 10362, 0
	ret nz
	stda16 10090, xhl
	stdi8 10092, 0
	ldmm16 10094, 10415
	ldda16 xwa, 9830
	stda8 10096, a
	ret

BmDrEdit_LoadAlternatePosition:
	stdi8 10362, 0
	calr BmDrEdit_SyncChannelAndGetPos
	cpdi8 10362, 0
	ret nz
	stda16 10078, xhl
	stdi8 10080, 0
	ret

BmDrEdit_CopyEventDataBetweenParts:
	lda xsp, (xsp - 10)
	push_werp 0xFA
	ld (xsp + 10), a
	calr BmDrEdit_SaveSongPosition
	ldda16 xwa, 10415
	ldda16 xbc, 9830
	ld (xsp + 8), wa
	ld (xsp + 6), bc
	call SeqData_SkipToNextEvent
	ldmw2 (xsp + 4), 0x28AF
	ldmw2 (xsp + 2), 0x2666

LABEL_F37E62:
	ld wa, (xsp + 4)
	ld bc, (xsp + 2)
	calr PartCtrl_ReadByteExtended
	ldfr_berp L, 0xFB
	ldto_berp E, 0xFB
	extz de
	ld wa, (xsp + 8)
	ld bc, (xsp + 6)
	calr PartCtrl_WriteByte_ZeroExtended
	cp_erpb 0xFB, 0x82
	jr z, BmDrEdit_FinalizePartTransfer
	cp_erpb 0xFB, 0x84
	jr z, BmDrEdit_FinalizePartTransfer
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 6)
	calr PartCtrl_ReadWordWithBoundsCheck
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 2)
	calr PartCtrl_ReadWordWithBoundsCheck
	jr LABEL_F37E62

BmDrEdit_FinalizePartTransfer:
	ld c, (xsp + 10)
	extz bc
	ld de, (xsp + 8)
	lds wa, 0
	call Part_WriteWord_Indexed
	ld c, (xsp + 10)
	extz bc
	ld wa, (xsp + 6)
	ld e, a
	extz de
	lds wa, 0
	call Part_WriteByte_Indexed
	ld wa, (xsp + 8)
	call PartCtrl_ReadWord
	ld wa, hl
	call Part_StealAndReallocVoices
	ld wa, (xsp + 8)
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	lds hl, 0
	pop_werp 0xFA
	lda xsp, (xsp + 10)
	ret

LABEL_F37EDC:
	push xiz
	bitda 7, 10588
	jr nz, LABEL_F37F44
	bitda 0, 10591
	jr z, LABEL_F37F44
	ldda8 a, 10597
	inc 1, a
	extz wa
	calr BmDrEdit_CopyEventDataBetweenParts
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, LABEL_F37F02
	cp l, 0x84
	jr nz, LABEL_F37F09

LABEL_F37F02:
	stdi8 10080, 0
	jr NoteEdit_FinalizeAndRefreshDisplay

LABEL_F37F09:
	cp l, 0x81
	jr nz, LABEL_F37F14
	incdi16 1, 10078
	jr NoteEdit_FinalizeAndRefreshDisplay

LABEL_F37F14:
	ldda16 xwa, 10415
	ldfr_werp WA, 0xFA
	ldda16 xiz, 9830
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stda8 10080, l
	ldto_werp WA, 0xFA
	stda16 10415, xwa
	stda16 9830, xiz

NoteEdit_FinalizeAndRefreshDisplay:
	resda 0, 10591
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	calr NoteEdit_UpdateScrollAndDisplay

LABEL_F37F44:
	pop xiz
	ret

BmDrEdit_ScanChannelEvents:
	dec 4, xsp
	pushw iz
	calr BmDrEdit_SaveEditState
	ldda16 xwa, 10052
	stda16 10162, xwa
	ldmm16 10367, 10052
	lds iz, 0
	ldw (xsp + 2), 0x0

LABEL_F37F61:
	calr BmDrEdit_CheckAndSelectChannel
	ldda8 a, 10597
	inc 1, a
	bitda 2, 10363
	jr z, LABEL_F37F72
	ld a, l

LABEL_F37F72:
	extz wa
	extz hl
	lda xde, (xsp + 4)
	ld bc, hl
	calr BmDrEdit_ValidateAndProcessVoice
	ldada xwa, 10148
	cpdi8 10362, 0
	jr z, LABEL_F37FBF
	ld xbc, xwa
	ldda8 a, 10146
	ldfr_berp A, 0xF0
	extz ix
	ld wa, (xsp + 2)

LABEL_F37F97:
	ldda8 l, 10382
	incm 1, (xsp + 2)
	inc 1, a
	ld iy, iz
	extz xiy
	add xiy, xbc
	ld (xiy), a

LABEL_F37FA8:
	inc 1, iz
	cp iz, ix
	jr nc, LABEL_F37FDB
	cps l, 1
	jr z, LABEL_F37F97
	ld de, iz
	extz xde
	add xde, xbc
	ld (xde), 0x0
	dec 1, l
	jr LABEL_F37FA8

LABEL_F37FBF:
	incm 1, (xsp + 2)
	ld xbc, xwa
	ld de, iz
	extz xde
	add xde, xwa
	ld wa, (xsp + 2)
	ld (xde), a
	ldda8 e, 10146
	extz de

LABEL_F37FD5:
	inc 1, iz
	cp iz, de
	jr c, LABEL_F37FE7

LABEL_F37FDB:
	calr BmDrEdit_RestoreEditState
	stdi8 10362, 0
	popw iz
	inc 4, xsp
	ret

LABEL_F37FE7:
	cps l, 1
	jr nz, LABEL_F37FF2
	incdi16 1, 10367
	jrl LABEL_F37F61

LABEL_F37FF2:
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld (xwa), 0x0
	dec 1, l
	jr LABEL_F37FD5

BmDrEdit_BuildVoiceList:
	ldda16 xbc, 10052
	subda16 xbc, 10162
	inc 1, bc
	ld h, c
	lds ix, 0
	ldb l, 0x0
	ldada xde, 10148
	lds wa, 0
	jr LABEL_F3801D

LABEL_F38017:
	inc 1, ix
	inc 1, l
	inc 1, wa

LABEL_F3801D:
	ld bc, wa
	extz xbc
	add xbc, xde
	cp (xbc), h
	jr nz, LABEL_F38017
	ldda16 xbc, 10114
	add bc, ix
	mul bc, 0x60
	ldda8 a, 10116
	extz wa
	add bc, wa
	stda16 10138, xbc
	ret

LABEL_F3803E:
	ret

LABEL_F3803F:
	ldda16 xhl, 10052
	subda16 xhl, 10162
	inc 1, l
	ldb e, 0x0
	ldada xbc, 10148

LABEL_F3804F:
	ld a, e
	extz wa
	extz xwa
	add xwa, xbc
	inc 1, e
	cp (xwa), l
	jr nz, LABEL_F3806F
	ldb l, 0x0
	ld a, e
	extz wa
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, BmDrEdit_FindNextNonZeroEntry
	ldb l, 0x0
	ret

LABEL_F3806F:
	cpda8 e, 10146
	jr c, LABEL_F3804F
	ldb l, 0xFF
	ret

LABEL_F38078:
	inc 1, e
	inc 1, l
	cpda8 e, 10146
	jr c, BmDrEdit_FindNextNonZeroEntry
	ldb l, 0xFF
	jr LABEL_F38093

BmDrEdit_FindNextNonZeroEntry:
	ld a, e
	extz wa
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, LABEL_F38078

LABEL_F38093:
	ret

BmDrEdit_AdjustScrollToView:
	dec 4, xsp
	bitda 0, 10050
	jr nz, NoteEditSy_ScrollComplete_Return
	ldmm8 10186, 10136

BmDrEdit_ScrollAdjustLoop:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupScrollRegion
	ldda8 c, 10594
	ldda8 a, 10136
	cp c, (xsp + 2)
	jr nc, LABEL_F380C5
	ld c, a
	cps a, 0
	jr z, NoteEditSy_ScrollComplete_Return
	dec 1, c
	stda8 10136, c
	jr BmDrEdit_ScrollAdjustLoop

LABEL_F380C5:
	cp c, (xsp)
	jr ule, LABEL_F380D8
	ld c, a
	cp a, 0x9
	jr nc, NoteEditSy_ScrollComplete_Return
	inc 1, c
	stda8 10136, c
	jr BmDrEdit_ScrollAdjustLoop

LABEL_F380D8:
	ldda8 a, 10186
	cpda8 a, 10136
	jr z, NoteEditSy_ScrollComplete_Return
	call NoteEditSy_UpdateChordDisplay

NoteEditSy_ScrollComplete_Return:
	inc 4, xsp
	ret

BmDrEdit_CountMeasuresInit:
	push_werp 0xFA
	stdi8 10362, 0
	calr BmDrEdit_SaveEditState
	calr LABEL_F37514
	ldfr_berp L, 0xFB
	inc1_berp 0xFB
	cpdi8 10362, 0
	jr z, LABEL_F3810B
	ldw wa, 0xB5
	call SeqData_SetErrorCode

LABEL_F3810B:
	calr BmDrEdit_CountMeasuresAndValidate
	inc1_berp 0xFB
	ldto_berp A, 0xFB
	extz wa
	ldda16 xbc, 10098
	cp wa, bc
	jr c, BmDrEdit_RestoreEditRet
	ldto_berp A, 0xFB
	sub a, c
	inc 1, a
	ldfr_berp A, 0xFB
	extz wa
	stda16 10098, xwa
	cps wa, 0
	jr z, BmDrEdit_RestoreEditRet

LABEL_F38132:
	calr EditChannel_LoadVoiceParams
	calr BmDrEdit_InsertStepEntry
	cpdi8 10362, 0
	jr z, LABEL_F3814D
	ldw wa, 0xCD
	call SeqData_SetErrorCode
	stdi8 10362, 255
	jr BmDrEdit_RestoreEditRet

LABEL_F3814D:
	ldda16 xwa, 10098
	dec 1, wa
	stda16 10098, xwa
	cps wa, 0
	jr nz, LABEL_F38132

BmDrEdit_RestoreEditRet:
	calr BmDrEdit_RestoreEditState
	pop_werp 0xFA
	ret

LABEL_F38162:
	ldda8 a, 10146
	dec 1, a
	extz wa
	ldada xbc, 10148
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, LABEL_F38183
	incdi16 1, 10052
	stdi16 10114, 0
	jr LABEL_F38187

LABEL_F38183:
	incdi16 1, 10114

LABEL_F38187:
	ldda16 xbc, 10138
	ldda8 a, 10100
	mul a, 0x60
	sub bc, wa
	stda8 10116, c
	ret

LABEL_F38199:
	lda xsp, (xsp - 10)
	ld (xsp), xde
	ld (xsp + 4), xbc
	ld (xsp + 8), a
	call SeqVoice_SetDefaultParams
	stdi8 10362, 0
	bitda 2, 10363
	jr nz, LABEL_F381E5
	ldda8 c, 1075
	extz bc
	ldda16 xwa, 3299
	extz xwa
	div xwa, xbc
	ld bc, wa
	ld xde, (xsp + 4)
	ld (xde), bc
	ldda8 c, 1075
	extz bc
	ldda16 xwa, 3299
	extz xwa
	div xwa, xbc
	ldto_werp BC, 0xE2
	ld xwa, (xsp)
	ld (xwa), bc
	incm 1, (xde)
	ldda8 l, 1075
	jr LABEL_F3821C

LABEL_F381E5:
	mrdb5 0x8F, 0x08, 0x19, 0x8D, 0x28
	call SeqVoice_ValidateAndProcessState
	ldda8 l, 10382
	ld xwa, (xsp)
	ldmw2 (xwa), 0xCE3
	ld xwa, (xsp + 4)
	ldw (xwa), 0x1
	jr LABEL_F38212

LABEL_F38201:
	ld xwa, (xsp)
	sub (xwa), bc
	ld xwa, (xsp + 4)
	incm 1, (xwa)
	call SeqTrack_ProcessControlBytes
	ldda8 l, 10382

LABEL_F38212:
	ld c, l
	extz bc
	ld xwa, (xsp)
	cp (xwa), bc
	jr nc, LABEL_F38201

LABEL_F3821C:
	lda xsp, (xsp + 10)
	ret

LABEL_F38220:
	dec 4, xsp
	ldmm16 3299, 10098
	ldmm16 10078, 10098

LABEL_F3822E:
	calr BmDrEdit_CheckAndSelectChannel
	extz hl
	lda xbc, (xsp + 2)
	lda xde, (xsp)
	ld wa, hl
	calr LABEL_F38199
	ldda16 xwa, 10052
	cp wa, (xsp + 2)
	jr z, LABEL_F3827D
	cpw (xsp), 0x0
	jr z, LABEL_F38250
	ld wa, (xsp)
	sub l, a

LABEL_F38250:
	extz hl
	stda16 10098, xhl

LABEL_F38256:
	calr EditChannel_LoadVoiceParams
	calr BmDrEdit_InsertStepEntry
	cpdi8 10362, 0
	jr nz, LABEL_F3827D
	incdi16 1, 10078
	ldda16 xwa, 10098
	dec 1, wa
	stda16 10098, xwa
	cps wa, 0
	jr nz, LABEL_F38256
	ldmm16 3299, 10078
	jr LABEL_F3822E

LABEL_F3827D:
	inc 4, xsp
	ret

NoteEdit_SendScrollCmds:
	bitda 0, 10050
	jr nz, LABEL_F382B0
	jr __jrt_nop_F38288
__jrt_nop_F38288:

LABEL_F38288:
	bitda 0, 10591
	jr nz, LABEL_F38294
	call NoteEditSy_SendScrollCmd8
	jr LABEL_F382A0

LABEL_F38294:
	call NoteEditSy_SendScrollCmd3
	call NoteEditSy_SendGateCmd
	call NoteEditSy_SendScrollCmd5

LABEL_F382A0:
	call NoteEditSy_SendScrollCmd0
	call NoteEditSy_SendScrollCmd1
	call NoteEditSy_SendScrollCmd2
	jp NoteEditSy_SendModeScrollCmd

LABEL_F382B0:
	bitda 0, 10591
	jr nz, LABEL_F382BC
	call NoteEditSy_SendVelocityCmd
	jr LABEL_F382C4

LABEL_F382BC:
	call NoteEditSy_SendScrollCmd3
	call NoteEditSy_SendGateCmd

LABEL_F382C4:
	call NoteEditSy_SendScrollCmd0
	call NoteEditSy_SendScrollCmd1
	call NoteEditSy_SendScrollCmd2
	jp NoteEditSy_SendModeScrollCmd

NoteEdit_UpdateScrollAndDisplay:
	ldda8 a, 10100
	mul a, 0x60
	cpdm16 10138, xwa
	ret nc
	jrl LABEL_F3888B
	sub a, c
	bitda 0, 10050
	jr z, LABEL_F382F5
	ldb c, 0xB
	sub c, a
	stda8 10188, c
	ret

LABEL_F382F5:
	ld c, a
	stda8 10188, a
	cpdi8 10136, 0
	ret nz
	inc 3, c
	stda8 10188, c
	ret

LABEL_F38309:
	.byte 0xef, 0x68, 0xd7, 0xfa, 0x04, 0xbf, 0x08, 0x30
	.byte 0xbf, 0x06, 0x31, 0x1e, 0xb7, 0xe7, 0x9f, 0x06
	.byte 0x20, 0x9f, 0x08, 0xa8, 0x9f, 0x08, 0x19, 0xce
	.byte 0x27, 0x1d, 0xa6, 0x21, 0xf4, 0xc7, 0xfa, 0x9f
	.byte 0xbf, 0x04, 0x30, 0xbf, 0x02, 0x31, 0x1e, 0xc0
	.byte 0xeb, 0xc7, 0xfa, 0x89, 0xd8, 0x12, 0x8f, 0x04
	.byte 0x23, 0xd9, 0x12, 0x1e, 0xa5, 0xff, 0x1d, 0x52
	.byte 0x00, 0xf4, 0x1d, 0x52, 0x00, 0xf4, 0x1d, 0xa6
	.byte 0x21, 0xf4, 0xc7, 0xfa, 0x9f, 0xc7, 0xfa, 0x89
	.byte 0xc7, 0xfb, 0x99, 0x1d, 0x52, 0x00, 0xf4, 0x1d
	.byte 0xa6, 0x21, 0xf4, 0xc7, 0xfa, 0x9f, 0xc7, 0xfb
	.byte 0x30, 0x07, 0xc7, 0xfa, 0x30, 0x07, 0xc7, 0xfa
	.byte 0x8b, 0xd9, 0x12, 0xd9, 0x08, 0x60, 0x00, 0xc7
	.byte 0xfb, 0x89, 0xd8, 0x12, 0xd8, 0x81, 0xf1, 0xd0
	.byte 0x27, 0x51, 0x1e, 0x06, 0x00, 0xd7, 0xfa, 0x05
	.byte 0xef, 0x60, 0x0e, 0xc1, 0x74, 0x27, 0x25, 0xcd
	.byte 0x08, 0x60, 0xda, 0x69, 0xd1, 0xce, 0x27, 0x20
	.byte 0xd8, 0x89, 0xd1, 0xd0, 0x27, 0x81, 0xda, 0xf1
	.byte 0xb0, 0xf3, 0xd8, 0xa2, 0xf1, 0xd0, 0x27, 0x52
	.byte 0x0e, 0xd1, 0xce, 0x27, 0x20, 0xd8, 0xef, 0x02
	.byte 0xd8, 0xc8, 0x16, 0x00, 0xf1, 0xba, 0x27, 0x50
	.byte 0xd1, 0xd0, 0x27, 0x20, 0xd8, 0xef, 0x02, 0xd1
	.byte 0xba, 0x27, 0x80, 0xf1, 0xbc, 0x27, 0x50, 0xd1
	.byte 0xbe, 0x27, 0x20, 0xd8, 0x63, 0xf1, 0xc0, 0x27
	.byte 0x50, 0x0e

ReadSeqData_StoreParams:
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stda8 10601, l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stda8 10602, l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stda8 10603, l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stda8 10604, l
	calr BmDrEdit_ClearAndScanToEnd
	ldda8 a, 10597
	inc 1, a
	extz wa
	calr BmDrEdit_CopyEventDataBetweenParts
	calr BmDrEdit_SeekForwardToEvent
	cpdi8 10362, 0
	jr nz, LABEL_F38441
	stdi8 10599, 144
	ldmm8 10600, 10116
	calr BmDrEdit_SaveSongPosition
	ldda8 a, 10597
	inc 1, a
	extz wa
	ld xbc, 0x2967
	lds de, 6
	calr BmDrEdit_ApplyVelocityChange
	calr BmDrEdit_CountMeasuresInit
	cpdi8 10362, 0
	ret z

LABEL_F38441:
	calr BmDrEdit_RefreshDisplayState
	ret

BmDrEdit_CalcBeatMeasure:
	ldda16 xwa, 10138
	extz xwa
	div wa, 0x60
	stdi8 9688, 0
	stda16 10098, xwa
	cps wa, 0
	jr z, BmDrEdit_ComputeMeasureAndBeat
	lds de, 1
	stdi8 9688, 1
	ldada xbc, 10148

LABEL_F38467:
	ld wa, de
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, LABEL_F38477
	stdi8 9688, 0

LABEL_F38477:
	inc 1, de
	ldda16 xwa, 10098
	dec 1, wa
	stda16 10098, xwa
	cps wa, 0
	jr z, BmDrEdit_ComputeMeasureAndBeat
	incdi8 1, 9688
	jr LABEL_F38467

BmDrEdit_ComputeMeasureAndBeat:
	ldda8 a, 9688
	extz wa
	stda16 10114, xwa
	ldda16 xwa, 10138
	extz xwa
	div wa, 0x60
	ldto_werp WA, 0xE2
	stda8 10116, a
	jr __jrt_nop_F384AA
__jrt_nop_F384AA:

LABEL_F384AA:
	ldda16 xbc, 10138
	extz xbc
	div bc, 0x60
	stdi8 9688, 0
	stda16 10098, xbc
	cps bc, 0
	jr z, LABEL_F384EB
	lds de, 1
	stdi8 9688, 0
	ldada xbc, 10148

LABEL_F384CC:
	ld wa, de
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, LABEL_F384DB
	incdi8 1, 9688

LABEL_F384DB:
	inc 1, de
	ldda16 xwa, 10098
	dec 1, wa
	stda16 10098, xwa
	cps wa, 0
	jr nz, LABEL_F384CC

LABEL_F384EB:
	ldda16 xbc, 10162
	ldda8 a, 9688
	extz wa
	add bc, wa
	stda16 10052, xbc
	ret

LABEL_F384FC:
	ldda16 xde, 10052
	subda16 xde, 10162
	inc 1, de
	lds hl, 0
	ldada xbc, 10148
	ldda8 a, 10146
	extz wa
	jr LABEL_F3851A

LABEL_F38514:
	inc 1, hl
	cp hl, wa
	jr ge, LABEL_F38521

LABEL_F3851A:
	cp_srib_rm E, 0x07, 0xE4, 0xEC
	jr nz, LABEL_F38514

LABEL_F38521:
	lds de, 0
	dec 1, hl
	cp_srib_im 0x07, 0xE4, 0xEC, 0x00
	jr z, LABEL_F38537
	jr BmDrEdit_StoreEventPositionAndReturn

LABEL_F3852F:
	inc 1, de
	sub hl, 0x1
	jr lt, BmDrEdit_StoreEventPositionAndReturn

LABEL_F38537:
	cp_srib_im 0x07, 0xE4, 0xEC, 0x00
	jr z, LABEL_F3852F

BmDrEdit_StoreEventPositionAndReturn:
	stda16 10114, xde
	ret

BmDrEdit_SyncSeekCheck:
	push xiz
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl
	cpdi8 10362, 0
	jr z, BmDrEdit_InitScanEventPositions
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jrl nz, LABEL_F38604
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl

BmDrEdit_InitScanEventPositions:
	ldi_berp 0xFB, 0
	stda16 10078, xiz
	stdi8 10080, 0
	cpdi16 10114, 0
	jr z, LABEL_F385A6
	stdi16 10098, 0

LABEL_F3857B:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, LABEL_F38589
	cp l, 0x84
	jr nz, LABEL_F385C0

LABEL_F38589:
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jr nz, LABEL_F38604
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl
	ldi_berp 0xFB, 1
	jr BmDrEdit_InitScanEventPositions

LABEL_F3859D:
	cpi_berp 0xFB, 1
	jr z, BmDrEdit_InitScanEventPositions

LABEL_F385A2:
	call SeqData_SkipToNextEvent

LABEL_F385A6:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, LABEL_F385B4
	cp l, 0x84
	jr nz, LABEL_F385F1

LABEL_F385B4:
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jr z, LABEL_F385DB
	jr LABEL_F38604

LABEL_F385C0:
	cp l, 0x81
	jr nz, LABEL_F385D5
	ldda16 xwa, 10098
	inc 1, wa
	stda16 10098, xwa
	cpda16 xwa, 10114
	jr nc, LABEL_F3859D

LABEL_F385D5:
	call SeqData_SkipToNextEvent
	jr LABEL_F3857B

LABEL_F385DB:
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl
	ldi_berp 0xFB, 1
	jrl BmDrEdit_InitScanEventPositions

LABEL_F385E6:
	cpi_berp 0xFB, 0
	jrl nz, BmDrEdit_InitScanEventPositions
	calr BmDrEdit_ClearAndScanToEnd
	jr LABEL_F385F6

LABEL_F385F1:
	cp l, 0x81
	jr nz, LABEL_F38606

LABEL_F385F6:
	ldda16 xwa, 10114
	adddm16 10078, xwa
	ldmm8 10080, 10116

LABEL_F38604:
	pop xiz
	ret

LABEL_F38606:
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cpda8 l, 10116
	jr nc, LABEL_F385E6
	jr LABEL_F385A2

BmDrEdit_SeekForwardToEvent:
	push xiz
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl
	cpdi8 10362, 0
	jrl z, BmDrEdit_StoreStreamPos
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jrl z, BmDrEdit_SyncStorePos
	jrl BmDrEdit_PopIzRet

LABEL_F38632:
	cp l, 0x81
	jr nz, BmDrEdit_AdvanceAndCheckBeat
	jrl BmDrEdit_CalcStorePos

LABEL_F3863A:
	stdi16 10098, 0
	ldi_berp 0xFB, 0

LABEL_F38643:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, LABEL_F38651
	cp l, 0x84
	jr nz, LABEL_F38692

LABEL_F38651:
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jr z, LABEL_F386C3
	jrl BmDrEdit_PopIzRet

LABEL_F3865E:
	cpi_berp 0xFB, 1
	jr z, BmDrEdit_StoreStreamPos

BmDrEdit_AdvanceAndCheckBeat:
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cpda8 l, 10116
	jrl ugt, LABEL_F38715
	call SeqData_SkipToNextEvent
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, LABEL_F38685
	cp l, 0x84
	jrl nz, LABEL_F3870D

LABEL_F38685:
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jr z, BmDrEdit_SyncStorePos
	jrl BmDrEdit_PopIzRet

LABEL_F38692:
	cp l, 0x81
	jr nz, BmDrEdit_SkipEventAndContinue
	ldda16 xwa, 10098
	inc 1, wa
	stda16 10098, xwa
	cpda16 xwa, 10114
	jr c, BmDrEdit_SkipEventAndContinue
	call SeqData_SkipToNextEvent
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, LABEL_F386B9
	cp l, 0x84
	jr nz, LABEL_F386CD

LABEL_F386B9:
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jr nz, BmDrEdit_PopIzRet

LABEL_F386C3:
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl
	ldi_berp 0xFB, 1
	jr BmDrEdit_StoreStreamPos

LABEL_F386CD:
	cp l, 0x81
	jr nz, LABEL_F3865E
	jr BmDrEdit_CalcStorePos

BmDrEdit_SkipEventAndContinue:
	call SeqData_SkipToNextEvent
	jrl LABEL_F38643

BmDrEdit_SyncStorePos:
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl

BmDrEdit_StoreStreamPos:
	stda16 10078, xiz
	stdi8 10080, 0
	cpdi16 10114, 0
	jrl nz, LABEL_F3863A
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, LABEL_F38701
	cp l, 0x84
	jrl nz, LABEL_F38632

LABEL_F38701:
	calr BmDrEdit_SeekToPartVoice
	cpdi8 10362, 0
	jr z, BmDrEdit_SyncStorePos
	jr BmDrEdit_PopIzRet

LABEL_F3870D:
	cp l, 0x81
	jrl nz, BmDrEdit_AdvanceAndCheckBeat
	jr BmDrEdit_CalcStorePos

LABEL_F38715:
	calr BmDrEdit_ClearAndScanToEnd

BmDrEdit_CalcStorePos:
	ldda16 xwa, 10114
	adddm16 10078, xwa
	ldmm8 10080, 10116

BmDrEdit_PopIzRet:
	pop xiz
	ret

LABEL_F38728:
	dec 4, xsp
	pushw iz
	bitda 0, 10591
	jrl z, LABEL_F387F0
	calr BmDrEdit_SaveEditState
	ldmm16 10252, 10090
	ldda8 a, 10092
	extz wa
	stda16 10254, xwa
	ldmm16 10256, 10094
	ldda8 a, 10096
	extz wa
	stda16 10258, xwa
	ldmm16 10260, 10078
	ldda8 a, 10080
	extz wa
	stda16 10262, xwa
	ldmm16 10264, 10415
	ldmm16 10266, 9830
	call SeqData_ReadNextByte
	and l, 0xF0
	cp l, 0x90
	jr nz, BmDrEdit_RestoreReturn
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	extz hl
	stda16 10262, xhl
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stda8 10268, l
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 2)
	calr BmDrEdit_SetupScrollRegion
	ldda8 a, 10268
	cp a, (xsp + 4)
	jr c, BmDrEdit_RestoreReturn
	cp a, (xsp + 2)
	jr ugt, BmDrEdit_RestoreReturn
	mrdb5 0x8F, 0x04, 0x19, 0x26, 0x28
	mrdb5 0x8F, 0x02, 0x19, 0x28, 0x28
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ldfr_berp L, 0xF8
	extz iz
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	extz hl
	and iz, 0x7F
	and hl, 0x7F
	ld wa, hl
	mul wa, 0x60
	ld hl, wa
	add hl, iz
	stda16 10272, xhl
	call NoteEditSy_SendWidgetCmdC

BmDrEdit_RestoreReturn:
	calr BmDrEdit_RestoreEditState

LABEL_F387F0:
	popw iz
	inc 4, xsp
	ret

LABEL_F387F4:
	ldda8 a, 36150
	cpda8 a, 36151
	ret z
	ldda8 a, 10417
	stda8 10300, a
	setda 0, 10417
	cpdi8 10298, 0
	jr nz, LABEL_F3881A
	ldmm_sd24w 0xEC, 0xFF, 0x00, 0x9E, 0xF1
	jr LABEL_F38820

LABEL_F3881A:
	ldmm16 61854, 10595

LABEL_F38820:
	call Audio_CheckSubsystemReady
	ldda16 xwa, 10052
	stda16 9500, xwa
	cpda16 xwa, 9502
	jr ule, LABEL_F38836
	stda16 9502, xwa

LABEL_F38836:
	ldmm16 9832, 9500
	cpdi16 9832, 1
	jr z, LABEL_F38848
	setda 3, 10407

LABEL_F38848:
	jp SeqPlay_AllocBuffersAndInit

LABEL_F3884C:
	ldda8 a, 36150
	cpda8 a, 36151
	ret z
	ldmm8 10417, 10300
	stdi16 61854, 0
	call Audio_CheckSubsystemReady
	call AccWrap_PlayModeDispatch
	ldda8 a, 36152
	cp a, 0x95
	jr z, LABEL_F38878
	cp a, 0x98
	ret nz

LABEL_F38878:
	ldmm16 3407, 10595
	call SeqVoice_FindSingleActive
	ret

