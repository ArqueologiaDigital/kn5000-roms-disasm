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
	lda xix, (MiddleFuncCall_DispatchData:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

MiddleFuncCall_DispatchData:
	.byte 0xf1, 0xa4
MiddleFuncCall_DispatchData_Code:
	pushw	wa
	ld	xiy, 1044134714
	call	16279416
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jrl	132
	push	xde
	pushw	0
	pushw	4441
	call	16713584
	inc	8, xsp
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15859911
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	105
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15855126
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	91
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15855165
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	77
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15855680
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	63
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15855698
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	49
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15855243
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	35
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15855321
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	21
	call	16635550
	jr	15
	calr	60449
	jr	10
	call	16553566
	jr	4
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
	lda xbc, (0x0ab000:24)
	ld wa, (xsp + 4)
	extz xwa
	sll xwa, 11
	add xbc, xwa
	lda_dri XBC, 0xe5, 0x00, 0x01
	ld wa, (xsp + 4)
	mul wa, 0x15
	lda xix, (6906:16)
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
	lda xbc, (6906:16)
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
	ld xwa, (7116:16)
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
	ld xwa, (7116:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr c, SeqSongName_RefreshLoop
	jrl SongBank_ReturnZero

SongBank_HandleNextPrev:
	ld wa, (7120:16)
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
	ld de, (7120:16)
	cp iz, de
	jr z, SongBank_ReturnZero
	extz xde
	ld xwa, (7116:16)
	ld xbc, 0x1e70003
	call ApPostEvent
	ld wa, iz
	ld bc, iz
	lds de, 1
	calr SongBank_ComputeTableOfs
	ld xde, xhl
	ld xwa, (7116:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	ld bc, (7120:16)
	ld wa, bc
	lds de, 1
	calr SongBank_ComputeTableOfs
	ld xde, xhl
	ld xwa, (7116:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	stb_erp A, 0xf8
	ld (7500:16), a
	ld wa, (7120:16)
	ld (7502:16), a
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
	lda xix, (4421:16)
	ld wa, (xsp + 4)
	extz xwa
	add xix, xwa
	ld wa, (xsp + 4)
	mul wa, 0x7
	lda xhl, (7122:16)
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
	lda	xbc, (7122:16)
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
	ld xwa, (7192:16)
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
	ld xwa, (7192:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr c, SeqSongMem_RefreshLoop
	jr SongBank_EventHandler_Return

SongBank_HandleNextPrevAlt:
	ld wa, (7196:16)
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
	ld de, (7196:16)
	cp iz, de
	jr z, SongBank_EventHandler_Return
	extz xde
	ld xwa, (7192:16)
	ld xbc, 0x1e70003
	call ApPostEvent
	ld wa, iz
	ld bc, iz
	lds de, 0
	calr SongBank_LookupTableEntry
	ld xde, xhl
	ld xwa, (7192:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	ld bc, (7196:16)
	ld wa, bc
	lds de, 0
	calr SongBank_LookupTableEntry
	ld xde, xhl
	ld xwa, (7192:16)
	ld xbc, 0x1c0000f

SeqSongMem_PostAndReturn:
	call ApPostEvent

SongBank_EventHandler_Return:
	lds32 xhl, 0
	popw iz
	ret

CDlikeSwTtl_DispatchData:
	lds32 xhl, 0
	ret
	lds32 xhl, 0
	ret
	bitda 0, (0x0ce0)
	jr nz, .Lc_f22901
	ld a, (0x0cdf:16)
	inc 2,A
	extz WA
	ld DE,WA
	extz XDE
	add XDE,0x00010000
	ld XWA,0x008b0004
	ld XBC,0x01e0008d
	jr t, .Lc_f2291d
.Lc_f22901:
	ld a, (0x0cdf:16)
	dec 6,A
	extz WA
	ld DE,WA
	extz XDE
	add XDE,0x00010000
	ld XWA,0x008b0004
	ld XBC,0x01e0008d
.Lc_f2291d:
	jp ApPostEvent
	ld XWA,0x008b0003
	ld XBC,0x01e0009c
	lds32 xde, 1
	jp ApPostEvent
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
	lda xbc, (SepaOut_Config_0_0x222:24)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

SeqInit_PostDispatchEvent:
	ld a, (0x28a4:16)
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
	ld	a, (35994:16)
	extz	wa
	sub	wa, 111
	cps	wa, 0
	ret	lt
	cps	wa, 7
	ret	gt
	add	wa, wa
	lda	xix, (14811728:24)
	ld_rrw	wa, xix, wa
	lda	xix, (15870773:24)
	jp_rr	8, xix, wa
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
	cpdi8 (0x8c9a), 0x72
	ret Z
	call 0xfeb7ab
	bit 0x00,HL
	ret Z
	calr SeqRecPlay_DisableBoth
	call 0xfeb94d
	ld XWA,0x006f0026
	ld XBC,0x01c70009
	lds32 xde, 0
	call ApPostEvent
	ret
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
	ld xde, (7514:16)
	ld (xhl), xde
	pop xde
	ret

DispatchHandler_InitAllSlots:
	ld xhl, 0x110a
	push xde
	ld xde, (7514:16)
	ld (xhl), xde
	pop xde
	lds iy, 1
	call SeqNode_ResolveSlotPtr
	stdi16 (0xf22f), 1
	ld xiy, (4349:16)
	xor xhl, xhl
	lds de, 2
	ld bc, (0x286d:16)
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
	ld xde, (7514:16)
	ld (xhl), xde
	pop xde
	ld iy, (0xf22f:16)
	cp iy, 0xffff
	jr z, DispatchResolve_ReturnFail
	ld xde, (4349:16)
	push xde
	call SeqNode_ResolveSlotPtr
	ld xhl, (4349:16)
	ld wa, (xhl + 3)
	stda16 (0xf22f), xwa
	ld ix, iy
	cp wa, 0xffff
	jr z, DispatchResolve_MarkCurrent
	ld iy, wa
	call SeqNode_ResolveSlotPtr
	ld xhl, (4349:16)
	ldw (xhl + 1), 0x0

DispatchResolve_MarkCurrent:
	ld iy, ix
	call SeqNode_ResolveSlotPtr
	ld xhl, (4349:16)
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
	ld xde, (7514:16)
	ld (xhl), xde
	pop xde
	stda16 (3302), xwa
	ld bc, (0xf22f:16)
	stda16 (0xf22f), xiy
	xor wa, wa
	call SeqNode_ResolveSlotPtr
	ld xhl, (4349:16)
	ld ix, (xhl + 1)
	ld de, ix
	cps ix, 0
	jr z, SeqNodeInsert_EmptyList
	ld iy, ix
	ldw (xhl + 1), 0x0
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ld xhl, (4349:16)
	ld iy, (xhl + 3)

SeqNodeInsert_TraverseNext:
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ld xhl, (4349:16)
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
	ld xhl, (4349:16)
	ld (xhl + 1), de

SeqNodeInsert_LinkHead:
	cps de, 0
	jr z, SeqNodeInsert_Finalize
	pushw iy
	ld iy, de
	call SeqNode_ResolveSlotPtr
	popw iy
	ld xhl, (4349:16)
	ld (xhl + 3), iy

SeqNodeInsert_Finalize:
	ld iy, ix
	call SeqNode_ResolveSlotPtr
	ld xhl, (4349:16)
	andmi8 (xhl), 0x7f
	ld (xhl + 5), 0x82
	ld (xhl + 3), bc
	ld iy, bc
	call SeqNode_ResolveSlotPtr
	ld xhl, (4349:16)
	ld (xhl + 1), ix
	inc 1, wa
	adddm16 0xf231, xwa
	ret

SeqNodeInsert_EmptyList:
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ld xhl, (4349:16)
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
	ld (3822:16), a
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
	ld wa, (0x28b6:16)
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld (xix + 32), a
	ldto_lerp XIX, 0x38
	sla iz, 1
	call SeqNode_ResolveSlotPtr
	ld xhl, (4349:16)
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
	ld xhl, (4349:16)
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
	ld a, (3822:16)
	dec 1, a
	ld w, a
	sla a, 1
	add a, w
	xor w, w
	ld iz, wa
	ld xix, 0xf250
	or_srib_im 0x07, 0xf0, 0xf8, 0x80
	ldfr_lerp XIX, 0x38
	lda_dri XIX, 0x07, 0xf0, 0xf8
	stw_dri IY, 0x39, 0x01, 0x00
	ldto_lerp XIX, 0x38
	pop xix
	popw iz
	popw wa
	call SeqNode_ResolveSlotPtr
	ld xhl, (4349:16)
	ldw (xhl + 1), 0x0
	ldw (xhl + 3), 0xffff
	jrl VoiceSlot_ScanLoop


; --- SMF Playback & Sequencer ---
