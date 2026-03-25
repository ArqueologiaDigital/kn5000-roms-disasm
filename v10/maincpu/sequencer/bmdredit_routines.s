; =============================================================================
; Bitmap Drum Editor
; =============================================================================
;
; Bitmap drum editor: stream positioning, sequence display,
; and voice allocation UI. Provides the graphical drum pattern
; editing interface.
; =============================================================================

BmDrEdit_AdvanceStreamPos:
	ldw_da xwa, 0x0210a6
	cp wa, 0xff
	jr nc, BmDrEdit_AdvanceStreamWrap
	inc 1, wa
	stw_da 0x0210a6, xwa
	ret

BmDrEdit_AdvanceStreamWrap:
	ldw_da xbc, 0x0210a4
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
	stw_da 0x0210a4, xwa
	stiw_da 0x0210a6, 0x0005
	ret

BmDrEdit_ScanForwardInit:
	pushw iz
	ldw_d16 xwa, 0x27fe
	stda16 0x27f6, xwa
	ldw_d16 xwa, 0x2800
	stda16 0x27f8, xwa
	ldw_d16 xwa, 0x2802
	stda16 0x27fa, xwa
	ldw_d16 xwa, 0x2804
	stda16 0x27fc, xwa
	ldmmw_dd24 0xa0, 0x10, 0x02, 0xfe, 0x27
	ldmmw_dd24 0xa2, 0x10, 0x02, 0x00, 0x28
	ldmmw_dd24 0xa4, 0x10, 0x02, 0x02, 0x28
	ldmmw_dd24 0xa6, 0x10, 0x02, 0x04, 0x28
	ldmmb_dd24 0xa8, 0x10, 0x02, 0x22, 0x28
	ldmmb_dd24 0xaa, 0x10, 0x02, 0x24, 0x28
	lds iz, 0
	ldb_d8 a, 0x2774
	extz wa
	cps wa, 0
	jrl ule, BmDrEdit_ScanForward_Done

BmDrEdit_ScanForwardLoop:
	ldw_da xbc, 0x0210a6
	extz xbc
	ldw_da xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	cp a, 0x82
	jrl z, BmDrEdit_ScanForward_Done
	cp a, 0x84
	jrl z, BmDrEdit_ScanForward_Done
	cp a, 0x81
	jr nz, BmDrEdit_ScanForward_CheckNote
	inc 1, iz
	incdi16_24 1, 0x0210a0
	jr BmDrEdit_ScanForward_NextByte

BmDrEdit_ScanForward_CheckNote:
	and a, 0xf0
	cp a, 0x90
	jr nz, BmDrEdit_ScanForward_NextByte
	calr BmDrEdit_AdvanceStreamPos
	ldw_da xbc, 0x0210a6
	extz xbc
	ldw_da xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	extz wa
	stw_da 0x0210a2, xwa
	calr BmDrEdit_AdvanceStreamPos
	ldw_da xbc, 0x0210a6
	extz xbc
	ldw_da xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	stb_d8 0x2806, a
	cpda8_24 a, 0x0210a8
	jr c, BmDrEdit_ScanForward_NextByte
	cpda8_24 a, 0x0210aa
	call_24 ule, BmDrEdit_RenderNoteBlock

BmDrEdit_ScanForward_NextByte:
	calr BmDrEdit_AdvanceStreamPos
	ldw_da xbc, 0x0210a6
	extz xbc
	ldw_da xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	bit 7, a
	jr z, BmDrEdit_ScanForward_NextByte
	ldb_d8 a, 0x2774
	extz wa
	cp iz, wa
	jrl c, BmDrEdit_ScanForwardLoop

BmDrEdit_ScanForward_Done:
	popw iz
	ret

BmDrEdit_ScanBackwardInit:
	pushw iz
	ldmm16 0x27f6, 0x27fe
	ldmm16 0x27f8, 0x2800
	ldmm16 0x27fa, 0x2802
	ldmm16 0x27fc, 0x2804
	ldmmw_dd24 0xa0, 0x10, 0x02, 0xfe, 0x27
	ldmmw_dd24 0xa2, 0x10, 0x02, 0x00, 0x28
	ldmmw_dd24 0xa4, 0x10, 0x02, 0x02, 0x28
	ldmmw_dd24 0xa6, 0x10, 0x02, 0x04, 0x28
	ldmmb_dd24 0xa8, 0x10, 0x02, 0x22, 0x28
	ldmmb_dd24 0xaa, 0x10, 0x02, 0x24, 0x28
	lds iz, 0
	ldb_d8 a, 0x2774
	extz wa
	cps wa, 0
	jrl ule, BmDrEdit_ScanBackward_Done

BmDrEdit_ScanBackwardLoop:
	ldw_da xbc, 0x0210a6
	extz xbc
	ldw_da xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	cp a, 0x82
	jrl z, BmDrEdit_ScanBackward_Done
	cp a, 0x84
	jrl z, BmDrEdit_ScanBackward_Done
	cp a, 0x81
	jr nz, BmDrEdit_ScanBackward_CheckNote
	inc 1, iz
	incdi16 1, 0x27fe
	jr BmDrEdit_ScanBackward_NextByte

BmDrEdit_ScanBackward_CheckNote:
	and a, 0xf0
	cp a, 0x90
	jr nz, BmDrEdit_ScanBackward_NextByte
	ldw_d16 xwa, 0x2802
	cpda16 xwa, 0x2766
	jr nz, BmDrEdit_ScanBackward_ReadNoteParams
	ldw_d16 xwa, 0x2804
	cpda16 xwa, 0x2768
	jr z, BmDrEdit_ScanBackward_NextByte

BmDrEdit_ScanBackward_ReadNoteParams:
	calr BmDrEdit_AdvanceStreamPos
	ldw_da xbc, 0x0210a6
	extz xbc
	ldw_da xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	extz wa
	stda16 0x2800, xwa
	calr BmDrEdit_AdvanceStreamPos
	ldw_da xbc, 0x0210a6
	extz xbc
	ldw_da xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	stb_d8 0x2806, a
	cpda8_24 a, 0x0210a8
	jr c, BmDrEdit_ScanBackward_NextByte
	cpda8_24 a, 0x0210aa
	call_24 ule, BmDrEdit_RenderNoteBlock

BmDrEdit_ScanBackward_NextByte:
	calr BmDrEdit_AdvanceStreamPos
	ldw_da xbc, 0x0210a6
	extz xbc
	ldw_da xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	bit 7, a
	jr z, BmDrEdit_ScanBackward_NextByte
	ldb_d8 a, 0x2774
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
	cp xhl, 0x1a00095
	jr nz, BmDrEdit_RenderNoteBlock_Vertical
	calr BmDrEdit_RenderHorizontal
	jr BmDrEdit_RenderNoteBlock_StoreCoords

BmDrEdit_RenderNoteBlock_Vertical:
	calr BmDrEdit_RenderVertical

BmDrEdit_RenderNoteBlock_StoreCoords:
	lda xwa, (xsp)
	ldmw2 (xwa), 0x27ba
	ldmw2 (xwa + 4), 0x27bc
	ldmw2 (xwa + 2), 0x27be
	ldmw2 (xwa + 6), 0x27c0
	lds bc, 0
	call DrawFrame
	inc 8, xsp
	ret

BmDrEdit_CalcNotePosition:
	pushw_erp 0xfa
	ldw_da xbc, 0x0210a0
	mul bc, 0x60
	addda16_24 xbc, 0x0210a2
	ldw_d16 xwa, 0x27f6
	mul wa, 0x60
	addda16 xwa, 0x27f8
	sub bc, wa
	stda16 0x2808, xbc
	ldb_da a, 0x0210a8
	subdm8 0x2806, a
	call GetTitleNow
	cp xhl, 0x1a00095
	jr nz, BmDrEdit_CalcNotePos_VerticalMode
	cpdi8 0x2798, 0
	jr nz, BmDrEdit_CalcNotePos_ReadFields
	incdi8 3, 0x2806
	jr BmDrEdit_CalcNotePos_ReadFields

BmDrEdit_CalcNotePos_VerticalMode:
	ldb a, 0xb
	subda8 a, 0x2806
	stb_d8 0x2806, a

BmDrEdit_CalcNotePos_ReadFields:
	calr BmDrEdit_AdvanceStreamPos
	calr BmDrEdit_AdvanceStreamPos
	ldw_da xbc, 0x0210a6
	extz xbc
	ldw_da xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	ldb_erp A, 0xfb
	calr BmDrEdit_AdvanceStreamPos
	ldw_da xbc, 0x0210a6
	extz xbc
	ldw_da xwa, 0x0210a4
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld c, (xbc)
	res_erpb 0xfb, 0x07
	res 7, c
	extz bc
	mul bc, 0x60
	stb_erp A, 0xfb
	extz wa
	add bc, wa
	stda16 0x280a, xbc
	ldb_d8 l, 0x2774
	mul l, 0x60
	dec 1, hl
	ldw_d16 xwa, 0x2808
	ld de, wa
	add de, bc
	cp de, hl
	jr ule, BmDrEdit_CalcNotePos_ClampSize
	sub hl, wa
	stda16 0x280a, xhl

BmDrEdit_CalcNotePos_ClampSize:
	popw_erp 0xfa
	ret

BmDrEdit_RenderHorizontal:
	ldw_d16 xwa, 0x2808
	srl wa, 2
	add wa, 0x16
	stda16 0x27ba, xwa
	ldw_d16 xwa, 0x280a
	srl wa, 2
	addda16 xwa, 0x27ba
	stda16 0x27bc, xwa
	ldb_d8 a, 0x2806
	extz wa
	add wa, wa
	lda_24 xbc, NakaInst_NO_OPERATION_0x19A
	ldmm_sriw 0x07, 0xe4, 0xe0, 0xbe, 0x27
	ldw_d16 xwa, 0x27be
	inc 3, wa
	stda16 0x27c0, xwa
	ret

BmDrEdit_RenderVertical:
	ldw_d16 xwa, 0x2808
	srl wa, 2
	add wa, 0x5b
	stda16 0x27ba, xwa
	ldw_d16 xwa, 0x280a
	srl wa, 2
	addda16 xwa, 0x27ba
	stda16 0x27bc, xwa
	ldb_d8 a, 0x2806
	extz wa
	add wa, wa
	lda_24 xbc, NakaInst_NO_OPERATION_0x1D4
	ldmm_sriw 0x07, 0xe4, 0xe0, 0xbe, 0x27
	ldw_d16 xwa, 0x27be
	inc 3, wa
	stda16 0x27c0, xwa
	ret

BmDrEdit_RenderSecondaryBlock:
	dec 8, xsp
	ldmmb_dd24 0xb0, 0x10, 0x02, 0x1c, 0x28
	ldmmw_dd24 0xb2, 0x10, 0x02, 0x20, 0x28
	calr BmDrEdit_CalcSecondaryPosition
	call GetTitleNow
	cp xhl, 0x1a00095
	jr nz, BmDrEdit_RenderSecondary_Vertical
	calr BmDrEdit_RenderSecondaryHoriz
	jr BmDrEdit_RenderSecondary_StoreCoords

BmDrEdit_RenderSecondary_Vertical:
	calr BmDrEdit_RenderSecondaryVert

BmDrEdit_RenderSecondary_StoreCoords:
	lda xwa, (xsp)
	ldmw2 (xwa), 0x27c2
	ldmw2 (xwa + 4), 0x27c4
	ldmw2 (xwa + 2), 0x27c6
	ldmw2 (xwa + 6), 0x27c8
	lds bc, 0
	lds de, 0
	call DrawDesignBox
	inc 8, xsp
	ret

BmDrEdit_RenderSecondaryHoriz:
	ldw_d16 xwa, 0x281e
	srl wa, 2
	add wa, 0x16
	stda16 0x27c2, xwa
	ldw_da xwa, 0x0210b2
	srl wa, 2
	addda16 xwa, 0x27c2
	stda16 0x27c4, xwa
	ldb_da a, 0x0210b0
	extz wa
	add wa, wa
	lda_24 xbc, NakaInst_NO_OPERATION_0x19A
	ldmm_sriw 0x07, 0xe4, 0xe0, 0xc6, 0x27
	ldw_d16 xwa, 0x27c6
	inc 3, wa
	stda16 0x27c8, xwa
	ret

BmDrEdit_RenderSecondaryVert:
	ldw_d16 xwa, 0x281e
	srl wa, 2
	add wa, 0x5b
	stda16 0x27c2, xwa
	ldw_da xwa, 0x0210b2
	srl wa, 2
	addda16 xwa, 0x27c2
	stda16 0x27c4, xwa
	ldb_da a, 0x0210b0
	extz wa
	add wa, wa
	lda_24 xbc, NakaInst_NO_OPERATION_0x1D4
	ldw_sri WA, 0x07, 0xe4, 0xe0
	stda16 0x27c6, xwa
	inc 3, wa
	stda16 0x27c8, xwa
	decdi16 2, 0x27c6
	incdi16 2, 0x27c8
	ret

BmDrEdit_CalcSecondaryPosition:
	ldw_d16 xbc, 0x2814
	mul bc, 0x60
	addda16 xbc, 0x2816
	ldw_d16 xwa, 0x280c
	mul wa, 0x60
	addda16 xwa, 0x280e
	sub bc, wa
	stda16 0x281e, xbc
	ldb_d8 a, 0x2826
	subdm8_24 0x0210b0, a
	call GetTitleNow
	cp xhl, 0x1a00095
	jr nz, BmDrEdit_CalcSecondaryPos_Vert
	cpdi8 0x2798, 0
	jr nz, BmDrEdit_CalcSecondaryPos_ClampSize
	incdi8_24 3, 0x0210b0
	jr BmDrEdit_CalcSecondaryPos_ClampSize

BmDrEdit_CalcSecondaryPos_Vert:
	ldb a, 0xb
	subda8_24 a, 0x0210b0
	stb_da 0x0210b0, a

BmDrEdit_CalcSecondaryPos_ClampSize:
	ldb_d8 e, 0x2774
	mul e, 0x60
	dec 1, de
	ldw_d16 xwa, 0x281e
	ld bc, wa
	addda16_24 xbc, 0x0210b2
	cp bc, de
	ret ule
	sub de, wa
	stw_da 0x0210b2, xde
	ret

BmDrEdit_InitDisplayParams:
	stdi16 0x2794, 48
	stdi16 0x2796, 48
	stdi16 0x2790, 38
	stdi8 0x2798, 5
	stdi16 0x279e, 40
	stdi16 0x27a0, 5
	stdi8 0x278a, 100
	ret

BmDrEdit_TempoAnimTimer:
	ldb_d8 a, 0xe372
	cp a, 0x1e
	jr ule, BmDrEdit_TempoAnimTimer_Reset
	inc 1, a
	stb_d8 0xe372, a
	ret

BmDrEdit_TempoAnimTimer_Reset:
	stdi8 0xe372, 0
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
	ldb_d8 a, 0x8d38
	cp a, 0x95
	jr z, BmDrEdit_CheckTempoData_ReadyToProcess
	cp a, 0x98
	ret nz

BmDrEdit_CheckTempoData_ReadyToProcess:
	bitda 7, 0x295c
	ret nz
	cpdi16 0xf231, 0
	jr z, BmDrEdit_ClearNoteAndRefresh
	call TempoRingBuf_CheckEmpty
	cps hl, 0
	ret z

BmDrEdit_ProcessTempoEvent:
	call TempoRingBuf_ReadByte
	bit 7, l
	jr z, BmDrEdit_TempoEventLoop
	and l, 0xf0
	cp l, 0x90
	jr nz, BmDrEdit_TempoEventLoop
	call TempoRingBuf_ReadByte
	call TempoRingBuf_ReadByte
	stb_d8 0x2960, l
	call TempoRingBuf_ReadByte
	stb_d8 0x2961, l
	call TempoRingBuf_ReadByte
	cpdi8 0x2961, 0
	jr z, BmDrEdit_ProcessTempoEvent_NoteOff
	calr BmDrEdit_AllocateNoteSlot
	jr BmDrEdit_TempoEventLoop

BmDrEdit_ProcessTempoEvent_NoteOff:
	calr BmDrEdit_FindNoteInSlots
	cp hl, 0xff
	jr z, BmDrEdit_TempoEventLoop
	calr BmDrEdit_CheckSlotsAvailable
	cps hl, 0
	jr nz, BmDrEdit_TempoEventLoop
	resda 0, 0x295f
	ldmm8 0x2962, 0x2960
	calr BmDrEdit_AdjustScrollToView
	calr BmDrEdit_InsertNotesFromSlots
	calr BmDrEdit_CountMeasuresInit
	cpdi8 0x287a, 0
	jr z, BmDrEdit_ClearSlotAndRedraw

BmDrEdit_ClearNoteAndRefresh:
	resda 0, 0x295f
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
	ldb_d8 a, 0x295c
	bit 7, a
	ret z
	cp a, 0x80
	ret z
	dec 1, a
	stb_d8 0x295c, a
	ret

BmDrEdit_DelayAExpired:
	cpdi8 0x295c, 128
	ret nz
	stdi8 0x295c, 0
	ldb_d8 a, 0x295d
	cps a, 5
	jrl z, BmDrEdit_DelayAction_WalkAndUpdateAlt
	cps a, 4
	jrl z, BmDrEdit_DelayAction_UpdateScrollAlt
	cps a, 3
	jrl z, BmDrEdit_DelayAction_CheckCountError
	cps a, 2
	jrl z, BmDrEdit_DelayAction_WalkAndUpdate
	cps a, 1
	jrl nz, BmDrEdit_HandleDelayExpired_Rescan
	jrl BmDrEdit_DelayAction_SetupAndWalk

BmDrEdit_DecrementDelayB:
	ldb_d8 a, 0x295e
	bit 7, a
	ret z
	cp a, 0x80
	ret z
	dec 1, a
	stb_d8 0x295e, a
	ret

BmDrEdit_DelayBExpired:
	cpdi8 0x295e, 128
	ret nz
	stdi8 0x295e, 0
	jrl BmDrEdit_DelayAction_PlayClick

BmDrEdit_DelayReturn:
	ret

BmDrEdit_AllocateNoteSlot:
	ldw ix, 0x8
	bitda 0, 0x2742
	jr z, BmDrEdit_AllocateNote_Search
	lds ix, 1

BmDrEdit_AllocateNote_Search:
	lds iy, 0
	cps ix, 0
	ret ule
	lda_d16 xde, 0x2746

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
	resda 0, 0x8d88
	ldw wa, 0xf
	call SoundCtrl_SaveAndSendCmd_EE
	setda 4, 0x28ad
	ret

BmDrEdit_CheckNoteType:
	ld c, a
	extz bc
	lds wa, 0
	call Part_ReadVoiceByte
	cp l, 0xd
	jr z, BmDrEdit_CheckNoteType_IsDrum
	cp l, 0xf
	jr z, BmDrEdit_CheckNoteType_IsDrum
	cp l, 0x10
	jr nz, BmDrEdit_CheckNoteType_NotDrum

BmDrEdit_CheckNoteType_IsDrum:
	ldw hl, 0xffff
	ret

BmDrEdit_CheckNoteType_NotDrum:
	lds hl, 0
	ret

BmDrEdit_SaveSequencerState:
	bitda 0, 0x2742
	jr z, BmDrEdit_SaveSeqState_SetMode95
	ldw wa, 0x98
	jr BmDrEdit_SaveSeqState_Apply

BmDrEdit_SaveSeqState_SetMode95:
	ldw wa, 0x95

BmDrEdit_SaveSeqState_Apply:
	call UI_PostModeChangeEvent
	ldmm16 0x2963, 3407
	call SeqVoice_FindSingleActive
	ldmm8 7512, 0x8d3a
	ret

BmDrEdit_CheckScrollBusy:
	bitda 7, 0x295c
	jr z, BmDrEdit_ScrollRight
	cpdi8 0x295d, 0
	jr z, BmDrEdit_ScrollRight
	ldw hl, 0xffff
	ret

BmDrEdit_ScrollRight:
	ldw_d16 xwa, 0x2744
	cp wa, 0x3e7
	jr nc, BmDrEdit_ScrollRight_Done
	inc 1, wa
	stda16 0x2744, xwa
	calr BmDrEdit_ScrollReset

BmDrEdit_ScrollRight_Done:
	lds hl, 0
	ret

BmDrEdit_CheckScrollBusyAlt:
	bitda 7, 0x295c
	jr z, BmDrEdit_ScrollLeft
	cpdi8 0x295d, 0
	jr z, BmDrEdit_ScrollLeft
	ldw hl, 0xffff
	ret

BmDrEdit_ScrollLeft:
	ldw_d16 xwa, 0x2744
	cps wa, 1
	jr ule, BmDrEdit_ScrollLeft_Done
	dec 1, wa
	stda16 0x2744, xwa
	calr BmDrEdit_ScrollReset

BmDrEdit_ScrollLeft_Done:
	lds hl, 0
	ret

BmDrEdit_ScrollReset:
	call NoteEditSy_SendScrollCmd0
	stdi16 0x279a, 0
	stdi16 0x2782, 0
	stdi8 0x2784, 0
	stdi8 0x295c, 130
	stdi8 0x295d, 0
	ret

BmDrEdit_PitchScrollUp_Check:
	bitda 7, 0x295c
	jr z, BmDrEdit_PitchScrollUp
	cpdi8 0x295d, 1
	ret nz

BmDrEdit_PitchScrollUp:
	ldb_d8 a, 0x2784
	cp a, 0x5f
	jrl nc, BmDrEdit_PitchScrollOverflow
	inc 1, a
	stb_d8 0x2784, a
	call NoteEditSy_SendScrollCmd2
	calr NoteEditSy_CallFarRoutine
	calr BmDrEdit_BuildVoice_NullReturn
	jrl BmDrEdit_SetFeedbackTimer

BmDrEdit_PitchScrollDown_Check:
	bitda 7, 0x295c
	jr z, BmDrEdit_PitchScrollDown
	cpdi8 0x295d, 1
	ret nz

BmDrEdit_PitchScrollDown:
	ldb_d8 a, 0x2784
	cps a, 0
	jrl z, BmDrEdit_PitchWrapToEnd
	dec 1, a
	stb_d8 0x2784, a
	call NoteEditSy_SendScrollCmd2
	calr NoteEditSy_CallFarRoutine
	calr BmDrEdit_BuildVoice_NullReturn
	jrl BmDrEdit_SetFeedbackTimer

BmDrEdit_VelocityUp_Check:
	bitda 7, 0x295c
	jr z, BmDrEdit_VelocityUp_Dispatch
	cpdi8 0x295d, 2
	ret nz

BmDrEdit_VelocityUp_Dispatch:
	bitda 0, 0x295f
	ret z
	bitda 0, 0x2742
	jr nz, BmDrEdit_DecrementVelocity
	jr BmDrEdit_IncrementVelocity

BmDrEdit_VelocityDown_Check:
	bitda 7, 0x295c
	jr z, BmDrEdit_VelocityDown_Dispatch
	cpdi8 0x295d, 2
	ret nz

BmDrEdit_VelocityDown_Dispatch:
	bitda 0, 0x295f
	ret z
	bitda 0, 0x2742
	jr nz, BmDrEdit_IncrementVelocity
	jr BmDrEdit_DecrementVelocity

BmDrEdit_IncrementVelocity:
	ldb_d8 a, 0x2786
	cp a, 0x7f
	ret nc
	inc 1, a
	stb_d8 0x2786, a
	bitda 0, 0x2742
	call_24 nz, BmDrEdit_DrumVoiceUp
	calr BmDrEdit_UpdateVelocityDisplay
	call NoteEditSy_SendScrollCmd3
	calr BmDrEdit_NullReturn
	stdi8 0x295c, 131
	stdi8 0x295d, 2
	ret

BmDrEdit_DecrementVelocity:
	ldb_d8 a, 0x2786
	cps a, 1
	ret z
	dec 1, a
	stb_d8 0x2786, a
	bitda 0, 0x2742
	call_24 nz, BmDrEdit_DrumVoiceDown
	calr BmDrEdit_UpdateVelocityDisplay
	call NoteEditSy_SendScrollCmd3
	calr BmDrEdit_NullReturn
	stdi8 0x295c, 131
	stdi8 0x295d, 2
	ret

BmDrEdit_GateOrVelocityUp:
	bitda 7, 0x295c
	ret nz
	bitda 0, 0x295f
	jr nz, BmDrEdit_IncrementGateTime
	bitda 0, 0x2742
	ret z
	calr BmDrEdit_IncrementVelocityValue
	ret

BmDrEdit_GateOrVelocityDown:
	bitda 7, 0x295c
	ret nz
	bitda 0, 0x295f
	jr nz, BmDrEdit_DecrementGateTime
	bitda 0, 0x2742
	ret z
	calr BmDrEdit_DecrementVelocityValue
	ret

BmDrEdit_IncrementGateTime:
	ldb_d8 a, 0x2788
	cp a, 0x7f
	ret nc
	inc 1, a
	stb_d8 0x2788, a
	call NoteEditSy_SendGateCmd
	jrl BmDrEdit_UpdateGateDisplay

BmDrEdit_DecrementGateTime:
	ldb_d8 a, 0x2788
	cps a, 1
	ret z
	dec 1, a
	stb_d8 0x2788, a
	call NoteEditSy_SendGateCmd
	jrl BmDrEdit_UpdateGateDisplay

BmDrEdit_IncrementVelocityValue:
	ldb_d8 a, 0x278a
	cp a, 0x7f
	ret nc
	inc 1, a
	stb_d8 0x278a, a
	jp NoteEditSy_SendVelocityCmd

BmDrEdit_DecrementVelocityValue:
	ldb_d8 a, 0x278a
	cps a, 1
	ret z
	dec 1, a
	stb_d8 0x278a, a
	jp NoteEditSy_SendVelocityCmd

BmDrEdit_DurationUp_Check:
	bitda 7, 0x295c
	jr z, BmDrEdit_DurationUp_Dispatch
	cpdi8 0x295d, 3
	ret nz

BmDrEdit_DurationUp_Dispatch:
	jr BmDrEdit_IncrementDuration

BmDrEdit_DurationDown_Check:
	bitda 7, 0x295c
	jr z, BmDrEdit_DurationDown_Dispatch
	cpdi8 0x295d, 3
	ret nz

BmDrEdit_DurationDown_Dispatch:
	jr BmDrEdit_DecrementDuration

BmDrEdit_IncrementDuration:
	bitda 0, 0x295f
	jr z, BmDrEdit_IncrementDuration_Global
	ldw_d16 xwa, 0x278c
	cp wa, 0x2fff
	ret nc
	inc 1, wa
	stda16 0x278c, xwa
	calr BmDrEdit_CalcDurationPosition
	call NoteEditSy_SendScrollCmd5
	calr BmDrEdit_NullReturn
	stdi8 0x295c, 131
	stdi8 0x295d, 3
	ret

BmDrEdit_IncrementDuration_Global:
	ldw_d16 xwa, 0x278e
	cp wa, 0x2fff
	ret nc
	inc 1, wa
	stda16 0x278e, xwa
	jp NoteEditSy_SendScrollCmd8

BmDrEdit_DecrementDuration:
	bitda 0, 0x295f
	jr z, BmDrEdit_DecrementDuration_Global
	ldw_d16 xwa, 0x278c
	cps wa, 0
	jr nz, BmDrEdit_DecrementDuration_Clamp
	stdi16 0x278c, 1
	jr BmDrEdit_DecrementDuration_Update

BmDrEdit_DecrementDuration_Clamp:
	cps wa, 1
	ret ule
	dec 1, wa
	stda16 0x278c, xwa

BmDrEdit_DecrementDuration_Update:
	calr BmDrEdit_CalcDurationPosition
	call NoteEditSy_SendScrollCmd5
	calr BmDrEdit_NullReturn
	stdi8 0x295c, 131
	stdi8 0x295d, 3
	ret

BmDrEdit_DecrementDuration_Global:
	ldw_d16 xwa, 0x278e
	cps wa, 0
	jr nz, BmDrEdit_DecrementDuration_GlobalClamp
	stdi16 0x278e, 1
	jr BmDrEdit_DecrementDuration_Send

BmDrEdit_DecrementDuration_GlobalClamp:
	cps wa, 1
	ret z
	dec 1, wa
	stda16 0x278e, xwa

BmDrEdit_DecrementDuration_Send:
	jp NoteEditSy_SendScrollCmd8

BmDrEdit_ModeScrollUp:
	bitda 7, 0x295c
	ret nz
	ldw_d16 xwa, 0x2792
	cp wa, 0x60
	ret nc
	inc 1, wa
	stda16 0x2792, xwa
	jp NoteEditSy_SendModeScrollCmd

BmDrEdit_ModeScrollDown:
	bitda 7, 0x295c
	ret nz
	ldw_d16 xwa, 0x2792
	cps wa, 0
	jr nz, BmDrEdit_ModeScrollDown_Clamp
	stdi16 0x2792, 48
	jr BmDrEdit_ModeScrollDown_Send

BmDrEdit_ModeScrollDown_Clamp:
	cps wa, 1
	ret ule
	dec 1, wa
	stda16 0x2792, xwa

BmDrEdit_ModeScrollDown_Send:
	jp NoteEditSy_SendModeScrollCmd

BmDrEdit_SetFeedbackTimer:
	stdi8 0x295c, 133
	stdi8 0x295d, 1
	ret

BmDrEdit_SaveEditState:
	ldmm16 0x2762, 0x275e
	ldmm8 0x2764, 0x2760
	ldmm16 0x2766, 0x28af
	ldmm16 0x2768, 9830
	ret

BmDrEdit_RestoreEditState:
	ldmm16 0x275e, 0x2762
	ldmm8 0x2760, 0x2764
	ldmm16 0x28af, 0x2766
	ldmm16 9830, 0x2768
	ret

BmDrEdit_ClearAndScanToEnd:
	stdi8 0x287a, 0

BmDrEdit_ScanToEnd_Loop:
	ldw_d16 xwa, 9830
	cps wa, 5
	jr ule, BmDrEdit_ScanToEnd_CheckNextSong
	dec 1, wa
	stda16 9830, xwa
	jr BmDrEdit_ScanToEnd_CheckEndMark

BmDrEdit_ScanToEnd_CheckNextSong:
	ldw_d16 xwa, 0x28af
	call PartCtrl_ReadWord_Off1
	cps hl, 0
	jr nz, BmDrEdit_ScanToEnd_AdvanceSong
	stdi8 0x287a, 255
	ret

BmDrEdit_ScanToEnd_AdvanceSong:
	stda16 0x28af, xhl
	stdi16 9830, 255

BmDrEdit_ScanToEnd_CheckEndMark:
	call SeqData_ReadNextByte
	bit 7, l
	jr z, BmDrEdit_ScanToEnd_Loop
	ret

BmDrEdit_LoadAlternateState:
	ldmm16 0x275e, 0x276a
	ldmm8 0x2760, 0x276c
	ldmm16 0x28af, 0x276e
	ldb_d8 a, 0x2770
	extz wa
	stda16 9830, xwa
	ret

BmDrEdit_LoadAlternateAndCountNotes:
	calr BmDrEdit_LoadAlternateState
	stdi16 0x2772, 0

BmDrEdit_CountNotesLoop:
	call SeqData_ReadNextByte
	cp l, 0x82
	ret z
	cp l, 0x84
	ret z
	cp l, 0x81
	jr nz, BmDrEdit_CountNotesLoop_Retry
	ldw_d16 xbc, 0x2772
	inc 1, bc
	stda16 0x2772, xbc
	ldb_d8 a, 0x2774
	extz wa
	cp bc, wa
	ret ugt

BmDrEdit_CountNotesLoop_Retry:
	call SeqData_SkipToNextEvent
	jr BmDrEdit_CountNotesLoop

BmDrEdit_CheckChannelActive:
	ldb e, 0x0
	lda_d16 xbc, 0xf1a0

BmDrEdit_CheckChannelActive_Loop:
	ld a, e
	extz wa
	extz xwa
	add xwa, xbc
	cp (xwa), 0x10
	jr nz, BmDrEdit_CheckChannelActive_Next
	lds bc, 1
	ld a, e
	and a, 0xf
	jr z, BmDrEdit_CheckChannelActive_TestBit
	slaa bc

BmDrEdit_CheckChannelActive_TestBit:
	andda16_24 xbc, 0xffec
	jr z, BmDrEdit_CheckChannelActive_None
	stdi8 0x2776, 1
	ret

BmDrEdit_CheckChannelActive_Next:
	inc 1, e
	cp e, 0x10
	jr c, BmDrEdit_CheckChannelActive_Loop

BmDrEdit_CheckChannelActive_None:
	stdi8 0x2776, 0
	ret

BmDrEdit_SelectActiveChannel:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0
	lda_d16 xbc, 0xf1a0

BmDrEdit_SelectChannel_Loop:
	stb_erp A, 0xfb
	extz wa
	extz xwa
	add xwa, xbc
	cp (xwa), 0x10
	jr nz, BmDrEdit_SelectChannel_NextCh
	lds bc, 1
	stb_erp A, 0xfb
	and a, 0xf
	jr z, BmDrEdit_SelectChannel_TestBit
	slaa bc

BmDrEdit_SelectChannel_TestBit:
	andda16_24 xbc, 0xffec
	jr z, BmDrEdit_SelectChannel_NotFound
	bitda 0, 0x2776
	jr z, BmDrEdit_SelectChannel_NotFound
	stb_erp C, 0xfb
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, BmDrEdit_SelectChannel_NotFound
	stb_erp A, 0xfb
	inc 1, a
	stb_d8 3414, a
	setda 0, 3412
	setda 2, 0x287b
	stb_erp L, 0xfb
	inc 1, l
	jr BmDrEdit_SelectChannel_Done

BmDrEdit_SelectChannel_NextCh:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, BmDrEdit_SelectChannel_Loop

BmDrEdit_SelectChannel_NotFound:
	resda 0, 3412
	resda 2, 0x287b
	ldb l, 0x0

BmDrEdit_SelectChannel_Done:
	popw_erp 0xfa
	ret

BmDrEdit_AlignDisplayGrid:
	lds de, 0
	ldw_d16 xwa, 0x279a
	cps wa, 0
	jr c, BmDrEdit_AlignGrid_Store
	ldw_d16 xbc, 0x2792

BmDrEdit_AlignGrid_AccumLoop:
	add de, bc
	cp de, wa
	jr ule, BmDrEdit_AlignGrid_AccumLoop

BmDrEdit_AlignGrid_Store:
	stda16 0x279a, xde
	ret

BmDrEdit_CompareVelocity:
	push xiz
	bitda 0, 0x2742
	jr z, BmDrEdit_CompareVelocity_Equal
	ldw_d16 xiz, 0x28af
	ldw_d16 xwa, 9830
	ldw_erp WA, 0xfa
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stda16 0x28af, xiz
	stw_erp WA, 0xfa
	stda16 9830, xwa
	cpda8 l, 0x2786
	jr z, BmDrEdit_CompareVelocity_Equal
	ldb l, 0xff
	jr BmDrEdit_CompareVelocity_Return

BmDrEdit_CompareVelocity_Equal:
	ldb l, 0x0

BmDrEdit_CompareVelocity_Return:
	pop xiz
	ret

BmDrEdit_SaveSongPosition:
	ldb_d8 a, 0x2965
	inc 1, a
	extz wa
	ldw_d16 xhl, 0x28af
	ldw_d16 xde, 9830
	dec 1, a
	extz wa
	sla wa, 2
	lda_d16 xbc, 9184
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de
	ret

BmDrEdit_ReadEventAtPosition:
	push xiz
	ldw_d16 xiz, 0x28af
	ldw_d16 xwa, 9830
	ldw_erp WA, 0xfa
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stb_d8 0x2760, l
	stda16 0x28af, xiz
	stw_erp WA, 0xfa
	stda16 9830, xwa
	pop xiz
	ret

BmDrEdit_CheckNoteAtPosition:
	call SeqData_ReadNextByte
	and l, 0xf0
	cp l, 0x90
	ret nz
	calr BmDrEdit_CompareVelocity
	cps l, 0
	ret nz
	jr BmDrEdit_ReadEventAtPosition

BmDrEdit_WalkTrackForward:
	ldb_d8 a, 0x295f
	res 1, a
	res 4, a
	stb_d8 0x295f, a
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_WalkTrack_EndOfTrack
	cp l, 0x84
	jr z, BmDrEdit_WalkTrack_EndOfTrack
	cp l, 0x81
	jr nz, BmDrEdit_WalkTrack_ProcessEvent
	ldw_d16 xbc, 0x275e
	inc 1, bc
	stda16 0x275e, xbc
	ldb_d8 a, 0x2774
	extz wa
	subda16 xbc, 0x276a
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
	setda 1, 0x295f
	stdi8 0x2760, 0
	ret

BmDrEdit_WalkTrack_CheckNoteCount:
	cp l, 0x81
	jr nz, BmDrEdit_WalkTrack_CheckNoteOn
	ldw_d16 xbc, 0x275e
	inc 1, bc
	stda16 0x275e, xbc
	ldb_d8 a, 0x2774
	extz wa
	subda16 xbc, 0x276a
	cp bc, wa
	jr c, BmDrEdit_WalkTrack_CheckNoteOn

BmDrEdit_WalkTrack_CountExceeded:
	setda 4, 0x295f
	ret

BmDrEdit_WalkTrack_CheckNoteOn:
	and l, 0xf0
	cp l, 0x90
	jr nz, BmDrEdit_WalkTrack_ProcessEvent
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr nz, BmDrEdit_WalkTrack_ProcessEvent
	jrl BmDrEdit_ReadEventAtPosition

BmDrEdit_SetupCoordinates:
	ld xde, xwa
	ldmw2 (xde), 0x275e
	ld xhl, xde
	ld wa, (xhl)
	mul wa, 0x60
	ld (xhl), wa
	ldb_d8 a, 0x2760
	extz wa
	add (xde), wa
	ldmw2 (xbc), 0x276a
	ld xde, xbc
	ld wa, (xde)
	mul wa, 0x60
	ld (xde), wa
	ldb_d8 a, 0x276c
	extz wa
	add (xbc), wa
	ret

BmDrEdit_SetupAndWalkToNote:
	dec 4, xsp
	pushw_erp 0xfa
	resda 0, 0x295f
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 2)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub (xsp + 4), wa
	ld wa, (xsp + 4)
	cpda16 xwa, 0x279a
	jr nz, BmDrEdit_SetupAndWalkDone
	call SeqData_ReadNextByte
	and l, 0xf0
	cp l, 0x90
	jr nz, BmDrEdit_SetupAndWalkDone
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr nz, BmDrEdit_SetupAndWalkDone
	setda 0, 0x295f
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stb_d8 0x2786, l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stb_d8 0x2788, l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ldb_erp L, 0xfb
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	res 7, l
	res_erpb 0xfb, 0x07
	extz hl
	ld bc, hl
	mul bc, 0x60
	ld hl, bc
	stb_erp A, 0xfb
	extz wa
	add hl, wa
	stda16 0x278c, xhl
	calr BmDrEdit_ClearAndScanToEnd
	ldmm8 0x2962, 0x2786
	calr BmDrEdit_AdjustScrollToView

BmDrEdit_SetupAndWalkDone:
	popw_erp 0xfa
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
	and l, 0xf0
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
	lda_d16 xbc, 0x2746
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
	bitda 0, 0x2742
	jr z, BmDrEdit_FindNote_SetupLoop
	lds iy, 1

BmDrEdit_FindNote_SetupLoop:
	lds iz, 0
	cps iy, 0
	jr ule, BmDrEdit_FindNote_NotFound
	lda_d16 xix, 0x2746

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
	cpda8 c, 0x2960
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
	ldw hl, 0xff

BmDrEdit_FindNote_Return:
	popw iz
	ret

BmDrEdit_ClearAllSlotsAlt:
	lda_d16 xbc, 0x2747
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
	lda_d16 xbc, 0x2746

BmDrEdit_CheckSlots_Loop:
	ld wa, de
	mul wa, 0x3
	extz xwa
	add xwa, xbc
	bitm 7, (xwa)
	jr z, BmDrEdit_CheckSlots_Next
	ldw hl, 0xff
	ret

BmDrEdit_CheckSlots_Next:
	inc 1, de
	cp de, 0x8
	jr c, BmDrEdit_CheckSlots_Loop
	lds hl, 0
	ret

BmDrEdit_CalcBeatFromGridPos:
	ldw_d16 xwa, 0x279a
	extz xwa
	div wa, 0x60
	stw_erp WA, 0xe2
	stb_d8 0x2760, a
	ldw_d16 xwa, 0x279a
	extz xwa
	div wa, 0x60
	stda16 0x275e, xwa
	ldw_d16 xwa, 0x276a
	adddm16 0x275e, xwa
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
	ret

BmDrEdit_ChordScrollUp_Check:
	bitda 7, 0x295c
	jr z, BmDrEdit_ChordScrollUp
	cpdi8 0x295d, 4
	ret nz

BmDrEdit_ChordScrollUp:
	ldb_d8 a, 0x2798
	cp a, 0x9
	ret nc
	inc 1, a
	stb_d8 0x2798, a
	call NoteEditSy_UpdateChordDisplay
	stdi8 0x295c, 129
	stdi8 0x295d, 4
	ret

BmDrEdit_ChordScrollDown_Check:
	bitda 7, 0x295c
	jr z, BmDrEdit_ChordScrollDown
	cpdi8 0x295d, 4
	ret nz

BmDrEdit_ChordScrollDown:
	ldb_d8 a, 0x2798
	cps a, 0
	ret z
	dec 1, a
	stb_d8 0x2798, a
	call NoteEditSy_UpdateChordDisplay
	stdi8 0x295c, 129
	stdi8 0x295d, 4
	ret

BmDrEdit_NullReturn:
	ret

BmDrEdit_PitchWrapToEnd:
	ldw_d16 xwa, 0x2782
	cps wa, 0
	jr z, BmDrEdit_PitchWrapPrevPage
	stdi8 0x2784, 95
	ldw_d16 xwa, 0x2782
	dec 1, wa
	stda16 0x2782, xwa
	jr BmDrEdit_PitchWrap_UpdateDisplay

BmDrEdit_PitchWrapPrevPage:
	ldw_d16 xwa, 0x2744
	cpda16 xwa, 0x27b2
	jr z, BmDrEdit_PitchWrap_CheckEnd
	calr BmDrEdit_CalcEventPosition
	decdi16 1, 0x2744
	stdi8 0x2784, 95
	call NoteEditSy_SendScrollCmd0

BmDrEdit_PitchWrap_UpdateDisplay:
	call NoteEditSy_SendScrollCmd2
	call NoteEditSy_SendScrollCmd1
	calr NoteEditSy_CallFarRoutine
	jrl BmDrEdit_SetFeedbackTimer

BmDrEdit_PitchWrap_CheckEnd:
	bitda 0, 0x295f
	jrl z, BmDrEdit_NavigatePrevPage
	cps wa, 1
	ret z
	stdi8 0x295c, 0
	calr ReadSeqData_StoreParams
	jrl BmDrEdit_NavigateToPrevAndDisplay

BmDrEdit_CalcDurationPosition:
	calr BmDrEdit_SaveEditState
	call SeqData_ReadNextByte
	and l, 0xf0
	cp l, 0x90
	ret nz
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	ldw_d16 xwa, 0x278c
	extz xwa
	div wa, 0x60
	stw_erp WA, 0xe2
	and wa, 0x7f
	extz wa
	call PartCtrl_WriteByte_Indexed
	call SeqData_AdvancePosition
	ldw_d16 xwa, 0x278c
	extz xwa
	div wa, 0x60
	and wa, 0x7f
	extz wa
	call PartCtrl_WriteByte_Indexed
	jrl BmDrEdit_RestoreEditState

BmDrEdit_UpdateGateDisplay:
	calr BmDrEdit_SaveEditState
	call SeqData_ReadNextByte
	and l, 0xf0
	cp l, 0x90
	ret nz
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	ldb_d8 l, 0x2788
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	calr BmDrEdit_RestoreEditState
	jrl BmDrEdit_SendMetronomeNoteOn

BmDrEdit_UpdateVelocityDisplay:
	calr BmDrEdit_SaveEditState
	call SeqData_ReadNextByte
	and l, 0xf0
	cp l, 0x90
	ret nz
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	ldb_d8 l, 0x2786
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	calr BmDrEdit_RestoreEditState
	jrl BmDrEdit_SendMetronomeNoteOn

BmDrEdit_InsertNoteEvent:
	resda 0, 0x295f
	calr BmDrEdit_CalcTrackPosition
	ldmm8 0x2960, 0x2786
	ldb_d8 a, 0x278a
	stb_d8 0x2961, a
	ldmm8 0x2788, 0x278a
	calr BmDrEdit_PlayNoteAndSetDelay
	calr BmDrEdit_WalkEventsOrSetError
	jr BmDrEdit_RefreshAfterInsert

BmDrEdit_SendWidgetCmd:
	bitda 0, 0x2742
	ret z
	jp NoteEditSy_SendWidgetCmdE

BmDrEdit_NavigatePrevPage:
	ldw_d16 xwa, 0x2744
	cps wa, 1
	ret ule
	dec 1, wa
	stda16 0x2744, xwa
	calr BmDrEdit_SelectChannelAndLoadPos
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_ScanChannelEvents
	incdi16 1, 0x2744
	stdi16 0x2782, 0
	stdi8 0x2784, 0
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
	bitda 2, 0x295f
	jr z, BmDrEdit_RefreshAfterInsert_CheckFull
	ldw wa, 0xd0
	call SeqData_SetErrorCode
	jrl BmDrEdit_RefreshDisplayState

BmDrEdit_RefreshAfterInsert_CheckFull:
	ldb_d8 a, 0x2774
	mul a, 0x60
	cpdm16 0x279a, xwa
	jrl nc, BmDrEdit_NavigateAndLoadPosition
	calr BmDrEdit_CalcBeatMeasure
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	jrl NoteEdit_UpdateScrollAndDisplay

BmDrEdit_SetupScrollRegion:
	ld xde, xwa
	bitda 0, 0x2742
	jr z, BmDrEdit_SetupScrollRegion_MelodicMode
	ldw_d16 xwa, 0x279e
	ld (xde), a
	ldw_d16 xwa, 0x279e
	ld (xbc), a
	addmi8 (xbc), 0xb
	ret

BmDrEdit_SetupScrollRegion_MelodicMode:
	ldb_d8 a, 0x2798
	extz wa
	add wa, wa
	lda_24 xhl, WidgetData_DrawbarPositionTable
	ldb_sri A, 0x07, 0xec, 0xe0
	ld (xde), a
	ldb_d8 a, 0x2798
	extz wa
	add wa, wa
	inc 1, wa
	ldb_sri A, 0x07, 0xec, 0xe0
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
	pushw 0x6a4
	call Malloc
	inc 2, xsp
	stda32 7504, xhl
	stda32 7508, xhl
	calr NoteEditSy_ScanAndSortEntries
	stdi16 0x278e, 10
	ldmm16 0x2792, 0x2796
	setda 0, 0x2742
	stdi8 0x2774, 7
	stdi8 0x27a2, 8
	jr BmDrEdit_InitCommon

BmDrEdit_InitMelodicMode:
	ldmm16 0x2792, 0x2794
	ldmm16 0x278e, 0x2790
	resda 0, 0x2742
	stdi8 0x2774, 10
	stdi8 0x27a2, 11
	jr BmDrEdit_InitCommon

BmDrEdit_InitCommon:
	pushw iz
	cpdi16 0x2792, 0
	jr nz, BmDrEdit_InitCommon_CheckSongActive
	stdi16 0x2792, 48

BmDrEdit_InitCommon_CheckSongActive:
	ldb_d8 a, 0x8d36
	cpda8 a, 0x8d37
	jr nz, BmDrEdit_InitCommon_SetupDisplay
	ldb_d8 a, 0x8d38
	cpda8 a, 0x8d39
	jr z, BmDrEdit_InitCommon_SetupDisplay
	bitda 4, 0x28ad
	jr z, BmDrEdit_InitCommon_SetupDisplay
	lds wa, 1
	call UI_PostPartChangeEvent
	resda 4, 0x28ad
	resda 0, 9834
	jrl BmDrEdit_PopIzAndReturn

BmDrEdit_InitCommon_SetupDisplay:
	setda 0, 9834
	setda 0, 9954
	call AccWrap_PlayModeDispatch
	setda 2, 0x28a7
	stdi8 0x295c, 0
	ldw_d16 xwa, 0x2963
	stda16 3407, xwa
	ldmm16 3409, 0x2963
	ldb_d8 a, 0x8d39
	cp a, 0x96
	jr z, BmDrEdit_CopyStepCount
	cp a, 0x99
	jr z, BmDrEdit_CopyStepCount
	cp a, 0x94
	jr z, BmDrEdit_SetRecordingFlag
	cp a, 0x97
	jr nz, BmDrEdit_CheckDrumModeEntry

BmDrEdit_SetRecordingFlag:
	setda 0, 0x8d88
	jr BmDrEdit_ReadVoiceBitAndCopy

BmDrEdit_CheckDrumModeEntry:
	bitda 0, 0x2742
	jrl z, BmDrEdit_FlagDisplayUpdate
	ldb_d8 a, 0x295b
	bit 0, a
	jrl z, BmDrEdit_FlagDisplayUpdate
	res 0, a
	stb_d8 0x295b, a

BmDrEdit_ReadVoiceBitAndCopy:
	ldb_d8 c, 0x2965
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, BmDrEdit_InitFirstStep

BmDrEdit_CopyStepCount:
	ldmm16 0x2744, 9832
	jrl BmDrEdit_InitPlayback

BmDrEdit_InitFirstStep:
	stdi16 0x2744, 1
	cpdi16 0xf231, 0
	jrl z, BmDrEdit_RefreshAndReturn
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	ld wa, iz
	lds bc, 1
	call PartCtrl_SetClearBit7
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	ldb_d8 c, 0x2965
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	ldb_d8 c, 0x2965
	inc 1, c
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteVoiceWord
	ldb_d8 c, 0x2965
	inc 1, c
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteWord_Indexed
	ldb_d8 c, 0x2965
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 5
	call Part_WriteByte_Indexed
	stda16 0x28af, xiz
	stdi16 9830, 5
	calr BmDrEdit_InsertStepEntry
	incdi16 1, 9830
	calr BmDrEdit_InsertStepEntry

BmDrEdit_InitPlayback:
	calr Metronome_PlayClick
	call TempoRingBuf_Init
	call SeqBuf_Init
	calr BmDrEdit_ClearAllSlotsAlt
	calr BmDrEdit_ClearAllSlots
	calr BmDrEdit_SelectChannelAndLoadPos
	cpdi8 0x287a, 0
	jr z, BmDrEdit_ResetAndScanNotes
	stdi16 0x2744, 1
	calr BmDrEdit_SelectChannelAndLoadPos
	cpdi8 0x287a, 0
	jr z, BmDrEdit_ResetAndScanNotes

BmDrEdit_RefreshAndReturn:
	calr BmDrEdit_RefreshDisplayState
	jr BmDrEdit_PopIzAndReturn

BmDrEdit_ResetAndScanNotes:
	stdi16 0x279a, 0
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_CalcTrackPosition
	calr BmDrEdit_SaveAndFindNote
	calr BmDrEdit_CheckNoteAtPosition
	calr BmDrEdit_SetupAndWalkToNote
	stdi16 0x2782, 0
	stdi8 0x2784, 0
	calr BmDrEdit_ScanChannelEvents

BmDrEdit_FlagDisplayUpdate:
	call Audio_CheckSubsystemReady
	setda 0, 0x27b0

BmDrEdit_PopIzAndReturn:
	popw iz
	ret

BmDrEdit_CleanupDrumMode:
	ldmm16 0x2796, 0x2792
	ldda32 xwa, 7504
	push xwa
	call Free
	inc 4, xsp
	cpdi8 0x8d36, 152
	jr z, BmDrEdit_SkipPartSelect
	resda 0, 9954
	call PartSelect_UpdateDisplayState

BmDrEdit_SkipPartSelect:
	jr BmDrEdit_CleanupCommon

BmDrEdit_CleanupMelodicMode:
	cpdi8 0x8d36, 149
	jr z, BmDrEdit_SkipMelodicPartSelect
	resda 0, 9954
	call PartSelect_UpdateDisplayState

BmDrEdit_SkipMelodicPartSelect:
	ldmm16 0x2794, 0x2792
	ldmm16 0x2790, 0x278e
	jr BmDrEdit_CleanupCommon

BmDrEdit_CleanupCommon:
	resda 2, 0x28a7
	stdi8 0x295c, 0
	ldw_d16 xwa, 3407
	ordm16_24 0xffec, xwa
	stdi16 3407, 0
	stdi16 3409, 0
	ldmm16 9832, 0x2744
	call Audio_CheckSubsystemReady
	resda 0, 0x27b0
	calr BmDrEdit_ClearAllSlotsAlt
	jrl BmDrEdit_ClearAllSlots

BmDrEdit_InsertNotesFromSlots:
	pushw iz
	bitda 0, 0x2742
	jr z, BmDrEdit_InsertNotesFromSlots_MelodicInit
	ldmm8 0x2960, 0x2786
	ldmm8 0x2961, 0x2748
	calr BmDrEdit_WalkEventsOrSetError
	jr BmDrEdit_InsertNotesFromSlots_Done

BmDrEdit_InsertNotesFromSlots_MelodicInit:
	lds iz, 0

BmDrEdit_InsertNotesFromSlots_Loop:
	ld de, iz
	mul de, 0x3
	lds wa, 1
	add wa, de
	lda_d16 xbc, 0x2746
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cps a, 0
	jr z, BmDrEdit_InsertNotesFromSlots_Next
	stb_d8 0x2960, a
	lds wa, 2
	add wa, de
	extz xwa
	add xwa, xbc
	mrib4 0x80, 0x19, 0x61, 0x29
	calr BmDrEdit_PrepareAndInsertNote
	cpdi8 0x287a, 0
	jr z, BmDrEdit_InsertNotesFromSlots_CalcBeat
	calr BmDrEdit_RefreshDisplayState
	jr BmDrEdit_InsertNotesFromSlots_Done

BmDrEdit_InsertNotesFromSlots_CalcBeat:
	calr BmDrEdit_CalcBeatFromGridPos

BmDrEdit_InsertNotesFromSlots_Next:
	inc 1, iz
	cp iz, 0x8
	jr c, BmDrEdit_InsertNotesFromSlots_Loop

BmDrEdit_InsertNotesFromSlots_Done:
	popw iz
	ret

BmDrEdit_WalkEventsOrSetError:
	calr BmDrEdit_PrepareAndInsertNote
	cpdi8 0x287a, 0
	jrl z, BmDrEdit_CalcBeatFromGridPos
	ldw wa, 0xcf
	call SeqData_SetErrorCode
	jrl BmDrEdit_RefreshDisplayState

BmDrEdit_WalkToGridPosition:
	dec 4, xsp
	calr BmDrEdit_LoadAlternateState
	cpdi16 0x279a, 0
	jr nz, BmDrEdit_WalkToGrid_ReadNext
	jr BmDrEdit_CleanupReturn

BmDrEdit_WalkToGrid_CheckEvent:
	cp l, 0x82
	jr z, BmDrEdit_CleanupReturn
	calr BmDrEdit_ReadEventAtPosition
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cpda16 xwa, 0x279a
	jr ugt, BmDrEdit_CleanupReturn

BmDrEdit_WalkToGrid_SkipEvent:
	call SeqData_SkipToNextEvent

BmDrEdit_WalkToGrid_ReadNext:
	call SeqData_ReadNextByte
	cp l, 0x81
	jr nz, BmDrEdit_WalkToGrid_CheckEvent
	stdi8 0x2760, 0
	incdi16 1, 0x275e
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cpda16 xwa, 0x279a
	jr ule, BmDrEdit_WalkToGrid_SkipEvent

BmDrEdit_CleanupReturn:
	inc 4, xsp
	ret

BmDrEdit_HandleDelayExpired_Rescan:
	calr Metronome_PlayClick
	calr BmDrEdit_SelectChannelAndLoadPos
	cpdi8 0x287a, 0
	jr z, BmDrEdit_Rescan_LoadAlternate
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jr nz, BmDrEdit_Rescan_RefreshDisplay
	calr BmDrEdit_SelectChannelAndLoadPos

BmDrEdit_Rescan_LoadAlternate:
	calr BmDrEdit_ScanChannelEvents
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_ValidateAndInsertSteps
	cpdi8 0x287a, 0
	jr z, BmDrEdit_Rescan_CalcAndWalk

BmDrEdit_Rescan_RefreshDisplay:
	jrl BmDrEdit_RefreshDisplayState

BmDrEdit_Rescan_CalcAndWalk:
	calr BmDrEdit_CalcTrackPosition
	calr BmDrEdit_SaveAndFindNote
	calr BmDrEdit_CheckNoteAtPosition
	calr BmDrEdit_SetupAndWalkToNote
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	calr NoteEditSy_SendCompoundWidgetUpdate
	jrl NoteEdit_UpdateScrollAndDisplay

BmDrEdit_ValidateAndInsertSteps:
	stdi8 0x287a, 0
	calr BmDrEdit_SaveEditState
	cpdi8 0x287a, 0
	jr z, BmDrEdit_ValidateSteps_CheckCount
	ldw wa, 0xb6
	call SeqData_SetErrorCode

BmDrEdit_ValidateSteps_CheckCount:
	calr BmDrEdit_CountMeasuresAndValidate
	cpdi16 0x2772, 0
	ret nz
	stdi16 0x2772, 2

BmDrEdit_ValidateSteps_InsertLoop:
	calr EditChannel_LoadVoiceParams
	calr BmDrEdit_InsertStepEntry
	cpdi8 0x287a, 0
	jr nz, BmDrEdit_ValidateSteps_RestoreState
	ldw_d16 xwa, 0x2772
	dec 1, wa
	stda16 0x2772, xwa
	cps wa, 0
	jr nz, BmDrEdit_ValidateSteps_InsertLoop

BmDrEdit_ValidateSteps_RestoreState:
	jrl BmDrEdit_RestoreEditState

BmDrEdit_SeekToPartVoice:
	ldb_d8 c, 0x2965
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceWord
	cp hl, 0xffff
	ret z
	stda16 0x28af, xhl
	stdi16 9830, 5
	cpdi8 0x287a, 0
	jr z, BmDrEdit_SeekVoice_CountAndInsert
	ldw wa, 0xb7
	call SeqData_SetErrorCode

BmDrEdit_SeekVoice_CountAndInsert:
	calr BmDrEdit_CountMeasuresAndValidate
	calr BmDrEdit_InsertMultiSongSteps
	cpdi8 0x287a, 0
	jr nz, BmDrEdit_SeekVoice_RefreshDisplay
	ldw_d16 xwa, 0x2782
	inc 2, wa
	stda16 0x2772, xwa
	cps wa, 0
	ret z

BmDrEdit_SeekVoice_InsertLoop:
	calr EditChannel_LoadVoiceParams
	calr BmDrEdit_InsertStepEntry
	cpdi8 0x287a, 0
	jr z, BmDrEdit_SeekVoice_DecrementLoop

BmDrEdit_SeekVoice_RefreshDisplay:
	jrl BmDrEdit_RefreshDisplayState

BmDrEdit_SeekVoice_DecrementLoop:
	ldw_d16 xwa, 0x2772
	dec 1, wa
	stda16 0x2772, xwa
	cps wa, 0
	jr nz, BmDrEdit_SeekVoice_InsertLoop
	ret

BmDrEdit_CalcTickPosition:
	calr BmDrEdit_CheckAndAdvancePage
	ldw_d16 xbc, 0x2782
	mul bc, 0x60
	ldb_d8 a, 0x2784
	extz wa
	add bc, wa
	stda16 0x279a, xbc
	ret

BmDrEdit_ReloadChannelAndDisplay:
	calr BmDrEdit_SelectChannelAndLoadPos
	cpdi8 0x287a, 0
	jr z, BmDrEdit_ReloadChannel_LoadAndSkip
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jr nz, BmDrEdit_ReloadChannel_RefreshDisplay
	calr BmDrEdit_SelectChannelAndLoadPos

BmDrEdit_ReloadChannel_LoadAndSkip:
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_SkipToEventByCount
	cpdi8 0x287a, 0
	jr z, BmDrEdit_LoadAndDisplayNotes
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jr z, BmDrEdit_LoadAndDisplayNotes

BmDrEdit_ReloadChannel_RefreshDisplay:
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
	bitda 0, 0x295f
	ret z
	calr BmDrEdit_SendMetronomeNoteOn
	ret

BmDrEdit_NavigateAndLoadPosition:
	calr BmDrEdit_CalcTickPosition
	calr BmDrEdit_SelectChannelAndLoadPos
	cpdi8 0x287a, 0
	jr z, BmDrEdit_NavLoad_LoadAndSkip
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jr nz, BmDrEdit_NavLoad_RefreshDisplay
	calr BmDrEdit_SelectChannelAndLoadPos

BmDrEdit_NavLoad_LoadAndSkip:
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_SkipToEventByCount
	cpdi8 0x287a, 0
	jr z, BmDrEdit_NavigateAndDisplayNotes
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jr z, BmDrEdit_NavigateAndDisplayNotes

BmDrEdit_NavLoad_RefreshDisplay:
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
	bitda 0, 0x295f
	ret z
	calr BmDrEdit_SendMetronomeNoteOn
	ret

BmDrEdit_SkipToEventByCount:
	stdi8 0x287a, 0
	ldw_d16 xwa, 0x2782
	cps wa, 0
	ret z
	stda16 0x2772, xwa
	cps wa, 0
	ret z

BmDrEdit_SkipToEvent_ReadLoop:
	call SeqData_ReadNextByte
	cp l, 0x81
	jr nz, BmDrEdit_SkipToEvent_EndOfTrack
	decdi16 1, 0x2772

BmDrEdit_SkipToEvent_SkipAndCheck:
	call SeqData_SkipToNextEvent
	cpdi16 0x2772, 0
	jr nz, BmDrEdit_SkipToEvent_ReadLoop
	ret

BmDrEdit_SkipToEvent_EndOfTrack:
	cp l, 0x82
	jr nz, BmDrEdit_SkipToEvent_SkipAndCheck
	stdi8 0x287a, 255
	ret

BmDrEdit_NavigateToPrevAndDisplay:
	ldw_d16 xwa, 0x2744
	cps wa, 1
	ret ule
	dec 1, wa
	stda16 0x2744, xwa
	calr BmDrEdit_SelectChannelAndLoadPos
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_ScanChannelEvents
	incdi16 1, 0x2744
	stdi16 0x2782, 0
	stdi8 0x2784, 0
	calr BmDrEdit_LoadAlternatePosition
	calr BmDrEdit_BuildVoiceList
	calr BmDrEdit_SyncSeekCheck
	calr BmDrEdit_SetupAndWalkToNote
	calr NoteEditSy_SendCompoundWidgetUpdate
	calr NoteEdit_UpdateScrollAndDisplay
	call NoteEditSy_SendWidgetCmd0
	jrl NoteEdit_SendScrollCmds

EditChannel_LoadVoiceParams:
	ldb_d8 c, 0x2965
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadWord_Indexed
	stda16 0x28af, xhl
	ldb_d8 c, 0x2965
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadByte_Indexed
	stda16 9830, xhl
	ret

BmDrEdit_DelayAction_SetupAndWalk:
	dec 4, xsp
	bitda 0, 0x295f
	jr z, BmDrEdit_DelayAction_UpdateDisplay
	calr ReadSeqData_StoreParams
	calr BmDrEdit_SetupAndWalkToNote
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	stda16 0x279a, xwa

BmDrEdit_DelayAction_UpdateDisplay:
	calr NoteEdit_UpdateScrollAndDisplay
	inc 4, xsp
	ret

BmDrEdit_DelayAction_WalkAndUpdate:
	calr BmDrEdit_SetupAndWalkToNote
	jrl NoteEdit_UpdateScrollAndDisplay

BmDrEdit_DelayAction_PlayClick:
	jrl Metronome_PlayClick

BmDrEdit_DelayAction_CheckCountError:
	bitda 0, 0x295f
	jr z, BmDrEdit_DelayAction_UpdateScroll
	calr BmDrEdit_CountMeasuresInit
	cpdi8 0x287a, 0
	jr z, BmDrEdit_DelayAction_UpdateScroll
	ldw wa, 0xcc
	call SeqData_SetErrorCode
	jrl BmDrEdit_RefreshDisplayState

BmDrEdit_DelayAction_UpdateScroll:
	jrl NoteEdit_UpdateScrollAndDisplay

BmDrEdit_DelayAction_UpdateScrollAlt:
	jrl NoteEdit_UpdateScrollAndDisplay

BmDrEdit_ReadNoteDataFields:
	pushw_erp 0xfa
	cpdi8 0x287a, 0
	jr z, BmDrEdit_ReadNoteData_Advance
	ldw wa, 0xb9
	call SeqData_SetErrorCode

BmDrEdit_ReadNoteData_Advance:
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ldb_erp L, 0xfb
	cpdi8 0x287a, 0
	jr z, BmDrEdit_ReadNoteData_StoreDuration
	ldw wa, 0xba
	call SeqData_SetErrorCode

BmDrEdit_ReadNoteData_StoreDuration:
	stb_erp L, 0xfb
	popw_erp 0xfa
	ret

BmDrEdit_PitchScrollOverflow:
	ldb_d8 c, 0x2774
	ld a, c
	extz wa
	mul wa, 0x60
	dec 1, wa
	cpdm16 0x279a, xwa
	jr c, BmDrEdit_PitchOverflow_CheckNextPage
	mul c, 0x60
	stda16 0x279a, xbc
	bitda 0, 0x295f
	jrl z, BmDrEdit_NavigateAndLoadPosition
	calr BmDrEdit_CalcTickPosition
	stdi8 0x295c, 0
	calr ReadSeqData_StoreParams
	jrl BmDrEdit_ReloadChannelAndDisplay

BmDrEdit_PitchOverflow_CheckNextPage:
	calr BmDrEdit_FindNextPageEntry
	cp l, 0xff
	jr z, BmDrEdit_PitchOverflow_IncrementBeat
	extz hl
	ldw_d16 xwa, 0x2782
	cp wa, hl
	jr nc, BmDrEdit_PitchOverflow_NextPage

BmDrEdit_PitchOverflow_IncrementBeat:
	stdi8 0x2784, 0
	incdi16 1, 0x2782
	jr BmDrEdit_PitchOverflow_UpdateDisplay

BmDrEdit_PitchOverflow_NextPage:
	stdi16 0x2782, 0
	incdi16 1, 0x2744
	stdi8 0x2784, 0
	call NoteEditSy_SendScrollCmd0

BmDrEdit_PitchOverflow_UpdateDisplay:
	call NoteEditSy_SendScrollCmd2
	call NoteEditSy_SendScrollCmd1
	calr NoteEditSy_CallFarRoutine
	calr BmDrEdit_SaveEditState
	calr BmDrEdit_SeekForwardToEvent
	calr BmDrEdit_RestoreEditState
	cpdi8 0x287a, 0
	jrl nz, BmDrEdit_RefreshDisplayState
	jrl BmDrEdit_SetFeedbackTimer

NoteEditSy_CallFarRoutine:
	jrl BmDrEdit_BuildVoiceList

BmDrEdit_AdjustViewAndInsert:
	dec 4, xsp
	bitda 7, 0x295c
	jrl nz, BmDrEdit_AdjustViewReturn
	calr BmDrEdit_SaveEditState
	ldmm16 0x279c, 0x279a
	calr BmDrEdit_AlignDisplayGrid
	ldb_d8 a, 0x2774
	mul a, 0x60
	cpdm16 0x279a, xwa
	call_24 c, BmDrEdit_CalcBeatMeasure
	bitda 0, 0x295f
	jr nz, BmDrEdit_WalkTrackLoop
	calr BmDrEdit_LoadAndCheckNote
	call SeqData_ReadNextByte
	and l, 0xf0
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
	cpda16 xwa, 0x279a
	jr ule, BmDrEdit_AdjustView_InitAndNavigate
	bitda 1, 0x295f
	jr z, BmDrEdit_WalkTrackLoop
	calr BmDrEdit_InsertNoteSequence
	bitda 2, 0x295f
	jr nz, BmDrEdit_AdjustView_RefreshDisplay
	jr BmDrEdit_AdjustViewPath

BmDrEdit_WalkTrackLoop:
	calr BmDrEdit_WalkTrackForward
	ldb_d8 a, 0x295f
	bit 4, a
	jr nz, BmDrEdit_AdjustViewPath
	bit 1, a
	jr z, BmDrEdit_AdjustView_CheckCoords
	calr BmDrEdit_InsertNoteSequence
	bitda 2, 0x295f
	jr z, BmDrEdit_AdjustViewPath

BmDrEdit_AdjustView_RefreshDisplay:
	calr BmDrEdit_RefreshDisplayState
	jr BmDrEdit_AdjustViewReturn

BmDrEdit_AdjustView_CheckCoords:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ldw_d16 xwa, 0x279a
	add (xsp), wa
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jr ule, BmDrEdit_AdjustView_InitAndNavigate

BmDrEdit_AdjustViewPath:
	calr BmDrEdit_AdjustViewToPosition
	jr BmDrEdit_AdjustViewReturn

BmDrEdit_AdjustView_InitAndNavigate:
	calr BmDrEdit_InitViewAndNavigate

BmDrEdit_AdjustViewReturn:
	inc 4, xsp
	ret

BmDrEdit_LoadAndCheckNote:
	dec 4, xsp
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_CheckNoteAtPosition
	call SeqData_ReadNextByte
	and l, 0xf0
	cp l, 0x90
	jr nz, BmDrEdit_LoadNote_WalkTrack
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr z, BmDrEdit_AdvanceToVisibleNote
	calr BmDrEdit_WalkTrackForward
	bitda 1, 0x295f
	jr z, BmDrEdit_AdvanceToVisibleNote
	jr BmDrEdit_WalkReturn

BmDrEdit_LoadNote_WalkTrack:
	calr BmDrEdit_WalkTrackForward
	bitda 1, 0x295f
	jr nz, BmDrEdit_WalkReturn

BmDrEdit_AdvanceToVisibleNote:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cpda16 xwa, 0x279c
	jr ugt, BmDrEdit_WalkReturn
	calr BmDrEdit_WalkTrackForward
	bitda 1, 0x295f
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
	stda16 0x279a, xwa
	ldb_d8 a, 0x2774
	mul a, 0x60
	cpdm16 0x279a, xwa
	jr c, BmDrEdit_InitView_CalcAndWalk
	calr BmDrEdit_NavigateAndLoadPosition
	jr BmDrEdit_InitView_Return

BmDrEdit_InitView_CalcAndWalk:
	calr BmDrEdit_CalcBeatMeasure
	calr BmDrEdit_SetupAndWalkToNote
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	calr NoteEdit_UpdateScrollAndDisplay
	calr BmDrEdit_SendMetronomeNoteOn

BmDrEdit_InitView_Return:
	inc 4, xsp
	ret

BmDrEdit_AdjustViewToPosition:
	ldb_d8 a, 0x2774
	mul a, 0x60
	cpdm16 0x279a, xwa
	jrl nc, BmDrEdit_NavigateAndLoadPosition
	resda 0, 0x295f
	calr BmDrEdit_RestoreEditState
	calr BmDrEdit_CalcBeatMeasure
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	jrl NoteEdit_UpdateScrollAndDisplay

BmDrEdit_SendMetronomeNoteOn:
	calr Metronome_PlayClick
	calr BmDrEdit_BuildNoteOnEvent
	stdi8 0x295e, 134
	ret

BmDrEdit_SendMetronomeNoteOn_Alt:
	calr Metronome_PlayClick
	calr BmDrEdit_BuildNoteOnEvent_WithVelocity
	stdi8 0x295e, 134
	ret

Metronome_PlayClick:
	jr BmDrEdit_WriteNoteOffEntry

BmDrEdit_BuildNoteOnEvent:
	dec 8, xsp
	lda xwa, (xsp)
	ld (xwa), 0x90
	ld (xwa + 1), 0x7e
	ldmi16 (xwa + 2), 0x2786
	ldmi16 (xwa + 3), 0x2788
	ldmi16 (xwa + 4), 0x2965
	ld (xwa + 5), 0x0
	lds bc, 5
	call SeqBuf_WriteMidiEvent
	call SeqBuf_FlushAndReinit_NoteEvents
	inc 8, xsp
	ret

BmDrEdit_BuildNoteOnEvent_WithVelocity:
	dec 8, xsp
	lda xwa, (xsp)
	ld (xwa), 0x90
	ld (xwa + 1), 0x7e
	ldmi16 (xwa + 2), 0x2786
	ld (xwa + 3), 0x50
	ldmi16 (xwa + 4), 0x2965
	ld (xwa + 5), 0x0
	lds bc, 5
	call SeqBuf_WriteMidiEvent
	call SeqBuf_FlushAndReinit_NoteEvents
	inc 8, xsp
	ret

BmDrEdit_WriteNoteOffEntry:
	ldb_d8 a, 0x2965
	inc 1, a
	extz wa
	jp SeqBuf_WriteNoteOffEntry

BmDrEdit_InsertNoteSequence:
	push xiz
	ldw_d16 xwa, 0x28af
	ldw_erp WA, 0xfa
	ldw_d16 xiz, 9830
	resda 2, 0x295f
	calr BmDrEdit_LoadAlternateAndValidate
	ldw_d16 xbc, 0x279a
	extz xbc
	div bc, 0x60
	inc 1, bc
	ldw_d16 xwa, 0x2772
	cp bc, wa
	jr c, BmDrEdit_InsertSeq_PopIzRet
	inc 1, bc
	sub bc, wa
	stda16 0x2772, xbc
	calr EditChannel_LoadVoiceParams
	cpdi16 0x2772, 0
	jr z, BmDrEdit_SavePositionAndReturn

BmDrEdit_InsertSeq_StepLoop:
	calr BmDrEdit_InsertStepEntry
	cpdi8 0x287a, 0
	jr z, BmDrEdit_InsertSeq_DecrementCount
	setda 2, 0x295f
	jr BmDrEdit_SavePositionAndReturn

BmDrEdit_InsertSeq_DecrementCount:
	ldw_d16 xwa, 0x2772
	dec 1, wa
	stda16 0x2772, xwa
	cps wa, 0
	jr nz, BmDrEdit_InsertSeq_StepLoop

BmDrEdit_SavePositionAndReturn:
	stw_erp WA, 0xfa
	stda16 0x28af, xwa
	stda16 9830, xiz

BmDrEdit_InsertSeq_PopIzRet:
	pop xiz
	ret

BmDrEdit_ScanAfterModify:
	dec 4, xsp
	resda 3, 0x295f
	cpdi16 0x279c, 0
	jr nz, BmDrEdit_ScanAfterModify_LoadAndWalk
	call SeqData_ReadNextByte
	cp l, 0x81
	jr z, BmDrEdit_SetFlagReturn
	and l, 0xf0
	cp l, 0x90
	jr z, BmDrEdit_ScanAfterModify_CheckVelocity
	calr BmDrEdit_WalkAndScanAfterEdit
	jr BmDrEdit_ScanAfterModify_Return

BmDrEdit_ScanAfterModify_CheckVelocity:
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr nz, BmDrEdit_SetFlagReturn
	cpdi8 0x2760, 0
	jr nz, BmDrEdit_SetFlagReturn

BmDrEdit_ScanAfterModify_LoadAndWalk:
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_CheckNoteAtPosition

BmDrEdit_ScanAfterModify_WalkLoop:
	calr BmDrEdit_SaveEditState
	calr BmDrEdit_WalkTrackForward
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cpda16 xwa, 0x279c
	jr c, BmDrEdit_ScanAfterModify_WalkLoop
	calr BmDrEdit_RestoreEditState
	jr BmDrEdit_ScanAfterModify_Return

BmDrEdit_SetFlagReturn:
	setda 3, 0x295f

BmDrEdit_ScanAfterModify_Return:
	inc 4, xsp
	ret

BmDrEdit_AlignGridBackward:
	ldw_d16 xwa, 0x279a
	cps wa, 0
	ret z
	lds de, 0
	cps wa, 0
	jr ule, BmDrEdit_AlignGridBackward_Store
	ldw_d16 xbc, 0x2792

BmDrEdit_AlignGridBackward_AccumLoop:
	add de, bc
	cp de, wa
	jr c, BmDrEdit_AlignGridBackward_AccumLoop

BmDrEdit_AlignGridBackward_Store:
	subda16 xde, 0x2792
	stda16 0x279a, xde
	ret

BmDrEdit_LoadAlternateAndValidate:
	calr BmDrEdit_LoadAlternateState
	cpdi8 0x287a, 0
	jr z, BmDrEdit_LoadAlternateAndValidate_Done
	ldw wa, 0xb8
	call SeqData_SetErrorCode

BmDrEdit_LoadAlternateAndValidate_Done:
	jr BmDrEdit_CountMeasuresAndValidate

BmDrEdit_CountMeasuresAndValidate:
	cpdi8 0x287a, 0
	jr z, BmDrEdit_CountMeasures_Init
	ldw wa, 0xd1
	call SeqData_SetErrorCode

BmDrEdit_CountMeasures_Init:
	stdi16 0x2772, 0

BmDrEdit_CountMeasures_Loop:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_CheckAndReportScanError
	cp l, 0x84
	jr z, BmDrEdit_CheckAndReportScanError
	cp l, 0x81
	jr nz, BmDrEdit_CountMeasures_SkipEvent
	incdi16 1, 0x2772

BmDrEdit_CountMeasures_SkipEvent:
	call SeqData_SkipToNextEvent
	jr BmDrEdit_CountMeasures_Loop

BmDrEdit_CheckAndReportScanError:
	cpdi8 0x287a, 0
	ret z
	ldw wa, 0xce
	call SeqData_SetErrorCode
	ret

BmDrEdit_NavigateBackwardWithEdit:
	dec 4, xsp
	bitda 7, 0x295c
	jrl nz, BmDrEdit_NavigateReturn
	calr BmDrEdit_SaveEditState
	ldmm16 0x279c, 0x279a
	calr BmDrEdit_AlignGridBackward
	calr BmDrEdit_CalcBeatMeasure
	bitda 0, 0x295f
	jr nz, BmDrEdit_NavigateAfterEdit
	calr BmDrEdit_ScanAfterModify
	bitda 3, 0x295f
	jr z, BmDrEdit_NavEdit_CheckPosition
	cpdi16 0x2744, 1
	jr z, BmDrEdit_ResetToFirstEvent
	cpdi16 0x279c, 0
	jr z, BmDrEdit_GoToPrevPage

BmDrEdit_ResetToFirstEvent:
	calr BmDrEdit_AdjustViewToPosition
	jrl BmDrEdit_NavigateReturn

BmDrEdit_GoToPrevPage:
	calr BmDrEdit_NavigatePrevPage
	jrl BmDrEdit_NavigateReturn

BmDrEdit_NavEdit_CheckPosition:
	ldw_d16 xwa, 0x276e
	cpda16 xwa, 0x28af
	jr nz, BmDrEdit_CheckCurrentNoteMatch
	ldb_d8 a, 0x2770
	extz wa
	cpda16 xwa, 9830
	jr nz, BmDrEdit_CheckCurrentNoteMatch
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cpdm16 0x279c, xwa
	jr ule, BmDrEdit_ResetToFirstEvent

BmDrEdit_CheckCurrentNoteMatch:
	call SeqData_ReadNextByte
	and l, 0xf0
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
	cpda16 xwa, 0x279a
	jr nc, BmDrEdit_NavEdit_InitView

BmDrEdit_NavigateAfterEdit:
	calr BmDrEdit_WalkAndScanAfterEdit
	bitda 3, 0x295f
	jr z, BmDrEdit_NavEdit_CalcCoords
	cpdi16 0x2744, 1
	jr z, BmDrEdit_ResetToFirstEvent
	cpdi16 0x279c, 0
	jr z, BmDrEdit_GoToPrevPage
	jr BmDrEdit_ResetToFirstEvent

BmDrEdit_NavEdit_CalcCoords:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jrl c, BmDrEdit_ResetToFirstEvent
	ldw_d16 xwa, 0x279a
	add (xsp), wa
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jrl c, BmDrEdit_ResetToFirstEvent

BmDrEdit_NavEdit_InitView:
	calr BmDrEdit_InitViewAndNavigate

BmDrEdit_NavigateReturn:
	inc 4, xsp
	ret

BmDrEdit_WalkAndScanAfterEdit:
	dec 4, xsp
	resda 3, 0x295f
	call SeqData_ReadNextByte
	cp l, 0x81
	jr nz, BmDrEdit_ScanSequenceEnd
	ldw_d16 xwa, 0x275e
	cps wa, 0
	jr z, BmDrEdit_CheckVelocityMatch
	dec 1, wa
	stda16 0x275e, xwa
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jr c, BmDrEdit_CheckVelocityMatch

BmDrEdit_ScanSequenceEnd:
	calr BmDrEdit_ClearAndScanToEnd
	cpdi8 0x287a, 0
	jr z, BmDrEdit_WalkScan_ReadNext
	setda 3, 0x295f
	stdi8 0x287a, 0
	jr BmDrEdit_WalkScan_Return

BmDrEdit_WalkScan_ReadNext:
	call SeqData_ReadNextByte
	cp l, 0x81
	jr nz, BmDrEdit_WalkScan_CheckNoteOn
	ldw_d16 xwa, 0x275e
	cps wa, 0
	jr z, BmDrEdit_CheckVelocityMatch
	dec 1, wa
	stda16 0x275e, xwa
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jr nc, BmDrEdit_ScanSequenceEnd
	jr BmDrEdit_CheckVelocityMatch

BmDrEdit_WalkScan_CheckNoteOn:
	and l, 0xf0
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
	jr nc, BmDrEdit_WalkScan_Return

BmDrEdit_CheckVelocityMatch:
	setda 3, 0x295f

BmDrEdit_WalkScan_Return:
	inc 4, xsp
	ret

BmDrEdit_PostModeChange96:
	bitda 7, 0x2746
	ret nz
	bitda 7, 0x295c
	ret nz
	ldw wa, 0x96
	jp UI_PostModeChangeEvent

BmDrEdit_DrumVoiceUp_Check:
	bitda 7, 0x295c
	jr z, BmDrEdit_DrumVoiceUp_ClearFlag
	cpdi8 0x295d, 5
	ret nz

BmDrEdit_DrumVoiceUp_ClearFlag:
	resda 0, 0x295f
	jr BmDrEdit_DrumVoiceUp

BmDrEdit_DrumVoiceUp:
	bitda 7, 0x2746
	ret nz
	ldw_d16 xwa, 0x27a0
	cp wa, 0xb
	jr c, BmDrEdit_DrumVoiceUp_IncrementOctave
	ldw_d16 xwa, 0x279e
	cp wa, 0x74
	ret nc
	inc 1, wa
	stda16 0x279e, xwa
	jr BmDrEdit_DrumVoiceUp_UpdateDisplay

BmDrEdit_DrumVoiceUp_IncrementOctave:
	inc 1, wa
	stda16 0x27a0, xwa

BmDrEdit_DrumVoiceUp_UpdateDisplay:
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	call NoteEditSy_UpdateChordDisplay
	calr BmDrEdit_SendMetronomeNoteOn_Alt
	stdi8 0x295c, 131
	stdi8 0x295d, 5
	jp Audio_CheckSubsystemReady

BmDrEdit_DrumVoiceDown_Check:
	bitda 7, 0x295c
	jr z, BmDrEdit_DrumVoiceDown_ClearFlag
	cpdi8 0x295d, 5
	ret nz

BmDrEdit_DrumVoiceDown_ClearFlag:
	resda 0, 0x295f
	jr BmDrEdit_DrumVoiceDown

BmDrEdit_DrumVoiceDown:
	bitda 7, 0x2746
	ret nz
	ldw_d16 xwa, 0x27a0
	cps wa, 0
	jr nz, BmDrEdit_DrumVoiceDown_DecrementOctave
	ldw_d16 xwa, 0x279e
	cps wa, 1
	ret z
	dec 1, wa
	stda16 0x279e, xwa
	jr BmDrEdit_DrumVoiceDown_UpdateDisplay

BmDrEdit_DrumVoiceDown_DecrementOctave:
	dec 1, wa
	stda16 0x27a0, xwa

BmDrEdit_DrumVoiceDown_UpdateDisplay:
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	call NoteEditSy_UpdateChordDisplay
	calr BmDrEdit_SendMetronomeNoteOn_Alt
	stdi8 0x295c, 131
	stdi8 0x295d, 5
	jp Audio_CheckSubsystemReady

BmDrEdit_CalcTrackPosition:
	bitda 0, 0x2742
	ret z
	ldw_d16 xwa, 0x279e
	addda16 xwa, 0x27a0
	stb_d8 0x2786, a
	ret

BmDrEdit_PostModeChange99:
	bitda 7, 0x2746
	ret nz
	bitda 7, 0x295c
	ret nz
	ldw wa, 0x99
	jp UI_PostModeChangeEvent

BmDrEdit_DelayAction_WalkAndUpdateAlt:
	calr BmDrEdit_SetupAndWalkToNote
	jrl NoteEdit_UpdateScrollAndDisplay

BmDrEdit_PlayNoteAndSetDelay:
	calr BmDrEdit_SendMetronomeNoteOn
	stdi8 0x295e, 134
	ret

BmDrEdit_ApplyVelocityChange:
	lda xsp, (xsp - 20)
	pushw iz
	ld (xsp + 14), de
	ld (xsp + 16), xbc
	ld (xsp + 20), a
	cpw (xsp + 14), 0x0
	jrl z, BmDrEdit_VelChange_ReturnZero
	cpw (xsp + 14), 0xff
	jr ugt, BmDrEdit_VelChange_Error
	ldmw2 (xsp + 2), 0x28af
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
	cpw (xsp + 6), 0xff
	jr ule, BmDrEdit_VelChange_WriteParams
	ld wa, (xsp + 12)
	call PartCtrl_ReadWord
	ld (xsp + 8), hl
	cpw (xsp + 8), 0xffff
	jr nz, BmDrEdit_VelChange_LinkVoice
	ld wa, (xsp + 12)
	call Part_LinkVoiceToChain
	ld (xsp + 8), hl
	cps hl, 0
	jr ge, BmDrEdit_VelChange_LinkVoice
	ldw wa, 0xbb
	call SeqData_SetErrorCode

BmDrEdit_VelChange_Error:
	ldw hl, 0xffff
	jrl BmDrEdit_VelChange_Epilog

BmDrEdit_VelChange_LinkVoice:
	submi16 (xsp + 6), 0xff
	incm 4, (xsp + 6)

BmDrEdit_VelChange_WriteParams:
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

BmDrEdit_VelChange_CopyLoop:
	ld wa, (xsp + 12)
	ld bc, (xsp + 10)
	calr PartCtrl_ReadByteExtended
	extz hl
	ld wa, (xsp + 8)
	ld bc, (xsp + 6)
	ld de, hl
	calr PartCtrl_WriteByte_ZeroExtended
	ldw_d16 xwa, 0x28af
	cp wa, (xsp + 12)
	jr nz, BmDrEdit_VelChange_DecrementCounters
	ldw_d16 xwa, 9830
	cp wa, (xsp + 10)
	jr z, BmDrEdit_VelChange_WriteEventBytes

BmDrEdit_VelChange_DecrementCounters:
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 10)
	calr BmDrEdit_DecrementAndValidateCounter
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 6)
	calr BmDrEdit_DecrementAndValidateCounter
	jr BmDrEdit_VelChange_CopyLoop

BmDrEdit_VelChange_WriteEventBytes:
	lds iz, 0
	cpw (xsp + 14), 0x0
	jr ule, BmDrEdit_VelChange_Finalize

BmDrEdit_VelChange_WriteByteLoop:
	ld wa, iz
	extz xwa
	add xwa, (xsp + 16)
	ld a, (xwa)
	extz wa
	call PartCtrl_WriteByte_Indexed
	call SeqData_AdvancePosition
	inc 1, iz
	cp iz, (xsp + 14)
	jr c, BmDrEdit_VelChange_WriteByteLoop

BmDrEdit_VelChange_Finalize:
	mrdw5 0x9f, 0x02, 0x19, 0xaf, 0x28
	mrdw5 0x9f, 0x04, 0x19, 0x66, 0x26

BmDrEdit_VelChange_ReturnZero:
	lds hl, 0

BmDrEdit_VelChange_Epilog:
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
	jr nc, BmDrEdit_DecrValidate_ReturnZero
	ld wa, (xiz)
	call PartCtrl_ReadWord_Off1
	ld (xiz), hl
	cpw (xiz), 0x4d8
	jr ule, BmDrEdit_DecrValidate_LinkNext
	ldw wa, 0xa0
	call SeqData_SetErrorCode
	ldw hl, 0xffff
	jr BmDrEdit_DecrValidate_Epilog

BmDrEdit_DecrValidate_LinkNext:
	ld xwa, (xsp + 4)
	ldw (xwa), 0xff

BmDrEdit_DecrValidate_ReturnZero:
	lds hl, 0

BmDrEdit_DecrValidate_Epilog:
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
	cpw (xwa), 0xff
	jr ule, BmDrEdit_BoundsCheck_ReturnZero
	ld wa, (xiz)
	call PartCtrl_ReadWord
	ld (xiz), hl
	cpw (xiz), 0x4d8
	jr ule, BmDrEdit_BoundsCheck_ResetCounter
	ldw wa, 0xa1
	call SeqData_SetErrorCode
	ldw hl, 0xffff
	jr BmDrEdit_BoundsCheck_Epilog

BmDrEdit_BoundsCheck_ResetCounter:
	ld xwa, (xsp + 4)
	ldw (xwa), 0x5

BmDrEdit_BoundsCheck_ReturnZero:
	lds hl, 0

BmDrEdit_BoundsCheck_Epilog:
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
	stdi8 0x287a, 0
	ld (xsp), 0x81
	ldb_d8 a, 0x2965
	inc 1, a
	extz wa
	lda xbc, (xsp)
	lds de, 1
	calr BmDrEdit_ApplyVelocityChange
	inc 2, xsp
	ret

BmDrEdit_PrepareAndInsertNote:
	calr BmDrEdit_WalkToGridPosition
	stdi8 0x2967, 144
	ldw_d16 xwa, 0x279a
	extz xwa
	div wa, 0x60
	stw_erp WA, 0xe2
	stb_d8 0x2968, a
	ldmm8 0x2969, 0x2960
	ldmm8 0x296a, 0x2961
	ldw_d16 xwa, 0x278e
	extz xwa
	div wa, 0x60
	stw_erp WA, 0xe2
	res 7, a
	stb_d8 0x296b, a
	ldw_d16 xwa, 0x278e
	extz xwa
	div wa, 0x60
	res 7, a
	stb_d8 0x296c, a
	calr BmDrEdit_SaveSongPosition
	ldb_d8 a, 0x2965
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
	stdi8 0x287a, 0
	stb_d8 0x288d, c
	call SeqVoice_SetDefaultParams
	ld a, (xsp + 10)
	extz wa
	call Part_ValidateVoiceChannel
	cpdi8 0x287a, 0
	jr z, BmDrEdit_ValidateVoice_ProcessState
	ldb l, 0xff
	jr BmDrEdit_ValidateVoice_Epilog

BmDrEdit_ValidateVoice_ProcessState:
	ldw_d16 xiz, 0x28af
	ldw_d16 xwa, 9830
	ldw_erp WA, 0xfa
	call SeqVoice_ValidateAndProcessState
	stda16 0x28af, xiz
	stw_erp WA, 0xfa
	stda16 9830, xwa
	ldw (xsp + 4), 0x1
	ld xwa, (xsp + 6)
	ldw (xwa), 0x0
	cpdi16 0x287f, 1
	jr z, BmDrEdit_TrackValidateRet

BmDrEdit_ValidateVoice_SkipSections:
	ldb_d8 a, 0x288e
	extz wa
	ld xbc, (xsp + 6)
	ld bc, (xbc)
	call SeqData_SkipSections
	ld xwa, (xsp + 6)
	ld (xwa), hl
	cpdi8 0x287a, 0
	jr nz, BmDrEdit_TrackValidateRet
	incm 1, (xsp + 4)
	call SeqTrack_ProcessControlBytes
	cpdi8 0x287a, 0
	jr nz, BmDrEdit_TrackValidateRet
	ld wa, (xsp + 4)
	cpda16 xwa, 0x287f
	jr nz, BmDrEdit_ValidateVoice_SkipSections

BmDrEdit_TrackValidateRet:
	ldb_d8 l, 0x288e

BmDrEdit_ValidateVoice_Epilog:
	pop xiz
	inc 8, xsp
	ret

BmDrEdit_SyncChannelAndGetPos:
	dec 2, xsp
	ldmm16 0x287f, 0x2744
	calr BmDrEdit_CheckAndSelectChannel
	ldb_d8 a, 0x2965
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
	stdi8 0x287a, 0
	calr BmDrEdit_SyncChannelAndGetPos
	cpdi8 0x287a, 0
	ret nz
	stda16 0x276a, xhl
	stdi8 0x276c, 0
	ldmm16 0x276e, 0x28af
	ldw_d16 xwa, 9830
	stb_d8 0x2770, a
	ret

BmDrEdit_LoadAlternatePosition:
	stdi8 0x287a, 0
	calr BmDrEdit_SyncChannelAndGetPos
	cpdi8 0x287a, 0
	ret nz
	stda16 0x275e, xhl
	stdi8 0x2760, 0
	ret

BmDrEdit_CopyEventDataBetweenParts:
	lda xsp, (xsp - 10)
	pushw_erp 0xfa
	ld (xsp + 10), a
	calr BmDrEdit_SaveSongPosition
	ldw_d16 xwa, 0x28af
	ldw_d16 xbc, 9830
	ld (xsp + 8), wa
	ld (xsp + 6), bc
	call SeqData_SkipToNextEvent
	ldmw2 (xsp + 4), 0x28af
	ldmw2 (xsp + 2), 0x2666

BmDrEdit_CopyEventLoop:
	ld wa, (xsp + 4)
	ld bc, (xsp + 2)
	calr PartCtrl_ReadByteExtended
	ldb_erp L, 0xfb
	stb_erp E, 0xfb
	extz de
	ld wa, (xsp + 8)
	ld bc, (xsp + 6)
	calr PartCtrl_WriteByte_ZeroExtended
	cp_erpb 0xfb, 0x82
	jr z, BmDrEdit_FinalizePartTransfer
	cp_erpb 0xfb, 0x84
	jr z, BmDrEdit_FinalizePartTransfer
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 6)
	calr PartCtrl_ReadWordWithBoundsCheck
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 2)
	calr PartCtrl_ReadWordWithBoundsCheck
	jr BmDrEdit_CopyEventLoop

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
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	lds hl, 0
	popw_erp 0xfa
	lda xsp, (xsp + 10)
	ret

BmDrEdit_DeleteNoteAtCursor:
	push xiz
	bitda 7, 0x295c
	jr nz, BmDrEdit_DeleteNote_PopIzRet
	bitda 0, 0x295f
	jr z, BmDrEdit_DeleteNote_PopIzRet
	ldb_d8 a, 0x2965
	inc 1, a
	extz wa
	calr BmDrEdit_CopyEventDataBetweenParts
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_DeleteNote_EndOfTrack
	cp l, 0x84
	jr nz, BmDrEdit_DeleteNote_CheckStep

BmDrEdit_DeleteNote_EndOfTrack:
	stdi8 0x2760, 0
	jr NoteEdit_FinalizeAndRefreshDisplay

BmDrEdit_DeleteNote_CheckStep:
	cp l, 0x81
	jr nz, BmDrEdit_DeleteNote_ReadNextEvent
	incdi16 1, 0x275e
	jr NoteEdit_FinalizeAndRefreshDisplay

BmDrEdit_DeleteNote_ReadNextEvent:
	ldw_d16 xwa, 0x28af
	ldw_erp WA, 0xfa
	ldw_d16 xiz, 9830
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stb_d8 0x2760, l
	stw_erp WA, 0xfa
	stda16 0x28af, xwa
	stda16 9830, xiz

NoteEdit_FinalizeAndRefreshDisplay:
	resda 0, 0x295f
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	calr NoteEdit_UpdateScrollAndDisplay

BmDrEdit_DeleteNote_PopIzRet:
	pop xiz
	ret

BmDrEdit_ScanChannelEvents:
	dec 4, xsp
	pushw iz
	calr BmDrEdit_SaveEditState
	ldw_d16 xwa, 0x2744
	stda16 0x27b2, xwa
	ldmm16 0x287f, 0x2744
	lds iz, 0
	ldw (xsp + 2), 0x0

BmDrEdit_ScanChannel_SelectLoop:
	calr BmDrEdit_CheckAndSelectChannel
	ldb_d8 a, 0x2965
	inc 1, a
	bitda 2, 0x287b
	jr z, BmDrEdit_ScanChannel_UseChannel
	ld a, l

BmDrEdit_ScanChannel_UseChannel:
	extz wa
	extz hl
	lda xde, (xsp + 4)
	ld bc, hl
	calr BmDrEdit_ValidateAndProcessVoice
	lda_d16 xwa, 0x27a4
	cpdi8 0x287a, 0
	jr z, BmDrEdit_ScanChannel_StoreAndContinue
	ld xbc, xwa
	ldb_d8 a, 0x27a2
	ldb_erp A, 0xf0
	extz ix
	ld wa, (xsp + 2)

BmDrEdit_ScanChannel_StoreEntry:
	ldb_d8 l, 0x288e
	incm 1, (xsp + 2)
	inc 1, a
	ld iy, iz
	extz xiy
	add xiy, xbc
	ld (xiy), a

BmDrEdit_ScanChannel_NextSlot:
	inc 1, iz
	cp iz, ix
	jr nc, BmDrEdit_ScanChannel_RestoreAndReturn
	cps l, 1
	jr z, BmDrEdit_ScanChannel_StoreEntry
	ld de, iz
	extz xde
	add xde, xbc
	ld (xde), 0x0
	dec 1, l
	jr BmDrEdit_ScanChannel_NextSlot

BmDrEdit_ScanChannel_StoreAndContinue:
	incm 1, (xsp + 2)
	ld xbc, xwa
	ld de, iz
	extz xde
	add xde, xwa
	ld wa, (xsp + 2)
	ld (xde), a
	ldb_d8 e, 0x27a2
	extz de

BmDrEdit_ScanChannel_FillRemaining:
	inc 1, iz
	cp iz, de
	jr c, BmDrEdit_ScanChannel_AdvanceSong

BmDrEdit_ScanChannel_RestoreAndReturn:
	calr BmDrEdit_RestoreEditState
	stdi8 0x287a, 0
	popw iz
	inc 4, xsp
	ret

BmDrEdit_ScanChannel_AdvanceSong:
	cps l, 1
	jr nz, BmDrEdit_ScanChannel_ClearSlot
	incdi16 1, 0x287f
	jrl BmDrEdit_ScanChannel_SelectLoop

BmDrEdit_ScanChannel_ClearSlot:
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld (xwa), 0x0
	dec 1, l
	jr BmDrEdit_ScanChannel_FillRemaining

BmDrEdit_BuildVoiceList:
	ldw_d16 xbc, 0x2744
	subda16 xbc, 0x27b2
	inc 1, bc
	ld h, c
	lds ix, 0
	ldb l, 0x0
	lda_d16 xde, 0x27a4
	lds wa, 0
	jr BmDrEdit_BuildVoice_SearchLoop

BmDrEdit_BuildVoice_IncrementAndSearch:
	inc 1, ix
	inc 1, l
	inc 1, wa

BmDrEdit_BuildVoice_SearchLoop:
	ld bc, wa
	extz xbc
	add xbc, xde
	cp (xbc), h
	jr nz, BmDrEdit_BuildVoice_IncrementAndSearch
	ldw_d16 xbc, 0x2782
	add bc, ix
	mul bc, 0x60
	ldb_d8 a, 0x2784
	extz wa
	add bc, wa
	stda16 0x279a, xbc
	ret

BmDrEdit_BuildVoice_NullReturn:
	ret

BmDrEdit_FindNextPageEntry:
	ldw_d16 xhl, 0x2744
	subda16 xhl, 0x27b2
	inc 1, l
	ldb e, 0x0
	lda_d16 xbc, 0x27a4

BmDrEdit_FindNextPage_ScanLoop:
	ld a, e
	extz wa
	extz xwa
	add xwa, xbc
	inc 1, e
	cp (xwa), l
	jr nz, BmDrEdit_FindNextPage_CheckBound
	ldb l, 0x0
	ld a, e
	extz wa
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, BmDrEdit_FindNextNonZeroEntry
	ldb l, 0x0
	ret

BmDrEdit_FindNextPage_CheckBound:
	cpda8 e, 0x27a2
	jr c, BmDrEdit_FindNextPage_ScanLoop
	ldb l, 0xff
	ret

BmDrEdit_FindNextPage_SkipZero:
	inc 1, e
	inc 1, l
	cpda8 e, 0x27a2
	jr c, BmDrEdit_FindNextNonZeroEntry
	ldb l, 0xff
	jr BmDrEdit_FindNextPage_Return

BmDrEdit_FindNextNonZeroEntry:
	ld a, e
	extz wa
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, BmDrEdit_FindNextPage_SkipZero

BmDrEdit_FindNextPage_Return:
	ret

BmDrEdit_AdjustScrollToView:
	dec 4, xsp
	bitda 0, 0x2742
	jr nz, NoteEditSy_ScrollComplete_Return
	ldmm8 0x27ca, 0x2798

BmDrEdit_ScrollAdjustLoop:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupScrollRegion
	ldb_d8 c, 0x2962
	ldb_d8 a, 0x2798
	cp c, (xsp + 2)
	jr nc, BmDrEdit_ScrollAdjust_CheckUpper
	ld c, a
	cps a, 0
	jr z, NoteEditSy_ScrollComplete_Return
	dec 1, c
	stb_d8 0x2798, c
	jr BmDrEdit_ScrollAdjustLoop

BmDrEdit_ScrollAdjust_CheckUpper:
	cp c, (xsp)
	jr ule, BmDrEdit_ScrollAdjust_CompareAndUpdate
	ld c, a
	cp a, 0x9
	jr nc, NoteEditSy_ScrollComplete_Return
	inc 1, c
	stb_d8 0x2798, c
	jr BmDrEdit_ScrollAdjustLoop

BmDrEdit_ScrollAdjust_CompareAndUpdate:
	ldb_d8 a, 0x27ca
	cpda8 a, 0x2798
	jr z, NoteEditSy_ScrollComplete_Return
	call NoteEditSy_UpdateChordDisplay

NoteEditSy_ScrollComplete_Return:
	inc 4, xsp
	ret

BmDrEdit_CountMeasuresInit:
	pushw_erp 0xfa
	stdi8 0x287a, 0
	calr BmDrEdit_SaveEditState
	calr BmDrEdit_ReadNoteDataFields
	ldb_erp L, 0xfb
	inc1b_erp 0xfb
	cpdi8 0x287a, 0
	jr z, BmDrEdit_CountInit_ValidateAndInsert
	ldw wa, 0xb5
	call SeqData_SetErrorCode

BmDrEdit_CountInit_ValidateAndInsert:
	calr BmDrEdit_CountMeasuresAndValidate
	inc1b_erp 0xfb
	stb_erp A, 0xfb
	extz wa
	ldw_d16 xbc, 0x2772
	cp wa, bc
	jr c, BmDrEdit_RestoreEditRet
	stb_erp A, 0xfb
	sub a, c
	inc 1, a
	ldb_erp A, 0xfb
	extz wa
	stda16 0x2772, xwa
	cps wa, 0
	jr z, BmDrEdit_RestoreEditRet

BmDrEdit_CountInit_InsertLoop:
	calr EditChannel_LoadVoiceParams
	calr BmDrEdit_InsertStepEntry
	cpdi8 0x287a, 0
	jr z, BmDrEdit_CountInit_DecrementLoop
	ldw wa, 0xcd
	call SeqData_SetErrorCode
	stdi8 0x287a, 255
	jr BmDrEdit_RestoreEditRet

BmDrEdit_CountInit_DecrementLoop:
	ldw_d16 xwa, 0x2772
	dec 1, wa
	stda16 0x2772, xwa
	cps wa, 0
	jr nz, BmDrEdit_CountInit_InsertLoop

BmDrEdit_RestoreEditRet:
	calr BmDrEdit_RestoreEditState
	popw_erp 0xfa
	ret

BmDrEdit_CheckAndAdvancePage:
	ldb_d8 a, 0x27a2
	dec 1, a
	extz wa
	lda_d16 xbc, 0x27a4
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, BmDrEdit_AdvancePage_IncrementBeat
	incdi16 1, 0x2744
	stdi16 0x2782, 0
	jr BmDrEdit_AdvancePage_CalcOffset

BmDrEdit_AdvancePage_IncrementBeat:
	incdi16 1, 0x2782

BmDrEdit_AdvancePage_CalcOffset:
	ldw_d16 xbc, 0x279a
	ldb_d8 a, 0x2774
	mul a, 0x60
	sub bc, wa
	stb_d8 0x2784, c
	ret

BmDrEdit_ProcessVoiceSection:
	lda xsp, (xsp - 10)
	ld (xsp), xde
	ld (xsp + 4), xbc
	ld (xsp + 8), a
	call SeqVoice_SetDefaultParams
	stdi8 0x287a, 0
	bitda 2, 0x287b
	jr nz, BmDrEdit_ProcessVoice_WithState
	ldb_d8 c, 1075
	extz bc
	ldw_d16 xwa, 3299
	extz xwa
	div xwa, xbc
	ld bc, wa
	ld xde, (xsp + 4)
	ld (xde), bc
	ldb_d8 c, 1075
	extz bc
	ldw_d16 xwa, 3299
	extz xwa
	div xwa, xbc
	stw_erp BC, 0xe2
	ld xwa, (xsp)
	ld (xwa), bc
	incm 1, (xde)
	ldb_d8 l, 1075
	jr BmDrEdit_ProcessVoice_Epilog

BmDrEdit_ProcessVoice_WithState:
	mrdb5 0x8f, 0x08, 0x19, 0x8d, 0x28
	call SeqVoice_ValidateAndProcessState
	ldb_d8 l, 0x288e
	ld xwa, (xsp)
	ldmw2 (xwa), 0xce3
	ld xwa, (xsp + 4)
	ldw (xwa), 0x1
	jr BmDrEdit_ProcessVoice_CompareAndLoop

BmDrEdit_ProcessVoice_SubtractAndContinue:
	ld xwa, (xsp)
	sub (xwa), bc
	ld xwa, (xsp + 4)
	incm 1, (xwa)
	call SeqTrack_ProcessControlBytes
	ldb_d8 l, 0x288e

BmDrEdit_ProcessVoice_CompareAndLoop:
	ld c, l
	extz bc
	ld xwa, (xsp)
	cp (xwa), bc
	jr nc, BmDrEdit_ProcessVoice_SubtractAndContinue

BmDrEdit_ProcessVoice_Epilog:
	lda xsp, (xsp + 10)
	ret

BmDrEdit_InsertMultiSongSteps:
	dec 4, xsp
	ldmm16 3299, 0x2772
	ldmm16 0x275e, 0x2772

BmDrEdit_MultiSong_SelectAndProcess:
	calr BmDrEdit_CheckAndSelectChannel
	extz hl
	lda xbc, (xsp + 2)
	lda xde, (xsp)
	ld wa, hl
	calr BmDrEdit_ProcessVoiceSection
	ldw_d16 xwa, 0x2744
	cp wa, (xsp + 2)
	jr z, BmDrEdit_MultiSong_Return
	cpw (xsp), 0x0
	jr z, BmDrEdit_MultiSong_CalcRemaining
	ld wa, (xsp)
	sub l, a

BmDrEdit_MultiSong_CalcRemaining:
	extz hl
	stda16 0x2772, xhl

BmDrEdit_MultiSong_InsertLoop:
	calr EditChannel_LoadVoiceParams
	calr BmDrEdit_InsertStepEntry
	cpdi8 0x287a, 0
	jr nz, BmDrEdit_MultiSong_Return
	incdi16 1, 0x275e
	ldw_d16 xwa, 0x2772
	dec 1, wa
	stda16 0x2772, xwa
	cps wa, 0
	jr nz, BmDrEdit_MultiSong_InsertLoop
	ldmm16 3299, 0x275e
	jr BmDrEdit_MultiSong_SelectAndProcess

BmDrEdit_MultiSong_Return:
	inc 4, xsp
	ret

NoteEdit_SendScrollCmds:
	bitda 0, 0x2742
	jr nz, BmDrEdit_SendScrollCmds_DrumMode
	jr BmDrEdit_SendScrollCmds_MelodicNoteOff

BmDrEdit_SendScrollCmds_MelodicNoteOff:
	bitda 0, 0x295f
	jr nz, BmDrEdit_SendScrollCmds_MelodicNoteOn
	call NoteEditSy_SendScrollCmd8
	jr BmDrEdit_SendScrollCmds_CommonMelodicEnd

BmDrEdit_SendScrollCmds_MelodicNoteOn:
	call NoteEditSy_SendScrollCmd3
	call NoteEditSy_SendGateCmd
	call NoteEditSy_SendScrollCmd5

BmDrEdit_SendScrollCmds_CommonMelodicEnd:
	call NoteEditSy_SendScrollCmd0
	call NoteEditSy_SendScrollCmd1
	call NoteEditSy_SendScrollCmd2
	jp NoteEditSy_SendModeScrollCmd

BmDrEdit_SendScrollCmds_DrumMode:
	bitda 0, 0x295f
	jr nz, BmDrEdit_SendScrollCmds_DrumNoteOn
	call NoteEditSy_SendVelocityCmd
	jr BmDrEdit_SendScrollCmds_CommonDrumEnd

BmDrEdit_SendScrollCmds_DrumNoteOn:
	call NoteEditSy_SendScrollCmd3
	call NoteEditSy_SendGateCmd

BmDrEdit_SendScrollCmds_CommonDrumEnd:
	call NoteEditSy_SendScrollCmd0
	call NoteEditSy_SendScrollCmd1
	call NoteEditSy_SendScrollCmd2
	jp NoteEditSy_SendModeScrollCmd

NoteEdit_UpdateScrollAndDisplay:
	ldb_d8 a, 0x2774
	mul a, 0x60
	cpdm16 0x279a, xwa
	ret nc
	jrl NoteEditSy_UpdateAllWidgets
	sub a, c
	bitda 0, 0x2742
	jr z, BmDrEdit_UpdateDisplay_MelodicOffset
	ldb c, 0xb
	sub c, a
	stb_d8 0x27cc, c
	ret

BmDrEdit_UpdateDisplay_MelodicOffset:
	ld c, a
	stb_d8 0x27cc, a
	cpdi8 0x2798, 0
	ret nz
	inc 3, c
	stb_d8 0x27cc, c
	ret

BmDrEdit_ByteData_CompoundWidgetUpdate:
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
	stb_d8 0x2969, l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stb_d8 0x296a, l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stb_d8 0x296b, l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stb_d8 0x296c, l
	calr BmDrEdit_ClearAndScanToEnd
	ldb_d8 a, 0x2965
	inc 1, a
	extz wa
	calr BmDrEdit_CopyEventDataBetweenParts
	calr BmDrEdit_SeekForwardToEvent
	cpdi8 0x287a, 0
	jr nz, BmDrEdit_ReadSeqStoreParams_Error
	stdi8 0x2967, 144
	ldmm8 0x2968, 0x2784
	calr BmDrEdit_SaveSongPosition
	ldb_d8 a, 0x2965
	inc 1, a
	extz wa
	ld xbc, 0x2967
	lds de, 6
	calr BmDrEdit_ApplyVelocityChange
	calr BmDrEdit_CountMeasuresInit
	cpdi8 0x287a, 0
	ret z

BmDrEdit_ReadSeqStoreParams_Error:
	calr BmDrEdit_RefreshDisplayState
	ret

BmDrEdit_CalcBeatMeasure:
	ldw_d16 xwa, 0x279a
	extz xwa
	div wa, 0x60
	stdi8 9688, 0
	stda16 0x2772, xwa
	cps wa, 0
	jr z, BmDrEdit_ComputeMeasureAndBeat
	lds de, 1
	stdi8 9688, 1
	lda_d16 xbc, 0x27a4

BmDrEdit_CalcBeatMeasure_ScanLoop:
	ld wa, de
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, BmDrEdit_CalcBeatMeasure_IncrementCount
	stdi8 9688, 0

BmDrEdit_CalcBeatMeasure_IncrementCount:
	inc 1, de
	ldw_d16 xwa, 0x2772
	dec 1, wa
	stda16 0x2772, xwa
	cps wa, 0
	jr z, BmDrEdit_ComputeMeasureAndBeat
	incdi8 1, 9688
	jr BmDrEdit_CalcBeatMeasure_ScanLoop

BmDrEdit_ComputeMeasureAndBeat:
	ldb_d8 a, 9688
	extz wa
	stda16 0x2782, xwa
	ldw_d16 xwa, 0x279a
	extz xwa
	div wa, 0x60
	stw_erp WA, 0xe2
	stb_d8 0x2784, a
	jr BmDrEdit_CalcSongPosition

BmDrEdit_CalcSongPosition:
	ldw_d16 xbc, 0x279a
	extz xbc
	div bc, 0x60
	stdi8 9688, 0
	stda16 0x2772, xbc
	cps bc, 0
	jr z, BmDrEdit_CalcSongPos_Store
	lds de, 1
	stdi8 9688, 0
	lda_d16 xbc, 0x27a4

BmDrEdit_CalcSongPos_ScanLoop:
	ld wa, de
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, BmDrEdit_CalcSongPos_IncrementCount
	incdi8 1, 9688

BmDrEdit_CalcSongPos_IncrementCount:
	inc 1, de
	ldw_d16 xwa, 0x2772
	dec 1, wa
	stda16 0x2772, xwa
	cps wa, 0
	jr nz, BmDrEdit_CalcSongPos_ScanLoop

BmDrEdit_CalcSongPos_Store:
	ldw_d16 xbc, 0x27b2
	ldb_d8 a, 9688
	extz wa
	add bc, wa
	stda16 0x2744, xbc
	ret

BmDrEdit_CalcEventPosition:
	ldw_d16 xde, 0x2744
	subda16 xde, 0x27b2
	inc 1, de
	lds hl, 0
	lda_d16 xbc, 0x27a4
	ldb_d8 a, 0x27a2
	extz wa
	jr BmDrEdit_CalcEventPos_CompareLoop

BmDrEdit_CalcEventPos_IncrementSearch:
	inc 1, hl
	cp hl, wa
	jr ge, BmDrEdit_CalcEventPos_InitBackward

BmDrEdit_CalcEventPos_CompareLoop:
	cpb_sri_rm E, 0x07, 0xe4, 0xec
	jr nz, BmDrEdit_CalcEventPos_IncrementSearch

BmDrEdit_CalcEventPos_InitBackward:
	lds de, 0
	dec 1, hl
	cpib_sri 0x07, 0xe4, 0xec, 0x00
	jr z, BmDrEdit_CalcEventPos_CheckZero
	jr BmDrEdit_StoreEventPositionAndReturn

BmDrEdit_CalcEventPos_BackwardLoop:
	inc 1, de
	sub hl, 0x1
	jr lt, BmDrEdit_StoreEventPositionAndReturn

BmDrEdit_CalcEventPos_CheckZero:
	cpib_sri 0x07, 0xe4, 0xec, 0x00
	jr z, BmDrEdit_CalcEventPos_BackwardLoop

BmDrEdit_StoreEventPositionAndReturn:
	stda16 0x2782, xde
	ret

BmDrEdit_SyncSeekCheck:
	push xiz
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl
	cpdi8 0x287a, 0
	jr z, BmDrEdit_InitScanEventPositions
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jrl nz, BmDrEdit_SyncSeek_PopIzRet
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl

BmDrEdit_InitScanEventPositions:
	ldib_erp 0xfb, 0
	stda16 0x275e, xiz
	stdi8 0x2760, 0
	cpdi16 0x2782, 0
	jr z, BmDrEdit_SyncSeek_ReadNext
	stdi16 0x2772, 0

BmDrEdit_SyncSeek_ReadLoop:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_SyncSeek_EndOfTrack
	cp l, 0x84
	jr nz, BmDrEdit_SyncSeek_CheckStep

BmDrEdit_SyncSeek_EndOfTrack:
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jr nz, BmDrEdit_SyncSeek_PopIzRet
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl
	ldib_erp 0xfb, 1
	jr BmDrEdit_InitScanEventPositions

BmDrEdit_SyncSeek_CheckRetry:
	cpib_erp 0xfb, 1
	jr z, BmDrEdit_InitScanEventPositions

BmDrEdit_SyncSeek_SkipAndRead:
	call SeqData_SkipToNextEvent

BmDrEdit_SyncSeek_ReadNext:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_SyncSeek_EndOfTrackAlt
	cp l, 0x84
	jr nz, BmDrEdit_SyncSeek_CheckStepMark

BmDrEdit_SyncSeek_EndOfTrackAlt:
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jr z, BmDrEdit_SyncSeek_ResyncChannel
	jr BmDrEdit_SyncSeek_PopIzRet

BmDrEdit_SyncSeek_CheckStep:
	cp l, 0x81
	jr nz, BmDrEdit_SyncSeek_SkipEvent
	ldw_d16 xwa, 0x2772
	inc 1, wa
	stda16 0x2772, xwa
	cpda16 xwa, 0x2782
	jr nc, BmDrEdit_SyncSeek_CheckRetry

BmDrEdit_SyncSeek_SkipEvent:
	call SeqData_SkipToNextEvent
	jr BmDrEdit_SyncSeek_ReadLoop

BmDrEdit_SyncSeek_ResyncChannel:
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl
	ldib_erp 0xfb, 1
	jrl BmDrEdit_InitScanEventPositions

BmDrEdit_SyncSeek_CheckFlagAndClear:
	cpib_erp 0xfb, 0
	jrl nz, BmDrEdit_InitScanEventPositions
	calr BmDrEdit_ClearAndScanToEnd
	jr BmDrEdit_SyncSeek_StorePosition

BmDrEdit_SyncSeek_CheckStepMark:
	cp l, 0x81
	jr nz, BmDrEdit_SyncSeek_AdvanceAndCompare

BmDrEdit_SyncSeek_StorePosition:
	ldw_d16 xwa, 0x2782
	adddm16 0x275e, xwa
	ldmm8 0x2760, 0x2784

BmDrEdit_SyncSeek_PopIzRet:
	pop xiz
	ret

BmDrEdit_SyncSeek_AdvanceAndCompare:
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cpda8 l, 0x2784
	jr nc, BmDrEdit_SyncSeek_CheckFlagAndClear
	jr BmDrEdit_SyncSeek_SkipAndRead

BmDrEdit_SeekForwardToEvent:
	push xiz
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl
	cpdi8 0x287a, 0
	jrl z, BmDrEdit_StoreStreamPos
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jrl z, BmDrEdit_SyncStorePos
	jrl BmDrEdit_PopIzRet

BmDrEdit_SeekFwd_CheckStep:
	cp l, 0x81
	jr nz, BmDrEdit_AdvanceAndCheckBeat
	jrl BmDrEdit_CalcStorePos

BmDrEdit_SeekFwd_InitCountLoop:
	stdi16 0x2772, 0
	ldib_erp 0xfb, 0

BmDrEdit_SeekFwd_ReadLoop:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_SeekFwd_EndOfTrack
	cp l, 0x84
	jr nz, BmDrEdit_SeekFwd_CheckStepMark

BmDrEdit_SeekFwd_EndOfTrack:
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jr z, BmDrEdit_SeekFwd_ResyncChannel
	jrl BmDrEdit_PopIzRet

BmDrEdit_SeekFwd_CheckRetryFlag:
	cpib_erp 0xfb, 1
	jr z, BmDrEdit_StoreStreamPos

BmDrEdit_AdvanceAndCheckBeat:
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cpda8 l, 0x2784
	jrl ugt, BmDrEdit_SeekFwd_ClearAndCalcStore
	call SeqData_SkipToNextEvent
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_SeekFwd_EndOfTrackAlt
	cp l, 0x84
	jrl nz, BmDrEdit_SeekFwd_CheckStepAdvance

BmDrEdit_SeekFwd_EndOfTrackAlt:
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jr z, BmDrEdit_SyncStorePos
	jrl BmDrEdit_PopIzRet

BmDrEdit_SeekFwd_CheckStepMark:
	cp l, 0x81
	jr nz, BmDrEdit_SkipEventAndContinue
	ldw_d16 xwa, 0x2772
	inc 1, wa
	stda16 0x2772, xwa
	cpda16 xwa, 0x2782
	jr c, BmDrEdit_SkipEventAndContinue
	call SeqData_SkipToNextEvent
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_SeekFwd_EndOfTrackResync
	cp l, 0x84
	jr nz, BmDrEdit_SeekFwd_CheckStepJump

BmDrEdit_SeekFwd_EndOfTrackResync:
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jr nz, BmDrEdit_PopIzRet

BmDrEdit_SeekFwd_ResyncChannel:
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl
	ldib_erp 0xfb, 1
	jr BmDrEdit_StoreStreamPos

BmDrEdit_SeekFwd_CheckStepJump:
	cp l, 0x81
	jr nz, BmDrEdit_SeekFwd_CheckRetryFlag
	jr BmDrEdit_CalcStorePos

BmDrEdit_SkipEventAndContinue:
	call SeqData_SkipToNextEvent
	jrl BmDrEdit_SeekFwd_ReadLoop

BmDrEdit_SyncStorePos:
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl

BmDrEdit_StoreStreamPos:
	stda16 0x275e, xiz
	stdi8 0x2760, 0
	cpdi16 0x2782, 0
	jrl nz, BmDrEdit_SeekFwd_InitCountLoop
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_SeekFwd_EndOfTrackResyncAlt
	cp l, 0x84
	jrl nz, BmDrEdit_SeekFwd_CheckStep

BmDrEdit_SeekFwd_EndOfTrackResyncAlt:
	calr BmDrEdit_SeekToPartVoice
	cpdi8 0x287a, 0
	jr z, BmDrEdit_SyncStorePos
	jr BmDrEdit_PopIzRet

BmDrEdit_SeekFwd_CheckStepAdvance:
	cp l, 0x81
	jrl nz, BmDrEdit_AdvanceAndCheckBeat
	jr BmDrEdit_CalcStorePos

BmDrEdit_SeekFwd_ClearAndCalcStore:
	calr BmDrEdit_ClearAndScanToEnd

BmDrEdit_CalcStorePos:
	ldw_d16 xwa, 0x2782
	adddm16 0x275e, xwa
	ldmm8 0x2760, 0x2784

BmDrEdit_PopIzRet:
	pop xiz
	ret

BmDrEdit_PrepareSecondaryNoteDisplay:
	dec 4, xsp
	pushw iz
	bitda 0, 0x295f
	jrl z, BmDrEdit_SecondaryNote_PopIzReturn
	calr BmDrEdit_SaveEditState
	ldmm16 0x280c, 0x276a
	ldb_d8 a, 0x276c
	extz wa
	stda16 0x280e, xwa
	ldmm16 0x2810, 0x276e
	ldb_d8 a, 0x2770
	extz wa
	stda16 0x2812, xwa
	ldmm16 0x2814, 0x275e
	ldb_d8 a, 0x2760
	extz wa
	stda16 0x2816, xwa
	ldmm16 0x2818, 0x28af
	ldmm16 0x281a, 9830
	call SeqData_ReadNextByte
	and l, 0xf0
	cp l, 0x90
	jr nz, BmDrEdit_RestoreReturn
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	extz hl
	stda16 0x2816, xhl
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	stb_d8 0x281c, l
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 2)
	calr BmDrEdit_SetupScrollRegion
	ldb_d8 a, 0x281c
	cp a, (xsp + 4)
	jr c, BmDrEdit_RestoreReturn
	cp a, (xsp + 2)
	jr ugt, BmDrEdit_RestoreReturn
	mrdb5 0x8f, 0x04, 0x19, 0x26, 0x28
	mrdb5 0x8f, 0x02, 0x19, 0x28, 0x28
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ldb_erp L, 0xf8
	extz iz
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	extz hl
	and iz, 0x7f
	and hl, 0x7f
	ld wa, hl
	mul wa, 0x60
	ld hl, wa
	add hl, iz
	stda16 0x2820, xhl
	call NoteEditSy_SendWidgetCmdC

BmDrEdit_RestoreReturn:
	calr BmDrEdit_RestoreEditState

BmDrEdit_SecondaryNote_PopIzReturn:
	popw iz
	inc 4, xsp
	ret

BmDrEdit_EnterPlayMode:
	ldb_d8 a, 0x8d36
	cpda8 a, 0x8d37
	ret z
	ldb_d8 a, 0x28b1
	stb_d8 0x283c, a
	setda 0, 0x28b1
	cpdi8 0x283a, 0
	jr nz, BmDrEdit_EnterPlay_RestoreSettings
	ldmm_sd24w 0xec, 0xff, 0x00, 0x9e, 0xf1
	jr BmDrEdit_EnterPlay_CheckAudio

BmDrEdit_EnterPlay_RestoreSettings:
	ldmm16 0xf19e, 0x2963

BmDrEdit_EnterPlay_CheckAudio:
	call Audio_CheckSubsystemReady
	ldw_d16 xwa, 0x2744
	stda16 9500, xwa
	cpda16 xwa, 9502
	jr ule, BmDrEdit_EnterPlay_UpdateProgress
	stda16 9502, xwa

BmDrEdit_EnterPlay_UpdateProgress:
	ldmm16 9832, 9500
	cpdi16 9832, 1
	jr z, BmDrEdit_EnterPlay_AllocAndInit
	setda 3, 0x28a7

BmDrEdit_EnterPlay_AllocAndInit:
	jp SeqPlay_AllocBuffersAndInit

BmDrEdit_ExitPlayMode:
	ldb_d8 a, 0x8d36
	cpda8 a, 0x8d37
	ret z
	ldmm8 0x28b1, 0x283c
	stdi16 0xf19e, 0
	call Audio_CheckSubsystemReady
	call AccWrap_PlayModeDispatch
	ldb_d8 a, 0x8d38
	cp a, 0x95
	jr z, BmDrEdit_ExitPlay_RestoreSequencer
	cp a, 0x98
	ret nz

BmDrEdit_ExitPlay_RestoreSequencer:
	ldmm16 3407, 0x2963
	call SeqVoice_FindSingleActive
	ret

