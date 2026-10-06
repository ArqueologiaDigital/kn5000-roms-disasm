; =============================================================================
; System Handlers (8K lines)
; =============================================================================
;
; Core system infrastructure: interrupt handlers (NMI, DMA, timers),
; the UI state machine, cooperative task scheduler, flash memory
; update routines, and LZSS decompression engine.
; =============================================================================


; Alias labels for backward compatibility with existing code
.equ SeqData_EF086F, Boot_CallInitHandlers
.equ SeqData_EF07A2, Boot_HandleComboDisplay
.equ SeqData_EF07F3, Boot_HandleFactoryReset

INTT2_HANDLER:
	reti

NMI_HANDLER:
	ldw (0x00ffca:24), 0x0000
	calr NMI_StorePayloadChecksums
	bit 2, (0xfdad:16)
	jr z, NMI_SetPowerOffCode_A5A5
	ldw (0x00ffcc:24), 0x5a5a
	jr NMI_ClearGuardAndHalt

NMI_SetPowerOffCode_A5A5:
	ldw (0x00ffcc:24), 0xa5a5

NMI_ClearGuardAndHalt:
	ld (1024:16), 0
	res 7, (354:16)
	set	2, (PF:8)
NMI_HaltLoop:
	halt
	jr	t, NMI_HaltLoop

; ===========================================================================
; NMI_StorePayloadChecksums - Power-off NMI: save checksums and copy payload
; ===========================================================================
; Called by: NMI_HANDLER
; Entry: Machine is powering off; NMI has been triggered by SNS signal
; Exit:  DRAM[0xFFD4] = one's-complement checksum of region 1 (0xf180, 0x800 words)
;        DRAM[0xFFD2] = one's-complement checksum of region 2 (0xf980, 0x280 words)
;        SRAM[0x1E8000..] = copy of DRAM[0xF980..]
;        CPU halts (machine powers off)
; Notes: Guards against running without being armed:
;          - Checks internal RAM[0x0400] == 0x80 (NMI guard set by Boot_DisplayScreen)
;          - If guard not set, returns immediately (no-op)
;        On success the checksums are stored so SubCPU_Payload_Verify can verify
;        the payload on the next boot and show the splash screen (not "ALL INITIAL SETTING!").
; ===========================================================================
NMI_StorePayloadChecksums:
	cp (1024:16), 128
	ret nz
	call Demo_SelectEntry_PreSaveCheck
	call SeqPlay_JumpCopyVoiceData
	ld xwa, 0xf180
	ldw bc, 0x800
	call Checksum_ComputeComplement
	ld (0x00ffd4:24), hl
	ld xwa, 0xf980
	ldw bc, 0x280
	call Checksum_ComputeComplement
	ld (0x00ffd2:24), hl
	call Seq_IsMelodyActive
	cp hl, 0:i3
	jr z, NMI_CopyPayloadToSRAM
	addw (0xffd4:24), 1000

NMI_CopyPayloadToSRAM:
	lda xde, (0x00066e:24)
	srl xde, 1
	ld xwa, 0x1e8000
	ld xbc, 0xf980
	call Copy_DE_words_from_XBC_to_XWA
	ret

; ===========================================================================
; SubCPU_Payload_Verify - Verify Sub-CPU firmware payload integrity
; ===========================================================================
; Entry: Sub-CPU firmware payload has been transferred
; Exit:  Error flag at 0x01e53e set to indicate result:
;          0x00 = Both checksums match (success)
;          0x01 = First checksum mismatch, second matches (partial error)
;          0xff = Checksum verification failed (error)
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
	ld xwa, 0xf180	; Start of payload region 1
	ldw bc, 0x800	; Size: 0x800 words
	call Checksum_ComputeComplement	; Compute checksum -> HL
	lda xwa, (0x00f980:24)
	cp hl, (0xffd4:24); Compare with expected checksum
	jr nz, SubCPU_Payload_Verify_Fail	; First region checksum failed
	ld (0x01e53e:24), 0x00; Mark as success (so far)
	ldw bc, 0x280	; Size of second region
	call Checksum_ComputeComplement	; Compute second checksum
	cp hl, (0xffd2:24); Compare with expected
	ret z	; Both match -> success
	ld (0x01e53e:24), 0xff; Second region failed
	ret

SubCPU_Payload_Verify_Fail:
	ld (0x01e53e:24), 0xff; Mark as failed
	ldw bc, 0x280
	call Checksum_ComputeComplement
	cp hl, (0xffd2:24)
	ret nz	; Both checksums wrong
	ld (0x01e53e:24), 0x01; First wrong, second correct (partial)
	ret

; ===========================================================================
; SubCPU_Payload_GetErrorFlag - Get Sub-CPU payload transfer error status
; ===========================================================================
; Entry: None
; Exit:  HL = Error flag value
;          0x0000 = Success (payload transferred correctly)
;          0xffff = Error (triggers "ERROR in CPU data transmission" dialog)
;          0x0001 = Partial error
; Notes: Called during boot to check if SubCPU_Payload_Verify detected errors.
;
; See also:
;   - SubCPU_Payload_Verify - Sets the error flag
;   - ErrorDialog_CPUTransmissionError - Error dialog shown when HL != 0
; ===========================================================================
SubCPU_Payload_GetErrorFlag:
	ld l, (0x01e53e:24)
	exts hl
	ret

SubCPU_PayloadErrorStore:
	ld (0x01e53e:24), 0xff
	ret

Sys_CheckPowerStableFlag:
	cpw (0xffcc:24), 0x5a5a
	scc16 z, hl
	ret

Vga_WritePortShortDelay:
	ld de, 0:i3

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
	ldw wa, 0x3c4
	ld bc, 6:i3
	calr Vga_WritePortShortDelay
	ldw wa, 0x3c5
	ld bc, 1:i3
	calr Vga_WritePortShortDelay
	ldw wa, 0x3c4
	ldw bc, 0x8
	calr Vga_WritePortShortDelay
	ld a, (xsp)
	sll a, 4
	set 0, a
	ld c, a
	extz bc
	ldw wa, 0x3c5
	calr Vga_WritePortShortDelay
	ldw wa, 0x3c4
	ld bc, 6:i3
	calr Vga_WritePortShortDelay
	ldw wa, 0x3c5
	ld bc, 0:i3
	calr Vga_WritePortShortDelay
	inc 2, xsp
	ret

Vga_SetupMultiPlaneDisplay:
	call Stop_and_Clear_8bit_Timer_3
	ld xwa, 0x1b4000
	ld xbc, 0xf180
	ldw de, 0x400
	call Copy_DE_words_from_XBC_to_XWA
	ld xwa, 0x1b4800
	ld xbc, SEQ_SONG_SLOTS
	ld xde, 0x5c00
	call Copy_DE_words_from_XBC_to_XWA
	ld wa, 1:i3
	calr Vga_SelectWritePlane
	lda xbc, (SEQ_SONG_SLOTS:24)
	add xbc, 0xb800
	ld xwa, 0x1a0000
	ld xde, 0x10000
	call Copy_DE_words_from_XBC_to_XWA
	ld wa, 2:i3
	calr Vga_SelectWritePlane
	lda xbc, (SEQ_SONG_SLOTS:24)
	add xbc, 0x2b800
	ld xwa, 0x1a0000
	ld xde, 0x10000
	call Copy_DE_words_from_XBC_to_XWA
	ld wa, 3:i3
	calr Vga_SelectWritePlane
	lda xbc, (SEQ_SONG_SLOTS:24)
	add xbc, 0x4b800
	ld xwa, 0x1a0000
	ldw de, 0x4c00
	call Copy_DE_words_from_XBC_to_XWA
	ld wa, 0:i3
	calr Vga_SelectWritePlane
	jp Start_8bit_Timer_3

Vga_RestoreMultiPlaneDisplay:
	call Stop_and_Clear_8bit_Timer_3
	ld xwa, 0xf180
	ld xbc, 0x1b4000
	ldw de, 0x400
	call Copy_DE_words_from_XBC_to_XWA
	ld xwa, SEQ_SONG_SLOTS
	ld xbc, 0x1b4800
	ld xde, 0x5c00
	call Copy_DE_words_from_XBC_to_XWA
	ld wa, 1:i3
	calr Vga_SelectWritePlane
	lda xwa, (SEQ_SONG_SLOTS:24)
	add xwa, 0xb800
	ld xbc, 0x1a0000
	ld xde, 0x10000
	call Copy_DE_words_from_XBC_to_XWA
	ld wa, 2:i3
	calr Vga_SelectWritePlane
	lda xwa, (SEQ_SONG_SLOTS:24)
	add xwa, 0x2b800
	ld xbc, 0x1a0000
	ld xde, 0x10000
	call Copy_DE_words_from_XBC_to_XWA
	ld wa, 3:i3
	calr Vga_SelectWritePlane
	lda xwa, (SEQ_SONG_SLOTS:24)
	add xwa, 0x4b800
	ld xbc, 0x1a0000
	ldw de, 0x4c00
	call Copy_DE_words_from_XBC_to_XWA
	ld wa, 0:i3
	calr Vga_SelectWritePlane
	jp Start_8bit_Timer_3

Vga_BackupPlane3ToBuffer:
	call Stop_and_Clear_8bit_Timer_3
	ld wa, 3:i3
	calr Vga_SelectWritePlane
	ld xwa, 0x1a9800
	ld xbc, 0x69800
	ld xde, 0xb400
	call Copy_DE_words_from_XBC_to_XWA
	ld wa, 0:i3
	calr Vga_SelectWritePlane
	jp Start_8bit_Timer_3

Vga_RestorePlane3FromBuffer:
	call Stop_and_Clear_8bit_Timer_3
	ld wa, 3:i3
	calr Vga_SelectWritePlane
	ld xwa, 0x69800
	ld xbc, 0x1a9800
	ld xde, 0xb400
	call Copy_DE_words_from_XBC_to_XWA
	ld wa, 0:i3
	calr Vga_SelectWritePlane
	jp Start_8bit_Timer_3

; Boot_InitWorkRAM -- Early-boot DRAM initialisation
;
; Called once from RESET_HANDLER before any other firmware subsystem is set up.
; Performs two passes over DRAM to prepare a clean working environment:
;
;   1. Zero-fill block 1: 0x010000 .. 0x03d523  (0x2d524 bytes, ~181 KB)
;      General-purpose work RAM used by the event dispatcher and subsystem state.
;
;   2. Zero-fill block 2: 0x000400 .. 0x00e35d  (0xdf5d bytes, ~55 KB)
;      Low DRAM including the control-panel button state array (0x8e4a),
;      the combo-code cell (0x402), and other low-DRAM variables.
;
;   3. ROM copy block 1: ROM 0xeed8c8 -> DRAM 0x03d524  (0x219e bytes, ~8.5 KB)
;      Copies a constant data block from Program ROM into work RAM.
;
;   4. ROM copy block 2: ROM 0xeefa66 -> DRAM 0x00e35e  (0x95b bytes, ~2.4 KB)
;      Copies a second constant data block from Program ROM into work RAM.
;
; Each block uses the firmware's block-transfer helper (ldirw93 / ldir83) which
; can transfer data in batches via the WA loop counter register.
;
; Returns: no return value; falls through to the next boot stage.
Boot_InitWorkRAM:
	ld xde, 0x10000
	ld xbc, 0x2d524
	ld ix, bc
	srl xbc, 1
	jr z, MemCopy_DataValidation
	ld xhl, xde
	ldw (xde+), 0x0000
	dec 1, xbc
	or xbc, xbc
	jr z, MemCopy_DataValidation
	ldirw93
	cpiw_erp 0xe6, 0
	jr z, MemCopy_DataValidation
	ldto_werp WA, 0xe6

Boot_InitWorkRAM_ZeroBlock1_Loop:
	ldirw93
	djnz16 wa, Boot_InitWorkRAM_ZeroBlock1_Loop

MemCopy_DataValidation:
	bit 0, ix
	jr z, Boot_InitWorkRAM_ZeroBlock1_Done
	ld (xde), 0x0

Boot_InitWorkRAM_ZeroBlock1_Done:
	ld xde, 0x400
	ld xbc, 0xdf5d
	ld ix, bc
	srl xbc, 1
	jr z, MemCopy_SetupAndDMA
	ld xhl, xde
	ldw (xde+), 0x0000
	dec 1, xbc
	or xbc, xbc
	jr z, MemCopy_SetupAndDMA
	ldirw93
	cpiw_erp 0xe6, 0
	jr z, MemCopy_SetupAndDMA
	ldto_werp WA, 0xe6

Boot_InitWorkRAM_ZeroBlock2_Loop:
	ldirw93
	djnz16 wa, Boot_InitWorkRAM_ZeroBlock2_Loop

MemCopy_SetupAndDMA:
	bit 0, ix
	jr z, Boot_InitWorkRAM_ROMCopy1_Start
	ld (xde), 0x0

Boot_InitWorkRAM_ROMCopy1_Start:
	ld xde, 0x3d524
	ld xhl, WorkRamInit_Image
	ld xbc, 0x219e
	or xbc, xbc
	jr z, Boot_InitWorkRAM_ROMCopy2_Start
	ldir83
	cpiw_erp 0xe6, 0
	jr z, Boot_InitWorkRAM_ROMCopy2_Start
	ldto_werp WA, 0xe6

Boot_InitWorkRAM_ROMCopy1_Loop:
	ldir83
	djnz16 wa, Boot_InitWorkRAM_ROMCopy1_Loop

Boot_InitWorkRAM_ROMCopy2_Start:
	ld xde, 0xe35e
	ld xhl, WorkRamInit_Image2
	ld xbc, 0x95b
	or xbc, xbc
	jr z, Boot_InitWorkRAM_Done
	ldir83
	cpiw_erp 0xe6, 0
	jr z, Boot_InitWorkRAM_Done
	ldto_werp WA, 0xe6

Boot_InitWorkRAM_ROMCopy2_Loop:
	ldir83
	djnz16 wa, Boot_InitWorkRAM_ROMCopy2_Loop

Boot_InitWorkRAM_Done:
	jrl Boot_RunSelfTest
	ret

Boot_InitWorkRAM_Trailer:
	ret

INTT1_HANDLER:
	incw 1, (1475:16)
	pushw wa
	push xhl
	xor xhl, xhl
	inc 1, xhl
	add (SYSTEM_TIMESTAMP:16), xhl
	incw 1, (1037:16)
	push	sr
	ei 6
	ld a, (1063:16)
	ld w, (1062:16)
	bit 7, a
	jr z, INTT1_NoOverflow
	inc 1, (1061:16)
	cp (1061:16), 165
	jr ule, INTT1_NoOverflow
	and a, 0x7f
	or a, 0x20

INTT1_NoOverflow:
	inc 1, w
	cp w, 0x86
	jr ule, INTT1_StoreCounters
	ld w, 0x0:opc
	or (1065:16), 16
	call MIDI_SC0_TX_DISPATCH

INTT1_StoreCounters:
	ld (1062:16), w
	ld (1063:16), a
	pop	sr
	ld a, (1066:16)
	cp a, 0xf1
	jr ugt, INTT1_CheckScanFlag
	inc 1, a

INTT1_CheckScanFlag:
	ld (1066:16), a
	bit 2, (0xfd50:16)
	jrl nz, INTT1_UpdateAlternateTimers
	inc 1, (1050:16)
	bit 0, (1056:16)
	jr nz, INTT1_CheckTickOverflow
	bit 5, (1056:16)
	jr nz, INTT1_CheckTickCount
	ld (1050:16), 0
	jp UIStateMachine_DispatchEntry

INTT1_CheckTickCount:
	cp (1050:16), 1
	jrl nc, UIStateMachine_DispatchEntry
	ld (1056:16), 16

INTT1_CheckMidiSync:
	cp (CURRENT_MODE:16), 19
	jr z, UIState_DispatchBranch
	bit 2, (0xfd52:16)
	jr z, UIState_DispatchBranch
	bit 2, (0xfd50:16)
	jr nz, UIState_DispatchBranch
	push	sr
	ei 6
	or (1065:16), 8
	call MIDI_SC0_TX_DISPATCH
	pop	sr

UIState_DispatchBranch:
	jr UIStateMachine_DispatchEntry

INTT1_CheckTickOverflow:
	cp (1050:16), 1
	jr ule, UIStateMachine_DispatchEntry
	ld (1056:16), 6
	res 0, (1139:16)
	bit 0, (1054:16)
	jr z, INTT1_CheckAltSeqOverflow
	ld (1054:16), 6
	res 0, (1139:16)

INTT1_CheckAltSeqOverflow:
	bit 0, (SEQ_TRANSPORT_STATE:16)
	jr z, INTT1_CheckMidiSyncGate
	ld (SEQ_TRANSPORT_STATE:16), 6
	res 0, (1139:16)

INTT1_CheckMidiSyncGate:
	cp (CURRENT_MODE:16), 19
	jr z, INTT1_SkipToDispatch
	push	sr
	ei 6
	or (1065:16), 1
	call MIDI_SC0_TX_DISPATCH
	pop	sr

INTT1_SkipToDispatch:
	jr UIStateMachine_DispatchEntry

INTT1_UpdateAlternateTimers:
	bit 3, (1054:16)
	jr z, INTT1_CheckAltSeqTimer
	ld (1054:16), 16

INTT1_CheckAltSeqTimer:
	bit 3, (SEQ_TRANSPORT_STATE:16)
	jr z, INTT1_CheckMetroTimer
	ld (SEQ_TRANSPORT_STATE:16), 16
	ld a, (1045:16)
	ld (1078:16), a
	ld a, (1046:16)
	ld (1079:16), a

INTT1_CheckMetroTimer:
	bit 3, (1056:16)
	jr z, UIStateMachine_DispatchEntry
	ld (1056:16), 16
	jrl INTT1_CheckMidiSync

UIStateMachine_DispatchEntry:
	lda xhl, (1055:16)
	ld a, (xhl)
	bit 2, (0xfd50:16)
	jr nz, UIStateMachine_CheckPending
	bit 0, a
	jr z, UIStateMachine_CheckPending
	ld (xhl), 0x6
	res 0, (1139:16)

UIStateMachine_CheckPending:
	bit 3, a
	jr z, UIStateMachine_ClearBit3
	ld (xhl), 0x10

UIStateMachine_ClearBit3:
	res 2, (1043:16)
	ld a, (1041:16)
	inc 1, a
	cp a, 2:i3
	jr ule, UIStateMachine_PrimaryDispatch
	sub a, a
	inc 1, (1042:16)

; UI state machine primary dispatch
; Index: DRAM[1041] (0-2), entries: 3
; State 0: Idle, State 1: Process, State 2: Sub-state dispatch
UIStateMachine_PrimaryDispatch:
	ld (1041:16), a
	sll a, 2
	lda xhl, (UI_STATE_MACHINE_TABLE:24)
	ld	xhl, (xhl+a)
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
	and (1058:16), 110
	bit 0, (1042:16)
	jr nz, UIState1_AlternateExit
	lda xhl, (1116:16)
	cp (xhl), 0x0
	jr z, UIState1_SkipToExit
	decm8 1, (xhl)

UIState1_SkipToExit:
	jrl UIStateMachine_ExitToScheduler

UIState1_AlternateExit:
	jrl UIStateMachine_ExitToScheduler

UI_STATE_2_SUBSTATE:
	ld a, (1042:16)
	and a, 0xf
	sll a, 2
	lda xhl, (UI_SUBSTATE_TABLE:24)
	ld	xhl, (xhl+a)
	jp (xhl)

; UI sub-state dispatch table (16 entries)
; Uses (0412h) & 0x0f as index, multiplied by 4
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
	res 6, (1058:16)
	res 0, (1043:16)
	jr UIStateMachine_ExitToScheduler

UI_SUBSTATE_PROCESS_A:
	res 1, (1043:16)
	res 0, (1044:16)
	ld a, 0x2:opc
	call TaskSched_SignalEvent_NoBlock
	jr UIStateMachine_ExitToScheduler

UI_SUBSTATE_CLEAR_BIT3:
	res 3, (1043:16)
	jr UIStateMachine_ExitToScheduler

UI_SUBSTATE_ACTION_0:
	res 4, (1043:16)
	jr UIStateMachine_ExitToScheduler

UI_SUBSTATE_ACTION_1:
	res 5, (1043:16)
	jr UIStateMachine_ExitToScheduler

UI_SUBSTATE_ACTION_2:
	res 6, (1043:16)
	jr UIStateMachine_ExitToScheduler

UI_SUBSTATE_ACTION_3:
	res 7, (1043:16)

UIStateMachine_ExitToScheduler:
	pop xhl
	popw wa
	jp INTT3_CheckNesting

INTTR4_HANDLER:
	pushw wa
	push xhl
	push xiy
	lda xiy, (0x01e753:24)
	lda xhl, (1039:16)
	incm8 1, (xhl)
	cp (xhl), 0x60
	jr c, INTTR4_TickWrapped
	ld (xhl), 0x0

INTTR4_TickWrapped:
	bit 2, (0xfd50:16)
	jr z, INTTR4_CheckSyncEnable
	jp INTTR4_SubTick_Mode

INTTR4_CheckSyncEnable:
	bit 2, (1055:16)
	jr z, INTTR4_CheckMetroEnable
	push	sr
	ei 6
	ld a, (1130:16)
	inc 1, a
	cp a, 0x60
	jr c, INTTR4_SyncCounter2_NoWrap
	xor a, a
	incw 1, (1128:16)
	ld (1130:16), a
	cp (0x7f0b:16), 0
	jr z, INTTR4_SyncCounter2_Done
	calr TempoRingBuf_Write
	jr INTTR4_SyncCounter2_Done

INTTR4_SyncCounter2_NoWrap:
	ld (1130:16), a

INTTR4_SyncCounter2_Done:
	pop	sr

INTTR4_CheckMetroEnable:
	bit 2, (1056:16)
	jr z, INTTR4_CheckSeqEnable
	push	sr
	ei 6
	ld a, (1047:16)
	inc 1, a
	cp a, 0x60
	jr lt, INTTR4_MetroCounter_Store
	xor a, a
	incw 1, (1048:16)

INTTR4_MetroCounter_Store:
	ld (1047:16), a
	pop	sr

INTTR4_CheckSeqEnable:
	bit 2, (1054:16)
	jr z, INTTR4_CheckAltSeqEnable
	inc 1, (1045:16)
	cp (1045:16), 96
	jr c, INTTR4_CheckAltSeqEnable
	ld (1045:16), 0
	inc 1, (1046:16)
	cp (0x379b:16), 0
	jr z, INTTR4_SeqTick_CheckBeat
	calr TempoRingBuf_Write

INTTR4_SeqTick_CheckBeat:
	ld a, (1046:16)
	ld w, (1075:16)
	ex (0x458:16), w
	cp a, w
	jr c, INTTR4_CheckAltSeqEnable
	ld (1046:16), 0
	inc 1, (1076:16)
	inc 1, (1077:16)
	ld a, (1077:16)
	cp a, (0x34d7:16)
	jr ule, INTTR4_CheckAltSeqEnable
	ld (1077:16), 0

INTTR4_CheckAltSeqEnable:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, INTTR4_MetroPhaseSync
	inc 1, (SEQ_BEAT_TICK:16)
	cp (SEQ_BEAT_TICK:16), 96
	jr lt, INTTR4_MetroPhaseSync
	ld (SEQ_BEAT_TICK:16), 0
	incw 1, (SEQ_BEAT_COUNT:16)
	cpw (0x28aa:16), 0
	jr z, INTTR4_MetroPhaseSync
	calr TempoRingBuf_Write

INTTR4_MetroPhaseSync:
	bit 2, (1056:16)
	jr z, INTTR4_SeqAutoStart
	bit 0, (1054:16)
	jr z, INTTR4_MetroSync_CheckAltSeq
	ld (1054:16), 6
	res 0, (1139:16)

INTTR4_MetroSync_CheckAltSeq:
	bit 0, (SEQ_TRANSPORT_STATE:16)
	jr z, INTTR4_MetroSync_Done
	ld (SEQ_TRANSPORT_STATE:16), 6
	res 0, (1139:16)

INTTR4_MetroSync_Done:
	jr INTTR4_MetroBeat_Check

INTTR4_SeqAutoStart:
	bit 7, (1054:16)
	jr z, INTTR4_MetroBeat_Check
	bit 2, (1054:16)
	jr z, INTTR4_SeqInit_SetEnable
	cp (1045:16), 95
	jr c, INTTR4_SeqAutoStart_Skip
	cp (1076:16), 1
	jr c, INTTR4_SeqAutoStart_Skip
	ld a, (1075:16)
	dec 1, a
	cp (1046:16), a
	jr c, INTTR4_SeqAutoStart_Skip
	ld a, 0x1:opc
	ld (1056:16), a
	ld (SEQ_TRANSPORT_STATE:16), a
	cp (CURRENT_MODE:16), 19
	jr z, INTTR4_SeqAutoStart_Skip
	bit 2, (0xfd52:16)
	jr z, INTTR4_SeqAutoStart_Skip
	bit 2, (0xfd50:16)
	jr nz, INTTR4_SeqAutoStart_Skip
	push	sr
	ei 6
	or (1065:16), 2
	call MIDI_SC0_TX_DISPATCH
	pop	sr

INTTR4_SeqAutoStart_Skip:
	jr INTTR4_MetroBeat_Check

INTTR4_SeqInit_SetEnable:
	ld (1054:16), 134

INTTR4_MetroBeat_Check:
	bit 3, (1056:16)
	jr z, INTTR4_SeqBeat_Check
	ld a, (1047:16)
	cp a, 0:i3
	jr z, INTTR4_MetroBeat_OnBeat
	cp a, 0x18
	jr z, INTTR4_MetroBeat_OnBeat
	cp a, 0x30
	jr z, INTTR4_MetroBeat_OnBeat
	cp a, 0x48
	jr z, INTTR4_MetroBeat_OnBeat
	jr INTTR4_MetroQuarter_Check

INTTR4_MetroBeat_OnBeat:
	ld (1056:16), 16
	cp (CURRENT_MODE:16), 19
	jr z, INTTR4_SeqBeat_Check
	bit 2, (0xfd52:16)
	jr z, INTTR4_SeqBeat_Check
	bit 2, (0xfd50:16)
	jr nz, INTTR4_SeqBeat_Check
	push	sr
	ei 6
	or (1065:16), 8
	call MIDI_SC0_TX_DISPATCH
	pop	sr

INTTR4_SeqBeat_Check:
	bit 3, (1054:16)
	jr z, INTTR4_AltSeqBeat_Check
	ld (1054:16), 16

INTTR4_AltSeqBeat_Check:
	bit 3, (SEQ_TRANSPORT_STATE:16)
	jr z, INTTR4_MetroQuarter_Check
	ld (SEQ_TRANSPORT_STATE:16), 16
	ld a, (1045:16)
	ld (1078:16), a
	ld a, (1046:16)
	ld (1079:16), a

INTTR4_MetroQuarter_Check:
	bit 2, (1056:16)
	jr z, INTTR4_SeqAccum_Update
	ld a, (1047:16)
	and a, 0x3
	jr nz, INTTR4_SeqAccum_Update
	cp (CURRENT_MODE:16), 19
	jr z, INTTR4_SeqAccum_Update
	push	sr
	ei 6
	or (1065:16), 1
	call MIDI_SC0_TX_DISPATCH
	pop	sr

INTTR4_SeqAccum_Update:
	bit 2, (1054:16)
	jr z, INTTR4_SeqAccum_Reset
	push	sr
	ei 6
	ld a, (1045:16)
	ld w, a
	sub a, (1111:16)
	jr z, INTTR4_SeqAccum_Done
	jr ugt, INTTR4_SeqAccum_PositiveDelta
	add a, 0x60

INTTR4_SeqAccum_PositiveDelta:
	ld (1111:16), w
	add (1124:16), a
	add (1122:16), a
	xor w, w
	add wa, (1120:16)
	cp a, 0x60
	jr c, INTTR4_SeqAccum_NoWrap
	sub a, 0x60
	inc 1, w

INTTR4_SeqAccum_NoWrap:
	ld (1120:16), wa

INTTR4_SeqAccum_Done:
	pop	sr
	jr INTTR4_AltSeqAccum_Update

INTTR4_SeqAccum_Reset:
	xor wa, wa
	ld (1120:16), wa
	ld (0x3372:16), wa
	ld (1122:16), a
	ld (0x3376:16), a
	ld (1111:16), a

INTTR4_AltSeqAccum_Update:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, INTTR4_FadeDelay_Check
	ld a, (SEQ_BEAT_TICK:16)
	bit 3, (1073:16)
	jr z, INTTR4_AltSeqSync_Check
	cp (1072:16), a
	jr nz, INTTR4_AltSeqSync_Check
	ld (1054:16), 8
	and (1073:16), 247
	cpw (0x28aa:16), 0
	jr z, INTTR4_AltSeqSync_Check
	ld a, 0x86:opc
	calr TempoRingBuf_WritePair

INTTR4_AltSeqSync_Check:
	bit 0, (1073:16)
	jr z, INTTR4_FadeDelay_Check
	cp (1071:16), a
	jr nz, INTTR4_FadeDelay_Check
	ld (1054:16), 1
	and (1073:16), 254
	cpw (0x28aa:16), 0
	jr z, INTTR4_FadeDelay_Check
	ld a, 0x85:opc
	calr TempoRingBuf_WritePair

INTTR4_FadeDelay_Check:
	cp (1126:16), 0
	jr z, INTTR4_SyncAccum_Update
	dec 1, (1126:16)

INTTR4_SyncAccum_Update:
	bit 2, (1055:16)
	jr z, INTTR4_SyncAccum_Reset
	push	sr
	ei 6
	ld a, (1130:16)
	ld w, a
	sub a, (1138:16)
	jr z, INTTR4_SyncAccum_Done
	jr ugt, INTTR4_SyncAccum_PositiveDelta
	add a, 0x60

INTTR4_SyncAccum_PositiveDelta:
	ld (1138:16), w
	add (1131:16), a
	add (1133:16), a
	xor w, w
	add wa, (1136:16)
	cp a, 0x60
	jr c, INTTR4_SyncAccum_NoWrap
	sub a, 0x60
	inc 1, w

INTTR4_SyncAccum_NoWrap:
	ld (1136:16), wa

INTTR4_SyncAccum_Done:
	pop	sr
	jr INTTR4_Return

INTTR4_SyncAccum_Reset:
	xor wa, wa
	ld (1136:16), wa
	ld (0x7dfe:16), wa
	ld (1133:16), a
	ld (0x7dfc:16), a
	ld (1138:16), a

INTTR4_Return:
	pop xiy
	pop xhl
	popw wa
	reti

TempoRingBuf_Write:
	bit 0, (1113:16)
	jr nz, TempoRingBuf_Write_Enqueue
	pushw wa
	ld wa, (xiy - 2)
	and wa, wa
	jr z, TempoRingBuf_Write_Dequeue
	ld hl, (xiy - 4)
	ld	(xiy+hl), 0x81
	minc1_16 hl, 0x7ff
	dec 1, wa
	ld (xiy - 4), hl
	ld (xiy - 2), wa

TempoRingBuf_Write_Dequeue:
	popw wa
	ldw (1141:16), 0
	jr TempoRingBuf_Write_Return

TempoRingBuf_Write_Enqueue:
	pushw ix
	lda xhl, (1143:16)
	ld ix, (1141:16)
	ld	(xhl+ix), 0x81
	inc 1, ix
	ld (1141:16), ix
	popw ix

TempoRingBuf_Write_Return:
	ret

TempoRingBuf_WritePair:
	bit 0, (1113:16)
	jr nz, TempoRingBuf_WritePair_Enqueue
	cpw (0x1e751:24), 2
	jr c, TempoRingBuf_WritePair_ClearPending
	push	sr
	ei 6
	push xiy
	lda xiy, (0x01e753:24)
	ld hl, (xiy - 4)
	ld	(xiy+hl), a
	decm 1, (xiy - 2)
	minc1_16 hl, 0x7ff
	ld a, (SEQ_BEAT_TICK:16)
	ld	(xiy+hl), a
	minc1_16 hl, 0x7ff
	decm 1, (xiy - 2)
	ld (0x01e74f:24), hl
	pop xiy
	pop	sr

TempoRingBuf_WritePair_ClearPending:
	ldw (1141:16), 0
	ret

TempoRingBuf_WritePair_Enqueue:
	pushw ix
	lda xhl, (1143:16)
	ld ix, (1141:16)
	ld	(xhl+ix), a
	ld a, (SEQ_BEAT_TICK:16)
	inc 1, ix
	ld	(xhl+ix), a
	ld a, (SEQ_BEAT_TICK:16)
	inc 1, ix
	ld (1141:16), ix
	popw ix
	ret

INTTR4_SubTick_Mode:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, INTTR4_SubTick_MetroInc
	ld a, (SEQ_BEAT_TICK:16)
	xor a, 0x3
	and a, 0x3
	jr z, INTTR4_SubTick_MetroInc
	inc 1, (SEQ_BEAT_TICK:16)

INTTR4_SubTick_MetroInc:
	bit 2, (1056:16)
	jr z, INTTR4_SubTick_SeqInc
	ld a, (1047:16)
	xor a, 0x3
	and a, 0x3
	jr z, INTTR4_SubTick_SeqInc
	inc 1, (1047:16)

INTTR4_SubTick_SeqInc:
	bit 2, (1054:16)
	jr z, INTTR4_SubTick_PhaseSync
	ld a, (1045:16)
	xor a, 0x3
	and a, 0x3
	jr z, INTTR4_SubTick_PhaseSync
	inc 1, (1045:16)

INTTR4_SubTick_PhaseSync:
	bit 2, (1056:16)
	jr z, INTTR4_SubTick_ToAccum
	bit 0, (1054:16)
	jr z, INTTR4_SubTick_PhaseSync_AltSeq
	ld (1054:16), 6
	res 0, (1139:16)

INTTR4_SubTick_PhaseSync_AltSeq:
	bit 0, (SEQ_TRANSPORT_STATE:16)
	jr z, INTTR4_SubTick_ToAccum
	ld (SEQ_TRANSPORT_STATE:16), 6
	res 0, (1139:16)

INTTR4_SubTick_ToAccum:
	jp INTTR4_SeqAccum_Update
INTTR4_BytecodeSnippet:
	ld	l, 0:opc
	tsetda16	0, (0x414)
	ret	nz
	ld	l, 1:opc
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
	call SeqData_EF086F
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
	cp (1124:16), 7
	jr ule, MainLoop_AfterSeqTick
	calr Seq_TickWrapper

MainLoop_AfterSeqTick:
	ei 6
	ld a, (1063:16)
	and a, 0x2c
	jr z, MainLoop_AfterVoiceReset
	call SeqMain_InitBuffer
	and (1063:16), 211
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
	ld a, (0x346d:16)
	and a, 0x3
	jr z, MainLoop_AfterAccWrap
	ld a, (0x3283:16)
	and a, 0x3
	jr nz, MainLoop_AfterAccWrap
	call AccWrap_DeferredAction

MainLoop_AfterAccWrap:
	tset_dd16 0, 0x73, 0x04
	jr nz, MainLoop_AfterPedalReset
	call CompIface_ResetPedal

MainLoop_AfterPedalReset:
	calr Seq_EventProcessingTick
	call PanelButton_ProcessChanges
	cp (0xbf39:16), 255
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
	lda xiy, (1058:16)
	mri_d2 0xb5, 0xae
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
	bit 7, (1068:16)
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
	lda xiy, (1115:16)
	cp (xiy), 0x1
	jr nz, SeqTick_CheckActive
	cp (0xcedf:16), 0
	jr z, SeqTick_CheckActive
	ld (xiy), 0x0

SeqTick_CheckActive:
	bitm 0, (xiy)
	jr z, SeqTick_Dispatch
	bit 2, (1054:16)
	jr nz, SeqTick_Return

SeqTick_Dispatch:
	call Seq_DispatcherEntry
	ld (1124:16), 0

SeqTick_Return:
	ret

MainLoop_ReinitSwbtWr:
	call SwbtWr_InitBank3
	call Audio_MainPeriodicUpdate
	ld (0xc039:16), 255
	calr SwbtWr_ReinitBothBanks
	ret

MainLoop_AudioPeriodicCheck:
	call VoiceEvent_ResetAndInit
	call Voice_UpdateNoteState
	call SndParam_DispatchReturn
	ret

Seq_ProcessMidiEvent:
	lda xhl, (0x01f37b:24)
	ld iy, (xhl - 8)
	ld ix, (xhl - 4)
	xor bc, bc
	ld iz, bc

MidiEvt_ScanLoop:
	bit	7, (xhl+iy)
	jr nz, MidiEvt_FoundStatusByte
	inc 1, iz
	minc1_16 iy, 0x3ff
	cp iy, ix
	jrl z, MidiSerial_BufferWrap
	jr MidiEvt_ScanLoop

MidiEvt_FoundStatusByte:
	ld	c, (xhl+iy)
	and c, 0xf0
	cp c, 0x90
	jr z, MidiEvt_SetNoteOnFlag
	cp c, 0x80
	jr z, MidiEvt_SetNoteOnFlag
	cp c, 0xb0
	jr nz, MidiSerial_DataReceive
	ld de, iy
	inc 1, iz
	minc1_16 iy, 0x3ff
	cp iy, ix
	jr z, MidiSerial_BufferWrap
	cp	(xhl+iy), 0x7b
	jr c, MidiSerial_DataReceive

MidiEvt_SetNoteOnFlag:
	ld b, 0x1:opc

MidiSerial_DataReceive:
	bit	7, (xhl+iy)
	jr z, MidiEvt_AdvancePointer
	ld	a, (xhl+iy)
	and a, 0xf0
	cp a, 0x90
	jr z, MidiEvt_SetDataFlag
	cp a, 0x80
	jr z, MidiEvt_SetDataFlag
	cp a, 0xb0
	jr nz, MidiEvt_ClearDataFlag
	ld de, iy
	ld wa, iz
	inc 1, iz
	minc1_16 iy, 0x3ff
	cp iy, ix
	jr z, MidiSerial_BufferWrap
	cp	(xhl+iy), 0x7b
	ld iz, wa
	ld iy, de
	jr c, MidiEvt_ClearDataFlag

MidiEvt_SetDataFlag:
	or b, 0x2
	jr MidiEvt_CheckProcessMode

MidiEvt_ClearDataFlag:
	and b, 0xfd

MidiEvt_CheckProcessMode:
	cp b, 1:i3
	jr z, MidiEvt_ProcessNoteOn
	cp b, 2:i3
	jr z, MidiSerial_ProcessAndReinit

MidiEvt_AdvancePointer:
	inc 1, iz
	minc1_16 iy, 0x3ff
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
	jr MidiEvt_UpdateReadPosition

MidiEvt_UpdateReadPosition:
	lda xhl, (0x01f37b:24)
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
	bit 7, (1058:16)
	jr nz, SeqEvtTick_ProcessTimers
	calr SeqEvt_CheckExpiry

SeqEvtTick_ProcessTimers:
	calr SeqEvt_ProcessTimedEvents
	call RhythmBuf_ProcessEvents
	call SeqEvt_ProcessBuffer
	call MIDI_OutputFlush
	call SysEx_ParseAndDispatch
	cp (1140:16), 85
	jr z, SeqEvtTick_Return

Seq_ProcessEventLoop:
	call Seq_CheckSongEnd
	and hl, hl
	jr z, SeqEvtTick_Return
	calr Seq_ProcessMidiEvent
	jr Seq_ProcessEventLoop

SeqEvtTick_Return:
	ret
; SwbtWr_ReinitBothBanks - Reinitialize both tone generator output banks
; Original Matsushita debug symbol: "assswb_op" (assign sound write bank - operation)
; Calls SwbtWr_InitBank1 and SwbtWr_InitBank2 to reinitialize voice
; parameter transfers to the tone generator.
SwbtWr_ReinitBothBanks:

	cp (SWBTWR_EVENT_QUEUE:16), 255
	jr z, SwbtWr_ReinitBothBanks_Return
	call SwbtWr_InitBank1
	call SwbtWr_InitBank2
	ld (SWBTWR_EVENT_QUEUE:16), 255
	ldw (0x90de:16), 0

SwbtWr_ReinitBothBanks_Return:
	ret
; SwbtWr_ReinitOutputBank - Reinitialize the output tone generator bank
; Original Matsushita debug symbol: "assswb_out" (assign sound write bank - output)
; Calls only SwbtWr_InitBank2 (the output bank).
SwbtWr_ReinitOutputBank:

	cp (SWBTWR_EVENT_QUEUE:16), 255
	jr z, SwbtWr_ReinitOutputBank_Return
	call SwbtWr_InitBank2
	ld (SWBTWR_EVENT_QUEUE:16), 255
	ldw (0x90de:16), 0

SwbtWr_ReinitOutputBank_Return:
	ret

RhythmBuf_ProcessEvents:
	bit 2, (1054:16)
	jr z, RhythmBuf_ProcessLoop
	calr SeqTiming_Snapshot

RhythmBuf_ProcessLoop:
	ld wa, (0x01ef59:24)
	cp wa, (0x1ef55:24)
	jr z, RhythmBuf_ProcessLoop_Done
	calr RhythmBuf_DispatchEvent
	jr RhythmBuf_ProcessLoop

RhythmBuf_ProcessLoop_Done:
	ret

RhythmBuf_DispatchEvent:
	lda xhl, (0x01ef5d:24)
	calr RhythmBuf_ScanForNoteOn
	jr c, RhythmBuf_Dispatch_NonNoteOn
	call RhythmMidi_Dispatcher
	jr RhythmBuf_Dispatch_UpdateReadPos

RhythmBuf_Dispatch_NonNoteOn:
	call SeqPart_EmitNoteOn_Full

RhythmBuf_Dispatch_UpdateReadPos:
	ld wa, (0x01ef57:24)
	ld bc, (0x01ef55:24)
	ld (0x01ef55:24), wa
	sub wa, bc
	jr ge, RhythmBuf_Dispatch_NoWrap
	add wa, 0x200

RhythmBuf_Dispatch_NoWrap:
	add (0x1ef5b:24), wa
	ret

RhythmBuf_ScanForNoteOn:
	ld iy, (xhl - 8)
	ld ix, (xhl - 4)

RhythmBuf_Scan_SkipNonStatus:
	bit	7, (xhl+iy)
	jr nz, RhythmBuf_Scan_FoundStatus
	minc1_16 iy, 0x1ff
	cp iy, ix
	jr z, RhythmBuf_Scan_EndReached
	jr RhythmBuf_Scan_SkipNonStatus

RhythmBuf_Scan_FoundStatus:
	ld de, iy
	ld	c, (xhl+iy)
	and c, 0xf0

RhythmBuf_Scan_CheckNext:
	bit	7, (xhl+iy)
	jr z, RhythmBuf_Scan_Advance
	ld de, iy
	ld	a, (xhl+iy)
	and a, 0xf0
	cp c, a
	jr z, RhythmBuf_Scan_Advance
	cp c, 0x90
	jr z, RhythmBuf_Scan_ReturnNoteOn
	cp a, 0x90
	jr z, RhythmBuf_Scan_ReturnOther

RhythmBuf_Scan_Advance:
	minc1_16 iy, 0x1ff
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
	and (1115:16), 253
	scf

RhythmBuf_Scan_Return:
	ret

SeqEvt_ProcessBuffer:
	bit 2, (1055:16)
	jr z, SeqEvt_ProcessBuffer_Main
	calr SyncTiming_Snapshot

SeqEvt_ProcessBuffer_Main:
	lda xhl, (0x01f271:24)

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
	lda xhl, (0x01f271:24)
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
	bit	7, (xhl+iy)
	jr nz, SeqEvt_Scan_FoundStatus
	minc1_16 iy, 0xff
	cp iy, ix
	jr z, SeqEvt_Scan_EndReached
	jr SeqEvt_Scan_SkipData

SeqEvt_Scan_FoundStatus:
	ld de, iy
	ld	c, (xhl+iy)
	and c, 0xf0

SeqEvt_Scan_CheckNext:
	bit	7, (xhl+iy)
	jr z, SeqEvt_Scan_Advance
	ld de, iy
	ld	a, (xhl+iy)
	and a, 0xf0
	cp c, a
	jr z, SeqEvt_Scan_Advance
	cp c, 0x90
	jr z, SeqEvt_Scan_ReturnNoteOn
	cp a, 0x90
	jr z, SeqEvt_Scan_ReturnOther

SeqEvt_Scan_Advance:
	minc1_16 iy, 0xff
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
	and (1115:16), 253
	scf

SeqEvt_Scan_Return:
	ret

SeqEvt_CallTimingHelper:
	call SeqPlay_HandleVoiceReassign
	ret

SeqEvt_ProcessTimedEvents:
	bit 5, (0x28ac:16)
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
	lda xix, (1143:16)
	xor hl, hl
	ei 6

TempoRingBuf_Consume_Loop:
	cp hl, (1141:16)
	jr nc, TempoRingBuf_Consume_Done
	ld	e, (xix+hl)
	calr TempoRingBuf_DequeueOne
	inc 1, hl
	jr TempoRingBuf_Consume_Loop

TempoRingBuf_Consume_Done:
	res 0, (1113:16)
	ldw (1141:16), 0
	ei 0
	popw hl
	pop xix
	ret

TempoRingBuf_BytecodeSnippet:
	bit	0, (0x459:16)
	jr	nz, TempoRingBuf_Consume_Skip
	ld	e, 129:opc
	calr	TempoRingBuf_DequeueOne
	ret
TempoRingBuf_Consume_Skip:
	push	xix
	lda	xix, (1143:16)
	ld	hl, (1141:16)
	ld	(xix+hl), 0x81
	inc	1, hl
	ld	(0x475:16), hl
	pop	xix
	ret

TempoRingBuf_DequeueOne:
	push xix
	pushw hl
	pushw wa
	lda xix, (0x01e753:24)
	ld wa, (xix - 2)
	and wa, wa
	jr z, TempoRingBuf_DequeueOne_Done
	ld hl, (xix - 4)
	ld	(xix+hl), e
	minc1_16 hl, 0x7ff
	dec 1, wa
	ld (xix - 4), hl
	ld (xix - 2), wa

TempoRingBuf_DequeueOne_Done:
	popw wa
	popw hl
	pop xix
	ret

SeqEvt_CheckExpiry:
	and (1058:16), 127
	ld a, (0xe9bc:16)
	and a, a
	jr z, SeqEvt_CheckExpiry_Return
	dec 1, a
	ld (0xe9bc:16), a
	jr nz, SeqEvt_CheckExpiry_Return
	call NoteMap_FindBestMatch
	cp l, 0xff
	jr z, SeqEvt_CheckExpiry_Return
	call VoiceEvent_DispatchTable

SeqEvt_CheckExpiry_Return:
	ret

SeqTiming_Snapshot:
	ei 6
	ld wa, (1120:16)
	ld l, (1122:16)
	ld (1118:16), wa
	ld (1117:16), l
	cp wa, (0x3372:16)
	jr c, SeqTiming_Snapshot_CheckFrac
	ldw (1120:16), 0

SeqTiming_Snapshot_CheckFrac:
	cp l, (0x3376:16)
	jr c, SeqTiming_Snapshot_PostSnap
	ld (1122:16), 0

SeqTiming_Snapshot_PostSnap:
	ei 0
	cp wa, (0x3372:16)
	jr c, SeqTiming_Snapshot_CheckFracOverflow
	push xhl
	call AccTiming_InitAllParts
	xor wa, wa
	ld (1118:16), wa
	pop xhl

SeqTiming_Snapshot_CheckFracOverflow:
	cp l, (0x3376:16)
	jr c, SeqTiming_Snapshot_Return
	call AccTiming_MasterTick

SeqTiming_Snapshot_Return:
	ret

SyncTiming_Snapshot:
	ei 6
	ld wa, (1136:16)
	ld l, (1133:16)
	ld (1134:16), wa
	ld (1132:16), l
	cp wa, (0x7dfe:16)
	jr c, SyncTiming_Snapshot_CheckFrac
	ldw (1136:16), 0

SyncTiming_Snapshot_CheckFrac:
	cp l, (0x7dfc:16)
	jr c, SyncTiming_Snapshot_PostSnap
	ld (1133:16), 0

SyncTiming_Snapshot_PostSnap:
	ei 0
	cp wa, (0x7dfe:16)
	jr c, SyncTiming_Snapshot_CheckFracOverflow
	push xhl
	call SeqEvt_EntryPoint2
	xor wa, wa
	ld (1134:16), wa
	pop xhl

SyncTiming_Snapshot_CheckFracOverflow:
	cp l, (0x7dfc:16)
	jr c, SyncTiming_Snapshot_Return
	call SeqEvt_EntryPoint1

SyncTiming_Snapshot_Return:
	ret

Seq_FullInit:
	ld a, 0xff:opc
	ld (1043:16), a
	ld (1058:16), a
	ld (1139:16), a
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
	ld (0xbf39:16), 255
	ret

Seq_InitStub_Nop1:
	ret

Seq_InitStub_Nop2:
	ret

Seq_InitStub_Nop3:
	ret

AudioMix_Init:
	link	xiz, 0xfff8
	xor xwa, xwa
	ld xwa, 0x5a5a5a5a
	ld (xiz - 8), xwa
	ld (xiz - 4), xwa
	lda xwa, (xiz - 8)
	push xwa
	ld bc, 0:i3
	calr AudioMix_WriteChannelGroup
	pop xwa
	push xwa
	ld bc, 1:i3
	calr AudioMix_WriteChannelGroup
	pop xwa
	push xwa
	ld bc, 2:i3
	calr AudioMix_WriteChannelGroup
	pop xwa
	push xwa
	ld bc, 3:i3
	calr AudioMix_WriteChannelGroup
	pop xwa
	ld xbc, 0x150000
	ld xwa, NAKA_FUNC_AcFdemoScreenProc
	ld d, 0x4:opc

AudioMix_EnableChannels_Loop:
	ld w, a
	ld (xbc), xwa
	add a, 0x20
	djnz8 d, AudioMix_EnableChannels_Loop
	unlk	xiz
	ret

AudioMix_WriteChannelGroup:
	pushw de
	sll a, 5
	set 4, a
	ld xhl, 0x150000
	ld d, 0x8:opc

AudioMix_WriteChannelGroup_Loop:
	ld (xhl), a
	ld E, (xbc+)
	ld (xhl + 2), e
	inc 1, a
	djnz8 d, AudioMix_WriteChannelGroup_Loop
	popw de
	ret

; -----------------------------------------------------------------------------
; AudioMix_WriteAllGroupRegs -- load all four channel groups of the audio/mixer
; register file at 0x150000 (address latch) / 0x150002 (data), 8 bytes each.
; Until 2026-09-25 this was `AudioMix_BytecodeData`, 124 B of `.byte`; it is code
; (scripts/lanes/sys/convert_code_runs.py: unidasm tiles it exactly with no
; absurd instruction, the four `calr` land on the helper's first instruction,
; every instruction re-assembles to the ROM bytes).
; Group g's registers are (g << 5) | 0x10 .. +7 -- the same indices
; AudioMix_WriteChannelGroup fills with a constant during AudioMix_Init.  Here
; AudioMix_WriteGroupRegs8 writes XBC's four bytes then XDE's (low byte first)
; to group <word pushed by the caller>: group 1 <- XBC:XDE as passed, group 0
; <- (xsp+0x0a):XIZ, group 2 <- XWA:XHL, group 3 <- XIX:XIY.
; No caller found in v7, v9 or v10: searched `call`/`jp` to the address,
; `calr` whose target is it, and its 24-bit little-endian value anywhere in
; the ROM (a pointer table entry); the same 124 bytes are in all three.
; -----------------------------------------------------------------------------
AudioMix_WriteAllGroupRegs:
	push	xbc
	push	xde
	pushw	1
	calr	AudioMix_WriteGroupRegs8
	ld	xbc, (xsp+0xa)
	ld	xde, xiz
	pushw	0
	calr	AudioMix_WriteGroupRegs8
	ld	xbc, xwa
	ld	xde, xhl
	pushw	2
	calr	AudioMix_WriteGroupRegs8
	ld	xbc, xix
	ld	xde, xiy
	pushw	3
	calr	AudioMix_WriteGroupRegs8
	inc	8, xsp
	pop	xde
	pop	xbc
	ret
; A = (group << 5) | 0x10; for 8 registers: latch A at (0x150000), write the
; next byte of XBC then XDE at (0x150002), A += 1.  Group = word argument.
AudioMix_WriteGroupRegs8:
	push	xiy
	pushw	wa
	pushw	bc
	ld	a, (xsp+0xc)
	sll	a, 5
	set	4, a
	ld	xiy, 0x150000
	ld	(xiy), a
	ld	(xiy+0x2), c
	inc	1, a
	ld	(xiy), a
	ld	(xiy+0x2), b
	inc	1, a
	ld	(xiy), a
	ld	bc, qbc
	ld	(xiy+0x2), c
	inc	1, a
	ld	(xiy), a
	ld	(xiy+0x2), b
	inc	1, a
	ld	(xiy), a
	ld	(xiy+0x2), e
	inc	1, a
	ld	(xiy), a
	ld	(xiy+0x2), d
	inc	1, a
	ld	(xiy), a
	ld	bc, qde
	ld	(xiy+0x2), c
	inc	1, a
	ld	(xiy), a
	ld	(xiy+0x2), b
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
;   XWA = 0x1a0000 (VRAM), XBC = 0x43c00 (offscreen), DE = 0x9600
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
;   DE  = word count (16-bit: `djnz16 de` decrements DE)
;   BC  = 16-bit fill pattern (e.g., color | (color << 8) for 8bpp)
; =============================================================================
Fill_memory_at_XWA_with_DE_words_of_BC_value:
	ld (xwa+), BC
	djnz16 de, Fill_memory_at_XWA_with_DE_words_of_BC_value
	ret

Checksum_ComputeComplement:
	xor xhl, xhl
	extz xbc
	add xbc, xwa

Checksum_AccumulateLoop:
	add XHL, (xwa+)
	cp xwa, xbc
	jr lt, Checksum_AccumulateLoop
	cpl hl
	ret

; TaskSched_ScreenGroupTable -- the five screen groups (tasks) Show_ScreenGroup starts, numbered from 1 (it adds
;          A*12 to the table address minus 12).  Each record: the entry point, the initial stack top (it builds
;          the first frame 0x22 below it), the initial SR word stored in that frame, the priority byte, 0.
TaskSched_ScreenGroupTable:
	.long	Boot_InitPeripherals, 0x0001dc34	; group 1
	.short	0x8800
	.byte	3, 0
	.long	ScreenGroup2_Entry, 0x0001e436	; group 2
	.short	0x8800
	.byte	3, 0
	.long	ScreenGroup3_IdleSpin, 0x0001e4b8	; group 3
	.short	0x8800
	.byte	1, 0
	.long	MainTitle_TeardownAndLoop, 0x0001c030	; group 4
	.short	0x8800
	.byte	3, 0
	.long	DrawTask_Entry, 0x0001d032	; group 5
	.short	0x8800
	.byte	3, 0
; one byte per queue, all 1: TaskSched_Init copies these 10 next to the 10 queue heads at RAM 0x4D1 (to 0x4F9),
; and the next 12 next to the 12 at 0x503 (to 0x533)
TaskSched_ExtQueueByteInit:	.byte	1, 1, 1, 1, 1, 1, 1, 1, 1, 1
TaskSched_ExtQueue2ByteInit:	.byte	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
; group 3's entry: spins forever (priority 1)
ScreenGroup3_IdleSpin:
	jr	ScreenGroup3_IdleSpin

INTT3_PriorityAdjust:
	bit 0, (1158:16)
	jr nz, INTT3_PriorityAdjust_Active
	ld a, 0x5:opc
	ld c, 0x2:opc
	jrl TaskSched_ChangePriority_Inline

INTT3_PriorityAdjust_Active:
	ld a, 0x3:opc
	calr TaskSched_YieldToQueue_NoBlock
	ld a, 0x5:opc
	ld c, 0x3:opc
	jrl TaskSched_ChangePriority_Inline
TaskTimer_NullCallback:
	ret

INTT3_HANDLER:
	incw 1, (1475:16)
	inc 1, (1158:16)
	pushw wa
	pushw bc
	calr INTT3_PriorityAdjust
	popw bc
	popw wa
	jrl INTT3_CheckNesting

TaskSched_Init:
	ld xsp, 0x1e53a
	xor wa, wa
	ld (1159:16), wa
	inc 1, wa
	ldc_cr16 wa, 0x7c
	ld (1475:16), wa
	ldw hl, 0x4c5
	extz xhl
	ld de, 4:i3
	ld b, 0x3:opc

TaskSched_InitPriorityQueues:
	ld ix, hl
	ld (xhl+), IX
	ld (xhl+), IX
	djnz8 b, TaskSched_InitPriorityQueues
	ldw ix, 0x489
	extz xix
	ld b, 0x5:opc
	ld a, 0x0:opc

TaskSched_InitTCBFields:
	ld (xix + 9), a
	ld (xix + 10), 0x0
	ld (xix + 11), 0x0
	add ix, 0xc
	djnz8 b, TaskSched_InitTCBFields
	ldw ix, 0x5bb
	extz xix
	ld b, 0x1:opc
	ld xwa, 0xffffffff

TaskSched_InitTimerSlots:
	ld (xix + 4), xwa
	add ix, 0x8
	djnz8 b, TaskSched_InitTimerSlots
	ld xhl, TaskSched_ExtQueueByteInit
	ldw de, 0x4f9
	extz xde
	ldw bc, 0xa
	ldir83
	ldw hl, 0x4d1
	extz xhl
	ld b, 0xa:opc

TaskSched_InitExtQueues:
	ld ix, hl
	ld (xhl+), IX
	ld (xhl+), IX
	djnz8 b, TaskSched_InitExtQueues
	ld xhl, TaskSched_ExtQueue2ByteInit
	ldw de, 0x533
	extz xde
	ldw bc, 0xc
	ldir83
	ldw hl, 0x503
	extz xhl
	ld b, 0xc:opc

TaskSched_InitExtQueues2:
	ld ix, hl
	ld (xhl+), IX
	ld (xhl+), IX
	djnz8 b, TaskSched_InitExtQueues2
	ldw hl, 0x567
	extz xhl
	ld b, 0xa:opc
	ld xwa, 0xffffffff

TaskSched_InitFreeList:
	ld (xhl + 4), xwa
	add hl, 0x8
	djnz8 b, TaskSched_InitFreeList
	ldw iy, 0x5b7
	extz xiy
	ld (xiy + 0:8), iy
	ld (xiy + 2), iy
	ldw ix, 0x567
	ld b, 0xa:opc

TaskSched_LinkFreeSlots:
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	add ix, 0x8
	djnz8 b, TaskSched_LinkFreeSlots
	ldw hl, 0x53f
	extz xhl
	ld b, 0x5:opc

TaskSched_InitLockQueues:
	ld ix, hl
	ld (xhl+), IX
	ld (xhl+), IX
	djnz8 b, TaskSched_InitLockQueues
	ldw hl, 0x553
	extz xhl
	ld b, 0x5:opc

TaskSched_InitMsgQueues:
	ld ix, hl
	ld (xhl+), IX
	ld (xhl+), IX
	djnz8 b, TaskSched_InitMsgQueues
	ld xwa, TaskSched_TimerDesc_Slot1
	jr TaskSched_PostInit

TaskSched_TimerDesc_Slot1:
	; The descriptor TaskSched_InitMsgQueues passes to TaskTimer_Register in XWA.  TaskTimer_Register
	; reads byte +0 as the timer slot; +4 is TaskTimer_NullCallback, a bare `ret`.  Was decoded as
	; `normal / nop / normal / nop / jr pe, 25 / .byte 0xef / nop`.
	.byte	1, 0, 1, 0
	.long	TaskTimer_NullCallback

TaskSched_PostInit:
	call TaskTimer_Register
	calr Stop_and_Clear_8bit_Timer_3
	ld (TREG3:8), 0x07:io
	ld	a, (INTET23:8)
	and a, 0xf
	or a, 0x20
	ld	(INTET23:8), a
	calr Start_8bit_Timer_3
	ld a, 0x1:opc
	calr Show_ScreenGroup
	ei 6
	ld (1157:16), 0
	xor wa, wa
	ldc_cr16 wa, 0x7c
	ld (1475:16), wa
	jrl TaskSched_Dispatch

TaskSched_AllIdle:
	ei 0
	ld (305:16), 255

TaskSched_HaltLoop:
	jr TaskSched_HaltLoop

TaskSched_Dispatch:
	ld (305:16), 0
	ld wa, (1475:16)
	or wa, wa
	jr nz, TaskSched_ReturnToDispatch
	xor wa, wa
	cp (1159:16), wa
	jr z, TaskSched_ScanPriorityQueues
	ld iy, (1159:16)
	extz xiy
	ld (xiy + 4), xsp
	ld xsp, 0x1e53a
	xor wa, wa
	ld (1159:16), wa

TaskSched_ScanPriorityQueues:
	ld b, 0x3:opc
	ldw ix, 0x4c5
	extz xix

TaskSched_ScanQueue_Loop:
	ld hl, (xix + 0:8)
	cp hl, ix
	jr nz, TaskSched_FoundReadyTask
	inc 4, ix
	djnz8 b, TaskSched_ScanQueue_Loop
	jr TaskSched_AllIdle

TaskSched_FoundReadyTask:
	ld (1159:16), hl
	extz xhl
	ld a, (xhl + 11)
	sll a, 5
	ld (305:16), a
	ld xsp, (xhl + 4)

TaskSched_ReturnToDispatch:
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xwa
	pop xhl
	pop	sr
	ret


TaskSched_TimerTick:
	ld wa, (1475:16)
	inc 1, wa
	ld (1475:16), wa
	ldc_cr16 wa, 0x7c
	ei 0
	ldw ix, 0x5bb
	extz xix
	ld b, 0x1:opc

TaskSched_CheckTimerSlot:
	ld xwa, (xix + 4)
	cp xwa, 0xffffffff
	jr z, TaskSched_TimerSlot_Skip

	ld wa, (xix + 0:8)
	dec 1, wa
	ld (xix + 0:8), wa
	or wa, wa
	jr z, TaskSched_TimerSlot_Fire

TaskSched_TimerSlot_Skip:
	add ix, 0x8
	djnz8 b, TaskSched_CheckTimerSlot
	ei 6
	ld wa, (1475:16)
	dec 1, wa
	ld (1475:16), wa
	ldc_cr16 wa, 0x7c
	ret

TaskSched_TimerSlot_Fire:
	ld wa, (xix + 2)
	ld (xix + 0:8), wa
	lda xwa, (TaskSched_TimerSlot_Skip:24)
	push xwa
	ld xwa, (xix + 4)
	jp (xwa)


INTT3_CheckNesting:
	pushw wa
	ld wa, (1475:16)
	cp wa, 1:i3
	jr z, INTT3_EnterScheduler
	dec 1, wa
	ld (1475:16), wa
	ldc_cr16 wa, 0x7c
	popw wa
	reti

INTT3_EnterScheduler:
	xor wa, wa
	ld (1475:16), wa
	ldc_cr16 wa, 0x7c
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
;        screen group table at 0xef18eb (12 bytes per entry).
;        Screen Group 7 contains the error dialogs including
;        "ERROR in CPU data transmission".
;
; See also:
;   - ScreenGroup_Dispatch (ScreenGroup_DispatchAlt) - Alternative dispatcher
;   - ErrorDialog_CPUTransmissionError - Error dialog in Screen Group 7
; ===========================================================================
Show_ScreenGroup:
	push	sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld w, a
	ld l, 0xc:opc
	mul hl, a
	extz xhl
	add xhl, TaskSched_ScreenGroupTable - 12	; groups are numbered from 1
	ld c, 0xc:opc
	mul bc, a
	add bc, 0x47d
	extz xbc
	ld xix, xbc
	ld a, (xix + 9)
	cp a, 0:i3
	jrl nz, TaskSched_ReturnToDispatch
	ld (xix + 11), w
	ld xiy, (xhl + 4)
	sub xiy, 0x22
	ld wa, (xhl + 8)
	ld (xiy + 28), wa
	ld xwa, (xhl + 0:8)
	ld (xiy + 30), xwa
	ld (xix + 4), xiy
	ld a, (xhl + 10)
	ld (xix + 8), a
	ld (xix + 9), 0x4
	ld (xix + 10), 0x0
	ld a, (xhl + 10)
	sll a, 2
	extz wa
	add wa, 0x4c1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch
SndTable_ByteBlock_ReadOps_Helper:
	ei 6
	ld xsp, 0x1e53a
	ld ix, (1159:16)
	extz xix
	ld (xix + 9), 0x0
	ld (xix + 10), 0x0
	xor wa, wa
	ld (1159:16), wa
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	jrl TaskSched_Dispatch

TaskSched_GetCurrentGroup:
	ld hl, (1475:16)
	or hl, hl
	jr nz, TaskSched_GetCurrentGroup_Nested
	push xix
	ld ix, (1159:16)
	extz xix
	ld l, (xix + 11)
	extz hl
	pop xix
	ret

TaskSched_GetCurrentGroup_Nested:
	xor hl, hl
	ret

TaskSched_YieldToQueue:
	push	sr
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
	add wa, 0x4c1
	ld iy, wa
	extz xiy
	ld ix, (xiy + 0:8)
	cp ix, (xiy + 2)
	jrl z, TaskSched_ReturnToDispatch
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
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
	add wa, 0x4c1
	ld iy, wa
	extz xiy
	ld ix, (xiy + 0:8)
	cp ix, (xiy + 2)
	jr z, TaskSched_YieldToQueue_NoBlock_Return
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
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
	push	sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld ix, (1159:16)
	extz xix
	ld a, (xix + 10)
	cp a, 0:i3
	jr nz, TaskSched_Resume_DecrementWait
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x3
	jrl TaskSched_Dispatch

TaskSched_Resume_DecrementWait:
	dec 1, a
	ld (xix + 10), a
	jrl TaskSched_ReturnToDispatch

TaskSched_WakeBySlotID:
	push	sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	mul a, 0xc
	add wa, 0x47d
	ld ix, wa
	extz xix
	cp (xix + 9), 0x3
	jr nz, TaskSched_WakeBySlotID_Pending
	ld (xix + 9), 0x4
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4c1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
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
	push	sr
	ei 6
	mul a, 0xc
	add wa, 0x47d
	ld ix, wa
	extz xix
	cp (xix + 9), 0x3
	jr nz, TaskSched_WakeInline_Pending
	ld (xix + 9), 0x4
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4c1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix

TaskSched_WakeInline_Return:
	pop	sr
	pop xiy
	pop xix
	pop xwa
	ret

TaskSched_WakeInline_Pending:
	incm8 1, (xix + 10)
	jr TaskSched_WakeInline_Return
	push	sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	mul a, 0xc
	add wa, 0x47d
	ld ix, wa
	extz xix
	ld l, (xix + 10)
	ld (xix + 10), 0x0
	jrl TaskSched_ReturnToDispatch

TaskSched_SignalEvent:
	push	sr
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
	add wa, 0x4cd
	ld iy, wa
	extz xiy
	ld ix, (xiy + 0:8)
	cp ix, iy
	jr nz, TaskSched_SignalEvent_Unlink
	extz hl
	add hl, 0x4f8
	extz xhl
	setm 0, (xhl)
	jrl TaskSched_ReturnToDispatch

TaskSched_SignalEvent_Unlink:
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x4
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4c1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
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
	add wa, 0x4cd
	ld iy, wa
	extz xiy
	push	sr
	ei 6
	ld ix, (xiy + 0:8)
	cp ix, iy
	jr nz, TaskSched_SignalEvent_NoBlock_Unlink
	extz hl
	add hl, 0x4f8
	extz xhl
	setm 0, (xhl)
	pop	sr
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

TaskSched_SignalEvent_NoBlock_Unlink:
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x4
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4c1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	pop	sr
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

TaskSched_WaitForEvent:
	push	sr
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
	add wa, 0x4f8
	extz xwa
	bitm 0, (xwa)
	jr z, TaskSched_WaitForEvent_Block
	resm 0, (xwa)
	jrl TaskSched_ReturnToDispatch

TaskSched_WaitForEvent_Block:
	ld ix, (1159:16)
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x3
	sll e, 2
	extz de
	add de, 0x4cd
	ld iy, de
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch
	extz wa
	add wa, 0x4f8
	extz xwa
	push	sr
	ei 6
	resm 0, (xwa)
	pop	sr
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
	push	sr
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
	add wa, 0x4ff
	ld iy, wa
	extz xiy
	ld ix, (xiy + 0:8)
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
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x4
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4c1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
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
	add wa, 0x4ff
	ld iy, wa
	extz xiy
	push	sr
	ei 6
	ld ix, (xiy + 0:8)
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
	pop	sr
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

AudioLock_Release_NB_WakeWaiter:
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x4
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4c1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	pop	sr
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
	push	sr
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
	ld ix, (1159:16)
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x3
	sll e, 2
	extz de
	add de, 0x4ff
	ld iy, de
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_Dispatch

AudioLock_TryAcquire:
	extz wa
	add wa, 0x532
	extz xwa
	push	sr
	ei 6
	cp (xwa), 0x0
	jr z, AudioLock_TryAcquire_Fail
	decm8 1, (xwa)
	xor hl, hl
	jr AudioLock_TryAcquire_Return

AudioLock_TryAcquire_Fail:
	ldw hl, 0xffff

AudioLock_TryAcquire_Return:
	pop	sr
	ret

AudioLock_GetCount:
	extz wa
	add wa, 0x532
	extz xwa
	ld l, (xwa)
	extz hl
	ret

TaskMsg_Send:
	push	sr
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
	add wa, 0x53b
	ld iy, wa
	extz xiy
	ld ix, (xiy + 0:8)
	cp ix, iy
	jr nz, TaskMsg_Send_WakeReceiver
	ld ix, (1463:16)
	extz xix
	ld iy, (xix + 0:8)
	cp iy, ix
	jrl z, TaskMsg_Send_QueueFull
	ldw (xsp + 24), 0x0
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 4), xiz
	extz bc
	add bc, 0x54f
	ld iy, bc
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_ReturnToDispatch

TaskMsg_Send_QueueFull:
	ldw (xsp + 24), 0xffff
	jrl TaskSched_ReturnToDispatch

TaskMsg_Send_WakeReceiver:
	ldw (xsp + 24), 0x0
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x4
	ld xwa, (xix + 4)
	ld (xwa + 24), xiz
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4c1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
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
	add wa, 0x53b
	ld iy, wa
	extz xiy
	push	sr
	ei 6
	ld ix, (xiy + 0:8)
	cp ix, iy
	jr nz, TaskMsg_Send_NB_WakeReceiver
	ld ix, (1463:16)
	extz xix
	ld iy, (xix + 0:8)
	cp iy, ix
	jrl z, TaskMsg_Send_NB_QueueFull
	ldw (xsp + 4), 0x0
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 4), xiz
	extz bc
	add bc, 0x54f
	ld iy, bc
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix

TaskMsg_Send_NB_Return:
	pop	sr
	pop xbc
	pop xhl
	pop xiz
	pop xiy
	pop xix
	pop xwa
	ret

TaskMsg_Send_NB_QueueFull:
	ldw (xsp + 4), 0xffff
	jr TaskMsg_Send_NB_Return

TaskMsg_Send_NB_WakeReceiver:
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x4
	ld xwa, (xix + 4)
	ld (xwa + 24), xiz
	ld a, (xix + 8)
	sll a, 2
	extz wa
	add wa, 0x4c1
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	pop	sr
	pop xbc
	pop xhl
	pop xiz
	pop xiy
	pop xix
	pop xwa
	ret

TaskMsg_Receive:
	push	sr
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
	add wa, 0x54f
	ld iy, wa
	extz xiy
	ld ix, (xiy + 0:8)
	cp ix, iy
	jr z, TaskMsg_Receive_Block
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld xiz, (xix + 4)
	ld xbc, 0xffffffff
	ld (xix + 4), xbc
	ldw iy, 0x5b7
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	ld (xsp + 24), xiz
	jrl TaskSched_ReturnToDispatch

TaskMsg_Receive_Block:
	ld ix, (1159:16)
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x3
	add de, 0x53b
	ld iy, de
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
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
	add wa, 0x54f
	ld iy, wa
	push	sr
	ei 6
	extz xiy
	ld ix, (xiy + 0:8)
	cp ix, iy
	jr z, TaskMsg_TryReceive_Empty
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld xiz, (xix + 4)
	ld xwa, 0xffffffff
	ld (xix + 4), xwa
	ldw iy, 0x5b7
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	ld xhl, xiz
	jr TaskMsg_TryReceive_Return

TaskMsg_TryReceive_Empty:
	xor xhl, xhl

TaskMsg_TryReceive_Return:
	pop	sr
	pop xiz
	pop xix
	ret

TaskTimer_Register:
	push	sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld xix, xwa
	ld a, (xix + 0:8)
	mul a, 0x8
	add wa, 0x5b3
	ld iy, wa
	extz xiy
	ld wa, (xix + 2)
	ld (xiy + 0:8), wa
	ld (xiy + 2), wa
	ld xwa, (xix + 4)
	ld (xiy + 4), xwa
	jrl TaskSched_Dispatch

TaskSched_ChangePriority:
	push	sr
	ei 6
	push xhl
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld e, c
	mul a, 0xc
	add wa, 0x47d
	ld ix, wa
	extz xix
	cp (xix + 9), 0x4
	jr nz, TaskSched_ChangePriority_NotReady
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 8), e
	sll e, 2
	extz de
	add de, 0x4c1
	ld iy, de
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
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
	mul a, 0xc
	add wa, 0x47d
	ld ix, wa
	extz xix
	push	sr
	ei 6
	cp (xix + 9), 0x4
	jr nz, TaskSched_ChangePriority_Inline_NotReady
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 0:8)
	ld hl, (xix + 2)
	ld (xhl + 0:8), wa
	ld (xwa + 2), hl
	ld (xix + 8), e
	sll e, 2
	extz de
	add de, 0x4c1
	ld iy, de
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 0:8), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jr TaskSched_ChangePriority_Inline_Return

TaskSched_ChangePriority_Inline_NotReady:
	ld (xix + 8), e

TaskSched_ChangePriority_Inline_Return:
	pop	sr
	popw de
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

TaskSched_TCBTemplate:
	pushw	wa
	push	xix
	push	xiy
	push	xhl
	ei	0x06
	mul	a, 12
	add	wa, 1149
	ld	ix, wa
	extz	xix
	xor	xwa, xwa
	xor	xhl, xhl
	ld wa, (xix+0:8)
	ld	hl, (xix+2)
	ld (xhl+0:8), wa
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
	add wa, (SYSTEM_TIMESTAMP:16)

TaskSched_DelayTicks_SpinLoop:
	cp wa, (SYSTEM_TIMESTAMP:16)
	jr gt, TaskSched_DelayTicks_SpinLoop
	ret

Start_8bit_Timer_3:
	set	3, (T8RUN:8)
	ret

Stop_and_Clear_8bit_Timer_3:
	res	3, (T8RUN:8)
	ret

SeqBuf_BytecodeSnippet:
	incw	1, (1475:16)
	ret
	decw	1, (0x5c3:16)
	ret
SeqBuf_ReadByte:
	pushw ix
	push xde
	lda xde, (0x01e549:24)
	calr RingBuf_CheckFull_512
	pop xde
	popw ix
	ret

SeqBuf_WriteByte:
	link	xiz, 0x0000
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda xde, (0x01e549:24)
	calr Seq_RingBuf_WriteByte_512
	pop xde
	popw ix
	unlk	xiz
	ret

SeqBuf_WriteBytes:
	link	xiz, 0x0000
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda xde, (0x01e549:24)

SeqBuf_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_512
	inc 1, xiy
	djnz16 bc, SeqBuf_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk	xiz
	ret

SeqBuf_InlineBytecode:
	ld	hl, (0x1e545:24)
	cp	hl, (0x1e541:24)
	ld	hl, 0:i3
	jr	z, SeqBuf_WriteBytes_Return
	ldw	hl, 0xffff
SeqBuf_WriteBytes_Return:
	ret

SeqBuf_GetWritePos:
	ld hl, (0x01e547:24)
	ret

SeqBuf_Init:
	pushw ix
	push xde
	lda xde, (0x01e549:24)
	call Seq_RingBuf_Init_512
	pop xde
	popw ix
	ret

SeqBuf_SaveReadPos:
	pushw hl
	ld hl, (0x01e541:24)
	ld (0x01e53f:24), hl
	popw hl
	ret

SeqBuf_ReadAlternate:
	pushw ix
	push xde
	lda xde, (0x01e549:24)
	call RingBuf_CheckFull_256
	pop xde
	popw ix
	ret

SeqBuf_ReadAlternate2:
	pushw	ix
	push	xde
	lda	xde, (0x1e549:24)
	call	RingBuf512_ReadAlt_ByteBlock
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld	hl, (0x1e543:24)
	ld	(0x1e541:24), hl
	popw	hl
	ret

SeqBuf_SaveWritePos:
	pushw hl
	ld hl, (0x01e545:24)
	ld (0x01e543:24), hl
	popw hl
	ret

TempoRingBuf_ReadByte:
	pushw ix
	push xde
	lda xde, (0x01e753:24)
	calr Seq_RingBuf_PeekByte
	pop xde
	popw ix
	ret

TempoRingBuf_WriteByte_Ext:
	link	xiz, 0x0000
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda xde, (0x01e753:24)
	calr Seq_RingBuf_WriteByte_Check
	pop xde
	popw ix
	unlk	xiz
	ret

TempoRingBuf_WriteBytes:
	link	xiz, 0x0000
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda xde, (0x01e753:24)

TempoRingBuf_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_Check
	inc 1, xiy
	djnz16 bc, TempoRingBuf_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk	xiz
	ret

TempoRingBuf_CheckEmpty:
	ld hl, (0x01e74f:24)
	cp hl, (0x1e74b:24)
	ld hl, 0:i3
	jr z, TempoRingBuf_CheckEmpty_Return
	ldw hl, 0xffff

TempoRingBuf_CheckEmpty_Return:
	ret

TempoRingBuf_BytecodeSnippet2:
	ld	hl, (0x1e751:24)
	ret

TempoRingBuf_Init:
	pushw ix
	push xde
	lda xde, (0x01e753:24)
	call Seq_RingBuf_Init_2048
	pop xde
	popw ix
	ret

TempoRingBuf_SaveReadPos:
	pushw hl
	ld hl, (0x01e74b:24)
	ld (0x01e749:24), hl
	popw hl
	ret

TempoRingBuf_InlineBytecode2:
	pushw	ix
	push	xde
	lda	xde, (0x1e753:24)
	call	Seq_RingBuf_WriteByte_Data
	pop	xde
	popw	ix
	ret

TempoRingBuf_ReadAlternate:
	pushw ix
	push xde
	lda xde, (0x01e753:24)
	call Seq_RingBuf_ReadAhead
	pop xde
	popw ix
	ret

TempoRingBuf_SaveWritePos:
	pushw	hl
	ld	hl, (0x1e74d:24)
	ld	(0x1e74b:24), hl
	popw	hl
	ret
	pushw	hl
	ld	hl, (0x1e74f:24)
	ld	(0x1e74d:24), hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda	xde, (0x1ef5d:24)
	calr	RingBuf_CheckFull_512
	pop	xde
	popw	ix
	ret

RhythmBuf_WriteByte:
	link	xiz, 0x0000
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda xde, (0x01ef5d:24)
	calr Seq_RingBuf_WriteByte_512
	pop xde
	popw ix
	unlk	xiz
	ret

RhythmBuf_InlineBytecode:
	link	xiz, 0
	push	xiy
	push	xix
	push	xde
	ld	bc, (xiz+8)
	ld	xiy, (xiz+10)
	lda	xde, (0x1ef5d:24)
	ld	a, (xiy)
	calr	Seq_RingBuf_WriteByte_512
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret

RhythmBuf_CheckEmpty:
	ld hl, (0x01ef59:24)
	cp hl, (0x1ef55:24)
	ld hl, 0:i3
	jr z, RhythmBuf_CheckEmpty_Return
	ldw hl, 0xffff

RhythmBuf_CheckEmpty_Return:
	ret

RhythmBuf_BytecodeSnippet:
	ld	hl, (0x1ef5b:24)
	ret

RhythmBuf_Init:
	pushw ix
	push xde
	lda xde, (0x01ef5d:24)
	call Seq_RingBuf_Init_512
	pop xde
	popw ix
	ret

RhythmBuf_SaveWritePos:
	pushw hl
	ld hl, (0x01ef55:24)
	ld (0x01ef53:24), hl
	popw hl
	ret

RhythmBuf_ReadAlternate:
	pushw ix
	push xde
	lda xde, (0x01ef5d:24)
	call RingBuf_CheckFull_256
	pop xde
	popw ix
	ret

RhythmBuf_InlineBytecode2:
	pushw	ix
	push	xde
	lda	xde, (0x1ef5d:24)
	call	RingBuf512_ReadAlt_ByteBlock
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld	hl, (0x1ef57:24)
	ld	(0x1ef55:24), hl
	popw	hl
	ret
	pushw	hl
	ld	hl, (0x1ef59:24)
	ld	(0x1ef57:24), hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda	xde, (0x1f167:24)
	calr	Seq_RingBuf_ReadByte
	pop	xde
	popw	ix
	ret
	link	xiz, 0
	pushw	ix
	push	xde
	ld	a, (xiz+8)
	lda	xde, (0x1f167:24)
	calr	Seq_RingBuf_WriteByte_Small
	pop	xde
	popw	ix
	unlk	xiz
	ret

AltEvtBuf_WriteBytes:
	link	xiz, 0x0000
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda xde, (0x01f167:24)

AltEvtBuf_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_Small
	inc 1, xiy
	djnz16 bc, AltEvtBuf_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk	xiz
	ret

AltEvtBuf_InlineBytecode:
	ld	hl, (0x1f163:24)
	cp	hl, (0x1f15f:24)
	ld	hl, 0:i3
	jr	z, AltEvtBuf_WriteBytes_Return
	ldw	hl, 0xffff
AltEvtBuf_WriteBytes_Return:
	ret
	ld	hl, (0x1f165:24)
	ret

AltEvtBuf_Init:
	pushw ix
	push xde
	lda xde, (0x01f167:24)
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret

AltEvtBuf_Helpers:
	pushw	hl
	ld	hl, (0x1f15f:24)
	ld	(0x1f15d:24), hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda	xde, (0x1f167:24)
	call	Seq_RingBuf_ReadByte_Large
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda	xde, (0x1f167:24)
	call	Seq_RingBuf_ReadByte_Small
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld	hl, (0x1f161:24)
	ld	(0x1f15f:24), hl
	popw	hl
	ret
	pushw	hl
	ld	hl, (0x1f163:24)
	ld	(0x1f161:24), hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda	xde, (0x1f271:24)
	calr	Seq_RingBuf_ReadByte
	pop	xde
	popw	ix
	ret

SeqEvtBuf_WriteByte:
	link	xiz, 0x0000
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda xde, (0x01f271:24)
	calr Seq_RingBuf_WriteByte_Small
	pop xde
	popw ix
	unlk	xiz
	ret

SeqEvtBuf_InlineBytecode:
	link	xiz, 0
	push	xiy
	push	xix
	push	xde
	ld	bc, (xiz+8)
	ld	xiy, (xiz+10)
	lda	xde, (0x1f271:24)
	ld	a, (xiy)
	calr	Seq_RingBuf_WriteByte_Small
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld	hl, (0x1f26d:24)
	cp	hl, (0x1f269:24)
	ld	hl, 0:i3
	jr	z, SeqEvtBuf_WriteByte_Return
	ldw	hl, 0xffff
SeqEvtBuf_WriteByte_Return:
	ret
	ld	hl, (0x1f26f:24)
	ret
SeqEvtBuf_Init:
	pushw ix
	push xde
	lda xde, (0x01f271:24)
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret

SeqEvtBuf_SaveReadPos:
	pushw hl
	ld hl, (0x01f269:24)
	ld (0x01f267:24), hl
	popw hl
	ret

SeqEvtBuf_ReadAlternate:
	pushw ix
	push xde
	lda xde, (0x01f271:24)
	call Seq_RingBuf_ReadByte_Large
	pop xde
	popw ix
	ret

SeqEvtBuf_ReadAlternate2:
	; --- Sub 1: call EF2FBC with XDE=0x01f271 (14 bytes) ---
	pushw ix
	push xde
	lda	xde, (0x1f271:24)
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret
SeqEvtBuf_SaveReadPos2:
	; --- Sub 2: copy (0x01f26b)->HL->(0x01f269) (13 bytes) ---
	pushw hl
	ld	hl, (0x1f26b:24)
	ld	(0x1f269:24), hl
	popw hl
	ret
SeqEvtBuf_SaveReadPos3:
	; --- Sub 3: copy (0x01f26d)->HL->(0x01f26b) (13 bytes) ---
	pushw hl
	ld	hl, (0x1f26d:24)
	ld	(0x1f26b:24), hl
	popw hl
	ret
SeqMain_ReadByte_1024:
	; --- Sub 4: calr EF30A1 with XDE=0x01f37b (13 bytes) ---
	pushw ix
	push xde
	lda	xde, (0x1f37b:24)
	calr Seq_RingBuf_Dequeue_1024
	pop xde
	popw ix
	ret


SeqMain_WriteByte:
	link	xiz, 0x0000
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda xde, (0x01f37b:24)
	calr Seq_RingBuf_WriteByte
	pop xde
	popw ix
	unlk	xiz
	ret

SeqMain_WriteBytes:
	link	xiz, 0x0000
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda xde, (0x01f37b:24)

SeqMain_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte
	inc 1, xiy
	djnz16 bc, SeqMain_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk	xiz
	ret

Seq_CheckSongEnd:
	ld hl, (0x01f377:24)
	cp hl, (0x1f373:24)
	ld hl, 0:i3
	jr z, Seq_CheckSongEnd_Return
	ldw hl, 0xffff

Seq_CheckSongEnd_Return:
	ret

SeqMain_GetTimingValue:
	ld hl, (0x01f379:24)
	ret

SeqMain_InitBuffer:
	pushw ix
	push xde
	lda xde, (0x01f37b:24)
	call Seq_RingBuf_Init_1024
	pop xde
	popw ix
	ret

SeqMain_SaveWritePos:
	pushw hl
	ld hl, (0x01f373:24)
	ld (0x01f371:24), hl
	popw hl
	ret

SeqMain_ReadData:
	pushw ix
	push xde
	lda xde, (0x01f37b:24)
	call Seq_RingBuf_ReadData
	pop xde
	popw ix
	ret

SeqMain_ReadAlternate:
	pushw	ix
	push	xde
	lda	xde, (0x1f37b:24)
	call	RingBuf1024_ReadAlt_ByteBlock
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld	hl, (0x1f375:24)
	ld	(0x1f373:24), hl
	popw	hl
	ret
	pushw	hl
	ld	hl, (0x1f377:24)
	ld	(0x1f375:24), hl
	popw	hl
	ret

SeqBuf_MidiOut_ReadByte:
	pushw ix
	push xde
	lda xde, (0x01f785:24)
	calr Seq_RingBuf_ReadByte
	pop xde
	popw ix
	ret

SeqBuf_MidiOut_WriteByte:
	link	xiz, 0x0000
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda xde, (0x01f785:24)
	calr Seq_RingBuf_WriteByte_Small
	pop xde
	popw ix
	unlk	xiz
	ret

SeqBuf_MidiOut_WriteBytes:
	link	xiz, 0x0000
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda xde, (0x01f785:24)

SeqBuf_MidiOut_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_Small
	inc 1, xiy
	djnz16 bc, SeqBuf_MidiOut_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk	xiz
	ret

SeqBuf_MidiOut_CheckEmpty:
	ld hl, (0x01f781:24)
	cp hl, (0x1f77d:24)
	ld hl, 0:i3
	jr z, SeqBuf_MidiOut_CheckEmpty_Return
	ldw hl, 0xffff

SeqBuf_MidiOut_CheckEmpty_Return:
	ret

SeqBuf_MidiOut_GetTimingValue:
	ld hl, (0x01f783:24)
	ret

SeqBuf_MidiOut_Init:
	pushw ix
	push xde
	lda xde, (0x01f785:24)
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret

SeqBuf_MidiOut_SaveReadPos:
	; --- Sub 1: copy (0x01f77d)->HL->(0x01f77b) (13 bytes) ---
	pushw hl
	ld	hl, (0x1f77d:24)
	ld	(0x1f77b:24), hl
	popw hl
	ret
SeqBuf_MidiOut_ReadAlternate:
	; --- Sub 2: call EF2FA1 with XDE=0x01f785 (14 bytes) ---
	pushw ix
	push xde
	lda	xde, (0x1f785:24)
	call Seq_RingBuf_ReadByte_Large
	pop xde
	popw ix
	ret
SeqBuf_MidiOut_ReadAlternate2:
	; --- Sub 3: call EF2FBC with XDE=0x01f785 (14 bytes) ---
	pushw ix
	push xde
	lda	xde, (0x1f785:24)
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret
SeqBuf_MidiOut_SaveReadPos2:
	; --- Sub 4: copy (0x01f77f)->HL->(0x01f77d) (13 bytes) ---
	pushw hl
	ld	hl, (0x1f77f:24)
	ld	(0x1f77d:24), hl
	popw hl
	ret
SeqBuf_MidiOut_SaveReadPos3:
	; --- Sub 5: copy (0x01f781)->HL->(0x01f77f) (13 bytes) ---
	pushw hl
	ld	hl, (0x1f781:24)
	ld	(0x1f77f:24), hl
	popw hl
	ret


SeqBuf2_ReadByte:
	pushw ix
	push xde
	lda xde, (0x01f88f:24)
	calr RingBuf_CheckFull_512
	pop xde
	popw ix
	ret

SeqBuf2_WriteByte:
	link	xiz, 0x0000
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda xde, (0x01f88f:24)
	calr Seq_RingBuf_WriteByte_512
	pop xde
	popw ix
	unlk	xiz
	ret

SeqBuf2_WriteBytes:
	link	xiz, 0x0000
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda xde, (0x01f88f:24)

SeqBuf2_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_512
	inc 1, xiy
	djnz16 bc, SeqBuf2_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk	xiz
	ret

SeqBuf2_InlineBytecode:
	ld	hl, (0x1f88b:24)
	cp	hl, (0x1f887:24)
	ld	hl, 0:i3
	jr	z, SeqBuf2_WriteBytes_Return
	ldw	hl, 0xffff
SeqBuf2_WriteBytes_Return:
	ret
	ld	hl, (0x1f88d:24)
	ret

SeqBuf2_Init:
	pushw ix
	push xde
	lda xde, (0x01f88f:24)
	call Seq_RingBuf_Init_512
	pop xde
	popw ix
	ret

SeqBuf2_SaveReadPos:
	; --- Sub 1: copy (0x01f887)->HL->(0x01f885) (13 bytes) ---
	pushw hl
	ld	hl, (0x1f887:24)
	ld	(0x1f885:24), hl
	popw hl
	ret
SeqBuf2_ReadAlternate:
	; --- Sub 2: call EF3030 with XDE=0x01f88f (14 bytes) ---
	pushw ix
	push xde
	lda	xde, (0x1f88f:24)
	call RingBuf_CheckFull_256
	pop xde
	popw ix
	ret
SeqBuf2_ReadAlternate2:
	; --- Sub 3: call EF304B with XDE=0x01f88f (14 bytes) ---
	pushw ix
	push xde
	lda	xde, (0x1f88f:24)
	call RingBuf512_ReadAlt_ByteBlock
	pop xde
	popw ix
	ret
SeqBuf2_SaveReadPos2:
	; --- Sub 4: copy (0x01f889)->HL->(0x01f887) (13 bytes) ---
	pushw hl
	ld	hl, (0x1f889:24)
	ld	(0x1f887:24), hl
	popw hl
	ret
SeqBuf2_SaveReadPos3:
	; --- Sub 5: copy (0x01f88b)->HL->(0x01f889) (13 bytes) ---
	pushw hl
	ld	hl, (0x1f88b:24)
	ld	(0x1f889:24), hl
	popw hl
	ret


SeqBuf3_ReadByte:
	pushw ix
	push xde
	lda xde, (0x01fa99:24)
	calr RingBuf_CheckFull_512
	pop xde
	popw ix
	ret

SeqBuf3_WriteByte:
	link	xiz, 0x0000
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda xde, (0x01fa99:24)
	calr Seq_RingBuf_WriteByte_512
	pop xde
	popw ix
	unlk	xiz
	ret

SeqBuf3_WriteBytes:
	link	xiz, 0x0000
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda xde, (0x01fa99:24)

SeqBuf3_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_512
	inc 1, xiy
	djnz16 bc, SeqBuf3_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk	xiz
	ret

SeqBuf3_InlineBytecode:
	ld	hl, (0x1fa95:24)
	cp	hl, (0x1fa91:24)
	ld	hl, 0:i3
	jr	z, SeqBuf3_WriteBytes_Return
	ldw	hl, 0xffff
SeqBuf3_WriteBytes_Return:
	ret

SeqBuf3_GetTimingValue:
	ld hl, (0x01fa97:24)
	ret

SeqBuf3_Init:
	pushw ix
	push xde
	lda xde, (0x01fa99:24)
	call Seq_RingBuf_Init_512
	pop xde
	popw ix
	ret

SeqBuf3_Helpers:
	pushw	hl
	ld	hl, (0x1fa91:24)
	ld	(0x1fa8f:24), hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda	xde, (0x1fa99:24)
	call	RingBuf_CheckFull_256
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda	xde, (0x1fa99:24)
	call	RingBuf512_ReadAlt_ByteBlock
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld	hl, (0x1fa93:24)
	ld	(0x1fa91:24), hl
	popw	hl
	ret
	pushw	hl
	ld	hl, (0x1fa95:24)
	ld	(0x1fa93:24), hl
	popw	hl
	ret

SeqBuf_DspSysEx_ReadByte:
	pushw ix
	push xde
	lda xde, (0x01fca3:24)
	calr Seq_RingBuf_Dequeue_1024
	pop xde
	popw ix
	ret


SeqBuf_DspSysEx_WriteByte:
	link	xiz, 0x0000
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda xde, (0x01fca3:24)
	calr Seq_RingBuf_WriteByte
	pop xde
	popw ix
	unlk	xiz
	ret

SeqBuf_DspSysEx_WriteBytes:
	link	xiz, 0x0000
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda xde, (0x01fca3:24)

SeqBuf_DspSysEx_WriteBytes_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte
	inc 1, xiy
	djnz16 bc, SeqBuf_DspSysEx_WriteBytes_Loop
	pop xde
	pop xix
	pop xiy
	unlk	xiz
	ret


SeqBuf_DspSysEx_CheckSongEnd:
	ld hl, (0x01fc9f:24)
	cp hl, (0x1fc9b:24)
	ld hl, 0:i3
	jr z, SeqBuf_DspSysEx_CheckSongEnd_Return
	ldw hl, 0xffff

SeqBuf_DspSysEx_CheckSongEnd_Return:
	ret

SeqBuf_DspSysEx_OrphanData:
	ld	hl, (0x1fca1:24)
	ret

SeqBuf_DspSysEx_InitBuffer:
	pushw ix
	push xde
	lda xde, (0x01fca3:24)
	call Seq_RingBuf_Init_1024
	pop xde
	popw ix
	ret

SeqBuf_DspSysEx_CopyPointers:
	pushw	hl
	ld	hl, (0x1fc9b:24)
	ld	(0x1fc99:24), hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda	xde, (0x1fca3:24)
	call	Seq_RingBuf_ReadData
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda	xde, (0x1fca3:24)
	call	RingBuf1024_ReadAlt_ByteBlock
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld	hl, (0x1fc9d:24)
	ld	(0x1fc9b:24), hl
	popw	hl
	ret
	pushw	hl
	ld	hl, (0x1fc9f:24)
	ld	(0x1fc9d:24), hl
	popw	hl
	ret


; Pop one byte from CPANEL_RX_EVENT_QUEUE (RingBuf128_CheckEmpty); hl = 0xFFFF when empty.
CPanel_RxEventQueue_Pop:
	pushw ix
	push xde
	lda xde, (CPANEL_RX_EVENT_QUEUE:24)
	calr RingBuf128_CheckEmpty
	pop xde
	popw ix
	ret


CPanel_RxEventQueue_Push:
	link	xiz, 0
	pushw	ix
	push	xde
	ld	a, (xiz+8)
	lda	xde, (CPANEL_RX_EVENT_QUEUE:24)
	calr	RingBuf128_WriteByte_CheckFull
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
	lda	xde, (CPANEL_RX_EVENT_QUEUE:24)
	ld	a, (xiy)
	calr	RingBuf128_WriteByte_CheckFull
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld	hl, (0x200a9:24)
	cp hl, (131237:24)
	ld	hl, 0:i3
	jr	z, Seq_DataHandler_Return
	ldw	hl, 0xffff
Seq_DataHandler_Return:
	ret
	ld	hl, (0x200ab:24)
	ret
	pushw	ix
	push	xde
	lda	xde, (CPANEL_RX_EVENT_QUEUE:24)
	call	RingBuf_InitStructFields
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld	hl, (0x200a5:24)
	ld	(0x200a3:24), hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda	xde, (CPANEL_RX_EVENT_QUEUE:24)
	call	RingBuf128_ReadAlt_CheckEmpty
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda	xde, (CPANEL_RX_EVENT_QUEUE:24)
	call	RingBuf128_ReadAlt2_CheckEmpty
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld	hl, (0x200a7:24)
	ld	(0x200a5:24), hl
	popw	hl
	ret
	pushw	hl
	ld	hl, (0x200a9:24)
	ld	(0x200a7:24), hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda	xde, (CPANEL_LED_EVENT_QUEUE:24)
	calr	RingBuf128_CheckEmpty
	pop	xde
	popw	ix
	ret


Seq_TimerEventLoop:
	link	xiz, 0x0000
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda xde, (CPANEL_LED_EVENT_QUEUE:24)
	calr RingBuf128_WriteByte_CheckFull
	pop xde
	popw ix
	unlk	xiz
	ret


SeqBuf_TimerEvent_BytecodeBlock2:
	link	xiz, 0
	push	xiy
	push	xix
	push	xde
	ld	bc, (xiz+8)
	ld	xiy, (xiz+10)
	lda	xde, (CPANEL_LED_EVENT_QUEUE:24)
	ld	a, (xiy)
	calr	RingBuf128_WriteByte_CheckFull
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld	hl, (0x20133:24)
	cp	hl, (0x2012f:24)
	ld	hl, 0:i3
	jr	z, Seq_TimerEventLoop_Return
	ldw	hl, 0xffff
Seq_TimerEventLoop_Return:
	ret
	ld	hl, (0x20135:24)
	ret
	pushw	ix
	push	xde
	lda	xde, (CPANEL_LED_EVENT_QUEUE:24)
	call	RingBuf_InitStructFields
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld	hl, (0x2012f:24)
	ld	(0x2012d:24), hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda	xde, (CPANEL_LED_EVENT_QUEUE:24)
	call	RingBuf128_ReadAlt_CheckEmpty
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda	xde, (CPANEL_LED_EVENT_QUEUE:24)
	call	RingBuf128_ReadAlt2_CheckEmpty
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld	hl, (0x20131:24)
	ld	(0x2012f:24), hl
	popw	hl
	ret
	pushw	hl
	ld	hl, (0x20133:24)
	ld	(0x20131:24), hl
	popw	hl
	ret


SeqBuf_VoiceMap_ReadByte:
	pushw ix
	push xde
	lda xde, (SEQ_ALT3_RINGBUF_BASE:24)
	calr Seq_RingBuf_ReadByte
	pop xde
	popw ix
	ret


SeqBuf_VoiceMap_WriteByte:
	link	xiz, 0x0000
	pushw ix
	push xde
	ld a, (xiz + 8)
	lda xde, (SEQ_ALT3_RINGBUF_BASE:24)
	calr Seq_RingBuf_WriteByte_Small
	pop xde
	popw ix
	unlk	xiz
	ret


SeqBuf_VoiceMap_WriteBlock:
	link	xiz, 0x0000
	push xiy
	push xix
	push xde
	ld bc, (xiz + 8)
	ld xiy, (xiz + 10)
	lda xde, (SEQ_ALT3_RINGBUF_BASE:24)

SeqBuf_VoiceMap_WriteBlock_Loop:
	ld a, (xiy)
	calr Seq_RingBuf_WriteByte_Small
	inc 1, xiy
	djnz16 bc, SeqBuf_VoiceMap_WriteBlock_Loop
	pop xde
	pop xix
	pop xiy
	unlk	xiz
	ret

SeqBuf_VoiceMap_CheckEmpty:
	ld hl, (0x0201bd:24)
	cp hl, (0x201b9:24)
	ld hl, 0:i3
	jr z, SeqBuf_VoiceMap_CheckEmpty_Done
	ldw hl, 0xffff

SeqBuf_VoiceMap_CheckEmpty_Done:
	ret


SeqBuf_VoiceMap_GetWritePos:
	ld hl, (0x0201bf:24)
	ret


SeqBuf_VoiceMap_Flush:
	pushw ix
	push xde
	lda xde, (SEQ_ALT3_RINGBUF_BASE:24)
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret

SeqBuf_VoiceMap_SaveWritePtr:
	; --- Sub 1: copy (0x0201b9)->HL->(0x0201b7) (13 bytes) ---
	pushw hl
	ld	hl, (0x201b9:24)
	ld	(0x201b7:24), hl
	popw hl
	ret
SeqBuf_VoiceMap_CommitWrite:
	; --- Sub 2: call EF2FA1 with XDE=0x0201c1 (14 bytes) ---
	pushw ix
	push xde
	lda	xde, (SEQ_ALT3_RINGBUF_BASE:24)
	call Seq_RingBuf_ReadByte_Large
	pop xde
	popw ix
	ret
SeqBuf_VoiceMap_RollbackWrite:
	; --- Sub 3: call EF2FBC with XDE=0x0201c1 (14 bytes) ---
	pushw ix
	push xde
	lda	xde, (SEQ_ALT3_RINGBUF_BASE:24)
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret
SeqBuf_VoiceMap_SaveReadPtr:
	; --- Sub 4: copy (0x0201bb)->HL->(0x0201b9) (13 bytes) ---
	pushw hl
	ld	hl, (0x201bb:24)
	ld	(0x201b9:24), hl
	popw hl
	ret
SeqBuf_VoiceMap_AdvanceCheckpoint:
	; --- Sub 5: copy (0x0201bd)->HL->(0x0201bb) (13 bytes) ---
	pushw hl
	ld	hl, (0x201bd:24)
	ld	(0x201bb:24), hl
	popw hl
	ret


SeqBuf_NoteEvent_ReadByte:
	pushw ix
	push xde
	lda xde, (0x0202cb:24)
	calr Seq_RingBuf_ReadByte
	pop xde
	popw ix
	ret

SeqBuf_NoteEvent_WriteByte_Data:
	link	xiz, 0
	pushw	ix
	push	xde
	ld	a, (xiz+8)
	lda	xde, (0x202cb:24)
	calr	Seq_RingBuf_WriteByte_Small
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
	lda	xde, (0x202cb:24)
	ld	a, (xiy)
	calr	Seq_RingBuf_WriteByte_Small
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld	hl, (0x202c7:24)
	cp hl, (131779:24)
	ld	hl, 0:i3
	jr	z, SeqBuf_NoteEvent_WriteByte_Data_Return
	ldw	hl, 0xffff
SeqBuf_NoteEvent_WriteByte_Data_Return:
	ret
	ld	hl, (0x202c9:24)
	ret

SeqBuf_NoteEvent_Flush:
	pushw ix
	push xde
	lda xde, (0x0202cb:24)
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret


SeqBuf_NoteEvent_SaveWritePtr:
	pushw	hl
	ld	hl, (0x202c3:24)
	ld	(0x202c1:24), hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda	xde, (0x202cb:24)
	call	Seq_RingBuf_ReadByte_Large
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda	xde, (0x202cb:24)
	call	Seq_RingBuf_ReadByte_Small
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld	hl, (0x202c5:24)
	ld	(0x202c3:24), hl
	popw	hl
	ret
	pushw	hl
	ld	hl, (0x202c7:24)
	ld	(0x202c5:24), hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda	xde, (0x203d5:24)
	calr	Seq_RingBuf_ReadByte
	pop	xde
	popw	ix
	ret

SeqBuf_NoteEvent_WriteByte_Block:
	link	xiz, 0
	pushw	ix
	push	xde
	ld	a, (xiz+8)
	lda	xde, (0x203d5:24)
	calr	Seq_RingBuf_WriteByte_Small
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
	lda	xde, (0x203d5:24)
	ld	a, (xiy)
	calr	Seq_RingBuf_WriteByte_Small
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld	hl, (0x203d1:24)
	cp hl, (132045:24)
	ld	hl, 0:i3
	jr	z, SeqBuf_NoteEvent_WriteByte_Block_Return
	ldw	hl, 0xffff
SeqBuf_NoteEvent_WriteByte_Block_Return:
	ret
	ld	hl, (0x203d3:24)
	ret

SeqBuf_SoundEdit_Flush:
	pushw ix
	push xde
	lda xde, (0x0203d5:24)
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret

SeqBuf_SoundEdit_SaveWritePtr:
	; --- Sub 1: copy (0x0203cd)->HL->(0x0203cb) (13 bytes) ---
	pushw hl
	ld	hl, (0x203cd:24)
	ld	(0x203cb:24), hl
	popw hl
	ret
SeqBuf_SoundEdit_CommitWrite:
	; --- Sub 2: call EF2FA1 with XDE=0x0203d5 (14 bytes) ---
	pushw ix
	push xde
	lda	xde, (0x203d5:24)
	call Seq_RingBuf_ReadByte_Large
	pop xde
	popw ix
	ret
SeqBuf_SoundEdit_RollbackWrite:
	; --- Sub 3: call EF2FBC with XDE=0x0203d5 (14 bytes) ---
	pushw ix
	push xde
	lda	xde, (0x203d5:24)
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret
SeqBuf_SoundEdit_SaveReadPtr:
	; --- Sub 4: copy (0x0203cf)->HL->(0x0203cd) (13 bytes) ---
	pushw hl
	ld	hl, (0x203cf:24)
	ld	(0x203cd:24), hl
	popw hl
	ret
SeqBuf_SoundEdit_AdvanceCheckpoint:
	; --- Sub 5: copy (0x0203d1)->HL->(0x0203cf) (13 bytes) ---
	pushw hl
	ld	hl, (0x203d1:24)
	ld	(0x203cf:24), hl
	popw hl
	ret


SeqBuf_SoundEdit_ReadByte:
	pushw ix
	push xde
	lda xde, (0x0204df:24)
	calr Seq_RingBuf_ReadByte
	pop xde
	popw ix
	ret

SeqBuf_SoundEdit_BytecodeBlock:
	link	xiz, 0
	pushw	ix
	push	xde
	ld	a, (xiz+8)
	lda	xde, (0x204df:24)
	calr	Seq_RingBuf_WriteByte_Small
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
	lda	xde, (0x204df:24)
	ld	a, (xiy)
	calr	Seq_RingBuf_WriteByte_Small
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret

SeqBuf_NoteEvent_CheckSongEnd:
	ld hl, (0x0204db:24)
	cp hl, (0x204d7:24)
	ld hl, 0:i3
	jr z, SeqBuf_NoteEvent_CheckSongEnd_Return
	ldw hl, 0xffff

SeqBuf_NoteEvent_CheckSongEnd_Return:
	ret

SeqBuf_NoteEvent_OrphanData:
	ld	hl, (0x204dd:24)
	ret

SeqBuf_NoteEvent_InitBuffer:
	pushw ix
	push xde
	lda xde, (0x0204df:24)
	call Seq_RingBuf_Init_256
	pop xde
	popw ix
	ret

SeqBuf_NoteEvent_CopyPointers:
	pushw hl
	ld hl, (0x0204d7:24)
	ld (0x0204d5:24), hl
	popw hl
	ret

SeqBuf_NoteEvent_AlternateRead:
	pushw	ix
	push	xde
	lda	xde, (0x204df:24)
	call	Seq_RingBuf_ReadByte_Large
	pop	xde
	popw	ix
	ret

Seq_RingBuf_ReadSmall:
	pushw ix
	push xde
	lda xde, (0x0204df:24)
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret


RingBuf_CopyPtr_Sub1:
	; --- Sub 1: copy (0x0204d9)->HL->(0x0204d7) (13 bytes) ---
	pushw hl
	ld	hl, (0x204d9:24)
	ld	(0x204d7:24), hl
	popw hl
	ret
RingBuf_CopyPtr_Sub2:
	; --- Sub 2: copy (0x0204db)->HL->(0x0204d9) (13 bytes) ---
	pushw hl
	ld	hl, (0x204db:24)
	ld	(0x204d9:24), hl
	popw hl
	ret
RingBuf_InitStructFields:
	; --- Sub 3: init XDE struct fields at offsets -10..-2 (26 bytes) ---
	ldw (xde-10), 0
	ldw	(xde-8), 0
	ldw	(xde-4), 0
	ldw	(xde-6), 0
	ldw	(xde-2), 127
	ret


RingBuf128_CheckEmpty:
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, RingBuf128_ReadByte
	ldw hl, 0xffff
	ret

RingBuf128_ReadByte:
	xor hl, hl
	ld	l, (xde+ix)
	minc1_16 ix, 0x7f
	ld (xde - 8), ix
	incw 1, (xde - 2)
	ret


RingBuf128_ReadAlt_CheckEmpty:
	; --- Ring buffer read 1: ix=(xde-10), check vs (xde-6), read (xde+ix) (27 bytes) ---
	ld ix, (xde-10)
	cp	ix, (xde-6)
	jr nz, RingBuf128_ReadAlt_Dequeue
	ldw hl, 0xffff
	ret
RingBuf128_ReadAlt_Dequeue:
	xor hl, hl
	ld	l, (xde+ix)
	.byte	0xdc, 0x38, 0x7f, 0x00	; minc1 0x007f,IX
	ld (xde-10), ix
	ret
RingBuf128_ReadAlt2_CheckEmpty:
	; --- Ring buffer read 2: same structure, check vs (xde-4) (27 bytes) ---
	ld ix, (xde-10)
	cp	ix, (xde-4)
	jr nz, RingBuf128_ReadAlt2_Dequeue
	ldw hl, 0xffff
	ret
RingBuf128_ReadAlt2_Dequeue:
	xor hl, hl
	ld	l, (xde+ix)
	.byte	0xdc, 0x38, 0x7f, 0x00	; minc1 0x007f,IX
	ld (xde-10), ix
	ret


RingBuf128_WriteByte_CheckFull:
	cpw (xde - 2), 0x0
	jr nz, RingBuf128_WriteByte_Store
	ldw hl, 0xffff
	ret

RingBuf128_WriteByte_Store:
	ld ix, (xde - 4)
	ld	(xde+ix), a
	minc1_16 ix, 0x7f
	ld (xde - 4), ix
	decm 1, (xde - 2)
	ld hl, (xde - 2)
	ret


Seq_RingBuf_Init_256:
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0xff
	ret

Seq_RingBuf_ReadByte:
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, Seq_RingBuf_ReadByte_Dequeue
	ldw hl, 0xffff
	ret

Seq_RingBuf_ReadByte_Dequeue:
	xor hl, hl
	ld	l, (xde+ix)
	minc1_16 ix, 0xff
	ld (xde - 8), ix
	incw 1, (xde - 2)
	ret

Seq_RingBuf_ReadByte_Large:
	ld ix, (xde - 10)
	cp ix, (xde - 6)
	jr nz, Seq_RingBuf_ReadByte_Large_Dequeue
	ldw hl, 0xffff
	ret

Seq_RingBuf_ReadByte_Large_Dequeue:
	xor hl, hl
	ld	l, (xde+ix)
	minc1_16 ix, 0xff
	ld (xde - 10), ix
	ret

Seq_RingBuf_ReadByte_Small:
	ld ix, (xde - 10)
	cp ix, (xde - 4)
	jr nz, Seq_RingBuf_ReadByte_Small_Dequeue
	ldw hl, 0xffff
	ret

Seq_RingBuf_ReadByte_Small_Dequeue:
	xor hl, hl
	ld	l, (xde+ix)
	minc1_16 ix, 0xff
	ld (xde - 10), ix
	ret

Seq_RingBuf_WriteByte_Small:
	cpw (xde - 2), 0x0
	jr nz, Seq_RingBuf_WriteByte_Small_Store
	ldw hl, 0xffff
	ret

Seq_RingBuf_WriteByte_Small_Store:
	ld ix, (xde - 4)
	ld	(xde+ix), a
	minc1_16 ix, 0xff
	ld (xde - 4), ix
	decm 1, (xde - 2)
	ld hl, (xde - 2)
	ret

Seq_RingBuf_Init_512:
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0x1ff
	ret

RingBuf_CheckFull_512:
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, RingBuf512_CheckFull_Read
	ldw hl, 0xffff
	ret

RingBuf512_CheckFull_Read:
	xor hl, hl
	ld	l, (xde+ix)
	minc1_16 ix, 0x1ff
	ld (xde - 8), ix
	incw 1, (xde - 2)
	ret

RingBuf_CheckFull_256:
	ld ix, (xde - 10)
	cp ix, (xde - 6)
	jr nz, RingBuf256_CheckFull_Read
	ldw hl, 0xffff
	ret

RingBuf256_CheckFull_Read:
	xor hl, hl
	ld	l, (xde+ix)
	minc1_16 ix, 0x1ff
	ld (xde - 10), ix
	ret

RingBuf512_ReadAlt_ByteBlock:
	ld	ix, (xde-10)
	cp	ix, (xde-4)
	jr	nz, RingBuf512_ReadAlt_ByteBlock_Skip
	ldw	hl, 0xffff
	ret
RingBuf512_ReadAlt_ByteBlock_Skip:
	xor	hl, hl
	ld	l, (xde+ix)
	.byte	0xdc, 0x38, 0xff, 0x01	; minc1 0x01ff,IX
	ld	(xde-10), ix
	ret

Seq_RingBuf_WriteByte_512:
	cpw (xde - 2), 0x0
	jr nz, Seq_RingBuf_WriteByte_512_Store
	ldw hl, 0xffff
	ret

Seq_RingBuf_WriteByte_512_Store:
	ld ix, (xde - 4)
	ld	(xde+ix), a
	minc1_16 ix, 0x1ff
	ld (xde - 4), ix
	decm 1, (xde - 2)
	ld hl, (xde - 2)
	ret

Seq_RingBuf_Init_1024:
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0x3ff
	ret

Seq_RingBuf_Dequeue_1024:
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, Seq_RingBuf_Dequeue_1024_Read
	ldw hl, 0xffff
	ret

Seq_RingBuf_Dequeue_1024_Read:
	xor hl, hl
	ld	l, (xde+ix)
	minc1_16 ix, 0x3ff
	ld (xde - 8), ix
	incw 1, (xde - 2)
	ret

Seq_RingBuf_ReadData:
	ld ix, (xde - 10)
	cp ix, (xde - 6)
	jr nz, Seq_RingBuf_ReadData_Dequeue
	ldw hl, 0xffff
	ret

Seq_RingBuf_ReadData_Dequeue:
	xor hl, hl
	ld	l, (xde+ix)
	minc1_16 ix, 0x3ff
	ld (xde - 10), ix
	ret

RingBuf1024_ReadAlt_ByteBlock:
	ld	ix, (xde-10)
	cp	ix, (xde-4)
	jr	nz, RingBuf1024_ReadAlt_ByteBlock_Skip
	ldw	hl, 0xffff
	ret
RingBuf1024_ReadAlt_ByteBlock_Skip:
	xor	hl, hl
	ld	l, (xde+ix)
	.byte	0xdc, 0x38, 0xff, 0x03	; minc1 0x03ff,IX
	ld	(xde-10), ix
	ret

Seq_RingBuf_WriteByte:
	cpw (xde - 2), 0x0
	jr nz, Seq_RingBuf_WriteByte_1024_Store
	ldw hl, 0xffff
	ret

Seq_RingBuf_WriteByte_1024_Store:
	ld ix, (xde - 4)
	ld	(xde+ix), a
	minc1_16 ix, 0x3ff
	ld (xde - 4), ix
	decm 1, (xde - 2)
	ld hl, (xde - 2)
	ret

Seq_RingBuf_Init_2048:
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0x7ff
	ret

Seq_RingBuf_PeekByte:
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, Seq_RingBuf_PeekByte_Read
	ldw hl, 0xffff
	ret

Seq_RingBuf_PeekByte_Read:
	xor hl, hl
	ld	l, (xde+ix)
	minc1_16 ix, 0x7ff
	ld (xde - 8), ix
	incw 1, (xde - 2)
	ret

Seq_RingBuf_WriteByte_Data:
	ld	ix, (xde-10)
	cp	ix, (xde-6)
	jr	nz, Seq_RingBuf_WriteByte_Data_Skip
	ldw	hl, 0xffff
	ret
Seq_RingBuf_WriteByte_Data_Skip:
	xor	hl, hl
	ld	l, (xde+ix)
	.byte	0xdc, 0x38, 0xff, 0x07	; minc1 0x07ff,IX
	ld	(xde-10), ix
	ret

Seq_RingBuf_ReadAhead:
	ld ix, (xde - 10)
	cp ix, (xde - 4)
	jr nz, Seq_RingBuf_ReadAhead_Read
	ldw hl, 0xffff
	ret

Seq_RingBuf_ReadAhead_Read:
	xor hl, hl
	ld	l, (xde+ix)
	minc1_16 ix, 0x7ff
	ld (xde - 10), ix
	ret

Seq_RingBuf_WriteByte_Check:
	cpw (xde - 2), 0x0
	jr nz, Seq_RingBuf_WriteByte_Store
	ldw hl, 0xffff
	ret

Seq_RingBuf_WriteByte_Store:
	ld ix, (xde - 4)
	ld	(xde+ix), a
	minc1_16 ix, 0x7ff
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
	ld iz, 0:i3
	ld a, (xsp + 6)
	extz wa
	cp wa, 0:i3
	jr ule, SeqDMA_MultiWrite_NoteEvent_Done

SeqDMA_MultiWrite_NoteEvent_Loop:
	ld xwa, (xsp + 2)
	ld C, (xwa+)
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
	ld iz, 0:i3
	ld a, (xsp + 6)
	extz wa
	cp wa, 0:i3
	jr ule, SeqDMA_MultiWrite_VoiceMap_Done

SeqDMA_MultiWrite_VoiceMap_Loop:
	ld xwa, (xsp + 2)
	ld C, (xwa+)
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
	ld iz, 0:i3
	ld a, (xsp + 6)
	extz wa
	cp wa, 0:i3
	jr ule, SeqDMA_MultiWrite_DspSysEx_Done

SeqDMA_MultiWrite_DspSysEx_Loop:
	ld xwa, (xsp + 2)
	ld C, (xwa+)
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
	ld iz, 0:i3
	ld a, (xsp + 6)
	extz wa
	cp wa, 0:i3
	jr ule, SeqDMA_MultiWrite_SoundEdit_Done

SeqDMA_MultiWrite_SoundEdit_Loop:
	ld xwa, (xsp + 2)
	ld C, (xwa+)
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
;        - DMA channel 2 destination = latch at 0x140000 (Main->Sub)
;        - DMA channel 0 source = latch at 0x140000 (Sub->Main)
;        - Configures interrupt priorities for DMA completion
;        - Clears transfer state variables at 0x05e0 and 0x05e2
;        Called during boot after Sub-CPU is released from reset
; ===========================================================================
SubCPU_Init_DMA_Channels:
	and	(INTET23:8), 0xf8
	res	2, (T8RUN:8)
	lda	xbc, (INTETC01:8)
	ld a, (xbc)
	and a, 0xf8
	or a, 0x5
	ld (xbc), a
	lda	xbc, (INTETC23:8)
	ld a, (xbc)
	and a, 0xf8
	or a, 0x5
	ld (xbc), a
	lda	xbc, (INTE0AD:8)
	ld a, (xbc)
	and a, 0xf8
	set 0, a
	ld (xbc), a
	ld (TREG2:8), 0x07:io
	lda xwa, (0x140000:24)
	ldc_cr32 xwa, 0x28
	ld a, 0x8:opc
	ldc_cr8 a, 0x4a
	lda xwa, (0x140000:24)
	ldc_cr32 xwa, 0x00
	ld a, 0x0:opc
	ldc_cr8 a, 0x42
	ld (1504:16), 0
	ld (1506:16), 0
	ret

; sendCOMM - Send chunked data to SubCPU via inter-CPU communication channel
; Original Matsushita debug symbol: "sendCOMM"
; Acquires Audio_Lock, splits data into 32-byte chunks, and transfers each
; via InterCPU_Send_Data_Block to the tone generator SubCPU.
; Entry: A = command/channel ID, BC = total byte count, XDE = source pointer
sendCOMM:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xde
	ld iz, bc
	ld (xsp + 6), a
	ld wa, 2:i3
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
	ldto_berp C, 0xf8
	extz bc
	ld xde, (xsp + 2)
	calr InterCPU_Send_Data_Block
	ld wa, 2:i3
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
;        Timeout: 60000 iterations (0xea60)
;        Called by sendCOMM for chunked audio data transfers
; ===========================================================================
InterCPU_Send_Data_Block:
	cp c, 0:i3
	ret z
	ld ix, 0:i3

InterCPU_Send_WaitReady:
	bit	3, (PZ:8)	; SSTAT1 - test if Sub CPU is ready
	jr z, InterCPU_Send_TimeoutLoop
	res	0, (PZ:8)	; MSTAT0 - clear to initiate handshake with Sub CPU
	ld (1504:16), 1
	ld l, c
	dec 1, l
	sll a, 5
	or a, l
	ld (0x140000:24), a
	ld ix, 0:i3

InterCPU_Send_WaitAck:
	bit	3, (PZ:8)	; SSTAT1 - wait for Sub CPU to acknowledge (goes low)
	jr nz, InterCPU_Send_AckTimeoutLoop
	set	0, (PZ:8)	; MSTAT0 - set to signal DMA data transfer starting
	ld (1498:16), xde
	extz bc
	ld (1502:16), bc
	calr Audio_DMA_Transfer
	ld (1504:16), 0
	cp (1504:16), 0
	ret z

InterCPU_Send_WaitComplete:
	cp (1504:16), 0
	jr nz, InterCPU_Send_WaitComplete
	ret

InterCPU_Send_TimeoutLoop:
	ld hl, ix
	inc 1, ix
	cp hl, 0xea60
	jr ule, InterCPU_Send_WaitReady
	ret

InterCPU_Send_AckTimeoutLoop:
	ld wa, ix
	inc 1, ix
	cp wa, 0xea60
	jr ule, InterCPU_Send_WaitAck
	set	0, (PZ:8)	; MSTAT0 - timeout recovery: force ready state
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
;        Timeout: 60000 iterations (0xea60)
; ===========================================================================
InterCPU_E2_Send:
	ld ix, 0:i3
	cp (1504:16), 0
	jr z, InterCPU_E2_ClearAndSend

InterCPU_E2_WaitIdle:
	ld hl, ix
	inc 1, ix
	cp hl, 0xea60
	ret ugt
	cp (1504:16), 0
	jr nz, InterCPU_E2_WaitIdle

InterCPU_E2_ClearAndSend:
	res	0, (PZ:8)	; MSTAT0 - clear to initiate E2 command handshake
	ld (1504:16), 1
	ld (0x140000:24), 0xe2
	ld ix, 0:i3

InterCPU_E2_WaitAck:
	bit	3, (PZ:8)	; SSTAT1 - wait for Sub CPU to acknowledge (goes low)
	jr nz, InterCPU_E2_TimeoutLoop
	set	0, (PZ:8)	; MSTAT0 - set to signal E2 header data ready
	lda xhl, (1478:16)
	ld (xhl), xwa
	ld (xhl + 4), xde
	ld (xhl + 8), bc
	ld (1498:16), xhl
	ldw (1502:16), 10
	calr Audio_DMA_Transfer
	ld (1504:16), 0
	set 7, (1568:16)
	cp (1504:16), 0
	ret z

InterCPU_E2_WaitComplete:
	cp (1504:16), 0
	jr nz, InterCPU_E2_WaitComplete
	ret

InterCPU_E2_TimeoutLoop:
	ld hl, ix
	inc 1, ix
	cp hl, 0xea60
	jr ule, InterCPU_E2_WaitAck
	set	0, (PZ:8)	; MSTAT0 - timeout recovery: force ready state
	ret

; ===========================================================================
; Audio_DMA_Transfer - Core DMA transfer routine for inter-CPU communication
; ===========================================================================
; Entry: Data pointer at 0x05da, byte count at 0x05de
; Exit:  Data byte-banged into the IC22 latch; one sub-CPU /INT0 per byte
; Notes: MISNOMER -- despite the name there is NO micro-DMA on this path.  The
;        body (0xEF341B-0xEF3456) is a software loop: read one byte through the
;        pointer at 0x05da (post-incrementing it and storing it back), write it
;        to the latch at 0x140000, spin a 3-iteration delay, repeat until the
;        counter at 0x05de is exhausted -- a count of 0 means 0x10000 bytes
;        (`ld XDE,0x00010000').  Each of those writes asserts the sub CPU's
;        /INT0.
;        No DMAS/DMAD/DMAC/DMAM register and no timer is touched here, and
;        "Audio_InitDMAChannels" is not a label in this disassembly: the setup
;        routine is SubCPU_Init_DMA_Channels, which programs channels 0 and 2
;        but never arms a start vector.  A byte scan for the `ld (0x0100),imm8'
;        encoding `f1 00 01 00 <imm>' finds only 0xEF36DE and 0xEF370B in code,
;        both writing 0, and DMA2V (0x0102) has no in-code write at all.
;        The label is not renamed here, so this note stands in for it.
; ===========================================================================
Audio_DMA_Transfer:
	ld wa, (1502:16)
	ld de, wa
	extz xde
	cp wa, 0:i3
	jr nz, Audio_DMA_Transfer_CheckSize
	ld xde, 0x10000

Audio_DMA_Transfer_CheckSize:
	ld xhl, 0:i3
	cp xde, 0x0
	ret ule

Audio_DMA_Transfer_ByteLoop:
	ld xwa, (1498:16)
	lda xbc, (xwa+:1)
	ld (1498:16), xwa
	ld a, (xbc)
	ld (0x140000:24), a
	ld a, 0x0:opc

Audio_DMA_Transfer_DelayLoop:
	inc 1, a
	cp a, 3:i3
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
;        4. Write 0xe1 to latch
;        5. Wait for SSTAT1 low (Sub-CPU acknowledged)
;        6. Set MSTAT0, send 6-byte header via DMA
;        7. Wait for state transition, send data payload
;        Timeout: 60000 iterations (0xea60) for each wait loop
;        Used by SubCPU_Send_Payload for firmware payload transfer
; ===========================================================================
InterCPU_E1_Bulk_Transfer:
	pushw iz
	ld iz, 0:i3
	cp (1504:16), 0
	jr z, E1Bulk_ReadyCheck

E1Bulk_WaitIdle_Loop:
	ld hl, iz
	inc 1, iz
	cp hl, 0xea60
	jrl ugt, FlashBufferIO_Exit
	cp (1504:16), 0
	jr nz, E1Bulk_WaitIdle_Loop

E1Bulk_ReadyCheck:
	ld iz, 0:i3

E1Bulk_WaitSubCPU_Ready:
	bit	3, (PZ:8)	; SSTAT1 - test if Sub CPU is ready for E1 transfer
	jrl z, E1Bulk_ReadyTimeout_Loop
	res	0, (PZ:8)	; MSTAT0 - clear to initiate E1 bulk transfer
	ld (1504:16), 2
	ld (0x140000:24), 0xe1
	ld iz, 0:i3

E1Bulk_WaitAck:
	bit	3, (PZ:8)	; SSTAT1 - wait for Sub CPU to acknowledge E1 (goes low)
	jrl nz, E1Bulk_AckTimeout_Loop
	set	0, (PZ:8)	; MSTAT0 - set to signal 6-byte header data ready
	lda xhl, (1544:16)
	ld (xhl), xwa
	lda xwa, (1488:16)
	ld (xwa), xde
	ld (xhl + 4), bc
	ld (xwa + 4), bc
	ld (1498:16), xwa
	ldw (1502:16), 6
	calr Audio_DMA_Transfer
	ld (1504:16), 1
	cp (1504:16), 1
	jr z, E1Bulk_Phase2_Init

E1Bulk_WaitPhase1_Loop:
	cp (1504:16), 1
	jr nz, E1Bulk_WaitPhase1_Loop

E1Bulk_Phase2_Init:
	ld wa, 0:i3

E1Bulk_Phase2_Delay:
	inc 1, wa
	cp wa, 0xc8
	jr c, E1Bulk_Phase2_Delay
	lda xbc, (1544:16)
	ld xwa, (xbc)
	ld (1498:16), xwa
	mrdw5 0x99, 0x04, 0x19, 0xde, 0x05
	calr Audio_DMA_Transfer
	ld (1504:16), 0
	cp (1504:16), 0
	jr z, E1Bulk_PostTransfer_Delay_Init

E1Bulk_WaitPhase2_Loop:
	cp (1504:16), 0
	jr nz, E1Bulk_WaitPhase2_Loop

E1Bulk_PostTransfer_Delay_Init:
	ld iz, 0:i3
	cp iz, 0xc8
	jr nc, E1Bulk_PostTransfer_Exit

E1Bulk_PostTransfer_Delay_Loop:
	nop
	inc 1, iz
	cp iz, 0xc8
	jr c, E1Bulk_PostTransfer_Delay_Loop

E1Bulk_PostTransfer_Exit:
	jr FlashBufferIO_Exit

E1Bulk_ReadyTimeout_Loop:
	ld hl, iz
	inc 1, iz
	cp hl, 0xea60
	jrl ule, E1Bulk_WaitSubCPU_Ready
	jr FlashBufferIO_Exit

E1Bulk_AckTimeout_Loop:
	ld hl, iz
	inc 1, iz
	cp hl, 0xea60
	jrl ule, E1Bulk_WaitAck
	set	0, (PZ:8)	; MSTAT0 - timeout recovery: force ready state

FlashBufferIO_Exit:
	popw iz
	ret

; =============================================================================
; INT0_HANDLER - inter-CPU latch receive ISR (sub CPU -> main CPU)
; =============================================================================
; ** NOT RE-ENTRANT.  Read the hazard note at the end of this block. **
; (Addresses below are v9/v10 program-ROM addresses; v9 and v10 are byte
;  identical through this whole block.  v7 carries the same code 0x2A lower
;  and uses different RAM addresses in the recovery code -- see the v7 file.)
;
; TRANSPORT.  The two CPUs pass single bytes through a pair of 8-bit latches:
; IC22 carries main->sub, IC23 carries sub->main.  The chip numbers and the
; port table below are quoted from docs/subcpu_boot_protocol.md, which takes
; them from MAME's kn5000 memory map -- they are NOT derived from these ROMs.
; The main CPU sees both at 0x140000 -- a READ takes a byte out of IC23, a
; WRITE puts one into IC22; the sub CPU sees the same pair at 0x120000 with the
; roles swapped.  Loading a latch asserts the RECEIVER's /INT0, so there is
; exactly one /INT0 per byte.  INT0 is edge triggered: IIMC (SFR 0xf6) is
; written once, at 0xEF04FE, with 0x00 (shared/boot_hw_init.s) -- I0LE=0 edge,
; I0EDGE=0 falling, bit names per
; .claude/skills/tmp94c241/references/interrupts.md.  A byte scan for the
; `ld (0xf6),imm8' encoding `08 f6 <imm>' finds no other site in code.
;
; HANDSHAKE (bit names from the main CPU's point of view):
;   MSTAT0  PZ.0 main out -> sub PD.2 in
;   MSTAT1  PZ.1 main out -> sub PD.4 in   HIGH = main receive channel is idle
;   SSTAT0  PZ.2 main in  <- sub PD.0 out  LOW  = the byte in IC23 is a HEADER
;   SSTAT1  PZ.3 main in  <- sub PD.1 out
; The SSTAT0 polarity is not a guess: InterCPU_DMA_Send_Chunk in the v142 sub
; payload CLEARS its SSTAT0 output before writing the header and SETS it again
; before the payload, and the gate here (`bit 2,(PZ) / ret NZ' at 0xEF3536)
; continues only while SSTAT0 reads LOW.
;
; FRAMING (sub -> main).  InterCPU_DMA_Send_Chunk waits for MSTAT1 high, drops
; SSTAT0, writes ONE header byte, waits for MSTAT1 to go low (the ack this ISR
; issues at INT0_AckAndReturn), raises SSTAT0 again, and only then streams the
; payload -- one byte per 8-bit-timer-2 tick, pushed by its own micro-DMA
; channel 2 (DMA2V = 22 = the INTT2 vector number).  A packet on the wire is
; therefore one header byte followed by N payload bytes, N implied by the
; header:
;   0xE1 -> 6  bytes into 0x060E  (E1 phase-1 block: dest address + count)
;   0xE2 -> 10 bytes into 0x0614  (E2 parameter block)
;   else -> (byte & 0x1f)+1 bytes into 0x05E8; bits 7:5 pick one of the eight
;           entries of SeqRingBuf_WriteDispatch_Table, called later by
;           INTTC0_HANDLER.
; The header byte is kept at 0x05E4 and the receive state at 0x05E2.
;
; WHY EVERY BYTE COMES THROUGH THIS ISR.  The main CPU never arms a hardware
; micro-DMA trigger for INT0.  Scanning the program ROM bytes for the
; `ld (0x0100),imm8' encoding `f1 00 01 00 <imm>' finds exactly two sites in
; code, 0xEF36DE and 0xEF370B, and both write 0; DMA2V (SFR 0x0102) has no
; in-code write at all.  So payload bytes enter here too, and this ISR issues
; ONE software micro-DMA request per byte by writing DMAR (SFR 0x0109 = 265)
; bit 0.  The sub CPU does the opposite: its INT0_Start_DMA writes DMA0V = 10 =
; the INT0 vector number (see v142/subcpu/subcpu_vectors.s), so its payload
; bytes are swallowed by hardware micro-DMA and never reach its ISR at all.
;   MSTAT1 high on entry -> header byte  -> INT0_ReadLatch parses it
;   MSTAT1 low  on entry -> payload byte -> DMAR bit 0 moves exactly one byte
; MSTAT1 is lowered at INT0_AckAndReturn (the END of the header parse) and
; raised again by INTTC0_HANDLER once DMAC0 reaches 0.
;
; ** RE-ENTRANCY HAZARD **
; The two gates that make the header path mutually exclusive are read long
; before the latch and are never re-checked:
;   0xEF3525  bit 1,(PZ)       test MSTAT1  (is a receive already running?)
;   0xEF3536  bit 2,(PZ)       test SSTAT0  (is this byte a header?)
;   0xEF353D  ld A,(0x140000)  THE LATCH READ       -- 0x18 after entry
;   0xEF35C4  res 1,(PZ)       MSTAT1 lowered (ack) -- 0x9F after entry,
;                                                      0x87 after the read
; There is no DI in that window; the ISR relies entirely on the CPU's interrupt
; mask.  What it does change is INT0's PRIORITY: each of the three parse
; branches ends with a read-modify-write of INTE0AD (SFR 0xF0) at 0xEF3560,
; 0xEF358A and 0xEF35B7 (`and A,0xf8 / or A,0x06'), which raises INT0 from
; level 1 to level 6, and then goes straight to the ack.  Level 1 is what
; SubCPU_Init_DMA_Channels programs; INTTC0_HANDLER puts it back at
; 0xEF35EF-0xEF35FA (`and A,0xf8 / set 0,A') when the count completes.
; INT0 therefore runs at 6 for the length of a payload burst and at 1 between
; bursts.  [INFERENCE] that looks deliberate: the scheduler spends its time at
; `ei 6' (TaskSched_PostInit, TaskSched_TimerSlot_Skip), so a level-1 INT0 has
; to wait for an unmasked window while a level-6 one does not.
; The soft spot is the RTOS tick: at 0xEF1B8D INTT3_EnterScheduler executes
; `ei 0 / nop / ei 6', a one-instruction window at IFF=0 in which any PENDING
; interrupt, INT0 included, is admitted whatever its level.
;
; [INFERENCE] if a second /INT0 is pending in that window, this ISR is entered
; again, passes both gates (the outer dispatch has not reached 0xEF35C4 yet),
; consumes the HEADER and acks.  The outer dispatch then resumes at 0xEF353D,
; reads a PAYLOAD byte and parses it as a header: DMAC0 is reprogrammed from
; that byte's low 5 bits, the count can never complete, INTTC0_HANDLER never
; runs, MSTAT1 is never raised again, and the link stays down.
; SEEN IN EMULATION ONLY -- kn7000_mame commit 3fd44f3, 2026-08-05, "kn5000:
; the sub->main wedge is a duplicate INT0 dispatch, not a lost byte".
; There the second /INT0 came from the emulated TMP94C241 re-asserting /INT0 at
; acceptance; it changed the outcome exactly twice in 59300 latch bytes, both
; times that duplicate, and with the re-assertion removed latch writes, INT0
; dispatches and latch reads are 1:1:1.
; NOT demonstrated on hardware, and two facts argue against it there: /INT0 is
; edge triggered, so one latch write is one request, and the sender does not
; put a second byte into IC23 before the ack.  Read this as a constraint on CPU
; MODELS -- one that dispatches /INT0 twice for a single latch write breaks the
; link.  Do NOT "repair" the firmware here.
;
; [INFERENCE] the code at 0xEF3689 looks like a recovery watchdog for exactly
; this state: it samples DMAC0 and, once the poll counter at 0xE360 passes 10
; with the count unchanged, clears DMA0V, resets the receive state at 0x05E2
; and forces MSTAT1 high.  UNVERIFIED -- it lies inside the region this file
; decodes as E1DMA_ISR_BytecodeBlock, and no call/calr anywhere in the ROM
; targets that address, so whether it ever runs is unknown.
; =============================================================================
INT0_HANDLER:
	bit	1, (PZ:8)	; MSTAT1 (PZ.1, our own output read back): HIGH = no receive
			; in progress, so this /INT0 carries a HEADER byte
	jr nz, INT0_ProcessCommand
	ld (265:16), 1	; MSTAT1 LOW = a receive is running, so this /INT0 carries a
			; PAYLOAD byte.  265 = 0x0109 = DMAR; bit 0 is one SOFTWARE
			; micro-DMA request on channel 0 = exactly one byte moved
			; out of the latch into the buffer, DMAC0 decremented once.
	reti
INT0_UnusedBranch:
	jr	t, INT0_ProcessCommand_Reti

INT0_ProcessCommand:
	calr INT0_ReadLatch
INT0_ProcessCommand_Reti:
	reti

INT0_ReadLatch:
	bit	2, (PZ:8)	; SSTAT0 - test Sub CPU handshake status
	ret nz
	push xwa
	push xbc
	ld a, (0x140000:24)	; THE LATCH READ (0xEF353D).  0x18 bytes after the
				; MSTAT1 test at ISR entry and 0x87 bytes before
				; MSTAT1 is lowered at 0xEF35C4, with neither gate
				; re-checked and no DI in between -- see the
				; RE-ENTRANCY HAZARD note above INT0_HANDLER.
	ld (1508:16), a	; 0x05E4 = the header byte, kept for INTTC0_HANDLER
	cp a, 0xe1
	jr nz, INT0_CheckE2Command
	ld (1506:16), 2
	lda xwa, (1550:16)
	ld (1494:16), xwa
	ldc_cr32 xwa, 0x20
	ld wa, 6:i3
	ldc_cr16 wa, 0x40
	lda	xbc, (INTE0AD:8)
	ld a, (xbc)
	and a, 0xf8
	or a, 0x6
	ld (xbc), a
	jr INT0_AckAndReturn

INT0_CheckE2Command:
	cp a, 0xe2
	jr nz, INT0_HandleDataCommand
	ld (1506:16), 3
	lda xwa, (1556:16)
	ld (1494:16), xwa
	ldc_cr32 xwa, 0x20
	ldw wa, 0xa
	ldc_cr16 wa, 0x40
	lda	xbc, (INTE0AD:8)
	ld a, (xbc)
	and a, 0xf8
	or a, 0x6
	ld (xbc), a
	jr INT0_AckAndReturn

INT0_HandleDataCommand:
	ld (1506:16), 1
	lda xwa, (1512:16)
	ld (1494:16), xwa
	ldc_cr32 xwa, 0x20
	ld a, (1508:16)
	and a, 0x1f
	inc 1, a
	extz wa
	ldc_cr16 wa, 0x40
	lda	xbc, (INTE0AD:8)
	ld a, (xbc)
	and a, 0xf8
	or a, 0x6
	ld (xbc), a

INT0_AckAndReturn:
	res	1, (PZ:8)	; MSTAT1 - clear to acknowledge command from Sub CPU.
			; This doubles as the RELEASE of the mutual-exclusion flag
			; tested at the top of INT0_HANDLER, and it happens only
			; here, at the very end of the parse -- which is what makes
			; this ISR unsafe to re-enter.  Every parse branch reaches it
			; straight from the INTE0AD write that raises INT0 to level
			; 6, so release and priority raise are adjacent.  MSTAT1 is
			; raised again by INTTC0_HANDLER once DMAC0 reaches 0;
			; [INFERENCE] if the count was programmed from a mis-framed
			; header it never will be, and the link stays down.
	pop xbc
	pop xwa
	ret

INTTC2_HANDLER:
	res	2, (T8RUN:8)
	cp (1504:16), 1
	jr nz, INTTC2_CheckPhase2
	ld (1504:16), 0
	jr INTTC2_Exit

INTTC2_CheckPhase2:
	cp (1504:16), 2
	jr nz, INTTC2_Exit
	ld (1504:16), 1

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
	lda	xbc, (INTE0AD:8)
	ld a, (xbc)
	and a, 0xf8
	set 0, a
	ld (xbc), a
	ld a, (1506:16)
	cp a, 4:i3
	jr z, INTTC0_E1_Phase2_Complete
	cp a, 3:i3
	jr z, INTTC0_E2_Complete
	cp a, 2:i3
	jr z, E1DMA_TransferSetup
	cp a, 1:i3
	jr nz, E1DMA_ISR_Epilogue
	ld c, (1508:16)
	ld a, c
	and a, 0x1f
	inc 1, a
	extz wa
	srl c, 5
	extz bc
	sla bc, 2
	lda xde, (SeqRingBuf_WriteDispatch_Table:24)
	lda	xde, (xde+bc)
	ld xbc, 0x5e8
	ld xhl, (xde)
	call (xhl)
	ld (1506:16), 0
	jr INTTC0_SetTransferDone

; E1DMA ISR - DMA transfer setup (after SeqRingBuf dispatch)
E1DMA_TransferSetup:
	lda xwa, (1550:16)
	ld xbc, (xwa)
	ldc_cr32 xbc, 0x20
	ld wa, (xwa + 4)
	ldc_cr16 wa, 0x40
	lda	xbc, (INTE0AD:8)
	ld a, (xbc)
	and a, 0xf8
	or a, 0x6
	ld (xbc), a
	ld (1506:16), 4
	jr E1DMA_ISR_Epilogue

INTTC0_E2_Complete:
	ld (1510:16), 255
	ld (1506:16), 0
	set	1, (PZ:8)	; MSTAT1 - set to signal E2 command complete
	set 7, (1566:16)
	jr E1DMA_ISR_Epilogue

INTTC0_E1_Phase2_Complete:
	ld (1506:16), 0
	res 7, (1568:16)

INTTC0_SetTransferDone:
	set	1, (PZ:8)	; MSTAT1 - set to signal E1 transfer complete

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
	ei	6
	lda	xwa, (1566:16)
	bitm	7, (xwa)
	jr	z, INTTC0_HANDLER_Skip3
	resm	7, (xwa)
	ei	0
	lda	xde, (1556:16)
	ld	xwa, (xde)
	ld	bc, (xde+8)
	ld	xde, (xde+4)
	calr	InterCPU_E1_Bulk_Transfer
INTTC0_HANDLER_Skip3:
	ei	0
	bit	1, (PZ:8)
	jr	nz, INTTC0_HANDLER_Skip2
	ldc_16_cr	wa, 0x40	; WA := control register 0x40 (which register 0x40 is, is not established)
	cp	(0xe362:16), wa
	jr	nz, INTTC0_HANDLER_Skip
	incw	1, (0xe360:16)
	jr	INTTC0_HANDLER_Join
INTTC0_HANDLER_Skip:
	ldw	(0xe360:16), 0
INTTC0_HANDLER_Join:
	ld	(0xe362:16), wa
	jr	INTTC0_HANDLER_Join2
INTTC0_HANDLER_Skip2:
	ldw	(0xe360:16), 0
INTTC0_HANDLER_Join2:
	ld	wa, (0xe360:16)
	cp	wa, 10
	ret	ule
	ldw	(0xe360:16), 0
	ld	(256:16), 0
	ld	(1506:16), 0
	set	1, (PZ:8)
	inc	1, (0xe35e:16)
	ret
	ld	de, (SYSTEM_TIMESTAMP:16)
INTTC0_HANDLER_Entry:
	bit	7, (0x620:16)
	jr	nz, INTTC0_HANDLER_Skip4
	ld	hl, 0:i3
	ret
INTTC0_HANDLER_Skip4:
	ld	wa, de
	ld	bc, (SYSTEM_TIMESTAMP:16)
	sub	bc, wa
	cp	bc, 250
	jr	le, INTTC0_HANDLER_Entry
	ld	(256:16), 0
	ld	(1506:16), 0
	set	1, (PZ:8)
	res	7, (0x620:16)
	inc	1, (0xe364:16)
	ldw	hl, 0xffff
	ret

Flash_IdentifyChip:
	push xiz
	ld xbc, 0x280000
	cp a, 1:i3
	jr nz, Flash_IdentifyChip_UseBank1
	ld xbc, 0x300000

Flash_IdentifyChip_UseBank1:
	ld xiz, xbc

Flash_IdentifyChip_WaitReady:
	bit	5, (P7:8)
	jr z, Flash_IdentifyChip_WaitReady
	ei 6
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	ldw	(xiz+21844), 0x0055
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xf0
	ld	wa, (xiz+12850)
	ei 0
	call Get_Region_Code
	cp l, 4:i3
	jr nz, Flash_IdentifyChip_Done
	add xiz, 0x80000
	ei 6
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	ldw	(xiz+21844), 0x0055
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xf0
	ld	wa, (xiz+12850)
	ei 0

Flash_IdentifyChip_Done:
	pop xiz
	ret

Flash_IdentifyAndValidateChip:
	dec 8, xsp
	push xiz
	ld (xsp + 10), a
	ldw (xsp + 8), 0xffff
	ld xwa, 0x280000
	cp (xsp + 10), 0x1
	jr nz, Flash_IdentifyValidate_UseBank1
	ld xwa, 0x300000

Flash_IdentifyValidate_UseBank1:
	ld (xsp + 4), xwa
	ei 6
	ld xbc, (xsp + 4)
	add xbc, 0xaaaa
	ldw (xbc), 0xaa
	ld xde, (xsp + 4)
	ldw	(xde+21844), 0x0055
	ldw (xbc), 0x90
	ld wa, (xde)
	ldfr_werp WA, 0xfa
	ld xbc, xde
	ld iz, (xbc + 2)
	ei 0
	cpiw_erp 0xfa, 1
	jr z, Flash_IdentifyValidate_CheckDeviceId
	cpiw_erp 0xfa, 4
	jr nz, Flash_IdentifyValidate_Return

Flash_IdentifyValidate_CheckDeviceId:
	cp iz, 0x2223
	jr z, Flash_BufferAddressStore
	cp iz, 0x22ab
	jr z, Flash_BufferAddressStore
	cp iz, 0x22d6
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
	cpw (xsp + 4), 0xffff
	jr z, Flash_ProgramWord_Done

Flash_ProgramWord_WaitReady:
	bit	5, (P7:8)
	jr z, Flash_ProgramWord_WaitReady
	cp a, 1:i3
	jr nz, Flash_ProgramWord_UseBank1
	lda xiz, (0x300000:24)
	call Get_Region_Code
	cp l, 4:i3
	jr nz, Flash_WriteWordSeq
	ld xwa, (xsp + 6)
	cp xwa, 0x380000
	jr c, Flash_WriteWordSeq
	add xiz, 0x80000
	jr Flash_WriteWordSeq

Flash_ProgramWord_UseBank1:
	lda xiz, (0x280000:24)

Flash_WriteWordSeq:
	ei 6
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	ldw	(xiz+21844), 0x0055
	ldw (xwa), 0xa0
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
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	ldw	(xiz+21844), 0x0055
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0x80
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	ldw	(xiz+21844), 0x0055
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0x10
	call Get_Region_Code
	cp l, 4:i3
	jr nz, Flash_ChipErase_Done
	cp (xsp + 4), 0x1
	jr nz, Flash_ChipErase_Done
	lda xiz, (0x380000:24)
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	ldw	(xiz+21844), 0x0055
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0x80
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	ldw	(xiz+21844), 0x0055
	ld xwa, xiz
	add xwa, 0xaaaa
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
	ld xwa, MASK_BITS16_23
	and (xsp + 4), xwa
	call Get_Region_Code
	cp l, 4:i3
	jr nz, Flash_EraseSector_WriteSequence
	ld xwa, (xsp + 4)
	cp xwa, 0x380000
	jr c, Flash_EraseSector_WriteSequence
	add xiz, 0x80000

Flash_EraseSector_WriteSequence:
	ei 6
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	ldw	(xiz+21844), 0x0055
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0x80
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	ldw	(xiz+21844), 0x0055
	ld xwa, (xsp + 4)
	ldw (xwa), 0x30
	call Get_Region_Code
	cp l, 4:i3
	jr nz, Flash_EraseSector_CheckRegion
	cp (xsp + 12), 0x1
	jrl nz, FlashOp_Epilogue10
	lda xwa, (0x300000:24)
	ld xbc, xwa
	add xbc, 0x70000
	cp xbc, (xsp + 4)
	jr z, Flash_EraseSector_BootBlock_HighBank
	ld xbc, xwa
	add xbc, 0xf0000
	cp xbc, (xsp + 4)
	jrl nz, FlashOp_Epilogue10

Flash_EraseSector_BootBlock_HighBank:
	ld xbc, xiz
	add xbc, 0x78000
	ldw (xbc), 0x30
	ld xbc, xiz
	add xbc, 0x7a000
	ldw (xbc), 0x30
	ld xbc, xiz
	add xbc, 0x7c000
	ldw (xbc), 0x30
	add xwa, 0xfffff
	cp (xsp + 8), xwa
	jrl nz, FlashOp_Epilogue10
	ld xwa, 0x60000
	jrl Flash_EraseSector_FinalWrite

Flash_EraseSector_CheckRegion:
	cp (xsp + 12), 0x1
	jr nz, Flash_EraseSector_Bank2Check
	lda xwa, (0x300000:24)
	cpw (0x205e0:24), 8792
	jr nz, Flash_EraseSector_TopSector
	cp xwa, (xsp + 4)
	jrl nz, FlashOp_Epilogue10
	ldw	(xiz+16384), 0x0030
	ldw	(xiz+24576), 0x0030
	ld xwa, 0x8000
	jrl Flash_EraseSector_FinalWrite

Flash_EraseSector_TopSector:
	ld xbc, xwa
	add xwa, 0xf0000
	cp xwa, (xsp + 4)
	jrl nz, FlashOp_Epilogue10
	ld xwa, xiz
	add xwa, 0xf8000
	ldw (xwa), 0x30
	ld xwa, xiz
	add xwa, 0xfa000
	ldw (xwa), 0x30
	ld xwa, xiz
	add xwa, 0xfc000
	ldw (xwa), 0x30
	add xbc, 0xfffff
	cp (xsp + 8), xbc
	jr nz, FlashOp_Epilogue10
	ld xwa, 0xe0000
	jr Flash_EraseSector_FinalWrite

Flash_EraseSector_Bank2Check:
	lda xwa, (0x280000:24)
	cpw (0x205e2:24), 8875
	jr nz, Flash_EraseSector_Bank2TopSector
	cp xwa, (xsp + 4)
	jr nz, FlashOp_Epilogue10
	ldw	(xiz+16384), 0x0030
	ldw	(xiz+24576), 0x0030
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
	add xwa, 0x7a000
	ldw (xwa), 0x30
	ld xwa, 0x7c000

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
	bit	5, (P7:8)
	jr z, Flash_CheckReady_NotReady
	ld hl, 0:i3
	ret

Flash_CheckReady_NotReady:
	ldw hl, 0xffff
	ret

Flash_WaitUntilReady:
	extz wa
	calr Flash_ChipErase
	calr Flash_CheckReady
	cp hl, 0xffff
	ret nz

Flash_WaitUntilReady_Loop:
	calr Flash_CheckReady
	cp hl, 0xffff
	jr z, Flash_WaitUntilReady_Loop
	ret

Flash_InitAllBanks:
	ld wa, 1:i3
	calr Flash_IdentifyChip
	ld wa, 2:i3
	calr Flash_IdentifyChip
	call Get_Region_Code
	cp l, 4:i3
	call nz, (TableDataROM_IdentifyChip:24)
	ld wa, 1:i3
	calr Flash_IdentifyAndValidateChip
	ld (0x0205e0:24), hl
	ld wa, 2:i3
	calr Flash_IdentifyAndValidateChip
	ld (0x0205e2:24), hl
	ret

Flash_FillBuffer:
	ld de, 0:i3
	cp bc, 0:i3
	ret ule

Flash_FillBuffer_Loop:
	ld (xwa+), DE
	inc 1, de
	cp de, bc
	jr c, Flash_FillBuffer_Loop
	ret

Flash_CopyROMToBuffer:
	ld xbc, xwa
	and xbc, MASK_BITS16_23
	ld xwa, 0x69800
	ld xde, 0x8000
	jp Copy_DE_words_from_XBC_to_XWA

Flash_WriteBufferToChip:
	lda xsp, (xsp - 10)
	pushw iz
	ld (xsp + 10), a
	lda xwa, (0x069800:24)
	ld (xsp + 2), xwa
	and xbc, MASK_BITS16_23
	ld (xsp + 6), xbc
	ld iz, 0:i3

Flash_WriteBufferToChip_Loop:
	ld a, (xsp + 10)
	extz wa
	ld xbc, (xsp + 6)
	lda xde, (xbc+:2)
	ld (xsp + 6), xbc
	ld xbc, xde
	ld xhl, (xsp + 2)
	ld DE, (xhl+)
	ld (xsp + 2), xhl
	calr Flash_ProgramWord
	inc 1, iz
	cp iz, 0x8000
	jr c, Flash_WriteBufferToChip_Loop
	ld iz, 0:i3

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
	ld xwa, MASK_BITS16_23
	and (xsp + 2), xwa
	ld iz, 0:i3

Flash_WriteFromMemory_Loop:
	ld a, (xsp + 10)
	extz wa
	ld xbc, (xsp + 2)
	lda xde, (xbc+:2)
	ld (xsp + 2), xbc
	ld xbc, xde
	ld xhl, (xsp + 6)
	ld DE, (xhl+)
	ld (xsp + 6), xhl
	calr Flash_ProgramWord
	inc 1, iz
	cp iz, 0x8000
	jr c, Flash_WriteFromMemory_Loop
	ld iz, 0:i3

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
	cp hl, 0xffff
	jr nz, Flash_EraseSectorAndWrite_Write

Flash_EraseSectorAndWrite_WaitLoop:
	calr Flash_CheckReady
	cp hl, 0xffff
	jr z, Flash_EraseSectorAndWrite_WaitLoop

Flash_EraseSectorAndWrite_Write:
	ld a, (xsp + 8)
	extz wa
	ld xbc, (xsp + 4)
	ld xde, (xsp)
	calr Flash_WriteFromMemory
	lda xsp, (xsp + 10)
	ret

; FlashWrite - Write data to flash memory chip
; Identifies the target flash chip, copies ROM content to a buffer,
; applies modifications, then programs the flash sector.
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
	ldiw_erp 0xe6, 0
	lda xde, (0x069800:24)
	add xde, xbc
	pushm (xsp + 4)
	ld xwa, (xsp + 8)
	push xwa
	push xde
	call Mem_Copy
	lda xsp, (xsp + 10)
	calr Flash_CheckReady
	cp hl, 0xffff
	jr nz, FlashWrite_DoWrite

FlashWrite_WaitEraseLoop:
	calr Flash_CheckReady
	cp hl, 0xffff
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
	ld wa, 1:i3
	ld xbc, 0x69800
	ld xde, 0x378700
	calr Flash_EraseSectorAndWrite
	ld xwa, 0x378700
	push xwa
	ld wa, 1:i3
	ld xbc, 0x800000
	ldw de, 0x400
	calr FlashWrite
	ld wa, 1:i3
	jrl Flash_IdentifyChip

TableDataROM_IdentifyChip:
	ld xde, 0x800000

TableDataROM_IdentifyChip_WaitReady:
	bit	5, (P7:8)
	jr z, TableDataROM_IdentifyChip_WaitReady
	ld xbc, xde
	add xbc, 0x15554
	ld xwa, FLASH_CMD_UNLOCK1
	ld (xbc), xwa
	ld xbc, xde
	add xbc, 0xaaa8
	ld xwa, FLASH_CMD_UNLOCK2
	ld (xbc), xwa
	ld xbc, xde
	add xbc, 0x15554
	ld xwa, FLASH_CMD_RESET
	ld (xbc), xwa
	ld XWA, (xde + 0x6464)
	ret

; ===========================================================================
; HDAE5000_Detect - Detect presence of HDAE5000 expansion board
; ===========================================================================
; Entry: None
; Exit:  XWA at (XSP+8) = 0 if detected, 0xffffffff if not present
; Notes: Probes Table Data ROM at 0x800000 using flash command sequence
;        Sends AMD/Atmel flash ID command (0xaa, 0x55, 0x90)
;        Checks for valid response to confirm hardware presence
; ===========================================================================
HDAE5000_Detect:
	dec 8, xsp
	push xiz
	ld xwa, 0xffffffff
	ld (xsp + 8), xwa
	ei 6
	ld xwa, FLASH_CMD_UNLOCK1
	ld (0x815554:24), xwa
	ld xwa, FLASH_CMD_UNLOCK2
	ld (0x80aaa8:24), xwa
	ld xwa, FLASH_CMD_AUTOSELECT
	ld (0x815554:24), xwa
	ld xwa, (0x800000:24)
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
	cp xiz, 0x22d622d6
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
	cp xiz, 0xffffffff
	jr z, Flash_ProgramByte_Done

Flash_ProgramByte_WaitReady:
	bit	5, (P7:8)
	jr z, Flash_ProgramByte_WaitReady
	ei 6
	ld xwa, FLASH_CMD_UNLOCK1
	ld (0x815554:24), xwa
	ld xwa, FLASH_CMD_UNLOCK2
	ld (0x80aaa8:24), xwa
	ld xwa, FLASH_CMD_PROGRAM
	ld (0x815554:24), xwa
	ld xwa, (xsp + 4)
	ld (xwa), xiz
	ei 0

Flash_ProgramByte_Done:
	pop xiz
	inc 4, xsp
	ret

; ===========================================================================
; TableDataFlash_ChipErase - erase the whole Table Data flash at 0x800000
; ===========================================================================
; Entry: None
; Exit:  the erase is started; three of the four callers then poll HDAE5000_Status_Check
; Notes: The six writes are the AMD/JEDEC CHIP ERASE command (FLASH_CMD_UNLOCK1, _UNLOCK2,
;        _ERASE_SETUP, _UNLOCK1, _UNLOCK2, _CHIP_ERASE) to both chips of the 32-bit bus.
;        It was named HDAE5000_Flash_Verify and described as an ID check; it is not one
;        (HDAE5000_Detect sends AUTOSELECT, 0x90).  Called by Flash_BurnWithProgress (which
;        then polls the status in its progress loop), HDAE5000_Status_DataBlock,
;        HDAE5000_Status_Check_Skip and HDAE5000_Init_VerifyROM.
; ===========================================================================
TableDataFlash_ChipErase:
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
	ld xwa, FLASH_CMD_UNLOCK1
	ld (xbc), xwa

	; [0080aaa8h] = 00550055h
	ld xbc, xiz
	add xbc, 0xaaa8
	ld xwa, FLASH_CMD_UNLOCK2
	ld (xbc), xwa

	; [00815554h] = 00800080h
	ld xbc, xiz
	add xbc, 0x15554
	ld xwa, FLASH_CMD_ERASE_SETUP
	ld (xbc), xwa

	; [00815554h] = 00aa00aah
	ld xbc, xiz
	add xbc, 0x15554
	ld xwa, FLASH_CMD_UNLOCK1
	ld (xbc), xwa

	; [0080aaa8h] = 00550055h
	ld xbc, xiz
	add xbc, 0xaaa8
	ld xwa, FLASH_CMD_UNLOCK2
	ld (xbc), xwa

	; [00815554h] = 00100010h
	ld xbc, xiz
	add xbc, 0x15554
	ld xwa, FLASH_CMD_CHIP_ERASE
	ld (xbc), xwa

	ei 0
	pop xiz
	ret

HDAE5000_Flash_Erase_AllSectors:
	push	xiz
	ld	xiz, 0x800000
	ei	6
	ld	xbc, xiz
	add	xbc, 0x15554
	ld	xwa, FLASH_CMD_UNLOCK1
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0xaaa8
	ld	xwa, FLASH_CMD_UNLOCK2
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x15554
	ld	xwa, FLASH_CMD_ERASE_SETUP
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x15554
	ld	xwa, FLASH_CMD_UNLOCK1
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0xaaa8
	ld	xwa, FLASH_CMD_UNLOCK2
	ld	(xbc), xwa
	ld	xwa, FLASH_CMD_SECTOR_ERASE
	ld	(xiz), xwa
	ld	xbc, xiz
	add	xbc, 0x20000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x40000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x60000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x80000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0xa0000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0xc0000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0xe0000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x100000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x120000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x140000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x160000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x180000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x1a0000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x1c0000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x1e0000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x1f0000
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x1f4000
	ld	(xbc), xwa
	ei	0
	pop	xiz
	ret

; ===========================================================================
; HDAE5000_Status_Check - Check HDAE5000 status register for ready state
; ===========================================================================
; Entry: None
; Exit:  HL = 0 if ready, 0xffff if busy
; Notes: Checks P7 bit 5 for HDAE5000 ready signal
;        Used to poll expansion board during data transfers
; ===========================================================================
HDAE5000_Status_Check:
	bit	5, (P7:8)
	jr z, HDAE5000_Status_NotPresent
	ld hl, 0:i3
	ret

HDAE5000_Status_NotPresent:
	ldw hl, 0xffff
	ret

HDAE5000_Status_DataBlock:
	calr	TableDataFlash_ChipErase
	calr	HDAE5000_Status_Check
	cp	hl, 0xffff
	ret	nz
HDAE5000_Status_Check_Loop:
	calr	HDAE5000_Status_Check
	cp	hl, 0xffff
	jr	z, HDAE5000_Status_Check_Loop
	ret
	dec	4, xsp
	push	xiz
	ld	xwa, 0x80000
	ld	(xsp+4), xwa
	calr	HDAE5000_Detect
	cp	xhl, 0xffffffff
	jr	nz, HDAE5000_Status_Check_Skip
	ldw	hl, 0xffff
	jr	HDAE5000_Status_Check_Epilogue
HDAE5000_Status_Check_Skip:
	calr	TableDataFlash_ChipErase
	ld	xwa, 0x80000
	ld	xbc, 0x10000
	call	Flash_FillBuffer
	calr	HDAE5000_Status_Check
	cp	hl, 0xffff
	jr	nz, HDAE5000_Status_Check_Skip2
HDAE5000_Status_Check_Loop2:
	calr	HDAE5000_Status_Check
	cp	hl, 0xffff
	jr	z, HDAE5000_Status_Check_Loop2
HDAE5000_Status_Check_Skip2:
	ld	xiz, 0:i3
HDAE5000_Status_Check_Loop3:
	ld	xwa, (xsp+4)
	lda	xbc, (xwa+:4)
	ld	(xsp+0x4), xwa
	ld	xwa, xbc
	ld	xbc, xiz
	calr	Flash_ProgramByte
	inc	1, xiz
	cp	xiz, 8000
	jr	c, HDAE5000_Status_Check_Loop3
	ld	hl, 0:i3
HDAE5000_Status_Check_Epilogue:
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
	ld (1570:16), xhl
	ld xwa, xhl
	lda xbc, (xhl+4078)

SLIDE_Decompress_4K_FillRing:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, SLIDE_Decompress_4K_FillRing
	ldw bc, 0xfee
	ldiw_erp 0x30, 0
	ldto_lerp XWA, 0x34
	ld xde, 0:i3
	ld e, (xwa + 2)
	sll xde, 8
	ld xhl, 0:i3
	ld l, (xwa + 3)
	add xhl, xde
	lda xde, (xwa + 1)
	inc4_lerp 0x34
	ld xwa, 0:i3
	ld a, (xde)
	ld xix, xwa
	sll xix, 16
	add xix, xhl
	ld xhl, 0:i3
	cp xix, 0x0
	jrl ule, SLIDE_Decompress_4K_Done

SLIDE_Decompress_4K_MainLoop:
	srl_erpw 0x30, 0x01
	bit_erpw 0x30, 0x08
	jr nz, SLIDE_Decompress_4K_CheckLiteral
	cp xhl, xix
	jrl nc, SLIDE_Decompress_4K_Done
	ld E, (xbc3+)
	ld a, e
	extz wa
	ldfr_werp WA, 0x30
	or_erpw 0x30, 0x00, 0xff

SLIDE_Decompress_4K_CheckLiteral:
	ldto_werp WA, 0x30
	bit 0, wa
	jr z, SLIDE_Decompress_4K_CopyMatch
	cp xhl, xix
	jrl nc, SLIDE_Decompress_4K_Done
	ld E, (xbc3+)
	ld a, e
	extz wa
	ld e, a
	ld (xde3+), e
	inc 1, xhl
	ld wa, bc
	inc 1, bc
	extz xwa
	add xwa, (1570:16)
	ld (xwa), e
	and bc, 0xfff
	jr SLIDE_Decompress_4K_Continue

SLIDE_Decompress_4K_CopyMatch:
	cp xhl, xix
	jr nc, SLIDE_Decompress_4K_Done
	ld A, (xbc3+)
	extz wa
	ldfr_werp WA, 0x32
	cp xhl, xix
	jr nc, SLIDE_Decompress_4K_Done
	ld A, (xbc3+)
	ldfr_berp A, 0xf8
	extz iz
	ld wa, iz
	and wa, 0xf0
	sll wa, 4
	exw_erp WA, 0x32
	orw_erp WA, 0x32
	exw_erp WA, 0x32
	and iz, 0xf
	inc 2, iz
	ld iy, 0:i3
	cp iz, 0:i3
	jr c, SLIDE_Decompress_4K_Continue

SLIDE_Decompress_4K_CopyLoop:
	ldto_werp WA, 0x32
	add wa, iy
	and wa, 0xfff
	extz xwa
	add xwa, (1570:16)
	ld a, (xwa)
	extz wa
	ld e, a
	ld (xde3+), e
	inc 1, xhl
	ld wa, bc
	inc 1, bc
	extz xwa
	add xwa, (1570:16)
	ld (xwa), e
	and bc, 0xfff
	inc 1, iy
	cp iy, iz
	jr ule, SLIDE_Decompress_4K_CopyLoop

SLIDE_Decompress_4K_Continue:
	cp xhl, xix
	jrl c, SLIDE_Decompress_4K_MainLoop

SLIDE_Decompress_4K_Done:
	ld xwa, (1570:16)
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
	ld (1570:16), xhl
	ld xwa, xhl
	lda xbc, (xhl+8182)

SLIDE_Decompress_8K_FillRing:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, SLIDE_Decompress_8K_FillRing
	ldw bc, 0x1ff6
	ldiw_erp 0x30, 0
	ldto_lerp XWA, 0x34
	ld xde, 0:i3
	ld e, (xwa + 2)
	sll xde, 8
	ld xhl, 0:i3
	ld l, (xwa + 3)
	add xhl, xde
	lda xde, (xwa + 1)
	add_erpl 0x34, 0x04, 0x00, 0x00, 0x00
	ld xwa, 0:i3
	ld a, (xde)
	ld xix, xwa
	sll xix, 16
	add xix, xhl
	ld xhl, 0:i3
	cp xix, 0x0
	jrl ule, SLIDE_Decompress_8K_Done

SLIDE_Decompress_8K_MainLoop:
	srl_erpw 0x30, 0x01
	bit_erpw 0x30, 0x08
	jr nz, SLIDE_Decompress_8K_CheckLiteral
	cp xhl, xix
	jrl nc, SLIDE_Decompress_8K_Done
	ld E, (xbc3+)
	ld a, e
	extz wa
	ldfr_werp WA, 0x30
	or_erpw 0x30, 0x00, 0xff

SLIDE_Decompress_8K_CheckLiteral:
	ldto_werp WA, 0x30
	bit 0, wa
	jr z, SLIDE_Decompress_8K_CopyMatch
	cp xhl, xix
	jrl nc, SLIDE_Decompress_8K_Done
	ld E, (xbc3+)
	ld a, e
	extz wa
	ld e, a
	ld (xde3+), e
	inc 1, xhl
	ld wa, bc
	inc 1, bc
	extz xwa
	add xwa, (1570:16)
	ld (xwa), e
	and bc, 0x1fff
	jr SLIDE_Decompress_8K_Continue

SLIDE_Decompress_8K_CopyMatch:
	cp xhl, xix
	jr nc, SLIDE_Decompress_8K_Done
	ld A, (xbc3+)
	extz wa
	ldfr_werp WA, 0x32
	cp xhl, xix
	jr nc, SLIDE_Decompress_8K_Done
	ld A, (xbc3+)
	ldfr_berp A, 0xf8
	extz iz
	ld wa, iz
	and wa, 0xf8
	sll wa, 5
	exw_erp WA, 0x32
	orw_erp WA, 0x32
	exw_erp WA, 0x32
	and iz, 0x7
	inc 2, iz
	ld iy, 0:i3
	cp iz, 0:i3
	jr c, SLIDE_Decompress_8K_Continue

SLIDE_Decompress_8K_CopyLoop:
	ldto_werp WA, 0x32
	add wa, iy
	and wa, 0x1fff
	extz xwa
	add xwa, (1570:16)
	ld a, (xwa)
	extz wa
	ld e, a
	ld (xde3+), e
	inc 1, xhl
	ld wa, bc
	inc 1, bc
	extz xwa
	add xwa, (1570:16)
	ld (xwa), e
	and bc, 0x1fff
	inc 1, iy
	cp iy, iz
	jr ule, SLIDE_Decompress_8K_CopyLoop

SLIDE_Decompress_8K_Continue:
	cp xhl, xix
	jrl c, SLIDE_Decompress_8K_MainLoop

SLIDE_Decompress_8K_Done:
	ld xwa, (1570:16)
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
	ld xiy, SLIDE_STRING	; "SLIDE"
	lda xix, (xsp + 4)
	ld bc, 3:i3
	ldirw
	pushw 0x5	; string length: 5 bytes
	lda xwa, (xsp + 6)
	push xwa
	push xiz
	call String_Compare
	add xsp, 0xa
	cp hl, 0:i3
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
	ld hl, 0:i3
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
	ldw hl, 0xffff

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
	ldw (xbc + 6), 0xd3
	ldw (xbc + 8), 0x1
	ldw (xbc + 10), 0x1
	ld xwa, 0:i3
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
	lda xiz, (1582:16)
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
	lda xwa, (1582:16)
	ldw (xwa), 0x3
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cp hl, 0:i3
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
	ld (xsp + 4), 0xff
	pushw 0x200
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, 0x21
	ld bc, 1:i3
	ld xde, xiz
	calr FDC_ReadSectors
	pushw 0x26	; string length
	pushw FILETYPE_SIG_PROGRAM_1@hi16
	pushw FILETYPE_SIG_PROGRAM_1@lo16	; "Technics KN5000 Program  DATA FILE 1/2"
	push xiz
	call String_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, DetectDisk_CheckProgram2of2
	ld (xsp + 4), 0x1
	jrl DetectDisk_FreeBufAndReturn

DetectDisk_CheckProgram2of2:
	pushw 0x26	; string length
	pushw FILETYPE_SIG_PROGRAM_2@hi16
	pushw FILETYPE_SIG_PROGRAM_2@lo16	; "Technics KN5000 Program  DATA FILE 2/2"
	push xiz
	call String_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, DetectDisk_CheckTable1of2
	ld (xsp + 4), 0x2
	jrl DetectDisk_FreeBufAndReturn

DetectDisk_CheckTable1of2:
	pushw 0x26	; string length
	pushw FILETYPE_SIG_TABLE_1@hi16
	pushw FILETYPE_SIG_TABLE_1@lo16	; "Technics KN5000 Table    DATA FILE 1/2"
	push xiz
	call String_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, DetectDisk_CheckTable2of2
	ld (xsp + 4), 0x3
	jrl DetectDisk_FreeBufAndReturn

DetectDisk_CheckTable2of2:
	pushw 0x26	; string length
	pushw FILETYPE_SIG_TABLE_2@hi16
	pushw FILETYPE_SIG_TABLE_2@lo16	; "Technics KN5000 Table    DATA FILE 2/2"
	push xiz
	call String_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, DetectDisk_CheckCmpCustom
	ld (xsp + 4), 0x4
	jr DetectDisk_FreeBufAndReturn

DetectDisk_CheckCmpCustom:
	pushw 0x26	; string length
	pushw FILETYPE_SIG_CMPCUSTOM@hi16
	pushw FILETYPE_SIG_CMPCUSTOM@lo16	; "Technics KN5000 CMPCUSTOMDATA FILE"
	push xiz
	call String_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, DetectDisk_CheckHDAEPRG
	ld (xsp + 4), 0x5
	jr DetectDisk_FreeBufAndReturn

DetectDisk_CheckHDAEPRG:
	pushw 0x26	; string length
	pushw FILETYPE_SIG_HDAE_PRG@hi16
	pushw FILETYPE_SIG_HDAE_PRG@lo16	; "Technics KN5000 HD-AEPRG DATA FILE"
	push xiz
	call String_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, DetectDisk_CheckProgramPCK
	ld (xsp + 4), 0x6
	jr DetectDisk_FreeBufAndReturn

DetectDisk_CheckProgramPCK:
	pushw 0x26	; string length
	pushw FILETYPE_SIG_PROGRAM_PCK@hi16
	pushw FILETYPE_SIG_PROGRAM_PCK@lo16	; "Technics KN5000 Program  DATA FILE PCK"
	push xiz
	call String_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, DetectDisk_CheckTablePCK
	ld (xsp + 4), 0x7
	jr DetectDisk_FreeBufAndReturn

DetectDisk_CheckTablePCK:
	pushw 0x26	; string length
	pushw FILETYPE_SIG_TABLE_PCK@hi16
	pushw FILETYPE_SIG_TABLE_PCK@lo16	; "Technics KN5000 Table    DATA FILE PCK"
	push xiz
	call String_Compare
	add xsp, 0xa
	cp hl, 0:i3
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
	ldto_werp WA, 0xe2
	ld iz, 0:i3
	cp wa, 0:i3
	jr z, FDC_WriteSectors_FullTracks
	ldw iz, 0x12
	sub iz, wa
	ld wa, (xsp + 6)
	extz xwa
	ld bc, iz
	ld xde, 0x69800
	calr FDC_ReadSectors
	lda xwa, (0x069800:24)
	ld (xsp + 10), xwa
	ldiw_erp 0xfa, 0
	jr FDC_WriteSectors_TrackLoopCheck

FDC_WriteSectors_TrackLoop:
	ld xwa, (xsp + 14)
	lda xbc, (xwa+:4)
	ld (xsp + 14), xwa
	ld xwa, xbc
	ld xde, (xsp + 10)
	ld XBC, (xde+)
	ld (xsp + 10), xde
	call Flash_ProgramByte
	inc1w_erp 0xfa

FDC_WriteSectors_TrackLoopCheck:
	ld bc, iz
	sla bc, 7
	ldto_werp WA, 0xfa
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
	cp wa, 0:i3
	jr ule, FDC_WriteSectors_Remainder

FDC_WriteSectors_FullTrackOuter:
	ld wa, (xsp + 6)
	extz xwa
	ldw bc, 0x12
	ld xde, 0x69800
	calr FDC_ReadSectors
	addiw_da (xsp + 6), 0x12
	lda xwa, (0x069800:24)
	ld (xsp + 10), xwa
	ldiw_erp 0xfa, 0

FDC_WriteSectors_FullTrackInner:
	ld xwa, (xsp + 14)
	lda xbc, (xwa+:4)
	ld (xsp + 14), xwa
	ld xwa, xbc
	ld xde, (xsp + 10)
	ld XBC, (xde+)
	ld (xsp + 10), xde
	call Flash_ProgramByte
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x00, 0x09
	jr c, FDC_WriteSectors_FullTrackInner
	incw 1, (xsp + 4)
	ld wa, (xsp + 8)
	cp (xsp + 4), wa
	jr c, FDC_WriteSectors_FullTrackOuter

FDC_WriteSectors_Remainder:
	ld wa, (xsp + 18)
	add wa, 0x800
	sub wa, (xsp + 6)
	ld iz, wa
	cp iz, 0:i3
	jr z, FDC_WriteSectors_Return
	ld wa, (xsp + 6)
	extz xwa
	ld bc, iz
	ld xde, 0x69800
	calr FDC_ReadSectors
	lda xwa, (0x069800:24)
	ld (xsp + 10), xwa
	ldiw_erp 0xfa, 0
	jr FDC_WriteSectors_RemainderCheck

FDC_WriteSectors_RemainderLoop:
	ld xwa, (xsp + 14)
	lda xbc, (xwa+:4)
	ld (xsp + 14), xwa
	ld xwa, xbc
	ld xde, (xsp + 10)
	ld XBC, (xde+)
	ld (xsp + 10), xde
	call Flash_ProgramByte
	inc1w_erp 0xfa

FDC_WriteSectors_RemainderCheck:
	ld bc, iz
	sla bc, 7
	ldto_werp WA, 0xfa
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
	ldto_werp WA, 0xe2
	ld iz, 0:i3
	cp wa, 0:i3
	jr z, FDC_WriteCompressed_FullTracks
	ldw iz, 0x12
	sub iz, wa
	ld wa, (xsp + 6)
	extz xwa
	ld bc, iz
	ld xde, 0x69800
	calr FDC_ReadSectors
	lda xwa, (0x069800:24)
	ld (xsp + 10), xwa
	ldiw_erp 0xfa, 0
	jr FDC_WriteCompressed_PartialTrackCheck

FDC_WriteCompressed_PartialTrackLoop:
	ld a, (xsp + 20)
	extz wa
	ld xbc, (xsp + 14)
	lda xde, (xbc+:2)
	ld (xsp + 14), xbc
	ld xbc, xde
	ld xhl, (xsp + 10)
	ld DE, (xhl+)
	ld (xsp + 10), xhl
	call Flash_ProgramWord
	inc1w_erp 0xfa

FDC_WriteCompressed_PartialTrackCheck:
	ld bc, iz
	sla bc, 8
	ldto_werp WA, 0xfa
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
	cp wa, 0:i3
	jr ule, FDC_WriteCompressed_Remainder

FDC_WriteCompressed_FullTrackOuter:
	ld wa, (xsp + 6)
	extz xwa
	ldw bc, 0x12
	ld xde, 0x69800
	calr FDC_ReadSectors
	addiw_da (xsp + 6), 0x12
	lda xwa, (0x069800:24)
	ld (xsp + 10), xwa
	ldiw_erp 0xfa, 0

FDC_WriteCompressed_FullTrackInner:
	ld a, (xsp + 20)
	extz wa
	ld xbc, (xsp + 14)
	lda xde, (xbc+:2)
	ld (xsp + 14), xbc
	ld xbc, xde
	ld xhl, (xsp + 10)
	ld DE, (xhl+)
	ld (xsp + 10), xhl
	call Flash_ProgramWord
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x00, 0x12
	jr c, FDC_WriteCompressed_FullTrackInner
	incw 1, (xsp + 4)
	ld wa, (xsp + 8)
	cp (xsp + 4), wa
	jr c, FDC_WriteCompressed_FullTrackOuter

FDC_WriteCompressed_Remainder:
	ld wa, (xsp + 18)
	add wa, (xsp + 26)
	sub wa, (xsp + 6)
	ld iz, wa
	cp iz, 0:i3
	jr z, FDC_WriteCompressed_Return
	ld wa, (xsp + 6)
	extz xwa
	ld bc, iz
	ld xde, 0x69800
	calr FDC_ReadSectors
	lda xwa, (0x069800:24)
	ld (xsp + 10), xwa
	ldiw_erp 0xfa, 0
	jr FDC_WriteCompressed_RemainderCheck

FDC_WriteCompressed_RemainderLoop:
	ld a, (xsp + 20)
	extz wa
	ld xbc, (xsp + 14)
	lda xde, (xbc+:2)
	ld (xsp + 14), xbc
	ld xbc, xde
	ld xhl, (xsp + 10)
	ld DE, (xhl+)
	ld (xsp + 10), xhl
	call Flash_ProgramWord
	inc1w_erp 0xfa

FDC_WriteCompressed_RemainderCheck:
	ld bc, iz
	sla bc, 8
	ldto_werp WA, 0xfa
	cp wa, bc
	jr c, FDC_WriteCompressed_RemainderLoop

FDC_WriteCompressed_Return:
	pop xiz
	lda xsp, (xsp + 18)
	retd 0x2

SHOW_FD_TO_FLASH_MEMORY_MESSAGE:
	pushw 0x8
	pushw 0x2
	ld xwa, Bitmap_1bit_FD_to_Flash_Memory	; "FD -> Flash Memory"
	ldw bc, 0x30
	ldw de, 0xa0
	call Draw_FlashMemUpdate_message_bitmap
	ret

FirmwareUpdate_SaveDiskType:
	dec 2, xsp
	ld (xsp), a

SHOW_CHANGE_FLOPPY_2_OF_2_MESSAGE:
	pushw 0x8
	pushw 0x2
	ld xwa, Bitmap_1bit_Change_FD_2_of_2	; "Change FD (2/2)"
	ldw bc, 0x30
	ldw de, 0xa0
	call Draw_FlashMemUpdate_message_bitmap
	call Check_for_Floppy_Disk_Change
	cp l, 0:i3
	jr z, FloppyChange_DiskRemoved

FloppyChange_WaitDiskRemove_Loop:
	call Check_for_Floppy_Disk_Change
	cp l, 0:i3
	jr nz, FloppyChange_WaitDiskRemove_Loop

FloppyChange_DiskRemoved:
	ld xwa, 0:i3

FloppyChange_Debounce1_Loop:
	inc 1, xwa
	cp xwa, 0x40000
	jr c, FloppyChange_Debounce1_Loop
	call Check_for_Floppy_Disk_Change
	cp l, 0:i3
	jr nz, FloppyChange_DiskInserted

FloppyChange_WaitDiskInsert_Loop:
	call Check_for_Floppy_Disk_Change
	cp l, 0:i3
	jr z, FloppyChange_WaitDiskInsert_Loop

FloppyChange_DiskInserted:
	ld xwa, 0:i3

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
	ld xwa, 0:i3
	ld (SYSTEM_TIMESTAMP:16), xwa
	call TableDataFlash_ChipErase
	call HDAE5000_Status_Check
	cp hl, 0xffff
	jr nz, FlashBurn_Done

FlashBurn_ProgressLoop:
	ld xwa, (SYSTEM_TIMESTAMP:16)
	cp xwa, 0x1f4
	jr ule, FlashBurn_CheckDone
	inc 8, iz
	ld wa, iz
	ldw bc, 0xb4
	ld de, 5:i3
	call VRAM_FillRect
	ld xwa, 0:i3
	ld (SYSTEM_TIMESTAMP:16), xwa

FlashBurn_CheckDone:
	call HDAE5000_Status_Check
	cp hl, 0xffff
	jr z, FlashBurn_ProgressLoop

FlashBurn_Done:
	popw iz
	ret

Erase_and_Burn____when_disk_is_valid:
	dec 2, xsp
	ld (xsp), a
	pushw 0x8
	pushw 0x2
	ld xwa, Bitmap_1bit_Now_Erasing	; "Now Erasing!!"
	ldw bc, 0x30
	ldw de, 0xa0
	call Draw_FlashMemUpdate_message_bitmap
	ld a, (xsp)
	extz wa
	dec 1, wa
	cp wa, 0:i3
	jrl lt, SHOW_ILLEGAL_DISK_MESSAGE
	cp wa, 7:i3
	jrl gt, SHOW_ILLEGAL_DISK_MESSAGE
	add wa, wa
	lda xix, (HANDLE_UPDATE_OFFSETS:24)
	ld	wa, (xix+wa)
	lda xix, (HANDLE_UPDATE_FILE_TYPE_ID_001h:24)
	jp	t, (xix+wa)


; "Technics KN5000 Program DATA FILE 1/2"
HANDLE_UPDATE_FILE_TYPE_ID_001h:
	calr Flash_BurnWithProgress
	calr SHOW_FD_TO_FLASH_MEMORY_MESSAGE
	ldw wa, 0x24
	ld xbc, 0x800000
	calr FDC_WriteSectors
	ld wa, 2:i3
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
	ld wa, 4:i3
	calr FirmwareUpdate_SaveDiskType
	ldw wa, 0x24
	ld xbc, 0x900000

UpdateFile_WriteSectors_AndCleanup:
	calr FDC_WriteSectors
	jr UpdateFile_StackCleanup


; "Technics KN5000 CMPCUSTOMDATA FILE"
HANDLE_UPDATE_FILE_TYPE_ID_005h:
	ld wa, 1:i3
	call Flash_WaitUntilReady
	calr SHOW_FD_TO_FLASH_MEMORY_MESSAGE
	pushw 0x800
	ld wa, 1:i3
	ldw bc, 0x24
	ld xde, 0x300000	; "custom_data" 8MBit FLASH ROM @ IC19
	jr UpdateFile_WriteCompressed_AndCleanup


; "Technics KN5000 HD-AEPRG DATA FILE"
HANDLE_UPDATE_FILE_TYPE_ID_006h:
	ld wa, 2:i3
	call Flash_WaitUntilReady
	calr SHOW_FD_TO_FLASH_MEMORY_MESSAGE
	pushw 0x400
	ld wa, 2:i3
	ldw bc, 0x24
	ld xde, 0x280000

UpdateFile_WriteCompressed_AndCleanup:
	calr FDC_WriteSectors_Compressed
	jr UpdateFile_StackCleanup


; "Technics KN5000 Program DATA FILE PCK"
HANDLE_UPDATE_FILE_TYPE_ID_007h:
	ld wa, 1:i3
	ld xbc, 0x3e0000
	call Flash_EraseSectorWithBankSelect
	ld wa, 1:i3
	ld xbc, 0x3f0000
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
	ld xwa, Bitmap_1bit_Illegal_Disk	; "Illegal Disk!"
	ldw bc, 0x30
	ldw de, 0xa0
	call Draw_FlashMemUpdate_message_bitmap
	inc 2, xsp

IllegalDisk_HaltLoop:
	jr IllegalDisk_HaltLoop

BusyWait_XWA_Cycles:
	ld xbc, 0:i3
	cp xbc, xwa
	ret nc

BusyWait_Loop:
	inc 1, xbc
	cp xbc, xwa
	jr c, BusyWait_Loop
	ret

LED_CyclePattern:
	inc 1, (1574:16)
	ld a, (1574:16)
	and a, 0x3
	cp a, 3:i3
	jr z, LED_CyclePattern_Phase3
	cp a, 2:i3
	jr z, LED_CyclePattern_Phase2
	cp a, 1:i3
	jr z, LED_CyclePattern_Phase1
	cp a, 0:i3
	jr nz, PortWrite_BusyWait
	ld (0x160004:24), 0x01
	jr PortWrite_BusyWait

LED_CyclePattern_Phase1:
	ld (0x160004:24), 0x02
	jr PortWrite_BusyWait

LED_CyclePattern_Phase2:
	ld (0x160004:24), 0x04
	jr PortWrite_BusyWait

LED_CyclePattern_Phase3:
	ld (0x160004:24), 0x08

PortWrite_BusyWait:
	ld xwa, 0x186a0
	jr BusyWait_XWA_Cycles

LED_Toggle_Bit2_Loop:
	chg 2, (0x160004:24)
	ld xwa, 0x249f0
	calr BusyWait_XWA_Cycles
	jr LED_Toggle_Bit2_Loop

LED_Toggle_Bit3_Loop:
	chg 3, (0x160004:24)
	ld xwa, 0x249f0
	calr BusyWait_XWA_Cycles
	jr LED_Toggle_Bit3_Loop

; ===========================================================================
; TableData_ROM_Verify - Verify Table Data ROM integrity via checksum
; ===========================================================================
; Entry: XWA = start address, XBC = end address
; Exit:  XHL = 0 if valid, non-zero address of first bad block if invalid
; Notes: Scans ROM in 64-byte blocks checking for erased (0xffffffff) markers
;        Used during boot to verify Table Data ROM contents
; ===========================================================================
TableData_ROM_Verify:
	ld xhl, xwa
	ld xde, (xhl)
	cp xde, 0xffffffff
	ret nz

TableData_ROM_Verify_NextBlock:
	lda xhl, (xhl + 64)
	cp xhl, xbc
	jr nz, TableData_ROM_Verify_CheckBlock
	ld xhl, 0:i3
	ret

TableData_ROM_Verify_CheckBlock:
	ld xde, (xhl)
	cp xde, 0xffffffff
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
	ld (0x160000:24), w
	ld xix, xbc
	ld xiy, 0x3ffff

HDAE5000_ROM_Transfer_WordLoop:
	ld DE, (xix+)
	cp DE, (xhl+)
	jr nz, HDAE5000_ROM_Transfer_Return
	ld xde, xiy
	dec 1, xiy
	or xde, xde
	jr nz, HDAE5000_ROM_Transfer_WordLoop
	inc 1, w
	cp w, a
	jr ule, HDAE5000_ROM_Transfer_BlockLoop

HDAE5000_ROM_Transfer_Success:
	ld xhl, 0:i3

HDAE5000_ROM_Transfer_Return:
	retd 0x2
HDAE5000_TableData_Write_Helper:
	lda xsp, (xsp - 10)
	push xiz
	lda xwa, (0x300000:24)
	ld (xsp + 8), xwa
	ld (xsp + 12), 0x0

HDAE5000_FlashWrite_BankLoop:
	ld a, (xsp + 12)
	ld (0x160000:24), a
	lda xwa, (0x200000:24)
	ld (xsp + 4), xwa
	ld xiz, 0:i3

HDAE5000_FlashWrite_WordLoop:
	ld xwa, (xsp + 8)
	lda xbc, (xwa+:2)
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	ld DE, (xwa+)
	ld (xsp + 4), xwa
	ld wa, 1:i3
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
	ld	xwa, 0x800000
	ld	(xsp+8), xwa
	ld	(xsp+12), 0
HDAE5000_FlashVerify_BytecodeBlock_Loop:
	ld	a, (xsp+12)
	ld	(0x160000:24), a
	lda	xwa, (0x280000:24)
	ld	(xsp+4), xwa
	ld	xiz, 0:i3
HDAE5000_FlashVerify_BytecodeBlock_Loop2:
	ld	xwa, (xsp+8)
	lda xbc, (xwa+:4)
	ld (xsp+8), xwa
	ld xwa, xbc
	ld	xde, (xsp+4)
	ld	xbc, (xde+)
	ld	(xsp+0x4), xde
	call	Flash_ProgramByte
	inc	1, xiz
	cp	xiz, 0x20000
	jr	c, HDAE5000_FlashVerify_BytecodeBlock_Loop2
	incm8	1, (xsp+12)
	cp	(xsp+0xc), 4
	jr	c, HDAE5000_FlashVerify_BytecodeBlock_Loop
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
	ld (0x160000:24), a
	lda xwa, (0x280000:24)
	ld (xsp + 4), xwa
	ld xiz, 0:i3

HDAE5000_TableData_WordLoop:
	ld xwa, (xsp + 8)
	lda xbc, (xwa+:4)
	ld (xsp + 8), xwa
	ld xwa, xbc
	ld xde, (xsp + 4)
	ld XBC, (xde+)
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
	push	qiz
	ldib_erp	251, 0
	ld	(0xe4:0x8), 0:io
	ld	(0xe0:0x8), 0:io
	ld	(INTETC23:8), 0:io
	ld	(INTEAB:8), 0:io
	ld	(INTES1:8), 0:io
	ld	(340:16), 102
	ld	(0x160006:24), 130
	ld	(0x160000:24), 0
	ld	(0x160004:24), 0
	ld	(0x160004:24), 15
	ld	xwa, 0xdbba0
	calr	BusyWait_XWA_Cycles
	ld	(0x160004:24), 0
HDAE5000_TableData_Write_Loop:
	ld	a, (0x160002:24)
	extz	wa
	bit	0, wa
	jr	nz, HDAE5000_TableData_Write_Loop
	call	HDAE5000_Detect
	cp	xhl, 0xffffffff
	jr	nz, HDAE5000_TableData_Write_Skip
	set	2, (0x160004:24)
	ldib_erp	251, 1
HDAE5000_TableData_Write_Skip:
	ld	wa, 1:i3
	call	Flash_IdentifyAndValidateChip
	cp	hl, 0xffff
	jr	nz, HDAE5000_TableData_Write_Skip2
	set	3, (0x160004:24)
	ldib_erp	251, 1
	jr	HDAE5000_TableData_Write_Join
HDAE5000_TableData_Write_Skip2:
	cpib_erp 251, 1
	jr nz, HDAE5000_TableData_Write_Skip3
	pop qiz
HDAE5000_TableData_Write_Join:
	jr	HDAE5000_TableData_Write_Join
HDAE5000_TableData_Write_Skip3:
	ld	(0x160004:24), 0
	ld	xwa, 0x800000
	ld	xbc, 0xa00000
	calr	TableData_ROM_Verify
	or	xhl, xhl
	call	nz, (0xef3dbb:24)
	lda	xwa, (0x300000:24)
	ld	xbc, xwa
	add	xbc, 0x100000
	calr	TableData_ROM_Verify
	or	xhl, xhl
	jr	z, HDAE5000_TableData_Write_Skip4
	ld	wa, 1:i3
	call	Flash_ChipErase
HDAE5000_TableData_Write_Skip4:
	call	HDAE5000_Status_Check
	cp	hl, 0xffff
	jr	nz, HDAE5000_TableData_Write_Skip5
HDAE5000_Init_BytecodeBlock_Code_Loop:
	calr	LED_CyclePattern
	call	HDAE5000_Status_Check
	cp	hl, 0xffff
	jr	z, HDAE5000_Init_BytecodeBlock_Code_Loop
HDAE5000_TableData_Write_Skip5:
	ld	(0x160004:24), 0
	set	0, (0x160004:24)
	calr	HDAE5000_FlashVerify_BytecodeBlock
	res	0, (0x160004:24)
	ld	xwa, 0xdbba0
	calr	BusyWait_XWA_Cycles
	set	0, (0x160004:24)
	calr	HDAE5000_TableData_Write_Helper
	res	0, (0x160004:24)
	set	1, (0x160004:24)
	pushw	3
	ld	xwa, 0x800000
	ld	xbc, 0x280000
	ld	de, 0:i3
	calr	HDAE5000_ROM_Transfer
	or	xhl, xhl
	call	nz, (0xef4890:24)
	pushw	1
	ld	xwa, 0x300000
	ld	xbc, 0x200000
	ld	de, 0:i3
	calr	HDAE5000_ROM_Transfer
	or	xhl, xhl
	call	nz, (0xef489f:24)
	ld	(0x160000:24), 7
	ld	xwa, (0x2fffc0:24)
	cp	xwa, 0x5f746b68
	jr	z, HDAE5000_TableData_Write_Skip6
	pop	qiz
HDAE5000_TableData_Write_Join2:
	jr	HDAE5000_TableData_Write_Join2
HDAE5000_TableData_Write_Skip6:
	ei	7
	ld	xwa, Debug_SWI_JumpTable_Code
	ldw	ix, 331
	extz	xix
	sll	xbc, 16
	sll	xbc, 16
	ld	(xix), 128
	jp	(xwa)
	pop qiz
	ret

HDAE5000_Init_DetectAndVerify:
	ld (0x160004:24), 0x00
	call HDAE5000_Detect
	cp xhl, 0xffffffff
	jr nz, HDAE5000_Init_VerifyROM
	set 2, (0x160004:24)

Infinite_Loop_FlashVerifyFail:
	jr Infinite_Loop_FlashVerifyFail

HDAE5000_Init_VerifyROM:
	ld xwa, 0x800000
	ld xbc, 0xa00000
	calr TableData_ROM_Verify
	or xhl, xhl
	jr z, HDAE5000_Init_TransferData
	call TableDataFlash_ChipErase
	call HDAE5000_Status_Check
	cp hl, 0xffff
	jr nz, HDAE5000_Init_TransferData

HDAE5000_Init_WaitFlashReady:
	calr LED_CyclePattern
	ld (0x160004:24), 0x00
	call HDAE5000_Status_Check
	cp hl, 0xffff
	jr z, HDAE5000_Init_WaitFlashReady

HDAE5000_Init_TransferData:
	set 0, (0x160004:24)
	calr HDAE5000_TableData_Write
	res 0, (0x160004:24)
	set 1, (0x160004:24)
	pushw 0x7
	ld xwa, 0x800000
	ld xbc, 0x280000
	ld de, 4:i3
	calr HDAE5000_ROM_Transfer
	or xhl, xhl
	call nz, (LED_Toggle_Bit2_Loop:24)

HDAE5000_Init_HaltLoop:
	jr HDAE5000_Init_HaltLoop

HDAE5000_Parport_Setup:
	ld (340:16), 102
	ld (0x160006:24), 0x82
	ld (0x160000:24), 0x00
	ld (0x160004:24), 0x00
	ld (0x160004:24), 0x0f
	ld xwa, 0xdbba0
	calr BusyWait_XWA_Cycles
	ld (0x160004:24), 0x00

Parport_WaitDataReady:
	ld a, (0x160002:24)
	extz wa
	bit 0, wa
	jr nz, Parport_WaitDataReady
	jrl HDAE5000_Init_DetectAndVerify
	ret

Parport_ReadNextByte:
	pushw iz
	ld xwa, (1602:16)
	cp xwa, (1598:16)
	jr c, Parport_ReadByte_FromBuffer
	ldw hl, 0xffff
	jr Parport_ReadByte_Return

Parport_ReadByte_FromBuffer:
	lda xwa, (0x069800:24)
	add xwa, 0x9000
	cp xwa, (1610:16)
	jr nz, Parport_ReadByte_Emit
	incw 8, (1614:16)
	ld wa, (1614:16)
	ld bc, (1616:16)
	ld de, 6:i3
	call VRAM_FillRect
	ld iz, 0:i3

Parport_RefillBuffer_Loop:
	ld wa, (1618:16)
	extz xwa
	ldw bc, 0x2400
	mul xbc, iz
	ld xde, 0x69800
	add xde, xbc
	ldw bc, 0x12
	calr FDC_ReadSectors
	addw (1618:16), 18
	inc 1, iz
	cp iz, 4:i3
	jr c, Parport_RefillBuffer_Loop
	lda xwa, (0x069800:24)
	ld (1610:16), xwa

Parport_ReadByte_Emit:
	ld xwa, (1610:16)
	lda xbc, (xwa+:1)
	ld (1610:16), xwa
	ld l, (xbc)
	extz hl

Parport_ReadByte_Return:
	popw iz
	ret

Flash_AccumWrite_Byte:
	ld e, (1620:16)
	extz de
	lda xbc, (1576:16)
	extz xde
	add xde, xbc
	ld (xde), a
	ld a, (1620:16)
	ld e, a
	inc 1, a
	ld (1620:16), a
	cp e, 3:i3
	jr nz, Flash_AccumWrite_ByteDone
	ld xwa, (1606:16)
	lda xde, (xwa+:4)
	ld (1606:16), xwa
	ld xbc, (xbc)
	ld xwa, xde
	call Flash_ProgramByte
	ld (1620:16), 0

Flash_AccumWrite_ByteDone:
	ld xwa, 1:i3
	add (1602:16), xwa
	ret

Flash_AccumWrite_Word:
	ld c, (1620:16)
	extz bc
	lda xde, (1580:16)
	extz xbc
	add xbc, xde
	ld (xbc), a
	ld a, (1620:16)
	ld c, a
	inc 1, a
	ld (1620:16), a
	cp c, 1:i3
	jr nz, Flash_AccumWrite_WordDone
	ld xwa, (1622:16)
	lda xbc, (xwa+:2)
	ld (1622:16), xwa
	ld de, (xde)
	ld wa, 1:i3
	call Flash_ProgramWord
	ld (1620:16), 0

Flash_AccumWrite_WordDone:
	ld xwa, 1:i3
	add (1602:16), xwa
	ret

LZSS_Decompress_ToFlash:
	dec 6, xsp
	pushw iz
	ld (1620:16), 0
	lda xwa, (0x300000:24)
	add xwa, 0xe0000
	ld (1622:16), xwa
	ld xwa, 0x20000
	add (1598:16), xwa
	ld iz, 0:i3

LZSS_Decompress_ReadHeader:
	calr Parport_ReadNextByte
	ld bc, iz
	extz xbc
	lda xwa, (xsp + 2)
	ld xde, xwa
	add xde, xbc
	ld (xde), l
	inc 1, iz
	cp iz, 6:i3
	jr c, LZSS_Decompress_ReadHeader
	pushw 0x5	; lenght: 5 bytes
	pushw SLIDE_STRING_2@hi16
	pushw SLIDE_STRING_2@lo16	; "SLIDE"
	push xwa
	call String_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr z, LZSS_Decompress_HeaderOK
	ldw hl, 0xffff
	jr LZSS_Decompress_Return

LZSS_Decompress_HeaderOK:
	ld iz, 0:i3

LZSS_Decompress_StreamHeaderBytes:
	ld bc, iz
	extz xbc
	lda xwa, (xsp + 2)
	add xwa, xbc
	ld a, (xwa)
	extz wa
	calr Flash_AccumWrite_Word
	inc 1, iz
	cp iz, 6:i3
	jr c, LZSS_Decompress_StreamHeaderBytes
	ldw (1614:16), 42
	ldw (1616:16), 200
	ld xwa, (1602:16)
	cp xwa, (1598:16)
	jr nc, LZSS_Decompress_ReturnOK

LZSS_Decompress_StreamData:
	calr Parport_ReadNextByte
	extz hl
	ld wa, hl
	calr Flash_AccumWrite_Word
	ld xwa, (1602:16)
	cp xwa, (1598:16)
	jr c, LZSS_Decompress_StreamData

LZSS_Decompress_ReturnOK:
	ld hl, 0:i3

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
	ld xwa, 0:i3
	ld (1602:16), xwa

LZ_Decompress_ClearRing:
	ld xwa, (1602:16)
	ld xbc, (xsp + 16)
	add xbc, xwa
	ld (xbc), 0x0
	ld xwa, (1602:16)
	inc 1, xwa
	ld (1602:16), xwa
	cp xwa, 0xfee
	jr c, LZ_Decompress_ClearRing
	ldw (xsp + 10), 0xfee
	ldw (xsp + 4), 0x0
	ld (1620:16), 0
	ld xwa, 0:i3
	ld (1602:16), xwa
	lda xwa, (0x069800:24)
	ld (1610:16), xwa
	ld xwa, 0x800000
	ld (1606:16), xwa
	ldw (1614:16), 50
	ldw (1616:16), 180
	ldw wa, 0x32
	ldw bc, 0xb4
	ld de, 6:i3
	call VRAM_FillRect
	ld xwa, 0x3e8
	ld (1598:16), xwa
	ldw (1618:16), 36
	ldiw_erp 0xfa, 0

LZ_Decompress_ReadTracks:
	ld wa, (1618:16)
	extz xwa
	ldw bc, 0x2400
	mul xbc, qiz
	ld xde, 0x69800
	add xde, xbc
	ldw bc, 0x12
	calr FDC_ReadSectors
	addw (1618:16), 18
	inc1w_erp 0xfa
	cpiw_erp 0xfa, 4
	jr c, LZ_Decompress_ReadTracks
	ldiw_erp 0xfa, 0

LZ_Decompress_ReadSizeField:
	calr Parport_ReadNextByte
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x08, 0x00
	jr c, LZ_Decompress_ReadSizeField
	calr Parport_ReadNextByte
	extz xhl
	sla xhl, 16
	ld (1598:16), xhl
	calr Parport_ReadNextByte
	sll hl, 8
	extz xhl
	add (1598:16), xhl
	calr Parport_ReadNextByte
	extz xhl
	ld xwa, (1598:16)
	add xwa, xhl
	ld (1598:16), xwa
	cp (1602:16), xwa
	jrl nc, LZ_Decompress_Done

LZ_Decompress_MainLoop:
	mrdw3 0x9f, 0x04, 0x7f
	ld wa, (xsp + 4)
	bit 8, wa
	jr nz, LZ_Decompress_LiteralByte
	calr Parport_ReadNextByte
	ld iz, hl
	cp iz, 0xffff
	jrl z, LZ_Decompress_Done
	ld (xsp + 4), iz
	ormi16 (xsp + 4), 0xff00

LZ_Decompress_LiteralByte:
	ld wa, (xsp + 4)
	bit 0, wa
	jr z, LZ_Decompress_MatchRef
	calr Parport_ReadNextByte
	ld iz, hl
	cp iz, 0xffff
	jrl z, LZ_Decompress_Done
	ldto_berp A, 0xf8
	extz wa
	calr Flash_AccumWrite_Byte
	ld bc, (xsp + 10)
	incw 1, (xsp + 10)
	extz xbc
	add xbc, (xsp + 16)
	ldto_berp A, 0xf8
	ld (xbc), a
	andmi16 (xsp + 10), 0xfff
	jr LZ_Decompress_LoopCheck

LZ_Decompress_MatchRef:
	calr Parport_ReadNextByte
	ldfr_werp HL, 0xfa
	cp_erpw 0xfa, 0xff, 0xff
	jr z, LZ_Decompress_Done
	calr Parport_ReadNextByte
	ld (xsp + 8), hl
	cpw (xsp + 8), 0xffff
	jr z, LZ_Decompress_Done
	ld bc, (xsp + 8)
	and bc, 0xf0
	sll bc, 4
	ldto_werp WA, 0xfa
	or wa, bc
	ldfr_werp WA, 0xfa
	andmi16 (xsp + 8), 0xf
	incw 2, (xsp + 8)
	ldw (xsp + 6), 0x0
	cpw (xsp + 8), 0x0
	jr c, LZ_Decompress_LoopCheck

LZ_Decompress_CopyMatchLoop:
	ldto_werp WA, 0xfa
	add wa, (xsp + 6)
	and wa, 0xfff
	extz xwa
	add xwa, (xsp + 12)
	ld a, (xwa)
	ldfr_berp A, 0xf8
	extz iz
	ldto_berp A, 0xf8
	extz wa
	calr Flash_AccumWrite_Byte
	ld bc, (xsp + 10)
	incw 1, (xsp + 10)
	extz xbc
	add xbc, (xsp + 12)
	ldto_berp A, 0xf8
	ld (xbc), a
	andmi16 (xsp + 10), 0xfff
	incw 1, (xsp + 6)
	ld wa, (xsp + 6)
	cp wa, (xsp + 8)
	jr ule, LZ_Decompress_CopyMatchLoop

LZ_Decompress_LoopCheck:
	ld xwa, (1602:16)
	cp xwa, (1598:16)
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
	pushw_erp 0xfa
	call Check_for_Floppy_Disk_Change
	cp l, 0:i3
	jrl z, flash_update__not_today
	calr FDC_InitRecalibrate
	calr Detect_Disk_Type
	ldfr_berp L, 0xfb
	call Get_Region_Code
	cp l, 4:i3
	jr z, Flash_CheckAndValidate
	call HDAE5000_Detect
	cp xhl, 0xffffffff
	jr z, Flash_CheckAndValidate
	cpib_erp 0xfb, 6	; Is it "HD-AEPRG DATA FILE"?
	jr z, Flash_CheckAndValidate	; yes, it is.
	pushw 0x8
	pushw 0x2
	ld xwa, Bitmap_1bit_Flash_Memory_Update	; "Flash Memory Update"
	ldw bc, 0x30
	ldw de, 0x50
	call Draw_FlashMemUpdate_message_bitmap
	ldto_berp A, 0xfb
	extz wa
	calr Erase_and_Burn____when_disk_is_valid
	pushw 0x8
	pushw 0x1
	ld xwa, Bitmap_1bit_Completed	; "Completed!"
	ldw bc, 0x30
	ldw de, 0xa0
	call Draw_FlashMemUpdate_message_bitmap
	pushw 0x8
	pushw 0x1
	ld xwa, Bitmap_1bit_Turn_On_AGAIN	; "Turn On AGAIN !!"
	ldw bc, 0x30
	ldw de, 0xc8
	call Draw_FlashMemUpdate_message_bitmap

Flash_CheckAndValidate:
	ld wa, 2:i3
	call Flash_IdentifyAndValidateChip
	cp hl, 0xffff
	jr z, flash_update__not_today
	cpib_erp 0xfb, 6	; Is it "HD-AEPRG DATA FILE"?
	jr nz, flash_update__not_today
	pushw 0x8
	pushw 0x2
	ld xwa, Bitmap_1bit_Flash_Memory_Update	; "Flash Memory Update"
	ldw bc, 0x30
	ldw de, 0x50
	call Draw_FlashMemUpdate_message_bitmap
	ldto_berp A, 0xfb
	extz wa
	calr Erase_and_Burn____when_disk_is_valid
	pushw 0x8
	pushw 0x1
	ld xwa, Bitmap_1bit_Completed	; "Completed!"
	ldw bc, 0x30
	ldw de, 0xa0
	call Draw_FlashMemUpdate_message_bitmap
	pushw 0x8
	pushw 0x1
	ld xwa, Bitmap_1bit_Turn_On_AGAIN	; "Turn On AGAIN !!"
	ldw bc, 0x30
	ldw de, 0xc8
	call Draw_FlashMemUpdate_message_bitmap

flash_update__not_today:
	popw_erp 0xfa
	ret

; =============================================================================
; Draw_FlashMemUpdate_message_bitmap - Draw 224x22 monochrome bitmap
;
; Renders a 1bpp monochrome bitmap (224 pixels wide × 22 pixels tall) to the
; offscreen buffer at 0x43c00, then blits the entire buffer to VRAM.
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
	ld iz, 0:i3

DrawBitmap_RowLoop:
	ld wa, iz
	extz xwa
	div wa, 0x1c	; 28 bytes = 224 pixels de largura da imagem a ser desenhada
	ldto_werp WA, 0xe2
	cp wa, 0:i3
	jr nz, DrawBitmap_CheckNewRow
	ld iy, hl	; IY = coordanada X do canto esquerdo da imagem a ser desenhada
	dec 1, ix

DrawBitmap_CheckNewRow:
	ldiw_erp 0xee, 0

DrawBitmap_BitLoop:
	ld de, iz
	extz xde
	add xde, (xsp + 2)
	lda xwa, (0xe36a:16); table of bit masks (equivalent to 1044h on boot "table_data" rom)
	ldto_werp BC, 0xee
	extz xbc
	add xbc, xwa	; indexing bit masks with value of QHL
	ld a, (xbc)
	and a, (xde)	; here XDE points at one of the bytes of the image we're drawing and we select the bit we need
	ldfr_berp A, 0xf2
	ld de, ix
	extz xde
	lda xbc, (OFFSCREEN_BUFFER_1:24); aparentemente isso é um buffer offscreen

; Convert Y coordinate to framebuffer row offset: XWA = XDE * 320
; Uses shift-add: (XDE << 2 + XDE) << 6 = XDE * 5 * 64 = XDE * 320
Set_XWA_to_320_times_XDE:
	ld xwa, xde
	sll xwa, 2		; XWA = Y * 4
	add xwa, xde		; XWA = Y * 5
	sll xwa, 6		; XWA = Y * 320
	cpib_erp 0xf2, 0
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
	inc1w_erp 0xee
	cp_erpw 0xee, 0x08, 0x00
	jr c, DrawBitmap_BitLoop
	inc 1, iz
	cp iz, 0x268	; 28 bytes (224 pixels/line) * 22 lines = 0268h bytes
	jr c, DrawBitmap_RowLoop
	lda xwa, (0x1a0000:24)
	ldw de, 0x9600	; 2 pixels per word
	call Copy_DE_words_from_XBC_to_XWA	; <-- "blit-screen"
	popw iz
	inc 4, xsp
	retd 0x4

;=============================================================================
; VRAM_FillRect - Fill a rectangular region in video RAM with a color
;
; Fills a 12-pixel tall rectangle in video RAM (0x1a0000) with the specified
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
	addiw_da (xsp + 4), 0xc	; End Y = start + 12
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
	ld xiz, 0x1a0000
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
