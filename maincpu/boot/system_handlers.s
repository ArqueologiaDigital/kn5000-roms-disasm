; =============================================================================
; System Handlers (8K lines)
; =============================================================================
;
; Core system infrastructure: interrupt handlers (NMI, DMA, timers),
; the UI state machine, cooperative task scheduler, flash memory
; update routines, and LZSS decompression engine.
; =============================================================================


; Alias labels for backward compatibility with existing code
.equ LABEL_EF086F, Boot_CallInitHandlers
.equ LABEL_EF07A2, Boot_HandleComboDisplay
.equ LABEL_EF07F3, Boot_HandleFactoryReset

INTT2_HANDLER:
	reti

NMI_HANDLER:
	sti16_24 0x00ffca, 0x0000
	calr NMI_StorePayloadChecksums
	bitda 2, 64941
	jr z, NMI_SetPowerOffCode_A5A5
	sti16_24 0x00ffcc, 0x5a5a
	jr NMI_ClearGuardAndHalt

NMI_SetPowerOffCode_A5A5:
	sti16_24 0x00ffcc, 0xa5a5

NMI_ClearGuardAndHalt:
	stdi8 1024, 0
	resda 7, 354
	set_dd8 2, 0x3C
	halt
NMI_HaltLoop:
	jr	t, 0xfd

; ===========================================================================
; NMI_StorePayloadChecksums - Power-off NMI: save checksums and copy payload
; ===========================================================================
; Called by: NMI_HANDLER
; Entry: Machine is powering off; NMI has been triggered by SNS signal
; Exit:  DRAM[0xFFD4] = one's-complement checksum of region 1 (0xF180, 0x800 words)
;        DRAM[0xFFD2] = one's-complement checksum of region 2 (0xF980, 0x280 words)
;        SRAM[0x1E8000..] = copy of DRAM[0xF980..]
;        CPU halts (machine powers off)
; Notes: Guards against running without being armed:
;          - Checks internal RAM[0x0400] == 0x80 (NMI guard set by Boot_DisplayScreen)
;          - If guard not set, returns immediately (no-op)
;        On success the checksums are stored so SubCPU_Payload_Verify can verify
;        the payload on the next boot and show the splash screen (not "ALL INITIAL SETTING!").
; ===========================================================================
NMI_StorePayloadChecksums:
NMI_StorePayloadChecksums_Entry:
	cpdi8 1024, 128
	ret nz
	call Demo_SelectEntry_PreSaveCheck
	call SeqPlay_JumpCopyVoiceData
	ld xwa, 0xF180
	ldw bc, 0x800
	call Checksum_ComputeComplement
	st16_24 0x00ffd4, xhl
	ld xwa, 0xF980
	ldw bc, 0x280
	call Checksum_ComputeComplement
	st16_24 0x00ffd2, xhl
	call Seq_IsMelodyActive
	cps hl, 0
	jr z, NMI_CopyPayloadToSRAM
	adddi16_24 65492, 1000

NMI_CopyPayloadToSRAM:
	lda_24 xde, 0x00066e
	srl xde, 1
	ld xwa, 0x1E8000
	ld xbc, 0xF980
	call Copy_DE_words_from_XBC_to_XWA
	ret

; ===========================================================================
; SubCPU_Payload_Verify - Verify Sub-CPU firmware payload integrity
; ===========================================================================
; Entry: Sub-CPU firmware payload has been transferred
; Exit:  Error flag at 0x01E53E set to indicate result:
;          0x00 = Both checksums match (success)
;          0x01 = First checksum mismatch, second matches (partial error)
;          0xFF = Checksum verification failed (error)
; Notes: Computes checksums over two memory regions and compares against
;        expected values stored at boot. On failure, the error flag triggers
;        the "ERROR in CPU data transmission" dialog during boot.
;
; See also:
;   - SubCPU_Send_Payload - Transfers the firmware payload
;   - SubCPU_Payload_GetErrorFlag - Reads the error flag
;   - ErrorDialog_CPUTransmissionError - Error dialog shown on failure
; ===========================================================================
SubCPU_Payload_Verify:
SubCPU_Payload_Verify_Entry:
	ld xwa, 0xF180	; Start of payload region 1
	ldw bc, 0x800	; Size: 0x800 words
	call Checksum_ComputeComplement	; Compute checksum -> HL
	lda_24 xwa, 0x00f980
	cpda16_24 xhl, 65492	; Compare with expected checksum
	jr nz, SubCPU_Payload_Verify_Fail	; First region checksum failed
	sti8_24 0x01e53e, 0x00                 ; Mark as success (so far)
	ldw bc, 0x280	; Size of second region
	call Checksum_ComputeComplement	; Compute second checksum
	cpda16_24 xhl, 65490	; Compare with expected
	ret z	; Both match -> success
	sti8_24 0x01e53e, 0xff                 ; Second region failed
	ret

SubCPU_Payload_Verify_Fail:
SubCPU_Payload_Verify_Fail_Entry:
	sti8_24 0x01e53e, 0xff                 ; Mark as failed
	ldw bc, 0x280
	call Checksum_ComputeComplement
	cpda16_24 xhl, 65490
	ret nz	; Both checksums wrong
	sti8_24 0x01e53e, 0x01                 ; First wrong, second correct (partial)
	ret

; ===========================================================================
; SubCPU_Payload_GetErrorFlag - Get Sub-CPU payload transfer error status
; ===========================================================================
; Entry: None
; Exit:  HL = Error flag value
;          0x0000 = Success (payload transferred correctly)
;          0xFFFF = Error (triggers "ERROR in CPU data transmission" dialog)
;          0x0001 = Partial error
; Notes: Called during boot to check if SubCPU_Payload_Verify detected errors.
;
; See also:
;   - SubCPU_Payload_Verify - Sets the error flag
;   - ErrorDialog_CPUTransmissionError - Error dialog shown when HL != 0
; ===========================================================================
SubCPU_Payload_GetErrorFlag:
SubCPU_Payload_GetErrorFlag_Entry:
	ld8_24 l, 0x01e53e
	exts hl
	ret

SubCPU_PayloadErrorStore:
	sti8_24 0x01e53e, 0xff
	ret

Sys_CheckPowerStableFlag:
	cpdi16_24 65484, 23130
	scc16 z, hl
	ret

Vga_WritePortShortDelay:
	lds de, 0

Vga_WritePort_DelayLoop:
	inc 1, de
	cp de, 0x80
	jr c, Vga_WritePort_DelayLoop
	extz xwa
	ld xde, 0x170000
	add xde, xwa
	ld (xde), c
	ret

Vga_SelectWritePlane:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x3C4
	lds bc, 6
	calr Vga_WritePortShortDelay
	ldw wa, 0x3C5
	lds bc, 1
	calr Vga_WritePortShortDelay
	ldw wa, 0x3C4
	ldw bc, 0x8
	calr Vga_WritePortShortDelay
	ld a, (xsp)
	sll a, 4
	set 0, a
	ld c, a
	extz bc
	ldw wa, 0x3C5
	calr Vga_WritePortShortDelay
	ldw wa, 0x3C4
	lds bc, 6
	calr Vga_WritePortShortDelay
	ldw wa, 0x3C5
	lds bc, 0
	calr Vga_WritePortShortDelay
	inc 2, xsp
	ret

Vga_SetupMultiPlaneDisplay:
	call Stop_and_Clear_8bit_Timer_3
	ld xwa, 0x1B4000
	ld xbc, 0xF180
	ldw de, 0x400
	call Copy_DE_words_from_XBC_to_XWA
	ld xwa, 0x1B4800
	ld xbc, 0xAB000
	ld xde, 0x5C00
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 1
	calr Vga_SelectWritePlane
	lda_24 xbc, 0x0ab000
	add xbc, 0xB800
	ld xwa, 0x1A0000
	ld xde, 0x10000
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 2
	calr Vga_SelectWritePlane
	lda_24 xbc, 0x0ab000
	add xbc, 0x2B800
	ld xwa, 0x1A0000
	ld xde, 0x10000
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 3
	calr Vga_SelectWritePlane
	lda_24 xbc, 0x0ab000
	add xbc, 0x4B800
	ld xwa, 0x1A0000
	ldw de, 0x4C00
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 0
	calr Vga_SelectWritePlane
	jp Start_8bit_Timer_3

Vga_RestoreMultiPlaneDisplay:
	call Stop_and_Clear_8bit_Timer_3
	ld xwa, 0xF180
	ld xbc, 0x1B4000
	ldw de, 0x400
	call Copy_DE_words_from_XBC_to_XWA
	ld xwa, 0xAB000
	ld xbc, 0x1B4800
	ld xde, 0x5C00
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 1
	calr Vga_SelectWritePlane
	lda_24 xwa, 0x0ab000
	add xwa, 0xB800
	ld xbc, 0x1A0000
	ld xde, 0x10000
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 2
	calr Vga_SelectWritePlane
	lda_24 xwa, 0x0ab000
	add xwa, 0x2B800
	ld xbc, 0x1A0000
	ld xde, 0x10000
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 3
	calr Vga_SelectWritePlane
	lda_24 xwa, 0x0ab000
	add xwa, 0x4B800
	ld xbc, 0x1A0000
	ldw de, 0x4C00
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 0
	calr Vga_SelectWritePlane
	jp Start_8bit_Timer_3

Vga_BackupPlane3ToBuffer:
	call Stop_and_Clear_8bit_Timer_3
	lds wa, 3
	calr Vga_SelectWritePlane
	ld xwa, 0x1A9800
	ld xbc, 0x69800
	ld xde, 0xB400
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 0
	calr Vga_SelectWritePlane
	jp Start_8bit_Timer_3

Vga_RestorePlane3FromBuffer:
	call Stop_and_Clear_8bit_Timer_3
	lds wa, 3
	calr Vga_SelectWritePlane
	ld xwa, 0x69800
	ld xbc, 0x1A9800
	ld xde, 0xB400
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 0
	calr Vga_SelectWritePlane
	jp Start_8bit_Timer_3

; Boot_InitWorkRAM -- Early-boot DRAM initialisation
;
; Called once from RESET_HANDLER before any other firmware subsystem is set up.
; Performs two passes over DRAM to prepare a clean working environment:
;
;   1. Zero-fill block 1: 0x010000 .. 0x03D523  (0x2D524 bytes, ~181 KB)
;      General-purpose work RAM used by the event dispatcher and subsystem state.
;
;   2. Zero-fill block 2: 0x000400 .. 0x00E35D  (0xDF5D bytes, ~55 KB)
;      Low DRAM including the control-panel button state array (0x8E4A),
;      the combo-code cell (0x402), and other low-DRAM variables.
;
;   3. ROM copy block 1: ROM 0xEED8C8 -> DRAM 0x03D524  (0x219E bytes, ~8.5 KB)
;      Copies a constant data block from Program ROM into work RAM.
;
;   4. ROM copy block 2: ROM 0xEEFA66 -> DRAM 0x00E35E  (0x95B bytes, ~2.4 KB)
;      Copies a second constant data block from Program ROM into work RAM.
;
; Each block uses the firmware's block-transfer helper (ldirw93 / ldir83) which
; can transfer data in batches via the WA loop counter register.
;
; Returns: no return value; falls through to the next boot stage.
Boot_InitWorkRAM:
	ld xde, 0x10000
	ld xbc, 0x2D524
	ld ix, bc
	srl xbc, 1
	jr z, MemCopy_DataValidation
	ld xhl, xde
	stiw_dpi 0xE9, 0x00, 0x00
	dec 1, xbc
	or xbc, xbc
	jr z, MemCopy_DataValidation
	ldirw93
	cpi_werp 0xE6, 0
	jr z, MemCopy_DataValidation
	ldto_werp WA, 0xE6

Boot_InitWorkRAM_ZeroBlock1_Loop:
	ldirw93
	djnz xwa, Boot_InitWorkRAM_ZeroBlock1_Loop

MemCopy_DataValidation:
	bit 0, ix
	jr z, Boot_InitWorkRAM_ZeroBlock1_Done
	ld (xde), 0x0

Boot_InitWorkRAM_ZeroBlock1_Done:
	ld xde, 0x400
	ld xbc, 0xDF5D
	ld ix, bc
	srl xbc, 1
	jr z, MemCopy_SetupAndDMA
	ld xhl, xde
	stiw_dpi 0xE9, 0x00, 0x00
	dec 1, xbc
	or xbc, xbc
	jr z, MemCopy_SetupAndDMA
	ldirw93
	cpi_werp 0xE6, 0
	jr z, MemCopy_SetupAndDMA
	ldto_werp WA, 0xE6

Boot_InitWorkRAM_ZeroBlock2_Loop:
	ldirw93
	djnz xwa, Boot_InitWorkRAM_ZeroBlock2_Loop

MemCopy_SetupAndDMA:
	bit 0, ix
	jr z, Boot_InitWorkRAM_ROMCopy1_Start
	ld (xde), 0x0

Boot_InitWorkRAM_ROMCopy1_Start:
	ld xde, 0x3D524
	ld xhl, 0xEED8C8
	ld xbc, 0x219E
	or xbc, xbc
	jr z, Boot_InitWorkRAM_ROMCopy2_Start
	ldir83
	cpi_werp 0xE6, 0
	jr z, Boot_InitWorkRAM_ROMCopy2_Start
	ldto_werp WA, 0xE6

Boot_InitWorkRAM_ROMCopy1_Loop:
	ldir83
	djnz xwa, Boot_InitWorkRAM_ROMCopy1_Loop

Boot_InitWorkRAM_ROMCopy2_Start:
	ld xde, 0xE35E
	ld xhl, 0xEEFA66
	ld xbc, 0x95B
	or xbc, xbc
	jr z, Boot_InitWorkRAM_Done
	ldir83
	cpi_werp 0xE6, 0
	jr z, Boot_InitWorkRAM_Done
	ldto_werp WA, 0xE6

Boot_InitWorkRAM_ROMCopy2_Loop:
	ldir83
	djnz xwa, Boot_InitWorkRAM_ROMCopy2_Loop

Boot_InitWorkRAM_Done:
	jrl Boot_RunSelfTest
	ret

Boot_InitWorkRAM_Trailer:
	.byte 0x0e

INTT1_HANDLER:
	incdi16 1, 1475
	pushw wa
	push xhl
	xor xhl, xhl
	inc 1, xhl
	adddm32 1033, xhl
	incdi16 1, 1037
	push_sr
	ei 6
	ldda8 a, 1063
	ldda8 w, 1062
	bit 7, a
	jr z, INTT1_NoOverflow
	incdi8 1, 1061
	cpdi8 1061, 165
	jr ule, INTT1_NoOverflow
	and a, 0x7F
	or a, 0x20

INTT1_NoOverflow:
	inc 1, w
	cp w, 0x86
	jr ule, INTT1_StoreCounters
	ldb w, 0x0
	ordi8 1065, 16
	call MIDI_SC0_TX_DISPATCH

INTT1_StoreCounters:
	stda8 1062, w
	stda8 1063, a
	pop_sr
	ldda8 a, 1066
	cp a, 0xF1
	jr ugt, INTT1_CheckScanFlag
	inc 1, a

INTT1_CheckScanFlag:
	stda8 1066, a
	bitda 2, 64848
	jrl nz, INTT1_UpdateAlternateTimers
	incdi8 1, 1050
	bitda 0, 1056
	jr nz, INTT1_CheckTickOverflow
	bitda 5, 1056
	jr nz, INTT1_CheckTickCount
	stdi8 1050, 0
	jp UIStateMachine_DispatchEntry

INTT1_CheckTickCount:
	cpdi8 1050, 1
	jrl nc, UIStateMachine_DispatchEntry
	stdi8 1056, 16

INTT1_CheckMidiSync:
	cpdi8 36148, 19
	jr z, UIState_DispatchBranch
	bitda 2, 64850
	jr z, UIState_DispatchBranch
	bitda 2, 64848
	jr nz, UIState_DispatchBranch
	push_sr
	ei 6
	ordi8 1065, 8
	call MIDI_SC0_TX_DISPATCH
	pop_sr

UIState_DispatchBranch:
	jr UIStateMachine_DispatchEntry

INTT1_CheckTickOverflow:
	cpdi8 1050, 1
	jr ule, UIStateMachine_DispatchEntry
	stdi8 1056, 6
	resda 0, 1139
	bitda 0, 1054
	jr z, INTT1_CheckAltSeqOverflow
	stdi8 1054, 6
	resda 0, 1139

INTT1_CheckAltSeqOverflow:
	bitda 0, 1057
	jr z, INTT1_CheckMidiSyncGate
	stdi8 1057, 6
	resda 0, 1139

INTT1_CheckMidiSyncGate:
	cpdi8 36148, 19
	jr z, INTT1_SkipToDispatch
	push_sr
	ei 6
	ordi8 1065, 1
	call MIDI_SC0_TX_DISPATCH
	pop_sr

INTT1_SkipToDispatch:
	jr UIStateMachine_DispatchEntry

INTT1_UpdateAlternateTimers:
	bitda 3, 1054
	jr z, INTT1_CheckAltSeqTimer
	stdi8 1054, 16

INTT1_CheckAltSeqTimer:
	bitda 3, 1057
	jr z, INTT1_CheckMetroTimer
	stdi8 1057, 16
	ldda8 a, 1045
	stda8 1078, a
	ldda8 a, 1046
	stda8 1079, a

INTT1_CheckMetroTimer:
	bitda 3, 1056
	jr z, UIStateMachine_DispatchEntry
	stdi8 1056, 16
	jrl INTT1_CheckMidiSync

UIStateMachine_DispatchEntry:
	ldada xhl, 1055
	ld a, (xhl)
	bitda 2, 64848
	jr nz, UIStateMachine_CheckPending
	bit 0, a
	jr z, UIStateMachine_CheckPending
	ld (xhl), 0x6
	resda 0, 1139

UIStateMachine_CheckPending:
	bit 3, a
	jr z, UIStateMachine_ClearBit3
	ld (xhl), 0x10

UIStateMachine_ClearBit3:
	resda 2, 1043
	ldda8 a, 1041
	inc 1, a
	cps a, 2
	jr ule, UIStateMachine_PrimaryDispatch
	sub a, a
	incdi8 1, 1042

; UI state machine primary dispatch
; Index: DRAM[1041] (0-2), entries: 3
; State 0: Idle, State 1: Process, State 2: Sub-state dispatch
UIStateMachine_PrimaryDispatch:
	stda8 1041, a
	sll a, 2
	lda_24 xhl, 0xef0d64
	ld_sril3 XHL, 0x03, 0xEC, 0xE0
	jp (xhl)

; UI state machine - primary state dispatch
; Uses (0411h) as state index (0-2), multiplied by 4
UI_STATE_MACHINE_TABLE:
	.long UI_STATE_0_IDLE
	.long UI_STATE_1_PROCESS
	.long UI_STATE_2_SUBSTATE

UI_STATE_0_IDLE:
	jrl UIStateMachine_ExitToScheduler

UI_STATE_1_PROCESS:
	anddi8 1058, 110
	bitda 0, 1042
	jr nz, UIState1_AlternateExit
	ldada xhl, 1116
	cp (xhl), 0x0
	jr z, UIState1_SkipToExit
	decm8 1, (xhl)

UIState1_SkipToExit:
	jrl UIStateMachine_ExitToScheduler

UIState1_AlternateExit:
	jrl UIStateMachine_ExitToScheduler

UI_STATE_2_SUBSTATE:
	ldda8 a, 1042
	and a, 0xF
	sll a, 2
	lda_24 xhl, 0xef0da5
	ld_sril3 XHL, 0x03, 0xEC, 0xE0
	jp (xhl)

; UI sub-state dispatch table (16 entries)
; Uses (0412h) & 0x0F as index, multiplied by 4
; Pattern repeats every 4 entries with different action in slot 2
UI_SUBSTATE_TABLE:
	.long UI_SUBSTATE_CLEAR_FLAGS
	.long UI_SUBSTATE_PROCESS_A
	.long UI_SUBSTATE_ACTION_0
	.long UI_SUBSTATE_CLEAR_BIT3
	.long UI_SUBSTATE_CLEAR_FLAGS
	.long UI_SUBSTATE_PROCESS_A
	.long UI_SUBSTATE_ACTION_1
	.long UI_SUBSTATE_CLEAR_BIT3
	.long UI_SUBSTATE_CLEAR_FLAGS
	.long UI_SUBSTATE_PROCESS_A
	.long UI_SUBSTATE_ACTION_2
	.long UI_SUBSTATE_CLEAR_BIT3
	.long UI_SUBSTATE_CLEAR_FLAGS
	.long UI_SUBSTATE_PROCESS_A
	.long UI_SUBSTATE_ACTION_3
	.long UI_SUBSTATE_CLEAR_BIT3

UI_SUBSTATE_CLEAR_FLAGS:
	resda 6, 1058
	resda 0, 1043
	jr UIStateMachine_ExitToScheduler

UI_SUBSTATE_PROCESS_A:
	resda 1, 1043
	resda 0, 1044
	ldb a, 0x2
	call TaskSched_SignalEvent_NoBlock
	jr UIStateMachine_ExitToScheduler

UI_SUBSTATE_CLEAR_BIT3:
	resda 3, 1043
	jr UIStateMachine_ExitToScheduler

UI_SUBSTATE_ACTION_0:
	resda 4, 1043
	jr UIStateMachine_ExitToScheduler

UI_SUBSTATE_ACTION_1:
	resda 5, 1043
	jr UIStateMachine_ExitToScheduler

UI_SUBSTATE_ACTION_2:
	resda 6, 1043
	jr UIStateMachine_ExitToScheduler

UI_SUBSTATE_ACTION_3:
	resda 7, 1043

UIStateMachine_ExitToScheduler:
	pop xhl
	popw wa
	jp INTT3_CheckNesting

INTTR4_HANDLER:
	pushw wa
	push xhl
	push xiy
	lda_24 xiy, 0x01e753
	ldada xhl, 1039
	incm8 1, (xhl)
	cp (xhl), 0x60
	jr c, INTTR4_TickWrapped
	ld (xhl), 0x0

INTTR4_TickWrapped:
	bitda 2, 64848
	jr z, INTTR4_CheckSyncEnable
	jp INTTR4_SubTick_Mode

INTTR4_CheckSyncEnable:
	bitda 2, 1055
	jr z, INTTR4_CheckMetroEnable
	push_sr
	ei 6
	ldda8 a, 1130
	inc 1, a
	cp a, 0x60
	jr c, INTTR4_SyncCounter2_NoWrap
	xor a, a
	incdi16 1, 1128
	stda8 1130, a
	cpdi8 32523, 0
	jr z, INTTR4_SyncCounter2_Done
	calr TempoRingBuf_Write
	jr INTTR4_SyncCounter2_Done

INTTR4_SyncCounter2_NoWrap:
	stda8 1130, a

INTTR4_SyncCounter2_Done:
	pop_sr

INTTR4_CheckMetroEnable:
	bitda 2, 1056
	jr z, INTTR4_CheckSeqEnable
	push_sr
	ei 6
	ldda8 a, 1047
	inc 1, a
	cp a, 0x60
	jr lt, INTTR4_MetroCounter_Store
	xor a, a
	incdi16 1, 1048

INTTR4_MetroCounter_Store:
	stda8 1047, a
	pop_sr

INTTR4_CheckSeqEnable:
	bitda 2, 1054
	jr z, INTTR4_CheckAltSeqEnable
	incdi8 1, 1045
	cpdi8 1045, 96
	jr c, INTTR4_CheckAltSeqEnable
	stdi8 1045, 0
	incdi8 1, 1046
	cpdi8 14235, 0
	jr z, INTTR4_SeqTick_CheckBeat
	calr TempoRingBuf_Write

INTTR4_SeqTick_CheckBeat:
	ldda8 a, 1046
	ldda8 w, 1075
	ex_sd16b W, 0x58, 0x04
	cp a, w
	jr c, INTTR4_CheckAltSeqEnable
	stdi8 1046, 0
	incdi8 1, 1076
	incdi8 1, 1077
	ldda8 a, 1077
	cpda8 a, 13527
	jr ule, INTTR4_CheckAltSeqEnable
	stdi8 1077, 0

INTTR4_CheckAltSeqEnable:
	bitda 2, 1057
	jr z, INTTR4_MetroPhaseSync
	incdi8 1, 1051
	cpdi8 1051, 96
	jr lt, INTTR4_MetroPhaseSync
	stdi8 1051, 0
	incdi16 1, 1052
	cpdi16 10410, 0
	jr z, INTTR4_MetroPhaseSync
	calr TempoRingBuf_Write

INTTR4_MetroPhaseSync:
	bitda 2, 1056
	jr z, INTTR4_SeqAutoStart
	bitda 0, 1054
	jr z, INTTR4_MetroSync_CheckAltSeq
	stdi8 1054, 6
	resda 0, 1139

INTTR4_MetroSync_CheckAltSeq:
	bitda 0, 1057
	jr z, INTTR4_MetroSync_Done
	stdi8 1057, 6
	resda 0, 1139

INTTR4_MetroSync_Done:
	jr INTTR4_MetroBeat_Check

INTTR4_SeqAutoStart:
	bitda 7, 1054
	jr z, INTTR4_MetroBeat_Check
	bitda 2, 1054
	jr z, INTTR4_SeqInit_SetEnable
	cpdi8 1045, 95
	jr c, INTTR4_SeqAutoStart_Skip
	cpdi8 1076, 1
	jr c, INTTR4_SeqAutoStart_Skip
	ldda8 a, 1075
	dec 1, a
	cpdm8 1046, a
	jr c, INTTR4_SeqAutoStart_Skip
	ldb a, 0x1
	stda8 1056, a
	stda8 1057, a
	cpdi8 36148, 19
	jr z, INTTR4_SeqAutoStart_Skip
	bitda 2, 64850
	jr z, INTTR4_SeqAutoStart_Skip
	bitda 2, 64848
	jr nz, INTTR4_SeqAutoStart_Skip
	push_sr
	ei 6
	ordi8 1065, 2
	call MIDI_SC0_TX_DISPATCH
	pop_sr

INTTR4_SeqAutoStart_Skip:
	jr INTTR4_MetroBeat_Check

INTTR4_SeqInit_SetEnable:
	stdi8 1054, 134

INTTR4_MetroBeat_Check:
	bitda 3, 1056
	jr z, INTTR4_SeqBeat_Check
	ldda8 a, 1047
	cps a, 0
	jr z, INTTR4_MetroBeat_OnBeat
	cp a, 0x18
	jr z, INTTR4_MetroBeat_OnBeat
	cp a, 0x30
	jr z, INTTR4_MetroBeat_OnBeat
	cp a, 0x48
	jr z, INTTR4_MetroBeat_OnBeat
	jr INTTR4_MetroQuarter_Check

INTTR4_MetroBeat_OnBeat:
	stdi8 1056, 16
	cpdi8 36148, 19
	jr z, INTTR4_SeqBeat_Check
	bitda 2, 64850
	jr z, INTTR4_SeqBeat_Check
	bitda 2, 64848
	jr nz, INTTR4_SeqBeat_Check
	push_sr
	ei 6
	ordi8 1065, 8
	call MIDI_SC0_TX_DISPATCH
	pop_sr

INTTR4_SeqBeat_Check:
	bitda 3, 1054
	jr z, INTTR4_AltSeqBeat_Check
	stdi8 1054, 16

INTTR4_AltSeqBeat_Check:
	bitda 3, 1057
	jr z, INTTR4_MetroQuarter_Check
	stdi8 1057, 16
	ldda8 a, 1045
	stda8 1078, a
	ldda8 a, 1046
	stda8 1079, a

INTTR4_MetroQuarter_Check:
	bitda 2, 1056
	jr z, INTTR4_SeqAccum_Update
	ldda8 a, 1047
	and a, 0x3
	jr nz, INTTR4_SeqAccum_Update
	cpdi8 36148, 19
	jr z, INTTR4_SeqAccum_Update
	push_sr
	ei 6
	ordi8 1065, 1
	call MIDI_SC0_TX_DISPATCH
	pop_sr

INTTR4_SeqAccum_Update:
	bitda 2, 1054
	jr z, INTTR4_SeqAccum_Reset
	push_sr
	ei 6
	ldda8 a, 1045
	ld w, a
	subda8 a, 1111
	jr z, INTTR4_SeqAccum_Done
	jr ugt, INTTR4_SeqAccum_PositiveDelta
	add a, 0x60

INTTR4_SeqAccum_PositiveDelta:
	stda8 1111, w
	adddm8 1124, a
	adddm8 1122, a
	xor w, w
	addda16 xwa, 1120
	cp a, 0x60
	jr c, INTTR4_SeqAccum_NoWrap
	sub a, 0x60
	inc 1, w

INTTR4_SeqAccum_NoWrap:
	stda16 1120, xwa

INTTR4_SeqAccum_Done:
	pop_sr
	jr INTTR4_AltSeqAccum_Update

INTTR4_SeqAccum_Reset:
	xor wa, wa
	stda16 1120, xwa
	stda16 13170, xwa
	stda8 1122, a
	stda8 13174, a
	stda8 1111, a

INTTR4_AltSeqAccum_Update:
	bitda 2, 1057
	jr z, INTTR4_FadeDelay_Check
	ldda8 a, 1051
	bitda 3, 1073
	jr z, INTTR4_AltSeqSync_Check
	cpdm8 1072, a
	jr nz, INTTR4_AltSeqSync_Check
	stdi8 1054, 8
	anddi8 1073, 247
	cpdi16 10410, 0
	jr z, INTTR4_AltSeqSync_Check
	ldb a, 0x86
	calr TempoRingBuf_WritePair

INTTR4_AltSeqSync_Check:
	bitda 0, 1073
	jr z, INTTR4_FadeDelay_Check
	cpdm8 1071, a
	jr nz, INTTR4_FadeDelay_Check
	stdi8 1054, 1
	anddi8 1073, 254
	cpdi16 10410, 0
	jr z, INTTR4_FadeDelay_Check
	ldb a, 0x85
	calr TempoRingBuf_WritePair

INTTR4_FadeDelay_Check:
	cpdi8 1126, 0
	jr z, INTTR4_SyncAccum_Update
	decdi8 1, 1126

INTTR4_SyncAccum_Update:
	bitda 2, 1055
	jr z, INTTR4_SyncAccum_Reset
	push_sr
	ei 6
	ldda8 a, 1130
	ld w, a
	subda8 a, 1138
	jr z, INTTR4_SyncAccum_Done
	jr ugt, INTTR4_SyncAccum_PositiveDelta
	add a, 0x60

INTTR4_SyncAccum_PositiveDelta:
	stda8 1138, w
	adddm8 1131, a
	adddm8 1133, a
	xor w, w
	addda16 xwa, 1136
	cp a, 0x60
	jr c, INTTR4_SyncAccum_NoWrap
	sub a, 0x60
	inc 1, w

INTTR4_SyncAccum_NoWrap:
	stda16 1136, xwa

INTTR4_SyncAccum_Done:
	pop_sr
	jr INTTR4_Return

INTTR4_SyncAccum_Reset:
	xor wa, wa
	stda16 1136, xwa
	stda16 32254, xwa
	stda8 1133, a
	stda8 32252, a
	stda8 1138, a

INTTR4_Return:
	pop xiy
	pop xhl
	popw wa
	reti

TempoRingBuf_Write:
	bitda 0, 1113
	jr nz, TempoRingBuf_Write_Enqueue
	pushw wa
	ld wa, (xiy - 2)
	and wa, wa
	jr z, TempoRingBuf_Write_Dequeue
	ld hl, (xiy - 4)
	stib_dri 0x07, 0xF4, 0xEC, 0x81
	minc1_16 hl, 0x7FF
	dec 1, wa
	ld (xiy - 4), hl
	ld (xiy - 2), wa

TempoRingBuf_Write_Dequeue:
	popw wa
	stdi16 1141, 0
	jr TempoRingBuf_Write_Return

TempoRingBuf_Write_Enqueue:
	pushw ix
	ldada xhl, 1143
	ldda16 xix, 1141
	stib_dri 0x07, 0xEC, 0xF0, 0x81
	inc 1, ix
	stda16 1141, xix
	popw ix

TempoRingBuf_Write_Return:
	ret

TempoRingBuf_WritePair:
	bitda 0, 1113
	jr nz, TempoRingBuf_WritePair_Enqueue
	cpdi16_24 124753, 2
	jr c, TempoRingBuf_WritePair_ClearPending
	push_sr
	ei 6
	push xiy
	lda_24 xiy, 0x01e753
	ld hl, (xiy - 4)
	lda_dri3 XBC, 0x07, 0xF4, 0xEC
	decm 1, (xiy - 2)
	minc1_16 hl, 0x7FF
	ldda8 a, 1051
	lda_dri3 XBC, 0x07, 0xF4, 0xEC
	minc1_16 hl, 0x7FF
	decm 1, (xiy - 2)
	st16_24 0x01e74f, xhl
	pop xiy
	pop_sr

TempoRingBuf_WritePair_ClearPending:
	stdi16 1141, 0
	ret

TempoRingBuf_WritePair_Enqueue:
	pushw ix
	ldada xhl, 1143
	ldda16 xix, 1141
	lda_dri3 XBC, 0x07, 0xEC, 0xF0
	ldda8 a, 1051
	inc 1, ix
	lda_dri3 XBC, 0x07, 0xEC, 0xF0
	ldda8 a, 1051
	inc 1, ix
	stda16 1141, xix
	popw ix
	ret

INTTR4_SubTick_Mode:
	bitda 2, 1057
	jr z, INTTR4_SubTick_MetroInc
	ldda8 a, 1051
	xor a, 0x3
	and a, 0x3
	jr z, INTTR4_SubTick_MetroInc
	incdi8 1, 1051

INTTR4_SubTick_MetroInc:
	bitda 2, 1056
	jr z, INTTR4_SubTick_SeqInc
	ldda8 a, 1047
	xor a, 0x3
	and a, 0x3
	jr z, INTTR4_SubTick_SeqInc
	incdi8 1, 1047

INTTR4_SubTick_SeqInc:
	bitda 2, 1054
	jr z, INTTR4_SubTick_PhaseSync
	ldda8 a, 1045
	xor a, 0x3
	and a, 0x3
	jr z, INTTR4_SubTick_PhaseSync
	incdi8 1, 1045

INTTR4_SubTick_PhaseSync:
	bitda 2, 1056
	jr z, INTTR4_SubTick_ToAccum
	bitda 0, 1054
	jr z, INTTR4_SubTick_PhaseSync_AltSeq
	stdi8 1054, 6
	resda 0, 1139

INTTR4_SubTick_PhaseSync_AltSeq:
	bitda 0, 1057
	jr z, INTTR4_SubTick_ToAccum
	stdi8 1057, 6
	resda 0, 1139

INTTR4_SubTick_ToAccum:
	jp INTTR4_SeqAccum_Update
INTTR4_BytecodeSnippet:
	ldb	l, 0
	.byte 0xf1, 0x14, 0x04, 0xa8
	ret	nz
	ldb	l, 1
	ret


Seq_InitFuncTable:
	.long Seq_FullInit
	.long Seq_InitStub_Nop2
	.long Seq_InitStub_Nop1
	.long Seq_InitStub_Nop3

; =============================================================================
; MainLoop - Firmware Main Processing Loop (EF1248)
; =============================================================================
; Called after boot initialization completes. Runs indefinitely, processing
; all firmware subsystems in a fixed order each iteration.
;
; The loop is organized into phases, each gated by timer flags in RAM:
;   - tset_dd16 atomically tests and sets bits (preventing re-entry)
;   - Timer ISR periodically clears bits to schedule the next iteration
;
; PHASE 1: Input Processing (gated by bit 0 of status word)
;   Boot_CallInitHandlers - Timer/init handler dispatch
;   MidiChannel_ProcessOutputState - MIDI output channel state changes
;   AccWrap_FlagSync - Accompaniment wrapper flag sync
;   MidiParam_ProcessDeltas - Delta-debounce for encoder parameters
;   CPanel_RX_ProcessOrInit - Control panel serial RX processing
;   Encoder_TimingAndOutput - Encoder timing and output formatting
;   MidiChannel_ScanPending - Scan for pending MIDI changes
;
; PHASE 2: Sequencer Core
;   Seq_TickWrapper - Advance sequencer one tick
;   Seq_EventProcessingTick - Process sequencer events (called 5x/loop)
;   SeqStep_MainTimerTick - Step sequencer timer
;
; PHASE 3: Voice/Effects Reset (conditional on flags at addr 1063)
;   SeqMain_InitBuffer, Voice_InitializeAll, MIDI_BroadcastPitchReset
;
; PHASE 4: MIDI and Polling (gated by timer bits 4-7)
;   MidiChannel_DispatchChanged, MIDI_ProcessChangedChannels, CPanel_Poll
;   EffectMode_CheckAndDispatch, Demo_SelectEntry_TimerTick
;   CommPort_StatusCheckAndSend, BitMapOut_DecrementTimer
;
; PHASE 5: UI and Display
;   MainTitle_PrepareAndDispatch, SwbtWr_ProcessAll, AccDir_PeriodicEntry
;   Display_DirtyRegionDispatch
;
; PHASE 6: Sequencer Finalization
;   SeqPhase_OperationStateCheck, AccompSeq_PeriodicEntry
;   CallExtIfActive_Entry (HDAE5000 extension)
; =============================================================================
MainLoop:
	ei 0
	call LABEL_EF086F
	call MidiChannel_ProcessOutputState
	call AccWrap_FlagSync
	tset_dd16 2, 0x13, 0x04
	jr nz, MainLoop_AfterTimerSync

MainLoop_AfterTimerSync:
	tset_dd16 0, 0x22, 0x04
	jr nz, MainLoop_AfterInput
	call MidiParam_ProcessDeltas
	call CPanel_RX_ProcessOrInit
	call Encoder_TimingAndOutput
	call MidiChannel_ScanPending

MainLoop_AfterInput:
	cpdi8 1124, 7
	jr ule, MainLoop_AfterSeqTick
	calr Seq_TickWrapper

MainLoop_AfterSeqTick:
	ei 6
	ldda8 a, 1063
	and a, 0x2C
	jr z, MainLoop_AfterVoiceReset
	call SeqMain_InitBuffer
	anddi8 1063, 211
	ei 0
	call Voice_InitializeAll
	call MIDI_BroadcastPitchReset

MainLoop_AfterVoiceReset:
	ei 0
	calr Seq_EventProcessingTick
	tset_dd16 0, 0x13, 0x04
	jr nz, MainLoop_AfterMidiDispatch
	call MidiChannel_DispatchChanged

MainLoop_AfterMidiDispatch:
	tset_dd16 1, 0x13, 0x04
	jr nz, MainLoop_AfterBit1Check

MainLoop_AfterBit1Check:
	tset_dd16 3, 0x13, 0x04
	jr nz, MainLoop_AfterBit3Check

MainLoop_AfterBit3Check:
	call SeqBuf_DspSysEx_CheckSongEnd
	and hl, hl
	jr z, MainLoop_AfterSeqBuf_DspSysEx
	call SeqBuf_DspSysEx_DataReadLoop

MainLoop_AfterSeqBuf_DspSysEx:
	ldda8 a, 13421
	and a, 0x3
	jr z, MainLoop_AfterAccWrap
	ldda8 a, 12931
	and a, 0x3
	jr nz, MainLoop_AfterAccWrap
	call AccWrap_DeferredAction

MainLoop_AfterAccWrap:
	tset_dd16 0, 0x73, 0x04
	jr nz, MainLoop_AfterPedalReset
	call CompIface_ResetPedal

MainLoop_AfterPedalReset:
	calr Seq_EventProcessingTick
	call Encoder_ValueScanAndSync
	cpdi8 48953, 255
	jr z, MainLoop_AfterSwbtWr
	call SwbtWr_ProcessAll

MainLoop_AfterSwbtWr:
	call MainTitle_PrepareAndDispatch
	calr MainLoop_ReinitSwbtWr
	call AccDir_PeriodicEntry
	calr Seq_EventProcessingTick
	call SeqBuf_NoteEvent_CheckSongEnd
	and hl, hl
	jr z, MainLoop_AfterSeqBuf_NoteEvent
	call SeMenu_ListSelector_Select

MainLoop_AfterSeqBuf_NoteEvent:
	ldada xiy, 1058
	mrid2 0xB5, 0xAE
	jr nz, MainLoop_AfterDialCheck
	calr MainLoop_AudioPeriodicCheck

MainLoop_AfterDialCheck:
	tset_dd16 4, 0x13, 0x04
	jr nz, MainLoop_AfterMidiPoll
	call EffectMode_TimerCountdown
	call SysEx_PeriodicDispatch
	call MIDI_ProcessChangedChannels
	call CPanel_Poll
	call EffectMode_CheckAndDispatch

MainLoop_AfterMidiPoll:
	tset_dd16 5, 0x13, 0x04
	jr nz, MainLoop_AfterDemoTick
	call Demo_SelectEntry_TimerTick
	call CDlikeSwitch_PlaybackTimer

MainLoop_AfterDemoTick:
	tset_dd16 6, 0x13, 0x04
	jr nz, MainLoop_AfterMidiPoll2
	call MIDI_ProcessChangedChannels
	call CPanel_Poll
	call CommPort_StatusCheckAndSend

MainLoop_AfterMidiPoll2:
	tset_dd16 7, 0x13, 0x04
	jr nz, MainLoop_AfterBitmapTimer
	call BitMapOut_DecrementTimer
	call Periodic_TimestampCheck

MainLoop_AfterBitmapTimer:
	ei 0
	bitda 7, 1068
	jr z, MainLoop_SequencerPhase
	call SeqPhase_OperationStateCheck

MainLoop_SequencerPhase:
	calr Seq_EventProcessingTick
	calr Seq_TickWrapper
	calr Seq_EventProcessingTick
	call SeqStep_MainTimerTick
	calr Seq_EventProcessingTick
	call Display_DirtyRegionDispatch
	call AccompSeq_PeriodicEntry
	call CallExtIfActive_Entry
	jrl MainLoop

Seq_TickWrapper:
	ldada xiy, 1115
	cp (xiy), 0x1
	jr nz, SeqTick_CheckActive
	cpdi8 52959, 0
	jr z, SeqTick_CheckActive
	ld (xiy), 0x0

SeqTick_CheckActive:
	bitm 0, (xiy)
	jr z, SeqTick_Dispatch
	bitda 2, 1054
	jr nz, SeqTick_Return

SeqTick_Dispatch:
	call Seq_DispatcherEntry
	stdi8 1124, 0

SeqTick_Return:
	ret

MainLoop_ReinitSwbtWr:
	call SwbtWr_InitBank3
	call Audio_MainPeriodicUpdate
	stdi8 49209, 255
	calr SwbtWr_ReinitBothBanks
	ret

MainLoop_AudioPeriodicCheck:
	call VoiceEvent_ResetAndInit
	call Voice_UpdateNoteState
	call SndParam_DispatchReturn
	ret

Seq_ProcessMidiEvent:
	lda_24 xhl, 0x01f37b
	ld iy, (xhl - 8)
	ld ix, (xhl - 4)
	xor bc, bc
	ld iz, bc

MidiEvt_ScanLoop:
	bit_dri 7, 0x07, 0xEC, 0xF4
	jr nz, MidiEvt_FoundStatusByte
	inc 1, iz
	minc1_16 iy, 0x3FF
	cp iy, ix
	jrl z, MidiSerial_BufferWrap
	jr MidiEvt_ScanLoop

MidiEvt_FoundStatusByte:
	ld_srib3 C, 0x07, 0xEC, 0xF4
	and c, 0xF0
	cp c, 0x90
	jr z, MidiEvt_SetNoteOnFlag
	cp c, 0x80
	jr z, MidiEvt_SetNoteOnFlag
	cp c, 0xB0
	jr nz, MidiSerial_DataReceive
	ld de, iy
	inc 1, iz
	minc1_16 iy, 0x3FF
	cp iy, ix
	jr z, MidiSerial_BufferWrap
	cp_srib_im 0x07, 0xEC, 0xF4, 0x7B
	jr c, MidiSerial_DataReceive

MidiEvt_SetNoteOnFlag:
	ldb b, 0x1

MidiSerial_DataReceive:
	bit_dri 7, 0x07, 0xEC, 0xF4
	jr z, MidiEvt_AdvancePointer
	ld_srib3 A, 0x07, 0xEC, 0xF4
	and a, 0xF0
	cp a, 0x90
	jr z, MidiEvt_SetDataFlag
	cp a, 0x80
	jr z, MidiEvt_SetDataFlag
	cp a, 0xB0
	jr nz, MidiEvt_ClearDataFlag
	ld de, iy
	ld wa, iz
	inc 1, iz
	minc1_16 iy, 0x3FF
	cp iy, ix
	jr z, MidiSerial_BufferWrap
	cp_srib_im 0x07, 0xEC, 0xF4, 0x7B
	ld iz, wa
	ld iy, de
	jr c, MidiEvt_ClearDataFlag

MidiEvt_SetDataFlag:
	or b, 0x2
	jr MidiEvt_CheckProcessMode

MidiEvt_ClearDataFlag:
	and b, 0xFD

MidiEvt_CheckProcessMode:
	cps b, 1
	jr z, MidiEvt_ProcessNoteOn
	cps b, 2
	jr z, MidiSerial_ProcessAndReinit

MidiEvt_AdvancePointer:
	inc 1, iz
	minc1_16 iy, 0x3FF
	cp iy, ix
	jr nz, MidiSerial_DataReceive

MidiSerial_BufferWrap:
	bit 0, b
	jr z, MidiSerial_ProcessAndReinit

MidiEvt_ProcessNoteOn:
	pushw iz
	ld (xhl - 6), iy
	call NoteOn_EntryPoint
	jr MidiEvt_UpdateReadPosition

MidiSerial_ProcessAndReinit:
	pushw iz
	ld (xhl - 6), iy
	call MidiSerial_ProcessInput
	call Audio_ProcessAllMidiStreams
	calr SwbtWr_ReinitBothBanks
	jr __jrt_nop_EF148F
__jrt_nop_EF148F:

MidiEvt_UpdateReadPosition:
	lda_24 xhl, 0x01f37b
	ld wa, (xhl - 6)
	ld (xhl - 8), wa
	popw wa
	add (xhl - 2), wa
	ret

RhythmBuf_DispatchWrap:
	calr RhythmBuf_DispatchEvent
	ret

Seq_EventProcessingTick:
	call AccNoteOn_ProcessVoiceSetup
	bitda 7, 1058
	jr nz, SeqEvtTick_ProcessTimers
	calr SeqEvt_CheckExpiry

SeqEvtTick_ProcessTimers:
	calr SeqEvt_ProcessTimedEvents
	call RhythmBuf_ProcessEvents
	call SeqEvt_ProcessBuffer
	call MIDI_OutputFlush
	call SysEx_ParseAndDispatch
	cpdi8 1140, 85
	jr z, SeqEvtTick_Return

Seq_ProcessEventLoop:
	call Seq_CheckSongEnd
	and hl, hl
	jr z, SeqEvtTick_Return
	calr Seq_ProcessMidiEvent
	jr Seq_ProcessEventLoop

SeqEvtTick_Return:
	ret
SwbtWr_ReinitBothBanks:

assswb_op:
	cpdi8 48444, 255
	jr z, SwbtWr_ReinitBothBanks_Return
	call SwbtWr_InitBank1
	call SwbtWr_InitBank2
	stdi8 48444, 255
	stdi16 37086, 0

SwbtWr_ReinitBothBanks_Return:
	ret
SwbtWr_ReinitOutputBank:

assswb_out:
	cpdi8 48444, 255
	jr z, SwbtWr_ReinitOutputBank_Return
	call SwbtWr_InitBank2
	stdi8 48444, 255
	stdi16 37086, 0

SwbtWr_ReinitOutputBank_Return:
	ret

RhythmBuf_ProcessEvents:
	bitda 2, 1054
	jr z, RhythmBuf_ProcessLoop
	calr SeqTiming_Snapshot

RhythmBuf_ProcessLoop:
	ld16_24 xwa, 0x01ef59
	cpda16_24 xwa, 126805
	jr z, RhythmBuf_ProcessLoop_Done
	calr RhythmBuf_DispatchEvent
	jr RhythmBuf_ProcessLoop

RhythmBuf_ProcessLoop_Done:
	ret

RhythmBuf_DispatchEvent:
	lda_24 xhl, 0x01ef5d
	calr RhythmBuf_ScanForNoteOn
	jr c, RhythmBuf_Dispatch_NonNoteOn
	call RhythmMidi_Dispatcher
	jr RhythmBuf_Dispatch_UpdateReadPos

RhythmBuf_Dispatch_NonNoteOn:
	call SeqPart_EmitNoteOn_Full

RhythmBuf_Dispatch_UpdateReadPos:
	ld16_24 xwa, 0x01ef57
	ld16_24 xbc, 0x01ef55
	st16_24 0x01ef55, xwa
	sub wa, bc
	jr ge, RhythmBuf_Dispatch_NoWrap
	add wa, 0x200

RhythmBuf_Dispatch_NoWrap:
	adddm16_24 126811, xwa
	ret

RhythmBuf_ScanForNoteOn:
	ld iy, (xhl - 8)
	ld ix, (xhl - 4)

RhythmBuf_Scan_SkipNonStatus:
	bit_dri 7, 0x07, 0xEC, 0xF4
	jr nz, RhythmBuf_Scan_FoundStatus
	minc1_16 iy, 0x1FF
	cp iy, ix
	jr z, RhythmBuf_Scan_EndReached
	jr RhythmBuf_Scan_SkipNonStatus

RhythmBuf_Scan_FoundStatus:
	ld de, iy
	ld_srib3 C, 0x07, 0xEC, 0xF4
	and c, 0xF0

RhythmBuf_Scan_CheckNext:
	bit_dri 7, 0x07, 0xEC, 0xF4
	jr z, RhythmBuf_Scan_Advance
	ld de, iy
	ld_srib3 A, 0x07, 0xEC, 0xF4
	and a, 0xF0
	cp c, a
	jr z, RhythmBuf_Scan_Advance
	cp c, 0x90
	jr z, RhythmBuf_Scan_ReturnNoteOn
	cp a, 0x90
	jr z, RhythmBuf_Scan_ReturnOther

RhythmBuf_Scan_Advance:
	minc1_16 iy, 0x1FF
	cp iy, ix
	jr z, RhythmBuf_Scan_EndReached
	jr RhythmBuf_Scan_CheckNext

RhythmBuf_Scan_EndReached:
	cp c, 0x90
	jr nz, RhythmBuf_Scan_ReturnOther

RhythmBuf_Scan_ReturnNoteOn:
	ld (xhl - 6), iy
	rcf
	jr RhythmBuf_Scan_Return

RhythmBuf_Scan_ReturnOther:
	ld (xhl - 6), iy
	anddi8 1115, 253
	scf

RhythmBuf_Scan_Return:
	ret

SeqEvt_ProcessBuffer:
	bitda 2, 1055
	jr z, SeqEvt_ProcessBuffer_Main
	calr SyncTiming_Snapshot

SeqEvt_ProcessBuffer_Main:
	lda_24 xhl, 0x01f271

SeqEvt_ProcessLoop:
	ld wa, (xhl - 4)
	cp wa, (xhl - 8)
	jr z, SeqEvt_ProcessDone
	calr SeqEvt_ScanForNoteOn
	jr c, SeqEvt_Dispatch_NonNoteOn
	call RhythmMidi_SeqEvt
	jr SeqEvt_UpdateReadPos

SeqEvt_Dispatch_NonNoteOn:
	call ProcessEventDispatch_Prologue

SeqEvt_UpdateReadPos:
	lda_24 xhl, 0x01f271
	ld wa, (xhl - 6)
	ld bc, (xhl - 8)
	ld (xhl - 8), wa
	sub wa, bc
	jr ge, SeqEvt_UpdateReadPos_NoWrap
	add wa, 0x100

SeqEvt_UpdateReadPos_NoWrap:
	add (xhl - 2), wa
	jr SeqEvt_ProcessLoop

SeqEvt_ProcessDone:
	ret

SeqEvt_ScanForNoteOn:
	ld iy, (xhl - 8)
	ld ix, (xhl - 4)

SeqEvt_Scan_SkipData:
	bit_dri 7, 0x07, 0xEC, 0xF4
	jr nz, SeqEvt_Scan_FoundStatus
	minc1_16 iy, 0xFF
	cp iy, ix
	jr z, SeqEvt_Scan_EndReached
	jr SeqEvt_Scan_SkipData

SeqEvt_Scan_FoundStatus:
	ld de, iy
	ld_srib3 C, 0x07, 0xEC, 0xF4
	and c, 0xF0

SeqEvt_Scan_CheckNext:
	bit_dri 7, 0x07, 0xEC, 0xF4
	jr z, SeqEvt_Scan_Advance
	ld de, iy
	ld_srib3 A, 0x07, 0xEC, 0xF4
	and a, 0xF0
	cp c, a
	jr z, SeqEvt_Scan_Advance
	cp c, 0x90
	jr z, SeqEvt_Scan_ReturnNoteOn
	cp a, 0x90
	jr z, SeqEvt_Scan_ReturnOther

SeqEvt_Scan_Advance:
	minc1_16 iy, 0xFF
	cp iy, ix
	jr z, SeqEvt_Scan_EndReached
	jr SeqEvt_Scan_CheckNext

SeqEvt_Scan_EndReached:
	cp c, 0x90
	jr nz, SeqEvt_Scan_ReturnOther

SeqEvt_Scan_ReturnNoteOn:
	ld (xhl - 6), iy
	rcf
	jr SeqEvt_Scan_Return

SeqEvt_Scan_ReturnOther:
	ld (xhl - 6), iy
	anddi8 1115, 253
	scf

SeqEvt_Scan_Return:
	ret

SeqEvt_CallTimingHelper:
	call SeqPlay_HandleVoiceReassign
	ret

SeqEvt_ProcessTimedEvents:
	bitda 5, 10412
	jr z, SeqEvt_ProcessTimedEvents_Idle
	call SeqEvent_CaseA
	calr Seq_TickWrapper
	call MIDI_START_PLAYBACK_REQUEST
	call AccNoteOn_ProcessVoiceSetup
	call RhythmBuf_ProcessEvents
	ret

SeqEvt_ProcessTimedEvents_Idle:
	call SeqPlay_HandleVoiceReassign
	ret

TempoRingBuf_Consume:
	push xix
	pushw hl
	ldada xix, 1143
	xor hl, hl
	ei 6

TempoRingBuf_Consume_Loop:
	cpda16 xhl, 1141
	jr nc, TempoRingBuf_Consume_Done
	ld_srib3 E, 0x07, 0xF0, 0xEC
	calr TempoRingBuf_DequeueOne
	inc 1, hl
	jr TempoRingBuf_Consume_Loop

TempoRingBuf_Consume_Done:
	resda 0, 1113
	stdi16 1141, 0
	ei 0
	popw hl
	pop xix
	ret

TempoRingBuf_BytecodeSnippet:
	bitda	0, 1113
	jr	nz, 6
	ldb	e, 129
	calr	24
	ret
	push	xix
	ldada	xix, 1143
	ldda16	hl, 1141
	.byte 0xf3, 0x07, 0xf0, 0xec, 0x00, 0x81
	inc	1, hl
	stda16	1141, hl
	pop	xix
	ret

TempoRingBuf_DequeueOne:
	push xix
	pushw hl
	pushw wa
	lda_24 xix, 0x01e753
	ld wa, (xix - 2)
	and wa, wa
	jr z, TempoRingBuf_DequeueOne_Done
	ld hl, (xix - 4)
	lda_dri3 XIY, 0x07, 0xF0, 0xEC
	minc1_16 hl, 0x7FF
	dec 1, wa
	ld (xix - 4), hl
	ld (xix - 2), wa

TempoRingBuf_DequeueOne_Done:
	popw wa
	popw hl
	pop xix
	ret

SeqEvt_CheckExpiry:
	anddi8 1058, 127
	ldda8 a, 59836
	and a, a
	jr z, SeqEvt_CheckExpiry_Return
	dec 1, a
	stda8 59836, a
	jr nz, SeqEvt_CheckExpiry_Return
	call NoteMap_FindBestMatch
	cp l, 0xFF
	jr z, SeqEvt_CheckExpiry_Return
	call VoiceEvent_DispatchTable

SeqEvt_CheckExpiry_Return:
	ret

SeqTiming_Snapshot:
	ei 6
	ldda16 xwa, 1120
	ldda8 l, 1122
	stda16 1118, xwa
	stda8 1117, l
	cpda16 xwa, 13170
	jr c, SeqTiming_Snapshot_CheckFrac
	stdi16 1120, 0

SeqTiming_Snapshot_CheckFrac:
	cpda8 l, 13174
	jr c, SeqTiming_Snapshot_PostSnap
	stdi8 1122, 0

SeqTiming_Snapshot_PostSnap:
	ei 0
	cpda16 xwa, 13170
	jr c, SeqTiming_Snapshot_CheckFracOverflow
	push xhl
	call AccTiming_InitAllParts
	xor wa, wa
	stda16 1118, xwa
	pop xhl

SeqTiming_Snapshot_CheckFracOverflow:
	cpda8 l, 13174
	jr c, SeqTiming_Snapshot_Return
	call AccTiming_MasterTick

SeqTiming_Snapshot_Return:
	ret

SyncTiming_Snapshot:
	ei 6
	ldda16 xwa, 1136
	ldda8 l, 1133
	stda16 1134, xwa
	stda8 1132, l
	cpda16 xwa, 32254
	jr c, SyncTiming_Snapshot_CheckFrac
	stdi16 1136, 0

SyncTiming_Snapshot_CheckFrac:
	cpda8 l, 32252
	jr c, SyncTiming_Snapshot_PostSnap
	stdi8 1133, 0

SyncTiming_Snapshot_PostSnap:
	ei 0
	cpda16 xwa, 32254
	jr c, SyncTiming_Snapshot_CheckFracOverflow
	push xhl
	call SeqEvt_EntryPoint2
	xor wa, wa
	stda16 1134, xwa
	pop xhl

SyncTiming_Snapshot_CheckFracOverflow:
	cpda8 l, 32252
	jr c, SyncTiming_Snapshot_Return
	call SeqEvt_EntryPoint1

SyncTiming_Snapshot_Return:
	ret

Seq_FullInit:
	ldb a, 0xFF
	stda8 1043, a
	stda8 1058, a
	stda8 1139, a
	call AudioMix_Init
	call SeqBuf_Init
	call TempoRingBuf_Init
	call SeqMain_InitBuffer
	call RhythmBuf_Init
	call SeqBuf_MidiOut_Init
	call SeqEvtBuf_Init
	call SeqBuf2_Init
	call AltEvtBuf_Init
	call SeqBuf_NoteEvent_Flush
	call SeqBuf_VoiceMap_Flush
	call SeqBuf_NoteEvent_InitBuffer
	call SeqBuf_SoundEdit_Flush
	call SeqBuf3_Init
	call SeqBuf_DspSysEx_InitBuffer
	stdi8 48953, 255
	ret

Seq_InitStub_Nop1:
	ret

Seq_InitStub_Nop2:
	ret

Seq_InitStub_Nop3:
	ret

AudioMix_Init:
	link32 0xEE, 0x0C, 0xF8, 0xFF
	xor xwa, xwa
	ld xwa, 0x5A5A5A5A
	ld (xiz - 8), xwa
	ld (xiz - 4), xwa
	lda xwa, (xiz - 8)
	push xwa
	lds bc, 0
	calr AudioMix_WriteChannelGroup
	pop xwa
	push xwa
	lds bc, 1
	calr AudioMix_WriteChannelGroup
	pop xwa
	push xwa
	lds bc, 2
	calr AudioMix_WriteChannelGroup
	pop xwa
	push xwa
	lds bc, 3
	calr AudioMix_WriteChannelGroup
	pop xwa
	ld xbc, 0x150000
	ld xwa, 0x101001F
	ldb d, 0x4

AudioMix_EnableChannels_Loop:
	ld w, a
	ld (xbc), xwa
	add a, 0x20
	djnz8 d, AudioMix_EnableChannels_Loop
	unlk32 xiz
	ret

AudioMix_WriteChannelGroup:
	pushw de
	sll a, 5
	set 4, a
	ld xhl, 0x150000
	ldb d, 0x8

AudioMix_WriteChannelGroup_Loop:
	ld (xhl), a
	ld_spib E, 0xE4
	ld (xhl + 2), e
	inc 1, a
	djnz8 d, AudioMix_WriteChannelGroup_Loop
	popw de
	ret

AudioMix_BytecodeData:
	push	xbc
	push	xde
	pushw 1
	calr	36
	ld	xbc, (xsp+10)
	ld	xde, xiz
	pushw 0
	calr	25
	ld	xbc, xwa
	ld	xde, xhl
	pushw 2
	calr	15
	ld	xbc, xix
	ld	xde, xiy
	pushw 3
	calr	5
	inc	8, xsp
	pop	xde
	pop	xbc
	ret
	push	xiy
	pushw	wa
	pushw	bc
	ld	a, (xsp+12)
	sll	a, 5
	set	4, a
	ld	xiy, 1376256
	ld	(xiy), a
	ld	(xiy+2), c
	inc	1, a
	ld	(xiy), a
	ld	(xiy+2), b
	inc	1, a
	ld	(xiy), a
	ld	bc, qbc
	ld	(xiy+2), c
	inc	1, a
	ld	(xiy), a
	ld	(xiy+2), b
	inc	1, a
	ld	(xiy), a
	ld	(xiy+2), e
	inc	1, a
	ld	(xiy), a
	ld	(xiy+2), d
	inc	1, a
	ld	(xiy), a
	ld	bc, qde
	ld	(xiy+2), c
	inc	1, a
	ld	(xiy), a
	ld	(xiy+2), b
	popw	bc
	popw	wa
	pop	xiy
	ret

; =============================================================================
; Copy_DE_words_from_XBC_to_XWA - Block memory copy (word-granularity)
;
; Copies DE 16-bit words from source to destination using LDIRW (block move).
; Used for blitting offscreen buffers to VRAM and general-purpose memory copy.
;
; Input:
;   XWA = destination address (24-bit)
;   XBC = source address (24-bit)
;   DE  = word count
;
; Example: Blit full screen (320x240 @ 8bpp = 38400 words):
;   XWA = 0x1A0000 (VRAM), XBC = 0x43C00 (offscreen), DE = 0x9600
; =============================================================================
Copy_DE_words_from_XBC_to_XWA:
	ld xix, xwa
	ld xiy, xbc
	ld bc, de
	ldirw
	ret

; =============================================================================
; Fill_memory_at_XWA_with_DE_words_of_BC_value - Block memory fill
;
; Fills memory with a repeating 16-bit pattern. Used for clearing VRAM or
; offscreen buffers to a solid color (duplicate color byte in both halves).
;
; Input:
;   XWA = destination address (24-bit, auto-increments via SFR post-increment)
;   XDE = word count (decrements to zero)
;   BC  = 16-bit fill pattern (e.g., color | (color << 8) for 8bpp)
; =============================================================================
Fill_memory_at_XWA_with_DE_words_of_BC_value:
	st_dpiw BC, 0xE1
	djnz xde, Fill_memory_at_XWA_with_DE_words_of_BC_value
	ret

Checksum_ComputeComplement:
	xor xhl, xhl
	extz xbc
	add xbc, xwa

Checksum_AccumulateLoop:
	add_spil XHL, 0xE2
	cp xwa, xbc
	jr lt, Checksum_AccumulateLoop
	cpl hl
	ret

TaskSched_ScreenGroupTable:
	.long Boot_InitPeripherals
	ldw	ix, 476
	nop
	nop
	.byte 0x88, 0x03, 0x00, 0x92, 0x2d, 0xf5, 0x00, 0x36, 0xe4, 0x01, 0x00
	nop
	.byte 0x88, 0x03, 0x00
	.long TaskSched_ScreenGroupTable_End
	.byte 0xb8, 0xe4, 0x01
	nop
	nop
	.byte 0x88, 0x01, 0x00, 0x6c, 0x80
	swi	1
	nop
	ldw	wa, 448
	nop
	nop
	.byte 0x88, 0x03, 0x00
	swi	2
	cp	(xde), xde
	nop
	ldw	de, 464
	nop
	nop
	.byte 0x88, 0x03, 0x00, 0x01, 0x01, 0x01, 0x01
	.fill 8, 1, 0x01
	.fill 8, 1, 0x01
	.byte 0x01, 0x01
TaskSched_ScreenGroupTable_End:
	.byte 0x68, 0xfe

INTT3_PriorityAdjust:
	bitda 0, 1158
	jr nz, INTT3_PriorityAdjust_Active
	ldb a, 0x5
	ldb c, 0x2
	jrl TaskSched_ChangePriority_Inline

INTT3_PriorityAdjust_Active:
	ldb a, 0x3
	calr TaskSched_YieldToQueue_NoBlock
	ldb a, 0x5
	ldb c, 0x3
	jrl TaskSched_ChangePriority_Inline
	ret

INTT3_HANDLER:
	incdi16 1, 1475
	incdi8 1, 1158
	pushw wa
	pushw bc
	calr INTT3_PriorityAdjust
	popw bc
	popw wa
	jrl INTT3_CheckNesting

TaskSched_Init:
	ld xsp, 0x1E53A
	xor wa, wa
	stda16 1159, xwa
	inc 1, wa
	ldc_cr16 wa, 0x7C
	stda16 1475, xwa
	ldw hl, 0x4C5
	extz xhl
	lds de, 4
	ldb b, 0x3

TaskSched_InitPriorityQueues:
	ld ix, hl
	st_dpiw IX, 0xED
	st_dpiw IX, 0xED
	djnz8 b, TaskSched_InitPriorityQueues
	ldw ix, 0x489
	extz xix
	ldb b, 0x5
	ldb a, 0x0

TaskSched_InitTCBFields:
	ld (xix + 9), a
	ld (xix + 10), 0x0
	ld (xix + 11), 0x0
	add ix, 0xC
	djnz8 b, TaskSched_InitTCBFields
	ldw ix, 0x5BB
	extz xix
	ldb b, 0x1
	ld xwa, 0xFFFFFFFF

TaskSched_InitTimerSlots:
	ld (xix + 4), xwa
	add ix, 0x8
	djnz8 b, TaskSched_InitTimerSlots
	ld xhl, 0xEF1933
	ldw de, 0x4F9
	extz xde
	ldw bc, 0xA
	ldir83
	ldw hl, 0x4D1
	extz xhl
	ldb b, 0xA

TaskSched_InitExtQueues:
	ld ix, hl
	st_dpiw IX, 0xED
	st_dpiw IX, 0xED
	djnz8 b, TaskSched_InitExtQueues
	ld xhl, 0xEF193D
	ldw de, 0x533
	extz xde
	ldw bc, 0xC
	ldir83
	ldw hl, 0x503
	extz xhl
	ldb b, 0xC

TaskSched_InitExtQueues2:
	ld ix, hl
	st_dpiw IX, 0xED
	st_dpiw IX, 0xED
	djnz8 b, TaskSched_InitExtQueues2
	ldw hl, 0x567
	extz xhl
	ldb b, 0xA
	ld xwa, 0xFFFFFFFF

TaskSched_InitFreeList:
	ld (xhl + 4), xwa
	add hl, 0x8
	djnz8 b, TaskSched_InitFreeList
	ldw iy, 0x5B7
	extz xiy
	ld (xiy + 256), iy
	ld (xiy + 2), iy
	ldw ix, 0x567
	ldb b, 0xA

TaskSched_LinkFreeSlots:
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	add ix, 0x8
	djnz8 b, TaskSched_LinkFreeSlots
	ldw hl, 0x53F
	extz xhl
	ldb b, 0x5

TaskSched_InitLockQueues:
	ld ix, hl
	st_dpiw IX, 0xED
	st_dpiw IX, 0xED
	djnz8 b, TaskSched_InitLockQueues
	ldw hl, 0x553
	extz xhl
	ldb b, 0x5

TaskSched_InitMsgQueues:
	ld ix, hl
	st_dpiw IX, 0xED
	st_dpiw IX, 0xED
	djnz8 b, TaskSched_InitMsgQueues
	ld xwa, 0xEF1A7E
	jr TaskSched_PostInit

	.byte 0x01
	nop
	.byte 0x01
	nop
	.byte 0x64, 0x19, 0xef, 0x00

TaskSched_PostInit:
	call TaskTimer_Register
	calr Stop_and_Clear_8bit_Timer_3
	ldio 0x8B, 0x07
	ld_sd8b A, 0xE5
	and a, 0xF
	or a, 0x20
	st_dd8b A, 0xE5
	calr Start_8bit_Timer_3
	ldb a, 0x1
	calr Show_ScreenGroup
	ei 6
	stdi8 1157, 0
	xor wa, wa
	ldc_cr16 wa, 0x7C
	stda16 1475, xwa
	jrl TaskSched_Dispatch

TaskSched_AllIdle:
	ei 0
	stdi8 305, 255

TaskSched_HaltLoop:
	jr TaskSched_HaltLoop

TaskSched_Dispatch:
	stdi8 305, 0
	ldda16 xwa, 1475
	or wa, wa
	jr nz, TaskSched_ReturnToDispatch
	xor wa, wa
	cpdm16 1159, xwa
	jr z, TaskSched_ScanPriorityQueues
	ldda16 xiy, 1159
	extz xiy
	ld (xiy + 4), xsp
	ld xsp, 0x1E53A
	xor wa, wa
	stda16 1159, xwa

TaskSched_ScanPriorityQueues:
	ldb b, 0x3
	ldw ix, 0x4C5
	extz xix

TaskSched_ScanQueue_Loop:
	ld hl, (xix + 256)
	cp hl, ix
	jr nz, TaskSched_FoundReadyTask
	inc 4, ix
	djnz8 b, TaskSched_ScanQueue_Loop
	jr TaskSched_AllIdle

TaskSched_FoundReadyTask:
	stda16 1159, xhl
	extz xhl
	ld a, (xhl + 11)
	sll a, 5
	stda8 305, a
	ld xsp, (xhl + 4)

TaskSched_ReturnToDispatch:
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xwa
	pop xhl
	pop_sr
	ret


TaskSched_TimerTick:
	ldda16 xwa, 1475
	inc 1, wa
	stda16 1475, xwa
	ldc_cr16 wa, 0x7C
	ei 0
	ldw ix, 0x5BB
	extz xix
	ldb b, 0x1

TaskSched_CheckTimerSlot:
	ld xwa, (xix + 4)
	cp xwa, 0xFFFFFFFF
	jr z, TaskSched_TimerSlot_Skip

	ld wa, (xix + 256)
	dec 1, wa
	ld (xix + 256), wa
	or wa, wa
	jr z, TaskSched_TimerSlot_Fire

TaskSched_TimerSlot_Skip:
	add ix, 0x8
	djnz8 b, TaskSched_CheckTimerSlot
	ei 6
	ldda16 xwa, 1475
	dec 1, wa
	stda16 1475, xwa
	ldc_cr16 wa, 0x7C
	ret

TaskSched_TimerSlot_Fire:
	ld wa, (xix + 2)
	ld (xix + 256), wa
	lda_24 xwa, 0xef1b47
	push xwa
	ld xwa, (xix + 4)
	jp (xwa)


INTT3_CheckNesting:
	pushw wa
	ldda16 xwa, 1475
	cps wa, 1
	jr z, INTT3_EnterScheduler
	dec 1, wa
	stda16 1475, xwa
	ldc_cr16 wa, 0x7C
	popw wa
	reti

INTT3_EnterScheduler:
	xor wa, wa
	stda16 1475, xwa
	ldc_cr16 wa, 0x7C
	popw wa
	ei 0
	nop
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	jrl TaskSched_Dispatch

; ===========================================================================
; Show_ScreenGroup - Display a screen group by ID
; ===========================================================================
; Entry: WA = Screen group ID
; Exit:  Screen group widgets have been initialized for display
; Notes: Sets up UI state structures and loads widget data from the
;        screen group table at 0xEF18EB (12 bytes per entry).
;        Screen Group 7 contains the error dialogs including
;        "ERROR in CPU data transmission".
;
; See also:
;   - ScreenGroup_Dispatch (ScreenGroup_DispatchAlt) - Alternative dispatcher
;   - ErrorDialog_CPUTransmissionError - Error dialog in Screen Group 7
; ===========================================================================
Show_ScreenGroup:
Show_ScreenGroup_Entry:
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld w, a
	ldb l, 0xC
	mul8rr l, a
	extz xhl
	add xhl, 0xEF18EB
	ldb c, 0xC
	mul8rr c, a
	add bc, 0x47D
	extz xbc
	ld xix, xbc
	ld a, (xix + 9)
	cps a, 0
	jrl nz, TaskSched_ReturnToDispatch
	ld (xix + 11), w
	ld xiy, (xhl + 4)
	sub xiy, 0x22
	ld wa, (xhl + 8)
	ld (xiy + 28), wa
	ld xwa, (xhl + 256)
	ld (xiy + 30), xwa
	ld (xix + 4), xiy
	ld a, (xhl + 10)
	ld (xix + 8), a
	ld (xix + 9), 0x4
	ld (xix + 10), 0x0
	ld a, (xhl + 10)
	sll a, 2
	extz wa
	add wa, 0x4C1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch
	ei 6
	ld xsp, 0x1E53A
	ldda16 xix, 1159
	extz xix
	ld (xix + 9), 0x0
	ld (xix + 10), 0x0
	xor wa, wa
	stda16 1159, xwa
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	jrl TaskSched_Dispatch

TaskSched_GetCurrentGroup:
	ldda16 xhl, 1475
	or hl, hl
	jr nz, TaskSched_GetCurrentGroup_Nested
	push xix
	ldda16 xix, 1159
	extz xix
	ld l, (xix + 11)
	extz hl
	pop xix
	ret

TaskSched_GetCurrentGroup_Nested:
	xor hl, hl
	ret

TaskSched_YieldToQueue:
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	sll a, 2
	extz wa
	add wa, 0x4C1
	ld iy, wa
	extz xiy
	ld ix, (xiy + 256)
	cp ix, (xiy + 2)
	jrl z, TaskSched_ReturnToDispatch
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch

TaskSched_YieldToQueue_NoBlock:
	push xwa
	push xix
	push xiy
	push xhl
	sll a, 2
	extz wa
	add wa, 0x4C1
	ld iy, wa
	extz xiy
	ld ix, (xiy + 256)
	cp ix, (xiy + 2)
	jr z, TaskSched_YieldToQueue_NoBlock_Return
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix

TaskSched_YieldToQueue_NoBlock_Return:
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

TaskSched_Resume:
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ldda16 xix, 1159
	extz xix
	ld a, (xix + 10)
	cps a, 0
	jr nz, TaskSched_Resume_DecrementWait
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x3
	jrl TaskSched_Dispatch

TaskSched_Resume_DecrementWait:
	dec 1, a
	ld (xix + 10), a
	jrl TaskSched_ReturnToDispatch

TaskSched_WakeBySlotID:
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	mul a, 0xC
	add wa, 0x47D
	ld ix, wa
	extz xix
	cp (xix + 9), 0x3
	jr nz, TaskSched_WakeBySlotID_Pending
	ld (xix + 9), 0x4
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4C1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch

TaskSched_WakeBySlotID_Pending:
	incm8 1, (xix + 10)
	jrl TaskSched_Dispatch
	push xwa
	push xix
	push xiy
	push_sr
	ei 6
	mul a, 0xC
	add wa, 0x47D
	ld ix, wa
	extz xix
	cp (xix + 9), 0x3
	jr nz, TaskSched_WakeInline_Pending
	ld (xix + 9), 0x4
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4C1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix

TaskSched_WakeInline_Return:
	pop_sr
	pop xiy
	pop xix
	pop xwa
	ret

TaskSched_WakeInline_Pending:
	incm8 1, (xix + 10)
	jr TaskSched_WakeInline_Return
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	mul a, 0xC
	add wa, 0x47D
	ld ix, wa
	extz xix
	ld l, (xix + 10)
	ld (xix + 10), 0x0
	jrl TaskSched_ReturnToDispatch

TaskSched_SignalEvent:
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld l, a
	sll a, 2
	extz wa
	add wa, 0x4CD
	ld iy, wa
	extz xiy
	ld ix, (xiy + 256)
	cp ix, iy
	jr nz, TaskSched_SignalEvent_Unlink
	extz hl
	add hl, 0x4F8
	extz xhl
	setm 0, (xhl)
	jrl TaskSched_ReturnToDispatch

TaskSched_SignalEvent_Unlink:
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x4
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4C1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch

TaskSched_SignalEvent_NoBlock:
	push xwa
	push xix
	push xiy
	push xhl
	ld l, a
	sll a, 2
	extz wa
	add wa, 0x4CD
	ld iy, wa
	extz xiy
	push_sr
	ei 6
	ld ix, (xiy + 256)
	cp ix, iy
	jr nz, TaskSched_SignalEvent_NoBlock_Unlink
	extz hl
	add hl, 0x4F8
	extz xhl
	setm 0, (xhl)
	pop_sr
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

TaskSched_SignalEvent_NoBlock_Unlink:
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x4
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4C1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	pop_sr
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

TaskSched_WaitForEvent:
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld e, a
	extz wa
	add wa, 0x4F8
	extz xwa
	bitm 0, (xwa)
	jr z, TaskSched_WaitForEvent_Block
	resm 0, (xwa)
	jrl TaskSched_ReturnToDispatch

TaskSched_WaitForEvent_Block:
	ldda16 xix, 1159
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x3
	sll e, 2
	extz de
	add de, 0x4CD
	ld iy, de
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch
	extz wa
	add wa, 0x4F8
	extz xwa
	push_sr
	ei 6
	resm 0, (xwa)
	pop_sr
	ret

; ===========================================================================
; Audio_Lock_Release - Release inter-CPU communication lock
; ===========================================================================
; Entry: A = lock index (0-7)
; Exit:  Lock released, next waiting request (if any) is signaled
; Notes: Increments counter at (0x0532 + lock_index)
;        Processes linked list at 0x0487 to wake waiting tasks
;        Must be paired with Audio_Lock_Acquire
; ===========================================================================
Audio_Lock_Release:
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld l, a
	sll a, 2
	extz wa
	add wa, 0x4FF
	ld iy, wa
	extz xiy
	ld ix, (xiy + 256)
	cp ix, iy
	jr nz, AudioLock_Release_WakeWaiter
	extz hl
	add hl, 0x532
	extz xhl
	ld a, (xhl)
	inc 1, a
	jr z, AudioLock_Release_NoWaiter_Done
	ld (xhl), a

AudioLock_Release_NoWaiter_Done:
	jrl TaskSched_ReturnToDispatch

AudioLock_Release_WakeWaiter:
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x4
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4C1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch
	push xwa
	push xix
	push xiy
	push xhl
	ld l, a
	sll a, 2
	extz wa
	add wa, 0x4FF
	ld iy, wa
	extz xiy
	push_sr
	ei 6
	ld ix, (xiy + 256)
	cp ix, iy
	jr nz, AudioLock_Release_NB_WakeWaiter
	extz hl
	add hl, 0x532
	extz xhl
	ld a, (xhl)
	inc 1, a
	jr z, AudioLock_Release_NB_Saturated
	ld (xhl), a

AudioLock_Release_NB_Saturated:
	pop_sr
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

AudioLock_Release_NB_WakeWaiter:
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x4
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4C1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	pop_sr
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

; ===========================================================================
; Audio_Lock_Acquire - Acquire inter-CPU communication lock
; ===========================================================================
; Entry: A = lock index (0-7)
; Exit:  Lock acquired, safe to send audio commands
; Notes: Decrements counter at (0x0532 + lock_index)
;        If counter is zero, adds request to linked list at 0x0487 and waits
;        Must be paired with Audio_Lock_Release after sending commands
;        Used by audio subsystem to serialize access to Sub-CPU communication
; ===========================================================================
Audio_Lock_Acquire:
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld e, a
	extz wa
	add wa, 0x532
	extz xwa
	cp (xwa), 0x0
	jr z, AudioLock_Acquire_Block
	decm8 1, (xwa)
	jrl TaskSched_ReturnToDispatch

AudioLock_Acquire_Block:
	ldda16 xix, 1159
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x3
	sll e, 2
	extz de
	add de, 0x4FF
	ld iy, de
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch

AudioLock_TryAcquire:
	extz wa
	add wa, 0x532
	extz xwa
	push_sr
	ei 6
	cp (xwa), 0x0
	jr z, AudioLock_TryAcquire_Fail
	decm8 1, (xwa)
	xor hl, hl
	jr AudioLock_TryAcquire_Return

AudioLock_TryAcquire_Fail:
	ldw hl, 0xFFFF

AudioLock_TryAcquire_Return:
	pop_sr
	ret

AudioLock_GetCount:
	extz wa
	add wa, 0x532
	extz xwa
	ld l, (xwa)
	extz hl
	ret

TaskMsg_Send:
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld xiz, xbc
	sll a, 2
	ld c, a
	extz wa
	add wa, 0x53B
	ld iy, wa
	extz xiy
	ld ix, (xiy + 256)
	cp ix, iy
	jr nz, TaskMsg_Send_WakeReceiver
	ldda16 xix, 1463
	extz xix
	ld iy, (xix + 256)
	cp iy, ix
	jrl z, TaskMsg_Send_QueueFull
	ldw (xsp + 24), 0x0
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 4), xiz
	extz bc
	add bc, 0x54F
	ld iy, bc
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_ReturnToDispatch

TaskMsg_Send_QueueFull:
	ldw (xsp + 24), 0xFFFF
	jrl TaskSched_ReturnToDispatch

TaskMsg_Send_WakeReceiver:
	ldw (xsp + 24), 0x0
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x4
	ld xwa, (xix + 4)
	ld (xwa + 24), xiz
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4C1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch
	push xwa
	push xix
	push xiy
	push xiz
	push xhl
	push xbc
	ld xiz, xbc
	sll a, 2
	ld c, a
	extz wa
	add wa, 0x53B
	ld iy, wa
	extz xiy
	push_sr
	ei 6
	ld ix, (xiy + 256)
	cp ix, iy
	jr nz, TaskMsg_Send_NB_WakeReceiver
	ldda16 xix, 1463
	extz xix
	ld iy, (xix + 256)
	cp iy, ix
	jrl z, TaskMsg_Send_NB_QueueFull
	ldw (xsp + 4), 0x0
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 4), xiz
	extz bc
	add bc, 0x54F
	ld iy, bc
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix

TaskMsg_Send_NB_Return:
	pop_sr
	pop xbc
	pop xhl
	pop xiz
	pop xiy
	pop xix
	pop xwa
	ret

TaskMsg_Send_NB_QueueFull:
	ldw (xsp + 4), 0xFFFF
	jr TaskMsg_Send_NB_Return

TaskMsg_Send_NB_WakeReceiver:
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x4
	ld xwa, (xix + 4)
	ld (xwa + 24), xiz
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4C1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	pop_sr
	pop xbc
	pop xhl
	pop xiz
	pop xiy
	pop xix
	pop xwa
	ret

TaskMsg_Receive:
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	sll a, 2
	extz wa
	ld de, wa
	add wa, 0x54F
	ld iy, wa
	extz xiy
	ld ix, (xiy + 256)
	cp ix, iy
	jr z, TaskMsg_Receive_Block
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld xiz, (xix + 4)
	ld xbc, 0xFFFFFFFF
	ld (xix + 4), xbc
	ldw iy, 0x5B7
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	ld (xsp + 24), xiz
	jrl TaskSched_ReturnToDispatch

TaskMsg_Receive_Block:
	ldda16 xix, 1159
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x3
	add de, 0x53B
	ld iy, de
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch

TaskMsg_TryReceive:
	push xix
	push xiz
	sll a, 2
	extz wa
	add wa, 0x54F
	ld iy, wa
	push_sr
	ei 6
	extz xiy
	ld ix, (xiy + 256)
	cp ix, iy
	jr z, TaskMsg_TryReceive_Empty
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld xiz, (xix + 4)
	ld xwa, 0xFFFFFFFF
	ld (xix + 4), xwa
	ldw iy, 0x5B7
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	ld xhl, xiz
	jr TaskMsg_TryReceive_Return

TaskMsg_TryReceive_Empty:
	xor xhl, xhl

TaskMsg_TryReceive_Return:
	pop_sr
	pop xiz
	pop xix
	ret

TaskTimer_Register:
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld xix, xwa
	ld a, (xix + 256)
	mul a, 0x8
	add wa, 0x5B3
	ld iy, wa
	extz xiy
	ld wa, (xix + 2)
	ld (xiy + 256), wa
	ld (xiy + 2), wa
	ld xwa, (xix + 4)
	ld (xiy + 4), xwa
	jrl TaskSched_Dispatch

TaskSched_ChangePriority:
	push_sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld e, c
	mul a, 0xC
	add wa, 0x47D
	ld ix, wa
	extz xix
	cp (xix + 9), 0x4
	jr nz, TaskSched_ChangePriority_NotReady
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 8), e
	sll e, 2
	extz de
	add de, 0x4C1
	ld iy, de
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch

TaskSched_ChangePriority_NotReady:
	ld (xix + 8), e
	jrl TaskSched_ReturnToDispatch

TaskSched_ChangePriority_Inline:
	push xwa
	push xix
	push xiy
	push xhl
	pushw de
	ld e, c
	mul a, 0xC
	add wa, 0x47D
	ld ix, wa
	extz xix
	push_sr
	ei 6
	cp (xix + 9), 0x4
	jr nz, TaskSched_ChangePriority_Inline_NotReady
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 8), e
	sll e, 2
	extz de
	add de, 0x4C1
	ld iy, de
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jr TaskSched_ChangePriority_Inline_Return

TaskSched_ChangePriority_Inline_NotReady:
	ld (xix + 8), e

TaskSched_ChangePriority_Inline_Return:
	pop_sr
	popw de
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

TaskSched_TCBTemplate:	.ascii "(<=;"
	ei	0x06
	mul	a, 12
	add	wa, 1149
	ld	ix, wa
	extz	xix
	xor	xwa, xwa
	xor	xhl, xhl
	.byte 0x9c, 0x00, 0x20
	ld	hl, (xix+2)
	.byte 0xbb, 0x00, 0x50
	ld	(xwa+2), hl
	ld	(xix+9), 0
	ld	(xix+10), 0
	ei	0x00
	pop	xhl
	pop	xiy
	pop	xix
	popw	wa
	ret

TaskSched_DelayTicks:
	srl wa, 1
	addda16 xwa, 1033

TaskSched_DelayTicks_SpinLoop:
	cpda16 xwa, 1033
	jr gt, TaskSched_DelayTicks_SpinLoop
	ret

Start_8bit_Timer_3:
	set_dd8 3, 0x80
	ret

Stop_and_Clear_8bit_Timer_3:
	res_dd8 3, 0x80
	ret

SeqBuf_BytecodeSnippet:
	incdi16	1, 1475
	ret
	.byte 0xd1, 0xc3, 0x05
	jr	ge, 0x0e

SeqBuf_ReadByte:
	pushw ix
	push xde
	lda_24 xde, 0x01e549
	calr RingBuf_CheckFull_512
	pop xde
	popw ix
	ret

SeqBuf_WriteByte:
	link32 0xEE, 0x0C, 0x00, 0x00
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda_24 xde, 0x01e549
	calr Seq_RingBuf_WriteByte_512
	pop xde
	popw ix
	unlk32 xiz
	ret

SeqBuf_WriteBytes:
	link32 0xEE, 0x0C, 0x00, 0x00
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda_24 xde, 0x01e549

SeqBuf_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_512
	inc 1, xiy
	djnz xbc, SeqBuf_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk32 xiz
	ret

SeqBuf_InlineBytecode:
	ld16_24	hl, 124229
	cpda16_24	hl, 124225
	lds	hl, 0
	jr	z, 3
	ldw	hl, 65535
	ret

SeqBuf_GetWritePos:
	ld16_24 xhl, 0x01e547
	ret

SeqBuf_Init:
	pushw ix
	push xde
	lda_24 xde, 0x01e549
	call Seq_RingBuf_Init_512
	pop xde
	popw ix
	ret

SeqBuf_SaveReadPos:
	pushw hl
	ld16_24 xhl, 0x01e541
	st16_24 0x01e53f, xhl
	popw hl
	ret

SeqBuf_ReadAlternate:
	pushw ix
	push xde
	lda_24 xde, 0x01e549
	call RingBuf_CheckFull_256
	pop xde
	popw ix
	ret

SeqBuf_ReadAlternate2:
	pushw	ix
	push	xde
	lda_24	xde, 124233
	call	15675467
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 124227
	st16_24	124225, hl
	popw	hl
	ret

SeqBuf_SaveWritePos:
	pushw hl
	ld16_24 xhl, 0x01e545
	st16_24 0x01e543, xhl
	popw hl
	ret

TempoRingBuf_ReadByte:
	pushw ix
	push xde
	lda_24 xde, 0x01e753
	calr Seq_RingBuf_PeekByte
	pop xde
	popw ix
	ret

TempoRingBuf_WriteByte_Ext:
	link32 0xEE, 0x0C, 0x00, 0x00
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda_24 xde, 0x01e753
	calr Seq_RingBuf_WriteByte_Check
	pop xde
	popw ix
	unlk32 xiz
	ret

TempoRingBuf_WriteBytes:
	link32 0xEE, 0x0C, 0x00, 0x00
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda_24 xde, 0x01e753

TempoRingBuf_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_Check
	inc 1, xiy
	djnz xbc, TempoRingBuf_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk32 xiz
	ret

TempoRingBuf_CheckEmpty:
	ld16_24 xhl, 0x01e74f
	cpda16_24 xhl, 124747
	lds hl, 0
	jr z, TempoRingBuf_CheckEmpty_Return
	ldw hl, 0xFFFF

TempoRingBuf_CheckEmpty_Return:
	ret

TempoRingBuf_BytecodeSnippet2:
	ld16_24	hl, 124753
	ret

TempoRingBuf_Init:
	pushw ix
	push xde
	lda_24 xde, 0x01e753
	call Seq_RingBuf_Init_2048
	pop xde
	popw ix
	ret

TempoRingBuf_SaveReadPos:
	pushw hl
	ld16_24 xhl, 0x01e74b
	st16_24 0x01e749, xhl
	popw hl
	ret

TempoRingBuf_InlineBytecode2:
	pushw	ix
	push	xde
	lda_24	xde, 124755
	call	15675726
	pop	xde
	popw	ix
	ret

TempoRingBuf_ReadAlternate:
	pushw ix
	push xde
	lda_24 xde, 0x01e753
	call Seq_RingBuf_ReadAhead
	pop xde
	popw ix
	ret

TempoRingBuf_SaveWritePos:
	pushw	hl
	ld16_24	hl, 124749
	st16_24	124747, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 124751
	st16_24	124749, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 126813
	calr	2738
	pop	xde
	popw	ix
	ret

RhythmBuf_WriteByte:
	link32 0xEE, 0x0C, 0x00, 0x00
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda_24 xde, 0x01ef5d
	calr Seq_RingBuf_WriteByte_512
	pop xde
	popw ix
	unlk32 xiz
	ret

RhythmBuf_InlineBytecode:
	link	xiz, 0
	push	xiy
	push	xix
	push	xde
	ld	bc, (xiz+8)
	ld	xiy, (xiz+10)
	lda_24	xde, 126813
	ld	a, (xiy)
	calr	2774
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret

RhythmBuf_CheckEmpty:
	ld16_24 xhl, 0x01ef59
	cpda16_24 xhl, 126805
	lds hl, 0
	jr z, RhythmBuf_CheckEmpty_Return
	ldw hl, 0xFFFF

RhythmBuf_CheckEmpty_Return:
	ret

RhythmBuf_BytecodeSnippet:
	ld16_24	hl, 126811
	ret

RhythmBuf_Init:
	pushw ix
	push xde
	lda_24 xde, 0x01ef5d
	call Seq_RingBuf_Init_512
	pop xde
	popw ix
	ret

RhythmBuf_SaveWritePos:
	pushw hl
	ld16_24 xhl, 0x01ef55
	st16_24 0x01ef53, xhl
	popw hl
	ret

RhythmBuf_ReadAlternate:
	pushw ix
	push xde
	lda_24 xde, 0x01ef5d
	call RingBuf_CheckFull_256
	pop xde
	popw ix
	ret

RhythmBuf_InlineBytecode2:
	pushw	ix
	push	xde
	lda_24	xde, 126813
	call	15675467
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 126807
	st16_24	126805, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 126809
	st16_24	126807, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 127335
	calr	2421
	pop	xde
	popw	ix
	ret
	link	xiz, 0
	pushw	ix
	push	xde
	ld	a, (xiz+8)
	lda_24	xde, 127335
	calr	2485
	pop	xde
	popw	ix
	unlk	xiz
	ret

AltEvtBuf_WriteBytes:
	link32 0xEE, 0x0C, 0x00, 0x00
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda_24 xde, 0x01f167

AltEvtBuf_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_Small
	inc 1, xiy
	djnz xbc, AltEvtBuf_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk32 xiz
	ret

AltEvtBuf_InlineBytecode:
	ld16_24	hl, 127331
	cpda16_24	hl, 127327
	lds	hl, 0
	jr	z, 3
	ldw	hl, 65535
	ret
	ld16_24	hl, 127333
	ret

AltEvtBuf_Init:
	pushw ix
	push xde
	lda_24 xde, 0x01f167
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret

AltEvtBuf_Helpers:
	pushw	hl
	ld16_24	hl, 127327
	st16_24	127325, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 127335
	call	15675297
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 127335
	call	15675324
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 127329
	st16_24	127327, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 127331
	st16_24	127329, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 127601
	calr	2247
	pop	xde
	popw	ix
	ret

SeqEvtBuf_WriteByte:
	link32 0xEE, 0x0C, 0x00, 0x00
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda_24 xde, 0x01f271
	calr Seq_RingBuf_WriteByte_Small
	pop xde
	popw ix
	unlk32 xiz
	ret

SeqEvtBuf_InlineBytecode:
	link	xiz, 0
	push	xiy
	push	xix
	push	xde
	ld	bc, (xiz+8)
	ld	xiy, (xiz+10)
	lda_24	xde, 127601
	ld	a, (xiy)
	calr	2283
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld16_24	hl, 127597
	cpda16_24	hl, 127593
	lds	hl, 0
	jr	z, 3
	ldw	hl, 65535
	ret
	.byte 0xd2, 0x6f, 0xf2, 0x01
	ldb	c, 0x0e

SeqEvtBuf_Init:
	pushw ix
	push xde
	lda_24 xde, 0x01f271
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret

SeqEvtBuf_SaveReadPos:
	pushw hl
	ld16_24 xhl, 0x01f269
	st16_24 0x01f267, xhl
	popw hl
	ret

SeqEvtBuf_ReadAlternate:
	pushw ix
	push xde
	lda_24 xde, 0x01f271
	call Seq_RingBuf_ReadByte_Large
	pop xde
	popw ix
	ret

SeqEvtBuf_ReadAlternate2:
	; --- Sub 1: call EF2FBC with XDE=0x01F271 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 127601
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret
SeqEvtBuf_SaveReadPos2:
	; --- Sub 2: copy (0x01F26B)->HL->(0x01F269) (13 bytes) ---
	pushw hl
	ld16_24	hl, 127595
	st16_24	127593, hl
	popw hl
	ret
SeqEvtBuf_SaveReadPos3:
	; --- Sub 3: copy (0x01F26D)->HL->(0x01F26B) (13 bytes) ---
	pushw hl
	ld16_24	hl, 127597
	st16_24	127595, hl
	popw hl
	ret
SeqMain_ReadByte_1024:
	; --- Sub 4: calr EF30A1 with XDE=0x01F37B (13 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 127867
	calr Seq_RingBuf_Dequeue_1024
	pop xde
	popw ix
	ret


SeqMain_WriteByte:
	link32 0xEE, 0x0C, 0x00, 0x00
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda_24 xde, 0x01f37b
	calr Seq_RingBuf_WriteByte
	pop xde
	popw ix
	unlk32 xiz
	ret

SeqMain_WriteBytes:
	link32 0xEE, 0x0C, 0x00, 0x00
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda_24 xde, 0x01f37b

SeqMain_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte
	inc 1, xiy
	djnz xbc, SeqMain_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk32 xiz
	ret

Seq_CheckSongEnd:
	ld16_24 xhl, 0x01f377
	cpda16_24 xhl, 127859
	lds hl, 0
	jr z, Seq_CheckSongEnd_Return
	ldw hl, 0xFFFF

Seq_CheckSongEnd_Return:
	ret

SeqMain_GetTimingValue:
	ld16_24 xhl, 0x01f379
	ret

SeqMain_InitBuffer:
	pushw ix
	push xde
	lda_24 xde, 0x01f37b
	call Seq_RingBuf_Init_1024
	pop xde
	popw ix
	ret

SeqMain_SaveWritePos:
	pushw hl
	ld16_24 xhl, 0x01f373
	st16_24 0x01f371, xhl
	popw hl
	ret

SeqMain_ReadData:
	pushw ix
	push xde
	lda_24 xde, 0x01f37b
	call Seq_RingBuf_ReadData
	pop xde
	popw ix
	ret

SeqMain_ReadAlternate:
	pushw	ix
	push	xde
	lda_24	xde, 127867
	call	15675610
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 127861
	st16_24	127859, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 127863
	st16_24	127861, hl
	popw	hl
	ret

SeqBuf_MidiOut_ReadByte:
	pushw ix
	push xde
	lda_24 xde, 0x01f785
	calr Seq_RingBuf_ReadByte
	pop xde
	popw ix
	ret

SeqBuf_MidiOut_WriteByte:
	link32 0xEE, 0x0C, 0x00, 0x00
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda_24 xde, 0x01f785
	calr Seq_RingBuf_WriteByte_Small
	pop xde
	popw ix
	unlk32 xiz
	ret

SeqBuf_MidiOut_WriteBytes:
	link32 0xEE, 0x0C, 0x00, 0x00
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda_24 xde, 0x01f785

SeqBuf_MidiOut_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_Small
	inc 1, xiy
	djnz xbc, SeqBuf_MidiOut_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk32 xiz
	ret

SeqBuf_MidiOut_CheckEmpty:
	ld16_24 xhl, 0x01f781
	cpda16_24 xhl, 128893
	lds hl, 0
	jr z, SeqBuf_MidiOut_CheckEmpty_Return
	ldw hl, 0xFFFF

SeqBuf_MidiOut_CheckEmpty_Return:
	ret

SeqBuf_MidiOut_GetTimingValue:
	ld16_24 xhl, 0x01f783
	ret

SeqBuf_MidiOut_Init:
	pushw ix
	push xde
	lda_24 xde, 0x01f785
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret

SeqBuf_MidiOut_SaveReadPos:
	; --- Sub 1: copy (0x01F77D)->HL->(0x01F77B) (13 bytes) ---
	pushw hl
	ld16_24	hl, 128893
	st16_24	128891, hl
	popw hl
	ret
SeqBuf_MidiOut_ReadAlternate:
	; --- Sub 2: call EF2FA1 with XDE=0x01F785 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 128901
	call Seq_RingBuf_ReadByte_Large
	pop xde
	popw ix
	ret
SeqBuf_MidiOut_ReadAlternate2:
	; --- Sub 3: call EF2FBC with XDE=0x01F785 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 128901
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret
SeqBuf_MidiOut_SaveReadPos2:
	; --- Sub 4: copy (0x01F77F)->HL->(0x01F77D) (13 bytes) ---
	pushw hl
	ld16_24	hl, 128895
	st16_24	128893, hl
	popw hl
	ret
SeqBuf_MidiOut_SaveReadPos3:
	; --- Sub 5: copy (0x01F781)->HL->(0x01F77F) (13 bytes) ---
	pushw hl
	ld16_24	hl, 128897
	st16_24	128895, hl
	popw hl
	ret


SeqBuf2_ReadByte:
	pushw ix
	push xde
	lda_24 xde, 0x01f88f
	calr RingBuf_CheckFull_512
	pop xde
	popw ix
	ret

SeqBuf2_WriteByte:
	link32 0xEE, 0x0C, 0x00, 0x00
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda_24 xde, 0x01f88f
	calr Seq_RingBuf_WriteByte_512
	pop xde
	popw ix
	unlk32 xiz
	ret

SeqBuf2_WriteBytes:
	link32 0xEE, 0x0C, 0x00, 0x00
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda_24 xde, 0x01f88f

SeqBuf2_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_512
	inc 1, xiy
	djnz xbc, SeqBuf2_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk32 xiz
	ret

SeqBuf2_InlineBytecode:
	ld16_24	hl, 129163
	cpda16_24	hl, 129159
	lds	hl, 0
	jr	z, 3
	ldw	hl, 65535
	ret
	ld16_24	hl, 129165
	ret

SeqBuf2_Init:
	pushw ix
	push xde
	lda_24 xde, 0x01f88f
	call Seq_RingBuf_Init_512
	pop xde
	popw ix
	ret

SeqBuf2_SaveReadPos:
	; --- Sub 1: copy (0x01F887)->HL->(0x01F885) (13 bytes) ---
	pushw hl
	ld16_24	hl, 129159
	st16_24	129157, hl
	popw hl
	ret
SeqBuf2_ReadAlternate:
	; --- Sub 2: call EF3030 with XDE=0x01F88F (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 129167
	call RingBuf_CheckFull_256
	pop xde
	popw ix
	ret
SeqBuf2_ReadAlternate2:
	; --- Sub 3: call EF304B with XDE=0x01F88F (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 129167
	call RingBuf512_ReadAlt_ByteBlock
	pop xde
	popw ix
	ret
SeqBuf2_SaveReadPos2:
	; --- Sub 4: copy (0x01F889)->HL->(0x01F887) (13 bytes) ---
	pushw hl
	ld16_24	hl, 129161
	st16_24	129159, hl
	popw hl
	ret
SeqBuf2_SaveReadPos3:
	; --- Sub 5: copy (0x01F88B)->HL->(0x01F889) (13 bytes) ---
	pushw hl
	ld16_24	hl, 129163
	st16_24	129161, hl
	popw hl
	ret


SeqBuf3_ReadByte:
	pushw ix
	push xde
	lda_24 xde, 0x01fa99
	calr RingBuf_CheckFull_512
	pop xde
	popw ix
	ret

SeqBuf3_WriteByte:
	link32 0xEE, 0x0C, 0x00, 0x00
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda_24 xde, 0x01fa99
	calr Seq_RingBuf_WriteByte_512
	pop xde
	popw ix
	unlk32 xiz
	ret

SeqBuf3_WriteBytes:
	link32 0xEE, 0x0C, 0x00, 0x00
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda_24 xde, 0x01fa99

SeqBuf3_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_512
	inc 1, xiy
	djnz xbc, SeqBuf3_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk32 xiz
	ret

SeqBuf3_InlineBytecode:
	ld16_24	hl, 129685
	cpda16_24	hl, 129681
	lds	hl, 0
	jr	z, 3
	ldw	hl, 65535
	ret

SeqBuf3_GetTimingValue:
	ld16_24 xhl, 0x01fa97
	ret

SeqBuf3_Init:
	pushw ix
	push xde
	lda_24 xde, 0x01fa99
	call Seq_RingBuf_Init_512
	pop xde
	popw ix
	ret

SeqBuf3_Helpers:
	pushw	hl
	ld16_24	hl, 129681
	st16_24	129679, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 129689
	call	15675440
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 129689
	call	15675467
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 129683
	st16_24	129681, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 129685
	st16_24	129683, hl
	popw	hl
	ret

SeqBuf_DspSysEx_ReadByte:
	pushw ix
	push xde
	lda_24 xde, 0x01fca3
	calr Seq_RingBuf_Dequeue_1024
	pop xde
	popw ix
	ret


SeqBuf_DspSysEx_WriteByte:
	link32 0xEE, 0x0C, 0x00, 0x00
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda_24 xde, 0x01fca3
	calr Seq_RingBuf_WriteByte
	pop xde
	popw ix
	unlk32 xiz
	ret

SeqBuf_DspSysEx_WriteBytes:
	link32 0xEE, 0x0C, 0x00, 0x00
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda_24 xde, 0x01fca3

SeqBuf_DspSysEx_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte
	inc 1, xiy
	djnz xbc, SeqBuf_DspSysEx_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk32 xiz
	ret


SeqBuf_DspSysEx_CheckSongEnd:
	ld16_24 xhl, 0x01fc9f
	cpda16_24 xhl, 130203
	lds hl, 0
	jr z, SeqBuf_DspSysEx_CheckSongEnd_Return
	ldw hl, 0xFFFF

SeqBuf_DspSysEx_CheckSongEnd_Return:
	ret

SeqBuf_DspSysEx_OrphanData:
	ld16_24	hl, 130209
	ret

SeqBuf_DspSysEx_InitBuffer:
	pushw ix
	push xde
	lda_24 xde, 0x01fca3
	call Seq_RingBuf_Init_1024
	pop xde
	popw ix
	ret

SeqBuf_DspSysEx_CopyPointers:
	pushw	hl
	ld16_24	hl, 130203
	st16_24	130201, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 130211
	call	15675583
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 130211
	call	15675610
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 130205
	st16_24	130203, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 130207
	st16_24	130205, hl
	popw	hl
	ret


Seq_DataHandler:
	pushw ix
	push xde
	lda_24 xde, 0x0200ad
	calr RingBuf128_CheckEmpty
	pop xde
	popw ix
	ret


SeqBuf_TimerEvent_BytecodeBlock:
	link	xiz, 0
	pushw	ix
	push	xde
	ld	a, (xiz+8)
	lda_24	xde, 131245
	calr	1124
	pop	xde
	popw	ix
	unlk	xiz
	ret
	link	xiz, 0
	push	xiy
	push	xix
	push	xde
	ld	bc, (xiz+8)
	ld	xiy, (xiz+10)
	lda_24	xde, 131245
	ld	a, (xiy)
	calr	1096
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld16_24	hl, 131241
	cpda16_24	hl, 131237
	lds	hl, 0
	jr	z, 3
	ldw	hl, 65535
	ret
	ld16_24	hl, 131243
	ret
	pushw	ix
	push	xde
	lda_24	xde, 131245
	call	15675098
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 131237
	st16_24	131235, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 131245
	call	15675154
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 131245
	call	15675181
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 131239
	st16_24	131237, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 131241
	st16_24	131239, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 131383
	calr	886
	pop	xde
	popw	ix
	ret


Seq_TimerEventLoop:
	link32 0xEE, 0x0C, 0x00, 0x00
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda_24 xde, 0x020137
	calr RingBuf128_WriteByte_CheckFull
	pop xde
	popw ix
	unlk32 xiz
	ret


SeqBuf_TimerEvent_BytecodeBlock2:
	link	xiz, 0
	push	xiy
	push	xix
	push	xde
	ld	bc, (xiz+8)
	ld	xiy, (xiz+10)
	lda_24	xde, 131383
	ld	a, (xiy)
	calr	922
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld16_24	hl, 131379
	cpda16_24	hl, 131375
	lds	hl, 0
	jr	z, 3
	ldw	hl, 65535
	ret
	ld16_24	hl, 131381
	ret
	pushw	ix
	push	xde
	lda_24	xde, 131383
	call	15675098
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 131375
	st16_24	131373, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 131383
	call	15675154
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 131383
	call	15675181
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 131377
	st16_24	131375, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 131379
	st16_24	131377, hl
	popw	hl
	ret


SeqBuf_VoiceMap_ReadByte:
	pushw ix
	push xde
	lda_24 xde, 0x0201c1
	calr Seq_RingBuf_ReadByte
	pop xde
	popw ix
	ret


SeqBuf_VoiceMap_WriteByte:
	link32 0xEE, 0x0C, 0x00, 0x00
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda_24 xde, 0x0201c1
	calr Seq_RingBuf_WriteByte_Small
	pop xde
	popw ix
	unlk32 xiz
	ret


SeqBuf_VoiceMap_WriteBlock:
	link32 0xEE, 0x0C, 0x00, 0x00
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda_24 xde, 0x0201c1

SeqBuf_VoiceMap_WriteBlock_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_Small
	inc 1, xiy
	djnz xbc, SeqBuf_VoiceMap_WriteBlock_Loop
	pop xde
	pop xix
	pop xiy
	unlk32 xiz
	ret

SeqBuf_VoiceMap_CheckEmpty:
	ld16_24 xhl, 0x0201bd
	cpda16_24 xhl, 131513
	lds hl, 0
	jr z, SeqBuf_VoiceMap_CheckEmpty_Done
	ldw hl, 0xFFFF

SeqBuf_VoiceMap_CheckEmpty_Done:
	ret


SeqBuf_VoiceMap_GetWritePos:
	ld16_24 xhl, 0x0201bf
	ret


SeqBuf_VoiceMap_Flush:
	pushw ix
	push xde
	lda_24 xde, 0x0201c1
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret

SeqBuf_VoiceMap_SaveWritePtr:
	; --- Sub 1: copy (0x0201B9)->HL->(0x0201B7) (13 bytes) ---
	pushw hl
	ld16_24	hl, 131513
	st16_24	131511, hl
	popw hl
	ret
SeqBuf_VoiceMap_CommitWrite:
	; --- Sub 2: call EF2FA1 with XDE=0x0201C1 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 131521
	call Seq_RingBuf_ReadByte_Large
	pop xde
	popw ix
	ret
SeqBuf_VoiceMap_RollbackWrite:
	; --- Sub 3: call EF2FBC with XDE=0x0201C1 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 131521
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret
SeqBuf_VoiceMap_SaveReadPtr:
	; --- Sub 4: copy (0x0201BB)->HL->(0x0201B9) (13 bytes) ---
	pushw hl
	ld16_24	hl, 131515
	st16_24	131513, hl
	popw hl
	ret
SeqBuf_VoiceMap_AdvanceCheckpoint:
	; --- Sub 5: copy (0x0201BD)->HL->(0x0201BB) (13 bytes) ---
	pushw hl
	ld16_24	hl, 131517
	st16_24	131515, hl
	popw hl
	ret


SeqBuf_NoteEvent_ReadByte:
	pushw ix
	push xde
	lda_24 xde, 0x0202cb
	calr Seq_RingBuf_ReadByte
	pop xde
	popw ix
	ret

SeqBuf_NoteEvent_WriteByte_Data:
	link	xiz, 0
	pushw	ix
	push	xde
	ld	a, (xiz+8)
	lda_24	xde, 131787
	calr	745
	pop	xde
	popw	ix
	unlk	xiz
	ret
	link	xiz, 0
	push	xiy
	push	xix
	push	xde
	ld	bc, (xiz+8)
	ld	xiy, (xiz+10)
	lda_24	xde, 131787
	ld	a, (xiy)
	calr	717
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld16_24	hl, 131783
	cpda16_24	hl, 131779
	lds	hl, 0
	jr	z, 3
	ldw	hl, 65535
	ret
	ld16_24	hl, 131785
	ret

SeqBuf_NoteEvent_Flush:
	pushw ix
	push xde
	lda_24 xde, 0x0202cb
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret


SeqBuf_NoteEvent_SaveWritePtr:
	pushw	hl
	ld16_24	hl, 131779
	st16_24	131777, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 131787
	call	15675297
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 131787
	call	15675324
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 131781
	st16_24	131779, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 131783
	st16_24	131781, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 132053
	calr	507
	pop	xde
	popw	ix
	ret

SeqBuf_NoteEvent_WriteByte_Block:
	link	xiz, 0
	pushw	ix
	push	xde
	ld	a, (xiz+8)
	lda_24	xde, 132053
	calr	571
	pop	xde
	popw	ix
	unlk	xiz
	ret
	link	xiz, 0
	push	xiy
	push	xix
	push	xde
	ld	bc, (xiz+8)
	ld	xiy, (xiz+10)
	lda_24	xde, 132053
	ld	a, (xiy)
	calr	543
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld16_24	hl, 132049
	cpda16_24	hl, 132045
	lds	hl, 0
	jr	z, 3
	ldw	hl, 65535
	ret
	ld16_24	hl, 132051
	ret

SeqBuf_SoundEdit_Flush:
	pushw ix
	push xde
	lda_24 xde, 0x0203d5
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret

SeqBuf_SoundEdit_SaveWritePtr:
	; --- Sub 1: copy (0x0203CD)->HL->(0x0203CB) (13 bytes) ---
	pushw hl
	ld16_24	hl, 132045
	st16_24	132043, hl
	popw hl
	ret
SeqBuf_SoundEdit_CommitWrite:
	; --- Sub 2: call EF2FA1 with XDE=0x0203D5 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 132053
	call Seq_RingBuf_ReadByte_Large
	pop xde
	popw ix
	ret
SeqBuf_SoundEdit_RollbackWrite:
	; --- Sub 3: call EF2FBC with XDE=0x0203D5 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 132053
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret
SeqBuf_SoundEdit_SaveReadPtr:
	; --- Sub 4: copy (0x0203CF)->HL->(0x0203CD) (13 bytes) ---
	pushw hl
	ld16_24	hl, 132047
	st16_24	132045, hl
	popw hl
	ret
SeqBuf_SoundEdit_AdvanceCheckpoint:
	; --- Sub 5: copy (0x0203D1)->HL->(0x0203CF) (13 bytes) ---
	pushw hl
	ld16_24	hl, 132049
	st16_24	132047, hl
	popw hl
	ret


SeqBuf_SoundEdit_ReadByte:
	pushw ix
	push xde
	lda_24 xde, 0x0204df
	calr Seq_RingBuf_ReadByte
	pop xde
	popw ix
	ret

SeqBuf_SoundEdit_BytecodeBlock:
	link	xiz, 0
	pushw	ix
	push	xde
	ld	a, (xiz+8)
	lda_24	xde, 132319
	calr	397
	pop	xde
	popw	ix
	unlk	xiz
	ret
	link	xiz, 0
	push	xiy
	push	xix
	push	xde
	ld	bc, (xiz+8)
	ld	xiy, (xiz+10)
	lda_24	xde, 132319
	ld	a, (xiy)
	calr	369
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret

SeqBuf_NoteEvent_CheckSongEnd:
	ld16_24 xhl, 0x0204db
	cpda16_24 xhl, 132311
	lds hl, 0
	jr z, SeqBuf_NoteEvent_CheckSongEnd_Return
	ldw hl, 0xFFFF

SeqBuf_NoteEvent_CheckSongEnd_Return:
	ret

SeqBuf_NoteEvent_OrphanData:
	ld16_24	hl, 132317
	ret

SeqBuf_NoteEvent_InitBuffer:
	pushw ix
	push xde
	lda_24 xde, 0x0204df
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret

SeqBuf_NoteEvent_CopyPointers:
	pushw hl
	ld16_24 xhl, 0x0204d7
	st16_24 0x0204d5, xhl
	popw hl
	ret

SeqBuf_NoteEvent_AlternateRead:
	pushw	ix
	push	xde
	lda_24	xde, 132319
	call	15675297
	pop	xde
	popw	ix
	ret

Seq_RingBuf_ReadSmall:
	pushw ix
	push xde
	lda_24 xde, 0x0204df
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret


RingBuf_CopyPtr_Sub1:
	; --- Sub 1: copy (0x0204D9)->HL->(0x0204D7) (13 bytes) ---
	pushw hl
	ld16_24	hl, 132313
	st16_24	132311, hl
	popw hl
	ret
RingBuf_CopyPtr_Sub2:
	; --- Sub 2: copy (0x0204DB)->HL->(0x0204D9) (13 bytes) ---
	pushw hl
	ld16_24	hl, 132315
	st16_24	132313, hl
	popw hl
	ret
RingBuf_InitStructFields:
	; --- Sub 3: init XDE struct fields at offsets -10..-2 (26 bytes) ---
	.byte 0xba, 0xf6, 0x02, 0x00, 0x00		; ld (xde+0xF6), 0x0000  [16-bit store]
	.byte 0xba, 0xf8, 0x02, 0x00, 0x00		; ld (xde+0xF8), 0x0000
	.byte 0xba, 0xfc, 0x02, 0x00, 0x00		; ld (xde+0xFC), 0x0000
	.byte 0xba, 0xfa, 0x02, 0x00, 0x00		; ld (xde+0xFA), 0x0000
	.byte 0xba, 0xfe, 0x02, 0x7f, 0x00		; ld (xde+0xFE), 0x007F
	ret


RingBuf128_CheckEmpty:
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, RingBuf128_ReadByte
	ldw hl, 0xFFFF
	ret

RingBuf128_ReadByte:
	xor hl, hl
	ld_srib3 L, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0x7F
	ld (xde - 8), ix
	incm 1, (xde - 2)
	ret


RingBuf128_ReadAlt_CheckEmpty:
	; --- Ring buffer read 1: ix=(xde-10), check vs (xde-6), read (xde+ix) (27 bytes) ---
	ld ix, (xde-10)
	.byte 0x9a, 0xfa, 0xf4				; cp ix, (xde-6)  [16-bit indirect cp]
	jr nz, RingBuf128_ReadAlt_Dequeue
	ldw hl, 0xFFFF
	ret
RingBuf128_ReadAlt_Dequeue:
	xor hl, hl
	ld_rrb	l, xde, ix
	.byte 0xdc, 0x38, 0x7f, 0x00
	ld (xde-10), ix
	ret
RingBuf128_ReadAlt2_CheckEmpty:
	; --- Ring buffer read 2: same structure, check vs (xde-4) (27 bytes) ---
	ld ix, (xde-10)
	.byte 0x9a, 0xfc, 0xf4				; cp ix, (xde-4)  [16-bit indirect cp]
	jr nz, RingBuf128_ReadAlt2_Dequeue
	ldw hl, 0xFFFF
	ret
RingBuf128_ReadAlt2_Dequeue:
	xor hl, hl
	ld_rrb	l, xde, ix
	.byte 0xdc, 0x38, 0x7f, 0x00
	ld (xde-10), ix
	ret


RingBuf128_WriteByte_CheckFull:
	cpw (xde - 2), 0x0
	jr nz, RingBuf128_WriteByte_Store
	ldw hl, 0xFFFF
	ret

RingBuf128_WriteByte_Store:
	ld ix, (xde - 4)
	lda_dri3 XBC, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0x7F
	ld (xde - 4), ix
	decm 1, (xde - 2)
	ld hl, (xde - 2)
	ret


Seq_RingBuf_Init_256:
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0xFF
	ret

Seq_RingBuf_ReadByte:
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, Seq_RingBuf_ReadByte_Dequeue
	ldw hl, 0xFFFF
	ret

Seq_RingBuf_ReadByte_Dequeue:
	xor hl, hl
	ld_srib3 L, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0xFF
	ld (xde - 8), ix
	incm 1, (xde - 2)
	ret

Seq_RingBuf_ReadByte_Large:
	ld ix, (xde - 10)
	cp ix, (xde - 6)
	jr nz, Seq_RingBuf_ReadByte_Large_Dequeue
	ldw hl, 0xFFFF
	ret

Seq_RingBuf_ReadByte_Large_Dequeue:
	xor hl, hl
	ld_srib3 L, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0xFF
	ld (xde - 10), ix
	ret

Seq_RingBuf_ReadByte_Small:
	ld ix, (xde - 10)
	cp ix, (xde - 4)
	jr nz, Seq_RingBuf_ReadByte_Small_Dequeue
	ldw hl, 0xFFFF
	ret

Seq_RingBuf_ReadByte_Small_Dequeue:
	xor hl, hl
	ld_srib3 L, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0xFF
	ld (xde - 10), ix
	ret

Seq_RingBuf_WriteByte_Small:
	cpw (xde - 2), 0x0
	jr nz, Seq_RingBuf_WriteByte_Small_Store
	ldw hl, 0xFFFF
	ret

Seq_RingBuf_WriteByte_Small_Store:
	ld ix, (xde - 4)
	lda_dri3 XBC, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0xFF
	ld (xde - 4), ix
	decm 1, (xde - 2)
	ld hl, (xde - 2)
	ret

Seq_RingBuf_Init_512:
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0x1FF
	ret

RingBuf_CheckFull_512:
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, RingBuf512_CheckFull_Read
	ldw hl, 0xFFFF
	ret

RingBuf512_CheckFull_Read:
	xor hl, hl
	ld_srib3 L, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0x1FF
	ld (xde - 8), ix
	incm 1, (xde - 2)
	ret

RingBuf_CheckFull_256:
	ld ix, (xde - 10)
	cp ix, (xde - 6)
	jr nz, RingBuf256_CheckFull_Read
	ldw hl, 0xFFFF
	ret

RingBuf256_CheckFull_Read:
	xor hl, hl
	ld_srib3 L, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0x1FF
	ld (xde - 10), ix
	ret

RingBuf512_ReadAlt_ByteBlock:
	ld	ix, (xde-10)
	.byte 0x9a, 0xfc, 0xf4
	jr	nz, 4
	ldw	hl, 65535
	ret
	xor	hl, hl
	ld_rrb	l, xde, ix
	.byte 0xdc, 0x38, 0xff, 0x01
	ld	(xde-10), ix
	ret

Seq_RingBuf_WriteByte_512:
	cpw (xde - 2), 0x0
	jr nz, Seq_RingBuf_WriteByte_512_Store
	ldw hl, 0xFFFF
	ret

Seq_RingBuf_WriteByte_512_Store:
	ld ix, (xde - 4)
	lda_dri3 XBC, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0x1FF
	ld (xde - 4), ix
	decm 1, (xde - 2)
	ld hl, (xde - 2)
	ret

Seq_RingBuf_Init_1024:
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0x3FF
	ret

Seq_RingBuf_Dequeue_1024:
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, Seq_RingBuf_Dequeue_1024_Read
	ldw hl, 0xFFFF
	ret

Seq_RingBuf_Dequeue_1024_Read:
	xor hl, hl
	ld_srib3 L, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0x3FF
	ld (xde - 8), ix
	incm 1, (xde - 2)
	ret

Seq_RingBuf_ReadData:
	ld ix, (xde - 10)
	cp ix, (xde - 6)
	jr nz, Seq_RingBuf_ReadData_Dequeue
	ldw hl, 0xFFFF
	ret

Seq_RingBuf_ReadData_Dequeue:
	xor hl, hl
	ld_srib3 L, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0x3FF
	ld (xde - 10), ix
	ret

RingBuf1024_ReadAlt_ByteBlock:
	ld	ix, (xde-10)
	.byte 0x9a, 0xfc, 0xf4
	jr	nz, 4
	ldw	hl, 65535
	ret
	xor	hl, hl
	ld_rrb	l, xde, ix
	.byte 0xdc, 0x38, 0xff, 0x03
	ld	(xde-10), ix
	ret

Seq_RingBuf_WriteByte:
	cpw (xde - 2), 0x0
	jr nz, Seq_RingBuf_WriteByte_1024_Store
	ldw hl, 0xFFFF
	ret

Seq_RingBuf_WriteByte_1024_Store:
	ld ix, (xde - 4)
	lda_dri3 XBC, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0x3FF
	ld (xde - 4), ix
	decm 1, (xde - 2)
	ld hl, (xde - 2)
	ret

Seq_RingBuf_Init_2048:
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0x7FF
	ret

Seq_RingBuf_PeekByte:
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, Seq_RingBuf_PeekByte_Read
	ldw hl, 0xFFFF
	ret

Seq_RingBuf_PeekByte_Read:
	xor hl, hl
	ld_srib3 L, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0x7FF
	ld (xde - 8), ix
	incm 1, (xde - 2)
	ret

Seq_RingBuf_WriteByte_Data:
	ld	ix, (xde-10)
	.byte 0x9a, 0xfa, 0xf4
	jr	nz, 4
	ldw	hl, 65535
	ret
	xor	hl, hl
	ld_rrb	l, xde, ix
	.byte 0xdc, 0x38, 0xff, 0x07
	ld	(xde-10), ix
	ret

Seq_RingBuf_ReadAhead:
	ld ix, (xde - 10)
	cp ix, (xde - 4)
	jr nz, Seq_RingBuf_ReadAhead_Read
	ldw hl, 0xFFFF
	ret

Seq_RingBuf_ReadAhead_Read:
	xor hl, hl
	ld_srib3 L, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0x7FF
	ld (xde - 10), ix
	ret

Seq_RingBuf_WriteByte_Check:
	cpw (xde - 2), 0x0
	jr nz, Seq_RingBuf_WriteByte_Store
	ldw hl, 0xFFFF
	ret

Seq_RingBuf_WriteByte_Store:
	ld ix, (xde - 4)
	lda_dri3 XBC, 0x07, 0xE8, 0xF0
	minc1_16 ix, 0x7FF
	ld (xde - 4), ix
	decm 1, (xde - 2)
	ld hl, (xde - 2)
	ret


SeqDMA_Nop:
	ret


SeqDMA_MultiWrite_NoteEvent:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), a
	lds iz, 0
	ld a, (xsp + 6)
	extz wa
	cps wa, 0
	jr ule, SeqDMA_MultiWrite_NoteEvent_Done

SeqDMA_MultiWrite_NoteEvent_Loop:
	ld xwa, (xsp + 2)
	ld_spib C, 0xE0
	ld (xsp + 2), xwa
	extz bc
	pushw bc
	call SeqBuf_NoteEvent_WriteByte_Block
	inc 2, xsp
	inc 1, iz
	ld a, (xsp + 6)
	extz wa
	cp iz, wa
	jr c, SeqDMA_MultiWrite_NoteEvent_Loop

SeqDMA_MultiWrite_NoteEvent_Done:
	popw iz
	inc 6, xsp
	ret


SeqDMA_MultiWrite_VoiceMap:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), a
	lds iz, 0
	ld a, (xsp + 6)
	extz wa
	cps wa, 0
	jr ule, SeqDMA_MultiWrite_VoiceMap_Done

SeqDMA_MultiWrite_VoiceMap_Loop:
	ld xwa, (xsp + 2)
	ld_spib C, 0xE0
	ld (xsp + 2), xwa
	extz bc
	pushw bc
	call SeqBuf_VoiceMap_WriteByte
	inc 2, xsp
	inc 1, iz
	ld a, (xsp + 6)
	extz wa
	cp iz, wa
	jr c, SeqDMA_MultiWrite_VoiceMap_Loop

SeqDMA_MultiWrite_VoiceMap_Done:
	popw iz
	inc 6, xsp
	ret

SeqDMA_MultiWrite_DspSysEx:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), a
	lds iz, 0
	ld a, (xsp + 6)
	extz wa
	cps wa, 0
	jr ule, SeqDMA_MultiWrite_DspSysEx_Done

SeqDMA_MultiWrite_DspSysEx_Loop:
	ld xwa, (xsp + 2)
	ld_spib C, 0xE0
	ld (xsp + 2), xwa
	extz bc
	pushw bc
	call SeqBuf_DspSysEx_WriteByte
	inc 2, xsp
	inc 1, iz
	ld a, (xsp + 6)
	extz wa
	cp iz, wa
	jr c, SeqDMA_MultiWrite_DspSysEx_Loop

SeqDMA_MultiWrite_DspSysEx_Done:
	popw iz
	inc 6, xsp
	ret


SeqDMA_MultiWrite_SoundEdit:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld (xsp + 6), a
	lds iz, 0
	ld a, (xsp + 6)
	extz wa
	cps wa, 0
	jr ule, SeqDMA_MultiWrite_SoundEdit_Done

SeqDMA_MultiWrite_SoundEdit_Loop:
	ld xwa, (xsp + 2)
	ld_spib C, 0xE0
	ld (xsp + 2), xwa
	extz bc
	pushw bc
	call SeqBuf_SoundEdit_BytecodeBlock
	inc 2, xsp
	inc 1, iz
	ld a, (xsp + 6)
	extz wa
	cp iz, wa
	jr c, SeqDMA_MultiWrite_SoundEdit_Loop

SeqDMA_MultiWrite_SoundEdit_Done:
	popw iz
	inc 6, xsp
	ret


SeqDMA_WriteMidi_NoteOn:
	push xiz
	ld xiz, xbc
	ld a, (xiz)
	cp a, 0x90
	jr nz, SeqDMA_WriteMidi_NoteOn_Done
	inc 1, xiz
	ld a, (xiz)
	extz wa
	pushw wa
	call SeqBuf_NoteEvent_WriteByte_Data
	inc 1, xiz
	ld a, (xiz)
	extz wa
	pushw wa
	call SeqBuf_NoteEvent_WriteByte_Data
	inc 4, xsp

SeqDMA_WriteMidi_NoteOn_Done:
	pop xiz
	ret


; ===========================================================================
; SubCPU_Init_DMA_Channels - Initialize DMA channels for inter-CPU communication
; ===========================================================================
; Entry: None
; Exit:  DMA channels configured for Sub-CPU payload transfer
; Notes: Sets up MicroDMA channels 0 and 2 for inter-CPU latch communication
;        - DMA channel 2 destination = latch at 0x140000 (Main→Sub)
;        - DMA channel 0 source = latch at 0x140000 (Sub→Main)
;        - Configures interrupt priorities for DMA completion
;        - Clears transfer state variables at 0x05E0 and 0x05E2
;        Called during boot after Sub-CPU is released from reset
; ===========================================================================
SubCPU_Init_DMA_Channels:
	and_sd8b_im 0xE5, 0xF8
	res_dd8 2, 0x80
	lda_dd8l XBC, 0xEC
	ld a, (xbc)
	and a, 0xF8
	or a, 0x5
	ld (xbc), a
	lda_dd8l XBC, 0xED
	ld a, (xbc)
	and a, 0xF8
	or a, 0x5
	ld (xbc), a
	lda_dd8l XBC, 0xF0
	ld a, (xbc)
	and a, 0xF8
	set 0, a
	ld (xbc), a
	ldio 0x8A, 0x07
	lda_24 xwa, 0x140000
	ldc_cr32 xwa, 0x28
	ldb a, 0x8
	ldc_cr8 a, 0x4A
	lda_24 xwa, 0x140000
	ldc_cr32 xwa, 0x00
	ldb a, 0x0
	ldc_cr8 a, 0x42
	stdi8 1504, 0
	stdi8 1506, 0
	ret
Audio_InitDMAChannels_Done:

sendCOMM:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xde
	ld iz, bc
	ld (xsp + 6), a
	lds wa, 2
	call Audio_Lock_Acquire
	cp iz, 0x20
	jr ule, sendCOMM_FinalChunk

sendCOMM_ChunkLoop:
	ld a, (xsp + 6)
	extz wa
	ldw bc, 0x20
	ld xde, (xsp + 2)
	calr InterCPU_Send_Data_Block
	ld xwa, 0x20
	add (xsp + 2), xwa
	sub iz, 0x20
	cp iz, 0x20
	jr ugt, sendCOMM_ChunkLoop

sendCOMM_FinalChunk:
	ld a, (xsp + 6)
	extz wa
	ldto_berp C, 0xF8
	extz bc
	ld xde, (xsp + 2)
	calr InterCPU_Send_Data_Block
	lds wa, 2
	call Audio_Lock_Release
	popw iz
	inc 6, xsp
	ret

; ===========================================================================
; InterCPU_Send_Data_Block - Send a data packet to Sub-CPU
; ===========================================================================
; Entry: A = command/channel identifier (upper 3 bits)
;        C = byte count (1-32 bytes)
;        XDE = source data pointer
; Exit:  Data transferred to Sub-CPU
; Notes: Sends a variable-length data packet using encoded command byte:
;        - Command byte format: (A << 5) | (count - 1)
;        - Upper 3 bits = channel/command ID
;        - Lower 5 bits = byte count minus 1 (0-31 = 1-32 bytes)
;        Protocol:
;        1. Wait for SSTAT1 high (Sub-CPU ready)
;        2. Clear MSTAT0, set state to 1
;        3. Write encoded command byte to latch
;        4. Wait for SSTAT1 low (Sub-CPU acknowledged)
;        5. Set MSTAT0, send data via DMA
;        Timeout: 60000 iterations (0xEA60)
;        Called by sendCOMM for chunked audio data transfers
; ===========================================================================
InterCPU_Send_Data_Block:
	cps c, 0
	ret z
	lds ix, 0

InterCPU_Send_WaitReady:
	bit_dd8 3, 0x68	; SSTAT1 - test if Sub CPU is ready
	jr z, InterCPU_Send_TimeoutLoop
	res_dd8 0, 0x68	; MSTAT0 - clear to initiate handshake with Sub CPU
	stdi8 1504, 1
	ld l, c
	dec 1, l
	sll a, 5
	or a, l
	st8_24 0x140000, a
	lds ix, 0

InterCPU_Send_WaitAck:
	bit_dd8 3, 0x68	; SSTAT1 - wait for Sub CPU to acknowledge (goes low)
	jr nz, InterCPU_Send_AckTimeoutLoop
	set_dd8 0, 0x68	; MSTAT0 - set to signal DMA data transfer starting
	stda32 1498, xde
	extz bc
	stda16 1502, xbc
	calr Audio_DMA_Transfer
	stdi8 1504, 0
	cpdi8 1504, 0
	ret z

InterCPU_Send_WaitComplete:
	cpdi8 1504, 0
	jr nz, InterCPU_Send_WaitComplete
	ret

InterCPU_Send_TimeoutLoop:
	ld hl, ix
	inc 1, ix
	cp hl, 0xEA60
	jr ule, InterCPU_Send_WaitReady
	ret

InterCPU_Send_AckTimeoutLoop:
	ld wa, ix
	inc 1, ix
	cp wa, 0xEA60
	jr ule, InterCPU_Send_WaitAck
	set_dd8 0, 0x68	; MSTAT0 - timeout recovery: force ready state
	ret

; ===========================================================================
; InterCPU_E2_Send - Send E2 extended transfer command
; ===========================================================================
; Entry: XWA = first parameter (4 bytes)
;        XDE = second parameter (4 bytes)
;        BC = third parameter (2 bytes)
; Exit:  10-byte header transferred to Sub-CPU
; Notes: Implements E2 command for extended transfers:
;        - Sends 10-byte header containing three parameters
;        - Used for complex audio operations requiring more metadata
;        Protocol similar to E1 but with larger header
;        Sets bit 7 of 0x0620 on completion
;        Timeout: 60000 iterations (0xEA60)
; ===========================================================================
InterCPU_E2_Send:
	lds ix, 0
	cpdi8 1504, 0
	jr z, InterCPU_E2_ClearAndSend

InterCPU_E2_WaitIdle:
	ld hl, ix
	inc 1, ix
	cp hl, 0xEA60
	ret ugt
	cpdi8 1504, 0
	jr nz, InterCPU_E2_WaitIdle

InterCPU_E2_ClearAndSend:
	res_dd8 0, 0x68	; MSTAT0 - clear to initiate E2 command handshake
	stdi8 1504, 1
	sti8_24 0x140000, 0xe2
	lds ix, 0

InterCPU_E2_WaitAck:
	bit_dd8 3, 0x68	; SSTAT1 - wait for Sub CPU to acknowledge (goes low)
	jr nz, InterCPU_E2_TimeoutLoop
	set_dd8 0, 0x68	; MSTAT0 - set to signal E2 header data ready
	ldada xhl, 1478
	ld (xhl), xwa
	ld (xhl + 4), xde
	ld (xhl + 8), bc
	stda32 1498, xhl
	stdi16 1502, 10
	calr Audio_DMA_Transfer
	stdi8 1504, 0
	setda 7, 1568
	cpdi8 1504, 0
	ret z

InterCPU_E2_WaitComplete:
	cpdi8 1504, 0
	jr nz, InterCPU_E2_WaitComplete
	ret

InterCPU_E2_TimeoutLoop:
	ld hl, ix
	inc 1, ix
	cp hl, 0xEA60
	jr ule, InterCPU_E2_WaitAck
	set_dd8 0, 0x68	; MSTAT0 - timeout recovery: force ready state
	ret

; ===========================================================================
; Audio_DMA_Transfer - Core DMA transfer routine for inter-CPU communication
; ===========================================================================
; Entry: Data pointer at 0x05DA, byte count at 0x05DE
; Exit:  Data transferred to Sub-CPU via DMA
; Notes: Transfers audio command/data blocks to Sub-CPU
;        Uses DMA channel configuration set up by Audio_InitDMAChannels
;        Handles both small transfers and large block transfers
; ===========================================================================
Audio_DMA_Transfer:
	ldda16 xwa, 1502
	ld de, wa
	extz xde
	cps wa, 0
	jr nz, Audio_DMA_Transfer_CheckSize
	ld xde, 0x10000

Audio_DMA_Transfer_CheckSize:
	lds32 xhl, 0
	cp xde, 0x0
	ret ule

Audio_DMA_Transfer_ByteLoop:
	ldda32 xwa, 1498
	st_dpib A, 0xE0
	stda32 1498, xwa
	ld a, (xbc)
	st8_24 0x140000, a
	ldb a, 0x0

Audio_DMA_Transfer_DelayLoop:
	inc 1, a
	cps a, 3
	jr c, Audio_DMA_Transfer_DelayLoop
	inc 1, xhl
	cp xhl, xde
	jr c, Audio_DMA_Transfer_ByteLoop
	ret

; ===========================================================================
; InterCPU_E1_Bulk_Transfer - E1 two-phase bulk transfer protocol
; ===========================================================================
; Entry: XWA = source address in Main-CPU memory space
;        XBC = byte count to transfer
;        XDE = destination address in Sub-CPU memory space
; Exit:  IZ restored, data transferred to Sub-CPU
; Notes: Implements the E1 command protocol for bulk data transfers:
;        Phase 1: Send 6-byte header (dest addr + byte count)
;        Phase 2: Send actual data payload
;        Protocol:
;        1. Wait for previous transfer complete (05E0h == 0)
;        2. Wait for SSTAT1 high (Sub-CPU ready)
;        3. Clear MSTAT0, set state to 2 (two-phase)
;        4. Write 0xE1 to latch
;        5. Wait for SSTAT1 low (Sub-CPU acknowledged)
;        6. Set MSTAT0, send 6-byte header via DMA
;        7. Wait for state transition, send data payload
;        Timeout: 60000 iterations (0xEA60) for each wait loop
;        Used by SubCPU_Send_Payload for firmware payload transfer
; ===========================================================================
InterCPU_E1_Bulk_Transfer:
	pushw iz
	lds iz, 0
	cpdi8 1504, 0
	jr z, E1Bulk_ReadyCheck

E1Bulk_WaitIdle_Loop:
	ld hl, iz
	inc 1, iz
	cp hl, 0xEA60
	jrl ugt, FlashBufferIO_Exit
	cpdi8 1504, 0
	jr nz, E1Bulk_WaitIdle_Loop

E1Bulk_ReadyCheck:
	lds iz, 0

E1Bulk_WaitSubCPU_Ready:
	bit_dd8 3, 0x68	; SSTAT1 - test if Sub CPU is ready for E1 transfer
	jrl z, E1Bulk_ReadyTimeout_Loop
	res_dd8 0, 0x68	; MSTAT0 - clear to initiate E1 bulk transfer
	stdi8 1504, 2
	sti8_24 0x140000, 0xe1
	lds iz, 0

E1Bulk_WaitAck:
	bit_dd8 3, 0x68	; SSTAT1 - wait for Sub CPU to acknowledge E1 (goes low)
	jrl nz, E1Bulk_AckTimeout_Loop
	set_dd8 0, 0x68	; MSTAT0 - set to signal 6-byte header data ready
	ldada xhl, 1544
	ld (xhl), xwa
	ldada xwa, 1488
	ld (xwa), xde
	ld (xhl + 4), bc
	ld (xwa + 4), bc
	stda32 1498, xwa
	stdi16 1502, 6
	calr Audio_DMA_Transfer
	stdi8 1504, 1
	cpdi8 1504, 1
	jr z, E1Bulk_Phase2_Init

E1Bulk_WaitPhase1_Loop:
	cpdi8 1504, 1
	jr nz, E1Bulk_WaitPhase1_Loop

E1Bulk_Phase2_Init:
	lds wa, 0

E1Bulk_Phase2_Delay:
	inc 1, wa
	cp wa, 0xC8
	jr c, E1Bulk_Phase2_Delay
	ldada xbc, 1544
	ld xwa, (xbc)
	stda32 1498, xwa
	mrdw5 0x99, 0x04, 0x19, 0xDE, 0x05
	calr Audio_DMA_Transfer
	stdi8 1504, 0
	cpdi8 1504, 0
	jr z, E1Bulk_PostTransfer_Delay_Init

E1Bulk_WaitPhase2_Loop:
	cpdi8 1504, 0
	jr nz, E1Bulk_WaitPhase2_Loop

E1Bulk_PostTransfer_Delay_Init:
	lds iz, 0
	cp iz, 0xC8
	jr nc, E1Bulk_PostTransfer_Exit

E1Bulk_PostTransfer_Delay_Loop:
	nop
	inc 1, iz
	cp iz, 0xC8
	jr c, E1Bulk_PostTransfer_Delay_Loop

E1Bulk_PostTransfer_Exit:
	jr FlashBufferIO_Exit

E1Bulk_ReadyTimeout_Loop:
	ld hl, iz
	inc 1, iz
	cp hl, 0xEA60
	jrl ule, E1Bulk_WaitSubCPU_Ready
	jr FlashBufferIO_Exit

E1Bulk_AckTimeout_Loop:
	ld hl, iz
	inc 1, iz
	cp hl, 0xEA60
	jrl ule, E1Bulk_WaitAck
	set_dd8 0, 0x68	; MSTAT0 - timeout recovery: force ready state

FlashBufferIO_Exit:
	popw iz
	ret

INT0_HANDLER:
	bit_dd8 1, 0x68	; MSTAT1 - test own status (check if transfer in progress)
	jr nz, INT0_ProcessCommand
	stdi8 265, 1
	reti
INT0_UnusedBranch:
	jr	t, 0x03

INT0_ProcessCommand:
	calr INT0_ReadLatch
	reti

INT0_ReadLatch:
	bit_dd8 2, 0x68	; SSTAT0 - test Sub CPU handshake status
	ret nz
	push xwa
	push xbc
	ld8_24 a, 0x140000
	stda8 1508, a
	cp a, 0xE1
	jr nz, INT0_CheckE2Command
	stdi8 1506, 2
	ldada xwa, 1550
	stda32 1494, xwa
	ldc_cr32 xwa, 0x20
	lds wa, 6
	ldc_cr16 wa, 0x40
	lda_dd8l XBC, 0xF0
	ld a, (xbc)
	and a, 0xF8
	or a, 0x6
	ld (xbc), a
	jr INT0_AckAndReturn

INT0_CheckE2Command:
	cp a, 0xE2
	jr nz, INT0_HandleDataCommand
	stdi8 1506, 3
	ldada xwa, 1556
	stda32 1494, xwa
	ldc_cr32 xwa, 0x20
	ldw wa, 0xA
	ldc_cr16 wa, 0x40
	lda_dd8l XBC, 0xF0
	ld a, (xbc)
	and a, 0xF8
	or a, 0x6
	ld (xbc), a
	jr INT0_AckAndReturn

INT0_HandleDataCommand:
	stdi8 1506, 1
	ldada xwa, 1512
	stda32 1494, xwa
	ldc_cr32 xwa, 0x20
	ldda8 a, 1508
	and a, 0x1F
	inc 1, a
	extz wa
	ldc_cr16 wa, 0x40
	lda_dd8l XBC, 0xF0
	ld a, (xbc)
	and a, 0xF8
	or a, 0x6
	ld (xbc), a

INT0_AckAndReturn:
	res_dd8 1, 0x68	; MSTAT1 - clear to acknowledge command from Sub CPU
	pop xbc
	pop xwa
	ret

INTTC2_HANDLER:
	res_dd8 2, 0x80
	cpdi8 1504, 1
	jr nz, INTTC2_CheckPhase2
	stdi8 1504, 0
	jr INTTC2_Exit

INTTC2_CheckPhase2:
	cpdi8 1504, 2
	jr nz, INTTC2_Exit
	stdi8 1504, 1

INTTC2_Exit:
	reti

INTTC0_HANDLER:
	push xiz
	push xiy
	push xix
	push xhl
	push xde
	push xbc
	push xwa
	lda_dd8l XBC, 0xF0
	ld a, (xbc)
	and a, 0xF8
	set 0, a
	ld (xbc), a
	ldda8 a, 1506
	cps a, 4
	jr z, INTTC0_E1_Phase2_Complete
	cps a, 3
	jr z, INTTC0_E2_Complete
	cps a, 2
	jr z, E1DMA_TransferSetup
	cps a, 1
	jr nz, E1DMA_ISR_Epilogue
	ldda8 c, 1508
	ld a, c
	and a, 0x1F
	inc 1, a
	extz wa
	srl c, 5
	extz bc
	sla bc, 2
	lda_24 xde, 0xe00012
	st_dri3b B, 0x07, 0xE8, 0xE4
	ld xbc, 0x5E8
	ld xhl, (xde)
	call (xhl)
	stdi8 1506, 0
	jr INTTC0_SetTransferDone

; E1DMA ISR - DMA transfer setup (after SeqRingBuf dispatch)
E1DMA_TransferSetup:
	ldada xwa, 1550
	ld xbc, (xwa)
	ldc_cr32 xbc, 0x20
	ld wa, (xwa + 4)
	ldc_cr16 wa, 0x40
	lda_dd8l XBC, 0xF0
	ld a, (xbc)
	and a, 0xF8
	or a, 0x6
	ld (xbc), a
	stdi8 1506, 4
	jr E1DMA_ISR_Epilogue

INTTC0_E2_Complete:
	stdi8 1510, 255
	stdi8 1506, 0
	set_dd8 1, 0x68	; MSTAT1 - set to signal E2 command complete
	setda 7, 1566
	jr E1DMA_ISR_Epilogue

INTTC0_E1_Phase2_Complete:
	stdi8 1506, 0
	resda 7, 1568

INTTC0_SetTransferDone:
	set_dd8 1, 0x68	; MSTAT1 - set to signal E1 transfer complete

E1DMA_ISR_Epilogue:
	pop xwa
	pop xbc
	pop xde
	pop xhl
	pop xix
	pop xiy
	pop xiz
	reti
E1DMA_ISR_BytecodeBlock:
	ei	0x06
	ldada	xwa, 1566
	bitm	7, (xwa)
	jr	z, 19
	resm	7, (xwa)
	ei	0x00
	ldada	xde, 1556
	ld	xwa, (xde)
	ld	bc, (xde+8)
	ld	xde, (xde+4)
	calr	-591
	ei	0x00
	.byte 0xf0, 0x68, 0xc9
	jr	nz, 27
	.byte 0xd8, 0x2f, 0x40, 0xd1, 0x62, 0xe3, 0xf8
	jr	nz, 6
	incdi16	1, 58208
	jr	6
	stdi16	58208, 0
	stda16	58210, wa
	jr	6
	stdi16	58208, 0
	ldda16	wa, 58208
	cp	wa, 10
	ret	ule
	stdi16	58208, 0
	stdi8	256, 0
	stdi8	1506, 0
	.byte 0xf0, 0x68, 0xb9
	incdi8	1, 58206
	ret
	ldda16	de, 1033
	bitda	7, 1568
	jr	nz, 3
	lds	hl, 0
	ret
	ld	wa, de
	ldda16	bc, 1033
	sub	bc, wa
	cp	bc, 250
	jr	le, -23
	stdi8	256, 0
	stdi8	1506, 0
	.byte 0xf0, 0x68, 0xb9
	resda	7, 1568
	incdi8	1, 58212
	ldw	hl, 65535
	ret

Flash_IdentifyChip:
	push xiz
	ld xbc, 0x280000
	cps a, 1
	jr nz, Flash_IdentifyChip_UseBank1
	ld xbc, 0x300000

Flash_IdentifyChip_UseBank1:
	ld xiz, xbc

Flash_IdentifyChip_WaitReady:
	bit_dd8 5, 0x1C
	jr z, Flash_IdentifyChip_WaitReady
	ei 6
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0xAA
	stiw_dri 0xF9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0xF0
	ld_sriw WA, (xiz + 0x3232)
	ei 0
	call Get_Region_Code
	cps l, 4
	jr nz, Flash_IdentifyChip_Done
	add xiz, 0x80000
	ei 6
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0xAA
	stiw_dri 0xF9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0xF0
	ld_sriw WA, (xiz + 0x3232)
	ei 0

Flash_IdentifyChip_Done:
	pop xiz
	ret

Flash_IdentifyAndValidateChip:
	dec 8, xsp
	push xiz
	ld (xsp + 10), a
	ldw (xsp + 8), 0xFFFF
	ld xwa, 0x280000
	cp (xsp + 10), 0x1
	jr nz, Flash_IdentifyValidate_UseBank1
	ld xwa, 0x300000

Flash_IdentifyValidate_UseBank1:
	ld (xsp + 4), xwa
	ei 6
	ld xbc, (xsp + 4)
	add xbc, 0xAAAA
	ldw (xbc), 0xAA
	ld xde, (xsp + 4)
	stiw_dri 0xE9, 0x54, 0x55, 0x55, 0x00
	ldw (xbc), 0x90
	ld wa, (xde)
	ldfr_werp WA, 0xFA
	ld xbc, xde
	ld iz, (xbc + 2)
	ei 0
	cpi_werp 0xFA, 1
	jr z, Flash_IdentifyValidate_CheckDeviceId
	cpi_werp 0xFA, 4
	jr nz, Flash_IdentifyValidate_Return

Flash_IdentifyValidate_CheckDeviceId:
	cp iz, 0x2223
	jr z, Flash_BufferAddressStore
	cp iz, 0x22AB
	jr z, Flash_BufferAddressStore
	cp iz, 0x22D6
	jr z, Flash_BufferAddressStore
	cp iz, 0x2258
	jr nz, Flash_IdentifyValidate_PostStore

Flash_BufferAddressStore:
	ld (xsp + 8), iz

Flash_IdentifyValidate_PostStore:
	ld a, (xsp + 10)
	extz wa
	calr Flash_IdentifyChip

Flash_IdentifyValidate_Return:
	ld hl, (xsp + 8)
	pop xiz
	inc 8, xsp
	ret

Flash_ProgramWord:
	dec 6, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), xbc
	cpw (xsp + 4), 0xFFFF
	jr z, Flash_ProgramWord_Done

Flash_ProgramWord_WaitReady:
	bit_dd8 5, 0x1C
	jr z, Flash_ProgramWord_WaitReady
	cps a, 1
	jr nz, Flash_ProgramWord_UseBank1
	lda_24 xiz, 0x300000
	call Get_Region_Code
	cps l, 4
	jr nz, Flash_WriteWordSeq
	ld xwa, (xsp + 6)
	cp xwa, 0x380000
	jr c, Flash_WriteWordSeq
	add xiz, 0x80000
	jr Flash_WriteWordSeq

Flash_ProgramWord_UseBank1:
	lda_24 xiz, 0x280000

Flash_WriteWordSeq:
	ei 6
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0xAA
	stiw_dri 0xF9, 0x54, 0x55, 0x55, 0x00
	ldw (xwa), 0xA0
	ld xwa, (xsp + 6)
	ld bc, (xsp + 4)
	ld (xwa), bc
	ei 0

Flash_ProgramWord_Done:
	pop xiz
	inc 6, xsp
	ret

Flash_ChipErase:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld xwa, 0x280000
	cp (xsp + 4), 0x1
	jr nz, Flash_ChipErase_UseBank1
	ld xwa, 0x300000

Flash_ChipErase_UseBank1:
	ld xiz, xwa
	ei 6
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0xAA
	stiw_dri 0xF9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0x80
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0xAA
	stiw_dri 0xF9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0x10
	call Get_Region_Code
	cps l, 4
	jr nz, Flash_ChipErase_Done
	cp (xsp + 4), 0x1
	jr nz, Flash_ChipErase_Done
	lda_24 xiz, 0x380000
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0xAA
	stiw_dri 0xF9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0x80
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0xAA
	stiw_dri 0xF9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0x10

Flash_ChipErase_Done:
	ei 0
	pop xiz
	inc 2, xsp
	ret

Flash_EraseSectorWithBankSelect:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 8), xbc
	ld (xsp + 12), a
	ld xwa, 0x280000
	cp (xsp + 12), 0x1
	jr nz, Flash_EraseSector_UseBank1
	ld xwa, 0x300000

Flash_EraseSector_UseBank1:
	ld xiz, xwa
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld xwa, 0xFF0000
	and (xsp + 4), xwa
	call Get_Region_Code
	cps l, 4
	jr nz, Flash_EraseSector_WriteSequence
	ld xwa, (xsp + 4)
	cp xwa, 0x380000
	jr c, Flash_EraseSector_WriteSequence
	add xiz, 0x80000

Flash_EraseSector_WriteSequence:
	ei 6
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0xAA
	stiw_dri 0xF9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0x80
	ld xwa, xiz
	add xwa, 0xAAAA
	ldw (xwa), 0xAA
	stiw_dri 0xF9, 0x54, 0x55, 0x55, 0x00
	ld xwa, (xsp + 4)
	ldw (xwa), 0x30
	call Get_Region_Code
	cps l, 4
	jr nz, Flash_EraseSector_CheckRegion
	cp (xsp + 12), 0x1
	jrl nz, FlashOp_Epilogue10
	lda_24 xwa, 0x300000
	ld xbc, xwa
	add xbc, 0x70000
	cp xbc, (xsp + 4)
	jr z, Flash_EraseSector_BootBlock_HighBank
	ld xbc, xwa
	add xbc, 0xF0000
	cp xbc, (xsp + 4)
	jrl nz, FlashOp_Epilogue10

Flash_EraseSector_BootBlock_HighBank:
	ld xbc, xiz
	add xbc, 0x78000
	ldw (xbc), 0x30
	ld xbc, xiz
	add xbc, 0x7A000
	ldw (xbc), 0x30
	ld xbc, xiz
	add xbc, 0x7C000
	ldw (xbc), 0x30
	add xwa, 0xFFFFF
	cp (xsp + 8), xwa
	jrl nz, FlashOp_Epilogue10
	ld xwa, 0x60000
	jrl Flash_EraseSector_FinalWrite

Flash_EraseSector_CheckRegion:
	cp (xsp + 12), 0x1
	jr nz, Flash_EraseSector_Bank2Check
	lda_24 xwa, 0x300000
	cpdi16_24 132576, 8792
	jr nz, Flash_EraseSector_TopSector
	cp xwa, (xsp + 4)
	jrl nz, FlashOp_Epilogue10
	stiw_dri 0xF9, 0x00, 0x40, 0x30, 0x00
	stiw_dri 0xF9, 0x00, 0x60, 0x30, 0x00
	ld xwa, 0x8000
	jrl Flash_EraseSector_FinalWrite

Flash_EraseSector_TopSector:
	ld xbc, xwa
	add xwa, 0xF0000
	cp xwa, (xsp + 4)
	jrl nz, FlashOp_Epilogue10
	ld xwa, xiz
	add xwa, 0xF8000
	ldw (xwa), 0x30
	ld xwa, xiz
	add xwa, 0xFA000
	ldw (xwa), 0x30
	ld xwa, xiz
	add xwa, 0xFC000
	ldw (xwa), 0x30
	add xbc, 0xFFFFF
	cp (xsp + 8), xbc
	jr nz, FlashOp_Epilogue10
	ld xwa, 0xE0000
	jr Flash_EraseSector_FinalWrite

Flash_EraseSector_Bank2Check:
	lda_24 xwa, 0x280000
	cpdi16_24 132578, 8875
	jr nz, Flash_EraseSector_Bank2TopSector
	cp xwa, (xsp + 4)
	jr nz, FlashOp_Epilogue10
	stiw_dri 0xF9, 0x00, 0x40, 0x30, 0x00
	stiw_dri 0xF9, 0x00, 0x60, 0x30, 0x00
	ld xwa, 0x8000
	jr Flash_EraseSector_FinalWrite

Flash_EraseSector_Bank2TopSector:
	add xwa, 0x70000
	cp xwa, (xsp + 4)
	jr nz, FlashOp_Epilogue10
	ld xwa, xiz
	add xwa, 0x78000
	ldw (xwa), 0x30
	ld xwa, xiz
	add xwa, 0x7A000
	ldw (xwa), 0x30
	ld xwa, 0x7C000

Flash_EraseSector_FinalWrite:
	ld xbc, xiz
	add xbc, xwa
	ldw (xbc), 0x30

FlashOp_Epilogue10:
	ei 0
	pop xiz
	lda xsp, (xsp + 10)
	ret

Flash_CheckReady:
	bit_dd8 5, 0x1C
	jr z, Flash_CheckReady_NotReady
	lds hl, 0
	ret

Flash_CheckReady_NotReady:
	ldw hl, 0xFFFF
	ret

Flash_WaitUntilReady:
	extz wa
	calr Flash_ChipErase
	calr Flash_CheckReady
	cp hl, 0xFFFF
	ret nz

Flash_WaitUntilReady_Loop:
	calr Flash_CheckReady
	cp hl, 0xFFFF
	jr z, Flash_WaitUntilReady_Loop
	ret

Flash_InitAllBanks:
	lds wa, 1
	calr Flash_IdentifyChip
	lds wa, 2
	calr Flash_IdentifyChip
	call Get_Region_Code
	cps l, 4
	call_24 nz, 0xEF3CD1
	lds wa, 1
	calr Flash_IdentifyAndValidateChip
	st16_24 0x0205e0, xhl
	lds wa, 2
	calr Flash_IdentifyAndValidateChip
	st16_24 0x0205e2, xhl
	ret

Flash_FillBuffer:
	lds de, 0
	cps bc, 0
	ret ule

Flash_FillBuffer_Loop:
	st_dpiw DE, 0xE1
	inc 1, de
	cp de, bc
	jr c, Flash_FillBuffer_Loop
	ret

Flash_CopyROMToBuffer:
	ld xbc, xwa
	and xbc, 0xFF0000
	ld xwa, 0x69800
	ld xde, 0x8000
	jp Copy_DE_words_from_XBC_to_XWA

Flash_WriteBufferToChip:
	lda xsp, (xsp - 10)
	pushw iz
	ld (xsp + 10), a
	lda_24 xwa, 0x069800
	ld (xsp + 2), xwa
	and xbc, 0xFF0000
	ld (xsp + 6), xbc
	lds iz, 0

Flash_WriteBufferToChip_Loop:
	ld a, (xsp + 10)
	extz wa
	ld xbc, (xsp + 6)
	st_dpib B, 0xE5
	ld (xsp + 6), xbc
	ld xbc, xde
	ld xhl, (xsp + 2)
	ld_spiw DE, 0xED
	ld (xsp + 2), xhl
	calr Flash_ProgramWord
	inc 1, iz
	cp iz, 0x8000
	jr c, Flash_WriteBufferToChip_Loop
	lds iz, 0

Flash_WriteBufferToChip_Delay:
	inc 1, iz
	cp iz, 0x1000
	jr c, Flash_WriteBufferToChip_Delay
	ld a, (xsp + 10)
	extz wa
	calr Flash_IdentifyChip
	popw iz
	lda xsp, (xsp + 10)
	ret

Flash_WriteFromMemory:
	lda xsp, (xsp - 10)
	pushw iz
	ld (xsp + 2), xde
	ld (xsp + 6), xbc
	ld (xsp + 10), a
	ld xwa, 0xFF0000
	and (xsp + 2), xwa
	lds iz, 0

Flash_WriteFromMemory_Loop:
	ld a, (xsp + 10)
	extz wa
	ld xbc, (xsp + 2)
	st_dpib B, 0xE5
	ld (xsp + 2), xbc
	ld xbc, xde
	ld xhl, (xsp + 6)
	ld_spiw DE, 0xED
	ld (xsp + 6), xhl
	calr Flash_ProgramWord
	inc 1, iz
	cp iz, 0x8000
	jr c, Flash_WriteFromMemory_Loop
	lds iz, 0

Flash_WriteFromMemory_Delay:
	inc 1, iz
	cp iz, 0x1000
	jr c, Flash_WriteFromMemory_Delay
	ld a, (xsp + 10)
	extz wa
	calr Flash_IdentifyChip
	popw iz
	lda xsp, (xsp + 10)
	ret

Flash_EraseSectorAndWrite:
	lda xsp, (xsp - 10)
	ld (xsp), xde
	ld (xsp + 4), xbc
	ld (xsp + 8), a
	ld a, (xsp + 8)
	extz wa
	calr Flash_IdentifyChip
	ld a, (xsp + 8)
	extz wa
	ld xbc, (xsp)
	calr Flash_EraseSectorWithBankSelect
	calr Flash_CheckReady
	cp hl, 0xFFFF
	jr nz, Flash_EraseSectorAndWrite_Write

Flash_EraseSectorAndWrite_WaitLoop:
	calr Flash_CheckReady
	cp hl, 0xFFFF
	jr z, Flash_EraseSectorAndWrite_WaitLoop

Flash_EraseSectorAndWrite_Write:
	ld a, (xsp + 8)
	extz wa
	ld xbc, (xsp + 4)
	ld xde, (xsp)
	calr Flash_WriteFromMemory
	lda xsp, (xsp + 10)
	ret
FlashWrite_Entry:

FlashWrite:
	dec 8, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), xbc
	ld (xsp + 10), a
	ld a, (xsp + 10)
	extz wa
	calr Flash_IdentifyChip
	ld xiz, (xsp + 16)
	ld xwa, xiz
	calr Flash_CopyROMToBuffer
	ld a, (xsp + 10)
	extz wa
	ld xbc, xiz
	calr Flash_EraseSectorWithBankSelect
	ld xbc, xiz
	ldi_werp 0xE6, 0
	lda_24 xde, 0x069800
	add xde, xbc
	pushm (xsp + 4)
	ld xwa, (xsp + 8)
	push xwa
	push xde
	call Mem_Copy
	lda xsp, (xsp + 10)
	calr Flash_CheckReady
	cp hl, 0xFFFF
	jr nz, FlashWrite_DoWrite

FlashWrite_WaitEraseLoop:
	calr Flash_CheckReady
	cp hl, 0xFFFF
	jr z, FlashWrite_WaitEraseLoop

FlashWrite_DoWrite:
	ld a, (xsp + 10)
	extz wa
	ld xbc, xiz
	calr Flash_WriteBufferToChip
	pop xiz
	inc 8, xsp
	retd 0x4
	ld xwa, 0x69800
	ldw bc, 0x8000
	calr Flash_FillBuffer
	lds wa, 1
	ld xbc, 0x69800
	ld xde, 0x378700
	calr Flash_EraseSectorAndWrite
	ld xwa, 0x378700
	push xwa
	lds wa, 1
	ld xbc, 0x800000
	ldw de, 0x400
	calr FlashWrite_Entry
	lds wa, 1
	jrl Flash_IdentifyChip

TableDataROM_IdentifyChip:
	ld xde, 0x800000

TableDataROM_IdentifyChip_WaitReady:
	bit_dd8 5, 0x1C
	jr z, TableDataROM_IdentifyChip_WaitReady
	ld xbc, xde
	add xbc, 0x15554
	ld xwa, 0xAA00AA
	ld (xbc), xwa
	ld xbc, xde
	add xbc, 0xAAA8
	ld xwa, 0x550055
	ld (xbc), xwa
	ld xbc, xde
	add xbc, 0x15554
	ld xwa, 0xF000F0
	ld (xbc), xwa
	ld_sril XWA, (xde + 0x6464)
	ret

; ===========================================================================
; HDAE5000_Detect - Detect presence of HDAE5000 expansion board
; ===========================================================================
; Entry: None
; Exit:  XWA at (XSP+8) = 0 if detected, 0xFFFFFFFF if not present
; Notes: Probes Table Data ROM at 0x800000 using flash command sequence
;        Sends AMD/Atmel flash ID command (0xAA, 0x55, 0x90)
;        Checks for valid response to confirm hardware presence
; ===========================================================================
HDAE5000_Detect:
	dec 8, xsp
	push xiz
	ld xwa, 0xFFFFFFFF
	ld (xsp + 8), xwa
	ei 6
	ld xwa, 0xAA00AA
	st32_24 0x815554, xwa
	ld xwa, 0x550055
	st32_24 0x80aaa8, xwa
	ld xwa, 0x900090
	st32_24 0x815554, xwa
	ld32_24 xwa, 0x800000
	ld (xsp + 4), xwa
	ld xwa, 0x800000
	ld xiz, (xwa + 4)
	ei 0
	ld xwa, (xsp + 4)
	cp xwa, 0x10001
	jr z, HDAE5000_Detect_CheckManufId
	cp xwa, 0x40004
	jr nz, HDAE5000_Detect_Return

HDAE5000_Detect_CheckManufId:
	cp xiz, 0x22D622D6
	jr z, HDAE5000_Detect_StoreDeviceId
	cp xiz, 0x22582258
	jr nz, HDAE5000_Detect_ResetChip

HDAE5000_Detect_StoreDeviceId:
	ld (xsp + 8), xiz

HDAE5000_Detect_ResetChip:
	calr TableDataROM_IdentifyChip

HDAE5000_Detect_Return:
	ld xhl, (xsp + 8)
	pop xiz
	inc 8, xsp
	ret

Flash_ProgramByte:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	cp xiz, 0xFFFFFFFF
	jr z, Flash_ProgramByte_Done

Flash_ProgramByte_WaitReady:
	bit_dd8 5, 0x1C
	jr z, Flash_ProgramByte_WaitReady
	ei 6
	ld xwa, 0xAA00AA
	st32_24 0x815554, xwa
	ld xwa, 0x550055
	st32_24 0x80aaa8, xwa
	ld xwa, 0xA000A0
	st32_24 0x815554, xwa
	ld xwa, (xsp + 4)
	ld (xwa), xiz
	ei 0

Flash_ProgramByte_Done:
	pop xiz
	inc 4, xsp
	ret

; ===========================================================================
; HDAE5000_Flash_Verify - Flash verification sequence on Table Data ROM
; ===========================================================================
; Entry: None
; Exit:  Flash ID verified
; Notes: Sends flash command sequence to Table Data ROM at 0x800000
;        Uses standard AMD/Atmel flash protocol for device identification
;        Called during HDAE5000 initialization to verify ROM presence
; ===========================================================================
HDAE5000_Flash_Verify:
	push xiz
	ld xiz, 0x800000
	ei 6

; == Notes ==
; This routine can be summarized as this sequence of memory writes:
; [00815554h] = 00aa00aah
; [0080aaa8h] = 00550055h
; [00815554h] = 00800080h
; [00815554h] = 00aa00aah
; [0080aaa8h] = 00550055h
; [00815554h] = 00100010h
;
; addresses:   ----------------| |||||||| ||||||--
; 00815554h = 00000000 10000001 01010101 01010100
; 0080aaa8h = 00000000 10000000 10101010 10101000
;
; data values: -------- |||||||| -------- ||||||||
; 00550055h = 00000000 01010101 00000000 01010101
; 00aa00aah = 00000000 10101010 00000000 10101010
; 00800080h = 00000000 10000000 00000000 10000000
; 00100010h = 00000000 00010000 00000000 00010000

	; [00815554h] = 00aa00aah
	ld xbc, xiz
	add xbc, 0x15554
	ld xwa, 0xAA00AA
	ld (xbc), xwa

	; [0080aaa8h] = 00550055h
	ld xbc, xiz
	add xbc, 0xAAA8
	ld xwa, 0x550055
	ld (xbc), xwa

	; [00815554h] = 00800080h
	ld xbc, xiz
	add xbc, 0x15554
	ld xwa, 0x800080
	ld (xbc), xwa

	; [00815554h] = 00aa00aah
	ld xbc, xiz
	add xbc, 0x15554
	ld xwa, 0xAA00AA
	ld (xbc), xwa

	; [0080aaa8h] = 00550055h
	ld xbc, xiz
	add xbc, 0xAAA8
	ld xwa, 0x550055
	ld (xbc), xwa

	; [00815554h] = 00100010h
	ld xbc, xiz
	add xbc, 0x15554
	ld xwa, 0x100010
	ld (xbc), xwa

	ei 0
	pop xiz
	ret

HDAE5000_Flash_Erase_AllSectors:
	push	xiz
	ld	xiz, 8388608
	ei	6
	ld	xbc, xiz
	add	xbc, 87380
	ld	xwa, 11141290
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 43688
	ld	xwa, 5570645
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 87380
	ld	xwa, 8388736
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 87380
	ld	xwa, 11141290
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 43688
	ld	xwa, 5570645
	ld	(xbc), xwa
	ld	xwa, 3145776
	ld	(xiz), xwa
	ld	xbc, xiz
	add	xbc, 131072
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 262144
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 393216
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 524288
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 655360
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 786432
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 917504
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 1048576
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 1179648
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 1310720
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 1441792
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 1572864
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 1703936
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 1835008
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 1966080
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 2031616
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 2048000
	ld	(xbc), xwa
	di
	pop	xiz
	ret

; ===========================================================================
; HDAE5000_Status_Check - Check HDAE5000 status register for ready state
; ===========================================================================
; Entry: None
; Exit:  HL = 0 if ready, 0xFFFF if busy
; Notes: Checks P7 bit 5 for HDAE5000 ready signal
;        Used to poll expansion board during data transfers
; ===========================================================================
HDAE5000_Status_Check:
	bit_dd8 5, 0x1C
	jr z, HDAE5000_Status_NotPresent
	lds hl, 0
	ret

HDAE5000_Status_NotPresent:
	ldw hl, 0xFFFF
	ret

HDAE5000_Status_DataBlock:
	calr	-381
	calr	-18
	cp	hl, 65535
	ret	nz
	calr	-27
	cp	hl, 65535
	jr	z, -9
	ret
	dec	4, xsp
	push	xiz
	ld	xwa, 524288
	ld	(xsp+4), xwa
	calr	-587
	cp	xhl, 4294967295
	jr	nz, 5
	ldw	hl, 65535
	jr	65
	calr	-430
	ld	xwa, 524288
	ld	xbc, 65536
	call	15678255
	calr	-81
	cp	hl, 65535
	jr	nz, 9
	calr	-90
	cp	hl, 65535
	jr	z, -9
	lds32	xiz, 0
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe2, 0x31
	ld	(xsp+4), xwa
	ld	xwa, xbc
	ld	xbc, xiz
	calr	-544
	inc	1, xiz
	cp	xiz, 8000
	jr	c, -26
	lds	hl, 0
	pop	xiz
	inc	4, xsp
	ret

SLIDE_Decompress_4K_Init:
	pushw iz
	ldfr_lerp XBC, 0x38
	ldfr_lerp XWA, 0x34
	pushw 0x1000
	call Malloc
	inc 2, xsp
	stda32 1570, xhl
	ld xwa, xhl
	st_dri3b A, 0xED, 0xEE, 0x0F

SLIDE_Decompress_4K_FillRing:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, SLIDE_Decompress_4K_FillRing
	ldw bc, 0xFEE
	ldi_werp 0x30, 0
	ldto_lerp XWA, 0x34
	lds32 xde, 0
	ld e, (xwa + 2)
	sll xde, 8
	lds32 xhl, 0
	ld l, (xwa + 3)
	add xhl, xde
	lda xde, (xwa + 1)
	inc4_lerp 0x34
	lds32 xwa, 0
	ld a, (xde)
	ld xix, xwa
	sll xix, 0
	add xix, xhl
	lds32 xhl, 0
	cp xix, 0x0
	jrl ule, SLIDE_Decompress_4K_Done

SLIDE_Decompress_4K_MainLoop:
	srl_erpw 0x30, 0x01
	bit_erpw 0x30, 0x08
	jr nz, SLIDE_Decompress_4K_CheckLiteral
	cp xhl, xix
	jrl nc, SLIDE_Decompress_4K_Done
	ld_spib E, 0x34
	ld a, e
	extz wa
	ldfr_werp WA, 0x30
	or_erpw 0x30, 0x00, 0xFF

SLIDE_Decompress_4K_CheckLiteral:
	ldto_werp WA, 0x30
	bit 0, wa
	jr z, SLIDE_Decompress_4K_CopyMatch
	cp xhl, xix
	jrl nc, SLIDE_Decompress_4K_Done
	ld_spib E, 0x34
	ld a, e
	extz wa
	ld e, a
	lda_dpi XIY, 0x38
	inc 1, xhl
	ld wa, bc
	inc 1, bc
	extz xwa
	addda32 xwa, 1570
	ld (xwa), e
	and bc, 0xFFF
	jr SLIDE_Decompress_4K_Continue

SLIDE_Decompress_4K_CopyMatch:
	cp xhl, xix
	jr nc, SLIDE_Decompress_4K_Done
	ld_spib A, 0x34
	extz wa
	ldfr_werp WA, 0x32
	cp xhl, xix
	jr nc, SLIDE_Decompress_4K_Done
	ld_spib A, 0x34
	ldfr_berp A, 0xF8
	extz iz
	ld wa, iz
	and wa, 0xF0
	sll wa, 4
	ex_werp WA, 0x32
	or_werp WA, 0x32
	ex_werp WA, 0x32
	and iz, 0xF
	inc 2, iz
	lds iy, 0
	cps iz, 0
	jr c, SLIDE_Decompress_4K_Continue

SLIDE_Decompress_4K_CopyLoop:
	ldto_werp WA, 0x32
	add wa, iy
	and wa, 0xFFF
	extz xwa
	addda32 xwa, 1570
	ld a, (xwa)
	extz wa
	ld e, a
	lda_dpi XIY, 0x38
	inc 1, xhl
	ld wa, bc
	inc 1, bc
	extz xwa
	addda32 xwa, 1570
	ld (xwa), e
	and bc, 0xFFF
	inc 1, iy
	cp iy, iz
	jr ule, SLIDE_Decompress_4K_CopyLoop

SLIDE_Decompress_4K_Continue:
	cp xhl, xix
	jrl c, SLIDE_Decompress_4K_MainLoop

SLIDE_Decompress_4K_Done:
	ldda32 xwa, 1570
	push xwa
	call Free
	inc 4, xsp
	popw iz
	ret

SLIDE_Decompress_8K_Init:
	pushw iz
	ldfr_lerp XBC, 0x38
	ldfr_lerp XWA, 0x34
	pushw 0x2000
	call Malloc
	inc 2, xsp
	stda32 1570, xhl
	ld xwa, xhl
	st_dri3b A, 0xED, 0xF6, 0x1F

SLIDE_Decompress_8K_FillRing:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, SLIDE_Decompress_8K_FillRing
	ldw bc, 0x1FF6
	ldi_werp 0x30, 0
	ldto_lerp XWA, 0x34
	lds32 xde, 0
	ld e, (xwa + 2)
	sll xde, 8
	lds32 xhl, 0
	ld l, (xwa + 3)
	add xhl, xde
	lda xde, (xwa + 1)
	add_erpl 0x34, 0x04, 0x00, 0x00, 0x00
	lds32 xwa, 0
	ld a, (xde)
	ld xix, xwa
	sll xix, 0
	add xix, xhl
	lds32 xhl, 0
	cp xix, 0x0
	jrl ule, SLIDE_Decompress_8K_Done

SLIDE_Decompress_8K_MainLoop:
	srl_erpw 0x30, 0x01
	bit_erpw 0x30, 0x08
	jr nz, SLIDE_Decompress_8K_CheckLiteral
	cp xhl, xix
	jrl nc, SLIDE_Decompress_8K_Done
	ld_spib E, 0x34
	ld a, e
	extz wa
	ldfr_werp WA, 0x30
	or_erpw 0x30, 0x00, 0xFF

SLIDE_Decompress_8K_CheckLiteral:
	ldto_werp WA, 0x30
	bit 0, wa
	jr z, SLIDE_Decompress_8K_CopyMatch
	cp xhl, xix
	jrl nc, SLIDE_Decompress_8K_Done
	ld_spib E, 0x34
	ld a, e
	extz wa
	ld e, a
	lda_dpi XIY, 0x38
	inc 1, xhl
	ld wa, bc
	inc 1, bc
	extz xwa
	addda32 xwa, 1570
	ld (xwa), e
	and bc, 0x1FFF
	jr SLIDE_Decompress_8K_Continue

SLIDE_Decompress_8K_CopyMatch:
	cp xhl, xix
	jr nc, SLIDE_Decompress_8K_Done
	ld_spib A, 0x34
	extz wa
	ldfr_werp WA, 0x32
	cp xhl, xix
	jr nc, SLIDE_Decompress_8K_Done
	ld_spib A, 0x34
	ldfr_berp A, 0xF8
	extz iz
	ld wa, iz
	and wa, 0xF8
	sll wa, 5
	ex_werp WA, 0x32
	or_werp WA, 0x32
	ex_werp WA, 0x32
	and iz, 0x7
	inc 2, iz
	lds iy, 0
	cps iz, 0
	jr c, SLIDE_Decompress_8K_Continue

SLIDE_Decompress_8K_CopyLoop:
	ldto_werp WA, 0x32
	add wa, iy
	and wa, 0x1FFF
	extz xwa
	addda32 xwa, 1570
	ld a, (xwa)
	extz wa
	ld e, a
	lda_dpi XIY, 0x38
	inc 1, xhl
	ld wa, bc
	inc 1, bc
	extz xwa
	addda32 xwa, 1570
	ld (xwa), e
	and bc, 0x1FFF
	inc 1, iy
	cp iy, iz
	jr ule, SLIDE_Decompress_8K_CopyLoop

SLIDE_Decompress_8K_Continue:
	cp xhl, xix
	jrl c, SLIDE_Decompress_8K_MainLoop

SLIDE_Decompress_8K_Done:
	ldda32 xwa, 1570
	push xwa
	call Free
	inc 4, xsp
	popw iz
	ret

SLIDE_Parse_Header:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), xbc
	ld xiz, xwa
	ld xiy, 0xE00032	; "SLIDE"
	lda xix, (xsp + 4)
	lds bc, 3
	ldirw
	pushw 0x5	; string length: 5 bytes
	lda xwa, (xsp + 6)
	push xwa
	push xiz
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, SLIDE_Parse_NotFound
	lda xwa, (xiz + 5)
	ld xiz, xwa
	ld a, (xwa)
	cp a, 0x34
	jr nz, SLIDE_Parse_Check8K
	inc 2, xiz
	ld xwa, xiz
	ld xbc, (xsp + 10)
	calr SLIDE_Decompress_4K_Init

SLIDE_Parse_ReturnOK:
	lds hl, 0
	jr SLIDE_Parse_Return

SLIDE_Parse_Check8K:
	cp a, 0x38
	jr nz, SLIDE_Parse_ReturnOK
	inc 2, xiz
	ld xwa, xiz
	ld xbc, (xsp + 10)
	calr SLIDE_Decompress_8K_Init
	jr SLIDE_Parse_ReturnOK

SLIDE_Parse_NotFound:
	ldw hl, 0xFFFF

SLIDE_Parse_Return:
	pop xiz
	lda xsp, (xsp + 10)
	ret

FDC_InitRecalibrate:
	lda xsp, (xsp - 16)
	lda xbc, (xsp)
	ldw (xbc), 0x0
	ldw (xbc + 2), 0x0
	ldw (xbc + 4), 0x0
	ldw (xbc + 6), 0xD3
	ldw (xbc + 8), 0x1
	ldw (xbc + 10), 0x1
	lds32 xwa, 0
	ld (xbc + 12), xwa
	push xbc
	call FDC_CommandEntry
	lda xsp, (xsp + 20)
	ret

FDC_SetupSectorParams:
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), bc
	ld (xsp + 14), xwa
	ld xwa, (xsp + 14)
	ld xbc, 0x12
	call Math_DivideU32
	ldada xiz, 1582
	ldw (xiz + 2), 0x0
	ld wa, hl
	srl wa, 1
	ld (xiz + 6), wa
	and hl, 0x1
	ld (xiz + 4), hl
	lda xwa, (xiz + 8)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 14)
	ld xbc, 0x12
	call DivMod32
	inc 1, xhl
	ld xwa, (xsp + 4)
	ld (xwa), hl
	ld wa, (xsp + 12)
	ld (xiz + 10), wa
	ld xwa, (xsp + 8)
	ld (xiz + 12), xwa
	pop xiz
	lda xsp, (xsp + 14)
	ret

FDC_ReadSectors:
	dec 6, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), bc
	ld xiz, xwa

FDC_ReadSectors_Retry:
	ld xwa, xiz
	ld bc, (xsp + 8)
	ld xde, (xsp + 4)
	calr FDC_SetupSectorParams
	ldada xwa, 1582
	ldw (xwa), 0x3
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr z, FDC_ReadSectors_Done
	calr FDC_InitRecalibrate
	jr FDC_ReadSectors_Retry

FDC_ReadSectors_Done:
	pop xiz
	inc 6, xsp
	ret

Detect_Disk_Type:
	dec 2, xsp
	push xiz
	ld (xsp + 4), 0xFF
	pushw 0x200
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, 0x21
	lds bc, 1
	ld xde, xiz
	calr FDC_ReadSectors
	pushw 0x26	; string length
	pushw 0xE0
	pushw 0x38	; "Technics KN5000 Program  DATA FILE 1/2"
	push xiz
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, DetectDisk_CheckProgram2of2
	ld (xsp + 4), 0x1
	jrl DetectDisk_FreeBufAndReturn

DetectDisk_CheckProgram2of2:
	pushw 0x26	; string length
	pushw 0xE0
	pushw 0x60	; "Technics KN5000 Program  DATA FILE 2/2"
	push xiz
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, DetectDisk_CheckTable1of2
	ld (xsp + 4), 0x2
	jrl DetectDisk_FreeBufAndReturn

DetectDisk_CheckTable1of2:
	pushw 0x26	; string length
	pushw 0xE0
	pushw 0xB0	; "Technics KN5000 Table    DATA FILE 1/2"
	push xiz
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, DetectDisk_CheckTable2of2
	ld (xsp + 4), 0x3
	jrl DetectDisk_FreeBufAndReturn

DetectDisk_CheckTable2of2:
	pushw 0x26	; string length
	pushw 0xE0
	pushw 0xD8	; "Technics KN5000 Table    DATA FILE 2/2"
	push xiz
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, DetectDisk_CheckCmpCustom
	ld (xsp + 4), 0x4
	jr DetectDisk_FreeBufAndReturn

DetectDisk_CheckCmpCustom:
	pushw 0x26	; string length
	pushw 0xE0
	pushw 0x128	; "Technics KN5000 CMPCUSTOMDATA FILE"
	push xiz
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, DetectDisk_CheckHDAEPRG
	ld (xsp + 4), 0x5
	jr DetectDisk_FreeBufAndReturn

DetectDisk_CheckHDAEPRG:
	pushw 0x26	; string length
	pushw 0xE0
	pushw 0x150	; "Technics KN5000 HD-AEPRG DATA FILE"
	push xiz
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, DetectDisk_CheckProgramPCK
	ld (xsp + 4), 0x6
	jr DetectDisk_FreeBufAndReturn

DetectDisk_CheckProgramPCK:
	pushw 0x26	; string length
	pushw 0xE0
	pushw 0x88	; "Technics KN5000 Program  DATA FILE PCK"
	push xiz
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, DetectDisk_CheckTablePCK
	ld (xsp + 4), 0x7
	jr DetectDisk_FreeBufAndReturn

DetectDisk_CheckTablePCK:
	pushw 0x26	; string length
	pushw 0xE0
	pushw 0x100	; "Technics KN5000 Table    DATA FILE PCK"
	push xiz
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, DetectDisk_FreeBufAndReturn
	ld (xsp + 4), 0x8

DetectDisk_FreeBufAndReturn:
	push xiz
	call Free
	inc 4, xsp
	ld l, (xsp + 4)
	pop xiz
	inc 2, xsp
	ret

FDC_WriteSectors:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 14), xbc
	ld (xsp + 18), wa
	ld wa, (xsp + 18)
	ld (xsp + 6), wa
	ld wa, (xsp + 6)
	extz xwa
	div wa, 0x12
	ldto_werp WA, 0xE2
	lds iz, 0
	cps wa, 0
	jr z, FDC_WriteSectors_FullTracks
	ldw iz, 0x12
	sub iz, wa
	ld wa, (xsp + 6)
	extz xwa
	ld bc, iz
	ld xde, 0x69800
	calr FDC_ReadSectors
	lda_24 xwa, 0x069800
	ld (xsp + 10), xwa
	ldi_werp 0xFA, 0
	jr FDC_WriteSectors_TrackLoopCheck

FDC_WriteSectors_TrackLoop:
	ld xwa, (xsp + 14)
	st_dpib A, 0xE2
	ld (xsp + 14), xwa
	ld xwa, xbc
	ld xde, (xsp + 10)
	ld_spil XBC, 0xEA
	ld (xsp + 10), xde
	call Flash_ProgramByte
	inc1_werp 0xFA

FDC_WriteSectors_TrackLoopCheck:
	ld bc, iz
	sla bc, 7
	ldto_werp WA, 0xFA
	cp wa, bc
	jr c, FDC_WriteSectors_TrackLoop

FDC_WriteSectors_FullTracks:
	add (xsp + 6), iz
	ldw (xsp + 8), 0x800
	sub (xsp + 8), iz
	ld wa, (xsp + 8)
	exts xwa
	divs wa, 0x12
	ld (xsp + 8), wa
	ldw (xsp + 4), 0x0
	ld wa, (xsp + 8)
	cps wa, 0
	jr ule, FDC_WriteSectors_Remainder

FDC_WriteSectors_FullTrackOuter:
	ld wa, (xsp + 6)
	extz xwa
	ldw bc, 0x12
	ld xde, 0x69800
	calr FDC_ReadSectors
	addmi16 (xsp + 6), 0x12
	lda_24 xwa, 0x069800
	ld (xsp + 10), xwa
	ldi_werp 0xFA, 0

FDC_WriteSectors_FullTrackInner:
	ld xwa, (xsp + 14)
	st_dpib A, 0xE2
	ld (xsp + 14), xwa
	ld xwa, xbc
	ld xde, (xsp + 10)
	ld_spil XBC, 0xEA
	ld (xsp + 10), xde
	call Flash_ProgramByte
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x00, 0x09
	jr c, FDC_WriteSectors_FullTrackInner
	incm 1, (xsp + 4)
	ld wa, (xsp + 8)
	cp (xsp + 4), wa
	jr c, FDC_WriteSectors_FullTrackOuter

FDC_WriteSectors_Remainder:
	ld wa, (xsp + 18)
	add wa, 0x800
	sub wa, (xsp + 6)
	ld iz, wa
	cps iz, 0
	jr z, FDC_WriteSectors_Return
	ld wa, (xsp + 6)
	extz xwa
	ld bc, iz
	ld xde, 0x69800
	calr FDC_ReadSectors
	lda_24 xwa, 0x069800
	ld (xsp + 10), xwa
	ldi_werp 0xFA, 0
	jr FDC_WriteSectors_RemainderCheck

FDC_WriteSectors_RemainderLoop:
	ld xwa, (xsp + 14)
	st_dpib A, 0xE2
	ld (xsp + 14), xwa
	ld xwa, xbc
	ld xde, (xsp + 10)
	ld_spil XBC, 0xEA
	ld (xsp + 10), xde
	call Flash_ProgramByte
	inc1_werp 0xFA

FDC_WriteSectors_RemainderCheck:
	ld bc, iz
	sla bc, 7
	ldto_werp WA, 0xFA
	cp wa, bc
	jr c, FDC_WriteSectors_RemainderLoop

FDC_WriteSectors_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

FDC_WriteSectors_Compressed:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 14), xde
	ld (xsp + 18), bc
	ld (xsp + 20), a
	ld wa, (xsp + 18)
	ld (xsp + 6), wa
	ld wa, (xsp + 6)
	extz xwa
	div wa, 0x12
	ldto_werp WA, 0xE2
	lds iz, 0
	cps wa, 0
	jr z, FDC_WriteCompressed_FullTracks
	ldw iz, 0x12
	sub iz, wa
	ld wa, (xsp + 6)
	extz xwa
	ld bc, iz
	ld xde, 0x69800
	calr FDC_ReadSectors
	lda_24 xwa, 0x069800
	ld (xsp + 10), xwa
	ldi_werp 0xFA, 0
	jr FDC_WriteCompressed_PartialTrackCheck

FDC_WriteCompressed_PartialTrackLoop:
	ld a, (xsp + 20)
	extz wa
	ld xbc, (xsp + 14)
	st_dpib B, 0xE5
	ld (xsp + 14), xbc
	ld xbc, xde
	ld xhl, (xsp + 10)
	ld_spiw DE, 0xED
	ld (xsp + 10), xhl
	call Flash_ProgramWord
	inc1_werp 0xFA

FDC_WriteCompressed_PartialTrackCheck:
	ld bc, iz
	sla bc, 8
	ldto_werp WA, 0xFA
	cp wa, bc
	jr c, FDC_WriteCompressed_PartialTrackLoop

FDC_WriteCompressed_FullTracks:
	add (xsp + 6), iz
	ld wa, iz
	ld bc, (xsp + 26)
	sub bc, wa
	extz xbc
	div bc, 0x12
	ld (xsp + 8), bc
	ldw (xsp + 4), 0x0
	ld wa, (xsp + 8)
	cps wa, 0
	jr ule, FDC_WriteCompressed_Remainder

FDC_WriteCompressed_FullTrackOuter:
	ld wa, (xsp + 6)
	extz xwa
	ldw bc, 0x12
	ld xde, 0x69800
	calr FDC_ReadSectors
	addmi16 (xsp + 6), 0x12
	lda_24 xwa, 0x069800
	ld (xsp + 10), xwa
	ldi_werp 0xFA, 0

FDC_WriteCompressed_FullTrackInner:
	ld a, (xsp + 20)
	extz wa
	ld xbc, (xsp + 14)
	st_dpib B, 0xE5
	ld (xsp + 14), xbc
	ld xbc, xde
	ld xhl, (xsp + 10)
	ld_spiw DE, 0xED
	ld (xsp + 10), xhl
	call Flash_ProgramWord
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x00, 0x12
	jr c, FDC_WriteCompressed_FullTrackInner
	incm 1, (xsp + 4)
	ld wa, (xsp + 8)
	cp (xsp + 4), wa
	jr c, FDC_WriteCompressed_FullTrackOuter

FDC_WriteCompressed_Remainder:
	ld wa, (xsp + 18)
	add wa, (xsp + 26)
	sub wa, (xsp + 6)
	ld iz, wa
	cps iz, 0
	jr z, FDC_WriteCompressed_Return
	ld wa, (xsp + 6)
	extz xwa
	ld bc, iz
	ld xde, 0x69800
	calr FDC_ReadSectors
	lda_24 xwa, 0x069800
	ld (xsp + 10), xwa
	ldi_werp 0xFA, 0
	jr FDC_WriteCompressed_RemainderCheck

FDC_WriteCompressed_RemainderLoop:
	ld a, (xsp + 20)
	extz wa
	ld xbc, (xsp + 14)
	st_dpib B, 0xE5
	ld (xsp + 14), xbc
	ld xbc, xde
	ld xhl, (xsp + 10)
	ld_spiw DE, 0xED
	ld (xsp + 10), xhl
	call Flash_ProgramWord
	inc1_werp 0xFA

FDC_WriteCompressed_RemainderCheck:
	ld bc, iz
	sla bc, 8
	ldto_werp WA, 0xFA
	cp wa, bc
	jr c, FDC_WriteCompressed_RemainderLoop

FDC_WriteCompressed_Return:
	pop xiz
	lda xsp, (xsp + 18)
	retd 0x2

SHOW_FD_TO_FLASH_MEMORY_MESSAGE:
	pushw 0x8
	pushw 0x2
	ld xwa, 0xE0065E	; "FD -> Flash Memory"
	ldw bc, 0x30
	ldw de, 0xA0
	call Draw_FlashMemUpdate_message_bitmap
	ret

FirmwareUpdate_SaveDiskType:
	dec 2, xsp
	ld (xsp), a

SHOW_CHANGE_FLOPPY_2_OF_2_MESSAGE:
	pushw 0x8
	pushw 0x2
	ld xwa, 0xE00D96	; "Change FD (2/2)"
	ldw bc, 0x30
	ldw de, 0xA0
	call Draw_FlashMemUpdate_message_bitmap
	call Check_for_Floppy_Disk_Change
	cps l, 0
	jr z, FloppyChange_DiskRemoved

FloppyChange_WaitDiskRemove_Loop:
	call Check_for_Floppy_Disk_Change
	cps l, 0
	jr nz, FloppyChange_WaitDiskRemove_Loop

FloppyChange_DiskRemoved:
	lds32 xwa, 0

FloppyChange_Debounce1_Loop:
	inc 1, xwa
	cp xwa, 0x40000
	jr c, FloppyChange_Debounce1_Loop
	call Check_for_Floppy_Disk_Change
	cps l, 0
	jr nz, FloppyChange_DiskInserted

FloppyChange_WaitDiskInsert_Loop:
	call Check_for_Floppy_Disk_Change
	cps l, 0
	jr z, FloppyChange_WaitDiskInsert_Loop

FloppyChange_DiskInserted:
	lds32 xwa, 0

FloppyChange_Debounce2_Loop:
	inc 1, xwa
	cp xwa, 0x200000
	jr c, FloppyChange_Debounce2_Loop
	calr Detect_Disk_Type
	cp l, (xsp)
	jr nz, SHOW_CHANGE_FLOPPY_2_OF_2_MESSAGE
	calr SHOW_FD_TO_FLASH_MEMORY_MESSAGE
	inc 2, xsp
	ret

Flash_BurnWithProgress:
	pushw iz
	ldw iz, 0x32
	lds32 xwa, 0
	stda32 1033, xwa
	call HDAE5000_Flash_Verify
	call HDAE5000_Status_Check
	cp hl, 0xFFFF
	jr nz, FlashBurn_Done

FlashBurn_ProgressLoop:
	ldda32 xwa, 1033
	cp xwa, 0x1F4
	jr ule, FlashBurn_CheckDone
	inc 8, iz
	ld wa, iz
	ldw bc, 0xB4
	lds de, 5
	call VRAM_FillRect
	lds32 xwa, 0
	stda32 1033, xwa

FlashBurn_CheckDone:
	call HDAE5000_Status_Check
	cp hl, 0xFFFF
	jr z, FlashBurn_ProgressLoop

FlashBurn_Done:
	popw iz
	ret

Erase_and_Burn____when_disk_is_valid:
	dec 2, xsp
	ld (xsp), a
	pushw 0x8
	pushw 0x2
	ld xwa, 0xE003F6	; "Now Erasing!!"
	ldw bc, 0x30
	ldw de, 0xA0
	call Draw_FlashMemUpdate_message_bitmap
	ld a, (xsp)
	extz wa
	dec 1, wa
	cps wa, 0
	jrl lt, SHOW_ILLEGAL_DISK_MESSAGE
	cps wa, 7
	jrl gt, SHOW_ILLEGAL_DISK_MESSAGE
	add wa, wa
	lda_24 xix, 0xe00178
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xef4784
	jp_dri 8, 0x07, 0xF0, 0xE0


; "Technics KN5000 Program DATA FILE 1/2"
HANDLE_UPDATE_FILE_TYPE_ID_001h:
	calr Flash_BurnWithProgress
	calr SHOW_FD_TO_FLASH_MEMORY_MESSAGE
	ldw wa, 0x24
	ld xbc, 0x800000
	calr FDC_WriteSectors
	lds wa, 2
	calr FirmwareUpdate_SaveDiskType
	ldw wa, 0x24
	ld xbc, 0x900000
	jr UpdateFile_WriteSectors_AndCleanup


; "Technics KN5000 Table DATA FILE 1/2"
HANDLE_UPDATE_FILE_TYPE_ID_003h:
	calr Flash_BurnWithProgress
	calr SHOW_FD_TO_FLASH_MEMORY_MESSAGE
	ldw wa, 0x24
	ld xbc, 0x800000
	calr FDC_WriteSectors
	lds wa, 4
	calr FirmwareUpdate_SaveDiskType
	ldw wa, 0x24
	ld xbc, 0x900000

UpdateFile_WriteSectors_AndCleanup:
	calr FDC_WriteSectors
	jr UpdateFile_StackCleanup


; "Technics KN5000 CMPCUSTOMDATA FILE"
HANDLE_UPDATE_FILE_TYPE_ID_005h:
	lds wa, 1
	call Flash_WaitUntilReady
	calr SHOW_FD_TO_FLASH_MEMORY_MESSAGE
	pushw 0x800
	lds wa, 1
	ldw bc, 0x24
	ld xde, 0x300000	; "custom_data" 8MBit FLASH ROM @ IC19
	jr UpdateFile_WriteCompressed_AndCleanup


; "Technics KN5000 HD-AEPRG DATA FILE"
HANDLE_UPDATE_FILE_TYPE_ID_006h:
	lds wa, 2
	call Flash_WaitUntilReady
	calr SHOW_FD_TO_FLASH_MEMORY_MESSAGE
	pushw 0x400
	lds wa, 2
	ldw bc, 0x24
	ld xde, 0x280000

UpdateFile_WriteCompressed_AndCleanup:
	calr FDC_WriteSectors_Compressed
	jr UpdateFile_StackCleanup


; "Technics KN5000 Program DATA FILE PCK"
HANDLE_UPDATE_FILE_TYPE_ID_007h:
	lds wa, 1
	ld xbc, 0x3E0000
	call Flash_EraseSectorWithBankSelect
	lds wa, 1
	ld xbc, 0x3F0000
	call Flash_EraseSectorWithBankSelect
	calr Flash_BurnWithProgress
	calr SHOW_FD_TO_FLASH_MEMORY_MESSAGE
	calr LZ_Decompress_Init
	calr LZSS_Decompress_ToFlash
	jr UpdateFile_StackCleanup


; "Technics KN5000 Table DATA FILE PCK"
HANDLE_UPDATE_FILE_TYPE_ID_008h:
	calr Flash_BurnWithProgress
	calr SHOW_FD_TO_FLASH_MEMORY_MESSAGE
	calr LZ_Decompress_Init

UpdateFile_StackCleanup:
	inc 2, xsp
	ret


; "Technics KN5000 Program DATA FILE 2/2" or "Technics KN5000 Table DATA FILE 2/2"
SHOW_ILLEGAL_DISK_MESSAGE:
	pushw 0x8
	pushw 0x2
	ld xwa, 0xE00FFE	; "Illegal Disk!"
	ldw bc, 0x30
	ldw de, 0xA0
	call Draw_FlashMemUpdate_message_bitmap
	inc 2, xsp

IllegalDisk_HaltLoop:
	jr IllegalDisk_HaltLoop

BusyWait_XWA_Cycles:
	lds32 xbc, 0
	cp xbc, xwa
	ret nc

BusyWait_Loop:
	inc 1, xbc
	cp xbc, xwa
	jr c, BusyWait_Loop
	ret

LED_CyclePattern:
	incdi8 1, 1574
	ldda8 a, 1574
	and a, 0x3
	cps a, 3
	jr z, LED_CyclePattern_Phase3
	cps a, 2
	jr z, LED_CyclePattern_Phase2
	cps a, 1
	jr z, LED_CyclePattern_Phase1
	cps a, 0
	jr nz, PortWrite_BusyWait
	sti8_24 0x160004, 0x01
	jr PortWrite_BusyWait

LED_CyclePattern_Phase1:
	sti8_24 0x160004, 0x02
	jr PortWrite_BusyWait

LED_CyclePattern_Phase2:
	sti8_24 0x160004, 0x04
	jr PortWrite_BusyWait

LED_CyclePattern_Phase3:
	sti8_24 0x160004, 0x08

PortWrite_BusyWait:
	ld xwa, 0x186A0
	jr BusyWait_XWA_Cycles

LED_Toggle_Bit2_Loop:
	chgda_24 2, 1441796
	ld xwa, 0x249F0
	calr BusyWait_XWA_Cycles
	jr LED_Toggle_Bit2_Loop

LED_Toggle_Bit3_Loop:
	chgda_24 3, 1441796
	ld xwa, 0x249F0
	calr BusyWait_XWA_Cycles
	jr LED_Toggle_Bit3_Loop

; ===========================================================================
; TableData_ROM_Verify - Verify Table Data ROM integrity via checksum
; ===========================================================================
; Entry: XWA = start address, XBC = end address
; Exit:  XHL = 0 if valid, non-zero address of first bad block if invalid
; Notes: Scans ROM in 64-byte blocks checking for erased (0xFFFFFFFF) markers
;        Used during boot to verify Table Data ROM contents
; ===========================================================================
TableData_ROM_Verify:
	ld xhl, xwa
	ld xde, (xhl)
	cp xde, 0xFFFFFFFF
	ret nz

TableData_ROM_Verify_NextBlock:
	lda xhl, (xhl + 64)
	cp xhl, xbc
	jr nz, TableData_ROM_Verify_CheckBlock
	lds32 xhl, 0
	ret

TableData_ROM_Verify_CheckBlock:
	ld xde, (xhl)
	cp xde, 0xFFFFFFFF
	jr z, TableData_ROM_Verify_NextBlock
	ret

; ===========================================================================
; HDAE5000_ROM_Transfer - Transfer HDAE5000 ROM data to working memory
; ===========================================================================
; Entry: XWA = source address (Table Data ROM)
;        XBC = destination address (HDAE5000 ROM space)
;        DE = starting block index
;        Stack+4 = block count
; Exit:  XHL = 0 on success, non-zero on verify failure
; Notes: Transfers data in blocks via HDAE5000 PPI at 0x160000
;        Block index written to PORT_A for each 256KB block
;        Verifies each word transferred matches source
; ===========================================================================
HDAE5000_ROM_Transfer:
	ld xhl, xwa
	ld w, e
	ld a, (xsp + 4)
	cp w, a
	jr ugt, HDAE5000_ROM_Transfer_Success

HDAE5000_ROM_Transfer_BlockLoop:
	st8_24 0x160000, w
	ld xix, xbc
	ld xiy, 0x3FFFF

HDAE5000_ROM_Transfer_WordLoop:
	ld_spiw DE, 0xF1
	cp_spiw DE, 0xED
	jr nz, HDAE5000_ROM_Transfer_Return
	ld xde, xiy
	dec 1, xiy
	or xde, xde
	jr nz, HDAE5000_ROM_Transfer_WordLoop
	inc 1, w
	cp w, a
	jr ule, HDAE5000_ROM_Transfer_BlockLoop

HDAE5000_ROM_Transfer_Success:
	lds32 xhl, 0

HDAE5000_ROM_Transfer_Return:
	retd 0x2
	lda xsp, (xsp - 10)
	push xiz
	lda_24 xwa, 0x300000
	ld (xsp + 8), xwa
	ld (xsp + 12), 0x0

HDAE5000_FlashWrite_BankLoop:
	ld a, (xsp + 12)
	st8_24 0x160000, a
	lda_24 xwa, 0x200000
	ld (xsp + 4), xwa
	lds32 xiz, 0

HDAE5000_FlashWrite_WordLoop:
	ld xwa, (xsp + 8)
	st_dpib A, 0xE1
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	ld_spiw DE, 0xE1
	ld (xsp + 4), xwa
	lds wa, 1
	call Flash_ProgramWord
	inc 1, xiz
	cp xiz, 0x40000
	jr c, HDAE5000_FlashWrite_WordLoop
	incm8 1, (xsp + 12)
	cp (xsp + 12), 0x2
	jr c, HDAE5000_FlashWrite_BankLoop
	pop xiz
	lda xsp, (xsp + 10)
	ret

HDAE5000_FlashVerify_BytecodeBlock:
	lda	xsp, (xsp-10)
	push	xiz
	ld	xwa, 8388608
	ld	(xsp+8), xwa
	ld	(xsp+12), 0
	ld	a, (xsp+12)
	st8_24	1441792, a
	lda_24	xwa, 2621440
	ld	(xsp+4), xwa
	lds32	xiz, 0
	ld	xwa, (xsp+8)
	.byte 0xf5, 0xe2, 0x31
	ld	(xsp+8), xwa
	ld	xwa, xbc
	ld	xde, (xsp+4)
	ld_spil	xbc, 234
	ld	(xsp+4), xde
	call	15678843
	inc	1, xiz
	cp	xiz, 131072
	jr	c, -34
	incm8	1, (xsp+12)
	cp	(xsp+12), 4
	jr	c, -61
	pop	xiz
	lda	xsp, (xsp+10)
	ret

HDAE5000_TableData_Write:
	lda xsp, (xsp - 10)
	push xiz
	ld xwa, 0x800000
	ld (xsp + 8), xwa
	ld (xsp + 12), 0x4

HDAE5000_TableData_BankLoop:
	ld a, (xsp + 12)
	st8_24 0x160000, a
	lda_24 xwa, 0x280000
	ld (xsp + 4), xwa
	lds32 xiz, 0

HDAE5000_TableData_WordLoop:
	ld xwa, (xsp + 8)
	st_dpib A, 0xE2
	ld (xsp + 8), xwa
	ld xwa, xbc
	ld xde, (xsp + 4)
	ld_spil XBC, 0xEA
	ld (xsp + 4), xde
	call Flash_ProgramByte
	inc 1, xiz
	cp xiz, 0x20000
	jr c, HDAE5000_TableData_WordLoop
	incm8 1, (xsp + 12)
	cp (xsp + 12), 0x8
	jr c, HDAE5000_TableData_BankLoop
	pop xiz
	lda xsp, (xsp + 10)
	ret

HDAE5000_Init_BytecodeBlock:
	.byte 0xd7, 0xfa, 0x04, 0xc7, 0xfb, 0xa8, 0x08, 0xe4
	.long LABEL_E00800
	ldio	237, 0
	ldio	227, 0
	ldio	235, 0
	stdi8	340, 102
	sti8_24	1441798, 130
	sti8_24	1441792, 0
	sti8_24	1441796, 0
	sti8_24	1441796, 15
	ld	xwa, 900000
	calr	-494
	sti8_24	1441796, 0
	ld8_24	a, 1441794
	extz	wa
	bit	0, wa
	jr	nz, -12
	call	15678734
	cp	xhl, 4294967295
	jr	nz, 8
	setda_24	2, 1441796
	ldi_berp	251, 1
	lds	wa, 1
	call	15677338
	cp	hl, 65535
	jr	nz, 10
	setda_24	3, 1441796
	ldi_berp	251, 1
	jr	8
	cpi_berp	251, 1
	jr	nz, 5
	pop qiz
	jr	-2
	sti8_24	1441796, 0
	ld	xwa, 8388608
	ld	xbc, 10485760
	calr	-476
	or	xhl, xhl
	.byte 0xf2, 0xbb, 0x3d, 0xef, 0xee
	lda_24	xwa, 3145728
	ld	xbc, xwa
	add	xbc, 1048576
	calr	-499
	or	xhl, xhl
	jr	z, 6
	lds	wa, 1
	call	15677562
	call	15679273
	cp	hl, 65535
	jr	nz, 13
	calr	-616
	call	15679273
	cp	hl, 65535
	jr	z, -13
	sti8_24	1441796, 0
	setda_24	0, 1441796
	calr	-381
	resda_24	0, 1441796
	ld	xwa, 900000
	calr	-666
	setda_24	0, 1441796
	calr	-484
	resda_24	0, 1441796
	setda_24	1, 1441796
	pushw 3
	ld	xwa, 8388608
	ld	xbc, 2621440
	lds	de, 0
	calr	-562
	or	xhl, xhl
	.byte 0xf2, 0x90, 0x48, 0xef, 0xee
	pushw 1
	ld	xwa, 3145728
	ld	xbc, 2097152
	lds	de, 0
	calr	-587
	or	xhl, xhl
	.byte 0xf2, 0x9f, 0x48, 0xef, 0xee
	sti8_24	1441792, 7
	ld32_24	xwa, 3145664
	.byte 0xe8, 0xcf, 0x68
	.ascii "kt_f"
	.byte 0x05, 0xd7, 0xfa, 0x05
	.byte 0x68, 0xfe, 0x06, 0x07, 0x40, 0xd8, 0xfe, 0xff
	.byte 0x00, 0x34, 0x4b, 0x01, 0xec, 0x12, 0xe9, 0xee
	.long SeqCh_SystemHandlerData
	.byte 0xb4, 0x00, 0x80, 0xb0
	.byte 0xd8, 0xd7, 0xfa, 0x05, 0x0e

HDAE5000_Init_DetectAndVerify:
	sti8_24 0x160004, 0x00
	call HDAE5000_Detect
	cp xhl, 0xFFFFFFFF
	jr nz, HDAE5000_Init_VerifyROM
	setda_24 2, 1441796

Infinite_Loop_at_EF4B6B:
	jr Infinite_Loop_at_EF4B6B

HDAE5000_Init_VerifyROM:
	ld xwa, 0x800000
	ld xbc, 0xA00000
	calr TableData_ROM_Verify
	or xhl, xhl
	jr z, HDAE5000_Init_TransferData
	call HDAE5000_Flash_Verify
	call HDAE5000_Status_Check
	cp hl, 0xFFFF
	jr nz, HDAE5000_Init_TransferData

HDAE5000_Init_WaitFlashReady:
	calr LED_CyclePattern
	sti8_24 0x160004, 0x00
	call HDAE5000_Status_Check
	cp hl, 0xFFFF
	jr z, HDAE5000_Init_WaitFlashReady

HDAE5000_Init_TransferData:
	setda_24 0, 1441796
	calr HDAE5000_TableData_Write
	resda_24 0, 1441796
	setda_24 1, 1441796
	pushw 0x7
	ld xwa, 0x800000
	ld xbc, 0x280000
	lds de, 4
	calr HDAE5000_ROM_Transfer
	or xhl, xhl
	call_24 nz, 0xEF4890

HDAE5000_Init_HaltLoop:
	jr HDAE5000_Init_HaltLoop

HDAE5000_Parport_Setup:
	stdi8 340, 102
	sti8_24 0x160006, 0x82
	sti8_24 0x160000, 0x00
	sti8_24 0x160004, 0x00
	sti8_24 0x160004, 0x0f
	ld xwa, 0xDBBA0
	calr BusyWait_XWA_Cycles
	sti8_24 0x160004, 0x00

Parport_WaitDataReady:
	ld8_24 a, 0x160002
	extz wa
	bit 0, wa
	jr nz, Parport_WaitDataReady
	jrl HDAE5000_Init_DetectAndVerify
	ret

Parport_ReadNextByte:
	pushw iz
	ldda32 xwa, 1602
	cpda32 xwa, 1598
	jr c, Parport_ReadByte_FromBuffer
	ldw hl, 0xFFFF
	jr Parport_ReadByte_Return

Parport_ReadByte_FromBuffer:
	lda_24 xwa, 0x069800
	add xwa, 0x9000
	cpda32 xwa, 1610
	jr nz, Parport_ReadByte_Emit
	incdi16 8, 1614
	ldda16 xwa, 1614
	ldda16 xbc, 1616
	lds de, 6
	call VRAM_FillRect
	lds iz, 0

Parport_RefillBuffer_Loop:
	ldda16 xwa, 1618
	extz xwa
	ldw bc, 0x2400
	mul xbc, xiz
	ld xde, 0x69800
	add xde, xbc
	ldw bc, 0x12
	calr FDC_ReadSectors
	adddi16 1618, 18
	inc 1, iz
	cps iz, 4
	jr c, Parport_RefillBuffer_Loop
	lda_24 xwa, 0x069800
	stda32 1610, xwa

Parport_ReadByte_Emit:
	ldda32 xwa, 1610
	st_dpib A, 0xE0
	stda32 1610, xwa
	ld l, (xbc)
	extz hl

Parport_ReadByte_Return:
	popw iz
	ret

Flash_AccumWrite_Byte:
	ldda8 e, 1620
	extz de
	ldada xbc, 1576
	extz xde
	add xde, xbc
	ld (xde), a
	ldda8 a, 1620
	ld e, a
	inc 1, a
	stda8 1620, a
	cps e, 3
	jr nz, Flash_AccumWrite_ByteDone
	ldda32 xwa, 1606
	st_dpib B, 0xE2
	stda32 1606, xwa
	ld xbc, (xbc)
	ld xwa, xde
	call Flash_ProgramByte
	stdi8 1620, 0

Flash_AccumWrite_ByteDone:
	lds32 xwa, 1
	adddm32 1602, xwa
	ret

Flash_AccumWrite_Word:
	ldda8 c, 1620
	extz bc
	ldada xde, 1580
	extz xbc
	add xbc, xde
	ld (xbc), a
	ldda8 a, 1620
	ld c, a
	inc 1, a
	stda8 1620, a
	cps c, 1
	jr nz, Flash_AccumWrite_WordDone
	ldda32 xwa, 1622
	st_dpib A, 0xE1
	stda32 1622, xwa
	ld de, (xde)
	lds wa, 1
	call Flash_ProgramWord
	stdi8 1620, 0

Flash_AccumWrite_WordDone:
	lds32 xwa, 1
	adddm32 1602, xwa
	ret

LZSS_Decompress_ToFlash:
	dec 6, xsp
	pushw iz
	stdi8 1620, 0
	lda_24 xwa, 0x300000
	add xwa, 0xE0000
	stda32 1622, xwa
	ld xwa, 0x20000
	adddm32 1598, xwa
	lds iz, 0

LZSS_Decompress_ReadHeader:
	calr Parport_ReadNextByte
	ld bc, iz
	extz xbc
	lda xwa, (xsp + 2)
	ld xde, xwa
	add xde, xbc
	ld (xde), l
	inc 1, iz
	cps iz, 6
	jr c, LZSS_Decompress_ReadHeader
	pushw 0x5	; lenght: 5 bytes
	pushw 0xE0
	pushw 0x188	; "SLIDE"
	push xwa
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr z, LZSS_Decompress_HeaderOK
	ldw hl, 0xFFFF
	jr LZSS_Decompress_Return

LZSS_Decompress_HeaderOK:
	lds iz, 0

LZSS_Decompress_StreamHeaderBytes:
	ld bc, iz
	extz xbc
	lda xwa, (xsp + 2)
	add xwa, xbc
	ld a, (xwa)
	extz wa
	calr Flash_AccumWrite_Word
	inc 1, iz
	cps iz, 6
	jr c, LZSS_Decompress_StreamHeaderBytes
	stdi16 1614, 42
	stdi16 1616, 200
	ldda32 xwa, 1602
	cpda32 xwa, 1598
	jr nc, LZSS_Decompress_ReturnOK

LZSS_Decompress_StreamData:
	calr Parport_ReadNextByte
	extz hl
	ld wa, hl
	calr Flash_AccumWrite_Word
	ldda32 xwa, 1602
	cpda32 xwa, 1598
	jr c, LZSS_Decompress_StreamData

LZSS_Decompress_ReturnOK:
	lds hl, 0

LZSS_Decompress_Return:
	popw iz
	inc 6, xsp
	ret

LZ_Decompress_Init:
	lda xsp, (xsp - 16)
	push xiz
	pushw 0x1000
	call Malloc
	inc 2, xsp
	ld (xsp + 16), xhl
	ld xwa, (xsp + 16)
	ld (xsp + 12), xwa
	lds32 xwa, 0
	stda32 1602, xwa

LZ_Decompress_ClearRing:
	ldda32 xwa, 1602
	ld xbc, (xsp + 16)
	add xbc, xwa
	ld (xbc), 0x0
	ldda32 xwa, 1602
	inc 1, xwa
	stda32 1602, xwa
	cp xwa, 0xFEE
	jr c, LZ_Decompress_ClearRing
	ldw (xsp + 10), 0xFEE
	ldw (xsp + 4), 0x0
	stdi8 1620, 0
	lds32 xwa, 0
	stda32 1602, xwa
	lda_24 xwa, 0x069800
	stda32 1610, xwa
	ld xwa, 0x800000
	stda32 1606, xwa
	stdi16 1614, 50
	stdi16 1616, 180
	ldw wa, 0x32
	ldw bc, 0xB4
	lds de, 6
	call VRAM_FillRect
	ld xwa, 0x3E8
	stda32 1598, xwa
	stdi16 1618, 36
	ldi_werp 0xFA, 0

LZ_Decompress_ReadTracks:
	ldda16 xwa, 1618
	extz xwa
	ldw bc, 0x2400
	mul_werp BC, 0xFA
	ld xde, 0x69800
	add xde, xbc
	ldw bc, 0x12
	calr FDC_ReadSectors
	adddi16 1618, 18
	inc1_werp 0xFA
	cpi_werp 0xFA, 4
	jr c, LZ_Decompress_ReadTracks
	ldi_werp 0xFA, 0

LZ_Decompress_ReadSizeField:
	calr Parport_ReadNextByte
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x08, 0x00
	jr c, LZ_Decompress_ReadSizeField
	calr Parport_ReadNextByte
	extz xhl
	sla xhl, 0
	stda32 1598, xhl
	calr Parport_ReadNextByte
	sll hl, 8
	extz xhl
	adddm32 1598, xhl
	calr Parport_ReadNextByte
	extz xhl
	ldda32 xwa, 1598
	add xwa, xhl
	stda32 1598, xwa
	cpdm32 1602, xwa
	jrl nc, LZ_Decompress_Done

LZ_Decompress_MainLoop:
	mrdw3 0x9F, 0x04, 0x7F
	ld wa, (xsp + 4)
	bit 8, wa
	jr nz, LZ_Decompress_LiteralByte
	calr Parport_ReadNextByte
	ld iz, hl
	cp iz, 0xFFFF
	jrl z, LZ_Decompress_Done
	ld (xsp + 4), iz
	ormi16 (xsp + 4), 0xFF00

LZ_Decompress_LiteralByte:
	ld wa, (xsp + 4)
	bit 0, wa
	jr z, LZ_Decompress_MatchRef
	calr Parport_ReadNextByte
	ld iz, hl
	cp iz, 0xFFFF
	jrl z, LZ_Decompress_Done
	ldto_berp A, 0xF8
	extz wa
	calr Flash_AccumWrite_Byte
	ld bc, (xsp + 10)
	incm 1, (xsp + 10)
	extz xbc
	add xbc, (xsp + 16)
	ldto_berp A, 0xF8
	ld (xbc), a
	andmi16 (xsp + 10), 0xFFF
	jr LZ_Decompress_LoopCheck

LZ_Decompress_MatchRef:
	calr Parport_ReadNextByte
	ldfr_werp HL, 0xFA
	cp_erpw 0xFA, 0xFF, 0xFF
	jr z, LZ_Decompress_Done
	calr Parport_ReadNextByte
	ld (xsp + 8), hl
	cpw (xsp + 8), 0xFFFF
	jr z, LZ_Decompress_Done
	ld bc, (xsp + 8)
	and bc, 0xF0
	sll bc, 4
	ldto_werp WA, 0xFA
	or wa, bc
	ldfr_werp WA, 0xFA
	andmi16 (xsp + 8), 0xF
	incm 2, (xsp + 8)
	ldw (xsp + 6), 0x0
	cpw (xsp + 8), 0x0
	jr c, LZ_Decompress_LoopCheck

LZ_Decompress_CopyMatchLoop:
	ldto_werp WA, 0xFA
	add wa, (xsp + 6)
	and wa, 0xFFF
	extz xwa
	add xwa, (xsp + 12)
	ld a, (xwa)
	ldfr_berp A, 0xF8
	extz iz
	ldto_berp A, 0xF8
	extz wa
	calr Flash_AccumWrite_Byte
	ld bc, (xsp + 10)
	incm 1, (xsp + 10)
	extz xbc
	add xbc, (xsp + 12)
	ldto_berp A, 0xF8
	ld (xbc), a
	andmi16 (xsp + 10), 0xFFF
	incm 1, (xsp + 6)
	ld wa, (xsp + 6)
	cp wa, (xsp + 8)
	jr ule, LZ_Decompress_CopyMatchLoop

LZ_Decompress_LoopCheck:
	ldda32 xwa, 1602
	cpda32 xwa, 1598
	jrl c, LZ_Decompress_MainLoop

LZ_Decompress_Done:
	ld xwa, (xsp + 16)
	push xwa
	call Free
	inc 4, xsp
	pop xiz
	lda xsp, (xsp + 16)
	ret

FLASH_MEM_UPDATE:
	push_werp 0xFA
	call Check_for_Floppy_Disk_Change
	cps l, 0
	jrl z, flash_update__not_today
	calr FDC_InitRecalibrate
	calr Detect_Disk_Type
	ldfr_berp L, 0xFB
	call Get_Region_Code
	cps l, 4
	jr z, Flash_CheckAndValidate
	call HDAE5000_Detect
	cp xhl, 0xFFFFFFFF
	jr z, Flash_CheckAndValidate
	cpi_berp 0xFB, 6	; Is it "HD-AEPRG DATA FILE"?
	jr z, Flash_CheckAndValidate	; yes, it is.
	pushw 0x8
	pushw 0x2
	ld xwa, 0xE0018E	; "Flash Memory Update"
	ldw bc, 0x30
	ldw de, 0x50
	call Draw_FlashMemUpdate_message_bitmap
	ldto_berp A, 0xFB
	extz wa
	calr Erase_and_Burn____when_disk_is_valid
	pushw 0x8
	pushw 0x1
	ld xwa, 0xE008C6	; "Completed!"
	ldw bc, 0x30
	ldw de, 0xA0
	call Draw_FlashMemUpdate_message_bitmap
	pushw 0x8
	pushw 0x1
	ld xwa, 0xE01266	; "Turn On AGAIN !!"
	ldw bc, 0x30
	ldw de, 0xC8
	call Draw_FlashMemUpdate_message_bitmap

Flash_CheckAndValidate:
	lds wa, 2
	call Flash_IdentifyAndValidateChip
	cp hl, 0xFFFF
	jr z, flash_update__not_today
	cpi_berp 0xFB, 6	; Is it "HD-AEPRG DATA FILE"?
	jr nz, flash_update__not_today
	pushw 0x8
	pushw 0x2
	ld xwa, 0xE0018E	; "Flash Memory Update"
	ldw bc, 0x30
	ldw de, 0x50
	call Draw_FlashMemUpdate_message_bitmap
	ldto_berp A, 0xFB
	extz wa
	calr Erase_and_Burn____when_disk_is_valid
	pushw 0x8
	pushw 0x1
	ld xwa, 0xE008C6	; "Completed!"
	ldw bc, 0x30
	ldw de, 0xA0
	call Draw_FlashMemUpdate_message_bitmap
	pushw 0x8
	pushw 0x1
	ld xwa, 0xE01266	; "Turn On AGAIN !!"
	ldw bc, 0x30
	ldw de, 0xC8
	call Draw_FlashMemUpdate_message_bitmap

flash_update__not_today:
	pop_werp 0xFA
	ret

; =============================================================================
; Draw_FlashMemUpdate_message_bitmap - Draw 224x22 monochrome bitmap
;
; Renders a 1bpp monochrome bitmap (224 pixels wide × 22 pixels tall) to the
; offscreen buffer at 0x43C00, then blits the entire buffer to VRAM.
; Used to display firmware update status messages on the LCD.
;
; The bitmap is stored as packed 1bpp data (28 bytes per row × 22 rows = 616
; bytes total). Each bit is unpacked to an 8bpp pixel using a bit mask table.
;
; Input:
;   XWA = pointer to bitmap data (24-bit, in ROM)
;   BC  = X start coordinate (left edge)
;   DE  = Y start coordinate (top edge)
;   Stack: foreground color (byte), background color (byte)
;
; Output:
;   Screen updated with rendered bitmap
; =============================================================================
Draw_FlashMemUpdate_message_bitmap:
	dec 4, xsp
	pushw iz
	ld hl, bc
	ld (xsp + 2), xwa
	ld iy, hl
	ld ix, de
	inc 1, ix
	lds iz, 0

DrawBitmap_RowLoop:
	ld wa, iz
	extz xwa
	div wa, 0x1C	; 28 bytes = 224 pixels de largura da imagem a ser desenhada
	ldto_werp WA, 0xE2
	cps wa, 0
	jr nz, DrawBitmap_CheckNewRow
	ld iy, hl	; IY = coordanada X do canto esquerdo da imagem a ser desenhada
	dec 1, ix

DrawBitmap_CheckNewRow:
	ldi_werp 0xEE, 0

DrawBitmap_BitLoop:
	ld de, iz
	extz xde
	add xde, (xsp + 2)
	ldada xwa, 58218	; table of bit masks (equivalent to 1044h on boot "table_data" rom)
	ldto_werp BC, 0xEE
	extz xbc
	add xbc, xwa	; indexing bit masks with value of QHL
	ld a, (xbc)
	and a, (xde)	; here XDE points at one of the bytes of the image we're drawing and we select the bit we need
	ldfr_berp A, 0xF2
	ld de, ix
	extz xde
	lda_24 xbc, 0x043c00                  ; aparentemente isso é um buffer offscreen

; Convert Y coordinate to framebuffer row offset: XWA = XDE * 320
; Uses shift-add: (XDE << 2 + XDE) << 6 = XDE * 5 * 64 = XDE * 320
Set_XWA_to_320_times_XDE:
	ld xwa, xde
	sll xwa, 2		; XWA = Y * 4
	add xwa, xde		; XWA = Y * 5
	sll xwa, 6		; XWA = Y * 320
	cpi_berp 0xF2, 0
	jr z, DrawBitmap_BackgroundPixel
	ld de, iy
	inc 1, iy
	extz xde
	add xwa, xde
	ld xde, xbc
	add xde, xwa
	ld a, (xsp + 10)
	ld (xde), a
	jr DrawBitmap_NextBit

DrawBitmap_BackgroundPixel:
	ld de, iy
	inc 1, iy
	extz xde
	add xwa, xde	; XWA = 320*y + x
	ld xde, xbc
	add xde, xwa	; XDE = offscreen_buffer[320*y + x]
	ld a, (xsp + 12)
	ld (xde), a

DrawBitmap_NextBit:
	inc1_werp 0xEE
	cp_erpw 0xEE, 0x08, 0x00
	jr c, DrawBitmap_BitLoop
	inc 1, iz
	cp iz, 0x268	; 28 bytes (224 pixels/line) * 22 lines = 0268h bytes
	jr c, DrawBitmap_RowLoop
	lda_24 xwa, 0x1a0000
	ldw de, 0x9600	; 2 pixels per word
	call Copy_DE_words_from_XBC_to_XWA	; <-- "blit-screen"
	popw iz
	inc 4, xsp
	retd 0x4

;=============================================================================
; VRAM_FillRect - Fill a rectangular region in video RAM with a color
;
; Fills a 12-pixel tall rectangle in video RAM (0x1A0000) with the specified
; color value. Used for clearing or highlighting UI regions.
;
; Input:
;   BC = Y start coordinate (row)
;   WA = X start coordinate (column)
;   E  = Color/pattern value (8-bit, duplicated to 16-bit)
;
; Output:
;   None (VRAM modified)
;
; Clobbers: XIZ, XHL, XWA, XDE, IX, IY
;=============================================================================
VRAM_FillRect:
	dec 6, xsp
	push xiz
	ld (xsp + 6), e	; Save color value
	ld (xsp + 8), wa	; Save X start
	ld ix, bc	; IX = Y start
	ld (xsp + 4), bc
	addmi16 (xsp + 4), 0xC	; End Y = start + 12
	cp ix, (xsp + 4)
	jr nc, VRAM_FillRect_Done

VRAM_FillRect_RowLoop:
	ld iy, (xsp + 8)	; IY = X start
	ld bc, iy
	inc 6, bc	; BC = X end (start + 6)
	cp iy, bc
	jr nc, VRAM_FillRect_NextRow

VRAM_FillRect_ColLoop:
	ld de, iy
	extz xde
	ld wa, ix
	extz xwa
	ld xhl, xwa
	sll xhl, 2
	add xhl, xwa
	sll xhl, 6
	add xhl, xde
	srl xhl, 1
	add xhl, xhl
	ld xiz, 0x1A0000
	add xiz, xhl
	ld a, (xsp + 6)
	extz wa
	ld de, wa
	sll de, 8
	or wa, de
	ld (xiz), wa
	inc 2, iy	; X += 2 (word increment)
	cp iy, bc
	jr c, VRAM_FillRect_ColLoop

VRAM_FillRect_NextRow:
	inc 1, ix	; Y++
	cp ix, (xsp + 4)
	jr c, VRAM_FillRect_RowLoop

VRAM_FillRect_Done:
	pop xiz
	inc 6, xsp
	ret

; =============================================================================
; VGA Register I/O Routines - Shared with table_data ROM
; =============================================================================
	.include "shared/vga_io.s"
