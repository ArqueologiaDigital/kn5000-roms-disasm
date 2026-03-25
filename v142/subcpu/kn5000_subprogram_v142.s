; =============================================================================
; KN5000 Sub-CPU Payload ROM (192KB)
; =============================================================================

; --- Interrupt Vector Table & Handlers ---
	.include "subcpu_vectors.s"

; --- Data Tables, Constants & Configuration ---
	.include "subcpu_data_tables.s"

; =============================================================================
; Core: RESET, Initialization, Main Loop, Voice Management,
;       Tone Generation, DSP Protocol
; =============================================================================
RESET:	; 01F924
	stdi8 256, 0
	stdi8 258, 0
	stdi8 265, 0
	stdi8 264, 0
	ldio 0xF8, 0x00
	stdi8 272, 0
	stdi8 273, 177
	stdi8 266, 4
	ldio 0x07, 0xFF
	ldio 0x0B, 0xFF
	ldio 0x0F, 0xFF
	ldio 0x18, 0xFF
	ldio 0x1B, 0x7F
	ldio 0x1A, 0x80
	ldio 0x1C, 0xFF
	ldio 0x1F, 0x07
	ldio 0x1E, 0x78
	ldio 0x20, 0x3B
	ldio 0x23, 0x3F
	ldio 0x22, 0xFF
	ldio 0x28, 0xFF
	ldio 0x2B, 0x08
	ldio 0x2C, 0xFF
	ldio 0x2F, 0x1F
	ldio 0x30, 0x03
	ldio 0x33, 0x00
	ldio 0x32, 0x02
	ldio 0x34, 0xFF
	ldio 0x37, 0x00
	ldio 0x36, 0x63
	ldio 0x38, 0xFE
	ldio 0x3B, 0x00
	ldio 0x3A, 0x71
	ldio 0x3C, 0xFF
	ldio 0x3F, 0x70	;
	ldio 0x3E, 0x15
	ldio 0x44, 0xFF
	ldio 0x47, 0x18
	ldio 0x46, 0x07
	ldio 0x68, 0x00
	ldio 0x6A, 0xFF
	ldio 0x84, 0x1D
	ldio 0x85, 0x1D
	ldio 0x82, 0x00
	ldio 0x88, 0x0A
	ldio 0x89, 0x14
	ldio 0x8A, 0x40
	ldio 0x8B, 0x20
	ldio 0x81, 0x00
	set_dd8 1, 0x80
	ldio 0x98, 0x05
	ldio 0x99, 0x00
	ldio 0x9F, 0x00
	ldio 0x9E, 0x00
	set_dd8 7, 0x9E	; prescaler: run
	stdi8 323, 16
	stdi8 327, 17
	stdi8 331, 255
	stdi8 335, 0
	stdi8 339, 18
	stdi8 343, 19
	stdi8 322, 7
	stdi8 326, 3
	stdi8 330, 1
	stdi8 334, 31
	stdi8 338, 1
	stdi8 342, 1
	ldio 0xD2, 0x01
	ldio 0xD1, 0x00
	and_sd8b_im 0xD3, 0xCF
	and_sd8b_im 0xD3, 0xF0
	ldio 0xD6, 0x29	;receive-enable | 8-bit uart mode | serial transfer clock: baud-rate generator
	lda_dd8l XBC, 0xD6
	ld a, (xbc)
	and a, 0xFC
	set 0, a
	ld (xbc), a
	ldio 0xD5, 0x00	; parity addition: disable
	and_sd8b_im 0xD7, 0xCF	; T0 (4/fc)
	and_sd8b_im 0xD7, 0xF0	; divide by 16
	stdi8 304, 255
	stdi8 305, 255
	stdi8 306, 3
	stdi8 357, 113
	stdi8 354, 139
	stdi8 355, 88
	resda 4, 358
	stdi8 320, 85
	stdi8 324, 85
	stdi8 328, 34
	stdi8 332, 34
	stdi8 336, 98
	stdi8 340, 102
	stdi8 321, 129
	stdi8 325, 129
	stdi8 329, 192
	stdi8 333, 138
	stdi8 337, 128
	stdi8 341, 129
	ldio 0xF6, 0x00
	lds32 xwa, 0
	stda32 4160, xwa
	calr MemClear_DRAM_And_ExtRAM

PostReset_InitAudio:
	lda_24 xwa, 0x04069a
	ld xsp, xwa
	call TaskSched_Init
	lda_dd8l XBC, 0xE4
	ld a, (xbc)
	and a, 0x8F
	or a, 0x30
	ld (xbc), a
	calr Audio_InitRingBuffers
	ei 0
	stdi16 4156, 0
	jr __jrt_nop_01FACB
__jrt_nop_01FACB:

; ============================================================================
; AUDIO SYSTEM INITIALIZATION
; Main initialization routine for all audio subsystems:
;   - Inter-CPU communication setup
;   - Serial port ring buffers
;   - DSP chip configuration (dual DSPs at 0x00130000)
;   - Tone generator initialization (at 0x00110000)
; ============================================================================
Audio_System_Init:	; 01FACBh
	pushw iz
	call InterCPU_Latch_Setup	; Setup inter-CPU comms via latches
	call INIT_RING_BUFFERS	; Initialize serial port #1 ring buffers
	call DSP_System_Init	; Initialize DSP state buffers, toggle reset signals
	call DSP2_Init	; Initialize DSP2 (second DSP chip)
	call DSP_Init_Channels	; Write channel config to DSP at 0x00130000
	call ToneGen_Init	; Initialize tone generator at 0x00110000
	ei 0	; Enable interrupts

Audio_Main_Loop:
	bitda 5, 4158
	jr z, AudioLoop_CheckWatchdog
	resda 5, 4158

AudioLoop_CheckWatchdog:
	ldda32 xwa, 4160
	cp xwa, 0x3E8
	jr ule, AudioLoop_CheckPeriodicReinit
	set_dd8 0, 0x38	; unmute (?) (here I'm assuming "MUTE" it is an active low signal)

AudioLoop_CheckPeriodicReinit:
	bitda 1, 4158
	jr z, AudioLoop_CallProcessors
	resda 1, 4158
	call Cmd_Check_E2_Pending
	call Audio_Process_Init
	ldw_d16 xwa, 61458
	ld bc, wa
	inc 1, wa
	stda16 61458, xwa
	cp bc, 0xA
	jr lt, AudioLoop_DecrementDelay
	stdi16 61458, 0

AudioLoop_DecrementDelay:
	cps iz, 0
	jr z, AudioLoop_CallProcessors
	dec 1, iz

AudioLoop_CallProcessors:
	call ToneGen_Process_Notes
	call MIDI_Dispatch
	call Audio_Process_DSP
	call Audio_Process_Final
	jr Audio_Main_Loop


Timer_AudioTick_Handler:
	pushw bc
	push xwa
	push xix
	lds32 xwa, 1
	adddm32 4160, xwa
	ldb_d8 a, 61460
	ld c, a
	inc 1, a
	stb_d8 61460, a
	extz bc
	cps bc, 0
	jr mi, AudioTick_Done
	cps bc, 5
	jr gt, AudioTick_Done
	add bc, bc
	lda_24 xix, 0x00f460
	ldw_sri BC, 0x07, 0xF0, 0xE4
	lda_24 xix, 0x01fb76
	jp_ind 8, 0x07, 0xF0, 0xE4


Audio_PlayNote_Variant_1:
	setda 4, 4158
	ldb a, 0x1
	jr AudioTick_StoreTick

Audio_PlayNote_Variant_2:
	ldb a, 0x3
	jr AudioTick_StoreTick

Audio_PlayNote_Variant_3:
	ldb a, 0x2
	jr AudioTick_StoreTick

AudioTick_Variant_4:
	setda 4, 4158
	ldb a, 0x0
	jr AudioTick_StoreTick

AudioTick_Variant_5:
	ldb a, 0x3

AudioTick_StoreTick:
	scf
	stcfa_dd16 0x3E, 0x10
	jr AudioTick_Done

AudioTick_Variant_6:
	setda 2, 4158
	stdi8 61460, 0
	ldb_d8 a, 61462
	inc 1, a
	stb_d8 61462, a
	cp a, 0x8
	jr c, AudioTick_Done
	setda 5, 4158
	stdi8 61462, 0

AudioTick_Done:
	pop xix
	pop xwa
	popw bc
	reti


EMPTY_HANDLER:	; 01FBBC
	reti


EMPTY_HANDLER_WITH_RESET:	; 01FBBD
	jrl RESET
	reti


PrevBank_RegHelper:
	push qiz
	cpib_da	16776942, 255
	jr	nz, 36
	ldib_erp	251, 0
	stb_erp	a, 251
	extz	wa
	stb_erp	c, 251
	extz	bc
	sla	bc, 2
	extz	xbc
	add	xbc, 16776944
	call	130270
	incb_erp	251, 1
	cpib_erp	251, 4
	jr	c, 16777183
	pop qiz
	ret


MUTE_AND_HALT:	; 01FBF4
	res_dd8 0, 0x38	; mute (?) (here I'm assuming "MUTE" it is an active low signal)
	halt


Timer_StatusHelper:
	jr	t, 16777213
	ldb_d8	l, 4154
	extz	hl
	ret


MemClear_DRAM_And_ExtRAM:
	ld xde, 0x3EE76
	ld xbc, 0x66F2
	ld ix, bc
	srl xbc, 1
	jr z, MemClear_DRAM_OddByte
	ld xhl, xde
	stiw_dsp 0xE9, 0x00, 0x00
	dec 1, xbc
	or xbc, xbc
	jr z, MemClear_DRAM_OddByte
	ldirw93
	cpiw_erp 0xE6, 0
	jr z, MemClear_DRAM_OddByte
	stw_erp WA, 0xE6

MemClear_DRAM_BulkLoop:
	ldirw93
	djnz xwa, MemClear_DRAM_BulkLoop

MemClear_DRAM_OddByte:
	bit 0, ix
	jr z, MemClear_ExtRAM
	ld (xde), 0x0

MemClear_ExtRAM:
	ld xde, 0x600
	ld xbc, 0x44CB
	ld ix, bc
	srl xbc, 1
	jr z, MemClear_ExtRAM_OddByte
	ld xhl, xde
	stiw_dsp 0xE9, 0x00, 0x00
	dec 1, xbc
	or xbc, xbc
	jr z, MemClear_ExtRAM_OddByte
	ldirw93
	cpiw_erp 0xE6, 0
	jr z, MemClear_ExtRAM_OddByte
	stw_erp WA, 0xE6

MemClear_ExtRAM_BulkLoop:
	ldirw93
	djnz xwa, MemClear_ExtRAM_BulkLoop

MemClear_ExtRAM_OddByte:
	bit 0, ix
	jr z, MemClear_ExtRAM_Finish
	ld (xde), 0x0

MemClear_ExtRAM_Finish:
	jrl PostReset_InitAudio
	ret


Const_0x0E:
	.byte 0x0e


Audio_InitRingBuffers:
	call RingBuf_Init_1K
	call RingBuf_Init_256
	jp RingBuf_Init_512


Audio_CmdHandler_20_3F:
	lds hl, 0
	ret

Audio_CmdHandler_40_5F:
	ld c, (xsp + 4)
	ld a, c
	dec 1, c
	cps a, 0
	jr z, AudioCmd_40_5F_Done

AudioCmd_40_5F_SkipLoop:
	ld a, c
	dec 1, c
	cps a, 0
	jr nz, AudioCmd_40_5F_SkipLoop

AudioCmd_40_5F_Done:
	lds hl, 0
	ret

; ----------------------------------------------------------------------------
; DSP_Init_Channels - Initialize DSP channel configuration
; Entry: None
; Exit:  None
; Notes: Writes test pattern 0x5A5A5A5A to 4 channels via DSP_Write_Channel
;        Then initializes 4 channel base registers at 0x00130000
;        Memory-mapped DSP register space at 0x00130000
; ----------------------------------------------------------------------------
DSP_Init_Channels:	; 01FC95h
	link32 0xEE, 0x0C, 0xF8, 0xFF
	xor xwa, xwa
	ld xwa, 0x5A5A5A5A	; Test pattern
	ld (xiz - 8), xwa	; Local buffer[0-3]
	ld (xiz - 4), xwa	; Local buffer[4-7]
	lda xwa, (xiz - 8)	; Pointer to test data
	push xwa
	lds bc, 0	; Channel 0
	calr DSP_Write_Channel
	pop xwa
	push xwa
	lds bc, 1	; Channel 1
	calr DSP_Write_Channel
	pop xwa
	push xwa
	lds bc, 2	; Channel 2
	calr DSP_Write_Channel
	pop xwa
	push xwa
	lds bc, 3	; Channel 3
	calr DSP_Write_Channel
	pop xwa
	ld xbc, 0x130000	; DSP register base
	ld xwa, 0x101001F	; Initial channel config
	ldb d, 0x4	; 4 channels

DSP_Init_Channels_Loop:
	ld w, a
	ld (xbc), xwa	; Write to DSP register
	add a, 0x20	; Next channel (0x20 spacing)
	djnz8 d, DSP_Init_Channels_Loop
	unlk32 xiz
	ret

; ----------------------------------------------------------------------------
; DSP_Write_Channel - Write 8 bytes of config data to a DSP channel
; Entry: XWA = pointer to 8 bytes of channel data
;        BC  = channel number (0-3)
; Exit:  None
; Notes: Calculates channel register address from channel number
;        Writes 8 sequential bytes to DSP at 0x00130000 + offset
; ----------------------------------------------------------------------------
DSP_Write_Channel:	; 01FCDEh
	pushw de
	sll a, 5	; Channel * 32 (register spacing)
	set 4, a	; Add 0x10 offset
	ld xhl, 0x130000	; DSP register base
	ldb d, 0x8	; 8 bytes per channel

DSP_Write_Channel_Loop:
	ld (xhl), a	; Write register address
	ldb_spi E, 0xE4	; Get next data byte
	ld (xhl + 2), e	; Write data value
	inc 1, a	; Next register
	djnz8 d, DSP_Write_Channel_Loop
	popw de
	ret


; ----------------------------------------------------------------------------
; DSP_WriteAllChannelRegs - Write register data to all 4 DSP channels
; Entry: XBC/XDE = channel data, prevbank QBC/QDE = additional data
; Notes: Calls DSP_WriteChannelRegs_Inner for channels 0-3
;        Each call writes 8 sequential DSP registers via 0x130000
; ----------------------------------------------------------------------------
DSP_WriteAllChannelRegs:
	push xbc
	push xde
	pushw 1				; Channel 1
	calr DSP_WriteChannelRegs_Inner
	ld xbc, (xsp + 10)		; Reload saved XBC
	ld xde, xiz
	pushw 0				; Channel 0
	calr DSP_WriteChannelRegs_Inner
	ld xbc, xwa
	ld xde, xhl
	pushw 2				; Channel 2
	calr DSP_WriteChannelRegs_Inner
	ld xbc, xix
	ld xde, xiy
	pushw 3				; Channel 3
	calr DSP_WriteChannelRegs_Inner
	inc 8, xsp			; Clean 4x pushw from stack
	pop xde
	pop xbc
	ret

; ----------------------------------------------------------------------------
; DSP_WriteChannelRegs_Inner - Write 8 register values to one DSP channel
; Entry: Stack+12 = channel number (0-3)
;        BC = data bytes 0-1, DE = data bytes 4-5
;        Prevbank QBC = data bytes 2-3, prevbank QDE = data bytes 6-7
; Notes: Register address = channel * 32 + 0x10
;        Writes via memory-mapped DSP I/O: addr to (xiy), data to (xiy+2)
; ----------------------------------------------------------------------------
DSP_WriteChannelRegs_Inner:
	push xiy
	pushw wa
	pushw bc
	ld a, (xsp + 12)		; Channel number
	sll a, 5			; * 32
	set 4, a			; + 0x10
	ld xiy, 0x130000		; DSP register base
	ld (xiy), a			; Reg addr [0]
	ld (xiy + 2), c			; Write data C
	inc 1, a
	ld (xiy), a			; Reg addr [1]
	ld (xiy + 2), b			; Write data B
	inc 1, a
	ld (xiy), a			; Reg addr [2]
	ld	bc, qbc
	ld (xiy + 2), c			; Write prevbank C
	inc 1, a
	ld (xiy), a			; Reg addr [3]
	ld (xiy + 2), b			; Write prevbank B
	inc 1, a
	ld (xiy), a			; Reg addr [4]
	ld (xiy + 2), e			; Write data E
	inc 1, a
	ld (xiy), a			; Reg addr [5]
	ld (xiy + 2), d			; Write data D
	inc 1, a
	ld (xiy), a			; Reg addr [6]
	ld	bc, qde
	ld (xiy + 2), c			; Write prevbank DE.low
	inc 1, a
	ld (xiy), a			; Reg addr [7]
	ld (xiy + 2), b			; Write prevbank DE.high
	popw bc
	popw wa
	pop xiy
	ret

; ----------------------------------------------------------------------------
; DSP_BlockCopyWords - Block copy words from (XHL) to destination
; Entry: XWA = dest base (saved to XIX), XBC = src base (saved to XIY)
;        DE = source reg, BC (after ld) = word count for ldirw
; Notes: ldirw copies BC words from (XHL+) to (XIX+)
; ----------------------------------------------------------------------------
DSP_BlockCopyWords:
	ld xix, xwa
	ld xiy, xbc
	ld bc, de
	ldirw				; Block transfer: (XHL+) -> (XIX+), BC words
	ret

; ----------------------------------------------------------------------------
; DSP_FillMemWords - Fill memory with word value
; Entry: XWA = dest pointer, BC = fill value, DE = count
; Notes: ld (xwa+),bc stores BC then increments XWA
; ----------------------------------------------------------------------------
DSP_FillMemWords:
	stw_dpi	bc, 225
	djnz16 de, DSP_FillMemWords
	ret

; ----------------------------------------------------------------------------
; DSP_ChecksumRange - Compute checksum of 32-bit words in memory range
; Entry: XWA = start address, XBC = byte count
; Exit:  HL = one's complement checksum
; Notes: Sums all 32-bit values, then complements result
; ----------------------------------------------------------------------------
DSP_ChecksumRange:
	xor xhl, xhl			; Accumulator = 0
	extz xbc			; Zero-extend count
	add xbc, xwa			; XBC = end address
DSP_ChecksumRange_Loop:
	.byte 0xe5, 0xe2, 0x83		; add xhl, (xwa+)  (add + auto-increment)
	cp xwa, xbc			; Reached end?
	jr lt, DSP_ChecksumRange_Loop
	cpl hl				; One's complement
	ret

; DSP channel configuration data table (42 bytes)
DSP_ChannelConfigTable:
	.byte 0xb1, 0xfa, 0x01, 0x00
	.byte 0x9a, 0x06, 0x04, 0x00, 0x00, 0x88, 0x03, 0x00
	.byte 0x6f, 0xfc, 0x01, 0x00
	.byte 0x20, 0x0c, 0x04, 0x00, 0x00, 0x88, 0x01, 0x00
	.byte 0x27, 0x63, 0x03, 0x00
	.byte 0x9c, 0x0a, 0x04, 0x00, 0x00, 0x88, 0x03, 0x00
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01

Task_DequeueDispatch_Prio3:
	ldb a, 0x3
	jrl TaskQueue_Dequeue
	ret


INT16_TaskSwitch_Handler:
	incdi16 1, 4306
	incdi8 1, 4165
	pushw wa
	pushw bc
	calr Task_DequeueDispatch_Prio3
	popw bc
	popw wa
	jrl TaskSwitch_Countdown

TaskSched_Init:
	ld xsp, 0x40B1E
	xor wa, wa
	stda16 4166, xwa
	inc 1, wa
	ldc_cr16 wa, 0x7C
	stda16 4306, xwa
	ldw hl, 0x106C
	extz xhl
	lds de, 4
	ldb b, 0x3

TaskSched_Init_QueueHeaders:
	ld ix, hl
	stw_dpi IX, 0xED
	stw_dpi IX, 0xED
	djnz8 b, TaskSched_Init_QueueHeaders
	ldw ix, 0x1048
	extz xix
	ldb b, 0x3
	ldb a, 0x0

TaskSched_Init_TaskDescriptors:
	ld (xix + 9), a
	ld (xix + 10), 0x0
	ld (xix + 11), 0x0
	add ix, 0xC
	djnz8 b, TaskSched_Init_TaskDescriptors
	ldw ix, 0x10CA
	extz xix
	ldb b, 0x1
	ld xwa, 0xFFFFFFFF

TaskSched_Init_FreeList_A:
	ld (xix + 4), xwa
	add ix, 0x8
	djnz8 b, TaskSched_Init_FreeList_A
	ld xhl, 0x1FDBC
	ldw de, 0x1080
	extz xde
	lds bc, 2
	ldir83
	ldw hl, 0x1078
	extz xhl
	ldb b, 0x2

TaskSched_Init_QueueGroup_B:
	ld ix, hl
	stw_dpi IX, 0xED
	stw_dpi IX, 0xED
	djnz8 b, TaskSched_Init_QueueGroup_B
	ld xhl, 0x1FDBE
	ldw de, 0x1092
	extz xde
	lds bc, 4
	ldir83
	ldw hl, 0x1082
	extz xhl
	ldb b, 0x4

TaskSched_Init_QueueGroup_C:
	ld ix, hl
	stw_dpi IX, 0xED
	stw_dpi IX, 0xED
	djnz8 b, TaskSched_Init_QueueGroup_C
	ldw hl, 0x10A6
	extz xhl
	ldb b, 0x4
	ld xwa, 0xFFFFFFFF

TaskSched_Init_FreeList_B:
	ld (xhl + 4), xwa
	add hl, 0x8
	djnz8 b, TaskSched_Init_FreeList_B
	ldw iy, 0x10C6
	extz xiy
	ld (xiy + 256), iy
	ld (xiy + 2), iy
	ldw ix, 0x10A6
	ldb b, 0x4

TaskSched_Init_LinkFreeNodes:
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	add ix, 0x8
	djnz8 b, TaskSched_Init_LinkFreeNodes
	ldw hl, 0x1096
	extz xhl
	ldb b, 0x2

TaskSched_Init_QueueGroup_D:
	ld ix, hl
	stw_dpi IX, 0xED
	stw_dpi IX, 0xED
	djnz8 b, TaskSched_Init_QueueGroup_D
	ldw hl, 0x109E
	extz xhl
	ldb b, 0x2

TaskSched_Init_QueueGroup_E:
	ld ix, hl
	stw_dpi IX, 0xED
	stw_dpi IX, 0xED
	djnz8 b, TaskSched_Init_QueueGroup_E
	ld xwa, 0x1FEDF
	jr TaskSched_ConfigAndDispatch

TaskSched_Init_ConfigData:
	.byte 0x01, 0x00, 0x01, 0x00, 0xc7, 0xfd, 0x01, 0x00

TaskSched_ConfigAndDispatch:
	call Task_ConfigTimer
	calr IntMask_ClearBit3
	ldio 0x8B, 0x1D
	ld_sd8b A, 0xE5
	and a, 0xF
	or a, 0x20
	st_dd8b A, 0xE5
	calr IntMask_SetBit3
	ldb a, 0x1
	calr TaskSched_SpawnTask
	ei 6
	stdi8 4164, 0
	xor wa, wa
	ldc_cr16 wa, 0x7C
	stda16 4306, xwa
	jrl TaskSched_Dispatch

TaskSched_Halt:
	ei 0
	stdi8 305, 255

TaskSched_HaltLoop:
	jr TaskSched_HaltLoop

TaskSched_Dispatch:
	stdi8 305, 0
	ldw_d16 xwa, 4306
	or wa, wa
	jr nz, TaskSched_ContextRestore
	xor wa, wa
	cpdm16 4166, xwa
	jr z, TaskSched_Dispatch_ScanQueues
	ldw_d16 xiy, 4166
	extz xiy
	ld (xiy + 4), xsp
	ld xsp, 0x40B1E
	xor wa, wa
	stda16 4166, xwa

TaskSched_Dispatch_ScanQueues:
	ldb b, 0x3
	ldw ix, 0x106C
	extz xix

TaskSched_Dispatch_ScanLoop:
	ld hl, (xix + 256)
	cp hl, ix
	jr nz, TaskSched_Dispatch_SwitchTo
	inc 4, ix
	djnz8 b, TaskSched_Dispatch_ScanLoop
	jr TaskSched_Halt

TaskSched_Dispatch_SwitchTo:
	stda16 4166, xhl
	extz xhl
	ld a, (xhl + 11)
	sll a, 5
	stb_d8 305, a
	ld xsp, (xhl + 4)

TaskSched_ContextRestore:
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xwa
	pop xhl
	pop	sr
	ret

TaskList_Operations_Opaque:
	.byte 0xd1, 0xd2, 0x10, 0x20, 0xd8, 0x61, 0xf1, 0xd2
	.byte 0x10, 0x50, 0xd8, 0x2e, 0x7c, 0x06, 0x00, 0x34
	.byte 0xca, 0x10, 0xec, 0x12, 0x22, 0x01, 0xac, 0x04
	.byte 0x20, 0xe8, 0xcf, 0xff, 0xff, 0xff, 0xff, 0x66
	.byte 0x0c, 0x9c, 0x00, 0x20, 0xd8, 0x69, 0xbc, 0x00
	.byte 0x50, 0xd8, 0xe0, 0x66, 0x17, 0xdc, 0xc8, 0x08
	.byte 0x00, 0xca, 0x1c, 0xe2, 0x06, 0x06, 0xd1, 0xd2
	.byte 0x10, 0x20, 0xd8, 0x69, 0xf1, 0xd2, 0x10, 0x50
	.byte 0xd8, 0x2e, 0x7c, 0x0e, 0x9c, 0x02, 0x20, 0xbc
	.byte 0x00, 0x50, 0xf2, 0xa8, 0xff, 0x01, 0x30, 0x38
	.byte 0xac, 0x04, 0x20, 0xb0, 0xd8

TaskSwitch_Countdown:
	pushw wa
	ldw_d16 xwa, 4306
	cps wa, 1
	jr z, TaskSwitch_Expired
	dec 1, wa
	stda16 4306, xwa
	ldc_cr16 wa, 0x7C
	popw wa
	reti

TaskSwitch_Expired:
	xor wa, wa
	stda16 4306, xwa
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

TaskSched_SpawnTask:
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
	ldb l, 0xC
	mul8rr l, a
	extz xhl
	add xhl, 0x1FD8C
	ldb c, 0xC
	mul8rr c, a
	add bc, 0x103C
	extz xbc
	ld xix, xbc
	ld a, (xix + 9)
	cps a, 0
	jrl nz, TaskSched_ContextRestore
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
	add wa, 0x1068
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
	ld xsp, 0x40B1E
	ldw_d16 xix, 4166
	extz xix
	ld (xix + 9), 0x0
	ld (xix + 10), 0x0
	xor wa, wa
	stda16 4166, xwa
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	jrl TaskSched_Dispatch
	ldw_d16 xhl, 4306
	or hl, hl
	jr nz, TaskSched_ReturnZero
	push xix
	ldw_d16 xix, 4166
	extz xix
	ld l, (xix + 11)
	extz hl
	pop xix
	ret

TaskSched_ReturnZero:
	xor hl, hl
	ret

TaskSched_PreemptiveYield:
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
	add wa, 0x1068
	ld iy, wa
	extz xiy
	ld ix, (xiy + 256)
	cp ix, (xiy + 2)
	jrl z, TaskSched_ContextRestore
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

TaskQueue_Dequeue:
	push xwa
	push xix
	push xiy
	push xhl
	sll a, 2
	extz wa
	add wa, 0x1068
	ld iy, wa
	extz xiy
	ld ix, (xiy + 256)
	cp ix, (xiy + 2)
	jr z, TaskQueue_Dequeue_Return
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

TaskQueue_Dequeue_Return:
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

TaskQueue_Operations_Opaque:
	.byte 0x02, 0x06, 0x06
	.byte 0x3b, 0x38, 0x39, 0x3a, 0x3c
	.byte 0x3d, 0x3e, 0xd1, 0x46, 0x10, 0x24, 0xec, 0x12
	.byte 0x8c, 0x0a, 0x21, 0xc9, 0xd8, 0x6e, 0x19, 0xec
	.byte 0x12, 0xe8, 0xd0, 0xeb, 0xd3, 0x9c, 0x00, 0x20
	.byte 0x9c, 0x02, 0x23, 0xbb, 0x00, 0x50, 0xb8, 0x02
	.byte 0x53, 0xbc, 0x09, 0x00, 0x03, 0x78, 0xa4, 0xfd
	.byte 0xc9, 0x69, 0xbc, 0x0a, 0x41, 0x78, 0xed, 0xfd
	.byte 0x02, 0x06, 0x06
	.byte 0x3b, 0x38, 0x39, 0x3a, 0x3c
	.byte 0x3d, 0x3e, 0xc9, 0x08, 0x0c, 0xd8, 0xc8, 0x3c
	.byte 0x10, 0xd8, 0x8c, 0xec, 0x12, 0x8c, 0x09, 0x3f
	.byte 0x03, 0x6e, 0x29, 0xbc, 0x09, 0x00, 0x04, 0x8c
	.byte 0x08, 0x21, 0xc9, 0xee, 0x02, 0xd8, 0x12, 0xd8
	.byte 0xc8, 0x68, 0x10, 0xd8, 0x8d, 0xec, 0x12, 0xed
	.byte 0x12, 0xe8, 0xd0, 0xbc, 0x00, 0x55, 0x9d, 0x02
	.byte 0x20, 0xbc, 0x02, 0x50, 0xb0, 0x54, 0xbd, 0x02
	.byte 0x54, 0x78, 0x58, 0xfd, 0x8c, 0x0a, 0x61, 0x78
	.byte 0x52, 0xfd, 0x38, 0x3c, 0x3d, 0x02, 0x06, 0x06
	.byte 0xc9, 0x08, 0x0c, 0xd8, 0xc8, 0x3c, 0x10, 0xd8
	.byte 0x8c, 0xec, 0x12, 0x8c, 0x09, 0x3f, 0x03, 0x6e
	.byte 0x2b, 0xbc, 0x09, 0x00, 0x04, 0x8c, 0x08, 0x21
	.byte 0xc9, 0xee, 0x02, 0xd8, 0x12, 0xd8, 0xc8, 0x68
	.byte 0x10, 0xd8, 0x8d, 0xec, 0x12, 0xed, 0x12, 0xe8
	.byte 0xd0, 0xbc, 0x00, 0x55, 0x9d, 0x02, 0x20, 0xbc
	.byte 0x02, 0x50, 0xb0, 0x54, 0xbd, 0x02, 0x54, 0x03
	.byte 0x5d, 0x5c, 0x58, 0x0e, 0x8c, 0x0a, 0x61, 0x68
	.byte 0xf6, 0x02, 0x06, 0x06
	.byte 0x3b, 0x38, 0x39, 0x3a
	.byte 0x3c, 0x3d, 0x3e, 0xc9, 0x08, 0x0c, 0xd8, 0xc8
	.byte 0x3c, 0x10, 0xd8, 0x8c, 0xec, 0x12, 0x8c, 0x0a
	.byte 0x27, 0xbc, 0x0a, 0x00, 0x00, 0x78, 0x3d, 0xfd
	.byte 0x02, 0x06, 0x06
	.byte 0x3b, 0x38, 0x39, 0x3a, 0x3c
	.byte 0x3d, 0x3e, 0xc9, 0x8f, 0xc9, 0xee, 0x02, 0xd8
	.byte 0x12, 0xd8, 0xc8, 0x74, 0x10, 0xd8, 0x8d, 0xed
	.byte 0x12, 0x9d, 0x00, 0x24, 0xdd, 0xf4, 0x6e, 0x0d
	.byte 0xdb, 0x12, 0xdb, 0xc8, 0x7f, 0x10, 0xeb, 0x12
	.byte 0xb3, 0xb8, 0x78, 0x10, 0xfd, 0xec, 0x12, 0xe8
	.byte 0xd0, 0xeb, 0xd3, 0x9c, 0x00, 0x20, 0x9c, 0x02
	.byte 0x23, 0xbb, 0x00, 0x50, 0xb8, 0x02, 0x53, 0xbc
	.byte 0x09, 0x00, 0x04, 0x8c, 0x08, 0x21, 0xc9, 0xee
	.byte 0x02, 0xd8, 0x12, 0xd8, 0xc8, 0x68, 0x10, 0xd8
	.byte 0x8d, 0xec, 0x12, 0xed, 0x12, 0xe8, 0xd0, 0xbc
	.byte 0x00, 0x55, 0x9d, 0x02, 0x20, 0xbc, 0x02, 0x50
	.byte 0xb0, 0x54, 0xbd, 0x02, 0x54, 0x78, 0x84, 0xfc
	.byte 0x38, 0x3c, 0x3d, 0x3b
	.byte 0xc9, 0x8f, 0xc9, 0xee
	.byte 0x02, 0xd8, 0x12, 0xd8, 0xc8, 0x74, 0x10, 0xd8
	.byte 0x8d, 0xed, 0x12, 0x02, 0x06, 0x06, 0x9d, 0x00
	.byte 0x24, 0xdd, 0xf4, 0x6e, 0x10, 0xdb, 0x12, 0xdb
	.byte 0xc8, 0x7f, 0x10, 0xeb, 0x12, 0xb3, 0xb8, 0x03
	.byte 0x5b, 0x5d, 0x5c, 0x58
	.byte 0x0e, 0xec, 0x12, 0xe8
	.byte 0xd0, 0xeb, 0xd3, 0x9c, 0x00, 0x20, 0x9c, 0x02
	.byte 0x23, 0xbb, 0x00, 0x50, 0xb8, 0x02, 0x53, 0xbc
	.byte 0x09, 0x00, 0x04, 0x8c, 0x08, 0x21, 0xc9, 0xee
	.byte 0x02, 0xd8, 0x12, 0xd8, 0xc8, 0x68, 0x10, 0xd8
	.byte 0x8d, 0xec, 0x12, 0xed, 0x12, 0xe8, 0xd0, 0xbc
	.byte 0x00, 0x55, 0x9d, 0x02, 0x20, 0xbc, 0x02, 0x50
	.byte 0xb0, 0x54, 0xbd, 0x02, 0x54, 0x03, 0x5b, 0x5d
	.byte 0x5c, 0x58, 0x0e, 0x02, 0x06, 0x06, 0x3b, 0x38
	.byte 0x39, 0x3a, 0x3c, 0x3d, 0x3e
	.byte 0xc9, 0x8d, 0xd8
	.byte 0x12, 0xd8, 0xc8, 0x7f, 0x10, 0xe8, 0x12, 0xb0
	.byte 0xc8, 0x66, 0x05, 0xb0, 0xb0, 0x78, 0x4d, 0xfc
	.byte 0xd1, 0x46, 0x10, 0x24, 0xec, 0x12, 0xe8, 0xd0
	.byte 0xeb, 0xd3, 0x9c, 0x00, 0x20, 0x9c, 0x02, 0x23
	.byte 0xbb, 0x00, 0x50, 0xb8, 0x02, 0x53, 0xbc, 0x09
	.byte 0x00, 0x03, 0xcd, 0xee, 0x02, 0xda, 0x12, 0xda
	.byte 0xc8, 0x74, 0x10, 0xda, 0x8d, 0xec, 0x12, 0xed
	.byte 0x12, 0xe8, 0xd0, 0xbc, 0x00, 0x55, 0x9d, 0x02
	.byte 0x20, 0xbc, 0x02, 0x50, 0xb0, 0x54, 0xbd, 0x02
	.byte 0x54, 0x78, 0xc0, 0xfb, 0xd8, 0x12, 0xd8, 0xc8
	.byte 0x7f, 0x10, 0xe8, 0x12, 0x02, 0x06, 0x06, 0xb0
	.byte 0xb0, 0x03, 0x0e

TaskSched_PreemptiveYield_INT:
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
	add wa, 0x107E
	ld iy, wa
	extz xiy
	ld ix, (xiy + 256)
	cp ix, iy
	jr nz, TaskSched_PreemptiveYield_INT_Dequeue
	extz hl
	add hl, 0x1091
	extz xhl
	ld a, (xhl)
	inc 1, a
	jr z, TaskSched_PreemptiveYield_INT_Empty
	ld (xhl), a

TaskSched_PreemptiveYield_INT_Empty:
	jrl TaskSched_ContextRestore

TaskSched_PreemptiveYield_INT_Dequeue:
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
	add wa, 0x1068
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
	add wa, 0x107E
	ld iy, wa
	extz xiy
	push	sr
	ei 6
	ld ix, (xiy + 256)
	cp ix, iy
	jr nz, TaskQueue_Dequeue_Guard_Dequeue
	extz hl
	add hl, 0x1091
	extz xhl
	ld a, (xhl)
	inc 1, a
	jr z, TaskQueue_Dequeue_Guard_Empty
	ld (xhl), a

TaskQueue_Dequeue_Guard_Empty:
	pop	sr
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

TaskQueue_Dequeue_Guard_Dequeue:
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
	add wa, 0x1068
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
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

TaskSched_Wait:
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
	add wa, 0x1091
	extz xwa
	cp (xwa), 0x0
	jr z, TaskSched_Wait_Block
	decm8 1, (xwa)
	jrl TaskSched_ContextRestore

TaskSched_Wait_Block:
	ldw_d16 xix, 4166
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
	add de, 0x107E
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
	add wa, 0x1091
	extz xwa
	push	sr
	ei 6
	cp (xwa), 0x0
	jr z, TaskSem_TryDec_WouldBlock
	decm8 1, (xwa)
	xor hl, hl
	jr TaskSem_TryDec_Return

TaskSem_TryDec_WouldBlock:
	ldw hl, 0xFFFF

TaskSem_TryDec_Return:
	pop	sr
	ret

TaskSem_AddrCalc_Opaque:
	.byte 0xd8, 0x12, 0xd8, 0xc8, 0x91, 0x10, 0xe8, 0x12
	.byte 0x80, 0x27, 0xdb, 0x12, 0x0e

TaskMsgQ_Send:
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
	add wa, 0x1092
	ld iy, wa
	extz xiy
	ld ix, (xiy + 256)
	cp ix, iy
	jr nz, TaskMsgQ_Send_DirectDeliver
	ldw_d16 xix, 4294
	extz xix
	ld iy, (xix + 256)
	cp iy, ix
	jrl z, TaskMsgQ_Send_PoolEmpty
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
	add bc, 0x109A
	ld iy, bc
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jrl TaskSched_ContextRestore

TaskMsgQ_Send_PoolEmpty:
	ldw (xsp + 24), 0xFFFF
	jrl TaskSched_ContextRestore

TaskMsgQ_Send_DirectDeliver:
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
	add wa, 0x1068
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
	add wa, 0x1092
	ld iy, wa
	extz xiy
	push	sr
	ei 6
	ld ix, (xiy + 256)
	cp ix, iy
	jr nz, TaskMsgQ_Send_Guard_DirectDeliver
	ldw_d16 xix, 4294
	extz xix
	ld iy, (xix + 256)
	cp iy, ix
	jrl z, TaskMsgQ_Send_Guard_PoolEmpty
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
	add bc, 0x109A
	ld iy, bc
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix

TaskMsgQ_Send_Guard_Return:
	pop	sr
	pop xbc
	pop xhl
	pop xiz
	pop xiy
	pop xix
	pop xwa
	ret

TaskMsgQ_Send_Guard_PoolEmpty:
	ldw (xsp + 4), 0xFFFF
	jr TaskMsgQ_Send_Guard_Return

TaskMsgQ_Send_Guard_DirectDeliver:
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
	add wa, 0x1068
	ld iy, wa
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
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

TaskMsgQ_Receive:
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
	add wa, 0x109A
	ld iy, wa
	extz xiy
	ld ix, (xiy + 256)
	cp ix, iy
	jr z, TaskMsgQ_Receive_Empty
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
	ldw iy, 0x10C6
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	ld (xsp + 24), xiz
	jrl TaskSched_ContextRestore

TaskMsgQ_Receive_Empty:
	ldw_d16 xix, 4166
	extz xix
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (xix + 256)
	ld hl, (xix + 2)
	ld (xhl + 256), wa
	ld (xwa + 2), hl
	ld (xix + 9), 0x3
	add de, 0x1092
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

TaskMsgQ_TryReceive:
	push xix
	push xiz
	sll a, 2
	extz wa
	add wa, 0x109A
	ld iy, wa
	push	sr
	ei 6
	extz xiy
	ld ix, (xiy + 256)
	cp ix, iy
	jr z, TaskMsgQ_TryReceive_Empty
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
	ldw iy, 0x10C6
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	ld xhl, xiz
	jr TaskMsgQ_TryReceive_Return

TaskMsgQ_TryReceive_Empty:
	xor xhl, xhl

TaskMsgQ_TryReceive_Return:
	pop	sr
	pop xiz
	pop xix
	ret

Task_ConfigTimer:
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
	ld a, (xix + 256)
	mul a, 0x8
	add wa, 0x10C2
	ld iy, wa
	extz xiy
	ld wa, (xix + 2)
	ld (xiy + 256), wa
	ld (xiy + 2), wa
	ld xwa, (xix + 4)
	ld (xiy + 4), xwa
	jrl TaskSched_Dispatch
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
	mul a, 0xC
	add wa, 0x103C
	ld ix, wa
	extz xix
	cp (xix + 9), 0x4
	jr nz, Task_Reassign_NotRunning
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
	add de, 0x1068
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

Task_Reassign_NotRunning:
	ld (xix + 8), e
	jrl TaskSched_ContextRestore
	push xwa
	push xix
	push xiy
	push xhl
	pushw de
	ld e, c
	mul a, 0xC
	add wa, 0x103C
	ld ix, wa
	extz xix
	push	sr
	ei 6
	cp (xix + 9), 0x4
	jr nz, Task_Reassign_Guard_NotRunning
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
	add de, 0x1068
	ld iy, de
	extz xix
	extz xiy
	xor xwa, xwa
	ld (xix + 256), iy
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ld (xwa), ix
	ld (xiy + 2), ix
	jr Task_Reassign_Guard_Return

Task_Reassign_Guard_NotRunning:
	ld (xix + 8), e

Task_Reassign_Guard_Return:
	pop	sr
	popw de
	pop xhl
	pop xiy
	pop xix
	pop xwa
	ret

RingBuf_Access_Opaque_A:
	.ascii "(<=;"
	.byte 0x06, 0x06, 0xc9, 0x08
	.byte 0x0c, 0xd8, 0xc8, 0x3c, 0x10, 0xd8, 0x8c, 0xec
	.byte 0x12, 0xe8, 0xd0, 0xeb, 0xd3, 0x9c, 0x00, 0x20
	.byte 0x9c, 0x02, 0x23, 0xbb, 0x00, 0x50, 0xb8, 0x02
	.byte 0x53, 0xbc, 0x09, 0x00, 0x00, 0xbc, 0x0a, 0x00
	.byte 0x00, 0x06, 0x00
	.byte 0x5b, 0x5d, 0x5c, 0x48
	.byte 0x0e
	.byte 0xd8, 0xef, 0x01, 0xd1, 0x40, 0x10, 0x80, 0xd1
	.byte 0x40, 0x10, 0xf0, 0x6a, 0xfa, 0x0e

IntMask_SetBit3:
	set_dd8 3, 0x80
	ret

IntMask_ClearBit3:
	res_dd8 3, 0x80
	ret

RingBuf_Control_Opaque:
	.byte 0xd1, 0xd2, 0x10, 0x61, 0x0e, 0xd1, 0xd2, 0x10
	.byte 0x69, 0x0e, 0x2c, 0x3a, 0xf2, 0x2e, 0x0c, 0x04
	.byte 0x32, 0x1e, 0x38, 0x03, 0x5a, 0x4c, 0x0e, 0xee
	.byte 0x0c, 0x00, 0x00, 0x2c, 0x3a, 0x8e, 0x08, 0x21
	.byte 0xf2, 0x2e, 0x0c, 0x04, 0x32, 0x1e, 0x78, 0x03
	.byte 0x5a, 0x4c, 0xee, 0x0d, 0x0e, 0xee, 0x0c, 0x00
	.byte 0x00, 0x3d, 0x3c, 0x3a, 0x9e, 0x08, 0x21, 0xae
	.byte 0x0a, 0x25, 0xf2, 0x2e, 0x0c, 0x04, 0x32, 0x85
	.byte 0x21, 0x1e, 0x5c, 0x03, 0xed, 0x61, 0xd9, 0x1c
	.byte 0xf6, 0x5a, 0x5c, 0x5d, 0xee, 0x0d, 0x0e, 0xd2
	.byte 0x2a, 0x0c, 0x04, 0x23, 0xd2, 0x26, 0x0c, 0x04
	.byte 0xf3, 0xdb, 0xa8, 0x66, 0x03, 0x33, 0xff, 0xff
	.byte 0x0e, 0xd2, 0x2c, 0x0c, 0x04, 0x23, 0x0e

RingBuf_Init_1K:
	pushw ix
	push xde
	lda_24 xde, 0x040c2e
	call RingBuf_Reset_1K
	pop xde
	popw ix
	ret

RingBuf_ReadWrite_Opaque_A:
	.byte 0x2b, 0xd2, 0x26, 0x0c, 0x04, 0x23, 0xf2, 0x24
	.byte 0x0c, 0x04, 0x53, 0x4b, 0x0e, 0x2c, 0x3a, 0xf2
	.byte 0x2e, 0x0c, 0x04, 0x32, 0x1d, 0xbb, 0x0b, 0x02
	.byte 0x5a, 0x4c, 0x0e, 0x2c, 0x3a, 0xf2, 0x2e, 0x0c
	.byte 0x04, 0x32, 0x1d, 0xd6, 0x0b, 0x02, 0x5a, 0x4c
	.byte 0x0e, 0x2b, 0xd2, 0x28, 0x0c, 0x04, 0x23, 0xf2
	.byte 0x26, 0x0c, 0x04, 0x53, 0x4b, 0x0e, 0x2b, 0xd2
	.byte 0x2a, 0x0c, 0x04, 0x23, 0xf2, 0x28, 0x0c, 0x04
	.byte 0x53, 0x4b, 0x0e, 0x2c, 0x3a, 0xf2, 0x38, 0x10
	.byte 0x04, 0x32, 0x1e, 0x6c, 0x01, 0x5a, 0x4c, 0x0e
	.byte 0xee, 0x0c, 0x00, 0x00, 0x2c, 0x3a, 0x8e, 0x08
	.byte 0x21, 0xf2, 0x38, 0x10, 0x04, 0x32, 0x1e, 0xac
	.byte 0x01, 0x5a, 0x4c, 0xee, 0x0d, 0x0e, 0xee, 0x0c
	.byte 0x00, 0x00, 0x3d, 0x3c, 0x3a, 0x9e, 0x08, 0x21
	.byte 0xae, 0x0a, 0x25, 0xf2, 0x38, 0x10, 0x04, 0x32
	.byte 0x85, 0x21, 0x1e, 0x90, 0x01, 0xed, 0x61, 0xd9
	.byte 0x1c, 0xf6, 0x5a, 0x5c, 0x5d, 0xee, 0x0d, 0x0e
	.byte 0xd2, 0x34, 0x10, 0x04, 0x23, 0xd2, 0x30, 0x10
	.byte 0x04, 0xf3, 0xdb, 0xa8, 0x66, 0x03, 0x33, 0xff
	.byte 0xff, 0x0e, 0xd2, 0x36, 0x10, 0x04, 0x23, 0x0e

RingBuf_Init_256:
	pushw ix
	push xde
	lda_24 xde, 0x041038
	call RingBuf_Reset_256
	pop xde
	popw ix
	ret

RingBuf_ReadWrite_Opaque_B:
	.byte 0x2b, 0xd2, 0x30, 0x10, 0x04, 0x23, 0xf2, 0x2e
	.byte 0x10, 0x04, 0x53, 0x4b, 0x0e, 0x2c, 0x3a, 0xf2
	.byte 0x38, 0x10, 0x04, 0x32, 0x1d, 0x9d, 0x0a, 0x02
	.byte 0x5a, 0x4c, 0x0e, 0x2c, 0x3a, 0xf2, 0x38, 0x10
	.byte 0x04, 0x32, 0x1d, 0xb8, 0x0a, 0x02, 0x5a, 0x4c
	.byte 0x0e, 0x2b, 0xd2, 0x32, 0x10, 0x04, 0x23, 0xf2
	.byte 0x30, 0x10, 0x04, 0x53, 0x4b, 0x0e, 0x2b, 0xd2
	.byte 0x34, 0x10, 0x04, 0x23, 0xf2, 0x32, 0x10, 0x04
	.byte 0x53, 0x4b, 0x0e, 0x2c, 0x3a, 0xf2, 0x42, 0x11
	.byte 0x04, 0x32, 0x1e, 0x4d, 0x01, 0x5a, 0x4c, 0x0e
	.byte 0xee, 0x0c, 0x00, 0x00, 0x2c, 0x3a, 0x8e, 0x08
	.byte 0x21, 0xf2, 0x42, 0x11, 0x04, 0x32, 0x1e, 0x8d
	.byte 0x01, 0x5a, 0x4c, 0xee, 0x0d, 0x0e, 0xee, 0x0c
	.byte 0x00, 0x00, 0x3d, 0x3c, 0x3a, 0x9e, 0x08, 0x21
	.byte 0xae, 0x0a, 0x25, 0xf2, 0x42, 0x11, 0x04, 0x32
	.byte 0x85, 0x21, 0x1e, 0x71, 0x01, 0xed, 0x61, 0xd9
	.byte 0x1c, 0xf6, 0x5a, 0x5c, 0x5d, 0xee, 0x0d, 0x0e
	.byte 0xd2, 0x3e, 0x11, 0x04, 0x23, 0xd2, 0x3a, 0x11
	.byte 0x04, 0xf3, 0xdb, 0xa8, 0x66, 0x03, 0x33, 0xff
	.byte 0xff, 0x0e, 0xd2, 0x40, 0x11, 0x04, 0x23, 0x0e

RingBuf_Init_512:
	pushw ix
	push xde
	lda_24 xde, 0x041142
	call RingBuf_Reset_512
	pop xde
	popw ix
	ret

; --- Audio buffer pointer load/store utilities ---
; Five small routines that load/store 16-bit pointer values
; from the audio buffer control block at 0x041138-0x041142.
; Each routine saves/restores caller registers.
AudioBuf_PtrUtils:
	pushw	hl
	ldw_da	hl, 266554
	stw_da	266552, hl
	popw	hl
	ret
	pushw	ix
	push	xde
	lda_24	xde, 266562
	call	133932
	pop	xde
	popw	ix
	ret
	pushw	ix
	push	xde
	lda_24	xde, 266562
	call	133959
	pop	xde
	popw	ix
	ret
	pushw	hl
	ldw_da	hl, 266556
	stw_da	266554, hl
	popw	hl
	ret
	pushw	hl
	ldw_da	hl, 266558
	stw_da	266556, hl
	popw	hl
	ret

RingBuf_Reset_256:
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0xFF
	ret

RingBuf_WrappedRead_Opaque_A:
	.byte 0x9a, 0xf8, 0x24, 0x9a, 0xfc, 0xf4, 0x6e, 0x04
	.byte 0x33, 0xff, 0xff, 0x0e, 0xdb, 0xd3, 0xc3, 0x07
	.byte 0xe8, 0xf0, 0x27, 0xdc, 0x38, 0xff, 0x00, 0xba
	.byte 0xf8, 0x54, 0x9a, 0xfe, 0x61, 0x0e, 0x9a, 0xf6
	.byte 0x24, 0x9a, 0xfa, 0xf4, 0x6e, 0x04, 0x33, 0xff
	.byte 0xff, 0x0e, 0xdb, 0xd3, 0xc3, 0x07, 0xe8, 0xf0
	.byte 0x27, 0xdc, 0x38, 0xff, 0x00, 0xba, 0xf6, 0x54
	.byte 0x0e, 0x9a, 0xf6, 0x24, 0x9a, 0xfc, 0xf4, 0x6e
	.byte 0x04, 0x33, 0xff, 0xff, 0x0e, 0xdb, 0xd3, 0xc3
	.byte 0x07, 0xe8, 0xf0, 0x27, 0xdc, 0x38, 0xff, 0x00
	.byte 0xba, 0xf6, 0x54, 0x0e, 0x9a, 0xfe, 0x3f, 0x00
	.byte 0x00, 0x6e, 0x04, 0x33, 0xff, 0xff, 0x0e, 0x9a
	.byte 0xfc, 0x24, 0xf3, 0x07, 0xe8, 0xf0, 0x41, 0xdc
	.byte 0x38, 0xff, 0x00, 0xba, 0xfc, 0x54, 0x9a, 0xfe
	.byte 0x69, 0x9a, 0xfe, 0x23, 0x0e

RingBuf_Reset_512:
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0x1FF
	ret

RingBuf_WrappedRead_Opaque_B:
	.byte 0x9a, 0xf8, 0x24, 0x9a, 0xfc, 0xf4, 0x6e, 0x04
	.byte 0x33, 0xff, 0xff, 0x0e, 0xdb, 0xd3, 0xc3, 0x07
	.byte 0xe8, 0xf0, 0x27, 0xdc, 0x38, 0xff, 0x01, 0xba
	.byte 0xf8, 0x54, 0x9a, 0xfe, 0x61, 0x0e, 0x9a, 0xf6
	.byte 0x24, 0x9a, 0xfa, 0xf4, 0x6e, 0x04, 0x33, 0xff
	.byte 0xff, 0x0e, 0xdb, 0xd3, 0xc3, 0x07, 0xe8, 0xf0
	.byte 0x27, 0xdc, 0x38, 0xff, 0x01, 0xba, 0xf6, 0x54
	.byte 0x0e, 0x9a, 0xf6, 0x24, 0x9a, 0xfc, 0xf4, 0x6e
	.byte 0x04, 0x33, 0xff, 0xff, 0x0e, 0xdb, 0xd3, 0xc3
	.byte 0x07, 0xe8, 0xf0, 0x27, 0xdc, 0x38, 0xff, 0x01
	.byte 0xba, 0xf6, 0x54, 0x0e, 0x9a, 0xfe, 0x3f, 0x00
	.byte 0x00, 0x6e, 0x04, 0x33, 0xff, 0xff, 0x0e, 0x9a
	.byte 0xfc, 0x24, 0xf3, 0x07, 0xe8, 0xf0, 0x41, 0xdc
	.byte 0x38, 0xff, 0x01, 0xba, 0xfc, 0x54, 0x9a, 0xfe
	.byte 0x69, 0x9a, 0xfe, 0x23, 0x0e

RingBuf_Reset_1K:
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0x3FF
	ret

RingBuf_WrappedRead_Opaque_C:
	.byte 0x9a, 0xf8, 0x24, 0x9a, 0xfc, 0xf4, 0x6e, 0x04
	.byte 0x33, 0xff, 0xff, 0x0e, 0xdb, 0xd3, 0xc3, 0x07
	.byte 0xe8, 0xf0, 0x27, 0xdc, 0x38, 0xff, 0x03, 0xba
	.byte 0xf8, 0x54, 0x9a, 0xfe, 0x61, 0x0e, 0x9a, 0xf6
	.byte 0x24, 0x9a, 0xfa, 0xf4, 0x6e, 0x04, 0x33, 0xff
	.byte 0xff, 0x0e, 0xdb, 0xd3, 0xc3, 0x07, 0xe8, 0xf0
	.byte 0x27, 0xdc, 0x38, 0xff, 0x03, 0xba, 0xf6, 0x54
	.byte 0x0e, 0x9a, 0xf6, 0x24, 0x9a, 0xfc, 0xf4, 0x6e
	.byte 0x04, 0x33, 0xff, 0xff, 0x0e, 0xdb, 0xd3, 0xc3
	.byte 0x07, 0xe8, 0xf0, 0x27, 0xdc, 0x38, 0xff, 0x03
	.byte 0xba, 0xf6, 0x54, 0x0e, 0x9a, 0xfe, 0x3f, 0x00
	.byte 0x00, 0x6e, 0x04, 0x33, 0xff, 0xff, 0x0e, 0x9a
	.byte 0xfc, 0x24, 0xf3, 0x07, 0xe8, 0xf0, 0x41, 0xdc
	.byte 0x38, 0xff, 0x03, 0xba, 0xfc, 0x54, 0x9a, 0xfe
	.byte 0x69, 0x9a, 0xfe, 0x23, 0x0e

Audio_CmdHandler_C0_FF:
	lds hl, 0
	ret

; ===========================================================================
; InterCPU_Latch_Setup - Setup inter-CPU communication via latches
; ===========================================================================
; Entry: None
; Exit:  DMA channels and interrupt handlers configured
; Notes: Configures interrupt priority for DMA channels 0-3
;        Sets up MicroDMA for inter-CPU latch communication at 0x120000
;        Initializes DMA_XFER_STATE and CMD_PROCESSING_STATE to 0
; ===========================================================================
InterCPU_Latch_Setup:
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
	ldio 0x8A, 0x14
	lda_24 xwa, 0x120000
	ldc_cr32 xwa, 0x28
	ldb a, 0x8
	ldc_cr8 a, 0x4A
	lda_24 xwa, 0x120000
	ldc_cr32 xwa, 0x00
	ldb a, 0x0
	ldc_cr8 a, 0x42
	stdi8 4328, 0
	stdi8 4330, 0
	ret

; ===========================================================================
; InterCPU_DMA_Send - Send data via DMA to main CPU
; ===========================================================================
; Entry: XDE = source data pointer
;        BC = byte count
;        A = command/channel identifier
; Exit:  Data transferred to main CPU via inter-CPU latch
; Notes: Splits large transfers into 32-byte chunks
;        Used by tone generator and audio subsystem for command responses
; ===========================================================================
InterCPU_DMA_Send:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xde
	ld iz, bc
	ld (xsp + 6), a
	cp iz, 0x20
	jr ule, DMA_Send_Final

DMA_Send_Loop:
	ld a, (xsp + 6)
	extz wa
	ldw bc, 0x20
	ld xde, (xsp + 2)
	calr InterCPU_DMA_Send_Chunk
	ld xwa, 0x20
	add (xsp + 2), xwa
	sub iz, 0x20
	cp iz, 0x20
	jr ugt, DMA_Send_Loop

DMA_Send_Final:
	ld a, (xsp + 6)
	extz wa
	stb_erp C, 0xF8
	extz bc
	ld xde, (xsp + 2)
	calr InterCPU_DMA_Send_Chunk
	popw iz
	inc 6, xsp
	ret

; ===========================================================================
; InterCPU_DMA_Send_Chunk - Transfer a single chunk of data to main CPU
; ===========================================================================
; Entry: XDE = source data pointer
;        BC = byte count (must be non-zero)
;        A = command/channel identifier (bits 7-5 used for dispatch)
; Exit:  Data transferred via DMA channel 2
; Notes: Helper for InterCPU_DMA_Send - handles one transfer operation.
;        Waits for MSTAT1 handshake, sets up DMA, then waits for completion.
;        Command byte format: (A << 5) | (length - 1)
; ===========================================================================
InterCPU_DMA_Send_Chunk:
	cps c, 0
	ret z
	lds ix, 0

DMA_Chunk_Start:
	bit_dd8 4, 0x34	; MSTAT1 - test if Main CPU is requesting handshake
	jr z, InterCPU_Wait_MSTAT1_Clear
	res_dd8 0, 0x34	; SSTAT0 - clear to acknowledge Main CPU handshake request
	stdi8 4328, 1
	ld l, c
	dec 1, l
	sll a, 5
	or a, l
	stb_da 0x120000, a
	lds ix, 0

DMA_Chunk_Transfer:
	bit_dd8 4, 0x34	; MSTAT1 - wait for Main CPU to clear (data ready to receive)
	jr nz, InterCPU_Wait_MSTAT1_Set
	set_dd8 0, 0x34	; SSTAT0 - set to signal ready to receive DMA data
	ldc_cr32 xde, 0x08
	extz bc
	ldc_cr16 bc, 0x48
	stdi8 258, 22
	set_dd8 2, 0x80
	cpdi8 4328, 0
	ret z

DMA_Chunk_Wait:
	cpdi8 4328, 0
	jr nz, DMA_Chunk_Wait
	ret

InterCPU_Wait_MSTAT1_Clear:
	ld hl, ix
	inc 1, ix
	cp hl, 0xEA60
	jr ule, DMA_Chunk_Start
	ret

InterCPU_Wait_MSTAT1_Set:
	ld wa, ix
	inc 1, ix
	cp wa, 0xEA60
	jr ule, DMA_Chunk_Transfer
	set_dd8 0, 0x34	; SSTAT0 - timeout recovery: force ready state before exit
	ret

InterCPU_LatchProtocol_Opaque:
	.byte 0xd9, 0xa8, 0xf0, 0x34, 0xcc, 0x66, 0x12, 0xf0
	.byte 0x34, 0xb0, 0xf2, 0x00, 0x00, 0x12, 0x00, 0xe3
	.byte 0xf0, 0x34, 0xcc, 0x6e, 0x0f, 0xf0, 0x34, 0xb8
	.byte 0x0e, 0xd9, 0x88, 0xd9, 0x61, 0xd8, 0xcf, 0x60
	.byte 0xea, 0x63, 0xdf, 0x0e, 0xd9, 0x88, 0xd9, 0x61
	.byte 0xd8, 0xcf, 0x60, 0xea, 0x6b, 0xe7, 0x68, 0xe0
	.byte 0xdc, 0xa8, 0xc1, 0xe8, 0x10, 0x3f, 0x00, 0x66
	.byte 0x11, 0xdc, 0x8b, 0xdc, 0x61, 0xdb, 0xcf, 0x60
	.byte 0xea, 0xb0, 0xfb, 0xc1, 0xe8, 0x10, 0x3f, 0x00
	.byte 0x6e, 0xef, 0xf0, 0x34, 0xb0, 0xf1, 0xe8, 0x10
	.byte 0x00, 0x01, 0xf2, 0x00, 0x00, 0x12, 0x00, 0xe2
	.byte 0xdc, 0xa8, 0xf0, 0x34, 0xcc, 0x6e, 0x33, 0xf0
	.byte 0x34, 0xb8, 0xf1, 0xd4, 0x10, 0x33, 0xb3, 0x60
	.byte 0xbb, 0x04, 0x62, 0xbb, 0x08, 0x51, 0xeb, 0x2e
	.byte 0x08, 0x30, 0x0a, 0x00, 0xd8, 0x2e, 0x48, 0xf1
	.byte 0x02, 0x01, 0x00, 0x16, 0xf0, 0x80, 0xba, 0xf1
	.byte 0xfe, 0x04, 0xbf, 0xc1, 0xe8, 0x10, 0x3f, 0x00
	.byte 0xb0, 0xf6, 0xc1, 0xe8, 0x10, 0x3f, 0x00, 0x6e
	.byte 0xf9, 0x0e, 0xdc, 0x8b, 0xdc, 0x61, 0xdb, 0xcf
	.byte 0x60, 0xea, 0x63, 0xbe, 0xf0, 0x34, 0xb8, 0x0e

; ===========================================================================
; InterCPU_E1_DMA_Transfer - E1 command bulk data transfer (Sub→Main CPU)
; ===========================================================================
; Entry: XWA = destination address (in main CPU memory)
;        XDE = source address (in sub CPU memory)
;        BC = byte count
; Exit:  Data transferred to main CPU via two-phase E1 protocol
; Notes: Called from Cmd_Check_E2_Pending to send response data.
;        Phase 1: Send E1 command + 6-byte header (dest addr, byte count)
;        Phase 2: Actual data transfer via DMA channel 2
;        Uses 60000 iteration timeout (0xEA60) for handshake waits.
;        Stores parameters at 0x1110 and 0x10DE for DMA setup.
; ===========================================================================
InterCPU_E1_DMA_Transfer:
	pushw iz
	lds iz, 0
	cpdi8 4328, 0
	jr z, E1_DMA_Ready

E1_Wait_DMA_Idle:
	ld hl, iz
	inc 1, iz
	cp hl, 0xEA60
	jrl ugt, E1_Exit
	cpdi8 4328, 0
	jr nz, E1_Wait_DMA_Idle

E1_DMA_Ready:
	lds iz, 0

E1_Check_MSTAT1:
	bit_dd8 4, 0x34	; MSTAT1 - test if Main CPU is initiating E1 transfer
	jrl z, E1_Timeout_Retry
	res_dd8 0, 0x34	; SSTAT0 - clear to acknowledge E1 command from Main CPU
	stdi8 4328, 2
	stib_da 0x120000, 0xe1
	lds iz, 0

E1_Start_Transfer:
	bit_dd8 4, 0x34	; MSTAT1 - wait for Main CPU to clear (header data ready)
	jrl nz, E1_Busy_Wait
	set_dd8 0, 0x34	; SSTAT0 - set to signal ready to receive DMA header
	lda_d16 xhl, 4368
	ld (xhl), xwa
	lda_d16 xwa, 4318
	ld (xwa), xde
	ld (xhl + 4), bc
	ld (xwa + 4), bc
	ldc_cr32 xwa, 0x08
	lds wa, 6
	ldc_cr16 wa, 0x48
	stdi8 258, 22
	set_dd8 2, 0x80
	cpdi8 4328, 1
	jr z, E1_Delay_Loop1

E1_Wait_State1:
	cpdi8 4328, 1
	jr nz, E1_Wait_State1

E1_Delay_Loop1:
	lds iz, 0
	cp iz, 0xC8
	jr nc, E1_Phase2_Setup

E1_Delay1:
	nop
	inc 1, iz
	cp iz, 0xC8
	jr c, E1_Delay1

E1_Phase2_Setup:
	lda_d16 xwa, 4368
	ld xbc, (xwa)
	ldc_cr32 xbc, 0x08
	ld wa, (xwa + 4)
	ldc_cr16 wa, 0x48
	stdi8 258, 22
	set_dd8 2, 0x80
	cpdi8 4328, 0
	jr z, E1_Delay_Loop2

E1_Wait_Complete:
	cpdi8 4328, 0
	jr nz, E1_Wait_Complete

E1_Delay_Loop2:
	lds iz, 0
	cp iz, 0xC8
	jr nc, E1_Done

E1_Delay2:
	nop
	inc 1, iz
	cp iz, 0xC8
	jr c, E1_Delay2

E1_Done:
	jr E1_Exit

E1_Timeout_Retry:
	ld hl, iz
	inc 1, iz
	cp hl, 0xEA60
	jrl ule, E1_Check_MSTAT1
	jr E1_Exit

E1_Busy_Wait:
	ld hl, iz
	inc 1, iz
	cp hl, 0xEA60
	jrl ule, E1_Start_Transfer
	set_dd8 0, 0x34	; SSTAT0 - timeout recovery: force ready state before exit

E1_Exit:
	popw iz
	ret


; ----------------------------------------------------------------------------
; INT0_HANDLER - External Interrupt 0 Handler (Inter-CPU Command Reception)
; Entry: Triggered when main CPU sends command via latch at 0x120000
; Notes: Reads command byte from latch, dispatches based on value:
;        0xE1 = Start E1 command (6 bytes, state 2) - bulk data transfer setup
;        0xE2 = Start E2 command (10 bytes, state 3) - extended data transfer
;        0xE3 = Payload ready signal (sets PAYLOAD_LOADED_FLAG bit 6)
;        Other = Standard command (1-32 bytes based on bits 4-0, state 1)
; ----------------------------------------------------------------------------
INT0_HANDLER:	; 20E86
	push xwa
	bit_dd8 2, 0x34	; MSTAT0 - test if Main CPU is currently sending data
	jr nz, INT0_Exit
	ldb_da a, 0x120000
	stb_d8 4332, a
	cp a, 0xE1
	jr nz, INT0_Check_E2
	stdi8 4330, 2	; E1 command - state 2
	lda_d16 xwa, 4374	; E1 data buffer
	stda32 4324, xwa	; Save DMA target
	ldc_cr32 xwa, 0x20
	lds wa, 6	; 6 bytes for E1
	ldc_cr16 wa, 0x40
	jr INT0_Start_DMA

INT0_Check_E2:	; 020EB1h
	cp a, 0xE2
	jr nz, INT0_Check_E3
	stdi8 4330, 3	; E2 command - state 3
	lda_d16 xwa, 4380	; E2 data buffer
	stda32 4324, xwa
	ldc_cr32 xwa, 0x20
	ldw wa, 0xA	; 10 bytes for E2
	ldc_cr16 wa, 0x40
	jr INT0_Start_DMA

INT0_Check_E3:	; 020ECEh
	cp a, 0xE3
	jr nz, INT0_Standard_Cmd
	setda 6, 1278	; E3 = payload ready
	jr INT0_Ack

INT0_Standard_Cmd:	; 020ED9h - standard variable-length command
	stdi8 4330, 1	; State 1
	lda_d16 xwa, 4336	; Standard command buffer
	stda32 4324, xwa
	ldc_cr32 xwa, 0x20
	ldb_d8 a, 4332
	and a, 0x1F	; Bits 4-0 = length - 1
	inc 1, a	; Add 1 for actual length
	extz wa
	ldc_cr16 wa, 0x40

INT0_Start_DMA:	; 020EF7h
	stdi8 256, 10	; Start DMA channel 0

INT0_Ack:	; 020EFCh
	res_dd8 1, 0x34	; SSTAT1 - clear to acknowledge command received from Main CPU

INT0_Exit:	; 020EFFh
	pop xwa
	reti


;=============================================================================
; MICRODMA_CH2_HANDLER - MicroDMA Channel 2 Completion Interrupt
;=============================================================================
; Called when DMA channel 2 transfer completes (payload data transfers).
; Manages the DMA state machine for multi-phase transfers:
;   - State 2 (two-phase) -> State 1 (waiting for phase 2)
;   - State 1 (single xfer) -> State 0 (idle)
; Stops Timer 8 which triggers the DMA transfers.
;=============================================================================
MICRODMA_CH2_HANDLER:	; Channel #2 completion		; 20F01
	res_dd8 2, 0x80
	cpdi8 4328, 1
	jr nz, MICRODMA_CH2_State2
	stdi8 4328, 0
	jr MICRODMA_CH2_Done

MICRODMA_CH2_State2:	; 020F12h - two-phase transfer, go to state 1
	cpdi8 4328, 2
	jr nz, MICRODMA_CH2_Done
	stdi8 4328, 1

MICRODMA_CH2_Done:	; 020F1Eh
	reti


;=============================================================================
; MICRODMA_CH0_HANDLER - MicroDMA Channel 0 Completion Interrupt
;=============================================================================
; Called when DMA channel 0 transfer completes (inter-CPU latch reads).
; This is the main command dispatcher - receives commands from main CPU
; and processes them based on CMD_PROCESSING_STATE:
;   State 1: Decode command byte (bits 7-5 = handler, bits 4-0 = length)
;   State 2: Process E1 command (two-phase transfer setup)
;   State 3: Process E2 command (transfer parameters)
;   State 4: Process E3 command (payload ready signal)
;=============================================================================
MICRODMA_CH0_HANDLER:	; 20F1Fh - Channel #0 completion (command dispatch)
	push xiz
	push xiy
	push xix
	push xhl
	push xde
	push xbc
	push xwa
	ldb_d8 a, 4330
	cps a, 4
	jr z, CH0_State4_E1_Done
	cps a, 3
	jr z, CH0_State3_E2
	cps a, 2
	jr z, CH0_State2_E1
	cps a, 1
	jr nz, CH0_Timer_Reset
	; State 1: Standard command processing
	pushw 0x0
	pushw 0x10F0	; Command buffer address
	ldb_d8 c, 4332
	ld a, c
	and a, 0x1F
	inc 1, a	; Length = (byte & 0x1F) + 1
	extz wa
	pushw wa
	srl c, 5	; The 3 highest bits from the byte received via maincpu latch
	             ; are used to select one of the 8 call-table entries
	ld a, c
	extz wa
	sla wa, 2	; Multiply by 4 (table entry size)
	lda_24 xbc, 0x00f46c
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	call (xwa)	; Dispatch to handler
	inc 6, xsp
	stdi8 4330, 0
	jr CH0_Ack

CH0_State2_E1:	; 020F6Dh - E1 command phase 1 complete, start phase 2
	lda_d16 xwa, 4374	; E1 data buffer
	ld xbc, (xwa)	; Get DMA destination address
	ldc_cr32 xbc, 0x20
	ld wa, (xwa + 4)	; Get DMA byte count
	ldc_cr16 wa, 0x40
	stdi8 256, 10	; Start DMA
	stdi8 4330, 4	; Move to state 4
	jr CH0_Timer_Reset

CH0_State3_E2:	; 020F88h - E2 command complete
	stdi8 4334, 255
	stdi8 4330, 0
	set_dd8 1, 0x34	; SSTAT1 - set to signal ready for next command from Main CPU
	setda 7, 4390	; Set E2 pending flag
	jr CH0_Timer_Reset

CH0_State4_E1_Done:	; 020F9Bh - E1 two-phase transfer complete
	stdi8 4330, 0
	resda 7, 1278

CH0_Ack:	; 020FA4h
	set_dd8 1, 0x34	; SSTAT1 - set to signal E1 transfer complete, ready for next

CH0_Timer_Reset:	; 020FA7h - reset Timer 8 if running
	bit_dd8 2, 0x80
	jr z, CH0_Exit
	res_dd8 2, 0x80	; Stop timer
	nop
	nop
	set_dd8 2, 0x80	; Restart timer

CH0_Exit:	; 020FB4h
	pop xwa
	pop xbc
	pop xde
	pop xhl
	pop xix
	pop xiy
	pop xiz
	reti

; ----------------------------------------------------------------------------
; Cmd_Check_E2_Pending - Check and process pending E2 command
; Entry: None
; Exit:  E2 data processed if pending flag set
; Notes: Called from main loop to handle deferred E2 processing
; ----------------------------------------------------------------------------
Cmd_Check_E2_Pending:	; 020FBCh
	ei 6
	lda_d16 xwa, 4390
	bitm 7, (xwa)	; Check E2 pending flag
	jr z, Cmd_Check_DMA_Timeout
	resm 7, (xwa)	; Clear pending flag
	ei 0
	lda_d16 xde, 4380	; E2 data buffer
	ld xwa, (xde)
	ld bc, (xde + 8)
	ld xde, (xde + 4)
	calr InterCPU_E1_DMA_Transfer	; Process E2 data

; Check for DMA timeout (stuck transfer detection)
Cmd_Check_DMA_Timeout:	; 020FD9h
	ei 0
	bit_dd8 1, 0x34	; SSTAT1 - test own status: if set, no DMA transfer in progress
	jr nz, Cmd_DMA_Idle
	ldc_16_cr wa, 0x40	; Get current DMA byte count
	cpdm16 61468, xwa	; Compare with previous
	jr nz, Cmd_DMA_Reset_Counter
	incdi16 1, 61466	; Increment stuck counter
	jr Cmd_DMA_Save_Count

Cmd_DMA_Reset_Counter:	; 020FEFh
	stdi16 61466, 0	; Reset stuck counter

Cmd_DMA_Save_Count:	; 020FF5h
	stda16 61468, xwa	; Save current count
	jr Cmd_DMA_Check_Stuck

Cmd_DMA_Idle:	; 020FFBh
	stdi16 61466, 0

Cmd_DMA_Check_Stuck:	; 021001h
	ldw_d16 xwa, 61466
	cp wa, 0xA	; Stuck for 10 iterations?
	ret ule
	; Timeout recovery - abort stuck DMA
	stdi16 61466, 0
	stdi8 256, 0	; Stop DMA
	stdi8 4330, 0
	set_dd8 1, 0x34	; SSTAT1 - timeout recovery: force ready state after DMA abort
	incdi8 1, 61464	; Increment error counter
	ret

; ===========================================================================
; DAC_Write_Sample - Write audio sample to DAC interface
; ===========================================================================
; Entry: WA = 16-bit audio sample value
; Exit:  HL = readback value from DAC
; Notes: P6.7 controls A23 address line for tone generator/DAC access.
;        DAC interface is at 0x100000 (memory-mapped).
;        Readback may be used for verification or status check.
; ===========================================================================
DAC_Write_Sample:
	res_dd8 7, 0x18
	stw_da 0x100000, xwa
	ldw_da xhl, 0x100000
	ret

RingBuf_SetOffsetHi:
	stda16 10215, xwa
	ret

RingBuf_SetOffsetLo:
	stb_d8 10214, a
	ret

RingBuf_CheckOffset_ClearFlags:
	cpdi8 10214, 0
	jr z, RingBuf_CheckOffset_LoZero
	cpdi16 10215, 48
	jr c, RingBuf_CheckOffset_Level1
	resm 7, (xwa + 3)
	resm 7, (xwa + 4)
	resm 7, (xwa + 5)
	ret

RingBuf_CheckOffset_Level1:
	cpdi16 10215, 32
	ret c
	resm 7, (xwa + 4)
	resm 7, (xwa + 5)
	ret

RingBuf_CheckOffset_LoZero:
	cpdi16 10215, 80
	jr c, RingBuf_CheckOffset_LoZero_Level1
	resm 7, (xwa + 3)
	resm 7, (xwa + 4)
	resm 7, (xwa + 5)
	ret

RingBuf_CheckOffset_LoZero_Level1:
	cpdi16 10215, 64
	ret c
	resm 7, (xwa + 4)
	resm 7, (xwa + 5)
	ret

Quad_Decode_A_To_L:
	cp a, 0x40
	jr nc, Quad_Decode_Quarter2
	ldb l, 0x0
	jr Quad_Decode_Return

Quad_Decode_Quarter2:
	cp a, 0x80
	jr nc, Quad_Decode_Quarter3
	ldb l, 0x4
	jr Quad_Decode_Return

Quad_Decode_Quarter3:
	cp a, 0xC0
	jr nc, Quad_Decode_Quarter4
	ldb l, 0x8
	jr Quad_Decode_Return

Quad_Decode_Quarter4:
	ldb l, 0x0

Quad_Decode_Return:
	ret

SlotPair_Decode_C_To_L:
	and c, 0x3
	cps c, 3
	jr z, SlotPair_Decode_Case3
	cps c, 2
	jr z, SlotPair_Decode_Case2
	cps c, 1
	jr z, SlotPair_Decode_Case1
	cps c, 0
	ret nz

SlotPair_Decode_Case1:
	and a, 0x3F
	ld l, a
	jr SlotPair_Decode_Return

SlotPair_Decode_Case2:
	sub a, 0x40
	ld l, a
	res 7, l
	jr SlotPair_Decode_Return

SlotPair_Decode_Case3:
	ld l, a
	res 7, l

SlotPair_Decode_Return:
	ret

VoiceState_SwapSlot_DE_BC:
	ld e, c
	extz de
	ld ix, de
	ld e, a
	extz de
	muls de, 0xC
	lda_d16 xhl, 9446
	exts xde
	add xde, xhl
	ld hl, ix
	extz xhl
	add xhl, xde
	ld b, (xhl)
	ld e, c
	extz de
	ld ix, de
	inc 4, ix
	ld e, a
	extz de
	muls de, 0xC
	lda_d16 xhl, 9446
	exts xde
	add xde, xhl
	ld hl, ix
	extz xhl
	add xhl, xde
	ld w, (xhl)
	ld e, c
	extz de
	ld ix, de
	ld e, w
	extz de
	muls de, 0xC
	lda_d16 xhl, 9446
	exts xde
	add xde, xhl
	ld hl, ix
	extz xhl
	add xhl, xde
	ld (xhl), b
	ld e, c
	extz de
	ld ix, de
	inc 4, ix
	ld e, b
	extz de
	muls de, 0xC
	lda_d16 xhl, 9446
	exts xde
	add xde, xhl
	ld hl, ix
	extz xhl
	add xhl, xde
	ld (xhl), w
	ld e, c
	extz de
	ld ix, de
	ld e, a
	extz de
	muls de, 0xC
	lda_d16 xhl, 9446
	exts xde
	add xde, xhl
	ld hl, ix
	extz xhl
	add xhl, xde
	ld (xhl), a
	extz bc
	ld hl, bc
	inc 4, hl
	ld c, a
	extz bc
	muls bc, 0xC
	lda_d16 xde, 9446
	exts xbc
	add xbc, xde
	ld de, hl
	extz xde
	add xde, xbc
	ld (xde), a
	ret

VoiceState_SwapSlot_HL_IY:
	ld l, c
	extz hl
	ld iy, hl
	ld l, a
	extz hl
	muls hl, 0xC
	lda_d16 xix, 9446
	exts xhl
	add xhl, xix
	ld ix, iy
	extz xix
	add xix, xhl
	ld b, (xix)
	ld l, c
	extz hl
	ld iy, hl
	inc 4, iy
	ld l, a
	extz hl
	muls hl, 0xC
	lda_d16 xix, 9446
	exts xhl
	add xhl, xix
	ld ix, iy
	extz xix
	add xix, xhl
	ld w, (xix)
	ld l, c
	extz hl
	ld iy, hl
	ld l, w
	extz hl
	muls hl, 0xC
	lda_d16 xix, 9446
	exts xhl
	add xhl, xix
	ld ix, iy
	extz xix
	add xix, xhl
	ld (xix), b
	ld l, c
	extz hl
	ld iy, hl
	inc 4, iy
	ld l, b
	extz hl
	muls hl, 0xC
	lda_d16 xix, 9446
	exts xhl
	add xhl, xix
	ld ix, iy
	extz xix
	add xix, xhl
	ld (xix), w
	ld l, c
	extz hl
	ld iy, hl
	inc 4, iy
	ld l, e
	extz hl
	muls hl, 0xC
	lda_d16 xix, 9446
	exts xhl
	add xhl, xix
	ld ix, iy
	extz xix
	add xix, xhl
	ld w, (xix)
	ld l, c
	extz hl
	ld iy, hl
	ld l, w
	extz hl
	muls hl, 0xC
	lda_d16 xix, 9446
	exts xhl
	add xhl, xix
	ld ix, iy
	extz xix
	add xix, xhl
	ld (xix), a
	ld l, c
	extz hl
	ld iy, hl
	inc 4, iy
	ld l, a
	extz hl
	muls hl, 0xC
	lda_d16 xix, 9446
	exts xhl
	add xhl, xix
	ld ix, iy
	extz xix
	add xix, xhl
	ld (xix), w
	ld l, c
	extz hl
	ld iy, hl
	ld l, a
	extz hl
	muls hl, 0xC
	lda_d16 xix, 9446
	exts xhl
	add xhl, xix
	ld ix, iy
	extz xix
	add xix, xhl
	ld (xix), e
	extz bc
	ld hl, bc
	inc 4, hl
	ld c, e
	extz bc
	muls bc, 0xC
	lda_d16 xde, 9446
	exts xbc
	add xbc, xde
	ld de, hl
	extz xde
	add xde, xbc
	ld (xde), a
	ret

VoiceState_SwapSlot_Guarded:
	dec 8, xsp
	ld (xsp + 4), e
	ld (xsp + 6), c
	ld c, a
	extz bc
	muls bc, 0xC
	lda_d16 xde, 9446
	exts xbc
	add xbc, xde
	ld (xsp), xbc
	ld c, (xsp + 6)
	extz bc
	ld de, bc
	inc 8, de
	ld xbc, (xsp)
	ldb_sri E, 0x07, 0xE4, 0xE8
	ld c, e
	cp c, 0xC0
	jr nc, VoiceState_SwapSlot_Guarded_WriteDst
	ld c, e
	extz bc
	muls bc, 0x5
	lda_d16 xde, 8486
	stb_dri D, 0x07, 0xE8, 0xE4
	cp (xix + 4), a
	jr nz, VoiceState_SwapSlot_Guarded_WriteDst
	ld c, (xsp + 6)
	ld e, c
	extz de
	ld xbc, (xsp)
	cpb_sri_mr A, 0x07, 0xE4, 0xE8
	jr z, VoiceState_SwapSlot_Guarded_MarkInactive
	ld c, (xsp + 6)
	ld e, c
	extz de
	ld xbc, (xsp)
	ldb_sri C, 0x07, 0xE4, 0xE8
	ld (xix + 4), c
	jr VoiceState_SwapSlot_Guarded_WriteDst

VoiceState_SwapSlot_Guarded_MarkInactive:
	ld (xix + 4), 0xFF

VoiceState_SwapSlot_Guarded_WriteDst:
	ld c, (xsp + 4)
	extz bc
	muls bc, 0x5
	lda_d16 xde, 8486
	stb_dri D, 0x07, 0xE8, 0xE4
	cp (xix + 4), 0x40
	jr ule, VoiceState_SwapSlot_Guarded_UseHL_IY
	ld (xix + 4), a
	ld e, a
	extz de
	ld a, (xsp + 6)
	ld c, a
	extz bc
	ld wa, de
	calr VoiceState_SwapSlot_DE_BC
	jr VoiceState_SwapSlot_Guarded_Return

VoiceState_SwapSlot_Guarded_UseHL_IY:
	ld l, a
	extz hl
	ld a, (xsp + 6)
	ld c, a
	extz bc
	ld a, (xix + 4)
	ld e, a
	extz de
	ld wa, hl
	calr VoiceState_SwapSlot_HL_IY

VoiceState_SwapSlot_Guarded_Return:
	ld a, (xsp + 6)
	extz wa
	ld de, wa
	inc 8, de
	ld xwa, (xsp)
	ld c, (xsp + 4)
	lda_dri XHL, 0x07, 0xE0, 0xE8
	inc 8, xsp
	ret

VoiceRow_FetchPair_WA_SP:
	ld c, a
	extz bc
	muls bc, 0x5
	lda_d16 xde, 8486
	ldb_sri W, 0x07, 0xE8, 0xE4
	ld c, a
	extz bc
	muls bc, 0x5
	lda_d16 xde, 8487
	ldb_sri L, 0x07, 0xE8, 0xE4
	ld c, l
	extz bc
	muls bc, 0x5
	lda_d16 xde, 8486
	lda_dri XWA, 0x07, 0xE8, 0xE4
	ld c, w
	extz bc
	muls bc, 0x5
	lda_d16 xde, 8487
	lda_dri XSP, 0x07, 0xE8, 0xE4
	ld c, a
	extz bc
	muls bc, 0x5
	lda_d16 xde, 8486
	lda_dri XBC, 0x07, 0xE8, 0xE4
	ld c, a
	extz bc
	muls bc, 0x5
	lda_d16 xde, 8487
	lda_dri XBC, 0x07, 0xE8, 0xE4
	ret

VoiceRow_FetchPair_DE_WA:
	ld e, a
	extz de
	muls de, 0x5
	lda_d16 xhl, 8486
	ldb_sri B, 0x07, 0xEC, 0xE8
	ld e, a
	extz de
	muls de, 0x5
	lda_d16 xhl, 8487
	ldb_sri W, 0x07, 0xEC, 0xE8
	ld e, w
	extz de
	muls de, 0x5
	lda_d16 xhl, 8486
	lda_dri XDE, 0x07, 0xEC, 0xE8
	ld e, b
	extz de
	muls de, 0x5
	lda_d16 xhl, 8487
	lda_dri XWA, 0x07, 0xEC, 0xE8
	ld e, c
	extz de
	muls de, 0x5
	lda_d16 xhl, 8487
	ldb_sri W, 0x07, 0xEC, 0xE8
	ld e, w
	extz de
	muls de, 0x5
	lda_d16 xhl, 8486
	lda_dri XBC, 0x07, 0xEC, 0xE8
	ld e, a
	extz de
	muls de, 0x5
	lda_d16 xhl, 8487
	lda_dri XWA, 0x07, 0xEC, 0xE8
	ld e, a
	extz de
	muls de, 0x5
	lda_d16 xhl, 8486
	lda_dri XHL, 0x07, 0xEC, 0xE8
	extz bc
	muls bc, 0x5
	lda_d16 xde, 8487
	lda_dri XBC, 0x07, 0xE8, 0xE4
	ret

VoiceSlot_UpdateNoteSource:
	dec 4, xsp
	push xiz
	ld (xsp + 4), e
	ld (xsp + 6), c
	ld c, a
	extz bc
	muls bc, 0x5
	lda_d16 xde, 8486
	stb_dri H, 0x07, 0xE8, 0xE4
	ld c, (xiz + 2)
	extz bc
	muls bc, 0x1B
	lda_d16 xde, 7757
	stb_dri C, 0x07, 0xE8, 0xE4
	ld e, (xiz + 3)
	ld c, e
	extz bc
	cpb_sri_mr A, 0x07, 0xEC, 0xE4
	jr nz, VoiceSlot_UpdateNoteSource_WriteCurrent
	cp (xiz), a
	jr z, VoiceSlot_UpdateNoteSource_MarkInactive
	extz de
	ld c, (xiz)
	lda_dri XHL, 0x07, 0xEC, 0xE8
	jr VoiceSlot_UpdateNoteSource_WriteCurrent

VoiceSlot_UpdateNoteSource_MarkInactive:
	ld c, e
	extz bc
	stib_ind 0x07, 0xEC, 0xE4, 0xFF

VoiceSlot_UpdateNoteSource_WriteCurrent:
	ld c, (xsp + 6)
	extz bc
	muls bc, 0x1B
	lda_d16 xde, 7757
	stb_dri C, 0x07, 0xE8, 0xE4
	ld c, (xsp + 4)
	extz bc
	cpib_sri 0x07, 0xEC, 0xE4, 0xC0
	jr ule, VoiceSlot_UpdateNoteSource_UseDE_WA
	ld c, (xsp + 4)
	extz bc
	lda_dri XBC, 0x07, 0xEC, 0xE4
	extz wa
	calr VoiceRow_FetchPair_WA_SP
	jr VoiceSlot_UpdateNoteSource_Return

VoiceSlot_UpdateNoteSource_UseDE_WA:
	ld e, a
	extz de
	ld a, (xsp + 4)
	extz wa
	ldb_sri A, 0x07, 0xEC, 0xE0
	ld c, a
	extz bc
	ld wa, de
	calr VoiceRow_FetchPair_DE_WA

VoiceSlot_UpdateNoteSource_Return:
	ld a, (xsp + 6)
	ld (xiz + 2), a
	ld a, (xsp + 4)
	ld (xiz + 3), a
	pop xiz
	inc 4, xsp
	ret

Voice_ScanSlots_ReassignSources:
	dec 6, xsp
	push xiz
	ld (xsp + 8), a
	ld a, (xsp + 8)
	extz wa
	muls wa, 0xC
	lda_d16 xbc, 9446
	exts xwa
	add xwa, xbc
	ld (xsp + 4), xwa
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jrl nc, Voice_ScanSlots_Return

Voice_ScanSlots_LoopBody:
	stb_erp A, 0xFB
	extz wa
	ld bc, wa
	inc 8, bc
	ld xwa, (xsp + 4)
	ldb_sri L, 0x07, 0xE0, 0xE4
	ld a, l
	cp a, 0xC0
	jrl nc, Voice_ScanSlots_LoopNext
	ld a, l
	extz wa
	muls wa, 0x5
	lda_d16 xbc, 8486
	stb_dri B, 0x07, 0xE4, 0xE0
	ld a, (xde + 4)
	cp a, (xsp + 8)
	jr nz, Voice_ScanSlots_MarkSlotInactive
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ldb_sri A, 0x07, 0xE0, 0xE4
	cp a, (xsp + 8)
	jr z, Voice_ScanSlots_PromoteSource
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ldb_sri A, 0x07, 0xE0, 0xE4
	ld (xde + 4), a
	jr Voice_ScanSlots_MarkSlotInactive

Voice_ScanSlots_PromoteSource:
	ld (xde + 4), 0xFF
	ldb_erp L, 0xF8
	extz iz
	ld a, l
	extz wa
	calr Quad_Decode_A_To_L
	ld c, l
	extz bc
	ld wa, iz
	ld de, bc
	ldw bc, 0x1A
	calr VoiceSlot_UpdateNoteSource

Voice_ScanSlots_MarkSlotInactive:
	ld a, (xsp + 8)
	ld e, a
	extz de
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld wa, de
	calr VoiceState_SwapSlot_DE_BC
	stb_erp A, 0xFB
	extz wa
	ld bc, wa
	inc 8, bc
	ld xwa, (xsp + 4)
	stib_ind 0x07, 0xE0, 0xE4, 0xFF

Voice_ScanSlots_LoopNext:
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jrl c, Voice_ScanSlots_LoopBody

Voice_ScanSlots_Return:
	pop xiz
	inc 6, xsp
	ret

VoiceState_FullReset:
	push xiz
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0x40
	jr nc, VoiceState_FullReset_Phase2

VoiceState_FullReset_Phase1_SlotLoop:
	ldb c, 0x0
	cps c, 4
	jr nc, VoiceState_FullReset_Phase1_Next

VoiceState_FullReset_Phase1_ColLoop:
	ld a, c
	extz wa
	ld hl, wa
	inc 8, hl
	stb_erp A, 0xFB
	extz wa
	muls wa, 0xC
	lda_d16 xde, 9446
	exts xwa
	add xwa, xde
	ld de, hl
	extz xde
	add xde, xwa
	ld (xde), 0xFF
	ld a, c
	extz wa
	ld hl, wa
	stb_erp A, 0xFB
	extz wa
	muls wa, 0xC
	lda_d16 xde, 9446
	exts xwa
	add xwa, xde
	ld de, hl
	extz xde
	add xde, xwa
	stb_erp A, 0xFB
	ld (xde), a
	ld a, c
	extz wa
	ld hl, wa
	inc 4, hl
	stb_erp A, 0xFB
	extz wa
	muls wa, 0xC
	lda_d16 xde, 9446
	exts xwa
	add xwa, xde
	ld de, hl
	extz xde
	add xde, xwa
	stb_erp A, 0xFB
	ld (xde), a
	inc 1, c
	cps c, 4
	jr c, VoiceState_FullReset_Phase1_ColLoop

VoiceState_FullReset_Phase1_Next:
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0x40
	jr c, VoiceState_FullReset_Phase1_SlotLoop

VoiceState_FullReset_Phase2:
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0xC0
	jr nc, VoiceState_FullReset_Phase3

VoiceState_FullReset_Phase2_Body:
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x5
	ld bc, wa
	lda_d16 xde, 8486
	stb_erp A, 0xFB
	lda_dri XBC, 0x07, 0xE8, 0xE4
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x5
	ld bc, wa
	lda_d16 xde, 8487
	stb_erp A, 0xFB
	lda_dri XBC, 0x07, 0xE8, 0xE4
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x5
	lda_d16 xbc, 8488
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x5
	lda_d16 xbc, 8489
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x5
	lda_d16 xbc, 8490
	stib_ind 0x07, 0xE4, 0xE0, 0xFF
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0xC0
	jr c, VoiceState_FullReset_Phase2_Body

VoiceState_FullReset_Phase3:
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0x1B
	jr nc, VoiceState_FullReset_Phase3_InitSlots

VoiceState_FullReset_Phase3_ClearLoop:
	ldb c, 0x0
	cp c, 0x1B
	jr nc, VoiceState_FullReset_Phase3_ClearNext

VoiceState_FullReset_Phase3_ClearInner:
	ld a, c
	extz wa
	ld hl, wa
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x1B
	lda_d16 xde, 7757
	exts xwa
	add xwa, xde
	ld de, hl
	extz xde
	add xde, xwa
	ld (xde), 0xFF
	inc 1, c
	cp c, 0x1B
	jr c, VoiceState_FullReset_Phase3_ClearInner

VoiceState_FullReset_Phase3_ClearNext:
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0x1B
	jr c, VoiceState_FullReset_Phase3_ClearLoop

VoiceState_FullReset_Phase3_InitSlots:
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0xC0
	jr nc, VoiceState_FullReset_Phase3_Return

VoiceState_FullReset_Phase3_InitBody:
	stb_erp A, 0xFB
	ldb_erp A, 0xF8
	extz iz
	stb_erp A, 0xFB
	extz wa
	calr Quad_Decode_A_To_L
	ld c, l
	extz bc
	ld wa, iz
	ld de, bc
	ldw bc, 0x1A
	calr VoiceSlot_UpdateNoteSource
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0xC0
	jr c, VoiceState_FullReset_Phase3_InitBody

VoiceState_FullReset_Phase3_Return:
	pop xiz
	ret

NoteSource_SelectRow:
	lda_d16 xbc, 8459
	and wa, 0x3
	cps wa, 3
	jr z, NoteSource_SelectRow_Case3
	cps wa, 2
	jr z, NoteSource_SelectRow_Case2
	cps wa, 1
	jr z, NoteSource_SelectRow_Case1
	cps wa, 0
	ret nz
	ld l, (xbc)
	jr NoteSource_SelectRow_Return

NoteSource_SelectRow_Case1:
	ld l, (xbc + 4)
	jr NoteSource_SelectRow_Return

NoteSource_SelectRow_Case2:
	ld l, (xbc + 8)
	cp l, 0xC0
	ret ule
	ld l, (xbc + 4)
	jr NoteSource_SelectRow_Return

NoteSource_SelectRow_Case3:
	ld l, (xbc + 8)

NoteSource_SelectRow_Return:
	ret

VoiceSlot_Assign:
	dec 8, xsp
	pushw_erp 0xFA
	ld (xsp + 4), e
	ld (xsp + 6), c
	ld (xsp + 8), a
	andmi8 (xsp + 4), 0x3F
	cp (xsp + 6), 0x40
	jr nc, VoiceSlot_Assign_NoMatch
	cp (xsp + 8), 0x1A
	jr c, VoiceSlot_Assign_Search

VoiceSlot_Assign_NoMatch:
	ld a, (xsp + 4)
	extz wa
	sll wa, 8
	ld hl, wa
	or hl, 0xFF
	jrl VoiceSlot_Assign_Return

VoiceSlot_Assign_Search:
	ld a, (xsp + 4)
	and a, 0x1F
	extz wa
	lda_24 xbc, 0x00f48c
	ldb_sri A, 0x07, 0xE4, 0xE0
	ldb_erp A, 0xFA
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x00f4ac
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld (xsp + 2), a
	ld a, (xsp + 6)
	extz wa
	muls wa, 0xC
	lda_d16 xbc, 9446
	stb_dri A, 0x07, 0xE4, 0xE0
	stb_erp A, 0xFA
	extz wa
	inc 8, wa
	ldb_sri A, 0x07, 0xE4, 0xE0
	ldb_erp A, 0xFB
	cp_erpb 0xFB, 0xC0
	jr nc, VoiceSlot_Assign_FallbackFB
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x5
	lda_d16 xbc, 8486
	stb_dri A, 0x07, 0xE4, 0xE0
	ld a, (xbc + 2)
	cp a, (xsp + 8)
	jr nz, VoiceSlot_Assign_FallbackFB
	ld a, (xbc + 3)
	cp a, (xsp + 2)
	jr nz, VoiceSlot_Assign_FallbackFB
	stb_erp A, 0xFB
	ld e, a
	extz de
	stb_erp A, 0xFA
	ld c, a
	extz bc
	ld wa, de
	calr SlotPair_Decode_C_To_L
	ld c, l
	extz bc
	ld a, (xsp + 4)
	set 7, a
	extz wa
	sll wa, 8
	ld hl, wa
	or hl, bc
	jrl VoiceSlot_Assign_Return

VoiceSlot_Assign_FallbackFB:
	bitm 5, (xsp + 4)
	jr z, VoiceSlot_Assign_TryNoteSourceTable
	stb_erp A, 0xFA
	extz wa
	calr NoteSource_SelectRow
	ldb_erp L, 0xFB
	stb_erp A, 0xFB
	cp a, 0xC0
	jr nc, VoiceSlot_Assign_FallbackFB_Inactive
	stb_erp A, 0xFB
	ld l, a
	extz hl
	ld a, (xsp + 8)
	ld c, a
	extz bc
	ld a, (xsp + 2)
	ld e, a
	extz de
	ld wa, hl
	calr VoiceSlot_UpdateNoteSource
	ld a, (xsp + 6)
	ld l, a
	extz hl
	stb_erp A, 0xFA
	ld c, a
	extz bc
	stb_erp A, 0xFB
	ld e, a
	extz de
	ld wa, hl
	calr VoiceState_SwapSlot_Guarded
	stb_erp A, 0xFB
	ld e, a
	extz de
	stb_erp A, 0xFA
	ld c, a
	extz bc
	ld wa, de
	calr SlotPair_Decode_C_To_L
	jrl VoiceSlot_Assign_PackResult

VoiceSlot_Assign_FallbackFB_Inactive:
	ldb l, 0xFF
	jrl VoiceSlot_Assign_PackResult

VoiceSlot_Assign_TryNoteSourceTable:
	ld a, (xsp + 2)
	extz wa
	ld de, wa
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x1B
	lda_d16 xbc, 7757
	exts xwa
	add xwa, xbc
	ld bc, de
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	ldb_erp A, 0xFB
	cp_erpb 0xFB, 0xC0
	jr nc, VoiceSlot_Assign_FallbackFA
	ld a, (xsp + 6)
	ld l, a
	extz hl
	stb_erp A, 0xFA
	ld c, a
	extz bc
	stb_erp A, 0xFB
	ld e, a
	extz de
	ld wa, hl
	calr VoiceState_SwapSlot_Guarded
	stb_erp A, 0xFB
	ld e, a
	extz de
	stb_erp A, 0xFA
	ld c, a
	extz bc
	ld wa, de
	calr SlotPair_Decode_C_To_L
	setm 7, (xsp + 4)
	jr VoiceSlot_Assign_PackResult

VoiceSlot_Assign_FallbackFA:
	stb_erp A, 0xFA
	extz wa
	calr NoteSource_SelectRow
	ldb_erp L, 0xFB
	stb_erp A, 0xFB
	cp a, 0xC0
	jr nc, VoiceSlot_Assign_FA_Inactive
	stb_erp A, 0xFB
	ld l, a
	extz hl
	ld a, (xsp + 8)
	ld c, a
	extz bc
	ld a, (xsp + 2)
	ld e, a
	extz de
	ld wa, hl
	calr VoiceSlot_UpdateNoteSource
	ld a, (xsp + 6)
	ld l, a
	extz hl
	stb_erp A, 0xFA
	ld c, a
	extz bc
	stb_erp A, 0xFB
	ld e, a
	extz de
	ld wa, hl
	calr VoiceState_SwapSlot_Guarded
	stb_erp A, 0xFB
	ld e, a
	extz de
	stb_erp A, 0xFA
	ld c, a
	extz bc
	ld wa, de
	calr SlotPair_Decode_C_To_L
	jr VoiceSlot_Assign_PackResult

VoiceSlot_Assign_FA_Inactive:
	ldb l, 0xFF

VoiceSlot_Assign_PackResult:
	ld c, l
	extz bc
	ld a, (xsp + 4)
	extz wa
	sll wa, 8
	ld hl, wa
	or hl, bc

VoiceSlot_Assign_Return:
	popw_erp 0xFA
	inc 8, xsp
	ret

VoiceState_OpaqueData1:
	.byte 0xef, 0x6a, 0xb7, 0x43, 0x87, 0x3c, 0x3f, 0xc9
	.byte 0xcf, 0x40, 0x67, 0x0f, 0x87, 0x21, 0xd8, 0x12
	.byte 0xd8, 0xee, 0x08, 0xd8, 0x8b, 0xdb, 0xce, 0xff
	.byte 0x00, 0x68, 0x12, 0xd8, 0x12, 0x1e, 0x71, 0xfb
	.byte 0x87, 0x21, 0xd8, 0x12, 0xd8, 0xee, 0x08, 0xd8
	.byte 0x8b, 0xdb, 0xce, 0xff, 0x00, 0xef, 0x62, 0x0e
	.byte 0xef, 0x6c, 0xb7, 0x43, 0xbf, 0x02, 0x41, 0x87
	.byte 0x21, 0xd8, 0x12, 0xcd, 0x8b, 0xd9, 0x12, 0x1e
	.byte 0xbe, 0xff, 0x8f, 0x02, 0x21, 0xc9, 0x8f, 0xdb
	.byte 0x12, 0x87, 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0x8f
	.byte 0x08, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0xdb, 0x88
	.byte 0x1e, 0xa7, 0xfd, 0xef, 0x64, 0x0f, 0x02, 0x00
	.byte 0xbf, 0xf4, 0x37, 0xd7, 0xfa, 0x04, 0xcd, 0x06
	.byte 0xbf, 0x08, 0x45, 0x8f, 0x08, 0xc3, 0xbf, 0x06
	.byte 0x43, 0xd8, 0x12, 0xd8, 0x09, 0x0c, 0x00, 0xf1
	.byte 0xe6, 0x24, 0x31, 0xe8, 0x13, 0xe9, 0x80, 0xbf
	.byte 0x02, 0x60, 0xf1, 0x6b, 0x28, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xc7, 0xfb, 0xa8, 0xc7, 0xfb, 0xdc, 0x6f
	.byte 0x6f, 0xc7, 0xfb, 0x89, 0xd8, 0x12, 0xd8, 0x89
	.byte 0xd9, 0x60, 0xaf, 0x02, 0x20, 0xc3, 0x07, 0xe0
	.byte 0xe4, 0x25, 0xcd, 0x89, 0xc9, 0xcf, 0xc0, 0x6f
	.byte 0x4f, 0xcd, 0x89, 0xd8, 0x12, 0xd8, 0x09, 0x05
	.byte 0x00, 0xf1, 0x29, 0x21, 0x31, 0xc3, 0x07, 0xe4
	.byte 0xe0, 0x21, 0xd8, 0x12, 0xf2, 0xec, 0xf4, 0x00
	.byte 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x21, 0xc7, 0xfa
	.byte 0x99, 0x8f, 0x08, 0xc1, 0x8f, 0x06, 0xf1, 0x6e
	.byte 0x27, 0xda, 0x12, 0xc7, 0xfb, 0x89, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xda, 0x88, 0x1e, 0x47, 0xf6, 0xcf
	.byte 0x8b, 0xd9, 0x12, 0xc7, 0xfa, 0x89, 0xd8, 0x12
	.byte 0xd8, 0xee, 0x08, 0xd8, 0x8a, 0xd9, 0xe2, 0xaf
	.byte 0x0a, 0x20, 0xf5, 0xe1, 0x52, 0xbf, 0x0a, 0x60
	.byte 0xc7, 0xfb, 0x61, 0xc7, 0xfb, 0xdc, 0x67, 0x91
	.byte 0xaf, 0x0a, 0x20, 0xb0, 0x02, 0xff, 0xff, 0xf1
	.byte 0x6b, 0x28, 0x33, 0xd7, 0xfa, 0x05, 0xbf, 0x0c
	.byte 0x37, 0x0e

Voice_BuildOutputList:
	lda xsp, (xsp - 12)
	pushw_erp 0xFA
	cpl e
	ld (xsp + 8), e
	and c, (xsp + 8)
	ld (xsp + 6), c
	extz wa
	muls wa, 0x1B
	lda_d16 xbc, 7757
	exts xwa
	add xwa, xbc
	ld (xsp + 2), xwa
	lda_d16 xwa, 10217
	ld (xsp + 10), xwa
	ldib_erp 0xFA, 0
	cp_erpb 0xFA, 0x1B
	jr nc, Voice_BuildOutputList_Return

Voice_BuildOutputList_Loop:
	stb_erp A, 0xFA
	ld c, a
	extz bc
	ld xwa, (xsp + 2)
	ldb_sri E, 0x07, 0xE0, 0xE4
	ld a, e
	cp a, 0xC0
	jr nc, Voice_BuildOutputList_Next
	stb_erp A, 0xFA
	extz wa
	lda_24 xbc, 0x00f4ec
	ldb_sri A, 0x07, 0xE4, 0xE0
	ldb_erp A, 0xFB
	and a, (xsp + 8)
	cp a, (xsp + 6)
	jr nz, Voice_BuildOutputList_Next
	stb_erp A, 0xFB
	and a, 0x1F
	extz wa
	lda_24 xbc, 0x00f48c
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld a, e
	extz wa
	extz bc
	calr SlotPair_Decode_C_To_L
	ld c, l
	extz bc
	stb_erp A, 0xFB
	extz wa
	sll wa, 8
	ld de, wa
	or de, bc
	ld xwa, (xsp + 10)
	stw_dpi DE, 0xE1
	ld (xsp + 10), xwa

Voice_BuildOutputList_Next:
	inc1b_erp 0xFA
	cp_erpb 0xFA, 0x1B
	jr c, Voice_BuildOutputList_Loop

Voice_BuildOutputList_Return:
	ld xwa, (xsp + 10)
	ldw (xwa), 0xFFFF
	lda_d16 xhl, 10217
	popw_erp 0xFA
	lda xsp, (xsp + 12)
	ret

VoiceState_OpaqueData2:
	.byte 0x2e, 0xcd, 0x06, 0xcd, 0xc3, 0xd8, 0x12, 0xd8
	.byte 0x09, 0x1b, 0x00, 0xf1, 0x4d, 0x1e, 0x33, 0xf3
	.byte 0x07, 0xec, 0xe0, 0x34, 0xf1, 0xed, 0x28, 0x33
	.byte 0x22, 0x00, 0xca, 0xcf, 0x1b, 0x7f, 0x8d, 0x00
	.byte 0xca, 0x89, 0xd8, 0x12, 0xc3, 0x07, 0xf0, 0xe0
	.byte 0x21, 0xc7, 0xe2, 0x99, 0xc9, 0xcf, 0xc0, 0x6f
	.byte 0x74, 0xca, 0x89, 0xd8, 0x12, 0xf2, 0xec, 0xf4
	.byte 0x00, 0x35, 0xc3, 0x07, 0xf4, 0xe0, 0x24, 0xcc
	.byte 0x89, 0xcd, 0xc1, 0xcb, 0xf1, 0x6e, 0x5e, 0xc7
	.byte 0xe2, 0x89, 0xd8, 0x12, 0xd8, 0x09, 0x05, 0x00
	.byte 0xf1, 0x2a, 0x21, 0x35, 0xc3, 0x07, 0xf4, 0xe0
	.byte 0x21, 0xc7, 0xe6, 0x99, 0xc9, 0xcf, 0x40, 0x6f
	.byte 0x44, 0xc7, 0xe6, 0x89, 0xc7, 0xe2, 0x99, 0xcc
	.byte 0x89, 0xc9, 0xcc, 0x1f, 0xd8, 0x12, 0xf2, 0x8c
	.byte 0xf4, 0x00, 0x35, 0xc3, 0x07, 0xf4, 0xe0, 0x24
	.byte 0xc7, 0xe6, 0x89, 0xf5, 0xec, 0x41, 0xcc, 0x89
	.byte 0xd8, 0x12, 0xd8, 0x8e, 0xc7, 0xe2, 0x89, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x0c, 0x00, 0xf1, 0xe6, 0x24
	.byte 0x35, 0xe8, 0x13, 0xed, 0x80, 0xde, 0x8d, 0xed
	.byte 0x12, 0xe8, 0x85, 0x85, 0x21, 0xc7, 0xe2, 0x99
	.byte 0xc7, 0xe6, 0xf1, 0x6e, 0xd3, 0xca, 0x61, 0xca
	.byte 0xcf, 0x1b, 0x77, 0x73, 0xff, 0xb3, 0x00, 0xff
	.byte 0xf1, 0xed, 0x28, 0x33, 0x4e, 0x0e

Voice_AdvanceSlotIterator:
	dec 2, xsp
	push xiz
	ldb c, 0x30
	mul8rr c, a
	ld iz, bc
	ld (xsp + 4), iz
	addiw_da (xsp + 4), 0x30
	cp iz, (xsp + 4)
	jr nc, Voice_AdvanceSlotIterator_Return

Voice_AdvanceSlotIterator_Loop:
	ld wa, iz
	mul wa, 0x5
	lda_d16 xbc, 8490
	extz xwa
	add xwa, xbc
	cp (xwa), 0x40
	jr ule, Voice_AdvanceSlotIterator_Next
	ld wa, iz
	mul wa, 0x5
	lda_d16 xbc, 8488
	extz xwa
	add xwa, xbc
	cp (xwa), 0x1A
	jr z, Voice_AdvanceSlotIterator_Next
	stb_erp A, 0xF8
	extz wa
	ldw_erp WA, 0xFA
	stb_erp A, 0xF8
	extz wa
	calr Quad_Decode_A_To_L
	ld c, l
	extz bc
	stw_erp WA, 0xFA
	ld de, bc
	ldw bc, 0x1A
	calr VoiceSlot_UpdateNoteSource

Voice_AdvanceSlotIterator_Next:
	inc 1, iz
	cp iz, (xsp + 4)
	jr c, Voice_AdvanceSlotIterator_Loop

Voice_AdvanceSlotIterator_Return:
	pop xiz
	inc 2, xsp
	ret

DList_Unlink_SelfLink:
	ld xde, (xwa)
	ld xbc, (xwa + 4)
	ld (xbc), xde
	ld (xde + 4), xbc
	ld (xwa), xwa
	ld (xwa + 4), xwa
	ret

DList_InsertAfter_Offsets0:
	ld xhl, (xwa)
	ld xde, (xwa + 4)
	ld (xde), xhl
	ld (xhl + 4), xde
	ld xde, (xbc + 4)
	ld (xde), xwa
	ld (xbc + 4), xwa
	ld (xwa), xbc
	ld (xwa + 4), xde
	ret

VoiceNode_PriorityList_Update:
	dec 6, xsp
	push xiz
	ld (xsp + 4), e
	ld (xsp + 6), xbc
	ld xiz, xwa
	ld xde, (xiz + 29)
	ld c, (xiz + 33)
	ld a, c
	extz wa
	sla wa, 2
	inc 2, wa
	cpl_sri_mr XIZ, 0x07, 0xE8, 0xE0
	jr nz, VoiceNode_PriorityList_InsertOrLink
	cp (xiz), xiz
	jr z, VoiceNode_PriorityList_SelfLink
	ld a, c
	extz wa
	sla wa, 2
	ld bc, wa
	inc 2, bc
	ld xwa, (xiz)
	stl_dri XWA, 0x07, 0xE8, 0xE4
	jr VoiceNode_PriorityList_InsertOrLink

VoiceNode_PriorityList_SelfLink:
	ld a, c
	extz wa
	sla wa, 2
	ld bc, wa
	inc 2, bc
	lds32 xwa, 0
	stl_dri XWA, 0x07, 0xE8, 0xE4

VoiceNode_PriorityList_InsertOrLink:
	ld a, (xsp + 4)
	extz wa
	sla wa, 2
	ld bc, wa
	inc 2, bc
	ld xwa, (xsp + 6)
	ld_sril3 XWA, 0x07, 0xE0, 0xE4
	or xwa, xwa
	jr nz, VoiceNode_PriorityList_Insert
	ld a, (xsp + 4)
	extz wa
	sla wa, 2
	ld bc, wa
	inc 2, bc
	ld xwa, (xsp + 6)
	stl_dri XIZ, 0x07, 0xE0, 0xE4
	ld xwa, xiz
	calr DList_Unlink_SelfLink
	jr VoiceNode_PriorityList_Return

VoiceNode_PriorityList_Insert:
	ld a, (xsp + 4)
	extz wa
	sla wa, 2
	ld de, wa
	inc 2, de
	ld xwa, xiz
	ld xbc, (xsp + 6)
	ld_sril3 XBC, 0x07, 0xE4, 0xE8
	calr DList_InsertAfter_Offsets0

VoiceNode_PriorityList_Return:
	ld xwa, (xsp + 6)
	ld (xiz + 29), xwa
	ld a, (xsp + 4)
	ld (xiz + 33), a
	pop xiz
	inc 6, xsp
	ret

DList_Unlink_SelfLink_Offsets8:
	ld xde, (xwa + 8)
	ld xbc, (xwa + 12)
	ld (xbc + 8), xde
	ld (xde + 12), xbc
	ld (xwa + 8), xwa
	ld (xwa + 12), xwa
	ret

DList_InsertAfter_Offsets8:
	ld xhl, (xwa + 8)
	ld xde, (xwa + 12)
	ld (xde + 8), xhl
	ld (xhl + 12), xde
	ld xde, (xbc + 12)
	ld (xde + 8), xwa
	ld (xbc + 12), xwa
	ld (xwa + 8), xbc
	ld (xwa + 12), xde
	ret

VoiceNode_SecondList_Update:
	dec 6, xsp
	push xiz
	ld (xsp + 4), e
	ld (xsp + 6), xbc
	ld xiz, xwa
	ld xde, (xiz + 24)
	ld c, (xiz + 28)
	ld a, c
	extz wa
	sla wa, 2
	inc 4, wa
	cpl_sri_mr XIZ, 0x07, 0xE8, 0xE0
	jr nz, VoiceNode_SecondList_InsertOrLink
	cp (xiz + 8), xiz
	jr z, VoiceNode_SecondList_SelfLink
	ld a, c
	extz wa
	sla wa, 2
	ld bc, wa
	inc 4, bc
	ld xwa, (xiz + 8)
	stl_dri XWA, 0x07, 0xE8, 0xE4
	jr VoiceNode_SecondList_InsertOrLink

VoiceNode_SecondList_SelfLink:
	ld a, c
	extz wa
	sla wa, 2
	ld bc, wa
	inc 4, bc
	lds32 xwa, 0
	stl_dri XWA, 0x07, 0xE8, 0xE4

VoiceNode_SecondList_InsertOrLink:
	ld a, (xsp + 4)
	extz wa
	sla wa, 2
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 6)
	ld_sril3 XWA, 0x07, 0xE0, 0xE4
	or xwa, xwa
	jr nz, VoiceNode_SecondList_Insert
	ld a, (xsp + 4)
	extz wa
	sla wa, 2
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 6)
	stl_dri XIZ, 0x07, 0xE0, 0xE4
	ld xwa, xiz
	calr DList_Unlink_SelfLink_Offsets8
	jr VoiceNode_SecondList_Return

VoiceNode_SecondList_Insert:
	ld a, (xsp + 4)
	extz wa
	sla wa, 2
	ld de, wa
	inc 4, de
	ld xwa, xiz
	ld xbc, (xsp + 6)
	ld_sril3 XBC, 0x07, 0xE4, 0xE8
	calr DList_InsertAfter_Offsets8

VoiceNode_SecondList_Return:
	ld xwa, (xsp + 6)
	ld (xiz + 24), xwa
	ld a, (xsp + 4)
	ld (xiz + 28), a
	pop xiz
	inc 6, xsp
	ret

DList_Unlink_SelfLink_Offsets16:
	ld xde, (xwa + 16)
	ld xbc, (xwa + 20)
	ld (xbc + 16), xde
	ld (xde + 20), xbc
	ld (xwa + 16), xwa
	ld (xwa + 20), xwa
	ret

DList_InsertAfter_Offsets16:
	ld xhl, (xwa + 16)
	ld xde, (xwa + 20)
	ld (xde + 16), xhl
	ld (xhl + 20), xde
	ld xde, (xbc + 20)
	ld (xde + 16), xwa
	ld (xbc + 20), xwa
	ld (xwa + 16), xbc
	ld (xwa + 20), xde
	ret

VoiceNode_Activate:
	push xiz
	ld xiz, xwa
	bitm 0, (xiz + 34)
	jr nz, VoiceNode_Activate_Return
	ld xwa, (xiz + 29)
	cp (xwa + 1), 0x0
	jr z, VoiceNode_Activate_InsertLists
	ld xwa, (xiz + 29)
	decm8 1, (xwa + 1)

VoiceNode_Activate_InsertLists:
	lda_d16 xwa, 4907
	ld xbc, xwa
	ld xwa, xiz
	lds de, 6
	calr VoiceNode_PriorityList_Update
	lda_d16 xwa, 5249
	ld xbc, xwa
	ld xwa, xiz
	lds de, 1
	calr VoiceNode_SecondList_Update
	ld xwa, xiz
	calr DList_Unlink_SelfLink_Offsets16
	ld (xiz + 34), 0x1
	ld (xiz + 37), 0x0
	ld xwa, (xiz + 29)
	ld xbc, xwa
	ld a, (xwa + 1)
	cp a, (xbc)
	jr nc, VoiceNode_Activate_Return
	ld xwa, (xiz + 29)
	incm8 1, (xwa + 1)

VoiceNode_Activate_Return:
	pop xiz
	ret

VoiceNode_BeginRelease:
	ld c, (xwa + 34)
	and c, 0x3
	ret nz
	andmi8 (xwa + 34), 0xF3
	setm 1, (xwa + 34)
	ld xbc, xwa
	ld xde, (xwa + 29)
	ld xwa, xbc
	ld xbc, xde
	lds de, 6
	calr VoiceNode_PriorityList_Update
	ret

VoiceNode_UpdateEnvState:
	bitm 7, (xwa + 34)
	ret nz
	cp (xwa + 37), 0x80
	jr c, VoiceNode_BeginRelease
	bitm 3, (xwa + 34)
	ret z
	resm 3, (xwa + 34)
	setm 2, (xwa + 34)
	ld c, (xwa + 38)
	ld e, c
	extz de
	ld xbc, xwa
	ld xhl, (xwa + 29)
	ld xwa, xbc
	ld xbc, xhl
	calr VoiceNode_PriorityList_Update
	ret

ToneGen_EmitCommandLoop:
	dec 4, xsp
	push xiz
	ld (xsp + 6), a
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x4
	jr nc, ToneGen_EmitCommandLoop_PhaseA

ToneGen_EmitCommandLoop_FindStart:
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	lda_d16 xbc, 10542
	cpiw_sri 0x07, 0xE4, 0xE0, 0x00, 0x00
	jr nz, ToneGen_EmitCommandLoop_PhaseA
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x4
	jr c, ToneGen_EmitCommandLoop_FindStart

ToneGen_EmitCommandLoop_PhaseA:
	cp (xsp + 4), 0x4
	jr nc, ToneGen_EmitCommandLoop_PhaseB
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x40
	jr nc, ToneGen_EmitCommandLoop_PhaseB

ToneGen_EmitCommandLoop_PhaseA_Body:
	res_dd8 7, 0x18
	ld a, (xsp + 4)
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xa200
	jr __jrt_nop_021F26
__jrt_nop_021F26:

ToneGen_EmitCommandLoop_PhaseA_Nop:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld a, (xsp + 4)
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xa280
	jr __jrt_nop_021F47
__jrt_nop_021F47:

ToneGen_EmitCommandLoop_PhaseA_Nop2:
	nop
	nop
	nop
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x40
	jr c, ToneGen_EmitCommandLoop_PhaseA_Body

ToneGen_EmitCommandLoop_PhaseB:
	cp (xsp + 4), 0x4
	jr nc, ToneGen_EmitCommandLoop_PhaseC
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x40
	jr nc, ToneGen_EmitCommandLoop_PhaseC

ToneGen_EmitCommandLoop_PhaseB_Body:
	res_dd8 7, 0x18
	ld a, (xsp + 4)
	add a, 0xC0
	extz wa
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x0000
	jr __jrt_nop_021F80
__jrt_nop_021F80:

ToneGen_EmitCommandLoop_PhaseB_Nop:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld a, (xsp + 4)
	extz wa
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x7e00
	jr __jrt_nop_021F9D
__jrt_nop_021F9D:

ToneGen_EmitCommandLoop_PhaseB_Nop2:
	nop
	nop
	nop
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x40
	jr c, ToneGen_EmitCommandLoop_PhaseB_Body

ToneGen_EmitCommandLoop_PhaseC:
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x12
	jrl nc, ChanStruct_Init_Loop

CmdTable_InitEntry_Loop:
	cp (xsp + 6), 0x0
	jr nz, CmdTable_InitEntry_AltPtr
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x1E
	ld de, wa
	lda_d16 xhl, 4397
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x00f507
	ldb_sri A, 0x07, 0xE4, 0xE0
	lda_dri XBC, 0x07, 0xEC, 0xE8
	jr CmdTable_InitEntry_ZeroFields

CmdTable_InitEntry_AltPtr:
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x1E
	ld de, wa
	lda_d16 xhl, 4397
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x00f519
	ldb_sri A, 0x07, 0xE4, 0xE0
	lda_dri XBC, 0x07, 0xEC, 0xE8

CmdTable_InitEntry_ZeroFields:
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x1E
	lda_d16 xbc, 4398
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	ldb e, 0x0
	cps e, 7
	jr nc, CmdTable_InitEntry_Next

CmdTable_InitEntry_ZeroLoop:
	ld a, e
	extz wa
	sla wa, 2
	ld hl, wa
	inc 2, hl
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x1E
	lda_d16 xbc, 4397
	stb_dri A, 0x07, 0xE4, 0xE0
	lds32 xwa, 0
	stl_dri XWA, 0x07, 0xE4, 0xEC
	inc 1, e
	cps e, 7
	jr c, CmdTable_InitEntry_ZeroLoop

CmdTable_InitEntry_Next:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x12
	jrl c, CmdTable_InitEntry_Loop

ChanStruct_Init_Loop:
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x1B
	jrl nc, VoiceNode_Init_Loop

ChanStruct_Init_Entry:
	cp (xsp + 6), 0x0
	jr nz, ChanStruct_Init_Entry_AltPtr
	ld a, (xsp + 4)
	extz wa
	muls wa, 0xC
	ld de, wa
	lda_d16 xhl, 4937
	ld a, (xsp + 4)
	extz wa
	sla wa, 2
	lda_24 xbc, 0x00f52b
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	stl_dri XWA, 0x07, 0xEC, 0xE8
	jr ChanStruct_Init_ZeroSub

ChanStruct_Init_Entry_AltPtr:
	ld a, (xsp + 4)
	extz wa
	muls wa, 0xC
	ld de, wa
	lda_d16 xhl, 4937
	ld a, (xsp + 4)
	extz wa
	sla wa, 2
	lda_24 xbc, 0x00f597
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	stl_dri XWA, 0x07, 0xEC, 0xE8

ChanStruct_Init_ZeroSub:
	ldb e, 0x0
	cps e, 2
	jr nc, ChanStruct_Init_Next

ChanStruct_Init_ZeroLoop:
	ld a, e
	extz wa
	sla wa, 2
	ld hl, wa
	inc 4, hl
	ld a, (xsp + 4)
	extz wa
	muls wa, 0xC
	lda_d16 xbc, 4937
	stb_dri A, 0x07, 0xE4, 0xE0
	lds32 xwa, 0
	stl_dri XWA, 0x07, 0xE4, 0xEC
	inc 1, e
	cps e, 2
	jr c, ChanStruct_Init_ZeroLoop

ChanStruct_Init_Next:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x1B
	jrl c, ChanStruct_Init_Entry

VoiceNode_Init_Loop:
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x40
	jr nc, VoiceNode_Activate_All

VoiceNode_Init_Body:
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x27
	lda_d16 xbc, 5261
	stb_dri H, 0x07, 0xE4, 0xE0
	ld a, (xsp + 4)
	ld (xiz + 36), a
	ld (xiz), xiz
	ld (xiz + 4), xiz
	ld (xiz + 8), xiz
	ld (xiz + 12), xiz
	ld (xiz + 16), xiz
	ld (xiz + 20), xiz
	ld (xiz + 34), 0x0
	lda_d16 xwa, 4937
	ld (xiz + 24), xwa
	ld (xiz + 28), 0x1
	lda_d16 xwa, 4397
	ld (xiz + 29), xwa
	ld (xiz + 33), 0x6
	ld (xiz + 37), 0x0
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x40
	jr c, VoiceNode_Init_Body

VoiceNode_Activate_All:
	lda_d16 xiz, 5261
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x40
	jr nc, IntMask_Clear_Loop

VoiceNode_Activate_All_Loop:
	ld xwa, xiz
	calr VoiceNode_Activate
	lda xiz, (xiz + 39)
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x40
	jr c, VoiceNode_Activate_All_Loop

IntMask_Clear_Loop:
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x4
	jr nc, AudioState_Init_Return

IntMask_Clear_Body:
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	lda_d16 xbc, 10542
	stiw_ind 0x07, 0xE4, 0xE0, 0x00, 0x00
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	lda_d16 xbc, 10550
	stiw_ind 0x07, 0xE4, 0xE0, 0x00, 0x00
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x4
	jr c, IntMask_Clear_Body

AudioState_Init_Return:
	calr VoiceState_FullReset
	pop xiz
	inc 4, xsp
	ret

AudioTick_UpdateVoice:
	dec 6, xsp
	push xiz
	incdi8 1, 4392
	anddi8 4392, 3
	ldb_d8 a, 4392
	extz wa
	calr DAC_Write_Sample
	ldb_d8 a, 4392
	extz wa
	add wa, wa
	lda_d16 xbc, 10550
	ldw_sri DE, 0x07, 0xE4, 0xE0
	or de, hl
	ldb_d8 a, 4392
	extz wa
	ld hl, wa
	add hl, hl
	lda_d16 xix, 10542
	ldb_d8 a, 4392
	extz wa
	add wa, wa
	lda_d16 xbc, 10542
	ld (xsp + 4), de
	ldw_sri WA, 0x07, 0xE4, 0xE0
	xor (xsp + 4), wa
	ldw_sri WA, 0x07, 0xF0, 0xEC
	and (xsp + 4), wa
	ldb_d8 a, 4392
	extz wa
	add wa, wa
	lda_d16 xbc, 10542
	stw_dri DE, 0x07, 0xE4, 0xE0
	ldb_d8 a, 4392
	sll a, 4
	ld (xsp + 8), a
	extz wa
	muls wa, 0x27
	lda_d16 xbc, 5261
	stb_dri H, 0x07, 0xE4, 0xE0
	ldw (xsp + 6), 0x1
	cpw (xsp + 6), 0x0
	jr z, AudioTick_UpdateVoice_Return

AudioTick_UpdateVoice_SlotLoop:
	ld wa, (xsp + 4)
	and wa, (xsp + 6)
	jr z, AudioTick_UpdateVoice_DecayCheck
	bitm 0, (xiz + 34)
	jr nz, AudioTick_UpdateVoice_DecayCheck
	ld xwa, xiz
	calr VoiceNode_Activate
	ld a, (xsp + 8)
	extz wa
	call ToneGen_WriteNoteKey
	ld a, (xsp + 8)
	extz wa
	calr Voice_ScanSlots_ReassignSources
	jr AudioTick_UpdateVoice_Next

AudioTick_UpdateVoice_DecayCheck:
	ld a, (xiz + 34)
	and a, 0x81
	jr nz, AudioTick_UpdateVoice_Next
	ld a, (xsp + 8)
	extz wa
	add wa, 0x180
	calr DAC_Write_Sample
	and hl, 0x3FFF
	srl hl, 5
	ld a, l
	ld (xiz + 37), a
	cp (xiz + 37), 0x80
	jr nc, AudioTick_UpdateVoice_Next
	bitm 2, (xiz + 34)
	jr z, AudioTick_UpdateVoice_Next
	ld xwa, xiz
	calr VoiceNode_BeginRelease

AudioTick_UpdateVoice_Next:
	incm8 1, (xsp + 8)
	lda xiz, (xiz + 39)
	ld wa, (xsp + 6)
	add (xsp + 6), wa
	jr nz, AudioTick_UpdateVoice_SlotLoop

AudioTick_UpdateVoice_Return:
	ldb_d8 a, 4392
	extz wa
	calr Voice_AdvanceSlotIterator
	pop xiz
	inc 6, xsp
	ret

NoteChain_FindNode_A:
	ldda32 xde, 4933
	or xde, xde
	jr z, NoteChain_FindNode_A_Walk
	ldda32 xhl, 4933
	ret

NoteChain_FindNode_A_Walk:
	lda_d16 xde, 4397
	stb_dri B, 0xE9, 0xE2, 0x01
	ld xwa, (xwa)
	lda xhl, (xwa + 2)
	cp (xbc), 0xFF
	jr z, NoteChain_FindNode_NotFound

NoteChain_FindNode_A_Secondary:
	bitm 7, (xbc)
	jr z, NoteChain_FindNode_A_Primary
	ld a, (xbc)
	res 7, a
	ldb_erp A, 0xF0
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	or xwa, xwa
	jr z, NoteChain_FindNode_A_Advance
	stb_erp A, 0xF0
	extz wa
	sla wa, 2
	ld_sril3 XHL, 0x07, 0xE8, 0xE0
	ret

NoteChain_FindNode_A_Primary:
	ld a, (xbc)
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xEC, 0xE0
	or xwa, xwa
	jr z, NoteChain_FindNode_A_Advance
	ld a, (xbc)
	extz wa
	sla wa, 2
	ld_sril3 XHL, 0x07, 0xEC, 0xE0
	ret

NoteChain_FindNode_A_Advance:
	inc 1, xbc
	cp (xbc), 0xFF
	jr nz, NoteChain_FindNode_A_Secondary

NoteChain_FindNode_NotFound:
	lds32 xhl, 0
	ret

NoteChain_FindNode_B:
	inc 2, xwa
	ld xde, xwa
	lda_24 xwa, 0x00f603
	ld xbc, xwa
	cp (xbc), 0xFF
	jr z, NoteChain_FindNode_B_NotFound

NoteChain_FindNode_B_Walk:
	ld a, (xbc)
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	or xwa, xwa
	jr z, NoteChain_FindNode_B_Advance
	ld a, (xbc)
	extz wa
	sla wa, 2
	ld_sril3 XHL, 0x07, 0xE8, 0xE0
	ret

NoteChain_FindNode_B_Advance:
	inc 1, xbc
	cp (xbc), 0xFF
	jr nz, NoteChain_FindNode_B_Walk

NoteChain_FindNode_B_NotFound:
	lds32 xhl, 0
	ret

NoteOn_Dispatch:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 16), xwa
	ld xwa, (xsp + 16)
	bitm 6, (xwa + 6)
	jr nz, NoteOn_Dispatch_SlotLoop
	lds32 xwa, 0
	stda32 4393, xwa

NoteOn_Dispatch_SlotLoop:
	ld xwa, (xsp + 16)
	ld wa, (xwa)
	and wa, 0x1F00
	srl wa, 8
	ldb_erp A, 0xFB
	cp_erpb 0xFB, 0x1A
	jrl nc, NoteOn_Dispatch_AllInactive
	ld xwa, (xsp + 16)
	calr RingBuf_CheckOffset_ClearFlags
	stb_erp A, 0xFB
	extz wa
	muls wa, 0xC
	lda_d16 xbc, 4937
	exts xwa
	add xwa, xbc
	ld (xsp + 4), xwa
	ld (xsp + 12), 0x0
	cp (xsp + 12), 0x4
	jrl nc, NoteOn_Dispatch_Return

NoteOn_Dispatch_ProcessSlot:
	ld a, (xsp + 12)
	extz wa
	ld bc, wa
	inc 2, bc
	ld xwa, (xsp + 16)
	bit_dri 7, 0x07, 0xE0, 0xE4
	jrl z, NoteOn_Dispatch_SlotInactive
	ld a, (xsp + 12)
	extz wa
	ld bc, wa
	inc 2, bc
	ld xwa, (xsp + 16)
	ldb_sri A, 0x07, 0xE0, 0xE4
	and a, 0xF
	extz wa
	muls wa, 0x6
	lda_24 xbc, 0x00f633
	exts xwa
	add xwa, xbc
	ld (xsp + 8), xwa
	ld xbc, (xwa)
	ld xwa, (xsp + 4)
	calr NoteChain_FindNode_A
	ld xiz, xhl
	ld xwa, xiz
	or xwa, xwa
	jrl z, NoteOn_Dispatch_SlotNoNode
	ld a, (xiz + 36)
	ld (xsp + 14), a
	ld xwa, (xiz + 29)
	cp (xwa + 1), 0x0
	jr z, NoteOn_Dispatch_ActivateNode
	ld xwa, (xiz + 29)
	decm8 1, (xwa + 1)

NoteOn_Dispatch_ActivateNode:
	ld xwa, (xsp + 16)
	ld wa, (xwa)
	and wa, 0x7F
	ld (xiz + 35), a
	ld (xiz + 37), 0xFF
	ld xwa, (xsp + 8)
	ld a, (xwa + 5)
	ld (xiz + 38), a
	ld a, (xsp + 12)
	extz wa
	ld bc, wa
	inc 6, bc
	ld xwa, (xsp + 16)
	bit_dri 7, 0x07, 0xE0, 0xE4
	jr z, NoteOn_Dispatch_Retrigger
	ld (xiz + 34), 0x88
	ld a, (xsp + 14)
	and a, 0xF
	lds de, 1
	and a, 0xF
	jr z, NoteOn_Dispatch_RetriggerActive
	slla de

NoteOn_Dispatch_RetriggerActive:
	ld a, (xsp + 14)
	srl a, 4
	extz wa
	add wa, wa
	lda_d16 xbc, 10550
	or_sriw_mr DE, 0x07, 0xE4, 0xE0
	jr NoteOn_Dispatch_UpdateLists

NoteOn_Dispatch_Retrigger:
	ld (xiz + 34), 0x8
	ld a, (xsp + 14)
	and a, 0xF
	lds bc, 1
	and a, 0xF
	jr z, NoteOn_Dispatch_RetriggerMask
	slla bc

NoteOn_Dispatch_RetriggerMask:
	ld wa, bc
	cpl wa
	ld de, wa
	ld a, (xsp + 14)
	srl a, 4
	extz wa
	add wa, wa
	lda_d16 xbc, 10550
	and_sriw_mr DE, 0x07, 0xE4, 0xE0
	ld a, (xsp + 14)
	and a, 0xF
	lds de, 1
	and a, 0xF
	jr z, NoteOn_Dispatch_RetriggerOrMask
	slla de

NoteOn_Dispatch_RetriggerOrMask:
	ld a, (xsp + 14)
	srl a, 4
	extz wa
	add wa, wa
	lda_d16 xbc, 10542
	or_sriw_mr DE, 0x07, 0xE4, 0xE0

NoteOn_Dispatch_UpdateLists:
	ld xwa, (xsp + 8)
	ld e, (xwa + 4)
	ld xwa, xiz
	ld xbc, (xsp + 4)
	ld xbc, (xbc)
	calr VoiceNode_PriorityList_Update
	ld xwa, xiz
	ld xbc, (xsp + 4)
	lds de, 0
	calr VoiceNode_SecondList_Update
	ldda32 xwa, 4393
	or xwa, xwa
	jr z, NoteOn_Dispatch_SetGlobalHead
	ld xwa, xiz
	ldda32 xbc, 4393
	calr DList_InsertAfter_Offsets16
	jr NoteOn_Dispatch_AdvancePriority

NoteOn_Dispatch_SetGlobalHead:
	stda32 4393, xiz
	ld xwa, xiz
	calr DList_Unlink_SelfLink_Offsets16

NoteOn_Dispatch_AdvancePriority:
	ld xwa, (xiz + 29)
	ld xbc, xwa
	ld a, (xwa + 1)
	cp a, (xbc)
	jr nc, NoteOn_Dispatch_WalkNext
	ld xwa, (xiz + 29)
	incm8 1, (xwa + 1)
	jr NoteOn_Dispatch_WriteSlot

NoteOn_Dispatch_WalkNext:
	ld xwa, (xiz + 29)
	calr NoteChain_FindNode_B
	ld xiz, xhl
	ld xwa, xiz
	or xwa, xwa
	jr z, NoteOn_Dispatch_WriteSlot
	lda_d16 xwa, 4877
	ld xbc, xwa
	ld a, (xiz + 33)
	ld e, a
	extz de
	ld xwa, xiz
	calr VoiceNode_PriorityList_Update
	ld xwa, (xiz + 29)
	incm8 1, (xwa + 1)
	setm 4, (xiz + 34)

NoteOn_Dispatch_WriteSlot:
	ld a, (xsp + 14)
	extz wa
	calr Voice_ScanSlots_ReassignSources
	ld a, (xsp + 12)
	extz wa
	ld de, wa
	add de, 0xA
	ld xwa, (xsp + 16)
	ld c, (xsp + 14)
	lda_dri XHL, 0x07, 0xE0, 0xE8
	jr NoteOn_Dispatch_SlotNext

NoteOn_Dispatch_SlotNoNode:
	ld a, (xsp + 12)
	extz wa
	ld bc, wa
	add bc, 0xA
	ld xwa, (xsp + 16)
	stib_ind 0x07, 0xE0, 0xE4, 0xFF
	jr NoteOn_Dispatch_SlotNext

NoteOn_Dispatch_SlotInactive:
	ld a, (xsp + 12)
	extz wa
	ld bc, wa
	add bc, 0xA
	ld xwa, (xsp + 16)
	stib_ind 0x07, 0xE0, 0xE4, 0xFF

NoteOn_Dispatch_SlotNext:
	incm8 1, (xsp + 12)
	cp (xsp + 12), 0x4
	jrl c, NoteOn_Dispatch_ProcessSlot
	jr NoteOn_Dispatch_Return

NoteOn_Dispatch_AllInactive:
	ld (xsp + 12), 0x0
	cp (xsp + 12), 0x4
	jr nc, NoteOn_Dispatch_Return

NoteOn_Dispatch_AllInactive_Loop:
	ld a, (xsp + 12)
	extz wa
	ld bc, wa
	add bc, 0xA
	ld xwa, (xsp + 16)
	stib_ind 0x07, 0xE0, 0xE4, 0xFF
	incm8 1, (xsp + 12)
	cp (xsp + 12), 0x4
	jr c, NoteOn_Dispatch_AllInactive_Loop

NoteOn_Dispatch_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

VoiceSlot_Release:
	ld c, a
	ld a, c
	extz wa
	muls wa, 0x27
	lda_d16 xde, 5295
	res_dri 7, 0x07, 0xE8, 0xE0
	ld a, c
	and a, 0xF
	lds de, 1
	and a, 0xF
	jr z, VoiceSlot_Release_ApplyMask
	slla de

VoiceSlot_Release_ApplyMask:
	ld wa, de
	cpl wa
	ld hl, wa
	ld a, c
	srl a, 4
	extz wa
	add wa, wa
	lda_d16 xde, 10550
	and_sriw_mr HL, 0x07, 0xE8, 0xE0
	ld a, c
	extz wa
	muls wa, 0x27
	lda_d16 xbc, 5261
	exts xwa
	add xwa, xbc
	jrl VoiceNode_UpdateEnvState

VoiceSlot_NoteOff:
	push xiz
	cp a, 0x40
	jr nc, VoiceSlot_NoteOff_Return
	extz wa
	muls wa, 0x27
	lda_d16 xbc, 5261
	stb_dri H, 0x07, 0xE4, 0xE0
	ld xwa, xiz
	ld xbc, (xiz + 24)
	lds de, 1
	calr VoiceNode_SecondList_Update
	ld xwa, xiz
	calr VoiceNode_UpdateEnvState
	cp xiz, (xiz + 16)
	jr z, VoiceSlot_NoteOff_Return
	ld xwa, xiz
	calr DList_Unlink_SelfLink_Offsets16

VoiceSlot_NoteOff_Return:
	pop xiz
	ret

OutputBuf_Flush_A:
	ld xhl, xbc
	or xhl, xhl
	jr z, OutputBuf_Flush_A_Done
	ld xiy, xhl

OutputBuf_Flush_A_Loop:
	cp (xsp + 4), 0x0
	jr nz, OutputBuf_Flush_A_Emit
	cp (xiy + 35), e
	jr nz, OutputBuf_Flush_A_Next

OutputBuf_Flush_A_Emit:
	ld xix, (xwa)
	ld c, (xiy + 36)
	ld (xix), c
	lds32 xbc, 1
	add (xwa), xbc

OutputBuf_Flush_A_Next:
	ld xiy, (xiy + 8)
	cp xiy, xhl
	jr nz, OutputBuf_Flush_A_Loop

OutputBuf_Flush_A_Done:
	ld xwa, (xwa)
	ld (xwa), 0xFF
	retd 0x2

OutputBuf_Flush_B:
	dec 8, xsp
	push xiz
	ld (xsp + 8), xwa
	or xbc, xbc
	jr z, OutputBuf_Flush_B_Done
	ld xiz, xbc

OutputBuf_Flush_B_Loop:
	cp (xsp + 16), 0x0
	jr nz, OutputBuf_Flush_B_Emit
	cp (xiz + 35), e
	jr nz, OutputBuf_Flush_B_Next

OutputBuf_Flush_B_Emit:
	ld xwa, xiz
	ld xbc, (xiz + 24)
	lds de, 1
	calr VoiceNode_SecondList_Update
	ld xwa, xiz
	calr VoiceNode_UpdateEnvState
	ld xwa, (xsp + 8)
	ld xbc, (xwa)
	ld a, (xiz + 36)
	ld (xbc), a
	ld xwa, (xsp + 8)
	lds32 xbc, 1
	add (xwa), xbc
	cp xiz, (xiz + 16)
	jr z, OutputBuf_Flush_B_Done
	ld xwa, (xiz + 16)
	ld (xsp + 4), xwa
	ld xwa, xiz
	calr DList_Unlink_SelfLink_Offsets16
	ld xiz, (xsp + 4)
	jr OutputBuf_Flush_B_Emit

OutputBuf_Flush_B_Next:
	ld xiz, (xiz + 8)
	cp xiz, xbc
	jr nz, OutputBuf_Flush_B_Loop

OutputBuf_Flush_B_Done:
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	ld (xwa), 0xFF
	pop xiz
	inc 8, xsp
	retd 0x2

NoteOn_RoutePacket:
	lda xsp, (xsp - 16)
	push xiz
	ld bc, (xwa + 3)
	and bc, 0x7F
	ld (xsp + 14), c
	ld bc, (xwa + 1)
	and bc, 0x7F
	ld (xsp + 12), c
	lda xbc, (xwa + 5)
	ld (xsp + 16), xbc
	ld bc, (xwa + 3)
	and bc, 0x1F00
	jr z, NoteOn_RoutePacket_Targeted
	lda_d16 xiz, 5261
	ldb e, 0x0
	cp e, 0x40
	jr nc, NoteOn_RoutePacket_BroadcastDone

NoteOn_RoutePacket_BroadcastLoop:
	bitm 0, (xiz + 34)
	jr nz, NoteOn_RoutePacket_BroadcastNext
	ld xbc, (xsp + 16)
	lds32 xwa, 1
	add (xsp + 16), xwa
	ld a, (xiz + 36)
	ld (xbc), a

NoteOn_RoutePacket_BroadcastNext:
	lda xiz, (xiz + 39)
	inc 1, e
	cp e, 0x40
	jr c, NoteOn_RoutePacket_BroadcastLoop

NoteOn_RoutePacket_BroadcastDone:
	ld xwa, (xsp + 16)
	ld (xwa), 0xFF
	jrl NoteOn_RoutePacket_Return

NoteOn_RoutePacket_Targeted:
	ld bc, (xwa + 1)
	and bc, 0x1F00
	srl bc, 8
	ld l, c
	extz bc
	muls bc, 0xC
	lda_d16 xde, 4941
	exts xbc
	add xbc, xde
	ld (xsp + 4), xbc
	ld c, l
	extz bc
	muls bc, 0xC
	lda_d16 xde, 4945
	exts xbc
	add xbc, xde
	ld (xsp + 8), xbc
	cp l, 0x1A
	jrl nc, NoteOn_RoutePacket_InvalidChannel
	bitm 7, (xwa)
	jr z, NoteOn_RoutePacket_Targeted_SecondaryOnly
	ld wa, (xwa + 3)
	and wa, 0x7F
	jr z, NoteOn_RoutePacket_Targeted_NoteZero
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	or xwa, xwa
	jr z, NoteOn_RoutePacket_Targeted_Done
	ld xwa, (xsp + 4)
	ld xiz, (xwa)

NoteOn_RoutePacket_Targeted_Loop:
	ld a, (xsp + 12)
	ld e, a
	extz de
	ld a, (xsp + 14)
	extz wa
	pushw wa
	lda xwa, (xsp + 18)
	ld xbc, (xsp + 6)
	ld xbc, (xbc)
	calr OutputBuf_Flush_B
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	or xwa, xwa
	jr z, NoteOn_RoutePacket_Targeted_Done
	ld xwa, (xsp + 4)
	cp (xwa), xiz
	jr nz, NoteOn_RoutePacket_Targeted_Loop

NoteOn_RoutePacket_Targeted_Done:
	ld xwa, (xsp + 16)
	ld (xwa), 0xFF
	jrl NoteOn_RoutePacket_Return

NoteOn_RoutePacket_Targeted_NoteZero:
	ld a, (xsp + 12)
	ld e, a
	extz de
	ld a, (xsp + 14)
	extz wa
	pushw wa
	lda xwa, (xsp + 18)
	ld xbc, (xsp + 6)
	ld xbc, (xbc)
	calr OutputBuf_Flush_B
	jrl NoteOn_RoutePacket_Return

NoteOn_RoutePacket_Targeted_SecondaryOnly:
	bitm 6, (xwa)
	jr z, NoteOn_RoutePacket_Targeted_BothLists_BitB
	ld a, (xsp + 12)
	ld e, a
	extz de
	ld a, (xsp + 14)
	extz wa
	pushw wa
	lda xwa, (xsp + 18)
	ld xbc, (xsp + 10)
	ld xbc, (xbc)
	calr OutputBuf_Flush_A
	jr NoteOn_RoutePacket_Return

NoteOn_RoutePacket_Targeted_BothLists_BitB:
	ld bc, (xwa + 3)
	bit 7, bc
	jr z, NoteOn_RoutePacket_Targeted_PrimaryOnly_BitA
	ld a, (xsp + 12)
	ld e, a
	extz de
	ld a, (xsp + 14)
	extz wa
	pushw wa
	lda xwa, (xsp + 18)
	ld xbc, (xsp + 6)
	ld xbc, (xbc)
	calr OutputBuf_Flush_A
	ld a, (xsp + 12)
	ld e, a
	extz de
	ld a, (xsp + 14)
	extz wa
	pushw wa
	lda xwa, (xsp + 18)
	ld xbc, (xsp + 10)
	ld xbc, (xbc)
	calr OutputBuf_Flush_A
	jr NoteOn_RoutePacket_Return

NoteOn_RoutePacket_Targeted_PrimaryOnly_BitA:
	ld wa, (xwa + 1)
	bit 7, wa
	jr z, NoteOn_RoutePacket_Targeted_SecondaryOnly_B
	ld a, (xsp + 12)
	ld e, a
	extz de
	ld a, (xsp + 14)
	extz wa
	pushw wa
	lda xwa, (xsp + 18)
	ld xbc, (xsp + 6)
	ld xbc, (xbc)
	calr OutputBuf_Flush_A
	jr NoteOn_RoutePacket_Return

NoteOn_RoutePacket_Targeted_SecondaryOnly_B:
	ld a, (xsp + 12)
	ld e, a
	extz de
	ld a, (xsp + 14)
	extz wa
	pushw wa
	lda xwa, (xsp + 18)
	ld xbc, (xsp + 10)
	ld xbc, (xbc)
	calr OutputBuf_Flush_A
	jr NoteOn_RoutePacket_Return

NoteOn_RoutePacket_InvalidChannel:
	ld xwa, (xsp + 16)
	ld (xwa), 0xFF

NoteOn_RoutePacket_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

VelocityQuantise_A:
	res 7, a
	cp a, (xbc)
	jr ule, VelocityQuantise_A_Level0
	cp a, (xbc + 1)
	jr ule, VelocityQuantise_A_Level1
	cp a, (xbc + 2)
	jr ule, VelocityQuantise_A_Level2
	ldb l, 0x3
	jr VelocityQuantise_A_Return

VelocityQuantise_A_Level2:
	ldb l, 0x2
	jr VelocityQuantise_A_Return

VelocityQuantise_A_Level1:
	ldb l, 0x1
	jr VelocityQuantise_A_Return

VelocityQuantise_A_Level0:
	ldb l, 0x0

VelocityQuantise_A_Return:
	ret

VelocityQuantise_B:
	res 7, a
	cp a, (xbc)
	jr ule, VelocityQuantise_B_Level0
	cp a, (xbc + 1)
	jr ule, VelocityQuantise_B_Level1
	cp a, (xbc + 2)
	jr ule, VelocityQuantise_B_Level2
	ldb l, 0x3
	jr VelocityQuantise_B_Return

VelocityQuantise_B_Level2:
	ldb l, 0x2
	jr VelocityQuantise_B_Return

VelocityQuantise_B_Level1:
	ldb l, 0x1
	jr VelocityQuantise_B_Return

VelocityQuantise_B_Level0:
	ldb l, 0x0

VelocityQuantise_B_Return:
	ret

VoiceDispatch_OpaqueData:
	.byte 0xd8, 0x12, 0xd8, 0x09, 0x47, 0x00, 0xf2, 0x8f
	.byte 0x30, 0x04, 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x20
	.byte 0xd8, 0xcc, 0xc0, 0x00, 0xd8, 0xcf, 0xc0, 0x00
	.byte 0x66, 0x1c, 0xd8, 0xcf, 0x80, 0x00, 0x66, 0x12
	.byte 0xd8, 0xcf, 0x40, 0x00, 0x66, 0x08, 0xd8, 0xd8
	.byte 0xb0, 0xfe, 0x27, 0x00, 0x68, 0x0a, 0x27, 0x01
	.byte 0x68, 0x06, 0x27, 0x02, 0x68, 0x02, 0x27, 0x03
	.byte 0x0e

Instrument_LookupProgram_HiNibble:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XBC, 0x07, 0xE8, 0xE4
	ld c, (xbc + 42)
	and c, 0xF0
	srl c, 4
	extz wa
	muls wa, 0x11F
	ld de, wa
	lda_24 xhl, 0x0413d5
	ld a, c
	extz wa
	lda_24 xbc, 0x011acf
	ldb_sri A, 0x07, 0xE4, 0xE0
	lda_dri XBC, 0x07, 0xEC, 0xE8
	ret

Instrument_LookupProgram_LoNibble:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XBC, 0x07, 0xE8, 0xE4
	ld c, (xbc + 42)
	and c, 0xF
	extz wa
	muls wa, 0x11F
	ld de, wa
	lda_24 xhl, 0x0413d5
	ld a, c
	extz wa
	lda_24 xbc, 0x011acf
	ldb_sri A, 0x07, 0xE4, 0xE0
	lda_dri XBC, 0x07, 0xEC, 0xE8
	ret

BitTest_Bit0_L:
	bit 0, a
	jr z, BitTest_Bit0_L_Clear
	ldb l, 0x1
	ret

BitTest_Bit0_L_Clear:
	ldb l, 0x0
	ret

BitTest_Mode2_L:
	bit 1, a
	jr z, BitTest_Mode2_L_Bit1Clear
	ldb l, 0x0
	ret

BitTest_Mode2_L_Bit1Clear:
	bit 0, a
	jr z, BitTest_Mode2_L_AllClear
	ldb l, 0x1
	ret

BitTest_Mode2_L_AllClear:
	ldb l, 0x0
	ret

BitTest_Bit0_L_v2:
	bit 0, a
	jr z, BitTest_Bit0_L_v2_Clear
	ldb l, 0x1
	ret

BitTest_Bit0_L_v2_Clear:
	ldb l, 0x0
	ret

BitTest_Mode2_L_v2:
	bit 1, a
	jr z, BitTest_Mode2_L_v2_Bit1Clear
	ldb l, 0x0
	ret

BitTest_Mode2_L_v2_Bit1Clear:
	bit 0, a
	jr z, BitTest_Mode2_L_v2_AllClear
	ldb l, 0x1
	ret

BitTest_Mode2_L_v2_AllClear:
	ldb l, 0x0
	ret

PitchBend_Process:
	ldw_da xde, 0x041343
	bit 1, de
	jr z, PitchBend_Process_Dispatch
	lds hl, 0
	jr PitchBend_Process_Return

PitchBend_Process_Dispatch:
	extz wa
	sub wa, 0x10
	cps wa, 0
	jr lt, PitchBend_Process_Fallback
	cp wa, 0x9
	jr gt, PitchBend_Process_Fallback
	add wa, wa
	lda_24 xix, 0x00f693
	ldw_sri WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0x022982
	jp_ind 8, 0x07, 0xF0, 0xE0

PitchBend_Process_JumpTable:
	.byte 0xdb
	.byte 0xa8
	.byte 0x68
	.byte 0x16

PitchBend_Process_Fallback:
	and c, 0xF
	ld a, c
	extz wa
	lda_24 xbc, 0x011acf
	ldb_sri L, 0x07, 0xE4, 0xE0
	exts hl
	sla hl, 8

PitchBend_Process_Return:
	ret

PitchBend_Saturate:
	ld hl, wa
	bit 15, wa
	jr z, PitchBend_Saturate_CompareLo
	cp hl, 0xC000
	jr le, PitchBend_Saturate_Clamp7FFF
	lds hl, 0
	jr PitchBend_Saturate_CompareLo

PitchBend_Saturate_Clamp7FFF:
	ldw hl, 0x7FFF

PitchBend_Saturate_CompareLo:
	ld a, c
	extz wa
	sla wa, 8
	add wa, 0x80
	cp hl, wa
	jr ge, PitchBend_Saturate_CompareHi
	ld a, c
	extz wa
	ld hl, wa
	sla hl, 8
	add hl, 0x80
	jr PitchBend_Saturate_Return

PitchBend_Saturate_CompareHi:
	ld a, e
	extz wa
	sla wa, 8
	add wa, 0x80
	cp hl, wa
	ret le
	ld a, e
	extz wa
	ld hl, wa
	sla hl, 8
	add hl, 0x80

PitchBend_Saturate_Return:
	ret

PitchBend_AlignLoop_Init:
	ld hl, wa
	jr PitchBend_AlignLoop_CheckSign

PitchBend_AlignLoop_CheckWrapped:
	cp hl, 0xC000
	jr le, PitchBend_AlignLoop_SubStep
	add hl, 0xC00
	jr PitchBend_AlignLoop_CheckSign

PitchBend_AlignLoop_SubStep:
	sub hl, 0xC00

PitchBend_AlignLoop_CheckSign:
	ld wa, hl
	bit 15, wa
	jr nz, PitchBend_AlignLoop_CheckWrapped
	jr PitchBend_AlignLoop_LoCheck

PitchBend_AlignLoop_AddStep:
	add hl, 0xC00

PitchBend_AlignLoop_LoCheck:
	ld a, c
	extz wa
	sla wa, 8
	add wa, 0x80
	cp hl, wa
	jr lt, PitchBend_AlignLoop_AddStep
	jr PitchBend_AlignLoop_HiCheck

PitchBend_AlignLoop_SubFinal:
	sub hl, 0xC00

PitchBend_AlignLoop_HiCheck:
	ld a, e
	extz wa
	sla wa, 8
	add wa, 0x80
	cp hl, wa
	jr gt, PitchBend_AlignLoop_SubFinal
	ret

ChanBitField_ExtractHi7:
	and bc, 0x7F00
	sra bc, 8
	ldb_sri L, 0x07, 0xE0, 0xE4
	ret

SlotParam_Write_Stride0F:
	extz de
	muls de, 0xF
	stb_dri A, 0x07, 0xE4, 0xE8
	ld (xwa + 15), xbc
	ormi16 (xwa + 1), 0x7000
	ld wa, (xbc)
	stw_da 0x0451ce, xwa
	ld wa, (xbc + 13)
	stda16 10558, xwa
	ret

SlotParam_Write_Stride0C:
	extz de
	muls de, 0xC
	stb_dri A, 0x07, 0xE4, 0xE8
	ld (xwa + 15), xbc
	ormi16 (xwa + 1), 0x5000
	ld wa, (xbc)
	stw_da 0x0451ce, xwa
	ld wa, (xbc + 10)
	stda16 10558, xwa
	ret

SlotParam_Write_Stride0D:
	extz de
	muls de, 0xD
	stb_dri A, 0x07, 0xE4, 0xE8
	ld (xwa + 15), xbc
	ormi16 (xwa + 1), 0x3000
	ld wa, (xbc)
	stw_da 0x0451ce, xwa
	stdi16 10558, 0
	ret

SlotParam_Write_Stride0A:
	extz de
	muls de, 0xA
	stb_dri A, 0x07, 0xE4, 0xE8
	ld (xwa + 15), xbc
	ormi16 (xwa + 1), 0x1000
	ld wa, (xbc)
	stw_da 0x0451ce, xwa
	stdi16 10558, 0
	ret

SlotParam_Write_Stride06:
	extz de
	muls de, 0x6
	stb_dri A, 0x07, 0xE4, 0xE8
	ld (xwa + 15), xbc
	ormi16 (xwa + 1), 0x4000
	ld wa, (xbc)
	stw_da 0x0451ce, xwa
	ld wa, (xbc + 4)
	stda16 10558, xwa
	ret

SlotParam_Write_Stride04_SLA:
	extz de
	sla de, 2
	stb_dri A, 0x07, 0xE4, 0xE8
	ld (xwa + 15), xbc
	ld wa, (xbc)
	stw_da 0x0451ce, xwa
	stdi16 10558, 0
	ret

SaturateS16_WA:
	ld bc, wa
	bit 15, bc
	jr z, SaturateS16_WA_Return
	cp wa, 0xC000
	jr ule, SaturateS16_WA_Clamp7FFF
	lds wa, 0
	jr SaturateS16_WA_Return

SaturateS16_WA_Clamp7FFF:
	ldw wa, 0x7FFF

SaturateS16_WA_Return:
	ld hl, wa
	ret

ClampS16_WA_To_DEBC:
	cp wa, bc
	jr le, ClampS16_WA_To_DEBC_CheckLo
	ld wa, bc
	jr ClampS16_WA_To_DEBC_Return

ClampS16_WA_To_DEBC_CheckLo:
	cp wa, de
	jr ge, ClampS16_WA_To_DEBC_Return
	ld wa, de

ClampS16_WA_To_DEBC_Return:
	ld hl, wa
	ret

PitchBend_Scale:
	res 7, c
	cps a, 0
	jr ge, PitchBend_Scale_Multiply
	extz bc
	lda_24 xhl, 0x00fee4
	ldb_sri C, 0x07, 0xEC, 0xE4
	extz bc
	cpl a
	inc 1, a

PitchBend_Scale_Multiply:
	ldb_erp A, 0xF0
	exts ix
	ld a, c
	extz wa
	lda_24 xbc, 0x00ff64
	ldb_sri L, 0x07, 0xE4, 0xE0
	exts hl
	ld wa, hl
	extpfx2 0xDC, 0x48
	ld hl, wa
	ld a, e
	and a, 0xF
	ret z
	sraa hl
	ret

Detune_ScaleSymmetric:
	cps wa, 0
	jr ge, Detune_ScaleSymmetric_PosArm
	cpl wa
	inc 1, wa
	cp wa, 0x32
	jr le, Detune_ScaleSymmetric_NegArm
	ldw wa, 0x32

Detune_ScaleSymmetric_NegArm:
	extz wa
	lda_24 xbc, 0x0119c8
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	cpl wa
	inc 1, wa
	jr Detune_ScaleSymmetric_Return

Detune_ScaleSymmetric_PosArm:
	cp wa, 0x32
	jr le, Detune_ScaleSymmetric_PosClamp
	ldw wa, 0x32

Detune_ScaleSymmetric_PosClamp:
	extz wa
	lda_24 xbc, 0x0119c8
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa

Detune_ScaleSymmetric_Return:
	ld hl, wa
	ret

Detune_ScaleUnsigned:
	extz wa
	lda_24 xbc, 0x0119c8
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld hl, wa
	ret

Pan_ScaleWithVelocity:
	and wa, 0x7F00
	srl wa, 8
	ld l, (xsp + 6)
	extz hl
	cp wa, hl
	jr ule, Pan_ScaleWithVelocity_ClampLo
	ld a, (xsp + 6)
	extz wa
	jr Pan_ScaleWithVelocity_Multiply

Pan_ScaleWithVelocity_ClampLo:
	ld l, e
	extz hl
	cp wa, hl
	jr nc, Pan_ScaleWithVelocity_Multiply
	ld a, e
	extz wa

Pan_ScaleWithVelocity_Multiply:
	extz bc
	ld de, wa
	sub de, bc
	ld l, (xsp + 4)
	exts hl
	ld wa, hl
	extpfx2 0xDA, 0x48
	ld hl, wa
	sra hl, 5
	retd 0x4

ClampS8_0_to_78:
	cp wa, 0x78
	jr le, ClampS8_0_to_78_CheckLo
	ldw wa, 0x78
	jr ClampS8_0_to_78_Return

ClampS8_0_to_78_CheckLo:
	cps wa, 0
	jr ge, ClampS8_0_to_78_Return
	lds wa, 0

ClampS8_0_to_78_Return:
	ld hl, wa
	ret

Portamento_CalcContrib_A:
	ld hl, de
	ld xix, (xwa + 23)
	cps hl, 0
	jr z, Portamento_CalcContrib_A_DepthScale
	ld e, (xix + 54)
	and e, 0xE0
	srl e, 5
	extz de
	ld iy, de
	sla iy, 7
	ld e, (xwa + 12)
	extz de
	and de, 0x7F
	extz xde
	stb_dri B, 0x07, 0xE8, 0xF4
	ld xiy, 0x11519
	add xiy, xde
	ld e, (xiy)
	ldb_erp E, 0xF4
	exts iy
	ld de, hl
	extpfx2 0xDD, 0x4A
	ld hl, de
	sra hl, 5
	add bc, hl

Portamento_CalcContrib_A_DepthScale:
	cp (xsp + 4), 0x0
	jr z, Portamento_CalcContrib_A_AddBaseline
	ld de, (xwa + 8)
	and de, 0x7F00
	srl de, 8
	ld a, (xix + 59)
	extz wa
	cp de, wa
	jr ule, Portamento_CalcContrib_A_ClampHi
	ld a, (xix + 59)
	ld e, a
	extz de
	jr Portamento_CalcContrib_A_Multiply

Portamento_CalcContrib_A_ClampHi:
	ld a, (xix + 58)
	extz wa
	cp de, wa
	jr nc, Portamento_CalcContrib_A_Multiply
	ld a, (xix + 58)
	ld e, a
	extz de

Portamento_CalcContrib_A_Multiply:
	ld a, (xix + 57)
	extz wa
	sub de, wa
	ld a, (xsp + 4)
	exts wa
	extpfx2 0xDA, 0x48
	sra wa, 5
	add bc, wa

Portamento_CalcContrib_A_AddBaseline:
	add bc, 0x18
	ld wa, bc
	calr ClampS8_0_to_78
	retd 0x2

Portamento_CalcContrib_B:
	ld xix, (xwa + 23)
	ld e, (xix + 16)
	ld l, e
	exts hl
	cps hl, 0
	jr z, Portamento_CalcContrib_B_AddBaseline
	ld e, (xix + 15)
	and e, 0xE0
	srl e, 5
	extz de
	sla de, 7
	ld a, (xwa + 12)
	extz wa
	and wa, 0x7F
	extz xwa
	stb_dri W, 0x07, 0xE0, 0xE8
	ld xde, 0x11519
	add xde, xwa
	ld a, (xde)
	ld e, a
	exts de
	ld wa, hl
	extpfx2 0xDA, 0x48
	ld hl, wa
	sra hl, 5
	ld wa, hl
	add bc, wa

Portamento_CalcContrib_B_AddBaseline:
	add bc, 0x18
	ld wa, bc
	jrl ClampS8_0_to_78

Portamento_ClampAdd18:
	add wa, 0x18
	cp wa, 0x78
	jr le, Portamento_ClampAdd18_Return
	ldw wa, 0x78

Portamento_ClampAdd18_Return:
	ld hl, wa
	ret

PitchBend_LookupCoeff:
	ld c, a
	and c, 0xF
	ld e, c
	extz de
	bit 7, a
	jr z, PitchBend_LookupCoeff_SetA
	ld wa, de
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	lda_24 xwa, 0x011a26
	add xwa, xbc
	ld a, (xwa)
	ld l, a
	extz hl
	sll hl, 8
	ld wa, de
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	ld xwa, 0x11A25
	add xwa, xbc
	ld a, (xwa)
	ldb_erp A, 0xF0
	extz ix
	ld wa, de
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	lda_24 xwa, 0x011a27
	add xwa, xbc
	ld a, (xwa)
	exts wa
	stda16 10560, xwa
	jr PitchBend_LookupCoeff_Return

PitchBend_LookupCoeff_SetA:
	ld wa, de
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	lda_24 xwa, 0x0119fc
	add xwa, xbc
	ld a, (xwa)
	ld l, a
	extz hl
	sll hl, 8
	ld wa, de
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	ld xwa, 0x119FB
	add xwa, xbc
	ld a, (xwa)
	ldb_erp A, 0xF0
	extz ix
	ld wa, de
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	lda_24 xwa, 0x0119fd
	add xwa, xbc
	ld a, (xwa)
	exts wa
	stda16 10560, xwa

PitchBend_LookupCoeff_Return:
	or hl, ix
	ret

NoteState_InitDefaults:
	ldw (xwa + 66), 0x17F
	ldw (xwa + 68), 0x7F7F
	ret

ClampS16_WA_Short:
	cp wa, bc
	jr le, ClampS16_WA_Short_CheckLo
	ld wa, bc
	jr ClampS16_WA_Short_Return

ClampS16_WA_Short_CheckLo:
	cp wa, de
	jr ge, ClampS16_WA_Short_Return
	ld wa, de

ClampS16_WA_Short_Return:
	ld hl, wa
	ret

NoteState_ClearRecord:
	extz wa
	muls wa, 0x9
	ld de, wa
	ld a, c
	extz wa
	muls wa, 0x1B
	lda_24 xbc, 0x04424e
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xwa + 1), 0x0
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x0
	ld (xwa + 4), 0x0
	ld (xwa), 0x0
	ld (xwa + 5), 0x0
	ld (xwa + 7), 0x0
	ret

EnvDepth_Cap:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld a, c
	ld xbc, 0x7F
	sub xbc, xwa
	lds32 xwa, 0
	ld a, e
	call FP_MulAccum64
	ld xiz, xhl
	ld xbc, (xsp + 4)
	ld xwa, xiz
	call FP_MulAccum64
	srl xhl, 12
	cp xhl, (xsp + 4)
	jr ule, EnvDepth_Cap_Return
	ld xhl, (xsp + 4)

EnvDepth_Cap_Return:
	pop xiz
	inc 4, xsp
	ret

EGEnv_Compute_A:
	dec 4, xsp
	push xiz
	extz wa
	muls wa, 0x1B
	lda_24 xbc, 0x04424e
	exts xwa
	add xwa, xbc
	ld (xsp + 4), xwa
	ld a, (xwa + 1)
	extz wa
	add wa, wa
	lda_24 xbc, 0x010a64
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld iz, wa
	extz xiz
	ld xwa, (xsp + 4)
	ld a, (xwa + 2)
	lds32 xbc, 0
	ld c, a
	ld xwa, xiz
	call FP_MulAccum64
	ld xiz, xhl
	ld xwa, (xsp + 4)
	cp (xwa + 5), 0x0
	jr z, EGEnv_Compute_A_Normalise
	ld xwa, (xsp + 4)
	ld a, (xwa + 6)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 5)
	ld e, a
	extz de
	ld xwa, xiz
	calr EnvDepth_Cap
	sub xiz, xhl

EGEnv_Compute_A_Normalise:
	srl xiz, 7
	cp xiz, 0x1FFF
	jr ule, EGEnv_Compute_A_FormatBits
	ld xiz, 0x1FFF

EGEnv_Compute_A_FormatBits:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	and a, 0x3
	extz wa
	add wa, wa
	lda_24 xbc, 0x011511
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld bc, iz
	ld hl, bc
	or hl, wa
	pop xiz
	inc 4, xsp
	ret

EGEnv_Compute_A_Simple:
	extz wa
	muls wa, 0x1B
	lda_24 xbc, 0x04424e
	stb_dri B, 0x07, 0xE4, 0xE0
	ld a, (xde + 3)
	extz wa
	add wa, wa
	lda_24 xbc, 0x010964
	ldw_sri HL, 0x07, 0xE4, 0xE0
	extz xhl
	ld a, (xde + 4)
	lds32 xbc, 0
	ld c, a
	ld xwa, xhl
	call FP_MulAccum64
	srl xhl, 7
	cp xhl, 0x3FFF
	ret ule
	ld xhl, 0x3FFF
	ret

EGEnv_OpaqueData:
	.byte 0xd8, 0x12, 0xd8, 0x09, 0x1b, 0x00, 0xf2, 0x4e
	.byte 0x42, 0x04, 0x31, 0xf3, 0x07, 0xe4, 0xe0, 0x32
	.byte 0x8a, 0x03, 0x21, 0xd8, 0x12, 0xd8, 0x80, 0xf2
	.byte 0x64, 0x09, 0x01, 0x31, 0xd3, 0x07, 0xe4, 0xe0
	.byte 0x23, 0xeb, 0x12, 0x8a, 0x04, 0x21, 0xe9, 0xa8
	.byte 0xc9, 0x8b, 0xeb, 0x88, 0x1d, 0xca, 0xd8, 0x03
	.byte 0xeb, 0xef, 0x07, 0xeb, 0xcf, 0xff, 0x3f, 0x00
	.byte 0x00, 0xb0, 0xf3, 0x43, 0xff, 0x3f, 0x00, 0x00
	.byte 0x0e

EGEnv_Compute_B:
	dec 4, xsp
	push xiz
	extz wa
	muls wa, 0x1B
	lda_24 xbc, 0x044257
	exts xwa
	add xwa, xbc
	ld (xsp + 4), xwa
	ld a, (xwa + 1)
	extz wa
	add wa, wa
	lda_24 xbc, 0x010b64
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld iz, wa
	extz xiz
	ld xwa, (xsp + 4)
	ld a, (xwa + 2)
	lds32 xbc, 0
	ld c, a
	ld xwa, xiz
	call FP_MulAccum64
	ld xiz, xhl
	ld xwa, (xsp + 4)
	cp (xwa + 5), 0x0
	jr z, EGEnv_Compute_B_Normalise
	ld xwa, (xsp + 4)
	ld a, (xwa + 6)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 5)
	ld e, a
	extz de
	ld xwa, xiz
	calr EnvDepth_Cap
	sub xiz, xhl

EGEnv_Compute_B_Normalise:
	srl xiz, 7
	cp xiz, 0x1FFF
	jr ule, EGEnv_Compute_B_FormatBits
	ld xiz, 0x1FFF

EGEnv_Compute_B_FormatBits:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	and a, 0x3
	extz wa
	add wa, wa
	lda_24 xbc, 0x011511
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld bc, iz
	ld hl, bc
	or hl, wa
	pop xiz
	inc 4, xsp
	ret

EGEnv_Compute_B_Simple:
	extz wa
	muls wa, 0x1B
	lda_24 xbc, 0x044257
	exts xwa
	add xwa, xbc
	ld xde, xwa
	ld a, (xde + 3)
	extz wa
	add wa, wa
	lda_24 xbc, 0x010964
	ldw_sri HL, 0x07, 0xE4, 0xE0
	extz xhl
	ld a, (xde + 4)
	lds32 xbc, 0
	ld c, a
	ld xwa, xhl
	call FP_MulAccum64
	srl xhl, 7
	cp xhl, 0x3FFF
	ret ule
	ld xhl, 0x3FFF
	ret

Voice_Freq_ComputeLeft_Raw:
	.byte 0xd8, 0x12, 0xd8, 0x09, 0x1b, 0x00, 0xf2, 0x57
	.byte 0x42, 0x04, 0x31, 0xe8, 0x13, 0xe9, 0x80, 0xe8
	.byte 0x8a, 0x8a, 0x03, 0x21, 0xd8, 0x12, 0xd8, 0x80
	.byte 0xf2, 0x64, 0x09, 0x01, 0x31, 0xd3, 0x07, 0xe4
	.byte 0xe0, 0x23, 0xeb, 0x12, 0x8a, 0x04, 0x21, 0xe9
	.byte 0xa8, 0xc9, 0x8b, 0xeb, 0x88, 0x1d, 0xca, 0xd8
	.byte 0x03, 0xeb, 0xef, 0x07, 0x0e

Voice_Freq_WriteLeft:
	dec 4, xsp
	push xiz
	ld c, a
	extz bc
	muls bc, 0x1B
	lda_24 xde, 0x044260
	exts xbc
	add xbc, xde
	ld (xsp + 4), xbc
	cp a, 0x40
	jr nc, Voice_Freq_WriteLeft_HiRange
	ld xwa, (xsp + 4)
	ld a, (xwa + 1)
	extz wa
	add wa, wa
	lda_24 xbc, 0x010c64
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld iz, wa
	extz xiz
	ld xwa, (xsp + 4)
	ld a, (xwa + 2)
	lds32 xbc, 0
	ld c, a
	ld xwa, xiz
	call FP_MulAccum64
	ld xiz, xhl
	ld xwa, (xsp + 4)
	cp (xwa + 5), 0x0
	jr z, Voice_Freq_WriteLeft_Clamp
	ld xwa, (xsp + 4)
	ld a, (xwa + 6)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 5)
	ld e, a
	extz de
	ld xwa, xiz
	calr EnvDepth_Cap
	sub xiz, xhl

Voice_Freq_WriteLeft_Clamp:
	srl xiz, 7
	cp xiz, 0x1FFF
	jr ule, Voice_Freq_WriteLeft_Store
	ld xiz, 0x1FFF

Voice_Freq_WriteLeft_Store:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	and a, 0x3
	extz wa
	add wa, wa
	lda_24 xbc, 0x011511
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld bc, iz
	or bc, wa
	stw_da 0x045204, xbc
	jr Voice_Freq_WriteLeft_Return

Voice_Freq_WriteLeft_HiRange:
	ld xwa, (xsp + 4)
	ld a, (xwa + 1)
	extz wa
	add wa, wa
	lda_24 xbc, 0x010c64
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld iz, wa
	extz xiz
	ld xwa, (xsp + 4)
	ld a, (xwa + 2)
	lds32 xbc, 0
	ld c, a
	ld xwa, xiz
	call FP_MulAccum64
	ld xiz, xhl
	ld xwa, (xsp + 4)
	cp (xwa + 5), 0x0
	jr z, Voice_Freq_WriteLeft_HiRange_Clamp
	ld xwa, (xsp + 4)
	ld a, (xwa + 6)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 5)
	ld e, a
	extz de
	ld xwa, xiz
	calr EnvDepth_Cap
	sub xiz, xhl

Voice_Freq_WriteLeft_HiRange_Clamp:
	srl xiz, 7
	cp xiz, 0x1FFF
	jr ule, Voice_Freq_WriteLeft_HiRange_Store
	ld xiz, 0x1FFF

Voice_Freq_WriteLeft_HiRange_Store:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	and a, 0x3
	extz wa
	add wa, wa
	lda_24 xbc, 0x011511
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld bc, iz
	or bc, wa
	stw_da 0x04520e, xbc

Voice_Freq_WriteLeft_Return:
	pop xiz
	inc 4, xsp
	ret

Voice_Freq_WriteRight:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x1B
	lda_24 xbc, 0x044260
	exts xwa
	add xwa, xbc
	ld xiz, xwa
	ld a, (xiz + 3)
	extz wa
	add wa, wa
	lda_24 xbc, 0x010964
	ldw_sri HL, 0x07, 0xE4, 0xE0
	extz xhl
	ld a, (xiz + 4)
	lds32 xbc, 0
	ld c, a
	ld xwa, xhl
	call FP_MulAccum64
	srl xhl, 7
	cp (xsp + 4), 0x40
	jr nc, Voice_Freq_WriteRight_HiRange
	cp xhl, 0x3FFF
	jr ule, Voice_Freq_WriteRight_FlagSet
	ld xhl, 0x3FFF

Voice_Freq_WriteRight_FlagSet:
	bitm 5, (xiz)
	jr z, Voice_Freq_WriteRight_Store
	set 15, hl
	stw_da 0x045206, xhl
	jr Voice_Freq_WriteRight_Return

Voice_Freq_WriteRight_Store:
	stw_da 0x045206, xhl
	jr Voice_Freq_WriteRight_Return

Voice_Freq_WriteRight_HiRange:
	cp xhl, 0x3FFF
	jr ule, Voice_Freq_WriteRight_HiRange_Store
	ld xhl, 0x3FFF

Voice_Freq_WriteRight_HiRange_Store:
	stw_da 0x04520a, xhl

Voice_Freq_WriteRight_Return:
	pop xiz
	inc 2, xsp
	ret

Voice_Freq_ComputeRight_Raw:
	.byte 0xef, 0x6a, 0xb7, 0x41, 0x87, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x1b, 0x00, 0xf2, 0x60, 0x42, 0x04
	.byte 0x31, 0xe8, 0x13, 0xe9, 0x80, 0xe8, 0x8a, 0x8a
	.byte 0x03, 0x21, 0xd8, 0x12, 0xd8, 0x80, 0xf2, 0x64
	.byte 0x09, 0x01, 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x23
	.byte 0xeb, 0x12, 0x8a, 0x04, 0x21, 0xe9, 0xa8, 0xc9
	.byte 0x8b, 0xeb, 0x88, 0x1d, 0xca, 0xd8, 0x03, 0xeb
	.byte 0xef, 0x07, 0x87, 0x3f, 0x40, 0x6f, 0x14, 0xeb
	.byte 0xcf, 0xff, 0x3f, 0x00, 0x00, 0x63, 0x05, 0x43
	.byte 0xff, 0x3f, 0x00, 0x00, 0xf2, 0x06, 0x52, 0x04
	.byte 0x53, 0x68, 0x12, 0xeb, 0xcf, 0xff, 0x3f, 0x00
	.byte 0x00, 0x63, 0x05, 0x43, 0xff, 0x3f, 0x00, 0x00
	.byte 0xf2, 0x0a, 0x52, 0x04, 0x53, 0xef, 0x62, 0x0e
	.byte 0xd8, 0xcf, 0xff, 0x00, 0x63, 0x03, 0x30, 0xff
	.byte 0x00, 0xd8, 0x8b, 0x0e

Voice_Colour_LookupIndex:
	and c, 0xE0
	srl c, 5
	extz xwa
	ld xde, 0x106E4
	add xde, xwa
	ld a, (xde)
	ld e, a
	extz de
	ld a, c
	extz wa
	sla wa, 8
	add wa, de
	lda_24 xbc, 0x00ffe4
	ldb_sri L, 0x07, 0xE4, 0xE0
	extz hl
	ret

Voice_Colour_ClampUpper:
	and wa, 0x7F00
	srl wa, 8
	ld l, (xsp + 6)
	extz hl
	cp wa, hl
	jr ule, Voice_Colour_ClampLower
	ld a, (xsp + 6)
	extz wa
	jr Voice_Colour_InterpolateDelta

Voice_Colour_ClampLower:
	ld l, e
	extz hl
	cp wa, hl
	jr nc, Voice_Colour_InterpolateDelta
	ld a, e
	extz wa

Voice_Colour_InterpolateDelta:
	extz bc
	ld de, wa
	sub de, bc
	ld l, (xsp + 4)
	exts hl
	ld wa, hl
	extpfx2 0xDA, 0x48
	ld hl, wa
	sra hl, 5
	retd 0x4

Voice_Clamp_Byte_WA:
	cp wa, 0xFF
	jr le, Voice_Clamp_Byte_WA_LowBound
	ldw wa, 0xFF
	jr Voice_Clamp_Byte_WA_Return

Voice_Clamp_Byte_WA_LowBound:
	cps wa, 0
	jr ge, Voice_Clamp_Byte_WA_Return
	lds wa, 0

Voice_Clamp_Byte_WA_Return:
	ld hl, wa
	ret

Voice_Colour_Write:
	push xiz
	ld xiz, xwa
	ld xwa, (xiz + 35)
	add bc, (xwa + 12)
	ld xwa, (xiz + 35)
	add bc, (xwa + 16)
	add bc, (xiz + 51)
	ld wa, bc
	calr Voice_Clamp_Byte_WA
	ld bc, hl
	add bc, bc
	lda_24 xwa, 0x010764
	ldw_sri WA, 0x07, 0xE0, 0xE4
	add wa, wa
	ld bc, wa
	ld xwa, (xiz + 15)
	bitm 7, (xwa + 2)
	jr z, Voice_Colour_Write_NoPanOverride
	ld xwa, (xiz + 15)
	ld a, (xwa + 2)
	extz wa
	and wa, 0x70
	sll wa, 8
	jr Voice_Colour_Write_Store

Voice_Colour_Write_NoPanOverride:
	ld wa, (xiz + 6)
	srl wa, 8
	extz xwa
	add xwa, xwa
	ld xde, 0xFBE4
	add xde, xwa
	ld wa, (xde)

Voice_Colour_Write_Store:
	or bc, wa
	set 15, bc
	stw_da 0x0451d0, xbc
	pop xiz
	ret

Voice_Clamp_Byte_HL:
	ld bc, wa
	cp bc, 0xFF
	jr ule, Voice_Clamp_Byte_HL_LowBound
	ldw wa, 0xFF
	jr Voice_Clamp_Byte_HL_Return

Voice_Clamp_Byte_HL_LowBound:
	cps wa, 0
	jr ge, Voice_Clamp_Byte_HL_Return
	lds wa, 0

Voice_Clamp_Byte_HL_Return:
	ld hl, wa
	ret

Voice_Env_UpdateVelocityCounters:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041481
	ldda32 xhl, 4160
	sub_sril_rm XHL, 0x07, 0xE8, 0xE4
	jrl z, Voice_Env_UpdateVelocity_Store
	cp xhl, 0x19
	jr nc, Voice_Env_UpdateVelocity_Reset
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041485
	exts xbc
	add xbc, xde
	incm8 1, (xbc)
	ld c, (xbc)
	cps c, 1
	jr z, Voice_Env_UpdateVelocity_SetPhase1
	cps c, 0
	jr nz, Voice_Env_UpdateVelocity_SetPhase2
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041486
	stib_ind 0x07, 0xE8, 0xE4, 0x00
	jr Voice_Env_UpdateVelocity_Store

Voice_Env_UpdateVelocity_SetPhase1:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041486
	stib_ind 0x07, 0xE8, 0xE4, 0x10
	jr Voice_Env_UpdateVelocity_Store

Voice_Env_UpdateVelocity_SetPhase2:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041486
	stib_ind 0x07, 0xE8, 0xE4, 0x20
	jr Voice_Env_UpdateVelocity_Store

Voice_Env_UpdateVelocity_Reset:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041485
	stib_ind 0x07, 0xE8, 0xE4, 0x00
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041486
	stib_ind 0x07, 0xE8, 0xE4, 0x00

Voice_Env_UpdateVelocity_Store:
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xde, 0x041481
	ldda32 xwa, 4160
	stl_dri XWA, 0x07, 0xE8, 0xE4
	ret

Voice_Env_ApplyVelocity_Type0:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x0413d5
	stib_ind 0x07, 0xE8, 0xE0, 0x00
	ld a, (xsp)
	cps a, 2
	jrl z, Voice_Env_ApplyVelocity_Type2
	cps a, 1
	jr z, Voice_Env_VelocityDispatch_c1
	cps a, 0
	jrl nz, Voice_Env_ApplyVelocity_Return

Voice_Env_VelocityDispatch_c1:
	cps c, 3
	jr z, Voice_Env_VelocityDispatch_c3
	cps c, 2
	jr z, Voice_Env_VelocityDispatch_c2
	cps c, 1
	jr z, Voice_Env_VelocityDispatch_c1_Bit1
	cps c, 0
	jrl nz, Voice_Env_VelocityDispatch_ClearFlag
	bitda_24 3, 267083
	jr z, Voice_Env_VelocityDispatch_c0_NoBit3
	ldb l, 0x0
	jrl Voice_Env_VelocityDispatch_Gate

Voice_Env_VelocityDispatch_c0_NoBit3:
	ldb_da a, 0x04134b
	extz wa
	calr BitTest_Bit0_L
	jr Voice_Env_VelocityDispatch_Gate

Voice_Env_VelocityDispatch_c1_Bit1:
	bitda_24 3, 267083
	jr z, Voice_Env_VelocityDispatch_c1_NoBit3
	ldb l, 0x0
	jr Voice_Env_VelocityDispatch_Gate

Voice_Env_VelocityDispatch_c1_NoBit3:
	ldb_da a, 0x04134b
	extz wa
	calr BitTest_Mode2_L
	jr Voice_Env_VelocityDispatch_Gate

Voice_Env_VelocityDispatch_c2:
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04137f
	bit_dri 3, 0x07, 0xE4, 0xE0
	jr z, Voice_Env_VelocityDispatch_c2_Trigger
	ldb l, 0x0
	jr Voice_Env_VelocityDispatch_Gate

Voice_Env_VelocityDispatch_c2_Trigger:
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04137f
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	calr BitTest_Bit0_L_v2
	jr Voice_Env_VelocityDispatch_Gate

Voice_Env_VelocityDispatch_c3:
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04137f
	bit_dri 3, 0x07, 0xE4, 0xE0
	jr z, Voice_Env_VelocityDispatch_c3_Trigger
	ldb l, 0x0
	jr Voice_Env_VelocityDispatch_Gate

Voice_Env_VelocityDispatch_c3_Trigger:
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04137f
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	calr BitTest_Mode2_L_v2
	jr Voice_Env_VelocityDispatch_Gate

Voice_Env_VelocityDispatch_ClearFlag:
	ldb l, 0x0

Voice_Env_VelocityDispatch_Gate:
	cps l, 0
	jrl z, Voice_Env_ApplyVelocity_Return
	ld a, (xsp)
	extz wa
	calr Instrument_LookupProgram_HiNibble
	jrl Voice_Env_ApplyVelocity_Return

Voice_Env_ApplyVelocity_Type2:
	cps c, 3
	jr z, Voice_Env_Type2_c3
	cps c, 2
	jr z, Voice_Env_Type2_c2
	cps c, 1
	jr z, Voice_Env_Type2_c1
	cps c, 0
	jrl nz, Voice_Env_Type2_ClearFlag
	bitda_24 4, 267083
	jr z, Voice_Env_Type2_c0_NoBit4
	ldb l, 0x0
	jrl Voice_Env_Type2_Gate

Voice_Env_Type2_c0_NoBit4:
	ldb_da a, 0x04134b
	extz wa
	calr BitTest_Bit0_L
	jr Voice_Env_Type2_Gate

Voice_Env_Type2_c1:
	bitda_24 4, 267083
	jr z, Voice_Env_Type2_c1_NoBit4
	ldb l, 0x0
	jr Voice_Env_Type2_Gate

Voice_Env_Type2_c1_NoBit4:
	ldb_da a, 0x04134b
	extz wa
	calr BitTest_Mode2_L
	jr Voice_Env_Type2_Gate

Voice_Env_Type2_c2:
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04137f
	bit_dri 4, 0x07, 0xE4, 0xE0
	jr z, Voice_Env_Type2_c2_Trigger
	ldb l, 0x0
	jr Voice_Env_Type2_Gate

Voice_Env_Type2_c2_Trigger:
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04137f
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	calr BitTest_Bit0_L_v2
	jr Voice_Env_Type2_Gate

Voice_Env_Type2_c3:
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04137f
	bit_dri 4, 0x07, 0xE4, 0xE0
	jr z, Voice_Env_Type2_c3_Trigger
	ldb l, 0x0
	jr Voice_Env_Type2_Gate

Voice_Env_Type2_c3_Trigger:
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04137f
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	calr BitTest_Mode2_L_v2
	jr Voice_Env_Type2_Gate

Voice_Env_Type2_ClearFlag:
	ldb l, 0x0

Voice_Env_Type2_Gate:
	cps l, 0
	jr z, Voice_Env_ApplyVelocity_Return
	ld a, (xsp)
	extz wa
	calr Instrument_LookupProgram_LoNibble

Voice_Env_ApplyVelocity_Return:
	inc 2, xsp
	ret

Voice_Pitch_Compute:
	lda xsp, (xsp - 10)
	pushw iz
	ld (xsp + 8), xwa
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 31)
	ld (xsp + 2), xwa
	ld xwa, (xsp + 8)
	ld a, (xwa + 4)
	ld (xsp + 6), a
	ld xwa, (xsp + 8)
	ld a, (xwa + 5)
	ldb_erp A, 0xF8
	extz iz
	sla iz, 8
	and iz, 0x7F00
	add iz, 0x80
	addda16_24 xiz, 267081
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 35)
	ld a, (xwa + 22)
	exts wa
	sla wa, 8
	add iz, wa
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 35)
	ld a, (xwa + 109)
	exts wa
	sla wa, 8
	add iz, wa
	ld xwa, (xsp + 8)
	ld a, (xwa + 4)
	ld e, a
	extz de
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 19)
	ld a, (xwa + 41)
	ld c, a
	extz bc
	ld wa, de
	calr PitchBend_Process
	add iz, hl
	call Voice_GetMonoMode
	cps hl, 0
	jrl z, Voice_Pitch_Compute_Inactive
	ld a, (xsp + 6)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	ldw_sri WA, 0x07, 0xE4, 0xE0
	bit 8, wa
	jrl z, Voice_Pitch_ApplyPortamento
	call Voice_GetParam_04134D
	ld a, l
	cp a, 0x80
	jr z, Voice_Pitch_BendType_Octave
	cp a, 0x42
	jr z, Voice_Pitch_BendType_TableB
	cp a, 0x41
	jr z, Voice_Pitch_BendType_TableA
	cp a, 0x40
	jr z, Voice_Pitch_BendType_Fixed
	cps a, 0
	jrl z, Voice_Pitch_ApplyPortamento

Voice_Pitch_BendType_Octave:
	ld xwa, (xsp + 8)
	ld a, (xwa + 5)
	res 7, a
	extz wa
	div a, 0xC
	ld a, w
	extz wa
	call Voice_ReadChannelAssign
	ld a, l
	exts wa
	add wa, wa
	add iz, wa
	jrl Voice_Pitch_ApplyPortamento

Voice_Pitch_BendType_Fixed:
	addda16_24 xiz, 267110
	jrl Voice_Pitch_ApplyPortamento

Voice_Pitch_BendType_TableA:
	ld xwa, (xsp + 8)
	ld a, (xwa + 5)
	res 7, a
	extz wa
	add wa, wa
	lda_24 xbc, 0x00fce4
	ldw_sri WA, 0x07, 0xE4, 0xE0
	add iz, wa
	jrl Voice_Pitch_ApplyPortamento

Voice_Pitch_BendType_TableB:
	ld xwa, (xsp + 8)
	ld a, (xwa + 5)
	res 7, a
	extz wa
	add wa, wa
	lda_24 xbc, 0x00fde4
	ldw_sri WA, 0x07, 0xE4, 0xE0
	add iz, wa
	jrl Voice_Pitch_ApplyPortamento

Voice_Pitch_Compute_Inactive:
	ld a, (xsp + 6)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld l, (xwa + 19)
	ld a, l
	cp a, 0x80
	jrl z, Voice_Pitch_ApplyPortamento
	cp a, 0x42
	jr z, Voice_Pitch_Inactive_BendType_TableB
	cp a, 0x41
	jr z, Voice_Pitch_Inactive_BendType_TableA
	cp a, 0x40
	jr z, Voice_Pitch_Inactive_BendType_Fixed
	cps a, 0
	jr nz, Voice_Pitch_Inactive_BendType_Chromatic
	jr Voice_Pitch_ApplyPortamento

Voice_Pitch_Inactive_BendType_Fixed:
	addda16_24 xiz, 267110
	jr Voice_Pitch_ApplyPortamento

Voice_Pitch_Inactive_BendType_TableA:
	ld xwa, (xsp + 8)
	ld a, (xwa + 5)
	res 7, a
	extz wa
	add wa, wa
	lda_24 xbc, 0x00fce4
	ldw_sri WA, 0x07, 0xE4, 0xE0
	add iz, wa
	jr Voice_Pitch_ApplyPortamento

Voice_Pitch_Inactive_BendType_TableB:
	ld xwa, (xsp + 8)
	ld a, (xwa + 5)
	res 7, a
	extz wa
	add wa, wa
	lda_24 xbc, 0x00fde4
	ldw_sri WA, 0x07, 0xE4, 0xE0
	add iz, wa
	jr Voice_Pitch_ApplyPortamento

Voice_Pitch_Inactive_BendType_Chromatic:
	ld xwa, (xsp + 8)
	ld a, (xwa + 5)
	res 7, a
	extz wa
	div a, 0xC
	ld a, w
	ld e, a
	extz de
	ld a, l
	extz wa
	muls wa, 0xC
	lda_24 xbc, 0x011b68
	exts xwa
	add xwa, xbc
	ldb_sri A, 0x07, 0xE0, 0xE8
	exts wa
	add wa, wa
	add iz, wa

Voice_Pitch_ApplyPortamento:
	ld wa, iz
	calr SaturateS16_WA
	ld xwa, (xsp + 8)
	ld (xwa + 8), hl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 23)
	ld l, (xwa + 6)
	and l, 0x7
	ld xwa, (xsp + 2)
	bitm 1, (xwa)
	jr nz, Voice_Pitch_Portamento_Active_SubBias
	cps l, 7
	jr z, Voice_Pitch_Portamento_Mode7_Direct
	ld xwa, (xsp + 2)
	ld a, (xwa + 11)
	extz wa
	sla wa, 8
	add wa, 0x80
	sub iz, wa
	ld a, l
	and a, 0xF
	jr z, Voice_Pitch_Portamento_Off_AddOffset
	sraa iz

Voice_Pitch_Portamento_Off_AddOffset:
	ld xwa, (xsp + 2)
	ld wa, (xwa + 12)
	add iz, wa
	jr Voice_Pitch_ApplyFineTune

Voice_Pitch_Portamento_Mode7_Direct:
	ld xwa, (xsp + 2)
	ld iz, (xwa + 12)
	jr Voice_Pitch_ApplyFineTune

Voice_Pitch_Portamento_Active_SubBias:
	cps l, 7
	jr z, Voice_Pitch_Portamento_Active_SetFixed
	sub iz, 0x4280
	ld a, l
	and a, 0xF
	jr z, Voice_Pitch_Portamento_Active_AddBias
	sraa iz

Voice_Pitch_Portamento_Active_AddBias:
	add iz, 0x4280
	jr Voice_Pitch_ApplyFineTune

Voice_Pitch_Portamento_Active_SetFixed:
	ldw iz, 0x4280

Voice_Pitch_ApplyFineTune:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 23)
	ld a, (xwa + 4)
	exts wa
	sla wa, 8
	add iz, wa
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 39)
	ld a, (xwa + 32)
	exts wa
	sla wa, 8
	add iz, wa
	cps l, 0
	jr nz, Voice_Pitch_ApplyFineTune_LegatoB
	ld xwa, (xsp + 2)
	ld a, (xwa + 9)
	ld c, a
	extz bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 10)
	ld e, a
	extz de
	ld wa, iz
	calr PitchBend_AlignLoop_Init
	ld xwa, (xsp + 8)
	ld (xwa + 6), hl
	jr Voice_Pitch_Compute_Return

Voice_Pitch_ApplyFineTune_LegatoB:
	ld xwa, (xsp + 2)
	ld a, (xwa + 9)
	ld c, a
	extz bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 10)
	ld e, a
	extz de
	ld wa, iz
	calr PitchBend_Saturate
	ld xwa, (xsp + 8)
	ld (xwa + 6), hl

Voice_Pitch_Compute_Return:
	popw iz
	lda xsp, (xsp + 10)
	ret

Voice_Pitch_CopyBase:
	push xiz
	ld xiz, xwa
	ld xbc, (xiz + 23)
	ld xwa, (xiz + 31)
	ld hl, (xwa + 12)
	ld (xiz + 8), hl
	ld a, (xbc + 3)
	exts wa
	sla wa, 8
	add hl, wa
	ld a, (xbc + 4)
	exts wa
	add wa, wa
	add hl, wa
	ld xwa, (xiz + 31)
	ld a, (xwa + 9)
	ld c, a
	extz bc
	ld xwa, (xiz + 31)
	ld a, (xwa + 10)
	ld e, a
	extz de
	ld wa, hl
	calr PitchBend_AlignLoop_Init
	ld (xiz + 6), hl
	pop xiz
	ret

Voice_Pitch_InterpDispatch:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 12), xwa
	ld xwa, (xsp + 12)
	ld xiz, (xwa + 31)
	ld xwa, (xiz + 1)
	addda32_24 xwa, 283408
	ld (xsp + 4), xwa
	ld xwa, (xiz + 5)
	addda32_24 xwa, 283408
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xde, xwa
	addda32_24 xde, 283408
	ld xwa, (xsp + 12)
	ld bc, (xwa + 6)
	ld xwa, xde
	calr ChanBitField_ExtractHi7
	ld a, l
	extz wa
	ld bc, wa
	inc 4, bc
	ld xwa, (xsp + 4)
	ldb_sri E, 0x07, 0xE0, 0xE4
	bitm 6, (xiz)
	jr z, Voice_Pitch_Interp_Bit7_NoB6
	bitm 7, (xiz)
	jr z, Voice_Pitch_Interp_Bit7_NoB5
	bitm 5, (xiz)
	jr z, Voice_Pitch_Interp_Bits56
	ld xbc, (xsp + 8)
	extz de
	ld xwa, (xsp + 12)
	calr SlotParam_Write_Stride0F
	jr Voice_Pitch_InterpDispatch_Return

Voice_Pitch_Interp_Bits56:
	ld xbc, (xsp + 8)
	extz de
	ld xwa, (xsp + 12)
	calr SlotParam_Write_Stride0C
	jr Voice_Pitch_InterpDispatch_Return

Voice_Pitch_Interp_Bit7_NoB5:
	bitm 5, (xiz)
	jr z, Voice_Pitch_Interp_Bits67
	ld xbc, (xsp + 8)
	extz de
	ld xwa, (xsp + 12)
	calr SlotParam_Write_Stride0D
	jr Voice_Pitch_InterpDispatch_Return

Voice_Pitch_Interp_Bits67:
	ld xbc, (xsp + 8)
	extz de
	ld xwa, (xsp + 12)
	calr SlotParam_Write_Stride0A
	jr Voice_Pitch_InterpDispatch_Return

Voice_Pitch_Interp_Bit7_NoB6:
	bitm 7, (xiz)
	jr z, Voice_Pitch_Interp_Base
	ld xbc, (xsp + 8)
	extz de
	ld xwa, (xsp + 12)
	calr SlotParam_Write_Stride06
	jr Voice_Pitch_InterpDispatch_Return

Voice_Pitch_Interp_Base:
	ld xbc, (xsp + 8)
	extz de
	ld xwa, (xsp + 12)
	calr SlotParam_Write_Stride04_SLA

Voice_Pitch_InterpDispatch_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

Voice_PitchEnv_Advance:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld xwa, (xiz + 31)
	ld xwa, (xwa + 5)
	addda32_24 xwa, 283408
	ld (xsp + 4), xwa
	cp (xiz + 3), 0x0
	jr nz, Voice_PitchEnv_Advance_StateB
	ld a, (xiz + 4)
	ld l, a
	extz hl
	ld a, (xiz)
	ld c, a
	extz bc
	ld a, (xiz + 3)
	ld e, a
	extz de
	ld wa, hl
	call Voice_Slot_CalcAmpNibble
	ld wa, hl
	call Voice_KeyIndex_Pack3Nibbles
	ld wa, hl
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	add (xsp + 4), xbc
	jr Voice_PitchEnv_StoreOutputRegs

Voice_PitchEnv_Advance_StateB:
	cp (xiz + 3), 0x3
	jr nc, Voice_PitchEnv_Advance_RoutingTable
	ld a, (xiz + 4)
	ld l, a
	extz hl
	ld a, (xiz)
	ld c, a
	extz bc
	ld a, (xiz + 3)
	ld e, a
	extz de
	ld wa, hl
	call Voice_Slot_FindOctaveOffset
	ld wa, hl
	call Voice_KeyIndex_Pack3Nibbles
	ld wa, hl
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	add (xsp + 4), xbc
	jr Voice_PitchEnv_StoreOutputRegs

Voice_PitchEnv_Advance_RoutingTable:
	ld a, (xiz + 3)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x102
	ld xwa, (xiz + 35)
	ldw_sri HL, 0x07, 0xE0, 0xE4
	ld wa, hl
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	add (xsp + 4), xbc

Voice_PitchEnv_StoreOutputRegs:
	ld xwa, (xsp + 4)
	ld (xiz + 15), xwa
	ormi16 (xiz + 1), 0x4000
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	stw_da 0x0451ce, xwa
	ld xwa, (xsp + 4)
	ld wa, (xwa + 4)
	stda16 10558, xwa
	ldw_da xwa, 0x041343
	bit 2, wa
	jr z, Voice_PitchEnv_StoreOutputRegs_Return
	ldw_da xwa, 0x0451ce
	and wa, 0xF000
	add wa, wa
	anddi16_24 283086, 4095
	ordm16_24 283086, xwa

Voice_PitchEnv_StoreOutputRegs_Return:
	pop xiz
	inc 4, xsp
	ret

Voice_Vol_ScaleVelocityWord:
	ldda32 xbc, 4160
	ld xwa, xbc
	call FP_MulAccum64
	srl xhl, 2
	and xhl, 0xFF
	ld a, l
	exts wa
	muls wa, 0xD
	sra wa, 7
	stw_da 0x041366, xwa
	ret

Voice_Pitch_WriteOutputReg_Portamento:
	ld de, (xwa + 6)
	addda16 xde, 10558
	ld xbc, (xwa + 23)
	ld c, (xbc + 5)
	exts bc
	add bc, bc
	add de, bc
	ld xbc, (xwa + 39)
	ld c, (xbc + 33)
	exts bc
	add de, bc
	ld xbc, (xwa + 35)
	add de, (xbc + 20)
	ld (xwa + 10), de
	ld xbc, (xwa + 35)
	ld bc, (xbc + 10)
	bit 2, bc
	jr z, Voice_Pitch_WriteOutputReg_Portamento_ClearBit
	ld xbc, (xwa + 19)
	bitm 5, (xbc + 16)
	jr z, Voice_Pitch_WriteOutputReg_Portamento_ClearBit
	ormi16 (xwa + 1), 0x400
	ret

Voice_Pitch_WriteOutputReg_Portamento_ClearBit:
	andmi16 (xwa + 1), 0xFBFF
	ret

Voice_Pitch_WriteOutputReg_Legato:
	ld de, (xwa + 10)
	addda16_24 xde, 267079
	ld xbc, (xwa + 39)
	ld bc, (xbc + 24)
	bit 4, bc
	jr z, Voice_Pitch_Legato_StoreOutput
	ld xbc, (xwa + 39)
	ld bc, (xbc + 24)
	bit 5, bc
	jr z, Voice_Pitch_Legato_DetuneDown
	ld xbc, (xwa + 35)
	sub de, (xbc + 29)
	jr Voice_Pitch_Legato_StoreOutput

Voice_Pitch_Legato_DetuneDown:
	ld xbc, (xwa + 35)
	add de, (xbc + 29)

Voice_Pitch_Legato_StoreOutput:
	ld wa, (xwa + 1)
	bit 10, wa
	jr z, Voice_Pitch_Legato_StoreOutput_Return
	addda16_24 xde, 267098

Voice_Pitch_Legato_StoreOutput_Return:
	ld wa, de
	calr SaturateS16_WA
	stw_da 0x0451da, xhl
	ret

Voice_Pitch_WriteOutputReg_Direct:
	ld bc, (xwa + 6)
	addda16 xbc, 10558
	ld (xwa + 10), bc
	ret

Voice_Pitch_WriteOutputReg_Secondary:
	ld de, (xwa + 10)
	addda16_24 xde, 267079
	ld xbc, (xwa + 39)
	ld bc, (xbc + 24)
	bit 4, bc
	jr z, Voice_Pitch_Secondary_StoreOutput
	ld xbc, (xwa + 39)
	ld bc, (xbc + 24)
	bit 5, bc
	jr z, Voice_Pitch_Secondary_DetuneDown
	ld xwa, (xwa + 35)
	sub de, (xwa + 29)
	jr Voice_Pitch_Secondary_StoreOutput

Voice_Pitch_Secondary_DetuneDown:
	ld xwa, (xwa + 35)
	add de, (xwa + 29)

Voice_Pitch_Secondary_StoreOutput:
	ld wa, de
	calr SaturateS16_WA
	stw_da 0x0451da, xhl
	ret

Voice_Level_ComputeTriplet:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 16), xwa
	ld xwa, (xsp + 16)
	ld xiz, (xwa + 23)
	cp (xiz + 7), 0x0
	jr ge, Voice_Level_Triplet_Positive
	ld a, (xiz + 10)
	exts wa
	cpl wa
	inc 1, wa
	ld (xsp + 4), wa
	ld a, (xiz + 12)
	exts wa
	cpl wa
	inc 1, wa
	ld (xsp + 6), wa
	ld a, (xiz + 14)
	exts wa
	cpl wa
	inc 1, wa
	ld (xsp + 8), wa
	jr Voice_Level_Triplet_ModByEnv

Voice_Level_Triplet_Positive:
	ld a, (xiz + 10)
	exts wa
	ld (xsp + 4), wa
	ld a, (xiz + 12)
	exts wa
	ld (xsp + 6), wa
	ld a, (xiz + 14)
	exts wa
	ld (xsp + 8), wa

Voice_Level_Triplet_ModByEnv:
	cp (xiz + 17), 0x0
	jrl z, Voice_Level_Triplet_Unmodulated
	ld a, (xiz + 17)
	ld e, a
	exts de
	ld xwa, (xsp + 16)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	cp (xiz + 9), 0x0
	jr z, Voice_Level_Ch1_Unmodulated
	ld de, hl
	ld a, (xiz + 9)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	add wa, de
	ld (xsp + 10), wa
	jr Voice_Level_Ch2_Modulated

Voice_Level_Ch1_Unmodulated:
	ld a, (xiz + 9)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 10), wa

Voice_Level_Ch2_Modulated:
	cp (xiz + 11), 0x0
	jr z, Voice_Level_Ch2_Unmodulated
	ld de, hl
	ld a, (xiz + 11)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	add wa, de
	ld (xsp + 12), wa
	jr Voice_Level_Ch3_Modulated

Voice_Level_Ch2_Unmodulated:
	ld a, (xiz + 11)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 12), wa

Voice_Level_Ch3_Modulated:
	cp (xiz + 13), 0x0
	jr z, Voice_Level_Ch3_Unmodulated
	ld a, (xiz + 13)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	add wa, hl
	ld (xsp + 14), wa
	jr Voice_Level_ApplyVelocityMod

Voice_Level_Ch3_Unmodulated:
	ld a, (xiz + 13)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 14), wa
	jr Voice_Level_ApplyVelocityMod

Voice_Level_Triplet_Unmodulated:
	ld a, (xiz + 9)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 10), wa
	ld a, (xiz + 11)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 12), wa
	ld a, (xiz + 13)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 14), wa

Voice_Level_ApplyVelocityMod:
	cp (xiz + 20), 0x0
	jr z, Voice_Level_PackAndStore
	ld a, (xiz + 19)
	ld c, a
	extz bc
	pushw 0x7F
	ld a, (xiz + 20)
	exts wa
	pushw wa
	ld xwa, (xsp + 20)
	ld wa, (xwa + 8)
	lds de, 0
	calr Pan_ScaleWithVelocity
	add (xsp + 10), hl

Voice_Level_PackAndStore:
	ld wa, (xsp + 10)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl
	ld wa, (xsp + 4)
	calr Detune_ScaleSymmetric
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	ldb w, 0x0
	ld bc, (xsp + 10)
	sla bc, 8
	or bc, wa
	stw_da 0x0451ec, xbc
	cp (xiz + 21), 0x0
	jr z, Voice_Level_PackAndStore_NoVelocityMod
	ld a, (xiz + 19)
	ld c, a
	extz bc
	pushw 0x7F
	ld a, (xiz + 21)
	exts wa
	pushw wa
	ld xwa, (xsp + 20)
	ld wa, (xwa + 8)
	lds de, 0
	calr Pan_ScaleWithVelocity
	ld iz, hl
	ld wa, (xsp + 12)
	add wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 12), hl
	ld wa, (xsp + 14)
	add wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 14), hl
	jr Voice_Level_PackSideChannels

Voice_Level_PackAndStore_NoVelocityMod:
	ld wa, (xsp + 12)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 12), hl
	ld wa, (xsp + 14)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 14), hl

Voice_Level_PackSideChannels:
	ld wa, (xsp + 6)
	calr Detune_ScaleSymmetric
	ld (xsp + 6), hl
	ld wa, (xsp + 8)
	calr Detune_ScaleSymmetric
	ld (xsp + 8), hl
	ld wa, (xsp + 6)
	ldb w, 0x0
	ld bc, (xsp + 12)
	sla bc, 8
	or bc, wa
	stw_da 0x0451ee, xbc
	ld wa, (xsp + 8)
	ldb w, 0x0
	ld bc, (xsp + 14)
	sla bc, 8
	or bc, wa
	stw_da 0x0451f0, xbc
	pop xiz
	lda xsp, (xsp + 16)
	ret

Voice_PitchPack_Mode1:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 103)
	ld c, a
	exts bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 77)
	ldb_erp A, 0xF8
	extz iz
	add iz, bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 55)
	ld e, a
	exts de
	ld xwa, (xsp + 2)
	ld a, (xwa + 60)
	exts wa
	pushw wa
	ld xwa, (xsp + 8)
	ld bc, iz
	calr Portamento_CalcContrib_A
	ld iz, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 78)
	extz wa
	sll wa, 13
	ld de, wa
	set 10, de
	ld wa, iz
	ld bc, wa
	or bc, de
	ld xwa, (xsp + 6)
	ld (xwa + 66), bc
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld wa, (xwa + 2)
	bit 9, wa
	jr z, Voice_PitchPack_Mode1_UseVoiceLUT
	ldw wa, 0x48
	calr Portamento_ClampAdd18
	ld iz, hl
	ldw wa, 0x8D
	calr PitchBend_LookupCoeff
	ld wa, iz
	ld bc, wa
	or bc, hl
	ld xwa, (xsp + 6)
	ld (xwa + 68), bc
	jr Voice_PitchPack_Mode1_Return

Voice_PitchPack_Mode1_UseVoiceLUT:
	ld xwa, (xsp + 2)
	ld a, (xwa + 79)
	extz wa
	calr Portamento_ClampAdd18
	ld iz, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 80)
	extz wa
	calr PitchBend_LookupCoeff
	ld wa, iz
	ld bc, wa
	or bc, hl
	ld xwa, (xsp + 6)
	ld (xwa + 68), bc

Voice_PitchPack_Mode1_Return:
	popw iz
	inc 8, xsp
	ret

Voice_PitchPack_Mode2:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld wa, (xwa + 2)
	bit 9, wa
	jr z, Voice_PitchPack_Mode2_AltPath
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 103)
	ld c, a
	exts bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 77)
	ldb_erp A, 0xF8
	extz iz
	sub iz, bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 55)
	ld e, a
	exts de
	ld xwa, (xsp + 2)
	ld a, (xwa + 60)
	exts wa
	pushw wa
	ld xwa, (xsp + 8)
	ld bc, iz
	calr Portamento_CalcContrib_A
	ld iz, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 78)
	extz wa
	sll wa, 13
	ld bc, wa
	set 10, bc
	ld wa, iz
	or wa, bc
	ld bc, wa
	set 7, bc
	ld xwa, (xsp + 6)
	ld (xwa + 66), bc
	ldw wa, 0x48
	calr Portamento_ClampAdd18
	ld iz, hl
	ldw wa, 0x8D
	calr PitchBend_LookupCoeff
	ld wa, iz
	ld bc, wa
	or bc, hl
	ld xwa, (xsp + 6)
	ld (xwa + 68), bc
	jr Voice_PitchPack_Mode2_Return

Voice_PitchPack_Mode2_AltPath:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 103)
	ld c, a
	exts bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 77)
	ldb_erp A, 0xF8
	extz iz
	add iz, bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 55)
	ld e, a
	exts de
	ld xwa, (xsp + 2)
	ld a, (xwa + 60)
	exts wa
	pushw wa
	ld xwa, (xsp + 8)
	ld bc, iz
	calr Portamento_CalcContrib_A
	ld iz, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 78)
	extz wa
	sll wa, 13
	ld bc, wa
	set 10, bc
	ld wa, iz
	or wa, bc
	ld bc, wa
	set 7, bc
	ld xwa, (xsp + 6)
	ld (xwa + 66), bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 79)
	extz wa
	calr Portamento_ClampAdd18
	ld iz, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 80)
	extz wa
	calr PitchBend_LookupCoeff
	ld wa, iz
	ld bc, wa
	or bc, hl
	ld xwa, (xsp + 6)
	ld (xwa + 68), bc

Voice_PitchPack_Mode2_Return:
	popw iz
	inc 8, xsp
	ret

Voice_PitchPack_Mode3:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld wa, (xwa + 2)
	bit 9, wa
	jr z, Voice_PitchPack_Mode3_AltPath
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 103)
	ld c, a
	exts bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 77)
	ldb_erp A, 0xF8
	extz iz
	add iz, bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 55)
	ld e, a
	exts de
	ld xwa, (xsp + 2)
	ld a, (xwa + 60)
	exts wa
	pushw wa
	ld xwa, (xsp + 8)
	ld bc, iz
	calr Portamento_CalcContrib_A
	ld iz, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 78)
	extz wa
	sll wa, 13
	ld de, wa
	set 10, de
	ld wa, iz
	ld bc, wa
	or bc, de
	ld xwa, (xsp + 6)
	ld (xwa + 66), bc
	ldw wa, 0x48
	calr Portamento_ClampAdd18
	ld iz, hl
	ldw wa, 0x8D
	calr PitchBend_LookupCoeff
	ld wa, iz
	ld bc, wa
	or bc, hl
	ld xwa, (xsp + 6)
	ld (xwa + 68), bc
	jr Voice_PitchPack_Mode3_Return

Voice_PitchPack_Mode3_AltPath:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 103)
	ld c, a
	exts bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 77)
	ldb_erp A, 0xF8
	extz iz
	add iz, bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 55)
	ld e, a
	exts de
	ld xwa, (xsp + 2)
	ld a, (xwa + 60)
	exts wa
	pushw wa
	ld xwa, (xsp + 8)
	ld bc, iz
	calr Portamento_CalcContrib_A
	ld iz, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 78)
	extz wa
	ld bc, wa
	sll bc, 10
	ld xwa, (xsp + 2)
	ld a, (xwa + 78)
	extz wa
	ld de, wa
	sll de, 13
	or de, bc
	ld wa, iz
	ld bc, wa
	or bc, de
	ld xwa, (xsp + 6)
	ld (xwa + 66), bc
	ld xwa, (xsp + 6)
	ld (xwa + 68), iz
	stdi16 10560, 0

Voice_PitchPack_Mode3_Return:
	popw iz
	inc 8, xsp
	ret

Voice_PitchPack_Mode4_Single:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 23)
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 35)
	ld wa, (xwa + 2)
	bit 9, wa
	jr z, Voice_PitchPack_Mode4_AltPath
	ld l, (xiz + 77)
	extz hl
	jr Voice_PitchPack_Mode4_Finalize

Voice_PitchPack_Mode4_AltPath:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 35)
	ld a, (xwa + 103)
	exts wa
	ld l, (xiz + 77)
	extz hl
	add hl, wa

Voice_PitchPack_Mode4_Finalize:
	ld a, (xiz + 55)
	ld e, a
	exts de
	ld a, (xiz + 60)
	exts wa
	pushw wa
	ld xwa, (xsp + 6)
	ld bc, hl
	calr Portamento_CalcContrib_A
	ld a, (xiz + 78)
	extz wa
	ld bc, wa
	sll bc, 10
	ld a, (xiz + 78)
	extz wa
	ld de, wa
	sll de, 13
	or de, bc
	ld wa, hl
	or wa, de
	ld bc, wa
	set 7, bc
	ld xwa, (xsp + 4)
	ld (xwa + 66), bc
	set 7, hl
	ld xwa, (xsp + 4)
	ld (xwa + 68), hl
	stdi16 10560, 0
	pop xiz
	inc 4, xsp
	ret

Voice_PitchPack_Mode5_Dual:
	dec 8, xsp
	push xiz
	ld (xsp + 8), xwa
	ld xwa, (xsp + 8)
	ld xiz, (xwa + 23)
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 35)
	ld wa, (xwa + 2)
	bit 9, wa
	jr z, Voice_PitchPack_Mode5_ApplyDetune
	ld a, (xiz + 77)
	extz wa
	ld (xsp + 4), wa
	ld a, (xiz + 79)
	extz wa
	ld (xsp + 6), wa
	jr Voice_PitchPack_Mode5_Finalize

Voice_PitchPack_Mode5_ApplyDetune:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 35)
	ld a, (xwa + 103)
	ld c, a
	exts bc
	ld a, (xiz + 77)
	extz wa
	add wa, bc
	ld (xsp + 4), wa
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 35)
	ld a, (xwa + 103)
	ld c, a
	exts bc
	ld a, (xiz + 79)
	extz wa
	add wa, bc
	ld (xsp + 6), wa

Voice_PitchPack_Mode5_Finalize:
	ld a, (xiz + 55)
	ld e, a
	exts de
	ld a, (xiz + 60)
	exts wa
	pushw wa
	ld xwa, (xsp + 10)
	ld bc, (xsp + 6)
	calr Portamento_CalcContrib_A
	ld (xsp + 4), hl
	ld a, (xiz + 55)
	ld e, a
	exts de
	ld a, (xiz + 60)
	exts wa
	pushw wa
	ld xwa, (xsp + 10)
	ld bc, (xsp + 8)
	calr Portamento_CalcContrib_A
	ld (xsp + 6), hl
	ld a, (xiz + 80)
	extz wa
	ld bc, wa
	sll bc, 10
	ld a, (xiz + 78)
	extz wa
	ld de, wa
	sll de, 13
	or de, bc
	ld wa, (xsp + 4)
	or wa, de
	ld bc, wa
	set 7, bc
	ld xwa, (xsp + 8)
	ld (xwa + 66), bc
	ld xwa, (xsp + 8)
	ld bc, (xsp + 6)
	ld (xwa + 68), bc
	stdi16 10560, 0
	pop xiz
	inc 8, xsp
	ret

Voice_PitchPack_Dispatch:
	ld xbc, (xwa + 23)
	ld c, (xbc + 54)
	and c, 0x7
	extz bc
	cps bc, 0
	jr mi, Voice_PitchPack_Dispatch_Table
	cps bc, 5
	jr gt, Voice_PitchPack_Dispatch_Table
	add bc, bc
	lda_24 xix, 0x00f6a7
	ldw_sri BC, 0x07, 0xF0, 0xE4
	lda_24 xix, 0x02412b
	jp_ind 8, 0x07, 0xF0, 0xE4

Voice_PitchPack_Dispatch_Table:
	jrl NoteState_InitDefaults
	jrl Voice_PitchPack_Mode1
	jrl Voice_PitchPack_Mode2
	jrl Voice_PitchPack_Mode3
	jrl Voice_PitchPack_Mode4_Single
	calr Voice_PitchPack_Mode5_Dual
	ret

Voice_PitchPack_RouteA:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	ld a, (xwa + 17)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	calr Portamento_CalcContrib_B
	ld iz, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 18)
	extz wa
	sll wa, 13
	ld de, wa
	set 10, de
	ld wa, iz
	ld bc, wa
	or bc, de
	ld xwa, (xsp + 6)
	ld (xwa + 66), bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 19)
	extz wa
	calr Portamento_ClampAdd18
	ld iz, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 20)
	extz wa
	calr PitchBend_LookupCoeff
	ld wa, iz
	ld bc, wa
	or bc, hl
	ld xwa, (xsp + 6)
	ld (xwa + 68), bc
	popw iz
	inc 8, xsp
	ret

Voice_PitchPack_RouteB:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	ld a, (xwa + 17)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	calr Portamento_CalcContrib_B
	ld iz, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 18)
	extz wa
	sll wa, 13
	ld bc, wa
	set 10, bc
	ld wa, iz
	or wa, bc
	ld bc, wa
	set 7, bc
	ld xwa, (xsp + 6)
	ld (xwa + 66), bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 19)
	extz wa
	calr Portamento_ClampAdd18
	ld iz, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 20)
	extz wa
	calr PitchBend_LookupCoeff
	ld wa, iz
	ld bc, wa
	or bc, hl
	ld xwa, (xsp + 6)
	ld (xwa + 68), bc
	popw iz
	inc 8, xsp
	ret

Voice_PitchPack_RouteC:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 23)
	ld a, (xiz + 17)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	calr Portamento_CalcContrib_B
	ld a, (xiz + 18)
	extz wa
	ld bc, wa
	sll bc, 10
	ld a, (xiz + 18)
	extz wa
	ld de, wa
	sll de, 13
	or de, bc
	ld wa, hl
	ld bc, wa
	or bc, de
	ld xwa, (xsp + 4)
	ld (xwa + 66), bc
	ld xwa, (xsp + 4)
	ld (xwa + 68), hl
	stdi16 10560, 0
	pop xiz
	inc 4, xsp
	ret

Voice_PitchPack_RouteD:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 23)
	ld a, (xiz + 17)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	calr Portamento_CalcContrib_B
	ld a, (xiz + 18)
	extz wa
	ld bc, wa
	sll bc, 10
	ld a, (xiz + 18)
	extz wa
	ld de, wa
	sll de, 13
	or de, bc
	ld wa, hl
	or wa, de
	ld bc, wa
	set 7, bc
	ld xwa, (xsp + 4)
	ld (xwa + 66), bc
	set 7, hl
	ld xwa, (xsp + 4)
	ld (xwa + 68), hl
	stdi16 10560, 0
	pop xiz
	inc 4, xsp
	ret

Voice_PitchPack_RouteE:
	dec 6, xsp
	push xiz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xiz, (xwa + 23)
	ld a, (xiz + 17)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	calr Portamento_CalcContrib_B
	ld (xsp + 4), hl
	ld a, (xiz + 19)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	calr Portamento_CalcContrib_B
	ld a, (xiz + 20)
	extz wa
	ld bc, wa
	sll bc, 10
	ld a, (xiz + 18)
	extz wa
	ld de, wa
	sll de, 13
	or de, bc
	ld wa, (xsp + 4)
	or wa, de
	ld bc, wa
	set 7, bc
	ld xwa, (xsp + 6)
	ld (xwa + 66), bc
	ld xwa, (xsp + 6)
	ld (xwa + 68), hl
	stdi16 10560, 0
	pop xiz
	inc 6, xsp
	ret

Voice_PitchReg_WriteDispatch:
	push xiz
	ld xiz, xwa
	ld xwa, (xiz + 23)
	ld a, (xwa + 15)
	and a, 0x7
	extz wa
	cps wa, 0
	jr mi, Voice_PitchReg_WriteDispatch_Table
	cps wa, 5
	jr gt, Voice_PitchReg_WriteDispatch_Table
	add wa, wa
	lda_24 xix, 0x00f6b3
	ldw_sri WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0x02432c
	jp_ind 8, 0x07, 0xF0, 0xE0

Voice_PitchReg_WriteDispatch_Table:
	ld xwa, xiz
	calr NoteState_InitDefaults
	ld wa, (xiz + 66)
	stw_da 0x0451d4, xwa
	ld wa, (xiz + 68)
	stw_da 0x0451d6, xwa
	jr Voice_PitchReg_WriteDispatch_Return
	ld xwa, xiz
	calr Voice_PitchPack_RouteA
	jr Voice_PitchReg_WriteDispatch_Return
	ld xwa, xiz
	calr Voice_PitchPack_RouteB
	jr Voice_PitchReg_WriteDispatch_Return
	ld xwa, xiz
	calr Voice_PitchPack_RouteC
	jr Voice_PitchReg_WriteDispatch_Return
	ld xwa, xiz
	calr Voice_PitchPack_RouteD
	jr Voice_PitchReg_WriteDispatch_Return
	ld xwa, xiz
	calr Voice_PitchPack_RouteE

Voice_PitchReg_WriteDispatch_Return:
	pop xiz
	ret

Voice_Pan_WriteWithDetune:
	push xiz
	ld xiz, xwa
	ld xwa, (xiz + 39)
	ld wa, (xwa + 24)
	bit 6, wa
	jr z, Voice_Pan_Write_AsIs
	ld xwa, (xiz + 39)
	ld wa, (xwa + 24)
	bit 7, wa
	jr z, Voice_Pan_WriteWithDetune_Positive
	ld xwa, (xiz + 35)
	ld a, (xwa + 31)
	exts wa
	ld bc, (xiz + 66)
	and bc, 0x7F
	sub bc, wa
	ld wa, bc
	jr Voice_Pan_WriteWithDetune_Clamp

Voice_Pan_WriteWithDetune_Positive:
	ld xwa, (xiz + 35)
	ld a, (xwa + 31)
	exts wa
	ld bc, (xiz + 66)
	and bc, 0x7F
	add bc, wa
	ld wa, bc

Voice_Pan_WriteWithDetune_Clamp:
	calr ClampS8_0_to_78
	ld wa, (xiz + 66)
	and wa, 0xFF80
	or wa, hl
	stw_da 0x0451d4, xwa
	jr Voice_Pan_WriteSecondary

Voice_Pan_Write_AsIs:
	ld wa, (xiz + 66)
	stw_da 0x0451d4, xwa

Voice_Pan_WriteSecondary:
	ld wa, (xiz + 68)
	stw_da 0x0451d6, xwa
	pop xiz
	ret

Voice_Pan_WriteBothWithDetune:
	push xiz
	ld xiz, xwa
	ld xwa, (xiz + 39)
	ld wa, (xwa + 24)
	bit 6, wa
	jr z, Voice_Pan_WriteBoth_AsIs
	ld xwa, (xiz + 39)
	ld wa, (xwa + 24)
	bit 7, wa
	jr z, Voice_Pan_WriteBoth_Positive
	ld xwa, (xiz + 35)
	ld a, (xwa + 31)
	exts wa
	ld bc, (xiz + 66)
	and bc, 0x7F
	sub bc, wa
	ld hl, bc
	jr Voice_Pan_WriteBoth_Clamp

Voice_Pan_WriteBoth_Positive:
	ld xwa, (xiz + 35)
	ld a, (xwa + 31)
	exts wa
	ld bc, (xiz + 66)
	and bc, 0x7F
	add bc, wa
	ld hl, bc

Voice_Pan_WriteBoth_Clamp:
	ld wa, hl
	calr ClampS8_0_to_78
	ld wa, hl
	ld bc, (xiz + 66)
	and bc, 0xFF80
	or bc, wa
	stw_da 0x0451d4, xbc
	ld wa, (xiz + 68)
	and wa, 0xFF80
	or wa, hl
	stw_da 0x0451d6, xwa
	jr Voice_Pan_WriteBoth_Return

Voice_Pan_WriteBoth_AsIs:
	ld wa, (xiz + 66)
	stw_da 0x0451d4, xwa
	ld wa, (xiz + 68)
	stw_da 0x0451d6, xwa

Voice_Pan_WriteBoth_Return:
	pop xiz
	ret

Voice_PanReg_WriteDispatch:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ld xwa, (xiz + 23)
	ld a, (xwa + 54)
	and a, 0x7
	extz wa
	cps wa, 0
	jr mi, Voice_PanReg_WriteDispatch_Table
	cps wa, 5
	jr gt, Voice_PanReg_WriteDispatch_Table
	add wa, wa
	lda_24 xix, 0x00f6bf
	ldw_sri WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0x024472
	jp_ind 8, 0x07, 0xF0, 0xE0

Voice_PanReg_WriteDispatch_Table:
	ld wa, (xiz + 66)
	stw_da 0x0451d4, xwa
	ld wa, (xiz + 68)
	stw_da 0x0451d6, xwa
	jrl Voice_PanReg_WriteDispatch_Return
	ld xwa, xiz
	calr Voice_Pan_WriteWithDetune
	jrl Voice_PanReg_WriteDispatch_Return
	ld xwa, (xiz + 35)
	ld wa, (xwa + 2)
	bit 9, wa
	jr z, Voice_PanReg_Dispatch_Mode2_CheckBit9
	ld xwa, xiz
	calr Voice_Pan_WriteWithDetune
	jrl Voice_PanReg_WriteDispatch_Return

Voice_PanReg_Dispatch_Mode2_CheckBit9:
	ld xwa, xiz
	calr Voice_Pan_WriteBothWithDetune
	jrl Voice_PanReg_WriteDispatch_Return
	ld xwa, xiz
	calr Voice_Pan_WriteBothWithDetune
	jrl Voice_PanReg_WriteDispatch_Return
	ld xwa, (xiz + 39)
	ld wa, (xwa + 24)
	bit 6, wa
	jrl z, Voice_PanReg_Dispatch_Mode5_AsIs
	ld xwa, (xiz + 39)
	ld wa, (xwa + 24)
	bit 7, wa
	jr z, Voice_PanReg_Dispatch_Mode5_Positive
	ld xwa, (xiz + 35)
	ld a, (xwa + 31)
	exts wa
	ld bc, (xiz + 66)
	and bc, 0x7F
	sub bc, wa
	ld de, bc
	ld xwa, (xiz + 35)
	ld a, (xwa + 31)
	exts wa
	ld bc, (xiz + 68)
	and bc, 0x7F
	sub bc, wa
	ld (xsp + 4), bc
	jr Voice_PanReg_Dispatch_Mode5_Finalize

Voice_PanReg_Dispatch_Mode5_Positive:
	ld xwa, (xiz + 35)
	ld a, (xwa + 31)
	exts wa
	ld bc, (xiz + 66)
	and bc, 0x7F
	add bc, wa
	ld de, bc
	ld xwa, (xiz + 35)
	ld a, (xwa + 31)
	exts wa
	ld bc, (xiz + 68)
	and bc, 0x7F
	add bc, wa
	ld (xsp + 4), bc

Voice_PanReg_Dispatch_Mode5_Finalize:
	ld wa, de
	calr ClampS8_0_to_78
	ld wa, (xiz + 66)
	and wa, 0xFF80
	or wa, hl
	stw_da 0x0451d4, xwa
	ld wa, (xsp + 4)
	calr ClampS8_0_to_78
	ld wa, (xiz + 68)
	and wa, 0xFF80
	or wa, hl
	stw_da 0x0451d6, xwa
	jr Voice_PanReg_WriteDispatch_Return

Voice_PanReg_Dispatch_Mode5_AsIs:
	ld wa, (xiz + 66)
	stw_da 0x0451d4, xwa
	ld wa, (xiz + 68)
	stw_da 0x0451d6, xwa

Voice_PanReg_WriteDispatch_Return:
	pop xiz
	inc 2, xsp
	ret

Voice_PanReg_WriteDispatchB:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ld xwa, (xiz + 23)
	ld a, (xwa + 15)
	and a, 0x7
	extz wa
	cps wa, 0
	jr mi, Voice_PanReg_WriteDispatchB_Table
	cps wa, 5
	jr gt, Voice_PanReg_WriteDispatchB_Table
	add wa, wa
	lda_24 xix, 0x00f6cb
	ldw_sri WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0x024582
	jp_ind 8, 0x07, 0xF0, 0xE0

Voice_PanReg_WriteDispatchB_Table:
	ld wa, (xiz + 66)
	stw_da 0x0451d4, xwa
	ld wa, (xiz + 68)
	stw_da 0x0451d6, xwa
	jrl Voice_PanReg_WriteDispatchB_Return
	ld xwa, xiz
	calr Voice_Pan_WriteWithDetune
	jrl Voice_PanReg_WriteDispatchB_Return
	ld xwa, (xiz + 35)
	ld wa, (xwa + 2)
	bit 9, wa
	jr z, Voice_PanReg_DispatchB_Mode2_CheckBit9
	ld xwa, xiz
	calr Voice_Pan_WriteWithDetune
	jrl Voice_PanReg_WriteDispatchB_Return

Voice_PanReg_DispatchB_Mode2_CheckBit9:
	ld xwa, xiz
	calr Voice_Pan_WriteBothWithDetune
	jrl Voice_PanReg_WriteDispatchB_Return
	ld xwa, xiz
	calr Voice_Pan_WriteBothWithDetune
	jrl Voice_PanReg_WriteDispatchB_Return
	ld xwa, (xiz + 39)
	ld wa, (xwa + 24)
	bit 6, wa
	jrl z, Voice_PanReg_DispatchB_Mode5_AsIs
	ld xwa, (xiz + 39)
	ld wa, (xwa + 24)
	bit 7, wa
	jr z, Voice_PanReg_DispatchB_Mode5_Positive
	ld xwa, (xiz + 35)
	ld a, (xwa + 31)
	exts wa
	ld bc, (xiz + 66)
	and bc, 0x7F
	sub bc, wa
	ld de, bc
	ld xwa, (xiz + 35)
	ld a, (xwa + 31)
	exts wa
	ld bc, (xiz + 68)
	and bc, 0x7F
	sub bc, wa
	ld (xsp + 4), bc
	jr Voice_PanReg_DispatchB_Mode5_Finalize

Voice_PanReg_DispatchB_Mode5_Positive:
	ld xwa, (xiz + 35)
	ld a, (xwa + 31)
	exts wa
	ld bc, (xiz + 66)
	and bc, 0x7F
	add bc, wa
	ld de, bc
	ld xwa, (xiz + 35)
	ld a, (xwa + 31)
	exts wa
	ld bc, (xiz + 68)
	and bc, 0x7F
	add bc, wa
	ld (xsp + 4), bc

Voice_PanReg_DispatchB_Mode5_Finalize:
	ld wa, de
	calr ClampS8_0_to_78
	ld wa, (xiz + 66)
	and wa, 0xFF80
	or wa, hl
	stw_da 0x0451d4, xwa
	ld wa, (xsp + 4)
	calr ClampS8_0_to_78
	ld wa, (xiz + 68)
	and wa, 0xFF80
	or wa, hl
	stw_da 0x0451d6, xwa
	jr Voice_PanReg_WriteDispatchB_Return

Voice_PanReg_DispatchB_Mode5_AsIs:
	ld wa, (xiz + 66)
	stw_da 0x0451d4, xwa
	ld wa, (xiz + 68)
	stw_da 0x0451d6, xwa

Voice_PanReg_WriteDispatchB_Return:
	pop xiz
	inc 2, xsp
	ret

Voice_StereoLevel_Compute:
	lda xsp, (xsp - 14)
	pushw iz
	ld (xsp + 12), xwa
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	cp (xwa + 71), 0x0
	jrl z, Voice_StereoLevel_AllUnmodulated
	ld xwa, (xsp + 2)
	ld a, (xwa + 71)
	ld e, a
	exts de
	ld xwa, (xsp + 12)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ld xwa, (xsp + 2)
	cp (xwa + 63), 0x0
	jr z, Voice_StereoLevel_Ch1_Unmodulated
	ld de, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 63)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	add wa, de
	ld (xsp + 6), wa
	jr Voice_StereoLevel_Ch2_Modulated

Voice_StereoLevel_Ch1_Unmodulated:
	ld xwa, (xsp + 2)
	ld a, (xwa + 63)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 6), wa

Voice_StereoLevel_Ch2_Modulated:
	ld xwa, (xsp + 2)
	cp (xwa + 65), 0x0
	jr z, Voice_StereoLevel_Ch2_Unmodulated
	ld de, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 65)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	add wa, de
	ld (xsp + 8), wa
	jr Voice_StereoLevel_Ch3_Modulated

Voice_StereoLevel_Ch2_Unmodulated:
	ld xwa, (xsp + 2)
	ld a, (xwa + 65)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 8), wa

Voice_StereoLevel_Ch3_Modulated:
	ld xwa, (xsp + 2)
	cp (xwa + 67), 0x0
	jr z, Voice_StereoLevel_Ch3_Unmodulated
	ld xwa, (xsp + 2)
	ld a, (xwa + 67)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	add wa, hl
	ld (xsp + 10), wa
	jr Voice_StereoLevel_ApplyTremolo

Voice_StereoLevel_Ch3_Unmodulated:
	ld xwa, (xsp + 2)
	ld a, (xwa + 67)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 10), wa
	jr Voice_StereoLevel_ApplyTremolo

Voice_StereoLevel_AllUnmodulated:
	ld xwa, (xsp + 2)
	ld a, (xwa + 63)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 6), wa
	ld xwa, (xsp + 2)
	ld a, (xwa + 65)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 8), wa
	ld xwa, (xsp + 2)
	ld a, (xwa + 67)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 10), wa

Voice_StereoLevel_ApplyTremolo:
	ld xwa, (xsp + 2)
	cp (xwa + 74), 0x0
	jr z, Voice_StereoLevel_PackCh1
	ld xwa, (xsp + 2)
	ld a, (xwa + 73)
	ld c, a
	extz bc
	pushw 0x7F
	ld xwa, (xsp + 4)
	ld a, (xwa + 74)
	exts wa
	pushw wa
	ld xwa, (xsp + 16)
	ld wa, (xwa + 8)
	lds de, 0
	calr Pan_ScaleWithVelocity
	add (xsp + 6), hl

Voice_StereoLevel_PackCh1:
	ld wa, (xsp + 6)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 6), hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 61)
	ld c, a
	exts bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 64)
	exts wa
	add wa, bc
	ldw bc, 0x32
	ldw de, 0xFFCE
	calr ClampS16_WA_To_DEBC
	ld wa, hl
	calr Detune_ScaleSymmetric
	ldb h, 0x0
	ld wa, (xsp + 6)
	sla wa, 8
	or wa, hl
	stw_da 0x0451f2, xwa
	ld xwa, (xsp + 2)
	cp (xwa + 75), 0x0
	jr z, Voice_StereoLevel_ClampCh23_NoMod
	ld xwa, (xsp + 2)
	ld a, (xwa + 73)
	ld c, a
	extz bc
	pushw 0x7F
	ld xwa, (xsp + 4)
	ld a, (xwa + 75)
	exts wa
	pushw wa
	ld xwa, (xsp + 16)
	ld wa, (xwa + 8)
	lds de, 0
	calr Pan_ScaleWithVelocity
	ld iz, hl
	ld wa, (xsp + 8)
	add wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 8), hl
	ld wa, (xsp + 10)
	add wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl
	jr Voice_StereoLevel_PackCh23

Voice_StereoLevel_ClampCh23_NoMod:
	ld wa, (xsp + 8)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 8), hl
	ld wa, (xsp + 10)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl

Voice_StereoLevel_PackCh23:
	ld xwa, (xsp + 2)
	ld a, (xwa + 61)
	ld c, a
	exts bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 66)
	exts wa
	add wa, bc
	ldw bc, 0x32
	ldw de, 0xFFCE
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	ld wa, iz
	calr Detune_ScaleSymmetric
	ld iz, hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 61)
	ld c, a
	exts bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 68)
	exts wa
	add wa, bc
	ldw bc, 0x32
	ldw de, 0xFFCE
	calr ClampS16_WA_To_DEBC
	ld wa, hl
	calr Detune_ScaleSymmetric
	ld wa, iz
	ldb w, 0x0
	ld bc, (xsp + 8)
	sla bc, 8
	or bc, wa
	stw_da 0x0451f4, xbc
	ldb h, 0x0
	ld wa, (xsp + 10)
	sla wa, 8
	or wa, hl
	stw_da 0x0451f6, xwa
	popw iz
	lda xsp, (xsp + 14)
	ret

Voice_PortaLevel_Compute:
	lda xsp, (xsp - 12)
	pushw iz
	ld (xsp + 10), xwa
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	cp (xwa + 7), 0x0
	jr ge, Voice_PortaLevel_Compute_Positive
	ld xwa, (xsp + 2)
	ld a, (xwa + 7)
	exts wa
	cpl wa
	inc 1, wa
	calr Detune_ScaleUnsigned
	ld (xsp + 8), hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 8)
	exts wa
	cpl wa
	inc 1, wa
	calr Detune_ScaleSymmetric
	ld (xsp + 6), hl
	jr Voice_PortaLevel_ScaleAndPack

Voice_PortaLevel_Compute_Positive:
	ld xwa, (xsp + 2)
	ld a, (xwa + 7)
	exts wa
	calr Detune_ScaleUnsigned
	ld (xsp + 8), hl
	ld xwa, (xsp + 2)
	ld a, (xwa + 8)
	exts wa
	calr Detune_ScaleSymmetric
	ld (xsp + 6), hl

Voice_PortaLevel_ScaleAndPack:
	ld xwa, (xsp + 2)
	ld a, (xwa + 18)
	ld e, a
	exts de
	ld xwa, (xsp + 10)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 6
	calr PitchBend_Scale
	add (xsp + 8), hl
	ld wa, (xsp + 8)
	ldw bc, 0x7F
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 8), hl
	ldw iz, 0x7F
	ld xwa, (xsp + 2)
	ld a, (xwa + 72)
	ld e, a
	exts de
	ld xwa, (xsp + 10)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 6
	calr PitchBend_Scale
	add iz, hl
	ld wa, iz
	ldw bc, 0x7F
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	ld wa, iz
	ld bc, wa
	ldb b, 0x0
	ld wa, (xsp + 8)
	sll wa, 8
	or wa, bc
	stw_da 0x0451e2, xwa
	ld xwa, (xsp + 2)
	ld c, (xwa + 61)
	ld xwa, (xsp + 2)
	add c, (xwa + 62)
	ld a, c
	exts wa
	calr Detune_ScaleSymmetric
	ldb h, 0x0
	ld wa, (xsp + 6)
	sll wa, 8
	or wa, hl
	stw_da 0x0451ea, xwa
	popw iz
	lda xsp, (xsp + 12)
	ret

Voice_Level_ClearAllOutputRegs:
	ld xhl, (xwa + 23)
	stiw_da 0x0451ea, 0x0000
	stiw_da 0x0451e2, 0x0000
	stiw_da 0x0451ec, 0x0000
	stiw_da 0x0451ee, 0x0000
	stiw_da 0x0451f0, 0x0000
	stiw_da 0x0451f2, 0x0000
	stiw_da 0x0451f4, 0x0000
	stiw_da 0x0451f6, 0x0000
	stiw_da 0x0451dc, 0x0000
	stiw_da 0x0451de, 0x0000
	ld c, (xwa + 4)
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04138e
	cpib_sri 0x07, 0xE8, 0xE4, 0x01
	jr nz, Voice_Level_ClearAllOutputRegs_Check2
	ldw (xwa + 43), 0x0
	jr Voice_Level_ClearAllOutputRegs_Store

Voice_Level_ClearAllOutputRegs_Check2:
	ld c, (xwa + 4)
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04138e
	cpib_sri 0x07, 0xE8, 0xE4, 0x02
	jr nz, Voice_Level_ClearAllOutputRegs_FromTable
	ldw (xwa + 43), 0x7F
	jr Voice_Level_ClearAllOutputRegs_Store

Voice_Level_ClearAllOutputRegs_FromTable:
	ld c, (xhl)
	extz bc
	ld (xwa + 43), bc

Voice_Level_ClearAllOutputRegs_Store:
	ld wa, (xwa + 43)
	stw_da 0x0451d8, xwa
	stiw_da 0x0451e0, 0x0000
	ret

Voice_OpSlot_WriteParams:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 12), xbc
	ld l, (xsp + 22)
	ld c, e
	extz bc
	ld ix, bc
	sla ix, 2
	ld c, l
	extz bc
	sla bc, 4
	ld iy, bc
	add iy, ix
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XBC, 0x07, 0xF0, 0xE4
	stb_dri A, 0x07, 0xE4, 0xF4
	ld (xsp + 4), xbc
	ld xbc, 0x2B
	add (xsp + 4), xbc
	ld c, l
	extz bc
	muls bc, 0x9
	ld iy, bc
	ld c, (xsp + 20)
	extz bc
	muls bc, 0x1B
	lda_24 xix, 0x04424e
	exts xbc
	add xbc, xix
	stb_dri H, 0x07, 0xE4, 0xF4
	ld c, e
	extz bc
	ld ix, bc
	sla ix, 2
	ld c, l
	extz bc
	sla bc, 4
	ld iy, bc
	add iy, ix
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xF4
	ld (xsp + 8), xwa
	ld xwa, 0x27
	add (xsp + 8), xwa
	cps l, 2
	jr z, Voice_OpSlot_WriteParams_Direct
	cps e, 0
	jr nz, Voice_OpSlot_WriteParams_Direct
	cpib_da 0x0451a7, 0xf5
	jr z, Voice_OpSlot_WriteParams_Direct
	ld xwa, (xsp + 12)
	ld a, (xwa + 104)
	ld c, a
	exts bc
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	add wa, bc
	ldw bc, 0x7F
	lds de, 0
	calr ClampS16_WA_Short
	ld (xiz + 1), l
	ld xwa, (xsp + 12)
	ld a, (xwa + 105)
	ld c, a
	exts bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 1)
	extz wa
	add wa, bc
	ldw bc, 0x7F
	lds de, 0
	calr ClampS16_WA_Short
	ld (xiz + 3), l
	ld xwa, (xsp + 12)
	ld a, (xwa + 106)
	ld c, a
	exts bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 3)
	and a, 0x3F
	extz wa
	add wa, bc
	ldw bc, 0x1E
	lds de, 0
	calr ClampS16_WA_Short
	ld (xiz + 7), l
	jr Voice_OpSlot_ApplySustainPedal

Voice_OpSlot_WriteParams_Direct:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	ld (xiz + 1), a
	ld xwa, (xsp + 4)
	ld a, (xwa + 1)
	ld (xiz + 3), a
	ld xwa, (xsp + 4)
	ld a, (xwa + 3)
	and a, 0x3F
	ld (xiz + 7), a

Voice_OpSlot_ApplySustainPedal:
	ld xwa, (xsp + 8)
	bitm 1, (xwa)
	jr z, Voice_OpSlot_SustainRelease_Set
	ld xwa, (xsp + 8)
	ld a, (xwa + 3)
	ld (xiz + 2), a
	ld (xiz + 7), 0x0
	jr Voice_OpSlot_ApplySostenuto

Voice_OpSlot_SustainRelease_Set:
	ld (xiz + 2), 0x80

Voice_OpSlot_ApplySostenuto:
	ld xwa, (xsp + 8)
	bitm 3, (xwa)
	jr z, Voice_OpSlot_SostenutoRelease_Set
	ld xwa, (xsp + 8)
	ld a, (xwa + 2)
	ld (xiz + 4), a
	ld (xiz + 7), 0x0
	jr Voice_OpSlot_CopyWaveformBits

Voice_OpSlot_SostenutoRelease_Set:
	ld (xiz + 4), 0x80

Voice_OpSlot_CopyWaveformBits:
	ld xwa, (xsp + 4)
	bitm 7, (xwa + 2)
	jr z, Voice_OpSlot_ClearWaveformBit5
	setm 5, (xiz)
	jr Voice_OpSlot_PackEnvelopeBits

Voice_OpSlot_ClearWaveformBit5:
	resm 5, (xiz)

Voice_OpSlot_PackEnvelopeBits:
	ld xwa, (xsp + 4)
	ld a, (xwa + 3)
	and a, 0xC0
	extz wa
	srl wa, 6
	andmi8 (xiz), 0xFC
	or (xiz), a
	ld xwa, (xsp + 4)
	ld a, (xwa + 2)
	res 7, a
	ld (xiz + 5), a
	pop xiz
	lda xsp, (xsp + 12)
	retd 0x4

Voice_Chan_ComputeParams:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 22), xwa
	stiw_da 0x0451dc, 0x0000
	stiw_da 0x0451de, 0x0000
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 35)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 39)
	ld (xsp + 8), xwa
	ld xwa, (xsp + 22)
	ld a, (xwa + 4)
	ld (xsp + 16), a
	ld xwa, (xsp + 22)
	ld a, (xwa + 3)
	ld (xsp + 18), a
	ld xwa, (xsp + 8)
	cpw (xwa + 26), 0x0
	jrl z, Voice_Chan_Fallback_NoWaveTable
	ld xwa, (xsp + 8)
	ld wa, (xwa + 26)
	and a, 0x3
	ld (xsp + 20), a
	extz wa
	sla wa, 2
	ld bc, wa
	add bc, 0x2B
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 19)
	stb_dri W, 0x07, 0xE0, 0xE4
	bitm 7, (xwa + 2)
	jr z, Voice_Chan_ComputeParams_NoAlgoSelect
	ld a, (xsp + 16)
	ld l, a
	extz hl
	ld xwa, (xsp + 22)
	ld a, (xwa)
	ld c, a
	extz bc
	ld a, (xsp + 20)
	extz wa
	set 5, wa
	ld e, a
	extz de
	ld wa, hl
	call VoiceSlot_Assign
	ld (xsp + 12), hl
	ld wa, (xsp + 12)
	ldb w, 0x0
	ld (xsp + 14), wa
	call ToneGen_WriteExtParam_600_Mute
	jr Voice_Chan_ResolveSlot

Voice_Chan_ComputeParams_NoAlgoSelect:
	ld a, (xsp + 16)
	ld l, a
	extz hl
	ld xwa, (xsp + 22)
	ld a, (xwa)
	ld c, a
	extz bc
	ld a, (xsp + 20)
	extz wa
	ld e, a
	extz de
	ld wa, hl
	call VoiceSlot_Assign
	ld (xsp + 12), hl
	ld wa, (xsp + 12)
	ldb w, 0x0
	ld (xsp + 14), wa

Voice_Chan_ResolveSlot:
	ld wa, (xsp + 14)
	extz xwa
	ld xbc, 0x1B
	call FP_MulAccum64
	lda_24 xiz, 0x04424e
	add xiz, xhl
	ld xwa, (xsp + 22)
	ld a, (xwa + 12)
	res 7, a
	ld (xiz + 6), a
	cpw (xsp + 14), 0x80
	jrl nc, Voice_Chan_SecondaryPitch_Trigger
	ld xwa, (xsp + 8)
	ld wa, (xwa + 26)
	and wa, 0xC0
	or wa, (xsp + 14)
	stw_da 0x0451dc, xwa
	ld wa, (xsp + 12)
	bit 15, wa
	jr z, Voice_Chan_WriteOpSlots
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	and wa, 0xC
	jr z, Voice_Chan_CheckPitchEnvGate

Voice_Chan_WriteOpSlots:
	ld a, (xsp + 16)
	ld c, a
	extz bc
	ld a, (xsp + 20)
	ld e, a
	extz de
	pushw 0x0
	ld wa, (xsp + 16)
	extz wa
	pushw wa
	ld wa, bc
	ld xbc, (xsp + 8)
	calr Voice_OpSlot_WriteParams
	ld wa, (xsp + 14)
	extz wa
	calr EGEnv_Compute_A_Simple
	stw_da 0x045208, xhl
	ld wa, (xsp + 14)
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParams_56_Alt

Voice_Chan_CheckPitchEnvGate:
	cp (xiz + 7), 0x0
	jr z, Voice_Chan_PitchEnvGate_CheckBit5
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	bit 13, wa
	jr nz, Voice_Chan_PitchEnvGate_Trigger

Voice_Chan_PitchEnvGate_CheckBit5:
	bitm 5, (xiz)
	jr z, Voice_Chan_PitchEnvFreeRun_Check

Voice_Chan_PitchEnvGate_Trigger:
	ld (xiz + 8), 0x0
	andmi8 (xiz), 0xF3
	setm 4, (xiz)
	stiw_da 0x04520c, 0x0000
	ld wa, (xsp + 14)
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParam_600
	jrl Voice_Chan_SecondaryPitch_Trigger

Voice_Chan_PitchEnvFreeRun_Check:
	cp (xiz + 5), 0x0
	jr nz, Voice_Chan_PitchEnvFreeRun_Trigger
	ld wa, (xsp + 12)
	bit 15, wa
	jr nz, Voice_Chan_ChokeGroup_Trigger

Voice_Chan_PitchEnvFreeRun_Trigger:
	ld a, (xiz)
	and a, 0x38
	jr nz, Voice_Chan_ChokeGroup_Trigger
	ld wa, (xsp + 14)
	extz wa
	calr EGEnv_Compute_A
	stw_da 0x04520c, xhl
	ld wa, (xsp + 14)
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParam_600
	jrl Voice_Chan_SecondaryPitch_Trigger

Voice_Chan_ChokeGroup_Trigger:
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	and wa, 0xC
	jrl z, Voice_Chan_SecondaryPitch_Trigger
	ld wa, (xsp + 14)
	extz wa
	calr EGEnv_Compute_A
	stw_da 0x04520c, xhl
	ld wa, (xsp + 14)
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParam_600
	jrl Voice_Chan_SecondaryPitch_Trigger

Voice_Chan_Fallback_NoWaveTable:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 10)
	extz xwa
	bit 15, wa
	jrl z, Voice_Chan_SecondaryPitch_Trigger
	ld a, (xsp + 16)
	ld e, a
	extz de
	ld a, (xsp + 18)
	ld c, a
	extz bc
	ld wa, de
	lds de, 1
	call DSP_AlgoType_Dispatch3
	ld (xsp + 20), hl
	cpw (xsp + 20), 0x0
	jr z, Voice_Chan_SecondaryPitch_Trigger
	ld a, (xsp + 16)
	ld e, a
	extz de
	ld xwa, (xsp + 22)
	ld a, (xwa)
	ld c, a
	extz bc
	ld wa, de
	ldw de, 0xD
	call VoiceSlot_Assign
	ld (xsp + 12), hl
	ld wa, (xsp + 12)
	ldb w, 0x0
	ld (xsp + 14), wa
	cpw (xsp + 14), 0x80
	jr nc, Voice_Chan_SecondaryPitch_Trigger
	ld wa, (xsp + 14)
	extz wa
	ld bc, wa
	lds wa, 0
	calr NoteState_ClearRecord
	ld wa, (xsp + 12)
	and wa, 0x7F
	or wa, (xsp + 20)
	stw_da 0x0451dc, xwa
	ld wa, (xsp + 12)
	bit 15, wa
	jr z, Voice_Chan_Fallback_WritePrecomputed
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	bit 2, wa
	jr z, Voice_Chan_SecondaryPitch_Trigger

Voice_Chan_Fallback_WritePrecomputed:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 91)
	stw_da 0x04520c, xwa
	ld xwa, (xsp + 4)
	ld wa, (xwa + 93)
	stw_da 0x045208, xwa
	ld wa, (xsp + 14)
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParams_56

Voice_Chan_SecondaryPitch_Trigger:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 10)
	extz xwa
	bit 15, wa
	jrl z, Voice_Chan_ComputeParams_Return
	ld a, (xsp + 16)
	ld e, a
	extz de
	ld a, (xsp + 18)
	ld c, a
	extz bc
	ld wa, de
	lds de, 0
	call DSP_AlgoType_Dispatch3
	ld (xsp + 20), hl
	cpw (xsp + 20), 0x0
	jrl z, Voice_Chan_ComputeParams_Return
	ld a, (xsp + 16)
	ld e, a
	extz de
	ld xwa, (xsp + 22)
	ld a, (xwa)
	ld c, a
	extz bc
	ld wa, de
	ldw de, 0xC
	call VoiceSlot_Assign
	ld (xsp + 12), hl
	ld wa, (xsp + 12)
	ldb w, 0x0
	ld (xsp + 14), wa
	cpw (xsp + 14), 0x80
	jr nc, Voice_Chan_ComputeParams_Return
	ld wa, (xsp + 14)
	or wa, (xsp + 20)
	stw_da 0x0451de, xwa
	ld a, (xsp + 16)
	extz wa
	call AlgoType_AB_Checker
	cps l, 0
	jr nz, Voice_Chan_SecondaryPitch_ComputeDelta
	ld wa, (xsp + 12)
	bit 15, wa
	jr z, Voice_Chan_SecondaryPitch_ComputeDelta
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	bit 2, wa
	jr z, Voice_Chan_ComputeParams_Return

Voice_Chan_SecondaryPitch_ComputeDelta:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 87)
	stw_da 0x04520e, xwa
	ldw_da xiz, 0x04520e
	extz xiz
	and xiz, 0x1FFF
	ld xwa, (xsp + 22)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld e, l
	extz de
	ld xwa, xiz
	calr EnvDepth_Cap
	sub xiz, xhl
	anddi16_24 283150, 57344
	ld wa, iz
	ordm16_24 283150, xwa
	ld xwa, (xsp + 4)
	ld wa, (xwa + 89)
	stw_da 0x04520a, xwa
	ld wa, (xsp + 14)
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParams_56b

Voice_Chan_ComputeParams_Return:
	pop xiz
	lda xsp, (xsp + 22)
	ret

Voice_SubVoice_ComputeAndTrigger:
	lda xsp, (xsp - 24)
	pushw iz
	ld (xsp + 22), xwa
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 35)
	ld (xsp + 2), xwa
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 39)
	ld (xsp + 6), xwa
	ld xwa, (xsp + 22)
	ld a, (xwa + 4)
	ld (xsp + 18), a
	ld xwa, (xsp + 22)
	ld c, (xwa + 3)
	ldw (xsp + 16), 0x0
	ld xwa, (xsp + 6)
	cpw (xwa + 28), 0x0
	jrl z, Voice1_UpdatePitch_AltEntry
	ld xwa, (xsp + 6)
	ld wa, (xwa + 28)
	and a, 0x3
	ld (xsp + 20), a
	extz wa
	sla wa, 2
	ld bc, wa
	add bc, 0x3B
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 19)
	stb_dri W, 0x07, 0xE0, 0xE4
	bitm 7, (xwa + 2)
	jr z, Voice_SubVoice_Compute_NoAlgoSelect
	ld a, (xsp + 18)
	ld l, a
	extz hl
	ld xwa, (xsp + 22)
	ld a, (xwa)
	ld c, a
	extz bc
	ld a, (xsp + 20)
	extz wa
	or wa, 0x24
	ld e, a
	extz de
	ld wa, hl
	call VoiceSlot_Assign
	ld (xsp + 14), hl
	ld iz, (xsp + 14)
	ldib_erp 0xF9, 0
	ld wa, iz
	call ToneGen_WriteExtParam_540_Mute
	jr Voice_SubVoice_ResolveSlot

Voice_SubVoice_Compute_NoAlgoSelect:
	ld a, (xsp + 18)
	ld l, a
	extz hl
	ld xwa, (xsp + 22)
	ld a, (xwa)
	ld c, a
	extz bc
	ld a, (xsp + 20)
	extz wa
	set 2, wa
	ld e, a
	extz de
	ld wa, hl
	call VoiceSlot_Assign
	ld (xsp + 14), hl
	ld iz, (xsp + 14)
	ldib_erp 0xF9, 0

Voice_SubVoice_ResolveSlot:
	ld wa, iz
	extz xwa
	ld xbc, 0x1B
	call FP_MulAccum64
	lda_24 xwa, 0x044257
	add xwa, xhl
	ld (xsp + 10), xwa
	ld xwa, (xsp + 22)
	ld xbc, (xsp + 10)
	ld a, (xwa + 12)
	ld (xbc + 6), a
	cp iz, 0x40
	jrl nc, Voice1_UpdatePitch_WriteStereoField
	ld xwa, (xsp + 6)
	ld wa, (xwa + 28)
	and wa, 0xC000
	ld (xsp + 16), wa
	ld wa, iz
	sll wa, 8
	or (xsp + 16), wa
	ld wa, (xsp + 14)
	bit 15, wa
	jr z, Voice1_UpdatePitch_WritePBend
	ld xwa, (xsp + 2)
	ld wa, (xwa)
	and wa, 0xC
	jr z, Voice1_UpdatePitch_CheckSustain

Voice1_UpdatePitch_WritePBend:
	ld a, (xsp + 18)
	ld c, a
	extz bc
	ld a, (xsp + 20)
	ld e, a
	extz de
	pushw 0x1
	stb_erp A, 0xF8
	extz wa
	pushw wa
	ld wa, bc
	ld xbc, (xsp + 6)
	calr Voice_OpSlot_WriteParams
	stb_erp A, 0xF8
	extz wa
	calr EGEnv_Compute_B_Simple
	stw_da 0x045206, xhl
	ld wa, iz
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParams_15_Alt

Voice1_UpdatePitch_CheckSustain:
	ld xwa, (xsp + 10)
	cp (xwa + 7), 0x0
	jr z, Voice1_UpdatePitch_CheckBit5
	ld xwa, (xsp + 2)
	ld wa, (xwa + 2)
	bit 13, wa
	jr nz, Voice1_UpdatePitch_DeactivateOsc

Voice1_UpdatePitch_CheckBit5:
	ld xwa, (xsp + 10)
	bitm 5, (xwa)
	jr z, Voice1_UpdatePitch_CheckPhase

Voice1_UpdatePitch_DeactivateOsc:
	ld xwa, (xsp + 10)
	ld (xwa + 8), 0x0
	ld xwa, (xsp + 10)
	andmi8 (xwa), 0xF3
	ld xwa, (xsp + 10)
	setm 4, (xwa)
	stiw_da 0x045204, 0x0000
	ld wa, iz
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParam_1C0_Single
	jrl Voice1_UpdatePitch_WriteStereoField

Voice1_UpdatePitch_CheckPhase:
	ld xwa, (xsp + 10)
	cp (xwa + 5), 0x0
	jr nz, Voice1_UpdatePitch_CheckStateFlags
	ld wa, (xsp + 14)
	bit 15, wa
	jr nz, Voice1_UpdatePitch_WriteFreq

Voice1_UpdatePitch_CheckStateFlags:
	ld xwa, (xsp + 10)
	ld a, (xwa)
	and a, 0x38
	jr nz, Voice1_UpdatePitch_WriteFreq
	stb_erp A, 0xF8
	extz wa
	calr EGEnv_Compute_B
	stw_da 0x045204, xhl
	ld wa, iz
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParam_1C0_Single
	jrl Voice1_UpdatePitch_WriteStereoField

Voice1_UpdatePitch_WriteFreq:
	ld xwa, (xsp + 2)
	ld wa, (xwa)
	and wa, 0xC
	jrl z, Voice1_UpdatePitch_WriteStereoField
	stb_erp A, 0xF8
	extz wa
	calr EGEnv_Compute_B
	stw_da 0x045204, xhl
	ld wa, iz
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParam_1C0_Single
	jrl Voice1_UpdatePitch_WriteStereoField

Voice1_UpdatePitch_AltEntry:
	ld xwa, (xsp + 2)
	ld wa, (xwa + 10)
	extz xwa
	bit 15, wa
	jrl z, Voice1_UpdatePitch_WriteStereoField
	ld a, (xsp + 18)
	extz wa
	extz bc
	call Algo67_LUTOffset_Check
	ld (xsp + 16), hl
	cpw (xsp + 16), 0x0
	jr z, Voice1_UpdatePitch_WriteStereoField
	ld a, (xsp + 18)
	ld e, a
	extz de
	ld xwa, (xsp + 22)
	ld a, (xwa)
	ld c, a
	extz bc
	ld wa, de
	ldw de, 0x10
	call VoiceSlot_Assign
	ld (xsp + 14), hl
	ld iz, (xsp + 14)
	and iz, 0xFF
	cp iz, 0x40
	jr nc, Voice1_UpdatePitch_WriteStereoField
	stb_erp A, 0xF8
	extz wa
	ld bc, wa
	lds wa, 1
	calr NoteState_ClearRecord
	ld wa, iz
	sll wa, 8
	or (xsp + 16), wa
	ld wa, (xsp + 14)
	bit 15, wa
	jr z, Voice1_UpdatePitch_WriteAltFreq
	ld xwa, (xsp + 2)
	ld wa, (xwa)
	bit 2, wa
	jr z, Voice1_UpdatePitch_WriteStereoField

Voice1_UpdatePitch_WriteAltFreq:
	ld xwa, (xsp + 2)
	ld wa, (xwa + 95)
	stw_da 0x045204, xwa
	ld xwa, (xsp + 2)
	ld wa, (xwa + 97)
	stw_da 0x045206, xwa
	ld wa, iz
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParams_15

Voice1_UpdatePitch_WriteStereoField:
	ld xwa, (xsp + 22)
	ld a, (xwa + 4)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04138e
	cpib_sri 0x07, 0xE4, 0xE0, 0x01
	jr nz, Voice1_UpdatePitch_StereoPart2
	ld bc, (xsp + 16)
	ld xwa, (xsp + 22)
	ld (xwa + 43), bc
	jr Voice1_UpdatePitch_StoreStereo

Voice1_UpdatePitch_StereoPart2:
	ld xwa, (xsp + 22)
	ld a, (xwa + 4)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04138e
	cpib_sri 0x07, 0xE4, 0xE0, 0x02
	jr nz, Voice1_UpdatePitch_StereoFallthrough
	ld bc, (xsp + 16)
	or bc, 0x7F
	ld xwa, (xsp + 22)
	ld (xwa + 43), bc
	jr Voice1_UpdatePitch_StoreStereo

Voice1_UpdatePitch_StereoFallthrough:
	ld xwa, (xsp + 6)
	ld a, (xwa + 35)
	extz wa
	ld bc, wa
	or bc, (xsp + 16)
	ld xwa, (xsp + 22)
	ld (xwa + 43), bc

Voice1_UpdatePitch_StoreStereo:
	ld xwa, (xsp + 22)
	ld wa, (xwa + 43)
	stw_da 0x0451d8, xwa
	popw iz
	lda xsp, (xsp + 24)
	ret

Voice2_UpdatePitch:
	lda xsp, (xsp - 22)
	pushw iz
	ld (xsp + 20), xwa
	stiw_da 0x0451e0, 0x4400
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 35)
	ld (xsp + 2), xwa
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 39)
	ld (xsp + 6), xwa
	ld xwa, (xsp + 20)
	ld a, (xwa + 4)
	ld (xsp + 16), a
	ld xwa, (xsp + 6)
	cpw (xwa + 30), 0x0
	jrl z, Voice2_UpdatePitch_Done
	ld xwa, (xsp + 6)
	ld wa, (xwa + 30)
	and a, 0x3
	ld (xsp + 18), a
	extz wa
	sla wa, 2
	ld bc, wa
	add bc, 0x4B
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 19)
	stb_dri W, 0x07, 0xE0, 0xE4
	bitm 7, (xwa + 2)
	jr z, Voice2_UpdatePitch_NoOsc7Flag
	ld a, (xsp + 16)
	ld l, a
	extz hl
	ld xwa, (xsp + 20)
	ld a, (xwa)
	ld c, a
	extz bc
	ld a, (xsp + 18)
	extz wa
	or wa, 0x28
	ld e, a
	extz de
	ld wa, hl
	call VoiceSlot_Assign
	ld (xsp + 14), hl
	ld iz, (xsp + 14)
	ldib_erp 0xF9, 0
	ld wa, iz
	call ToneGen_WriteExtParam_Mute_TypeDispatch
	jr Voice2_UpdatePitch_ChanEntry

Voice2_UpdatePitch_NoOsc7Flag:
	ld a, (xsp + 16)
	ld l, a
	extz hl
	ld xwa, (xsp + 20)
	ld a, (xwa)
	ld c, a
	extz bc
	ld a, (xsp + 18)
	extz wa
	set 3, wa
	ld e, a
	extz de
	ld wa, hl
	call VoiceSlot_Assign
	ld (xsp + 14), hl
	ld iz, (xsp + 14)
	ldib_erp 0xF9, 0

Voice2_UpdatePitch_ChanEntry:
	ld wa, iz
	extz xwa
	ld xbc, 0x1B
	call FP_MulAccum64
	lda_24 xwa, 0x044260
	add xwa, xhl
	ld (xsp + 10), xwa
	ld xwa, (xsp + 20)
	ld xbc, (xsp + 10)
	ld a, (xwa + 12)
	ld (xbc + 6), a
	cp iz, 0x80
	jrl nc, Voice2_UpdatePitch_Done
	ld xwa, (xsp + 6)
	ld wa, (xwa + 30)
	and wa, 0x3300
	or wa, iz
	ordm16_24 283104, xwa
	ld wa, (xsp + 14)
	bit 15, wa
	jr z, Voice2_UpdatePitch_WritePBend
	ld xwa, (xsp + 2)
	ld wa, (xwa)
	and wa, 0xC
	jr z, Voice2_UpdatePitch_CheckSustain

Voice2_UpdatePitch_WritePBend:
	ld a, (xsp + 16)
	ld c, a
	extz bc
	ld a, (xsp + 18)
	ld e, a
	extz de
	pushw 0x2
	stb_erp A, 0xF8
	extz wa
	pushw wa
	ld wa, bc
	ld xbc, (xsp + 6)
	calr Voice_OpSlot_WriteParams
	stb_erp A, 0xF8
	extz wa
	calr Voice_Freq_WriteRight
	ld wa, iz
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParams_TypeDispatch

Voice2_UpdatePitch_CheckSustain:
	ld xwa, (xsp + 10)
	cp (xwa + 7), 0x0
	jr z, Voice2_UpdatePitch_CheckBit5
	ld xwa, (xsp + 2)
	ld wa, (xwa + 2)
	bit 13, wa
	jr nz, Voice2_UpdatePitch_DeactivateOsc

Voice2_UpdatePitch_CheckBit5:
	ld xwa, (xsp + 10)
	bitm 5, (xwa)
	jr z, Voice2_UpdatePitch_CheckPhase

Voice2_UpdatePitch_DeactivateOsc:
	ld xwa, (xsp + 10)
	ld (xwa + 8), 0x0
	ld xwa, (xsp + 10)
	andmi8 (xwa), 0xF3
	ld xwa, (xsp + 10)
	setm 4, (xwa)
	stiw_da 0x045204, 0x0000
	stiw_da 0x04520e, 0x0000
	ld wa, iz
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParam_TypeDispatch_Single
	jr Voice2_UpdatePitch_Done

Voice2_UpdatePitch_CheckPhase:
	ld xwa, (xsp + 10)
	cp (xwa + 5), 0x0
	jr nz, Voice2_UpdatePitch_CheckStateFlags
	ld wa, (xsp + 14)
	bit 15, wa
	jr nz, Voice2_UpdatePitch_WriteFreq

Voice2_UpdatePitch_CheckStateFlags:
	ld xwa, (xsp + 10)
	ld a, (xwa)
	and a, 0x38
	jr nz, Voice2_UpdatePitch_WriteFreq
	stb_erp A, 0xF8
	extz wa
	calr Voice_Freq_WriteLeft
	ld wa, iz
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParam_TypeDispatch_Single
	jr Voice2_UpdatePitch_Done

Voice2_UpdatePitch_WriteFreq:
	ld xwa, (xsp + 2)
	ld wa, (xwa)
	and wa, 0xC
	jr z, Voice2_UpdatePitch_Done
	stb_erp A, 0xF8
	extz wa
	calr Voice_Freq_WriteLeft
	ld wa, iz
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParam_TypeDispatch_Single

Voice2_UpdatePitch_Done:
	popw iz
	lda xsp, (xsp + 22)
	ret

Voice_ComputeExprPitchBend:
	ld xbc, (xwa + 35)
	cp (xbc + 15), 0x0
	jr z, Voice_ComputeExprPitchBend_ZeroCoarse
	ld xbc, (xwa + 35)
	cp (xbc + 18), 0x0
	jr z, Voice_ComputeExprPitchBend_ZeroCoarse
	ldb_da c, 0x04134c
	cps c, 6
	jr nz, Voice_ComputeExprPitchBend_UseCoarse
	lds de, 0
	jr Voice_ComputeExprPitchBend_ApplyDetune

Voice_ComputeExprPitchBend_UseCoarse:
	ld xbc, (xwa + 35)
	ld c, (xbc + 15)
	extz bc
	ld de, bc
	jr Voice_ComputeExprPitchBend_ApplyDetune

Voice_ComputeExprPitchBend_ZeroCoarse:
	ld xbc, (xwa + 35)
	ld c, (xbc + 15)
	extz bc
	ld de, bc

Voice_ComputeExprPitchBend_ApplyDetune:
	cps de, 0
	jr z, Voice_ComputeExprPitchBend_CheckExpr
	ld xbc, (xwa + 19)
	ld c, (xbc + 92)
	extz bc
	sub bc, 0x40
	add de, bc
	ld xbc, (xwa + 35)
	ld c, (xbc + 102)
	exts bc
	add de, bc
	jr ge, Voice_ComputeExprPitchBend_ClampHigh
	lds de, 0
	jr Voice_ComputeExprPitchBend_ShiftLeft

Voice_ComputeExprPitchBend_ClampHigh:
	cp de, 0x7F
	jr le, Voice_ComputeExprPitchBend_ShiftLeft
	ldw de, 0x7F

Voice_ComputeExprPitchBend_ShiftLeft:
	sla de, 8

Voice_ComputeExprPitchBend_CheckExpr:
	ld xbc, (xwa + 35)
	cp (xbc + 18), 0x0
	jr z, Voice_ComputeExprPitchBend_NoExpr
	ldb_da c, 0x04134c
	cps c, 6
	jr z, Voice_ComputeExprPitchBend_FullExpr
	cps c, 5
	jr nz, Voice_ComputeExprPitchBend_PartialExpr

Voice_ComputeExprPitchBend_FullExpr:
	or de, 0x7F
	jr Voice_ComputeExprPitchBend_Write

Voice_ComputeExprPitchBend_PartialExpr:
	ld xwa, (xwa + 35)
	ld a, (xwa + 18)
	extz wa
	or de, wa
	jr Voice_ComputeExprPitchBend_Write

Voice_ComputeExprPitchBend_NoExpr:
	ld xwa, (xwa + 35)
	ld a, (xwa + 18)
	extz wa
	or de, wa

Voice_ComputeExprPitchBend_Write:
	stw_da 0x0451d2, xde
	ret

Voice_ComputePitchBend2:
	ld xhl, (xwa + 19)
	ld xbc, (xwa + 35)
	cp (xbc + 15), 0x0
	jr z, Voice_ComputePitchBend2_ZeroCoarse
	ld xbc, (xwa + 35)
	cp (xbc + 18), 0x0
	jr z, Voice_ComputePitchBend2_ZeroCoarse
	ldb_da c, 0x04134c
	cps c, 6
	jr nz, Voice_ComputePitchBend2_UseCoarse
	lds de, 0
	jr Voice_ComputePitchBend2_ApplyDetune

Voice_ComputePitchBend2_UseCoarse:
	ld xbc, (xwa + 35)
	ld c, (xbc + 15)
	extz bc
	ld de, bc
	jr Voice_ComputePitchBend2_ApplyDetune

Voice_ComputePitchBend2_ZeroCoarse:
	ld xbc, (xwa + 35)
	ld c, (xbc + 15)
	extz bc
	ld de, bc

Voice_ComputePitchBend2_ApplyDetune:
	cps de, 0
	jr z, Voice_ComputePitchBend2_CheckExpr
	ld c, (xhl + 15)
	extz bc
	sub bc, 0x40
	add de, bc
	jr ge, Voice_ComputePitchBend2_ClampHigh
	lds de, 0
	jr Voice_ComputePitchBend2_ShiftLeft

Voice_ComputePitchBend2_ClampHigh:
	cp de, 0x7F
	jr le, Voice_ComputePitchBend2_ShiftLeft
	ldw de, 0x7F

Voice_ComputePitchBend2_ShiftLeft:
	sla de, 8

Voice_ComputePitchBend2_CheckExpr:
	ld xbc, (xwa + 35)
	cp (xbc + 18), 0x0
	jr z, Voice_ComputePitchBend2_NoExpr
	ldb_da c, 0x04134c
	cps c, 6
	jr z, Voice_ComputePitchBend2_FullExpr
	cps c, 5
	jr nz, Voice_ComputePitchBend2_PartialExpr

Voice_ComputePitchBend2_FullExpr:
	or de, 0x7F
	jr Voice_ComputePitchBend2_Write

Voice_ComputePitchBend2_PartialExpr:
	ld xwa, (xwa + 35)
	ld a, (xwa + 18)
	extz wa
	or de, wa
	jr Voice_ComputePitchBend2_Write

Voice_ComputePitchBend2_NoExpr:
	ld xwa, (xwa + 35)
	ld a, (xwa + 18)
	extz wa
	or de, wa

Voice_ComputePitchBend2_Write:
	stw_da 0x0451d2, xde
	ret

Voice_ApplyModeToPitchWord:
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xhl, 0x04138d
	ldb_sri E, 0x07, 0xEC, 0xE8
	and e, 0xF
	cps e, 1
	jr z, Voice_ApplyModeToPitchWord_HighNibble
	cps e, 2
	jr z, Voice_ApplyModeToPitchWord_Mode2
	cps e, 0
	jr nz, Voice_ApplyModeToPitchWord_HighNibble
	or bc, 0xE00
	jr Voice_ApplyModeToPitchWord_HighNibble

Voice_ApplyModeToPitchWord_Mode2:
	and bc, 0xF1FF
	set 9, bc

Voice_ApplyModeToPitchWord_HighNibble:
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x04138d
	ldb_sri A, 0x07, 0xE8, 0xE0
	and a, 0xF0
	cp a, 0x10
	jr z, Voice_ApplyModeToPitchWord_Done
	cp a, 0x20
	jr z, Voice_ApplyModeToPitchWord_Mode2High
	cps a, 0
	jr nz, Voice_ApplyModeToPitchWord_Done
	or bc, 0x7000
	jr Voice_ApplyModeToPitchWord_Done

Voice_ApplyModeToPitchWord_Mode2High:
	and bc, 0x8FFF
	set 12, bc

Voice_ApplyModeToPitchWord_Done:
	ld hl, bc
	ret

Voice_SetPitchWord_Muted:
	push xiz
	ld xiz, xwa
	ld xwa, (xiz + 23)
	ld a, (xwa)
	extz wa
	and wa, 0x3F
	sll wa, 2
	ldw bc, 0xFF
	sub bc, wa
	ld xwa, (xiz + 23)
	cp (xwa), 0x0
	jr z, Voice_SetPitchWord_Muted_CheckExpr
	set 8, bc

Voice_SetPitchWord_Muted_CheckExpr:
	ld xwa, (xiz + 35)
	cp (xwa + 18), 0x0
	jr z, Voice_SetPitchWord_Muted_NoExpr
	ldb_da a, 0x04134c
	cps a, 6
	jr z, Voice_SetPitchWord_Muted_FullExpr
	cps a, 5
	jr z, Voice_SetPitchWord_Muted_FullExpr
	cps a, 0
	jr nz, Voice_SetPitchWord_Muted_PartialExpr

Voice_SetPitchWord_Muted_FullExpr:
	ld wa, bc
	or wa, 0xFE00
	ld (xiz + 45), wa
	jr Voice_SetPitchWord_Muted_ApplyMode

Voice_SetPitchWord_Muted_PartialExpr:
	ld wa, bc
	or wa, 0xF000
	ld (xiz + 45), wa
	jr Voice_SetPitchWord_Muted_ApplyMode

Voice_SetPitchWord_Muted_NoExpr:
	ld wa, bc
	or wa, 0xF000
	ld (xiz + 45), wa

Voice_SetPitchWord_Muted_ApplyMode:
	ld a, (xiz + 4)
	extz wa
	ld bc, (xiz + 45)
	calr Voice_ApplyModeToPitchWord
	ld (xiz + 45), hl
	pop xiz
	ret

Voice_SetPitchWord_Unmuted:
	push xiz
	ld xiz, xwa
	ld xwa, (xiz + 19)
	ld xwa, (xiz + 35)
	cp (xwa + 18), 0x0
	jr z, Voice_SetPitchWord_Unmuted_NoExpr
	ldb_da a, 0x04134c
	cps a, 6
	jr z, Voice_SetPitchWord_Unmuted_FullExpr
	cps a, 5
	jr z, Voice_SetPitchWord_Unmuted_FullExpr
	cps a, 0
	jr nz, Voice_SetPitchWord_Unmuted_PartialExpr

Voice_SetPitchWord_Unmuted_FullExpr:
	ldw (xiz + 45), 0xFE00
	jr Voice_SetPitchWord_Unmuted_ApplyMode

Voice_SetPitchWord_Unmuted_PartialExpr:
	ldw (xiz + 45), 0xF000
	jr Voice_SetPitchWord_Unmuted_ApplyMode

Voice_SetPitchWord_Unmuted_NoExpr:
	ldw (xiz + 45), 0xF000

Voice_SetPitchWord_Unmuted_ApplyMode:
	ld a, (xiz + 4)
	extz wa
	ld bc, (xiz + 45)
	calr Voice_ApplyModeToPitchWord
	ld (xiz + 45), hl
	pop xiz
	ret

Voice_ComputeAndWritePan:
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 14), xwa
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 23)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 31)
	ld (xsp + 10), xwa
	ld xwa, (xsp + 14)
	ld xbc, (xwa + 35)
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 19)
	bitm 4, (xwa + 16)
	jr z, Voice_ComputeAndWritePan_SetInvFlag
	ld xwa, (xsp + 14)
	andmi16 (xwa + 1), 0x7FFF
	jr Voice_ComputeAndWritePan_ApplyKeyTrack

Voice_ComputeAndWritePan_SetInvFlag:
	ld xwa, (xsp + 14)
	ormi16 (xwa + 1), 0x8000

Voice_ComputeAndWritePan_ApplyKeyTrack:
	ld a, (xbc + 107)
	ld c, a
	exts bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 39)
	extz wa
	add wa, bc
	ldw bc, 0x64
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	stb_erp A, 0xF8
	extz wa
	lda_24 xbc, 0x011899
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld iz, wa
	ld xwa, (xsp + 4)
	cp (xwa + 51), 0x0
	jr z, Voice_ComputeAndWritePan_NoOscLFO
	ld xwa, (xsp + 4)
	ld a, (xwa + 48)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 49)
	ld e, a
	extz de
	ld xwa, (xsp + 4)
	ld a, (xwa + 50)
	extz wa
	pushw wa
	ld xwa, (xsp + 6)
	ld a, (xwa + 51)
	exts wa
	pushw wa
	ld xwa, (xsp + 18)
	ld wa, (xwa + 8)
	calr Pan_ScaleWithVelocity
	ld (xsp + 8), hl
	ld xwa, (xsp + 4)
	cp (xwa + 46), 0x0
	jr z, Voice_ComputeAndWritePan_NoPanLFO
	ld xwa, (xsp + 4)
	ld a, (xwa + 46)
	ld e, a
	exts de
	ld xwa, (xsp + 14)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ldw_erp HL, 0xFA
	ld wa, iz
	add wa, (xsp + 8)
	addw_erp WA, 0xFA
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	jr Voice_ComputeAndWritePan_CheckMax

Voice_ComputeAndWritePan_NoPanLFO:
	ld wa, iz
	add wa, (xsp + 8)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	jr Voice_ComputeAndWritePan_CheckMax

Voice_ComputeAndWritePan_NoOscLFO:
	ld xwa, (xsp + 4)
	cp (xwa + 46), 0x0
	jr z, Voice_ComputeAndWritePan_CheckMax
	ld xwa, (xsp + 4)
	ld a, (xwa + 46)
	ld e, a
	exts de
	ld xwa, (xsp + 14)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ldw_erp HL, 0xFA
	ld wa, iz
	addw_erp WA, 0xFA
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl

Voice_ComputeAndWritePan_CheckMax:
	ld xwa, (xsp + 10)
	bitm 0, (xwa)
	jr z, Voice_ComputeAndWritePan_WriteDSP
	ld wa, iz
	cp wa, 0xFF
	jr nz, Voice_ComputeAndWritePan_WriteDSP
	dec 1, iz

Voice_ComputeAndWritePan_WriteDSP:
	ld xwa, (xsp + 4)
	ld a, (xwa + 40)
	extz wa
	lda_24 xbc, 0x011963
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ldb w, 0x0
	ld bc, iz
	sla bc, 8
	or bc, wa
	stw_da 0x0451e4, xbc
	ld xwa, (xsp + 14)
	ld (xwa + 60), bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 41)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 10), wa
	ld xwa, (xsp + 4)
	ld a, (xwa + 43)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 12), wa
	ld xwa, (xsp + 4)
	cp (xwa + 52), 0x0
	jrl z, Voice_ComputeAndWritePan_NoPanDepth2
	ld xwa, (xsp + 4)
	ld a, (xwa + 48)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 49)
	ld e, a
	extz de
	ld xwa, (xsp + 4)
	ld a, (xwa + 50)
	extz wa
	pushw wa
	ld xwa, (xsp + 6)
	ld a, (xwa + 52)
	exts wa
	pushw wa
	ld xwa, (xsp + 18)
	ld wa, (xwa + 8)
	calr Pan_ScaleWithVelocity
	ld (xsp + 8), hl
	ld xwa, (xsp + 4)
	cp (xwa + 47), 0x0
	jr z, Voice_ComputeAndWritePan_NoModDepth
	ld xwa, (xsp + 4)
	ld a, (xwa + 47)
	ld e, a
	exts de
	ld xwa, (xsp + 14)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ldw_erp HL, 0xFA
	ld wa, (xsp + 10)
	add wa, (xsp + 8)
	addw_erp WA, 0xFA
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl
	ld wa, (xsp + 12)
	add wa, (xsp + 8)
	addw_erp WA, 0xFA
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 12), hl
	jr Voice_ComputeAndWritePan_WriteChans

Voice_ComputeAndWritePan_NoModDepth:
	ld wa, (xsp + 10)
	add wa, (xsp + 8)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl
	ld wa, (xsp + 12)
	add wa, (xsp + 8)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 12), hl
	jr Voice_ComputeAndWritePan_WriteChans

Voice_ComputeAndWritePan_NoPanDepth2:
	ld xwa, (xsp + 4)
	cp (xwa + 47), 0x0
	jr z, Voice_ComputeAndWritePan_WriteChans
	ld xwa, (xsp + 4)
	ld a, (xwa + 47)
	ld e, a
	exts de
	ld xwa, (xsp + 14)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ldw_erp HL, 0xFA
	ld wa, (xsp + 10)
	addw_erp WA, 0xFA
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl
	ld wa, (xsp + 12)
	addw_erp WA, 0xFA
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 12), hl

Voice_ComputeAndWritePan_WriteChans:
	ld xwa, (xsp + 4)
	ld a, (xwa + 42)
	extz wa
	lda_24 xbc, 0x011963
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld hl, wa
	lds wa, 4
	cps hl, 4
	jr lt, Voice_ComputeAndWritePan_ClampDepth
	ld wa, hl

Voice_ComputeAndWritePan_ClampDepth:
	ld hl, wa
	ld xwa, (xsp + 4)
	ld a, (xwa + 44)
	extz wa
	lda_24 xbc, 0x011963
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld de, wa
	ld wa, hl
	ldb w, 0x0
	ld bc, (xsp + 10)
	sla bc, 8
	or bc, wa
	ld xwa, (xsp + 14)
	ld (xwa + 62), bc
	ld wa, de
	ldb w, 0x0
	ld bc, (xsp + 12)
	sla bc, 8
	or bc, wa
	ld xwa, (xsp + 14)
	ld (xwa + 64), bc
	pop xiz
	lda xsp, (xsp + 14)
	ret

Voice_WriteChPanShift:
	dec 8, xsp
	pushw iz
	ld (xsp + 4), c
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 39)
	ld wa, (xwa + 24)
	bit 8, wa
	jrl z, Voice_WriteChPanShift_Passthrough
	ld xwa, (xsp + 6)
	ld wa, (xwa + 64)
	and wa, 0xFF
	jrl z, Voice_WriteChPanShift_Passthrough
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 39)
	ld wa, (xwa + 24)
	bit 9, wa
	jr z, Voice_WriteChPanShift_AddShift
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 32)
	ld c, a
	exts bc
	ld xwa, (xsp + 6)
	ld wa, (xwa + 62)
	and wa, 0x7F
	ld (xsp + 2), wa
	sub (xsp + 2), bc
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 32)
	ld c, a
	exts bc
	ld xwa, (xsp + 6)
	ld wa, (xwa + 64)
	and wa, 0x7F
	ld iz, wa
	sub iz, bc
	jr Voice_WriteChPanShift_ClampAndWrite

Voice_WriteChPanShift_AddShift:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 32)
	ld c, a
	exts bc
	ld xwa, (xsp + 6)
	ld wa, (xwa + 62)
	and wa, 0x7F
	ld (xsp + 2), wa
	add (xsp + 2), bc
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 32)
	ld c, a
	exts bc
	ld xwa, (xsp + 6)
	ld wa, (xwa + 64)
	and wa, 0x7F
	ld iz, wa
	add iz, bc

Voice_WriteChPanShift_ClampAndWrite:
	ld wa, (xsp + 2)
	ldw bc, 0x7F
	lds de, 4
	calr ClampS16_WA_To_DEBC
	ld (xsp + 2), hl
	ld wa, iz
	ldw bc, 0x7F
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	cp (xsp + 4), 0x0
	jr z, Voice_WriteChPanShift_NoChanFlag
	ld wa, iz
	set 15, wa
	stw_da 0x0451e8, xwa
	jr Voice_WriteChPanShift_WriteL

Voice_WriteChPanShift_NoChanFlag:
	ld wa, iz
	ldb w, 0x0
	ld bc, wa
	ld xwa, (xsp + 6)
	ld wa, (xwa + 64)
	ldb a, 0x0
	or wa, bc
	stw_da 0x0451e8, xwa

Voice_WriteChPanShift_WriteL:
	ld wa, (xsp + 2)
	ldb w, 0x0
	ld bc, wa
	ld xwa, (xsp + 6)
	ld wa, (xwa + 62)
	ldb a, 0x0
	or wa, bc
	stw_da 0x0451e6, xwa
	jr Voice_WriteChPanShift_Done

Voice_WriteChPanShift_Passthrough:
	ld xwa, (xsp + 6)
	ld wa, (xwa + 62)
	stw_da 0x0451e6, xwa
	ld xwa, (xsp + 6)
	ld wa, (xwa + 64)
	stw_da 0x0451e8, xwa

Voice_WriteChPanShift_Done:
	popw iz
	inc 8, xsp
	ret

Voice_UpdatePan_Simple:
	lda xsp, (xsp - 12)
	pushw iz
	ld (xsp + 10), xwa
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 19)
	ld (xsp + 2), xwa
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 23)
	ld (xsp + 6), xwa
	ld xwa, (xsp + 10)
	ormi16 (xwa + 1), 0x8000
	ld xwa, (xsp + 6)
	ld a, (xwa + 8)
	extz wa
	lda_24 xbc, 0x011899
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld iz, wa
	ld xwa, (xsp + 6)
	cp (xwa + 14), 0x0
	jr z, Voice_UpdatePan_Simple_WritePan
	ld xwa, (xsp + 6)
	ld a, (xwa + 14)
	ld e, a
	exts de
	ld xwa, (xsp + 10)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	add iz, hl
	ld wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl

Voice_UpdatePan_Simple_WritePan:
	ld wa, iz
	sla wa, 8
	ld bc, wa
	or bc, 0x7F
	stw_da 0x0451e4, xbc
	ld xwa, (xsp + 10)
	ld (xwa + 60), bc
	ld xwa, (xsp + 6)
	ld a, (xwa + 9)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld hl, wa
	ld xwa, (xsp + 6)
	ld a, (xwa + 11)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld de, wa
	ld xwa, (xsp + 6)
	ld a, (xwa + 10)
	extz wa
	lda_24 xbc, 0x011963
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld bc, wa
	lds wa, 4
	cps bc, 4
	jr lt, Voice_UpdatePan_Simple_WriteChans
	ld wa, bc

Voice_UpdatePan_Simple_WriteChans:
	ld bc, wa
	ldb w, 0x0
	ld bc, hl
	sla bc, 8
	or bc, wa
	ld xwa, (xsp + 10)
	ld (xwa + 62), bc
	ld xwa, (xsp + 2)
	bitm 5, (xwa + 13)
	jr z, Voice_UpdatePan_Simple_NoChanFlag
	ld xwa, (xsp + 6)
	ld a, (xwa + 12)
	extz wa
	lda_24 xbc, 0x011963
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ldb w, 0x0
	ld bc, de
	sla bc, 8
	or bc, wa
	ld xwa, (xsp + 10)
	ld (xwa + 64), bc
	ld xwa, (xsp + 6)
	ld a, (xwa + 13)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld c, a
	ld xwa, (xsp + 10)
	ld (xwa + 70), c
	jr Voice_UpdatePan_Simple_Done

Voice_UpdatePan_Simple_NoChanFlag:
	ld bc, de
	sla bc, 8
	ld xwa, (xsp + 10)
	ld (xwa + 64), bc
	ld xwa, (xsp + 10)
	ld (xwa + 70), 0x0

Voice_UpdatePan_Simple_Done:
	popw iz
	lda xsp, (xsp + 12)
	ret

Voice_WriteChPanShift2:
	dec 8, xsp
	pushw iz
	ld (xsp + 4), c
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 39)
	ld wa, (xwa + 24)
	bit 8, wa
	jrl z, Voice_WriteChPanShift2_Passthrough
	ld xwa, (xsp + 6)
	ld wa, (xwa + 64)
	and wa, 0xFF
	jrl z, Voice_WriteChPanShift2_Passthrough
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 39)
	ld wa, (xwa + 24)
	bit 9, wa
	jr z, Voice_WriteChPanShift2_AddShift
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 32)
	ld c, a
	exts bc
	ld xwa, (xsp + 6)
	ld wa, (xwa + 62)
	and wa, 0x7F
	ld (xsp + 2), wa
	sub (xsp + 2), bc
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 32)
	ld c, a
	exts bc
	ld xwa, (xsp + 6)
	ld wa, (xwa + 64)
	and wa, 0x7F
	ld iz, wa
	sub iz, bc
	jr Voice_WriteChPanShift2_ClampAndWrite

Voice_WriteChPanShift2_AddShift:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 32)
	ld c, a
	exts bc
	ld xwa, (xsp + 6)
	ld wa, (xwa + 62)
	and wa, 0x7F
	ld (xsp + 2), wa
	add (xsp + 2), bc
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 32)
	ld c, a
	exts bc
	ld xwa, (xsp + 6)
	ld wa, (xwa + 64)
	and wa, 0x7F
	ld iz, wa
	add iz, bc

Voice_WriteChPanShift2_ClampAndWrite:
	ld wa, (xsp + 2)
	ldw bc, 0x7F
	lds de, 4
	calr ClampS16_WA_To_DEBC
	ld (xsp + 2), hl
	ld wa, iz
	ldw bc, 0x7F
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	cp (xsp + 4), 0x0
	jr z, Voice_WriteChPanShift2_NoChanFlag
	ld wa, iz
	set 15, wa
	stw_da 0x0451e8, xwa
	jr Voice_WriteChPanShift2_WriteL

Voice_WriteChPanShift2_NoChanFlag:
	ld wa, iz
	ldb w, 0x0
	ld bc, wa
	ld xwa, (xsp + 6)
	ld wa, (xwa + 64)
	ldb a, 0x0
	or wa, bc
	stw_da 0x0451e8, xwa

Voice_WriteChPanShift2_WriteL:
	ld wa, (xsp + 2)
	ldb w, 0x0
	ld bc, wa
	ld xwa, (xsp + 6)
	ld wa, (xwa + 62)
	ldb a, 0x0
	or wa, bc
	stw_da 0x0451e6, xwa
	jr Voice_WriteChPanShift2_Done

Voice_WriteChPanShift2_Passthrough:
	ld xwa, (xsp + 6)
	ld wa, (xwa + 62)
	stw_da 0x0451e6, xwa
	ld xwa, (xsp + 6)
	ld wa, (xwa + 64)
	stw_da 0x0451e8, xwa

Voice_WriteChPanShift2_Done:
	popw iz
	inc 8, xsp
	ret

Voice_UpdatePan_Full:
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 14), xwa
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 23)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 19)
	bitm 4, (xwa + 16)
	jr z, Voice_UpdatePan_Full_SetInvFlag
	ld xwa, (xsp + 14)
	andmi16 (xwa + 1), 0x7FFF
	jr Voice_UpdatePan_Full_CheckBit11

Voice_UpdatePan_Full_SetInvFlag:
	ld xwa, (xsp + 14)
	ormi16 (xwa + 1), 0x8000

Voice_UpdatePan_Full_CheckBit11:
	ld xwa, (xsp + 14)
	ld wa, (xwa + 1)
	bit 11, wa
	jr z, Voice_UpdatePan_Full_OscTablePath
	ldb_da a, 0x0118b3
	extz wa
	ld iz, wa
	jrl Voice_UpdatePan_Full_CheckMax

Voice_UpdatePan_Full_OscTablePath:
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 35)
	ldb_sri0 A, (xwa + 0x010c)
	ld c, a
	exts bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 39)
	extz wa
	add wa, bc
	ldw bc, 0x64
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	stb_erp A, 0xF8
	extz wa
	lda_24 xbc, 0x011899
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld iz, wa
	ld xwa, (xsp + 4)
	cp (xwa + 51), 0x0
	jr z, Voice_UpdatePan_Full_NoPanLFO
	ld xwa, (xsp + 4)
	ld a, (xwa + 48)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 49)
	ld e, a
	extz de
	ld xwa, (xsp + 4)
	ld a, (xwa + 50)
	extz wa
	pushw wa
	ld xwa, (xsp + 6)
	ld a, (xwa + 51)
	exts wa
	pushw wa
	ld xwa, (xsp + 18)
	ld wa, (xwa + 8)
	calr Pan_ScaleWithVelocity
	ld (xsp + 8), hl
	ld xwa, (xsp + 4)
	cp (xwa + 46), 0x0
	jr z, Voice_UpdatePan_Full_NoPanDepth
	ld xwa, (xsp + 4)
	ld a, (xwa + 46)
	ld e, a
	exts de
	ld xwa, (xsp + 14)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ldw_erp HL, 0xFA
	ld wa, iz
	add wa, (xsp + 8)
	addw_erp WA, 0xFA
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	jr Voice_UpdatePan_Full_CheckMax

Voice_UpdatePan_Full_NoPanDepth:
	ld wa, iz
	add wa, (xsp + 8)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	jr Voice_UpdatePan_Full_CheckMax

Voice_UpdatePan_Full_NoPanLFO:
	ld xwa, (xsp + 4)
	cp (xwa + 46), 0x0
	jr z, Voice_UpdatePan_Full_CheckMax
	ld xwa, (xsp + 4)
	ld a, (xwa + 46)
	ld e, a
	exts de
	ld xwa, (xsp + 14)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ldw_erp HL, 0xFA
	ld wa, iz
	addw_erp WA, 0xFA
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl

Voice_UpdatePan_Full_CheckMax:
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 31)
	bitm 0, (xwa)
	jr z, Voice_UpdatePan_Full_WriteDSP
	ld wa, iz
	cp wa, 0xFF
	jr nz, Voice_UpdatePan_Full_WriteDSP
	dec 1, iz

Voice_UpdatePan_Full_WriteDSP:
	ld xwa, (xsp + 4)
	ld a, (xwa + 40)
	extz wa
	lda_24 xbc, 0x011963
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ldb w, 0x0
	ld bc, iz
	sla bc, 8
	or bc, wa
	stw_da 0x0451e4, xbc
	ld xwa, (xsp + 14)
	ld (xwa + 60), bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 41)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 10), wa
	ld xwa, (xsp + 4)
	ld a, (xwa + 43)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 12), wa
	ld xwa, (xsp + 4)
	cp (xwa + 52), 0x0
	jrl z, Voice_UpdatePan_Full_NoPanDepth2
	ld xwa, (xsp + 4)
	ld a, (xwa + 48)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 49)
	ld e, a
	extz de
	ld xwa, (xsp + 4)
	ld a, (xwa + 50)
	extz wa
	pushw wa
	ld xwa, (xsp + 6)
	ld a, (xwa + 52)
	exts wa
	pushw wa
	ld xwa, (xsp + 18)
	ld wa, (xwa + 8)
	calr Pan_ScaleWithVelocity
	ld (xsp + 8), hl
	ld xwa, (xsp + 4)
	cp (xwa + 47), 0x0
	jr z, Voice_UpdatePan_Full_NoModDepth
	ld xwa, (xsp + 4)
	ld a, (xwa + 47)
	ld e, a
	exts de
	ld xwa, (xsp + 14)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ldw_erp HL, 0xFA
	ld wa, (xsp + 10)
	add wa, (xsp + 8)
	addw_erp WA, 0xFA
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl
	ld wa, (xsp + 12)
	add wa, (xsp + 8)
	addw_erp WA, 0xFA
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 12), hl
	jr Voice_UpdatePan_Full_WriteChDepth

Voice_UpdatePan_Full_NoModDepth:
	ld wa, (xsp + 10)
	add wa, (xsp + 8)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl
	ld wa, (xsp + 12)
	add wa, (xsp + 8)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 12), hl
	jr Voice_UpdatePan_Full_WriteChDepth

Voice_UpdatePan_Full_NoPanDepth2:
	ld xwa, (xsp + 4)
	cp (xwa + 47), 0x0
	jr z, Voice_UpdatePan_Full_WriteChDepth
	ld xwa, (xsp + 4)
	ld a, (xwa + 47)
	ld e, a
	exts de
	ld xwa, (xsp + 14)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ldw_erp HL, 0xFA
	ld wa, (xsp + 10)
	addw_erp WA, 0xFA
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl
	ld wa, (xsp + 12)
	addw_erp WA, 0xFA
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 12), hl

Voice_UpdatePan_Full_WriteChDepth:
	ld xwa, (xsp + 4)
	ld a, (xwa + 42)
	extz wa
	lda_24 xbc, 0x011963
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld hl, wa
	lds wa, 4
	cps hl, 4
	jr lt, Voice_UpdatePan_Full_WriteCh2
	ld wa, hl

Voice_UpdatePan_Full_WriteCh2:
	ld hl, wa
	ld xwa, (xsp + 4)
	ld a, (xwa + 44)
	extz wa
	lda_24 xbc, 0x011963
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld de, wa
	ld wa, hl
	ldb w, 0x0
	ld bc, (xsp + 10)
	sla bc, 8
	or bc, wa
	stw_da 0x0451e6, xbc
	ld wa, de
	ldb w, 0x0
	ld bc, (xsp + 12)
	sla bc, 8
	or bc, wa
	stw_da 0x0451e8, xbc
	pop xiz
	lda xsp, (xsp + 14)
	ret

Voice_UpdatePan_Mono:
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 14), xwa
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 23)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 19)
	bitm 4, (xwa + 16)
	jr z, Voice_UpdatePan_Mono_SetInvFlag
	ld xwa, (xsp + 14)
	andmi16 (xwa + 1), 0x7FFF
	jr Voice_UpdatePan_Mono_ComputePan

Voice_UpdatePan_Mono_SetInvFlag:
	ld xwa, (xsp + 14)
	ormi16 (xwa + 1), 0x8000

Voice_UpdatePan_Mono_ComputePan:
	ld xwa, (xsp + 4)
	ld a, (xwa + 39)
	extz wa
	lda_24 xbc, 0x011899
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ldw_erp WA, 0xFA
	ld xwa, (xsp + 4)
	cp (xwa + 51), 0x0
	jrl z, Voice_UpdatePan_Mono_NoPanLFO
	ld xwa, (xsp + 4)
	ld a, (xwa + 48)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 49)
	ld e, a
	extz de
	ld xwa, (xsp + 4)
	ld a, (xwa + 50)
	extz wa
	pushw wa
	ld xwa, (xsp + 6)
	ld a, (xwa + 51)
	exts wa
	pushw wa
	ld xwa, (xsp + 18)
	ld wa, (xwa + 8)
	calr Pan_ScaleWithVelocity
	ld (xsp + 8), hl
	ld xwa, (xsp + 4)
	cp (xwa + 46), 0x0
	jr z, Voice_UpdatePan_Mono_NoPanDepth
	ld xwa, (xsp + 4)
	ld a, (xwa + 46)
	ld e, a
	exts de
	ld xwa, (xsp + 14)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ld iz, hl
	stw_erp WA, 0xFA
	add wa, (xsp + 8)
	add wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ldw_erp HL, 0xFA
	jr Voice_UpdatePan_Mono_CheckMax

Voice_UpdatePan_Mono_NoPanDepth:
	stw_erp WA, 0xFA
	add wa, (xsp + 8)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ldw_erp HL, 0xFA
	jr Voice_UpdatePan_Mono_CheckMax

Voice_UpdatePan_Mono_NoPanLFO:
	ld xwa, (xsp + 4)
	cp (xwa + 46), 0x0
	jr z, Voice_UpdatePan_Mono_CheckMax
	ld xwa, (xsp + 4)
	ld a, (xwa + 46)
	ld e, a
	exts de
	ld xwa, (xsp + 14)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ld iz, hl
	stw_erp WA, 0xFA
	add wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ldw_erp HL, 0xFA

Voice_UpdatePan_Mono_CheckMax:
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 31)
	bitm 0, (xwa)
	jr z, Voice_UpdatePan_Mono_WriteDSP
	stw_erp WA, 0xFA
	cp wa, 0xFF
	jr nz, Voice_UpdatePan_Mono_WriteDSP
	dec1w_erp 0xFA

Voice_UpdatePan_Mono_WriteDSP:
	ld xwa, (xsp + 4)
	ld a, (xwa + 40)
	extz wa
	lda_24 xbc, 0x011963
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ldb w, 0x0
	stw_erp BC, 0xFA
	sla bc, 8
	or bc, wa
	stw_da 0x0451e4, xbc
	ld xwa, (xsp + 14)
	ld (xwa + 60), bc
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 35)
	ldb_sri0 A, (xwa + 0x010b)
	ld c, a
	exts bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 41)
	extz wa
	add wa, bc
	ldw bc, 0x64
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 10), wa
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 35)
	ldb_sri0 A, (xwa + 0x010b)
	ld c, a
	exts bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 43)
	extz wa
	add wa, bc
	ldw bc, 0x64
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 12), hl
	ld wa, (xsp + 12)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 12), wa
	ld xwa, (xsp + 4)
	cp (xwa + 52), 0x0
	jrl z, Voice_UpdatePan_Full2_NoPanDepth
	ld xwa, (xsp + 4)
	ld a, (xwa + 48)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ld a, (xwa + 49)
	ld e, a
	extz de
	ld xwa, (xsp + 4)
	ld a, (xwa + 50)
	extz wa
	pushw wa
	ld xwa, (xsp + 6)
	ld a, (xwa + 52)
	exts wa
	pushw wa
	ld xwa, (xsp + 18)
	ld wa, (xwa + 8)
	calr Pan_ScaleWithVelocity
	ld (xsp + 8), hl
	ld xwa, (xsp + 4)
	cp (xwa + 47), 0x0
	jr z, Voice_UpdatePan_Full2_NoModDepth
	ld xwa, (xsp + 4)
	ld a, (xwa + 47)
	ld e, a
	exts de
	ld xwa, (xsp + 14)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ld iz, hl
	ld wa, (xsp + 10)
	add wa, (xsp + 8)
	add wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl
	ld wa, (xsp + 12)
	add wa, (xsp + 8)
	add wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 12), hl
	jr Voice_UpdatePan_Full2_WriteChDepth

Voice_UpdatePan_Full2_NoModDepth:
	ld wa, (xsp + 10)
	add wa, (xsp + 8)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl
	ld wa, (xsp + 12)
	add wa, (xsp + 8)
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 12), hl
	jr Voice_UpdatePan_Full2_WriteChDepth

Voice_UpdatePan_Full2_NoPanDepth:
	ld xwa, (xsp + 4)
	cp (xwa + 47), 0x0
	jr z, Voice_UpdatePan_Full2_WriteChDepth
	ld xwa, (xsp + 4)
	ld a, (xwa + 47)
	ld e, a
	exts de
	ld xwa, (xsp + 14)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	ld iz, hl
	ld wa, (xsp + 10)
	add wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 10), hl
	ld wa, (xsp + 12)
	add wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld (xsp + 12), hl

Voice_UpdatePan_Full2_WriteChDepth:
	ld xwa, (xsp + 4)
	ld a, (xwa + 42)
	extz wa
	lda_24 xbc, 0x011963
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld hl, wa
	lds wa, 4
	cps hl, 4
	jr lt, Voice_UpdatePan_Full2_WriteCh2
	ld wa, hl

Voice_UpdatePan_Full2_WriteCh2:
	ld hl, wa
	ld xwa, (xsp + 4)
	ld a, (xwa + 44)
	extz wa
	lda_24 xbc, 0x011963
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld de, wa
	ld wa, hl
	ldb w, 0x0
	ld bc, (xsp + 10)
	sla bc, 8
	or bc, wa
	stw_da 0x0451e6, xbc
	ld wa, de
	ldb w, 0x0
	ld bc, (xsp + 12)
	sla bc, 8
	or bc, wa
	stw_da 0x0451e8, xbc
	pop xiz
	lda xsp, (xsp + 14)
	ret

Voice_InterpolatePanCurve:
	ld hl, (xwa + 8)
	and hl, 0x7F00
	sra hl, 8
	ld a, (xbc + 30)
	extz wa
	cp hl, wa
	jr ge, Voice_InterpolatePanCurve_HighCheck
	ld a, (xbc + 31)
	extz wa
	cp hl, wa
	jr ge, Voice_InterpolatePanCurve_LowRange
	ldw hl, 0xFE00
	jr Voice_InterpolatePanCurve_Done

Voice_InterpolatePanCurve_LowRange:
	ld a, (xbc + 31)
	ld e, a
	extz de
	ld a, (xbc + 30)
	extz wa
	ld ix, wa
	sub ix, de
	ld a, (xbc + 30)
	extz wa
	sub wa, hl
	muls wa, 0xFFC0
	ld hl, wa
	exts xwa
	divs xwa, xix
	ld hl, wa
	jr Voice_InterpolatePanCurve_Done

Voice_InterpolatePanCurve_HighCheck:
	ld a, (xbc + 32)
	extz wa
	cp hl, wa
	jr le, Voice_InterpolatePanCurve_Zero
	ld a, (xbc + 33)
	extz wa
	cp hl, wa
	jr le, Voice_InterpolatePanCurve_HighRange
	ldw hl, 0xFE00
	jr Voice_InterpolatePanCurve_Done

Voice_InterpolatePanCurve_HighRange:
	ld a, (xbc + 32)
	ld e, a
	extz de
	ld a, (xbc + 33)
	extz wa
	ld ix, wa
	sub ix, de
	ld a, (xbc + 32)
	extz wa
	ld bc, hl
	sub bc, wa
	ld wa, bc
	muls wa, 0xFFC0
	ld hl, wa
	exts xwa
	divs xwa, xix
	ld hl, wa
	jr Voice_InterpolatePanCurve_Done

Voice_InterpolatePanCurve_Zero:
	lds hl, 0

Voice_InterpolatePanCurve_Done:
	ret

Voice_InterpolateNoteCurve:
	ld a, (xwa + 12)
	ld l, a
	extz hl
	and hl, 0x7F
	ld a, (xbc + 34)
	extz wa
	cp hl, wa
	jr ge, Voice_InterpolateNoteCurve_HighCheck
	ld a, (xbc + 35)
	extz wa
	cp hl, wa
	jr ge, Voice_InterpolateNoteCurve_LowRange
	ldw hl, 0xFE00
	jr Voice_InterpolateNoteCurve_Done

Voice_InterpolateNoteCurve_LowRange:
	ld a, (xbc + 35)
	ld e, a
	extz de
	ld a, (xbc + 34)
	extz wa
	ld ix, wa
	sub ix, de
	ld a, (xbc + 34)
	extz wa
	sub wa, hl
	muls wa, 0xFFC0
	ld hl, wa
	exts xwa
	divs xwa, xix
	ld hl, wa
	jr Voice_InterpolateNoteCurve_Done

Voice_InterpolateNoteCurve_HighCheck:
	ld a, (xbc + 36)
	extz wa
	cp hl, wa
	jr le, Voice_InterpolateNoteCurve_Zero
	ld a, (xbc + 37)
	extz wa
	cp hl, wa
	jr le, Voice_InterpolateNoteCurve_HighRange
	ldw hl, 0xFE00
	jr Voice_InterpolateNoteCurve_Done

Voice_InterpolateNoteCurve_HighRange:
	ld a, (xbc + 36)
	ld e, a
	extz de
	ld a, (xbc + 37)
	extz wa
	ld ix, wa
	sub ix, de
	ld a, (xbc + 36)
	extz wa
	ld bc, hl
	sub bc, wa
	ld wa, bc
	muls wa, 0xFFC0
	ld hl, wa
	exts xwa
	divs xwa, xix
	ld hl, wa
	jr Voice_InterpolateNoteCurve_Done

Voice_InterpolateNoteCurve_Zero:
	lds hl, 0

Voice_InterpolateNoteCurve_Done:
	ret

Voice_ComputePitch:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	ld xwa, (xsp + 6)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	bit 7, bc
	jr z, Voice_ComputePitch_CheckSysExTune
	ld xwa, (xsp + 6)
	ormi16 (xwa + 1), 0x800

Voice_ComputePitch_CheckSysExTune:
	and bc, 0x7F
	ldw_da xwa, 0x041343
	bit 0, wa
	jr nz, Voice_ComputePitch_SysExTable
	ld xwa, (xsp + 2)
	cp (xwa + 25), 0xE0
	jr nz, Voice_ComputePitch_CheckAltTune

Voice_ComputePitch_SysExTable:
	ld wa, bc
	extz xwa
	ld xbc, 0x11C96
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld iz, wa
	sub iz, 0xC
	jrl Voice_ComputePitch_ApplyLFO

Voice_ComputePitch_CheckAltTune:
	ldw_da xwa, 0x041343
	bit 1, wa
	jr z, Voice_ComputePitch_NormalTune
	ld wa, bc
	extz xwa
	ld xbc, 0x11C96
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld iz, wa
	sub iz, 0xC
	jr Voice_ComputePitch_ApplyLFO

Voice_ComputePitch_NormalTune:
	ld xwa, (xsp + 2)
	cp (xwa + 24), 0x0
	jr ge, Voice_ComputePitch_PortaPositive
	ld wa, bc
	extz xwa
	ld xbc, 0xFEE4
	add xbc, xwa
	ld a, (xbc)
	ld c, a
	extz bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 25)
	ld e, a
	extz de
	ld wa, bc
	ld bc, de
	calr Voice_Colour_LookupIndex
	sub hl, 0xD0
	ld xwa, (xsp + 2)
	ld a, (xwa + 24)
	exts wa
	cpl wa
	ld bc, wa
	inc 1, bc
	ld wa, hl
	muls xwa, xbc
	ld hl, wa
	jr Voice_ComputePitch_PortaScale

Voice_ComputePitch_PortaPositive:
	ld xwa, (xsp + 2)
	ld a, (xwa + 25)
	ld e, a
	extz de
	ld wa, bc
	ld bc, de
	calr Voice_Colour_LookupIndex
	sub hl, 0xD0
	ld xwa, (xsp + 2)
	ld a, (xwa + 24)
	ld c, a
	exts bc
	ld wa, hl
	muls xwa, xbc
	ld hl, wa

Voice_ComputePitch_PortaScale:
	sra hl, 5
	ld iz, hl
	add iz, 0xD8

Voice_ComputePitch_ApplyLFO:
	ld xwa, (xsp + 2)
	ld a, (xwa + 26)
	ld c, a
	extz bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 27)
	ld e, a
	extz de
	ld xwa, (xsp + 2)
	ld a, (xwa + 28)
	extz wa
	pushw wa
	ld xwa, (xsp + 4)
	ld a, (xwa + 29)
	exts wa
	pushw wa
	ld xwa, (xsp + 10)
	ld wa, (xwa + 8)
	calr Voice_Colour_ClampUpper
	add iz, hl
	ld xwa, (xsp + 6)
	ld wa, (xwa + 43)
	and wa, 0x7F
	extz xwa
	ld xbc, 0x11A4F
	add xbc, xwa
	ld a, (xbc)
	exts wa
	add iz, wa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 15)
	ld a, (xwa + 3)
	exts wa
	add iz, wa
	ldl_da xwa, 0x045314
	add_sriw_rm IZ, 0xE1, 0xE0, 0x00
	addda16 xiz, 10560
	ld xwa, (xsp + 6)
	ld xbc, (xsp + 2)
	calr Voice_InterpolatePanCurve
	add iz, hl
	ld xwa, (xsp + 6)
	ld xbc, (xsp + 2)
	calr Voice_InterpolateNoteCurve
	add iz, hl
	ld xwa, (xsp + 2)
	bitm 7, (xwa)
	jr z, Voice_ComputePitch_WriteDone
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ldb_sri0 A, (xwa + 0x011e)
	extz wa
	add iz, wa

Voice_ComputePitch_WriteDone:
	ld xwa, (xsp + 6)
	ld (xwa + 13), iz
	ld xwa, (xsp + 6)
	ldw (xwa + 51), 0x0
	popw iz
	inc 8, xsp
	ret

Voice_ComputePitch_InlineData:
	.byte 0xda, 0xf0, 0x69, 0x04, 0xda, 0x88, 0x68, 0x06
	.byte 0xd9, 0xf0, 0x62, 0x02, 0xd9, 0x88, 0xd8, 0x8b
	.byte 0x0e

Voice_ComputePitch_Mono:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 23)
	ld xwa, (xsp + 4)
	ld a, (xwa + 12)
	ld e, a
	extz de
	and de, 0x7F
	ldw_da xwa, 0x041343
	bit 0, wa
	jr nz, Voice_ComputePitch_Mono_SysExTable
	cp (xiz + 7), 0xE0
	jr nz, Voice_ComputePitch_Mono_CheckAltTune

Voice_ComputePitch_Mono_SysExTable:
	ld wa, de
	extz xwa
	ld xbc, 0x11C96
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld hl, wa
	sub hl, 0xC
	jr Voice_ComputePitch_Mono_ApplyLFO

Voice_ComputePitch_Mono_CheckAltTune:
	ldw_da xwa, 0x041343
	bit 1, wa
	jr z, Voice_ComputePitch_Mono_CheckPorta
	ld wa, de
	extz xwa
	ld xbc, 0x11C96
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld hl, wa
	sub hl, 0xC

Voice_ComputePitch_Mono_CheckPorta:
	cp (xiz + 6), 0x0
	jr ge, Voice_ComputePitch_Mono_PortaPositive
	ld wa, de
	extz xwa
	ld xbc, 0xFEE4
	add xbc, xwa
	ld a, (xbc)
	ld e, a
	extz de
	ld a, (xiz + 7)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_Colour_LookupIndex
	sub hl, 0xD0
	ld a, (xiz + 6)
	exts wa
	cpl wa
	ld bc, wa
	inc 1, bc
	ld wa, hl
	muls xwa, xbc
	ld hl, wa
	jr Voice_ComputePitch_Mono_PortaScale

Voice_ComputePitch_Mono_PortaPositive:
	ld a, (xiz + 7)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_Colour_LookupIndex
	sub hl, 0xD0
	ld a, (xiz + 6)
	ld c, a
	exts bc
	ld wa, hl
	muls xwa, xbc
	ld hl, wa

Voice_ComputePitch_Mono_PortaScale:
	sra hl, 5
	add hl, 0xD8

Voice_ComputePitch_Mono_ApplyLFO:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 43)
	and wa, 0x7F
	extz xwa
	ld xbc, 0x11A4F
	add xbc, xwa
	ld a, (xbc)
	exts wa
	add hl, wa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 15)
	ld a, (xwa + 3)
	exts wa
	add hl, wa
	ldl_da xwa, 0x045314
	add_sriw_rm HL, 0xE1, 0xE0, 0x00
	addda16 xhl, 10560
	ld xwa, (xsp + 4)
	ld (xwa + 13), hl
	ld xwa, (xsp + 4)
	ldw (xwa + 51), 0x0
	pop xiz
	inc 4, xsp
	ret

Voice_ApplyPortamento:
	ld de, (xwa + 13)
	ld xbc, (xwa + 23)
	cp (xbc + 23), 0x0
	jr z, Voice_ApplyPortamento_NoChanDetune
	ld xbc, (xwa + 23)
	ld c, (xbc + 23)
	extz bc
	sub bc, 0x64
	add de, bc
	jr Voice_ApplyPortamento_ApplyDetune

Voice_ApplyPortamento_NoChanDetune:
	sub de, 0x200

Voice_ApplyPortamento_ApplyDetune:
	ld xbc, (xwa + 39)
	ld c, (xbc + 34)
	exts bc
	add de, bc
	ldw_da xbc, 0x041343
	bit 1, bc
	jr z, Voice_ApplyPortamento_Done
	cp (xwa + 4), 0x1
	jr ugt, Voice_ApplyPortamento_HighNote
	ld xbc, (xwa + 35)
	sub de, (xbc + 16)
	dec 8, de
	jr Voice_ApplyPortamento_Done

Voice_ApplyPortamento_HighNote:
	sub de, 0x10

Voice_ApplyPortamento_Done:
	ld bc, de
	jrl Voice_Colour_Write

Voice_ApplyPortamento2:
	ld xbc, (xwa + 23)
	ld de, (xwa + 13)
	cp (xbc + 5), 0x0
	jr z, Voice_ApplyPortamento2_NoChanDetune
	ld c, (xbc + 5)
	extz bc
	sub bc, 0x64
	add de, bc
	jr Voice_ApplyPortamento2_ApplyDetune

Voice_ApplyPortamento2_NoChanDetune:
	sub de, 0x200

Voice_ApplyPortamento2_ApplyDetune:
	ldw_da xbc, 0x041343
	bit 1, bc
	jr z, Voice_ApplyPortamento2_Done
	ld xbc, (xwa + 35)
	sub de, (xbc + 16)
	ld xbc, (xwa + 35)
	sub de, (xbc + 12)
	ldw hl, 0xFE00
	ld xbc, (xwa + 35)
	ld bc, (xbc + 12)
	cp bc, 0xFE00
	jr z, Voice_ApplyPortamento2_AddVibrato
	ld xbc, (xwa + 35)
	ld bc, (xbc + 12)
	sra bc, 2
	ld hl, bc

Voice_ApplyPortamento2_AddVibrato:
	add de, hl

Voice_ApplyPortamento2_Done:
	ld bc, de
	jrl Voice_Colour_Write

Voice_WriteChPitchWithVib:
	dec 2, xsp
	push xiz
	extz bc
	muls bc, 0x47
	lda_24 xde, 0x0430ad
	ld_sril3 XBC, 0x07, 0xE8, 0xE4
	bitm 3, (xbc)
	jr z, Voice_WriteChPitchWithVib_Done
	ld c, (xbc + 14)
	ld (xsp + 4), c
	extz bc
	lda_24 xde, 0x011ae8
	ldb_sri C, 0x07, 0xE8, 0xE4
	extz bc
	sll bc, 8
	set 7, bc
	stw_da 0x0451f8, xbc
	ld c, (xsp + 4)
	extz bc
	lda_24 xde, 0x011ae8
	ldb_sri C, 0x07, 0xE8, 0xE4
	extz bc
	sll bc, 8
	stw_da 0x0451fa, xbc
	extz wa
	call Voice_AllocateForFull
	lda xwa, (xhl + 5)
	ld xiz, xwa
	cp (xiz), 0x40
	jr nc, Voice_WriteChPitchWithVib_Done

Voice_WriteChPitchWithVib_Loop:
	ld a, (xiz)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x0430ad
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	ld a, (xsp + 4)
	cp a, (xbc + 14)
	jr nz, Voice_WriteChPitchWithVib_NextSlot
	ld a, (xiz)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteNote_2Regs

Voice_WriteChPitchWithVib_NextSlot:
	inc 1, xiz
	cp (xiz), 0x40
	jr c, Voice_WriteChPitchWithVib_Loop

Voice_WriteChPitchWithVib_Done:
	pop xiz
	inc 2, xsp
	ret

Voice_ComputeAndWriteVolume1:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 108)
	ld c, a
	exts bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 45)
	extz wa
	add wa, bc
	ldw bc, 0x64
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	stb_erp A, 0xF8
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld iz, wa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld wa, (xwa + 10)
	bit 0, wa
	jr z, Voice_ComputeAndWriteVolume1_ApplyLFO
	ld xwa, (xsp + 6)
	ld wa, (xwa + 1)
	bit 8, wa
	jr nz, Voice_ComputeAndWriteVolume1_ApplyLFO
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 24)
	extz wa
	lda_24 xbc, 0x011adf
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	cp wa, iz
	jr gt, Voice_ComputeAndWriteVolume1_ApplyLFO
	ld iz, wa

Voice_ComputeAndWriteVolume1_ApplyLFO:
	ld xwa, (xsp + 2)
	cp (xwa + 53), 0x0
	jr z, Voice_ComputeAndWriteVolume1_WriteDSP
	ld xwa, (xsp + 2)
	ld a, (xwa + 48)
	ld c, a
	extz bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 49)
	ld e, a
	extz de
	ld xwa, (xsp + 2)
	ld a, (xwa + 50)
	extz wa
	pushw wa
	ld xwa, (xsp + 4)
	ld a, (xwa + 53)
	exts wa
	pushw wa
	ld xwa, (xsp + 10)
	ld wa, (xwa + 8)
	calr Pan_ScaleWithVelocity
	add iz, hl
	ld wa, iz
	calr Voice_Clamp_Byte_HL
	ld iz, hl

Voice_ComputeAndWriteVolume1_WriteDSP:
	ld wa, iz
	sla wa, 8
	set 7, wa
	stw_da 0x0451f8, xwa
	ld wa, iz
	sla wa, 8
	stw_da 0x0451fa, xwa
	popw iz
	inc 8, xsp
	ret

Voice_WritePan_Passthrough:
	ld bc, (xwa + 62)
	stw_da 0x0451e6, xbc
	ld wa, (xwa + 64)
	stw_da 0x0451e8, xwa
	ret

Voice_WriteVolume_SetFlag:
	ld bc, (xwa + 64)
	set 7, bc
	stw_da 0x0451f8, xbc
	ld wa, (xwa + 64)
	stw_da 0x0451fa, xwa
	ret

Voice_ComputeVolume_CappedLFO:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld wa, (xwa + 10)
	bit 0, wa
	jr z, Voice_ComputeVolume_CappedLFO_UseOscMax
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 24)
	extz wa
	lda_24 xbc, 0x011adf
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld iz, wa
	ld xwa, (xsp + 2)
	ld a, (xwa + 45)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld bc, iz
	cp bc, wa
	jr ule, Voice_ComputeVolume_CappedLFO_ApplyLFO
	ld xwa, (xsp + 2)
	ld a, (xwa + 45)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld iz, wa
	jr Voice_ComputeVolume_CappedLFO_ApplyLFO

Voice_ComputeVolume_CappedLFO_UseOscMax:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ldb_sri0 A, (xwa + 0x010d)
	ld c, a
	exts bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 45)
	extz wa
	add wa, bc
	ldw bc, 0x64
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	stb_erp A, 0xF8
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld iz, wa

Voice_ComputeVolume_CappedLFO_ApplyLFO:
	ld xwa, (xsp + 2)
	cp (xwa + 53), 0x0
	jr z, Voice_ComputeVolume_CappedLFO_WriteDSP
	ld xwa, (xsp + 2)
	ld a, (xwa + 48)
	ld c, a
	extz bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 49)
	ld e, a
	extz de
	ld xwa, (xsp + 2)
	ld a, (xwa + 50)
	extz wa
	pushw wa
	ld xwa, (xsp + 4)
	ld a, (xwa + 53)
	exts wa
	pushw wa
	ld xwa, (xsp + 10)
	ld wa, (xwa + 8)
	calr Pan_ScaleWithVelocity
	add iz, hl
	ld wa, iz
	calr Voice_Clamp_Byte_HL
	ld iz, hl

Voice_ComputeVolume_CappedLFO_WriteDSP:
	ld wa, iz
	sla wa, 8
	set 7, wa
	stw_da 0x0451f8, xwa
	ld wa, iz
	sla wa, 8
	stw_da 0x0451fa, xwa
	popw iz
	inc 8, xsp
	ret

Voice_ComputeAndWriteVolume2:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	ld a, (xwa + 15)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld iz, wa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld wa, (xwa + 10)
	bit 0, wa
	jr z, Voice_ComputeAndWriteVolume2_ApplyLFO
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 24)
	extz wa
	lda_24 xbc, 0x011adf
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	cp wa, iz
	jr gt, Voice_ComputeAndWriteVolume2_ApplyLFO
	ld iz, wa

Voice_ComputeAndWriteVolume2_ApplyLFO:
	ld xwa, (xsp + 2)
	cp (xwa + 22), 0x0
	jr z, Voice_ComputeAndWriteVolume2_NoLFO
	ld xwa, (xsp + 2)
	ld a, (xwa + 19)
	ld c, a
	extz bc
	pushw 0x7F
	ld xwa, (xsp + 4)
	ld a, (xwa + 22)
	exts wa
	pushw wa
	ld xwa, (xsp + 10)
	ld wa, (xwa + 8)
	lds de, 0
	calr Pan_ScaleWithVelocity
	add iz, hl
	ld xwa, (xsp + 2)
	cp (xwa + 17), 0x0
	jr z, Voice_ComputeAndWriteVolume2_NoKeyTrack
	ld xwa, (xsp + 2)
	ld a, (xwa + 17)
	ld e, a
	exts de
	ld xwa, (xsp + 6)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	add iz, hl
	ld wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	jr Voice_ComputeAndWriteVolume2_WriteDSP

Voice_ComputeAndWriteVolume2_NoKeyTrack:
	ld wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	jr Voice_ComputeAndWriteVolume2_WriteDSP

Voice_ComputeAndWriteVolume2_NoLFO:
	ld xwa, (xsp + 2)
	cp (xwa + 17), 0x0
	jr z, Voice_ComputeAndWriteVolume2_WriteDSP
	ld xwa, (xsp + 2)
	ld a, (xwa + 17)
	ld e, a
	exts de
	ld xwa, (xsp + 6)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	add iz, hl
	ld wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl

Voice_ComputeAndWriteVolume2_WriteDSP:
	ld xwa, (xsp + 2)
	cp (xwa + 7), 0x0
	jr ge, Voice_ComputeAndWriteVolume2_PositiveDetune
	ld xwa, (xsp + 2)
	ld a, (xwa + 16)
	exts wa
	cpl wa
	inc 1, wa
	calr Detune_ScaleSymmetric
	jr Voice_ComputeAndWriteVolume2_WriteResult

Voice_ComputeAndWriteVolume2_PositiveDetune:
	ld xwa, (xsp + 2)
	ld a, (xwa + 16)
	exts wa
	calr Detune_ScaleSymmetric

Voice_ComputeAndWriteVolume2_WriteResult:
	ldb h, 0x0
	ld wa, iz
	sla wa, 8
	or wa, hl
	stw_da 0x0451fc, xwa
	stw_da 0x0451fe, xwa
	popw iz
	inc 8, xsp
	ret

Voice_ComputeAndWriteVolume3:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	ld a, (xwa + 69)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	ld iz, wa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld wa, (xwa + 10)
	bit 0, wa
	jr z, Voice_ComputeAndWriteVolume3_ApplyLFO
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 35)
	ld a, (xwa + 24)
	extz wa
	lda_24 xbc, 0x011adf
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	cp wa, iz
	jr gt, Voice_ComputeAndWriteVolume3_ApplyLFO
	ld iz, wa

Voice_ComputeAndWriteVolume3_ApplyLFO:
	ld xwa, (xsp + 2)
	cp (xwa + 76), 0x0
	jr z, Voice_ComputeAndWriteVolume3_NoLFO
	ld xwa, (xsp + 2)
	ld a, (xwa + 73)
	ld c, a
	extz bc
	pushw 0x7F
	ld xwa, (xsp + 4)
	ld a, (xwa + 76)
	exts wa
	pushw wa
	ld xwa, (xsp + 10)
	ld wa, (xwa + 8)
	lds de, 0
	calr Pan_ScaleWithVelocity
	add iz, hl
	ld xwa, (xsp + 2)
	cp (xwa + 71), 0x0
	jr z, Voice_ComputeAndWriteVolume3_NoKeyTrack
	ld xwa, (xsp + 2)
	ld a, (xwa + 71)
	ld e, a
	exts de
	ld xwa, (xsp + 6)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	add iz, hl
	ld wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	jr Voice_ComputeAndWriteVolume3_WriteDSP

Voice_ComputeAndWriteVolume3_NoKeyTrack:
	ld wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl
	jr Voice_ComputeAndWriteVolume3_WriteDSP

Voice_ComputeAndWriteVolume3_NoLFO:
	ld xwa, (xsp + 2)
	cp (xwa + 71), 0x0
	jr z, Voice_ComputeAndWriteVolume3_WriteDSP
	ld xwa, (xsp + 2)
	ld a, (xwa + 71)
	ld e, a
	exts de
	ld xwa, (xsp + 6)
	ld a, (xwa + 12)
	ld c, a
	extz bc
	ld wa, de
	lds de, 4
	calr PitchBend_Scale
	add iz, hl
	ld wa, iz
	ldw bc, 0xFF
	lds de, 0
	calr ClampS16_WA_To_DEBC
	ld iz, hl

Voice_ComputeAndWriteVolume3_WriteDSP:
	ld xwa, (xsp + 2)
	ld a, (xwa + 61)
	ld c, a
	exts bc
	ld xwa, (xsp + 2)
	ld a, (xwa + 70)
	exts wa
	add wa, bc
	ldw bc, 0x32
	ldw de, 0xFFCE
	calr ClampS16_WA_To_DEBC
	ld wa, hl
	calr Detune_ScaleSymmetric
	ldb h, 0x0
	ld wa, iz
	sla wa, 8
	or wa, hl
	stw_da 0x045200, xwa
	stw_da 0x045202, xwa
	popw iz
	inc 8, xsp
	ret

Voice_WriteVolume_Muted:
	stiw_da 0x0451fc, 0x0000
	stiw_da 0x0451fe, 0x0000
	ld c, (xwa + 70)
	extz bc
	sll bc, 8
	set 7, bc
	stw_da 0x0451f8, xbc
	ld a, (xwa + 70)
	extz wa
	sll wa, 8
	stw_da 0x0451fa, xwa
	stiw_da 0x045200, 0x0000
	stiw_da 0x045202, 0x0000
	ret

Voice_WriteVolume_OrPan:
	ld xbc, (xwa + 19)
	ld xwa, (xwa + 23)
	bitm 5, (xbc + 13)
	jr z, Voice_WriteVolume_OrPan_Muted
	ld a, (xwa + 13)
	extz wa
	lda_24 xbc, 0x0118fe
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	sll wa, 8
	stw_da 0x0451fa, xwa
	set 7, wa
	stw_da 0x0451f8, xwa
	ret

Voice_WriteVolume_OrPan_Muted:
	stiw_da 0x0451f8, 0x0080
	stiw_da 0x0451fa, 0x0000
	ret

Voice_AdvanceLFOPhase:
	ld c, (xwa)
	and c, 0x1C
	cp c, 0x8
	jr z, Voice_AdvanceLFOPhase_Triangle
	cp c, 0x10
	jr nz, Voice_AdvanceLFOPhase_Idle
	lda xbc, (xwa + 8)
	incm8 1, (xbc)
	ld c, (xbc)
	cp c, (xwa + 7)
	jr c, Voice_AdvanceLFOPhase_IncDone
	ld (xwa + 8), 0x0
	resm 4, (xwa)
	setm 3, (xwa)

Voice_AdvanceLFOPhase_IncDone:
	lds hl, 0
	jr Voice_AdvanceLFOPhase_Done

Voice_AdvanceLFOPhase_Triangle:
	lda xbc, (xwa + 8)
	incm8 1, (xbc)
	ld c, (xbc)
	cp c, (xwa + 7)
	jr nc, Voice_AdvanceLFOPhase_TriangleReset
	ld l, (xwa + 8)
	extz hl
	sll hl, 8
	ld a, (xwa + 7)
	ld c, a
	extz bc
	ld wa, hl
	extz xwa
	div xwa, xbc
	ld hl, wa
	jr Voice_AdvanceLFOPhase_Done

Voice_AdvanceLFOPhase_TriangleReset:
	ld (xwa + 8), 0x0
	resm 3, (xwa)
	setm 2, (xwa)
	ldw hl, 0x100
	jr Voice_AdvanceLFOPhase_Done

Voice_AdvanceLFOPhase_Idle:
	lds hl, 0

Voice_AdvanceLFOPhase_Done:
	ret

Voice_UpdateAllLFO:
	push xiz
	lds iz, 0
	cp iz, 0x80
	jr nc, Voice_UpdateAllLFO_Loop2

Voice_UpdateAllLFO_Loop1:
	ld wa, iz
	extz xwa
	ld xbc, 0x1B
	call FP_MulAccum64
	lda_24 xbc, 0x04424e
	add xbc, xhl
	ld a, (xbc)
	and a, 0x18
	jr z, Voice_UpdateAllLFO_NextSlot1
	ld xwa, xbc
	calr Voice_AdvanceLFOPhase
	ldw_erp HL, 0xFA
	cpiw_erp 0xFA, 0
	jr z, Voice_UpdateAllLFO_NextSlot1
	stb_erp A, 0xF8
	extz wa
	calr EGEnv_Compute_A
	stw_da 0x04520c, xhl
	cp_erpw 0xFA, 0x00, 0x01
	jr z, Voice_UpdateAllLFO_DispatchVoice1
	ldw_da xhl, 0x04520c
	extz xhl
	and xhl, 0x1FFF
	stw_erp BC, 0xFA
	extz xbc
	ld xwa, xhl
	call FP_MulAccum64
	anddi16_24 283148, 57344
	srl xhl, 8
	ordm16_24 283148, xhl

Voice_UpdateAllLFO_DispatchVoice1:
	ld wa, iz
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParam_600

Voice_UpdateAllLFO_NextSlot1:
	inc 1, iz
	cp iz, 0x80
	jr c, Voice_UpdateAllLFO_Loop1

Voice_UpdateAllLFO_Loop2:
	lds iz, 0
	cp iz, 0x40
	jr nc, Voice_UpdateAllLFO_Loop3

Voice_UpdateAllLFO_Loop2_Body:
	ld wa, iz
	extz xwa
	ld xbc, 0x1B
	call FP_MulAccum64
	lda_24 xwa, 0x044257
	add xwa, xhl
	ld xbc, xwa
	ld a, (xbc)
	and a, 0x18
	jr z, Voice_UpdateAllLFO_NextSlot2
	ld xwa, xbc
	calr Voice_AdvanceLFOPhase
	ldw_erp HL, 0xFA
	cpiw_erp 0xFA, 0
	jr z, Voice_UpdateAllLFO_NextSlot2
	stb_erp A, 0xF8
	extz wa
	calr EGEnv_Compute_B
	stw_da 0x045204, xhl
	cp_erpw 0xFA, 0x00, 0x01
	jr z, Voice_UpdateAllLFO_DispatchVoice2
	ldw_da xhl, 0x045204
	extz xhl
	and xhl, 0x1FFF
	stw_erp BC, 0xFA
	extz xbc
	ld xwa, xhl
	call FP_MulAccum64
	anddi16_24 283140, 57344
	srl xhl, 8
	ordm16_24 283140, xhl

Voice_UpdateAllLFO_DispatchVoice2:
	ld wa, iz
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParam_1C0_Single

Voice_UpdateAllLFO_NextSlot2:
	inc 1, iz
	cp iz, 0x40
	jr c, Voice_UpdateAllLFO_Loop2_Body

Voice_UpdateAllLFO_Loop3:
	lds iz, 0
	cp iz, 0x80
	jrl nc, Voice_UpdateAllLFO_Done

Voice_UpdateAllLFO_Loop3_Body:
	ld wa, iz
	extz xwa
	ld xbc, 0x1B
	call FP_MulAccum64
	lda_24 xwa, 0x044260
	add xwa, xhl
	ld xbc, xwa
	ld a, (xbc)
	and a, 0x18
	jr z, Voice_UpdateAllLFO_NextSlot3
	ld xwa, xbc
	calr Voice_AdvanceLFOPhase
	ldw_erp HL, 0xFA
	cpiw_erp 0xFA, 0
	jr z, Voice_UpdateAllLFO_NextSlot3
	stb_erp A, 0xF8
	extz wa
	calr Voice_Freq_WriteLeft
	cp_erpw 0xFA, 0x00, 0x01
	jr z, Voice_UpdateAllLFO_DispatchVoice3
	cp iz, 0x40
	jr nc, Voice_UpdateAllLFO_DispatchGroup3_High
	ldw_da xhl, 0x045204
	extz xhl
	and xhl, 0x1FFF
	stw_erp BC, 0xFA
	extz xbc
	ld xwa, xhl
	call FP_MulAccum64
	anddi16_24 283140, 57344
	srl xhl, 8
	ordm16_24 283140, xhl
	jr Voice_UpdateAllLFO_DispatchVoice3

Voice_UpdateAllLFO_DispatchGroup3_High:
	ldw_da xhl, 0x04520e
	extz xhl
	and xhl, 0x1FFF
	stw_erp BC, 0xFA
	extz xbc
	ld xwa, xhl
	call FP_MulAccum64
	anddi16_24 283150, 57344
	srl xhl, 8
	ordm16_24 283150, xhl

Voice_UpdateAllLFO_DispatchVoice3:
	ld wa, iz
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParam_TypeDispatch_Single

Voice_UpdateAllLFO_NextSlot3:
	inc 1, iz
	cp iz, 0x80
	jrl c, Voice_UpdateAllLFO_Loop3_Body

Voice_UpdateAllLFO_Done:
	pop xiz
	ret

Voice_UpdateNoteOff:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ld iz, (xwa + 47)
	ld wa, iz
	extz xwa
	bit 15, wa
	jr z, Voice_UpdateNoteOff_CheckRelease
	sub iz, 0x100
	ld wa, iz
	and wa, 0x7F00
	jr nz, Voice_UpdateNoteOff_CheckRelease
	ld xwa, (xsp + 2)
	ld a, (xwa)
	extz wa
	ld xbc, (xsp + 2)
	ld bc, (xbc + 45)
	call ToneGen_WriteSingleReg
	ld xwa, (xsp + 2)
	ld a, (xwa)
	extz wa
	call VoiceSlot_Release
	res 15, iz

Voice_UpdateNoteOff_CheckRelease:
	bit 7, iz
	jr z, Voice_UpdateNoteOff_StoreDone
	dec 1, iz
	ld wa, iz
	and wa, 0x7F
	jr nz, Voice_UpdateNoteOff_StoreDone
	ld xwa, (xsp + 2)
	ld a, (xwa)
	extz wa
	call Voice_Release
	and iz, 0x7F

Voice_UpdateNoteOff_StoreDone:
	ld xwa, (xsp + 2)
	ld (xwa + 47), iz
	popw iz
	inc 4, xsp
	ret

Voice_UpdatePortamento:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), xwa
	ld xwa, (xsp + 4)
	ld wa, (xwa + 49)
	ld (xsp + 2), wa
	and wa, 0x7F
	jrl nz, Voice_UpdatePortamento_ActiveCount
	ld xwa, (xsp + 4)
	ld a, (xwa + 53)
	extz wa
	or (xsp + 2), wa
	xormi16 (xsp + 2), 0x800
	ld wa, (xsp + 2)
	bit 11, wa
	jrl z, Voice_UpdatePortamento_ZeroState
	ld xwa, (xsp + 4)
	ld a, (xwa + 4)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04138e
	cpib_sri 0x07, 0xE4, 0xE0, 0x01
	jr nz, Voice_UpdatePortamento_ModeCheck2
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	ld xbc, (xsp + 4)
	ld bc, (xbc + 43)
	call ToneGen_WriteSingleReg_180
	jr Voice_UpdatePortamento_DispatchMode

Voice_UpdatePortamento_ModeCheck2:
	ld xwa, (xsp + 4)
	ld a, (xwa + 4)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04138e
	cpib_sri 0x07, 0xE4, 0xE0, 0x02
	jr nz, Voice_UpdatePortamento_ModeDefault
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	ld xbc, (xsp + 4)
	ld bc, (xbc + 43)
	call ToneGen_WriteSingleReg_180
	jr Voice_UpdatePortamento_DispatchMode

Voice_UpdatePortamento_ModeDefault:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	ld l, a
	extz hl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 39)
	ld a, (xwa + 36)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	ld wa, (xwa + 43)
	and wa, 0xFF80
	ld de, wa
	or de, bc
	ld wa, hl
	ld bc, de
	call ToneGen_WriteSingleReg_180
	jr Voice_UpdatePortamento_DispatchMode

Voice_UpdatePortamento_ZeroState:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	ld xbc, (xsp + 4)
	ld bc, (xbc + 43)
	call ToneGen_WriteSingleReg_180

Voice_UpdatePortamento_DispatchMode:
	ld wa, (xsp + 2)
	and wa, 0x7000
	cp wa, 0x1000
	jrl z, Voice_UpdatePortamento_Release_Start
	cp wa, 0x2000
	jrl z, Voice_UpdatePortamento_Descend_Tick
	cp wa, 0x4000
	jrl nz, Voice_UpdatePortamento_NullMode
	ld xwa, (xsp + 4)
	ld iz, (xwa + 54)
	ld xwa, (xsp + 4)
	add iz, (xwa + 51)
	cp iz, 0xFF00
	jr gt, Voice_UpdatePortamento_Ascend_Tick
	ld xwa, (xsp + 4)
	ldw (xwa + 51), 0xFF00
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	call VoiceSlot_Release
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	call Voice_Release
	andmi16 (xsp + 2), 0x6FFF
	jrl Voice_UpdatePortamento_StoreDone

Voice_UpdatePortamento_Ascend_Tick:
	res_dd8 7, 0x18
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff00
	jr __jrt_nop_026FFD
__jrt_nop_026FFD:

Voice_UpdatePortamento_Ascend_Tick2:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff80
	jr __jrt_nop_027020
__jrt_nop_027020:

Voice_UpdatePortamento_Ascend_ClampFloor:
	nop
	nop
	nop
	ld xwa, (xsp + 4)
	cp iz, (xwa + 58)
	jr ge, Voice_UpdatePortamento_Ascend_WritePitch
	ld xwa, (xsp + 4)
	ld iz, (xwa + 58)
	resm 6, (xsp + 3)
	setm 5, (xsp + 3)

Voice_UpdatePortamento_Ascend_WritePitch:
	ld xwa, (xsp + 4)
	ld (xwa + 51), iz
	ld xwa, (xsp + 4)
	calr Voice_ApplyPortamento
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	lda_24 xbc, 0x0451cc
	ld xde, (xsp + 4)
	call ToneGen_WriteVoiceParams_Ext
	jrl Voice_UpdatePortamento_StoreDone

Voice_UpdatePortamento_Descend_Tick:
	res_dd8 7, 0x18
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff00
	jr __jrt_nop_027079
__jrt_nop_027079:

Voice_UpdatePortamento_Descend_Tick2:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff80
	jr __jrt_nop_02709C
__jrt_nop_02709C:

Voice_UpdatePortamento_Descend_WritePitch:
	nop
	nop
	nop
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	ld xbc, (xsp + 4)
	call ToneGen_WriteVoiceParams_Ext2
	jrl Voice_UpdatePortamento_StoreDone

Voice_UpdatePortamento_Release_Start:
	ld xwa, (xsp + 4)
	ld iz, (xwa + 56)
	ld xwa, (xsp + 4)
	add iz, (xwa + 51)
	cp iz, 0xFF00
	jr gt, Voice_UpdatePortamento_Release_Tick
	ld xwa, (xsp + 4)
	ldw (xwa + 51), 0xFF00
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	call VoiceSlot_Release
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	call Voice_Release
	andmi16 (xsp + 2), 0x6FFF
	jrl Voice_UpdatePortamento_StoreDone

Voice_UpdatePortamento_Release_Tick:
	res_dd8 7, 0x18
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff00
	jr __jrt_nop_027108
__jrt_nop_027108:

Voice_UpdatePortamento_Release_Tick2:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff80
	jr __jrt_nop_02712B
__jrt_nop_02712B:

Voice_UpdatePortamento_Release_WritePitch:
	nop
	nop
	nop
	ld xwa, (xsp + 4)
	ld (xwa + 51), iz
	ld xwa, (xsp + 4)
	calr Voice_ApplyPortamento
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	lda_24 xbc, 0x0451cc
	ld xde, (xsp + 4)
	call ToneGen_WriteVoiceParams_Ext
	jr Voice_UpdatePortamento_StoreDone

Voice_UpdatePortamento_NullMode:
	ldw (xsp + 2), 0x0
	jr Voice_UpdatePortamento_StoreDone

Voice_UpdatePortamento_ActiveCount:
	ld wa, (xsp + 2)
	and wa, 0x7F
	cps wa, 1
	jr nz, Voice_UpdatePortamento_CountDecrement
	res_dd8 7, 0x18
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xa200
	jr __jrt_nop_027181
__jrt_nop_027181:

Voice_UpdatePortamento_CountTick:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xa280
	jr __jrt_nop_0271A4
__jrt_nop_0271A4:

Voice_UpdatePortamento_CountTick2:
	nop
	nop
	nop
	decm 1, (xsp + 2)
	jr Voice_UpdatePortamento_StoreDone

Voice_UpdatePortamento_CountDecrement:
	decm 1, (xsp + 2)

Voice_UpdatePortamento_StoreDone:
	ld xwa, (xsp + 4)
	ld bc, (xsp + 2)
	ld (xwa + 49), bc
	popw iz
	inc 6, xsp
	ret

Voice_ApplyTuningSysEx:
	ldw_da xwa, 0x041343
	bit 11, wa
	jr z, Voice_ApplyTuningSysEx_Bit12
	incdi16_24 1, 267100
	ldb_da a, 0x011c7c
	exts wa
	add wa, wa
	stw_da 0x04135a, xwa
	anddi16_24 267075, 63487
	ordi16_24 267075, 5120
	ret

Voice_ApplyTuningSysEx_Bit12:
	ldw_da xwa, 0x041343
	bit 12, wa
	jr z, Voice_ApplyTuningSysEx_Bit13Check
	incdi16_24 1, 267100
	anddi16_24 267075, 64511
	ret

Voice_ApplyTuningSysEx_Bit13Check:
	ldw_da xwa, 0x041343
	bit 13, wa
	jrl z, Voice_ApplyTuningSysEx_ClearMode
	ldw_da xwa, 0x041343
	bit 14, wa
	jr z, Voice_ApplyTuningSysEx_Bit14Clear
	incdi16_24 2, 267100
	ldw_da xwa, 0x04135c
	extz xwa
	ld xbc, 0x11C7C
	add xbc, xwa
	ld a, (xbc)
	exts wa
	add wa, wa
	stw_da 0x04135a, xwa
	ordi16_24 267075, 1024
	jr Voice_ApplyTuningSysEx_CheckCounter

Voice_ApplyTuningSysEx_Bit14Clear:
	ldw_da xwa, 0x041343
	extz xwa
	bit 15, wa
	jr z, Voice_ApplyTuningSysEx_ZeroPitch
	incdi16_24 1, 267100
	ldw_da xwa, 0x04135c
	extz xwa
	ld xbc, 0x11C7C
	add xbc, xwa
	ld a, (xbc)
	exts wa
	add wa, wa
	stw_da 0x04135a, xwa
	ordi16_24 267075, 1024
	jr Voice_ApplyTuningSysEx_CheckCounter

Voice_ApplyTuningSysEx_ZeroPitch:
	stiw_da 0x04135a, 0x0000
	ordi16_24 267075, 1024

Voice_ApplyTuningSysEx_CheckCounter:
	cpw_da 267098, 0
	ret nz
	anddi16_24 267075, 8191
	stiw_da 0x04135c, 0x0000
	ordi16_24 267075, 1024
	ret

Voice_ApplyTuningSysEx_ClearMode:
	anddi16_24 267075, 64511
	ret

Voice_InitVoiceState:
	stiw_da 0x0451ce, 0x0000
	ldw_da xbc, 0x041360
	stw_da 0x0451da, xbc
	stiw_da 0x0451ec, 0x0000
	stiw_da 0x0451ee, 0x0000
	stiw_da 0x0451f0, 0x0000
	stiw_da 0x0451d4, 0x017f
	stiw_da 0x0451d6, 0x7f7f
	stiw_da 0x0451f2, 0x0000
	stiw_da 0x0451f4, 0x0000
	stiw_da 0x0451f6, 0x0000
	stiw_da 0x0451e2, 0x0000
	stiw_da 0x0451ea, 0x0000
	stiw_da 0x0451dc, 0x0000
	stiw_da 0x0451de, 0x0000
	stiw_da 0x0451d8, 0x0040
	stiw_da 0x0451e0, 0x0000
	stiw_da 0x0451d2, 0x0000
	stiw_da 0x0451e4, 0xff7f
	ldw_da xbc, 0x041362
	stw_da 0x0451e6, xbc
	ldw_da xbc, 0x041362
	stw_da 0x0451e8, xbc
	ldw_da xbc, 0x041364
	add bc, bc
	lda_24 xde, 0x010764
	ldw_sri BC, 0x07, 0xE8, 0xE4
	add bc, bc
	stw_da 0x0451d0, xbc
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x0430bb
	stiw_ind 0x07, 0xE4, 0xE0, 0x00, 0xF0
	ret

Voice_TickNoteDecay:
	lda xsp, (xsp - 14)
	pushw_erp 0xFA
	cpib_da 0x04135e, 0x00
	jr z, Voice_TickNoteDecay_Done
	decdi8_24 1, 267103
	cpib_da 0x04135f, 0x00
	jr nz, Voice_TickNoteDecay_Done
	lda xwa, (xsp + 2)
	call Voice_SetPanning
	cp (xsp + 12), 0x40
	jr nc, Voice_TickNoteDecay_Reload
	ld a, (xsp + 12)
	ldb_erp A, 0xFB
	extz wa
	calr Voice_InitVoiceState
	stb_erp A, 0xFB
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteVoiceParams
	stb_erp A, 0xFB
	ld l, a
	extz hl
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x47
	ld bc, wa
	lda_24 xde, 0x0430bb
	ld wa, hl
	ldw_sri BC, 0x07, 0xE8, 0xE4
	call ToneGen_WriteSingleReg

Voice_TickNoteDecay_Reload:
	decdi8_24 1, 267102
	stib_da 0x04135f, 0x04

Voice_TickNoteDecay_Done:
	popw_erp 0xFA
	lda xsp, (xsp + 14)
	ret

Voice_LoadPitchTable_Ch:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), c
	ld (xsp + 8), a
	ld a, (xsp + 8)
	extz wa
	lds bc, 1
	call DSP_AlgoType_Dispatch2
	extz xhl
	ld a, (xsp + 6)
	lds32 xbc, 0
	ld c, a
	ld xwa, xhl
	call FP_MulAccum64
	srl xhl, 8
	cp xhl, 0x2C
	jr nc, Voice_LoadPitchTable_Ch_NoClamp
	stiw_da 0x045208, 0x002c
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413c5
	stiw_ind 0x07, 0xE4, 0xE0, 0x2C, 0x00
	jr Voice_LoadPitchTable_Ch_ScanLoop

Voice_LoadPitchTable_Ch_NoClamp:
	ld wa, hl
	stw_da 0x045208, xwa
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413c5
	stw_dri HL, 0x07, 0xE4, 0xE0

Voice_LoadPitchTable_Ch_ScanLoop:
	ld a, (xsp + 8)
	extz wa
	lds bc, 1
	call DSP_AlgoType_Dispatch1
	extz xhl
	ld a, (xsp + 6)
	extz wa
	lda_24 xbc, 0x010dce
	ldb_sri A, 0x07, 0xE4, 0xE0
	lds32 xbc, 0
	ld c, a
	ld xwa, xhl
	call FP_MulAccum64
	srl xhl, 8
	ld wa, hl
	stw_da 0x04520c, xwa
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413c3
	stw_dri HL, 0x07, 0xE4, 0xE0
	ld a, (xsp + 8)
	extz wa
	ldw bc, 0xD
	lds de, 0
	call Voice_BuildOutputList
	ld (xsp + 2), xhl
	lds iz, 0
	jr Voice_LoadPitchTable_Ch_LoopCheck

Voice_LoadPitchTable_Ch_LoopBody:
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 2)
	ld wa, (xwa)
	ldb w, 0x0
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParams_56
	inc 1, iz

Voice_LoadPitchTable_Ch_LoopCheck:
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 2)
	ld wa, (xwa)
	and wa, 0xFF
	cp wa, 0x80
	jr c, Voice_LoadPitchTable_Ch_LoopBody
	popw iz
	inc 8, xsp
	ret

Voice_LoadPitchTable_All:
	dec 8, xsp
	ld (xsp + 6), a
	ld a, (xsp + 6)
	extz wa
	lds bc, 1
	call DSP_AlgoType_Dispatch2
	stw_da 0x045208, xhl
	ld a, (xsp + 6)
	extz wa
	lds bc, 1
	call DSP_AlgoType_Dispatch1
	stw_da 0x04520c, xhl
	ld a, (xsp + 6)
	extz wa
	ldw bc, 0xD
	lds de, 0
	call Voice_BuildOutputList
	ld (xsp), xhl
	ldw (xsp + 4), 0x0
	jr Voice_LoadPitchTable_All_LoopCheck

Voice_LoadPitchTable_All_LoopBody:
	ld wa, (xsp + 4)
	extz xwa
	add xwa, xwa
	add xwa, (xsp)
	ld wa, (xwa)
	ldb w, 0x0
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParams_56
	incm 1, (xsp + 4)

Voice_LoadPitchTable_All_LoopCheck:
	ld wa, (xsp + 4)
	extz xwa
	add xwa, xwa
	add xwa, (xsp)
	ld wa, (xwa)
	and wa, 0xFF
	cp wa, 0x80
	jr c, Voice_LoadPitchTable_All_LoopBody
	inc 8, xsp
	ret

Voice_LoadFilterTable_Ch:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), c
	ld (xsp + 8), a
	ld a, (xsp + 8)
	extz wa
	lds bc, 0
	call DSP_AlgoType_Dispatch2
	extz xhl
	ld a, (xsp + 6)
	lds32 xbc, 0
	ld c, a
	ld xwa, xhl
	call FP_MulAccum64
	srl xhl, 8
	cp xhl, 0x1C
	jr nc, Voice_LoadFilterTable_Ch_NoClamp
	stiw_da 0x04520a, 0x001c
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413c1
	stiw_ind 0x07, 0xE4, 0xE0, 0x1C, 0x00
	jr Voice_LoadFilterTable_Ch_ScanFilter

Voice_LoadFilterTable_Ch_NoClamp:
	ld wa, hl
	stw_da 0x04520a, xwa
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413c1
	stw_dri HL, 0x07, 0xE4, 0xE0

Voice_LoadFilterTable_Ch_ScanFilter:
	ld a, (xsp + 8)
	extz wa
	lds bc, 0
	call DSP_AlgoType_Dispatch1
	extz xhl
	ld a, (xsp + 6)
	extz wa
	lda_24 xbc, 0x010ece
	ldb_sri A, 0x07, 0xE4, 0xE0
	lds32 xbc, 0
	ld c, a
	ld xwa, xhl
	call FP_MulAccum64
	srl xhl, 8
	ld wa, hl
	stw_da 0x04520e, xwa
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413bf
	stw_dri HL, 0x07, 0xE4, 0xE0
	ld a, (xsp + 8)
	extz wa
	ldw bc, 0xC
	lds de, 0
	call Voice_BuildOutputList
	ld (xsp + 2), xhl
	lds iz, 0
	jr Voice_LoadFilterTable_Ch_LoopCheck

Voice_LoadFilterTable_Ch_LoopBody:
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 2)
	ld wa, (xwa)
	ldb w, 0x0
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParams_56b
	inc 1, iz

Voice_LoadFilterTable_Ch_LoopCheck:
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 2)
	ld wa, (xwa)
	and wa, 0xFF
	cp wa, 0x80
	jr c, Voice_LoadFilterTable_Ch_LoopBody
	popw iz
	inc 8, xsp
	ret

Voice_LoadFilterTable_All:
	dec 8, xsp
	ld (xsp + 6), a
	ld a, (xsp + 6)
	extz wa
	lds bc, 0
	call DSP_AlgoType_Dispatch2
	stw_da 0x04520a, xhl
	ld a, (xsp + 6)
	extz wa
	lds bc, 0
	call DSP_AlgoType_Dispatch1
	stw_da 0x04520e, xhl
	ld a, (xsp + 6)
	extz wa
	ldw bc, 0xC
	lds de, 0
	call Voice_BuildOutputList
	ld (xsp), xhl
	ldw (xsp + 4), 0x0
	jr Voice_LoadFilterTable_All_LoopCheck

Voice_LoadFilterTable_All_LoopBody:
	ld wa, (xsp + 4)
	extz xwa
	add xwa, xwa
	add xwa, (xsp)
	ld wa, (xwa)
	ldb w, 0x0
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParams_56b
	incm 1, (xsp + 4)

Voice_LoadFilterTable_All_LoopCheck:
	ld wa, (xsp + 4)
	extz xwa
	add xwa, xwa
	add xwa, (xsp)
	ld wa, (xwa)
	and wa, 0xFF
	cp wa, 0x80
	jr c, Voice_LoadFilterTable_All_LoopBody
	inc 8, xsp
	ret

Voice_LoadToneTable_Ch:
	lda xsp, (xsp - 10)
	ld (xsp + 6), c
	ld (xsp + 8), a
	ld a, (xsp + 8)
	extz wa
	call DSP_ChanFreq_WritePacket2
	extz xhl
	ld a, (xsp + 6)
	lds32 xbc, 0
	ld c, a
	ld xwa, xhl
	call FP_MulAccum64
	srl xhl, 8
	cp xhl, 0x1C
	jr nc, Voice_LoadToneTable_Ch_NoClamp
	stiw_da 0x045206, 0x001c
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413c9
	stiw_ind 0x07, 0xE4, 0xE0, 0x1C, 0x00
	jr Voice_LoadToneTable_Ch_ScanLoop

Voice_LoadToneTable_Ch_NoClamp:
	ld wa, hl
	stw_da 0x045206, xwa
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413c9
	stw_dri HL, 0x07, 0xE4, 0xE0

Voice_LoadToneTable_Ch_ScanLoop:
	ld a, (xsp + 8)
	extz wa
	ldw bc, 0x10
	lds de, 0
	call Voice_BuildOutputList
	ld (xsp), xhl
	ldw (xsp + 4), 0x0
	jr Voice_LoadToneTable_Ch_LoopCheck

Voice_LoadToneTable_Ch_LoopBody:
	ld wa, (xsp + 4)
	extz xwa
	add xwa, xwa
	add xwa, (xsp)
	ld wa, (xwa)
	ldb w, 0x0
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParams_15_Alt
	incm 1, (xsp + 4)

Voice_LoadToneTable_Ch_LoopCheck:
	ld wa, (xsp + 4)
	extz xwa
	add xwa, xwa
	add xwa, (xsp)
	ld wa, (xwa)
	and wa, 0xFF
	cp wa, 0x40
	jr c, Voice_LoadToneTable_Ch_LoopBody
	lda xsp, (xsp + 10)
	ret

Voice_LoadToneTable_All:
	dec 8, xsp
	ld (xsp + 6), a
	ld a, (xsp + 6)
	extz wa
	call DSP_ChanFreq_WritePacket2
	stw_da 0x045206, xhl
	ld a, (xsp + 6)
	extz wa
	ldw bc, 0x10
	lds de, 0
	call Voice_BuildOutputList
	ld (xsp), xhl
	ldw (xsp + 4), 0x0
	jr Voice_LoadToneTable_All_LoopCheck

Voice_LoadToneTable_All_LoopBody:
	ld wa, (xsp + 4)
	extz xwa
	add xwa, xwa
	add xwa, (xsp)
	ld wa, (xwa)
	ldb w, 0x0
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteExtParams_15_Alt
	incm 1, (xsp + 4)

Voice_LoadToneTable_All_LoopCheck:
	ld wa, (xsp + 4)
	extz xwa
	add xwa, xwa
	add xwa, (xsp)
	ld wa, (xwa)
	and wa, 0xFF
	cp wa, 0x40
	jr c, Voice_LoadToneTable_All_LoopBody
	inc 8, xsp
	ret

Voice_ToneTableRamp_Up:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 6), a
	cp (xiz + 100), 0x4F
	jr c, Voice_ToneTableRamp_Up_Increment
	setm 3, (xiz + 99)
	ld a, (xsp + 6)
	extz wa
	calr Voice_LoadPitchTable_All
	jr Voice_ToneTableRamp_Up_CheckFilter

Voice_ToneTableRamp_Up_Increment:
	incm8 1, (xiz + 100)
	resm 3, (xiz + 99)
	ld a, (xiz + 100)
	ld (xsp + 4), a
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x010d64
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld wa, de
	calr Voice_LoadPitchTable_Ch

Voice_ToneTableRamp_Up_CheckFilter:
	cp (xiz + 101), 0x96
	jr c, Voice_ToneTableRamp_Up_FilterIncrement
	ld a, (xsp + 6)
	extz wa
	calr Voice_LoadFilterTable_All
	ld a, (xsp + 6)
	extz wa
	calr Voice_LoadToneTable_All
	jr Voice_ToneTableRamp_Up_Done

Voice_ToneTableRamp_Up_FilterIncrement:
	incm8 1, (xiz + 101)
	resm 3, (xiz + 99)
	ld a, (xiz + 101)
	extz wa
	div a, 0x6
	ld (xsp + 4), a
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x010db4
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld wa, de
	calr Voice_LoadFilterTable_Ch
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x010db4
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld wa, de
	calr Voice_LoadToneTable_Ch

Voice_ToneTableRamp_Up_Done:
	pop xiz
	inc 4, xsp
	ret

Voice_ToneTableRamp_Down:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 6), a
	cp (xiz + 100), 0x0
	jr nz, Voice_ToneTableRamp_Down_Decrement
	setm 4, (xiz + 99)
	jr Voice_ToneTableRamp_Down_CheckFilter

Voice_ToneTableRamp_Down_Decrement:
	decm8 1, (xiz + 100)
	resm 4, (xiz + 99)
	ld a, (xiz + 100)
	srl a, 1
	ld (xsp + 4), a
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x010db4
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld wa, de
	calr Voice_LoadPitchTable_Ch

Voice_ToneTableRamp_Down_CheckFilter:
	cp (xiz + 101), 0x0
	jr z, Voice_ToneTableRamp_Down_Done
	decm8 1, (xiz + 101)
	resm 4, (xiz + 99)
	ld a, (xiz + 101)
	extz wa
	div a, 0x5
	ld (xsp + 4), a
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x010db4
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld wa, de
	calr Voice_LoadFilterTable_Ch
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x010db4
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld wa, de
	calr Voice_LoadToneTable_Ch

Voice_ToneTableRamp_Down_Done:
	pop xiz
	inc 4, xsp
	ret

Voice_ToneTableApply_Pitch:
	dec 6, xsp
	pushw_erp 0xFA
	ld (xsp + 2), xbc
	ld (xsp + 6), a
	ld xwa, (xsp + 2)
	andmi8 (xwa + 99), 0xE7
	ld xwa, (xsp + 2)
	ld a, (xwa + 100)
	extz wa
	lda_24 xbc, 0x010d64
	ldb_sri L, 0x07, 0xE4, 0xE0
	ldi_erpb 0xFB, 0x19
	jr Voice_ToneTableApply_Pitch_Loop

Voice_ToneTableApply_Pitch_Decrement:
	dec1b_erp 0xFB

Voice_ToneTableApply_Pitch_Loop:
	stb_erp A, 0xFB
	extz wa
	lda_24 xbc, 0x010db4
	cpb_sri_rm L, 0x07, 0xE4, 0xE0
	jr c, Voice_ToneTableApply_Pitch_Decrement
	ld xwa, (xsp + 2)
	stb_erp C, 0xFB
	ld (xwa + 100), c
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld a, l
	extz wa
	lda_24 xbc, 0x010d64
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld wa, de
	calr Voice_LoadPitchTable_Ch
	ld xwa, (xsp + 2)
	ld l, (xwa + 101)
	ld a, l
	extz wa
	div a, 0x6
	ld l, a
	ldb_erp L, 0xFB
	ld a, l
	mul a, 0x5
	ld l, a
	ld xwa, (xsp + 2)
	ld (xwa + 101), l
	ld a, (xsp + 6)
	ld e, a
	extz de
	stb_erp A, 0xFB
	extz wa
	lda_24 xbc, 0x010db4
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld wa, de
	calr Voice_LoadFilterTable_Ch
	ld a, (xsp + 6)
	ld e, a
	extz de
	stb_erp A, 0xFB
	extz wa
	lda_24 xbc, 0x010db4
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld wa, de
	calr Voice_LoadToneTable_Ch
	popw_erp 0xFA
	inc 6, xsp
	ret

Voice_ToneTableApply_Filter:
	dec 6, xsp
	pushw_erp 0xFA
	ld (xsp + 2), xbc
	ld (xsp + 6), a
	ld xwa, (xsp + 2)
	andmi8 (xwa + 99), 0xE7
	ld xwa, (xsp + 2)
	ld a, (xwa + 100)
	srl a, 1
	extz wa
	lda_24 xbc, 0x010db4
	ldb_sri E, 0x07, 0xE4, 0xE0
	ldib_erp 0xFB, 0
	jr Voice_ToneTableApply_Filter_Loop

Voice_ToneTableApply_Filter_Increment:
	inc1b_erp 0xFB

Voice_ToneTableApply_Filter_Loop:
	stb_erp A, 0xFB
	extz wa
	lda_24 xbc, 0x010d64
	cpb_sri_rm E, 0x07, 0xE4, 0xE0
	jr ugt, Voice_ToneTableApply_Filter_Increment
	ld xwa, (xsp + 2)
	stb_erp C, 0xFB
	ld (xwa + 100), c
	ld a, (xsp + 6)
	ld e, a
	extz de
	stb_erp A, 0xFB
	extz wa
	lda_24 xbc, 0x010db4
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld wa, de
	calr Voice_LoadPitchTable_Ch
	ld xwa, (xsp + 2)
	ld e, (xwa + 101)
	ld a, e
	extz wa
	div a, 0x5
	ld e, a
	ldb_erp E, 0xFB
	ld a, e
	mul a, 0x6
	ld e, a
	ld xwa, (xsp + 2)
	ld (xwa + 101), e
	ld a, (xsp + 6)
	ld e, a
	extz de
	stb_erp A, 0xFB
	extz wa
	lda_24 xbc, 0x010db4
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld wa, de
	calr Voice_LoadFilterTable_Ch
	ld a, (xsp + 6)
	ld e, a
	extz de
	stb_erp A, 0xFB
	extz wa
	lda_24 xbc, 0x010db4
	ldb_sri C, 0x07, 0xE4, 0xE0
	ld wa, de
	calr Voice_LoadToneTable_Ch
	popw_erp 0xFA
	inc 6, xsp
	ret

Voice_ScanAndCancelNoteOff:
	dec 4, xsp
	push xiz
	calr Voice_UpdateAllLFO
	call Voice_AllocateForAny
	lda xwa, (xhl + 5)
	ld (xsp + 4), xwa
	cp (xwa), 0x40
	jr nc, Voice_ScanAndCancelNoteOff_Done

Voice_ScanAndCancelNoteOff_Loop:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	stb_dri H, 0x07, 0xE4, 0xE0
	ld xwa, (xiz + 35)
	ld wa, (xwa + 10)
	extz xwa
	bit 15, wa
	jr z, Voice_ScanAndCancelNoteOff_ClearSlot
	ld wa, (xiz + 47)
	extz xwa
	and xwa, 0x8080
	jr z, Voice_ScanAndCancelNoteOff_NextSlot
	ld xwa, xiz
	calr Voice_UpdateNoteOff
	jr Voice_ScanAndCancelNoteOff_NextSlot

Voice_ScanAndCancelNoteOff_ClearSlot:
	ld wa, (xiz + 47)
	extz xwa
	and xwa, 0x8080
	jr z, Voice_ScanAndCancelNoteOff_NextSlot
	ld a, (xiz)
	extz wa
	call VoiceSlot_Release
	ld a, (xiz)
	extz wa
	call Voice_Release
	ldw (xiz + 47), 0x0

Voice_ScanAndCancelNoteOff_NextSlot:
	lds32 xwa, 1
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	cp (xwa), 0x40
	jr c, Voice_ScanAndCancelNoteOff_Loop

Voice_ScanAndCancelNoteOff_Done:
	pop xiz
	inc 4, xsp
	ret

Voice_UpdateAllNoteStates:
	dec 4, xsp
	push xiz
	calr Voice_TickNoteDecay
	calr Voice_ApplyTuningSysEx
	ldw_da xwa, 0x041343
	bit 10, wa
	jrl z, Voice_UpdateAllNoteStates_LoopB_Start
	call Voice_AllocateForAny
	lda xwa, (xhl + 5)
	ld (xsp + 4), xwa
	cp (xwa), 0x40
	jrl nc, Voice_UpdateAllNoteStates_ScanLFO

Voice_UpdateAllNoteStates_LoopA:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	stb_dri H, 0x07, 0xE4, 0xE0
	ld wa, (xiz + 1)
	bit 10, wa
	jr z, Voice_UpdateAllNoteStates_CheckPortaA
	ld xwa, xiz
	calr Voice_Pitch_WriteOutputReg_Legato
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WritePanReg

Voice_UpdateAllNoteStates_CheckPortaA:
	ld xwa, (xiz + 35)
	ld wa, (xwa + 10)
	extz xwa
	bit 15, wa
	jr z, Voice_UpdateAllNoteStates_ClearNoteOffA
	ld wa, (xiz + 47)
	extz xwa
	and xwa, 0x8080
	jr z, Voice_UpdateAllNoteStates_CheckPortamento2A
	ld xwa, xiz
	calr Voice_UpdateNoteOff
	jr Voice_UpdateAllNoteStates_NextSlotA

Voice_UpdateAllNoteStates_CheckPortamento2A:
	ld wa, (xiz + 49)
	extz xwa
	bit 15, wa
	jr z, Voice_UpdateAllNoteStates_NextSlotA
	ld xwa, xiz
	calr Voice_UpdatePortamento
	jr Voice_UpdateAllNoteStates_NextSlotA

Voice_UpdateAllNoteStates_ClearNoteOffA:
	ld wa, (xiz + 47)
	extz xwa
	and xwa, 0x8080
	jr z, Voice_UpdateAllNoteStates_ClearPorta2A
	ld a, (xiz)
	extz wa
	call VoiceSlot_Release
	ld a, (xiz)
	extz wa
	call Voice_Release
	ldw (xiz + 47), 0x0
	jr Voice_UpdateAllNoteStates_NextSlotA

Voice_UpdateAllNoteStates_ClearPorta2A:
	ld wa, (xiz + 49)
	extz xwa
	bit 15, wa
	jr z, Voice_UpdateAllNoteStates_NextSlotA
	ld a, (xiz)
	extz wa
	call VoiceSlot_Release
	ld a, (xiz)
	extz wa
	call Voice_Release
	ldw (xiz + 49), 0x0

Voice_UpdateAllNoteStates_NextSlotA:
	lds32 xwa, 1
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	cp (xwa), 0x40
	jrl c, Voice_UpdateAllNoteStates_LoopA
	jrl Voice_UpdateAllNoteStates_ScanLFO

Voice_UpdateAllNoteStates_LoopB_Start:
	call Voice_AllocateForAny
	lda xwa, (xhl + 5)
	ld (xsp + 4), xwa
	cp (xwa), 0x40
	jrl nc, Voice_UpdateAllNoteStates_ScanLFO

Voice_UpdateAllNoteStates_LoopB:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	stb_dri H, 0x07, 0xE4, 0xE0
	ld xwa, (xiz + 35)
	ld wa, (xwa + 10)
	extz xwa
	bit 15, wa
	jr z, Voice_UpdateAllNoteStates_ClearNoteOffB
	ld wa, (xiz + 47)
	extz xwa
	and xwa, 0x8080
	jr z, Voice_UpdateAllNoteStates_CheckPortamento2B
	ld xwa, xiz
	calr Voice_UpdateNoteOff
	jr Voice_UpdateAllNoteStates_NextSlotB

Voice_UpdateAllNoteStates_CheckPortamento2B:
	ld wa, (xiz + 49)
	extz xwa
	bit 15, wa
	jr z, Voice_UpdateAllNoteStates_NextSlotB
	ld xwa, xiz
	calr Voice_UpdatePortamento
	jr Voice_UpdateAllNoteStates_NextSlotB

Voice_UpdateAllNoteStates_ClearNoteOffB:
	ld wa, (xiz + 47)
	extz xwa
	and xwa, 0x8080
	jr z, Voice_UpdateAllNoteStates_ClearPorta2B
	ld a, (xiz)
	extz wa
	call VoiceSlot_Release
	ld a, (xiz)
	extz wa
	call Voice_Release
	ldw (xiz + 47), 0x0
	jr Voice_UpdateAllNoteStates_NextSlotB

Voice_UpdateAllNoteStates_ClearPorta2B:
	ld wa, (xiz + 49)
	extz xwa
	bit 15, wa
	jr z, Voice_UpdateAllNoteStates_NextSlotB
	ld a, (xiz)
	extz wa
	call VoiceSlot_Release
	ld a, (xiz)
	extz wa
	call Voice_Release
	ldw (xiz + 49), 0x0

Voice_UpdateAllNoteStates_NextSlotB:
	lds32 xwa, 1
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	cp (xwa), 0x40
	jrl c, Voice_UpdateAllNoteStates_LoopB

Voice_UpdateAllNoteStates_ScanLFO:
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0x1A
	jr nc, Voice_UpdateAllNoteStates_Done

Voice_UpdateAllNoteStates_LFOLoopBody:
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	stb_dri A, 0x07, 0xE4, 0xE0
	ld a, (xbc + 99)
	bit 0, a
	jr z, Voice_UpdateAllNoteStates_LFONextSlot
	bit 1, a
	jr z, Voice_UpdateAllNoteStates_LFO_CheckRampDown
	bit 2, a
	jr z, Voice_UpdateAllNoteStates_LFO_ApplyFilter
	bit 3, a
	jr nz, Voice_UpdateAllNoteStates_LFONextSlot
	stb_erp A, 0xFB
	extz wa
	calr Voice_ToneTableRamp_Up
	jr Voice_UpdateAllNoteStates_LFONextSlot

Voice_UpdateAllNoteStates_LFO_ApplyFilter:
	setm 2, (xbc + 99)
	stb_erp A, 0xFB
	extz wa
	calr Voice_ToneTableApply_Filter
	jr Voice_UpdateAllNoteStates_LFONextSlot

Voice_UpdateAllNoteStates_LFO_CheckRampDown:
	bit 2, a
	jr nz, Voice_UpdateAllNoteStates_LFO_RampDown
	bit 4, a
	jr nz, Voice_UpdateAllNoteStates_LFONextSlot
	stb_erp A, 0xFB
	extz wa
	calr Voice_ToneTableRamp_Down
	jr Voice_UpdateAllNoteStates_LFONextSlot

Voice_UpdateAllNoteStates_LFO_RampDown:
	resm 2, (xbc + 99)
	stb_erp A, 0xFB
	extz wa
	calr Voice_ToneTableApply_Pitch

Voice_UpdateAllNoteStates_LFONextSlot:
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0x1A
	jr c, Voice_UpdateAllNoteStates_LFOLoopBody

Voice_UpdateAllNoteStates_Done:
	pop xiz
	inc 4, xsp
	ret

Voice_SetLFO_ActiveFlag:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	or_sriw_im 0x07, 0xE4, 0xE0, 0x00, 0x20
	ret

Voice_ClearLFO_ActiveFlag:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	and_sriw_im 0x07, 0xE4, 0xE0, 0xFF, 0xDF
	ret

; ----------------------------------------------------------------------------
; Voice_DSP_OutputConfig - Configure voice-to-DSP output routing
; Entry: A = voice number, C = channel
; Notes: Calls DSP_AlgoType_Dispatch1 for algorithm type lookup
;        Stores result to DSP state at 0x04520E
;        Iterates voice output list via Voice_BuildOutputList
;        Configures tone generator params via ToneGen_ExtParams56b_DataTable
;        Two-pass: first updates 0x04520E, then 0x04520C
; ----------------------------------------------------------------------------
Voice_DSP_OutputConfig:
	.byte 0xbf, 0xf6, 0x37, 0xbf, 0x06, 0x43, 0xbf, 0x08
	.byte 0x41, 0x8f, 0x06, 0x3f, 0x00, 0x6e, 0x6e, 0x8f
	.byte 0x08, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x06
	.byte 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0xda, 0x88, 0x1d
	.byte 0xd2, 0x37, 0x03, 0xf2, 0x0e, 0x52, 0x04, 0x53
	.byte 0x8f, 0x08, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f
	.byte 0x06, 0x21, 0xd8, 0x12, 0xd8, 0xce, 0x0c, 0x00
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xda, 0x88, 0xda, 0xa8
	.byte 0x1d, 0x8e, 0x1a, 0x02, 0xb7, 0x63, 0xbf, 0x04
	.byte 0x02, 0x00, 0x00, 0x68, 0x19, 0x9f, 0x04, 0x20
	.byte 0xe8, 0x12, 0xe8, 0x80, 0xa7, 0x80, 0x90, 0x20
	.byte 0x20, 0x00, 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1d
	.byte 0xb3, 0xdb, 0x02, 0x9f, 0x04, 0x61, 0x9f, 0x04
	.byte 0x20, 0xe8, 0x12, 0xe8, 0x80, 0xa7, 0x80, 0x90
	.byte 0x20, 0xd8, 0xcc, 0xff, 0x00, 0xd8, 0xcf, 0x80
	.byte 0x00, 0x67, 0xd2, 0x68, 0x6c, 0x8f, 0x08, 0x21
	.byte 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x06, 0x21, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xda, 0x88, 0x1d, 0xd2, 0x37
	.byte 0x03, 0xf2, 0x0c, 0x52, 0x04, 0x53, 0x8f, 0x08
	.byte 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x06, 0x21
	.byte 0xd8, 0x12, 0xd8, 0xce, 0x0c, 0x00, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xda, 0x88, 0xda, 0xa8, 0x1d, 0x8e
	.byte 0x1a, 0x02, 0xb7, 0x63, 0xbf, 0x04, 0x02, 0x00
	.byte 0x00, 0x68, 0x19, 0x9f, 0x04, 0x20, 0xe8, 0x12
	.byte 0xe8, 0x80, 0xa7, 0x80, 0x90, 0x20, 0x20, 0x00
	.byte 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1d, 0x96, 0xda
	.byte 0x02, 0x9f, 0x04, 0x61, 0x9f, 0x04, 0x20, 0xe8
	.byte 0x12, 0xe8, 0x80, 0xa7, 0x80, 0x90, 0x20, 0xd8
	.byte 0xcc, 0xff, 0x00, 0xd8, 0xcf, 0x80, 0x00, 0x67
	.byte 0xd2, 0xbf, 0x0a, 0x37, 0x0e
; ----------------------------------------------------------------------------
; Voice_DSP_OutputConfig2 - Configure voice-to-DSP output routing (type 2)
; Entry: A = voice number, C = channel
; Notes: Same algorithm as Voice_DSP_OutputConfig with different table offsets
; ----------------------------------------------------------------------------
Voice_DSP_OutputConfig2:
	.byte 0xbf, 0xf6, 0x37, 0xbf, 0x06, 0x43, 0xbf, 0x08
	.byte 0x41, 0x8f, 0x06, 0x3f, 0x00, 0x6e, 0x6e, 0x8f
	.byte 0x08, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x06
	.byte 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0xda, 0x88, 0x1d
	.byte 0x9e, 0x39, 0x03, 0xf2, 0x0a, 0x52, 0x04, 0x53
	.byte 0x8f, 0x08, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f
	.byte 0x06, 0x21, 0xd8, 0x12, 0xd8, 0xce, 0x0c, 0x00
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xda, 0x88, 0xda, 0xa8
	.byte 0x1d, 0x8e, 0x1a, 0x02, 0xb7, 0x63, 0xbf, 0x04
	.byte 0x02, 0x00, 0x00, 0x68, 0x19, 0x9f, 0x04, 0x20
	.byte 0xe8, 0x12, 0xe8, 0x80, 0xa7, 0x80, 0x90, 0x20
	.byte 0x20, 0x00, 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1d
	.byte 0xd5, 0xdb, 0x02, 0x9f, 0x04, 0x61, 0x9f, 0x04
	.byte 0x20, 0xe8, 0x12, 0xe8, 0x80, 0xa7, 0x80, 0x90
	.byte 0x20, 0xd8, 0xcc, 0xff, 0x00, 0xd8, 0xcf, 0x80
	.byte 0x00, 0x67, 0xd2, 0x68, 0x6c, 0x8f, 0x08, 0x21
	.byte 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x06, 0x21, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xda, 0x88, 0x1d, 0x9e, 0x39
	.byte 0x03, 0xf2, 0x08, 0x52, 0x04, 0x53, 0x8f, 0x08
	.byte 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x06, 0x21
	.byte 0xd8, 0x12, 0xd8, 0xce, 0x0c, 0x00, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xda, 0x88, 0xda, 0xa8, 0x1d, 0x8e
	.byte 0x1a, 0x02, 0xb7, 0x63, 0xbf, 0x04, 0x02, 0x00
	.byte 0x00, 0x68, 0x19, 0x9f, 0x04, 0x20, 0xe8, 0x12
	.byte 0xe8, 0x80, 0xa7, 0x80, 0x90, 0x20, 0x20, 0x00
	.byte 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1d, 0xb8, 0xda
	.byte 0x02, 0x9f, 0x04, 0x61, 0x9f, 0x04, 0x20, 0xe8
	.byte 0x12, 0xe8, 0x80, 0xa7, 0x80, 0x90, 0x20, 0xd8
	.byte 0xcc, 0xff, 0x00, 0xd8, 0xcf, 0x80, 0x00, 0x67
	.byte 0xd2, 0xbf, 0x0a, 0x37, 0x0e
; ----------------------------------------------------------------------------
; Voice_DSP_SimpleCopy - Simple voice-to-DSP parameter copy
; Entry: A = voice number
; Notes: Calls DSP function at 0x033B8B, stores to 0x045204
;        Iterates voice output list (max 64 entries)
; ----------------------------------------------------------------------------
Voice_DSP_SimpleCopy:
	.byte 0xef, 0x68, 0xbf, 0x06, 0x41, 0x8f, 0x06, 0x21
	.byte 0xd8, 0x12, 0x1d, 0x8b, 0x3b, 0x03, 0xf2, 0x04
	.byte 0x52, 0x04, 0x53, 0x8f, 0x06, 0x21, 0xd8, 0x12
	.byte 0x31, 0x10, 0x00, 0xda, 0xa8, 0x1d, 0x8e, 0x1a
	.byte 0x02, 0xb7, 0x63, 0xbf, 0x04, 0x02, 0x00, 0x00
	.byte 0x68, 0x19, 0x9f, 0x04, 0x20, 0xe8, 0x12, 0xe8
	.byte 0x80, 0xa7, 0x80, 0x90, 0x20, 0x20, 0x00, 0xf2
	.byte 0xcc, 0x51, 0x04, 0x31, 0x1d, 0xd0, 0xdc, 0x02
	.byte 0x9f, 0x04, 0x61, 0x9f, 0x04, 0x20, 0xe8, 0x12
	.byte 0xe8, 0x80, 0xa7, 0x80, 0x90, 0x20, 0xd8, 0xcc
	.byte 0xff, 0x00, 0xd8, 0xcf, 0x40, 0x00, 0x67, 0xd2
	.byte 0xef, 0x60, 0x0e
; ----------------------------------------------------------------------------
; Voice_DSP_SimpleCopy2 - Simple voice-to-DSP parameter copy (type 2)
; Entry: A = voice number
; Notes: Same algorithm as Voice_DSP_SimpleCopy with different offsets
; ----------------------------------------------------------------------------
Voice_DSP_SimpleCopy2:
	.byte 0xef, 0x68, 0xbf, 0x06, 0x41, 0x8f, 0x06, 0x21
	.byte 0xd8, 0x12, 0x1d, 0x6b, 0x3c, 0x03, 0xf2, 0x06
	.byte 0x52, 0x04, 0x53, 0x8f, 0x06, 0x21, 0xd8, 0x12
	.byte 0x31, 0x10, 0x00, 0xda, 0xa8, 0x1d, 0x8e, 0x1a
	.byte 0x02, 0xb7, 0x63, 0xbf, 0x04, 0x02, 0x00, 0x00
	.byte 0x68, 0x19, 0x9f, 0x04, 0x20, 0xe8, 0x12, 0xe8
	.byte 0x80, 0xa7, 0x80, 0x90, 0x20, 0x20, 0x00, 0xf2
	.byte 0xcc, 0x51, 0x04, 0x31, 0x1d, 0xf2, 0xdc, 0x02
	.byte 0x9f, 0x04, 0x61, 0x9f, 0x04, 0x20, 0xe8, 0x12
	.byte 0xe8, 0x80, 0xa7, 0x80, 0x90, 0x20, 0xd8, 0xcc
	.byte 0xff, 0x00, 0xd8, 0xcf, 0x40, 0x00, 0x67, 0xd2
	.byte 0xef, 0x60, 0x0e

DSP_WriteVoiceParam_Long:
	push xiz
	ld xiz, xbc
	res_dd8 7, 0x18
	add wa, 0x400
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 14)
	stw_da 0x100002, xwa
	jr __jrt_nop_027F91
__jrt_nop_027F91:

DSP_WriteVoiceParam_Long_NopGap:
	nop
	nop
	nop
	pop xiz
	ret

DSP_WriteVoiceParam_Short:
	push xiz
	ld xiz, xbc
	res_dd8 7, 0x18
	add wa, 0x80
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 4)
	res 15, wa
	stw_da 0x100002, xwa
	jr __jrt_nop_027FB6
__jrt_nop_027FB6:

DSP_WriteVoiceParam_Short_NopGap:
	nop
	nop
	nop
	pop xiz
	ret

DSP_WriteVoiceParam_Direct:
	pushw iz
	ld iz, bc
	res_dd8 7, 0x18
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stw_da 0x100002, xiz
	jr __jrt_nop_027FD1
__jrt_nop_027FD1:

DSP_WriteVoiceParam_Direct_NopGap:
	nop
	nop
	nop
	popw iz
	ret

DSP_WriteVoiceParam_6Words:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 46)
	stw_da 0x100002, xwa
	jr __jrt_nop_027FFD
__jrt_nop_027FFD:

DSP_WriteVoiceParam_6Words_Word2:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x940
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 50)
	stw_da 0x100002, xwa
	jr __jrt_nop_02801F
__jrt_nop_02801F:

ToneGen_WriteNote6ch_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0xA00
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 54)
	stw_da 0x100002, xwa
	jr __jrt_nop_028041
__jrt_nop_028041:

ToneGen_WriteNote6ch_NopCont2:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 44)
	stw_da 0x100002, xwa
	jr __jrt_nop_028063
__jrt_nop_028063:

ToneGen_WriteNote6ch_NopCont3:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x900
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 48)
	stw_da 0x100002, xwa
	jr __jrt_nop_028085
__jrt_nop_028085:

ToneGen_WriteNote6ch_NopCont4:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x9C0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 52)
	stw_da 0x100002, xwa
	jr __jrt_nop_0280A7
__jrt_nop_0280A7:

ToneGen_WriteNote6ch_NopCont5:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

ToneGen_WriteNote2ch:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 46)
	stw_da 0x100002, xwa
	jr __jrt_nop_0280D5
__jrt_nop_0280D5:

ToneGen_WriteNote2ch_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 44)
	stw_da 0x100002, xwa
	jr __jrt_nop_0280F7
__jrt_nop_0280F7:

ToneGen_WriteNote2ch_NopCont2:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

VoiceCC_DataTable_0280FE:
	.byte 0x3e, 0xe9, 0x8e, 0xf0, 0x18, 0xb7, 0xd8, 0xc8
	.byte 0x40, 0x08, 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00
	.byte 0xf0, 0x18, 0xbf, 0x9e, 0x2e, 0x20, 0xf2, 0x02
	.byte 0x00, 0x10, 0x50, 0x68, 0x00, 0x00, 0x00, 0x00
	.byte 0x5e, 0x0e, 0xef, 0x6c, 0x2e, 0xbf, 0x02, 0x61
	.byte 0xd8, 0x8e, 0xf0, 0x18, 0xb7, 0xde, 0x88, 0xd8
	.byte 0xc8, 0x00, 0x01, 0xf2, 0x00, 0x00, 0x10, 0x50
	.byte 0x00, 0xf0, 0x18, 0xbf, 0xaf, 0x02, 0x20, 0x98
	.byte 0x08, 0x20, 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68
	.byte 0x00, 0x00, 0x00, 0x00, 0xf0, 0x18, 0xb7, 0xde
	.byte 0x88, 0xd8, 0xc8, 0x40, 0x01, 0xf2, 0x00, 0x00
	.byte 0x10, 0x50, 0x00, 0xf0, 0x18, 0xbf, 0xaf, 0x02
	.byte 0x20, 0x98, 0x0a, 0x20, 0xf2, 0x02, 0x00, 0x10
	.byte 0x50, 0x68, 0x00, 0x00, 0x00, 0x00, 0x4e, 0xef
	.byte 0x64, 0x0e, 0xef, 0x6c, 0x2e, 0xbf, 0x02, 0x61
	.byte 0xd8, 0x8e, 0xf0, 0x18, 0xb7, 0xde, 0x88, 0xd8
	.byte 0xc8, 0x40, 0x08, 0xf2, 0x00, 0x00, 0x10, 0x50
	.byte 0x00, 0xf0, 0x18, 0xbf, 0xaf, 0x02, 0x20, 0x98
	.byte 0x1a, 0x20, 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68
	.byte 0x00, 0x00, 0x00, 0x00, 0xf0, 0x18, 0xb7, 0xde
	.byte 0x88, 0xd8, 0xc8, 0x80, 0x08, 0xf2, 0x00, 0x00
	.byte 0x10, 0x50, 0x00, 0xf0, 0x18, 0xbf, 0xaf, 0x02
	.byte 0x20, 0x98, 0x1c, 0x20, 0xf2, 0x02, 0x00, 0x10
	.byte 0x50, 0x68, 0x00, 0x00, 0x00, 0x00, 0x4e, 0xef
	.byte 0x64, 0x0e, 0x3e, 0xe9, 0x8e, 0xf0, 0x18, 0xb7
	.byte 0xd8, 0xc8, 0x80, 0x01, 0xf2, 0x00, 0x00, 0x10
	.byte 0x50, 0x00, 0xf0, 0x18, 0xbf, 0x9e, 0x0c, 0x20
	.byte 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68, 0x00, 0x00
	.byte 0x00, 0x00, 0x5e, 0x0e, 0x3e, 0xe9, 0x8e, 0xf0
	.byte 0x18, 0xb7, 0xd8, 0xc8, 0x40, 0x04, 0xf2, 0x00
	.byte 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18, 0xbf, 0x9e
	.byte 0x10, 0x20, 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68
	.byte 0x00, 0x00, 0x00, 0x00, 0x5e, 0x0e, 0x3e, 0xe9
	.byte 0x8e, 0xf0, 0x18, 0xb7, 0xd8, 0xc8, 0xc0, 0x04
	.byte 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18
	.byte 0xbf, 0x9e, 0x14, 0x20, 0xf2, 0x02, 0x00, 0x10
	.byte 0x50, 0x68, 0x00, 0x00, 0x00, 0x00, 0x5e, 0x0e
	.byte 0x3e, 0xe9, 0x8e, 0xf0, 0x18, 0xb7, 0xd8, 0xc8
	.byte 0x00, 0x06, 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00
	.byte 0xf0, 0x18, 0xbf, 0x9e, 0x40, 0x20, 0xf2, 0x02
	.byte 0x00, 0x10, 0x50, 0x68, 0x00, 0x00, 0x00, 0x00
	.byte 0x5e, 0x0e, 0x3e, 0xe9, 0x8e, 0xf0, 0x18, 0xb7
	.byte 0xd8, 0xc8, 0x80, 0x05, 0xf2, 0x00, 0x00, 0x10
	.byte 0x50, 0x00, 0xf0, 0x18, 0xbf, 0x9e, 0x3c, 0x20
	.byte 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68, 0x00, 0x00
	.byte 0x00, 0x00, 0x5e, 0x0e, 0x3e, 0xe9, 0x8e, 0xf0
	.byte 0x18, 0xb7, 0xd8, 0xc8, 0xc0, 0x01, 0xf2, 0x00
	.byte 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18, 0xbf, 0x9e
	.byte 0x38, 0x20, 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68
	.byte 0x00, 0x00, 0x00, 0x00, 0x5e, 0x0e, 0x3e, 0xe9
	.byte 0x8e, 0xf0, 0x18, 0xb7, 0xd8, 0xc8, 0x40, 0x05
	.byte 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18
	.byte 0xbf, 0x9e, 0x3a, 0x20, 0xf2, 0x02, 0x00, 0x10
	.byte 0x50, 0x68, 0x00, 0x00, 0x00, 0x00, 0x5e, 0x0e
	.byte 0x3e, 0xe9, 0x8e, 0xd8, 0xcf, 0x40, 0x00, 0x6f
	.byte 0x1f, 0xf0, 0x18, 0xb7, 0xd8, 0xc8, 0xc0, 0x01
	.byte 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18
	.byte 0xbf, 0x9e, 0x38, 0x20, 0xf2, 0x02, 0x00, 0x10
	.byte 0x50, 0x68, 0x00, 0x00, 0x00, 0x00, 0x68, 0x1d
	.byte 0xf0, 0x18, 0xb7, 0xd8, 0xc8, 0x00, 0x06, 0xf2
	.byte 0x00, 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18, 0xbf
	.byte 0x9e, 0x42, 0x20, 0xf2, 0x02, 0x00, 0x10, 0x50
	.byte 0x68, 0x00, 0x00, 0x00, 0x00, 0x5e, 0x0e, 0x3e
	.byte 0xe9, 0x8e, 0xd8, 0xcf, 0x40, 0x00, 0x6f, 0x1f
	.byte 0xf0, 0x18, 0xb7, 0xd8, 0xc8, 0x40, 0x05, 0xf2
	.byte 0x00, 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18, 0xbf
	.byte 0x9e, 0x3a, 0x20, 0xf2, 0x02, 0x00, 0x10, 0x50
	.byte 0x68, 0x00, 0x00, 0x00, 0x00, 0x68, 0x1d, 0xf0
	.byte 0x18, 0xb7, 0xd8, 0xc8, 0x80, 0x05, 0xf2, 0x00
	.byte 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18, 0xbf, 0x9e
	.byte 0x3e, 0x20, 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68
	.byte 0x00, 0x00, 0x00, 0x00, 0x5e, 0x0e, 0x2e, 0x9f
	.byte 0x06, 0x24, 0x20, 0x00, 0xc8, 0xdc, 0x7f, 0xdb
	.byte 0x00, 0xc8, 0x8f, 0xdb, 0x12, 0xf2, 0xd7, 0xf6
	.byte 0x00, 0x35, 0xc3, 0x07, 0xf4, 0xec, 0x27, 0xcb
	.byte 0xc7, 0x76, 0x94, 0x00, 0xc8, 0x8f, 0xdb, 0x12
	.byte 0xf2, 0xdb, 0xf6, 0x00, 0x35, 0xc3, 0x07, 0xf4
	.byte 0xec, 0x27, 0xcb, 0xc7, 0x66, 0x2e, 0xc8, 0x8f
	.byte 0xdb, 0x12, 0xdb, 0x09, 0x25, 0x00, 0xdb, 0x8e
	.byte 0xde, 0xc8, 0x6e, 0x00, 0xc9, 0x8f, 0xdb, 0x12
	.byte 0xdb, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04
	.byte 0x35, 0xeb, 0x13, 0xed, 0x83, 0xf3, 0x07, 0xec
	.byte 0xf8, 0x33, 0xda, 0x8d, 0xdc, 0xe5, 0x9b, 0x18
	.byte 0xed, 0x78, 0x81, 0x00, 0xc8, 0x8f, 0xdb, 0x12
	.byte 0xdb, 0x09, 0x25, 0x00, 0xdb, 0x8e, 0xde, 0xc8
	.byte 0x6e, 0x00, 0xc9, 0x8f, 0xdb, 0x12, 0xdb, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04, 0x35, 0xeb
	.byte 0x13, 0xed, 0x83, 0xf3, 0x07, 0xec, 0xf8, 0x35
	.byte 0xdc, 0x8b, 0xdb, 0x06, 0x9d, 0x18, 0xcb, 0xc8
	.byte 0x8f, 0xdb, 0x12, 0xdb, 0x09, 0x25, 0x00, 0xdb
	.byte 0x8e, 0xde, 0xc8, 0x6e, 0x00, 0xc9, 0x8f, 0xdb
	.byte 0x12, 0xdb, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13
	.byte 0x04, 0x35, 0xeb, 0x13, 0xed, 0x83, 0xf3, 0x07
	.byte 0xec, 0xf8, 0x33, 0x9b, 0x18, 0xea, 0x68, 0x2d
	.byte 0xc8, 0x8f, 0xdb, 0x12, 0xdb, 0x09, 0x25, 0x00
	.byte 0xdb, 0x8e, 0xde, 0xc8, 0x6e, 0x00, 0xc9, 0x8f
	.byte 0xdb, 0x12, 0xdb, 0x09, 0x1f, 0x01, 0xf2, 0x68
	.byte 0x13, 0x04, 0x35, 0xeb, 0x13, 0xed, 0x83, 0xf3
	.byte 0x07, 0xec, 0xf8, 0x35, 0xda, 0x8b, 0xdc, 0xe3
	.byte 0xdb, 0x06, 0x9d, 0x18, 0xcb, 0xc8, 0x61, 0xc8
	.byte 0xdc, 0x77, 0x25, 0xff, 0x4e, 0x0f, 0x02, 0x00
	.byte 0xba, 0x01, 0xcf, 0x66, 0x19, 0x8a, 0x02, 0x25
	.byte 0xcd, 0x8f, 0xdb, 0x12, 0xd9, 0x12, 0xd9, 0xca
	.byte 0x40, 0x00, 0xd9, 0x8a, 0xda, 0x82, 0xda, 0x89
	.byte 0xdb, 0x41, 0xd9, 0x8a, 0x68, 0x11, 0x8a, 0x02
	.byte 0x25, 0xcd, 0x8f, 0xdb, 0x12, 0xcb, 0x8d, 0xda
	.byte 0x12, 0xda, 0x89, 0xdb, 0x41, 0xd9, 0x8a, 0xda
	.byte 0xef, 0x06, 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01
	.byte 0xf2, 0x84, 0x13, 0x04, 0x31, 0xf3, 0x07, 0xe4
	.byte 0xe0, 0x45, 0x0e, 0xba, 0x01, 0xcf, 0x66, 0x19
	.byte 0x8a, 0x02, 0x25, 0xcd, 0x8f, 0xdb, 0x12, 0xd9
	.byte 0x12, 0xd9, 0xca, 0x40, 0x00, 0xd9, 0x8a, 0xda
	.byte 0x82, 0xda, 0x89, 0xdb, 0x41, 0xd9, 0x8a, 0x68
	.byte 0x11, 0x8a, 0x02, 0x25, 0xcd, 0x8f, 0xdb, 0x12
	.byte 0xcb, 0x8d, 0xda, 0x12, 0xda, 0x89, 0xdb, 0x41
	.byte 0xd9, 0x8a, 0xda, 0xef, 0x06, 0xd8, 0x12, 0xd8
	.byte 0x09, 0x1f, 0x01, 0xf2, 0x83, 0x13, 0x04, 0x31
	.byte 0xf3, 0x07, 0xe4, 0xe0, 0x45, 0x0e, 0xef, 0x6a
	.byte 0xb7, 0x41, 0xba, 0x01, 0xcf, 0x66, 0x0c, 0xd9
	.byte 0x8b, 0xeb, 0x13, 0xeb, 0xca, 0x00, 0x20, 0x00
	.byte 0x00, 0x68, 0x07, 0xd9, 0x8b, 0xeb, 0x13, 0xeb
	.byte 0xed, 0x01, 0x8a, 0x02, 0x21, 0xe9, 0xa8, 0xc9
	.byte 0x8b, 0xeb, 0x88, 0x1d, 0xca, 0xd8, 0x03, 0xeb
	.byte 0xed, 0x06, 0x87, 0x21, 0xd8, 0x12, 0xd8, 0xca
	.byte 0x10, 0x00, 0xd8, 0xd8, 0x61, 0x27, 0xd8, 0xcf
	.byte 0x09, 0x00, 0x6a, 0x21, 0xd8, 0x80, 0xf2, 0xdf
	.byte 0xf6, 0x00, 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20
	.byte 0xf2, 0x00, 0x85, 0x02, 0x34, 0xf3, 0x07, 0xf0
	.byte 0xe0, 0xd8, 0xeb, 0x88, 0xeb, 0x83, 0xe8, 0x83
	.byte 0xeb, 0xec, 0x02, 0x68, 0x1c, 0x87, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x7b, 0x13
	.byte 0x04, 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x21, 0xe9
	.byte 0xa8, 0xc9, 0x8b, 0xeb, 0x88, 0x1d, 0xca, 0xd8
	.byte 0x03, 0xeb, 0xec, 0x09, 0xeb, 0xcf, 0x00, 0x00
	.byte 0x00, 0x00, 0x62, 0x0d, 0xeb, 0x88, 0x41, 0x00
	.byte 0x40, 0x00, 0x00, 0x1d, 0x5f, 0xdc, 0x03, 0x68
	.byte 0x0b, 0xeb, 0x88, 0x41, 0xff, 0x3f, 0x00, 0x00
	.byte 0x1d, 0x5f, 0xdc, 0x03, 0x87, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x85, 0x13, 0x04
	.byte 0x31, 0xf3, 0x07, 0xe4, 0xe0, 0x53, 0xef, 0x62
	.byte 0x0e, 0xba, 0x01, 0xcf, 0x66, 0x19, 0x8a, 0x02
	.byte 0x25, 0xcd, 0x8f, 0xdb, 0x12, 0xd9, 0x12, 0xd9
	.byte 0xca, 0x40, 0x00, 0xd9, 0x8a, 0xda, 0x82, 0xda
	.byte 0x89, 0xdb, 0x49, 0xd9, 0x8a, 0x68, 0x11, 0x8a
	.byte 0x02, 0x25, 0xcd, 0x8f, 0xdb, 0x12, 0xcb, 0x8d
	.byte 0xda, 0x12, 0xda, 0x89, 0xdb, 0x49, 0xd9, 0x8a
	.byte 0xda, 0xed, 0x01, 0xda, 0x89, 0xe9, 0x13, 0xd9
	.byte 0x0b, 0x7f, 0x00, 0xd9, 0x8a, 0xd8, 0x12, 0xd8
	.byte 0x09, 0x1f, 0x01, 0xf2, 0x87, 0x13, 0x04, 0x31
	.byte 0xf3, 0x07, 0xe4, 0xe0, 0x45, 0x0e, 0xba, 0x01
	.byte 0xcf, 0x66, 0x19, 0x8a, 0x02, 0x25, 0xcd, 0x8f
	.byte 0xdb, 0x12, 0xd9, 0x12, 0xd9, 0xca, 0x40, 0x00
	.byte 0xd9, 0x8a, 0xda, 0x82, 0xda, 0x89, 0xdb, 0x49
	.byte 0xd9, 0x8a, 0x68, 0x11, 0x8a, 0x02, 0x25, 0xcd
	.byte 0x8f, 0xdb, 0x12, 0xcb, 0x8d, 0xda, 0x12, 0xda
	.byte 0x89, 0xdb, 0x49, 0xd9, 0x8a, 0xda, 0x89, 0xe9
	.byte 0x13, 0xd9, 0x0b, 0x7f, 0x00, 0xd9, 0x8a, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x88, 0x13
	.byte 0x04, 0x31, 0xf3, 0x07, 0xe4, 0xe0, 0x45, 0x0e
	.byte 0x2e, 0xea, 0x8c, 0x8f, 0x06, 0x27, 0x8f, 0x08
	.byte 0x20, 0xbc, 0x01, 0xcf, 0x66, 0x10, 0xcb, 0xcf
	.byte 0x40, 0x63, 0x09, 0xcb, 0xca, 0x40, 0xcb, 0x8d
	.byte 0xcd, 0x83, 0x68, 0x02, 0x23, 0x00, 0xcb, 0xd8
	.byte 0x66, 0x79, 0xc8, 0x8d, 0xda, 0x12, 0xda, 0x8d
	.byte 0xdd, 0xec, 0x02, 0xcf, 0x8d, 0xda, 0x12, 0xda
	.byte 0xec, 0x04, 0xda, 0x8e, 0xdd, 0x86, 0xc9, 0x8d
	.byte 0xda, 0x12, 0xda, 0x09, 0x1f, 0x01, 0xf2, 0x68
	.byte 0x13, 0x04, 0x35, 0xea, 0x13, 0xed, 0x82, 0xf3
	.byte 0x07, 0xe8, 0xf8, 0x32, 0x8a, 0x28, 0x25, 0xcd
	.byte 0xcc, 0x55, 0xcd, 0x8e, 0x84, 0x25, 0xcd, 0xcc
	.byte 0x55, 0xcd, 0x8a, 0xce, 0x8d, 0xca, 0xe5, 0xcd
	.byte 0x8e, 0x84, 0x25, 0xcd, 0xcc, 0xaa, 0xcd, 0x8a
	.byte 0xc8, 0x8d, 0xda, 0x12, 0xda, 0x8d, 0xdd, 0xec
	.byte 0x02, 0xcf, 0x8d, 0xda, 0x12, 0xda, 0xec, 0x04
	.byte 0xda, 0x8e, 0xdd, 0x86, 0xc9, 0x8d, 0xda, 0x12
	.byte 0xda, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04
	.byte 0x35, 0xea, 0x13, 0xed, 0x82, 0xf3, 0x07, 0xe8
	.byte 0xf8, 0x35, 0xce, 0x8d, 0xca, 0xe5, 0xbd, 0x28
	.byte 0x45, 0x68, 0x2e, 0xc8, 0x8d, 0xda, 0x12, 0xda
	.byte 0x8d, 0xdd, 0xec, 0x02, 0xcf, 0x8d, 0xda, 0x12
	.byte 0xda, 0xec, 0x04, 0xda, 0x8e, 0xdd, 0x86, 0xc9
	.byte 0x8d, 0xda, 0x12, 0xda, 0x09, 0x1f, 0x01, 0xf2
	.byte 0x68, 0x13, 0x04, 0x35, 0xea, 0x13, 0xed, 0x82
	.byte 0xf3, 0x07, 0xe8, 0xf8, 0x32, 0xba, 0x28, 0x00
	.byte 0x00, 0xc7, 0xf4, 0x9b, 0xdd, 0x12, 0x8c, 0x02
	.byte 0x25, 0xc7, 0xf0, 0x9d, 0xdc, 0x12, 0xdd, 0x8a
	.byte 0xdc, 0x42, 0xda, 0x8d, 0xdd, 0xef, 0x06, 0x6e
	.byte 0x06, 0xcb, 0xd8, 0x66, 0x02, 0xdd, 0xa9, 0xc8
	.byte 0x8b, 0xd9, 0x12, 0xd9, 0x8a, 0xda, 0xec, 0x02
	.byte 0xcf, 0x8b, 0xd9, 0x12, 0xd9, 0xec, 0x04, 0xd9
	.byte 0x8b, 0xda, 0x83, 0xd8, 0x12, 0xd8, 0x09, 0x1f
	.byte 0x01, 0xf2, 0x68, 0x13, 0x04, 0x31, 0xe8, 0x13
	.byte 0xe9, 0x80, 0xf3, 0x07, 0xe0, 0xec, 0x31, 0xc7
	.byte 0xf4, 0x89, 0xb9, 0x2a, 0x41, 0x4e, 0x0f, 0x04
	.byte 0x00, 0x2e, 0xea, 0x8c, 0x8f, 0x06, 0x27, 0x8f
	.byte 0x08, 0x20, 0xbc, 0x01, 0xcf, 0x66, 0x10, 0xcb
	.byte 0xcf, 0x40, 0x63, 0x09, 0xcb, 0xca, 0x40, 0xcb
	.byte 0x8d, 0xcd, 0x83, 0x68, 0x02, 0x23, 0x00, 0xcb
	.byte 0xd8, 0x66, 0x79, 0xc8, 0x8d, 0xda, 0x12, 0xda
	.byte 0x8d, 0xdd, 0xec, 0x02, 0xcf, 0x8d, 0xda, 0x12
	.byte 0xda, 0xec, 0x04, 0xda, 0x8e, 0xdd, 0x86, 0xc9
	.byte 0x8d, 0xda, 0x12, 0xda, 0x09, 0x1f, 0x01, 0xf2
	.byte 0x68, 0x13, 0x04, 0x35, 0xea, 0x13, 0xed, 0x82
	.byte 0xf3, 0x07, 0xe8, 0xf8, 0x32, 0x8a, 0x28, 0x25
	.byte 0xcd, 0xcc, 0x55, 0xcd, 0x8e, 0x84, 0x25, 0xcd
	.byte 0xcc, 0x55, 0xcd, 0x8a, 0xce, 0x8d, 0xca, 0xe5
	.byte 0xcd, 0x8e, 0x84, 0x25, 0xcd, 0xcc, 0xaa, 0xcd
	.byte 0x8a, 0xc8, 0x8d, 0xda, 0x12, 0xda, 0x8d, 0xdd
	.byte 0xec, 0x02, 0xcf, 0x8d, 0xda, 0x12, 0xda, 0xec
	.byte 0x04, 0xda, 0x8e, 0xdd, 0x86, 0xc9, 0x8d, 0xda
	.byte 0x12, 0xda, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13
	.byte 0x04, 0x35, 0xea, 0x13, 0xed, 0x82, 0xf3, 0x07
	.byte 0xe8, 0xf8, 0x35, 0xce, 0x8d, 0xca, 0xe5, 0xbd
	.ascii "(Eh."
	.byte 0xc8, 0x8d, 0xda, 0x12
	.byte 0xda, 0x8d, 0xdd, 0xec, 0x02, 0xcf, 0x8d, 0xda
	.byte 0x12, 0xda, 0xec, 0x04, 0xda, 0x8e, 0xdd, 0x86
	.byte 0xc9, 0x8d, 0xda, 0x12, 0xda, 0x09, 0x1f, 0x01
	.byte 0xf2, 0x68, 0x13, 0x04, 0x35, 0xea, 0x13, 0xed
	.byte 0x82, 0xf3, 0x07, 0xe8, 0xf8, 0x32, 0xba, 0x28
	.byte 0x00, 0x00, 0xc7, 0xf4, 0x9b, 0xdd, 0x12, 0x8c
	.byte 0x02, 0x25, 0xc7, 0xf0, 0x9d, 0xdc, 0x12, 0xdd
	.byte 0x8a, 0xdc, 0x42, 0xda, 0x8d, 0xdd, 0xef, 0x06
	.byte 0x6e, 0x06, 0xcb, 0xd8, 0x66, 0x02, 0xdd, 0xa9
	.byte 0xc8, 0x8b, 0xd9, 0x12, 0xd9, 0x8a, 0xda, 0xec
	.byte 0x02, 0xcf, 0x8b, 0xd9, 0x12, 0xd9, 0xec, 0x04
	.byte 0xd9, 0x8b, 0xda, 0x83, 0xd8, 0x12, 0xd8, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04, 0x31, 0xe8
	.byte 0x13, 0xe9, 0x80, 0xf3, 0x07, 0xe0, 0xec, 0x31
	.byte 0xc7, 0xf4, 0x89, 0xb9, 0x29, 0x41, 0x4e, 0x0f
	.byte 0x04, 0x00, 0xda, 0xf0, 0x69, 0x04, 0xda, 0x88
	.byte 0x68, 0x06, 0xd9, 0xf0, 0x62, 0x02, 0xd9, 0x88
	.byte 0xd8, 0x8b, 0x0e

; Voice_CC_SetVolume -- CC 0x07: Store volume via lookup table
; Uses non-linear lookup table at ROM 0x011D16. Mute value: 0xFE00.
Voice_CC_SetVolume:
	cps c, 0
	jr z, VoiceCC_SetVolume_Mute
	ldw_da xde, 0x041343
	bit 0, de
	jr z, VoiceCC_SetVolume_Bit1Set
	extz wa
	muls wa, 0x11F
	ld de, wa
	lda_24 xhl, 0x041374
	ld a, c
	extz wa
	add wa, wa
	lda_24 xbc, 0x011d16
	ldw_sri WA, 0x07, 0xE4, 0xE0
	stw_dri WA, 0x07, 0xEC, 0xE8
	ret

VoiceCC_SetVolume_Bit1Set:
	ldw_da xde, 0x041343
	bit 1, de
	jr z, VoiceCC_SetVolume_RawSub
	extz wa
	muls wa, 0x11F
	ld de, wa
	lda_24 xhl, 0x041374
	ld a, c
	extz wa
	add wa, wa
	lda_24 xbc, 0x011d16
	ldw_sri WA, 0x07, 0xE4, 0xE0
	stw_dri WA, 0x07, 0xEC, 0xE8
	ret

VoiceCC_SetVolume_RawSub:
	extz wa
	muls wa, 0x11F
	ld de, wa
	lda_24 xhl, 0x041374
	ld a, c
	extz wa
	sub wa, 0x7F
	stw_dri WA, 0x07, 0xEC, 0xE8
	ret

VoiceCC_SetVolume_Mute:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041374
	stiw_ind 0x07, 0xE4, 0xE0, 0x00, 0xFE
	ret

; Voice_CC_SetPan -- CC 0x0A: Store pan value at voice + 0x0E
Voice_CC_SetPan:
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x041376
	lda_dri XHL, 0x07, 0xE8, 0xE0
	ret

; Voice_CC_SetExpression -- CC 0x0B: Store expression via lookup table
; Uses same lookup table as Volume (0x011D16). Mute value: 0xFE00.
Voice_CC_SetExpression:
	cps c, 0
	jr z, VoiceCC_SetExpression_Mute
	ldw_da xde, 0x041343
	bit 0, de
	jr z, VoiceCC_SetExpression_Bit1Set
	extz wa
	muls wa, 0x11F
	ld de, wa
	lda_24 xhl, 0x041378
	ld a, c
	extz wa
	add wa, wa
	lda_24 xbc, 0x011d16
	ldw_sri WA, 0x07, 0xE4, 0xE0
	stw_dri WA, 0x07, 0xEC, 0xE8
	ret

VoiceCC_SetExpression_Bit1Set:
	ldw_da xde, 0x041343
	bit 1, de
	jr z, VoiceCC_SetExpression_RawSub
	extz wa
	muls wa, 0x11F
	ld de, wa
	lda_24 xhl, 0x041378
	ld a, c
	extz wa
	add wa, wa
	lda_24 xbc, 0x011d16
	ldw_sri WA, 0x07, 0xE4, 0xE0
	stw_dri WA, 0x07, 0xEC, 0xE8
	ret

VoiceCC_SetExpression_RawSub:
	extz wa
	muls wa, 0x11F
	ld de, wa
	lda_24 xhl, 0x041378
	ld a, c
	extz wa
	sub wa, 0x7F
	stw_dri WA, 0x07, 0xEC, 0xE8
	ret

VoiceCC_SetExpression_Mute:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041378
	stiw_ind 0x07, 0xE4, 0xE0, 0x00, 0xFE
	ret

; Voice_CC_SetSustain -- CC 0x40: Set/clear sustain bit 0 at voice+0x0A
Voice_CC_SetSustain:
	cps c, 0
	jr z, VoiceCC_SetSustain_ClearBit
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	or_sriw_im 0x07, 0xE4, 0xE0, 0x01, 0x00
	ret

VoiceCC_SetSustain_ClearBit:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	and_sriw_im 0x07, 0xE4, 0xE0, 0xFE, 0xFF
	ret

Voice_CC_SetSostenuto:
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x041377
	lda_dri XHL, 0x07, 0xE8, 0xE0
	ret

Voice_CC_SetSoftPedal:
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x04137a
	lda_dri XHL, 0x07, 0xE8, 0xE0
	ret

Voice_CC_SetSostenutoFlag:
	cps c, 0
	jr z, VoiceCC_SetSostenuto_ClearFlag
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	or_sriw_im 0x07, 0xE4, 0xE0, 0x00, 0x40
	ret

VoiceCC_SetSostenuto_ClearFlag:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	and_sriw_im 0x07, 0xE4, 0xE0, 0xFF, 0xBF
	ret

Voice_CC_SetPortamentoRate:
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x04137b
	lda_dri XHL, 0x07, 0xE8, 0xE0
	ret

Voice_CC_SetPortamentoDepth:
	ld e, c
	extz de
	sub de, 0x80
	add de, de
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04137c
	stw_dri DE, 0x07, 0xE4, 0xE0
	ret

Voice_CC_SetPortamentoTime:
	ld e, c
	sub e, 0x40
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04137e
	lda_dri XIY, 0x07, 0xE4, 0xE0
	ret

Voice_CC_SetModWheelRange:
	.byte 0xcb, 0xd8, 0x66, 0x13, 0xd8, 0x12, 0xd8, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x72, 0x13, 0x04, 0x31, 0xd3
	.byte 0x07, 0xe4, 0xe0, 0x3e, 0x02, 0x00, 0x0e, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x72, 0x13
	.byte 0x04, 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x3c, 0xfd
	.byte 0xff, 0x0e

; Voice_CC_SetReverbDepth -- CC 0x91: Store reverb depth
; Stores value at voice + 0x7F (base 0x04137F). Range 0x00-0x7F.
Voice_CC_SetReverbDepth:
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x04137f
	lda_dri XHL, 0x07, 0xE8, 0xE0
	ret

; Voice_CC_SetChorusEnable -- CC 0x95: Set/clear chorus bit 2 at voice+0x0A
Voice_CC_SetChorusEnable:
	cps c, 0
	jr z, VoiceCC_SetChorus_ClearBit
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	or_sriw_im 0x07, 0xE4, 0xE0, 0x04, 0x00
	ret

VoiceCC_SetChorus_ClearBit:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	and_sriw_im 0x07, 0xE4, 0xE0, 0xFB, 0xFF
	ret

; Voice_CC_SetChorusDepth -- CC 0x97: Store chorus depth at voice+0x18
Voice_CC_SetChorusDepth:
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x041380
	lda_dri XHL, 0x07, 0xE8, 0xE0
	ret

; Voice_CC_SetDelayDepth -- CC 0x9B: Store delay depth at voice+0x25
Voice_CC_SetDelayDepth:
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x04138d
	lda_dri XHL, 0x07, 0xE8, 0xE0
	ret

; Voice_CC_SetDelayEnable -- CC 0x9C: Set/clear delay bit 8 at voice+0x02
Voice_CC_SetDelayEnable:
	cps c, 0
	jr z, VoiceCC_SetDelay_ClearBit
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	or_sriw_im 0x07, 0xE4, 0xE0, 0x00, 0x01
	ret

VoiceCC_SetDelay_ClearBit:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	and_sriw_im 0x07, 0xE4, 0xE0, 0xFF, 0xFE
	ret

; Voice_CC_SetDelayFeedback -- CC 0x9D: Store delay feedback at voice+0x26
Voice_CC_SetDelayFeedback:
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x04138e
	lda_dri XHL, 0x07, 0xE8, 0xE0
	ret

Voice_SetPolyphonyMode:
	pushw_erp 0xFA
	cps a, 1
	jr nz, Voice_SetPolyphonyMode_Else
	ordi16_24 267075, 1
	lds wa, 1
	call ToneGen_EmitCommandLoop
	jr Voice_SetPolyphonyMode_Apply

Voice_SetPolyphonyMode_Else:
	anddi16_24 267075, 65534
	lds wa, 0
	call ToneGen_EmitCommandLoop

Voice_SetPolyphonyMode_Apply:
	call VoiceSlot_ClearAll
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0x0F
	jr ugt, Voice_SetPolyphonyMode_LoopExit

Voice_SetPolyphonyMode_LoopBody:
	stb_erp A, 0xFB
	extz wa
	calr Voice_PerVoice_PortamentoPitchUpdate
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0x0F
	jr ule, Voice_SetPolyphonyMode_LoopBody

Voice_SetPolyphonyMode_LoopExit:
	popw_erp 0xFA
	ret

VoiceCC_Stub_Ret1:
	ret

VoiceCC_Stub_Ret2:
	ret

Voice_SetMasterTune:
	sub a, 0x40
	add a, a
	exts wa
	stw_da 0x041347, xwa
	ret

Voice_SetPitchBendRange:
	exts wa
	sla wa, 8
	stw_da 0x041349, xwa
	ret

Voice_SetKeyShiftEnable:
	cps a, 0
	jr z, Voice_SetKeyShiftRange
	ldw_da xwa, 0x041343
	bit 12, wa
	ret nz
	ordi16_24 267075, 2048
	stiw_da 0x04135c, 0x0000
	ret

Voice_SetKeyShiftRange:
	ldw_da xwa, 0x041343
	bit 12, wa
	ret z
	ldw_da xwa, 0x041343
	extz xwa
	and xwa, 0xFFFF2FFF
	set 13, wa
	cpw_da 267100, 20
	jr ule, Voice_SetKeyShiftRange_BranchA
	set 15, wa
	jr Voice_SetKeyShiftRange_BranchB

Voice_SetKeyShiftRange_BranchA:
	set 14, wa

Voice_SetKeyShiftRange_BranchB:
	stw_da 0x041343, xwa
	stiw_da 0x04135c, 0x0000
	ret

Voice_SetParam_04134D:
	stb_da 0x04134d, a
	ret

Voice_GetParam_04134D:
	ldb_da l, 0x04134d
	ret

Voice_SetRhythmMode:
	bit 3, a
	jr z, Voice_SetRhythmMode_BranchA
	stib_da 0x04135e, 0x03
	jr Voice_SetRhythmMode_BranchB

Voice_SetRhythmMode_BranchA:
	stib_da 0x04135e, 0x01

Voice_SetRhythmMode_BranchB:
	stib_da 0x04135f, 0x01
	ld c, a
	and c, 0xF0
	srl c, 4
	extz bc
	add bc, bc
	lda_24 xde, 0x00f6f3
	ldw_sri BC, 0x07, 0xE8, 0xE4
	stw_da 0x041360, xbc
	bit 2, a
	jr z, Voice_SetRhythmMode_BranchC
	stiw_da 0x041362, 0x8000
	jr Voice_SetRhythmMode_BranchD

Voice_SetRhythmMode_BranchC:
	stiw_da 0x041362, 0xa000

Voice_SetRhythmMode_BranchD:
	and a, 0x3
	sll a, 3
	ld c, a
	ldb a, 0xC8
	sub a, c
	extz wa
	stw_da 0x041364, xwa
	ret

Voice_SetParam_04134B:
	stb_da 0x04134b, a
	ret

Voice_SetCCMaxFlag:
	cp a, 0x7F
	jr nz, Voice_SetCCMaxFlag_Clear
	ordi16_24 267075, 2
	ret

Voice_SetCCMaxFlag_Clear:
	anddi16_24 267075, 65533
	ret

Voice_WriteChannelAssign:
	extz wa
	add wa, 0xC
	lda_24 xde, 0x041342
	sub c, 0x80
	lda_dri XHL, 0x07, 0xE8, 0xE0
	ret

Voice_ReadChannelAssign:
	extz wa
	add wa, 0xC
	lda_24 xbc, 0x041342
	ldb_sri L, 0x07, 0xE4, 0xE0
	ret

Voice_AllVoices_UpdateVelocity:
	dec 2, xsp
	push xiz
	and a, 0xF
	stb_da 0x04134c, a
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x1A
	jrl nc, Voice_AllVoices_UpdateVelocity_Exit

Voice_AllVoices_UpdateVelocity_LoopStart:
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	ldw_sri WA, 0x07, 0xE4, 0xE0
	bit 1, wa
	jrl z, Voice_AllVoices_UpdateVelocity_InnerStep
	ld a, (xsp + 4)
	extz wa
	call Voice_AllocateForFull
	lda xwa, (xhl + 5)
	ld xiz, xwa
	cp (xiz), 0x40
	jrl nc, Voice_AllVoices_UpdateVelocity_InnerStep

Voice_AllVoices_UpdateVelocity_InnerLoop:
	ld a, (xiz)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x043092
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld (xsp + 4), a
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0x80
	jr z, Voice_AllVoices_UpdateVelocity_TypeB
	cp a, 0xC0
	jr z, Voice_AllVoices_UpdateVelocity_TypeA
	cp a, 0x40
	jr z, Voice_AllVoices_UpdateVelocity_TypeA
	cps a, 0
	jr nz, Voice_AllVoices_UpdateVelocity_NextOuter

Voice_AllVoices_UpdateVelocity_TypeA:
	ld a, (xiz)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	exts xwa
	add xwa, xbc
	call Voice_ComputeExprPitchBend
	ld a, (xiz)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	exts xwa
	add xwa, xbc
	call Voice_SetPitchWord_Muted
	jr Voice_AllVoices_UpdateVelocity_NextOuter

Voice_AllVoices_UpdateVelocity_TypeB:
	ld a, (xiz)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	exts xwa
	add xwa, xbc
	call Voice_ComputePitchBend2
	ld a, (xiz)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	exts xwa
	add xwa, xbc
	call Voice_SetPitchWord_Unmuted

Voice_AllVoices_UpdateVelocity_NextOuter:
	ld a, (xiz)
	extz wa
	call ToneGen_ReadPitch_AndScale
	inc 1, xiz
	cp (xiz), 0x40
	jrl c, Voice_AllVoices_UpdateVelocity_InnerLoop

Voice_AllVoices_UpdateVelocity_InnerStep:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x1A
	jrl c, Voice_AllVoices_UpdateVelocity_LoopStart

Voice_AllVoices_UpdateVelocity_Exit:
	pop xiz
	inc 2, xsp
	ret

Voice_SetMonoMode:
	cps a, 0
	jr nz, Voice_SetMonoMode_Clear
	ordi16_24 267075, 512
	ret

Voice_SetMonoMode_Clear:
	anddi16_24 267075, 65023
	ret

Voice_GetMonoMode:
	ldw_da xhl, 0x041343
	and hl, 0x200
	ret

Voice_AllVoices_WritePan:
	dec 4, xsp
	push xiz
	lda_24 xbc, 0x04308e
	ld (xsp + 4), xbc
	inc 5, xwa
	ld xiz, xwa
	cp (xiz), 0x40
	jr nc, Voice_AllVoices_WritePan_Exit

Voice_AllVoices_WritePan_LoopBody:
	ld a, (xiz)
	extz wa
	muls wa, 0x47
	ld bc, wa
	ld xwa, (xsp + 4)
	exts xbc
	add xbc, xwa
	ld wa, (xbc + 1)
	and wa, 0x3C
	cp wa, 0x10
	jr z, Voice_AllVoices_WritePan_BranchB
	cp wa, 0x20
	jr z, Voice_AllVoices_WritePan_BranchA
	cp wa, 0x8
	jr z, Voice_AllVoices_WritePan_BranchA
	cps wa, 4
	jr nz, Voice_AllVoices_WritePan_LoopStep

Voice_AllVoices_WritePan_BranchA:
	ld xwa, xbc
	call Voice_Pitch_WriteOutputReg_Legato
	ld a, (xiz)
	extz wa
	lda_24 xbc, 0x0451cc
	calr DSP_WriteVoiceParam_Long
	jr Voice_AllVoices_WritePan_LoopStep

Voice_AllVoices_WritePan_BranchB:
	ld xwa, xbc
	call Voice_Pitch_WriteOutputReg_Secondary
	ld a, (xiz)
	extz wa
	lda_24 xbc, 0x0451cc
	calr DSP_WriteVoiceParam_Long

Voice_AllVoices_WritePan_LoopStep:
	inc 1, xiz
	cp (xiz), 0x40
	jr c, Voice_AllVoices_WritePan_LoopBody

Voice_AllVoices_WritePan_Exit:
	pop xiz
	inc 4, xsp
	ret

Voice_AllVoices_WriteAmplitude:
	dec 4, xsp
	push xiz
	lda_24 xbc, 0x04308e
	ld (xsp + 4), xbc
	inc 5, xwa
	ld xiz, xwa
	cp (xiz), 0x40
	jr nc, Voice_AllVoices_WriteAmplitude_Exit

Voice_AllVoices_WriteAmplitude_LoopBody:
	ld a, (xiz)
	extz wa
	muls wa, 0x47
	ld bc, wa
	ld xwa, (xsp + 4)
	exts xbc
	add xbc, xwa
	ld wa, (xbc + 1)
	and wa, 0x3C
	cp wa, 0x10
	jr z, Voice_AllVoices_WriteAmplitude_BranchB
	cp wa, 0x20
	jr z, Voice_AllVoices_WriteAmplitude_BranchA
	cp wa, 0x8
	jr z, Voice_AllVoices_WriteAmplitude_BranchA
	cps wa, 4
	jr nz, Voice_AllVoices_WriteAmplitude_LoopStep

Voice_AllVoices_WriteAmplitude_BranchA:
	ld xwa, xbc
	call Voice_ApplyPortamento
	jr Voice_AllVoices_WriteAmplitude_LoopStep

Voice_AllVoices_WriteAmplitude_BranchB:
	ld xwa, xbc
	call Voice_ApplyPortamento2

Voice_AllVoices_WriteAmplitude_LoopStep:
	ld a, (xiz)
	extz wa
	lda_24 xbc, 0x0451cc
	calr DSP_WriteVoiceParam_Short
	inc 1, xiz
	cp (xiz), 0x40
	jr c, Voice_AllVoices_WriteAmplitude_LoopBody

Voice_AllVoices_WriteAmplitude_Exit:
	pop xiz
	inc 4, xsp
	ret

Voice_AllNotes_SustainRetrigger:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 12), c
	lda_24 xbc, 0x04308e
	ld (xsp + 4), xbc
	inc 5, xwa
	ld (xsp + 8), xwa
	cp (xwa), 0x40
	jrl nc, Voice_AllNotes_SustainRetrigger_Exit

Voice_AllNotes_SustainRetrigger_LoopBody:
	ld xwa, (xsp + 8)
	ld a, (xwa)
	extz wa
	muls wa, 0x47
	ld bc, wa
	ld xwa, (xsp + 4)
	stb_dri H, 0x07, 0xE0, 0xE4
	ld wa, (xiz + 1)
	and wa, 0x3C
	cp wa, 0x10
	jrl z, Voice_AllNotes_SustainRetrigger_BranchF
	cp wa, 0x20
	jr z, Voice_AllNotes_SustainRetrigger_BranchA
	cp wa, 0x8
	jr z, Voice_AllNotes_SustainRetrigger_BranchA
	cps wa, 4
	jrl nz, Voice_AllNotes_SustainRetrigger_LoopStep

Voice_AllNotes_SustainRetrigger_BranchA:
	ld wa, (xiz + 1)
	extz xwa
	bit 15, wa
	jr nz, Voice_AllNotes_SustainRetrigger_BranchB
	ld xwa, (xiz + 35)
	ld wa, (xwa + 10)
	bit 0, wa
	jr nz, Voice_AllNotes_SustainRetrigger_BranchD

Voice_AllNotes_SustainRetrigger_BranchB:
	ld wa, (xiz + 1)
	bit 8, wa
	jr z, Voice_AllNotes_SustainRetrigger_BranchC
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume1
	ld xwa, (xsp + 8)
	ld a, (xwa)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteNote_Hold
	ld xwa, (xsp + 8)
	ld a, (xwa)
	extz wa
	ld bc, (xiz + 45)
	calr DSP_WriteVoiceParam_Direct
	ld xwa, (xsp + 8)
	ld a, (xwa)
	extz wa
	call VoiceSlot_Release
	andmi16 (xiz + 1), 0xFEFF
	jrl Voice_AllNotes_SustainRetrigger_LoopStep

Voice_AllNotes_SustainRetrigger_BranchC:
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume1
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume2
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume3
	ld xwa, (xsp + 8)
	ld a, (xwa)
	extz wa
	lda_24 xbc, 0x0451cc
	calr DSP_WriteVoiceParam_6Words
	jr Voice_AllNotes_SustainRetrigger_LoopStep

Voice_AllNotes_SustainRetrigger_BranchD:
	ld wa, (xiz + 1)
	bit 8, wa
	jr z, Voice_AllNotes_SustainRetrigger_BranchE
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume1
	ld xwa, (xsp + 8)
	ld a, (xwa)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteNote_Hold
	ld xwa, (xsp + 8)
	ld a, (xwa)
	extz wa
	ld bc, (xiz + 45)
	calr DSP_WriteVoiceParam_Direct
	ld xwa, (xsp + 8)
	ld a, (xwa)
	extz wa
	call VoiceSlot_Release
	andmi16 (xiz + 1), 0xFEFF
	jr Voice_AllNotes_SustainRetrigger_LoopStep

Voice_AllNotes_SustainRetrigger_BranchE:
	ld wa, (xiz + 64)
	and wa, 0xFF
	jr nz, Voice_AllNotes_SustainRetrigger_LoopStep
	ld xwa, xiz
	call Voice_WriteVolume_SetFlag
	ld xwa, (xsp + 8)
	ld a, (xwa)
	extz wa
	lda_24 xbc, 0x0451cc
	calr ToneGen_WriteNote2ch
	jr Voice_AllNotes_SustainRetrigger_LoopStep

Voice_AllNotes_SustainRetrigger_BranchF:
	cp (xsp + 12), 0x0
	jr z, Voice_AllNotes_SustainRetrigger_LoopStep
	ld xwa, xiz
	call Voice_WriteVolume_OrPan
	ld xwa, (xsp + 8)
	ld a, (xwa)
	extz wa
	lda_24 xbc, 0x0451cc
	calr ToneGen_WriteNote2ch

Voice_AllNotes_SustainRetrigger_LoopStep:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp (xwa), 0x40
	jrl c, Voice_AllNotes_SustainRetrigger_LoopBody

Voice_AllNotes_SustainRetrigger_Exit:
	pop xiz
	lda xsp, (xsp + 10)
	ret

VoiceCC_DataTable_028F75:
	.byte 0xef, 0x6c, 0x3e, 0xf2, 0x8e, 0x30, 0x04, 0x31
	.byte 0xbf, 0x04, 0x61, 0xe8, 0x65, 0xe8, 0x8e, 0x86
	.ascii "?@o["
	.byte 0x86, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x47, 0x00, 0xd8, 0x89, 0xaf, 0x04
	.byte 0x20, 0xe9, 0x13, 0xe8, 0x81, 0x99, 0x01, 0x20
	.byte 0xd8, 0xcc, 0x3c, 0x00, 0xd8, 0xcf, 0x08, 0x00
	.byte 0x66, 0x36, 0xd8, 0xcf, 0x10, 0x00, 0x66, 0x1e
	.byte 0xd8, 0xcf, 0x20, 0x00, 0x66, 0x04, 0xd8, 0xdc
	.byte 0x6e, 0x26, 0xe9, 0x88, 0x1d, 0x44, 0x44, 0x02
	.byte 0x86, 0x21, 0xd8, 0x12, 0xf2, 0xcc, 0x51, 0x04
	.byte 0x31, 0x1e, 0x57, 0xf1, 0x68, 0x12, 0xe9, 0x88
	.byte 0x1d, 0x54, 0x45, 0x02, 0x86, 0x21, 0xd8, 0x12
	.byte 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1e, 0x43, 0xf1
	.byte 0xee, 0x61, 0x86, 0x3f, 0x40, 0x67, 0xa5, 0x5e
	.byte 0xef, 0x64, 0x0e, 0xef, 0x6c, 0x3e, 0xf2, 0x8e
	.byte 0x30, 0x04, 0x31, 0xbf, 0x04, 0x61, 0xe8, 0x65
	.byte 0xe8, 0x8e, 0x86
	.ascii "?@oq"
	.byte 0x86
	.byte 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x47, 0x00, 0xd8
	.byte 0x89, 0xaf, 0x04, 0x20, 0xe9, 0x13, 0xe8, 0x81
	.byte 0x99, 0x01, 0x20, 0xd8, 0xcc, 0x3c, 0x00, 0xd8
	.byte 0xcf, 0x08, 0x00, 0x66, 0x4c, 0xd8, 0xcf, 0x10
	.byte 0x00, 0x66, 0x25, 0xd8, 0xcf, 0x20, 0x00, 0x66
	.byte 0x04, 0xd8, 0xdc, 0x6e, 0x3c, 0xb9, 0x05, 0xcf
	.byte 0x66, 0x37, 0xe9, 0x88, 0xd9, 0xa9, 0x1d, 0x1d
	.byte 0x59, 0x02, 0x86, 0x21, 0xd8, 0x12, 0xf2, 0xcc
	.byte 0x51, 0x04, 0x31, 0x1e, 0x2d, 0xf1, 0x68, 0x21
	.byte 0xa9, 0x13, 0x20, 0xb8, 0x0d, 0xcd, 0x66, 0x05
	.byte 0xb9, 0x05, 0xcf, 0x66, 0x14, 0xe9, 0x88, 0xd9
	.byte 0xa9, 0x1d, 0x6f, 0x5b, 0x02, 0x86, 0x21, 0xd8
	.byte 0x12, 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1e, 0x0a
	.byte 0xf1, 0xee, 0x61, 0x86, 0x3f, 0x40, 0x67, 0x8f
	.byte 0x5e, 0xef, 0x64, 0x0e, 0xef, 0x68, 0x3e, 0xf2
	.byte 0x8e, 0x30, 0x04, 0x31, 0xbf, 0x04, 0x61, 0xe8
	.byte 0x65, 0xbf, 0x08, 0x60, 0x80, 0x3f, 0x40, 0x6f
	.byte 0x5d, 0xaf, 0x08, 0x20, 0x80, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x47, 0x00, 0xd8, 0x89, 0xaf, 0x04
	.byte 0x20, 0xf3, 0x07, 0xe0, 0xe4, 0x36, 0x9e, 0x01
	.byte 0x20, 0xd8, 0xcc, 0x3c, 0x00, 0xd8, 0xcf, 0x10
	.byte 0x00, 0x66, 0x0e, 0xd8, 0xcf, 0x08, 0x00, 0x66
	.byte 0x28, 0xd8, 0xcf, 0x20, 0x00, 0x66, 0x22, 0x68
	.byte 0x20, 0xae, 0x13, 0x20, 0xee, 0x88, 0x1d, 0x35
	.byte 0x5a, 0x02, 0xee, 0x88, 0xd9, 0xa8, 0x1d, 0x6f
	.byte 0x5b, 0x02, 0xaf, 0x08, 0x20, 0x80, 0x21, 0xd8
	.byte 0x12, 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1e, 0x9a
	.byte 0xf0, 0xe8, 0xa9, 0xaf, 0x08, 0x88, 0xaf, 0x08
	.byte 0x20, 0x80, 0x3f, 0x40, 0x67, 0xa3, 0x5e, 0xef
	.byte 0x60, 0x0e, 0xef, 0x6a, 0x3e, 0xea, 0x8e, 0xbf
	.byte 0x04, 0x41, 0xd9, 0x88, 0xe8, 0x12, 0xd8, 0x33
	.byte 0x0f, 0x66, 0x05, 0xd9, 0x30, 0x0f, 0x68, 0x03
	.byte 0xd9, 0xee, 0x07, 0x8f, 0x04, 0x21, 0xd8, 0x12
	.byte 0xee, 0x8a, 0x1e, 0xa2, 0xf3, 0x8f, 0x04, 0x21
	.byte 0xc9, 0x8d, 0xda, 0x12, 0x86, 0x21, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0x0b, 0x20, 0x00, 0xda, 0x88, 0x32
	.byte 0x10, 0x00, 0x1e, 0x1a, 0xf2, 0x8f, 0x04, 0x21
	.byte 0xd8, 0x12, 0x1d, 0x36, 0xcd, 0x02, 0xeb, 0x88
	.byte 0x1e, 0x1c, 0xfc, 0x5e, 0xef, 0x62, 0x0e, 0xef
	.byte 0x6a, 0x3e, 0xea, 0x8e, 0xbf, 0x04, 0x41, 0x8f
	.byte 0x04, 0x21, 0xd8, 0x12, 0xd9, 0x12, 0xee, 0x8a
	.byte 0x1e, 0x17, 0xf4, 0x8f, 0x04, 0x21, 0xc9, 0x8d
	.byte 0xda, 0x12, 0x86, 0x21, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0x0b, 0x80, 0x00, 0xda, 0x88, 0x32, 0x40, 0x00
	.byte 0x1e, 0xdc, 0xf1, 0x8f, 0x04, 0x21, 0xd8, 0x12
	.byte 0x1d, 0x36, 0xcd, 0x02, 0xeb, 0x88, 0x1e, 0x07
	.byte 0xfe, 0x5e, 0xef, 0x62, 0x0e, 0xef, 0x6e, 0x3e
	.byte 0xea, 0x8e, 0xbf, 0x08, 0x41, 0x8f, 0x08, 0x21
	.byte 0xd8, 0x12, 0xd9, 0x12, 0xee, 0x8a, 0x1e, 0x26
	.byte 0xf4, 0x8f, 0x08, 0x21, 0xc9, 0x8d, 0xda, 0x12
	.byte 0x86, 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0x0b, 0x00
	.byte 0x02, 0xda, 0x88, 0x32, 0x00, 0x01, 0x1e, 0x9e
	.byte 0xf1, 0x8f, 0x08, 0x21, 0xd8, 0x12, 0xd8, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04, 0x31, 0xe3
	.byte 0x07, 0xe4, 0xe0, 0x20, 0x88, 0x10, 0x21, 0xc9
	.byte 0xcc, 0xc0, 0xc9, 0xcf, 0xc0, 0x66, 0x28, 0xc9
	.byte 0xcf, 0x40, 0x66, 0x23, 0xc9, 0xcf, 0x80, 0x66
	.byte 0x12, 0xc9, 0xd8, 0x6e, 0x1a, 0x8f, 0x08, 0x21
	.byte 0xd8, 0x12, 0x1d, 0x14, 0xcd, 0x02, 0xbf, 0x04
	.byte 0x63, 0x68, 0x0c, 0x8f, 0x08, 0x21, 0xd8, 0x12
	.byte 0x1d, 0x36, 0xcd, 0x02, 0xbf, 0x04, 0x63, 0xaf
	.byte 0x04, 0x20, 0x1e, 0xfe, 0xfd, 0x5e, 0xef, 0x66
	.byte 0x0e, 0xbf, 0xf6, 0x37, 0x3e, 0xbf, 0x0a, 0x43
	.byte 0xbf, 0x0c, 0x41, 0x8f, 0x12, 0x21, 0xd8, 0x12
	.byte 0xd8, 0xec, 0x02, 0xd8, 0x8b, 0xdb, 0xc8, 0x27
	.byte 0x00, 0x8f, 0x0c, 0x21, 0xd8, 0x12, 0xd8, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04, 0x31, 0xe8
	.byte 0x13, 0xe9, 0x80, 0xf3, 0x07, 0xe0, 0xec, 0x30
	.byte 0x88, 0x03, 0x3f, 0x00, 0x7e, 0xb3, 0x00, 0x8f
	.byte 0x0c, 0x21, 0xc9, 0x8f, 0xdb, 0x12, 0x8f, 0x0a
	.byte 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0x8f, 0x12, 0x21
	.byte 0xd8, 0x12, 0x28, 0x0b, 0x00, 0x00, 0xdb, 0x88
	.byte 0x1e, 0xb6, 0xf3, 0x8f, 0x0c, 0x21, 0xc9, 0x8d
	.byte 0xda, 0x12, 0x8f, 0x12, 0x21, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xda, 0x88, 0xd9, 0x8a, 0xd9, 0xa8, 0x1d
	.byte 0xd5, 0x2f, 0x03, 0xde, 0xa8, 0xde, 0xdc, 0x6f
	.byte 0x1c, 0x8f, 0x0c, 0x21, 0xc9, 0x8d, 0xda, 0x12
	.byte 0xc7, 0xf8, 0x89, 0xc9, 0x8b, 0xd9, 0x12, 0xda
	.byte 0x88, 0xda, 0xa8, 0x1d, 0xbe, 0x33, 0x03, 0xde
	.byte 0x61, 0xde, 0xdc, 0x67, 0xe4, 0x8f, 0x0c, 0x21
	.byte 0xd8, 0x12, 0x1d, 0x36, 0xcd, 0x02, 0x8f, 0x0c
	.byte 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2
	.byte 0x68, 0x13, 0x04, 0x31, 0xd3, 0x07, 0xe4, 0xe0
	.byte 0x3e, 0x08, 0x00, 0xf2, 0x8e, 0x30, 0x04, 0x30
	.byte 0xbf, 0x06, 0x60, 0xbb, 0x05, 0x30, 0xe8, 0x8e
	.byte 0x86, 0x3f, 0x40, 0x7f, 0x3e, 0x01, 0x86, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x09, 0x47, 0x00, 0xd8, 0x89
	.byte 0xaf, 0x06, 0x20, 0xf3, 0x07, 0xe0, 0xe4, 0x30
	.byte 0x1d, 0xe3, 0x4b, 0x02, 0x86, 0x21, 0xd8, 0x12
	.byte 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1e, 0x15, 0xef
	.byte 0xee, 0x61, 0x86, 0x3f, 0x40, 0x67, 0xd7, 0x78
	.byte 0x12, 0x01, 0x8f, 0x0c, 0x21, 0xc9, 0x8f, 0xdb
	.byte 0x12, 0x8f, 0x0a, 0x21, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0x8f, 0x12, 0x21, 0xd8, 0x12, 0x28, 0x0b, 0x00
	.byte 0x00, 0xdb, 0x88, 0x1e, 0x03, 0xf3, 0x8f, 0x0c
	.byte 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x12, 0x21
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xda, 0x88, 0xd9, 0x8a
	.byte 0xd9, 0xa8, 0x1d, 0xd5, 0x2f, 0x03, 0xde, 0xa8
	.byte 0xde, 0xdc, 0x6f, 0x1c, 0x8f, 0x0c, 0x21, 0xc9
	.byte 0x8d, 0xda, 0x12, 0xc7, 0xf8, 0x89, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xda, 0x88, 0xda, 0xa8, 0x1d, 0xbe
	.byte 0x33, 0x03, 0xde, 0x61, 0xde, 0xdc, 0x67, 0xe4
	.byte 0x8f, 0x0c, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f
	.byte 0x12, 0x21, 0xd8, 0x12, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xda, 0x88, 0x32, 0x20, 0x00, 0x1d, 0x8e, 0x1a
	.byte 0x02, 0xbf, 0x04, 0x63, 0xbf, 0x08, 0x02, 0x00
	.byte 0x00, 0x78, 0x81, 0x00, 0x9f, 0x08, 0x20, 0xe8
	.byte 0x12, 0xe8, 0x80, 0xaf, 0x04, 0x80, 0x90, 0x26
	.byte 0xc7, 0xf9, 0xa8, 0x8f, 0x0c, 0x21, 0xc9, 0x8f
	.byte 0xdb, 0x12, 0x8f, 0x0c, 0x21, 0xd8, 0x12, 0xd8
	.byte 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04, 0x31
	.byte 0xf3, 0x07, 0xe4, 0xe0, 0x31, 0x8f, 0x12, 0x21
	.byte 0xc9, 0x8d, 0xda, 0x12, 0x0b, 0x00, 0x00, 0xc7
	.byte 0xf8, 0x89, 0xd8, 0x12, 0x28, 0xdb, 0x88, 0x1d
	.byte 0x59, 0x4a, 0x02, 0x8f, 0x0a, 0x3f, 0x00, 0x6e
	.byte 0x1e, 0x8f, 0x0c, 0x21, 0xd8, 0x12, 0xd8, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04, 0x31, 0xd3
	.byte 0x07, 0xe4, 0xe0, 0x3e, 0x08, 0x00, 0xf2, 0x0c
	.byte 0x52, 0x04, 0x02, 0x00, 0x00, 0x68, 0x0e, 0xc7
	.byte 0xf8, 0x89, 0xd8, 0x12, 0x1d, 0x2a, 0x2e, 0x02
	.byte 0xf2, 0x0c, 0x52, 0x04, 0x53, 0xc7, 0xf8, 0x89
	.byte 0xd8, 0x12, 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1e
	.byte 0x57, 0xee, 0x9f, 0x08, 0x61, 0x9f, 0x08, 0x20
	.byte 0xe8, 0x12, 0xe8, 0x80, 0xaf, 0x04, 0x80, 0x90
	.byte 0x20, 0xd8, 0xcc, 0xff, 0x00, 0xd8, 0xcf, 0x80
	.byte 0x00, 0x77, 0x68, 0xff, 0x5e, 0xbf, 0x0a, 0x37
	.byte 0x0f, 0x02, 0x00, 0xbf, 0xf6, 0x37, 0x3e, 0xbf
	.byte 0x0a, 0x43, 0xbf, 0x0c, 0x41, 0x8f, 0x12, 0x21
	.byte 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xd8, 0x8b, 0xdb
	.byte 0xc8, 0x27, 0x00, 0x8f, 0x0c, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04
	.byte 0x31, 0xe8, 0x13, 0xe9, 0x80, 0xf3, 0x07, 0xe0
	.byte 0xec, 0x30, 0x88, 0x02, 0x3f, 0x00, 0x7e, 0xb3
	.byte 0x00, 0x8f, 0x0c, 0x21, 0xc9, 0x8f, 0xdb, 0x12
	.byte 0x8f, 0x0a, 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0x8f
	.byte 0x12, 0x21, 0xd8, 0x12, 0x28, 0x0b, 0x00, 0x00
	.byte 0xdb, 0x88, 0x1e, 0xcd, 0xf2, 0x8f, 0x0c, 0x21
	.byte 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x12, 0x21, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xda, 0x88, 0xd9, 0x8a, 0xd9
	.byte 0xa8, 0x1d, 0xd5, 0x30, 0x03, 0xde, 0xa8, 0xde
	.byte 0xdc, 0x6f, 0x1c, 0x8f, 0x0c, 0x21, 0xc9, 0x8d
	.byte 0xda, 0x12, 0xc7, 0xf8, 0x89, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xda, 0x88, 0xda, 0xa8, 0x1d, 0xbe, 0x33
	.byte 0x03, 0xde, 0x61, 0xde, 0xdc, 0x67, 0xe4, 0x8f
	.byte 0x0c, 0x21, 0xd8, 0x12, 0x1d, 0x36, 0xcd, 0x02
	.byte 0x8f, 0x0c, 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x1f
	.byte 0x01, 0xf2, 0x68, 0x13, 0x04, 0x31, 0xd3, 0x07
	.byte 0xe4, 0xe0, 0x3e, 0x08, 0x00, 0xf2, 0x8e, 0x30
	.byte 0x04, 0x30, 0xbf, 0x06, 0x60, 0xbb, 0x05, 0x30
	.byte 0xe8, 0x8e, 0x86, 0x3f, 0x40, 0x7f, 0x4b, 0x01
	.byte 0x86, 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x47, 0x00
	.byte 0xd8, 0x89, 0xaf, 0x06, 0x20, 0xf3, 0x07, 0xe0
	.byte 0xe4, 0x30, 0x1d, 0xe3, 0x4b, 0x02, 0x86, 0x21
	.byte 0xd8, 0x12, 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1e
	.byte 0x13, 0xed, 0xee, 0x61, 0x86, 0x3f, 0x40, 0x67
	.byte 0xd7, 0x78, 0x1f, 0x01, 0x8f, 0x0c, 0x21, 0xc9
	.byte 0x8f, 0xdb, 0x12, 0x8f, 0x0a, 0x21, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0x8f, 0x12, 0x21, 0xd8, 0x12, 0x28
	.byte 0x0b, 0x00, 0x00, 0xdb, 0x88, 0x1e, 0x1a, 0xf2
	.byte 0x8f, 0x0c, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f
	.byte 0x12, 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0xda, 0x88
	.byte 0xd9, 0x8a, 0xd9, 0xa8, 0x1d, 0xd5, 0x30, 0x03
	.byte 0xde, 0xa8, 0xde, 0xdc, 0x6f, 0x1c, 0x8f, 0x0c
	.byte 0x21, 0xc9, 0x8d, 0xda, 0x12, 0xc7, 0xf8, 0x89
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xda, 0x88, 0xda, 0xa8
	.byte 0x1d, 0xbe, 0x33, 0x03, 0xde, 0x61, 0xde, 0xdc
	.byte 0x67, 0xe4, 0x8f, 0x0c, 0x21, 0xc9, 0x8d, 0xda
	.byte 0x12, 0x8f, 0x12, 0x21, 0xd8, 0x12, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xda, 0x88, 0x32, 0x20, 0x00, 0x1d
	.byte 0x8e, 0x1a, 0x02, 0xbf, 0x04, 0x63, 0xbf, 0x08
	.byte 0x02, 0x00, 0x00, 0x78, 0x8e, 0x00, 0x9f, 0x08
	.byte 0x20, 0xe8, 0x12, 0xe8, 0x80, 0xaf, 0x04, 0x80
	.byte 0x90, 0x26, 0xc7, 0xf9, 0xa8, 0x8f, 0x0c, 0x21
	.byte 0xc9, 0x8f, 0xdb, 0x12, 0x8f, 0x0c, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13
	.byte 0x04, 0x31, 0xf3, 0x07, 0xe4, 0xe0, 0x31, 0x8f
	.byte 0x12, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x0b, 0x00
	.byte 0x00, 0xc7, 0xf8, 0x89, 0xd8, 0x12, 0x28, 0xdb
	.byte 0x88, 0x1d, 0x59, 0x4a, 0x02, 0x8f, 0x0a, 0x3f
	.byte 0x00, 0x6e, 0x2b, 0x8f, 0x0c, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04
	.byte 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x3e, 0x08, 0x00
	.byte 0xf2, 0x0c, 0x52, 0x04, 0x02, 0x00, 0x00, 0xc7
	.byte 0xf8, 0x89, 0xd8, 0x12, 0xf2, 0xcc, 0x51, 0x04
	.byte 0x31, 0x1e, 0x65, 0xec, 0x68, 0x1b, 0xc7, 0xf8
	.byte 0x89, 0xd8, 0x12, 0x1d, 0xba, 0x2e, 0x02, 0xf2
	.byte 0x08, 0x52, 0x04, 0x53, 0xc7, 0xf8, 0x89, 0xd8
	.byte 0x12, 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1e, 0x6a
	.byte 0xec, 0x9f, 0x08, 0x61, 0x9f, 0x08, 0x20, 0xe8
	.byte 0x12, 0xe8, 0x80, 0xaf, 0x04, 0x80, 0x90, 0x20
	.byte 0xd8, 0xcc, 0xff, 0x00, 0xd8, 0xcf, 0x80, 0x00
	.byte 0x77, 0x5b, 0xff, 0x5e, 0xbf, 0x0a, 0x37, 0x0f
	.byte 0x02, 0x00, 0xbf, 0xf6, 0x37, 0x3e, 0xbf, 0x0a
	.byte 0x43, 0xbf, 0x0c, 0x41, 0x8f, 0x12, 0x21, 0xd8
	.byte 0x12, 0xd8, 0xec, 0x02, 0xd8, 0x8b, 0xdb, 0xc8
	.byte 0x37, 0x00, 0x8f, 0x0c, 0x21, 0xd8, 0x12, 0xd8
	.byte 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04, 0x31
	.byte 0xe8, 0x13, 0xe9, 0x80, 0xf3, 0x07, 0xe0, 0xec
	.byte 0x30, 0x88, 0x03, 0x3f, 0x00, 0x7e, 0xb3, 0x00
	.byte 0x8f, 0x0c, 0x21, 0xc9, 0x8f, 0xdb, 0x12, 0x8f
	.byte 0x0a, 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0x8f, 0x12
	.byte 0x21, 0xd8, 0x12, 0x28, 0x0b, 0x01, 0x00, 0xdb
	.byte 0x88, 0x1e, 0xa5, 0xef, 0x8f, 0x0c, 0x21, 0xc9
	.byte 0x8d, 0xda, 0x12, 0x8f, 0x12, 0x21, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xda, 0x88, 0xd9, 0x8a, 0xd9, 0xa9
	.byte 0x1d, 0xd5, 0x2f, 0x03, 0xde, 0xa8, 0xde, 0xdc
	.byte 0x6f, 0x1c, 0x8f, 0x0c, 0x21, 0xc9, 0x8d, 0xda
	.byte 0x12, 0xc7, 0xf8, 0x89, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xda, 0x88, 0xda, 0xa9, 0x1d, 0xbe, 0x33, 0x03
	.byte 0xde, 0x61, 0xde, 0xdc, 0x67, 0xe4, 0x8f, 0x0c
	.byte 0x21, 0xd8, 0x12, 0x1d, 0x36, 0xcd, 0x02, 0x8f
	.byte 0x0c, 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01
	.byte 0xf2, 0x68, 0x13, 0x04, 0x31, 0xd3, 0x07, 0xe4
	.byte 0xe0, 0x3e, 0x08, 0x00, 0xf2, 0x8e, 0x30, 0x04
	.byte 0x30, 0xbf, 0x06, 0x60, 0xbb, 0x05, 0x30, 0xe8
	.byte 0x8e, 0x86, 0x3f, 0x40, 0x7f, 0x41, 0x01, 0x86
	.byte 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x47, 0x00, 0xd8
	.byte 0x89, 0xaf, 0x06, 0x20, 0xf3, 0x07, 0xe0, 0xe4
	.byte 0x30, 0x1d, 0x41, 0x4f, 0x02, 0x86, 0x21, 0xd8
	.byte 0x12, 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1e, 0xe2
	.byte 0xea, 0xee, 0x61, 0x86, 0x3f, 0x40, 0x67, 0xd7
	.byte 0x78, 0x15, 0x01, 0x8f, 0x0c, 0x21, 0xc9, 0x8f
	.byte 0xdb, 0x12, 0x8f, 0x0a, 0x21, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0x8f, 0x12, 0x21, 0xd8, 0x12, 0x28, 0x0b
	.byte 0x01, 0x00, 0xdb, 0x88, 0x1e, 0xf2, 0xee, 0x8f
	.byte 0x0c, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x12
	.byte 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0xda, 0x88, 0xd9
	.byte 0x8a, 0xd9, 0xa9, 0x1d, 0xd5, 0x2f, 0x03, 0xde
	.byte 0xa8, 0xde, 0xdc, 0x6f, 0x1c, 0x8f, 0x0c, 0x21
	.byte 0xc9, 0x8d, 0xda, 0x12, 0xc7, 0xf8, 0x89, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xda, 0x88, 0xda, 0xa9, 0x1d
	.byte 0xbe, 0x33, 0x03, 0xde, 0x61, 0xde, 0xdc, 0x67
	.byte 0xe4, 0x8f, 0x0c, 0x21, 0xc9, 0x8d, 0xda, 0x12
	.byte 0x8f, 0x12, 0x21, 0xd8, 0x12, 0xd8, 0x31, 0x02
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xda, 0x88, 0x32, 0x20
	.byte 0x00, 0x1d, 0x8e, 0x1a, 0x02, 0xbf, 0x04, 0x63
	.byte 0xbf, 0x08, 0x02, 0x00, 0x00, 0x78, 0x81, 0x00
	.byte 0x9f, 0x08, 0x20, 0xe8, 0x12, 0xe8, 0x80, 0xaf
	.byte 0x04, 0x80, 0x90, 0x26, 0xc7, 0xf9, 0xa8, 0x8f
	.byte 0x0c, 0x21, 0xc9, 0x8f, 0xdb, 0x12, 0x8f, 0x0c
	.byte 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2
	.byte 0x68, 0x13, 0x04, 0x31, 0xf3, 0x07, 0xe4, 0xe0
	.byte 0x31, 0x8f, 0x12, 0x21, 0xc9, 0x8d, 0xda, 0x12
	.byte 0x0b, 0x01, 0x00, 0xc7, 0xf8, 0x89, 0xd8, 0x12
	.byte 0x28, 0xdb, 0x88, 0x1d, 0x59, 0x4a, 0x02, 0x8f
	.byte 0x0a, 0x3f, 0x00, 0x6e, 0x1e, 0x8f, 0x0c, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x68
	.byte 0x13, 0x04, 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x3e
	.byte 0x08, 0x00, 0xf2, 0x04, 0x52, 0x04, 0x02, 0x00
	.byte 0x00, 0x68, 0x0e, 0xc7, 0xf8, 0x89, 0xd8, 0x12
	.byte 0x1d, 0x3c, 0x2f, 0x02, 0xf2, 0x04, 0x52, 0x04
	.byte 0x53, 0xc7, 0xf8, 0x89, 0xd8, 0x12, 0xf2, 0xcc
	.byte 0x51, 0x04, 0x31, 0x1e, 0x87, 0xea, 0x9f, 0x08
	.byte 0x61, 0x9f, 0x08, 0x20, 0xe8, 0x12, 0xe8, 0x80
	.byte 0xaf, 0x04, 0x80, 0x90, 0x20, 0xd8, 0xcc, 0xff
	.byte 0x00, 0xd8, 0xcf, 0x40, 0x00, 0x77, 0x68, 0xff
	.byte 0x5e, 0xbf, 0x0a, 0x37, 0x0f, 0x02, 0x00, 0xbf
	.byte 0xf6, 0x37, 0x3e, 0xbf, 0x0a, 0x43, 0xbf, 0x0c
	.byte 0x41, 0x8f, 0x12, 0x21, 0xd8, 0x12, 0xd8, 0xec
	.byte 0x02, 0xd8, 0x8b, 0xdb, 0xc8, 0x37, 0x00, 0x8f
	.byte 0x0c, 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01
	.byte 0xf2, 0x68, 0x13, 0x04, 0x31, 0xe8, 0x13, 0xe9
	.byte 0x80, 0xf3, 0x07, 0xe0, 0xec, 0x30, 0x88, 0x02
	.byte 0x3f, 0x00, 0x7e, 0xb3, 0x00, 0x8f, 0x0c, 0x21
	.byte 0xc9, 0x8f, 0xdb, 0x12, 0x8f, 0x0a, 0x21, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0x8f, 0x12, 0x21, 0xd8, 0x12
	.byte 0x28, 0x0b, 0x01, 0x00, 0xdb, 0x88, 0x1e, 0xb9
	.byte 0xee, 0x8f, 0x0c, 0x21, 0xc9, 0x8d, 0xda, 0x12
	.byte 0x8f, 0x12, 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0xda
	.byte 0x88, 0xd9, 0x8a, 0xd9, 0xa9, 0x1d, 0xd5, 0x30
	.byte 0x03, 0xde, 0xa8, 0xde, 0xdc, 0x6f, 0x1c, 0x8f
	.byte 0x0c, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0xc7, 0xf8
	.byte 0x89, 0xc9, 0x8b, 0xd9, 0x12, 0xda, 0x88, 0xda
	.byte 0xa9, 0x1d, 0xbe, 0x33, 0x03, 0xde, 0x61, 0xde
	.byte 0xdc, 0x67, 0xe4, 0x8f, 0x0c, 0x21, 0xd8, 0x12
	.byte 0x1d, 0x36, 0xcd, 0x02, 0x8f, 0x0c, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13
	.byte 0x04, 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x3e, 0x08
	.byte 0x00, 0xf2, 0x8e, 0x30, 0x04, 0x30, 0xbf, 0x06
	.byte 0x60, 0xbb, 0x05, 0x30, 0xe8, 0x8e, 0x86, 0x3f
	.byte 0x40, 0x7f, 0x4e, 0x01, 0x86, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x47, 0x00, 0xd8, 0x89, 0xaf, 0x06
	.byte 0x20, 0xf3, 0x07, 0xe0, 0xe4, 0x30, 0x1d, 0x41
	.byte 0x4f, 0x02, 0x86, 0x21, 0xd8, 0x12, 0xf2, 0xcc
	.byte 0x51, 0x04, 0x31, 0x1e, 0xdd, 0xe8, 0xee, 0x61
	.byte 0x86, 0x3f, 0x40, 0x67, 0xd7, 0x78, 0x22, 0x01
	.byte 0x8f, 0x0c, 0x21, 0xc9, 0x8f, 0xdb, 0x12, 0x8f
	.byte 0x0a, 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0x8f, 0x12
	.byte 0x21, 0xd8, 0x12, 0x28, 0x0b, 0x01, 0x00, 0xdb
	.byte 0x88, 0x1e, 0x06, 0xee, 0x8f, 0x0c, 0x21, 0xc9
	.byte 0x8d, 0xda, 0x12, 0x8f, 0x12, 0x21, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xda, 0x88, 0xd9, 0x8a, 0xd9, 0xa9
	.byte 0x1d, 0xd5, 0x30, 0x03, 0xde, 0xa8, 0xde, 0xdc
	.byte 0x6f, 0x1c, 0x8f, 0x0c, 0x21, 0xc9, 0x8d, 0xda
	.byte 0x12, 0xc7, 0xf8, 0x89, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xda, 0x88, 0xda, 0xa9, 0x1d, 0xbe, 0x33, 0x03
	.byte 0xde, 0x61, 0xde, 0xdc, 0x67, 0xe4, 0x8f, 0x0c
	.byte 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x12, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x31, 0x02, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xda, 0x88, 0x32, 0x20, 0x00, 0x1d, 0x8e
	.byte 0x1a, 0x02, 0xbf, 0x04, 0x63, 0xbf, 0x08, 0x02
	.byte 0x00, 0x00, 0x78, 0x8e, 0x00, 0x9f, 0x08, 0x20
	.byte 0xe8, 0x12, 0xe8, 0x80, 0xaf, 0x04, 0x80, 0x90
	.byte 0x26, 0xc7, 0xf9, 0xa8, 0x8f, 0x0c, 0x21, 0xc9
	.byte 0x8f, 0xdb, 0x12, 0x8f, 0x0c, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04
	.byte 0x31, 0xf3, 0x07, 0xe4, 0xe0, 0x31, 0x8f, 0x12
	.byte 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x0b, 0x01, 0x00
	.byte 0xc7, 0xf8, 0x89, 0xd8, 0x12, 0x28, 0xdb, 0x88
	.byte 0x1d, 0x59, 0x4a, 0x02, 0x8f, 0x0a, 0x3f, 0x00
	.byte 0x6e, 0x2b, 0x8f, 0x0c, 0x21, 0xd8, 0x12, 0xd8
	.byte 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04, 0x31
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x3e, 0x08, 0x00, 0xf2
	.byte 0x04, 0x52, 0x04, 0x02, 0x00, 0x00, 0xc7, 0xf8
	.byte 0x89, 0xd8, 0x12, 0xf2, 0xcc, 0x51, 0x04, 0x31
	.byte 0x1e, 0x92, 0xe8, 0x68, 0x1b, 0xc7, 0xf8, 0x89
	.byte 0xd8, 0x12, 0x1d, 0xcc, 0x2f, 0x02, 0xf2, 0x06
	.byte 0x52, 0x04, 0x53, 0xc7, 0xf8, 0x89, 0xd8, 0x12
	.byte 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1e, 0x97, 0xe8
	.byte 0x9f, 0x08, 0x61, 0x9f, 0x08, 0x20, 0xe8, 0x12
	.byte 0xe8, 0x80, 0xaf, 0x04, 0x80, 0x90, 0x20, 0xd8
	.byte 0xcc, 0xff, 0x00, 0xd8, 0xcf, 0x40, 0x00, 0x77
	.byte 0x5b, 0xff, 0x5e, 0xbf, 0x0a, 0x37, 0x0f, 0x02
	.byte 0x00, 0xbf, 0xf6, 0x37, 0x3e, 0xbf, 0x0a, 0x43
	.byte 0xbf, 0x0c, 0x41, 0x8f, 0x12, 0x21, 0xd8, 0x12
	.byte 0xd8, 0xec, 0x02, 0xd8, 0x8b, 0xdb, 0xc8, 0x47
	.byte 0x00, 0x8f, 0x0c, 0x21, 0xd8, 0x12, 0xd8, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04, 0x31, 0xe8
	.byte 0x13, 0xe9, 0x80, 0xf3, 0x07, 0xe0, 0xec, 0x30
	.byte 0x88, 0x03, 0x3f, 0x00, 0x7e, 0xb3, 0x00, 0x8f
	.byte 0x0c, 0x21, 0xc9, 0x8f, 0xdb, 0x12, 0x8f, 0x0a
	.byte 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0x8f, 0x12, 0x21
	.byte 0xd8, 0x12, 0x28, 0x0b, 0x02, 0x00, 0xdb, 0x88
	.byte 0x1e, 0x8e, 0xeb, 0x8f, 0x0c, 0x21, 0xc9, 0x8d
	.byte 0xda, 0x12, 0x8f, 0x12, 0x21, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xda, 0x88, 0xd9, 0x8a, 0xd9, 0xaa, 0x1d
	.byte 0xd5, 0x2f, 0x03, 0xde, 0xa8, 0xde, 0xdc, 0x6f
	.byte 0x1c, 0x8f, 0x0c, 0x21, 0xc9, 0x8d, 0xda, 0x12
	.byte 0xc7, 0xf8, 0x89, 0xc9, 0x8b, 0xd9, 0x12, 0xda
	.byte 0x88, 0xda, 0xaa, 0x1d, 0xbe, 0x33, 0x03, 0xde
	.byte 0x61, 0xde, 0xdc, 0x67, 0xe4, 0x8f, 0x0c, 0x21
	.byte 0xd8, 0x12, 0x1d, 0x36, 0xcd, 0x02, 0x8f, 0x0c
	.byte 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2
	.byte 0x68, 0x13, 0x04, 0x31, 0xd3, 0x07, 0xe4, 0xe0
	.byte 0x3e, 0x08, 0x00, 0xf2, 0x8e, 0x30, 0x04, 0x30
	.byte 0xbf, 0x06, 0x60, 0xbb, 0x05, 0x30, 0xe8, 0x8e
	.byte 0x86, 0x3f, 0x40, 0x7f, 0x43, 0x01, 0x86, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x09, 0x47, 0x00, 0xd8, 0x89
	.byte 0xaf, 0x06, 0x20, 0xf3, 0x07, 0xe0, 0xe4, 0x30
	.byte 0x1d, 0x29, 0x52, 0x02, 0x86, 0x21, 0xd8, 0x12
	.byte 0xf2, 0xcc, 0x51, 0x04, 0x31, 0x1e, 0x0f, 0xe7
	.byte 0xee, 0x61, 0x86, 0x3f, 0x40, 0x67, 0xd7, 0x78
	.byte 0x17, 0x01, 0x8f, 0x0c, 0x21, 0xc9, 0x8f, 0xdb
	.byte 0x12, 0x8f, 0x0a, 0x21, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0x8f, 0x12, 0x21, 0xd8, 0x12, 0x28, 0x0b, 0x02
	.byte 0x00, 0xdb, 0x88, 0x1e, 0xdb, 0xea, 0x8f, 0x0c
	.byte 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x12, 0x21
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xda, 0x88, 0xd9, 0x8a
	.byte 0xd9, 0xaa, 0x1d, 0xd5, 0x2f, 0x03, 0xde, 0xa8
	.byte 0xde, 0xdc, 0x6f, 0x1c, 0x8f, 0x0c, 0x21, 0xc9
	.byte 0x8d, 0xda, 0x12, 0xc7, 0xf8, 0x89, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xda, 0x88, 0xda, 0xaa, 0x1d, 0xbe
	.byte 0x33, 0x03, 0xde, 0x61, 0xde, 0xdc, 0x67, 0xe4
	.byte 0x8f, 0x0c, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f
	.byte 0x12, 0x21, 0xd8, 0x12, 0xd8, 0x31, 0x03, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xda, 0x88, 0x32, 0x20, 0x00
	.byte 0x1d, 0x8e, 0x1a, 0x02, 0xbf, 0x04, 0x63, 0xbf
	.byte 0x08, 0x02, 0x00, 0x00, 0x78, 0x83, 0x00, 0x9f
	.byte 0x08, 0x20, 0xe8, 0x12, 0xe8, 0x80, 0xaf, 0x04
	.byte 0x80, 0x90, 0x26, 0xc7, 0xf9, 0xa8, 0x8f, 0x0c
	.byte 0x21, 0xc9, 0x8f, 0xdb, 0x12, 0x8f, 0x0c, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x68
	.byte 0x13, 0x04, 0x31, 0xf3, 0x07, 0xe4, 0xe0, 0x31
	.byte 0x8f, 0x12, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x0b
	.byte 0x02, 0x00, 0xc7, 0xf8, 0x89, 0xd8, 0x12, 0x28
	.byte 0xdb, 0x88, 0x1d, 0x59, 0x4a, 0x02, 0x8f, 0x0a
	.byte 0x3f, 0x00, 0x6e, 0x25, 0x8f, 0x0c, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13
	.byte 0x04, 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x3e, 0x08
	.byte 0x00, 0xf2, 0x04, 0x52, 0x04, 0x02, 0x00, 0x00
	.byte 0xf2, 0x0e, 0x52, 0x04, 0x02, 0x00, 0x00, 0x68
	.byte 0x09, 0xc7, 0xf8, 0x89, 0xd8, 0x12, 0x1d, 0x43
	.byte 0x30, 0x02, 0xc7, 0xf8, 0x89, 0xd8, 0x12, 0xf2
	.byte 0xcc, 0x51, 0x04, 0x31, 0x1e, 0xb2, 0xe6, 0x9f
	.byte 0x08, 0x61, 0x9f, 0x08, 0x20, 0xe8, 0x12, 0xe8
	.byte 0x80, 0xaf, 0x04, 0x80, 0x90, 0x20, 0xd8, 0xcc
	.byte 0xff, 0x00, 0xd8, 0xcf, 0x80, 0x00, 0x77, 0x66
	.byte 0xff, 0x5e, 0xbf, 0x0a, 0x37, 0x0f, 0x02, 0x00
	.byte 0xbf, 0xf6, 0x37, 0x3e, 0xbf, 0x0a, 0x43, 0xbf
	.byte 0x0c, 0x41, 0x8f, 0x12, 0x21, 0xd8, 0x12, 0xd8
	.byte 0xec, 0x02, 0xd8, 0x8b, 0xdb, 0xc8, 0x47, 0x00
	.byte 0x8f, 0x0c, 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x1f
	.byte 0x01, 0xf2, 0x68, 0x13, 0x04, 0x31, 0xe8, 0x13
	.byte 0xe9, 0x80, 0xf3, 0x07, 0xe0, 0xec, 0x30, 0x88
	.byte 0x02, 0x3f, 0x00, 0x7e, 0xb3, 0x00, 0x8f, 0x0c
	.byte 0x21, 0xc9, 0x8f, 0xdb, 0x12, 0x8f, 0x0a, 0x21
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0x8f, 0x12, 0x21, 0xd8
	.byte 0x12, 0x28, 0x0b, 0x02, 0x00, 0xdb, 0x88, 0x1e
	.byte 0xa0, 0xea, 0x8f, 0x0c, 0x21, 0xc9, 0x8d, 0xda
	.byte 0x12, 0x8f, 0x12, 0x21, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xda, 0x88, 0xd9, 0x8a, 0xd9, 0xaa, 0x1d, 0xd5
	.byte 0x30, 0x03, 0xde, 0xa8, 0xde, 0xdc, 0x6f, 0x1c
	.byte 0x8f, 0x0c, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0xc7
	.byte 0xf8, 0x89, 0xc9, 0x8b, 0xd9, 0x12, 0xda, 0x88
	.byte 0xda, 0xaa, 0x1d, 0xbe, 0x33, 0x03, 0xde, 0x61
	.byte 0xde, 0xdc, 0x67, 0xe4, 0x8f, 0x0c, 0x21, 0xd8
	.byte 0x12, 0x1d, 0x36, 0xcd, 0x02, 0x8f, 0x0c, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x68
	.byte 0x13, 0x04, 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x3e
	.byte 0x08, 0x00, 0xf2, 0x8e, 0x30, 0x04, 0x30, 0xbf
	.byte 0x06, 0x60, 0xbb, 0x05, 0x30, 0xe8, 0x8e, 0x86
	.byte 0x3f, 0x40, 0x7f, 0x50, 0x01, 0x86, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x47, 0x00, 0xd8, 0x89, 0xaf
	.byte 0x06, 0x20, 0xf3, 0x07, 0xe0, 0xe4, 0x30, 0x1d
	.byte 0x29, 0x52, 0x02, 0x86, 0x21, 0xd8, 0x12, 0xf2
	.byte 0xcc, 0x51, 0x04, 0x31, 0x1e, 0x08, 0xe5, 0xee
	.byte 0x61, 0x86, 0x3f, 0x40, 0x67, 0xd7, 0x78, 0x24
	.byte 0x01, 0x8f, 0x0c, 0x21, 0xc9, 0x8f, 0xdb, 0x12
	.byte 0x8f, 0x0a, 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0x8f
	.byte 0x12, 0x21, 0xd8, 0x12, 0x28, 0x0b, 0x02, 0x00
	.byte 0xdb, 0x88, 0x1e, 0xed, 0xe9, 0x8f, 0x0c, 0x21
	.byte 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x12, 0x21, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xda, 0x88, 0xd9, 0x8a, 0xd9
	.byte 0xaa, 0x1d, 0xd5, 0x30, 0x03, 0xde, 0xa8, 0xde
	.byte 0xdc, 0x6f, 0x1c, 0x8f, 0x0c, 0x21, 0xc9, 0x8d
	.byte 0xda, 0x12, 0xc7, 0xf8, 0x89, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xda, 0x88, 0xda, 0xaa, 0x1d, 0xbe, 0x33
	.byte 0x03, 0xde, 0x61, 0xde, 0xdc, 0x67, 0xe4, 0x8f
	.byte 0x0c, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x8f, 0x12
	.byte 0x21, 0xd8, 0x12, 0xd8, 0x31, 0x03, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xda, 0x88, 0x32, 0x20, 0x00, 0x1d
	.byte 0x8e, 0x1a, 0x02, 0xbf, 0x04, 0x63, 0xbf, 0x08
	.byte 0x02, 0x00, 0x00, 0x78, 0x90, 0x00, 0x9f, 0x08
	.byte 0x20, 0xe8, 0x12, 0xe8, 0x80, 0xaf, 0x04, 0x80
	.byte 0x90, 0x26, 0xc7, 0xf9, 0xa8, 0x8f, 0x0c, 0x21
	.byte 0xc9, 0x8f, 0xdb, 0x12, 0x8f, 0x0c, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13
	.byte 0x04, 0x31, 0xf3, 0x07, 0xe4, 0xe0, 0x31, 0x8f
	.byte 0x12, 0x21, 0xc9, 0x8d, 0xda, 0x12, 0x0b, 0x02
	.byte 0x00, 0xc7, 0xf8, 0x89, 0xd8, 0x12, 0x28, 0xdb
	.byte 0x88, 0x1d, 0x59, 0x4a, 0x02, 0x8f, 0x0a, 0x3f
	.byte 0x00, 0x6e, 0x32, 0x8f, 0x0c, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04
	.byte 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x3e, 0x08, 0x00
	.byte 0xf2, 0x04, 0x52, 0x04, 0x02, 0x00, 0x00, 0xf2
	.byte 0x0e, 0x52, 0x04, 0x02, 0x00, 0x00, 0xc7, 0xf8
	.byte 0x89, 0xd8, 0x12, 0xf2, 0xcc, 0x51, 0x04, 0x31
	.byte 0x1e, 0xb6, 0xe4, 0x68, 0x16, 0xc7, 0xf8, 0x89
	.byte 0xd8, 0x12, 0x1d, 0x5f, 0x31, 0x02, 0xc7, 0xf8
	.byte 0x89, 0xd8, 0x12, 0xf2, 0xcc, 0x51, 0x04, 0x31
	.byte 0x1e, 0xe5, 0xe4, 0x9f, 0x08, 0x61, 0x9f, 0x08
	.byte 0x20, 0xe8, 0x12, 0xe8, 0x80, 0xaf, 0x04, 0x80
	.byte 0x90, 0x20, 0xd8, 0xcc, 0xff, 0x00, 0xd8, 0xcf
	.byte 0x80, 0x00, 0x77, 0x59, 0xff, 0x5e, 0xbf, 0x0a
	.byte 0x37, 0x0f, 0x02, 0x00

AudioChannel_Dispatch:
	ld l, (xde + 1)
	and l, 0x3F
	extz hl
	dec 1, hl
	cps hl, 0
	ret lt
	cp hl, 0x1A
	ret gt
	add hl, hl
	lda_24 xix, 0x00f703
	ldw_sri HL, 0x07, 0xF0, 0xEC
	lda_24 xix, 0x029e5b
	jp_ind 8, 0x07, 0xF0, 0xEC
; --- AudioChannel_DispatchTable: 25 handler stubs for audio channel commands ---
; Entry: WA = command parameter, BC = secondary parameter
; Each stub: zero-extends WA/BC, pushes channel index (0-3),
; calls a common audio handler via calr, then returns.
; First 3 entries redirect via jrl to alternate handler routines.
; Called from jump table indexed by HL.
AudioChannel_DispatchTable:
	extz	wa
	jrl	-3449
	extz	wa
	jrl	-3315
	extz	wa
	jrl	-3382
	extz	wa
	extz	bc
	pushw	0
	calr	62330
	ret
	extz	wa
	extz	bc
	pushw	1
	calr	62319
	ret
	extz	wa
	extz	bc
	pushw	2
	calr	62308
	ret
	extz	wa
	extz	bc
	pushw	3
	calr	62297
	ret
	extz	wa
	extz	bc
	pushw	0
	calr	63327
	ret
	extz	wa
	extz	bc
	pushw	1
	calr	63316
	ret
	extz	wa
	extz	bc
	pushw	2
	calr	63305
	ret
	extz	wa
	extz	bc
	pushw	3
	calr	63294
	ret
	extz	wa
	extz	bc
	pushw	0
	calr	64330
	ret
	extz	wa
	extz	bc
	pushw	1
	calr	64319
	ret
	extz	wa
	extz	bc
	pushw	2
	calr	64308
	ret
	extz	wa
	extz	bc
	pushw	3
	calr	64297
	ret
	extz	wa
	extz	bc
	pushw	0
	calr	62712
	ret
	extz	wa
	extz	bc
	pushw	1
	calr	62701
	ret
	extz	wa
	extz	bc
	pushw	2
	calr	62690
	ret
	extz	wa
	extz	bc
	pushw	3
	calr	62679
	ret
	extz	wa
	extz	bc
	pushw	0
	calr	63712
	ret
	extz	wa
	extz	bc
	pushw	1
	calr	63701
	ret
	extz	wa
	extz	bc
	pushw	2
	calr	63690
	ret
	extz	wa
	extz	bc
	pushw	3
	calr	63679
	ret
	extz	wa
	extz	bc
	pushw	0
	calr	64717
	ret
	extz	wa
	extz	bc
	pushw	1
	calr	64706
	ret
	extz	wa
	extz	bc
	pushw	2
	calr	64695
	ret
	extz	wa
	extz	bc
	pushw	3
	calr	64684
	ret
	ret

Voice_ModWheel_Apply:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), c
	ld (xsp + 12), a
	ld a, (xsp + 12)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0x80
	jr z, Voice_ModWheel_Apply_StereoLoopA
	cp a, 0x40
	jr z, Voice_ModWheel_Apply_StereoPath
	cp a, 0xC0
	jr z, Voice_ModWheel_Apply_StereoPath
	cps a, 0
	jrl nz, Voice_ModWheel_Apply_Exit

Voice_ModWheel_Apply_StereoPath:
	ldw (xsp + 8), 0x0
	cpw (xsp + 8), 0x2
	jrl nc, Voice_ModWheel_Apply_Exit

Voice_ModWheel_Apply_PolyPath:
	ld a, (xsp + 12)
	ldb_erp A, 0xF4
	extz iy
	ld a, (xsp + 10)
	ldb_erp A, 0xF0
	extz ix
	ld a, (xsp + 12)
	extz wa
	muls wa, 0x11F
	ld de, wa
	lda_24 xhl, 0x04136e
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, 0x17
	ld xiz, xbc
	add_sril_rm XIZ, 0x07, 0xEC, 0xE8
	ld wa, iy
	ld bc, ix
	ld xde, xiz
	calr AudioChannel_Dispatch
	incm 1, (xsp + 8)
	cpw (xsp + 8), 0x2
	jr c, Voice_ModWheel_Apply_PolyPath
	jr Voice_ModWheel_Apply_Exit

Voice_ModWheel_Apply_StereoLoopA:
	ld a, (xsp + 12)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xsp + 4), xwa
	ldw (xsp + 8), 0x0
	cpw (xsp + 8), 0x2
	jr nc, Voice_ModWheel_Apply_Exit

Voice_ModWheel_Apply_StereoLoopB:
	ld a, (xsp + 12)
	ldb_erp A, 0xF0
	extz ix
	ld a, (xsp + 10)
	ld l, a
	extz hl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, 0x15
	ld xde, xbc
	add xde, (xsp + 4)
	ld wa, ix
	ld bc, hl
	calr AudioChannel_Dispatch
	incm 1, (xsp + 8)
	cpw (xsp + 8), 0x2
	jr c, Voice_ModWheel_Apply_StereoLoopB

Voice_ModWheel_Apply_Exit:
	pop xiz
	lda xsp, (xsp + 10)
	ret

VoiceModWheel_DataTable_02A061:
	.byte 0xef, 0x6c, 0xd7, 0xfa, 0x04, 0xbf, 0x02, 0x43
	.byte 0xbf, 0x04, 0x41, 0x8f, 0x04, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04
	.byte 0x31, 0xe3, 0x07, 0xe4, 0xe0, 0x20, 0x88, 0x10
	.byte 0x21, 0xc9, 0xcc, 0xc0, 0xc9, 0xcf, 0x40, 0x66
	.byte 0x09, 0xc9, 0xcf, 0xc0, 0x66, 0x04, 0xc9, 0xd8
	.byte 0x6e, 0x50, 0xc7, 0xfb, 0xa8, 0xc7, 0xfb, 0xda
	.byte 0x6f, 0x48, 0x8f, 0x04, 0x21, 0xc9, 0x8f, 0xdb
	.byte 0x12, 0x8f, 0x02, 0x21, 0xc9, 0x8d, 0xda, 0x12
	.byte 0x8f, 0x04, 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x1f
	.byte 0x01, 0xd8, 0x89, 0xf2, 0x6e, 0x13, 0x04, 0x34
	.byte 0xc7, 0xfb, 0x89, 0xd8, 0x12, 0xd8, 0x09, 0x03
	.byte 0x00, 0xd8, 0x8d, 0xdd, 0xc8, 0x1d, 0x00, 0xe3
	.byte 0x07, 0xf0, 0xe4, 0x20, 0xf3, 0x07, 0xe0, 0xf4
	.byte 0x34, 0xdb, 0x88, 0xda, 0x89, 0xec, 0x8a, 0x1e
	.byte 0x56, 0xfd, 0xc7, 0xfb, 0x61, 0xc7, 0xfb, 0xda
	.byte 0x67, 0xb8, 0xd7, 0xfa, 0x05, 0xef, 0x64, 0x0e

Voice_Portamento_OnHandler:
	dec 4, xsp
	ld (xsp), c
	ld (xsp + 2), a
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0x80
	jr z, Voice_Portamento_OnHandler_Exit
	cp a, 0x40
	jr z, Voice_Portamento_OnHandler_Exit
	cp a, 0xC0
	jr z, Voice_Portamento_OnHandler_C0Mode
	cps a, 0
	jr nz, Voice_Portamento_OnHandler_Exit

Voice_Portamento_OnHandler_C0Mode:
	ld a, (xsp + 2)
	ld e, a
	extz de
	ld a, (xsp)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetSostenutoFlag
	ld a, (xsp + 2)
	extz wa
	lds bc, 1
	call AlgoType_StateWrite
	ld a, (xsp + 2)
	ld e, a
	extz de
	ld a, (xsp)
	ld c, a
	extz bc
	ld wa, de
	call VoiceAlloc_WithRoutingFlag
	ld a, (xsp + 2)
	extz wa
	call VoiceFlags_Aggregate
	ld a, (xsp + 2)
	extz wa
	call EnvTranspose_UpdateLoop
	ld a, (xsp + 2)
	extz wa
	call VoiceNoteParam_UpdateLoop
	ld a, (xsp + 2)
	extz wa
	call Voice_ActiveFlag_CheckAndLoad
	ld a, (xsp + 2)
	extz wa
	call Voice_SecondaryParam_Epilogue
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413ce
	lda_dri XSP, 0x07, 0xE4, 0xE0

Voice_Portamento_OnHandler_Exit:
	inc 4, xsp
	ret

Voice_PortamentoSlots_WriteHW:
	dec 6, xsp
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	call Voice_AllocateForRelease
	ld a, (xsp + 4)
	extz wa
	call Voice_SetLFO_ActiveFlag
	ld a, (xsp + 4)
	extz wa
	call Voice_AllocateForFull
	lda xwa, (xhl + 5)
	ld (xsp), xwa
	cp (xwa), 0x40
	jrl nc, Voice_PortamentoSlots_WriteHW_Exit

Voice_PortamentoSlots_WriteHW_LoopBody:
	ld xwa, (xsp)
	ld a, (xwa)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308f
	ldw_sri WA, 0x07, 0xE4, 0xE0
	and wa, 0x3C
	cp wa, 0x8
	jr z, Voice_PortamentoSlots_WriteHW_BranchSkip
	cp wa, 0x20
	jr z, Voice_PortamentoSlots_WriteHW_NopCont1
	cp wa, 0x10
	jr z, Voice_PortamentoSlots_WriteHW_NopCont1
	cps wa, 4
	jrl nz, Voice_PortamentoSlots_WriteHW_LoopStep

Voice_PortamentoSlots_WriteHW_NopCont1:
	res_dd8 7, 0x18
	ld xwa, (xsp)
	ld a, (xwa)
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xa200
	jr __jrt_nop_02A208
__jrt_nop_02A208:

Voice_PortamentoSlots_WriteHW_NopCont2:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld xwa, (xsp)
	ld a, (xwa)
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xa280
	jr __jrt_nop_02A22A
__jrt_nop_02A22A:

Voice_PortamentoSlots_WriteHW_NopCont3:
	nop
	nop
	nop
	jr Voice_PortamentoSlots_WriteHW_LoopStep

Voice_PortamentoSlots_WriteHW_BranchSkip:
	res_dd8 7, 0x18
	ld xwa, (xsp)
	ld a, (xwa)
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xa200
	jr __jrt_nop_02A24E
__jrt_nop_02A24E:

Voice_PortamentoSlots_WriteHW_NopCont4:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld xwa, (xsp)
	ld a, (xwa)
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xa280
	jr __jrt_nop_02A270
__jrt_nop_02A270:

Voice_PortamentoSlots_WriteHW_NopCont5:
	nop
	nop
	nop

Voice_PortamentoSlots_WriteHW_LoopStep:
	lds32 xwa, 1
	add (xsp), xwa
	ld xwa, (xsp)
	cp (xwa), 0x40
	jrl c, Voice_PortamentoSlots_WriteHW_LoopBody

Voice_PortamentoSlots_WriteHW_Exit:
	inc 6, xsp
	ret

; ===========================================================================
; Voice_CtrlChange - Process MIDI Control Change messages
; ===========================================================================
; Entry: XWA = pointer to 4-byte CC data:
;        +0 = status byte (0xBn where n=channel)
;        +1 = channel number (0-25)
;        +2 = controller number
;        +3 = controller value
; Exit:  Voice parameters updated based on CC number
; Notes: Handles standard MIDI CCs: Mod Wheel(1), Volume(7), Pan(10),
;        Expression(11), Sustain(64), Sostenuto(91), Soft(93), Portamento(94)
;        Plus proprietary CCs in 0x91-0x9D range for effects depth
; ===========================================================================
Voice_CtrlChange:
	push xiz
	ld xiz, xwa
	cp (xiz + 1), 0x1A
	jrl nc, Voice_CC_Exit
	ld a, (xiz + 2)
	cp a, 0x9D
	jrl z, Voice_CC_9D
	cp a, 0x9C
	jrl z, Voice_CC_9C
	cp a, 0x9B
	jrl z, Voice_CC_9B
	cp a, 0x97
	jrl z, Voice_CC_97
	cp a, 0x95
	jrl z, Voice_CC_95
	cp a, 0x91
	jrl z, Voice_CC_91
	cp a, 0x5E
	jrl z, Voice_CC_Portamento
	cp a, 0x5D
	jrl z, Voice_CC_Soft
	cp a, 0x5B
	jrl z, Voice_CC_Sostenuto
	cp a, 0x40
	jrl z, Voice_CC_Sustain
	cp a, 0xB
	jrl z, Voice_CC_Expression
	cp a, 0xA
	jr z, Voice_CC_Pan
	cps a, 7
	jr z, Voice_CC_Volume
	cps a, 1
	jr z, Voice_CC_ModWheel
	extz wa
	sub wa, 0x78
	cps wa, 0
	jrl lt, Voice_CC_Exit
	cp wa, 0xA
	jrl gt, Voice_CC_Exit
	add wa, wa
	lda_24 xix, 0x00f739
	ldw_sri WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0x02a306
	jp_ind 8, 0x07, 0xF0, 0xE0

Voice_CC_ModWheel:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_ModWheel_Apply
	jrl Voice_CC_Exit

Voice_CC_Volume:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetVolume
	ld a, (xiz + 1)
	extz wa
	call Voice_AllocateForFull
	ld xwa, xhl
	calr Voice_AllVoices_WriteAmplitude
	jrl Voice_CC_Exit

Voice_CC_Pan:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetPan
	ld a, (xiz + 1)
	extz wa
	call EnvTranspose_UpdateLoop
	jrl Voice_CC_Exit

Voice_CC_Expression:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetExpression
	ld a, (xiz + 1)
	extz wa
	call Voice_AllocateForFull
	ld xwa, xhl
	calr Voice_AllVoices_WriteAmplitude
	jrl Voice_CC_Exit

Voice_CC_Sustain:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetSustain
	ld a, (xiz + 1)
	extz wa
	call Voice_AllocateForSustain
	ld xwa, xhl
	lds bc, 0
	calr Voice_AllNotes_SustainRetrigger
	jrl Voice_CC_Exit

Voice_CC_Sostenuto:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetSostenuto
	jrl Voice_CC_Exit

Voice_CC_Soft:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetSoftPedal
	jrl Voice_CC_Exit

Voice_CC_Portamento:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_Portamento_OnHandler
	jrl Voice_CC_Exit
	ld a, (xiz + 1)
	extz wa
	calr Voice_PortamentoSlots_WriteHW
	jrl Voice_CC_Exit
	ld a, (xiz + 1)
	extz wa
	call Voice_NoteState_Clear
	jrl Voice_CC_Exit
	ld a, (xiz + 1)
	extz wa
	call Voice_SetLFO_ActiveFlag
	ld a, (xiz + 1)
	extz wa
	call Voice_AllocateForRelease
	ld xwa, xhl
	call Voice_ParamInit
	jrl Voice_CC_Exit
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetPortamentoRate
	jrl Voice_CC_Exit
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetPortamentoDepth
	ld a, (xiz + 1)
	extz wa
	call Voice_AllocateForFull
	ld xwa, xhl
	calr Voice_AllVoices_WritePan
	jrl Voice_CC_Exit
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetPortamentoTime
	jr Voice_CC_Exit

Voice_CC_91:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetReverbDepth
	jr Voice_CC_Exit

Voice_CC_95:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetChorusEnable
	jr Voice_CC_Exit

Voice_CC_97:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetChorusDepth
	jr Voice_CC_Exit

Voice_CC_9B:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetDelayDepth
	jr Voice_CC_Exit

Voice_CC_9C:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetDelayEnable
	jr Voice_CC_Exit

Voice_CC_9D:
	ld a, (xiz + 1)
	ld e, a
	extz de
	ld a, (xiz + 3)
	ld c, a
	extz bc
	ld wa, de
	calr Voice_CC_SetDelayFeedback

Voice_CC_Exit:
	pop xiz
	ret

Voice_ChanPressure:
	lda xsp, (xsp - 10)
	pushw_erp 0xFA
	ld (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp (xwa + 1), 0x1A
	jrl nc, Voice_ChanPressure_Exit
	ld xwa, (xsp + 8)
	ld a, (xwa + 1)
	ld (xsp + 6), a
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0x80
	jr z, Voice_ChanPressure_MonoLoopStart
	cp a, 0x40
	jr z, Voice_ChanPressure_StereoLoopStart
	cp a, 0xC0
	jr z, Voice_ChanPressure_StereoLoopStart
	cps a, 0
	jrl nz, Voice_ChanPressure_Exit

Voice_ChanPressure_StereoLoopStart:
	ld a, (xsp + 6)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xsp + 2), xwa
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 2
	jrl nc, Voice_ChanPressure_Exit

Voice_ChanPressure_StereoLoopBody:
	ld a, (xsp + 6)
	ldb_erp A, 0xF0
	extz ix
	ld xwa, (xsp + 8)
	ld a, (xwa + 3)
	ld l, a
	extz hl
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x3
	ld bc, wa
	add bc, 0x23
	ld xwa, (xsp + 2)
	stb_dri B, 0x07, 0xE0, 0xE4
	ld wa, ix
	ld bc, hl
	calr AudioChannel_Dispatch
	inc1b_erp 0xFB
	cpib_erp 0xFB, 2
	jr c, Voice_ChanPressure_StereoLoopBody
	jr Voice_ChanPressure_Exit

Voice_ChanPressure_MonoLoopStart:
	ld a, (xsp + 6)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xsp + 2), xwa
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 2
	jr nc, Voice_ChanPressure_Exit

Voice_ChanPressure_MonoLoopBody:
	ld a, (xsp + 6)
	ldb_erp A, 0xF0
	extz ix
	ld xwa, (xsp + 8)
	ld a, (xwa + 3)
	ld l, a
	extz hl
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x3
	ld bc, wa
	add bc, 0x21
	ld xwa, (xsp + 2)
	stb_dri B, 0x07, 0xE0, 0xE4
	ld wa, ix
	ld bc, hl
	calr AudioChannel_Dispatch
	inc1b_erp 0xFB
	cpib_erp 0xFB, 2
	jr c, Voice_ChanPressure_MonoLoopBody

Voice_ChanPressure_Exit:
	popw_erp 0xFA
	lda xsp, (xsp + 10)
	ret

Voice_PitchBend:
	cp (xwa + 1), 0x1A
	ret nc
	ld e, (xwa + 1)
	ld c, (xwa + 3)
	extz bc
	sll bc, 7
	ld a, (xwa + 2)
	extz wa
	extz xwa
	set 15, wa
	or bc, wa
	ld a, e
	extz wa
	muls wa, 0x11F
	lda_24 xhl, 0x04136e
	ld_sril3 XWA, 0x07, 0xEC, 0xE0
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0x80
	jr z, Voice_PitchBend_BranchB
	cp a, 0x40
	jr z, Voice_PitchBend_BranchA
	cp a, 0xC0
	jr z, Voice_PitchBend_BranchA
	cps a, 0
	ret nz

Voice_PitchBend_BranchA:
	ld l, e
	extz hl
	ld a, e
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	lda xde, (xwa + 20)
	ld wa, hl
	jrl AudioChannel_Dispatch

Voice_PitchBend_BranchB:
	ld a, e
	extz wa
	muls wa, 0x11F
	lda_24 xhl, 0x04136e
	ld_sril3 XHL, 0x07, 0xEC, 0xE0
	ld a, e
	extz wa
	lda xde, (xhl + 18)
	jrl AudioChannel_Dispatch

Voice_AllVoices_PortamentoReset:
	push xiz
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0x1A
	jr nc, Voice_AllVoices_PortamentoReset_NopCont1

Voice_AllVoices_PortamentoReset_LoopBody:
	stb_erp A, 0xFB
	extz wa
	call Voice_NoteState_Clear
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0x1A
	jr c, Voice_AllVoices_PortamentoReset_LoopBody

Voice_AllVoices_PortamentoReset_NopCont1:
	call Voice_AllocateForAny
	lda xwa, (xhl + 5)
	ld xiz, xwa
	cp (xiz), 0x40
	jr nc, Voice_AllVoices_PortamentoReset_Exit

Voice_AllVoices_PortamentoReset_NopCont2:
	res_dd8 7, 0x18
	ld a, (xiz)
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xa200
	jr __jrt_nop_02A6AF
__jrt_nop_02A6AF:

Voice_AllVoices_PortamentoReset_NopCont3:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld a, (xiz)
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xa280
	jr __jrt_nop_02A6CF
__jrt_nop_02A6CF:

Voice_AllVoices_PortamentoReset_LoopStep:
	nop
	nop
	nop
	inc 1, xiz
	cp (xiz), 0x40
	jr c, Voice_AllVoices_PortamentoReset_NopCont2

Voice_AllVoices_PortamentoReset_Exit:
	pop xiz
	ret

Voice_SetPitchBendRangeAndApply:
	exts wa
	calr Voice_SetMasterTune
	call Voice_AllocateForAny
	ld xwa, xhl
	jrl Voice_AllVoices_WritePan
	extz wa
	calr Voice_SetKeyShiftEnable
	call Voice_AllocateForAny
	ld xwa, xhl
	jrl Voice_AllVoices_WritePan

Voice_PerVoice_PortamentoPitchUpdate:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	call Voice_NoteState_Clear
	ld a, (xsp)
	extz wa
	call Voice_SetLFO_ActiveFlag
	ld a, (xsp)
	ld l, a
	extz hl
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041381
	ldb_sri A, 0x07, 0xE4, 0xE0
	ldb_erp A, 0xF0
	extz ix
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041382
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld e, a
	extz de
	ld wa, hl
	ld bc, ix
	call VoiceInit_Dispatcher
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0x80
	jr z, Voice_PerVoice_PortamentoPitchUpdate_Exit
	cp a, 0x40
	jr z, Voice_PerVoice_PortamentoPitchUpdate_BranchB
	cp a, 0xC0
	jr z, Voice_PerVoice_PortamentoPitchUpdate_BranchA
	cps a, 0
	jr nz, Voice_PerVoice_PortamentoPitchUpdate_Exit

Voice_PerVoice_PortamentoPitchUpdate_BranchA:
	ld a, (xsp)
	extz wa
	call VoiceSlot_FullInit
	jr Voice_PerVoice_PortamentoPitchUpdate_Exit

Voice_PerVoice_PortamentoPitchUpdate_BranchB:
	ld a, (xsp)
	extz wa
	call Voice_PortamentoTargets_SetAll
	ld a, (xsp)
	extz wa
	call VoiceSlot_AltInit

Voice_PerVoice_PortamentoPitchUpdate_Exit:
	inc 2, xsp
	ret

Voice_AllVoices_PortamentoUpdate:
	pushw_erp 0xFA
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0x1A
	jr nc, Voice_AllVoices_PortamentoUpdate_Exit

Voice_AllVoices_PortamentoUpdate_LoopBody:
	stb_erp A, 0xFB
	extz wa
	calr Voice_PerVoice_PortamentoPitchUpdate
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0x1A
	jr c, Voice_AllVoices_PortamentoUpdate_LoopBody

Voice_AllVoices_PortamentoUpdate_Exit:
	popw_erp 0xFA
	ret

Voice_SystemMsg:
	ld c, (xwa + 2)
	cp c, 0x99
	jrl z, Voice_SystemMsg_DispatchEntry2
	cp c, 0x92
	jrl z, Voice_SystemMsg_DispatchEntry1
	cp c, 0x91
	jr z, Voice_SystemMsg_DispatchEntry0
	cp c, 0x9
	jr z, Voice_SystemMsg_DispatchTable
	extz bc
	sub bc, 0x80
	cps bc, 0
	ret lt
	cps bc, 7
	jr le, Voice_SystemMsg_DispatchJump
	sub bc, 0x1B
	cp bc, 0x8
	ret lt
	cp bc, 0x16
	ret gt

Voice_SystemMsg_DispatchJump:
	add bc, bc
	lda_24 xix, 0x00f74f
	ldw_sri BC, 0x07, 0xF0, 0xE4
	lda_24 xix, 0x02a7fc
	jp_ind 8, 0x07, 0xF0, 0xE4

Voice_SystemMsg_DispatchTable:
	ld a, (xwa + 3)
	extz wa
	jrl Voice_SetPolyphonyMode
	ld a, (xwa + 3)
	extz wa
	jrl VoiceCC_Stub_Ret1
	ld a, (xwa + 3)
	extz wa
	jrl VoiceCC_Stub_Ret2
	ld a, (xwa + 3)
	jrl Voice_SetPitchBendRangeAndApply
	ld a, (xwa + 3)
	jrl Voice_SetPitchBendRange
	ld a, (xwa + 3)
	extz wa
	jrl Voice_SetKeyShiftEnable
	ld a, (xwa + 3)
	extz wa
	jrl Voice_SetParam_04134D
	ld a, (xwa + 3)
	extz wa
	jrl Voice_SetRhythmMode

Voice_SystemMsg_DispatchEntry0:
	ld a, (xwa + 3)
	extz wa
	jrl Voice_SetParam_04134B

Voice_SystemMsg_DispatchEntry1:
	jrl Voice_AllVoices_PortamentoUpdate

Voice_SystemMsg_DispatchEntry2:
	ld a, (xwa + 3)
	extz wa
	jrl Voice_SetCCMaxFlag
	jrl Voice_AllVoices_PortamentoReset
	ld a, (xwa + 3)
	extz wa
	ld bc, wa
	lds wa, 0
	jrl Voice_WriteChannelAssign
	ld a, (xwa + 3)
	extz wa
	ld bc, wa
	lds wa, 1
	jrl Voice_WriteChannelAssign
	ld a, (xwa + 3)
	extz wa
	ld bc, wa
	lds wa, 2
	jrl Voice_WriteChannelAssign
	ld a, (xwa + 3)
	extz wa
	ld bc, wa
	lds wa, 3
	jrl Voice_WriteChannelAssign
	ld a, (xwa + 3)
	extz wa
	ld bc, wa
	lds wa, 4
	jrl Voice_WriteChannelAssign
	ld a, (xwa + 3)
	extz wa
	ld bc, wa
	lds wa, 5
	jrl Voice_WriteChannelAssign
	ld a, (xwa + 3)
	extz wa
	ld bc, wa
	lds wa, 6
	jrl Voice_WriteChannelAssign
	ld a, (xwa + 3)
	extz wa
	ld bc, wa
	lds wa, 7
	jrl Voice_WriteChannelAssign
	ld a, (xwa + 3)
	extz wa
	ld bc, wa
	ldw wa, 0x8
	jrl Voice_WriteChannelAssign
	ld a, (xwa + 3)
	extz wa
	ld bc, wa
	ldw wa, 0x9
	jrl Voice_WriteChannelAssign
	ld a, (xwa + 3)
	extz wa
	ld bc, wa
	ldw wa, 0xA
	jrl Voice_WriteChannelAssign
	ld a, (xwa + 3)
	extz wa
	ld bc, wa
	ldw wa, 0xB
	jrl Voice_WriteChannelAssign
	ld a, (xwa + 3)
	extz wa
	jrl Voice_AllVoices_UpdateVelocity
	ld a, (xwa + 3)
	extz wa
	jrl Voice_SetMonoMode
	ret

Voice_ResetAllControllers:
	pushw_erp 0xFA
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0x1A
	jrl nc, Voice_ResetAllControllers_PostLoop

Voice_ResetAllControllers_LoopBody:
	stb_erp A, 0xFB
	extz wa
	lds bc, 0
	calr Voice_ModWheel_Apply
	stb_erp A, 0xFB
	extz wa
	ldw bc, 0x7F
	calr Voice_CC_SetVolume
	stb_erp A, 0xFB
	extz wa
	ldw bc, 0x40
	calr Voice_CC_SetPan
	stb_erp A, 0xFB
	extz wa
	ldw bc, 0x7F
	calr Voice_CC_SetExpression
	stb_erp A, 0xFB
	extz wa
	lds bc, 0
	calr Voice_CC_SetSustain
	stb_erp A, 0xFB
	extz wa
	lds bc, 0
	calr Voice_CC_SetSostenuto
	stb_erp A, 0xFB
	extz wa
	lds bc, 0
	calr Voice_CC_SetSoftPedal
	stb_erp A, 0xFB
	extz wa
	lds bc, 0
	calr Voice_Portamento_OnHandler
	stb_erp A, 0xFB
	extz wa
	calr Voice_PortamentoSlots_WriteHW
	stb_erp A, 0xFB
	extz wa
	call Voice_NoteState_Clear
	stb_erp A, 0xFB
	extz wa
	call Voice_SetLFO_ActiveFlag
	stb_erp A, 0xFB
	extz wa
	lds bc, 2
	calr Voice_CC_SetPortamentoRate
	stb_erp A, 0xFB
	extz wa
	ldw bc, 0x80
	calr Voice_CC_SetPortamentoDepth
	stb_erp A, 0xFB
	extz wa
	ldw bc, 0x40
	calr Voice_CC_SetPortamentoTime
	stb_erp A, 0xFB
	extz wa
	lds bc, 0
	calr Voice_CC_SetReverbDepth
	stb_erp A, 0xFB
	extz wa
	lds bc, 0
	calr Voice_CC_SetChorusEnable
	stb_erp A, 0xFB
	extz wa
	lds bc, 6
	calr Voice_CC_SetChorusDepth
	stb_erp A, 0xFB
	extz wa
	lds bc, 1
	calr Voice_CC_SetDelayDepth
	stb_erp A, 0xFB
	extz wa
	lds bc, 0
	calr Voice_CC_SetDelayEnable
	stb_erp A, 0xFB
	extz wa
	lds bc, 0
	calr Voice_CC_SetDelayFeedback
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0x1A
	jrl c, Voice_ResetAllControllers_LoopBody

Voice_ResetAllControllers_PostLoop:
	lds wa, 2
	calr Voice_SetPolyphonyMode
	ldw wa, 0x7F
	calr VoiceCC_Stub_Ret1
	ldw wa, 0x7F
	calr VoiceCC_Stub_Ret2
	ldw wa, 0x40
	calr Voice_SetPitchBendRangeAndApply
	lds wa, 0
	calr Voice_SetPitchBendRange
	lds wa, 0
	calr Voice_SetKeyShiftEnable
	lds wa, 0
	calr Voice_SetParam_04134D
	lds wa, 0
	calr Voice_SetRhythmMode
	lds wa, 0
	calr Voice_SetParam_04134B
	calr Voice_AllVoices_PortamentoUpdate
	lds wa, 0
	calr Voice_SetCCMaxFlag
	calr Voice_AllVoices_PortamentoReset
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0x0C
	jr nc, Voice_ResetAllControllers_ChanModeExit

Voice_ResetAllControllers_ChanModeLoop:
	stb_erp A, 0xFB
	extz wa
	lds bc, 0
	calr Voice_WriteChannelAssign
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0x0C
	jr c, Voice_ResetAllControllers_ChanModeLoop

Voice_ResetAllControllers_ChanModeExit:
	lds wa, 1
	calr Voice_AllVoices_UpdateVelocity
	lds wa, 0
	calr Voice_SetMonoMode
	popw_erp 0xFA
	ret

Voice_PortamentoTargets_SetAll:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ldiw_erp 0xFA, 0
	cpiw_erp 0xFA, 4
	jrl nc, Voice_PortamentoTargets_SetAll_Exit

Voice_PortamentoTargets_SetAll_LoopBody:
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	add xwa, xhl
	ld xwa, (xwa)
	ld a, (xwa + 2)
	ldb_erp A, 0xF8
	extz iz
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	add xwa, xhl
	ld xwa, (xwa)
	ld a, (xwa + 3)
	extz wa
	sll wa, 8
	or iz, wa
	stw_erp WA, 0xFA
	extz xwa
	add xwa, xwa
	ld xde, xwa
	add xde, 0x102
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	ld xbc, xwa
	add xbc, xde
	ld wa, iz
	and wa, 0xFFF
	ld (xbc), wa
	inc1w_erp 0xFA
	cpiw_erp 0xFA, 4
	jrl c, Voice_PortamentoTargets_SetAll_LoopBody

Voice_PortamentoTargets_SetAll_Exit:
	pop xiz
	inc 2, xsp
	ret

Voice_PortamentoTarget_SetSlot:
	extz bc
	muls bc, 0x25
	ld de, bc
	add de, 0x6E
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri A, 0x07, 0xE0, 0xE8
	lda_24 xwa, 0x00f8b0
	ld (xbc + 4), xwa
	ret

Voice_PortamentoTarget_ComputePitch:
	ld e, c
	extz de
	muls de, 0x25
	ld ix, de
	add ix, 0x6E
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xhl, 0x041368
	exts xde
	add xde, xhl
	ld_sril3 XDE, 0x07, 0xE8, 0xF0
	ld e, (xde + 3)
	and e, 0x30
	srl e, 4
	ldb_erp E, 0xF0
	extz ix
	ldl_da xde, 0x045314
	ld xhl, (xde + 112)
	ldl_da xde, 0x045314
	ldw_sri0 DE, (xde + 0x00ec)
	extz bc
	muls bc, 0x25
	ld iy, bc
	add iy, 0x6E
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri A, 0x07, 0xE0, 0xF4
	ld wa, de
	mul xwa, xix
	add xwa, xhl
	addda32_24 xwa, 283408
	ld (xbc + 8), xwa
	ret

Voice_UpdateFlagsFromSlot:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041368
	stb_dri B, 0x07, 0xE8, 0xE4
	stb_dri B, 0xE9, 0x02, 0x01
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	inc 2, xwa
	cpw (xde), 0x0
	jr z, Voice_UpdateFlagsFromSlot_BranchA
	ormi16 (xwa), 0x1
	jr Voice_UpdateFlagsFromSlot_BranchB

Voice_UpdateFlagsFromSlot_BranchA:
	andmi16 (xwa), 0xFFFE

Voice_UpdateFlagsFromSlot_BranchB:
	cpw (xde + 2), 0x0
	jr z, Voice_UpdateFlagsFromSlot_BranchC
	ormi16 (xwa), 0x2
	jr Voice_UpdateFlagsFromSlot_BranchD

Voice_UpdateFlagsFromSlot_BranchC:
	andmi16 (xwa), 0xFFFD

Voice_UpdateFlagsFromSlot_BranchD:
	cpw (xde + 4), 0x0
	jr z, Voice_UpdateFlagsFromSlot_BranchE
	ormi16 (xwa), 0x4
	jr Voice_UpdateFlagsFromSlot_BranchF

Voice_UpdateFlagsFromSlot_BranchE:
	andmi16 (xwa), 0xFFFB

Voice_UpdateFlagsFromSlot_BranchF:
	cpw (xde + 6), 0x0
	jr z, Voice_UpdateFlagsFromSlot_Exit
	ormi16 (xwa), 0x8
	ret

Voice_UpdateFlagsFromSlot_Exit:
	andmi16 (xwa), 0xFFF7
	ret

Voice_Selector_Unpack3Groups:
	ld l, e
	extz hl
	muls hl, 0x3
	lda_24 xix, 0x00f77d
	ldb_sri L, 0x07, 0xF0, 0xEC
	ldb_erp L, 0xF0
	extz ix
	ld hl, bc
	and hl, 0xF
	lda_dri XSP, 0x07, 0xE0, 0xF0
	srl bc, 4
	ld l, e
	extz hl
	muls hl, 0x3
	lda_24 xix, 0x00f77e
	ldb_sri L, 0x07, 0xF0, 0xEC
	ldb_erp L, 0xF0
	extz ix
	ld hl, bc
	and hl, 0xF
	lda_dri XSP, 0x07, 0xE0, 0xF0
	srl bc, 4
	extz de
	muls de, 0x3
	lda_24 xhl, 0x00f77f
	ldb_sri E, 0x07, 0xEC, 0xE8
	extz de
	and bc, 0xF
	lda_dri XHL, 0x07, 0xE0, 0xE8
	ret

Voice_Selector_FindBestSlot:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 14), xde
	ld (xsp + 18), xbc
	ld xiz, xwa
	lda xwa, (xsp + 4)
	ld bc, (xiz)
	lds de, 0
	calr Voice_Selector_Unpack3Groups
	lda xwa, (xsp + 4)
	ld bc, (xiz + 2)
	lds de, 1
	calr Voice_Selector_Unpack3Groups
	lda xwa, (xsp + 4)
	ld bc, (xiz + 4)
	lds de, 2
	calr Voice_Selector_Unpack3Groups
	ldb e, 0xFF
	ldb l, 0xFF
	ld xwa, (xsp + 18)
	ld (xwa), 0x0
	ldb d, 0x0
	cp d, 0x9
	jr nc, Voice_Selector_FindBestSlot_InnerStep

Voice_Selector_FindBestSlot_InnerLoop:
	cp l, 0xFF
	jr nz, Voice_Selector_FindBestSlot_SlotCheck
	ld a, d
	extz wa
	lda xbc, (xsp + 4)
	cpib_sri 0x07, 0xE4, 0xE0, 0x00
	jr z, Voice_Selector_FindBestSlot_SlotCheck
	ld l, d

Voice_Selector_FindBestSlot_SlotCheck:
	ld a, d
	extz wa
	lda xbc, (xsp + 4)
	cpib_sri 0x07, 0xE4, 0xE0, 0x04
	jr c, Voice_Selector_FindBestSlot_Update
	ld xwa, (xsp + 18)
	incm8 1, (xwa)
	cp e, 0xFF
	jr nz, Voice_Selector_FindBestSlot_Update
	ld e, d

Voice_Selector_FindBestSlot_Update:
	inc 1, d
	cp d, 0x9
	jr c, Voice_Selector_FindBestSlot_InnerLoop

Voice_Selector_FindBestSlot_InnerStep:
	cp e, 0xFF
	jr z, Voice_Selector_FindBestSlot_OuterStep
	ld xwa, (xsp + 14)
	ld (xwa), e
	ld a, e
	extz wa
	lda xbc, (xsp + 4)
	ld xde, (xsp + 26)
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld (xde), a
	jr Voice_Selector_FindBestSlot_Exit

Voice_Selector_FindBestSlot_OuterStep:
	ld xwa, (xsp + 14)
	ld (xwa), l
	ld a, l
	extz wa
	lda xbc, (xsp + 4)
	ld xde, (xsp + 26)
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld (xde), a

Voice_Selector_FindBestSlot_Exit:
	pop xiz
	lda xsp, (xsp + 18)
	retd 0x4

Voice_Selector_ComputeMixWeights:
	dec 8, xsp
	ld (xsp + 6), a
	ld a, (xsp + 6)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04146a
	stb_dri C, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 4)
	ld xbc, xwa
	lda xwa, (xsp + 2)
	ld xde, xwa
	lda xwa, (xsp)
	push xwa
	ld xwa, xhl
	calr Voice_Selector_FindBestSlot
	ld a, (xsp + 6)
	extz wa
	muls wa, 0x11F
	ld de, wa
	lda_24 xhl, 0x041476
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	lda_24 xbc, 0x00f786
	ldw_sri WA, 0x07, 0xE4, 0xE0
	stw_dri WA, 0x07, 0xEC, 0xE8
	ld a, (xsp + 6)
	extz wa
	muls wa, 0x11F
	ld de, wa
	lda_24 xhl, 0x04147a
	ld a, (xsp + 2)
	extz wa
	add wa, wa
	lda_24 xbc, 0x00f79a
	ldw_sri WA, 0x07, 0xE4, 0xE0
	stw_dri WA, 0x07, 0xEC, 0xE8
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	lda_24 xbc, 0x00f7d2
	ldw_sri DE, 0x07, 0xE4, 0xE0
	ld a, (xsp + 2)
	extz wa
	add wa, wa
	lda_24 xbc, 0x00f7ac
	add_sriw_rm DE, 0x07, 0xE4, 0xE0
	ld a, (xsp)
	extz wa
	add wa, wa
	lda_24 xbc, 0x00f7be
	add_sriw_rm DE, 0x07, 0xE4, 0xE0
	ld a, (xsp + 6)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041478
	stw_dri DE, 0x07, 0xE4, 0xE0
	inc 8, xsp
	ret

Voice_InitFromSlot:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	calr Voice_UpdateFlagsFromSlot
	ld a, (xsp)
	extz wa
	calr Voice_Selector_ComputeMixWeights
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041472
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041473
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041474
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041475
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	inc 2, xsp
	ret

VoiceSlot_DataTable_02AE22:
	dec	2, xsp
	ld	(xsp), a
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xde, 267112
	lda_rr	xde, xde, wa
	lda	xde, (xde+258)
	.byte 0x92, 0x3c, 0x00, 0xff
	ld	a, c
	extz	wa
	or	(xde), wa
	ld	a, (xsp)
	extz	wa
	.byte 0x1e, 0x35, 0xfd
	ld	a, (xsp)
	extz	wa
	.byte 0x1e, 0xae, 0xfe
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xde, 267112
	lda_rr	xde, xde, wa
	lda	xde, (xde+258)
	.byte 0x9a, 0x04, 0x3c, 0xf0, 0xff
	ld	a, c
	and	a, 15
	extz	wa
	or	(xde+4), wa
	.byte 0x9a, 0x02, 0x3c, 0xf0, 0xff
	srl	c, 4
	ld	a, c
	extz	wa
	or	(xde+2), wa
	ld	a, (xsp)
	extz	wa
	.byte 0x1e, 0xeb, 0xfc
	ld	a, (xsp)
	extz	wa
	.byte 0x1e, 0x64, 0xfe
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xde, 267112
	lda_rr	xde, xde, wa
	lda	xde, (xde+258)
	.byte 0x9a, 0x04, 0x3c, 0x0f, 0xff
	ld	a, c
	sll	a, 4
	extz	wa
	or	(xde+4), wa
	.byte 0x9a, 0x02, 0x3c, 0x0f, 0xff
	and	c, 240
	ld	a, c
	extz	wa
	or	(xde+2), wa
	ld	a, (xsp)
	extz	wa
	.byte 0x1e, 0xa1, 0xfc
	ld	a, (xsp)
	extz	wa
	.byte 0x1e, 0x1a, 0xfe
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xde, 267112
	lda_rr	xde, xde, wa
	lda	xde, (xde+258)
	.byte 0x92, 0x3c, 0xff, 0xf0
	ld	a, c
	and	a, 15
	extz	wa
	sll	wa, 8
	or	(xde), wa
	.byte 0x9a, 0x04, 0x3c, 0xff, 0xf0
	and	c, 240
	ld	a, c
	extz	wa
	sll	wa, 4
	or	(xde+4), wa
	ld	a, (xsp)
	extz	wa
	.byte 0x1e, 0x53, 0xfc
	ld	a, (xsp)
	extz	wa
	.byte 0x1e, 0xcc, 0xfd
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xde, 267112
	lda_rr	xde, xde, wa
	lda	xde, (xde+258)
	.byte 0x9a, 0x02, 0x3c, 0xff, 0xf0
	ld	a, c
	and	a, 15
	extz	wa
	sll	wa, 8
	or	(xde+2), wa
	srl	c, 4
	ld	a, c
	extz	wa
	ld	(xde+6), wa
	ld	a, (xsp)
	extz	wa
	.byte 0x1e, 0x0b, 0xfc
	ld	a, (xsp)
	extz	wa
	.byte 0x1e, 0x84, 0xfd
	inc	2, xsp
	ret
	ld	e, a
	extz	de
	muls	de, 287
	ld	hl, de
	lda_24	xix, 267378
	ld	e, c
	sra	e, 4
	sla	e, 2
	st_rrb	e, xix, hl
	extz	wa
	muls	wa, 287
	ld	de, wa
	lda_24	xhl, 267379
	ld	a, c
	sla	a, 4
	sra	a, 4
	ld	c, a
	add	a, c
	st_rrb	a, xhl, de
	ret
	ld	e, a
	extz	de
	muls	de, 287
	ld	hl, de
	lda_24	xix, 267380
	ld	e, c
	sra	e, 4
	sla	e, 2
	st_rrb	e, xix, hl
	extz	wa
	muls	wa, 287
	ld	de, wa
	lda_24	xhl, 267381
	ld	a, c
	sla	a, 4
	sra	a, 4
	sla	a, 3
	st_rrb	a, xhl, de
	ret

Voice_SignedClamp:
	ld l, c
	exts hl
	ld c, (xwa)
	extz bc
	add bc, hl
	cp bc, de
	jr le, Voice_SignedClamp_ClampHi
	ld bc, de

Voice_SignedClamp_ClampHi:
	cp bc, (xsp + 4)
	jr ge, Voice_SignedClamp_ClampLo
	ld bc, (xsp + 4)

Voice_SignedClamp_ClampLo:
	ld (xwa), c
	retd 0x2

Voice_Slot_CalcArticParams:
	dec 8, xsp
	push xiz
	ld (xsp + 10), a
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041474
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld (xsp + 6), a
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041475
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld (xsp + 8), a
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413d6
	ld_sril3 XIZ, 0x07, 0xE4, 0xE0
	ldw (xsp + 4), 0x0
	cpw (xsp + 4), 0x4
	jrl nc, Voice_Slot_CalcArticParams_Exit

Voice_Slot_CalcArticParams_LoopBody:
	ld wa, (xsp + 4)
	extz xwa
	add xwa, xwa
	ld xde, xwa
	add xde, 0x102
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	add xwa, xde
	ld bc, (xwa)
	ld a, c
	ld (xiz + 2), a
	andmi8 (xiz + 3), 0xF0
	ld wa, bc
	srl wa, 8
	and wa, 0xF
	or (xiz + 3), a
	cpw (xsp + 4), 0x3
	jr nc, Voice_Slot_CalcArticParams_Type3Branch
	lda xde, (xiz + 39)
	ld a, (xsp + 6)
	ld c, a
	exts bc
	pushw 0x0
	ld xwa, xde
	ldw de, 0x64
	calr Voice_SignedClamp
	lda xde, (xiz + 45)
	ld a, (xsp + 8)
	ld c, a
	exts bc
	pushw 0x0
	ld xwa, xde
	ldw de, 0x64
	calr Voice_SignedClamp
	jr Voice_Slot_CalcArticParams_LoopStep

Voice_Slot_CalcArticParams_Type3Branch:
	lda xde, (xiz + 23)
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041472
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld c, a
	exts bc
	pushw 0x0
	ld xwa, xde
	ldw de, 0x7F
	calr Voice_SignedClamp
	lda xde, (xiz + 41)
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041473
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld c, a
	exts bc
	pushw 0x0
	ld xwa, xde
	ldw de, 0x64
	calr Voice_SignedClamp
	lda xde, (xiz + 43)
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041473
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld c, a
	exts bc
	pushw 0x0
	ld xwa, xde
	ldw de, 0x64
	calr Voice_SignedClamp

Voice_Slot_CalcArticParams_LoopStep:
	incm 1, (xsp + 4)
	lda xiz, (xiz + 81)
	cpw (xsp + 4), 0x4
	jrl c, Voice_Slot_CalcArticParams_LoopBody

Voice_Slot_CalcArticParams_Exit:
	pop xiz
	inc 8, xsp
	ret

Voice_Slot_CalcAmpNibble:
	extz wa
	muls wa, 0x11F
	lda_24 xhl, 0x041368
	stb_dri C, 0x07, 0xEC, 0xE0
	stb_dri C, 0xED, 0x02, 0x01
	ld a, c
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x043094
	ldw_sri WA, 0x07, 0xE4, 0xE0
	srl wa, 8
	add wa, 0xC
	cp wa, 0x24
	jr c, Voice_Slot_CalcAmpNibble_BranchA
	ld a, e
	extz wa
	add wa, wa
	ldw_sri HL, 0x07, 0xEC, 0xE0
	jr Voice_Slot_CalcAmpNibble_Exit

Voice_Slot_CalcAmpNibble_BranchA:
	ld a, e
	extz wa
	add wa, wa
	ldw_sri BC, 0x07, 0xEC, 0xE0
	and bc, 0xF
	ld a, e
	extz wa
	add wa, wa
	ldw_sri WA, 0x07, 0xEC, 0xE0
	srl wa, 4
	and wa, 0xF
	cp bc, wa
	jr nc, Voice_Slot_CalcAmpNibble_BranchB
	ld a, e
	extz wa
	add wa, wa
	ldw_sri HL, 0x07, 0xEC, 0xE0
	and hl, 0xFF0
	jr Voice_Slot_CalcAmpNibble_Exit

Voice_Slot_CalcAmpNibble_BranchB:
	sll bc, 4
	ld a, e
	extz wa
	add wa, wa
	ldw_sri HL, 0x07, 0xEC, 0xE0
	and hl, 0xF00
	or hl, bc

Voice_Slot_CalcAmpNibble_Exit:
	ret

Voice_Slot_FindOctaveOffset:
	extz wa
	muls wa, 0x11F
	lda_24 xhl, 0x041368
	stb_dri D, 0x07, 0xEC, 0xE0
	stb_dri D, 0xF1, 0x02, 0x01
	ldb l, 0x0
	ld a, c
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x043094
	ldw_sri WA, 0x07, 0xE4, 0xE0
	srl wa, 8
	sub wa, 0xC
	cp wa, 0x54
	jr c, Voice_Slot_FindOctaveOffset_BranchB

Voice_Slot_FindOctaveOffset_BranchA:
	sub wa, 0xC
	inc 1, l
	cp wa, 0x54
	jr nc, Voice_Slot_FindOctaveOffset_BranchA

Voice_Slot_FindOctaveOffset_BranchB:
	cps l, 0
	jr nz, Voice_Slot_FindOctaveOffset_BranchC
	ld a, e
	extz wa
	add wa, wa
	ldw_sri HL, 0x07, 0xF0, 0xE0
	jrl Voice_Slot_FindOctaveOffset_Exit

Voice_Slot_FindOctaveOffset_BranchC:
	cps l, 1
	jr nz, Voice_Slot_FindOctaveOffset_BranchD
	ld a, e
	extz wa
	add wa, wa
	ldw_sri HL, 0x07, 0xF0, 0xE0
	ldb h, 0x0
	ld a, e
	extz wa
	add wa, wa
	ldw_sri BC, 0x07, 0xF0, 0xE0
	srl bc, 4
	and bc, 0xF
	ld a, e
	extz wa
	add wa, wa
	ldw_sri WA, 0x07, 0xF0, 0xE0
	srl wa, 8
	and wa, 0xF
	cp bc, wa
	ret nc
	sll wa, 4
	and hl, 0xF
	or hl, wa
	jr Voice_Slot_FindOctaveOffset_Exit

Voice_Slot_FindOctaveOffset_BranchD:
	ld a, e
	extz wa
	add wa, wa
	ldw_sri HL, 0x07, 0xF0, 0xE0
	and hl, 0xF
	ld a, e
	extz wa
	add wa, wa
	ldw_sri BC, 0x07, 0xF0, 0xE0
	srl bc, 4
	and bc, 0xF
	ld a, e
	extz wa
	add wa, wa
	ldw_sri WA, 0x07, 0xF0, 0xE0
	srl wa, 8
	and wa, 0xF
	cp hl, bc
	jr nc, Voice_Slot_FindOctaveOffset_BranchF
	cp bc, wa
	jr nc, Voice_Slot_FindOctaveOffset_BranchE
	ld hl, wa
	jr Voice_Slot_FindOctaveOffset_Exit

Voice_Slot_FindOctaveOffset_BranchE:
	ld hl, bc
	jr Voice_Slot_FindOctaveOffset_Exit

Voice_Slot_FindOctaveOffset_BranchF:
	cp hl, wa
	ret nc
	ld hl, wa

Voice_Slot_FindOctaveOffset_Exit:
	ret

Voice_KeyIndex_Pack3Nibbles:
	ld hl, wa
	srl hl, 8
	and hl, 0xF
	ld bc, hl
	mul bc, 0x51
	ld hl, bc
	ld bc, wa
	srl bc, 4
	and bc, 0xF
	mul bc, 0x9
	add hl, bc
	and wa, 0xF
	add hl, wa
	ret

Voice_Slot_LoadPitchOffset_A:
	ld xbc, (xwa + 35)
	ldw_sri0 BC, (xbc + 0x010e)
	add (xwa + 13), bc
	ret

Voice_Slot_LoadPitchOffset_B:
	ld xbc, (xwa + 35)
	ldw_sri0 BC, (xbc + 0x0110)
	add (xwa + 13), bc
	ret

Voice_Slot_ApplyPortamentoDelta:
	dec 8, xsp
	push xiz
	ld (xsp + 8), xwa
	ld xwa, (xsp + 8)
	ld xiz, (xwa + 35)
	ldb_sri0 A, (xiz + 0x010a)
	ld c, a
	exts bc
	ld xwa, (xsp + 8)
	add (xwa + 13), bc
	bit_dri 7, 0xF9, 0x18, 0x01
	jr z, Voice_Slot_ApplyPortamentoDelta_BranchA
	ei 6
	ldda32 xwa, 4160
	stl_dri XWA, 0xF9, 0x14, 0x01
	ei 0
	jrl Voice_Slot_ApplyPortamentoDelta_Exit

Voice_Slot_ApplyPortamentoDelta_BranchA:
	ei 6
	ldda32 xwa, 4160
	ld (xsp + 4), xwa
	ld_sril XWA, (xiz + 0x0114)
	sub (xsp + 4), xwa
	ei 0
	ld xwa, (xsp + 4)
	cp xwa, 0x7FFF
	jr ule, Voice_Slot_ApplyPortamentoDelta_BranchB
	ld xwa, 0x7FFF
	ld (xsp + 4), xwa

Voice_Slot_ApplyPortamentoDelta_BranchB:
	ldb_sri0 A, (xiz + 0x010b)
	ld c, a
	exts bc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 23)
	ld a, (xwa + 41)
	ld e, a
	extz de
	add de, bc
	ldw wa, 0x64
	cp de, 0x64
	jr gt, Voice_Slot_ApplyPortamentoDelta_BranchC
	ld wa, de

Voice_Slot_ApplyPortamentoDelta_BranchC:
	ld de, wa
	lds wa, 0
	cps de, 0
	jr lt, Voice_Slot_ApplyPortamentoDelta_BranchD
	ld wa, de

Voice_Slot_ApplyPortamentoDelta_BranchD:
	ld de, wa
	add wa, wa
	lda_24 xbc, 0x00f7e6
	ldw_sri WA, 0x07, 0xE4, 0xE0
	extz xwa
	ld xbc, (xsp + 4)
	call FP_MulAccum64
	ld xwa, xhl
	srl xwa, 10
	cp xwa, 0xFFF
	jr ule, Voice_Slot_ApplyPortamentoDelta_BranchE
	ld xwa, (xsp + 8)
	ldw (xwa + 13), 0xC000
	jr Voice_Slot_ApplyPortamentoDelta_Exit

Voice_Slot_ApplyPortamentoDelta_BranchE:
	ld bc, wa
	ld xwa, (xsp + 8)
	sub (xwa + 13), bc

Voice_Slot_ApplyPortamentoDelta_Exit:
	pop xiz
	inc 8, xsp
	ret

Voice_Slot_ApplyPitchJitter:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	ei 6
	ldda32 xwa, 4160
	ld iz, wa
	and iz, 0x7
	ei 0
	ld xwa, (xsp + 2)
	add (xwa), iz
	popw iz
	inc 4, xsp
	ret

Voice_Slot_ComputePitch:
	lda xsp, (xsp - 12)
	pushw iz
	ld (xsp + 10), xwa
	ld xwa, (xsp + 10)
	ld xbc, (xwa + 35)
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 23)
	ld (xsp + 2), xwa
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 31)
	ld (xsp + 6), xwa
	ld xwa, (xsp + 10)
	ld a, (xwa + 5)
	res 7, a
	ldb_erp A, 0xF8
	extz iz
	sla iz, 8
	add iz, 0x80
	add_sriw_rm IZ, 0xE5, 0x12, 0x01
	addda16_24 xiz, 267081
	ld a, (xbc + 22)
	exts wa
	sla wa, 8
	add iz, wa
	ld a, (xbc + 109)
	exts wa
	sla wa, 8
	add iz, wa
	ld wa, iz
	call SaturateS16_WA
	ld xwa, (xsp + 10)
	ld (xwa + 8), hl
	ld xwa, (xsp + 6)
	ld a, (xwa + 11)
	extz wa
	sla wa, 8
	add wa, 0x80
	sub iz, wa
	ld xwa, (xsp + 6)
	ld wa, (xwa + 12)
	add iz, wa
	ld xwa, (xsp + 2)
	ld a, (xwa + 3)
	exts wa
	sla wa, 8
	add iz, wa
	ld xwa, (xsp + 2)
	ld a, (xwa + 4)
	exts wa
	add iz, wa
	ld xwa, (xsp + 6)
	ld a, (xwa + 9)
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	ld a, (xwa + 10)
	ld e, a
	extz de
	ld wa, iz
	call PitchBend_AlignLoop_Init
	ld xwa, (xsp + 10)
	ld (xwa + 6), hl
	popw iz
	lda xsp, (xsp + 12)
	ret

Voice_Pitch_ClampRange:
	cp wa, de
	jr ge, Voice_Pitch_ClampRange_Hi
	ld wa, de
	jr Voice_Pitch_ClampRange_Lo

Voice_Pitch_ClampRange_Hi:
	cp wa, bc
	jr le, Voice_Pitch_ClampRange_Lo
	ld wa, bc

Voice_Pitch_ClampRange_Lo:
	ld hl, wa
	ret

ToneGen_WriteNoteKey:
	dec 2, xsp
	ld (xsp), a
	res_dd8 7, 0x18
	ld a, (xsp)
	add a, 0xC0
	extz wa
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x0000
	jr __jrt_nop_02B4C1
__jrt_nop_02B4C1:

ToneGen_WriteNoteKey_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld a, (xsp)
	extz wa
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x7e00
	jr __jrt_nop_02B4DD
__jrt_nop_02B4DD:

ToneGen_WriteNoteKey_NopCont2:
	nop
	nop
	nop
	inc 2, xsp
	ret

Voice_Init_Type4:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	stb_dri H, 0x07, 0xE4, 0xE0
	ld xwa, xiz
	call Voice_Pitch_InterpDispatch
	ld xwa, xiz
	call Voice_Pitch_WriteOutputReg_Portamento
	ld xwa, xiz
	call Voice_Pitch_WriteOutputReg_Legato
	ld xwa, xiz
	call Voice_Level_ComputeTriplet
	ld xwa, xiz
	call Voice_PitchPack_Dispatch
	ld xwa, xiz
	call Voice_PanReg_WriteDispatch
	ld xwa, xiz
	call Voice_StereoLevel_Compute
	ld xwa, xiz
	call Voice_PortaLevel_Compute
	ld xwa, xiz
	call Voice_Chan_ComputeParams
	ld xwa, xiz
	call Voice_SubVoice_ComputeAndTrigger
	ld xwa, xiz
	call Voice2_UpdatePitch
	ld xwa, xiz
	call Voice_ComputeExprPitchBend
	ld xwa, xiz
	call Voice_SetPitchWord_Muted
	ld xwa, xiz
	call Voice_ComputeAndWritePan
	ld xwa, xiz
	lds bc, 0
	call Voice_WriteChPanShift
	ld xwa, xiz
	call Voice_ComputePitch
	ld xwa, xiz
	call Voice_ApplyPortamento
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteVoiceParams
	pop xiz
	inc 2, xsp
	ret

Voice_Allocate_Typed:
	lda xsp, (xsp - 24)
	pushw_erp 0xFA
	ld (xsp + 18), de
	ld (xsp + 20), c
	ld (xsp + 22), xwa
	ld a, (xsp + 38)
	extz wa
	muls wa, 0x47
	lda_d16 xbc, 10562
	exts xwa
	add xwa, xbc
	ld (xsp + 2), xwa
	ld wa, (xsp + 30)
	ld e, a
	extz de
	ld wa, (xsp + 30)
	srl wa, 8
	ld c, a
	extz bc
	ld wa, de
	call DSP_LookupVoiceBuffer
	ld a, (xsp + 36)
	ld c, a
	extz bc
	ld a, (xsp + 20)
	ld e, a
	extz de
	ld xwa, xhl
	call VoiceParam_WriteDispatchHelper
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	ld a, (xwa + 13)
	extz wa
	and wa, (xsp + 18)
	jrl z, Voice_Allocate_Typed_ExitA
	ld a, (xsp + 38)
	extz wa
	muls wa, 0x15
	ld bc, wa
	add bc, 0x10
	ld xwa, (xsp + 6)
	stb_dri W, 0x07, 0xE0, 0xE4
	ld (xsp + 10), xwa
	ld a, (xsp + 38)
	ld c, a
	extz bc
	ld a, (xsp + 36)
	ld e, a
	extz de
	ld a, (xsp + 20)
	extz wa
	pushw wa
	ld wa, bc
	ld xbc, (xsp + 12)
	call VoiceField_ExtractAndWrite
	ld (xsp + 14), xhl
	ld a, (xsp + 34)
	extz wa
	ld xbc, (xsp + 14)
	call VelocityQuantise_B
	ldb_erp L, 0xFB
	stb_erp A, 0xFB
	extz wa
	ld xbc, (xsp + 14)
	call VoiceParam_WriteWithOffset_Alt
	stb_erp A, 0xFB
	sll a, 6
	or a, 0x12
	ld c, a
	extz bc
	ld xwa, (xsp + 2)
	ld (xwa + 1), bc
	ld xbc, (xsp + 2)
	ld a, (xsp + 38)
	ld (xbc + 3), a
	ld xbc, (xsp + 2)
	ld a, (xsp + 20)
	ld (xbc + 4), a
	ld c, (xsp + 36)
	set 7, c
	ld xwa, (xsp + 2)
	ld (xwa + 5), c
	ld xbc, (xsp + 2)
	ld a, (xsp + 34)
	ld (xbc + 12), a
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	stb_dri A, 0x07, 0xE4, 0xE0
	ld xwa, (xsp + 2)
	ld (xwa + 35), xbc
	ld a, (xsp + 38)
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri A, 0x07, 0xE0, 0xE8
	ld xwa, (xsp + 2)
	ld (xwa + 39), xbc
	ld xwa, (xsp + 2)
	ld xbc, (xsp + 6)
	ld (xwa + 19), xbc
	ld xwa, (xsp + 2)
	ld xbc, (xsp + 10)
	ld (xwa + 23), xbc
	ld xwa, (xsp + 2)
	ld xbc, (xsp + 14)
	ld (xwa + 27), xbc
	ld xwa, (xsp + 2)
	ld (xwa + 31), xhl
	ld xwa, (xsp + 2)
	call Voice_Pitch_CopyBase
	ld a, (xsp + 38)
	extz wa
	ld bc, wa
	inc 2, bc
	ld e, (xsp + 32)
	set 7, e
	ld xwa, (xsp + 22)
	lda_dri XIY, 0x07, 0xE0, 0xE4
	jr Voice_Allocate_Typed_ExitB

Voice_Allocate_Typed_ExitA:
	ld a, (xsp + 38)
	extz wa
	ld bc, wa
	inc 2, bc
	ld xwa, (xsp + 22)
	stib_ind 0x07, 0xE0, 0xE4, 0x00

Voice_Allocate_Typed_ExitB:
	ld a, (xsp + 38)
	extz wa
	ld bc, wa
	inc 6, bc
	ld xwa, (xsp + 22)
	stib_ind 0x07, 0xE0, 0xE4, 0x00
	popw_erp 0xFA
	lda xsp, (xsp + 24)
	retd 0xA

Voice_Setup_Typed:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 20), c
	ld (xsp + 22), xwa
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	ldw_sri WA, 0x07, 0xE4, 0xE0
	and wa, de
	jrl z, Voice_Setup_Typed_ExitA
	ld a, (xsp + 36)
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld xwa, (xwa + 4)
	ld (xsp + 8), xwa
	ld a, (xsp + 32)
	extz wa
	ld xbc, (xsp + 8)
	call VelocityQuantise_A
	ld a, (xsp + 36)
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	ld_sril3 XWA, 0x07, 0xE0, 0xE8
	ld (xsp + 4), xwa
	ld a, l
	extz wa
	ld bc, wa
	sla bc, 2
	ld a, (xsp + 36)
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, bc
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld xwa, (xwa + 118)
	ld (xsp + 12), xwa
	ld a, (xsp + 38)
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xsp + 16), xwa
	cp (xsp + 34), 0x78
	jr c, Voice_Setup_Typed_BranchB
	ld xwa, (xsp + 12)
	bitm 1, (xwa)
	jr z, Voice_Setup_Typed_BranchA
	ld c, (xsp + 34)
	sub c, 0x78
	ld xwa, (xsp + 12)
	add c, (xwa + 11)
	ld e, c
	ld a, (xsp + 20)
	ld c, a
	extz bc
	pushw 0x0
	ld a, e
	extz wa
	pushw wa
	ld a, (xsp + 36)
	extz wa
	pushw wa
	pushw 0x3
	ld xwa, (xsp + 20)
	pushm (xwa + 12)
	ld xwa, (xsp + 32)
	lds de, 1
	calr Voice_Allocate_Typed
	jrl Voice_Setup_Typed_ExitB

Voice_Setup_Typed_BranchA:
	ld a, (xsp + 38)
	extz wa
	ld bc, wa
	inc 2, bc
	ld xwa, (xsp + 22)
	stib_ind 0x07, 0xE0, 0xE4, 0x00
	ld a, (xsp + 38)
	extz wa
	ld bc, wa
	inc 6, bc
	ld xwa, (xsp + 22)
	stib_ind 0x07, 0xE0, 0xE4, 0x00
	jrl Voice_Setup_Typed_ExitB

Voice_Setup_Typed_BranchB:
	ld a, (xsp + 38)
	extz wa
	muls wa, 0x47
	lda_d16 xbc, 10562
	stb_dri H, 0x07, 0xE4, 0xE0
	sll l, 6
	set 2, l
	ld a, l
	extz wa
	ld (xiz + 1), wa
	ld a, (xsp + 38)
	ld (xiz + 3), a
	ld a, (xsp + 20)
	ld (xiz + 4), a
	ld a, (xsp + 34)
	set 7, a
	ld (xiz + 5), a
	ldw_da xwa, 0x041343
	bit 1, wa
	jr z, Voice_Setup_Typed_BranchD
	cp (xsp + 20), 0x0
	jr nz, Voice_Setup_Typed_BranchC
	ld a, (xsp + 32)
	add a, 0x28
	extz wa
	ldw bc, 0x7F
	lds de, 0
	calr Voice_Pitch_ClampRange
	ld (xsp + 32), l
	jr Voice_Setup_Typed_BranchD

Voice_Setup_Typed_BranchC:
	cp (xsp + 20), 0x1
	jr nz, Voice_Setup_Typed_BranchD
	ld a, (xsp + 32)
	add a, 0xC
	extz wa
	ldw bc, 0x7F
	lds de, 0
	calr Voice_Pitch_ClampRange
	ld (xsp + 32), l

Voice_Setup_Typed_BranchD:
	ld a, (xsp + 32)
	ld (xiz + 12), a
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	ld (xiz + 35), xwa
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xiz + 19), xwa
	ld xwa, (xsp + 4)
	ld (xiz + 23), xwa
	ld xwa, (xsp + 16)
	ld (xiz + 39), xwa
	ld xwa, (xsp + 8)
	ld (xiz + 27), xwa
	ld xwa, (xsp + 12)
	ld (xiz + 31), xwa
	ld xwa, xiz
	call Voice_Pitch_Compute
	ld a, (xsp + 20)
	ld e, a
	extz de
	ld a, (xsp + 38)
	ld c, a
	extz bc
	ld wa, de
	call Algo_SubTable_Bit15Dispatch
	ld a, l
	extz wa
	ld (xiz + 47), wa
	ld a, (xsp + 20)
	extz wa
	call Voice_SecondaryParam_Fetch
	ld a, l
	extz wa
	ld (xiz + 49), wa
	ld xwa, (xiz + 19)
	ld a, (xwa + 94)
	extz wa
	lda_24 xbc, 0x012038
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld (xiz + 53), a
	ld xwa, (xiz + 19)
	ld a, (xwa + 95)
	extz wa
	add wa, wa
	lda_24 xbc, 0x012057
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld (xiz + 54), wa
	ld xwa, (xiz + 19)
	ld a, (xwa + 96)
	extz wa
	add wa, wa
	lda_24 xbc, 0x012095
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld (xiz + 58), wa
	ld xwa, (xiz + 19)
	ld a, (xwa + 97)
	extz wa
	add wa, wa
	lda_24 xbc, 0x012057
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld (xiz + 56), wa
	ld a, (xsp + 38)
	extz wa
	ld bc, wa
	inc 2, bc
	ld e, (xsp + 30)
	set 7, e
	ld xwa, (xsp + 22)
	lda_dri XIY, 0x07, 0xE0, 0xE4
	cpw (xiz + 47), 0x0
	jr nz, Voice_Setup_Typed_BranchE
	cpw (xiz + 49), 0xFF
	jr nz, Voice_Setup_Typed_BranchE
	ld xwa, (xsp + 16)
	ld wa, (xwa + 24)
	extz xwa
	bit 15, wa
	jr z, Voice_Setup_Typed_BranchF

Voice_Setup_Typed_BranchE:
	ld a, (xsp + 38)
	extz wa
	ld bc, wa
	inc 6, bc
	ld xwa, (xsp + 22)
	stib_ind 0x07, 0xE0, 0xE4, 0x80
	jr Voice_Setup_Typed_ExitB

Voice_Setup_Typed_BranchF:
	ld a, (xsp + 38)
	extz wa
	ld bc, wa
	inc 6, bc
	ld xwa, (xsp + 22)
	stib_ind 0x07, 0xE0, 0xE4, 0x00
	jr Voice_Setup_Typed_ExitB

Voice_Setup_Typed_ExitA:
	ld a, (xsp + 38)
	extz wa
	ld bc, wa
	inc 2, bc
	ld xwa, (xsp + 22)
	stib_ind 0x07, 0xE0, 0xE4, 0x00
	ld a, (xsp + 38)
	extz wa
	ld bc, wa
	inc 6, bc
	ld xwa, (xsp + 22)
	stib_ind 0x07, 0xE0, 0xE4, 0x00

Voice_Setup_Typed_ExitB:
	pop xiz
	lda xsp, (xsp + 22)
	retd 0xA

Voice_NoteOn_Type4:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 6), e
	ld (xsp + 8), c
	ld (xsp + 10), xwa
	ld a, (xsp + 6)
	ld c, a
	extz bc
	ld a, (xsp + 8)
	extz wa
	sll wa, 8
	or wa, bc
	ld bc, wa
	set 7, bc
	ld xwa, (xsp + 10)
	ld (xwa), bc
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	ldw_sri WA, 0x07, 0xE4, 0xE0
	bit 14, wa
	jr z, Voice_NoteOn_Type4_BranchA
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x0
	pushw 0x1
	ld a, (xsp + 10)
	extz wa
	pushw wa
	ld a, (xsp + 24)
	extz wa
	pushw wa
	pushw 0x0
	ld xwa, (xsp + 20)
	lds de, 1
	calr Voice_Setup_Typed
	jr Voice_NoteOn_Type4_BranchB

Voice_NoteOn_Type4_BranchA:
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x0
	pushw 0x0
	ld a, (xsp + 10)
	extz wa
	pushw wa
	ld a, (xsp + 24)
	extz wa
	pushw wa
	pushw 0x0
	ld xwa, (xsp + 20)
	lds de, 1
	calr Voice_Setup_Typed

Voice_NoteOn_Type4_BranchB:
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	ldw_sri WA, 0x07, 0xE4, 0xE0
	extz xwa
	bit 15, wa
	jr z, Voice_NoteOn_Type4_BranchC
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x1
	pushw 0x0
	ld a, (xsp + 10)
	extz wa
	pushw wa
	ld a, (xsp + 24)
	extz wa
	pushw wa
	pushw 0x1
	ld xwa, (xsp + 20)
	lds de, 2
	calr Voice_Setup_Typed
	jr Voice_NoteOn_Type4_BranchD

Voice_NoteOn_Type4_BranchC:
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x1
	pushw 0x1
	ld a, (xsp + 10)
	extz wa
	pushw wa
	ld a, (xsp + 24)
	extz wa
	pushw wa
	pushw 0x1
	ld xwa, (xsp + 20)
	lds de, 2
	calr Voice_Setup_Typed

Voice_NoteOn_Type4_BranchD:
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x2
	pushw 0x2
	ld a, (xsp + 10)
	extz wa
	pushw wa
	ld a, (xsp + 24)
	extz wa
	pushw wa
	pushw 0x5
	ld xwa, (xsp + 20)
	lds de, 4
	calr Voice_Setup_Typed
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x3
	pushw 0x3
	ld a, (xsp + 10)
	extz wa
	pushw wa
	ld a, (xsp + 24)
	extz wa
	pushw wa
	pushw 0x3
	ld xwa, (xsp + 20)
	ldw de, 0x8
	calr Voice_Setup_Typed
	ld xwa, (xsp + 10)
	call NoteOn_Dispatch
	ld (xsp + 4), 0x0
	cp (xsp + 4), 0x4
	jrl nc, Voice_NoteOn_Type4_Exit

Voice_NoteOn_Type4_SlotLoop:
	ld a, (xsp + 4)
	extz wa
	ld bc, wa
	add bc, 0xA
	ld xwa, (xsp + 10)
	cpib_sri 0x07, 0xE0, 0xE4, 0x40
	jrl nc, Voice_NoteOn_Type4_BranchK
	ld a, (xsp + 4)
	extz wa
	ld bc, wa
	add bc, 0xA
	ld xwa, (xsp + 10)
	ldb_sri E, 0x07, 0xE0, 0xE4
	cp (xsp + 6), 0x78
	jr c, Voice_NoteOn_Type4_AltSlotPath
	ld a, e
	extz wa
	muls wa, 0x47
	ld hl, wa
	lda_24 xiz, 0x04308e
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x47
	lda_d16 xbc, 10562
	stb_dri E, 0x07, 0xE4, 0xE0
	stb_dri D, 0x07, 0xF8, 0xEC
	ldw bc, 0x23
	ldirw
	ldi85
	jrl Voice_NoteOn_Type4_BranchI

Voice_NoteOn_Type4_AltSlotPath:
	ld a, e
	extz wa
	muls wa, 0x47
	ld hl, wa
	lda_24 xiz, 0x04308e
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x47
	lda_d16 xbc, 10562
	stb_dri E, 0x07, 0xE4, 0xE0
	stb_dri D, 0x07, 0xF8, 0xEC
	ldw bc, 0x23
	ldirw
	ldi85
	ld a, e
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	lda_dri XIY, 0x07, 0xE4, 0xE0
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x47
	lda_d16 xbc, 10609
	ldw_sri HL, 0x07, 0xE4, 0xE0
	cps hl, 0
	jr z, Voice_NoteOn_Type4_BranchE
	ld wa, hl
	sll wa, 8
	extz xwa
	set 15, wa
	or hl, wa
	jr Voice_NoteOn_Type4_BranchF

Voice_NoteOn_Type4_BranchE:
	lds hl, 0

Voice_NoteOn_Type4_BranchF:
	ld a, e
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x0430bd
	stw_dri HL, 0x07, 0xE4, 0xE0
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x47
	lda_d16 xbc, 10611
	ldw_sri HL, 0x07, 0xE4, 0xE0
	cp hl, 0xFF
	jr z, Voice_NoteOn_Type4_BranchG
	or hl, 0xC000
	jr Voice_NoteOn_Type4_BranchH

Voice_NoteOn_Type4_BranchG:
	ldw hl, 0xFF

Voice_NoteOn_Type4_BranchH:
	ld a, e
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x0430bf
	stw_dri HL, 0x07, 0xE4, 0xE0

Voice_NoteOn_Type4_BranchI:
	ld a, e
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x0430b5
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld wa, (xwa + 24)
	extz xwa
	bit 15, wa
	jr z, Voice_NoteOn_Type4_BranchJ
	ld a, e
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308f
	or_sriw_im 0x07, 0xE4, 0xE0, 0x00, 0x01
	jr Voice_NoteOn_Type4_BranchK

Voice_NoteOn_Type4_BranchJ:
	ld a, e
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308f
	and_sriw_im 0x07, 0xE4, 0xE0, 0xFF, 0xFE

Voice_NoteOn_Type4_BranchK:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x4
	jrl c, Voice_NoteOn_Type4_SlotLoop

Voice_NoteOn_Type4_Exit:
	pop xiz
	lda xsp, (xsp + 10)
	retd 0x2

Voice_Release_Type4:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	stb_dri H, 0x07, 0xE4, 0xE0
	ld xwa, xiz
	call Voice_PitchEnv_Advance
	ld xwa, xiz
	call Voice_Pitch_WriteOutputReg_Portamento
	ld xwa, xiz
	call Voice_Pitch_WriteOutputReg_Legato
	ld xwa, xiz
	call Voice_Level_ComputeTriplet
	ld xwa, xiz
	call Voice_PitchPack_Dispatch
	ld xwa, xiz
	call Voice_PanReg_WriteDispatch
	ld xwa, xiz
	call Voice_StereoLevel_Compute
	ld xwa, xiz
	call Voice_PortaLevel_Compute
	ld xwa, xiz
	call Voice_Chan_ComputeParams
	ld xwa, xiz
	call Voice_SubVoice_ComputeAndTrigger
	ld xwa, xiz
	call Voice2_UpdatePitch
	ld xwa, xiz
	call Voice_ComputeExprPitchBend
	ld xwa, xiz
	call Voice_SetPitchWord_Muted
	cp (xiz + 3), 0x3
	jr nc, Voice_Release_Type4_BranchA
	ld xwa, xiz
	call Voice_UpdatePan_Full
	ld xwa, xiz
	call Voice_ComputePitch
	ld xwa, xiz
	call Voice_Slot_LoadPitchOffset_A
	ld xwa, xiz
	call Voice_ApplyPortamento
	jr Voice_Release_Type4_BranchB

Voice_Release_Type4_BranchA:
	ld xwa, xiz
	call Voice_UpdatePan_Mono
	ld xwa, xiz
	call Voice_ComputePitch
	ld xwa, xiz
	call Voice_Slot_ApplyPortamentoDelta
	ld xwa, xiz
	call Voice_ApplyPortamento

Voice_Release_Type4_BranchB:
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteVoiceParams
	pop xiz
	inc 2, xsp
	ret

Voice_NoteOn_Type3:
	dec 8, xsp
	push xiz
	ld (xsp + 8), xwa
	ld a, c
	extz wa
	muls wa, 0x11F
	lda_24 xhl, 0x04136a
	ldw_sri WA, 0x07, 0xEC, 0xE0
	and wa, de
	jrl z, Voice_NoteOn_Type3_ExitA
	ld a, (xsp + 22)
	extz wa
	muls wa, 0x25
	ld hl, wa
	add hl, 0x6E
	ld a, c
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x041368
	exts xwa
	add xwa, xde
	stb_dri W, 0x07, 0xE0, 0xEC
	ld xwa, (xwa + 4)
	ld (xsp + 4), xwa
	ld a, (xsp + 22)
	extz wa
	muls wa, 0x25
	ld hl, wa
	add hl, 0x6E
	ld a, c
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x041368
	exts xwa
	add xwa, xde
	ld_sril3 XDE, 0x07, 0xE0, 0xEC
	ld a, (xsp + 22)
	extz wa
	muls wa, 0x25
	ld ix, wa
	add ix, 0x6E
	ld a, c
	extz wa
	muls wa, 0x11F
	lda_24 xhl, 0x041368
	exts xwa
	add xwa, xhl
	stb_dri W, 0x07, 0xE0, 0xF0
	ld xhl, (xwa + 8)
	ld a, (xsp + 22)
	extz wa
	muls wa, 0x25
	ld iy, wa
	add iy, 0x6E
	ld a, c
	extz wa
	muls wa, 0x11F
	lda_24 xix, 0x041368
	exts xwa
	add xwa, xix
	stb_dri D, 0x07, 0xE0, 0xF4
	ld a, (xsp + 22)
	extz wa
	muls wa, 0x47
	lda_d16 xiy, 10562
	stb_dri H, 0x07, 0xF4, 0xE0
	ldw (xiz + 1), 0x8
	bitm 7, (xsp + 18)
	jr z, Voice_NoteOn_Type3_BranchA
	ormi16 (xiz + 1), 0x800

Voice_NoteOn_Type3_BranchA:
	ld a, (xsp + 22)
	ld (xiz + 3), a
	ld (xiz + 4), c
	ld a, (xsp + 20)
	set 7, a
	ld (xiz + 5), a
	ld a, (xsp + 18)
	res 7, a
	ld (xiz + 12), a
	ld a, c
	extz wa
	muls wa, 0x11F
	lda_24 xiy, 0x041368
	exts xwa
	add xwa, xiy
	ld (xiz + 35), xwa
	ld a, c
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xiz + 19), xwa
	ld (xiz + 23), xde
	ld xwa, (xsp + 4)
	ld (xiz + 27), xwa
	ld (xiz + 31), xhl
	ld (xiz + 39), xix
	ld xwa, xiz
	call Voice_Pitch_Compute
	ldw (xiz + 47), 0x0
	ldw (xiz + 49), 0xFF
	ld (xiz + 53), 0x0
	ldw (xiz + 54), 0x0
	ldw (xiz + 58), 0x0
	ldw (xiz + 56), 0x0
	ld a, (xsp + 22)
	extz wa
	ld bc, wa
	inc 2, bc
	ld e, (xsp + 16)
	set 7, e
	ld xwa, (xsp + 8)
	lda_dri XIY, 0x07, 0xE0, 0xE4
	jr Voice_NoteOn_Type3_ExitB

Voice_NoteOn_Type3_ExitA:
	ld a, (xsp + 22)
	extz wa
	ld bc, wa
	inc 2, bc
	ld xwa, (xsp + 8)
	stib_ind 0x07, 0xE0, 0xE4, 0x00

Voice_NoteOn_Type3_ExitB:
	ld a, (xsp + 22)
	extz wa
	ld bc, wa
	inc 6, bc
	ld xwa, (xsp + 8)
	stib_ind 0x07, 0xE0, 0xE4, 0x00
	pop xiz
	inc 8, xsp
	retd 0x8

Voice_NoteOn_Type2:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 6), e
	ld (xsp + 8), c
	ld (xsp + 10), xwa
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	ldw_sri WA, 0x07, 0xE4, 0xE0
	bit 13, wa
	jr z, Voice_NoteOn_Type2_BranchA
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041480
	set_dri 7, 0x07, 0xE4, 0xE0
	jr Voice_NoteOn_Type2_BranchB

Voice_NoteOn_Type2_BranchA:
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041480
	res_dri 7, 0x07, 0xE4, 0xE0

Voice_NoteOn_Type2_BranchB:
	ld a, (xsp + 6)
	ld c, a
	extz bc
	ld a, (xsp + 8)
	extz wa
	sll wa, 8
	or wa, bc
	ld bc, wa
	set 7, bc
	ld xwa, (xsp + 10)
	ld (xwa), bc
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x0
	ld a, (xsp + 8)
	extz wa
	pushw wa
	ld a, (xsp + 22)
	extz wa
	pushw wa
	pushw 0x0
	ld xwa, (xsp + 18)
	lds de, 1
	calr Voice_NoteOn_Type3
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x1
	ld a, (xsp + 8)
	extz wa
	pushw wa
	ld a, (xsp + 22)
	extz wa
	pushw wa
	pushw 0x1
	ld xwa, (xsp + 18)
	lds de, 2
	calr Voice_NoteOn_Type3
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x2
	ld a, (xsp + 8)
	extz wa
	pushw wa
	ld a, (xsp + 22)
	extz wa
	pushw wa
	pushw 0x1
	ld xwa, (xsp + 18)
	lds de, 4
	calr Voice_NoteOn_Type3
	bitm 7, (xsp + 18)
	jr z, Voice_NoteOn_Type2_BranchC
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x3
	ld a, (xsp + 8)
	extz wa
	pushw wa
	ld a, (xsp + 22)
	extz wa
	pushw wa
	pushw 0x3
	ld xwa, (xsp + 18)
	lds de, 0
	calr Voice_NoteOn_Type3
	jr Voice_NoteOn_Type2_BranchD

Voice_NoteOn_Type2_BranchC:
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x3
	ld a, (xsp + 8)
	extz wa
	pushw wa
	ld a, (xsp + 22)
	extz wa
	pushw wa
	pushw 0x3
	ld xwa, (xsp + 18)
	ldw de, 0x8
	calr Voice_NoteOn_Type3

Voice_NoteOn_Type2_BranchD:
	ld xwa, (xsp + 10)
	call NoteOn_Dispatch
	ldb e, 0x0
	cps e, 4
	jr nc, Voice_NoteOn_Type2_Exit

Voice_NoteOn_Type2_BranchE:
	ld a, e
	extz wa
	ld bc, wa
	add bc, 0xA
	ld xwa, (xsp + 10)
	cpib_sri 0x07, 0xE0, 0xE4, 0x40
	jr nc, Voice_NoteOn_Type2_LoopStep
	ld a, e
	extz wa
	ld bc, wa
	add bc, 0xA
	ld xwa, (xsp + 10)
	ldb_sri A, 0x07, 0xE0, 0xE4
	ld (xsp + 4), a
	extz wa
	muls wa, 0x47
	ld hl, wa
	lda_24 xiz, 0x04308e
	ld a, e
	extz wa
	muls wa, 0x47
	lda_d16 xbc, 10562
	stb_dri E, 0x07, 0xE4, 0xE0
	stb_dri D, 0x07, 0xF8, 0xEC
	ldw bc, 0x23
	ldirw
	ldi85
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x47
	ld bc, wa
	lda_24 xhl, 0x04308e
	ld a, (xsp + 4)
	lda_dri XBC, 0x07, 0xEC, 0xE4

Voice_NoteOn_Type2_LoopStep:
	inc 1, e
	cps e, 4
	jr c, Voice_NoteOn_Type2_BranchE

Voice_NoteOn_Type2_Exit:
	pop xiz
	lda xsp, (xsp + 10)
	retd 0x2

Voice_Init_Type2:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	stb_dri H, 0x07, 0xE4, 0xE0
	ld xwa, xiz
	call Voice_Pitch_InterpDispatch
	ld xwa, xiz
	call Voice_Pitch_WriteOutputReg_Direct
	ld xwa, xiz
	call Voice_Pitch_WriteOutputReg_Secondary
	ld xwa, xiz
	call Voice_PitchReg_WriteDispatch
	ld xwa, xiz
	call Voice_PanReg_WriteDispatchB
	ld xwa, xiz
	call Voice_ComputePitchBend2
	ld xwa, xiz
	call Voice_SetPitchWord_Unmuted
	ld xwa, xiz
	call Voice_UpdatePan_Simple
	ld xwa, xiz
	lds bc, 0
	call Voice_WriteChPanShift2
	ld xwa, xiz
	call Voice_Level_ClearAllOutputRegs
	ld xwa, xiz
	call Voice_ComputePitch_Mono
	ld xwa, xiz
	call Voice_ApplyPortamento2
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteVoiceParams
	pop xiz
	inc 2, xsp
	ret

Voice_Allocate_Type2:
	lda xsp, (xsp - 26)
	push xiz
	ld (xsp + 22), de
	ld (xsp + 24), c
	ld (xsp + 26), xwa
	ld a, (xsp + 24)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XHL, 0x07, 0xE4, 0xE0
	ld a, (xsp + 38)
	ld c, a
	extz bc
	ld a, (xsp + 24)
	ld e, a
	extz de
	ld xwa, xhl
	call VoiceParam_WriteDispatchHelper
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld a, (xwa + 13)
	extz wa
	and wa, (xsp + 22)
	jrl z, Voice_Allocate_Type2_ExitA
	ld a, (xsp + 40)
	extz wa
	muls wa, 0x15
	ld bc, wa
	add bc, 0x10
	ld xwa, (xsp + 4)
	stb_dri W, 0x07, 0xE0, 0xE4
	ld (xsp + 8), xwa
	ld a, (xsp + 40)
	ld c, a
	extz bc
	ld a, (xsp + 38)
	ld e, a
	extz de
	ld a, (xsp + 24)
	extz wa
	pushw wa
	ld wa, bc
	ld xbc, (xsp + 10)
	call VoiceField_ExtractAndWrite
	ld (xsp + 12), xhl
	ld a, (xsp + 36)
	extz wa
	ld xbc, (xsp + 12)
	call VelocityQuantise_B
	ld (xsp + 20), l
	ld a, (xsp + 20)
	extz wa
	ld xbc, (xsp + 12)
	call VoiceParam_WriteWithOffset_Alt
	ld (xsp + 16), xhl
	ld a, (xsp + 40)
	extz wa
	muls wa, 0x47
	lda_d16 xbc, 10562
	stb_dri H, 0x07, 0xE4, 0xE0
	ld a, (xsp + 20)
	sll a, 6
	set 4, a
	extz wa
	ld (xiz + 1), wa
	ld a, (xsp + 40)
	ld (xiz + 3), a
	ld a, (xsp + 24)
	ld (xiz + 4), a
	ld a, (xsp + 38)
	set 7, a
	ld (xiz + 5), a
	ldw_da xwa, 0x041343
	bit 1, wa
	jr z, Voice_Allocate_Type2_BranchA
	ld a, (xsp + 36)
	add a, 0x10
	extz wa
	ldw bc, 0x7F
	lds de, 0
	calr Voice_Pitch_ClampRange
	ld (xsp + 36), l

Voice_Allocate_Type2_BranchA:
	ld a, (xsp + 36)
	ld (xiz + 12), a
	ld a, (xsp + 24)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	ld (xiz + 35), xwa
	ld a, (xsp + 40)
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 24)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xiz + 39), xwa
	ld xwa, (xsp + 4)
	ld (xiz + 19), xwa
	ld xwa, (xsp + 8)
	ld (xiz + 23), xwa
	ld xwa, (xsp + 12)
	ld (xiz + 27), xwa
	ld xwa, (xsp + 16)
	ld (xiz + 31), xwa
	ld xwa, xiz
	call Voice_Pitch_CopyBase
	ld a, (xsp + 40)
	extz wa
	ld bc, wa
	inc 2, bc
	ld e, (xsp + 34)
	set 7, e
	ld xwa, (xsp + 26)
	lda_dri XIY, 0x07, 0xE0, 0xE4
	jr Voice_Allocate_Type2_ExitB

Voice_Allocate_Type2_ExitA:
	ld a, (xsp + 40)
	extz wa
	ld bc, wa
	inc 2, bc
	ld xwa, (xsp + 26)
	stib_ind 0x07, 0xE0, 0xE4, 0x00

Voice_Allocate_Type2_ExitB:
	ld a, (xsp + 40)
	extz wa
	ld bc, wa
	inc 6, bc
	ld xwa, (xsp + 26)
	stib_ind 0x07, 0xE0, 0xE4, 0x00
	pop xiz
	lda xsp, (xsp + 26)
	retd 0x8

Voice_NoteOn_Type1:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 6), e
	ld (xsp + 8), c
	ld (xsp + 10), xwa
	ld a, (xsp + 6)
	ld c, a
	extz bc
	ld a, (xsp + 8)
	extz wa
	sll wa, 8
	or wa, bc
	ld bc, wa
	set 7, bc
	ld xwa, (xsp + 10)
	ld (xwa), bc
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x0
	ld a, (xsp + 8)
	extz wa
	pushw wa
	ld a, (xsp + 22)
	extz wa
	pushw wa
	pushw 0x0
	ld xwa, (xsp + 18)
	lds de, 1
	calr Voice_Allocate_Type2
	ld a, (xsp + 8)
	ld c, a
	extz bc
	pushw 0x1
	ld a, (xsp + 8)
	extz wa
	pushw wa
	ld a, (xsp + 22)
	extz wa
	pushw wa
	pushw 0x1
	ld xwa, (xsp + 18)
	lds de, 4
	calr Voice_Allocate_Type2
	ld xwa, (xsp + 10)
	ld (xwa + 4), 0x0
	ld xwa, (xsp + 10)
	ld (xwa + 8), 0x0
	ld xwa, (xsp + 10)
	ld (xwa + 5), 0x0
	ld xwa, (xsp + 10)
	ld (xwa + 9), 0x0
	ld xwa, (xsp + 10)
	call NoteOn_Dispatch
	ldb e, 0x0
	cps e, 2
	jr nc, Voice_NoteOn_Type1_Exit

Voice_NoteOn_Type1_LoopBody:
	ld a, e
	extz wa
	ld bc, wa
	add bc, 0xA
	ld xwa, (xsp + 10)
	cpib_sri 0x07, 0xE0, 0xE4, 0x40
	jr nc, Voice_NoteOn_Type1_LoopStep
	ld a, e
	extz wa
	ld bc, wa
	add bc, 0xA
	ld xwa, (xsp + 10)
	ldb_sri A, 0x07, 0xE0, 0xE4
	ld (xsp + 4), a
	extz wa
	muls wa, 0x47
	ld hl, wa
	lda_24 xiz, 0x04308e
	ld a, e
	extz wa
	muls wa, 0x47
	lda_d16 xbc, 10562
	stb_dri E, 0x07, 0xE4, 0xE0
	stb_dri D, 0x07, 0xF8, 0xEC
	ldw bc, 0x23
	ldirw
	ldi85
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x47
	ld bc, wa
	lda_24 xhl, 0x04308e
	ld a, (xsp + 4)
	lda_dri XBC, 0x07, 0xEC, 0xE4

Voice_NoteOn_Type1_LoopStep:
	inc 1, e
	cps e, 2
	jr c, Voice_NoteOn_Type1_LoopBody

Voice_NoteOn_Type1_Exit:
	pop xiz
	lda xsp, (xsp + 10)
	retd 0x2

Voice_Init_Type1:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	stb_dri H, 0x07, 0xE4, 0xE0
	ld xwa, xiz
	call Voice_Pitch_InterpDispatch
	lda_24 xwa, 0x0451ce
	call Voice_Slot_ApplyPitchJitter
	ld xwa, xiz
	call Voice_Pitch_WriteOutputReg_Direct
	ld xwa, xiz
	call Voice_Pitch_WriteOutputReg_Secondary
	ld xwa, xiz
	call Voice_PitchReg_WriteDispatch
	ld xwa, xiz
	call Voice_PanReg_WriteDispatchB
	ld xwa, xiz
	call Voice_ComputePitchBend2
	ld xwa, xiz
	call Voice_SetPitchWord_Unmuted
	ld xwa, xiz
	call Voice_UpdatePan_Simple
	ld xwa, xiz
	lds bc, 0
	call Voice_WriteChPanShift2
	ld xwa, xiz
	call Voice_Level_ClearAllOutputRegs
	ld xwa, xiz
	call Voice_ComputePitch_Mono
	ld xwa, xiz
	call Voice_Slot_LoadPitchOffset_B
	ld xwa, xiz
	call Voice_ApplyPortamento2
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteVoiceParams
	pop xiz
	inc 2, xsp
	ret

Voice_Allocate_1of4:
	lda xsp, (xsp - 24)
	pushw_erp 0xFA
	ld (xsp + 18), de
	ld (xsp + 20), c
	ld (xsp + 22), xwa
	ldib_erp 0xFB, 0
	stb_erp A, 0xFB
	extz wa
	ld bc, wa
	sla bc, 2
	ld a, (xsp + 36)
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, bc
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld xwa, (xwa + 118)
	ld (xsp + 14), xwa
	ld bc, (xwa + 12)
	ld a, c
	ld e, a
	extz de
	ld wa, bc
	srl wa, 8
	ld c, a
	extz bc
	ld wa, de
	call DSP_LookupVoiceBuffer
	ld xwa, (xsp + 14)
	ld a, (xwa + 11)
	ld c, a
	extz bc
	ld a, (xsp + 20)
	ld e, a
	extz de
	ld xwa, xhl
	call VoiceParam_WriteDispatchHelper
	ld (xsp + 2), xhl
	ld xwa, (xsp + 14)
	bitm 1, (xwa)
	jrl z, Voice_Allocate_1of4_ExitA
	ld xwa, (xsp + 2)
	ld a, (xwa + 13)
	extz wa
	and wa, (xsp + 18)
	jrl z, Voice_Allocate_1of4_ExitA
	ld a, (xsp + 36)
	extz wa
	muls wa, 0x15
	ld bc, wa
	add bc, 0x10
	ld xwa, (xsp + 2)
	stb_dri W, 0x07, 0xE0, 0xE4
	ld (xsp + 6), xwa
	ld a, (xsp + 36)
	ld c, a
	extz bc
	ld a, (xsp + 34)
	ld e, a
	extz de
	ld a, (xsp + 20)
	extz wa
	pushw wa
	ld wa, bc
	ld xbc, (xsp + 8)
	call VoiceField_ExtractAndWrite
	ld (xsp + 10), xhl
	ld a, (xsp + 32)
	extz wa
	ld xbc, (xsp + 10)
	call VelocityQuantise_B
	ldb_erp L, 0xFB
	stb_erp A, 0xFB
	extz wa
	ld xbc, (xsp + 10)
	call VoiceParam_WriteWithOffset_Alt
	ld (xsp + 14), xhl
	ld a, (xsp + 36)
	extz wa
	muls wa, 0x47
	lda_d16 xbc, 10562
	stb_dri A, 0x07, 0xE4, 0xE0
	stb_erp A, 0xFB
	sll a, 6
	or a, 0x12
	extz wa
	ld (xbc + 1), wa
	ld a, (xsp + 36)
	ld (xbc + 3), a
	ld a, (xsp + 20)
	ld (xbc + 4), a
	ld a, (xsp + 34)
	set 7, a
	ld (xbc + 5), a
	ld a, (xsp + 32)
	ld (xbc + 12), a
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x041368
	exts xwa
	add xwa, xde
	ld (xbc + 35), xwa
	ld xwa, (xsp + 2)
	ld (xbc + 19), xwa
	ld xwa, (xsp + 6)
	ld (xbc + 23), xwa
	ld xwa, (xsp + 10)
	ld (xbc + 27), xwa
	ld xwa, (xsp + 14)
	ld (xbc + 31), xwa
	ld xwa, xbc
	call Voice_Slot_ComputePitch
	ld a, (xsp + 36)
	extz wa
	ld bc, wa
	inc 2, bc
	ld e, (xsp + 30)
	set 7, e
	ld xwa, (xsp + 22)
	lda_dri XIY, 0x07, 0xE0, 0xE4
	jr Voice_Allocate_1of4_ExitB

Voice_Allocate_1of4_ExitA:
	ld a, (xsp + 36)
	extz wa
	ld bc, wa
	inc 2, bc
	ld xwa, (xsp + 22)
	stib_ind 0x07, 0xE0, 0xE4, 0x00

Voice_Allocate_1of4_ExitB:
	popw_erp 0xFA
	lda xsp, (xsp + 24)
	retd 0x8

Voice_NoteOn_Rhythm:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ld l, (xsp + 10)
	ldb_erp E, 0xF0
	extz ix
	ld a, c
	extz wa
	sll wa, 8
	or wa, ix
	set 7, wa
	ld (xiz), wa
	cps l, 0
	jr z, Voice_NoteOn_Rhythm_BranchA
	ld (xsp + 4), 0x0
	extz bc
	ld a, (xsp + 4)
	extz wa
	pushw wa
	ld a, e
	extz wa
	pushw wa
	ld a, l
	extz wa
	pushw wa
	pushw 0x3
	ld xwa, xiz
	lds de, 1
	calr Voice_Allocate_1of4
	ld (xiz + 6), 0x40
	ld (xiz + 3), 0x0
	ld (xiz + 7), 0x0
	jr Voice_NoteOn_Rhythm_BranchB

Voice_NoteOn_Rhythm_BranchA:
	ld (xsp + 4), 0x1
	ldb l, 0x50
	ld (xiz + 2), 0x0
	ld (xiz + 6), 0x0
	extz bc
	ld a, (xsp + 4)
	extz wa
	pushw wa
	ld a, e
	extz wa
	pushw wa
	ld a, l
	extz wa
	pushw wa
	pushw 0x3
	ld xwa, xiz
	lds de, 4
	calr Voice_Allocate_1of4
	ld (xiz + 7), 0x0

Voice_NoteOn_Rhythm_BranchB:
	ld (xiz + 4), 0x0
	ld (xiz + 8), 0x0
	ld (xiz + 5), 0x0
	ld (xiz + 9), 0x0
	ld xwa, xiz
	call NoteOn_Dispatch
	ld a, (xsp + 4)
	extz wa
	add wa, 0xA
	cpib_sri 0x07, 0xF8, 0xE0, 0x40
	jr nc, Voice_NoteOn_Rhythm_Exit
	ld a, (xsp + 4)
	extz wa
	add wa, 0xA
	ldb_sri E, 0x07, 0xF8, 0xE0
	ld a, e
	extz wa
	muls wa, 0x47
	ld hl, wa
	lda_24 xiz, 0x04308e
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x47
	lda_d16 xbc, 10562
	stb_dri E, 0x07, 0xE4, 0xE0
	stb_dri D, 0x07, 0xF8, 0xEC
	ldw bc, 0x23
	ldirw
	ldi85
	ld a, e
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	lda_dri XIY, 0x07, 0xE4, 0xE0

Voice_NoteOn_Rhythm_Exit:
	pop xiz
	inc 2, xsp
	retd 0x2

Voice_SetPitch:
	lda xsp, (xsp - 20)
	pushw_erp 0xFA
	ld (xsp + 16), e
	ld (xsp + 18), c
	ld (xsp + 20), a
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0x40
	jrl nz, Voice_SetPitch_Exit
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	ldw_sri WA, 0x07, 0xE4, 0xE0
	and wa, 0x7
	jrl z, Voice_SetPitch_Exit
	bitm 7, (xsp + 16)
	jrl nz, Voice_SetPitch_Exit
	ld a, (xsp + 20)
	ld e, a
	extz de
	ld a, (xsp + 26)
	ld c, a
	extz bc
	ld wa, de
	call Voice_Env_ApplyVelocity_Type0
	ld a, (xsp + 20)
	extz wa
	call Voice_Env_UpdateVelocityCounters
	lda xwa, (xsp + 2)
	ld xhl, xwa
	ld a, (xsp + 20)
	ld c, a
	extz bc
	ld a, (xsp + 18)
	ld e, a
	extz de
	ld a, (xsp + 16)
	extz wa
	pushw wa
	ld xwa, xhl
	calr Voice_NoteOn_Rhythm
	ld a, (xsp + 12)
	ldb_erp A, 0xFB
	cp_erpb 0xFB, 0x40
	jr nc, Voice_SetPitch_Exit
	res_dd8 7, 0x18
	stb_erp A, 0xFB
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff00
	jr __jrt_nop_02C780
__jrt_nop_02C780:

Voice_SetPitch_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stb_erp A, 0xFB
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff80
	jr __jrt_nop_02C7A1
__jrt_nop_02C7A1:

Voice_SetPitch_NopCont2:
	nop
	nop
	nop
	stb_erp A, 0xFB
	extz wa
	calr Voice_Init_Type1
	stb_erp A, 0xFB
	ld l, a
	extz hl
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x47
	ld bc, wa
	lda_24 xde, 0x0430bb
	ld wa, hl
	ldw_sri BC, 0x07, 0xE8, 0xE4
	call ToneGen_WriteSingleReg

Voice_SetPitch_Exit:
	popw_erp 0xFA
	lda xsp, (xsp + 20)
	retd 0x2

Voice_NoteOff:
	lda xsp, (xsp - 20)
	pushw_erp 0xFA
	ld (xsp + 16), e
	ld (xsp + 18), c
	ld (xsp + 20), a
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0x40
	jrl nz, Voice_NoteOff_Exit
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	ldw_sri WA, 0x07, 0xE4, 0xE0
	and wa, 0x7
	jrl z, Voice_NoteOff_Exit
	ld a, (xsp + 20)
	ld e, a
	extz de
	ld a, (xsp + 26)
	ld c, a
	extz bc
	ld wa, de
	call Voice_Env_ApplyVelocity_Type0
	ld a, (xsp + 20)
	extz wa
	call Voice_Env_UpdateVelocityCounters
	lda xwa, (xsp + 2)
	ld xhl, xwa
	ld a, (xsp + 20)
	ld c, a
	extz bc
	ld a, (xsp + 18)
	ld e, a
	extz de
	ld a, (xsp + 16)
	extz wa
	pushw wa
	ld xwa, xhl
	calr Voice_NoteOn_Rhythm
	ld a, (xsp + 13)
	ldb_erp A, 0xFB
	cp_erpb 0xFB, 0x40
	jr nc, Voice_NoteOff_Exit
	res_dd8 7, 0x18
	stb_erp A, 0xFB
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff00
	jr __jrt_nop_02C884
__jrt_nop_02C884:

Voice_NoteOff_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stb_erp A, 0xFB
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff80
	jr __jrt_nop_02C8A5
__jrt_nop_02C8A5:

Voice_NoteOff_NopCont2:
	nop
	nop
	nop
	stb_erp A, 0xFB
	extz wa
	calr Voice_Init_Type1
	stb_erp A, 0xFB
	ld l, a
	extz hl
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x47
	ld bc, wa
	lda_24 xde, 0x0430bb
	ld wa, hl
	ldw_sri BC, 0x07, 0xE8, 0xE4
	call ToneGen_WriteSingleReg
	stb_erp A, 0xFB
	extz wa
	call VoiceSlot_NoteOff

Voice_NoteOff_Exit:
	popw_erp 0xFA
	lda xsp, (xsp + 20)
	retd 0x2

Voice_SetVelocity:
	lda xsp, (xsp - 20)
	pushw_erp 0xFA
	ld (xsp + 16), e
	ld (xsp + 18), c
	ld (xsp + 20), a
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0xC0
	jrl z, Voice_SetVelocity_Exit
	cp a, 0x80
	jrl z, Voice_SetVelocity_Type80_Entry
	cp a, 0x40
	jrl z, Voice_SetVelocity_Type40_Entry
	cps a, 0
	jrl nz, Voice_SetVelocity_Exit
	ld a, (xsp + 20)
	ld e, a
	extz de
	ld a, (xsp + 26)
	ld c, a
	extz bc
	ld wa, de
	call Voice_Env_ApplyVelocity_Type0
	ld a, (xsp + 20)
	extz wa
	call Voice_Env_UpdateVelocityCounters
	call Voice_Vol_ScaleVelocityWord
	lda xwa, (xsp + 2)
	ld xhl, xwa
	ld a, (xsp + 20)
	ld c, a
	extz bc
	ld a, (xsp + 18)
	ld e, a
	extz de
	ld a, (xsp + 16)
	extz wa
	pushw wa
	ld xwa, xhl
	calr Voice_NoteOn_Type4
	ldib_erp 0xFA, 0
	cpib_erp 0xFA, 4
	jrl nc, Voice_SetVelocity_Type0_Loop2Start

Voice_SetVelocity_Type0_SlotLoop:
	stb_erp A, 0xFA
	extz wa
	add wa, 0xA
	lda xbc, (xsp + 2)
	ldb_sri A, 0x07, 0xE4, 0xE0
	ldb_erp A, 0xFB
	cp_erpb 0xFB, 0x40
	jr nc, Voice_SetVelocity_Type0_BranchB
	res_dd8 7, 0x18
	stb_erp A, 0xFB
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff00
	jr __jrt_nop_02C9A3
__jrt_nop_02C9A3:

Voice_SetVelocity_Type0_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stb_erp A, 0xFB
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff80
	jr __jrt_nop_02C9C4
__jrt_nop_02C9C4:

Voice_SetVelocity_Type0_NopCont2:
	nop
	nop
	nop
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308f
	ldw_sri WA, 0x07, 0xE4, 0xE0
	bit 1, wa
	jr z, Voice_SetVelocity_Type0_BranchA
	stb_erp A, 0xFB
	extz wa
	calr Voice_Init_Type2
	jr Voice_SetVelocity_Type0_BranchB

Voice_SetVelocity_Type0_BranchA:
	stb_erp A, 0xFB
	extz wa
	calr Voice_Init_Type4

Voice_SetVelocity_Type0_BranchB:
	inc1b_erp 0xFA
	cpib_erp 0xFA, 4
	jrl c, Voice_SetVelocity_Type0_SlotLoop

Voice_SetVelocity_Type0_Loop2Start:
	ldib_erp 0xFA, 0
	cpib_erp 0xFA, 4
	jr nc, Voice_SetVelocity_Type0_Loop2Exit

Voice_SetVelocity_Type0_Loop2Body:
	stb_erp A, 0xFA
	extz wa
	add wa, 0xA
	lda xbc, (xsp + 2)
	cpib_sri 0x07, 0xE4, 0xE0, 0x40
	jr nc, Voice_SetVelocity_Type0_Loop2Step
	stb_erp A, 0xFA
	extz wa
	add wa, 0xA
	lda xbc, (xsp + 2)
	ldb_sri A, 0x07, 0xE4, 0xE0
	ldb_erp A, 0xFB
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x0430bd
	cpiw_sri 0x07, 0xE4, 0xE0, 0x00, 0x00
	jr nz, Voice_SetVelocity_Type0_Loop2Step
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308f
	ldw_sri WA, 0x07, 0xE4, 0xE0
	bit 8, wa
	jr nz, Voice_SetVelocity_Type0_Loop2Step
	stb_erp A, 0xFB
	ld l, a
	extz hl
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x47
	ld bc, wa
	lda_24 xde, 0x0430bb
	ld wa, hl
	ldw_sri BC, 0x07, 0xE8, 0xE4
	call ToneGen_WriteSingleReg

Voice_SetVelocity_Type0_Loop2Step:
	inc1b_erp 0xFA
	cpib_erp 0xFA, 4
	jr c, Voice_SetVelocity_Type0_Loop2Body

Voice_SetVelocity_Type0_Loop2Exit:
	ld a, (xsp + 20)
	extz wa
	call Voice_ClearLFO_ActiveFlag
	jrl Voice_SetVelocity_Exit

Voice_SetVelocity_Type40_Entry:
	ld a, (xsp + 20)
	ld e, a
	extz de
	ld a, (xsp + 26)
	ld c, a
	extz bc
	ld wa, de
	call Voice_Env_ApplyVelocity_Type0
	ld a, (xsp + 20)
	extz wa
	call Voice_Env_UpdateVelocityCounters
	lda xwa, (xsp + 2)
	ld xhl, xwa
	ld a, (xsp + 20)
	ld c, a
	extz bc
	ld a, (xsp + 18)
	ld e, a
	extz de
	ld a, (xsp + 16)
	extz wa
	pushw wa
	ld xwa, xhl
	calr Voice_NoteOn_Type2
	ldib_erp 0xFA, 0
	cpib_erp 0xFA, 4
	jr nc, Voice_SetVelocity_Type40_Loop2Start

Voice_SetVelocity_Type40_SlotLoop:
	stb_erp A, 0xFA
	extz wa
	add wa, 0xA
	lda xbc, (xsp + 2)
	ldb_sri A, 0x07, 0xE4, 0xE0
	ldb_erp A, 0xFB
	cp_erpb 0xFB, 0x40
	jr nc, Voice_SetVelocity_Type40_LoopStep
	res_dd8 7, 0x18
	stb_erp A, 0xFB
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff00
	jr __jrt_nop_02CB07
__jrt_nop_02CB07:

Voice_SetVelocity_Type40_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stb_erp A, 0xFB
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff80
	jr __jrt_nop_02CB28
__jrt_nop_02CB28:

Voice_SetVelocity_Type40_NopCont2:
	nop
	nop
	nop
	stb_erp A, 0xFB
	extz wa
	calr Voice_Release_Type4

Voice_SetVelocity_Type40_LoopStep:
	inc1b_erp 0xFA
	cpib_erp 0xFA, 4
	jr c, Voice_SetVelocity_Type40_SlotLoop

Voice_SetVelocity_Type40_Loop2Start:
	ldib_erp 0xFA, 0
	cpib_erp 0xFA, 4
	jr nc, Voice_SetVelocity_Type40_Loop2Exit

Voice_SetVelocity_Type40_Loop2Body:
	stb_erp A, 0xFA
	extz wa
	add wa, 0xA
	lda xbc, (xsp + 2)
	ldb_sri A, 0x07, 0xE4, 0xE0
	ldb_erp A, 0xFB
	cp_erpb 0xFB, 0x40
	jr nc, Voice_SetVelocity_Type40_Loop2Step
	stb_erp A, 0xFB
	ld l, a
	extz hl
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x47
	ld bc, wa
	lda_24 xde, 0x0430bb
	ld wa, hl
	ldw_sri BC, 0x07, 0xE8, 0xE4
	call ToneGen_WriteSingleReg

Voice_SetVelocity_Type40_Loop2Step:
	inc1b_erp 0xFA
	cpib_erp 0xFA, 4
	jr c, Voice_SetVelocity_Type40_Loop2Body

Voice_SetVelocity_Type40_Loop2Exit:
	ld a, (xsp + 20)
	extz wa
	call Voice_ClearLFO_ActiveFlag
	jrl Voice_SetVelocity_Exit

Voice_SetVelocity_Type80_Entry:
	lda xwa, (xsp + 2)
	ld xhl, xwa
	ld a, (xsp + 20)
	ld c, a
	extz bc
	ld a, (xsp + 18)
	ld e, a
	extz de
	ld a, (xsp + 16)
	extz wa
	pushw wa
	ld xwa, xhl
	calr Voice_NoteOn_Type1
	ldib_erp 0xFA, 0
	cpib_erp 0xFA, 2
	jrl nc, Voice_SetVelocity_Type80_Loop2Start

Voice_SetVelocity_Type80_SlotLoop:
	stb_erp A, 0xFA
	extz wa
	add wa, 0xA
	lda xbc, (xsp + 2)
	ldb_sri A, 0x07, 0xE4, 0xE0
	ldb_erp A, 0xFB
	cp_erpb 0xFB, 0x40
	jr nc, Voice_SetVelocity_Type80_LoopStep
	ld a, (xsp + 20)
	ld e, a
	extz de
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld wa, de
	call Voice_WriteChPitchWithVib
	res_dd8 7, 0x18
	stb_erp A, 0xFB
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff00
	jr __jrt_nop_02CC06
__jrt_nop_02CC06:

Voice_SetVelocity_Type80_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stb_erp A, 0xFB
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff80
	jr __jrt_nop_02CC27
__jrt_nop_02CC27:

Voice_SetVelocity_Type80_NopCont2:
	nop
	nop
	nop
	stb_erp A, 0xFB
	extz wa
	calr Voice_Init_Type2

Voice_SetVelocity_Type80_LoopStep:
	inc1b_erp 0xFA
	cpib_erp 0xFA, 2
	jr c, Voice_SetVelocity_Type80_SlotLoop

Voice_SetVelocity_Type80_Loop2Start:
	ldib_erp 0xFA, 0
	cpib_erp 0xFA, 2
	jr nc, Voice_SetVelocity_Type80_Loop2Exit

Voice_SetVelocity_Type80_Loop2Body:
	stb_erp A, 0xFA
	extz wa
	add wa, 0xA
	lda xbc, (xsp + 2)
	ldb_sri A, 0x07, 0xE4, 0xE0
	ldb_erp A, 0xFB
	cp_erpb 0xFB, 0x40
	jr nc, Voice_SetVelocity_Type80_Loop2Step
	stb_erp A, 0xFB
	ld l, a
	extz hl
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x47
	ld bc, wa
	lda_24 xde, 0x0430bb
	ld wa, hl
	ldw_sri BC, 0x07, 0xE8, 0xE4
	call ToneGen_WriteSingleReg

Voice_SetVelocity_Type80_Loop2Step:
	inc1b_erp 0xFA
	cpib_erp 0xFA, 2
	jr c, Voice_SetVelocity_Type80_Loop2Body

Voice_SetVelocity_Type80_Loop2Exit:
	ld a, (xsp + 20)
	extz wa
	call Voice_ClearLFO_ActiveFlag

Voice_SetVelocity_Exit:
	ld a, (xsp + 20)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	and_sriw_im 0x07, 0xE4, 0xE0, 0xF3, 0xFF
	popw_erp 0xFA
	lda xsp, (xsp + 20)
	retd 0x2

Voice_Allocate:
	push xiz
	lda_d16 xiz, 10846
	ld (xiz), 0x80
	extz bc
	extz wa
	sll wa, 8
	or wa, bc
	set 7, wa
	ld (xiz + 1), wa
	ldw (xiz + 3), 0x0
	ld xwa, xiz
	call NoteOn_RoutePacket
	ld xhl, xiz
	pop xiz
	ret

Voice_AllocateForRelease:
	push xiz
	lda_d16 xiz, 10846
	ld (xiz), 0x80
	extz wa
	sll wa, 8
	set 7, wa
	ld (xiz + 1), wa
	ldw (xiz + 3), 0x7F
	ld xwa, xiz
	call NoteOn_RoutePacket
	ld xhl, xiz
	pop xiz
	ret

Voice_AllocateForSustain:
	push xiz
	lda_d16 xiz, 10846
	ld (xiz), 0x40
	extz wa
	sll wa, 8
	ld (xiz + 1), wa
	ldw (xiz + 3), 0x7F
	ld xwa, xiz
	call NoteOn_RoutePacket
	ld xhl, xiz
	pop xiz
	ret

VoiceAllocate_DataTable_02CD14:
	.byte 0x3e, 0xf1, 0x5e, 0x2a, 0x36, 0xb6, 0x00, 0x00
	.byte 0xd8, 0x12, 0xd8, 0xee, 0x08, 0xd8, 0x31, 0x07
	.byte 0xbe, 0x01, 0x50, 0xbe, 0x03, 0x02, 0x7f, 0x00
	.byte 0xee, 0x88, 0x1d, 0x91, 0x26, 0x02, 0xee, 0x8b
	.byte 0x5e, 0x0e

Voice_AllocateForFull:
	push xiz
	lda_d16 xiz, 10846
	ld (xiz), 0x0
	extz wa
	sll wa, 8
	ld (xiz + 1), wa
	ldw (xiz + 3), 0xFF
	ld xwa, xiz
	call NoteOn_RoutePacket
	ld xhl, xiz
	pop xiz
	ret

Voice_AllocateForAny:
	push xiz
	lda_d16 xiz, 10846
	ld (xiz), 0x0
	ldw (xiz + 1), 0x0
	ldw (xiz + 3), 0x1FFF
	ld xwa, xiz
	call NoteOn_RoutePacket
	ld xhl, xiz
	pop xiz
	ret

Voice_Release:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	stb_dri H, 0x07, 0xE4, 0xE0
	resm 7, (xiz + 5)
	ld wa, (xiz + 1)
	extz xwa
	bit 15, wa
	jr nz, Voice_Release_BranchA
	ld xwa, (xiz + 35)
	ld wa, (xwa + 10)
	bit 0, wa
	jr nz, Voice_Release_BranchC

Voice_Release_BranchA:
	ld wa, (xiz + 1)
	bit 8, wa
	jr z, Voice_Release_BranchB
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume1
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteNote_Hold
	ld a, (xsp + 4)
	extz wa
	ld bc, (xiz + 45)
	call ToneGen_WriteSingleReg
	ld a, (xsp + 4)
	extz wa
	call VoiceSlot_Release
	andmi16 (xiz + 1), 0xFEFF
	jr Voice_Release_Exit

Voice_Release_BranchB:
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume1
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume2
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume3
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteNote
	jr Voice_Release_Exit

Voice_Release_BranchC:
	ld wa, (xiz + 1)
	bit 8, wa
	jr z, Voice_Release_BranchD
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume1
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteNote_Hold
	ld a, (xsp + 4)
	extz wa
	ld bc, (xiz + 45)
	call ToneGen_WriteSingleReg
	ld a, (xsp + 4)
	extz wa
	call VoiceSlot_Release
	andmi16 (xiz + 1), 0xFEFF
	jr Voice_Release_Exit

Voice_Release_BranchD:
	ld xwa, xiz
	call Voice_WritePan_Passthrough
	ld a, (xsp + 4)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteNote_Stereo

Voice_Release_Exit:
	pop xiz
	inc 2, xsp
	ret

Voice_Cut:
	dec 8, xsp
	push xiz
	ld (xsp + 10), a
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	stb_dri H, 0x07, 0xE4, 0xE0
	ld xwa, (xiz + 35)
	ld (xsp + 4), xwa
	resm 7, (xiz + 5)
	ld xwa, (xsp + 4)
	ld wa, (xwa + 10)
	ld (xsp + 8), wa
	cp (xiz + 3), 0x3
	jr nz, Voice_Cut_BranchA
	ld xwa, (xsp + 4)
	andmi16 (xwa + 10), 0xFFFE

Voice_Cut_BranchA:
	ld wa, (xiz + 1)
	extz xwa
	bit 15, wa
	jr nz, Voice_Cut_BranchB
	ld xwa, (xiz + 35)
	ld wa, (xwa + 10)
	bit 0, wa
	jr nz, Voice_Cut_Exit

Voice_Cut_BranchB:
	cp (xiz + 3), 0x3
	jr nc, Voice_Cut_BranchC
	ld xwa, xiz
	call Voice_ComputeVolume_CappedLFO
	jr Voice_Cut_BranchD

Voice_Cut_BranchC:
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume1

Voice_Cut_BranchD:
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume2
	ld xwa, xiz
	call Voice_ComputeAndWriteVolume3
	ld a, (xsp + 10)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteNote

Voice_Cut_Exit:
	ld xwa, (xsp + 4)
	ld bc, (xsp + 8)
	ld (xwa + 10), bc
	pop xiz
	inc 8, xsp
	ret

Voice_ReleaseSingle:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	exts xwa
	add xwa, xbc
	resm 7, (xwa + 5)
	cp (xwa + 70), 0x0
	jr z, Voice_ReleaseSingle_Exit
	call Voice_WriteVolume_Muted
	ld a, (xsp)
	extz wa
	lda_24 xbc, 0x0451cc
	call ToneGen_WriteNote

Voice_ReleaseSingle_Exit:
	inc 2, xsp
	ret

Voice_ParamInit:
	dec 4, xsp
	push xiz
	inc 5, xwa
	ld xiz, xwa
	lda_24 xwa, 0x04308e
	ld (xsp + 4), xwa
	cp (xiz), 0x40
	jr nc, Voice_ParamInit_LoopStep

Voice_ParamInit_LoopBody:
	ld a, (xiz)
	extz wa
	muls wa, 0x47
	ld bc, wa
	ld xwa, (xsp + 4)
	exts xbc
	add xbc, xwa
	ld wa, (xbc + 1)
	and wa, 0x3C
	cp wa, 0x20
	jr z, Voice_ParamInit_BranchE
	cp wa, 0x10
	jr z, Voice_ParamInit_BranchD
	cp wa, 0x8
	jr z, Voice_ParamInit_BranchC
	cps wa, 4
	jr nz, Voice_ParamInit_BranchF
	cpw (xbc + 47), 0x0
	jr z, Voice_ParamInit_BranchA
	ormi16 (xbc + 47), 0x80
	jr Voice_ParamInit_BranchF

Voice_ParamInit_BranchA:
	cpw (xbc + 49), 0xFF
	jr z, Voice_ParamInit_BranchB
	andmi16 (xbc + 49), 0x9FFF
	ormi16 (xbc + 49), 0x1000
	jr Voice_ParamInit_BranchF

Voice_ParamInit_BranchB:
	ld a, (xiz)
	extz wa
	calr Voice_Release
	jr Voice_ParamInit_BranchF

Voice_ParamInit_BranchC:
	ld a, (xiz)
	extz wa
	calr Voice_Cut
	jr Voice_ParamInit_BranchF

Voice_ParamInit_BranchD:
	ld a, (xiz)
	extz wa
	calr Voice_ReleaseSingle
	jr Voice_ParamInit_BranchF

Voice_ParamInit_BranchE:
	ld a, (xiz)
	extz wa
	calr Voice_Release

Voice_ParamInit_BranchF:
	inc 1, xiz
	cp (xiz), 0x40
	jr c, Voice_ParamInit_LoopBody

Voice_ParamInit_LoopStep:
	pop xiz
	inc 4, xsp
	ret

; ===========================================================================
; Voice_NoteOn - Process MIDI Note On messages
; ===========================================================================
; Entry: XWA = pointer to 4-byte note data:
;        +0 = status byte (0x9n where n=channel)
;        +1 = channel number (0-25)
;        +2 = note number (0-127)
;        +3 = velocity (0-127, 0 = note off)
; Exit:  Voice allocated and parameters set for new note
; Notes: Allocates voice slot, sets pitch via Voice_SetPitch
;        Sets velocity via Voice_SetVelocity
;        Velocity 0 triggers note-off via Voice_NoteOff
; ===========================================================================
Voice_NoteOn:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	cp (xiz + 1), 0x1A
	jr ge, Voice_NoteOn_Exit
	ld a, (xiz)
	and a, 0x7
	ld (xsp + 4), a
	ld a, (xiz + 3)
	res 7, a
	cps a, 0
	jr z, Voice_NoteOn_ZeroVelocity
	ld a, (xiz)
	and a, 0x8
	call RingBuf_SetOffsetLo
	ld l, (xiz + 1)
	ld c, (xiz + 2)
	ld e, (xiz + 3)
	ld a, (xsp + 4)
	extz wa
	pushw wa
	ld a, l
	calr Voice_SetVelocity
	ld l, (xiz + 1)
	ld c, (xiz + 2)
	ld e, (xiz + 3)
	ld a, (xsp + 4)
	extz wa
	pushw wa
	ld a, l
	calr Voice_SetPitch
	jr Voice_NoteOn_Exit

Voice_NoteOn_ZeroVelocity:
	ld a, (xiz + 1)
	ld c, (xiz + 2)
	calr Voice_Allocate
	ld xwa, xhl
	calr Voice_ParamInit
	ld l, (xiz + 1)
	ld c, (xiz + 2)
	ld e, (xiz + 3)
	ld a, (xsp + 4)
	extz wa
	pushw wa
	ld a, l
	calr Voice_NoteOff

Voice_NoteOn_Exit:
	pop xiz
	inc 2, xsp
	ret

Voice_SetPanning:
	push xiz
	ld xiz, xwa
	ldw_da xwa, 0x041360
	srl wa, 8
	or wa, 0x1480
	ld (xiz), wa
	ld (xiz + 2), 0x80
	ld (xiz + 6), 0x0
	ld (xiz + 3), 0x0
	ld (xiz + 4), 0x0
	ld (xiz + 5), 0x0
	ld xwa, xiz
	call NoteOn_Dispatch
	cp (xiz + 10), 0x40
	jr nc, Voice_SetPanning_Exit
	ld a, (xiz + 10)
	extz wa
	muls wa, 0x47
	lda_24 xbc, 0x04308e
	stb_dri A, 0x07, 0xE4, 0xE0
	ldw_da xwa, 0x041360
	ld (xbc + 8), wa
	ldw_da xwa, 0x041360
	ld (xbc + 6), wa
	ldw (xbc + 1), 0x1
	lds32 xwa, 0
	ld (xbc + 19), xwa
	lds32 xwa, 0
	ld (xbc + 23), xwa
	lds32 xwa, 0
	ld (xbc + 27), xwa
	lds32 xwa, 0
	ld (xbc + 31), xwa
	lds32 xwa, 0
	ld (xbc + 39), xwa
	ld (xbc + 12), 0x0
	ld (xbc + 4), 0x14
	ldw_da xwa, 0x041360
	srl wa, 8
	ld (xbc + 5), a
	ld a, (xiz + 10)
	ld (xbc), a
	ld (xbc + 3), 0x0
	ldw (xbc + 47), 0x0
	ldw (xbc + 49), 0xFF
	ld (xbc + 53), 0x0
	ldw (xbc + 54), 0x0
	ldw (xbc + 58), 0x0
	ldw (xbc + 56), 0x0

Voice_SetPanning_Exit:
	pop xiz
	ret

ToneGen_WritePanReg:
	push xiz
	ld xiz, xbc
	res_dd8 7, 0x18
	add wa, 0x400
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 14)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D0D7
__jrt_nop_02D0D7:

ToneGen_WritePanReg_NopCont:
	nop
	nop
	nop
	pop xiz
	ret

ToneGen_PanTable_02D0DC:
	.byte 0x3e, 0xe9, 0x8e, 0xf0, 0x18, 0xb7, 0xd8, 0xc8
	.byte 0x80, 0x00, 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00
	.byte 0xf0, 0x18, 0xbf, 0x9e, 0x04, 0x20, 0xd8, 0x30
	.byte 0x0f, 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68, 0x00
	.byte 0x00, 0x00, 0x00, 0x5e, 0x0e

ToneGen_WriteVoiceParams:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	lds wa, 0
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x40
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 2)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D12A
__jrt_nop_02D12A:

ToneGen_WriteVoiceParams_NopCont01:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x80
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 4)
	set 15, wa
	stw_da 0x100002, xwa
	jr __jrt_nop_02D14F
__jrt_nop_02D14F:

ToneGen_WriteVoiceParams_NopCont02:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0xC0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 6)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D171
__jrt_nop_02D171:

ToneGen_WriteVoiceParams_NopCont03:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x100
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 8)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D193
__jrt_nop_02D193:

ToneGen_WriteVoiceParams_NopCont04:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x140
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 10)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D1B5
__jrt_nop_02D1B5:

ToneGen_WriteVoiceParams_NopCont05:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x180
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 12)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D1D7
__jrt_nop_02D1D7:

ToneGen_WriteVoiceParams_NopCont06:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x400
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 14)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D1F9
__jrt_nop_02D1F9:

ToneGen_WriteVoiceParams_NopCont07:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x440
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 16)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D21B
__jrt_nop_02D21B:

ToneGen_WriteVoiceParams_NopCont08:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x480
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 18)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D23D
__jrt_nop_02D23D:

ToneGen_WriteVoiceParams_NopCont09:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x4C0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 20)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D25F
__jrt_nop_02D25F:

ToneGen_WriteVoiceParams_NopCont10:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x500
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 22)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D281
__jrt_nop_02D281:

ToneGen_WriteVoiceParams_NopCont11:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 24)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D2A3
__jrt_nop_02D2A3:

ToneGen_WriteVoiceParams_NopCont12:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x8100
	jr __jrt_nop_02D2BD
__jrt_nop_02D2BD:

ToneGen_WriteVoiceParams_NopCont13:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 26)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D2DF
__jrt_nop_02D2DF:

ToneGen_WriteVoiceParams_NopCont14:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x880
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 28)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D301
__jrt_nop_02D301:

ToneGen_WriteVoiceParams_NopCont15:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x8C0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 30)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D323
__jrt_nop_02D323:

ToneGen_WriteVoiceParams_NopCont16:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x900
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 32)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D345
__jrt_nop_02D345:

ToneGen_WriteVoiceParams_NopCont17:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x940
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 34)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D367
__jrt_nop_02D367:

ToneGen_WriteVoiceParams_NopCont18:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x980
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 36)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D389
__jrt_nop_02D389:

ToneGen_WriteVoiceParams_NopCont19:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x9C0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 38)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D3AB
__jrt_nop_02D3AB:

ToneGen_WriteVoiceParams_NopCont20:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0xA00
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 40)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D3CD
__jrt_nop_02D3CD:

ToneGen_WriteVoiceParams_NopCont21:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0xA40
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 42)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D3EF
__jrt_nop_02D3EF:

ToneGen_WriteVoiceParams_NopCont22:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x80
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 4)
	res 15, wa
	stw_da 0x100002, xwa
	jr __jrt_nop_02D414
__jrt_nop_02D414:

ToneGen_WriteVoiceParams_Exit:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

ToneGen_WriteSingleReg:
	pushw iz
	ld iz, bc
	res_dd8 7, 0x18
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stw_da 0x100002, xiz
	jr __jrt_nop_02D431
__jrt_nop_02D431:

ToneGen_WriteSingleReg_NopCont:
	nop
	nop
	nop
	popw iz
	ret

ToneGen_WriteNote:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 46)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D45D
__jrt_nop_02D45D:

ToneGen_WriteNote_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x940
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 50)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D47F
__jrt_nop_02D47F:

ToneGen_WriteNote_NopCont2:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0xA00
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 54)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D4A1
__jrt_nop_02D4A1:

ToneGen_WriteNote_NopCont3:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 44)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D4C3
__jrt_nop_02D4C3:

ToneGen_WriteNote_NopCont4:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x900
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 48)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D4E5
__jrt_nop_02D4E5:

ToneGen_WriteNote_NopCont5:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x9C0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 52)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D507
__jrt_nop_02D507:

ToneGen_WriteNote_NopCont6:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

ToneGen_WriteNote_2Regs:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 46)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D535
__jrt_nop_02D535:

ToneGen_WriteNote_2Regs_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 44)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D557
__jrt_nop_02D557:

ToneGen_WriteNote_2Regs_NopCont2:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

ToneGen_NoteTable_02D55E:
	push xiz
	ld	xiz, xbc
	.byte 0xf0, 0x18, 0xb7
	add	wa, 2112
	stw_da	1048576, wa
	nop
	.byte 0xf0, 0x18, 0xbf
	ld	wa, (xiz+46)
	stw_da	1048578, wa
	jr	t, 0
	nop
	nop
	nop
	pop xiz
	ret
	dec	4, xsp
	pushw iz
	ld	(xsp+2), xbc
	ld	iz, wa
	.byte 0xf0, 0x18, 0xb7
	ld	wa, iz
	add	wa, 256
	stw_da	1048576, wa
	nop
	.byte 0xf0, 0x18, 0xbf
	ld	xwa, (xsp+2)
	ld	wa, (xwa+8)
	stw_da	1048578, wa
	jr	t, 0
	nop
	nop
	nop
	.byte 0xf0, 0x18, 0xb7
	ld	wa, iz
	add	wa, 320
	stw_da	1048576, wa
	nop
	.byte 0xf0, 0x18, 0xbf
	ld	xwa, (xsp+2)
	ld	wa, (xwa+10)
	stw_da	1048578, wa
	jr	t, 0
	nop
	nop
	nop
	popw iz
	.byte 0xef
	jr	ov, 0x0e

ToneGen_WriteNote_Stereo:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 26)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D5F7
__jrt_nop_02D5F7:

ToneGen_WriteNote_Stereo_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x880
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 28)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D619
__jrt_nop_02D619:

ToneGen_WriteNote_Stereo_NopCont2:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

ToneGen_WriteNote_Hold:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 46)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D647
__jrt_nop_02D647:

ToneGen_WriteNote_Hold_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x880
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 46)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D669
__jrt_nop_02D669:

ToneGen_WriteNote_Hold_NopCont2:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

ToneGen_WriteSingleReg_180:
	pushw iz
	ld iz, bc
	res_dd8 7, 0x18
	add wa, 0x180
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stw_da 0x100002, xiz
	jr __jrt_nop_02D68A
__jrt_nop_02D68A:

ToneGen_WriteSingleReg_180_NopCont:
	nop
	nop
	nop
	popw iz
	ret

ToneGen_WriteVoiceParams_Ext:
	dec 8, xsp
	pushw iz
	ld (xsp + 2), xde
	ld (xsp + 6), xbc
	ld iz, wa
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 60)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D6B9
__jrt_nop_02D6B9:

ToneGen_WriteVoiceParams_Ext_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x8100
	jr __jrt_nop_02D6D3
__jrt_nop_02D6D3:

ToneGen_WriteVoiceParams_Ext_NopCont2:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 62)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D6F5
__jrt_nop_02D6F5:

ToneGen_WriteVoiceParams_Ext_NopCont3:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x80
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 6)
	ld wa, (xwa + 4)
	res 15, wa
	stw_da 0x100002, xwa
	jr __jrt_nop_02D71A
__jrt_nop_02D71A:

ToneGen_WriteVoiceParams_Ext_NopCont4:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 45)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D738
__jrt_nop_02D738:

ToneGen_WriteVoiceParams_Ext_NopCont5:
	nop
	nop
	nop
	popw iz
	inc 8, xsp
	ret

ToneGen_WriteVoiceParams_Ext2:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 60)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D766
__jrt_nop_02D766:

ToneGen_WriteVoiceParams_Ext2_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x8100
	jr __jrt_nop_02D780
__jrt_nop_02D780:

ToneGen_WriteVoiceParams_Ext2_NopCont2:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 62)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D7A2
__jrt_nop_02D7A2:

ToneGen_WriteVoiceParams_Ext2_NopCont3:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 45)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D7C0
__jrt_nop_02D7C0:

ToneGen_WriteVoiceParams_Ext2_NopCont4:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

ToneGen_WriteGlobalConfig:
	push xiz
	ld xiz, xwa
	ldw_da xwa, 0x041343
	bit 3, wa
	jr z, ToneGen_WriteGlobalConfig_BranchA
	andmi16 (xiz), 0xFFF7
	jr ToneGen_WriteGlobalConfig_BranchB

ToneGen_WriteGlobalConfig_BranchA:
	ormi16 (xiz), 0x8

ToneGen_WriteGlobalConfig_BranchB:
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0200
	nop
	set_dd8 7, 0x18
	ld wa, (xiz)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D7F5
__jrt_nop_02D7F5:

ToneGen_WriteGlobalConfig_NopCont01:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0201
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 2)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D810
__jrt_nop_02D810:

ToneGen_WriteGlobalConfig_NopCont02:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0202
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 4)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D82B
__jrt_nop_02D82B:

ToneGen_WriteGlobalConfig_NopCont03:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0203
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 6)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D846
__jrt_nop_02D846:

ToneGen_WriteGlobalConfig_NopCont04:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0204
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 8)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D861
__jrt_nop_02D861:

ToneGen_WriteGlobalConfig_NopCont05:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0205
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 10)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D87C
__jrt_nop_02D87C:

ToneGen_WriteGlobalConfig_NopCont06:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0c00
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 12)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D897
__jrt_nop_02D897:

ToneGen_WriteGlobalConfig_NopCont07:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0c01
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 14)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D8B2
__jrt_nop_02D8B2:

ToneGen_WriteGlobalConfig_NopCont08:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0c02
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 16)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D8CD
__jrt_nop_02D8CD:

ToneGen_WriteGlobalConfig_NopCont09:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0c03
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 18)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D8E8
__jrt_nop_02D8E8:

ToneGen_WriteGlobalConfig_NopCont10:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0c04
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 20)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D903
__jrt_nop_02D903:

ToneGen_WriteGlobalConfig_NopCont11:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0c05
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 22)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D91E
__jrt_nop_02D91E:

ToneGen_WriteGlobalConfig_NopCont12:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stiw_da 0x100000, 0x0e00
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 24)
	stw_da 0x100002, xwa
	jr __jrt_nop_02D939
__jrt_nop_02D939:

ToneGen_WriteGlobalConfig_NopCont13:
	nop
	nop
	nop
	pop xiz
	ret

ToneGen_GlobalConfigTable_02D93E:
	.byte 0xef, 0x6c, 0x2e, 0xbf, 0x02, 0x61, 0xd8, 0x8e
	.byte 0xf0, 0x18, 0xb7, 0xde, 0x88, 0xd8, 0xc8, 0x40
	.byte 0x04, 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00, 0xf0
	.byte 0x18, 0xbf, 0xaf, 0x02, 0x20, 0x98, 0x10, 0x20
	.byte 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68, 0x00, 0x00
	.byte 0x00, 0x00, 0xf0, 0x18, 0xb7, 0xde, 0x88, 0xd8
	.byte 0xc8, 0x80, 0x04, 0xf2, 0x00, 0x00, 0x10, 0x50
	.byte 0x00, 0xf0, 0x18, 0xbf, 0xaf, 0x02, 0x20, 0x98
	.byte 0x12, 0x20, 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68
	.byte 0x00, 0x00, 0x00, 0x00, 0x4e, 0xef, 0x64, 0x0e
	.byte 0x3e, 0xe9, 0x8e, 0xf0, 0x18, 0xb7, 0xd8, 0xc8
	.byte 0x80, 0x01, 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00
	.byte 0xf0, 0x18, 0xbf, 0x9e, 0x0c, 0x20, 0xf2, 0x02
	.byte 0x00, 0x10, 0x50, 0x68, 0x00, 0x00, 0x00, 0x00
	.byte 0x5e, 0x0e, 0x3e, 0xe9, 0x8e, 0xf0, 0x18, 0xb7
	.byte 0xd8, 0xc8, 0x40, 0x04, 0xf2, 0x00, 0x00, 0x10
	.byte 0x50, 0x00, 0xf0, 0x18, 0xbf, 0x9e, 0x10, 0x20
	.byte 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68, 0x00, 0x00
	.byte 0x00, 0x00, 0x5e, 0x0e, 0x3e, 0xe9, 0x8e, 0xf0
	.byte 0x18, 0xb7, 0xd8, 0xc8, 0x80, 0x04, 0xf2, 0x00
	.byte 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18, 0xbf, 0x9e
	.byte 0x12, 0x20, 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68
	.byte 0x00, 0x00, 0x00, 0x00, 0x5e, 0x0e, 0x3e, 0xe9
	.byte 0x8e, 0xf0, 0x18, 0xb7, 0xd8, 0xc8, 0xc0, 0x04
	.byte 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18
	.byte 0xbf, 0x9e, 0x14, 0x20, 0xf2, 0x02, 0x00, 0x10
	.byte 0x50, 0x68, 0x00, 0x00, 0x00, 0x00, 0x5e, 0x0e

ToneGen_WriteExtParams_56:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	ld xwa, (xsp + 2)
	ld wa, (xwa + 60)
	bit 15, wa
	jr z, ToneGen_WriteExtParams_56_BranchSkip
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x580
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 60)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DA48
__jrt_nop_02DA48:

ToneGen_WriteExtParams_56_NopCont1:
	nop
	nop
	nop

ToneGen_WriteExtParams_56_BranchSkip:
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x600
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 64)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DA6A
__jrt_nop_02DA6A:

ToneGen_WriteExtParams_56_NopCont2:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x580
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 60)
	res 15, wa
	stw_da 0x100002, xwa
	jr __jrt_nop_02DA8F
__jrt_nop_02DA8F:

ToneGen_WriteExtParams_56_NopCont3:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

ToneGen_WriteExtParam_600:
	push xiz
	ld xiz, xbc
	res_dd8 7, 0x18
	add wa, 0x600
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 64)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DAB3
__jrt_nop_02DAB3:

ToneGen_WriteExtParam_600_NopCont:
	nop
	nop
	nop
	pop xiz
	ret

ToneGen_WriteExtParams_56_Alt:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	ld xwa, (xsp + 2)
	ld wa, (xwa + 60)
	bit 15, wa
	jr z, ToneGen_WriteExtParams_56_Alt_ClearPath
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x580
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 60)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DAEA
__jrt_nop_02DAEA:

ToneGen_WriteExtParams_56_Alt_NopCont1:
	nop
	nop
	nop

ToneGen_WriteExtParams_56_Alt_ClearPath:
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x580
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 60)
	res 15, wa
	stw_da 0x100002, xwa
	jr __jrt_nop_02DB0F
__jrt_nop_02DB0F:

ToneGen_WriteExtParams_56_Alt_NopCont2:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

ToneGen_WriteExtParam_600_Mute:
	res_dd8 7, 0x18
	add wa, 0x580
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x8100
	jr __jrt_nop_02DB2F
__jrt_nop_02DB2F:

ToneGen_WriteExtParam_600_Mute_NopCont:
	nop
	nop
	nop
	ret

ToneGen_WriteExtParams_56b:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	ld xwa, (xsp + 2)
	ld wa, (xwa + 62)
	bit 15, wa
	jr z, ToneGen_WriteExtParams_56b_ClearPath
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x5C0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 62)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DB65
__jrt_nop_02DB65:

ToneGen_WriteExtParams_56b_NopCont1:
	nop
	nop
	nop

ToneGen_WriteExtParams_56b_ClearPath:
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x640
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 66)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DB87
__jrt_nop_02DB87:

ToneGen_WriteExtParams_56b_NopCont2:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x5C0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 62)
	res 15, wa
	stw_da 0x100002, xwa
	jr __jrt_nop_02DBAC
__jrt_nop_02DBAC:

ToneGen_WriteExtParams_56b_NopCont3:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

ToneGen_ExtParams56b_DataTable:
	.byte 0x3e, 0xe9, 0x8e, 0xf0, 0x18, 0xb7, 0xd8, 0xc8
	.byte 0x40, 0x06, 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00
	.byte 0xf0, 0x18, 0xbf, 0x9e, 0x42, 0x20, 0xf2, 0x02
	.byte 0x00, 0x10, 0x50, 0x68, 0x00, 0x00, 0x00, 0x00
	.byte 0x5e, 0x0e, 0xef, 0x6c, 0x2e, 0xbf, 0x02, 0x61
	.byte 0xd8, 0x8e, 0xaf, 0x02, 0x20, 0x98, 0x3e, 0x20
	.byte 0xd8, 0x33, 0x0f, 0x66, 0x22, 0xf0, 0x18, 0xb7
	.byte 0xde, 0x88, 0xd8, 0xc8, 0xc0, 0x05, 0xf2, 0x00
	.byte 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18, 0xbf, 0xaf
	.byte 0x02, 0x20, 0x98, 0x3e, 0x20, 0xf2, 0x02, 0x00
	.byte 0x10, 0x50, 0x68, 0x00, 0x00, 0x00, 0x00, 0xf0
	.byte 0x18, 0xb7, 0xde, 0x88, 0xd8, 0xc8, 0xc0, 0x05
	.byte 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18
	.byte 0xbf, 0xaf, 0x02, 0x20, 0x98, 0x3e, 0x20, 0xd8
	.byte 0x30, 0x0f, 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68
	.byte 0x00, 0x00, 0x00, 0x00, 0x4e, 0xef, 0x64, 0x0e
	.byte 0xf0, 0x18, 0xb7, 0xd8, 0xc8, 0xc0, 0x05, 0xf2
	.byte 0x00, 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18, 0xbf
	.byte 0xf2, 0x02, 0x00, 0x10, 0x02, 0x00, 0x81, 0x68
	.byte 0x00, 0x00, 0x00, 0x00, 0x0e

ToneGen_WriteExtParams_15:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	ld xwa, (xsp + 2)
	ld wa, (xwa + 58)
	bit 15, wa
	jr z, ToneGen_WriteExtParams_15_ClearPath
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x540
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 58)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DC82
__jrt_nop_02DC82:

ToneGen_WriteExtParams_15_NopCont1:
	nop
	nop
	nop

ToneGen_WriteExtParams_15_ClearPath:
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x1C0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 56)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DCA4
__jrt_nop_02DCA4:

ToneGen_WriteExtParams_15_NopCont2:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x540
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 58)
	res 15, wa
	stw_da 0x100002, xwa
	jr __jrt_nop_02DCC9
__jrt_nop_02DCC9:

ToneGen_WriteExtParams_15_NopCont3:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

ToneGen_WriteExtParam_1C0_Single:
	push xiz
	ld xiz, xbc
	res_dd8 7, 0x18
	add wa, 0x1C0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 56)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DCED
__jrt_nop_02DCED:

ToneGen_WriteExtParam_1C0_Single_NopCont:
	nop
	nop
	nop
	pop xiz
	ret

ToneGen_WriteExtParams_15_Alt:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	ld xwa, (xsp + 2)
	ld wa, (xwa + 58)
	bit 15, wa
	jr z, ToneGen_WriteExtParams_15_Alt_ClearPath
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x540
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 58)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DD24
__jrt_nop_02DD24:

ToneGen_WriteExtParams_15_Alt_NopCont1:
	nop
	nop
	nop

ToneGen_WriteExtParams_15_Alt_ClearPath:
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x540
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 58)
	res 15, wa
	stw_da 0x100002, xwa
	jr __jrt_nop_02DD49
__jrt_nop_02DD49:

ToneGen_WriteExtParams_15_Alt_NopCont2:
	nop
	nop
	nop
	popw iz
	inc 4, xsp
	ret

ToneGen_WriteExtParam_540_Mute:
	res_dd8 7, 0x18
	add wa, 0x540
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x8100
	jr __jrt_nop_02DD69
__jrt_nop_02DD69:

ToneGen_WriteExtParam_540_Mute_NopCont:
	nop
	nop
	nop
	ret

ToneGen_ExtParams15_DataTable:
	.byte 0xef, 0x6c, 0x2e, 0xbf, 0x02, 0x61, 0xd8, 0x8e
	.byte 0xde, 0xcf, 0x40, 0x00, 0x6f, 0x76, 0xaf, 0x02
	.byte 0x20, 0x98, 0x3a, 0x20, 0xd8, 0x33, 0x0f, 0x66
	.byte 0x22, 0xf0, 0x18, 0xb7, 0xde, 0x88, 0xd8, 0xc8
	.byte 0x40, 0x05, 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00
	.byte 0xf0, 0x18, 0xbf, 0xaf, 0x02, 0x20, 0x98, 0x3a
	.byte 0x20, 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68, 0x00
	.byte 0x00, 0x00, 0x00, 0xf0, 0x18, 0xb7, 0xde, 0x88
	.byte 0xd8, 0xc8, 0xc0, 0x01, 0xf2, 0x00, 0x00, 0x10
	.byte 0x50, 0x00, 0xf0, 0x18, 0xbf, 0xaf, 0x02, 0x20
	.byte 0x98, 0x38, 0x20, 0xf2, 0x02, 0x00, 0x10, 0x50
	.byte 0x68, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x18, 0xb7
	.byte 0xde, 0x88, 0xd8, 0xc8, 0x40, 0x05, 0xf2, 0x00
	.byte 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18, 0xbf, 0xaf
	.byte 0x02, 0x20, 0x98, 0x3a, 0x20, 0xd8, 0x30, 0x0f
	.byte 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68, 0x00, 0x00
	.byte 0x00, 0x00, 0x68, 0x74, 0xaf, 0x02, 0x20, 0x98
	.byte 0x3e, 0x20, 0xd8, 0x33, 0x0f, 0x66, 0x22, 0xf0
	.byte 0x18, 0xb7, 0xde, 0x88, 0xd8, 0xc8, 0x80, 0x05
	.byte 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00, 0xf0, 0x18
	.byte 0xbf, 0xaf, 0x02, 0x20, 0x98, 0x3e, 0x20, 0xf2
	.byte 0x02, 0x00, 0x10, 0x50, 0x68, 0x00, 0x00, 0x00
	.byte 0x00, 0xf0, 0x18, 0xb7, 0xde, 0x88, 0xd8, 0xc8
	.byte 0x00, 0x06, 0xf2, 0x00, 0x00, 0x10, 0x50, 0x00
	.byte 0xf0, 0x18, 0xbf, 0xaf, 0x02, 0x20, 0x98, 0x42
	.byte 0x20, 0xf2, 0x02, 0x00, 0x10, 0x50, 0x68, 0x00
	.byte 0x00, 0x00, 0x00, 0xf0, 0x18, 0xb7, 0xde, 0x88
	.byte 0xd8, 0xc8, 0x80, 0x05, 0xf2, 0x00, 0x00, 0x10
	.byte 0x50, 0x00, 0xf0, 0x18, 0xbf, 0xaf, 0x02, 0x20
	.byte 0x98, 0x3e, 0x20, 0xd8, 0x30, 0x0f, 0xf2, 0x02
	.byte 0x00, 0x10, 0x50, 0x68, 0x00, 0x00, 0x00, 0x00
	.byte 0x4e, 0xef, 0x64, 0x0e

ToneGen_WriteExtParam_TypeDispatch_Single:
	push xiz
	ld xiz, xbc
	cp wa, 0x40
	jr nc, ToneGen_WriteExtParam_TypeDispatch_Single_HiPath
	res_dd8 7, 0x18
	add wa, 0x1C0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 56)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DE8C
__jrt_nop_02DE8C:

ToneGen_WriteExtParam_TypeDispatch_Single_NopCont1:
	nop
	nop
	nop
	jr ToneGen_WriteExtParam_TypeDispatch_Single_Exit

ToneGen_WriteExtParam_TypeDispatch_Single_HiPath:
	res_dd8 7, 0x18
	add wa, 0x600
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld wa, (xiz + 66)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DEAB
__jrt_nop_02DEAB:

ToneGen_WriteExtParam_TypeDispatch_Single_NopCont2:
	nop
	nop
	nop

ToneGen_WriteExtParam_TypeDispatch_Single_Exit:
	pop xiz
	ret

ToneGen_WriteExtParams_TypeDispatch:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	cp iz, 0x40
	jr nc, ToneGen_WriteExtParams_TypeDispatch_HiPath
	ld xwa, (xsp + 2)
	ld wa, (xwa + 58)
	bit 15, wa
	jr z, ToneGen_WriteExtParams_TypeDispatch_LoClearPath
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x540
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 58)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DEE8
__jrt_nop_02DEE8:

ToneGen_WriteExtParams_TypeDispatch_NopCont1:
	nop
	nop
	nop

ToneGen_WriteExtParams_TypeDispatch_LoClearPath:
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x540
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 58)
	res 15, wa
	stw_da 0x100002, xwa
	jr __jrt_nop_02DF0D
__jrt_nop_02DF0D:

ToneGen_WriteExtParams_TypeDispatch_NopCont2:
	nop
	nop
	nop
	jr ToneGen_WriteExtParams_TypeDispatch_Exit

ToneGen_WriteExtParams_TypeDispatch_HiPath:
	ld xwa, (xsp + 2)
	ld wa, (xwa + 62)
	bit 15, wa
	jr z, ToneGen_WriteExtParams_TypeDispatch_HiClearPath
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x580
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 62)
	stw_da 0x100002, xwa
	jr __jrt_nop_02DF3C
__jrt_nop_02DF3C:

ToneGen_WriteExtParams_TypeDispatch_NopCont3:
	nop
	nop
	nop

ToneGen_WriteExtParams_TypeDispatch_HiClearPath:
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x580
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 2)
	ld wa, (xwa + 62)
	res 15, wa
	stw_da 0x100002, xwa
	jr __jrt_nop_02DF61
__jrt_nop_02DF61:

ToneGen_WriteExtParams_TypeDispatch_NopCont4:
	nop
	nop
	nop

ToneGen_WriteExtParams_TypeDispatch_Exit:
	popw iz
	inc 4, xsp
	ret

ToneGen_WriteExtParam_Mute_TypeDispatch:
	cp wa, 0x40
	jr nc, ToneGen_WriteExtParam_Mute_TypeDispatch_HiPath
	res_dd8 7, 0x18
	add wa, 0x540
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x8100
	jr __jrt_nop_02DF87
__jrt_nop_02DF87:

ToneGen_WriteExtParam_Mute_TypeDispatch_NopCont1:
	nop
	nop
	nop
	ret

ToneGen_WriteExtParam_Mute_TypeDispatch_HiPath:
	res_dd8 7, 0x18
	add wa, 0x580
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x8100
	jr __jrt_nop_02DFA4
__jrt_nop_02DFA4:

ToneGen_WriteExtParam_Mute_TypeDispatch_NopCont2:
	nop
	nop
	nop
	ret

DSP_Config_Init:
	dec 4, xsp
	pushw iz
	lda_24 xwa, 0x00f8bb
	calr ToneGen_WriteGlobalConfig
	lda_d16 xwa, 10916
	ld (xsp + 2), xwa
	ld xiy, 0xF8D5
	ld xix, xwa
	ldw bc, 0x22
	ldirw
	lds iz, 0
	cp iz, 0x40
	jrl nc, ToneGen_ConfigInit_Return

ToneGen_Config_Init:
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff00
	jr __jrt_nop_02DFEA
__jrt_nop_02DFEA:

ToneGen_Config_Init_NopCont1:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff80
	jr __jrt_nop_02E008
__jrt_nop_02E008:

ToneGen_ConfigInit_WriteVoiceRegs:
	nop
	nop
	nop
	ld wa, iz
	ld xbc, (xsp + 2)
	calr ToneGen_WriteVoiceParams
	ld wa, iz
	ld xbc, (xsp + 2)
	ld bc, (xbc)
	calr ToneGen_WriteSingleReg
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff00
	jr __jrt_nop_02E038
__jrt_nop_02E038:

ToneGen_ConfigInit_WriteAddr800:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff80
	jr __jrt_nop_02E056
__jrt_nop_02E056:

ToneGen_ConfigInit_WriteAddrC0:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0xC0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x0000
	jr __jrt_nop_02E074
__jrt_nop_02E074:

ToneGen_ConfigInit_WriteAddr00:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0x7e00
	jr __jrt_nop_02E08E
__jrt_nop_02E08E:

ToneGen_ConfigInit_WriteExtParams:
	nop
	nop
	nop
	ld wa, iz
	ld xbc, (xsp + 2)
	calr ToneGen_WriteExtParams_15
	ld wa, iz
	ld xbc, (xsp + 2)
	calr ToneGen_WriteExtParams_56
	ld wa, iz
	ld xbc, (xsp + 2)
	calr ToneGen_WriteExtParams_56b
	inc 1, iz
	cp iz, 0x40
	jrl c, ToneGen_Config_Init

ToneGen_ConfigInit_Return:
	popw iz
	inc 4, xsp
	ret

ToneGen_ConfigInit_AltData:
	.byte 0x3e, 0x36, 0xff, 0xff, 0xf0, 0x18, 0xb7, 0xf2
	.byte 0x00, 0x00, 0x10, 0x02, 0x40, 0x08, 0x00, 0xf0
	.byte 0x18, 0xbf, 0xf2, 0x02, 0x00, 0x10, 0x02, 0x00
	.byte 0xff, 0x68, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x18
	.byte 0xb7, 0xf2, 0x00, 0x00, 0x10, 0x02, 0x00, 0x08
	.byte 0x00, 0xf0, 0x18, 0xbf, 0xf2, 0x02, 0x00, 0x10
	.byte 0x02, 0x80, 0xff, 0x68, 0x00, 0x00, 0x00, 0x00
	.byte 0xf2, 0x19, 0xf9, 0x00, 0x30, 0xe8, 0x89, 0xd8
	.byte 0xa8, 0x1e, 0x07, 0xf0, 0xd8, 0xa8, 0x31, 0x00
	.byte 0xf0, 0x1e, 0x19, 0xf3, 0xd7, 0xfa, 0xcf, 0xe8
	.byte 0x03, 0x6f, 0x4c, 0xd8, 0xa8, 0x1d, 0x23, 0x10
	.byte 0x02, 0xdb, 0xd8, 0x66, 0x38, 0xde, 0xa8, 0xf0
	.byte 0x18, 0xb7, 0xf2, 0x00, 0x00, 0x10, 0x02, 0x40
	.byte 0x08, 0x00, 0xf0, 0x18, 0xbf, 0xf2, 0x02, 0x00
	.byte 0x10, 0x02, 0x00, 0xff, 0x68, 0x00, 0x00, 0x00
	.byte 0x00, 0xf0, 0x18, 0xb7, 0xf2, 0x00, 0x00, 0x10
	.byte 0x02, 0x00, 0x08, 0x00, 0xf0, 0x18, 0xbf, 0xf2
	.byte 0x02, 0x00, 0x10, 0x02, 0x80, 0xff, 0x68, 0x00
	.byte 0x00, 0x00, 0x00, 0x68, 0x0a, 0xd7, 0xfa, 0x61
	.byte 0xd7, 0xfa, 0xcf, 0xe8, 0x03, 0x67, 0xb4, 0xf0
	.byte 0x18, 0xb7, 0xf2, 0x00, 0x00, 0x10, 0x02, 0xc0
	.byte 0x00, 0x00, 0xf0, 0x18, 0xbf, 0xf2, 0x02, 0x00
	.byte 0x10, 0x02, 0x00, 0x00, 0x68, 0x00, 0x00, 0x00
	.byte 0x00, 0xf0, 0x18, 0xb7, 0xf2, 0x00, 0x00, 0x10
	.byte 0x02, 0x00, 0x00, 0x00, 0xf0, 0x18, 0xbf, 0xf2
	.byte 0x02, 0x00, 0x10, 0x02, 0x00, 0x7e, 0x68, 0x00
	.byte 0x00, 0x00, 0x00, 0xde, 0x8b, 0x5e, 0x0e

ToneGen_ReadPitch_AndScale:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xbc
	ld iz, wa
	res_dd8 7, 0x18
	ld wa, iz
	add wa, 0xC0
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, (xsp + 6)
	ld wa, (xwa + 6)
	stw_da 0x100002, xwa
	jr __jrt_nop_02E1B4
__jrt_nop_02E1B4:

ToneGen_ReadPitch_Compute:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ld wa, iz
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	ld xwa, 0x100002
	ld (xsp + 2), xwa
	ld wa, iz
	extz xwa
	ld xbc, 0x47
	call FP_MulAccum64
	lda_24 xwa, 0x0430bb
	add xwa, xhl
	ld bc, (xwa)
	res 15, bc
	ld xwa, (xsp + 2)
	ld (xwa), bc
	jr __jrt_nop_02E1ED
__jrt_nop_02E1ED:

ToneGen_ReadPitch_Return:
	nop
	nop
	nop
	popw iz
	inc 8, xsp
	ret

; --- CheckStatusBits_Zero: Check if status bits [7:6] are zero ---
; Entry: WA = index
; Exit: HL = 1 if status bits are 0b00, else HL = 0
CheckStatusBits_Zero:
	extz	xwa
	ld	xbc, 287
	call	252106
	lda_24	xwa, 267118
	add	xwa, xhl
	ld	xwa, (xwa)
	ld	a, (xwa+16)
	and	a, 192
	cps	a, 0
	scc16	z, hl
	ret

CheckStatusBits_40:
	extz xwa
	ld xbc, 0x11F
	call FP_MulAccum64
	lda_24 xwa, 0x04136e
	add xwa, xhl
	ld xwa, (xwa)
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0x40
	scc16 z, hl
	ret

; --- CheckStatusBits_80: Check if status bits [7:6] are 0b10 ---
; Entry: WA = index
; Exit: HL = 1 if status bits are 0x80, else HL = 0
CheckStatusBits_80:
	extz	xwa
	ld	xbc, 287
	call	252106
	lda_24	xwa, 267118
	add	xwa, xhl
	ld	xwa, (xwa)
	ld	a, (xwa+16)
	and	a, 192
	cp	a, 128
	scc16	z, hl
	ret
; --- CheckStatusBits_C0: Check if status bits [7:6] are 0b11 ---
	extz	xwa
	ld	xbc, 287
	call	252106
	lda_24	xwa, 267118
	add	xwa, xhl
	ld	xwa, (xwa)
	ld	a, (xwa+16)
	and	a, 192
	cp	a, 192
	scc16	z, hl
	ret

BlockCopy_Words_BC_to_HL:
	ld xhl, xbc
	lds ix, 0
	cp ix, de
	ret nc

BlockCopy_Words_BC_to_HL_Loop:
	ldb_spi C, 0xE0
	lda_dpi XHL, 0xEC
	inc 1, ix
	cp ix, de
	jr c, BlockCopy_Words_BC_to_HL_Loop
	ret

VoiceStruct_BulkInit:
	dec 2, xsp
	pushw_erp 0xFA
	ld (xsp + 2), a
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XDE, 0x07, 0xE4, 0xE0
	lda_24 xwa, 0x044fce
	ld xbc, xwa
	ld xwa, xde
	ldw de, 0x66
	calr BlockCopy_Words_BC_to_HL
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jr nc, VoiceStruct_BulkInit_Return

VoiceStruct_BulkInit_SubSlotLoop:
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	ld_sril3 XDE, 0x07, 0xE0, 0xE8
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x51
	add wa, 0x66
	lda_24 xbc, 0x044fce
	exts xwa
	add xwa, xbc
	ld xbc, xwa
	ld xwa, xde
	ldw de, 0x51
	calr BlockCopy_Words_BC_to_HL
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jr c, VoiceStruct_BulkInit_SubSlotLoop

VoiceStruct_BulkInit_Return:
	popw_erp 0xFA
	inc 2, xsp
	ret

VoiceStruct_BulkInit_AltData:
	dec	2, xsp
	ld	(xsp), e
	ld	l, a
	extz	hl
	extz	bc
	ld	a, (xsp)
	ld	e, a
	extz	de
	pushw 255
	ld	wa, hl
	call	207368
	ld	a, (xsp)
	extz	wa
	muls	wa, 80
	ld	bc, wa
	add	bc, 19111
	ldl_da	xwa, 283420
	lda_rr	xwa, xwa, bc
	ld	xbc, xwa
	ldl_da	xde, 283412
	ld	xwa, xhl
	ld	de, (xde+238)
	.byte 0x1e, 0x23, 0xff
	inc	2, xsp
	ret

VoiceSubSlot_Init:
	dec 2, xsp
	ld (xsp), c
	ld e, a
	extz de
	ld a, (xsp)
	ld c, a
	extz bc
	ld wa, de
	call VoiceChanCopy_Main
	ld a, (xsp)
	extz wa
	muls wa, 0xB
	add wa, 0x1AA
	lda_24 xbc, 0x044fce
	exts xwa
	add xwa, xbc
	ld xbc, xwa
	ldl_da xde, 0x045314
	ld xwa, xhl
	ldw_sri0 DE, (xde + 0x00ea)
	calr BlockCopy_Words_BC_to_HL
	inc 2, xsp
	ret

VoiceSubSlot_Init_AltData:
	.byte 0xef, 0x6a, 0xb7, 0x41, 0x87, 0x21, 0xc9, 0x8f
	.byte 0xdb, 0x12, 0xd9, 0x12, 0xda, 0x12, 0x8f, 0x06
	.byte 0x21, 0xd8, 0x12, 0x28, 0x0b, 0xff, 0x00, 0xdb
	.byte 0x88, 0x1d, 0x8b, 0x24, 0x03, 0x87, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x0b, 0x00, 0xd8, 0x89, 0x8f
	.byte 0x06, 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x50, 0x00
	.byte 0xd8, 0x8a, 0xd9, 0x82, 0xe2, 0x1c, 0x53, 0x04
	.byte 0x20, 0xf3, 0x07, 0xe0, 0xe8, 0x30, 0xf3, 0xe1
	.byte 0xe1, 0x4a, 0x30, 0xe8, 0x89, 0xe2, 0x14, 0x53
	.byte 0x04, 0x22, 0xeb, 0x88, 0xd3, 0xe9, 0xf0, 0x00
	.byte 0x22, 0x1e, 0x8f, 0xfe, 0xef, 0x62, 0x0f, 0x02
	.byte 0x00

VoiceParam_FullSetup:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	calr VoiceStruct_BulkInit
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jr nc, VoiceParam_FullSetup_SetRoutingBit

VoiceParam_FullSetup_SubSlotInitLoop:
	ld a, (xsp + 4)
	ld e, a
	extz de
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld wa, de
	calr VoiceSubSlot_Init
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jr c, VoiceParam_FullSetup_SubSlotInitLoop

VoiceParam_FullSetup_SetRoutingBit:
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	ldw_sri WA, 0x07, 0xE4, 0xE0
	extz xwa
	bit 15, wa
	jr z, VoiceParam_FullSetup_ClearRoutingBit
	setda_24 7, 282667
	jr VoiceParam_FullSetup_CopyLUT

VoiceParam_FullSetup_ClearRoutingBit:
	resda_24 7, 282667

VoiceParam_FullSetup_CopyLUT:
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0x08
	jr nc, VoiceParam_FullSetup_CountActive

VoiceParam_FullSetup_CopyLUT_Body:
	stb_erp A, 0xFB
	extz wa
	ld de, wa
	add de, 0x1D8
	lda_24 xhl, 0x044fce
	stb_erp A, 0xFB
	extz wa
	lda_24 xbc, 0x00f95d
	ldb_sri A, 0x07, 0xE4, 0xE0
	lda_dri XBC, 0x07, 0xEC, 0xE8
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0x08
	jr c, VoiceParam_FullSetup_CopyLUT_Body

VoiceParam_FullSetup_CountActive:
	ldb c, 0x0
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jr nc, VoiceParam_FullSetup_CheckAllActive

VoiceParam_FullSetup_CountActive_Loop:
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x51
	add wa, 0x66
	lda_24 xde, 0x044fd4
	ldb_sri A, 0x07, 0xE8, 0xE0
	and a, 0xC0
	jr nz, VoiceParam_FullSetup_CountActive_Next
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x51
	add wa, 0x66
	lda_24 xde, 0x044fd4
	bit_dri 5, 0x07, 0xE8, 0xE0
	jr nz, VoiceParam_FullSetup_CountActive_Next
	inc 1, c

VoiceParam_FullSetup_CountActive_Next:
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jr c, VoiceParam_FullSetup_CountActive_Loop

VoiceParam_FullSetup_CheckAllActive:
	cps c, 4
	jr z, VoiceParam_FullSetup_CopySlotParams
	stib_da 0x0451a7, 0x00

VoiceParam_FullSetup_CopySlotParams:
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jrl nc, VoiceParam_FullSetup_Return

VoiceParam_FullSetup_CopySlotParams_Body:
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	ld_sril3 XWA, 0x07, 0xE0, 0xE8
	ld a, (xwa + 54)
	and a, 0x7
	ld e, a
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x5
	add wa, 0x1E0
	lda_24 xbc, 0x044fce
	lda_dri XIY, 0x07, 0xE4, 0xE0
	ldb c, 0x0
	cps c, 4
	jr nc, VoiceParam_FullSetup_CopySlotParams_OuterNext

VoiceParam_FullSetup_CopySlotParams_Inner:
	ld l, c
	extz hl
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x5
	ld de, wa
	add de, hl
	lda_24 xhl, 0x0451af
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld iy, wa
	add iy, 0x6E
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x11F
	lda_24 xix, 0x041368
	stb_dri D, 0x07, 0xF0, 0xE0
	ld a, c
	extz wa
	ld iz, wa
	add iz, 0x4D
	ld_sril3 XWA, 0x07, 0xF0, 0xF4
	ldb_sri A, 0x07, 0xE0, 0xF8
	lda_dri XBC, 0x07, 0xEC, 0xE8
	inc 1, c
	cps c, 4
	jr c, VoiceParam_FullSetup_CopySlotParams_Inner

VoiceParam_FullSetup_CopySlotParams_OuterNext:
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jrl c, VoiceParam_FullSetup_CopySlotParams_Body

VoiceParam_FullSetup_Return:
	pop xiz
	inc 2, xsp
	ret

VoiceParam_FullSetup_ExtData:
	dec	2, xsp
	ld	(xsp), a
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xde, 267112
	ld_rrw	wa, xde, wa
	and	wa, 3
	jrl	z, 307
	cps	c, 0
	jr	nz, 42
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267112
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x3c, 0xfe, 0xff
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267112
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x3e, 0x02, 0x00, 0x68
	.byte 0x28
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267112
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x3c, 0xfd, 0xff
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267112
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x3e, 0x01, 0x00
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267112
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x3e, 0x04, 0x00
	ld	a, (xsp)
	extz	wa
	call	214967
	ld	a, (xsp)
	extz	wa
	call	163006
	ld	a, (xsp)
	ld	l, a
	extz	hl
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267137
	ld_rrb	a, xbc, wa
	ldb_erp	a, 240
	extz	ix
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267138
	ld_rrb	a, xbc, wa
	ld	e, a
	extz	de
	ld	wa, hl
	ld	bc, ix
	call	207160
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	bitm	7, (xwa+93)
	jr	z, 22
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267122
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x3e, 0x00, 0x40, 0x68
	.byte 0x14
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267122
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x3c, 0xff, 0xbf
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	ld	a, (xwa+16)
	and	a, 192
	cp	a, 128
	jr	z, 32
	cp	a, 64
	jr	z, 19
	cp	a, 192
	jr	z, 4
	cps	a, 0
	jr	nz, 18
	ld	a, (xsp)
	extz	wa
	call	215184
	jr	t, 8
	ld	a, (xsp)
	extz	wa
	call	215400
	inc	2, xsp
	ret
	dec	2, xsp
	push qiz
	ld	(xsp+2), a
	ldl_da	xwa, 283412
	ld	xwa, (xwa+80)
	ldl_da	xhl, 283408
	add	xhl, xwa
	ldb_erp	e, 251
	.byte 0xc7, 0xfb, 0xcc, 0x0f
	stb_erp	a, 251
	extz	wa
	muls	wa, 37
	ld	ix, wa
	add	ix, 110
	ld	a, (xsp+2)
	extz	wa
	muls	wa, 287
	lda_24	xde, 267112
	exts	xwa
	add	xwa, xde
	ld_rrl	xde, xwa, ix
	ld	wa, bc
	extz	xwa
	sll	xwa, 4
	add	xwa, xhl
	ld	a, (xwa+14)
	ld	(xde+2), a
	stb_erp	a, 251
	extz	wa
	muls	wa, 37
	ld	ix, wa
	add	ix, 110
	ld	a, (xsp+2)
	extz	wa
	muls	wa, 287
	lda_24	xde, 267112
	exts	xwa
	add	xwa, xde
	ld_rrl	xde, xwa, ix
	ld	wa, bc
	extz	xwa
	sll	xwa, 4
	add	xwa, xhl
	ld	a, (xwa+15)
	ld	(xde+3), a
	ld	a, (xsp+2)
	ld	e, a
	extz	de
	stb_erp	a, 251
	ld	c, a
	extz	bc
	ld	wa, de
	.byte 0x1e, 0xe4, 0xfb
	ldib_erp	250, 0
	cpib_erp	250, 4
	jr	nc, 35
	ld	a, (xsp+2)
	ld	l, a
	extz	hl
	stb_erp	a, 251
	ld	c, a
	extz	bc
	stb_erp	a, 250
	ld	e, a
	extz	de
	ld	wa, hl
	call	207074
	incb_erp	250, 1
	cpib_erp	250, 4
	jr	c, 16777181
	pop qiz
	inc	2, xsp
	ret
	ldl_da	xhl, 283412
	ld	xhl, (xhl+100)
	ldl_da	xix, 283408
	add	xix, xhl
	ldb_erp	e, 226
	.byte 0xc7, 0xe2, 0xcc, 0x0f
	and	e, 240
	srl	e, 4
	ld	w, e
	stb_erp	e, 226
	extz	de
	muls	de, 37
	ld	iy, de
	add	iy, 110
	ld	e, a
	extz	de
	muls	de, 287
	lda_24	xhl, 267112
	exts	xde
	add	xde, xhl
	lda_rr	xhl, xde, iy
	ld	e, w
	extz	de
	add	de, de
	ld	iy, de
	inc	3, iy
	ld	xhl, (xhl+4)
	ld	de, bc
	extz	xde
	sll	xde, 4
	add	xde, xix
	ld	e, (xde+14)
	st_rrb	e, xhl, iy
	stb_erp	e, 226
	extz	de
	muls	de, 37
	ld	iy, de
	add	iy, 110
	ld	e, a
	extz	de
	muls	de, 287
	lda_24	xhl, 267112
	exts	xde
	add	xde, xhl
	lda_rr	xhl, xde, iy
	ld	e, w
	extz	de
	add	de, de
	ld	iy, de
	inc	3, iy
	ld	xde, (xhl+4)
	lda_rr	xde, xde, iy
	extz	xbc
	sll	xbc, 4
	add	xbc, xix
	ld	c, (xbc+15)
	ld	(xde+1), c
	ld	l, a
	extz	hl
	stb_erp	a, 226
	ld	c, a
	extz	bc
	ld	e, w
	extz	de
	ld	wa, hl
	jp	207074
	dec	4, xsp
	ld	(xsp), e
	ld	(xsp+2), a
	ld	a, c
	extz	wa
	ld	de, wa
	add	de, 472
	lda_24	xhl, 282574
	ld	a, (xsp)
	st_rrb	a, xhl, de
	ld	a, c
	extz	wa
	cps	wa, 0
	.byte 0x75, 0x98, 0x00
	cps	wa, 6
	jrl	gt, 147
	add	wa, wa
	lda_24	xix, 63845
	ld_rrw	wa, xix, wa
	lda_24	xix, 190619
	jp_rr	8, xix, wa
	ld	a, (xsp+2)
	extz	wa
	call	214161
	jr	t, 114
	ld	a, (xsp+2)
	extz	wa
	call	214275
	cp	(xsp), 245
	jr	z, 9
	ld	a, (xsp+2)
	extz	wa
	call	214534
	ld	a, (xsp+2)
	extz	wa
	lds	bc, 0
	.byte 0x1e, 0x63, 0x0c, 0x68, 0x4f
	ld	a, (xsp+2)
	extz	wa
	call	214609
	ld	a, (xsp+2)
	extz	wa
	lds	bc, 0
	.byte 0x1e, 0x4e, 0x0c, 0x68, 0x3a
	ld	a, (xsp+2)
	extz	wa
	call	214684
	ld	a, (xsp+2)
	extz	wa
	lds	bc, 0
	.byte 0x1e, 0x39, 0x0c, 0x68, 0x25
	ld	a, (xsp+2)
	extz	wa
	call	214759
	jr	t, 26
	ld	a, (xsp+2)
	extz	wa
	call	214834
	ld	a, (xsp+2)
	extz	wa
	call	183541
	ld	xwa, xhl
	lds	bc, 1
	call	167462
	inc	4, xsp
	ret
	dec	2, xsp
	push xiz
	ld	(xsp+4), a
	ldl_da	xbc, 283420
	ld	a, (xsp+4)
	ld	(xbc+29351), a
	ld	qiz, 0
	cp	qiz, 2
	jr	nc, 119
	ld	a, (xsp+4)
	extz	wa
	muls	wa, 80
	ld	iz, wa
	ld	wa, qiz
	extz	xwa
	ld	xbc, 21
	call	252106
	lda_rr	xhl, xhl, iz
	addda32_24	xhl, 283420
	lda	xhl, (xhl+19127)
	ld	wa, qiz
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	add	xbc, 500
	lda_24	xde, 282574
	add	xde, xbc
	ld	a, (xhl+15)
	and	a, 7
	ld	(xde), a
	lds	bc, 0
	cps	bc, 4
	jr	nc, 32
	ld	wa, bc
	extz	xwa
	inc	1, xwa
	ld	xix, xwa
	add	xix, xde
	ld	wa, bc
	extz	xwa
	add	xwa, 17
	add	xwa, xhl
	ld	a, (xwa)
	ld	(xix), a
	inc	1, bc
	cps	bc, 4
	jr	c, 16777184
	inc	1, qiz
	cp	qiz, 2
	jr	c, 16777097
	pop xiz
	inc	2, xsp
	ret
	.byte 0xbf, 0xf2, 0x37
	push xiz
	ld	(xsp+16), wa
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	ld	(xsp+12), a
	extz	wa
	muls	wa, 80
	ld	bc, wa
	add	bc, 19111
	ldl_da	xwa, 283420
	lda_rr	xwa, xwa, bc
	ld	(xsp+4), xwa
	ldl_da	xwa, 283412
	ld	xwa, (xwa+128)
	ldl_da	xbc, 283408
	add	xbc, xwa
	ld	(xsp+8), xbc
	ld	wa, (xsp+16)
	extz	xwa
	sll	xwa, 4
	add	xwa, (xsp+8)
	ld	a, (xwa+14)
	ld	l, a
	extz	hl
	ld	wa, (xsp+16)
	extz	xwa
	sll	xwa, 4
	add	xwa, (xsp+8)
	ld	a, (xwa+15)
	ld	c, a
	extz	bc
	ld	a, (xsp+12)
	ld	e, a
	extz	de
	ld	wa, hl
	.byte 0x1e, 0xec, 0xf8
	ld	(xsp+14), 0
	cp	(xsp+14), 2
	jr	nc, 72
	ld	a, (xsp+14)
	extz	wa
	muls	wa, 21
	ld	bc, wa
	add	bc, 16
	ld	xwa, (xsp+4)
	lda_rr	xiz, xwa, bc
	ld	a, (xsp+14)
	ld	l, a
	extz	hl
	ld	a, (xiz+1)
	ld	c, a
	extz	bc
	ld	a, (xiz+2)
	ld	e, a
	extz	de
	ld	a, (xsp+12)
	extz	wa
	pushw wa
	ld	wa, hl
	.byte 0x1e, 0x2d, 0xf9
	andmi8	(xiz+2), 15
	ormi8	(xiz+2), 80
	.byte 0x8f, 0x0e, 0x61
	cp	(xsp+14), 2
	jr	c, 16777144
	ld	a, (xsp+12)
	extz	wa
	add	wa, wa
	ld	de, wa
	add	de, 18855
	ldl_da	xbc, 283420
	ld	wa, (xsp+16)
	extz	xwa
	sll	xwa, 4
	add	xwa, (xsp+8)
	ld	a, (xwa+14)
	st_rrb	a, xbc, de
	ld	wa, (xsp+16)
	extz	xwa
	sll	xwa, 4
	add	xwa, (xsp+8)
	ld	a, (xwa+15)
	and	a, 31
	or	a, 96
	ld	e, a
	ld	a, (xsp+12)
	extz	wa
	add	wa, wa
	ld	bc, wa
	add	bc, 18855
	ldl_da	xwa, 283420
	lda_rr	xwa, xwa, bc
	ld	(xwa+1), e
	pop xiz
	lda	xsp, (xsp+14)
	ret
	dec	6, xsp
	push xiz
	ld	(xsp+8), wa
	ldl_da	xwa, 283420
	ld	e, (xwa+29351)
	ldl_da	xwa, 283412
	ld	xwa, (xwa+140)
	ldl_da	xhl, 283408
	add	xhl, xwa
	ld	xiz, xhl
	ld	l, c
	and	l, 15
	ld	a, l
	extz	wa
	muls	wa, 21
	ld	bc, wa
	ld	a, e
	extz	wa
	muls	wa, 80
	ld	ix, wa
	add	ix, bc
	ldl_da	xwa, 283420
	lda_rr	xwa, xwa, ix
	ld	(xsp+4), xwa
	ld	xwa, 19127
	add	(xsp+4), xwa
	ld	c, l
	extz	bc
	ld	wa, (xsp+8)
	extz	xwa
	sll	xwa, 4
	add	xwa, xiz
	ld	a, (xwa+14)
	ldb_erp	a, 240
	extz	ix
	ld	wa, (xsp+8)
	extz	xwa
	sll	xwa, 4
	add	xwa, xiz
	ld	a, (xwa+15)
	ld	l, a
	extz	hl
	ld	a, e
	extz	wa
	pushw wa
	ld	wa, bc
	ld	bc, ix
	ld	de, hl
	.byte 0x1e, 0x3a, 0xf8
	ld	wa, (xsp+8)
	extz	xwa
	sll	xwa, 4
	ld	xbc, xwa
	add	xbc, xiz
	ld	xwa, (xsp+4)
	ld	c, (xbc+14)
	ld	(xwa+1), c
	ld	wa, (xsp+8)
	extz	xwa
	sll	xwa, 4
	add	xwa, xiz
	ld	a, (xwa+15)
	and	a, 15
	or	a, 80
	ld	c, a
	ld	xwa, (xsp+4)
	ld	(xwa+2), c
	pop xiz
	inc	6, xsp
	ret
	ldl_da	xde, 283420
	ld	b, (xde+29351)
	ldl_da	xde, 283412
	ld	xde, (xde+148)
	ldl_da	xhl, 283408
	add	xhl, xde
	ld	e, c
	and	e, 15
	extz	de
	muls	de, 11
	ld	ix, de
	ld	e, b
	extz	de
	muls	de, 80
	ld	iy, de
	add	iy, ix
	ldl_da	xde, 283420
	lda_rr	xde, xde, iy
	lda	xde, (xde+19169)
	and	c, 240
	srl	c, 4
	ldb_erp	c, 226
	extz	bc
	add	bc, bc
	ld	ix, bc
	inc	3, ix
	ld	bc, wa
	extz	xbc
	sll	xbc, 4
	add	xbc, xhl
	ld	c, (xbc+14)
	st_rrb	c, xde, ix
	stb_erp	c, 226
	extz	bc
	add	bc, bc
	inc	3, bc
	exts	xbc
	add	xbc, xde
	extz	xwa
	sll	xwa, 4
	add	xwa, xhl
	ld	a, (xwa+15)
	ld	(xbc+1), a
	ret

VoiceAlloc_CheckAndInit:
	dec 2, xsp
	ld (xsp), a
	ldb_da a, 0x0451a4
	cp a, (xsp)
	jrl nz, VoiceAlloc_CheckAndInit_Return
	cp (xsp), 0x2
	jr ule, VoiceAlloc_SetFlagBit0
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	ldw_sri WA, 0x07, 0xE4, 0xE0
	and wa, 0x3
	cps wa, 3
	jrl nz, VoiceAlloc_CheckAndInit_Return

VoiceAlloc_SetFlagBit0:
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	ldw_sri WA, 0x07, 0xE4, 0xE0
	bit 0, wa
	jr z, VoiceAlloc_InitNewAllocation
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	or_sriw_im 0x07, 0xE4, 0xE0, 0x01, 0x00
	jr VoiceAlloc_CheckAndInit_Return

VoiceAlloc_InitNewAllocation:
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	or_sriw_im 0x07, 0xE4, 0xE0, 0x01, 0x00
	ld a, (xsp)
	extz wa
	calr VoiceParam_FullSetup
	ld a, (xsp)
	ld l, a
	extz hl
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041381
	ldb_sri A, 0x07, 0xE4, 0xE0
	ldb_erp A, 0xF0
	extz ix
	ld a, (xsp)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041382
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld e, a
	extz de
	ld wa, hl
	ld bc, ix
	call VoiceInit_Dispatcher

VoiceAlloc_CheckAndInit_Return:
	inc 2, xsp
	ret

VoiceAlloc_CheckAndInit_ExtData:
	ld	e, (xwa+1)
	cps	e, 2
	jr	ule, 26
	ld	a, e
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267112
	ld_rrw	wa, xbc, wa
	and	wa, 3
	cps	wa, 3
	ret	nz
	ld	a, e
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267112
	ld_rrw	wa, xbc, wa
	bit	0, wa
	jr	z, 21
	ld	a, e
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267112
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x3e, 0x01, 0x00
	ret
	ld	a, e
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267112
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x3e, 0x01, 0x00
	ld	a, e
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267138
	ld_rrb	a, xbc, wa
	cp	a, 64
	ret	c
	cp	a, 80
	ret	nc
	ld	a, e
	extz	wa
	call	217523
	ret
	ld	xix, 1966080
	ldw	hl, 470
	ld	c, a
	extz	bc
	muls	bc, 80
	ld	de, bc
	add	de, 19111
	ldl_da	xbc, 283420
	lda_rr	xbc, xbc, de
	ld	xde, xbc
	extz	wa
	muls	wa, 80
	add	wa, 19111
	exts	xwa
	add	xwa, xix
	ld	xbc, xwa
	ld	xwa, xde
	ld	xde, xbc
	ld	bc, hl
	jp	134579
	push xiz
	ld	xiz, xwa
	ld	a, (xiz+2)
	extz	wa
	cps	wa, 0
	.byte 0x75, 0x81, 0x02
	cp	wa, 13
	jr	le, 16
	dec	5, wa
	cp	wa, 14
	jrl	lt, 626
	cp	wa, 19
	jrl	gt, 619
	add	wa, wa
	lda_24	xix, 63859
	ld_rrw	wa, xix, wa
	lda_24	xix, 191929
	jp_rr	8, xix, wa
	ld	a, (xiz+1)
	ld	e, a
	extz	de
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	wa, de
	.byte 0x1e, 0xb5, 0xf7, 0x78, 0x3f, 0x02
	ld	a, (xiz+1)
	extz	wa
	.byte 0x1e, 0x33, 0xfe
	ld	a, (xiz+1)
	ld	e, a
	extz	de
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	wa, de
	call	175650
	jrl	t, 544
	ld	a, (xiz+1)
	extz	wa
	.byte 0x1e, 0x14, 0xfe
	ld	a, (xiz+1)
	ld	e, a
	extz	de
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	wa, de
	call	175704
	jrl	t, 513
	ld	a, (xiz+1)
	extz	wa
	.byte 0x1e, 0xf5, 0xfd
	ld	a, (xiz+1)
	ld	e, a
	extz	de
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	wa, de
	call	175778
	jrl	t, 482
	ld	a, (xiz+1)
	extz	wa
	.byte 0x1e, 0xd6, 0xfd
	ld	a, (xiz+1)
	ld	e, a
	extz	de
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	wa, de
	call	175852
	jrl	t, 451
	ld	a, (xiz+1)
	extz	wa
	.byte 0x1e, 0xb7, 0xfd
	ld	a, (xiz+1)
	ld	e, a
	extz	de
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	wa, de
	call	175930
	jrl	t, 420
	ld	a, (xiz+1)
	extz	wa
	.byte 0x1e, 0x98, 0xfd
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	a, (xiz+3)
	extz	wa
	ld	hl, wa
	sll	hl, 8
	or	hl, bc
	ld	a, (xiz+1)
	ld	c, a
	extz	bc
	ld	a, (xiz+5)
	ld	e, a
	extz	de
	ld	wa, bc
	ld	bc, hl
	.byte 0x1e, 0x3a, 0xf8, 0x78, 0x71, 0x01
	ld	a, (xiz+1)
	extz	wa
	.byte 0x1e, 0x65, 0xfd
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	a, (xiz+3)
	extz	wa
	ld	hl, wa
	sll	hl, 8
	or	hl, bc
	ld	a, (xiz+1)
	ld	c, a
	extz	bc
	ld	a, (xiz+5)
	ld	e, a
	extz	de
	ld	wa, bc
	ld	bc, hl
	.byte 0x1e, 0xd3, 0xf8, 0x78, 0x3e, 0x01
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	ld	a, (xwa+16)
	and	a, 192
	cp	a, 64
	jr	nz, 23
	ld	a, (xiz+1)
	ld	e, a
	extz	de
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	wa, de
	call	176002
	jrl	t, 265
	ld	a, (xiz+1)
	extz	wa
	.byte 0x1e, 0xfd, 0xfc
	ld	a, (xiz+1)
	ld	l, a
	extz	hl
	ld	a, (xiz+3)
	ld	c, a
	extz	bc
	ld	e, (xiz+4)
	ld	wa, hl
	.byte 0x1e, 0x37, 0xf9, 0x78, 0xe8, 0x00
	ldb_da	a, 283044
	stb_da	283045, a
	ld	a, (xiz+1)
	stb_da	283044, a
	jrl	t, 211
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	ld	a, (xwa+16)
	and	a, 192
	cp	a, 64
	jrl	nz, 180
	ld	a, (xiz+1)
	ld	e, a
	extz	de
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	wa, de
	call	176061
	jrl	t, 157
	ld	xwa, xiz
	.byte 0x1e, 0x48, 0xfd
	ld	a, (xiz+4)
	extz	wa
	.byte 0x1e, 0x9d, 0xf9, 0x78, 0x8d, 0x00
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	a, (xiz+3)
	extz	wa
	ld	hl, wa
	sll	hl, 8
	or	hl, bc
	ld	wa, hl
	.byte 0x1e, 0x18, 0xfa
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	extz	wa
	.byte 0x1e, 0x9c, 0xfd, 0x68, 0x64
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	a, (xiz+3)
	extz	wa
	ld	hl, wa
	sll	hl, 8
	or	hl, bc
	ld	a, (xiz+5)
	ld	c, a
	extz	bc
	ld	wa, hl
	.byte 0x1e, 0x05, 0xfb
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	extz	wa
	.byte 0x1e, 0x6c, 0xfd, 0x68, 0x34
	ld	a, (xiz+4)
	ld	c, a
	extz	bc
	ld	a, (xiz+3)
	extz	wa
	ld	hl, wa
	sll	hl, 8
	or	hl, bc
	ld	a, (xiz+5)
	ld	c, a
	extz	bc
	ld	wa, hl
	.byte 0x1e, 0x91, 0xfb
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	extz	wa
	.byte 0x1e, 0x3c, 0xfd, 0x68, 0x04
	call	218485
	pop xiz
	ret
	extz	wa
	muls	wa, 287
	lda_24	xde, 267118
	ld_rrl	xde, xde, wa
	ld	a, c
	extz	wa
	muls	wa, 39
	lda_24	xbc, 73238
	exts	xwa
	add	xwa, xbc
	ld	xbc, xwa
	ld	a, (xbc)
	ld	(xde+94), a
	ld	a, (xbc+1)
	ld	(xde+95), a
	ld	a, (xbc+26)
	ld	(xde+96), a
	ld	a, (xbc+28)
	ld	(xde+97), a
	ld	a, (xbc+27)
	ld	(xde+98), a
	ld	a, (xbc+14)
	ld	(xde+100), a
	ld	a, (xbc+18)
	ld	(xde+101), a
	ret
	extz	wa
	muls	wa, 287
	lda_24	xde, 267118
	ld_rrl	xde, xde, wa
	ld	a, c
	extz	wa
	muls	wa, 39
	lda_24	xbc, 73238
	exts	xwa
	add	xwa, xbc
	ld	xbc, xwa
	ld	a, (xbc)
	ld	(xde+94), a
	ld	a, (xbc+1)
	ld	(xde+95), a
	ld	a, (xbc+3)
	ld	(xde+96), a
	ld	a, (xbc+4)
	ld	(xde+97), a
	ld	a, (xbc+26)
	ld	(xde+98), a
	ld	a, (xbc+28)
	ld	(xde+99), a
	ld	a, (xbc+14)
	ld	(xde+100), a
	ld	a, (xbc+18)
	ld	(xde+101), a
	ret
	extz	wa
	muls	wa, 287
	lda_24	xde, 267118
	ld_rrl	xde, xde, wa
	ld	a, c
	extz	wa
	muls	wa, 39
	lda_24	xbc, 73238
	exts	xwa
	add	xwa, xbc
	ld	xbc, xwa
	ld	a, (xbc+6)
	ld	(xde+94), a
	ld	a, (xbc+7)
	ld	(xde+95), a
	ld	a, (xbc+8)
	ld	(xde+96), a
	ld	a, (xbc+27)
	ld	(xde+97), a
	ld	(xde+98), 0
	ld	(xde+99), 0
	ld	a, (xbc+14)
	ld	(xde+100), a
	ld	a, (xbc+18)
	ld	(xde+101), a
	ret
	extz	wa
	muls	wa, 287
	lda_24	xde, 267118
	ld_rrl	xde, xde, wa
	ld	a, c
	extz	wa
	muls	wa, 39
	lda_24	xbc, 73238
	exts	xwa
	add	xwa, xbc
	ld	xbc, xwa
	ld	a, (xbc)
	ld	(xde+94), a
	ld	a, (xbc+1)
	ld	(xde+95), a
	ld	a, (xbc+3)
	ld	(xde+96), a
	ld	a, (xbc+4)
	ld	(xde+97), a
	ld	(xde+98), 0
	ld	(xde+99), 0
	ld	a, (xbc+14)
	ld	(xde+100), a
	ld	a, (xbc+18)
	ld	(xde+101), a
	ret
	extz	wa
	muls	wa, 287
	lda_24	xde, 267118
	ld_rrl	xde, xde, wa
	ld	a, c
	extz	wa
	muls	wa, 39
	lda_24	xbc, 73238
	exts	xwa
	add	xwa, xbc
	ld	xbc, xwa
	ld	a, (xbc+28)
	ld	(xde+94), a
	ld	a, (xbc+26)
	ld	(xde+95), a
	ld	a, (xbc+25)
	ld	(xde+96), a
	ld	a, (xbc+27)
	ld	(xde+97), a
	ld	(xde+98), 0
	ld	(xde+99), 0
	ld	a, (xbc+14)
	ld	(xde+100), a
	ld	a, (xbc+18)
	ld	(xde+101), a
	ret
	extz	wa
	muls	wa, 287
	lda_24	xde, 267118
	ld_rrl	xde, xde, wa
	ld	a, c
	extz	wa
	muls	wa, 39
	lda_24	xbc, 73238
	exts	xwa
	add	xwa, xbc
	ld	xbc, xwa
	ld	a, (xbc+9)
	ld	(xde+94), a
	ld	a, (xbc+10)
	ld	(xde+95), a
	ld	a, (xbc+11)
	ld	(xde+96), a
	ld	a, (xbc+12)
	ld	(xde+97), a
	ld	(xde+98), 0
	ld	(xde+99), 0
	ld	a, (xbc+14)
	ld	(xde+100), a
	ld	a, (xbc+18)
	ld	(xde+101), a
	ret
	extz	wa
	muls	wa, 287
	lda_24	xde, 267118
	ld_rrl	xde, xde, wa
	ld	a, c
	extz	wa
	muls	wa, 39
	lda_24	xbc, 73238
	exts	xwa
	add	xwa, xbc
	ld	xbc, xwa
	bitm	7, (xbc+19)
	jr	z, 6
	ld	(xde+94), 1
	jr	t, 4
	ld	(xde+94), 0
	ld	a, (xbc+2)
	and	a, 63
	ld	(xde+95), a
	ld	a, (xbc)
	ld	(xde+96), a
	ld	(xde+97), 0
	ld	(xde+98), 0
	ld	(xde+99), 0
	ld	(xde+100), 0
	ld	a, (xbc+18)
	ld	(xde+101), a
	ret
	extz	wa
	muls	wa, 287
	lda_24	xde, 267118
	ld_rrl	xde, xde, wa
	ld	a, c
	extz	wa
	muls	wa, 39
	lda_24	xbc, 73238
	exts	xwa
	add	xwa, xbc
	ld	xbc, xwa
	bitm	7, (xbc+19)
	jr	z, 6
	ld	(xde+94), 1
	jr	t, 4
	ld	(xde+94), 0
	ld	a, (xbc+2)
	and	a, 63
	ld	(xde+95), a
	ld	a, (xbc)
	ld	(xde+96), a
	ld	(xde+97), 0
	ld	(xde+98), 0
	ld	(xde+99), 0
	ld	a, (xbc+14)
	ld	(xde+100), a
	ld	a, (xbc+18)
	ld	(xde+101), a
	ret
	ld	c, a
	extz	bc
	muls	bc, 287
	lda_24	xde, 267118
	ld_rrl	xbc, xde, bc
	ld	c, (xbc+93)
	and	c, 15
	extz	bc
	cps	bc, 0
	.byte 0xb0, 0xf5
	cp	bc, 11
	ret	gt
	add	bc, bc
	lda_24	xix, 63899
	ld_rrw	bc, xix, bc
	lda_24	xix, 193241
	jp_rr	8, xix, bc
	extz	wa
	lds	bc, 0
	jrl	t, 16776496
	extz	wa
	lds	bc, 1
	jrl	t, 16776489
	extz	wa
	lds	bc, 2
	jrl	t, 16776482
	extz	wa
	lds	bc, 3
	jrl	t, 16776475
	extz	wa
	lds	bc, 4
	jrl	t, 16776545
	extz	wa
	lds	bc, 5
	jrl	t, 16776538
	extz	wa
	lds	bc, 6
	jrl	t, 16776614
	extz	wa
	lds	bc, 7
	jrl	t, 16776687
	extz	wa
	ldw	bc, 8
	jrl	t, 16776758
	extz	wa
	ldw	bc, 9
	jrl	t, 16776830
	extz	wa
	ldw	bc, 10
	jrl	t, 16776902
	extz	wa
	ldw	bc, 11
	jrl	t, 16776981
	ret
	dec	2, xsp
	ld	(xsp), a
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	ld	a, (xwa+93)
	and	a, 15
	extz	wa
	cps	wa, 0
	.byte 0x65, 0x67
	cps	wa, 7
	jr	gt, 99
	add	wa, wa
	lda_24	xix, 63923
	ld_rrw	wa, xix, wa
	lda_24	xix, 193390
	jp_rr	8, xix, wa
	ld	a, (xsp)
	extz	wa
	lds	bc, 0
	call	163044
	ld	a, (xsp)
	extz	wa
	lds	bc, 1
	call	163044
	jr	t, 55
	ld	a, (xsp)
	extz	wa
	lds	bc, 0
	call	163044
	jr	t, 43
	ld	a, (xsp)
	extz	wa
	call	163518
	jr	t, 33
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267122
	ld_rrw	wa, xbc, wa
	bit	14, wa
	jr	z, 10
	ld	a, (xsp)
	extz	wa
	lds	bc, 0
	call	163044
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	ld	a, (xwa+93)
	and	a, 15
	extz	wa
	cps	wa, 0
	.byte 0x65, 0x6f
	cps	wa, 7
	jr	gt, 107
	add	wa, wa
	.byte 0xf2
	xor	c, (xiz+13312)
	reti
	.byte 0xf0, 0xe0, 0x20
	lda_24	xix, 193530
	jp_rr	8, xix, wa
	ld	a, (xsp)
	extz	wa
	lds	bc, 0
	call	163281
	ld	a, (xsp)
	extz	wa
	lds	bc, 1
	call	163281
	jr	t, 63
	ld	a, (xsp)
	extz	wa
	lds	bc, 0
	call	163281
	jr	t, 51
	ld	a, (xsp)
	extz	wa
	call	163609
	jr	t, 41
	ld	a, (xsp)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267122
	ld_rrw	wa, xbc, wa
	bit	14, wa
	jr	z, 18
	ld	a, (xsp)
	extz	wa
	lds	bc, 0
	call	163281
	ld	a, (xsp)
	extz	wa
	call	163609
	inc	2, xsp
	ret
	ld	c, a
	extz	bc
	muls	bc, 287
	lda_24	xde, 267118
	ld_rrl	xbc, xde, bc
	ld	c, (xbc+93)
	and	c, 15
	extz	bc
	dec	4, bc
	cps	bc, 0
	ret	lt
	cps	bc, 7
	ret	gt
	add	bc, bc
	.byte 0xf2
	xor	hl, (xiz+13312)
	reti
	.byte 0xf0, 0xe4, 0x21
	lda_24	xix, 193676
	jp_rr	8, xix, bc
	extz	wa
	lds	bc, 1
	jp	163044
	extz	wa
	jp	163518
	ld	c, a
	extz	bc
	muls	bc, 287
	lda_24	xde, 267122
	ld_rrw	bc, xde, bc
	bit	14, bc
	ret	z
	extz	wa
	lds	bc, 1
	jp	163044
	extz	wa
	lds	bc, 0
	jp	163044
	ret
	ld	c, a
	extz	bc
	muls	bc, 287
	lda_24	xde, 267118
	ld_rrl	xbc, xde, bc
	ld	c, (xbc+93)
	and	c, 15
	cps	c, 7
	jr	z, 16
	cps	c, 5
	jr	z, 4
	cps	c, 4
	ret	nz
	extz	wa
	lds	bc, 1
	jp	163281
	ld	c, a
	extz	bc
	muls	bc, 287
	lda_24	xde, 267122
	ld_rrw	bc, xde, bc
	bit	14, bc
	ret	z
	extz	wa
	lds	bc, 1
	jp	163281

VoiceAlloc_WithRoutingFlag:
	dec 2, xsp
	ld (xsp), c
	extz wa
	calr VoiceAlloc_CheckAndInit
	cp (xsp), 0x0
	jr z, VoiceAlloc_WithRoutingFlag_Clear
	setda_24 7, 282667
	jr VoiceAlloc_WithRoutingFlag_Return

VoiceAlloc_WithRoutingFlag_Clear:
	resda_24 7, 282667

VoiceAlloc_WithRoutingFlag_Return:
	inc 2, xsp
	ret

VoiceAlloc_WithRoutingFlag_ExtData:
	.byte 0xbf, 0xf6, 0x37
	push xiz
	ld	(xsp+10), c
	ld	(xsp+12), a
	ld	a, (xsp+12)
	ld	e, a
	extz	de
	ld	a, (xsp+10)
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	lds	bc, 0
	call	208853
	ld	a, (xsp+12)
	ld	e, a
	extz	de
	ld	a, (xsp+10)
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	lds	bc, 0
	call	209109
	ldib_erp	251, 0
	cpib_erp	251, 4
	jr	nc, 30
	ld	a, (xsp+12)
	ld	e, a
	extz	de
	stb_erp	a, 251
	ld	c, a
	extz	bc
	ld	wa, de
	lds	de, 0
	call	209854
	incb_erp	251, 1
	cpib_erp	251, 4
	jr	c, 16777186
	ld	a, (xsp+12)
	ld	e, a
	extz	de
	ld	a, (xsp+10)
	extz	wa
	ld	c, a
	extz	bc
	ld	wa, de
	lds	de, 0
	call	137870
	ld	(xsp+4), xhl
	ldw	(xsp+8), 0
	jr	t, 105
	ld	wa, (xsp+8)
	extz	xwa
	add	xwa, xwa
	add	xwa, (xsp+4)
	ld	iz, (xwa)
	ldib_erp	249, 0
	ld	a, (xsp+12)
	ld	l, a
	extz	hl
	ld	a, (xsp+12)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267112
	lda_rr	xbc, xbc, wa
	ld	a, (xsp+10)
	ld	e, a
	extz	de
	pushw 0
	stb_erp	a, 248
	extz	wa
	pushw wa
	ld	wa, hl
	call	150105
	stb_erp	a, 248
	extz	wa
	call	142890
	stw_da	283148, hl
	stb_erp	a, 248
	extz	wa
	call	143034
	stw_da	283144, hl
	ld	wa, iz
	lda_24	xbc, 283084
	call	186902
	.byte 0x9f, 0x08, 0x61
	ld	wa, (xsp+8)
	extz	xwa
	add	xwa, xwa
	add	xwa, (xsp+4)
	ld	wa, (xwa)
	and	wa, 255
	cp	wa, 128
	jr	c, 16777089
	pop xiz
	lda	xsp, (xsp+10)
	ret
	dec	0, xsp
	push xiz
	ld	(xsp+8), c
	ld	(xsp+10), a
	ld	a, (xsp+10)
	ld	e, a
	extz	de
	ld	a, (xsp+8)
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	lds	bc, 1
	call	208853
	ld	a, (xsp+10)
	ld	e, a
	extz	de
	ld	a, (xsp+8)
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	lds	bc, 1
	call	209109
	ldib_erp	251, 0
	cpib_erp	251, 4
	jr	nc, 30
	ld	a, (xsp+10)
	ld	e, a
	extz	de
	stb_erp	a, 251
	ld	c, a
	extz	bc
	ld	wa, de
	lds	de, 1
	call	209854
	incb_erp	251, 1
	cpib_erp	251, 4
	jr	c, 16777186
	ld	a, (xsp+10)
	ld	e, a
	extz	de
	ld	a, (xsp+8)
	extz	wa
	set	2, wa
	ld	c, a
	extz	bc
	ld	wa, de
	lds	de, 0
	call	137870
	ld	(xsp+4), xhl
	ld	qiz, 0
	jr	t, 105
	ld	wa, qiz
	extz	xwa
	add	xwa, xwa
	add	xwa, (xsp+4)
	ld	iz, (xwa)
	ldib_erp	249, 0
	ld	a, (xsp+10)
	ld	l, a
	extz	hl
	ld	a, (xsp+10)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267112
	lda_rr	xbc, xbc, wa
	ld	a, (xsp+8)
	ld	e, a
	extz	de
	pushw 1
	stb_erp	a, 248
	extz	wa
	pushw wa
	ld	wa, hl
	call	150105
	stb_erp	a, 248
	extz	wa
	call	143164
	stw_da	283140, hl
	stb_erp	a, 248
	extz	wa
	call	143308
	stw_da	283142, hl
	ld	wa, iz
	lda_24	xbc, 283084
	call	187472
	inc	1, qiz
	ld	wa, qiz
	extz	xwa
	add	xwa, xwa
	add	xwa, (xsp+4)
	ld	wa, (xwa)
	and	wa, 255
	cp	wa, 64
	jr	c, 16777089
	pop xiz
	inc	0, xsp
	ret
	dec	0, xsp
	push xiz
	ld	(xsp+8), c
	ld	(xsp+10), a
	ld	a, (xsp+10)
	ld	e, a
	extz	de
	ld	a, (xsp+8)
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	lds	bc, 2
	call	208853
	ld	a, (xsp+10)
	ld	e, a
	extz	de
	ld	a, (xsp+8)
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	lds	bc, 2
	call	209109
	ldib_erp	251, 0
	cpib_erp	251, 4
	jr	nc, 30
	ld	a, (xsp+10)
	ld	e, a
	extz	de
	stb_erp	a, 251
	ld	c, a
	extz	bc
	ld	wa, de
	lds	de, 2
	call	209854
	incb_erp	251, 1
	cpib_erp	251, 4
	jr	c, 16777186
	ld	a, (xsp+10)
	ld	e, a
	extz	de
	ld	a, (xsp+8)
	extz	wa
	set	3, wa
	ld	c, a
	extz	bc
	ld	wa, de
	lds	de, 0
	call	137870
	ld	(xsp+4), xhl
	ld	qiz, 0
	jr	t, 95
	ld	wa, qiz
	extz	xwa
	add	xwa, xwa
	add	xwa, (xsp+4)
	ld	iz, (xwa)
	ldib_erp	249, 0
	ld	a, (xsp+10)
	ld	l, a
	extz	hl
	ld	a, (xsp+10)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267112
	lda_rr	xbc, xbc, wa
	ld	a, (xsp+8)
	ld	e, a
	extz	de
	pushw 2
	stb_erp	a, 248
	extz	wa
	pushw wa
	ld	wa, hl
	call	150105
	stb_erp	a, 248
	extz	wa
	call	143427
	stb_erp	a, 248
	extz	wa
	call	143711
	ld	wa, iz
	lda_24	xbc, 283084
	call	187757
	inc	1, qiz
	ld	wa, qiz
	extz	xwa
	add	xwa, xwa
	add	xwa, (xsp+4)
	ld	wa, (xwa)
	and	wa, 255
	cp	wa, 128
	jr	c, 16777099
	pop xiz
	inc	0, xsp
	ret
	dec	4, xsp
	push qiz
	ld	(xsp+2), xwa
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	ldb_erp	a, 251
	ld	xwa, (xsp+2)
	ld	a, (xwa+2)
	extz	wa
	sub	wa, 21
	cps	wa, 0
	jrl	lt, 327
	cp	wa, 18
	jrl	gt, 320
	add	wa, wa
	lda_24	xix, 64118
	ld_rrw	wa, xix, wa
	lda_24	xix, 194671
	jp_rr	8, xix, wa
	stb_erp	a, 251
	ld	l, a
	extz	hl
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xde, (xwa+20)
	ld	wa, hl
	lds	bc, 0
	call	171569
	jrl	t, 258
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+23)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	jrl	t, 214
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+26)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	jrl	t, 170
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+29)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	jr	t, 127
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+32)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	jr	t, 84
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+35)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	jr	t, 41
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+38)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	lda_24	xwa, 282574
	ld	xbc, xwa
	ld	xwa, (xsp+2)
	ld	a, (xwa+2)
	extz	wa
	lda_rr	xbc, xbc, wa
	ld	xwa, (xsp+2)
	ld	a, (xwa+4)
	ld	(xbc), a
	ld	xwa, (xsp+2)
	ld	a, (xwa+2)
	cp	a, 16
	jr	ugt, 5
	cps	a, 0
	jrl	nc, 954
	extz	wa
	sub	wa, 17
	cps	wa, 0
	jrl	lt, 943
	cp	wa, 84
	jrl	gt, 936
	lda_24	xix, 63971
	ld_rrw	wa, xix, wa
	extz	wa
	sll	wa, 1
	ld	xix, 64056
	ld_rrw	wa, xix, wa
	lda_24	xix, 195066
	jp_rr	8, xix, wa
	jrl	t, 898
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	207646
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	208414
	jrl	t, 871
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	207646
	jrl	t, 856
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+29)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	jrl	t, 812
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+23)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	jrl	t, 768
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+26)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	jrl	t, 724
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+29)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	jrl	t, 680
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+32)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	jrl	t, 636
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+35)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	jrl	t, 592
	stb_erp	a, 251
	ld	e, a
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xwa, xbc, wa
	lda	xwa, (xwa+38)
	ld	xbc, xwa
	ld	wa, de
	ld	xde, xbc
	lds	bc, 0
	call	171569
	jrl	t, 548
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 0
	.byte 0x1e, 0xc2, 0xf9, 0x78, 0x14, 0x02
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 1
	.byte 0x1e, 0xb2, 0xf9, 0x78, 0x04, 0x02
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 2
	.byte 0x1e, 0xa2, 0xf9, 0x78, 0xf4, 0x01
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 3
	.byte 0x1e, 0x92, 0xf9, 0x78, 0xe4, 0x01
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 0
	.byte 0x1e, 0x88, 0xfa, 0x78, 0xd4, 0x01
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 1
	.byte 0x1e, 0x78, 0xfa, 0x78, 0xc4, 0x01
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 2
	.byte 0x1e, 0x68, 0xfa, 0x78, 0xb4, 0x01
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 3
	.byte 0x1e, 0x58, 0xfa, 0x78, 0xa4, 0x01
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 0
	.byte 0x1e, 0x4d, 0xfb, 0x78, 0x94, 0x01
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 1
	.byte 0x1e, 0x3d, 0xfb, 0x78, 0x84, 0x01
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 2
	.byte 0x1e, 0x2d, 0xfb, 0x78, 0x74, 0x01
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 3
	.byte 0x1e, 0x1d, 0xfb, 0x78, 0x64, 0x01
	ld	xwa, (xsp+2)
	cp	(xwa+5), 15
	jrl	nz, 154
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	.byte 0x1e, 0x6f, 0xf6
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	lds	bc, 0
	call	210263
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	207646
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	208414
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	213775
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	.byte 0x1e, 0xc5, 0xf6
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	.byte 0x1e, 0x46, 0xf7
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	.byte 0x1e, 0xcf, 0xf7
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	.byte 0x1e, 0x34, 0xf8
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	214161
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	212435
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267214
	st_rrb	l, xbc, wa
	jrl	t, 192
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	207646
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	208414
	jrl	t, 165
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	.byte 0x1e, 0x4d, 0xf6, 0x78, 0x97, 0x00
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	.byte 0x1e, 0xcb, 0xf6
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	213775
	jr	t, 126
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	.byte 0x1e, 0x46, 0xf7
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	213775
	jr	t, 101
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	.byte 0x1e, 0x9d, 0xf7
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	213775
	jr	t, 76
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	213775
	jr	t, 62
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	213775
	jr	t, 48
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	214161
	jr	t, 34
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	call	212435
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267214
	st_rrb	l, xbc, wa
	pop qiz
	inc	4, xsp
	ret
	ld	e, c
	extz	de
	muls	de, 37
	ld	hl, de
	add	hl, 110
	extz	wa
	muls	wa, 287
	lda_24	xde, 267112
	exts	xwa
	add	xwa, xde
	ld_rrl	xde, xwa, hl
	ld	a, c
	extz	wa
	muls	wa, 5
	add	wa, 480
	lda_24	xbc, 282574
	lda_rr	xbc, xbc, wa
	ld	a, (xde+54)
	and	a, 7
	cp	a, (xbc)
	jr	nz, 39
	lds	hl, 0
	cps	hl, 4
	ret	nc
	ld	wa, hl
	extz	xwa
	add	xwa, 77
	ld	xix, xwa
	add	xix, xde
	ld	wa, hl
	extz	xwa
	inc	1, xwa
	add	xwa, xbc
	ld	a, (xwa)
	ld	(xix), a
	inc	1, hl
	cps	hl, 4
	jr	c, 16777184
	ret
	ld	a, (xbc)
	cps	a, 5
	jrl	z, 156
	cps	a, 4
	jr	z, 82
	cps	a, 2
	jr	z, 78
	cps	a, 3
	jr	z, 4
	cps	a, 1
	ret	nz
	ld	a, (xde+54)
	and	a, 7
	cps	a, 5
	jr	nz, 21
	ld	(xde+77), 0
	ld	(xde+78), 1
	ld	a, (xbc+1)
	ld	(xde+79), a
	ld	a, (xbc+2)
	ld	(xde+80), a
	ret
	lds	hl, 0
	cps	hl, 4
	ret	nc
	ld	wa, hl
	extz	xwa
	add	xwa, 77
	ld	xix, xwa
	add	xix, xde
	ld	wa, hl
	extz	xwa
	inc	1, xwa
	add	xwa, xbc
	ld	a, (xwa)
	ld	(xix), a
	inc	1, hl
	cps	hl, 4
	jr	c, 16777184
	ret
	ld	a, (xde+54)
	and	a, 7
	cps	a, 5
	jr	nz, 21
	ld	a, (xbc+1)
	ld	(xde+77), a
	ld	a, (xbc+2)
	ld	(xde+78), a
	ld	(xde+79), 127
	ld	(xde+80), 1
	ret
	lds	hl, 0
	cps	hl, 4
	ret	nc
	ld	wa, hl
	extz	xwa
	add	xwa, 77
	ld	xix, xwa
	add	xix, xde
	ld	wa, hl
	extz	xwa
	inc	1, xwa
	add	xwa, xbc
	ld	a, (xwa)
	ld	(xix), a
	inc	1, hl
	cps	hl, 4
	jr	c, 16777184
	ret
	ld	a, (xde+54)
	and	a, 7
	cps	a, 4
	jr	z, 33
	cps	a, 2
	jr	z, 29
	cps	a, 3
	jr	z, 4
	cps	a, 1
	ret	nz
	ld	a, (xbc+3)
	ld	(xde+77), a
	ld	a, (xbc+4)
	ld	(xde+78), a
	ld	(xde+79), 64
	ld	(xde+80), 135
	ret
	ld	a, (xbc+1)
	ld	(xde+77), a
	ld	a, (xbc+2)
	ld	(xde+78), a
	ld	(xde+79), 64
	ld	(xde+80), 7
	ret
	ld	e, c
	extz	de
	muls	de, 37
	ld	hl, de
	add	hl, 110
	extz	wa
	muls	wa, 287
	lda_24	xde, 267112
	exts	xwa
	add	xwa, xde
	ld_rrl	xde, xwa, hl
	ld	a, c
	extz	wa
	muls	wa, 5
	add	wa, 480
	lda_24	xbc, 282574
	lda_rr	xhl, xbc, wa
	ld	a, (xde+54)
	and	a, 7
	cp	a, (xhl)
	ret	nz
	lds	bc, 0
	cps	bc, 4
	ret	nc
	ld	wa, bc
	extz	xwa
	inc	1, xwa
	ld	xix, xwa
	add	xix, xhl
	ld	wa, bc
	extz	xwa
	add	xwa, 77
	add	xwa, xde
	ld	a, (xwa)
	ld	(xix), a
	inc	1, bc
	cps	bc, 4
	jr	c, 16777184
	ret
	dec	6, xsp
	pushw iz
	ld	(xsp+2), c
	ld	(xsp+4), xwa
	ld	a, (xsp+2)
	extz	wa
	muls	wa, 81
	add	wa, 102
	lda_24	xbc, 282574
	exts	xwa
	add	xwa, xbc
	ld	xbc, xwa
	ld	xwa, (xsp+4)
	ld	a, (xwa+2)
	res	7, a
	extz	wa
	lda_rr	xbc, xbc, wa
	ld	xwa, (xsp+4)
	ld	a, (xwa+4)
	ld	(xbc), a
	ld	xwa, (xsp+4)
	ld	a, (xwa+2)
	res	7, a
	cp	a, 77
	jrl	z, 583
	cp	a, 78
	jrl	z, 577
	cp	a, 79
	jrl	z, 571
	cp	a, 80
	jrl	z, 565
	cp	a, 76
	jrl	ugt, 581
	cp	a, 57
	jrl	nc, 575
	cp	a, 37
	jr	ugt, 6
	cp	a, 24
	jrl	nc, 564
	cp	a, 23
	jrl	z, 271
	cp	a, 22
	jr	ugt, 5
	cps	a, 7
	jrl	nc, 548
	extz	wa
	cps	wa, 0
	.byte 0x75, 0x1d, 0x02
	cps	wa, 6
	jr	le, 16
	sub	wa, 31
	cps	wa, 7
	jrl	lt, 528
	cp	wa, 25
	jrl	gt, 521
	lda_24	xix, 64156
	ld_rrw	wa, xix, wa
	extz	wa
	sll	wa, 1
	ld	xix, 64182
	ld_rrw	wa, xix, wa
	lda_24	xix, 196601
	jp_rr	8, xix, wa
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	extz	wa
	call	208414
	jrl	t, 471
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	ld	a, (xsp+2)
	ld	c, a
	extz	bc
	ld	wa, de
	call	206518
	lds	iz, 0
	cps	iz, 4
	jrl	nc, 441
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	l, a
	extz	hl
	ld	a, (xsp+2)
	ld	c, a
	extz	bc
	stb_erp	a, 248
	ld	e, a
	extz	de
	ld	wa, hl
	call	207074
	inc	1, iz
	cps	iz, 4
	jr	c, 16777180
	jrl	t, 402
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	extz	wa
	call	183606
	ld	xwa, xhl
	call	167244
	jrl	t, 381
	lds	iz, 0
	cps	iz, 4
	jr	nc, 60
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	stb_erp	a, 248
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	lds	bc, 0
	call	209109
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	stb_erp	a, 248
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	lds	bc, 0
	call	208853
	inc	1, iz
	cps	iz, 4
	jr	c, 16777156
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	ld	a, (xsp+2)
	ld	c, a
	extz	bc
	ld	wa, de
	lds	de, 0
	call	209854
	jrl	t, 287
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	extz	wa
	call	183606
	ld	xwa, xhl
	call	167359
	jrl	t, 266
	lds	iz, 0
	cps	iz, 4
	jr	nc, 60
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	stb_erp	a, 248
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	lds	bc, 1
	call	209109
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	stb_erp	a, 248
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	lds	bc, 1
	call	208853
	inc	1, iz
	cps	iz, 4
	jr	c, 16777156
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	ld	a, (xsp+2)
	ld	c, a
	extz	bc
	ld	wa, de
	lds	de, 1
	call	209854
	jrl	t, 172
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	extz	wa
	call	183541
	ld	xwa, xhl
	lds	bc, 1
	call	167462
	jrl	t, 149
	ld	xwa, (xsp+4)
	cp	(xwa+5), 7
	jrl	nz, 139
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	ld	a, (xsp+2)
	ld	c, a
	extz	bc
	ld	wa, de
	.byte 0x1e, 0x1b, 0xfc, 0x68, 0x73
	lds	iz, 0
	cps	iz, 4
	jr	nc, 60
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	stb_erp	a, 248
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	lds	bc, 2
	call	209109
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	stb_erp	a, 248
	ld	c, a
	extz	bc
	ld	wa, de
	ld	de, bc
	lds	bc, 2
	call	208853
	inc	1, iz
	cps	iz, 4
	jr	c, 16777156
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	ld	a, (xsp+2)
	ld	c, a
	extz	bc
	ld	wa, de
	lds	de, 2
	call	209854
	jr	t, 22
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	ld	a, (xsp+2)
	ld	c, a
	extz	bc
	ld	wa, de
	.byte 0x1e, 0xf2, 0xfc
	popw iz
	inc	6, xsp
	ret
	ld	c, (xwa+2)
	and	c, 192
	srl	c, 6
	extz	bc
	muls	bc, 11
	add	bc, 426
	lda_24	xde, 282574
	exts	xbc
	add	xbc, xde
	ld	xde, xbc
	ld	c, (xwa+2)
	and	c, 63
	extz	bc
	lda_rr	xde, xde, bc
	ld	c, (xwa+4)
	ld	(xde), c
	ld	a, (xwa+2)
	res	7, a
	cp	a, 10
	ret	ugt
	ret
	ld	c, (xwa+1)
	extz	bc
	muls	bc, 287
	lda_24	xde, 267118
	ld_rrl	xhl, xde, bc
	ld	c, (xwa+2)
	extz	bc
	extz	xbc
	add	xhl, xbc
	ld	c, (xwa+4)
	ld	(xhl), c
	ld	xde, 1966080
	ld	a, (xwa+2)
	extz	wa
	ld	bc, wa
	extz	xbc
	lda	xwa, (xde+18816)
	ld	xde, xwa
	add	xde, xbc
	ld	xwa, xhl
	lds	bc, 1
	jp	134579
	ld	c, a
	extz	bc
	muls	bc, 21
	ld	de, bc
	ldl_da	xbc, 283420
	ld	c, (xbc+29351)
	extz	bc
	muls	bc, 80
	ld	hl, bc
	add	hl, de
	ldl_da	xbc, 283420
	lda_rr	xbc, xbc, hl
	lda	xbc, (xbc+19127)
	extz	wa
	muls	wa, 5
	add	wa, 500
	lda_24	xde, 282574
	lda_rr	xde, xde, wa
	ld	a, (xbc+15)
	and	a, 7
	cp	a, (xde)
	jr	nz, 39
	lds	hl, 0
	cps	hl, 4
	ret	nc
	ld	wa, hl
	extz	xwa
	add	xwa, 17
	ld	xix, xwa
	add	xix, xbc
	ld	wa, hl
	extz	xwa
	inc	1, xwa
	add	xwa, xde
	ld	a, (xwa)
	ld	(xix), a
	inc	1, hl
	cps	hl, 4
	jr	c, 16777184
	ret
	ld	a, (xde)
	cps	a, 5
	jrl	z, 156
	cps	a, 4
	jr	z, 82
	cps	a, 2
	jr	z, 78
	cps	a, 3
	jr	z, 4
	cps	a, 1
	ret	nz
	ld	a, (xbc+15)
	and	a, 7
	cps	a, 5
	jr	nz, 21
	ld	(xbc+17), 0
	ld	(xbc+18), 1
	ld	a, (xde+1)
	ld	(xbc+19), a
	ld	a, (xde+2)
	ld	(xbc+20), a
	ret
	lds	hl, 0
	cps	hl, 4
	ret	nc
	ld	wa, hl
	extz	xwa
	add	xwa, 17
	ld	xix, xwa
	add	xix, xbc
	ld	wa, hl
	extz	xwa
	inc	1, xwa
	add	xwa, xde
	ld	a, (xwa)
	ld	(xix), a
	inc	1, hl
	cps	hl, 4
	jr	c, 16777184
	ret
	ld	a, (xbc+15)
	and	a, 7
	cps	a, 5
	jr	nz, 21
	ld	a, (xde+1)
	ld	(xbc+17), a
	ld	a, (xde+2)
	ld	(xbc+18), a
	ld	(xbc+19), 127
	ld	(xbc+20), 1
	ret
	lds	hl, 0
	cps	hl, 4
	ret	nc
	ld	wa, hl
	extz	xwa
	add	xwa, 17
	ld	xix, xwa
	add	xix, xbc
	ld	wa, hl
	extz	xwa
	inc	1, xwa
	add	xwa, xde
	ld	a, (xwa)
	ld	(xix), a
	inc	1, hl
	cps	hl, 4
	jr	c, 16777184
	ret
	ld	a, (xbc+15)
	and	a, 7
	cps	a, 4
	jr	z, 33
	cps	a, 2
	jr	z, 29
	cps	a, 3
	jr	z, 4
	cps	a, 1
	ret	nz
	ld	a, (xde+3)
	ld	(xbc+17), a
	ld	a, (xde+4)
	ld	(xbc+18), a
	ld	(xbc+19), 64
	ld	(xbc+20), 135
	ret
	ld	a, (xde+1)
	ld	(xbc+17), a
	ld	a, (xde+2)
	ld	(xbc+18), a
	ld	(xbc+19), 64
	ld	(xbc+20), 7
	ret
	ld	a, c
	extz	wa
	muls	wa, 21
	ld	de, wa
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	extz	wa
	muls	wa, 80
	ld	hl, wa
	add	hl, de
	ldl_da	xwa, 283420
	lda_rr	xde, xwa, hl
	lda	xde, (xde+19127)
	ld	a, c
	extz	wa
	muls	wa, 5
	add	wa, 500
	lda_24	xbc, 282574
	lda_rr	xhl, xbc, wa
	ld	a, (xde+15)
	and	a, 7
	cp	a, (xhl)
	ret	nz
	lds	bc, 0
	cps	bc, 4
	ret	nc
	ld	wa, bc
	extz	xwa
	inc	1, xwa
	ld	xix, xwa
	add	xix, xhl
	ld	wa, bc
	extz	xwa
	add	xwa, 17
	add	xwa, xde
	ld	a, (xwa)
	ld	(xix), a
	inc	1, bc
	cps	bc, 4
	jr	c, 16777184
	ret
	dec	4, xsp
	push xiz
	ld	xiz, xwa
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xhl, xbc, wa
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	ld	c, a
	extz	bc
	ld	a, (xiz+1)
	ld	e, a
	extz	de
	ld	xwa, xhl
	call	207584
	ld	(xsp+4), xhl
	ld	a, (xiz+2)
	extz	wa
	extz	xwa
	ld	xbc, xwa
	add	xbc, (xsp+4)
	ld	a, (xiz+4)
	ld	(xbc), a
	ld	a, (xiz+2)
	extz	wa
	sub	wa, 25
	cps	wa, 0
	jrl	lt, 139
	cp	wa, 11
	jr	le, 16
	sub	wa, 9
	cp	wa, 12
	jr	lt, 123
	cp	wa, 23
	jr	gt, 117
	lda_24	xix, 64200
	ld_rrw	wa, xix, wa
	extz	wa
	sll	wa, 1
	ld	xix, 64224
	ld_rrw	wa, xix, wa
	lda_24	xix, 197814
	jp_rr	8, xix, wa
	ld	a, (xiz+1)
	extz	wa
	call	183606
	ld	xwa, xhl
	call	168049
	jr	t, 65
	ld	a, (xiz+1)
	extz	wa
	call	183541
	ld	xwa, xhl
	lds	bc, 1
	call	167462
	jr	t, 46
	cp	(xiz+5), 7
	jr	nz, 40
	lds	wa, 0
	.byte 0x1e, 0x7a, 0xfd, 0x68, 0x21
	cp	(xiz+5), 7
	jr	nz, 27
	lds	wa, 1
	.byte 0x1e, 0x6d, 0xfd, 0x68, 0x14
	ld	a, (xiz+1)
	extz	wa
	lds	bc, 0
	.byte 0x1e, 0xb6, 0xfe
	ld	a, (xiz+1)
	extz	wa
	lds	bc, 1
	.byte 0x1e, 0xac, 0xfe
	ld	xde, 1966080
	ldw	bc, 58
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	extz	wa
	muls	wa, 80
	add	wa, 19111
	exts	xwa
	add	xwa, xde
	ld	xde, xwa
	ld	xwa, (xsp+4)
	call	134579
	pop xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push qiz
	ld	(xsp+2), xwa
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xhl, xbc, wa
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	ld	c, a
	extz	bc
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	ld	xwa, xhl
	call	207584
	ld	xwa, (xsp+2)
	ld	a, (xwa+2)
	and	a, 192
	srl	a, 6
	ldb_erp	a, 251
	extz	wa
	muls	wa, 21
	add	wa, 16
	lda_rr	xhl, xhl, wa
	stb_erp	a, 251
	ld	c, a
	extz	bc
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	ld	e, a
	extz	de
	ld	xwa, (xsp+2)
	ld	a, (xwa+1)
	extz	wa
	pushw wa
	ld	wa, bc
	ld	xbc, xhl
	call	206466
	ld	xwa, (xsp+2)
	ld	a, (xwa+2)
	and	a, 63
	extz	wa
	extz	xwa
	add	xhl, xwa
	ld	xwa, (xsp+2)
	ld	a, (xwa+4)
	ld	(xhl), a
	ld	xde, 1966080
	stb_erp	a, 251
	extz	wa
	muls	wa, 11
	ld	bc, wa
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	extz	wa
	muls	wa, 80
	add	wa, bc
	exts	xwa
	add	xwa, xde
	lda	xwa, (xwa+19169)
	ld	xbc, xwa
	ld	xwa, (xsp+2)
	ld	a, (xwa+2)
	and	a, 63
	extz	wa
	extz	xwa
	ld	xde, xwa
	add	xde, xbc
	ld	xwa, xhl
	lds	bc, 1
	call	134579
	pop qiz
	inc	4, xsp
	ret

; DSP_EffectStateQuery -- Query whether effect is active for a voice
; Reads bit 0 of voice struct at 0x041368; returns 1 (active) or 0.
DSP_EffectStateQuery:
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x041368
	ldw_sri WA, 0x07, 0xE8, 0xE0
	bit 0, wa
	jr z, DSP_EffectStateQuery_WriteZero
	ld (xbc), 0x1
	jr DSP_EffectStateQuery_SetResult

DSP_EffectStateQuery_WriteZero:
	ld (xbc), 0x0

DSP_EffectStateQuery_SetResult:
	lds hl, 1
	ret

DSP_AdjustVoiceParams:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), xwa
	ldb_da a, 0x0451a6
	sla a, 2
	exts wa
	ld (xsp + 4), wa
	ldb_da a, 0x0451ab
	sla a, 2
	exts wa
	ld (xsp + 6), wa
	ldb_da a, 0x0451ac
	sla a, 2
	exts wa
	ld (xsp + 8), wa
	ldiw_erp 0xFA, 0
	cpiw_erp 0xFA, 4
	jrl nc, DSP_AdjustVoiceParams_Vibrato

DSP_AdjustVoiceParams_SlotLoop:
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	add xhl, (xsp + 10)
	ld xwa, (xhl)
	ld a, (xwa + 54)
	and a, 0x7
	cps a, 5
	jr z, DSP_AdjustVoiceParams_Type5
	cps a, 4
	jr z, DSP_AdjustVoiceParams_Type1to4
	cps a, 3
	jr z, DSP_AdjustVoiceParams_Type1to4
	cps a, 2
	jr z, DSP_AdjustVoiceParams_Type1to4
	cps a, 1
	jrl nz, DSP_AdjustVoiceParams_ReverbChorus

DSP_AdjustVoiceParams_Type1to4:
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	add xhl, (xsp + 10)
	ld xwa, (xhl)
	ld a, (xwa + 77)
	extz wa
	add wa, (xsp + 4)
	call ClampS8_0_to_78
	ld iz, hl
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	add xhl, (xsp + 10)
	ld xwa, (xhl)
	stb_erp C, 0xF8
	ld (xwa + 77), c
	jrl DSP_AdjustVoiceParams_ReverbChorus

DSP_AdjustVoiceParams_Type5:
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	add xhl, (xsp + 10)
	ld xwa, (xhl)
	ld a, (xwa + 77)
	extz wa
	add wa, (xsp + 4)
	call ClampS8_0_to_78
	ld iz, hl
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	add xhl, (xsp + 10)
	ld xwa, (xhl)
	stb_erp C, 0xF8
	ld (xwa + 77), c
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	add xhl, (xsp + 10)
	ld xwa, (xhl)
	ld a, (xwa + 79)
	extz wa
	add wa, (xsp + 4)
	call ClampS8_0_to_78
	ld iz, hl
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	add xhl, (xsp + 10)
	ld xwa, (xhl)
	stb_erp C, 0xF8
	ld (xwa + 79), c

DSP_AdjustVoiceParams_ReverbChorus:
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	add xhl, (xsp + 10)
	ld xwa, (xhl)
	ld a, (xwa + 39)
	extz wa
	add wa, (xsp + 6)
	ldw bc, 0xFF
	lds de, 0
	call ClampS16_WA_To_DEBC
	ld iz, hl
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	add xhl, (xsp + 10)
	ld xwa, (xhl)
	stb_erp C, 0xF8
	ld (xwa + 39), c
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	add xhl, (xsp + 10)
	ld xwa, (xhl)
	ld a, (xwa + 45)
	extz wa
	add wa, (xsp + 8)
	ldw bc, 0xFF
	lds de, 0
	call ClampS16_WA_To_DEBC
	ld iz, hl
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, 0x6E
	add xhl, (xsp + 10)
	ld xwa, (xhl)
	stb_erp C, 0xF8
	ld (xwa + 45), c
	inc1w_erp 0xFA
	cpiw_erp 0xFA, 4
	jrl c, DSP_AdjustVoiceParams_SlotLoop

DSP_AdjustVoiceParams_Vibrato:
	cpib_da 0x0451a7, 0xf5
	jr z, DSP_AdjustVoiceParams_Filter
	ldb_da a, 0x0451a7
	sla a, 1
	ld c, a
	exts bc
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	ld a, (xwa + 43)
	extz wa
	add wa, bc
	ldw bc, 0x7F
	lds de, 0
	call ClampS16_WA_Short
	ld iz, hl
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	stb_erp C, 0xF8
	ld (xwa + 43), c
	ldb_da a, 0x0451a7
	sla a, 1
	ld c, a
	exts bc
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	ld a, (xwa + 59)
	extz wa
	add wa, bc
	ldw bc, 0x7F
	lds de, 0
	call ClampS16_WA_Short
	ld iz, hl
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	stb_erp C, 0xF8
	ld (xwa + 59), c

DSP_AdjustVoiceParams_Filter:
	ldb_da a, 0x0451a8
	sla a, 1
	ld c, a
	exts bc
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	ld a, (xwa + 44)
	extz wa
	add wa, bc
	ldw bc, 0x7F
	lds de, 0
	call ClampS16_WA_Short
	ld iz, hl
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	stb_erp C, 0xF8
	ld (xwa + 44), c
	ldb_da a, 0x0451a8
	sla a, 1
	ld c, a
	exts bc
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	ld a, (xwa + 60)
	extz wa
	add wa, bc
	ldw bc, 0x7F
	lds de, 0
	call ClampS16_WA_Short
	ld iz, hl
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	stb_erp C, 0xF8
	ld (xwa + 60), c
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	ld a, (xwa + 46)
	and a, 0x3F
	ldb_erp A, 0xF8
	extz iz
	ldb_da a, 0x0451a9
	sla a, 1
	exts wa
	add wa, iz
	ldw bc, 0x1E
	lds de, 0
	call ClampS16_WA_Short
	ld iz, hl
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	andmi8 (xwa + 46), 0xC0
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	stb_erp C, 0xF8
	or (xwa + 46), c
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	ld a, (xwa + 62)
	and a, 0x3F
	ldb_erp A, 0xF8
	extz iz
	ldb_da a, 0x0451a9
	sla a, 1
	exts wa
	add wa, iz
	ldw bc, 0x1E
	lds de, 0
	call ClampS16_WA_Short
	ld iz, hl
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	andmi8 (xwa + 62), 0xC0
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 6)
	stb_erp C, 0xF8
	or (xwa + 62), c
	pop xiz
	lda xsp, (xsp + 10)
	ret

; =============================================================================
; DSP_AlgoSelect -- Select DSP algorithm for a voice slot
; =============================================================================
; Allocates a DSP algorithm slot in the voice structure array at 0x041368.
; Multiplies algo index by 0x11F (287 bytes per voice), sets bit 0 of flags
; to mark as allocated, configures the DSP processing chain.
; Validates algo sub-type < 0x28 (40); returns error code 2 on failure.
; Called from DSP_Cmd2B_AlgoSelect (sub-command 0x00 in Audio_Process_DSP).
DSP_AlgoSelect:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), bc
	ld (xsp + 10), a
	cpw (xsp + 8), 0x28
	jr nc, DSP_AlgoSelect_InvalidParam
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	stb_dri H, 0x07, 0xE4, 0xE0
	ld wa, (xiz)
	bit 0, wa
	jr nz, DSP_AlgoSelect_AlreadyAllocated
	ormi16 (xiz), 0x1
	ld a, (xsp + 10)
	extz wa
	calr VoiceParam_FullSetup
	ld a, (xsp + 10)
	ld l, a
	extz hl
	ld a, (xiz + 25)
	ld c, a
	extz bc
	ld a, (xiz + 26)
	ld e, a
	extz de
	ld wa, hl
	call VoiceInit_Dispatcher

DSP_AlgoSelect_AlreadyAllocated:
	ld wa, (xiz)
	bit 0, wa
	jr z, DSP_AlgoSelect_WriteAndDispatch
	ld xwa, xiz
	calr DSP_AdjustVoiceParams

DSP_AlgoSelect_WriteAndDispatch:
	ld a, (xsp + 10)
	extz wa
	ld bc, (xsp + 8)
	call DSP_WriteAlgoBuffer
	ldw wa, 0xFF
	ldw bc, 0xFF
	call DSP_VoiceState_Dispatch
	ld xwa, (xsp + 4)
	ld (xwa), 0x0
	jr DSP_AlgoSelect_Return

DSP_AlgoSelect_InvalidParam:
	ld xwa, (xsp + 4)
	ld (xwa), 0x2

DSP_AlgoSelect_Return:
	lds hl, 1
	pop xiz
	inc 8, xsp
	ret

; DSP_MixSendConfig -- Configure DSP mix/send routing
; Copies 0x11 bytes of routing data via DSP_LookupVoiceBuffer.
DSP_MixSendConfig:
	push xiz
	ld xiz, xde
	call DSP_LookupVoiceBuffer
	ld xbc, xhl
	ldw hl, 0x11
	lds de, 0
	cp de, hl
	jr nc, DSP_MixSendConfig_Return

DSP_MixSendConfig_CopyLoop:
	ldb_spi A, 0xE4
	lda_dpi XBC, 0xF8
	inc 1, de
	cp de, hl
	jr c, DSP_MixSendConfig_CopyLoop

DSP_MixSendConfig_Return:
	pop xiz
	ret

; ----------------------------------------------------------------------------
; DSP_RouteCoeffs_TypeA - Route DSP coefficients via type-A table
; Entry: WA = voice parameter (masked to 7 bits)
;        BC = channel/type packed (low 4 bits = channel, bits 6-7 = type)
; Notes: 4-way dispatch based on type bits to select coefficient table
;        Table offsets: 0x44/0x48/0x4C from routing config at (0x45314)
;        Computes index: (channel << 7 + voice) * 2
;        Copies 13 bytes from source to DSP buffer at 0x45210
; ----------------------------------------------------------------------------
DSP_RouteCoeffs_TypeA:
	.byte 0x3e, 0xd8, 0xcc, 0x7f, 0x00, 0xd9, 0x8a, 0xd9
	.byte 0xcc, 0x0f, 0x00, 0xda, 0xcc, 0xc0, 0x00, 0xda
	.byte 0xcf, 0xc0, 0x00, 0x66, 0x2e, 0xda, 0xcf, 0x80
	.byte 0x00, 0x66, 0x1e, 0xda, 0xcf, 0x40, 0x00, 0x66
	.byte 0x0e, 0xda, 0xd8, 0x6e, 0x26, 0xe2, 0x14, 0x53
	.byte 0x04, 0x22, 0xaa, 0x44, 0x23, 0x68, 0x1c, 0xe2
	.byte 0x14, 0x53, 0x04, 0x22, 0xaa, 0x4c, 0x23, 0x68
	.byte 0x12, 0xe2, 0x14, 0x53, 0x04, 0x22, 0xaa, 0x48
	.byte 0x23, 0x68, 0x08, 0xe2, 0x14, 0x53, 0x04, 0x22
	.byte 0xaa, 0x44, 0x23, 0xd9, 0xee, 0x07, 0xd8, 0x81
	.byte 0xd9, 0x81, 0xd9, 0x88, 0xe8, 0x12, 0xeb, 0x80
	.byte 0xe2, 0x10, 0x53, 0x04, 0x80, 0xa0, 0x20, 0xd8
	.byte 0x8c, 0xe2, 0x14, 0x53, 0x04, 0x20, 0xa8, 0x50
	.byte 0x23, 0xe2, 0x10, 0x53, 0x04, 0x25, 0xeb, 0x85
	.byte 0x33, 0x0d, 0x00, 0xda, 0xa8, 0xdb, 0xf2, 0x6f
	.byte 0x28, 0xda, 0x89, 0xe9, 0x12, 0xdc, 0x88, 0xe8
	.byte 0x12, 0xe8, 0xee, 0x04, 0xe9, 0x80, 0xe8, 0x89
	.byte 0xed, 0x81, 0xda, 0x88, 0xd8, 0x66, 0xe8, 0x12
	.byte 0x46, 0x10, 0x52, 0x04, 0x00, 0xe8, 0x86, 0x81
	.byte 0x21, 0xb6, 0x41, 0xda, 0x61, 0xdb, 0xf2, 0x67
	.byte 0xd8, 0x5e, 0x0e
; ----------------------------------------------------------------------------
; DSP_RouteCoeffs_TypeB - Route DSP coefficients via type-B table
; Entry: Same as TypeA
; Notes: Same algorithm as TypeA with different table offsets (0x58-0x64)
; ----------------------------------------------------------------------------
DSP_RouteCoeffs_TypeB:
	.byte 0x3e, 0xd8, 0xcc, 0x7f, 0x00, 0xd9, 0x8a, 0xd9
	.byte 0xcc, 0x0f, 0x00, 0xda, 0xcc, 0xc0, 0x00, 0xda
	.byte 0xcf, 0xc0, 0x00, 0x66, 0x2e, 0xda, 0xcf, 0x80
	.byte 0x00, 0x66, 0x1e, 0xda, 0xcf, 0x40, 0x00, 0x66
	.byte 0x0e, 0xda, 0xd8, 0x6e, 0x26, 0xe2, 0x14, 0x53
	.byte 0x04, 0x22, 0xaa, 0x58, 0x23, 0x68, 0x1c, 0xe2
	.byte 0x14, 0x53, 0x04, 0x22, 0xaa, 0x60, 0x23, 0x68
	.byte 0x12, 0xe2, 0x14, 0x53, 0x04, 0x22, 0xaa, 0x5c
	.byte 0x23, 0x68, 0x08, 0xe2, 0x14, 0x53, 0x04, 0x22
	.byte 0xaa, 0x58, 0x23, 0xd9, 0xee, 0x07, 0xd8, 0x81
	.byte 0xd9, 0x81, 0xd9, 0x88, 0xe8, 0x12, 0xeb, 0x80
	.byte 0xe2, 0x10, 0x53, 0x04, 0x80, 0xa0, 0x20, 0xd8
	.byte 0x8c, 0xe2, 0x14, 0x53, 0x04, 0x20, 0xa8, 0x64
	.byte 0x23, 0xe2, 0x10, 0x53, 0x04, 0x25, 0xeb, 0x85
	.byte 0x33, 0x0d, 0x00, 0xda, 0xa8, 0xdb, 0xf2, 0x6f
	.byte 0x28, 0xda, 0x89, 0xe9, 0x12, 0xdc, 0x88, 0xe8
	.byte 0x12, 0xe8, 0xee, 0x04, 0xe9, 0x80, 0xe8, 0x89
	.byte 0xed, 0x81, 0xda, 0x88, 0xd8, 0x66, 0xe8, 0x12
	.byte 0x46, 0x10, 0x52, 0x04, 0x00, 0xe8, 0x86, 0x81
	.byte 0x21, 0xb6, 0x41, 0xda, 0x61, 0xdb, 0xf2, 0x67
	.byte 0xd8, 0x5e, 0x0e
; ----------------------------------------------------------------------------
; DSP_CopyCoeffs_TypeA - Direct coefficient copy (type A)
; Entry: WA = voice parameter
; Notes: Direct copy without 4-way dispatch, uses offset 0x50
;        Copies 13 bytes from source to DSP buffer at 0x45210
; ----------------------------------------------------------------------------
DSP_CopyCoeffs_TypeA:
	.byte 0x3e, 0xe2, 0x14, 0x53, 0x04, 0x21, 0xa9, 0x50
	.byte 0x21, 0xe2, 0x10, 0x53, 0x04, 0x25, 0xe9, 0x85
	.byte 0x33, 0x0d, 0x00, 0xdc, 0xa8, 0xdb, 0xf4, 0x6f
	.byte 0x28, 0xdc, 0x8a, 0xea, 0x12, 0xd8, 0x89, 0xe9
	.byte 0x12, 0xe9, 0xee, 0x04, 0xea, 0x81, 0xe9, 0x8a
	.byte 0xed, 0x82, 0xdc, 0x89, 0xd9, 0x66, 0xe9, 0x12
	.byte 0x46, 0x10, 0x52, 0x04, 0x00, 0xe9, 0x86, 0x82
	.byte 0x23, 0xb6, 0x43, 0xdc, 0x61, 0xdb, 0xf4, 0x67
	.byte 0xd8, 0x5e, 0x0e
; ----------------------------------------------------------------------------
; DSP_CopyCoeffs_TypeB - Direct coefficient copy (type B)
; Entry: WA = voice parameter
; Notes: Direct copy without 4-way dispatch, uses offset 0x64
;        Copies 13 bytes from source to DSP buffer at 0x45210
; ----------------------------------------------------------------------------
DSP_CopyCoeffs_TypeB:
	.byte 0x3e, 0xe2, 0x14, 0x53, 0x04, 0x21, 0xa9, 0x64
	.byte 0x21, 0xe2, 0x10, 0x53, 0x04, 0x25, 0xe9, 0x85
	.byte 0x33, 0x0d, 0x00, 0xdc, 0xa8, 0xdb, 0xf4, 0x6f
	.byte 0x28, 0xdc, 0x8a, 0xea, 0x12, 0xd8, 0x89, 0xe9
	.byte 0x12, 0xe9, 0xee, 0x04, 0xea, 0x81, 0xe9, 0x8a
	.byte 0xed, 0x82, 0xdc, 0x89, 0xd9, 0x66, 0xe9, 0x12
	.byte 0x46, 0x10, 0x52, 0x04, 0x00, 0xe9, 0x86, 0x82
	.byte 0x23, 0xb6, 0x43, 0xdc, 0x61, 0xdb, 0xf4, 0x67
	.byte 0xd8, 0x5e, 0x0e
; ----------------------------------------------------------------------------
; DSP_VoiceCoeffRoute - Voice-specific coefficient routing
; Entry: A = voice number, C = channel (low 4 bits)
; Notes: Looks up voice allocation at 0x41368 (voice * 287 + chan * 37 + 110)
;        Reads routing type from allocation entry byte 2 (bits 6-7)
;        4-way dispatch to select coefficient source table
;        Copies 13 coefficient bytes + 3 extra config bytes
;        Extra bytes: voice DE value (low, 0x00, high >> 8)
; ----------------------------------------------------------------------------
DSP_VoiceCoeffRoute:
	.byte 0x3e, 0xcb, 0x8d, 0xcd, 0xcc, 0x0f, 0xcd, 0x8b
	.byte 0xd9, 0x12, 0xd9, 0x09, 0x25, 0x00, 0xd9, 0x8d
	.byte 0xdd, 0xc8, 0x6e, 0x00, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xd9, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04
	.byte 0x34, 0xe9, 0x13, 0xec, 0x81, 0xe3, 0x07, 0xe4
	.byte 0xf4, 0x21, 0x89, 0x02, 0x23, 0xc7, 0xf0, 0x9b
	.byte 0xdc, 0x12, 0xdc, 0xcc, 0x7f, 0x00, 0xcd, 0x8b
	.byte 0xd9, 0x12, 0xd9, 0x09, 0x25, 0x00, 0xd9, 0x8e
	.byte 0xde, 0xc8, 0x6e, 0x00, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xd9, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04
	.byte 0x35, 0xe9, 0x13, 0xed, 0x81, 0xe3, 0x07, 0xe4
	.byte 0xf8, 0x21, 0x89, 0x03, 0x23, 0xc7, 0xf4, 0x9b
	.byte 0xdd, 0x12, 0xdd, 0xcc, 0x0f, 0x00, 0xcd, 0x8b
	.byte 0xd9, 0x12, 0xd9, 0x09, 0x25, 0x00, 0xd9, 0x8a
	.byte 0xda, 0xc8, 0x6e, 0x00, 0xd8, 0x12, 0xd8, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04, 0x31, 0xe8
	.byte 0x13, 0xe9, 0x80, 0xe3, 0x07, 0xe0, 0xe8, 0x20
	.byte 0x88, 0x03, 0x21, 0xd8, 0x12, 0xd8, 0xcc, 0xc0
	.byte 0x00, 0xd8, 0xcf, 0xc0, 0x00, 0x66, 0x2e, 0xd8
	.byte 0xcf, 0x80, 0x00, 0x66, 0x1e, 0xd8, 0xcf, 0x40
	.byte 0x00, 0x66, 0x0e, 0xd8, 0xd8, 0x6e, 0x26, 0xe2
	.byte 0x14, 0x53, 0x04, 0x20, 0xa8, 0x44, 0x23, 0x68
	.byte 0x1c, 0xe2, 0x14, 0x53, 0x04, 0x20, 0xa8, 0x4c
	.byte 0x23, 0x68, 0x12, 0xe2, 0x14, 0x53, 0x04, 0x20
	.byte 0xa8, 0x48, 0x23, 0x68, 0x08, 0xe2, 0x14, 0x53
	.byte 0x04, 0x20, 0xa8, 0x44, 0x23, 0xdd, 0xee, 0x07
	.byte 0xdc, 0x85, 0xdd, 0x85, 0xdd, 0x88, 0xe8, 0x12
	.byte 0xeb, 0x80, 0xe2, 0x10, 0x53, 0x04, 0x80, 0xa0
	.byte 0x20, 0xd8, 0x8a, 0xe2, 0x14, 0x53, 0x04, 0x20
	.byte 0xa8, 0x50, 0x23, 0xe2, 0x10, 0x53, 0x04, 0x24
	.byte 0xeb, 0x84, 0x33, 0x0d, 0x00, 0xdd, 0xa8, 0xdb
	.byte 0xf5, 0x6f, 0x28, 0xdd, 0x89, 0xe9, 0x12, 0xda
	.byte 0x88, 0xe8, 0x12, 0xe8, 0xee, 0x04, 0xe9, 0x80
	.byte 0xe8, 0x89, 0xec, 0x81, 0xdd, 0x88, 0xd8, 0x66
	.byte 0xe8, 0x12, 0x46, 0x10, 0x52, 0x04, 0x00, 0xe8
	.byte 0x86, 0x81, 0x21, 0xb6, 0x41, 0xdd, 0x61, 0xdb
	.byte 0xf5, 0x67, 0xd8, 0xdb, 0x88, 0xd8, 0x66, 0xe8
	.byte 0x12, 0x41, 0x10, 0x52, 0x04, 0x00, 0xe8, 0x81
	.byte 0xda, 0x88, 0xe8, 0x12, 0xe8, 0xee, 0x04, 0xec
	.byte 0x80, 0x88, 0x0d, 0x21, 0xb1, 0x41, 0xdb, 0x61
	.byte 0xdb, 0x88, 0xd8, 0x66, 0xe8, 0x12, 0x41, 0x10
	.byte 0x52, 0x04, 0x00, 0xe8, 0x81, 0xda, 0x88, 0x20
	.byte 0x00, 0xb1, 0x41, 0xdb, 0x61, 0xdb, 0x88, 0xd8
	.byte 0x66, 0xe8, 0x12, 0x41, 0x10, 0x52, 0x04, 0x00
	.byte 0xe8, 0x81, 0xda, 0x88, 0xd8, 0xef, 0x08, 0xb1
	.byte 0x41, 0xdb, 0x61, 0x5e, 0x0e
; ----------------------------------------------------------------------------
; DSP_VoiceCoeffRoute2 - Voice coefficient routing (variant 2)
; Entry: A = voice number, C = channel/type packed
; Notes: Similar to DSP_VoiceCoeffRoute but extracts both channel
;        and type from C (low 4 = channel, high 4 >> 4 = type)
;        Uses prevbank registers (D7 prefix) for extended operations
;        Multiple nested table lookups with different coefficient sets
;        Includes filter and vibrato coefficient routing
; ----------------------------------------------------------------------------
DSP_VoiceCoeffRoute2:
	.byte 0x3e, 0xcb, 0x8f, 0xcf, 0xcc, 0x0f, 0xcb, 0xcc
	.byte 0xf0, 0xcb, 0xef, 0x04, 0xcb, 0x8d, 0xcf, 0x8b
	.byte 0xd9, 0x12, 0xd9, 0x09, 0x25, 0x00, 0xd9, 0x8e
	.byte 0xde, 0xc8, 0x6e, 0x00, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xd9, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13, 0x04
	.byte 0x35, 0xe9, 0x13, 0xed, 0x81, 0xf3, 0x07, 0xe4
	.byte 0xf8, 0x35, 0xcd, 0x8b, 0xd9, 0x12, 0xd9, 0x81
	.byte 0xd9, 0x8e, 0xde, 0x63, 0xad, 0x04, 0x21, 0xc3
	.byte 0x07, 0xe4, 0xf8, 0x23, 0xc7, 0xf4, 0x9b, 0xdd
	.byte 0x12, 0xdd, 0xcc, 0x7f, 0x00, 0xcf, 0x8b, 0xd9
	.byte 0x12, 0xd9, 0x09, 0x25, 0x00, 0xd7, 0xe2, 0x99
	.byte 0xd7, 0xe2, 0xc8, 0x6e, 0x00, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xd9, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13
	.byte 0x04, 0x36, 0xe9, 0x13, 0xee, 0x81, 0xf3, 0x07
	.byte 0xe4, 0xe2, 0x36, 0xcd, 0x8b, 0xd9, 0x12, 0xd9
	.byte 0x81, 0xd7, 0xe2, 0x99, 0xd7, 0xe2, 0x63, 0xae
	.byte 0x04, 0x21, 0xf3, 0x07, 0xe4, 0xe2, 0x31, 0x89
	.byte 0x01, 0x23, 0xc7, 0xf8, 0x9b, 0xde, 0x12, 0xde
	.byte 0xcc, 0x0f, 0x00, 0xcf, 0x8b, 0xd9, 0x12, 0xd9
	.byte 0x09, 0x25, 0x00, 0xd9, 0x8b, 0xdb, 0xc8, 0x6e
	.byte 0x00, 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2
	.byte 0x68, 0x13, 0x04, 0x31, 0xe8, 0x13, 0xe9, 0x80
	.byte 0xf3, 0x07, 0xe0, 0xec, 0x31, 0xcd, 0x89, 0xd8
	.byte 0x12, 0xd8, 0x80, 0xd8, 0x8a, 0xda, 0x63, 0xa9
	.byte 0x04, 0x20, 0xf3, 0x07, 0xe0, 0xe8, 0x30, 0x88
	.byte 0x01, 0x21, 0xd8, 0x12, 0xd8, 0xcc, 0xc0, 0x00
	.byte 0xd8, 0xcf, 0xc0, 0x00, 0x66, 0x2e, 0xd8, 0xcf
	.byte 0x80, 0x00, 0x66, 0x1e, 0xd8, 0xcf, 0x40, 0x00
	.byte 0x66, 0x0e, 0xd8, 0xd8, 0x6e, 0x26, 0xe2, 0x14
	.byte 0x53, 0x04, 0x20, 0xa8, 0x58, 0x24, 0x68, 0x1c
	.byte 0xe2, 0x14, 0x53, 0x04, 0x20, 0xa8, 0x60, 0x24
	.byte 0x68, 0x12, 0xe2, 0x14, 0x53, 0x04, 0x20, 0xa8
	.byte 0x5c, 0x24, 0x68, 0x08, 0xe2, 0x14, 0x53, 0x04
	.byte 0x20, 0xa8, 0x58, 0x24, 0xde, 0xee, 0x07, 0xdd
	.byte 0x86, 0xde, 0x86, 0xde, 0x88, 0xe8, 0x12, 0xec
	.byte 0x80, 0xe2, 0x10, 0x53, 0x04, 0x80, 0xa0, 0x20
	.byte 0xd8, 0x8a, 0xe2, 0x14, 0x53, 0x04, 0x20, 0xa8
	.byte 0x64, 0x24, 0xe2, 0x10, 0x53, 0x04, 0x20, 0xec
	.byte 0x80, 0xe8, 0x8c, 0x33, 0x0d, 0x00, 0xdd, 0xa8
	.byte 0xdb, 0xf5, 0x6f, 0x28, 0xdd, 0x89, 0xe9, 0x12
	.byte 0xda, 0x88, 0xe8, 0x12, 0xe8, 0xee, 0x04, 0xe9
	.byte 0x80, 0xe8, 0x89, 0xec, 0x81, 0xdd, 0x88, 0xd8
	.byte 0x66, 0xe8, 0x12, 0x46, 0x10, 0x52, 0x04, 0x00
	.byte 0xe8, 0x86, 0x81, 0x21, 0xb6, 0x41, 0xdd, 0x61
	.byte 0xdb, 0xf5, 0x67, 0xd8, 0xdb, 0x88, 0xd8, 0x66
	.byte 0xe8, 0x12, 0x41, 0x10, 0x52, 0x04, 0x00, 0xe8
	.byte 0x81, 0xda, 0x88, 0xe8, 0x12, 0xe8, 0xee, 0x04
	.byte 0xec, 0x80, 0x88, 0x0d, 0x21, 0xb1, 0x41, 0xdb
	.byte 0x61, 0xdb, 0x88, 0xd8, 0x66, 0xe8, 0x12, 0x41
	.byte 0x10, 0x52, 0x04, 0x00, 0xe8, 0x81, 0xda, 0x88
	.byte 0x20, 0x00, 0xb1, 0x41, 0xdb, 0x61, 0xdb, 0x88
	.byte 0xd8, 0x66, 0xe8, 0x12, 0x41, 0x10, 0x52, 0x04
	.byte 0x00, 0xe8, 0x81, 0xda, 0x88, 0xd8, 0xef, 0x08
	.byte 0xb1, 0x41, 0xdb, 0x61, 0x5e, 0x0e
; ----------------------------------------------------------------------------
; DSP_AlgoCoeffLookup - Algorithm-based coefficient table lookup
; Entry: A = algorithm number (0-4)
; Notes: 5-way dispatch based on algorithm (0-4) to select table
;        Tables at config offsets: 0x54, 0x70, 0x7C, 0x88-0x98
;        Reads entry count from byte 2 of selected table entry
;        Copies coefficient data to DSP buffer at 0x45210
; ----------------------------------------------------------------------------
DSP_AlgoCoeffLookup:
	cps	a, 4
	jr	z, 60
	cps	a, 3
	jr	z, 44
	cps	a, 2
	jr	z, 28
	cps	a, 1
	jr	z, 14
	cps	a, 0
	jr	nz, 56
	ldl_da	xwa, 283412
	ld	xix, (xwa+84)
	jr	t, 54
	ldl_da	xwa, 283412
	ld	xix, (xwa+104)
	jr	t, 44
	ldl_da	xwa, 283412
	ld	xix, (xwa+132)
	jr	t, 32
	ldl_da	xwa, 283412
	ld	xix, (xwa+144)
	jr	t, 20
	ldl_da	xwa, 283412
	ld	xix, (xwa+152)
	jr	t, 8
	ldl_da	xwa, 283412
	ld	xix, (xwa+84)
	ldl_da	xwa, 283408
	add	xwa, xix
	ld	xix, xwa
	ld	a, (xwa+2)
	inc	3, a
	ld	l, a
	extz	hl
	lds	de, 0
	cp	de, hl
	ret	nc
	ld	wa, de
	extz	xwa
	ld	xbc, xix
	add	xbc, xwa
	ld	wa, de
	inc	6, wa
	extz	xwa
	ld	xiy, 283152
	add	xiy, xwa
	ld	a, (xbc)
	ld	(xiy), a
	inc	1, de
	cp	de, hl
	jr	c, 16777185
	ret

; =============================================================================
; DSP_VoiceParamReadWrite -- Read/write a single DSP parameter
; =============================================================================
; Accesses DSP parameter storage at 0x44FCE + 0x1D8 + param_index.
; If voice is allocated (bit 0 set), reads from single slot.
; Otherwise iterates 4 sub-slots via DSP_VoiceParam_MultiSlot.
; Args: wa = voice number (0-15), bc = param index (0-7),
;       xde = pointer to voice parameter data area
; Called from: sub-commands 0x10-0x17 (DSP param set) in Audio_Process_DSP
DSP_VoiceParamReadWrite:
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 10), xde
	ld (xsp + 14), bc
	ld (xsp + 16), wa
	ldw (xsp + 8), 0x0
	ld wa, (xsp + 16)
	extz xwa
	ld xbc, 0x11F
	call FP_MulAccum64
	ld xwa, 0x41368
	add xwa, xhl
	ld wa, (xwa)
	bit 0, wa
	jr z, DSP_VoiceParam_MultiSlot
	ld wa, (xsp + 14)
	extz xwa
	add xwa, 0x1D8
	ld xbc, 0x44FCE
	add xbc, xwa
	ld xwa, (xsp + 10)
	ld c, (xbc)
	ld (xwa), c
	jrl DSP_VoiceParamReadWrite_Return

DSP_VoiceParam_MultiSlot:
	ldw (xsp + 6), 0x0
	cpw (xsp + 6), 0x4
	jr nc, DSP_VoiceParam_MultiSlot_CheckResult

DSP_VoiceParam_MultiSlot_LoopBody:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	ld xiz, xhl
	add xiz, 0x6E
	ld wa, (xsp + 16)
	extz xwa
	ld xbc, 0x11F
	call FP_MulAccum64
	ld xwa, 0x41368
	add xwa, xhl
	add xwa, xiz
	ld xwa, (xwa)
	ld a, (xwa + 6)
	and a, 0xC0
	jr nz, DSP_VoiceParam_MultiSlot_LoopNext
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	ld xiz, xhl
	add xiz, 0x6E
	ld wa, (xsp + 16)
	extz xwa
	ld xbc, 0x11F
	call FP_MulAccum64
	ld xwa, 0x41368
	add xwa, xhl
	add xwa, xiz
	ld xwa, (xwa)
	bitm 5, (xwa + 6)
	jr nz, DSP_VoiceParam_MultiSlot_LoopNext
	incm 1, (xsp + 8)

DSP_VoiceParam_MultiSlot_LoopNext:
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x4
	jr c, DSP_VoiceParam_MultiSlot_LoopBody

DSP_VoiceParam_MultiSlot_CheckResult:
	ld xde, (xsp + 10)
	ldb a, 0x0
	cpw (xsp + 8), 0x4
	jr nz, DSP_VoiceParam_MultiSlot_StoreResult
	ld wa, (xsp + 14)
	extz xwa
	ld xbc, 0xF95D
	add xbc, xwa
	ld a, (xbc)

DSP_VoiceParam_MultiSlot_StoreResult:
	ld (xde), a

DSP_VoiceParamReadWrite_Return:
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 14)
	ret

DSP_ReadVoiceParam5D:
	push xiz
	ld xiz, xde
	call DSP_LookupVoiceBuffer
	ld a, (xhl + 93)
	ld (xiz), a
	lds hl, 1
	pop xiz
	ret

; ----------------------------------------------------------------------------
; DSP_VoiceParam_Dispatch - Voice parameter dispatch with routing type check
; Entry: WA = voice parameter, BC = channel/type, XDE = data pointer
; Notes: Checks bit 5 of IX (from BC) for routing mode dispatch
;        If bit 5 set: uses alternate routing path
;        Otherwise: masks WA to 7 bits, extracts HL from BC bits 4:0,
;        uses 4-way dispatch on BC bits 7:6 for coefficient table selection
;        Computes routing index and copies parameters
; ----------------------------------------------------------------------------
DSP_VoiceParam_Dispatch:
	.byte 0x3e, 0xea, 0x8e, 0xd9, 0x8c, 0xdc, 0xcc, 0x20
	.byte 0x00, 0xdc, 0xcf, 0x20, 0x00, 0x66, 0x68, 0xdc
	.byte 0xd8, 0x6e, 0x68, 0xd8, 0xcc, 0x7f, 0x00, 0xd9
	.byte 0x8b, 0xdb, 0xcc, 0x1f, 0x00, 0xd9, 0xcc, 0xc0
	.byte 0x00, 0xd9, 0xcf, 0xc0, 0x00, 0x66, 0x10, 0xd9
	.byte 0xcf, 0x80, 0x00, 0x66, 0x0a, 0xd9, 0xcf, 0x40
	.byte 0x00, 0x66, 0x04, 0xd9, 0xd8, 0x6e, 0x08, 0xe2
	.byte 0x14, 0x53, 0x04, 0x21, 0xa9, 0x7c, 0x22, 0xdb
	.byte 0x89, 0xd9, 0xee, 0x07, 0xd8, 0x81, 0xd9, 0x81
	.byte 0xd9, 0x88, 0xe8, 0x12, 0xea, 0x80, 0xe2, 0x10
	.byte 0x53, 0x04, 0x80, 0xa0, 0x20, 0xd8, 0x89, 0xe2
	.byte 0x14, 0x53, 0x04, 0x20, 0xe3, 0xe1, 0x80, 0x00
	.byte 0x22, 0xe2, 0x10, 0x53, 0x04, 0x20, 0xea, 0x80
	.byte 0xe8, 0x8a, 0xd9, 0x88, 0xe8, 0x12, 0xe8, 0xee
	.byte 0x04, 0xea, 0x80, 0xe8, 0x8b, 0x68, 0x04, 0x1d
	.byte 0x6f, 0x20, 0x03, 0x30, 0x0d, 0x00, 0xdc, 0xa8
	.byte 0xd8, 0xf4, 0x6f, 0x13, 0xf5, 0xf8, 0x32, 0xdc
	.byte 0x89, 0xe9, 0x12, 0xeb, 0x81, 0x81, 0x23, 0xb2
	.byte 0x43, 0xdc, 0x61, 0xd8, 0xf4, 0x67, 0xed, 0xd8
	.byte 0x8b, 0x5e, 0x0e

; DSP_SetVoiceCoefficients -- Write DSP voice coefficients
; Complex parameter setter using voice+0x27 region with coefficient lookups.
DSP_SetVoiceCoefficients:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), c
	lds32 xiz, 0
	lds32 xbc, 0
	ld (xsp + 4), xbc
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041381
	ldb_sri C, 0x07, 0xE8, 0xE4
	ld e, c
	extz de
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041382
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld c, a
	extz bc
	ld wa, de
	call DSP_LookupVoiceBuffer
	ld a, (xsp + 12)
	extz wa
	add wa, wa
	add wa, 0x27
	ldb_sri A, 0x07, 0xEC, 0xE0
	ld c, a
	extz bc
	ld a, (xsp + 12)
	extz wa
	add wa, wa
	add wa, 0x27
	exts xwa
	add xwa, xhl
	ld a, (xwa + 1)
	ldb_erp A, 0xF0
	extz ix
	ld wa, ix
	and wa, 0x20
	cp wa, 0x20
	jr z, DSP_SetCoeff_DirectLookup
	cps wa, 0
	jr nz, DSP_SetCoeff_CopyLoop
	and bc, 0x7F
	ld de, ix
	and de, 0x1F
	ld wa, ix
	and wa, 0xC0
	cp wa, 0xC0
	jr z, DSP_SetCoeff_LoadTableBase
	cp wa, 0x80
	jr z, DSP_SetCoeff_LoadTableBase
	cp wa, 0x40
	jr z, DSP_SetCoeff_LoadTableBase
	cps wa, 0
	jr nz, DSP_SetCoeff_ComputeIndex

DSP_SetCoeff_LoadTableBase:
	ldl_da xwa, 0x045314
	ld xwa, (xwa + 124)
	ld (xsp + 4), xwa

DSP_SetCoeff_ComputeIndex:
	ld wa, de
	sll wa, 7
	add wa, bc
	add wa, wa
	extz xwa
	add xwa, (xsp + 4)
	addda32_24 xwa, 283408
	ld xwa, (xwa)
	ld bc, wa
	ldl_da xwa, 0x045314
	ld_sril XWA, (xwa + 0x00b0)
	ld (xsp + 4), xwa
	ldl_da xiz, 0x045310
	add xiz, (xsp + 4)
	ld wa, bc
	mul wa, 0xA
	add xiz, xwa
	jr DSP_SetCoeff_CopyLoop

DSP_SetCoeff_DirectLookup:
	ld a, (xsp + 12)
	ld c, a
	extz bc
	ld xwa, xhl
	ldw de, 0xFF
	call VoiceParam_WriteDispatchHelper
	ld xiz, xhl

DSP_SetCoeff_CopyLoop:
	ldw hl, 0xA
	lds de, 0
	cp de, hl
	jr nc, DSP_SetCoeff_Return

DSP_SetCoeff_CopyLoop_Body:
	ld xwa, (xsp + 8)
	ldb_spi C, 0xF8
	lda_dpi XHL, 0xE0
	ld (xsp + 8), xwa
	inc 1, de
	cp de, hl
	jr c, DSP_SetCoeff_CopyLoop_Body

DSP_SetCoeff_Return:
	pop xiz
	lda xsp, (xsp + 10)
	ret

; ----------------------------------------------------------------------------
; DSP_SetCoeff_CopyDirect - Copy coefficients directly to DSP buffer
; Notes: Reads routing config from (0x45314), adds base from (0x45310)
;        Copies to DSP coefficient buffer at 0x45210
; ----------------------------------------------------------------------------
DSP_SetCoeff_CopyDirect:
	.byte 0x3e, 0xe2, 0x14, 0x53, 0x04, 0x21, 0xe3, 0xe5
	.byte 0x80, 0x00, 0x21, 0xe2, 0x10, 0x53, 0x04, 0x25
	.byte 0xe9, 0x85, 0x33, 0x0d, 0x00, 0xdc, 0xa8, 0xdb
	.byte 0xf4, 0x6f, 0x28, 0xdc, 0x8a, 0xea, 0x12, 0xd8
	.byte 0x89, 0xe9, 0x12, 0xe9, 0xee, 0x04, 0xea, 0x81
	.byte 0xe9, 0x8a, 0xed, 0x82, 0xdc, 0x89, 0xd9, 0x66
	.byte 0xe9, 0x12, 0x46, 0x10, 0x52, 0x04, 0x00, 0xe9
	.byte 0x86, 0x82, 0x23, 0xb6, 0x43, 0xdc, 0x61, 0xdb
	.byte 0xf4, 0x67, 0xd8, 0x5e, 0x0e
; ----------------------------------------------------------------------------
; DSP_SetCoeff_RouteComplex - Complex coefficient routing with table lookup
; Notes: Multiple table lookups via (0x45314) and (0x45310)
;        Extended routing with coefficient transformation
;        Writes to coefficient buffer at 0x45210
; ----------------------------------------------------------------------------
DSP_SetCoeff_RouteComplex:
	dec	4, xsp
	push xiz
	extz	wa
	muls	wa, 287
	lda_24	xde, 267118
	ld_rrl	xhl, xde, wa
	ld	a, c
	extz	wa
	add	wa, wa
	add	wa, 39
	ld_rrb	a, xhl, wa
	ld	e, a
	extz	de
	and	de, 127
	ld	a, c
	extz	wa
	add	wa, wa
	add	wa, 39
	exts	xwa
	add	xwa, xhl
	ld	a, (xwa+1)
	ldb_erp	a, 244
	extz	iy
	and	iy, 31
	ld	a, c
	extz	wa
	add	wa, wa
	add	wa, 39
	exts	xwa
	add	xwa, xhl
	ld	a, (xwa+1)
	ldb_erp	a, 240
	extz	ix
	and	ix, 32
	ldl_da	xwa, 283412
	ld	xhl, (xwa+124)
	ld	wa, iy
	sll	wa, 7
	add	wa, de
	add	wa, wa
	extz	xwa
	add	xwa, xhl
	addda32_24	xwa, 283408
	ld	xwa, (xwa)
	ld	de, wa
	ldl_da	xwa, 283412
	ld	xhl, (xwa+128)
	ldl_da	xwa, 283408
	add	xwa, xhl
	ld	(xsp+4), xwa
	ldw	hl, 13
	ld	wa, ix
	cp	wa, 32
	jr	z, 53
	cps	wa, 0
	jr	nz, 108
	lds	ix, 0
	cp	ix, hl
	jr	nc, 102
	ld	bc, ix
	extz	xbc
	ld	wa, de
	extz	xwa
	sll	xwa, 4
	add	xwa, xbc
	ld	xbc, xwa
	add	xbc, (xsp+4)
	ld	wa, ix
	inc	6, wa
	extz	xwa
	ld	xiy, 283152
	add	xiy, xwa
	ld	a, (xbc)
	ld	(xiy), a
	inc	1, ix
	cp	ix, hl
	jr	c, 16777175
	jr	t, 59
	lds	ix, 0
	cp	ix, hl
	jr	nc, 53
	ld	a, c
	extz	wa
	muls	wa, 80
	ld	iy, wa
	add	iy, 19111
	ldl_da	xwa, 283420
	lda_rr	xiz, xwa, iy
	ld	wa, ix
	inc	6, wa
	extz	xwa
	ld	xiy, 283152
	add	xiy, xwa
	ld	wa, ix
	extz	xwa
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xiy), a
	inc	1, ix
	cp	ix, hl
	jr	c, 16777163
	ld	wa, hl
	inc	6, wa
	extz	xwa
	ld	xbc, 283152
	add	xbc, xwa
	ld	wa, de
	extz	xwa
	sll	xwa, 4
	add	xwa, (xsp+4)
	ld	a, (xwa+13)
	ld	(xbc), a
	inc	1, hl
	ld	wa, hl
	inc	6, wa
	extz	xwa
	ld	xbc, 283152
	add	xbc, xwa
	ld	wa, de
	ldb	w, 0
	ld	(xbc), a
	inc	1, hl
	ld	wa, hl
	inc	6, wa
	extz	xwa
	ld	xbc, 283152
	add	xbc, xwa
	ld	wa, de
	srl	wa, 8
	ld	(xbc), a
	inc	1, hl
	pop xiz
	inc	4, xsp
	ret
; ----------------------------------------------------------------------------
; DSP_SetCoeff_CopyDirect2 - Copy coefficients directly (variant 2)
; Notes: Same pattern as DSP_SetCoeff_CopyDirect with different offsets
; ----------------------------------------------------------------------------
DSP_SetCoeff_CopyDirect2:
	.byte 0x3e, 0xe2, 0x14, 0x53, 0x04, 0x21, 0xe3, 0xe5
	.byte 0x8c, 0x00, 0x21, 0xe2, 0x10, 0x53, 0x04, 0x25
	.byte 0xe9, 0x85, 0x33, 0x0d, 0x00, 0xdc, 0xa8, 0xdb
	.byte 0xf4, 0x6f, 0x28, 0xdc, 0x8a, 0xea, 0x12, 0xd8
	.byte 0x89, 0xe9, 0x12, 0xe9, 0xee, 0x04, 0xea, 0x81
	.byte 0xe9, 0x8a, 0xed, 0x82, 0xdc, 0x89, 0xd9, 0x66
	.byte 0xe9, 0x12, 0x46, 0x10, 0x52, 0x04, 0x00, 0xe9
	.byte 0x86, 0x82, 0x23, 0xb6, 0x43, 0xdc, 0x61, 0xdb
	.byte 0xf4, 0x67, 0xd8, 0x5e, 0x0e
; ----------------------------------------------------------------------------
; DSP_SetCoeff_RouteWithCallback - Coefficient routing with callback function
; Notes: Calls 0x032AE0 for parameter transformation
;        Routes coefficients via (0x45314) tables
;        Uses (0x45310) base for address computation
; ----------------------------------------------------------------------------
DSP_SetCoeff_RouteWithCallback:
	.byte 0xef, 0x6c, 0x3e, 0xc7, 0xfb, 0x9d, 0xc7, 0xfb
	.byte 0xcc, 0x0f, 0xc9, 0x8d, 0xda, 0x12, 0xda, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04, 0x33, 0xe3
	.byte 0x07, 0xec, 0xe8, 0x23, 0xd9, 0x12, 0xc9, 0x8d
	.byte 0xda, 0x12, 0xeb, 0x88, 0x1d, 0xe0, 0x2a, 0x03
	.byte 0xc7, 0xfb, 0x89, 0xd8, 0x12, 0xd8, 0x09, 0x15
	.byte 0x00, 0xd8, 0xc8, 0x10, 0x00, 0xf3, 0x07, 0xec
	.byte 0xe0, 0x33, 0x8b, 0x01, 0x21, 0xc9, 0x8d, 0xda
	.byte 0x12, 0xda, 0xcc, 0x7f, 0x00, 0x8b, 0x02, 0x21
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xd9, 0xcc, 0x0f, 0x00
	.byte 0x8b, 0x02, 0x21, 0xd8, 0x12, 0xd8, 0xcc, 0xc0
	.byte 0x00, 0xd8, 0xcf, 0xc0, 0x00, 0x66, 0x10, 0xd8
	.byte 0xcf, 0x80, 0x00, 0x66, 0x0a, 0xd8, 0xcf, 0x40
	.byte 0x00, 0x66, 0x04, 0xd8, 0xd8, 0x6e, 0x0b, 0xe2
	.byte 0x14, 0x53, 0x04, 0x20, 0xa8, 0x4c, 0x20, 0xbf
	.byte 0x04, 0x60, 0xd9, 0x88, 0xd8, 0xee, 0x07, 0xda
	.byte 0x80, 0xd8, 0x80, 0xe8, 0x12, 0xaf, 0x04, 0x80
	.byte 0xe2, 0x10, 0x53, 0x04, 0x80, 0xa0, 0x20, 0xd8
	.byte 0x8a, 0xe2, 0x14, 0x53, 0x04, 0x20, 0xe3, 0xe1
	.byte 0x8c, 0x00, 0x20, 0xbf, 0x04, 0x60, 0xe2, 0x10
	.byte 0x53, 0x04, 0x24, 0xaf, 0x04, 0x84, 0x33, 0x0d
	.byte 0x00, 0xdd, 0xa8, 0xdb, 0xf5, 0x6f, 0x28, 0xdd
	.byte 0x89, 0xe9, 0x12, 0xda, 0x88, 0xe8, 0x12, 0xe8
	.byte 0xee, 0x04, 0xe9, 0x80, 0xe8, 0x89, 0xec, 0x81
	.byte 0xdd, 0x88, 0xd8, 0x66, 0xe8, 0x12, 0x46, 0x10
	.byte 0x52, 0x04, 0x00, 0xe8, 0x86, 0x81, 0x21, 0xb6
	.byte 0x41, 0xdd, 0x61, 0xdb, 0xf5, 0x67, 0xd8, 0xdb
	.byte 0x88, 0xd8, 0x66, 0xe8, 0x12, 0x41, 0x10, 0x52
	.byte 0x04, 0x00, 0xe8, 0x81, 0xda, 0x88, 0xe8, 0x12
	.byte 0xe8, 0xee, 0x04, 0xec, 0x80, 0x88, 0x0d, 0x21
	.byte 0xb1, 0x41, 0xdb, 0x61, 0xdb, 0x88, 0xd8, 0x66
	.byte 0xe8, 0x12, 0x41, 0x10, 0x52, 0x04, 0x00, 0xe8
	.byte 0x81, 0xda, 0x88, 0x20, 0x00, 0xb1, 0x41, 0xdb
	.byte 0x61, 0xdb, 0x88, 0xd8, 0x66, 0xe8, 0x12, 0x41
	.byte 0x10, 0x52, 0x04, 0x00, 0xe8, 0x81, 0xda, 0x88
	.byte 0xd8, 0xef, 0x08, 0xb1, 0x41, 0xdb, 0x61, 0x5e
	.byte 0xef, 0x64, 0x0e
; ----------------------------------------------------------------------------
; DSP_SetCoeff_FullPipeline - Full coefficient setup pipeline
; Notes: Largest coefficient setup function (384 bytes)
;        Calls 0x032AE0 and 0x032682 for multi-stage processing
;        Full routing table lookup chain via (0x45314)/(0x45310)
;        Writes computed coefficients to DSP buffer at 0x45210
; ----------------------------------------------------------------------------
DSP_SetCoeff_FullPipeline:
	.byte 0xbf, 0xf6, 0x37
	push xiz
	ld	(xsp+10), c
	ld	(xsp+12), a
	ldb_erp	e, 251
	.byte 0xc7, 0xfb, 0xcc, 0x0f
	ld	a, e
	and	a, 240
	srl	a, 4
	ld	(xsp+8), a
	ld	a, (xsp+12)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xhl, xbc, wa
	ld	a, (xsp+10)
	ld	c, a
	extz	bc
	ld	a, (xsp+12)
	ld	e, a
	extz	de
	ld	xwa, xhl
	call	207584
	stb_erp	a, 251
	extz	wa
	muls	wa, 21
	add	wa, 16
	lda_rr	xhl, xhl, wa
	stb_erp	a, 251
	ld	c, a
	extz	bc
	ld	a, (xsp+10)
	ld	e, a
	extz	de
	ld	a, (xsp+12)
	extz	wa
	pushw wa
	ld	wa, bc
	ld	xbc, xhl
	call	206466
	ld	a, (xsp+8)
	extz	wa
	add	wa, wa
	inc	3, wa
	ld_rrb	a, xhl, wa
	ld	c, a
	extz	bc
	and	bc, 127
	ld	a, (xsp+8)
	extz	wa
	add	wa, wa
	inc	3, wa
	exts	xwa
	add	xwa, xhl
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	and	de, 15
	ld	a, (xsp+8)
	extz	wa
	add	wa, wa
	inc	3, wa
	exts	xwa
	add	xwa, xhl
	ld	a, (xwa+1)
	extz	wa
	and	wa, 192
	cp	wa, 192
	jr	z, 16
	cp	wa, 128
	jr	z, 10
	cp	wa, 64
	jr	z, 4
	cps	wa, 0
	jr	nz, 11
	ldl_da	xwa, 283412
	ld	xwa, (xwa+96)
	ld	(xsp+4), xwa
	ld	wa, de
	sll	wa, 7
	add	wa, bc
	add	wa, wa
	extz	xwa
	add	xwa, (xsp+4)
	addda32_24	xwa, 283408
	ld	xwa, (xwa)
	ld	de, wa
	ldl_da	xwa, 283412
	ld	xwa, (xwa+148)
	ld	(xsp+4), xwa
	ldl_da	xix, 283408
	add	xix, (xsp+4)
	ldw	hl, 13
	lds	iy, 0
	cp	iy, hl
	jr	nc, 40
	ld	bc, iy
	extz	xbc
	ld	wa, de
	extz	xwa
	sll	xwa, 4
	add	xwa, xbc
	ld	xbc, xwa
	add	xbc, xix
	ld	wa, iy
	inc	6, wa
	extz	xwa
	ld	xiz, 283152
	add	xiz, xwa
	ld	a, (xbc)
	ld	(xiz), a
	inc	1, iy
	cp	iy, hl
	jr	c, 16777176
	ld	wa, hl
	inc	6, wa
	extz	xwa
	ld	xbc, 283152
	add	xbc, xwa
	ld	wa, de
	extz	xwa
	sll	xwa, 4
	add	xwa, xix
	ld	a, (xwa+13)
	ld	(xbc), a
	inc	1, hl
	ld	wa, hl
	inc	6, wa
	extz	xwa
	ld	xbc, 283152
	add	xbc, xwa
	ld	wa, de
	ldb	w, 0
	ld	(xbc), a
	inc	1, hl
	ld	wa, hl
	inc	6, wa
	extz	xwa
	ld	xbc, 283152
	add	xbc, xwa
	ld	wa, de
	srl	wa, 8
	ld	(xbc), a
	inc	1, hl
	pop xiz
	lda	xsp, (xsp+10)
	ret
; ----------------------------------------------------------------------------
; DSP_SetCoeff_WithDispatch - Coefficient setup with type dispatch
; Notes: Loads from (0x45314), dispatches by routing type
;        Copies coefficients to DSP buffer at 0x45210
; ----------------------------------------------------------------------------
DSP_SetCoeff_WithDispatch:
	push xiz
	and	wa, 127
	ld	de, bc
	and	bc, 15
	and	de, 192
	cp	de, 192
	jr	z, 16
	cp	de, 128
	jr	z, 10
	cp	de, 64
	jr	z, 4
	cps	de, 0
	jr	nz, 8
	ldl_da	xde, 283412
	ld	xhl, (xde+76)
	sll	bc, 7
	add	bc, wa
	add	bc, bc
	ld	wa, bc
	extz	xwa
	add	xwa, xhl
	addda32_24	xwa, 283408
	ld	xwa, (xwa)
	ld	ix, wa
	ldl_da	xwa, 283412
	ld	xhl, (xwa+140)
	ldl_da	xiy, 283408
	add	xiy, xhl
	ldw	hl, 13
	lds	de, 0
	cp	de, hl
	jr	nc, 40
	ld	bc, de
	extz	xbc
	ld	wa, ix
	extz	xwa
	sll	xwa, 4
	add	xwa, xbc
	ld	xbc, xwa
	add	xbc, xiy
	ld	wa, de
	inc	6, wa
	extz	xwa
	ld	xiz, 283152
	add	xiz, xwa
	ld	a, (xbc)
	ld	(xiz), a
	inc	1, de
	cp	de, hl
	jr	c, 16777176
	pop xiz
	ret
; ----------------------------------------------------------------------------
; DSP_SetCoeff_WriteParams - Write individual coefficient parameters
; Notes: Writes directly to DSP coefficient bytes at 0x045216/0x045217
;        Handles special parameter formatting
; ----------------------------------------------------------------------------
DSP_SetCoeff_WriteParams:
	.byte 0xdb, 0xaa, 0xc9, 0x8b, 0xd9, 0x12, 0xd9, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04, 0x32, 0xe3
	.byte 0x07, 0xe8, 0xe4, 0x21, 0x89, 0x10, 0x23, 0xf2
	.byte 0x16, 0x52, 0x04, 0x43, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xd9, 0x09, 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04
	.byte 0x32, 0xe3, 0x07, 0xe8, 0xe4, 0x21, 0x89, 0x5d
	.byte 0x23, 0xcb, 0xcc, 0x0f, 0xcb, 0xcf, 0x0c, 0x6e
	.byte 0x1a, 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2
	.byte 0x6e, 0x13, 0x04, 0x31, 0xe3, 0x07, 0xe4, 0xe0
	.byte 0x20, 0x88, 0x5f, 0x21, 0xf2, 0x17, 0x52, 0x04
	.byte 0x41, 0x68, 0x06, 0xf2, 0x17, 0x52, 0x04, 0x00
	.byte 0x00, 0x0e
; ----------------------------------------------------------------------------
; DSP_SetCoeff_MasterConfig - Master coefficient configuration routine
; Notes: Largest DSP coefficient function (706 bytes)
;        References 0x045216 (coefficient buffer) extensively
;        Calls 0x02B014 for coefficient computation
;        Full DSP state setup with all coefficient types
;        Writes to coefficient output table at 0x45210
; ----------------------------------------------------------------------------
DSP_SetCoeff_MasterConfig:
	dec	6, xsp
	pushw iz
	ld	(xsp+4), xwa
	ldw	(xsp+2), 0
	lds	iz, 0
	ld	xwa, (xsp+4)
	ld	a, (xwa+2)
	res	7, a
	extz	wa
	cps	wa, 0
	.byte 0x75, 0x9f, 0x02
	cp	wa, 23
	jrl	gt, 664
	add	wa, wa
	lda_24	xix, 64238
	ld_rrw	wa, xix, wa
	lda_24	xix, 202703
	jp_rr	8, xix, wa
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	lda_24	xwa, 283158
	ld	xbc, xwa
	ld	wa, de
	.byte 0x1e, 0x33, 0xee
	ld	iz, hl
	jrl	t, 615
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	extz	wa
	.byte 0x1e, 0x1e, 0xca
	cps	l, 0
	jr	z, 12
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	extz	wa
	call	176148
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	l, a
	extz	hl
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	c, a
	extz	bc
	lda_24	xwa, 283158
	ld	xde, xwa
	ld	wa, hl
	.byte 0x1e, 0x3b, 0xf1
	ld	iz, hl
	jrl	t, 551
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	l, a
	extz	hl
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	c, a
	extz	bc
	lda_24	xwa, 283158
	ld	xde, xwa
	ld	wa, hl
	.byte 0x1e, 0xa0, 0xf1
	ld	iz, hl
	jrl	t, 514
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	e, a
	extz	de
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	c, a
	extz	bc
	ld	wa, de
	.byte 0x1e, 0xa2, 0xf1
	ld	iz, hl
	jrl	t, 484
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	e, a
	extz	de
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	c, a
	extz	bc
	ld	wa, de
	.byte 0x1e, 0x27, 0xf2
	ld	iz, hl
	jrl	t, 454
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	c, a
	extz	bc
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	extz	wa
	sll	wa, 8
	or	wa, bc
	.byte 0x1e, 0xab, 0xf2
	ld	iz, hl
	jrl	t, 423
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	c, a
	extz	bc
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	extz	wa
	sll	wa, 8
	or	wa, bc
	.byte 0x1e, 0xcf, 0xf2
	ld	iz, hl
	jrl	t, 392
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	c, a
	extz	bc
	ld	wa, de
	.byte 0x1e, 0xf4, 0xf2
	ld	iz, hl
	jrl	t, 362
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	c, a
	extz	bc
	ld	wa, de
	.byte 0x1e, 0x43, 0xf4
	ld	iz, hl
	jrl	t, 332
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	extz	wa
	.byte 0x1e, 0xe1, 0xf5
	ld	iz, hl
	jrl	t, 316
	ldw	iz, 8
	cp	(xsp+2), iz
	jrl	nc, 307
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	c, a
	extz	bc
	ld	wa, (xsp+2)
	inc	6, wa
	extz	xwa
	ld	xde, 283152
	add	xde, xwa
	ld	wa, bc
	ld	bc, (xsp+2)
	.byte 0x1e, 0x3f, 0xf6, 0x9f, 0x02, 0x61
	cp	(xsp+2), iz
	jr	c, 16777176
	jrl	t, 264
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	l, a
	extz	hl
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	c, a
	extz	bc
	lda_24	xwa, 283158
	ld	xde, xwa
	ld	wa, hl
	.byte 0x1e, 0x06, 0xf7
	ld	iz, hl
	jrl	t, 227
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	l, a
	extz	hl
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	c, a
	extz	bc
	lda_24	xwa, 283158
	ld	xde, xwa
	ld	wa, hl
	.byte 0x1e, 0xf1, 0xf6
	ld	iz, hl
	jrl	t, 190
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	c, a
	extz	bc
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	extz	wa
	sll	wa, 8
	or	wa, bc
	.byte 0x1e, 0x82, 0xf8
	ld	iz, hl
	jrl	t, 159
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	e, a
	extz	de
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	c, a
	extz	bc
	ld	wa, de
	.byte 0x1e, 0xa9, 0xf8
	ld	iz, hl
	jrl	t, 129
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	c, a
	extz	bc
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	extz	wa
	sll	wa, 8
	or	wa, bc
	.byte 0x1e, 0xe2, 0xf9
	ld	iz, hl
	jr	t, 99
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	l, a
	extz	hl
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	ld	c, a
	extz	bc
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	e, a
	extz	de
	ld	wa, hl
	.byte 0x1e, 0xfc, 0xf9
	ld	iz, hl
	jr	t, 56
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	ld	l, a
	extz	hl
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	ld	c, a
	extz	bc
	ld	xwa, (xsp+4)
	ld	a, (xwa+3)
	ld	e, a
	extz	de
	ld	wa, hl
	.byte 0x1e, 0xf4, 0xfa
	ld	iz, hl
	jr	t, 13
	ld	xwa, (xsp+4)
	ld	a, (xwa+1)
	extz	wa
	.byte 0x1e, 0xec, 0xfc
	ld	iz, hl
	ld	hl, iz
	popw iz
	inc	6, xsp
	ret

DSP_ParamWrite_BlockCopy:
	ld xhl, xbc
	lds ix, 0
	cp ix, wa
	ret nc

DSP_ParamWrite_BlockCopy_Loop:
	ldb_spi C, 0xEC
	lda_dpi XHL, 0xE8
	inc 1, ix
	cp ix, wa
	jr c, DSP_ParamWrite_BlockCopy_Loop
	ret

DSP_ParamWrite_NopPad:
	.fill 6, 1, 0x0e

Voice_ParamFinalize:
	push xiz
	ld xiz, xwa
	ld a, (xiz)
	and a, 0x7
	bitm 3, (xiz)
	jrl z, VoiceParamFinalize_SecondaryDispatch
	extz wa
	cps wa, 0
	jrl mi, VoiceParamFinalize_Return
	cps wa, 7
	jrl gt, VoiceParamFinalize_Return
	add wa, wa
	lda_24 xix, 0x00fb2e
	ldw_sri WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0x031aa1
	jp_ind 8, 0x07, 0xF0, 0xE0

; --- ToneCmd_Dispatcher: Route tone/MIDI commands by type and channel ---
; Entry: XIZ = pointer to command structure
;   byte[0] = command type, byte[1] = note/key, byte[2] = velocity/flags
; Dispatches to velocity handlers, channel assignment (BC=0-3),
; note-on/off routing, and special command handlers.
; Each dispatch path exits via jrl to common return.
ToneCmd_DispatchTable_Body:
	ld	xwa, xiz
	calr	53978
	jrl	959
	ld	a, (xiz+1)
	extz	wa
	calr	53593
	ld	xwa, xiz
	calr	56698
	jrl	943
	ld	a, (xiz+1)
	extz	wa
	calr	53577
	ld	a, (xiz+2)
	and	a, 128
	cp	a, 128
	jr	z, 15
	cps	a, 0
	jrl	nz, 919
	ld	xwa, xiz
	lds	bc, 0
	calr	58466
	jrl	909
	ld	xwa, xiz
	lds	bc, 1
	calr	58456
	jrl	899
	ld	a, (xiz+1)
	extz	wa
	calr	53533
	ld	a, (xiz+2)
	and	a, 128
	cp	a, 128
	jr	z, 15
	cps	a, 0
	jrl	nz, 875
	ld	xwa, xiz
	lds	bc, 2
	calr	58422
	jrl	865
	ld	xwa, xiz
	lds	bc, 3
	calr	58412
	jrl	855
	ld	a, (xiz+1)
	extz	wa
	calr	53489
	ld	xwa, xiz
	calr	59077
	jrl	839
	ld	xwa, xiz
	calr	59129
	jrl	831
	ld	xwa, xiz
	calr	59642
	jrl	823
	ld	xwa, xiz
	calr	59903
	jrl	815

VoiceParamFinalize_SecondaryDispatch:
	extz wa
	cps wa, 0
	jrl mi, VoiceParamFinalize_CopyToWorkArea
	cps wa, 7
	jrl gt, VoiceParamFinalize_CopyToWorkArea
	add wa, wa
	lda_24 xix, 0x00fb1e
	ldw_sri WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0x031b5b
	jp_ind 8, 0x07, 0xF0, 0xE0

VoiceParamFinalize_SecondaryBody:
	.byte 0xee, 0x88, 0x1e, 0x35, 0xfc, 0x78, 0xca, 0x02
	.byte 0x8e, 0x01, 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x1f
	.byte 0x01, 0xf2, 0x6e, 0x13, 0x04, 0x31, 0xe3, 0x07
	.byte 0xe4, 0xe0, 0x21, 0x8e, 0x02, 0x21, 0xd8, 0x12
	.byte 0xe8, 0x12, 0xe8, 0x81, 0x8e, 0x03, 0x21, 0xc9
	.byte 0x8f, 0xdb, 0x12, 0xf2, 0x16, 0x52, 0x04, 0x30
	.byte 0xe8, 0x8a, 0xdb, 0x88, 0x1e, 0xc5, 0xfe, 0x8e
	.byte 0x02
	.ascii "?]n("
	resda_24	7, 283158
	lda_24	xhl, 283158
	ldb	e, 0
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267122
	ld_rrw	wa, xbc, wa
	bit	14, wa
	jr	z, 2
	ldb	e, 128
	or	(xhl), e
	ld	l, (xiz+3)
	extz	hl
	jrl	t, 613
	ld	a, (xiz+2)
	and	a, 128
	cp	a, 128
	jr	z, 25
	cps	a, 0
	jr	nz, 40
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267222
	ld_rrl	xbc, xbc, wa
	jr	t, 19
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267259
	ld_rrl	xbc, xbc, wa
	ld	a, (xiz+2)
	res	7, a
	extz	wa
	extz	xwa
	add	xbc, xwa
	ld	a, (xiz+3)
	ld	l, a
	extz	hl
	lda_24	xwa, 283158
	ld	xde, xwa
	ld	wa, hl
	.byte 0x1e, 0x39, 0xfe
	ld	l, (xiz+3)
	extz	hl
	jrl	t, 519
	ld	a, (xiz+2)
	and	a, 128
	cp	a, 128
	jr	z, 25
	cps	a, 0
	jr	nz, 40
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267296
	ld_rrl	xbc, xbc, wa
	jr	t, 19
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267333
	ld_rrl	xbc, xbc, wa
	ld	a, (xiz+2)
	res	7, a
	extz	wa
	extz	xwa
	add	xbc, xwa
	ld	a, (xiz+3)
	ld	l, a
	extz	hl
	lda_24	xwa, 283158
	ld	xde, xwa
	ld	wa, hl
	.byte 0x1e, 0xdb, 0xfd
	ld	l, (xiz+3)
	extz	hl
	jrl	t, 425
	ld	a, (xiz+2)
	and	a, 192
	cp	a, 192
	jr	z, 77
	cp	a, 128
	jr	z, 51
	cp	a, 64
	jr	z, 25
	cps	a, 0
	jr	nz, 82
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267226
	ld_rrl	xbc, xbc, wa
	jr	t, 61
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267263
	ld_rrl	xbc, xbc, wa
	jr	t, 40
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267300
	ld_rrl	xbc, xbc, wa
	jr	t, 19
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267337
	ld_rrl	xbc, xbc, wa
	ld	a, (xiz+2)
	and	a, 63
	extz	wa
	extz	xwa
	add	xbc, xwa
	ld	a, (xiz+3)
	ld	l, a
	extz	hl
	lda_24	xwa, 283158
	ld	xde, xwa
	ld	wa, hl
	.byte 0x1e, 0x49, 0xfd
	ld	l, (xiz+3)
	extz	hl
	jrl	t, 279
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xbc, xbc, wa
	ld	a, (xiz+2)
	extz	wa
	extz	xwa
	add	xbc, xwa
	ld	a, (xiz+3)
	ld	l, a
	extz	hl
	lda_24	xwa, 283158
	ld	xde, xwa
	ld	wa, hl
	.byte 0x1e, 0x12, 0xfd
	ld	l, (xiz+3)
	extz	hl
	jrl	t, 224
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xhl, xbc, wa
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	ld	c, a
	extz	bc
	ld	a, (xiz+1)
	ld	e, a
	extz	de
	ld	xwa, xhl
	call	207584
	ld	xbc, xhl
	ld	a, (xiz+2)
	extz	wa
	extz	xwa
	add	xbc, xwa
	ld	a, (xiz+3)
	ld	l, a
	extz	hl
	lda_24	xwa, 283158
	ld	xde, xwa
	ld	wa, hl
	.byte 0x1e, 0xbe, 0xfc
	ld	l, (xiz+3)
	extz	hl
	jrl	t, 140
	ld	a, (xiz+1)
	extz	wa
	muls	wa, 287
	lda_24	xbc, 267118
	ld_rrl	xhl, xbc, wa
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	ld	c, a
	extz	bc
	ld	a, (xiz+1)
	ld	e, a
	extz	de
	ld	xwa, xhl
	call	207584
	ld	a, (xiz+2)
	and	a, 192
	srl	a, 6
	ld	c, a
	extz	wa
	muls	wa, 21
	add	wa, 16
	lda_rr	xhl, xhl, wa
	extz	bc
	ldl_da	xwa, 283420
	ld	a, (xwa+29351)
	ld	e, a
	extz	de
	ld	a, (xiz+1)
	extz	wa
	pushw wa
	ld	wa, bc
	ld	xbc, xhl
	call	206466
	ld	xbc, xhl
	ld	a, (xiz+2)
	and	a, 63
	extz	wa
	extz	xwa
	add	xbc, xwa
	ld	a, (xiz+3)
	ld	l, a
	extz	hl
	lda_24	xwa, 283158
	ld	xde, xwa
	ld	wa, hl
	.byte 0x1e, 0x2f, 0xfc
	ld	l, (xiz+3)
	extz	hl

VoiceParamFinalize_CopyToWorkArea:
	lds ix, 0
	cps ix, 6
	jr nc, VoiceParamFinalize_CallDispatch

VoiceParamFinalize_CopyLoop:
	ld wa, ix
	extz xwa
	ld xbc, xiz
	add xbc, xwa
	ld wa, ix
	extz xwa
	ld xde, 0x45210
	add xde, xwa
	ld a, (xbc)
	ld (xde), a
	inc 1, ix
	cps ix, 6
	jr c, VoiceParamFinalize_CopyLoop

VoiceParamFinalize_CallDispatch:
	ld a, (xiz + 4)
	ld c, a
	extz bc
	inc 6, hl
	lda_24 xwa, 0x045210
	ld xde, xwa
	ld wa, bc
	ld bc, hl
	call InterCPU_DMA_Send

VoiceParamFinalize_Return:
	pop xiz
	ret

; DSP_WriteVoiceParam -- Write DSP voice parameter by mode
; Dispatches on voice+16 bits 7:6 for 4 modes (0x00/0x40/0x80/0xC0).
DSP_WriteVoiceParam:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), de
	ld (xsp + 4), bc
	ld iz, wa
	ld wa, iz
	extz xwa
	ld xbc, 0x11F
	call FP_MulAccum64
	lda_24 xwa, 0x04136e
	add xwa, xhl
	ld xwa, (xwa)
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0xC0
	jr z, DSP_WriteVoiceParam_ModeC0
	cp a, 0x80
	jr z, DSP_WriteVoiceParam_Mode80
	cp a, 0x40
	jr z, DSP_WriteVoiceParam_Mode40
	cps a, 0
	jr nz, DSP_WriteVoiceParam_Return
	ld wa, iz
	extz xwa
	ld xbc, 0x11F
	call FP_MulAccum64
	lda_24 xwa, 0x04136e
	add xwa, xhl
	ld xbc, (xwa)
	ld wa, (xsp + 4)
	extz xwa
	add xbc, xwa
	ld wa, (xsp + 2)
	ld xde, (xsp + 10)
	calr DSP_ParamWrite_BlockCopy
	ld hl, (xsp + 2)
	jr DSP_WriteVoiceParam_Return

DSP_WriteVoiceParam_Mode40:
	lds hl, 0
	jr DSP_WriteVoiceParam_Return

DSP_WriteVoiceParam_Mode80:
	ld wa, iz
	extz xwa
	ld xbc, 0x11F
	call FP_MulAccum64
	lda_24 xwa, 0x04136e
	add xwa, xhl
	ld xbc, (xwa)
	ld wa, (xsp + 4)
	extz xwa
	add xbc, xwa
	ld wa, (xsp + 2)
	ld xde, (xsp + 10)
	calr DSP_ParamWrite_BlockCopy
	ld hl, (xsp + 2)
	jr DSP_WriteVoiceParam_Return

DSP_WriteVoiceParam_ModeC0:
	lds hl, 0

DSP_WriteVoiceParam_Return:
	popw iz
	inc 4, xsp
	retd 0x4

DSP_ReadVoiceParam11:
	push xiz
	ld xiz, xde
	call DSP_LookupVoiceBuffer
	ld a, (xhl + 17)
	ld (xiz), a
	lds hl, 1
	pop xiz
	ret

DSP_LookupVoiceBuffer_CoeffPath:
	ld de, bc
	extz xde
	ldl_da xbc, 0x045314
	ld xbc, (xbc + 108)
	add xbc, xde
	addda32_24 xbc, 283408
	ld c, (xbc)
	extz bc
	ldl_da xde, 0x045314
	ld xhl, (xde + 108)
	add xhl, 0x80
	sll bc, 7
	add bc, wa
	add bc, bc
	ld wa, bc
	extz xwa
	add xwa, xhl
	addda32_24 xwa, 283408
	ld bc, (xwa)
	ldl_da xwa, 0x045314
	ld xhl, (xwa + 8)
	ld wa, bc
	sll wa, 2
	extz xwa
	add xwa, xhl
	addda32_24 xwa, 283408
	ld xhl, (xwa)
	ldl_da xwa, 0x045310
	add xwa, xhl
	ld xhl, xwa
	ret

DSP_LookupVoiceBuffer_ParamPath:
	cps bc, 7
	jr ule, DSP_LookupVoiceBuffer_ParamPath_Valid
	cp bc, 0x40
	jr z, DSP_LookupVoiceBuffer_ParamPath_Valid
	cp bc, 0x41
	jr z, DSP_LookupVoiceBuffer_ParamPath_Valid
	cp bc, 0x70
	jr nz, DSP_LookupVoiceBuffer_ParamPath_Special

DSP_LookupVoiceBuffer_ParamPath_Valid:
	ld de, bc
	extz xde
	ldl_da xbc, 0x045314
	ld xbc, (xbc + 4)
	add xbc, xde
	addda32_24 xbc, 283408
	ld c, (xbc)
	extz bc
	ldl_da xde, 0x045314
	ld xhl, (xde + 4)
	add xhl, 0x80
	sll bc, 7
	add bc, wa
	add bc, bc
	ld wa, bc
	extz xwa
	add xwa, xhl
	addda32_24 xwa, 283408
	ld bc, (xwa)
	ldl_da xwa, 0x045314
	ld xhl, (xwa + 8)
	ld wa, bc
	sll wa, 2
	extz xwa
	add xwa, xhl
	addda32_24 xwa, 283408
	ld xhl, (xwa)
	ldl_da xwa, 0x045310
	add xwa, xhl
	ld xhl, xwa
	jrl VoiceBuf_TypeSelector_Epilogue

DSP_LookupVoiceBuffer_ParamPath_Special:
	cp bc, 0x10
	jr nz, VoiceBuf_TypeCheck_0x15
	extz xwa
	ld xbc, 0x1D6
	call FP_MulAccum64
	add xhl, 0x10
	addda32_24 xhl, 283420
	jr VoiceBuf_TypeSelector_Epilogue

VoiceBuf_TypeCheck_0x15:
	cp bc, 0x15
	jr nz, VoiceBuf_TypeCheck_0x50
	extz xwa
	ld xbc, 0x1D6
	call FP_MulAccum64
	add xhl, 0x10
	addda32_24 xhl, 283416
	jr VoiceBuf_TypeSelector_Epilogue

VoiceBuf_TypeCheck_0x50:
	cp bc, 0x50
	jr nz, VoiceBuf_TypeCheck_0x55
	ldl_da xwa, 0x04531c
	stb_dri C, 0xE1, 0x80, 0x49
	jr VoiceBuf_TypeSelector_Epilogue

VoiceBuf_TypeCheck_0x55:
	cp bc, 0x55
	jr nz, VoiceBuf_TypeCheck_Default
	and wa, 0x3
	extz xwa
	ld xbc, 0x2927
	call FP_MulAccum64
	add xhl, 0x4980
	addda32_24 xhl, 283416
	jr VoiceBuf_TypeSelector_Epilogue

VoiceBuf_TypeCheck_Default:
	ldl_da xwa, 0x045314
	ld xhl, (xwa + 8)
	ldl_da xwa, 0x045310
	add xwa, xhl
	ld xhl, (xwa)
	ldl_da xwa, 0x045310
	add xwa, xhl
	ld xhl, xwa

VoiceBuf_TypeSelector_Epilogue:
	ret

; DSP_LookupVoiceBuffer -- Resolve voice buffer pointer
; Checks flag at 0x041343 and dispatches to one of two lookup functions.
; Referenced 10 times throughout the DSP processing code.
DSP_LookupVoiceBuffer:
	ldw_da xde, 0x041343
	bit 0, de
	jr z, VoiceBuf_TypeSelector_EFFMatch
	calr DSP_LookupVoiceBuffer_CoeffPath
	jr VoiceBuf_TypeSelector_NoMatch

VoiceBuf_TypeSelector_EFFMatch:
	calr DSP_LookupVoiceBuffer_ParamPath

VoiceBuf_TypeSelector_NoMatch:
	ret

VoiceBuf_TypeSelector_MatchEpilogue:
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xhl, 0x041382
	cpib_sri 0x07, 0xEC, 0xE8, 0x10
	jr c, VoiceChanScan_LoopBody
	cps c, 0
	jr nz, VoiceChanScan_Data

VoiceChanScan_LoopBody:
	ld e, c
	extz de
	ld ix, de
	add ix, ix
	lda_24 xiy, 0x00fb4e
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xhl, 0x04136e
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	ld e, (xde + 17)
	extz de
	and_sriw_rm DE, 0x07, 0xF4, 0xF0
	jr z, VoiceChanScan_Epilogue
	ldb w, 0x0
	ldb b, 0x1
	ld e, c
	inc 1, e
	cp b, e
	jr nc, VoiceChanScan_LoopNext

VoiceChanScan_MatchFound:
	ld e, b
	extz de
	ld ix, de
	add ix, ix
	lda_24 xiy, 0x00fb4e
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xhl, 0x04136e
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	ld e, (xde + 17)
	extz de
	and_sriw_rm DE, 0x07, 0xF4, 0xF0
	jr z, VoiceChanScan_NoMatch
	inc 1, w

VoiceChanScan_NoMatch:
	inc 1, b
	ld e, c
	inc 1, e
	cp b, e
	jr c, VoiceChanScan_MatchFound

VoiceChanScan_LoopNext:
	ld c, w
	jr VoiceChanScan_Data

VoiceChanScan_Epilogue:
	ldb c, 0xFF

VoiceChanScan_Data:
	ld l, c
	ret

VoiceParam_Update:
	dec 2, xsp
	pushw_erp 0xFA
	ld (xsp + 2), a
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xhl, 0x041368
	ldw_sri WA, 0x07, 0xEC, 0xE0
	bit 0, wa
	jrl z, VoiceParam_Update_InactivePath
	cp de, 0x40
	jr z, VoiceParam_Update_ActivePath
	cp de, 0x41
	jr z, VoiceParam_Update_ActivePath
	cp de, 0x50
	jr nz, VoiceParam_Update_ActiveEFF

VoiceParam_Update_ActivePath:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xde, 0x04136e
	ldl_da xwa, 0x04531c
	stb_dri W, 0xE1, 0x80, 0x49
	stl_dri XWA, 0x07, 0xE8, 0xE4
	jrl EFFSlotScan_Epilogue

VoiceParam_Update_ActiveEFF:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xde, 0x04136e
	lda_24 xwa, 0x044fce
	stl_dri XWA, 0x07, 0xE8, 0xE4
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jrl nc, EFFSlotScan_Epilogue

VoiceParam_Update_ActiveMain:
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	stb_dri C, 0x07, 0xE4, 0xE0
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xix, 0x04136e
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x51
	ld iy, wa
	add iy, 0x66
	ld_sril3 XWA, 0x07, 0xF0, 0xE4
	stb_dri W, 0x07, 0xE0, 0xF4
	stl_dri XWA, 0x07, 0xEC, 0xE8
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jr c, VoiceParam_Update_ActiveMain
	jrl EFFSlotScan_Epilogue

VoiceParam_Update_InactivePath:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xhl, 0x041368
	ldw_sri WA, 0x07, 0xEC, 0xE0
	bit 1, wa
	jrl z, EFFSlotScan_AltLoopBody
	cp (xsp + 2), 0xF
	jr ugt, VoiceParam_Update_InactiveSub
	ld wa, bc
	ld bc, de
	calr DSP_LookupVoiceBuffer
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	stl_dri XHL, 0x07, 0xE4, 0xE0
	jr VoiceParam_Update_InactiveEpilogue

VoiceParam_Update_InactiveSub:
	ld wa, bc
	ld bc, de
	calr DSP_LookupVoiceBuffer_ParamPath
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	stl_dri XHL, 0x07, 0xE4, 0xE0

VoiceParam_Update_InactiveEpilogue:
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jrl nc, EFFSlotScan_Epilogue

EFFSlotScan_LoopBody:
	ld a, (xsp + 2)
	ld e, a
	extz de
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBuf_TypeSelector_MatchEpilogue
	cp l, 0xFF
	jr nz, EFFSlotScan_AssignPath
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	stb_dri C, 0x07, 0xE4, 0xE0
	ldl_da xbc, 0x045310
	ldl_da xwa, 0x045314
	ld_sril XWA, (xwa + 0x00ac)
	add xwa, xbc
	stl_dri XWA, 0x07, 0xEC, 0xE8
	jr EFFSlotScan_LoopNext

EFFSlotScan_AssignPath:
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	stb_dri D, 0x07, 0xE4, 0xE0
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xiy, 0x04136e
	ld a, l
	extz wa
	muls wa, 0x51
	ld hl, wa
	add hl, 0x66
	ld_sril3 XWA, 0x07, 0xF4, 0xE4
	stb_dri W, 0x07, 0xE0, 0xEC
	stl_dri XWA, 0x07, 0xF0, 0xE8

EFFSlotScan_LoopNext:
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jrl c, EFFSlotScan_LoopBody
	jrl EFFSlotScan_Epilogue

EFFSlotScan_AltLoopBody:
	cp (xsp + 2), 0xF
	jr ugt, EFFSlotScan_AltMatchPath
	ld wa, bc
	ld bc, de
	calr DSP_LookupVoiceBuffer
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	stl_dri XHL, 0x07, 0xE4, 0xE0
	jr EFFSlotScan_AltAssign

EFFSlotScan_AltMatchPath:
	ld wa, bc
	ld bc, de
	calr DSP_LookupVoiceBuffer_ParamPath
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	stl_dri XHL, 0x07, 0xE4, 0xE0

EFFSlotScan_AltAssign:
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jrl nc, EFFSlotScan_Epilogue

EFFSlotScan_AltLoopNext:
	ld a, (xsp + 2)
	ld e, a
	extz de
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBuf_TypeSelector_MatchEpilogue
	cp l, 0xFF
	jr nz, EFFSlotScan_AltEpilogue
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	stb_dri C, 0x07, 0xE4, 0xE0
	ldl_da xbc, 0x045310
	ldl_da xwa, 0x045314
	ld_sril XWA, (xwa + 0x00ac)
	add xwa, xbc
	stl_dri XWA, 0x07, 0xEC, 0xE8
	jr EFFSlotScan_OuterNext

EFFSlotScan_AltEpilogue:
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	stb_dri D, 0x07, 0xE4, 0xE0
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xiy, 0x04136e
	ld a, l
	extz wa
	muls wa, 0x51
	ld hl, wa
	add hl, 0x66
	ld_sril3 XWA, 0x07, 0xF4, 0xE4
	stb_dri W, 0x07, 0xE0, 0xEC
	stl_dri XWA, 0x07, 0xF0, 0xE8

EFFSlotScan_OuterNext:
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jrl c, EFFSlotScan_AltLoopNext

EFFSlotScan_Epilogue:
	popw_erp 0xFA
	inc 2, xsp
	ret

VoiceBufIdx_Decode:
	cp de, 0xC0
	jr z, VoiceBufIdx_TableC
	cp de, 0x80
	jr z, VoiceBufIdx_TableB
	cp de, 0x40
	jr z, VoiceBufIdx_TableA
	cps de, 0
	jr nz, VoiceBufIdx_TableD
	ldl_da xde, 0x045314
	ld xhl, (xde + 12)
	ldl_da xde, 0x045314
	ld xix, (xde + 24)
	ldl_da xde, 0x045314
	ldw_sri0 IY, (xde + 0x00ea)
	jr VoiceBufIdx_TableD

VoiceBufIdx_TableA:
	ldl_da xde, 0x045314
	ld xhl, (xde + 20)
	ldl_da xde, 0x045314
	ld xix, (xde + 32)
	ldl_da xde, 0x045314
	ldw_sri0 IY, (xde + 0x00f0)
	jr VoiceBufIdx_TableD

VoiceBufIdx_TableB:
	ldl_da xde, 0x045314
	ld xhl, (xde + 16)
	ldl_da xde, 0x045314
	ld xix, (xde + 28)
	ldl_da xde, 0x045314
	ldw_sri0 IY, (xde + 0x00ea)
	jr VoiceBufIdx_TableD

VoiceBufIdx_TableC:
	ldl_da xde, 0x045314
	ld xhl, (xde + 12)
	ldl_da xde, 0x045314
	ld xix, (xde + 24)
	ldl_da xde, 0x045314
	ldw_sri0 IY, (xde + 0x00ea)

VoiceBufIdx_TableD:
	sll bc, 7
	add bc, wa
	add bc, bc
	ld wa, bc
	extz xwa
	add xwa, xhl
	addda32_24 xwa, 283408
	ld xwa, (xwa)
	ld bc, iy
	mul xbc, xwa
	add xbc, xix
	ld xhl, xbc
	addda32_24 xhl, 283408
	ret

SlotParam_WriteDispatch:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), a
	ld a, (xsp + 8)
	ld w, (xsp + 10)
	ldb_erp C, 0xF8
	extz iz
	and iz, 0x7F
	ldb_erp E, 0xF4
	extz iy
	and iy, 0xF
	ldb_erp E, 0xF0
	extz ix
	and ix, 0xC0
	ld c, e
	extz bc
	and bc, 0x30
	cp bc, 0x10
	jr z, SlotParam_WriteType1
	cp bc, 0x30
	jr z, SlotParam_WriteType0
	cp bc, 0x20
	jr z, SlotParam_WriteType0
	cps bc, 0
	jrl nz, SlotParam_WriteDispatch_Epilogue

SlotParam_WriteType0:
	ld wa, iz
	ld bc, iy
	ld de, ix
	calr VoiceBufIdx_Decode
	jrl SlotParam_WriteDispatch_Epilogue

SlotParam_WriteType1:
	ld bc, ix
	cp bc, 0x40
	jrl z, SlotParam_WriteType5
	cp bc, 0xC0
	jr z, SlotParam_WriteType2
	cp bc, 0x80
	jr z, SlotParam_WriteType2
	cps bc, 0
	jrl nz, SlotParam_WriteDispatch_Epilogue

SlotParam_WriteType2:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XDE, 0x07, 0xE8, 0xE4
	lda_24 xbc, 0x045318
	cp xde, xbc
	jr c, SlotParam_WriteType3
	cp a, 0xFF
	jr nz, SlotParam_WriteType4

SlotParam_WriteType3:
	ld a, (xsp + 2)
	ld c, a
	extz bc
	muls bc, 0xB
	ld a, w
	extz wa
	muls wa, 0x1D6
	ld de, wa
	add de, bc
	ldl_da xwa, 0x04531c
	stb_dri C, 0x07, 0xE0, 0xE8
	stb_dri C, 0xED, 0xBA, 0x01
	jrl SlotParam_WriteDispatch_Epilogue

SlotParam_WriteType4:
	ld a, (xsp + 2)
	ld c, a
	extz bc
	muls bc, 0xB
	ld a, w
	extz wa
	muls wa, 0x1D6
	ld de, wa
	add de, bc
	ldl_da xwa, 0x045318
	stb_dri C, 0x07, 0xE0, 0xE8
	stb_dri C, 0xED, 0xBA, 0x01
	jrl SlotParam_WriteDispatch_Epilogue

SlotParam_WriteType5:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XDE, 0x07, 0xE8, 0xE4
	lda_24 xbc, 0x045318
	cp xde, xbc
	jr c, SlotParam_WriteType6
	cp a, 0xFF
	jr nz, SlotParam_WriteType7

SlotParam_WriteType6:
	ld a, (xsp + 2)
	ld c, a
	extz bc
	muls bc, 0xB
	ld a, w
	extz wa
	muls wa, 0x50
	ld de, wa
	add de, bc
	ldl_da xwa, 0x04531c
	stb_dri C, 0x07, 0xE0, 0xE8
	stb_dri C, 0xED, 0xE1, 0x4A
	jr SlotParam_WriteDispatch_Epilogue

SlotParam_WriteType7:
	ld c, w
	extz bc
	muls bc, 0x50
	ld iz, bc
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041381
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	extz xwa
	ld xbc, 0x2927
	call FP_MulAccum64
	stb_dri W, 0x07, 0xEC, 0xF8
	ld xbc, xwa
	addda32_24 xbc, 283416
	ld a, (xsp + 2)
	extz wa
	muls wa, 0xB
	add wa, 0x4AE1
	stb_dri C, 0x07, 0xE4, 0xE0

SlotParam_WriteDispatch_Epilogue:
	popw iz
	inc 2, xsp
	retd 0x4

VoiceChanCopy_Main:
	ld e, c
	extz de
	muls de, 0x25
	ld ix, de
	add ix, 0x6E
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xhl, 0x041368
	exts xde
	add xde, xhl
	ld_sril3 XDE, 0x07, 0xE8, 0xF0
	ld e, (xde + 2)
	ld l, e
	extz hl
	ld e, c
	extz de
	muls de, 0x25
	ld iy, de
	add iy, 0x6E
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xix, 0x041368
	exts xde
	add xde, xix
	ld_sril3 XDE, 0x07, 0xE8, 0xF4
	ld e, (xde + 3)
	extz de
	ldb_erp C, 0xF4
	extz iy
	ldb_erp L, 0xF0
	extz ix
	ld c, e
	ld l, c
	extz hl
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041381
	ldb_sri C, 0x07, 0xE8, 0xE4
	extz bc
	pushw bc
	extz wa
	pushw wa
	ld wa, iy
	ld bc, ix
	ld de, hl
	calr SlotParam_WriteDispatch
	ret

VoiceField_ExtractAndWrite:
	ld l, (xbc + 1)
	ldb_erp L, 0xF4
	extz iy
	ld c, (xbc + 2)
	ld l, c
	extz hl
	ldb_erp A, 0xF0
	extz ix
	stb_erp A, 0xF4
	ld c, a
	extz bc
	ld a, l
	extz hl
	ld a, e
	extz wa
	pushw wa
	ld a, (xsp + 6)
	extz wa
	pushw wa
	ld wa, ix
	ld de, hl
	calr SlotParam_WriteDispatch
	retd 0x2

VoiceBufPtr_Update:
	dec 4, xsp
	ld (xsp), c
	ld (xsp + 2), a
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	ldw_sri WA, 0x07, 0xE4, 0xE0
	bit 0, wa
	jr z, VoiceBufPtr_Update_Path0
	ld a, (xsp)
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	exts xde
	add xde, xwa
	ld a, (xsp)
	extz wa
	muls wa, 0xB
	add wa, 0x1AA
	lda_24 xbc, 0x044fce
	exts xwa
	add xwa, xbc
	ld (xde + 4), xwa
	jr VoiceBufPtr_Update_Path1

VoiceBufPtr_Update_Path0:
	ld a, (xsp + 2)
	ld e, a
	extz de
	ld a, (xsp)
	ld c, a
	extz bc
	ld wa, de
	calr VoiceChanCopy_Main
	ld a, (xsp)
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xwa + 4), xhl

VoiceBufPtr_Update_Path1:
	inc 4, xsp
	ret

VoiceBufPtr_Update_Common:
	pushw iz
	ld l, a
	extz hl
	and hl, 0x7F
	ld e, c
	extz de
	and de, 0xF
	ld a, c
	extz wa
	and wa, 0xC0
	cp wa, 0x80
	jr z, VoiceTablePtr_Epilogue
	cp wa, 0x40
	jr z, VoiceTablePtr_SelectC
	cp wa, 0xC0
	jr z, VoiceTablePtr_Select
	cps wa, 0
	jrl nz, VoiceSlotAddr_Multiply

VoiceTablePtr_Select:
	ldw_da xwa, 0x041343
	bit 2, wa
	jr z, VoiceTablePtr_SelectA
	ldl_da xwa, 0x045314
	ld_sril XIX, (xwa + 0x009c)
	jr VoiceTablePtr_SelectB

VoiceTablePtr_SelectA:
	ldl_da xwa, 0x045314
	ld xix, (xwa + 36)

VoiceTablePtr_SelectB:
	ldl_da xwa, 0x045314
	ld xiy, (xwa + 48)
	ldl_da xwa, 0x045314
	ldw_sri0 IZ, (xwa + 0x00ec)
	jr VoiceSlotAddr_Multiply

VoiceTablePtr_SelectC:
	ldw_da xwa, 0x041343
	bit 2, wa
	jr z, VoiceTablePtr_SelectD
	ldl_da xwa, 0x045314
	ld_sril XIX, (xwa + 0x00a4)
	jr VoiceTablePtr_Common

VoiceTablePtr_SelectD:
	ldl_da xwa, 0x045314
	ld xix, (xwa + 44)

VoiceTablePtr_Common:
	ldl_da xwa, 0x045314
	ld xiy, (xwa + 56)
	ldl_da xwa, 0x045314
	ldw_sri0 IZ, (xwa + 0x00f2)
	jr VoiceSlotAddr_Multiply

VoiceTablePtr_Epilogue:
	ldw_da xwa, 0x041343
	bit 2, wa
	jr z, VoiceTablePtr_Data
	ldl_da xwa, 0x045314
	ld_sril XIX, (xwa + 0x00a0)
	jr VoiceTablePtr_Select2

VoiceTablePtr_Data:
	ldl_da xwa, 0x045314
	ld xix, (xwa + 40)

VoiceTablePtr_Select2:
	ldl_da xwa, 0x045314
	ld xiy, (xwa + 52)
	ldl_da xwa, 0x045314
	ldw_sri0 IZ, (xwa + 0x00ec)

VoiceSlotAddr_Multiply:
	sll de, 7
	add de, hl
	add de, de
	ld wa, de
	extz xwa
	add xwa, xix
	addda32_24 xwa, 283408
	ld xwa, (xwa)
	ld hl, wa
	ld wa, iz
	mul xwa, xhl
	add xwa, xiy
	ld xhl, xwa
	addda32_24 xhl, 283408
	popw iz
	ret

VoiceParam_WriteWithOffset:
	ld l, c
	extz hl
	muls hl, 0x25
	ld iy, hl
	add iy, 0x6E
	ld l, a
	extz hl
	muls hl, 0x11F
	lda_24 xix, 0x041368
	exts xhl
	add xhl, xix
	stb_dri D, 0x07, 0xEC, 0xF4
	ld l, e
	extz hl
	add hl, hl
	ld iy, hl
	inc 3, iy
	ld xhl, (xix + 4)
	ldb_sri L, 0x07, 0xEC, 0xF4
	extz hl
	extz bc
	muls bc, 0x25
	ld ix, bc
	add ix, 0x6E
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri A, 0x07, 0xE0, 0xF0
	ld a, e
	extz wa
	add wa, wa
	ld de, wa
	inc 3, de
	ld xwa, (xbc + 4)
	stb_dri W, 0x07, 0xE0, 0xE8
	ld a, (xwa + 1)
	extz wa
	ld e, l
	extz de
	ld c, a
	extz bc
	ld wa, de
	jrl VoiceBufPtr_Update_Common

VoiceParam_WriteWithOffset_Alt:
	ld e, a
	extz de
	add de, de
	inc 3, de
	ldb_sri E, 0x07, 0xE4, 0xE8
	extz de
	extz wa
	add wa, wa
	inc 3, wa
	exts xwa
	add xwa, xbc
	ld a, (xwa + 1)
	ld c, a
	extz bc
	ld a, e
	extz de
	ld a, c
	extz bc
	ld wa, de
	jrl VoiceBufPtr_Update_Common

VoiceParam_WriteWithOffset_3Arg:
	dec 6, xsp
	ld (xsp), e
	ld (xsp + 2), c
	ld (xsp + 4), a
	ld a, (xsp + 4)
	ld l, a
	extz hl
	ld a, (xsp + 2)
	ld c, a
	extz bc
	ld a, (xsp)
	ld e, a
	extz de
	ld wa, hl
	calr VoiceParam_WriteWithOffset
	ld a, (xsp)
	extz wa
	ld bc, wa
	sla bc, 2
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, bc
	ld a, (xsp + 4)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xwa + 118), xhl
	inc 6, xsp
	ret

VoiceInit_Dispatcher:
	dec 2, xsp
	pushw_erp 0xFA
	ld (xsp + 2), a
	ld a, (xsp + 2)
	extz wa
	extz bc
	extz de
	calr VoiceParam_Update
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0xC0
	jrl z, VoiceInit_Epilogue
	cp a, 0x80
	jrl z, VoiceInit_Epilogue
	cp a, 0x40
	jr z, VoiceInit_AltPath
	cps a, 0
	jrl nz, VoiceInit_Epilogue
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jr nc, VoiceInit_Epilogue

VoiceInit_EFFScanLoop:
	ld a, (xsp + 2)
	ld e, a
	extz de
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld wa, de
	calr VoiceBufPtr_Update
	ldib_erp 0xFA, 0
	cpib_erp 0xFA, 4
	jr nc, VoiceInit_EFFScanNext

VoiceInit_EFFScanMatch:
	ld a, (xsp + 2)
	ld l, a
	extz hl
	stb_erp A, 0xFB
	ld c, a
	extz bc
	stb_erp A, 0xFA
	ld e, a
	extz de
	ld wa, hl
	calr VoiceParam_WriteWithOffset_3Arg
	inc1b_erp 0xFA
	cpib_erp 0xFA, 4
	jr c, VoiceInit_EFFScanMatch

VoiceInit_EFFScanNext:
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jr c, VoiceInit_EFFScanLoop
	jr VoiceInit_Epilogue

VoiceInit_AltPath:
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jr nc, VoiceInit_Epilogue

VoiceInit_AltPath2:
	ld a, (xsp + 2)
	ld e, a
	extz de
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld wa, de
	call Voice_PortamentoTarget_SetSlot
	ld a, (xsp + 2)
	ld e, a
	extz de
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld wa, de
	call Voice_PortamentoTarget_ComputePitch
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jr c, VoiceInit_AltPath2

VoiceInit_Epilogue:
	popw_erp 0xFA
	inc 2, xsp
	ret

VoiceBuf_Lookup_0x20Flag:
	pushw iz
	ld l, (xsp + 6)
	ld iy, wa
	and iy, 0x7F
	ld iz, bc
	and iz, 0x1F
	and bc, 0x20
	ld wa, bc
	cp wa, 0x20
	jr z, VoiceBuf_Lookup_FlagSet
	cps wa, 0
	jrl nz, VoiceBuf_Lookup_Epilogue
	ldl_da xwa, 0x045314
	ld xde, (xwa + 116)
	ldl_da xwa, 0x045314
	ld xbc, (xwa + 120)
	ldl_da xwa, 0x045314
	ldw_sri0 HL, (xwa + 0x00ee)
	ld wa, iz
	sll wa, 7
	add wa, iy
	add wa, wa
	extz xwa
	add xwa, xde
	addda32_24 xwa, 283408
	ld xwa, (xwa)
	ld iy, wa
	ld wa, hl
	mul xwa, xiy
	add xwa, xbc
	addda32_24 xwa, 283408
	ld xix, xwa
	jr VoiceBuf_Lookup_Epilogue

VoiceBuf_Lookup_FlagSet:
	ld a, l
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	lda_24 xwa, 0x045318
	cp xbc, xwa
	jr c, VoiceBuf_Lookup_FlagClear
	cp l, 0xFF
	jr nz, VoiceBuf_Lookup_Common

VoiceBuf_Lookup_FlagClear:
	ld a, e
	extz wa
	muls wa, 0x50
	ld bc, wa
	add bc, 0x4AA7
	ldl_da xwa, 0x04531c
	stb_dri D, 0x07, 0xE0, 0xE4
	jr VoiceBuf_Lookup_Epilogue

VoiceBuf_Lookup_Common:
	ld a, e
	extz wa
	muls wa, 0x50
	ld iz, wa
	ld a, l
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041381
	ldb_sri A, 0x07, 0xE4, 0xE0
	extz wa
	extz xwa
	ld xbc, 0x2927
	call FP_MulAccum64
	stb_dri D, 0x07, 0xEC, 0xF8
	addda32_24 xix, 283416
	stb_dri D, 0xF1, 0xA7, 0x4A

VoiceBuf_Lookup_Epilogue:
	ld xhl, xix
	popw iz
	retd 0x2

VoiceParam_WriteDispatchHelper:
	ld l, c
	extz hl
	add hl, hl
	add hl, 0x27
	ldb_sri L, 0x07, 0xE0, 0xEC
	ldb_erp L, 0xF4
	extz iy
	ld l, c
	extz hl
	add hl, hl
	add hl, 0x27
	stb_dri W, 0x07, 0xE0, 0xEC
	ld a, (xwa + 1)
	ldb_erp A, 0xF0
	extz ix
	ld l, c
	extz hl
	ld a, e
	extz wa
	pushw wa
	ld wa, iy
	ld bc, ix
	ld de, hl
	calr VoiceBuf_Lookup_0x20Flag
	ret

VoiceFlags_Aggregate:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136a
	ldw_sri BC, 0x07, 0xE8, 0xE4
	extz xbc
	and xbc, 0xFFFF3FF0
	ld de, bc
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xhl, 0x04136e
	ld_sril3 XBC, 0x07, 0xEC, 0xE4
	ld l, (xbc + 18)
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XBC, 0x07, 0xF0, 0xE4
	bitm 0, (xbc + 17)
	jr z, VoiceFlags_Bit0Check
	set 0, de
	jr VoiceFlags_Bit0Set

VoiceFlags_Bit0Check:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x041372
	ldw_sri BC, 0x07, 0xF0, 0xE4
	extz xbc
	bit 15, bc
	jr z, VoiceFlags_Bit0Set
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XBC, 0x07, 0xF0, 0xE4
	bitm 2, (xbc + 17)
	jr z, VoiceFlags_Bit0Set
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XBC, 0x07, 0xF0, 0xE4
	ld c, (xbc + 93)
	and c, 0xF
	cp c, 0x8
	jr ugt, VoiceFlags_Bit0Set
	cps c, 0
	jr c, VoiceFlags_Bit0Set
	or de, 0x4001

VoiceFlags_Bit0Set:
	ld c, l
	and c, 0x3
	cps c, 1
	jr nz, VoiceFlags_Bit1Check
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x0413ee
	or_sriw_im 0x07, 0xF0, 0xE4, 0x00, 0x80
	jr VoiceFlags_Bit1Set

VoiceFlags_Bit1Check:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x0413ee
	and_sriw_im 0x07, 0xF0, 0xE4, 0xFF, 0x7F

VoiceFlags_Bit1Set:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XBC, 0x07, 0xF0, 0xE4
	bitm 2, (xbc + 17)
	jr z, VoiceFlags_Bit2Check
	set 1, de
	jr VoiceFlags_Bit2Set

VoiceFlags_Bit2Check:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x041372
	ldw_sri BC, 0x07, 0xF0, 0xE4
	extz xbc
	bit 15, bc
	jr z, VoiceFlags_Bit2Set
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XBC, 0x07, 0xF0, 0xE4
	bitm 0, (xbc + 17)
	jr z, VoiceFlags_Bit2Set
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XBC, 0x07, 0xF0, 0xE4
	ld c, (xbc + 93)
	and c, 0xF
	cp c, 0x8
	jr ugt, VoiceFlags_Bit2Set
	cps c, 0
	jr c, VoiceFlags_Bit2Set
	or de, 0x8002

VoiceFlags_Bit2Set:
	ld c, l
	and c, 0xC
	cps c, 4
	jr nz, VoiceFlags_Bit3Check
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x041413
	or_sriw_im 0x07, 0xF0, 0xE4, 0x00, 0x80
	jr VoiceFlags_Bit3Set

VoiceFlags_Bit3Check:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x041413
	and_sriw_im 0x07, 0xF0, 0xE4, 0xFF, 0x7F

VoiceFlags_Bit3Set:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XBC, 0x07, 0xF0, 0xE4
	bitm 4, (xbc + 17)
	jr z, VoiceFlags_Bit4Check
	set 2, de

VoiceFlags_Bit4Check:
	ld c, l
	and c, 0x30
	cp c, 0x10
	jr nz, VoiceFlags_Bit4Set
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x041438
	or_sriw_im 0x07, 0xF0, 0xE4, 0x00, 0x80
	jr VoiceFlags_Bit5Check

VoiceFlags_Bit4Set:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x041438
	and_sriw_im 0x07, 0xF0, 0xE4, 0xFF, 0x7F

VoiceFlags_Bit5Check:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XBC, 0x07, 0xF0, 0xE4
	bitm 6, (xbc + 17)
	jr z, VoiceFlags_Bit5Set
	set 3, de

VoiceFlags_Bit5Set:
	ld c, l
	and c, 0xC0
	cp c, 0x40
	jr nz, VoiceFlags_Bit6Check
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xhl, 0x04145d
	or_sriw_im 0x07, 0xEC, 0xE4, 0x00, 0x80
	jr VoiceFlags_Bit6Set

VoiceFlags_Bit6Check:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xhl, 0x04145d
	and_sriw_im 0x07, 0xEC, 0xE4, 0xFF, 0x7F

VoiceFlags_Bit6Set:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	stw_dri DE, 0x07, 0xE4, 0xE0
	ret

SignedClamp_Zero:
	cp wa, 0x7F
	jr le, SignedClamp_Max
	ldw wa, 0x7F
	jr SignedClamp_InRange

SignedClamp_Max:
	cps wa, 0
	jr ge, SignedClamp_InRange
	lds wa, 0

SignedClamp_InRange:
	ld hl, wa
	ret

AlgoType_TableLookup:
	cps c, 3
	jrl z, AlgoType_TableCommon
	cps c, 2
	jrl z, AlgoType_Table3
	cps c, 1
	jr z, AlgoType_Table1
	cps c, 0
	ret nz
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136a
	ldw_sri BC, 0x07, 0xE8, 0xE4
	bit 14, bc
	jr z, AlgoType_Table0
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413fb
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld l, (xwa + 1)
	extz hl
	ret

AlgoType_Table0:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413d6
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld l, (xwa + 1)
	extz hl
	ret

AlgoType_Table1:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136a
	ldw_sri BC, 0x07, 0xE8, 0xE4
	extz xbc
	bit 15, bc
	jr z, AlgoType_Table2
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413d6
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld l, (xwa + 1)
	extz hl
	ret

AlgoType_Table2:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413fb
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld l, (xwa + 1)
	extz hl
	ret

AlgoType_Table3:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041420
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld l, (xwa + 1)
	extz hl
	ret

AlgoType_TableCommon:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041445
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld l, (xwa + 1)
	extz hl
	ret

EnvTranspose_UpdateLoop:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 18), a
	ld a, (xsp + 18)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	ld (xsp + 4), xwa
	ld a, (xsp + 18)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041376
	ldb_sri A, 0x07, 0xE4, 0xE0
	sub a, 0x40
	exts wa
	ld (xsp + 8), wa
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jrl nc, EnvTranspose_SubPath1

EnvTranspose_ApplyPath:
	ld a, (xsp + 18)
	ld e, a
	extz de
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld wa, de
	calr AlgoType_TableLookup
	stb_erp A, 0xFB
	extz wa
	add wa, wa
	lda xbc, (xsp + 10)
	stw_dri HL, 0x07, 0xE4, 0xE0
	cp hl, 0x80
	jr z, EnvTranspose_LoopNext
	stb_erp A, 0xFB
	extz wa
	add wa, wa
	lda xbc, (xsp + 10)
	ldw_sri WA, 0x07, 0xE4, 0xE0
	add wa, (xsp + 8)
	calr SignedClamp_Zero
	stb_erp A, 0xFB
	extz wa
	add wa, wa
	lda xbc, (xsp + 10)
	stw_dri HL, 0x07, 0xE4, 0xE0

EnvTranspose_LoopNext:
	stb_erp A, 0xFB
	extz wa
	add wa, wa
	lda xbc, (xsp + 10)
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld e, a
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld bc, wa
	add bc, 0x6E
	ld xwa, (xsp + 4)
	stb_dri W, 0x07, 0xE0, 0xE4
	ld (xwa + 35), e
	stb_erp A, 0xFB
	extz wa
	add wa, wa
	lda xbc, (xsp + 10)
	ldw_sri WA, 0x07, 0xE4, 0xE0
	ld e, a
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld bc, wa
	add bc, 0x6E
	ld xwa, (xsp + 4)
	stb_dri W, 0x07, 0xE0, 0xE4
	ld (xwa + 36), e
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jrl c, EnvTranspose_ApplyPath

EnvTranspose_SubPath1:
	ld a, (xsp + 18)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 93)
	ldb_erp A, 0xFB
	ld xwa, (xsp + 4)
	ld wa, (xwa + 10)
	extz xwa
	bit 15, wa
	jrl z, EnvTranspose_Epilogue
	bit_erpb 0xFB, 0x06
	jrl z, EnvTranspose_Epilogue
	ld wa, (xsp + 12)
	cp wa, (xsp + 10)
	jrl nz, EnvTranspose_Epilogue
	cpw (xsp + 10), 0x80
	jrl z, EnvTranspose_Epilogue
	ld iz, (xsp + 10)
	ld wa, iz
	cp wa, 0x40
	jr ge, EnvTranspose_SubPath2
	ld wa, iz
	sub wa, 0x10
	calr SignedClamp_Zero
	ld iz, hl
	ld wa, iz
	add wa, 0x28
	calr SignedClamp_Zero
	jr EnvTranspose_SubPath3

EnvTranspose_SubPath2:
	ld wa, iz
	add wa, 0x10
	calr SignedClamp_Zero
	ld iz, hl
	ld wa, iz
	sub wa, 0x28
	calr SignedClamp_Zero

EnvTranspose_SubPath3:
	stb_erp A, 0xFB
	and a, 0xF
	cp a, 0x9
	jr nz, EnvTranspose_SubPath4
	stb_erp C, 0xF8
	ld xwa, (xsp + 4)
	lda_dri XHL, 0xE1, 0x91, 0x00
	stb_erp C, 0xF8
	ld xwa, (xsp + 4)
	lda_dri XHL, 0xE1, 0xB6, 0x00
	ld c, l
	ld xwa, (xsp + 4)
	lda_dri XHL, 0xE1, 0x92, 0x00
	ld xwa, (xsp + 4)
	lda_dri XSP, 0xE1, 0xB7, 0x00
	jr EnvTranspose_Epilogue

EnvTranspose_SubPath4:
	stb_erp A, 0xFB
	and a, 0xF
	cp a, 0xA
	jr nc, EnvTranspose_Epilogue
	stb_erp C, 0xF8
	ld xwa, (xsp + 4)
	lda_dri XHL, 0xE1, 0x91, 0x00
	ld xwa, (xsp + 4)
	lda_dri XSP, 0xE1, 0xB6, 0x00

EnvTranspose_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

AlgoFlag_Write:
	pushw iz
	ld l, e
	extz hl
	ld ix, hl
	sla ix, 2
	ld l, c
	extz hl
	sla hl, 4
	ld iy, hl
	add iy, ix
	ld l, a
	extz hl
	muls hl, 0x11F
	lda_24 xix, 0x041368
	exts xhl
	add xhl, xix
	stb_dri D, 0x07, 0xEC, 0xF4
	lda xix, (xix + 39)
	ld l, a
	extz hl
	muls hl, 0x11F
	lda_24 xiy, 0x04136e
	ld_sril3 XHL, 0x07, 0xF4, 0xEC
	andmi8 (xix), 0xFC
	cp (xix + 3), 0x0
	jr z, AlgoFlag_Write_OuterStart
	ld l, (xix + 1)
	and l, 0x55
	jr z, AlgoFlag_Write_OuterStart
	setm 1, (xix)
	jrl AlgoFlag_Write_Epilogue

AlgoFlag_Write_OuterStart:
	ldb w, 0x0
	cps w, 4
	jrl nc, AlgoFlag_Write_Epilogue

AlgoFlag_Write_InnerLoop:
	ld l, c
	cps l, 2
	jr z, AlgoFlag_Write_InnerNext
	cps l, 1
	jr z, AlgoFlag_Write_InnerMatch
	cps l, 0
	jr nz, AlgoFlag_Write_OuterMatch
	ld l, w
	extz hl
	muls hl, 0x25
	ld iz, hl
	add iz, 0x6E
	ld l, a
	extz hl
	muls hl, 0x11F
	lda_24 xiy, 0x041368
	exts xhl
	add xhl, xiy
	ld_sril3 XHL, 0x07, 0xEC, 0xF8
	ld b, (xhl + 6)
	jr AlgoFlag_Write_OuterMatch

AlgoFlag_Write_InnerMatch:
	ld l, w
	extz hl
	muls hl, 0x25
	ld iz, hl
	add iz, 0x6E
	ld l, a
	extz hl
	muls hl, 0x11F
	lda_24 xiy, 0x041368
	exts xhl
	add xhl, xiy
	ld_sril3 XHL, 0x07, 0xEC, 0xF8
	ld b, (xhl + 38)
	jr AlgoFlag_Write_OuterMatch

AlgoFlag_Write_InnerNext:
	ld l, w
	extz hl
	muls hl, 0x25
	ld iz, hl
	add iz, 0x6E
	ld l, a
	extz hl
	muls hl, 0x11F
	lda_24 xiy, 0x041368
	exts xhl
	add xhl, xiy
	ld_sril3 XHL, 0x07, 0xEC, 0xF8
	ld b, (xhl + 56)

AlgoFlag_Write_OuterMatch:
	bit 5, b
	jr z, AlgoFlag_Write_OuterNext
	ld l, b
	and l, 0xC0
	srl l, 6
	cp l, e
	jr nz, AlgoFlag_Write_OuterNext
	setm 0, (xix)

AlgoFlag_Write_OuterNext:
	inc 1, w
	cps w, 4
	jrl c, AlgoFlag_Write_InnerLoop

AlgoFlag_Write_Epilogue:
	popw iz
	ret

AlgoFlag_Write_Bit3:
	pushw iz
	ld l, e
	extz hl
	ld ix, hl
	sla ix, 2
	ld l, c
	extz hl
	sla hl, 4
	ld iy, hl
	add iy, ix
	ld l, a
	extz hl
	muls hl, 0x11F
	lda_24 xix, 0x041368
	exts xhl
	add xhl, xix
	stb_dri D, 0x07, 0xEC, 0xF4
	lda xix, (xix + 39)
	ld l, a
	extz hl
	muls hl, 0x11F
	lda_24 xiy, 0x04136e
	ld_sril3 XHL, 0x07, 0xF4, 0xEC
	andmi8 (xix), 0xF3
	cp (xix + 2), 0x0
	jr z, AlgoFlag_Write_Bit3_OuterStart
	ld l, (xix + 1)
	and l, 0x55
	jr z, AlgoFlag_Write_Bit3_OuterStart
	setm 3, (xix)
	jrl AlgoFlag_Write_Bit3_Epilogue

AlgoFlag_Write_Bit3_OuterStart:
	ldb w, 0x0
	cps w, 4
	jrl nc, AlgoFlag_Write_Bit3_Epilogue

AlgoFlag_Write_Bit3_InnerLoop:
	ld l, c
	cps l, 2
	jr z, AlgoFlag_Write_Bit3_InnerNext
	cps l, 1
	jr z, AlgoFlag_Write_Bit3_InnerMatch
	cps l, 0
	jr nz, AlgoFlag_Write_Bit3_OuterMatch
	ld l, w
	extz hl
	muls hl, 0x25
	ld iz, hl
	add iz, 0x6E
	ld l, a
	extz hl
	muls hl, 0x11F
	lda_24 xiy, 0x041368
	exts xhl
	add xhl, xiy
	ld_sril3 XHL, 0x07, 0xEC, 0xF8
	ld b, (xhl + 6)
	jr AlgoFlag_Write_Bit3_OuterMatch

AlgoFlag_Write_Bit3_InnerMatch:
	ld l, w
	extz hl
	muls hl, 0x25
	ld iz, hl
	add iz, 0x6E
	ld l, a
	extz hl
	muls hl, 0x11F
	lda_24 xiy, 0x041368
	exts xhl
	add xhl, xiy
	ld_sril3 XHL, 0x07, 0xEC, 0xF8
	ld b, (xhl + 38)
	jr AlgoFlag_Write_Bit3_OuterMatch

AlgoFlag_Write_Bit3_InnerNext:
	ld l, w
	extz hl
	muls hl, 0x25
	ld iz, hl
	add iz, 0x6E
	ld l, a
	extz hl
	muls hl, 0x11F
	lda_24 xiy, 0x041368
	exts xhl
	add xhl, xiy
	ld_sril3 XHL, 0x07, 0xEC, 0xF8
	ld b, (xhl + 56)

AlgoFlag_Write_Bit3_OuterMatch:
	bit 5, b
	jr z, AlgoFlag_Write_Bit3_OuterNext
	ld l, b
	and l, 0xC0
	srl l, 6
	cp l, e
	jr nz, AlgoFlag_Write_Bit3_OuterNext
	setm 2, (xix)

AlgoFlag_Write_Bit3_OuterNext:
	inc 1, w
	cps w, 4
	jrl c, AlgoFlag_Write_Bit3_InnerLoop

AlgoFlag_Write_Bit3_Epilogue:
	popw iz
	ret

RoutingFlag_Encode:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ld a, (xsp + 12)
	ld l, (xsp + 14)
	ldb_erp E, 0xF0
	extz ix
	ld iy, ix
	add iy, iy
	lda_24 xiz, 0x00fb56
	ld w, (xbc + 1)
	ldb_erp W, 0xF0
	extz ix
	and_sriw_rm IX, 0x07, 0xF8, 0xF4
	jrl z, RoutingFlag_Epilogue
	extz de
	add de, de
	lda_24 xix, 0x00fb5e
	ld c, (xbc + 1)
	extz bc
	and_sriw_rm BC, 0x07, 0xF0, 0xE8
	jr z, RoutingFlag_Chan2
	ld c, l
	cps c, 2
	jr z, RoutingFlag_Chan1
	cps c, 1
	jr z, RoutingFlag_Chan0
	cps c, 0
	jrl nz, RoutingFlag_Epilogue
	ld c, l
	extz bc
	add bc, bc
	add bc, 0x1A
	extz wa
	ld de, wa
	or de, 0xC0
	ld xwa, (xsp + 4)
	stw_dri DE, 0x07, 0xE0, 0xE4
	jrl RoutingFlag_Epilogue

RoutingFlag_Chan0:
	ld c, l
	extz bc
	add bc, bc
	add bc, 0x1A
	extz wa
	ld de, wa
	or de, 0xC000
	ld xwa, (xsp + 4)
	stw_dri DE, 0x07, 0xE0, 0xE4
	jr RoutingFlag_Epilogue

RoutingFlag_Chan1:
	ld c, l
	extz bc
	add bc, bc
	add bc, 0x1A
	extz wa
	ld de, wa
	or de, 0x3300
	ld xwa, (xsp + 4)
	stw_dri DE, 0x07, 0xE0, 0xE4
	jr RoutingFlag_Epilogue

RoutingFlag_Chan2:
	ld c, l
	cps c, 2
	jr z, RoutingFlag_Chan1B
	cps c, 1
	jr z, RoutingFlag_Chan0B
	cps c, 0
	jr nz, RoutingFlag_Epilogue
	ld c, l
	extz bc
	add bc, bc
	add bc, 0x1A
	extz wa
	ld de, wa
	set 6, de
	ld xwa, (xsp + 4)
	stw_dri DE, 0x07, 0xE0, 0xE4
	jr RoutingFlag_Epilogue

RoutingFlag_Chan0B:
	ld c, l
	extz bc
	add bc, bc
	add bc, 0x1A
	extz wa
	ld de, wa
	set 14, de
	ld xwa, (xsp + 4)
	stw_dri DE, 0x07, 0xE0, 0xE4
	jr RoutingFlag_Epilogue

RoutingFlag_Chan1B:
	ld c, l
	extz bc
	add bc, bc
	add bc, 0x1A
	extz wa
	ld de, wa
	or de, 0x1100
	ld xwa, (xsp + 4)
	stw_dri DE, 0x07, 0xE0, 0xE4

RoutingFlag_Epilogue:
	pop xiz
	inc 4, xsp
	retd 0x4

SlotRouting_WriteSingle:
	ld b, (xsp + 4)
	bit 5, b
	jr z, SlotRouting_Chan1PreWrite
	ld l, b
	and l, 0xC0
	srl l, 6
	cp l, e
	jr nz, SlotRouting_Chan1PreWrite
	bit 4, b
	jr z, SlotRouting_Chan0
	extz bc
	add bc, bc
	ld hl, bc
	add hl, 0x1A
	ld c, e
	extz bc
	or bc, 0xC0
	stw_dri BC, 0x07, 0xE0, 0xEC
	jr SlotRouting_Chan1PreWrite

SlotRouting_Chan0:
	extz bc
	add bc, bc
	ld hl, bc
	add hl, 0x1A
	ld c, e
	extz bc
	set 6, bc
	stw_dri BC, 0x07, 0xE0, 0xEC

SlotRouting_Chan1PreWrite:
	retd 0x2

SlotRouting_Chan1:
	ld b, (xsp + 4)
	bit 5, b
	jr z, SlotRouting_Chan3PreWrite
	ld l, b
	and l, 0xC0
	srl l, 6
	cp l, e
	jr nz, SlotRouting_Chan3PreWrite
	bit 4, b
	jr z, SlotRouting_Chan2
	extz bc
	add bc, bc
	ld hl, bc
	add hl, 0x1A
	ld c, e
	extz bc
	or bc, 0xC000
	stw_dri BC, 0x07, 0xE0, 0xEC
	jr SlotRouting_Chan3PreWrite

SlotRouting_Chan2:
	extz bc
	add bc, bc
	ld hl, bc
	add hl, 0x1A
	ld c, e
	extz bc
	set 14, bc
	stw_dri BC, 0x07, 0xE0, 0xEC

SlotRouting_Chan3PreWrite:
	retd 0x2

SlotRouting_Chan3:
	ld b, (xsp + 4)
	bit 5, b
	jr z, SlotRouting_Epilogue
	ld l, b
	and l, 0xC0
	srl l, 6
	cp l, e
	jr nz, SlotRouting_Epilogue
	bit 4, b
	jr z, SlotRouting_Chan4
	extz bc
	add bc, bc
	ld hl, bc
	add hl, 0x1A
	ld c, e
	extz bc
	or bc, 0x3300
	stw_dri BC, 0x07, 0xE0, 0xEC
	jr SlotRouting_Epilogue

SlotRouting_Chan4:
	extz bc
	add bc, bc
	ld hl, bc
	add hl, 0x1A
	ld c, e
	extz bc
	or bc, 0x1100
	stw_dri BC, 0x07, 0xE0, 0xEC

SlotRouting_Epilogue:
	retd 0x2

EFF_RoutingInit:
	lda xsp, (xsp - 10)
	pushw_erp 0xFA
	ld (xsp + 6), e
	ld (xsp + 8), c
	ld (xsp + 10), a
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xsp + 2), xwa
	ld a, (xsp + 6)
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0x1A
	ld xwa, (xsp + 2)
	stiw_ind 0x07, 0xE0, 0xE4, 0x00, 0x00
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jrl nc, EFF_RoutingInit_Epilogue

EFF_RoutingInit_LoopBody:
	stb_erp A, 0xFB
	extz wa
	ld bc, wa
	sla bc, 2
	ld a, (xsp + 6)
	extz wa
	sla wa, 4
	ld de, wa
	add de, bc
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri A, 0x07, 0xE0, 0xE8
	lda xbc, (xbc + 39)
	ld a, (xbc)
	and a, 0xA
	jr z, EFF_RoutingInit_SlotPath
	ld a, (xsp + 8)
	ld e, a
	extz de
	ld a, (xsp + 6)
	extz wa
	pushw wa
	stb_erp A, 0xFB
	extz wa
	pushw wa
	ld xwa, (xsp + 6)
	calr RoutingFlag_Encode
	jrl EFF_RoutingInit_SubLoopNext

EFF_RoutingInit_SlotPath:
	ld a, (xbc)
	and a, 0x5
	jrl z, EFF_RoutingInit_SubLoopNext
	ld a, (xsp + 6)
	cps a, 2
	jrl z, EFF_RoutingInit_SubLoop
	cps a, 1
	jr z, EFF_RoutingInit_LoopNext
	cps a, 0
	jrl nz, EFF_RoutingInit_SubLoopNext
	ld a, (xsp + 6)
	ld c, a
	extz bc
	stb_erp A, 0xFB
	ld e, a
	extz de
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x25
	ld ix, wa
	add ix, 0x6E
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xhl, 0x041368
	exts xwa
	add xwa, xhl
	ld_sril3 XWA, 0x07, 0xE0, 0xF0
	ld a, (xwa + 6)
	extz wa
	pushw wa
	ld xwa, (xsp + 4)
	calr SlotRouting_WriteSingle
	jrl EFF_RoutingInit_SubLoopNext

EFF_RoutingInit_LoopNext:
	ld a, (xsp + 6)
	ld c, a
	extz bc
	stb_erp A, 0xFB
	ld e, a
	extz de
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x25
	ld ix, wa
	add ix, 0x6E
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xhl, 0x041368
	exts xwa
	add xwa, xhl
	ld_sril3 XWA, 0x07, 0xE0, 0xF0
	ld a, (xwa + 38)
	extz wa
	pushw wa
	ld xwa, (xsp + 4)
	calr SlotRouting_Chan1
	jr EFF_RoutingInit_SubLoopNext

EFF_RoutingInit_SubLoop:
	ld a, (xsp + 6)
	ld c, a
	extz bc
	stb_erp A, 0xFB
	ld e, a
	extz de
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x25
	ld ix, wa
	add ix, 0x6E
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x11F
	lda_24 xhl, 0x041368
	exts xwa
	add xwa, xhl
	ld_sril3 XWA, 0x07, 0xE0, 0xF0
	ld a, (xwa + 56)
	extz wa
	pushw wa
	ld xwa, (xsp + 4)
	calr SlotRouting_Chan3

EFF_RoutingInit_SubLoopNext:
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jrl c, EFF_RoutingInit_LoopBody

EFF_RoutingInit_Epilogue:
	popw_erp 0xFA
	lda xsp, (xsp + 10)
	ret

AlgoType_StateWrite:
	dec 4, xsp
	ld (xsp + 2), a
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	ld a, (xwa + 93)
	and a, 0xF
	ld (xsp), a
	cp (xsp), 0x7
	jrl nz, AlgoType_StateWrite_RefreshD
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x041372
	or_sriw_im 0x07, 0xE8, 0xE0, 0x00, 0x80
	cps c, 0
	jrl nz, AlgoType_StateWrite_RefreshA
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	ldw_sri WA, 0x07, 0xE4, 0xE0
	bit 14, wa
	jr z, AlgoType_StateWrite_Type7
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413cb
	stib_ind 0x07, 0xE4, 0xE0, 0x0F
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413cc
	stib_ind 0x07, 0xE4, 0xE0, 0x4F
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413cd
	stib_ind 0x07, 0xE4, 0xE0, 0x96
	jr AlgoType_StateWrite_NonType7

AlgoType_StateWrite_Type7:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413cb
	stib_ind 0x07, 0xE4, 0xE0, 0x01
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413cc
	stib_ind 0x07, 0xE4, 0xE0, 0x01
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413cd
	stib_ind 0x07, 0xE4, 0xE0, 0x01

AlgoType_StateWrite_NonType7:
	ld a, (xsp + 2)
	extz wa
	lds bc, 0
	calr DSP_AlgoType_Dispatch1
	ld a, (xsp + 2)
	extz wa
	lds bc, 0
	calr DSP_AlgoType_Dispatch2
	ld a, (xsp + 2)
	extz wa
	lds bc, 1
	calr DSP_AlgoType_Dispatch1
	ld a, (xsp + 2)
	extz wa
	lds bc, 1
	calr DSP_AlgoType_Dispatch2
	ld a, (xsp + 2)
	extz wa
	calr DSP_ChanFreq_WritePacket1
	ld a, (xsp + 2)
	extz wa
	calr DSP_ChanFreq_WritePacket2
	jr AlgoType_StateWrite_RefreshC

AlgoType_StateWrite_RefreshA:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	ldw_sri WA, 0x07, 0xE4, 0xE0
	bit 14, wa
	jr z, AlgoType_StateWrite_RefreshB
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413cb
	and_srib_im 0x07, 0xE4, 0xE0, 0x05
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413cb
	set_dri 1, 0x07, 0xE4, 0xE0
	jr AlgoType_StateWrite_RefreshC

AlgoType_StateWrite_RefreshB:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413cb
	and_srib_im 0x07, 0xE4, 0xE0, 0x05

AlgoType_StateWrite_RefreshC:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	and_sriw_im 0x07, 0xE4, 0xE0, 0xFF, 0xFD
	jrl AlgoType_StateWrite_Epilogue

AlgoType_StateWrite_RefreshD:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	ldw_sri WA, 0x07, 0xE4, 0xE0
	bit 14, wa
	jrl z, AlgoType_StateWrite_RefreshF
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	or_sriw_im 0x07, 0xE4, 0xE0, 0x00, 0x80
	ld a, (xsp + 2)
	extz wa
	lds bc, 0
	calr DSP_AlgoType_Dispatch1
	ld a, (xsp + 2)
	extz wa
	lds bc, 0
	calr DSP_AlgoType_Dispatch2
	ld a, (xsp + 2)
	extz wa
	lds bc, 1
	calr DSP_AlgoType_Dispatch1
	ld a, (xsp + 2)
	extz wa
	lds bc, 1
	calr DSP_AlgoType_Dispatch2
	ld a, (xsp + 2)
	extz wa
	calr DSP_ChanFreq_WritePacket1
	ld a, (xsp + 2)
	extz wa
	calr DSP_ChanFreq_WritePacket2
	cp (xsp), 0xA
	jr nz, AlgoType_StateWrite_RefreshE
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	or_sriw_im 0x07, 0xE4, 0xE0, 0x00, 0x02
	jr AlgoType_StateWrite_RefreshG

AlgoType_StateWrite_RefreshE:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	and_sriw_im 0x07, 0xE4, 0xE0, 0xFF, 0xFD
	jr AlgoType_StateWrite_RefreshG

AlgoType_StateWrite_RefreshF:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	and_sriw_im 0x07, 0xE4, 0xE0, 0xFF, 0x7F
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136a
	and_sriw_im 0x07, 0xE4, 0xE0, 0xFF, 0xFD

AlgoType_StateWrite_RefreshG:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413cb
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413cc
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413cd
	stib_ind 0x07, 0xE4, 0xE0, 0x00

AlgoType_StateWrite_Epilogue:
	inc 4, xsp
	ret

DSP_AlgoType_Dispatch1:
	lds hl, 0
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XDE, 0x07, 0xF0, 0xE8
	ld e, (xde + 93)
	and e, 0xF
	ld b, e
	extz de
	cps de, 0
	jrl mi, DSP_AlgoType_Dispatch1_Store
	cp de, 0xB
	jrl gt, DSP_AlgoType_Dispatch1_Store
	add de, de
	lda_24 xix, 0x00fb66
	ldw_sri DE, 0x07, 0xF0, 0xE8
	lda_24 xix, 0x033812
	jp_ind 8, 0x07, 0xF0, 0xE8

DSP_AlgoType_Dispatch1_TableData:
	.byte 0xcb, 0x8d, 0xda, 0x12, 0xda, 0x8c, 0xdc, 0x84
	.byte 0xca, 0x8d, 0xda, 0x12, 0xda, 0x09, 0x06, 0x00
	.byte 0xf2, 0xce, 0x0f, 0x01, 0x33, 0xea, 0x13, 0xeb
	.byte 0x82, 0xc3, 0x07, 0xe8, 0xf0, 0x20, 0xc9, 0x8d
	.byte 0xda, 0x12, 0xda, 0x09, 0x1f, 0x01, 0xf2, 0x6e
	.byte 0x13, 0x04, 0x33, 0xe3, 0x07, 0xec, 0xe8, 0x22
	.byte 0x8a, 0x5e, 0x25, 0xda, 0x12, 0xda, 0x8c, 0xdc
	.byte 0x84, 0xc8, 0x8d, 0xda, 0x12, 0xda, 0x09, 0x66
	.byte 0x00, 0xf2, 0x46, 0x13, 0x01, 0x33, 0xea, 0x13
	.byte 0xeb, 0x82, 0xd3, 0x07, 0xe8, 0xf0, 0x23, 0x78
	.byte 0x1a, 0x01, 0xcb, 0x8d, 0xda, 0x12, 0xda, 0x8d
	.byte 0xdd, 0x85, 0xca, 0x8d, 0xda, 0x12, 0xda, 0x09
	.byte 0x06, 0x00, 0xf2, 0xce, 0x0f, 0x01, 0x34, 0xea
	.byte 0x13, 0xec, 0x82, 0xc3, 0x07, 0xe8, 0xf4, 0x20
	.byte 0xcb, 0xd8, 0x6e, 0x34, 0xc9, 0x8d, 0xda, 0x12
	.byte 0xda, 0x09, 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04
	.byte 0x33, 0xe3, 0x07, 0xec, 0xe8, 0x22, 0x8a, 0x5e
	.byte 0x25, 0xda, 0x12, 0xda, 0x8c, 0xdc, 0x84, 0xc8
	.byte 0x8d, 0xda, 0x12, 0xda, 0x09, 0x66, 0x00, 0xf2
	.byte 0x46, 0x13, 0x01, 0x33, 0xea, 0x13, 0xeb, 0x82
	.byte 0xd3, 0x07, 0xe8, 0xf0, 0x23, 0x78, 0xc4, 0x00
	.byte 0xcb, 0xd9, 0x7e, 0xbf, 0x00, 0xc9, 0x8d, 0xda
	.byte 0x12, 0xda, 0x09, 0x1f, 0x01, 0xf2, 0x6e, 0x13
	.byte 0x04, 0x33, 0xe3, 0x07, 0xec, 0xe8, 0x22, 0x8a
	.byte 0x60, 0x25, 0xda, 0x12, 0xda, 0x8c, 0xdc, 0x84
	.byte 0xc8, 0x8d, 0xda, 0x12, 0xda, 0x09, 0x66, 0x00
	.byte 0xf2, 0x46, 0x13, 0x01, 0x33, 0xea, 0x13, 0xeb
	.byte 0x82, 0xd3, 0x07, 0xe8, 0xf0, 0x23, 0x78, 0x8b
	.byte 0x00, 0xcb, 0x8d, 0xda, 0x12, 0xda, 0x8d, 0xdd
	.byte 0x85, 0xca, 0x8d, 0xda, 0x12, 0xda, 0x09, 0x06
	.byte 0x00, 0xf2, 0xce, 0x0f, 0x01, 0x34, 0xea, 0x13
	.byte 0xec, 0x82, 0xc3, 0x07, 0xe8, 0xf4, 0x20, 0xc8
	.byte 0xcf, 0xff, 0x66, 0x31, 0xc9, 0x8d, 0xda, 0x12
	.byte 0xda, 0x09, 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04
	.byte 0x33, 0xe3, 0x07, 0xec, 0xe8, 0x22, 0x8a, 0x60
	.byte 0x25, 0xda, 0x12, 0xda, 0x8c, 0xdc, 0x84, 0xc8
	.byte 0x8d, 0xda, 0x12, 0xda, 0x09, 0x66, 0x00, 0xf2
	.byte 0x46, 0x13, 0x01, 0x33, 0xea, 0x13, 0xeb, 0x82
	.byte 0xd3, 0x07, 0xe8, 0xf0, 0x23, 0xcb, 0x8d, 0xda
	.byte 0x12, 0xda, 0x09, 0x03, 0x00, 0xda, 0x8d, 0xca
	.byte 0x8d, 0xda, 0x12, 0xda, 0x09, 0x27, 0x00, 0xf2
	.byte 0x16, 0x1e, 0x01, 0x34, 0xea, 0x13, 0xec, 0x82
	.byte 0xf3, 0x07, 0xe8, 0xf4, 0x32, 0x8a, 0x02, 0x25
	.byte 0xcd, 0xcc, 0xc0, 0xcd, 0xef, 0x06, 0xda, 0x12
	.byte 0xda, 0x82, 0xf2, 0x11, 0x15, 0x01, 0x34, 0xd3
	.byte 0x07, 0xf0, 0xe8, 0xe3

DSP_AlgoType_Dispatch1_Store:
	extz bc
	sla bc, 2
	ld de, bc
	add de, 0x57
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stw_dri HL, 0x07, 0xE0, 0xE8
	ret

DSP_AlgoType_Dispatch2:
	lds hl, 0
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XDE, 0x07, 0xF0, 0xE8
	ld e, (xde + 93)
	and e, 0xF
	ld b, e
	extz de
	cps de, 0
	jrl mi, DSP_AlgoType_Dispatch2_Store
	cp de, 0xB
	jrl gt, DSP_AlgoType_Dispatch2_Store
	add de, de
	lda_24 xix, 0x00fb7e
	ldw_sri DE, 0x07, 0xF0, 0xE8
	lda_24 xix, 0x0339de
	jp_ind 8, 0x07, 0xF0, 0xE8

DSP_AlgoType_Dispatch2_TableData:
	.byte 0xcb, 0x8d, 0xda, 0x12, 0xda, 0x8c, 0xdc, 0x84
	.byte 0xca, 0x8d, 0xda, 0x12, 0xda, 0x09, 0x06, 0x00
	.byte 0xf2, 0xce, 0x0f, 0x01, 0x33, 0xea, 0x13, 0xeb
	.byte 0x82, 0xf3, 0x07, 0xe8, 0xf0, 0x32, 0x8a, 0x01
	.byte 0x20, 0xc9, 0x8d, 0xda, 0x12, 0xda, 0x09, 0x1f
	.byte 0x01, 0xf2, 0x6e, 0x13, 0x04, 0x33, 0xe3, 0x07
	.byte 0xec, 0xe8, 0x22, 0x8a, 0x5f, 0x25, 0xda, 0x12
	.byte 0xda, 0x8c, 0xdc, 0x84, 0xc8, 0x8d, 0xda, 0x12
	.byte 0xda, 0x09, 0x66, 0x00, 0xf2, 0x16, 0x10, 0x01
	.byte 0x33, 0xea, 0x13, 0xeb, 0x82, 0xd3, 0x07, 0xe8
	.byte 0xf0, 0x23, 0x78, 0xf6, 0x00, 0xcb, 0x8d, 0xda
	.byte 0x12, 0xda, 0x8d, 0xdd, 0x85, 0xca, 0x8d, 0xda
	.byte 0x12, 0xda, 0x09, 0x06, 0x00, 0xf2, 0xce, 0x0f
	.byte 0x01, 0x34, 0xea, 0x13, 0xec, 0x82, 0xf3, 0x07
	.byte 0xe8, 0xf4, 0x32, 0x8a, 0x01, 0x20, 0xcb, 0xd8
	.byte 0x6e, 0x34, 0xc9, 0x8d, 0xda, 0x12, 0xda, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04, 0x33, 0xe3
	.byte 0x07, 0xec, 0xe8, 0x22, 0x8a, 0x5f, 0x25, 0xda
	.byte 0x12, 0xda, 0x8c, 0xdc, 0x84, 0xc8, 0x8d, 0xda
	.byte 0x12, 0xda, 0x09, 0x66, 0x00, 0xf2, 0x16, 0x10
	.byte 0x01, 0x33, 0xea, 0x13, 0xeb, 0x82, 0xd3, 0x07
	.byte 0xe8, 0xf0, 0x23, 0x78, 0x9d, 0x00, 0xcb, 0xd9
	.byte 0x7e, 0x98, 0x00, 0xc9, 0x8d, 0xda, 0x12, 0xda
	.byte 0x09, 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04, 0x33
	.byte 0xe3, 0x07, 0xec, 0xe8, 0x22, 0x8a, 0x61, 0x25
	.byte 0xda, 0x12, 0xda, 0x8c, 0xdc, 0x84, 0xc8, 0x8d
	.byte 0xda, 0x12, 0xda, 0x09, 0x66, 0x00, 0xf2, 0x16
	.byte 0x10, 0x01, 0x33, 0xea, 0x13, 0xeb, 0x82, 0xd3
	.byte 0x07, 0xe8, 0xf0, 0x23, 0x68, 0x65, 0xcb, 0x8d
	.byte 0xda, 0x12, 0xda, 0x8d, 0xdd, 0x85, 0xca, 0x8d
	.byte 0xda, 0x12, 0xda, 0x09, 0x06, 0x00, 0xf2, 0xce
	.byte 0x0f, 0x01, 0x34, 0xea, 0x13, 0xec, 0x82, 0xf3
	.byte 0x07, 0xe8, 0xf4, 0x32, 0x8a, 0x01, 0x20, 0xc8
	.byte 0xcf, 0xff, 0x66, 0x3f, 0xcb, 0x8d, 0xda, 0x12
	.byte 0xda, 0x09, 0x03, 0x00, 0xda, 0x8c, 0xca, 0x8d
	.byte 0xda, 0x12, 0xda, 0x09, 0x27, 0x00, 0xf2, 0x16
	.byte 0x1e, 0x01, 0x33, 0xea, 0x13, 0xeb, 0x82, 0xf3
	.byte 0x07, 0xe8, 0xf0, 0x32, 0x8a, 0x01, 0x25, 0xda
	.byte 0x12, 0xda, 0x8c, 0xdc, 0x84, 0xc8, 0x8d, 0xda
	.byte 0x12, 0xda, 0x09, 0x66, 0x00, 0xf2, 0x16, 0x10
	.byte 0x01, 0x33, 0xea, 0x13, 0xeb, 0x82, 0xd3, 0x07
	.byte 0xe8, 0xf0, 0x23

DSP_AlgoType_Dispatch2_Store:
	extz bc
	sla bc, 2
	ld de, bc
	add de, 0x57
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xwa + 2), hl
	ret

AlgoType_AB_Checker:
	lds hl, 0
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XBC, 0x07, 0xE8, 0xE4
	ld c, (xbc + 93)
	and c, 0xF
	cp c, 0xB
	jr z, AlgoType_AB_LoadIndex
	cp c, 0xA
	ret nz

AlgoType_AB_LoadIndex:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 95)
	and a, 0x3F
	ld l, a
	extz hl
	ret

DSP_ChanFreq_WritePacket1:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XBC, 0x07, 0xE8, 0xE4
	ld c, (xbc + 93)
	and c, 0xF
	ld l, c
	cps c, 7
	jr z, DSP_ChanFreq_WritePacket1_Algo7
	cps c, 6
	jrl nz, DSP_ChanFreq_WritePacket1_Zero
	ld c, l
	extz bc
	muls bc, 0x6
	lda_24 xde, 0x010fd2
	ldb_sri W, 0x07, 0xE8, 0xE4
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XBC, 0x07, 0xE8, 0xE4
	ld c, (xbc + 94)
	extz bc
	ld hl, bc
	add hl, hl
	ld c, w
	extz bc
	muls bc, 0x66
	lda_24 xde, 0x011478
	exts xbc
	add xbc, xde
	ldw_sri HL, 0x07, 0xE4, 0xEC
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XBC, 0x07, 0xE8, 0xE4
	ld c, (xbc + 96)
	extz bc
	add bc, bc
	lda_24 xde, 0x011511
	or_sriw_rm HL, 0x07, 0xE8, 0xE4
	jr DSP_ChanFreq_WritePacket1_Epilogue

DSP_ChanFreq_WritePacket1_Algo7:
	ld c, l
	extz bc
	muls bc, 0x6
	lda_24 xde, 0x010fd2
	ldb_sri W, 0x07, 0xE8, 0xE4
	ld c, l
	extz bc
	muls bc, 0x27
	lda_24 xde, 0x011e1c
	ldb_sri C, 0x07, 0xE8, 0xE4
	extz bc
	ld hl, bc
	add hl, hl
	ld c, w
	extz bc
	muls bc, 0x66
	lda_24 xde, 0x011478
	exts xbc
	add xbc, xde
	ldw_sri HL, 0x07, 0xE4, 0xEC
	jr DSP_ChanFreq_WritePacket1_Epilogue

DSP_ChanFreq_WritePacket1_Zero:
	lds hl, 0

DSP_ChanFreq_WritePacket1_Epilogue:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413c7
	stw_dri HL, 0x07, 0xE4, 0xE0
	ret

DSP_ChanFreq_WritePacket2:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XBC, 0x07, 0xE8, 0xE4
	ld c, (xbc + 93)
	and c, 0xF
	ld e, c
	cps c, 7
	jr z, DSP_ChanFreq_WritePacket2_PathA
	cps c, 6
	jr nz, DSP_ChanFreq_WritePacket2_PathB

DSP_ChanFreq_WritePacket2_PathA:
	ld c, e
	extz bc
	muls bc, 0x6
	lda_24 xde, 0x010fd3
	ldb_sri W, 0x07, 0xE8, 0xE4
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XBC, 0x07, 0xE8, 0xE4
	ld c, (xbc + 95)
	extz bc
	ld hl, bc
	add hl, hl
	ld c, w
	extz bc
	muls bc, 0x66
	lda_24 xde, 0x011016
	exts xbc
	add xbc, xde
	ldw_sri HL, 0x07, 0xE4, 0xEC
	jr DSP_ChanFreq_WritePacket2_Epilogue

DSP_ChanFreq_WritePacket2_PathB:
	lds hl, 0

DSP_ChanFreq_WritePacket2_Epilogue:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413c9
	stw_dri HL, 0x07, 0xE4, 0xE0
	ret

Voice_SecondaryParam_Fetch:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041372
	ldw_sri BC, 0x07, 0xE8, 0xE4
	extz xbc
	bit 15, bc
	jr z, Voice_SecondaryParam_FallbackB
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XBC, 0x07, 0xE8, 0xE4
	ld c, (xbc + 93)
	and c, 0xF
	cp c, 0x9
	jr nz, Voice_SecondaryParam_FallbackA
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 94)
	extz wa
	lda_24 xbc, 0x012038
	ldb_sri L, 0x07, 0xE4, 0xE0
	jr Voice_SecondaryParam_FallbackC

Voice_SecondaryParam_FallbackA:
	ldb l, 0xFF
	jr Voice_SecondaryParam_FallbackC

Voice_SecondaryParam_FallbackB:
	ldb l, 0xFF

Voice_SecondaryParam_FallbackC:
	ret

Voice_SecondaryParam_Fetch2:
	ldb l, 0x0
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041372
	ldw_sri BC, 0x07, 0xE8, 0xE4
	extz xbc
	bit 15, bc
	ret z
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XBC, 0x07, 0xE8, 0xE4
	ld c, (xbc + 93)
	and c, 0xF
	ld l, c
	cp c, 0xB
	jr z, Voice_SecondaryParam_AlgoAB
	cp c, 0xA
	jr nz, Voice_SecondaryParam_Path3

Voice_SecondaryParam_AlgoAB:
	ld c, l
	extz bc
	muls bc, 0x27
	lda_24 xde, 0x011e23
	bit_dri 7, 0x07, 0xE8, 0xE4
	jr z, Voice_SecondaryParam_Path2
	ld a, l
	extz wa
	muls wa, 0x27
	lda_24 xbc, 0x011e24
	ldb_sri L, 0x07, 0xE4, 0xE0
	jr Voice_SecondaryParam_Path4

Voice_SecondaryParam_Path2:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld l, (xwa + 100)
	jr Voice_SecondaryParam_Path4

Voice_SecondaryParam_Path3:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld l, (xwa + 100)

Voice_SecondaryParam_Path4:
	ret

Voice_SecondaryParam_Epilogue:
	ldb l, 0x0
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041372
	ldw_sri BC, 0x07, 0xE8, 0xE4
	extz xbc
	bit 15, bc
	ret z
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld l, (xwa + 101)
	ret

DSP_AlgoType_Dispatch3:
	lds hl, 0
	ldb_erp A, 0xF0
	extz ix
	muls ix, 0x11F
	lda_24 xiy, 0x04136e
	ld_sril3 XIX, 0x07, 0xF4, 0xF0
	ld w, (xix + 93)
	and w, 0xF
	ld b, w
	ldb_erp W, 0xF4
	extz iy
	cps iy, 0
	ret mi
	cp iy, 0xB
	ret gt
	add iy, iy
	lda_24 xix, 0x00fb96
	ldw_sri IY, 0x07, 0xF0, 0xF4
	lda_24 xix, 0x033e44
	jp_ind 8, 0x07, 0xF0, 0xF4

DSP_AlgoType_Dispatch3_TableData:
	cps	e, 0
	jr	nz, 115
	ld	e, c
	extz	de
	muls	de, 5
	ld	iy, de
	add	iy, 19
	ld	e, b
	extz	de
	muls	de, 39
	lda_24	xix, 73238
	exts	xde
	add	xde, xix
	.byte 0xf3, 0x07, 0xe8, 0xf4, 0xcf
	ret	z
	extz	wa
	muls	wa, 287
	lda_24	xde, 267118
	ld_rrl	xwa, xde, wa
	bitm	6, (xwa+93)
	jr	z, 50
	ld	a, c
	extz	wa
	muls	wa, 5
	ld	de, wa
	add	de, 19
	ld	a, b
	extz	wa
	muls	wa, 39
	lda_24	xbc, 73238
	exts	xwa
	add	xwa, xbc
	.byte 0xf3, 0x07, 0xe0, 0xe8, 0xcb, 0x66, 0x06
	ldw	hl, 192
	jrl	t, 196
	ldw	hl, 64
	jrl	t, 190
	ldw	hl, 64
	jrl	t, 184
	ld	e, c
	extz	de
	muls	de, 5
	ld	iy, de
	add	iy, 19
	ld	e, b
	extz	de
	muls	de, 39
	lda_24	xix, 73238
	exts	xde
	add	xde, xix
	.byte 0xf3, 0x07, 0xe8, 0xf4, 0xce
	ret	z
	extz	wa
	muls	wa, 287
	lda_24	xde, 267118
	ld_rrl	xwa, xde, wa
	bitm	6, (xwa+93)
	jr	z, 48
	ld	a, c
	extz	wa
	muls	wa, 5
	ld	de, wa
	add	de, 19
	ld	a, b
	extz	wa
	muls	wa, 39
	lda_24	xbc, 73238
	exts	xwa
	add	xwa, xbc
	.byte 0xf3, 0x07, 0xe0, 0xe8, 0xca, 0x66, 0x05
	ldw	hl, 0x00c0
	.asciz "hR3@"
	.asciz "hM3@"
	.byte 0x68, 0x48, 0xcd
	.byte 0xd8, 0xb0, 0xfe, 0xd8, 0x12, 0xd8, 0x09, 0x1f
	.byte 0x01, 0xf2, 0x6e, 0x13, 0x04, 0x32, 0xe3, 0x07
	.byte 0xe8, 0xe0, 0x20, 0x88, 0x5e, 0x3f, 0x00, 0xb0
	.byte 0xf6, 0xcb, 0x89, 0xd8, 0x12, 0xd8, 0x09, 0x05
	.byte 0x00, 0xd8, 0x8a, 0xda, 0xc8, 0x13, 0x00, 0xca
	.byte 0x89, 0xd8, 0x12, 0xd8, 0x09, 0x27, 0x00, 0xf2
	.byte 0x16, 0x1e, 0x01, 0x31, 0xe8, 0x13, 0xe9, 0x80
	.byte 0xf3, 0x07, 0xe0, 0xe8, 0xcb, 0x66, 0x05, 0x33
	.byte 0xc0, 0x00, 0x68, 0x03, 0x33, 0x40, 0x00, 0x0e

Algo67_LUTOffset_Check:
	lds hl, 0
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XDE, 0x07, 0xF0, 0xE8
	ld e, (xde + 93)
	and e, 0xF
	ld b, e
	cps e, 7
	jr z, Algo67_LUTOffset_Read
	cps e, 6
	ret nz

Algo67_LUTOffset_Read:
	ld e, c
	extz de
	muls de, 0x5
	ld iy, de
	add iy, 0x13
	ld e, b
	extz de
	muls de, 0x27
	lda_24 xix, 0x011e16
	exts xde
	add xde, xix
	bit_dri 5, 0x07, 0xE8, 0xF4
	ret z
	extz wa
	muls wa, 0x11F
	lda_24 xde, 0x04136e
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	bitm 6, (xwa + 93)
	jr z, Algo_SubTable_Flag8000
	ld a, c
	extz wa
	muls wa, 0x5
	ld de, wa
	add de, 0x13
	ld a, b
	extz wa
	muls wa, 0x27
	lda_24 xbc, 0x011e16
	exts xwa
	add xwa, xbc
	bit_dri 1, 0x07, 0xE0, 0xE8
	jr z, Algo67_LUTOffset_Flag4000
	ldw hl, 0xC000
	jr Algo_SubTable_FlagC000

Algo67_LUTOffset_Flag4000:
	ldw hl, 0x4000
	jr Algo_SubTable_FlagC000

Algo_SubTable_Flag8000:
	ldw hl, 0x4000

Algo_SubTable_FlagC000:
	ret

Algo_SubTable_DispatchA:
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xhl, 0x04136e
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	ld e, (xde + 93)
	and e, 0xF
	ld w, e
	ld e, c
	extz de
	muls de, 0x5
	ld ix, de
	add ix, 0x13
	ld e, w
	extz de
	muls de, 0x27
	lda_24 xhl, 0x011e16
	exts xde
	add xde, xhl
	stb_dri B, 0x07, 0xE8, 0xF0
	ld l, (xde + 1)
	ld e, w
	cp e, 0x8
	ret nz
	cps c, 1
	ret nz
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld l, (xwa + 96)
	ret

Algo_SubTable_DispatchB:
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xhl, 0x04136e
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	ld e, (xde + 93)
	and e, 0xF
	ld w, e
	ld e, c
	extz de
	muls de, 0x5
	ld ix, de
	add ix, 0x13
	ld e, w
	extz de
	muls de, 0x27
	lda_24 xhl, 0x011e16
	exts xde
	add xde, xhl
	stb_dri B, 0x07, 0xE8, 0xF0
	ld l, (xde + 2)
	ld e, w
	extz de
	cps de, 0
	ret mi
	cp de, 0x8
	ret gt
	add de, de
	lda_24 xix, 0x00fbae
	ldw_sri DE, 0x07, 0xF0, 0xE8
	lda_24 xix, 0x0340cc
	jp_ind 8, 0x07, 0xF0, 0xE8

Algo_SubTable_JumpTable1:
	.byte 0xcb, 0xd9, 0xb0, 0xfe, 0xd8, 0x12, 0xd8, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04, 0x31, 0xe3
	.byte 0x07, 0xe4, 0xe0, 0x20, 0x88, 0x60, 0x21, 0xc9
	.byte 0x8f, 0xc9, 0x87, 0x68, 0x38, 0xcb, 0xd9, 0xb0
	.byte 0xfe, 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2
	.byte 0x6e, 0x13, 0x04, 0x31, 0xe3, 0x07, 0xe4, 0xe0
	.byte 0x20, 0x88, 0x62, 0x21, 0xc9, 0x8f, 0xc9, 0x87
	.byte 0x68, 0x1b, 0xcb, 0xd9, 0xb0, 0xfe, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04
	.byte 0x31, 0xe3, 0x07, 0xe4, 0xe0, 0x20, 0x88, 0x5f
	.byte 0x21, 0xc9, 0x8f, 0xc9, 0x87, 0x0e, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x6a, 0x13, 0x04
	.byte 0x32, 0xd3, 0x07, 0xe8, 0xe0, 0x20, 0xe8, 0x12
	.byte 0xe8, 0xcc, 0x00, 0xc0, 0x00, 0x00, 0x66, 0x14
	.byte 0xcb, 0xd9, 0x66, 0x08, 0xcb, 0xd8, 0x6e, 0x08
	.byte 0x27, 0xfc, 0x68, 0x0a, 0x27, 0xf0, 0x68, 0x06
	.byte 0x27, 0x00, 0x68, 0x02, 0x27, 0x00, 0x0e

Algo_SubTable_DispatchC:
	pushw_erp 0xFA
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xhl, 0x04136e
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	ld e, (xde + 93)
	and e, 0xF
	ld w, e
	ld e, c
	extz de
	muls de, 0x5
	ld ix, de
	add ix, 0x13
	ld e, w
	extz de
	muls de, 0x27
	lda_24 xhl, 0x011e16
	exts xde
	add xde, xhl
	stb_dri B, 0x07, 0xE8, 0xF0
	ld e, (xde + 3)
	ldb_erp E, 0xFB
	ld e, w
	extz de
	cps de, 0
	jr mi, Algo_SubTable_Epilogue
	cp de, 0x8
	jr gt, Algo_SubTable_Epilogue
	add de, de
	lda_24 xix, 0x00fbc0
	ldw_sri DE, 0x07, 0xF0, 0xE8
	lda_24 xix, 0x0341be
	jp_ind 8, 0x07, 0xF0, 0xE8

Algo_SubTable_JumpTable2:
	.byte 0xcb, 0xd9, 0x6e, 0x1b, 0xc9, 0x8d, 0xda, 0x12
	.byte 0xda, 0x09, 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04
	.byte 0x33, 0xe3, 0x07, 0xec, 0xe8, 0x22, 0x8a, 0x62
	.byte 0x25, 0xcd, 0xca, 0x64, 0xc7, 0xfb, 0x9d, 0xd8
	.byte 0x12, 0xd9, 0x12, 0x1e, 0x3e, 0xff, 0xc7, 0xfb
	.byte 0x89, 0xcf, 0x81, 0xc7, 0xfb, 0x99, 0x68, 0x29
	.byte 0xd8, 0x12, 0xd9, 0x12, 0x1e, 0x2d, 0xff, 0xc7
	.byte 0xfb, 0x9f, 0x68, 0x1d, 0xcb, 0xd9, 0x6e, 0x19
	.byte 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x6e
	.byte 0x13, 0x04, 0x31, 0xe3, 0x07, 0xe4, 0xe0, 0x20
	.byte 0x88, 0x61, 0x21, 0xc9, 0xca, 0x64, 0xc7, 0xfb
	.byte 0x99

Algo_SubTable_Epilogue:
	stb_erp L, 0xFB
	popw_erp 0xFA
	ret

Algo_SubTable_Bit15Dispatch:
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xhl, 0x041372
	ldw_sri DE, 0x07, 0xEC, 0xE8
	extz xde
	bit 15, de
	jrl z, Algo_SubTable_ZeroReturn
	ld e, a
	extz de
	muls de, 0x11F
	lda_24 xhl, 0x04136e
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	ld e, (xde + 93)
	and e, 0xF
	ld w, e
	ld e, c
	extz de
	muls de, 0x5
	ld ix, de
	add ix, 0x13
	ld e, w
	extz de
	muls de, 0x27
	lda_24 xhl, 0x011e16
	exts xde
	add xde, xhl
	stb_dri B, 0x07, 0xE8, 0xF0
	ld l, (xde + 4)
	ld e, w
	extz de
	cps de, 0
	ret mi
	cp de, 0x8
	ret gt
	add de, de
	lda_24 xix, 0x00fbd2
	ldw_sri DE, 0x07, 0xF0, 0xE8
	lda_24 xix, 0x03429d
	jp_ind 8, 0x07, 0xF0, 0xE8

Algo_SubTable_JumpTable3:
	.byte 0xcb, 0xd9, 0xb0, 0xfe, 0xd8, 0x12, 0xd8, 0x09
	.byte 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04, 0x31, 0xe3
	.byte 0x07, 0xe4, 0xe0, 0x20, 0x88, 0x61, 0x21, 0xd8
	.byte 0x12, 0xf2, 0xde, 0x14, 0x01, 0x31, 0xc3, 0x07
	.byte 0xe4, 0xe0, 0x27, 0x68, 0x4c, 0xcb, 0xd9, 0xb0
	.byte 0xfe, 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2
	.byte 0x6e, 0x13, 0x04, 0x31, 0xe3, 0x07, 0xe4, 0xe0
	.byte 0x20, 0x88, 0x63, 0x21, 0xd8, 0x12, 0xf2, 0xde
	.byte 0x14, 0x01, 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x27
	.byte 0x68, 0x27, 0xcb, 0xd9, 0xb0, 0xfe, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x6e, 0x13, 0x04
	.byte 0x31, 0xe3, 0x07, 0xe4, 0xe0, 0x20, 0x88, 0x5e
	.byte 0x21, 0xd8, 0x12, 0xf2, 0xde, 0x14, 0x01, 0x31
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x27, 0x68, 0x02

Algo_SubTable_ZeroReturn:
	ldb l, 0x0
	ret

VoiceNoteParam_UpdateLoop:
	dec 2, xsp
	pushw_erp 0xFA
	ld (xsp + 2), a
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	ldw_sri WA, 0x07, 0xE4, 0xE0
	extz xwa
	bit 15, wa
	jrl z, VoiceNoteParam_FallbackPath
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jrl nc, VoiceNoteParam_Epilogue

VoiceNoteParam_LoopBody:
	ld a, (xsp + 2)
	ld e, a
	extz de
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld wa, de
	calr Algo_SubTable_DispatchA
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xwa + 32), l
	ld a, (xsp + 2)
	ld e, a
	extz de
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld wa, de
	calr Algo_SubTable_DispatchB
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xwa + 33), l
	ld a, (xsp + 2)
	ld e, a
	extz de
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld wa, de
	calr Algo_SubTable_DispatchC
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xwa + 34), l
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jrl c, VoiceNoteParam_LoopBody
	jrl VoiceNoteParam_Epilogue

VoiceNoteParam_FallbackPath:
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jrl nc, VoiceNoteParam_Epilogue

VoiceNoteParam_LoopNext:
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xwa + 32), 0x0
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xwa + 33), 0x0
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x25
	ld de, wa
	add de, 0x6E
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	stb_dri W, 0x07, 0xE0, 0xE8
	ld (xwa + 34), 0x0
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jrl c, VoiceNoteParam_LoopNext

VoiceNoteParam_Epilogue:
	popw_erp 0xFA
	inc 2, xsp
	ret

Voice_ActiveFlag_CheckAndLoad:
	dec 4, xsp
	ld (xsp + 2), a
	ld (xsp), 0x0
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	ldw_sri WA, 0x07, 0xE4, 0xE0
	bit 0, wa
	jr z, Voice_ActiveFlag_ActivePath
	ldb_da a, 0x0451a4
	cp a, (xsp + 2)
	jr nz, Voice_ActiveFlag_ActivePath
	ldb_da a, 0x0451a6
	sla a, 2
	ld (xsp), a

Voice_ActiveFlag_ActivePath:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	ldw_sri WA, 0x07, 0xE4, 0xE0
	extz xwa
	bit 15, wa
	jr z, Voice_ActiveFlag_InactivePath
	ld a, (xsp + 2)
	extz wa
	calr Voice_SecondaryParam_Fetch2
	add (xsp), l

Voice_ActiveFlag_InactivePath:
	ld a, (xsp + 2)
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xde, 0x0413cf
	ld a, (xsp)
	lda_dri XBC, 0x07, 0xE8, 0xE4
	inc 4, xsp
	ret

Voice_ProgChange_TableData:
	.byte 0xef, 0x6a, 0x2e, 0xbf, 0x02, 0x41, 0xc2, 0xa7
	.byte 0x51, 0x04, 0x3f, 0xf5, 0x66, 0x7f, 0xde, 0xa8
	.byte 0xde, 0xdc, 0x6f, 0x5f, 0xde, 0x88, 0xe8, 0x12
	.byte 0x41, 0x25, 0x00, 0x00, 0x00, 0x1d, 0xca, 0xd8
	.byte 0x03, 0xeb, 0xc8, 0x6e, 0x00, 0x00, 0x00, 0x8f
	.byte 0x02, 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01
	.byte 0xf2, 0x68, 0x13, 0x04, 0x31, 0xe8, 0x13, 0xe9
	.byte 0x80, 0xeb, 0x80, 0xa0, 0x20, 0x88, 0x06, 0x3c
	.byte 0x07, 0xde, 0x88, 0xe8, 0x12, 0x41, 0x25, 0x00
	.byte 0x00, 0x00, 0x1d, 0xca, 0xd8, 0x03, 0xeb, 0xc8
	.byte 0x6e, 0x00, 0x00, 0x00, 0x8f, 0x02, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x68, 0x13
	.byte 0x04, 0x31, 0xe8, 0x13, 0xe9, 0x80, 0xeb, 0x80
	.byte 0xa0, 0x20, 0xb8, 0x06, 0xbd, 0xde, 0x61, 0xde
	.byte 0xdc, 0x67, 0xa1, 0x8f, 0x02, 0x21, 0xd8, 0x12
	.byte 0xd9, 0xa8, 0xda, 0xa8, 0x1e, 0x53, 0xeb, 0x8f
	.byte 0x02, 0x21, 0xd8, 0x12, 0xd9, 0xa8, 0xda, 0xa8
	.byte 0x1e, 0x47, 0xea, 0x68, 0x51, 0xde, 0xa8, 0xde
	.byte 0xdc, 0x6f, 0x33, 0xde, 0x88, 0xe8, 0x12, 0x41
	.byte 0x25, 0x00, 0x00, 0x00, 0x1d, 0xca, 0xd8, 0x03
	.byte 0xeb, 0xc8, 0x6e, 0x00, 0x00, 0x00, 0x8f, 0x02
	.byte 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x1f, 0x01, 0xf2
	.byte 0x68, 0x13, 0x04, 0x31, 0xe8, 0x13, 0xe9, 0x80
	.byte 0xeb, 0x80, 0xa0, 0x20, 0x88, 0x06, 0x3c, 0x07
	.byte 0xde, 0x61, 0xde, 0xdc, 0x67, 0xcd, 0x8f, 0x02
	.byte 0x21, 0xd8, 0x12, 0xd9, 0xa8, 0xda, 0xa8, 0x1e
	.byte 0x00, 0xeb, 0x8f, 0x02, 0x21, 0xd8, 0x12, 0xd9
	.byte 0xa8, 0xda, 0xa8, 0x1e, 0xf4, 0xe9, 0xde, 0xa8
	.byte 0xde, 0xdc, 0x6f, 0x1b, 0x8f, 0x02, 0x21, 0xc9
	.byte 0x8d, 0xda, 0x12, 0xc7, 0xf8, 0x89, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xda, 0x88, 0xda, 0xa8, 0x1e, 0xc2
	.byte 0xed, 0xde, 0x61, 0xde, 0xdc, 0x67, 0xe5, 0x4e
	.byte 0xef, 0x62, 0x0e

DSP_SlotParam_Write_Slot0:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041368
	ldw_sri BC, 0x07, 0xE8, 0xE4
	bit 0, bc
	jr z, DSP_SlotParam_Write_Slot0_Path
	cpdm8_24 283044, a
	jr nz, DSP_SlotParam_Write_Slot0_Path
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xde, 0x0413d0
	ldb_da a, 0x0451a7
	sla a, 1
	lda_dri XBC, 0x07, 0xE8, 0xE4
	ret

DSP_SlotParam_Write_Slot0_Path:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413d0
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	ret

DSP_SlotParam_Write_Slot1:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041368
	ldw_sri BC, 0x07, 0xE8, 0xE4
	bit 0, bc
	jr z, DSP_SlotParam_Write_Slot1_Path
	cpdm8_24 283044, a
	jr nz, DSP_SlotParam_Write_Slot1_Path
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xde, 0x0413d1
	ldb_da a, 0x0451a8
	sla a, 1
	lda_dri XBC, 0x07, 0xE8, 0xE4
	ret

DSP_SlotParam_Write_Slot1_Path:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413d1
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	ret

DSP_SlotParam_Write_Slot2:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041368
	ldw_sri BC, 0x07, 0xE8, 0xE4
	bit 0, bc
	jr z, DSP_SlotParam_Write_Slot2_Path
	cpdm8_24 283044, a
	jr nz, DSP_SlotParam_Write_Slot2_Path
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xde, 0x0413d2
	ldb_da a, 0x0451a9
	sla a, 1
	lda_dri XBC, 0x07, 0xE8, 0xE4
	ret

DSP_SlotParam_Write_Slot2_Path:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413d2
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	ret

DSP_SlotParam_Write_Slot3:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041368
	ldw_sri BC, 0x07, 0xE8, 0xE4
	bit 0, bc
	jr z, DSP_SlotParam_Write_Slot3_Path
	cpdm8_24 283044, a
	jr nz, DSP_SlotParam_Write_Slot3_Path
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xde, 0x0413d3
	ldb_da a, 0x0451ab
	sla a, 2
	lda_dri XBC, 0x07, 0xE8, 0xE4
	ret

DSP_SlotParam_Write_Slot3_Path:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413d3
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	ret

DSP_SlotParam_Write_Slot4:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041368
	ldw_sri BC, 0x07, 0xE8, 0xE4
	bit 0, bc
	jr z, DSP_SlotParam_Write_Slot4_Path
	cpdm8_24 283044, a
	jr nz, DSP_SlotParam_Write_Slot4_Path
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xde, 0x0413d4
	ldb_da a, 0x0451ac
	sla a, 2
	lda_dri XBC, 0x07, 0xE8, 0xE4
	ret

DSP_SlotParam_Write_Slot4_Path:
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x0413d4
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	ret

Voice_ActiveFlag_Set:
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041368
	and_sriw_im 0x07, 0xE8, 0xE4, 0xFC, 0xFF
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041368
	or_sriw_im 0x07, 0xE8, 0xE4, 0x04, 0x00
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136c
	stib_ind 0x07, 0xE4, 0xE0, 0x00
	ret

Voice_NoteState_Clear:
	ldw_da xbc, 0x041343
	bit 0, bc
	ret nz
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041385
	stiw_ind 0x07, 0xE8, 0xE4, 0x00, 0x00
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041387
	stib_ind 0x07, 0xE8, 0xE4, 0x00
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041388
	stib_ind 0x07, 0xE8, 0xE4, 0x00
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041383
	stib_ind 0x07, 0xE8, 0xE4, 0x40
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041384
	stib_ind 0x07, 0xE8, 0xE4, 0x40
	lds ix, 0
	cps ix, 4
	ret nc

Voice_NoteState_InnerLoopA:
	lds hl, 0
	cps hl, 3
	jr nc, Voice_NoteState_Epilogue

Voice_NoteState_InnerLoopB:
	ld bc, ix
	extz xbc
	ld xde, xbc
	sll xde, 2
	ld bc, hl
	extz xbc
	sll xbc, 4
	ld xiy, xbc
	add xiy, xde
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041368
	exts xbc
	add xbc, xde
	add xbc, xiy
	ld (xbc + 41), 0x0
	ld bc, ix
	extz xbc
	ld xde, xbc
	sll xde, 2
	ld bc, hl
	extz xbc
	sll xbc, 4
	ld xiy, xbc
	add xiy, xde
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xde, 0x041368
	exts xbc
	add xbc, xde
	add xbc, xiy
	ld (xbc + 42), 0x0
	inc 1, hl
	cps hl, 3
	jr c, Voice_NoteState_InnerLoopB

Voice_NoteState_Epilogue:
	inc 1, ix
	cps ix, 4
	jr c, Voice_NoteState_InnerLoopA
	ret

VoiceSlot_FullInit:
	dec 4, xsp
	pushw iz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	lds bc, 0
	calr AlgoType_StateWrite
	ld a, (xsp + 4)
	extz wa
	calr Voice_ActiveFlag_CheckAndLoad
	ld a, (xsp + 4)
	extz wa
	calr DSP_SlotParam_Write_Slot0
	ld a, (xsp + 4)
	extz wa
	calr DSP_SlotParam_Write_Slot1
	ld a, (xsp + 4)
	extz wa
	calr DSP_SlotParam_Write_Slot2
	ld a, (xsp + 4)
	extz wa
	calr DSP_SlotParam_Write_Slot3
	ld a, (xsp + 4)
	extz wa
	calr DSP_SlotParam_Write_Slot4
	ld a, (xsp + 4)
	extz wa
	calr VoiceFlags_Aggregate
	ld a, (xsp + 4)
	extz wa
	calr EnvTranspose_UpdateLoop
	ldw (xsp + 2), 0x0
	cpw (xsp + 2), 0x3
	jr nc, VoiceSlot_FullInit_Epilogue

VoiceSlot_FullInit_Loop1:
	lds iz, 0
	cps iz, 4
	jr nc, VoiceSlot_FullInit_Loop2

VoiceSlot_FullInit_Loop1Next:
	ld a, (xsp + 4)
	ld l, a
	extz hl
	ld wa, (xsp + 2)
	ld c, a
	extz bc
	stb_erp A, 0xF8
	ld e, a
	extz de
	ld wa, hl
	calr AlgoFlag_Write_Bit3
	ld a, (xsp + 4)
	ld l, a
	extz hl
	ld wa, (xsp + 2)
	ld c, a
	extz bc
	stb_erp A, 0xF8
	ld e, a
	extz de
	ld wa, hl
	calr AlgoFlag_Write
	inc 1, iz
	cps iz, 4
	jr c, VoiceSlot_FullInit_Loop1Next

VoiceSlot_FullInit_Loop2:
	lds iz, 0
	cps iz, 4
	jr nc, VoiceSlot_FullInit_Loop3

VoiceSlot_FullInit_Loop2Next:
	ld a, (xsp + 4)
	ld l, a
	extz hl
	stb_erp A, 0xF8
	ld c, a
	extz bc
	ld wa, (xsp + 2)
	ld e, a
	extz de
	ld wa, hl
	calr EFF_RoutingInit
	inc 1, iz
	cps iz, 4
	jr c, VoiceSlot_FullInit_Loop2Next

VoiceSlot_FullInit_Loop3:
	incm 1, (xsp + 2)
	cpw (xsp + 2), 0x3
	jr c, VoiceSlot_FullInit_Loop1

VoiceSlot_FullInit_Epilogue:
	ld a, (xsp + 4)
	extz wa
	calr VoiceNoteParam_UpdateLoop
	popw iz
	inc 4, xsp
	ret

VoiceSlot_AltInit:
	dec 4, xsp
	pushw_erp 0xFA
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	lds bc, 0
	calr AlgoType_StateWrite
	ld a, (xsp + 4)
	extz wa
	calr Voice_ActiveFlag_CheckAndLoad
	ld a, (xsp + 4)
	extz wa
	calr DSP_SlotParam_Write_Slot0
	ld a, (xsp + 4)
	extz wa
	calr DSP_SlotParam_Write_Slot1
	ld a, (xsp + 4)
	extz wa
	calr DSP_SlotParam_Write_Slot2
	ld a, (xsp + 4)
	extz wa
	calr DSP_SlotParam_Write_Slot3
	ld a, (xsp + 4)
	extz wa
	calr DSP_SlotParam_Write_Slot4
	ld a, (xsp + 4)
	extz wa
	call Voice_InitFromSlot
	ld a, (xsp + 4)
	extz wa
	calr EnvTranspose_UpdateLoop
	ld (xsp + 2), 0x0
	cp (xsp + 2), 0x3
	jr nc, VoiceSlot_AltInit_Epilogue

VoiceSlot_AltInit_Loop1:
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jr nc, VoiceSlot_AltInit_Loop2

VoiceSlot_AltInit_Loop1Next:
	ld a, (xsp + 4)
	ld l, a
	extz hl
	ld a, (xsp + 2)
	ld c, a
	extz bc
	stb_erp A, 0xFB
	ld e, a
	extz de
	ld wa, hl
	calr AlgoFlag_Write_Bit3
	ld a, (xsp + 4)
	ld l, a
	extz hl
	ld a, (xsp + 2)
	ld c, a
	extz bc
	stb_erp A, 0xFB
	ld e, a
	extz de
	ld wa, hl
	calr AlgoFlag_Write
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jr c, VoiceSlot_AltInit_Loop1Next

VoiceSlot_AltInit_Loop2:
	ldib_erp 0xFB, 0
	cpib_erp 0xFB, 4
	jr nc, VoiceSlot_AltInit_Loop3

VoiceSlot_AltInit_Loop2Next:
	ld a, (xsp + 4)
	ld l, a
	extz hl
	stb_erp A, 0xFB
	ld c, a
	extz bc
	ld a, (xsp + 2)
	ld e, a
	extz de
	ld wa, hl
	calr EFF_RoutingInit
	inc1b_erp 0xFB
	cpib_erp 0xFB, 4
	jr c, VoiceSlot_AltInit_Loop2Next

VoiceSlot_AltInit_Loop3:
	incm8 1, (xsp + 2)
	cp (xsp + 2), 0x3
	jr c, VoiceSlot_AltInit_Loop1

VoiceSlot_AltInit_Epilogue:
	ld a, (xsp + 4)
	extz wa
	calr VoiceNoteParam_UpdateLoop
	popw_erp 0xFA
	inc 4, xsp
	ret

Voice_ProgChange:
	dec 4, xsp
	pushw_erp 0xFA
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0x1A
	jrl ge, Voice_ProgChange_InnerDispatch3
	ld xwa, (xsp + 2)
	ld a, (xwa + 1)
	ldb_erp A, 0xFB
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xde, 0x041381
	ld xwa, (xsp + 2)
	ld a, (xwa + 2)
	lda_dri XBC, 0x07, 0xE8, 0xE4
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x11F
	ld bc, wa
	lda_24 xde, 0x041382
	ld xwa, (xsp + 2)
	ld a, (xwa + 3)
	lda_dri XBC, 0x07, 0xE8, 0xE4
	ld xwa, (xsp + 2)
	cp (xwa + 4), 0x0
	jr z, Voice_ProgChange_Path1
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	or_sriw_im 0x07, 0xE4, 0xE0, 0x00, 0x40
	jr Voice_ProgChange_Path2

Voice_ProgChange_Path1:
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041372
	and_sriw_im 0x07, 0xE4, 0xE0, 0xFF, 0xBF

Voice_ProgChange_Path2:
	stb_erp A, 0xFB
	extz wa
	calr Voice_ActiveFlag_Set
	stb_erp A, 0xFB
	extz wa
	calr Voice_NoteState_Clear
	stb_erp A, 0xFB
	extz wa
	call Voice_SetLFO_ActiveFlag
	stb_erp A, 0xFB
	ld l, a
	extz hl
	ld xwa, (xsp + 2)
	ld c, (xwa + 2)
	ld xwa, (xsp + 2)
	ld e, (xwa + 3)
	ld wa, hl
	calr VoiceInit_Dispatcher
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0x80
	jr z, Voice_ProgChange_InnerDispatch3
	cp a, 0x40
	jr z, Voice_ProgChange_InnerDispatch2
	cp a, 0xC0
	jr z, Voice_ProgChange_InnerDispatch1
	cps a, 0
	jr nz, Voice_ProgChange_InnerDispatch3

Voice_ProgChange_InnerDispatch1:
	stb_erp A, 0xFB
	extz wa
	calr VoiceSlot_FullInit
	jr Voice_ProgChange_InnerDispatch3

Voice_ProgChange_InnerDispatch2:
	stb_erp A, 0xFB
	extz wa
	call Voice_PortamentoTargets_SetAll
	stb_erp A, 0xFB
	extz wa
	calr VoiceSlot_AltInit

Voice_ProgChange_InnerDispatch3:
	popw_erp 0xFA
	inc 4, xsp
	ret

VoiceSlot_ClearAll:
	dec 6, xsp
	push xiz
	ld (xsp + 8), 0x0
	cp (xsp + 8), 0x1A
	jrl nc, VoiceSlot_ClearAll_OuterNext

VoiceSlot_ClearAll_OuterLoop:
	ldw (xsp + 4), 0x0
	cpw (xsp + 4), 0x4
	jrl nc, VoiceSlot_ClearAll_MidNext

VoiceSlot_ClearAll_MidLoop:
	ldw (xsp + 6), 0x0
	cpw (xsp + 6), 0x3
	jr nc, VoiceSlot_ClearAll_InnerNext

VoiceSlot_ClearAll_InnerLoop:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	ld wa, (xsp + 6)
	extz xwa
	sll xwa, 4
	ld xde, xwa
	add xde, xbc
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	add xwa, xde
	ld (xwa + 39), 0x0
	ld wa, (xsp + 6)
	extz xwa
	ld xiz, xwa
	add xiz, xiz
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x25
	call FP_MulAccum64
	add xhl, xiz
	ld a, (xsp + 8)
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041368
	exts xwa
	add xwa, xbc
	add xwa, xhl
	stiw_ind 0xE1, 0x88, 0x00, 0x00, 0x00
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x3
	jr c, VoiceSlot_ClearAll_InnerLoop

VoiceSlot_ClearAll_InnerNext:
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x4
	jrl c, VoiceSlot_ClearAll_MidLoop

VoiceSlot_ClearAll_MidNext:
	ld a, (xsp + 8)
	extz wa
	calr Voice_NoteState_Clear
	incm8 1, (xsp + 8)
	cp (xsp + 8), 0x1A
	jrl c, VoiceSlot_ClearAll_OuterLoop

VoiceSlot_ClearAll_OuterNext:
	ldw (xsp + 4), 0x0
	cpw (xsp + 4), 0x40
	jr nc, VoiceSlot_ClearAll_Epilogue

VoiceSlot_ClearAll_SubLoop1:
	ldw (xsp + 6), 0x0
	cpw (xsp + 6), 0x3
	jr nc, VoiceSlot_ClearAll_SubLoop2

VoiceSlot_ClearAll_SubLoop1Next:
	ld wa, (xsp + 4)
	ld e, a
	extz de
	ld wa, (xsp + 6)
	ld c, a
	extz bc
	ld wa, de
	call NoteState_ClearRecord
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x3
	jr c, VoiceSlot_ClearAll_SubLoop1Next

VoiceSlot_ClearAll_SubLoop2:
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x40
	jr c, VoiceSlot_ClearAll_SubLoop1

VoiceSlot_ClearAll_Epilogue:
	stib_da 0x0451a4, 0xff
	pop xiz
	inc 6, xsp
	ret

; ----------------------------------------------------------------------------
; DSP_System_Init - Initialize DSP subsystem state and buffers
; Entry: None
; Exit:  None (jumps to DSP_Audio_Init via JP)
; Notes: Clears DSP state buffers at 0x041342 (38 bytes) and 0x041368 (7462 bytes)
;        Initializes control variables at 0x2B0D, 0x2B0F, 0x2B11
;        Checks PH.3 hardware pin for configuration variant
;        Then calls DSP reset and audio initialization routines
; ----------------------------------------------------------------------------
DSP_System_Init:	; 034C45h
	lds bc, 0
	lda_24 xwa, 0x041342                  ; DSP state buffer 1
	cp bc, 0x26	; 38 bytes
	jr nc, DSP_System_Init_Clear2

DSP_System_Init_Clear1:
	stib_dsp 0xE0, 0x00	; Clear byte
	inc 1, bc
	cp bc, 0x26
	jr c, DSP_System_Init_Clear1

DSP_System_Init_Clear2:
	lds bc, 0
	lda_24 xwa, 0x041368                  ; DSP state buffer 2
	cp bc, 0x1D26	; 7462 bytes
	jr nc, DSP_System_Init_Vars

DSP_System_Init_Clear2_Loop:
	stib_dsp 0xE0, 0x00
	inc 1, bc
	cp bc, 0x1D26
	jr c, DSP_System_Init_Clear2_Loop

DSP_System_Init_Vars:
	stdi16 11025, 0	; Clear DSP control variable
	lds wa, 0
	stda16 11023, xwa	; Clear control variable
	stda16 11021, xwa	; Clear control variable
	bit_dd8 3, 0x44	; Check hardware config pin
	jr z, DSP_System_Init_SetBit
	anddi16_24 267075, 65527	; Clear bit 3 of DSP config
	jr DSP_System_Init_Continue

DSP_System_Init_SetBit:
	ordi16_24 267075, 8	; Set bit 3 of DSP config

DSP_System_Init_Continue:
	ld xwa, 0x50000
	stl_da 0x045310, xwa
	ld xwa, 0x50000
	stl_da 0x045314, xwa
	lda_24 xwa, 0x0a0000
	stl_da 0x045318, xwa
	call DSP_Config_Init
	call DSP_Reset
	lds wa, 0
	call ToneGen_EmitCommandLoop
	call DSP_ResetWriteBufferPtr
	call VoiceSlot_ClearAll
	stib_da 0x041342, 0x00
	jp Voice_ResetAllControllers
Audio_Process_Init_Data:
	.byte 0x0e

Audio_Process_Init:
	cpib_da 0x041342, 0x00
	jr nz, Audio_Process_Init_BranchA
	call Voice_ScanAndCancelNoteOff
	call DSP_SlotState_DisplayRestore
	jr Audio_Process_Init_BranchB

Audio_Process_Init_BranchA:
	call AudioTick_UpdateVoice
	call Voice_UpdateAllNoteStates

Audio_Process_Init_BranchB:
	xordi8_24 267074, 255
	ret

; ===========================================================================
; RingBuf_ReadByte - Read single byte from audio ring buffer
; ===========================================================================
; Entry: XWA = pointer to buffer control structure:
;        +0 = read pointer (16-bit)
;        +2 = write pointer (16-bit)
;        +4 = byte count (16-bit)
;        +6 = buffer data (4KB)
; Exit:  HL = byte read (0x0000-0x00FF) or 0xFFFF if buffer empty
; Notes: Uses 12-bit circular index (0xFFF mask = 4KB buffer)
;        Decrements byte count after successful read
; ===========================================================================
RingBuf_ReadByte:
	cpw (xwa + 4), 0x0
	jr z, RingBuf_ReadByte_Empty
	lda xbc, (xwa + 2)
	ld de, (xbc)
	incm 1, (xbc)
	and de, 0xFFF
	ld bc, de
	extz xbc
	inc 6, xbc
	add xbc, xwa
	ld c, (xbc)
	extz bc
	ld hl, bc
	decm 1, (xwa + 4)
	jr RingBuf_ReadByte_Return

RingBuf_ReadByte_Empty:
	ldw hl, 0xFFFF

RingBuf_ReadByte_Return:
	ret

RingBuf_ReadByte_Data:
	.byte 0xf1, 0x0d, 0x2b, 0x30, 0x68, 0xd1

RingBuf_SkipToEnd:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr RingBuf_ReadByte
	cps hl, 0
	jr lt, RingBuf_SkipToEnd_Epilogue

RingBuf_SkipToEnd_Loop:
	ld xwa, xiz
	calr RingBuf_ReadByte
	cps hl, 0
	jr ge, RingBuf_SkipToEnd_Loop

RingBuf_SkipToEnd_Epilogue:
	ld wa, (xiz + 2)
	ld (xiz), wa
	pop xiz
	ret

; --- RingBuffer_Write4K: Write a byte to a 4KB circular buffer ---
; Entry: XWA = pointer to buffer control block
;        C = byte to write
; Buffer layout: [0]=write_ptr(16), [4]=count(16), [6+]=data area
; Write pointer wraps at 4095 (AND 0x0FFF).
Audio_CmdHandler_ConstData:
	ld	xde, xwa
	ld	hl, (xde)
	incm	1, (xde)
	and	hl, 4095
	ld	de, hl
	extz	xde
	inc	6, xde
	add	xde, xwa
	ld	(xde), c
	incm	1, (xwa+4)
	ret

; ===========================================================================
; Audio_CmdHandler_00_1F - Audio command handler for DSP/audio control
; ===========================================================================
; Entry: Stack contains:
;        XSP+004h = count of bytes to process (DE)
;        XSP+006h = pointer to command data (XWA)
; Exit:  HL = 0 (success)
; Notes: Writes incoming audio data to circular ring buffer
;        Buffer control at 0x2B0D (write ptr), 0x2B11 (count), 0x2B13 (base)
;        Uses 12-bit index (0xFFF mask = 4KB buffer capacity)
;        Called from CMD_DISPATCH_TABLE for commands 0x00-0x1F
; ===========================================================================
Audio_CmdHandler_00_1F:
	ld de, (xsp + 4)
	cps de, 0
	jr z, Audio_CmdHandler_00_1F_Done

Audio_CmdHandler_00_1F_Loop:
	lda_d16 xwa, 11021
	ld bc, (xwa)
	incm 1, (xwa)
	and bc, 0xFFF
	lda_d16 xwa, 11027
	extz xbc
	add xbc, xwa
	ld xwa, (xsp + 6)
	ld a, (xwa)
	ld (xbc), a
	incdi16 1, 11025
	dec 1, de
	lds32 xwa, 1
	add (xsp + 6), xwa
	cps de, 0
	jr nz, Audio_CmdHandler_00_1F_Loop

Audio_CmdHandler_00_1F_Done:
	lds hl, 0
	ret

; ===========================================================================
; MIDI_Dispatch - MIDI message dispatcher
; ===========================================================================
; Entry: Ring buffer at 0x2B0D contains MIDI data from main CPU
; Exit:  Messages dispatched to appropriate voice parameter handlers
; Notes: Parses MIDI status byte (0x80-0xF0) and routes to handlers:
;        0x80/0x90 = Note Off/On -> Voice_NoteOn (velocity 0 = off)
;        0xB0 = Control Change -> Voice_CtrlChange
;        0xC0 = Program Change -> Voice_ProgChange
;        0xD0 = Channel Pressure -> Voice_ChanPressure
;        0xE0 = Pitch Bend -> Voice_PitchBend
;        0xF0 = System Message -> Voice_SystemMsg
;        Loops until buffer is empty (RingBuf_ReadByte returns 0xFFFF)
; ===========================================================================
MIDI_Dispatch:
	push xiz
	lda_d16 xiz, 11021
	ld wa, (xiz + 4)
	call RingBuf_SetOffsetHi
	jrl MIDI_Dispatch_NextByte

MIDI_Dispatch_ParseStatus:
	ld wa, hl
	and wa, 0xF0
	cp wa, 0xF0
	jrl z, MIDI_Status_System
	cp wa, 0xE0
	jrl z, MIDI_Status_PitchBend
	cp wa, 0xD0
	jrl z, MIDI_Status_ChanPressure
	cp wa, 0xC0
	jrl z, MIDI_Status_ProgChange
	cp wa, 0xB0
	jrl z, MIDI_Status_CtrlChange
	cp wa, 0x90
	jrl z, MIDI_Status_NoteOn
	cp wa, 0x80
	jrl nz, MIDI_Status_Unknown
	cpw (xiz + 4), 0x5
	jr c, MIDI_Status_Incomplete
	bit 3, hl
	jr nz, MIDI_Status_NoteOn_Extended
	stb_d8 10984, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10985, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10986, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10987, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10988, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10989, l
	lda_d16 xwa, 10984
	call Voice_ParamFinalize
	jrl MIDI_Dispatch_Exit

MIDI_Status_NoteOn_Extended:
	stb_d8 10990, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10991, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10992, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10993, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10994, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10995, l
	lda_d16 xwa, 10990
	call Voice_ParamFinalize
	jrl MIDI_Dispatch_Exit

MIDI_Status_Incomplete:
	ld xwa, xiz
	calr RingBuf_SkipToEnd
	jrl MIDI_Dispatch_NextByte

MIDI_Status_NoteOn:
	cpw (xiz + 4), 0x3
	jr c, MIDI_Status_NoteOn_Skip
	stb_d8 10996, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10997, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10998, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 10999, l
	ldb_d8 a, 10997
	cp a, 0xF0
	jr nc, MIDI_Status_NoteOn_Poly
	lda_d16 xwa, 10996
	call Voice_NoteOn
	jrl MIDI_Dispatch_Exit

MIDI_Status_NoteOn_Poly:
	lda_d16 xwa, 10996
	call Voice_Poly_NoteOn
	jrl MIDI_Dispatch_Exit

MIDI_Status_NoteOn_Skip:
	ld xwa, xiz
	calr RingBuf_SkipToEnd
	jrl MIDI_Dispatch_NextByte

MIDI_Status_CtrlChange:
	cpw (xiz + 4), 0x3
	jr c, MIDI_Status_CtrlChange_Skip
	stb_d8 11000, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11001, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11002, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11003, l
	lda_d16 xwa, 11000
	call Voice_CtrlChange
	jrl MIDI_Dispatch_Exit

MIDI_Status_CtrlChange_Skip:
	ld xwa, xiz
	calr RingBuf_SkipToEnd
	jrl MIDI_Dispatch_NextByte

MIDI_Status_ProgChange:
	cpw (xiz + 4), 0x4
	jr c, MIDI_Status_ProgChange_Skip
	stb_d8 11004, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11005, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11006, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11007, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11008, l
	lda_d16 xwa, 11004
	call Voice_ProgChange
	jrl MIDI_Dispatch_Exit

MIDI_Status_ProgChange_Skip:
	ld xwa, xiz
	calr RingBuf_SkipToEnd
	jrl MIDI_Dispatch_NextByte

MIDI_Status_ChanPressure:
	cpw (xiz + 4), 0x3
	jr c, MIDI_Status_ChanPressure_Skip
	stb_d8 11009, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11010, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11011, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11012, l
	lda_d16 xwa, 11009
	call Voice_ChanPressure
	jrl MIDI_Dispatch_Exit

MIDI_Status_ChanPressure_Skip:
	ld xwa, xiz
	calr RingBuf_SkipToEnd
	jr MIDI_Dispatch_NextByte

MIDI_Status_PitchBend:
	cpw (xiz + 4), 0x3
	jr c, MIDI_Status_PitchBend_Skip
	stb_d8 11013, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11014, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11015, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11016, l
	lda_d16 xwa, 11013
	call Voice_PitchBend
	jr MIDI_Dispatch_Exit

MIDI_Status_PitchBend_Skip:
	ld xwa, xiz
	calr RingBuf_SkipToEnd
	jr MIDI_Dispatch_NextByte

MIDI_Status_System:
	cpw (xiz + 4), 0x3
	jr c, MIDI_Status_System_Skip
	stb_d8 11017, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11018, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11019, l
	ld xwa, xiz
	calr RingBuf_ReadByte
	stb_d8 11020, l
	lda_d16 xwa, 11017
	call Voice_SystemMsg
	jr MIDI_Dispatch_Exit

MIDI_Status_System_Skip:
	ld xwa, xiz
	calr RingBuf_SkipToEnd
	jr MIDI_Dispatch_NextByte

MIDI_Status_Unknown:
	ld xwa, xiz
	calr RingBuf_SkipToEnd

MIDI_Dispatch_NextByte:
	ld xwa, xiz
	calr RingBuf_ReadByte
	ld wa, hl
	cps wa, 0
	jrl ge, MIDI_Dispatch_ParseStatus

MIDI_Dispatch_Exit:
	pop xiz
	ret

DSP_WriteCount_Compute:
	ldw bc, 0x4970
	srl bc, 1
	ldl_da xwa, 0x04531c
	lda xwa, (xwa + 16)
	lds de, 0
	cps bc, 0
	jr z, DSP_WriteCount_Next

DSP_WriteCount_Loop:
	add_spiw DE, 0xE1
	djnz xbc, DSP_WriteCount_Loop

DSP_WriteCount_Next:
	ld wa, de
	cpl wa
	ld hl, wa
	ret

DSP_InitChannelSlot:
	dec 6, xsp
	push xiz
	ld (xsp + 8), bc
	ld xde, xwa
	ld wa, (xsp + 8)
	ld c, a
	extz bc
	ld xwa, xde
	ldw de, 0xFF
	call VoiceParam_WriteDispatchHelper
	ld (xsp + 4), xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 4
	add xbc, 0x4AA7
	ld xde, xbc
	addda32_24 xde, 283420
	ld xwa, (xsp + 4)
	ld xiy, xwa
	ld xix, xde
	ldw bc, 0x1D
	ldirw
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 4
	add xbc, 0x4AA7
	addda32_24 xbc, 283420
	ld (xsp + 4), xbc
	ld xwa, xbc
	lda xwa, (xwa + 16)
	ld xiz, xwa
	ld xbc, xiz
	ld wa, (xsp + 8)
	extz wa
	pushw 0xFF
	ld de, wa
	lds wa, 0
	call VoiceField_ExtractAndWrite
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 4
	add xbc, 0x4AA7
	ld xwa, xbc
	addda32_24 xwa, 283420
	ld xiy, xhl
	lda xix, (xwa + 58)
	lds bc, 5
	ldirw
	ldi85
	andmi8 (xiz + 2), 0xCF
	setm 4, (xiz + 2)
	ld xwa, (xsp + 4)
	lda xwa, (xwa + 37)
	ld xiz, xwa
	ld xbc, xiz
	ld wa, (xsp + 8)
	extz wa
	pushw 0xFF
	ld de, wa
	lds wa, 1
	call VoiceField_ExtractAndWrite
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 4
	add xbc, 0x4AA7
	ld xwa, xbc
	addda32_24 xwa, 283420
	ld xiy, xhl
	lda xix, (xwa + 69)
	lds bc, 5
	ldirw
	ldi85
	andmi8 (xiz + 2), 0xCF
	setm 4, (xiz + 2)
	pop xiz
	inc 6, xsp
	ret

DSP_FlushAllSlots:
	dec 4, xsp
	pushw iz
	extz wa
	extz bc
	call DSP_LookupVoiceBuffer
	ld (xsp + 2), xhl
	ldl_da xde, 0x04531c
	ld xwa, (xsp + 2)
	ld xiy, xwa
	stb_dri D, 0xE9, 0x80, 0x49
	ldw bc, 0x93
	ldirw
	ldi85
	lds iz, 0
	cp iz, 0x80
	jr nc, DSP_FlushAllSlots_Loop1Next

DSP_FlushAllSlots_Loop1:
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, 0x49A7
	addda32_24 xwa, 283420
	resm 5, (xwa + 1)
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, 0x49A7
	addda32_24 xwa, 283420
	setm 5, (xwa + 1)
	inc 1, iz
	cp iz, 0x80
	jr c, DSP_FlushAllSlots_Loop1

DSP_FlushAllSlots_Loop1Next:
	lds iz, 0
	cp iz, 0x80
	jr nc, DSP_FlushAllSlots_Loop2Next

DSP_FlushAllSlots_Loop2:
	ld xwa, (xsp + 2)
	ld bc, iz
	calr DSP_InitChannelSlot
	inc 1, iz
	cp iz, 0x80
	jr c, DSP_FlushAllSlots_Loop2

DSP_FlushAllSlots_Loop2Next:
	lds iz, 0
	cp iz, 0x10
	jr nc, DSP_FlushAllSlots_Loop3Next

DSP_FlushAllSlots_Loop3:
	ld wa, iz
	extz xwa
	add xwa, 0x4980
	ld xde, xwa
	addda32_24 xde, 283420
	ld wa, iz
	extz xwa
	ld xbc, 0x120F4
	add xbc, xwa
	ld a, (xbc)
	ld (xde), a
	inc 1, iz
	cp iz, 0x10
	jr c, DSP_FlushAllSlots_Loop3

DSP_FlushAllSlots_Loop3Next:
	lda_24 xwa, 0x007800
	ldw bc, 0x72AA
	ld xde, 0x1E0000
	call InterCPU_E1_DMA_Transfer
	popw iz
	inc 4, xsp
	ret

DSP_FlushAllSlots_Data:
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xd9, 0x09, 0x1f, 0x01
	.byte 0xf2, 0x81, 0x13, 0x04, 0x32, 0xc3, 0x07, 0xe8
	.byte 0xe4, 0x23, 0xcb, 0x8d, 0xda, 0x12, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x1f, 0x01, 0xf2, 0x82, 0x13, 0x04
	.byte 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x21, 0xc9, 0x8b
	.byte 0xd9, 0x12, 0xda, 0x88, 0x78, 0x18, 0xff

DSP1_ResolveStreamPtr:
	ld xhl, 0x50000
	ld_sril XBC, (xhl + 0x0088)
	add wa, bc
	ld xbc, (xhl + 8)
	ld xde, xhl
	add xde, xbc
	extz xwa
	sll xwa, 2
	add xde, xwa
	ld xwa, (xde)
	ld xbc, xhl
	add xhl, xwa
	ret

DSP_ResetAlgoDefaults:
	lds hl, 0
	cp hl, 0x10
	ret nc

DSP_ResetAlgoDefaults_Loop:
	ld wa, hl
	extz xwa
	ld xde, xwa
	addda32_24 xde, 283420
	ld wa, hl
	extz xwa
	ld xbc, 0x120E3
	add xbc, xwa
	ld a, (xbc)
	ld (xde), a
	inc 1, hl
	cp hl, 0x10
	jr c, DSP_ResetAlgoDefaults_Loop
	ret

DSP_WriteAlgoBuffer:
	push xiz
	ld e, c
	cp a, 0x1A
	jr nc, DSP_WriteAlgoBuffer_PathA
	cp e, 0x28
	jr c, DSP_WriteAlgoBuffer_PathB

DSP_WriteAlgoBuffer_PathA:
	ldb l, 0x2
	jrl DSP_WriteAlgoBuffer_Data

DSP_WriteAlgoBuffer_PathB:
	ld c, e
	extz bc
	muls bc, 0x1D6
	ld iz, bc
	add iz, 0x10
	ldl_da xhl, 0x04531c
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x04136e
	ld_sril3 XIY, 0x07, 0xF0, 0xE4
	stb_dri D, 0x07, 0xEC, 0xF8
	ldw bc, 0xD5
	ldirw
	ldb l, 0x0
	cps l, 4
	jrl nc, DSP_WriteAlgoBuffer_Epilogue

DSP_WriteAlgoBuffer_Loop:
	ld c, l
	extz bc
	muls bc, 0xB
	ld ix, bc
	ld c, e
	extz bc
	muls bc, 0x1D6
	ld iy, bc
	add iy, ix
	ldl_da xbc, 0x04531c
	stb_dri H, 0x07, 0xE4, 0xF4
	ld c, l
	extz bc
	muls bc, 0x25
	ld iy, bc
	add iy, 0x6E
	ld c, a
	extz bc
	muls bc, 0x11F
	lda_24 xix, 0x041368
	exts xbc
	add xbc, xix
	stb_dri A, 0x07, 0xE4, 0xF4
	ld xiy, (xbc + 4)
	stb_dri D, 0xF9, 0xBA, 0x01
	lds bc, 5
	ldirw
	ldi85
	ld c, l
	extz bc
	muls bc, 0x51
	ld ix, bc
	ld c, e
	extz bc
	muls bc, 0x1D6
	ld iy, bc
	add iy, ix
	ldl_da xbc, 0x04531c
	stb_dri D, 0x07, 0xE4, 0xF4
	lda xix, (xix + 121)
	ld c, (xix)
	and c, 0xC0
	cp c, 0xC0
	jr z, DSP_WriteAlgoBuffer_LoopNext
	andmi8 (xix), 0xCF
	setm 4, (xix)

DSP_WriteAlgoBuffer_LoopNext:
	inc 1, l
	cps l, 4
	jrl c, DSP_WriteAlgoBuffer_Loop

DSP_WriteAlgoBuffer_Epilogue:
	calr DSP_WriteCount_Compute
	ldl_da xwa, 0x04531c
	stw_dri HL, 0xE1, 0xA8, 0x72
	lda_24 xwa, 0x007800
	ldw bc, 0x72AA
	ld xde, 0x1E0000
	call InterCPU_E1_DMA_Transfer
	ldb l, 0x0

DSP_WriteAlgoBuffer_Data:
	pop xiz
	ret

DSP_Reinit_VoiceSlots:
	dec 4, xsp
	push xiz
	cp a, 0x40
	jrl nc, DSP_Reinit_VoiceSlots_Loop2A
	cp c, 0xFF
	jr z, DSP_Reinit_VoiceSlots_Loop1
	extz bc
	extz wa
	mul wa, 0x14
	ldw_erp WA, 0xFA
	add wa, bc
	ldw_erp WA, 0xFA
	calr DSP1_ResolveStreamPtr
	ld (xsp + 4), xhl
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x1D6
	call FP_MulAccum64
	add xhl, 0x10
	addda32_24 xhl, 283420
	ld xwa, (xsp + 4)
	ld xiy, xwa
	ld xix, xhl
	ldw bc, 0xD5
	ldirw
	jr DSP_Reinit_VoiceSlots_Loop2

DSP_Reinit_VoiceSlots_Loop1:
	ldb_erp A, 0xF8
	extz iz
	ld wa, iz
	mul wa, 0x14
	ld iz, wa
	ldw_erp IZ, 0xFA
	ld bc, iz
	add bc, 0x14
	stw_erp WA, 0xFA
	cp wa, bc
	jr nc, DSP_Reinit_VoiceSlots_Loop2

DSP_Reinit_VoiceSlots_Loop1Next:
	stw_erp WA, 0xFA
	calr DSP1_ResolveStreamPtr
	ld (xsp + 4), xhl
	stw_erp WA, 0xFA
	extz xwa
	ld xbc, 0x1D6
	call FP_MulAccum64
	add xhl, 0x10
	addda32_24 xhl, 283420
	ld xwa, (xsp + 4)
	ld xiy, xwa
	ld xix, xhl
	ldw bc, 0xD5
	ldirw
	inc1w_erp 0xFA
	ld bc, iz
	add bc, 0x14
	stw_erp WA, 0xFA
	cp wa, bc
	jr c, DSP_Reinit_VoiceSlots_Loop1Next

DSP_Reinit_VoiceSlots_Loop2:
	calr DSP_WriteCount_Compute
	ldl_da xwa, 0x04531c
	stw_dri HL, 0xE1, 0xA8, 0x72
	jrl DSP_Reinit_VoiceSlots_DMAFlush

DSP_Reinit_VoiceSlots_Loop2A:
	cp a, 0xFF
	jr z, DSP_Reinit_VoiceSlots_Loop3A
	cp c, 0xFF
	jr z, DSP_Reinit_VoiceSlots_Loop2B
	ldl_da xwa, 0x04531c
	stb_dri W, 0xE1, 0x80, 0x49
	extz bc
	calr DSP_InitChannelSlot
	jr DSP_Reinit_VoiceSlots_Loop3

DSP_Reinit_VoiceSlots_Loop2B:
	ldw_erp IZ, 0xFA
	cp_erpw 0xFA, 0x80, 0x00
	jr nc, DSP_Reinit_VoiceSlots_Loop3

DSP_Reinit_VoiceSlots_Loop2Next:
	ldl_da xwa, 0x04531c
	stb_dri W, 0xE1, 0x80, 0x49
	stw_erp BC, 0xFA
	calr DSP_InitChannelSlot
	inc1w_erp 0xFA
	cp_erpw 0xFA, 0x80, 0x00
	jr c, DSP_Reinit_VoiceSlots_Loop2Next

DSP_Reinit_VoiceSlots_Loop3:
	calr DSP_WriteCount_Compute
	ldl_da xwa, 0x04531c
	stw_dri HL, 0xE1, 0xA8, 0x72
	jr DSP_Reinit_VoiceSlots_DMAFlush

DSP_Reinit_VoiceSlots_Loop3A:
	calr DSP_ResetAlgoDefaults
	lds iz, 0
	cp iz, 0x28
	jr nc, DSP_Reinit_VoiceSlots_OuterNext

DSP_Reinit_VoiceSlots_Loop3Next:
	ld wa, iz
	calr DSP1_ResolveStreamPtr
	ld (xsp + 4), xhl
	ld wa, iz
	extz xwa
	ld xbc, 0x1D6
	call FP_MulAccum64
	add xhl, 0x10
	addda32_24 xhl, 283420
	ld xwa, (xsp + 4)
	ld xiy, xwa
	ld xix, xhl
	ldw bc, 0xD5
	ldirw
	inc 1, iz
	cp iz, 0x28
	jr c, DSP_Reinit_VoiceSlots_Loop3Next

DSP_Reinit_VoiceSlots_OuterNext:
	lds wa, 0
	ldw bc, 0x40
	calr DSP_FlushAllSlots
	calr DSP_WriteCount_Compute
	ldl_da xwa, 0x04531c
	stw_dri HL, 0xE1, 0xA8, 0x72

DSP_Reinit_VoiceSlots_DMAFlush:
	lda_24 xwa, 0x007800
	ldw bc, 0x72AA
	ld xde, 0x1E0000
	call InterCPU_E1_DMA_Transfer
	pop xiz
	inc 4, xsp
	ret

DSP_VoiceState_Dispatch:
	pushw_erp 0xFA
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0x1A
	jrl nc, DSP_VoiceState_Dispatch_Epilogue

DSP_VoiceState_Dispatch_Scan:
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041382
	cpib_sri 0x07, 0xE4, 0xE0, 0x10
	jr z, DSP_VoiceState_Dispatch_ActiveVoice
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041382
	cpib_sri 0x07, 0xE4, 0xE0, 0x50
	jrl nz, DSP_VoiceState_Dispatch_LoopNext

DSP_VoiceState_Dispatch_ActiveVoice:
	stb_erp A, 0xFB
	ld l, a
	extz hl
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041381
	ldb_sri A, 0x07, 0xE4, 0xE0
	ldb_erp A, 0xF0
	extz ix
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x041382
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld e, a
	extz de
	ld wa, hl
	ld bc, ix
	call VoiceInit_Dispatcher
	stb_erp A, 0xFB
	extz wa
	muls wa, 0x11F
	lda_24 xbc, 0x04136e
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 16)
	and a, 0xC0
	cp a, 0x80
	jr z, DSP_VoiceState_Dispatch_LoopNext
	cp a, 0x40
	jr z, DSP_VoiceState_Dispatch_SubPathB
	cp a, 0xC0
	jr z, DSP_VoiceState_Dispatch_SubPathA
	cps a, 0
	jr nz, DSP_VoiceState_Dispatch_LoopNext

DSP_VoiceState_Dispatch_SubPathA:
	stb_erp A, 0xFB
	extz wa
	call VoiceSlot_FullInit
	jr DSP_VoiceState_Dispatch_LoopNext

DSP_VoiceState_Dispatch_SubPathB:
	stb_erp A, 0xFB
	extz wa
	call Voice_PortamentoTargets_SetAll
	stb_erp A, 0xFB
	extz wa
	call VoiceSlot_AltInit

DSP_VoiceState_Dispatch_LoopNext:
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0x1A
	jrl c, DSP_VoiceState_Dispatch_Scan

DSP_VoiceState_Dispatch_Epilogue:
	popw_erp 0xFA
	ret

DSP_ResetWriteBufferPtr:
	lda_24 xwa, 0x007800
	stl_da 0x045320, xwa
	lda_24 xwa, 0x007800
	stl_da 0x04531c, xwa
	ret

DSP_Stub_RetA:
	ret

DSP_Stub_RetB:
	ret

DSP_Stub_RetC:
	ret

DSP_VelocityToVolume:
	ld bc, wa
	mul xbc, xwa
	srl bc, 2
	ld hl, bc
	add hl, 0x3F
	ret

DSP_GetEffectRouting:
	lds hl, 0
	cpib_da 0x041377, 0x00
	jr z, DSP_GetEffectRouting_Path
	ldb_da a, 0x041377
	extz wa
	sll wa, 8
	or hl, wa

DSP_GetEffectRouting_Path:
	cpib_da 0x04137a, 0x00
	ret z
	ldb_da a, 0x041377
	extz wa
	or hl, wa
	ret

ToneGen_SetupPolyVoice:
	dec 4, xsp
	ld (xsp), e
	ld e, c
	ld (xsp + 2), a
	ld xiy, 0x12115
	ld xix, 0x3B1C
	ldw bc, 0x22
	ldirw
	ld a, e
	extz wa
	lda_24 xbc, 0x012171
	ldb_sri A, 0x07, 0xE4, 0xE0
	add a, (xsp)
	ld (xsp), a
	resm 7, (xsp)
	ld a, (xsp)
	extz wa
	sll wa, 8
	set 7, wa
	stda16 15146, xwa
	ld a, e
	extz wa
	lda_24 xbc, 0x012177
	cpib_sri 0x07, 0xE4, 0xE0, 0x00
	jr z, ToneGen_SetupPolyVoice_Path
	ld a, e
	extz wa
	lda_24 xbc, 0x012177
	ldb_sri A, 0x07, 0xE4, 0xE0
	ld (xsp + 8), a

ToneGen_SetupPolyVoice_Path:
	ld a, (xsp + 8)
	extz wa
	calr DSP_VelocityToVolume
	orddm16 15136, xhl
	calr DSP_GetEffectRouting
	orddm16 15138, xhl
	ld a, (xsp)
	extz wa
	div a, 0xC
	ld a, w
	extz wa
	add wa, wa
	lda_24 xbc, 0x01217d
	ldw_sri WA, 0x07, 0xE4, 0xE0
	stda16 15134, xwa
	ld a, (xsp + 2)
	extz wa
	lda_d16 xbc, 15132
	call ToneGen_WriteVoiceParams
	ld a, (xsp + 2)
	extz wa
	ldw_d16 xbc, 15132
	call ToneGen_WriteSingleReg
	inc 4, xsp
	retd 0x2

ToneGen_SetupPercussionVoice:
	dec 2, xsp
	ld (xsp), a
	ld xiy, 0x12115
	ld xix, 0x3B1C
	ldw bc, 0x22
	ldirw
	ld a, e
	extz wa
	div a, 0xC
	ld c, w
	sub e, c
	res 7, e
	ld a, e
	extz wa
	sll wa, 8
	orddm16 15146, xwa
	ld a, c
	extz wa
	add wa, wa
	lda_24 xbc, 0x012195
	ldw_sri WA, 0x07, 0xE4, 0xE0
	orddm16 15132, xwa
	calr DSP_GetEffectRouting
	orddm16 15138, xhl
	ordi16 15136, 4095
	ldw_da xwa, 0x01217d
	stda16 15134, xwa
	ld a, (xsp)
	extz wa
	lda_d16 xbc, 15132
	call ToneGen_WriteVoiceParams
	ld a, (xsp)
	extz wa
	ldw_d16 xbc, 15132
	call ToneGen_WriteSingleReg
	inc 2, xsp
	retd 0x2

Voice_Poly_NoteOn:
	push xiz
	ld e, (xwa + 1)
	ld c, e
	and c, 0xF
	ldb_erp C, 0xFB
	cp e, 0xF0
	jrl c, Voice_Poly_NoteOn_Epilogue
	cpib_erp 0xFB, 5
	jr ule, Voice_Poly_NoteOn_RoundRobin
	ldib_erp 0xFB, 0

Voice_Poly_NoteOn_RoundRobin:
	ldb_d8 c, 15123
	inc 1, c
	and c, 0x7
	stb_d8 15123, c
	ld c, (xwa + 3)
	res 7, c
	ldb_erp C, 0xF9
	ld a, (xwa + 2)
	res 7, a
	ldb_erp A, 0xFA
	cpib_erp 0xF9, 0
	jrl z, Voice_Poly_NoteOn_ReleasePath
	res_dd8 7, 0x18
	ldb_d8 a, 15123
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff00
	jr __jrt_nop_035727
__jrt_nop_035727:

Voice_Poly_NoteOn_SlotSearch:
	nop
	nop
	nop
	res_dd8 7, 0x18
	ldb_d8 a, 15123
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xff80
	jr __jrt_nop_035749
__jrt_nop_035749:

Voice_Poly_NoteOn_SlotFound:
	nop
	nop
	nop
	ldb_d8 a, 15123
	ld l, a
	extz hl
	stb_erp A, 0xFB
	ld c, a
	extz bc
	stb_erp A, 0xFA
	ld e, a
	extz de
	stb_erp A, 0xF9
	extz wa
	pushw wa
	ld wa, hl
	stb_erp L, 0xFB
	extz hl
	sla hl, 2
	lda_24 xix, 0x012159
	exts xhl
	add xhl, xix
	ld xhl, (xhl)
	call (xhl)
	ldb_d8 a, 15123
	extz wa
	lda_d16 xbc, 15124
	ld de, wa
	extz xde
	add xde, xbc
	stb_erp A, 0xFA
	set 7, a
	ld (xde), a
	jr Voice_Poly_NoteOn_Epilogue

Voice_Poly_NoteOn_ReleasePath:
	set_erpb 0xFA, 0x07
	ldib_erp 0xFB, 0
	cp_erpb 0xFB, 0x08
	jr nc, Voice_Poly_NoteOn_Epilogue

Voice_Poly_NoteOn_ReleaseCheck:
	stb_erp A, 0xFB
	extz wa
	lda_d16 xbc, 15124
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cpb_erp A, 0xFA
	jr nz, Voice_Poly_NoteOn_AssignSlot
	res_dd8 7, 0x18
	stb_erp A, 0xFB
	extz wa
	add wa, 0x840
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xa200
	jr __jrt_nop_0357D8
__jrt_nop_0357D8:

Voice_Poly_NoteOn_ReleaseNext:
	nop
	nop
	nop
	res_dd8 7, 0x18
	stb_erp A, 0xFB
	extz wa
	add wa, 0x800
	stw_da 0x100000, xwa
	nop
	set_dd8 7, 0x18
	stiw_da 0x100002, 0xa280
	jr __jrt_nop_0357F9
__jrt_nop_0357F9:

Voice_Poly_NoteOn_ReleaseDone:
	nop
	nop
	nop
	stb_erp A, 0xFB
	extz wa
	lda_d16 xbc, 15124
	extz xwa
	add xwa, xbc
	resm 7, (xwa)
	jr Voice_Poly_NoteOn_Epilogue

Voice_Poly_NoteOn_AssignSlot:
	inc1b_erp 0xFB
	cp_erpb 0xFB, 0x08
	jr c, Voice_Poly_NoteOn_ReleaseCheck

Voice_Poly_NoteOn_Epilogue:
	pop xiz
	ret

DSP_StoreBufferCount:
	stda16 17254, xwa
	ret

; ===========================================================================
; DSP2_Init - Initialize second DSP chip
; ===========================================================================
; Entry: None
; Exit:  DSP2 state cleared
; Notes: Clears DSP2 control variables at 0x3B60-0x3B64
;        Called during Audio_System_Init after primary DSP initialization
; ===========================================================================
DSP2_Init:
	stdi16 15204, 0
	lds wa, 0
	stda16 15202, xwa
	stda16 15200, xwa
	ret

Voice_Poly_NoteOn_Data:
	.byte 0x0e, 0x0e

DSP_RingBuf_Read:
	cpw (xwa + 4), 0x0
	jr z, DSP_RingBuf_Read_Empty
	lda xbc, (xwa + 2)
	ld de, (xbc)
	incm 1, (xbc)
	and de, 0x7FF
	ld bc, de
	extz xbc
	inc 6, xbc
	add xbc, xwa
	ld c, (xbc)
	extz bc
	ld hl, bc
	decm 1, (xwa + 4)
	jr DSP_RingBuf_Read_Return

DSP_RingBuf_Read_Empty:
	ldw hl, 0xFFFF

DSP_RingBuf_Read_Return:
	ret

DSP_RingBuf_Read_Data:
	.byte 0xf1
	.ascii "`;0h"
	.byte 0xd1

DSP_RingBuf_Skip:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr DSP_RingBuf_Read
	cps hl, 0
	jr lt, DSP_RingBuf_Skip_Epilogue

DSP_RingBuf_Skip_Loop:
	ld xwa, xiz
	calr DSP_RingBuf_Read
	cps hl, 0
	jr ge, DSP_RingBuf_Skip_Loop

DSP_RingBuf_Skip_Epilogue:
	ld wa, (xiz + 2)
	ld (xiz), wa
	pop xiz
	ret

; --- RingBuffer_Write2K: Write a byte to a 2KB circular buffer ---
; Entry: XWA = pointer to buffer control block
;        C = byte to write
; Same as RingBuffer_Write4K but wraps at 2047 (AND 0x07FF).
DSP_RingBuf_Write2K:
	ld	xde, xwa
	ld	hl, (xde)
	incm	1, (xde)
	and	hl, 2047
	ld	de, hl
	extz	xde
	inc	6, xde
	add	xde, xwa
	ld	(xde), c
	incm	1, (xwa+4)
	ret

Audio_CmdHandler_60_7F:
	ld xhl, (xsp + 6)
	ld de, (xsp + 4)
	cpdi16 17548, 0
	jr z, CmdHandler60_StreamSizeC
	cpdi16 17548, 1
	jr ule, CmdHandler60_StreamSizeA
	lds ix, 0

CmdHandler60_StreamSizeA:
	ldw_d16 xwa, 17546
	add wa, de
	cpda16 xwa, 17544
	jr nc, CmdHandler60_StreamSizeB
	adddm16 17546, xde
	incdi16 1, 17548
	jr DSP_EnqueueOrReturn

CmdHandler60_StreamSizeB:
	stdi16 17546, 0
	stdi16 17548, 0
	jr DSP_EnqueueOrReturn

CmdHandler60_StreamSizeC:
	cp de, 0x20
	jr nz, DSP_CmdHandler_StateReset
	ld a, (xhl + 5)
	extz wa
	and wa, 0x7FF
	ld bc, wa
	sll bc, 7
	ld a, (xhl + 6)
	extz wa
	add wa, bc
	inc 8, wa
	stda16 17544, xwa
	adddi16 17546, 32
	stdi16 17548, 1
	jr DSP_EnqueueOrReturn

DSP_CmdHandler_StateReset:
	stdi16 17546, 0
	stdi16 17548, 0

DSP_EnqueueOrReturn:
	lds ix, 0
	cp ix, de
	jr nc, DSP_Enqueue_ReturnOK

DSP_RingBuf_Enqueue:
	lda_d16 xwa, 15200
	ld bc, (xwa)
	incm 1, (xwa)
	and bc, 0x7FF
	lda_d16 xwa, 15206
	extz xbc
	add xbc, xwa
	ldb_spi A, 0xEC
	ld (xbc), a
	incdi16 1, 15204
	inc 1, ix
	cp ix, de
	jr c, DSP_RingBuf_Enqueue

DSP_Enqueue_ReturnOK:
	lds hl, 0
	ret

Extract_14Bit_PayloadSize:
	ld c, (xwa + 6)
	extz bc
	and bc, 0x7F
	ld a, (xwa + 5)
	extz wa
	and wa, 0x7F
	sll wa, 7
	ld hl, wa
	or hl, bc
	ret

; --- Pack3x7bit: Extract and pack three 7-bit fields ---
; Entry: XWA = pointer to a 4-byte structure
;   byte[1] bits 6:0 -> XHL bits 20:14
;   byte[2] bits 6:0 -> XHL bits 13:7
;   byte[3] bits 6:0 -> XHL bits 6:0
; Exit: XHL = packed 21-bit value
DSP_Pack3x7bitFields:
	ld	c, (xwa+2)
	res	7, c
	ldb	b, 0
	extz	xbc
	ld	xde, xbc
	sll	xde, 7
	ld	c, (xwa+1)
	res	7, c
	ldb	b, 0
	extz	xbc
	sll	xbc, 14
	or	xbc, xde
	ld	a, (xwa+3)
	res	7, a
	ldb	w, 0
	extz	xwa
	ld	xhl, xwa
	or	xhl, xbc
	ret

Extract_14Bit_VoiceParam:
	ld c, (xwa + 3)
	extz bc
	and bc, 0x7F
	ld a, (xwa + 2)
	extz wa
	and wa, 0x7F
	sll wa, 7
	ld hl, wa
	or hl, bc
	ret

DSP_Cmd_DequeueHeader:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr DSP_RingBuf_Read
	stb_d8 17257, l
	ld xwa, xiz
	calr DSP_RingBuf_Read
	stb_d8 17258, l
	ld xwa, xiz
	calr DSP_RingBuf_Read
	stb_d8 17259, l
	ld xwa, xiz
	calr DSP_RingBuf_Read
	stb_d8 17260, l
	ld xwa, xiz
	calr DSP_RingBuf_Read
	stb_d8 17261, l
	ld xwa, xiz
	calr DSP_RingBuf_Read
	stb_d8 17262, l
	ld xwa, xiz
	calr DSP_RingBuf_Read
	stb_d8 17263, l
	pop xiz
	ret

DSP_Cmd_LoadEffectPreset:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), xwa
	ldb_d8 a, 17261
	extz wa
	ld bc, wa
	sll bc, 7
	ldb_d8 a, 17262
	extz wa
	add wa, bc
	cp wa, 0x122
	jr nz, DSP_LoadEffPreset_Loop3Next
	call DSP_GetConfigBuffer
	ld (xsp + 6), xhl
	ldw (xsp + 4), 0x8
	lds iz, 0
	cp iz, (xsp + 4)
	jr nc, DSP_LoadEffPreset_Loop1Next

DSP_LoadEffPreset_Loop1:
	ld xwa, (xsp + 10)
	calr DSP_RingBuf_Read
	ld xwa, (xsp + 6)
	lda_dpi XSP, 0xE0
	ld (xsp + 6), xwa
	inc 1, iz
	cp iz, (xsp + 4)
	jr c, DSP_LoadEffPreset_Loop1

DSP_LoadEffPreset_Loop1Next:
	ldw (xsp + 4), 0x38
	ldiw_erp 0xFA, 0
	cpi3_erpw 5, 0xFA
	jr nc, DSP_LoadEffPreset_Loop3A

DSP_LoadEffPreset_Loop2:
	stw_erp WA, 0xFA
	call EFF_GetSlotBuffer
	ld (xsp + 6), xhl
	lds iz, 0
	cp iz, (xsp + 4)
	jr nc, DSP_LoadEffPreset_Loop3

DSP_LoadEffPreset_Loop2Next:
	ld xwa, (xsp + 10)
	calr DSP_RingBuf_Read
	ld xwa, (xsp + 6)
	lda_dpi XSP, 0xE0
	ld (xsp + 6), xwa
	inc 1, iz
	cp iz, (xsp + 4)
	jr c, DSP_LoadEffPreset_Loop2Next

DSP_LoadEffPreset_Loop3:
	inc1w_erp 0xFA
	cpi3_erpw 5, 0xFA
	jr c, DSP_LoadEffPreset_Loop2

DSP_LoadEffPreset_Loop3A:
	ld xwa, (xsp + 10)
	calr DSP_RingBuf_Read
	ld xwa, (xsp + 10)
	calr DSP_RingBuf_Read
	lds hl, 0
	jr DSP_LoadEffPreset_Epilogue

DSP_LoadEffPreset_Loop3Next:
	ld xwa, (xsp + 10)
	calr DSP_RingBuf_Skip
	ldw hl, 0xFFFF

DSP_LoadEffPreset_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

DSP_RingBuf_ReadAndCompare:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	lds iz, 0
	jr DSP_RingBuf_Compare_MismatchPath

DSP_RingBuf_Compare_Loop:
	ld xwa, (xsp + 8)
	calr DSP_RingBuf_Read
	ld xwa, (xsp + 4)
	cp (xwa), l
	jr z, DSP_RingBuf_Compare_MatchPath
	inc1w_erp 0xFA

DSP_RingBuf_Compare_MatchPath:
	ld xwa, (xsp + 4)
	lda_dpi XSP, 0xE0
	ld (xsp + 4), xwa
	inc 1, iz

DSP_RingBuf_Compare_MismatchPath:
	ldb_d8 a, 17262
	extz wa
	cp iz, wa
	jr c, DSP_RingBuf_Compare_Loop
	cpdi8 17263, 255
	jr z, DSP_RingBuf_Compare_LoopNext
	cpi3_erpw 2, 0xFA
	jr c, DSP_RingBuf_Compare_FoundPath

DSP_RingBuf_Compare_LoopNext:
	ldb_d8 l, 17263
	jr DSP_RingBuf_Compare_Epilogue

DSP_RingBuf_Compare_FoundPath:
	ldb l, 0x0

DSP_RingBuf_Compare_Epilogue:
	pop xiz
	inc 8, xsp
	ret

; ===========================================================================
; Audio_Process_DSP - DSP audio processing main loop
; ===========================================================================
; Entry: Called from main audio loop after MIDI_Dispatch
; Exit:  DSP state updated, audio buffers processed
; Notes: Processes pending DSP commands from buffer at 0x3B60
;        Updates DSP2 voice parameters and effect processing
;        Part of main audio loop: ToneGen -> MIDI -> DSP -> Final
; ===========================================================================
; =============================================================================
; Audio_Process_DSP -- Main DSP command processing loop
; =============================================================================
; Consumes commands from the DSP ring buffer (2KB at 0x3B60).
; Each message is 1 framing byte + 7 header bytes:
;   0x2B = voice DSP param update (per-voice effects)
;   0x2C = channel/voice configuration
;   0x2D = DSP effect configuration (preset loads)
; Sub-commands for 0x2B (header byte 2):
;   0x00 -> DSP_AlgoSelect (select algorithm)
;   0x03 -> DSP_EffectStateQuery (state control)
;   0x10-0x17 -> DSP_VoiceParamReadWrite (set param 0-7)
;   0x20 -> DSP_MixSendConfig (mix/send routing)
; Jump table for params 0-7 at Sub CPU ROM 0x0121DB.
Audio_Process_DSP:
	lda xsp, (xsp - 10)
	push xiz
	lda_d16 xwa, 15200
	ld (xsp + 4), xwa
	ld wa, (xwa + 4)
	calr DSP_StoreBufferCount
	cpdi16 17548, 0
	jrl z, DSP_Process_ReadNext
	jrl DSP_Process_Exit

DSP_Process_NextCmd:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	inc 5, wa
	and wa, 0x7FF
	extz xwa
	inc 6, xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	cp bc, (xwa + 4)
	jr ule, Audio_Process_DSP_MsgSizeCheck
	ld xwa, (xsp + 4)
	decm 1, (xwa + 2)
	ld xwa, (xsp + 4)
	incm 1, (xwa + 4)
	stdi16 17548, 1
	jrl DSP_Process_Exit

Audio_Process_DSP_MsgSizeCheck:
	ld xwa, (xsp + 4)
	calr DSP_Cmd_DequeueHeader
	ld wa, (xsp + 12)
	stb_d8 17256, a
	cp a, 0x2D
	jrl z, DSP_CmdHandler_2D
	cp a, 0x2C
	jrl z, DSP_CmdHandler_2C
	cp a, 0x2B
	jrl nz, DSP_Cmd_DefaultSkip
	lda_d16 xwa, 17264
	ld xbc, xwa
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_ReadAndCompare
	ldb_d8 a, 17257
	ldb_erp A, 0xFB
	cp_erpb 0xFB, 0x30
	jrl c, DSP_Cmd2B_SkipAndContinue
	cp_erpb 0xFB, 0x3F
	jrl ugt, DSP_Cmd2B_SkipAndContinue
	cpdi8 17258, 127
	jrl nz, DSP_Cmd2B_VoiceParamWrite
	stb_erp A, 0xFB
	ldb_erp A, 0xF8
	extz iz
	and iz, 0xF
	lda_d16 xwa, 17264
	ld (xsp + 10), xwa
	ldb_d8 a, 17259
	cp a, 0x30
	jrl z, DSP_Cmd2B_Noop
	cp a, 0x27
	jrl z, DSP_Cmd2B_ReadParam11
	cp a, 0x24
	jrl z, DSP_Cmd2B_SetParam
	cp a, 0x22
	jrl z, DSP_Cmd2B_ReadParam5D
	cp a, 0x20
	jrl z, DSP_Cmd2B_MixSendConfig
	cps a, 3
	jr z, DSP_Cmd2B_StateControl
	cps a, 0
	jr z, DSP_Cmd2B_AlgoSelect
	extz wa
	sub wa, 0x10
	cps wa, 0
	jrl lt, DSP_Cmd2B_UnknownSkip
	cps wa, 7
	jrl gt, DSP_Cmd2B_UnknownSkip
	add wa, wa
	lda_24 xix, 0x0121db
	ldw_sri WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0x035bc6
	jp_ind 8, 0x07, 0xF0, 0xE0

DSP_Cmd2B_AlgoSelect:
	ld wa, iz
	call CheckStatusBits_40
	cps hl, 0
	jr z, DSP_Cmd2B_AlgoSelect_Continue
	ld wa, iz
	call Voice_Slot_CalcArticParams

DSP_Cmd2B_AlgoSelect_Continue:
	stb_erp A, 0xF8
	ld e, a
	extz de
	ldb_d8 a, 17264
	ld c, a
	extz bc
	ld wa, de
	ld xde, (xsp + 10)
	call DSP_AlgoSelect
	jrl DSP_Cmd2B_PostProcess

DSP_Cmd2B_StateControl:
	ld a, (xsp + 8)
	and a, 0xF
	extz wa
	ld xbc, (xsp + 10)
	call DSP_EffectStateQuery
	jrl DSP_Cmd2B_PostProcess
	ld a, (xsp + 8)
	and a, 0xF
	extz wa
	ld xde, (xsp + 10)
	lds bc, 0
	call DSP_VoiceParamReadWrite
	jrl DSP_Cmd2B_PostProcess
	ld a, (xsp + 8)
	and a, 0xF
	extz wa
	ld xde, (xsp + 10)
	lds bc, 1
	call DSP_VoiceParamReadWrite
	jrl DSP_Cmd2B_PostProcess
	ld a, (xsp + 8)
	and a, 0xF
	extz wa
	ld xde, (xsp + 10)
	lds bc, 2
	call DSP_VoiceParamReadWrite
	jrl DSP_Cmd2B_PostProcess
	ld a, (xsp + 8)
	and a, 0xF
	extz wa
	ld xde, (xsp + 10)
	lds bc, 3
	call DSP_VoiceParamReadWrite
	jrl DSP_Cmd2B_PostProcess
	ld a, (xsp + 8)
	and a, 0xF
	extz wa
	ld xde, (xsp + 10)
	lds bc, 4
	call DSP_VoiceParamReadWrite
	jrl DSP_Cmd2B_PostProcess
	ld a, (xsp + 8)
	and a, 0xF
	extz wa
	ld xde, (xsp + 10)
	lds bc, 5
	call DSP_VoiceParamReadWrite
	jrl DSP_Cmd2B_PostProcess
	ld a, (xsp + 8)
	and a, 0xF
	extz wa
	ld xde, (xsp + 10)
	lds bc, 6
	call DSP_VoiceParamReadWrite
	jrl DSP_Cmd2B_PostProcess
	ld a, (xsp + 8)
	and a, 0xF
	extz wa
	ld xde, (xsp + 10)
	lds bc, 7
	call DSP_VoiceParamReadWrite
	jrl DSP_Cmd2B_PostProcess

DSP_Cmd2B_MixSendConfig:
	ldb_d8 a, 17264
	ld e, a
	extz de
	ldb_d8 a, 17265
	ld c, a
	extz bc
	ld wa, de
	ld xde, (xsp + 10)
	call DSP_MixSendConfig
	jrl DSP_Cmd2B_PostProcess

DSP_Cmd2B_ReadParam5D:
	ldb_d8 a, 17264
	ld e, a
	extz de
	ldb_d8 a, 17265
	ld c, a
	extz bc
	ld wa, de
	ld xde, (xsp + 10)
	call DSP_ReadVoiceParam5D
	jr DSP_Cmd2B_PostProcess

DSP_Cmd2B_SetParam:
	ldb_d8 a, 17264
	ld e, a
	extz de
	ldb_d8 a, 17265
	ld c, a
	extz bc
	ld wa, de
	ld xde, (xsp + 10)
	call DSP_SetVoiceCoefficients
	jr DSP_Cmd2B_PostProcess

DSP_Cmd2B_ReadParam11:
	ldb_d8 a, 17264
	ld e, a
	extz de
	ldb_d8 a, 17265
	ld c, a
	extz bc
	ld wa, de
	ld xde, (xsp + 10)
	call DSP_ReadVoiceParam11
	jr DSP_Cmd2B_PostProcess

DSP_Cmd2B_Noop:
	lds hl, 0
	jr DSP_Cmd2B_PostProcess

DSP_Cmd2B_UnknownSkip:
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip
	lds hl, 0
	jr DSP_Cmd2B_PostProcess

DSP_Cmd2B_VoiceParamWrite:
	stb_erp A, 0xFB
	extz wa
	ld iz, wa
	and iz, 0xF
	lda_d16 xwa, 17256
	calr Extract_14Bit_VoiceParam
	ldw_erp HL, 0xFA
	lda_d16 xwa, 17256
	calr Extract_14Bit_PayloadSize
	lda_d16 xwa, 17264
	push xwa
	ld wa, iz
	stw_erp BC, 0xFA
	ld de, hl
	call DSP_WriteVoiceParam

DSP_Cmd2B_PostProcess:
	cps hl, 0
	jrl z, DSP_Process_ReadNext
	inc 8, hl
	lda_d16 xde, 17256
	ld bc, hl
	lds wa, 3
	call InterCPU_DMA_Send
	jrl DSP_Process_ReadNext

DSP_Cmd2B_SkipAndContinue:
	cp_erpb 0xFB, 0x40
	jr nz, DSP_Cmd2B_SkipPath
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip
	jrl DSP_Process_ReadNext

DSP_Cmd2B_SkipPath:
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip
	jrl DSP_Process_ReadNext

DSP_CmdHandler_2C:
	lda_d16 xwa, 17264
	ld xbc, xwa
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_ReadAndCompare
	ldb_d8 a, 17257
	ldb_erp A, 0xFB
	cpib_erp 0xFB, 0
	jrl nz, CmdHandler2C_SubCmd1
	cpdi8 17258, 8
	jrl nz, DSP_Process_ReadNext
	ldb_d8 a, 17259
	extz wa
	cps wa, 0
	jrl mi, CmdHandler2C_SubCmd0
	cp wa, 0x8
	jr le, CmdHandler2C_JumpDispatch
	sub wa, 0x17
	cp wa, 0x9
	jrl lt, CmdHandler2C_SubCmd0
	cp wa, 0xE
	jrl gt, CmdHandler2C_SubCmd0

CmdHandler2C_JumpDispatch:
	add wa, wa
	lda_24 xix, 0x0121bd
	ldw_sri WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0x035dd2
	jp_ind 8, 0x07, 0xF0, 0xE0
CmdHandler2C_TableData:
	.byte 0xc1, 0x70, 0x43, 0x21, 0xd8, 0x13, 0x1d, 0x23
	.byte 0x8b, 0x02, 0x78, 0x54, 0x02, 0xc1, 0x70, 0x43
	.byte 0x21, 0xd8, 0x12, 0x1d, 0x05, 0x62, 0x03, 0x78
	.byte 0x47, 0x02, 0xc1, 0x70, 0x43, 0x21, 0xd8, 0x12
	.byte 0x1d, 0x1c, 0x62, 0x03, 0x78, 0x3a, 0x02, 0xc1
	.byte 0x70, 0x43, 0x21, 0xd8, 0x12, 0x1d, 0x2e, 0x8d
	.byte 0x02, 0x78, 0x2d, 0x02, 0xc1, 0x70, 0x43, 0x21
	.byte 0xd8, 0x13, 0x1d, 0x30, 0x8b, 0x02, 0x78, 0x20
	.byte 0x02, 0xc1, 0x70, 0x43, 0x21, 0xd8, 0x12, 0x1d
	.byte 0x37, 0x62, 0x03, 0x78, 0x13, 0x02, 0xc1, 0x70
	.byte 0x43, 0x21, 0xd8, 0x12, 0x1d, 0x52, 0x62, 0x03
	.byte 0x78, 0x06, 0x02, 0xc1, 0x70, 0x43, 0x21, 0xd8
	.byte 0x12, 0x1d, 0x7a, 0x62, 0x03, 0x78, 0xf9, 0x01
	.byte 0xc1, 0x70, 0x43, 0x21, 0xd8, 0x12, 0x1d, 0xa2
	.byte 0x62, 0x03, 0x78, 0xec, 0x01, 0xc1, 0x70, 0x43
	.byte 0x21, 0xd8, 0x12, 0x1d, 0xb6, 0x62, 0x03, 0x78
	.byte 0xdf, 0x01, 0xc1, 0x70, 0x43, 0x21, 0xd8, 0x12
	.byte 0x1d, 0xca, 0x62, 0x03, 0x78, 0xd2, 0x01, 0xc1
	.byte 0x70, 0x43, 0x21, 0xd8, 0x12, 0x1d, 0xdd, 0x62
	.byte 0x03, 0x78, 0xc5, 0x01, 0xc1, 0x70, 0x43, 0x21
	.byte 0xd8, 0x12, 0x1d, 0xf1, 0x62, 0x03, 0x78, 0xb8
	.byte 0x01

CmdHandler2C_SubCmd0:
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip
	jrl DSP_Process_ReadNext

CmdHandler2C_SubCmd1:
	cp_erpb 0xFB, 0x30
	jrl c, CmdHandler2C_SubCmd6
	cp_erpb 0xFB, 0x3F
	jrl ugt, CmdHandler2C_SubCmd6
	cpdi8 17258, 127
	jrl nz, DSP_Process_ReadNext
	stb_erp A, 0xFB
	ldb_erp A, 0xF8
	extz iz
	and iz, 0xF
	lda_d16 xwa, 17264
	ld (xsp + 10), xwa
	ldb_d8 a, 17259
	cp a, 0x8
	jr z, CmdHandler2C_SubCmd5
	cps a, 6
	jr z, CmdHandler2C_SubCmd4
	cps a, 4
	jr z, CmdHandler2C_SubCmd3
	cps a, 3
	jrl z, DSP_Process_ReadNext
	cp a, 0x17
	jr ugt, CmdHandler2C_SubCmd2
	cp a, 0x10
	jrl nc, DSP_Process_ReadNext

CmdHandler2C_SubCmd2:
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip
	jrl DSP_Process_ReadNext

CmdHandler2C_SubCmd3:
	ldb_d8 a, 17264
	ld e, a
	extz de
	ldb_d8 a, 17265
	ld c, a
	extz bc
	ld wa, de
	call DSP_Reinit_VoiceSlots
	ldw wa, 0xFF
	ldw bc, 0xFF
	call DSP_VoiceState_Dispatch
	jrl DSP_Process_ReadNext

CmdHandler2C_SubCmd4:
	ldb_d8 a, 17264
	ld e, a
	extz de
	ldb_d8 a, 17265
	ld c, a
	extz bc
	ld wa, de
	call DSP_VoiceState_Dispatch
	jrl DSP_Process_ReadNext

CmdHandler2C_SubCmd5:
	call Voice_AllVoices_PortamentoUpdate
	jrl DSP_Process_ReadNext

CmdHandler2C_SubCmd6:
	cp_erpb 0xFB, 0x40
	jr nz, CmdHandler2C_Epilogue
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip
	jrl DSP_Process_ReadNext

CmdHandler2C_Epilogue:
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip
	jrl DSP_Process_ReadNext

DSP_CmdHandler_2D:
	ldb_d8 a, 17257
	ldb_erp A, 0xFB
	cpib_erp 0xFB, 0
	jrl nz, CmdHandler2D_PathD
	ldb_d8 a, 17258
	ldb_erp A, 0xFB
	cp_erpb 0xFB, 0x09
	jr nz, CmdHandler2D_PathA
	ld xwa, (xsp + 4)
	calr DSP_Cmd_LoadEffectPreset
	ld wa, hl
	exts xwa
	cp xwa, 0xFFFFFFFF
	jrl z, DSP_Process_ReadNext
	call DSP_ReconfigAndStatus
	jrl DSP_Process_ReadNext

CmdHandler2D_PathA:
	cp_erpb 0xFB, 0x0A
	jr c, CmdHandler2D_PathC
	cp_erpb 0xFB, 0x0E
	jr ugt, CmdHandler2D_PathC
	stb_erp A, 0xFB
	sub a, 0xA
	extz wa
	call EFF_GetSlotBuffer
	ld (xsp + 10), xhl
	ld xwa, (xsp + 10)
	cp xwa, 0xFFFFFFFF
	jrl z, DSP_Process_ReadNext
	ldb_d8 a, 17262
	ld c, a
	extz bc
	ld xwa, (xsp + 4)
	cp bc, (xwa + 4)
	jr ugt, CmdHandler2D_PathB
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 10)
	calr DSP_RingBuf_ReadAndCompare
	stb_erp A, 0xFB
	sub a, 0xA
	ldb_erp A, 0xF0
	extz ix
	lda_d16 xwa, 17264
	ld xbc, xwa
	ld e, l
	extz de
	ld wa, ix
	call DSP_ApplyConfig
	jr DSP_Process_ReadNext

CmdHandler2D_PathB:
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip
	jr DSP_Process_ReadNext

CmdHandler2D_PathC:
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip
	jr DSP_Process_ReadNext

CmdHandler2D_PathD:
	cp_erpb 0xFB, 0x30
	jr c, CmdHandler2D_EnqueueOrReturn
	cp_erpb 0xFB, 0x3F
	jr ugt, CmdHandler2D_EnqueueOrReturn
	ldb_d8 a, 17264
	lds32 xbc, 0
	ld c, a
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_ReadAndCompare
	cpdi8 17258, 127
	jr z, CmdHandler2D_MsgSizeMatch
	stb_erp A, 0xFB
	sub a, 0x30
	ldb_erp A, 0xF8
	extz iz
	jr DSP_Process_ReadNext

CmdHandler2D_MsgSizeMatch:
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip
	jr DSP_Process_ReadNext

CmdHandler2D_EnqueueOrReturn:
	cp_erpb 0xFB, 0x40
	jr nz, CmdHandler2D_QueuedPath
	ldb_d8 a, 17264
	lds32 xbc, 0
	ld c, a
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_ReadAndCompare
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip
	jr DSP_Process_ReadNext

CmdHandler2D_QueuedPath:
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip
	jr DSP_Process_ReadNext

DSP_Cmd_DefaultSkip:
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Skip

DSP_Process_ReadNext:
	ld xwa, (xsp + 4)
	calr DSP_RingBuf_Read
	ld (xsp + 12), hl
	ld wa, (xsp + 12)
	cps wa, 0
	jrl ge, DSP_Process_NextCmd

DSP_Process_Exit:
	pop xiz
	lda xsp, (xsp + 10)
	ret

DSP_WriteAlgoInitPreset:
	call DSP_State_LookupAlgoIndex
	ld wa, hl
	cps wa, 2
	jr nz, DSP_WriteAlgoInitPreset_PresetPath
	lda_24 xwa, 0x0121f3
	push xwa
	pushw 0x4
	call Audio_CmdHandler_00_1F
	inc 6, xsp
	jr DSP_WriteAlgoInitPreset_Epilogue

DSP_WriteAlgoInitPreset_PresetPath:
	cps wa, 1
	jr nz, DSP_WriteAlgoInitPreset_DefaultPath
	lda_24 xwa, 0x0121ef
	push xwa
	pushw 0x4
	call Audio_CmdHandler_00_1F
	inc 6, xsp
	jr DSP_WriteAlgoInitPreset_Epilogue

DSP_WriteAlgoInitPreset_DefaultPath:
	lda_24 xwa, 0x0121eb
	push xwa
	pushw 0x4
	call Audio_CmdHandler_00_1F
	inc 6, xsp

DSP_WriteAlgoInitPreset_Epilogue:
	jp MIDI_Dispatch

DSP_ApplyAlgoForVoiceType:
	cp wa, 0x35
	jr z, DSP_ApplyAlgoForVoiceType_TypeF
	cp wa, 0xF
	ret nz

DSP_ApplyAlgoForVoiceType_TypeF:
	ldmm16 17588, 17840	; LDW_16_16 (044b4h), (045b0h)
	lda_d16 xwa, 17550
	call DSP_State_ApplyBuf
	ret

DSP_Reset:
	pushw iz
	stdi16 17840, 1
	stdi16 17842, 0
	stdi16 17844, 0
	stdi16 17846, 0
	stdi16 17848, 0
	stdi16 17850, 0
	ldw_d16 xwa, 17842
	ldw_d16 xbc, 17844
	ldw_d16 xde, 17846
	call DSP_MixerCoeff_Compute
	ld xiy, 0xF01E
	ld xix, 0x448E
	ldw bc, 0x91
	ldirw
	lda_d16 xwa, 17550
	call DSP_State_LoadAndApplyAll
	stdi16 17554, 0
	call DSP_State_DmaLoadPresets
	ldw_d16 xiz, 61478
	ld wa, iz
	calr DSP_WriteAlgoInitPreset
	ld wa, iz
	calr DSP_ApplyAlgoForVoiceType
	ldw_d16 xwa, 17842
	ldw_d16 xbc, 17844
	ldw_d16 xde, 17846
	call DSP_MixerCoeff_Compute
	popw iz
	ret

DSP_ApplyAlgoForVoiceType_Data:
	.byte 0x0e

DSP_SlotState_DisplayRestore:
	lds wa, 0
	call DSP_SlotMuteState_ReadAndClear
	cps hl, 3
	jr nz, DSP_SlotState_DisplayRestore_ActivePath
	lda_24 xwa, 0x0121f3
	push xwa
	pushw 0x4
	call Audio_CmdHandler_00_1F
	inc 6, xsp
	jp MIDI_Dispatch

DSP_SlotState_DisplayRestore_ActivePath:
	cps hl, 2
	jr nz, DSP_SlotState_DisplayRestore_Epilogue
	lda_24 xwa, 0x0121ef
	push xwa
	pushw 0x4
	call Audio_CmdHandler_00_1F
	inc 6, xsp
	jp MIDI_Dispatch

DSP_SlotState_DisplayRestore_Epilogue:
	cps hl, 1
	ret nz
	lda_24 xwa, 0x0121eb
	push xwa
	pushw 0x4
	call Audio_CmdHandler_00_1F
	inc 6, xsp
	call MIDI_Dispatch
	ret

DSP_ApplyConfig:
	cp e, 0xFF
	jr nz, DSP_ApplyConfig_ActivePath
	stdi16 17550, 1
	jr DSP_ApplyConfig_InactivePath

DSP_ApplyConfig_ActivePath:
	stdi16 17550, 0

DSP_ApplyConfig_InactivePath:
	cps a, 3
	jr z, DSP_ApplyConfig_BufSelectB
	cps a, 4
	jr z, DSP_ApplyConfig_BufSelectA
	cps a, 2
	jr z, DSP_ApplyConfig_BufSelectA
	cps a, 1
	jr z, DSP_ApplyConfig_BufSelectA
	cps a, 0
	ret nz
	lda_d16 xwa, 17550
	call DSP_State_ApplyBuf
	ldw_d16 xwa, 17558
	jrl DSP_ApplyAlgoForVoiceType

DSP_ApplyConfig_BufSelectA:
	lda_d16 xwa, 17550
	jp DSP_State_ApplyBuf

DSP_ApplyConfig_BufSelectB:
	lda_d16 xbc, 17738
	lds wa, 0
	cpdi16 17850, 0
	jr z, DSP_ApplyConfig_Epilogue
	ldw_d16 xwa, 17848

DSP_ApplyConfig_Epilogue:
	ld (xbc), wa
	lda_d16 xwa, 17550
	call DSP_State_ApplyBuf
	ret

DSP_ReconfigAndStatus:
	lda_d16 xwa, 17550
	call DSP_State_ApplyBuf
	ldw_d16 xwa, 17558
	jrl DSP_ApplyAlgoForVoiceType

DSP_GetConfigBuffer:
	lda_d16 xhl, 17550
	ret

EFF_GetSlotBuffer:
	ld bc, wa
	cps bc, 4
	jr z, EFF_GetSlotBuffer_NoSlot
	cps bc, 3
	jr z, EFF_GetSlotBuffer_NoSlot
	cps bc, 2
	jr z, EFF_GetSlotBuffer_NoSlot
	cps bc, 1
	jr z, EFF_GetSlotBuffer_NoSlot
	cps bc, 0
	jr nz, EFF_GetSlotBuffer_LoopBody

EFF_GetSlotBuffer_NoSlot:
	mul wa, 0x38
	lda_d16 xbc, 17558
	extz xwa
	add xwa, xbc
	ld xhl, xwa
	jr EFF_GetSlotBuffer_Epilogue

EFF_GetSlotBuffer_LoopBody:
	ld xhl, 0xFFFFFFFF

EFF_GetSlotBuffer_Epilogue:
	ret

DSP_StateTable_DefaultData:
	.byte 0xd8, 0x12, 0xf1, 0xb2, 0x45, 0x50, 0xd1, 0xb4
	.byte 0x45, 0x21, 0xd1, 0xb6, 0x45, 0x22, 0x1b, 0x67
	.byte 0xc0, 0x03, 0xd1, 0xb2, 0x45, 0x23, 0x0e, 0xd8
	.byte 0x12, 0xf1, 0xb4, 0x45, 0x50, 0xd1, 0xb2, 0x45
	.byte 0x20, 0xd1, 0xb4, 0x45, 0x21, 0xd1, 0xb6, 0x45
	.byte 0x22, 0x1b, 0x67, 0xc0, 0x03, 0xd1, 0xb4, 0x45
	.byte 0x23, 0x0e, 0xd8, 0x12, 0xf1, 0xb6, 0x45, 0x50
	.byte 0xd1, 0xb2, 0x45, 0x20, 0xd1, 0xb4, 0x45, 0x21
	.byte 0xd1, 0xb6, 0x45, 0x22, 0x1b, 0x67, 0xc0, 0x03
	.byte 0xd1, 0xb6, 0x45, 0x23, 0x0e, 0xd8, 0x12, 0xf1
	.byte 0xb8, 0x45, 0x50, 0xd1, 0xba, 0x45, 0x3f, 0x00
	.byte 0x00, 0xb0, 0xf6, 0xf1, 0x8e, 0x44, 0x02, 0x00
	.byte 0x00, 0xd1, 0xb8, 0x45, 0x19, 0x4a, 0x45, 0xf1
	.byte 0x8e, 0x44, 0x30, 0x1d, 0x31, 0x8e, 0x03, 0x0e
	.byte 0xd1, 0xb8, 0x45, 0x23, 0x0e, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xf1, 0xba, 0x45, 0x51, 0xf1, 0x8e, 0x44
	.byte 0x02, 0x00, 0x00, 0xc9, 0xd8, 0x66, 0x08, 0xd1
	.byte 0xb8, 0x45, 0x19, 0x4a, 0x45, 0x68, 0x06, 0xf1
	.byte 0x4a, 0x45, 0x02, 0x00, 0x00, 0xf1, 0x8e, 0x44
	.byte 0x30, 0x1b, 0x31, 0x8e, 0x03, 0xf1, 0x8e, 0x44
	.byte 0x02, 0x00, 0x00, 0xd8, 0x12, 0xf1, 0x04, 0x45
	.byte 0x50, 0xf1, 0x8e, 0x44, 0x30, 0x1b, 0x31, 0x8e
	.byte 0x03, 0xf1, 0x8e, 0x44, 0x02, 0x00, 0x00, 0xd8
	.byte 0x12, 0xf1, 0x3c, 0x45, 0x50, 0xf1, 0x8e, 0x44
	.byte 0x30, 0x1b, 0x31, 0x8e, 0x03, 0xf1, 0x8e, 0x44
	.byte 0x02, 0x00, 0x00, 0xd8, 0x12, 0xf1, 0xb0, 0x45
	.byte 0x50, 0xd1, 0x96, 0x44, 0x20, 0x78, 0xaf, 0xfd
	.byte 0xf1, 0x8e, 0x44, 0x02, 0x00, 0x00, 0xd8, 0x12
	.byte 0xf1, 0x74, 0x45, 0x50, 0xf1, 0x8e, 0x44, 0x30
	.byte 0x1b, 0x31, 0x8e, 0x03, 0xf1, 0x8e, 0x44, 0x02
	.byte 0x00, 0x00, 0xd8, 0x12, 0xf1, 0xac, 0x45, 0x50
	.byte 0xf1, 0x8e, 0x44, 0x30, 0x1b, 0x31, 0x8e, 0x03

DSP_WaitForDelay:
	push xiz
	extz xwa
	inc 1, xwa
	srl xwa, 1
	addda32 xwa, 4160
	ld xiz, xwa
	cpdm32 4160, xiz
	jr nc, DSP_WaitForTaskSlot_Epilogue

DSP_WaitForTaskSlot_Loop:
	lds wa, 3
	call TaskSched_PreemptiveYield
	cpdm32 4160, xiz
	jr c, DSP_WaitForTaskSlot_Loop

DSP_WaitForTaskSlot_Epilogue:
	pop xiz
	ret

DSP_WaitForTaskSlot_Data:
	.byte 0x1b, 0x0f, 0x8e, 0x03

DSP_WakeAudioTask:
	lds wa, 1
	jp TaskSched_Wait

; ----------------------------------------------------------------------------
; DSP_Send_Command - Send a command byte to DSP chip
; Entry: BC = chip number (0=DSP1, 1=DSP2)
;        A  = command byte to send
; Exit:  HL = 0 on success, 1 on timeout
; Notes: Polls DSP status with timeout of 0x1F40 iterations (~8000)
;        Writes command byte to port PZ when DSP is ready
; ----------------------------------------------------------------------------
DSP_Send_Command:	; 036331h
	dec 8, xsp
	pushw iz
	ld (xsp + 6), bc	; Save chip number
	ld (xsp + 8), a	; Save command byte
	ldw (xsp + 4), 0x0	; Result = success
	ldw (xsp + 2), 0x1F40	; Timeout counter
	ei 6
	call DSP_Deassert_Read
	call DSP_Deassert_Write
	ld wa, (xsp + 6)
	call DSP_Select_Chip
	ld wa, (xsp + 6)
	call DSP_Read_Status
	ld iz, hl
	ld wa, (xsp + 6)
	call DSP_Deselect_Chip
	ei 0
	cps iz, 0
	jr nz, DSP_Send_Cmd_Ready

DSP_Send_Cmd_WaitLoop:
	ld wa, (xsp + 2)	; Get timeout counter
	decm 1, (xsp + 2)	; Decrement
	cps wa, 0
	jr nz, DSP_Send_Cmd_Poll
	ldw (xsp + 4), 0x1	; Timeout - set error
	jr DSP_Send_Cmd_Cleanup

DSP_Send_Cmd_Poll:
	ei 6
	call DSP_Deassert_Read
	call DSP_Deassert_Write
	ld wa, (xsp + 6)
	call DSP_Select_Chip
	ld wa, (xsp + 6)
	call DSP_Read_Status
	ld iz, hl
	ld wa, (xsp + 6)
	call DSP_Deselect_Chip
	ei 0
	cps iz, 0
	jr z, DSP_Send_Cmd_WaitLoop	; Still not ready, keep waiting

DSP_Send_Cmd_Ready:
	ei 6
	ld wa, (xsp + 6)
	call DSP_Deselect_Chip
	call DSP_Deassert_Read
	call DSP_Assert_Write
	call DSP_Set_Command_Mode
	ld wa, (xsp + 6)
	call DSP_Select_Chip
	ld wa, (xsp + 6)
	call DSP_Read_Status
	cps hl, 0
	jr z, DSP_Send_Cmd_Error
	ld a, (xsp + 8)	; Get command byte
	st_dd8b A, 0x68	; Write to DSP data port
	jr DSP_Send_Cmd_Cleanup

DSP_Send_Cmd_Error:
	ldw (xsp + 4), 0x1	; Set error flag

DSP_Send_Cmd_Cleanup:
	ld wa, (xsp + 6)
	call DSP_Deselect_Chip
	call DSP_Deassert_Write
	call DSP_Set_Data_Mode
	ei 0
	lda_24 xwa, 0x012207
	call Debug_Print_String
	ld a, (xsp + 8)
	extz wa
	call Debug_Print_Byte
	lda_24 xwa, 0x01220a
	call Debug_Print_String
	ld hl, (xsp + 4)	; Return result
	popw iz
	inc 8, xsp
	ret

DSP2_SPI_ClockPulseHigh:
	set_dd8 2, 0x3C
	jr __jrt_nop_03640F
__jrt_nop_03640F:

DSP2_ClkHigh_Nop01:
	nop
	jr __jrt_nop_036412
__jrt_nop_036412:

DSP2_ClkHigh_Nop02:
	nop
	jr __jrt_nop_036415
__jrt_nop_036415:

DSP2_ClkHigh_Nop03:
	nop
	jr __jrt_nop_036418
__jrt_nop_036418:

DSP2_ClkHigh_Nop04:
	nop
	jr __jrt_nop_03641B
__jrt_nop_03641B:

DSP2_ClkHigh_Nop05:
	nop
	jr __jrt_nop_03641E
__jrt_nop_03641E:

DSP2_ClkHigh_Nop06:
	nop
	jr __jrt_nop_036421
__jrt_nop_036421:

DSP2_ClkHigh_Nop07:
	nop
	jr __jrt_nop_036424
__jrt_nop_036424:

DSP2_ClkHigh_Nop08:
	nop
	jr __jrt_nop_036427
__jrt_nop_036427:

DSP2_ClkHigh_Nop09:
	nop
	jr __jrt_nop_03642A
__jrt_nop_03642A:

DSP2_ClkHigh_Nop10:
	nop
	jr __jrt_nop_03642D
__jrt_nop_03642D:

DSP2_ClkHigh_Nop11:
	nop
	jr __jrt_nop_036430
__jrt_nop_036430:

DSP2_ClkHigh_Nop12:
	nop
	jr __jrt_nop_036433
__jrt_nop_036433:

DSP2_ClkHigh_Nop13:
	nop
	jr __jrt_nop_036436
__jrt_nop_036436:

DSP2_ClkHigh_Nop14:
	nop
	jr __jrt_nop_036439
__jrt_nop_036439:

DSP2_ClkHigh_Nop15:
	nop
	jr __jrt_nop_03643C
__jrt_nop_03643C:

DSP2_ClkHigh_Nop16:
	nop
	jr __jrt_nop_03643F
__jrt_nop_03643F:

DSP2_ClkHigh_Nop17:
	nop
	jr __jrt_nop_036442
__jrt_nop_036442:

DSP2_ClkHigh_Nop18:
	nop
	jr __jrt_nop_036445
__jrt_nop_036445:

DSP2_ClkHigh_Nop19:
	nop
	set_dd8 0, 0x3C
	jr __jrt_nop_03644B
__jrt_nop_03644B:

DSP2_ClkHigh_Nop20:
	nop
	res_dd8 0, 0x3C
	jr __jrt_nop_036451
__jrt_nop_036451:

DSP2_ClkHigh_Nop21:
	nop
	jr __jrt_nop_036454
__jrt_nop_036454:

DSP2_ClkHigh_Nop22:
	nop
	jr __jrt_nop_036457
__jrt_nop_036457:

DSP2_ClkHigh_Nop23:
	nop
	jr __jrt_nop_03645A
__jrt_nop_03645A:

DSP2_ClkHigh_Nop24:
	nop
	jr __jrt_nop_03645D
__jrt_nop_03645D:

DSP2_ClkHigh_Nop25:
	nop
	jr __jrt_nop_036460
__jrt_nop_036460:

DSP2_ClkHigh_Nop26:
	nop
	jr __jrt_nop_036463
__jrt_nop_036463:

DSP2_ClkHigh_Nop27:
	nop
	jr __jrt_nop_036466
__jrt_nop_036466:

DSP2_ClkHigh_Nop28:
	nop
	jr __jrt_nop_036469
__jrt_nop_036469:

DSP2_ClkHigh_Nop29:
	nop
	jr __jrt_nop_03646C
__jrt_nop_03646C:

DSP2_ClkHigh_Nop30:
	nop
	jr __jrt_nop_03646F
__jrt_nop_03646F:

DSP2_ClkHigh_Nop31:
	nop
	jr __jrt_nop_036472
__jrt_nop_036472:

DSP2_ClkHigh_Nop32:
	nop
	jr __jrt_nop_036475
__jrt_nop_036475:

DSP2_ClkHigh_Nop33:
	nop
	jr __jrt_nop_036478
__jrt_nop_036478:

DSP2_ClkHigh_Nop34:
	nop
	jr __jrt_nop_03647B
__jrt_nop_03647B:

DSP2_ClkHigh_Nop35:
	nop
	jr __jrt_nop_03647E
__jrt_nop_03647E:

DSP2_ClkHigh_Nop36:
	nop
	res_dd8 2, 0x3C
	jr __jrt_nop_036484
__jrt_nop_036484:

DSP2_ClkHigh_Nop37:
	nop
	jr __jrt_nop_036487
__jrt_nop_036487:

DSP2_ClkHigh_Nop38:
	nop
	jr __jrt_nop_03648A
__jrt_nop_03648A:

DSP2_ClkHigh_Nop39:
	nop
	jr __jrt_nop_03648D
__jrt_nop_03648D:

DSP2_ClkHigh_Nop40:
	nop
	jr __jrt_nop_036490
__jrt_nop_036490:

DSP2_ClkHigh_Nop41:
	nop
	jr __jrt_nop_036493
__jrt_nop_036493:

DSP2_ClkHigh_Nop42:
	nop
	jr __jrt_nop_036496
__jrt_nop_036496:

DSP2_ClkHigh_Nop43:
	nop
	jr __jrt_nop_036499
__jrt_nop_036499:

DSP2_ClkHigh_Nop44:
	nop
	jr __jrt_nop_03649C
__jrt_nop_03649C:

DSP2_ClkHigh_Nop45:
	nop
	jr __jrt_nop_03649F
__jrt_nop_03649F:

DSP2_ClkHigh_Nop46:
	nop
	jr __jrt_nop_0364A2
__jrt_nop_0364A2:

DSP2_ClkHigh_Nop47:
	nop
	jr __jrt_nop_0364A5
__jrt_nop_0364A5:

DSP2_ClkHigh_Nop48:
	nop
	jr __jrt_nop_0364A8
__jrt_nop_0364A8:

DSP2_ClkHigh_Nop49:
	nop
	jr __jrt_nop_0364AB
__jrt_nop_0364AB:

DSP2_ClkHigh_Nop50:
	nop
	jr __jrt_nop_0364AE
__jrt_nop_0364AE:

DSP2_ClkHigh_Nop51:
	nop
	jr __jrt_nop_0364B1
__jrt_nop_0364B1:

DSP2_ClkHigh_Nop52:
	nop
	jr __jrt_nop_0364B4
__jrt_nop_0364B4:

DSP2_ClkHigh_Nop53:
	nop
	jr __jrt_nop_0364B7
__jrt_nop_0364B7:

DSP2_ClkHigh_Nop54:
	nop
	jr __jrt_nop_0364BA
__jrt_nop_0364BA:

DSP2_ClkHigh_Nop55:
	nop
	lda_24 xwa, 0x01220d
	jp Debug_Print_String

DSP2_SPI_BusIdle:
	res_dd8 2, 0x3C
	res_dd8 0, 0x3C
	jr __jrt_nop_0364CC
__jrt_nop_0364CC:

DSP2_BusIdle_Nop01:
	nop
	jr __jrt_nop_0364CF
__jrt_nop_0364CF:

DSP2_BusIdle_Nop02:
	nop
	jr __jrt_nop_0364D2
__jrt_nop_0364D2:

DSP2_BusIdle_Nop03:
	nop
	jr __jrt_nop_0364D5
__jrt_nop_0364D5:

DSP2_BusIdle_Nop04:
	nop
	jr __jrt_nop_0364D8
__jrt_nop_0364D8:

DSP2_BusIdle_Nop05:
	nop
	jr __jrt_nop_0364DB
__jrt_nop_0364DB:

DSP2_BusIdle_Nop06:
	nop
	jr __jrt_nop_0364DE
__jrt_nop_0364DE:

DSP2_BusIdle_Nop07:
	nop
	jr __jrt_nop_0364E1
__jrt_nop_0364E1:

DSP2_BusIdle_Nop08:
	nop
	jr __jrt_nop_0364E4
__jrt_nop_0364E4:

DSP2_BusIdle_Nop09:
	nop
	jr __jrt_nop_0364E7
__jrt_nop_0364E7:

DSP2_BusIdle_Nop10:
	nop
	jr __jrt_nop_0364EA
__jrt_nop_0364EA:

DSP2_BusIdle_Nop11:
	nop
	jr __jrt_nop_0364ED
__jrt_nop_0364ED:

DSP2_BusIdle_Nop12:
	nop
	jr __jrt_nop_0364F0
__jrt_nop_0364F0:

DSP2_BusIdle_Nop13:
	nop
	jr __jrt_nop_0364F3
__jrt_nop_0364F3:

DSP2_BusIdle_Nop14:
	nop
	jr __jrt_nop_0364F6
__jrt_nop_0364F6:

DSP2_BusIdle_Nop15:
	nop
	jr __jrt_nop_0364F9
__jrt_nop_0364F9:

DSP2_BusIdle_Nop16:
	nop
	jr __jrt_nop_0364FC
__jrt_nop_0364FC:

DSP2_BusIdle_Nop17:
	nop
	jr __jrt_nop_0364FF
__jrt_nop_0364FF:

DSP2_BusIdle_Nop18:
	nop
	jr __jrt_nop_036502
__jrt_nop_036502:

DSP2_BusIdle_Nop19:
	nop
	set_dd8 2, 0x3C
	jr __jrt_nop_036508
__jrt_nop_036508:

DSP2_BusIdle_Nop20:
	nop
	jr __jrt_nop_03650B
__jrt_nop_03650B:

DSP2_BusIdle_Nop21:
	nop
	jr __jrt_nop_03650E
__jrt_nop_03650E:

DSP2_BusIdle_Nop22:
	nop
	jr __jrt_nop_036511
__jrt_nop_036511:

DSP2_BusIdle_Nop23:
	nop
	jr __jrt_nop_036514
__jrt_nop_036514:

DSP2_BusIdle_Nop24:
	nop
	jr __jrt_nop_036517
__jrt_nop_036517:

DSP2_BusIdle_Nop25:
	nop
	jr __jrt_nop_03651A
__jrt_nop_03651A:

DSP2_BusIdle_Nop26:
	nop
	jr __jrt_nop_03651D
__jrt_nop_03651D:

DSP2_BusIdle_Nop27:
	nop
	jr __jrt_nop_036520
__jrt_nop_036520:

DSP2_BusIdle_Nop28:
	nop
	jr __jrt_nop_036523
__jrt_nop_036523:

DSP2_BusIdle_Nop29:
	nop
	jr __jrt_nop_036526
__jrt_nop_036526:

DSP2_BusIdle_Nop30:
	nop
	jr __jrt_nop_036529
__jrt_nop_036529:

DSP2_BusIdle_Nop31:
	nop
	jr __jrt_nop_03652C
__jrt_nop_03652C:

DSP2_BusIdle_Nop32:
	nop
	jr __jrt_nop_03652F
__jrt_nop_03652F:

DSP2_BusIdle_Nop33:
	nop
	jr __jrt_nop_036532
__jrt_nop_036532:

DSP2_BusIdle_Nop34:
	nop
	jr __jrt_nop_036535
__jrt_nop_036535:

DSP2_BusIdle_Nop35:
	nop
	jr __jrt_nop_036538
__jrt_nop_036538:

DSP2_BusIdle_Nop36:
	nop
	jr __jrt_nop_03653B
__jrt_nop_03653B:

DSP2_BusIdle_Nop37:
	nop
	jr __jrt_nop_03653E
__jrt_nop_03653E:

DSP2_BusIdle_Nop38:
	nop
	set_dd8 0, 0x3C
	jr __jrt_nop_036544
__jrt_nop_036544:

DSP2_BusIdle_Nop39:
	nop
	jr __jrt_nop_036547
__jrt_nop_036547:

DSP2_BusIdle_Nop40:
	nop
	jr __jrt_nop_03654A
__jrt_nop_03654A:

DSP2_BusIdle_Nop41:
	nop
	jr __jrt_nop_03654D
__jrt_nop_03654D:

DSP2_BusIdle_Nop42:
	nop
	jr __jrt_nop_036550
__jrt_nop_036550:

DSP2_BusIdle_Nop43:
	nop
	jr __jrt_nop_036553
__jrt_nop_036553:

DSP2_BusIdle_Nop44:
	nop
	jr __jrt_nop_036556
__jrt_nop_036556:

DSP2_BusIdle_Nop45:
	nop
	jr __jrt_nop_036559
__jrt_nop_036559:

DSP2_BusIdle_Nop46:
	nop
	jr __jrt_nop_03655C
__jrt_nop_03655C:

DSP2_BusIdle_Nop47:
	nop
	jr __jrt_nop_03655F
__jrt_nop_03655F:

DSP2_BusIdle_Nop48:
	nop
	jr __jrt_nop_036562
__jrt_nop_036562:

DSP2_BusIdle_Nop49:
	nop
	jr __jrt_nop_036565
__jrt_nop_036565:

DSP2_BusIdle_Nop50:
	nop
	jr __jrt_nop_036568
__jrt_nop_036568:

DSP2_BusIdle_Nop51:
	nop
	jr __jrt_nop_03656B
__jrt_nop_03656B:

DSP2_BusIdle_Nop52:
	nop
	jr __jrt_nop_03656E
__jrt_nop_03656E:

DSP2_BusIdle_Nop53:
	nop
	jr __jrt_nop_036571
__jrt_nop_036571:

DSP2_BusIdle_Nop54:
	nop
	jr __jrt_nop_036574
__jrt_nop_036574:

DSP2_BusIdle_Nop55:
	nop
	jr __jrt_nop_036577
__jrt_nop_036577:

DSP2_BusIdle_Nop56:
	nop
	jr __jrt_nop_03657A
__jrt_nop_03657A:

DSP2_BusIdle_Nop57:
	nop
	jr __jrt_nop_03657D
__jrt_nop_03657D:

DSP2_BusIdle_Nop58:
	nop
	jr __jrt_nop_036580
__jrt_nop_036580:

DSP2_BusIdle_Nop59:
	nop
	jr __jrt_nop_036583
__jrt_nop_036583:

DSP2_BusIdle_Nop60:
	nop
	jr __jrt_nop_036586
__jrt_nop_036586:

DSP2_BusIdle_Nop61:
	nop
	jr __jrt_nop_036589
__jrt_nop_036589:

DSP2_BusIdle_Nop62:
	nop
	jr __jrt_nop_03658C
__jrt_nop_03658C:

DSP2_BusIdle_Nop63:
	nop
	jr __jrt_nop_03658F
__jrt_nop_03658F:

DSP2_BusIdle_Nop64:
	nop
	jr __jrt_nop_036592
__jrt_nop_036592:

DSP2_BusIdle_Nop65:
	nop
	jr __jrt_nop_036595
__jrt_nop_036595:

DSP2_BusIdle_Nop66:
	nop
	jr __jrt_nop_036598
__jrt_nop_036598:

DSP2_BusIdle_Nop67:
	nop
	jr __jrt_nop_03659B
__jrt_nop_03659B:

DSP2_BusIdle_Nop68:
	nop
	jr __jrt_nop_03659E
__jrt_nop_03659E:

DSP2_BusIdle_Nop69:
	nop
	jr __jrt_nop_0365A1
__jrt_nop_0365A1:

DSP2_BusIdle_Nop70:
	nop
	jr __jrt_nop_0365A4
__jrt_nop_0365A4:

DSP2_BusIdle_Nop71:
	nop
	jr __jrt_nop_0365A7
__jrt_nop_0365A7:

DSP2_BusIdle_Nop72:
	nop
	jr __jrt_nop_0365AA
__jrt_nop_0365AA:

DSP2_BusIdle_Nop73:
	nop
	jr __jrt_nop_0365AD
__jrt_nop_0365AD:

DSP2_BusIdle_Nop74:
	nop
	jr __jrt_nop_0365B0
__jrt_nop_0365B0:

DSP2_BusIdle_Nop75:
	nop
	jr __jrt_nop_0365B3
__jrt_nop_0365B3:

DSP2_BusIdle_Nop76:
	nop
	jr __jrt_nop_0365B6
__jrt_nop_0365B6:

DSP2_BusIdle_Nop77:
	nop
	jr __jrt_nop_0365B9
__jrt_nop_0365B9:

DSP2_BusIdle_Nop78:
	nop
	jr __jrt_nop_0365BC
__jrt_nop_0365BC:

DSP2_BusIdle_Nop79:
	nop
	jr __jrt_nop_0365BF
__jrt_nop_0365BF:

DSP2_BusIdle_Nop80:
	nop
	jr __jrt_nop_0365C2
__jrt_nop_0365C2:

DSP2_BusIdle_Nop81:
	nop
	jr __jrt_nop_0365C5
__jrt_nop_0365C5:

DSP2_BusIdle_Nop82:
	nop
	jr __jrt_nop_0365C8
__jrt_nop_0365C8:

DSP2_BusIdle_Nop83:
	nop
	jr __jrt_nop_0365CB
__jrt_nop_0365CB:

DSP2_BusIdle_Nop84:
	nop
	jr __jrt_nop_0365CE
__jrt_nop_0365CE:

DSP2_BusIdle_Nop85:
	nop
	jr __jrt_nop_0365D1
__jrt_nop_0365D1:

DSP2_BusIdle_Nop86:
	nop
	jr __jrt_nop_0365D4
__jrt_nop_0365D4:

DSP2_BusIdle_Nop87:
	nop
	jr __jrt_nop_0365D7
__jrt_nop_0365D7:

DSP2_BusIdle_Nop88:
	nop
	jr __jrt_nop_0365DA
__jrt_nop_0365DA:

DSP2_BusIdle_Nop89:
	nop
	jr __jrt_nop_0365DD
__jrt_nop_0365DD:

DSP2_BusIdle_Nop90:
	nop
	jr __jrt_nop_0365E0
__jrt_nop_0365E0:

DSP2_BusIdle_Nop91:
	nop
	jr __jrt_nop_0365E3
__jrt_nop_0365E3:

DSP2_BusIdle_Nop92:
	nop
	jr __jrt_nop_0365E6
__jrt_nop_0365E6:

DSP2_BusIdle_Nop93:
	nop
	jr __jrt_nop_0365E9
__jrt_nop_0365E9:

DSP2_BusIdle_Nop94:
	nop
	jr __jrt_nop_0365EC
__jrt_nop_0365EC:

DSP2_BusIdle_Nop95:
	nop
	jr __jrt_nop_0365EF
__jrt_nop_0365EF:

DSP2_BusIdle_Nop96:
	nop
	jr __jrt_nop_0365F2
__jrt_nop_0365F2:

DSP2_BusIdle_Nop97:
	nop
	jr __jrt_nop_0365F5
__jrt_nop_0365F5:

DSP2_BusIdle_Nop98:
	nop
	jr __jrt_nop_0365F8
__jrt_nop_0365F8:

DSP2_BusIdle_Nop99:
	nop
	jr __jrt_nop_0365FB
__jrt_nop_0365FB:

DSP2_BusIdle_Nop100:
	nop
	jr __jrt_nop_0365FE
__jrt_nop_0365FE:

DSP2_BusIdle_Nop101:
	nop
	jr __jrt_nop_036601
__jrt_nop_036601:

DSP2_BusIdle_Nop102:
	nop
	jr __jrt_nop_036604
__jrt_nop_036604:

DSP2_BusIdle_Nop103:
	nop
	jr __jrt_nop_036607
__jrt_nop_036607:

DSP2_BusIdle_Nop104:
	nop
	jr __jrt_nop_03660A
__jrt_nop_03660A:

DSP2_BusIdle_Nop105:
	nop
	jr __jrt_nop_03660D
__jrt_nop_03660D:

DSP2_BusIdle_Nop106:
	nop
	jr __jrt_nop_036610
__jrt_nop_036610:

DSP2_BusIdle_Nop107:
	nop
	jr __jrt_nop_036613
__jrt_nop_036613:

DSP2_BusIdle_Nop108:
	nop
	jr __jrt_nop_036616
__jrt_nop_036616:

DSP2_BusIdle_Nop109:
	nop
	jr __jrt_nop_036619
__jrt_nop_036619:

DSP2_BusIdle_Nop110:
	nop
	jr __jrt_nop_03661C
__jrt_nop_03661C:

DSP2_BusIdle_Nop111:
	nop
	jr __jrt_nop_03661F
__jrt_nop_03661F:

DSP2_BusIdle_Nop112:
	nop
	jr __jrt_nop_036622
__jrt_nop_036622:

DSP2_BusIdle_Nop113:
	nop
	jr __jrt_nop_036625
__jrt_nop_036625:

DSP2_BusIdle_Nop114:
	nop
	jr __jrt_nop_036628
__jrt_nop_036628:

DSP2_BusIdle_Nop115:
	nop
	jr __jrt_nop_03662B
__jrt_nop_03662B:

DSP2_BusIdle_Nop116:
	nop
	jr __jrt_nop_03662E
__jrt_nop_03662E:

DSP2_BusIdle_Nop117:
	nop
	jr __jrt_nop_036631
__jrt_nop_036631:

DSP2_BusIdle_Nop118:
	nop
	jr __jrt_nop_036634
__jrt_nop_036634:

DSP2_BusIdle_Nop119:
	nop
	jr __jrt_nop_036637
__jrt_nop_036637:

DSP2_BusIdle_Nop120:
	nop
	jr __jrt_nop_03663A
__jrt_nop_03663A:

DSP2_BusIdle_Nop121:
	nop
	jr __jrt_nop_03663D
__jrt_nop_03663D:

DSP2_BusIdle_Nop122:
	nop
	jr __jrt_nop_036640
__jrt_nop_036640:

DSP2_BusIdle_Nop123:
	nop
	jr __jrt_nop_036643
__jrt_nop_036643:

DSP2_BusIdle_Nop124:
	nop
	jr __jrt_nop_036646
__jrt_nop_036646:

DSP2_BusIdle_Nop125:
	nop
	jr __jrt_nop_036649
__jrt_nop_036649:

DSP2_BusIdle_Nop126:
	nop
	jr __jrt_nop_03664C
__jrt_nop_03664C:

DSP2_BusIdle_Nop127:
	nop
	jr __jrt_nop_03664F
__jrt_nop_03664F:

DSP2_BusIdle_Nop128:
	nop
	jr __jrt_nop_036652
__jrt_nop_036652:

DSP2_BusIdle_Nop129:
	nop
	jr __jrt_nop_036655
__jrt_nop_036655:

DSP2_BusIdle_Nop130:
	nop
	jr __jrt_nop_036658
__jrt_nop_036658:

DSP2_BusIdle_Nop131:
	nop
	jr __jrt_nop_03665B
__jrt_nop_03665B:

DSP2_BusIdle_Nop132:
	nop
	jr __jrt_nop_03665E
__jrt_nop_03665E:

DSP2_BusIdle_Nop133:
	nop
	jr __jrt_nop_036661
__jrt_nop_036661:

DSP2_BusIdle_Nop134:
	nop
	lda_24 xwa, 0x012215
	jp Debug_Print_String

DSP2_Send_Command:
	dec 6, xsp
	push xiz
	ld (xsp + 6), bc
	ld (xsp + 8), a
	ldw (xsp + 4), 0x0
	calr DSP_WakeAudioTask
	ei 6
	ld a, (xsp + 8)
	ldb_erp A, 0xFB
	ld wa, (xsp + 6)
	call DSP_Select_Chip
	calr DSP2_SPI_ClockPulseHigh
	ldw iz, 0x8
	cps iz, 0
	jrl le, DSP2_SendCmd_PostLoop_Entry

DSP2_SendCmd_BitLoop:
	bit_erpb 0xFB, 0x07
	jr z, DSP2_SendCmd_BitClear
	set_dd8 0, 0x3C
	jr DSP2_SendCmd_BitSet_Done

DSP2_SendCmd_BitClear:
	res_dd8 0, 0x3C

DSP2_SendCmd_BitSet_Done:
	jr __jrt_nop_0366A6
__jrt_nop_0366A6:

DSP2_SendCmd_ClkHigh_Nop01:
	nop
	sll_erpb 0xFB, 0x01
	set_dd8 2, 0x3C
	jr __jrt_nop_0366B0
__jrt_nop_0366B0:

DSP2_SendCmd_ClkHigh_Nop02:
	nop
	jr __jrt_nop_0366B3
__jrt_nop_0366B3:

DSP2_SendCmd_ClkHigh_Nop03:
	nop
	jr __jrt_nop_0366B6
__jrt_nop_0366B6:

DSP2_SendCmd_ClkHigh_Nop04:
	nop
	jr __jrt_nop_0366B9
__jrt_nop_0366B9:

DSP2_SendCmd_ClkHigh_Nop05:
	nop
	jr __jrt_nop_0366BC
__jrt_nop_0366BC:

DSP2_SendCmd_ClkHigh_Nop06:
	nop
	jr __jrt_nop_0366BF
__jrt_nop_0366BF:

DSP2_SendCmd_ClkHigh_Nop07:
	nop
	jr __jrt_nop_0366C2
__jrt_nop_0366C2:

DSP2_SendCmd_ClkHigh_Nop08:
	nop
	jr __jrt_nop_0366C5
__jrt_nop_0366C5:

DSP2_SendCmd_ClkHigh_Nop09:
	nop
	jr __jrt_nop_0366C8
__jrt_nop_0366C8:

DSP2_SendCmd_ClkHigh_Nop10:
	nop
	jr __jrt_nop_0366CB
__jrt_nop_0366CB:

DSP2_SendCmd_ClkHigh_Nop11:
	nop
	jr __jrt_nop_0366CE
__jrt_nop_0366CE:

DSP2_SendCmd_ClkHigh_Nop12:
	nop
	jr __jrt_nop_0366D1
__jrt_nop_0366D1:

DSP2_SendCmd_ClkHigh_Nop13:
	nop
	jr __jrt_nop_0366D4
__jrt_nop_0366D4:

DSP2_SendCmd_ClkHigh_Nop14:
	nop
	jr __jrt_nop_0366D7
__jrt_nop_0366D7:

DSP2_SendCmd_ClkHigh_Nop15:
	nop
	jr __jrt_nop_0366DA
__jrt_nop_0366DA:

DSP2_SendCmd_ClkHigh_Nop16:
	nop
	jr __jrt_nop_0366DD
__jrt_nop_0366DD:

DSP2_SendCmd_ClkLow_Nop01:
	nop
	res_dd8 2, 0x3C
	jr __jrt_nop_0366E3
__jrt_nop_0366E3:

DSP2_SendCmd_ClkLow_Nop02:
	nop
	jr __jrt_nop_0366E6
__jrt_nop_0366E6:

DSP2_SendCmd_ClkLow_Nop03:
	nop
	jr __jrt_nop_0366E9
__jrt_nop_0366E9:

DSP2_SendCmd_ClkLow_Nop04:
	nop
	jr __jrt_nop_0366EC
__jrt_nop_0366EC:

DSP2_SendCmd_ClkLow_Nop05:
	nop
	jr __jrt_nop_0366EF
__jrt_nop_0366EF:

DSP2_SendCmd_ClkLow_Nop06:
	nop
	jr __jrt_nop_0366F2
__jrt_nop_0366F2:

DSP2_SendCmd_ClkLow_Nop07:
	nop
	jr __jrt_nop_0366F5
__jrt_nop_0366F5:

DSP2_SendCmd_ClkLow_Nop08:
	nop
	jr __jrt_nop_0366F8
__jrt_nop_0366F8:

DSP2_SendCmd_ClkLow_Nop09:
	nop
	jr __jrt_nop_0366FB
__jrt_nop_0366FB:

DSP2_SendCmd_ClkLow_Nop10:
	nop
	jr __jrt_nop_0366FE
__jrt_nop_0366FE:

DSP2_SendCmd_ClkLow_Nop11:
	nop
	jr __jrt_nop_036701
__jrt_nop_036701:

DSP2_SendCmd_ClkLow_Nop12:
	nop
	jr __jrt_nop_036704
__jrt_nop_036704:

DSP2_SendCmd_ClkLow_Nop13:
	nop
	jr __jrt_nop_036707
__jrt_nop_036707:

DSP2_SendCmd_ClkLow_Nop14:
	nop
	jr __jrt_nop_03670A
__jrt_nop_03670A:

DSP2_SendCmd_ClkLow_Nop15:
	nop
	jr __jrt_nop_03670D
__jrt_nop_03670D:

DSP2_SendCmd_ClkLow_Nop16:
	nop
	jr __jrt_nop_036710
__jrt_nop_036710:

DSP2_SendCmd_ClkLow_Nop17:
	nop
	jr __jrt_nop_036713
__jrt_nop_036713:

DSP2_SendCmd_ClkLow_Nop18:
	nop
	jr __jrt_nop_036716
__jrt_nop_036716:

DSP2_SendCmd_ClkLow_Nop19:
	nop
	jr __jrt_nop_036719
__jrt_nop_036719:

DSP2_SendCmd_ClkLow_Nop20:
	nop
	sub iz, 0x1
	jrl gt, DSP2_SendCmd_BitLoop

DSP2_SendCmd_PostLoop_Entry:
	jr __jrt_nop_036723
__jrt_nop_036723:

DSP2_SendCmd_PostLoop_Nop01:
	nop
	set_dd8 2, 0x3C
	jr __jrt_nop_036729
__jrt_nop_036729:

DSP2_SendCmd_PostLoop_Nop02:
	nop
	jr __jrt_nop_03672C
__jrt_nop_03672C:

DSP2_SendCmd_PostLoop_Nop03:
	nop
	jr __jrt_nop_03672F
__jrt_nop_03672F:

DSP2_SendCmd_PostLoop_Nop04:
	nop
	jr __jrt_nop_036732
__jrt_nop_036732:

DSP2_SendCmd_PostLoop_Nop05:
	nop
	jr __jrt_nop_036735
__jrt_nop_036735:

DSP2_SendCmd_PostLoop_Nop06:
	nop
	jr __jrt_nop_036738
__jrt_nop_036738:

DSP2_SendCmd_PostLoop_Nop07:
	nop
	jr __jrt_nop_03673B
__jrt_nop_03673B:

DSP2_SendCmd_PostLoop_Nop08:
	nop
	jr __jrt_nop_03673E
__jrt_nop_03673E:

DSP2_SendCmd_PostLoop_Nop09:
	nop
	jr __jrt_nop_036741
__jrt_nop_036741:

DSP2_SendCmd_PostLoop_Nop10:
	nop
	jr __jrt_nop_036744
__jrt_nop_036744:

DSP2_SendCmd_PostLoop_Nop11:
	nop
	jr __jrt_nop_036747
__jrt_nop_036747:

DSP2_SendCmd_PostLoop_Nop12:
	nop
	jr __jrt_nop_03674A
__jrt_nop_03674A:

DSP2_SendCmd_PostLoop_Nop13:
	nop
	jr __jrt_nop_03674D
__jrt_nop_03674D:

DSP2_SendCmd_PostLoop_Nop14:
	nop
	jr __jrt_nop_036750
__jrt_nop_036750:

DSP2_SendCmd_PostLoop_Nop15:
	nop
	jr __jrt_nop_036753
__jrt_nop_036753:

DSP2_SendCmd_PostLoop_Nop16:
	nop
	jr __jrt_nop_036756
__jrt_nop_036756:

DSP2_SendCmd_PostLoop_Nop17:
	nop
	res_dd8 2, 0x3C
	jr __jrt_nop_03675C
__jrt_nop_03675C:

DSP2_SendCmd_PostClkLow_Nop01:
	nop
	jr __jrt_nop_03675F
__jrt_nop_03675F:

DSP2_SendCmd_PostClkLow_Nop02:
	nop
	jr __jrt_nop_036762
__jrt_nop_036762:

DSP2_SendCmd_PostClkLow_Nop03:
	nop
	jr __jrt_nop_036765
__jrt_nop_036765:

DSP2_SendCmd_PostClkLow_Nop04:
	nop
	jr __jrt_nop_036768
__jrt_nop_036768:

DSP2_SendCmd_PostClkLow_Nop05:
	nop
	jr __jrt_nop_03676B
__jrt_nop_03676B:

DSP2_SendCmd_PostClkLow_Nop06:
	nop
	jr __jrt_nop_03676E
__jrt_nop_03676E:

DSP2_SendCmd_PostClkLow_Nop07:
	nop
	jr __jrt_nop_036771
__jrt_nop_036771:

DSP2_SendCmd_PostClkLow_Nop08:
	nop
	jr __jrt_nop_036774
__jrt_nop_036774:

DSP2_SendCmd_PostClkLow_Nop09:
	nop
	jr __jrt_nop_036777
__jrt_nop_036777:

DSP2_SendCmd_PostClkLow_Nop10:
	nop
	jr __jrt_nop_03677A
__jrt_nop_03677A:

DSP2_SendCmd_PostClkLow_Nop11:
	nop
	jr __jrt_nop_03677D
__jrt_nop_03677D:

DSP2_SendCmd_PostClkLow_Nop12:
	nop
	jr __jrt_nop_036780
__jrt_nop_036780:

DSP2_SendCmd_PostClkLow_Nop13:
	nop
	jr __jrt_nop_036783
__jrt_nop_036783:

DSP2_SendCmd_PostClkLow_Nop14:
	nop
	jr __jrt_nop_036786
__jrt_nop_036786:

DSP2_SendCmd_PostClkLow_Nop15:
	nop
	jr __jrt_nop_036789
__jrt_nop_036789:

DSP2_SendCmd_PostClkLow_Nop16:
	nop
	jr __jrt_nop_03678C
__jrt_nop_03678C:

DSP2_SendCmd_PostClkLow_Nop17:
	nop
	jr __jrt_nop_03678F
__jrt_nop_03678F:

DSP2_SendCmd_PostClkLow_Nop18:
	nop
	jr __jrt_nop_036792
__jrt_nop_036792:

DSP2_SendCmd_PostClkLow_Nop19:
	nop
	ld wa, (xsp + 6)
	call DSP_Deselect_Chip
	jr __jrt_nop_03679C
__jrt_nop_03679C:

DSP2_SendCmd_Epilogue_Nop01:
	nop
	jr __jrt_nop_03679F
__jrt_nop_03679F:

DSP2_SendCmd_Epilogue_Nop02:
	nop
	jr __jrt_nop_0367A2
__jrt_nop_0367A2:

DSP2_SendCmd_Epilogue_Nop03:
	nop
	jr __jrt_nop_0367A5
__jrt_nop_0367A5:

DSP2_SendCmd_Epilogue_Nop04:
	nop
	jr __jrt_nop_0367A8
__jrt_nop_0367A8:

DSP2_SendCmd_Epilogue_Nop05:
	nop
	jr __jrt_nop_0367AB
__jrt_nop_0367AB:

DSP2_SendCmd_Epilogue_Nop06:
	nop
	jr __jrt_nop_0367AE
__jrt_nop_0367AE:

DSP2_SendCmd_Epilogue_Nop07:
	nop
	jr __jrt_nop_0367B1
__jrt_nop_0367B1:

DSP2_SendCmd_Epilogue_Nop08:
	nop
	jr __jrt_nop_0367B4
__jrt_nop_0367B4:

DSP2_SendCmd_Epilogue_Nop09:
	nop
	jr __jrt_nop_0367B7
__jrt_nop_0367B7:

DSP2_SendCmd_Epilogue_Nop10:
	nop
	jr __jrt_nop_0367BA
__jrt_nop_0367BA:

DSP2_SendCmd_Epilogue_Nop11:
	nop
	jr __jrt_nop_0367BD
__jrt_nop_0367BD:

DSP2_SendCmd_Epilogue_Nop12:
	nop
	jr __jrt_nop_0367C0
__jrt_nop_0367C0:

DSP2_SendCmd_Epilogue_Nop13:
	nop
	jr __jrt_nop_0367C3
__jrt_nop_0367C3:

DSP2_SendCmd_Epilogue_Nop14:
	nop
	jr __jrt_nop_0367C6
__jrt_nop_0367C6:

DSP2_SendCmd_Epilogue_Nop15:
	nop
	jr __jrt_nop_0367C9
__jrt_nop_0367C9:

DSP2_SendCmd_Epilogue_Nop16:
	nop
	ei 0
	lda_24 xwa, 0x01221d
	call Debug_Print_String
	ld a, (xsp + 8)
	extz wa
	call Debug_Print_Byte
	lda_24 xwa, 0x01221f
	call Debug_Print_String
	ld hl, (xsp + 4)
	pop xiz
	inc 6, xsp
	ret

; ----------------------------------------------------------------------------
; DSP_Send_Data - Send a data byte to DSP chip
; Entry: BC = chip number (0=DSP1, 1=DSP2)
;        A  = data byte to send
; Exit:  HL = 0 on success, 1 on timeout
; Notes: Similar to DSP_Send_Command but uses data mode
; ----------------------------------------------------------------------------
DSP_Send_Data:	; 0367EEh
	dec 8, xsp
	pushw iz
	ld (xsp + 6), bc	; Save chip number
	ld (xsp + 8), a	; Save data byte
	ldw (xsp + 4), 0x0	; Result = success
	ldw (xsp + 2), 0x1F40	; Timeout counter
	ei 6
	call DSP_Deassert_Read
	call DSP_Deassert_Write
	ld wa, (xsp + 6)
	call DSP_Select_Chip
	ld wa, (xsp + 6)
	call DSP_Read_Status
	ld iz, hl
	ld wa, (xsp + 6)
	call DSP_Deselect_Chip
	ei 0
	cps iz, 0
	jr nz, DSP_Send_Data_Ready

DSP_Send_Data_WaitLoop:
	ld wa, (xsp + 2)
	decm 1, (xsp + 2)
	cps wa, 0
	jr nz, DSP_Send_Data_Poll
	ldw (xsp + 4), 0x1	; Timeout error
	jr DSP_Send_Data_Cleanup

DSP_Send_Data_Poll:
	ei 6
	call DSP_Deassert_Read
	call DSP_Deassert_Write
	ld wa, (xsp + 6)
	call DSP_Select_Chip
	ld wa, (xsp + 6)
	call DSP_Read_Status
	ld iz, hl
	ld wa, (xsp + 6)
	call DSP_Deselect_Chip
	ei 0
	cps iz, 0
	jr z, DSP_Send_Data_WaitLoop

DSP_Send_Data_Ready:
	ei 6
	call DSP_Set_Data_Mode	; Set data mode (unlike command routine)
	ld wa, (xsp + 6)
	call DSP_Deselect_Chip
	call DSP_Deassert_Read
	call DSP_Assert_Write
	ld wa, (xsp + 6)
	call DSP_Select_Chip
	ld wa, (xsp + 6)
	call DSP_Read_Status
	cps hl, 0
	jr z, DSP_Send_Data_Error
	ld a, (xsp + 8)	; Get data byte
	st_dd8b A, 0x68	; Write to DSP data port
	jr DSP_Send_Data_Cleanup

DSP_Send_Data_Error:
	ldw (xsp + 4), 0x1

DSP_Send_Data_Cleanup:
	ld wa, (xsp + 6)
	call DSP_Deselect_Chip
	call DSP_Deassert_Write
	ei 0
	ld a, (xsp + 8)
	extz wa
	call Debug_Print_Byte
	lda_24 xwa, 0x012222
	call Debug_Print_String
	ld hl, (xsp + 4)	; Return result
	popw iz
	inc 8, xsp
	ret

DSP2_Send_Data:
	dec 6, xsp
	push xiz
	ld (xsp + 6), bc
	ld (xsp + 8), a
	ldw (xsp + 4), 0x0
	ei 6
	ld a, (xsp + 8)
	ldb_erp A, 0xFB
	ld wa, (xsp + 6)
	call DSP_Select_Chip
	ldw iz, 0x8
	cps iz, 0
	jrl le, DSP2_SendData_PostLoop_Entry

DSP2_SendData_BitLoop:
	bit_erpb 0xFB, 0x07
	jr z, DSP2_SendData_BitClear
	set_dd8 0, 0x3C
	jr DSP2_SendData_BitSet_Done

DSP2_SendData_BitClear:
	res_dd8 0, 0x3C

DSP2_SendData_BitSet_Done:
	jr __jrt_nop_0368EF
__jrt_nop_0368EF:

DSP2_SendData_ClkHigh_Nop01:
	nop
	sll_erpb 0xFB, 0x01
	set_dd8 2, 0x3C
	jr __jrt_nop_0368F9
__jrt_nop_0368F9:

DSP2_SendData_ClkHigh_Nop02:
	nop
	jr __jrt_nop_0368FC
__jrt_nop_0368FC:

DSP2_SendData_ClkHigh_Nop03:
	nop
	jr __jrt_nop_0368FF
__jrt_nop_0368FF:

DSP2_SendData_ClkHigh_Nop04:
	nop
	jr __jrt_nop_036902
__jrt_nop_036902:

DSP2_SendData_ClkHigh_Nop05:
	nop
	jr __jrt_nop_036905
__jrt_nop_036905:

DSP2_SendData_ClkHigh_Nop06:
	nop
	jr __jrt_nop_036908
__jrt_nop_036908:

DSP2_SendData_ClkHigh_Nop07:
	nop
	jr __jrt_nop_03690B
__jrt_nop_03690B:

DSP2_SendData_ClkHigh_Nop08:
	nop
	jr __jrt_nop_03690E
__jrt_nop_03690E:

DSP2_SendData_ClkHigh_Nop09:
	nop
	jr __jrt_nop_036911
__jrt_nop_036911:

DSP2_SendData_ClkHigh_Nop10:
	nop
	jr __jrt_nop_036914
__jrt_nop_036914:

DSP2_SendData_ClkHigh_Nop11:
	nop
	jr __jrt_nop_036917
__jrt_nop_036917:

DSP2_SendData_ClkHigh_Nop12:
	nop
	jr __jrt_nop_03691A
__jrt_nop_03691A:

DSP2_SendData_ClkHigh_Nop13:
	nop
	jr __jrt_nop_03691D
__jrt_nop_03691D:

DSP2_SendData_ClkHigh_Nop14:
	nop
	jr __jrt_nop_036920
__jrt_nop_036920:

DSP2_SendData_ClkHigh_Nop15:
	nop
	jr __jrt_nop_036923
__jrt_nop_036923:

DSP2_SendData_ClkHigh_Nop16:
	nop
	jr __jrt_nop_036926
__jrt_nop_036926:

DSP2_SendData_ClkHigh_Nop17:
	nop
	res_dd8 2, 0x3C
	jr __jrt_nop_03692C
__jrt_nop_03692C:

DSP2_SendData_ClkLow_Nop01:
	nop
	jr __jrt_nop_03692F
__jrt_nop_03692F:

DSP2_SendData_ClkLow_Nop02:
	nop
	jr __jrt_nop_036932
__jrt_nop_036932:

DSP2_SendData_ClkLow_Nop03:
	nop
	jr __jrt_nop_036935
__jrt_nop_036935:

DSP2_SendData_ClkLow_Nop04:
	nop
	jr __jrt_nop_036938
__jrt_nop_036938:

DSP2_SendData_ClkLow_Nop05:
	nop
	jr __jrt_nop_03693B
__jrt_nop_03693B:

DSP2_SendData_ClkLow_Nop06:
	nop
	jr __jrt_nop_03693E
__jrt_nop_03693E:

DSP2_SendData_ClkLow_Nop07:
	nop
	jr __jrt_nop_036941
__jrt_nop_036941:

DSP2_SendData_ClkLow_Nop08:
	nop
	jr __jrt_nop_036944
__jrt_nop_036944:

DSP2_SendData_ClkLow_Nop09:
	nop
	jr __jrt_nop_036947
__jrt_nop_036947:

DSP2_SendData_ClkLow_Nop10:
	nop
	jr __jrt_nop_03694A
__jrt_nop_03694A:

DSP2_SendData_ClkLow_Nop11:
	nop
	jr __jrt_nop_03694D
__jrt_nop_03694D:

DSP2_SendData_ClkLow_Nop12:
	nop
	jr __jrt_nop_036950
__jrt_nop_036950:

DSP2_SendData_ClkLow_Nop13:
	nop
	jr __jrt_nop_036953
__jrt_nop_036953:

DSP2_SendData_ClkLow_Nop14:
	nop
	jr __jrt_nop_036956
__jrt_nop_036956:

DSP2_SendData_ClkLow_Nop15:
	nop
	jr __jrt_nop_036959
__jrt_nop_036959:

DSP2_SendData_ClkLow_Nop16:
	nop
	jr __jrt_nop_03695C
__jrt_nop_03695C:

DSP2_SendData_ClkLow_Nop17:
	nop
	jr __jrt_nop_03695F
__jrt_nop_03695F:

DSP2_SendData_ClkLow_Nop18:
	nop
	jr __jrt_nop_036962
__jrt_nop_036962:

DSP2_SendData_ClkLow_Nop19:
	nop
	sub iz, 0x1
	jrl gt, DSP2_SendData_BitLoop

DSP2_SendData_PostLoop_Entry:
	jr __jrt_nop_03696C
__jrt_nop_03696C:

DSP2_SendData_PostLoop_Nop01:
	nop
	set_dd8 2, 0x3C
	jr __jrt_nop_036972
__jrt_nop_036972:

DSP2_SendData_PostLoop_Nop02:
	nop
	jr __jrt_nop_036975
__jrt_nop_036975:

DSP2_SendData_PostLoop_Nop03:
	nop
	jr __jrt_nop_036978
__jrt_nop_036978:

DSP2_SendData_PostLoop_Nop04:
	nop
	jr __jrt_nop_03697B
__jrt_nop_03697B:

DSP2_SendData_PostLoop_Nop05:
	nop
	jr __jrt_nop_03697E
__jrt_nop_03697E:

DSP2_SendData_PostLoop_Nop06:
	nop
	jr __jrt_nop_036981
__jrt_nop_036981:

DSP2_SendData_PostLoop_Nop07:
	nop
	jr __jrt_nop_036984
__jrt_nop_036984:

DSP2_SendData_PostLoop_Nop08:
	nop
	jr __jrt_nop_036987
__jrt_nop_036987:

DSP2_SendData_PostLoop_Nop09:
	nop
	jr __jrt_nop_03698A
__jrt_nop_03698A:

DSP2_SendData_PostLoop_Nop10:
	nop
	jr __jrt_nop_03698D
__jrt_nop_03698D:

DSP2_SendData_PostLoop_Nop11:
	nop
	jr __jrt_nop_036990
__jrt_nop_036990:

DSP2_SendData_PostLoop_Nop12:
	nop
	jr __jrt_nop_036993
__jrt_nop_036993:

DSP2_SendData_PostLoop_Nop13:
	nop
	jr __jrt_nop_036996
__jrt_nop_036996:

DSP2_SendData_PostLoop_Nop14:
	nop
	jr __jrt_nop_036999
__jrt_nop_036999:

DSP2_SendData_PostLoop_Nop15:
	nop
	jr __jrt_nop_03699C
__jrt_nop_03699C:

DSP2_SendData_PostLoop_Nop16:
	nop
	jr __jrt_nop_03699F
__jrt_nop_03699F:

DSP2_SendData_PostLoop_Nop17:
	nop
	res_dd8 2, 0x3C
	jr __jrt_nop_0369A5
__jrt_nop_0369A5:

DSP2_SendData_PostClkLow_Nop01:
	nop
	jr __jrt_nop_0369A8
__jrt_nop_0369A8:

DSP2_SendData_PostClkLow_Nop02:
	nop
	jr __jrt_nop_0369AB
__jrt_nop_0369AB:

DSP2_SendData_PostClkLow_Nop03:
	nop
	jr __jrt_nop_0369AE
__jrt_nop_0369AE:

DSP2_SendData_PostClkLow_Nop04:
	nop
	jr __jrt_nop_0369B1
__jrt_nop_0369B1:

DSP2_SendData_PostClkLow_Nop05:
	nop
	jr __jrt_nop_0369B4
__jrt_nop_0369B4:

DSP2_SendData_PostClkLow_Nop06:
	nop
	jr __jrt_nop_0369B7
__jrt_nop_0369B7:

DSP2_SendData_PostClkLow_Nop07:
	nop
	jr __jrt_nop_0369BA
__jrt_nop_0369BA:

DSP2_SendData_PostClkLow_Nop08:
	nop
	jr __jrt_nop_0369BD
__jrt_nop_0369BD:

DSP2_SendData_PostClkLow_Nop09:
	nop
	jr __jrt_nop_0369C0
__jrt_nop_0369C0:

DSP2_SendData_PostClkLow_Nop10:
	nop
	jr __jrt_nop_0369C3
__jrt_nop_0369C3:

DSP2_SendData_PostClkLow_Nop11:
	nop
	jr __jrt_nop_0369C6
__jrt_nop_0369C6:

DSP2_SendData_PostClkLow_Nop12:
	nop
	jr __jrt_nop_0369C9
__jrt_nop_0369C9:

DSP2_SendData_PostClkLow_Nop13:
	nop
	jr __jrt_nop_0369CC
__jrt_nop_0369CC:

DSP2_SendData_PostClkLow_Nop14:
	nop
	jr __jrt_nop_0369CF
__jrt_nop_0369CF:

DSP2_SendData_PostClkLow_Nop15:
	nop
	jr __jrt_nop_0369D2
__jrt_nop_0369D2:

DSP2_SendData_PostClkLow_Nop16:
	nop
	jr __jrt_nop_0369D5
__jrt_nop_0369D5:

DSP2_SendData_PostClkLow_Nop17:
	nop
	jr __jrt_nop_0369D8
__jrt_nop_0369D8:

DSP2_SendData_PostClkLow_Nop18:
	nop
	jr __jrt_nop_0369DB
__jrt_nop_0369DB:

DSP2_SendData_PostClkLow_Nop19:
	nop
	ld wa, (xsp + 6)
	call DSP_Deselect_Chip
	jr __jrt_nop_0369E5
__jrt_nop_0369E5:

DSP2_SendData_Epilogue_Nop01:
	nop
	jr __jrt_nop_0369E8
__jrt_nop_0369E8:

DSP2_SendData_Epilogue_Nop02:
	nop
	jr __jrt_nop_0369EB
__jrt_nop_0369EB:

DSP2_SendData_Epilogue_Nop03:
	nop
	jr __jrt_nop_0369EE
__jrt_nop_0369EE:

DSP2_SendData_Epilogue_Nop04:
	nop
	jr __jrt_nop_0369F1
__jrt_nop_0369F1:

DSP2_SendData_Epilogue_Nop05:
	nop
	jr __jrt_nop_0369F4
__jrt_nop_0369F4:

DSP2_SendData_Epilogue_Nop06:
	nop
	jr __jrt_nop_0369F7
__jrt_nop_0369F7:

DSP2_SendData_Epilogue_Nop07:
	nop
	jr __jrt_nop_0369FA
__jrt_nop_0369FA:

DSP2_SendData_Epilogue_Nop08:
	nop
	jr __jrt_nop_0369FD
__jrt_nop_0369FD:

DSP2_SendData_Epilogue_Nop09:
	nop
	jr __jrt_nop_036A00
__jrt_nop_036A00:

DSP2_SendData_Epilogue_Nop10:
	nop
	jr __jrt_nop_036A03
__jrt_nop_036A03:

DSP2_SendData_Epilogue_Nop11:
	nop
	jr __jrt_nop_036A06
__jrt_nop_036A06:

DSP2_SendData_Epilogue_Nop12:
	nop
	jr __jrt_nop_036A09
__jrt_nop_036A09:

DSP2_SendData_Epilogue_Nop13:
	nop
	jr __jrt_nop_036A0C
__jrt_nop_036A0C:

DSP2_SendData_Epilogue_Nop14:
	nop
	jr __jrt_nop_036A0F
__jrt_nop_036A0F:

DSP2_SendData_Epilogue_Nop15:
	nop
	jr __jrt_nop_036A12
__jrt_nop_036A12:

DSP2_SendData_Epilogue_Nop16:
	nop
	ei 0
	ld a, (xsp + 8)
	extz wa
	call Debug_Print_Byte
	lda_24 xwa, 0x012224
	call Debug_Print_String
	ld hl, (xsp + 4)
	pop xiz
	inc 6, xsp
	ret

DSP_DispatchCommand:
	pushw iz
	lds iz, 0
	ld de, bc
	cps de, 1
	jr z, DSP_DispatchCommand_DSP2Path
	cps de, 0
	jr nz, DSP_DispatchCommand_InvalidChip
	extz wa
	calr DSP_Send_Command
	jr DSP_DispatchCommand_Epilogue

DSP_DispatchCommand_DSP2Path:
	extz wa
	calr DSP2_Send_Command
	jr DSP_DispatchCommand_Epilogue

DSP_DispatchCommand_InvalidChip:
	inc 1, iz

DSP_DispatchCommand_Epilogue:
	ld hl, iz
	popw iz
	ret

DSP_DispatchData:
	pushw iz
	lds iz, 0
	ld de, bc
	cps de, 1
	jr z, DSP_DispatchData_DSP2Path
	cps de, 0
	jr nz, DSP_DispatchData_InvalidChip
	extz wa
	calr DSP_Send_Data
	jr DSP_DispatchData_Epilogue

DSP_DispatchData_DSP2Path:
	extz wa
	calr DSP2_Send_Data
	jr DSP_DispatchData_Epilogue

DSP_DispatchData_InvalidChip:
	inc 1, iz

DSP_DispatchData_Epilogue:
	ld hl, iz
	popw iz
	ret

DSP_StateTable_Reset:
	ld xiy, xwa
	ld xix, 0x45CA
	ldw bc, 0x91
	ldirw
	ret

DSP_AlgoChange_CheckAndFlag:
	ld bc, (xwa + 6)
	cpda16 xbc, 17872
	jr nz, DSP_AlgoChange_NoChange
	cpw (xwa + 2), 0x1
	jr z, DSP_AlgoChange_NoChange
	cpw (xwa + 4), 0x1
	jr nz, DSP_AlgoChange_FlagAndClear

DSP_AlgoChange_NoChange:
	stdi16 18750, 1
	ret

DSP_AlgoChange_FlagAndClear:
	stdi16 18750, 0
	ret

DSP_SlotParam_DiffAndFlag:
	lds hl, 0
	cps hl, 5
	ret nc

DSP_SlotParam_DiffLoop:
	ld bc, hl
	mul bc, 0x38
	lda_d16 xde, 17874
	ld ix, bc
	extz xix
	add xix, xde
	ld bc, hl
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	sll xde, 3
	inc 8, xde
	add xde, xwa
	ld bc, (xde)
	cp bc, (xix)
	jr z, DSP_SlotParam_DiffMatch
	ld bc, hl
	mul bc, 0x32
	lda_d16 xde, 18752
	extz xbc
	add xbc, xde
	ldw (xbc), 0x1
	jr DSP_SlotParam_DiffMismatch

DSP_SlotParam_DiffMatch:
	ld bc, hl
	mul bc, 0x32
	lda_d16 xde, 18752
	extz xbc
	add xbc, xde
	ldw (xbc), 0x0

DSP_SlotParam_DiffMismatch:
	inc 1, hl
	cps hl, 5
	jr c, DSP_SlotParam_DiffLoop
	ret

DSP_EFFParam_DiffAllAndFlag:
	push xiz
	lds de, 0
	cps de, 5
	jrl nc, DSP_EFFParam_DiffEpilogue

DSP_EFFParam_DiffOuter:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18784
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0
	lds hl, 0
	cps hl, 1
	jrl nc, DSP_EFFParam_DiffInner

DSP_EFFParam_DiffMid:
	ld ix, hl
	add ix, ix
	ld bc, de
	mul bc, 0x38
	add bc, ix
	lda_d16 xix, 17876
	ld iz, bc
	extz xiz
	add xiz, xix
	ld bc, hl
	extz xbc
	ld xix, xbc
	add xix, xix
	ld bc, de
	extz xbc
	ld xiy, xbc
	sll xiy, 3
	sub xiy, xbc
	sll xiy, 3
	add xiy, xix
	add xiy, xwa
	ld bc, (xiy + 10)
	cp bc, (xiz)
	jr z, DSP_EFFParam_DiffMidMatch
	ld ix, hl
	add ix, ix
	ld bc, de
	mul bc, 0x32
	add bc, ix
	lda_d16 xix, 18754
	extz xbc
	add xbc, xix
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xix, 18784
	extz xbc
	add xbc, xix
	ldw (xbc), 0x1
	jr DSP_EFFParam_DiffMidNext

DSP_EFFParam_DiffMidMatch:
	ld ix, hl
	add ix, ix
	ld bc, de
	mul bc, 0x32
	add bc, ix
	lda_d16 xix, 18754
	extz xbc
	add xbc, xix
	ldw (xbc), 0x0

DSP_EFFParam_DiffMidNext:
	inc 1, hl
	cps hl, 1
	jrl c, DSP_EFFParam_DiffMid

DSP_EFFParam_DiffInner:
	lds hl, 0
	cp hl, 0x11
	jrl nc, DSP_EFFParam_DiffLevel4

DSP_EFFParam_DiffInnerBody:
	ld ix, hl
	add ix, ix
	ld bc, de
	mul bc, 0x38
	add bc, ix
	lda_d16 xix, 17878
	ld iz, bc
	extz xiz
	add xiz, xix
	ld bc, hl
	extz xbc
	ld xix, xbc
	add xix, xix
	ld bc, de
	extz xbc
	ld xiy, xbc
	sll xiy, 3
	sub xiy, xbc
	sll xiy, 3
	add xiy, xix
	add xiy, xwa
	ld bc, (xiy + 12)
	cp bc, (xiz)
	jr z, DSP_EFFParam_DiffInnerMatch
	ld ix, hl
	add ix, ix
	ld bc, de
	mul bc, 0x32
	add bc, ix
	lda_d16 xix, 18756
	extz xbc
	add xbc, xix
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xix, 18784
	extz xbc
	add xbc, xix
	ldw (xbc), 0x1
	jr DSP_EFFParam_DiffInnerNext

DSP_EFFParam_DiffInnerMatch:
	ld ix, hl
	add ix, ix
	ld bc, de
	mul bc, 0x32
	add bc, ix
	lda_d16 xix, 18756
	extz xbc
	add xbc, xix
	ldw (xbc), 0x0

DSP_EFFParam_DiffInnerNext:
	inc 1, hl
	cp hl, 0x11
	jrl c, DSP_EFFParam_DiffInnerBody

DSP_EFFParam_DiffLevel4:
	lds hl, 0
	cps hl, 1
	jrl nc, DSP_EFFParam_DiffAlgoSection

DSP_EFFParam_DiffLevel4Body:
	ld ix, hl
	add ix, ix
	ld bc, de
	mul bc, 0x38
	add bc, ix
	lda_d16 xix, 17914
	ld iz, bc
	extz xiz
	add xiz, xix
	ld bc, hl
	extz xbc
	ld xix, xbc
	add xix, xix
	ld bc, de
	extz xbc
	ld xiy, xbc
	sll xiy, 3
	sub xiy, xbc
	sll xiy, 3
	add xiy, xix
	add xiy, xwa
	ld bc, (xiy + 48)
	cp bc, (xiz)
	jr z, DSP_EFFParam_DiffLevel4Match
	ld ix, hl
	add ix, ix
	ld bc, de
	mul bc, 0x32
	add bc, ix
	lda_d16 xix, 18790
	extz xbc
	add xbc, xix
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xix, 18784
	extz xbc
	add xbc, xix
	ldw (xbc), 0x1
	jr DSP_EFFParam_DiffLevel4Next

DSP_EFFParam_DiffLevel4Match:
	ld ix, hl
	add ix, ix
	ld bc, de
	mul bc, 0x32
	add bc, ix
	lda_d16 xix, 18790
	extz xbc
	add xbc, xix
	ldw (xbc), 0x0

DSP_EFFParam_DiffLevel4Next:
	inc 1, hl
	cps hl, 1
	jrl c, DSP_EFFParam_DiffLevel4Body

DSP_EFFParam_DiffAlgoSection:
	ld bc, de
	mul bc, 0x38
	inc 8, bc
	lda_d16 xhl, 17920
	ld ix, bc
	extz xix
	add xix, xhl
	ld bc, de
	extz xbc
	ld xhl, xbc
	sll xhl, 3
	sub xhl, xbc
	sll xhl, 3
	inc 8, xhl
	add xhl, xwa
	ld bc, (xhl + 54)
	cp bc, (xix)
	jr z, DSP_EFFParam_AlgoChangePath
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18782
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18784
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	jr DSP_EFFParam_DiffOuterNext

DSP_EFFParam_AlgoChangePath:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18782
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0

DSP_EFFParam_DiffOuterNext:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18776
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18778
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18780
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0
	inc 1, de
	cps de, 5
	jrl c, DSP_EFFParam_DiffOuter

DSP_EFFParam_DiffEpilogue:
	pop xiz
	ret

DSP_State_DiffAll:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr DSP_AlgoChange_CheckAndFlag
	ld xwa, xiz
	calr DSP_SlotParam_DiffAndFlag
	ld xwa, xiz
	calr DSP_EFFParam_DiffAllAndFlag
	pop xiz
	ret

DSP_State_DiffAndPrepare:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr DSP_State_DiffAll
	ld xwa, xiz
	calr EFF_StateLoad_Prepare
	pop xiz
	ret

DSP_Config_ClampLimits:
	cpw (xwa + 6), 0x1
	jr ule, DSP_Config_ClampLoop
	ldw (xwa + 6), 0x0

DSP_Config_ClampLoop:
	lds hl, 0
	cps hl, 5
	ret nc

DSP_Config_ClampApply:
	ld bc, hl
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	sll xde, 3
	inc 8, xde
	add xde, xwa
	cpw (xde), 0x63
	jr ule, DSP_Config_ClampNext
	ld bc, hl
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	sll xde, 3
	inc 8, xde
	add xde, xwa
	ldw (xde), 0x63

DSP_Config_ClampNext:
	inc 1, hl
	cps hl, 5
	jr c, DSP_Config_ClampApply
	ret

DSP_Config_ClampData:
	.byte 0xd2, 0x66, 0x55, 0x04, 0x23, 0xd2, 0x44, 0x54
	.byte 0x04, 0x83, 0x0e

DSP_SlotMuteState_ReadAndClear:
	ld bc, wa
	add bc, bc
	lda_d16 xde, 17852
	extz xbc
	add xbc, xde
	ld hl, (xbc)
	add wa, wa
	lda_d16 xbc, 17852
	extz xwa
	add xwa, xbc
	ldw (xwa), 0x0
	ret

; --- CalcSampleAddr: Compute sample address from 2-byte index ---
; Entry: XWA = pointer to structure with byte[0] and byte[1]
; Exit: XHL = XWA + computed offset (address into sample data)
;   offset = (byte[0] << 8) + byte[1], capped at 0xF0
CalcSampleAddr:
	ld	c, (xwa+1)
	and	c, 255
	ld	e, c
	extz	de
	ld	c, (xwa)
	extz	bc
	sll	bc, 8
	ld	hl, bc
	ldb	l, 0
	add	hl, de
	ld	bc, hl
	srl	bc, 8
	cp	bc, 240
	jr	z, 6
	ld	bc, hl
	extz	xbc
	add	xwa, xbc
	ld	xhl, xwa
	ret

DSP_State_ApplyAll:
	push xiz
	ld xiz, xwa
	stdi16 17864, 0
	ld xwa, xiz
	calr DSP_Config_ClampLimits
	ld xwa, xiz
	calr DSP_State_DiffAndPrepare
	ld xwa, xiz
	calr DSP_State_Dispatcher
	ld xwa, xiz
	calr DSP_StateTable_Reset
	ldw_d16 xhl, 17864
	pop xiz
	ret

EFF_SlotActive_UpdateFlags:
	lds de, 0
	cpdi16 18750, 1
	jr nz, EFF_SlotActive_SlotActive
	lds hl, 0
	cps hl, 5
	ret nc

EFF_SlotActive_CheckSlot:
	ld wa, hl
	add wa, wa
	lda_d16 xbc, 18736
	extz xwa
	add xwa, xbc
	ldw (xwa), 0x1
	inc 1, hl
	cps hl, 5
	jr c, EFF_SlotActive_CheckSlot
	ret

EFF_SlotActive_SlotActive:
	lds hl, 0
	cps hl, 5
	ret nc

EFF_SlotActive_SlotInactive:
	ld bc, hl
	extz xbc
	ld xix, xbc
	sll xix, 3
	sub xix, xbc
	sll xix, 3
	inc 8, xix
	add xix, xwa
	ld bc, (xix)
	cp bc, 0x33
	jr z, EFF_SlotActive_VoiceCheck
	cp bc, 0x34
	jr z, EFF_SlotActive_VoiceCheck
	cp bc, 0x45
	jr z, EFF_SlotActive_VoiceCheck
	cp bc, 0x46
	jr nz, EFF_SlotActive_VoiceInactive

EFF_SlotActive_VoiceCheck:
	lds de, 1

EFF_SlotActive_VoiceInactive:
	ld bc, hl
	mul bc, 0x32
	lda_d16 xix, 18752
	extz xbc
	add xbc, xix
	cpw (xbc), 0x1
	jr z, EFF_SlotActive_LoopNext
	cpw (xwa), 0x1
	jr nz, EFF_SlotActive_AlgoCheck
	ld bc, hl
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xix, 18784
	extz xbc
	add xbc, xix
	cpw (xbc), 0x1
	jr z, EFF_SlotActive_LoopNext

EFF_SlotActive_AlgoCheck:
	ld bc, hl
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xix, 18784
	extz xbc
	add xbc, xix
	cpw (xbc), 0x1
	jrl nz, EFF_SlotActive_InnerLoopNext
	cps de, 1
	jrl nz, EFF_SlotActive_InnerLoopNext

EFF_SlotActive_LoopNext:
	ld bc, hl
	add bc, bc
	lda_d16 xix, 18736
	extz xbc
	add xbc, xix
	ldw (xbc), 0x1
	ld bc, hl
	extz xbc
	ld xix, xbc
	sll xix, 3
	sub xix, xbc
	sll xix, 3
	inc 8, xix
	add xix, xwa
	ld ix, (xix + 38)
	sll ix, 1
	ld bc, hl
	mul bc, 0x32
	add bc, ix
	lda_d16 xix, 18756
	extz xbc
	add xbc, xix
	ldw (xbc), 0x1
	ld bc, hl
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xix, 18778
	extz xbc
	add xbc, xix
	ldw (xbc), 0x1
	ld bc, hl
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xix, 18780
	extz xbc
	add xbc, xix
	ldw (xbc), 0x1
	ld bc, hl
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xix, 18784
	extz xbc
	add xbc, xix
	ldw (xbc), 0x1
	ld bc, hl
	extz xbc
	ld xix, xbc
	sll xix, 3
	sub xix, xbc
	sll xix, 3
	inc 8, xix
	add xix, xwa
	cpw (xix + 48), 0x63
	jr z, EFF_SlotActive_Epilogue
	ld bc, hl
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xix, 18776
	extz xbc
	add xbc, xix
	ldw (xbc), 0x1
	jr EFF_SlotActive_Epilogue

EFF_SlotActive_InnerLoopNext:
	ld bc, hl
	add bc, bc
	lda_d16 xix, 18736
	extz xbc
	add xbc, xix
	ldw (xbc), 0x0

EFF_SlotActive_Epilogue:
	inc 1, hl
	cps hl, 5
	jrl c, EFF_SlotActive_SlotInactive
	ret

EFF_DSPLink_ResetFlags:
	cpdi16 18750, 1
	jr nz, EFF_DSPLink_ResetFlags_LoopNext
	stdi16 18746, 1
	lds de, 1
	cps de, 2
	ret nc

EFF_DSPLink_ResetFlags_ZeroPath:
	ld wa, de
	add wa, wa
	lda_d16 xbc, 18746
	extz xwa
	add xwa, xbc
	ldw (xwa), 0x0
	inc 1, de
	cps de, 2
	jr c, EFF_DSPLink_ResetFlags_ZeroPath
	ret

EFF_DSPLink_ResetFlags_LoopNext:
	lds de, 0
	cps de, 2
	ret nc

EFF_DSPLink_ResetFlags_InnerBody:
	ld wa, de
	add wa, wa
	lda_d16 xbc, 18746
	extz xwa
	add xwa, xbc
	ldw (xwa), 0x0
	inc 1, de
	cps de, 2
	jr c, EFF_DSPLink_ResetFlags_InnerBody
	ret

EFF_DspChannel_InitFlags:
	lds de, 0
	cps de, 5
	ret nc

EFF_DspChannel_Init_AlgoCheck:
	cpdi16 18750, 1
	jr nz, EFF_DspChannel_Init_SlotNext
	ld bc, de
	mul bc, 0x32
	lda_d16 xhl, 18752
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1

EFF_DspChannel_Init_SlotNext:
	ld bc, de
	mul bc, 0x32
	lda_d16 xhl, 18752
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jrl nz, EFF_DspChannel_Init_OuterNext
	lds ix, 0
	cp ix, 0x11
	jr nc, EFF_DspChannel_Init_CoeffLoop

EFF_DspChannel_Init_FreqLoop:
	ld hl, ix
	add hl, hl
	ld bc, de
	mul bc, 0x32
	add bc, hl
	lda_d16 xhl, 18756
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	inc 1, ix
	cp ix, 0x11
	jr c, EFF_DspChannel_Init_FreqLoop

EFF_DspChannel_Init_CoeffLoop:
	lds ix, 0
	cps ix, 1
	jr nc, EFF_DspChannel_Init_Coeff2Loop

EFF_DspChannel_Init_CoeffNext:
	ld hl, ix
	add hl, hl
	ld bc, de
	mul bc, 0x32
	add bc, hl
	lda_d16 xhl, 18754
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	inc 1, ix
	cps ix, 1
	jr c, EFF_DspChannel_Init_CoeffNext

EFF_DspChannel_Init_Coeff2Loop:
	lds ix, 0
	cps ix, 1
	jr nc, EFF_DspChannel_Init_MultiTableDirty

EFF_DspChannel_Init_Coeff2Next:
	ld hl, ix
	add hl, hl
	ld bc, de
	mul bc, 0x32
	add bc, hl
	lda_d16 xhl, 18790
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	inc 1, ix
	cps ix, 1
	jr c, EFF_DspChannel_Init_Coeff2Next

EFF_DspChannel_Init_MultiTableDirty:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18776
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18778
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18780
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18782
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18784
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	cps de, 1
	jr nz, EFF_DspChannel_Init_OuterNext
	ld bc, (xwa + 46)
	inc 1, bc
	ld hl, (xwa + 8)
	cp hl, 0x35
	jr z, EFF_DspChannel_Init_AlgoTypePath
	cp hl, 0xF
	jr z, EFF_DspChannel_Init_AlgoTypePath
	add bc, bc
	add bc, 0x14
	lda_d16 xhl, 18736
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	jr EFF_DspChannel_Init_OuterNext

EFF_DspChannel_Init_AlgoTypePath:
	inc 1, bc
	add bc, bc
	add bc, 0x14
	lda_d16 xhl, 18736
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1

EFF_DspChannel_Init_OuterNext:
	ld bc, de
	extz xbc
	ld xhl, xbc
	sll xhl, 3
	sub xhl, xbc
	sll xhl, 3
	inc 8, xhl
	add xhl, xwa
	cpw (xhl), 0x27
	jrl nz, EFF_DspChanInit_AlgoType9_Dirty
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18740
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr z, EFF_DspChanInit_AlgoType0_Dirty
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18742
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr z, EFF_DspChanInit_AlgoType0_Dirty
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18744
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr nz, EFF_DspChanInit_AlgoType1_Dirty

EFF_DspChanInit_AlgoType0_Dirty:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18740
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18742
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18744
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0

EFF_DspChanInit_AlgoType1_Dirty:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18746
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr z, EFF_DspChanInit_AlgoType2_Dirty
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18748
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr z, EFF_DspChanInit_AlgoType2_Dirty
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18750
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr nz, EFF_DspChanInit_AlgoType3_Dirty

EFF_DspChanInit_AlgoType2_Dirty:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18746
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18748
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18750
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0

EFF_DspChanInit_AlgoType3_Dirty:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18752
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr z, EFF_DspChanInit_AlgoType4_Dirty
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18754
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr z, EFF_DspChanInit_AlgoType4_Dirty
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18756
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr nz, EFF_DspChanInit_AlgoType5_Dirty

EFF_DspChanInit_AlgoType4_Dirty:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18752
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18754
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18756
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0

EFF_DspChanInit_AlgoType5_Dirty:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18758
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr z, EFF_DspChanInit_AlgoType6_Dirty
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18760
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr z, EFF_DspChanInit_AlgoType6_Dirty
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18762
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr nz, EFF_DspChanInit_AlgoType7_Dirty

EFF_DspChanInit_AlgoType6_Dirty:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18758
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18760
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18762
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0

EFF_DspChanInit_AlgoType7_Dirty:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18764
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr z, EFF_DspChanInit_AlgoType8_Dirty
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18766
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr z, EFF_DspChanInit_AlgoType8_Dirty
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18768
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr nz, EFF_DspChanInit_AlgoType9_Dirty

EFF_DspChanInit_AlgoType8_Dirty:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18764
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18766
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18768
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0

EFF_DspChanInit_AlgoType9_Dirty:
	ld bc, de
	extz xbc
	ld xhl, xbc
	sll xhl, 3
	sub xhl, xbc
	sll xhl, 3
	inc 8, xhl
	add xhl, xwa
	cpw (xhl), 0x4F
	jrl nz, EFF_DspChanInit_AlgoType4F_Epilogue
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18742
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr nz, EFF_DspChanInit_AlgoType4F_SubA
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18740
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18742
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0

EFF_DspChanInit_AlgoType4F_SubA:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18746
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr nz, EFF_DspChanInit_AlgoType4F_SubB
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18744
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18746
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0

EFF_DspChanInit_AlgoType4F_SubB:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18750
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr nz, EFF_DspChanInit_AlgoType4F_SubC
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18748
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18750
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0

EFF_DspChanInit_AlgoType4F_SubC:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18754
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr nz, EFF_DspChanInit_AlgoType4F_Epilogue
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18752
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18754
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x0

EFF_DspChanInit_AlgoType4F_Epilogue:
	ld bc, de
	extz xbc
	ld xhl, xbc
	sll xhl, 3
	sub xhl, xbc
	sll xhl, 3
	inc 8, xhl
	add xhl, xwa
	cpw (xhl), 0x35
	jr z, EFF_DspChanInit_AlgoType35_Dirty
	ld bc, de
	extz xbc
	ld xhl, xbc
	sll xhl, 3
	sub xhl, xbc
	sll xhl, 3
	inc 8, xhl
	add xhl, xwa
	cpw (xhl), 0xF
	jrl nz, EFF_DspChanInit_AlgoType35_SubC

EFF_DspChanInit_AlgoType35_Dirty:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18766
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jrl nz, EFF_DspChanInit_AlgoType35_SubC
	ld bc, de
	extz xbc
	ld xhl, xbc
	sll xhl, 3
	sub xhl, xbc
	sll xhl, 3
	inc 8, xhl
	add xhl, xwa
	cpw (xhl + 30), 0x1
	jr nz, EFF_DspChanInit_AlgoType35_SubA
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18746
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18756
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18750
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18760
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	jr EFF_DspChanInit_AlgoType35_SubB

EFF_DspChanInit_AlgoType35_SubA:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18748
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18758
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18752
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18762
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1

EFF_DspChanInit_AlgoType35_SubB:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18784
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1
	jr EFF_DspChanInit_AlgoType35_SubF

EFF_DspChanInit_AlgoType35_SubC:
	ld bc, de
	extz xbc
	ld xhl, xbc
	sll xhl, 3
	sub xhl, xbc
	sll xhl, 3
	inc 8, xhl
	add xhl, xwa
	cpw (xhl), 0x3F
	jr nz, EFF_DspChanInit_AlgoType35_SubE
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18742
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr z, EFF_DspChanInit_AlgoType35_SubD
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18744
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr nz, EFF_DspChanInit_AlgoType35_SubE

EFF_DspChanInit_AlgoType35_SubD:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18740
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1

EFF_DspChanInit_AlgoType35_SubE:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18784
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1

EFF_DspChanInit_AlgoType35_SubF:
	ld bc, de
	mul bc, 0x32
	add bc, 0x10
	lda_d16 xhl, 18782
	extz xbc
	add xbc, xhl
	cpw (xbc), 0x1
	jr nz, EFF_DspChanInit_AlgoType35_Epilogue
	ld bc, de
	extz xbc
	ld xhl, xbc
	sll xhl, 3
	sub xhl, xbc
	sll xhl, 3
	inc 8, xhl
	add xhl, xwa
	ld hl, (xhl + 38)
	sll hl, 1
	ld bc, de
	mul bc, 0x32
	add bc, hl
	lda_d16 xhl, 18756
	extz xbc
	add xbc, xhl
	ldw (xbc), 0x1

EFF_DspChanInit_AlgoType35_Epilogue:
	inc 1, de
	cps de, 5
	jrl c, EFF_DspChannel_Init_AlgoCheck
	ret

EFF_StateLoad_Prepare:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr EFF_SlotActive_UpdateFlags
	calr EFF_DSPLink_ResetFlags
	ld xwa, xiz
	calr EFF_DspChannel_InitFlags
	pop xiz
	ret

EFF_MuteLoop:
	pushw iz
	lds de, 0
	lds iz, 0
	cps iz, 5
	jr nc, EFF_MuteLoop_Epilogue

EFF_MuteLoop_SlotBody:
	ld wa, iz
	add wa, wa
	lda_d16 xbc, 18736
	extz xwa
	add xwa, xbc
	cpw (xwa), 0x1
	jr nz, EFF_MuteLoop_SlotNext
	ld wa, iz
	mul wa, 0x32
	lda_d16 xbc, 18752
	extz xwa
	add xwa, xbc
	cpw (xwa), 0x1
	jr nz, EFF_MuteLoop_NoMute
	ld wa, iz
	mul wa, 0x38
	lda_d16 xbc, 17874
	extz xwa
	add xwa, xbc
	ld wa, (xwa)
	extz xwa
	ld xbc, 0x12226
	add xbc, xwa
	cp (xbc), 0x0
	jr z, EFF_MuteLoop_NoMute
	ld wa, iz
	add wa, wa
	lda_d16 xbc, 17852
	extz xwa
	add xwa, xbc
	ldw (xwa), 0x1

EFF_MuteLoop_NoMute:
	ld wa, iz
	call EFF_Mute_WithDebug
	lds de, 1

EFF_MuteLoop_SlotNext:
	inc 1, iz
	cps iz, 5
	jr c, EFF_MuteLoop_SlotBody

EFF_MuteLoop_Epilogue:
	cps de, 1
	jr nz, EFF_MuteLoop_NoFlush
	ldw wa, 0x14
	call DSP_ScheduleDelay

EFF_MuteLoop_NoFlush:
	popw iz
	ret

DSP_ResetLoop:
	pushw iz
	lds iz, 0
	cps iz, 2
	jr nc, DSP_ResetLoop_Epilogue

DSP_ResetLoop_Body:
	ld wa, iz
	call DSP_Reset_WithDebug
	inc 1, iz
	cps iz, 2
	jr c, DSP_ResetLoop_Body

DSP_ResetLoop_Epilogue:
	popw iz
	ret

DSP_MuteLoop:
	pushw iz
	lds iz, 0
	cps iz, 2
	jr nc, DSP_MuteLoop_Epilogue

DSP_MuteLoop_Body:
	ld wa, iz
	add wa, wa
	lda_d16 xbc, 18746
	extz xwa
	add xwa, xbc
	cpw (xwa), 0x1
	jr nz, DSP_MuteLoop_Next
	ld wa, iz
	call DSP_Mute_WithDebug

DSP_MuteLoop_Next:
	inc 1, iz
	cps iz, 2
	jr c, DSP_MuteLoop_Body

DSP_MuteLoop_Epilogue:
	popw iz
	ret

DSP_UnmuteLoop:
	pushw iz
	lds iz, 0
	cps iz, 2
	jr nc, DSP_UnmuteLoop_Epilogue

DSP_UnmuteLoop_Body:
	ld wa, iz
	add wa, wa
	lda_d16 xbc, 18746
	extz xwa
	add xwa, xbc
	cpw (xwa), 0x1
	jr nz, DSP_UnmuteLoop_Next
	ld wa, iz
	call DSP_Unmute_WithDebug

DSP_UnmuteLoop_Next:
	inc 1, iz
	cps iz, 2
	jr c, DSP_UnmuteLoop_Body

DSP_UnmuteLoop_Epilogue:
	popw iz
	ret

DSP_AlgorithmChangeCheck:
	cpdi16 18750, 1
	ret nz
	call DSP_AlgorithmChange
	ret

Unsigned_Max_Select:
	cp bc, wa
	jr ule, Unsigned_Max_Select_Return
	ld wa, bc

Unsigned_Max_Select_Return:
	ld hl, wa
	ret

EFF_ParamIterator_Process:
	dec 6, xsp
	push xiz
	ld (xsp + 4), xbc
	ld (xsp + 8), wa
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 4)
	ld wa, (xbc)
	cp wa, 0xF
	jrl z, EFF_ParamIter_SpecialAlgoPath
	cp wa, 0x35
	jrl z, EFF_ParamIter_SpecialAlgoPath
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 4)
	ld wa, (xbc + 44)
	ldw_erp WA, 0xFA
	cp_erpw 0xFA, 0x11, 0x00
	jr ule, EFF_ParamIter_CountClamp
	ldi_erpw 0xFA, 0x11, 0x00

EFF_ParamIter_CountClamp:
	lds iz, 0
	cpw_erp IZ, 0xFA
	jrl nc, EFF_ParamIter_Epilogue

EFF_ParamIter_StdLoop:
	ld bc, iz
	add bc, bc
	ld wa, (xsp + 8)
	mul wa, 0x32
	add wa, bc
	lda_d16 xbc, 18756
	extz xwa
	add xwa, xbc
	cpw (xwa), 0x1
	jr nz, EFF_ParamIter_StdLoopNext
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 4)
	cp iz, (xbc + 38)
	jr z, EFF_ParamIter_StdLoopNext
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 4)
	ld xwa, (xsp + 4)
	push xwa
	ld wa, (xsp + 12)
	ld bc, (xbc)
	ld de, iz
	call EFF_ParamEdit_WithDebug

EFF_ParamIter_StdLoopNext:
	inc 1, iz
	cpw_erp IZ, 0xFA
	jr c, EFF_ParamIter_StdLoop
	jr EFF_ParamIter_Epilogue

EFF_ParamIter_SpecialAlgoPath:
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 4)
	ld wa, (xbc + 30)
	and wa, 0x1
	muls wa, 0xB
	lda_24 xbc, 0x0122a6
	stb_dri H, 0x07, 0xE4, 0xE0
	cp (xiz), 0xC
	jr z, EFF_ParamIter_Epilogue

EFF_ParamIter_SpecialLoop:
	ld a, (xiz)
	extz wa
	ld bc, wa
	add bc, bc
	ld wa, (xsp + 8)
	mul wa, 0x32
	add bc, wa
	lda_d16 xwa, 18756
	extz xbc
	add xbc, xwa
	cpw (xbc), 0x1
	jr nz, EFF_ParamIter_SpecialLoopNext
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 4)
	ld a, (xiz)
	ld e, a
	extz de
	ld xwa, (xsp + 4)
	push xwa
	ld wa, (xsp + 12)
	ld bc, (xbc)
	call EFF_ParamEdit_WithDebug

EFF_ParamIter_SpecialLoopNext:
	inc 1, xiz
	cp (xiz), 0xC
	jr nz, EFF_ParamIter_SpecialLoop

EFF_ParamIter_Epilogue:
	pop xiz
	inc 6, xsp
	ret

EFF_VolumeChange_Check:
	ld de, wa
	mul de, 0x32
	add de, 0x10
	lda_d16 xhl, 18784
	extz xde
	add xde, xhl
	cpw (xde), 0x1
	ret nz
	calr EFF_ParamIterator_Process
	ret

EFF_Change_Handler:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xbc
	ld iz, wa
	ld wa, iz
	mul wa, 0x32
	lda_d16 xbc, 18752
	extz xwa
	add xwa, xbc
	cpw (xwa), 0x1
	jrl nz, EFF_Change_Handler_Epilogue
	ld wa, iz
	cps wa, 2
	jr nz, EFF_Change_Handler_NonSlot2
	ld xwa, (xsp + 2)
	cpw (xwa + 4), 0x1
	jr nz, EFF_Change_Handler_SlotDispatch
	ld wa, iz
	ld xbc, (xsp + 2)
	ld bc, (xbc + 6)
	call EFF_Disconnect
	jr EFF_Change_Handler_SlotDispatch

EFF_Change_Handler_NonSlot2:
	ld wa, iz
	ld xbc, (xsp + 2)
	ld bc, (xbc + 6)
	call EFF_Disconnect

EFF_Change_Handler_SlotDispatch:
	ld wa, iz
	cps wa, 4
	jr z, EFF_Change_Handler_Slot234_AlgoPath
	cps wa, 3
	jr z, EFF_Change_Handler_Slot234_AlgoPath
	cps wa, 2
	jr z, EFF_Change_Handler_Slot234_AlgoPath
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 2)
	ld wa, iz
	ld bc, (xbc)
	call EFF_Change_WithDebug
	jr EFF_Change_Handler_Epilogue

EFF_Change_Handler_Slot234_AlgoPath:
	ld xwa, (xsp + 2)
	cpw (xwa + 4), 0x1
	jr nz, EFF_Change_Handler_Slot234_AltPath
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 2)
	ld wa, iz
	ld bc, (xbc)
	call EFF_Change_WithDebug
	jr EFF_Change_Handler_Epilogue

EFF_Change_Handler_Slot234_AltPath:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 2)
	ld wa, iz
	ld bc, (xbc)
	call EFF_DataChange_WithDebug

EFF_Change_Handler_Epilogue:
	ld wa, iz
	ld xbc, (xsp + 2)
	calr EFF_VolumeChange_Check
	popw iz
	inc 4, xsp
	ret

EFF_HeaderChangeDataLoop:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ldiw_erp 0xFA, 0
	lds iz, 4
	cp iz, 0xFFFF
	jr le, EFF_HeaderChangeLoop_Epilogue

EFF_HeaderChangeLoop_Body:
	ld xwa, (xsp + 4)
	cpw (xwa + 2), 0x1
	jr z, EFF_HeaderChangeLoop_CallAlgo
	ld xwa, (xsp + 4)
	cpw (xwa + 4), 0x1
	jr nz, EFF_HeaderChangeLoop_PostAlgo

EFF_HeaderChangeLoop_CallAlgo:
	ld wa, iz
	call EFF_WriteHeader

EFF_HeaderChangeLoop_PostAlgo:
	ld wa, iz
	mul wa, 0x32
	lda_d16 xbc, 18752
	extz xwa
	add xwa, xbc
	cpw (xwa), 0x1
	jr z, EFF_HeaderChangeLoop_ActiveSlot
	ld xwa, (xsp + 4)
	cpw (xwa), 0x1
	jr nz, EFF_HeaderChangeLoop_CallChange

EFF_HeaderChangeLoop_ActiveSlot:
	lda_24 xwa, 0x01ed72
	ldb_sri A, 0x07, 0xE0, 0xF8
	ld c, a
	extz bc
	stw_erp WA, 0xFA
	calr Unsigned_Max_Select
	ldw_erp HL, 0xFA

EFF_HeaderChangeLoop_CallChange:
	ld wa, iz
	ld xbc, (xsp + 4)
	calr EFF_Change_Handler
	dec 1, iz
	cp iz, 0xFFFF
	jr gt, EFF_HeaderChangeLoop_Body

EFF_HeaderChangeLoop_Epilogue:
	cpiw_erp 0xFA, 0
	jr z, EFF_HeaderChangeLoop_SkipApply
	stw_erp WA, 0xFA
	call DSP_ScheduleDelay

EFF_HeaderChangeLoop_SkipApply:
	pop xiz
	inc 4, xsp
	ret

EFF_LinkLoop:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	lds iz, 4
	cp iz, 0xFFFF
	jr le, EFF_LinkLoop_Epilogue

EFF_LinkLoop_Body:
	ld wa, iz
	mul wa, 0x32
	add wa, 0x10
	lda_d16 xbc, 18782
	extz xwa
	add xwa, xbc
	cpw (xwa), 0x1
	jr nz, EFF_LinkLoop_Next
	ld wa, iz
	muls wa, 0x38
	ld bc, wa
	inc 8, bc
	ld xwa, (xsp + 2)
	stb_dri W, 0x07, 0xE0, 0xE4
	cpw (xwa + 54), 0x1
	jr nz, EFF_LinkLoop_Next
	ld wa, iz
	ld xbc, (xsp + 2)
	ld bc, (xbc + 6)
	call EFF_Link

EFF_LinkLoop_Next:
	dec 1, iz
	cp iz, 0xFFFF
	jr gt, EFF_LinkLoop_Body

EFF_LinkLoop_Epilogue:
	popw iz
	inc 4, xsp
	ret

EFF_SecondaryLinkPath:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	lds iz, 0
	ldiw_erp 0xFA, 4
	cp_erpw 0xFA, 0xFF, 0xFF
	jr le, EFF_SecLinkPath_Pass1Epilogue

EFF_SecLinkPath_Pass1Body:
	stw_erp WA, 0xFA
	mul wa, 0x32
	add wa, 0x10
	lda_d16 xbc, 18782
	extz xwa
	add xwa, xbc
	cpw (xwa), 0x1
	jr nz, EFF_SecLinkPath_Pass1Next
	stw_erp WA, 0xFA
	muls wa, 0x38
	ld bc, wa
	inc 8, bc
	ld xwa, (xsp + 4)
	stb_dri W, 0x07, 0xE0, 0xE4
	cpw (xwa + 54), 0x0
	jr nz, EFF_SecLinkPath_Pass1Next
	ld wa, iz
	ldw bc, 0x14
	calr Unsigned_Max_Select
	ld iz, hl

EFF_SecLinkPath_Pass1Next:
	dec1w_erp 0xFA
	cp_erpw 0xFA, 0xFF, 0xFF
	jr gt, EFF_SecLinkPath_Pass1Body

EFF_SecLinkPath_Pass1Epilogue:
	cps iz, 0
	jr z, EFF_SecLinkPath_Pass2Start
	ld wa, iz
	call DSP_ScheduleDelay

EFF_SecLinkPath_Pass2Start:
	lds iz, 0
	ldiw_erp 0xFA, 4
	cp_erpw 0xFA, 0xFF, 0xFF
	jr le, EFF_SecLinkPath_Pass2Epilogue

EFF_SecLinkPath_Pass2Body:
	stw_erp WA, 0xFA
	mul wa, 0x32
	add wa, 0x10
	lda_d16 xbc, 18782
	extz xwa
	add xwa, xbc
	cpw (xwa), 0x1
	jr nz, EFF_SecLinkPath_Pass2Next
	stw_erp WA, 0xFA
	muls wa, 0x38
	ld bc, wa
	inc 8, bc
	ld xwa, (xsp + 4)
	stb_dri W, 0x07, 0xE0, 0xE4
	cpw (xwa + 54), 0x0
	jr nz, EFF_SecLinkPath_Pass2Next
	cpiw_erp 0xFA, 3
	jr z, EFF_SecLinkPath_Pass2MaxVol
	cpi3_erpw 2, 0xFA
	jr z, EFF_SecLinkPath_Pass2MaxVol
	stw_erp WA, 0xFA
	ld xbc, (xsp + 4)
	ld bc, (xbc + 6)
	call EFF_Disconnect

EFF_SecLinkPath_Pass2MaxVol:
	ld de, iz
	lda_24 xwa, 0x01ed72
	ldb_sri A, 0x07, 0xE0, 0xFA
	ld c, a
	extz bc
	ld wa, de
	calr Unsigned_Max_Select
	ld iz, hl

EFF_SecLinkPath_Pass2Next:
	dec1w_erp 0xFA
	cp_erpw 0xFA, 0xFF, 0xFF
	jr gt, EFF_SecLinkPath_Pass2Body

EFF_SecLinkPath_Pass2Epilogue:
	cps iz, 0
	jr z, EFF_SecLinkPath_Epilogue
	ld wa, iz
	call DSP_ScheduleDelay

EFF_SecLinkPath_Epilogue:
	pop xiz
	inc 4, xsp
	ret

EFF_VolumeLoop:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	lds iz, 0
	cps iz, 5
	jrl nc, EFF_VolumeLoop_Epilogue

EFF_VolumeLoop_Body:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 2)
	ld bc, (xbc + 38)
	sll bc, 1
	ld wa, iz
	mul wa, 0x32
	add wa, bc
	lda_d16 xbc, 18756
	extz xwa
	add xwa, xbc
	cpw (xwa), 0x1
	jrl nz, EFF_VolumeLoop_Next
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 2)
	ld de, (xbc + 38)
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 2)
	cpw (xbc), 0x3F
	jrl nz, EFF_VolumeLoop_ApplyDelta
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	ld xix, xbc
	add xix, (xsp + 2)
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 2)
	lda_24 xhl, 0x0122c4
	ld wa, (xbc + 6)
	ldb_sri A, 0x07, 0xEC, 0xE0
	extz wa
	ld hl, (xix + 4)
	sub hl, wa
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 2)
	ld (xbc + 4), hl
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 2)
	cpw (xbc + 4), 0x0
	jr ge, EFF_VolumeLoop_ApplyDelta
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 2)
	ldw (xbc + 4), 0x0

EFF_VolumeLoop_ApplyDelta:
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 2)
	ld xwa, (xsp + 2)
	push xwa
	ld wa, iz
	ld bc, (xbc)
	call EFF_VolumeUpdate_WithDebug

EFF_VolumeLoop_Next:
	inc 1, iz
	cps iz, 5
	jrl c, EFF_VolumeLoop_Body

EFF_VolumeLoop_Epilogue:
	popw iz
	inc 4, xsp
	ret

EFF_DisconnectLoop:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	lds iz, 4
	cp iz, 0xFFFF
	jr le, EFF_DisconnectLoop_Epilogue

EFF_DisconnectLoop_Body:
	cps iz, 3
	jr z, EFF_DisconnectLoop_Next
	cps iz, 2
	jr z, EFF_DisconnectLoop_Next
	ld wa, iz
	ld xbc, (xsp + 2)
	ld bc, (xbc + 6)
	call EFF_Disconnect

EFF_DisconnectLoop_Next:
	dec 1, iz
	cp iz, 0xFFFF
	jr gt, EFF_DisconnectLoop_Body

EFF_DisconnectLoop_Epilogue:
	popw iz
	inc 4, xsp
	ret

DSP_State_Dispatcher:
	push xiz
	ld xiz, xwa
	cpw (xiz + 4), 0x1
	jr nz, DSP_StateDispatcher_MutePath
	calr DSP_ResetLoop
	jr DSP_StateDispatcher_PostMute

DSP_StateDispatcher_MutePath:
	ld xwa, xiz
	calr EFF_MuteLoop

DSP_StateDispatcher_PostMute:
	calr DSP_MuteLoop
	ld xwa, xiz
	calr DSP_AlgorithmChangeCheck
	cpw (xiz + 4), 0x1
	jr z, DSP_StateDispatcher_DisconnectPath
	cpw (xiz + 2), 0x1
	jr nz, DSP_StateDispatcher_UnmutePath

DSP_StateDispatcher_DisconnectPath:
	lds wa, 0
	call EFF_WriteHeader
	ld xwa, xiz
	calr EFF_DisconnectLoop

DSP_StateDispatcher_UnmutePath:
	calr DSP_UnmuteLoop
	ld xwa, xiz
	calr EFF_HeaderChangeDataLoop
	ld xwa, xiz
	calr EFF_LinkLoop
	ld xwa, xiz
	calr EFF_VolumeLoop
	ld xwa, xiz
	calr EFF_SecondaryLinkPath
	lds de, 4
	cp de, 0xFFFF
	jr le, DSP_StateDispatcher_Epilogue

DSP_StateDispatcher_AlgoLoop:
	ld wa, de
	muls wa, 0x38
	inc 8, wa
	ldw_sri IX, 0x07, 0xF8, 0xE0
	ld wa, de
	mul wa, 0x32
	lda_d16 xbc, 18752
	extz xwa
	add xwa, xbc
	cpw (xwa), 0x1
	jr nz, DSP_StateDispatcher_AlgoNext
	ld wa, ix
	extz xwa
	ld xbc, 0x12226
	add xbc, xwa
	cp (xbc), 0x0
	jr z, DSP_StateDispatcher_AlgoClear
	ld wa, de
	add wa, wa
	lda_d16 xbc, 17852
	ld hl, wa
	extz xhl
	add xhl, xbc
	ld wa, ix
	extz xwa
	ld xbc, 0x12226
	add xbc, xwa
	ld a, (xbc)
	inc 1, a
	extz wa
	ld (xhl), wa
	jr DSP_StateDispatcher_AlgoNext

DSP_StateDispatcher_AlgoClear:
	ld wa, de
	add wa, wa
	lda_d16 xbc, 17852
	extz xwa
	add xwa, xbc
	ldw (xwa), 0x0

DSP_StateDispatcher_AlgoNext:
	dec 1, de
	cp de, 0xFFFF
	jr gt, DSP_StateDispatcher_AlgoLoop

DSP_StateDispatcher_Epilogue:
	pop xiz
	ret

DSP_State_LookupAlgoIndex:
	extz xwa
	ld xbc, 0x12226
	add xbc, xwa
	ld l, (xbc)
	extz hl
	ret

DSP_State_Dispatcher_Data:
	.byte 0x45, 0xec, 0x46, 0x00, 0x00, 0x44, 0x0e, 0x48
	.byte 0x00, 0x00, 0x31, 0x91, 0x00, 0x95, 0x11, 0xdb
	.byte 0xa8, 0x0e, 0x45, 0x0e, 0x48, 0x00, 0x00, 0x44
	.byte 0xec, 0x46, 0x00, 0x00, 0x31, 0x91, 0x00, 0x95
	.byte 0x11, 0xdb, 0xa8, 0x0e

DSP_Reset_WithDebug:
	pushw iz
	ld iz, wa
	lda_24 xwa, 0x0122cc
	call Debug_Print_String
	ld wa, iz
	call Debug_Print_Byte
	lda_24 xwa, 0x0122d2
	call Debug_Print_String
	call DSP1_Deassert_Reset
	call DSP2_Deassert_Reset
	call DSP1_Assert_Reset
	call DSP2_Assert_Reset
	call DSP1_Deassert_Reset
	popw iz
	ret

DSP_AntiReset_WithDebug:
	pushw iz
	ld iz, wa
	lda_24 xwa, 0x0122da
	call Debug_Print_String
	ld wa, iz
	call Debug_Print_Byte
	lda_24 xwa, 0x0122e0
	call Debug_Print_String
	call DSP2_Deassert_Reset
	popw iz
	ret

EFF_Mute_WithDebug:
	pushw iz
	ld iz, wa
	lda_24 xwa, 0x0122ed
	call Debug_Print_String
	ld wa, iz
	inc 1, wa
	call Debug_Print_Byte
	lda_24 xwa, 0x0122f3
	call Debug_Print_String
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, 0x1F3BC
	add xbc, xwa
	ld wa, iz
	ld xbc, (xbc)
	call DSP_WriteEFFConfig
	popw iz
	ret

DSP_Mute_WithDebug:
	pushw iz
	ld iz, wa
	lda_24 xwa, 0x0122fa
	call Debug_Print_String
	ld wa, iz
	call Debug_Print_Byte
	lda_24 xwa, 0x012300
	call Debug_Print_String
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, 0x1F3D0
	add xbc, xwa
	ld wa, iz
	ld xbc, (xbc)
	call DSP_WriteGlobalConfig
	popw iz
	ret

DSP_Unmute_WithDebug:
	pushw iz
	ld iz, wa
	lda_24 xwa, 0x012307
	call Debug_Print_String
	ld wa, iz
	call Debug_Print_Byte
	lda_24 xwa, 0x01230d
	call Debug_Print_String
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, 0x1F3E0
	add xbc, xwa
	ld wa, iz
	ld xbc, (xbc)
	call DSP_WriteGlobalConfig
	popw iz
	ret

EFF_Disconnect:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), bc
	ld iz, wa
	lda_24 xwa, 0x012318
	call Debug_Print_String
	ld wa, iz
	inc 1, wa
	call Debug_Print_Byte
	lda_24 xwa, 0x01231e
	call Debug_Print_String
	ld wa, iz
	extz xwa
	ld xbc, 0x1ED6D
	add xbc, xwa
	ld a, (xbc)
	ld l, a
	extz hl
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	ld wa, (xsp + 2)
	extz xwa
	ld xde, xwa
	add xde, xde
	add xde, xwa
	sll xde, 2
	add xde, xbc
	ld xbc, 0x1F3F0
	add xbc, xde
	ld wa, hl
	ld xbc, (xbc)
	call DSP_WriteGlobalConfig
	popw iz
	inc 2, xsp
	ret

EFF_Link:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), bc
	ld iz, wa
	lda_24 xwa, 0x01232b
	call Debug_Print_String
	ld wa, iz
	inc 1, wa
	call Debug_Print_Byte
	lda_24 xwa, 0x012331
	call Debug_Print_String
	ld wa, iz
	extz xwa
	ld xbc, 0x1ED6D
	add xbc, xwa
	ld a, (xbc)
	ld l, a
	extz hl
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	ld wa, (xsp + 2)
	extz xwa
	ld xde, xwa
	add xde, xde
	add xde, xwa
	sll xde, 2
	add xde, xbc
	ld xbc, 0x1F404
	add xbc, xde
	ld wa, hl
	ld xbc, (xbc)
	call DSP_WriteGlobalConfig
	popw iz
	inc 2, xsp
	ret

DSP_AlgorithmChange:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	lda_24 xwa, 0x012338
	call Debug_Print_String
	ld xwa, (xsp + 2)
	ld wa, (xwa + 6)
	call Debug_Print_Byte
	lds iz, 0
	lda_24 xwa, 0x01e63c
	ld xbc, xwa
	ld wa, iz
	call DSP_WriteGlobalConfig
	ld xwa, (xsp + 2)
	cpw (xwa + 4), 0x1
	jr nz, EFF_LoadConfigs_ForChannel
	ld wa, iz
	calr DSP_AntiReset_WithDebug

EFF_LoadConfigs_ForChannel:
	lda_24 xwa, 0x01e6be
	ld xbc, xwa
	ld wa, iz
	call DSP_WriteGlobalConfig
	lds iz, 1
	lda_24 xwa, 0x01e996
	ld xbc, xwa
	ld wa, iz
	call DSP_WriteGlobalConfig
	lda_24 xwa, 0x01ea12
	ld xbc, xwa
	ld wa, iz
	call DSP_WriteGlobalConfig
	lds wa, 1
	call DSP_WaitForDelay
	lda_24 xwa, 0x01e7c5
	ld xbc, xwa
	ld wa, iz
	call DSP_WriteGlobalConfig
	lda_24 xwa, 0x01e8a7
	ld xbc, xwa
	ld wa, iz
	call DSP_WriteGlobalConfig
	lda_24 xwa, 0x01e891
	ld xbc, xwa
	ld wa, iz
	call DSP_WriteGlobalConfig
	lda_24 xwa, 0x01e947
	ld xbc, xwa
	ld wa, iz
	call DSP_WriteGlobalConfig
	popw iz
	inc 4, xsp
	ret

EFF_WriteHeader:
	pushw iz
	ld iz, wa
	lda_24 xwa, 0x012346
	call Debug_Print_String
	ld wa, iz
	inc 1, wa
	call Debug_Print_Byte
	lda_24 xwa, 0x01234c
	call Debug_Print_String
	ld wa, iz
	extz xwa
	ld xbc, 0x1ED6D
	add xbc, xwa
	ld a, (xbc)
	ld e, a
	extz de
	cps de, 0
	jr nz, EFF_WriteHeader_Return
	lda_24 xwa, 0x01e496
	ld xbc, xwa
	ld wa, de
	call DSP_WriteGlobalConfig

EFF_WriteHeader_Return:
	popw iz
	ret

EFF_Change_WithDebug:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), bc
	ld iz, wa
	lda_24 xwa, 0x012355
	call Debug_Print_String
	ld wa, iz
	inc 1, wa
	call Debug_Print_Byte
	lda_24 xwa, 0x01235b
	call Debug_Print_String
	ld wa, (xsp + 2)
	call Debug_Print_Byte
	ld wa, iz
	cps wa, 1
	jr nz, EFF_Change_ChannelNot1
	ld wa, (xsp + 2)
	cp wa, 0xA
	jr z, EFF_Change_Case0xA
	cp wa, 0x9
	jr nz, EFF_Change_GenericLookup
	ld wa, iz
	lda_24 xbc, 0x01dfa5
	call DSP_WriteEFFConfig
	ld wa, iz
	lda_24 xbc, 0x01e0b9
	call DSP_WriteEFFConfig
	jr EFF_Change_Return

EFF_Change_Case0xA:
	ld wa, iz
	lda_24 xbc, 0x01e1de
	call DSP_WriteEFFConfig
	ld wa, iz
	lda_24 xbc, 0x01e342
	call DSP_WriteEFFConfig
	jr EFF_Change_Return

EFF_Change_GenericLookup:
	ld wa, (xsp + 2)
	extz xwa
	sll xwa, 2
	ld xbc, 0x1ED7C
	add xbc, xwa
	ld wa, iz
	ld xbc, (xbc)
	call DSP_WriteEFFConfig
	ld wa, (xsp + 2)
	extz xwa
	sll xwa, 2
	ld xbc, 0x1EF0C
	add xbc, xwa
	ld wa, iz
	ld xbc, (xbc)
	call DSP_WriteEFFConfig
	jr EFF_Change_Return

EFF_Change_ChannelNot1:
	ld wa, (xsp + 2)
	extz xwa
	sll xwa, 2
	ld xbc, 0x1ED7C
	add xbc, xwa
	ld wa, iz
	ld xbc, (xbc)
	call DSP_WriteEFFConfig
	ld wa, (xsp + 2)
	extz xwa
	sll xwa, 2
	ld xbc, 0x1EF0C
	add xbc, xwa
	ld wa, iz
	ld xbc, (xbc)
	call DSP_WriteEFFConfig

EFF_Change_Return:
	popw iz
	inc 2, xsp
	ret

EFF_DataChange_WithDebug:
	dec 2, xsp
	pushw iz
	ld iz, bc
	ld (xsp + 2), wa
	lda_24 xwa, 0x012364
	call Debug_Print_String
	ld wa, (xsp + 2)
	inc 1, wa
	call Debug_Print_Byte
	lda_24 xwa, 0x01236a
	call Debug_Print_String
	ld wa, iz
	call Debug_Print_Byte
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, 0x1EF0C
	add xbc, xwa
	ld wa, (xsp + 2)
	ld xbc, (xbc)
	call DSP_WriteEFFConfig
	popw iz
	inc 2, xsp
	ret

EFF_ParamEdit_WithDebug:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), de
	ld (xsp + 4), bc
	ld iz, wa
	lda_24 xwa, 0x012378
	call Debug_Print_String
	ld wa, iz
	inc 1, wa
	call Debug_Print_Byte
	lda_24 xwa, 0x01237e
	call Debug_Print_String
	ld wa, (xsp + 2)
	call Debug_Print_Byte
	lda_24 xwa, 0x012384
	call Debug_Print_String
	ld wa, (xsp + 2)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	add xde, xbc
	add xde, (xsp + 10)
	ld wa, (xde + 12)
	call Debug_Print_Word
	ld xwa, (xsp + 10)
	push xwa
	ld wa, iz
	ld bc, (xsp + 8)
	ld de, (xsp + 6)
	call DSP_WriteParameter
	popw iz
	inc 4, xsp
	retd 0x4

EFF_VolumeUpdate_WithDebug:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), de
	ld (xsp + 6), bc
	ld iz, wa
	cpw (xsp + 4), 0x63
	jrl z, EFF_VolumeUpdate_Return
	lda_24 xwa, 0x01238b
	call Debug_Print_String
	ld wa, iz
	inc 1, wa
	call Debug_Print_Byte
	lda_24 xwa, 0x012391
	call Debug_Print_String
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	add xde, xbc
	add xde, (xsp + 12)
	ld wa, (xde + 12)
	call Debug_Print_Word
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	sll xbc, 3
	inc 8, xbc
	add xbc, (xsp + 12)
	ld wa, (xbc + 54)
	cps wa, 0
	jr z, EFF_VolumeUpdate_ZeroAndReload
	ld xwa, (xsp + 12)
	push xwa
	ld wa, iz
	ld bc, (xsp + 10)
	ld de, (xsp + 8)
	call DSP_WriteParameter
	jr EFF_VolumeUpdate_Return

EFF_VolumeUpdate_ZeroAndReload:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	add xde, xbc
	add xde, (xsp + 12)
	ld wa, (xde + 12)
	ld (xsp + 2), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	add xde, xbc
	add xde, (xsp + 12)
	ldw (xde + 12), 0x0
	ld xwa, (xsp + 12)
	push xwa
	ld wa, iz
	ld bc, (xsp + 10)
	ld de, (xsp + 8)
	call DSP_WriteParameter
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	sll xde, 3
	add xde, xbc
	add xde, (xsp + 12)
	ld wa, (xsp + 2)
	ld (xde + 12), wa

EFF_VolumeUpdate_Return:
	popw iz
	inc 6, xsp
	retd 0x4

; ----------------------------------------------------------------------------
; Debug_Print_String - Print null-terminated string via serial port
; Entry: XWA = pointer to string
; Exit:  WA = 0
; Notes: Calls boot ROM serial output routine at 0xFFFEA1
; ----------------------------------------------------------------------------
Debug_Print_String:	; 038365h
	call 0xFFFEA1
	lds wa, 0
	ret

; ----------------------------------------------------------------------------
; Debug_Print_Byte - Print single byte as hex via serial port
; Entry: A = byte value
; Exit:  WA = 0
; Notes: Calls boot ROM serial byte output routine at 0xFFFE86
; ----------------------------------------------------------------------------
Debug_Print_Byte:	; 03836Ch
	extz wa
	call 0xFFFE86
	lds wa, 0
	ret

; ----------------------------------------------------------------------------
; Debug_Print_Word - Print 16-bit word as hex via serial port
; Entry: WA = word value
; Exit:  WA = 0
; Notes: Prints high byte first, then low byte
; ----------------------------------------------------------------------------
Debug_Print_Word:	; 038375h
	pushw iz
	ld iz, wa
	ld wa, iz
	srl wa, 8	; Get high byte
	extz wa
	call 0xFFFE86
	lds wa, 0
	stb_erp A, 0xF8	; Get low byte
	extz wa
	call 0xFFFE86
	lds wa, 0
	popw iz
	ret

DSP_ScheduleDelay:
	jp DSP_WaitForDelay

; ============================================================================
; DSP CONTROL ROUTINES
; These routines control the two DSP chips via GPIO pins:
;   PH.1 = DSP1 reset (active low)
;   PH.2 = DSP2 reset (active low)
;   P7.3 = DSP write strobe (active low)
;   P7.4 = DSP read strobe (active low)
;   P7.5 = DSP1 chip select (active low)
;   P7.6 = DSP command/data select (0=command, 1=data)
;   PE.6 = DSP2 chip select (active low)
; ============================================================================

DSP1_Assert_Reset:	; 038396h
	res_dd8 1, 0x44	; Assert DSP1 reset (active low)
	ret

DSP1_Deassert_Reset:	; 03839Ah
	set_dd8 1, 0x44	; Deassert DSP1 reset
	ret

DSP2_Assert_Reset:	; 03839Eh
	res_dd8 2, 0x44	; Assert DSP2 reset (active low)
	ret

DSP2_Deassert_Reset:	; 0383A2h
	set_dd8 2, 0x44	; Deassert DSP2 reset
	ret

DSP_Nop:	; 0383A6h - Empty routine, used as placeholder
	ret

DSP_Set_Command_Mode:	; 0383A7h
	res_dd8 6, 0x1C	; DSPCD=0 selects command mode
	ret

DSP_Set_Data_Mode:	; 0383ABh
	set_dd8 6, 0x1C	; DSPCD=1 selects data mode
	ret

DSP_Assert_Write:	; 0383AFh
	res_dd8 3, 0x1C	; Assert write strobe (active low)
	ret

DSP_Deassert_Write:	; 0383B3h
	set_dd8 3, 0x1C	; Deassert write strobe
	ret

DSP_Assert_Read_Data:	; 0383B7h - Raw bytes, appears to be RES 4, (P7)
	.byte 0xf0, 0x1c, 0xb4, 0x0e

DSP_Deassert_Read:	; 0383BBh
	set_dd8 4, 0x1C	; Deassert read strobe
	ret

; ----------------------------------------------------------------------------
; DSP_Select_Chip - Select DSP chip for communication
; Entry: WA = chip number (0=DSP1, 1=DSP2)
; Exit:  Chip select asserted (active low)
; ----------------------------------------------------------------------------
DSP_Select_Chip:	; 0383BFh
	pushw iz
	ld iz, wa
	ld wa, iz
	calr DSP_Nop
	ld wa, iz
	cps wa, 1
	jr z, DSP_Select_Chip__select_dsp2
	cps wa, 0
	jr nz, DSP_Select_Chip__done
	res_dd8 5, 0x1C	; Assert DSP1 chip select (active low)
	jr DSP_Select_Chip__done

DSP_Select_Chip__select_dsp2:
	res_dd8 6, 0x38	; Assert DSP2 chip select (active low)

DSP_Select_Chip__done:
	popw iz
	ret

; ----------------------------------------------------------------------------
; DSP_Deselect_Chip - Deselect DSP chip after communication
; Entry: WA = chip number (0=DSP1, 1=DSP2)
; Exit:  Chip select deasserted
; ----------------------------------------------------------------------------
DSP_Deselect_Chip:	; 0383DBh
	pushw iz
	ld iz, wa
	ld wa, iz
	calr DSP_Nop
	ld wa, iz
	cps wa, 1
	jr z, DSP_Deselect_Chip__deselect_dsp2
	cps wa, 0
	jr nz, DSP_Deselect_Chip__done
	set_dd8 5, 0x1C	; Deassert DSP1 chip select
	jr DSP_Deselect_Chip__done

DSP_Deselect_Chip__deselect_dsp2:
	set_dd8 6, 0x38	; Deassert DSP2 chip select

DSP_Deselect_Chip__done:
	popw iz
	ret

; ----------------------------------------------------------------------------
; DSP_Read_Status - Read DSP status from PH.0
; Entry: None
; Exit:  HL = status bit (0 or 1)
; ----------------------------------------------------------------------------
DSP_Read_Status:	; 0383F7h
	calr DSP_Nop
	set_dd8 0, 0x44
	ldcf_dd8 0, 0x44
	scc8 c, l
	extz hl
	ret

DSP_WriteParamWord:
	dec 2, xsp
	push xiz
	ld (xsp + 4), bc
	ld xiz, xwa
	ld xwa, xiz
	sra xwa, 0
	and xwa, 0xFF
	extz wa
	ld bc, (xsp + 4)
	call DSP_DispatchData
	ld xwa, xiz
	sra xwa, 8
	and xwa, 0xFF
	extz wa
	ld bc, (xsp + 4)
	call DSP_DispatchData
	pop xiz
	inc 2, xsp
	ret

DSP_WriteParamCmd30:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), xde
	ld (xsp + 6), bc
	ld iz, wa
	ld bc, iz
	ldw wa, 0x30
	call DSP_DispatchCommand
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld wa, (xsp + 6)
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	ld bc, iz
	calr DSP_WriteParamWord
	popw iz
	inc 6, xsp
	ret

DSP_WriteFreqParam_AlgoType:
	dec 6, xsp
	pushw iz
	ld iz, de
	ld (xsp + 2), xbc
	ld (xsp + 6), wa
	ld wa, iz
	cps wa, 1
	jrl z, DSP_WriteFreqParam_AlgoType_UseCmd30
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld wa, (xsp + 12)
	add wa, (xsp + 6)
	srl wa, 4
	and wa, 0xF
	add wa, 0x10
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld wa, (xsp + 12)
	add wa, (xsp + 6)
	sll wa, 4
	and wa, 0xF0
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld bc, iz
	ldw wa, 0xA
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sra xwa, 1
	sra xwa, 0
	and xwa, 0x7F
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sra xwa, 9
	and xwa, 0xFF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sra xwa, 1
	and xwa, 0xFF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sla xwa, 7
	and xwa, 0x80
	add xwa, 0x15
	extz wa
	ld bc, iz
	call DSP_DispatchData
	jr DSP_WriteFreqParam_AlgoType_Return

DSP_WriteFreqParam_AlgoType_UseCmd30:
	ld wa, iz
	ld bc, (xsp + 6)
	ld xde, (xsp + 2)
	calr DSP_WriteParamCmd30

DSP_WriteFreqParam_AlgoType_Return:
	popw iz
	inc 6, xsp
	retd 0x2

DSP_WriteFreqParam:
	dec 6, xsp
	pushw iz
	ld iz, de
	ld (xsp + 2), xbc
	ld (xsp + 6), wa
	ld wa, iz
	cps wa, 1
	jrl z, DSP_WriteFreqParam_UseCmd30
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld wa, (xsp + 12)
	add wa, (xsp + 6)
	srl wa, 4
	and wa, 0xF
	add wa, 0x10
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld wa, (xsp + 12)
	add wa, (xsp + 6)
	sll wa, 4
	and wa, 0xF0
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld bc, iz
	ldw wa, 0xA
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sra xwa, 1
	sra xwa, 0
	and xwa, 0x7F
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sra xwa, 9
	and xwa, 0xFF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sra xwa, 1
	and xwa, 0xFF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sla xwa, 7
	and xwa, 0x80
	add xwa, 0x15
	extz wa
	ld bc, iz
	call DSP_DispatchData
	jr DSP_WriteFreqParam_Return

DSP_WriteFreqParam_UseCmd30:
	ld wa, iz
	ld bc, (xsp + 6)
	ld xde, (xsp + 2)
	calr DSP_WriteParamCmd30

DSP_WriteFreqParam_Return:
	popw iz
	inc 6, xsp
	retd 0x2

DSP_WriteCoeffData_5B:
	dec 2, xsp
	push xiz
	ld (xsp + 4), bc
	ld xiz, xwa
	ld bc, (xsp + 4)
	ldw wa, 0xA
	call DSP_DispatchData
	ld xwa, xiz
	sra xwa, 1
	sra xwa, 0
	and xwa, 0x7F
	extz wa
	ld bc, (xsp + 4)
	call DSP_DispatchData
	ld xwa, xiz
	sra xwa, 9
	and xwa, 0xFF
	extz wa
	ld bc, (xsp + 4)
	call DSP_DispatchData
	ld xwa, xiz
	sra xwa, 1
	and xwa, 0xFF
	extz wa
	ld bc, (xsp + 4)
	call DSP_DispatchData
	ld xwa, xiz
	sla xwa, 7
	and xwa, 0x80
	add xwa, 0x15
	extz wa
	ld bc, (xsp + 4)
	call DSP_DispatchData
	pop xiz
	inc 2, xsp
	ret

DSP_UnpackParam3B:
	ld xix, (xwa)
	lds32 xbc, 0
	ld c, (xix + 1)
	ld xde, xbc
	sla xde, 8
	lds32 xbc, 0
	ld c, (xix)
	sla xbc, 0
	ld xiy, xbc
	add xiy, xde
	ld c, (xix + 2)
	lds32 xhl, 0
	ld l, c
	add xhl, xiy
	lda xbc, (xix + 3)
	ld (xwa), xbc
	ret

DSP_WriteLUTParamSet:
	lda xsp, (xsp - 18)
	pushw iz
	ld (xsp + 14), bc
	ld (xsp + 16), xwa
	ld xwa, (xsp + 16)
	ld xwa, (xwa)
	ld (xsp + 6), xwa
	ldb_spi C, 0xE0
	ld (xsp + 6), xwa
	cps c, 1
	jr z, DSP_WriteLUT_AlgoC1
	ldw (xsp + 2), 0x24
	cp xde, 0x2
	jr z, DSP_WriteLUT_AlgoC0_TypeDE2
	cp xde, 0x1
	jr z, DSP_WriteLUT_AlgoC0_TypeDE1
	lda_24 xwa, 0x01eafa
	ld (xsp + 10), xwa
	jr DSP_WriteLUT_MainLoop_Init

DSP_WriteLUT_AlgoC0_TypeDE1:
	lda_24 xwa, 0x01eb67
	ld (xsp + 10), xwa
	jr DSP_WriteLUT_MainLoop_Init

DSP_WriteLUT_AlgoC0_TypeDE2:
	lda_24 xwa, 0x01ebd4
	ld (xsp + 10), xwa
	jr DSP_WriteLUT_MainLoop_Init

DSP_WriteLUT_AlgoC1:
	ldw (xsp + 2), 0x20
	cp xde, 0x2
	jr z, DSP_WriteLUT_AlgoC1_TypeDE2
	cp xde, 0x1
	jr z, DSP_WriteLUT_AlgoC1_TypeDE1
	lda_24 xwa, 0x01ec41
	ld (xsp + 10), xwa
	jr DSP_WriteLUT_MainLoop_Init

DSP_WriteLUT_AlgoC1_TypeDE1:
	lda_24 xwa, 0x01eca5
	ld (xsp + 10), xwa
	jr DSP_WriteLUT_MainLoop_Init

DSP_WriteLUT_AlgoC1_TypeDE2:
	lda_24 xwa, 0x01ed09
	ld (xsp + 10), xwa

DSP_WriteLUT_MainLoop_Init:
	ld xbc, (xsp + 10)
	lds32 xwa, 1
	add (xsp + 10), xwa
	ld a, (xbc)
	extz wa
	ld (xsp + 14), wa
	ldw (xsp + 4), 0x0
	ld wa, (xsp + 2)
	srl wa, 2
	cp (xsp + 4), wa
	jrl nc, DSP_WriteLUT_MainLoop_Done

DSP_WriteLUT_MainLoop_Body:
	cpw (xsp + 4), 0x0
	jr z, DSP_WriteLUT_MainLoop_FirstEntry
	ld bc, (xsp + 26)
	lds wa, 1
	call DSP_DispatchCommand
	ld iz, hl
	ld bc, (xsp + 26)
	lds wa, 1
	call DSP_DispatchData
	ld iz, hl
	ld bc, (xsp + 26)
	ldw wa, 0x60
	call DSP_DispatchData
	ld iz, hl

DSP_WriteLUT_MainLoop_FirstEntry:
	ld wa, (xsp + 4)
	sll wa, 2
	ld iz, wa
	add iz, (xsp + 14)
	lda xwa, (xsp + 10)
	calr DSP_UnpackParam3B
	pushm (xsp + 24)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 28)
	calr DSP_WriteFreqParam
	ld iz, hl
	lda xwa, (xsp + 10)
	calr DSP_UnpackParam3B
	ld xwa, xhl
	ld bc, (xsp + 26)
	ld de, (xsp + 24)
	calr DSP_WriteCoeffData_5B
	ld iz, hl
	lda xwa, (xsp + 10)
	calr DSP_UnpackParam3B
	ld xwa, xhl
	ld bc, (xsp + 26)
	ld de, (xsp + 24)
	calr DSP_WriteCoeffData_5B
	ld iz, hl
	lda xwa, (xsp + 10)
	calr DSP_UnpackParam3B
	ld xwa, xhl
	ld bc, (xsp + 26)
	ld de, (xsp + 24)
	calr DSP_WriteCoeffData_5B
	ld iz, hl
	ld bc, (xsp + 26)
	lds wa, 3
	call DSP_DispatchCommand
	incm 1, (xsp + 4)
	ld wa, (xsp + 2)
	srl wa, 2
	cp (xsp + 4), wa
	jrl c, DSP_WriteLUT_MainLoop_Body

DSP_WriteLUT_MainLoop_Done:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 6)
	ld (xwa), xbc
	ld hl, iz
	popw iz
	lda xsp, (xsp + 18)
	retd 0x4

DSP_WriteOscParam:
	dec 6, xsp
	pushw iz
	ld iz, de
	ld (xsp + 2), xbc
	ld (xsp + 6), wa
	ld wa, iz
	cps wa, 1
	jrl z, DSP_WriteOscParam_UseCmd30
	ld bc, iz
	ldw wa, 0x8
	call DSP_DispatchData
	ld bc, iz
	lds wa, 1
	call DSP_DispatchData
	ld wa, (xsp + 12)
	add wa, (xsp + 6)
	srl wa, 4
	and wa, 0xF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld wa, (xsp + 12)
	add wa, (xsp + 6)
	sll wa, 4
	and wa, 0xF0
	inc 8, wa
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld bc, iz
	ldw wa, 0x21
	call DSP_DispatchData
	ld bc, iz
	ldw wa, 0xA
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sra xwa, 1
	sra xwa, 0
	and xwa, 0x7F
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sra xwa, 9
	and xwa, 0xFF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sra xwa, 1
	and xwa, 0xFF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sla xwa, 7
	and xwa, 0x80
	add xwa, 0x26
	extz wa
	ld bc, iz
	call DSP_DispatchData
	jr DSP_WriteOscParam_Return

DSP_WriteOscParam_UseCmd30:
	ld wa, iz
	ld bc, (xsp + 6)
	ld xde, (xsp + 2)
	calr DSP_WriteParamCmd30

DSP_WriteOscParam_Return:
	popw iz
	inc 6, xsp
	retd 0x2

DSP_WriteCoeffData_5B_Direct:
	dec 2, xsp
	push xiz
	ld (xsp + 4), bc
	ld xiz, xwa
	ld bc, (xsp + 4)
	ldw wa, 0xA
	call DSP_DispatchData
	ld xwa, xiz
	sra xwa, 1
	sra xwa, 0
	and xwa, 0x7F
	extz wa
	ld bc, (xsp + 4)
	call DSP_DispatchData
	ld xwa, xiz
	sra xwa, 9
	and xwa, 0xFF
	extz wa
	ld bc, (xsp + 4)
	call DSP_DispatchData
	ld xwa, xiz
	sra xwa, 1
	and xwa, 0xFF
	extz wa
	ld bc, (xsp + 4)
	call DSP_DispatchData
	ld xwa, xiz
	sla xwa, 7
	and xwa, 0x80
	add xwa, 0x26
	extz wa
	ld bc, (xsp + 4)
	call DSP_DispatchData
	pop xiz
	inc 2, xsp
	ret

DSP_WriteOscParam_Offset:
	dec 6, xsp
	pushw iz
	ld iz, de
	ld (xsp + 2), xbc
	ld (xsp + 6), wa
	ld bc, iz
	ldw wa, 0x8
	call DSP_DispatchData
	ld bc, iz
	lds wa, 1
	call DSP_DispatchData
	ld wa, (xsp + 16)
	add wa, (xsp + 6)
	srl wa, 4
	and wa, 0xF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld wa, (xsp + 16)
	add wa, (xsp + 6)
	sll wa, 4
	and wa, 0xF0
	inc 8, wa
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld bc, iz
	ldw wa, 0x25
	call DSP_DispatchData
	ld xwa, (xsp + 12)
	add (xsp + 2), xwa
	ld bc, iz
	ldw wa, 0xA
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sra xwa, 1
	sra xwa, 0
	and xwa, 0x7F
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sra xwa, 9
	and xwa, 0xFF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sra xwa, 1
	and xwa, 0xFF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld xwa, (xsp + 2)
	sla xwa, 7
	and xwa, 0x80
	add xwa, 0x4C
	extz wa
	ld bc, iz
	call DSP_DispatchData
	popw iz
	inc 6, xsp
	retd 0x6
	dec 8, xsp
	pushw iz
	ld iz, de
	ld (xsp + 6), bc
	ld (xsp + 8), wa
	ld xhl, (xsp + 20)
	ldw bc, 0x78
	lda xwa, (xsp + 4)
	push xwa
	ld xwa, xhl
	ld de, (xsp + 18)
	call DSP_TableWalk_Search
	ld wa, (xsp + 6)
	mul wa, 0x3
	ld bc, wa
	ld a, (xhl)
	and a, 0xFF
	extz wa
	add wa, bc
	ld (xsp + 2), wa
	ld bc, iz
	lds wa, 1
	call DSP_DispatchCommand
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld wa, (xsp + 2)
	incm 1, (xsp + 2)
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	cpw (xsp + 18), 0x63
	jr z, DSP_AlgoSelect_TypeEq63
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld wa, (xsp + 16)
	add wa, (xsp + 8)
	srl wa, 4
	and wa, 0xF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld wa, (xsp + 16)
	add wa, (xsp + 8)
	sll wa, 4
	and wa, 0xF0
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	jr DSP_AlgoSelect_WriteHeader

DSP_AlgoSelect_TypeEq63:
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	ldw wa, 0x20
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl

DSP_AlgoSelect_WriteHeader:
	cpw (xsp + 6), 0x0
	jr nz, DSP_AlgoSelect_WriteHeaderNonZero
	ld bc, iz
	ldw wa, 0x8
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	ldw wa, 0x80
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	ldw wa, 0xB4
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 7
	call DSP_DispatchData
	ld (xsp + 4), hl
	jr DSP_AlgoSelect_HeaderReturn

DSP_AlgoSelect_WriteHeaderNonZero:
	ld wa, (xsp + 2)
	srl wa, 7
	and wa, 0x2
	add wa, 0xC
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld wa, (xsp + 2)
	srl wa, 7
	and wa, 0x1
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld wa, (xsp + 2)
	add wa, wa
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 4
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 7
	call DSP_DispatchData
	ld (xsp + 4), hl

DSP_AlgoSelect_HeaderReturn:
	ld hl, (xsp + 4)
	popw iz
	inc 8, xsp
	retd 0xA
	dec 8, xsp
	pushw iz
	ld iz, de
	ld (xsp + 6), bc
	ld (xsp + 8), wa
	ld xhl, (xsp + 20)
	ldw bc, 0x78
	lda xwa, (xsp + 4)
	push xwa
	ld xwa, xhl
	ld de, (xsp + 18)
	call DSP_TableWalk_Search
	ld wa, (xsp + 6)
	mul wa, 0x3
	ld bc, wa
	ld a, (xhl)
	and a, 0xFF
	extz wa
	add wa, bc
	ld (xsp + 2), wa
	ld bc, iz
	lds wa, 1
	call DSP_DispatchCommand
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld wa, (xsp + 2)
	incm 1, (xsp + 2)
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	ldw wa, 0x8
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 1
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld wa, (xsp + 18)
	add wa, (xsp + 8)
	srl wa, 4
	and wa, 0xF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld wa, (xsp + 16)
	add wa, (xsp + 8)
	sll wa, 4
	and wa, 0xF0
	inc 8, wa
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	ldw wa, 0x21
	call DSP_DispatchData
	ld (xsp + 4), hl
	cpw (xsp + 6), 0x0
	jr nz, DSP_OscAlgoSelect_WriteHeaderNonZero
	ld bc, iz
	ldw wa, 0x8
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	ldw wa, 0x80
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	ldw wa, 0xB4
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	ldw wa, 0x8
	call DSP_DispatchData
	ld (xsp + 4), hl
	jr DSP_OscAlgoSelect_Return

DSP_OscAlgoSelect_WriteHeaderNonZero:
	ld wa, (xsp + 2)
	srl wa, 7
	and wa, 0x2
	add wa, 0xC
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld wa, (xsp + 2)
	srl wa, 7
	and wa, 0x1
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld wa, (xsp + 2)
	add wa, wa
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 4
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	ldw wa, 0x8
	call DSP_DispatchData
	ld (xsp + 4), hl

DSP_OscAlgoSelect_Return:
	ld hl, (xsp + 4)
	popw iz
	inc 8, xsp
	retd 0xA
	dec 8, xsp
	pushw iz
	ld iz, bc
	ld (xsp + 6), xwa
	ldw bc, 0x79
	lda xwa, (xsp + 4)
	push xwa
	ld xwa, xde
	ld de, (xsp + 20)
	call DSP_TableWalk_Search
	ld xde, xhl
	ld a, (xde)
	extz wa
	ld (xsp + 2), wa
	cpw (xsp + 14), 0x0
	jr z, DSP_TuneOffset_WriteSequence
	ld wa, (xsp + 16)
	cps wa, 1
	jr z, DSP_TuneOffset_Increment
	cps wa, 0
	jr nz, DSP_TuneOffset_WriteSequence
	decm 1, (xsp + 2)
	jr DSP_TuneOffset_WriteSequence

DSP_TuneOffset_Increment:
	incm 1, (xsp + 2)

DSP_TuneOffset_WriteSequence:
	ld bc, iz
	lds wa, 1
	call DSP_DispatchCommand
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 1
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	ldw wa, 0x60
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld wa, (xsp + 2)
	srl wa, 4
	and wa, 0xF
	add wa, 0x10
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld wa, (xsp + 2)
	sll wa, 4
	and wa, 0xF0
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 0
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	ldw wa, 0xA
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld xwa, (xsp + 6)
	sra xwa, 1
	sra xwa, 0
	and xwa, 0x7F
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld xwa, (xsp + 6)
	sra xwa, 9
	and xwa, 0xFF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld xwa, (xsp + 6)
	sra xwa, 1
	and xwa, 0xFF
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld xwa, (xsp + 6)
	sla xwa, 7
	and xwa, 0x80
	add xwa, 0x15
	extz wa
	ld bc, iz
	call DSP_DispatchData
	ld (xsp + 4), hl
	ld bc, iz
	lds wa, 3
	call DSP_DispatchCommand
	ld (xsp + 4), hl
	ld hl, (xsp + 4)
	popw iz
	inc 8, xsp
	retd 0x4

DSP_State_DmaLoadPresets:
	lds wa, 3
	call TaskSched_SpawnTask
	lda_24 xwa, 0x045324
	ld xbc, xwa
	lds wa, 1
	call TaskMsgQ_Send
	lda_24 xwa, 0x045446
	ld xbc, xwa
	lds wa, 1
	jp TaskMsgQ_Send
DSP_State_InlineData:
	push xiz
	lds	wa, 2
	call	132674
	ld	xiz, xhl
	ld	xwa, xiz
	call	224829
	ldw	(xiz+288), 0
	ld	xwa, xiz
	ld	xbc, xwa
	lds	wa, 1
	call	132305
	jr	t, 0xdf

DSP_State_ApplyBuf:
	push xiz
	ld xiz, xwa
	lds wa, 2
	call TaskMsgQ_TryReceive
	stda32 19002, xhl
	or xhl, xhl
	jr nz, DSP_State_ApplyBuf_DoCopy
	lds wa, 1
	call TaskMsgQ_Receive
	stda32 19002, xhl

DSP_State_ApplyBuf_DoCopy:
	ldda32 xix, 19002
	ld xiy, xiz
	ldw bc, 0x91
	ldirw
	ldda32 xwa, 19002
	stiw_ind 0xE1, 0x20, 0x01, 0x01, 0x00
	ldda32 xbc, 19002
	lds wa, 2
	call TaskMsgQ_Send
	pop xiz
	ret

DSP_State_LoadAndApplyAll:
	lda_24 xde, 0x045324
	stda32 19006, xde
	ld xiy, xwa
	ld xix, xde
	ldw bc, 0x91
	ldirw
	ldda32 xwa, 19006
	stiw_ind 0xE1, 0x20, 0x01, 0x01, 0x00
	ldda32 xwa, 19006
	call DSP_State_ApplyAll
	ldda32 xwa, 19006
	stiw_ind 0xE1, 0x20, 0x01, 0x00, 0x00
	ret

DSP_State_LoadAndApply_InlineData:
	.byte 0xe9, 0xee, 0x02, 0x40, 0xa3, 0x29, 0x01, 0x00
	.byte 0xe9, 0x80, 0xa0, 0x23, 0x0e

DSP_ParamFetch_SingleTable:
	sll xbc, 2
	ld xwa, 0x12B33
	add xwa, xbc
	ld xhl, (xwa)
	ret

DSP_ParamFetch_AlgoTypeTable:
	ld xix, (xwa)
	ld e, (xix)
	cps e, 2
	jr z, DSP_ParamFetch_AlgoType2
	cps e, 1
	jr z, DSP_ParamFetch_AlgoType1
	cps e, 0
	jr nz, DSP_ParamFetch_AlgoTypeReturn
	sll xbc, 2
	ld xde, 0x12483
	add xde, xbc
	ld xhl, (xde)
	jr DSP_ParamFetch_AlgoTypeReturn

DSP_ParamFetch_AlgoType1:
	sll xbc, 2
	ld xde, 0x12613
	add xde, xbc
	ld xhl, (xde)
	jr DSP_ParamFetch_AlgoTypeReturn

DSP_ParamFetch_AlgoType2:
	sll xbc, 2
	ld xde, 0x127A3
	add xde, xbc
	ld xhl, (xde)

DSP_ParamFetch_AlgoTypeReturn:
	inc 1, xix
	ld (xwa), xix
	ret

DSP_AlgoParam_Decode:
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 28), xwa
	ld xwa, (xsp + 28)
	ld xwa, (xwa)
	ld (xsp + 4), xwa
	ld a, (xwa)
	cps a, 1
	jr z, DSP_AlgoParam_Decode_Type1
	sll xbc, 2
	ld xwa, 0x127A3
	add xwa, xbc
	ld xwa, (xwa)
	cpl wa
	cplw_erp 0xE2
	inc 1, xwa
	ld (xsp + 20), xwa
	lda xbc, (xsp + 20)
	lda xwa, (xsp + 8)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 8)
	lda xwa, (xsp + 12)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 12)
	lda_24 xde, 0x012cc3
	lda xwa, (xsp + 12)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 24)
	call FP_DP_DecodeToInt
	jr DSP_AlgoParam_Decode_Return

DSP_AlgoParam_Decode_Type1:
	sll xbc, 2
	ld xiz, 0x127A3
	add xiz, xbc
	lda xwa, (xsp + 8)
	ld xbc, xiz
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 8)
	lda xwa, (xsp + 12)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 12)
	lda_24 xde, 0x012ccb
	lda xwa, (xsp + 12)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 24)
	call FP_DP_DecodeToInt

DSP_AlgoParam_Decode_Return:
	lds32 xwa, 1
	add (xsp + 4), xwa
	ld xwa, (xsp + 28)
	ld xbc, (xsp + 4)
	ld (xwa), xbc
	ld xhl, (xsp + 24)
	pop xiz
	lda xsp, (xsp + 28)
	ret

DSP_PitchParam_Scale:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 12)
	ld xiz, (xwa)
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	ld xwa, (xsp + 4)
	sra xwa, 8
	and_erpw 0xE2, 0xFF, 0x00
	ld (xsp + 4), xwa
	ld xwa, (xsp + 8)
	sla xwa, 5
	sla xwa, 0
	ld xbc, (xsp + 4)
	call Int_SignedDiv_AltEntry
	sla xhl, 2
	add xhl, 0xFF800000
	ld xwa, (xsp + 12)
	ld (xwa), xiz
	pop xiz
	lda xsp, (xsp + 12)
	ret

DSP_VolumeParam_Scale:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ld xwa, (xsp + 4)
	ld xiz, (xwa)
	ldb_spi A, 0xF8
	cps a, 2
	jrl z, DSP_VolScale_Algo2_Seg1
	cps a, 1
	jrl z, DSP_VolScale_Algo1_Seg1
	cps a, 0
	jrl nz, DSP_VolScale_Return
	cp xbc, 0x32
	jr gt, DSP_VolScale_Algo0_Seg2
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, 0x6BAA8
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_Return

DSP_VolScale_Algo0_Seg2:
	cp xbc, 0x4B
	jr gt, DSP_VolScale_Algo0_Seg3
	sub xbc, 0x19
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, 0x35D54
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_Return

DSP_VolScale_Algo0_Seg3:
	cp xbc, 0x58
	jr gt, DSP_VolScale_Algo0_Seg4
	sla xbc, 2
	sub xbc, 0xFA
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, 0x35D54
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_Return

DSP_VolScale_Algo0_Seg4:
	ld xwa, xbc
	sla xwa, 3
	add xwa, xbc
	sub xwa, 0x2B2
	sla xwa, 7
	sla xwa, 0
	ld xbc, 0x35D54
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_Return

DSP_VolScale_Algo1_Seg1:
	cp xbc, 0xA
	jr gt, DSP_VolScale_Algo1_Seg2
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, 0xAC44
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_Return

DSP_VolScale_Algo1_Seg2:
	cp xbc, 0x13
	jr gt, DSP_VolScale_Algo1_Seg3
	ld xwa, xbc
	sla xwa, 2
	add xwa, xbc
	add xwa, xwa
	sub xwa, 0x5A
	sla xwa, 7
	sla xwa, 0
	ld xbc, 0xAC44
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_Return

DSP_VolScale_Algo1_Seg3:
	cp xbc, 0x40
	jr gt, DSP_VolScale_Algo1_Seg4
	ld xwa, xbc
	sla xwa, 2
	add xwa, xbc
	sla xwa, 2
	sub xwa, 0x118
	sla xwa, 15
	ld xbc, 0xAC44
	call Int_SignedDiv_AltEntry
	sla xhl, 8
	jrl DSP_VolScale_Return

DSP_VolScale_Algo1_Seg4:
	cp xbc, 0x57
	jr gt, DSP_VolScale_Algo1_Seg5
	ld xwa, xbc
	ld xbc, 0x190
	call FP_MulAccum64
	sub xhl, 0x60E0
	sla xhl, 15
	ld xwa, xhl
	ld xbc, 0xAC44
	call Int_SignedDiv_AltEntry
	sla xhl, 8
	jrl DSP_VolScale_Return

DSP_VolScale_Algo1_Seg5:
	ld xwa, xbc
	ld xbc, 0x320
	call FP_MulAccum64
	sub xhl, 0xE8D0
	sla xhl, 15
	ld xwa, xhl
	ld xbc, 0xAC44
	call Int_SignedDiv_AltEntry
	sla xhl, 8
	jrl DSP_VolScale_Return

DSP_VolScale_Algo2_Seg1:
	cp xbc, 0x32
	jr gt, DSP_VolScale_Algo2_Seg2
	ld xwa, xbc
	add xwa, xwa
	ld xde, 0xFA0
	sub xde, xwa
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, xde
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_Return

DSP_VolScale_Algo2_Seg2:
	cp xbc, 0x4B
	jr gt, DSP_VolScale_Algo2_Seg3
	ld xwa, xbc
	add xwa, xwa
	sub xwa, 0x66
	ld xde, 0x79C
	sub xde, xwa
	sub xbc, 0x19
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, xde
	call Int_SignedDiv_AltEntry
	jr DSP_VolScale_Return

DSP_VolScale_Algo2_Seg3:
	cp xbc, 0x58
	jr gt, DSP_VolScale_Algo2_Seg4
	ld xwa, xbc
	sla xwa, 3
	sub xwa, 0x260
	ld xde, 0x764
	sub xde, xwa
	sla xbc, 2
	sub xbc, 0xFA
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, xde
	call Int_SignedDiv_AltEntry
	jr DSP_VolScale_Return

DSP_VolScale_Algo2_Seg4:
	ld xwa, xbc
	sla xwa, 3
	add xwa, xbc
	add xwa, xwa
	sub xwa, 0x642
	ld xde, 0x6F2
	sub xde, xwa
	ld xwa, xbc
	sla xwa, 3
	add xwa, xbc
	sub xwa, 0x2B2
	sla xwa, 7
	sla xwa, 0
	ld xbc, xde
	call Int_SignedDiv_AltEntry

DSP_VolScale_Return:
	ld xwa, (xsp + 4)
	ld (xwa), xiz
	pop xiz
	inc 4, xsp
	ret

DSP_ParamInterp_2Point:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld xwa, (xsp + 16)
	ld xiz, (xwa)
	lda xwa, (xsp + 8)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	ld xwa, (xsp + 4)
	sub xwa, (xsp + 8)
	sra xwa, 8
	ld xbc, (xsp + 12)
	call FP_MulAccum64
	ld xwa, xhl
	ld xbc, 0x63
	call Int_SignedDiv_AltEntry
	ld xwa, xhl
	ld xhl, (xsp + 8)
	sra xhl, 8
	add xhl, xwa
	ld xwa, (xsp + 16)
	ld (xwa), xiz
	pop xiz
	lda xsp, (xsp + 16)
	ret

DSP_ParamInterp_FPScale:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 12)
	ld xiz, (xwa)
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	ld xwa, (xsp + 4)
	sra xwa, 8
	and_erpw 0xE2, 0xFF, 0x00
	ld (xsp + 4), xwa
	ld xwa, (xsp + 8)
	ld xbc, 0xAC44
	call FP_MulAccum64
	ld xwa, xhl
	ld xbc, 0x3E8
	call Int_SignedDiv_AltEntry
	add xhl, (xsp + 4)
	ld xwa, (xsp + 12)
	ld (xwa), xiz
	pop xiz
	lda xsp, (xsp + 12)
	ret

DSP_ParamInterp_Div0xB4:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 12)
	ld xiz, (xwa)
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	ld xwa, (xsp + 4)
	sra xwa, 8
	and_erpw 0xE2, 0xFF, 0x00
	ld (xsp + 4), xwa
	ld xbc, (xsp + 8)
	call FP_MulAccum64
	ld xwa, xhl
	ld xbc, 0xB4
	call Int_SignedDiv_AltEntry
	ld xwa, (xsp + 12)
	ld (xwa), xiz
	pop xiz
	lda xsp, (xsp + 12)
	ret

DSP_VolumeCurve_FP:
	lda xsp, (xsp - 68)
	ld (xsp + 64), xbc
	ld xwa, (xsp + 64)
	cp xwa, 0x4B
	jrl gt, DSP_VolumeCurve_FP_HighRange
	lda xbc, (xsp + 64)
	lda xwa, (xsp + 36)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012cd3
	lda xwa, (xsp + 36)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012cd7
	lda xwa, (xsp + 36)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012cdb
	lda xwa, (xsp + 36)
	call FP_SP_Mul
	lda_24 xbc, 0x012cdf
	lda xde, (xsp + 36)
	lda xwa, (xsp + 36)
	call FP_SP_Sub
	lda_24 xbc, 0x012ce3
	lda xde, (xsp + 36)
	lda xwa, (xsp + 36)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 36)
	lda xwa, (xsp + 28)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 28)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012ce7
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 64)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 48)
	lda xwa, (xsp + 60)
	call FP_DP_NormalizeMantissa
	jrl DSP_VolumeCurve_FP_Finalize

DSP_VolumeCurve_FP_HighRange:
	lda xbc, (xsp + 64)
	lda xwa, (xsp + 36)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012cef
	lda xwa, (xsp + 36)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012cf3
	lda xwa, (xsp + 36)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012cf7
	lda xwa, (xsp + 36)
	call FP_SP_Sub
	lda_24 xbc, 0x012cfb
	lda xde, (xsp + 36)
	lda xwa, (xsp + 36)
	call FP_SP_Sub
	lda_24 xbc, 0x012cff
	lda xde, (xsp + 36)
	lda xwa, (xsp + 36)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 36)
	lda xwa, (xsp + 28)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 28)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012d03
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 56)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 40)
	lda xwa, (xsp + 60)
	call FP_DP_NormalizeMantissa

DSP_VolumeCurve_FP_Finalize:
	lda xbc, (xsp + 60)
	lda_24 xde, 0x012d0b
	lda xwa, (xsp + 36)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 36)
	lda xwa, (xsp + 56)
	call FP_SP_Decode_ReadSign
	ld xhl, (xsp + 56)
	lda xsp, (xsp + 68)
	ret

DSP_FreqCurve_FP:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	cp xiz, 0x14
	jr gt, DSP_FreqCurve_FP_Seg2
	ld xwa, xiz
	add xwa, xwa
	ld xbc, 0xFA0
	sub xbc, xwa
	ld xwa, xiz
	sla xwa, 7
	sla xwa, 0
	call Int_SignedDiv_AltEntry
	jr DSP_FreqCurve_FP_Return

DSP_FreqCurve_FP_Seg2:
	cp xiz, 0x32
	jr gt, DSP_FreqCurve_FP_Seg3
	ld xwa, xiz
	add xwa, xwa
	sub xwa, 0x2A
	ld xbc, 0x7BA
	sub xbc, xwa
	ld xwa, xiz
	sub xwa, 0xA
	sla xwa, 7
	sla xwa, 0
	call Int_SignedDiv_AltEntry
	jr DSP_FreqCurve_FP_Return

DSP_FreqCurve_FP_Seg3:
	ld xwa, xiz
	ld xbc, 0x16
	call FP_MulAccum64
	sub xhl, 0x462
	ld xwa, 0x1DEA
	sub xwa, xhl
	ld (xsp + 4), xwa
	ld xwa, xiz
	ld xbc, 0xB
	call FP_MulAccum64
	sub xhl, 0x186
	sla xhl, 15
	ld xwa, xhl
	ld xbc, (xsp + 4)
	call Int_SignedDiv_AltEntry
	sla xhl, 8

DSP_FreqCurve_FP_Return:
	pop xiz
	inc 4, xsp
	ret

DSP_FreqInterp_2Point:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld xwa, (xsp + 16)
	ld xiz, (xwa)
	lda xwa, (xsp + 8)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	ld xwa, (xsp + 4)
	sub xwa, (xsp + 8)
	sra xwa, 8
	ld xbc, (xsp + 12)
	call FP_MulAccum64
	ld xwa, xhl
	ld xbc, 0x63
	call Int_SignedDiv_AltEntry
	ld xwa, xhl
	ld xhl, (xsp + 8)
	sra xhl, 8
	add xhl, xwa
	ld xwa, (xsp + 16)
	ld (xwa), xiz
	pop xiz
	lda xsp, (xsp + 16)
	ret

DSP_ParamInterp_3Point_WithOffset:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld (xsp + 20), xwa
	ld xwa, (xsp + 20)
	ld xiz, (xwa)
	lda xwa, (xsp + 8)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	ld xwa, (xsp + 8)
	sra xwa, 8
	and_erpw 0xE2, 0xFF, 0x00
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	sra xwa, 8
	and_erpw 0xE2, 0xFF, 0x00
	ld (xsp + 4), xwa
	sub xwa, (xsp + 8)
	ld xbc, (xsp + 16)
	call FP_MulAccum64
	ld xwa, xhl
	ld xbc, 0x63
	call Int_SignedDiv_AltEntry
	ld xwa, (xsp + 12)
	add xwa, (xsp + 8)
	add xwa, xhl
	sla xwa, 8
	ld xbc, (xsp + 20)
	ld (xbc), xiz
	ld xhl, xwa
	pop xiz
	lda xsp, (xsp + 20)
	ret

DSP_ReverbCurve_FP:
	lda xsp, (xsp - 68)
	ld (xsp + 64), xbc
	ld xwa, (xsp + 64)
	cp xwa, 0x59
	jr gt, DSP_ReverbCurve_FP_HighRange
	lda xbc, (xsp + 64)
	lda xwa, (xsp + 28)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 28)
	lda_24 xde, 0x012d0f
	lda xwa, (xsp + 28)
	call FP_SP_Mul
	lda xbc, (xsp + 28)
	lda xwa, (xsp + 40)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 40)
	lda_24 xde, 0x012d13
	lda xwa, (xsp + 40)
	call FP_DP_Add_Outer
	lda_24 xbc, 0x012d1b
	lda xde, (xsp + 40)
	lda xwa, (xsp + 40)
	call VoiceFloat_SubDP
	lda xiy, (xsp + 40)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012d23
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 64)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda_24 xbc, 0x012d2b
	lda xde, (xsp + 48)
	lda xwa, (xsp + 40)
	call FP_DP_Sub
	lda xbc, (xsp + 40)
	lda xwa, (xsp + 60)
	call FP_DP_NormalizeMantissa
	jr DSP_ReverbCurve_FP_Finalize

DSP_ReverbCurve_FP_HighRange:
	lda xbc, (xsp + 64)
	lda xwa, (xsp + 28)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 28)
	lda_24 xde, 0x012d33
	lda xwa, (xsp + 28)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 28)
	lda_24 xde, 0x012d37
	lda xwa, (xsp + 28)
	call FP_SP_Sub
	lda_24 xbc, 0x012d3b
	lda xde, (xsp + 28)
	lda xwa, (xsp + 28)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 28)
	lda xwa, (xsp + 40)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 40)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012d3f
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 48)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda_24 xbc, 0x012d47
	lda xde, (xsp + 32)
	lda xwa, (xsp + 40)
	call FP_DP_Sub
	lda xbc, (xsp + 40)
	lda xwa, (xsp + 60)
	call FP_DP_NormalizeMantissa

DSP_ReverbCurve_FP_Finalize:
	lda xbc, (xsp + 60)
	lda_24 xde, 0x012d4f
	lda xwa, (xsp + 28)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 28)
	lda xwa, (xsp + 56)
	call FP_SP_Decode_ReadSign
	ld xhl, (xsp + 56)
	lda xsp, (xsp + 68)
	ret

DSP_ParamInterp_FPComplex:
	lda xsp, (xsp - 52)
	push xiz
	ld (xsp + 48), xbc
	ld (xsp + 52), xwa
	ld xwa, (xsp + 52)
	ld xiz, (xwa)
	lda xwa, (xsp + 40)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xbc, (xsp + 40)
	lda xwa, (xsp + 20)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 20)
	lda_24 xde, 0x012d53
	lda xwa, (xsp + 20)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 20)
	lda_24 xde, 0x012d57
	lda xwa, (xsp + 28)
	call VoiceFloat_SubSP
	lda xwa, (xsp + 36)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	ld xwa, (xsp + 36)
	sra xwa, 8
	and_erpw 0xE2, 0xFF, 0x00
	ld (xsp + 36), xwa
	lda xbc, (xsp + 48)
	lda xwa, (xsp + 20)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 36)
	lda xwa, (xsp + 24)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 24)
	lda xde, (xsp + 28)
	lda xwa, (xsp + 24)
	call FP_SP_Sub
	lda xbc, (xsp + 24)
	lda xde, (xsp + 20)
	lda xwa, (xsp + 24)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 28)
	lda_24 xde, 0x012d5b
	lda xwa, (xsp + 20)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 20)
	lda xde, (xsp + 24)
	lda xwa, (xsp + 24)
	call FP_SP_Mul
	lda xbc, (xsp + 24)
	lda_24 xde, 0x012d5f
	lda xwa, (xsp + 24)
	call FP_SP_Add_Outer
	lda_24 xbc, 0x012d63
	lda xde, (xsp + 24)
	lda xwa, (xsp + 24)
	call FP_SP_Sub
	lda_24 xbc, 0x012d67
	lda xde, (xsp + 24)
	lda xwa, (xsp + 24)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 24)
	lda xwa, (xsp + 4)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 4)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012d6b
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 28)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 44)
	call FP_DP_NormalizeMantissa
	ld xwa, (xsp + 52)
	ld (xwa), xiz
	lda xbc, (xsp + 44)
	lda_24 xde, 0x012d73
	lda xwa, (xsp + 24)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 24)
	lda xwa, (xsp + 32)
	call FP_SP_Decode_ReadSign
	ld xhl, (xsp + 32)
	pop xiz
	lda xsp, (xsp + 52)
	ret

DSP_PanCurve_PiecewiseLin:
	cp xbc, 0x14
	jr gt, DSP_PanCurve_Seg2
	add xbc, xbc
	ld xwa, xbc
	ld xbc, 0xAC44
	call FP_MulAccum64
	add xhl, 0x6BAA8
	ld xwa, xhl
	ld xbc, 0x3E8
	call Int_SignedDiv_AltEntry
	jrl DSP_PanCurve_Return

DSP_PanCurve_Seg2:
	cp xbc, 0x1E
	jr gt, DSP_PanCurve_Seg3
	ld xwa, xbc
	sla xwa, 2
	add xwa, xbc
	ld xbc, 0xAC44
	call FP_MulAccum64
	sub xhl, 0x21A548
	ld xwa, xhl
	ld xbc, 0x3E8
	call Int_SignedDiv_AltEntry
	jrl DSP_PanCurve_Return

DSP_PanCurve_Seg3:
	cp xbc, 0x46
	jr gt, DSP_PanCurve_Seg4
	ld xwa, xbc
	sla xwa, 2
	add xwa, xbc
	add xwa, xwa
	ld xbc, 0xAC44
	call FP_MulAccum64
	sub xhl, 0x869520
	ld xwa, xhl
	ld xbc, 0x3E8
	call Int_SignedDiv_AltEntry
	jr DSP_PanCurve_Return

DSP_PanCurve_Seg4:
	cp xbc, 0x50
	jr gt, DSP_PanCurve_Seg5
	ld xwa, xbc
	ld xbc, 0x32
	call FP_MulAccum64
	ld xwa, xhl
	ld xbc, 0xAC44
	call FP_MulAccum64
	sub xhl, 0x7E2BCE0
	ld xwa, xhl
	ld xbc, 0x3E8
	call Int_SignedDiv_AltEntry
	jr DSP_PanCurve_Return

DSP_PanCurve_Seg5:
	ld xwa, xbc
	ld xbc, 0x64
	call FP_MulAccum64
	ld xwa, xhl
	ld xbc, 0xAC44
	call FP_MulAccum64
	sub xhl, 0x12666360
	ld xwa, xhl
	ld xbc, 0x3E8
	call Int_SignedDiv_AltEntry

DSP_PanCurve_Return:
	ret

DSP_DetuneCurve_SignedFP:
	lda xsp, (xsp - 72)
	push xiz
	ld xiz, xbc
	cp xiz, 0x0
	jr lt, DSP_DetuneCurve_NegateInput
	ld xwa, xiz
	jr DSP_DetuneCurve_CheckMagnitude

DSP_DetuneCurve_NegateInput:
	ld xwa, xiz
	cpl wa
	cplw_erp 0xE2
	inc 1, xwa

DSP_DetuneCurve_CheckMagnitude:
	cp xwa, 0xA
	jr gt, DSP_DetuneCurve_CheckRange2
	cp xiz, 0x0
	jr lt, DSP_DetuneCurve_Range1_NegArm
	ld (xsp + 60), xiz
	jr DSP_DetuneCurve_Range1_Compute

DSP_DetuneCurve_Range1_NegArm:
	ld xwa, xiz
	cpl wa
	cplw_erp 0xE2
	inc 1, xwa
	ld (xsp + 60), xwa

DSP_DetuneCurve_Range1_Compute:
	lda xbc, (xsp + 60)
	lda xwa, (xsp + 36)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012d77
	lda xwa, (xsp + 68)
	call FP_SP_Add_Outer
	jrl DSP_DetuneCurve_ApplySign

DSP_DetuneCurve_CheckRange2:
	cp xiz, 0x0
	jr lt, DSP_DetuneCurve_Range2_NegArm
	ld xwa, xiz
	jr DSP_DetuneCurve_CheckRange2Limit

DSP_DetuneCurve_Range2_NegArm:
	ld xwa, xiz
	cpl wa
	cplw_erp 0xE2
	inc 1, xwa

DSP_DetuneCurve_CheckRange2Limit:
	cp xwa, 0x13
	jr gt, DSP_DetuneCurve_CheckRange3
	cp xiz, 0x0
	jr lt, DSP_DetuneCurve_Range2_NegStore
	ld (xsp + 56), xiz
	jr DSP_DetuneCurve_Range2_Compute

DSP_DetuneCurve_Range2_NegStore:
	ld xwa, xiz
	cpl wa
	cplw_erp 0xE2
	inc 1, xwa
	ld (xsp + 56), xwa

DSP_DetuneCurve_Range2_Compute:
	lda xbc, (xsp + 56)
	lda xwa, (xsp + 36)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012d7b
	lda xwa, (xsp + 36)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012d7f
	lda xwa, (xsp + 68)
	call FP_SP_Sub
	jrl DSP_DetuneCurve_ApplySign

DSP_DetuneCurve_CheckRange3:
	cp xiz, 0x0
	jr lt, DSP_DetuneCurve_Range3_NegArm
	ld xwa, xiz
	jr DSP_DetuneCurve_CheckRange3Limit

DSP_DetuneCurve_Range3_NegArm:
	ld xwa, xiz
	cpl wa
	cplw_erp 0xE2
	inc 1, xwa

DSP_DetuneCurve_CheckRange3Limit:
	cp xwa, 0x1F
	jr gt, DSP_DetuneCurve_Range4_CheckSign
	cp xiz, 0x0
	jr lt, DSP_DetuneCurve_Range3_NegStore
	ld (xsp + 52), xiz
	jr DSP_DetuneCurve_Range3_Compute

DSP_DetuneCurve_Range3_NegStore:
	ld xwa, xiz
	cpl wa
	cplw_erp 0xE2
	inc 1, xwa
	ld (xsp + 52), xwa

DSP_DetuneCurve_Range3_Compute:
	lda xbc, (xsp + 52)
	lda xwa, (xsp + 36)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012d83
	lda xwa, (xsp + 36)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012d87
	lda xwa, (xsp + 68)
	call FP_SP_Sub
	jr DSP_DetuneCurve_ApplySign

DSP_DetuneCurve_Range4_CheckSign:
	cp xiz, 0x0
	jr lt, DSP_DetuneCurve_Range4_NegStore
	ld (xsp + 48), xiz
	jr DSP_DetuneCurve_Range4_Compute

DSP_DetuneCurve_Range4_NegStore:
	ld xwa, xiz
	cpl wa
	cplw_erp 0xE2
	inc 1, xwa
	ld (xsp + 48), xwa

DSP_DetuneCurve_Range4_Compute:
	lda xbc, (xsp + 48)
	lda xwa, (xsp + 36)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012d8b
	lda xwa, (xsp + 36)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 36)
	lda_24 xde, 0x012d8f
	lda xwa, (xsp + 68)
	call FP_SP_Sub

DSP_DetuneCurve_ApplySign:
	cp xiz, 0x0
	jr ge, DSP_DetuneCurve_Finalize
	lda xbc, (xsp + 68)
	lda xwa, (xsp + 68)
	call FP_SP_CopyOrNegate4

DSP_DetuneCurve_Finalize:
	lda xbc, (xsp + 68)
	lda_24 xde, 0x012d93
	lda xwa, (xsp + 36)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 36)
	lda xwa, (xsp + 28)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 28)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012d97
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 56)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda_24 xbc, 0x012d9f
	lda xde, (xsp + 40)
	lda xwa, (xsp + 28)
	call FP_DP_Sub
	lda xbc, (xsp + 28)
	lda_24 xde, 0x012da7
	lda xwa, (xsp + 28)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 28)
	lda xwa, (xsp + 72)
	call FP_DP_NormalizeMantissa
	lda xbc, (xsp + 72)
	lda_24 xde, 0x012daf
	lda xwa, (xsp + 36)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 36)
	lda xwa, (xsp + 64)
	call FP_SP_Decode_ReadSign
	ld xhl, (xsp + 64)
	pop xiz
	lda xsp, (xsp + 72)
	ret

DSP_BiquadWarp_FP:
	lda xsp, (xsp - 88)
	pushw iz
	ld (xsp + 86), xwa
	ld de, (xsp + 100)
	ld xwa, (xsp + 86)
	ld xwa, (xwa)
	ld (xsp + 2), xwa
	ldb_spi L, 0xE0
	ld (xsp + 2), xwa
	and l, 0xF0
	jr nz, DSP_BiquadWarp_ReadPrevEntry
	ld wa, de
	extz xwa
	add xwa, xwa
	add xwa, xbc
	ld hl, (xwa)
	inc 1, de
	ld wa, de
	extz xwa
	add xwa, xwa
	add xwa, xbc
	ld iz, (xwa)
	jr DSP_BiquadWarp_ClampHL

DSP_BiquadWarp_ReadPrevEntry:
	ld wa, de
	dec 1, wa
	extz xwa
	add xwa, xwa
	add xwa, xbc
	ld hl, (xwa)
	ld wa, de
	extz xwa
	add xwa, xwa
	add xwa, xbc
	ld iz, (xwa)

DSP_BiquadWarp_ClampHL:
	cp hl, 0x59
	jr le, DSP_BiquadWarp_ClampIZ
	ldw hl, 0x59

DSP_BiquadWarp_ClampIZ:
	cp iz, 0x58
	jr le, DSP_BiquadWarp_ComputeCoeffs
	ldw iz, 0x58

DSP_BiquadWarp_ComputeCoeffs:
	ldw wa, 0x63
	sub wa, hl
	exts xwa
	ld (xsp + 14), xwa
	lda xbc, (xsp + 14)
	lda xwa, (xsp + 58)
	call FP_ScalarToDP
	lda xbc, (xsp + 58)
	lda_24 xde, 0x012db3
	lda xwa, (xsp + 58)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 58)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012dbb
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 66)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 50)
	lda_24 xde, 0x012dc3
	lda xwa, (xsp + 58)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 58)
	lda xwa, (xsp + 82)
	call FP_DP_NormalizeMantissa
	ldw wa, 0x63
	sub wa, iz
	exts xwa
	ld (xsp + 18), xwa
	lda xbc, (xsp + 18)
	lda xwa, (xsp + 58)
	call FP_ScalarToDP
	lda xbc, (xsp + 58)
	lda_24 xde, 0x012dcb
	lda xwa, (xsp + 58)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 58)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012dd3
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 58)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 42)
	lda_24 xde, 0x012ddb
	lda xwa, (xsp + 58)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 58)
	lda xwa, (xsp + 74)
	call FP_DP_NormalizeMantissa
	ld xwa, 0x40400000
	ld (xsp + 78), xwa
	lda xbc, (xsp + 82)
	lda_24 xde, 0x012de3
	lda xwa, (xsp + 10)
	call FP_SP_Sub
	lda xbc, (xsp + 82)
	lda_24 xde, 0x012de7
	lda xwa, (xsp + 6)
	call FP_SP_Sub
	lda xbc, (xsp + 6)
	lda xde, (xsp + 10)
	lda xwa, (xsp + 6)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 6)
	lda_24 xde, 0x012deb
	lda xwa, (xsp + 6)
	call FP_SP_Sub
	lda xbc, (xsp + 78)
	lda xde, (xsp + 74)
	lda xwa, (xsp + 10)
	call FP_SP_Sub
	lda xbc, (xsp + 10)
	lda xde, (xsp + 6)
	lda xwa, (xsp + 70)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 70)
	lda_24 xde, 0x012def
	lda xwa, (xsp + 6)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 6)
	lda xde, (xsp + 74)
	lda xwa, (xsp + 66)
	call FP_SP_Mul
	lda xbc, (xsp + 78)
	lda_24 xde, 0x012df3
	lda xwa, (xsp + 6)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 6)
	lda xwa, (xsp + 38)
	call FP_SP_Decode_ReadSign
	pushm (xsp + 94)
	ld wa, (xsp + 100)
	ld xbc, (xsp + 40)
	ld de, (xsp + 98)
	call DSP_WriteOscParam
	lda xbc, (xsp + 82)
	lda_24 xde, 0x012df7
	lda xwa, (xsp + 6)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 6)
	lda xwa, (xsp + 34)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 34)
	ld bc, (xsp + 96)
	ld de, (xsp + 94)
	call DSP_WriteCoeffData_5B_Direct
	lda xbc, (xsp + 70)
	lda xwa, (xsp + 6)
	call FP_SP_CopyOrNegate4
	lda xbc, (xsp + 6)
	lda_24 xde, 0x012dfb
	lda xwa, (xsp + 6)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 6)
	lda xwa, (xsp + 30)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 30)
	ld bc, (xsp + 96)
	ld de, (xsp + 94)
	call DSP_WriteCoeffData_5B_Direct
	lda xbc, (xsp + 70)
	lda_24 xde, 0x012dff
	lda xwa, (xsp + 6)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 6)
	lda xwa, (xsp + 26)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 26)
	ld bc, (xsp + 96)
	ld de, (xsp + 94)
	call DSP_WriteCoeffData_5B_Direct
	lda xbc, (xsp + 66)
	lda_24 xde, 0x012e03
	lda xwa, (xsp + 6)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 6)
	lda xwa, (xsp + 22)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 22)
	ld bc, (xsp + 96)
	ld de, (xsp + 94)
	call DSP_WriteCoeffData_5B_Direct
	ld xwa, (xsp + 86)
	ld xbc, (xsp + 2)
	ld (xwa), xbc
	popw iz
	lda xsp, (xsp + 88)
	retd 0x8

DSP_ParamInterp_Div0xC6:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 20), xbc
	ld (xsp + 24), xwa
	ld xwa, (xsp + 24)
	ld xwa, (xwa)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld xbc, xwa
	ld xwa, (xsp + 4)
	call DSP_StreamDecode_3ByteWord
	ld (xsp + 4), xhl
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, (xsp + 4)
	call DSP_StreamDecode_3ByteWord
	ld (xsp + 4), xhl
	ld xwa, (xsp + 20)
	ld (xsp + 8), xwa
	ld xwa, 0x63
	add (xsp + 8), xwa
	ld xwa, (xsp + 12)
	sub xwa, (xsp + 16)
	sra xwa, 8
	ld xbc, 0xC6
	call Int_SignedDiv_AltEntry
	ld xiz, xhl
	ld xbc, (xsp + 8)
	ld xwa, xiz
	call FP_MulAccum64
	ld xwa, xhl
	ld xhl, (xsp + 16)
	sra xhl, 8
	add xhl, xwa
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 4)
	ld (xwa), xbc
	pop xiz
	lda xsp, (xsp + 24)
	ret

DSP_ParamEQ_Curve_FP:
	lda xsp, (xsp - 100)
	push xiz
	ld (xsp + 96), xbc
	ld (xsp + 100), xwa
	ld xwa, (xsp + 100)
	ld xiz, (xwa)
	lda xwa, (xsp + 88)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xbc, (xsp + 88)
	lda xwa, (xsp + 12)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 12)
	lda_24 xde, 0x012e07
	lda xwa, (xsp + 12)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 12)
	lda_24 xde, 0x012e0b
	lda xwa, (xsp + 80)
	call VoiceFloat_SubSP
	ld xwa, (xsp + 96)
	cp xwa, 0xF
	jrl gt, DSP_ParamEQ_Range2
	lda xbc, (xsp + 96)
	lda xwa, (xsp + 12)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 40)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 40)
	lda_24 xde, 0x012e0f
	lda xwa, (xsp + 40)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 40)
	lda_24 xde, 0x012e17
	lda xwa, (xsp + 40)
	call FP_DP_Mul
	lda_24 xbc, 0x012e1f
	lda xde, (xsp + 40)
	lda xwa, (xsp + 40)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 40)
	lda xwa, (xsp + 76)
	call FP_DP_NormalizeMantissa
	lda xbc, (xsp + 76)
	lda xwa, (xsp + 40)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 80)
	lda xwa, (xsp + 64)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 64)
	lda xde, (xsp + 40)
	lda xwa, (xsp + 64)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012e27
	lda xwa, (xsp + 64)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 64)
	lda xwa, (xsp + 72)
	call FP_DP_NormalizeMantissa
	lda xbc, (xsp + 72)
	lda xwa, (xsp + 64)
	call FP_DP_NegMantissaLS
	lda xwa, (xsp + 64)
	lda_24 xbc, 0x012e2f
	lds de, 1
	call ToneGen_Compare_Voice
	cps hl, 0
	jr nz, DSP_ParamEQ_Range1_NonzeroCoeff
	lda xbc, (xsp + 72)
	lda xwa, (xsp + 64)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 64)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012e37
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 72)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 56)
	lda xwa, (xsp + 64)
	call FP_DP_CopyOrNegate8
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012e3f
	lda xwa, (xsp + 64)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 64)
	lda xwa, (xsp + 92)
	call FP_DP_NormalizeMantissa
	jrl DSP_ParamEQ_Finalize

DSP_ParamEQ_Range1_NonzeroCoeff:
	lda xbc, (xsp + 72)
	lda_24 xde, 0x012e47
	lda xwa, (xsp + 12)
	call FP_SP_Mul
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 64)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 64)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012e4b
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 64)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 48)
	lda xwa, (xsp + 64)
	call FP_DP_CopyOrNegate8
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012e53
	lda xwa, (xsp + 64)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012e5b
	lda xwa, (xsp + 64)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 64)
	lda xwa, (xsp + 92)
	call FP_DP_NormalizeMantissa
	jrl DSP_ParamEQ_Finalize

DSP_ParamEQ_Range2:
	ld xwa, (xsp + 96)
	cp xwa, 0x17
	jrl gt, DSP_ParamEQ_Range3
	lda xbc, (xsp + 96)
	lda xwa, (xsp + 12)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 12)
	lda_24 xde, 0x012e63
	lda xwa, (xsp + 12)
	call FP_SP_Sub
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 64)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012e67
	lda xwa, (xsp + 64)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012e6f
	lda xwa, (xsp + 64)
	call FP_DP_Mul
	lda xbc, (xsp + 80)
	lda xwa, (xsp + 40)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 40)
	lda_24 xde, 0x012e77
	lda xwa, (xsp + 40)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 40)
	lda xde, (xsp + 64)
	lda xwa, (xsp + 64)
	call VoiceFloat_SubDP
	lda xiy, (xsp + 64)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012e7f
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 48)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 32)
	lda xwa, (xsp + 64)
	call FP_DP_CopyOrNegate8
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012e87
	lda xwa, (xsp + 64)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 64)
	lda xwa, (xsp + 92)
	call FP_DP_NormalizeMantissa
	jrl DSP_ParamEQ_Finalize

DSP_ParamEQ_Range3:
	ld xwa, (xsp + 96)
	cp xwa, 0x37
	jrl gt, DSP_ParamEQ_Range4
	lda xbc, (xsp + 96)
	lda xwa, (xsp + 12)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 12)
	lda_24 xde, 0x012e8f
	lda xwa, (xsp + 12)
	call FP_SP_Sub
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 64)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012e93
	lda xwa, (xsp + 64)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012e9b
	lda xwa, (xsp + 64)
	call FP_DP_Mul
	lda xbc, (xsp + 80)
	lda xwa, (xsp + 40)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 40)
	lda_24 xde, 0x012ea3
	lda xwa, (xsp + 40)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 40)
	lda xde, (xsp + 64)
	lda xwa, (xsp + 64)
	call VoiceFloat_SubDP
	lda xiy, (xsp + 64)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012eab
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 40)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 24)
	lda xwa, (xsp + 64)
	call FP_DP_CopyOrNegate8
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012eb3
	lda xwa, (xsp + 64)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 64)
	lda xwa, (xsp + 92)
	call FP_DP_NormalizeMantissa
	jrl DSP_ParamEQ_Finalize

DSP_ParamEQ_Range4:
	ld xwa, (xsp + 96)
	cp xwa, 0x4B
	jrl gt, DSP_ParamEQ_Range5
	lda xbc, (xsp + 96)
	lda xwa, (xsp + 12)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 12)
	lda_24 xde, 0x012ebb
	lda xwa, (xsp + 12)
	call FP_SP_Sub
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 64)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012ebf
	lda xwa, (xsp + 64)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012ec7
	lda xwa, (xsp + 64)
	call FP_DP_Mul
	lda xbc, (xsp + 80)
	lda xwa, (xsp + 40)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 40)
	lda_24 xde, 0x012ecf
	lda xwa, (xsp + 40)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 40)
	lda xde, (xsp + 64)
	lda xwa, (xsp + 64)
	call VoiceFloat_SubDP
	lda xiy, (xsp + 64)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012ed7
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 32)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 16)
	lda xwa, (xsp + 64)
	call FP_DP_CopyOrNegate8
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012edf
	lda xwa, (xsp + 64)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 64)
	lda xwa, (xsp + 92)
	call FP_DP_NormalizeMantissa
	jrl DSP_ParamEQ_Finalize

DSP_ParamEQ_Range5:
	lda xbc, (xsp + 96)
	lda xwa, (xsp + 12)
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 12)
	lda_24 xde, 0x012ee7
	lda xwa, (xsp + 12)
	call FP_SP_Sub
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 64)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 80)
	lda xwa, (xsp + 40)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 40)
	lda_24 xde, 0x012eeb
	lda xwa, (xsp + 40)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 40)
	lda xde, (xsp + 64)
	lda xwa, (xsp + 64)
	call VoiceFloat_SubDP
	lda xiy, (xsp + 64)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012ef3
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 20)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 4)
	lda xwa, (xsp + 64)
	call FP_DP_CopyOrNegate8
	lda xbc, (xsp + 64)
	lda_24 xde, 0x012efb
	lda xwa, (xsp + 64)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 64)
	lda xwa, (xsp + 92)
	call FP_DP_NormalizeMantissa

DSP_ParamEQ_Finalize:
	ld xwa, (xsp + 100)
	ld (xwa), xiz
	lda xbc, (xsp + 92)
	lda_24 xde, 0x012f03
	lda xwa, (xsp + 12)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 84)
	call FP_SP_Decode_ReadSign
	ld xhl, (xsp + 84)
	pop xiz
	lda xsp, (xsp + 100)
	ret

DSP_ParamInterp_2Point_B:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld xwa, (xsp + 16)
	ld xiz, (xwa)
	lda xwa, (xsp + 8)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	ld xwa, (xsp + 4)
	sub xwa, (xsp + 8)
	sra xwa, 8
	ld xbc, (xsp + 12)
	call FP_MulAccum64
	ld xwa, xhl
	ld xbc, 0x63
	call Int_SignedDiv_AltEntry
	ld xwa, xhl
	ld xhl, (xsp + 8)
	sra xhl, 8
	add xhl, xwa
	ld xwa, (xsp + 16)
	ld (xwa), xiz
	pop xiz
	lda xsp, (xsp + 16)
	ret

DSP_VolScale_B:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ld xwa, (xsp + 4)
	ld xiz, (xwa)
	ldb_spi A, 0xF8
	cps a, 2
	jrl z, DSP_VolScale_B_Algo2_Seg1
	cps a, 1
	jrl z, DSP_VolScale_B_Algo1_Seg1
	cps a, 0
	jrl nz, DSP_VolScale_B_Return
	cp xbc, 0x32
	jr gt, DSP_VolScale_B_Algo0_Seg2
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, 0x6BAA8
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_B_Return

DSP_VolScale_B_Algo0_Seg2:
	cp xbc, 0x4B
	jr gt, DSP_VolScale_B_Algo0_Seg3
	sub xbc, 0x19
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, 0x35D54
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_B_Return

DSP_VolScale_B_Algo0_Seg3:
	cp xbc, 0x58
	jr gt, DSP_VolScale_B_Algo0_Seg4
	sla xbc, 2
	sub xbc, 0xFA
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, 0x35D54
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_B_Return

DSP_VolScale_B_Algo0_Seg4:
	ld xwa, xbc
	sla xwa, 3
	add xwa, xbc
	sub xwa, 0x2B2
	sla xwa, 7
	sla xwa, 0
	ld xbc, 0x35D54
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_B_Return

DSP_VolScale_B_Algo1_Seg1:
	cp xbc, 0xA
	jr gt, DSP_VolScale_B_Algo1_Seg2
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, 0xAC44
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_B_Return

DSP_VolScale_B_Algo1_Seg2:
	cp xbc, 0x13
	jr gt, DSP_VolScale_B_Algo1_Seg3
	ld xwa, xbc
	sla xwa, 2
	add xwa, xbc
	add xwa, xwa
	sub xwa, 0x5A
	sla xwa, 7
	sla xwa, 0
	ld xbc, 0xAC44
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_B_Return

DSP_VolScale_B_Algo1_Seg3:
	cp xbc, 0x40
	jr gt, DSP_VolScale_B_Algo1_Seg4
	ld xwa, xbc
	sla xwa, 2
	add xwa, xbc
	sla xwa, 2
	sub xwa, 0x118
	sla xwa, 15
	ld xbc, 0xAC44
	call Int_SignedDiv_AltEntry
	sla xhl, 8
	jrl DSP_VolScale_B_Return

DSP_VolScale_B_Algo1_Seg4:
	cp xbc, 0x57
	jr gt, DSP_VolScale_B_Algo1_Seg5
	ld xwa, xbc
	ld xbc, 0x190
	call FP_MulAccum64
	sub xhl, 0x60E0
	sla xhl, 15
	ld xwa, xhl
	ld xbc, 0xAC44
	call Int_SignedDiv_AltEntry
	sla xhl, 8
	jrl DSP_VolScale_B_Return

DSP_VolScale_B_Algo1_Seg5:
	ld xwa, xbc
	ld xbc, 0x320
	call FP_MulAccum64
	sub xhl, 0xE8D0
	sla xhl, 15
	ld xwa, xhl
	ld xbc, 0xAC44
	call Int_SignedDiv_AltEntry
	sla xhl, 8
	jrl DSP_VolScale_B_Return

DSP_VolScale_B_Algo2_Seg1:
	cp xbc, 0x32
	jr gt, DSP_VolScale_B_Algo2_Seg2
	ld xwa, xbc
	add xwa, xwa
	ld xde, 0xFA0
	sub xde, xwa
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, xde
	call Int_SignedDiv_AltEntry
	jrl DSP_VolScale_B_Return

DSP_VolScale_B_Algo2_Seg2:
	cp xbc, 0x4B
	jr gt, DSP_VolScale_B_Algo2_Seg3
	ld xwa, xbc
	add xwa, xwa
	sub xwa, 0x66
	ld xde, 0x79C
	sub xde, xwa
	sub xbc, 0x19
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, xde
	call Int_SignedDiv_AltEntry
	jr DSP_VolScale_B_Return

DSP_VolScale_B_Algo2_Seg3:
	cp xbc, 0x58
	jr gt, DSP_VolScale_B_Algo2_Seg4
	ld xwa, xbc
	sla xwa, 3
	sub xwa, 0x260
	ld xde, 0x764
	sub xde, xwa
	sla xbc, 2
	sub xbc, 0xFA
	sla xbc, 7
	sla xbc, 0
	ld xwa, xbc
	ld xbc, xde
	call Int_SignedDiv_AltEntry
	jr DSP_VolScale_B_Return

DSP_VolScale_B_Algo2_Seg4:
	ld xwa, xbc
	sla xwa, 3
	add xwa, xbc
	add xwa, xwa
	sub xwa, 0x642
	ld xde, 0x6F2
	sub xde, xwa
	ld xwa, xbc
	sla xwa, 3
	add xwa, xbc
	sub xwa, 0x2B2
	sla xwa, 7
	sla xwa, 0
	ld xbc, xde
	call Int_SignedDiv_AltEntry

DSP_VolScale_B_Return:
	ld xwa, (xsp + 4)
	ld (xwa), xiz
	pop xiz
	inc 4, xsp
	ret

DSP_PanScale_Simple:
	ld xwa, xbc
	ld xbc, 0xAC44
	call FP_MulAccum64
	ld xwa, xhl
	ld xbc, 0x3E8
	call Int_SignedDiv_AltEntry
	ret

DSP_ParamInterp_MultiStep:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 16), xbc
	ld (xsp + 20), xwa
	ld xwa, (xsp + 20)
	ld xiz, (xwa)
	ldb_spi A, 0xF8
	and a, 0xF0
	cp a, 0x20
	jr z, DSP_ParamInterp_MultiStep_Mode0x20
	cp a, 0x10
	jr z, DSP_ParamInterp_MultiStep_Mode0x10
	ld xwa, (xsp + 16)
	jr DSP_ParamInterp_MultiStep_Dispatch

DSP_ParamInterp_MultiStep_Mode0x10:
	ld wa, (xsp + 28)
	dec 1, wa
	extz xwa
	add xwa, xwa
	add xwa, xde
	ld wa, (xwa)
	jr DSP_ParamInterp_MultiStep_Dispatch

DSP_ParamInterp_MultiStep_Mode0x20:
	ld wa, (xsp + 28)
	dec 2, wa
	extz xwa
	add xwa, xwa
	add xwa, xde
	ld wa, (xwa)

DSP_ParamInterp_MultiStep_Dispatch:
	cps wa, 2
	jrl z, DSP_ParamInterp_MultiStep_Order2
	cps wa, 1
	jr z, DSP_ParamInterp_MultiStep_Order1
	lda xwa, (xsp + 8)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	jrl DSP_ParamInterp_MultiStep_Compute

DSP_ParamInterp_MultiStep_Order1:
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 8)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	jr DSP_ParamInterp_MultiStep_Compute

DSP_ParamInterp_MultiStep_Order2:
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 8)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl
	lda xwa, (xsp + 4)
	ld xbc, xwa
	ld xwa, xiz
	call DSP_StreamDecode_3ByteWord
	ld xiz, xhl

DSP_ParamInterp_MultiStep_Compute:
	ld xwa, (xsp + 4)
	sub xwa, (xsp + 8)
	sra xwa, 8
	ld xbc, (xsp + 16)
	call FP_MulAccum64
	ld xwa, xhl
	ld xbc, 0x63
	call Int_SignedDiv_AltEntry
	ld xwa, (xsp + 8)
	sra xwa, 8
	add xwa, xhl
	ld xbc, (xsp + 20)
	ld (xbc), xiz
	ld xhl, xwa
	pop xiz
	lda xsp, (xsp + 20)
	retd 0x4

DSP_FilterLUT_Fetch:
	lda xsp, (xsp - 50)
	pushw iz
	ld (xsp + 44), xde
	ld (xsp + 48), xbc
	ld iz, wa
	ld xwa, (xsp + 56)
	ld a, (xwa)
	and a, 0xF
	extz wa
	ld (xsp + 2), wa
	ld xwa, (xsp + 56)
	ldb_spi C, 0xE0
	ld (xsp + 56), xwa
	and c, 0xF0
	extz bc
	ld wa, (xsp + 2)
	cps wa, 2
	jrl z, DSP_FilterLUT_ModeType2
	cps wa, 1
	jrl z, DSP_FilterLUT_ModeType1
	cps wa, 0
	jrl nz, DSP_FilterLUT_StoreResults
	ld wa, bc
	cp wa, 0x20
	jrl z, DSP_FilterLUT_Mode0x20
	cp wa, 0x10
	jrl z, DSP_FilterLUT_Mode0x10
	cps wa, 0
	jrl nz, DSP_FilterLUT_Mode0x20
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0x012397
	stb_dri A, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 40)
	call FP_SP_Raw4Copy
	ld wa, iz
	inc 1, wa
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0x012403
	stb_dri A, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 36)
	call FP_SP_Raw4Copy
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	exts xwa
	ld (xsp + 4), xwa
	lda xbc, (xsp + 4)
	lda xwa, (xsp + 24)
	call FP_ScalarToDP
	lda xbc, (xsp + 24)
	lda_24 xde, 0x012f07
	lda xwa, (xsp + 24)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 24)
	lda_24 xde, 0x012f0f
	lda xwa, (xsp + 24)
	call FP_DP_Mul
	lda xbc, (xsp + 24)
	lda xwa, (xsp + 32)
	call FP_DP_NormalizeMantissa
	jrl DSP_FilterLUT_StoreResults

DSP_FilterLUT_Mode0x10:
	ld wa, iz
	dec 1, wa
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0x012397
	stb_dri A, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 40)
	call FP_SP_Raw4Copy
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0x012403
	stb_dri A, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 36)
	call FP_SP_Raw4Copy
	ld wa, iz
	inc 1, wa
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	exts xwa
	ld (xsp + 8), xwa
	lda xbc, (xsp + 8)
	lda xwa, (xsp + 24)
	call FP_ScalarToDP
	lda xbc, (xsp + 24)
	lda_24 xde, 0x012f17
	lda xwa, (xsp + 24)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 24)
	lda_24 xde, 0x012f1f
	lda xwa, (xsp + 24)
	call FP_DP_Mul
	lda xbc, (xsp + 24)
	lda xwa, (xsp + 32)
	call FP_DP_NormalizeMantissa
	jrl DSP_FilterLUT_StoreResults

DSP_FilterLUT_Mode0x20:
	ld wa, iz
	dec 2, wa
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0x012397
	stb_dri A, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 40)
	call FP_SP_Raw4Copy
	ld wa, iz
	dec 1, wa
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0x012403
	stb_dri A, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 36)
	call FP_SP_Raw4Copy
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	exts xwa
	ld (xsp + 12), xwa
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 24)
	call FP_ScalarToDP
	lda xbc, (xsp + 24)
	lda_24 xde, 0x012f27
	lda xwa, (xsp + 24)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 24)
	lda_24 xde, 0x012f2f
	lda xwa, (xsp + 24)
	call FP_DP_Mul
	lda xbc, (xsp + 24)
	lda xwa, (xsp + 32)
	call FP_DP_NormalizeMantissa
	jrl DSP_FilterLUT_StoreResults

DSP_FilterLUT_ModeType1:
	ld xwa, 0x3DCCCCCD
	ld (xsp + 36), xwa
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0x012397
	stb_dri A, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 40)
	call FP_SP_Raw4Copy
	jrl DSP_FilterLUT_StoreResults

DSP_FilterLUT_ModeType2:
	ld xwa, 0x40000000
	ld (xsp + 36), xwa
	ld wa, bc
	cp wa, 0x20
	jr z, DSP_FilterLUT_ModeType2_SubMode
	cps wa, 0
	jr nz, DSP_FilterLUT_ModeType2_SubMode
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0x012397
	stb_dri A, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 40)
	call FP_SP_Raw4Copy
	ld wa, iz
	inc 1, wa
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	exts xwa
	ld (xsp + 16), xwa
	lda xbc, (xsp + 16)
	lda xwa, (xsp + 24)
	call FP_ScalarToDP
	lda xbc, (xsp + 24)
	lda_24 xde, 0x012f37
	lda xwa, (xsp + 24)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 24)
	lda_24 xde, 0x012f3f
	lda xwa, (xsp + 24)
	call FP_DP_Mul
	lda xbc, (xsp + 24)
	lda xwa, (xsp + 32)
	call FP_DP_NormalizeMantissa
	jr DSP_FilterLUT_StoreResults

DSP_FilterLUT_ModeType2_SubMode:
	ld wa, iz
	dec 1, wa
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0x012397
	stb_dri A, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 40)
	call FP_SP_Raw4Copy
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 60)
	ld wa, (xwa)
	exts xwa
	ld (xsp + 20), xwa
	lda xbc, (xsp + 20)
	lda xwa, (xsp + 24)
	call FP_ScalarToDP
	lda xbc, (xsp + 24)
	lda_24 xde, 0x012f47
	lda xwa, (xsp + 24)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 24)
	lda_24 xde, 0x012f4f
	lda xwa, (xsp + 24)
	call FP_DP_Mul
	lda xbc, (xsp + 24)
	lda xwa, (xsp + 32)
	call FP_DP_NormalizeMantissa

DSP_FilterLUT_StoreResults:
	ld xbc, (xsp + 64)
	ld wa, (xsp + 2)
	ld (xbc), wa
	ld xbc, (xsp + 48)
	ld xwa, (xsp + 40)
	ld (xbc), xwa
	ld xbc, (xsp + 44)
	ld xwa, (xsp + 36)
	ld (xbc), xwa
	ld xbc, (xsp + 68)
	ld xwa, (xsp + 32)
	ld (xbc), xwa
	ld xhl, (xsp + 56)
	popw iz
	lda xsp, (xsp + 50)
	retd 0x10

DSP_BiquadCoeff_Compute:
	stb_dri L, 0xFD, 0x14, 0xFF
	pushw iz
	stw_dri WA, 0xFD, 0xEC, 0x00
	stb_dri W, 0xFD, 0xDE, 0x00
	push xwa
	stb_dri W, 0xFD, 0xEE, 0x00
	push xwa
	ld_sril XWA, (xsp + 0x0100)
	push xwa
	ld_sril XWA, (xsp + 0x010a)
	push xwa
	ld wa, de
	stb_dri A, 0xFD, 0xF6, 0x00
	stb_dri B, 0xFD, 0xF2, 0x00
	calr DSP_FilterLUT_Fetch
	stl_dri XHL, 0xFD, 0xFE, 0x00
	ldw_sri0 WA, (xsp + 0x00ea)
	cps wa, 2
	jrl z, DSP_BiquadCoeff_Algo2
	cps wa, 1
	jrl z, DSP_BiquadCoeff_Algo1
	cps wa, 0
	jrl nz, DSP_BiquadCoeff_Epilogue
	stb_dri A, 0xFD, 0xE6, 0x00
	lda xwa, (xsp + 78)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 78)
	lda_24 xde, 0x012f57
	lda xwa, (xsp + 78)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 78)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	stb_dri W, 0xFD, 0x9E, 0x00
	push xwa
	call VoiceFloat_MulAddDispatch
	lda xsp, (xsp + 12)
	stb_dri A, 0xFD, 0x96, 0x00
	stb_dri W, 0xFD, 0xDA, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri A, 0xFD, 0xDA, 0x00
	stb_dri B, 0xFD, 0xE2, 0x00
	stb_dri W, 0xFD, 0xAA, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xDA, 0x00
	stb_dri B, 0xFD, 0xDA, 0x00
	stb_dri W, 0xFD, 0xA6, 0x00
	call FP_SP_Add_Outer
	stb_dri A, 0xFD, 0xAA, 0x00
	stb_dri B, 0xFD, 0xA6, 0x00
	lda xwa, (xsp + 86)
	call FP_SP_Mul
	lda xbc, (xsp + 86)
	lda_24 xde, 0x012f5f
	stb_dri W, 0xFD, 0xD6, 0x00
	call FP_SP_Mul
	lda_24 xbc, 0x012f63
	stb_dri B, 0xFD, 0xA6, 0x00
	lda xwa, (xsp + 86)
	call FP_SP_Sub
	lda xbc, (xsp + 86)
	lda_24 xde, 0x012f67
	stb_dri W, 0xFD, 0xD2, 0x00
	call FP_SP_Add_Outer
	stb_dri A, 0xFD, 0xA6, 0x00
	stb_dri B, 0xFD, 0xAA, 0x00
	lda xwa, (xsp + 86)
	call FP_SP_Sub
	lda xbc, (xsp + 86)
	lda_24 xde, 0x012f6b
	stb_dri W, 0xFD, 0xCE, 0x00
	call FP_SP_Mul
	stb_dri W, 0xFD, 0xDE, 0x00
	lds bc, 1
	call FP_SP_CmpZero32
	cps hl, 0
	jr nz, DSP_BiquadCoeff_Algo0_SignZero
	ld_sril XWA, (xsp + 0x00de)
	stl_dri XWA, 0xFD, 0x8A, 0x00
	jr DSP_BiquadCoeff_Algo0_AfterSign

DSP_BiquadCoeff_Algo0_SignZero:
	stb_dri A, 0xFD, 0xDE, 0x00
	stb_dri W, 0xFD, 0x8A, 0x00
	call FP_SP_CopyOrNegate4

DSP_BiquadCoeff_Algo0_AfterSign:
	stb_dri A, 0xFD, 0x8A, 0x00
	lda_24 xde, 0x012f6f
	lda xwa, (xsp + 86)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 86)
	lda xwa, (xsp + 78)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 78)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012f73
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	stb_dri W, 0xFD, 0x9E, 0x00
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	stb_dri A, 0xFD, 0xAA, 0x00
	lda xwa, (xsp + 78)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 78)
	stb_dri B, 0xFD, 0x8E, 0x00
	lda xwa, (xsp + 78)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 78)
	lda_24 xde, 0x012f7b
	lda xwa, (xsp + 78)
	call FP_DP_Mul
	stb_dri A, 0xFD, 0xA6, 0x00
	lda xwa, (xsp + 118)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 118)
	lda xde, (xsp + 78)
	lda xwa, (xsp + 118)
	call FP_DP_Mul
	lda xbc, (xsp + 118)
	stb_dri W, 0xFD, 0xCA, 0x00
	call FP_DP_NormalizeMantissa
	ld_sril XWA, (xsp + 0x00d2)
	stl_dri XWA, 0xFD, 0xC6, 0x00
	stb_dri W, 0xFD, 0xDE, 0x00
	lds bc, 1
	call FP_SP_CmpZero32
	cps hl, 0
	jr nz, DSP_BiquadCoeff_Algo0_Sign2Zero
	ld_sril XWA, (xsp + 0x00de)
	ld (xsp + 126), xwa
	jr DSP_BiquadCoeff_Algo0_AfterSign2

DSP_BiquadCoeff_Algo0_Sign2Zero:
	stb_dri A, 0xFD, 0xDE, 0x00
	lda xwa, (xsp + 126)
	call FP_SP_CopyOrNegate4

DSP_BiquadCoeff_Algo0_AfterSign2:
	lda xbc, (xsp + 126)
	lda_24 xde, 0x012f83
	lda xwa, (xsp + 86)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 86)
	lda xwa, (xsp + 118)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 118)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x012f87
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	stb_dri W, 0xFD, 0x92, 0x00
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	stb_dri A, 0xFD, 0xAA, 0x00
	lda xwa, (xsp + 118)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 118)
	stb_dri B, 0xFD, 0x82, 0x00
	lda xwa, (xsp + 118)
	call FP_DP_Add_Outer
	lda_24 xbc, 0x012f8f
	lda xde, (xsp + 118)
	lda xwa, (xsp + 118)
	call FP_DP_Sub
	stb_dri A, 0xFD, 0xA6, 0x00
	lda xwa, (xsp + 78)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 78)
	lda xde, (xsp + 118)
	lda xwa, (xsp + 118)
	call FP_DP_Mul
	lda xbc, (xsp + 118)
	stb_dri W, 0xFD, 0xC2, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri W, 0xFD, 0xDE, 0x00
	lds bc, 1
	call FP_SP_CmpZero32
	cps hl, 0
	jr nz, DSP_BiquadCoeff_Algo0_NegBranch
	stb_dri A, 0xFD, 0xCA, 0x00
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xBE, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xC6, 0x00
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xBA, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xC2, 0x00
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xB6, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xD2, 0x00
	lda xwa, (xsp + 86)
	call FP_SP_CopyOrNegate4
	lda xbc, (xsp + 86)
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xB2, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xCE, 0x00
	lda xwa, (xsp + 86)
	call FP_SP_CopyOrNegate4
	lda xbc, (xsp + 86)
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xAE, 0x00
	call VoiceFloat_SubSP
	jr DSP_BiquadCoeff_Algo0_Assembly

DSP_BiquadCoeff_Algo0_NegBranch:
	stb_dri A, 0xFD, 0xD6, 0x00
	stb_dri B, 0xFD, 0xCA, 0x00
	stb_dri W, 0xFD, 0xBE, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xD2, 0x00
	stb_dri B, 0xFD, 0xCA, 0x00
	stb_dri W, 0xFD, 0xBA, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xCE, 0x00
	stb_dri B, 0xFD, 0xCA, 0x00
	stb_dri W, 0xFD, 0xB6, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xC6, 0x00
	lda xwa, (xsp + 86)
	call FP_SP_CopyOrNegate4
	lda xbc, (xsp + 86)
	stb_dri B, 0xFD, 0xCA, 0x00
	stb_dri W, 0xFD, 0xB2, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xC2, 0x00
	lda xwa, (xsp + 86)
	call FP_SP_CopyOrNegate4
	lda xbc, (xsp + 86)
	stb_dri B, 0xFD, 0xCA, 0x00
	stb_dri W, 0xFD, 0xAE, 0x00
	call VoiceFloat_SubSP

DSP_BiquadCoeff_Algo0_Assembly:
	stb_dri A, 0xFD, 0xBE, 0x00
	stb_dri B, 0xFD, 0xBA, 0x00
	lda xwa, (xsp + 86)
	call FP_SP_Mul
	lda xbc, (xsp + 86)
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 86)
	call FP_SP_Mul
	lda_24 xbc, 0x012f97
	stb_dri B, 0xFD, 0xB2, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_Sub
	lda xbc, (xsp + 2)
	stb_dri B, 0xFD, 0xAE, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_Sub
	lda xbc, (xsp + 2)
	lda xde, (xsp + 86)
	stb_dri W, 0xFD, 0x9E, 0x00
	call VoiceFloat_SubSP
	stb_dri W, 0xFD, 0x9E, 0x00
	lda_24 xbc, 0x012f9b
	lds de, 0
	call ToneGen_Compare_Voice_32
	cps hl, 0
	jr nz, DSP_BiquadCoeff_Algo0_Fixup
	ld xwa, 0x3F800000
	stl_dri XWA, 0xFD, 0x9E, 0x00

DSP_BiquadCoeff_Algo0_Fixup:
	stb_dri A, 0xFD, 0x9E, 0x00
	stb_dri B, 0xFD, 0xBE, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda_24 xde, 0x012f9f
	stb_dri W, 0xFD, 0xBE, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0x9E, 0x00
	stb_dri B, 0xFD, 0xBA, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda_24 xde, 0x012fa3
	stb_dri W, 0xFD, 0xBA, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0x9E, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda_24 xde, 0x012fa7
	stb_dri W, 0xFD, 0xB6, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xBA, 0x00
	lda_24 xde, 0x012fab
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 114)
	call FP_SP_Decode_ReadSign
	push_sriw 0xFD, 0xF6, 0x00
	ldw_sri0 WA, (xsp + 0x00fe)
	ld xbc, (xsp + 116)
	ldw_sri0 DE, (xsp + 0x00ee)
	call DSP_WriteOscParam
	ld iz, hl
	stb_dri A, 0xFD, 0xBE, 0x00
	lda_24 xde, 0x012faf
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 110)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 110)
	ldw_sri0 BC, (xsp + 0x00ec)
	ldw_sri0 DE, (xsp + 0x00f6)
	call DSP_WriteCoeffData_5B_Direct
	ld iz, hl
	stb_dri A, 0xFD, 0xB6, 0x00
	lda_24 xde, 0x012fb3
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 106)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 106)
	ldw_sri0 BC, (xsp + 0x00ec)
	ldw_sri0 DE, (xsp + 0x00f6)
	call DSP_WriteCoeffData_5B_Direct
	ld iz, hl
	stb_dri A, 0xFD, 0xB2, 0x00
	lda_24 xde, 0x012fb7
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 102)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 102)
	ldw_sri0 BC, (xsp + 0x00ec)
	ldw_sri0 DE, (xsp + 0x00f6)
	call DSP_WriteCoeffData_5B_Direct
	ld iz, hl
	stb_dri A, 0xFD, 0xAE, 0x00
	lda_24 xde, 0x012fbb
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 98)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 98)
	ldw_sri0 BC, (xsp + 0x00ec)
	ldw_sri0 DE, (xsp + 0x00f6)
	call DSP_WriteCoeffData_5B_Direct
	ld iz, hl
	jrl DSP_BiquadCoeff_Epilogue

DSP_BiquadCoeff_Algo1:
	stb_dri A, 0xFD, 0xE6, 0x00
	lda xwa, (xsp + 118)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 118)
	lda_24 xde, 0x012fbf
	lda xwa, (xsp + 118)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 118)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 98)
	push xwa
	call VoiceFloat_MulAddDispatch
	lda xsp, (xsp + 12)
	lda xbc, (xsp + 90)
	stb_dri W, 0xFD, 0xDA, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri A, 0xFD, 0xDA, 0x00
	stb_dri B, 0xFD, 0xE2, 0x00
	stb_dri W, 0xFD, 0xAA, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xDA, 0x00
	stb_dri B, 0xFD, 0xDA, 0x00
	stb_dri W, 0xFD, 0xA6, 0x00
	call FP_SP_Add_Outer
	stb_dri A, 0xFD, 0xAA, 0x00
	stb_dri B, 0xFD, 0xA6, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_Mul
	lda xbc, (xsp + 2)
	lda_24 xde, 0x012fc7
	stb_dri W, 0xFD, 0xD6, 0x00
	call FP_SP_Mul
	lda_24 xbc, 0x012fcb
	stb_dri B, 0xFD, 0xA6, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_Sub
	lda xbc, (xsp + 2)
	lda_24 xde, 0x012fcf
	stb_dri W, 0xFD, 0xD2, 0x00
	call FP_SP_Add_Outer
	stb_dri A, 0xFD, 0xA6, 0x00
	stb_dri B, 0xFD, 0xAA, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_Sub
	lda xbc, (xsp + 2)
	lda_24 xde, 0x012fd3
	stb_dri W, 0xFD, 0xCE, 0x00
	call FP_SP_Mul
	stb_dri A, 0xFD, 0xAA, 0x00
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xBE, 0x00
	call VoiceFloat_SubSP
	lds32 xwa, 0
	stl_dri XWA, 0xFD, 0xBA, 0x00
	stb_dri A, 0xFD, 0xBE, 0x00
	stb_dri W, 0xFD, 0xB6, 0x00
	call FP_SP_CopyOrNegate4
	stb_dri A, 0xFD, 0xD2, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_CopyOrNegate4
	lda xbc, (xsp + 2)
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xB2, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xCE, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_CopyOrNegate4
	lda xbc, (xsp + 2)
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xAE, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xBA, 0x00
	lda_24 xde, 0x012fd7
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 74)
	call FP_SP_Decode_ReadSign
	push_sriw 0xFD, 0xF6, 0x00
	ldw_sri0 WA, (xsp + 0x00fe)
	ld xbc, (xsp + 76)
	ldw_sri0 DE, (xsp + 0x00ee)
	call DSP_WriteOscParam
	ld iz, hl
	stb_dri A, 0xFD, 0xBE, 0x00
	lda_24 xde, 0x012fdb
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 70)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 70)
	ldw_sri0 BC, (xsp + 0x00ec)
	ldw_sri0 DE, (xsp + 0x00f6)
	call DSP_WriteCoeffData_5B_Direct
	ld iz, hl
	stb_dri A, 0xFD, 0xB6, 0x00
	lda_24 xde, 0x012fdf
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 66)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 66)
	ldw_sri0 BC, (xsp + 0x00ec)
	ldw_sri0 DE, (xsp + 0x00f6)
	call DSP_WriteCoeffData_5B_Direct
	ld iz, hl
	stb_dri A, 0xFD, 0xB2, 0x00
	lda_24 xde, 0x012fe3
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 62)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 62)
	ldw_sri0 BC, (xsp + 0x00ec)
	ldw_sri0 DE, (xsp + 0x00f6)
	call DSP_WriteCoeffData_5B_Direct
	ld iz, hl
	stb_dri A, 0xFD, 0xAE, 0x00
	lda_24 xde, 0x012fe7
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 58)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 58)
	ldw_sri0 BC, (xsp + 0x00ec)
	ldw_sri0 DE, (xsp + 0x00f6)
	call DSP_WriteCoeffData_5B_Direct
	ld iz, hl
	jrl DSP_BiquadCoeff_Epilogue

DSP_BiquadCoeff_Algo2:
	stb_dri A, 0xFD, 0xE6, 0x00
	lda xwa, (xsp + 118)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 118)
	lda_24 xde, 0x012feb
	lda xwa, (xsp + 118)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 118)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 58)
	push xwa
	call VoiceFloat_MulAddDispatch
	lda xsp, (xsp + 12)
	lda xbc, (xsp + 50)
	lda_24 xde, 0x012ff3
	lda xwa, (xsp + 118)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 118)
	stb_dri W, 0xFD, 0xDA, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri A, 0xFD, 0xDA, 0x00
	stb_dri B, 0xFD, 0xE2, 0x00
	lda xwa, (xsp + 2)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 118)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 118)
	lda_24 xde, 0x012ffb
	lda xwa, (xsp + 118)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 118)
	stb_dri W, 0xFD, 0xAA, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri A, 0xFD, 0xDA, 0x00
	lda xwa, (xsp + 118)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 118)
	lda_24 xde, 0x013003
	lda xwa, (xsp + 118)
	call FP_DP_Add_Outer
	stb_dri A, 0xFD, 0xDA, 0x00
	lda xwa, (xsp + 78)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 78)
	lda xde, (xsp + 118)
	lda xwa, (xsp + 118)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 118)
	lda_24 xde, 0x01300b
	lda xwa, (xsp + 118)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 118)
	stb_dri W, 0xFD, 0xA2, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri A, 0xFD, 0xAA, 0x00
	stb_dri B, 0xFD, 0xA2, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_Mul
	lda xbc, (xsp + 2)
	lda_24 xde, 0x013013
	stb_dri W, 0xFD, 0xD6, 0x00
	call FP_SP_Mul
	lda_24 xbc, 0x013017
	stb_dri B, 0xFD, 0xA2, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_Sub
	lda xbc, (xsp + 2)
	lda_24 xde, 0x01301b
	stb_dri W, 0xFD, 0xD2, 0x00
	call FP_SP_Add_Outer
	stb_dri A, 0xFD, 0xA2, 0x00
	stb_dri B, 0xFD, 0xAA, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_Sub
	lda xbc, (xsp + 2)
	lda_24 xde, 0x01301f
	stb_dri W, 0xFD, 0xCE, 0x00
	call FP_SP_Mul
	stb_dri W, 0xFD, 0xDE, 0x00
	lds bc, 1
	call FP_SP_CmpZero32
	cps hl, 0
	jr nz, DSP_BiquadCoeff_Algo2_Sign1Zero
	ld_sril XWA, (xsp + 0x00de)
	ld (xsp + 38), xwa
	jr DSP_BiquadCoeff_Algo2_AfterSign1

DSP_BiquadCoeff_Algo2_Sign1Zero:
	stb_dri A, 0xFD, 0xDE, 0x00
	lda xwa, (xsp + 38)
	call FP_SP_CopyOrNegate4

DSP_BiquadCoeff_Algo2_AfterSign1:
	lda xbc, (xsp + 38)
	lda_24 xde, 0x013023
	lda xwa, (xsp + 2)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 118)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 118)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x013027
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 58)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	stb_dri A, 0xFD, 0xAA, 0x00
	lda xwa, (xsp + 118)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 118)
	lda xde, (xsp + 42)
	lda xwa, (xsp + 118)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 118)
	lda_24 xde, 0x01302f
	lda xwa, (xsp + 118)
	call FP_DP_Mul
	stb_dri A, 0xFD, 0xA2, 0x00
	lda xwa, (xsp + 78)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 78)
	lda xde, (xsp + 118)
	lda xwa, (xsp + 118)
	call FP_DP_Mul
	lda xbc, (xsp + 118)
	stb_dri W, 0xFD, 0xCA, 0x00
	call FP_DP_NormalizeMantissa
	ld_sril XWA, (xsp + 0x00d2)
	stl_dri XWA, 0xFD, 0xC6, 0x00
	stb_dri W, 0xFD, 0xDE, 0x00
	lds bc, 1
	call FP_SP_CmpZero32
	cps hl, 0
	jr nz, DSP_BiquadCoeff_Algo2_Sign2Zero
	ld_sril XWA, (xsp + 0x00de)
	ld (xsp + 26), xwa
	jr DSP_BiquadCoeff_Algo2_AfterSign2

DSP_BiquadCoeff_Algo2_Sign2Zero:
	stb_dri A, 0xFD, 0xDE, 0x00
	lda xwa, (xsp + 26)
	call FP_SP_CopyOrNegate4

DSP_BiquadCoeff_Algo2_AfterSign2:
	lda xbc, (xsp + 26)
	lda_24 xde, 0x013037
	lda xwa, (xsp + 2)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 118)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 118)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x01303b
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 46)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	stb_dri A, 0xFD, 0xAA, 0x00
	lda xwa, (xsp + 118)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 118)
	lda xde, (xsp + 30)
	lda xwa, (xsp + 118)
	call FP_DP_Add_Outer
	lda_24 xbc, 0x013043
	lda xde, (xsp + 118)
	lda xwa, (xsp + 118)
	call FP_DP_Sub
	stb_dri A, 0xFD, 0xA2, 0x00
	lda xwa, (xsp + 78)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 78)
	lda xde, (xsp + 118)
	lda xwa, (xsp + 118)
	call FP_DP_Mul
	lda xbc, (xsp + 118)
	stb_dri W, 0xFD, 0xC2, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri W, 0xFD, 0xDE, 0x00
	lds bc, 1
	call FP_SP_CmpZero32
	cps hl, 0
	jr nz, DSP_BiquadCoeff_Algo2_NegBranch
	stb_dri A, 0xFD, 0xD2, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_CopyOrNegate4
	lda xbc, (xsp + 2)
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xB2, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xCE, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_CopyOrNegate4
	lda xbc, (xsp + 2)
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xAE, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xCA, 0x00
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xBE, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xC6, 0x00
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xBA, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xC2, 0x00
	stb_dri B, 0xFD, 0xD6, 0x00
	stb_dri W, 0xFD, 0xB6, 0x00
	call VoiceFloat_SubSP
	jr DSP_BiquadCoeff_Algo2_WriteParams

DSP_BiquadCoeff_Algo2_NegBranch:
	stb_dri A, 0xFD, 0xC6, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_CopyOrNegate4
	lda xbc, (xsp + 2)
	stb_dri B, 0xFD, 0xCA, 0x00
	stb_dri W, 0xFD, 0xB2, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xC2, 0x00
	lda xwa, (xsp + 2)
	call FP_SP_CopyOrNegate4
	lda xbc, (xsp + 2)
	stb_dri B, 0xFD, 0xCA, 0x00
	stb_dri W, 0xFD, 0xAE, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xD6, 0x00
	stb_dri B, 0xFD, 0xCA, 0x00
	stb_dri W, 0xFD, 0xBE, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xD2, 0x00
	stb_dri B, 0xFD, 0xCA, 0x00
	stb_dri W, 0xFD, 0xBA, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xCE, 0x00
	stb_dri B, 0xFD, 0xCA, 0x00
	stb_dri W, 0xFD, 0xB6, 0x00
	call VoiceFloat_SubSP

DSP_BiquadCoeff_Algo2_WriteParams:
	stb_dri A, 0xFD, 0xBA, 0x00
	lda_24 xde, 0x01304b
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 22)
	call FP_SP_Decode_ReadSign
	push_sriw 0xFD, 0xF6, 0x00
	ldw_sri0 WA, (xsp + 0x00fe)
	ld xbc, (xsp + 24)
	ldw_sri0 DE, (xsp + 0x00ee)
	call DSP_WriteOscParam
	ld iz, hl
	stb_dri A, 0xFD, 0xB6, 0x00
	lda_24 xde, 0x01304f
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 18)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 18)
	ldw_sri0 BC, (xsp + 0x00ec)
	call DSP_WriteParamWord
	ld iz, hl
	stb_dri A, 0xFD, 0xAE, 0x00
	lda_24 xde, 0x013053
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 14)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 14)
	ldw_sri0 BC, (xsp + 0x00ec)
	call DSP_WriteParamWord
	ld iz, hl
	stb_dri A, 0xFD, 0xBE, 0x00
	lda_24 xde, 0x013057
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 10)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 10)
	ldw_sri0 BC, (xsp + 0x00ec)
	call DSP_WriteParamWord
	ld iz, hl
	stb_dri A, 0xFD, 0xB2, 0x00
	lda_24 xde, 0x01305b
	lda xwa, (xsp + 2)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 2)
	lda xwa, (xsp + 6)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 6)
	ldw_sri0 BC, (xsp + 0x00ec)
	call DSP_WriteParamWord
	ld iz, hl

DSP_BiquadCoeff_Epilogue:
	ld_sril XWA, (xsp + 0x00f2)
	ld (xwa), iz
	ld_sril XHL, (xsp + 0x00fe)
	popw iz
	stb_dri L, 0xFD, 0xEC, 0x00
	retd 0x10

DSP_SOS_LUT_Fetch:
	lda xsp, (xsp - 34)
	pushw iz
	ld (xsp + 28), xde
	ld (xsp + 32), xbc
	ld iz, wa
	ld xwa, (xsp + 40)
	ld a, (xwa)
	and a, 0xF
	extz wa
	ld (xsp + 2), wa
	ld xwa, (xsp + 40)
	ldb_spi C, 0xE0
	ld (xsp + 40), xwa
	and c, 0xF0
	ld a, c
	cp a, 0x10
	jr z, DSP_SOS_LUT_Mode0x10
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 44)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0x012397
	stb_dri A, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 24)
	call FP_SP_Raw4Copy
	ld wa, iz
	inc 1, wa
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 44)
	ld wa, (xwa)
	exts xwa
	ld (xsp + 4), xwa
	lda xbc, (xsp + 4)
	lda xwa, (xsp + 12)
	call FP_ScalarToDP
	lda xbc, (xsp + 12)
	lda_24 xde, 0x01305f
	lda xwa, (xsp + 12)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 12)
	lda_24 xde, 0x013067
	lda xwa, (xsp + 12)
	call FP_DP_Mul
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 20)
	call FP_DP_NormalizeMantissa
	jr DSP_SOS_LUT_CheckType2

DSP_SOS_LUT_Mode0x10:
	ld wa, iz
	dec 1, wa
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 44)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0x012397
	stb_dri A, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 24)
	call FP_SP_Raw4Copy
	ld wa, iz
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 44)
	ld wa, (xwa)
	exts xwa
	ld (xsp + 8), xwa
	lda xbc, (xsp + 8)
	lda xwa, (xsp + 12)
	call FP_ScalarToDP
	lda xbc, (xsp + 12)
	lda_24 xde, 0x01306f
	lda xwa, (xsp + 12)
	call FP_DP_Add_Outer
	lda xbc, (xsp + 12)
	lda_24 xde, 0x013077
	lda xwa, (xsp + 12)
	call FP_DP_Mul
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 20)
	call FP_DP_NormalizeMantissa

DSP_SOS_LUT_CheckType2:
	ld wa, (xsp + 2)
	cps wa, 2
	jr nz, DSP_SOS_LUT_StoreResults
	ld xwa, (xsp + 40)
	ldb_spi C, 0xE0
	ld (xsp + 40), xwa
	and c, 0x1F
	ld a, c
	extz wa
	sla wa, 2
	lda_24 xbc, 0x012397
	stb_dri A, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 24)
	call FP_SP_Raw4Copy

DSP_SOS_LUT_StoreResults:
	ld xbc, (xsp + 48)
	ld wa, (xsp + 2)
	ld (xbc), wa
	ld xbc, (xsp + 32)
	ld xwa, (xsp + 24)
	ld (xbc), xwa
	ld xbc, (xsp + 28)
	ld xwa, (xsp + 20)
	ld (xbc), xwa
	ld xhl, (xsp + 40)
	popw iz
	lda xsp, (xsp + 34)
	retd 0xC

DSP_SOS_Coeff_Compute:
	stb_dri L, 0xFD, 0x2E, 0xFF
	push xiz
	ld iz, wa
	stb_dri W, 0xFD, 0xB0, 0x00
	push xwa
	ld_sril XWA, (xsp + 0x00e4)
	push xwa
	ld_sril XWA, (xsp + 0x00ee)
	push xwa
	ld wa, de
	stb_dri A, 0xFD, 0xDE, 0x00
	stb_dri B, 0xFD, 0xDA, 0x00
	calr DSP_SOS_LUT_Fetch
	stl_dri XHL, 0xFD, 0xE6, 0x00
	ldw_sri0 WA, (xsp + 0x00b0)
	cps wa, 2
	jrl z, DSP_SOS_Algo2
	cps wa, 1
	jrl z, DSP_SOS_Algo1
	cps wa, 0
	jrl nz, DSP_SOS_Coeff_Epilogue
	stb_dri A, 0xFD, 0xCE, 0x00
	lda_24 xde, 0x01307f
	lda xwa, (xsp + 56)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 56)
	lda xwa, (xsp + 72)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 72)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x013083
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	stb_dri W, 0xFD, 0xB8, 0x00
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	stb_dri A, 0xFD, 0xA8, 0x00
	stb_dri W, 0xFD, 0xB2, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri W, 0xFD, 0xCE, 0x00
	lds bc, 1
	call FP_SP_CmpZero32
	cps hl, 0
	jrl nz, DSP_SOS_Algo0_NonzeroCoeff
	stb_dri A, 0xFD, 0xD2, 0x00
	lda xwa, (xsp + 72)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 72)
	lda_24 xde, 0x01308b
	lda xwa, (xsp + 72)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 72)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	stb_dri W, 0xFD, 0xA8, 0x00
	push xwa
	call VoiceFloat_DispatchMulAdd
	stb_dri A, 0xFD, 0xDE, 0x00
	lda xwa, (xsp + 84)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 84)
	lda_24 xde, 0x013093
	lda xwa, (xsp + 84)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 84)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	stb_dri W, 0xFD, 0xAC, 0x00
	push xwa
	call VoiceFloat_MulAddVariant2
	lda xsp, (xsp + 24)
	stb_dri A, 0xFD, 0x98, 0x00
	lda_24 xde, 0x01309b
	lda xwa, (xsp + 72)
	call FP_DP_Sub
	lda xbc, (xsp + 72)
	stb_dri B, 0xFD, 0xA0, 0x00
	lda xwa, (xsp + 72)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 72)
	stb_dri W, 0xFD, 0xCA, 0x00
	call FP_DP_NormalizeMantissa
	lda_24 xbc, 0x0130a3
	stb_dri B, 0xFD, 0xCA, 0x00
	lda xwa, (xsp + 56)
	call FP_SP_Sub
	stb_dri A, 0xFD, 0xCA, 0x00
	lda_24 xde, 0x0130a7
	lda xwa, (xsp + 120)
	call FP_SP_Mul
	lda xbc, (xsp + 120)
	lda xde, (xsp + 56)
	stb_dri W, 0xFD, 0xB6, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xB2, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 120)
	call VoiceFloat_SubSP
	lda_24 xbc, 0x0130ab
	lda xde, (xsp + 120)
	lda xwa, (xsp + 120)
	call FP_SP_Sub
	stb_dri A, 0xFD, 0xB2, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 56)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 56)
	lda_24 xde, 0x0130af
	lda xwa, (xsp + 56)
	call FP_SP_Mul
	lda xbc, (xsp + 120)
	lda xde, (xsp + 56)
	stb_dri W, 0xFD, 0xC6, 0x00
	call VoiceFloat_SubSP
	jrl DSP_SOS_Algo0_FinalChain

DSP_SOS_Algo0_NonzeroCoeff:
	stb_dri A, 0xFD, 0xD2, 0x00
	lda xwa, (xsp + 72)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 72)
	lda_24 xde, 0x0130b3
	lda xwa, (xsp + 72)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 72)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	stb_dri W, 0xFD, 0x98, 0x00
	push xwa
	call VoiceFloat_DispatchMulAdd
	stb_dri A, 0xFD, 0xDE, 0x00
	lda xwa, (xsp + 84)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 84)
	lda_24 xde, 0x0130bb
	lda xwa, (xsp + 84)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 84)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	stb_dri W, 0xFD, 0x9C, 0x00
	push xwa
	call VoiceFloat_MulAddVariant2
	lda xsp, (xsp + 24)
	stb_dri A, 0xFD, 0x88, 0x00
	lda_24 xde, 0x0130c3
	lda xwa, (xsp + 72)
	call FP_DP_Sub
	lda xbc, (xsp + 72)
	stb_dri B, 0xFD, 0x90, 0x00
	lda xwa, (xsp + 72)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 72)
	stb_dri W, 0xFD, 0xC6, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri A, 0xFD, 0xC6, 0x00
	lda_24 xde, 0x0130cb
	lda xwa, (xsp + 120)
	call FP_SP_Mul
	lda_24 xbc, 0x0130cf
	stb_dri B, 0xFD, 0xC6, 0x00
	lda xwa, (xsp + 56)
	call FP_SP_Sub
	lda xbc, (xsp + 56)
	lda xde, (xsp + 120)
	stb_dri W, 0xFD, 0xB6, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xB2, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 120)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 120)
	lda_24 xde, 0x0130d3
	lda xwa, (xsp + 120)
	call FP_SP_Mul
	stb_dri A, 0xFD, 0xB2, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 56)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 56)
	lda_24 xde, 0x0130d7
	lda xwa, (xsp + 56)
	call FP_SP_Sub
	lda xbc, (xsp + 56)
	lda xde, (xsp + 120)
	stb_dri W, 0xFD, 0xCA, 0x00
	call VoiceFloat_SubSP

DSP_SOS_Algo0_FinalChain:
	lda_24 xbc, 0x0130db
	stb_dri B, 0xFD, 0xCA, 0x00
	lda xwa, (xsp + 120)
	call FP_SP_Sub
	lda_24 xbc, 0x0130df
	stb_dri B, 0xFD, 0xC6, 0x00
	lda xwa, (xsp + 56)
	call FP_SP_Sub
	lda xbc, (xsp + 56)
	lda xde, (xsp + 120)
	stb_dri W, 0xFD, 0xC2, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xCA, 0x00
	stb_dri B, 0xFD, 0xC2, 0x00
	stb_dri W, 0xFD, 0xBE, 0x00
	call FP_SP_Add_Outer
	stb_dri A, 0xFD, 0xC6, 0x00
	stb_dri W, 0xFD, 0xBA, 0x00
	call FP_SP_CopyOrNegate4
	stb_dri A, 0xFD, 0xBE, 0x00
	lda_24 xde, 0x0130e3
	lda xwa, (xsp + 120)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 120)
	stb_dri W, 0xFD, 0x84, 0x00
	call FP_SP_Decode_ReadSign
	push_sriw 0xFD, 0xDA, 0x00
	ldw_sri0 WA, (xsp + 0x00e6)
	ld_sril XBC, (xsp + 0x0086)
	ld de, iz
	call DSP_WriteOscParam
	ldw_erp HL, 0xFA
	stb_dri A, 0xFD, 0xBA, 0x00
	lda_24 xde, 0x0130e7
	lda xwa, (xsp + 120)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 120)
	stb_dri W, 0xFD, 0x80, 0x00
	call FP_SP_Decode_ReadSign
	ld_sril XWA, (xsp + 0x0080)
	ld bc, iz
	call DSP_WriteParamWord
	ldw_erp HL, 0xFA
	stb_dri A, 0xFD, 0xC2, 0x00
	lda_24 xde, 0x0130eb
	lda xwa, (xsp + 120)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 120)
	lda xwa, (xsp + 124)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 124)
	ld bc, iz
	call DSP_WriteParamWord
	ldw_erp HL, 0xFA
	jrl DSP_SOS_Coeff_Epilogue

DSP_SOS_Algo1:
	stb_dri A, 0xFD, 0xCE, 0x00
	lda_24 xde, 0x0130ef
	lda xwa, (xsp + 120)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 120)
	lda xwa, (xsp + 72)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 72)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x0130f3
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	stb_dri W, 0xFD, 0x80, 0x00
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 112)
	stb_dri W, 0xFD, 0xB2, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri W, 0xFD, 0xCE, 0x00
	lds bc, 1
	call FP_SP_CmpZero32
	cps hl, 0
	jrl nz, DSP_SOS_Algo1_NonzeroCoeff
	stb_dri A, 0xFD, 0xD2, 0x00
	lda xwa, (xsp + 72)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 72)
	lda_24 xde, 0x0130fb
	lda xwa, (xsp + 72)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 72)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 112)
	push xwa
	call VoiceFloat_DispatchMulAdd
	stb_dri A, 0xFD, 0xDE, 0x00
	lda xwa, (xsp + 84)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 84)
	lda_24 xde, 0x013103
	lda xwa, (xsp + 84)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 84)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 116)
	push xwa
	call VoiceFloat_MulAddVariant2
	lda xsp, (xsp + 24)
	lda xbc, (xsp + 96)
	lda_24 xde, 0x01310b
	lda xwa, (xsp + 72)
	call FP_DP_Sub
	lda xbc, (xsp + 72)
	lda xde, (xsp + 104)
	lda xwa, (xsp + 72)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 72)
	stb_dri W, 0xFD, 0xCA, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri A, 0xFD, 0xCA, 0x00
	lda_24 xde, 0x013113
	lda xwa, (xsp + 120)
	call FP_SP_Mul
	lda_24 xbc, 0x013117
	stb_dri B, 0xFD, 0xCA, 0x00
	lda xwa, (xsp + 56)
	call FP_SP_Sub
	lda xbc, (xsp + 56)
	lda xde, (xsp + 120)
	stb_dri W, 0xFD, 0xB6, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xB2, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 120)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 120)
	lda_24 xde, 0x01311b
	lda xwa, (xsp + 120)
	call FP_SP_Mul
	stb_dri A, 0xFD, 0xB2, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 56)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 56)
	lda_24 xde, 0x01311f
	lda xwa, (xsp + 56)
	call FP_SP_Sub
	lda xbc, (xsp + 56)
	lda xde, (xsp + 120)
	stb_dri W, 0xFD, 0xC6, 0x00
	call VoiceFloat_SubSP
	jrl DSP_SOS_Algo1_FinalChain

DSP_SOS_Algo1_NonzeroCoeff:
	stb_dri A, 0xFD, 0xD2, 0x00
	lda xwa, (xsp + 72)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 72)
	lda_24 xde, 0x013123
	lda xwa, (xsp + 72)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 72)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 96)
	push xwa
	call VoiceFloat_DispatchMulAdd
	stb_dri A, 0xFD, 0xDE, 0x00
	lda xwa, (xsp + 84)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 84)
	lda_24 xde, 0x01312b
	lda xwa, (xsp + 84)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 84)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 100)
	push xwa
	call VoiceFloat_MulAddVariant2
	lda xsp, (xsp + 24)
	lda xbc, (xsp + 80)
	lda_24 xde, 0x013133
	lda xwa, (xsp + 72)
	call FP_DP_Sub
	lda xbc, (xsp + 72)
	lda xde, (xsp + 88)
	lda xwa, (xsp + 72)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 72)
	stb_dri W, 0xFD, 0xC6, 0x00
	call FP_DP_NormalizeMantissa
	lda_24 xbc, 0x01313b
	stb_dri B, 0xFD, 0xC6, 0x00
	lda xwa, (xsp + 120)
	call FP_SP_Sub
	stb_dri A, 0xFD, 0xC6, 0x00
	lda_24 xde, 0x01313f
	lda xwa, (xsp + 56)
	call FP_SP_Mul
	lda xbc, (xsp + 56)
	lda xde, (xsp + 120)
	stb_dri W, 0xFD, 0xB6, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xB2, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 120)
	call VoiceFloat_SubSP
	lda_24 xbc, 0x013143
	lda xde, (xsp + 120)
	lda xwa, (xsp + 120)
	call FP_SP_Sub
	stb_dri A, 0xFD, 0xB2, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 56)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 56)
	lda_24 xde, 0x013147
	lda xwa, (xsp + 56)
	call FP_SP_Mul
	lda xbc, (xsp + 120)
	lda xde, (xsp + 56)
	stb_dri W, 0xFD, 0xCA, 0x00
	call VoiceFloat_SubSP

DSP_SOS_Algo1_FinalChain:
	stb_dri A, 0xFD, 0xCA, 0x00
	lda_24 xde, 0x01314b
	lda xwa, (xsp + 120)
	call FP_SP_Mul
	stb_dri A, 0xFD, 0xC6, 0x00
	lda_24 xde, 0x01314f
	lda xwa, (xsp + 56)
	call FP_SP_Mul
	lda xbc, (xsp + 56)
	lda xde, (xsp + 120)
	stb_dri W, 0xFD, 0xC2, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xCA, 0x00
	stb_dri B, 0xFD, 0xC2, 0x00
	stb_dri W, 0xFD, 0xBE, 0x00
	call FP_SP_Add_Outer
	stb_dri A, 0xFD, 0xC6, 0x00
	stb_dri W, 0xFD, 0xBA, 0x00
	call FP_SP_CopyOrNegate4
	stb_dri A, 0xFD, 0xBE, 0x00
	lda_24 xde, 0x013153
	lda xwa, (xsp + 120)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 120)
	lda xwa, (xsp + 68)
	call FP_SP_Decode_ReadSign
	push_sriw 0xFD, 0xDA, 0x00
	ldw_sri0 WA, (xsp + 0x00e6)
	ld xbc, (xsp + 70)
	ld de, iz
	call DSP_WriteOscParam
	ldw_erp HL, 0xFA
	stb_dri A, 0xFD, 0xBA, 0x00
	lda_24 xde, 0x013157
	lda xwa, (xsp + 120)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 120)
	lda xwa, (xsp + 64)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 64)
	ld bc, iz
	call DSP_WriteParamWord
	ldw_erp HL, 0xFA
	stb_dri A, 0xFD, 0xC2, 0x00
	lda_24 xde, 0x01315b
	lda xwa, (xsp + 120)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 120)
	lda xwa, (xsp + 60)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 60)
	ld bc, iz
	call DSP_WriteParamWord
	ldw_erp HL, 0xFA
	jrl DSP_SOS_Coeff_Epilogue

DSP_SOS_Algo2:
	stb_dri A, 0xFD, 0xCE, 0x00
	lda_24 xde, 0x01315f
	lda xwa, (xsp + 120)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 120)
	lda xwa, (xsp + 72)
	call FP_DP_NegMantissaLS
	lda xiy, (xsp + 72)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda_24 xiy, 0x013163
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 64)
	push xwa
	call VoiceFloat_CompareAndConvert
	lda xsp, (xsp + 20)
	lda xbc, (xsp + 48)
	stb_dri W, 0xFD, 0xB2, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri W, 0xFD, 0xCE, 0x00
	lds bc, 1
	call FP_SP_CmpZero32
	cps hl, 0
	jrl nz, DSP_SOS_Algo2_NonzeroCoeff
	stb_dri A, 0xFD, 0xD2, 0x00
	lda xwa, (xsp + 72)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 72)
	lda_24 xde, 0x01316b
	lda xwa, (xsp + 72)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 72)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 48)
	push xwa
	call VoiceFloat_DispatchMulAdd
	stb_dri A, 0xFD, 0xDE, 0x00
	lda xwa, (xsp + 84)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 84)
	lda_24 xde, 0x013173
	lda xwa, (xsp + 84)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 84)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 52)
	push xwa
	call VoiceFloat_MulAddVariant2
	lda xsp, (xsp + 24)
	lda xbc, (xsp + 32)
	lda_24 xde, 0x01317b
	lda xwa, (xsp + 72)
	call FP_DP_Sub
	lda xbc, (xsp + 72)
	lda xde, (xsp + 40)
	lda xwa, (xsp + 72)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 72)
	stb_dri W, 0xFD, 0xCA, 0x00
	call FP_DP_NormalizeMantissa
	stb_dri A, 0xFD, 0xCA, 0x00
	lda_24 xde, 0x013183
	lda xwa, (xsp + 120)
	call FP_SP_Mul
	lda_24 xbc, 0x013187
	stb_dri B, 0xFD, 0xCA, 0x00
	lda xwa, (xsp + 56)
	call FP_SP_Sub
	lda xbc, (xsp + 56)
	lda xde, (xsp + 120)
	stb_dri W, 0xFD, 0xB6, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xB2, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 120)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 120)
	lda_24 xde, 0x01318b
	lda xwa, (xsp + 120)
	call FP_SP_Mul
	stb_dri A, 0xFD, 0xB2, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 56)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 56)
	lda_24 xde, 0x01318f
	lda xwa, (xsp + 56)
	call FP_SP_Sub
	lda xbc, (xsp + 56)
	lda xde, (xsp + 120)
	stb_dri W, 0xFD, 0xC6, 0x00
	call VoiceFloat_SubSP
	jrl DSP_SOS_Algo2_FinalChain

DSP_SOS_Algo2_NonzeroCoeff:
	stb_dri A, 0xFD, 0xD2, 0x00
	lda xwa, (xsp + 72)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 72)
	lda_24 xde, 0x013193
	lda xwa, (xsp + 72)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 72)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 32)
	push xwa
	call VoiceFloat_DispatchMulAdd
	stb_dri A, 0xFD, 0xDE, 0x00
	lda xwa, (xsp + 84)
	call FP_DP_NegMantissaLS
	lda xbc, (xsp + 84)
	lda_24 xde, 0x01319b
	lda xwa, (xsp + 84)
	call FP_DP_Add_Outer
	lda xiy, (xsp + 84)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 36)
	push xwa
	call VoiceFloat_MulAddVariant2
	lda xsp, (xsp + 24)
	lda xbc, (xsp + 16)
	lda_24 xde, 0x0131a3
	lda xwa, (xsp + 72)
	call FP_DP_Sub
	lda xbc, (xsp + 72)
	lda xde, (xsp + 24)
	lda xwa, (xsp + 72)
	call VoiceFloat_SubDP
	lda xbc, (xsp + 72)
	stb_dri W, 0xFD, 0xC6, 0x00
	call FP_DP_NormalizeMantissa
	lda_24 xbc, 0x0131ab
	stb_dri B, 0xFD, 0xC6, 0x00
	lda xwa, (xsp + 120)
	call FP_SP_Sub
	stb_dri A, 0xFD, 0xC6, 0x00
	lda_24 xde, 0x0131af
	lda xwa, (xsp + 56)
	call FP_SP_Mul
	lda xbc, (xsp + 56)
	lda xde, (xsp + 120)
	stb_dri W, 0xFD, 0xB6, 0x00
	call VoiceFloat_SubSP
	stb_dri A, 0xFD, 0xB2, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 120)
	call VoiceFloat_SubSP
	lda_24 xbc, 0x0131b3
	lda xde, (xsp + 120)
	lda xwa, (xsp + 120)
	call FP_SP_Sub
	stb_dri A, 0xFD, 0xB2, 0x00
	stb_dri B, 0xFD, 0xB6, 0x00
	lda xwa, (xsp + 56)
	call VoiceFloat_SubSP
	lda xbc, (xsp + 56)
	lda_24 xde, 0x0131b7
	lda xwa, (xsp + 56)
	call FP_SP_Mul
	lda xbc, (xsp + 120)
	lda xde, (xsp + 56)
	stb_dri W, 0xFD, 0xCA, 0x00
	call VoiceFloat_SubSP

DSP_SOS_Algo2_FinalChain:
	stb_dri A, 0xFD, 0xCA, 0x00
	lda_24 xde, 0x0131bb
	lda xwa, (xsp + 120)
	call FP_SP_Mul
	stb_dri A, 0xFD, 0xC6, 0x00
	lda_24 xde, 0x0131bf
	lda xwa, (xsp + 56)
	call FP_SP_Mul
	lda xbc, (xsp + 56)
	lda xde, (xsp + 120)
	stb_dri W, 0xFD, 0xC2, 0x00
	call VoiceFloat_SubSP
	ld_sril XWA, (xsp + 0x00ca)
	stl_dri XWA, 0xFD, 0xBE, 0x00
	stb_dri A, 0xFD, 0xC6, 0x00
	stb_dri W, 0xFD, 0xBA, 0x00
	call FP_SP_CopyOrNegate4
	stb_dri A, 0xFD, 0xBA, 0x00
	lda_24 xde, 0x0131c3
	lda xwa, (xsp + 120)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 120)
	lda xwa, (xsp + 12)
	call FP_SP_Decode_ReadSign
	push_sriw 0xFD, 0xDA, 0x00
	ldw_sri0 WA, (xsp + 0x00e6)
	ld xbc, (xsp + 14)
	ld de, iz
	call DSP_WriteOscParam
	ldw_erp HL, 0xFA
	stb_dri A, 0xFD, 0xC2, 0x00
	lda_24 xde, 0x0131c7
	lda xwa, (xsp + 120)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 120)
	lda xwa, (xsp + 8)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 8)
	ld bc, iz
	ldw_sri0 DE, (xsp + 0x00da)
	call DSP_WriteCoeffData_5B_Direct
	ldw_erp HL, 0xFA
	stb_dri A, 0xFD, 0xBE, 0x00
	lda_24 xde, 0x0131cb
	lda xwa, (xsp + 120)
	call FP_SP_Add_Outer
	lda xbc, (xsp + 120)
	lda xwa, (xsp + 4)
	call FP_SP_Decode_ReadSign
	ld xwa, (xsp + 4)
	ld bc, iz
	ldw_sri0 DE, (xsp + 0x00da)
	call DSP_WriteCoeffData_5B_Direct
	ldw_erp HL, 0xFA

DSP_SOS_Coeff_Epilogue:
	ld_sril XBC, (xsp + 0x00dc)
	stw_erp WA, 0xFA
	ld (xbc), wa
	ld_sril XHL, (xsp + 0x00e6)
	pop xiz
	stb_dri L, 0xFD, 0xD2, 0x00
	retd 0x10

DSP_MixerCoeff_Compute:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), de
	ld (xsp + 22), wa
	ld wa, bc
	extz xwa
	sll xwa, 2
	ld xbc, 0x131CF
	add xbc, xwa
	ld xde, (xbc)
	srl xde, 15
	ld wa, (xsp + 22)
	sll wa, 2
	lda_d16 xbc, 61760
	extz xwa
	add xwa, xbc
	ld xwa, (xwa)
	sra xwa, 0
	ld xbc, xde
	call FP_MulAccum64
	srl xhl, 0
	ld wa, (xsp + 20)
	sll wa, 2
	lda_d16 xbc, 61760
	extz xwa
	add xwa, xbc
	ld xwa, (xwa)
	sra xwa, 15
	ld xbc, xhl
	call FP_MulAccum64
	ld (xsp + 8), xhl
	ld wa, (xsp + 22)
	sll wa, 2
	lda_d16 xbc, 61760
	ld iz, wa
	extz xiz
	add xiz, xbc
	lda xwa, (xsp + 12)
	ld xbc, xiz
	call FP_SP_CallWithBuf8
	lda xbc, (xsp + 12)
	lda xwa, (xsp + 16)
	call FP_SP_Decode_ReadSign
	ldw wa, 0x30
	lds bc, 1
	call DSP_DispatchCommand
	lds wa, 0
	lds bc, 1
	call DSP_DispatchData
	ldw wa, 0xD0
	lds bc, 1
	call DSP_DispatchData
	ld xwa, (xsp + 8)
	srl xwa, 8
	srl xwa, 0
	lds bc, 1
	call DSP_DispatchData
	ld xwa, (xsp + 8)
	srl xwa, 0
	lds bc, 1
	call DSP_DispatchData
	call DSP2_SPI_BusIdle
	call DSP_Bytecode_NotifyStateChange
	ldw wa, 0x30
	lds bc, 1
	call DSP_DispatchCommand
	lds wa, 0
	lds bc, 1
	call DSP_DispatchData
	ldw wa, 0xD3
	lds bc, 1
	call DSP_DispatchData
	ld xwa, (xsp + 16)
	srl xwa, 9
	srl xwa, 0
	lds bc, 1
	call DSP_DispatchData
	ld xwa, (xsp + 16)
	srl xwa, 1
	srl xwa, 0
	lds bc, 1
	call DSP_DispatchData
	call DSP2_SPI_BusIdle
	call DSP_Bytecode_NotifyStateChange
	pop xiz
	lda xsp, (xsp + 20)
	ret

DSP_WriteEFFConfig:
	ld de, wa
	extz xde
	ld xhl, 0x1ED6D
	add xhl, xde
	ld e, (xhl)
	extz de
	push xbc
	ld hl, de
	ld bc, wa
	lda_24 xde, 0x014777
	ld wa, hl
	call DSP_BytecodeInterpreter_Init
	ret

DSP_WriteGlobalConfig:
	lds de, 0
	push xbc
	ld bc, de
	lda_24 xde, 0x0147b3
	call DSP_BytecodeInterpreter_Init
	ret

DSP_WriteParameter:
	ld xix, (xsp + 4)
	cps wa, 1
	jr nz, DSP_WriteParam_Generic
	cp bc, 0x9
	jr z, DSP_WriteParam_EFFCase
	cp bc, 0xA
	jr nz, DSP_WriteParam_Generic

DSP_WriteParam_EFFCase:
	cp bc, 0xA
	jr z, DSP_WriteParam_EFFCase0xA
	cp bc, 0x9
	jrl nz, DSP_WriteParam_Return
	lda_24 xhl, 0x01e17f
	lda_24 xbc, 0x01e19e
	push xbc
	pushw de
	ld bc, wa
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	sll xde, 3
	inc 8, xde
	add xde, xix
	lda xbc, (xde + 4)
	push xbc
	lda_24 xbc, 0x014777
	ld xde, xhl
	call DSP_ParameterWriteEngine
	jr DSP_WriteParam_Return

DSP_WriteParam_EFFCase0xA:
	lda_24 xhl, 0x01e40a
	lda_24 xbc, 0x01e42d
	push xbc
	pushw de
	ld bc, wa
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	sll xde, 3
	inc 8, xde
	add xde, xix
	lda xbc, (xde + 4)
	push xbc
	lda_24 xbc, 0x014777
	ld xde, xhl
	call DSP_ParameterWriteEngine
	jr DSP_WriteParam_Return

DSP_WriteParam_Generic:
	ld hl, bc
	extz xhl
	sll xhl, 2
	ld xiy, 0x1F22C
	add xiy, xhl
	ld xhl, (xiy)
	extz xbc
	sll xbc, 2
	ld xiy, 0x1F09C
	add xiy, xbc
	ld xbc, (xiy)
	push xbc
	pushw de
	ld bc, wa
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	sll xde, 3
	inc 8, xde
	add xde, xix
	lda xbc, (xde + 4)
	push xbc
	lda_24 xbc, 0x014777
	ld xde, xhl
	call DSP_ParameterWriteEngine

DSP_WriteParam_Return:
	retd 0x4
	ret

DSP_Bytecode_NotifyStateChange:
	lds wa, 1
	jp TaskSched_PreemptiveYield_INT

DSP_BytecodeInterpreter_Init:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 20), wa
	ld wa, bc
	extz xwa
	ld xhl, xwa
	add xhl, xhl
	add xhl, xwa
	sll xhl, 2
	add xhl, xde
	ld wa, (xhl)
	ld (xsp + 8), wa
	ld wa, bc
	extz xwa
	ld xhl, xwa
	add xhl, xhl
	add xhl, xwa
	sll xhl, 2
	add xhl, xde
	ld wa, (xhl + 2)
	ld (xsp + 10), wa
	ld wa, bc
	extz xwa
	ld xhl, xwa
	add xhl, xhl
	add xhl, xwa
	sll xhl, 2
	add xhl, xde
	ld wa, (xhl + 4)
	ld (xsp + 12), wa
	ld wa, bc
	extz xwa
	ld xhl, xwa
	add xhl, xhl
	add xhl, xwa
	sll xhl, 2
	add xhl, xde
	ld wa, (xhl + 6)
	ld (xsp + 14), wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	add xbc, xde
	ld xwa, (xbc + 8)
	ld (xsp + 16), xwa
	jrl DSP_BytecodeInterpreter_CheckEnd

DSP_BytecodeInterpreter_Loop:
	ld xwa, (xsp + 26)
	ld a, (xwa)
	and a, 0xF0
	ld e, a
	extz de
	ld xwa, (xsp + 26)
	ld a, (xwa + 1)
	and a, 0xFF
	ld c, a
	extz bc
	ld xwa, (xsp + 26)
	ld a, (xwa)
	and a, 0xF
	extz wa
	sla wa, 8
	add wa, bc
	dec 2, wa
	ld (xsp + 6), wa
	ld xwa, (xsp + 26)
	inc 2, xwa
	ld (xsp + 26), xwa
	ld wa, de
	srl wa, 4
	cp wa, 0xE
	jrl z, DSP_Bytecode_Op0E_SendCommand
	cp wa, 0xD
	jrl z, DSP_Bytecode_Op0D_StateChange
	cps wa, 5
	jrl ugt, DSP_BytecodeInterpreter_CheckEnd
	add wa, wa
	lda_24 xix, 0x014739
	ldw_sri WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0x03c32e
	jp_ind 8, 0x07, 0xF0, 0xE0


// DSP_Bytecode_Programs: 1613 bytes of native TLCS-900 code implementing
// 6 opcode handlers (0-5) for the DSP bytecode interpreter.
// Dispatch table at OFFSETS_14739 contains 16-bit offsets from this address.
//
// Uses prevbank registers (D7), auto-increment addressing ld C,(XWA+),
// and compact register forms. Cannot be converted to LLVM native instructions
// due to unsupported addressing modes.
//
// Handler 0 (offset 0x000, 570 bytes): Command + 2 preamble + groups-of-5
//   3-way branch per group: 0x00=static addr, 0x0A=raw, else=param-modified
//   Mixes 32-bit runtime parameter into template coefficients (Branch C)
//
// Handler 1 (offset 0x23A, 249 bytes): Command + 2 preamble + groups-of-5
//   12-bit address computation (4-bit shift), accumulator at stack[0x08]
//
// Handler 2 (offset 0x333, 167 bytes): Command + 2 preamble + groups-of-3
//   Pure raw data writes, no address computation
//
// Handler 3 (offset 0x3DA, 153 bytes): Command + 16-bit address + raw tail
//   16-bit address (8-bit shift), accumulator at stack[0x0E]
//
// Handler 4 (offset 0x473, 26 bytes): Single command byte only
//   Simplest handler - no data, no loop
//
// Handler 5 (offset 0x48D, 448 bytes): Command + 2 preamble + groups-of-5
//   2-way branch: 0x08=addr (with IZH mask), else=param-modified
//   Variant of Handler 0 with different branching and accumulator at stack[0x0C]
DSP_Bytecode_Programs:
	.byte 0xaf, 0x1a, 0x20, 0xc5, 0xe0, 0x23, 0xbf, 0x1a
	.byte 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f, 0x14, 0x21
	.byte 0x1d, 0x2e, 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf
	.byte 0x1a, 0x20, 0xc5, 0xe0, 0x23, 0xbf, 0x1a, 0x60
	.byte 0xcb, 0x89, 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d
	.byte 0x4f, 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x1a
	.byte 0x20, 0xc5, 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb
	.byte 0x89, 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f
	.byte 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xbf, 0x04, 0x02
	.byte 0x01, 0x00, 0x78, 0xd9, 0x01, 0xaf, 0x1a, 0x20
	.byte 0x80, 0x3f, 0x00, 0x7e, 0x96, 0x00, 0xaf, 0x1a
	.byte 0x20, 0xc5, 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb
	.byte 0x89, 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f
	.byte 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x1a, 0x20
	.byte 0xc5, 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89
	.byte 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a
	.byte 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x1a, 0x20, 0x88
	.byte 0x01, 0x21, 0xc9, 0xef, 0x04, 0xc9, 0xcc, 0x0f
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xaf, 0x1a, 0x20, 0x80
	.byte 0x21, 0xd8, 0x12, 0xd8, 0x8e, 0xde, 0xee, 0x04
	.byte 0xd9, 0x86, 0x9f, 0x0a, 0x20, 0xd8, 0x86, 0xde
	.byte 0x88, 0xd8, 0xef, 0x04, 0x20, 0x00, 0xd8, 0x12
	.byte 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7
	.byte 0xfa, 0x9b, 0xde, 0x88, 0xd8, 0xee, 0x04, 0x20
	.byte 0x00, 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f
	.byte 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x1a, 0x20
	.byte 0xe8, 0x62, 0xbf, 0x1a, 0x60, 0xc5, 0xe0, 0x23
	.byte 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f
	.byte 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa
	.byte 0x9b, 0x78, 0x37, 0x01, 0xaf, 0x1a, 0x20, 0x80
	.byte 0x3f, 0x0a, 0x6e, 0x76, 0xaf, 0x1a, 0x20, 0xc5
	.byte 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8
	.byte 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03
	.byte 0xd7, 0xfa, 0x9b, 0xaf, 0x1a, 0x20, 0xc5, 0xe0
	.byte 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12
	.byte 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7
	.byte 0xfa, 0x9b, 0xaf, 0x1a, 0x20, 0xc5, 0xe0, 0x23
	.byte 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f
	.byte 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa
	.byte 0x9b, 0xaf, 0x1a, 0x20, 0xc5, 0xe0, 0x23, 0xbf
	.byte 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f, 0x14
	.byte 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa, 0x9b
	.byte 0xaf, 0x1a, 0x20, 0xc5, 0xe0, 0x23, 0xbf, 0x1a
	.byte 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f, 0x14, 0x21
	.byte 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0x78
	.byte 0xb9, 0x00, 0xaf, 0x1a, 0x20, 0xc5, 0xe0, 0x23
	.byte 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f
	.byte 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa
	.byte 0x9b, 0xaf, 0x10, 0x20, 0xe8, 0xed, 0x01, 0xe8
	.byte 0xed, 0x00, 0xe8, 0x89, 0xe9, 0xcc, 0x7f, 0x00
	.byte 0x00, 0x00, 0xaf, 0x1a, 0x20, 0x80, 0x21, 0xd8
	.byte 0x12, 0xe8, 0x12, 0xe9, 0x80, 0xd8, 0x12, 0x9f
	.byte 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa
	.byte 0x9b, 0xaf, 0x10, 0x20, 0xe8, 0xed, 0x09, 0xe8
	.byte 0x89, 0xe9, 0xcc, 0xff, 0x00, 0x00, 0x00, 0xaf
	.byte 0x1a, 0x20, 0x88, 0x01, 0x21, 0xd8, 0x12, 0xe8
	.byte 0x12, 0xe9, 0x80, 0xd8, 0x12, 0x9f, 0x14, 0x21
	.byte 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf
	.byte 0x10, 0x20, 0xe8, 0xed, 0x01, 0xe8, 0x89, 0xe9
	.byte 0xcc, 0xff, 0x00, 0x00, 0x00, 0xaf, 0x1a, 0x20
	.byte 0x88, 0x02, 0x21, 0xd8, 0x12, 0xe8, 0x12, 0xe9
	.byte 0x80, 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f
	.byte 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x10, 0x20
	.byte 0xe8, 0xec, 0x07, 0xe8, 0x89, 0xe9, 0xcc, 0x80
	.byte 0x00, 0x00, 0x00, 0xaf, 0x1a, 0x20, 0x88, 0x03
	.byte 0x21, 0xd8, 0x12, 0xe8, 0x12, 0xe9, 0x80, 0xd8
	.byte 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03
	.byte 0xd7, 0xfa, 0x9b, 0xaf, 0x1a, 0x20, 0xe8, 0x64
	.byte 0xbf, 0x1a, 0x60, 0x9f, 0x04, 0x61, 0x9f, 0x06
	.byte 0x20, 0xd8, 0x6b, 0xe8, 0x12, 0xd8, 0x0a, 0x05
	.byte 0x00, 0x9f, 0x04, 0xf8, 0x73, 0x16, 0xfe, 0x78
	.byte 0x66, 0x04, 0xaf, 0x1a, 0x20, 0xc5, 0xe0, 0x23
	.byte 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f
	.byte 0x14, 0x21, 0x1d, 0x2e, 0x6a, 0x03, 0xd7, 0xfa
	.byte 0x9b, 0xaf, 0x1a, 0x20, 0xc5, 0xe0, 0x23, 0xbf
	.byte 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f, 0x14
	.byte 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa, 0x9b
	.byte 0xaf, 0x1a, 0x20, 0xc5, 0xe0, 0x23, 0xbf, 0x1a
	.byte 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f, 0x14, 0x21
	.byte 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xbf
	.byte 0x04, 0x02, 0x01, 0x00, 0x78, 0x98, 0x00, 0xaf
	.byte 0x1a, 0x20, 0xc5, 0xe0, 0x23, 0xbf, 0x1a, 0x60
	.byte 0xcb, 0x89, 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d
	.byte 0x4f, 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x1a
	.byte 0x20, 0xc5, 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb
	.byte 0x89, 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f
	.byte 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x1a, 0x20
	.byte 0x88, 0x01, 0x21, 0xc9, 0xef, 0x04, 0xc9, 0xcc
	.byte 0x0f, 0xc9, 0x8b, 0xd9, 0x12, 0xaf, 0x1a, 0x20
	.byte 0x80, 0x21, 0xd8, 0x12, 0xd8, 0x8e, 0xde, 0xee
	.byte 0x04, 0xd9, 0x86, 0x9f, 0x08, 0x20, 0xd8, 0x86
	.byte 0xde, 0x88, 0xd8, 0xef, 0x04, 0x20, 0x00, 0xd8
	.byte 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03
	.byte 0xd7, 0xfa, 0x9b, 0xde, 0x88, 0xd8, 0xee, 0x04
	.byte 0x20, 0x00, 0xd8, 0x60, 0xd8, 0x12, 0x9f, 0x14
	.byte 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa, 0x9b
	.byte 0xaf, 0x1a, 0x20, 0xe8, 0x62, 0xbf, 0x1a, 0x60
	.byte 0xc5, 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89
	.byte 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a
	.byte 0x03, 0xd7, 0xfa, 0x9b, 0x9f, 0x04, 0x61, 0x9f
	.byte 0x06, 0x20, 0xd8, 0x6b, 0xe8, 0x12, 0xd8, 0x0a
	.byte 0x05, 0x00, 0x9f, 0x04, 0xf8, 0x73, 0x57, 0xff
	.byte 0x78, 0x6d, 0x03, 0xaf, 0x1a, 0x20, 0xc5, 0xe0
	.byte 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12
	.byte 0x9f, 0x14, 0x21, 0x1d, 0x2e, 0x6a, 0x03, 0xd7
	.byte 0xfa, 0x9b, 0xaf, 0x1a, 0x20, 0xc5, 0xe0, 0x23
	.byte 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f
	.byte 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa
	.byte 0x9b, 0xaf, 0x1a, 0x20, 0xc5, 0xe0, 0x23, 0xbf
	.byte 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f, 0x14
	.byte 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa, 0x9b
	.byte 0xbf, 0x04, 0x02, 0x01, 0x00, 0x68, 0x48, 0xaf
	.byte 0x1a, 0x20, 0xc5, 0xe0, 0x23, 0xbf, 0x1a, 0x60
	.byte 0xcb, 0x89, 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d
	.byte 0x4f, 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x1a
	.byte 0x20, 0xc5, 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb
	.byte 0x89, 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f
	.byte 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x1a, 0x20
	.byte 0xc5, 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89
	.byte 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a
	.byte 0x03, 0xd7, 0xfa, 0x9b, 0x9f, 0x04, 0x61, 0x9f
	.byte 0x06, 0x20, 0xd8, 0x6b, 0xe8, 0x12, 0xd8, 0x0a
	.byte 0x03, 0x00, 0x9f, 0x04, 0xf8, 0x63, 0xa8, 0x78
	.byte 0xc6, 0x02, 0xaf, 0x1a, 0x20, 0xc5, 0xe0, 0x23
	.byte 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f
	.byte 0x14, 0x21, 0x1d, 0x2e, 0x6a, 0x03, 0xd7, 0xfa
	.byte 0x9b, 0xaf, 0x1a, 0x20, 0x88, 0x01, 0x21, 0xc9
	.byte 0xcc, 0xff, 0xc9, 0x8b, 0xd9, 0x12, 0xaf, 0x1a
	.byte 0x20, 0x80, 0x21, 0xd8, 0x12, 0xd8, 0x8e, 0xde
	.byte 0xee, 0x08, 0xd9, 0x86, 0x9f, 0x0e, 0x20, 0xd8
	.byte 0x86, 0xde, 0x88, 0xd8, 0xef, 0x08, 0x20, 0x00
	.byte 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a
	.byte 0x03, 0xd7, 0xfa, 0x9b, 0xde, 0x88, 0x20, 0x00
	.byte 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a
	.byte 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x1a, 0x20, 0xe8
	.byte 0x62, 0xbf, 0x1a, 0x60, 0xbf, 0x04, 0x02, 0x01
	.byte 0x00, 0x9f, 0x06, 0x20, 0xd8, 0x6b, 0x9f, 0x04
	.byte 0xf8, 0x7b, 0x54, 0x02, 0xaf, 0x1a, 0x20, 0xc5
	.byte 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8
	.byte 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03
	.byte 0xd7, 0xfa, 0x9b, 0x9f, 0x04, 0x61, 0x9f, 0x06
	.byte 0x20, 0xd8, 0x6b, 0x9f, 0x04, 0xf8, 0x63, 0xdc
	.byte 0x78, 0x2d, 0x02, 0xaf, 0x1a, 0x20, 0xc5, 0xe0
	.byte 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12
	.byte 0x9f, 0x14, 0x21, 0x1d, 0x2e, 0x6a, 0x03, 0xd7
	.byte 0xfa, 0x9b, 0x78, 0x13, 0x02, 0xaf, 0x1a, 0x20
	.byte 0xc5, 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89
	.byte 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x2e, 0x6a
	.byte 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x1a, 0x20, 0xc5
	.byte 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8
	.byte 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03
	.byte 0xd7, 0xfa, 0x9b, 0xaf, 0x1a, 0x20, 0xc5, 0xe0
	.byte 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12
	.byte 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7
	.byte 0xfa, 0x9b, 0xbf, 0x04, 0x02, 0x01, 0x00, 0x78
	.byte 0x60, 0x01, 0xaf, 0x1a, 0x20, 0x80, 0x3f, 0x08
	.byte 0x7e, 0x9b, 0x00, 0xaf, 0x1a, 0x20, 0xc5, 0xe0
	.byte 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12
	.byte 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7
	.byte 0xfa, 0x9b, 0xaf, 0x1a, 0x20, 0xc5, 0xe0, 0x23
	.byte 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8, 0x12, 0x9f
	.byte 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa
	.byte 0x9b, 0xaf, 0x1a, 0x20, 0x88, 0x01, 0x21, 0xc9
	.byte 0xef, 0x04, 0xc9, 0xcc, 0x0f, 0xc9, 0x8b, 0xd9
	.byte 0x12, 0xaf, 0x1a, 0x20, 0x80, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x8e, 0xde, 0xee, 0x04, 0xd9, 0x86, 0x9f
	.byte 0x0c, 0x20, 0xd8, 0x86, 0xc7, 0xf9, 0xa8, 0xde
	.byte 0x88, 0xd8, 0xef, 0x04, 0x20, 0x00, 0xd8, 0x12
	.byte 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7
	.byte 0xfa, 0x9b, 0xde, 0x88, 0xd8, 0xee, 0x04, 0x20
	.byte 0x00, 0xd8, 0x60, 0xd8, 0x12, 0x9f, 0x14, 0x21
	.byte 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf
	.byte 0x1a, 0x20, 0xe8, 0x62, 0xbf, 0x1a, 0x60, 0xc5
	.byte 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb, 0x89, 0xd8
	.byte 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03
	.byte 0xd7, 0xfa, 0x9b, 0x78, 0xb9, 0x00, 0xaf, 0x1a
	.byte 0x20, 0xc5, 0xe0, 0x23, 0xbf, 0x1a, 0x60, 0xcb
	.byte 0x89, 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f
	.byte 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x10, 0x20
	.byte 0xe8, 0xed, 0x01, 0xe8, 0xed, 0x00, 0xe8, 0x89
	.byte 0xe9, 0xcc, 0x7f, 0x00, 0x00, 0x00, 0xaf, 0x1a
	.byte 0x20, 0x80, 0x21, 0xd8, 0x12, 0xe8, 0x12, 0xe9
	.byte 0x80, 0xd8, 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f
	.byte 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf, 0x10, 0x20
	.byte 0xe8, 0xed, 0x09, 0xe8, 0x89, 0xe9, 0xcc, 0xff
	.byte 0x00, 0x00, 0x00, 0xaf, 0x1a, 0x20, 0x88, 0x01
	.byte 0x21, 0xd8, 0x12, 0xe8, 0x12, 0xe9, 0x80, 0xd8
	.byte 0x12, 0x9f, 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03
	.byte 0xd7, 0xfa, 0x9b, 0xaf, 0x10, 0x20, 0xe8, 0xed
	.byte 0x01, 0xe8, 0x89, 0xe9, 0xcc, 0xff, 0x00, 0x00
	.byte 0x00, 0xaf, 0x1a, 0x20, 0x88, 0x02, 0x21, 0xd8
	.byte 0x12, 0xe8, 0x12, 0xe9, 0x80, 0xd8, 0x12, 0x9f
	.byte 0x14, 0x21, 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa
	.byte 0x9b, 0xaf, 0x10, 0x20, 0xe8, 0xec, 0x07, 0xe8
	.byte 0x89, 0xe9, 0xcc, 0x80, 0x00, 0x00, 0x00, 0xaf
	.byte 0x1a, 0x20, 0x88, 0x03, 0x21, 0xd8, 0x12, 0xe8
	.byte 0x12, 0xe9, 0x80, 0xd8, 0x12, 0x9f, 0x14, 0x21
	.byte 0x1d, 0x4f, 0x6a, 0x03, 0xd7, 0xfa, 0x9b, 0xaf
	.byte 0x1a, 0x20, 0xe8, 0x64, 0xbf, 0x1a, 0x60, 0x9f
	.byte 0x04, 0x61, 0x9f, 0x06, 0x20, 0xd8, 0x6b, 0xe8
	.byte 0x12, 0xd8, 0x0a, 0x05, 0x00, 0x9f, 0x04, 0xf8
	.byte 0x73, 0x8f, 0xfe, 0x68, 0x53

DSP_Bytecode_Op0D_StateChange:
	call DSP2_SPI_BusIdle
	calr DSP_Bytecode_NotifyStateChange
	jr DSP_BytecodeInterpreter_CheckEnd

DSP_Bytecode_Op0E_SendCommand:
	ld xwa, (xsp + 26)
	ldb_spi C, 0xE0
	ld (xsp + 26), xwa
	ld a, c
	extz wa
	ld bc, (xsp + 20)
	call DSP_DispatchCommand
	ldw_erp HL, 0xFA
	ldw (xsp + 4), 0x1
	ld wa, (xsp + 6)
	dec 1, wa
	cp (xsp + 4), wa
	jr ugt, DSP_BytecodeInterpreter_CheckEnd

DSP_Bytecode_Op0E_DataLoop:
	ld xwa, (xsp + 26)
	ldb_spi C, 0xE0
	ld (xsp + 26), xwa
	ld a, c
	extz wa
	ld bc, (xsp + 20)
	call DSP_DispatchData
	ldw_erp HL, 0xFA
	incm 1, (xsp + 4)
	ld wa, (xsp + 6)
	dec 1, wa
	cp (xsp + 4), wa
	jr ule, DSP_Bytecode_Op0E_DataLoop

DSP_BytecodeInterpreter_CheckEnd:
	ld xwa, (xsp + 26)
	ld a, (xwa)
	and a, 0xF0
	cp a, 0xF0
	jrl nz, DSP_BytecodeInterpreter_Loop
	stw_erp HL, 0xFA
	pop xiz
	lda xsp, (xsp + 18)
	retd 0x4

DSP_ParameterWriteEngine:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld (xsp + 20), wa
	ld xiz, (xsp + 32)
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x1ED6D
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld (xsp + 4), wa
	ldw (xsp + 10), 0x0
	lda xwa, (xsp + 10)
	ld xde, xwa
	lda xwa, (xsp + 6)
	push xwa
	ld xwa, xiz
	ld bc, (xsp + 34)
	calr DSP_TableWalk_SearchWithState
	ld xiz, xhl
	cpw (xsp + 10), 0x0
	jr z, DSP_ParamLoop_CheckBound
	ld wa, (xsp + 10)
	calr DSP_NopReturn
	jr DSP_ParamLoop_Return

DSP_ParamLoop_CheckBound:
	cp xiz, (xsp + 6)
	jr nc, DSP_ParamLoop_Return

DSP_ParamLoop_Iterate:
	cpw (xsp + 4), 0x0
	jr nz, DSP_ParamLoop_CallTranslator
	ld bc, (xsp + 4)
	lds wa, 1
	call DSP_DispatchCommand
	ld (xsp + 10), hl
	ld bc, (xsp + 4)
	lds wa, 1
	call DSP_DispatchData
	ld (xsp + 10), hl
	ld bc, (xsp + 4)
	ldw wa, 0x60
	call DSP_DispatchData
	ld (xsp + 10), hl

DSP_ParamLoop_CallTranslator:
	push xiz
	ld xwa, (xsp + 16)
	push xwa
	ld xwa, (xsp + 34)
	push xwa
	ld xwa, (xsp + 28)
	push xwa
	lda xwa, (xsp + 26)
	push xwa
	ld wa, (xsp + 24)
	ld bc, (xsp + 40)
	ld de, (xsp + 50)
	calr DSP_PerParameterTranslator
	ld xiz, xhl
	cpw (xsp + 10), 0x0
	jr z, DSP_ParamLoop_PostCall
	ld wa, (xsp + 10)
	calr DSP_NopReturn
	jr DSP_ParamLoop_Return

DSP_ParamLoop_PostCall:
	cpw (xsp + 4), 0x0
	jr nz, DSP_ParamLoop_SendEndCmd
	ld bc, (xsp + 4)
	lds wa, 3
	call DSP_DispatchCommand
	ld (xsp + 10), hl

DSP_ParamLoop_SendEndCmd:
	cp xiz, (xsp + 6)
	jr c, DSP_ParamLoop_Iterate

DSP_ParamLoop_Return:
	pop xiz
	lda xsp, (xsp + 18)
	retd 0xA

DSP_PerParameterTranslator:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 16), de
	ld (xsp + 18), bc
	ld (xsp + 20), wa
	ld xde, (xsp + 30)
	ld wa, (xsp + 18)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	add xbc, xde
	ld wa, (xbc)
	ld (xsp + 4), wa
	ld wa, (xsp + 18)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	add xbc, xde
	ld wa, (xbc + 2)
	ld (xsp + 6), wa
	ld wa, (xsp + 18)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	add xbc, xde
	ld wa, (xbc + 4)
	ld (xsp + 8), wa
	ld wa, (xsp + 18)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	add xbc, xde
	ld xwa, (xbc + 8)
	ld (xsp + 10), xwa
	jrl DSP_Translator_CheckEnd

DSP_Translator_ReadOpcode:
	ld xbc, (xsp + 42)
	lds32 xwa, 1
	add (xsp + 42), xwa
	ld a, (xbc)
	ld e, a
	extz de
	lda xwa, (xsp + 14)
	push xwa
	ld xwa, (xsp + 42)
	stw_erp BC, 0xFA
	calr DSP_TableWalk_Search
	cpw (xsp + 14), 0x0
	jrl nz, DSP_Translator_Return
	ld a, (xhl)
	ldb_erp A, 0xF8
	extz iz
	ld wa, (xsp + 16)
	extz xwa
	add xwa, xwa
	add xwa, (xsp + 34)
	ld de, (xwa)
	exts xde
	stw_erp WA, 0xFA
	cp wa, 0x21
	jrl z, DSP_Op_0x21_Interp2Point
	cp wa, 0x24
	jrl z, DSP_Op_0x24_MultiStepInterp
	cp wa, 0x40
	jrl z, DSP_Op_0x40_PanScale
	sub wa, 0x61
	cps wa, 0
	jrl c, DSP_Op_Unknown_Error
	cp wa, 0x18
	jrl ugt, DSP_Op_Unknown_Error
	add wa, wa
	lda_24 xix, 0x014745
	ldw_sri WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0x03cb8e
	jp_ind 8, 0x07, 0xF0, 0xE0
DSP_Translator_JumpTable:
	.byte 0xbf, 0x2a, 0x30, 0xea, 0x89, 0x1d, 0x9f, 0x8e
	.byte 0x03, 0x9f, 0x04, 0x04, 0xde, 0x88, 0xeb, 0x89
	.byte 0x9f, 0x16, 0x22, 0x1d, 0xe6, 0x87, 0x03, 0xbf
	.byte 0x0e, 0x53

DSP_Translator_PostDispatch:
	cpw (xsp + 20), 0x1
	jr nz, DSP_Translator_CheckEnd
	call DSP2_SPI_BusIdle
	calr DSP_Bytecode_NotifyStateChange

DSP_Translator_CheckEnd:
	ld xbc, (xsp + 42)
	lds32 xwa, 1
	add (xsp + 42), xwa
	ld a, (xbc)
	extz wa
	ldw_erp WA, 0xFA
	cp wa, 0x7A
	jrl nz, DSP_Translator_ReadOpcode

DSP_Translator_Return:
	ld xbc, (xsp + 26)
	ld wa, (xsp + 14)
	ld (xbc), wa
	ld xhl, (xsp + 42)
	pop xiz
	lda xsp, (xsp + 18)
	retd 0x14
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_ParamFetch_SingleTable
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jr DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_ParamFetch_AlgoTypeTable
	pushm (xsp + 6)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteFreqParam_AlgoType
	ld (xsp + 14), hl
	jr DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_AlgoParam_Decode
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_PitchParam_Scale
	pushm (xsp + 6)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteFreqParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_VolumeParam_Scale
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_ParamInterp_2Point
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_ParamInterp_FPScale
	pushm (xsp + 8)
	ld xwa, (xsp + 12)
	push xwa
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 26)
	call DSP_WriteOscParam_Offset
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_ParamInterp_Div0xB4
	pushm (xsp + 6)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteFreqParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_VolumeCurve_FP
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_FreqCurve_FP
	pushm (xsp + 6)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteFreqParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_FreqInterp_2Point
	pushm (xsp + 6)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteFreqParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	ld xde, (xsp + 10)
	call DSP_ParamInterp_3Point_WithOffset
	pushm (xsp + 6)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteFreqParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_ReverbCurve_FP
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_ParamInterp_FPComplex
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_PanCurve_PiecewiseLin
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	ld xwa, (xsp + 42)
	push xwa
	pushw iz
	ld xwa, (xsp + 40)
	push xwa
	pushm (xsp + 14)
	lda xwa, (xsp + 26)
	push xwa
	ld wa, (xsp + 36)
	ld bc, (xsp + 34)
	ld de, (xsp + 32)
	call DSP_BiquadCoeff_Compute
	ld (xsp + 42), xhl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_DetuneCurve_SignedFP
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	pushm (xsp + 16)
	pushw iz
	pushm (xsp + 24)
	pushm (xsp + 10)
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 42)
	ld de, (xsp + 26)
	call DSP_BiquadWarp_FP
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_ParamInterp_Div0xC6
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	pushm (xsp + 20)
	pushm (xsp + 8)
	lda xwa, (xsp + 46)
	ld bc, iz
	call DSP_WriteLUTParamSet
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_ParamEQ_Curve_FP
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	ld xwa, (xsp + 42)
	push xwa
	pushw iz
	ld xwa, (xsp + 40)
	push xwa
	lda xwa, (xsp + 24)
	push xwa
	pushm (xsp + 18)
	ld wa, (xsp + 36)
	ld bc, (xsp + 34)
	ld de, (xsp + 32)
	call DSP_SOS_Coeff_Compute
	ld (xsp + 42), xhl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_ParamInterp_2Point_B
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_VolScale_B
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch

DSP_Op_0x40_PanScale:
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_PanScale_Simple
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch

DSP_Op_0x24_MultiStepInterp:
	pushm (xsp + 18)
	pushm (xsp + 18)
	lda xwa, (xsp + 46)
	ld xbc, xde
	ld xde, (xsp + 38)
	call DSP_ParamInterp_MultiStep
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch

DSP_Op_0x21_Interp2Point:
	lda xwa, (xsp + 42)
	ld xbc, xde
	call DSP_ParamInterp_2Point
	pushm (xsp + 4)
	ld wa, iz
	ld xbc, xhl
	ld de, (xsp + 22)
	call DSP_WriteOscParam
	ld (xsp + 14), hl
	jrl DSP_Translator_PostDispatch

DSP_Op_Unknown_Error:
	ldw (xsp + 14), 0x5
	jrl DSP_Translator_Return

DSP_StreamDecode_3ByteWord:
	ld xde, xwa
	stb_dpi W, 0xE8
	ld a, (xwa)
	exts wa
	exts xwa
	sla xwa, 8
	sla xwa, 0
	and xwa, 0xFF000000
	ld xhl, xwa
	stb_dpi W, 0xE8
	ld a, (xwa)
	exts wa
	exts xwa
	ld xix, xwa
	sla xix, 0
	and xix, 0xFF0000
	stb_dpi W, 0xE8
	ld a, (xwa)
	exts wa
	exts xwa
	ld xiy, xwa
	sla xiy, 8
	and xiy, 0xFF00
	ld xwa, xhl
	add xwa, xix
	add xwa, xiy
	ld (xbc), xwa
	ld xhl, xde
	ret

DSP_TableWalk_Search:
	ld xhl, xwa
	jr DSP_TableWalk_ReadHeader

DSP_TableWalk_CheckEntry:
	ld ix, iy
	extz xix
	add xix, xhl
	inc 2, xhl
	ld a, (xhl)
	extz wa
	cp wa, bc
	jr nz, DSP_TableWalk_SkipEntry
	ld wa, de
	extz xwa
	inc 1, xwa
	add xhl, xwa
	cp xhl, xix
	jr c, DSP_TableWalk_FoundInRange
	lds bc, 4
	jr DSP_TableWalk_Return

DSP_TableWalk_FoundInRange:
	lds bc, 0
	jr DSP_TableWalk_Return

DSP_TableWalk_SkipEntry:
	ld xhl, xix

DSP_TableWalk_ReadHeader:
	ld a, (xhl + 1)
	ldb_erp A, 0xF0
	extz ix
	ld a, (xhl)
	extz wa
	ld iy, wa
	sll iy, 8
	add iy, ix
	ld wa, iy
	srl wa, 8
	cp wa, 0xF0
	jr nz, DSP_TableWalk_CheckEntry
	lds bc, 3

DSP_TableWalk_Return:
	ld xwa, (xsp + 4)
	ld (xwa), bc
	retd 0x4

DSP_TableWalk_SearchWithState:
	ld xhl, xde
	jr DSP_TableWalk_State_ReadHeader

DSP_TableWalk_State_CheckEntry:
	cps bc, 0
	jr nz, DSP_TableWalk_State_Advance
	lds ix, 0
	ld xde, (xsp + 4)
	ld bc, iy
	extz xbc
	add xbc, xwa
	ld (xde), xbc
	inc 2, xwa
	jr DSP_TableWalk_State_Return

DSP_TableWalk_State_Advance:
	ld de, iy
	extz xde
	add xwa, xde
	dec 1, bc

DSP_TableWalk_State_ReadHeader:
	ld e, (xwa + 1)
	ldb_erp E, 0xF0
	extz ix
	ld e, (xwa)
	extz de
	ld iy, de
	sll iy, 8
	add iy, ix
	ld de, iy
	srl de, 8
	cp de, 0xF0
	jr nz, DSP_TableWalk_State_CheckEntry
	lds ix, 2

DSP_TableWalk_State_Return:
	ld (xhl), ix
	ld xhl, xwa
	retd 0x4

DSP_NopReturn:
	ret


Audio_CmdHandler_A0_BF:
	ld xbc, (xsp + 6)
	ld a, (xbc)
	cps a, 1
	jr z, CmdA0BF_CheckSubByte
	cps a, 0
	jr nz, CmdA0BF_Return
	cp (xbc + 1), 0x1
	jr nz, CmdA0BF_Return
	stdi8 19018, 1
	jr CmdA0BF_Return

CmdA0BF_CheckSubByte:
	cp (xbc + 1), 0x9
	jr ugt, CmdA0BF_Return
	mrdb5 0x89, 0x01, 0x19, 0x48, 0x4A	; LD (4A48h), (XBC + 001h)

CmdA0BF_Return:
	lds hl, 0
	ret

; ----------------------------------------------------------------------------
; ToneGen_Init - Initialize tone generator subsystem
; Entry: None
; Exit:  Via JRL to ToneGen_Process
; Notes: Sets up tone generator state at 0x4A48 (mode = 6)
;        Tone generator is memory-mapped at 0x00110000
;        State buffer at 0x4A42-0x4A5C
; ----------------------------------------------------------------------------
ToneGen_Init:	; 03D016h
	stdi8 19016, 6	; Set tone gen mode to 6
	jrl ToneGen_Poll_Init	; Continue to main processing

; ----------------------------------------------------------------------------
; ToneGen_Process_Notes - Process incoming note events from tone generator
; Entry: Called from main tone gen handler
; Exit:  Note events dispatched to appropriate voice slots
; Notes: Reads notes via ToneGen_Read_Voice_Data, manages voice allocation
;        at 0x4A4C-0x4A5C (16 voice slots), sends to DMA at 0x4A42
; ----------------------------------------------------------------------------
ToneGen_Process_Notes:	; 03D01Eh
	dec 2, xsp	; Allocate 2 bytes for result
	lds wa, 0
	lda xwa, (xsp)
	calr ToneGen_Read_Voice_Data
	cp hl, 0xFFFF
	jrl z, ToneGen_Note_Done

ToneGen_Note_Loop:	; 03D02Eh
	cp (xsp + 1), 0x0	; Check velocity
	jr z, ToneGen_Note_Off_Slot
	ld a, (xsp + 256)	; Get note number
	extz wa
	lda_d16 xbc, 19020	; Voice slot table
	extz xwa
	add xwa, xbc
	ld (xwa), 0xFF	; Mark slot as note-on
	stdi8 19010, 144	; DMA command: note on
	ld a, (xsp + 256)
	stb_d8 19011, a	; Store note number
	ld a, (xsp + 1)
	stb_d8 19012, a	; Store velocity
	cpdi8 19018, 1	; Check if DMA enabled
	jr nz, ToneGen_Note_Continue
	ld xde, 0x4A42
	lds wa, 2
	lds bc, 3
	call InterCPU_DMA_Send	; Send via DMA
	jr ToneGen_Note_Continue

ToneGen_Note_Off_Slot:	; 03D06Dh
	ld a, (xsp + 256)
	extz wa
	lda_d16 xbc, 19020
	extz xwa
	add xwa, xbc
	cp (xwa), 0xFF	; Check if slot was active
	jr nz, ToneGen_Note_Continue
	ld a, (xsp + 256)
	extz wa
	lda_d16 xbc, 19020
	extz xwa
	add xwa, xbc
	ld (xwa), 0x0	; Clear slot
	stdi8 19010, 144	; DMA command: note off
	ld a, (xsp + 256)
	stb_d8 19011, a
	ld a, (xsp + 1)
	stb_d8 19012, a
	cpdi8 19018, 1
	jr nz, ToneGen_Note_Continue
	ld xde, 0x4A42
	lds wa, 2
	lds bc, 3
	call InterCPU_DMA_Send

ToneGen_Note_Continue:	; 03D0B6h
	lda xwa, (xsp)
	calr ToneGen_Read_Voice_Data
	cp hl, 0xFFFF
	jrl nz, ToneGen_Note_Loop

ToneGen_Note_Done:	; 03D0C2h
	inc 2, xsp
	ret

; ----------------------------------------------------------------------------
; ToneGen_Read_Voice_Data - Read voice data from tone generator
; Entry: XWA = pointer to 2-byte result buffer
; Exit:  HL = 0 (success) or 0xFFFF (not ready)
; Notes: P6.7 controls A23 address line to tone generator
;        Reads status from 0x110002, data from 0x110000
;        Extracts note (low byte) and velocity (high byte)
; ----------------------------------------------------------------------------
ToneGen_Read_Voice_Data:	; 03D0C5h
	push xiz
	ld xiz, xwa
	set_dd8 7, 0x18	; Assert A23 for status read
	nop
	ldw_da xbc, 0x110002                 ; Read status register
	bit 0, bc	; Check data ready bit
	jr z, ToneGen_Read_Not_Ready
	res_dd8 7, 0x18	; Deassert A23 for data read
	nop
	ldw_da xwa, 0x110000                 ; Read voice data (16-bit)
	ld l, a	; L = note byte (low)
	and l, 0xFF
	srl wa, 8
	ld e, a	; E = velocity byte (high)
	and e, 0xFF
	cp e, 0xFF	; Check for note-off
	jr z, ToneGen_Read_NoteOff
	bit 1, bc	; Check status bit 1
	jr z, ToneGen_Read_NoteOn

ToneGen_Read_NoteOff:	; 03D0F6h
	bit 7, l	; Check note high bit (release flag)
	jr z, ToneGen_Read_Release
	ldw hl, 0xFFFF	; Return not ready
	jr ToneGen_Read_Done

ToneGen_Read_Release:	; 03D100h
	ld c, l
	ld xwa, xiz
	calr ToneGen_Calc_Pitch
	ld (xiz + 1), 0x0	; Clear velocity for note-off
	lds hl, 0
	jr ToneGen_Read_Done

ToneGen_Read_NoteOn:	; 03D10Fh
	ld c, l
	ld xwa, xiz
	calr ToneGen_Calc_Pitch
	lds hl, 0
	jr ToneGen_Read_Done

ToneGen_Read_Not_Ready:	; 03D11Ah
	ldw hl, 0xFFFF

ToneGen_Read_Done:	; 03D11Dh
	pop xiz
	ret

; ----------------------------------------------------------------------------
; ToneGen_Calc_Pitch - Calculate pitch value for voice
; Entry: C = note number, XWA = result pointer
; Exit:  Pitch value stored at (XWA), velocity at (XWA+1)
; Notes: Uses lookup tables at 0x01F43E (note map), 0x01F420 (mode params)
;        Mode stored at 0x4A48, calculation uses MULS/DIVS
; ----------------------------------------------------------------------------
ToneGen_Calc_Pitch:	; 03D11Fh
	ld l, c
	res 7, l	; Clear release flag
	add l, 0x24	; Add pitch offset (36)
	ld (xwa), l	; Store base pitch
	bit 7, c	; Check if release (note-off)
	jrl z, ToneGen_Calc_NoVel
	ld c, e
	extz bc
	lda_24 xde, 0x01f43e
	ldb_sri C, 0x07, 0xE8, 0xE4
	extz bc
	extz xbc
	ld xde, xbc
	ldw_da xbc, 0x01f418
	ld hl, de
	sub hl, bc
	ldb_d8 c, 19016
	extz bc
	muls bc, 0x3
	lda_24 xde, 0x01f420
	ldb_sri C, 0x07, 0xE8, 0xE4
	extz bc
	muls xbc, xhl
	ldw_da xde, 0x01f41a
	exts xbc
	divs xbc, xde
	ld hl, bc
	ldb_d8 c, 19016
	extz bc
	muls bc, 0x3
	lda_24 xde, 0x01f421
	ldb_sri C, 0x07, 0xE8, 0xE4
	extz bc
	add bc, hl
	ld de, bc
	exts xde
	ld c, (xwa)
	extz bc
	div c, 0xC
	ld c, b
	cp c, 0xA
	jr z, ToneGen_Pitch_Adjust
	cp c, 0x8
	jr z, ToneGen_Pitch_Adjust
	cps c, 6
	jr z, ToneGen_Pitch_Adjust
	cps c, 3
	jr z, ToneGen_Pitch_Adjust
	cps c, 1
	jr nz, ToneGen_Pitch_Clamp

ToneGen_Pitch_Adjust:	; 03D1AAh - apply mode-specific pitch offset
	ldb_d8 c, 19016	; Get tone gen mode
	extz bc
	muls bc, 0x3	; mode * 3 for table index
	lda_24 xhl, 0x01f422                  ; Pitch offset table
	ldb_sri C, 0x07, 0xEC, 0xE4
	extz bc
	extz xbc
	sub xde, xbc	; Apply offset

ToneGen_Pitch_Clamp:	; 03D1C4h - clamp pitch to 0-255 range
	ld xbc, 0xFF
	cp xde, 0xFF
	jr gt, ToneGen_Pitch_ClampHi
	ld xbc, xde

ToneGen_Pitch_ClampHi:	; 03D1D3h
	ld xde, xbc
	lds32 xbc, 0
	cp xde, 0x0
	jr lt, ToneGen_Pitch_ClampLo
	ld xbc, xde

ToneGen_Pitch_ClampLo:	; 03D1E1h
	ld xde, xbc
	ld c, e
	extz bc
	lda_24 xde, 0x01f53e                  ; Velocity lookup table
	ldb_sri C, 0x07, 0xE8, 0xE4
	ld (xwa + 1), c	; Store velocity
	ret

ToneGen_Calc_NoVel:	; 03D1F5h - note-off, no velocity
	ld (xwa + 1), 0x0
	ret

ToneGen_Poll_Padding:	; 03D1FAh
	.byte 0x0e

; ----------------------------------------------------------------------------
; ToneGen_Poll_Init - Initialize and poll all tone generator voices
; Entry: Called from ToneGen_Init
; Exit:  Voice status updated in buffer at (0x01F41C)
; Notes: Clears 8 voice buffers, then polls 16 iterations
; ----------------------------------------------------------------------------
ToneGen_Poll_Init:	; 03D1FBh
	lds hl, 0
	cp hl, 0x8
	jr nc, ToneGen_Poll_All

ToneGen_Clear_Voice_Loop:	; 03D203h
	ld wa, hl
	extz xwa
	addda32_24 xwa, 128028	; Voice status buffer base
	ld (xwa), 0x0	; Clear voice status
	inc 1, hl
	cp hl, 0x8
	jr c, ToneGen_Clear_Voice_Loop

; ----------------------------------------------------------------------------
; ToneGen_Poll_All - Poll tone generator for all 16 channels
; Entry: None
; Exit:  Voice status bits updated
; Notes: Reads from 0x110000/0x110002, uses P6.7 for control
; ----------------------------------------------------------------------------
ToneGen_Poll_All:	; 03D217h
	lds hl, 0
	cp hl, 0x10	; 16 iterations (one per MIDI channel)
	ret nc

ToneGen_Poll_Channel:	; 03D21Fh
	lds wa, 0
	cp wa, 0x2710	; 10000 delay cycles
	jr nc, ToneGen_Poll_Read

ToneGen_Poll_Delay:	; 03D227h
	nop
	inc 1, wa
	cp wa, 0x2710
	jr c, ToneGen_Poll_Delay

ToneGen_Poll_Read:	; 03D230h
	set_dd8 7, 0x18	; A23 pin tied to D5VNAD (both pins "NAD" and "EXADL0" of of tone generator)
	nop
	ldw_da xwa, 0x110002
	res_dd8 7, 0x18
	nop
	ldw_da xwa, 0x110000
	ld c, a
	and c, 0xFF
	srl wa, 8
	and a, 0xFF
	ld a, c
	srl a, 3	; Extract voice index (bits 3-5)
	and a, 0x7
	ld e, a
	ld a, c
	and a, 0x7	; Extract bit position (bits 0-2)
	ld w, a
	bit 7, c	; Check note-on flag
	jr z, ToneGen_Poll_NoteOff
	ld a, e	; Note ON - set voice bit
	ldb_erp A, 0xF0
	extz ix
	ldl_da xbc, 0x01f41c                 ; Voice status buffer
	lds de, 1
	ld a, w
	and a, 0xF
	jr z, ToneGen_Poll_SetBit
	slaa de	; Create bit mask

ToneGen_Poll_SetBit:	; 03D27Ah
	or_srib_mr E, 0x07, 0xE4, 0xF0	; Set voice active bit
	jr ToneGen_Poll_Next

ToneGen_Poll_NoteOff:	; 03D281h - Note OFF - clear voice bit
	ld a, e
	ldb_erp A, 0xF0
	extz ix
	ldl_da xbc, 0x01f41c
	lds de, 1
	ld a, w
	and a, 0xF
	jr z, ToneGen_Poll_ClearBit
	slaa de

ToneGen_Poll_ClearBit:	; 03D298h
	ld wa, de
	cpl wa	; Invert mask
	and_srib_mr A, 0x07, 0xE4, 0xF0	; Clear voice bit

ToneGen_Poll_Next:	; 03D2A1h
	inc 1, hl
	cp hl, 0x10
	jrl c, ToneGen_Poll_Channel
	ret

ToneGen_Voice_Padding:	; 03D2ABh
	.byte 0xff

; ----------------------------------------------------------------------------
; ToneGen_Compare_Voice - Compare two voice parameter blocks
; Entry: XWA = voice 1 pointer, XBC = voice 2 pointer, DE = comparison type
; Exit:  HL = comparison result (0 = different, 1 = same, or lookup value)
; Notes: Compares 8-byte voice blocks at XWA and XBC
;        Uses lookup table at 0x03D978 for result mapping
; ----------------------------------------------------------------------------
ToneGen_Compare_Voice:	; 03D2ACh
	ld xix, (xwa + 4)	; Compare high 4 bytes
	cp xix, (xbc + 4)
	jr nz, ToneGen_Compare_Diff
	ld xiy, (xwa)	; Compare low 4 bytes
	cp xiy, (xbc)
	jr nz, ToneGen_Compare_Result
	lda_24 xix, 0x03d978                  ; Exact match - lookup result
	ldb_sri L, 0x07, 0xF0, 0xE8
	ldb h, 0x0
	ret

ToneGen_Compare_Diff:	; 03D2C7h
	ld xiy, (xwa)

ToneGen_Compare_Result:	; 03D2C9h
	lds hl, 0
	cps de, 4
	ret z
	lds hl, 1
	cps de, 5
	ret z
	ld xwa, (xbc + 4)
	lds hl, 0
	ldcf_erpw 0xF2, 0x0F
	jr nc, ToneGen_Compare_Sign
	xorcf_erpw 0xE2, 0x0F
	scc16 nc, hl

ToneGen_Compare_Sign:	; 03D2E6h
	cp xix, xwa
	jr gt, ToneGen_Cmp_Greater
	jr lt, ToneGen_Cmp_Less
	cp xiy, (xbc)
	jr ugt, ToneGen_Cmp_Greater

ToneGen_Cmp_Less:	; 03D2F0h - voice 1 < voice 2
	lda_24 xix, 0x03d97e                  ; Less-than lookup table
	xor_srib_rm L, 0x07, 0xF0, 0xE8
	ret

ToneGen_Cmp_Greater:	; 03D2FBh - voice 1 > voice 2
	lda_24 xix, 0x03d984                  ; Greater-than lookup table
	xor_srib_rm L, 0x07, 0xF0, 0xE8
	ret

; ----------------------------------------------------------------------------
; ToneGen_Compare_Voice_32 - Compare two 32-bit voice parameters
; Entry: XWA = voice 1 pointer, XBC = voice 2 pointer, DE = comparison type
; Exit:  HL = comparison result
; Notes: Simplified version comparing only first 4 bytes
; ----------------------------------------------------------------------------
ToneGen_Compare_Voice_32:	; 03D306h
	lds hl, 0
	ld xwa, (xwa)	; Load 32-bit value from voice 1
	ld xbc, (xbc)	; Load 32-bit value from voice 2
	cp xwa, xbc
	jr nz, ToneGen_Cmp32_NotEqual
	lda_24 xix, 0x03d978                  ; Equal - lookup result
	ldb_sri L, 0x07, 0xF0, 0xE8
	ret

ToneGen_Cmp32_NotEqual:	; 03D31Bh
	cps de, 4
	ret z
	lds hl, 1
	cps de, 5
	ret z
	lds hl, 0
	ldcf_erpw 0xE2, 0x0F	; Load carry from sign bit
	jr nc, ToneGen_Cmp32_Sign
	xorcf_erpw 0xE6, 0x0F
	scc16 nc, hl

ToneGen_Cmp32_Sign:	; 03D333h
	cp xwa, xbc
	jr gt, ToneGen_Cmp32_Greater
	lda_24 xix, 0x03d97e
	xor_srib_rm L, 0x07, 0xF0, 0xE8
	ret

ToneGen_Cmp32_Greater:	; 03D342h
	lda_24 xix, 0x03d984
	xor_srib_rm L, 0x07, 0xF0, 0xE8
	ret

VoiceFloat_DispatchMulAdd:
	lda xsp, (xsp - 48)
	pushw 0x0
	lda xiy, (xsp + 58)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 34)
	push xwa
	call FP_DP_CmpAndCopy
	lda xsp, (xsp + 12)
	lda_24 xbc, 0x00f3ca
	lda xde, (xsp + 26)
	lda xwa, (xsp + 34)
	call FP_DP_Mul
	lda xiy, (xsp + 34)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xiy, (xsp + 66)
	ld xix, (xiy + 4)
	push xix
	ld xix, (xiy)
	push xix
	lda xwa, (xsp + 58)
	push xwa
	call VoiceFloat_BlendAndMerge
	lda xsp, (xsp + 22)
	ld xwa, (xsp + 52)
	lda xbc, (xsp + 40)
	call FP_DP_Raw8Copy
	lda xsp, (xsp + 48)
	ret

VoiceFloat_SubDP:
	push xiz
	lda xsp, (xsp - 28)
	ld xiz, xde
	ld (xsp + 24), xwa
	ld xwa, xsp
	call FP_DP_Decode
	ld xbc, xiz
	lda xiz, (xsp + 12)
	lda xwa, (xiz)
	call FP_DP_Decode
	ld xwa, xsp
	lda xbc, (xiz)
	call FP_DP_Mul_Outer
	ld xwa, (xsp + 24)
	ld xbc, xsp
	call FP_DP_Encode
	lda xsp, (xsp + 28)
	pop xiz
	ret

VoiceFloat_SubSP:
	push xiz
	lda xsp, (xsp - 20)
	ld xiz, xde
	ld (xsp + 16), xwa
	ld xwa, xsp
	call FP_SP_Decode
	ld xbc, xiz
	lda xiz, (xsp + 8)
	lda xwa, (xiz)
	call FP_SP_Decode
	ld xwa, xsp
	lda xbc, (xiz)
	call FP_SP_Mul_Outer
	ld xwa, (xsp + 16)
	ld xbc, xsp
	call FP_SP_Encode
	lda xsp, (xsp + 20)
	pop xiz
	ret


; --- Floating-Point Math Library ---
	.include "subcpu_fp_math.s"
