; =============================================================================
; Demo-to-Sequencer Bridge & Playback Init (1K lines)
; =============================================================================
;
; MiddleFuncCall dispatcher, SqTrSel (sequencer track select),
; demo sequence playback initialization, and SMF node/slot
; resolution. Bridges demo mode to sequencer engine.
; =============================================================================


MiddleFuncCall:
	ld xwa, xbc
	cp xbc, 0x1e70018
	jrl z, SqTrSel_CaseB
	sub xwa, 0x1e70000
	cp xwa, 0x0
	jrl lt, SqTrSel_CaseC
	cp xwa, 0xc
	jrl gt, SqTrSel_CaseC
	add xwa, xwa
	add xwa, SepaOut_Config_0_0x202
	ld wa, (xwa)
	lda_24 xix, (MiddleFuncCall_DispatchData)
	jp_ind 8, 0x07, 0xf0, 0xe0

MiddleFuncCall_DispatchData:
	.incbin "includes/generated/v7_transplant_MiddleFuncCall_DispatchData.bin"
SqTrSel_CaseB:
	call	16696381
SqTrSel_CaseC:
	lds32 xhl, 0
	ret

SongBank_ComputeTableOfs:
	dec 2, xsp
	push xiz
	ld hl, bc
	ld (xsp + 4), wa
	lda_24 xbc, (0x0ab000)
	ld wa, (xsp + 4)
	extz xwa
	sll xwa, 11
	add xbc, xwa
	stb_dri A, 0xe5, 0x00, 0x01
	ld wa, (xsp + 4)
	mul wa, 0x15
	lda_d16 xix, (6906)
	ld iz, wa
	extz xiz
	add xiz, xix
	lda_dpi XSP, 0xf8
	cps e, 0
	jr z, SongBank_CopyNameAndFinish
	cpw (xsp + 4), 0x9
	jr nz, SongBank_FormatTwoDigit
	stib_dsp 0xf8, 0x31
	ld (xiz), 0x30
	jr SongBank_AppendColon

SongBank_FormatTwoDigit:
	stib_dsp 0xf8, 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

SongBank_AppendColon:
	inc 1, xiz
	stib_dsp 0xf8, 0x3a

SongBank_CopyNameAndFinish:
	ld xwa, xiz
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	ld (xiz + 16), 0x0
	ld wa, (xsp + 4)
	mul wa, 0x15
	lda_d16 xbc, (6906)
	extz xwa
	add xwa, xbc
	ld xhl, xwa
	pop xiz
	inc 2, xsp
	ret

SeqSongNameFunc:
	pushw iz
	cp xbc, 0x1e70003
	jrl z, SongBank_ReturnZero
	cp xbc, 0x1c00018
	jr z, SongBank_HandleNextPrev
	cp xbc, 0x1c00017
	jr z, SongBank_HandleNextPrev
	cp xbc, 0x1c0000b
	jr z, SeqSongName_RefreshAll
	cp xbc, 0x1e70002
	jrl nz, SongBank_ReturnZero
	stda32 7116, xde
	ldb_da a, (0x00ffe3)
	extz wa
	stda16 (7120), xwa
	ld de, wa
	extz xde
	ldda32 xwa, (7116)
	ld xbc, 0x1e70003
	call ApPostEvent
	jrl SongBank_ReturnZero

SeqSongName_RefreshAll:
	lds iz, 0

SeqSongName_RefreshLoop:
	ld wa, iz
	ld bc, iz
	lds de, 1
	calr SongBank_ComputeTableOfs
	ld xde, xhl
	ldda32 xwa, (7116)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr c, SeqSongName_RefreshLoop
	jrl SongBank_ReturnZero

SongBank_HandleNextPrev:
	ldw_d16 xwa, (7120)
	ld iz, wa
	cp xbc, 0x1c00018
	jr nz, SeqSongName_CheckPrev
	cp wa, 0x9
	jr nc, SongBank_StoreCurrentSong
	inc 1, wa
	jr SeqSongName_StoreCurrent

SeqSongName_CheckPrev:
	cp xbc, 0x1c00017
	jr nz, SongBank_StoreCurrentSong
	cps wa, 0
	jr z, SongBank_StoreCurrentSong
	dec 1, wa

SeqSongName_StoreCurrent:
	stda16 (7120), xwa

SongBank_StoreCurrentSong:
	ldw_d16 xde, (7120)
	cp iz, de
	jr z, SongBank_ReturnZero
	extz xde
	ldda32 xwa, (7116)
	ld xbc, 0x1e70003
	call ApPostEvent
	ld wa, iz
	ld bc, iz
	lds de, 1
	calr SongBank_ComputeTableOfs
	ld xde, xhl
	ldda32 xwa, (7116)
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw_d16 xbc, (7120)
	ld wa, bc
	lds de, 1
	calr SongBank_ComputeTableOfs
	ld xde, xhl
	ldda32 xwa, (7116)
	ld xbc, 0x1c0000f
	call ApPostEvent
	stb_erp A, 0xf8
	stb_d8 (7500), a
	ldw_d16 xwa, (7120)
	stb_d8 (7502), a
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_LoadToneGenData
	pop xiz
	pop xix
	pop xhl
	pop xde

SongBank_ReturnZero:
	lds32 xhl, 0
	popw iz
	ret

SongBank_LookupTableEntry:
	dec 2, xsp
	push xiz
	ld (xsp + 4), wa
	lda_d16 xix, (4421)
	ld wa, (xsp + 4)
	extz xwa
	add xix, xwa
	ld wa, (xsp + 4)
	mul wa, 0x7
	lda_d16 xhl, (7122)
	ld iz, wa
	extz xiz
	add xiz, xhl
	lda_dpi XHL, 0xf8
	cps e, 0
	jr z, SongBankLookup_BuildAudioCmd
	cpw (xsp + 4), 0x9
	jr nz, SongBankLookup_FormatTwoDigit
	stib_dsp 0xf8, 0x31
	ld (xiz), 0x30
	jr SongBankLookup_AppendColon

SongBankLookup_FormatTwoDigit:
	stib_dsp 0xf8, 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

SongBankLookup_AppendColon:
	inc 1, xiz

SongBankLookup_BuildAudioCmd:
	stib_dsp	248, 58
	ld	a, (xix)
	extz	wa
	pushw	wa
	pushw	226
	pushw	514
	push	xiz
	call	16712341
	lda	xsp, (xsp+10)
	ld	(xiz+4), 0
	ld	wa, (xsp+4)
	mul	wa, 7
	lda_d16	xbc, (7122)
	extz	xwa
	add	xwa, xbc
	ld	xhl, xwa
	pop	xiz
	inc	2, xsp
	ret
SeqSongMemoryFunc:
	pushw iz
	cp xbc, 0x1e70003
	jrl z, SongBank_EventHandler_Return
	cp xbc, 0x1c00018
	jr z, SongBank_HandleNextPrevAlt
	cp xbc, 0x1c00017
	jr z, SongBank_HandleNextPrevAlt
	cp xbc, 0x1c0000b
	jr z, SeqSongMem_RefreshAll
	cp xbc, 0x1e70002
	jrl nz, SongBank_EventHandler_Return
	stda32 7192, xde
	ldb_da a, (0x00ffe3)
	extz wa
	stda16 (7196), xwa
	ld de, wa
	extz xde
	ldda32 xwa, (7192)
	ld xbc, 0x1e70003
	jrl SeqSongMem_PostAndReturn

SeqSongMem_RefreshAll:
	lds iz, 0

SeqSongMem_RefreshLoop:
	ld wa, iz
	ld bc, iz
	lds de, 0
	calr SongBank_LookupTableEntry
	ld xde, xhl
	ldda32 xwa, (7192)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr c, SeqSongMem_RefreshLoop
	jr SongBank_EventHandler_Return

SongBank_HandleNextPrevAlt:
	ldw_d16 xwa, (7196)
	ld iz, wa
	cp xbc, 0x1c00018
	jr nz, SeqSongMem_CheckPrev
	cp wa, 0x9
	jr nc, SongBank_EventCompare
	inc 1, wa
	jr SeqSongMem_StoreCurrent

SeqSongMem_CheckPrev:
	cp xbc, 0x1c00017
	jr nz, SongBank_EventCompare
	cps wa, 0
	jr z, SongBank_EventCompare
	dec 1, wa

SeqSongMem_StoreCurrent:
	stda16 (7196), xwa

SongBank_EventCompare:
	ldw_d16 xde, (7196)
	cp iz, de
	jr z, SongBank_EventHandler_Return
	extz xde
	ldda32 xwa, (7192)
	ld xbc, 0x1e70003
	call ApPostEvent
	ld wa, iz
	ld bc, iz
	lds de, 0
	calr SongBank_LookupTableEntry
	ld xde, xhl
	ldda32 xwa, (7192)
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw_d16 xbc, (7196)
	ld wa, bc
	lds de, 0
	calr SongBank_LookupTableEntry
	ld xde, xhl
	ldda32 xwa, (7192)
	ld xbc, 0x1c0000f

SeqSongMem_PostAndReturn:
	call ApPostEvent

SongBank_EventHandler_Return:
	lds32 xhl, 0
	popw iz
	ret

CDlikeSwTtl_DispatchData:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_DispatchData.bin"
CDlikeSwTtl_SendStartEvt:
	ld xwa, 0x8b0003
	ld xbc, 0x1e0009c
	lds32 xde, 0
	jp ApPostEvent

CDlikeSwTtl_SendResetEvent:
	ld xwa, 0x8b0000
	ld xbc, 0x1c00001
	lds32 xde, 0
	jp ApPostEvent

CDlikeSwTtl_SendStopEvtD:
	ld xwa, 0x8b000d
	ld xbc, 0x1c00001
	lds32 xde, 0
	jp ApPostEvent

CDlikeSwTtl_SendEvent8C_0:
	ld xwa, 0x8c0000
	ld xbc, 0x1c00001
	lds32 xde, 0
	jp ApPostEvent

CDlikeSwTtl_SendEvent8C_A:
	ld xwa, 0x8c000a
	ld xbc, 0x1c00001
	lds32 xde, 0
	jp ApPostEvent

CDlikeSwTtl_SendEvent8C_13:
	ld xwa, 0x8c0013
	ld xbc, 0x1c00001
	lds32 xde, 0
	jp ApPostEvent

CDlikeSwTtl_SetRecordAndNotify:
	stib_da (0x021090), 0x01
	ld xwa, NAKA_PerfReg_Container_Root_0x1697
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApPostEvent
	ld xwa, SepaOut_Config_0_0x25
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApPostEvent
	ld xwa, NakaInst_FADE_IN_OUT_SETTING_0x2475
	ld xbc, 0x1c0000c
	lds32 xde, 0
	jp ApPostEvent

SeqInit_PostEventSequence:
	stib_da (0x021090), 0x00
	ld xwa, NAKA_PerfReg_Container_Root_0x1697
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApPostEvent
	ld xwa, SepaOut_Config_0_0x25
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApPostEvent
	ld xwa, NakaInst_FADE_IN_OUT_SETTING_0x2475
	ld xbc, 0x1c0000c
	lds32 xde, 0
	jp ApPostEvent

SeqInit_LookupDispatchEntry:
	extz wa
	sla wa, 2
	lda_24 xbc, (SepaOut_Config_0_0x222)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

SeqInit_PostDispatchEvent:
	ldb_d8 a, (0x28a4)
	extz wa
	calr SeqInit_LookupDispatchEntry
	ld xwa, xhl
	ld xbc, 0x1e0004d
	lds32 xde, 1
	jp ApDeliveryEvent

SeqInit_FinalEvent:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	lds32 xde, 0
	jp ApPostEvent

SeqRecPlay_EnableRecordOnly:
	stib_da (0x021092), 0x01
	stib_da (0x021094), 0x00
	ld xwa, 0x6f0025
	ld xbc, 0x1e000a7
	lds32 xde, 1
	call ApPostEvent
	lds32 xde, 0
	ldb_da e, (0x021094)
	ld xwa, 0x6f0024
	ld xbc, 0x1e000a7
	jp ApPostEvent

SeqRecPlay_EnablePlayOnly:
	stib_da (0x021092), 0x00
	stib_da (0x021094), 0x01
	ld xwa, 0x6f0025
	ld xbc, 0x1e000a7
	lds32 xde, 0
	call ApPostEvent
	lds32 xde, 0
	ldb_da e, (0x021094)
	ld xwa, 0x6f0024
	ld xbc, 0x1e000a7
	jp ApPostEvent

SeqRecPlay_DisableBoth:
	stib_da (0x021092), 0x00
	stib_da (0x021094), 0x00
	ld xwa, 0x6f0025
	ld xbc, 0x1e000a7
	lds32 xde, 0
	call ApPostEvent
	lds32 xde, 0
	ldb_da e, (0x021094)
	ld xwa, 0x6f0024
	ld xbc, 0x1e000a7
	jp ApPostEvent

; SqTrSelTtl case D
SqTrSel_CaseD:
	calr	65484
	call	16693581
	stdi8	(7498), 0
	ret
SqTrSel_CaseE:
	calr	65471
	call	16693581
	ld	xwa, 7274534
	ld	xbc, 29818889
	lds32	xde, 0
	call	16423243
	stdi8	(7498), 0
	ret
SqTrSel_CaseF:
	calr	65442
	call	16693581
	stdi8	(7498), 0
	ret
PlayMode_SendStopEvent:
	ld xwa, 0x6f0026
	ld xbc, 0x1c70009
	lds32 xde, 0
	jp ApPostEvent

; SqTrSelTtl case G
SqTrSel_CaseG:
	.byte 0xc1, 0x9a, 0x8c, 0x21, 0xd8, 0x12, 0xd8, 0xca
	.byte 0x6f, 0x00, 0xd8, 0xd8, 0xb0, 0xf1, 0xd8, 0xdf
	.byte 0xb0, 0xfa, 0xd8, 0x80, 0xf2, 0x50, 0x02, 0xe2
	.byte 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20, 0xf2, 0x35
	.byte 0x2b, 0xf2, 0x34, 0xf3, 0x07, 0xf0, 0xe0, 0xd8
SqTrSel_CaseG_JumpTable:
	; --- Jump table entries + 4 register-save call thunks ---
	jrl CDlikeSwTtl_SongBit1Check
	jrl CDlikeSwTtl_DocBitCheck
	jrl CDlikeSwTtl_PdBitCheck
SqTrSel_CaseG_Thunk1:
	push xde
	push xhl
	push xix
	push xiz
	call PlayMode_SendCommand6C
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret
SqTrSel_CaseG_Thunk2:
	push xde
	push xhl
	push xix
	push xiz
	call PlayMode_SendCommand6C
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret
SqTrSel_CaseG_Thunk3:
	push xde
	push xhl
	push xix
	push xiz
	call SongMode_StartPlayback
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret
SqTrSel_CaseG_Thunk4:
	push xde
	push xhl
	push xix
	push xiz
	call PartFormat_StartPlayback
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret


PlayMode_CheckAndAbort:
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x72, 0xb0, 0xf6, 0x1d
	.byte 0xab, 0xb7, 0xfe, 0xdb, 0x33, 0x00, 0xb0, 0xf6
	.byte 0x1e, 0x10, 0xff, 0x1d, 0x4d, 0xb9, 0xfe, 0x40
	.byte 0x26, 0x00, 0x6f, 0x00, 0x41, 0x09, 0x00, 0xc7
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x4b, 0x99, 0xfa, 0x0e
PlayMode_SwitchToModeAndNotify:
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ldw	wa, 139
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	stdi8	(32422), 35
	ldw	wa, 238
	jp	16355504
DispatchHandler_ConditionalJump:
	jr	t, 0x08

DispatchHandler_JumpToSubHandler:
	jr DispatchHandler_CallResolve

DispatchHandler_JumpSub:
	jr DispatchHandler_CallNodeInsert

DispatchHandler_SubJumpTable:
	jr DispatchHandler_CallSlotResolve
	jr DispatchHandler_StoreNodePtr
	call DispatchHandler_InitAllSlots
	ret

DispatchHandler_CallResolve:
	call DispatchHandler_ResolveSlot
	ret

DispatchHandler_CallNodeInsert:
	call SeqNode_InsertAtPosition
	ret

DispatchHandler_CallSlotResolve:
	call SeqNode_ResolveSlotPtr
	ret

DispatchHandler_StoreNodePtr:
	ld xhl, 0x110a
	push xde
	ldda32 xde, (7514)
	ld (xhl), xde
	pop xde
	ret

DispatchHandler_InitAllSlots:
	ld xhl, 0x110a
	push xde
	ldda32 xde, (7514)
	ld (xhl), xde
	pop xde
	lds iy, 1
	call SeqNode_ResolveSlotPtr
	stdi16 (0xf22f), 1
	ldda32 xiy, (4349)
	xor xhl, xhl
	lds de, 2
	ldw_d16 xbc, (0x286d)
	stda16 (0xf231), xbc
	dec 1, bc

SeqSlot_InitEntryLoop:
	andmi8 (xiy), 0x7f
	ld (xiy + 1), hl
	ld (xiy + 3), de
	ld (xiy + 5), 0x82
	inc 1, hl
	inc 1, de
	add xiy, 0x100
	djnz xbc, SeqSlot_InitEntryLoop
	andmi8 (xiy), 0x7f
	ld (xiy + 1), hl
	ld (xiy + 5), 0x82
	ldw (xiy + 3), 0xffff
	ld xhl, 0xf250
	ldw bc, 0x10

SeqSlot_ClearF250Loop:
	ld (xhl), 0x0
	ldw (xhl + 1), 0xffff
	add xhl, 0x3
	djnz xbc, SeqSlot_ClearF250Loop
	ld xhl, 0xc9e
	ldw bc, 0x10

SeqSlot_ClearC9ELoop:
	ldw (xhl), 0xffff
	inc 2, xhl
	djnz xbc, SeqSlot_ClearC9ELoop
	ld xhl, 0xcae
	ldw bc, 0x10

SeqSlot_InitCAELoop:
	ld (xhl), 0x5
	inc 1, xhl
	djnz xbc, SeqSlot_InitCAELoop
	ld xhl, 0xf1f8
	ldw bc, 0x10

SeqSlot_ClearF1F8Loop:
	ldw (xhl), 0xffff
	inc 2, xhl
	djnz xbc, SeqSlot_ClearF1F8Loop
	ld xhl, 0xf218
	ldw bc, 0x10

SeqSlot_InitF218Loop:
	ld (xhl), 0x5
	inc 1, xhl
	djnz xbc, SeqSlot_InitF218Loop
	ret

DispatchHandler_ResolveSlot:
	push xde
	ld xhl, 0x110a
	push xde
	ldda32 xde, (7514)
	ld (xhl), xde
	pop xde
	ldw_d16 xiy, (0xf22f)
	cp iy, 0xffff
	jr z, DispatchResolve_ReturnFail
	ldda32 xde, (4349)
	push xde
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, (4349)
	ld wa, (xhl + 3)
	stda16 (0xf22f), xwa
	ld ix, iy
	cp wa, 0xffff
	jr z, DispatchResolve_MarkCurrent
	ld iy, wa
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, (4349)
	ldw (xhl + 1), 0x0

DispatchResolve_MarkCurrent:
	ld iy, ix
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, (4349)
	ormi8 (xhl), 0x80
	decdi16 1, 0xf231
	pop xde
	stda32 4349, xde
	ldb w, 0x0
	pop xde
	ret

DispatchResolve_ReturnFail:
	ldb w, 0xff
	pop xde
	ret

SeqNode_InsertAtPosition:
	ld xhl, 0x110a
	push xde
	ldda32 xde, (7514)
	ld (xhl), xde
	pop xde
	stda16 (3302), xwa
	ldw_d16 xbc, (0xf22f)
	stda16 (0xf22f), xiy
	xor wa, wa
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, (4349)
	ld ix, (xhl + 1)
	ld de, ix
	cps ix, 0
	jr z, SeqNodeInsert_EmptyList
	ld iy, ix
	ldw (xhl + 1), 0x0
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ldda32 xhl, (4349)
	ld iy, (xhl + 3)

SeqNodeInsert_TraverseNext:
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ldda32 xhl, (4349)
	ld iy, (xhl + 3)
	cp iy, 0xffff
	jr z, SeqNodeInsert_LinkHead

SeqNodeInsert_UnmarkAndCount:
	andmi8 (xhl), 0x7f
	ld (xhl + 5), 0x82
	inc 1, wa
	cpda16 xwa, 3302
	jr nz, SeqNodeInsert_TraverseNext
	dec 1, wa

SeqNodeInsert_LinkPrev:
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, (4349)
	ld (xhl + 1), de

SeqNodeInsert_LinkHead:
	cps de, 0
	jr z, SeqNodeInsert_Finalize
	pushw iy
	ld iy, de
	call SeqNode_ResolveSlotPtr
	popw iy
	ldda32 xhl, (4349)
	ld (xhl + 3), iy

SeqNodeInsert_Finalize:
	ld iy, ix
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, (4349)
	andmi8 (xhl), 0x7f
	ld (xhl + 5), 0x82
	ld (xhl + 3), bc
	ld iy, bc
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, (4349)
	ld (xhl + 1), ix
	inc 1, wa
	adddm16 0xf231, xwa
	ret

SeqNodeInsert_EmptyList:
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ldda32 xhl, (4349)
	ld iy, (xhl + 3)
	cp iy, 0xffff
	jr nz, SeqNodeInsert_UnmarkAndCount
	stdi16 (3302), 0
	ld iy, ix
	andmi8 (xhl), 0x7f
	jr SeqNodeInsert_LinkPrev

SeqNode_ResolveSlotPtr:
	ld hl, iy
	extz xhl
	dec 1, hl
	sla xhl, 8
	addda32 xhl, 4362
	stda32 4349, xhl
	xor xhl, xhl
	ret

VoiceSlot_AssignWrapper:
	call VoiceSlot_AssignToChannel
	ret

VoiceSlot_AssignToChannel:
	pushw bc
	stda32 4353, xiy
	stb_d8 (3822), a
	ld c, w
	call VoiceSlot_ComputeWordIndex
	extz xiz
	ld xix, 0xf1f8
	xor b, b

VoiceSlot_ScanLoop:
	ldw_sri IY, 0x07, 0xf0, 0xf8
	cp iy, 0xffff
	jrl z, VoiceSlot_AllocNewSlot
	stda16 (0x28ba), xiy
	srl iz, 1
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld a, (xix + 32)
	ldto_lerp XIX, 0x38
	xor w, w
	sla iz, 1
	stda16 (0x28bc), xwa
	ld xix, 0xc9e

VoiceSlot_FindFreeEntry:
	ldw_sri DE, 0x07, 0xf0, 0xf8
	cp de, 0xffff
	jr nz, VoiceSlot_CheckOccupied
	stw_dri IY, 0x07, 0xf0, 0xf8
	srl iz, 1
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld (xix + 32), 0x5
	ldto_lerp XIX, 0x38
	sla iz, 1
	jr VoiceSlot_FindFreeEntry

VoiceSlot_CheckOccupied:
	srl iz, 1
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld iy, (xix + 32)
	ldto_lerp XIX, 0x38
	sla iz, 1
	and iy, 0xff
	stda16 (0x28b8), xiy
	ld xix, 0xf1f8
	srl iz, 1
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld a, (xix + 32)
	ldto_lerp XIX, 0x38
	xor w, w
	sla iz, 1
	add wa, bc
	cp wa, 0xff
	jr ugt, VoiceSlot_Overflow
	ldw_sri IY, 0x07, 0xf0, 0xf8
	stda16 (0x289f), xiy
	stda16 (0x28b6), xwa
	srl iz, 1
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld (xix + 32), a
	ldto_lerp XIX, 0x38
	sla iz, 1
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call Scoop_EventHandler_Scroll
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	call VoiceSlot_InitAndProcess
	xor w, w
	popw bc
	ret

VoiceSlot_Overflow:
	sub wa, 0xfb
	stda16 (0x28b6), xwa
	pushw de
	call DispatchHandler_ResolveSlot
	popw de
	cp w, 0xff
	jr z, VoiceSlot_SendErrorAndReset
	ld iy, ix
	ld xix, 0xf1f8
	srl iz, 1
	ldw_d16 xwa, (0x28b6)
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld (xix + 32), a
	ldto_lerp XIX, 0x38
	sla iz, 1
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, (4349)
	ldw (xhl + 3), 0xffff
	stda16 (0x289f), xiy
	ld wa, iy
	pushw de
	ld xix, 0xf1f8
	ldw_sri DE, 0x07, 0xf0, 0xf8
	ld (xhl + 1), de
	stw_dri WA, 0x07, 0xf0, 0xf8
	ld iy, de
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, (4349)
	ld (xhl + 3), wa
	popw de
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call Scoop_EventHandler_Scroll
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	call VoiceSlot_InitAndProcess
	xor w, w
	popw bc
	ret

VoiceSlot_SendErrorAndReset:
	ldb w, 0x68

	.byte 0x1d, 0xd2, 0xb5, 0xfe	; call MIDI_SendSysExCmd (v7 addr)

	.byte 0xc1, 0x1c, 0xe3, 0x3c, 0x6f	; anddi8 (0xe3e2), 111 (v7 patched)

	.byte 0xf1, 0xa6, 0x7e, 0x00, 0x0f	; stdi8 (0x7f42), 15 (v7 patched)

	.byte 0xf1, 0x16, 0xe3, 0x02, 0xee, 0x40	; stdi16 (0xe3dc), 0x40ee (v7 patched)

	popw bc

	ret



VoiceSlot_AllocNewSlot:
	push xix
	call DispatchHandler_ResolveSlot
	ld iy, ix
	pop xix
	cp w, 0xff
	jr z, VoiceSlot_SendErrorAndReset
	stw_dri IY, 0x07, 0xf0, 0xf8
	srl iz, 1
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld (xix + 32), 0x5
	ldto_lerp XIX, 0x38
	sla iz, 1
	pushw wa
	pushw iz
	push xix
	ldb_d8 a, (3822)
	dec 1, a
	ld w, a
	sla a, 1
	add a, w
	xor w, w
	ld iz, wa
	ld xix, 0xf250
	or_srib_im 0x07, 0xf0, 0xf8, 0x80
	ldfr_lerp XIX, 0x38
	stb_dri D, 0x07, 0xf0, 0xf8
	stw_dri IY, 0x39, 0x01, 0x00
	ldto_lerp XIX, 0x38
	pop xix
	popw iz
	popw wa
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, (4349)
	ldw (xhl + 1), 0x0
	ldw (xhl + 3), 0xffff
	jrl VoiceSlot_ScanLoop


; --- SMF Playback & Sequencer ---
