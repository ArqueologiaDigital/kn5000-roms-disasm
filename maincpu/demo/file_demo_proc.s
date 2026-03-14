; =============================================================================
; File Demo Procedures
; =============================================================================
;
; File demo procedures and title handlers. Manages demo file
; playback, title display, and demo mode UI integration.
; =============================================================================

FDemo_DisplayResourceData:
	.byte 0xf3, 0xfd, 0xdc, 0xfe, 0x37, 0x3e, 0xe8, 0x8e
	.byte 0xbf, 0x06, 0x02, 0x00, 0x00, 0xf3, 0xfd, 0x08
	.byte 0x01, 0x31, 0xe9, 0x88, 0xb9, 0x20, 0x31, 0xf5
	.byte 0xe0, 0x00, 0x20, 0xe9, 0xf0, 0x67, 0xf8, 0x3e
	.byte 0x1d, 0xa0, 0x0f, 0xff, 0x2b, 0x3e, 0xf3, 0xfd
	.byte 0x12, 0x01, 0x30, 0x38, 0x1d, 0xf3, 0x0c, 0xff
	lda	xwa, (xsp+278)
	.byte 0xb8, 0x08, 0x00
	.long Data_DiskFuncPtrTbl_EA0B00
	.byte 0x0b, 0x70, 0x00, 0x38
	.byte 0x1d, 0xc1, 0x0d, 0xff, 0xbf, 0x16, 0x37, 0xf3
	.byte 0xfd, 0x08, 0x01, 0x30, 0x41, 0x76, 0x00, 0xea
	.byte 0x00, 0x1d, 0xc7, 0x8b, 0xf8, 0xbf, 0x04, 0x53
	.byte 0x9f, 0x04, 0x3f, 0x00, 0x00, 0x71, 0xbb, 0x00
	.byte 0x1e, 0xc2, 0x00, 0xbf, 0x08, 0x30, 0x41, 0x00
	.byte 0x01, 0x00, 0x00, 0x1d, 0x74, 0x8d, 0xf8, 0xeb
	.byte 0xe3, 0x66, 0x1f, 0x40, 0x00, 0x01, 0x00, 0x00
	.byte 0x1e, 0xb5, 0x00, 0xbf, 0x08, 0x31, 0x89, 0x04
	.byte 0x21, 0xd8, 0x12, 0xbf, 0x06, 0x50, 0x0b, 0x00
	.byte 0x01, 0x39, 0x3b, 0x1d, 0x99, 0x0d, 0xff, 0xbf
	.byte 0x0a, 0x37, 0xde, 0xa9, 0xbf, 0x08, 0x30, 0x41
	.byte 0x00, 0x01, 0x00, 0x00, 0x1d, 0x74, 0x8d, 0xf8
	.byte 0xeb, 0xe3, 0x66, 0x17, 0x40, 0x00, 0x01, 0x00
	.byte 0x00, 0x1e, 0x84, 0x00, 0x0b, 0x00, 0x01, 0xbf
	.byte 0x0a, 0x30, 0x38, 0x3b, 0x1d, 0x99, 0x0d, 0xff
	.byte 0xbf, 0x0a, 0x37, 0xde, 0x61, 0xde, 0xcf, 0x08
	.byte 0x00, 0x61, 0xd1, 0x9f, 0x06, 0x3f, 0x01, 0x00
	.byte 0x6e, 0x16, 0xde, 0xa8, 0xbf, 0x08, 0x30, 0x41
	.byte 0x00, 0x01, 0x00, 0x00, 0x1d, 0x74, 0x8d, 0xf8
	.byte 0xde, 0x61, 0xde, 0xcf, 0x48, 0x00, 0x61, 0xec
	.byte 0xbf, 0x08, 0x30, 0x41, 0x00, 0x01, 0x00, 0x00
	.byte 0x1d, 0x74, 0x8d, 0xf8, 0xeb, 0xe3, 0x66, 0x27
	.byte 0x40, 0x00, 0x01, 0x00, 0x00, 0x1e, 0x38, 0x00
	.byte 0x0b, 0x00, 0x01, 0xbf, 0x0a, 0x30, 0x38, 0x3b
	.byte 0x1d, 0x99, 0x0d, 0xff, 0xbf, 0x0a, 0x37, 0xbf
	.byte 0x08, 0x30, 0x41, 0x00, 0x01, 0x00, 0x00, 0x1d
	.byte 0x74, 0x8d, 0xf8, 0xeb, 0xe3, 0x6e, 0xd9, 0x1d
	.byte 0x48, 0x8c, 0xf8, 0x9f, 0x04, 0x23, 0x5e, 0xf3
	.byte 0xfd, 0x24, 0x01, 0x37, 0x0e, 0xf2, 0x00, 0xb0
	.byte 0x0a, 0x30, 0xf2, 0x7e, 0x5b, 0x02, 0x60, 0x0e
	.byte 0xf2, 0x00, 0xb0, 0x0a, 0x33, 0xf2, 0x00, 0xd8
	.byte 0x0f, 0x31, 0xeb, 0xa1, 0xe9, 0x8c, 0xe2, 0x7e
	.byte 0x5b, 0x02, 0x22, 0xea, 0x89, 0xeb, 0xa1, 0xe8
	.byte 0x81, 0xec, 0xf1, 0x6f, 0x0b, 0xea, 0x8b, 0xe8
	.byte 0x82, 0xf2, 0x7e, 0x5b, 0x02, 0x62, 0x68, 0x02
	.byte 0xeb, 0xa8, 0x0e

MainPreControl:
	sub xbc, 0x1E10003
	cp xbc, 0x0
	jr lt, MainPreControl_ReturnNull
	cp xbc, 0xA
	jr gt, MainPreControl_ReturnNull
	add xbc, xbc
	add xbc, 0xEA007A
	ld bc, (xbc)
	lda_24 xix, 0xf86625
	jp_dri 8, 0x07, 0xF0, 0xE4
; MainPreControl dispatch (11-entry, table 0xEA007A)
MainPreControl_Dispatch:
	sti16_24	0x0251D8, 0

MainPreControl_ReturnNull:
	lds32 xhl, 0
	ret

FDemo_DisplayCtrlJumpHandler:
	; --- Display control jump table handler stubs ---
	; Three stubs call display resource loaders (F86360/F864A0/F863E4),
	; convert result, set up event codes, then dispatch via FA9D58.
	; Also handles display state queries on (0x0251D8).
	ld xwa, xde				; workspace
	calr LABEL_F86360			; load display resource (format validation)
	exts xhl				; sign-extend result
	ld xwa, 0xFFFFFFFF			; broadcast target
	ld xbc, 0x01C10001			; event code
	ld xde, xhl				; result as param
	jr FDemo_DispatchEventPost				; dispatch
	ld xwa, xde				; workspace
	calr FDemo_DisplayResourceData			; load alternate display resource
	exts xhl
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C10003			; event code 3
	ld xde, xhl
	jr FDemo_DispatchEventPost
	ld xwa, xde				; workspace
	calr LABEL_F863E4			; load named display resource
	exts xhl
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C10002			; event code 2
	ld xde, xhl
FDemo_DispatchEventPost:
	call ApPostEvent				; dispatch event
	jr MainPreControl_ReturnNull		; return null
	stdi8	10404, 19
	call Demo_SelectEntry_ProcessSongList			; additional handler
	jr MainPreControl_ReturnNull
	.byte 0xd2, 0xd8, 0x51, 0x02, 0x3f, 0x00, 0x00	; cp (0x0251D8), 0x0000  [16-bit direct]
	jr z, MainPreControl_Dispatch			; if zero, clear state
	call Part_InitFromPreset			; process display state
	jr MainPreControl_Dispatch
	ld16_24	hl, 152024
	exts xhl
	ret


ApPreControl:
	push xiz
	ld xiz, xde
	ld xwa, xbc
	cp xbc, 0x1E0003A
	jrl z, Seq_GetControlBlock
	cp xbc, 0x1E1000B
	jrl z, Seq_ReadStartFlag
	cp xbc, 0x1E1000D
	jrl z, Seq_PostMelodyEventAlt
	ld de, iz
	cp xbc, 0x1C00006
	jrl z, FDemo_ProcessDisplayStateQuery
	cp xbc, 0x1E10007
	jr z, Seq_StartWithFullInit
	cp xbc, 0x1E1000C
	jr z, Seq_PostMelodyEvent
	sub xwa, 0x1C10001
	cp xwa, 0x0
	jr lt, ApPreControl_ReturnNull
	cp xwa, 0x6
	jr gt, ApPreControl_ReturnNull
	add xwa, xwa
	add xwa, 0xEA0090
	ld wa, (xwa)
	lda_24 xix, 0xf866f9
	jp_dri 8, 0x07, 0xF0, 0xE0

Seq_PostMelodyEvent:
	ld xwa, 0x1410000
	ld xde, xiz

Seq_DispatchMainFunc:
	call MainFuncCall

ApPreControl_ReturnNull:
	lds32 xhl, 0
	jrl ApPreControl_Exit

Seq_StartWithFullInit:
	ld xwa, xiz
	calr Seq_InitializeAndStart
	jr ApPreControl_ReturnNull
	st16_24 0x025b7c, xde
	cps de, 0
	jr lt, ApPreControl_ReturnNull
	ld32_24 xwa, 0x0248c4
	lds bc, 0
	calr FDemoText_ProcessTextMarkup
	jr ApPreControl_ReturnNull
	st16_24 0x025b7c, xde
	cps de, 0
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
	ld xwa, 0x1410000
	ld xbc, 0x1E10004
	ld xde, xiz
	call MainFuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
	ld xde, xiz
	jr Seq_DispatchMainFunc
	st16_24 0x025b7c, xde
	cps de, 0
	jr lt, ApPreControl_ReturnNull
	ld xwa, 0x1410000
	ld xbc, 0x1E10006
	lds32 xde, 0
	jrl Seq_DispatchMainFunc
	ld xwa, 0xEE0016
	ld xbc, 0x1C00002
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call PostEvent
	ld wa, iz
	calr LABEL_F862B5
	lds wa, 2
	calr FDemoText_ProcessMarkupLoop
	jrl ApPreControl_ReturnNull

FDemo_ProcessDisplayStateQuery:
	cps de, 0
	jrl lt, ApPreControl_ReturnNull
	cp de, 0x7F
	jrl gt, ApPreControl_ReturnNull
	sla de, 2
	lda_24 xwa, 0x024fd8
	ld_sril3 XWA, 0x07, 0xE0, 0xE8
	cp (xwa), 0x0
	jrl z, ApPreControl_ReturnNull

FDemo_DisplayStateQueryLoop:
	lds bc, 0
	calr FDemoText_ProcessTextMarkup
	ld xwa, xhl
	cp (xwa), 0x0
	jr nz, FDemo_DisplayStateQueryLoop
	jrl ApPreControl_ReturnNull

Seq_PostMelodyEventAlt:
	ld xwa, 0x1410000
	ld xde, xiz
	jrl Seq_DispatchMainFunc

Seq_ReadStartFlag:
	ld16_24 xhl, 0x0251d8
	exts xhl
	jr ApPreControl_Exit

Seq_GetControlBlock:
	lda_24 xhl, 0x024882

ApPreControl_Exit:
	pop xiz
	ret

FDemo_MultiGuardCheck:
	; --- Routine 1: multi-guard check, return HL=1 or 0 (30 bytes) ---
	.byte 0xc1, 0x38, 0x8d, 0x3f, 0xe4		; cp (0x8D38), 0xE4  [C1 prefix]
	jr nz, Banner_ReturnZero
	.byte 0xd1, 0xb4, 0x28, 0x3f, 0x00, 0x00	; cp (0x28B4), 0x0000  [D1 prefix]
	jr nz, Banner_ReturnZero
	.byte 0xc1, 0x2f, 0x0d, 0x3f, 0x00		; cp (0x0D2F), 0x00  [C1 prefix]
	jr nz, Banner_ReturnZero
	.byte 0xf1, 0xad, 0x28, 0xcb			; bit 3, (0x28AD)  [F1 prefix]
	jr nz, Banner_ReturnZero
	lds	hl, 1
	ret
Banner_ReturnZero:
	lds	hl, 0
	ret
FDemo_LoadRegsAndPostEvent:
	; --- Routine 2: load regs, jp FA9D58 (23 bytes) ---
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C10007
	ld xde, 0x00EA009E
	jp ApPostEvent


FDemo_LinkedListSearch:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ld32_24 xiz, 0x880008
	ld xwa, (xiz + 16)
	or xwa, xwa
	jr z, FDemo_LinkedListSearchFound

FDemo_LinkedListSearchLoop:
	push xiz
	ld xwa, (xsp + 8)
	push xwa
	call Strcmp
	inc 8, xsp
	cps hl, 0
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
	lds32 xhl, 0

FDemo_LinkedListSearchExit:
	pop xiz
	inc 4, xsp
	ret

; --- LinkedList_SearchInsert: Search and insert into a 24-byte-node list ---
; Two routines sharing this label block:
; 1) Search: Walks a fixed-size array at 0x249D8 (up to 63 entries,
;    24 bytes each). Calls compare function (0xFF3F35) for each node.
;    Returns pointer to matching entry or falls through.
; 2) Insert: Walks the same list checking node+16 for empty slot,
;    calls insert function (0xFF3F4D), returns success (HL=1) or fail.
FDemo_LinkedListSearchInsert:
	dec	8, xsp
	pushw	iz
	ld	(xsp+6), xwa
	lda_24	xwa, 149976
	ld	(xsp+2), xwa
	lds	iz, 0
	ld	xwa, (xsp+2)
	push	xwa
	ld	xwa, (xsp+10)
	push	xwa
	call	16715573
	inc	8, xsp
	cps	hl, 0
	jr	z, 16
	ld	xwa, 24
	add	(xsp+2), xwa
	inc	1, iz
	cp	iz, 63
	jr	lt, -34
	cp	iz, 63
	jr	z, 5
	ld	xhl, (xsp+2)
	jr	6
	ld	xwa, (xsp+6)
	calr	65409
	popw	iz
	inc	8, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xbc
	lda_24	xiz, 149976
	lds	de, 0
	ld	xbc, (xiz+16)
	or	xbc, xbc
	jr	z, 11
	lda	xiz, (xiz+24)
	inc	1, de
	cp	de, 63
	jr	lt, -18
	cp	de, 63
	jr	z, 18
	push	xwa
	push	xiz
	call	16715597
	inc	8, xsp
	ld	xwa, (xsp+4)
	ld	(xiz+16), xwa
	lds	hl, 1
	jr	2
	lds	hl, 0
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
	lds32 xhl, 0
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
	calr	65369
	or xhl, xhl
	jr z, FDemo_FileOpen_DoOpen
	lds	hl, 0
	jr t, FDemo_FileOpen_Exit
FDemo_FileOpen_DoOpen:
	lda	xwa, (xsp+10)
	ld xbc, 0x00EA00A8
	call FileIO_OpenWithMode
	ld (xsp+4), hl
	cpw (xsp+4), 0x0000
	jr lt, FDemo_FileOpen_GetResult
	lds32	xwa, 0
	lds	bc, 2
	call FileIO_SeekAndReadBlock
	call FileIO_SeekWriteBlock_Impl
	ld xiz, xhl
	call FileIO_SeekRead_ExtReturn
	ld xwa, xiz
	calr	64649
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
	calr	65355
FDemo_FileOpen_GetResult:
	ld hl, (xsp+4)
FDemo_FileOpen_Exit:
	pop xiz
	lda	xsp, (xsp+22)
	ret


DemoMode_Main_Operation:
	resda 0, 10417
	call Voice_InitializeAll
	ldada xbc, 63904
	ldada xwa, 65470
	sub xwa, xbc
	inc 2, xwa
	pushw wa
	push xbc
	pushw 0x3
	pushw 0xCF04
	call Mem_Copy
	lda xsp, (xsp + 10)
	call Audio_ConfigureDSP
	calr Voice_LoadVoiceTable
	setda 4, 64848
	resda 2, 64848
	resda 2, 64850
	calr Demo_PreSetup
	resda 0, 1115
	call AccompSeq_StopSequence
	calr Voice_CopyPreset
	call MIDI_BroadcastPitchReset
	calr Timer7_DisableInterrupt
	call Audio_CheckSubsystemReady
	setda 6, 47074
	resda 3, 10413
	call SeqInit_PostEventSequence
	call SeqInit_FinalEvent
	jp Seq_StartMainControl

FDemo_IndicatorSetup:
	ldw wa, 0x22
	lds bc, 0
	lds de, 0
	call CtrlPanel_IndicatorDispatch
	stdi8 36686, 4
	ret

DemoMode_Initialize:
	calr Demo_PreSetup
	stdi8 10598, 0
	stdi8 3379, 0
	stdi8 3375, 0
	resda 7, 10414
	call MidiChannel_ResetAndConfigure
	calr Audio_WaitForReady
	call SeqStep_PlaybackStateMachine
	calr Voice_SavePreset
	resda 3, 10413
	call SeqInit_PostEventSequence
	call LABEL_FC5399
	call SeqTimer_UpdateTempoReg
	call Voice_InitializeAll
	call Seq_StartMainControlAlt
	call TempoRingBuf_Init
	call SeqBuf_Init
	ldw wa, 0x22
	call CtrlPanel_SetIndicatorLED
	bitda 0, 10405
	jr z, FDemo_PostBannerCheck
	ldmm_sd24w 0xEC, 0xFF, 0x00, 0x9E, 0xF1

FDemo_PostBannerCheck:
	calr Banner_Loop_Check
	call Audio_CheckSubsystemReady
	resda 6, 47074
	ret

Demo_SelectionEntryHandler:
	calr Demo_PreSetup
	stdi8 10598, 0
	stdi8 3379, 0
	stdi8 3375, 0
	calr Audio_WaitForReady
	call SeqStep_PlaybackStateMachine
	resda 3, 10413
	call SeqInit_PostEventSequence
	call TempoRingBuf_Init
	call SeqBuf_Init
	ldw wa, 0x22
	call CtrlPanel_SetIndicatorLED
	jrl Banner_Loop_Check
	cpdi8 49277, 32
	ret nz
	ldda8 a, 49279
	and a, 0x13
	ret z
	ldda8 a, 49278
	and a, 0x13
	jr z, Demo_SelectEntry_NoNewButton
	stdi8 3379, 16
	ret

Demo_SelectEntry_NoNewButton:
	stdi8 3379, 0
	ret

Demo_SelectEntry_PreSaveCheck:
	cpdi8 36148, 19
	jr nz, Demo_SelectEntry_CheckVoiceKeys
	calr Voice_SavePreset
	ldada xbc, 63904
	ldada xwa, 65470
	sub xwa, xbc
	inc 2, xwa
	pushw wa
	pushw 0x3
	pushw 0xCF04
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 10)
	jr Demo_SelectEntry_ExitDispatch

Demo_SelectEntry_CheckVoiceKeys:
	ldda8 a, 36150
	cp a, 0x72
	jr z, Demo_SelectEntry_SaveVoice
	cp a, 0x70
	jr z, Demo_SelectEntry_SaveVoice
	cp a, 0x71
	jr z, Demo_SelectEntry_SaveVoice
	cp a, 0x6F
	jr nz, Demo_SelectEntry_ExitDispatch

Demo_SelectEntry_SaveVoice:
	calr Voice_SavePreset

Demo_SelectEntry_ExitDispatch:
	ldmm_sd24b 0xE3, 0xFF, 0x00, 0x4A, 0xF2
	ret

Demo_SelectEntry_ByteTable:
	.byte 0xf1, 0x66, 0x29, 0xcf, 0xb0, 0xfe, 0xc1, 0x21
	.byte 0x04, 0x21, 0xc9, 0xcc, 0x03, 0xb0, 0xfe, 0xc1
	.byte 0x5b, 0x04, 0x21, 0xc9, 0xcc, 0x03, 0xb0, 0xfe
	.byte 0xc1, 0x2f, 0x0d, 0x3f, 0x00, 0xb0, 0xfe, 0xc1
	.byte 0x7d, 0xc0, 0x3f, 0x01, 0xb0, 0xfe, 0xc1, 0x34
	.byte 0x8d, 0x3f, 0x13, 0xb0, 0xfe, 0xf1, 0x7e, 0xc0
	.byte 0xc8, 0xb0, 0xf6, 0xd1, 0xb4, 0x28, 0x3f, 0x00
	.byte 0x00, 0x6e, 0x06, 0xf1, 0x83, 0x32, 0xc8, 0x66
	.byte 0x34, 0xf1, 0xad, 0x28, 0xb3, 0xc1, 0x38, 0x8d
	.byte 0x3f, 0xe4, 0xf2, 0xf1, 0x29, 0xf2, 0xee, 0x1e
	.byte 0x3b, 0x03, 0x1e, 0xf0, 0x03, 0xf2, 0x84, 0x5b
	.byte 0x02, 0x02, 0x01, 0x00, 0xf1, 0x4e, 0x8f, 0x00
	.byte 0x04, 0xc1, 0x38, 0x8d, 0x3f, 0xe4, 0xf2, 0x4d
	.byte 0x2a, 0xf2, 0xee, 0xc1, 0xa4, 0x28, 0x21, 0xd8
	.byte 0x12, 0x1b, 0xad, 0x46, 0xf8, 0xf1, 0xad, 0x28
	.byte 0xbb, 0xc1, 0x38, 0x8d, 0x3f, 0xe4, 0x66, 0x0b
	.byte 0x1d, 0xbb, 0x29, 0xf2, 0xf1, 0x58, 0x11, 0x00
	.byte 0x00, 0x68, 0x05, 0xf1, 0x58, 0x11, 0x00, 0x12
	jrl	t, 0x00e3

Demo_SelectEntry_ProcessSongList:
	cpdi16 10420, 0
	jr z, Demo_SelectEntry_ToCountdown
	bitda 3, 10413
	jr z, Demo_SelectEntry_ManualSelect
	ldda8 a, 10404
	cpda8 a, 4439
	ret nz
	calr Demo_PreSetupAndScan
	calr Demo_WaitForDisplayBit
	calr Banner_Loop_Check
	cpdi8 36152, 228
	call_24 nz, 0xF22A4D
	jrl Demo_SelectEntry_AfterSongLoad

Demo_SelectEntry_ManualSelect:
	calr Demo_PreSetupAndScan
	calr Demo_WaitForDisplayBit
	calr Banner_Loop_Check
	ldda8 a, 10404
	cpda8 a, 4439
	jr z, Demo_SelectEntry_StartAutoPlay
	cpdi8 36152, 228
	call_24 nz, 0xF22A4D

Demo_SelectEntry_ToCountdown:
	jrl Demo_ResetCountdownTimer

Demo_SelectEntry_StartAutoPlay:
	stdi8 36686, 4
	cpdi8 36152, 228
	call_24 nz, 0xF22A4D
	ldda8 a, 10404
	extz wa
	call Seq_DispatchEventType6
	ret

Demo_SelectEntry_TimerTick:
	calr Demo_SelectEntry_CheckCPanel
	cpdi16_24 154500, 0
	call_24 nz, 0xF86E17
	ldda8 a, 3375
	cps a, 0
	ret z
	dec 1, a
	stda8 3375, a
	cp a, 0xA
	jr nz, Demo_SelectEntry_CheckCountdown
	ldda8 a, 10404
	extz wa
	calr Demo_ParseSlideHeader
	jrl Demo_SelectEntry_PlaySong

Demo_SelectEntry_CheckCountdown:
	ldda8 a, 3375
	cps a, 3
	jrl z, Demo_SelectEntry_StartPlayback
	cps a, 1
	ret nz
	stdi8 10598, 133
	ret

Demo_SelectEntry_CheckCPanel:
	cpdi8 36148, 19
	ret nz
	calr Demo_SelectEntry_Debounce
	ret

Demo_SelectEntry_Debounce:
	ldda8 a, 3379
	cps a, 0
	ret z
	dec 1, a
	stda8 3379, a
	cps a, 0
	ret nz
	setda 3, 10413
	cpdi8 36152, 228
	call_24 nz, 0xF229BB
	pushw 0x1
	ldw wa, 0xA8
	lds bc, 1
	lds de, 1
	call AddswbWr
	ret

Demo_SelectEntry_AfterSongLoad:
	cpdi8 36152, 228
	call_24 nz, 0xF22A4D
	ldda8 a, 10404
	extz wa
	call Seq_DispatchEventType6
	stdi8 36686, 4
	bitda 3, 10413
	ret z
	cpdi8 36152, 228
	jr z, Demo_SelectEntry_CheckSongCount
	cpdi8 4440, 18
	jr c, Demo_SelectEntry_UpdateDisplay
	stdi8 4440, 0
	jr Demo_SelectEntry_UpdateDisplay

Demo_SelectEntry_CheckSongCount:
	call Seq_IsMelodyActive
	cps hl, 0
	jr z, Demo_SelectEntry_CheckLimit18
	cpdi8 4440, 19
	jr ugt, Demo_SelectEntry_ClampSongIdx
	jr Demo_SelectEntry_UpdateDisplay

Demo_SelectEntry_CheckLimit18:
	cpdi8 4440, 18
	jr ule, Demo_SelectEntry_UpdateDisplay

Demo_SelectEntry_ClampSongIdx:
	stdi8 4440, 18

Demo_SelectEntry_UpdateDisplay:
	calr Demo_SelectEntry_LoadPattern
	calr Demo_SelectEntry_DrawSecondary
	calr Demo_ResetCountdownTimer
	incdi8 1, 4440
	ret

Demo_SelectEntry_LoadPattern:
	ldda8 a, 4440
	extz wa
	add wa, wa
	lda_24 xbc, 0xea00ac
	ldmm_srib 0x07, 0xE4, 0xE0, 0xA4, 0x28
	ret

Demo_SelectEntry_DrawSecondary:
	bitda 3, 10413
	ret z
	cpdi8 36152, 228
	ret z
	ldda8 a, 4440
	extz wa
	add wa, wa
	lda_24 xbc, 0xea00ad
	ld_srib3 A, 0x07, 0xE4, 0xE0
	call UI_PostModeChangeEvent
	ret

Demo_SelectEntry_PlaySong:
	cpdi8 36148, 19
	ret nz
	ldda8 a, 10404
	extz wa
	calr Demo_GetPresetBaseForPartAlt
	ld xwa, xhl
	call LABEL_FC534C
	lds wa, 2
	call BitMapOut_GetRenderMode_CheckBit3
	call SwbtWr_ReinitBothBanks
	lds wa, 2
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
	stdi8 36686, 6
	ldda8 a, 10404
	extz wa
	call Seq_DispatchEventType5
	ret

Demo_SelectEntry_StartPlayback:
	cpdi8 36148, 19
	ret nz
	call Seq_ResetAndRestartAccompaniment
	call Audio_CheckSubsystemReady
	ldmm8 4439, 10404
	cpdi8 36152, 228
	ret z
	call LABEL_F22A37
	ret

Audio_WaitForReady:
	ld xbc, 0xF000
	ldda8 a, 1056

Audio_WaitForReady_PollLoop:
	bit 2, a
	jr z, Audio_WaitForReady_Dispatch
	sub xbc, 0x1
	jr nz, Audio_WaitForReady_PollLoop

Audio_WaitForReady_Dispatch:
	stdi8 13046, 255
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
	stdi8 3375, 15
	ret

Timer7_DisableInterrupt:
	ldada xbc, 64920
	ld e, (xbc)
	res 7, e
	ld (xbc), e
	extz de
	pushw 0x80
	ldw wa, 0x98
	lds bc, 2
	call AddswbWr
	ret

Voice_LoadVoiceTable:
	push_werp 0xFA
	ldi_berp 0xFB, 0

Voice_LoadVoiceTable_Loop:
	ldto_berp A, 0xFB
	extz wa
	calr Demo_LookupPartTableEntry
	ld c, (xhl + 13)
	ldto_berp A, 0xFB
	st8_24 0x025b86, a
	and c, 0xF
	st8_24 0x025b88, c
	push xde
	push xhl
	push xix
	push xiz
	ld8_24 w, 0x025b88
	ld8_24 a, 0x025b86
	call MidiStream_HandlePartSelect
	pop xiz
	pop xix
	pop xhl
	pop xde
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x16
	jr ule, Voice_LoadVoiceTable_Loop
	ldw wa, 0x19
	calr Demo_LookupPartTableEntry
	ld c, (xhl + 13)
	sti8_24 0x025b86, 0x19
	and c, 0xF
	st8_24 0x025b88, c
	push xde
	push xhl
	push xix
	push xiz
	ld8_24 w, 0x025b88
	ld8_24 a, 0x025b86
	call MidiStream_HandlePartSelect
	pop xiz
	pop xix
	pop xhl
	pop xde
	pop_werp 0xFA
	ret

Banner_Loop_Check:
	dec 4, xsp
	push_werp 0xFA
	ldi_berp 0xFB, 0

Banner_Loop_CheckEntry:
	ldto_berp A, 0xFB
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xE
	jr z, Banner_Loop_Exit
	cp a, 0xF
	jr z, Banner_Loop_Exit
	cp a, 0x10
	jr z, Banner_Loop_Exit
	cp a, 0xD
	jr z, Banner_Loop_Exit
	setda 6, 10419
	lda xwa, (xsp + 2)
	ld (xwa), 0xD3
	ld (xwa + 1), 0x7E
	ld (xwa + 2), 0x7F
	ldto_berp C, 0xFB
	ld (xwa + 3), c
	lds bc, 4
	call SeqBuf_WriteMidiEventDirect

Banner_Loop_Exit:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, Banner_Loop_CheckEntry
	sti16_24 0x025b84, 0x0000
	pop_werp 0xFA
	inc 4, xsp
	ret

Demo_PreSetupAndScan:
	calr Demo_ScanActivePartChannels
	jr __jrt_nop_F86E7B
__jrt_nop_F86E7B:

Demo_PreSetup:
	call AccWrap_PlayModeDispatch
	call SeqBuf_Init
	call SeqPlay_EmergencyStopAll
	stdi8 1073, 0
	ret

Demo_ScanActivePartChannels:
	ldb l, 0x0
	ldada xix, 61856

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
	lda_24 xde, 0xea00da
	ld_sriw3 BC, 0x07, 0xE8, 0xE4
	andda16 xbc, 61854
	jr z, Demo_ScanPartSkipToEnd
	muls wa, 0x3
	ldada xbc, 62032
	bit_dri 7, 0x07, 0xE4, 0xE0
	jr z, Demo_ScanPartSkipToEnd
	ld a, l
	inc 1, a
	stda8 3414, a
	setda 0, 3412
	setda 2, 10363
	jr Demo_ScanPartDone

Demo_ScanPartSkipToEnd:
	ldb l, 0xF

Demo_ScanPartNext:
	inc 1, l
	cp l, 0x10
	jr c, Demo_ScanPartLoop

Demo_ScanPartDone:
	cp l, 0x10
	ret nz
	resda 0, 3412
	resda 2, 10363
	ret

Voice_SavePreset:
	pushw 0x10
	pushw 0x0
	pushw 0xCCE
	pushw 0x0
	pushw 0xF1A0
	call Mem_Copy
	lda xsp, (xsp + 10)
	ret

Voice_CopyPreset:
	pushw 0x10
	pushw 0x0
	pushw 0xF1A0
	pushw 0x0
	pushw 0xCCE
	call Mem_Copy
	lda xsp, (xsp + 10)
	ret

Demo_LookupPartTableEntry:
	extz wa
	sla wa, 2
	ldda32 xbc, 37106
	exts xwa
	add xwa, xbc
	ld xhl, (xwa)
	ret

Demo_WaitForDisplayBit:
	ld xwa, 0xFFFFFF
	bitda 2, 1056
	ret z

Demo_WaitForDisplayBit_Loop:
	sub xwa, 0x1
	ret z
	bitda 2, 1056
	jr nz, Demo_WaitForDisplayBit_Loop
	ret

Demo_GetPresetBaseForPart:
	extz wa
	sla wa, 2
	extz xwa
	add xwa, 0x9C4000
	ld xwa, (xwa)
	or xwa, xwa
	jr z, Demo_GetPresetBase_Default
	ld xhl, 0x69800
	jr Demo_GetPresetBase_StoreAndRet

Demo_GetPresetBase_Default:
	lda_24 xhl, 0x0ab000

Demo_GetPresetBase_StoreAndRet:
	st_dri3b C, 0xED, 0x00, 0x08
	ret

Demo_GetPresetBaseForPartAlt:
	extz wa
	sla wa, 2
	extz xwa
	add xwa, 0x9C4000
	ld xwa, (xwa)
	or xwa, xwa
	jr z, Demo_GetPresetBaseAlt_Default
	ld xhl, 0x69800
	jr Demo_GetPresetBaseAlt_StoreAndRet

Demo_GetPresetBaseAlt_Default:
	lda_24 xhl, 0x0ab000

Demo_GetPresetBaseAlt_StoreAndRet:
	st_dri3b C, 0xED, 0x00, 0x03
	ret

Demo_GetPresetBaseForPartExt:
	extz wa
	sla wa, 2
	extz xwa
	add xwa, 0x9C4000
	ld xwa, (xwa)
	or xwa, xwa
	jr z, Demo_GetPresetBaseExt_Default
	ld xwa, 0x69800
	jr Demo_GetPresetBaseExt_StoreAndRet

Demo_GetPresetBaseExt_Default:
	lda_24 xwa, 0x0ab000

Demo_GetPresetBaseExt_StoreAndRet:
	st_dri3b C, 0xE1, 0xD0, 0x00
	ret

Voice_GetPresetFieldWord:
	extz wa
	sla wa, 2
	extz xwa
	add xwa, 0x9C4000
	ld xwa, (xwa)
	or xwa, xwa
	jr z, Voice_GetPresetField_Default
	ld xwa, 0x69800
	jr Voice_GetPresetField_Compute

Voice_GetPresetField_Default:
	lda_24 xwa, 0x0ab000

Voice_GetPresetField_Compute:
	lda xwa, (xwa + 30)
	ld hl, (xwa)
	ret

Voice_GetPresetFieldAddr:
	extz wa
	sla wa, 2
	extz xwa
	add xwa, 0x9C4000
	ld xwa, (xwa)
	or xwa, xwa
	jr z, Voice_GetPresetFieldAddr_Default
	ld xwa, 0x69800
	jr Voice_GetPresetFieldAddr_Compute

Voice_GetPresetFieldAddr_Default:
	lda_24 xwa, 0x0ab000

Voice_GetPresetFieldAddr_Compute:
	lda xhl, (xwa + 32)
	ret

Demo_ProcessRecordEntry:
	lda xsp, (xsp - 14)
	push_werp 0xFA
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
	ldi_berp 0xFB, 0

Demo_RecordChainScanLoop:
	ldto_berp C, 0xFB
	extz bc
	ld xwa, (xsp + 4)
	ld_srib3 A, 0x07, 0xE0, 0xE4
	cp a, 0xD
	jr z, Demo_VoiceTypeDispatch
	cp a, 0x10
	jr z, Demo_VoiceTypeDispatch
	cp a, 0xF
	jr z, Demo_VoiceTypeDispatch
	cp a, 0xE
	jrl nz, Demo_RecordChainLoopExit

Demo_VoiceTypeDispatch:
	add bc, bc
	lda_24 xwa, 0xea00da
	ld_sriw3 WA, 0x07, 0xE0, 0xE4
	and wa, (xsp + 2)
	jrl z, Demo_RecordChainLoopExit
	ldto_berp A, 0xFB
	mul a, 0x3
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	bit_dri 7, 0x07, 0xE0, 0xE4
	jrl z, Demo_RecordChainLoopExit
	ld a, (xsp + 14)
	extz wa
	calr Demo_GetPresetBaseForPart
	ld xwa, xhl
	ldto_berp C, 0xFB
	mul c, 0x3
	ld e, c
	extz de
	inc 1, de
	ld xbc, (xsp + 8)
	ld_sriw3 BC, 0x07, 0xE4, 0xE8
	lds de, 0
	calr Demo_StoreRecordChainParams
	jr RecordChain_SkipToNext

RecordChain_ParseMidiStatus:
	ld a, l
	and a, 0xF0
	cp hl, 0x85
	jr nz, RecordChain_HandleStatus80
	ld (xsp + 12), 0x1
	jr Demo_RecordChainReturn

RecordChain_HandleStatus80:
	cp hl, 0x80
	jr nz, RecordChain_HandleOtherStatus
	calr RecordChain_ReadNextByte
	cps hl, 0
	jr z, RecordChain_SkipToNext
	jr RecordChain_ContinueLoop

RecordChain_HandleOtherStatus:
	cp a, 0x80
	jr z, RecordChain_ContinueLoop
	cp a, 0x90
	jr z, RecordChain_SkipDataByte
	cp a, 0xB0
	jr z, RecordChain_SkipDataByte
	cp a, 0xC0
	jr nz, RecordChain_HandleStatusD2

RecordChain_SkipDataByte:
	calr RecordChain_ReadNextByte
	cps hl, 0
	jr z, RecordChain_SkipToNext
	jr RecordChain_ContinueLoop

RecordChain_HandleStatusD2:
	cp hl, 0xD2
	jr nz, RecordChain_HandleStatusD0
	calr RecordChain_ReadNextByte
	cps hl, 0
	jr z, RecordChain_SkipToNext
	jr RecordChain_ContinueLoop

RecordChain_HandleStatusD0:
	cp a, 0xD0
	jr nz, RecordChain_SkipToNext
	calr RecordChain_ReadNextByte
	cps hl, 0
	jr nz, RecordChain_ContinueLoop

RecordChain_SkipToNext:
	calr RecordChain_SkipToStatusByte
	ld wa, hl
	cp wa, 0xFFFF
	jr nz, RecordChain_ParseMidiStatus

RecordChain_ContinueLoop:
	cp (xsp + 12), 0x1
	jr z, Demo_RecordChainReturn

Demo_RecordChainLoopExit:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jrl c, Demo_RecordChainScanLoop

Demo_RecordChainReturn:
	ld l, (xsp + 12)
	pop_werp 0xFA
	lda xsp, (xsp + 14)
	ret

Demo_StoreRecordChainParams:
	st32_24 0x025b8a, xwa
	st16_24 0x03ec4e, xbc
	st16_24 0x025b8e, xde
	ret

RecordChain_ReadNextByte:
	ld16_24 xwa, 0x03ec4e
	cp wa, 0xFFFF
	jr nz, RecordChain_ReadAdvance
	ldw hl, 0xFFFF
	ret

RecordChain_ReadAdvance:
	sll wa, 8
	sub wa, 0x100
	ld de, wa
	extz xde
	addda32_24 xde, 154506
	ld16_24 xwa, 0x025b8e
	ld bc, wa
	extz xbc
	inc 5, xbc
	add xbc, xde
	ld l, (xbc)
	extz hl
	inc 1, wa
	st16_24 0x025b8e, xwa
	cp wa, 0xFA
	ret ule
	ld wa, (xde + 3)
	st16_24 0x03ec4e, xwa
	sti16_24 0x025b8e, 0x0000
	ret

RecordChain_SkipToStatusByte:
	jr RecordChain_SkipReadNext

RecordChain_SkipCheckBit7:
	bit 7, hl
	ret nz

RecordChain_SkipReadNext:
	calr RecordChain_ReadNextByte
	cp hl, 0xFFFF
	jr nz, RecordChain_SkipCheckBit7
	ret

Demo_ParseSlideHeader:
	extz wa
	sla wa, 2
	extz xwa
	add xwa, 0x9C4000
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
	lda_24 xbc, 0xea0108
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	extz xwa
	lds bc, 0
	call FileIO_SeekAndReadBlock
	ldi_werp 0xFA, 1
	lds iz, 0
	jr FileIO_CheckSig_LoopTest

FileIO_CheckSig_ReadLoop:
	call FileIO_ReadByte
	cps hl, 0
	jr lt, FileIO_CheckSig_Fail
	ld a, (xsp + 4)
	extz wa
	sla wa, 3
	lda_24 xbc, 0xea0104
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld_srib3 A, 0x07, 0xE0, 0xF8
	cp l, a
	jr z, FileIO_CheckSig_Match

FileIO_CheckSig_Fail:
	ldi_werp 0xFA, 0
	jr FileIO_CheckSig_Return

FileIO_CheckSig_Match:
	inc 1, iz

FileIO_CheckSig_LoopTest:
	ld a, (xsp + 4)
	extz wa
	sla wa, 3
	lda_24 xbc, 0xea010a
	ld de, iz
	cp_sriw_rm DE, 0x07, 0xE4, 0xE0
	jr c, FileIO_CheckSig_ReadLoop

FileIO_CheckSig_Return:
	call FileIO_SeekRead_ExtReturn
	ldto_werp HL, 0xFA
	pop xiz
	inc 2, xsp
	ret

FileIO_ValidateFileSignature:
	lda xsp, (xsp - 26)
	push xiz
	ld (xsp + 28), a
	ldi_werp 0xFA, 0
	call GetCurrentFileIndex
	cps hl, 0
	jr ge, FileIO_ValidateSig_Process
	lds hl, 0
	jr FileIO_ValidateSig_Return

FileIO_ValidateSig_Process:
	ld a, l
	ldfr_berp A, 0xF8
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
	ld xbc, 0xEA0172
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, FileIO_ValidateSig_Done
	ld a, (xsp + 28)
	extz wa
	calr FileIO_CheckRegionSignature
	ldfr_werp HL, 0xFA
	call FileIO_CloseHandle

FileIO_ValidateSig_Done:
	ldto_werp HL, 0xFA

FileIO_ValidateSig_Return:
	pop xiz
	lda xsp, (xsp + 26)
	ret

FileIO_ReadAndValidateHeader:
	dec 4, xsp
	pushw iz
	lds32 xwa, 0
	lds bc, 0
	call FileIO_SeekAndReadBlock
	lds iz, 0

FileIO_ReadValidateHdr_Loop:
	call FileIO_ReadByte
	cps hl, 0
	jr ge, FileIO_ReadValidateHdr_Store
	lds hl, 0

FileIO_ReadValidateHdr_Store:
	lda xwa, (xsp + 2)
	lda_dri3 XSP, 0x07, 0xE0, 0xF8
	inc 1, iz
	cps iz, 3
	jr lt, FileIO_ReadValidateHdr_Loop
	call FileIO_SeekRead_ExtReturn
	lda xwa, (xsp + 2)
	ld xbc, 0xEA017E
	lds de, 3
	call FileIO_Search_SkipEntry
	cps hl, 0
	jr z, FileIO_ReadHeader_TypeMatch
	lda xwa, (xsp + 2)
	ld xbc, 0xEA0176
	lds de, 3
	call FileIO_Search_SkipEntry
	cps hl, 0
	jr z, FileIO_ReadHeader_TypeMatch
	lda xwa, (xsp + 2)
	ld xbc, 0xEA017A
	lds de, 3
	call FileIO_Search_SkipEntry
	lds wa, 0
	cps hl, 0
	jr nz, FileIO_ReadValidateHdr_Return

FileIO_ReadHeader_TypeMatch:
	lds wa, 1

FileIO_ReadValidateHdr_Return:
	ld hl, wa
	popw iz
	inc 4, xsp
	ret

FileIO_ValidateAndOpenFile:
	lda xsp, (xsp - 24)
	push xiz
	ldi_werp 0xFA, 0
	call GetCurrentFileIndex
	cps hl, 0
	jr ge, FileIO_ValidateOpen_Process
	lds hl, 0
	jr FileIO_ValidateOpen_Return

FileIO_ValidateOpen_Process:
	ld a, l
	ldfr_berp A, 0xF8
	extz iz
	ld wa, hl
	call GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 18)
	ld bc, iz
	call FileIO_FormatFileIndex
	lda xbc, (xsp + 18)
	lda xwa, (xsp + 4)
	lds de, 3
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, 0xEA0182
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, FileIO_ValidateOpen_Done
	calr FileIO_ReadAndValidateHeader
	ldfr_werp HL, 0xFA
	call FileIO_CloseHandle

FileIO_ValidateOpen_Done:
	ldto_werp HL, 0xFA

FileIO_ValidateOpen_Return:
	pop xiz
	lda xsp, (xsp + 24)
	ret

FileIO_ReadHeaderAt4:
	pushw iz
	lds iz, 1
	lds32 xwa, 4
	lds bc, 0
	call FileIO_SeekAndReadBlock
	call FileIO_ReadByte
	cps hl, 0
	jr lt, FileIO_ReadHdr4_Fail
	ld32_24 xwa, 0xea0186
	ld a, (xwa)
	cp l, a
	jr z, FileIO_ReadHdr4_Success

FileIO_ReadHdr4_Fail:
	lds iz, 0

FileIO_ReadHdr4_Success:
	call FileIO_SeekRead_ExtReturn
	ld hl, iz
	popw iz
	ret

FileIO_ValidateFileWithRegion:
	lda xsp, (xsp - 24)
	push xiz
	ldi_werp 0xFA, 0
	call GetCurrentFileIndex
	cps hl, 0
	jr lt, FileIO_ValidateRegion_NoFile
	ld a, l
	ldfr_berp A, 0xF8
	extz iz
	ld wa, hl
	call GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 18)
	ld bc, iz
	call FileIO_FormatFileIndex
	lda xbc, (xsp + 18)
	lda xwa, (xsp + 4)
	lds de, 2
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, 0xEA018C
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, FileIO_ValidateRegion_CheckSig

FileIO_ValidateRegion_NoFile:
	lds hl, 0
	jr FileIO_ValidateRegion_Return

FileIO_ValidateRegion_CheckSig:
	lds wa, 2
	calr FileIO_CheckRegionSignature
	cps hl, 0
	jr z, FileIO_ValidateRegion_Close
	calr FileIO_ReadHeaderAt4
	ldfr_werp HL, 0xFA

FileIO_ValidateRegion_Close:
	call FileIO_CloseHandle
	ldto_werp HL, 0xFA

FileIO_ValidateRegion_Return:
	pop xiz
	lda xsp, (xsp + 24)
	ret

FileIO_ReadHeaderAtF:
	pushw iz
	lds iz, 1
	ld xwa, 0xF
	lds bc, 0
	call FileIO_SeekAndReadBlock
	call FileIO_ReadByte
	cps hl, 0
	jr lt, FileIO_ReadHdrF_Fail
	cp l, 0x8
	jr z, FileIO_ReadHdrF_Success

FileIO_ReadHdrF_Fail:
	lds iz, 0

FileIO_ReadHdrF_Success:
	call FileIO_SeekRead_ExtReturn
	ld hl, iz
	popw iz
	ret

FileIO_ValidateWithExtHeader:
	lda xsp, (xsp - 24)
	push xiz
	ldi_werp 0xFA, 0
	call GetCurrentFileIndex
	cps hl, 0
	jr lt, FileIO_ValidateExt_NoFile
	ld a, l
	ldfr_berp A, 0xF8
	extz iz
	ld wa, hl
	call GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 18)
	ld bc, iz
	call FileIO_FormatFileIndex
	lda xbc, (xsp + 18)
	lda xwa, (xsp + 4)
	lds de, 1
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, 0xEA0190
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, FileIO_ValidateExt_CheckSig

FileIO_ValidateExt_NoFile:
	lds hl, 0
	jr FileIO_ValidateExt_Return

FileIO_ValidateExt_CheckSig:
	lds wa, 1
	calr FileIO_CheckRegionSignature
	cps hl, 0
	jr z, FileIO_ValidateExt_Close
	calr FileIO_ReadHeaderAtF
	ldfr_werp HL, 0xFA

FileIO_ValidateExt_Close:
	call FileIO_CloseHandle
	ldto_werp HL, 0xFA

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
	; --- Display region 0: VRAM 0xF980-0xFFC0, 0x1E7800-0x1E8000 ---
	lda xsp, (xsp - 14)			; allocate 14 bytes
	pushw iz				; save IZ (2 bytes, total frame=16)
	ld xbc, xwa				; XBC = caller arg
	lda xwa, (xsp + 2)			; XWA = stack buffer ptr
	lds	de, 0
	call FileIO_ReadHeader				; init display region descriptor
	lda xwa, (xsp + 2)			; reload buffer ptr
	ld xbc, 0x00EA0194			; resource ID for region 0
	call FileIO_OpenWithMode				; open display resource
	cps hl, 0				; check result (negative=error)
	jr ge, LoadRegion0_OpenSuccess			; success, continue
	call FileIO_ReturnError				; close resource (error path)
	jr LoadRegion0_Return				; return
LoadRegion0_OpenSuccess:
	lds	wa, 0
	calr FileIO_CheckRegionSignature			; check mode availability
	cps hl, 0
	jr z, LoadRegion0_AltPath			; mode not available, alt path
	call PreLswLoad				; primary display setup
	ldada	xwa, 63872
	ldada	xbc, 65472
	ld xde, xwa				; XDE = base (0xF980)
	sub xbc, xde				; XBC = size (0xFFC0-0xF980)
	call FileIO_ReadBlock				; configure memory range
	lda_24 xwa, 0x1E7800			; VRAM region base
	ld xde, xwa
	lda_24 xbc, 0x1E8000			; VRAM region end
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
	; --- Display region 1: VRAM 0x1ED350, memory up to 0x200000 ---
	lda xsp, (xsp - 14)
	pushw iz
	ld xbc, xwa
	lda xwa, (xsp + 2)
	lds	de, 1
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, 0x00EA0198			; resource ID for region 1
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadRegion1_OpenSuccess
	call FileIO_ReturnError
	jrl LoadRegion1_Return
LoadRegion1_OpenSuccess:
	lds	wa, 1
	calr FileIO_CheckRegionSignature
	cps hl, 0
	jrl z, LoadRegion1_ModeError
	calr FileIO_ReadHeaderAtF			; check extended mode
	cps hl, 0
	jr z, LoadRegion1_AltPmLoad
	lds	wa, 0
	call 0xFB62C3
	ld xwa, 0x00000010
	lds	bc, 0
	call FileIO_SeekAndReadBlock				; set region param
	lda_24 xwa, 0x1ED350			; VRAM base
	add xwa, 0x00000010			; offset +0x10
	ld xbc, 0x00000010			; size = 0x10
	call FileIO_ReadBlock
	ld xwa, 0x000000B0
	lds	bc, 0
	call FileIO_SeekAndReadBlock
	lda_24 xwa, 0x1ED350
	ld bc, (xwa + 13)			; load field at offset 0x0D
	extz xbc
	sll xbc, 3				; multiply by 8
	add xwa, 0x000000B0			; offset +0xB0
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	lds	wa, 0
	ld bc, iz
	call 0xFB62C4
	jr LoadRegion1_Finalize
LoadRegion1_AltPmLoad:
	call PrePmLoad				; alternate region setup
	lda_24 xwa, 0x1ED350
	ld xde, xwa
	lda_24 xbc, 0x200000			; end of DRAM
	sub xbc, xde				; size = 0x200000 - 0x1ED350
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call PostPmLoad
	jr LoadRegion1_Finalize
LoadRegion1_ModeError:
	ldw iz, 0xFF9A				; error code
LoadRegion1_Finalize:
	call FileIO_CloseHandle			; finalize
	ld hl, iz
LoadRegion1_Return:
	popw iz
	lda xsp, (xsp + 14)
	ret

FileIO_LoadRegion7_Flash:
	; --- Display region 7: flash/file buffer 0x3D3000, 0x0400 bytes ---
	lda xsp, (xsp - 14)
	push xiz				; save XIZ (4 bytes)
	ld xbc, xwa
	lda xwa, (xsp + 4)			; stack offset differs (XIZ=4 vs IZ=2)
	lds	de, 7
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, 0x00EA019C			; resource ID for region 7
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadRegion7_OpenSuccess
	call FileIO_ReturnError
	jr LoadRegion7_Return
LoadRegion7_OpenSuccess:
	lds	wa, 7
	calr FileIO_CheckRegionSignature
	cps hl, 0
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
	ld xwa, 0x003D3000			; flash/file area base
	push xwa
	lds	wa, 1
	ld xbc, xiz				; buffer ptr
	ldw de, 0x0400				; size
	call FlashWrite_Entry				; flash read/copy
	push xiz
	call Free				; Free buffer
	inc 4, xsp				; clean stack
	call FileIO_ReturnError
	ld iz, hl
	jr LoadRegion7_PostMidi
LoadRegion7_AllocFailed:
	ldw iz, 0xFF38				; alloc failure error code
LoadRegion7_PostMidi:
	ld wa, iz
	call PostMidiLoad
	jr LoadRegion7_Finalize
LoadRegion7_ModeError:
	ldw iz, 0xFF9A				; mode unavailable error
LoadRegion7_Finalize:
	call FileIO_CloseHandle
	ld hl, iz
LoadRegion7_Return:
	pop xiz
	lda xsp, (xsp + 14)
	ret

FileIO_LoadRegion2_ExtMem:
	; --- Display region 2: external memory 0x0AB000-0x0FD800 ---
	lda xsp, (xsp - 18)
	pushw iz
	ld (xsp + 16), xwa			; save caller arg
	lda xwa, (xsp + 2)
	ld xbc, (xsp + 16)
	lds	de, 2
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, 0x00EA01A0			; resource ID for region 2
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadRegion2_OpenSuccess
	call FileIO_ReturnError
	jrl LoadRegion2_Return
LoadRegion2_OpenSuccess:
	lds	wa, 2
	calr FileIO_CheckRegionSignature
	cps hl, 0
	jr z, LoadRegion2_ModeError
	calr FileIO_ReadHeaderAt4			; check extended mode (region 2)
	cps hl, 0
	jr z, LoadRegion2_AltSeqInit
	call SeqLoadPre				; primary ext memory init
	ld xwa, 0x000AB000			; ext memory base
	ld xbc, 0x00005000			; size = 0x5000
	call FileIO_ReadBlock
	lda_24 xwa, 0x0B0000			; ext memory region 2
	ld xde, xwa
	lda_24 xbc, 0x0FD800			; end address
	sub xbc, xde				; size = 0x0FD800 - 0x0B0000
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call SeqLoadPost				; post-setup
	jr LoadRegion2_Finalize
LoadRegion2_AltSeqInit:
	call SeqLoad_JumpInitFromPreset				; alternate ext memory init
	ld xwa, 0x000AB000
	ld xbc, 0x00000800			; smaller size
	call FileIO_ReadBlock
	lda_24 xwa, 0x0B0000
	ld xde, xwa
	lda_24 xbc, 0x0FD800
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call SeqLoad_PostAltEntry				; post-setup (alt)
	jr LoadRegion2_Finalize
LoadRegion2_ModeError:
	ldw iz, 0xFF9A				; mode unavailable error
LoadRegion2_Finalize:
	call FileIO_CloseHandle
	cps iz, 0				; check result
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
	ld xbc, 0xEA01A4
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadSong8_InitLoop
	call FileIO_ReturnError
	jrl LoadSong8_Return

LoadSong8_InitLoop:
	lds iz, 0

LoadSong8_ReadLoop:
	call FileIO_ReadByte
	cps hl, 0
	jr lt, LoadSong8_ReadDone
	lda xwa, (xsp + 4)
	lda_dri3 XSP, 0x07, 0xE0, 0xF8
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
	cps hl, 0
	jrl z, LoadSong8_AltPresetPath
	cps hl, 1
	jrl nz, FileIO_CloseHandle_Return
	call SeqLoad_JmpLoadPre
	ld xwa, 0xAB000
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
	ld xbc, 0xEA01A8
	call FileIO_OpenWithMode
	call FileIO_ReturnError
	ld (xsp + 2), hl
	cpw (xsp + 2), 0x0
	jr lt, LoadSong8_PostProcess
	lda_24 xwa, 0x0b0000
	ld xde, xwa
	lda_24 xbc, 0x0fd800
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld (xsp + 2), hl

LoadSong8_PostProcess:
	lds wa, 0
	ld bc, (xsp + 2)
	call SeqScan_ValidateAndDispatch
	lds iz, 0

LoadSong8_SlotLoop:
	ldto_berp A, 0xF8
	extz wa
	call FileData_LoadFromSlot
	inc 1, iz
	cp iz, 0xA
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
	ld xwa, 0xAB000
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
	ld xbc, 0xEA01AC
	call FileIO_OpenWithMode
	call FileIO_ReturnError
	ld (xsp + 2), hl
	cpw (xsp + 2), 0x0
	jr lt, Song_LoadAndInitPlayback
	lda_24 xwa, 0x0b0000
	ld xde, xwa
	lda_24 xbc, 0x0fd800
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld (xsp + 2), hl

Song_LoadAndInitPlayback:
	lds wa, 0
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
	; --- Display region 3: ext memory 0x094800-0x0AB000 ---
	lda xsp, (xsp - 14)
	pushw iz
	ld xbc, xwa
	lda xwa, (xsp + 2)
	lds	de, 3
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, 0x00EA01B0			; resource ID for region 3
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadRegion3_OpenSuccess
	call FileIO_ReturnError
	jr LoadRegion3_Return
LoadRegion3_OpenSuccess:
	lds	wa, 3
	calr FileIO_CheckRegionSignature
	cps hl, 0
	jr z, LoadRegion3_AltPath
	call cmp_ld_mae
	lda_24 xwa, 0x094800
	ld xde, xwa
	lda_24 xbc, 0x0AB000
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call cmp_ld_ato
	jr LoadRegion3_Finalize
LoadRegion3_AltPath:
	call LABEL_F18EC8				; alternate path
	ld iz, hl
LoadRegion3_Finalize:
	call FileIO_CloseHandle
	ld hl, iz
LoadRegion3_Return:
	popw iz
	lda xsp, (xsp + 14)
	ret

FileIO_LoadRegion5_VRAM:
	; --- Display region 5: VRAM 0x1E8800-0x1EC400 ---
	lda xsp, (xsp - 14)
	pushw iz
	ld xbc, xwa
	lda xwa, (xsp + 2)
	lds	de, 5
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, 0x00EA01B4			; resource ID for region 5
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadRegion5_OpenSuccess
	call FileIO_ReturnError
	jr LoadRegion5_Return
LoadRegion5_OpenSuccess:
	lds	wa, 5
	calr FileIO_CheckRegionSignature
	cps hl, 0
	jr z, LoadRegion5_AltPath
	call msp_ld_mae
	lda_24 xwa, 0x1E8800
	ld xde, xwa
	lda_24 xbc, 0x1EC400
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call msp_ld_ato
	jr LoadRegion5_Finalize
LoadRegion5_AltPath:
	call 0xF194C9				; alternate path
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
	lds	de, 6
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, 0x00EA01B8			; resource ID for region 6
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadRegion6_OpenSuccess
	call FileIO_ReturnError
	jr LoadRegion6_Return
LoadRegion6_OpenSuccess:
	lds	wa, 6
	calr FileIO_CheckRegionSignature
	cps hl, 0
	jr z, LoadRegion6_ModeError
	call 0xF186A9
	ld iz, hl
	jr LoadRegion6_Finalize
LoadRegion6_ModeError:
	ldw iz, 0xFF9A				; mode unavailable
LoadRegion6_Finalize:
	call FileIO_CloseHandle
	ld hl, iz
LoadRegion6_Return:
	popw iz
	lda xsp, (xsp + 14)
	ret

FileIO_LoadRegion4_VRAM:
	; --- Display region 4: VRAM 0x1E0000-0x1E7800 (with iteration loop) ---
	lda xsp, (xsp - 30)
	pushw iz
	ld xbc, xwa
	lda xwa, (xsp + 18)
	lds	de, 4
	call FileIO_ReadHeader
	lda xwa, (xsp + 18)
	ld xbc, 0x00EA01BC			; resource ID for region 4
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadRegion4_OpenSuccess
	call FileIO_ReturnError
	jrl LoadRegion4_Return
LoadRegion4_OpenSuccess:
	lds	wa, 4
	calr FileIO_CheckRegionSignature
	cps hl, 0
	jr z, LoadRegion4_AltIterLoop
	call PreTmLoad
	lda_24 xwa, 0x1E0000
	ld xde, xwa
	lda_24 xbc, 0x1E7800
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call PostTmLoad
	jr LoadRegion4_Finalize
LoadRegion4_AltIterLoop:
	lds	iz, 0
LoadRegion4_ReadByteLoop:
	call FileIO_ReadByte
	cps hl, 0
	jr lt, LoadRegion4_ReadDone
	lda xwa, (xsp + 2)
	.byte 0xf3, 0x07, 0xe0, 0xf8, 0x47	; ld (xwa + iz), l  [reg+reg indexed, not in LLVM]
	inc 1, iz
	cp iz, 0x0010				; loop 16 times
	jr lt, LoadRegion4_ReadByteLoop
LoadRegion4_ReadDone:
	call FileIO_ReturnError
	ld iz, hl
	cps iz, 0
	jr lt, LoadRegion4_PostSave
	lda xwa, (xsp + 2)
	call PostTmSave_ByteBlock
	ld iz, hl
	cps iz, 0
	jr lt, LoadRegion4_PostSave
	call FileIO_SeekRead_ExtReturn
	lda_24 xwa, 0x1E0000
	ld xde, xwa
	lda_24 xbc, 0x1E7800
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
	ldi_werp 0xFA, 0
	call GetCurrentFileIndex
	ld iz, hl
	cps iz, 0
	jr ge, ParseDir_ValidIndex
	ldw hl, 0xFF98
	jrl ParseDir_Return

ParseDir_ValidIndex:
	ld wa, iz
	call GetFileEntryPtr
	ld (xsp + 4), xhl
	ldto_berp C, 0xF8
	extz bc
	lda xwa, (xsp + 10)
	ld xde, (xsp + 4)
	call FileIO_FormatFileIndex
	ldw (xsp + 8), 0x0
	lds iz, 0

; File demo record callback dispatch
FileDemo_RecordCallback:
	ld wa, iz
	muls wa, 0x6
	lda_24 xbc, 0xea01c0
	ld_srib3 A, 0x07, 0xE4, 0xE0
	call FileIO_WriteRecordName_Done
	cps l, 0
	jr z, FileIO_RecordLoop_Continue
	ld wa, iz
	muls wa, 0x6
	lda_24 xbc, 0xea01c0
	ld_srib3 A, 0x07, 0xE4, 0xE0
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileIO_RecordLoop_Continue
	lda xwa, (xsp + 10)
	ld bc, iz
	muls bc, 0x6
	lda_24 xde, 0xea01c2
	exts xbc
	add xbc, xde
	ld xix, (xbc)
	call (xix)
	cps hl, 0
	jr ge, ParseDir_IncrementCount
	cpi_werp 0xFA, 0
	jr lt, FileIO_RecordLoop_Continue
	ldfr_werp HL, 0xFA
	jr FileIO_RecordLoop_Continue

ParseDir_IncrementCount:
	incm 1, (xsp + 8)

FileIO_RecordLoop_Continue:
	inc 1, iz
	cp iz, 0x8
	jr lt, FileDemo_RecordCallback
	lds wa, 2
	call FileIO_WriteRecordName_Done
	cps l, 0
	jr z, FileIO_FinalizeRecordLookup
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileIO_FinalizeRecordLookup
	ldw wa, 0x9
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileIO_FinalizeRecordLookup
	lda xwa, (xsp + 10)
	calr FileIO_LoadSongRegion8
	cps hl, 0
	jr ge, ParseDir_SongIncrCount
	cpi_werp 0xFA, 0
	jr lt, FileIO_FinalizeRecordLookup
	ldfr_werp HL, 0xFA
	jr FileIO_FinalizeRecordLookup

ParseDir_SongIncrCount:
	incm 1, (xsp + 8)

FileIO_FinalizeRecordLookup:
	cpw (xsp + 8), 0x0
	jr le, ParseDir_NoRecords
	ld xwa, (xsp + 4)
	call FileIO_GetRecordByType_Lookup
	jr ParseDir_GetResult

ParseDir_NoRecords:
	cpi_werp 0xFA, 0
	jr lt, ParseDir_GetResult
	ldi_erpw 0xFA, 0x98, 0xFF

ParseDir_GetResult:
	ldto_werp HL, 0xFA

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
; Resource IDs: 0xEA01F0 through 0xEA020C (one per region).
; Returns HL=0xFF9B on insufficient space.
; =============================================================================
FileIO_SaveRegion0_VRAM:
	; --- Save region 0: VRAM F980-FFC0, ext mem 1E7800-1E8000 ---
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 22), xwa			; save arg
	ldada	xbc, 65472
	ldada	xwa, 63872
	ld (xsp + 4), xbc			; save end address
	sub (xsp + 4), xwa			; size = end - start
	lda_24 xbc, 0x1E7800
	lda_24 xiz, 0x1E8000
	sub xiz, xbc				; VRAM size
	call FileIO_GetDiskFreeSpace				; get available space
	ld xwa, (xsp + 4)			; total size needed
	add xwa, xiz
	cp xhl, xwa				; enough space?
	jr ge, SaveRegion0_SpaceOk			; yes
	ldw hl, 0xFF9B				; error: insufficient space
	jr SaveRegion0_Return				; return error
SaveRegion0_SpaceOk:
	lda xwa, (xsp + 8)			; local buffer
	ld xbc, (xsp + 22)			; saved arg
	lds	de, 0
	call FileIO_ReadHeader				; init region
	lda xwa, (xsp + 8)			; buffer
	ld xbc, 0x00EA01F0			; resource ID region 0
	call FileIO_OpenWithMode				; open resource
	cps hl, 0
	jr ge, SaveRegion0_OpenSuccess			; success
	call FileIO_ReturnError				; close/cleanup
	jr SaveRegion0_Return				; return error
SaveRegion0_OpenSuccess:
	call PreLswSave				; pre-save hook
	ld xwa, 0x0000F980			; VRAM start
	ld xbc, (xsp + 4)			; VRAM size
	call FileIO_WriteByte_Impl				; save range 1
	ld xwa, 0x001E7800			; ext mem start
	ld xbc, xiz				; ext mem size
	call FileIO_WriteByte_Impl				; save range 2
	call FileIO_ReturnError				; close
	ld iz, hl				; save status
	ld wa, iz
	call PostLswSave				; post-save hook
	call FileIO_CloseHandle			; finalize
	cps iz, 0
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
	lda_24 xbc, 0x1ED350			; base address
	cps l, 0				; check mode
	jr z, SaveRegion1_FullRange			; mode 0 path
	ld iz, (xbc + 13)			; get size param
	extz xiz
	sla xiz, 3				; * 8
	add xiz, 0x000000B0			; + 0xB0 base size
	jr SaveRegion1_CheckSpace
SaveRegion1_FullRange:
	lda_24 xiz, 0x200000			; full range
	sub xiz, xbc				; size = 0x200000 - 0x1ED350
SaveRegion1_CheckSpace:
	call FileIO_GetDiskFreeSpace				; get available space
	cp xhl, xiz				; enough?
	jr ge, SaveRegion1_SpaceOk
	ldw hl, 0xFF9B
	jr SaveRegion1_Return
SaveRegion1_SpaceOk:
	lda xwa, (xsp + 4)			; buffer
	ld xbc, (xsp + 18)			; arg
	lds	de, 1
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, 0x00EA01F4			; resource ID region 1
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, SaveRegion1_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion1_Return
SaveRegion1_OpenSuccess:
	call FileIO_GetRecordAttr_Check				; re-check mode
	cps l, 0
	jr z, SaveRegion1_AltPmSave			; mode 0 path
	ld xwa, 0x001ED350
	ld xbc, xiz
	call FileIO_WriteByte_Impl				; save VRAM range
	ld xwa, 0x0000000F			; param
	lds	bc, 0
	call FileIO_SeekAndReadBlock				; set region param
	ldw wa, 0x0008
	call FileIO_ReadByte_BufferHit				; configure
	call FileIO_ReturnError
	ld iz, hl
	jr SaveRegion1_Finalize
SaveRegion1_AltPmSave:
	call PrePmSave				; alternate pre-save
	ld xwa, 0x001ED350
	ld xbc, xiz
	call FileIO_WriteByte_Impl
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call PostPmSave				; alternate post-save
SaveRegion1_Finalize:
	call FileIO_CloseHandle
	cps iz, 0
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
	ldw hl, 0xFF9B
	jr SaveRegion7_Return
SaveRegion7_SpaceOk:
	lda xwa, (xsp + 4)
	ld xbc, xiz
	lds	de, 7
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, Resource_Region7_Start			; resource ID region 7
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, SaveRegion7_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion7_Return
SaveRegion7_OpenSuccess:
	call PreMidiSave				; pre-save hook
	ld xwa, 0x003D3000			; flash address
	ld xbc, 0x00000400			; 1024 bytes
	call FileIO_WriteByte_Impl
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call PostMidiSave				; post-save hook
	call FileIO_CloseHandle
	cps iz, 0
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
	ldw hl, 0xFF9B
	jr SaveRegion2_Return
SaveRegion2_SpaceOk:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	lds	de, 2
	call FileIO_ReadHeader
	lda xwa, (xsp + 8)
	ld xbc, Resource_Region2_Start			; resource ID region 2
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, SaveRegion2_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion2_Return
SaveRegion2_OpenSuccess:
	ld xwa, 0x000AB000			; ext mem base
	ld xbc, 0x00005000			; fixed range
	call FileIO_WriteByte_Impl
	ld xwa, 0x000B0000			; second range base
	ld xbc, (xsp + 4)			; computed size
	call FileIO_WriteByte_Impl
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call SeqSavePost				; post-save hook
	call FileIO_CloseHandle
	cps iz, 0
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
	ldw hl, 0xFF9B
	jr SaveRegion3_Return
SaveRegion3_SpaceOk:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	lds	de, 3
	call FileIO_ReadHeader
	lda xwa, (xsp + 8)
	ld xbc, Resource_Region3_Start			; resource ID region 3
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, SaveRegion3_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion3_Return
SaveRegion3_OpenSuccess:
	ld xwa, 0x00094800			; ext mem start
	ld xbc, (xsp + 4)			; computed size
	call FileIO_WriteByte_Impl
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call cmp_sv_ato				; post-save
	call FileIO_CloseHandle
	cps iz, 0
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
	ldw hl, 0xFF9B
	jr SaveRegion5_Return
SaveRegion5_SpaceOk:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	lds	de, 5
	call FileIO_ReadHeader
	lda xwa, (xsp + 8)
	ld xbc, 0x00EA0204			; resource ID region 5
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, SaveRegion5_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion5_Return
SaveRegion5_OpenSuccess:
	ld xwa, 0x001E8800			; VRAM start
	ld xbc, (xsp + 4)			; computed size
	call FileIO_WriteByte_Impl
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call msp_sv_ato				; post-save
	call FileIO_CloseHandle
	cps iz, 0
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
	lds	de, 6
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, 0x00EA0208			; resource ID region 6
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, SaveRegion6_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion6_Return
SaveRegion6_OpenSuccess:
	call 0xF187F3				; region-specific handler
	ld iz, hl
	call FileIO_CloseHandle
	cps iz, 0
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
	; --- Save region 4: VRAM 1E0000, fixed 0x72AA bytes ---
	lda xsp, (xsp - 14)
	push xiz
	ld xiz, xwa
	call FileIO_GetDiskFreeSpace
	cp xhl, 0x000072AA			; need 29,354 bytes
	jr ge, SaveRegion4_SpaceOk
	ldw hl, 0xFF9B
	jr SaveRegion4_Return
SaveRegion4_SpaceOk:
	lda xwa, (xsp + 4)
	ld xbc, xiz
	lds	de, 4
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, 0x00EA020C			; resource ID region 4
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, SaveRegion4_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion4_Return
SaveRegion4_OpenSuccess:
	call PreTmSave				; pre-save hook
	ld xwa, 0x001E0000			; VRAM base
	ld xbc, 0x000072AA			; size
	call FileIO_WriteByte_Impl
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call PostTmSave				; post-save hook
	call FileIO_CloseHandle
	cps iz, 0
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
	cps iz, 0
	jr ge, SaveAll_GetEntryPtr
	ldw hl, 0xFF98
	jrl SaveAll_Return

SaveAll_GetEntryPtr:
	ld wa, iz
	call GetFileEntryPtr
	ld xde, xhl
	ldto_berp C, 0xF8
	extz bc
	lda xwa, (xsp + 20)
	call FileIO_FormatFileIndex
	ldi_werp 0xFA, 0

SaveAll_CheckRecordLoop:
	ldto_werp WA, 0xFA
	muls wa, 0x6
	lda_24 xbc, 0xea0210
	ld_srib3 A, 0x07, 0xE4, 0xE0
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, SaveAll_NextRecord
	lda xbc, (xsp + 20)
	ldto_werp WA, 0xFA
	muls wa, 0x6
	lda_24 xde, 0xea0210
	ld_srib3 E, 0x07, 0xE8, 0xE0
	lda xwa, (xsp + 6)
	call FileIO_ReadHeader
	lda xwa, (xsp + 6)
	call FileIO_OpenDefault
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jrl lt, SaveAll_GetResult

SaveAll_NextRecord:
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x08, 0x00
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
	ldto_berp C, 0xF8
	extz bc
	lda xwa, (xsp + 20)
	call FileIO_FormatFileIndex
	ldi_werp 0xFA, 0

; File demo process callback dispatch
FileDemo_ProcessCallback:
	ldto_werp WA, 0xFA
	muls wa, 0x6
	lda_24 xbc, 0xea0210
	ld_srib3 A, 0x07, 0xE4, 0xE0
	call FileIO_FormatName_Return
	cps l, 0
	jr z, SaveAll_ProcessNextRecord
	lda xwa, (xsp + 20)
	ldto_werp BC, 0xFA
	muls bc, 0x6
	lda_24 xde, 0xea0212
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jr lt, SaveAll_CheckSaveError

SaveAll_ProcessNextRecord:
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x08, 0x00
	jr lt, FileDemo_ProcessCallback

SaveAll_CheckSaveError:
	cpw (xsp + 4), 0x0
	jr ge, SaveAll_GetResult
	ldi_werp 0xFA, 0

SaveAll_RollbackLoop:
	ldto_werp WA, 0xFA
	muls wa, 0x6
	lda_24 xbc, 0xea0210
	ld_srib3 A, 0x07, 0xE4, 0xE0
	call FileIO_FormatName_Return
	cps l, 0
	jr z, SaveAll_RollbackNext
	lda xbc, (xsp + 20)
	ldto_werp WA, 0xFA
	muls wa, 0x6
	lda_24 xde, 0xea0210
	ld_srib3 E, 0x07, 0xE8, 0xE0
	lda xwa, (xsp + 6)
	call FileIO_ReadHeader
	lda xwa, (xsp + 6)
	call FileIO_OpenDefault

SaveAll_RollbackNext:
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x08, 0x00
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
	cps hl, 0
	jr ge, LoadSMF_GetRecordPtr
	ldw hl, 0xFF98
	jr LoadSMF_Return

LoadSMF_GetRecordPtr:
	ld wa, hl
	call GetRecordPtrForFile
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0240
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadSMF_OpenAndProcess
	call FileIO_ReturnError
	jr LoadSMF_Return

LoadSMF_OpenAndProcess:
	ld wa, (xsp + 8)
	extz wa
	ld c, (xsp + 6)
	extz bc
	call LABEL_F23251
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
	ld xbc, 0xEA0244
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadVariant_OpenAndProcess
	call FileIO_ReturnError
	jr LoadVariant_Return

LoadVariant_OpenAndProcess:
	ldto_berp A, 0xF8
	extz wa
	ld c, (xsp + 8)
	extz bc
	ld e, (xsp + 6)
	extz de
	call SMF_LoadSoundBankAndPlay
	ld iz, hl
	call FileIO_CloseHandle
	cps iz, 0
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
	ldw hl, 0xFF98
	jrl MultiPass_Return

MultiPass_SetupEntry:
	ld wa, (xsp + 4)
	ldfr_berp A, 0xF8
	extz iz
	ld wa, (xsp + 4)
	call GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 20)
	ld bc, iz
	call FileIO_FormatFileIndex
	lds iz, 0

MultiPass_RetryLoop:
	lda_24 xwa, 0xea00fa
	ld_srib3 A, 0x07, 0xE0, 0xF8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, MultiPass_LoopNext
	lda xbc, (xsp + 20)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
	lda xwa, (xsp + 6)
	call FileIO_ReadHeader
	lda xwa, (xsp + 6)
	call FileIO_OpenDefault
	ldfr_werp HL, 0xFA
	cpi_werp 0xFA, 0
	jr lt, MultiPass_StoreResult

MultiPass_LoopNext:
	inc 1, iz
	cp iz, 0xA
	jr lt, MultiPass_RetryLoop
	ld wa, (xsp + 4)
	ldfr_berp A, 0xF8
	extz iz
	call FileIO_GetRecordByType
	ld xde, xhl
	lda xwa, (xsp + 20)
	ld bc, iz
	call FileIO_FormatFileIndex
	lda xbc, (xsp + 20)
	lda xwa, (xsp + 6)
	lds de, 2
	call FileIO_ReadHeader
	lda xwa, (xsp + 6)
	ld xbc, 0xEA0248
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, MultiPass_Finalize
	call FileIO_ReturnError
	jr MultiPass_Return

MultiPass_Finalize:
	ld wa, (xsp + 30)
	extz wa
	call SeqSave_PreparePartData
	ldfr_werp HL, 0xFA
	call FileIO_CloseHandle
	cpi_werp 0xFA, 0
	jr ge, MultiPass_StoreResult
	lda xwa, (xsp + 6)
	call FileIO_OpenDefault

MultiPass_StoreResult:
	ldto_werp HL, 0xFA

MultiPass_Return:
	pop xiz
	lda xsp, (xsp + 28)
	ret

FileIO_ByteBlock_F8817E:
	.byte 0xbf, 0xdc, 0x37, 0x3e, 0xbf, 0x24, 0x51, 0xbf
	.byte 0x26, 0x50, 0x1d, 0xef, 0x95, 0xf8, 0xdb, 0xd8
	.byte 0x69, 0x06, 0x33, 0x98, 0xff, 0x78, 0xbb, 0x00
	.byte 0xcf, 0x89, 0xc7, 0xf8, 0x99, 0xde, 0x12, 0xdb
	.byte 0x88, 0x1d, 0x23, 0x96, 0xf8, 0xeb, 0x8a, 0xbf
	.byte 0x1a, 0x30, 0xde, 0x89, 0x1d, 0x7e, 0x91, 0xf8
	.byte 0xbf, 0x1a, 0x31, 0xbf, 0x0c, 0x30, 0xda, 0xa9
	.byte 0x1d, 0xab, 0x91, 0xf8, 0xbf, 0x0c, 0x30, 0x41
	.long Resource_RegionPad
	.byte 0x1d, 0xc7, 0x8b, 0xf8
	.byte 0xdb, 0xd8, 0x69, 0x07, 0x1d, 0xc2, 0x8b, 0xf8
	.byte 0x78, 0x80, 0x00, 0xd8, 0xa9, 0x1e, 0xd0, 0xef
	.byte 0xdb, 0xd8, 0x66, 0x6e, 0xd2, 0x5d, 0xd3, 0x1e
	.byte 0x20, 0xe8, 0x12, 0xbf, 0x08, 0x60, 0x9f, 0x26
	.byte 0x20, 0xe8, 0x12, 0xaf, 0x08, 0x21, 0x1d, 0x5c
	.byte 0x0a, 0xff, 0xeb, 0x8e, 0xee, 0xc8, 0xb0, 0x00
	.byte 0x00, 0x00, 0x9f, 0x24, 0x20, 0xe8, 0x12, 0xaf
	.byte 0x08, 0x21, 0x1d, 0x5c, 0x0a, 0xff, 0xbf, 0x04
	.byte 0x63, 0x40, 0xb0, 0x00, 0x00, 0x00, 0xaf, 0x04
	.byte 0x88, 0xee, 0x88, 0xd9, 0xa8, 0x1d, 0xe0, 0x8e
	.byte 0xf8, 0xdb, 0x8e, 0xde, 0xd8, 0x61, 0x2e, 0x9f
	.byte 0x24, 0x20, 0xd8, 0x12, 0x1d, 0xb5, 0x62, 0xfb
	.byte 0xf2, 0x50, 0xd3, 0x1e, 0x30, 0xaf, 0x04, 0x80
	.byte 0xaf, 0x08, 0x21, 0x1d, 0x74, 0x8d, 0xf8, 0x1d
	.byte 0xc2, 0x8b, 0xf8, 0xdb, 0x8e, 0x9f, 0x24, 0x20
	.byte 0xd8, 0x12, 0xde, 0x89, 0x1d, 0xb6, 0x62, 0xfb
	.byte 0x68, 0x03, 0x36, 0x9a, 0xff, 0x1d, 0x48, 0x8c
	.byte 0xf8, 0xde, 0x8b, 0x5e, 0xbf, 0x24, 0x37, 0x0e
	.byte 0xbf, 0xdc, 0x37, 0x3e, 0xbf, 0x24, 0x51, 0xbf
	.byte 0x26, 0x50, 0x1d, 0xef, 0x95, 0xf8, 0xdb, 0xd8
	.byte 0x69, 0x06, 0x33, 0x98, 0xff, 0x78, 0x03, 0x01
	.byte 0xcf, 0x89, 0xd8, 0x12, 0xbf, 0x0a, 0x50, 0xdb
	.byte 0x88, 0x1d, 0x23, 0x96, 0xf8, 0xeb, 0x8a, 0xbf
	.byte 0x1a, 0x30, 0x9f, 0x0a, 0x21, 0x1d, 0x7e, 0x91
	.byte 0xf8, 0xbf, 0x1a, 0x31, 0xbf, 0x0c, 0x30, 0xda
	.byte 0xa9, 0x1d, 0xab, 0x91, 0xf8, 0xbf, 0x0c, 0x30
	.byte 0x41, 0x50, 0x02, 0xea, 0x00, 0x1d, 0xc7, 0x8b
	.byte 0xf8, 0xdb, 0xd8, 0x69, 0x07, 0x1d, 0xc2, 0x8b
	.byte 0xf8, 0x78, 0xc7, 0x00, 0xd8, 0xa9, 0x1e, 0xf7
	.byte 0xee, 0xdb, 0xd8, 0x76, 0xb4, 0x00, 0x9f, 0x26
	.byte 0x20, 0xe8, 0x12, 0xe8, 0x8e, 0xee, 0xee, 0x04
	.byte 0xee, 0xc8, 0x10, 0x00, 0x00, 0x00, 0x9f, 0x24
	.byte 0x20, 0xe8, 0x12, 0xbf, 0x04, 0x60, 0xe8, 0xee
	.byte 0x04, 0xbf, 0x04, 0x60, 0x40, 0x10, 0x00, 0x00
	.byte 0x00, 0xaf, 0x04, 0x88, 0xee, 0x88, 0xd9, 0xa8
	.byte 0x1d, 0xe0, 0x8e, 0xf8, 0xdb, 0x8e, 0xde, 0xd8
	.byte 0x71, 0x82, 0x00, 0x9f, 0x24, 0x20, 0xd8, 0x12
	.byte 0x1d, 0xc3, 0x62, 0xfb, 0xf2, 0x50, 0xd3, 0x1e
	.byte 0x30, 0xaf, 0x04, 0x80, 0x41, 0x10, 0x00, 0x00
	.byte 0x00, 0x1d, 0x74, 0x8d, 0xf8, 0xd2, 0x5d, 0xd3
	.byte 0x1e, 0x20, 0xe8, 0x12, 0xbf, 0x08, 0x60, 0xe8
	.byte 0xee, 0x03, 0xbf, 0x08, 0x60, 0x9f, 0x26, 0x20
	.byte 0xe8, 0x12, 0xaf, 0x08, 0x21, 0x1d, 0x5c, 0x0a
	.byte 0xff, 0xeb, 0x8e, 0xee, 0xc8, 0xb0, 0x00, 0x00
	.byte 0x00, 0x9f, 0x24, 0x20, 0xe8, 0x12, 0xaf, 0x08
	.byte 0x21, 0x1d, 0x5c, 0x0a, 0xff, 0xbf, 0x04, 0x63
	.byte 0x40, 0xb0, 0x00, 0x00, 0x00, 0xaf, 0x04, 0x88
	.byte 0xee, 0x88, 0xd9, 0xa8, 0x1d, 0xe0, 0x8e, 0xf8
	.byte 0xf2, 0x50, 0xd3, 0x1e, 0x30, 0xaf, 0x04, 0x80
	.byte 0xaf, 0x08, 0x21, 0x1d, 0x74, 0x8d, 0xf8, 0x1d
	.byte 0xc2, 0x8b, 0xf8, 0xdb, 0x8e, 0x9f, 0x24, 0x20
	.byte 0xd8, 0x12, 0xde, 0x89, 0x1d, 0xc4, 0x62, 0xfb
	.byte 0x68, 0x03, 0x36, 0x9a, 0xff, 0x1d, 0x48, 0x8c
	.byte 0xf8, 0xde, 0x8b, 0x5e, 0xbf, 0x24, 0x37, 0x0e
	.byte 0xbf, 0xe2, 0x37, 0x3e, 0xbf, 0x20, 0x50, 0x1d
	.byte 0xef, 0x95, 0xf8, 0xdb, 0xd8, 0x69, 0x06, 0x33
	.byte 0x98, 0xff, 0x78, 0xcc, 0x00, 0xcf, 0x89, 0xc7
	.byte 0xf8, 0x99, 0xde, 0x12, 0xdb, 0x88, 0x1d, 0x23
	.byte 0x96, 0xf8, 0xeb, 0x8a, 0xbf, 0x16, 0x30, 0xde
	.byte 0x89, 0x1d, 0x7e, 0x91, 0xf8, 0xbf, 0x16, 0x31
	.byte 0xbf, 0x08, 0x30, 0xda, 0xaa, 0x1d, 0xab, 0x91
	.byte 0xf8, 0xbf, 0x08, 0x30, 0x41, 0x54, 0x02, 0xea
	.byte 0x00, 0x1d, 0xc7, 0x8b, 0xf8, 0xdb, 0xd8, 0x69
	.byte 0x07, 0x1d, 0xc2, 0x8b, 0xf8, 0x78, 0x91, 0x00
	.byte 0xd8, 0xaa, 0x1e, 0xdb, 0xed, 0xdb, 0xd8, 0x66
	.byte 0x7f, 0x1e, 0x6c, 0xef, 0xdb, 0xd8, 0x66, 0x05
	.byte 0x36, 0x96, 0xff, 0x68, 0x76, 0x9f, 0x20, 0x20
	.byte 0xd8, 0x12, 0x1d, 0x5a, 0x79, 0xf4, 0xbf, 0x04
	.byte 0x63, 0x1d, 0xef, 0x95, 0xf8, 0xdb, 0x88, 0xd9
	.byte 0xaa, 0x1d, 0x6f, 0x96, 0xf8, 0xaf, 0x04, 0xfb
	.byte 0x67, 0x51, 0x9f, 0x20, 0x20, 0xd8, 0x12, 0x1d
	.byte 0xda, 0x79, 0xf4, 0xeb, 0x8e, 0x9f, 0x20, 0x21
	.byte 0xe9, 0x12, 0xe9, 0xee, 0x0b, 0xf2, 0x00, 0xb0
	.byte 0x0a, 0x30, 0xe9, 0x80, 0x41, 0x00, 0x08, 0x00
	.byte 0x00, 0x1d, 0x74, 0x8d, 0xf8, 0xf2, 0x00, 0x00
	.byte 0x0b, 0x30, 0xee, 0x80, 0xaf, 0x04, 0x21, 0x1d
	.byte 0x74, 0x8d, 0xf8, 0x1d, 0xc2, 0x8b, 0xf8, 0xdb
	.byte 0x8e, 0x9f, 0x20, 0x20, 0xd8, 0x12, 0xde, 0x89
	.byte 0x1d, 0x26, 0x7a, 0xf4, 0xde, 0xd8, 0x61, 0x13
	.byte 0x9f, 0x20, 0x20, 0xd9, 0xa8, 0x1d, 0x93, 0x41
	.byte 0xf9, 0x68, 0x08, 0x36, 0x97, 0xff, 0x68, 0x03
	.byte 0x36, 0x9a, 0xff, 0x1d, 0x48, 0x8c, 0xf8, 0xde
	.byte 0x8b, 0x5e, 0xbf, 0x1e, 0x37, 0x0e, 0xbf, 0xe4
	.byte 0x37, 0x2e, 0xbf, 0x1a, 0x51, 0xbf, 0x1c, 0x50
	.byte 0x1d, 0xef, 0x95, 0xf8, 0xdb, 0xd8, 0x69, 0x05
	.byte 0x33, 0x98, 0xff, 0x68, 0x5c, 0xcf, 0x89, 0xc7
	.byte 0xf8, 0x99, 0xde, 0x12, 0xdb, 0x88, 0x1d, 0x23
	.byte 0x96, 0xf8, 0xeb, 0x8a, 0xbf, 0x10, 0x30, 0xde
	.byte 0x89, 0x1d, 0x7e, 0x91, 0xf8, 0xbf, 0x10, 0x31
	.byte 0xbf, 0x02, 0x30, 0xda, 0xab, 0x1d, 0xab, 0x91
	.byte 0xf8, 0xbf, 0x02, 0x30, 0x41, 0x58, 0x02, 0xea
	.byte 0x00, 0x1d, 0xc7, 0x8b, 0xf8, 0xdb, 0xd8, 0x69
	.byte 0x06, 0x1d, 0xc2, 0x8b, 0xf8, 0x68, 0x22, 0x1e
	.byte 0xcc, 0xed, 0xdb, 0xd8, 0x66, 0x12, 0x9f, 0x1c
	.byte 0x20, 0xd8, 0x12, 0x9f, 0x1a, 0x21, 0xd9, 0x12
	.byte 0x1d, 0xdd, 0xd8, 0xf6, 0xdb, 0x8e, 0x68, 0x03
	.byte 0x36, 0x9a, 0xff, 0x1d, 0x48, 0x8c, 0xf8, 0xde
	.byte 0x8b, 0x4e, 0xbf, 0x1c, 0x37, 0x0e, 0xbf, 0xd6
	.byte 0x37, 0x2e, 0xbf, 0x28, 0x51, 0xbf, 0x2a, 0x50
	.byte 0x1d, 0xef, 0x95, 0xf8, 0xdb, 0xd8, 0x69, 0x06
	.byte 0x33, 0x98, 0xff, 0x78, 0x39, 0x01, 0xcf, 0x89
	.byte 0xc7, 0xf8, 0x99, 0xde, 0x12, 0xdb, 0x88, 0x1d
	.byte 0x23, 0x96, 0xf8, 0xeb, 0x8a, 0xbf, 0x1e, 0x30
	.byte 0xde, 0x89, 0x1d, 0x7e, 0x91, 0xf8, 0xbf, 0x1e
	.byte 0x31, 0xbf, 0x10, 0x30, 0xda, 0xac, 0x1d, 0xab
	.byte 0x91, 0xf8, 0xbf, 0x10, 0x30, 0x41, 0x5c, 0x02
	.byte 0xea, 0x00, 0x1d, 0xc7, 0x8b, 0xf8, 0xdb, 0xd8
	.byte 0x69, 0x07, 0x1d, 0xc2, 0x8b, 0xf8, 0x78, 0xfe
	.byte 0x00, 0xd8, 0xac, 0x1e, 0x7a, 0xec, 0xdb, 0xd8
	.byte 0x6e, 0x0a, 0x1d, 0x48, 0x8c, 0xf8, 0x33, 0x9a
	.long LABEL_EB78FF
	.byte 0x9f, 0x2a, 0x20, 0x9f
	.byte 0x28, 0x26, 0xd8, 0xcf, 0x28, 0x00, 0x6f, 0x4e
	.byte 0xbf, 0x0a, 0x02, 0xd6, 0x01, 0xe8, 0x12, 0x41
	.byte 0xd6, 0x01, 0x00, 0x00, 0x1d, 0x5c, 0x0a, 0xff
	.byte 0xbf, 0x02, 0x63, 0x40, 0x10, 0x00, 0x00, 0x00
	.byte 0xaf, 0x02, 0x88, 0xde, 0x88, 0xe8, 0x12, 0x41
	.byte 0xd6, 0x01, 0x00, 0x00, 0x1d, 0x5c, 0x0a, 0xff
	.byte 0xbf, 0x06, 0x63, 0x40, 0x10, 0x00, 0x00, 0x00
	.byte 0xaf, 0x06, 0x88, 0xde, 0x88, 0xe8, 0x12, 0xd8
	.byte 0x0a, 0x14, 0x00, 0xbf, 0x0c, 0x41, 0xde, 0x88
	.byte 0xe8, 0x12, 0xd8, 0x0a, 0x14, 0x00, 0xd7, 0xe2
	.byte 0x88, 0xbf, 0x0e, 0x41, 0x68, 0x47, 0xd8, 0xca
	.byte 0x28, 0x00, 0xde, 0xca, 0x28, 0x00, 0xbf, 0x0a
	.byte 0x02, 0x50, 0x00, 0xe8, 0x12, 0xe8, 0x89, 0xe9
	.byte 0xee, 0x02, 0xe8, 0x81, 0xe9, 0xee, 0x04, 0xbf
	.byte 0x02, 0x61, 0x40, 0xa7, 0x4a, 0x00, 0x00, 0xaf
	.byte 0x02, 0x88, 0xde, 0x88, 0xe8, 0x12, 0xe8, 0x89
	.byte 0xe9, 0xee, 0x02, 0xe8, 0x81, 0xe9, 0xee, 0x04
	.byte 0xbf, 0x06, 0x61, 0x40, 0xa7, 0x4a, 0x00, 0x00
	.byte 0xaf, 0x06, 0x88, 0xbf, 0x0c, 0x00, 0x40, 0xc7
	.byte 0xf8, 0x89, 0xbf, 0x0e, 0x41, 0xaf, 0x02, 0x20
	.byte 0xd9, 0xa8, 0x1d, 0xe0, 0x8e, 0xf8, 0xdb, 0x8e
	.byte 0xde, 0xd8, 0x61, 0x35, 0x8f, 0x0c, 0x21, 0xd8
	.byte 0x12, 0x8f, 0x0e, 0x23, 0xd9, 0x12, 0x1d, 0x4a
	.byte 0x05, 0xff, 0xf2, 0x00, 0x00, 0x1e, 0x30, 0xaf
	.byte 0x06, 0x80, 0x9f, 0x0a, 0x21, 0xe9, 0x12, 0x1d
	.byte 0x74, 0x8d, 0xf8, 0x1d, 0xc2, 0x8b, 0xf8, 0xdb
	.byte 0x8e, 0x8f, 0x0c, 0x21, 0xd8, 0x12, 0x8f, 0x0e
	.byte 0x23, 0xd9, 0x12, 0xde, 0x8a, 0x1d, 0x4b, 0x05
	.byte 0xff, 0x1d, 0x48, 0x8c, 0xf8, 0xde, 0x8b, 0x4e
	.byte 0xbf, 0x2a, 0x37, 0x0e, 0xbf, 0xdc, 0x37, 0x3e
	.byte 0xbf, 0x24, 0x51, 0xbf, 0x26, 0x50, 0x1d, 0xef
	.byte 0x95, 0xf8, 0xdb, 0xd8, 0x69, 0x06, 0x33, 0x98
	.long LABEL_E678FF
	.byte 0xcf, 0x89, 0xc7, 0xf8
	.byte 0x99, 0xde, 0x12, 0xdb, 0x88, 0x1d, 0x23, 0x96
	.byte 0xf8, 0xeb, 0x8a, 0xbf, 0x1a, 0x30, 0xde, 0x89
	.byte 0x1d, 0x7e, 0x91, 0xf8, 0xbf, 0x1a, 0x31, 0xbf
	.byte 0x0c, 0x30, 0xda, 0xac, 0x1d, 0xab, 0x91, 0xf8
	.byte 0xbf, 0x0c, 0x30, 0x41, 0x60, 0x02, 0xea, 0x00
	.byte 0x1d, 0xc7, 0x8b, 0xf8, 0xdb, 0xd8, 0x69, 0x07
	.byte 0x1d, 0xc2, 0x8b, 0xf8, 0x78, 0xab, 0x00, 0xd8
	.byte 0xac, 0x1e, 0x24, 0xeb, 0xdb, 0xd8, 0x6e, 0x0a
	.byte 0x1d, 0x48, 0x8c, 0xf8, 0x33, 0x9a, 0xff, 0x78
	.byte 0x98, 0x00, 0x9f, 0x26, 0x3f, 0x02, 0x00, 0x6f
	.byte 0x3c, 0xbf, 0x08, 0x02, 0xb8, 0x24, 0x9f, 0x26
	.byte 0x20, 0xe8, 0x12, 0x41, 0xb8, 0x24, 0x00, 0x00
	.byte 0x1d, 0x5c, 0x0a, 0xff, 0xeb, 0x8e, 0xee, 0xc8
	.byte 0x10, 0x00, 0x00, 0x00, 0x9f, 0x24, 0x20, 0xe8
	.byte 0x12, 0x41, 0xb8, 0x24, 0x00, 0x00, 0x1d, 0x5c
	.byte 0x0a, 0xff, 0xbf, 0x04, 0x63, 0x40, 0x10, 0x00
	.byte 0x00, 0x00, 0xaf, 0x04, 0x88, 0x9f, 0x24, 0x20
	.byte 0xbf, 0x0a, 0x41, 0x68, 0x16, 0xbf, 0x08, 0x02
	.byte 0x27, 0x29, 0x46, 0x80, 0x49, 0x00, 0x00, 0x40
	.byte 0x80, 0x49, 0x00, 0x00, 0xbf, 0x04, 0x60, 0xbf
	.byte 0x0a, 0x00, 0x40, 0xee, 0x88, 0xd9, 0xa8, 0x1d
	.byte 0xe0, 0x8e, 0xf8, 0xdb, 0x8e, 0xde, 0xd8, 0x61
	.byte 0x2b, 0x8f, 0x0a, 0x21, 0xd8, 0x12, 0x1d, 0xe5
	.byte 0x05, 0xff, 0xf2, 0x00, 0x00, 0x1e, 0x30, 0xaf
	.byte 0x04, 0x80, 0x9f, 0x08, 0x21, 0xe9, 0x12, 0x1d
	.byte 0x74, 0x8d, 0xf8, 0x1d, 0xc2, 0x8b, 0xf8, 0xdb
	.byte 0x8e, 0x8f, 0x0a, 0x21, 0xd8, 0x12, 0xde, 0x89
	.byte 0x1d, 0xe6, 0x05, 0xff, 0x1d, 0x48, 0x8c, 0xf8
	.byte 0xde, 0x8b, 0x5e, 0xbf, 0x24, 0x37, 0x0e

ReadSingleFile:
	lda xsp, (xsp - 24)
	push xiz
	ldi_werp 0xFA, 0
	call GetCurrentFileIndex
	ld iz, hl
	cps iz, 0
	jr ge, ReadSingle_SetupEntry
	ldw hl, 0xFF98
	jr ReadSingle_Return

ReadSingle_SetupEntry:
	ld wa, iz
	call GetFileEntryPtr
	ld xde, xhl
	ldto_berp C, 0xF8
	extz bc
	lda xwa, (xsp + 18)
	call FileIO_FormatFileIndex
	lds iz, 0

ReadSingle_RetryLoop:
	lda_24 xwa, 0xea00fa
	ld_srib3 A, 0x07, 0xE0, 0xF8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, ReadSingle_LoopNext
	lda xbc, (xsp + 18)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
	lda xwa, (xsp + 4)
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	call FileIO_OpenDefault
	ldfr_werp HL, 0xFA
	cpi_werp 0xFA, 0
	jr lt, ReadSingle_StoreResult

ReadSingle_LoopNext:
	inc 1, iz
	cp iz, 0xA
	jr lt, ReadSingle_RetryLoop

ReadSingle_StoreResult:
	ldto_werp HL, 0xFA

ReadSingle_Return:
	pop xiz
	lda xsp, (xsp + 24)
	ret

ReadDualFile:
	lda xsp, (xsp - 52)
	push xiz
	ld (xsp + 52), xwa
	ldi_werp 0xFA, 0
	call GetCurrentFileIndex
	ld iz, hl
	cps iz, 0
	jr ge, ReadDual_SetupEntries
	ldw hl, 0xFF98
	jr ReadDual_Return

ReadDual_SetupEntries:
	ld wa, iz
	call GetFileEntryPtr
	ld xde, xhl
	ldto_berp C, 0xF8
	extz bc
	lda xwa, (xsp + 32)
	call FileIO_FormatFileIndex
	ldto_berp C, 0xF8
	extz bc
	lda xwa, (xsp + 42)
	ld xde, (xsp + 52)
	call FileIO_FormatFileIndex
	lds iz, 0

ReadDual_RetryLoop:
	lda_24 xwa, 0xea00fa
	ld_srib3 A, 0x07, 0xE0, 0xF8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, ReadDual_LoopNext
	lda xbc, (xsp + 32)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
	lda xwa, (xsp + 4)
	call FileIO_ReadHeader
	lda xbc, (xsp + 42)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
	lda xwa, (xsp + 18)
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 18)
	call FileIO_CopyAndOpen
	ldfr_werp HL, 0xFA
	cpi_werp 0xFA, 0
	jr lt, ReadDual_StoreResult

ReadDual_LoopNext:
	inc 1, iz
	cp iz, 0xA
	jr lt, ReadDual_RetryLoop

ReadDual_StoreResult:
	ldto_werp HL, 0xFA

ReadDual_Return:
	pop xiz
	lda xsp, (xsp + 52)
	ret

ReadDualFileEx:
	lda xsp, (xsp - 60)
	push xiz
	ld (xsp + 62), wa
	ldi_werp 0xFA, 0
	call GetCurrentFileIndex
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jr ge, ReadDualEx_SetupPages
	ldw hl, 0xFF98
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
	lds iz, 0

ReadDualEx_FirstLoop:
	lda_24 xwa, 0xea00fa
	ld_srib3 C, 0x07, 0xE0, 0xF8
	ld wa, (xsp + 62)
	call FileIO_CheckRecordByFile
	cps l, 0
	jr z, ReadDualEx_FirstLoopNext
	lda xbc, (xsp + 52)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
	lda xwa, (xsp + 28)
	call FileIO_ReadHeader
	lda xbc, (xsp + 42)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
	lda xwa, (xsp + 14)
	call FileIO_ReadHeader
	lda xwa, (xsp + 28)
	lda xbc, (xsp + 14)
	call FileIO_CopyAndOpen
	ldfr_werp HL, 0xFA
	cpi_werp 0xFA, 0
	jrl lt, ReadDualEx_StoreResult

ReadDualEx_FirstLoopNext:
	inc 1, iz
	cp iz, 0xA
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
	lds iz, 0

ReadDualEx_SecondLoop:
	lda_24 xwa, 0xea00fa
	ld_srib3 A, 0x07, 0xE0, 0xF8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, ReadDualEx_SecondLoopNext
	lda xbc, (xsp + 52)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
	lda xwa, (xsp + 28)
	call FileIO_ReadHeader
	lda xbc, (xsp + 42)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
	lda xwa, (xsp + 14)
	call FileIO_ReadHeader
	lda xwa, (xsp + 28)
	lda xbc, (xsp + 14)
	call FileIO_CopyAndOpen
	ldfr_werp HL, 0xFA
	cpi_werp 0xFA, 0
	jr lt, ReadDualEx_StoreResult

ReadDualEx_SecondLoopNext:
	inc 1, iz
	cp iz, 0xA
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
	lds iz, 0

ReadDualEx_ThirdLoop:
	lda_24 xwa, 0xea00fa
	ld_srib3 C, 0x07, 0xE0, 0xF8
	ld wa, (xsp + 62)
	call FileIO_CheckRecordByFile
	cps l, 0
	jr z, ReadDualEx_ThirdLoopNext
	lda xbc, (xsp + 52)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
	lda xwa, (xsp + 28)
	call FileIO_ReadHeader
	lda xbc, (xsp + 42)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
	lda xwa, (xsp + 14)
	call FileIO_ReadHeader
	lda xwa, (xsp + 28)
	lda xbc, (xsp + 14)
	call FileIO_CopyAndOpen
	ldfr_werp HL, 0xFA
	cpi_werp 0xFA, 0
	jr lt, ReadDualEx_StoreResult

ReadDualEx_ThirdLoopNext:
	inc 1, iz
	cp iz, 0xA
	jr lt, ReadDualEx_ThirdLoop

ReadDualEx_StoreResult:
	ldto_werp HL, 0xFA

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
	ldw hl, 0xFF98
	jrl WriteVerify_Return

WriteVerify_InitCounters:
	lds32 xwa, 0
	ld (xsp + 8), xwa
	lds iz, 0

WriteVerify_WriteLoop:
	lda_24 xwa, 0xea00fa
	ld_srib3 A, 0x07, 0xE0, 0xF8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, WriteVerify_WriteLoopNext
	ld wa, (xsp + 4)
	lda_24 xbc, 0xea00fa
	ld_srib3 C, 0x07, 0xE4, 0xF8
	call UpdateFileEntry
	add (xsp + 8), xhl

WriteVerify_WriteLoopNext:
	inc 1, iz
	cp iz, 0xA
	jr lt, WriteVerify_WriteLoop
	call FileIO_GetDiskFreeSpace
	cp xhl, (xsp + 8)
	jr ge, WriteVerify_SetupReadback
	ldw hl, 0xFF9B
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
	lds iz, 0

WriteVerify_ReadbackLoop:
	lda_24 xwa, 0xea00fa
	ld_srib3 C, 0x07, 0xE0, 0xF8
	ld wa, (xsp + 60)
	call FileIO_CheckRecordByFile
	cps l, 0
	jr z, WriteVerify_ReadbackNext
	lda xbc, (xsp + 50)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
	lda xwa, (xsp + 26)
	call FileIO_ReadHeader
	lda xwa, (xsp + 26)
	call FileIO_OpenDefault
	ld (xsp + 6), hl
	cpw (xsp + 6), 0x0
	jrl lt, WriteVerify_GetStatus

WriteVerify_ReadbackNext:
	inc 1, iz
	cp iz, 0xA
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
	lds iz, 0

WriteVerify_CrossVerifyLoop:
	lda_24 xwa, 0xea00fa
	ld_srib3 A, 0x07, 0xE0, 0xF8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, WriteVerify_CrossVerifyNext
	lda xbc, (xsp + 50)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
	lda xwa, (xsp + 26)
	call FileIO_ReadHeader
	lda xbc, (xsp + 40)
	lda_24 xwa, 0xea00fa
	ld_srib3 E, 0x07, 0xE0, 0xF8
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
	cp iz, 0xA
	jr lt, WriteVerify_CrossVerifyLoop

WriteVerify_GetStatus:
	ld hl, (xsp + 6)

WriteVerify_Return:
	pop xiz
	lda xsp, (xsp + 58)
	ret

GetFirstRecordAndOpen:
	call GetFirstPageBase
	cps hl, 0
	jr ge, GetFirstRecord_GotPage
	ldw hl, 0xFF98
	ret

GetFirstRecord_GotPage:
	ld wa, hl
	call GetRecordPtrForFile
	ld xwa, xhl
	jp FileIO_OpenDefault

SearchAndOpen:
	st_dri3b L, 0xFD, 0xF2, 0xFE
	pushw iz
	st_dri3l XWA, 0xFD, 0x0C, 0x01
	call GetFirstPageBase
	ld iz, hl
	cps iz, 0
	jr ge, SearchOpen_DoSearch
	ldw hl, 0xFF98
	jr SearchOpen_Return

SearchOpen_DoSearch:
	lda xbc, (xsp + 2)
	ld_sril XWA, (xsp + 0x010c)
	call _findfirst
	ld xwa, xhl
	cp xwa, 0x0
	jr ge, SearchOpen_AlreadyExists
	ld wa, iz
	call GetRecordPtrForFile
	ld xwa, xhl
	ld_sril XBC, (xsp + 0x010c)
	call FileIO_CopyAndOpen
	jr SearchOpen_Return

SearchOpen_AlreadyExists:
	call _findclose
	ldw hl, 0xFFF6

SearchOpen_Return:
	popw iz
	st_dri3b L, 0xFD, 0x0E, 0x01
	ret

LoadFromSecondaryPage:
	pushw iz
	call LABEL_F8B015
	cps hl, 0
	jr ge, LoadSecondary_OpenFile
	ldw hl, 0xFF98
	jr LoadSecondary_Return

LoadSecondary_OpenFile:
	ld wa, hl
	call LABEL_F8B13D
	ld xwa, xhl
	ld xbc, 0xEA0264
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadSecondary_Process
	call FileIO_ReturnError
	jr LoadSecondary_Return

LoadSecondary_Process:
	call LABEL_FAE86D
	ld iz, hl
	call FileIO_CloseHandle
	ld hl, iz

LoadSecondary_Return:
	popw iz
	ret

FileIO_ReturnError:
	ldda16 xhl, 32584
	ret

FileIO_OpenWithMode:
	lda xsp, (xsp - 128)
	push xiz
	ld xiz, xbc
	ld xde, xwa
	ld xiy, 0xEA0268
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
	stda32 32580, xhl
	or xhl, xhl
	jr nz, FileIO_OpenMode_Success
	cp (xiz), 0x72
	jr nz, FileIO_OpenMode_CheckWrite
	stdi16 32584, 65534
	ldw hl, 0xFFFE
	jr FileIO_OpenMode_Return

FileIO_OpenMode_CheckWrite:
	cp (xiz), 0x77
	jr nz, FileIO_OpenMode_UnknownMode
	cpdi16_24 124220, 31
	jr nz, FileIO_OpenMode_WriteMaxFiles
	stdi16 32584, 65525
	ldw hl, 0xFFF5
	jr FileIO_OpenMode_Return

FileIO_OpenMode_WriteMaxFiles:
	stdi16 32584, 65533
	ldw hl, 0xFFFD
	jr FileIO_OpenMode_Return

FileIO_OpenMode_UnknownMode:
	stdi16 32584, 65535
	ldw hl, 0xFFFF
	jr FileIO_OpenMode_Return

FileIO_OpenMode_Success:
	stdi16 32584, 0
	ldda16 xhl, 32584

FileIO_OpenMode_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x80, 0x00
	ret

FileIO_CloseHandle:
	ldda32 xwa, 32580
	or xwa, xwa
	jr z, FileIO_CloseHandle_Done
	push xwa
	call FileClose
	inc 4, xsp
	lds32 xwa, 0
	stda32 32580, xwa

FileIO_CloseHandle_Done:
	lds hl, 0
	ret

FileIO_OpenDefault:
	lda xsp, (xsp - 16)
	ld xde, xwa
	ld xiy, 0xEA02E8
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
	cps hl, 0
	jr nz, FileIO_OpenDefault_CheckMaxFiles
	lds hl, 0
	jr FileIO_OpenDefault_Return

FileIO_OpenDefault_CheckMaxFiles:
	cp hl, 0x1F
	jr nz, FileIO_OpenDefault_OtherError
	ldw hl, 0xFFF5
	jr FileIO_OpenDefault_Return

FileIO_OpenDefault_OtherError:
	ldw hl, 0xFFFD

FileIO_OpenDefault_Return:
	lda xsp, (xsp + 16)
	ret

FileIO_CopyAndOpen:
	lda xsp, (xsp - 32)
	push xiz
	ld xiz, xbc
	ld xde, xwa
	ld xiy, 0xEA02F8
	lda xix, (xsp + 20)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xEA0308
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
	cps hl, 0
	jr nz, FileIO_CopyOpen_CheckMaxFiles
	lds hl, 0
	jr FileIO_CopyOpen_Return

FileIO_CopyOpen_CheckMaxFiles:
	cpdi16_24 124220, 31
	jr nz, FileIO_CopyOpen_OtherError
	ldw hl, 0xFFF5
	jr FileIO_CopyOpen_Return

FileIO_CopyOpen_OtherError:
	ldw hl, 0xFFFD

FileIO_CopyOpen_Return:
	pop xiz
	lda xsp, (xsp + 32)
	ret

FileIO_ReadByte:
	ldda32 xwa, 32580
	or xwa, xwa
	jr z, FileIO_ReadByte_NoHandle
	push xwa
	call SeqStep_FileReadReturn
	inc 4, xsp
	cps hl, 0
	jr ge, FileIO_ReadByte_CheckEOF
	ldw hl, 0xFFFE
	jr FileIO_ReadByte_Return

FileIO_ReadByte_NoHandle:
	ldw hl, 0xFF9C
	jr FileIO_ReadByte_Return

FileIO_ReadByte_CheckEOF:
	cps hl, 0
	ret ge

FileIO_ReadByte_Return:
	ldda16 xwa, 32584
	cps wa, 0
	jr lt, FileIO_ReadByte_Extended
	ld wa, hl

FileIO_ReadByte_Extended:
	stda16 32584, xwa
	ret

FileIO_ReadByte_BufferHit:
	pushw iz
	lds iz, 0
	ldda32 xbc, 32580
	or xbc, xbc
	jr z, FileIO_SeekAndRead_Error
	push xbc
	extz wa
	pushw wa
	call SeqStep_FileWriteSetup
	inc 6, xsp
	cps hl, 0
	jr ge, FileIO_SeekAndRead_Return
	ldda32 xwa, 32580
	ld wa, (xwa + 6)
	res 15, wa
	cp wa, 0x1F
	jr nz, FileIO_SeekAndRead_NoHandle
	ldw iz, 0xFFF5
	jr FileIO_SeekAndRead_Return

FileIO_SeekAndRead_NoHandle:
	ldw iz, 0xFFFD
	jr FileIO_SeekAndRead_Return

FileIO_SeekAndRead_Error:
	ldw iz, 0xFF9C

FileIO_SeekAndRead_Return:
	ldda16 xwa, 32584
	cps wa, 0
	jr lt, FileIO_SeekToOffset
	ld wa, iz

FileIO_SeekToOffset:
	stda16 32584, xwa
	ld hl, iz
	popw iz
	ret

FileIO_ReadBlock:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 18), xwa
	ldw (xsp + 4), 0x0
	lds32 xwa, 0
	ld (xsp + 6), xwa
	ldda32 xwa, 32580
	or xwa, xwa
	jr z, FileIO_WriteBlock_LoopNext
	ld (xsp + 14), xbc
	cp xbc, 0x0
	jr le, FileIO_WriteBlock_Error

FileIO_ReadBlock_Loop:
	ld xiz, 0x7FFF
	ld xwa, (xsp + 14)
	cp xwa, 0x7FFF
	jr ge, FileIO_ReadBlock_Done
	ld xiz, (xsp + 14)

FileIO_ReadBlock_Done:
	ld (xsp + 10), xiz
	ldda32 xwa, 32580
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
	ldda32 xwa, 32580
	ld wa, (xwa + 6)
	bit 15, wa
	jr z, FileIO_WriteBlock_CheckResult
	add (xsp + 6), xhl
	jr FileIO_WriteBlock_Error

FileIO_WriteBlock_CheckResult:
	ldw (xsp + 4), 0xFFFE
	jr FileIO_WriteBlock_Return

FileIO_WriteBlock_LoopNext:
	ldw (xsp + 4), 0xFF9C
	jr FileIO_WriteBlock_Return

FileIO_WriteBlock_Error:
	cpw (xsp + 4), 0x0
	jr ge, FileIO_WriteByte

FileIO_WriteBlock_Return:
	ldda16 xwa, 32584
	cps wa, 0
	jr lt, FileIO_WriteWord
	ld wa, (xsp + 4)

FileIO_WriteWord:
	stda16 32584, xwa
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
	ldda32 xwa, 32580
	or xwa, xwa
	jr z, FileIO_FlushAndClose
	ld xwa, (xsp + 14)
	ld (xsp + 10), xwa
	cp xwa, 0x0
	jr le, FileIO_FlushClose_Return

FileIO_WriteByte_NoHandle:
	ld xiz, 0x7FFF
	ld xwa, (xsp + 10)
	cp xwa, 0x7FFF
	jr ge, FileIO_WriteByte_Return
	ld xiz, (xsp + 10)

FileIO_WriteByte_Return:
	ld (xsp + 6), xiz
	ldda32 xwa, 32580
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
	ldda32 xwa, 32580
	ld wa, (xwa + 6)
	res 15, wa
	cp wa, 0x1F
	jr nz, FileIO_FlushBuffer
	ldw (xsp + 4), 0xFFF5
	jr FileIO_GetPosition

FileIO_FlushBuffer:
	ldw (xsp + 4), 0xFFFD
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
	ldw (xsp + 4), 0xFF9C
	jr FileIO_GetPosition

FileIO_FlushClose_Return:
	cpw (xsp + 4), 0x0
	jr ge, FileIO_CheckHandle

FileIO_GetPosition:
	ldda16 xwa, 32584
	cps wa, 0
	jr lt, FileIO_GetPosition_Return
	ld wa, (xsp + 4)

FileIO_GetPosition_Return:
	stda16 32584, xwa
	ld wa, (xsp + 4)
	exts xwa
	ld (xsp + 14), xwa

FileIO_CheckHandle:
	ld xhl, (xsp + 14)
	pop xiz
	lda xsp, (xsp + 18)
	ret

FileIO_SeekAndReadBlock:
	ldda32 xde, 32580
	or xde, xde
	jr z, FileIO_SeekRead_NoHandle
	pushw bc
	push xwa
	push xde
	call SeqStep_FileSeekSetup
	add xsp, 0xA
	cps hl, 0
	jr z, FileIO_SeekRead_Return
	ldw hl, 0xFFFB
	jr FileIO_SeekRead_Return

FileIO_SeekRead_NoHandle:
	ldw hl, 0xFF9C

FileIO_SeekRead_Return:
	ldda16 xwa, 32584
	cps wa, 0
	jr lt, FileIO_SeekRead_Extended
	ld wa, hl

FileIO_SeekRead_Extended:
	stda16 32584, xwa
	ret

FileIO_SeekRead_ExtReturn:
	pushw iz
	lds iz, 0
	ldda32 xwa, 32580
	or xwa, xwa
	jr z, FileIO_SeekWrite_NoHandle
	push xwa
	call SeqStep_FileIoHelper
	inc 4, xsp
	jr FileIO_SeekWrite_Return

FileIO_SeekWrite_NoHandle:
	ldw iz, 0xFF9C

FileIO_SeekWrite_Return:
	ldda16 xwa, 32584
	cps wa, 0
	jr lt, FileIO_SeekWriteBlock
	ld wa, iz

FileIO_SeekWriteBlock:
	stda16 32584, xwa
	ld hl, iz
	popw iz
	ret

FileIO_SeekWriteBlock_Impl:
	ldda32 xwa, 32580
	or xwa, xwa
	jr z, FileIO_SeekWriteBlock_NoHandle
	push xwa
	call SeqStep_FileSeekStore
	inc 4, xsp
	cp xhl, 0x0
	jr ge, FileIO_SeekWriteBlock_Error
	ld xhl, 0xFFFFFFFB
	jr FileIO_SeekWriteBlock_Return

FileIO_SeekWriteBlock_NoHandle:
	ld xhl, 0xFFFFFF9C
	jr FileIO_SeekWriteBlock_Return

FileIO_SeekWriteBlock_Error:
	cp xhl, 0x0
	ret ge

FileIO_SeekWriteBlock_Return:
	ldda16 xwa, 32584
	cps wa, 0
	jr lt, FileIO_SeekWriteBlock_Done
	ld wa, hl

FileIO_SeekWriteBlock_Done:
	stda16 32584, xwa
	ret

FileIO_CompareFiles:
	lda xsp, (xsp - 50)
	pushw iz
	ld (xsp + 48), xbc
	ld xde, xwa
	ldw (xsp + 10), 0x0
	ld xiy, 0xEA0318
	lda xix, (xsp + 32)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xEA0328
	lda xix, (xsp + 16)
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp + 16)
	ld xbc, xde
	call FileIO_BuildFilePath
	pushw 0xEA
	pushw 0x338
	lda xwa, (xsp + 20)
	push xwa
	call FileOpen
	inc 8, xsp
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr nz, FileIO_Compare_Return
	cpdi16_24 124220, 31
	jr nz, FileIO_Compare_Mismatch
	ldw hl, 0xFFF5
	jrl FileIO_ParseHeader_Error

FileIO_Compare_Mismatch:
	ldw hl, 0xFFFD
	jrl FileIO_ParseHeader_Error

FileIO_Compare_Return:
	lda xwa, (xsp + 32)
	ld xbc, (xsp + 48)
	call FileIO_BuildFilePath
	pushw 0xEA
	pushw 0x33C
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
	ldw hl, 0xFFFE
	jr FileIO_ParseHeader_Error

FileIO_ParseHeader_CheckType:
	lda_24 xwa, 0x069800
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
	cps iz, 0
	jr gt, FileIO_ParseHeader_Return
	cpw (xsp + 10), 0x0
	jr lt, FileIO_ParseHeader_Done
	ld xwa, (xsp + 2)
	ld wa, (xwa + 6)
	bit 15, wa
	jr nz, FileIO_ParseHeader_Done
	ldw (xsp + 10), 0xFFFE

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
	ldda32 xwa, 32580
	ld wa, (xwa + 6)
	res 15, wa
	cp wa, 0x1F
	jr nz, FileIO_ValidateRecord
	ldw (xsp + 10), 0xFFF5
	jr FileIO_ParseHeader_Done

FileIO_ValidateRecord:
	ldw (xsp + 10), 0xFFFD
	jr FileIO_ParseHeader_Done

FileIO_ValidateRecord_CheckSize:
	extz wa
	call format_FD
	cps hl, 0
	jr z, FileIO_ValidateRecord_Fail
	lds hl, 0
	ret

FileIO_ValidateRecord_Fail:
	cpdi16_24 124220, 31
	jr nz, FileIO_ValidateRecord_Ok
	ldw hl, 0xFFF5
	ret

FileIO_ValidateRecord_Ok:
	ldw hl, 0xFFFA
	ret

FileIO_ValidateRecord_Return:
	sti16_24 0x0272cc, 0x003f
	sti16_24 0x0272ce, 0x003f
	sti8_24 0x0272d0, 0x00
	ld xwa, 0x25EAA
	ld xbc, 0xEA044A
	calr FileIO_CopyString
	ld xwa, 0x271F2
	ld xbc, 0xEA0452	; pointer to "________.MID"
	jr __jrt_nop_F890DC
__jrt_nop_F890DC:

FileIO_CopyString:
	ld xde, xbc
	cp (xde), 0x0
	jr z, FileIO_CopyString_Done

FileIO_CopyString_Loop:
	ld_spib C, 0xE8
	lda_dpi XHL, 0xE0
	cp (xde), 0x0
	jr nz, FileIO_CopyString_Loop

FileIO_CopyString_Done:
	ld (xwa), 0x0
	ret

FileIO_CopyString_WriteNull:
	ld xhl, xbc
	jr FileIO_CopyString_CheckEnd

FileIO_CopyString_Advance:
	ld_spib C, 0xEC
	lda_dpi XHL, 0xE0
	dec 1, de

FileIO_CopyString_CheckEnd:
	cps de, 0
	jr z, FileIO_CopyString_StoreAndCont
	cp (xhl), 0x0
	jr nz, FileIO_CopyString_Advance

FileIO_CopyString_StoreAndCont:
	cps de, 0
	ret z

FileIO_CopyString_Return:
	stib_dpi 0xE0, 0x00
	djnz xde, FileIO_CopyString_Return
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
	ld_spib C, 0xE8
	lda_dpi XHL, 0xE0
	cp (xde), 0x0
	jr nz, FileIO_BuildPath_AddSep

FileIO_BuildPath_Return:
	ld (xwa), 0x0
	ret

FileIO_SearchFile:
	ld xhl, xwa
	jr FileIO_Search_CheckNext

FileIO_Search_CompareChar:
	cps e, 0
	jr nz, FileIO_Search_Match
	lds hl, 0
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
	lds hl, 0
	ret

FileIO_Search_Found:
	inc 1, xhl
	inc 1, xbc
	dec 1, de

FileIO_Search_NotFound:
	cps de, 0
	jr z, FileIO_Search_Error
	ld a, (xbc)
	cp a, (xhl)
	jr z, FileIO_Search_EndOfList

FileIO_Search_Error:
	ldb a, 0x0
	cps de, 0
	jr z, FileIO_Search_Return
	ld a, (xhl)
	sub a, (xbc)

FileIO_Search_Return:
	ld l, a
	exts hl
	ret

FileIO_FormatFileIndex:
	inc 1, c
	cp c, 0xA
	jr nc, FileIO_FormatIndex_TwoDigit
	stib_dpi 0xE0, 0x30
	jr FileIO_FormatIndex_AddChar

FileIO_FormatIndex_TwoDigit:
	cp c, 0x14
	jr nc, FileIO_FormatIndex_AddOnes
	stib_dpi 0xE0, 0x31
	sub c, 0xA
	jr FileIO_FormatIndex_AddChar

FileIO_FormatIndex_AddOnes:
	stib_dpi 0xE0, 0x32
	sub c, 0x14

FileIO_FormatIndex_AddChar:
	add c, 0x30
	lda_dpi XHL, 0xE0
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
	ld xbc, 0xEA0460
	calr FileIO_BuildFilePath
	ld a, (xsp + 4)
	extz wa
	sla wa, 2
	lda_24 xbc, 0xea0340
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	ld xwa, xiz
	calr FileIO_BuildFilePath
	pop xiz
	inc 2, xsp
	ret

FileIO_ReadHeader_ParseLoop:
	pushw iz
	cp de, 0x64
	jr c, FileIO_ReadHeader_Done
	st_dpib D, 0xE0
	ld hl, de
	extz xhl
	div hl, 0x64
	add l, 0x30
	ld (xix), l
	sub de, 0x64
	st_dpib D, 0xE0
	ld hl, de
	extz xhl
	div hl, 0xA
	add l, 0x30
	ld (xix), l
	extz xde
	div de, 0xA
	ldto_werp DE, 0xEA
	add e, 0x30
	ld (xwa), e
	jr FileIO_ReadHeader_Field1

FileIO_ReadHeader_Done:
	st_dpib D, 0xE0
	ld hl, de
	extz xhl
	div hl, 0xA
	add l, 0x30
	ld (xix), l
	st_dpib C, 0xE0
	extz xde
	div de, 0xA
	ldto_werp DE, 0xEA
	add e, 0x30
	ld (xhl), e
	ld (xwa), 0x3A

FileIO_ReadHeader_Field1:
	inc 1, xwa
	stib_dpi 0xE0, 0x20
	lds iy, 0
	lds iz, 0
	jr FileIO_ReadHeader_Return

FileIO_ReadHeader_Field2:
	add xde, xwa
	cp l, 0x7E
	jr nz, FileIO_ReadHeader_Field3
	ld (xde), 0x5F
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
	cps l, 0
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
	cp (xwa), 0x7E
	jr nz, FileIO_GetRecordType_Return
	ldb c, 0x5F
	jr FileIO_GetRecordType_ReturnOk

FileIO_GetRecordType_Return:
	cp (xwa), 0x20
	jr nc, FileIO_GetRecordType_Alt
	ldb c, 0x20

FileIO_GetRecordType_ReturnOk:
	ld (xwa), c

FileIO_GetRecordType_Alt:
	inc 1, xwa
	cp (xwa), 0x0
	jr nz, FileIO_GetRecordType_Error
	ret

FileIO_GetRecordByType:
	lda_24 xhl, 0x025eaa
	ret

FileIO_GetRecordByType_Lookup:
	ld xbc, xwa
	ld xwa, 0x25EAA
	lds de, 6
	calr FileIO_CopyString_WriteNull
	sti8_24 0x025eb0, 0x00
	ret

FileIO_GetRecordPtrAlt:
	lda_24 xhl, 0x0271f2
	ret

FileIO_WriteRecordName:
	ld xbc, xwa
	ld xwa, 0x271F2
	ldw de, 0xC
	calr FileIO_CopyString_WriteNull
	sti8_24 0x0271fe, 0x00
	ret

FileIO_WriteRecordName_Loop:
	ld16_24 xhl, 0x0272cc
	ret

FileIO_WriteRecordName_Done:
	ld16_24 xbc, 0x025ea8
	cps bc, 0
	jr lt, FileIO_WriteRecordName_Pad
	cp bc, 0x14
	jr ge, FileIO_WriteRecordName_Pad
	cp a, 0xA
	jr c, FileIO_WriteRecordName_Return

FileIO_WriteRecordName_Pad:
	ldb l, 0x0
	ret

FileIO_WriteRecordName_Return:
	lds bc, 1
	and a, 0xF
	jr z, FileIO_FormatRecordName
	slla bc

FileIO_FormatRecordName:
	ld16_24 xwa, 0x0272cc
	and wa, bc
	cp wa, bc
	scc8 z, l
	ret

FileIO_FormatName_Loop:
	cp a, 0xA
	ret nc
	lds bc, 1
	and a, 0xF
	jr z, FileIO_FormatName_NoPrefix
	slla bc

FileIO_FormatName_NoPrefix:
	ordm16_24 160460, xbc
	ret

FileIO_FormatName_Copy:
	cp a, 0xA
	ret nc
	lds bc, 1
	and a, 0xF
	jr z, FileIO_FormatName_CopyLoop
	slla bc

FileIO_FormatName_CopyLoop:
	xor bc, 0xFFFF
	anddm16_24 160460, xbc
	ret

FileIO_FormatName_Done:
	ld16_24 xhl, 0x0272ce
	ret

FileIO_FormatName_Return:
	ld16_24 xbc, 0x025ea8
	cps bc, 0
	jr lt, FileIO_BuildRecordPath
	cp bc, 0x14
	jr ge, FileIO_BuildRecordPath
	cp a, 0xA
	jr c, FileIO_BuildRecordPath_Loop

FileIO_BuildRecordPath:
	ldb l, 0x0
	ret

FileIO_BuildRecordPath_Loop:
	lds bc, 1
	and a, 0xF
	jr z, FileIO_BuildRecordPath_AddExt
	slla bc

FileIO_BuildRecordPath_AddExt:
	ld16_24 xwa, 0x0272ce
	and wa, bc
	cp wa, bc
	scc8 z, l
	ret

FileIO_BuildRecordPath_Done:
	cp a, 0xA
	ret nc
	lds bc, 1
	and a, 0xF
	jr z, FileIO_BuildRecordPath_Error
	slla bc

FileIO_BuildRecordPath_Error:
	ordm16_24 160462, xbc
	ret

FileIO_BuildRecordPath_Return:
	cp a, 0xA
	ret nc
	lds bc, 1
	and a, 0xF
	jr z, FileIO_GetRecordAttr
	slla bc

FileIO_GetRecordAttr:
	xor bc, 0xFFFF
	anddm16_24 160462, xbc
	ret

FileIO_GetRecordAttr_Check:
	ld16_24 xwa, 0x025ea8
	cps wa, 0
	jr lt, FileIO_GetRecordAttr_Return
	cp wa, 0x14
	jr lt, FileIO_GetRecordAttr_Default

FileIO_GetRecordAttr_Return:
	ldb l, 0x0
	ret

FileIO_GetRecordAttr_Default:
	ld8_24 l, 0x0272d0
	ret

FileIO_SetModeFlag_Writing:
	sti8_24 0x0272d0, 0x01
	ret

FileIO_SetModeFlag_Reading:
	sti8_24 0x0272d0, 0x00
	ret

FileIO_CheckRecordValid:
	ld16_24 xbc, 0x025ea8
	cps bc, 0
	jr lt, CheckRecord_ReturnFalse
	cp bc, 0x14
	jr ge, CheckRecord_ReturnFalse
	cp a, 0xA
	jr c, CheckRecord_ValidRange

CheckRecord_ReturnFalse:
	ldb l, 0x0
	ret

CheckRecord_ValidRange:
	lds de, 1
	and a, 0xF
	jr z, CheckRecord_ShiftDone
	slla de

CheckRecord_ShiftDone:
	muls bc, 0xC
	ld wa, bc
	lda_24 xbc, 0x025db8
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	and wa, de
	cp wa, de
	scc8 z, l
	ret

FileIO_CheckRecordByFile:
	ld de, wa
	cp de, 0x14
	jr nc, CheckRecordByFile_OutOfRange
	cp c, 0xA
	jr c, CheckRecordByFile_Valid

CheckRecordByFile_OutOfRange:
	ldb l, 0x0
	ret

CheckRecordByFile_Valid:
	lds hl, 1
	ld a, c
	and a, 0xF
	jr z, CheckRecordByFile_ShiftDone
	slla hl

CheckRecordByFile_ShiftDone:
	extz xde
	ld xbc, xde
	add xbc, xbc
	add xbc, xde
	sll xbc, 2
	ld xwa, 0x25DB8
	add xwa, xbc
	ld wa, (xwa)
	and wa, hl
	cp wa, hl
	scc8 z, l
	ret

CheckFileSystemStatus:
	ld16_24 xwa, 0x025ea8
	cps wa, 0
	jr lt, CheckFS_ReturnZero
	cp wa, 0x14
	jr lt, CheckFS_ValidIndex

CheckFS_ReturnZero:
	lds hl, 0
	ret

CheckFS_ValidIndex:
	muls wa, 0xC
	lda_24 xbc, 0x025db8
	ld_sriw3 HL, 0x07, 0xE4, 0xE0
	ret

FileIO_GetRecordFlags:
	cp wa, 0x14
	jr c, GetRecordFlags_Valid
	lds hl, 0
	ret

GetRecordFlags_Valid:
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	ld xwa, 0x25DB8
	add xwa, xbc
	ld hl, (xwa)
	ret

FileIO_CheckFileExists:
	st_dri3b L, 0xFD, 0xF6, 0xFE
	lda xbc, (xsp)
	call _findfirst
	ld xwa, xhl
	cp xwa, 0x0
	jr lt, CheckFileExists_NotFound
	call _findclose
	ldb l, 0x1
	jr CheckFileExists_Done

CheckFileExists_NotFound:
	ldb l, 0x0

CheckFileExists_Done:
	st_dri3b L, 0xFD, 0x0A, 0x01
	ret

FileIO_InitRecordTable:
	ld xiy, 0xEA0390
	ld xix, 0x25D6C
	ldw bc, 0x26
	ldirw
	lda_24 xbc, 0x025db8
	ld xwa, xbc
	st_dri3b B, 0xE5, 0xF0, 0x00

InitRecordTable_CopyLoop:
	ld xiy, 0xEA03DC
	ld xix, xwa
	lds bc, 6
	ldirw
	lda xwa, (xwa + 12)
	cp xwa, xde
	jr c, InitRecordTable_CopyLoop
	lda_24 xbc, 0x025eb2
	ld xwa, xbc
	st_dri3b B, 0xE5, 0x38, 0x13

InitRecordTable_ExtLoop:
	ld xiy, 0xEA03E8
	ld xix, xwa
	ldw bc, 0x29
	ldirw
	lda xwa, (xwa + 82)
	cp xwa, xde
	jr c, InitRecordTable_ExtLoop
	sti16_24 0x025ea8, 0x0000
	sti16_24 0x0271ea, 0x0000
	sti16_24 0x0271ec, 0x0000
	sti16_24 0x0271ee, 0x0000
	sti16_24 0x0271f0, 0x0000
	sti16_24 0x0272c8, 0x0000
	sti16_24 0x0272ca, 0x0000
	ret

GetDiskSizeInfo:
	ld8_24 a, 0xea03da
	cpda8_24 a, 155062
	jr nz, GetDiskSize_Return
	call GetMediaType
	st8_24 0x025db6, l

GetDiskSize_Return:
	ld8_24 l, 0x025db6
	ret

GetEncodedFreeSpaceData:
	lda_24 xwa, 0x025d6c
	ld32_24 xbc, 0xea0390
	cp xbc, (xwa)
	jr nz, GetEncoded_Return
	lda xbc, (xwa + 4)
	call GetDiskFreeSpace

GetEncoded_Return:
	ld32_24 xhl, 0x025d6c
	ret

FileIO_GetDiskFreeSpace:
	lda_24 xwa, 0x025d6c
	lda xbc, (xwa + 4)
	call GetDiskFreeSpace
	ld32_24 xhl, 0x025d6c
	ret

FileIO_ResetCurrentRecord:
	ld32_24 xwa, 0xea0390
	st32_24 0x025d6c, xwa
	ret

FileIO_GetDiskRecordPtr:
	lda_24 xwa, 0x025d6c
	lda xbc, (xwa + 4)
	ld32_24 xde, 0xea0394
	cp xde, (xbc)
	call_24 z, 0xF52751
	ld32_24 xhl, 0x025d70
	ret

FileIO_SearchAndLoadFile:
	push xiz
	lda_24 xwa, 0x025d74
	lda_24 xbc, 0xea0398
	calr FileIO_SearchFile
	cps hl, 0
	jr nz, SearchLoad_Return
	call GetVolumeLabel
	ld xwa, xhl
	ld xiz, xwa
	or xwa, xwa
	jr z, SearchLoad_DefaultVolume
	lda_24 xbc, 0xea0398
	calr FileIO_SearchFile
	cps hl, 0
	jr nz, SearchLoad_CopyPath

SearchLoad_DefaultVolume:
	ld xiz, 0xEA0462

SearchLoad_CopyPath:
	lda_24 xwa, 0x025d74
	ld xbc, xiz
	calr FileIO_CopyString

SearchLoad_Return:
	lda_24 xhl, 0x025d74
	pop xiz
	ret

ValidateFileSelectionIndex:
	ld8_24 c, 0x025db6
	cps c, 2
	jr z, ValidateSelection_CheckRange
	cps c, 3
	jr z, ValidateSelection_CheckRange
	cps c, 4
	jr nz, ValidateSelection_Error

ValidateSelection_CheckRange:
	cps wa, 0
	jr lt, ValidateSelection_Error
	cp wa, 0x14
	jr lt, ValidateSelection_Ok

ValidateSelection_Error:
	ldw hl, 0xFFFF
	ret

ValidateSelection_Ok:
	lds hl, 0
	ret

GetCurrentFileIndex:
	ld16_24 xwa, 0x025ea8
	calr ValidateFileSelectionIndex
	cps hl, 0
	jr z, GetCurrentFile_ReturnIndex
	ldw hl, 0xFF98
	ret

GetCurrentFile_ReturnIndex:
	ld16_24 xhl, 0x025ea8
	ret

NotifyUIOfSelectionChange:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileSelectionIndex
	cp hl, 0xFFFF
	jr nz, NotifyUI_StoreIndex
	ld16_24 xhl, 0x025ea8
	jr NotifyUI_Return

NotifyUI_StoreIndex:
	ld hl, iz
	st16_24 0x025ea8, xhl

NotifyUI_Return:
	popw iz
	ret

GetFileEntryPtr:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileSelectionIndex
	cps hl, 0
	jr z, GetFileEntryPtr_Compute
	lda_24 xhl, 0xea0448
	jr GetFileEntryPtr_Return

GetFileEntryPtr_Compute:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	lda_24 xhl, 0x025dba
	add xhl, xbc

GetFileEntryPtr_Return:
	popw iz
	ret

GetCurrentFileType:
	ld16_24 xwa, 0x025ea8
	calr ValidateFileSelectionIndex
	cps hl, 0
	jr z, GetCurrentFileType_Lookup
	ldb l, 0x0
	ret

GetCurrentFileType_Lookup:
	ld16_24 xwa, 0x025ea8
	muls wa, 0xC
	lda_24 xbc, 0x025dc2
	ld_srib3 L, 0x07, 0xE4, 0xE0
	ret

UpdateFileEntry:
	st_dri3b L, 0xFD, 0xD4, 0xFE
	push xiz
	lda_dri3 XHL, 0xFD, 0x2E, 0x01
	ld iz, wa
	ld xiy, 0xEA046E
	lda xix, (xsp + 20)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xEA047E
	lda xix, (xsp + 4)
	ldw bc, 0x8
	ldirw
	ld wa, iz
	calr ValidateFileSelectionIndex
	cps hl, 0
	jr nz, UpdateFileEntry_Error
	ldto_berp A, 0xF8
	extz wa
	ldfr_werp WA, 0xFA
	ld wa, iz
	calr GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 20)
	ldto_werp BC, 0xFA
	calr FileIO_FormatFileIndex
	lda xbc, (xsp + 20)
	ld_srib E, (xsp + 0x012e)
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
	ld xhl, 0xFFFFFF98
	jr UpdateFileEntry_Return

UpdateFileEntry_Commit:
	call _findclose
	ld xhl, (xsp + 38)

UpdateFileEntry_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x2C, 0x01
	ret

ParseFileExtension:
	dec 6, xsp
	push xiz
	ld (xsp + 4), xbc
	ld (xsp + 8), wa
	cpw (xsp + 8), 0x14
	jr nc, ParseFileExt_NoMatch
	lds iz, 0
	ld xwa, (xsp + 4)
	jr ParseFileExt_CheckDot

ParseFileExt_ScanDot:
	inc 1, iz
	inc 1, xwa

ParseFileExt_CheckDot:
	cp (xwa), 0x2E
	jr z, ParseFileExt_DotFound
	cp iz, 0xA
	jr c, ParseFileExt_ScanDot

ParseFileExt_DotFound:
	cp iz, 0xA
	jr nc, ParseFileExt_NoMatch
	inc 1, iz
	ldi_berp 0xFB, 0

ParseFileExt_MatchLoop:
	ldto_berp A, 0xFB
	extz wa
	sla wa, 2
	lda_24 xbc, 0xea0340
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld bc, iz
	extz xbc
	add xbc, (xsp + 4)
	calr FileIO_SearchFile
	cps hl, 0
	jr z, ParseFileExt_MatchCheck
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr c, ParseFileExt_MatchLoop

ParseFileExt_MatchCheck:
	cp_erpb 0xFB, 0x0A
	jr c, ParseFileExt_StoreResult

ParseFileExt_NoMatch:
	ldw hl, 0xFFFF
	jr ParseFileExt_Return

ParseFileExt_StoreResult:
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	ld xde, 0x25DB8
	add xde, xbc
	lds bc, 1
	ldto_berp A, 0xFB
	and a, 0xF
	jr z, ParseFileExt_SetFlag
	slla bc

ParseFileExt_SetFlag:
	or (xde), bc
	ldto_berp L, 0xFB
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
	muls a, 0xA
	add a, c
	sub a, 0x10
	exts wa
	cps wa, 1
	jr lt, ParseTwoDigitFileNum_Invalid
	cp wa, 0x14
	jr le, ParseTwoDigitFileNum_Return

ParseTwoDigitFileNum_Invalid:
	ldw hl, 0xFFFF
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
	muls bc, 0xC
	lda_24 xwa, 0x025db8
	st_dri3b W, 0x07, 0xE0, 0xE4
	cp (xwa + 2), 0x0
	jr nz, HandleFilenameChange_ExistingEntry
	ld wa, iz
	ld xbc, (xsp + 10)
	calr ParseFileExtension
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jrl lt, HandleFilenameChange_ReturnFail
	ld bc, iz
	muls bc, 0xC
	lda_24 xwa, 0x025dba
	st_dri3b W, 0x07, 0xE0, 0xE4
	ld xbc, (xsp + 10)
	inc 2, xbc
	lds de, 6
	calr FileIO_CopyString_WriteNull
	muls iz, 0xC
	lda_24 xwa, 0x025db8
	st_dri3b W, 0x07, 0xE0, 0xF8
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
	lds hl, 1
	jr HandleFilenameChange_Return

HandleFilenameChange_ExistingEntry:
	inc 2, xwa
	ld xbc, (xsp + 10)
	inc 2, xbc
	lds de, 6
	calr FileIO_Search_SkipEntry
	cps hl, 0
	jr nz, HandleFilenameChange_ReturnFail
	ld wa, iz
	ld xbc, (xsp + 10)
	calr ParseFileExtension
	cps hl, 0
	jr nz, HandleFilenameChange_ReturnFail
	lda_24 xbc, 0x025dc2
	muls iz, 0xC
	st_dri3b A, 0x07, 0xE4, 0xF8
	ld xwa, (xsp + 6)
	cp xwa, 0x1388
	jr ule, HandleFilenameChange_SmallFile
	ld (xbc), 0x1
	jr HandleFilenameChange_ReturnFail

HandleFilenameChange_SmallFile:
	ld (xbc), 0x0

HandleFilenameChange_ReturnFail:
	lds hl, 0

HandleFilenameChange_Return:
	pop xiz
	lda xsp, (xsp + 10)
	ret

GetEncodedFileSizeData:
	st_dri3b L, 0xFD, 0xEE, 0xFE
	pushw iz
	lda_24 xbc, 0x025db8
	ld xwa, xbc
	st_dri3b B, 0xE5, 0xF0, 0x00

GetEncFileSize_CopyRecordLoop:
	ld xiy, 0xEA03DC
	ld xix, xwa
	lds bc, 6
	ldirw
	lda xwa, (xwa + 12)
	cp xwa, xde
	jr c, GetEncFileSize_CopyRecordLoop
	lds iz, 0
	lda xbc, (xsp + 10)
	ld xwa, 0xEA048E
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
	cps wa, 0
	jr lt, GetEncFileSize_AfterFirstMatch
	ld xde, (xsp + 12)
	ld xbc, (xsp + 6)
	calr HandleFilenameChange
	add iz, hl

GetEncFileSize_AfterFirstMatch:
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cps hl, 0
	jr nz, GetEncFileSize_ReleaseHandle

GetEncFileSize_IterLoop:
	ld xwa, (xsp + 6)
	calr ParseTwoDigitFileNum
	ld wa, hl
	cps wa, 0
	jr lt, GetEncFileSize_IterNext
	ld xde, (xsp + 12)
	ld xbc, (xsp + 6)
	calr HandleFilenameChange
	add iz, hl

GetEncFileSize_IterNext:
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cps hl, 0
	jr z, GetEncFileSize_IterLoop

GetEncFileSize_ReleaseHandle:
	ld xwa, (xsp + 2)
	call _findclose

GetEncFileSize_Return:
	ld hl, iz
	popw iz
	st_dri3b L, 0xFD, 0x12, 0x01
	ret

; =============================================================================
; Number conversion and array search function (F8991C-F89A7A)
;
; Converts a numeric index to ASCII digit pair, formats into a buffer,
; then iterates through a 12-byte record array at 0x025DB8 performing
; lookups and copies. Uses div-by-10 to extract decimal digits.
; =============================================================================
IndexToRecordLookup:
	.byte 0xf3, 0xfd, 0xe0, 0xfe, 0x37	; lda xsp, (xsp + 0xFEE0)  [R+d16, not in LLVM]
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
	ld xix, 0x00025DB8			; record array base
	add xix, xbc				; XIX = &records[index]
	ld xiy, 0x00EA03DC			; destination descriptor
	lds	bc, 6
	ldirw					; copy 6 words (12 bytes)
	lda xbc, (xsp + 8)			; XBC = output buffer
	ld hl, iz
	inc 1, hl				; HL = index + 1
	ld wa, hl
	extz xwa
	div wa, 0x000A				; WA = quotient, remainder in ?
	add a, 0x30				; convert to ASCII '0'-'9'
	ld (xbc), a				; store ones digit
	extz xhl
	div hl, 0x000A				; second digit extraction
	ld wa, qhl				; get quotient from Q bank
	add a, 0x30				; convert to ASCII
	ld (xbc + 1), a				; store tens digit
	lda xwa, (xbc + 2)			; buffer + 2
	ld xbc, xde				; restore saved arg
	calr FileIO_CopyString			; format string
	lda xwa, (xsp + 8)			; output buffer
	ld xbc, 0x00EA0492			; descriptor
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
	cps hl, 0
	jr lt, IdxRecLookup_AfterFirstMatch			; failed
	ld wa, iz				; --- copy record[index].field to buffer ---
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2				; XBC = index * 12
	lda_24 xwa, 0x025DBA			; field at offset +2
	add xwa, xbc
	lda xbc, (xsp + 32)			; destination
	lds	de, 6
	calr FileIO_CopyString_WriteNull			; copy 6 words
	ld wa, iz				; --- clear record[index].flag ---
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2				; XBC = index * 12
	lda_24 xwa, 0x025DC0			; flag at offset +8
	add xwa, xbc
	ld (xwa), 0x00				; clear flag byte
	ldw (xsp + 6), 0x0001			; result flag = 1 (found)
IdxRecLookup_AfterFirstMatch:
	lda xbc, (xsp + 24)
	ld xwa, (xsp + 2)			; result handle
	call _findnext				; iterate/next
	cps hl, 0
	jrl nz, IdxRecLookup_ReleaseHandle			; done iterating
IdxRecLookup_IterBody:
	ld wa, iz				; --- iteration loop body ---
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2				; XBC = index * 12
	ld xwa, 0x00025DB8			; record base
	add xwa, xbc
	lda xbc, (xsp + 24)
	cp (xwa + 2), 0x00			; check record field
	jr nz, IdxRecLookup_NonZeroField			; non-zero, different path
	inc 6, xbc				; advance buffer by 6
	ld wa, iz
	calr ParseFileExtension			; lookup
	cps hl, 0
	jr lt, IdxRecLookup_IterNext			; failed
	ld wa, iz				; --- copy record field ---
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	lda_24 xwa, 0x025DBA
	add xwa, xbc
	lda xbc, (xsp + 32)
	lds	de, 6
	calr FileIO_CopyString_WriteNull			; copy
	ld wa, iz
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	lda_24 xwa, 0x025DC0
	add xwa, xbc
	ld (xwa), 0x00				; clear flag
	jr IdxRecLookup_IterNext				; continue
IdxRecLookup_NonZeroField:
	inc 2, xwa				; advance to next field
	inc 8, xbc				; advance buffer (inc 0 encoding = 8)
	lds	de, 6
	calr FileIO_Search_SkipEntry			; compare/copy
	cps hl, 0
	jr nz, IdxRecLookup_IterNext			; mismatch, skip
	lda xbc, (xsp + 30)
	ld wa, iz
	calr ParseFileExtension			; lookup
IdxRecLookup_IterNext:
	lda xbc, (xsp + 24)
	ld xwa, (xsp + 2)			; result handle
	call _findnext				; iterate/next
	cps hl, 0
	jr z, IdxRecLookup_IterBody			; more entries, loop
IdxRecLookup_ReleaseHandle:
	ld xwa, (xsp + 2)			; result handle
	call _findclose				; release/close
IdxRecLookup_Return:
	ld hl, (xsp + 6)			; return result flag
	popw iz
	.byte 0xf3, 0xfd, 0x20, 0x01, 0x37	; lda xsp, (xsp + 0x0120)  [R+d16, not in LLVM]
	ret


ValidateFileRange:
	ld8_24 c, 0x025db6
	cps c, 2
	jr z, ValidateFileRange_CheckLower
	cps c, 3
	jr z, ValidateFileRange_CheckLower
	cps c, 4
	jr nz, ValidateFileRange_Invalid

ValidateFileRange_CheckLower:
	cps wa, 0
	jr lt, ValidateFileRange_Invalid
	cpda16_24 xwa, 160236
	jr le, ValidateFileRange_InRange

ValidateFileRange_Invalid:
	ldw hl, 0xFFFF
	ret

ValidateFileRange_InRange:
	ld16_24 xbc, 0x0271ee
	cp wa, bc
	jr lt, ValidateFileRange_FirstPage
	cpda16_24 xwa, 160240
	jr le, ValidateFileRange_SecondPage

ValidateFileRange_FirstPage:
	lds hl, 1
	ret

ValidateFileRange_SecondPage:
	sub wa, bc
	muls wa, 0x52
	lda_24 xbc, 0x025eb2
	cp_srib_im 0x07, 0xE4, 0xE0, 0x00
	jr nz, ValidateFileRange_Found
	lds hl, 2
	ret

ValidateFileRange_Found:
	lds hl, 0
	ret

GetFirstPageBase:
	ld16_24 xwa, 0x0271ea
	calr ValidateFileRange
	cps hl, 0
	jr z, GetFirstPageBase_Valid
	ldw hl, 0xFF98
	ret

GetFirstPageBase_Valid:
	ld16_24 xhl, 0x0271ea
	ret

BuildSecondPageRecords:
	st_dri3b L, 0xFD, 0xEE, 0xFE
	pushw iz
	lda_24 xbc, 0x025eb2
	ld xwa, xbc
	st_dri3b B, 0xE5, 0x38, 0x13

BuildSecondPage_CopyRecordLoop:
	ld xiy, 0xEA03E8
	ld xix, xwa
	ldw bc, 0x29
	ldirw
	lda xwa, (xwa + 82)
	cp xwa, xde
	jr c, BuildSecondPage_CopyRecordLoop
	lds iz, 0
	lda xbc, (xsp + 10)
	ld xwa, 0xEA0496
	call _findfirst
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr lt, BuildSecondPage_Return
	lda xwa, (xsp + 16)
	ld (xsp + 6), xwa
	ld16_24 xwa, 0x0271ee
	cps wa, 0
	jr gt, BuildSecondPage_IterStart
	cpdi16_24 160240, 0
	jr lt, BuildSecondPage_IterStart
	neg wa
	muls wa, 0x52
	lda_24 xbc, 0x025eb2
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

BuildSecondPage_IterStart:
	lds iz, 1
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cps hl, 0
	jr nz, BuildSecondPage_ReleaseHandle

BuildSecondPage_IterBody:
	ld16_24 xwa, 0x0271ee
	cp iz, wa
	jr lt, BuildSecondPage_IterNext
	cpda16_24 xiz, 160240
	jr gt, BuildSecondPage_IterNext
	ld bc, iz
	sub bc, wa
	muls bc, 0x52
	ld wa, bc
	lda_24 xbc, 0x025eb2
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

BuildSecondPage_IterNext:
	inc 1, iz
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cps hl, 0
	jr z, BuildSecondPage_IterBody

BuildSecondPage_ReleaseHandle:
	ld xwa, (xsp + 2)
	call _findclose

BuildSecondPage_Return:
	ld hl, iz
	popw iz
	st_dri3b L, 0xFD, 0x12, 0x01
	ret

NavigateToFileIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRange
	cp hl, 0xFFFF
	jr nz, NavToFileIdx_InSecondPage
	ld16_24 xhl, 0x0271ea
	jr NavToFileIdx_Return

NavToFileIdx_InSecondPage:
	cps hl, 1
	jr nz, NavToFileIdx_StoreIndex
	ld wa, iz
	extz xwa
	div wa, 0x3C
	mul wa, 0x3C
	ld bc, wa
	st16_24 0x0271ee, xbc
	add bc, 0x3B
	ld16_24 xwa, 0x0271ec
	cp bc, wa
	jr ge, NavToFileIdx_ClampEnd
	ld wa, bc

NavToFileIdx_ClampEnd:
	st16_24 0x0271f0, xwa
	calr BuildSecondPageRecords

NavToFileIdx_StoreIndex:
	ld hl, iz
	st16_24 0x0271ea, xhl

NavToFileIdx_Return:
	popw iz
	ret

GetRecordPtrForFile:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRange
	cps hl, 0
	jr z, GetRecordPtr_InRange
	lda_24 xhl, 0xea0448
	jr GetRecordPtr_Return

GetRecordPtr_InRange:
	ld16_24 xwa, 0x0271ee
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25EB2
	add xwa, xhl
	ld xhl, xwa

GetRecordPtr_Return:
	popw iz
	ret

ValidateAndSearchFile:
	; --- Configuration/validation function (84 bytes) ---
	.byte 0xf3, 0xfd, 0xe6, 0xfe, 0x37	; lda xsp, (xsp + 0xFEE6)  [R+d16]
	pushw iz
	ld iz, wa
	ld xiy, 0x00EA049C
	lda xix, (xsp + 2)
	ldw bc, 8
	ldirw
	ld wa, iz
	calr ValidateFileRange
	cps hl, 0
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
	ld xhl, 0xFFFFFF98
	jr t, ValidateAndSearch_Return
ValidateAndSearch_Found:
	call _findclose
	ld xhl, (xsp + 20)
ValidateAndSearch_Return:
	popw iz
	.byte 0xf3, 0xfd, 0x1a, 0x01, 0x37	; lda xsp, (xsp + 0x011A)  [R+d16]
	ret


GetFileCountEncoded:
	sti16_24 0x0271ee, 0x0000
	sti16_24 0x0271f0, 0x003b
	calr BuildSecondPageRecords
	lds wa, 0
	cps hl, 0
	jr le, GetFileCount_StoreAndClamp
	ld wa, hl
	dec 1, wa

GetFileCount_StoreAndClamp:
	st16_24 0x0271ec, xwa
	cpdm16_24 160240, xwa
	ret le
	st16_24 0x0271f0, xwa
	ret

ReadVariableLengthInt:
	push xiz
	lds32 xiz, 0
	jr ReadVarLen_ReadNext

ReadVarLen_AccumulateLoop:
	and hl, 0x7F
	exts xhl
	add xiz, xhl
	sll xiz, 7

ReadVarLen_ReadNext:
	call FileIO_ReadByte
	cp hl, 0x7F
	jr gt, ReadVarLen_AccumulateLoop
	cps hl, 0
	jr ge, ReadVarLen_Negative
	ldw hl, 0xFFFF
	jr ReadVarLen_Return

ReadVarLen_Negative:
	exts xhl
	add xiz, xhl
	ld xhl, 0x7FFF
	cp xiz, 0x7FFF
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
	lds iz, 0
	cpw (xsp + 8), 0x40
	jr gt, ReadField_LongInit
	cpw (xsp + 8), 0x0
	jr le, ReadField_Terminate

ReadField_ShortLoop:
	call FileIO_ReadByte
	cps hl, 0
	jr ge, ReadField_StoreByte
	lds hl, 0

ReadField_StoreByte:
	ld xwa, (xsp + 4)
	lda_dri3 XSP, 0x07, 0xE0, 0xF8
	decm 1, (xsp + 8)
	inc 1, iz
	cpw (xsp + 8), 0x0
	jr gt, ReadField_ShortLoop
	jr ReadField_Terminate

ReadField_LongInit:
	ldw (xsp + 2), 0x1

ReadField_LongLoop:
	call FileIO_ReadByte
	cps hl, 0
	jr lt, ReadField_DiscardExtra
	ld c, l
	ld xwa, (xsp + 4)
	st_dri3b W, 0x07, 0xE0, 0xF8
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
	stib_dri 0x07, 0xE0, 0xF8, 0x00
	jr ReadField_TrimLoop

ReadField_TrimSpace:
	ld (xwa), 0x0

ReadField_TrimLoop:
	dec 1, iz
	ld xwa, (xsp + 4)
	st_dri3b W, 0x07, 0xE0, 0xF8
	cp (xwa), 0x20
	jr nz, ReadField_Return
	cps iz, 0
	jr gt, ReadField_TrimSpace

ReadField_Return:
	popw iz
	inc 8, xsp
	ret

ParseSMFTrackName:
	push xiz
	lds iz, 0
	sti8_24 0x025b90, 0x00
	ldi_werp 0xFA, 0
	calr ReadVariableLengthInt
	cps hl, 0
	jrl nz, ParseSMF_ReturnNamePtr

ParseSMF_ReadEvent:
	call FileIO_ReadByte
	cp hl, 0xFF
	jr nz, ParseSMF_CheckSysex
	call FileIO_ReadByte
	ldfr_werp HL, 0xFA
	calr ReadVariableLengthInt
	ld iz, hl
	cpi_werp 0xFA, 3
	jr nz, ParseSMF_ResetRunning
	ld wa, iz
	ld xbc, 0x25B90
	calr ReadFieldToBuffer
	lds iz, 0
	jr ParseSMF_ResetRunning

ParseSMF_CheckSysex:
	cp hl, 0xF0
	jr z, ParseSMF_SysexReadLen
	cp hl, 0xF7
	jr nz, ParseSMF_CheckMIDI

ParseSMF_SysexReadLen:
	calr ReadVariableLengthInt
	ld iz, hl

ParseSMF_ResetRunning:
	ldi_werp 0xFA, 0

ParseSMF_SkipDataBytes:
	cps iz, 0
	jr le, ParseSMF_CheckEOF

ParseSMF_SkipLoop:
	ld wa, iz
	exts xwa
	lds bc, 1
	call FileIO_SeekAndReadBlock

ParseSMF_CheckEOF:
	call FileIO_ReturnError
	cps hl, 0
	jr ge, ParseSMF_ReadDeltaAndLoop
	lds32 xhl, 0
	jr ParseSMF_Return

ParseSMF_CheckMIDI:
	cp hl, 0xC0
	jr lt, ParseSMF_Check3ByteMsg
	cp hl, 0xDF
	jr gt, ParseSMF_Check3ByteMsg
	lds iz, 2
	jr ParseSMF_SetRunningStatus

ParseSMF_Check3ByteMsg:
	cp hl, 0x80
	jr lt, ParseSMF_CheckDataByte
	cp hl, 0xEF
	jr gt, ParseSMF_CheckDataByte
	lds iz, 3

ParseSMF_SetRunningStatus:
	ldfr_werp HL, 0xFA
	jr ParseSMF_SkipDataBytes

ParseSMF_CheckDataByte:
	cp hl, 0x7F
	jr gt, ParseSMF_SkipDataBytes
	cp_erpw 0xFA, 0xC0, 0x00
	jr lt, ParseSMF_RunningStatus3Byte
	cp_erpw 0xFA, 0xDF, 0x00
	jr gt, ParseSMF_RunningStatus3Byte
	lds iz, 1
	jr ParseSMF_SkipLoop

ParseSMF_RunningStatus3Byte:
	lds iz, 2
	jr ParseSMF_SkipLoop

ParseSMF_ReadDeltaAndLoop:
	calr ReadVariableLengthInt
	cps hl, 0
	jrl z, ParseSMF_ReadEvent

ParseSMF_ReturnNamePtr:
	lda_24 xhl, 0x025b90

ParseSMF_Return:
	pop xiz
	ret

ProcessFileRecord:
	dec 8, xsp
	push xiz
	ld (xsp + 10), wa
	ld16_24 xwa, 0x0271ee
	sub (xsp + 10), wa
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25EB2
	add xwa, xhl
	ld xbc, 0xEA04BE
	call FileIO_OpenWithMode
	cps hl, 0
	jrl lt, ProcessRecord_ErrorReturn
	lds iz, 0

ProcessRecord_MatchLoop1:
	call FileIO_ReadByte
	ld wa, iz
	extz xwa
	ld xbc, 0xEA04AC
	add xbc, xwa
	ld a, (xbc)
	exts wa
	cp wa, hl
	jr z, ProcessRecord_Match1Next
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25EB2
	add xwa, xhl
	setm 5, (xwa + 80)
	lda xwa, (xwa + 14)
	ld xbc, 0xEA04B8
	calr FileIO_CopyString
	jr ProcessRecord_CheckBit5

ProcessRecord_Match1Next:
	inc 1, iz
	cps iz, 4
	jr c, ProcessRecord_MatchLoop1

ProcessRecord_CheckBit5:
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda_24 xwa, 0x025f02
	add xwa, xhl
	bitm 5, (xwa)
	jr z, ProcessRecord_ReadTimeSig
	ld xwa, 0x80
	lds bc, 0
	call FileIO_SeekAndReadBlock
	lds iz, 0

ProcessRecord_MatchLoop2:
	call FileIO_ReadByte
	ld wa, iz
	extz xwa
	ld xbc, 0xEA04AC
	add xbc, xwa
	ld a, (xbc)
	exts wa
	cp wa, hl
	jr z, ProcessRecord_Match2Next
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25EB2
	add xwa, xhl
	setm 5, (xwa + 80)
	lda xwa, (xwa + 14)
	ld xbc, 0xEA04B8
	jrl ProcessRecord_CopyPath

ProcessRecord_Match2Next:
	inc 1, iz
	cps iz, 5
	jr c, ProcessRecord_MatchLoop2
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda_24 xwa, 0x025f02
	add xwa, xhl
	resm 5, (xwa)
	setm 6, (xwa)

ProcessRecord_ReadTimeSig:
	lds32 xwa, 4
	lds bc, 1
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
	lda_24 xwa, 0x025f02
	add xwa, xhl
	resm 7, (xwa)

ProcessRecord_ReadAfterTimeSig:
	lds32 xwa, 4
	lds bc, 1
	call FileIO_SeekAndReadBlock
	lds iz, 0

ProcessRecord_MatchLoop3:
	call FileIO_ReadByte
	ld wa, iz
	extz xwa
	ld xbc, 0xEA04B2
	add xbc, xwa
	ld a, (xbc)
	exts wa
	cp wa, hl
	jr z, ProcessRecord_Match3Next
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25EB2
	add xwa, xhl
	setm 5, (xwa + 80)
	lda xwa, (xwa + 14)
	ld xbc, 0xEA04B8
	jr ProcessRecord_CopyPath

ProcessRecord_CheckTempo:
	cps iz, 1
	jr nz, ProcessRecord_DefaultSetBit
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda_24 xwa, 0x025f02
	add xwa, xhl
	setm 7, (xwa)
	jr ProcessRecord_ReadAfterTimeSig

ProcessRecord_DefaultSetBit:
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25EB2
	add xwa, xhl
	setm 5, (xwa + 80)
	lda xwa, (xwa + 14)
	ld xbc, 0xEA04B8

ProcessRecord_CopyPath:
	calr FileIO_CopyString
	call FileIO_CloseHandle

ProcessRecord_ErrorReturn:
	ldw hl, 0xFFFF
	jrl ProcessRecord_Return

ProcessRecord_Match3Next:
	inc 1, iz
	cps iz, 4
	jrl c, ProcessRecord_MatchLoop3
	lds32 xwa, 4
	lds bc, 1
	call FileIO_SeekAndReadBlock
	calr ParseSMFTrackName
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr z, ProcessRecord_NoTrackName
	call FileIO_ReturnError
	cps hl, 0
	jr ge, ProcessRecord_SearchTrackName

ProcessRecord_NoTrackName:
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda_24 xwa, 0x025ec0
	add xwa, xhl
	ld xbc, 0xEA04B8
	jr ProcessRecord_CopyAndClose

ProcessRecord_SearchTrackName:
	lda_24 xbc, 0xea03f6
	ld xwa, (xsp + 4)
	calr FileIO_SearchFile
	ld (xsp + 8), hl
	ld wa, (xsp + 10)
	extz xwa
	lda_24 xiz, 0x025eb2
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, xiz
	add xwa, xhl
	lda xwa, (xwa + 14)
	cpw (xsp + 8), 0x0
	jr nz, ProcessRecord_UseTrackName
	ld xbc, 0xEA04B8
	jr ProcessRecord_CopyAndClose

ProcessRecord_UseTrackName:
	ld xbc, (xsp + 4)

ProcessRecord_CopyAndClose:
	calr FileIO_CopyString
	call FileIO_CloseHandle
	lds hl, 0

ProcessRecord_Return:
	pop xiz
	inc 8, xsp
	ret

GetFileEntryByIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRange
	cps hl, 0
	jr z, GetEntry_ComputeOffset
	lda_24 xhl, 0xea0448
	jr GetEntry_Return

GetEntry_ComputeOffset:
	ld16_24 xwa, 0x0271ee
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda_24 xwa, 0x025ec0
	add xwa, xhl
	lda_24 xbc, 0xea03f6
	calr FileIO_SearchFile
	cps hl, 0
	jr nz, FileEntry_ComputeOffset
	ld wa, iz
	calr ProcessFileRecord

FileEntry_ComputeOffset:
	ld16_24 xwa, 0x0271ee
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda_24 xwa, 0x025ec0
	add xwa, xhl
	ld xhl, xwa

GetEntry_Return:
	popw iz
	ret

FileIO_ByteBlock_F8A0E1:
	.byte 0x2e, 0xd8, 0x8e, 0xde, 0x88, 0x1e, 0x92, 0xf9
	.byte 0xdb, 0xd8, 0x66, 0x05, 0x33, 0xff, 0xff, 0x68
	.byte 0x1a, 0xde, 0x88, 0xe8, 0x12, 0x41, 0x52, 0x00
	.byte 0x00, 0x00, 0x1d, 0x5c, 0x0a, 0xff, 0xf2, 0x02
	.byte 0x5f, 0x02, 0x30, 0xeb, 0x80, 0xb0, 0x9f, 0xcf
	.byte 0x77, 0xdb, 0x12, 0x4e, 0x0e, 0xbf, 0xe6, 0x37
	.byte 0x2e, 0xbf, 0x1a, 0x50, 0x1e, 0xd7, 0xf4, 0xdb
	.byte 0xd8, 0x61, 0x31, 0xcf, 0x89, 0xc7, 0xf8, 0x99
	.byte 0xde, 0x12, 0xdb, 0x88, 0x1e, 0xfb, 0xf4, 0xeb
	.byte 0x8a, 0xbf, 0x10, 0x30, 0xde, 0x89, 0x1e, 0x4c
	.byte 0xf0, 0xbf, 0x10, 0x31, 0xbf, 0x02, 0x30, 0xda
	.byte 0xa9, 0x1e, 0x6e, 0xf0, 0xbf, 0x02, 0x30, 0x41
	.long FileOp_StubAndDirNames
	.byte 0x1d, 0xc7, 0x8b, 0xf8
	.byte 0xdb, 0xd8, 0x69, 0x07, 0x43, 0x48, 0x04, 0xea
	.byte 0x00, 0x68, 0x2f, 0x9f, 0x1a, 0x20, 0xd8, 0xee
	.byte 0x04, 0xd8, 0xc8, 0x10, 0x00, 0xe8, 0x12, 0xd9
	.byte 0xa8, 0x1d, 0xe0, 0x8e, 0xf8, 0x40, 0xd2, 0x5b
	.byte 0x02, 0x00, 0x41, 0x10, 0x00, 0x00, 0x00, 0x1d
	.byte 0x74, 0x8d, 0xf8, 0xf2, 0xe2, 0x5b, 0x02, 0x00
	.byte 0x00, 0x1d, 0x48, 0x8c, 0xf8, 0xf2, 0xd2, 0x5b
	.byte 0x02, 0x33, 0x4e, 0xbf, 0x1a, 0x37, 0x0e, 0xbf
	.byte 0xe6, 0x37, 0x3e, 0xbf, 0x1c, 0x50, 0x1e, 0x5d
	.byte 0xf4, 0xdb, 0xd8, 0x61, 0x31, 0xcf, 0x89, 0xc7
	.byte 0xf8, 0x99, 0xde, 0x12, 0xdb, 0x88, 0x1e, 0x81
	.byte 0xf4, 0xeb, 0x8a, 0xbf, 0x12, 0x30, 0xde, 0x89
	.byte 0x1e, 0xd2, 0xef, 0xbf, 0x12, 0x31, 0xbf, 0x04
	.byte 0x30, 0xda, 0xa9, 0x1e, 0xf4, 0xef, 0xbf, 0x04
	.byte 0x30, 0x41, 0xc6, 0x04, 0xea, 0x00, 0x1d, 0xc7
	.byte 0x8b, 0xf8, 0xdb, 0xd8, 0x69, 0x07, 0x43, 0x48
	.byte 0x04, 0xea, 0x00, 0x68, 0x48, 0x40, 0x0d, 0x00
	.byte 0x00, 0x00, 0xd9, 0xa8, 0x1d, 0xe0, 0x8e, 0xf8
	.byte 0x1d, 0xfc, 0x8c, 0xf8, 0xdb, 0x8e, 0x1d, 0xfc
	.byte 0x8c, 0xf8, 0xdb, 0xee, 0x08, 0xdb, 0xe6, 0x9f
	.byte 0x1c, 0x46, 0xee, 0x88, 0xe8, 0xc8, 0xb2, 0x00
	.byte 0x00, 0x00, 0xd9, 0xa8, 0x1d, 0xe0, 0x8e, 0xf8
	.byte 0x40, 0xe8, 0x5b, 0x02, 0x00, 0x41, 0x10, 0x00
	.byte 0x00, 0x00, 0x1d, 0x74, 0x8d, 0xf8, 0xf2, 0xf8
	.byte 0x5b, 0x02, 0x00, 0x00, 0x1d, 0x48, 0x8c, 0xf8
	.byte 0xf2, 0xe8, 0x5b, 0x02, 0x33, 0x5e, 0xbf, 0x1a
	.byte 0x37, 0x0e, 0xbf, 0xe6, 0x37, 0x2e, 0xbf, 0x1a
	.byte 0x50, 0x1e, 0xca, 0xf3, 0xdb, 0xd8, 0x61, 0x31
	.byte 0xcf, 0x89, 0xc7, 0xf8, 0x99, 0xde, 0x12, 0xdb
	.byte 0x88, 0x1e, 0xee, 0xf3, 0xeb, 0x8a, 0xbf, 0x10
	.byte 0x30, 0xde, 0x89, 0x1e, 0x3f, 0xef, 0xbf, 0x10
	.byte 0x31, 0xbf, 0x02, 0x30, 0xda, 0xaa, 0x1e, 0x61
	.byte 0xef, 0xbf, 0x02, 0x30, 0x41, 0xca, 0x04, 0xea
	.byte 0x00, 0x1d, 0xc7, 0x8b, 0xf8, 0xdb, 0xd8, 0x69
	.byte 0x07, 0x43, 0x48, 0x04, 0xea, 0x00, 0x68, 0x2f
	.byte 0x9f, 0x1a, 0x20, 0xd8, 0xee, 0x0b, 0xd8, 0xc8
	.byte 0x00, 0x01, 0xe8, 0x12, 0xd9, 0xa8, 0x1d, 0xe0
	.byte 0x8e, 0xf8, 0x40, 0xfe, 0x5b, 0x02, 0x00, 0x41
	.byte 0x10, 0x00, 0x00, 0x00, 0x1d, 0x74, 0x8d, 0xf8
	.byte 0xf2, 0x0e, 0x5c, 0x02, 0x00, 0x00, 0x1d, 0x48
	.byte 0x8c, 0xf8, 0xf2, 0xfe, 0x5b, 0x02, 0x33, 0x4e
	.byte 0xbf, 0x1a, 0x37, 0x0e, 0xbf, 0xe4, 0x37, 0x2e
	.byte 0xbf, 0x1a, 0x51, 0xbf, 0x1c, 0x50, 0x1e, 0x4d
	.byte 0xf3, 0xdb, 0xd8, 0x61, 0x31, 0xcf, 0x89, 0xc7
	.byte 0xf8, 0x99, 0xde, 0x12, 0xdb, 0x88, 0x1e, 0x71
	.byte 0xf3, 0xeb, 0x8a, 0xbf, 0x10, 0x30, 0xde, 0x89
	.byte 0x1e, 0xc2, 0xee, 0xbf, 0x10, 0x31, 0xbf, 0x02
	.byte 0x30, 0xda, 0xab, 0x1e, 0xe4, 0xee, 0xbf, 0x02
	.byte 0x30, 0x41, 0xce, 0x04, 0xea, 0x00, 0x1d, 0xc7
	.byte 0x8b, 0xf8, 0xdb, 0xd8, 0x69, 0x07, 0x43, 0x48
	.byte 0x04, 0xea, 0x00, 0x68, 0x36, 0x9f, 0x1c, 0x20
	.byte 0xd8, 0xee, 0x02, 0x9f, 0x1a, 0x80, 0xd8, 0x08
	.byte 0x60, 0x00, 0xd8, 0xc8, 0xa0, 0x00, 0xe8, 0x12
	.byte 0xd9, 0xa8, 0x1d, 0xe0, 0x8e, 0xf8, 0x40, 0x14
	.byte 0x5c, 0x02, 0x00, 0x41, 0x0d, 0x00, 0x00, 0x00
	.byte 0x1d, 0x74, 0x8d, 0xf8, 0xf2, 0x21, 0x5c, 0x02
	.byte 0x00, 0x00, 0x1d, 0x48, 0x8c, 0xf8, 0xf2, 0x14
	.byte 0x5c, 0x02, 0x33, 0x4e, 0xbf, 0x1c, 0x37, 0x0e
	.byte 0xbf, 0xe6, 0x37, 0x2e, 0xbf, 0x1a, 0x50, 0x1e
	.byte 0xcc, 0xf2, 0xdb, 0xd8, 0x61, 0x31, 0xcf, 0x89
	.byte 0xc7, 0xf8, 0x99, 0xde, 0x12, 0xdb, 0x88, 0x1e
	.byte 0xf0, 0xf2, 0xeb, 0x8a, 0xbf, 0x10, 0x30, 0xde
	.byte 0x89, 0x1e, 0x41, 0xee, 0xbf, 0x10, 0x31, 0xbf
	.byte 0x02, 0x30, 0xda, 0xac, 0x1e, 0x63, 0xee, 0xbf
	.byte 0x02, 0x30, 0x41, 0xd2, 0x04, 0xea, 0x00, 0x1d
	.byte 0xc7, 0x8b, 0xf8, 0xdb, 0xd8, 0x69, 0x07, 0x43
	.long Filename_TemplateArea
	.byte 0x68, 0x30, 0x9f, 0x1a
	.byte 0x20, 0xd8, 0x08, 0xd6, 0x01, 0xd8, 0xc8, 0x10
	.byte 0x00, 0xe8, 0x12, 0xd9, 0xa8, 0x1d, 0xe0, 0x8e
	.byte 0xf8, 0x40, 0x2a, 0x5c, 0x02, 0x00, 0x41, 0x10
	.byte 0x00, 0x00, 0x00, 0x1d, 0x74, 0x8d, 0xf8, 0xf2
	.byte 0x3a, 0x5c, 0x02, 0x00, 0x00, 0x1d, 0x48, 0x8c
	.byte 0xf8, 0xf2, 0x2a, 0x5c, 0x02, 0x33, 0x4e, 0xbf
	.byte 0x1a, 0x37, 0x0e, 0xbf, 0xe8, 0x37, 0x2e, 0x1e
	.byte 0x54, 0xf2, 0xdb, 0xd8, 0x61, 0x31, 0xcf, 0x89
	.byte 0xc7, 0xf8, 0x99, 0xde, 0x12, 0xdb, 0x88, 0x1e
	.byte 0x78, 0xf2, 0xeb, 0x8a, 0xbf, 0x10, 0x30, 0xde
	.byte 0x89, 0x1e, 0xc9, 0xed, 0xbf, 0x10, 0x31, 0xbf
	.byte 0x02, 0x30, 0xda, 0xac, 0x1e, 0xeb, 0xed, 0xbf
	.byte 0x02, 0x30, 0x41, 0xd6, 0x04, 0xea, 0x00, 0x1d
	.byte 0xc7, 0x8b, 0xf8, 0xdb, 0xd8, 0x69, 0x07, 0x43
	.long Filename_TemplateArea
	.byte 0x68, 0x28, 0x40, 0x80
	.byte 0x49, 0x00, 0x00, 0xd9, 0xa8, 0x1d, 0xe0, 0x8e
	.byte 0xf8, 0x40, 0x40, 0x5c, 0x02, 0x00, 0x41, 0x10
	.byte 0x00, 0x00, 0x00, 0x1d, 0x74, 0x8d, 0xf8, 0xf2
	.byte 0x50, 0x5c, 0x02, 0x00, 0x00, 0x1d, 0x48, 0x8c
	.byte 0xf8, 0xf2, 0x40, 0x5c, 0x02, 0x33, 0x4e, 0xbf
	.byte 0x18, 0x37, 0x0e, 0xbf, 0xe6, 0x37, 0x2e, 0xbf
	.byte 0x1a, 0x50, 0x1e, 0xe1, 0xf1, 0xdb, 0xd8, 0x61
	.byte 0x31, 0xcf, 0x89, 0xc7, 0xf8, 0x99, 0xde, 0x12
	.byte 0xdb, 0x88, 0x1e, 0x05, 0xf2, 0xeb, 0x8a, 0xbf
	.byte 0x10, 0x30, 0xde, 0x89, 0x1e, 0x56, 0xed, 0xbf
	.byte 0x10, 0x31, 0xbf, 0x02, 0x30, 0xda, 0xac, 0x1e
	.byte 0x78, 0xed, 0xbf, 0x02, 0x30, 0x41, 0xda, 0x04
	.byte 0xea, 0x00, 0x1d, 0xc7, 0x8b, 0xf8, 0xdb, 0xd8
	.byte 0x69, 0x07, 0x43, 0x48, 0x04, 0xea, 0x00, 0x68
	.byte 0x36, 0xf2, 0x56, 0x5c, 0x02, 0x00, 0x20, 0x9f
	.byte 0x1a, 0x20, 0xd8, 0x08, 0x50, 0x00, 0xd8, 0xc8
	.byte 0xa7, 0x4a, 0xe8, 0x12, 0xd9, 0xa8, 0x1d, 0xe0
	.byte 0x8e, 0xf8, 0xf2, 0x57, 0x5c, 0x02, 0x30, 0x41
	.byte 0x0d, 0x00, 0x00, 0x00, 0x1d, 0x74, 0x8d, 0xf8
	.byte 0xf2, 0x64, 0x5c, 0x02, 0x00, 0x00, 0x1d, 0x48
	.byte 0x8c, 0xf8, 0xf2, 0x56, 0x5c, 0x02, 0x33, 0x4e
	.byte 0xbf, 0x1a, 0x37, 0x0e

ValidateFileRangeType5:
	cpi8_24 0x025db6, 0x05
	jr nz, ValidateRange_OutOfRange
	cps wa, 0
	jr lt, ValidateRange_OutOfRange
	cpda16_24 xwa, 160236
	jr le, ValidateRange_CheckPage

ValidateRange_OutOfRange:
	ldw hl, 0xFFFF
	ret

ValidateRange_CheckPage:
	ld16_24 xbc, 0x0271ee
	cp wa, bc
	jr lt, ValidateRange_NeedPageChange
	cpda16_24 xwa, 160240
	jr le, ValidateRange_CheckEmpty

ValidateRange_NeedPageChange:
	lds hl, 1
	ret

ValidateRange_CheckEmpty:
	sub wa, bc
	muls wa, 0x52
	lda_24 xbc, 0x025ec0
	cp_srib_im 0x07, 0xE4, 0xE0, 0x00
	jr nz, ValidateRange_IsValid
	lds hl, 2
	ret

ValidateRange_IsValid:
	lds hl, 0
	ret

GetCurrentFileIndexAlt:
	ld16_24 xwa, 0x0271ea
	calr ValidateFileRangeType5
	cps hl, 0
	jr z, GetCurrentIndex_Return
	ldw hl, 0xFF98
	ret

GetCurrentIndex_Return:
	ld16_24 xhl, 0x0271ea
	ret

BuildPageRecords:
	st_dri3b L, 0xFD, 0xEE, 0xFE
	pushw iz
	lda_24 xbc, 0x025eb2
	ld xwa, xbc
	st_dri3b B, 0xE5, 0x38, 0x13

BuildRecords_CopyLoop:
	ld xiy, 0xEA03E8
	ld xix, xwa
	ldw bc, 0x29
	ldirw
	lda xwa, (xwa + 82)
	cp xwa, xde
	jr c, BuildRecords_CopyLoop
	lds iz, 0
	lda xbc, (xsp + 10)
	ld xwa, 0xEA04DE
	call _findfirst
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr lt, BuildRecords_Return
	lda xwa, (xsp + 16)
	ld (xsp + 6), xwa
	ld16_24 xwa, 0x0271ee
	cps wa, 0
	jr gt, BuildRecords_SearchDone
	cpdi16_24 160240, 0
	jr lt, BuildRecords_SearchDone
	neg wa
	muls wa, 0x52
	lda_24 xbc, 0x025ec0
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

BuildRecords_SearchDone:
	lds iz, 1
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cps hl, 0
	jr nz, BuildRecords_Cleanup

BuildRecords_UpdateLoop:
	ld16_24 xwa, 0x0271ee
	cp iz, wa
	jr lt, BuildRecords_UpdateNext
	cpda16_24 xiz, 160240
	jr gt, BuildRecords_UpdateNext
	ld bc, iz
	sub bc, wa
	muls bc, 0x52
	ld wa, bc
	lda_24 xbc, 0x025ec0
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

BuildRecords_UpdateNext:
	inc 1, iz
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cps hl, 0
	jr z, BuildRecords_UpdateLoop

BuildRecords_Cleanup:
	ld xwa, (xsp + 2)
	call _findclose

BuildRecords_Return:
	ld hl, iz
	popw iz
	st_dri3b L, 0xFD, 0x12, 0x01
	ret

SetCurrentFileIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRangeType5
	cp hl, 0xFFFF
	jr nz, SetIndex_InvalidWrap
	ld16_24 xhl, 0x0271ea
	jr SetIndex_Return

SetIndex_InvalidWrap:
	cps hl, 1
	jr nz, SetIndex_StoreIndex
	ld wa, iz
	extz xwa
	div wa, 0x3C
	mul wa, 0x3C
	ld bc, wa
	st16_24 0x0271ee, xbc
	add bc, 0x3B
	ld16_24 xwa, 0x0271ec
	cp bc, wa
	jr ge, SetIndex_UpdatePageEnd
	ld wa, bc

SetIndex_UpdatePageEnd:
	st16_24 0x0271f0, xwa
	calr BuildPageRecords

SetIndex_StoreIndex:
	ld hl, iz
	st16_24 0x0271ea, xhl

SetIndex_Return:
	popw iz
	ret

GetFileRecordPtr:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRangeType5
	cps hl, 0
	jr z, GetRecordPtr_ComputeOffset
	lda_24 xhl, 0xea0448
	jr GetRecordPtrAlt_Return

GetRecordPtr_ComputeOffset:
	ld16_24 xwa, 0x0271ee
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda_24 xwa, 0x025ec0
	add xwa, xhl
	ld xhl, xwa

GetRecordPtrAlt_Return:
	popw iz
	ret

BuildPageRecordsAlt:
	sti16_24 0x0271ee, 0x0000
	sti16_24 0x0271f0, 0x003b
	calr BuildPageRecords
	lds wa, 0
	cps hl, 0
	jr le, BuildRecordsAlt_StoreCount
	ld wa, hl
	dec 1, wa

BuildRecordsAlt_StoreCount:
	st16_24 0x0271ec, xwa
	cpdm16_24 160240, xwa
	ret le
	st16_24 0x0271f0, xwa
	ret

TrimAndFormatFilename:
	lda xsp, (xsp - 128)
	push xiz
	ld xiz, xbc
	stib_dri 0x07, 0xF8, 0xE0, 0x00
	lds ix, 0
	cps wa, 0
	jr le, TrimFormat_TrimTrailing

TrimFormat_ScanLoop:
	st_dri3b C, 0x07, 0xF8, 0xF0
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
	st_dri3b W, 0x07, 0xF8, 0xF0
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
	lds ix, 0
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
	st_dri3b A, 0x07, 0xE0, 0xF0
	cp (xbc), 0x20
	jr z, TrimFormat_SkipSpaces
	ld xwa, xiz
	calr FileIO_CopyString

TrimFormat_Done:
	lds hl, 0
	pop xiz
	st_dri3b L, 0xFD, 0x80, 0x00
	ret

DetectFileType:
	ld8_24 l, 0x025db6
	cps l, 6
	jr z, DetectType_KnownType
	cps l, 7
	jr nz, DetectType_TryOpen

DetectType_KnownType:
	extz hl
	ret

DetectType_TryOpen:
	cps l, 2
	jrl nz, DetectType_NotFound
	ld xwa, 0xEA04E4
	ld xbc, 0xEA04E0
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, DetectType_TryExtended
	sti8_24 0x025db6, 0x06
	ld xwa, 0x10
	lds bc, 0
	call FileIO_SeekAndReadBlock
	lda_24 xwa, 0x025d74
	ld xbc, 0x40
	call FileIO_ReadBlock
	ld xwa, 0x60
	lds bc, 0
	call FileIO_SeekAndReadBlock
	ld xwa, 0x27200
	ld xbc, 0x3C
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	lda_24 xbc, 0x025d74
	ldw wa, 0x40
	lds de, 0

DetectType_TrimAndReturn:
	calr TrimAndFormatFilename
	ld8_24 l, 0x025db6
	extz hl
	ret

DetectType_TryExtended:
	ld xwa, 0xEA04F2
	ld xbc, 0xEA04EE
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, DetectType_NotFound
	sti8_24 0x025db6, 0x07
	ld xwa, 0x12D8
	lds bc, 0
	call FileIO_SeekAndReadBlock
	lda_24 xwa, 0x025d74
	ld xbc, 0x38
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	lda_24 xbc, 0x025d74
	ldw wa, 0x38
	lds de, 0
	jr DetectType_TrimAndReturn

DetectType_NotFound:
	ldw hl, 0xFFFF
	ret

ValidateFileRangeAlt:
	ld8_24 c, 0x025db6
	cps c, 6
	jr z, ValidateRangeAlt_CheckType
	cps c, 7
	jr nz, ValidateRangeAlt_OutOfRange

ValidateRangeAlt_CheckType:
	cps wa, 0
	jr lt, ValidateRangeAlt_OutOfRange
	cpda16_24 xwa, 160236
	jr le, ValidateRangeAlt_CheckPage

ValidateRangeAlt_OutOfRange:
	ldw hl, 0xFFFF
	ret

ValidateRangeAlt_CheckPage:
	ld16_24 xbc, 0x0271ee
	cp wa, bc
	jr lt, ValidateRangeAlt_NeedPageChange
	cpda16_24 xwa, 160240
	jr le, ValidateRangeAlt_CheckEmpty

ValidateRangeAlt_NeedPageChange:
	lds hl, 1
	ret

ValidateRangeAlt_CheckEmpty:
	sub wa, bc
	muls wa, 0x52
	lda_24 xbc, 0x025eb2
	cp_srib_im 0x07, 0xE4, 0xE0, 0x00
	jr nz, ValidateRangeAlt_IsValid
	lds hl, 2
	ret

ValidateRangeAlt_IsValid:
	lds hl, 0
	ret

FileIO_GetCurrentFileIndex_Alt:
	ld16_24 xwa, 0x0271ea
	calr ValidateFileRangeAlt
	cps hl, 0
	jr z, GetCurrentFileAlt_ReturnIndex
	ldw hl, 0xFF98
	ret

GetCurrentFileAlt_ReturnIndex:
	ld16_24 xhl, 0x0271ea
	ret

FileIO_BuildFileExtName:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	lda xwa, (xsp + 4)
	stib_dpi 0xE0, 0x2E
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
	lda_24 xbc, 0x025eb2
	ld xwa, xbc
	st_dri3b B, 0xE5, 0x38, 0x13

InitDirScan_CopyLoop:
	ld xiy, 0xEA03E8
	ld xix, xwa
	ldw bc, 0x29
	ldirw
	lda xwa, (xwa + 82)
	cp xwa, xde
	jr c, InitDirScan_CopyLoop
	ldi_werp 0xFA, 0
	cpi8_24 0x025db6, 0x06
	jrl nz, DirScan_AltMediaPath
	ld xwa, 0xEA0504
	ld xbc, 0xEA0500
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, DirScan_ReturnResult
	ld xwa, 0x51
	lds bc, 0
	call FileIO_SeekAndReadBlock
	call FileIO_ReadByte
	ldfr_werp HL, 0xFA
	ld16_24 xiz, 0x0271ee
	cpda16_24 xiz, 160240
	jr gt, FileIO_DirScanDone

DirScan_ProcessEntry:
	lda_24 xwa, 0x027200
	ld_srib3 A, 0x07, 0xE0, 0xF8
	exts wa
	mul wa, 0x30
	add wa, 0xA0
	exts xwa
	lds bc, 0
	call FileIO_SeekAndReadBlock
	ld wa, iz
	subda16_24 xwa, 160238
	muls wa, 0x52
	lda_24 xbc, 0x025eb2
	exts xwa
	add xwa, xbc
	ld xbc, 0xB
	call FileIO_ReadBlock
	ld wa, iz
	subda16_24 xwa, 160238
	muls wa, 0x52
	lda_24 xbc, 0x025eb2
	exts xwa
	add xwa, xbc
	calr FileIO_BuildFileExtName
	inc 1, iz
	cpda16_24 xiz, 160240
	jr le, DirScan_ProcessEntry

FileIO_DirScanDone:
	call FileIO_CloseHandle

DirScan_ReturnResult:
	ldto_werp HL, 0xFA
	pop xiz
	lda xsp, (xsp + 16)
	ret

DirScan_AltMediaPath:
	ld xwa, 0xEA0512
	ld xbc, 0xEA050E
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, DirScan_ReturnResult
	ld xwa, 0x10
	lds bc, 0

DirScan_AltReadLoop:
	call FileIO_SeekAndReadBlock
	lda xwa, (xsp + 4)
	ld xbc, 0xB
	call FileIO_ReadBlock
	call FileIO_ReturnError
	cps hl, 0
	jr lt, FileIO_DirScanDone
	lda xbc, (xsp + 4)
	cp (xbc), 0x20
	jr lt, FileIO_DirScanDone
	ld16_24 xde, 0x0271ee
	ldto_werp WA, 0xFA
	cp wa, de
	jr lt, DirScan_AltNextEntry
	ldto_werp WA, 0xFA
	cpda16_24 xwa, 160240
	jr gt, DirScan_AltNextEntry
	ldto_werp WA, 0xFA
	sub wa, de
	muls wa, 0x52
	lda_24 xde, 0x025eb2
	exts xwa
	add xwa, xde
	ldw de, 0xB
	calr FileIO_CopyString_WriteNull
	ldto_werp WA, 0xFA
	subda16_24 xwa, 160238
	muls wa, 0x52
	lda_24 xbc, 0x025eb2
	exts xwa
	add xwa, xbc
	calr FileIO_BuildFileExtName

DirScan_AltNextEntry:
	inc1_werp 0xFA
	ld xwa, 0x45
	lds bc, 1
	jr DirScan_AltReadLoop

FileIO_SelectFileByIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRangeAlt
	cp hl, 0xFFFF
	jr nz, SelectFile_CheckPageBound
	ld16_24 xhl, 0x0271ea
	jr SelectFile_Return

SelectFile_CheckPageBound:
	cps hl, 1
	jr nz, SelectFile_StoreIndex
	ld wa, iz
	extz xwa
	div wa, 0x3C
	mul wa, 0x3C
	ld bc, wa
	st16_24 0x0271ee, xbc
	add bc, 0x3B
	ld16_24 xwa, 0x0271ec
	cp bc, wa
	jr ge, SelectFile_ClampEnd
	ld wa, bc

SelectFile_ClampEnd:
	st16_24 0x0271f0, xwa
	calr FileIO_InitDirScan

SelectFile_StoreIndex:
	ld hl, iz
	st16_24 0x0271ea, xhl

SelectFile_Return:
	popw iz
	ret

FileIO_GetFileEntryByIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRangeAlt
	cps hl, 0
	jr z, GetFileEntry_ComputeOffset
	lda_24 xhl, 0xea0448
	jr GetFileEntry_Return

GetFileEntry_ComputeOffset:
	ld16_24 xwa, 0x0271ee
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	ld xwa, 0x25EB2
	add xwa, xhl
	ld xhl, xwa

GetFileEntry_Return:
	popw iz
	ret

FileIO_InitFileNavigation:
	sti16_24 0x0271ee, 0x0000
	sti16_24 0x0271f0, 0x003b
	calr FileIO_InitDirScan
	lds wa, 0
	cps hl, 0
	jr le, InitFileNav_ClampEnd
	ld wa, hl
	dec 1, wa

InitFileNav_ClampEnd:
	st16_24 0x0271ec, xwa
	cpdm16_24 160240, xwa
	ret le
	st16_24 0x0271f0, xwa
	ret

FileIO_RefreshFileNames:
	push xiz
	cpi8_24 0x025db6, 0x06
	jrl nz, RefreshNames_AltMediaPath
	ld xwa, 0xEA0524
	ld xbc, 0xEA0520
	call FileIO_OpenWithMode
	ld16_24 xwa, 0x0271ee
	ld iz, wa
	cps hl, 0
	jr ge, RefreshNames_CheckEnd
	cpda16_24 xwa, 160240
	jrl gt, FileIO_ScanComplete_Return

RefreshNames_FallbackLoop:
	ld wa, iz
	subda16_24 xwa, 160238
	muls wa, 0x52
	lda_24 xbc, 0x025eb2
	st_dri3b A, 0x07, 0xE4, 0xE0
	lda xwa, (xbc + 14)
	calr FileIO_CopyString
	inc 1, iz
	cpda16_24 xiz, 160240
	jr le, RefreshNames_FallbackLoop
	jrl FileIO_ScanComplete_Return

RefreshNames_CheckEnd:
	cpda16_24 xwa, 160240
	jrl gt, FileIO_ScanDone

RefreshNames_ReadLoop:
	lda_24 xwa, 0x027200
	ld_srib3 A, 0x07, 0xE0, 0xF8
	exts wa
	mul wa, 0x30
	add wa, 0xA0
	ldfr_werp WA, 0xFA
	exts xwa
	lds bc, 0
	call FileIO_SeekAndReadBlock
	ld wa, iz
	subda16_24 xwa, 160238
	muls wa, 0x52
	ld bc, wa
	lda_24 xwa, 0x025ec0
	st_dri3b W, 0x07, 0xE0, 0xE4
	ld xbc, 0x30
	call FileIO_ReadBlock
	ld wa, iz
	subda16_24 xwa, 160238
	muls wa, 0x52
	ld bc, wa
	lda_24 xwa, 0x025ec0
	exts xbc
	add xbc, xwa
	ldw wa, 0x30
	ldw de, 0x40
	calr TrimAndFormatFilename
	cps hl, 0
	jr ge, RefreshNames_NextEntry
	ld wa, iz
	subda16_24 xwa, 160238
	muls wa, 0x52
	lda_24 xbc, 0x025eb2
	st_dri3b A, 0x07, 0xE4, 0xE0
	lda xwa, (xbc + 14)
	calr FileIO_CopyString

RefreshNames_NextEntry:
	inc 1, iz
	cpda16_24 xiz, 160240
	jrl le, RefreshNames_ReadLoop
	jrl FileIO_ScanDone

RefreshNames_AltMediaPath:
	ld xwa, 0xEA0532
	ld xbc, 0xEA052E
	call FileIO_OpenWithMode
	ld16_24 xwa, 0x0271ee
	cps hl, 0
	jr ge, RefreshNames_AltOpenSuccess
	ld iz, wa
	cpda16_24 xwa, 160240
	jrl gt, FileIO_ScanComplete_Return

RefreshNames_AltFallbackLoop:
	ld wa, iz
	subda16_24 xwa, 160238
	muls wa, 0x52
	lda_24 xbc, 0x025eb2
	st_dri3b A, 0x07, 0xE4, 0xE0
	lda xwa, (xbc + 14)
	calr FileIO_CopyString
	inc 1, iz
	cpda16_24 xiz, 160240
	jr le, RefreshNames_AltFallbackLoop
	jrl FileIO_ScanComplete_Return

RefreshNames_AltOpenSuccess:
	ldi_erpw 0xFA, 0x40, 0x00
	ld iz, wa
	cpda16_24 xwa, 160240
	jr gt, FileIO_ScanDone

RefreshNames_AltReadLoop:
	ldto_werp WA, 0xFA
	exts xwa
	lds bc, 0
	call FileIO_SeekAndReadBlock
	ld wa, iz
	subda16_24 xwa, 160238
	muls wa, 0x52
	ld bc, wa
	lda_24 xwa, 0x025ec0
	st_dri3b W, 0x07, 0xE0, 0xE4
	ld xbc, 0x10
	call FileIO_ReadBlock
	ld wa, iz
	subda16_24 xwa, 160238
	muls wa, 0x52
	ld bc, wa
	lda_24 xwa, 0x025ec0
	exts xbc
	add xbc, xwa
	ldw wa, 0x10
	lds de, 0
	calr TrimAndFormatFilename
	cps hl, 0
	jr ge, RefreshNames_AltNextEntry
	ld wa, iz
	subda16_24 xwa, 160238
	muls wa, 0x52
	lda_24 xbc, 0x025eb2
	st_dri3b A, 0x07, 0xE4, 0xE0
	lda xwa, (xbc + 14)
	calr FileIO_CopyString

RefreshNames_AltNextEntry:
	add_erpw 0xFA, 0x50, 0x00
	inc 1, iz
	cpda16_24 xiz, 160240
	jr le, RefreshNames_AltReadLoop

FileIO_ScanDone:
	call FileIO_CloseHandle

FileIO_ScanComplete_Return:
	lds hl, 0
	pop xiz
	ret

FileIO_GetFileEntryWithRefresh:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRangeAlt
	cps hl, 0
	jr z, GetEntryRefresh_ComputeOffset
	lda_24 xhl, 0xea0448
	jr GetEntryRefresh_Return

GetEntryRefresh_ComputeOffset:
	ld16_24 xwa, 0x0271ee
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda_24 xwa, 0x025ec0
	add xwa, xhl
	cp (xwa), 0x0
	call_24 z, 0xF8AA03
	ld16_24 xwa, 0x0271ee
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, 0x52
	call Math_MultiplyAccumulate
	lda_24 xwa, 0x025ec0
	add xwa, xhl
	ld xhl, xwa

GetEntryRefresh_Return:
	popw iz
	ret

FileIO_CheckMediaIsWritable:
	call GetMediaType
	cps l, 2
	jr z, CheckMediaWritable_Ok
	cps l, 3
	jr z, CheckMediaWritable_Ok
	ldw hl, 0xFFFF
	ret

CheckMediaWritable_Ok:
	lds hl, 0
	ret

FileIO_OpenWithBuiltPath:
	st_dri3b L, 0xFD, 0x70, 0xFF
	push xiz
	st_dri3l XBC, 0xFD, 0x90, 0x00
	ld xiz, xwa
	lda xwa, (xsp + 4)
	ld xbc, 0x272D2
	calr FileIO_CopyString
	lda xwa, (xsp + 4)
	ld xbc, 0x272F2
	calr FileIO_BuildFilePath
	lda xwa, (xsp + 4)
	ld xbc, xiz
	calr FileIO_BuildFilePath
	lda xwa, (xsp + 4)
	ld_sril XBC, (xsp + 0x0090)
	call FileIO_OpenWithMode
	pop xiz
	st_dri3b L, 0xFD, 0x90, 0x00
	ret

LABEL_F8AC65:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	sti8_24 0x027412, 0x00
	sti8_24 0x027414, 0x00
	lds iz, 0

LABEL_F8AC79:
	ld xwa, (xsp + 4)
	st_dri3b W, 0x07, 0xE0, 0xF8
	ld xbc, 0xEA0540
	lds de, 3
	calr FileIO_Search_SkipEntry
	cps hl, 0
	jr z, LABEL_F8ACFE
	ldi_werp 0xFA, 0
	jr LABEL_F8ACBE

LABEL_F8AC94:
	ld8_24 c, 0x027412
	exts bc
	sla bc, 5
	add_werp BC, 0xFA
	lda_24 xhl, 0x027312
	lda_dri3 XIY, 0x07, 0xEC, 0xE4
	ld xbc, 0xEA0544
	lds de, 3
	calr FileIO_Search_SkipEntry
	cps hl, 0
	jr z, FileIO_StoreIndexedEntry
	inc1_werp 0xFA
	inc 1, iz

LABEL_F8ACBE:
	ld xwa, (xsp + 4)
	st_dri3b W, 0x07, 0xE0, 0xF8
	ld e, (xwa)
	cp e, 0x2C
	jr z, FileIO_StoreIndexedEntry
	cps e, 0
	jr z, FileIO_StoreIndexedEntry
	cp_erpw 0xFA, 0x20, 0x00
	jr lt, LABEL_F8AC94

FileIO_StoreIndexedEntry:
	ld8_24 a, 0x027412
	exts wa
	sla wa, 5
	add_werp WA, 0xFA
	lda_24 xbc, 0x027312
	stib_dri 0x07, 0xE4, 0xE0, 0x00
	incdi8_24 1, 160786
	inc 1, iz
	cp iz, 0x80
	jrl lt, LABEL_F8AC79

LABEL_F8ACFE:
	pop xiz
	inc 4, xsp
	ret

LABEL_F8AD02:
	ld xde, xwa
	lds hl, 0
	lda_24 xbc, 0x0272d2
	jr LABEL_F8AD14

LABEL_F8AD0D:
	lda_dpi XBC, 0xE4
	inc 1, hl
	inc 1, xde

LABEL_F8AD14:
	ld a, (xde)
	cp a, 0x5C
	jr z, LABEL_F8AD21
	cp hl, 0x1F
	jr lt, LABEL_F8AD0D

LABEL_F8AD21:
	ld (xbc), 0x5C
	ret

ControlState_ProcessCommand:
	push xiz
	ld xiz, xwa
	ld xwa, 0xFFFFFFFF
	st32_24 0x027416, xwa
	sti8_24 0x027414, 0x00
	cp (xiz), 0x2
	jr nz, LABEL_F8AD76
	ld e, (xiz + 1)
	lda_24 xbc, 0x0272f2
	lda xwa, (xiz + 2)
	cp e, 0x80
	jr z, ControlState_ProcessNext
	cp e, 0x40
	jr z, ControlState_ProcessNext
	cp e, 0x10
	jr z, LABEL_F8AD66
	cps e, 0
	jr nz, LABEL_F8AD76
	sti8_24 0x0272d2, 0x00
	ld (xbc), 0x0
	jr ControlState_ProcessNext

LABEL_F8AD66:
	ld (xbc), 0x0
	calr LABEL_F8AD02
	inc 3, hl
	st_dri3b W, 0x07, 0xF8, 0xEC

ControlState_ProcessNext:
	calr LABEL_F8AC65

LABEL_F8AD76:
	pop xiz
	ret

LABEL_F8AD78:
	st_dri3b L, 0xFD, 0xEC, 0xFE
	push xiz
	st_dri3l XBC, 0xFD, 0x10, 0x01
	st_dri3l XWA, 0xFD, 0x14, 0x01
	ld_sril XWA, (xsp + 0x0114)
	ld (xwa), 0x0
	ld_sril XWA, (xsp + 0x0110)
	lds32 xbc, 0
	ld (xwa), xbc
	ld8_24 a, 0x027414
	exts wa
	ld (xsp + 4), wa
	ld8_24 a, 0x027412
	exts wa
	cp (xsp + 4), wa
	jrl ge, LABEL_F8AE50

LABEL_F8ADB0:
	ld xwa, 0x25C6C
	ld xbc, 0xEA0548
	calr FileIO_CopyString
	ld xwa, 0x25C6C
	ld xbc, 0x272D2
	calr FileIO_BuildFilePath
	ld xwa, 0x25C6C
	ld xbc, 0x272F2
	calr FileIO_BuildFilePath
	ld wa, (xsp + 4)
	sla wa, 5
	lda_24 xbc, 0x027312
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld xwa, 0x25C6C
	calr FileIO_BuildFilePath
	lda xbc, (xsp + 6)
	ld xwa, 0x25C6C
	call _findfirst
	ld xiz, xhl
	cp xiz, 0x0
	jr lt, LABEL_F8AE40
	lda xbc, (xsp + 12)
	ld_sril XWA, (xsp + 0x0114)
	calr FileIO_CopyString
	lda xbc, (xsp + 6)
	bitm 4, (xbc)
	jr z, LABEL_F8AE25
	ld_sril XWA, (xsp + 0x0110)
	ld xbc, 0xFFFFFFFF
	ld (xwa), xbc
	jr LABEL_F8AE2F

LABEL_F8AE25:
	ld_sril XWA, (xsp + 0x0110)
	ld xbc, (xbc + 2)
	ld (xwa), xbc

LABEL_F8AE2F:
	st32_24 0x027416, xiz
	ld wa, (xsp + 4)
	st8_24 0x027414, a
	lds hl, 0
	jr LABEL_F8AE5D

LABEL_F8AE40:
	incm 1, (xsp + 4)
	ld8_24 a, 0x027412
	exts wa
	cp (xsp + 4), wa
	jrl lt, LABEL_F8ADB0

LABEL_F8AE50:
	ld xwa, 0xFFFFFFFF
	st32_24 0x027416, xwa
	ldw hl, 0xFFFF

LABEL_F8AE5D:
	pop xiz
	st_dri3b L, 0xFD, 0x14, 0x01
	ret

LABEL_F8AE64:
	st_dri3b L, 0xFD, 0xF2, 0xFE
	push xiz
	st_dri3l XBC, 0xFD, 0x0E, 0x01
	ld xiz, xwa
	ld32_24 xwa, 0x027416
	lda xbc, (xsp + 4)
	call _findnext
	cps hl, 0
	jr z, LABEL_F8AEA5
	ld (xiz), 0x0
	ld_sril XWA, (xsp + 0x010e)
	lds32 xbc, 0
	ld (xwa), xbc
	ld32_24 xwa, 0x027416
	call _findclose
	ld xwa, 0xFFFFFFFF
	st32_24 0x027416, xwa
	ldw hl, 0xFFFF
	jr LABEL_F8AECE

LABEL_F8AEA5:
	lda xbc, (xsp + 10)
	ld xwa, xiz
	calr FileIO_CopyString
	lda xbc, (xsp + 4)
	bitm 4, (xbc)
	jr z, LABEL_F8AEC2
	ld_sril XWA, (xsp + 0x010e)
	ld xbc, 0xFFFFFFFF
	ld (xwa), xbc
	jr LABEL_F8AECC

LABEL_F8AEC2:
	ld_sril XWA, (xsp + 0x010e)
	ld xbc, (xbc + 2)
	ld (xwa), xbc

LABEL_F8AECC:
	lds hl, 0

LABEL_F8AECE:
	pop xiz
	st_dri3b L, 0xFD, 0x0E, 0x01
	ret

FileIO_SearchStringMatch:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	ldw hl, 0xFFFF
	ld32_24 xwa, 0x027416
	cp xwa, 0x0
	jr ge, LABEL_F8AEF4
	ld xwa, xiz
	ld xbc, (xsp + 4)
	jr LABEL_F8AF16

LABEL_F8AEF4:
	ld8_24 a, 0x027414
	cpda8_24 a, 160786
	jr ge, LABEL_F8AF19
	ld xwa, xiz
	ld xbc, (xsp + 4)
	calr LABEL_F8AE64
	cps hl, 0
	jr ge, LABEL_F8AF19
	incdi8_24 1, 160788
	ld xwa, xiz
	ld xbc, (xsp + 4)

LABEL_F8AF16:
	calr LABEL_F8AD78

LABEL_F8AF19:
	pop xiz
	inc 4, xsp
	ret

LABEL_F8AF1D:
	lda_24 xhl, 0x025cec
	ld (xhl), 0x0
	ld32_24 xwa, 0x027416
	cp xwa, 0x0
	ret lt
	ld8_24 c, 0x027412
	cps c, 0
	ret le
	ld8_24 a, 0x027414
	cp a, c
	ret ge
	exts wa
	sla wa, 5
	lda_24 xbc, 0x027312
	st_dri3b A, 0x07, 0xE4, 0xE0
	ldw de, 0xFFFF
	lds ix, 0
	cp (xbc), 0x0
	jr z, LABEL_F8AF78

LABEL_F8AF5D:
	ld_srib3 A, 0x07, 0xE4, 0xF0
	lda_dri3 XBC, 0x07, 0xEC, 0xF0
	cp a, 0x5C
	jr nz, LABEL_F8AF6E
	ld de, ix

LABEL_F8AF6E:
	inc 1, ix
	cp_srib_im 0x07, 0xE4, 0xF0, 0x00
	jr nz, LABEL_F8AF5D

LABEL_F8AF78:
	cps de, 0
	jr le, LABEL_F8AF86
	inc 1, de
	stib_dri 0x07, 0xEC, 0xE8, 0x00
	jr LABEL_F8AF89

LABEL_F8AF86:
	ld (xhl), 0x0

LABEL_F8AF89:
	ret

LABEL_F8AF8A:
	cp (xwa), 0x5C
	scc16 z, de
	st_dri3b A, 0x07, 0xE0, 0xE8
	ld xwa, 0x272F2
	calr FileIO_CopyString
	lds de, 0
	lda_24 xbc, 0x0272f2
	jr LABEL_F8AFA7

LABEL_F8AFA5:
	inc 1, de

LABEL_F8AFA7:
	st_dri3b W, 0x07, 0xE4, 0xE8
	cp (xwa), 0x0
	jr nz, LABEL_F8AFA5
	cp de, 0x20
	ret ge
	cps de, 0
	ret le
	dec 1, de
	cp_srib_im 0x07, 0xE4, 0xE8, 0x5C
	ret z
	ld (xwa), 0x5C
	ret

FileIO_ValidateModeAndRange:
	ld8_24 c, 0x025db6
	cps c, 2
	jr z, LABEL_F8AFDA
	cps c, 3
	jr z, LABEL_F8AFDA
	cps c, 4
	jr nz, LABEL_F8AFE5

LABEL_F8AFDA:
	cps wa, 0
	jr lt, LABEL_F8AFE5
	cpda16_24 xwa, 160458
	jr le, LABEL_F8AFE9

LABEL_F8AFE5:
	ldw hl, 0xFFFF
	ret

LABEL_F8AFE9:
	ld16_24 xbc, 0x0271ee
	cp wa, bc
	jr lt, LABEL_F8AFF9
	cpda16_24 xwa, 160240
	jr le, LABEL_F8AFFC

LABEL_F8AFF9:
	lds hl, 1
	ret

LABEL_F8AFFC:
	sub wa, bc
	muls wa, 0xE
	lda_24 xbc, 0x02723c
	cp_srib_im 0x07, 0xE4, 0xE0, 0x00
	jr nz, LABEL_F8B012
	lds hl, 2
	ret

LABEL_F8B012:
	lds hl, 0
	ret

LABEL_F8B015:
	ld16_24 xwa, 0x0272c8
	calr FileIO_ValidateModeAndRange
	cps hl, 0
	jr z, LABEL_F8B025
	ldw hl, 0xFF98
	ret

LABEL_F8B025:
	ld16_24 xhl, 0x0272c8
	ret

FileIO_ScanDirEntries:
	st_dri3b L, 0xFD, 0xEE, 0xFE
	pushw iz
	lda_24 xbc, 0x02723c
	ld xwa, xbc
	st_dri3b B, 0xE5, 0x8C, 0x00

LABEL_F8B03D:
	ld xiy, 0xEA043A
	ld xix, xwa
	lds bc, 7
	ldirw
	lda xwa, (xwa + 14)
	cp xwa, xde
	jr c, LABEL_F8B03D
	lds iz, 0
	lda xbc, (xsp + 10)
	ld xwa, 0xEA054C
	call _findfirst
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr lt, LABEL_F8B0E8
	lda xwa, (xsp + 16)
	ld (xsp + 6), xwa
	ld16_24 xwa, 0x0271ee
	cps wa, 0
	jr gt, LABEL_F8B098
	cpdi16_24 160240, 0
	jr lt, LABEL_F8B098
	neg wa
	muls wa, 0xE
	lda_24 xbc, 0x02723c
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

LABEL_F8B098:
	lds iz, 1
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cps hl, 0
	jr nz, LABEL_F8B0E1

LABEL_F8B0A8:
	ld16_24 xwa, 0x0271ee
	cp iz, wa
	jr lt, LABEL_F8B0D1
	cpda16_24 xiz, 160240
	jr gt, LABEL_F8B0D1
	ld bc, iz
	sub bc, wa
	muls bc, 0xE
	ld wa, bc
	lda_24 xbc, 0x02723c
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

LABEL_F8B0D1:
	inc 1, iz
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cps hl, 0
	jr z, LABEL_F8B0A8

LABEL_F8B0E1:
	ld xwa, (xsp + 2)
	call _findclose

LABEL_F8B0E8:
	ld hl, iz
	popw iz
	st_dri3b L, 0xFD, 0x12, 0x01
	ret

LABEL_F8B0F1:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr FileIO_ValidateModeAndRange
	cp hl, 0xFFFF
	jr nz, LABEL_F8B106
	ld16_24 xhl, 0x0272c8
	jr LABEL_F8B13B

LABEL_F8B106:
	cps hl, 1
	jr nz, LABEL_F8B134
	ld wa, iz
	extz xwa
	div wa, 0xA
	mul wa, 0xA
	ld bc, wa
	st16_24 0x0271ee, xbc
	add bc, 0x9
	ld16_24 xwa, 0x0272ca
	cp bc, wa
	jr ge, LABEL_F8B12C
	ld wa, bc

LABEL_F8B12C:
	st16_24 0x0271f0, xwa
	calr FileIO_ScanDirEntries

LABEL_F8B134:
	ld hl, iz
	st16_24 0x0272c8, xhl

LABEL_F8B13B:
	popw iz
	ret

LABEL_F8B13D:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr FileIO_ValidateModeAndRange
	cps hl, 0
	jr z, LABEL_F8B150
	lda_24 xhl, 0xea0448
	jr LABEL_F8B16D

LABEL_F8B150:
	ld16_24 xwa, 0x0271ee
	ld bc, iz
	sub bc, wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	ld xhl, 0x2723C
	add xhl, xbc

LABEL_F8B16D:
	popw iz
	ret

LABEL_F8B16F:
	sti16_24 0x0271ee, 0x0000
	sti16_24 0x0271f0, 0x0009
	calr FileIO_ScanDirEntries
	lds wa, 0
	cps hl, 0
	jr le, LABEL_F8B18A
	ld wa, hl
	dec 1, wa

LABEL_F8B18A:
	st16_24 0x0272ca, xwa
	cpdm16_24 160240, xwa
	ret le
	st16_24 0x0271f0, xwa
	ret

ResetProgressIndication:
	stdi16 34048, 65535
	stdi16 34050, 65535
	stdi16 34052, 65535
	stdi16 34054, 65535
	stdi16 34056, 65535
	stdi16 34058, 65535
	call FileIO_InitRecordTable
	ld xiy, 0xEA066A
	ld xix, 0x8A0C
	ldiw
	ret

LABEL_F8B1D1:
	stdi8 34046, 0
	calr ResetProgressIndication
	jp FileIO_ValidateRecord_Return

LABEL_F8B1DD:
	ret

LABEL_F8B1DE:
	ret

LABEL_F8B1DF:
	stdi8 34046, 0
	calr ResetProgressIndication
	call FileIO_ValidateRecord_Return
	call GetAprStatus_Entry
	cps l, 0
	ret nz
	ld xwa, 0x600002
	ld xbc, 0x1E0009C
	lds32 xde, 0
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
	jr z, LABEL_F8B221
	setda 2, 10407

LABEL_F8B221:
	call AccompSeq_StopSequence
	call AudioInit_RefreshToneBank
	call NoteMap_ProcessAndMerge
	call Voice_InitializeAll
	call Voice_InitTablePair
	call Voice_InitTableGroup
	call MIDI_SendAllSoundOff
	call LABEL_FDBB32
	inc 2, xsp
	ret

CancelOperationCleanup:
	ldda8 a, 10407
	bit 2, a
	jr z, LABEL_F8B254
	res 2, a
	stda8 10407, a

LABEL_F8B254:
	resda 3, 10407
	call SeqAcc_InitPlaybackState
	jp LABEL_FDBB2D

SignalProgressUpdate:
	call CPanel_InitButtonState_SaveRegs
	jp RefreshSwEvent

SeqPhase_OperationStateCheck:
	pushw iz
	ldda8 a, 1068
	bit 7, a
	jrl z, SeqPhase_PopIzRet
	res 7, a
	stda8 1068, a
	bitda 2, 1056
	jrl nz, SeqPhase_PopIzRet
	bitda 2, 1055
	jrl nz, SeqPhase_PopIzRet
	lds wa, 0
	calr InitializeOperationState
	cpdi16 34048, 0
	jr ge, LABEL_F8B2A2
	call GetDiskSizeInfo
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

LABEL_F8B2A2:
	ldda16 xwa, 34048
	cps wa, 2
	jr z, LABEL_F8B2B4
	cps wa, 3
	jr z, LABEL_F8B2B4
	calr ResetProgressIndication
	jrl SeqPhase_PopIzRet

LABEL_F8B2B4:
	cpdi16 34050, 0
	jr ge, LABEL_F8B2C7
	call GetEncodedFileSizeData
	stda16 34050, xhl
	calr SignalProgressUpdate

LABEL_F8B2C7:
	cpdi16 34050, 0
	jr z, SeqPhase_PopIzRet
	ldda8 a, 1068
	res 7, a
	ldfr_berp A, 0xF8
	extz iz
	cp iz, 0x13
	jr gt, SeqPhase_PopIzRet
	ld wa, iz
	call NotifyUIOfSelectionChange
	call CheckFileSystemStatus
	cps hl, 0
	jr z, SeqPhase_PopIzRet
	lds iz, 0

LABEL_F8B2F1:
	ldto_berp A, 0xF8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, LABEL_F8B2F1
	stdi8 32578, 37
	ldw wa, 0xEE
	call SoundCtrl_SendCommand
	call FileIO_ParseDirectoryEntry
	ld iz, hl
	call SwbtWr_ReinitOutputBank
	calr SignalProgressUpdate
	calr CancelOperationCleanup
	cps iz, 0
	jr ge, LABEL_F8B329
	stdi8 32578, 1
	jr LABEL_F8B32E

LABEL_F8B329:
	stdi8 32578, 35

LABEL_F8B32E:
	ldw wa, 0xEE
	call SoundCtrl_SendCommand

SeqPhase_PopIzRet:
	popw iz
	ret

LABEL_F8B337:
	dec 2, xsp
	ld (xsp), a
	ld xwa, 0x2280
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, LABEL_F8B36B
	stdi8 1060, 243
	ei 6
	pushw 0xF3
	call SeqBuf_MidiOut_WriteByte
	ld a, (xsp + 2)
	res 7, a
	extz wa
	pushw wa
	call SeqBuf_MidiOut_WriteByte
	inc 4, xsp
	call MIDI_SC0_TX_DISPATCH
	ei 0

LABEL_F8B36B:
	inc 2, xsp
	ret

LABEL_F8B36E:
	dec 4, xsp
	ld (xsp), c
	ld (xsp + 2), a
	cpdi16 34048, 0
	jr ge, LABEL_F8B387
	call GetDiskSizeInfo
	extz hl
	stda16 34048, xhl

LABEL_F8B387:
	ldda16 xwa, 34048
	cps wa, 1
	jr z, LABEL_F8B3C6
	cps wa, 0
	jr z, LABEL_F8B3BD
	cps wa, 5
	jr z, LABEL_F8B3B3
	cps wa, 2
	jr z, LABEL_F8B39F
	cps wa, 3
	jr nz, LABEL_F8B3D5

LABEL_F8B39F:
	bitda_24 0, 213236
	jr z, LABEL_F8B3AC
	ld a, (xsp)
	extz wa
	jr LABEL_F8B3C0

LABEL_F8B3AC:
	ld a, (xsp + 2)
	extz wa
	jr LABEL_F8B3C0

LABEL_F8B3B3:
	stdi8 32578, 0
	ldw wa, 0xEE
	jr LABEL_F8B3D1

LABEL_F8B3BD:
	ldw wa, 0x7D

LABEL_F8B3C0:
	call UI_PostModeChangeEvent
	jr LABEL_F8B3D5

LABEL_F8B3C6:
	calr ResetProgressIndication
	stdi8 32578, 2
	ldw wa, 0xEE

LABEL_F8B3D1:
	call SoundCtrl_SendCommand

LABEL_F8B3D5:
	inc 4, xsp
	ret

LABEL_F8B3D8:
	cpdi16 34048, 0
	jr ge, LABEL_F8B3EA
	call GetDiskSizeInfo
	extz hl
	stda16 34048, xhl

LABEL_F8B3EA:
	ldda16 xwa, 34048
	cps wa, 1
	jr z, LABEL_F8B425
	cps wa, 0
	jr z, LABEL_F8B41E
	cps wa, 5
	jr z, LABEL_F8B419
	cps wa, 2
	jr z, LABEL_F8B407
	cps wa, 3
	ret nz
	ldw wa, 0x6C
	jr UI_PostEventCommon

LABEL_F8B407:
	call DetectFileType
	cps hl, 0
	jr ge, LABEL_F8B414
	ldw wa, 0x6C
	jr UI_PostEventCommon

LABEL_F8B414:
	ldw wa, 0x6D
	jr UI_PostEventCommon

LABEL_F8B419:
	ldw wa, 0x6E
	jr UI_PostEventCommon

LABEL_F8B41E:
	ldw wa, 0x7D

UI_PostEventCommon:
	jp UI_PostModeChangeEvent

LABEL_F8B425:
	calr ResetProgressIndication
	stdi8 32578, 2
	ldw wa, 0xEE
	call SoundCtrl_SendCommand
	ret

FileIO_GetDiskCapacity:
	dec 2, xsp
	ld (xsp), a
	cpdi16 34048, 0
	jr ge, LABEL_F8B44B
	call GetDiskSizeInfo
	extz hl
	stda16 34048, xhl

LABEL_F8B44B:
	ldda16 xwa, 34048
	cps wa, 3
	jr z, LABEL_F8B483
	cps wa, 2
	jr z, LABEL_F8B483
	cps wa, 1
	jr z, LABEL_F8B472
	cps wa, 0
	jr z, LABEL_F8B46D
	cps wa, 5
	jr nz, LABEL_F8B48B
	stdi8 32578, 0
	ldw wa, 0xEE
	jr LABEL_F8B47D

LABEL_F8B46D:
	ldw wa, 0x7D
	jr LABEL_F8B487

LABEL_F8B472:
	calr ResetProgressIndication
	stdi8 32578, 2
	ldw wa, 0xEE

LABEL_F8B47D:
	call SoundCtrl_SendCommand
	jr LABEL_F8B48B

LABEL_F8B483:
	ld a, (xsp)
	extz wa

LABEL_F8B487:
	call UI_PostModeChangeEvent

LABEL_F8B48B:
	inc 2, xsp
	ret

FileIO_ValidateSignedValue:
	cps wa, 0
	jr ge, LABEL_F8B4C9
	ld de, wa
	res 15, de
	cp de, 0xFF
	jr ge, LABEL_F8B4A0
	ld l, a
	ret

LABEL_F8B4A0:
	lds iy, 0
	lda_24 xix, 0xea067c
	lds de, 0
	jr LABEL_F8B4AF

LABEL_F8B4AB:
	inc 1, iy
	inc 4, de

LABEL_F8B4AF:
	st_dri3b C, 0x07, 0xF0, 0xE8
	cp wa, (xhl)
	jr z, LABEL_F8B4BE
	cpw (xhl), 0x0
	jr lt, LABEL_F8B4AB

LABEL_F8B4BE:
	ld l, (xhl + 2)
	cp l, 0xFF
	ret c
	ld l, c
	ret

LABEL_F8B4C9:
	ldb l, 0x23
	ret

LABEL_F8B4CC:
	.byte 0x1d, 0x97, 0x07, 0xef, 0xdb, 0xd8, 0xb0, 0xf6
	.byte 0xc1, 0x7d, 0xc0, 0x3f, 0x41, 0xb0, 0xfe, 0xf1
	.byte 0x7f, 0xc0, 0xc8, 0xb0, 0xf6, 0xc1, 0x36, 0x8d
	.byte 0x23, 0xcb, 0xcf, 0x10, 0x67, 0x05, 0xcb, 0xcf
	.byte 0x16, 0xb0, 0xf3, 0xf1, 0x7e, 0xc0, 0xc8, 0x66
	.byte 0x44, 0xc1, 0x34, 0x8d, 0x3f, 0x06, 0x6e, 0x0f
	.byte 0xcb, 0xcf, 0x60, 0x66, 0x34, 0xcb, 0xcf, 0x7e
	.asciz "f/0`"
	.byte 0x68, 0x26, 0xcb
	.byte 0xcf, 0xbc, 0x66, 0x0a, 0xcb, 0xcf, 0x61, 0x66
	.byte 0x05, 0xcb, 0xcf, 0x64, 0x6e, 0x05, 0x30, 0x60
	.byte 0x00, 0x68, 0x12, 0xcb, 0xcf, 0x62, 0x6e, 0x05
	.byte 0x30, 0xb0, 0x00, 0x68, 0x08, 0xcb, 0xcf, 0x63
	.byte 0x6e, 0x07, 0x30, 0x48, 0x00, 0x1d, 0x90, 0x94
	.byte 0xf9, 0x1e, 0x64, 0xfc, 0x0e, 0xc2, 0xf2, 0x40
	.byte 0x03, 0x21, 0xc1, 0x34, 0x8d, 0x3f, 0x01, 0x6e
	.byte 0x4b, 0xf1, 0x20, 0x04, 0xca, 0xb0, 0xfe, 0xf1
	.byte 0x1f, 0x04, 0xca, 0xb0, 0xfe, 0xc9, 0x8b, 0xc9
	.byte 0xd8, 0xb0, 0xf6, 0xcb, 0xdd, 0xb0, 0xff, 0xd8
	.byte 0xae, 0x1d, 0x63, 0x94, 0xf9, 0xc2, 0xf2, 0x40
	.byte 0x03, 0x21, 0xd8, 0x12, 0xf2, 0x52, 0x05, 0xea
	.byte 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x21, 0xc9, 0xcf
	.byte 0x77, 0x66, 0x15, 0xc9, 0xcf, 0x6c, 0x66, 0x0d
	.byte 0xc9, 0xcf, 0x61, 0xb0, 0xfe, 0x30, 0x61, 0x00
	ldw	bc, 0x0064
	.ascii "h>xLþ"
	.byte 0xd8, 0x12, 0x68, 0x3c, 0xcb, 0xcf, 0x60, 0x66
	.byte 0x05, 0xcb, 0xcf, 0x7e, 0x6e, 0x36, 0xc9, 0x8b
	.byte 0xc9, 0xd8, 0xb0, 0xf6, 0xcb, 0xdd, 0xb0, 0xff
	.byte 0xcb, 0x89, 0xd8, 0x12, 0xf2, 0x52, 0x05, 0xea
	.byte 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x21, 0xc9, 0xcf
	.byte 0x77, 0x66, 0x13, 0xc9, 0xcf, 0x6c, 0x66, 0xcd
	.byte 0xc9, 0xcf, 0x61, 0xb0, 0xfe, 0x30, 0x61, 0x00
	.byte 0x31, 0x64, 0x00, 0x78, 0xa4, 0xfd, 0xd8, 0x12
	.byte 0x1b, 0x90, 0x94, 0xf9, 0x1d, 0xfa, 0x67, 0xf8
	.byte 0xdb, 0xd8, 0xb0, 0xf6, 0xd1, 0x00, 0x85, 0x3f
	.byte 0x00, 0x00, 0x69, 0x0a, 0x1d, 0x20, 0x95, 0xf8
	.byte 0xdb, 0x12, 0xf1, 0x00, 0x85, 0x53, 0xd1, 0x00
	.byte 0x85, 0x20, 0xd8, 0xd9, 0x76, 0x42, 0xff, 0xd8
	.byte 0xd8, 0x76, 0x3d, 0xff, 0xd8, 0xdd, 0xb0, 0xf6
	.byte 0xd8, 0xdb, 0x66, 0x04, 0xd8, 0xda, 0xb0, 0xfe
	.byte 0x40, 0xb0, 0x06, 0xea, 0x00, 0x1d, 0x7d, 0x94
	.byte 0xf8, 0xcf, 0xd8, 0xb0, 0xf6, 0x1b, 0x1c, 0x68
	.byte 0xf8

LABEL_F8B615:
	ldda8 a, 36150
	cp a, 0x79
	jr nz, LABEL_F8B62D
	lds32 xwa, 0
	ld xbc, 0x1C00017
	ld xde, 0xD
	jrl FmmIntMedleyFunc

LABEL_F8B62D:
	cp a, 0x6C
	jr nz, LABEL_F8B641
	lds32 xwa, 0
	ld xbc, 0x1C00017
	ld xde, 0xD
	jrl FmmSmfMedleyFunc

LABEL_F8B641:
	cp a, 0x6D
	jr nz, LABEL_F8B656
	lds32 xwa, 0
	ld xbc, 0x1C00017
	ld xde, 0xD
	jp FmmDocMedleyFunc

LABEL_F8B656:
	cp a, 0x6E
	jr nz, LABEL_F8B66A
	lds32 xwa, 0
	ld xbc, 0x1C00017
	ld xde, 0xD
	jrl FmmPdMedleyFunc

LABEL_F8B66A:
	cp a, 0x77
	ret nz
	lds32 xwa, 0
	ld xbc, 0x1C00017
	ld xde, 0xD
	calr FmmDiskMedleySelectFunc
	ret

LABEL_F8B67F:
	push xiz
	lds ix, 0
	cp c, 0x10
	jr ule, LABEL_F8B68B
	ldb c, 0x10
	jr LABEL_F8B68F

LABEL_F8B68B:
	cps c, 5
	jr ule, LABEL_F8B6A4

LABEL_F8B68F:
	ldada xde, 32586

LABEL_F8B693:
	ld hl, ix
	inc 1, ix
	extz xhl
	add xhl, xde
	ld (xhl), 0x20
	dec 1, c
	cps c, 5
	jr ugt, LABEL_F8B693

LABEL_F8B6A4:
	ld hl, ix
	cp wa, 0x2710
	jr c, LABEL_F8B6D0
	ld iy, wa
	extz xiy
	div iy, 0x2710
	ld iz, ix
	inc 1, ix
	ldada xde, 32586
	extz xiz
	add xiz, xde
	ldto_berp E, 0xF4
	add e, 0x30
	ld (xiz), e
	mul iy, 0x2710
	sub wa, iy
	jr LABEL_F8B6E5

LABEL_F8B6D0:
	cps c, 5
	jr c, LABEL_F8B6E5
	ld hl, ix
	inc 1, ix
	ldada xde, 32586
	extz xhl
	add xhl, xde
	ld (xhl), 0x20
	ld hl, ix

LABEL_F8B6E5:
	cp wa, 0x3E8
	jr c, LABEL_F8B70F
	ld iy, wa
	extz xiy
	div iy, 0x3E8
	ld iz, ix
	inc 1, ix
	ldada xde, 32586
	extz xiz
	add xiz, xde
	ldto_berp E, 0xF4
	add e, 0x30
	ld (xiz), e
	mul iy, 0x3E8
	sub wa, iy
	jr NumToAscii_HundredsDigit

LABEL_F8B70F:
	cp ix, hl
	jr z, LABEL_F8B724
	ld iy, ix
	inc 1, ix
	ldada xde, 32586
	extz xiy
	add xiy, xde
	ld (xiy), 0x30
	jr NumToAscii_HundredsDigit

LABEL_F8B724:
	cps c, 4
	jr c, NumToAscii_HundredsDigit
	ld hl, ix
	inc 1, ix
	ldada xde, 32586
	extz xhl
	add xhl, xde
	ld (xhl), 0x20
	ld hl, ix

NumToAscii_HundredsDigit:
	cp wa, 0x64
	jr c, LABEL_F8B763
	ld iy, wa
	extz xiy
	div iy, 0x64
	ld iz, ix
	inc 1, ix
	ldada xde, 32586
	extz xiz
	add xiz, xde
	ldto_berp E, 0xF4
	add e, 0x30
	ld (xiz), e
	mul iy, 0x64
	sub wa, iy
	jr NumToAscii_TensDigit

LABEL_F8B763:
	cp ix, hl
	jr z, LABEL_F8B778
	ld iy, ix
	inc 1, ix
	ldada xde, 32586
	extz xiy
	add xiy, xde
	ld (xiy), 0x30
	jr NumToAscii_TensDigit

LABEL_F8B778:
	cps c, 3
	jr c, NumToAscii_TensDigit
	ld hl, ix
	inc 1, ix
	ldada xde, 32586
	extz xhl
	add xhl, xde
	ld (xhl), 0x20
	ld hl, ix

NumToAscii_TensDigit:
	cp wa, 0xA
	jr c, LABEL_F8B7B7
	ld iy, wa
	extz xiy
	div iy, 0xA
	ld de, ix
	inc 1, ix
	ldada xbc, 32586
	extz xde
	add xde, xbc
	ldto_berp C, 0xF4
	add c, 0x30
	ld (xde), c
	mul iy, 0xA
	sub wa, iy
	jr NumToAscii_OnesDigitAndFinish

LABEL_F8B7B7:
	ldada xde, 32586
	cp ix, hl
	jr z, LABEL_F8B7CC
	ld bc, ix
	inc 1, ix
	extz xbc
	add xbc, xde
	ld (xbc), 0x30
	jr NumToAscii_OnesDigitAndFinish

LABEL_F8B7CC:
	cps c, 2
	jr c, NumToAscii_OnesDigitAndFinish
	ld bc, ix
	inc 1, ix
	extz xbc
	add xbc, xde
	ld (xbc), 0x20

NumToAscii_OnesDigitAndFinish:
	ld bc, ix
	inc 1, ix
	ldada xhl, 32586
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
