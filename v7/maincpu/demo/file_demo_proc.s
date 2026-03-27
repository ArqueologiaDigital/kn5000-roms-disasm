; =============================================================================
; File Demo Procedures
; =============================================================================
;
; File demo procedures and title handlers. Manages demo file
; playback, title display, and demo mode UI integration.
; =============================================================================

FDemo_DisplayResourceData:
	.incbin "includes/generated/v7_transplant_FDemo_DisplayResourceData.bin"
MainPreControl:
	sub xbc, 0x1e10003
	cp xbc, 0x0
	jr lt, MainPreControl_ReturnNull
	cp xbc, 0xa
	jr gt, MainPreControl_ReturnNull
	add xbc, xbc
	add xbc, Presentation_TagStrTable_0x72
	ld bc, (xbc)
	lda_24 xix, (MainPreControl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe4
; MainPreControl dispatch (11-entry, table 0xea007a)
MainPreControl_Dispatch:
	stiw_da	(0x0251d8), 0

MainPreControl_ReturnNull:
	lds32 xhl, 0
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
	ld xbc, 0x01c10001			; event code
	ld xde, xhl				; result as param
	jr FDemo_DispatchEventPost				; dispatch
	ld xwa, xde				; workspace
	calr FDemo_DisplayResourceData			; load alternate display resource
	exts xhl
	ld xwa, 0xffffffff
	ld xbc, 0x01c10003			; event code 3
	ld xde, xhl
	jr FDemo_DispatchEventPost
	ld xwa, xde				; workspace
	calr Seq_LoadNamedResource			; load named display resource
	exts xhl
	ld xwa, 0xffffffff
	ld xbc, 0x01c10002			; event code 2
	ld xde, xhl
FDemo_DispatchEventPost:
	call ApPostEvent				; dispatch event
	jr MainPreControl_ReturnNull		; return null
	stdi8	(0x28a4), 19
	call Demo_SelectEntry_ProcessSongList			; additional handler
	jr MainPreControl_ReturnNull
	cpw_da	(0x251d8), 0
	jr z, MainPreControl_Dispatch			; if zero, clear state
	call Part_InitFromPreset			; process display state
	jr MainPreControl_Dispatch
	ldw_da	hl, (0x251d8)
	exts xhl
	ret


ApPreControl:
	push xiz
	ld xiz, xde
	ld xwa, xbc
	cp xbc, 0x1e0003a
	jrl z, Seq_GetControlBlock
	cp xbc, 0x1e1000b
	jrl z, Seq_ReadStartFlag
	cp xbc, 0x1e1000d
	jrl z, Seq_PostMelodyEventAlt
	ld de, iz
	cp xbc, 0x1c00006
	jrl z, FDemo_ProcessDisplayStateQuery
	cp xbc, 0x1e10007
	jr z, Seq_StartWithFullInit
	cp xbc, 0x1e1000c
	jr z, Seq_PostMelodyEvent
	sub xwa, 0x1c10001
	cp xwa, 0x0
	jr lt, ApPreControl_ReturnNull
	cp xwa, 0x6
	jr gt, ApPreControl_ReturnNull
	add xwa, xwa
	add xwa, Presentation_TagStrTable_0x88
	ld wa, (xwa)
	lda_24 xix, (Seq_PostMelodyEvent)
	jp_ind 8, 0x07, 0xf0, 0xe0

Seq_PostMelodyEvent:
	ld xwa, 0x1410000
	ld xde, xiz

Seq_DispatchMainFunc:
	call MainFuncCall

ApPreControl_ReturnNull:
	lds32 xhl, 0
	jrl ApPreControl_Exit

Seq_StartWithFullInit:
	.incbin "includes/generated/v7_transplant_Seq_StartWithFullInit.bin"
FDemo_ProcessDisplayStateQuery:
	cps de, 0
	jrl lt, ApPreControl_ReturnNull
	cp de, 0x7f
	jrl gt, ApPreControl_ReturnNull
	sla de, 2
	lda_24 xwa, (0x024fd8)
	ld_sril3 XWA, 0x07, 0xe0, 0xe8
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
	ldw_da xhl, (0x0251d8)
	exts xhl
	jr ApPreControl_Exit

Seq_GetControlBlock:
	lda_24 xhl, (0x024882)

ApPreControl_Exit:
	pop xiz
	ret

FDemo_MultiGuardCheck:
	.incbin "includes/generated/v7_transplant_FDemo_MultiGuardCheck.bin"
Banner_ReturnZero:
	lds	hl, 0
	ret
FDemo_LoadRegsAndPostEvent:
	; --- Routine 2: load regs, jp FA9D58 (23 bytes) ---
	ld xwa, 0xffffffff
	ld xbc, 0x01c10007
	ld xde, 0x00ea009e
	jp ApPostEvent


FDemo_LinkedListSearch:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ldl_da xiz, (0x880008)
	ld xwa, (xiz + 16)
	or xwa, xwa
	jr z, FDemo_LinkedListSearchFound

FDemo_LinkedListSearchLoop:
	.incbin "includes/generated/v7_transplant_FDemo_LinkedListSearchLoop.bin"
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
; 1) Search: Walks a fixed-size array at 0x249d8 (up to 63 entries,
;    24 bytes each). Calls compare function (0xff3f35) for each node.
;    Returns pointer to matching entry or falls through.
; 2) Insert: Walks the same list checking node+16 for empty slot,
;    calls insert function (0xff3f4d), returns success (HL=1) or fail.
FDemo_LinkedListSearchInsert:
	.incbin "includes/generated/v7_transplant_FDemo_LinkedListSearchInsert.bin"
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
	.incbin "includes/generated/v7_transplant_FDemo_FileOpenAndProcess.bin"
FDemo_FileOpen_DoOpen:
	lda	xwa, (xsp+10)
	ld xbc, 0x00ea00a8
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
	.incbin "includes/generated/v7_transplant_DemoMode_Main_Operation.bin"
FDemo_IndicatorSetup:
	.incbin "includes/generated/v7_transplant_FDemo_IndicatorSetup.bin"
DemoMode_Initialize:
	.incbin "includes/generated/v7_transplant_DemoMode_Initialize.bin"
FDemo_PostBannerCheck:
	.incbin "includes/generated/v7_transplant_FDemo_PostBannerCheck.bin"
Demo_SelectionEntryHandler:
	.incbin "includes/generated/v7_transplant_Demo_SelectionEntryHandler.bin"
Demo_SelectEntry_NoNewButton:
	stdi8 (3379), 0
	ret

Demo_SelectEntry_PreSaveCheck:
	.incbin "includes/generated/v7_transplant_Demo_SelectEntry_PreSaveCheck.bin"
Demo_SelectEntry_CheckVoiceKeys:
	.incbin "includes/generated/v7_transplant_Demo_SelectEntry_CheckVoiceKeys.bin"
Demo_SelectEntry_SaveVoice:
	calr Voice_SavePreset

Demo_SelectEntry_ExitDispatch:
	ldmm_sd24b 0xe3, 0xff, 0x00, 0x4a, 0xf2
	ret

Demo_SelectEntry_ByteTable:
	.incbin "includes/generated/v7_transplant_Demo_SelectEntry_ByteTable.bin"
Demo_SelectEntry_ProcessSongList:
	.incbin "includes/generated/v7_transplant_Demo_SelectEntry_ProcessSongList.bin"
Demo_SelectEntry_ManualSelect:
	.incbin "includes/generated/v7_transplant_Demo_SelectEntry_ManualSelect.bin"
Demo_SelectEntry_ToCountdown:
	jrl Demo_ResetCountdownTimer

Demo_SelectEntry_StartAutoPlay:
	.incbin "includes/generated/v7_transplant_Demo_SelectEntry_StartAutoPlay.bin"
Demo_SelectEntry_TimerTick:
	calr Demo_SelectEntry_CheckCPanel
	cpw_da (0x25b84), 0
	call_24 nz, Banner_Loop_Check
	ldb_d8 a, (3375)
	cps a, 0
	ret z
	dec 1, a
	stb_d8 (3375), a
	cp a, 0xa
	jr nz, Demo_SelectEntry_CheckCountdown
	ldb_d8 a, (0x28a4)
	extz wa
	calr Demo_ParseSlideHeader
	jrl Demo_SelectEntry_PlaySong

Demo_SelectEntry_CheckCountdown:
	ldb_d8 a, (3375)
	cps a, 3
	jrl z, Demo_SelectEntry_StartPlayback
	cps a, 1
	ret nz
	stdi8 (0x2966), 133
	ret

Demo_SelectEntry_CheckCPanel:
	.incbin "includes/generated/v7_transplant_Demo_SelectEntry_CheckCPanel.bin"
Demo_SelectEntry_Debounce:
	.incbin "includes/generated/v7_transplant_Demo_SelectEntry_Debounce.bin"
Demo_SelectEntry_AfterSongLoad:
	.incbin "includes/generated/v7_transplant_Demo_SelectEntry_AfterSongLoad.bin"
Demo_SelectEntry_CheckSongCount:
	call Seq_IsMelodyActive
	cps hl, 0
	jr z, Demo_SelectEntry_CheckLimit18
	cpdi8 (4440), 19
	jr ugt, Demo_SelectEntry_ClampSongIdx
	jr Demo_SelectEntry_UpdateDisplay

Demo_SelectEntry_CheckLimit18:
	cpdi8 (4440), 18
	jr ule, Demo_SelectEntry_UpdateDisplay

Demo_SelectEntry_ClampSongIdx:
	stdi8 (4440), 18

Demo_SelectEntry_UpdateDisplay:
	calr Demo_SelectEntry_LoadPattern
	calr Demo_SelectEntry_DrawSecondary
	calr Demo_ResetCountdownTimer
	incdi8 1, (4440)
	ret

Demo_SelectEntry_LoadPattern:
	ldb_d8 a, (4440)
	extz wa
	add wa, wa
	lda_24 xbc, (Presentation_TagStrTable_0xA4)
	ldmm_srib 0x07, 0xe4, 0xe0, 0xa4, 0x28
	ret

Demo_SelectEntry_DrawSecondary:
	.incbin "includes/generated/v7_transplant_Demo_SelectEntry_DrawSecondary.bin"
Demo_SelectEntry_PlaySong:
	.incbin "includes/generated/v7_transplant_Demo_SelectEntry_PlaySong.bin"
Demo_SelectEntry_StartPlayback:
	.incbin "includes/generated/v7_transplant_Demo_SelectEntry_StartPlayback.bin"
Audio_WaitForReady:
	ld xbc, 0xf000
	ldb_d8 a, (1056)

Audio_WaitForReady_PollLoop:
	bit 2, a
	jr z, Audio_WaitForReady_Dispatch
	sub xbc, 0x1
	jr nz, Audio_WaitForReady_PollLoop

Audio_WaitForReady_Dispatch:
	.incbin "includes/generated/v7_transplant_Audio_WaitForReady_Dispatch.bin"
Demo_ResetCountdownTimer:
	stdi8 (3375), 15
	ret

Timer7_DisableInterrupt:
	.incbin "includes/generated/v7_transplant_Timer7_DisableInterrupt.bin"
Voice_LoadVoiceTable:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0

Voice_LoadVoiceTable_Loop:
	stb_erp A, 0xfb
	extz wa
	calr Demo_LookupPartTableEntry
	ld c, (xhl + 13)
	stb_erp A, 0xfb
	stb_da (0x025b86), a
	and c, 0xf
	stb_da (0x025b88), c
	push xde
	push xhl
	push xix
	push xiz
	ldb_da w, (0x025b88)
	ldb_da a, (0x025b86)
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
	stib_da (0x025b86), 0x19
	and c, 0xf
	stb_da (0x025b88), c
	push xde
	push xhl
	push xix
	push xiz
	ldb_da w, (0x025b88)
	ldb_da a, (0x025b86)
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
	stb_erp A, 0xfb
	extz wa
	lda_d16 xbc, (0xf1a0)
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
	setda 6, 0x28b3
	lda xwa, (xsp + 2)
	ld (xwa), 0xd3
	ld (xwa + 1), 0x7e
	ld (xwa + 2), 0x7f
	stb_erp C, 0xfb
	ld (xwa + 3), c
	lds bc, 4
	call SeqBuf_WriteMidiEventDirect

Banner_Loop_Exit:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, Banner_Loop_CheckEntry
	stiw_da (0x025b84), 0x0000
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
	stdi8 (1073), 0
	ret

Demo_ScanActivePartChannels:
	ldb l, 0x0
	lda_d16 xix, (0xf1a0)

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
	lda_24 xde, (Presentation_TagStrTable_0xD2)
	ldw_sri BC, 0x07, 0xe8, 0xe4
	andda16 xbc, 0xf19e
	jr z, Demo_ScanPartSkipToEnd
	muls wa, 0x3
	lda_d16 xbc, (0xf250)
	bit_dri 7, 0x07, 0xe4, 0xe0
	jr z, Demo_ScanPartSkipToEnd
	ld a, l
	inc 1, a
	stb_d8 (3414), a
	setda 0, 3412
	setda 2, 0x287b
	jr Demo_ScanPartDone

Demo_ScanPartSkipToEnd:
	ldb l, 0xf

Demo_ScanPartNext:
	inc 1, l
	cp l, 0x10
	jr c, Demo_ScanPartLoop

Demo_ScanPartDone:
	cp l, 0x10
	ret nz
	resda 0, 3412
	resda 2, 0x287b
	ret

Voice_SavePreset:
	.incbin "includes/generated/v7_transplant_Voice_SavePreset.bin"
Voice_CopyPreset:
	.incbin "includes/generated/v7_transplant_Voice_CopyPreset.bin"
Demo_LookupPartTableEntry:
	.incbin "includes/generated/v7_transplant_Demo_LookupPartTableEntry.bin"
Demo_WaitForDisplayBit:
	ld xwa, NakaData_RomEnd
	bitda 2, (1056)
	ret z

Demo_WaitForDisplayBit_Loop:
	sub xwa, 0x1
	ret z
	bitda 2, (1056)
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
	lda_24 xhl, (0x0ab000)

Demo_GetPresetBase_StoreAndRet:
	stb_dri C, 0xed, 0x00, 0x08
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
	lda_24 xhl, (0x0ab000)

Demo_GetPresetBaseAlt_StoreAndRet:
	stb_dri C, 0xed, 0x00, 0x03
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
	lda_24 xwa, (0x0ab000)

Demo_GetPresetBaseExt_StoreAndRet:
	stb_dri C, 0xe1, 0xd0, 0x00
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
	lda_24 xwa, (0x0ab000)

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
	lda_24 xwa, (0x0ab000)

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
	stb_erp C, 0xfb
	extz bc
	ld xwa, (xsp + 4)
	ldb_sri A, 0x07, 0xe0, 0xe4
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
	lda_24 xwa, (Presentation_TagStrTable_0xD2)
	ldw_sri WA, 0x07, 0xe0, 0xe4
	and wa, (xsp + 2)
	jrl z, Demo_RecordChainLoopExit
	stb_erp A, 0xfb
	mul a, 0x3
	ld c, a
	extz bc
	ld xwa, (xsp + 8)
	bit_dri 7, 0x07, 0xe0, 0xe4
	jrl z, Demo_RecordChainLoopExit
	ld a, (xsp + 14)
	extz wa
	calr Demo_GetPresetBaseForPart
	ld xwa, xhl
	stb_erp C, 0xfb
	mul c, 0x3
	ld e, c
	extz de
	inc 1, de
	ld xbc, (xsp + 8)
	ldw_sri BC, 0x07, 0xe4, 0xe8
	lds de, 0
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
	cps hl, 0
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
	cps hl, 0
	jr z, RecordChain_SkipToNext
	jr RecordChain_ContinueLoop

RecordChain_HandleStatusD2:
	cp hl, 0xd2
	jr nz, RecordChain_HandleStatusD0
	calr RecordChain_ReadNextByte
	cps hl, 0
	jr z, RecordChain_SkipToNext
	jr RecordChain_ContinueLoop

RecordChain_HandleStatusD0:
	cp a, 0xd0
	jr nz, RecordChain_SkipToNext
	calr RecordChain_ReadNextByte
	cps hl, 0
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
	stl_da (0x025b8a), xwa
	stw_da (0x03ec4e), xbc
	stw_da (0x025b8e), xde
	ret

RecordChain_ReadNextByte:
	ldw_da xwa, (0x03ec4e)
	cp wa, 0xffff
	jr nz, RecordChain_ReadAdvance
	ldw hl, 0xffff
	ret

RecordChain_ReadAdvance:
	sll wa, 8
	sub wa, 0x100
	ld de, wa
	extz xde
	addda32_24 xde, (0x25b8a)
	ldw_da xwa, (0x025b8e)
	ld bc, wa
	extz xbc
	inc 5, xbc
	add xbc, xde
	ld l, (xbc)
	extz hl
	inc 1, wa
	stw_da (0x025b8e), xwa
	cp wa, 0xfa
	ret ule
	ld wa, (xde + 3)
	stw_da (0x03ec4e), xwa
	stiw_da (0x025b8e), 0x0000
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
	lda_24 xbc, (Presentation_TagStrTable_0x100)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	extz xwa
	lds bc, 0
	call FileIO_SeekAndReadBlock
	ldiw_erp 0xfa, 1
	lds iz, 0
	jr FileIO_CheckSig_LoopTest

FileIO_CheckSig_ReadLoop:
	call FileIO_ReadByte
	cps hl, 0
	jr lt, FileIO_CheckSig_Fail
	ld a, (xsp + 4)
	extz wa
	sla wa, 3
	lda_24 xbc, (Presentation_TagStrTable_0xFC)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ldb_sri A, 0x07, 0xe0, 0xf8
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
	lda_24 xbc, (Presentation_TagStrTable_0x102)
	ld de, iz
	cpw_sri_rm DE, 0x07, 0xe4, 0xe0
	jr c, FileIO_CheckSig_ReadLoop

FileIO_CheckSig_Return:
	call FileIO_SeekRead_ExtReturn
	stw_erp HL, 0xfa
	pop xiz
	inc 2, xsp
	ret

FileIO_ValidateFileSignature:
	lda xsp, (xsp - 26)
	push xiz
	ld (xsp + 28), a
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	cps hl, 0
	jr ge, FileIO_ValidateSig_Process
	lds hl, 0
	jr FileIO_ValidateSig_Return

FileIO_ValidateSig_Process:
	ld a, l
	ldb_erp A, 0xf8
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
	ld xbc, Presentation_TagTableEnd_0x33
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, FileIO_ValidateSig_Done
	ld a, (xsp + 28)
	extz wa
	calr FileIO_CheckRegionSignature
	ldw_erp HL, 0xfa
	call FileIO_CloseHandle

FileIO_ValidateSig_Done:
	stw_erp HL, 0xfa

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
	lda_dri XSP, 0x07, 0xe0, 0xf8
	inc 1, iz
	cps iz, 3
	jr lt, FileIO_ReadValidateHdr_Loop
	call FileIO_SeekRead_ExtReturn
	lda xwa, (xsp + 2)
	ld xbc, Presentation_TagTableEnd_0x3F
	lds de, 3
	call FileIO_Search_SkipEntry
	cps hl, 0
	jr z, FileIO_ReadHeader_TypeMatch
	lda xwa, (xsp + 2)
	ld xbc, Presentation_TagTableEnd_0x37
	lds de, 3
	call FileIO_Search_SkipEntry
	cps hl, 0
	jr z, FileIO_ReadHeader_TypeMatch
	lda xwa, (xsp + 2)
	ld xbc, Presentation_TagTableEnd_0x3B
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
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	cps hl, 0
	jr ge, FileIO_ValidateOpen_Process
	lds hl, 0
	jr FileIO_ValidateOpen_Return

FileIO_ValidateOpen_Process:
	ld a, l
	ldb_erp A, 0xf8
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
	ld xbc, Presentation_TagTableEnd_0x43
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, FileIO_ValidateOpen_Done
	calr FileIO_ReadAndValidateHeader
	ldw_erp HL, 0xfa
	call FileIO_CloseHandle

FileIO_ValidateOpen_Done:
	stw_erp HL, 0xfa

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
	ldl_da xwa, (Presentation_TagTableEnd_0x47)
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
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	cps hl, 0
	jr lt, FileIO_ValidateRegion_NoFile
	ld a, l
	ldb_erp A, 0xf8
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
	ld xbc, Presentation_TagTableEnd_0x4D
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
	ldw_erp HL, 0xfa

FileIO_ValidateRegion_Close:
	call FileIO_CloseHandle
	stw_erp HL, 0xfa

FileIO_ValidateRegion_Return:
	pop xiz
	lda xsp, (xsp + 24)
	ret

FileIO_ReadHeaderAtF:
	pushw iz
	lds iz, 1
	ld xwa, 0xf
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
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	cps hl, 0
	jr lt, FileIO_ValidateExt_NoFile
	ld a, l
	ldb_erp A, 0xf8
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
	ld xbc, Presentation_TagTableEnd_0x51
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
	ldw_erp HL, 0xfa

FileIO_ValidateExt_Close:
	call FileIO_CloseHandle
	stw_erp HL, 0xfa

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
	lds	de, 0
	call FileIO_ReadHeader				; init display region descriptor
	lda xwa, (xsp + 2)			; reload buffer ptr
	ld xbc, 0x00ea0194			; resource ID for region 0
	call FileIO_OpenWithMode				; open display resource
	cps hl, 0				; check result (negative=error)
	jr ge, LoadRegion0_OpenSuccess			; success, continue
	call FileIO_ReturnError				; close resource (error path)
	jr LoadRegion0_Return				; return
LoadRegion0_OpenSuccess:
	.incbin "includes/generated/v7_transplant_LoadRegion0_OpenSuccess.bin"
LoadRegion0_AltPath:
	.incbin "includes/generated/v7_transplant_LoadRegion0_AltPath.bin"
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
	lds	de, 1
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, 0x00ea0198			; resource ID for region 1
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
	call BitMapOut_UpdateWidget_Done_0x98
	ld xwa, 0x00000010
	lds	bc, 0
	call FileIO_SeekAndReadBlock				; set region param
	lda_24 xwa, (0x1ed350); VRAM base
	add xwa, 0x00000010			; offset +0x10
	ld xbc, 0x00000010			; size = 0x10
	call FileIO_ReadBlock
	ld xwa, 0x000000b0
	lds	bc, 0
	call FileIO_SeekAndReadBlock
	lda_24 xwa, (0x1ed350)
	ld bc, (xwa + 13)			; load field at offset 0x0d
	extz xbc
	sll xbc, 3				; multiply by 8
	add xwa, 0x000000b0			; offset +0xb0
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	lds	wa, 0
	ld bc, iz
	call BitMapOut_UpdateWidget_Done_0x99
	jr LoadRegion1_Finalize
LoadRegion1_AltPmLoad:
	.incbin "includes/generated/v7_transplant_LoadRegion1_AltPmLoad.bin"
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
	lds	de, 7
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, 0x00ea019c			; resource ID for region 7
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadRegion7_OpenSuccess
	call FileIO_ReturnError
	jr LoadRegion7_Return
LoadRegion7_OpenSuccess:
	.incbin "includes/generated/v7_transplant_LoadRegion7_OpenSuccess.bin"
LoadRegion7_AllocFailed:
	ldw iz, 0xff38				; alloc failure error code
LoadRegion7_PostMidi:
	.incbin "includes/generated/v7_transplant_LoadRegion7_PostMidi.bin"
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
	lds	de, 2
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, 0x00ea01a0			; resource ID for region 2
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
	ld xwa, 0x000ab000			; ext memory base
	ld xbc, 0x00005000			; size = 0x5000
	call FileIO_ReadBlock
	lda_24 xwa, (0x0b0000); ext memory region 2
	ld xde, xwa
	lda_24 xbc, (0x0fd800); end address
	sub xbc, xde				; size = 0x0fd800 - 0x0b0000
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call SeqLoadPost				; post-setup
	jr LoadRegion2_Finalize
LoadRegion2_AltSeqInit:
	call SeqLoad_JumpInitFromPreset				; alternate ext memory init
	ld xwa, 0x000ab000
	ld xbc, 0x00000800			; smaller size
	call FileIO_ReadBlock
	lda_24 xwa, (0x0b0000)
	ld xde, xwa
	lda_24 xbc, (0x0fd800)
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


; === v7-specific block: FileIO_LoadSongRegion8 (372 bytes) ===
FileIO_LoadSongRegion8:
	.incbin "includes/generated/v7_block_fileio_loadsongregion8.bin"
; === end v7 block ===
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
	lds	de, 3
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, 0x00ea01b0			; resource ID for region 3
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
	lda_24 xwa, (0x094800)
	ld xde, xwa
	lda_24 xbc, (0x0ab000)
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
	lds	de, 5
	call FileIO_ReadHeader
	lda xwa, (xsp + 2)
	ld xbc, 0x00ea01b4			; resource ID for region 5
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
	lda_24 xwa, (0x1e8800)
	ld xde, xwa
	lda_24 xbc, (0x1ec400)
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	ld wa, iz
	call msp_ld_ato
	jr LoadRegion5_Finalize
LoadRegion5_AltPath:
	call DualVoice_WriteBackSlots_0x5				; alternate path
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
	ld xbc, 0x00ea01b8			; resource ID for region 6
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
	call Flash_SlotUpdateOpsBlock_0x336
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
	lds	de, 4
	call FileIO_ReadHeader
	lda xwa, (xsp + 18)
	ld xbc, 0x00ea01bc			; resource ID for region 4
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadRegion4_OpenSuccess
	call FileIO_ReturnError
	jrl LoadRegion4_Return
LoadRegion4_OpenSuccess:
	.incbin "includes/generated/v7_transplant_LoadRegion4_OpenSuccess.bin"
LoadRegion4_AltIterLoop:
	lds	iz, 0
LoadRegion4_ReadByteLoop:
	call FileIO_ReadByte
	cps hl, 0
	jr lt, LoadRegion4_ReadDone
	lda xwa, (xsp + 2)
	st_rrb	l, xwa, iz
	inc 1, iz
	cp iz, 0x0010				; loop 16 times
	jr lt, LoadRegion4_ReadByteLoop
LoadRegion4_ReadDone:
	.incbin "includes/generated/v7_transplant_LoadRegion4_ReadDone.bin"
LoadRegion4_PostSave:
	.incbin "includes/generated/v7_transplant_LoadRegion4_PostSave.bin"
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
	cps iz, 0
	jr ge, ParseDir_ValidIndex
	ldw hl, 0xff98
	jrl ParseDir_Return

ParseDir_ValidIndex:
	ld wa, iz
	call GetFileEntryPtr
	ld (xsp + 4), xhl
	stb_erp C, 0xf8
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
	lda_24 xbc, (Presentation_TagTableEnd_0x81)
	ldb_sri A, 0x07, 0xe4, 0xe0
	call FileIO_WriteRecordName_Done
	cps l, 0
	jr z, FileIO_RecordLoop_Continue
	ld wa, iz
	muls wa, 0x6
	lda_24 xbc, (Presentation_TagTableEnd_0x81)
	ldb_sri A, 0x07, 0xe4, 0xe0
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileIO_RecordLoop_Continue
	lda xwa, (xsp + 10)
	ld bc, iz
	muls bc, 0x6
	lda_24 xde, (Presentation_TagTableEnd_0x83)
	exts xbc
	add xbc, xde
	ld xix, (xbc)
	call (xix)
	cps hl, 0
	jr ge, ParseDir_IncrementCount
	cpiw_erp 0xfa, 0
	jr lt, FileIO_RecordLoop_Continue
	ldw_erp HL, 0xfa
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
	cpiw_erp 0xfa, 0
	jr lt, FileIO_FinalizeRecordLookup
	ldw_erp HL, 0xfa
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
	cpiw_erp 0xfa, 0
	jr lt, ParseDir_GetResult
	ldi_erpw 0xfa, 0x98, 0xff

ParseDir_GetResult:
	stw_erp HL, 0xfa

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
	lda_d16	xbc, (0xffc0)
	lda_d16	xwa, (0xf980)
	ld (xsp + 4), xbc			; save end address
	sub (xsp + 4), xwa			; size = end - start
	lda_24 xbc, (0x1e7800)
	lda_24 xiz, (0x1e8000)
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
	lds	de, 0
	call FileIO_ReadHeader				; init region
	lda xwa, (xsp + 8)			; buffer
	ld xbc, 0x00ea01f0			; resource ID region 0
	call FileIO_OpenWithMode				; open resource
	cps hl, 0
	jr ge, SaveRegion0_OpenSuccess			; success
	call FileIO_ReturnError				; close/cleanup
	jr SaveRegion0_Return				; return error
SaveRegion0_OpenSuccess:
	.incbin "includes/generated/v7_transplant_SaveRegion0_OpenSuccess.bin"
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
	lda_24 xbc, (0x1ed350); base address
	cps l, 0				; check mode
	jr z, SaveRegion1_FullRange			; mode 0 path
	ld iz, (xbc + 13)			; get size param
	extz xiz
	sla xiz, 3				; * 8
	add xiz, 0x000000b0			; + 0xb0 base size
	jr SaveRegion1_CheckSpace
SaveRegion1_FullRange:
	lda_24 xiz, (0x200000); full range
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
	lds	de, 1
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, 0x00ea01f4			; resource ID region 1
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, SaveRegion1_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion1_Return
SaveRegion1_OpenSuccess:
	call FileIO_GetRecordAttr_Check				; re-check mode
	cps l, 0
	jr z, SaveRegion1_AltPmSave			; mode 0 path
	ld xwa, 0x001ed350
	ld xbc, xiz
	call FileIO_WriteByte_Impl				; save VRAM range
	ld xwa, 0x0000000f			; param
	lds	bc, 0
	call FileIO_SeekAndReadBlock				; set region param
	ldw wa, 0x0008
	call FileIO_ReadByte_BufferHit				; configure
	call FileIO_ReturnError
	ld iz, hl
	jr SaveRegion1_Finalize
SaveRegion1_AltPmSave:
	.incbin "includes/generated/v7_transplant_SaveRegion1_AltPmSave.bin"
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
	ldw hl, 0xff9b
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
	.incbin "includes/generated/v7_transplant_SaveRegion7_OpenSuccess.bin"
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
	ld xwa, 0x000ab000			; ext mem base
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
	ldw hl, 0xff9b
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
	ldw hl, 0xff9b
	jr SaveRegion5_Return
SaveRegion5_SpaceOk:
	lda xwa, (xsp + 8)
	ld xbc, xiz
	lds	de, 5
	call FileIO_ReadHeader
	lda xwa, (xsp + 8)
	ld xbc, 0x00ea0204			; resource ID region 5
	call FileIO_OpenWithMode
	cps hl, 0
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
	ld xbc, 0x00ea0208			; resource ID region 6
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, SaveRegion6_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion6_Return
SaveRegion6_OpenSuccess:
	call Flash_SlotUpdateOpsBlock_0x480				; region-specific handler
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
	lds	de, 4
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	ld xbc, 0x00ea020c			; resource ID region 4
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, SaveRegion4_OpenSuccess
	call FileIO_ReturnError
	jr SaveRegion4_Return
SaveRegion4_OpenSuccess:
	.incbin "includes/generated/v7_transplant_SaveRegion4_OpenSuccess.bin"
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
	ldw hl, 0xff98
	jrl SaveAll_Return

SaveAll_GetEntryPtr:
	ld wa, iz
	call GetFileEntryPtr
	ld xde, xhl
	stb_erp C, 0xf8
	extz bc
	lda xwa, (xsp + 20)
	call FileIO_FormatFileIndex
	ldiw_erp 0xfa, 0

SaveAll_CheckRecordLoop:
	stw_erp WA, 0xfa
	muls wa, 0x6
	lda_24 xbc, (Resource_Region3_Start_0x10)
	ldb_sri A, 0x07, 0xe4, 0xe0
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, SaveAll_NextRecord
	lda xbc, (xsp + 20)
	stw_erp WA, 0xfa
	muls wa, 0x6
	lda_24 xde, (Resource_Region3_Start_0x10)
	ldb_sri E, 0x07, 0xe8, 0xe0
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
	stb_erp C, 0xf8
	extz bc
	lda xwa, (xsp + 20)
	call FileIO_FormatFileIndex
	ldiw_erp 0xfa, 0

; File demo process callback dispatch
FileDemo_ProcessCallback:
	stw_erp WA, 0xfa
	muls wa, 0x6
	lda_24 xbc, (Resource_Region3_Start_0x10)
	ldb_sri A, 0x07, 0xe4, 0xe0
	call FileIO_FormatName_Return
	cps l, 0
	jr z, SaveAll_ProcessNextRecord
	lda xwa, (xsp + 20)
	stw_erp BC, 0xfa
	muls bc, 0x6
	lda_24 xde, (Resource_Region3_Start_0x12)
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
	stw_erp WA, 0xfa
	muls wa, 0x6
	lda_24 xbc, (Resource_Region3_Start_0x10)
	ldb_sri A, 0x07, 0xe4, 0xe0
	call FileIO_FormatName_Return
	cps l, 0
	jr z, SaveAll_RollbackNext
	lda xbc, (xsp + 20)
	stw_erp WA, 0xfa
	muls wa, 0x6
	lda_24 xde, (Resource_Region3_Start_0x10)
	ldb_sri E, 0x07, 0xe8, 0xe0
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
	cps hl, 0
	jr ge, LoadSMF_GetRecordPtr
	ldw hl, 0xff98
	jr LoadSMF_Return

LoadSMF_GetRecordPtr:
	ld wa, hl
	call GetRecordPtrForFile
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	ld xbc, Resource_Region3_Start_0x40
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
	ld xbc, Resource_Region3_Start_0x44
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, LoadVariant_OpenAndProcess
	call FileIO_ReturnError
	jr LoadVariant_Return

LoadVariant_OpenAndProcess:
	stb_erp A, 0xf8
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
	ldw hl, 0xff98
	jrl MultiPass_Return

MultiPass_SetupEntry:
	ld wa, (xsp + 4)
	ldb_erp A, 0xf8
	extz iz
	ld wa, (xsp + 4)
	call GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 20)
	ld bc, iz
	call FileIO_FormatFileIndex
	lds iz, 0

MultiPass_RetryLoop:
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri A, 0x07, 0xe0, 0xf8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, MultiPass_LoopNext
	lda xbc, (xsp + 20)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
	lda xwa, (xsp + 6)
	call FileIO_ReadHeader
	lda xwa, (xsp + 6)
	call FileIO_OpenDefault
	ldw_erp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, MultiPass_StoreResult

MultiPass_LoopNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, MultiPass_RetryLoop
	ld wa, (xsp + 4)
	ldb_erp A, 0xf8
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
	ld xbc, Resource_Region3_Start_0x48
	call FileIO_OpenWithMode
	cps hl, 0
	jr ge, MultiPass_Finalize
	call FileIO_ReturnError
	jr MultiPass_Return

MultiPass_Finalize:
	ld wa, (xsp + 30)
	extz wa
	call SeqSave_PreparePartData
	ldw_erp HL, 0xfa
	call FileIO_CloseHandle
	cpiw_erp 0xfa, 0
	jr ge, MultiPass_StoreResult
	lda xwa, (xsp + 6)
	call FileIO_OpenDefault

MultiPass_StoreResult:
	stw_erp HL, 0xfa

MultiPass_Return:
	pop xiz
	lda xsp, (xsp + 28)
	ret

FileIO_ByteBlock_DemoProc1:
	.incbin "includes/generated/v7_transplant_FileIO_ByteBlock_DemoProc1.bin"
ReadSingleFile:
	lda xsp, (xsp - 24)
	push xiz
	ldiw_erp 0xfa, 0
	call GetCurrentFileIndex
	ld iz, hl
	cps iz, 0
	jr ge, ReadSingle_SetupEntry
	ldw hl, 0xff98
	jr ReadSingle_Return

ReadSingle_SetupEntry:
	ld wa, iz
	call GetFileEntryPtr
	ld xde, xhl
	stb_erp C, 0xf8
	extz bc
	lda xwa, (xsp + 18)
	call FileIO_FormatFileIndex
	lds iz, 0

ReadSingle_RetryLoop:
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri A, 0x07, 0xe0, 0xf8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, ReadSingle_LoopNext
	lda xbc, (xsp + 18)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
	lda xwa, (xsp + 4)
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	call FileIO_OpenDefault
	ldw_erp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, ReadSingle_StoreResult

ReadSingle_LoopNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, ReadSingle_RetryLoop

ReadSingle_StoreResult:
	stw_erp HL, 0xfa

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
	cps iz, 0
	jr ge, ReadDual_SetupEntries
	ldw hl, 0xff98
	jr ReadDual_Return

ReadDual_SetupEntries:
	ld wa, iz
	call GetFileEntryPtr
	ld xde, xhl
	stb_erp C, 0xf8
	extz bc
	lda xwa, (xsp + 32)
	call FileIO_FormatFileIndex
	stb_erp C, 0xf8
	extz bc
	lda xwa, (xsp + 42)
	ld xde, (xsp + 52)
	call FileIO_FormatFileIndex
	lds iz, 0

ReadDual_RetryLoop:
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri A, 0x07, 0xe0, 0xf8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, ReadDual_LoopNext
	lda xbc, (xsp + 32)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
	lda xwa, (xsp + 4)
	call FileIO_ReadHeader
	lda xbc, (xsp + 42)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
	lda xwa, (xsp + 18)
	call FileIO_ReadHeader
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 18)
	call FileIO_CopyAndOpen
	ldw_erp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, ReadDual_StoreResult

ReadDual_LoopNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, ReadDual_RetryLoop

ReadDual_StoreResult:
	stw_erp HL, 0xfa

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
	lds iz, 0

ReadDualEx_FirstLoop:
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri C, 0x07, 0xe0, 0xf8
	ld wa, (xsp + 62)
	call FileIO_CheckRecordByFile
	cps l, 0
	jr z, ReadDualEx_FirstLoopNext
	lda xbc, (xsp + 52)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
	lda xwa, (xsp + 28)
	call FileIO_ReadHeader
	lda xbc, (xsp + 42)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
	lda xwa, (xsp + 14)
	call FileIO_ReadHeader
	lda xwa, (xsp + 28)
	lda xbc, (xsp + 14)
	call FileIO_CopyAndOpen
	ldw_erp HL, 0xfa
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
	lds iz, 0

ReadDualEx_SecondLoop:
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri A, 0x07, 0xe0, 0xf8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, ReadDualEx_SecondLoopNext
	lda xbc, (xsp + 52)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
	lda xwa, (xsp + 28)
	call FileIO_ReadHeader
	lda xbc, (xsp + 42)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
	lda xwa, (xsp + 14)
	call FileIO_ReadHeader
	lda xwa, (xsp + 28)
	lda xbc, (xsp + 14)
	call FileIO_CopyAndOpen
	ldw_erp HL, 0xfa
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
	lds iz, 0

ReadDualEx_ThirdLoop:
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri C, 0x07, 0xe0, 0xf8
	ld wa, (xsp + 62)
	call FileIO_CheckRecordByFile
	cps l, 0
	jr z, ReadDualEx_ThirdLoopNext
	lda xbc, (xsp + 52)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
	lda xwa, (xsp + 28)
	call FileIO_ReadHeader
	lda xbc, (xsp + 42)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
	lda xwa, (xsp + 14)
	call FileIO_ReadHeader
	lda xwa, (xsp + 28)
	lda xbc, (xsp + 14)
	call FileIO_CopyAndOpen
	ldw_erp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, ReadDualEx_StoreResult

ReadDualEx_ThirdLoopNext:
	inc 1, iz
	cp iz, 0xa
	jr lt, ReadDualEx_ThirdLoop

ReadDualEx_StoreResult:
	stw_erp HL, 0xfa

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
	lds32 xwa, 0
	ld (xsp + 8), xwa
	lds iz, 0

WriteVerify_WriteLoop:
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri A, 0x07, 0xe0, 0xf8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, WriteVerify_WriteLoopNext
	ld wa, (xsp + 4)
	lda_24 xbc, (Presentation_TagStrTable_0xF2)
	ldb_sri C, 0x07, 0xe4, 0xf8
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
	lds iz, 0

WriteVerify_ReadbackLoop:
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri C, 0x07, 0xe0, 0xf8
	ld wa, (xsp + 60)
	call FileIO_CheckRecordByFile
	cps l, 0
	jr z, WriteVerify_ReadbackNext
	lda xbc, (xsp + 50)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
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
	lds iz, 0

WriteVerify_CrossVerifyLoop:
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri A, 0x07, 0xe0, 0xf8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, WriteVerify_CrossVerifyNext
	lda xbc, (xsp + 50)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
	lda xwa, (xsp + 26)
	call FileIO_ReadHeader
	lda xbc, (xsp + 40)
	lda_24 xwa, (Presentation_TagStrTable_0xF2)
	ldb_sri E, 0x07, 0xe0, 0xf8
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
	cps hl, 0
	jr ge, GetFirstRecord_GotPage
	ldw hl, 0xff98
	ret

GetFirstRecord_GotPage:
	ld wa, hl
	call GetRecordPtrForFile
	ld xwa, xhl
	jp FileIO_OpenDefault

SearchAndOpen:
	stb_dri L, 0xfd, 0xf2, 0xfe
	pushw iz
	stl_dri XWA, 0xfd, 0x0c, 0x01
	call GetFirstPageBase
	ld iz, hl
	cps iz, 0
	jr ge, SearchOpen_DoSearch
	ldw hl, 0xff98
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
	ldw hl, 0xfff6

SearchOpen_Return:
	popw iz
	stb_dri L, 0xfd, 0x0e, 0x01
	ret

LoadFromSecondaryPage:
	pushw iz
	call FileIO_GetCurrentWallpaperIndex
	cps hl, 0
	jr ge, LoadSecondary_OpenFile
	ldw hl, 0xff98
	jr LoadSecondary_Return

LoadSecondary_OpenFile:
	ld wa, hl
	call FileIO_GetWallpaperEntry
	ld xwa, xhl
	ld xbc, Resource_RegionPad_0x18
	call FileIO_OpenWithMode
	cps hl, 0
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
	.incbin "includes/generated/v7_transplant_FileIO_ReturnError.bin"
FileIO_OpenWithMode:
	.incbin "includes/generated/v7_transplant_FileIO_OpenWithMode.bin"
FileIO_OpenMode_CheckWrite:
	.incbin "includes/generated/v7_transplant_FileIO_OpenMode_CheckWrite.bin"
FileIO_OpenMode_WriteMaxFiles:
	.incbin "includes/generated/v7_transplant_FileIO_OpenMode_WriteMaxFiles.bin"
FileIO_OpenMode_UnknownMode:
	.incbin "includes/generated/v7_transplant_FileIO_OpenMode_UnknownMode.bin"
FileIO_OpenMode_Success:
	.incbin "includes/generated/v7_transplant_FileIO_OpenMode_Success.bin"
FileIO_OpenMode_Return:
	pop xiz
	stb_dri L, 0xfd, 0x80, 0x00
	ret

FileIO_CloseHandle:
	.incbin "includes/generated/v7_transplant_FileIO_CloseHandle.bin"
FileIO_CloseHandle_Done:
	lds hl, 0
	ret

FileIO_OpenDefault:
	lda xsp, (xsp - 16)
	ld xde, xwa
	ld xiy, Resource_RegionPad_0x9C
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
	ld xiy, Resource_RegionPad_0xAC
	lda xix, (xsp + 20)
	ldw bc, 0x8
	ldirw
	ld xiy, Resource_RegionPad_0xBC
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
	cpw_da (0x1e53c), 31
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
	.incbin "includes/generated/v7_transplant_FileIO_ReadByte.bin"
FileIO_ReadByte_NoHandle:
	ldw hl, 0xff9c
	jr FileIO_ReadByte_Return

FileIO_ReadByte_CheckEOF:
	cps hl, 0
	ret ge

FileIO_ReadByte_Return:
	.incbin "includes/generated/v7_transplant_FileIO_ReadByte_Return.bin"
FileIO_ReadByte_Extended:
	.incbin "includes/generated/v7_transplant_FileIO_ReadByte_Extended.bin"
FileIO_ReadByte_BufferHit:
	.incbin "includes/generated/v7_transplant_FileIO_ReadByte_BufferHit.bin"
FileIO_SeekAndRead_NoHandle:
	ldw iz, 0xfffd
	jr FileIO_SeekAndRead_Return

FileIO_SeekAndRead_Error:
	ldw iz, 0xff9c

FileIO_SeekAndRead_Return:
	.incbin "includes/generated/v7_transplant_FileIO_SeekAndRead_Return.bin"
FileIO_SeekToOffset:
	.incbin "includes/generated/v7_transplant_FileIO_SeekToOffset.bin"
FileIO_ReadBlock:
	.incbin "includes/generated/v7_transplant_FileIO_ReadBlock.bin"
FileIO_ReadBlock_Loop:
	ld xiz, 0x7fff
	ld xwa, (xsp + 14)
	cp xwa, 0x7fff
	jr ge, FileIO_ReadBlock_Done
	ld xiz, (xsp + 14)

FileIO_ReadBlock_Done:
	.incbin "includes/generated/v7_transplant_FileIO_ReadBlock_Done.bin"
FileIO_WriteBlock_NoHandle:
	.incbin "includes/generated/v7_transplant_FileIO_WriteBlock_NoHandle.bin"
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
	.incbin "includes/generated/v7_transplant_FileIO_WriteBlock_Return.bin"
FileIO_WriteWord:
	.incbin "includes/generated/v7_transplant_FileIO_WriteWord.bin"
FileIO_WriteByte:
	ld xhl, (xsp + 6)
	pop xiz
	lda xsp, (xsp + 18)
	ret

FileIO_WriteByte_Impl:
	.incbin "includes/generated/v7_transplant_FileIO_WriteByte_Impl.bin"
FileIO_WriteByte_NoHandle:
	ld xiz, 0x7fff
	ld xwa, (xsp + 10)
	cp xwa, 0x7fff
	jr ge, FileIO_WriteByte_Return
	ld xiz, (xsp + 10)

FileIO_WriteByte_Return:
	.incbin "includes/generated/v7_transplant_FileIO_WriteByte_Return.bin"
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
	.incbin "includes/generated/v7_transplant_FileIO_GetPosition.bin"
FileIO_GetPosition_Return:
	.incbin "includes/generated/v7_transplant_FileIO_GetPosition_Return.bin"
FileIO_CheckHandle:
	ld xhl, (xsp + 14)
	pop xiz
	lda xsp, (xsp + 18)
	ret

FileIO_SeekAndReadBlock:
	.incbin "includes/generated/v7_transplant_FileIO_SeekAndReadBlock.bin"
FileIO_SeekRead_NoHandle:
	ldw hl, 0xff9c

FileIO_SeekRead_Return:
	.incbin "includes/generated/v7_transplant_FileIO_SeekRead_Return.bin"
FileIO_SeekRead_Extended:
	.incbin "includes/generated/v7_transplant_FileIO_SeekRead_Extended.bin"
FileIO_SeekRead_ExtReturn:
	.incbin "includes/generated/v7_transplant_FileIO_SeekRead_ExtReturn.bin"
FileIO_SeekWrite_NoHandle:
	ldw iz, 0xff9c

FileIO_SeekWrite_Return:
	.incbin "includes/generated/v7_transplant_FileIO_SeekWrite_Return.bin"
FileIO_SeekWriteBlock:
	.incbin "includes/generated/v7_transplant_FileIO_SeekWriteBlock.bin"
FileIO_SeekWriteBlock_Impl:
	.incbin "includes/generated/v7_transplant_FileIO_SeekWriteBlock_Impl.bin"
FileIO_SeekWriteBlock_NoHandle:
	ld xhl, 0xffffff9c
	jr FileIO_SeekWriteBlock_Return

FileIO_SeekWriteBlock_Error:
	cp xhl, 0x0
	ret ge

FileIO_SeekWriteBlock_Return:
	.incbin "includes/generated/v7_transplant_FileIO_SeekWriteBlock_Return.bin"
FileIO_SeekWriteBlock_Done:
	.incbin "includes/generated/v7_transplant_FileIO_SeekWriteBlock_Done.bin"
FileIO_CompareFiles:
	lda xsp, (xsp - 50)
	pushw iz
	ld (xsp + 48), xbc
	ld xde, xwa
	ldw (xsp + 10), 0x0
	ld xiy, Resource_RegionPad_0xCC
	lda xix, (xsp + 32)
	ldw bc, 0x8
	ldirw
	ld xiy, Resource_RegionPad_0xDC
	lda xix, (xsp + 16)
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp + 16)
	ld xbc, xde
	call FileIO_BuildFilePath
	pushw 0xea
	pushw 0x338
	lda xwa, (xsp + 20)
	push xwa
	call FileOpen
	inc 8, xsp
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr nz, FileIO_Compare_Return
	cpw_da (0x1e53c), 31
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
	pushw 0xea
	pushw 0x33c
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
	lda_24 xwa, (0x069800)
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
	.incbin "includes/generated/v7_transplant_FileIO_ParseHeader_Return.bin"
FileIO_ValidateRecord:
	ldw (xsp + 10), 0xfffd
	jr FileIO_ParseHeader_Done

FileIO_ValidateRecord_CheckSize:
	extz wa
	call format_FD
	cps hl, 0
	jr z, FileIO_ValidateRecord_Fail
	lds hl, 0
	ret

FileIO_ValidateRecord_Fail:
	cpw_da (0x1e53c), 31
	jr nz, FileIO_ValidateRecord_Ok
	ldw hl, 0xfff5
	ret

FileIO_ValidateRecord_Ok:
	ldw hl, 0xfffa
	ret

FileIO_ValidateRecord_Return:
	stiw_da (0x0272cc), 0x003f
	stiw_da (0x0272ce), 0x003f
	stib_da (0x0272d0), 0x00
	ld xwa, 0x25eaa
	ld xbc, Filename_TemplateArea_0x2
	calr FileIO_CopyString
	ld xwa, 0x271f2
	ld xbc, Filename_TemplateArea_0xA	; pointer to "________.MID"
	jr FileIO_CopyString

FileIO_CopyString:
	ld xde, xbc
	cp (xde), 0x0
	jr z, FileIO_CopyString_Done

FileIO_CopyString_Loop:
	ldb_spi C, 0xe8
	lda_dpi XHL, 0xe0
	cp (xde), 0x0
	jr nz, FileIO_CopyString_Loop

FileIO_CopyString_Done:
	ld (xwa), 0x0
	ret

FileIO_CopyString_WriteNull:
	ld xhl, xbc
	jr FileIO_CopyString_CheckEnd

FileIO_CopyString_Advance:
	ldb_spi C, 0xec
	lda_dpi XHL, 0xe0
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
	stib_dsp 0xe0, 0x00
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
	ldb_spi C, 0xe8
	lda_dpi XHL, 0xe0
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
	cp c, 0xa
	jr nc, FileIO_FormatIndex_TwoDigit
	stib_dsp 0xe0, 0x30
	jr FileIO_FormatIndex_AddChar

FileIO_FormatIndex_TwoDigit:
	cp c, 0x14
	jr nc, FileIO_FormatIndex_AddOnes
	stib_dsp 0xe0, 0x31
	sub c, 0xa
	jr FileIO_FormatIndex_AddChar

FileIO_FormatIndex_AddOnes:
	stib_dsp 0xe0, 0x32
	sub c, 0x14

FileIO_FormatIndex_AddChar:
	add c, 0x30
	lda_dpi XHL, 0xe0
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
	ld xbc, Filename_TemplateArea_0x18
	calr FileIO_BuildFilePath
	ld a, (xsp + 4)
	extz wa
	sla wa, 2
	lda_24 xbc, (SeqFileType_CodeTable)
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	ld xwa, xiz
	calr FileIO_BuildFilePath
	pop xiz
	inc 2, xsp
	ret

FileIO_ReadHeader_ParseLoop:
	pushw iz
	cp de, 0x64
	jr c, FileIO_ReadHeader_Done
	stb_dpi D, 0xe0
	ld hl, de
	extz xhl
	div hl, 0x64
	add l, 0x30
	ld (xix), l
	sub de, 0x64
	stb_dpi D, 0xe0
	ld hl, de
	extz xhl
	div hl, 0xa
	add l, 0x30
	ld (xix), l
	extz xde
	div de, 0xa
	stw_erp DE, 0xea
	add e, 0x30
	ld (xwa), e
	jr FileIO_ReadHeader_Field1

FileIO_ReadHeader_Done:
	stb_dpi D, 0xe0
	ld hl, de
	extz xhl
	div hl, 0xa
	add l, 0x30
	ld (xix), l
	stb_dpi C, 0xe0
	extz xde
	div de, 0xa
	stw_erp DE, 0xea
	add e, 0x30
	ld (xhl), e
	ld (xwa), 0x3a

FileIO_ReadHeader_Field1:
	inc 1, xwa
	stib_dsp 0xe0, 0x20
	lds iy, 0
	lds iz, 0
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
	cp (xwa), 0x7e
	jr nz, FileIO_GetRecordType_Return
	ldb c, 0x5f
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
	lda_24 xhl, (0x025eaa)
	ret

FileIO_GetRecordByType_Lookup:
	ld xbc, xwa
	ld xwa, 0x25eaa
	lds de, 6
	calr FileIO_CopyString_WriteNull
	stib_da (0x025eb0), 0x00
	ret

FileIO_GetRecordPtrAlt:
	lda_24 xhl, (0x0271f2)
	ret

FileIO_WriteRecordName:
	ld xbc, xwa
	ld xwa, 0x271f2
	ldw de, 0xc
	calr FileIO_CopyString_WriteNull
	stib_da (0x0271fe), 0x00
	ret

FileIO_WriteRecordName_Loop:
	ldw_da xhl, (0x0272cc)
	ret

FileIO_WriteRecordName_Done:
	ldw_da xbc, (0x025ea8)
	cps bc, 0
	jr lt, FileIO_WriteRecordName_Pad
	cp bc, 0x14
	jr ge, FileIO_WriteRecordName_Pad
	cp a, 0xa
	jr c, FileIO_WriteRecordName_Return

FileIO_WriteRecordName_Pad:
	ldb l, 0x0
	ret

FileIO_WriteRecordName_Return:
	lds bc, 1
	and a, 0xf
	jr z, FileIO_FormatRecordName
	slla bc

FileIO_FormatRecordName:
	ldw_da xwa, (0x0272cc)
	and wa, bc
	cp wa, bc
	scc8 z, l
	ret

FileIO_FormatName_Loop:
	cp a, 0xa
	ret nc
	lds bc, 1
	and a, 0xf
	jr z, FileIO_FormatName_NoPrefix
	slla bc

FileIO_FormatName_NoPrefix:
	ordm16_24 (0x272cc), xbc
	ret

FileIO_FormatName_Copy:
	cp a, 0xa
	ret nc
	lds bc, 1
	and a, 0xf
	jr z, FileIO_FormatName_CopyLoop
	slla bc

FileIO_FormatName_CopyLoop:
	xor bc, 0xffff
	anddm16_24 (0x272cc), xbc
	ret

FileIO_FormatName_Done:
	ldw_da xhl, (0x0272ce)
	ret

FileIO_FormatName_Return:
	ldw_da xbc, (0x025ea8)
	cps bc, 0
	jr lt, FileIO_BuildRecordPath
	cp bc, 0x14
	jr ge, FileIO_BuildRecordPath
	cp a, 0xa
	jr c, FileIO_BuildRecordPath_Loop

FileIO_BuildRecordPath:
	ldb l, 0x0
	ret

FileIO_BuildRecordPath_Loop:
	lds bc, 1
	and a, 0xf
	jr z, FileIO_BuildRecordPath_AddExt
	slla bc

FileIO_BuildRecordPath_AddExt:
	ldw_da xwa, (0x0272ce)
	and wa, bc
	cp wa, bc
	scc8 z, l
	ret

FileIO_BuildRecordPath_Done:
	cp a, 0xa
	ret nc
	lds bc, 1
	and a, 0xf
	jr z, FileIO_BuildRecordPath_Error
	slla bc

FileIO_BuildRecordPath_Error:
	ordm16_24 (0x272ce), xbc
	ret

FileIO_BuildRecordPath_Return:
	cp a, 0xa
	ret nc
	lds bc, 1
	and a, 0xf
	jr z, FileIO_GetRecordAttr
	slla bc

FileIO_GetRecordAttr:
	xor bc, 0xffff
	anddm16_24 (0x272ce), xbc
	ret

FileIO_GetRecordAttr_Check:
	ldw_da xwa, (0x025ea8)
	cps wa, 0
	jr lt, FileIO_GetRecordAttr_Return
	cp wa, 0x14
	jr lt, FileIO_GetRecordAttr_Default

FileIO_GetRecordAttr_Return:
	ldb l, 0x0
	ret

FileIO_GetRecordAttr_Default:
	ldb_da l, (0x0272d0)
	ret

FileIO_SetModeFlag_Writing:
	stib_da (0x0272d0), 0x01
	ret

FileIO_SetModeFlag_Reading:
	stib_da (0x0272d0), 0x00
	ret

FileIO_CheckRecordValid:
	ldw_da xbc, (0x025ea8)
	cps bc, 0
	jr lt, CheckRecord_ReturnFalse
	cp bc, 0x14
	jr ge, CheckRecord_ReturnFalse
	cp a, 0xa
	jr c, CheckRecord_ValidRange

CheckRecord_ReturnFalse:
	ldb l, 0x0
	ret

CheckRecord_ValidRange:
	lds de, 1
	and a, 0xf
	jr z, CheckRecord_ShiftDone
	slla de

CheckRecord_ShiftDone:
	muls bc, 0xc
	ld wa, bc
	lda_24 xbc, (0x025db8)
	ldw_sri WA, 0x07, 0xe4, 0xe0
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
	ldb l, 0x0
	ret

CheckRecordByFile_Valid:
	lds hl, 1
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
	ldw_da xwa, (0x025ea8)
	cps wa, 0
	jr lt, CheckFS_ReturnZero
	cp wa, 0x14
	jr lt, CheckFS_ValidIndex

CheckFS_ReturnZero:
	lds hl, 0
	ret

CheckFS_ValidIndex:
	muls wa, 0xc
	lda_24 xbc, (0x025db8)
	ldw_sri HL, 0x07, 0xe4, 0xe0
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
	ld xwa, 0x25db8
	add xwa, xbc
	ld hl, (xwa)
	ret

FileIO_CheckFileExists:
	stb_dri L, 0xfd, 0xf6, 0xfe
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
	stb_dri L, 0xfd, 0x0a, 0x01
	ret

FileIO_InitRecordTable:
	ld xiy, SeqFileTypeCode_Lsw_0x4
	ld xix, 0x25d6c
	ldw bc, 0x26
	ldirw
	lda_24 xbc, (0x025db8)
	ld xwa, xbc
	stb_dri B, 0xe5, 0xf0, 0x00

InitRecordTable_CopyLoop:
	ld xiy, SeqFileTypeCode_Lsw_0x50
	ld xix, xwa
	lds bc, 6
	ldirw
	lda xwa, (xwa + 12)
	cp xwa, xde
	jr c, InitRecordTable_CopyLoop
	lda_24 xbc, (0x025eb2)
	ld xwa, xbc
	stb_dri B, 0xe5, 0x38, 0x13

InitRecordTable_ExtLoop:
	ld xiy, SeqFileTypeCode_Lsw_0x5C
	ld xix, xwa
	ldw bc, 0x29
	ldirw
	lda xwa, (xwa + 82)
	cp xwa, xde
	jr c, InitRecordTable_ExtLoop
	stiw_da (0x025ea8), 0x0000
	stiw_da (0x0271ea), 0x0000
	stiw_da (0x0271ec), 0x0000
	stiw_da (0x0271ee), 0x0000
	stiw_da (0x0271f0), 0x0000
	stiw_da (0x0272c8), 0x0000
	stiw_da (0x0272ca), 0x0000
	ret

GetDiskSizeInfo:
	ldb_da a, (SeqFileTypeCode_Lsw_0x4E)
	cpda8_24 a, (0x25db6)
	jr nz, GetDiskSize_Return
	call GetMediaType
	stb_da (0x025db6), l

GetDiskSize_Return:
	ldb_da l, (0x025db6)
	ret

GetEncodedFreeSpaceData:
	lda_24 xwa, (0x025d6c)
	ldl_da xbc, (SeqFileTypeCode_Lsw_0x4)
	cp xbc, (xwa)
	jr nz, GetEncoded_Return
	lda xbc, (xwa + 4)
	call GetDiskFreeSpace

GetEncoded_Return:
	ldl_da xhl, (0x025d6c)
	ret

FileIO_GetDiskFreeSpace:
	lda_24 xwa, (0x025d6c)
	lda xbc, (xwa + 4)
	call GetDiskFreeSpace
	ldl_da xhl, (0x025d6c)
	ret

FileIO_ResetCurrentRecord:
	ldl_da xwa, (SeqFileTypeCode_Lsw_0x4)
	stl_da (0x025d6c), xwa
	ret

FileIO_GetDiskRecordPtr:
	lda_24 xwa, (0x025d6c)
	lda xbc, (xwa + 4)
	ldl_da xde, (SeqFileTypeCode_Lsw_0x8)
	cp xde, (xbc)
	call_24 z, GetDiskFreeSpace
	ldl_da xhl, (0x025d70)
	ret

FileIO_SearchAndLoadFile:
	push xiz
	lda_24 xwa, (0x025d74)
	lda_24 xbc, (SeqFileTypeCode_Lsw_0xC)
	calr FileIO_SearchFile
	cps hl, 0
	jr nz, SearchLoad_Return
	call GetVolumeLabel
	ld xwa, xhl
	ld xiz, xwa
	or xwa, xwa
	jr z, SearchLoad_DefaultVolume
	lda_24 xbc, (SeqFileTypeCode_Lsw_0xC)
	calr FileIO_SearchFile
	cps hl, 0
	jr nz, SearchLoad_CopyPath

SearchLoad_DefaultVolume:
	ld xiz, Filename_TemplateArea_0x1A

SearchLoad_CopyPath:
	lda_24 xwa, (0x025d74)
	ld xbc, xiz
	calr FileIO_CopyString

SearchLoad_Return:
	lda_24 xhl, (0x025d74)
	pop xiz
	ret

ValidateFileSelectionIndex:
	ldb_da c, (0x025db6)
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
	ldw hl, 0xffff
	ret

ValidateSelection_Ok:
	lds hl, 0
	ret

GetCurrentFileIndex:
	ldw_da xwa, (0x025ea8)
	calr ValidateFileSelectionIndex
	cps hl, 0
	jr z, GetCurrentFile_ReturnIndex
	ldw hl, 0xff98
	ret

GetCurrentFile_ReturnIndex:
	ldw_da xhl, (0x025ea8)
	ret

NotifyUIOfSelectionChange:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileSelectionIndex
	cp hl, 0xffff
	jr nz, NotifyUI_StoreIndex
	ldw_da xhl, (0x025ea8)
	jr NotifyUI_Return

NotifyUI_StoreIndex:
	ld hl, iz
	stw_da (0x025ea8), xhl

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
	lda_24 xhl, (Filename_TemplateArea)
	jr GetFileEntryPtr_Return

GetFileEntryPtr_Compute:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	lda_24 xhl, (0x025dba)
	add xhl, xbc

GetFileEntryPtr_Return:
	popw iz
	ret

GetCurrentFileType:
	ldw_da xwa, (0x025ea8)
	calr ValidateFileSelectionIndex
	cps hl, 0
	jr z, GetCurrentFileType_Lookup
	ldb l, 0x0
	ret

GetCurrentFileType_Lookup:
	ldw_da xwa, (0x025ea8)
	muls wa, 0xc
	lda_24 xbc, (0x025dc2)
	ldb_sri L, 0x07, 0xe4, 0xe0
	ret

UpdateFileEntry:
	stb_dri L, 0xfd, 0xd4, 0xfe
	push xiz
	lda_dri XHL, 0xfd, 0x2e, 0x01
	ld iz, wa
	ld xiy, Filename_TemplateArea_0x26
	lda xix, (xsp + 20)
	ldw bc, 0x8
	ldirw
	ld xiy, Filename_TemplateArea_0x36
	lda xix, (xsp + 4)
	ldw bc, 0x8
	ldirw
	ld wa, iz
	calr ValidateFileSelectionIndex
	cps hl, 0
	jr nz, UpdateFileEntry_Error
	stb_erp A, 0xf8
	extz wa
	ldw_erp WA, 0xfa
	ld wa, iz
	calr GetFileEntryPtr
	ld xde, xhl
	lda xwa, (xsp + 20)
	stw_erp BC, 0xfa
	calr FileIO_FormatFileIndex
	lda xbc, (xsp + 20)
	ldb_sri0 E, (xsp + 0x012e)
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
	stb_dri L, 0xfd, 0x2c, 0x01
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
	stb_erp A, 0xfb
	extz wa
	sla wa, 2
	lda_24 xbc, (SeqFileType_CodeTable)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld bc, iz
	extz xbc
	add xbc, (xsp + 4)
	calr FileIO_SearchFile
	cps hl, 0
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
	lds bc, 1
	stb_erp A, 0xfb
	and a, 0xf
	jr z, ParseFileExt_SetFlag
	slla bc

ParseFileExt_SetFlag:
	or (xde), bc
	stb_erp L, 0xfb
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
	cps wa, 1
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
	lda_24 xwa, (0x025db8)
	stb_dri W, 0x07, 0xe0, 0xe4
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
	lda_24 xwa, (0x025dba)
	stb_dri W, 0x07, 0xe0, 0xe4
	ld xbc, (xsp + 10)
	inc 2, xbc
	lds de, 6
	calr FileIO_CopyString_WriteNull
	muls iz, 0xc
	lda_24 xwa, (0x025db8)
	stb_dri W, 0x07, 0xe0, 0xf8
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
	lda_24 xbc, (0x025dc2)
	muls iz, 0xc
	stb_dri A, 0x07, 0xe4, 0xf8
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
	stb_dri L, 0xfd, 0xee, 0xfe
	pushw iz
	lda_24 xbc, (0x025db8)
	ld xwa, xbc
	stb_dri B, 0xe5, 0xf0, 0x00

GetEncFileSize_CopyRecordLoop:
	ld xiy, SeqFileTypeCode_Lsw_0x50
	ld xix, xwa
	lds bc, 6
	ldirw
	lda xwa, (xwa + 12)
	cp xwa, xde
	jr c, GetEncFileSize_CopyRecordLoop
	lds iz, 0
	lda xbc, (xsp + 10)
	ld xwa, Filename_TemplateArea_0x46
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
	stb_dri L, 0xfd, 0x12, 0x01
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
	ld xiy, 0x00ea03dc			; destination descriptor
	lds	bc, 6
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
	ld xbc, 0x00ea0492			; descriptor
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
	lda_24 xwa, (0x025dba); field at offset +2
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
	lda_24 xwa, (0x025dc0); flag at offset +8
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
	ld xwa, 0x00025db8			; record base
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
	lda_24 xwa, (0x025dba)
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
	lda_24 xwa, (0x025dc0)
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
	lda	xsp, (xsp+288)
	ret


ValidateFileRange:
	ldb_da c, (0x025db6)
	cps c, 2
	jr z, ValidateFileRange_CheckLower
	cps c, 3
	jr z, ValidateFileRange_CheckLower
	cps c, 4
	jr nz, ValidateFileRange_Invalid

ValidateFileRange_CheckLower:
	cps wa, 0
	jr lt, ValidateFileRange_Invalid
	cpda16_24 xwa, (0x271ec)
	jr le, ValidateFileRange_InRange

ValidateFileRange_Invalid:
	ldw hl, 0xffff
	ret

ValidateFileRange_InRange:
	ldw_da xbc, (0x0271ee)
	cp wa, bc
	jr lt, ValidateFileRange_FirstPage
	cpda16_24 xwa, (0x271f0)
	jr le, ValidateFileRange_SecondPage

ValidateFileRange_FirstPage:
	lds hl, 1
	ret

ValidateFileRange_SecondPage:
	sub wa, bc
	muls wa, 0x52
	lda_24 xbc, (0x025eb2)
	cpib_sri 0x07, 0xe4, 0xe0, 0x00
	jr nz, ValidateFileRange_Found
	lds hl, 2
	ret

ValidateFileRange_Found:
	lds hl, 0
	ret

GetFirstPageBase:
	ldw_da xwa, (0x0271ea)
	calr ValidateFileRange
	cps hl, 0
	jr z, GetFirstPageBase_Valid
	ldw hl, 0xff98
	ret

GetFirstPageBase_Valid:
	ldw_da xhl, (0x0271ea)
	ret

BuildSecondPageRecords:
	stb_dri L, 0xfd, 0xee, 0xfe
	pushw iz
	lda_24 xbc, (0x025eb2)
	ld xwa, xbc
	stb_dri B, 0xe5, 0x38, 0x13

BuildSecondPage_CopyRecordLoop:
	ld xiy, SeqFileTypeCode_Lsw_0x5C
	ld xix, xwa
	ldw bc, 0x29
	ldirw
	lda xwa, (xwa + 82)
	cp xwa, xde
	jr c, BuildSecondPage_CopyRecordLoop
	lds iz, 0
	lda xbc, (xsp + 10)
	ld xwa, Filename_TemplateArea_0x4E
	call _findfirst
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr lt, BuildSecondPage_Return
	lda xwa, (xsp + 16)
	ld (xsp + 6), xwa
	ldw_da xwa, (0x0271ee)
	cps wa, 0
	jr gt, BuildSecondPage_IterStart
	cpw_da (0x271f0), 0
	jr lt, BuildSecondPage_IterStart
	neg wa
	muls wa, 0x52
	lda_24 xbc, (0x025eb2)
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
	ldw_da xwa, (0x0271ee)
	cp iz, wa
	jr lt, BuildSecondPage_IterNext
	cpda16_24 xiz, (0x271f0)
	jr gt, BuildSecondPage_IterNext
	ld bc, iz
	sub bc, wa
	muls bc, 0x52
	ld wa, bc
	lda_24 xbc, (0x025eb2)
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
	stb_dri L, 0xfd, 0x12, 0x01
	ret

NavigateToFileIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRange
	cp hl, 0xffff
	jr nz, NavToFileIdx_InSecondPage
	ldw_da xhl, (0x0271ea)
	jr NavToFileIdx_Return

NavToFileIdx_InSecondPage:
	cps hl, 1
	jr nz, NavToFileIdx_StoreIndex
	ld wa, iz
	extz xwa
	div wa, 0x3c
	mul wa, 0x3c
	ld bc, wa
	stw_da (0x0271ee), xbc
	add bc, 0x3b
	ldw_da xwa, (0x0271ec)
	cp bc, wa
	jr ge, NavToFileIdx_ClampEnd
	ld wa, bc

NavToFileIdx_ClampEnd:
	stw_da (0x0271f0), xwa
	calr BuildSecondPageRecords

NavToFileIdx_StoreIndex:
	ld hl, iz
	stw_da (0x0271ea), xhl

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
	lda_24 xhl, (Filename_TemplateArea)
	jr GetRecordPtr_Return

GetRecordPtr_InRange:
	.incbin "includes/generated/v7_transplant_GetRecordPtr_InRange.bin"
GetRecordPtr_Return:
	popw iz
	ret

ValidateAndSearchFile:
	; --- Configuration/validation function (84 bytes) ---
	lda	xsp, (xsp-282)
	pushw iz
	ld iz, wa
	ld xiy, 0x00ea049c
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
	stiw_da (0x0271ee), 0x0000
	stiw_da (0x0271f0), 0x003b
	calr BuildSecondPageRecords
	lds wa, 0
	cps hl, 0
	jr le, GetFileCount_StoreAndClamp
	ld wa, hl
	dec 1, wa

GetFileCount_StoreAndClamp:
	stw_da (0x0271ec), xwa
	cpdm16_24 (0x271f0), xwa
	ret le
	stw_da (0x0271f0), xwa
	ret

ReadVariableLengthInt:
	push xiz
	lds32 xiz, 0
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
	cps hl, 0
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
	lda_dri XSP, 0x07, 0xe0, 0xf8
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
	stb_dri W, 0x07, 0xe0, 0xf8
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
	stib_ind 0x07, 0xe0, 0xf8, 0x00
	jr ReadField_TrimLoop

ReadField_TrimSpace:
	ld (xwa), 0x0

ReadField_TrimLoop:
	dec 1, iz
	ld xwa, (xsp + 4)
	stb_dri W, 0x07, 0xe0, 0xf8
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
	stib_da (0x025b90), 0x00
	ldiw_erp 0xfa, 0
	calr ReadVariableLengthInt
	cps hl, 0
	jrl nz, ParseSMF_ReturnNamePtr

ParseSMF_ReadEvent:
	call FileIO_ReadByte
	cp hl, 0xff
	jr nz, ParseSMF_CheckSysex
	call FileIO_ReadByte
	ldw_erp HL, 0xfa
	calr ReadVariableLengthInt
	ld iz, hl
	cpiw_erp 0xfa, 3
	jr nz, ParseSMF_ResetRunning
	ld wa, iz
	ld xbc, 0x25b90
	calr ReadFieldToBuffer
	lds iz, 0
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
	cp hl, 0xc0
	jr lt, ParseSMF_Check3ByteMsg
	cp hl, 0xdf
	jr gt, ParseSMF_Check3ByteMsg
	lds iz, 2
	jr ParseSMF_SetRunningStatus

ParseSMF_Check3ByteMsg:
	cp hl, 0x80
	jr lt, ParseSMF_CheckDataByte
	cp hl, 0xef
	jr gt, ParseSMF_CheckDataByte
	lds iz, 3

ParseSMF_SetRunningStatus:
	ldw_erp HL, 0xfa
	jr ParseSMF_SkipDataBytes

ParseSMF_CheckDataByte:
	cp hl, 0x7f
	jr gt, ParseSMF_SkipDataBytes
	cp_erpw 0xfa, 0xc0, 0x00
	jr lt, ParseSMF_RunningStatus3Byte
	cp_erpw 0xfa, 0xdf, 0x00
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
	lda_24 xhl, (0x025b90)

ParseSMF_Return:
	pop xiz
	ret

ProcessFileRecord:
	.incbin "includes/generated/v7_transplant_ProcessFileRecord.bin"
ProcessRecord_MatchLoop1:
	.incbin "includes/generated/v7_transplant_ProcessRecord_MatchLoop1.bin"
ProcessRecord_Match1Next:
	inc 1, iz
	cps iz, 4
	jr c, ProcessRecord_MatchLoop1

ProcessRecord_CheckBit5:
	.incbin "includes/generated/v7_transplant_ProcessRecord_CheckBit5.bin"
ProcessRecord_MatchLoop2:
	.incbin "includes/generated/v7_transplant_ProcessRecord_MatchLoop2.bin"
ProcessRecord_Match2Next:
	.incbin "includes/generated/v7_transplant_ProcessRecord_Match2Next.bin"
ProcessRecord_ReadTimeSig:
	.incbin "includes/generated/v7_transplant_ProcessRecord_ReadTimeSig.bin"
ProcessRecord_ReadAfterTimeSig:
	lds32 xwa, 4
	lds bc, 1
	call FileIO_SeekAndReadBlock
	lds iz, 0

ProcessRecord_MatchLoop3:
	.incbin "includes/generated/v7_transplant_ProcessRecord_MatchLoop3.bin"
ProcessRecord_CheckTempo:
	.incbin "includes/generated/v7_transplant_ProcessRecord_CheckTempo.bin"
ProcessRecord_DefaultSetBit:
	.incbin "includes/generated/v7_transplant_ProcessRecord_DefaultSetBit.bin"
ProcessRecord_CopyPath:
	calr FileIO_CopyString
	call FileIO_CloseHandle

ProcessRecord_ErrorReturn:
	ldw hl, 0xffff
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
	.incbin "includes/generated/v7_transplant_ProcessRecord_NoTrackName.bin"
ProcessRecord_SearchTrackName:
	.incbin "includes/generated/v7_transplant_ProcessRecord_SearchTrackName.bin"
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
	lda_24 xhl, (Filename_TemplateArea)
	jr GetEntry_Return

GetEntry_ComputeOffset:
	.incbin "includes/generated/v7_transplant_GetEntry_ComputeOffset.bin"
FileEntry_ComputeOffset:
	.incbin "includes/generated/v7_transplant_FileEntry_ComputeOffset.bin"
GetEntry_Return:
	popw iz
	ret

FileIO_ByteBlock_DemoProc2:
	.incbin "includes/generated/v7_transplant_FileIO_ByteBlock_DemoProc2.bin"
ValidateFileRangeType5:
	cpib_da (0x025db6), 0x05
	jr nz, ValidateRange_OutOfRange
	cps wa, 0
	jr lt, ValidateRange_OutOfRange
	cpda16_24 xwa, (0x271ec)
	jr le, ValidateRange_CheckPage

ValidateRange_OutOfRange:
	ldw hl, 0xffff
	ret

ValidateRange_CheckPage:
	ldw_da xbc, (0x0271ee)
	cp wa, bc
	jr lt, ValidateRange_NeedPageChange
	cpda16_24 xwa, (0x271f0)
	jr le, ValidateRange_CheckEmpty

ValidateRange_NeedPageChange:
	lds hl, 1
	ret

ValidateRange_CheckEmpty:
	sub wa, bc
	muls wa, 0x52
	lda_24 xbc, (0x025ec0)
	cpib_sri 0x07, 0xe4, 0xe0, 0x00
	jr nz, ValidateRange_IsValid
	lds hl, 2
	ret

ValidateRange_IsValid:
	lds hl, 0
	ret

GetCurrentFileIndexAlt:
	ldw_da xwa, (0x0271ea)
	calr ValidateFileRangeType5
	cps hl, 0
	jr z, GetCurrentIndex_Return
	ldw hl, 0xff98
	ret

GetCurrentIndex_Return:
	ldw_da xhl, (0x0271ea)
	ret

BuildPageRecords:
	stb_dri L, 0xfd, 0xee, 0xfe
	pushw iz
	lda_24 xbc, (0x025eb2)
	ld xwa, xbc
	stb_dri B, 0xe5, 0x38, 0x13

BuildRecords_CopyLoop:
	ld xiy, SeqFileTypeCode_Lsw_0x5C
	ld xix, xwa
	ldw bc, 0x29
	ldirw
	lda xwa, (xwa + 82)
	cp xwa, xde
	jr c, BuildRecords_CopyLoop
	lds iz, 0
	lda xbc, (xsp + 10)
	ld xwa, FileOp_StubAndDirNames_0x1C
	call _findfirst
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr lt, BuildRecords_Return
	lda xwa, (xsp + 16)
	ld (xsp + 6), xwa
	ldw_da xwa, (0x0271ee)
	cps wa, 0
	jr gt, BuildRecords_SearchDone
	cpw_da (0x271f0), 0
	jr lt, BuildRecords_SearchDone
	neg wa
	muls wa, 0x52
	lda_24 xbc, (0x025ec0)
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
	ldw_da xwa, (0x0271ee)
	cp iz, wa
	jr lt, BuildRecords_UpdateNext
	cpda16_24 xiz, (0x271f0)
	jr gt, BuildRecords_UpdateNext
	ld bc, iz
	sub bc, wa
	muls bc, 0x52
	ld wa, bc
	lda_24 xbc, (0x025ec0)
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
	stb_dri L, 0xfd, 0x12, 0x01
	ret

SetCurrentFileIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRangeType5
	cp hl, 0xffff
	jr nz, SetIndex_InvalidWrap
	ldw_da xhl, (0x0271ea)
	jr SetIndex_Return

SetIndex_InvalidWrap:
	cps hl, 1
	jr nz, SetIndex_StoreIndex
	ld wa, iz
	extz xwa
	div wa, 0x3c
	mul wa, 0x3c
	ld bc, wa
	stw_da (0x0271ee), xbc
	add bc, 0x3b
	ldw_da xwa, (0x0271ec)
	cp bc, wa
	jr ge, SetIndex_UpdatePageEnd
	ld wa, bc

SetIndex_UpdatePageEnd:
	stw_da (0x0271f0), xwa
	calr BuildPageRecords

SetIndex_StoreIndex:
	ld hl, iz
	stw_da (0x0271ea), xhl

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
	lda_24 xhl, (Filename_TemplateArea)
	jr GetRecordPtrAlt_Return

GetRecordPtr_ComputeOffset:
	.incbin "includes/generated/v7_transplant_GetRecordPtr_ComputeOffset.bin"
GetRecordPtrAlt_Return:
	popw iz
	ret

BuildPageRecordsAlt:
	stiw_da (0x0271ee), 0x0000
	stiw_da (0x0271f0), 0x003b
	calr BuildPageRecords
	lds wa, 0
	cps hl, 0
	jr le, BuildRecordsAlt_StoreCount
	ld wa, hl
	dec 1, wa

BuildRecordsAlt_StoreCount:
	stw_da (0x0271ec), xwa
	cpdm16_24 (0x271f0), xwa
	ret le
	stw_da (0x0271f0), xwa
	ret

TrimAndFormatFilename:
	lda xsp, (xsp - 128)
	push xiz
	ld xiz, xbc
	stib_ind 0x07, 0xf8, 0xe0, 0x00
	lds ix, 0
	cps wa, 0
	jr le, TrimFormat_TrimTrailing

TrimFormat_ScanLoop:
	stb_dri C, 0x07, 0xf8, 0xf0
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
	stb_dri W, 0x07, 0xf8, 0xf0
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
	stb_dri A, 0x07, 0xe0, 0xf0
	cp (xbc), 0x20
	jr z, TrimFormat_SkipSpaces
	ld xwa, xiz
	calr FileIO_CopyString

TrimFormat_Done:
	lds hl, 0
	pop xiz
	stb_dri L, 0xfd, 0x80, 0x00
	ret

DetectFileType:
	ldb_da l, (0x025db6)
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
	ld xwa, FileOp_StubAndDirNames_0x22
	ld xbc, FileOp_StubAndDirNames_0x1E
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, DetectType_TryExtended
	stib_da (0x025db6), 0x06
	ld xwa, 0x10
	lds bc, 0
	call FileIO_SeekAndReadBlock
	lda_24 xwa, (0x025d74)
	ld xbc, 0x40
	call FileIO_ReadBlock
	ld xwa, 0x60
	lds bc, 0
	call FileIO_SeekAndReadBlock
	ld xwa, 0x27200
	ld xbc, 0x3c
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	lda_24 xbc, (0x025d74)
	ldw wa, 0x40
	lds de, 0

DetectType_TrimAndReturn:
	calr TrimAndFormatFilename
	ldb_da l, (0x025db6)
	extz hl
	ret

DetectType_TryExtended:
	ld xwa, FileOp_StubAndDirNames_0x30
	ld xbc, FileOp_StubAndDirNames_0x2C
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, DetectType_NotFound
	stib_da (0x025db6), 0x07
	ld xwa, 0x12d8
	lds bc, 0
	call FileIO_SeekAndReadBlock
	lda_24 xwa, (0x025d74)
	ld xbc, 0x38
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	lda_24 xbc, (0x025d74)
	ldw wa, 0x38
	lds de, 0
	jr DetectType_TrimAndReturn

DetectType_NotFound:
	ldw hl, 0xffff
	ret

ValidateFileRangeAlt:
	ldb_da c, (0x025db6)
	cps c, 6
	jr z, ValidateRangeAlt_CheckType
	cps c, 7
	jr nz, ValidateRangeAlt_OutOfRange

ValidateRangeAlt_CheckType:
	cps wa, 0
	jr lt, ValidateRangeAlt_OutOfRange
	cpda16_24 xwa, (0x271ec)
	jr le, ValidateRangeAlt_CheckPage

ValidateRangeAlt_OutOfRange:
	ldw hl, 0xffff
	ret

ValidateRangeAlt_CheckPage:
	ldw_da xbc, (0x0271ee)
	cp wa, bc
	jr lt, ValidateRangeAlt_NeedPageChange
	cpda16_24 xwa, (0x271f0)
	jr le, ValidateRangeAlt_CheckEmpty

ValidateRangeAlt_NeedPageChange:
	lds hl, 1
	ret

ValidateRangeAlt_CheckEmpty:
	sub wa, bc
	muls wa, 0x52
	lda_24 xbc, (0x025eb2)
	cpib_sri 0x07, 0xe4, 0xe0, 0x00
	jr nz, ValidateRangeAlt_IsValid
	lds hl, 2
	ret

ValidateRangeAlt_IsValid:
	lds hl, 0
	ret

FileIO_GetCurrentFileIndex_Alt:
	ldw_da xwa, (0x0271ea)
	calr ValidateFileRangeAlt
	cps hl, 0
	jr z, GetCurrentFileAlt_ReturnIndex
	ldw hl, 0xff98
	ret

GetCurrentFileAlt_ReturnIndex:
	ldw_da xhl, (0x0271ea)
	ret

FileIO_BuildFileExtName:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	lda xwa, (xsp + 4)
	stib_dsp 0xe0, 0x2e
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
	lda_24 xbc, (0x025eb2)
	ld xwa, xbc
	stb_dri B, 0xe5, 0x38, 0x13

InitDirScan_CopyLoop:
	ld xiy, SeqFileTypeCode_Lsw_0x5C
	ld xix, xwa
	ldw bc, 0x29
	ldirw
	lda xwa, (xwa + 82)
	cp xwa, xde
	jr c, InitDirScan_CopyLoop
	ldiw_erp 0xfa, 0
	cpib_da (0x025db6), 0x06
	jrl nz, DirScan_AltMediaPath
	ld xwa, FileOp_StubAndDirNames_0x42
	ld xbc, FileOp_StubAndDirNames_0x3E
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, DirScan_ReturnResult
	ld xwa, 0x51
	lds bc, 0
	call FileIO_SeekAndReadBlock
	call FileIO_ReadByte
	ldw_erp HL, 0xfa
	ldw_da xiz, (0x0271ee)
	cpda16_24 xiz, (0x271f0)
	jr gt, FileIO_DirScanDone

DirScan_ProcessEntry:
	lda_24 xwa, (0x027200)
	ldb_sri A, 0x07, 0xe0, 0xf8
	exts wa
	mul wa, 0x30
	add wa, 0xa0
	exts xwa
	lds bc, 0
	call FileIO_SeekAndReadBlock
	ld wa, iz
	subda16_24 xwa, (0x271ee)
	muls wa, 0x52
	lda_24 xbc, (0x025eb2)
	exts xwa
	add xwa, xbc
	ld xbc, 0xb
	call FileIO_ReadBlock
	ld wa, iz
	subda16_24 xwa, (0x271ee)
	muls wa, 0x52
	lda_24 xbc, (0x025eb2)
	exts xwa
	add xwa, xbc
	calr FileIO_BuildFileExtName
	inc 1, iz
	cpda16_24 xiz, (0x271f0)
	jr le, DirScan_ProcessEntry

FileIO_DirScanDone:
	call FileIO_CloseHandle

DirScan_ReturnResult:
	stw_erp HL, 0xfa
	pop xiz
	lda xsp, (xsp + 16)
	ret

DirScan_AltMediaPath:
	ld xwa, FileOp_StubAndDirNames_0x50
	ld xbc, FileOp_StubAndDirNames_0x4C
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, DirScan_ReturnResult
	ld xwa, 0x10
	lds bc, 0

DirScan_AltReadLoop:
	call FileIO_SeekAndReadBlock
	lda xwa, (xsp + 4)
	ld xbc, 0xb
	call FileIO_ReadBlock
	call FileIO_ReturnError
	cps hl, 0
	jr lt, FileIO_DirScanDone
	lda xbc, (xsp + 4)
	cp (xbc), 0x20
	jr lt, FileIO_DirScanDone
	ldw_da xde, (0x0271ee)
	stw_erp WA, 0xfa
	cp wa, de
	jr lt, DirScan_AltNextEntry
	stw_erp WA, 0xfa
	cpda16_24 xwa, (0x271f0)
	jr gt, DirScan_AltNextEntry
	stw_erp WA, 0xfa
	sub wa, de
	muls wa, 0x52
	lda_24 xde, (0x025eb2)
	exts xwa
	add xwa, xde
	ldw de, 0xb
	calr FileIO_CopyString_WriteNull
	stw_erp WA, 0xfa
	subda16_24 xwa, (0x271ee)
	muls wa, 0x52
	lda_24 xbc, (0x025eb2)
	exts xwa
	add xwa, xbc
	calr FileIO_BuildFileExtName

DirScan_AltNextEntry:
	inc1w_erp 0xfa
	ld xwa, 0x45
	lds bc, 1
	jr DirScan_AltReadLoop

FileIO_SelectFileByIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr ValidateFileRangeAlt
	cp hl, 0xffff
	jr nz, SelectFile_CheckPageBound
	ldw_da xhl, (0x0271ea)
	jr SelectFile_Return

SelectFile_CheckPageBound:
	cps hl, 1
	jr nz, SelectFile_StoreIndex
	ld wa, iz
	extz xwa
	div wa, 0x3c
	mul wa, 0x3c
	ld bc, wa
	stw_da (0x0271ee), xbc
	add bc, 0x3b
	ldw_da xwa, (0x0271ec)
	cp bc, wa
	jr ge, SelectFile_ClampEnd
	ld wa, bc

SelectFile_ClampEnd:
	stw_da (0x0271f0), xwa
	calr FileIO_InitDirScan

SelectFile_StoreIndex:
	ld hl, iz
	stw_da (0x0271ea), xhl

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
	lda_24 xhl, (Filename_TemplateArea)
	jr GetFileEntry_Return

GetFileEntry_ComputeOffset:
	.incbin "includes/generated/v7_transplant_GetFileEntry_ComputeOffset.bin"
GetFileEntry_Return:
	popw iz
	ret

FileIO_InitFileNavigation:
	stiw_da (0x0271ee), 0x0000
	stiw_da (0x0271f0), 0x003b
	calr FileIO_InitDirScan
	lds wa, 0
	cps hl, 0
	jr le, InitFileNav_ClampEnd
	ld wa, hl
	dec 1, wa

InitFileNav_ClampEnd:
	stw_da (0x0271ec), xwa
	cpdm16_24 (0x271f0), xwa
	ret le
	stw_da (0x0271f0), xwa
	ret

FileIO_RefreshFileNames:
	push xiz
	cpib_da (0x025db6), 0x06
	jrl nz, RefreshNames_AltMediaPath
	ld xwa, FileOp_StubAndDirNames_0x62
	ld xbc, FileOp_StubAndDirNames_0x5E
	call FileIO_OpenWithMode
	ldw_da xwa, (0x0271ee)
	ld iz, wa
	cps hl, 0
	jr ge, RefreshNames_CheckEnd
	cpda16_24 xwa, (0x271f0)
	jrl gt, FileIO_ScanComplete_Return

RefreshNames_FallbackLoop:
	ld wa, iz
	subda16_24 xwa, (0x271ee)
	muls wa, 0x52
	lda_24 xbc, (0x025eb2)
	stb_dri A, 0x07, 0xe4, 0xe0
	lda xwa, (xbc + 14)
	calr FileIO_CopyString
	inc 1, iz
	cpda16_24 xiz, (0x271f0)
	jr le, RefreshNames_FallbackLoop
	jrl FileIO_ScanComplete_Return

RefreshNames_CheckEnd:
	cpda16_24 xwa, (0x271f0)
	jrl gt, FileIO_ScanDone

RefreshNames_ReadLoop:
	lda_24 xwa, (0x027200)
	ldb_sri A, 0x07, 0xe0, 0xf8
	exts wa
	mul wa, 0x30
	add wa, 0xa0
	ldw_erp WA, 0xfa
	exts xwa
	lds bc, 0
	call FileIO_SeekAndReadBlock
	ld wa, iz
	subda16_24 xwa, (0x271ee)
	muls wa, 0x52
	ld bc, wa
	lda_24 xwa, (0x025ec0)
	stb_dri W, 0x07, 0xe0, 0xe4
	ld xbc, 0x30
	call FileIO_ReadBlock
	ld wa, iz
	subda16_24 xwa, (0x271ee)
	muls wa, 0x52
	ld bc, wa
	lda_24 xwa, (0x025ec0)
	exts xbc
	add xbc, xwa
	ldw wa, 0x30
	ldw de, 0x40
	calr TrimAndFormatFilename
	cps hl, 0
	jr ge, RefreshNames_NextEntry
	ld wa, iz
	subda16_24 xwa, (0x271ee)
	muls wa, 0x52
	lda_24 xbc, (0x025eb2)
	stb_dri A, 0x07, 0xe4, 0xe0
	lda xwa, (xbc + 14)
	calr FileIO_CopyString

RefreshNames_NextEntry:
	inc 1, iz
	cpda16_24 xiz, (0x271f0)
	jrl le, RefreshNames_ReadLoop
	jrl FileIO_ScanDone

RefreshNames_AltMediaPath:
	ld xwa, FileOp_StubAndDirNames_0x70
	ld xbc, FileOp_StubAndDirNames_0x6C
	call FileIO_OpenWithMode
	ldw_da xwa, (0x0271ee)
	cps hl, 0
	jr ge, RefreshNames_AltOpenSuccess
	ld iz, wa
	cpda16_24 xwa, (0x271f0)
	jrl gt, FileIO_ScanComplete_Return

RefreshNames_AltFallbackLoop:
	ld wa, iz
	subda16_24 xwa, (0x271ee)
	muls wa, 0x52
	lda_24 xbc, (0x025eb2)
	stb_dri A, 0x07, 0xe4, 0xe0
	lda xwa, (xbc + 14)
	calr FileIO_CopyString
	inc 1, iz
	cpda16_24 xiz, (0x271f0)
	jr le, RefreshNames_AltFallbackLoop
	jrl FileIO_ScanComplete_Return

RefreshNames_AltOpenSuccess:
	ldi_erpw 0xfa, 0x40, 0x00
	ld iz, wa
	cpda16_24 xwa, (0x271f0)
	jr gt, FileIO_ScanDone

RefreshNames_AltReadLoop:
	stw_erp WA, 0xfa
	exts xwa
	lds bc, 0
	call FileIO_SeekAndReadBlock
	ld wa, iz
	subda16_24 xwa, (0x271ee)
	muls wa, 0x52
	ld bc, wa
	lda_24 xwa, (0x025ec0)
	stb_dri W, 0x07, 0xe0, 0xe4
	ld xbc, 0x10
	call FileIO_ReadBlock
	ld wa, iz
	subda16_24 xwa, (0x271ee)
	muls wa, 0x52
	ld bc, wa
	lda_24 xwa, (0x025ec0)
	exts xbc
	add xbc, xwa
	ldw wa, 0x10
	lds de, 0
	calr TrimAndFormatFilename
	cps hl, 0
	jr ge, RefreshNames_AltNextEntry
	ld wa, iz
	subda16_24 xwa, (0x271ee)
	muls wa, 0x52
	lda_24 xbc, (0x025eb2)
	stb_dri A, 0x07, 0xe4, 0xe0
	lda xwa, (xbc + 14)
	calr FileIO_CopyString

RefreshNames_AltNextEntry:
	add_erpw 0xfa, 0x50, 0x00
	inc 1, iz
	cpda16_24 xiz, (0x271f0)
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
	lda_24 xhl, (Filename_TemplateArea)
	jr GetEntryRefresh_Return

GetEntryRefresh_ComputeOffset:
	.incbin "includes/generated/v7_transplant_GetEntryRefresh_ComputeOffset.bin"
GetEntryRefresh_Return:
	popw iz
	ret

FileIO_CheckMediaIsWritable:
	call GetMediaType
	cps l, 2
	jr z, CheckMediaWritable_Ok
	cps l, 3
	jr z, CheckMediaWritable_Ok
	ldw hl, 0xffff
	ret

CheckMediaWritable_Ok:
	lds hl, 0
	ret

FileIO_OpenWithBuiltPath:
	stb_dri L, 0xfd, 0x70, 0xff
	push xiz
	stl_dri XBC, 0xfd, 0x90, 0x00
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
	ld_sril XBC, (xsp + 0x0090)
	call FileIO_OpenWithMode
	pop xiz
	stb_dri L, 0xfd, 0x90, 0x00
	ret

FileIO_BuildFileIndex:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	stib_da (0x027412), 0x00
	stib_da (0x027414), 0x00
	lds iz, 0

BuildIndex_ScanLoop:
	ld xwa, (xsp + 4)
	stb_dri W, 0x07, 0xe0, 0xf8
	ld xbc, FileOp_StubAndDirNames_0x7E
	lds de, 3
	calr FileIO_Search_SkipEntry
	cps hl, 0
	jr z, BuildIndex_Return
	ldiw_erp 0xfa, 0
	jr BuildIndex_CheckComma

BuildIndex_CheckSubEntry:
	ldb_da c, (0x027412)
	exts bc
	sla bc, 5
	addw_erp BC, 0xfa
	lda_24 xhl, (0x027312)
	lda_dri XIY, 0x07, 0xec, 0xe4
	ld xbc, FileOp_StubAndDirNames_0x82
	lds de, 3
	calr FileIO_Search_SkipEntry
	cps hl, 0
	jr z, FileIO_StoreIndexedEntry
	inc1w_erp 0xfa
	inc 1, iz

BuildIndex_CheckComma:
	ld xwa, (xsp + 4)
	stb_dri W, 0x07, 0xe0, 0xf8
	ld e, (xwa)
	cp e, 0x2c
	jr z, FileIO_StoreIndexedEntry
	cps e, 0
	jr z, FileIO_StoreIndexedEntry
	cp_erpw 0xfa, 0x20, 0x00
	jr lt, BuildIndex_CheckSubEntry

FileIO_StoreIndexedEntry:
	ldb_da a, (0x027412)
	exts wa
	sla wa, 5
	addw_erp WA, 0xfa
	lda_24 xbc, (0x027312)
	stib_ind 0x07, 0xe4, 0xe0, 0x00
	incdi8_24 1, (0x27412)
	inc 1, iz
	cp iz, 0x80
	jrl lt, BuildIndex_ScanLoop

BuildIndex_Return:
	pop xiz
	inc 4, xsp
	ret

FileIO_FindPathSeparator:
	ld xde, xwa
	lds hl, 0
	lda_24 xbc, (0x0272d2)
	jr FindPathSep_CheckChar

FindPathSep_NextChar:
	lda_dpi XBC, 0xe4
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
	stl_da (0x027416), xwa
	stib_da (0x027414), 0x00
	cp (xiz), 0x2
	jr nz, CtrlCmd_Return
	ld e, (xiz + 1)
	lda_24 xbc, (0x0272f2)
	lda xwa, (xiz + 2)
	cp e, 0x80
	jr z, ControlState_ProcessNext
	cp e, 0x40
	jr z, ControlState_ProcessNext
	cp e, 0x10
	jr z, CtrlCmd_SetPathAndBuild
	cps e, 0
	jr nz, CtrlCmd_Return
	stib_da (0x0272d2), 0x00
	ld (xbc), 0x0
	jr ControlState_ProcessNext

CtrlCmd_SetPathAndBuild:
	ld (xbc), 0x0
	calr FileIO_FindPathSeparator
	inc 3, hl
	stb_dri W, 0x07, 0xf8, 0xec

ControlState_ProcessNext:
	calr FileIO_BuildFileIndex

CtrlCmd_Return:
	pop xiz
	ret

FileIO_FindFirstMatch:
	stb_dri L, 0xfd, 0xec, 0xfe
	push xiz
	stl_dri XBC, 0xfd, 0x10, 0x01
	stl_dri XWA, 0xfd, 0x14, 0x01
	ld_sril XWA, (xsp + 0x0114)
	ld (xwa), 0x0
	ld_sril XWA, (xsp + 0x0110)
	lds32 xbc, 0
	ld (xwa), xbc
	ldb_da a, (0x027414)
	exts wa
	ld (xsp + 4), wa
	ldb_da a, (0x027412)
	exts wa
	cp (xsp + 4), wa
	jrl ge, FindFirst_NotFound

FindFirst_BuildPathLoop:
	ld xwa, 0x25c6c
	ld xbc, FileOp_StubAndDirNames_0x86
	calr FileIO_CopyString
	ld xwa, 0x25c6c
	ld xbc, 0x272d2
	calr FileIO_BuildFilePath
	ld xwa, 0x25c6c
	ld xbc, 0x272f2
	calr FileIO_BuildFilePath
	ld wa, (xsp + 4)
	sla wa, 5
	lda_24 xbc, (0x027312)
	stb_dri A, 0x07, 0xe4, 0xe0
	ld xwa, 0x25c6c
	calr FileIO_BuildFilePath
	lda xbc, (xsp + 6)
	ld xwa, 0x25c6c
	call _findfirst
	ld xiz, xhl
	cp xiz, 0x0
	jr lt, FindFirst_NextIndex
	lda xbc, (xsp + 12)
	ld_sril XWA, (xsp + 0x0114)
	calr FileIO_CopyString
	lda xbc, (xsp + 6)
	bitm 4, (xbc)
	jr z, FindFirst_StoreFileSize
	ld_sril XWA, (xsp + 0x0110)
	ld xbc, 0xffffffff
	ld (xwa), xbc
	jr FindFirst_StoreResult

FindFirst_StoreFileSize:
	ld_sril XWA, (xsp + 0x0110)
	ld xbc, (xbc + 2)
	ld (xwa), xbc

FindFirst_StoreResult:
	stl_da (0x027416), xiz
	ld wa, (xsp + 4)
	stb_da (0x027414), a
	lds hl, 0
	jr FindFirst_Return

FindFirst_NextIndex:
	incm 1, (xsp + 4)
	ldb_da a, (0x027412)
	exts wa
	cp (xsp + 4), wa
	jrl lt, FindFirst_BuildPathLoop

FindFirst_NotFound:
	ld xwa, 0xffffffff
	stl_da (0x027416), xwa
	ldw hl, 0xffff

FindFirst_Return:
	pop xiz
	stb_dri L, 0xfd, 0x14, 0x01
	ret

FileIO_FindNextMatch:
	stb_dri L, 0xfd, 0xf2, 0xfe
	push xiz
	stl_dri XBC, 0xfd, 0x0e, 0x01
	ld xiz, xwa
	ldl_da xwa, (0x027416)
	lda xbc, (xsp + 4)
	call _findnext
	cps hl, 0
	jr z, FindNext_CopyName
	ld (xiz), 0x0
	ld_sril XWA, (xsp + 0x010e)
	lds32 xbc, 0
	ld (xwa), xbc
	ldl_da xwa, (0x027416)
	call _findclose
	ld xwa, 0xffffffff
	stl_da (0x027416), xwa
	ldw hl, 0xffff
	jr FindNext_Return

FindNext_CopyName:
	lda xbc, (xsp + 10)
	ld xwa, xiz
	calr FileIO_CopyString
	lda xbc, (xsp + 4)
	bitm 4, (xbc)
	jr z, FindNext_StoreFileSize
	ld_sril XWA, (xsp + 0x010e)
	ld xbc, 0xffffffff
	ld (xwa), xbc
	jr FindNext_Ok

FindNext_StoreFileSize:
	ld_sril XWA, (xsp + 0x010e)
	ld xbc, (xbc + 2)
	ld (xwa), xbc

FindNext_Ok:
	lds hl, 0

FindNext_Return:
	pop xiz
	stb_dri L, 0xfd, 0x0e, 0x01
	ret

FileIO_SearchStringMatch:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	ldw hl, 0xffff
	ldl_da xwa, (0x027416)
	cp xwa, 0x0
	jr ge, SearchMatch_HasHandle
	ld xwa, xiz
	ld xbc, (xsp + 4)
	jr SearchMatch_FirstSearch

SearchMatch_HasHandle:
	ldb_da a, (0x027414)
	cpda8_24 a, (0x27412)
	jr ge, SearchMatch_Return
	ld xwa, xiz
	ld xbc, (xsp + 4)
	calr FileIO_FindNextMatch
	cps hl, 0
	jr ge, SearchMatch_Return
	incdi8_24 1, (0x27414)
	ld xwa, xiz
	ld xbc, (xsp + 4)

SearchMatch_FirstSearch:
	calr FileIO_FindFirstMatch

SearchMatch_Return:
	pop xiz
	inc 4, xsp
	ret

FileIO_ExtractBasename:
	lda_24 xhl, (0x025cec)
	ld (xhl), 0x0
	ldl_da xwa, (0x027416)
	cp xwa, 0x0
	ret lt
	ldb_da c, (0x027412)
	cps c, 0
	ret le
	ldb_da a, (0x027414)
	cp a, c
	ret ge
	exts wa
	sla wa, 5
	lda_24 xbc, (0x027312)
	stb_dri A, 0x07, 0xe4, 0xe0
	ldw de, 0xffff
	lds ix, 0
	cp (xbc), 0x0
	jr z, ExtractBase_TruncatePath

ExtractBase_ScanLoop:
	ldb_sri A, 0x07, 0xe4, 0xf0
	lda_dri XBC, 0x07, 0xec, 0xf0
	cp a, 0x5c
	jr nz, ExtractBase_TrackSep
	ld de, ix

ExtractBase_TrackSep:
	inc 1, ix
	cpib_sri 0x07, 0xe4, 0xf0, 0x00
	jr nz, ExtractBase_ScanLoop

ExtractBase_TruncatePath:
	cps de, 0
	jr le, ExtractBase_ClearAll
	inc 1, de
	stib_ind 0x07, 0xec, 0xe8, 0x00
	jr ExtractBase_Done

ExtractBase_ClearAll:
	ld (xhl), 0x0

ExtractBase_Done:
	ret

FileIO_NormalizePath:
	cp (xwa), 0x5c
	scc16 z, de
	stb_dri A, 0x07, 0xe0, 0xe8
	ld xwa, 0x272f2
	calr FileIO_CopyString
	lds de, 0
	lda_24 xbc, (0x0272f2)
	jr NormalizePath_CheckLoop

NormalizePath_NextChar:
	inc 1, de

NormalizePath_CheckLoop:
	stb_dri W, 0x07, 0xe4, 0xe8
	cp (xwa), 0x0
	jr nz, NormalizePath_NextChar
	cp de, 0x20
	ret ge
	cps de, 0
	ret le
	dec 1, de
	cpib_sri 0x07, 0xe4, 0xe8, 0x5c
	ret z
	ld (xwa), 0x5c
	ret

FileIO_ValidateModeAndRange:
	ldb_da c, (0x025db6)
	cps c, 2
	jr z, ValidateMode_CheckRange
	cps c, 3
	jr z, ValidateMode_CheckRange
	cps c, 4
	jr nz, ValidateMode_Error

ValidateMode_CheckRange:
	cps wa, 0
	jr lt, ValidateMode_Error
	cpda16_24 xwa, (0x272ca)
	jr le, ValidateMode_InRange

ValidateMode_Error:
	ldw hl, 0xffff
	ret

ValidateMode_InRange:
	ldw_da xbc, (0x0271ee)
	cp wa, bc
	jr lt, ValidateMode_OutOfPage
	cpda16_24 xwa, (0x271f0)
	jr le, ValidateMode_InPage

ValidateMode_OutOfPage:
	lds hl, 1
	ret

ValidateMode_InPage:
	sub wa, bc
	muls wa, 0xe
	lda_24 xbc, (0x02723c)
	cpib_sri 0x07, 0xe4, 0xe0, 0x00
	jr nz, ValidateMode_Valid
	lds hl, 2
	ret

ValidateMode_Valid:
	lds hl, 0
	ret

FileIO_GetCurrentWallpaperIndex:
	ldw_da xwa, (0x0272c8)
	calr FileIO_ValidateModeAndRange
	cps hl, 0
	jr z, GetWallpaper_ReturnIndex
	ldw hl, 0xff98
	ret

GetWallpaper_ReturnIndex:
	ldw_da xhl, (0x0272c8)
	ret

FileIO_ScanDirEntries:
	stb_dri L, 0xfd, 0xee, 0xfe
	pushw iz
	lda_24 xbc, (0x02723c)
	ld xwa, xbc
	stb_dri B, 0xe5, 0x8c, 0x00

ScanDir_CopyEntryLoop:
	ld xiy, SeqFileTypeCode_Lsw_0xAE
	ld xix, xwa
	lds bc, 7
	ldirw
	lda xwa, (xwa + 14)
	cp xwa, xde
	jr c, ScanDir_CopyEntryLoop
	lds iz, 0
	lda xbc, (xsp + 10)
	ld xwa, FileOp_StubAndDirNames_0x8A
	call _findfirst
	ld (xsp + 2), xhl
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jr lt, ScanDir_Return
	lda xwa, (xsp + 16)
	ld (xsp + 6), xwa
	ldw_da xwa, (0x0271ee)
	cps wa, 0
	jr gt, ScanDir_FirstEntryDone
	cpw_da (0x271f0), 0
	jr lt, ScanDir_FirstEntryDone
	neg wa
	muls wa, 0xe
	lda_24 xbc, (0x02723c)
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

ScanDir_FirstEntryDone:
	lds iz, 1
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cps hl, 0
	jr nz, ScanDir_CloseFindHandle

ScanDir_NextEntryCheck:
	ldw_da xwa, (0x0271ee)
	cp iz, wa
	jr lt, ScanDir_IterateNext
	cpda16_24 xiz, (0x271f0)
	jr gt, ScanDir_IterateNext
	ld bc, iz
	sub bc, wa
	muls bc, 0xe
	ld wa, bc
	lda_24 xbc, (0x02723c)
	exts xwa
	add xwa, xbc
	ld xbc, (xsp + 6)
	calr FileIO_CopyString

ScanDir_IterateNext:
	inc 1, iz
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 2)
	call _findnext
	cps hl, 0
	jr z, ScanDir_NextEntryCheck

ScanDir_CloseFindHandle:
	ld xwa, (xsp + 2)
	call _findclose

ScanDir_Return:
	ld hl, iz
	popw iz
	stb_dri L, 0xfd, 0x12, 0x01
	ret

FileIO_SelectWallpaperByIndex:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr FileIO_ValidateModeAndRange
	cp hl, 0xffff
	jr nz, SelectWP_CheckPageBound
	ldw_da xhl, (0x0272c8)
	jr SelectWP_Return

SelectWP_CheckPageBound:
	cps hl, 1
	jr nz, SelectWP_StoreIndex
	ld wa, iz
	extz xwa
	div wa, 0xa
	mul wa, 0xa
	ld bc, wa
	stw_da (0x0271ee), xbc
	add bc, 0x9
	ldw_da xwa, (0x0272ca)
	cp bc, wa
	jr ge, SelectWP_ClampEnd
	ld wa, bc

SelectWP_ClampEnd:
	stw_da (0x0271f0), xwa
	calr FileIO_ScanDirEntries

SelectWP_StoreIndex:
	ld hl, iz
	stw_da (0x0272c8), xhl

SelectWP_Return:
	popw iz
	ret

FileIO_GetWallpaperEntry:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr FileIO_ValidateModeAndRange
	cps hl, 0
	jr z, GetWPEntry_ComputeOffset
	lda_24 xhl, (Filename_TemplateArea)
	jr GetWPEntry_Return

GetWPEntry_ComputeOffset:
	ldw_da xwa, (0x0271ee)
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
	stiw_da (0x0271ee), 0x0000
	stiw_da (0x0271f0), 0x0009
	calr FileIO_ScanDirEntries
	lds wa, 0
	cps hl, 0
	jr le, InitWPNav_ClampEnd
	ld wa, hl
	dec 1, wa

InitWPNav_ClampEnd:
	stw_da (0x0272ca), xwa
	cpdm16_24 (0x271f0), xwa
	ret le
	stw_da (0x0271f0), xwa
	ret

ResetProgressIndication:
	.incbin "includes/generated/v7_transplant_ResetProgressIndication.bin"
FileIO_DiskInserted:
	.incbin "includes/generated/v7_transplant_FileIO_DiskInserted.bin"
FileIO_DiskInserted_Stub1:
	ret

FileIO_DiskInserted_Stub2:
	ret

FileIO_DiskRemoved:
	.incbin "includes/generated/v7_transplant_FileIO_DiskRemoved.bin"
InitializeOperationState:
	.incbin "includes/generated/v7_transplant_InitializeOperationState.bin"
InitOp_SkipSetFlag:
	.incbin "includes/generated/v7_transplant_InitOp_SkipSetFlag.bin"
CancelOperationCleanup:
	ldb_d8 a, (0x28a7)
	bit 2, a
	jr z, CancelOp_ClearSeq
	res 2, a
	stb_d8 (0x28a7), a

CancelOp_ClearSeq:
	.incbin "includes/generated/v7_transplant_CancelOp_ClearSeq.bin"
SignalProgressUpdate:
	call CPanel_InitButtonState_SaveRegs
	jp RefreshSwEvent

SeqPhase_OperationStateCheck:
	.incbin "includes/generated/v7_transplant_SeqPhase_OperationStateCheck.bin"
SeqPhase_CheckMediaType:
	.incbin "includes/generated/v7_transplant_SeqPhase_CheckMediaType.bin"
SeqPhase_MediaIsValid:
	.incbin "includes/generated/v7_transplant_SeqPhase_MediaIsValid.bin"
SeqPhase_CheckEncodedData:
	.incbin "includes/generated/v7_transplant_SeqPhase_CheckEncodedData.bin"
SeqPhase_FormatNameLoop:
	.incbin "includes/generated/v7_transplant_SeqPhase_FormatNameLoop.bin"
SeqPhase_LoadSuccess:
	.incbin "includes/generated/v7_transplant_SeqPhase_LoadSuccess.bin"
SeqPhase_SendSoundCmd:
	ldw wa, 0xee
	call SoundCtrl_SendCommand

SeqPhase_PopIzRet:
	popw iz
	ret

FileIO_MidiOutSendByte:
	.incbin "includes/generated/v7_transplant_FileIO_MidiOutSendByte.bin"
MidiOutSend_Return:
	inc 2, xsp
	ret

FileIO_DiskEventDispatch:
	.incbin "includes/generated/v7_transplant_FileIO_DiskEventDispatch.bin"
DiskEvt_CheckMediaType:
	.incbin "includes/generated/v7_transplant_DiskEvt_CheckMediaType.bin"
DiskEvt_TypeIsFloppyOrHD:
	bitda_24 0, (0x340f4)
	jr z, DiskEvt_UseAltChannel
	ld a, (xsp)
	extz wa
	jr DiskEvt_PostModeEvent

DiskEvt_UseAltChannel:
	ld a, (xsp + 2)
	extz wa
	jr DiskEvt_PostModeEvent

DiskEvt_TypeIsUSB:
	.incbin "includes/generated/v7_transplant_DiskEvt_TypeIsUSB.bin"
DiskEvt_TypeIsNone:
	ldw wa, 0x7d

DiskEvt_PostModeEvent:
	call UI_PostModeChangeEvent
	jr DiskEvt_Return

DiskEvt_TypeIsCard:
	.incbin "includes/generated/v7_transplant_DiskEvt_TypeIsCard.bin"
DiskEvt_SendSoundCmd:
	call SoundCtrl_SendCommand

DiskEvt_Return:
	inc 4, xsp
	ret

FileIO_DetectFileTypeAndPost:
	.incbin "includes/generated/v7_transplant_FileIO_DetectFileTypeAndPost.bin"
DetectType_CheckMediaType:
	.incbin "includes/generated/v7_transplant_DetectType_CheckMediaType.bin"
DetectType_TypeIsFloppy:
	call DetectFileType
	cps hl, 0
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
	.incbin "includes/generated/v7_transplant_DetectType_IsCardReset.bin"
FileIO_GetDiskCapacity:
	.incbin "includes/generated/v7_transplant_FileIO_GetDiskCapacity.bin"
DiskCap_CheckMediaType:
	.incbin "includes/generated/v7_transplant_DiskCap_CheckMediaType.bin"
DiskCap_TypeIsNone:
	ldw wa, 0x7d
	jr DiskCap_PostModeEvent

DiskCap_TypeIsCardReset:
	.incbin "includes/generated/v7_transplant_DiskCap_TypeIsCardReset.bin"
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
	cps wa, 0
	jr ge, ValidateSigned_Positive
	ld de, wa
	res 15, de
	cp de, 0xff
	jr ge, ValidateSigned_LookupTable
	ld l, a
	ret

ValidateSigned_LookupTable:
	lds iy, 0
	lda_24 xix, (DiskOp_ChannelCfgTable_0x10)
	lds de, 0
	jr ValidateSigned_ScanLoop

ValidateSigned_NextEntry:
	inc 1, iy
	inc 4, de

ValidateSigned_ScanLoop:
	stb_dri C, 0x07, 0xf0, 0xe8
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
	ldb l, 0x23
	ret

FileIO_ErrorCodeByteBlock:
	.incbin "includes/generated/v7_transplant_FileIO_ErrorCodeByteBlock.bin"
FileIO_MedleyDispatchByMode:
	.incbin "includes/generated/v7_transplant_FileIO_MedleyDispatchByMode.bin"
MedleyDisp_ModeSmf:
	cp a, 0x6c
	jr nz, MedleyDisp_ModeDoc
	lds32 xwa, 0
	ld xbc, 0x1c00017
	ld xde, 0xd
	jrl FmmSmfMedleyFunc

MedleyDisp_ModeDoc:
	cp a, 0x6d
	jr nz, MedleyDisp_ModePd
	lds32 xwa, 0
	ld xbc, 0x1c00017
	ld xde, 0xd
	jp FmmDocMedleyFunc

MedleyDisp_ModePd:
	cp a, 0x6e
	jr nz, MedleyDisp_ModeDisk
	lds32 xwa, 0
	ld xbc, 0x1c00017
	ld xde, 0xd
	jrl FmmPdMedleyFunc

MedleyDisp_ModeDisk:
	cp a, 0x77
	ret nz
	lds32 xwa, 0
	ld xbc, 0x1c00017
	ld xde, 0xd
	calr FmmDiskMedleySelectFunc
	ret

NumToAscii_FormatNumber:
	push xiz
	lds ix, 0
	cp c, 0x10
	jr ule, NumToAscii_ClampMin
	ldb c, 0x10
	jr NumToAscii_PadLeading

NumToAscii_ClampMin:
	cps c, 5
	jr ule, NumToAscii_StartDigits

NumToAscii_PadLeading:
	.incbin "includes/generated/v7_transplant_NumToAscii_PadLeading.bin"
NumToAscii_PadLoop:
	ld hl, ix
	inc 1, ix
	extz xhl
	add xhl, xde
	ld (xhl), 0x20
	dec 1, c
	cps c, 5
	jr ugt, NumToAscii_PadLoop

NumToAscii_StartDigits:
	.incbin "includes/generated/v7_transplant_NumToAscii_StartDigits.bin"
NumToAscii_NoTenThousands:
	.incbin "includes/generated/v7_transplant_NumToAscii_NoTenThousands.bin"
NumToAscii_ThousandsDigit:
	.incbin "includes/generated/v7_transplant_NumToAscii_ThousandsDigit.bin"
NumToAscii_NoThousands:
	.incbin "includes/generated/v7_transplant_NumToAscii_NoThousands.bin"
NumToAscii_PadThousands:
	.incbin "includes/generated/v7_transplant_NumToAscii_PadThousands.bin"
NumToAscii_HundredsDigit:
	.incbin "includes/generated/v7_transplant_NumToAscii_HundredsDigit.bin"
NumToAscii_NoHundreds:
	.incbin "includes/generated/v7_transplant_NumToAscii_NoHundreds.bin"
NumToAscii_PadHundreds:
	.incbin "includes/generated/v7_transplant_NumToAscii_PadHundreds.bin"
NumToAscii_TensDigit:
	.incbin "includes/generated/v7_transplant_NumToAscii_TensDigit.bin"
NumToAscii_NoTens:
	.incbin "includes/generated/v7_transplant_NumToAscii_NoTens.bin"
NumToAscii_PadTens:
	cps c, 2
	jr c, NumToAscii_OnesDigitAndFinish
	ld bc, ix
	inc 1, ix
	extz xbc
	add xbc, xde
	ld (xbc), 0x20

NumToAscii_OnesDigitAndFinish:
	.incbin "includes/generated/v7_fix_numtoascii_onesdigitandfinish.bin"
	.include "file_io/title_handlers.s"
