; =============================================================================
; File Demo Procedures
; =============================================================================
;
; File demo procedures and title handlers. Manages demo file
; playback, title display, and demo mode UI integration.
; =============================================================================

FDemo_DisplayResourceData:
	lda xsp, (xsp-292)
	push	xiz
	ld	xiz, xwa
	ldw (xsp+6), 0
	lda	xbc, (xsp+0x108)
	ld	xwa, xbc
	lda	xbc, (xbc+32)
FDemo_DisplayResourceData_Loop:
	ld (xwa+), 32
	cp xwa, xbc
	jr	c, FDemo_DisplayResourceData_Loop
	push	xiz
	call	Strlen
	pushw	hl
	push	xiz
	lda	xwa, (xsp+0x112)
	push	xwa
	call	Strncpy
	lda	xwa, (xsp+0x116)
	ld	(xwa+0x8), 0
	pushw	FDemo_DisplayResourceData_Str_SQT@hi16
	pushw	FDemo_DisplayResourceData_Str_SQT@lo16
	push	xwa
	call	Strcat
	lda	xsp, (xsp+22)
	lda	xwa, (xsp+0x108)
	ld	xbc, FDemo_DisplayResourceData_Str_rb
	call	FileIO_OpenWithMode
	ld	(xsp+4), hl
	cpw	(xsp+0x4), 0
	jrl	lt, FDemo_DisplayResourceData_Skip6
	calr	FDemo_ResetAllocBuffer
	lda	xwa, (xsp+8)
	ld	xbc, 256
	call	FileIO_ReadBlock
	or	xhl, xhl
	jr	z, FDemo_DisplayResourceData_Skip4
	ld	xwa, 256
	calr	FDemo_AllocBuffer
	lda	xbc, (xsp+8)
	ld	a, (xbc+4)
	extz	wa
	ld	(xsp+6), wa
	pushw	256
	push	xbc
	push	xhl
	call	Mem_Copy
	lda	xsp, (xsp+10)
FDemo_DisplayResourceData_Skip4:
	ld	iz, 1:i3
FDemo_DisplayResourceData_Loop2:
	lda	xwa, (xsp+8)
	ld	xbc, 256
	call	FileIO_ReadBlock
	or	xhl, xhl
	jr	z, FDemo_DisplayResourceData_Skip
	ld	xwa, 256
	calr	FDemo_AllocBuffer
	pushw	256
	lda	xwa, (xsp+10)
	push	xwa
	push	xhl
	call	Mem_Copy
	lda	xsp, (xsp+10)
FDemo_DisplayResourceData_Skip:
	inc	1, iz
	cp	iz, 8
	jr	lt, FDemo_DisplayResourceData_Loop2
	cpw	(xsp+0x6), 1
	jr	nz, FDemo_DisplayResourceData_Skip5
	ld	iz, 0:i3
FDemo_DisplayResourceData_Loop3:
	lda	xwa, (xsp+8)
	ld	xbc, 256
	call	FileIO_ReadBlock
	inc	1, iz
	cp	iz, 72
	jr	lt, FDemo_DisplayResourceData_Loop3
FDemo_DisplayResourceData_Skip5:
	lda	xwa, (xsp+8)
	ld	xbc, 256
	call	FileIO_ReadBlock
	or	xhl, xhl
	jr	z, FDemo_DisplayResourceData_Skip2
FDemo_DisplayResourceData_Loop4:
	ld	xwa, 256
	calr	FDemo_AllocBuffer
	pushw	256
	lda	xwa, (xsp+10)
	push	xwa
	push	xhl
	call	Mem_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+8)
	ld	xbc, 256
	call	FileIO_ReadBlock
	or	xhl, xhl
	jr	nz, FDemo_DisplayResourceData_Loop4
FDemo_DisplayResourceData_Skip2:
	call	FileIO_CloseHandle
FDemo_DisplayResourceData_Skip6:
	ld	hl, (xsp+4)
	pop	xiz
	lda	xsp, (xsp+0x124)
	ret
FDemo_ResetAllocBuffer:
	lda	xwa, (SEQ_SONG_SLOTS:24)
	ld	(0x25b7e:24), xwa
	ret
FDemo_AllocBuffer:
	lda	xhl, (SEQ_SONG_SLOTS:24)
	lda	xbc, (0xfd800:24)
	sub	xbc, xhl
	ld	xix, xbc
	ld	xde, (0x25b7e:24)
	ld	xbc, xde
	sub	xbc, xhl
	add	xbc, xwa
	cp	xbc, xix
	jr	nc, FDemo_AllocBuffer_Skip3
	ld	xhl, xde
	add	xde, xwa
	ld	(0x25b7e:24), xde
	jr	FDemo_AllocBuffer_Return
FDemo_AllocBuffer_Skip3:
	ld	xhl, 0:i3
FDemo_AllocBuffer_Return:
	ret

MainPreControl:
	sub xbc, EVT_READ_PRESENTATION_REQ
	cp xbc, 0x0
	jr lt, MainPreControl_ReturnNull
	cp xbc, 0xa
	jr gt, MainPreControl_ReturnNull
	add xbc, xbc
	add xbc, MainPreControl_CaseTable
	ld bc, (xbc)
	lda xix, (MainPreControl_Dispatch:24)
	jp	t, (xix+bc)
; MainPreControl dispatch (11-entry, table 0xea007a)
MainPreControl_Dispatch:
	ldw	(0x0251d8:24), 0

MainPreControl_ReturnNull:
	ld xhl, 0:i3
	ret

FDemo_DisplayCtrlJumpHandler:
	; --- Display control jump table handler stubs ---
	; Three stubs call display resource loaders (F86360/F864A0/F863E4),
	; convert result, set up event codes, then dispatch via FA9D58.
	; Also handles display state queries on (0x0251d8).
	ld xwa, xde				; workspace
	calr Seq_LoadDisplayResource			; load display resource (format validation)
	exts xhl				; sign-extend result
	ld xwa, 0xffffffff			; broadcast target
	ld xbc, EVT_READ_PRESENTATION			; event code
	ld xde, xhl				; result as param
	jr FDemo_DispatchEventPost				; dispatch
MainPreControl_OnReadSongReq:
	ld xwa, xde				; workspace
	calr FDemo_DisplayResourceData			; load alternate display resource
	exts xhl
	ld xwa, 0xffffffff
	ld xbc, EVT_READ_SONG			; event code 3
	ld xde, xhl
	jr FDemo_DispatchEventPost
MainPreControl_OnReadActionReq:
	ld xwa, xde				; workspace
	calr Seq_LoadNamedResource			; load named display resource
	exts xhl
	ld xwa, 0xffffffff
	ld xbc, EVT_READ_ACTION			; event code 2
	ld xde, xhl
FDemo_DispatchEventPost:
	call ApPostEvent				; dispatch event
	jr MainPreControl_ReturnNull		; return null
MainPreControl_OnStartPresentation:
	ld	(DEMO_ACTIVE_ENTRY:16), 19
	call Demo_SelectEntry_ProcessSongList			; additional handler
	jr MainPreControl_ReturnNull
MainPreControl_OnExitPresentation:
	cpw	(0x251d8:24), 0
	jr z, MainPreControl_Dispatch			; if zero, clear state
	call Part_InitFromPreset			; process display state
	jr MainPreControl_Dispatch
MainPreControl_OnExistPresentation:
	ld	hl, (0x251d8:24)
	exts xhl
	ret


ApPreControl:
	push xiz
	ld xiz, xde
	ld xwa, xbc
	cp xbc, EVT_GET_STRING
	jrl z, Seq_GetControlBlock
	cp xbc, EVT_EXIST_PRESENTATION
	jrl z, Seq_ReadStartFlag
	cp xbc, EVT_EXIT_PRESENTATION
	jrl z, Seq_PostMelodyEventAlt
	ld de, iz
	cp xbc, EVT_ACTION
	jrl z, FDemo_ProcessDisplayStateQuery
	cp xbc, EVT_EXEC_PRESENTATION_REQ
	jr z, Seq_StartWithFullInit
	cp xbc, EVT_INIT_PRESENTATION
	jr z, Seq_PostMelodyEvent
	sub xwa, EVT_READ_PRESENTATION
	cp xwa, 0x0
	jr lt, ApPreControl_ReturnNull
	cp xwa, 0x6
	jr gt, ApPreControl_ReturnNull
	add xwa, xwa
	add xwa, ApPreControl_CaseTable
	ld wa, (xwa)
	lda xix, (Seq_PostMelodyEvent:24)
	jp	t, (xix+wa)

Seq_PostMelodyEvent:
	ld xwa, NAKA_MAINFUNC_MainPreControl
	ld xde, xiz

Seq_DispatchMainFunc:
	call MainFuncCall

ApPreControl_ReturnNull:
	ld xhl, 0:i3
	jrl ApPreControl_Exit

Seq_StartWithFullInit:
	ld xwa, xiz
	calr Seq_InitializeAndStart
	jr ApPreControl_ReturnNull
ApPreControl_OnReadPresentation:
	ld (0x025b7c:24), de
	cp de, 0:i3
	jr lt, ApPreControl_ReturnNull
	ld xwa, (0x0248c4:24)
	ld bc, 0:i3
	calr FDemoText_ProcessTextMarkup
	jr ApPreControl_ReturnNull
ApPreControl_OnReadSong:
	ld (0x025b7c:24), de
	cp de, 0:i3
	jr lt, ApPreControl_ReturnNull
	pushw 0x2
	pushw 0x4878
	call Strlen
	inc 1, hl
	pushw hl
	call Malloc
	ld xiz, xhl
	pushw 0x2
	pushw 0x4878
	push xiz
	call Strcpy
	lda xsp, (xsp + 14)
	ld xwa, NAKA_MAINFUNC_MainPreControl
	ld xbc, EVT_READ_ACTION_REQ
	ld xde, xiz
	call MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, xiz
	jr Seq_DispatchMainFunc
ApPreControl_OnReadAction:
	ld (0x025b7c:24), de
	cp de, 0:i3
	jr lt, ApPreControl_ReturnNull
	ld xwa, NAKA_MAINFUNC_MainPreControl
	ld xbc, EVT_START_PRESENTATION
	ld xde, 0:i3
	jrl Seq_DispatchMainFunc
ApPreControl_OnStartSong:
	ld xwa, NAKA_VIEW_PleaseWait
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call PostEvent
	ld wa, iz
	calr Seq_CopyResourcePtrs
	ld wa, 2:i3
	calr FDemoText_ProcessMarkupLoop
	jrl ApPreControl_ReturnNull

FDemo_ProcessDisplayStateQuery:
	cp de, 0:i3
	jrl lt, ApPreControl_ReturnNull
	cp de, 0x7f
	jrl gt, ApPreControl_ReturnNull
	sla de, 2
	lda xwa, (0x024fd8:24)
	ld	xwa, (xwa+de)
	cp (xwa), 0x0
	jrl z, ApPreControl_ReturnNull

FDemo_DisplayStateQueryLoop:
	ld bc, 0:i3
	calr FDemoText_ProcessTextMarkup
	ld xwa, xhl
	cp (xwa), 0x0
	jr nz, FDemo_DisplayStateQueryLoop
	jrl ApPreControl_ReturnNull

Seq_PostMelodyEventAlt:
	ld xwa, NAKA_MAINFUNC_MainPreControl
	ld xde, xiz
	jrl Seq_DispatchMainFunc

Seq_ReadStartFlag:
	ld hl, (0x0251d8:24)
	exts xhl
	jr ApPreControl_Exit

Seq_GetControlBlock:
	lda xhl, (0x024882:24)

ApPreControl_Exit:
	pop xiz
	ret

FDemo_MultiGuardCheck:
	; --- Routine 1: multi-guard check, return HL=1 or 0 (30 bytes) ---
	cp	(ACTIVE_TITLE:16), 228
	jr nz, Banner_ReturnZero
	cpw	(SEQ_ACTIVE_PARTS:16), 0
	jr nz, Banner_ReturnZero
	cp	(DEMO_TIMER_COUNTDOWN:16), 0
	jr nz, Banner_ReturnZero
	bit	3, (DEMO_CONTROL_FLAGS:16)
	jr nz, Banner_ReturnZero
	ld	hl, 1:i3
	ret
Banner_ReturnZero:
	ld	hl, 0:i3
	ret
FDemo_LoadRegsAndPostEvent:
	; --- Routine 2: load regs, jp FA9D58 (23 bytes) ---
	ld xwa, 0xffffffff
	ld xbc, EVT_EXEC_PRESENTATION
	ld xde, FDemo_LoadRegsAndPostEvent_Str_FEATURE
	jp ApPostEvent


FDemo_LinkedListSearch:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ld xiz, (0x880008:24)
	ld xwa, (xiz + 16)
	or xwa, xwa
	jr z, FDemo_LinkedListSearchFound

FDemo_LinkedListSearchLoop:
	push xiz
	ld xwa, (xsp + 8)
	push xwa
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr z, FDemo_LinkedListSearchFound
	lda xiz, (xiz + 24)
	ld xwa, (xiz + 16)
	or xwa, xwa
	jr nz, FDemo_LinkedListSearchLoop

FDemo_LinkedListSearchFound:
	ld xwa, (xiz + 16)
	or xwa, xwa
	jr z, FDemo_LinkedListSearchRetNull
	ld xhl, xiz
	jr FDemo_LinkedListSearchExit

FDemo_LinkedListSearchRetNull:
	ld xhl, 0:i3

FDemo_LinkedListSearchExit:
	pop xiz
	inc 4, xsp
	ret

; --- LinkedList_SearchInsert: Search and insert into a 24-byte-node list ---
; Two routines sharing this label block:
; 1) Search: Walks a fixed-size array at 0x249d8 (up to 63 entries,
;    24 bytes each). Calls compare function (0xff3f35) for each node.
;    Returns pointer to matching entry or falls through.
; 2) Insert: Walks the same list checking node+16 for empty slot,
;    calls insert function (0xff3f4d), returns success (HL=1) or fail.
FDemo_LinkedListSearchInsert:
	dec	8, xsp
	pushw	iz
	ld	(xsp+6), xwa
	lda	xwa, (0x249d8:24)
	ld	(xsp+2), xwa
	ld	iz, 0:i3
FDemo_LinkedListSearchInsert_Loop:
	ld	xwa, (xsp+2)
	push	xwa
	ld	xwa, (xsp+10)
	push	xwa
	call	Strcmp
	inc	8, xsp
	cp	hl, 0:i3
	jr	z, FDemo_LinkedListSearchInsert_Skip
	ld	xwa, 24
	add	(xsp+2), xwa
	inc	1, iz
	cp	iz, 63
	jr	lt, FDemo_LinkedListSearchInsert_Loop
FDemo_LinkedListSearchInsert_Skip:
	cp	iz, 63
	jr	z, FDemo_LinkedListSearchInsert_Skip2
	ld	xhl, (xsp+2)
	jr	FDemo_LinkedListSearchInsert_Epilogue
FDemo_LinkedListSearchInsert_Skip2:
	ld	xwa, (xsp+6)
	calr	FDemo_LinkedListSearch
FDemo_LinkedListSearchInsert_Epilogue:
	popw	iz
	inc	8, xsp
	ret
FDemo_RegisterLoadedFile:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xbc
	lda	xiz, (0x249d8:24)
	ld	de, 0:i3
FDemo_RegisterLoadedFile_Loop2:
	ld	xbc, (xiz+16)
	or	xbc, xbc
	jr	z, FDemo_RegisterLoadedFile_Skip3
	lda	xiz, (xiz+24)
	inc	1, de
	cp	de, 63
	jr	lt, FDemo_RegisterLoadedFile_Loop2
FDemo_RegisterLoadedFile_Skip3:
	cp	de, 63
	jr	z, FDemo_RegisterLoadedFile_Skip4
	push	xwa
	push	xiz
	call	Strcpy
	inc	8, xsp
	ld	xwa, (xsp+4)
	ld	(xiz+16), xwa
	ld	hl, 1:i3
	jr	FDemo_RegisterLoadedFile_Epilogue2
FDemo_RegisterLoadedFile_Skip4:
	ld	hl, 0:i3
FDemo_RegisterLoadedFile_Epilogue2:
	pop	xiz
	inc	4, xsp
	ret

FDemo_LinkedListLookupField:
	calr FDemo_LinkedListSearch
	or xhl, xhl
	jr z, FDemo_LinkedListLookupNull
	ld xhl, (xhl + 16)
	ret

FDemo_LinkedListLookupNull:
	ld xhl, 0:i3
	ret

FDemo_FileOpenAndProcess:
	; --- Stack-frame function: alloc, multi-call dispatch (114 bytes) ---
	lda	xsp, (xsp-22)
	push xiz
	push xwa
	lda	xwa, (xsp+14)
	push xwa
	call Strcpy
	inc	8, xsp
	lda	xwa, (xsp+10)
	calr	FDemo_LinkedListSearchInsert
	or xhl, xhl
	jr z, FDemo_FileOpen_DoOpen
	ld	hl, 0:i3
	jr t, FDemo_FileOpen_Exit
FDemo_FileOpen_DoOpen:
	lda	xwa, (xsp+10)
	ld xbc, FDemo_FileOpen_DoOpen_Str_rb
	call FileIO_OpenWithMode
	ld (xsp+4), hl
	cpw (xsp+4), 0x0000
	jr lt, FDemo_FileOpen_GetResult
	ld	xwa, 0:i3
	ld	bc, 2:i3
	call FileIO_SeekAndReadBlock
	call FileIO_SeekWriteBlock_Impl
	ld xiz, xhl
	call FileIO_SeekRead_ExtReturn
	ld xwa, xiz
	calr	FDemo_AllocBuffer
	ld (xsp+6), xhl
	ld xwa, (xsp+6)
	or xwa, xwa
	jr z, FDemo_FileOpen_CloseHandle
	ld xbc, xiz
	ld xwa, (xsp+6)
	call FileIO_ReadBlock
FDemo_FileOpen_CloseHandle:
	call FileIO_CloseHandle
	lda	xwa, (xsp+10)
	ld xbc, (xsp+6)
	calr	FDemo_RegisterLoadedFile
FDemo_FileOpen_GetResult:
	ld hl, (xsp+4)
FDemo_FileOpen_Exit:
	pop xiz
	lda	xsp, (xsp+22)
	ret


DemoMode_Main_Operation:
	res 0, (0x28b1:16)
	call Voice_InitializeAll
	lda xbc, (0xf9a0:16)
	lda xwa, (0xffbe:16)
	sub xwa, xbc
	inc 2, xwa
	pushw wa
	push xbc
	pushw 0x3
	pushw 0xcf04
	call Mem_Copy
	lda xsp, (xsp + 10)
	call Audio_ConfigureDSP
	calr Voice_LoadVoiceTable
	set 4, (0xfd50:16)
	res 2, (0xfd50:16)
	res 2, (0xfd52:16)
	calr Demo_PreSetup
	res 0, (1115:16)
	call AccompSeq_StopSequence
	calr Voice_CopyPreset
	call MIDI_BroadcastPitchReset
	calr Timer7_DisableInterrupt
	call Audio_CheckSubsystemReady
	set 6, (0xb7e2:16)
	res 3, (DEMO_CONTROL_FLAGS:16)
	call SeqInit_PostEventSequence
	call SeqInit_FinalEvent
	jp Seq_StartMainControl

FDemo_IndicatorSetup:
	ldw wa, 0x22
	ld bc, 0:i3
	ld de, 0:i3
	call CtrlPanel_IndicatorDispatch
	ld (0x8f4e:16), 4
	ret

DemoMode_Initialize:
	calr Demo_PreSetup
	ld (0x2966:16), 0
	ld (3379:16), 0
	ld (DEMO_TIMER_COUNTDOWN:16), 0
	res 7, (0x28ae:16)
	call MidiChannel_ResetAndConfigure
	calr Audio_WaitForReady
	call SeqStep_PlaybackStateMachine
	calr Voice_SavePreset
	res 3, (DEMO_CONTROL_FLAGS:16)
	call SeqInit_PostEventSequence
	call ToneGen_FileIO_RestoreFromBackup
	call SeqTimer_UpdateTempoReg
	call Voice_InitializeAll
	call Seq_StartMainControlAlt
	call TempoRingBuf_Init
	call SeqBuf_Init
	ldw wa, 0x22
	call CtrlPanel_SetIndicatorLED
	bit 0, (0x28a5:16)
	jr z, FDemo_PostBannerCheck
	ldmm_sd24w 0xec, 0xff, 0x00, 0x9e, 0xf1

FDemo_PostBannerCheck:
	calr Banner_Loop_Check
	call Audio_CheckSubsystemReady
	res 6, (0xb7e2:16)
	ret

Demo_SelectionEntryHandler:
	calr Demo_PreSetup
	ld (0x2966:16), 0
	ld (3379:16), 0
	ld (DEMO_TIMER_COUNTDOWN:16), 0
	calr Audio_WaitForReady
	call SeqStep_PlaybackStateMachine
	res 3, (DEMO_CONTROL_FLAGS:16)
	call SeqInit_PostEventSequence
	call TempoRingBuf_Init
	call SeqBuf_Init
	ldw wa, 0x22
	call CtrlPanel_SetIndicatorLED
	jrl Banner_Loop_Check
SwbtB3_CodeA9_Listener0:
	cp (SWBTWR_PAYLOAD_1:16), 32
	ret nz
	ld a, (SWBTWR_PAYLOAD_3:16)
	and a, 0x13
	ret z
	ld a, (SWBTWR_PAYLOAD_2:16)
	and a, 0x13
	jr z, Demo_SelectEntry_NoNewButton
	ld (3379:16), 16
	ret

Demo_SelectEntry_NoNewButton:
	ld (3379:16), 0
	ret

Demo_SelectEntry_PreSaveCheck:
	cp (CURRENT_MODE:16), 19
	jr nz, Demo_SelectEntry_CheckVoiceKeys
	calr Voice_SavePreset
	lda xbc, (0xf9a0:16)
	lda xwa, (0xffbe:16)
	sub xwa, xbc
	inc 2, xwa
	pushw wa
	pushw 0x3
	pushw 0xcf04
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 10)
	jr Demo_SelectEntry_ExitDispatch

Demo_SelectEntry_CheckVoiceKeys:
	ld a, (CURRENT_TITLE:16)
	cp a, 0x72
	jr z, Demo_SelectEntry_SaveVoice
	cp a, 0x70
	jr z, Demo_SelectEntry_SaveVoice
	cp a, 0x71
	jr z, Demo_SelectEntry_SaveVoice
	cp a, 0x6f
	jr nz, Demo_SelectEntry_ExitDispatch

Demo_SelectEntry_SaveVoice:
	calr Voice_SavePreset

Demo_SelectEntry_ExitDispatch:
	ldmm_sd24b 0xe3, 0xff, 0x00, 0x4a, 0xf2
	ret

Demo_SelectEntry_ByteTable:
	bit	7, (0x2966:16)
	ret	nz
	ld	a, (SEQ_TRANSPORT_STATE:16)
	and	a, 3
	ret	nz
	ld	a, (1115:16)
	and	a, 3
	ret	nz
	cp	(DEMO_TIMER_COUNTDOWN:16), 0
	ret	nz
	cp	(SWBTWR_PAYLOAD_1:16), 1
	ret	nz
	cp	(CURRENT_MODE:16), 19
	ret	nz
	bit	0, (SWBTWR_PAYLOAD_2:16)
	ret	z
	cpw	(SEQ_ACTIVE_PARTS:16), 0
	jr	nz, Demo_SelectEntry_ByteTable_Skip
	bit	0, (0x3283:16)
	jr	z, Demo_SelectEntry_ByteTable_Skip2
Demo_SelectEntry_ByteTable_Skip:
	res	3, (DEMO_CONTROL_FLAGS:16)
	cp	(ACTIVE_TITLE:16), 228
	call	nz, (SeqInit_PostEventSequence:24)
	calr	Demo_PreSetupAndScan
	calr	Demo_WaitForDisplayBit
	ldw	(0x25b84:24), 1
	ld	(0x8f4e:16), 4
	cp	(ACTIVE_TITLE:16), 228
	call	nz, (SeqInit_FinalEvent:24)
	ld	a, (DEMO_ACTIVE_ENTRY:16)
	extz	wa
	jp	Seq_DispatchEventType6
Demo_SelectEntry_ByteTable_Skip2:
	set	3, (DEMO_CONTROL_FLAGS:16)
	cp	(ACTIVE_TITLE:16), 228
	jr	z, Demo_SelectEntry_ByteTable_Skip3
	call	CDlikeSwTtl_SetRecordAndNotify
	ld	(DEMO_CURRENT_SONG:16), 0
	jr	Demo_SelectEntry_ByteTable_Join
Demo_SelectEntry_ByteTable_Skip3:
	ld	(DEMO_CURRENT_SONG:16), 18
Demo_SelectEntry_ByteTable_Join:
	jrl	t, Demo_SelectEntry_AfterSongLoad

Demo_SelectEntry_ProcessSongList:
	cpw (SEQ_ACTIVE_PARTS:16), 0
	jr z, Demo_SelectEntry_ToCountdown
	bit 3, (DEMO_CONTROL_FLAGS:16)
	jr z, Demo_SelectEntry_ManualSelect
	ld a, (DEMO_ACTIVE_ENTRY:16)
	cp a, (DEMO_TARGET_SONG:16)
	ret nz
	calr Demo_PreSetupAndScan
	calr Demo_WaitForDisplayBit
	calr Banner_Loop_Check
	cp (ACTIVE_TITLE:16), 228
	call nz, (SeqInit_FinalEvent:24)
	jrl Demo_SelectEntry_AfterSongLoad

Demo_SelectEntry_ManualSelect:
	calr Demo_PreSetupAndScan
	calr Demo_WaitForDisplayBit
	calr Banner_Loop_Check
	ld a, (DEMO_ACTIVE_ENTRY:16)
	cp a, (DEMO_TARGET_SONG:16)
	jr z, Demo_SelectEntry_StartAutoPlay
	cp (ACTIVE_TITLE:16), 228
	call nz, (SeqInit_FinalEvent:24)

Demo_SelectEntry_ToCountdown:
	jrl Demo_ResetCountdownTimer

Demo_SelectEntry_StartAutoPlay:
	ld (0x8f4e:16), 4
	cp (ACTIVE_TITLE:16), 228
	call nz, (SeqInit_FinalEvent:24)
	ld a, (DEMO_ACTIVE_ENTRY:16)
	extz wa
	call Seq_DispatchEventType6
	ret

Demo_SelectEntry_TimerTick:
	calr Demo_SelectEntry_CheckCPanel
	cpw (0x25b84:24), 0
	call nz, (Banner_Loop_Check:24)
	ld a, (DEMO_TIMER_COUNTDOWN:16)
	cp a, 0:i3
	ret z
	dec 1, a
	ld (DEMO_TIMER_COUNTDOWN:16), a
	cp a, 0xa
	jr nz, Demo_SelectEntry_CheckCountdown
	ld a, (DEMO_ACTIVE_ENTRY:16)
	extz wa
	calr Demo_ParseSlideHeader
	jrl Demo_SelectEntry_PlaySong

Demo_SelectEntry_CheckCountdown:
	ld a, (DEMO_TIMER_COUNTDOWN:16)
	cp a, 3:i3
	jrl z, Demo_SelectEntry_StartPlayback
	cp a, 1:i3
	ret nz
	ld (0x2966:16), 133
	ret

Demo_SelectEntry_CheckCPanel:
	cp (CURRENT_MODE:16), 19
	ret nz
	calr Demo_SelectEntry_Debounce
	ret

Demo_SelectEntry_Debounce:
	ld a, (3379:16)
	cp a, 0:i3
	ret z
	dec 1, a
	ld (3379:16), a
	cp a, 0:i3
	ret nz
	set 3, (DEMO_CONTROL_FLAGS:16)
	cp (ACTIVE_TITLE:16), 228
	call nz, (CDlikeSwTtl_SetRecordAndNotify:24)
	pushw 0x1
	ldw wa, 0xa8
	ld bc, 1:i3
	ld de, 1:i3
	call AddswbWr
	ret

Demo_SelectEntry_AfterSongLoad:
	cp (ACTIVE_TITLE:16), 228
	call nz, (SeqInit_FinalEvent:24)
	ld a, (DEMO_ACTIVE_ENTRY:16)
	extz wa
	call Seq_DispatchEventType6
	ld (0x8f4e:16), 4
	bit 3, (DEMO_CONTROL_FLAGS:16)
	ret z
	cp (ACTIVE_TITLE:16), 228
	jr z, Demo_SelectEntry_CheckSongCount
	cp (DEMO_CURRENT_SONG:16), 18
	jr c, Demo_SelectEntry_UpdateDisplay
	ld (DEMO_CURRENT_SONG:16), 0
	jr Demo_SelectEntry_UpdateDisplay

Demo_SelectEntry_CheckSongCount:
	call Seq_IsMelodyActive
	cp hl, 0:i3
	jr z, Demo_SelectEntry_CheckLimit18
	cp (DEMO_CURRENT_SONG:16), 19
	jr ugt, Demo_SelectEntry_ClampSongIdx
	jr Demo_SelectEntry_UpdateDisplay

Demo_SelectEntry_CheckLimit18:
	cp (DEMO_CURRENT_SONG:16), 18
	jr ule, Demo_SelectEntry_UpdateDisplay

Demo_SelectEntry_ClampSongIdx:
	ld (DEMO_CURRENT_SONG:16), 18

Demo_SelectEntry_UpdateDisplay:
	calr Demo_SelectEntry_LoadPattern
	calr Demo_SelectEntry_DrawSecondary
	calr Demo_ResetCountdownTimer
	inc 1, (DEMO_CURRENT_SONG:16)
	ret

Demo_SelectEntry_LoadPattern:
	ld a, (DEMO_CURRENT_SONG:16)
	extz wa
	add wa, wa
	lda xbc, (DemoSong_EntryCol:24)
	ld	(DEMO_ACTIVE_ENTRY:16), (xbc+wa)
	ret

Demo_SelectEntry_DrawSecondary:
	bit 3, (DEMO_CONTROL_FLAGS:16)
	ret z
	cp (ACTIVE_TITLE:16), 228
	ret z
	ld a, (DEMO_CURRENT_SONG:16)
	extz wa
	add wa, wa
	lda xbc, (DemoSong_TitleCol:24)
	ld	a, (xbc+wa)
	call UI_PostModeChangeEvent
	ret

Demo_SelectEntry_PlaySong:
	cp (CURRENT_MODE:16), 19
	ret nz
	ld a, (DEMO_ACTIVE_ENTRY:16)
	extz wa
	calr Demo_GetPresetBaseForPartAlt
	ld xwa, xhl
	call ToneGen_FileIO_SaveAndSync
	ld wa, 2:i3
	call BitMapOut_GetRenderMode_CheckBit3
	call SwbtWr_ReinitBothBanks
	ld wa, 2:i3
	call BitMapOut_GetRenderMode_Return
	push xde
	push xhl
	push xix
	push xiz
	call Seq_DispatcherEntry
	pop xiz
	pop xix
	pop xhl
	pop xde
	call SeqTimer_UpdateTempoReg
	ld (0x8f4e:16), 6
	ld a, (DEMO_ACTIVE_ENTRY:16)
	extz wa
	call Seq_DispatchEventType5
	ret

Demo_SelectEntry_StartPlayback:
	cp (CURRENT_MODE:16), 19
	ret nz
	call Seq_ResetAndRestartAccompaniment
	call Audio_CheckSubsystemReady
	ldmm8 DEMO_TARGET_SONG, DEMO_ACTIVE_ENTRY
	cp (ACTIVE_TITLE:16), 228
	ret z
	call SeqInit_PostDispatchEvent
	ret

Audio_WaitForReady:
	ld xbc, 0xf000
	ld a, (1056:16)

Audio_WaitForReady_PollLoop:
	bit 2, a
	jr z, Audio_WaitForReady_Dispatch
	sub xbc, 0x1
	jr nz, Audio_WaitForReady_PollLoop

Audio_WaitForReady_Dispatch:
	ld (0x32f6:16), 255
	push xde
	push xhl
	push xix
	push xiz
	call Seq_DispatcherEntry
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

Demo_ResetCountdownTimer:
	ld (DEMO_TIMER_COUNTDOWN:16), 15
	ret

Timer7_DisableInterrupt:
	lda xbc, (0xfd98:16)
	ld e, (xbc)
	res 7, e
	ld (xbc), e
	extz de
	pushw 0x80
	ldw wa, 0x98
	ld bc, 2:i3
	call AddswbWr
	ret

Voice_LoadVoiceTable:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0

Voice_LoadVoiceTable_Loop:
	ldto_berp A, 0xfb
	extz wa
	calr Demo_LookupPartTableEntry
	ld c, (xhl + 13)
	ldto_berp A, 0xfb
	ld (0x025b86:24), a
	and c, 0xf
	ld (0x025b88:24), c
	push xde
	push xhl
	push xix
	push xiz
	ld w, (0x025b88:24)
	ld a, (0x025b86:24)
	call MidiStream_HandlePartSelect
	pop xiz
	pop xix
	pop xhl
	pop xde
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x16
	jr ule, Voice_LoadVoiceTable_Loop
	ldw wa, 0x19
	calr Demo_LookupPartTableEntry
	ld c, (xhl + 13)
	ld (0x025b86:24), 0x19
	and c, 0xf
	ld (0x025b88:24), c
	push xde
	push xhl
	push xix
	push xiz
	ld w, (0x025b88:24)
	ld a, (0x025b86:24)
	call MidiStream_HandlePartSelect
	pop xiz
	pop xix
	pop xhl
	pop xde
	popw_erp 0xfa
	ret

Banner_Loop_Check:
	dec 4, xsp
	pushw_erp 0xfa
	ldib_erp 0xfb, 0

Banner_Loop_CheckEntry:
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xe
	jr z, Banner_Loop_Exit
	cp a, 0xf
	jr z, Banner_Loop_Exit
	cp a, 0x10
	jr z, Banner_Loop_Exit
	cp a, 0xd
	jr z, Banner_Loop_Exit
	set 6, (0x28b3:16)
	lda xwa, (xsp + 2)
	ld (xwa), 0xd3
	ld (xwa + 1), 0x7e
	ld (xwa + 2), 0x7f
	ldto_berp C, 0xfb
	ld (xwa + 3), c
	ld bc, 4:i3
	call SeqBuf_WriteMidiEventDirect

Banner_Loop_Exit:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, Banner_Loop_CheckEntry
	ldw (0x025b84:24), 0x0000
	popw_erp 0xfa
	inc 4, xsp
	ret

Demo_PreSetupAndScan:
	calr Demo_ScanActivePartChannels
	jr Demo_PreSetup

Demo_PreSetup:
	call AccWrap_PlayModeDispatch
	call SeqBuf_Init
	call SeqPlay_EmergencyStopAll
	ld (1073:16), 0
	ret

Demo_ScanActivePartChannels:
	ld l, 0x0:opc
	lda xix, (0xf1a0:16)

Demo_ScanPartLoop:
	ld a, l
	extz wa
	extz xwa
	add xwa, xix
	cp (xwa), 0x10
	jr nz, Demo_ScanPartNext
	ld a, l
	extz wa
	ld bc, wa
	add bc, bc
	lda xde, (Demo_PartBitMask:24)
	ld	bc, (xde+bc)
	and bc, (0xf19e:16)
	jr z, Demo_ScanPartSkipToEnd
	muls wa, 0x3
	lda xbc, (0xf250:16)
	bit	7, (xbc+wa)
	jr z, Demo_ScanPartSkipToEnd
	ld a, l
	inc 1, a
	ld (3414:16), a
	set 0, (3412:16)
	set 2, (0x287b:16)
	jr Demo_ScanPartDone

Demo_ScanPartSkipToEnd:
	ld l, 0xf:opc

Demo_ScanPartNext:
	inc 1, l
	cp l, 0x10
	jr c, Demo_ScanPartLoop

Demo_ScanPartDone:
	cp l, 0x10
	ret nz
	res 0, (3412:16)
	res 2, (0x287b:16)
	ret

Voice_SavePreset:
	pushw 0x10
	pushw 0x0
	pushw 0xcce
	pushw 0x0
	pushw 0xf1a0
	call Mem_Copy
	lda xsp, (xsp + 10)
	ret

Voice_CopyPreset:
	pushw 0x10
	pushw 0x0
	pushw 0xf1a0
	pushw 0x0
	pushw 0xcce
	call Mem_Copy
	lda xsp, (xsp + 10)
	ret

Demo_LookupPartTableEntry:
	extz wa
	sla wa, 2
	ld xbc, (0x90f2:16)
	exts xwa
	add xwa, xbc
	ld xhl, (xwa)
	ret

Demo_WaitForDisplayBit:
	ld xwa, NakaData_RomEnd
	bit 2, (1056:16)
	ret z

Demo_WaitForDisplayBit_Loop:
	sub xwa, 0x1
	ret z
	bit 2, (1056:16)
	jr nz, Demo_WaitForDisplayBit_Loop
	ret

Demo_GetPresetBaseForPart:
	extz wa
	sla wa, 2
	extz xwa
	add xwa, 0x9c4000
	ld xwa, (xwa)
	or xwa, xwa
	jr z, Demo_GetPresetBase_Default
	ld xhl, 0x69800
	jr Demo_GetPresetBase_StoreAndRet

Demo_GetPresetBase_Default:
	lda xhl, (SEQ_SONG_SLOTS:24)

Demo_GetPresetBase_StoreAndRet:
	lda xhl, (xhl+2048)
	ret

Demo_GetPresetBaseForPartAlt:
	extz wa
	sla wa, 2
	extz xwa
	add xwa, 0x9c4000
	ld xwa, (xwa)
	or xwa, xwa
	jr z, Demo_GetPresetBaseAlt_Default
	ld xhl, 0x69800
	jr Demo_GetPresetBaseAlt_StoreAndRet

Demo_GetPresetBaseAlt_Default:
	lda xhl, (SEQ_SONG_SLOTS:24)

Demo_GetPresetBaseAlt_StoreAndRet:
	lda xhl, (xhl+768)
	ret

Demo_GetPresetBaseForPartExt:
	extz wa
	sla wa, 2
	extz xwa
	add xwa, 0x9c4000
	ld xwa, (xwa)
	or xwa, xwa
	jr z, Demo_GetPresetBaseExt_Default
	ld xwa, 0x69800
	jr Demo_GetPresetBaseExt_StoreAndRet

Demo_GetPresetBaseExt_Default:
	lda xwa, (SEQ_SONG_SLOTS:24)

Demo_GetPresetBaseExt_StoreAndRet:
	lda xhl, (xwa+208:16)
	ret

Voice_GetPresetFieldWord:
	extz wa
	sla wa, 2
	extz xwa
	add xwa, 0x9c4000
	ld xwa, (xwa)
	or xwa, xwa
	jr z, Voice_GetPresetField_Default
	ld xwa, 0x69800
	jr Voice_GetPresetField_Compute

Voice_GetPresetField_Default:
	lda xwa, (SEQ_SONG_SLOTS:24)

Voice_GetPresetField_Compute:
	lda xwa, (xwa + 30)
	ld hl, (xwa)
	ret

Voice_GetPresetFieldAddr:
	extz wa
	sla wa, 2
	extz xwa
	add xwa, 0x9c4000
	ld xwa, (xwa)
	or xwa, xwa
	jr z, Voice_GetPresetFieldAddr_Default
	ld xwa, 0x69800
	jr Voice_GetPresetFieldAddr_Compute

Voice_GetPresetFieldAddr_Default:
	lda xwa, (SEQ_SONG_SLOTS:24)

Voice_GetPresetFieldAddr_Compute:
	lda xhl, (xwa + 32)
	ret

Demo_ProcessRecordEntry:
	lda xsp, (xsp - 14)
	pushw_erp 0xfa
	ld (xsp + 14), a
	ld (xsp + 12), 0x0
	ld a, (xsp + 14)
	extz wa
	calr Voice_GetPresetFieldWord
	ld (xsp + 2), hl
	ld a, (xsp + 14)
	extz wa
	calr Voice_GetPresetFieldAddr
	ld (xsp + 4), xhl
	ld a, (xsp + 14)
	extz wa
	calr Demo_GetPresetBaseForPartExt
	ld (xsp + 8), xhl
	ldib_erp 0xfb, 0

Demo_RecordChainScanLoop:
	ldto_berp C, 0xfb
	extz bc
	ld xwa, (xsp + 4)
	ld	a, (xwa+bc)
	cp a, 0xd
	jr z, Demo_VoiceTypeDispatch
	cp a, 0x10
	jr z, Demo_VoiceTypeDispatch
	cp a, 0xf
	jr z, Demo_VoiceTypeDispatch
	cp a, 0xe
	jrl nz, Demo_RecordChainLoopExit

Demo_VoiceTypeDispatch:
	add bc, bc
	lda xwa, (Demo_PartBitMask:24)
	ld	wa, (xwa+bc)
	and wa, (xsp + 2)
	jrl z, Demo_RecordChainLoopExit
	ldto_berp A, 0xfb
	mul a, 0x3
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	bit	7, (xwa+bc)
	jrl z, Demo_RecordChainLoopExit
	ld a, (xsp + 14)
	extz wa
	calr Demo_GetPresetBaseForPart
	ld xwa, xhl
	ldto_berp C, 0xfb
	mul c, 0x3
	ld e, c
	extz de
	inc 1, de
	ld xbc, (xsp + 8)
	ld	bc, (xbc+de)
	ld de, 0:i3
	calr Demo_StoreRecordChainParams
	jr RecordChain_SkipToNext

RecordChain_ParseMidiStatus:
	ld a, l
	and a, 0xf0
	cp hl, 0x85
	jr nz, RecordChain_HandleStatus80
	ld (xsp + 12), 0x1
	jr Demo_RecordChainReturn

RecordChain_HandleStatus80:
	cp hl, 0x80
	jr nz, RecordChain_HandleOtherStatus
	calr RecordChain_ReadNextByte
	cp hl, 0:i3
	jr z, RecordChain_SkipToNext
	jr RecordChain_ContinueLoop

RecordChain_HandleOtherStatus:
	cp a, 0x80
	jr z, RecordChain_ContinueLoop
	cp a, 0x90
	jr z, RecordChain_SkipDataByte
	cp a, 0xb0
	jr z, RecordChain_SkipDataByte
	cp a, 0xc0
	jr nz, RecordChain_HandleStatusD2

RecordChain_SkipDataByte:
	calr RecordChain_ReadNextByte
	cp hl, 0:i3
	jr z, RecordChain_SkipToNext
	jr RecordChain_ContinueLoop

RecordChain_HandleStatusD2:
	cp hl, 0xd2
	jr nz, RecordChain_HandleStatusD0
	calr RecordChain_ReadNextByte
	cp hl, 0:i3
	jr z, RecordChain_SkipToNext
	jr RecordChain_ContinueLoop

RecordChain_HandleStatusD0:
	cp a, 0xd0
	jr nz, RecordChain_SkipToNext
	calr RecordChain_ReadNextByte
	cp hl, 0:i3
	jr nz, RecordChain_ContinueLoop

RecordChain_SkipToNext:
	calr RecordChain_SkipToStatusByte
	ld wa, hl
	cp wa, 0xffff
	jr nz, RecordChain_ParseMidiStatus

RecordChain_ContinueLoop:
	cp (xsp + 12), 0x1
	jr z, Demo_RecordChainReturn

Demo_RecordChainLoopExit:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jrl c, Demo_RecordChainScanLoop

Demo_RecordChainReturn:
	ld l, (xsp + 12)
	popw_erp 0xfa
	lda xsp, (xsp + 14)
	ret

Demo_StoreRecordChainParams:
	ld (0x025b8a:24), xwa
	ld (0x03ec4e:24), bc
	ld (0x025b8e:24), de
	ret

RecordChain_ReadNextByte:
	ld wa, (0x03ec4e:24)
	cp wa, 0xffff
	jr nz, RecordChain_ReadAdvance
	ldw hl, 0xffff
	ret

RecordChain_ReadAdvance:
	sll wa, 8
	sub wa, 0x100
	ld de, wa
	extz xde
	add xde, (0x25b8a:24)
	ld wa, (0x025b8e:24)
	ld bc, wa
	extz xbc
	inc 5, xbc
	add xbc, xde
	ld l, (xbc)
	extz hl
	inc 1, wa
	ld (0x025b8e:24), wa
	cp wa, 0xfa
	ret ule
	ld wa, (xde + 3)
	ld (0x03ec4e:24), wa
	ldw (0x025b8e:24), 0x0000
	ret

RecordChain_SkipToStatusByte:
	jr RecordChain_SkipReadNext

RecordChain_SkipCheckBit7:
	bit 7, hl
	ret nz

RecordChain_SkipReadNext:
	calr RecordChain_ReadNextByte
	cp hl, 0xffff
	jr nz, RecordChain_SkipCheckBit7
	ret

Demo_ParseSlideHeader:
	extz wa
	sla wa, 2
	extz xwa
	add xwa, 0x9c4000
	ld xwa, (xwa)
	or xwa, xwa
	ret z
	ld xbc, 0x69800
	call SLIDE_Parse_Header
	ret

FileIO_CheckRegionSignature:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	sla wa, 3
	lda xbc, (FileIO_FileSigRecs_OffsetCol:24)
	ld	wa, (xbc+wa)
	extz xwa
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	ldiw_erp 0xfa, 1
	ld iz, 0:i3
	jr FileIO_CheckSig_LoopTest

FileIO_CheckSig_ReadLoop:
	call FileIO_ReadByte
	cp hl, 0:i3
	jr lt, FileIO_CheckSig_Fail
	ld a, (xsp + 4)
	extz wa
	sla wa, 3
	lda xbc, (FileIO_RegionSignatures:24)
	ld	xwa, (xbc+wa)
	ld	a, (xwa+iz)
	cp l, a
	jr z, FileIO_CheckSig_Match

FileIO_CheckSig_Fail:
	ldiw_erp 0xfa, 0
	jr FileIO_CheckSig_Return

FileIO_CheckSig_Match:
	inc 1, iz

FileIO_CheckSig_LoopTest:
	ld a, (xsp + 4)
	extz wa
	sla wa, 3
	lda xbc, (FileIO_FileSigRecs_LengthCol:24)
	ld de, iz
	cp	de, (xbc+wa)
	jr c, FileIO_CheckSig_ReadLoop

FileIO_CheckSig_Return:
	call FileIO_SeekRead_ExtReturn
	ldto_werp HL, 0xfa
	pop xiz
	inc 2, xsp
	ret

FileIO_ValidateFileSignature:
	lda xsp, (xsp - 26)
	push xiz
	ld (xsp + 28), a
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	cp hl, 0:i3
	jr ge, FileIO_ValidateSig_Process
	ld hl, 0:i3
	jr FileIO_ValidateSig_Return

FileIO_ValidateSig_Process:
	ld a, l
	ldfr_berp A, 0xf8
	extz iz
	ld wa, hl
	call GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 18)
	ld bc, iz
	call FileIO_FormatFileIndex
	lda xbc, (xsp + 18)
	ld e, (xsp + 28)
	extz de
	lda xwa, (xsp + 4)
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, FileIO_ValidateSig_Process_Str_rb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr lt, FileIO_ValidateSig_Done
	ld a, (xsp + 28)
	extz wa
	calr FileIO_CheckRegionSignature
	ldfr_werp HL, 0xfa
	call FileIO_CloseHandle

FileIO_ValidateSig_Done:
	ldto_werp HL, 0xfa

FileIO_ValidateSig_Return:
	pop xiz
	lda xsp, (xsp + 26)
	ret

FileIO_ReadAndValidateHeader:
	dec 4, xsp
	pushw iz
	ld xwa, 0:i3
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	ld iz, 0:i3

FileIO_ReadValidateHdr_Loop:
	call FileIO_ReadByte
	cp hl, 0:i3
	jr ge, FileIO_ReadValidateHdr_Store
	ld hl, 0:i3

FileIO_ReadValidateHdr_Store:
	lda xwa, (xsp + 2)
	ld	(xwa+iz), l
	inc 1, iz
	cp iz, 3:i3
	jr lt, FileIO_ReadValidateHdr_Loop
	call FileIO_SeekRead_ExtReturn
	lda xwa, (xsp + 2)
	ld xbc, FileIO_ReadValidateHdr_Store_Str_H
	ld de, 3:i3
	call FileIO_Search_SkipEntry
	cp hl, 0:i3
	jr z, FileIO_ReadHeader_TypeMatch
	lda xwa, (xsp + 2)
	ld xbc, FileIO_ReadValidateHdr_Store_Str_G
	ld de, 3:i3
	call FileIO_Search_SkipEntry
	cp hl, 0:i3
	jr z, FileIO_ReadHeader_TypeMatch
	lda xwa, (xsp + 2)
	ld xbc, FileIO_ReadValidateHdr_Store_Str_LKE
	ld de, 3:i3
	call FileIO_Search_SkipEntry
	ld wa, 0:i3
	cp hl, 0:i3
	jr nz, FileIO_ReadValidateHdr_Return

FileIO_ReadHeader_TypeMatch:
	ld wa, 1:i3

FileIO_ReadValidateHdr_Return:
	ld hl, wa
	popw iz
	inc 4, xsp
	ret

FileIO_ValidateAndOpenFile:
	lda xsp, (xsp - 24)
	push xiz
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	cp hl, 0:i3
	jr ge, FileIO_ValidateOpen_Process
	ld hl, 0:i3
	jr FileIO_ValidateOpen_Return

FileIO_ValidateOpen_Process:
	ld a, l
	ldfr_berp A, 0xf8
	extz iz
	ld wa, hl
	call GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 18)
	ld bc, iz
	call FileIO_FormatFileIndex
	lda xbc, (xsp + 18)
	lda xwa, (xsp + 4)
	ld de, 3:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, FileIO_ValidateOpen_Process_Str_rb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr lt, FileIO_ValidateOpen_Done
	calr FileIO_ReadAndValidateHeader
	ldfr_werp HL, 0xfa
	call FileIO_CloseHandle

FileIO_ValidateOpen_Done:
	ldto_werp HL, 0xfa

FileIO_ValidateOpen_Return:
	pop xiz
	lda xsp, (xsp + 24)
	ret

FileIO_ReadHeaderAt4:
	pushw iz
	ld iz, 1:i3
	ld xwa, 4:i3
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	call FileIO_ReadByte
	cp hl, 0:i3
	jr lt, FileIO_ReadHdr4_Fail
	ld xwa, (FileIO_HeaderAt4_ExpectedPtr:24)
	ld a, (xwa)
	cp l, a
	jr z, FileIO_ReadHdr4_Success

FileIO_ReadHdr4_Fail:
	ld iz, 0:i3

FileIO_ReadHdr4_Success:
	call FileIO_SeekRead_ExtReturn
	ld hl, iz
	popw iz
	ret

FileIO_ValidateFileWithRegion:
	lda xsp, (xsp - 24)
	push xiz
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	cp hl, 0:i3
	jr lt, FileIO_ValidateRegion_NoFile
	ld a, l
	ldfr_berp A, 0xf8
	extz iz
	ld wa, hl
	call GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 18)
	ld bc, iz
	call FileIO_FormatFileIndex
	lda xbc, (xsp + 18)
	lda xwa, (xsp + 4)
	ld de, 2:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, FileIO_ValidateFileWithRegion_Str_rb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, FileIO_ValidateRegion_CheckSig

FileIO_ValidateRegion_NoFile:
	ld hl, 0:i3
	jr FileIO_ValidateRegion_Return

FileIO_ValidateRegion_CheckSig:
	ld wa, 2:i3
	calr FileIO_CheckRegionSignature
	cp hl, 0:i3
	jr z, FileIO_ValidateRegion_Close
	calr FileIO_ReadHeaderAt4
	ldfr_werp HL, 0xfa

FileIO_ValidateRegion_Close:
	call FileIO_CloseHandle
	ldto_werp HL, 0xfa

FileIO_ValidateRegion_Return:
	pop xiz
	lda xsp, (xsp + 24)
	ret

FileIO_ReadHeaderAtF:
	pushw iz
	ld iz, 1:i3
	ld xwa, 0xf
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	call FileIO_ReadByte
	cp hl, 0:i3
	jr lt, FileIO_ReadHdrF_Fail
	cp l, 0x8
	jr z, FileIO_ReadHdrF_Success

FileIO_ReadHdrF_Fail:
	ld iz, 0:i3

FileIO_ReadHdrF_Success:
	call FileIO_SeekRead_ExtReturn
	ld hl, iz
	popw iz
	ret

FileIO_ValidateWithExtHeader:
	lda xsp, (xsp - 24)
	push xiz
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	cp hl, 0:i3
	jr lt, FileIO_ValidateExt_NoFile
	ld a, l
	ldfr_berp A, 0xf8
	extz iz
	ld wa, hl
	call GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 18)
	ld bc, iz
	call FileIO_FormatFileIndex
	lda xbc, (xsp + 18)
	lda xwa, (xsp + 4)
	ld de, 1:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, FileIO_ValidateWithExtHeader_Str_rb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, FileIO_ValidateExt_CheckSig

FileIO_ValidateExt_NoFile:
	ld hl, 0:i3
	jr FileIO_ValidateExt_Return

FileIO_ValidateExt_CheckSig:
	ld wa, 1:i3
	calr FileIO_CheckRegionSignature
	cp hl, 0:i3
	jr z, FileIO_ValidateExt_Close
	calr FileIO_ReadHeaderAtF
	ldfr_werp HL, 0xfa

FileIO_ValidateExt_Close:
	call FileIO_CloseHandle
	ldto_werp HL, 0xfa

FileIO_ValidateExt_Return:
	pop xiz
	lda xsp, (xsp + 24)
	ret

; =============================================================================
; Display region management functions (F8744F-F876CA)
;
; Four functions that initialize, validate, and configure different display/
; memory regions. Each follows the same pattern:
;   1. F891AB: init region descriptor
;   2. F88BC7: open resource (returns handle in HL, negative=error)
;   3. F871A6: check mode availability
;   4. F88D74: configure memory range (XWA=base, XBC=size)
;   5. F88C48: finalize
; =============================================================================
FileIO_LoadRegion0_VRAM:
	; --- Display region 0: VRAM 0xf980-0xffc0, 0x1e7800-0x1e8000 ---
	lda xsp, (xsp - 14)			; allocate 14 bytes
	pushw iz				; save IZ (2 bytes, total frame=16)
	ld xbc, xwa				; XBC = caller arg
	lda xwa, (xsp + 2)			; XWA = stack buffer ptr
	ld	de, 0:i3
	call FileIO_ReadHeader				; init display region descriptor
	lda xwa, (xsp + 2)			; reload buffer ptr
	ld xbc, FileIO_LoadRegion0_VRAM_Str_rb			; resource ID for region 0
	call FileIO_OpenWithMode				; open display resource
	cp hl, 0:i3				; check result (negative=error)
	jr ge, LoadRegion0_OpenSuccess			; success, continue
	call FileIO_ReturnError				; close resource (error path)
	jr LoadRegion0_Return				; return
LoadRegion0_OpenSuccess:
	ld	wa, 0:i3
	calr FileIO_CheckRegionSignature			; check mode availability
	cp hl, 0:i3
	jr z, LoadRegion0_AltPath			; mode not available, alt path
	call PreLswLoad				; primary display setup
	lda	xwa, (0xf980:16)
	lda	xbc, (0xffc0:16)
	ld xde, xwa				; XDE = base (0xf980)
	sub xbc, xde				; XBC = size (0xffc0-0xf980)
	call FileIO_ReadBlock				; configure memory range
	lda xwa, (0x1e7800:24); VRAM region base
	ld xde, xwa
	lda xbc, (0x1e8000:24); VRAM region end
	sub xbc, xde				; size = 0x800 bytes
	call FileIO_ReadBlock				; configure VRAM range
	call FileIO_ReturnError				; close resource
	ld iz, hl				; IZ = result handle
	ld wa, iz
	call PostLswLoad				; post-setup
	jr LoadRegion0_Finalize
LoadRegion0_AltPath:
	call FileData_AllocLoadAndParse				; alternate path setup
	ld iz, hl				; IZ = result
LoadRegion0_Finalize:
	call FileIO_CloseHandle			; finalize display
	ld hl, iz				; return result in HL
LoadRegion0_Return:
	popw iz
	lda xsp, (xsp + 14)
	ret

FileIO_LoadRegion1_VRAM:
	; --- Display region 1: VRAM 0x1ed350, memory up to 0x200000 ---
	lda xsp, (xsp - 14)
	pushw iz
	ld xbc, xwa
	lda xwa, (xsp + 2)
	ld	de, 1:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, FileIO_LoadRegion1_VRAM_Str_rb			; resource ID for region 1
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, LoadRegion1_OpenSuccess
	call FileIO_ReturnError
	jrl LoadRegion1_Return
LoadRegion1_OpenSuccess:
	ld	wa, 1:i3
	calr FileIO_CheckRegionSignature
	cp hl, 0:i3
	jrl z, LoadRegion1_ModeError
	calr FileIO_ReadHeaderAtF			; check extended mode
	cp hl, 0:i3
	jr z, LoadRegion1_AltPmLoad
	ld	wa, 0:i3
	call PanelMemory_PreBankLoad
	ld xwa, 0x00000010
	ld	bc, 0:i3
	call FileIO_SeekAndReadBlock				; set region param
	lda xwa, (0x1ed350:24); VRAM base
	add xwa, 0x00000010			; offset +0x10
	ld xbc, 0x00000010			; size = 0x10
	call FileIO_ReadBlock
	ld xwa, 0x000000b0
	ld	bc, 0:i3
	call FileIO_SeekAndReadBlock
	lda xwa, (0x1ed350:24)
	ld bc, (xwa + 13)			; load field at offset 0x0d
	extz xbc
	sll xbc, 3				; multiply by 8
	add xwa, 0x000000b0			; offset +0xb0
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld	wa, 0:i3
	ld bc, iz
	call PanelMemory_PostBankLoad
	jr LoadRegion1_Finalize
LoadRegion1_AltPmLoad:
	call PrePmLoad				; alternate region setup
	lda xwa, (0x1ed350:24)
	ld xde, xwa
	lda xbc, (0x200000:24); end of DRAM
	sub xbc, xde				; size = 0x200000 - 0x1ed350
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call PostPmLoad
	jr LoadRegion1_Finalize
LoadRegion1_ModeError:
	ldw iz, 0xff9a				; error code
LoadRegion1_Finalize:
	call FileIO_CloseHandle			; finalize
	ld hl, iz
LoadRegion1_Return:
	popw iz
	lda xsp, (xsp + 14)
	ret

FileIO_LoadRegion7_Flash:
	; --- Display region 7: flash/file buffer 0x3d3000, 0x0400 bytes ---
	lda xsp, (xsp - 14)
	push xiz				; save XIZ (4 bytes)
	ld xbc, xwa
	lda xwa, (xsp + 4)			; stack offset differs (XIZ=4 vs IZ=2)
	ld	de, 7:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, FileIO_LoadRegion7_Flash_Str_rb			; resource ID for region 7
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, LoadRegion7_OpenSuccess
	call FileIO_ReturnError
	jr LoadRegion7_Return
LoadRegion7_OpenSuccess:
	ld	wa, 7:i3
	calr FileIO_CheckRegionSignature
	cp hl, 0:i3
	jr z, LoadRegion7_ModeError
	call PreMidiLoad
	pushw 0x0400				; buffer size
	call Malloc				; allocate buffer (Malloc)
	inc 2, xsp				; clean stack
	ld xiz, xhl				; XIZ = buffer ptr
	or xiz, xiz				; check null
	jr z, LoadRegion7_AllocFailed			; alloc failed
	pushw 0x0000				; fill value
	pushw 0x0400				; fill size
	push xiz				; buffer ptr
	call Memset				; memset
	inc	8, xsp
	ld xwa, xiz				; base address
	ld xbc, 0x00000400			; size
	call FileIO_ReadBlock
	ld xwa, 0x003d3000			; flash/file area base
	push xwa
	ld	wa, 1:i3
	ld xbc, xiz				; buffer ptr
	ldw de, 0x0400				; size
	call FlashWrite				; flash read/copy
	push xiz
	call Free				; Free buffer
	inc 4, xsp				; clean stack
	call FileIO_ReturnError
	ld iz, hl
	jr LoadRegion7_PostMidi
LoadRegion7_AllocFailed:
	ldw iz, 0xff38				; alloc failure error code
LoadRegion7_PostMidi:
	ld wa, iz
	call PostMidiLoad
	jr LoadRegion7_Finalize
LoadRegion7_ModeError:
	ldw iz, 0xff9a				; mode unavailable error
LoadRegion7_Finalize:
	call FileIO_CloseHandle
	ld hl, iz
LoadRegion7_Return:
	pop xiz
	lda xsp, (xsp + 14)
	ret

FileIO_LoadRegion2_ExtMem:
	; --- Display region 2: external memory 0x0ab000-0x0fd800 ---
	lda xsp, (xsp - 18)
	pushw iz
	ld (xsp + 16), xwa			; save caller arg
	lda xwa, (xsp + 2)
	ld xbc, (xsp + 16)
	ld	de, 2:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, FileIO_LoadRegion2_ExtMem_Str_rb			; resource ID for region 2
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, LoadRegion2_OpenSuccess
	call FileIO_ReturnError
	jrl LoadRegion2_Return
LoadRegion2_OpenSuccess:
	ld	wa, 2:i3
	calr FileIO_CheckRegionSignature
	cp hl, 0:i3
	jr z, LoadRegion2_ModeError
	calr FileIO_ReadHeaderAt4			; check extended mode (region 2)
	cp hl, 0:i3
	jr z, LoadRegion2_AltSeqInit
	call SeqLoadPre				; primary ext memory init
	ld xwa, SEQ_SONG_SLOTS			; ext memory base
	ld xbc, 0x00005000			; size = 0x5000
	call FileIO_ReadBlock
	lda xwa, (0x0b0000:24); ext memory region 2
	ld xde, xwa
	lda xbc, (0x0fd800:24); end address
	sub xbc, xde				; size = 0x0fd800 - 0x0b0000
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call SeqLoadPost				; post-setup
	jr LoadRegion2_Finalize
LoadRegion2_AltSeqInit:
	call SeqLoad_JumpInitFromPreset				; alternate ext memory init
	ld xwa, SEQ_SONG_SLOTS
	ld xbc, 0x00000800			; smaller size
	call FileIO_ReadBlock
	lda xwa, (0x0b0000:24)
	ld xde, xwa
	lda xbc, (0x0fd800:24)
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call SeqLoad_PostAltEntry				; post-setup (alt)
	jr LoadRegion2_Finalize
LoadRegion2_ModeError:
	ldw iz, 0xff9a				; mode unavailable error
LoadRegion2_Finalize:
	call FileIO_CloseHandle
	cp iz, 0:i3				; check result
	jr lt, LoadRegion2_SkipVoiceCmd			; error, skip
	ld xwa, (xsp + 16)			; restore caller arg
	call VoiceSynth_CmdCase0				; additional processing
LoadRegion2_SkipVoiceCmd:
	ld hl, iz
LoadRegion2_Return:
	popw iz
	lda xsp, (xsp + 18)
	ret


FileIO_LoadSongRegion8:
	lda xsp, (xsp - 28)
	pushw iz
	ld (xsp + 26), xwa
	lda xwa, (xsp + 12)
	ld xbc, (xsp + 26)
	ldw de, 0x8
	call FileIO_ReadHeader
	lda xwa, (xsp + 12)
	ld xbc, FileIO_LoadSongRegion8_Str_rb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, LoadSong8_InitLoop
	call FileIO_ReturnError
	jrl LoadSong8_Return

LoadSong8_InitLoop:
	ld iz, 0:i3

LoadSong8_ReadLoop:
	call FileIO_ReadByte
	cp hl, 0:i3
	jr lt, LoadSong8_ReadDone
	lda xwa, (xsp + 4)
	ld	(xwa+iz), l
	inc 1, iz
	cp iz, 0x8
	jr lt, LoadSong8_ReadLoop

LoadSong8_ReadDone:
	call FileIO_ReturnError
	ld (xsp + 2), hl
	cpw (xsp + 2), 0x0
	jrl lt, FileIO_CloseHandle_Return
	call FileIO_SeekRead_ExtReturn
	lda xwa, (xsp + 4)
	call SeqLoad_ValidateFormat
	cp hl, 0:i3
	jrl z, LoadSong8_AltPresetPath
	cp hl, 1:i3
	jrl nz, FileIO_CloseHandle_Return
	call SeqLoad_JmpLoadPre
	ld xwa, SEQ_SONG_SLOTS
	ld xbc, 0x5000
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld (xsp + 2), hl
	cpw (xsp + 2), 0x0
	jr lt, LoadSong8_PostProcess
	call FileIO_CloseHandle
	lda xwa, (xsp + 12)
	ld xbc, (xsp + 26)
	ldw de, 0x9
	call FileIO_ReadHeader
	lda xwa, (xsp + 12)
	ld xbc, LoadSong8_ReadDone_Str_rb
	call FileIO_OpenWithMode
	call FileIO_ReturnError
	ld (xsp + 2), hl
	cpw (xsp + 2), 0x0
	jr lt, LoadSong8_PostProcess
	lda xwa, (0x0b0000:24)
	ld xde, xwa
	lda xbc, (0x0fd800:24)
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld (xsp + 2), hl

LoadSong8_PostProcess:
	ld wa, 0:i3
	ld bc, (xsp + 2)
	call SeqScan_ValidateAndDispatch
	ld iz, 0:i3

LoadSong8_SlotLoop:
	ldto_berp A, 0xf8
	extz wa
	call FileData_LoadFromSlot
	inc 1, iz
	cp iz, 0xa
	jr lt, LoadSong8_SlotLoop
	call SMF_InitSongPlayback
	ld wa, (xsp + 2)
	call SeqLoad_JmpLoadPost
	cpw (xsp + 2), 0x0
	jr lt, FileIO_CloseHandle_Return
	call ResetSlotsIfEmpty
	jr FileIO_CloseHandle_Return

LoadSong8_AltPresetPath:
	call SeqLoad_JmpInitPreset
	ld xwa, SEQ_SONG_SLOTS
	ld xbc, 0x800
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld (xsp + 2), hl
	cpw (xsp + 2), 0x0
	jr lt, Song_LoadAndInitPlayback
	call FileIO_CloseHandle
	lda xwa, (xsp + 12)
	ld xbc, (xsp + 26)
	ldw de, 0x9
	call FileIO_ReadHeader
	lda xwa, (xsp + 12)
	ld xbc, LoadSong8_AltPresetPath_Str_rb
	call FileIO_OpenWithMode
	call FileIO_ReturnError
	ld (xsp + 2), hl
	cpw (xsp + 2), 0x0
	jr lt, Song_LoadAndInitPlayback
	lda xwa, (0x0b0000:24)
	ld xde, xwa
	lda xbc, (0x0fd800:24)
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld (xsp + 2), hl

Song_LoadAndInitPlayback:
	ld wa, 0:i3
	call FileData_LoadFromSlot
	call SMF_InitSongPlayback
	ld wa, (xsp + 2)
	call SeqLoad_JmpAltEntry

FileIO_CloseHandle_Return:
	call FileIO_CloseHandle
	ld hl, (xsp + 2)

LoadSong8_Return:
	popw iz
	lda xsp, (xsp + 28)
	ret

; =============================================================================
; Display region management functions (F8784D-F87A07)
;
; Four more display region init/validate/configure functions following the
; same pattern as F8744F-F876CA.
; =============================================================================
FileIO_LoadRegion3_ExtMem:
	; --- Display region 3: ext memory 0x094800-0x0ab000 ---
	lda xsp, (xsp - 14)
	pushw iz
	ld xbc, xwa
	lda xwa, (xsp + 2)
	ld	de, 3:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, FileIO_LoadRegion3_ExtMem_Str_rb			; resource ID for region 3
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, LoadRegion3_OpenSuccess
	call FileIO_ReturnError
	jr LoadRegion3_Return
LoadRegion3_OpenSuccess:
	ld	wa, 3:i3
	calr FileIO_CheckRegionSignature
	cp hl, 0:i3
	jr z, LoadRegion3_AltPath
	call cmp_ld_mae
	lda xwa, (RHYTHM_PATTERN_BUF_A:24)
	ld xde, xwa
	lda xbc, (SEQ_SONG_SLOTS:24)
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call cmp_ld_ato
	jr LoadRegion3_Finalize
LoadRegion3_AltPath:
	call ToneParam_ExtendedOpsBlock				; alternate path
	ld iz, hl
LoadRegion3_Finalize:
	call FileIO_CloseHandle
	ld hl, iz
LoadRegion3_Return:
	popw iz
	lda xsp, (xsp + 14)
	ret

FileIO_LoadRegion5_VRAM:
	; --- Display region 5: VRAM 0x1e8800-0x1ec400 ---
	lda xsp, (xsp - 14)
	pushw iz
	ld xbc, xwa
	lda xwa, (xsp + 2)
	ld	de, 5:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, FileIO_LoadRegion5_VRAM_Str_rb			; resource ID for region 5
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, LoadRegion5_OpenSuccess
	call FileIO_ReturnError
	jr LoadRegion5_Return
LoadRegion5_OpenSuccess:
	ld	wa, 5:i3
	calr FileIO_CheckRegionSignature
	cp hl, 0:i3
	jr z, LoadRegion5_AltPath
	call msp_ld_mae
	lda xwa, (0x1e8800:24)
	ld xde, xwa
	lda xbc, (0x1ec400:24)
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call msp_ld_ato
	jr LoadRegion5_Finalize
LoadRegion5_AltPath:
	call FileIO_LoadMspAltFormat				; alternate path
	ld iz, hl
LoadRegion5_Finalize:
	call FileIO_CloseHandle
	ld hl, iz
LoadRegion5_Return:
	popw iz
	lda xsp, (xsp + 14)
	ret

FileIO_LoadRegion6_Simple:
	; --- Display region 6: simple init ---
	lda xsp, (xsp - 14)
	pushw iz
	ld xbc, xwa
	lda xwa, (xsp + 2)
	ld	de, 6:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, FileIO_LoadRegion6_Simple_Str_rb			; resource ID for region 6
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, LoadRegion6_OpenSuccess
	call FileIO_ReturnError
	jr LoadRegion6_Return
LoadRegion6_OpenSuccess:
	ld	wa, 6:i3
	calr FileIO_CheckRegionSignature
	cp hl, 0:i3
	jr z, LoadRegion6_ModeError
	call FileIO_LoadRcmToFlash
	ld iz, hl
	jr LoadRegion6_Finalize
LoadRegion6_ModeError:
	ldw iz, 0xff9a				; mode unavailable
LoadRegion6_Finalize:
	call FileIO_CloseHandle
	ld hl, iz
LoadRegion6_Return:
	popw iz
	lda xsp, (xsp + 14)
	ret

FileIO_LoadRegion4_VRAM:
	; --- Display region 4: VRAM 0x1e0000-0x1e7800 (with iteration loop) ---
	lda xsp, (xsp - 30)
	pushw iz
	ld xbc, xwa
	lda xwa, (xsp + 18)
	ld	de, 4:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 18)
	ld xbc, FileIO_LoadRegion4_VRAM_Str_rb			; resource ID for region 4
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, LoadRegion4_OpenSuccess
	call FileIO_ReturnError
	jrl LoadRegion4_Return
LoadRegion4_OpenSuccess:
	ld	wa, 4:i3
	calr FileIO_CheckRegionSignature
	cp hl, 0:i3
	jr z, LoadRegion4_AltIterLoop
	call PreTmLoad
	lda xwa, (0x1e0000:24)
	ld xde, xwa
	lda xbc, (0x1e7800:24)
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call PostTmLoad
	jr LoadRegion4_Finalize
LoadRegion4_AltIterLoop:
	ld	iz, 0:i3
LoadRegion4_ReadByteLoop:
	call FileIO_ReadByte
	cp hl, 0:i3
	jr lt, LoadRegion4_ReadDone
	lda xwa, (xsp + 2)
	ld	(xwa+iz), l
	inc 1, iz
	cp iz, 0x0010				; loop 16 times
	jr lt, LoadRegion4_ReadByteLoop
LoadRegion4_ReadDone:
	call FileIO_ReturnError
	ld iz, hl
	cp iz, 0:i3
	jr lt, LoadRegion4_PostSave
	lda xwa, (xsp + 2)
	call PostTmSave_ByteBlock
	ld iz, hl
	cp iz, 0:i3
	jr lt, LoadRegion4_PostSave
	call FileIO_SeekRead_ExtReturn
	lda xwa, (0x1e0000:24)
	ld xde, xwa
	lda xbc, (0x1e7800:24)
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
LoadRegion4_PostSave:
	ld wa, iz
	call PostTmSave_Success
LoadRegion4_Finalize:
	call FileIO_CloseHandle
	ld hl, iz
LoadRegion4_Return:
	popw iz
	lda xsp, (xsp + 30)
	ret


FileIO_ParseDirectoryEntry:
	lda xsp, (xsp - 16)
	push xiz
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	ld iz, hl
	cp iz, 0:i3
	jr ge, ParseDir_ValidIndex
	ldw hl, 0xff98
	jrl ParseDir_Return

ParseDir_ValidIndex:
	ld wa, iz
	call GetFileEntryPtr
	ld (xsp + 4), xhl
	ldto_berp C, 0xf8
	extz bc
	lda xwa, (xsp + 10)
	ld xde, (xsp + 4)
	call FileIO_FormatFileIndex
	ldw (xsp + 8), 0x0
	ld iz, 0:i3

; File demo record callback dispatch
FileDemo_RecordCallback:
	ld wa, iz
	muls wa, 0x6
	lda xbc, (FileIO_RegionLoaders:24)
	ld	a, (xbc+wa)
	call FileIO_WriteRecordName_Done
	cp l, 0:i3
	jr z, FileIO_RecordLoop_Continue
	ld wa, iz
	muls wa, 0x6
	lda xbc, (FileIO_RegionLoaders:24)
	ld	a, (xbc+wa)
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, FileIO_RecordLoop_Continue
	lda xwa, (xsp + 10)
	ld bc, iz
	muls bc, 0x6
	lda xde, (FileIO_TypeLoaderColumn:24)
	exts xbc
	add xbc, xde
	ld xix, (xbc)
	call (xix)
	cp hl, 0:i3
	jr ge, ParseDir_IncrementCount
	cpiw_erp 0xfa, 0
	jr lt, FileIO_RecordLoop_Continue
	ldfr_werp HL, 0xfa
	jr FileIO_RecordLoop_Continue

ParseDir_IncrementCount:
	incw 1, (xsp + 8)

FileIO_RecordLoop_Continue:
	inc 1, iz
	cp iz, 0x8
	jr lt, FileDemo_RecordCallback
	ld wa, 2:i3
	call FileIO_WriteRecordName_Done
	cp l, 0:i3
	jr z, FileIO_FinalizeRecordLookup
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, FileIO_FinalizeRecordLookup
	ldw wa, 0x9
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, FileIO_FinalizeRecordLookup
	lda xwa, (xsp + 10)
	calr FileIO_LoadSongRegion8
	cp hl, 0:i3
	jr ge, ParseDir_SongIncrCount
	cpiw_erp 0xfa, 0
	jr lt, FileIO_FinalizeRecordLookup
	ldfr_werp HL, 0xfa
	jr FileIO_FinalizeRecordLookup

ParseDir_SongIncrCount:
	incw 1, (xsp + 8)

FileIO_FinalizeRecordLookup:
	cpw (xsp + 8), 0x0
	jr le, ParseDir_NoRecords
	ld xwa, (xsp + 4)
	call FileIO_GetRecordByType_Lookup
	jr ParseDir_GetResult

ParseDir_NoRecords:
	cpiw_erp 0xfa, 0
	jr lt, ParseDir_GetResult
	ldi_erpw 0xfa, 0x98, 0xff

ParseDir_GetResult:
	ldto_werp HL, 0xfa

ParseDir_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

; =============================================================================
; Display region save/restore functions (F87AF6-F87EAC)
;
; 8 functions that save display region data to external memory or VRAM.
; Each follows the pattern: check available space via F89556, open resource
; via F891AB/F88BC7, configure ranges via F88E28, finalize via F88C48.
; Plus 1 simpler function (F87E00) that calls F187F3.
; Resource IDs: 0xea01f0 through 0xea020c (one per region).
; Returns HL=0xff9b on insufficient space.
; =============================================================================
FileIO_SaveRegion0_VRAM:
	; --- Save region 0: VRAM F980-FFC0, ext mem 1E7800-1E8000 ---
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 22), xwa			; save arg
	lda	xbc, (0xffc0:16)
	lda	xwa, (0xf980:16)
	ld (xsp + 4), xbc			; save end address
	sub (xsp + 4), xwa			; size = end - start
	lda xbc, (0x1e7800:24)
	lda xiz, (0x1e8000:24)
	sub xiz, xbc				; VRAM size
	call FileIO_GetDiskFreeSpace				; get available space
	ld xwa, (xsp + 4)			; total size needed
	add xwa, xiz
	cp xhl, xwa				; enough space?
	jr ge, SaveRegion0_SpaceOk			; yes
	ldw hl, 0xff9b				; error: insufficient space
	jr SaveRegion0_Return				; return error
SaveRegion0_SpaceOk:
	lda xwa, (xsp + 8)			; local buffer
	ld xbc, (xsp + 22)			; saved arg
	ld	de, 0:i3
	call FileIO_ReadHeader				; init region
	lda xwa, (xsp + 8)			; buffer
	ld xbc, SaveRegion0_SpaceOk_Str_wb			; resource ID region 0
	call FileIO_OpenWithMode				; open resource
	cp hl, 0:i3
	jr ge, SaveRegion0_OpenSuccess			; success
	call FileIO_ReturnError				; close/cleanup
	jr SaveRegion0_Return				; return error
SaveRegion0_OpenSuccess:
	call PreLswSave				; pre-save hook
	ld xwa, 0x0000f980			; VRAM start
	ld xbc, (xsp + 4)			; VRAM size
	call FileIO_WriteByte_Impl				; save range 1
	ld xwa, 0x001e7800			; ext mem start
	ld xbc, xiz				; ext mem size
	call FileIO_WriteByte_Impl				; save range 2
	call FileIO_ReturnError				; close
	ld iz, hl				; save status
	ld wa, iz
	call PostLswSave				; post-save hook
	call FileIO_CloseHandle			; finalize
	cp iz, 0:i3
	jr ge, SaveRegion0_Done			; success
	lda xwa, (xsp + 8)
	call FileIO_OpenDefault				; error cleanup
SaveRegion0_Done:
	ld hl, iz				; return status
SaveRegion0_Return:
	pop xiz
	lda xsp, (xsp + 22)
	ret

FileIO_SaveRegion1_VRAM:
	; --- Save region 1: VRAM at 1ED350, conditional size ---
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 18), xwa			; save arg
	call FileIO_GetRecordAttr_Check				; get display mode
	lda xbc, (0x1ed350:24); base address
	cp l, 0:i3				; check mode
	jr z, SaveRegion1_FullRange			; mode 0 path
	ld iz, (xbc + 13)			; get size param
	extz xiz
	sla xiz, 3				; * 8
	add xiz, 0x000000b0			; + 0xb0 base size
	jr SaveRegion1_CheckSpace
SaveRegion1_FullRange:
	lda xiz, (0x200000:24); full range
	sub xiz, xbc				; size = 0x200000 - 0x1ed350
SaveRegion1_CheckSpace:
	call FileIO_GetDiskFreeSpace				; get available space
	cp xhl, xiz				; enough?
	jr ge, SaveRegion1_SpaceOk
	ldw hl, 0xff9b
	jr SaveRegion1_Return
SaveRegion1_SpaceOk:
	lda xwa, (xsp + 4)			; buffer
	ld xbc, (xsp + 18)			; arg
	ld	de, 1:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, SaveRegion1_SpaceOk_Str_wb			; resource ID region 1
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, SaveRegion1_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion1_Return
SaveRegion1_OpenSuccess:
	call FileIO_GetRecordAttr_Check				; re-check mode
	cp l, 0:i3
	jr z, SaveRegion1_AltPmSave			; mode 0 path
	ld xwa, 0x001ed350
	ld xbc, xiz
	call FileIO_WriteByte_Impl				; save VRAM range
	ld xwa, 0x0000000f			; param
	ld	bc, 0:i3
	call FileIO_SeekAndReadBlock				; set region param
	ldw wa, 0x0008
	call FileIO_ReadByte_BufferHit				; configure
	call FileIO_ReturnError
	ld iz, hl
	jr SaveRegion1_Finalize
SaveRegion1_AltPmSave:
	call PrePmSave				; alternate pre-save
	ld xwa, 0x001ed350
	ld xbc, xiz
	call FileIO_WriteByte_Impl
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call PostPmSave				; alternate post-save
SaveRegion1_Finalize:
	call FileIO_CloseHandle
	cp iz, 0:i3
	jr ge, SaveRegion1_Done
	lda xwa, (xsp + 4)
	call FileIO_OpenDefault
SaveRegion1_Done:
	ld hl, iz
SaveRegion1_Return:
	pop xiz
	lda xsp, (xsp + 18)
	ret

FileIO_SaveRegion7_Flash:
	; --- Save region 7: flash 3D3000, fixed 0x400 bytes ---
	lda xsp, (xsp - 14)
	push xiz
	ld xiz, xwa				; XIZ = arg
	call FileIO_GetDiskFreeSpace
	cp xhl, 0x00000400			; need 1024 bytes
	jr ge, SaveRegion7_SpaceOk
	ldw hl, 0xff9b
	jr SaveRegion7_Return
SaveRegion7_SpaceOk:
	lda xwa, (xsp + 4)
	ld xbc, xiz
	ld	de, 7:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, Resource_Region7_Start			; resource ID region 7
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, SaveRegion7_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion7_Return
SaveRegion7_OpenSuccess:
	call PreMidiSave				; pre-save hook
	ld xwa, 0x003d3000			; flash address
	ld xbc, 0x00000400			; 1024 bytes
	call FileIO_WriteByte_Impl
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call PostMidiSave				; post-save hook
	call FileIO_CloseHandle
	cp iz, 0:i3
	jr ge, SaveRegion7_Done
	lda xwa, (xsp + 4)
	call FileIO_OpenDefault
SaveRegion7_Done:
	ld hl, iz
SaveRegion7_Return:
	pop xiz
	lda xsp, (xsp + 14)
	ret

FileIO_SaveRegion2_ExtMem:
	; --- Save region 2: ext mem 0AB000 + computed size ---
	lda xsp, (xsp - 18)
	push xiz
	ld xiz, xwa
	call SeqSavePre				; get size info
	ld (xsp + 4), xhl			; save size
	call FileIO_GetDiskFreeSpace
	ld xwa, (xsp + 4)			; size
	add xwa, 0x00005000			; add overhead
	cp xhl, xwa
	jr ge, SaveRegion2_SpaceOk
	ldw hl, 0xff9b
	jr SaveRegion2_Return
SaveRegion2_SpaceOk:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	ld	de, 2:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 8)
	ld xbc, Resource_Region2_Start			; resource ID region 2
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, SaveRegion2_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion2_Return
SaveRegion2_OpenSuccess:
	ld xwa, SEQ_SONG_SLOTS			; ext mem base
	ld xbc, 0x00005000			; fixed range
	call FileIO_WriteByte_Impl
	ld xwa, 0x000b0000			; second range base
	ld xbc, (xsp + 4)			; computed size
	call FileIO_WriteByte_Impl
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call SeqSavePost				; post-save hook
	call FileIO_CloseHandle
	cp iz, 0:i3
	jr ge, SaveRegion2_Done
	lda xwa, (xsp + 8)
	call FileIO_OpenDefault
SaveRegion2_Done:
	ld hl, iz
SaveRegion2_Return:
	pop xiz
	lda xsp, (xsp + 18)
	ret

FileIO_SaveRegion3_ExtMem:
	; --- Save region 3: ext mem 094800, computed size ---
	lda xsp, (xsp - 18)
	push xiz
	ld xiz, xwa
	call cmp_sv_mae				; get size
	ld (xsp + 4), xhl
	call FileIO_GetDiskFreeSpace
	cp xhl, (xsp + 4)
	jr ge, SaveRegion3_SpaceOk
	ldw hl, 0xff9b
	jr SaveRegion3_Return
SaveRegion3_SpaceOk:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	ld	de, 3:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 8)
	ld xbc, Resource_Region3_Start			; resource ID region 3
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, SaveRegion3_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion3_Return
SaveRegion3_OpenSuccess:
	ld xwa, RHYTHM_PATTERN_BUF_A			; ext mem start
	ld xbc, (xsp + 4)			; computed size
	call FileIO_WriteByte_Impl
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call cmp_sv_ato				; post-save
	call FileIO_CloseHandle
	cp iz, 0:i3
	jr ge, SaveRegion3_Done
	lda xwa, (xsp + 8)
	call FileIO_OpenDefault
SaveRegion3_Done:
	ld hl, iz
SaveRegion3_Return:
	pop xiz
	lda xsp, (xsp + 18)
	ret

FileIO_SaveRegion5_VRAM:
	; --- Save region 5: VRAM 1E8800, computed size ---
	lda xsp, (xsp - 18)
	push xiz
	ld xiz, xwa
	call msp_sv_mae				; get size
	ld (xsp + 4), xhl
	call FileIO_GetDiskFreeSpace
	cp xhl, (xsp + 4)
	jr ge, SaveRegion5_SpaceOk
	ldw hl, 0xff9b
	jr SaveRegion5_Return
SaveRegion5_SpaceOk:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	ld	de, 5:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 8)
	ld xbc, SaveRegion5_SpaceOk_Str_wb			; resource ID region 5
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, SaveRegion5_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion5_Return
SaveRegion5_OpenSuccess:
	ld xwa, 0x001e8800			; VRAM start
	ld xbc, (xsp + 4)			; computed size
	call FileIO_WriteByte_Impl
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call msp_sv_ato				; post-save
	call FileIO_CloseHandle
	cp iz, 0:i3
	jr ge, SaveRegion5_Done
	lda xwa, (xsp + 8)
	call FileIO_OpenDefault
SaveRegion5_Done:
	ld hl, iz
SaveRegion5_Return:
	pop xiz
	lda xsp, (xsp + 18)
	ret

FileIO_SaveRegion6_Simple:
	; --- Save region 6: simple, calls F187F3 ---
	lda xsp, (xsp - 14)
	pushw iz
	ld xbc, xwa
	lda xwa, (xsp + 2)
	ld	de, 6:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, FileIO_SaveRegion6_Simple_Str_wb			; resource ID region 6
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, SaveRegion6_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion6_Return
SaveRegion6_OpenSuccess:
	call FileIO_SaveRcmFromFlash				; region-specific handler
	ld iz, hl
	call FileIO_CloseHandle
	cp iz, 0:i3
	jr ge, SaveRegion6_Done
	lda xwa, (xsp + 2)
	call FileIO_OpenDefault
SaveRegion6_Done:
	ld hl, iz
SaveRegion6_Return:
	popw iz
	lda xsp, (xsp + 14)
	ret

FileIO_SaveRegion4_VRAM:
	; --- Save region 4: VRAM 1E0000, fixed 0x72aa bytes ---
	lda xsp, (xsp - 14)
	push xiz
	ld xiz, xwa
	call FileIO_GetDiskFreeSpace
	cp xhl, 0x000072aa			; need 29,354 bytes
	jr ge, SaveRegion4_SpaceOk
	ldw hl, 0xff9b
	jr SaveRegion4_Return
SaveRegion4_SpaceOk:
	lda xwa, (xsp + 4)
	ld xbc, xiz
	ld	de, 4:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, SaveRegion4_SpaceOk_Str_wb			; resource ID region 4
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, SaveRegion4_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion4_Return
SaveRegion4_OpenSuccess:
	call PreTmSave				; pre-save hook
	ld xwa, 0x001e0000			; VRAM base
	ld xbc, 0x000072aa			; size
	call FileIO_WriteByte_Impl
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call PostTmSave				; post-save hook
	call FileIO_CloseHandle
	cp iz, 0:i3
	jr ge, SaveRegion4_Done
	lda xwa, (xsp + 4)
	call FileIO_OpenDefault
SaveRegion4_Done:
	ld hl, iz
SaveRegion4_Return:
	pop xiz
	lda xsp, (xsp + 14)
	ret


FileIO_SaveAllRegions:
	lda xsp, (xsp - 26)
	push xiz
	ldw (xsp + 4), 0x0
	call GetCurrentFileIndex
	ld iz, hl
	cp iz, 0:i3
	jr ge, SaveAll_GetEntryPtr
	ldw hl, 0xff98
	jrl SaveAll_Return

SaveAll_GetEntryPtr:
	ld wa, iz
	call GetFileEntryPtr
	ld xde, xhl
	ldto_berp C, 0xf8
	extz bc
	lda xwa, (xsp + 20)
	call FileIO_FormatFileIndex
	ldiw_erp 0xfa, 0

SaveAll_CheckRecordLoop:
	ldto_werp WA, 0xfa
	muls wa, 0x6
	lda xbc, (SaveAll_RegionSaveRecs:24)
	ld	a, (xbc+wa)
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, SaveAll_NextRecord
	lda xbc, (xsp + 20)
	ldto_werp WA, 0xfa
	muls wa, 0x6
	lda xde, (SaveAll_RegionSaveRecs:24)
	ld	e, (xde+wa)
	lda xwa, (xsp + 6)
	call FileIO_ReadHeader
	lda xwa, (xsp + 6)
	call FileIO_OpenDefault
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jrl lt, SaveAll_GetResult

SaveAll_NextRecord:
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x08, 0x00
	jr lt, SaveAll_CheckRecordLoop
	lda xbc, (xsp + 20)
	lda xwa, (xsp + 6)
	ldw de, 0x8
	call FileIO_ReadHeader
	lda xwa, (xsp + 6)
	call FileIO_OpenDefault
	lda xbc, (xsp + 20)
	lda xwa, (xsp + 6)
	ldw de, 0x9
	call FileIO_ReadHeader
	lda xwa, (xsp + 6)
	call FileIO_OpenDefault
	call FileIO_GetRecordByType
	ld xde, xhl
	ldto_berp C, 0xf8
	extz bc
	lda xwa, (xsp + 20)
	call FileIO_FormatFileIndex
	ldiw_erp 0xfa, 0

; File demo process callback dispatch
FileDemo_ProcessCallback:
	ldto_werp WA, 0xfa
	muls wa, 0x6
	lda xbc, (SaveAll_RegionSaveRecs:24)
	ld	a, (xbc+wa)
	call FileIO_FormatName_Return
	cp l, 0:i3
	jr z, SaveAll_ProcessNextRecord
	lda xwa, (xsp + 20)
	ldto_werp BC, 0xfa
	muls bc, 0x6
	lda xde, (SaveAll_RegionRecs_HandlerCol:24)
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jr lt, SaveAll_CheckSaveError

SaveAll_ProcessNextRecord:
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x08, 0x00
	jr lt, FileDemo_ProcessCallback

SaveAll_CheckSaveError:
	cpw (xsp + 4), 0x0
	jr ge, SaveAll_GetResult
	ldiw_erp 0xfa, 0

SaveAll_RollbackLoop:
	ldto_werp WA, 0xfa
	muls wa, 0x6
	lda xbc, (SaveAll_RegionSaveRecs:24)
	ld	a, (xbc+wa)
	call FileIO_FormatName_Return
	cp l, 0:i3
	jr z, SaveAll_RollbackNext
	lda xbc, (xsp + 20)
	ldto_werp WA, 0xfa
	muls wa, 0x6
	lda xde, (SaveAll_RegionSaveRecs:24)
	ld	e, (xde+wa)
	lda xwa, (xsp + 6)
	call FileIO_ReadHeader
	lda xwa, (xsp + 6)
	call FileIO_OpenDefault

SaveAll_RollbackNext:
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x08, 0x00
	jr lt, SaveAll_RollbackLoop

SaveAll_GetResult:
	ld hl, (xsp + 4)

SaveAll_Return:
	pop xiz
	lda xsp, (xsp + 26)
	ret

LoadFileSMF:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), c
	ld (xsp + 8), wa
	call GetFirstPageBase
	cp hl, 0:i3
	jr ge, LoadSMF_GetRecordPtr
	ldw hl, 0xff98
	jr LoadSMF_Return

LoadSMF_GetRecordPtr:
	ld wa, hl
	call GetRecordPtrForFile
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	ld xbc, LoadSMF_GetRecordPtr_Str_rb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, LoadSMF_OpenAndProcess
	call FileIO_ReturnError
	jr LoadSMF_Return

LoadSMF_OpenAndProcess:
	ld wa, (xsp + 8)
	extz wa
	ld c, (xsp + 6)
	extz bc
	call SMF_SelectBankAndLoad
	ld iz, hl
	call FileIO_CloseHandle
	ld xwa, (xsp + 2)
	call FileIO_WriteRecordName
	ld hl, iz

LoadSMF_Return:
	popw iz
	inc 8, xsp
	ret

LoadFileVariant:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), e
	ld (xsp + 8), c
	ld iz, wa
	call FileIO_GetRecordPtrAlt
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	ld xbc, LoadFileVariant_Str_wb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, LoadVariant_OpenAndProcess
	call FileIO_ReturnError
	jr LoadVariant_Return

LoadVariant_OpenAndProcess:
	ldto_berp A, 0xf8
	extz wa
	ld c, (xsp + 8)
	extz bc
	ld e, (xsp + 6)
	extz de
	call SMF_LoadSoundBankAndPlay
	ld iz, hl
	call FileIO_CloseHandle
	cp iz, 0:i3
	jr ge, LoadVariant_CheckResult
	ld xwa, (xsp + 2)
	call FileIO_OpenDefault

LoadVariant_CheckResult:
	ld hl, iz

LoadVariant_Return:
	popw iz
	inc 8, xsp
	ret

LoadFileMultiPass:
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 30), wa
	call GetCurrentFileIndex
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jr ge, MultiPass_SetupEntry
	ldw hl, 0xff98
	jrl MultiPass_Return

MultiPass_SetupEntry:
	ld wa, (xsp + 4)
	ldfr_berp A, 0xf8
	extz iz
	ld wa, (xsp + 4)
	call GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 20)
	ld bc, iz
	call FileIO_FormatFileIndex
	ld iz, 0:i3

MultiPass_RetryLoop:
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	a, (xwa+iz)
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, MultiPass_LoopNext
	lda xbc, (xsp + 20)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 6)
	call FileIO_ReadHeader
	lda xwa, (xsp + 6)
	call FileIO_OpenDefault
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, MultiPass_StoreResult

MultiPass_LoopNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, MultiPass_RetryLoop
	ld wa, (xsp + 4)
	ldfr_berp A, 0xf8
	extz iz
	call FileIO_GetRecordByType
	ld xde, xhl
	lda xwa, (xsp + 20)
	ld bc, iz
	call FileIO_FormatFileIndex
	lda xbc, (xsp + 20)
	lda xwa, (xsp + 6)
	ld de, 2:i3
	call FileIO_ReadHeader
	lda xwa, (xsp + 6)
	ld xbc, MultiPass_LoopNext_Str_wb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, MultiPass_Finalize
	call FileIO_ReturnError
	jr MultiPass_Return

MultiPass_Finalize:
	ld wa, (xsp + 30)
	extz wa
	call SeqSave_PreparePartData
	ldfr_werp HL, 0xfa
	call FileIO_CloseHandle
	cpiw_erp 0xfa, 0
	jr ge, MultiPass_StoreResult
	lda xwa, (xsp + 6)
	call FileIO_OpenDefault

MultiPass_StoreResult:
	ldto_werp HL, 0xfa

MultiPass_Return:
	pop xiz
	lda xsp, (xsp + 28)
	ret

FileIO_ByteBlock_DemoProc1:
	lda	xsp, (xsp-36)
	push	xiz
	ld	(xsp+36), bc
	ld	(xsp+38), wa
	call	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	ge, FileIO_ByteBlock_DemoProc1_Skip
	ldw	hl, 0xff98
	jrl	FileIO_ByteBlock_DemoProc1_Epilogue
FileIO_ByteBlock_DemoProc1_Skip:
	ld	a, l
	ldfr_berp a, 248
	extz	iz
	ld	wa, hl
	call	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+26)
	ld	bc, iz
	call	FileIO_FormatFileIndex
	lda	xbc, (xsp+26)
	lda	xwa, (xsp+12)
	ld	de, 1:i3
	call	FileIO_ReadHeader
	lda	xwa, (xsp+12)
	.byte 0x41
	.long Resource_RegionPad
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, FileIO_ByteBlock_DemoProc1_Skip2
	call	FileIO_ReturnError
	jrl	FileIO_ByteBlock_DemoProc1_Epilogue
FileIO_ByteBlock_DemoProc1_Skip2:
	ld	wa, 1:i3
	calr	FileIO_CheckRegionSignature
	cp	hl, 0:i3
	jr	z, FileIO_ByteBlock_DemoProc1_Skip3
	ld	wa, (0x1ed35d:24)
	extz	xwa
	ld	(xsp+8), xwa
	ld	wa, (xsp+38)
	extz	xwa
	ld	xbc, (xsp+8)
	call	Math_MultiplyAccumulate
	ld	xiz, xhl
	add	xiz, 176
	ld	wa, (xsp+36)
	extz	xwa
	ld	xbc, (xsp+8)
	call	Math_MultiplyAccumulate
	ld	(xsp+4), xhl
	ld	xwa, 176
	add	(xsp+4), xwa
	ld	xwa, xiz
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	ld	iz, hl
	cp	iz, 0:i3
	jr	lt, FileIO_ByteBlock_DemoProc1_Join
	ld	wa, (xsp+36)
	extz	wa
	call	PanelMemory_PreSlotLoad
	lda	xwa, (0x1ed350:24)
	add	xwa, (xsp+0x4)
	ld	xbc, (xsp+0x8)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	ld	wa, (xsp+36)
	extz	wa
	ld	bc, iz
	call	PanelMemory_PostSlotLoad
	jr	FileIO_ByteBlock_DemoProc1_Join
FileIO_ByteBlock_DemoProc1_Skip3:
	ldw	iz, 0xff9a
FileIO_ByteBlock_DemoProc1_Join:
	call	FileIO_CloseHandle
	ld	hl, iz
FileIO_ByteBlock_DemoProc1_Epilogue:
	pop	xiz
	lda	xsp, (xsp+36)
	ret
SingleLoad_LoadPanelMemBank:
	lda	xsp, (xsp-36)
	push	xiz
	ld	(xsp+36), bc
	ld	(xsp+38), wa
	call	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	ge, SingleLoad_LoadPanelMemBank_Skip4
	ldw	hl, 0xff98
	jrl	SingleLoad_LoadPanelMemBank_Epilogue2
SingleLoad_LoadPanelMemBank_Skip4:
	ld	a, l
	extz	wa
	ld	(xsp+10), wa
	ld	wa, hl
	call	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+26)
	ld	bc, (xsp+10)
	call	FileIO_FormatFileIndex
	lda	xbc, (xsp+26)
	lda	xwa, (xsp+12)
	ld	de, 1:i3
	call	FileIO_ReadHeader
	lda	xwa, (xsp+12)
	ld	xbc, FileIO_ByteBlock_DemoProc1_Str_rb
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, SingleLoad_LoadPanelMemBank_Skip5
	call	FileIO_ReturnError
	jrl	SingleLoad_LoadPanelMemBank_Epilogue2
SingleLoad_LoadPanelMemBank_Skip5:
	ld	wa, 1:i3
	calr	FileIO_CheckRegionSignature
	cp	hl, 0:i3
	jrl	z, SingleLoad_LoadPanelMemBank_Skip6
	ld	wa, (xsp+38)
	extz	xwa
	ld	xiz, xwa
	sll	xiz, 4
	add	xiz, 16
	ld	wa, (xsp+36)
	extz	xwa
	ld	(xsp+4), xwa
	sll	xwa, 4
	ld	(xsp+4), xwa
	ld	xwa, 16
	add	(xsp+4), xwa
	ld	xwa, xiz
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	ld	iz, hl
	cp	iz, 0:i3
	jrl	lt, SingleLoad_LoadPanelMemBank_Join2
	ld	wa, (xsp+36)
	extz	wa
	call	PanelMemory_PreBankLoad
	lda	xwa, (0x1ed350:24)
	add	xwa, (xsp+0x4)
	ld	xbc, 16
	call	FileIO_ReadBlock
	ld	wa, (0x1ed35d:24)
	extz	xwa
	ld	(xsp+8), xwa
	sll	xwa, 3
	ld	(xsp+8), xwa
	ld	wa, (xsp+38)
	extz	xwa
	ld	xbc, (xsp+8)
	call	Math_MultiplyAccumulate
	ld	xiz, xhl
	add	xiz, 176
	ld	wa, (xsp+36)
	extz	xwa
	ld	xbc, (xsp+8)
	call	Math_MultiplyAccumulate
	ld	(xsp+4), xhl
	ld	xwa, 176
	add	(xsp+4), xwa
	ld	xwa, xiz
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	lda	xwa, (0x1ed350:24)
	add	xwa, (xsp+0x4)
	ld	xbc, (xsp+0x8)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	ld	wa, (xsp+36)
	extz	wa
	ld	bc, iz
	call	PanelMemory_PostBankLoad
	jr	SingleLoad_LoadPanelMemBank_Join2
SingleLoad_LoadPanelMemBank_Skip6:
	ldw	iz, 0xff9a
SingleLoad_LoadPanelMemBank_Join2:
	call	FileIO_CloseHandle
	ld	hl, iz
SingleLoad_LoadPanelMemBank_Epilogue2:
	pop	xiz
	lda	xsp, (xsp+36)
	ret
SingleLoad_LoadSong:
	lda	xsp, (xsp-30)
	push	xiz
	ld	(xsp+32), wa
	call	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	ge, SingleLoad_LoadSong_Skip7
	ldw	hl, 0xff98
	jrl	SingleLoad_LoadSong_Epilogue3
SingleLoad_LoadSong_Skip7:
	ld	a, l
	ldfr_berp a, 248
	extz	iz
	ld	wa, hl
	call	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+22)
	ld	bc, iz
	call	FileIO_FormatFileIndex
	lda	xbc, (xsp+22)
	lda	xwa, (xsp+8)
	ld	de, 2:i3
	call	FileIO_ReadHeader
	lda	xwa, (xsp+8)
	ld	xbc, FileIO_ByteBlock_DemoProc1_Str_rb_2
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, SingleLoad_LoadSong_Skip8
	call	FileIO_ReturnError
	jrl	SingleLoad_LoadSong_Epilogue3
SingleLoad_LoadSong_Skip8:
	ld	wa, 2:i3
	calr	FileIO_CheckRegionSignature
	cp	hl, 0:i3
	jr	z, SingleLoad_LoadSong_Skip11
	calr	FileIO_ReadHeaderAt4
	cp	hl, 0:i3
	jr	z, SingleLoad_LoadSong_Skip9
	ldw	iz, 0xff96
	jr	SingleLoad_LoadSong_Join3
SingleLoad_LoadSong_Skip9:
	ld	wa, (xsp+32)
	extz	wa
	call	SeqLoad_ProcessDataBlock
	ld	(xsp+4), xhl
	call	GetCurrentFileIndex
	ld	wa, hl
	ld	bc, 2:i3
	call	UpdateFileEntry
	cp	(xsp+4), xhl
	jr	c, SingleLoad_LoadSong_Skip10
	ld	wa, (xsp+32)
	extz	wa
	call	FileIO_ByteBlock_DemoProc1_Helper
	ld	xiz, xhl
	ld	bc, (xsp+32)
	extz	xbc
	sll	xbc, 11
	lda	xwa, (SEQ_SONG_SLOTS:24)
	add	xwa, xbc
	ld	xbc, 2048
	call	FileIO_ReadBlock
	lda	xwa, (0xb0000:24)
	add	xwa, xiz
	ld	xbc, (xsp+4)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	ld	wa, (xsp+32)
	extz	wa
	ld	bc, iz
	call	FileIO_ByteBlock_DemoProc1_Helper2
	cp	iz, 0:i3
	jr	lt, SingleLoad_LoadSong_Join3
	ld	wa, (xsp+32)
	ld	bc, 0:i3
	call	SetSongSlotValue
	jr	SingleLoad_LoadSong_Join3
SingleLoad_LoadSong_Skip10:
	ldw	iz, 0xff97
	jr	SingleLoad_LoadSong_Join3
SingleLoad_LoadSong_Skip11:
	ldw	iz, 0xff9a
SingleLoad_LoadSong_Join3:
	call	FileIO_CloseHandle
	ld	hl, iz
SingleLoad_LoadSong_Epilogue3:
	pop	xiz
	lda	xsp, (xsp+30)
	ret
SingleLoad_LoadComposerPattern:
	lda	xsp, (xsp-28)
	pushw	iz
	ld	(xsp+26), bc
	ld	(xsp+28), wa
	call	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	ge, SingleLoad_LoadComposerPattern_Skip12
	ldw	hl, 0xff98
	jr	SingleLoad_LoadComposerPattern_Epilogue4
SingleLoad_LoadComposerPattern_Skip12:
	ld	a, l
	ldfr_berp a, 248
	extz	iz
	ld	wa, hl
	call	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+16)
	ld	bc, iz
	call	FileIO_FormatFileIndex
	lda	xbc, (xsp+16)
	lda	xwa, (xsp+2)
	ld	de, 3:i3
	call	FileIO_ReadHeader
	lda	xwa, (xsp+2)
	ld	xbc, FileIO_ByteBlock_DemoProc1_Str_rb_3
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, SingleLoad_LoadComposerPattern_Skip13
	call	FileIO_ReturnError
	jr	SingleLoad_LoadComposerPattern_Epilogue4
SingleLoad_LoadComposerPattern_Skip13:
	calr	FileIO_ReadAndValidateHeader
	cp	hl, 0:i3
	jr	z, SingleLoad_LoadComposerPattern_Skip14
	ld	wa, (xsp+28)
	extz	wa
	ld	bc, (xsp+26)
	extz	bc
	call	FileIO_ByteBlock_DemoProc1_Helper3
	ld	iz, hl
	jr	SingleLoad_LoadComposerPattern_Join4
SingleLoad_LoadComposerPattern_Skip14:
	ldw	iz, 0xff9a
SingleLoad_LoadComposerPattern_Join4:
	call	FileIO_CloseHandle
	ld	hl, iz
SingleLoad_LoadComposerPattern_Epilogue4:
	popw	iz
	lda	xsp, (xsp+28)
	ret
SingleLoad_LoadSoundMemEntry:
	lda	xsp, (xsp-42)
	pushw	iz
	ld	(xsp+40), bc
	ld	(xsp+42), wa
	call	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	ge, SingleLoad_LoadSoundMemEntry_Skip15
	ldw	hl, 0xff98
	jrl	SingleLoad_LoadSoundMemEntry_Epilogue5
SingleLoad_LoadSoundMemEntry_Skip15:
	ld	a, l
	ldfr_berp a, 248
	extz	iz
	ld	wa, hl
	call	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+30)
	ld	bc, iz
	call	FileIO_FormatFileIndex
	lda	xbc, (xsp+30)
	lda	xwa, (xsp+16)
	ld	de, 4:i3
	call	FileIO_ReadHeader
	lda	xwa, (xsp+16)
	ld	xbc, FileIO_ByteBlock_DemoProc1_Str_rb_4
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, SingleLoad_LoadSoundMemEntry_Skip16
	call	FileIO_ReturnError
	jrl	SingleLoad_LoadSoundMemEntry_Epilogue5
SingleLoad_LoadSoundMemEntry_Skip16:
	ld	wa, 4:i3
	calr	FileIO_CheckRegionSignature
	cp	hl, 0:i3
	jr	nz, SingleLoad_LoadSoundMemEntry_Skip17
	call	FileIO_CloseHandle
	ldw	hl, 65434
	jrl	SingleLoad_LoadSoundMemEntry_Epilogue5
SingleLoad_LoadSoundMemEntry_Skip17:
	ld	wa, (xsp+42)
	ld	iz, (xsp+40)
	cp	wa, 40
	jr	nc, SingleLoad_LoadSoundMemEntry_Skip18
	ldw	(xsp+10), 470
	extz	xwa
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	ld	(xsp+2), xhl
	ld	xwa, 16
	add	(xsp+2), xwa
	ld	wa, iz
	extz	xwa
	ld	xbc, 470
	call	Math_MultiplyAccumulate
	ld	(xsp+6), xhl
	ld	xwa, 16
	add	(xsp+6), xwa
	ld	wa, iz
	extz	xwa
	div	wa, 20
	ld	(xsp+12), a
	ld	wa, iz
	extz	xwa
	div	wa, 20
	ld	wa, qwa
	ld	(xsp+14), a
	jr	SingleLoad_LoadSoundMemEntry_Join5
SingleLoad_LoadSoundMemEntry_Skip18:
	sub	wa, 40
	sub	iz, 40
	ldw	(xsp+10), 80
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 4
	ld	(xsp+2), xbc
	ld	xwa, 0x4aa7
	add	(xsp+2), xwa
	ld	wa, iz
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 4
	ld	(xsp+6), xbc
	ld	xwa, 0x4aa7
	add	(xsp+6), xwa
	ld	(xsp+12), 64
	ldto_berp a, 248
	ld	(xsp+14), a
SingleLoad_LoadSoundMemEntry_Join5:
	ld	xwa, (xsp+2)
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	ld	iz, hl
	cp	iz, 0:i3
	jr	lt, SingleLoad_LoadSoundMemEntry_Skip19
	ld	a, (xsp+12)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	call	PreTmLoadEntry
	lda	xwa, (0x1e0000:24)
	add	xwa, (xsp+0x6)
	ld	bc, (xsp+10)
	extz	xbc
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	ld	a, (xsp+12)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	ld	de, iz
	call	PostTmLoadEntry
SingleLoad_LoadSoundMemEntry_Skip19:
	call	FileIO_CloseHandle
	ld	hl, iz
SingleLoad_LoadSoundMemEntry_Epilogue5:
	popw	iz
	lda	xsp, (xsp+42)
	ret
SingleLoad_LoadSoundMemBank:
	lda	xsp, (xsp-36)
	push	xiz
	ld	(xsp+36), bc
	ld	(xsp+38), wa
	call	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	ge, SingleLoad_LoadSoundMemBank_Skip20
	ldw	hl, 0xff98
	jrl	SingleLoad_LoadSoundMemBank_Epilogue6
SingleLoad_LoadSoundMemBank_Skip20:
	ld	a, l
	ldfr_berp a, 248
	extz	iz
	ld	wa, hl
	call	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+26)
	ld	bc, iz
	call	FileIO_FormatFileIndex
	lda	xbc, (xsp+26)
	lda	xwa, (xsp+12)
	ld	de, 4:i3
	call	FileIO_ReadHeader
	lda	xwa, (xsp+12)
	ld	xbc, FileIO_ByteBlock_DemoProc1_Str_rb_5
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, SingleLoad_LoadSoundMemBank_Skip21
	call	FileIO_ReturnError
	jrl	SingleLoad_LoadSoundMemBank_Epilogue6
SingleLoad_LoadSoundMemBank_Skip21:
	ld	wa, 4:i3
	calr	FileIO_CheckRegionSignature
	cp	hl, 0:i3
	jr	nz, SingleLoad_LoadSoundMemBank_Skip22
	call	FileIO_CloseHandle
	ldw	hl, 0xff9a
	jrl	SingleLoad_LoadSoundMemBank_Epilogue6
SingleLoad_LoadSoundMemBank_Skip22:
	cpw	(xsp+38), 2
	jr	nc, SingleLoad_LoadSoundMemBank_Skip23
	ldw (xsp+8), 9400
	ld wa, (xsp+38)
	extz	xwa
	ld	xbc, 9400
	call	Math_MultiplyAccumulate
	ld	xiz, xhl
	add	xiz, 16
	ld	wa, (xsp+36)
	extz	xwa
	ld	xbc, 9400
	call	Math_MultiplyAccumulate
	ld	(xsp+4), xhl
	ld	xwa, 16
	add	(xsp+4), xwa
	ld	wa, (xsp+36)
	ld	(xsp+10), a
	jr	SingleLoad_LoadSoundMemBank_Join6
SingleLoad_LoadSoundMemBank_Skip23:
	ldw	(xsp+8), 0x2927
	ld	xiz, 0x4980
	ld	xwa, 0x4980
	ld	(xsp+4), xwa
	ld	(xsp+10), 64
SingleLoad_LoadSoundMemBank_Join6:
	ld	xwa, xiz
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	ld	iz, hl
	cp	iz, 0:i3
	jr	lt, SingleLoad_LoadSoundMemBank_Skip24
	ld	a, (xsp+10)
	extz	wa
	call	PostTmLoadEntry_Return
	lda	xwa, (0x1e0000:24)
	add	xwa, (xsp+0x4)
	ld	bc, (xsp+8)
	extz	xbc
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	ld	a, (xsp+10)
	extz	wa
	ld	bc, iz
	call	TmFlashWrite_ValidateParams
SingleLoad_LoadSoundMemBank_Skip24:
	call	FileIO_CloseHandle
	ld	hl, iz
SingleLoad_LoadSoundMemBank_Epilogue6:
	pop	xiz
	lda	xsp, (xsp+36)
	ret

ReadSingleFile:
	lda xsp, (xsp - 24)
	push xiz
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	ld iz, hl
	cp iz, 0:i3
	jr ge, ReadSingle_SetupEntry
	ldw hl, 0xff98
	jr ReadSingle_Return

ReadSingle_SetupEntry:
	ld wa, iz
	call GetFileEntryPtr
	ld xde, xhl
	ldto_berp C, 0xf8
	extz bc
	lda xwa, (xsp + 18)
	call FileIO_FormatFileIndex
	ld iz, 0:i3

ReadSingle_RetryLoop:
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	a, (xwa+iz)
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, ReadSingle_LoopNext
	lda xbc, (xsp + 18)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 4)
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	call FileIO_OpenDefault
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, ReadSingle_StoreResult

ReadSingle_LoopNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, ReadSingle_RetryLoop

ReadSingle_StoreResult:
	ldto_werp HL, 0xfa

ReadSingle_Return:
	pop xiz
	lda xsp, (xsp + 24)
	ret

ReadDualFile:
	lda xsp, (xsp - 52)
	push xiz
	ld (xsp + 52), xwa
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	ld iz, hl
	cp iz, 0:i3
	jr ge, ReadDual_SetupEntries
	ldw hl, 0xff98
	jr ReadDual_Return

ReadDual_SetupEntries:
	ld wa, iz
	call GetFileEntryPtr
	ld xde, xhl
	ldto_berp C, 0xf8
	extz bc
	lda xwa, (xsp + 32)
	call FileIO_FormatFileIndex
	ldto_berp C, 0xf8
	extz bc
	lda xwa, (xsp + 42)
	ld xde, (xsp + 52)
	call FileIO_FormatFileIndex
	ld iz, 0:i3

ReadDual_RetryLoop:
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	a, (xwa+iz)
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, ReadDual_LoopNext
	lda xbc, (xsp + 32)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 4)
	call FileIO_ReadHeader
	lda xbc, (xsp + 42)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 18)
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 18)
	call FileIO_CopyAndOpen
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, ReadDual_StoreResult

ReadDual_LoopNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, ReadDual_RetryLoop

ReadDual_StoreResult:
	ldto_werp HL, 0xfa

ReadDual_Return:
	pop xiz
	lda xsp, (xsp + 52)
	ret

ReadDualFileEx:
	lda xsp, (xsp - 60)
	push xiz
	ld (xsp + 62), wa
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jr ge, ReadDualEx_SetupPages
	ldw hl, 0xff98
	jrl ReadDualEx_Return

ReadDualEx_SetupPages:
	ld wa, (xsp + 4)
	call GetFileEntryPtr
	ld (xsp + 6), xhl
	ld wa, (xsp + 62)
	call GetFileEntryPtr
	ld (xsp + 10), xhl
	ld wa, (xsp + 62)
	ld c, a
	extz bc
	lda xwa, (xsp + 52)
	ld xde, (xsp + 10)
	call FileIO_FormatFileIndex
	lda xwa, (xsp + 42)
	ldw bc, 0x14
	ld xde, (xsp + 10)
	call FileIO_FormatFileIndex
	ld iz, 0:i3

ReadDualEx_FirstLoop:
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	c, (xwa+iz)
	ld wa, (xsp + 62)
	call FileIO_CheckRecordByFile
	cp l, 0:i3
	jr z, ReadDualEx_FirstLoopNext
	lda xbc, (xsp + 52)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 28)
	call FileIO_ReadHeader
	lda xbc, (xsp + 42)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 14)
	call FileIO_ReadHeader
	lda xwa, (xsp + 28)
	lda xbc, (xsp + 14)
	call FileIO_CopyAndOpen
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jrl lt, ReadDualEx_StoreResult

ReadDualEx_FirstLoopNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, ReadDualEx_FirstLoop
	ld wa, (xsp + 4)
	ld c, a
	extz bc
	lda xwa, (xsp + 52)
	ld xde, (xsp + 6)
	call FileIO_FormatFileIndex
	ld wa, (xsp + 62)
	ld c, a
	extz bc
	lda xwa, (xsp + 42)
	ld xde, (xsp + 6)
	call FileIO_FormatFileIndex
	ld iz, 0:i3

ReadDualEx_SecondLoop:
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	a, (xwa+iz)
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, ReadDualEx_SecondLoopNext
	lda xbc, (xsp + 52)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 28)
	call FileIO_ReadHeader
	lda xbc, (xsp + 42)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 14)
	call FileIO_ReadHeader
	lda xwa, (xsp + 28)
	lda xbc, (xsp + 14)
	call FileIO_CopyAndOpen
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, ReadDualEx_StoreResult

ReadDualEx_SecondLoopNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, ReadDualEx_SecondLoop
	lda xwa, (xsp + 52)
	ldw bc, 0x14
	ld xde, (xsp + 10)
	call FileIO_FormatFileIndex
	ld wa, (xsp + 4)
	ld c, a
	extz bc
	lda xwa, (xsp + 42)
	ld xde, (xsp + 10)
	call FileIO_FormatFileIndex
	ld iz, 0:i3

ReadDualEx_ThirdLoop:
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	c, (xwa+iz)
	ld wa, (xsp + 62)
	call FileIO_CheckRecordByFile
	cp l, 0:i3
	jr z, ReadDualEx_ThirdLoopNext
	lda xbc, (xsp + 52)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 28)
	call FileIO_ReadHeader
	lda xbc, (xsp + 42)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 14)
	call FileIO_ReadHeader
	lda xwa, (xsp + 28)
	lda xbc, (xsp + 14)
	call FileIO_CopyAndOpen
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, ReadDualEx_StoreResult

ReadDualEx_ThirdLoopNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, ReadDualEx_ThirdLoop

ReadDualEx_StoreResult:
	ldto_werp HL, 0xfa

ReadDualEx_Return:
	pop xiz
	lda xsp, (xsp + 60)
	ret

WriteFileWithVerify:
	lda xsp, (xsp - 58)
	push xiz
	ld (xsp + 60), wa
	ldw (xsp + 6), 0x0
	call GetCurrentFileIndex
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jr ge, WriteVerify_InitCounters
	ldw hl, 0xff98
	jrl WriteVerify_Return

WriteVerify_InitCounters:
	ld xwa, 0:i3
	ld (xsp + 8), xwa
	ld iz, 0:i3

WriteVerify_WriteLoop:
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	a, (xwa+iz)
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, WriteVerify_WriteLoopNext
	ld wa, (xsp + 4)
	lda xbc, (FileIO_TypeProbeOrder:24)
	ld	c, (xbc+iz)
	call UpdateFileEntry
	add (xsp + 8), xhl

WriteVerify_WriteLoopNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, WriteVerify_WriteLoop
	call FileIO_GetDiskFreeSpace
	cp xhl, (xsp + 8)
	jr ge, WriteVerify_SetupReadback
	ldw hl, 0xff9b
	jrl WriteVerify_Return

WriteVerify_SetupReadback:
	ld wa, (xsp + 60)
	call GetFileEntryPtr
	ld xde, xhl
	ld wa, (xsp + 60)
	ld c, a
	extz bc
	lda xwa, (xsp + 50)
	call FileIO_FormatFileIndex
	ld iz, 0:i3

WriteVerify_ReadbackLoop:
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	c, (xwa+iz)
	ld wa, (xsp + 60)
	call FileIO_CheckRecordByFile
	cp l, 0:i3
	jr z, WriteVerify_ReadbackNext
	lda xbc, (xsp + 50)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 26)
	call FileIO_ReadHeader
	lda xwa, (xsp + 26)
	call FileIO_OpenDefault
	ld (xsp + 6), hl
	cpw (xsp + 6), 0x0
	jrl lt, WriteVerify_GetStatus

WriteVerify_ReadbackNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, WriteVerify_ReadbackLoop
	ld wa, (xsp + 4)
	call GetFileEntryPtr
	ld xiz, xhl
	ld wa, (xsp + 4)
	ld c, a
	extz bc
	lda xwa, (xsp + 50)
	ld xde, xiz
	call FileIO_FormatFileIndex
	ld wa, (xsp + 60)
	ld c, a
	extz bc
	lda xwa, (xsp + 40)
	ld xde, xiz
	call FileIO_FormatFileIndex
	ld iz, 0:i3

WriteVerify_CrossVerifyLoop:
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	a, (xwa+iz)
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, WriteVerify_CrossVerifyNext
	lda xbc, (xsp + 50)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 26)
	call FileIO_ReadHeader
	lda xbc, (xsp + 40)
	lda xwa, (FileIO_TypeProbeOrder:24)
	ld	e, (xwa+iz)
	lda xwa, (xsp + 12)
	call FileIO_ReadHeader
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 26)
	call FileIO_CompareFiles
	ld (xsp + 6), hl
	cpw (xsp + 6), 0x0
	jr lt, WriteVerify_GetStatus

WriteVerify_CrossVerifyNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, WriteVerify_CrossVerifyLoop

WriteVerify_GetStatus:
	ld hl, (xsp + 6)

WriteVerify_Return:
	pop xiz
	lda xsp, (xsp + 58)
	ret

GetFirstRecordAndOpen:
	call GetFirstPageBase
	cp hl, 0:i3
	jr ge, GetFirstRecord_GotPage
	ldw hl, 0xff98
	ret

GetFirstRecord_GotPage:
	ld wa, hl
	call GetRecordPtrForFile
	ld xwa, xhl
	jp FileIO_OpenDefault

SearchAndOpen:
	lda xsp, (xsp-270)
	pushw iz
	ld	(xsp+268), xwa
	call GetFirstPageBase
	ld iz, hl
	cp iz, 0:i3
	jr ge, SearchOpen_DoSearch
	ldw hl, 0xff98
	jr SearchOpen_Return

SearchOpen_DoSearch:
	lda xbc, (xsp + 2)
	ld XWA, (xsp + 0x010c)
	call _findfirst
	ld xwa, xhl
	cp xwa, 0x0
	jr ge, SearchOpen_AlreadyExists
	ld wa, iz
	call GetRecordPtrForFile
	ld xwa, xhl
	ld XBC, (xsp + 0x010c)
	call FileIO_CopyAndOpen
	jr SearchOpen_Return

SearchOpen_AlreadyExists:
	call _findclose
	ldw hl, 0xfff6

SearchOpen_Return:
	popw iz
	lda xsp, (xsp+270)
	ret

LoadFromSecondaryPage:
	pushw iz
	call FileIO_GetCurrentWallpaperIndex
	cp hl, 0:i3
	jr ge, LoadSecondary_OpenFile
	ldw hl, 0xff98
	jr LoadSecondary_Return

LoadSecondary_OpenFile:
	ld wa, hl
	call FileIO_GetWallpaperEntry
	ld xwa, xhl
	ld xbc, LoadSecondary_OpenFile_Str_rb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr ge, LoadSecondary_Process
	call FileIO_ReturnError
	jr LoadSecondary_Return

LoadSecondary_Process:
	call Gfx_LoadSplashBMP
	ld iz, hl
	call FileIO_CloseHandle
	ld hl, iz

LoadSecondary_Return:
	popw iz
	ret

FileIO_ReturnError:
	ld hl, (0x7f48:16)
	ret

FileIO_OpenWithMode:
	lda xsp, (xsp - 128)
	push xiz
	ld xiz, xbc
	ld xde, xwa
	ld xiy, FileIO_OpenWithMode_PathInit
	lda xix, (xsp + 4)
	ldw bc, 0x40
	ldirw
	lda xwa, (xsp + 4)
	ld xbc, xde
	call FileIO_BuildFilePath
	push xiz
	lda xwa, (xsp + 8)
	push xwa
	call FileOpen
	inc 8, xsp
	ld (0x7f44:16), xhl
	or xhl, xhl
	jr nz, FileIO_OpenMode_Success
	cp (xiz), 0x72
	jr nz, FileIO_OpenMode_CheckWrite
	ldw (0x7f48:16), 0xfffe
	ldw hl, 0xfffe
	jr FileIO_OpenMode_Return

FileIO_OpenMode_CheckWrite:
	cp (xiz), 0x77
	jr nz, FileIO_OpenMode_UnknownMode
	cpw (0x1e53c:24), 31
	jr nz, FileIO_OpenMode_WriteMaxFiles
	ldw (0x7f48:16), 0xfff5
	ldw hl, 0xfff5
	jr FileIO_OpenMode_Return

FileIO_OpenMode_WriteMaxFiles:
	ldw (0x7f48:16), 0xfffd
	ldw hl, 0xfffd
	jr FileIO_OpenMode_Return

FileIO_OpenMode_UnknownMode:
	ldw (0x7f48:16), 0xffff
	ldw hl, 0xffff
	jr FileIO_OpenMode_Return

FileIO_OpenMode_Success:
	ldw (0x7f48:16), 0
	ld hl, (0x7f48:16)

FileIO_OpenMode_Return:
	pop xiz
	lda xsp, (xsp+128:16)
	ret

FileIO_CloseHandle:
	ld xwa, (0x7f44:16)
	or xwa, xwa
	jr z, FileIO_CloseHandle_Done
	push xwa
	call FileClose
	inc 4, xsp
	ld xwa, 0:i3
	ld (0x7f44:16), xwa

FileIO_CloseHandle_Done:
	ld hl, 0:i3
	ret

FileIO_OpenDefault:
	lda xsp, (xsp - 16)
	ld xde, xwa
	ld xiy, FileIO_OpenDefault_PathInit
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xde
	call FileIO_BuildFilePath
	lda xwa, (xsp)
	push xwa
	call FileOpenDefault
	inc 4, xsp
	cp hl, 0:i3
	jr nz, FileIO_OpenDefault_CheckMaxFiles
	ld hl, 0:i3
	jr FileIO_OpenDefault_Return

FileIO_OpenDefault_CheckMaxFiles:
	cp hl, 0x1f
	jr nz, FileIO_OpenDefault_OtherError
	ldw hl, 0xfff5
	jr FileIO_OpenDefault_Return

FileIO_OpenDefault_OtherError:
	ldw hl, 0xfffd

FileIO_OpenDefault_Return:
	lda xsp, (xsp + 16)
	ret

FileIO_CopyAndOpen:
	lda xsp, (xsp - 32)
	push xiz
	ld xiz, xbc
	ld xde, xwa
	ld xiy, FileIO_CopyAndOpen_Path1Init
	lda xix, (xsp + 20)
	ldw bc, 0x8
	ldirw
	ld xiy, FileIO_CopyAndOpen_PathInitB
	lda xix, (xsp + 4)
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp + 20)
	ld xbc, xde
	call FileIO_BuildFilePath
	lda xwa, (xsp + 4)
	ld xbc, xiz
	call FileIO_BuildFilePath
	lda xwa, (xsp + 4)
	push xwa
	lda xwa, (xsp + 24)
	push xwa
	call SeqStep_FileSeekCleanup
	inc 8, xsp
	cp hl, 0:i3
	jr nz, FileIO_CopyOpen_CheckMaxFiles
	ld hl, 0:i3
	jr FileIO_CopyOpen_Return

FileIO_CopyOpen_CheckMaxFiles:
	cpw (0x1e53c:24), 31
	jr nz, FileIO_CopyOpen_OtherError
	ldw hl, 0xfff5
	jr FileIO_CopyOpen_Return

FileIO_CopyOpen_OtherError:
	ldw hl, 0xfffd

FileIO_CopyOpen_Return:
	pop xiz
	lda xsp, (xsp + 32)
	ret

FileIO_ReadByte:
	ld xwa, (0x7f44:16)
	or xwa, xwa
	jr z, FileIO_ReadByte_NoHandle
	push xwa
	call SeqStep_FileReadReturn
	inc 4, xsp
	cp hl, 0:i3
	jr ge, FileIO_ReadByte_CheckEOF
	ldw hl, 0xfffe
	jr FileIO_ReadByte_Return

FileIO_ReadByte_NoHandle:
	ldw hl, 0xff9c
	jr FileIO_ReadByte_Return

FileIO_ReadByte_CheckEOF:
	cp hl, 0:i3
	ret ge

FileIO_ReadByte_Return:
	ld wa, (0x7f48:16)
	cp wa, 0:i3
	jr lt, FileIO_ReadByte_Extended
	ld wa, hl

FileIO_ReadByte_Extended:
	ld (0x7f48:16), wa
	ret

FileIO_ReadByte_BufferHit:
	pushw iz
	ld iz, 0:i3
	ld xbc, (0x7f44:16)
	or xbc, xbc
	jr z, FileIO_SeekAndRead_Error
	push xbc
	extz wa
	pushw wa
	call SeqStep_FileWriteSetup
	inc 6, xsp
	cp hl, 0:i3
	jr ge, FileIO_SeekAndRead_Return
	ld xwa, (0x7f44:16)
	ld wa, (xwa + 6)
	res 15, wa
	cp wa, 0x1f
	jr nz, FileIO_SeekAndRead_NoHandle
	ldw iz, 0xfff5
	jr FileIO_SeekAndRead_Return

FileIO_SeekAndRead_NoHandle:
	ldw iz, 0xfffd
	jr FileIO_SeekAndRead_Return

FileIO_SeekAndRead_Error:
	ldw iz, 0xff9c

FileIO_SeekAndRead_Return:
	ld wa, (0x7f48:16)
	cp wa, 0:i3
	jr lt, FileIO_SeekToOffset
	ld wa, iz

FileIO_SeekToOffset:
	ld (0x7f48:16), wa
	ld hl, iz
	popw iz
	ret

FileIO_ReadBlock:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 18), xwa
	ldw (xsp + 4), 0x0
	ld xwa, 0:i3
	ld (xsp + 6), xwa
	ld xwa, (0x7f44:16)
	or xwa, xwa
	jr z, FileIO_WriteBlock_LoopNext
	ld (xsp + 14), xbc
	cp xbc, 0x0
	jr le, FileIO_WriteBlock_Error

FileIO_ReadBlock_Loop:
	ld xiz, 0x7fff
	ld xwa, (xsp + 14)
	cp xwa, 0x7fff
	jr ge, FileIO_ReadBlock_Done
	ld xiz, (xsp + 14)

FileIO_ReadBlock_Done:
	ld (xsp + 10), xiz
	ld xwa, (0x7f44:16)
	push xwa
	ld wa, iz
	pushw wa
	pushw 0x1
	ld xwa, (xsp + 26)
	push xwa
	call FileRead
	lda xsp, (xsp + 12)
	exts xhl
	cp xhl, xiz
	jr nz, FileIO_WriteBlock_NoHandle
	add (xsp + 6), xhl
	ld xwa, (xsp + 10)
	add (xsp + 18), xwa
	sub (xsp + 14), xwa
	ld xwa, (xsp + 14)
	cp xwa, 0x0
	jr gt, FileIO_ReadBlock_Loop
	jr FileIO_WriteBlock_Error

FileIO_WriteBlock_NoHandle:
	ld xwa, (0x7f44:16)
	ld wa, (xwa + 6)
	bit 15, wa
	jr z, FileIO_WriteBlock_CheckResult
	add (xsp + 6), xhl
	jr FileIO_WriteBlock_Error

FileIO_WriteBlock_CheckResult:
	ldw (xsp + 4), 0xfffe
	jr FileIO_WriteBlock_Return

FileIO_WriteBlock_LoopNext:
	ldw (xsp + 4), 0xff9c
	jr FileIO_WriteBlock_Return

FileIO_WriteBlock_Error:
	cpw (xsp + 4), 0x0
	jr ge, FileIO_WriteByte

FileIO_WriteBlock_Return:
	ld wa, (0x7f48:16)
	cp wa, 0:i3
	jr lt, FileIO_WriteWord
	ld wa, (xsp + 4)

FileIO_WriteWord:
	ld (0x7f48:16), wa
	ld wa, (xsp + 4)
	exts xwa
	ld (xsp + 6), xwa

FileIO_WriteByte:
	ld xhl, (xsp + 6)
	pop xiz
	lda xsp, (xsp + 18)
	ret

FileIO_WriteByte_Impl:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 14), xbc
	ld (xsp + 18), xwa
	ldw (xsp + 4), 0x0
	ld xwa, (0x7f44:16)
	or xwa, xwa
	jr z, FileIO_FlushAndClose
	ld xwa, (xsp + 14)
	ld (xsp + 10), xwa
	cp xwa, 0x0
	jr le, FileIO_FlushClose_Return

FileIO_WriteByte_NoHandle:
	ld xiz, 0x7fff
	ld xwa, (xsp + 10)
	cp xwa, 0x7fff
	jr ge, FileIO_WriteByte_Return
	ld xiz, (xsp + 10)

FileIO_WriteByte_Return:
	ld (xsp + 6), xiz
	ld xwa, (0x7f44:16)
	push xwa
	ld wa, iz
	pushw wa
	pushw 0x1
	ld xwa, (xsp + 26)
	push xwa
	call FileWrite
	lda xsp, (xsp + 12)
	exts xhl
	cp xhl, xiz
	jr ge, FileIO_FlushBuffer_Return
	ld xwa, (0x7f44:16)
	ld wa, (xwa + 6)
	res 15, wa
	cp wa, 0x1f
	jr nz, FileIO_FlushBuffer
	ldw (xsp + 4), 0xfff5
	jr FileIO_GetPosition

FileIO_FlushBuffer:
	ldw (xsp + 4), 0xfffd
	jr FileIO_GetPosition

FileIO_FlushBuffer_Return:
	add (xsp + 18), xiz
	ld xwa, (xsp + 6)
	sub (xsp + 10), xwa
	ld xwa, (xsp + 10)
	cp xwa, 0x0
	jr gt, FileIO_WriteByte_NoHandle
	jr FileIO_FlushClose_Return

FileIO_FlushAndClose:
	ldw (xsp + 4), 0xff9c
	jr FileIO_GetPosition

FileIO_FlushClose_Return:
	cpw (xsp + 4), 0x0
	jr ge, FileIO_CheckHandle

FileIO_GetPosition:
	ld wa, (0x7f48:16)
	cp wa, 0:i3
	jr lt, FileIO_GetPosition_Return
	ld wa, (xsp + 4)

FileIO_GetPosition_Return:
	ld (0x7f48:16), wa
	ld wa, (xsp + 4)
	exts xwa
	ld (xsp + 14), xwa

FileIO_CheckHandle:
	ld xhl, (xsp + 14)
	pop xiz
	lda xsp, (xsp + 18)
	ret

FileIO_SeekAndReadBlock:
	ld xde, (0x7f44:16)
	or xde, xde
	jr z, FileIO_SeekRead_NoHandle
	pushw bc
	push xwa
	push xde
	call SeqStep_FileSeekSetup
	add xsp, 0xa
	cp hl, 0:i3
	jr z, FileIO_SeekRead_Return
	ldw hl, 0xfffb
	jr FileIO_SeekRead_Return

FileIO_SeekRead_NoHandle:
	ldw hl, 0xff9c

FileIO_SeekRead_Return:
	ld wa, (0x7f48:16)
	cp wa, 0:i3
	jr lt, FileIO_SeekRead_Extended
	ld wa, hl

FileIO_SeekRead_Extended:
	ld (0x7f48:16), wa
	ret

FileIO_SeekRead_ExtReturn:
	pushw iz
	ld iz, 0:i3
	ld xwa, (0x7f44:16)
	or xwa, xwa
	jr z, FileIO_SeekWrite_NoHandle
	push xwa
	call SeqStep_FileIoHelper
	inc 4, xsp
	jr FileIO_SeekWrite_Return

FileIO_SeekWrite_NoHandle:
	ldw iz, 0xff9c

FileIO_SeekWrite_Return:
	ld wa, (0x7f48:16)
	cp wa, 0:i3
	jr lt, FileIO_SeekWriteBlock
	ld wa, iz

FileIO_SeekWriteBlock:
	ld (0x7f48:16), wa
	ld hl, iz
	popw iz
	ret

FileIO_SeekWriteBlock_Impl:
	ld xwa, (0x7f44:16)
	or xwa, xwa
	jr z, FileIO_SeekWriteBlock_NoHandle
	push xwa
	call SeqStep_FileSeekStore
	inc 4, xsp
	cp xhl, 0x0
	jr ge, FileIO_SeekWriteBlock_Error
	ld xhl, 0xfffffffb
	jr FileIO_SeekWriteBlock_Return

FileIO_SeekWriteBlock_NoHandle:
	ld xhl, 0xffffff9c
	jr FileIO_SeekWriteBlock_Return

FileIO_SeekWriteBlock_Error:
	cp xhl, 0x0
	ret ge

FileIO_SeekWriteBlock_Return:
	ld wa, (0x7f48:16)
	cp wa, 0:i3
	jr lt, FileIO_SeekWriteBlock_Done
	ld wa, hl

FileIO_SeekWriteBlock_Done:
	ld (0x7f48:16), wa
	ret

FileIO_CompareFiles:
	lda xsp, (xsp - 50)
	pushw iz
	ld (xsp + 48), xbc
	ld xde, xwa
	ldw (xsp + 10), 0x0
	ld xiy, FileIO_CompareFiles_Path2Init
	lda xix, (xsp + 32)
	ldw bc, 0x8
	ldirw
	ld xiy, FileIO_CompareFiles_PathInitB
	lda xix, (xsp + 16)
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp + 16)
	ld xbc, xde
	call FileIO_BuildFilePath
	pushw FileIO_CompareFiles_Str_wb@hi16
	pushw FileIO_CompareFiles_Str_wb@lo16
	lda xwa, (xsp + 20)
	push xwa
	call FileOpen
	inc 8, xsp
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr nz, FileIO_Compare_Return
	cpw (0x1e53c:24), 31
	jr nz, FileIO_Compare_Mismatch
	ldw hl, 0xfff5
	jrl FileIO_ParseHeader_Error

FileIO_Compare_Mismatch:
	ldw hl, 0xfffd
	jrl FileIO_ParseHeader_Error

FileIO_Compare_Return:
	lda xwa, (xsp + 32)
	ld xbc, (xsp + 48)
	call FileIO_BuildFilePath
	pushw FileIO_Compare_Mismatch_Str_rb@hi16
	pushw FileIO_Compare_Mismatch_Str_rb@lo16
	lda xwa, (xsp + 36)
	push xwa
	call FileOpen
	inc 8, xsp
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, FileIO_ParseHeader_CheckType
	ld xwa, (xsp + 6)
	push xwa
	call FileClose
	inc 4, xsp
	ldw hl, 0xfffe
	jr FileIO_ParseHeader_Error

FileIO_ParseHeader_CheckType:
	lda xwa, (0x069800:24)
	ld (xsp + 12), xwa

FileIO_ParseHeader_ReadFields:
	ld xwa, (xsp + 2)
	push xwa
	pushw 0x1000
	pushw 0x1
	ld xwa, (xsp + 20)
	push xwa
	call FileRead
	lda xsp, (xsp + 12)
	ld iz, hl
	cp iz, 0:i3
	jr gt, FileIO_ParseHeader_Return
	cpw (xsp + 10), 0x0
	jr lt, FileIO_ParseHeader_Done
	ld xwa, (xsp + 2)
	ld wa, (xwa + 6)
	bit 15, wa
	jr nz, FileIO_ParseHeader_Done
	ldw (xsp + 10), 0xfffe

FileIO_ParseHeader_Done:
	ld xwa, (xsp + 2)
	push xwa
	call FileClose
	ld xwa, (xsp + 10)
	push xwa
	call FileClose
	inc 8, xsp
	ld hl, (xsp + 10)

FileIO_ParseHeader_Error:
	popw iz
	lda xsp, (xsp + 50)
	ret

FileIO_ParseHeader_Return:
	ld xwa, (xsp + 6)
	push xwa
	pushw iz
	pushw 0x1
	ld xwa, (xsp + 20)
	push xwa
	call FileWrite
	lda xsp, (xsp + 12)
	cp hl, iz
	jr z, FileIO_ParseHeader_ReadFields
	ld xwa, (0x7f44:16)
	ld wa, (xwa + 6)
	res 15, wa
	cp wa, 0x1f
	jr nz, FileIO_ValidateRecord
	ldw (xsp + 10), 0xfff5
	jr FileIO_ParseHeader_Done

FileIO_ValidateRecord:
	ldw (xsp + 10), 0xfffd
	jr FileIO_ParseHeader_Done

FileIO_ValidateRecord_CheckSize:
	extz wa
	call format_FD
	cp hl, 0:i3
	jr z, FileIO_ValidateRecord_Fail
	ld hl, 0:i3
	ret

FileIO_ValidateRecord_Fail:
	cpw (0x1e53c:24), 31
	jr nz, FileIO_ValidateRecord_Ok
	ldw hl, 0xfff5
	ret

FileIO_ValidateRecord_Ok:
	ldw hl, 0xfffa
	ret

FileIO_ValidateRecord_Return:
	ldw (0x0272cc:24), 0x003f
	ldw (0x0272ce:24), 0x003f
	ld (0x0272d0:24), 0x00
	ld xwa, 0x25eaa
	ld xbc, FileIO_ValidateRecord_Ok_Str_Under_Under_Under_Under
	calr FileIO_CopyString
	ld xwa, 0x271f2
	ld	xbc, FileIO_ValidateRecord_Ok_Str_MID	; pointer to "________.MID"
	jr FileIO_CopyString

FileIO_CopyString:
	ld xde, xbc
	cp (xde), 0x0
	jr z, FileIO_CopyString_Done

FileIO_CopyString_Loop:
	ld C, (xde+)
	ld (xwa+), c
	cp (xde), 0x0
	jr nz, FileIO_CopyString_Loop

FileIO_CopyString_Done:
	ld (xwa), 0x0
	ret

FileIO_CopyString_WriteNull:
	ld xhl, xbc
	jr FileIO_CopyString_CheckEnd

FileIO_CopyString_Advance:
	ld C, (xhl+)
	ld (xwa+), c
	dec 1, de

FileIO_CopyString_CheckEnd:
	cp de, 0:i3
	jr z, FileIO_CopyString_StoreAndCont
	cp (xhl), 0x0
	jr nz, FileIO_CopyString_Advance

FileIO_CopyString_StoreAndCont:
	cp de, 0:i3
	ret z

FileIO_CopyString_Return:
	ld (xwa+), 0x00
	djnz16 de, FileIO_CopyString_Return
	ret

FileIO_BuildFilePath:
	ld xde, xbc
	cp (xwa), 0x0
	jr z, FileIO_BuildPath_NullDir

FileIO_BuildPath_CopyDir:
	inc 1, xwa
	cp (xwa), 0x0
	jr nz, FileIO_BuildPath_CopyDir

FileIO_BuildPath_NullDir:
	cp (xde), 0x0
	jr z, FileIO_BuildPath_Return

FileIO_BuildPath_AddSep:
	ld C, (xde+)
	ld (xwa+), c
	cp (xde), 0x0
	jr nz, FileIO_BuildPath_AddSep

FileIO_BuildPath_Return:
	ld (xwa), 0x0
	ret

FileIO_SearchFile:
	ld xhl, xwa
	jr FileIO_Search_CheckNext

FileIO_Search_CompareChar:
	cp e, 0:i3
	jr nz, FileIO_Search_Match
	ld hl, 0:i3
	ret

FileIO_Search_Match:
	inc 1, xwa
	inc 1, xhl
	inc 1, xbc

FileIO_Search_CheckNext:
	ld e, (xhl)
	cp (xbc), e
	jr z, FileIO_Search_CompareChar
	ld l, (xwa)
	sub l, (xbc)
	exts hl
	ret

FileIO_Search_SkipEntry:
	ld xhl, xwa
	jr FileIO_Search_NotFound

FileIO_Search_EndOfList:
	cp (xhl), 0x0
	jr nz, FileIO_Search_Found
	ld hl, 0:i3
	ret

FileIO_Search_Found:
	inc 1, xhl
	inc 1, xbc
	dec 1, de

FileIO_Search_NotFound:
	cp de, 0:i3
	jr z, FileIO_Search_Error
	ld a, (xbc)
	cp a, (xhl)
	jr z, FileIO_Search_EndOfList

FileIO_Search_Error:
	ld a, 0x0:opc
	cp de, 0:i3
	jr z, FileIO_Search_Return
	ld a, (xhl)
	sub a, (xbc)

FileIO_Search_Return:
	ld l, a
	exts hl
	ret

FileIO_FormatFileIndex:
	inc 1, c
	cp c, 0xa
	jr nc, FileIO_FormatIndex_TwoDigit
	ld (xwa+), 0x30
	jr FileIO_FormatIndex_AddChar

FileIO_FormatIndex_TwoDigit:
	cp c, 0x14
	jr nc, FileIO_FormatIndex_AddOnes
	ld (xwa+), 0x31
	sub c, 0xa
	jr FileIO_FormatIndex_AddChar

FileIO_FormatIndex_AddOnes:
	ld (xwa+), 0x32
	sub c, 0x14

FileIO_FormatIndex_AddChar:
	add c, 0x30
	ld (xwa+), c
	ld xbc, xde
	jrl FileIO_CopyString

FileIO_ReadHeader:
	dec 2, xsp
	push xiz
	ld (xsp + 4), e
	ld xiz, xwa
	ld xwa, xiz
	calr FileIO_CopyString
	ld xwa, xiz
	ld xbc, FileIO_ReadHeader_Str_Dot
	calr FileIO_BuildFilePath
	ld a, (xsp + 4)
	extz wa
	sla wa, 2
	lda xbc, (FileIO_TypeExtensions:24)
	ld	xbc, (xbc+wa)
	ld xwa, xiz
	calr FileIO_BuildFilePath
	pop xiz
	inc 2, xsp
	ret

FileIO_ReadHeader_ParseLoop:
	pushw iz
	cp de, 0x64
	jr c, FileIO_ReadHeader_Done
	lda xix, (xwa+:1)
	ld hl, de
	extz xhl
	div hl, 0x64
	add l, 0x30
	ld (xix), l
	sub de, 0x64
	lda xix, (xwa+:1)
	ld hl, de
	extz xhl
	div hl, 0xa
	add l, 0x30
	ld (xix), l
	extz xde
	div de, 0xa
	ldto_werp DE, 0xea
	add e, 0x30
	ld (xwa), e
	jr FileIO_ReadHeader_Field1

FileIO_ReadHeader_Done:
	lda xix, (xwa+:1)
	ld hl, de
	extz xhl
	div hl, 0xa
	add l, 0x30
	ld (xix), l
	lda xhl, (xwa+:1)
	extz xde
	div de, 0xa
	ldto_werp DE, 0xea
	add e, 0x30
	ld (xhl), e
	ld (xwa), 0x3a

FileIO_ReadHeader_Field1:
	inc 1, xwa
	ld (xwa+), 0x20
	ld iy, 0:i3
	ld iz, 0:i3
	jr FileIO_ReadHeader_Return

FileIO_ReadHeader_Field2:
	add xde, xwa
	cp l, 0x7e
	jr nz, FileIO_ReadHeader_Field3
	ld (xde), 0x5f
	jr FileIO_ReadHeader_FieldDone

FileIO_ReadHeader_Field3:
	ld h, l
	cp h, 0x20
	jr nc, FileIO_ReadHeader_Field4
	ld (xde), 0x20
	jr FileIO_ReadHeader_FieldDone

FileIO_ReadHeader_Field4:
	ld (xde), l

FileIO_ReadHeader_FieldDone:
	inc 1, iz
	inc 1, iy

FileIO_ReadHeader_Return:
	ld de, iz
	extz xde
	add xde, xbc
	ld ix, (xsp + 8)
	ld l, (xde)
	ld de, iy
	extz xde
	cp l, 0:i3
	jr z, FileIO_GetRecordType_CheckRange
	cp iy, ix
	jr c, FileIO_ReadHeader_Field2

FileIO_GetRecordType_CheckRange:
	cp iy, ix
	jr nc, FileIO_GetRecordType_Standard

FileIO_GetRecordType_Dispatch:
	ld xbc, xde
	add xbc, xwa
	ld (xbc), 0x20
	inc 1, iy
	inc 1, xde
	cp iy, ix
	jr c, FileIO_GetRecordType_Dispatch

FileIO_GetRecordType_Standard:
	ld bc, iy
	extz xbc
	add xbc, xwa
	ld (xbc), 0x0
	popw iz
	retd 0x4

FileIO_GetRecordType_Extended:
	cp (xwa), 0x0
	ret z

FileIO_GetRecordType_Error:
	cp (xwa), 0x7e
	jr nz, FileIO_GetRecordType_Return
	ld c, 0x5f:opc
	jr FileIO_GetRecordType_ReturnOk

FileIO_GetRecordType_Return:
	cp (xwa), 0x20
	jr nc, FileIO_GetRecordType_Alt
	ld c, 0x20:opc

FileIO_GetRecordType_ReturnOk:
	ld (xwa), c

FileIO_GetRecordType_Alt:
	inc 1, xwa
	cp (xwa), 0x0
	jr nz, FileIO_GetRecordType_Error
	ret

FileIO_GetRecordByType:
	lda xhl, (0x025eaa:24)
	ret

FileIO_GetRecordByType_Lookup:
	ld xbc, xwa
	ld xwa, 0x25eaa
	ld de, 6:i3
	calr FileIO_CopyString_WriteNull
	ld (0x025eb0:24), 0x00
	ret

FileIO_GetRecordPtrAlt:
	lda xhl, (0x0271f2:24)
	ret

FileIO_WriteRecordName:
	ld xbc, xwa
	ld xwa, 0x271f2
	ldw de, 0xc
	calr FileIO_CopyString_WriteNull
	ld (0x0271fe:24), 0x00
	ret

FileIO_WriteRecordName_Loop:
	ld hl, (0x0272cc:24)
	ret

FileIO_WriteRecordName_Done:
	ld bc, (0x025ea8:24)
	cp bc, 0:i3
	jr lt, FileIO_WriteRecordName_Pad
	cp bc, 0x14
	jr ge, FileIO_WriteRecordName_Pad
	cp a, 0xa
	jr c, FileIO_WriteRecordName_Return

FileIO_WriteRecordName_Pad:
	ld l, 0x0:opc
	ret

FileIO_WriteRecordName_Return:
	ld bc, 1:i3
	and a, 0xf
	jr z, FileIO_FormatRecordName
	slla bc

FileIO_FormatRecordName:
	ld wa, (0x0272cc:24)
	and wa, bc
	cp wa, bc
	scc8 z, l
	ret

FileIO_FormatName_Loop:
	cp a, 0xa
	ret nc
	ld bc, 1:i3
	and a, 0xf
	jr z, FileIO_FormatName_NoPrefix
	slla bc

FileIO_FormatName_NoPrefix:
	or (0x272cc:24), bc
	ret

FileIO_FormatName_Copy:
	cp a, 0xa
	ret nc
	ld bc, 1:i3
	and a, 0xf
	jr z, FileIO_FormatName_CopyLoop
	slla bc

FileIO_FormatName_CopyLoop:
	xor bc, 0xffff
	and (0x272cc:24), bc
	ret

FileIO_FormatName_Done:
	ld hl, (0x0272ce:24)
	ret

FileIO_FormatName_Return:
	ld bc, (0x025ea8:24)
	cp bc, 0:i3
	jr lt, FileIO_BuildRecordPath
	cp bc, 0x14
	jr ge, FileIO_BuildRecordPath
	cp a, 0xa
	jr c, FileIO_BuildRecordPath_Loop

FileIO_BuildRecordPath:
	ld l, 0x0:opc
	ret

FileIO_BuildRecordPath_Loop:
	ld bc, 1:i3
	and a, 0xf
	jr z, FileIO_BuildRecordPath_AddExt
	slla bc

FileIO_BuildRecordPath_AddExt:
	ld wa, (0x0272ce:24)
	and wa, bc
	cp wa, bc
	scc8 z, l
	ret

FileIO_BuildRecordPath_Done:
	cp a, 0xa
	ret nc
	ld bc, 1:i3
	and a, 0xf
	jr z, FileIO_BuildRecordPath_Error
	slla bc

FileIO_BuildRecordPath_Error:
	or (0x272ce:24), bc
	ret

FileIO_BuildRecordPath_Return:
	cp a, 0xa
	ret nc
	ld bc, 1:i3
	and a, 0xf
	jr z, FileIO_GetRecordAttr
	slla bc

FileIO_GetRecordAttr:
	xor bc, 0xffff
	and (0x272ce:24), bc
	ret

FileIO_GetRecordAttr_Check:
	ld wa, (0x025ea8:24)
	cp wa, 0:i3
	jr lt, FileIO_GetRecordAttr_Return
	cp wa, 0x14
	jr lt, FileIO_GetRecordAttr_Default

FileIO_GetRecordAttr_Return:
	ld l, 0x0:opc
	ret

FileIO_GetRecordAttr_Default:
	ld l, (0x0272d0:24)
	ret

FileIO_SetModeFlag_Writing:
	ld (0x0272d0:24), 0x01
	ret

FileIO_SetModeFlag_Reading:
	ld (0x0272d0:24), 0x00
	ret

FileIO_CheckRecordValid:
	ld bc, (0x025ea8:24)
	cp bc, 0:i3
	jr lt, CheckRecord_ReturnFalse
	cp bc, 0x14
	jr ge, CheckRecord_ReturnFalse
	cp a, 0xa
	jr c, CheckRecord_ValidRange

CheckRecord_ReturnFalse:
	ld l, 0x0:opc
	ret

CheckRecord_ValidRange:
	ld de, 1:i3
	and a, 0xf
	jr z, CheckRecord_ShiftDone
	slla de

CheckRecord_ShiftDone:
	muls bc, 0xc
	ld wa, bc
	lda xbc, (0x025db8:24)
	ld	wa, (xbc+wa)
	and wa, de
	cp wa, de
	scc8 z, l
	ret

FileIO_CheckRecordByFile:
	ld de, wa
	cp de, 0x14
	jr nc, CheckRecordByFile_OutOfRange
	cp c, 0xa
	jr c, CheckRecordByFile_Valid

CheckRecordByFile_OutOfRange:
	ld l, 0x0:opc
	ret

CheckRecordByFile_Valid:
	ld hl, 1:i3
	ld a, c
	and a, 0xf
	jr z, CheckRecordByFile_ShiftDone
	slla hl

CheckRecordByFile_ShiftDone:
	extz xde
	ld xbc, xde
	add xbc, xbc
	add xbc, xde
	sll xbc, 2
	ld xwa, 0x25db8
	add xwa, xbc
	ld wa, (xwa)
	and wa, hl
	cp wa, hl
	scc8 z, l
	ret

CheckFileSystemStatus:
	ld wa, (0x025ea8:24)
	cp wa, 0:i3
	jr lt, CheckFS_ReturnZero
	cp wa, 0x14
	jr lt, CheckFS_ValidIndex

CheckFS_ReturnZero:
	ld hl, 0:i3
	ret

CheckFS_ValidIndex:
	muls wa, 0xc
	lda xbc, (0x025db8:24)
	ld	hl, (xbc+wa)
	ret

FileIO_GetRecordFlags:
	cp wa, 0x14
	jr c, GetRecordFlags_Valid
	ld hl, 0:i3
	ret

GetRecordFlags_Valid:
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	ld xwa, 0x25db8
	add xwa, xbc
	ld hl, (xwa)
	ret

FileIO_CheckFileExists:
	lda xsp, (xsp-266)
	lda xbc, (xsp)
	call _findfirst
	ld xwa, xhl
	cp xwa, 0x0
	jr lt, CheckFileExists_NotFound
	call _findclose
	ld l, 0x1:opc
	jr CheckFileExists_Done

CheckFileExists_NotFound:
	ld l, 0x0:opc

CheckFileExists_Done:
	lda xsp, (xsp+266)
	ret

FileIO_InitRecordTable:
	ld xiy, FileIO_DiskInfoInit
	ld xix, 0x25d6c
	ldw bc, 0x26
	ldirw
	lda xbc, (0x025db8:24)
	ld xwa, xbc
	lda xde, (xbc+240:16)

InitRecordTable_CopyLoop:
	ld xiy, FileIO_EmptyFileRecord
	ld xix, xwa
	ld bc, 6:i3
	ldirw
	lda xwa, (xwa + 12)
	cp xwa, xde
	jr c, InitRecordTable_CopyLoop
	lda xbc, (0x025eb2:24)
	ld xwa, xbc
	lda xde, (xbc+4920)

InitRecordTable_ExtLoop:
	ld xiy, FileIO_DirListEntryTemplate
	ld xix, xwa
	ldw bc, 0x29
	ldirw
	lda xwa, (xwa + 82)
	cp xwa, xde
	jr c, InitRecordTable_ExtLoop
	ldw (0x025ea8:24), 0x0000
	ldw (0x0271ea:24), 0x0000
	ldw (0x0271ec:24), 0x0000
	ldw (0x0271ee:24), 0x0000
	ldw (0x0271f0:24), 0x0000
	ldw (0x0272c8:24), 0x0000
	ldw (0x0272ca:24), 0x0000
	ret

GetDiskSizeInfo:
	ld a, (FileIO_DiskInfoInit_MediaType:24)
	cp a, (0x25db6:24)
	jr nz, GetDiskSize_Return
	call GetMediaType
	ld (0x025db6:24), l

GetDiskSize_Return:
	ld l, (0x025db6:24)
	ret

GetEncodedFreeSpaceData:
	lda xwa, (0x025d6c:24)
	ld xbc, (FileIO_DiskInfoInit:24)
	cp xbc, (xwa)
	jr nz, GetEncoded_Return
	lda xbc, (xwa + 4)
	call GetDiskFreeSpace

GetEncoded_Return:
	ld xhl, (0x025d6c:24)
	ret

FileIO_GetDiskFreeSpace:
	lda xwa, (0x025d6c:24)
	lda xbc, (xwa + 4)
	call GetDiskFreeSpace
	ld xhl, (0x025d6c:24)
	ret

FileIO_ResetCurrentRecord:
	ld xwa, (FileIO_DiskInfoInit:24)
	ld (0x025d6c:24), xwa
	ret

FileIO_GetDiskRecordPtr:
	lda xwa, (0x025d6c:24)
	lda xbc, (xwa + 4)
	ld xde, (FileIO_DiskInfoInit_Capacity:24)
	cp xde, (xbc)
	call z, (GetDiskFreeSpace:24)
	ld xhl, (0x025d70:24)
	ret

FileIO_SearchAndLoadFile:
	push xiz
	lda xwa, (0x025d74:24)
	lda xbc, (FileIO_EmptyVolumeName:24)
	calr FileIO_SearchFile
	cp hl, 0:i3
	jr nz, SearchLoad_Return
	call GetVolumeLabel
	ld xwa, xhl
	ld xiz, xwa
	or xwa, xwa
	jr z, SearchLoad_DefaultVolume
	lda xbc, (FileIO_EmptyVolumeName:24)
	calr FileIO_SearchFile
	cp hl, 0:i3
	jr nz, SearchLoad_CopyPath

SearchLoad_DefaultVolume:
	ld xiz, SearchLoad_DefaultVolume_Str_Under_Under_Under_Under

SearchLoad_CopyPath:
	lda xwa, (0x025d74:24)
	ld xbc, xiz
	calr FileIO_CopyString

SearchLoad_Return:
	lda xhl, (0x025d74:24)
	pop xiz
	ret

ValidateFileSelectionIndex:
	ld c, (0x025db6:24)
	cp c, 2:i3
	jr z, ValidateSelection_CheckRange
	cp c, 3:i3
	jr z, ValidateSelection_CheckRange
	cp c, 4:i3
	jr nz, ValidateSelection_Error

ValidateSelection_CheckRange:
	cp wa, 0:i3
	jr lt, ValidateSelection_Error
	cp wa, 0x14
	jr lt, ValidateSelection_Ok

ValidateSelection_Error:
	ldw hl, 0xffff
	ret

ValidateSelection_Ok:
	ld hl, 0:i3
	ret

GetCurrentFileIndex:
	ld wa, (0x025ea8:24)
	calr ValidateFileSelectionIndex
	cp hl, 0:i3
	jr z, GetCurrentFile_ReturnIndex
	ldw hl, 0xff98
	ret

GetCurrentFile_ReturnIndex:
	ld hl, (0x025ea8:24)
	ret

NotifyUIOfSelectionChange:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileSelectionIndex
	cp hl, 0xffff
	jr nz, NotifyUI_StoreIndex
	ld hl, (0x025ea8:24)
	jr NotifyUI_Return

NotifyUI_StoreIndex:
	ld hl, iz
	ld (0x025ea8:24), hl

NotifyUI_Return:
	popw iz
	ret

GetFileEntryPtr:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileSelectionIndex
	cp hl, 0:i3
	jr z, GetFileEntryPtr_Compute
	lda xhl, (FileIO_EmptyEntryName:24)
	jr GetFileEntryPtr_Return

GetFileEntryPtr_Compute:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	lda xhl, (0x025dba:24)
	add xhl, xbc

GetFileEntryPtr_Return:
	popw iz
	ret

GetCurrentFileType:
	ld wa, (0x025ea8:24)
	calr ValidateFileSelectionIndex
	cp hl, 0:i3
	jr z, GetCurrentFileType_Lookup
	ld l, 0x0:opc
	ret

GetCurrentFileType_Lookup:
	ld wa, (0x025ea8:24)
	muls wa, 0xc
	lda xbc, (0x025dc2:24)
	ld	l, (xbc+wa)
	ret

UpdateFileEntry:
	lda xsp, (xsp-300)
	push xiz
	ld	(xsp+302), c
	ld iz, wa
	ld xiy, UpdateFileEntry_BaseNameInit
	lda xix, (xsp + 20)
	ldw bc, 0x8
	ldirw
	ld xiy, UpdateFileEntry_FileNameInit
	lda xix, (xsp + 4)
	ldw bc, 0x8
	ldirw
	ld wa, iz
	calr ValidateFileSelectionIndex
	cp hl, 0:i3
	jr nz, UpdateFileEntry_Error
	ldto_berp A, 0xf8
	extz wa
	ldfr_werp WA, 0xfa
	ld wa, iz
	calr GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 20)
	ldto_werp BC, 0xfa
	calr FileIO_FormatFileIndex
	lda xbc, (xsp + 20)
	ld	e, (xsp+302)
	extz de
	lda xwa, (xsp + 4)
	calr FileIO_ReadHeader
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 36)
	call _findfirst
	ld xwa, xhl
	cp xwa, 0x0
	jr ge, UpdateFileEntry_Commit

UpdateFileEntry_Error:
	ld xhl, 0xffffff98
	jr UpdateFileEntry_Return

UpdateFileEntry_Commit:
	call _findclose
	ld xhl, (xsp + 38)

UpdateFileEntry_Return:
	pop xiz
	lda xsp, (xsp+300)
	ret

ParseFileExtension:
	dec 6, xsp
	push xiz
	ld (xsp + 4), xbc
	ld (xsp + 8), wa
	cpw (xsp + 8), 0x14
	jr nc, ParseFileExt_NoMatch
	ld iz, 0:i3
	ld xwa, (xsp + 4)
	jr ParseFileExt_CheckDot

ParseFileExt_ScanDot:
	inc 1, iz
	inc 1, xwa

ParseFileExt_CheckDot:
	cp (xwa), 0x2e
	jr z, ParseFileExt_DotFound
	cp iz, 0xa
	jr c, ParseFileExt_ScanDot

ParseFileExt_DotFound:
	cp iz, 0xa
	jr nc, ParseFileExt_NoMatch
	inc 1, iz
	ldib_erp 0xfb, 0

ParseFileExt_MatchLoop:
	ldto_berp A, 0xfb
	extz wa
	sla wa, 2
	lda xbc, (FileIO_TypeExtensions:24)
	ld	xwa, (xbc+wa)
	ld bc, iz
	extz xbc
	add xbc, (xsp + 4)
	calr FileIO_SearchFile
	cp hl, 0:i3
	jr z, ParseFileExt_MatchCheck
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr c, ParseFileExt_MatchLoop

ParseFileExt_MatchCheck:
	cp_erpb 0xfb, 0x0a
	jr c, ParseFileExt_StoreResult

ParseFileExt_NoMatch:
	ldw hl, 0xffff
	jr ParseFileExt_Return

ParseFileExt_StoreResult:
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	ld xde, 0x25db8
	add xde, xbc
	ld bc, 1:i3
	ldto_berp A, 0xfb
	and a, 0xf
	jr z, ParseFileExt_SetFlag
	slla bc

ParseFileExt_SetFlag:
	or (xde), bc
	ldto_berp L, 0xfb
	extz hl

ParseFileExt_Return:
	pop xiz
	inc 6, xsp
	ret

ParseTwoDigitFileNum:
	cp (xwa), 0x30
	jr lt, ParseTwoDigitFileNum_Invalid
	cp (xwa), 0x32
	jr gt, ParseTwoDigitFileNum_Invalid
	ld c, (xwa + 1)
	cp c, 0x30
	jr lt, ParseTwoDigitFileNum_Invalid
	cp c, 0x39
	jr gt, ParseTwoDigitFileNum_Invalid
	ld a, (xwa)
	muls a, 0xa
	add a, c
	sub a, 0x10
	exts wa
	cp wa, 1:i3
	jr lt, ParseTwoDigitFileNum_Invalid
	cp wa, 0x14
	jr le, ParseTwoDigitFileNum_Return

ParseTwoDigitFileNum_Invalid:
	ldw hl, 0xffff
	ret

ParseTwoDigitFileNum_Return:
	dec 1, wa
	ld hl, wa
	ret

HandleFilenameChange:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 6), xde
	ld (xsp + 10), xbc
	ld iz, wa
	ld bc, iz
	muls bc, 0xc
	lda xwa, (0x025db8:24)
	lda	xwa, (xwa+bc)
	cp (xwa + 2), 0x0
	jr nz, HandleFilenameChange_ExistingEntry
	ld wa, iz
	ld xbc, (xsp + 10)
	calr ParseFileExtension
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jrl lt, HandleFilenameChange_ReturnFail
	ld bc, iz
	muls bc, 0xc
	lda xwa, (0x025dba:24)
	lda	xwa, (xwa+bc)
	ld xbc, (xsp + 10)
	inc 2, xbc
	ld de, 6:i3
	calr FileIO_CopyString_WriteNull
	muls iz, 0xc
	lda xwa, (0x025db8:24)
	lda	xwa, (xwa+iz)
	ld (xwa + 8), 0x0
	cpw (xsp + 4), 0x0
	jr nz, HandleFilenameChange_ReturnOK
	lda xbc, (xwa + 10)
	ld xwa, (xsp + 6)
	cp xwa, 0x1388
	jr ule, HandleFilenameChange_NoOverwrite
	ld (xbc), 0x1
	jr HandleFilenameChange_ReturnOK

HandleFilenameChange_NoOverwrite:
	ld (xbc), 0x0

HandleFilenameChange_ReturnOK:
	ld hl, 1:i3
	jr HandleFilenameChange_Return

HandleFilenameChange_ExistingEntry:
	inc 2, xwa
	ld xbc, (xsp + 10)
	inc 2, xbc
	ld de, 6:i3
	calr FileIO_Search_SkipEntry
	cp hl, 0:i3
	jr nz, HandleFilenameChange_ReturnFail
	ld wa, iz
	ld xbc, (xsp + 10)
	calr ParseFileExtension
	cp hl, 0:i3
	jr nz, HandleFilenameChange_ReturnFail
	lda xbc, (0x025dc2:24)
	muls iz, 0xc
	lda	xbc, (xbc+iz)
	ld xwa, (xsp + 6)
	cp xwa, 0x1388
	jr ule, HandleFilenameChange_SmallFile
	ld (xbc), 0x1
	jr HandleFilenameChange_ReturnFail

HandleFilenameChange_SmallFile:
	ld (xbc), 0x0

HandleFilenameChange_ReturnFail:
	ld hl, 0:i3

HandleFilenameChange_Return:
	pop xiz
	lda xsp, (xsp + 10)
	ret

GetEncodedFileSizeData:
	lda xsp, (xsp-274)
	pushw iz
	lda xbc, (0x025db8:24)
	ld xwa, xbc
	lda xde, (xbc+240:16)

GetEncFileSize_CopyRecordLoop:
	ld xiy, FileIO_EmptyFileRecord
	ld xix, xwa
	ld bc, 6:i3
	ldirw
	lda xwa, (xwa + 12)
	cp xwa, xde
	jr c, GetEncFileSize_CopyRecordLoop
	ld iz, 0:i3
	lda xbc, (xsp + 10)
	ld xwa, GetEncFileSize_CopyRecordLoop_Str_Star_Dot_Star
	call _findfirst
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr lt, GetEncFileSize_Return
	lda xbc, (xsp + 16)
	ld xwa, xbc
	ld (xsp + 6), xbc
	calr ParseTwoDigitFileNum
	ld wa, hl
	cp wa, 0:i3
	jr lt, GetEncFileSize_AfterFirstMatch
	ld xde, (xsp + 12)
	ld xbc, (xsp + 6)
	calr HandleFilenameChange
	add iz, hl

GetEncFileSize_AfterFirstMatch:
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cp hl, 0:i3
	jr nz, GetEncFileSize_ReleaseHandle

GetEncFileSize_IterLoop:
	ld xwa, (xsp + 6)
	calr ParseTwoDigitFileNum
	ld wa, hl
	cp wa, 0:i3
	jr lt, GetEncFileSize_IterNext
	ld xde, (xsp + 12)
	ld xbc, (xsp + 6)
	calr HandleFilenameChange
	add iz, hl

GetEncFileSize_IterNext:
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cp hl, 0:i3
	jr z, GetEncFileSize_IterLoop

GetEncFileSize_ReleaseHandle:
	ld xwa, (xsp + 2)
	call _findclose

GetEncFileSize_Return:
	ld hl, iz
	popw iz
	lda xsp, (xsp+274)
	ret

; =============================================================================
; Number conversion and array search function (F8991C-F89A7A)
;
; Converts a numeric index to ASCII digit pair, formats into a buffer,
; then iterates through a 12-byte record array at 0x025db8 performing
; lookups and copies. Uses div-by-10 to extract decimal digits.
; =============================================================================
IndexToRecordLookup:
	lda	xsp, (xsp-288)
	pushw iz
	ld xde, xbc
	ld iz, wa				; IZ = index parameter
	ldw (xsp + 6), 0x0000			; result flag = 0 (16-bit store)
	ld wa, iz
	extz xwa
	ld xbc, xwa				; XBC = index
	add xbc, xbc				; XBC = index * 2
	add xbc, xwa				; XBC = index * 3
	sll xbc, 2				; XBC = index * 12 (record stride)
	ld xix, 0x00025db8			; record array base
	add xix, xbc				; XIX = &records[index]
	ld xiy, FileIO_EmptyFileRecord			; destination descriptor
	ld	bc, 6:i3
	ldirw					; copy 6 words (12 bytes)
	lda xbc, (xsp + 8)			; XBC = output buffer
	ld hl, iz
	inc 1, hl				; HL = index + 1
	ld wa, hl
	extz xwa
	div wa, 0x000a				; WA = quotient, remainder in ?
	add a, 0x30				; convert to ASCII '0'-'9'
	ld (xbc), a				; store ones digit
	extz xhl
	div hl, 0x000a				; second digit extraction
	ld wa, qhl				; get quotient from Q bank
	add a, 0x30				; convert to ASCII
	ld (xbc + 1), a				; store tens digit
	lda xwa, (xbc + 2)			; buffer + 2
	ld xbc, xde				; restore saved arg
	calr FileIO_CopyString			; format string
	lda xwa, (xsp + 8)			; output buffer
	ld xbc, IndexToRecordLookup_Str_Dot_Star			; descriptor
	calr FileIO_BuildFilePath			; additional format
	lda xwa, (xsp + 8)			; output buffer
	lda xbc, (xsp + 24)			; secondary buffer
	call _findfirst				; compare/process
	ld (xsp + 2), xhl			; save result handle
	ld xwa, (xsp + 2)			; reload handle
	cp xwa, 0x00000000			; valid handle?
	jrl lt, IdxRecLookup_Return			; no, cleanup
	lda xbc, (xsp + 30)			; tertiary buffer
	ld wa, iz				; index
	calr ParseFileExtension			; lookup
	cp hl, 0:i3
	jr lt, IdxRecLookup_AfterFirstMatch			; failed
	ld wa, iz				; --- copy record[index].field to buffer ---
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2				; XBC = index * 12
	lda xwa, (0x025dba:24); field at offset +2
	add xwa, xbc
	lda xbc, (xsp + 32)			; destination
	ld	de, 6:i3
	calr FileIO_CopyString_WriteNull			; copy 6 words
	ld wa, iz				; --- clear record[index].flag ---
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2				; XBC = index * 12
	lda xwa, (0x025dc0:24); flag at offset +8
	add xwa, xbc
	ld (xwa), 0x00				; clear flag byte
	ldw (xsp + 6), 0x0001			; result flag = 1 (found)
IdxRecLookup_AfterFirstMatch:
	lda xbc, (xsp + 24)
	ld xwa, (xsp + 2)			; result handle
	call _findnext				; iterate/next
	cp hl, 0:i3
	jrl nz, IdxRecLookup_ReleaseHandle			; done iterating
IdxRecLookup_IterBody:
	ld wa, iz				; --- iteration loop body ---
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2				; XBC = index * 12
	ld xwa, 0x00025db8			; record base
	add xwa, xbc
	lda xbc, (xsp + 24)
	cp (xwa + 2), 0x00			; check record field
	jr nz, IdxRecLookup_NonZeroField			; non-zero, different path
	inc 6, xbc				; advance buffer by 6
	ld wa, iz
	calr ParseFileExtension			; lookup
	cp hl, 0:i3
	jr lt, IdxRecLookup_IterNext			; failed
	ld wa, iz				; --- copy record field ---
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	lda xwa, (0x025dba:24)
	add xwa, xbc
	lda xbc, (xsp + 32)
	ld	de, 6:i3
	calr FileIO_CopyString_WriteNull			; copy
	ld wa, iz
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	lda xwa, (0x025dc0:24)
	add xwa, xbc
	ld (xwa), 0x00				; clear flag
	jr IdxRecLookup_IterNext				; continue
IdxRecLookup_NonZeroField:
	inc 2, xwa				; advance to next field
	inc 8, xbc				; advance buffer (inc 0 encoding = 8)
	ld	de, 6:i3
	calr FileIO_Search_SkipEntry			; compare/copy
	cp hl, 0:i3
	jr nz, IdxRecLookup_IterNext			; mismatch, skip
	lda xbc, (xsp + 30)
	ld wa, iz
	calr ParseFileExtension			; lookup
IdxRecLookup_IterNext:
	lda xbc, (xsp + 24)
	ld xwa, (xsp + 2)			; result handle
	call _findnext				; iterate/next
	cp hl, 0:i3
	jr z, IdxRecLookup_IterBody			; more entries, loop
IdxRecLookup_ReleaseHandle:
	ld xwa, (xsp + 2)			; result handle
	call _findclose				; release/close
IdxRecLookup_Return:
	ld hl, (xsp + 6)			; return result flag
	popw iz
	lda	xsp, (xsp+288)
	ret


ValidateFileRange:
	ld c, (0x025db6:24)
	cp c, 2:i3
	jr z, ValidateFileRange_CheckLower
	cp c, 3:i3
	jr z, ValidateFileRange_CheckLower
	cp c, 4:i3
	jr nz, ValidateFileRange_Invalid

ValidateFileRange_CheckLower:
	cp wa, 0:i3
	jr lt, ValidateFileRange_Invalid
	cp wa, (0x271ec:24)
	jr le, ValidateFileRange_InRange

ValidateFileRange_Invalid:
	ldw hl, 0xffff
	ret

ValidateFileRange_InRange:
	ld bc, (0x0271ee:24)
	cp wa, bc
	jr lt, ValidateFileRange_FirstPage
	cp wa, (0x271f0:24)
	jr le, ValidateFileRange_SecondPage

ValidateFileRange_FirstPage:
	ld hl, 1:i3
	ret

ValidateFileRange_SecondPage:
	sub wa, bc
	muls wa, 0x52
	lda xbc, (0x025eb2:24)
	cp	(xbc+wa), 0x00
	jr nz, ValidateFileRange_Found
	ld hl, 2:i3
	ret

ValidateFileRange_Found:
	ld hl, 0:i3
	ret

GetFirstPageBase:
	ld wa, (0x0271ea:24)
	calr ValidateFileRange
	cp hl, 0:i3
	jr z, GetFirstPageBase_Valid
	ldw hl, 0xff98
	ret

GetFirstPageBase_Valid:
	ld hl, (0x0271ea:24)
	ret

BuildSecondPageRecords:
	lda xsp, (xsp-274)
	pushw iz
	lda xbc, (0x025eb2:24)
	ld xwa, xbc
	lda xde, (xbc+4920)

BuildSecondPage_CopyRecordLoop:
	ld xiy, FileIO_DirListEntryTemplate
	ld xix, xwa
	ldw bc, 0x29
	ldirw
	lda xwa, (xwa + 82)
	cp xwa, xde
	jr c, BuildSecondPage_CopyRecordLoop
	ld iz, 0:i3
	lda xbc, (xsp + 10)
	ld xwa, BuildSecondPage_CopyRecordLoop_Str_MID
	call _findfirst
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr lt, BuildSecondPage_Return
	lda xwa, (xsp + 16)
	ld (xsp + 6), xwa
	ld wa, (0x0271ee:24)
	cp wa, 0:i3
	jr gt, BuildSecondPage_IterStart
	cpw (0x271f0:24), 0
	jr lt, BuildSecondPage_IterStart
	neg wa
	muls wa, 0x52
	lda xbc, (0x025eb2:24)
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

BuildSecondPage_IterStart:
	ld iz, 1:i3
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cp hl, 0:i3
	jr nz, BuildSecondPage_ReleaseHandle

BuildSecondPage_IterBody:
	ld wa, (0x0271ee:24)
	cp iz, wa
	jr lt, BuildSecondPage_IterNext
	cp iz, (0x271f0:24)
	jr gt, BuildSecondPage_IterNext
	ld bc, iz
	sub bc, wa
	muls bc, 0x52
	ld wa, bc
	lda xbc, (0x025eb2:24)
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

BuildSecondPage_IterNext:
	inc 1, iz
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cp hl, 0:i3
	jr z, BuildSecondPage_IterBody

BuildSecondPage_ReleaseHandle:
	ld xwa, (xsp + 2)
	call _findclose

BuildSecondPage_Return:
	ld hl, iz
	popw iz
	lda xsp, (xsp+274)
	ret

NavigateToFileIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRange
	cp hl, 0xffff
	jr nz, NavToFileIdx_InSecondPage
	ld hl, (0x0271ea:24)
	jr NavToFileIdx_Return

NavToFileIdx_InSecondPage:
	cp hl, 1:i3
	jr nz, NavToFileIdx_StoreIndex
	ld wa, iz
	extz xwa
	div wa, 0x3c
	mul wa, 0x3c
	ld bc, wa
	ld (0x0271ee:24), bc
	add bc, 0x3b
	ld wa, (0x0271ec:24)
	cp bc, wa
	jr ge, NavToFileIdx_ClampEnd
	ld wa, bc

NavToFileIdx_ClampEnd:
	ld (0x0271f0:24), wa
	calr BuildSecondPageRecords

NavToFileIdx_StoreIndex:
	ld hl, iz
	ld (0x0271ea:24), hl

NavToFileIdx_Return:
	popw iz
	ret

GetRecordPtrForFile:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRange
	cp hl, 0:i3
	jr z, GetRecordPtr_InRange
	lda xhl, (FileIO_EmptyEntryName:24)
	jr GetRecordPtr_Return

GetRecordPtr_InRange:
	ld wa, (0x0271ee:24)
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25eb2
	add xwa, xhl
	ld xhl, xwa

GetRecordPtr_Return:
	popw iz
	ret

ValidateAndSearchFile:
	; --- Configuration/validation function (84 bytes) ---
	lda	xsp, (xsp-282)
	pushw iz
	ld iz, wa
	ld xiy, ValidateAndSearchFile_PathInit
	lda xix, (xsp + 2)
	ldw bc, 8
	ldirw
	ld wa, iz
	calr ValidateFileRange
	cp hl, 0:i3
	jr nz, ValidateAndSearch_NotFound
	ld wa, iz
	calr GetRecordPtrForFile
	ld xbc, xhl
	lda xwa, (xsp + 2)
	calr FileIO_CopyString
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 18)
	call _findfirst
	ld xwa, xhl
	cp xwa, 0x00000000
	jr ge, ValidateAndSearch_Found
ValidateAndSearch_NotFound:
	ld xhl, 0xffffff98
	jr t, ValidateAndSearch_Return
ValidateAndSearch_Found:
	call _findclose
	ld xhl, (xsp + 20)
ValidateAndSearch_Return:
	popw iz
	lda	xsp, (xsp+282)
	ret


GetFileCountEncoded:
	ldw (0x0271ee:24), 0x0000
	ldw (0x0271f0:24), 0x003b
	calr BuildSecondPageRecords
	ld wa, 0:i3
	cp hl, 0:i3
	jr le, GetFileCount_StoreAndClamp
	ld wa, hl
	dec 1, wa

GetFileCount_StoreAndClamp:
	ld (0x0271ec:24), wa
	cp (0x271f0:24), wa
	ret le
	ld (0x0271f0:24), wa
	ret

ReadVariableLengthInt:
	push xiz
	ld xiz, 0:i3
	jr ReadVarLen_ReadNext

ReadVarLen_AccumulateLoop:
	and hl, 0x7f
	exts xhl
	add xiz, xhl
	sll xiz, 7

ReadVarLen_ReadNext:
	call FileIO_ReadByte
	cp hl, 0x7f
	jr gt, ReadVarLen_AccumulateLoop
	cp hl, 0:i3
	jr ge, ReadVarLen_Negative
	ldw hl, 0xffff
	jr ReadVarLen_Return

ReadVarLen_Negative:
	exts xhl
	add xiz, xhl
	ld xhl, 0x7fff
	cp xiz, 0x7fff
	jr ugt, ReadVarLen_Return
	ld xhl, xiz

ReadVarLen_Return:
	pop xiz
	ret

ReadFieldToBuffer:
	dec 8, xsp
	pushw iz
	ld (xsp + 4), xbc
	ld (xsp + 8), wa
	ld xwa, (xsp + 4)
	cp (xwa), 0x0
	jrl nz, ReadField_Return
	ld iz, 0:i3
	cpw (xsp + 8), 0x40
	jr gt, ReadField_LongInit
	cpw (xsp + 8), 0x0
	jr le, ReadField_Terminate

ReadField_ShortLoop:
	call FileIO_ReadByte
	cp hl, 0:i3
	jr ge, ReadField_StoreByte
	ld hl, 0:i3

ReadField_StoreByte:
	ld xwa, (xsp + 4)
	ld	(xwa+iz), l
	decm 1, (xsp + 8)
	inc 1, iz
	cpw (xsp + 8), 0x0
	jr gt, ReadField_ShortLoop
	jr ReadField_Terminate

ReadField_LongInit:
	ldw (xsp + 2), 0x1

ReadField_LongLoop:
	call FileIO_ReadByte
	cp hl, 0:i3
	jr lt, ReadField_DiscardExtra
	ld c, l
	ld xwa, (xsp + 4)
	lda	xwa, (xwa+iz)
	cpw (xsp + 2), 0x0
	jr z, ReadField_Long_CheckSpace
	cp hl, 0x20
	jr z, ReadField_Long_StoreIfNotLeading
	ldw (xsp + 2), 0x0

ReadField_Long_CheckSpace:
	ld (xwa), c

ReadField_Long_StoreIfNotLeading:
	decm 1, (xsp + 8)
	inc 1, iz
	cp iz, 0x40
	jr lt, ReadField_LongLoop

ReadField_DiscardExtra:
	cpw (xsp + 8), 0x0
	jr le, ReadField_Terminate

ReadField_DiscardLoop:
	call FileIO_ReadByte
	decm 1, (xsp + 8)
	cpw (xsp + 8), 0x0
	jr gt, ReadField_DiscardLoop

ReadField_Terminate:
	ld xwa, (xsp + 4)
	ld	(xwa+iz), 0x00
	jr ReadField_TrimLoop

ReadField_TrimSpace:
	ld (xwa), 0x0

ReadField_TrimLoop:
	dec 1, iz
	ld xwa, (xsp + 4)
	lda	xwa, (xwa+iz)
	cp (xwa), 0x20
	jr nz, ReadField_Return
	cp iz, 0:i3
	jr gt, ReadField_TrimSpace

ReadField_Return:
	popw iz
	inc 8, xsp
	ret

ParseSMFTrackName:
	push xiz
	ld iz, 0:i3
	ld (0x025b90:24), 0x00
	ldiw_erp 0xfa, 0
	calr ReadVariableLengthInt
	cp hl, 0:i3
	jrl nz, ParseSMF_ReturnNamePtr

ParseSMF_ReadEvent:
	call FileIO_ReadByte
	cp hl, 0xff
	jr nz, ParseSMF_CheckSysex
	call FileIO_ReadByte
	ldfr_werp HL, 0xfa
	calr ReadVariableLengthInt
	ld iz, hl
	cpiw_erp 0xfa, 3
	jr nz, ParseSMF_ResetRunning
	ld wa, iz
	ld xbc, 0x25b90
	calr ReadFieldToBuffer
	ld iz, 0:i3
	jr ParseSMF_ResetRunning

ParseSMF_CheckSysex:
	cp hl, 0xf0
	jr z, ParseSMF_SysexReadLen
	cp hl, 0xf7
	jr nz, ParseSMF_CheckMIDI

ParseSMF_SysexReadLen:
	calr ReadVariableLengthInt
	ld iz, hl

ParseSMF_ResetRunning:
	ldiw_erp 0xfa, 0

ParseSMF_SkipDataBytes:
	cp iz, 0:i3
	jr le, ParseSMF_CheckEOF

ParseSMF_SkipLoop:
	ld wa, iz
	exts xwa
	ld bc, 1:i3
	call FileIO_SeekAndReadBlock

ParseSMF_CheckEOF:
	call FileIO_ReturnError
	cp hl, 0:i3
	jr ge, ParseSMF_ReadDeltaAndLoop
	ld xhl, 0:i3
	jr ParseSMF_Return

ParseSMF_CheckMIDI:
	cp hl, 0xc0
	jr lt, ParseSMF_Check3ByteMsg
	cp hl, 0xdf
	jr gt, ParseSMF_Check3ByteMsg
	ld iz, 2:i3
	jr ParseSMF_SetRunningStatus

ParseSMF_Check3ByteMsg:
	cp hl, 0x80
	jr lt, ParseSMF_CheckDataByte
	cp hl, 0xef
	jr gt, ParseSMF_CheckDataByte
	ld iz, 3:i3

ParseSMF_SetRunningStatus:
	ldfr_werp HL, 0xfa
	jr ParseSMF_SkipDataBytes

ParseSMF_CheckDataByte:
	cp hl, 0x7f
	jr gt, ParseSMF_SkipDataBytes
	cp_erpw 0xfa, 0xc0, 0x00
	jr lt, ParseSMF_RunningStatus3Byte
	cp_erpw 0xfa, 0xdf, 0x00
	jr gt, ParseSMF_RunningStatus3Byte
	ld iz, 1:i3
	jr ParseSMF_SkipLoop

ParseSMF_RunningStatus3Byte:
	ld iz, 2:i3
	jr ParseSMF_SkipLoop

ParseSMF_ReadDeltaAndLoop:
	calr ReadVariableLengthInt
	cp hl, 0:i3
	jrl z, ParseSMF_ReadEvent

ParseSMF_ReturnNamePtr:
	lda xhl, (0x025b90:24)

ParseSMF_Return:
	pop xiz
	ret

ProcessFileRecord:
	dec 8, xsp
	push xiz
	ld (xsp + 10), wa
	ld wa, (0x0271ee:24)
	sub (xsp + 10), wa
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25eb2
	add xwa, xhl
	ld xbc, ProcessFileRecord_Str_rb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jrl lt, ProcessRecord_ErrorReturn
	ld iz, 0:i3

ProcessRecord_MatchLoop1:
	call FileIO_ReadByte
	ld wa, iz
	extz xwa
	ld xbc, ProcessRecord_MatchLoop1_Str_MThd
	add xbc, xwa
	ld a, (xbc)
	exts wa
	cp wa, hl
	jr z, ProcessRecord_Match1Next
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25eb2
	add xwa, xhl
	setm 5, (xwa + 80)
	lda xwa, (xwa + 14)
	ld xbc, ProcessRecord_MatchLoop1_Str_Blank5
	calr FileIO_CopyString
	jr ProcessRecord_CheckBit5

ProcessRecord_Match1Next:
	inc 1, iz
	cp iz, 4:i3
	jr c, ProcessRecord_MatchLoop1

ProcessRecord_CheckBit5:
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda xwa, (0x025f02:24)
	add xwa, xhl
	bitm 5, (xwa)
	jr z, ProcessRecord_ReadTimeSig
	ld xwa, 0x80
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	ld iz, 0:i3

ProcessRecord_MatchLoop2:
	call FileIO_ReadByte
	ld wa, iz
	extz xwa
	ld xbc, ProcessRecord_MatchLoop1_Str_MThd
	add xbc, xwa
	ld a, (xbc)
	exts wa
	cp wa, hl
	jr z, ProcessRecord_Match2Next
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25eb2
	add xwa, xhl
	setm 5, (xwa + 80)
	lda xwa, (xwa + 14)
	ld xbc, ProcessRecord_MatchLoop1_Str_Blank5
	jrl ProcessRecord_CopyPath

ProcessRecord_Match2Next:
	inc 1, iz
	cp iz, 5:i3
	jr c, ProcessRecord_MatchLoop2
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda xwa, (0x025f02:24)
	add xwa, xhl
	resm 5, (xwa)
	setm 6, (xwa)

ProcessRecord_ReadTimeSig:
	ld xwa, 4:i3
	ld bc, 1:i3
	call FileIO_SeekAndReadBlock
	call FileIO_ReadByte
	ld iz, hl
	sll iz, 8
	call FileIO_ReadByte
	or iz, hl
	jr nz, ProcessRecord_CheckTempo
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda xwa, (0x025f02:24)
	add xwa, xhl
	resm 7, (xwa)

ProcessRecord_ReadAfterTimeSig:
	ld xwa, 4:i3
	ld bc, 1:i3
	call FileIO_SeekAndReadBlock
	ld iz, 0:i3

ProcessRecord_MatchLoop3:
	call FileIO_ReadByte
	ld wa, iz
	extz xwa
	ld xbc, ProcessRecord_MatchLoop3_Str_MTrk
	add xbc, xwa
	ld a, (xbc)
	exts wa
	cp wa, hl
	jr z, ProcessRecord_Match3Next
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25eb2
	add xwa, xhl
	setm 5, (xwa + 80)
	lda xwa, (xwa + 14)
	ld xbc, ProcessRecord_MatchLoop1_Str_Blank5
	jr ProcessRecord_CopyPath

ProcessRecord_CheckTempo:
	cp iz, 1:i3
	jr nz, ProcessRecord_DefaultSetBit
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda xwa, (0x025f02:24)
	add xwa, xhl
	setm 7, (xwa)
	jr ProcessRecord_ReadAfterTimeSig

ProcessRecord_DefaultSetBit:
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25eb2
	add xwa, xhl
	setm 5, (xwa + 80)
	lda xwa, (xwa + 14)
	ld xbc, ProcessRecord_MatchLoop1_Str_Blank5

ProcessRecord_CopyPath:
	calr FileIO_CopyString
	call FileIO_CloseHandle

ProcessRecord_ErrorReturn:
	ldw hl, 0xffff
	jrl ProcessRecord_Return

ProcessRecord_Match3Next:
	inc 1, iz
	cp iz, 4:i3
	jrl c, ProcessRecord_MatchLoop3
	ld xwa, 4:i3
	ld bc, 1:i3
	call FileIO_SeekAndReadBlock
	calr ParseSMFTrackName
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr z, ProcessRecord_NoTrackName
	call FileIO_ReturnError
	cp hl, 0:i3
	jr ge, ProcessRecord_SearchTrackName

ProcessRecord_NoTrackName:
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda xwa, (0x025ec0:24)
	add xwa, xhl
	ld xbc, ProcessRecord_MatchLoop1_Str_Blank5
	jr ProcessRecord_CopyAndClose

ProcessRecord_SearchTrackName:
	lda xbc, (FileIO_EmptyNameKey:24)
	ld xwa, (xsp + 4)
	calr FileIO_SearchFile
	ld (xsp + 8), hl
	ld wa, (xsp + 10)
	extz xwa
	lda xiz, (0x025eb2:24)
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, xiz
	add xwa, xhl
	lda xwa, (xwa + 14)
	cpw (xsp + 8), 0x0
	jr nz, ProcessRecord_UseTrackName
	ld xbc, ProcessRecord_MatchLoop1_Str_Blank5
	jr ProcessRecord_CopyAndClose

ProcessRecord_UseTrackName:
	ld xbc, (xsp + 4)

ProcessRecord_CopyAndClose:
	calr FileIO_CopyString
	call FileIO_CloseHandle
	ld hl, 0:i3

ProcessRecord_Return:
	pop xiz
	inc 8, xsp
	ret

GetFileEntryByIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRange
	cp hl, 0:i3
	jr z, GetEntry_ComputeOffset
	lda xhl, (FileIO_EmptyEntryName:24)
	jr GetEntry_Return

GetEntry_ComputeOffset:
	ld wa, (0x0271ee:24)
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda xwa, (0x025ec0:24)
	add xwa, xhl
	lda xbc, (FileIO_EmptyNameKey:24)
	calr FileIO_SearchFile
	cp hl, 0:i3
	jr nz, FileEntry_ComputeOffset
	ld wa, iz
	calr ProcessFileRecord

FileEntry_ComputeOffset:
	ld wa, (0x0271ee:24)
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda xwa, (0x025ec0:24)
	add xwa, xhl
	ld xhl, xwa

GetEntry_Return:
	popw iz
	ret

FileIO_ByteBlock_DemoProc2:
	pushw	iz
	ld	iz, wa
	ld	wa, iz
	calr	ValidateFileRange
	cp	hl, 0:i3
	jr	z, GetFileEntryByIndex_Skip
	ldw	hl, 0xffff
	jr	GetFileEntryByIndex_Epilogue
GetFileEntryByIndex_Skip:
	ld	wa, iz
	extz	xwa
	ld	xbc, 82
	call	Math_MultiplyAccumulate
	lda	xwa, (0x25f02:24)
	add	xwa, xhl
	ldcfm	7, (xwa)
	scc8	c, l
	extz	hl
GetFileEntryByIndex_Epilogue:
	popw	iz
	ret
SLSrcBankList_FuncBody_Helper12:
	lda	xsp, (xsp-26)
	pushw	iz
	ld	(xsp+26), wa
	calr	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	lt, GetFileEntryByIndex_Skip2
	ld	a, l
	ldfr_berp a, 248
	extz	iz
	ld	wa, hl
	calr	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+16)
	ld	bc, iz
	calr	FileIO_FormatFileIndex
	lda	xbc, (xsp+16)
	lda	xwa, (xsp+2)
	ld	de, 1:i3
	calr	FileIO_ReadHeader
	lda	xwa, (xsp+2)
	ld	xbc, FileOp_StubAndDirNames
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, GetFileEntryByIndex_Skip3
GetFileEntryByIndex_Skip2:
	ld	xhl, FileIO_EmptyEntryName
	jr	GetFileEntryByIndex_Epilogue2
GetFileEntryByIndex_Skip3:
	ld	wa, (xsp+26)
	sll	wa, 4
	add	wa, 16
	extz	xwa
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	ld	xwa, 0x25bd2
	ld	xbc, 16
	call	FileIO_ReadBlock
	ld	(0x25be2:24), 0
	call	FileIO_CloseHandle
	lda	xhl, (0x25bd2:24)
GetFileEntryByIndex_Epilogue2:
	popw	iz
	lda	xsp, (xsp+26)
	ret
SLSrcBankList_FuncBody_Helper13:
	lda	xsp, (xsp-26)
	push	xiz
	ld	(xsp+28), wa
	calr	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	lt, GetFileEntryByIndex_Skip4
	ld	a, l
	ldfr_berp a, 248
	extz	iz
	ld	wa, hl
	calr	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+18)
	ld	bc, iz
	calr	FileIO_FormatFileIndex
	lda	xbc, (xsp+18)
	lda	xwa, (xsp+4)
	ld	de, 1:i3
	calr	FileIO_ReadHeader
	lda	xwa, (xsp+4)
	ld	xbc, FileIO_ByteBlock_DemoProc2_Str_rb
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, GetFileEntryByIndex_Skip5
GetFileEntryByIndex_Skip4:
	ld	xhl, FileIO_EmptyEntryName
	jr	GetFileEntryByIndex_Epilogue3
GetFileEntryByIndex_Skip5:
	ld	xwa, 13
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	call	FileIO_ReadByte
	ld	iz, hl
	call	FileIO_ReadByte
	sll	hl, 8
	or	iz, hl
	mul	xiz, (xsp+0x1c)
	ld	xwa, xiz
	add	xwa, 178
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	ld	xwa, 0x25be8
	ld	xbc, 16
	call	FileIO_ReadBlock
	ld	(0x25bf8:24), 0
	call	FileIO_CloseHandle
	lda	xhl, (0x25be8:24)
GetFileEntryByIndex_Epilogue3:
	pop	xiz
	lda	xsp, (xsp+26)
	ret
SingleLoadSrc_ReadSqtSongName:
	lda	xsp, (xsp-26)
	pushw	iz
	ld	(xsp+26), wa
	calr	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	lt, SingleLoadSrc_ReadSqtSongName_Skip6
	ld	a, l
	ldfr_berp a, 248
	extz	iz
	ld	wa, hl
	calr	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+16)
	ld	bc, iz
	calr	FileIO_FormatFileIndex
	lda	xbc, (xsp+16)
	lda	xwa, (xsp+2)
	ld	de, 2:i3
	calr	FileIO_ReadHeader
	lda	xwa, (xsp+2)
	ld	xbc, FileIO_ByteBlock_DemoProc2_Str_rb_2
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, SingleLoadSrc_ReadSqtSongName_Skip7
SingleLoadSrc_ReadSqtSongName_Skip6:
	ld	xhl, FileIO_EmptyEntryName
	jr	SingleLoadSrc_ReadSqtSongName_Epilogue4
SingleLoadSrc_ReadSqtSongName_Skip7:
	ld	wa, (xsp+26)
	sll	wa, 11
	add	wa, 256
	extz	xwa
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	ld	xwa, 0x25bfe
	ld	xbc, 16
	call	FileIO_ReadBlock
	ld	(0x25c0e:24), 0
	call	FileIO_CloseHandle
	lda	xhl, (0x25bfe:24)
SingleLoadSrc_ReadSqtSongName_Epilogue4:
	popw	iz
	lda	xsp, (xsp+26)
	ret
SLSrcBankList_FuncBody_Helper15:
	lda	xsp, (xsp-28)
	pushw	iz
	ld	(xsp+26), bc
	ld	(xsp+28), wa
	calr	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	lt, GetFileEntryByIndex_Skip8
	ld	a, l
	ldfr_berp a, 248
	extz	iz
	ld	wa, hl
	calr	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+16)
	ld	bc, iz
	calr	FileIO_FormatFileIndex
	lda	xbc, (xsp+16)
	lda	xwa, (xsp+2)
	ld	de, 3:i3
	calr	FileIO_ReadHeader
	lda	xwa, (xsp+2)
	ld	xbc, FileIO_ByteBlock_DemoProc2_Str_rb_3
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, GetFileEntryByIndex_Skip9
GetFileEntryByIndex_Skip8:
	ld	xhl, FileIO_EmptyEntryName
	jr	GetFileEntryByIndex_Epilogue5
GetFileEntryByIndex_Skip9:
	ld	wa, (xsp+28)
	sll	wa, 2
	add	wa, (xsp+0x1a)
	mul	wa, 96
	add	wa, 160
	extz	xwa
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	ld	xwa, 0x25c14
	ld	xbc, 13
	call	FileIO_ReadBlock
	ld	(0x25c21:24), 0
	call	FileIO_CloseHandle
	lda	xhl, (0x25c14:24)
GetFileEntryByIndex_Epilogue5:
	popw	iz
	lda	xsp, (xsp+28)
	ret
SLSrcBankList_FuncBody_Helper16:
	lda	xsp, (xsp-26)
	pushw	iz
	ld	(xsp+26), wa
	calr	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	lt, GetFileEntryByIndex_Entry
	ld	a, l
	ldfr_berp a, 248
	extz	iz
	ld	wa, hl
	calr	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+16)
	ld	bc, iz
	calr	FileIO_FormatFileIndex
	lda	xbc, (xsp+16)
	lda	xwa, (xsp+2)
	ld	de, 4:i3
	calr	FileIO_ReadHeader
	lda	xwa, (xsp+2)
	ld	xbc, FileIO_ByteBlock_DemoProc2_Str_rb_4
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, GetFileEntryByIndex_Skip10
GetFileEntryByIndex_Entry:
	.byte 0x43
	.long FileIO_EmptyEntryName
	jr	GetFileEntryByIndex_Epilogue6
GetFileEntryByIndex_Skip10:
	ld	wa, (xsp+26)
	mul	wa, 470
	add	wa, 16
	extz	xwa
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	ld	xwa, 0x25c2a
	ld	xbc, 16
	call	FileIO_ReadBlock
	ld	(0x25c3a:24), 0
	call	FileIO_CloseHandle
	lda	xhl, (0x25c2a:24)
GetFileEntryByIndex_Epilogue6:
	popw	iz
	lda	xsp, (xsp+26)
	ret
SLSrcBankList_FuncBody_Helper17:
	lda	xsp, (xsp-24)
	pushw	iz
	calr	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	lt, GetFileEntryByIndex_Entry2
	ld	a, l
	ldfr_berp a, 248
	extz	iz
	ld	wa, hl
	calr	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+16)
	ld	bc, iz
	calr	FileIO_FormatFileIndex
	lda	xbc, (xsp+16)
	lda	xwa, (xsp+2)
	ld	de, 4:i3
	calr	FileIO_ReadHeader
	lda	xwa, (xsp+2)
	ld	xbc, GetFileEntryByIndex_Entry_Str_rb
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, GetFileEntryByIndex_Skip11
GetFileEntryByIndex_Entry2:
	.byte 0x43
	.long FileIO_EmptyEntryName
	jr	GetFileEntryByIndex_Epilogue7
GetFileEntryByIndex_Skip11:
	ld	xwa, 0x4980
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	ld	xwa, 0x25c40
	ld	xbc, 16
	call	FileIO_ReadBlock
	ld	(0x25c50:24), 0
	call	FileIO_CloseHandle
	lda	xhl, (0x25c40:24)
GetFileEntryByIndex_Epilogue7:
	popw	iz
	lda	xsp, (xsp+24)
	ret
SLSrcBankList_FuncBody_Helper18:
	lda	xsp, (xsp-26)
	pushw	iz
	ld	(xsp+26), wa
	calr	GetCurrentFileIndex
	cp	hl, 0:i3
	jr	lt, GetFileEntryByIndex_Skip12
	ld	a, l
	ldfr_berp a, 248
	extz	iz
	ld	wa, hl
	calr	GetFileEntryPtr
	ld	xde, xhl
	lda	xwa, (xsp+16)
	ld	bc, iz
	calr	FileIO_FormatFileIndex
	lda	xbc, (xsp+16)
	lda	xwa, (xsp+2)
	ld	de, 4:i3
	calr	FileIO_ReadHeader
	lda	xwa, (xsp+2)
	ld	xbc, GetFileEntryByIndex_Entry2_Str_rb
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	ge, GetFileEntryByIndex_Skip13
GetFileEntryByIndex_Skip12:
	ld	xhl, FileIO_EmptyEntryName
	jr	GetFileEntryByIndex_Epilogue8
GetFileEntryByIndex_Skip13:
	ld	(0x25c56:24), 32
	ld	wa, (xsp+26)
	mul	wa, 80
	add	wa, 0x4aa7
	extz	xwa
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	lda	xwa, (0x25c57:24)
	ld	xbc, 13
	call	FileIO_ReadBlock
	ld	(0x25c64:24), 0
	call	FileIO_CloseHandle
	lda	xhl, (0x25c56:24)
GetFileEntryByIndex_Epilogue8:
	popw	iz
	lda	xsp, (xsp+26)
	ret

ValidateFileRangeType5:
	cp (0x025db6:24), 0x05
	jr nz, ValidateRange_OutOfRange
	cp wa, 0:i3
	jr lt, ValidateRange_OutOfRange
	cp wa, (0x271ec:24)
	jr le, ValidateRange_CheckPage

ValidateRange_OutOfRange:
	ldw hl, 0xffff
	ret

ValidateRange_CheckPage:
	ld bc, (0x0271ee:24)
	cp wa, bc
	jr lt, ValidateRange_NeedPageChange
	cp wa, (0x271f0:24)
	jr le, ValidateRange_CheckEmpty

ValidateRange_NeedPageChange:
	ld hl, 1:i3
	ret

ValidateRange_CheckEmpty:
	sub wa, bc
	muls wa, 0x52
	lda xbc, (0x025ec0:24)
	cp	(xbc+wa), 0x00
	jr nz, ValidateRange_IsValid
	ld hl, 2:i3
	ret

ValidateRange_IsValid:
	ld hl, 0:i3
	ret

GetCurrentFileIndexAlt:
	ld wa, (0x0271ea:24)
	calr ValidateFileRangeType5
	cp hl, 0:i3
	jr z, GetCurrentIndex_Return
	ldw hl, 0xff98
	ret

GetCurrentIndex_Return:
	ld hl, (0x0271ea:24)
	ret

BuildPageRecords:
	lda xsp, (xsp-274)
	pushw iz
	lda xbc, (0x025eb2:24)
	ld xwa, xbc
	lda xde, (xbc+4920)

BuildRecords_CopyLoop:
	ld xiy, FileIO_DirListEntryTemplate
	ld xix, xwa
	ldw bc, 0x29
	ldirw
	lda xwa, (xwa + 82)
	cp xwa, xde
	jr c, BuildRecords_CopyLoop
	ld iz, 0:i3
	lda xbc, (xsp + 10)
	ld xwa, BuildRecords_CopyLoop_Str_Star
	call _findfirst
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr lt, BuildRecords_Return
	lda xwa, (xsp + 16)
	ld (xsp + 6), xwa
	ld wa, (0x0271ee:24)
	cp wa, 0:i3
	jr gt, BuildRecords_SearchDone
	cpw (0x271f0:24), 0
	jr lt, BuildRecords_SearchDone
	neg wa
	muls wa, 0x52
	lda xbc, (0x025ec0:24)
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

BuildRecords_SearchDone:
	ld iz, 1:i3
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cp hl, 0:i3
	jr nz, BuildRecords_Cleanup

BuildRecords_UpdateLoop:
	ld wa, (0x0271ee:24)
	cp iz, wa
	jr lt, BuildRecords_UpdateNext
	cp iz, (0x271f0:24)
	jr gt, BuildRecords_UpdateNext
	ld bc, iz
	sub bc, wa
	muls bc, 0x52
	ld wa, bc
	lda xbc, (0x025ec0:24)
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

BuildRecords_UpdateNext:
	inc 1, iz
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cp hl, 0:i3
	jr z, BuildRecords_UpdateLoop

BuildRecords_Cleanup:
	ld xwa, (xsp + 2)
	call _findclose

BuildRecords_Return:
	ld hl, iz
	popw iz
	lda xsp, (xsp+274)
	ret

SetCurrentFileIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRangeType5
	cp hl, 0xffff
	jr nz, SetIndex_InvalidWrap
	ld hl, (0x0271ea:24)
	jr SetIndex_Return

SetIndex_InvalidWrap:
	cp hl, 1:i3
	jr nz, SetIndex_StoreIndex
	ld wa, iz
	extz xwa
	div wa, 0x3c
	mul wa, 0x3c
	ld bc, wa
	ld (0x0271ee:24), bc
	add bc, 0x3b
	ld wa, (0x0271ec:24)
	cp bc, wa
	jr ge, SetIndex_UpdatePageEnd
	ld wa, bc

SetIndex_UpdatePageEnd:
	ld (0x0271f0:24), wa
	calr BuildPageRecords

SetIndex_StoreIndex:
	ld hl, iz
	ld (0x0271ea:24), hl

SetIndex_Return:
	popw iz
	ret

GetFileRecordPtr:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRangeType5
	cp hl, 0:i3
	jr z, GetRecordPtr_ComputeOffset
	lda xhl, (FileIO_EmptyEntryName:24)
	jr GetRecordPtrAlt_Return

GetRecordPtr_ComputeOffset:
	ld wa, (0x0271ee:24)
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda xwa, (0x025ec0:24)
	add xwa, xhl
	ld xhl, xwa

GetRecordPtrAlt_Return:
	popw iz
	ret

BuildPageRecordsAlt:
	ldw (0x0271ee:24), 0x0000
	ldw (0x0271f0:24), 0x003b
	calr BuildPageRecords
	ld wa, 0:i3
	cp hl, 0:i3
	jr le, BuildRecordsAlt_StoreCount
	ld wa, hl
	dec 1, wa

BuildRecordsAlt_StoreCount:
	ld (0x0271ec:24), wa
	cp (0x271f0:24), wa
	ret le
	ld (0x0271f0:24), wa
	ret

TrimAndFormatFilename:
	lda xsp, (xsp - 128)
	push xiz
	ld xiz, xbc
	ld	(xiz+wa), 0x00
	ld ix, 0:i3
	cp wa, 0:i3
	jr le, TrimFormat_TrimTrailing

TrimFormat_ScanLoop:
	lda	xhl, (xiz+ix)
	ld c, (xhl)
	cp c, 0x20
	jr nc, TrimFormat_CheckSeparator
	ld (xhl), 0x20

TrimFormat_ScanNext:
	inc 1, ix
	cp ix, wa
	jr lt, TrimFormat_ScanLoop

TrimFormat_TrimTrailing:
	sub ix, 0x1
	jr lt, TrimFormat_CheckLeading

TrimFormat_TrimLoop:
	lda	xwa, (xiz+ix)
	cp (xwa), 0x20
	jr nz, TrimFormat_CheckLeading
	ld (xwa), 0x0
	sub ix, 0x1
	jr ge, TrimFormat_TrimLoop

TrimFormat_CheckLeading:
	cp (xiz), 0x20
	jr nz, TrimFormat_Done
	lda xwa, (xsp + 4)
	ld xbc, xiz
	calr FileIO_CopyString
	ld ix, 0:i3
	lda xwa, (xsp + 4)
	jr TrimFormat_SkipLoop

TrimFormat_CheckSeparator:
	cp c, e
	jr nz, TrimFormat_ScanNext
	ld (xhl), 0x0
	jr TrimFormat_TrimTrailing

TrimFormat_SkipSpaces:
	inc 1, ix

TrimFormat_SkipLoop:
	lda	xbc, (xwa+ix)
	cp (xbc), 0x20
	jr z, TrimFormat_SkipSpaces
	ld xwa, xiz
	calr FileIO_CopyString

TrimFormat_Done:
	ld hl, 0:i3
	pop xiz
	lda xsp, (xsp+128:16)
	ret

DetectFileType:
	ld l, (0x025db6:24)
	cp l, 6:i3
	jr z, DetectType_KnownType
	cp l, 7:i3
	jr nz, DetectType_TryOpen

DetectType_KnownType:
	extz hl
	ret

DetectType_TryOpen:
	cp l, 2:i3
	jrl nz, DetectType_NotFound
	ld xwa, DetectType_TryOpen_Str_MUSIC_DIR
	ld xbc, DetectType_TryOpen_Str_rb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr lt, DetectType_TryExtended
	ld (0x025db6:24), 0x06
	ld xwa, 0x10
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	lda xwa, (0x025d74:24)
	ld xbc, 0x40
	call FileIO_ReadBlock
	ld xwa, 0x60
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	ld xwa, 0x27200
	ld xbc, 0x3c
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	lda xbc, (0x025d74:24)
	ldw wa, 0x40
	ld de, 0:i3

DetectType_TrimAndReturn:
	calr TrimAndFormatFilename
	ld l, (0x025db6:24)
	extz hl
	ret

DetectType_TryExtended:
	ld xwa, DetectType_TryExtended_Str_PIANODIR_FIL
	ld xbc, DetectType_TryExtended_Str_rb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr lt, DetectType_NotFound
	ld (0x025db6:24), 0x07
	ld xwa, 0x12d8
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	lda xwa, (0x025d74:24)
	ld xbc, 0x38
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	lda xbc, (0x025d74:24)
	ldw wa, 0x38
	ld de, 0:i3
	jr DetectType_TrimAndReturn

DetectType_NotFound:
	ldw hl, 0xffff
	ret

ValidateFileRangeAlt:
	ld c, (0x025db6:24)
	cp c, 6:i3
	jr z, ValidateRangeAlt_CheckType
	cp c, 7:i3
	jr nz, ValidateRangeAlt_OutOfRange

ValidateRangeAlt_CheckType:
	cp wa, 0:i3
	jr lt, ValidateRangeAlt_OutOfRange
	cp wa, (0x271ec:24)
	jr le, ValidateRangeAlt_CheckPage

ValidateRangeAlt_OutOfRange:
	ldw hl, 0xffff
	ret

ValidateRangeAlt_CheckPage:
	ld bc, (0x0271ee:24)
	cp wa, bc
	jr lt, ValidateRangeAlt_NeedPageChange
	cp wa, (0x271f0:24)
	jr le, ValidateRangeAlt_CheckEmpty

ValidateRangeAlt_NeedPageChange:
	ld hl, 1:i3
	ret

ValidateRangeAlt_CheckEmpty:
	sub wa, bc
	muls wa, 0x52
	lda xbc, (0x025eb2:24)
	cp	(xbc+wa), 0x00
	jr nz, ValidateRangeAlt_IsValid
	ld hl, 2:i3
	ret

ValidateRangeAlt_IsValid:
	ld hl, 0:i3
	ret

FileIO_GetCurrentFileIndex_Alt:
	ld wa, (0x0271ea:24)
	calr ValidateFileRangeAlt
	cp hl, 0:i3
	jr z, GetCurrentFileAlt_ReturnIndex
	ldw hl, 0xff98
	ret

GetCurrentFileAlt_ReturnIndex:
	ld hl, (0x0271ea:24)
	ret

FileIO_BuildFileExtName:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	lda xwa, (xsp + 4)
	ld (xwa+), 0x2e
	ld (xiz + 12), 0x0
	lda xbc, (xiz + 8)
	calr FileIO_CopyString
	lda xwa, (xiz + 8)
	lda xbc, (xsp + 4)
	calr FileIO_CopyString
	pop xiz
	inc 8, xsp
	ret

FileIO_InitDirScan:
	lda xsp, (xsp - 16)
	push xiz
	lda xbc, (0x025eb2:24)
	ld xwa, xbc
	lda xde, (xbc+4920)

InitDirScan_CopyLoop:
	ld xiy, FileIO_DirListEntryTemplate
	ld xix, xwa
	ldw bc, 0x29
	ldirw
	lda xwa, (xwa + 82)
	cp xwa, xde
	jr c, InitDirScan_CopyLoop
	ldiw_erp 0xfa, 0
	cp (0x025db6:24), 0x06
	jrl nz, DirScan_AltMediaPath
	ld xwa, InitDirScan_CopyLoop_Str_MUSIC_DIR
	ld xbc, InitDirScan_CopyLoop_Str_rb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr lt, DirScan_ReturnResult
	ld xwa, 0x51
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	call FileIO_ReadByte
	ldfr_werp HL, 0xfa
	ld iz, (0x0271ee:24)
	cp iz, (0x271f0:24)
	jr gt, FileIO_DirScanDone

DirScan_ProcessEntry:
	lda xwa, (0x027200:24)
	ld	a, (xwa+iz)
	exts wa
	mul wa, 0x30
	add wa, 0xa0
	exts xwa
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	ld wa, iz
	sub wa, (0x271ee:24)
	muls wa, 0x52
	lda xbc, (0x025eb2:24)
	exts xwa
	add xwa, xbc
	ld xbc, 0xb
	call FileIO_ReadBlock
	ld wa, iz
	sub wa, (0x271ee:24)
	muls wa, 0x52
	lda xbc, (0x025eb2:24)
	exts xwa
	add xwa, xbc
	calr FileIO_BuildFileExtName
	inc 1, iz
	cp iz, (0x271f0:24)
	jr le, DirScan_ProcessEntry

FileIO_DirScanDone:
	call FileIO_CloseHandle

DirScan_ReturnResult:
	ldto_werp HL, 0xfa
	pop xiz
	lda xsp, (xsp + 16)
	ret

DirScan_AltMediaPath:
	ld xwa, DirScan_AltMediaPath_Str_PIANODIR_FIL
	ld xbc, DirScan_AltMediaPath_Str_rb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr lt, DirScan_ReturnResult
	ld xwa, 0x10
	ld bc, 0:i3

DirScan_AltReadLoop:
	call FileIO_SeekAndReadBlock
	lda xwa, (xsp + 4)
	ld xbc, 0xb
	call FileIO_ReadBlock
	call FileIO_ReturnError
	cp hl, 0:i3
	jr lt, FileIO_DirScanDone
	lda xbc, (xsp + 4)
	cp (xbc), 0x20
	jr lt, FileIO_DirScanDone
	ld de, (0x0271ee:24)
	ldto_werp WA, 0xfa
	cp wa, de
	jr lt, DirScan_AltNextEntry
	ldto_werp WA, 0xfa
	cp wa, (0x271f0:24)
	jr gt, DirScan_AltNextEntry
	ldto_werp WA, 0xfa
	sub wa, de
	muls wa, 0x52
	lda xde, (0x025eb2:24)
	exts xwa
	add xwa, xde
	ldw de, 0xb
	calr FileIO_CopyString_WriteNull
	ldto_werp WA, 0xfa
	sub wa, (0x271ee:24)
	muls wa, 0x52
	lda xbc, (0x025eb2:24)
	exts xwa
	add xwa, xbc
	calr FileIO_BuildFileExtName

DirScan_AltNextEntry:
	inc1w_erp 0xfa
	ld xwa, 0x45
	ld bc, 1:i3
	jr DirScan_AltReadLoop

FileIO_SelectFileByIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRangeAlt
	cp hl, 0xffff
	jr nz, SelectFile_CheckPageBound
	ld hl, (0x0271ea:24)
	jr SelectFile_Return

SelectFile_CheckPageBound:
	cp hl, 1:i3
	jr nz, SelectFile_StoreIndex
	ld wa, iz
	extz xwa
	div wa, 0x3c
	mul wa, 0x3c
	ld bc, wa
	ld (0x0271ee:24), bc
	add bc, 0x3b
	ld wa, (0x0271ec:24)
	cp bc, wa
	jr ge, SelectFile_ClampEnd
	ld wa, bc

SelectFile_ClampEnd:
	ld (0x0271f0:24), wa
	calr FileIO_InitDirScan

SelectFile_StoreIndex:
	ld hl, iz
	ld (0x0271ea:24), hl

SelectFile_Return:
	popw iz
	ret

FileIO_GetFileEntryByIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRangeAlt
	cp hl, 0:i3
	jr z, GetFileEntry_ComputeOffset
	lda xhl, (FileIO_EmptyEntryName:24)
	jr GetFileEntry_Return

GetFileEntry_ComputeOffset:
	ld wa, (0x0271ee:24)
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25eb2
	add xwa, xhl
	ld xhl, xwa

GetFileEntry_Return:
	popw iz
	ret

FileIO_InitFileNavigation:
	ldw (0x0271ee:24), 0x0000
	ldw (0x0271f0:24), 0x003b
	calr FileIO_InitDirScan
	ld wa, 0:i3
	cp hl, 0:i3
	jr le, InitFileNav_ClampEnd
	ld wa, hl
	dec 1, wa

InitFileNav_ClampEnd:
	ld (0x0271ec:24), wa
	cp (0x271f0:24), wa
	ret le
	ld (0x0271f0:24), wa
	ret

FileIO_RefreshFileNames:
	push xiz
	cp (0x025db6:24), 0x06
	jrl nz, RefreshNames_AltMediaPath
	ld xwa, FileIO_RefreshFileNames_Str_NAME_MDA
	ld xbc, FileIO_RefreshFileNames_Str_rb
	call FileIO_OpenWithMode
	ld wa, (0x0271ee:24)
	ld iz, wa
	cp hl, 0:i3
	jr ge, RefreshNames_CheckEnd
	cp wa, (0x271f0:24)
	jrl gt, FileIO_ScanComplete_Return

RefreshNames_FallbackLoop:
	ld wa, iz
	sub wa, (0x271ee:24)
	muls wa, 0x52
	lda xbc, (0x025eb2:24)
	lda	xbc, (xbc+wa)
	lda xwa, (xbc + 14)
	calr FileIO_CopyString
	inc 1, iz
	cp iz, (0x271f0:24)
	jr le, RefreshNames_FallbackLoop
	jrl FileIO_ScanComplete_Return

RefreshNames_CheckEnd:
	cp wa, (0x271f0:24)
	jrl gt, FileIO_ScanDone

RefreshNames_ReadLoop:
	lda xwa, (0x027200:24)
	ld	a, (xwa+iz)
	exts wa
	mul wa, 0x30
	add wa, 0xa0
	ldfr_werp WA, 0xfa
	exts xwa
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	ld wa, iz
	sub wa, (0x271ee:24)
	muls wa, 0x52
	ld bc, wa
	lda xwa, (0x025ec0:24)
	lda	xwa, (xwa+bc)
	ld xbc, 0x30
	call FileIO_ReadBlock
	ld wa, iz
	sub wa, (0x271ee:24)
	muls wa, 0x52
	ld bc, wa
	lda xwa, (0x025ec0:24)
	exts xbc
	add xbc, xwa
	ldw wa, 0x30
	ldw de, 0x40
	calr TrimAndFormatFilename
	cp hl, 0:i3
	jr ge, RefreshNames_NextEntry
	ld wa, iz
	sub wa, (0x271ee:24)
	muls wa, 0x52
	lda xbc, (0x025eb2:24)
	lda	xbc, (xbc+wa)
	lda xwa, (xbc + 14)
	calr FileIO_CopyString

RefreshNames_NextEntry:
	inc 1, iz
	cp iz, (0x271f0:24)
	jrl le, RefreshNames_ReadLoop
	jrl FileIO_ScanDone

RefreshNames_AltMediaPath:
	ld xwa, RefreshNames_AltMediaPath_Str_PIANODIR_FIL
	ld xbc, RefreshNames_AltMediaPath_Str_rb
	call FileIO_OpenWithMode
	ld wa, (0x0271ee:24)
	cp hl, 0:i3
	jr ge, RefreshNames_AltOpenSuccess
	ld iz, wa
	cp wa, (0x271f0:24)
	jrl gt, FileIO_ScanComplete_Return

RefreshNames_AltFallbackLoop:
	ld wa, iz
	sub wa, (0x271ee:24)
	muls wa, 0x52
	lda xbc, (0x025eb2:24)
	lda	xbc, (xbc+wa)
	lda xwa, (xbc + 14)
	calr FileIO_CopyString
	inc 1, iz
	cp iz, (0x271f0:24)
	jr le, RefreshNames_AltFallbackLoop
	jrl FileIO_ScanComplete_Return

RefreshNames_AltOpenSuccess:
	ldi_erpw 0xfa, 0x40, 0x00
	ld iz, wa
	cp wa, (0x271f0:24)
	jr gt, FileIO_ScanDone

RefreshNames_AltReadLoop:
	ldto_werp WA, 0xfa
	exts xwa
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	ld wa, iz
	sub wa, (0x271ee:24)
	muls wa, 0x52
	ld bc, wa
	lda xwa, (0x025ec0:24)
	lda	xwa, (xwa+bc)
	ld xbc, 0x10
	call FileIO_ReadBlock
	ld wa, iz
	sub wa, (0x271ee:24)
	muls wa, 0x52
	ld bc, wa
	lda xwa, (0x025ec0:24)
	exts xbc
	add xbc, xwa
	ldw wa, 0x10
	ld de, 0:i3
	calr TrimAndFormatFilename
	cp hl, 0:i3
	jr ge, RefreshNames_AltNextEntry
	ld wa, iz
	sub wa, (0x271ee:24)
	muls wa, 0x52
	lda xbc, (0x025eb2:24)
	lda	xbc, (xbc+wa)
	lda xwa, (xbc + 14)
	calr FileIO_CopyString

RefreshNames_AltNextEntry:
	add_erpw 0xfa, 0x50, 0x00
	inc 1, iz
	cp iz, (0x271f0:24)
	jr le, RefreshNames_AltReadLoop

FileIO_ScanDone:
	call FileIO_CloseHandle

FileIO_ScanComplete_Return:
	ld hl, 0:i3
	pop xiz
	ret

FileIO_GetFileEntryWithRefresh:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRangeAlt
	cp hl, 0:i3
	jr z, GetEntryRefresh_ComputeOffset
	lda xhl, (FileIO_EmptyEntryName:24)
	jr GetEntryRefresh_Return

GetEntryRefresh_ComputeOffset:
	ld wa, (0x0271ee:24)
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda xwa, (0x025ec0:24)
	add xwa, xhl
	cp (xwa), 0x0
	call z, (FileIO_RefreshFileNames:24)
	ld wa, (0x0271ee:24)
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda xwa, (0x025ec0:24)
	add xwa, xhl
	ld xhl, xwa

GetEntryRefresh_Return:
	popw iz
	ret

FileIO_CheckMediaIsWritable:
	call GetMediaType
	cp l, 2:i3
	jr z, CheckMediaWritable_Ok
	cp l, 3:i3
	jr z, CheckMediaWritable_Ok
	ldw hl, 0xffff
	ret

CheckMediaWritable_Ok:
	ld hl, 0:i3
	ret

FileIO_OpenWithBuiltPath:
	lda xsp, (xsp-144)
	push xiz
	ld	(xsp+144), xbc
	ld xiz, xwa
	lda xwa, (xsp + 4)
	ld xbc, 0x272d2
	calr FileIO_CopyString
	lda xwa, (xsp + 4)
	ld xbc, 0x272f2
	calr FileIO_BuildFilePath
	lda xwa, (xsp + 4)
	ld xbc, xiz
	calr FileIO_BuildFilePath
	lda xwa, (xsp + 4)
	ld	xbc, (xsp+144)
	call FileIO_OpenWithMode
	pop xiz
	lda xsp, (xsp+144:16)
	ret

FileIO_BuildFileIndex:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ld (0x027412:24), 0x00
	ld (0x027414:24), 0x00
	ld iz, 0:i3

BuildIndex_ScanLoop:
	ld xwa, (xsp + 4)
	lda	xwa, (xwa+iz)
	ld xbc, BuildIndex_ScanLoop_Str_Star_Star_Star
	ld de, 3:i3
	calr FileIO_Search_SkipEntry
	cp hl, 0:i3
	jr z, BuildIndex_Return
	ldiw_erp 0xfa, 0
	jr BuildIndex_CheckComma

BuildIndex_CheckSubEntry:
	ld c, (0x027412:24)
	exts bc
	sla bc, 5
	addw_erp BC, 0xfa
	lda xhl, (0x027312:24)
	ld	(xhl+bc), e
	ld xbc, BuildIndex_CheckSubEntry_Str_Star_Star_Star
	ld de, 3:i3
	calr FileIO_Search_SkipEntry
	cp hl, 0:i3
	jr z, FileIO_StoreIndexedEntry
	inc1w_erp 0xfa
	inc 1, iz

BuildIndex_CheckComma:
	ld xwa, (xsp + 4)
	lda	xwa, (xwa+iz)
	ld e, (xwa)
	cp e, 0x2c
	jr z, FileIO_StoreIndexedEntry
	cp e, 0:i3
	jr z, FileIO_StoreIndexedEntry
	cp_erpw 0xfa, 0x20, 0x00
	jr lt, BuildIndex_CheckSubEntry

FileIO_StoreIndexedEntry:
	ld a, (0x027412:24)
	exts wa
	sla wa, 5
	addw_erp WA, 0xfa
	lda xbc, (0x027312:24)
	ld	(xbc+wa), 0x00
	inc 1, (0x27412:24)
	inc 1, iz
	cp iz, 0x80
	jrl lt, BuildIndex_ScanLoop

BuildIndex_Return:
	pop xiz
	inc 4, xsp
	ret

FileIO_FindPathSeparator:
	ld xde, xwa
	ld hl, 0:i3
	lda xbc, (0x0272d2:24)
	jr FindPathSep_CheckChar

FindPathSep_NextChar:
	ld (xbc+), a
	inc 1, hl
	inc 1, xde

FindPathSep_CheckChar:
	ld a, (xde)
	cp a, 0x5c
	jr z, FindPathSep_Found
	cp hl, 0x1f
	jr lt, FindPathSep_NextChar

FindPathSep_Found:
	ld (xbc), 0x5c
	ret

ControlState_ProcessCommand:
	push xiz
	ld xiz, xwa
	ld xwa, 0xffffffff
	ld (0x027416:24), xwa
	ld (0x027414:24), 0x00
	cp (xiz), 0x2
	jr nz, CtrlCmd_Return
	ld e, (xiz + 1)
	lda xbc, (0x0272f2:24)
	lda xwa, (xiz + 2)
	cp e, 0x80
	jr z, ControlState_ProcessNext
	cp e, 0x40
	jr z, ControlState_ProcessNext
	cp e, 0x10
	jr z, CtrlCmd_SetPathAndBuild
	cp e, 0:i3
	jr nz, CtrlCmd_Return
	ld (0x0272d2:24), 0x00
	ld (xbc), 0x0
	jr ControlState_ProcessNext

CtrlCmd_SetPathAndBuild:
	ld (xbc), 0x0
	calr FileIO_FindPathSeparator
	inc 3, hl
	lda	xwa, (xiz+hl)

ControlState_ProcessNext:
	calr FileIO_BuildFileIndex

CtrlCmd_Return:
	pop xiz
	ret

FileIO_FindFirstMatch:
	lda xsp, (xsp-276)
	push xiz
	ld	(xsp+272), xbc
	ld	(xsp+276), xwa
	ld XWA, (xsp + 0x0114)
	ld (xwa), 0x0
	ld XWA, (xsp + 0x0110)
	ld xbc, 0:i3
	ld (xwa), xbc
	ld a, (0x027414:24)
	exts wa
	ld (xsp + 4), wa
	ld a, (0x027412:24)
	exts wa
	cp (xsp + 4), wa
	jrl ge, FindFirst_NotFound

FindFirst_BuildPathLoop:
	ld xwa, 0x25c6c
	ld xbc, FindFirst_BuildPathLoop_Str_A
	calr FileIO_CopyString
	ld xwa, 0x25c6c
	ld xbc, 0x272d2
	calr FileIO_BuildFilePath
	ld xwa, 0x25c6c
	ld xbc, 0x272f2
	calr FileIO_BuildFilePath
	ld wa, (xsp + 4)
	sla wa, 5
	lda xbc, (0x027312:24)
	lda	xbc, (xbc+wa)
	ld xwa, 0x25c6c
	calr FileIO_BuildFilePath
	lda xbc, (xsp + 6)
	ld xwa, 0x25c6c
	call _findfirst
	ld xiz, xhl
	cp xiz, 0x0
	jr lt, FindFirst_NextIndex
	lda xbc, (xsp + 12)
	ld XWA, (xsp + 0x0114)
	calr FileIO_CopyString
	lda xbc, (xsp + 6)
	bitm 4, (xbc)
	jr z, FindFirst_StoreFileSize
	ld XWA, (xsp + 0x0110)
	ld xbc, 0xffffffff
	ld (xwa), xbc
	jr FindFirst_StoreResult

FindFirst_StoreFileSize:
	ld XWA, (xsp + 0x0110)
	ld xbc, (xbc + 2)
	ld (xwa), xbc

FindFirst_StoreResult:
	ld (0x027416:24), xiz
	ld wa, (xsp + 4)
	ld (0x027414:24), a
	ld hl, 0:i3
	jr FindFirst_Return

FindFirst_NextIndex:
	incw 1, (xsp + 4)
	ld a, (0x027412:24)
	exts wa
	cp (xsp + 4), wa
	jrl lt, FindFirst_BuildPathLoop

FindFirst_NotFound:
	ld xwa, 0xffffffff
	ld (0x027416:24), xwa
	ldw hl, 0xffff

FindFirst_Return:
	pop xiz
	lda xsp, (xsp+276)
	ret

FileIO_FindNextMatch:
	lda xsp, (xsp-270)
	push xiz
	ld	(xsp+270), xbc
	ld xiz, xwa
	ld xwa, (0x027416:24)
	lda xbc, (xsp + 4)
	call _findnext
	cp hl, 0:i3
	jr z, FindNext_CopyName
	ld (xiz), 0x0
	ld XWA, (xsp + 0x010e)
	ld xbc, 0:i3
	ld (xwa), xbc
	ld xwa, (0x027416:24)
	call _findclose
	ld xwa, 0xffffffff
	ld (0x027416:24), xwa
	ldw hl, 0xffff
	jr FindNext_Return

FindNext_CopyName:
	lda xbc, (xsp + 10)
	ld xwa, xiz
	calr FileIO_CopyString
	lda xbc, (xsp + 4)
	bitm 4, (xbc)
	jr z, FindNext_StoreFileSize
	ld XWA, (xsp + 0x010e)
	ld xbc, 0xffffffff
	ld (xwa), xbc
	jr FindNext_Ok

FindNext_StoreFileSize:
	ld XWA, (xsp + 0x010e)
	ld xbc, (xbc + 2)
	ld (xwa), xbc

FindNext_Ok:
	ld hl, 0:i3

FindNext_Return:
	pop xiz
	lda xsp, (xsp+270)
	ret

FileIO_SearchStringMatch:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	ldw hl, 0xffff
	ld xwa, (0x027416:24)
	cp xwa, 0x0
	jr ge, SearchMatch_HasHandle
	ld xwa, xiz
	ld xbc, (xsp + 4)
	jr SearchMatch_FirstSearch

SearchMatch_HasHandle:
	ld a, (0x027414:24)
	cp a, (0x27412:24)
	jr ge, SearchMatch_Return
	ld xwa, xiz
	ld xbc, (xsp + 4)
	calr FileIO_FindNextMatch
	cp hl, 0:i3
	jr ge, SearchMatch_Return
	inc 1, (0x27414:24)
	ld xwa, xiz
	ld xbc, (xsp + 4)

SearchMatch_FirstSearch:
	calr FileIO_FindFirstMatch

SearchMatch_Return:
	pop xiz
	inc 4, xsp
	ret

FileIO_ExtractBasename:
	lda xhl, (0x025cec:24)
	ld (xhl), 0x0
	ld xwa, (0x027416:24)
	cp xwa, 0x0
	ret lt
	ld c, (0x027412:24)
	cp c, 0:i3
	ret le
	ld a, (0x027414:24)
	cp a, c
	ret ge
	exts wa
	sla wa, 5
	lda xbc, (0x027312:24)
	lda	xbc, (xbc+wa)
	ldw de, 0xffff
	ld ix, 0:i3
	cp (xbc), 0x0
	jr z, ExtractBase_TruncatePath

ExtractBase_ScanLoop:
	ld	a, (xbc+ix)
	ld	(xhl+ix), a
	cp a, 0x5c
	jr nz, ExtractBase_TrackSep
	ld de, ix

ExtractBase_TrackSep:
	inc 1, ix
	cp	(xbc+ix), 0x00
	jr nz, ExtractBase_ScanLoop

ExtractBase_TruncatePath:
	cp de, 0:i3
	jr le, ExtractBase_ClearAll
	inc 1, de
	ld	(xhl+de), 0x00
	jr ExtractBase_Done

ExtractBase_ClearAll:
	ld (xhl), 0x0

ExtractBase_Done:
	ret

FileIO_NormalizePath:
	cp (xwa), 0x5c
	scc16 z, de
	lda	xbc, (xwa+de)
	ld xwa, 0x272f2
	calr FileIO_CopyString
	ld de, 0:i3
	lda xbc, (0x0272f2:24)
	jr NormalizePath_CheckLoop

NormalizePath_NextChar:
	inc 1, de

NormalizePath_CheckLoop:
	lda	xwa, (xbc+de)
	cp (xwa), 0x0
	jr nz, NormalizePath_NextChar
	cp de, 0x20
	ret ge
	cp de, 0:i3
	ret le
	dec 1, de
	cp	(xbc+de), 0x5c
	ret z
	ld (xwa), 0x5c
	ret

FileIO_ValidateModeAndRange:
	ld c, (0x025db6:24)
	cp c, 2:i3
	jr z, ValidateMode_CheckRange
	cp c, 3:i3
	jr z, ValidateMode_CheckRange
	cp c, 4:i3
	jr nz, ValidateMode_Error

ValidateMode_CheckRange:
	cp wa, 0:i3
	jr lt, ValidateMode_Error
	cp wa, (0x272ca:24)
	jr le, ValidateMode_InRange

ValidateMode_Error:
	ldw hl, 0xffff
	ret

ValidateMode_InRange:
	ld bc, (0x0271ee:24)
	cp wa, bc
	jr lt, ValidateMode_OutOfPage
	cp wa, (0x271f0:24)
	jr le, ValidateMode_InPage

ValidateMode_OutOfPage:
	ld hl, 1:i3
	ret

ValidateMode_InPage:
	sub wa, bc
	muls wa, 0xe
	lda xbc, (0x02723c:24)
	cp	(xbc+wa), 0x00
	jr nz, ValidateMode_Valid
	ld hl, 2:i3
	ret

ValidateMode_Valid:
	ld hl, 0:i3
	ret

FileIO_GetCurrentWallpaperIndex:
	ld wa, (0x0272c8:24)
	calr FileIO_ValidateModeAndRange
	cp hl, 0:i3
	jr z, GetWallpaper_ReturnIndex
	ldw hl, 0xff98
	ret

GetWallpaper_ReturnIndex:
	ld hl, (0x0272c8:24)
	ret

FileIO_ScanDirEntries:
	lda xsp, (xsp-274)
	pushw iz
	lda xbc, (0x02723c:24)
	ld xwa, xbc
	lda xde, (xbc+140:16)

ScanDir_CopyEntryLoop:
	ld xiy, FileIO_ScanDir_EmptyNameSlot
	ld xix, xwa
	ld bc, 7:i3
	ldirw
	lda xwa, (xwa + 14)
	cp xwa, xde
	jr c, ScanDir_CopyEntryLoop
	ld iz, 0:i3
	lda xbc, (xsp + 10)
	ld xwa, ScanDir_CopyEntryLoop_Str_BMP
	call _findfirst
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr lt, ScanDir_Return
	lda xwa, (xsp + 16)
	ld (xsp + 6), xwa
	ld wa, (0x0271ee:24)
	cp wa, 0:i3
	jr gt, ScanDir_FirstEntryDone
	cpw (0x271f0:24), 0
	jr lt, ScanDir_FirstEntryDone
	neg wa
	muls wa, 0xe
	lda xbc, (0x02723c:24)
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

ScanDir_FirstEntryDone:
	ld iz, 1:i3
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cp hl, 0:i3
	jr nz, ScanDir_CloseFindHandle

ScanDir_NextEntryCheck:
	ld wa, (0x0271ee:24)
	cp iz, wa
	jr lt, ScanDir_IterateNext
	cp iz, (0x271f0:24)
	jr gt, ScanDir_IterateNext
	ld bc, iz
	sub bc, wa
	muls bc, 0xe
	ld wa, bc
	lda xbc, (0x02723c:24)
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

ScanDir_IterateNext:
	inc 1, iz
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cp hl, 0:i3
	jr z, ScanDir_NextEntryCheck

ScanDir_CloseFindHandle:
	ld xwa, (xsp + 2)
	call _findclose

ScanDir_Return:
	ld hl, iz
	popw iz
	lda xsp, (xsp+274)
	ret

FileIO_SelectWallpaperByIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr FileIO_ValidateModeAndRange
	cp hl, 0xffff
	jr nz, SelectWP_CheckPageBound
	ld hl, (0x0272c8:24)
	jr SelectWP_Return

SelectWP_CheckPageBound:
	cp hl, 1:i3
	jr nz, SelectWP_StoreIndex
	ld wa, iz
	extz xwa
	div wa, 0xa
	mul wa, 0xa
	ld bc, wa
	ld (0x0271ee:24), bc
	add bc, 0x9
	ld wa, (0x0272ca:24)
	cp bc, wa
	jr ge, SelectWP_ClampEnd
	ld wa, bc

SelectWP_ClampEnd:
	ld (0x0271f0:24), wa
	calr FileIO_ScanDirEntries

SelectWP_StoreIndex:
	ld hl, iz
	ld (0x0272c8:24), hl

SelectWP_Return:
	popw iz
	ret

FileIO_GetWallpaperEntry:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr FileIO_ValidateModeAndRange
	cp hl, 0:i3
	jr z, GetWPEntry_ComputeOffset
	lda xhl, (FileIO_EmptyEntryName:24)
	jr GetWPEntry_Return

GetWPEntry_ComputeOffset:
	ld wa, (0x0271ee:24)
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	ld xhl, 0x2723c
	add xhl, xbc

GetWPEntry_Return:
	popw iz
	ret

FileIO_InitWallpaperNav:
	ldw (0x0271ee:24), 0x0000
	ldw (0x0271f0:24), 0x0009
	calr FileIO_ScanDirEntries
	ld wa, 0:i3
	cp hl, 0:i3
	jr le, InitWPNav_ClampEnd
	ld wa, hl
	dec 1, wa

InitWPNav_ClampEnd:
	ld (0x0272ca:24), wa
	cp (0x271f0:24), wa
	ret le
	ld (0x0271f0:24), wa
	ret

ResetProgressIndication:
	ldw (0x8500:16), 0xffff
	ldw (0x8502:16), 0xffff
	ldw (0x8504:16), 0xffff
	ldw (0x8506:16), 0xffff
	ldw (0x8508:16), 0xffff
	ldw (0x850a:16), 0xffff
	call FileIO_InitRecordTable
	ld xiy, FmmPassword_StateInit
	ld xix, 0x8a0c
	ldiw
	ret

FileIO_DiskInserted:
	ld (MEDLEY_PLAY_FLAG:16), 0
	calr ResetProgressIndication
	jp FileIO_ValidateRecord_Return

FileIO_DiskInserted_Stub1:
	ret

FileIO_DiskInserted_Stub2:
	ret

FileIO_DiskRemoved:
	ld (MEDLEY_PLAY_FLAG:16), 0
	calr ResetProgressIndication
	call FileIO_ValidateRecord_Return
	call Xapr_GetPresentFlag
	cp l, 0:i3
	ret nz
	ld xwa, 0x600002
	ld xbc, EVT_SET_VISIBLE
	ld xde, 0:i3
	call ApPostEvent
	ret

InitializeOperationState:
	dec 2, xsp
	ld (xsp), a
	call SeqBuf_Init
	call NoteMap_SendAllNotesOff
	call Part_ReinitAllActive
	call AccWrap_PlayModeDispatch
	cp (xsp), 0x0
	jr z, InitOp_SkipSetFlag
	set 2, (0x28a7:16)

InitOp_SkipSetFlag:
	call AccompSeq_StopSequence
	call AudioInit_RefreshToneBank
	call NoteMap_ProcessAndMerge
	call Voice_InitializeAll
	call Voice_InitTablePair
	call Voice_InitTableGroup
	call MIDI_SendAllSoundOff
	call MidiThru_Enable
	inc 2, xsp
	ret

CancelOperationCleanup:
	ld a, (0x28a7:16)
	bit 2, a
	jr z, CancelOp_ClearSeq
	res 2, a
	ld (0x28a7:16), a

CancelOp_ClearSeq:
	res 3, (0x28a7:16)
	call SeqAcc_InitPlaybackState
	jp MidiThru_Disable

SignalProgressUpdate:
	call CPanel_InitButtonState_SaveRegs
	jp RefreshSwEvent

SeqPhase_OperationStateCheck:
	pushw iz
	ld a, (1068:16)
	bit 7, a
	jrl z, SeqPhase_PopIzRet
	res 7, a
	ld (1068:16), a
	bit 2, (1056:16)
	jrl nz, SeqPhase_PopIzRet
	bit 2, (1055:16)
	jrl nz, SeqPhase_PopIzRet
	ld wa, 0:i3
	calr InitializeOperationState
	cpw (0x8500:16), 0
	jr ge, SeqPhase_CheckMediaType
	call GetDiskSizeInfo
	extz hl
	ld (0x8500:16), hl
	calr SignalProgressUpdate

SeqPhase_CheckMediaType:
	ld wa, (0x8500:16)
	cp wa, 2:i3
	jr z, SeqPhase_MediaIsValid
	cp wa, 3:i3
	jr z, SeqPhase_MediaIsValid
	calr ResetProgressIndication
	jrl SeqPhase_PopIzRet

SeqPhase_MediaIsValid:
	cpw (0x8502:16), 0
	jr ge, SeqPhase_CheckEncodedData
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	calr SignalProgressUpdate

SeqPhase_CheckEncodedData:
	cpw (0x8502:16), 0
	jr z, SeqPhase_PopIzRet
	ld a, (1068:16)
	res 7, a
	ldfr_berp A, 0xf8
	extz iz
	cp iz, 0x13
	jr gt, SeqPhase_PopIzRet
	ld wa, iz
	call NotifyUIOfSelectionChange
	call CheckFileSystemStatus
	cp hl, 0:i3
	jr z, SeqPhase_PopIzRet
	ld iz, 0:i3

SeqPhase_FormatNameLoop:
	ldto_berp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, SeqPhase_FormatNameLoop
	ld (GLOBAL_ERROR_CODE:16), 37
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	call FileIO_ParseDirectoryEntry
	ld iz, hl
	call SwbtWr_ReinitOutputBank
	calr SignalProgressUpdate
	calr CancelOperationCleanup
	cp iz, 0:i3
	jr ge, SeqPhase_LoadSuccess
	ld (GLOBAL_ERROR_CODE:16), 1
	jr SeqPhase_SendSoundCmd

SeqPhase_LoadSuccess:
	ld (GLOBAL_ERROR_CODE:16), 35

SeqPhase_SendSoundCmd:
	ldw wa, 0xee
	call SoundCtrl_SendCommand

SeqPhase_PopIzRet:
	popw iz
	ret

FileIO_MidiOutSendByte:
	dec 2, xsp
	ld (xsp), a
	ld xwa, 0x2280
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jr z, MidiOutSend_Return
	ld (1060:16), 243
	ei 6
	pushw 0xf3
	call SeqBuf_MidiOut_WriteByte
	ld a, (xsp + 2)
	res 7, a
	extz wa
	pushw wa
	call SeqBuf_MidiOut_WriteByte
	inc 4, xsp
	call MIDI_SC0_TX_DISPATCH
	ei 0

MidiOutSend_Return:
	inc 2, xsp
	ret

FileIO_DiskEventDispatch:
	dec 4, xsp
	ld (xsp), c
	ld (xsp + 2), a
	cpw (0x8500:16), 0
	jr ge, DiskEvt_CheckMediaType
	call GetDiskSizeInfo
	extz hl
	ld (0x8500:16), hl

DiskEvt_CheckMediaType:
	ld wa, (0x8500:16)
	cp wa, 1:i3
	jr z, DiskEvt_TypeIsCard
	cp wa, 0:i3
	jr z, DiskEvt_TypeIsNone
	cp wa, 5:i3
	jr z, DiskEvt_TypeIsUSB
	cp wa, 2:i3
	jr z, DiskEvt_TypeIsFloppyOrHD
	cp wa, 3:i3
	jr nz, DiskEvt_Return

DiskEvt_TypeIsFloppyOrHD:
	bit 0, (0x340f4:24)
	jr z, DiskEvt_UseAltChannel
	ld a, (xsp)
	extz wa
	jr DiskEvt_PostModeEvent

DiskEvt_UseAltChannel:
	ld a, (xsp + 2)
	extz wa
	jr DiskEvt_PostModeEvent

DiskEvt_TypeIsUSB:
	ld (GLOBAL_ERROR_CODE:16), 0
	ldw wa, 0xee
	jr DiskEvt_SendSoundCmd

DiskEvt_TypeIsNone:
	ldw wa, 0x7d

DiskEvt_PostModeEvent:
	call UI_PostModeChangeEvent
	jr DiskEvt_Return

DiskEvt_TypeIsCard:
	calr ResetProgressIndication
	ld (GLOBAL_ERROR_CODE:16), 2
	ldw wa, 0xee

DiskEvt_SendSoundCmd:
	call SoundCtrl_SendCommand

DiskEvt_Return:
	inc 4, xsp
	ret

FileIO_DetectFileTypeAndPost:
	cpw (0x8500:16), 0
	jr ge, DetectType_CheckMediaType
	call GetDiskSizeInfo
	extz hl
	ld (0x8500:16), hl

DetectType_CheckMediaType:
	ld wa, (0x8500:16)
	cp wa, 1:i3
	jr z, DetectType_IsCardReset
	cp wa, 0:i3
	jr z, DetectType_IsNone
	cp wa, 5:i3
	jr z, DetectType_IsPdFormat
	cp wa, 2:i3
	jr z, DetectType_TypeIsFloppy
	cp wa, 3:i3
	ret nz
	ldw wa, 0x6c
	jr UI_PostEventCommon

DetectType_TypeIsFloppy:
	call DetectFileType
	cp hl, 0:i3
	jr ge, DetectType_IsDocFormat
	ldw wa, 0x6c
	jr UI_PostEventCommon

DetectType_IsDocFormat:
	ldw wa, 0x6d
	jr UI_PostEventCommon

DetectType_IsPdFormat:
	ldw wa, 0x6e
	jr UI_PostEventCommon

DetectType_IsNone:
	ldw wa, 0x7d

UI_PostEventCommon:
	jp UI_PostModeChangeEvent

DetectType_IsCardReset:
	calr ResetProgressIndication
	ld (GLOBAL_ERROR_CODE:16), 2
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	ret

FileIO_GetDiskCapacity:
	dec 2, xsp
	ld (xsp), a
	cpw (0x8500:16), 0
	jr ge, DiskCap_CheckMediaType
	call GetDiskSizeInfo
	extz hl
	ld (0x8500:16), hl

DiskCap_CheckMediaType:
	ld wa, (0x8500:16)
	cp wa, 3:i3
	jr z, DiskCap_TypeIsFloppyOrHD
	cp wa, 2:i3
	jr z, DiskCap_TypeIsFloppyOrHD
	cp wa, 1:i3
	jr z, DiskCap_TypeIsCardReset
	cp wa, 0:i3
	jr z, DiskCap_TypeIsNone
	cp wa, 5:i3
	jr nz, DiskCap_Return
	ld (GLOBAL_ERROR_CODE:16), 0
	ldw wa, 0xee
	jr DiskCap_SendSoundCmd

DiskCap_TypeIsNone:
	ldw wa, 0x7d
	jr DiskCap_PostModeEvent

DiskCap_TypeIsCardReset:
	calr ResetProgressIndication
	ld (GLOBAL_ERROR_CODE:16), 2
	ldw wa, 0xee

DiskCap_SendSoundCmd:
	call SoundCtrl_SendCommand
	jr DiskCap_Return

DiskCap_TypeIsFloppyOrHD:
	ld a, (xsp)
	extz wa

DiskCap_PostModeEvent:
	call UI_PostModeChangeEvent

DiskCap_Return:
	inc 2, xsp
	ret

FileIO_ValidateSignedValue:
	cp wa, 0:i3
	jr ge, ValidateSigned_Positive
	ld de, wa
	res 15, de
	cp de, 0xff
	jr ge, ValidateSigned_LookupTable
	ld l, a
	ret

ValidateSigned_LookupTable:
	ld iy, 0:i3
	lda xix, (FileIO_StatusToErrorCode:24)
	ld de, 0:i3
	jr ValidateSigned_ScanLoop

ValidateSigned_NextEntry:
	inc 1, iy
	inc 4, de

ValidateSigned_ScanLoop:
	lda	xhl, (xix+de)
	cp wa, (xhl)
	jr z, ValidateSigned_FoundMatch
	cpw (xhl), 0x0
	jr lt, ValidateSigned_NextEntry

ValidateSigned_FoundMatch:
	ld l, (xhl + 2)
	cp l, 0xff
	ret c
	ld l, c
	ret

ValidateSigned_Positive:
	ld l, 0x23:opc
	ret

FileIO_ErrorCodeByteBlock:
	call	Boot_CheckConfigFlag7
	cp	hl, 0:i3
	ret	z
	cp	(SWBTWR_PAYLOAD_1:16), 65
	ret	nz
	bit	0, (SWBTWR_PAYLOAD_3:16)
	ret	z
	ld	c, (CURRENT_TITLE:16)
	cp	c, 16
	jr	c, FileIO_ErrorCodeByteBlock_Entry
	cp	c, 22
	ret	ule
FileIO_ErrorCodeByteBlock_Entry:
	bit	0, (SWBTWR_PAYLOAD_2:16)
	jr	z, FileIO_ErrorCodeByteBlock_Skip4
	cp	(CURRENT_MODE:16), 6
	jr	nz, FileIO_ErrorCodeByteBlock_Skip
	cp	c, 96
	jr	z, FileIO_ErrorCodeByteBlock_Loop
	cp	c, 126
	jr	z, FileIO_ErrorCodeByteBlock_Loop
	ldw	wa, 96
	jr	FileIO_ErrorCodeByteBlock_Join
FileIO_ErrorCodeByteBlock_Skip:
	cp	c, 188
	jr	z, FileIO_ErrorCodeByteBlock_Skip2
	cp	c, 97
	jr	z, FileIO_ErrorCodeByteBlock_Skip2
	cp	c, 100
	jr	nz, FileIO_ErrorCodeByteBlock_Skip3
FileIO_ErrorCodeByteBlock_Skip2:
	ldw	wa, 96
	jr	FileIO_ErrorCodeByteBlock_Join
FileIO_ErrorCodeByteBlock_Skip3:
	cp	c, 98
	jr	nz, FileIO_ErrorCodeByteBlock_Skip11
	ldw	wa, 176
	jr	FileIO_ErrorCodeByteBlock_Join
FileIO_ErrorCodeByteBlock_Skip11:
	cp	c, 99
	jr	nz, FileIO_ErrorCodeByteBlock_Loop
	ldw	wa, 72
FileIO_ErrorCodeByteBlock_Join:
	call	UI_PostModeChangeEvent
FileIO_ErrorCodeByteBlock_Loop:
	calr	ResetProgressIndication
	ret
FileIO_ErrorCodeByteBlock_Skip4:
	ld	a, (0x340f2:24)
	cp	(CURRENT_MODE:16), 1
	jr	nz, FileIO_ErrorCodeByteBlock_Skip12
	bit	2, (0x420:16)
	ret	nz
	bit	2, (0x41f:16)
	ret	nz
	ld	c, a
	cp	a, 0:i3
	ret	z
	cp	c, 5:i3
	ret	nc
	ld	wa, 6:i3
	call	UI_PostPartChangeEvent
	ld	a, (0x340f2:24)
	extz	wa
	lda	xbc, (FileIO_ErrorCodeByteBlock_Entry_Data:24)
	ld	a, (xbc+wa)
	cp a, 119
	jr	z, FileIO_ErrorCodeByteBlock_Skip5
	cp	a, 108
	jr	z, FileIO_ErrorCodeByteBlock_Loop2
	cp	a, 97
	ret	nz
	ldw	wa, 97
	ldw	bc, 0x0064
	jr	FileIO_ErrorCodeByteBlock_Join3
FileIO_ErrorCodeByteBlock_Loop2:
	jrl	FileIO_DetectFileTypeAndPost
FileIO_ErrorCodeByteBlock_Skip5:
	extz	wa
	jr	FileIO_ErrorCodeByteBlock_Join2
FileIO_ErrorCodeByteBlock_Skip12:
	cp	c, 96
	jr	z, FileIO_ErrorCodeByteBlock_Skip6
	cp	c, 126
	jr	nz, FileIO_ErrorCodeByteBlock_Skip8
FileIO_ErrorCodeByteBlock_Skip6:
	ld	c, a
	cp	a, 0:i3
	ret	z
	cp	c, 5:i3
	ret	nc
	ld	a, c
	extz	wa
	lda	xbc, (FileIO_ErrorCodeByteBlock_Entry_Data:24)
	ld	a, (xbc+wa)
	cp a, 119
	jr	z, FileIO_ErrorCodeByteBlock_Skip7
	cp	a, 108
	jr	z, FileIO_ErrorCodeByteBlock_Loop2
	cp	a, 97
	ret	nz
	ldw	wa, 97
	ldw	bc, 100
FileIO_ErrorCodeByteBlock_Join3:
	jrl	FileIO_DiskEventDispatch
FileIO_ErrorCodeByteBlock_Skip7:
	extz	wa
FileIO_ErrorCodeByteBlock_Join2:
	jp	UI_PostModeChangeEvent
FileIO_ErrorCodeByteBlock_Skip8:
	call	FDemo_MultiGuardCheck
	cp	hl, 0:i3
	ret	z
	cpw	(0x8500:16), 0
	jr	ge, FileIO_ErrorCodeByteBlock_Skip9
	call	GetDiskSizeInfo
	extz	hl
	ld	(0x8500:16), hl
FileIO_ErrorCodeByteBlock_Skip9:
	ld	wa, (0x8500:16)
	cp	wa, 1:i3
	jrl	z, FileIO_ErrorCodeByteBlock_Loop
	cp	wa, 0:i3
	jrl	z, FileIO_ErrorCodeByteBlock_Loop
	cp	wa, 5:i3
	ret	z
	cp	wa, 3:i3
	jr	z, FileIO_ErrorCodeByteBlock_Skip10
	cp	wa, 2:i3
	ret	nz
FileIO_ErrorCodeByteBlock_Skip10:
	ld	xwa, FileIO_ErrorCodeByteBlock_Entry_Str_FEATURE_PRE
	call	FileIO_CheckFileExists
	cp	l, 0:i3
	ret	z
	jp	FDemo_LoadRegsAndPostEvent

FileIO_MedleyDispatchByMode:
	ld a, (CURRENT_TITLE:16)
	cp a, 0x79
	jr nz, MedleyDisp_ModeSmf
	ld xwa, 0:i3
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0xd
	jrl FmmIntMedleyFunc

MedleyDisp_ModeSmf:
	cp a, 0x6c
	jr nz, MedleyDisp_ModeDoc
	ld xwa, 0:i3
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0xd
	jrl FmmSmfMedleyFunc

MedleyDisp_ModeDoc:
	cp a, 0x6d
	jr nz, MedleyDisp_ModePd
	ld xwa, 0:i3
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0xd
	jp FmmDocMedleyFunc

MedleyDisp_ModePd:
	cp a, 0x6e
	jr nz, MedleyDisp_ModeDisk
	ld xwa, 0:i3
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0xd
	jrl FmmPdMedleyFunc

MedleyDisp_ModeDisk:
	cp a, 0x77
	ret nz
	ld xwa, 0:i3
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0xd
	calr FmmDiskMedleySelectFunc
	ret

NumToAscii_FormatNumber:
	push xiz
	ld ix, 0:i3
	cp c, 0x10
	jr ule, NumToAscii_ClampMin
	ld c, 0x10:opc
	jr NumToAscii_PadLeading

NumToAscii_ClampMin:
	cp c, 5:i3
	jr ule, NumToAscii_StartDigits

NumToAscii_PadLeading:
	lda xde, (0x7f4a:16)

NumToAscii_PadLoop:
	ld hl, ix
	inc 1, ix
	extz xhl
	add xhl, xde
	ld (xhl), 0x20
	dec 1, c
	cp c, 5:i3
	jr ugt, NumToAscii_PadLoop

NumToAscii_StartDigits:
	ld hl, ix
	cp wa, 0x2710
	jr c, NumToAscii_NoTenThousands
	ld iy, wa
	extz xiy
	div iy, 0x2710
	ld iz, ix
	inc 1, ix
	lda xde, (0x7f4a:16)
	extz xiz
	add xiz, xde
	ldto_berp E, 0xf4
	add e, 0x30
	ld (xiz), e
	mul iy, 0x2710
	sub wa, iy
	jr NumToAscii_ThousandsDigit

NumToAscii_NoTenThousands:
	cp c, 5:i3
	jr c, NumToAscii_ThousandsDigit
	ld hl, ix
	inc 1, ix
	lda xde, (0x7f4a:16)
	extz xhl
	add xhl, xde
	ld (xhl), 0x20
	ld hl, ix

NumToAscii_ThousandsDigit:
	cp wa, 0x3e8
	jr c, NumToAscii_NoThousands
	ld iy, wa
	extz xiy
	div iy, 0x3e8
	ld iz, ix
	inc 1, ix
	lda xde, (0x7f4a:16)
	extz xiz
	add xiz, xde
	ldto_berp E, 0xf4
	add e, 0x30
	ld (xiz), e
	mul iy, 0x3e8
	sub wa, iy
	jr NumToAscii_HundredsDigit

NumToAscii_NoThousands:
	cp ix, hl
	jr z, NumToAscii_PadThousands
	ld iy, ix
	inc 1, ix
	lda xde, (0x7f4a:16)
	extz xiy
	add xiy, xde
	ld (xiy), 0x30
	jr NumToAscii_HundredsDigit

NumToAscii_PadThousands:
	cp c, 4:i3
	jr c, NumToAscii_HundredsDigit
	ld hl, ix
	inc 1, ix
	lda xde, (0x7f4a:16)
	extz xhl
	add xhl, xde
	ld (xhl), 0x20
	ld hl, ix

NumToAscii_HundredsDigit:
	cp wa, 0x64
	jr c, NumToAscii_NoHundreds
	ld iy, wa
	extz xiy
	div iy, 0x64
	ld iz, ix
	inc 1, ix
	lda xde, (0x7f4a:16)
	extz xiz
	add xiz, xde
	ldto_berp E, 0xf4
	add e, 0x30
	ld (xiz), e
	mul iy, 0x64
	sub wa, iy
	jr NumToAscii_TensDigit

NumToAscii_NoHundreds:
	cp ix, hl
	jr z, NumToAscii_PadHundreds
	ld iy, ix
	inc 1, ix
	lda xde, (0x7f4a:16)
	extz xiy
	add xiy, xde
	ld (xiy), 0x30
	jr NumToAscii_TensDigit

NumToAscii_PadHundreds:
	cp c, 3:i3
	jr c, NumToAscii_TensDigit
	ld hl, ix
	inc 1, ix
	lda xde, (0x7f4a:16)
	extz xhl
	add xhl, xde
	ld (xhl), 0x20
	ld hl, ix

NumToAscii_TensDigit:
	cp wa, 0xa
	jr c, NumToAscii_NoTens
	ld iy, wa
	extz xiy
	div iy, 0xa
	ld de, ix
	inc 1, ix
	lda xbc, (0x7f4a:16)
	extz xde
	add xde, xbc
	ldto_berp C, 0xf4
	add c, 0x30
	ld (xde), c
	mul iy, 0xa
	sub wa, iy
	jr NumToAscii_OnesDigitAndFinish

NumToAscii_NoTens:
	lda xde, (0x7f4a:16)
	cp ix, hl
	jr z, NumToAscii_PadTens
	ld bc, ix
	inc 1, ix
	extz xbc
	add xbc, xde
	ld (xbc), 0x30
	jr NumToAscii_OnesDigitAndFinish

NumToAscii_PadTens:
	cp c, 2:i3
	jr c, NumToAscii_OnesDigitAndFinish
	ld bc, ix
	inc 1, ix
	extz xbc
	add xbc, xde
	ld (xbc), 0x20

NumToAscii_OnesDigitAndFinish:
	ld bc, ix
	inc 1, ix
	lda xhl, (0x7f4a:16)
	extz xbc
	add xbc, xhl
	add a, 0x30
	ld (xbc), a
	ld wa, ix
	extz xwa
	add xwa, xhl
	ld (xwa), 0x0
	pop xiz
	ret


; File I/O and Disk Operations routines (split into file_io/ subdirectory)
	.include "file_io/title_handlers.s"
