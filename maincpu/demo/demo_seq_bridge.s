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
	cp xbc, 0x1E70018
	jrl z, SqTrSel_CaseB
	sub xwa, 0x1E70000
	cp xwa, 0x0
	jrl lt, SqTrSel_CaseC
	cp xwa, 0xC
	jrl gt, SqTrSel_CaseC
	add xwa, xwa
	add xwa, 0xE201E8
	ld wa, (xwa)
	lda_24 xix, 0xf2258e
	jp_dri 8, 0x07, 0xF0, 0xE0

MiddleFuncCall_DispatchData:
	.byte 0xf1, 0xa4
	.ascii "(E:;<>"
	call	16280444
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jrl	132
	push	xde
	pushw	0
	pushw	4441
	call	16715597
	inc	8, xsp
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15859953
	.ascii "^\\[Zhi:;<>"
	.byte 0x1d, 0x40, 0xee, 0xf1, 0x5e, 0x5c
	.ascii "[Zh[:;<>"
	.byte 0x1d, 0x67, 0xee, 0xf1
	.ascii "^\\[ZhM:;<>"
	.byte 0x1d, 0x6a
	.byte 0xf0, 0xf1
	.ascii "^\\[Zh?:;<>"
	.byte 0x1d, 0x7c, 0xf0, 0xf1
	.ascii "^\\[Zh1:;<>"
	.byte 0x1d, 0xb5, 0xee, 0xf1, 0x5e, 0x5c
	.ascii "[Zh#:;<>"
	call	15855363
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	21
	call	16637551
	jr	15
	calr	60449
	jr	10
	call	16555561
	jr	4

; SqTrSelTtl case B
SqTrSel_CaseB:
	call SeqFile_ParseHeader

; SqTrSelTtl case C
SqTrSel_CaseC:
	lds32 xhl, 0
	ret

SongBank_ComputeTableOfs:
	dec 2, xsp
	push xiz
	ld hl, bc
	ld (xsp + 4), wa
	lda_24 xbc, 0x0ab000
	ld wa, (xsp + 4)
	extz xwa
	sll xwa, 11
	add xbc, xwa
	st_dri3b A, 0xE5, 0x00, 0x01
	ld wa, (xsp + 4)
	mul wa, 0x15
	ldada xix, 6906
	ld iz, wa
	extz xiz
	add xiz, xix
	lda_dpi XSP, 0xF8
	cps e, 0
	jr z, SongBank_CopyNameAndFinish
	cpw (xsp + 4), 0x9
	jr nz, SongBank_FormatTwoDigit
	stib_dpi 0xF8, 0x31
	ld (xiz), 0x30
	jr SongBank_AppendColon

SongBank_FormatTwoDigit:
	stib_dpi 0xF8, 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

SongBank_AppendColon:
	inc 1, xiz
	stib_dpi 0xF8, 0x3A

SongBank_CopyNameAndFinish:
	ld xwa, xiz
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	ld (xiz + 16), 0x0
	ld wa, (xsp + 4)
	mul wa, 0x15
	ldada xbc, 6906
	extz xwa
	add xwa, xbc
	ld xhl, xwa
	pop xiz
	inc 2, xsp
	ret

SeqSongNameFunc:
	pushw iz
	cp xbc, 0x1E70003
	jrl z, SongBank_ReturnZero
	cp xbc, 0x1C00018
	jr z, SongBank_HandleNextPrev
	cp xbc, 0x1C00017
	jr z, SongBank_HandleNextPrev
	cp xbc, 0x1C0000B
	jr z, SeqSongName_RefreshAll
	cp xbc, 0x1E70002
	jrl nz, SongBank_ReturnZero
	stda32 7116, xde
	ld8_24 a, 0x00ffe3
	extz wa
	stda16 7120, xwa
	ld de, wa
	extz xde
	ldda32 xwa, 7116
	ld xbc, 0x1E70003
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
	ldda32 xwa, 7116
	ld xbc, 0x1C0000F
	call ApPostEvent
	inc 1, iz
	cp iz, 0xA
	jr c, SeqSongName_RefreshLoop
	jrl SongBank_ReturnZero

SongBank_HandleNextPrev:
	ldda16 xwa, 7120
	ld iz, wa
	cp xbc, 0x1C00018
	jr nz, SeqSongName_CheckPrev
	cp wa, 0x9
	jr nc, SongBank_StoreCurrentSong
	inc 1, wa
	jr SeqSongName_StoreCurrent

SeqSongName_CheckPrev:
	cp xbc, 0x1C00017
	jr nz, SongBank_StoreCurrentSong
	cps wa, 0
	jr z, SongBank_StoreCurrentSong
	dec 1, wa

SeqSongName_StoreCurrent:
	stda16 7120, xwa

SongBank_StoreCurrentSong:
	ldda16 xde, 7120
	cp iz, de
	jr z, SongBank_ReturnZero
	extz xde
	ldda32 xwa, 7116
	ld xbc, 0x1E70003
	call ApPostEvent
	ld wa, iz
	ld bc, iz
	lds de, 1
	calr SongBank_ComputeTableOfs
	ld xde, xhl
	ldda32 xwa, 7116
	ld xbc, 0x1C0000F
	call ApPostEvent
	ldda16 xbc, 7120
	ld wa, bc
	lds de, 1
	calr SongBank_ComputeTableOfs
	ld xde, xhl
	ldda32 xwa, 7116
	ld xbc, 0x1C0000F
	call ApPostEvent
	ldto_berp A, 0xF8
	stda8 7500, a
	ldda16 xwa, 7120
	stda8 7502, a
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
	ldada xix, 4421
	ld wa, (xsp + 4)
	extz xwa
	add xix, xwa
	ld wa, (xsp + 4)
	mul wa, 0x7
	ldada xhl, 7122
	ld iz, wa
	extz xiz
	add xiz, xhl
	lda_dpi XHL, 0xF8
	cps e, 0
	jr z, SongBankLookup_BuildAudioCmd
	cpw (xsp + 4), 0x9
	jr nz, SongBankLookup_FormatTwoDigit
	stib_dpi 0xF8, 0x31
	ld (xiz), 0x30
	jr SongBankLookup_AppendColon

SongBankLookup_FormatTwoDigit:
	stib_dpi 0xF8, 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

SongBankLookup_AppendColon:
	inc 1, xiz

SongBankLookup_BuildAudioCmd:
	stib_dpi 0xF8, 0x3A
	ld a, (xix)
	extz wa
	pushw wa
	pushw 0xE2
	pushw 0x202
	push xiz
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	ld (xiz + 4), 0x0
	ld wa, (xsp + 4)
	mul wa, 0x7
	ldada xbc, 7122
	extz xwa
	add xwa, xbc
	ld xhl, xwa
	pop xiz
	inc 2, xsp
	ret

SeqSongMemoryFunc:
	pushw iz
	cp xbc, 0x1E70003
	jrl z, SongBank_EventHandler_Return
	cp xbc, 0x1C00018
	jr z, SongBank_HandleNextPrevAlt
	cp xbc, 0x1C00017
	jr z, SongBank_HandleNextPrevAlt
	cp xbc, 0x1C0000B
	jr z, SeqSongMem_RefreshAll
	cp xbc, 0x1E70002
	jrl nz, SongBank_EventHandler_Return
	stda32 7192, xde
	ld8_24 a, 0x00ffe3
	extz wa
	stda16 7196, xwa
	ld de, wa
	extz xde
	ldda32 xwa, 7192
	ld xbc, 0x1E70003
	jrl SeqSongMem_PostAndReturn

SeqSongMem_RefreshAll:
	lds iz, 0

SeqSongMem_RefreshLoop:
	ld wa, iz
	ld bc, iz
	lds de, 0
	calr SongBank_LookupTableEntry
	ld xde, xhl
	ldda32 xwa, 7192
	ld xbc, 0x1C0000F
	call ApPostEvent
	inc 1, iz
	cp iz, 0xA
	jr c, SeqSongMem_RefreshLoop
	jr SongBank_EventHandler_Return

SongBank_HandleNextPrevAlt:
	ldda16 xwa, 7196
	ld iz, wa
	cp xbc, 0x1C00018
	jr nz, SeqSongMem_CheckPrev
	cp wa, 0x9
	jr nc, SongBank_EventCompare
	inc 1, wa
	jr SeqSongMem_StoreCurrent

SeqSongMem_CheckPrev:
	cp xbc, 0x1C00017
	jr nz, SongBank_EventCompare
	cps wa, 0
	jr z, SongBank_EventCompare
	dec 1, wa

SeqSongMem_StoreCurrent:
	stda16 7196, xwa

SongBank_EventCompare:
	ldda16 xde, 7196
	cp iz, de
	jr z, SongBank_EventHandler_Return
	extz xde
	ldda32 xwa, 7192
	ld xbc, 0x1E70003
	call ApPostEvent
	ld wa, iz
	ld bc, iz
	lds de, 0
	calr SongBank_LookupTableEntry
	ld xde, xhl
	ldda32 xwa, 7192
	ld xbc, 0x1C0000F
	call ApPostEvent
	ldda16 xbc, 7196
	ld wa, bc
	lds de, 0
	calr SongBank_LookupTableEntry
	ld xde, xhl
	ldda32 xwa, 7192
	ld xbc, 0x1C0000F

SeqSongMem_PostAndReturn:
	call ApPostEvent

SongBank_EventHandler_Return:
	lds32 xhl, 0
	popw iz
	ret

CDlikeSwTtl_DispatchData:
	lds32	xhl, 0
	ret
	lds32	xhl, 0
	ret
	bitda	0, 3296
	jr	nz, 30
	ldda8	a, 3295
	inc	2, a
	extz	wa
	ld	de, wa
	extz	xde
	add	xde, 65536
	ld	xwa, 9109508
	ld	xbc, 31457421
	jr	28
	ldda8	a, 3295
	dec	6, a
	extz	wa
	ld	de, wa
	extz	xde
	add	xde, 65536
	ld	xwa, 9109508
	ld	xbc, 31457421
	jp	16424280
	ld	xwa, 9109507
	ld	xbc, 31457436
	lds32	xde, 1
	jp	16424280

CDlikeSwTtl_SendStartEvt:
	ld xwa, 0x8B0003
	ld xbc, 0x1E0009C
	lds32 xde, 0
	jp ApPostEvent

CDlikeSwTtl_SendResetEvent:
	ld xwa, 0x8B0000
	ld xbc, 0x1C00001
	lds32 xde, 0
	jp ApPostEvent

CDlikeSwTtl_SendStopEvtD:
	ld xwa, 0x8B000D
	ld xbc, 0x1C00001
	lds32 xde, 0
	jp ApPostEvent

CDlikeSwTtl_SendEvent8C_0:
	ld xwa, 0x8C0000
	ld xbc, 0x1C00001
	lds32 xde, 0
	jp ApPostEvent

CDlikeSwTtl_SendEvent8C_A:
	ld xwa, 0x8C000A
	ld xbc, 0x1C00001
	lds32 xde, 0
	jp ApPostEvent

CDlikeSwTtl_SendEvent8C_13:
	ld xwa, 0x8C0013
	ld xbc, 0x1C00001
	lds32 xde, 0
	jp ApPostEvent

CDlikeSwTtl_SetRecordAndNotify:
	sti8_24 0x021090, 0x01
	ld xwa, 0xE1000B
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xE2000B
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xE3000B
	ld xbc, 0x1C0000C
	lds32 xde, 0
	jp ApPostEvent

SeqInit_PostEventSequence:
	sti8_24 0x021090, 0x00
	ld xwa, 0xE1000B
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xE2000B
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xE3000B
	ld xbc, 0x1C0000C
	lds32 xde, 0
	jp ApPostEvent

SeqInit_LookupDispatchEntry:
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe20208
	ld_sril3 XHL, 0x07, 0xE4, 0xE0
	ret

SeqInit_PostDispatchEvent:
	ldda8 a, 10404
	extz wa
	calr SeqInit_LookupDispatchEntry
	ld xwa, xhl
	ld xbc, 0x1E0004D
	lds32 xde, 1
	jp ApDeliveryEvent

SeqInit_FinalEvent:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001B
	lds32 xde, 0
	jp ApPostEvent

SeqRecPlay_EnableRecordOnly:
	sti8_24 0x021092, 0x01
	sti8_24 0x021094, 0x00
	ld xwa, 0x6F0025
	ld xbc, 0x1E000A7
	lds32 xde, 1
	call ApPostEvent
	lds32 xde, 0
	ld8_24 e, 0x021094
	ld xwa, 0x6F0024
	ld xbc, 0x1E000A7
	jp ApPostEvent

SeqRecPlay_EnablePlayOnly:
	sti8_24 0x021092, 0x00
	sti8_24 0x021094, 0x01
	ld xwa, 0x6F0025
	ld xbc, 0x1E000A7
	lds32 xde, 0
	call ApPostEvent
	lds32 xde, 0
	ld8_24 e, 0x021094
	ld xwa, 0x6F0024
	ld xbc, 0x1E000A7
	jp ApPostEvent

SeqRecPlay_DisableBoth:
	sti8_24 0x021092, 0x00
	sti8_24 0x021094, 0x00
	ld xwa, 0x6F0025
	ld xbc, 0x1E000A7
	lds32 xde, 0
	call ApPostEvent
	lds32 xde, 0
	ld8_24 e, 0x021094
	ld xwa, 0x6F0024
	ld xbc, 0x1E000A7
	jp ApPostEvent

; SqTrSelTtl case D
SqTrSel_CaseD:
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	stdi8 7498, 0
	ret

; SqTrSelTtl case E
SqTrSel_CaseE:
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld xwa, 0x6F0026
	ld xbc, 0x1C70009
	lds32 xde, 0
	call ApPostEvent
	stdi8 7498, 0
	ret

; SqTrSelTtl case F
SqTrSel_CaseF:
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	stdi8 7498, 0
	ret

PlayMode_SendStopEvent:
	ld xwa, 0x6F0026
	ld xbc, 0x1C70009
	lds32 xde, 0
	jp ApPostEvent

; SqTrSelTtl case G
SqTrSel_CaseG:
	ldda8 a, 36150
	extz wa
	sub wa, 0x6F
	cps wa, 0
	ret lt
	cps wa, 7
	ret gt
	add wa, wa
	lda_24 xix, 0xe20250
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf22b5f
	jp_dri 8, 0x07, 0xF0, 0xE0

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
	cpdi8 36150, 114
	ret z
	call SeqState_GetFlags
	bit 0, hl
	ret z
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld xwa, 0x6F0026
	ld xbc, 0x1C70009
	lds32 xde, 0
	call ApPostEvent
	ret

PlayMode_SwitchToModeAndNotify:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call ApPostEvent
	ldw wa, 0x8B
	call UI_PostModeChangeEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call ApPostEvent
	stdi8 32578, 35
	ldw wa, 0xEE
	jp SoundCtrl_SendCommand
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
	ld xhl, 0x110A
	push xde
	ldda32 xde, 7514
	ld (xhl), xde
	pop xde
	ret

DispatchHandler_InitAllSlots:
	ld xhl, 0x110A
	push xde
	ldda32 xde, 7514
	ld (xhl), xde
	pop xde
	lds iy, 1
	call SeqNode_ResolveSlotPtr
	stdi16 61999, 1
	ldda32 xiy, 4349
	xor xhl, xhl
	lds de, 2
	ldda16 xbc, 10349
	stda16 62001, xbc
	dec 1, bc

SeqSlot_InitEntryLoop:
	andmi8 (xiy), 0x7F
	ld (xiy + 1), hl
	ld (xiy + 3), de
	ld (xiy + 5), 0x82
	inc 1, hl
	inc 1, de
	add xiy, 0x100
	djnz xbc, SeqSlot_InitEntryLoop
	andmi8 (xiy), 0x7F
	ld (xiy + 1), hl
	ld (xiy + 5), 0x82
	ldw (xiy + 3), 0xFFFF
	ld xhl, 0xF250
	ldw bc, 0x10

SeqSlot_ClearF250Loop:
	ld (xhl), 0x0
	ldw (xhl + 1), 0xFFFF
	add xhl, 0x3
	djnz xbc, SeqSlot_ClearF250Loop
	ld xhl, 0xC9E
	ldw bc, 0x10

SeqSlot_ClearC9ELoop:
	ldw (xhl), 0xFFFF
	inc 2, xhl
	djnz xbc, SeqSlot_ClearC9ELoop
	ld xhl, 0xCAE
	ldw bc, 0x10

SeqSlot_InitCAELoop:
	ld (xhl), 0x5
	inc 1, xhl
	djnz xbc, SeqSlot_InitCAELoop
	ld xhl, 0xF1F8
	ldw bc, 0x10

SeqSlot_ClearF1F8Loop:
	ldw (xhl), 0xFFFF
	inc 2, xhl
	djnz xbc, SeqSlot_ClearF1F8Loop
	ld xhl, 0xF218
	ldw bc, 0x10

SeqSlot_InitF218Loop:
	ld (xhl), 0x5
	inc 1, xhl
	djnz xbc, SeqSlot_InitF218Loop
	ret

DispatchHandler_ResolveSlot:
	push xde
	ld xhl, 0x110A
	push xde
	ldda32 xde, 7514
	ld (xhl), xde
	pop xde
	ldda16 xiy, 61999
	cp iy, 0xFFFF
	jr z, DispatchResolve_ReturnFail
	ldda32 xde, 4349
	push xde
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
	ld wa, (xhl + 3)
	stda16 61999, xwa
	ld ix, iy
	cp wa, 0xFFFF
	jr z, DispatchResolve_MarkCurrent
	ld iy, wa
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
	ldw (xhl + 1), 0x0

DispatchResolve_MarkCurrent:
	ld iy, ix
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
	ormi8 (xhl), 0x80
	decdi16 1, 62001
	pop xde
	stda32 4349, xde
	ldb w, 0x0
	pop xde
	ret

DispatchResolve_ReturnFail:
	ldb w, 0xFF
	pop xde
	ret

SeqNode_InsertAtPosition:
	ld xhl, 0x110A
	push xde
	ldda32 xde, 7514
	ld (xhl), xde
	pop xde
	stda16 3302, xwa
	ldda16 xbc, 61999
	stda16 61999, xiy
	xor wa, wa
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
	ld ix, (xhl + 1)
	ld de, ix
	cps ix, 0
	jr z, SeqNodeInsert_EmptyList
	ld iy, ix
	ldw (xhl + 1), 0x0
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ldda32 xhl, 4349
	ld iy, (xhl + 3)

SeqNodeInsert_TraverseNext:
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ldda32 xhl, 4349
	ld iy, (xhl + 3)
	cp iy, 0xFFFF
	jr z, SeqNodeInsert_LinkHead

SeqNodeInsert_UnmarkAndCount:
	andmi8 (xhl), 0x7F
	ld (xhl + 5), 0x82
	inc 1, wa
	cpda16 xwa, 3302
	jr nz, SeqNodeInsert_TraverseNext
	dec 1, wa

SeqNodeInsert_LinkPrev:
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
	ld (xhl + 1), de

SeqNodeInsert_LinkHead:
	cps de, 0
	jr z, SeqNodeInsert_Finalize
	pushw iy
	ld iy, de
	call SeqNode_ResolveSlotPtr
	popw iy
	ldda32 xhl, 4349
	ld (xhl + 3), iy

SeqNodeInsert_Finalize:
	ld iy, ix
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
	andmi8 (xhl), 0x7F
	ld (xhl + 5), 0x82
	ld (xhl + 3), bc
	ld iy, bc
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
	ld (xhl + 1), ix
	inc 1, wa
	adddm16 62001, xwa
	ret

SeqNodeInsert_EmptyList:
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ldda32 xhl, 4349
	ld iy, (xhl + 3)
	cp iy, 0xFFFF
	jr nz, SeqNodeInsert_UnmarkAndCount
	stdi16 3302, 0
	ld iy, ix
	andmi8 (xhl), 0x7F
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
	stda8 3822, a
	ld c, w
	call VoiceSlot_ComputeWordIndex
	extz xiz
	ld xix, 0xF1F8
	xor b, b

VoiceSlot_ScanLoop:
	ld_sriw3 IY, 0x07, 0xF0, 0xF8
	cp iy, 0xFFFF
	jrl z, VoiceSlot_AllocNewSlot
	stda16 10426, xiy
	srl iz, 1
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld a, (xix + 32)
	ldto_lerp XIX, 0x38
	xor w, w
	sla iz, 1
	stda16 10428, xwa
	ld xix, 0xC9E

VoiceSlot_FindFreeEntry:
	ld_sriw3 DE, 0x07, 0xF0, 0xF8
	cp de, 0xFFFF
	jr nz, VoiceSlot_CheckOccupied
	st_dri3w IY, 0x07, 0xF0, 0xF8
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
	and iy, 0xFF
	stda16 10424, xiy
	ld xix, 0xF1F8
	srl iz, 1
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld a, (xix + 32)
	ldto_lerp XIX, 0x38
	xor w, w
	sla iz, 1
	add wa, bc
	cp wa, 0xFF
	jr ugt, VoiceSlot_Overflow
	ld_sriw3 IY, 0x07, 0xF0, 0xF8
	stda16 10399, xiy
	stda16 10422, xwa
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
	sub wa, 0xFB
	stda16 10422, xwa
	pushw de
	call DispatchHandler_ResolveSlot
	popw de
	cp w, 0xFF
	jr z, VoiceSlot_SendErrorAndReset
	ld iy, ix
	ld xix, 0xF1F8
	srl iz, 1
	ldda16 xwa, 10422
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld (xix + 32), a
	ldto_lerp XIX, 0x38
	sla iz, 1
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
	ldw (xhl + 3), 0xFFFF
	stda16 10399, xiy
	ld wa, iy
	pushw de
	ld xix, 0xF1F8
	ld_sriw3 DE, 0x07, 0xF0, 0xF8
	ld (xhl + 1), de
	st_dri3w WA, 0x07, 0xF0, 0xF8
	ld iy, de
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
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
	call MIDI_SendSysExCmd
	anddi8 58338, 111
	stdi8 32578, 15
	stdi16 58332, 16622
	popw bc
	ret

VoiceSlot_AllocNewSlot:
	push xix
	call DispatchHandler_ResolveSlot
	ld iy, ix
	pop xix
	cp w, 0xFF
	jr z, VoiceSlot_SendErrorAndReset
	st_dri3w IY, 0x07, 0xF0, 0xF8
	srl iz, 1
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld (xix + 32), 0x5
	ldto_lerp XIX, 0x38
	sla iz, 1
	pushw wa
	pushw iz
	push xix
	ldda8 a, 3822
	dec 1, a
	ld w, a
	sla a, 1
	add a, w
	xor w, w
	ld iz, wa
	ld xix, 0xF250
	or_srib_im 0x07, 0xF0, 0xF8, 0x80
	ldfr_lerp XIX, 0x38
	st_dri3b D, 0x07, 0xF0, 0xF8
	st_dri3w IY, 0x39, 0x01, 0x00
	ldto_lerp XIX, 0x38
	pop xix
	popw iz
	popw wa
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
	ldw (xhl + 1), 0x0
	ldw (xhl + 3), 0xFFFF
	jrl VoiceSlot_ScanLoop


; --- SMF Playback & Sequencer ---
