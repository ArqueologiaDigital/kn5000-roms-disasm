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

LABEL_F2258E:
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
	jr z, LABEL_F2267E
	cpw (xsp + 4), 0x9
	jr nz, LABEL_F2266C
	stib_dpi 0xF8, 0x31
	ld (xiz), 0x30
	jr LABEL_F22678

LABEL_F2266C:
	stib_dpi 0xF8, 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

LABEL_F22678:
	inc 1, xiz
	stib_dpi 0xF8, 0x3A

LABEL_F2267E:
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
	jr z, LABEL_F226EE
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

LABEL_F226EE:
	lds iz, 0

LABEL_F226F0:
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
	jr c, LABEL_F226F0
	jrl SongBank_ReturnZero

SongBank_HandleNextPrev:
	ldda16 xwa, 7120
	ld iz, wa
	cp xbc, 0x1C00018
	jr nz, LABEL_F2272B
	cp wa, 0x9
	jr nc, SongBank_StoreCurrentSong
	inc 1, wa
	jr LABEL_F22739

LABEL_F2272B:
	cp xbc, 0x1C00017
	jr nz, SongBank_StoreCurrentSong
	cps wa, 0
	jr z, SongBank_StoreCurrentSong
	dec 1, wa

LABEL_F22739:
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
	jr z, LABEL_F227EC
	cpw (xsp + 4), 0x9
	jr nz, LABEL_F227DE
	stib_dpi 0xF8, 0x31
	ld (xiz), 0x30
	jr LABEL_F227EA

LABEL_F227DE:
	stib_dpi 0xF8, 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

LABEL_F227EA:
	inc 1, xiz

LABEL_F227EC:
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
	jr z, LABEL_F22866
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
	jrl LABEL_F228F9

LABEL_F22866:
	lds iz, 0

LABEL_F22868:
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
	jr c, LABEL_F22868
	jr SongBank_EventHandler_Return

SongBank_HandleNextPrevAlt:
	ldda16 xwa, 7196
	ld iz, wa
	cp xbc, 0x1C00018
	jr nz, LABEL_F228A2
	cp wa, 0x9
	jr nc, SongBank_EventCompare
	inc 1, wa
	jr LABEL_F228B0

LABEL_F228A2:
	cp xbc, 0x1C00017
	jr nz, SongBank_EventCompare
	cps wa, 0
	jr z, SongBank_EventCompare
	dec 1, wa

LABEL_F228B0:
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

LABEL_F228F9:
	call ApPostEvent

SongBank_EventHandler_Return:
	lds32 xhl, 0
	popw iz
	ret

LABEL_F22901:
	.byte 0xeb, 0xa8, 0x0e, 0xeb, 0xa8, 0x0e, 0xf1, 0xe0
	.byte 0x0c, 0xc8, 0x6e, 0x1e, 0xc1, 0xdf, 0x0c, 0x21
	.byte 0xc9, 0x62, 0xd8, 0x12, 0xd8, 0x8a, 0xea, 0x12
	.byte 0xea, 0xc8, 0x00, 0x00, 0x01, 0x00, 0x40, 0x04
	.byte 0x00, 0x8b, 0x00, 0x41, 0x8d, 0x00, 0xe0, 0x01
	.byte 0x68, 0x1c, 0xc1, 0xdf, 0x0c, 0x21, 0xc9, 0x6e
	.byte 0xd8, 0x12, 0xd8, 0x8a, 0xea, 0x12, 0xea, 0xc8
	.byte 0x00, 0x00, 0x01, 0x00, 0x40, 0x04, 0x00, 0x8b
	.byte 0x00, 0x41, 0x8d, 0x00, 0xe0, 0x01, 0x1b, 0x58
	.byte 0x9d, 0xfa, 0x40, 0x03, 0x00, 0x8b, 0x00, 0x41
	.byte 0x9c, 0x00, 0xe0, 0x01, 0xea, 0xa9, 0x1b, 0x58
	.byte 0x9d, 0xfa

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

LABEL_F2297B:
	ld xwa, 0x8B000D
	ld xbc, 0x1C00001
	lds32 xde, 0
	jp ApPostEvent

LABEL_F2298B:
	ld xwa, 0x8C0000
	ld xbc, 0x1C00001
	lds32 xde, 0
	jp ApPostEvent

LABEL_F2299B:
	ld xwa, 0x8C000A
	ld xbc, 0x1C00001
	lds32 xde, 0
	jp ApPostEvent

LABEL_F229AB:
	ld xwa, 0x8C0013
	ld xbc, 0x1C00001
	lds32 xde, 0
	jp ApPostEvent

LABEL_F229BB:
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

LABEL_F22A27:
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe20208
	ld_sril3 XHL, 0x07, 0xE4, 0xE0
	ret

LABEL_F22A37:
	ldda8 a, 10404
	extz wa
	calr LABEL_F22A27
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

LABEL_F22B5F:
	; --- Jump table entries + 4 register-save call thunks ---
	jrl CDlikeSwTtl_SongBit1Check
	jrl CDlikeSwTtl_DocBitCheck
	jrl CDlikeSwTtl_PdBitCheck
LABEL_F22B68:
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
LABEL_F22B75:
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
LABEL_F22B82:
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
LABEL_F22B8F:
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


LABEL_F22B9C:
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

LABEL_F22BC4:
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
LABEL_F22BF7:
	jr	t, 0x08

DispatchHandler_JumpToSubHandler:
	jr LABEL_F22C06

DispatchHandler_JumpSub:
	jr LABEL_F22C0B

DispatchHandler_SubJumpTable:
	jr LABEL_F22C10
	jr LABEL_F22C15
	call LABEL_F22C23
	ret

LABEL_F22C06:
	call DispatchHandler_ResolveSlot
	ret

LABEL_F22C0B:
	call LABEL_F22D34
	ret

LABEL_F22C10:
	call SeqNode_ResolveSlotPtr
	ret

LABEL_F22C15:
	ld xhl, 0x110A
	push xde
	ldda32 xde, 7514
	ld (xhl), xde
	pop xde
	ret

LABEL_F22C23:
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

LABEL_F22C4E:
	andmi8 (xiy), 0x7F
	ld (xiy + 1), hl
	ld (xiy + 3), de
	ld (xiy + 5), 0x82
	inc 1, hl
	inc 1, de
	add xiy, 0x100
	djnz xbc, LABEL_F22C4E
	andmi8 (xiy), 0x7F
	ld (xiy + 1), hl
	ld (xiy + 5), 0x82
	ldw (xiy + 3), 0xFFFF
	ld xhl, 0xF250
	ldw bc, 0x10

LABEL_F22C7F:
	ld (xhl), 0x0
	ldw (xhl + 1), 0xFFFF
	add xhl, 0x3
	djnz xbc, LABEL_F22C7F
	ld xhl, 0xC9E
	ldw bc, 0x10

LABEL_F22C98:
	ldw (xhl), 0xFFFF
	inc 2, xhl
	djnz xbc, LABEL_F22C98
	ld xhl, 0xCAE
	ldw bc, 0x10

LABEL_F22CA9:
	ld (xhl), 0x5
	inc 1, xhl
	djnz xbc, LABEL_F22CA9
	ld xhl, 0xF1F8
	ldw bc, 0x10

LABEL_F22CB9:
	ldw (xhl), 0xFFFF
	inc 2, xhl
	djnz xbc, LABEL_F22CB9
	ld xhl, 0xF218
	ldw bc, 0x10

LABEL_F22CCA:
	ld (xhl), 0x5
	inc 1, xhl
	djnz xbc, LABEL_F22CCA
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
	jr z, LABEL_F22D30
	ldda32 xde, 4349
	push xde
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
	ld wa, (xhl + 3)
	stda16 61999, xwa
	ld ix, iy
	cp wa, 0xFFFF
	jr z, LABEL_F22D16
	ld iy, wa
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
	ldw (xhl + 1), 0x0

LABEL_F22D16:
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

LABEL_F22D30:
	ldb w, 0xFF
	pop xde
	ret

LABEL_F22D34:
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
	jr z, LABEL_F22DDE
	ld iy, ix
	ldw (xhl + 1), 0x0
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ldda32 xhl, 4349
	ld iy, (xhl + 3)

LABEL_F22D74:
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ldda32 xhl, 4349
	ld iy, (xhl + 3)
	cp iy, 0xFFFF
	jr z, LABEL_F22DA3

LABEL_F22D87:
	andmi8 (xhl), 0x7F
	ld (xhl + 5), 0x82
	inc 1, wa
	cpda16 xwa, 3302
	jr nz, LABEL_F22D74
	dec 1, wa

LABEL_F22D98:
	call SeqNode_ResolveSlotPtr
	ldda32 xhl, 4349
	ld (xhl + 1), de

LABEL_F22DA3:
	cps de, 0
	jr z, LABEL_F22DB6
	pushw iy
	ld iy, de
	call SeqNode_ResolveSlotPtr
	popw iy
	ldda32 xhl, 4349
	ld (xhl + 3), iy

LABEL_F22DB6:
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

LABEL_F22DDE:
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ldda32 xhl, 4349
	ld iy, (xhl + 3)
	cp iy, 0xFFFF
	jr nz, LABEL_F22D87
	stdi16 3302, 0
	ld iy, ix
	andmi8 (xhl), 0x7F
	jr LABEL_F22D98

SeqNode_ResolveSlotPtr:
	ld hl, iy
	extz xhl
	dec 1, hl
	sla xhl, 8
	addda32 xhl, 4362
	stda32 4349, xhl
	xor xhl, xhl
	ret

LABEL_F22E12:
	call LABEL_F22E17
	ret

LABEL_F22E17:
	pushw bc
	stda32 4353, xiy
	stda8 3822, a
	ld c, w
	call VoiceSlot_ComputeWordIndex
	extz xiz
	ld xix, 0xF1F8
	xor b, b

LABEL_F22E2F:
	ld_sriw3 IY, 0x07, 0xF0, 0xF8
	cp iy, 0xFFFF
	jrl z, LABEL_F22F85
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

LABEL_F22E5B:
	ld_sriw3 DE, 0x07, 0xF0, 0xF8
	cp de, 0xFFFF
	jr nz, LABEL_F22E7F
	st_dri3w IY, 0x07, 0xF0, 0xF8
	srl iz, 1
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld (xix + 32), 0x5
	ldto_lerp XIX, 0x38
	sla iz, 1
	jr LABEL_F22E5B

LABEL_F22E7F:
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
	jr ugt, LABEL_F22EF0
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

LABEL_F22EF0:
	sub wa, 0xFB
	stda16 10422, xwa
	pushw de
	call DispatchHandler_ResolveSlot
	popw de
	cp w, 0xFF
	jr z, LABEL_F22F6D
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

LABEL_F22F6D:
	ldb w, 0x68
	call MIDI_SendSysExCmd
	anddi8 58338, 111
	stdi8 32578, 15
	stdi16 58332, 16622
	popw bc
	ret

LABEL_F22F85:
	push xix
	call DispatchHandler_ResolveSlot
	ld iy, ix
	pop xix
	cp w, 0xFF
	jr z, LABEL_F22F6D
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
	jrl LABEL_F22E2F


; --- SMF Playback & Sequencer ---
