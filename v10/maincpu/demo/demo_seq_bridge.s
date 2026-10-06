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
	cp xbc, EVT_LYRICS_CHARA_REQ
	jrl z, MiddleFuncCall_OnLyricsCharaReq
	sub xwa, EVT_DEMO_SONG_SEL
	cp xwa, 0x0
	jrl lt, SqTrSel_CaseC
	cp xwa, 0xc
	jrl gt, SqTrSel_CaseC
	add xwa, xwa
	add xwa, MiddleFuncCall_CaseTable
	ld wa, (xwa)
	lda xix, (MiddleFuncCall_DispatchData:24)
	jp	t, (xix+wa)

MiddleFuncCall_DispatchData:
	stb_d8	(DEMO_ACTIVE_ENTRY), e
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
MiddleFuncCall_OnSongNameSet:
	push	xde
	pushw	0
	pushw	4441
	call	Strcpy
	inc	8, xsp
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SqSngName_ApplyNameAndExit
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	SqTrSel_CaseC
MiddleFuncCall_OnTrAsTrackInc:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call SqTrAs_CursorNextTrack
	pop xiz
	pop xix
	pop	xhl
	pop	xde
	jr	SqTrSel_CaseC
MiddleFuncCall_OnTrAsTrackDec:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call SqTrAs_CursorPrevTrack
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	SqTrSel_CaseC
MiddleFuncCall_OnTrAsPageInc:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SetWall_InitCallSequences
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	SqTrSel_CaseC
MiddleFuncCall_OnTrAsPageDec:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call SqTrAs_CursorToFirstPage
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	SqTrSel_CaseC
MiddleFuncCall_OnTrAsPartInc:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call SqTrAs_PartInc_UpdateOkSw
	pop xiz
	pop xix
	pop	xhl
	pop	xde
	jr	SqTrSel_CaseC
MiddleFuncCall_OnTrAsPartDec:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	MiddleFuncCall_DispatchData_Helper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	SqTrSel_CaseC
MiddleFuncCall_OnAmdCall:
	call	Audio_CheckSubsystemReady
	jr	SqTrSel_CaseC
MiddleFuncCall_OnDirectPlayMute:
	calr	DisplayMode_RefreshState
	jr	SqTrSel_CaseC
MiddleFuncCall_OnTrackMidiCall:
	call	VoiceChannels_InitPanFromPreset
	jr	SqTrSel_CaseC

; SqTrSelTtl case B
MiddleFuncCall_OnLyricsCharaReq:
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
	lda xbc, (SEQ_SONG_SLOTS:24)
	ld wa, (xsp + 4)
	extz xwa
	sll xwa, 11
	add xbc, xwa
	lda xbc, (xbc+256)
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
	cp xbc, EVT_SET_SELECTED_FILE_NUM
	jrl z, SongBank_ReturnZero
	cp xbc, EVT_INDEXSW_DOWN
	jr z, SongBank_HandleNextPrev
	cp xbc, EVT_INDEXSW_UP
	jr z, SongBank_HandleNextPrev
	cp xbc, EVT_PAINT
	jr z, SeqSongName_RefreshAll
	cp xbc, EVT_PS_SONG_SEL_BOX_ID
	jrl nz, SongBank_ReturnZero
	ld (7116:16), xde
	ld a, (0x00ffe3:24)
	extz wa
	ld (7120:16), wa
	ld de, wa
	extz xde
	ld xwa, (7116:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUM
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
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr c, SeqSongName_RefreshLoop
	jrl SongBank_ReturnZero

SongBank_HandleNextPrev:
	ld wa, (7120:16)
	ld iz, wa
	cp xbc, EVT_INDEXSW_DOWN
	jr nz, SeqSongName_CheckPrev
	cp wa, 0x9
	jr nc, SongBank_StoreCurrentSong
	inc 1, wa
	jr SeqSongName_StoreCurrent

SeqSongName_CheckPrev:
	cp xbc, EVT_INDEXSW_UP
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
	ld xbc, EVT_SET_SELECTED_FILE_NUM
	call ApPostEvent
	ld wa, iz
	ld bc, iz
	ld de, 1:i3
	calr SongBank_ComputeTableOfs
	ld xde, xhl
	ld xwa, (7116:16)
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	ld bc, (7120:16)
	ld wa, bc
	ld de, 1:i3
	calr SongBank_ComputeTableOfs
	ld xde, xhl
	ld xwa, (7116:16)
	ld xbc, EVT_PARA_DRAW
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
	pushw SongBankLookup_BuildAudioCmd_Str_Fmt3d_FmtPct@hi16
	pushw SongBankLookup_BuildAudioCmd_Str_Fmt3d_FmtPct@lo16
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
	cp xbc, EVT_SET_SELECTED_FILE_NUM
	jrl z, SongBank_EventHandler_Return
	cp xbc, EVT_INDEXSW_DOWN
	jr z, SongBank_HandleNextPrevAlt
	cp xbc, EVT_INDEXSW_UP
	jr z, SongBank_HandleNextPrevAlt
	cp xbc, EVT_PAINT
	jr z, SeqSongMem_RefreshAll
	cp xbc, EVT_PS_SONG_SEL_BOX_ID
	jrl nz, SongBank_EventHandler_Return
	ld (7192:16), xde
	ld a, (0x00ffe3:24)
	extz wa
	ld (7196:16), wa
	ld de, wa
	extz xde
	ld xwa, (7192:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUM
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
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr c, SeqSongMem_RefreshLoop
	jr SongBank_EventHandler_Return

SongBank_HandleNextPrevAlt:
	ld wa, (7196:16)
	ld iz, wa
	cp xbc, EVT_INDEXSW_DOWN
	jr nz, SeqSongMem_CheckPrev
	cp wa, 0x9
	jr nc, SongBank_EventCompare
	inc 1, wa
	jr SeqSongMem_StoreCurrent

SeqSongMem_CheckPrev:
	cp xbc, EVT_INDEXSW_UP
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
	ld xbc, EVT_SET_SELECTED_FILE_NUM
	call ApPostEvent
	ld wa, iz
	ld bc, iz
	ld de, 0:i3
	calr SongBank_LookupTableEntry
	ld xde, xhl
	ld xwa, (7192:16)
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	ld bc, (7196:16)
	ld wa, bc
	ld de, 0:i3
	calr SongBank_LookupTableEntry
	ld xde, xhl
	ld xwa, (7192:16)
	ld xbc, EVT_PARA_DRAW

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
; (CDlikeSwTtl_SendEvt4 / _0x4A, shared/positional_labels.s), now
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
	bit	0, (0xce0:16)
	jr	nz, CDlikeSwTtl_SendEvt4_Bit0Set
	ldb_d8	a, (0xcdf)
	inc	2, a
	extz	wa
	ld	de, wa
	extz	xde
	add	xde, 0x10000
	ld	xwa, 0x8b0004
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jr	CDlikeSwTtl_SendEvt4_Post
CDlikeSwTtl_SendEvt4_Bit0Set:
	ldb_d8	a, (0xcdf)
	dec	6, a
	extz	wa
	ld	de, wa
	extz	xde
	add	xde, 0x10000
	ld	xwa, 0x8b0004
	ld	xbc, EVT_REQUEST_GRID_DRAW
CDlikeSwTtl_SendEvt4_Post:
	jp	ApPostEvent
; Same event as CDlikeSwTtl_SendStartEvt (0x8B0003) but with XDE = 1.
; Called from ui/setwall_routines.s.
CDlikeSwTtl_SendStartEvtArg1:
	ld	xwa, 0x8b0003
	ld	xbc, EVT_SET_VISIBLE
	ld	xde, 1:i3
	jp	ApPostEvent

CDlikeSwTtl_SendStartEvt:
	ld xwa, 0x8b0003
	ld xbc, EVT_SET_VISIBLE
	ld xde, 0:i3
	jp ApPostEvent

CDlikeSwTtl_SendResetEvent:
	ld xwa, 0x8b0000
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jp ApPostEvent

CDlikeSwTtl_SendStopEvtD:
	ld xwa, 0x8b000d
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jp ApPostEvent

CDlikeSwTtl_SendEvent8C_0:
	ld xwa, 0x8c0000
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jp ApPostEvent

CDlikeSwTtl_SendEvent8C_A:
	ld xwa, 0x8c000a
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jp ApPostEvent

CDlikeSwTtl_SendEvent8C_13:
	ld xwa, 0x8c0013
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jp ApPostEvent

CDlikeSwTtl_SetRecordAndNotify:
	ld (0x021090:24), 0x01
	ld xwa, NAKA_VIEW_DemoMed1
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, NAKA_VIEW_DemoMed2
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, NAKA_VIEW_DemoMed3
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	jp ApPostEvent

SeqInit_PostEventSequence:
	ld (0x021090:24), 0x00
	ld xwa, NAKA_VIEW_DemoMed1
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, NAKA_VIEW_DemoMed2
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, NAKA_VIEW_DemoMed3
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	jp ApPostEvent

SeqInit_LookupDispatchEntry:
	extz wa
	sla wa, 2
	lda xbc, (Demo_SongViewIdTable:24)
	ld	xhl, (xbc+wa)
	ret

SeqInit_PostDispatchEvent:
	ld a, (DEMO_ACTIVE_ENTRY:16)
	extz wa
	calr SeqInit_LookupDispatchEntry
	ld xwa, xhl
	ld xbc, EVT_SET_SELECTED
	ld xde, 1:i3
	jp ApDeliveryEvent

SeqInit_FinalEvent:
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	ld xde, 0:i3
	jp ApPostEvent

SeqRecPlay_EnableRecordOnly:
	ld (0x021092:24), 0x01
	ld (0x021094:24), 0x00
	ld xwa, 0x6f0025
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 1:i3
	call ApPostEvent
	ld xde, 0:i3
	ld e, (0x021094:24)
	ld xwa, 0x6f0024
	ld xbc, EVT_REFRESH_PARA_DRAW
	jp ApPostEvent

SeqRecPlay_EnablePlayOnly:
	ld (0x021092:24), 0x00
	ld (0x021094:24), 0x01
	ld xwa, 0x6f0025
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 0:i3
	call ApPostEvent
	ld xde, 0:i3
	ld e, (0x021094:24)
	ld xwa, 0x6f0024
	ld xbc, EVT_REFRESH_PARA_DRAW
	jp ApPostEvent

SeqRecPlay_DisableBoth:
	ld (0x021092:24), 0x00
	ld (0x021094:24), 0x00
	ld xwa, 0x6f0025
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 0:i3
	call ApPostEvent
	ld xde, 0:i3
	ld e, (0x021094:24)
	ld xwa, 0x6f0024
	ld xbc, EVT_REFRESH_PARA_DRAW
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
	ld xbc, EVT_LYRICS_ALL_CLEAR
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
	ld xbc, EVT_LYRICS_ALL_CLEAR
	ld xde, 0:i3
	jp ApPostEvent

; SqTrSelTtl case G
SqTrSel_CaseG:
	ld a, (CURRENT_TITLE:16)
	extz wa
	sub wa, 0x6f
	cp wa, 0:i3
	ret lt
	cp wa, 7:i3
	ret gt
	add wa, wa
	lda xix, (SqTrSel_CaseG_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (SqTrSel_CaseG_JumpTable:24)
	jp	t, (xix+wa)

SqTrSel_CaseG_JumpTable:
	; --- Jump table entries + 4 register-save call thunks ---
	jrl CDlikeSwTtl_SongBit1Check
SqTrSel_CaseG_OnTitleDpdoc:
	jrl CDlikeSwTtl_DocBitCheck
SqTrSel_CaseG_OnTitleDppd:
	jrl CDlikeSwTtl_PdBitCheck
; SqTrSel_CaseG_OnTitleDpMdlySmf: Case CURRENT_TITLE = 0x73 (TT_DPMDLYSMF) of SqTrSel_CaseG: calls
;   PlayMode_SendCommand6C with XDE/XHL/XIX/XIZ preserved. Basis: callers + body (switch value from the title
;   registration).
SqTrSel_CaseG_OnTitleDpMdlySmf:
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
; SqTrSel_CaseG_OnTitleDpMdlySmfLyr: Case CURRENT_TITLE = 0x76 (TT_DPMDLYSMFLYR) of SqTrSel_CaseG: calls
;   PlayMode_SendCommand6C with XDE/XHL/XIX/XIZ preserved. Basis: callers + body (switch value from the title
;   registration).
SqTrSel_CaseG_OnTitleDpMdlySmfLyr:
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
; SqTrSel_CaseG_OnTitleDpMdlyDoc: Case CURRENT_TITLE = 0x74 (TT_DPMDLYDOC) of SqTrSel_CaseG: calls
;   SongMode_StartPlayback with XDE/XHL/XIX/XIZ preserved. Basis: callers + body (switch value from the title
;   registration).
SqTrSel_CaseG_OnTitleDpMdlyDoc:
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
; SqTrSel_CaseG_OnTitleDpMdlyPd: Case CURRENT_TITLE = 0x75 (TT_DPMDLYPD) of SqTrSel_CaseG: calls
;   PartFormat_StartPlayback with XDE/XHL/XIX/XIZ preserved. Basis: callers + body (switch value from the title
;   registration).
SqTrSel_CaseG_OnTitleDpMdlyPd:
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
	cp (CURRENT_TITLE:16), 114
	ret z
	call SeqState_GetFlags
	bit 0, hl
	ret z
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld xwa, 0x6f0026
	ld xbc, EVT_LYRICS_ALL_CLEAR
	ld xde, 0:i3
	call ApPostEvent
	ret

PlayMode_SwitchToModeAndNotify:
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	ldw wa, 0x8b
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ld (GLOBAL_ERROR_CODE:16), 35
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
	djnz16 bc, SeqSlot_InitEntryLoop
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
	djnz16 bc, SeqSlot_ClearF250Loop
	ld xhl, 0xc9e
	ldw bc, 0x10

SeqSlot_ClearC9ELoop:
	ldw (xhl), 0xffff
	inc 2, xhl
	djnz16 bc, SeqSlot_ClearC9ELoop
	ld xhl, 0xcae
	ldw bc, 0x10

SeqSlot_InitCAELoop:
	ld (xhl), 0x5
	inc 1, xhl
	djnz16 bc, SeqSlot_InitCAELoop
	ld xhl, 0xf1f8
	ldw bc, 0x10

SeqSlot_ClearF1F8Loop:
	ldw (xhl), 0xffff
	inc 2, xhl
	djnz16 bc, SeqSlot_ClearF1F8Loop
	ld xhl, 0xf218
	ldw bc, 0x10

SeqSlot_InitF218Loop:
	ld (xhl), 0x5
	inc 1, xhl
	djnz16 bc, SeqSlot_InitF218Loop
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
	ld	iy, (xix+iz)
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
	ld	de, (xix+iz)
	cp de, 0xffff
	jr nz, VoiceSlot_CheckOccupied
	ld	(xix+iz), iy
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
	ld	iy, (xix+iz)
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
	ld	de, (xix+iz)
	ld (xhl + 1), de
	ld	(xix+iz), wa
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
	ld (GLOBAL_ERROR_CODE:16), 15
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
	ld	(xix+iz), iy
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
	or	(xix+iz), 0x80
	ldfr_lerp XIX, 0x38
	lda	xix, (xix+iz)
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
