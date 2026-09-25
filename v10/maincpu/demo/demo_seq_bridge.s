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
	stb_d8	(0x28a4), e
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	Demo_SelectEntry_ProcessSongList
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jrl	SqTrSel_CaseC
	push	xde
	pushw	0
	pushw	4441
	call	Strcpy
	inc	8, xsp
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SetWall_MiscDataAndCode_0x2
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	SqTrSel_CaseC
	push	xde
	push	xhl
	push	xix
	push	xiz
	call MiddleFuncCall_DispatchData_Code_Helper
	pop xiz
	pop xix
	pop	xhl
	pop	xde
	jr	91
	push	xde
	push	xhl
	push	xix
	push	xiz
	call MiddleFuncCall_DispatchData_Code_Helper2
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	77
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SetWall_InitCallSequences
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	63
	push	xde
	push	xhl
	push	xix
	push	xiz
	call MiddleFuncCall_DispatchData_Code_Helper3
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	SqTrSel_CaseC
	push	xde
	push	xhl
	push	xix
	push	xiz
	call SetWall_InlineCodeBlock_Sub
	pop xiz
	pop xix
	pop	xhl
	pop	xde
	jr	SqTrSel_CaseC
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SetWall_InlineCodeBlock_0xC8
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	SqTrSel_CaseC
	call	Audio_CheckSubsystemReady
	jr	SqTrSel_CaseC
	calr	DisplayMode_RefreshState
	jr	SqTrSel_CaseC
	call	VoiceChannels_InitPanFromPreset
	jr	SqTrSel_CaseC

; SqTrSelTtl case B
SqTrSel_CaseB:
	call SeqFile_ParseHeader

; SqTrSelTtl case C
SqTrSel_CaseC:
	ld xhl, 0:i3
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
	ld (xiz+), l
	cp e, 0:i3
	jr z, SongBank_CopyNameAndFinish
	cpw (xsp + 4), 0x9
	jr nz, SongBank_FormatTwoDigit
	ld (xiz+), 0x31
	ld (xiz), 0x30
	jr SongBank_AppendColon

SongBank_FormatTwoDigit:
	ld (xiz+), 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

SongBank_AppendColon:
	inc 1, xiz
	ld (xiz+), 0x3a

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
	ld (7116:16), xde
	ld a, (0x00ffe3:24)
	extz wa
	ld (7120:16), wa
	ld de, wa
	extz xde
	ld xwa, (7116:16)
	ld xbc, 0x1e70003
	call ApPostEvent
	jrl SongBank_ReturnZero

SeqSongName_RefreshAll:
	ld iz, 0:i3

SeqSongName_RefreshLoop:
	ld wa, iz
	ld bc, iz
	ld de, 1:i3
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
	cp wa, 0:i3
	jr z, SongBank_StoreCurrentSong
	dec 1, wa

SeqSongName_StoreCurrent:
	ld (7120:16), wa

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
	ld de, 1:i3
	calr SongBank_ComputeTableOfs
	ld xde, xhl
	ld xwa, (7116:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	ld bc, (7120:16)
	ld wa, bc
	ld de, 1:i3
	calr SongBank_ComputeTableOfs
	ld xde, xhl
	ld xwa, (7116:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldto_berp A, 0xf8
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
	ld xhl, 0:i3
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
	ld (xiz+), c
	cp e, 0:i3
	jr z, SongBankLookup_BuildAudioCmd
	cpw (xsp + 4), 0x9
	jr nz, SongBankLookup_FormatTwoDigit
	ld (xiz+), 0x31
	ld (xiz), 0x30
	jr SongBankLookup_AppendColon

SongBankLookup_FormatTwoDigit:
	ld (xiz+), 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

SongBankLookup_AppendColon:
	inc 1, xiz

SongBankLookup_BuildAudioCmd:
	ld (xiz+), 0x3a
	ld a, (xix)
	extz wa
	pushw wa
	pushw 0xe2
	pushw 0x202
	push xiz
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	ld (xiz + 4), 0x0
	ld wa, (xsp + 4)
	mul wa, 0x7
	lda xbc, (7122:16)
	extz xwa
	add xwa, xbc
	ld xhl, xwa
	pop xiz
	inc 2, xsp
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
	ld (7192:16), xde
	ld a, (0x00ffe3:24)
	extz wa
	ld (7196:16), wa
	ld de, wa
	extz xde
	ld xwa, (7192:16)
	ld xbc, 0x1e70003
	jrl SeqSongMem_PostAndReturn

SeqSongMem_RefreshAll:
	ld iz, 0:i3

SeqSongMem_RefreshLoop:
	ld wa, iz
	ld bc, iz
	ld de, 0:i3
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
	cp wa, 0:i3
	jr z, SongBank_EventCompare
	dec 1, wa

SeqSongMem_StoreCurrent:
	ld (7196:16), wa

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
	ld de, 0:i3
	calr SongBank_LookupTableEntry
	ld xde, xhl
	ld xwa, (7192:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	ld bc, (7196:16)
	ld wa, bc
	ld de, 0:i3
	calr SongBank_LookupTableEntry
	ld xde, xhl
	ld xwa, (7192:16)
	ld xbc, 0x1c0000f

SeqSongMem_PostAndReturn:
	call ApPostEvent

SongBank_EventHandler_Return:
	ld xhl, 0:i3
	popw iz
	ret

; -----------------------------------------------------------------------------
; Until 2026-09-25 the 90 bytes from here to CDlikeSwTtl_SendStartEvt were one
; `.byte` block named CDlikeSwTtl_DispatchData.  They are four routines
; (scripts/lanes/sys/convert_code_runs.py; both `jp ApPostEvent` land on
; ApPostEvent, every instruction re-assembles to the ROM bytes).  The two
; entries other files call were reached through positional names
; (CDlikeSwTtl_DispatchData_0x6 / _0x4A, shared/positional_labels.s), now
; aliases of the labels below.
; -----------------------------------------------------------------------------
; Two `return 0` stubs; no call, jump or 24-bit pointer to either was found.
CDlikeSwTtl_ReturnZeroStub:
	ld	xhl, 0:i3
	ret
CDlikeSwTtl_ReturnZeroStub2:
	ld	xhl, 0:i3
	ret
; Post event 0x8B0004 (XBC = 0x01E0008D) with XDE = 0x10000 + n, where
; n = (0xCDF) + 2 when bit 0 of (0xCE0) is clear, (0xCDF) - 6 when it is set.
; Called twice from ui/setwall_routines.s.
CDlikeSwTtl_SendEvt4:
	bitda	0, (0xce0)
	jr	nz, CDlikeSwTtl_SendEvt4_Bit0Set
	ldb_d8	a, (0xcdf)
	inc	2, a
	extz	wa
	ld	de, wa
	extz	xde
	add	xde, 0x10000
	ld	xwa, 0x8b0004
	ld	xbc, 0x1e0008d
	jr	CDlikeSwTtl_SendEvt4_Post
CDlikeSwTtl_SendEvt4_Bit0Set:
	ldb_d8	a, (0xcdf)
	dec	6, a
	extz	wa
	ld	de, wa
	extz	xde
	add	xde, 0x10000
	ld	xwa, 0x8b0004
	ld	xbc, 0x1e0008d
CDlikeSwTtl_SendEvt4_Post:
	jp	ApPostEvent
; Same event as CDlikeSwTtl_SendStartEvt (0x8B0003) but with XDE = 1.
; Called from ui/setwall_routines.s.
CDlikeSwTtl_SendStartEvtArg1:
	ld	xwa, 0x8b0003
	ld	xbc, 0x1e0009c
	ld	xde, 1:i3
	jp	ApPostEvent

CDlikeSwTtl_SendStartEvt:
	ld xwa, 0x8b0003
	ld xbc, 0x1e0009c
	ld xde, 0:i3
	jp ApPostEvent

CDlikeSwTtl_SendResetEvent:
	ld xwa, 0x8b0000
	ld xbc, 0x1c00001
	ld xde, 0:i3
	jp ApPostEvent

CDlikeSwTtl_SendStopEvtD:
	ld xwa, 0x8b000d
	ld xbc, 0x1c00001
	ld xde, 0:i3
	jp ApPostEvent

CDlikeSwTtl_SendEvent8C_0:
	ld xwa, 0x8c0000
	ld xbc, 0x1c00001
	ld xde, 0:i3
	jp ApPostEvent

CDlikeSwTtl_SendEvent8C_A:
	ld xwa, 0x8c000a
	ld xbc, 0x1c00001
	ld xde, 0:i3
	jp ApPostEvent

CDlikeSwTtl_SendEvent8C_13:
	ld xwa, 0x8c0013
	ld xbc, 0x1c00001
	ld xde, 0:i3
	jp ApPostEvent

CDlikeSwTtl_SetRecordAndNotify:
	ld (0x021090:24), 0x01
	ld xwa, NAKA_PerfReg_Container_Root_0x1697
	ld xbc, 0x1c0000c
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, SepaOut_Config_0_0x25
	ld xbc, 0x1c0000c
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, NakaInst_FADE_IN_OUT_SETTING_0x2475
	ld xbc, 0x1c0000c
	ld xde, 0:i3
	jp ApPostEvent

SeqInit_PostEventSequence:
	ld (0x021090:24), 0x00
	ld xwa, NAKA_PerfReg_Container_Root_0x1697
	ld xbc, 0x1c0000c
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, SepaOut_Config_0_0x25
	ld xbc, 0x1c0000c
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, NakaInst_FADE_IN_OUT_SETTING_0x2475
	ld xbc, 0x1c0000c
	ld xde, 0:i3
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
	ld xde, 1:i3
	jp ApDeliveryEvent

SeqInit_FinalEvent:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	ld xde, 0:i3
	jp ApPostEvent

SeqRecPlay_EnableRecordOnly:
	ld (0x021092:24), 0x01
	ld (0x021094:24), 0x00
	ld xwa, 0x6f0025
	ld xbc, 0x1e000a7
	ld xde, 1:i3
	call ApPostEvent
	ld xde, 0:i3
	ld e, (0x021094:24)
	ld xwa, 0x6f0024
	ld xbc, 0x1e000a7
	jp ApPostEvent

SeqRecPlay_EnablePlayOnly:
	ld (0x021092:24), 0x00
	ld (0x021094:24), 0x01
	ld xwa, 0x6f0025
	ld xbc, 0x1e000a7
	ld xde, 0:i3
	call ApPostEvent
	ld xde, 0:i3
	ld e, (0x021094:24)
	ld xwa, 0x6f0024
	ld xbc, 0x1e000a7
	jp ApPostEvent

SeqRecPlay_DisableBoth:
	ld (0x021092:24), 0x00
	ld (0x021094:24), 0x00
	ld xwa, 0x6f0025
	ld xbc, 0x1e000a7
	ld xde, 0:i3
	call ApPostEvent
	ld xde, 0:i3
	ld e, (0x021094:24)
	ld xwa, 0x6f0024
	ld xbc, 0x1e000a7
	jp ApPostEvent

; SqTrSelTtl case D
SqTrSel_CaseD:
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld (7498:16), 0
	ret

; SqTrSelTtl case E
SqTrSel_CaseE:
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld xwa, 0x6f0026
	ld xbc, 0x1c70009
	ld xde, 0:i3
	call ApPostEvent
	ld (7498:16), 0
	ret

; SqTrSelTtl case F
SqTrSel_CaseF:
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld (7498:16), 0
	ret

PlayMode_SendStopEvent:
	ld xwa, 0x6f0026
	ld xbc, 0x1c70009
	ld xde, 0:i3
	jp ApPostEvent

; SqTrSelTtl case G
SqTrSel_CaseG:
	ld a, (0x8d36:16)
	extz wa
	sub wa, 0x6f
	cp wa, 0:i3
	ret lt
	cp wa, 7:i3
	ret gt
	add wa, wa
	lda xix, (SepaOut_Config_0_0x26A:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (SqTrSel_CaseG_JumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

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
	cp (0x8d36:16), 114
	ret z
	call SeqState_GetFlags
	bit 0, hl
	ret z
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld xwa, 0x6f0026
	ld xbc, 0x1c70009
	ld xde, 0:i3
	call ApPostEvent
	ret

PlayMode_SwitchToModeAndNotify:
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call ApPostEvent
	ldw wa, 0x8b
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call ApPostEvent
	ld (0x7f42:16), 35
	ldw wa, 0xee
	jp SoundCtrl_SendCommand
DispatchHandler_ConditionalJump:
	jr	t, DispatchHandler_SubJumpTable_Join

DispatchHandler_JumpToSubHandler:
	jr DispatchHandler_CallResolve

DispatchHandler_JumpSub:
	jr DispatchHandler_CallNodeInsert

DispatchHandler_SubJumpTable:
	jr DispatchHandler_CallSlotResolve
	jr DispatchHandler_StoreNodePtr
DispatchHandler_SubJumpTable_Join:
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
	ld iy, 1:i3
	call SeqNode_ResolveSlotPtr
	ldw (0xf22f:16), 1
	ld xiy, (4349:16)
	xor xhl, xhl
	ld de, 2:i3
	ld bc, (0x286d:16)
	ld (0xf231:16), bc
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
	ld (0xf22f:16), wa
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
	decw 1, (0xf231:16)
	pop xde
	ld (4349:16), xde
	ld w, 0x0:opc
	pop xde
	ret

DispatchResolve_ReturnFail:
	ld w, 0xff:opc
	pop xde
	ret

SeqNode_InsertAtPosition:
	ld xhl, 0x110a
	push xde
	ld xde, (7514:16)
	ld (xhl), xde
	pop xde
	ld (3302:16), wa
	ld bc, (0xf22f:16)
	ld (0xf22f:16), iy
	xor wa, wa
	call SeqNode_ResolveSlotPtr
	ld xhl, (4349:16)
	ld ix, (xhl + 1)
	ld de, ix
	cp ix, 0:i3
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
	cp wa, (3302:16)
	jr nz, SeqNodeInsert_TraverseNext
	dec 1, wa

SeqNodeInsert_LinkPrev:
	call SeqNode_ResolveSlotPtr
	ld xhl, (4349:16)
	ld (xhl + 1), de

SeqNodeInsert_LinkHead:
	cp de, 0:i3
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
	add (0xf231:16), wa
	ret

SeqNodeInsert_EmptyList:
	call SeqNode_ResolveSlotPtr
	ld ix, iy
	ld xhl, (4349:16)
	ld iy, (xhl + 3)
	cp iy, 0xffff
	jr nz, SeqNodeInsert_UnmarkAndCount
	ldw (3302:16), 0
	ld iy, ix
	andmi8 (xhl), 0x7f
	jr SeqNodeInsert_LinkPrev

SeqNode_ResolveSlotPtr:
	ld hl, iy
	extz xhl
	dec 1, hl
	sla xhl, 8
	add xhl, (4362:16)
	ld (4349:16), xhl
	xor xhl, xhl
	ret

VoiceSlot_AssignWrapper:
	call VoiceSlot_AssignToChannel
	ret

VoiceSlot_AssignToChannel:
	pushw bc
	ld (4353:16), xiy
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
	ld (0x28ba:16), iy
	srl iz, 1
	ldfr_lerp XIX, 0x38
	add xix, xiz
	ld a, (xix + 32)
	ldto_lerp XIX, 0x38
	xor w, w
	sla iz, 1
	ld (0x28bc:16), wa
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
	ld (0x28b8:16), iy
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
	ld (0x289f:16), iy
	ld (0x28b6:16), wa
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
	ld (0x28b6:16), wa
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
	ld (0x289f:16), iy
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
	ld w, 0x68:opc
	call MIDI_SendSysExCmd
	and (0xe3e2:16), 111
	ld (0x7f42:16), 15
	ldw (0xe3dc:16), 0x40ee
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
