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
	sti16_24 0x00ffca, 0x0000
	calr NMI_StorePayloadChecksums
	bitda 2, 0xfdad
	jr z, NMI_SetPowerOffCode_A5A5
	sti16_24 0x00ffcc, 0x5a5a
	jr NMI_ClearGuardAndHalt

NMI_SetPowerOffCode_A5A5:
	sti16_24 0x00ffcc, 0xa5a5

NMI_ClearGuardAndHalt:
	stdi8 1024, 0
	resda 7, 354
	set_dd8 2, 0x3c
	halt
NMI_HaltLoop:
	jr	t, 0xfd

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
NMI_StorePayloadChecksums_Entry:
	cpdi8 1024, 128
	ret nz
	call Demo_SelectEntry_PreSaveCheck
	call SeqPlay_JumpCopyVoiceData
	ld xwa, 0xf180
	ldw bc, 0x800
	call Checksum_ComputeComplement
	st16_24 0x00ffd4, xhl
	ld xwa, 0xf980
	ldw bc, 0x280
	call Checksum_ComputeComplement
	st16_24 0x00ffd2, xhl
	call Seq_IsMelodyActive
	cps hl, 0
	jr z, NMI_CopyPayloadToSRAM
	adddi16_24 0xffd4, 1000

NMI_CopyPayloadToSRAM:
	lda_24 xde, 0x00066e
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
SubCPU_Payload_Verify_Entry:
	ld xwa, 0xf180	; Start of payload region 1
	ldw bc, 0x800	; Size: 0x800 words
	call Checksum_ComputeComplement	; Compute checksum -> HL
	lda_24 xwa, 0x00f980
	cpda16_24 xhl, 0xffd4	; Compare with expected checksum
	jr nz, SubCPU_Payload_Verify_Fail	; First region checksum failed
	sti8_24 0x01e53e, 0x00                 ; Mark as success (so far)
	ldw bc, 0x280	; Size of second region
	call Checksum_ComputeComplement	; Compute second checksum
	cpda16_24 xhl, 0xffd2	; Compare with expected
	ret z	; Both match -> success
	sti8_24 0x01e53e, 0xff                 ; Second region failed
	ret

SubCPU_Payload_Verify_Fail:
SubCPU_Payload_Verify_Fail_Entry:
	sti8_24 0x01e53e, 0xff                 ; Mark as failed
	ldw bc, 0x280
	call Checksum_ComputeComplement
	cpda16_24 xhl, 0xffd2
	ret nz	; Both checksums wrong
	sti8_24 0x01e53e, 0x01                 ; First wrong, second correct (partial)
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
SubCPU_Payload_GetErrorFlag_Entry:
	ld8_24 l, 0x01e53e
	exts hl
	ret

SubCPU_PayloadErrorStore:
	sti8_24 0x01e53e, 0xff
	ret

Sys_CheckPowerStableFlag:
	cpdi16_24 0xffcc, 0x5a5a
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
	ldw wa, 0x3c4
	lds bc, 6
	calr Vga_WritePortShortDelay
	ldw wa, 0x3c5
	lds bc, 1
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
	lds bc, 6
	calr Vga_WritePortShortDelay
	ldw wa, 0x3c5
	lds bc, 0
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
	ld xbc, 0xab000
	ld xde, 0x5c00
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 1
	calr Vga_SelectWritePlane
	lda_24 xbc, 0x0ab000
	add xbc, 0xb800
	ld xwa, 0x1a0000
	ld xde, 0x10000
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 2
	calr Vga_SelectWritePlane
	lda_24 xbc, 0x0ab000
	add xbc, 0x2b800
	ld xwa, 0x1a0000
	ld xde, 0x10000
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 3
	calr Vga_SelectWritePlane
	lda_24 xbc, 0x0ab000
	add xbc, 0x4b800
	ld xwa, 0x1a0000
	ldw de, 0x4c00
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 0
	calr Vga_SelectWritePlane
	jp Start_8bit_Timer_3

Vga_RestoreMultiPlaneDisplay:
	call Stop_and_Clear_8bit_Timer_3
	ld xwa, 0xf180
	ld xbc, 0x1b4000
	ldw de, 0x400
	call Copy_DE_words_from_XBC_to_XWA
	ld xwa, 0xab000
	ld xbc, 0x1b4800
	ld xde, 0x5c00
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 1
	calr Vga_SelectWritePlane
	lda_24 xwa, 0x0ab000
	add xwa, 0xb800
	ld xbc, 0x1a0000
	ld xde, 0x10000
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 2
	calr Vga_SelectWritePlane
	lda_24 xwa, 0x0ab000
	add xwa, 0x2b800
	ld xbc, 0x1a0000
	ld xde, 0x10000
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 3
	calr Vga_SelectWritePlane
	lda_24 xwa, 0x0ab000
	add xwa, 0x4b800
	ld xbc, 0x1a0000
	ldw de, 0x4c00
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 0
	calr Vga_SelectWritePlane
	jp Start_8bit_Timer_3

Vga_BackupPlane3ToBuffer:
	call Stop_and_Clear_8bit_Timer_3
	lds wa, 3
	calr Vga_SelectWritePlane
	ld xwa, 0x1a9800
	ld xbc, 0x69800
	ld xde, 0xb400
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 0
	calr Vga_SelectWritePlane
	jp Start_8bit_Timer_3

Vga_RestorePlane3FromBuffer:
	call Stop_and_Clear_8bit_Timer_3
	lds wa, 3
	calr Vga_SelectWritePlane
	ld xwa, 0x69800
	ld xbc, 0x1a9800
	ld xde, 0xb400
	call Copy_DE_words_from_XBC_to_XWA
	lds wa, 0
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
	stiw_dpi 0xe9, 0x00, 0x00
	dec 1, xbc
	or xbc, xbc
	jr z, MemCopy_DataValidation
	ldirw93
	cpi_werp 0xe6, 0
	jr z, MemCopy_DataValidation
	ldto_werp WA, 0xe6

Boot_InitWorkRAM_ZeroBlock1_Loop:
	ldirw93
	djnz xwa, Boot_InitWorkRAM_ZeroBlock1_Loop

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
	stiw_dpi 0xe9, 0x00, 0x00
	dec 1, xbc
	or xbc, xbc
	jr z, MemCopy_SetupAndDMA
	ldirw93
	cpi_werp 0xe6, 0
	jr z, MemCopy_SetupAndDMA
	ldto_werp WA, 0xe6

Boot_InitWorkRAM_ZeroBlock2_Loop:
	ldirw93
	djnz xwa, Boot_InitWorkRAM_ZeroBlock2_Loop

MemCopy_SetupAndDMA:
	bit 0, ix
	jr z, Boot_InitWorkRAM_ROMCopy1_Start
	ld (xde), 0x0

Boot_InitWorkRAM_ROMCopy1_Start:
	ld xde, 0x3d524
	ld xhl, CharMap_FullPermutation_0x7B0_
	ld xbc, 0x219e
	or xbc, xbc
	jr z, Boot_InitWorkRAM_ROMCopy2_Start
	ldir83
	cpi_werp 0xe6, 0
	jr z, Boot_InitWorkRAM_ROMCopy2_Start
	ldto_werp WA, 0xe6

Boot_InitWorkRAM_ROMCopy1_Loop:
	ldir83
	djnz xwa, Boot_InitWorkRAM_ROMCopy1_Loop

Boot_InitWorkRAM_ROMCopy2_Start:
	ld xde, 0xe35e
	ld xhl, Naka_DrawbarReg_Table_0x4DE_
	ld xbc, 0x95b
	or xbc, xbc
	jr z, Boot_InitWorkRAM_Done
	ldir83
	cpi_werp 0xe6, 0
	jr z, Boot_InitWorkRAM_Done
	ldto_werp WA, 0xe6

Boot_InitWorkRAM_ROMCopy2_Loop:
	ldir83
	djnz xwa, Boot_InitWorkRAM_ROMCopy2_Loop

Boot_InitWorkRAM_Done:
	jrl Boot_RunSelfTest
	ret

Boot_InitWorkRAM_Trailer:
	ret

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
	and a, 0x7f
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
	cp a, 0xf1
	jr ugt, INTT1_CheckScanFlag
	inc 1, a

INTT1_CheckScanFlag:
	stda8 1066, a
	bitda 2, 0xfd50
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
	cpdi8 0x8d34, 19
	jr z, UIState_DispatchBranch
	bitda 2, 0xfd52
	jr z, UIState_DispatchBranch
	bitda 2, 0xfd50
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
	cpdi8 0x8d34, 19
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
	bitda 2, 0xfd50
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
	lda_24 xhl, UI_STATE_MACHINE_TABLE
	ld_sril3 XHL, 0x03, 0xec, 0xe0
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
	and a, 0xf
	sll a, 2
	lda_24 xhl, UI_SUBSTATE_TABLE
	ld_sril3 XHL, 0x03, 0xec, 0xe0
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
	bitda 2, 0xfd50
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
	cpdi8 0x7f0b, 0
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
	cpdi8 0x379b, 0
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
	cpda8 a, 0x34d7
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
	cpdi16 0x28aa, 0
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
	cpdi8 0x8d34, 19
	jr z, INTTR4_SeqAutoStart_Skip
	bitda 2, 0xfd52
	jr z, INTTR4_SeqAutoStart_Skip
	bitda 2, 0xfd50
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
	cpdi8 0x8d34, 19
	jr z, INTTR4_SeqBeat_Check
	bitda 2, 0xfd52
	jr z, INTTR4_SeqBeat_Check
	bitda 2, 0xfd50
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
	cpdi8 0x8d34, 19
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
	stda16 0x3372, xwa
	stda8 1122, a
	stda8 0x3376, a
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
	cpdi16 0x28aa, 0
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
	cpdi16 0x28aa, 0
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
	stda16 0x7dfe, xwa
	stda8 1133, a
	stda8 0x7dfc, a
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
	stib_dri 0x07, 0xf4, 0xec, 0x81
	minc1_16 hl, 0x7ff
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
	stib_dri 0x07, 0xec, 0xf0, 0x81
	inc 1, ix
	stda16 1141, xix
	popw ix

TempoRingBuf_Write_Return:
	ret

TempoRingBuf_WritePair:
	bitda 0, 1113
	jr nz, TempoRingBuf_WritePair_Enqueue
	cpdi16_24 0x1e751, 2
	jr c, TempoRingBuf_WritePair_ClearPending
	push_sr
	ei 6
	push xiy
	lda_24 xiy, 0x01e753
	ld hl, (xiy - 4)
	lda_dri3 XBC, 0x07, 0xf4, 0xec
	decm 1, (xiy - 2)
	minc1_16 hl, 0x7ff
	ldda8 a, 1051
	lda_dri3 XBC, 0x07, 0xf4, 0xec
	minc1_16 hl, 0x7ff
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
	lda_dri3 XBC, 0x07, 0xec, 0xf0
	ldda8 a, 1051
	inc 1, ix
	lda_dri3 XBC, 0x07, 0xec, 0xf0
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
	.byte 0xf1
	push_a
	.byte 0x04
	cp	(xwa-80), xiz
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
	cpdi8 1124, 7
	jr ule, MainLoop_AfterSeqTick
	calr Seq_TickWrapper

MainLoop_AfterSeqTick:
	ei 6
	ldda8 a, 1063
	and a, 0x2c
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
	ldda8 a, 0x346d
	and a, 0x3
	jr z, MainLoop_AfterAccWrap
	ldda8 a, 0x3283
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
	cpdi8 0xbf39, 255
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
	mrid2 0xb5, 0xae
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
	cpdi8 0xcedf, 0
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
	stdi8 0xc039, 255
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
	bit_dri 7, 0x07, 0xec, 0xf4
	jr nz, MidiEvt_FoundStatusByte
	inc 1, iz
	minc1_16 iy, 0x3ff
	cp iy, ix
	jrl z, MidiSerial_BufferWrap
	jr MidiEvt_ScanLoop

MidiEvt_FoundStatusByte:
	ld_srib3 C, 0x07, 0xec, 0xf4
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
	cp_srib_im 0x07, 0xec, 0xf4, 0x7b
	jr c, MidiSerial_DataReceive

MidiEvt_SetNoteOnFlag:
	ldb b, 0x1

MidiSerial_DataReceive:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr z, MidiEvt_AdvancePointer
	ld_srib3 A, 0x07, 0xec, 0xf4
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
	cp_srib_im 0x07, 0xec, 0xf4, 0x7b
	ld iz, wa
	ld iy, de
	jr c, MidiEvt_ClearDataFlag

MidiEvt_SetDataFlag:
	or b, 0x2
	jr MidiEvt_CheckProcessMode

MidiEvt_ClearDataFlag:
	and b, 0xfd

MidiEvt_CheckProcessMode:
	cps b, 1
	jr z, MidiEvt_ProcessNoteOn
	cps b, 2
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
; SwbtWr_ReinitBothBanks - Reinitialize both tone generator output banks
; Original Matsushita debug symbol: "assswb_op" (assign sound write bank - operation)
; Calls SwbtWr_InitBank1 and SwbtWr_InitBank2 to reinitialize voice
; parameter transfers to the tone generator.
SwbtWr_ReinitBothBanks:

	cpdi8 0xbd3c, 255
	jr z, SwbtWr_ReinitBothBanks_Return
	call SwbtWr_InitBank1
	call SwbtWr_InitBank2
	stdi8 0xbd3c, 255
	stdi16 0x90de, 0

SwbtWr_ReinitBothBanks_Return:
	ret
; SwbtWr_ReinitOutputBank - Reinitialize the output tone generator bank
; Original Matsushita debug symbol: "assswb_out" (assign sound write bank - output)
; Calls only SwbtWr_InitBank2 (the output bank).
SwbtWr_ReinitOutputBank:

	cpdi8 0xbd3c, 255
	jr z, SwbtWr_ReinitOutputBank_Return
	call SwbtWr_InitBank2
	stdi8 0xbd3c, 255
	stdi16 0x90de, 0

SwbtWr_ReinitOutputBank_Return:
	ret

RhythmBuf_ProcessEvents:
	bitda 2, 1054
	jr z, RhythmBuf_ProcessLoop
	calr SeqTiming_Snapshot

RhythmBuf_ProcessLoop:
	ld16_24 xwa, 0x01ef59
	cpda16_24 xwa, 0x1ef55
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
	adddm16_24 0x1ef5b, xwa
	ret

RhythmBuf_ScanForNoteOn:
	ld iy, (xhl - 8)
	ld ix, (xhl - 4)

RhythmBuf_Scan_SkipNonStatus:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr nz, RhythmBuf_Scan_FoundStatus
	minc1_16 iy, 0x1ff
	cp iy, ix
	jr z, RhythmBuf_Scan_EndReached
	jr RhythmBuf_Scan_SkipNonStatus

RhythmBuf_Scan_FoundStatus:
	ld de, iy
	ld_srib3 C, 0x07, 0xec, 0xf4
	and c, 0xf0

RhythmBuf_Scan_CheckNext:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr z, RhythmBuf_Scan_Advance
	ld de, iy
	ld_srib3 A, 0x07, 0xec, 0xf4
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
	bit_dri 7, 0x07, 0xec, 0xf4
	jr nz, SeqEvt_Scan_FoundStatus
	minc1_16 iy, 0xff
	cp iy, ix
	jr z, SeqEvt_Scan_EndReached
	jr SeqEvt_Scan_SkipData

SeqEvt_Scan_FoundStatus:
	ld de, iy
	ld_srib3 C, 0x07, 0xec, 0xf4
	and c, 0xf0

SeqEvt_Scan_CheckNext:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr z, SeqEvt_Scan_Advance
	ld de, iy
	ld_srib3 A, 0x07, 0xec, 0xf4
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
	anddi8 1115, 253
	scf

SeqEvt_Scan_Return:
	ret

SeqEvt_CallTimingHelper:
	call SeqPlay_HandleVoiceReassign
	ret

SeqEvt_ProcessTimedEvents:
	bitda 5, 0x28ac
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
	ld_srib3 E, 0x07, 0xf0, 0xec
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
	.byte 0xf1
	pop	xbc
	.byte 0x04
	dec	6, w
	.byte 0x06
	ldb	e, 129
	calr	24
	ret
	push	xix
	ldada	xix, 1143
	ldda16	hl, 1141
	.byte 0xf3
	reti
	.byte 0xf0, 0xec
	nop
	xor	(xbc), c
	jr	lt, -15
	jrl	mi, 0x5304
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
	lda_dri3 XIY, 0x07, 0xf0, 0xec
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
	anddi8 1058, 127
	ldda8 a, 0xe9bc
	and a, a
	jr z, SeqEvt_CheckExpiry_Return
	dec 1, a
	stda8 0xe9bc, a
	jr nz, SeqEvt_CheckExpiry_Return
	call NoteMap_FindBestMatch
	cp l, 0xff
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
	cpda16 xwa, 0x3372
	jr c, SeqTiming_Snapshot_CheckFrac
	stdi16 1120, 0

SeqTiming_Snapshot_CheckFrac:
	cpda8 l, 0x3376
	jr c, SeqTiming_Snapshot_PostSnap
	stdi8 1122, 0

SeqTiming_Snapshot_PostSnap:
	ei 0
	cpda16 xwa, 0x3372
	jr c, SeqTiming_Snapshot_CheckFracOverflow
	push xhl
	call AccTiming_InitAllParts
	xor wa, wa
	stda16 1118, xwa
	pop xhl

SeqTiming_Snapshot_CheckFracOverflow:
	cpda8 l, 0x3376
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
	cpda16 xwa, 0x7dfe
	jr c, SyncTiming_Snapshot_CheckFrac
	stdi16 1136, 0

SyncTiming_Snapshot_CheckFrac:
	cpda8 l, 0x7dfc
	jr c, SyncTiming_Snapshot_PostSnap
	stdi8 1133, 0

SyncTiming_Snapshot_PostSnap:
	ei 0
	cpda16 xwa, 0x7dfe
	jr c, SyncTiming_Snapshot_CheckFracOverflow
	push xhl
	call SeqEvt_EntryPoint2
	xor wa, wa
	stda16 1134, xwa
	pop xhl

SyncTiming_Snapshot_CheckFracOverflow:
	cpda8 l, 0x7dfc
	jr c, SyncTiming_Snapshot_Return
	call SeqEvt_EntryPoint1

SyncTiming_Snapshot_Return:
	ret

Seq_FullInit:
	ldb a, 0xff
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
	stdi8 0xbf39, 255
	ret

Seq_InitStub_Nop1:
	ret

Seq_InitStub_Nop2:
	ret

Seq_InitStub_Nop3:
	ret

AudioMix_Init:
	link32 0xee, 0x0c, 0xf8, 0xff
	xor xwa, xwa
	ld xwa, 0x5a5a5a5a
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
	ld xwa, 0x101001f
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
	ld_spib E, 0xe4
	ld (xhl + 2), e
	inc 1, a
	djnz8 d, AudioMix_WriteChannelGroup_Loop
	popw de
	ret

AudioMix_BytecodeData:
	.byte 0x39, 0x3a, 0x0b, 0x01, 0x00, 0x1e, 0x24, 0x00
	.byte 0xaf, 0x0a, 0x21, 0xee, 0x8a, 0x0b, 0x00, 0x00
	.byte 0x1e, 0x19, 0x00, 0xe8, 0x89, 0xeb, 0x8a, 0x0b
	.byte 0x02, 0x00, 0x1e, 0x0f, 0x00, 0xec, 0x89, 0xed
	.byte 0x8a, 0x0b, 0x03, 0x00, 0x1e, 0x05, 0x00, 0xef
	.byte 0x60, 0x5a, 0x59, 0x0e, 0x3d, 0x28, 0x29, 0x8f
	.byte 0x0c, 0x21, 0xc9, 0xee, 0x05, 0xc9, 0x31, 0x04
	.byte 0x45, 0x00, 0x00, 0x15, 0x00, 0xb5, 0x41, 0xbd
	.byte 0x02, 0x43, 0xc9, 0x61, 0xb5, 0x41, 0xbd, 0x02
	.byte 0x42, 0xc9, 0x61, 0xb5, 0x41, 0xd7, 0xe6, 0x89
	.byte 0xbd, 0x02, 0x43, 0xc9, 0x61, 0xb5, 0x41, 0xbd
	.byte 0x02, 0x42, 0xc9, 0x61, 0xb5, 0x41, 0xbd, 0x02
	.byte 0x45, 0xc9, 0x61, 0xb5, 0x41, 0xbd, 0x02, 0x44
	.byte 0xc9, 0x61, 0xb5, 0x41, 0xd7, 0xea, 0x89, 0xbd
	.byte 0x02, 0x43, 0xc9, 0x61, 0xb5, 0x41, 0xbd, 0x02
	.byte 0x42, 0x49, 0x48, 0x5d
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
;   XDE = word count (decrements to zero)
;   BC  = 16-bit fill pattern (e.g., color | (color << 8) for 8bpp)
; =============================================================================
Fill_memory_at_XWA_with_DE_words_of_BC_value:
	st_dpiw BC, 0xe1
	djnz xde, Fill_memory_at_XWA_with_DE_words_of_BC_value
	ret

Checksum_ComputeComplement:
	xor xhl, xhl
	extz xbc
	add xbc, xwa

Checksum_AccumulateLoop:
	add_spil XHL, 0xe2
	cp xwa, xbc
	jr lt, Checksum_AccumulateLoop
	cpl hl
	ret

TaskSched_ScreenGroupTable:
	.long Boot_InitPeripherals
	.byte 0x34, 0xdc, 0x01, 0x00
	.byte 0x00, 0x88, 0x03, 0x00, 0x92, 0x2d, 0xf5, 0x00
	.byte 0x36, 0xe4, 0x01, 0x00, 0x00, 0x88, 0x03, 0x00
	.long TaskSched_ScreenGroupTable_End
	.byte 0xb8, 0xe4, 0x01, 0x00
	.byte 0x00, 0x88, 0x01, 0x00, 0x6c, 0x80, 0xf9, 0x00
	.byte 0x30, 0xc0, 0x01, 0x00, 0x00, 0x88, 0x03, 0x00
	.byte 0xfa, 0xa2, 0xfa, 0x00, 0x32, 0xd0, 0x01, 0x00
	.byte 0x00, 0x88, 0x03, 0x00, 0x01, 0x01, 0x01, 0x01
	.fill 8, 1, 0x01
	.fill 8, 1, 0x01
	.byte 0x01, 0x01
TaskSched_ScreenGroupTable_End:
	jr	-2

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
	ld xsp, 0x1e53a
	xor wa, wa
	stda16 1159, xwa
	inc 1, wa
	ldc_cr16 wa, 0x7c
	stda16 1475, xwa
	ldw hl, 0x4c5
	extz xhl
	lds de, 4
	ldb b, 0x3

TaskSched_InitPriorityQueues:
	ld ix, hl
	st_dpiw IX, 0xed
	st_dpiw IX, 0xed
	djnz8 b, TaskSched_InitPriorityQueues
	ldw ix, 0x489
	extz xix
	ldb b, 0x5
	ldb a, 0x0

TaskSched_InitTCBFields:
	ld (xix + 9), a
	ld (xix + 10), 0x0
	ld (xix + 11), 0x0
	add ix, 0xc
	djnz8 b, TaskSched_InitTCBFields
	ldw ix, 0x5bb
	extz xix
	ldb b, 0x1
	ld xwa, 0xffffffff

TaskSched_InitTimerSlots:
	ld (xix + 4), xwa
	add ix, 0x8
	djnz8 b, TaskSched_InitTimerSlots
	ld xhl, TaskSched_ScreenGroupTable_0x3C_
	ldw de, 0x4f9
	extz xde
	ldw bc, 0xa
	ldir83
	ldw hl, 0x4d1
	extz xhl
	ldb b, 0xa

TaskSched_InitExtQueues:
	ld ix, hl
	st_dpiw IX, 0xed
	st_dpiw IX, 0xed
	djnz8 b, TaskSched_InitExtQueues
	ld xhl, TaskSched_ScreenGroupTable_0x46_
	ldw de, 0x533
	extz xde
	ldw bc, 0xc
	ldir83
	ldw hl, 0x503
	extz xhl
	ldb b, 0xc

TaskSched_InitExtQueues2:
	ld ix, hl
	st_dpiw IX, 0xed
	st_dpiw IX, 0xed
	djnz8 b, TaskSched_InitExtQueues2
	ldw hl, 0x567
	extz xhl
	ldb b, 0xa
	ld xwa, 0xffffffff

TaskSched_InitFreeList:
	ld (xhl + 4), xwa
	add hl, 0x8
	djnz8 b, TaskSched_InitFreeList
	ldw iy, 0x5b7
	extz xiy
	ld (xiy + 256), iy
	ld (xiy + 2), iy
	ldw ix, 0x567
	ldb b, 0xa

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
	ldw hl, 0x53f
	extz xhl
	ldb b, 0x5

TaskSched_InitLockQueues:
	ld ix, hl
	st_dpiw IX, 0xed
	st_dpiw IX, 0xed
	djnz8 b, TaskSched_InitLockQueues
	ldw hl, 0x553
	extz xhl
	ldb b, 0x5

TaskSched_InitMsgQueues:
	ld ix, hl
	st_dpiw IX, 0xed
	st_dpiw IX, 0xed
	djnz8 b, TaskSched_InitMsgQueues
	ld xwa, TaskSched_InitMsgQueues_0x12_
	jr TaskSched_PostInit

	normal
	nop
	normal
	nop
	jr	pe, 25
	.byte 0xef
	nop

TaskSched_PostInit:
	call TaskTimer_Register
	calr Stop_and_Clear_8bit_Timer_3
	ldio 0x8b, 0x07
	ld_sd8b A, 0xe5
	and a, 0xf
	or a, 0x20
	st_dd8b A, 0xe5
	calr Start_8bit_Timer_3
	ldb a, 0x1
	calr Show_ScreenGroup
	ei 6
	stdi8 1157, 0
	xor wa, wa
	ldc_cr16 wa, 0x7c
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
	ld xsp, 0x1e53a
	xor wa, wa
	stda16 1159, xwa

TaskSched_ScanPriorityQueues:
	ldb b, 0x3
	ldw ix, 0x4c5
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
	ldc_cr16 wa, 0x7c
	ei 0
	ldw ix, 0x5bb
	extz xix
	ldb b, 0x1

TaskSched_CheckTimerSlot:
	ld xwa, (xix + 4)
	cp xwa, 0xffffffff
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
	ldc_cr16 wa, 0x7c
	ret

TaskSched_TimerSlot_Fire:
	ld wa, (xix + 2)
	ld (xix + 256), wa
	lda_24 xwa, TaskSched_TimerSlot_Skip
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
	ldc_cr16 wa, 0x7c
	popw wa
	reti

INTT3_EnterScheduler:
	xor wa, wa
	stda16 1475, xwa
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
	ldb l, 0xc
	mul8rr l, a
	extz xhl
	add xhl, Checksum_ComputeComplement_0x04_
	ldb c, 0xc
	mul8rr c, a
	add bc, 0x47d
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
	add wa, 0x4c1
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
	ld xsp, 0x1e53a
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
	add wa, 0x4c1
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
	add wa, 0x4c1
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
	mul a, 0xc
	add wa, 0x47d
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
	add wa, 0x4cd
	ld iy, wa
	extz xiy
	ld ix, (xiy + 256)
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
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
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
	add wa, 0x4cd
	ld iy, wa
	extz xiy
	push_sr
	ei 6
	ld ix, (xiy + 256)
	cp ix, iy
	jr nz, TaskSched_SignalEvent_NoBlock_Unlink
	extz hl
	add hl, 0x4f8
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
	add wa, 0x4c1
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
	add wa, 0x4f8
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
	add de, 0x4cd
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
	add wa, 0x4f8
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
	add wa, 0x4ff
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
	add wa, 0x4c1
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
	add wa, 0x4ff
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
	add wa, 0x4c1
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
	add de, 0x4ff
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
	ldw hl, 0xffff

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
	add wa, 0x53b
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
	add bc, 0x54f
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
	ldw (xsp + 24), 0xffff
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
	add wa, 0x4c1
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
	add wa, 0x53b
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
	add bc, 0x54f
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
	ldw (xsp + 4), 0xffff
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
	add wa, 0x4c1
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
	add wa, 0x54f
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
	ld xbc, 0xffffffff
	ld (xix + 4), xbc
	ldw iy, 0x5b7
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
	add de, 0x53b
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
	add wa, 0x54f
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
	ld xwa, 0xffffffff
	ld (xix + 4), xwa
	ldw iy, 0x5b7
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
	add wa, 0x5b3
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
	mul a, 0xc
	add wa, 0x47d
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
	add de, 0x4c1
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
	mul a, 0xc
	add wa, 0x47d
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
	add de, 0x4c1
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
	.byte 0x9c
	nop
	.byte 0x20
	ld	hl, (xix+2)
	.byte 0xbb
	nop
	.byte 0x50
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
	.byte 0xd1, 0xc3
	halt
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	ld16_24	hl, 0x1e545
	.byte 0xd2
	ld	xbc, 0xdbf301e5
	.byte 0xa8
	jr	z, 3
	ldw	hl, 0xffff
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
	lda_24	xde, 0x1e549
	call	RingBuf512_ReadAlt_ByteBlock
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 0x1e543
	st16_24	0x1e541, hl
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	cpda16_24 xhl, 0x1e74b
	lds hl, 0
	jr z, TempoRingBuf_CheckEmpty_Return
	ldw hl, 0xffff

TempoRingBuf_CheckEmpty_Return:
	ret

TempoRingBuf_BytecodeSnippet2:
	ld16_24	hl, 0x1e751
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
	lda_24	xde, 0x1e753
	call	Seq_RingBuf_WriteByte_Data
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
	ld16_24	hl, 0x1e74d
	st16_24	0x1e74b, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 0x1e74f
	st16_24	0x1e74d, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x1ef5d
	calr	2738
	pop	xde
	popw	ix
	ret

RhythmBuf_WriteByte:
	link32 0xee, 0x0c, 0x00, 0x00
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
	lda_24	xde, 0x1ef5d
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
	cpda16_24 xhl, 0x1ef55
	lds hl, 0
	jr z, RhythmBuf_CheckEmpty_Return
	ldw hl, 0xffff

RhythmBuf_CheckEmpty_Return:
	ret

RhythmBuf_BytecodeSnippet:
	ld16_24	hl, 0x1ef5b
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
	lda_24	xde, 0x1ef5d
	call	RingBuf512_ReadAlt_ByteBlock
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 0x1ef57
	st16_24	0x1ef55, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 0x1ef59
	st16_24	0x1ef57, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x1f167
	calr	2421
	pop	xde
	popw	ix
	ret
	link	xiz, 0
	pushw	ix
	push	xde
	ld	a, (xiz+8)
	lda_24	xde, 0x1f167
	calr	2485
	pop	xde
	popw	ix
	unlk	xiz
	ret

AltEvtBuf_WriteBytes:
	link32 0xee, 0x0c, 0x00, 0x00
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
	ld16_24	hl, 0x1f163
	.byte 0xd2
	pop	xsp
	.byte 0xf1, 0x01, 0xf3
	lds	hl, 0
	jr	z, 3
	ldw	hl, 0xffff
	ret
	ld16_24	hl, 0x1f165
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
	ld16_24	hl, 0x1f15f
	st16_24	0x1f15d, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x1f167
	call	Seq_RingBuf_ReadByte_Large
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x1f167
	call	Seq_RingBuf_ReadByte_Small
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 0x1f161
	st16_24	0x1f15f, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 0x1f163
	st16_24	0x1f161, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x1f271
	calr	2247
	pop	xde
	popw	ix
	ret

SeqEvtBuf_WriteByte:
	link32 0xee, 0x0c, 0x00, 0x00
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
	lda_24	xde, 0x1f271
	ld	a, (xiy)
	calr	2283
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld16_24	hl, 0x1f26d
	cpda16_24	hl, 0x1f269
	lds	hl, 0
	jr	z, 3
	ldw	hl, 0xffff
	ret
	.byte 0xd2
	jr	nc, -14
	.byte 0x01
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
	; --- Sub 1: call EF2FBC with XDE=0x01f271 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 0x1f271
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret
SeqEvtBuf_SaveReadPos2:
	; --- Sub 2: copy (0x01f26b)->HL->(0x01f269) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x1f26b
	st16_24	0x1f269, hl
	popw hl
	ret
SeqEvtBuf_SaveReadPos3:
	; --- Sub 3: copy (0x01f26d)->HL->(0x01f26b) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x1f26d
	st16_24	0x1f26b, hl
	popw hl
	ret
SeqMain_ReadByte_1024:
	; --- Sub 4: calr EF30A1 with XDE=0x01f37b (13 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 0x1f37b
	calr Seq_RingBuf_Dequeue_1024
	pop xde
	popw ix
	ret


SeqMain_WriteByte:
	link32 0xee, 0x0c, 0x00, 0x00
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	cpda16_24 xhl, 0x1f373
	lds hl, 0
	jr z, Seq_CheckSongEnd_Return
	ldw hl, 0xffff

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
	lda_24	xde, 0x1f37b
	call	RingBuf1024_ReadAlt_ByteBlock
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 0x1f375
	st16_24	0x1f373, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 0x1f377
	st16_24	0x1f375, hl
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	cpda16_24 xhl, 0x1f77d
	lds hl, 0
	jr z, SeqBuf_MidiOut_CheckEmpty_Return
	ldw hl, 0xffff

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
	; --- Sub 1: copy (0x01f77d)->HL->(0x01f77b) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x1f77d
	st16_24	0x1f77b, hl
	popw hl
	ret
SeqBuf_MidiOut_ReadAlternate:
	; --- Sub 2: call EF2FA1 with XDE=0x01f785 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 0x1f785
	call Seq_RingBuf_ReadByte_Large
	pop xde
	popw ix
	ret
SeqBuf_MidiOut_ReadAlternate2:
	; --- Sub 3: call EF2FBC with XDE=0x01f785 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 0x1f785
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret
SeqBuf_MidiOut_SaveReadPos2:
	; --- Sub 4: copy (0x01f77f)->HL->(0x01f77d) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x1f77f
	st16_24	0x1f77d, hl
	popw hl
	ret
SeqBuf_MidiOut_SaveReadPos3:
	; --- Sub 5: copy (0x01f781)->HL->(0x01f77f) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x1f781
	st16_24	0x1f77f, hl
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	ld16_24	hl, 0x1f88b
	.byte 0xd2
	cp	(xsp), w
	.byte 0x01, 0xf3
	lds	hl, 0
	jr	z, 3
	ldw	hl, 0xffff
	ret
	ld16_24	hl, 0x1f88d
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
	; --- Sub 1: copy (0x01f887)->HL->(0x01f885) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x1f887
	st16_24	0x1f885, hl
	popw hl
	ret
SeqBuf2_ReadAlternate:
	; --- Sub 2: call EF3030 with XDE=0x01f88f (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 0x1f88f
	call RingBuf_CheckFull_256
	pop xde
	popw ix
	ret
SeqBuf2_ReadAlternate2:
	; --- Sub 3: call EF304B with XDE=0x01f88f (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 0x1f88f
	call RingBuf512_ReadAlt_ByteBlock
	pop xde
	popw ix
	ret
SeqBuf2_SaveReadPos2:
	; --- Sub 4: copy (0x01f889)->HL->(0x01f887) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x1f889
	st16_24	0x1f887, hl
	popw hl
	ret
SeqBuf2_SaveReadPos3:
	; --- Sub 5: copy (0x01f88b)->HL->(0x01f889) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x1f88b
	st16_24	0x1f889, hl
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	ld16_24	hl, 0x1fa95
	.byte 0xd2
	cp	(xbc), de
	.byte 0x01, 0xf3
	lds	hl, 0
	jr	z, 3
	ldw	hl, 0xffff
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
	ld16_24	hl, 0x1fa91
	st16_24	0x1fa8f, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x1fa99
	call	RingBuf_CheckFull_256
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x1fa99
	call	RingBuf512_ReadAlt_ByteBlock
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 0x1fa93
	st16_24	0x1fa91, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 0x1fa95
	st16_24	0x1fa93, hl
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	cpda16_24 xhl, 0x1fc9b
	lds hl, 0
	jr z, SeqBuf_DspSysEx_CheckSongEnd_Return
	ldw hl, 0xffff

SeqBuf_DspSysEx_CheckSongEnd_Return:
	ret

SeqBuf_DspSysEx_OrphanData:
	ld16_24	hl, 0x1fca1
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
	ld16_24	hl, 0x1fc9b
	st16_24	0x1fc99, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x1fca3
	call	Seq_RingBuf_ReadData
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x1fca3
	call	RingBuf1024_ReadAlt_ByteBlock
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 0x1fc9d
	st16_24	0x1fc9b, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 0x1fc9f
	st16_24	0x1fc9d, hl
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
	lda_24	xde, 0x200ad
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
	lda_24	xde, 0x200ad
	ld	a, (xiy)
	calr	1096
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld16_24	hl, 0x200a9
	.byte 0xd2, 0xa5
	nop
	push_sr
	.byte 0xf3
	lds	hl, 0
	jr	z, 3
	ldw	hl, 0xffff
	ret
	ld16_24	hl, 0x200ab
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x200ad
	call	RingBuf_InitStructFields
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 0x200a5
	st16_24	0x200a3, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x200ad
	call	RingBuf128_ReadAlt_CheckEmpty
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x200ad
	call	RingBuf128_ReadAlt2_CheckEmpty
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 0x200a7
	st16_24	0x200a5, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 0x200a9
	st16_24	0x200a7, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x20137
	calr	886
	pop	xde
	popw	ix
	ret


Seq_TimerEventLoop:
	link32 0xee, 0x0c, 0x00, 0x00
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
	lda_24	xde, 0x20137
	ld	a, (xiy)
	calr	922
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld16_24	hl, 0x20133
	.byte 0xd2
	pushw	sp
	.byte 0x01
	push_sr
	.byte 0xf3
	lds	hl, 0
	jr	z, 3
	ldw	hl, 0xffff
	ret
	ld16_24	hl, 0x20135
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x20137
	call	RingBuf_InitStructFields
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 0x2012f
	st16_24	0x2012d, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x20137
	call	RingBuf128_ReadAlt_CheckEmpty
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x20137
	call	RingBuf128_ReadAlt2_CheckEmpty
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 0x20131
	st16_24	0x2012f, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 0x20133
	st16_24	0x20131, hl
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	link32 0xee, 0x0c, 0x00, 0x00
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
	cpda16_24 xhl, 0x201b9
	lds hl, 0
	jr z, SeqBuf_VoiceMap_CheckEmpty_Done
	ldw hl, 0xffff

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
	; --- Sub 1: copy (0x0201b9)->HL->(0x0201b7) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x201b9
	st16_24	0x201b7, hl
	popw hl
	ret
SeqBuf_VoiceMap_CommitWrite:
	; --- Sub 2: call EF2FA1 with XDE=0x0201c1 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 0x201c1
	call Seq_RingBuf_ReadByte_Large
	pop xde
	popw ix
	ret
SeqBuf_VoiceMap_RollbackWrite:
	; --- Sub 3: call EF2FBC with XDE=0x0201c1 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 0x201c1
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret
SeqBuf_VoiceMap_SaveReadPtr:
	; --- Sub 4: copy (0x0201bb)->HL->(0x0201b9) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x201bb
	st16_24	0x201b9, hl
	popw hl
	ret
SeqBuf_VoiceMap_AdvanceCheckpoint:
	; --- Sub 5: copy (0x0201bd)->HL->(0x0201bb) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x201bd
	st16_24	0x201bb, hl
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
	lda_24	xde, 0x202cb
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
	lda_24	xde, 0x202cb
	ld	a, (xiy)
	calr	717
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld16_24	hl, 0x202c7
	.byte 0xd2, 0xc3
	push_sr
	push_sr
	.byte 0xf3
	lds	hl, 0
	jr	z, 3
	ldw	hl, 0xffff
	ret
	ld16_24	hl, 0x202c9
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
	ld16_24	hl, 0x202c3
	st16_24	0x202c1, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x202cb
	call	Seq_RingBuf_ReadByte_Large
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x202cb
	call	Seq_RingBuf_ReadByte_Small
	pop	xde
	popw	ix
	ret
	pushw	hl
	ld16_24	hl, 0x202c5
	st16_24	0x202c3, hl
	popw	hl
	ret
	pushw	hl
	ld16_24	hl, 0x202c7
	st16_24	0x202c5, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 0x203d5
	calr	507
	pop	xde
	popw	ix
	ret

SeqBuf_NoteEvent_WriteByte_Block:
	link	xiz, 0
	pushw	ix
	push	xde
	ld	a, (xiz+8)
	lda_24	xde, 0x203d5
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
	lda_24	xde, 0x203d5
	ld	a, (xiy)
	calr	543
	inc	1, xiy
	djnz16	bc, -10
	pop	xde
	pop	xix
	pop	xiy
	unlk	xiz
	ret
	ld16_24	hl, 0x203d1
	.byte 0xd2
	ld	e, 2
	.byte 0xf3
	lds	hl, 0
	jr	z, 3
	ldw	hl, 0xffff
	ret
	ld16_24	hl, 0x203d3
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
	; --- Sub 1: copy (0x0203cd)->HL->(0x0203cb) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x203cd
	st16_24	0x203cb, hl
	popw hl
	ret
SeqBuf_SoundEdit_CommitWrite:
	; --- Sub 2: call EF2FA1 with XDE=0x0203d5 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 0x203d5
	call Seq_RingBuf_ReadByte_Large
	pop xde
	popw ix
	ret
SeqBuf_SoundEdit_RollbackWrite:
	; --- Sub 3: call EF2FBC with XDE=0x0203d5 (14 bytes) ---
	pushw ix
	push xde
	lda_24	xde, 0x203d5
	call Seq_RingBuf_ReadByte_Small
	pop xde
	popw ix
	ret
SeqBuf_SoundEdit_SaveReadPtr:
	; --- Sub 4: copy (0x0203cf)->HL->(0x0203cd) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x203cf
	st16_24	0x203cd, hl
	popw hl
	ret
SeqBuf_SoundEdit_AdvanceCheckpoint:
	; --- Sub 5: copy (0x0203d1)->HL->(0x0203cf) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x203d1
	st16_24	0x203cf, hl
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
	lda_24	xde, 0x204df
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
	lda_24	xde, 0x204df
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
	cpda16_24 xhl, 0x204d7
	lds hl, 0
	jr z, SeqBuf_NoteEvent_CheckSongEnd_Return
	ldw hl, 0xffff

SeqBuf_NoteEvent_CheckSongEnd_Return:
	ret

SeqBuf_NoteEvent_OrphanData:
	ld16_24	hl, 0x204dd
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
	lda_24	xde, 0x204df
	call	Seq_RingBuf_ReadByte_Large
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
	; --- Sub 1: copy (0x0204d9)->HL->(0x0204d7) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x204d9
	st16_24	0x204d7, hl
	popw hl
	ret
RingBuf_CopyPtr_Sub2:
	; --- Sub 2: copy (0x0204db)->HL->(0x0204d9) (13 bytes) ---
	pushw hl
	ld16_24	hl, 0x204db
	st16_24	0x204d9, hl
	popw hl
	ret
RingBuf_InitStructFields:
	; --- Sub 3: init XDE struct fields at offsets -10..-2 (26 bytes) ---
	.byte 0xba, 0xf6
	push_sr
	nop
	nop
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
	ld_srib3 L, 0x07, 0xe8, 0xf0
	minc1_16 ix, 0x7f
	ld (xde - 8), ix
	incm 1, (xde - 2)
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
	ld_rrb	l, xde, ix
	.byte 0xdc
	push	xwa
	.byte 0x7f
	nop
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
	ld_rrb	l, xde, ix
	.byte 0xdc
	push	xwa
	.byte 0x7f
	nop
	ld (xde-10), ix
	ret


RingBuf128_WriteByte_CheckFull:
	cpw (xde - 2), 0x0
	jr nz, RingBuf128_WriteByte_Store
	ldw hl, 0xffff
	ret

RingBuf128_WriteByte_Store:
	ld ix, (xde - 4)
	lda_dri3 XBC, 0x07, 0xe8, 0xf0
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
	ld_srib3 L, 0x07, 0xe8, 0xf0
	minc1_16 ix, 0xff
	ld (xde - 8), ix
	incm 1, (xde - 2)
	ret

Seq_RingBuf_ReadByte_Large:
	ld ix, (xde - 10)
	cp ix, (xde - 6)
	jr nz, Seq_RingBuf_ReadByte_Large_Dequeue
	ldw hl, 0xffff
	ret

Seq_RingBuf_ReadByte_Large_Dequeue:
	xor hl, hl
	ld_srib3 L, 0x07, 0xe8, 0xf0
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
	ld_srib3 L, 0x07, 0xe8, 0xf0
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
	lda_dri3 XBC, 0x07, 0xe8, 0xf0
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
	ld_srib3 L, 0x07, 0xe8, 0xf0
	minc1_16 ix, 0x1ff
	ld (xde - 8), ix
	incm 1, (xde - 2)
	ret

RingBuf_CheckFull_256:
	ld ix, (xde - 10)
	cp ix, (xde - 6)
	jr nz, RingBuf256_CheckFull_Read
	ldw hl, 0xffff
	ret

RingBuf256_CheckFull_Read:
	xor hl, hl
	ld_srib3 L, 0x07, 0xe8, 0xf0
	minc1_16 ix, 0x1ff
	ld (xde - 10), ix
	ret

RingBuf512_ReadAlt_ByteBlock:
	ld	ix, (xde-10)
	cp	ix, (xde-4)
	jr	nz, 4
	ldw	hl, 0xffff
	ret
	xor	hl, hl
	.byte 0xc3
	reti
	cp	xwa, xwa
	ldb	l, 220
	push	xwa
	swi	7
	.byte 0x01
	ld	(xde-10), ix
	ret

Seq_RingBuf_WriteByte_512:
	cpw (xde - 2), 0x0
	jr nz, Seq_RingBuf_WriteByte_512_Store
	ldw hl, 0xffff
	ret

Seq_RingBuf_WriteByte_512_Store:
	ld ix, (xde - 4)
	lda_dri3 XBC, 0x07, 0xe8, 0xf0
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
	ld_srib3 L, 0x07, 0xe8, 0xf0
	minc1_16 ix, 0x3ff
	ld (xde - 8), ix
	incm 1, (xde - 2)
	ret

Seq_RingBuf_ReadData:
	ld ix, (xde - 10)
	cp ix, (xde - 6)
	jr nz, Seq_RingBuf_ReadData_Dequeue
	ldw hl, 0xffff
	ret

Seq_RingBuf_ReadData_Dequeue:
	xor hl, hl
	ld_srib3 L, 0x07, 0xe8, 0xf0
	minc1_16 ix, 0x3ff
	ld (xde - 10), ix
	ret

RingBuf1024_ReadAlt_ByteBlock:
	ld	ix, (xde-10)
	cp	ix, (xde-4)
	jr	nz, 4
	ldw	hl, 0xffff
	ret
	xor	hl, hl
	.byte 0xc3
	reti
	cp	xwa, xwa
	ldb	l, 220
	push	xwa
	swi	7
	pop_sr
	ld	(xde-10), ix
	ret

Seq_RingBuf_WriteByte:
	cpw (xde - 2), 0x0
	jr nz, Seq_RingBuf_WriteByte_1024_Store
	ldw hl, 0xffff
	ret

Seq_RingBuf_WriteByte_1024_Store:
	ld ix, (xde - 4)
	lda_dri3 XBC, 0x07, 0xe8, 0xf0
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
	ld_srib3 L, 0x07, 0xe8, 0xf0
	minc1_16 ix, 0x7ff
	ld (xde - 8), ix
	incm 1, (xde - 2)
	ret

Seq_RingBuf_WriteByte_Data:
	ld	ix, (xde-10)
	cp	ix, (xde-6)
	jr	nz, 4
	ldw	hl, 0xffff
	ret
	xor	hl, hl
	.byte 0xc3
	reti
	cp	xwa, xwa
	ldb	l, 220
	push	xwa
	swi	7
	reti
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
	ld_srib3 L, 0x07, 0xe8, 0xf0
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
	lda_dri3 XBC, 0x07, 0xe8, 0xf0
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
	lds iz, 0
	ld a, (xsp + 6)
	extz wa
	cps wa, 0
	jr ule, SeqDMA_MultiWrite_NoteEvent_Done

SeqDMA_MultiWrite_NoteEvent_Loop:
	ld xwa, (xsp + 2)
	ld_spib C, 0xe0
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
	ld_spib C, 0xe0
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
	ld_spib C, 0xe0
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
	ld_spib C, 0xe0
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
	and_sd8b_im 0xe5, 0xf8
	res_dd8 2, 0x80
	lda_dd8l XBC, 0xec
	ld a, (xbc)
	and a, 0xf8
	or a, 0x5
	ld (xbc), a
	lda_dd8l XBC, 0xed
	ld a, (xbc)
	and a, 0xf8
	or a, 0x5
	ld (xbc), a
	lda_dd8l XBC, 0xf0
	ld a, (xbc)
	and a, 0xf8
	set 0, a
	ld (xbc), a
	ldio 0x8a, 0x07
	lda_24 xwa, 0x140000
	ldc_cr32 xwa, 0x28
	ldb a, 0x8
	ldc_cr8 a, 0x4a
	lda_24 xwa, 0x140000
	ldc_cr32 xwa, 0x00
	ldb a, 0x0
	ldc_cr8 a, 0x42
	stdi8 1504, 0
	stdi8 1506, 0
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
	ldto_berp C, 0xf8
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
;        Timeout: 60000 iterations (0xea60)
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
	cp hl, 0xea60
	jr ule, InterCPU_Send_WaitReady
	ret

InterCPU_Send_AckTimeoutLoop:
	ld wa, ix
	inc 1, ix
	cp wa, 0xea60
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
;        Timeout: 60000 iterations (0xea60)
; ===========================================================================
InterCPU_E2_Send:
	lds ix, 0
	cpdi8 1504, 0
	jr z, InterCPU_E2_ClearAndSend

InterCPU_E2_WaitIdle:
	ld hl, ix
	inc 1, ix
	cp hl, 0xea60
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
	cp hl, 0xea60
	jr ule, InterCPU_E2_WaitAck
	set_dd8 0, 0x68	; MSTAT0 - timeout recovery: force ready state
	ret

; ===========================================================================
; Audio_DMA_Transfer - Core DMA transfer routine for inter-CPU communication
; ===========================================================================
; Entry: Data pointer at 0x05da, byte count at 0x05de
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
	st_dpib A, 0xe0
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
;        4. Write 0xe1 to latch
;        5. Wait for SSTAT1 low (Sub-CPU acknowledged)
;        6. Set MSTAT0, send 6-byte header via DMA
;        7. Wait for state transition, send data payload
;        Timeout: 60000 iterations (0xea60) for each wait loop
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
	cp hl, 0xea60
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
	cp wa, 0xc8
	jr c, E1Bulk_Phase2_Delay
	ldada xbc, 1544
	ld xwa, (xbc)
	stda32 1498, xwa
	mrdw5 0x99, 0x04, 0x19, 0xde, 0x05
	calr Audio_DMA_Transfer
	stdi8 1504, 0
	cpdi8 1504, 0
	jr z, E1Bulk_PostTransfer_Delay_Init

E1Bulk_WaitPhase2_Loop:
	cpdi8 1504, 0
	jr nz, E1Bulk_WaitPhase2_Loop

E1Bulk_PostTransfer_Delay_Init:
	lds iz, 0
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
	cp a, 0xe1
	jr nz, INT0_CheckE2Command
	stdi8 1506, 2
	ldada xwa, 1550
	stda32 1494, xwa
	ldc_cr32 xwa, 0x20
	lds wa, 6
	ldc_cr16 wa, 0x40
	lda_dd8l XBC, 0xf0
	ld a, (xbc)
	and a, 0xf8
	or a, 0x6
	ld (xbc), a
	jr INT0_AckAndReturn

INT0_CheckE2Command:
	cp a, 0xe2
	jr nz, INT0_HandleDataCommand
	stdi8 1506, 3
	ldada xwa, 1556
	stda32 1494, xwa
	ldc_cr32 xwa, 0x20
	ldw wa, 0xa
	ldc_cr16 wa, 0x40
	lda_dd8l XBC, 0xf0
	ld a, (xbc)
	and a, 0xf8
	or a, 0x6
	ld (xbc), a
	jr INT0_AckAndReturn

INT0_HandleDataCommand:
	stdi8 1506, 1
	ldada xwa, 1512
	stda32 1494, xwa
	ldc_cr32 xwa, 0x20
	ldda8 a, 1508
	and a, 0x1f
	inc 1, a
	extz wa
	ldc_cr16 wa, 0x40
	lda_dd8l XBC, 0xf0
	ld a, (xbc)
	and a, 0xf8
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
	lda_dd8l XBC, 0xf0
	ld a, (xbc)
	and a, 0xf8
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
	and a, 0x1f
	inc 1, a
	extz wa
	srl c, 5
	extz bc
	sla bc, 2
	lda_24 xde, SeqRingBuf_WriteDispatch_Table
	st_dri3b B, 0x07, 0xe8, 0xe4
	ld xbc, 0x5e8
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
	lda_dd8l XBC, 0xf0
	ld a, (xbc)
	and a, 0xf8
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
	ei	6
	ldada	xwa, 1566
	.byte 0xb0
	inc	6, l
	zcf
	.byte 0xb0, 0xb7
	di
	ldada	xde, 1556
	ld	xwa, (xde)
	ld	bc, (xde+8)
	ld	xde, (xde+4)
	calr	64945
	di
	.byte 0xf0
	jr	-55
	jr	nz, 27
	.byte 0xd8
	pushw	sp
	ld	xwa, 0xf8e362d1
	jr	nz, 6
	incdi16	1, 0xe360
	jr	6
	stdi16	0xe360, 0
	stda16	0xe362, wa
	jr	6
	stdi16	0xe360, 0
	ldda16	wa, 0xe360
	cp	wa, 10
	ret	ule
	stdi16	0xe360, 0
	stdi8	256, 0
	stdi8	1506, 0
	.byte 0xf0
	jr	-71
	incdi8	1, 0xe35e
	ret
	ldda16	de, 1033
	.byte 0xf1
	ldb	w, 6
	dec	6, l
	pop_sr
	lds	hl, 0
	ret
	ld	wa, de
	ldda16	bc, 1033
	sub	bc, wa
	cp	bc, 250
	jr	le, -23
	stdi8	256, 0
	stdi8	1506, 0
	.byte 0xf0
	jr	-71
	.byte 0xf1
	ldb	w, 6
	.byte 0xb7
	incdi8	1, 0xe364
	ldw	hl, 0xffff
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
	bit_dd8 5, 0x1c
	jr z, Flash_IdentifyChip_WaitReady
	ei 6
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	stiw_dri 0xf9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xf0
	ld_sriw WA, (xiz + 0x3232)
	ei 0
	call Get_Region_Code
	cps l, 4
	jr nz, Flash_IdentifyChip_Done
	add xiz, 0x80000
	ei 6
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	stiw_dri 0xf9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xf0
	ld_sriw WA, (xiz + 0x3232)
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
	stiw_dri 0xe9, 0x54, 0x55, 0x55, 0x00
	ldw (xbc), 0x90
	ld wa, (xde)
	ldfr_werp WA, 0xfa
	ld xbc, xde
	ld iz, (xbc + 2)
	ei 0
	cpi_werp 0xfa, 1
	jr z, Flash_IdentifyValidate_CheckDeviceId
	cpi_werp 0xfa, 4
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
	bit_dd8 5, 0x1c
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
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	stiw_dri 0xf9, 0x54, 0x55, 0x55, 0x00
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
	stiw_dri 0xf9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0x80
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	stiw_dri 0xf9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0x10
	call Get_Region_Code
	cps l, 4
	jr nz, Flash_ChipErase_Done
	cp (xsp + 4), 0x1
	jr nz, Flash_ChipErase_Done
	lda_24 xiz, 0x380000
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	stiw_dri 0xf9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0x80
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	stiw_dri 0xf9, 0x54, 0x55, 0x55, 0x00
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
	ld xwa, SendPartDataBlock_Data2_0x0B
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
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	stiw_dri 0xf9, 0x54, 0x55, 0x55, 0x00
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0x80
	ld xwa, xiz
	add xwa, 0xaaaa
	ldw (xwa), 0xaa
	stiw_dri 0xf9, 0x54, 0x55, 0x55, 0x00
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
	lda_24 xwa, 0x300000
	cpdi16_24 0x205e0, 8792
	jr nz, Flash_EraseSector_TopSector
	cp xwa, (xsp + 4)
	jrl nz, FlashOp_Epilogue10
	stiw_dri 0xf9, 0x00, 0x40, 0x30, 0x00
	stiw_dri 0xf9, 0x00, 0x60, 0x30, 0x00
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
	lda_24 xwa, 0x280000
	cpdi16_24 0x205e2, 8875
	jr nz, Flash_EraseSector_Bank2TopSector
	cp xwa, (xsp + 4)
	jr nz, FlashOp_Epilogue10
	stiw_dri 0xf9, 0x00, 0x40, 0x30, 0x00
	stiw_dri 0xf9, 0x00, 0x60, 0x30, 0x00
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
	bit_dd8 5, 0x1c
	jr z, Flash_CheckReady_NotReady
	lds hl, 0
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
	lds wa, 1
	calr Flash_IdentifyChip
	lds wa, 2
	calr Flash_IdentifyChip
	call Get_Region_Code
	cps l, 4
	call_24 nz, TableDataROM_IdentifyChip
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
	st_dpiw DE, 0xe1
	inc 1, de
	cp de, bc
	jr c, Flash_FillBuffer_Loop
	ret

Flash_CopyROMToBuffer:
	ld xbc, xwa
	and xbc, 0xff0000
	ld xwa, 0x69800
	ld xde, 0x8000
	jp Copy_DE_words_from_XBC_to_XWA

Flash_WriteBufferToChip:
	lda xsp, (xsp - 10)
	pushw iz
	ld (xsp + 10), a
	lda_24 xwa, 0x069800
	ld (xsp + 2), xwa
	and xbc, 0xff0000
	ld (xsp + 6), xbc
	lds iz, 0

Flash_WriteBufferToChip_Loop:
	ld a, (xsp + 10)
	extz wa
	ld xbc, (xsp + 6)
	st_dpib B, 0xe5
	ld (xsp + 6), xbc
	ld xbc, xde
	ld xhl, (xsp + 2)
	ld_spiw DE, 0xed
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
	ld xwa, SendPartDataBlock_Data2_0x0B
	and (xsp + 2), xwa
	lds iz, 0

Flash_WriteFromMemory_Loop:
	ld a, (xsp + 10)
	extz wa
	ld xbc, (xsp + 2)
	st_dpib B, 0xe5
	ld (xsp + 2), xbc
	ld xbc, xde
	ld xhl, (xsp + 6)
	ld_spiw DE, 0xed
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
	ldi_werp 0xe6, 0
	lda_24 xde, 0x069800
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
	lds wa, 1
	ld xbc, 0x69800
	ld xde, 0x378700
	calr Flash_EraseSectorAndWrite
	ld xwa, 0x378700
	push xwa
	lds wa, 1
	ld xbc, 0x800000
	ldw de, 0x400
	calr FlashWrite
	lds wa, 1
	jrl Flash_IdentifyChip

TableDataROM_IdentifyChip:
	ld xde, 0x800000

TableDataROM_IdentifyChip_WaitReady:
	bit_dd8 5, 0x1c
	jr z, TableDataROM_IdentifyChip_WaitReady
	ld xbc, xde
	add xbc, 0x15554
	ld xwa, 0xaa00aa
	ld (xbc), xwa
	ld xbc, xde
	add xbc, 0xaaa8
	ld xwa, 0x550055
	ld (xbc), xwa
	ld xbc, xde
	add xbc, 0x15554
	ld xwa, StringData_APCModeNames_0x24F_
	ld (xbc), xwa
	ld_sril XWA, (xde + 0x6464)
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
	ld xwa, 0xaa00aa
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
	bit_dd8 5, 0x1c
	jr z, Flash_ProgramByte_WaitReady
	ei 6
	ld xwa, 0xaa00aa
	st32_24 0x815554, xwa
	ld xwa, 0x550055
	st32_24 0x80aaa8, xwa
	ld xwa, 0xa000a0
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
	ld xwa, 0xaa00aa
	ld (xbc), xwa

	; [0080aaa8h] = 00550055h
	ld xbc, xiz
	add xbc, 0xaaa8
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
	ld xwa, 0xaa00aa
	ld (xbc), xwa

	; [0080aaa8h] = 00550055h
	ld xbc, xiz
	add xbc, 0xaaa8
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
	ld	xiz, 0x800000
	ei	6
	ld	xbc, xiz
	add	xbc, 0x15554
	ld	xwa, 0xaa00aa
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0xaaa8
	ld	xwa, 0x550055
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x15554
	ld	xwa, 0x800080
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0x15554
	ld	xwa, 0xaa00aa
	ld	(xbc), xwa
	ld	xbc, xiz
	add	xbc, 0xaaa8
	ld	xwa, 0x550055
	ld	(xbc), xwa
	ld	xwa, 0x300030
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
	di
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
	bit_dd8 5, 0x1c
	jr z, HDAE5000_Status_NotPresent
	lds hl, 0
	ret

HDAE5000_Status_NotPresent:
	ldw hl, 0xffff
	ret

HDAE5000_Status_DataBlock:
	calr	65155
	calr	65518
	cp	hl, 0xffff
	ret	nz
	calr	65509
	cp	hl, 0xffff
	jr	z, -9
	ret
	dec	4, xsp
	push	xiz
	ld	xwa, 0x80000
	ld	(xsp+4), xwa
	calr	64949
	cp	xhl, 0xffffffff
	jr	nz, 5
	ldw	hl, 0xffff
	jr	65
	calr	65106
	ld	xwa, 0x80000
	ld	xbc, 0x10000
	call	Flash_FillBuffer
	calr	65455
	cp	hl, 0xffff
	jr	nz, 9
	calr	65446
	cp	hl, 0xffff
	jr	z, -9
	lds32	xiz, 0
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe2
	ldw	bc, 1215
	jr	f, -23
	add	(xwa-18), a
	calr	64992
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
	st_dri3b A, 0xed, 0xee, 0x0f

SLIDE_Decompress_4K_FillRing:
	stib_dpi 0xe0, 0x00
	cp xwa, xbc
	jr c, SLIDE_Decompress_4K_FillRing
	ldw bc, 0xfee
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
	or_erpw 0x30, 0x00, 0xff

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
	and bc, 0xfff
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
	ldfr_berp A, 0xf8
	extz iz
	ld wa, iz
	and wa, 0xf0
	sll wa, 4
	ex_werp WA, 0x32
	or_werp WA, 0x32
	ex_werp WA, 0x32
	and iz, 0xf
	inc 2, iz
	lds iy, 0
	cps iz, 0
	jr c, SLIDE_Decompress_4K_Continue

SLIDE_Decompress_4K_CopyLoop:
	ldto_werp WA, 0x32
	add wa, iy
	and wa, 0xfff
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
	and bc, 0xfff
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
	st_dri3b A, 0xed, 0xf6, 0x1f

SLIDE_Decompress_8K_FillRing:
	stib_dpi 0xe0, 0x00
	cp xwa, xbc
	jr c, SLIDE_Decompress_8K_FillRing
	ldw bc, 0x1ff6
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
	or_erpw 0x30, 0x00, 0xff

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
	and bc, 0x1fff
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
	ldfr_berp A, 0xf8
	extz iz
	ld wa, iz
	and wa, 0xf8
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
	and wa, 0x1fff
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
	and bc, 0x1fff
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
	ld xiy, SLIDE_STRING	; "SLIDE"
	lda xix, (xsp + 4)
	lds bc, 3
	ldirw
	pushw 0x5	; string length: 5 bytes
	lda xwa, (xsp + 6)
	push xwa
	push xiz
	call String_Compare
	add xsp, 0xa
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
	ld (xsp + 4), 0xff
	pushw 0x200
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, 0x21
	lds bc, 1
	ld xde, xiz
	calr FDC_ReadSectors
	pushw 0x26	; string length
	pushw 0xe0
	pushw 0x38	; "Technics KN5000 Program  DATA FILE 1/2"
	push xiz
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, DetectDisk_CheckProgram2of2
	ld (xsp + 4), 0x1
	jrl DetectDisk_FreeBufAndReturn

DetectDisk_CheckProgram2of2:
	pushw 0x26	; string length
	pushw 0xe0
	pushw 0x60	; "Technics KN5000 Program  DATA FILE 2/2"
	push xiz
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, DetectDisk_CheckTable1of2
	ld (xsp + 4), 0x2
	jrl DetectDisk_FreeBufAndReturn

DetectDisk_CheckTable1of2:
	pushw 0x26	; string length
	pushw 0xe0
	pushw 0xb0	; "Technics KN5000 Table    DATA FILE 1/2"
	push xiz
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, DetectDisk_CheckTable2of2
	ld (xsp + 4), 0x3
	jrl DetectDisk_FreeBufAndReturn

DetectDisk_CheckTable2of2:
	pushw 0x26	; string length
	pushw 0xe0
	pushw 0xd8	; "Technics KN5000 Table    DATA FILE 2/2"
	push xiz
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, DetectDisk_CheckCmpCustom
	ld (xsp + 4), 0x4
	jr DetectDisk_FreeBufAndReturn

DetectDisk_CheckCmpCustom:
	pushw 0x26	; string length
	pushw 0xe0
	pushw 0x128	; "Technics KN5000 CMPCUSTOMDATA FILE"
	push xiz
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, DetectDisk_CheckHDAEPRG
	ld (xsp + 4), 0x5
	jr DetectDisk_FreeBufAndReturn

DetectDisk_CheckHDAEPRG:
	pushw 0x26	; string length
	pushw 0xe0
	pushw 0x150	; "Technics KN5000 HD-AEPRG DATA FILE"
	push xiz
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, DetectDisk_CheckProgramPCK
	ld (xsp + 4), 0x6
	jr DetectDisk_FreeBufAndReturn

DetectDisk_CheckProgramPCK:
	pushw 0x26	; string length
	pushw 0xe0
	pushw 0x88	; "Technics KN5000 Program  DATA FILE PCK"
	push xiz
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, DetectDisk_CheckTablePCK
	ld (xsp + 4), 0x7
	jr DetectDisk_FreeBufAndReturn

DetectDisk_CheckTablePCK:
	pushw 0x26	; string length
	pushw 0xe0
	pushw 0x100	; "Technics KN5000 Table    DATA FILE PCK"
	push xiz
	call String_Compare
	add xsp, 0xa
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
	ldto_werp WA, 0xe2
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
	ldi_werp 0xfa, 0
	jr FDC_WriteSectors_TrackLoopCheck

FDC_WriteSectors_TrackLoop:
	ld xwa, (xsp + 14)
	st_dpib A, 0xe2
	ld (xsp + 14), xwa
	ld xwa, xbc
	ld xde, (xsp + 10)
	ld_spil XBC, 0xea
	ld (xsp + 10), xde
	call Flash_ProgramByte
	inc1_werp 0xfa

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
	ldi_werp 0xfa, 0

FDC_WriteSectors_FullTrackInner:
	ld xwa, (xsp + 14)
	st_dpib A, 0xe2
	ld (xsp + 14), xwa
	ld xwa, xbc
	ld xde, (xsp + 10)
	ld_spil XBC, 0xea
	ld (xsp + 10), xde
	call Flash_ProgramByte
	inc1_werp 0xfa
	cp_erpw 0xfa, 0x00, 0x09
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
	ldi_werp 0xfa, 0
	jr FDC_WriteSectors_RemainderCheck

FDC_WriteSectors_RemainderLoop:
	ld xwa, (xsp + 14)
	st_dpib A, 0xe2
	ld (xsp + 14), xwa
	ld xwa, xbc
	ld xde, (xsp + 10)
	ld_spil XBC, 0xea
	ld (xsp + 10), xde
	call Flash_ProgramByte
	inc1_werp 0xfa

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
	ldi_werp 0xfa, 0
	jr FDC_WriteCompressed_PartialTrackCheck

FDC_WriteCompressed_PartialTrackLoop:
	ld a, (xsp + 20)
	extz wa
	ld xbc, (xsp + 14)
	st_dpib B, 0xe5
	ld (xsp + 14), xbc
	ld xbc, xde
	ld xhl, (xsp + 10)
	ld_spiw DE, 0xed
	ld (xsp + 10), xhl
	call Flash_ProgramWord
	inc1_werp 0xfa

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
	ldi_werp 0xfa, 0

FDC_WriteCompressed_FullTrackInner:
	ld a, (xsp + 20)
	extz wa
	ld xbc, (xsp + 14)
	st_dpib B, 0xe5
	ld (xsp + 14), xbc
	ld xbc, xde
	ld xhl, (xsp + 10)
	ld_spiw DE, 0xed
	ld (xsp + 10), xhl
	call Flash_ProgramWord
	inc1_werp 0xfa
	cp_erpw 0xfa, 0x00, 0x12
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
	ldi_werp 0xfa, 0
	jr FDC_WriteCompressed_RemainderCheck

FDC_WriteCompressed_RemainderLoop:
	ld a, (xsp + 20)
	extz wa
	ld xbc, (xsp + 14)
	st_dpib B, 0xe5
	ld (xsp + 14), xbc
	ld xbc, xde
	ld xhl, (xsp + 10)
	ld_spiw DE, 0xed
	ld (xsp + 10), xhl
	call Flash_ProgramWord
	inc1_werp 0xfa

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
	cp hl, 0xffff
	jr nz, FlashBurn_Done

FlashBurn_ProgressLoop:
	ldda32 xwa, 1033
	cp xwa, 0x1f4
	jr ule, FlashBurn_CheckDone
	inc 8, iz
	ld wa, iz
	ldw bc, 0xb4
	lds de, 5
	call VRAM_FillRect
	lds32 xwa, 0
	stda32 1033, xwa

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
	cps wa, 0
	jrl lt, SHOW_ILLEGAL_DISK_MESSAGE
	cps wa, 7
	jrl gt, SHOW_ILLEGAL_DISK_MESSAGE
	add wa, wa
	lda_24 xix, HANDLE_UPDATE_OFFSETS
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, HANDLE_UPDATE_FILE_TYPE_ID_001h
	jp_dri 8, 0x07, 0xf0, 0xe0


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
	ld xbc, 0x3e0000
	call Flash_EraseSectorWithBankSelect
	lds wa, 1
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
	ld xwa, 0x186a0
	jr BusyWait_XWA_Cycles

LED_Toggle_Bit2_Loop:
	chgda_24 2, 0x160004
	ld xwa, 0x249f0
	calr BusyWait_XWA_Cycles
	jr LED_Toggle_Bit2_Loop

LED_Toggle_Bit3_Loop:
	chgda_24 3, 0x160004
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
	lds32 xhl, 0
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
	st8_24 0x160000, w
	ld xix, xbc
	ld xiy, 0x3ffff

HDAE5000_ROM_Transfer_WordLoop:
	ld_spiw DE, 0xf1
	cp_spiw DE, 0xed
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
	st_dpib A, 0xe1
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	ld_spiw DE, 0xe1
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
	ld	xwa, 0x800000
	ld	(xsp+8), xwa
	ld	(xsp+12), 0
	ld	a, (xsp+12)
	st8_24	0x160000, a
	lda_24	xwa, 0x280000
	ld	(xsp+4), xwa
	lds32	xiz, 0
	ld	xwa, (xsp+8)
	.byte 0xf5, 0xe2
	ldw	bc, 2239
	jr	f, -23
	.byte 0x88
	ld	xde, (xsp+4)
	.byte 0xe5, 0xea
	ldb	a, 191
	.byte 0x04
	jr	le, 29
	jrl	ugt, -4291
	inc	1, xiz
	cp	xiz, 0x20000
	jr	c, -34
	incm8	1, (xsp+12)
	.byte 0x8f
	incf
	push	xsp
	.byte 0x04
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
	st_dpib A, 0xe2
	ld (xsp + 8), xwa
	ld xwa, xbc
	ld xde, (xsp + 4)
	ld_spil XBC, 0xea
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
	.byte 0xd7
	swi	2
	.byte 0x04, 0xc7
	swi	3
	.byte 0xa8, 0x08, 0xe4
	.long Bitmap_1bit_FlashStatus_Icon
	ldio	237, 0
	ldio	227, 0
	ldio	235, 0
	stdi8	340, 102
	sti8_24	0x160006, 130
	sti8_24	0x160000, 0
	sti8_24	0x160004, 0
	sti8_24	0x160004, 15
	ld	xwa, 0xdbba0
	calr	65042
	sti8_24	0x160004, 0
	ld8_24	a, 0x160002
	extz	wa
	bit	0, wa
	jr	nz, -12
	call	HDAE5000_Detect
	cp	xhl, 0xffffffff
	jr	nz, 8
	.byte 0xf2, 0x04
	nop
	ex_ff
	.byte 0xba, 0xc7
	swi	3
	sub	(xbc-40), xbc
	call	Flash_IdentifyAndValidateChip
	cp	hl, 0xffff
	jr	nz, 10
	.byte 0xf2, 0x04
	nop
	ex_ff
	.byte 0xbb, 0xc7
	swi	3
	.byte 0xa9
	jr	8
	.byte 0xc7
	swi	3
	dec	6, bc
	halt
	.byte 0xd7
	swi	2
	halt
	jr	-2
	sti8_24	0x160004, 0
	ld	xwa, 0x800000
	ld	xbc, 0xa00000
	calr	65060
	or	xhl, xhl
	.byte 0xf2, 0xbb
	push	xiy
	sll	xsp, 242
	nop
	nop
	ldw	wa, 0xe830
	and	(xbc-23), w
	nop
	nop
	rcf
	nop
	calr	65037
	or	xhl, xhl
	jr	z, 6
	lds	wa, 1
	call	Flash_ChipErase
	call	HDAE5000_Status_Check
	cp	hl, 0xffff
	jr	nz, 13
	calr	64920
	call	HDAE5000_Status_Check
	cp	hl, 0xffff
	jr	z, -13
	sti8_24	0x160004, 0
	.byte 0xf2, 0x04
	nop
	ex_ff
	.byte 0xb8
	calr	65155
	.byte 0xf2, 0x04
	nop
	ex_ff
	ld	(xwa), w
	.byte 0xa0
	ld	(xhl+13), 30
	jr	z, -3
	.byte 0xf2, 0x04
	nop
	ex_ff
	.byte 0xb8
	calr	65052
	.byte 0xf2, 0x04
	nop
	ex_ff
	ret	le
	.byte 0x04
	nop
	ex_ff
	.byte 0xb9
	pushw	3
	ld	xwa, 0x800000
	ld	xbc, 0x280000
	lds	de, 0
	calr	64974
	or	xhl, xhl
	.byte 0xf2, 0x90
	popw	wa
	sll	xsp, 11
	.byte 0x01
	nop
	ld	xwa, 0x300000
	ld	xbc, 0x200000
	lds	de, 0
	calr	64949
	or	xhl, xhl
	.byte 0xf2, 0x9f
	popw	wa
	sll	xsp, 242
	nop
	nop
	ex_ff
	nop
	reti
	ld32_24	xwa, 0x2fffc0
	.byte 0xe8
	dec	8, l
	.ascii "kt_f"
	halt
	.byte 0xd7
	swi	2
	halt
	jr	-2
	ei	7
	ld	xwa, Debug_SWI_JumpTable_0x06_
	ldw	ix, 331
	extz	xix
	.byte 0xe9, 0xee
	.long SeqCh_SystemHandlerData
	ld	(xix), 128
	jp	(xwa)
	.byte 0xd7
	swi	2
	halt
	ret

HDAE5000_Init_DetectAndVerify:
	sti8_24 0x160004, 0x00
	call HDAE5000_Detect
	cp xhl, 0xffffffff
	jr nz, HDAE5000_Init_VerifyROM
	setda_24 2, 0x160004

Infinite_Loop_FlashVerifyFail:
	jr Infinite_Loop_FlashVerifyFail

HDAE5000_Init_VerifyROM:
	ld xwa, 0x800000
	ld xbc, 0xa00000
	calr TableData_ROM_Verify
	or xhl, xhl
	jr z, HDAE5000_Init_TransferData
	call HDAE5000_Flash_Verify
	call HDAE5000_Status_Check
	cp hl, 0xffff
	jr nz, HDAE5000_Init_TransferData

HDAE5000_Init_WaitFlashReady:
	calr LED_CyclePattern
	sti8_24 0x160004, 0x00
	call HDAE5000_Status_Check
	cp hl, 0xffff
	jr z, HDAE5000_Init_WaitFlashReady

HDAE5000_Init_TransferData:
	setda_24 0, 0x160004
	calr HDAE5000_TableData_Write
	resda_24 0, 0x160004
	setda_24 1, 0x160004
	pushw 0x7
	ld xwa, 0x800000
	ld xbc, 0x280000
	lds de, 4
	calr HDAE5000_ROM_Transfer
	or xhl, xhl
	call_24 nz, LED_Toggle_Bit2_Loop

HDAE5000_Init_HaltLoop:
	jr HDAE5000_Init_HaltLoop

HDAE5000_Parport_Setup:
	stdi8 340, 102
	sti8_24 0x160006, 0x82
	sti8_24 0x160000, 0x00
	sti8_24 0x160004, 0x00
	sti8_24 0x160004, 0x0f
	ld xwa, 0xdbba0
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
	ldw hl, 0xffff
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
	st_dpib A, 0xe0
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
	st_dpib B, 0xe2
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
	st_dpib A, 0xe1
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
	add xwa, 0xe0000
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
	pushw 0xe0
	pushw 0x188	; "SLIDE"
	push xwa
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr z, LZSS_Decompress_HeaderOK
	ldw hl, 0xffff
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
	cp xwa, 0xfee
	jr c, LZ_Decompress_ClearRing
	ldw (xsp + 10), 0xfee
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
	ldw bc, 0xb4
	lds de, 6
	call VRAM_FillRect
	ld xwa, 0x3e8
	stda32 1598, xwa
	stdi16 1618, 36
	ldi_werp 0xfa, 0

LZ_Decompress_ReadTracks:
	ldda16 xwa, 1618
	extz xwa
	ldw bc, 0x2400
	mul_werp BC, 0xfa
	ld xde, 0x69800
	add xde, xbc
	ldw bc, 0x12
	calr FDC_ReadSectors
	adddi16 1618, 18
	inc1_werp 0xfa
	cpi_werp 0xfa, 4
	jr c, LZ_Decompress_ReadTracks
	ldi_werp 0xfa, 0

LZ_Decompress_ReadSizeField:
	calr Parport_ReadNextByte
	inc1_werp 0xfa
	cp_erpw 0xfa, 0x08, 0x00
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
	incm 1, (xsp + 10)
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
	incm 2, (xsp + 8)
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
	incm 1, (xsp + 10)
	extz xbc
	add xbc, (xsp + 12)
	ldto_berp A, 0xf8
	ld (xbc), a
	andmi16 (xsp + 10), 0xfff
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
	push_werp 0xfa
	call Check_for_Floppy_Disk_Change
	cps l, 0
	jrl z, flash_update__not_today
	calr FDC_InitRecalibrate
	calr Detect_Disk_Type
	ldfr_berp L, 0xfb
	call Get_Region_Code
	cps l, 4
	jr z, Flash_CheckAndValidate
	call HDAE5000_Detect
	cp xhl, 0xffffffff
	jr z, Flash_CheckAndValidate
	cpi_berp 0xfb, 6	; Is it "HD-AEPRG DATA FILE"?
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
	lds wa, 2
	call Flash_IdentifyAndValidateChip
	cp hl, 0xffff
	jr z, flash_update__not_today
	cpi_berp 0xfb, 6	; Is it "HD-AEPRG DATA FILE"?
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
	pop_werp 0xfa
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
	lds iz, 0

DrawBitmap_RowLoop:
	ld wa, iz
	extz xwa
	div wa, 0x1c	; 28 bytes = 224 pixels de largura da imagem a ser desenhada
	ldto_werp WA, 0xe2
	cps wa, 0
	jr nz, DrawBitmap_CheckNewRow
	ld iy, hl	; IY = coordanada X do canto esquerdo da imagem a ser desenhada
	dec 1, ix

DrawBitmap_CheckNewRow:
	ldi_werp 0xee, 0

DrawBitmap_BitLoop:
	ld de, iz
	extz xde
	add xde, (xsp + 2)
	ldada xwa, 0xe36a	; table of bit masks (equivalent to 1044h on boot "table_data" rom)
	ldto_werp BC, 0xee
	extz xbc
	add xbc, xwa	; indexing bit masks with value of QHL
	ld a, (xbc)
	and a, (xde)	; here XDE points at one of the bytes of the image we're drawing and we select the bit we need
	ldfr_berp A, 0xf2
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
	cpi_berp 0xf2, 0
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
	inc1_werp 0xee
	cp_erpw 0xee, 0x08, 0x00
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
	addmi16 (xsp + 4), 0xc	; End Y = start + 12
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
