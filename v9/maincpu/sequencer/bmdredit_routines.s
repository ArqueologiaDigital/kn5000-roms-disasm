; =============================================================================
; Bitmap Drum Editor
; =============================================================================
;
; Bitmap drum editor: stream positioning, sequence display,
; and voice allocation UI. Provides the graphical drum pattern
; editing interface.
; =============================================================================

BmDrEdit_AdvanceStreamPos:
	ld wa, (0x0210a6:24)
	cp wa, 0xff
	jr nc, BmDrEdit_AdvanceStreamWrap
	inc 1, wa
	ld (0x0210a6:24), wa
	ret

BmDrEdit_AdvanceStreamWrap:
	ld bc, (0x0210a4:24)
	dec 1, bc
	extz xbc
	sll xbc, 8
	lda xwa, (xbc + 4)
	lda xde, (0x0b0000:24)
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
	ld (0x0210a4:24), wa
	ldw (0x0210a6:24), 0x0005
	ret

BmDrEdit_ScanForwardInit:
	pushw iz
	ld wa, (0x27fe:16)
	ld (0x27f6:16), wa
	ld wa, (0x2800:16)
	ld (0x27f8:16), wa
	ld wa, (0x2802:16)
	ld (0x27fa:16), wa
	ld wa, (0x2804:16)
	ld (0x27fc:16), wa
	ldmmw_dd24 0xa0, 0x10, 0x02, 0xfe, 0x27
	ldmmw_dd24 0xa2, 0x10, 0x02, 0x00, 0x28
	ldmmw_dd24 0xa4, 0x10, 0x02, 0x02, 0x28
	ldmmw_dd24 0xa6, 0x10, 0x02, 0x04, 0x28
	ldmmb_dd24 0xa8, 0x10, 0x02, 0x22, 0x28
	ldmmb_dd24 0xaa, 0x10, 0x02, 0x24, 0x28
	lds iz, 0
	ld a, (0x2774:16)
	extz wa
	cps wa, 0
	jrl ule, BmDrEdit_ScanForward_Done

BmDrEdit_ScanForwardLoop:
	ld bc, (0x0210a6:24)
	extz xbc
	ld wa, (0x0210a4:24)
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
	incw 1, (0x0210a0:24)
	jr BmDrEdit_ScanForward_NextByte

BmDrEdit_ScanForward_CheckNote:
	and a, 0xf0
	cp a, 0x90
	jr nz, BmDrEdit_ScanForward_NextByte
	calr BmDrEdit_AdvanceStreamPos
	ld bc, (0x0210a6:24)
	extz xbc
	ld wa, (0x0210a4:24)
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld (0x0210a2:24), wa
	calr BmDrEdit_AdvanceStreamPos
	ld bc, (0x0210a6:24)
	extz xbc
	ld wa, (0x0210a4:24)
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	ld (0x2806:16), a
	cp a, (0x0210a8:24)
	jr c, BmDrEdit_ScanForward_NextByte
	cp a, (0x0210aa:24)
	call_24 ule, BmDrEdit_RenderNoteBlock

BmDrEdit_ScanForward_NextByte:
	calr BmDrEdit_AdvanceStreamPos
	ld bc, (0x0210a6:24)
	extz xbc
	ld wa, (0x0210a4:24)
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	bit 7, a
	jr z, BmDrEdit_ScanForward_NextByte
	ld a, (0x2774:16)
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
	ld a, (0x2774:16)
	extz wa
	cps wa, 0
	jrl ule, BmDrEdit_ScanBackward_Done

BmDrEdit_ScanBackwardLoop:
	ld bc, (0x0210a6:24)
	extz xbc
	ld wa, (0x0210a4:24)
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
	incw 1, (0x27fe:16)
	jr BmDrEdit_ScanBackward_NextByte

BmDrEdit_ScanBackward_CheckNote:
	and a, 0xf0
	cp a, 0x90
	jr nz, BmDrEdit_ScanBackward_NextByte
	ld wa, (0x2802:16)
	cp wa, (0x2766:16)
	jr nz, BmDrEdit_ScanBackward_ReadNoteParams
	ld wa, (0x2804:16)
	cp wa, (0x2768:16)
	jr z, BmDrEdit_ScanBackward_NextByte

BmDrEdit_ScanBackward_ReadNoteParams:
	calr BmDrEdit_AdvanceStreamPos
	ld bc, (0x0210a6:24)
	extz xbc
	ld wa, (0x0210a4:24)
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld (0x2800:16), wa
	calr BmDrEdit_AdvanceStreamPos
	ld bc, (0x0210a6:24)
	extz xbc
	ld wa, (0x0210a4:24)
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	ld (0x2806:16), a
	cp a, (0x0210a8:24)
	jr c, BmDrEdit_ScanBackward_NextByte
	cp a, (0x0210aa:24)
	call_24 ule, BmDrEdit_RenderNoteBlock

BmDrEdit_ScanBackward_NextByte:
	calr BmDrEdit_AdvanceStreamPos
	ld bc, (0x0210a6:24)
	extz xbc
	ld wa, (0x0210a4:24)
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	bit 7, a
	jr z, BmDrEdit_ScanBackward_NextByte
	ld a, (0x2774:16)
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
	ld bc, (0x0210a0:24)
	mul bc, 0x60
	add bc, (0x0210a2:24)
	ld wa, (0x27f6:16)
	mul wa, 0x60
	add wa, (0x27f8:16)
	sub bc, wa
	ld (0x2808:16), bc
	ld a, (0x0210a8:24)
	sub (0x2806:16), a
	call GetTitleNow
	cp xhl, 0x1a00095
	jr nz, BmDrEdit_CalcNotePos_VerticalMode
	cp (0x2798:16), 0
	jr nz, BmDrEdit_CalcNotePos_ReadFields
	inc 3, (0x2806:16)
	jr BmDrEdit_CalcNotePos_ReadFields

BmDrEdit_CalcNotePos_VerticalMode:
	ldb a, 0xb
	sub a, (0x2806:16)
	ld (0x2806:16), a

BmDrEdit_CalcNotePos_ReadFields:
	calr BmDrEdit_AdvanceStreamPos
	calr BmDrEdit_AdvanceStreamPos
	ld bc, (0x0210a6:24)
	extz xbc
	ld wa, (0x0210a4:24)
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, xbc
	ld xbc, 0xb0000
	add xbc, xwa
	ld a, (xbc)
	ldb_erp A, 0xfb
	calr BmDrEdit_AdvanceStreamPos
	ld bc, (0x0210a6:24)
	extz xbc
	ld wa, (0x0210a4:24)
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
	ld (0x280a:16), bc
	ld l, (0x2774:16)
	mul l, 0x60
	dec 1, hl
	ld wa, (0x2808:16)
	ld de, wa
	add de, bc
	cp de, hl
	jr ule, BmDrEdit_CalcNotePos_ClampSize
	sub hl, wa
	ld (0x280a:16), hl

BmDrEdit_CalcNotePos_ClampSize:
	popw_erp 0xfa
	ret

BmDrEdit_RenderHorizontal:
	ld wa, (0x2808:16)
	srl wa, 2
	add wa, 0x16
	ld (0x27ba:16), wa
	ld wa, (0x280a:16)
	srl wa, 2
	add wa, (0x27ba:16)
	ld (0x27bc:16), wa
	ld a, (0x2806:16)
	extz wa
	add wa, wa
	lda xbc, (NakaInst_NO_OPERATION_0x19A:24)
	ldmm_sriw 0x07, 0xe4, 0xe0, 0xbe, 0x27
	ld wa, (0x27be:16)
	inc 3, wa
	ld (0x27c0:16), wa
	ret

BmDrEdit_RenderVertical:
	ld wa, (0x2808:16)
	srl wa, 2
	add wa, 0x5b
	ld (0x27ba:16), wa
	ld wa, (0x280a:16)
	srl wa, 2
	add wa, (0x27ba:16)
	ld (0x27bc:16), wa
	ld a, (0x2806:16)
	extz wa
	add wa, wa
	lda xbc, (NakaInst_NO_OPERATION_0x1D4:24)
	ldmm_sriw 0x07, 0xe4, 0xe0, 0xbe, 0x27
	ld wa, (0x27be:16)
	inc 3, wa
	ld (0x27c0:16), wa
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
	ld wa, (0x281e:16)
	srl wa, 2
	add wa, 0x16
	ld (0x27c2:16), wa
	ld wa, (0x0210b2:24)
	srl wa, 2
	add wa, (0x27c2:16)
	ld (0x27c4:16), wa
	ld a, (0x0210b0:24)
	extz wa
	add wa, wa
	lda xbc, (NakaInst_NO_OPERATION_0x19A:24)
	ldmm_sriw 0x07, 0xe4, 0xe0, 0xc6, 0x27
	ld wa, (0x27c6:16)
	inc 3, wa
	ld (0x27c8:16), wa
	ret

BmDrEdit_RenderSecondaryVert:
	ld wa, (0x281e:16)
	srl wa, 2
	add wa, 0x5b
	ld (0x27c2:16), wa
	ld wa, (0x0210b2:24)
	srl wa, 2
	add wa, (0x27c2:16)
	ld (0x27c4:16), wa
	ld a, (0x0210b0:24)
	extz wa
	add wa, wa
	lda xbc, (NakaInst_NO_OPERATION_0x1D4:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	ld (0x27c6:16), wa
	inc 3, wa
	ld (0x27c8:16), wa
	decw 2, (0x27c6:16)
	incw 2, (0x27c8:16)
	ret

BmDrEdit_CalcSecondaryPosition:
	ld bc, (0x2814:16)
	mul bc, 0x60
	add bc, (0x2816:16)
	ld wa, (0x280c:16)
	mul wa, 0x60
	add wa, (0x280e:16)
	sub bc, wa
	ld (0x281e:16), bc
	ld a, (0x2826:16)
	sub (0x0210b0:24), a
	call GetTitleNow
	cp xhl, 0x1a00095
	jr nz, BmDrEdit_CalcSecondaryPos_Vert
	cp (0x2798:16), 0
	jr nz, BmDrEdit_CalcSecondaryPos_ClampSize
	inc 3, (0x0210b0:24)
	jr BmDrEdit_CalcSecondaryPos_ClampSize

BmDrEdit_CalcSecondaryPos_Vert:
	ldb a, 0xb
	sub a, (0x0210b0:24)
	ld (0x0210b0:24), a

BmDrEdit_CalcSecondaryPos_ClampSize:
	ld e, (0x2774:16)
	mul e, 0x60
	dec 1, de
	ld wa, (0x281e:16)
	ld bc, wa
	add bc, (0x0210b2:24)
	cp bc, de
	ret ule
	sub de, wa
	ld (0x0210b2:24), de
	ret

BmDrEdit_InitDisplayParams:
	ldw (0x2794:16), 48
	ldw (0x2796:16), 48
	ldw (0x2790:16), 38
	ld (0x2798:16), 5
	ldw (0x279e:16), 40
	ldw (0x27a0:16), 5
	ld (0x278a:16), 100
	ret

BmDrEdit_TempoAnimTimer:
	ld a, (0xe372:16)
	cp a, 0x1e
	jr ule, BmDrEdit_TempoAnimTimer_Reset
	inc 1, a
	ld (0xe372:16), a
	ret

BmDrEdit_TempoAnimTimer_Reset:
	ld (0xe372:16), 0
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
	ld a, (0x8d38:16)
	cp a, 0x95
	jr z, BmDrEdit_CheckTempoData_ReadyToProcess
	cp a, 0x98
	ret nz

BmDrEdit_CheckTempoData_ReadyToProcess:
	bit 7, (0x295c:16)
	ret nz
	cpw (0xf231:16), 0
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
	ld (0x2960:16), l
	call TempoRingBuf_ReadByte
	ld (0x2961:16), l
	call TempoRingBuf_ReadByte
	cp (0x2961:16), 0
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
	res 0, (0x295f:16)
	ldmm8 0x2962, 0x2960
	calr BmDrEdit_AdjustScrollToView
	calr BmDrEdit_InsertNotesFromSlots
	calr BmDrEdit_CountMeasuresInit
	cp (0x287a:16), 0
	jr z, BmDrEdit_ClearSlotAndRedraw

BmDrEdit_ClearNoteAndRefresh:
	res 0, (0x295f:16)
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
	ld a, (0x295c:16)
	bit 7, a
	ret z
	cp a, 0x80
	ret z
	dec 1, a
	ld (0x295c:16), a
	ret

BmDrEdit_DelayAExpired:
	cp (0x295c:16), 128
	ret nz
	ld (0x295c:16), 0
	ld a, (0x295d:16)
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
	ld a, (0x295e:16)
	bit 7, a
	ret z
	cp a, 0x80
	ret z
	dec 1, a
	ld (0x295e:16), a
	ret

BmDrEdit_DelayBExpired:
	cp (0x295e:16), 128
	ret nz
	ld (0x295e:16), 0
	jrl BmDrEdit_DelayAction_PlayClick

BmDrEdit_DelayReturn:
	ret

BmDrEdit_AllocateNoteSlot:
	ldw ix, 0x8
	bit 0, (0x2742:16)
	jr z, BmDrEdit_AllocateNote_Search
	lds ix, 1

BmDrEdit_AllocateNote_Search:
	lds iy, 0
	cps ix, 0
	ret ule
	lda xde, (0x2746:16)

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
	res 0, (0x8d88:16)
	ldw wa, 0xf
	call SoundCtrl_SaveAndSendCmd_EE
	set 4, (0x28ad:16)
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
	bit 0, (0x2742:16)
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
	bit 7, (0x295c:16)
	jr z, BmDrEdit_ScrollRight
	cp (0x295d:16), 0
	jr z, BmDrEdit_ScrollRight
	ldw hl, 0xffff
	ret

BmDrEdit_ScrollRight:
	ld wa, (0x2744:16)
	cp wa, 0x3e7
	jr nc, BmDrEdit_ScrollRight_Done
	inc 1, wa
	ld (0x2744:16), wa
	calr BmDrEdit_ScrollReset

BmDrEdit_ScrollRight_Done:
	lds hl, 0
	ret

BmDrEdit_CheckScrollBusyAlt:
	bit 7, (0x295c:16)
	jr z, BmDrEdit_ScrollLeft
	cp (0x295d:16), 0
	jr z, BmDrEdit_ScrollLeft
	ldw hl, 0xffff
	ret

BmDrEdit_ScrollLeft:
	ld wa, (0x2744:16)
	cps wa, 1
	jr ule, BmDrEdit_ScrollLeft_Done
	dec 1, wa
	ld (0x2744:16), wa
	calr BmDrEdit_ScrollReset

BmDrEdit_ScrollLeft_Done:
	lds hl, 0
	ret

BmDrEdit_ScrollReset:
	call NoteEditSy_SendScrollCmd0
	ldw (0x279a:16), 0
	ldw (0x2782:16), 0
	ld (0x2784:16), 0
	ld (0x295c:16), 130
	ld (0x295d:16), 0
	ret

BmDrEdit_PitchScrollUp_Check:
	bit 7, (0x295c:16)
	jr z, BmDrEdit_PitchScrollUp
	cp (0x295d:16), 1
	ret nz

BmDrEdit_PitchScrollUp:
	ld a, (0x2784:16)
	cp a, 0x5f
	jrl nc, BmDrEdit_PitchScrollOverflow
	inc 1, a
	ld (0x2784:16), a
	call NoteEditSy_SendScrollCmd2
	calr NoteEditSy_CallFarRoutine
	calr BmDrEdit_BuildVoice_NullReturn
	jrl BmDrEdit_SetFeedbackTimer

BmDrEdit_PitchScrollDown_Check:
	bit 7, (0x295c:16)
	jr z, BmDrEdit_PitchScrollDown
	cp (0x295d:16), 1
	ret nz

BmDrEdit_PitchScrollDown:
	ld a, (0x2784:16)
	cps a, 0
	jrl z, BmDrEdit_PitchWrapToEnd
	dec 1, a
	ld (0x2784:16), a
	call NoteEditSy_SendScrollCmd2
	calr NoteEditSy_CallFarRoutine
	calr BmDrEdit_BuildVoice_NullReturn
	jrl BmDrEdit_SetFeedbackTimer

BmDrEdit_VelocityUp_Check:
	bit 7, (0x295c:16)
	jr z, BmDrEdit_VelocityUp_Dispatch
	cp (0x295d:16), 2
	ret nz

BmDrEdit_VelocityUp_Dispatch:
	bit 0, (0x295f:16)
	ret z
	bit 0, (0x2742:16)
	jr nz, BmDrEdit_DecrementVelocity
	jr BmDrEdit_IncrementVelocity

BmDrEdit_VelocityDown_Check:
	bit 7, (0x295c:16)
	jr z, BmDrEdit_VelocityDown_Dispatch
	cp (0x295d:16), 2
	ret nz

BmDrEdit_VelocityDown_Dispatch:
	bit 0, (0x295f:16)
	ret z
	bit 0, (0x2742:16)
	jr nz, BmDrEdit_IncrementVelocity
	jr BmDrEdit_DecrementVelocity

BmDrEdit_IncrementVelocity:
	ld a, (0x2786:16)
	cp a, 0x7f
	ret nc
	inc 1, a
	ld (0x2786:16), a
	bit 0, (0x2742:16)
	call_24 nz, BmDrEdit_DrumVoiceUp
	calr BmDrEdit_UpdateVelocityDisplay
	call NoteEditSy_SendScrollCmd3
	calr BmDrEdit_NullReturn
	ld (0x295c:16), 131
	ld (0x295d:16), 2
	ret

BmDrEdit_DecrementVelocity:
	ld a, (0x2786:16)
	cps a, 1
	ret z
	dec 1, a
	ld (0x2786:16), a
	bit 0, (0x2742:16)
	call_24 nz, BmDrEdit_DrumVoiceDown
	calr BmDrEdit_UpdateVelocityDisplay
	call NoteEditSy_SendScrollCmd3
	calr BmDrEdit_NullReturn
	ld (0x295c:16), 131
	ld (0x295d:16), 2
	ret

BmDrEdit_GateOrVelocityUp:
	bit 7, (0x295c:16)
	ret nz
	bit 0, (0x295f:16)
	jr nz, BmDrEdit_IncrementGateTime
	bit 0, (0x2742:16)
	ret z
	calr BmDrEdit_IncrementVelocityValue
	ret

BmDrEdit_GateOrVelocityDown:
	bit 7, (0x295c:16)
	ret nz
	bit 0, (0x295f:16)
	jr nz, BmDrEdit_DecrementGateTime
	bit 0, (0x2742:16)
	ret z
	calr BmDrEdit_DecrementVelocityValue
	ret

BmDrEdit_IncrementGateTime:
	ld a, (0x2788:16)
	cp a, 0x7f
	ret nc
	inc 1, a
	ld (0x2788:16), a
	call NoteEditSy_SendGateCmd
	jrl BmDrEdit_UpdateGateDisplay

BmDrEdit_DecrementGateTime:
	ld a, (0x2788:16)
	cps a, 1
	ret z
	dec 1, a
	ld (0x2788:16), a
	call NoteEditSy_SendGateCmd
	jrl BmDrEdit_UpdateGateDisplay

BmDrEdit_IncrementVelocityValue:
	ld a, (0x278a:16)
	cp a, 0x7f
	ret nc
	inc 1, a
	ld (0x278a:16), a
	jp NoteEditSy_SendVelocityCmd

BmDrEdit_DecrementVelocityValue:
	ld a, (0x278a:16)
	cps a, 1
	ret z
	dec 1, a
	ld (0x278a:16), a
	jp NoteEditSy_SendVelocityCmd

BmDrEdit_DurationUp_Check:
	bit 7, (0x295c:16)
	jr z, BmDrEdit_DurationUp_Dispatch
	cp (0x295d:16), 3
	ret nz

BmDrEdit_DurationUp_Dispatch:
	jr BmDrEdit_IncrementDuration

BmDrEdit_DurationDown_Check:
	bit 7, (0x295c:16)
	jr z, BmDrEdit_DurationDown_Dispatch
	cp (0x295d:16), 3
	ret nz

BmDrEdit_DurationDown_Dispatch:
	jr BmDrEdit_DecrementDuration

BmDrEdit_IncrementDuration:
	bit 0, (0x295f:16)
	jr z, BmDrEdit_IncrementDuration_Global
	ld wa, (0x278c:16)
	cp wa, 0x2fff
	ret nc
	inc 1, wa
	ld (0x278c:16), wa
	calr BmDrEdit_CalcDurationPosition
	call NoteEditSy_SendScrollCmd5
	calr BmDrEdit_NullReturn
	ld (0x295c:16), 131
	ld (0x295d:16), 3
	ret

BmDrEdit_IncrementDuration_Global:
	ld wa, (0x278e:16)
	cp wa, 0x2fff
	ret nc
	inc 1, wa
	ld (0x278e:16), wa
	jp NoteEditSy_SendScrollCmd8

BmDrEdit_DecrementDuration:
	bit 0, (0x295f:16)
	jr z, BmDrEdit_DecrementDuration_Global
	ld wa, (0x278c:16)
	cps wa, 0
	jr nz, BmDrEdit_DecrementDuration_Clamp
	ldw (0x278c:16), 1
	jr BmDrEdit_DecrementDuration_Update

BmDrEdit_DecrementDuration_Clamp:
	cps wa, 1
	ret ule
	dec 1, wa
	ld (0x278c:16), wa

BmDrEdit_DecrementDuration_Update:
	calr BmDrEdit_CalcDurationPosition
	call NoteEditSy_SendScrollCmd5
	calr BmDrEdit_NullReturn
	ld (0x295c:16), 131
	ld (0x295d:16), 3
	ret

BmDrEdit_DecrementDuration_Global:
	ld wa, (0x278e:16)
	cps wa, 0
	jr nz, BmDrEdit_DecrementDuration_GlobalClamp
	ldw (0x278e:16), 1
	jr BmDrEdit_DecrementDuration_Send

BmDrEdit_DecrementDuration_GlobalClamp:
	cps wa, 1
	ret z
	dec 1, wa
	ld (0x278e:16), wa

BmDrEdit_DecrementDuration_Send:
	jp NoteEditSy_SendScrollCmd8

BmDrEdit_ModeScrollUp:
	bit 7, (0x295c:16)
	ret nz
	ld wa, (0x2792:16)
	cp wa, 0x60
	ret nc
	inc 1, wa
	ld (0x2792:16), wa
	jp NoteEditSy_SendModeScrollCmd

BmDrEdit_ModeScrollDown:
	bit 7, (0x295c:16)
	ret nz
	ld wa, (0x2792:16)
	cps wa, 0
	jr nz, BmDrEdit_ModeScrollDown_Clamp
	ldw (0x2792:16), 48
	jr BmDrEdit_ModeScrollDown_Send

BmDrEdit_ModeScrollDown_Clamp:
	cps wa, 1
	ret ule
	dec 1, wa
	ld (0x2792:16), wa

BmDrEdit_ModeScrollDown_Send:
	jp NoteEditSy_SendModeScrollCmd

BmDrEdit_SetFeedbackTimer:
	ld (0x295c:16), 133
	ld (0x295d:16), 1
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
	ld (0x287a:16), 0

BmDrEdit_ScanToEnd_Loop:
	ld wa, (9830:16)
	cps wa, 5
	jr ule, BmDrEdit_ScanToEnd_CheckNextSong
	dec 1, wa
	ld (9830:16), wa
	jr BmDrEdit_ScanToEnd_CheckEndMark

BmDrEdit_ScanToEnd_CheckNextSong:
	ld wa, (0x28af:16)
	call PartCtrl_ReadWord_Off1
	cps hl, 0
	jr nz, BmDrEdit_ScanToEnd_AdvanceSong
	ld (0x287a:16), 255
	ret

BmDrEdit_ScanToEnd_AdvanceSong:
	ld (0x28af:16), hl
	ldw (9830:16), 255

BmDrEdit_ScanToEnd_CheckEndMark:
	call SeqData_ReadNextByte
	bit 7, l
	jr z, BmDrEdit_ScanToEnd_Loop
	ret

BmDrEdit_LoadAlternateState:
	ldmm16 0x275e, 0x276a
	ldmm8 0x2760, 0x276c
	ldmm16 0x28af, 0x276e
	ld a, (0x2770:16)
	extz wa
	ld (9830:16), wa
	ret

BmDrEdit_LoadAlternateAndCountNotes:
	calr BmDrEdit_LoadAlternateState
	ldw (0x2772:16), 0

BmDrEdit_CountNotesLoop:
	call SeqData_ReadNextByte
	cp l, 0x82
	ret z
	cp l, 0x84
	ret z
	cp l, 0x81
	jr nz, BmDrEdit_CountNotesLoop_Retry
	ld bc, (0x2772:16)
	inc 1, bc
	ld (0x2772:16), bc
	ld a, (0x2774:16)
	extz wa
	cp bc, wa
	ret ugt

BmDrEdit_CountNotesLoop_Retry:
	call SeqData_SkipToNextEvent
	jr BmDrEdit_CountNotesLoop

BmDrEdit_CheckChannelActive:
	ldb e, 0x0
	lda xbc, (0xf1a0:16)

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
	andda16_24 xbc, (0xffec)
	jr z, BmDrEdit_CheckChannelActive_None
	ld (0x2776:16), 1
	ret

BmDrEdit_CheckChannelActive_Next:
	inc 1, e
	cp e, 0x10
	jr c, BmDrEdit_CheckChannelActive_Loop

BmDrEdit_CheckChannelActive_None:
	ld (0x2776:16), 0
	ret

BmDrEdit_SelectActiveChannel:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0
	lda xbc, (0xf1a0:16)

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
	andda16_24 xbc, (0xffec)
	jr z, BmDrEdit_SelectChannel_NotFound
	bit 0, (0x2776:16)
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
	ld (3414:16), a
	set 0, (3412:16)
	set 2, (0x287b:16)
	stb_erp L, 0xfb
	inc 1, l
	jr BmDrEdit_SelectChannel_Done

BmDrEdit_SelectChannel_NextCh:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, BmDrEdit_SelectChannel_Loop

BmDrEdit_SelectChannel_NotFound:
	res 0, (3412:16)
	res 2, (0x287b:16)
	ldb l, 0x0

BmDrEdit_SelectChannel_Done:
	popw_erp 0xfa
	ret

BmDrEdit_AlignDisplayGrid:
	lds de, 0
	ld wa, (0x279a:16)
	cps wa, 0
	jr c, BmDrEdit_AlignGrid_Store
	ld bc, (0x2792:16)

BmDrEdit_AlignGrid_AccumLoop:
	add de, bc
	cp de, wa
	jr ule, BmDrEdit_AlignGrid_AccumLoop

BmDrEdit_AlignGrid_Store:
	ld (0x279a:16), de
	ret

BmDrEdit_CompareVelocity:
	push xiz
	bit 0, (0x2742:16)
	jr z, BmDrEdit_CompareVelocity_Equal
	ld iz, (0x28af:16)
	ld wa, (9830:16)
	ldw_erp WA, 0xfa
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ld (0x28af:16), iz
	stw_erp WA, 0xfa
	ld (9830:16), wa
	cp l, (0x2786:16)
	jr z, BmDrEdit_CompareVelocity_Equal
	ldb l, 0xff
	jr BmDrEdit_CompareVelocity_Return

BmDrEdit_CompareVelocity_Equal:
	ldb l, 0x0

BmDrEdit_CompareVelocity_Return:
	pop xiz
	ret

BmDrEdit_SaveSongPosition:
	ld a, (0x2965:16)
	inc 1, a
	extz wa
	ld hl, (0x28af:16)
	ld de, (9830:16)
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de
	ret

BmDrEdit_ReadEventAtPosition:
	push xiz
	ld iz, (0x28af:16)
	ld wa, (9830:16)
	ldw_erp WA, 0xfa
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ld (0x2760:16), l
	ld (0x28af:16), iz
	stw_erp WA, 0xfa
	ld (9830:16), wa
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
	ld a, (0x295f:16)
	res 1, a
	res 4, a
	ld (0x295f:16), a
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_WalkTrack_EndOfTrack
	cp l, 0x84
	jr z, BmDrEdit_WalkTrack_EndOfTrack
	cp l, 0x81
	jr nz, BmDrEdit_WalkTrack_ProcessEvent
	ld bc, (0x275e:16)
	inc 1, bc
	ld (0x275e:16), bc
	ld a, (0x2774:16)
	extz wa
	sub bc, (0x276a:16)
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
	set 1, (0x295f:16)
	ld (0x2760:16), 0
	ret

BmDrEdit_WalkTrack_CheckNoteCount:
	cp l, 0x81
	jr nz, BmDrEdit_WalkTrack_CheckNoteOn
	ld bc, (0x275e:16)
	inc 1, bc
	ld (0x275e:16), bc
	ld a, (0x2774:16)
	extz wa
	sub bc, (0x276a:16)
	cp bc, wa
	jr c, BmDrEdit_WalkTrack_CheckNoteOn

BmDrEdit_WalkTrack_CountExceeded:
	set 4, (0x295f:16)
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
	ld a, (0x2760:16)
	extz wa
	add (xde), wa
	ldmw2 (xbc), 0x276a
	ld xde, xbc
	ld wa, (xde)
	mul wa, 0x60
	ld (xde), wa
	ld a, (0x276c:16)
	extz wa
	add (xbc), wa
	ret

BmDrEdit_SetupAndWalkToNote:
	dec 4, xsp
	pushw_erp 0xfa
	res 0, (0x295f:16)
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 2)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub (xsp + 4), wa
	ld wa, (xsp + 4)
	cp wa, (0x279a:16)
	jr nz, BmDrEdit_SetupAndWalkDone
	call SeqData_ReadNextByte
	and l, 0xf0
	cp l, 0x90
	jr nz, BmDrEdit_SetupAndWalkDone
	calr BmDrEdit_CompareVelocity
	cps l, 0
	jr nz, BmDrEdit_SetupAndWalkDone
	set 0, (0x295f:16)
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ld (0x2786:16), l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ld (0x2788:16), l
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
	ld (0x278c:16), hl
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
	lda xbc, (0x2746:16)
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
	bit 0, (0x2742:16)
	jr z, BmDrEdit_FindNote_SetupLoop
	lds iy, 1

BmDrEdit_FindNote_SetupLoop:
	lds iz, 0
	cps iy, 0
	jr ule, BmDrEdit_FindNote_NotFound
	lda xix, (0x2746:16)

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
	cp c, (0x2960:16)
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
	lda xbc, (0x2747:16)
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
	lda xbc, (0x2746:16)

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
	ld wa, (0x279a:16)
	extz xwa
	div wa, 0x60
	stw_erp WA, 0xe2
	ld (0x2760:16), a
	ld wa, (0x279a:16)
	extz xwa
	div wa, 0x60
	ld (0x275e:16), wa
	ld wa, (0x276a:16)
	add (0x275e:16), wa
	ret

BmDrEdit_ByteData_NoteCoordTable:
	.byte 0xd1, 0x5e, 0x27, 0x19, 0x78, 0x27, 0xc1, 0x60, 0x27, 0x19, 0x7a, 0x27, 0xd1, 0xaf, 0x28, 0x19, 0x7c, 0x27, 0xd1, 0x66, 0x26, 0x19, 0x7e, 0x27
	ret
	.byte 0xd1, 0x78, 0x27, 0x19, 0x5e, 0x27, 0xc1, 0x7a, 0x27, 0x19, 0x60, 0x27, 0xd1, 0x7c, 0x27, 0x19, 0xaf, 0x28, 0xd1, 0x7e, 0x27, 0x19, 0x66, 0x26
	ret
	.byte 0xf1, 0x5c, 0x29, 0xcf
	ret	nz
	ld	wa, (10130:16)
	cp	wa, 96
	ret	nc
	inc	1, wa
	ld	(10130:16), wa
	jp	16017633
	.byte 0xf1, 0x5c, 0x29, 0xcf
	ret	nz
	ld	wa, (10130:16)
	cps	wa, 0
	jr	nz, 8
	ldw	(10130:16), 48
	jr	10
	cps	wa, 1
	ret	ule
	dec	1, wa
	ld	(10130:16), wa
	call	16017633
	ret

BmDrEdit_ChordScrollUp_Check:
	bit 7, (0x295c:16)
	jr z, BmDrEdit_ChordScrollUp
	cp (0x295d:16), 4
	ret nz

BmDrEdit_ChordScrollUp:
	ld a, (0x2798:16)
	cp a, 0x9
	ret nc
	inc 1, a
	ld (0x2798:16), a
	call NoteEditSy_UpdateChordDisplay
	ld (0x295c:16), 129
	ld (0x295d:16), 4
	ret

BmDrEdit_ChordScrollDown_Check:
	bit 7, (0x295c:16)
	jr z, BmDrEdit_ChordScrollDown
	cp (0x295d:16), 4
	ret nz

BmDrEdit_ChordScrollDown:
	ld a, (0x2798:16)
	cps a, 0
	ret z
	dec 1, a
	ld (0x2798:16), a
	call NoteEditSy_UpdateChordDisplay
	ld (0x295c:16), 129
	ld (0x295d:16), 4
	ret

BmDrEdit_NullReturn:
	ret

BmDrEdit_PitchWrapToEnd:
	ld wa, (0x2782:16)
	cps wa, 0
	jr z, BmDrEdit_PitchWrapPrevPage
	ld (0x2784:16), 95
	ld wa, (0x2782:16)
	dec 1, wa
	ld (0x2782:16), wa
	jr BmDrEdit_PitchWrap_UpdateDisplay

BmDrEdit_PitchWrapPrevPage:
	ld wa, (0x2744:16)
	cp wa, (0x27b2:16)
	jr z, BmDrEdit_PitchWrap_CheckEnd
	calr BmDrEdit_CalcEventPosition
	decw 1, (0x2744:16)
	ld (0x2784:16), 95
	call NoteEditSy_SendScrollCmd0

BmDrEdit_PitchWrap_UpdateDisplay:
	call NoteEditSy_SendScrollCmd2
	call NoteEditSy_SendScrollCmd1
	calr NoteEditSy_CallFarRoutine
	jrl BmDrEdit_SetFeedbackTimer

BmDrEdit_PitchWrap_CheckEnd:
	bit 0, (0x295f:16)
	jrl z, BmDrEdit_NavigatePrevPage
	cps wa, 1
	ret z
	ld (0x295c:16), 0
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
	ld wa, (0x278c:16)
	extz xwa
	div wa, 0x60
	stw_erp WA, 0xe2
	and wa, 0x7f
	extz wa
	call PartCtrl_WriteByte_Indexed
	call SeqData_AdvancePosition
	ld wa, (0x278c:16)
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
	ld l, (0x2788:16)
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
	ld l, (0x2786:16)
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	calr BmDrEdit_RestoreEditState
	jrl BmDrEdit_SendMetronomeNoteOn

BmDrEdit_InsertNoteEvent:
	res 0, (0x295f:16)
	calr BmDrEdit_CalcTrackPosition
	ldmm8 0x2960, 0x2786
	ld a, (0x278a:16)
	ld (0x2961:16), a
	ldmm8 0x2788, 0x278a
	calr BmDrEdit_PlayNoteAndSetDelay
	calr BmDrEdit_WalkEventsOrSetError
	jr BmDrEdit_RefreshAfterInsert

BmDrEdit_SendWidgetCmd:
	bit 0, (0x2742:16)
	ret z
	jp NoteEditSy_SendWidgetCmdE

BmDrEdit_NavigatePrevPage:
	ld wa, (0x2744:16)
	cps wa, 1
	ret ule
	dec 1, wa
	ld (0x2744:16), wa
	calr BmDrEdit_SelectChannelAndLoadPos
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_ScanChannelEvents
	incw 1, (0x2744:16)
	ldw (0x2782:16), 0
	ld (0x2784:16), 0
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
	bit 2, (0x295f:16)
	jr z, BmDrEdit_RefreshAfterInsert_CheckFull
	ldw wa, 0xd0
	call SeqData_SetErrorCode
	jrl BmDrEdit_RefreshDisplayState

BmDrEdit_RefreshAfterInsert_CheckFull:
	ld a, (0x2774:16)
	mul a, 0x60
	cp (0x279a:16), wa
	jrl nc, BmDrEdit_NavigateAndLoadPosition
	calr BmDrEdit_CalcBeatMeasure
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	jrl NoteEdit_UpdateScrollAndDisplay

BmDrEdit_SetupScrollRegion:
	ld xde, xwa
	bit 0, (0x2742:16)
	jr z, BmDrEdit_SetupScrollRegion_MelodicMode
	ld wa, (0x279e:16)
	ld (xde), a
	ld wa, (0x279e:16)
	ld (xbc), a
	addmi8 (xbc), 0xb
	ret

BmDrEdit_SetupScrollRegion_MelodicMode:
	ld a, (0x2798:16)
	extz wa
	add wa, wa
	lda xhl, (WidgetData_DrawbarPositionTable:24)
	ldb_sri A, 0x07, 0xec, 0xe0
	ld (xde), a
	ld a, (0x2798:16)
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
	ld (7504:16), xhl
	ld (7508:16), xhl
	calr NoteEditSy_ScanAndSortEntries
	ldw (0x278e:16), 10
	ldmm16 0x2792, 0x2796
	set 0, (0x2742:16)
	ld (0x2774:16), 7
	ld (0x27a2:16), 8
	jr BmDrEdit_InitCommon

BmDrEdit_InitMelodicMode:
	ldmm16 0x2792, 0x2794
	ldmm16 0x278e, 0x2790
	res 0, (0x2742:16)
	ld (0x2774:16), 10
	ld (0x27a2:16), 11
	jr BmDrEdit_InitCommon

BmDrEdit_InitCommon:
	pushw iz
	cpw (0x2792:16), 0
	jr nz, BmDrEdit_InitCommon_CheckSongActive
	ldw (0x2792:16), 48

BmDrEdit_InitCommon_CheckSongActive:
	ld a, (0x8d36:16)
	cp a, (0x8d37:16)
	jr nz, BmDrEdit_InitCommon_SetupDisplay
	ld a, (0x8d38:16)
	cp a, (0x8d39:16)
	jr z, BmDrEdit_InitCommon_SetupDisplay
	bit 4, (0x28ad:16)
	jr z, BmDrEdit_InitCommon_SetupDisplay
	lds wa, 1
	call UI_PostPartChangeEvent
	res 4, (0x28ad:16)
	res 0, (9834:16)
	jrl BmDrEdit_PopIzAndReturn

BmDrEdit_InitCommon_SetupDisplay:
	set 0, (9834:16)
	set 0, (9954:16)
	call AccWrap_PlayModeDispatch
	set 2, (0x28a7:16)
	ld (0x295c:16), 0
	ld wa, (0x2963:16)
	ld (3407:16), wa
	ldmm16 3409, 0x2963
	ld a, (0x8d39:16)
	cp a, 0x96
	jr z, BmDrEdit_CopyStepCount
	cp a, 0x99
	jr z, BmDrEdit_CopyStepCount
	cp a, 0x94
	jr z, BmDrEdit_SetRecordingFlag
	cp a, 0x97
	jr nz, BmDrEdit_CheckDrumModeEntry

BmDrEdit_SetRecordingFlag:
	set 0, (0x8d88:16)
	jr BmDrEdit_ReadVoiceBitAndCopy

BmDrEdit_CheckDrumModeEntry:
	bit 0, (0x2742:16)
	jrl z, BmDrEdit_FlagDisplayUpdate
	ld a, (0x295b:16)
	bit 0, a
	jrl z, BmDrEdit_FlagDisplayUpdate
	res 0, a
	ld (0x295b:16), a

BmDrEdit_ReadVoiceBitAndCopy:
	ld c, (0x2965:16)
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
	ldw (0x2744:16), 1
	cpw (0xf231:16), 0
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
	ld c, (0x2965:16)
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	ld c, (0x2965:16)
	inc 1, c
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteVoiceWord
	ld c, (0x2965:16)
	inc 1, c
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteWord_Indexed
	ld c, (0x2965:16)
	inc 1, c
	extz bc
	lds wa, 0
	lds de, 5
	call Part_WriteByte_Indexed
	ld (0x28af:16), iz
	ldw (9830:16), 5
	calr BmDrEdit_InsertStepEntry
	incw 1, (9830:16)
	calr BmDrEdit_InsertStepEntry

BmDrEdit_InitPlayback:
	calr Metronome_PlayClick
	call TempoRingBuf_Init
	call SeqBuf_Init
	calr BmDrEdit_ClearAllSlotsAlt
	calr BmDrEdit_ClearAllSlots
	calr BmDrEdit_SelectChannelAndLoadPos
	cp (0x287a:16), 0
	jr z, BmDrEdit_ResetAndScanNotes
	ldw (0x2744:16), 1
	calr BmDrEdit_SelectChannelAndLoadPos
	cp (0x287a:16), 0
	jr z, BmDrEdit_ResetAndScanNotes

BmDrEdit_RefreshAndReturn:
	calr BmDrEdit_RefreshDisplayState
	jr BmDrEdit_PopIzAndReturn

BmDrEdit_ResetAndScanNotes:
	ldw (0x279a:16), 0
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_CalcTrackPosition
	calr BmDrEdit_SaveAndFindNote
	calr BmDrEdit_CheckNoteAtPosition
	calr BmDrEdit_SetupAndWalkToNote
	ldw (0x2782:16), 0
	ld (0x2784:16), 0
	calr BmDrEdit_ScanChannelEvents

BmDrEdit_FlagDisplayUpdate:
	call Audio_CheckSubsystemReady
	set 0, (0x27b0:16)

BmDrEdit_PopIzAndReturn:
	popw iz
	ret

BmDrEdit_CleanupDrumMode:
	ldmm16 0x2796, 0x2792
	ld xwa, (7504:16)
	push xwa
	call Free
	inc 4, xsp
	cp (0x8d36:16), 152
	jr z, BmDrEdit_SkipPartSelect
	res 0, (9954:16)
	call PartSelect_UpdateDisplayState

BmDrEdit_SkipPartSelect:
	jr BmDrEdit_CleanupCommon

BmDrEdit_CleanupMelodicMode:
	cp (0x8d36:16), 149
	jr z, BmDrEdit_SkipMelodicPartSelect
	res 0, (9954:16)
	call PartSelect_UpdateDisplayState

BmDrEdit_SkipMelodicPartSelect:
	ldmm16 0x2794, 0x2792
	ldmm16 0x2790, 0x278e
	jr BmDrEdit_CleanupCommon

BmDrEdit_CleanupCommon:
	res 2, (0x28a7:16)
	ld (0x295c:16), 0
	ld wa, (3407:16)
	ordm16_24 (0xffec), xwa
	ldw (3407:16), 0
	ldw (3409:16), 0
	ldmm16 9832, 0x2744
	call Audio_CheckSubsystemReady
	res 0, (0x27b0:16)
	calr BmDrEdit_ClearAllSlotsAlt
	jrl BmDrEdit_ClearAllSlots

BmDrEdit_InsertNotesFromSlots:
	pushw iz
	bit 0, (0x2742:16)
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
	lda xbc, (0x2746:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cps a, 0
	jr z, BmDrEdit_InsertNotesFromSlots_Next
	ld (0x2960:16), a
	lds wa, 2
	add wa, de
	extz xwa
	add xwa, xbc
	mrib4 0x80, 0x19, 0x61, 0x29
	calr BmDrEdit_PrepareAndInsertNote
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jrl z, BmDrEdit_CalcBeatFromGridPos
	ldw wa, 0xcf
	call SeqData_SetErrorCode
	jrl BmDrEdit_RefreshDisplayState

BmDrEdit_WalkToGridPosition:
	dec 4, xsp
	calr BmDrEdit_LoadAlternateState
	cpw (0x279a:16), 0
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
	cp wa, (0x279a:16)
	jr ugt, BmDrEdit_CleanupReturn

BmDrEdit_WalkToGrid_SkipEvent:
	call SeqData_SkipToNextEvent

BmDrEdit_WalkToGrid_ReadNext:
	call SeqData_ReadNextByte
	cp l, 0x81
	jr nz, BmDrEdit_WalkToGrid_CheckEvent
	ld (0x2760:16), 0
	incw 1, (0x275e:16)
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cp wa, (0x279a:16)
	jr ule, BmDrEdit_WalkToGrid_SkipEvent

BmDrEdit_CleanupReturn:
	inc 4, xsp
	ret

BmDrEdit_HandleDelayExpired_Rescan:
	calr Metronome_PlayClick
	calr BmDrEdit_SelectChannelAndLoadPos
	cp (0x287a:16), 0
	jr z, BmDrEdit_Rescan_LoadAlternate
	calr BmDrEdit_SeekToPartVoice
	cp (0x287a:16), 0
	jr nz, BmDrEdit_Rescan_RefreshDisplay
	calr BmDrEdit_SelectChannelAndLoadPos

BmDrEdit_Rescan_LoadAlternate:
	calr BmDrEdit_ScanChannelEvents
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_ValidateAndInsertSteps
	cp (0x287a:16), 0
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
	ld (0x287a:16), 0
	calr BmDrEdit_SaveEditState
	cp (0x287a:16), 0
	jr z, BmDrEdit_ValidateSteps_CheckCount
	ldw wa, 0xb6
	call SeqData_SetErrorCode

BmDrEdit_ValidateSteps_CheckCount:
	calr BmDrEdit_CountMeasuresAndValidate
	cpw (0x2772:16), 0
	ret nz
	ldw (0x2772:16), 2

BmDrEdit_ValidateSteps_InsertLoop:
	calr EditChannel_LoadVoiceParams
	calr BmDrEdit_InsertStepEntry
	cp (0x287a:16), 0
	jr nz, BmDrEdit_ValidateSteps_RestoreState
	ld wa, (0x2772:16)
	dec 1, wa
	ld (0x2772:16), wa
	cps wa, 0
	jr nz, BmDrEdit_ValidateSteps_InsertLoop

BmDrEdit_ValidateSteps_RestoreState:
	jrl BmDrEdit_RestoreEditState

BmDrEdit_SeekToPartVoice:
	ld c, (0x2965:16)
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceWord
	cp hl, 0xffff
	ret z
	ld (0x28af:16), hl
	ldw (9830:16), 5
	cp (0x287a:16), 0
	jr z, BmDrEdit_SeekVoice_CountAndInsert
	ldw wa, 0xb7
	call SeqData_SetErrorCode

BmDrEdit_SeekVoice_CountAndInsert:
	calr BmDrEdit_CountMeasuresAndValidate
	calr BmDrEdit_InsertMultiSongSteps
	cp (0x287a:16), 0
	jr nz, BmDrEdit_SeekVoice_RefreshDisplay
	ld wa, (0x2782:16)
	inc 2, wa
	ld (0x2772:16), wa
	cps wa, 0
	ret z

BmDrEdit_SeekVoice_InsertLoop:
	calr EditChannel_LoadVoiceParams
	calr BmDrEdit_InsertStepEntry
	cp (0x287a:16), 0
	jr z, BmDrEdit_SeekVoice_DecrementLoop

BmDrEdit_SeekVoice_RefreshDisplay:
	jrl BmDrEdit_RefreshDisplayState

BmDrEdit_SeekVoice_DecrementLoop:
	ld wa, (0x2772:16)
	dec 1, wa
	ld (0x2772:16), wa
	cps wa, 0
	jr nz, BmDrEdit_SeekVoice_InsertLoop
	ret

BmDrEdit_CalcTickPosition:
	calr BmDrEdit_CheckAndAdvancePage
	ld bc, (0x2782:16)
	mul bc, 0x60
	ld a, (0x2784:16)
	extz wa
	add bc, wa
	ld (0x279a:16), bc
	ret

BmDrEdit_ReloadChannelAndDisplay:
	calr BmDrEdit_SelectChannelAndLoadPos
	cp (0x287a:16), 0
	jr z, BmDrEdit_ReloadChannel_LoadAndSkip
	calr BmDrEdit_SeekToPartVoice
	cp (0x287a:16), 0
	jr nz, BmDrEdit_ReloadChannel_RefreshDisplay
	calr BmDrEdit_SelectChannelAndLoadPos

BmDrEdit_ReloadChannel_LoadAndSkip:
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_SkipToEventByCount
	cp (0x287a:16), 0
	jr z, BmDrEdit_LoadAndDisplayNotes
	calr BmDrEdit_SeekToPartVoice
	cp (0x287a:16), 0
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
	bit 0, (0x295f:16)
	ret z
	calr BmDrEdit_SendMetronomeNoteOn
	ret

BmDrEdit_NavigateAndLoadPosition:
	calr BmDrEdit_CalcTickPosition
	calr BmDrEdit_SelectChannelAndLoadPos
	cp (0x287a:16), 0
	jr z, BmDrEdit_NavLoad_LoadAndSkip
	calr BmDrEdit_SeekToPartVoice
	cp (0x287a:16), 0
	jr nz, BmDrEdit_NavLoad_RefreshDisplay
	calr BmDrEdit_SelectChannelAndLoadPos

BmDrEdit_NavLoad_LoadAndSkip:
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_SkipToEventByCount
	cp (0x287a:16), 0
	jr z, BmDrEdit_NavigateAndDisplayNotes
	calr BmDrEdit_SeekToPartVoice
	cp (0x287a:16), 0
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
	bit 0, (0x295f:16)
	ret z
	calr BmDrEdit_SendMetronomeNoteOn
	ret

BmDrEdit_SkipToEventByCount:
	ld (0x287a:16), 0
	ld wa, (0x2782:16)
	cps wa, 0
	ret z
	ld (0x2772:16), wa
	cps wa, 0
	ret z

BmDrEdit_SkipToEvent_ReadLoop:
	call SeqData_ReadNextByte
	cp l, 0x81
	jr nz, BmDrEdit_SkipToEvent_EndOfTrack
	decw 1, (0x2772:16)

BmDrEdit_SkipToEvent_SkipAndCheck:
	call SeqData_SkipToNextEvent
	cpw (0x2772:16), 0
	jr nz, BmDrEdit_SkipToEvent_ReadLoop
	ret

BmDrEdit_SkipToEvent_EndOfTrack:
	cp l, 0x82
	jr nz, BmDrEdit_SkipToEvent_SkipAndCheck
	ld (0x287a:16), 255
	ret

BmDrEdit_NavigateToPrevAndDisplay:
	ld wa, (0x2744:16)
	cps wa, 1
	ret ule
	dec 1, wa
	ld (0x2744:16), wa
	calr BmDrEdit_SelectChannelAndLoadPos
	calr BmDrEdit_LoadAlternateState
	calr BmDrEdit_ScanChannelEvents
	incw 1, (0x2744:16)
	ldw (0x2782:16), 0
	ld (0x2784:16), 0
	calr BmDrEdit_LoadAlternatePosition
	calr BmDrEdit_BuildVoiceList
	calr BmDrEdit_SyncSeekCheck
	calr BmDrEdit_SetupAndWalkToNote
	calr NoteEditSy_SendCompoundWidgetUpdate
	calr NoteEdit_UpdateScrollAndDisplay
	call NoteEditSy_SendWidgetCmd0
	jrl NoteEdit_SendScrollCmds

EditChannel_LoadVoiceParams:
	ld c, (0x2965:16)
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadWord_Indexed
	ld (0x28af:16), hl
	ld c, (0x2965:16)
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadByte_Indexed
	ld (9830:16), hl
	ret

BmDrEdit_DelayAction_SetupAndWalk:
	dec 4, xsp
	bit 0, (0x295f:16)
	jr z, BmDrEdit_DelayAction_UpdateDisplay
	calr ReadSeqData_StoreParams
	calr BmDrEdit_SetupAndWalkToNote
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	ld (0x279a:16), wa

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
	bit 0, (0x295f:16)
	jr z, BmDrEdit_DelayAction_UpdateScroll
	calr BmDrEdit_CountMeasuresInit
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jr z, BmDrEdit_ReadNoteData_StoreDuration
	ldw wa, 0xba
	call SeqData_SetErrorCode

BmDrEdit_ReadNoteData_StoreDuration:
	stb_erp L, 0xfb
	popw_erp 0xfa
	ret

BmDrEdit_PitchScrollOverflow:
	ld c, (0x2774:16)
	ld a, c
	extz wa
	mul wa, 0x60
	dec 1, wa
	cp (0x279a:16), wa
	jr c, BmDrEdit_PitchOverflow_CheckNextPage
	mul c, 0x60
	ld (0x279a:16), bc
	bit 0, (0x295f:16)
	jrl z, BmDrEdit_NavigateAndLoadPosition
	calr BmDrEdit_CalcTickPosition
	ld (0x295c:16), 0
	calr ReadSeqData_StoreParams
	jrl BmDrEdit_ReloadChannelAndDisplay

BmDrEdit_PitchOverflow_CheckNextPage:
	calr BmDrEdit_FindNextPageEntry
	cp l, 0xff
	jr z, BmDrEdit_PitchOverflow_IncrementBeat
	extz hl
	ld wa, (0x2782:16)
	cp wa, hl
	jr nc, BmDrEdit_PitchOverflow_NextPage

BmDrEdit_PitchOverflow_IncrementBeat:
	ld (0x2784:16), 0
	incw 1, (0x2782:16)
	jr BmDrEdit_PitchOverflow_UpdateDisplay

BmDrEdit_PitchOverflow_NextPage:
	ldw (0x2782:16), 0
	incw 1, (0x2744:16)
	ld (0x2784:16), 0
	call NoteEditSy_SendScrollCmd0

BmDrEdit_PitchOverflow_UpdateDisplay:
	call NoteEditSy_SendScrollCmd2
	call NoteEditSy_SendScrollCmd1
	calr NoteEditSy_CallFarRoutine
	calr BmDrEdit_SaveEditState
	calr BmDrEdit_SeekForwardToEvent
	calr BmDrEdit_RestoreEditState
	cp (0x287a:16), 0
	jrl nz, BmDrEdit_RefreshDisplayState
	jrl BmDrEdit_SetFeedbackTimer

NoteEditSy_CallFarRoutine:
	jrl BmDrEdit_BuildVoiceList

BmDrEdit_AdjustViewAndInsert:
	dec 4, xsp
	bit 7, (0x295c:16)
	jrl nz, BmDrEdit_AdjustViewReturn
	calr BmDrEdit_SaveEditState
	ldmm16 0x279c, 0x279a
	calr BmDrEdit_AlignDisplayGrid
	ld a, (0x2774:16)
	mul a, 0x60
	cp (0x279a:16), wa
	call_24 c, BmDrEdit_CalcBeatMeasure
	bit 0, (0x295f:16)
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
	cp wa, (0x279a:16)
	jr ule, BmDrEdit_AdjustView_InitAndNavigate
	bit 1, (0x295f:16)
	jr z, BmDrEdit_WalkTrackLoop
	calr BmDrEdit_InsertNoteSequence
	bit 2, (0x295f:16)
	jr nz, BmDrEdit_AdjustView_RefreshDisplay
	jr BmDrEdit_AdjustViewPath

BmDrEdit_WalkTrackLoop:
	calr BmDrEdit_WalkTrackForward
	ld a, (0x295f:16)
	bit 4, a
	jr nz, BmDrEdit_AdjustViewPath
	bit 1, a
	jr z, BmDrEdit_AdjustView_CheckCoords
	calr BmDrEdit_InsertNoteSequence
	bit 2, (0x295f:16)
	jr z, BmDrEdit_AdjustViewPath

BmDrEdit_AdjustView_RefreshDisplay:
	calr BmDrEdit_RefreshDisplayState
	jr BmDrEdit_AdjustViewReturn

BmDrEdit_AdjustView_CheckCoords:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (0x279a:16)
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
	bit 1, (0x295f:16)
	jr z, BmDrEdit_AdvanceToVisibleNote
	jr BmDrEdit_WalkReturn

BmDrEdit_LoadNote_WalkTrack:
	calr BmDrEdit_WalkTrackForward
	bit 1, (0x295f:16)
	jr nz, BmDrEdit_WalkReturn

BmDrEdit_AdvanceToVisibleNote:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cp wa, (0x279c:16)
	jr ugt, BmDrEdit_WalkReturn
	calr BmDrEdit_WalkTrackForward
	bit 1, (0x295f:16)
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
	ld (0x279a:16), wa
	ld a, (0x2774:16)
	mul a, 0x60
	cp (0x279a:16), wa
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
	ld a, (0x2774:16)
	mul a, 0x60
	cp (0x279a:16), wa
	jrl nc, BmDrEdit_NavigateAndLoadPosition
	res 0, (0x295f:16)
	calr BmDrEdit_RestoreEditState
	calr BmDrEdit_CalcBeatMeasure
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	jrl NoteEdit_UpdateScrollAndDisplay

BmDrEdit_SendMetronomeNoteOn:
	calr Metronome_PlayClick
	calr BmDrEdit_BuildNoteOnEvent
	ld (0x295e:16), 134
	ret

BmDrEdit_SendMetronomeNoteOn_Alt:
	calr Metronome_PlayClick
	calr BmDrEdit_BuildNoteOnEvent_WithVelocity
	ld (0x295e:16), 134
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
	ld a, (0x2965:16)
	inc 1, a
	extz wa
	jp SeqBuf_WriteNoteOffEntry

BmDrEdit_InsertNoteSequence:
	push xiz
	ld wa, (0x28af:16)
	ldw_erp WA, 0xfa
	ld iz, (9830:16)
	res 2, (0x295f:16)
	calr BmDrEdit_LoadAlternateAndValidate
	ld bc, (0x279a:16)
	extz xbc
	div bc, 0x60
	inc 1, bc
	ld wa, (0x2772:16)
	cp bc, wa
	jr c, BmDrEdit_InsertSeq_PopIzRet
	inc 1, bc
	sub bc, wa
	ld (0x2772:16), bc
	calr EditChannel_LoadVoiceParams
	cpw (0x2772:16), 0
	jr z, BmDrEdit_SavePositionAndReturn

BmDrEdit_InsertSeq_StepLoop:
	calr BmDrEdit_InsertStepEntry
	cp (0x287a:16), 0
	jr z, BmDrEdit_InsertSeq_DecrementCount
	set 2, (0x295f:16)
	jr BmDrEdit_SavePositionAndReturn

BmDrEdit_InsertSeq_DecrementCount:
	ld wa, (0x2772:16)
	dec 1, wa
	ld (0x2772:16), wa
	cps wa, 0
	jr nz, BmDrEdit_InsertSeq_StepLoop

BmDrEdit_SavePositionAndReturn:
	stw_erp WA, 0xfa
	ld (0x28af:16), wa
	ld (9830:16), iz

BmDrEdit_InsertSeq_PopIzRet:
	pop xiz
	ret

BmDrEdit_ScanAfterModify:
	dec 4, xsp
	res 3, (0x295f:16)
	cpw (0x279c:16), 0
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
	cp (0x2760:16), 0
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
	cp wa, (0x279c:16)
	jr c, BmDrEdit_ScanAfterModify_WalkLoop
	calr BmDrEdit_RestoreEditState
	jr BmDrEdit_ScanAfterModify_Return

BmDrEdit_SetFlagReturn:
	set 3, (0x295f:16)

BmDrEdit_ScanAfterModify_Return:
	inc 4, xsp
	ret

BmDrEdit_AlignGridBackward:
	ld wa, (0x279a:16)
	cps wa, 0
	ret z
	lds de, 0
	cps wa, 0
	jr ule, BmDrEdit_AlignGridBackward_Store
	ld bc, (0x2792:16)

BmDrEdit_AlignGridBackward_AccumLoop:
	add de, bc
	cp de, wa
	jr c, BmDrEdit_AlignGridBackward_AccumLoop

BmDrEdit_AlignGridBackward_Store:
	sub de, (0x2792:16)
	ld (0x279a:16), de
	ret

BmDrEdit_LoadAlternateAndValidate:
	calr BmDrEdit_LoadAlternateState
	cp (0x287a:16), 0
	jr z, BmDrEdit_LoadAlternateAndValidate_Done
	ldw wa, 0xb8
	call SeqData_SetErrorCode

BmDrEdit_LoadAlternateAndValidate_Done:
	jr BmDrEdit_CountMeasuresAndValidate

BmDrEdit_CountMeasuresAndValidate:
	cp (0x287a:16), 0
	jr z, BmDrEdit_CountMeasures_Init
	ldw wa, 0xd1
	call SeqData_SetErrorCode

BmDrEdit_CountMeasures_Init:
	ldw (0x2772:16), 0

BmDrEdit_CountMeasures_Loop:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_CheckAndReportScanError
	cp l, 0x84
	jr z, BmDrEdit_CheckAndReportScanError
	cp l, 0x81
	jr nz, BmDrEdit_CountMeasures_SkipEvent
	incw 1, (0x2772:16)

BmDrEdit_CountMeasures_SkipEvent:
	call SeqData_SkipToNextEvent
	jr BmDrEdit_CountMeasures_Loop

BmDrEdit_CheckAndReportScanError:
	cp (0x287a:16), 0
	ret z
	ldw wa, 0xce
	call SeqData_SetErrorCode
	ret

BmDrEdit_NavigateBackwardWithEdit:
	dec 4, xsp
	bit 7, (0x295c:16)
	jrl nz, BmDrEdit_NavigateReturn
	calr BmDrEdit_SaveEditState
	ldmm16 0x279c, 0x279a
	calr BmDrEdit_AlignGridBackward
	calr BmDrEdit_CalcBeatMeasure
	bit 0, (0x295f:16)
	jr nz, BmDrEdit_NavigateAfterEdit
	calr BmDrEdit_ScanAfterModify
	bit 3, (0x295f:16)
	jr z, BmDrEdit_NavEdit_CheckPosition
	cpw (0x2744:16), 1
	jr z, BmDrEdit_ResetToFirstEvent
	cpw (0x279c:16), 0
	jr z, BmDrEdit_GoToPrevPage

BmDrEdit_ResetToFirstEvent:
	calr BmDrEdit_AdjustViewToPosition
	jrl BmDrEdit_NavigateReturn

BmDrEdit_GoToPrevPage:
	calr BmDrEdit_NavigatePrevPage
	jrl BmDrEdit_NavigateReturn

BmDrEdit_NavEdit_CheckPosition:
	ld wa, (0x276e:16)
	cp wa, (0x28af:16)
	jr nz, BmDrEdit_CheckCurrentNoteMatch
	ld a, (0x2770:16)
	extz wa
	cp wa, (9830:16)
	jr nz, BmDrEdit_CheckCurrentNoteMatch
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	sub wa, (xsp)
	cp (0x279c:16), wa
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
	cp wa, (0x279a:16)
	jr nc, BmDrEdit_NavEdit_InitView

BmDrEdit_NavigateAfterEdit:
	calr BmDrEdit_WalkAndScanAfterEdit
	bit 3, (0x295f:16)
	jr z, BmDrEdit_NavEdit_CalcCoords
	cpw (0x2744:16), 1
	jr z, BmDrEdit_ResetToFirstEvent
	cpw (0x279c:16), 0
	jr z, BmDrEdit_GoToPrevPage
	jr BmDrEdit_ResetToFirstEvent

BmDrEdit_NavEdit_CalcCoords:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jrl c, BmDrEdit_ResetToFirstEvent
	ld wa, (0x279a:16)
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
	res 3, (0x295f:16)
	call SeqData_ReadNextByte
	cp l, 0x81
	jr nz, BmDrEdit_ScanSequenceEnd
	ld wa, (0x275e:16)
	cps wa, 0
	jr z, BmDrEdit_CheckVelocityMatch
	dec 1, wa
	ld (0x275e:16), wa
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupCoordinates
	ld wa, (xsp + 2)
	cp wa, (xsp)
	jr c, BmDrEdit_CheckVelocityMatch

BmDrEdit_ScanSequenceEnd:
	calr BmDrEdit_ClearAndScanToEnd
	cp (0x287a:16), 0
	jr z, BmDrEdit_WalkScan_ReadNext
	set 3, (0x295f:16)
	ld (0x287a:16), 0
	jr BmDrEdit_WalkScan_Return

BmDrEdit_WalkScan_ReadNext:
	call SeqData_ReadNextByte
	cp l, 0x81
	jr nz, BmDrEdit_WalkScan_CheckNoteOn
	ld wa, (0x275e:16)
	cps wa, 0
	jr z, BmDrEdit_CheckVelocityMatch
	dec 1, wa
	ld (0x275e:16), wa
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
	set 3, (0x295f:16)

BmDrEdit_WalkScan_Return:
	inc 4, xsp
	ret

BmDrEdit_PostModeChange96:
	bit 7, (0x2746:16)
	ret nz
	bit 7, (0x295c:16)
	ret nz
	ldw wa, 0x96
	jp UI_PostModeChangeEvent

BmDrEdit_DrumVoiceUp_Check:
	bit 7, (0x295c:16)
	jr z, BmDrEdit_DrumVoiceUp_ClearFlag
	cp (0x295d:16), 5
	ret nz

BmDrEdit_DrumVoiceUp_ClearFlag:
	res 0, (0x295f:16)
	jr BmDrEdit_DrumVoiceUp

BmDrEdit_DrumVoiceUp:
	bit 7, (0x2746:16)
	ret nz
	ld wa, (0x27a0:16)
	cp wa, 0xb
	jr c, BmDrEdit_DrumVoiceUp_IncrementOctave
	ld wa, (0x279e:16)
	cp wa, 0x74
	ret nc
	inc 1, wa
	ld (0x279e:16), wa
	jr BmDrEdit_DrumVoiceUp_UpdateDisplay

BmDrEdit_DrumVoiceUp_IncrementOctave:
	inc 1, wa
	ld (0x27a0:16), wa

BmDrEdit_DrumVoiceUp_UpdateDisplay:
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	call NoteEditSy_UpdateChordDisplay
	calr BmDrEdit_SendMetronomeNoteOn_Alt
	ld (0x295c:16), 131
	ld (0x295d:16), 5
	jp Audio_CheckSubsystemReady

BmDrEdit_DrumVoiceDown_Check:
	bit 7, (0x295c:16)
	jr z, BmDrEdit_DrumVoiceDown_ClearFlag
	cp (0x295d:16), 5
	ret nz

BmDrEdit_DrumVoiceDown_ClearFlag:
	res 0, (0x295f:16)
	jr BmDrEdit_DrumVoiceDown

BmDrEdit_DrumVoiceDown:
	bit 7, (0x2746:16)
	ret nz
	ld wa, (0x27a0:16)
	cps wa, 0
	jr nz, BmDrEdit_DrumVoiceDown_DecrementOctave
	ld wa, (0x279e:16)
	cps wa, 1
	ret z
	dec 1, wa
	ld (0x279e:16), wa
	jr BmDrEdit_DrumVoiceDown_UpdateDisplay

BmDrEdit_DrumVoiceDown_DecrementOctave:
	dec 1, wa
	ld (0x27a0:16), wa

BmDrEdit_DrumVoiceDown_UpdateDisplay:
	call NoteEditSy_SendWidgetCmd0
	calr NoteEdit_SendScrollCmds
	call NoteEditSy_UpdateChordDisplay
	calr BmDrEdit_SendMetronomeNoteOn_Alt
	ld (0x295c:16), 131
	ld (0x295d:16), 5
	jp Audio_CheckSubsystemReady

BmDrEdit_CalcTrackPosition:
	bit 0, (0x2742:16)
	ret z
	ld wa, (0x279e:16)
	add wa, (0x27a0:16)
	ld (0x2786:16), a
	ret

BmDrEdit_PostModeChange99:
	bit 7, (0x2746:16)
	ret nz
	bit 7, (0x295c:16)
	ret nz
	ldw wa, 0x99
	jp UI_PostModeChangeEvent

BmDrEdit_DelayAction_WalkAndUpdateAlt:
	calr BmDrEdit_SetupAndWalkToNote
	jrl NoteEdit_UpdateScrollAndDisplay

BmDrEdit_PlayNoteAndSetDelay:
	calr BmDrEdit_SendMetronomeNoteOn
	ld (0x295e:16), 134
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
	incw 4, (xsp + 6)

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
	ld wa, (0x28af:16)
	cp wa, (xsp + 12)
	jr nz, BmDrEdit_VelChange_DecrementCounters
	ld wa, (9830:16)
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
	incw 1, (xwa)
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
	ld (0x287a:16), 0
	ld (xsp), 0x81
	ld a, (0x2965:16)
	inc 1, a
	extz wa
	lda xbc, (xsp)
	lds de, 1
	calr BmDrEdit_ApplyVelocityChange
	inc 2, xsp
	ret

BmDrEdit_PrepareAndInsertNote:
	calr BmDrEdit_WalkToGridPosition
	ld (0x2967:16), 144
	ld wa, (0x279a:16)
	extz xwa
	div wa, 0x60
	stw_erp WA, 0xe2
	ld (0x2968:16), a
	ldmm8 0x2969, 0x2960
	ldmm8 0x296a, 0x2961
	ld wa, (0x278e:16)
	extz xwa
	div wa, 0x60
	stw_erp WA, 0xe2
	res 7, a
	ld (0x296b:16), a
	ld wa, (0x278e:16)
	extz xwa
	div wa, 0x60
	res 7, a
	ld (0x296c:16), a
	calr BmDrEdit_SaveSongPosition
	ld a, (0x2965:16)
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
	ld (0x287a:16), 0
	ld (0x288d:16), c
	call SeqVoice_SetDefaultParams
	ld a, (xsp + 10)
	extz wa
	call Part_ValidateVoiceChannel
	cp (0x287a:16), 0
	jr z, BmDrEdit_ValidateVoice_ProcessState
	ldb l, 0xff
	jr BmDrEdit_ValidateVoice_Epilog

BmDrEdit_ValidateVoice_ProcessState:
	ld iz, (0x28af:16)
	ld wa, (9830:16)
	ldw_erp WA, 0xfa
	call SeqVoice_ValidateAndProcessState
	ld (0x28af:16), iz
	stw_erp WA, 0xfa
	ld (9830:16), wa
	ldw (xsp + 4), 0x1
	ld xwa, (xsp + 6)
	ldw (xwa), 0x0
	cpw (0x287f:16), 1
	jr z, BmDrEdit_TrackValidateRet

BmDrEdit_ValidateVoice_SkipSections:
	ld a, (0x288e:16)
	extz wa
	ld xbc, (xsp + 6)
	ld bc, (xbc)
	call SeqData_SkipSections
	ld xwa, (xsp + 6)
	ld (xwa), hl
	cp (0x287a:16), 0
	jr nz, BmDrEdit_TrackValidateRet
	incw 1, (xsp + 4)
	call SeqTrack_ProcessControlBytes
	cp (0x287a:16), 0
	jr nz, BmDrEdit_TrackValidateRet
	ld wa, (xsp + 4)
	cp wa, (0x287f:16)
	jr nz, BmDrEdit_ValidateVoice_SkipSections

BmDrEdit_TrackValidateRet:
	ld l, (0x288e:16)

BmDrEdit_ValidateVoice_Epilog:
	pop xiz
	inc 8, xsp
	ret

BmDrEdit_SyncChannelAndGetPos:
	dec 2, xsp
	ldmm16 0x287f, 0x2744
	calr BmDrEdit_CheckAndSelectChannel
	ld a, (0x2965:16)
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
	ld (0x287a:16), 0
	calr BmDrEdit_SyncChannelAndGetPos
	cp (0x287a:16), 0
	ret nz
	ld (0x276a:16), hl
	ld (0x276c:16), 0
	ldmm16 0x276e, 0x28af
	ld wa, (9830:16)
	ld (0x2770:16), a
	ret

BmDrEdit_LoadAlternatePosition:
	ld (0x287a:16), 0
	calr BmDrEdit_SyncChannelAndGetPos
	cp (0x287a:16), 0
	ret nz
	ld (0x275e:16), hl
	ld (0x2760:16), 0
	ret

BmDrEdit_CopyEventDataBetweenParts:
	lda xsp, (xsp - 10)
	pushw_erp 0xfa
	ld (xsp + 10), a
	calr BmDrEdit_SaveSongPosition
	ld wa, (0x28af:16)
	ld bc, (9830:16)
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
	bit 7, (0x295c:16)
	jr nz, BmDrEdit_DeleteNote_PopIzRet
	bit 0, (0x295f:16)
	jr z, BmDrEdit_DeleteNote_PopIzRet
	ld a, (0x2965:16)
	inc 1, a
	extz wa
	calr BmDrEdit_CopyEventDataBetweenParts
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_DeleteNote_EndOfTrack
	cp l, 0x84
	jr nz, BmDrEdit_DeleteNote_CheckStep

BmDrEdit_DeleteNote_EndOfTrack:
	ld (0x2760:16), 0
	jr NoteEdit_FinalizeAndRefreshDisplay

BmDrEdit_DeleteNote_CheckStep:
	cp l, 0x81
	jr nz, BmDrEdit_DeleteNote_ReadNextEvent
	incw 1, (0x275e:16)
	jr NoteEdit_FinalizeAndRefreshDisplay

BmDrEdit_DeleteNote_ReadNextEvent:
	ld wa, (0x28af:16)
	ldw_erp WA, 0xfa
	ld iz, (9830:16)
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ld (0x2760:16), l
	stw_erp WA, 0xfa
	ld (0x28af:16), wa
	ld (9830:16), iz

NoteEdit_FinalizeAndRefreshDisplay:
	res 0, (0x295f:16)
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
	ld wa, (0x2744:16)
	ld (0x27b2:16), wa
	ldmm16 0x287f, 0x2744
	lds iz, 0
	ldw (xsp + 2), 0x0

BmDrEdit_ScanChannel_SelectLoop:
	calr BmDrEdit_CheckAndSelectChannel
	ld a, (0x2965:16)
	inc 1, a
	bit 2, (0x287b:16)
	jr z, BmDrEdit_ScanChannel_UseChannel
	ld a, l

BmDrEdit_ScanChannel_UseChannel:
	extz wa
	extz hl
	lda xde, (xsp + 4)
	ld bc, hl
	calr BmDrEdit_ValidateAndProcessVoice
	lda xwa, (0x27a4:16)
	cp (0x287a:16), 0
	jr z, BmDrEdit_ScanChannel_StoreAndContinue
	ld xbc, xwa
	ld a, (0x27a2:16)
	ldb_erp A, 0xf0
	extz ix
	ld wa, (xsp + 2)

BmDrEdit_ScanChannel_StoreEntry:
	ld l, (0x288e:16)
	incw 1, (xsp + 2)
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
	incw 1, (xsp + 2)
	ld xbc, xwa
	ld de, iz
	extz xde
	add xde, xwa
	ld wa, (xsp + 2)
	ld (xde), a
	ld e, (0x27a2:16)
	extz de

BmDrEdit_ScanChannel_FillRemaining:
	inc 1, iz
	cp iz, de
	jr c, BmDrEdit_ScanChannel_AdvanceSong

BmDrEdit_ScanChannel_RestoreAndReturn:
	calr BmDrEdit_RestoreEditState
	ld (0x287a:16), 0
	popw iz
	inc 4, xsp
	ret

BmDrEdit_ScanChannel_AdvanceSong:
	cps l, 1
	jr nz, BmDrEdit_ScanChannel_ClearSlot
	incw 1, (0x287f:16)
	jrl BmDrEdit_ScanChannel_SelectLoop

BmDrEdit_ScanChannel_ClearSlot:
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld (xwa), 0x0
	dec 1, l
	jr BmDrEdit_ScanChannel_FillRemaining

BmDrEdit_BuildVoiceList:
	ld bc, (0x2744:16)
	sub bc, (0x27b2:16)
	inc 1, bc
	ld h, c
	lds ix, 0
	ldb l, 0x0
	lda xde, (0x27a4:16)
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
	ld bc, (0x2782:16)
	add bc, ix
	mul bc, 0x60
	ld a, (0x2784:16)
	extz wa
	add bc, wa
	ld (0x279a:16), bc
	ret

BmDrEdit_BuildVoice_NullReturn:
	ret

BmDrEdit_FindNextPageEntry:
	ld hl, (0x2744:16)
	sub hl, (0x27b2:16)
	inc 1, l
	ldb e, 0x0
	lda xbc, (0x27a4:16)

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
	cp e, (0x27a2:16)
	jr c, BmDrEdit_FindNextPage_ScanLoop
	ldb l, 0xff
	ret

BmDrEdit_FindNextPage_SkipZero:
	inc 1, e
	inc 1, l
	cp e, (0x27a2:16)
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
	bit 0, (0x2742:16)
	jr nz, NoteEditSy_ScrollComplete_Return
	ldmm8 0x27ca, 0x2798

BmDrEdit_ScrollAdjustLoop:
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr BmDrEdit_SetupScrollRegion
	ld c, (0x2962:16)
	ld a, (0x2798:16)
	cp c, (xsp + 2)
	jr nc, BmDrEdit_ScrollAdjust_CheckUpper
	ld c, a
	cps a, 0
	jr z, NoteEditSy_ScrollComplete_Return
	dec 1, c
	ld (0x2798:16), c
	jr BmDrEdit_ScrollAdjustLoop

BmDrEdit_ScrollAdjust_CheckUpper:
	cp c, (xsp)
	jr ule, BmDrEdit_ScrollAdjust_CompareAndUpdate
	ld c, a
	cp a, 0x9
	jr nc, NoteEditSy_ScrollComplete_Return
	inc 1, c
	ld (0x2798:16), c
	jr BmDrEdit_ScrollAdjustLoop

BmDrEdit_ScrollAdjust_CompareAndUpdate:
	ld a, (0x27ca:16)
	cp a, (0x2798:16)
	jr z, NoteEditSy_ScrollComplete_Return
	call NoteEditSy_UpdateChordDisplay

NoteEditSy_ScrollComplete_Return:
	inc 4, xsp
	ret

BmDrEdit_CountMeasuresInit:
	pushw_erp 0xfa
	ld (0x287a:16), 0
	calr BmDrEdit_SaveEditState
	calr BmDrEdit_ReadNoteDataFields
	ldb_erp L, 0xfb
	inc1b_erp 0xfb
	cp (0x287a:16), 0
	jr z, BmDrEdit_CountInit_ValidateAndInsert
	ldw wa, 0xb5
	call SeqData_SetErrorCode

BmDrEdit_CountInit_ValidateAndInsert:
	calr BmDrEdit_CountMeasuresAndValidate
	inc1b_erp 0xfb
	stb_erp A, 0xfb
	extz wa
	ld bc, (0x2772:16)
	cp wa, bc
	jr c, BmDrEdit_RestoreEditRet
	stb_erp A, 0xfb
	sub a, c
	inc 1, a
	ldb_erp A, 0xfb
	extz wa
	ld (0x2772:16), wa
	cps wa, 0
	jr z, BmDrEdit_RestoreEditRet

BmDrEdit_CountInit_InsertLoop:
	calr EditChannel_LoadVoiceParams
	calr BmDrEdit_InsertStepEntry
	cp (0x287a:16), 0
	jr z, BmDrEdit_CountInit_DecrementLoop
	ldw wa, 0xcd
	call SeqData_SetErrorCode
	ld (0x287a:16), 255
	jr BmDrEdit_RestoreEditRet

BmDrEdit_CountInit_DecrementLoop:
	ld wa, (0x2772:16)
	dec 1, wa
	ld (0x2772:16), wa
	cps wa, 0
	jr nz, BmDrEdit_CountInit_InsertLoop

BmDrEdit_RestoreEditRet:
	calr BmDrEdit_RestoreEditState
	popw_erp 0xfa
	ret

BmDrEdit_CheckAndAdvancePage:
	ld a, (0x27a2:16)
	dec 1, a
	extz wa
	lda xbc, (0x27a4:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, BmDrEdit_AdvancePage_IncrementBeat
	incw 1, (0x2744:16)
	ldw (0x2782:16), 0
	jr BmDrEdit_AdvancePage_CalcOffset

BmDrEdit_AdvancePage_IncrementBeat:
	incw 1, (0x2782:16)

BmDrEdit_AdvancePage_CalcOffset:
	ld bc, (0x279a:16)
	ld a, (0x2774:16)
	mul a, 0x60
	sub bc, wa
	ld (0x2784:16), c
	ret

BmDrEdit_ProcessVoiceSection:
	lda xsp, (xsp - 10)
	ld (xsp), xde
	ld (xsp + 4), xbc
	ld (xsp + 8), a
	call SeqVoice_SetDefaultParams
	ld (0x287a:16), 0
	bit 2, (0x287b:16)
	jr nz, BmDrEdit_ProcessVoice_WithState
	ld c, (1075:16)
	extz bc
	ld wa, (3299:16)
	extz xwa
	div xwa, xbc
	ld bc, wa
	ld xde, (xsp + 4)
	ld (xde), bc
	ld c, (1075:16)
	extz bc
	ld wa, (3299:16)
	extz xwa
	div xwa, xbc
	stw_erp BC, 0xe2
	ld xwa, (xsp)
	ld (xwa), bc
	incw 1, (xde)
	ld l, (1075:16)
	jr BmDrEdit_ProcessVoice_Epilog

BmDrEdit_ProcessVoice_WithState:
	mrdb5 0x8f, 0x08, 0x19, 0x8d, 0x28
	call SeqVoice_ValidateAndProcessState
	ld l, (0x288e:16)
	ld xwa, (xsp)
	ldmw2 (xwa), 0xce3
	ld xwa, (xsp + 4)
	ldw (xwa), 0x1
	jr BmDrEdit_ProcessVoice_CompareAndLoop

BmDrEdit_ProcessVoice_SubtractAndContinue:
	ld xwa, (xsp)
	sub (xwa), bc
	ld xwa, (xsp + 4)
	incw 1, (xwa)
	call SeqTrack_ProcessControlBytes
	ld l, (0x288e:16)

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
	ld wa, (0x2744:16)
	cp wa, (xsp + 2)
	jr z, BmDrEdit_MultiSong_Return
	cpw (xsp), 0x0
	jr z, BmDrEdit_MultiSong_CalcRemaining
	ld wa, (xsp)
	sub l, a

BmDrEdit_MultiSong_CalcRemaining:
	extz hl
	ld (0x2772:16), hl

BmDrEdit_MultiSong_InsertLoop:
	calr EditChannel_LoadVoiceParams
	calr BmDrEdit_InsertStepEntry
	cp (0x287a:16), 0
	jr nz, BmDrEdit_MultiSong_Return
	incw 1, (0x275e:16)
	ld wa, (0x2772:16)
	dec 1, wa
	ld (0x2772:16), wa
	cps wa, 0
	jr nz, BmDrEdit_MultiSong_InsertLoop
	ldmm16 3299, 0x275e
	jr BmDrEdit_MultiSong_SelectAndProcess

BmDrEdit_MultiSong_Return:
	inc 4, xsp
	ret

NoteEdit_SendScrollCmds:
	bit 0, (0x2742:16)
	jr nz, BmDrEdit_SendScrollCmds_DrumMode
	jr BmDrEdit_SendScrollCmds_MelodicNoteOff

BmDrEdit_SendScrollCmds_MelodicNoteOff:
	bit 0, (0x295f:16)
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
	bit 0, (0x295f:16)
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
	ld a, (0x2774:16)
	mul a, 0x60
	cp (0x279a:16), wa
	ret nc
	jrl NoteEditSy_UpdateAllWidgets
	sub a, c
	bit 0, (0x2742:16)
	jr z, BmDrEdit_UpdateDisplay_MelodicOffset
	ldb c, 0xb
	sub c, a
	ld (0x27cc:16), c
	ret

BmDrEdit_UpdateDisplay_MelodicOffset:
	ld c, a
	ld (0x27cc:16), a
	cp (0x2798:16), 0
	ret nz
	inc 3, c
	ld (0x27cc:16), c
	ret

BmDrEdit_ByteData_CompoundWidgetUpdate:
	dec	8, xsp
	push	qiz
	lda	xwa, (xsp+8)
	lda	xbc, (xsp+6)
	calr	-6217
	ld	wa, (xsp+6)
	sub	(xsp+8), wa
	.byte 0x9f, 0x08, 0x19, 0xce, 0x27
	call	15999398
	ldb_erp	l, 250
	lda	xwa, (xsp+4)
	lda	xbc, (xsp+2)
	calr	-5184
	stb_erp	a, 250
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	calr	-91
	call	15990866
	call	15990866
	call	15999398
	ldb_erp	l, 250
	stb_erp	a, 250
	ldb_erp	a, 251
	call	15990866
	call	15999398
	ldb_erp	l, 250
	res_erpb	251, 7
	res_erpb	250, 7
	stb_erp	c, 250
	extz	bc
	mul	bc, 96
	stb_erp	a, 251
	extz	wa
	add	bc, wa
	ld	(10192:16), bc
	calr	6
	pop	qiz
	inc	8, xsp
	ret
	ld	e, (10100:16)
	mul	e, 96
	dec	1, de
	ld	wa, (10190:16)
	ld	bc, wa
	add	bc, (10192:16)
	cp	bc, de
	ret	ule
	sub	de, wa
	ld	(10192:16), de
	ret
	ld	wa, (10190:16)
	srl	wa, 2
	add	wa, 22
	ld	(10170:16), wa
	ld	wa, (10192:16)
	srl	wa, 2
	add	wa, (10170:16)
	ld	(10172:16), wa
	ld	wa, (10174:16)
	inc	3, wa
	ld	(10176:16), wa
	ret

ReadSeqData_StoreParams:
	call SeqData_AdvancePosition
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ld (0x2969:16), l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ld (0x296a:16), l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ld (0x296b:16), l
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ld (0x296c:16), l
	calr BmDrEdit_ClearAndScanToEnd
	ld a, (0x2965:16)
	inc 1, a
	extz wa
	calr BmDrEdit_CopyEventDataBetweenParts
	calr BmDrEdit_SeekForwardToEvent
	cp (0x287a:16), 0
	jr nz, BmDrEdit_ReadSeqStoreParams_Error
	ld (0x2967:16), 144
	ldmm8 0x2968, 0x2784
	calr BmDrEdit_SaveSongPosition
	ld a, (0x2965:16)
	inc 1, a
	extz wa
	ld xbc, 0x2967
	lds de, 6
	calr BmDrEdit_ApplyVelocityChange
	calr BmDrEdit_CountMeasuresInit
	cp (0x287a:16), 0
	ret z

BmDrEdit_ReadSeqStoreParams_Error:
	calr BmDrEdit_RefreshDisplayState
	ret

BmDrEdit_CalcBeatMeasure:
	ld wa, (0x279a:16)
	extz xwa
	div wa, 0x60
	ld (9688:16), 0
	ld (0x2772:16), wa
	cps wa, 0
	jr z, BmDrEdit_ComputeMeasureAndBeat
	lds de, 1
	ld (9688:16), 1
	lda xbc, (0x27a4:16)

BmDrEdit_CalcBeatMeasure_ScanLoop:
	ld wa, de
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, BmDrEdit_CalcBeatMeasure_IncrementCount
	ld (9688:16), 0

BmDrEdit_CalcBeatMeasure_IncrementCount:
	inc 1, de
	ld wa, (0x2772:16)
	dec 1, wa
	ld (0x2772:16), wa
	cps wa, 0
	jr z, BmDrEdit_ComputeMeasureAndBeat
	inc 1, (9688:16)
	jr BmDrEdit_CalcBeatMeasure_ScanLoop

BmDrEdit_ComputeMeasureAndBeat:
	ld a, (9688:16)
	extz wa
	ld (0x2782:16), wa
	ld wa, (0x279a:16)
	extz xwa
	div wa, 0x60
	stw_erp WA, 0xe2
	ld (0x2784:16), a
	jr BmDrEdit_CalcSongPosition

BmDrEdit_CalcSongPosition:
	ld bc, (0x279a:16)
	extz xbc
	div bc, 0x60
	ld (9688:16), 0
	ld (0x2772:16), bc
	cps bc, 0
	jr z, BmDrEdit_CalcSongPos_Store
	lds de, 1
	ld (9688:16), 0
	lda xbc, (0x27a4:16)

BmDrEdit_CalcSongPos_ScanLoop:
	ld wa, de
	extz xwa
	add xwa, xbc
	cp (xwa), 0x0
	jr z, BmDrEdit_CalcSongPos_IncrementCount
	inc 1, (9688:16)

BmDrEdit_CalcSongPos_IncrementCount:
	inc 1, de
	ld wa, (0x2772:16)
	dec 1, wa
	ld (0x2772:16), wa
	cps wa, 0
	jr nz, BmDrEdit_CalcSongPos_ScanLoop

BmDrEdit_CalcSongPos_Store:
	ld bc, (0x27b2:16)
	ld a, (9688:16)
	extz wa
	add bc, wa
	ld (0x2744:16), bc
	ret

BmDrEdit_CalcEventPosition:
	ld de, (0x2744:16)
	sub de, (0x27b2:16)
	inc 1, de
	lds hl, 0
	lda xbc, (0x27a4:16)
	ld a, (0x27a2:16)
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
	ld (0x2782:16), de
	ret

BmDrEdit_SyncSeekCheck:
	push xiz
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl
	cp (0x287a:16), 0
	jr z, BmDrEdit_InitScanEventPositions
	calr BmDrEdit_SeekToPartVoice
	cp (0x287a:16), 0
	jrl nz, BmDrEdit_SyncSeek_PopIzRet
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl

BmDrEdit_InitScanEventPositions:
	ldib_erp 0xfb, 0
	ld (0x275e:16), iz
	ld (0x2760:16), 0
	cpw (0x2782:16), 0
	jr z, BmDrEdit_SyncSeek_ReadNext
	ldw (0x2772:16), 0

BmDrEdit_SyncSeek_ReadLoop:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_SyncSeek_EndOfTrack
	cp l, 0x84
	jr nz, BmDrEdit_SyncSeek_CheckStep

BmDrEdit_SyncSeek_EndOfTrack:
	calr BmDrEdit_SeekToPartVoice
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jr z, BmDrEdit_SyncSeek_ResyncChannel
	jr BmDrEdit_SyncSeek_PopIzRet

BmDrEdit_SyncSeek_CheckStep:
	cp l, 0x81
	jr nz, BmDrEdit_SyncSeek_SkipEvent
	ld wa, (0x2772:16)
	inc 1, wa
	ld (0x2772:16), wa
	cp wa, (0x2782:16)
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
	ld wa, (0x2782:16)
	add (0x275e:16), wa
	ldmm8 0x2760, 0x2784

BmDrEdit_SyncSeek_PopIzRet:
	pop xiz
	ret

BmDrEdit_SyncSeek_AdvanceAndCompare:
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cp l, (0x2784:16)
	jr nc, BmDrEdit_SyncSeek_CheckFlagAndClear
	jr BmDrEdit_SyncSeek_SkipAndRead

BmDrEdit_SeekForwardToEvent:
	push xiz
	calr BmDrEdit_SyncChannelAndGetPos
	ld iz, hl
	cp (0x287a:16), 0
	jrl z, BmDrEdit_StoreStreamPos
	calr BmDrEdit_SeekToPartVoice
	cp (0x287a:16), 0
	jrl z, BmDrEdit_SyncStorePos
	jrl BmDrEdit_PopIzRet

BmDrEdit_SeekFwd_CheckStep:
	cp l, 0x81
	jr nz, BmDrEdit_AdvanceAndCheckBeat
	jrl BmDrEdit_CalcStorePos

BmDrEdit_SeekFwd_InitCountLoop:
	ldw (0x2772:16), 0
	ldib_erp 0xfb, 0

BmDrEdit_SeekFwd_ReadLoop:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_SeekFwd_EndOfTrack
	cp l, 0x84
	jr nz, BmDrEdit_SeekFwd_CheckStepMark

BmDrEdit_SeekFwd_EndOfTrack:
	calr BmDrEdit_SeekToPartVoice
	cp (0x287a:16), 0
	jr z, BmDrEdit_SeekFwd_ResyncChannel
	jrl BmDrEdit_PopIzRet

BmDrEdit_SeekFwd_CheckRetryFlag:
	cpib_erp 0xfb, 1
	jr z, BmDrEdit_StoreStreamPos

BmDrEdit_AdvanceAndCheckBeat:
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cp l, (0x2784:16)
	jrl ugt, BmDrEdit_SeekFwd_ClearAndCalcStore
	call SeqData_SkipToNextEvent
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_SeekFwd_EndOfTrackAlt
	cp l, 0x84
	jrl nz, BmDrEdit_SeekFwd_CheckStepAdvance

BmDrEdit_SeekFwd_EndOfTrackAlt:
	calr BmDrEdit_SeekToPartVoice
	cp (0x287a:16), 0
	jr z, BmDrEdit_SyncStorePos
	jrl BmDrEdit_PopIzRet

BmDrEdit_SeekFwd_CheckStepMark:
	cp l, 0x81
	jr nz, BmDrEdit_SkipEventAndContinue
	ld wa, (0x2772:16)
	inc 1, wa
	ld (0x2772:16), wa
	cp wa, (0x2782:16)
	jr c, BmDrEdit_SkipEventAndContinue
	call SeqData_SkipToNextEvent
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_SeekFwd_EndOfTrackResync
	cp l, 0x84
	jr nz, BmDrEdit_SeekFwd_CheckStepJump

BmDrEdit_SeekFwd_EndOfTrackResync:
	calr BmDrEdit_SeekToPartVoice
	cp (0x287a:16), 0
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
	ld (0x275e:16), iz
	ld (0x2760:16), 0
	cpw (0x2782:16), 0
	jrl nz, BmDrEdit_SeekFwd_InitCountLoop
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, BmDrEdit_SeekFwd_EndOfTrackResyncAlt
	cp l, 0x84
	jrl nz, BmDrEdit_SeekFwd_CheckStep

BmDrEdit_SeekFwd_EndOfTrackResyncAlt:
	calr BmDrEdit_SeekToPartVoice
	cp (0x287a:16), 0
	jr z, BmDrEdit_SyncStorePos
	jr BmDrEdit_PopIzRet

BmDrEdit_SeekFwd_CheckStepAdvance:
	cp l, 0x81
	jrl nz, BmDrEdit_AdvanceAndCheckBeat
	jr BmDrEdit_CalcStorePos

BmDrEdit_SeekFwd_ClearAndCalcStore:
	calr BmDrEdit_ClearAndScanToEnd

BmDrEdit_CalcStorePos:
	ld wa, (0x2782:16)
	add (0x275e:16), wa
	ldmm8 0x2760, 0x2784

BmDrEdit_PopIzRet:
	pop xiz
	ret

BmDrEdit_PrepareSecondaryNoteDisplay:
	dec 4, xsp
	pushw iz
	bit 0, (0x295f:16)
	jrl z, BmDrEdit_SecondaryNote_PopIzReturn
	calr BmDrEdit_SaveEditState
	ldmm16 0x280c, 0x276a
	ld a, (0x276c:16)
	extz wa
	ld (0x280e:16), wa
	ldmm16 0x2810, 0x276e
	ld a, (0x2770:16)
	extz wa
	ld (0x2812:16), wa
	ldmm16 0x2814, 0x275e
	ld a, (0x2760:16)
	extz wa
	ld (0x2816:16), wa
	ldmm16 0x2818, 0x28af
	ldmm16 0x281a, 9830
	call SeqData_ReadNextByte
	and l, 0xf0
	cp l, 0x90
	jr nz, BmDrEdit_RestoreReturn
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	extz hl
	ld (0x2816:16), hl
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	ld (0x281c:16), l
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 2)
	calr BmDrEdit_SetupScrollRegion
	ld a, (0x281c:16)
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
	ld (0x2820:16), hl
	call NoteEditSy_SendWidgetCmdC

BmDrEdit_RestoreReturn:
	calr BmDrEdit_RestoreEditState

BmDrEdit_SecondaryNote_PopIzReturn:
	popw iz
	inc 4, xsp
	ret

BmDrEdit_EnterPlayMode:
	ld a, (0x8d36:16)
	cp a, (0x8d37:16)
	ret z
	ld a, (0x28b1:16)
	ld (0x283c:16), a
	set 0, (0x28b1:16)
	cp (0x283a:16), 0
	jr nz, BmDrEdit_EnterPlay_RestoreSettings
	ldmm_sd24w 0xec, 0xff, 0x00, 0x9e, 0xf1
	jr BmDrEdit_EnterPlay_CheckAudio

BmDrEdit_EnterPlay_RestoreSettings:
	ldmm16 0xf19e, 0x2963

BmDrEdit_EnterPlay_CheckAudio:
	call Audio_CheckSubsystemReady
	ld wa, (0x2744:16)
	ld (9500:16), wa
	cp wa, (9502:16)
	jr ule, BmDrEdit_EnterPlay_UpdateProgress
	ld (9502:16), wa

BmDrEdit_EnterPlay_UpdateProgress:
	ldmm16 9832, 9500
	cpw (9832:16), 1
	jr z, BmDrEdit_EnterPlay_AllocAndInit
	set 3, (0x28a7:16)

BmDrEdit_EnterPlay_AllocAndInit:
	jp SeqPlay_AllocBuffersAndInit

BmDrEdit_ExitPlayMode:
	ld a, (0x8d36:16)
	cp a, (0x8d37:16)
	ret z
	ldmm8 0x28b1, 0x283c
	ldw (0xf19e:16), 0
	call Audio_CheckSubsystemReady
	call AccWrap_PlayModeDispatch
	ld a, (0x8d38:16)
	cp a, 0x95
	jr z, BmDrEdit_ExitPlay_RestoreSequencer
	cp a, 0x98
	ret nz

BmDrEdit_ExitPlay_RestoreSequencer:
	ldmm16 3407, 0x2963
	call SeqVoice_FindSingleActive
	ret

