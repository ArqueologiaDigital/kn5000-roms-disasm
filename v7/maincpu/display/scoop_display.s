; =============================================================================
; Scoop Display & Performance Parameters (10K lines)
; =============================================================================
;
; Display dirty-region tracking, performance mode parameter
; handlers, and the Scoop (oscilloscope) editor UI. Manages
; the real-time display update system for the 320x240 LCD.
; =============================================================================

	; === ROM-specific ending: initialize video buffers ===
	call Fill_memory_at_XWA_with_DE_words_of_BC_value
	lda_24 xwa, (0x1a0000)
	ld xbc, 0x43c00
	ldw de, 0x9600
	call Copy_DE_words_from_XBC_to_XWA	; Blit video buffer

	RET_VGA_SEQUENCER 0x1, 0x1	; Clocking Mode (screen on)


;=============================================================================
; Display_ResetDirtyFlags - Reset all display dirty flags
;
; Clears both the enable flag (0x205e6) and dirty bitmap (0x205e4) to zero.
; Call this to initialize display state or force a full refresh.
;=============================================================================
Display_ResetDirtyFlags:
	stiw_da (0x0205e6), 0x0000
	stiw_da (0x0205e4), 0x0000
	ret

;=============================================================================
; Display_UpdateDirtyRegions - Update all dirty display regions
;
; Sets enable flag and checks each dirty bit. For each dirty region,
; calls the corresponding update routine. Used during main loop to
; refresh only changed portions of the display.
;
; Uses:
;   0x205e4 - DISPLAY_DIRTY_FLAGS: Bitmap of dirty regions
;   0x205e6 - DISPLAY_ENABLE_FLAG: Update enable flag
;=============================================================================
Display_UpdateDirtyRegions:
	stib_da (0x0205e6), 0x01
	cpw_da (0x0205e4), 0
	jr z, Display_MarkClean
	call Display_UpdateRegion0	; Status bar area
	call Display_UpdateRegion5	; Menu area
	call Display_UpdateRegion7	; Parameter display
	call Display_UpdateRegion8	; Value display
	call Display_UpdateRegion9	; Indicator area
	call Display_UpdateRegion1	; Title bar
	call Display_UpdateRegion10	; Footer area
	call Display_UpdateRegion6	; Button labels
	call Display_UpdateRegion3	; Main content area
	call Display_UpdateRegion4	; Side panel
	call Display_UpdateRegion2	; Selection highlight

Display_MarkClean:
	stiw_da (0x0205e4), 0xffff
	ret

; Undisassembled data block (18 bytes) - possibly lookup table
Display_Data_ScoopInit:
	ldb	a, 255
	stb_da	(0x0205ea), a
	stb_da	(0x0205e8), a
	stb_da	(0x0205ec), a
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion0 - Update status bar region (bit 0)
;
; Checks if status bar needs refresh by comparing cached values.
; If changed, calls the status bar redraw routine.
;-----------------------------------------------------------------------------
Display_UpdateRegion0:
	bitda_24 0, (0x0205e6)
	jr nz, Display_UpdateRegion0_Check
	setda_24 0, (0x0205e4)
	ret

Display_UpdateRegion0_Check:
	bitda_24 0, (0x0205e4)
	jr z, Display_UpdateRegion0_Done
	pushw wa
	ldb_d8 a, (3429)
	cpda8_24 a, (0x0205ea)
	jr nz, Display_UpdateRegion0_Changed
	ldb_d8 a, (3567)
	cpda8_24 a, (0x0205e8)
	jr nz, Display_UpdateRegion0_Changed
	ldb_d8 a, (3424)
	cpda8_24 a, (0x0205ec)
	jr z, Display_UpdateRegion0_NoChange

Display_UpdateRegion0_Changed:
	bitda 0, (3927)
	jrl nz, Display_UpdateRegion0_NoChange
	call Display_RedrawStatusBar
	ldb_d8 a, (3429)
	stb_da (0x0205ea), a
	ldb_d8 a, (3567)
	stb_da (0x0205e8), a
	ldb_d8 a, (3424)
	stb_da (0x0205ec), a

Display_UpdateRegion0_NoChange:
	popw wa

Display_UpdateRegion0_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion1 - Update title bar region (bit 1)
;-----------------------------------------------------------------------------
Display_UpdateRegion1:
	bitda_24 0, (0x0205e6)
	jr nz, Display_UpdateRegion1_Check
	setda_24 1, (0x0205e4)
	ret

Display_UpdateRegion1_Check:
	bitda_24 1, (0x0205e4)
	jr z, Display_UpdateRegion1_Done
	call Display_RedrawTitleBar

Display_UpdateRegion1_Done:
	ret

Display_UpdateRegion1_Alt:
	call Display_RedrawAltContent
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion3 - Update main content area (bit 3)
;-----------------------------------------------------------------------------
Display_UpdateRegion3:
	bitda_24 0, (0x0205e6)
	jr nz, Display_UpdateRegion3_Check
	setda_24 3, (0x0205e4)
	ret

Display_UpdateRegion3_Check:
	bitda_24 3, (0x0205e4)
	jr z, Display_UpdateRegion3_Done
	call Display_RedrawMainContent

Display_UpdateRegion3_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion2 - Update selection highlight (bit 4)
;-----------------------------------------------------------------------------
Display_UpdateRegion2:
	bitda_24 0, (0x0205e6)
	jr nz, Display_UpdateRegion2_Check
	setda_24 4, (0x0205e4)
	ret

Display_UpdateRegion2_Check:
	bitda_24 4, (0x0205e4)
	jr z, Display_UpdateRegion2_Done
	call Display_RedrawSelection

Display_UpdateRegion2_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion4 - Update side panel (bit 5)
;-----------------------------------------------------------------------------
Display_UpdateRegion4:
	bitda_24 0, (0x0205e6)
	jr nz, Display_UpdateRegion4_Check
	setda_24 5, (0x0205e4)
	ret

Display_UpdateRegion4_Check:
	bitda_24 5, (0x0205e4)
	jr z, Display_UpdateRegion4_Done
	call Display_RedrawSidePanel

Display_UpdateRegion4_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion5 - Update menu area (bit 6)
;-----------------------------------------------------------------------------
Display_UpdateRegion5:
	bitda_24 0, (0x0205e6)
	jr nz, Display_UpdateRegion5_Check
	setda_24 6, (0x0205e4)
	ret

Display_UpdateRegion5_Check:
	bitda_24 6, (0x0205e4)
	jr z, Display_UpdateRegion5_Done
	call Display_RedrawMenu

Display_UpdateRegion5_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion6 - Update button labels (bit 7)
;-----------------------------------------------------------------------------
Display_UpdateRegion6:
	bitda_24 0, (0x0205e6)
	jr nz, Display_UpdateRegion6_Check
	setda_24 7, (0x0205e4)
	ret

Display_UpdateRegion6_Check:
	bitda_24 7, (0x0205e4)
	jr z, Display_UpdateRegion6_Done
	call Display_RedrawButtonLabels

Display_UpdateRegion6_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion7 - Update parameter display (bit 0 of 0x205e5)
;-----------------------------------------------------------------------------
Display_UpdateRegion7:
	bitda_24 0, (0x0205e6)
	jr nz, Display_UpdateRegion7_Check
	setda_24 0, (0x0205e5)
	ret

Display_UpdateRegion7_Check:
	bitda_24 0, (0x0205e5)
	jr z, Display_UpdateRegion7_Done
	call Display_RedrawParameters

Display_UpdateRegion7_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion8 - Update value display (bit 1 of 0x205e5)
;-----------------------------------------------------------------------------
Display_UpdateRegion8:
	bitda_24 0, (0x0205e6)
	jr nz, Display_UpdateRegion8_Check
	setda_24 1, (0x0205e5)
	ret

Display_UpdateRegion8_Check:
	bitda_24 1, (0x0205e5)
	jr z, Display_UpdateRegion8_Done
	call Display_RedrawValues

Display_UpdateRegion8_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion9 - Update indicator area (bit 2 of 0x205e5)
;-----------------------------------------------------------------------------
Display_UpdateRegion9:
	bitda_24 0, (0x0205e6)
	jr nz, Display_UpdateRegion9_Check
	setda_24 2, (0x0205e5)
	ret

Display_UpdateRegion9_Check:
	bitda_24 2, (0x0205e5)
	jr z, Display_UpdateRegion9_Done
	call Display_RedrawIndicators

Display_UpdateRegion9_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion10 - Update footer area (bit 3 of 0x205e5)
;-----------------------------------------------------------------------------
Display_UpdateRegion10:
	bitda_24 0, (0x0205e6)
	jr nz, Display_UpdateRegion10_Check
	setda_24 3, (0x0205e5)
	ret

Display_UpdateRegion10_Check:
	bitda_24 3, (0x0205e5)
	jr z, Display_UpdateRegion10_Done
	call Display_RedrawFooter

Display_UpdateRegion10_Done:
	ret

UIRender_SingleTable:
	bitda_24 0, (0x0205e6)
	jr nz, UIRender_SingleTable_Body
	ret

UIRender_SingleTable_Body:
	ld xwa, xiy
	ld xbc, xix
	call GraphicsRender_ProcessEntries
	ret

; Render UI element from two ROM descriptor tables (general renderer)
; Input: XIY = descriptor table 1, XIX = descriptor table 2
UIRender_TwoTableGeneral:
	bitda_24 0, (0x0205e6)
	jr nz, UIRender_TwoTableGeneral_Body
	ret

UIRender_TwoTableGeneral_Body:
	ld xwa, xiy
	ld xbc, xix
	call Scoop_EventLoop_12Entry		; General UI element renderer
	ret

; Render UI element from two ROM descriptor tables (paired renderer)
; Input: XIY = descriptor table 1, XIX = descriptor table 2

; -----------------------------------------------------------------------------
; Section: Graphics Rendering
; -----------------------------------------------------------------------------
; Two-table rendering, conditional updates, event
; checking, and curve/glide setup.
; -----------------------------------------------------------------------------

GraphicsRender_TwoTable:
	bitda_24 0, (0x0205e6)
	jr nz, GraphicsRender_TwoTable_Body
	ret

GraphicsRender_TwoTable_Body:
	push xwa
	push xbc
	ld xwa, xiy
	ld xbc, xix
	call GraphicsRender_Start		; Two-descriptor pair renderer
	pop xbc
	pop xwa
	ret

GraphicsRender_TwoTable_Alt:
	bitda_24 0, (0x0205e6)
	jr nz, GraphicsRender_TwoTable_Alt_Body
	ret

GraphicsRender_TwoTable_Alt_Body:
	push xwa
	push xbc
	ld xwa, xiy
	ld xbc, xix
	call Scoop_EventLoop_12Entry_Alt
	pop xbc
	pop xwa
	ret

UIRender_TwoTableEvtCheck:
	bitda_24 0, (0x0205e6)
	jr nz, UIRender_TwoTableEvtCheck_Body
	ret

UIRender_TwoTableEvtCheck_Body:
	push xwa
	ld xwa, xiy
	call ColorBlit_WithPaletteSave
	pop xwa
	ret

UIRender_ConditionalDrawInit:
	bitda_24 0, (0x0205e6)
	jr nz, UIRender_ConditionalDrawInit_Body
	ret

UIRender_ConditionalDrawInit_Body:
	push xwa
	ld xwa, xiy
	call DrawFunc_Init
	pop xwa
	ret

Scoop_ConditionalCurveUpdate:
	bitda_24 0, (0x0205e6)
	jr nz, Scoop_ConditionalCurveUpdate_Body
	ret

Scoop_ConditionalCurveUpdate_Body:
	push xwa
	ld xwa, xiy
	call Scoop_CurveUpdate_SegmentEnd
	pop xwa
	ret

Scoop_CurveUpdate_Direct:
	push xwa
	ld xwa, xiy
	call Scoop_CurveUpdate_SegmentEnd
	pop xwa
	ret

Scoop_ConditionalGlideSetup:
	bitda_24 0, (0x0205e6)
	jr nz, Scoop_ConditionalGlideSetup_Body
	ret

Scoop_ConditionalGlideSetup_Body:
	push xwa
	ld xwa, xiy
	call Scoop_GlideParam_Setup
	pop xwa
	ret

UIRender_ConditionalFBCall:
	bitda_24 0, (0x0205e6)
	jr nz, UIRender_ConditionalFBCall_Body
	ret

UIRender_ConditionalFBCall_Body:
	push xwa
	ld xwa, xiy
	call ColorBlit_ComputeRectAndBlit
	pop xwa
	ret

GraphicsRender_EventCheck:
	bitda_24 0, (0x0205e6)
	jr nz, GraphicsRender_EventCheck_Body
	ret

GraphicsRender_EventCheck_Body:
	push xwa
	ld xwa, xiy
	call Scoop_EventLoop_36Entry
	pop xwa
	ret

UIRender_LoadTwoDescriptors:
	ld xiy, UIRender_DescriptorTable1
	ld xix, UIRender_DescriptorTable2
	ld xwa, xiy
	ld xbc, xix
	call Scoop_EventLoop_12Entry
	ret

UIRender_DescriptorTable1:
	ret
	ldio	18, 6
	di
	zcf
	nop
	ret
	ldio	82, 12
	di
	zcf
	nop
	ret
	ldio	146, 18
	di
	zcf
	nop
	jp	0x010b0a
	.byte 0x9e
	nop
	ldw	iy, 0xb101
	nop
	reti
	halt
	jrl	c, 8217
	ldb	w, 41
	pop_f
	.byte 0x1f
	.ascii "                                      "
	push	26
	.byte 0x17
	.ascii "     "
	ret
	ldio	213, 32
	halt
	nop
	.byte 0xec
	nop
	ret
	ldio	218, 32
	halt
	nop
	.byte 0xec
	nop
	ret
	ldio	223, 32
	halt
	nop
	.byte 0xec
	nop
	ret
	ldio	228, 32
	halt
	nop
	.byte 0xec
	nop
	ret
	ldio	233, 32
	halt
	nop
	.byte 0xec
	nop

UIRender_DescriptorTable2:
	calr	74
	.byte 0xf1, 0x85
	scf
	dec	6, a
	jp	0x1182d1
	ldb	w, 241
	.byte 0x81
	scf
	.byte 0x50
	stdi8	(4483), 32
	.byte 0xf1, 0x85
	scf
	dec	6, w
	ldio	209, 130
	scf
	ldb	w, 241
	.byte 0x81
	scf
	.byte 0x50
	ret

ParamDigit_ExtractAndFormat:
	calr ParamDigit_DivideValue
	bitda 1, (4485)
	jr nz, ParamDigit_ExtractDone
	stdi8 (4481), 32
	bitda 0, (4485)
	jr nz, ParamDigit_ExtractDone
	stdi8 (4482), 32

ParamDigit_ExtractDone:
	ret

ParamDigit_CalrData:
	calr	117
	calr	65504
	ret
	calr	110
	calr	65460
	ret

ParamDigit_DivideValue:
	push c
	anddi8 (4485), 252
	stdi8 (4481), 0
	stdi16 (4482), 0
	cps wa, 0
	jr z, ParamUpdate_AddAndStore
	xor c, c

ParamDigit_Div100Loop:
	sub wa, 0x64
	jr c, ParamDigit_Div100Done
	inc 1, c
	ordi8 4485, 2
	cps wa, 0
	jr nz, ParamDigit_Div100Loop
	stb_d8 (4481), c
	jr ParamUpdate_AddAndStore

ParamDigit_Div100Done:
	stb_d8 (4481), c
	add wa, 0x64
	xor c, c

ParamDigit_Div10Loop:
	sub wa, 0xa
	jr c, ParamDigit_Div10Done
	inc 1, c
	ordi8 4485, 1
	cps wa, 0
	jr nz, ParamDigit_Div10Loop
	stb_d8 (4482), c
	jr ParamUpdate_AddAndStore

ParamDigit_Div10Done:
	stb_d8 (4482), c
	add wa, 0xa
	stb_d8 (4483), a


; -----------------------------------------------------------------------------
; Section: Parameter Update Routines
; -----------------------------------------------------------------------------
; Parameter add/store, zero-check, and conditional
; update helpers.
; -----------------------------------------------------------------------------

ParamUpdate_AddAndStore:
	adddi8 4481, 48
	adddi16 4482, 0x3030
	pop c
	ret

ScoopDisp_BytecodeBlock1:
	cps	de, 0
	jr	z, 14
	jr	gt, 10
	xor	de, 0xffff
	inc	1, de
	add	wa, de
	jr	2
	sub	wa, de
	cps	wa, 0
	jr	z, 22
	jr	gt, 13
	xor	wa, 0xffff
	inc	1, wa
	stdi8	(4480), 45
	jr	12
	stdi8	(4480), 43
	jr	5
	.byte 0xf1
	ldir
	nop
	ldb	w, 0x0e
	.ascii "9:;<=>…ã “»â»–"
	call	Scoop_CurveUpdate_DrawSegment_0x20
	ld	a, l
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	ret
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	ld	c, a
	xor	b, b
	ld	a, w
	xor	w, w
	call	Scoop_CurveUpdate_NextSegment
	ld	a, l
	.ascii "^]\\[ZY"
	ret

ChannelFilter_InitAndApply:
	call ChannelFilter_SetMode
	call ChannelFilter_ApplyWrapper
	stdi16 (4360), 0
	ret

ChannelFilter_SetMode:
	stdi8 (3294), 2
	ret

ChannelFilter_ApplyWrapper:
	calr ChannelFilter_ApplyMask
	ret

ChannelFilter_ApplyMask:
	ldw_d16 xde, (0xf19e)
	push	sr
	cpl de
	pop	sr
	ld xhl, 0xf1a0
	xor bc, bc

ChannelFilter_BitScanLoop:
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld a, c
	scf
	xorcfw_erp 0x3e
	stb_erp A, 0x3c
	jr c, ChannelFilter_NextBit
	ld iy, bc
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0xd
	jr z, ChannelFilter_ClearBit
	cp a, 0x10
	jr nz, ChannelFilter_NextBit

ChannelFilter_ClearBit:
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld a, c
	rcf
	stcfw_erp 0x3e
	stb_erp A, 0x3c
	stw_erp DE, 0x3e

ChannelFilter_NextBit:
	inc 1, c
	cp c, 0x10
	jr c, ChannelFilter_BitScanLoop
	ldw_d16 xwa, (0xf19e)
	ret

Display_LoadAndSetIndicator:
	call Display_LoadChannelMask
	xor wa, wa
	ldb a, 0x4c
	call CtrlPanel_SetIndicatorBit
	ret

Display_LoadChannelMask:
	ldw_d16 xwa, (0xf19e)
	calr Display_LoadChannelMask_Ret
	call Display_CopyToneTableToRAM
	ret

Display_LoadChannelMask_Ret:
	ret

Display_CopyToneTableToRAM:
	push xhl
	push xbc
	push xix
	push xiy
	ld xix, 0xab000
	xor xhl, xhl
	ldb_da l, (0x00ffe3)
	sla xhl, 11
	add xix, xhl
	ld xiy, 0xf180
	ldw bc, 0x800
	ldir85
	pop xiy
	pop xix
	pop xbc
	pop xhl
	ret

Display_InitScreenLayout:
	; --- Init/setup function (29 bytes) ---
	call Display_Data_ScoopInit
	call Display_ResetDirtyFlags
	calr Display_InitParamLoader1
	call Display_CallMenuInit
	calr Display_InitParamLoader2
	call Display_UpdateDirtyRegions
	stdi16	(4360), 0
	ret
Display_InitParamLoader1:
	; --- Param loader 1: C=0, A=0x0c, A=0x10, call FB1536 ---
	ldb c, 0x00
	ldb a, 0x0c
	ldb a, 0x10
	call Display_DeferOrDrawWall
	stib_da	(0x03efa8), 0
	ret
Display_InitParamLoader2:
	; --- Param loader 2: C=7, A=0x0c, call FB155F ---
	ldb c, 0x07
	ldb a, 0x0c
	call Display_DeferOrUpdateScreen
	ret
Display_CallMenuInit:
	; --- Simple wrapper: call EFA133 ---
	call ScoopParam_ValueTable_0x186
	ret
Display_ConditionalCompare:
	.incbin "includes/generated/v7_transplant_Display_ConditionalCompare.bin"
Display_ConditionalCompare_Ret:
	ret
Display_CallMenuConfig:
	; --- Simple wrapper: call EFA8CE ---
	call ClockConfig_Handler_0_0x110
	ret
Display_PollAudioAndUpdate:
	; --- Polling function with loop ---
	ld bc, hl
	pushw bc
	call Display_ResetDirtyFlags
	popw bc
	call Display_CallSetupRoutine
	call Display_UpdateDirtyRegions
Display_PollAudioLoop:
	ldb a, 0x01
	call AudioLock_GetCount
	cps	l, 0
	jr z, Display_PollAudioDone
	ldb a, 0x03
	call TaskSched_YieldToQueue
	jr t, Display_PollAudioLoop
Display_PollAudioDone:
	call Display_DeletePollEvent
	ret
Display_DeletePollEvent:
	; --- XBC/XWA setup and call ---
	ld xbc, 0x01c00007
	lds32	xwa, 0
	call DeleteEvent
	ret
Display_CallSetupRoutine:
	; --- Simple wrapper: call EF61E9 ---
	call DefaultHandler_Ret_0x1
	ret
Display_NullHandler:
	ret


MIDI_SendSysExFromW:
	.incbin "includes/generated/v7_transplant_MIDI_SendSysExFromW.bin"
SoundEvt_ShortPacketHandler:
	.incbin "includes/generated/v7_transplant_SoundEvt_ShortPacketHandler.bin"
SoundEvt_LongPacketHandler:
	.incbin "includes/generated/v7_transplant_SoundEvt_LongPacketHandler.bin"
ScoopDisp_HandlerData2:
	.incbin "includes/generated/v7_transplant_ScoopDisp_HandlerData2.bin"
DefaultHandler_Ret:
	.incbin "includes/generated/v7_transplant_DefaultHandler_Ret.bin"
ScoopDisp_FlagSetAndDispatch:
	.incbin "includes/generated/v7_transplant_ScoopDisp_FlagSetAndDispatch.bin"
ScoopDisp_DispatchTable_Small:
	.incbin "includes/generated/v7_transplant_ScoopDisp_DispatchTable_Small.bin"
ToneParam_Evt0F_BytecodeHandler:
	bit	7, w
	jrl	nz, 17
	.byte 0xc1
	jr	gt, 38
	push	xix
	swi	6
	xor	wa, wa
	ldb	a, 137
	call	UI_PostModeChangeEvent
	jp	ToneParam_Evt0F_BytecodeHandler_0x17
	ret
	.byte 0xc1, 0xd3
	decf
	push	xix
	swi	6
	ldb_d8	e, (3567)
	xor	d, d
	sla	de, 2
	ld	iy, de
	push	xhl
	ld	xhl, PerfMode_ParamHandler_Table
	.byte 0xe3
	reti
	cp	xix, xix
	ldb	e, 91
	call	(xiy)
	.byte 0xc1, 0xd3
	decf
	push	xiz
	.byte 0x01
	ldw_d16	bc, (9920)
	cp	bc, 15
	jrl	z, 79
	cps	bc, 0
	jrl	z, 5
	.byte 0xc1, 0x57
	retd	0xfe3c
	.byte 0xf1, 0x57
	retd	0x7ec8
	ldw	bc, 0xc100
	.byte 0xef
	decf
	ldb	a, 201
	scc16	nz, wa
	halt
	nop
	cps	bc, 6
	jrl	ule, 35
	cps	a, 3
	jrl	nz, 5
	cps	bc, 4
	jrl	z, 25
	cps	a, 7
	jrl	nz, 5
	cps	bc, 3
	jrl	z, 15
	cp	a, 9
	jrl	nz, 14
	cps	bc, 4
	jrl	z, 4
	jp	ToneParam_Evt0F_BytecodeHandler_0x8D
	.byte 0xc1, 0xd3
	decf
	push	xix
	swi	6
	call	VoiceSlot_TableSetup
	call	Timer_ModeHandler_0_0x13
	ret

; -----------------------------------------------------------------------------
; Section: Performance Mode Parameter Handlers
; -----------------------------------------------------------------------------
; Parameter handler dispatch table and individual
; handlers for each performance mode parameter.
; -----------------------------------------------------------------------------

PerfMode_ParamHandler_Table:
	.incbin "includes/generated/v7_transplant_PerfMode_ParamHandler_Table.bin"
PerfMode_JumpTable_Extended:
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long UIState_PerfModeEntry
	.long PerfMode_BytecodeEntry_A
	.long PerfMode_BytecodeEntry_A
	.long UIState_PerfModeEntry
	.long PerfMode_BytecodeBody_A
	.long PerfMode_BytecodeEntry_B
	.long PerfMode_BytecodeEntry_C
PerfMode_ParamHandler_0:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, 17
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_0
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	call	(xhl)
	ret
PerfMode_EventTable_0:
	.long UIDisp_DefaultInputHandler
	.long PerfMode_Evt01_Handler
	.long PerfMode_Evt02_Handler
	.long PerfMode_Evt03_FlagHandler_A
	.long PerfMode_Evt03_FlagHandler_B
	.long PerfMode_Evt03_ClampAndUpdate
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long PerfMode_VolumeParam_Process
	.long ToneParam_Evt09_BytecodeHandler
	.long SubCPU_ToneParamDisplay
	.long ToneParam_ModeGuardEntry
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIDisp_DefaultInputHandler
	.long PerfMode_Evt01_Handler
	.long PerfMode_Evt02_Handler
	.long PerfMode_Evt03_FlagHandler_A
	.long PerfMode_Evt03_FlagHandler_B
	.long PerfMode_Evt03_ClampAndUpdate
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
PerfMode_Evt03_FlagHandler_A:
	.incbin "includes/generated/v7_transplant_PerfMode_Evt03_FlagHandler_A.bin"
PerfMode_Evt03_FlagHandler_B:
	.incbin "includes/generated/v7_transplant_PerfMode_Evt03_FlagHandler_B.bin"
PerfMode_Evt03_ClampAndUpdate:
	.incbin "includes/generated/v7_transplant_PerfMode_Evt03_ClampAndUpdate.bin"
PerfMode_ClampValue:
	; --- Clamp/adjust: inc or dec A within [L..H] (29 bytes) ---
	bit 0x07, w
	jrl nz, PerfMode_ClampValue_Dec
	inc 1, a
	cp a, h
	jrl ule, CompareClamp_ValueReturn
	ld a, h
	jp CompareClamp_ValueReturn
PerfMode_ClampValue_Dec:
	dec 1, a
	cp a, l
	jrl ge, CompareClamp_ValueReturn
	ld a, l
CompareClamp_ValueReturn:
	ret


PerfMode_ParamHandler_1:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, 17
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_1
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	call	(xhl)
	ret
UIDisp_DefaultInputHandler:
	lds	bc, 1
	.ascii "8;9:<=>"
	call	UIDisp_DefaultInputHandler_0x20
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	djnz16	bc, -21
	call	Display_UpdateRegion5
	call	Display_UpdateRegion3
	ret
	.byte 0xc1, 0x57
	retd	318
	stdi8	(3923), 1
	stb_d8	(3385), w
	bit	7, w
	jrl	z, 8
	call	ToneParam_HandlerTable_BC_0x532
	jp	UIDisp_DefaultInputHandler_0x40
	call	ToneParam_HandlerTable_BC_0x4F5
	ret


PerfMode_EventTable_1:
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long PerfMode_VolumeParam_Process
	.long ToneParam_Evt09_BytecodeHandler
	.long SubCPU_ToneParamDisplay
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
PerfMode_ParamHandler_2:
	.incbin "includes/generated/v7_transplant_PerfMode_ParamHandler_2.bin"
PerfMode_EventTable_2:
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long PerfMode_VolumeParam_Process
	.long DefaultHandler_Ret
	.long PeriphReg_CheckAndDispatch
	.long ToneEvt_Handler_ModeSingle
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
PerfMode_ParamHandler_3:
	.incbin "includes/generated/v7_transplant_PerfMode_ParamHandler_3.bin"
PerfMode_ParamHandler_3_Entry:
	bit	7, w
	jrl	nz, 8
	call	DisplayMode_Handler_3_0x55E
	jp	PerfMode_ParamHandler_3_Entry_0x12
	call	DisplayMode_Handler_3_0x5AF
	ret
PerfMode_EventTable_3:
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long PerfMode_ParamHandler_3_Entry
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long PerfMode_VolumeParam_Process
	.long ToneParam_Evt09_BytecodeHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long PerfMode_ParamHandler_3_Entry
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
PerfMode_ParamHandler_4:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, 17
	sla	hl, 2
	push	xix
	.byte 0x44
	.long PerfMode_StringData_4
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
	ret
PerfMode_StringData_4:
	.incbin "includes/generated/v7_transplant_PerfMode_StringData_4.bin"
PerfMode_EventTable_4:
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long PerfMode_VolumeParam_Process
	.long ToneParam_Evt09_BytecodeHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
PerfMode_ParamHandler_5:
	.incbin "includes/generated/v7_transplant_PerfMode_ParamHandler_5.bin"
PerfMode_EventTable_5:
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long PerfMode_VolumeParam_Process
	.long ToneParam_Evt09_BytecodeHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
PerfMode_ParamHandler_7:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, 17
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_ParamHandler_Data_0x13
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	call	(xhl)
	ret
PerfMode_ParamHandler_Data:
	.incbin "includes/generated/v7_transplant_PerfMode_ParamHandler_Data.bin"
PerfMode_EventTable_6:
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long PerfMode_ParamHandler_Data
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long PerfMode_VolumeParam_Process
	.long ToneParam_Evt09_BytecodeHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long PerfMode_ParamHandler_Data
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
PerfMode_ParamHandler_8:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, 17
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_7
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
	ret


PerfMode_EventTable_7:
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long PerfMode_VolumeParam_Process
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
PerfMode_VolumeParam_Process:
	.incbin "includes/generated/v7_transplant_PerfMode_VolumeParam_Process.bin"
PerfMode_ParamHandler_9:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, 17
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_9
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	call	(xhl)
	ret
PerfMode_EventTable_9:
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long PerfMode_Evt04_VolumeHandler
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long PerfMode_Evt04_VolumeHandler
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
PerfMode_Evt04_VolumeHandler:
	.incbin "includes/generated/v7_transplant_PerfMode_Evt04_VolumeHandler.bin"
PerfMode_VoiceAddressTable:
	.incbin "includes/generated/v7_transplant_PerfMode_VoiceAddressTable.bin"
PerfMode_ParamHandler_10:
	.incbin "includes/generated/v7_transplant_PerfMode_ParamHandler_10.bin"
PerfMode_EventTable_10:
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long VoiceParam_MultiDispatch
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long PerfMode_VolumeParam_Process
	.long ToneParam_Evt09_BytecodeHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIDisp_DefaultInputHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long VoiceParam_MultiDispatch
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
VoiceParam_MultiDispatch:
	; --- Dispatcher: 5-way branch on (0x10f2) value (318 bytes total) ---
	ldb_d8	a, (4337)
	ldb l, 0x03
	ldb_d8	a, (4338)
	cp a, l
	jrl z, VoiceParam_Case03
	cp a, 0x08
	jrl z, VoiceParam_Case08
	cp a, 0x0a
	jrl z, VoiceParam_Case0A
	cp a, 0x0b
	jrl z, VoiceParam_Case0B
	; --- Default handler: H=0x4c, L=0x34 ---
	ldb_d8	a, (4339)
	ldb l, 0x34
	ldb h, 0x4c
	call PerfMode_VoiceAddressTable_0x50
	stb_d8	(4339), a
	stdi8	(3571), 4
	call VoiceSlot_ReadParamsWithSaveRestore
	call StringData_PartNames_0xB3
	jp VoiceParam_CommonTail
VoiceParam_Case03:
	; --- Case 0x03: H=0x7f, L=0x00 ---
	ldb_d8	a, (4339)
	ldb l, 0x00
	ldb h, 0x7f
	call PerfMode_VoiceAddressTable_0x50
	stb_d8	(4339), a
	stdi8	(3571), 4
	call VoiceSlot_ReadParamsWithSaveRestore
	call StringData_KeyNames_0x341
	jp VoiceParam_CommonTail
VoiceParam_Case08:
	; --- Case 0x08: H=0x7f, L=0x00 ---
	ldb_d8	a, (4339)
	ldb l, 0x00
	ldb h, 0x7f
	call PerfMode_VoiceAddressTable_0x50
	stb_d8	(4339), a
	stdi8	(3571), 4
	call VoiceSlot_ReadParamsWithSaveRestore
	call StringData_PartNames_0x54
	jp VoiceParam_CommonTail
VoiceParam_Case0A:
	; --- Case 0x0a: H=0xff, L=0x00 ---
	ldb_d8	a, (4339)
	ldb l, 0x00
	ldb h, 0xff
	call PerfMode_VoiceAddressTable_0x50
	stb_d8	(4339), a
	stdi8	(3571), 4
	call VoiceParam_BitManipHelper
	call StringData_PartNames_0x120
	jp VoiceParam_CommonTail
VoiceParam_Case0B:
	; --- Case 0x0b: H=0x0c, L=0x00 ---
	ldb_d8	a, (4339)
	ldb l, 0x00
	ldb h, 0x0c
	call PerfMode_VoiceAddressTable_0x50
	stb_d8	(4339), a
	stdi8	(3571), 4
	call VoiceSlot_ReadParamsWithSaveRestore
	call StringData_PartNames_0x1C9
VoiceParam_CommonTail:
	.incbin "includes/generated/v7_transplant_VoiceParam_CommonTail.bin"
VoiceSlot_ReadParamsWithSaveRestore:
	; --- Helper 1: guard on W, parameter setup + calls (44 bytes) ---
	call VoiceState_DataBlock2_0x10C
	cps	w, 0
	jrl z, VoiceParam_SaveRestore_Ret
	xor	a, a
	call VoiceSlot_SaveState
	ldb_d8	e, (3571)
	xor d, d
	call VoiceSlot_FinalRetZ_0xB8
	call VoiceSlot_ReadCurrentParams
	ldb_d8	w, (4339)
	call VoiceSlot_FinalRetZ_0x84
	xor	a, a
	call VoiceSlot_RestoreState
VoiceParam_SaveRestore_Ret:
	ret
VoiceParam_BitManipHelper:
	; --- Helper 2: guard on W, bit manipulation + calls (70 bytes) ---
	call VoiceState_DataBlock2_0x10C
	cps	w, 0
	jrl z, VoiceParam_BitManip_Ret
	xor	a, a
	call VoiceSlot_SaveState
	call VoiceSlot_ReadCurrentParams
	ldb_d8	w, (4339)
	and w, 0x80
	rlc	w
	and a, 0xfe
	or w, a
	call VoiceSlot_FinalRetZ_0x84
	ldb_d8	e, (3571)
	xor d, d
	call VoiceSlot_FinalRetZ_0xB8
	call VoiceSlot_ReadCurrentParams
	ldb_d8	w, (4339)
	and w, 0x7f
	call VoiceSlot_FinalRetZ_0x84
	xor	a, a
	call VoiceSlot_RestoreState
VoiceParam_BitManip_Ret:
	ret


UIState_PerfModeEntry:
	.incbin "includes/generated/v7_transplant_UIState_PerfModeEntry.bin"
UIState_EventTable:
	.long UIState_DispatchHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long UIState_Evt05_Handler
	.long UIState_Evt06_Handler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_ShortCallHandler
	.long DefaultHandler_Ret
	.long ScoopDisp_DispatchTable_Extended_0x20
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIState_DispatchHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long UIState_Evt05_Handler
	.long UIState_Evt06_Handler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
UIState_DispatchHandler:
	.incbin "includes/generated/v7_transplant_UIState_DispatchHandler.bin"
UIState_CallDecHandler:
	call VoiceSlot_TableSetup_0x56D
UIState_CheckValueChanged:
	.incbin "includes/generated/v7_transplant_UIState_CheckValueChanged.bin"
UIState_UpdateAllRegions:
	call UIState_UpdateMultiRegions
UIState_Dispatch_Ret:
	ret
UIState_UpdateMultiRegions:
	; --- Multi-call teardown (25 bytes) ---
	call Display_UpdateRegion7
	call Display_UpdateRegion8
	call Display_UpdateRegion9
	call Display_UpdateRegion1
	call Display_UpdateRegion10
	call Display_UpdateRegion2
	ret


Display_RedrawParameters:
	.incbin "includes/generated/v7_transplant_Display_RedrawParameters.bin"
Display_RedrawParams_StoreAndLoad:
	stda16 (3660), xwa
	call VoiceBank_BitsAndLoad
	ldb_d8 a, (3424)
	call SetWall_SlotResolve
	stb_d8 (3820), a
	ldw_d16 xwa, (0x28af)
	stda16 (0x28bf), xwa
	stda16 (0x28c1), xiy
	call VoiceBank_ProcessCommand
	ld xix, 0xef8
	call VoiceBank_CheckCommand
	ldb c, 0x0
	call VoiceBank_StatusDoubleRCF
	ldb_d8 a, (3820)
	ld l, a
	cps a, 4
	jrl ule, Display_RedrawParams_StoreDigits
	ldb a, 0x4

Display_RedrawParams_StoreDigits:
	stb_d8 (3666), a
	cps l, 4
	jrl ule, Display_RedrawParams_Ret
	add l, 0x30
	ld xix, 0xf07
	ld (xix), 0x28
	ld (xix + 1), l
	ldw (xix + 2), 0x342f
	ld (xix + 4), 0x29

Display_RedrawParams_Ret:
	ret

Display_RedrawValues:
	.incbin "includes/generated/v7_transplant_Display_RedrawValues.bin"
Display_RedrawValues_Store:
	.incbin "includes/generated/v7_transplant_Display_RedrawValues_Store.bin"
Display_RedrawValues_StoreDigits:
	stb_d8 (3667), a
	cps l, 4
	jrl ule, Display_RedrawValues_Ret
	add l, 0x30
	ld xix, 0xf25
	ld (xix), 0x28
	ld (xix + 1), l
	ldw (xix + 2), 0x342f
	ld (xix + 4), 0x29

Display_RedrawValues_Ret:
	ret

Display_RedrawIndicators:
	.incbin "includes/generated/v7_transplant_Display_RedrawIndicators.bin"
Display_RedrawInd_Store:
	stda16 (3664), xwa
	call VoiceBank_BitsAndLoad
	ldb_d8 a, (3424)
	call SetWall_SlotResolve
	cpdi8 (0x287a), 0
	jrl z, Display_RedrawInd_LoadDirect
	ldb_d8 a, (3421)
	stb_d8 (3820), a
	jp Display_RedrawInd_CalcSlotCount

Display_RedrawInd_LoadDirect:
	stb_d8 (3820), a
	ldw_d16 xwa, (0x28af)
	stda16 (0x28bf), xwa
	stda16 (0x28c1), xiy
	call VoiceBank_ProcessCommand
	ld xix, 0xf34
	call VoiceBank_CheckCommand
	ldb c, 0x4
	call VoiceBank_StatusDoubleRCF

Display_RedrawInd_CalcSlotCount:
	ldb_d8 a, (3820)
	ld l, a
	cps a, 4
	jrl ule, Display_RedrawInd_StoreDigits
	ldb a, 0x4

Display_RedrawInd_StoreDigits:
	stb_d8 (3668), a
	cps l, 4
	jrl ule, Display_RedrawInd_Ret
	add l, 0x30
	ld xix, 0xf43
	ld (xix), 0x28
	ld (xix + 1), l
	ldw (xix + 2), 0x342f
	ld (xix + 4), 0x29

Display_RedrawInd_Ret:
	ret

VoiceBank_BitsAndLoad:
	ldb_d8 w, (3822)
	ordi8 0x287b, 4
	ret

VoiceBank_StatusDoubleRCF:
	ldb_erp A, 0x3c
	ld a, c
	rcf
	stcfa_dd16 0x52, 0x0f
	stb_erp A, 0x3c
	inc 1, c
	ldb_erp A, 0x3c
	ld a, c
	rcf
	stcfa_dd16 0x52, 0x0f
	stb_erp A, 0x3c
	dec 1, c
	ldb_d8 a, (3765)
	cp a, 0x81
	jrl z, Display_NullRet2
	cp a, 0x82
	jrl z, Display_NullRet2
	cp a, 0x84
	jrl z, Display_NullRet2
	ldb_erp A, 0x3c
	ld a, c
	scf
	stcfa_dd16 0x52, 0x0f
	stb_erp A, 0x3c

Display_RedrawFooter_Main:
	pushw bc
	call VoiceBank_ProcessCommand
	popw bc
	ldb_d8 a, (3765)
	cp a, 0x82
	jrl z, Display_NullRet2
	cp a, 0x84
	jrl z, Display_NullRet2
	cp a, 0x81
	jrl z, Display_NullRet2
	cp a, 0x85
	jrl z, Display_RedrawTitleString
	cp a, 0x86
	jrl z, Display_RedrawTitleString
	cpdi8 (3766), 0
	jrl nz, Display_RedrawFooter_Main

Display_RedrawTitleString:
	ldb_erp A, 0x3c
	ld a, c
	rcf
	stcfa_dd16 0x52, 0x0f
	stb_erp A, 0x3c
	inc 1, c
	ldb_erp A, 0x3c
	ld a, c
	scf
	stcfa_dd16 0x52, 0x0f
	stb_erp A, 0x3c

Display_NullRet2:
	ret

VoiceBank_CheckCommand:
	cpdi8 (3765), 129
	jrl nz, Display_TitleString_BuildFromMode
	push xix
	call VoiceBank_ProcessCommand
	pop xix
	cpdi8 (3765), 129
	jrl z, TitleString_NullRet

Display_TitleString_BuildFromMode:
	ldb_d8 a, (3765)
	cp a, 0x80
	jrl z, Display_TitleString_Mode0
	cp a, 0x82
	jrl z, Display_TitleString_Mode1
	cp a, 0x84
	jrl z, Display_TitleString_Mode2
	cp a, 0x85
	jrl z, Display_TitleString_Mode3
	cp a, 0x86
	jrl z, Display_TitleString_Mode4
	and a, 0xf0
	cp a, 0xb0
	jrl z, Display_TitleString_Mode5
	cp a, 0xc0
	jrl z, TitleString_LoadRhythmLabel
	jp TitleString_NullRet

Display_TitleString_Mode0:
	ld xiy, StringData_Tempo
	lds bc, 5
	jp String_CopyFromIY

Display_TitleString_Mode1:
	ldw (xix), 0x4e45
	ld (xix + 2), 0x44
	jp TitleString_NullRet

Display_TitleString_Mode2:
	ld xiy, StringData_Repeat
	lds bc, 6
	jp String_CopyFromIY

Display_TitleString_Mode3:
	ld xiy, StringData_Start
	lds bc, 5
	jp String_CopyFromIY

Display_TitleString_Mode4:
	ld xiy, StringData_Stop
	lds bc, 4
	jp String_CopyFromIY

Display_TitleString_Mode5:
	cpdi8 (3767), 72
	jrl nz, TitleString_NullRet
	ldb_d8 a, (3768)
	cps a, 5
	jrl z, TitleString_MaskAndFormat
	cps a, 6
	jrl z, TitleString_MaskAndFormat
	cps a, 7
	jrl nz, TitleString_NullRet
	bitda 4, (3770)
	jrl z, TitleString_NullRet
	ldb_d8 a, (3769)
	and a, 0x30
	sra a, 4
	ldw bc, 0xa
	ld xiy, StringData_VariNames
	ld w, a
	sla a, 3
	sla w, 1
	add a, w
	xor w, w
	stb_dri E, 0x07, 0xf4, 0xe0
	jp String_CopyFromIY

TitleString_MaskAndFormat:
	ldb_d8 w, (3765)
	ld h, w
	and w, 0x1
	rrc w
	ldb_d8 a, (3769)
	or a, w
	and h, 0x2
	ldb_d8 l, (3770)
	rrc_i_8 h, 2
	or l, h
	and a, l
	xor c, c

TitleString_BitScanLoop:
	ldb_erp A, 0x3c
	ldb_erp A, 0x3d
	ld a, c
	scf
	xorcfb_erp 0x3d
	stb_erp A, 0x3c
	jrl nc, TitleString_CheckRhythmBank
	inc 1, c
	cps c, 7
	jrl ule, TitleString_BitScanLoop
	jp TitleString_NullRet

TitleString_CheckRhythmBank:
	cpdi8 (3768), 6
	jrl nz, TitleString_BuildFromBank
	add c, 0x8

TitleString_BuildFromBank:
	xor b, b
	sla bc, 3
	ld xiy, StringData_StyleSections
	stb_dri E, 0x07, 0xf4, 0xe4
	ldw bc, 0x8
	jp String_CopyFromIY

TitleString_LoadRhythmLabel:
	ld xiy, StringData_Rhythm
	lds bc, 6

String_CopyFromIY:
	ldir85

TitleString_NullRet:
	ret

StringData_Tempo:	.ascii "TEMPO"

StringData_Repeat:	.ascii "REPEAT"

StringData_Start:	.ascii "START"

StringData_Stop:	.ascii "STOP"

StringData_Rhythm:	.ascii "RHYTHM"

StringData_VariNames:	.ascii "VARI 1    VARI 2    VARI 3    VARI 4    "

StringData_StyleSections:	.ascii "                INTRO1  COUNT   ENDING1 ENDING2 FILL IN1FILL IN2                INTRO2                                          "

Display_FillRegion0:
	ld xix, 0xef8
	call Display_FillMemoryLoop
	ret

Display_FillRegion1:
	ld xix, 0xf16
	call Display_FillMemoryLoop
	ret

Display_FillRegion2:
	ld xix, 0xf34
	call Display_FillMemoryLoop
	ret

Display_FillMemoryLoop:
	pushw wa
	ldw wa, 0x2020
	ldw bc, 0xf

Display_FillRegionLoop:
	stw_dpi WA, 0xf1
	djnz xbc, Display_FillRegionLoop
	popw wa
	ret

PerfMode_BytecodeEntry_A:
	cps	bc, 0
	jrl	nz, 4
	call	UIState_DispatchHandler
	ret
PerfMode_BytecodeBody_A:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, 17
	sla	hl, 2
	push	xix
	.byte 0x44
	.long PerfMode_StringData_A
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
	ret
PerfMode_StringData_A:
	.incbin "includes/generated/v7_transplant_PerfMode_StringData_A.bin"
PerfMode_DispatchTable_A:
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneEvt_Handler_ModeAlt
	.long ToneEvt_Handler_Mode9
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIState_DispatchHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
PerfMode_BytecodeEntry_B:
	.incbin "includes/generated/v7_transplant_PerfMode_BytecodeEntry_B.bin"
PerfMode_DispatchTable_B:
	.long UIState_DispatchHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long PerfMode_ParamHandler_Data
	.long DefaultHandler_Ret
	.long UIState_Evt05_Handler
	.long UIState_Evt06_Handler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_ShortCallHandler
	.long DefaultHandler_Ret
	.long ScoopDisp_DispatchTable_Extended_0x20
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIState_DispatchHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long PerfMode_ParamHandler_Data
	.long DefaultHandler_Ret
	.long UIState_Evt05_Handler
	.long UIState_Evt06_Handler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
PerfMode_BytecodeEntry_C:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, 17
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_DispatchTable_C
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	call	(xhl)
	ret
PerfMode_DispatchTable_C:
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long PerfMode_Handler_EvtA
	.long PerfMode_Handler_EvtB
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
PerfMode_Handler_EvtA:
	bit	7, w
	jrl	nz, 4
	call	ScoopDisp_DispatchTable_Extended_0x3E
	ret
PerfMode_Handler_EvtB:
	.incbin "includes/generated/v7_transplant_PerfMode_Handler_EvtB.bin"
ScoopDisp_DispatchTable_Extended:
	.incbin "includes/generated/v7_transplant_ScoopDisp_DispatchTable_Extended.bin"
Display_DirtyRegionDispatch:
	bitda 3, (3411)
	jrl z, Timer_ModeDispatch_Return
	call Display_ResetDirtyFlags
; Timer mode dispatch
; Index: DRAM[3429] & 0x3 (0-3), entries: 4
; Dispatches display timer update based on current mode
Timer_ModeDispatch:
	ldb_d8 l, (3429)
	and l, 0x3
	xor h, h
	sla hl, 2
	push xix
	ld xix, Timer_ModeSelect_Table
	ld_sril3 XHL, 0x07, 0xf0, 0xec
	pop xix
	call (xhl)
	call Display_UpdateDirtyRegions

Timer_ModeDispatch_Return:
	ret


Timer_ModeSelect_Table:
	.long Timer_ModeHandler_0
	.long Timer_ModeHandler_1
	.long Timer_ModeHandler_1
	.long Timer_ModeHandler_3
Timer_ModeHandler_1:
	; --- Guard/init function (55 bytes) ---
	call VoiceState_DataBlock2_0x1D8
	cps	w, 0
	jrl nz, Timer_GuardCallSetup_Ret
	call DisplayMode_Handler_3_0x5F
	call MemConfig_Handler_4_0x15B
	call SeqState_HasModeChanged
	cps	hl, 0
	jrl nz, Timer_GuardCallSetup_Ret
	bitda	0, (3927)
	jrl z, Timer_GuardCallSetup
	anddi8	(3927), 254
Timer_GuardCallSetup:
	call VoiceSlot_TableSetup
	call Timer_ModeHandler_0_0x13
	call Display_UpdateRegion5
	call Display_UpdateRegion3
Timer_GuardCallSetup_Ret:
	ret


Timer_ModeHandler_3:
	call	VoiceState_DataBlock2_0x1D8
	cps	w, 0
	jrl	nz, 50
	.byte 0xc1, 0xef
	decf
	push	xsp
	ccf
	jrl	nz, 8
	call	PortConfig_DataTable_B_0x20
	jp	Timer_ModeHandler_3_0x3B
	call	DisplayMode_Handler_3_0x5F
	call	SeqState_HasModeChanged
	cps	hl, 0
	jrl	nz, 21
	call	UIState_UpdateMultiRegions
	call	MemConfig_Handler_4_0x15B
	call	SeqState_HasModeChanged
	cps	hl, 0
	jrl	nz, 4
	call	DisplayStr_StyleSectionNames_0x69
	ret
Timer_ModeHandler_0:
	.incbin "includes/generated/v7_transplant_Timer_ModeHandler_0.bin"
Timer_ParamLoadAndCompare:
	.incbin "includes/generated/v7_transplant_Timer_ParamLoadAndCompare.bin"
Timer_ParamCompareAlt:
	.incbin "includes/generated/v7_transplant_Timer_ParamCompareAlt.bin"
ToneParam_ModeGuardEntry:
	.incbin "includes/generated/v7_transplant_ToneParam_ModeGuardEntry.bin"
MemConfig_Handler_5:
	.incbin "includes/generated/v7_transplant_MemConfig_Handler_5.bin"
ToneParam_ShortCallHandler:
	call	ToneParam_Evt09_BytecodeHandler
	call	UIState_UpdateMultiRegions
	ret
ToneParam_Evt09_BytecodeHandler:
	.incbin "includes/generated/v7_transplant_ToneParam_Evt09_BytecodeHandler.bin"
ToneParam_HandlerTable_BC:
	.incbin "includes/generated/v7_transplant_ToneParam_HandlerTable_BC.bin"
ToneEvt_Handler_Mode9:
	bit	7, w
	jrl	nz, 8
	call	ToneEvt_Handler_ModeSingle
	call	DisplayMode_Handler_3_0x3F
	ret
ToneEvt_Handler_ModeSingle:
	bit	7, w
	jrl	nz, 4
	call	Display_ModeHandler
	ret
ToneEvt_Handler_ModeAlt:
	bit	7, w
	jrl	nz, 4
	call	PeriphReg_CheckAndDispatch
	ret
PeriphReg_CheckAndDispatch:
	; --- Peripheral register handler (111 bytes, 2 functions) ---
	bit 7, w
	jrl z, PeriphReg_CheckActiveSlot
	jp PeriphReg_Ret
PeriphReg_CheckActiveSlot:
	cpdi8	(3413), 255
	jrl nz, PeriphReg_StoreAndUpdate
	jp PeriphReg_Ret
PeriphReg_StoreAndUpdate:
	ldb_d8	a, (3471)
	stb_d8	(3536), a
	cpda8	a, 3537
	jrl nz, PeriphReg_LoadWordAndCall
	call ToneParam_HandlerTable_BC_0x4DC
PeriphReg_LoadWordAndCall:
	ldb_d8	w, (3538)
	ld xiy, 0x00000d8f
	call SysInit_BytecodeBlock_0x486
	call Display_ModeHandler
PeriphReg_Ret:
	ret
; Display mode handler
Display_ModeHandler:
	ordi8	3539, 1
	xor	a, a
	stb_d8	(3538), a
	stdi8	(3413), 255
	call VoiceState_DataBlock2_0x10C
	cps w, 0
	jrl	nz, 82
	ldb_d8	l, (3429)
	and l, 0x03
	xor	h, h
	sla hl, 2
	push xix
	ld xix, DisplayMode_DispatchTable
	ld_rrl	xhl, xix, hl
	pop xix
	call	(xhl)
	ret


DisplayMode_DispatchTable:
	.long DefaultHandler_Ret
	.long DisplayMode_Handler_1
	.long DisplayMode_Handler_2
	.long DisplayMode_Handler_3
DisplayMode_Handler_1:
	stdi8	(3567), 0
	call	Display_BytecodeBlock_F
	ret
DisplayMode_Handler_2:
	stdi8	(3567), 8
	call	DisplayStr_TempoString_0x32
	ret
DisplayMode_Handler_3:
	.incbin "includes/generated/v7_transplant_DisplayMode_Handler_3.bin"
DMA_ChannelSelect_Table:
	.long DMA_ChannelHandler_0
	.long DMA_ChannelHandler_1
	.long DMA_ChannelHandler_2
	.long DMA_ChannelHandler_3
DMA_ChannelHandler_1:
	.incbin "includes/generated/v7_transplant_DMA_ChannelHandler_1.bin"
DMA_ChannelHandler_2:
	.byte 0xc1, 0xef
	decf
	push	xsp
	ldio	126, 8
	nop
	call	DisplayStr_TempoString_0x36
	jp	DMA_ChannelHandler_2_0x19
	stdi8	(3567), 8
	call	DisplayStr_TempoString_0x32
	ret
DMA_ChannelHandler_0:
	.incbin "includes/generated/v7_transplant_DMA_ChannelHandler_0.bin"
DMA_ChannelHandler_3:
	; --- Conditional init (31 bytes) ---
	cpdi8	(3567), 15
	jrl z, DMA_Channel3_CallAndInit
	stdi8	(3567), 15
	call DisplayStr_TempoString_0x6F
DMA_Channel3_CallAndInit:
	.incbin "includes/generated/v7_transplant_DMA_Channel3_CallAndInit.bin"
DMA_FlagCheckWithCalls:
	; --- Flag-check with calls (42 bytes) ---
	xor	a, a
	call VoiceSlot_SaveState
	call VoiceSlot_StatusRet
	xor	a, a
	call VoiceSlot_RestoreState
	call VoiceSlot_ReadCurrentParams
	ld xhl, 0x00000d54
	and a, 0xf0
	cp a, 0x90
	jrl nz, DMA_StoreFlagAndReturn
	setm	2, (xhl)
DMA_StoreFlagAndReturn:
	stdi8	(3422), 0
	ret


VoiceSlot_TableSetup:
	.incbin "includes/generated/v7_transplant_VoiceSlot_TableSetup.bin"
AccPedal_CheckBitAndUpdate:
	bitda 0, (3412)
	jrl z, AccPedal_ClearFlagAndJump
	ordi8 0x287b, 4

AccPedal_LoadModeAndChannel:
	ldb_d8 w, (3414)
	ldb_d8 a, (3822)
	cpdi8 (3429), 0
	jrl z, AccPedal_LoadAddr0
	ldw_d16 xhl, (3418)
	jp AccPedal_StoreAddrAndCheck

AccPedal_LoadAddr0:
	ldw_d16 xhl, (3416)

AccPedal_StoreAddrAndCheck:
	stda16 (3299), xhl
	cpdi8 (3429), 3
	jrl nz, AccPedal_CallEventSwitch
	ld w, a
	ordi8 0x287b, 4

AccPedal_CallEventSwitch:
	.incbin "includes/generated/v7_transplant_AccPedal_CallEventSwitch.bin"
AccPedal_ClearFlagAndJump:
	anddi8 (0x287b), 251
	jp AccPedal_LoadModeAndChannel

AccPedal_SendSysExAndReturn:
	ldb w, 0x68
	call MIDI_SendSysExFromW
	ldb w, 0xff

AccPedal_Ret:
	ret

AccPedal_ScanVoiceSlots:
	push xwa
	ldda32 xwa, (4349)
	ldfr_lerp XWA, 0x38
	pop xwa
	push_lerp 0x38
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	anddi8 (3411), 253
	xor a, a
	call VoiceSlot_SaveState
	call MemConfig_VoiceSlotLookup
	call VoiceSlot_ReadCurrentParams
	cp a, 0x81
	jrl nz, AccPedal_CompareMode85
	jp AccPedal_ClearBit2Flag

VoiceSlot_ProcessedWordRet:
	call VoiceSlot_DispatchRet
	cp w, 0xff
	jrl z, AccPedal_RestoreAndReturn
	call VoiceSlot_ComputeWordIndex
	push xix
	ld xix, 0xc9e
	ldw_sri IY, 0x07, 0xf0, 0xf8
	srl xiz, 1
	ld xix, 0xcbe
	ldb_sri A, 0x07, 0xf0, 0xf8
	pop xix
	cpda16 xiy, 3583
	jrl nz, AccPedal_RereadParams
	cpda8 a, 3585
	jrl nc, AccPedal_RestoreAndReturn

AccPedal_RereadParams:
	call VoiceSlot_ReadCurrentParams

AccPedal_CompareMode85:
	cp a, 0x85
	jrl z, AccPedal_SetBit2Flag
	cp a, 0x86
	jrl z, AccPedal_ClearBit2Flag
	jp VoiceSlot_ProcessedWordRet

AccPedal_SetBit2Flag:
	ordi8 3411, 2
	jp VoiceSlot_ProcessedWordRet

AccPedal_ClearBit2Flag:
	anddi8 (3411), 253
	jp VoiceSlot_ProcessedWordRet

AccPedal_RestoreAndReturn:
	xor a, a
	call VoiceSlot_RestoreState
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	pop_lerp 0x38
	push xwa
	ldto_lerp XWA, 0x38
	stda32 4349, xwa
	pop xwa
	ret

VoiceCtrl_BytecodeHandler:
	ldb	a, 2
	call	VoiceSlot_SaveState
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 176
	jrl	nz, 107
	call	VoiceSlot_FinalRetZ
	and	a, 3
	stb_d8	(3528), a
	call	VoiceSlot_FinalRetZ
	call	VoiceSlot_FinalRetZ
	cp	a, 72
	jrl	nz, 82
	call	VoiceSlot_FinalRetZ
	.byte 0xc7
	push	xwa
	xor	(xbc-55), iz
	jrl	z, 5
	cps	a, 5
	jrl	nz, 65
	call	VoiceSlot_FinalRetZ
	stb_d8	(3527), a
	.byte 0xf1, 0xc8
	decf
	scc8	z, w
	halt
	nop
	.byte 0xc1, 0xc7
	decf
	push	xiz
	.byte 0x80
	call	VoiceSlot_FinalRetZ
	.byte 0xf1, 0xc8
	decf
	scc8	z, a
	pop	sr
	nop
	or	a, 128
	ldb	c, 7
	.byte 0xc7
	push	xix
	.byte 0x99, 0xc7
	push	xiy
	add	(xbc-53), bc
	scf
	.byte 0xc7
	push	xiy
	pushw	de
	.byte 0xc7
	push	xix
	.byte 0x89
	jrl	nc, 23
	cps	c, 0
	jrl	z, 6
	dec	1, c
	jp	VoiceCtrl_BytecodeHandler_0x61
	ldb	b, 255
	ldb	a, 2
	call	VoiceSlot_RestoreState
	jp	VoiceCtrl_BytecodeHandler_0xB9
	ld	b, c
	.byte 0xc7
	push	xix
	add	(xbc-53), bc
	scf
	.byte 0xf1, 0xc7
	decf
	pushw	de
	.byte 0xc7
	push	xix
	.byte 0x89
	jrl	c, 13
	.byte 0xc7
	push	xwa
	scc16	nz, iz
	.byte 0xde
	swi	7
	add	b, 8
	jp	VoiceCtrl_BytecodeHandler_0x80
	.byte 0xc7
	push	xwa
	scc16	nz, iz
	pop	sr
	nop
	add	b, 8
	set	4, b
	jp	VoiceCtrl_BytecodeHandler_0x9C
	ret
VoiceCtrl_CheckAndReset:
	.incbin "includes/generated/v7_transplant_VoiceCtrl_CheckAndReset.bin"
VoiceCtrl_SendNoteOffSequence:
	push xhl
	pushw wa
	ordi8 0x28b3, 64
	ldb a, 0x90
	ld hl, wa
	pushw hl
	call SeqBuf_WriteByte
	inc 2, xsp
	ldb a, 0x7f
	ld hl, wa
	pushw hl
	call SeqBuf_WriteByte
	inc 2, xsp
	ldb a, 0x33
	ld hl, wa
	pushw hl
	call SeqBuf_WriteByte
	inc 2, xsp
	ldb a, 0x0
	ld hl, wa
	pushw hl
	call SeqBuf_WriteByte
	inc 2, xsp
	ldb_d8 a, (3822)
	dec 1, a
	ld hl, wa
	pushw hl
	call SeqBuf_WriteByte
	inc 2, xsp
	call VoiceAlloc_ScoopDisplayProcess
	popw wa
	pop xhl
	ret

VoiceCtrl_ParamSetupBytecode:
	.incbin "includes/generated/v7_transplant_VoiceCtrl_ParamSetupBytecode.bin"
SerialPort_ModeSelect_Table:
	.long SerialPort_ModeHandler_0
	.long SerialPort_ModeHandler_1
	.long SerialPort_ModeHandler_1
	.long SerialPort_ModeHandler_3
SerialPort_ModeHandler_1:
	stdi8	(3567), 5
	call	DisplayStr_BytecodeBlock_C
	ret
SerialPort_ModeHandler_3:
	stdi8	(3567), 15
	call	DisplayStr_StyleSectionInit
	ret
SerialPort_ModeHandler_0:
	.incbin "includes/generated/v7_transplant_SerialPort_ModeHandler_0.bin"
ScoopParam_ValueTable:
	.incbin "includes/generated/v7_transplant_ScoopParam_ValueTable.bin"
Interrupt_ModeGuardCheck:
	cpdi8 (3567), 18
	jrl z, Interrupt_NullRet
	cpdi8 (3429), 0
	jrl nz, Interrupt_NullRet
	jp Interrupt_ModeGuardEntry
Interrupt_JumpToGuard:
	jp	Interrupt_NullRet

Interrupt_ModeGuardEntry:
	cpdi8 (3429), 0
	jrl nz, Interrupt_NullRet
	ldb_d8 a, (3432)
	cps a, 4
	jrl ule, Interrupt_CodeDispatch
	xor a, a

; Interrupt dispatch by code
Interrupt_CodeDispatch:
	xor w, w
	sla a, 2
	ld hl, wa
	ld xwa, Interrupt_VectorSelect_Table
	ld_sril3 XHL, 0x07, 0xe0, 0xec
	call (xhl)
	jp Interrupt_NullRet

Interrupt_NullRet:
	ret

Interrupt_VectorSelect_Table:
	.long Interrupt_VectorHandler_0
	.long Interrupt_VectorHandler_1
	.long Interrupt_VectorHandler_2
	.long Interrupt_VectorHandler_3
	.long Interrupt_VectorHandler_4

Interrupt_VectorHandler_0:
	.incbin "includes/generated/v7_transplant_Interrupt_VectorHandler_0.bin"
Interrupt_Vec0_InitPath:
	call Interrupt_ClearRegsAndInit

Interrupt_Vec0_Ret:
	ret

Interrupt_VectorHandler_1:
	stdi8 (3432), 0
	call Interrupt_VectorHandler_0
	ret

Interrupt_VectorHandler_2:
	.incbin "includes/generated/v7_transplant_Interrupt_VectorHandler_2.bin"
Interrupt_Vec2_Ret:
	ret

Interrupt_VectorHandler_3:
	.incbin "includes/generated/v7_transplant_Interrupt_VectorHandler_3.bin"
Interrupt_Vec3_UpdatePath:
	call Display_RegionUpdateFromHW

Interrupt_Vec3_Ret:
	ret

Interrupt_VectorHandler_4:
	.incbin "includes/generated/v7_transplant_Interrupt_VectorHandler_4.bin"
Interrupt_Vec4_InitPath:
	call Interrupt_ClearModeAndRet

Interrupt_Vec4_Ret:
	ret

Interrupt_StoreHWRegsAndInit:
	cpdi8 (3422), 0
	jrl z, Interrupt_LoadAndStoreRegs
	stdi8 (3422), 0

Interrupt_LoadAndStoreRegs:
	.incbin "includes/generated/v7_transplant_Interrupt_LoadAndStoreRegs.bin"
Interrupt_ClearRegsAndInit:
	xor a, a
	stb_d8 (3437), a
	stb_d8 (3438), a
	stb_d8 (3425), a
	stb_d8 (4391), a
	call SNS_Init_Startup
	call Display_UpdateRegion3
	ret

Interrupt_FlagSetBytecode:
	.incbin "includes/generated/v7_transplant_Interrupt_FlagSetBytecode.bin"
Interrupt_SendAllNotesOff:
	.incbin "includes/generated/v7_transplant_Interrupt_SendAllNotesOff.bin"
Interrupt_ClearModeRegs:
	.incbin "includes/generated/v7_transplant_Interrupt_ClearModeRegs.bin"
Interrupt_SetFlagBytecode:
	.incbin "includes/generated/v7_transplant_Interrupt_SetFlagBytecode.bin"
Interrupt_UpdateFromHW:
	call Display_RegionUpdateFromHW
	ret

Interrupt_ClearModeAndRet:
	stdi8 (3432), 0
	ret

Display_RegionUpdateFromHW:
	.incbin "includes/generated/v7_transplant_Display_RegionUpdateFromHW.bin"
PortConfig_SetupBytecode:
	stdi8	(0x28be), 255
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	push	xix
	ld	xix, 0xf1a0
	.byte 0xc3
	reti
	.byte 0xf0
	swi	0
	push	xsp
	ret
	pop	xix
	jrl	nz, 23
	ldb_d8	a, (3822)
	dec	1, a
	stb_d8	(0x28be), a
	push	xix
	ld	xix, 0xf1a0
	.byte 0xf3
	reti
	.byte 0xf0
	swi	0
	nop
	decf
	pop	xix
	ret
	ldb_d8	a, (3429)
	and	wa, 3
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, PortConfig_Select_Table
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	call	(xhl)
	ret
PortConfig_Select_Table:
	.long PortConfig_Handler_0
	.long PortConfig_Handler_1
	.long PortConfig_Handler_1
	.long PortConfig_Handler_3
PortConfig_Handler_1:
	.byte 0xc1, 0xd3
	decf
	push	xiz
	.byte 0x01
	call	VoiceSlot_TableSetup
	call	Timer_ModeHandler_0_0x13
	call	PortConfig_Handler_0_0xD7
	call	ToneParam_HandlerTable_BC_0x567
	.byte 0xf1, 0x54
	decf
	.byte 0xb2
	ret
PortConfig_Handler_3:
	; --- Init: call FB1536, set 3 flags, call 6 handlers, call FB155F (51 bytes) ---
	call Display_DeferOrDrawWall
	stib_da	(0x0205e8), 255
	stib_da	(0x0205ec), 255
	stib_da	(0x0205ea), 255
	call DisplayStr_TempoString_0x6F
	call DisplayStr_TempoString_0x74
	call PortConfig_Handler_0_0xD7
	call UIState_UpdateMultiRegions
	call Display_UpdateRegion3
	call Display_UpdateRegion2
	call Display_DeferOrUpdateScreen
	ret


PortConfig_Handler_0:
	.incbin "includes/generated/v7_transplant_PortConfig_Handler_0.bin"
PortConfig_DataTable_A:
	.incbin "includes/generated/v7_transplant_PortConfig_DataTable_A.bin"
PortConfig_DataTable_B:
	nop
	push	sr
	.byte 0x01
	reti
	ldio	9, 10
	pushw	1284
	ei	3
	retd	0xffff
	swi	7
	swi	7
	incf
	decf
	ret
	ld	xhl, 4362
	ldda32	xwa, (7514)
	ld	(xhl), xwa
	ret
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	cp	wa, 0xffff
	jrl	nz, -13
	ret
	ld	xhl, PortConfig_DataTable_B_0x44
	ldb_d8	a, (3429)
	and	a, 3
	.byte 0xc3
	pop	sr
	or	xwa, xix
	ldb	a, 241
	.byte 0xef
	decf
	ld	xbc, 14
	incf
	ret
ClockConfig_Select_Table:
	.long ClockConfig_Handler_0
	.long ClockConfig_Handler_1
	.long ClockConfig_Handler_1
	.long ClockConfig_Handler_0
ClockConfig_Handler_1:
	.incbin "includes/generated/v7_transplant_ClockConfig_Handler_1.bin"
ClockConfig_Handler_0:
	.incbin "includes/generated/v7_transplant_ClockConfig_Handler_0.bin"
SysEx_PeriodicDispatch:
	.incbin "includes/generated/v7_transplant_SysEx_PeriodicDispatch.bin"
SysEx_CountdownCheck:
	cp (xiy), 0x0
	jrl z, SysEx_ControllerBitCheck

SysEx_DecrementAndCheck:
	decm8 1, (xiy)
	cp (xiy), 0x0
	jrl nz, SysEx_ControllerBitCheck
	call SysInit_SendAllNotesAndReset

SysEx_ControllerBitCheck:
	bitda 3, (3411)
	jrl z, ControllerMode_UpdateFlags
	bitda 0, (3924)
	jrl z, SysEx_ModeChangeCheck
	ldb_d8 c, (3925)
	add c, 0x5
	ldl_da xwa, (0x02749a)
	orda32_24 xwa, (0x02749e)
	stda32 4560, xwa
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ldw_d16 xde, (4560)
	ld a, c
	scf
	xorcf_a_16 de
	stw_erp DE, 0x3e
	stb_erp A, 0x3c
	jrl nc, SysEx_ModeChangeCheck
	anddi8 (3924), 254
	call VoiceCtrl_SendNoteOffSequence

SysEx_ModeChangeCheck:
	ld xiy, 0xd5e
	cp (xiy), 0x0
	jrl z, ControllerMode_UpdateFlags
	call SeqState_HasModeChanged
	cps hl, 0
	jrl nz, ControllerMode_UpdateFlags
	decm8 1, (xiy)
	cp (xiy), 0x0
	jrl nz, ControllerMode_UpdateFlags

ControllerMode_UpdateFlags:
	.incbin "includes/generated/v7_transplant_ControllerMode_UpdateFlags.bin"
SysEx_FlagClearAndCompare:
	.incbin "includes/generated/v7_transplant_SysEx_FlagClearAndCompare.bin"
SysEx_DecrementCounter:
	cpdi8 (3393), 0
	jrl z, SubCPU_CmdCountdownRet
	decdi8 1, 3393

SubCPU_CmdCountdownRet:
	ret

SysEx_BytecodeDispatcher:
	.incbin "includes/generated/v7_transplant_SysEx_BytecodeDispatcher.bin"
MemoryConfig_Handler_Table:
	.incbin "includes/generated/v7_transplant_MemoryConfig_Handler_Table.bin"
MemConfig_VoiceSlotLookup:
	call VoiceSlot_ComputeIndex
	push xde
	ld xde, 0xf250
	add xde, xiz
	ld wa, (xde + 1)
	pop xde
	cp wa, 0xffff
	jrl z, MemConfig_VoiceSlotSkip
	pushw wa
	call VoiceSlot_ComputeWordIndex
	popw wa
	push xix
	ld xix, 0xc9e
	stw_dri WA, 0x07, 0xf0, 0xf8
	pop xix

MemConfig_VoiceSlotCompare:
	srl xiz, 1
	push xix
	ld xix, 0xcbe
	stib_ind 0x07, 0xf0, 0xf8, 0x05
	pop xix
	jp MemConfig_VoiceSlotRet

MemConfig_VoiceSlotSkip:
	call VoiceSlot_ComputeWordIndex
	jp MemConfig_VoiceSlotCompare

MemConfig_VoiceSlotRet:
	ret

MemConfig_Handler_0:
	.incbin "includes/generated/v7_transplant_MemConfig_Handler_0.bin"
MemConfig_Handler_1:
	.incbin "includes/generated/v7_transplant_MemConfig_Handler_1.bin"
MemConfig_Handler_3:
	.incbin "includes/generated/v7_transplant_MemConfig_Handler_3.bin"
SndDispatch_JumpTable_Main:
	.long DefaultHandler_Ret
	.long SndDispatch_Handler_1
	.long SndDispatch_Handler_2
	.long SndDispatch_TableEntryBegin
	.long SndDispatch_ShortHandler
	.long SndDispatch_TableEntryBegin
	.long SndDispatch_TableEntryBegin
	.long SndDispatch_Handler_3
	.long SndDispatch_ShortHandler
	.long SndDispatch_Handler_3
	.long SndDispatch_Handler_4
SndDispatch_Handler_1:
	call	SndDispatch_ProcessCommand_0xF9
	call	SndDispatch_ProcessCommand_0xA5
	cps	a, 0
	jrl	z, 23
	dec	1, a
	xor	w, w
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_SubTable_1
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	call	(xhl)
	ret
SndDispatch_SubTable_1:
	.long SndDispatch_InitHandler
	.long SndDispatch_ProcessCommand
	.long SndDispatch_ProcessCommand
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
SndDispatch_Handler_2:
	call	SndDispatch_ProcessCommand_0xF9
	call	SndDispatch_ProcessCommand_0xA5
	cps	a, 0
	jrl	z, 23
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_SubTable_2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	call	(xhl)
	ret
SndDispatch_SubTable_2:
	.long SndDispatch_InitHandler
	.long SndDispatch_ProcessCommand
	.long SndDispatch_ProcessCommand
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
SndDispatch_TableEntryBegin:
	call	SndDispatch_ProcessCommand_0xF9
	call	SndDispatch_ProcessCommand_0xA5
	cps	a, 0
	jrl	z, 23
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	.byte 0x44
	.long SndDispatch_BytecodeString
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
	ret
SndDispatch_BytecodeString:
	.incbin "includes/generated/v7_transplant_SndDispatch_BytecodeString.bin"
SndDispatch_SubTable_3:
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SndDispatch_ProcessCommand
	.long SndDispatch_ProcessCommand
	.long DefaultHandler_Ret
SndDispatch_ShortHandler:
	call	SndDispatch_ProcessCommand
	ret
SndDispatch_Handler_3:
	call	SndDispatch_ProcessCommand_0xF9
	call	SndDispatch_ProcessCommand_0xA5
	cps	a, 0
	jrl	z, 23
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_SubTable_4
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	call	(xhl)
	ret
SndDispatch_SubTable_4:
	.long SndDispatch_CallAndInit
	.long SndDispatch_InitHandler
	.long SndDispatch_InitHandler
	.long SndDispatch_ProcessCommand
	.long SndDispatch_InitHandler
	.long DefaultHandler_Ret
SndDispatch_Handler_4:
	.incbin "includes/generated/v7_transplant_SndDispatch_Handler_4.bin"
SndDispatch_SubTable_5:
	.long SndDispatch_InitHandler
	.long SndDispatch_SetFlag30
	.long SndDispatch_ProcessCommand
	.long SndDispatch_SetFlag30
	.long DefaultHandler_Ret
SndDispatch_CallAndInit:
	call	VoiceSlot_SubrRetZ
	call	SndDispatch_InitHandler
	ret
SndDispatch_InitHandler:
	.byte 0xc1
	jr	gt, 13
	push	xsp
	nop
	jrl	nz, 5
	stdi8	(3415), 0
	ret
SndDispatch_SetFlag30:
	stdi8	(3415), 48
	ret
SndDispatch_ProcessCommand:
	.incbin "includes/generated/v7_transplant_SndDispatch_ProcessCommand.bin"
MemConfig_Handler_4:
	.incbin "includes/generated/v7_transplant_MemConfig_Handler_4.bin"
SysInit_SendAllNotesAndReset:
	.incbin "includes/generated/v7_transplant_SysInit_SendAllNotesAndReset.bin"
SystemInit_Handler_Table:
	.incbin "includes/generated/v7_transplant_SystemInit_Handler_Table.bin"
SystemInit_StepHandler_5:
	push	xwa
	push	xhl
	.ascii "9:<=>'"
	halt
	call	SystemInit_StepHandler_0_0x4B
	call	SysInit_BytecodeBlock_0xC
	pop	xiz
	.ascii "]\\ZY[X€»"
	.byte 0x04
	nop
	jp	SystemInit_Handler_Table_0x43
SystemInit_StepHandler_4:
	add	hl, 4
	jp	SystemInit_Handler_Table_0x43
SystemInit_StepHandler_3:
	call	SystemInit_StepHandler_0_0x19
	jp	SystemInit_StepHandler_0
SystemInit_StepHandler_2:
	call	MemConfig_Handler_0
	call	SysInit_SendAllNotesAndReset
	jp	SystemInit_StepHandler_0
SystemInit_StepHandler_0:
	.incbin "includes/generated/v7_transplant_SystemInit_StepHandler_0.bin"
SysInit_BytecodeBlock:
	.incbin "includes/generated/v7_transplant_SysInit_BytecodeBlock.bin"
VoiceSlot_InitAndProcess:
	cps bc, 0
	jrl nz, VoiceSlot_InitLoop
	jp VoiceSlot_RetNZ

VoiceSlot_InitLoop:
	ld xix, 0xc9e
	srl iz, 1
	ldfr_lerp XIX, 0x38
	stb_dri D, 0x07, 0xf0, 0xf8
	ld iy, (xix + 32)
	ldto_lerp XIX, 0x38
	sla iz, 1
	and iy, 0xff
	pushw bc
	add bc, iy
	cp bc, 0xff
	jrl ugt, VoiceSlot_ProcessEntry
	srl iz, 1
	ldfr_lerp XIX, 0x38
	stb_dri D, 0x07, 0xf0, 0xf8
	ld (xix + 32), c
	ldto_lerp XIX, 0x38
	sla iz, 1
	pushw iy
	ldw_sri IY, 0x07, 0xf0, 0xf8
	call VoiceSlot_UpdateCurrentPointer
	popw iy
	ldda32 xhl, (4349)
	extz xiy
	add xhl, xiy
	popw bc
	ld xix, xhl
	ldda32 xiy, (4353)
	ldir85
	jp VoiceSlot_RetNZ

VoiceSlot_ProcessEntry:
	ld de, bc
	ldw wa, 0x100
	ldw_sri IY, 0x07, 0xf0, 0xf8
	srl iz, 1
	stb_dri D, 0x07, 0xf0, 0xf8
	ld ix, (xix + 32)
	and ix, 0xff
	sub wa, ix
	ld bc, wa
	call VoiceSlot_UpdateCurrentPointer
	ldda32 xhl, (4349)
	extz xix
	add xhl, xix
	ld xix, xhl
	ldda32 xiy, (4353)
	adddm16 4353, xbc
	ldir85
	ld bc, de
	sub bc, 0xfb
	ld xix, 0xc9e
	ldfr_lerp XIX, 0x38
	stb_dri D, 0x07, 0xf0, 0xf8
	ld (xix + 32), c
	ldto_lerp XIX, 0x38
	sla iz, 1
	sub c, 0x5
	ldw_sri IY, 0x07, 0xf0, 0xf8
	call VoiceSlot_UpdateCurrentPointer
	ldda32 xhl, (4349)
	ld iy, (xhl + 3)
	call VoiceSlot_UpdateCurrentPointer
	ldda32 xhl, (4349)
	stw_dri IY, 0x07, 0xf0, 0xf8
	ld xix, xhl
	add xix, 0x5
	ldda32 xiy, (4353)
	cps bc, 0
	jrl z, VoiceSlot_CheckDone
	ldir85

VoiceSlot_CheckDone:
	popw bc

VoiceSlot_RetNZ:
	ret

VoiceSlot_RetZ:
	ld	c, w
	call	VoiceSlot_ComputeWordIndex
	ld	xix, 3230
	.byte 0xd3
	reti
	.byte 0xf0
	swi	0
	ldb	e, 241
	.byte 0x9f
	pushw	wa
	.byte 0x55
	srl	iz, 1
	.byte 0xe7
	push	xwa
	.byte 0x9c, 0xf3
	reti
	.byte 0xf0
	swi	0
	ldw	ix, 8332
	ldb	a, 231
	push	xwa
	.byte 0x8c
	xor	w, w
	sla	iz, 1
	stda16	(0x28b6), wa
	xor	b, b
	add	wa, bc
	cp	wa, 255
	jrl	ugt, 12
	stda16	(0x28ba), iy
	stda16	(0x28bc), wa
	jp	VoiceSlot_RetZ_0x58
	call	VoiceSlot_UpdateCurrentPointer
	ldda32	xhl, (4349)
	ld	iy, (xhl+3)
	sub	wa, 251
	jp	VoiceSlot_RetZ_0x39
	ld	xix, 0xf1f8
	.byte 0xd3
	reti
	.byte 0xf0
	swi	0
	ldb	b, 222
	.byte 0xef, 0x01, 0xe7
	push	xwa
	.byte 0x9c, 0xf3
	reti
	.byte 0xf0
	swi	0
	ldw	ix, 8332
	ldb	a, 231
	push	xwa
	.byte 0x8c
	xor	w, w
	sla	iz, 1
	.byte 0xf1, 0xb8
	.ascii "(P8;9:<=>"
	call	Scoop_EventHandler_SpecialMode
	pop	xiz
	.ascii "]\\ZY[X"
	sub	wa, bc
	cps	wa, 4
	jrl	le, 24
	srl	iz, 1
	.byte 0xe7
	push	xwa
	.byte 0x9c, 0xf3
	reti
	.byte 0xf0
	swi	0
	ldw	ix, 8380
	ld	xbc, 0xde8c38e7
	.byte 0xec, 0x01
	jp	VoiceSlot_RetZ_0xF8
	cp	wa, 0xffff
	jrl	le, 7
	add	a, 251
	jp	VoiceSlot_RetZ_0xBF
	sub	wa, 5
	ld	iy, de
	call	VoiceSlot_UpdateCurrentPointer
	ldda32	xhl, (4349)
	ld	de, (xhl+1)
	.byte 0xf3
	reti
	.byte 0xf0
	swi	0
	.byte 0x52
	ld	iy, de
	call	VoiceSlot_UpdateCurrentPointer
	ldda32	xhl, (4349)
	srl	iz, 1
	.byte 0xe7
	push	xwa
	.byte 0x9c, 0xf3
	reti
	.byte 0xf0
	swi	0
	ldw	ix, 8380
	ld	xbc, 0xde8c38e7
	.byte 0xec, 0x01
	ld	iy, (xhl+3)
	lds	wa, 1
	call	VoiceSlot_FinalRetZ_0x1B2
	ret

VoiceSlot_LoadAndDispatch:
	call VoiceSlot_FlagCheck
	cp w, 0xff
	jrl z, VoiceSlot_ReadParamsErrExit
	cp a, 0x82
	jrl z, VoiceSlot_ReadParamsErrExit
	call VoiceSlot_ReadCurrentParams
	cp a, 0x84
	jrl z, VoiceSlot_ReadParamsErrExit
	ldb w, 0x0
	call VoiceSlot_CompareRet
	jp VoiceSlot_DispatchDone

VoiceSlot_ReadParamsErrExit:
	ldb w, 0xff

VoiceSlot_DispatchDone:
	ret

VoiceSlot_DispatchRet:
	push_sd16w 0x58, 0x0d
	call VoiceSlot_LoadAndDispatch
	popw_dd16 0x58, 0x0d
	ret

VoiceSlot_CompareAndBranch:
	ldb	w, 1
	call	VoiceSlot_CompareRet
	ret
	.byte 0xd1
	pop	xwa
	decf
	.byte 0x04
	call	VoiceSlot_CompareAndBranch
	.byte 0xf1
	pop	xwa
	decf
	.byte 0x06
	ret

VoiceSlot_CompareRet:
	ld h, w
	call VoiceSlot_ComputeWordIndex
	pushw bc
	xor c, c
	ld b, h
	push xix
	ld xix, 0xc9e
	ldw_sri IY, 0x07, 0xf0, 0xf8
	pop xix
	call VoiceSlot_UpdateCurrentPointer
	ldda32 xhl, (4349)
	srl iz, 1
	push xde
	ld xde, 0xcbe
	ldw_sri IX, 0x07, 0xe8, 0xf8
	pop xde
	and ix, 0xff
	sla iz, 1
	cps b, 0
	jrl nz, VoiceSlot_DecCountLoop

VoiceSlot_StoreAndAdvance:
	inc 1, ix
	cp ix, 0xff
	jrl ugt, VoiceSlot_LoadFromTableBody
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, c
	cp a, 0x81
	jrl z, VoiceSlot_CopyBlockDone
	call VoiceSlot_StatusCheck
	cp w, 0xff
	jrl z, VoiceSlot_StoreAndAdvance

VoiceSlot_CopyBlock:
	ld wa, ix
	push xde
	ld xde, 0xc9e
	stw_dri IY, 0x07, 0xe8, 0xf8
	srl iz, 1
	ld xde, 0xcbe
	lda_dri XBC, 0x07, 0xe8, 0xf8
	pop xde
	sla iz, 1
	xor w, w
	stb_d8 (3532), c
	popw bc
	jp VoiceSlot_SubrRetNZ

VoiceSlot_CopyBlockDone:
	pushw wa
	pushw bc
	push xhl
	push xix
	push xiy
	push xiz
	call VoiceSlot_FlagCheckBody
	cp w, 0xff
	jrl z, VoiceSlot_LoadFromTable
	cp a, 0x82
	jrl z, VoiceSlot_LoadFromTable
	incdi16 1, (3416)

VoiceSlot_LoadFromTable:
	pop xiz
	pop xiy
	pop xix
	pop xhl
	popw bc
	popw wa
	jp VoiceSlot_CopyBlock

VoiceSlot_LoadFromTableBody:
	push xde
	ld xde, 0xc9e
	ldw_sri IY, 0x07, 0xe8, 0xf8
	pop xde
	call VoiceSlot_UpdateCurrentPointer
	ldda32 xhl, (4349)
	ld iy, (xhl + 3)
	cp iy, 0xffff
	jrl z, VoiceSlot_SubrDone
	call VoiceSlot_UpdateCurrentPointer
	ldda32 xhl, (4349)
	lds ix, 4
	jp VoiceSlot_StoreAndAdvance

VoiceSlot_DecCountLoop:
	dec 1, ix
	cps ix, 4
	jrl le, VoiceSlot_SubroutineBody
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, c
	cp a, 0x81
	jrl z, VoiceSlot_SubroutineTable
	call VoiceSlot_StatusCheck
	cp w, 0xff
	jrl z, VoiceSlot_DecCountLoop

VoiceSlot_CallSubroutine:
	ld wa, ix
	push xde
	ld xde, 0xc9e
	stw_dri IY, 0x07, 0xe8, 0xf8
	srl iz, 1
	ld xde, 0xcbe
	lda_dri XBC, 0x07, 0xe8, 0xf8
	pop xde
	sla iz, 1
	xor w, w
	stb_d8 (3532), c
	popw bc
	jp VoiceSlot_SubrRetNZ

VoiceSlot_SubroutineTable:
	call VoiceSlot_SubrRetZ
	jp VoiceSlot_CallSubroutine

VoiceSlot_SubroutineBody:
	push xde
	ld xde, 0xc9e
	ldw_sri IY, 0x07, 0xe8, 0xf8
	pop xde
	call VoiceSlot_UpdateCurrentPointer
	ldda32 xhl, (4349)
	ld iy, (xhl + 1)
	cps iy, 0
	jrl z, VoiceSlot_SubrDone
	call VoiceSlot_UpdateCurrentPointer
	ldda32 xhl, (4349)
	ldw ix, 0x100
	jp VoiceSlot_DecCountLoop

VoiceSlot_SubrDone:
	ldb w, 0xff
	popw bc

VoiceSlot_SubrRetNZ:
	ret

VoiceSlot_SubrRetZ:
	push xiy
	ld xiy, 0xd58
	cpw (xiy), 0x0
	jrl z, VoiceSlot_AdvancePointer
	decm 1, (xiy)

VoiceSlot_AdvancePointer:
	pop xiy
	ret

VoiceSlot_ReadCurrentParams:
	call VoiceSlot_ComputeWordIndex
	push xde
	ld xde, 0xc9e
	ldw_sri IY, 0x07, 0xe8, 0xf8
	pop xde
	call VoiceSlot_UpdateCurrentPointer
	ldda32 xhl, (4349)
	srl iz, 1
	push xde
	ld xde, 0xcbe
	ldw_sri IY, 0x07, 0xe8, 0xf8
	pop xde
	sla iz, 1
	and iy, 0xff
	ldb_sri A, 0x07, 0xec, 0xf4
	xor w, w
	ret

VoiceSlot_FlagCheck:
	stdi16 (3573), 1
	call VoiceSlot_FlagCheckDone
	ret

VoiceSlot_FlagCheckBody:
	stdi16 (3573), 2
	call VoiceSlot_FlagCheckDone
	ret

VoiceSlot_FlagCheckDone:
	call VoiceSlot_ComputeWordIndex
	xor w, w
	push xde
	ld xde, 0xc9e
	ldw_sri IY, 0x07, 0xe8, 0xf8
	pop xde
	call VoiceSlot_UpdateCurrentPointer
	ldda32 xhl, (4349)
	srl iz, 1
	push xde
	ld xde, 0xcbe
	ldw_sri IY, 0x07, 0xe8, 0xf8
	pop xde
	sla iz, 1
	and iy, 0xff
	addda16 xiy, 3573
	cp iy, 0xff
	jrl ugt, VoiceSlot_FinalCheck
	ldb_sri A, 0x07, 0xec, 0xf4
	jp VoiceSlot_FinalRetNZ

VoiceSlot_FinalCheck:
	ld iy, (xhl + 3)
	cp iy, 0xffff
	jrl z, VoiceSlot_FinalDone
	call VoiceSlot_UpdateCurrentPointer
	ldda32 xhl, (4349)
	lds iy, 5
	ldb_sri A, 0x07, 0xec, 0xf4
	jp VoiceSlot_FinalRetNZ

VoiceSlot_FinalDone:
	ldb w, 0xff

VoiceSlot_FinalRetNZ:
	ret

VoiceSlot_FinalRetZ:
	.incbin "includes/generated/v7_transplant_VoiceSlot_FinalRetZ.bin"
VoiceSlot_UpdateCurrentPointer:
	ld hl, iy
	dec 1, hl
	extz xhl
	sla xhl, 8
	addda32 xhl, 7514
	stda32 4349, xhl
	xor xhl, xhl
	ret

VoiceSlot_ComputeWordIndex:
	pushw wa
	ldb_d8 a, (3822)
	dec 1, a
	xor w, w
	sla wa, 1
	ld iz, wa
	extz xiz
	popw wa
	ret

VoiceSlot_ComputeIndex:
	pushw wa
	ldb_d8 a, (3822)
	dec 1, a
	ld w, a
	sla a, 1
	add a, w
	xor w, w
	ld iz, wa
	extz xiz
	popw wa
	ret

VoiceSlot_IndexDone:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IndexDone.bin"
VoiceSlot_StatusCheck:
	bit 7, a
	jrl z, VoiceSlot_SetFFAndContinue
	cp a, 0x83
	jrl z, VoiceSlot_SetFFAndContinue
	cp a, 0x90
	jrl nc, VoiceSlot_StatusActive
	cp a, 0x86
	jrl ugt, VoiceSlot_SetFFAndContinue

VoiceSlot_StatusActive:
	cp a, 0xd3
	jrl ugt, VoiceSlot_SetFFAndContinue
	ld w, a
	and w, 0xf0
	cp w, 0xa0
	jrl z, VoiceSlot_SetFFAndContinue
	ldb w, 0x0
	jp VoiceSlot_StatusDone

VoiceSlot_SetFFAndContinue:
	ldb w, 0xff

VoiceSlot_StatusDone:
	ret

VoiceSlot_StatusRet:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StatusRet.bin"
VoiceState_SaveAndRestore:
	.incbin "includes/generated/v7_transplant_VoiceState_SaveAndRestore.bin"
VoiceSlot_SaveState:
	pushw wa
	push xhl
	push xiz
	push xiy
	and a, 0x7
	sla a, 3
	xor w, w
	exts xwa
	add xwa, 0xdff
	ld xhl, xwa
	call VoiceSlot_ComputeWordIndex
	ld xiy, 0xc9e
	ldw_sri WA, 0x07, 0xf4, 0xf8
	ld (xhl), wa
	srl iz, 1
	ldfr_lerp XIY, 0x38
	stb_dri E, 0x07, 0xf4, 0xf8
	ld a, (xiy + 32)
	ldto_lerp XIY, 0x38
	ld (xhl + 2), a
	ldb_d8 a, (3415)
	ld (xhl + 3), a
	ldw_d16 xwa, (3416)
	ld (xhl + 4), wa
	ldw_d16 xwa, (3418)
	ld (xhl + 6), wa
	pop xiy
	pop xiz
	pop xhl
	popw wa
	ret

VoiceSlot_RestoreState:
	pushw wa
	push xhl
	push xiz
	push xiy
	call VoiceState_RestoreEntry
	call VoiceState_RestoreDone
	pop xiy
	pop xiz
	pop xhl
	popw wa
	ret

VoiceState_DataBlock1:	.ascii "(;>="
	call	VoiceState_RestoreEntry
	ld	a, (xhl+3)
	stb_d8	(3415), a
	call	VoiceState_RestoreDone
	pop	xiy
	pop	xiz
	pop	xhl
	popw	wa
	ret

VoiceState_RestoreEntry:
	xor w, w
	and a, 0x7
	sla a, 3
	exts xwa
	add xwa, 0xdff
	ld xhl, xwa
	call VoiceSlot_ComputeWordIndex
	ld xiy, 0xc9e
	ld wa, (xhl)
	stw_dri WA, 0x07, 0xf4, 0xf8
	srl iz, 1
	ld a, (xhl + 2)
	ldfr_lerp XIY, 0x38
	stb_dri E, 0x07, 0xf4, 0xf8
	ld (xiy + 32), a
	ldto_lerp XIY, 0x38
	ret

VoiceState_RestoreDone:
	ld wa, (xhl + 4)
	stda16 (3416), xwa
	ld wa, (xhl + 6)
	stda16 (3418), xwa
	ret

VoiceState_DataBlock2:
	.incbin "includes/generated/v7_transplant_VoiceState_DataBlock2.bin"
SubCPU_ToneParamDisplay:
	.incbin "includes/generated/v7_transplant_SubCPU_ToneParamDisplay.bin"
SubCPU_ToneDispatch:
	ret_cc_ri xiz, 9
	nop
	nop
	.byte 0xea
	swi	1
	nop
	nop
	.byte 0xd0
	swi	1
	nop
	nop
	jr	nov, -6
	nop
	nop
	cp	(xiz), b
	nop
	nop
	cp	(xwa), xde
	nop
	nop
	ld	(xde-6), 0
	.byte 0xd4
	swi	2
	nop
	nop
	calr	250
	nop
	push	xwa
	swi	2
	nop
	nop
	.byte 0x52
	swi	2
	nop
	nop
	.byte 0x04
	swi	2
	nop
	nop
	push	xix
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	swi	7
	swi	7
	.byte 0xee
	swi	2
	nop
	nop
	ldio	251, 0
	nop
	ldb	b, 251
	nop
	nop
	ldio	9, 10
	pushw	0xd7cf
	bit	7, w
	jrl	nz, 2
	ldb	l, 3
	cpdm8	4380, l
	jrl	z, 28
	ldb_d8	a, (4380)
	xor	l, l
	ldb	h, 3
	call	SubCPU_ToneStoreDigits
	stb_d8	(4380), a
	call	SubCPU_ToneParamDisplay_0x9F
	call	SubCPU_ToneParamDisplay_0xE3
	call	SubCPU_ToneParamDisplay_0x4E
	ret
SubCPU_ToneHandler_A:
	.incbin "includes/generated/v7_transplant_SubCPU_ToneHandler_A.bin"
SubCPU_ToneHandler_B:
	cpdi8	(4380), 3
	jrl nz, SubCPU_ToneLoadAndStore
	ldb h, 0x0c
	jp SubCPU_CallRoutine
SubCPU_ToneLoadAndStore:
	cpdi8	(4380), 2
	jrl nz, SubCPU_CallRoutine
	ldb h, 0xff
SubCPU_CallRoutine:
	call PerfMode_VoiceAddressTable_0x50
	stb_d8	(4381), a
	call SubCPU_ToneParamDisplay_0xE3
	call SubCPU_ToneParamDisplay_0x4E
	ret
SubCPU_ToneStoreDigits:
	; --- Clamp/adjust: inc/dec A within [L..H] based on W bit 7 (34 bytes) ---
	bit 0x07, w
	jrl nz, SubCPU_ToneFormatValue
	cp a, h
	jrl nc, PerfMode_NullRet
	inc 1, a
	cp a, h
	jrl ule, PerfMode_NullRet
	ld a, h
	jp PerfMode_NullRet
SubCPU_ToneFormatValue:
	dec 1, a
	cp a, l
	jrl ge, PerfMode_NullRet
	ld a, l
PerfMode_NullRet:
	ret


SubCPU_ToneFormatDone:
	bit	7, w
	jrl	z, 4
	jp	SubCPU_ToneClearRegion_0x62
	ldb_d8	w, (3538)
	ldb	w, 6
	ld	xiy, 4382
	call	SysInit_BytecodeBlock_0x486
SubCPU_ToneClearRegion:
	.incbin "includes/generated/v7_transplant_SubCPU_ToneClearRegion.bin"
PerfMode_ParamHandler_11:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, 17
	sla	hl, 2
	push	xix
	ld	xix, SubCPU_ToneParamRet
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	call	(xhl)
	ret
SubCPU_ToneParamRet:
	.incbin "includes/generated/v7_transplant_SubCPU_ToneParamRet.bin"
OscScope_HandlerTable:
	.incbin "includes/generated/v7_transplant_OscScope_HandlerTable.bin"
SndHandler_DefaultRet:
	ret
OscScope_Handler_2:
	call	OscScope_Handler_7_0x5
	ret
OscScope_Handler_3:
	call	OscScope_Handler_7_0x5
	ret
OscScope_Handler_4:
	call	OscScope_Handler_7_0x5
	ret
OscScope_Handler_6:
	call	OscScope_Handler_7_0x5
	ret
OscScope_Handler_7:
	call	OscScope_Handler_7_0x5
	ret
	ldda32	xix, (4372)
	ldb_d8	e, (3780)
	sla	e, 2
	xor	d, d
	extz	xde
	add	xix, xde
	.byte 0x84
	push	xix
	.byte 0xdf, 0x84
	push	xiz
	ld	xwa, 0x1114e10e
	ldb	d, 193
	.byte 0xc4
	ret
	ldb	e, 205
	.byte 0xec
	push	sr
	xor	d, d
	extz	xde
	add	xix, xde
	xor	de, de
	ld	(xix), e
	ld	(xix+1), a
	ld	(xix+2), de
	ret
	pushw	wa
	push	xhl
	ldb_d8	a, (3770)
	ldb	w, 96
	muls8rr	a, w
	ldb_d8	l, (3769)
	xor	h, h
	add	wa, hl
	.byte 0xf1, 0xc2
	ret
OscScope_DrawWaveform:
	.byte 0x50
	pop	xhl
	popw	wa
	ret
	.byte 0xc1
	jrl	f, 16143
	ldw	wa, 0x747e
	nop
	ldw_d16	wa, (3778)
	ldb_d8	l, (3952)
	xor	h, h
	sub	wa, hl
OscScope_UpdateDisplay:
	cp	wa, 48
	jrl	z, 78
	ldb	l, 96
	div8rr	a, l
	cp	w, 48
	jrl	z, 23
	exts	wa
	ld	bc, wa
	pushw	bc
	call	DisplayStr_BytecodeBlock_A_0x53
	popw	bc
	djnz16	bc, -9
	stdi16	(3778), 0
	jp	OscScope_RefreshLoop_0x3F
	ldw_d16	wa, (3778)
	ldb	l, 96
	div8rr	a, l
	cps	a, 0
	jrl	z, 32
	ld	c, a
	ldb	l, 96
	muls8rr	a, l
	.byte 0xd1
	adddm8_24	(0xcba80e), a
	dec	1, a
	cps	a, 0
	jrl	z, 13
	exts	wa
	ld	bc, wa
	pushw	bc
	call	DisplayStr_BytecodeBlock_A_0x53
	popw	bc
	djnz16	bc, -9
	call	DisplayStr_BytecodeBlock_A_0x120
	stdi16	(3778), 0
	stdi8	(3952), 0
	jp	OscScope_RefreshLoop_0x3F
OscScope_RefreshLoop:
	ldw_d16	wa, (3778)
	ldb	l, 96
	div8rr	a, l
	ld	c, a
	ld	e, w
	cps	c, 0
	jrl	z, 29
	ldb	a, 96
	muls8rr	a, c
	.byte 0xd1
	xorda8_24	b, (0xcaa80e)
	pushw	bc
	pushw	de
	call	DisplayStr_BytecodeBlock_A_0x53
	popw	de
	popw	bc
	.byte 0xc1, 0xf6
	ret
	push	xsp
	nop
	jrl	nz, 20
	djnz16	bc, -19
	cps	e, 0
	jrl	z, 12
	.byte 0xc1
	jrl	f, 16143
	ldw	wa, 1142
	nop
	call	DisplayStr_BytecodeBlock_A_0x120
	ret
	push	xhl
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, 105
	ldb	a, 7
	call	VoiceSlot_SaveState
	xor	bc, bc
	ldb_d8	l, (3822)
	xor	h, h
	dec	1, hl
	sla	hl, 1
	push	xde
	ld	xde, 3230
	.byte 0xd3
	reti
	sla	xwa, 32
	pop	xde
	cp	wa, 0xffff
	jrl	z, 52
	cps	wa, 0
	jrl	z, 47
	push	xhl
	push	xbc
	push	xde
	push	xiy
	push	xix
	push	xiz
	call	VoiceSlot_FinalRetZ
	pop	xiz
	pop	xix
	pop	xiy
	pop	xde
	pop	xbc
	pop	xhl
	inc	1, bc
	cps	c, 2
	jrl	ugt, 18
	cp	a, 129
	jrl	z, -29
	cp	a, 130
	jrl	z, 12
OscScope_RenderBlock:
	cp	a, 132
	jrl	z, 6
	ldb	w, 255
	jp	OscScope_RenderBlock_0xE
	ldb	w, 0
	pop	xhl
	pushw	wa
	ldb	a, 7
	call	VoiceSlot_RestoreState
	popw	wa
	jp	OscScope_RenderBlock_0x20
	lds	bc, 2
	pop	xhl
	ldb	w, 255
	ret
	call	OscScope_RenderBlock_0x2E
	call	OscScope_RenderBlock_0x3F
	call	OscScope_RenderBlock_0x50
	ret
	ld	xix, 3669
	ldw	bc, 16
	xor	wa, wa
	.byte 0xf5, 0xf1, 0x50
	djnz16	bc, -6
	ret
	ld	xix, 3701
	ldw	bc, 16
	xor	wa, wa
	.byte 0xf5, 0xf1, 0x50
	djnz16	bc, -6
	ret
	ld	xix, 3733
	ldw	bc, 16
	xor	wa, wa
	.byte 0xf5, 0xf1, 0x50
	djnz16	bc, -6
	ret
	ld	xiy, 3669
	.byte 0x44
	pop	xbc
OscScope_FinalizeRender:
	.incbin "includes/generated/v7_transplant_OscScope_FinalizeRender.bin"
VoiceBank_ProcessCommand:
	ld xix, 0xeb5
	call VoiceBank_LoadLerpState
	lda_dpi XBC, 0xf0
	cp a, 0x81
	jrl z, VoiceBank_CallAndReturn
	cp a, 0x82
	jrl z, VoiceBank_CallAndReturn
	cp a, 0x84
	jrl nz, VoiceBank_CallAndLoop

VoiceBank_CallAndReturn:
	call VoiceBank_UpdateLerpState
	jp VoiceBank_Ret

VoiceBank_CallAndLoop:
	call VoiceBank_UpdateLerpState
	call VoiceBank_LoadLerpState
	bit 7, a
	jrl nz, VoiceBank_Ret
	lda_dpi XBC, 0xf0
	jp VoiceBank_CallAndLoop

VoiceBank_Ret:
	ret

VoiceBank_LoadLerpState:
	push xiz
	ldda32 xiz, (4349)
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	push xix
	ldw_d16 xhl, (0x28bf)
	call DisplayStr_ComputeTableAddr
	ldda32 xiy, (4349)
	ldw_d16 xix, (0x28c1)
	ldb_sri A, 0x07, 0xf4, 0xf0
	pop xix
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	ret

VoiceBank_UpdateLerpState:
	push xiz
	ldda32 xiz, (4349)
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	push xix
	ldw_d16 xwa, (0x28c1)
	cp wa, 0xff
	jrl nz, VoiceBank_IncrementIndex
	ldw_d16 xhl, (0x28bf)
	call DisplayStr_ComputeTableAddr
	ldda32 xhl, (4349)
	ld hl, (xhl + 3)
	stda16 (0x28bf), xhl
	lds wa, 5
	jp VoiceBank_StoreIndex

VoiceBank_IncrementIndex:
	inc 1, wa

VoiceBank_StoreIndex:
	stda16 (0x28c1), xwa
	pop xix
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	ret

DisplayStr_BytecodeBlock_A:
	.incbin "includes/generated/v7_transplant_DisplayStr_BytecodeBlock_A.bin"
DisplayStr_ComputeTableAddr:
	dec 1, hl
	extz xhl
	sla xhl, 8
	addda32 xhl, 7514
	stda32 4349, xhl
	xor xhl, xhl
	ret

DisplayStr_BytecodeBlock_B:
	.incbin "includes/generated/v7_transplant_DisplayStr_BytecodeBlock_B.bin"
DisplayStr_RhythmLabel:
	.incbin "includes/generated/v7_transplant_DisplayStr_RhythmLabel.bin"
DisplayStr_BytecodeBlock_C:
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_0x32D
	.byte 0x45
	.long DisplayStr_RhythmLabel
	ld	xix, 3791
	ldw	bc, 9
	ldir85
	call	Display_UpdateRegion5
	call	DisplayStr_RhythmLabel_0x92
	call	Display_UpdateRegion3
	ret
	call	Display_BytecodeBlock_F_0x32D
	ld	xix, 3786
	ld	xiy, DisplayStr_BytecodeBlock_C_0x5E
	cpdi8	(0xfc5a), 7
	jrl	nz, 13
	cpdi8	(0xfc5b), 2
	jrl	nz, 5
	ld	xiy, DisplayStr_BytecodeBlock_C_0x77
	ld	xix, 3791
	ldw	bc, 25
	ldir85
	call	Display_UpdateRegion5
	call	Display_BytecodeBlock_F_0x2A2
	call	Display_UpdateRegion3
	ret
	ldb	w, 32
	.byte 0x54
	.ascii "EMPO  "
	pop_a
	push	xiy
	.ascii "                TEMPO  ì=              "
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_0x32D
	.byte 0x45
	.long DisplayStr_TempoString
	.byte 0xc1
	pop	xde
	swi	4
	push	xsp
	reti
	jrl	nz, 13
	.byte 0xc1
	pop	xhl
	swi	4
	push	xsp
	push	sr
	jrl	nz, 5
	ld	xiy, DisplayStr_TempoString_0x19
	ld	xix, 3791
	ldw	bc, 25
	.byte 0x85
	scf
	call	Display_UpdateRegion5
	call	Display_BytecodeBlock_F_0x2A2
	call	Display_UpdateRegion3
	ret
DisplayStr_TempoString:
	.incbin "includes/generated/v7_transplant_DisplayStr_TempoString.bin"
DisplayStr_FillDashes:
	ld xix, 0xeca
	ldb a, 0x2d
	ld (xix), a
	ld (xix + 1), a
	ld (xix + 2), a
	ret

DisplayStr_BytecodeBlock_D:
	.incbin "includes/generated/v7_transplant_DisplayStr_BytecodeBlock_D.bin"
DisplayStr_ClearRegion:
	pushw wa
	pushw bc
	push xix
	ld xix, 0xecd
	ldw bc, 0x1b
	ldb a, 0x20

DisplayStr_ClearLoop:
	lda_dpi XBC, 0xf0
	djnz xbc, DisplayStr_ClearLoop
	pop xix
	popw bc
	popw wa
	ret

DisplayStr_StyleSectionInit:
	.incbin "includes/generated/v7_transplant_DisplayStr_StyleSectionInit.bin"
DisplayStr_StyleClearLoop:
	lda_dpi XBC, 0xf0
	djnz xbc, DisplayStr_StyleClearLoop
	call Display_UpdateRegion3
	ret

DisplayStr_BytecodeBlock_E:
	.incbin "includes/generated/v7_transplant_DisplayStr_BytecodeBlock_E.bin"
DisplayStr_StyleSectionNames:	.ascii "        START   STOP    FILL IN1FILL IN2INTRO1  COUNT INENDING1 END     REPEAT  CLEAR   ENDING2 INTRO2  "
	ret
	call	Display_UpdateRegion2
	ret

Display_RedrawMenu:
	.incbin "includes/generated/v7_transplant_Display_RedrawMenu.bin"
Display_RedrawMenu_Extract:
	.incbin "includes/generated/v7_transplant_Display_RedrawMenu_Extract.bin"
Display_RedrawMenu_Update:
	call Display_UpdateRegion3
	ret

Display_BytecodeBlock_F:
	.incbin "includes/generated/v7_transplant_Display_BytecodeBlock_F.bin"
SNS_Init_Startup:
	ld xix, 0xed4
	call SNS_LoadKeyAndChord
	call SNS_LoadDurationData
	ret

SNS_LoadKeyAndChord:
	xor xhl, xhl
	ldb_d8 l, (3437)
	and l, 0xf
	sla hl, 1
	ld xiy, StringData_KeyNames
	stb_dri E, 0x07, 0xf4, 0xec
	ld wa, (xiy)
	ld (xix), wa
	xor hl, hl
	ldb_d8 l, (3438)
	and l, 0x3f
	ldb a, 0x5
	muls8rr a, l
	ld hl, wa
	extz xhl
	ld xiy, StringData_KeyNames_0x20
	stb_dri E, 0x07, 0xf4, 0xec
	ld wa, (xiy)
	ld (xix + 2), wa
	ld wa, (xiy + 2)
	ld (xix + 4), wa
	ld a, (xiy + 4)
	ld (xix + 6), a
	ret

SNS_LoadDurationData:
	ldw wa, 0x2020
	ld (xix + 7), wa
	ld (xix + 10), wa
	xor hl, hl
	ld xix, 0xedd
	ldb_d8 l, (3425)
	sla hl, 2
	ld xiy, StringData_KeyNames_0x160
	stb_dri E, 0x07, 0xf4, 0xec
	ld wa, (xiy)
	ld (xix), wa
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ret

StringData_KeyNames:
	.incbin "includes/generated/v7_transplant_StringData_KeyNames.bin"
StringData_PartNames:	.ascii "RT1 RT2 LFT P 4 P 5 P 6 P 7 P 8 P 9 P10 P11 P12 P13 P14 P15 KBP AC1 AC2 AC3 XXXXDRUM"
	.byte 0xc1, 0xef
	decf
	push	xsp
	ldwio	118, 9
	stdi8	(3567), 10
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ldb_d8	l, (4337)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xd144
	ret
	nop
	nop
	lds	bc, 4
	.byte 0x85
	scf
	ld	xiy, StringData_PartNames_0xAC
	inc	1, xix
	lds	bc, 7
	.byte 0x85
	scf
	ldb_d8	a, (4339)
	xor	w, w
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ld	xiy, 4481
	inc	1, xix
	lds	bc, 3
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.byte 0x50
	ld	xbc, 0x544f504e
	push	xiy
	.byte 0xc1, 0xef
	decf
	push	xsp
	ldwio	118, 9
	stdi8	(3567), 10
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ldb_d8	l, (4337)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xcf44
	ret
	nop
	nop
	lds	bc, 4
	.byte 0x85
	scf
	ld	xiy, StringData_PartNames_0x116
	inc	1, xix
	ldw	bc, 10
	.byte 0x85
	scf
	ldb_d8	a, (4339)
	xor	w, w
	ldw	de, 64
	push	xix
	call	ParamDigit_CalrData
	pop	xix
	inc	1, xix
	ldb_d8	a, (4480)
	.byte 0xf5, 0xf0
	ld	xbc, 0x118145
	nop
	lds	bc, 3
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	popw	hl
	.byte 0x45
	.ascii "Y SHIFT="
	.byte 0xc1, 0xef
	decf
	push	xsp
	ldwio	118, 9
	stdi8	(3567), 10
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ldb_d8	l, (4337)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xcf44
	ret
	nop
	nop
	lds	bc, 4
	.byte 0x85
	scf
	ld	xiy, StringData_PartNames_0x182
	inc	1, xix
	lds	bc, 7
	.byte 0x85
	scf
	ldb_d8	a, (4339)
	xor	w, w
	ldw	de, 128
	push	xix
	call	ParamDigit_CalrData
	pop	xix
	inc	1, xix
	ldb_d8	a, (4480)
	.byte 0xf5, 0xf0
	ld	xbc, 0x118145
	nop
	lds	bc, 3
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.ascii "TUNING=US1 US2 US3 BAS P 8 P 9 P10 LS1 LS2 LS3 P11 P12 P13 P14 P15 KBP "
	.byte 0xc1, 0xef
	decf
	push	xsp
	ldwio	118, 9
	stdi8	(3567), 10
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ldb_d8	l, (4337)
	xor	h, h
	sla	hl, 2
	.byte 0x45
	.long StringData_PartNames
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xcf44
	ret
	nop
	nop
	lds	bc, 4
	.byte 0x85
	scf
	ld	xiy, StringData_PartNames_0x222
	inc	1, xix
	ldw	bc, 10
	.byte 0x85
	scf
	ldb_d8	a, (4339)
	xor	w, w
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	inc	1, xix
	ld	xiy, 4482
	lds	bc, 2
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.ascii "BEND SENS="
	.byte 0xc1, 0xef
	decf
	push	xsp
	.byte 0x01
	jrl	z, 9
	stdi8	(3567), 1
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ldb_d8	l, (4337)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xcf44
	ret
	nop
	nop
	lds	bc, 4
	.byte 0x85
	scf
	ld	xiy, StringData_PartNames_0x287
	inc	1, xix
	ldw	bc, 8
	.byte 0x85
	scf
	.byte 0xdb
	and	(xix+4339), hl
	jrl	nz, 2
	ldb	l, 4
	ld	xiy, StringData_PartNames_0x28F
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xacd9
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.byte 0x53
	.ascii "USTAIN ON  OFF ¡"
	.byte 0xef
	decf
	push	xsp
	.byte 0x01
	jrl	z, 9
	stdi8	(3567), 1
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ldb_d8	l, (4337)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xcf44
	ret
	nop
	nop
	lds	bc, 4
	.byte 0x85
	scf
	ld	xiy, StringData_PartNames_0x2EB
	inc	1, xix
	ldw	bc, 11
	.byte 0x85
	scf
	xor	hl, hl
	ldb	l, 4
	ld	xiy, StringData_PartNames_0x28F
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xacd9
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.ascii "DSP EFFECT ¡Ô"
	decf
	push	xsp
	.byte 0x01
	jrl	z, 9
	stdi8	(3567), 1
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ldb_d8	l, (4337)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xcf44
	ret
	nop
	nop
	lds	bc, 4
	.byte 0x85
	scf
	.byte 0x45
	.long StringData_EffectLabel
	inc	1, xix
	lds	bc, 7
	.byte 0x85
	scf
	.byte 0xdb
	and	(xix+4339), iz
	jrl	nz, 2
	ldb	l, 4
	ld	xiy, StringData_PartNames_0x28F
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xacd9
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
StringData_EffectLabel:	.ascii "EFFECT "
	.byte 0xc1, 0xef
	decf
	push	xsp
	.byte 0x01
	jrl	z, 9
	stdi8	(3567), 1
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ldb_d8	l, (4337)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xcf44
	ret
	nop
	nop
	lds	bc, 4
	.byte 0x85
	scf
	ld	xiy, StringData_EffectLabel_0x5C
	inc	1, xix
	ldw	bc, 11
	.byte 0x85
	scf
	xor	w, w
	ldb_d8	a, (4339)
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	lds	bc, 3
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.ascii "DSP EFFECT=¡"
	.byte 0xef
	decf
	push	xsp
	.byte 0x01
	jrl	z, 9
	stdi8	(3567), 1
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ldb_d8	l, (4337)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xcf44
	ret
	nop
	nop
	lds	bc, 4
	.byte 0x85
	scf
	ld	xiy, StringData_EffectLabel_0xBB
	inc	1, xix
	lds	bc, 7
	.byte 0x85
	scf
	xor	w, w
	ldb_d8	a, (4339)
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	lds	bc, 3
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.byte 0x52
	ld	xiy, 0x42524556
	push	xiy
	.byte 0xc1, 0xef
	decf
	push	xsp
	.byte 0x01
	jrl	z, 11
	stdi8	(3567), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	xiy, StringData_EffectLabel_0x12B
	ld	xix, 3791
	ldw	bc, 13
	.byte 0x85
	scf
	xor	w, w
	dec	1, a
	div	a, 8
	inc	1, a
	inc	1, w
	stb_d8	(4594), a
	stb_d8	(4595), w
	xor	wa, wa
	ldb_d8	a, (4594)
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ldw_d16	wa, (4482)
	ld	(xix), wa
	ld	(xix+2), 45
	xor	wa, wa
	ldb_d8	a, (4595)
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ldb_d8	a, (4483)
	ld	(xix+3), a
	call	Display_UpdateRegion3
	ret
	.ascii "PANEL MEMORY="
	.byte 0xc1, 0xef
	decf
	push	xsp
	.byte 0x01
	jrl	z, 11
	stdi8	(3567), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	xiy, StringData_EffectLabel_0x17F
	ld	xix, 3791
	ldw	bc, 8
	.byte 0x85
	scf
	cps	a, 0
	jr	z, 13
	cps	a, 1
	jr	z, 0
	ld	xiy, StringData_EffectLabel_0x187
	jp	StringData_EffectLabel_0x176
	ld	xiy, StringData_EffectLabel_0x18A
	lds	bc, 3
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.byte 0x46
	.ascii "ADE-IN ON OFF"
	.byte 0xc1, 0xef
	decf
	push	xsp
	.byte 0x01
	jrl	z, 11
	stdi8	(3567), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	xiy, StringData_EffectLabel_0x1D4
	ld	xix, 3791
	ldw	bc, 9
	.byte 0x85
	scf
	cps	a, 0
	jr	z, 13
	cps	a, 1
	jr	z, 0
	ld	xiy, StringData_EffectLabel_0x187
	jp	StringData_EffectLabel_0x1CB
	ld	xiy, StringData_EffectLabel_0x18A
	lds	bc, 3
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.ascii "FADE-OUT "
	.byte 0xc1, 0xef
	decf
	push	xsp
	.byte 0x01
	jrl	z, 11
	stdi8	(3567), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
	and	w, a
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	l, w
	xor	h, h
	sla	hl, 4
	.byte 0x45
	.long StringData_APCModeNames
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ldw	iy, 0xcf44
	ret
	nop
	nop
	ldw	bc, 16
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
StringData_APCModeNames:
	.incbin "includes/generated/v7_transplant_StringData_APCModeNames.bin"
Display_RedrawStatusBar:
	.incbin "includes/generated/v7_transplant_Display_RedrawStatusBar.bin"
Scoop_SetupDisplayTables:
	ld xiy, StyleUI_ParamBlock_AltB
	ld xix, StyleUI_ParamBlock_AltC
	push xhl
	call UIRender_TwoTableGeneral
	pop xhl
	cpdi8 (3429), 0
	jr nz, Scoop_InitPartDisplay
	call Scoop_InitDisplayFull
	jr Scoop_Return

Scoop_InitPartDisplay:
	ldb_d8 a, (3424)
	stb_d8 (4494), a
	ld xiy, StyleUI_ScreenData_Main_0x1EF
	push xhl
	call UIRender_ConditionalDrawInit
	pop xhl
	push xhl
	sla hl, 2
	ld xiy, StyleUI_ParamBlockPtrTable
	cpdi8 (3429), 2
	jr nz, Scoop_SelectModeTable_2Part
	ld xiy, StyleUI_ParamBlockPtrTable_0x98

Scoop_SelectModeTable_2Part:
	ld_sril3 XIY, 0x07, 0xf4, 0xec
	ld xix, StyleUI_ParamBlockPtrTable_0x4C
	cpdi8 (3429), 2
	jr nz, Scoop_SelectModeTable_2Part_XIX
	ld xix, StyleUI_ParamBlockPtrTable_0xE4

Scoop_SelectModeTable_2Part_XIX:
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	call UIRender_TwoTableGeneral
	call Scoop_CheckPartStatus
	pop xhl
	cps l, 0
	jr nz, Scoop_SetPartIndexAndDisplay
	ld xiy, StyleUI_ScreenData_Main_0xD3F
	ld xix, StyleUI_ScreenData_MeasCursor
	call UIRender_TwoTableGeneral

Scoop_SetPartIndexAndDisplay:
	ldb_d8 a, (3424)
	dec 1, a
	ld xiy, 0xf1a0
	ldb_sri A, 0x03, 0xf4, 0xe0
	stb_d8 (4493), a
	ld xiy, SOUND_DATA_DRUM_KITS_0x3A
	call Scoop_ConditionalCurveUpdate

Scoop_Return:
	ret

Scoop_CheckPartStatus:
	pushw hl
	push xix
	ldb h, 0x0
	ldb_d8 l, (3424)
	dec 1, l
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xec, 0x0c
	jrl nz, Scoop_CheckPartStatus_End
	call Scoop_CallDisplayHelper

Scoop_CheckPartStatus_End:
	pop xix
	popw hl
	ret

Scoop_CallDisplayHelper:
	ld xiy, Scoop_DisplayData_ButtonLayout
	ld xix, Scoop_DisplayData_ButtonLayout_0x8
	call UIRender_TwoTableGeneral
	ret

Scoop_DisplayData_ButtonLayout:
	ret
	ldio	146, 18
	di
	zcf
	nop
	ld	xiy, Scoop_DisplayData_ButtonLayout_0x17
	ld	xix, Scoop_DisplayData_ButtonLayout_0x21
	call	UIRender_TwoTableGeneral
	ret
	jp	2058
	ldw	de, 4096
	.byte 0x01
	ld	xde, 0xb42a4500
	.byte 0xe0
	nop
	ld	xix, SOUND_DATA_DRUM_KITS_0x1A
	call	UIRender_SingleTable
	ret

Scoop_DrawGridLines:
	ld xiy, Scoop_GridLineData
	ld xix, Scoop_DrawGridDividers
	call UIRender_TwoTableGeneral
	call Scoop_DrawGridDividers
	ret

Scoop_GridLineData:
	jp	2058
	ldw	de, 4096
	.byte 0x01
	ld	xde, 0x050a1b00
	nop
	popw	hl
	nop
	halt
	nop
	popw	sp
	nop
	jp	0x490a
	popw	hl
	nop
	popw	bc
	nop
	popw	sp
	nop
	jp	0x890a
	popw	hl
	nop
	.byte 0x89
	nop
	popw	sp
	nop
	jp	0xc90a
	popw	hl
	nop
	.byte 0xc9
	nop
	popw	sp
	nop
	jp	0x01090a
	popw	hl
	nop
	push	1
	popw	sp
	nop
	jp	1290
	.byte 0x50
	nop
	push	1
	.byte 0x50
	nop
	jp	2058
	pop	xsp
	nop
	rcf
	.byte 0x01
	jr	nc, 0
	jp	2058
	.byte 0x8c
	nop
	rcf
	.byte 0x01, 0x9c
	nop

Scoop_DrawGridDividers:
	ld xiy, Scoop_GridDividerData
	ld xix, Scoop_DrawFrameLines
	call UIRender_TwoTableGeneral
	ret

Scoop_GridDividerData:
	jp	2058
	pushw	wa
	nop
	ldb	l, 0
	ldw	de, 6912
	ldwio	8, 0x5500
	nop
	ldb	l, 0
	pop	xsp
	nop
	jp	2058
	.byte 0x82
	nop
	ldb	l, 0
	.byte 0x8c
	nop

Scoop_DrawFrameLines:
	ld xiy, Scoop_FrameData
	ld xix, Scoop_InitDisplayFull
	call UIRender_TwoTableGeneral
	ret

Scoop_FrameData:
	ret
	ldio	18, 6
	di
	zcf
	nop
	ret
	ldio	82, 12
	di
	zcf
	nop
	ret
	ldio	146, 18
	di
	zcf
	nop
	ret
	ldio	209, 24
	reti
	nop
	zcf
	nop
	ldb	w, 41
	pop_f
	.byte 0x1f
	.ascii "                                     "
	ret
	ldio	213, 32
	halt
	nop
	.byte 0xec
	nop
	ret
	ldio	218, 32
	halt
	nop
	.byte 0xec
	nop
	ret
	ldio	223, 32
	halt
	nop
	.byte 0xec
	nop
	ret
	ldio	228, 32
	halt
	nop
	.byte 0xec
	nop
	ret
	ldio	233, 32
	halt
	nop
	.byte 0xec
	nop

Scoop_InitDisplayFull:
	stib_da (0x03efa8), 0x00
	calr Scoop_DrawFrameLines
	ld xiy, StyleUI_ParamBlock_AltE
	ld xix, StyleUI_ParamBlockPtrTable
	call UIRender_TwoTableGeneral
	ldb_d8 a, (3424)
	stb_d8 (4494), a
	ld xiy, StyleUI_ScreenData_Main_0x1EF
	call UIRender_ConditionalDrawInit
	ldb_d8 a, (3424)
	dec 1, a
	ld xiy, 0xf1a0
	ldb_sri A, 0x03, 0xf4, 0xe0
	stb_d8 (4493), a
	ld xiy, SOUND_DATA_DRUM_KITS_0x3A
	call Scoop_ConditionalCurveUpdate
	ret

Display_RedrawMainContent:
	.incbin "includes/generated/v7_transplant_Display_RedrawMainContent.bin"
Scoop_RedrawMainContent_End:
	ret

Display_RedrawFooter:
	.incbin "includes/generated/v7_transplant_Display_RedrawFooter.bin"
Scoop_FooterShowPartValue:
	ldb_d8 a, (3922)
	stb_d8 (4499), a
	ld xix, StyleUI_ScreenData_Main_0x276

Scoop_FooterCallDisplay:
	call GraphicsRender_TwoTable

Scoop_RedrawFooter_End:
	ret

;=============================================================================
; Display_RedrawTitleBar - Redraw the title bar region
;=============================================================================
Display_RedrawTitleBar:
	.incbin "includes/generated/v7_transplant_Display_RedrawTitleBar.bin"
Scoop_TitleBar_ShowBPM_Part0:
	ldw_d16 xwa, (3660)
	stda16 (4487), xwa
	ld xiy, StyleUI_ScreenData_Main_0x1C2
	call GraphicsRender_EventCheck

Scoop_TitleBar_Part1Check:
	cpdi16 3662, 0
	jr z, Scoop_TitleBar_Part2Check
	lds bc, 1
	calr Scoop_TitleBar_GetPartConfig
	cpdi16 3662, 1000
	jr c, Scoop_TitleBar_ShowBPM_Part1
	ld xiy, StyleUI_ScreenData_Main_0x1E5
	call Scoop_ConditionalGlideSetup
	jr Scoop_TitleBar_Part2Check

Scoop_TitleBar_ShowBPM_Part1:
	ldw_d16 xwa, (3662)
	stda16 (4489), xwa
	ld xiy, StyleUI_ScreenData_Main_0x1CC
	call GraphicsRender_EventCheck

Scoop_TitleBar_Part2Check:
	cpdi16 3664, 0
	jr z, Scoop_TitleBar_End
	lds bc, 2
	calr Scoop_TitleBar_GetPartConfig
	cpdi16 3664, 1000
	jr c, Scoop_TitleBar_ShowBPM_Part2
	ld xiy, StyleUI_ScreenData_Main_0x1EA
	call Scoop_ConditionalGlideSetup
	jr Scoop_TitleBar_End

Scoop_TitleBar_ShowBPM_Part2:
	ldw_d16 xwa, (3664)
	stda16 (4491), xwa
	ld xiy, StyleUI_ScreenData_Main_0x1D6
	call GraphicsRender_EventCheck

Scoop_TitleBar_End:
	ret

Scoop_TitleBar_SelectPartRange:
	xor xbc, xbc
	ldb_d8 c, (3667)
	cpda8 c, 3668
	jr nc, Scoop_TitleBar_ClampParts
	ldb_d8 c, (3668)

Scoop_TitleBar_ClampParts:
	cps c, 4
	jr ule, Scoop_TitleBar_DisplayPartTable
	lds bc, 4

Scoop_TitleBar_DisplayPartTable:
	ld xiy, StyleUI_ScreenData_Main
	ld xix, xiy
	muls bc, 0x2d
	add xix, xbc
	call UIRender_TwoTableGeneral
	ret

Scoop_TitleBar_GetPartConfig:
	ld xiy, StyleUI_ScreenData_Main_0xB4
	cps bc, 1
	jr ge, Scoop_TitleBar_Part1Config
	ldb_d8 a, (3666)
	cps a, 0
	jr nz, Scoop_TitleBar_ShowPartSlot
	jr Scoop_TitleBar_GetPartConfig_End

Scoop_TitleBar_Part1Config:
	cps bc, 2
	jr ge, Scoop_TitleBar_Part2Config
	add xiy, 0x5a
	ldb_d8 a, (3667)
	cps a, 0
	jr nz, Scoop_TitleBar_ShowPartSlot
	jr Scoop_TitleBar_GetPartConfig_End

Scoop_TitleBar_Part2Config:
	add xiy, 0xb4
	ldb_d8 a, (3668)
	cps a, 0
	jr nz, Scoop_TitleBar_ShowPartSlot
	jr Scoop_TitleBar_GetPartConfig_End

Scoop_TitleBar_ShowPartSlot:
	ld xix, xiy
	add xix, 0xa
	xor w, w
	muls wa, 0x14
	add xix, xwa
	call UIRender_SingleTable

Scoop_TitleBar_GetPartConfig_End:
	ret

Display_RedrawSelection:
	.incbin "includes/generated/v7_transplant_Display_RedrawSelection.bin"
Scoop_Selection_RedrawActive:
	stib_da (0x03efa8), 0x01
	ldb_d8 a, (3429)
	cps a, 0
	jr nz, Scoop_Selection_CheckMode1
	pushw wa
	ld xiy, StyleUI_ScreenData_Main_0x97E
	ld xix, StyleUI_ScreenData_Main_0x986
	call UIRender_SingleTable
	ldb_d8 a, (3823)
	stb_d8 (4497), a
	popw wa
	ld xiy, StyleUI_ScreenData_Main_0x9BB
	call UIRender_TwoTableEvtCheck
	jp Scoop_Selection_End

Scoop_Selection_CheckMode1:
	cps a, 1
	jr nz, Scoop_Selection_DrawMode2

Scoop_Selection_DrawMode1:
	.incbin "includes/generated/v7_transplant_Scoop_Selection_DrawMode1.bin"
Scoop_Selection_DrawMode2:
	cps a, 2
	jr z, Scoop_Selection_DrawMode1
	ld xiy, StyleUI_ScreenData_Main_0x97E
	ld xix, StyleUI_ScreenData_Main_0x986
	call UIRender_SingleTable
	pushw wa
	ldb_d8 a, (3922)
	stb_d8 (4500), a
	popw wa
	ld xiy, StyleUI_ScreenData_Main_0x990
	call UIRender_TwoTableEvtCheck

Scoop_Selection_End:
	ret

Display_RedrawSidePanel:
	.incbin "includes/generated/v7_transplant_Display_RedrawSidePanel.bin"
Scoop_SidePanel_DrawPartLoop:
	xor bc, bc
	ld xiz, 0xe52
	xor xwa, xwa
	ld a, e
	add xiz, xwa
	ld d, (xiz)
	cps d, 0
	jr z, Scoop_SidePanel_NextPart

Scoop_SidePanel_DrawSlotPair:
	xor hl, hl
	ld l, c
	ldb_sri L, 0x07, 0xf4, 0xec
	and l, 0xf
	calr Scoop_SidePanel_DrawOneSlot
	add xix, 0x4
	xor hl, hl
	ld l, c
	ldb_sri L, 0x07, 0xf4, 0xec
	and l, 0xf0
	srl l, 4
	calr Scoop_SidePanel_DrawOneSlot
	add xix, 0x4
	inc 1, c
	cp c, d
	jr c, Scoop_SidePanel_DrawSlotPair

Scoop_SidePanel_NextPart:
	inc 1, e
	cps e, 3
	jr ge, Scoop_SidePanel_DrawValues
	add xiy, 0x4
	ldb a, 0x8
	mul8rr a, c
	extz xwa
	sub xix, xwa
	add xix, 0x708
	jr Scoop_SidePanel_DrawPartLoop

Scoop_SidePanel_DrawValues:
	stib_da (0x03efa8), 0x00
	ldb_d8 a, (3666)
	cpdi8 (3660), 0
	jr nz, Scoop_SidePanel_StoreAndDraw
	ldb a, 0x0

Scoop_SidePanel_StoreAndDraw:
	stb_d8 (4507), a
	ldb_d8 a, (3667)
	stb_d8 (4508), a
	ldb_d8 a, (3668)
	stb_d8 (4509), a
	ld xiy, StyleUI_ScreenData_Main_0xB19
	ld xix, StyleUI_ScreenData_Main_0xB3A
	call GraphicsRender_TwoTable_Alt
	call Display_UpdateRegion1_Alt

Scoop_SidePanel_End:
	ret

Scoop_SidePanel_DrawOneSlot:
	push xiy
	push xix
	pushw de
	pushw bc
	ld xiy, StyleUI_ScreenData_Main_0xB94
	lds bc, 4
	stib_da (0x03efa8), 0x00
	ld xwa, 0x11d4
	ld (xwa), 0x6
	ld (xwa + 1), 0x8
	ld (xwa + 2), ix
	extz hl
	extz xhl
	sll xhl, 2
	add xiy, xhl
	ldb_spi L, 0xf4
	ld (xwa + 4), l
	ldb_spi L, 0xf4
	ld (xwa + 5), l
	ldb_spi L, 0xf4
	ld (xwa + 6), l
	ld l, (xiy)
	ld (xwa + 7), l
	ld xiy, 0x11d4
	call Scoop_ConditionalGlideSetup
	popw bc
	popw de
	pop xix
	pop xiy
	ret

Display_RedrawAltContent:
	cpdi8 (3930), 0
	jr z, Scoop_AltContent_ClearRegions
	ld xix, 0x820
	xor wa, wa
	ldb_d8 a, (3930)
	dec 1, wa
	muls wa, 0x708
	add xix, xwa
	xor xwa, xwa
	ldb_d8 a, (3931)
	cps a, 0
	jr z, Scoop_AltContent_ClearRegions
	add xix, xwa
	stib_da (0x03efa8), 0x02
	ld xiy, StyleUI_ScreenData_CtlOnly_0x20
	lds bc, 3
	xor hl, hl
	stdi8 (4579), 6
	stdi8 (4580), 7
	stda16 (4581), xix
	stdi8 (4583), 69
	stdi8 (4584), 78
	stdi8 (4585), 68
	ld xiy, 0x11e3
	call Scoop_ConditionalGlideSetup
	jr Scoop_AltContent_End

Scoop_AltContent_ClearRegions:
	ld xiy, 0x821
	calr Scoop_AltContent_ClearOneRegion
	ld xiy, 0xf29
	calr Scoop_AltContent_ClearOneRegion
	ld xiy, 0x1631
	calr Scoop_AltContent_ClearOneRegion

Scoop_AltContent_End:
	ret

Scoop_AltContent_ClearOneRegion:
	stib_da (0x03efa8), 0x02
	ldw bc, 0x20
	ldw hl, 0xa
	stdi8 (4586), 14
	stdi8 (4587), 8
	stda16 (4588), xiy
	stda16 (4590), xbc
	stda16 (4592), xhl
	ld xiy, 0x11ea
	call UIRender_ConditionalFBCall
	ret

Display_RedrawButtonLabels:
	.incbin "includes/generated/v7_transplant_Display_RedrawButtonLabels.bin"
Scoop_ButtonLabels_End:
	ret

Scoop_ButtonLabels_CopySlotData:
	pushw wa
	pushw bc
	push xix
	push xiy
	ld xix, 0x11b3
	ld xiy, 0xe55
	ldb c, 0x8

Scoop_ButtonLabels_CopyLoop:
	ld a, (xiy)
	lda_dpi XBC, 0xf0
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_CopyLoop
	ld xix, 0x1192
	ld xiy, 0xe75
	ldb c, 0x8

Scoop_ButtonLabels_DrawRow1:
	ld a, (xiy)
	lda_dpi XBC, 0xf0
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_DrawRow1
	ld xiy, 0xe95
	ldb c, 0x8

Scoop_ButtonLabels_DrawRow1_Alt:
	ld a, (xiy)
	lda_dpi XBC, 0xf0
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_DrawRow1_Alt
	pop xiy
	pop xix
	popw bc
	popw wa
	ret

Scoop_ButtonLabels_SetupPartButtons:
	pushw wa
	pushw bc
	push xix
	push xiy
	ld xix, 0x119b
	ld xiy, 0xe56
	ldb c, 0x8

Scoop_ButtonLabels_Part1:
	ld a, (xiy)
	lda_dpi XBC, 0xf0
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_Part1
	ld xiy, 0xe76
	ldb c, 0x8

Scoop_ButtonLabels_Part2:
	ld a, (xiy)
	lda_dpi XBC, 0xf0
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_Part2
	ld xiy, 0xe96
	ldb c, 0x8

Scoop_ButtonLabels_Part3:
	ld a, (xiy)
	lda_dpi XBC, 0xf0
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_Part3
	pop xiy
	pop xix
	popw bc
	popw wa
	ret

Scoop_ButtonLabels_DrawPitchLabels:
	pushw wa
	pushw bc
	push xix
	push xiy
	ld xix, 0x11a3
	ld xiy, 0xe57
	ldb c, 0x8

Scoop_ButtonLabels_DrawPitchLabel1:
	ld wa, (xiy)
	stw_dpi WA, 0xf1
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_DrawPitchLabel1
	pop xiy
	pop xix
	popw bc
	popw wa
	ret

Scoop_ButtonLabels_DrawAmpLabels:
	pushw wa
	pushw bc
	push xix
	push xiy
	ld xix, 0x11a3
	ld xiy, 0xe77
	ldb c, 0x8

Scoop_ButtonLabels_DrawAmpLabel1:
	ld wa, (xiy)
	stw_dpi WA, 0xf1
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_DrawAmpLabel1
	pop xiy
	pop xix
	popw bc
	popw wa
	ret

Scoop_ButtonLabels_DrawFilterLabels:
	pushw wa
	pushw bc
	push xix
	push xiy
	ld xix, 0x11a3
	ld xiy, 0xe97
	ldb c, 0x8

Scoop_ButtonLabels_DrawFilterLabel1:
	ld wa, (xiy)
	stw_dpi WA, 0xf1
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_DrawFilterLabel1
	pop xiy
	pop xix
	popw bc
	popw wa
	ret

Scoop_ButtonLabels_DrawCategory:
	.incbin "includes/generated/v7_transplant_Scoop_ButtonLabels_DrawCategory.bin"
Scoop_ButtonLabels_DrawCategoryData:
	push xix
	inc 2, xix
	ld a, (xix)
	cps a, 0
	jr z, Scoop_EventHandler_Setup
	pushw bc
	push xiy
	push xix
	call Scoop_ConditionalCurveUpdate
	pop xix
	pop xiy
	popw bc
	inc 1, xix
	ld a, (xix)
	cps a, 1
	jr nz, Scoop_EventHandler_PartSelect
	stdi8 (4531), 0
	jr Scoop_EventHandler_PartRedrawData

Scoop_EventHandler_PartSelect:
	cps a, 2
	jr nz, Scoop_EventHandler_Part1
	stb_d8 (4531), a
	jr Scoop_EventHandler_PartRedrawData

Scoop_EventHandler_Part1:
	cp a, 0xb
	jr nz, Scoop_EventHandler_PartRedraw
	stdi8 (4531), 3
	jr Scoop_EventHandler_PartRedrawData

Scoop_EventHandler_PartRedraw:
	stdi8 (4531), 1

Scoop_EventHandler_PartRedrawData:
	dec 1, xix
	dec 1, xix
	dec 1, xix
	ld a, (xix)
	push xiy
	bit 7, a
	jr nz, Scoop_EventHandler_ValueChange
	add xiy, 0xf
	jr Scoop_EventHandler_ValueChangeData

Scoop_EventHandler_ValueChange:
	add xiy, 0x1e

Scoop_EventHandler_ValueChangeData:
	pushw bc
	call Scoop_ConditionalCurveUpdate
	popw bc
	pop xiy

Scoop_EventHandler_Setup:
	pop xix
	add xix, 0x4
	add xiy, 0x2d
	inc 1, bc
	cps bc, 7
	jr ule, Scoop_ButtonLabels_DrawCategoryData

Scoop_EventHandler_SetupData:
	ret

Scoop_EventHandler_MenuSwitch:
	pushw wa
	call SetWall_ParserInit
	popw wa
	stdi8 (0x287a), 0
	bitda 2, (0x287b)
	jr nz, Scoop_EventHandler_MenuSwitch_Mode1
	xor de, de
	ldw_d16 xwa, (3299)
	xor bc, bc
	ldb_d8 c, (1075)
	ldw_erp DE, 0xe2
	div xwa, xbc
	stw_erp DE, 0xe2
	ld c, e
	ld de, wa
	inc 1, de
	ldb_d8 a, (1075)
	jr Scoop_EventHandler_MenuSwitch_End

Scoop_EventHandler_MenuSwitch_Mode1:
	stb_d8 (0x288d), w
	call SetWall_DualPassScanner
	xor wa, wa
	ldb_d8 a, (0x288e)
	ldw_d16 xbc, (3299)
	xor de, de
	inc 1, de

Scoop_EventHandler_MenuSwitch_Mode2:
	cp bc, wa
	jr c, Scoop_EventHandler_MenuSwitch_End
	sub bc, wa
	inc 1, de
	pushw bc
	pushw de
	call SetWall_ReplayScanner
	popw de
	popw bc
	xor wa, wa
	ldb_d8 a, (0x288e)
	jr Scoop_EventHandler_MenuSwitch_Mode2

Scoop_EventHandler_MenuSwitch_End:
	ret

Scoop_EventHandler_Scroll:
	stdi8 (0x287a), 0
	ldw_d16 xhl, (0x28ba)
	call SetWall_StreamIndexResolve
	ldda32 xwa, (4349)
	stda32 9854, xwa
	ldw_d16 xhl, (0x289f)
	call SetWall_StreamIndexResolve
	ldda32 xwa, (4349)
	stda32 9850, xwa
	cpda16 xde, 0x28ba
	jr nz, Scoop_Scroll_ValidateRange
	ldw_d16 xiy, (0x28bc)
	sub iy, 0x5
	inc 1, iy
	stda16 (9874), xiy
	ldw_d16 xiy, (0x28bc)
	ldw_d16 xix, (0x28b6)
	sub ix, 0x5
	inc 1, ix
	stda16 (9876), xix
	ldw_d16 xix, (0x28b6)
	jrl Scoop_ButtonGrid_ProcessCell

Scoop_Scroll_ValidateRange:
	ldw_d16 xwa, (0x28b6)
	cpda16 xwa, 0x28bc
	jr ugt, Scoop_Scroll_Boundary1
	jr z, Scoop_Scroll_Boundary2
	jr Scoop_Scroll_Boundary3

Scoop_Scroll_Boundary1:
	jr Scoop_Scroll_Apply

Scoop_Scroll_Boundary2:
	jrl Scoop_CategorySelect_Amplitude

Scoop_Scroll_Boundary3:
	jrl Scoop_CategorySelect_UpdateDisplay

Scoop_Scroll_Apply:
	subda16 xwa, 0x28bc
	stda16 (9870), xwa
	ldw bc, 0x100
	sub bc, 0x5
	sub bc, wa
	stda16 (9872), xbc
	ldw_d16 xiy, (0x28bc)
	ldw_d16 xix, (0x28b6)
	ldw_d16 xbc, (0x28bc)
	sub bc, 0x5
	inc 1, bc
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Data
	cpdi8 (0x287a), 0
	jrl nz, Scoop_ButtonGrid_Data

Scoop_EventHandler_CategorySelect:
	cpda16 xde, 0x28ba
	jrl z, Scoop_CategorySelect_Pitch
	ldw_d16 xbc, (9870)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Draw
	cpdi8 (0x287a), 0
	jrl nz, Scoop_ButtonGrid_Data
	ldw_d16 xbc, (9872)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Data
	cpdi8 (0x287a), 0
	jr z, Scoop_EventHandler_CategorySelect
	jrl Scoop_ButtonGrid_Data

Scoop_CategorySelect_Pitch:
	ldw_d16 xwa, (9870)
	stda16 (9876), xwa
	ldw bc, 0x100
	sub bc, 0x5
	stda16 (9874), xbc
	jrl Scoop_ButtonGrid_ProcessCell

Scoop_CategorySelect_Amplitude:
	ldw_d16 xbc, (0x28bc)
	sub bc, 0x5
	inc 1, bc
	ldw_d16 xiy, (0x28bc)
	ldw_d16 xix, (0x28b6)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Draw
	cpdi8 (0x287a), 0
	jrl nz, Scoop_ButtonGrid_Data
	call Scoop_SpecialMode_Data
	cpdi8 (0x287a), 0
	jrl nz, Scoop_ButtonGrid_Data

Scoop_CategorySelect_Filter:
	cpda16 xde, 0x28ba
	jrl z, Scoop_CategorySelect_End
	ldw bc, 0x100
	sub bc, 0x5
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Draw
	cpdi8 (0x287a), 0
	jrl nz, Scoop_ButtonGrid_Data
	call Scoop_SpecialMode_Data
	cpdi8 (0x287a), 0
	jr z, Scoop_CategorySelect_Filter
	jrl Scoop_ButtonGrid_Data

Scoop_CategorySelect_End:
	ldw bc, 0x100
	sub bc, 0x5
	stda16 (9876), xbc
	stda16 (9874), xbc
	jrl Scoop_ButtonGrid_ProcessCell

Scoop_CategorySelect_UpdateDisplay:
	ldw_d16 xwa, (0x28bc)
	subda16 xwa, 0x28b6
	stda16 (9870), xwa
	ldw bc, 0x100
	sub bc, 0x5
	sub bc, wa
	stda16 (9872), xbc
	ldw_d16 xiy, (0x28bc)
	ldw_d16 xix, (0x28b6)
	ldw_d16 xbc, (0x28b6)
	sub bc, 0x5
	inc 1, bc
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Draw
	cpdi8 (0x287a), 0
	jrl nz, Scoop_ButtonGrid_Data
	ldw_d16 xbc, (9870)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Data
	cpdi8 (0x287a), 0
	jrl nz, Scoop_ButtonGrid_Data

Scoop_EventHandler_ButtonGrid:
	cpda16 xde, 0x28ba
	jrl z, Scoop_ButtonGrid_CheckBounds
	ldw_d16 xbc, (9872)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Draw
	cpdi8 (0x287a), 0
	jrl nz, Scoop_ButtonGrid_Data
	ldw_d16 xbc, (9870)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Data
	cpdi8 (0x287a), 0
	jr z, Scoop_EventHandler_ButtonGrid
	jr Scoop_ButtonGrid_Data

Scoop_ButtonGrid_CheckBounds:
	ldw_d16 xwa, (9872)
	stda16 (9876), xwa
	ldw wa, 0x100
	sub wa, 0x5
	stda16 (9874), xwa

Scoop_ButtonGrid_ProcessCell:
	ldw_d16 xwa, (0x28b8)
	sub wa, 0x5
	ldw_d16 xbc, (9874)
	sub bc, wa
	stda16 (9880), xbc
	cpdm16 9876, xbc
	jr nc, Scoop_ButtonGrid_UpdateValue
	jr Scoop_ButtonGrid_End

Scoop_ButtonGrid_UpdateValue:
	call Scoop_SpecialMode_Setup
	jr Scoop_ButtonGrid_Data

Scoop_ButtonGrid_End:
	ldw_d16 xbc, (9876)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Draw
	cpdi8 (0x287a), 0
	jr nz, Scoop_ButtonGrid_Data
	ldw_d16 xbc, (9880)
	subda16 xbc, 9876
	call Scoop_SpecialMode_Setup

Scoop_ButtonGrid_Data:
	ret

Scoop_EventHandler_SpecialMode:
	stdi8	(0x287a), 0
	ldw_d16	hl, (0x28ba)
	call	SetWall_StreamIndexResolve
	push	xwa
	ldda32	xwa, (4349)
	stda32	9854, xwa
	ldw_d16	hl, (0x289f)
	call	SetWall_StreamIndexResolve
	ldda32	xwa, (4349)
	.byte 0xf1
	.ascii "z&`X—"
	.byte 0xba
	pushw	wa
	stib_da	(0x35216e), 1
	.byte 0xd1, 0xbc
	pushw	wa
	.byte 0xa5
	stda16	(9874), iy
	ldw_d16	iy, (0x28bc)
	ldw	ix, 256
	.byte 0xd1, 0xb6
	pushw	wa
	.byte 0xa4
	stda16	(9876), ix
	ldw_d16	ix, (0x28b6)
	jrl	431
	ldw_d16	wa, (0x28b6)
	.byte 0xd1, 0xbc
	pushw	wa
	.byte 0xf0
	jr	c, 4
	jr	z, 4
	jr	ugt, 5
	jr	6
	jrl	143
	jrl	252
	ldw	wa, 256
	.byte 0xd1, 0xb6
	pushw	wa
	.byte 0xa0
	ldw	bc, 256
	.byte 0xd1, 0xbc
	pushw	wa
	xor	(xbc), xbc
	.byte 0xa0
	stda16	(9870), wa
	ldw	bc, 256
	sub	bc, 5
	sub	bc, wa
	stda16	(9872), bc
	ldw_d16	iy, (0x28bc)
	ldw_d16	ix, (0x28b6)
	ldw	bc, 256
	.byte 0xd1, 0xbc
	pushw	wa
	.byte 0xa1
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 3
	jrl	407
	.byte 0xd1, 0xba
	pushw	wa
	.byte 0xf2
	jr	nz, 2
	jr	44
	ldw_d16	bc, (9870)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams_0x38
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 3
	jrl	377
	ldw_d16	bc, (9872)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, -49
	jrl	355
	ldw_d16	wa, (9870)
	stda16	(9876), wa
	ldw	bc, 256
	sub	bc, 5
	stda16	(9874), bc
	jrl	269
	ldw	bc, 256
	.byte 0xd1, 0xbc
	pushw	wa
	.byte 0xa1
	ldw_d16	iy, (0x28bc)
	ldw_d16	ix, (0x28b6)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 3
	jrl	300
	call	Scoop_SpecialMode_UpdateParams_0x38
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 3
	jrl	286
	.byte 0xd1, 0xba
	pushw	wa
	.byte 0xf2
	jr	nz, 2
	jr	39
	ldw	bc, 256
	sub	bc, 5
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 3
	jrl	253
	call	Scoop_SpecialMode_UpdateParams_0x38
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, -44
	jrl	239
	ldw	bc, 256
	sub	bc, 5
	stda16	(9876), bc
	stda16	(9874), bc
	jrl	157
	ldw	wa, 256
	.byte 0xd1, 0xbc
	pushw	wa
	.byte 0xa0
	ldw	bc, 256
	.byte 0xd1, 0xb6
	pushw	wa
	xor	(xbc), xbc
	.byte 0xa0
	stda16	(9870), wa
	ldw	bc, 256
	sub	bc, 5
	sub	bc, wa
	stda16	(9872), bc
	ldw_d16	iy, (0x28bc)
	ldw_d16	ix, (0x28b6)
	ldw	bc, 256
	.byte 0xd1, 0xb6
	pushw	wa
	.byte 0xa1
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams_0x38
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 3
	jrl	155
	ldw_d16	bc, (9870)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 3
	jrl	133
	.byte 0xd1, 0xba
	pushw	wa
	.byte 0xf2
	jr	nz, 2
	jr	42
	ldw_d16	bc, (9872)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams_0x38
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 2
	jr	104
	ldw_d16	bc, (9870)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, -48
	jr	83
	ldw_d16	wa, (9872)
	stda16	(9876), wa
	ldw	wa, 256
	sub	wa, 5
	stda16	(9874), wa
	ldw	wa, 255
	.byte 0xd1, 0xb8
	pushw	wa
	.byte 0xa0
	ldw_d16	bc, (9874)
	sub	bc, wa
	stda16	(9880), bc
	.byte 0xd1
	ld	iz, (xix)
	swi	1
	jr	nc, 2
	jr	6
	call	Scoop_SpecialMode_UpdateParams_0x70
	jr	33
	ldw_d16	bc, (9876)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams_0x38
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 2
	jr	12
	ldw_d16	bc, (9880)
	.byte 0xd1
	ld	iz, (xix)
	.byte 0xa1
	call	Scoop_SpecialMode_UpdateParams_0x70
	ret

Scoop_SpecialMode_Setup:
	pushw wa
	push xde
	push xhl
	cps bc, 0
	jr z, Scoop_SpecialMode_CheckState
	ldda32 xhl, (9854)
	ldda32 xde, (9850)
	extz xiy
	extz xix
	add xhl, xiy
	add xde, xix
	lddr83
	subda32 xhl, 9854
	subda32 xde, 9850
	ld iy, hl
	ld ix, de

Scoop_SpecialMode_CheckState:
	pop xhl
	pop xde
	popw wa
	ret

Scoop_SpecialMode_Data:
	xor iy, iy
	ldda32 xiy, (9854)
	stda32 4349, xiy
	ld wa, (xiy + 1)
	stda16 (0x28ba), xwa
	extz xwa
	dec 1, xwa
	sla xwa, 8
	addda32 xwa, 7514
	stda32 4349, xwa
	bitm 7, (xwa)
	jr nz, Scoop_SpecialMode_Toggle
	stdi8 (0x287a), 11
	jr Scoop_SpecialMode_ToggleEnd

Scoop_SpecialMode_Toggle:
	ldda32 xwa, (4349)
	stda32 9854, xwa
	ldw iy, 0xff

Scoop_SpecialMode_ToggleEnd:
	ret

Scoop_SpecialMode_Draw:
	xor ix, ix
	ldda32 xix, (9850)
	stda32 4349, xix
	ld wa, (xix + 1)
	stda16 (0x289f), xwa
	extz xwa
	dec 1, xwa
	sla xwa, 8
	addda32 xwa, 7514
	stda32 4349, xwa
	bitm 7, (xwa)
	jr nz, Scoop_SpecialMode_DrawAlt
	stdi8 (0x287a), 11
	jr Scoop_SpecialMode_DrawEnd

Scoop_SpecialMode_DrawAlt:
	ldda32 xwa, (4349)
	stda32 9850, xwa
	ldw ix, 0xff

Scoop_SpecialMode_DrawEnd:
	ret

Scoop_SpecialMode_UpdateParams:
	xor	iy, iy
	ldda32	xiy, (9854)
	stda32	3304, xiy
	ld	wa, (xiy+3)
	stda16	(0x28ba), wa
	extz	xwa
	dec	1, xwa
	sla	xwa, 8
	addda32	xwa, 7514
	stda32	4349, xwa
	.byte 0xb0
	dec	6, l
	reti
	stdi8	(0x287a), 11
	jr	12
	push	xwa
	ldda32	xwa, (4349)
	stda32	9854, xwa
	pop	xwa
	lds	iy, 5
	ret
	xor	xix, xix
	ldda32	xix, (9850)
	stda32	4349, xix
	ld	wa, (xix+3)
	stda16	(0x289f), wa
	extz	xwa
	dec	1, xwa
	sla	xwa, 8
	addda32	xwa, 7514
	stda32	4349, xwa
	.byte 0xb4
	sbc	w, l
	dec	6, l
	reti
	stdi8	(0x287a), 11
	jr	10
	ldda32	xwa, (4349)
	stda32	9850, xwa
	lds	ix, 5
	ret
	pushw	wa
	push	xde
	push	xhl
	cps	bc, 0
	jr	z, 26
	ldda32	xhl, (9854)
	ldda32	xde, (9850)
	extz	xix
	extz	xiy
	add	xiy, xhl
	add	xix, xde
	.byte 0x85
	scf
	subda32	xiy, 9854
	subda32	xix, 9850
	pop	xhl
	pop	xde
	popw	wa
	ret

Scoop_SpecialMode_ParamCheckBound:
	ldb_d8 a, (0x2877)
	cps a, 1
	jr c, Scoop_SpecialMode_ParamEnd
	cp a, 0x10
	jr ule, Scoop_SpecialMode_ParamApply
	jr Scoop_SpecialMode_ParamEnd

Scoop_SpecialMode_ParamApply:
	calr Scoop_SpecialMode_ValueEdit

Scoop_SpecialMode_ParamEnd:
	ret

Scoop_SpecialMode_ValueEdit:
	xor wa, wa
	ldb_d8 a, (0x2877)
	dec 1, a
	ld iy, wa
	pushw bc
	ld c, a
	ldw_d16 xiz, (0x2875)
	ld a, c
	rcf
	stcf_a_16 iz
	stda16 (0x2875), xiz
	popw bc
	ld xix, 0xf218
	stib_ind 0x07, 0xf0, 0xf4, 0x05
	ld xix, 0xcbe
	stib_ind 0x07, 0xf0, 0xf4, 0x05
	sla iy, 1
	ld xix, 0xf1f8
	stiw_ind 0x07, 0xf0, 0xf4, 0xff, 0xff
	ld xix, 0xc9e
	stiw_ind 0x07, 0xf0, 0xf4, 0xff, 0xff
	muls wa, 0x3
	ld iy, wa
	ld xix, 0xf250
	bit_dri 7, 0x07, 0xf0, 0xf4
	jr z, Scoop_SpecialMode_ValueEditEnd
	and_srib_im 0x07, 0xf0, 0xf4, 0x7f
	inc 1, iy
	ldw_sri WA, 0x07, 0xf0, 0xf4
	cp wa, 0xffff
	jr z, Scoop_SpecialMode_ValueEditEnd
	stiw_ind 0x07, 0xf0, 0xf4, 0xff, 0xff
	ld iy, wa
	ldw_d16 xwa, (0x286d)
	calr Scoop_SpecialMode_ValueSend

Scoop_SpecialMode_ValueEditEnd:
	ret

Scoop_SpecialMode_ValueSend:
	stda16 (3302), xwa
	ldw_d16 xbc, (0xf22f)
	stda16 (0xf22f), xiy
	xor wa, wa
	call DispatchHandler_SubJumpTable
	ldda32 xhl, (4349)
	ld ix, (xhl + 1)
	ld de, ix
	cps ix, 0
	jr z, Scoop_CurveUpdate_DrawSegment
	ld iy, ix
	ldw (xhl + 1), 0x0
	call DispatchHandler_SubJumpTable
	ldda32 xhl, (4349)
	ld ix, iy
	ld iy, (xhl + 3)

Scoop_SpecialMode_ValueSend_Part1:
	call DispatchHandler_SubJumpTable
	ldda32 xhl, (4349)
	ld ix, iy
	ld iy, (xhl + 3)
	cp iy, 0xffff
	jr z, Scoop_SpecialMode_ValueSend_End

Scoop_SpecialMode_ValueSend_Part2:
	andmi8 (xhl), 0x7f
	ld (xhl + 5), 0x82
	inc 1, wa
	cpda16 xwa, 3302
	jr nz, Scoop_SpecialMode_ValueSend_Part1
	dec 1, wa

Scoop_SpecialMode_ValueSend_Part3:
	call DispatchHandler_SubJumpTable
	ldda32 xhl, (4349)
	ld (xhl + 1), de

Scoop_SpecialMode_ValueSend_End:
	cps de, 0
	jr z, Scoop_SpecialMode_CurveUpdate
	pushw iy
	ld iy, de
	call DispatchHandler_SubJumpTable
	ldda32 xhl, (4349)
	popw iy
	ld (xhl + 3), iy

Scoop_SpecialMode_CurveUpdate:
	ld iy, ix
	call DispatchHandler_SubJumpTable
	ldda32 xhl, (4349)
	andmi8 (xhl), 0x7f
	ld (xhl + 5), 0x82
	ld (xhl + 3), bc
	ld iy, bc
	call DispatchHandler_SubJumpTable
	ldda32 xhl, (4349)
	ld (xhl + 1), ix
	inc 1, wa
	adddm16 0xf231, xwa
	ret

Scoop_CurveUpdate_DrawSegment:
	.incbin "includes/generated/v7_transplant_Scoop_CurveUpdate_DrawSegment.bin"
Scoop_CurveUpdate_NextSegment:
	.incbin "includes/generated/v7_transplant_Scoop_CurveUpdate_NextSegment.bin"
Scoop_CurveUpdate_SegmentEnd:
	stb_dri L, 0xfd, 0xf0, 0xfe
	push xiz
	ld xbc, xwa
	ld iz, (xbc + 2)
	extz xiz
	ld l, (xbc + 4)
	ld e, (xbc + 5)
	ld a, (xiz)
	and a, l
	ld (xsp + 6), a
	ld a, e
	ld e, (xsp + 6)
	and a, 0xf
	jr z, Scoop_CurveUpdate_Finalize
	srla e

Scoop_CurveUpdate_Finalize:
	ld (xsp + 6), e
	ld hl, (xbc + 13)
	ld de, (xbc + 11)
	ld wa, hl
	extz xwa
	div wa, 0x28
	stw_dri WA, 0xfd, 0x0a, 0x01
	ldw_sri0 WA, (xsp + 0x010a)
	muls wa, 0x28
	sub hl, wa
	sll hl, 3
	stw_dri HL, 0xfd, 0x08, 0x01
	lds iy, 0
	cp iy, de
	jr nc, Scoop_EnvelopeCalc

Scoop_CurveUpdate_End:
	ld xiz, (xbc + 7)
	ld wa, iy
	extz xwa
	lda xix, (xsp + 8)
	add xix, xwa
	ld a, (xsp + 6)
	extz wa
	mul xwa, xde
	ld hl, iy
	extz xhl
	add xhl, xwa
	add xhl, xiz
	ld a, (xhl)
	extz wa
	lda_24 xhl, (StyleUI_ScreenData_CtlOnly_0x23)
	ldb_sri A, 0x07, 0xec, 0xe0
	ld (xix), a
	inc 1, iy
	cp iy, de
	jr c, Scoop_CurveUpdate_End

Scoop_EnvelopeCalc:
	ld wa, iy
	extz xwa
	lda xde, (xsp + 8)
	add xde, xwa
	ld (xde), 0x0
	ld a, (xbc + 6)
	and a, 0x3f
	extz wa
	sla wa, 2
	lda_24 xbc, (Str_No_0xCEE)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 4), xwa
	dec_sriw 2, 0xfd, 0x0a, 0x01
	ldw_sri0 WA, (xsp + 0x0108)
	stw_dri WA, 0xfd, 0x0c, 0x01
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call CalcTotalWidth
	ldw_sri0 WA, (xsp + 0x0108)
	add wa, hl
	stw_dri WA, 0xfd, 0x10, 0x01
	ldw_sri0 WA, (xsp + 0x010a)
	stw_dri WA, 0xfd, 0x0e, 0x01
	ld xwa, (xsp + 4)
	call GetCharHeight
	ldw_sri0 WA, (xsp + 0x010a)
	add wa, hl
	stw_dri WA, 0xfd, 0x12, 0x01
	stb_dri W, 0xfd, 0x0c, 0x01
	ld xhl, xwa
	stb_dri W, 0xfd, 0x08, 0x01
	ld xbc, xwa
	lda xwa, (xsp + 8)
	ld xde, xwa
	ld xwa, (xsp + 4)
	push xwa
	pushw 0xff
	pushw 0xf5
	ld xwa, xhl
	call DrawString
	pop xiz
	stb_dri L, 0xfd, 0x10, 0x01
	ret

Scoop_EnvelopeCalc_Data:
	.byte 0xf3
	swi	5
	.byte 0xee
	swi	6
	.byte 0x37
	push	xiz
	ld	xbc, xwa
	ld	iz, (xbc+2)
	extz	xiz
	ld	l, (xbc+4)
	ld	e, (xbc+5)
	ld	a, (xiz)
	and	a, l
	ld	(xsp+8), a
	ld	a, e
	ld	e, (xsp+8)
	and	a, 15
	jr	z, 2
	.byte 0xcd
	swi	7
	ld	(xsp+8), e
	ld	hl, (xbc+13)
	ld	de, (xbc+11)
	ld	wa, hl
	extz	xwa
	div	wa, 40
	.byte 0xf3
	swi	5
	incf
	.byte 0x01, 0x50, 0xd3
	swi	5
	incf
	.byte 0x01
	ldb	w, 216
	push	40
	nop
	sub	hl, wa
	sll	hl, 3
	ld	(xsp+266), hl
	lds	iy, 0
	cp	iy, de
	jr	nc, 49
	ld	xiz, (xbc+7)
	ld	wa, iy
	extz	xwa
	lda	xix, (xsp+10)
	add	xix, xwa
	ld	a, (xsp+8)
	extz	wa
	mul	xwa, xde
	ld	hl, iy
	extz	xhl
	add	xhl, xwa
	add	xhl, xiz
	ld	a, (xhl)
	extz	wa
	lda_24	xhl, (StyleUI_ScreenData_CtlOnly_0x23)
	.byte 0xc3
	reti
	or	xwa, xix
	ldb	a, 180
	ld	xbc, 0xf5da61dd
	jr	c, -49
	ld	wa, iy
	extz	xwa
	lda	xde, (xsp+10)
	add	xde, xwa
	ld	(xde), 0
	ld	a, (xbc+6)
	and	a, 63
	extz	wa
	sla	wa, 2
	lda_24	xbc, (Str_No_0xCEE)
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	.byte 0x04
	jr	f, -45
	swi	5
	incf
	.byte 0x01
	jr	gt, -45
	swi	5
	ldwio	1, 0xf320
	swi	5
	ret
	.byte 0x01, 0x50
	lda	xwa, (xsp+10)
	ld	xbc, (xsp+4)
	call	CalcTotalWidth
	ld	wa, (xsp+266)
	add	wa, hl
	ld	(xsp+274), wa
	.byte 0xd3
	swi	5
	incf
	.byte 0x01
	ldb	w, 243
	swi	5
	rcf
	.byte 0x01, 0x50
	ld	xwa, (xsp+4)
	call	GetCharDescent
	ld	(xsp+8), hl
	ld	xwa, (xsp+4)
	call	GetCharHeight
	ld	wa, (xsp+268)
	add	wa, hl
	.byte 0x9f
	ldio	160, 243
	swi	5
	push_a
	.byte 0x01, 0x50
	lda	xwa, (xsp+270)
	ld	xhl, xwa
	lda	xwa, (xsp+266)
	ld	xbc, xwa
	lda	xwa, (xsp+10)
	ld	xde, xwa
	ld	xwa, (xsp+4)
	push	xwa
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	pop	xiz
	.byte 0xf3
	swi	5
	ccf
	.byte 0x01, 0x37
	ret
	dec	8, xsp
	ld	xbc, xwa
	ld	wa, (xbc+2)
	extz	xwa
	ld	l, (xbc+4)
	ld	e, (xbc+5)
	ld	a, (xwa)
	and	a, l
	ld	l, a
	ld	a, e
	and	a, 15
	jr	z, 2
	.byte 0xcf
	swi	7
	ld	a, l
	mul	a, 3
	extz	wa
	add	wa, wa
	ld	xbc, (xbc+7)
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	ldw	bc, 8337
	extz	xwa
	div	wa, 40
	ld	(xsp+2), wa
	ld	wa, (xbc)
	extz	xwa
	div	wa, 40
	.byte 0xd7, 0xe2
	or	(xwa-40), h
	pop	sr
	.byte 0xbf
	nop
	.byte 0x50
	ld	wa, (xsp+2)
	.byte 0x99, 0x04, 0x80
	ld	(xsp+6), wa
	ld	wa, (xbc+2)
	sll	wa, 3
	.byte 0x9f
	nop
	ldb	a, 216
	.byte 0x81
	ld	(xsp+4), bc
	lda	xwa, (xsp)
	ldw	bc, 245
	call	DrawBox
	inc	8, xsp
	ret
	dec	8, xsp
	ld	xbc, xwa
	ld	wa, (xbc+2)
	extz	xwa
	ld	l, (xbc+4)
	ld	e, (xbc+5)
	ld	a, (xwa)
	and	a, l
	ld	l, a
	ld	a, e
	and	a, 15
	jr	z, 2
	.byte 0xcf
	swi	7
	ld	a, l
	sll	a, 2
	extz	wa
	add	wa, wa
	ld	xbc, (xbc+7)
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	ldw	bc, 8337
	.byte 0xbf
	nop
	.byte 0x50
	ld	wa, (xbc+2)
	ld	(xsp+2), wa
	ld	wa, (xbc+4)
	ld	(xsp+4), wa
	ld	wa, (xbc+6)
	ld	(xsp+6), wa
	lda	xwa, (xsp)
	ldw	bc, 245
	call	DrawBox
	inc	8, xsp
	ret
Scoop_EnvCalc_Handler0:
	dec	8, xsp
	ld	bc, (xwa+2)
	extz	xbc
	div	bc, 40
	ld	(xsp+2), bc
	ld	bc, (xwa+2)
	extz	xbc
	div	bc, 40
	.byte 0xd7, 0xe6
	or	(xbc-39), h
	pop	sr
	.byte 0xbf
	nop
	.byte 0x51
	ld	bc, (xsp+2)
	.byte 0x98, 0x06, 0x81
	ld	(xsp+6), bc
	ld	wa, (xwa+4)
	sll	wa, 3
	.byte 0x9f
	nop
	ldb	a, 216
	.byte 0x81
	ld	(xsp+4), bc
	lda	xwa, (xsp)
	ldw	bc, 245
	call	DrawBox
	inc	8, xsp
	ret
Scoop_EnvCalc_Handler1:
	.byte 0xf3
	swi	5
	.byte 0xf4
	swi	6
	.byte 0x37
	ld	xiy, StyleUI_ScreenData_CtlOnly_0x123
	lda	xix, (xsp+260)
	lds	bc, 4
	.byte 0x95
	scf
	ld	hl, (xwa+2)
	ld	c, (xwa+1)
	dec	4, c
	ld	e, c
	extz	de
	ld	bc, hl
	extz	xbc
	div	bc, 40
	.byte 0xf3
	swi	5
	push	sr
	.byte 0x01, 0x51
	ld	bc, (xsp+258)
	muls	bc, 40
	sub	hl, bc
	sll	hl, 3
	.byte 0xf3
	swi	5
	nop
	.byte 0x01, 0x53
	lds	ix, 0
	cp	ix, de
	jr	nc, 38
	ld	bc, ix
	extz	xbc
	lda	xhl, (xsp)
	add	xhl, xbc
	ld	bc, ix
	extz	xbc
	inc	4, xbc
	add	xbc, xwa
	ld	c, (xbc)
	extz	bc
	lda_24	xiy, (StyleUI_ScreenData_CtlOnly_0x23)
	.byte 0xc3
	reti
	.byte 0xf4, 0xe4
	ldb	c, 179
	ld	xhl, 0xf4da61dc
	jr	c, -38
	ld	wa, ix
	extz	xwa
	lda	xbc, (xsp)
	add	xbc, xwa
	ld	(xbc), 0
	.byte 0xf3
	swi	5
	.byte 0x04, 0x01
	ldw	wa, 0x8be8
	.byte 0xf3
	swi	5
	nop
	.byte 0x01
	ldw	wa, 0x89e8
	lda	xwa, (xsp)
	ld	xde, xwa
	lds32	xwa, 6
	push	xwa
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	.byte 0xf3
	swi	5
	incf
	.byte 0x01, 0x37
	ret
Scoop_EnvCalc_Handler2:
	dec	8, xsp
	ld	bc, (xwa+2)
	ld	(xsp+4), bc
	ld	bc, (xwa+4)
	ld	(xsp+6), bc
	ld	bc, (xwa+6)
	.byte 0xbf
	nop
	.byte 0x51
	ld	wa, (xwa+8)
	ld	(xsp+2), wa
	lda	xwa, (xsp+4)
	ld	xde, xwa
	lda	xwa, (xsp)
	ld	xbc, xwa
	ld	xwa, xde
	ldw	de, 255
	call	DrawLine
	inc	8, xsp
	ret
Scoop_EnvCalc_Handler3:
	lda	xsp, (xsp-12)
	pushw	iz
	ld	bc, (xwa+3)
	extz	xbc
	div	bc, 40
	ld	(xsp+12), bc
	ld	bc, (xwa+3)
	extz	xbc
	div	bc, 40
	.byte 0xd7, 0xe6
	or	(xbc-39), h
	pop	sr
	ld	(xsp+10), bc
	ld	a, (xwa+2)
	.byte 0xc7
	swi	0
	.byte 0x99
	extz	iz
	ld	wa, (xsp+10)
	dec	2, wa
	ld	(xsp+2), wa
	ld	wa, (xsp+10)
	add	wa, 25
	ld	(xsp+6), wa
	ld	wa, (xsp+12)
	dec	2, wa
	ld	(xsp+4), wa
	ld	wa, (xsp+12)
	add	wa, 25
	ld	(xsp+8), wa
	lda	xwa, (xsp+2)
	ldw	bc, 196
	ldw	de, 240
	call	DrawDesignBox
	lda	xwa, (xsp+10)
	ld	xde, xwa
	ld	wa, iz
	inc	2, wa
	ld	bc, wa
	extz	xbc
	ld	xwa, xde
	call	DrawIcons
	popw	iz
	lda	xsp, (xsp+12)
	ret

Scoop_GlideParam_Setup:
	stb_dri L, 0xfd, 0xf4, 0xfe
	pushw iz
	ld hl, (xwa + 2)
	ld c, (xwa + 1)
	dec 4, c
	ld e, c
	extz de
	ld bc, hl
	extz xbc
	div bc, 0x28
	stw_dri BC, 0xfd, 0x04, 0x01
	ldw_sri0 BC, (xsp + 0x0104)
	muls bc, 0x28
	sub hl, bc
	sll hl, 3
	stw_dri HL, 0xfd, 0x02, 0x01
	lds ix, 0
	cp ix, de
	jr nc, Scoop_GlideParam_End

Scoop_GlideParam_Configure:
	ld bc, ix
	extz xbc
	lda xhl, (xsp + 2)
	add xhl, xbc
	ld bc, ix
	extz xbc
	inc 4, xbc
	add xbc, xwa
	ld c, (xbc)
	extz bc
	lda_24 xiy, (StyleUI_ScreenData_CtlOnly_0x23)
	ldb_sri C, 0x07, 0xf4, 0xe4
	ld (xhl), c
	inc 1, ix
	cp ix, de
	jr c, Scoop_GlideParam_Configure

Scoop_GlideParam_End:
	ld wa, ix
	extz xwa
	lda xbc, (xsp + 2)
	add xbc, xwa
	ld (xbc), 0x0
	dec_sriw 2, 0xfd, 0x04, 0x01
	ldw_sri0 WA, (xsp + 0x0102)
	stw_dri WA, 0xfd, 0x06, 0x01
	lda xwa, (xsp + 2)
	lds32 xbc, 0
	call CalcTotalWidth
	ldw_sri0 WA, (xsp + 0x0102)
	add wa, hl
	stw_dri WA, 0xfd, 0x0a, 0x01
	ldw_sri0 WA, (xsp + 0x0104)
	stw_dri WA, 0xfd, 0x08, 0x01
	lds32 xwa, 0
	call GetCharDescent
	ld iz, hl
	lds32 xwa, 0
	call GetCharHeight
	ldw_sri0 WA, (xsp + 0x0104)
	add wa, hl
	sub wa, iz
	stw_dri WA, 0xfd, 0x0c, 0x01
	stb_dri W, 0xfd, 0x06, 0x01
	ld xhl, xwa
	stb_dri W, 0xfd, 0x02, 0x01
	ld xbc, xwa
	lda xwa, (xsp + 2)
	ld xde, xwa
	lds32 xwa, 0
	push xwa
	pushw 0xff
	pushw 0xf5
	ld xwa, xhl
	call DrawString
	popw iz
	stb_dri L, 0xfd, 0x0c, 0x01
	ret

Scoop_GlideParam_Data:
	.byte 0xf3
	swi	5
	.byte 0xf4
	swi	6
	.byte 0x37
	ld	xiy, StyleUI_ScreenData_CtlOnly_0x12B
	lda	xix, (xsp+260)
	lds	bc, 4
	.byte 0x95
	scf
	ld	hl, (xwa+2)
	ld	c, (xwa+1)
	dec	4, c
	ld	e, c
	extz	de
	ld	bc, hl
	extz	xbc
	div	bc, 40
	.byte 0xf3
	swi	5
	push	sr
	.byte 0x01, 0x51, 0xd3
	swi	5
	push	sr
	.byte 0x01
	ldb	a, 217
	push	40
	nop
	sub	hl, bc
	sll	hl, 3
	.byte 0xf3
	swi	5
	nop
	.byte 0x01, 0x53
	lds	ix, 0
	cp	ix, de
	jr	nc, 38
	ld	bc, ix
	extz	xbc
	lda	xhl, (xsp)
	add	xhl, xbc
	ld	bc, ix
	extz	xbc
	inc	4, xbc
	add	xbc, xwa
	ld	c, (xbc)
	extz	bc
	lda_24	xiy, (StyleUI_ScreenData_CtlOnly_0x23)
	.byte 0xc3
	reti
	.byte 0xf4, 0xe4
	ldb	c, 179
	ld	xhl, 0xf4da61dc
	jr	c, -38
	ld	wa, ix
	extz	xwa
	lda	xbc, (xsp)
	add	xbc, xwa
	ld	(xbc), 0
	.byte 0xf3
	swi	5
	.byte 0x04, 0x01
	ldw	wa, 0x8be8
	.byte 0xf3
	swi	5
	nop
	.byte 0x01
	ldw	wa, 0x89e8
	lda	xwa, (xsp)
	ld	xde, xwa
	lds32	xwa, 1
	push	xwa
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	.byte 0xf3
	swi	5
	incf
	.byte 0x01, 0x37
	ret
Scoop_GlideCalc_Handler0:
	.byte 0xf3
	swi	5
	.byte 0xf4
	swi	6
	.byte 0x37
	ld	xiy, StyleUI_ScreenData_CtlOnly_0x133
	.byte 0xf3
	swi	5
	.byte 0x04, 0x01
	ldw	ix, 0xacd9
	.byte 0x95
	scf
	ld	hl, (xwa+2)
	ld	c, (xwa+1)
	dec	4, c
	ld	e, c
	extz	de
	ld	bc, hl
	extz	xbc
	div	bc, 40
	.byte 0xf3
	swi	5
	push	sr
	.byte 0x01, 0x51
	ld	bc, (xsp+258)
	muls	bc, 40
	sub	hl, bc
	sll	hl, 3
	.byte 0xf3
	swi	5
	nop
	.byte 0x01, 0x53
	lds	ix, 0
	cp	ix, de
	jr	nc, 26
	ld	bc, ix
	extz	xbc
	lda	xhl, (xsp)
	add	xhl, xbc
	ld	bc, ix
	extz	xbc
	inc	4, xbc
	add	xbc, xwa
	ld	c, (xbc)
	ld	(xhl), c
	inc	1, ix
	cp	ix, de
	jr	c, -26
	ld	wa, ix
	extz	xwa
	lda	xbc, (xsp)
	add	xbc, xwa
	ld	(xbc), 0
	.byte 0xf3
	swi	5
	.byte 0x04, 0x01
	ldw	wa, 0x8be8
	.byte 0xf3
	swi	5
	nop
	.byte 0x01
	ldw	wa, 0x89e8
	lda	xwa, (xsp)
	ld	xde, xwa
	lds32	xwa, 2
	push	xwa
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	.byte 0xf3
	swi	5
	incf
	.byte 0x01, 0x37
	ret
Scoop_GlideCalc_Handler1:
	dec	8, xsp
	ld	bc, (xwa+2)
	.byte 0xbf
	nop
	.byte 0x51
	ld	bc, (xwa+4)
	ld	(xsp+2), bc
	ld	bc, (xwa+6)
	ld	(xsp+4), bc
	ld	wa, (xwa+8)
	ld	(xsp+6), wa
	lda	xwa, (xsp)
	ldw	bc, 255
	call	DrawFrame
	inc	8, xsp
	ret
Scoop_GlideCalc_Handler2:
	lda	xsp, (xsp-16)
	push	xiz
	ld	xiz, xwa
	ld	wa, (xiz+2)
	ld	(xsp+12), wa
	ld	wa, (xiz+4)
	ld	(xsp+14), wa
	ld	wa, (xiz+6)
	ld	(xsp+16), wa
	ld	wa, (xiz+8)
	ld	(xsp+18), wa
	lda	xwa, (xsp+12)
	ldw	bc, 255
	call	DrawFrame
	ld	wa, (xiz+6)
	inc	1, wa
	ld	(xsp+8), wa
	ld	wa, (xiz+4)
	inc	1, wa
	ld	(xsp+10), wa
	ld	wa, (xiz+6)
	inc	1, wa
	ld	(xsp+4), wa
	ld	wa, (xiz+8)
	inc	1, wa
	ld	(xsp+6), wa
	lda	xwa, (xsp+8)
	ld	xde, xwa
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, xde
	ldw	de, 255
	call	DrawLine
	ld	wa, (xiz+6)
	inc	2, wa
	ld	(xsp+8), wa
	ld	wa, (xiz+4)
	inc	2, wa
	ld	(xsp+10), wa
	ld	wa, (xiz+6)
	inc	2, wa
	ld	(xsp+4), wa
	ld	wa, (xiz+8)
	inc	2, wa
	ld	(xsp+6), wa
	lda	xwa, (xsp+8)
	ld	xde, xwa
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, xde
	ldw	de, 255
	call	DrawLine
	ld	wa, (xiz+2)
	inc	1, wa
	ld	(xsp+8), wa
	ld	wa, (xiz+8)
	inc	1, wa
	ld	(xsp+10), wa
	ld	wa, (xiz+6)
	inc	1, wa
	ld	(xsp+4), wa
	ld	wa, (xiz+8)
	inc	1, wa
	ld	(xsp+6), wa
	lda	xwa, (xsp+8)
	ld	xde, xwa
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, xde
	ldw	de, 255
	call	DrawLine
	ld	wa, (xiz+2)
	inc	2, wa
	ld	(xsp+8), wa
	ld	wa, (xiz+8)
	inc	2, wa
	ld	(xsp+10), wa
	ld	wa, (xiz+6)
	inc	2, wa
	ld	(xsp+4), wa
	ld	wa, (xiz+8)
	inc	2, wa
	ld	(xsp+6), wa
	lda	xwa, (xsp+8)
	ld	xde, xwa
	lda	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xwa, xde
	ldw	de, 255
	call	DrawLine
	pop	xiz
	lda	xsp, (xsp+16)
	ret

Scoop_Dispatch_Nop:
	ret

Scoop_Dispatch_CallFAA98A:
	; --- Routine 1: copy (XWA+2..8) to stack, call FAA98A with DE=0xff (47 bytes) ---
	dec 8, xsp
	ld bc, (xwa+2)
	ld (xsp+4), bc
	ld bc, (xwa+4)
	ld (xsp+6), bc
	ld bc, (xwa+6)
	.byte 0xbf
	nop
	.byte 0x51
	ld wa, (xwa+8)
	ld (xsp+2), wa
	lda	xwa, (xsp+4)
	ld xde, xwa
	lda	xwa, (xsp)
	ld xbc, xwa
	ld xwa, xde
	ldw de, 0x00ff
	call DrawLine
	inc 8, xsp
	ret
Scoop_Dispatch_CallFAB273:
	; --- Routine 2: copy (XWA+2..8) to stack, call FAB273 with BC=0xf5 (38 bytes) ---
	dec 8, xsp
	ld bc, (xwa+2)
	.byte 0xbf
	nop
	.byte 0x51
	ld bc, (xwa+4)
	ld (xsp+2), bc
	ld bc, (xwa+6)
	ld (xsp+4), bc
	ld wa, (xwa+8)
	ld (xsp+6), wa
	lda	xwa, (xsp)
	ldw bc, 0x00f5
	call DrawBox
	inc 8, xsp
	ret


Scoop_EventLoop_12Entry:
	stb_dri L, 0xfd, 0x6a, 0xff
	push xiz
	stl_dri XBC, 0xfd, 0x96, 0x00
	ld xiz, xwa
	ld xiy, StyleUI_ScreenData_CtlOnly_0x13B
	lda xix, (xsp + 6)
	ldw bc, 0x48
	ldirw
	cpl_sri_mr XIZ, 0xfd, 0x96, 0x00
	jr ule, Scoop_EventLoop_12Entry_End

Scoop_EventLoop_12Entry_Process:
	ld c, (xiz)
	ld a, (xiz + 1)
	ld (xsp + 4), a
	cp c, 0x23
	jr ugt, Scoop_EventLoop_12Entry_End
	ld xwa, xiz
	extz bc
	sla bc, 2
	lda xde, (xsp + 6)
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	ld a, (xsp + 4)
	extz wa
	stb_dri H, 0x07, 0xf8, 0xe0
	cpl_sri_mr XIZ, 0xfd, 0x96, 0x00
	jr ugt, Scoop_EventLoop_12Entry_Process

Scoop_EventLoop_12Entry_End:
	pop xiz
	stb_dri L, 0xfd, 0x96, 0x00
	ret

Scoop_EnvProcessor_Data:
	.incbin "includes/generated/v7_transplant_Scoop_EnvProcessor_Data.bin"
Scoop_EventLoop_36Entry:
	.incbin "includes/generated/v7_transplant_Scoop_EventLoop_36Entry.bin"
Scoop_EventLoop_36Entry_Branch1:
	.incbin "includes/generated/v7_transplant_Scoop_EventLoop_36Entry_Branch1.bin"
Scoop_EventLoop_36Entry_Branch2:
	.incbin "includes/generated/v7_transplant_Scoop_EventLoop_36Entry_Branch2.bin"
Scoop_EventLoop_36Entry_Branch3:
	ld_sril XWA, (xsp + 0x0112)
	ld a, (xwa + 6)
	and a, 0x3f
	extz wa
	sla wa, 2
	lda_24 xbc, (Str_No_0xCEE)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 2), xwa
	ldw_sri0 WA, (xsp + 0x0106)
	stw_dri WA, 0xfd, 0x0a, 0x01
	lda xwa, (xsp + 6)
	ld xbc, (xsp + 2)
	call CalcTotalWidth
	ldw_sri0 WA, (xsp + 0x0106)
	add wa, hl
	stw_dri WA, 0xfd, 0x0e, 0x01
	ldw_sri0 WA, (xsp + 0x0108)
	inc 2, wa
	stw_dri WA, 0xfd, 0x0c, 0x01
	ld xwa, (xsp + 2)
	call GetCharDescent
	ld iz, hl
	ld xwa, (xsp + 2)
	call GetCharHeight
	ldw_sri0 WA, (xsp + 0x0108)
	add wa, hl
	sub wa, iz
	stw_dri WA, 0xfd, 0x10, 0x01
	stb_dri W, 0xfd, 0x0a, 0x01
	ld xhl, xwa
	stb_dri W, 0xfd, 0x06, 0x01
	ld xbc, xwa
	lda xwa, (xsp + 6)
	ld xde, xwa
	ld xwa, (xsp + 2)
	push xwa
	pushw 0xff
	pushw 0xf5
	ld xwa, xhl
	call DrawString
	popw iz
	stb_dri L, 0xfd, 0x14, 0x01
	ret

Scoop_EventLoop_36Entry_Data:
	.incbin "includes/generated/v7_transplant_Scoop_EventLoop_36Entry_Data.bin"
Scoop_EventLoop_12Entry_Alt:
	lda xsp, (xsp - 54)
	push xiz
	ld (xsp + 54), xbc
	ld xiz, xwa
	ld xiy, GUI_FormatStrings_0x3C
	lda xix, (xsp + 6)
	ldw bc, 0x18
	ldirw
	cp (xsp + 54), xiz
	jr ule, Scoop_EventLoop_12Entry_Alt_End

Scoop_EventLoop_12Entry_Alt_Process:
	ld c, (xiz)
	ld a, (xiz + 1)
	ld (xsp + 4), a
	cp c, 0xb
	jr ule, Scoop_EventLoop_12Entry_Alt_Dispatch
	ld xwa, xiz
	calr Scoop_Dispatch_Nop
	jr Scoop_EventLoop_12Entry_Alt_End

Scoop_EventLoop_12Entry_Alt_Dispatch:
	ld xwa, xiz
	extz bc
	sla bc, 2
	lda xde, (xsp + 6)
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	ld a, (xsp + 4)
	extz wa
	stb_dri H, 0x07, 0xf8, 0xe0
	cp (xsp + 54), xiz
	jr ugt, Scoop_EventLoop_12Entry_Alt_Process

Scoop_EventLoop_12Entry_Alt_End:
	pop xiz
	lda xsp, (xsp + 54)
	ret

.macro RegObjTable ParamA, ParamB, ParamC, ParamD, ParamE
	mri_d2 0xb7, 0x31
	.if \ParamA <= 7
	lds32 xwa, \ParamA
	.else
	ld xwa, \ParamA
	.endif
	ld (xbc), xwa
	lda_24 xwa, (\ParamB)
	ld (xbc + 4), xwa
	ldw_da xwa, (\ParamC)
	ld (xbc + 8), wa
	lda_24 xwa, (\ParamD)
	ld (xbc + 10), xwa
	.if \ParamE <= 7
	lds wa, \ParamE
	.else
	ldw wa, \ParamE
	.endif
	call RegisterObjectTable
.endm


.macro RegObjTabl ParamA, ParamB, ParamC, ParamD, ParamE
	mri_d2 0xb7, 0x31
	.if \ParamA <= 7
	lds32 xwa, \ParamA
	.else
	ld xwa, \ParamA
	.endif
	ld (xbc), xwa
	lda_24 xwa, (\ParamB)
	ld (xbc + 4), xwa
	ldw (xbc + 8), \ParamC
	lda_24 xwa, (\ParamD)
	ld (xbc + 10), xwa
	.if \ParamE <= 7
	lds wa, \ParamE
	.else
	ldw wa, \ParamE
	.endif
	call RegisterObjectTable
.endm


.macro RegMode ParamA, ParamBhi, ParamBlow, ParamC, ParamD, ParamE
	pushw \ParamA
	pushw \ParamBhi
	pushw \ParamBlow
	.if \ParamC <= 7
	lds32 xwa, \ParamC
	.else
	ld xwa, \ParamC
	.endif
	.if \ParamD <= 7
	lds32 xbc, \ParamD
	.else
	ld xbc, \ParamD
	.endif
	.if \ParamE <= 7
	lds32 xde, \ParamE
	.else
	ld xde, \ParamE
	.endif
	call RegisterMode
.endm


.macro RegTitle ParamA, ParamBhi, ParamBlow, ParamC, ParamD, ParamE
	pushw \ParamA
	pushw \ParamBhi
	pushw \ParamBlow
	.if \ParamC <= 7
	lds32 xwa, \ParamC
	.else
	ld xwa, \ParamC
	.endif
	.if \ParamD <= 7
	lds32 xbc, \ParamD
	.else
	ld xbc, \ParamD
	.endif
	.if \ParamE <= 7
	lds32 xde, \ParamE
	.else
	ld xde, \ParamE
	.endif
	call RegisterTitle
.endm


InitializeScoop:
	lda xsp, (xsp - 14)

	RegObjTable 0x1600004, 0xfa40d5, 0xe0cdac, 0xe0cd94, 0x166
	RegObjTable 0x160000c, 0xfa54ee, 0xe0cdb2, 0xe0cdae, 0x1c6
	RegObjTable 0x160000d, 0xfa553b, 0xe0cdb8, 0xe0cdb4, 0x1e6
	RegObjTabl 0x1600002, ApFunctionProc, 0x0, 0xe0cd8a, 0x126
	RegObjTabl 0x1600002, ApFunctionProc, 0x0, 0xe0cd8e, 0x426
	RegObjTabl 0x1600001, FunctionProc, 0x0, 0xe0cdba, 0x106
	RegObjTabl 0x1600001, FunctionProc, 0x0, 0xe0cdbe, 0x406
	RegObjTabl 0x1600003, MainFunctionProc, 0x21, 0xe0d72e, 0x146
	RegObjTabl 0x1600003, MainFunctionProc, 0x21, 0xe0d7b6, 0x446
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d204, 0x20
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d304, 0x320
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d20c, 0x21
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d316, 0x321
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d214, 0x22
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d328, 0x322
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d21c, 0x23
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d33c, 0x323
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d224, 0x24
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d350, 0x324
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d22c, 0x25
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d364, 0x325
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d234, 0x26
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d378, 0x326
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d23c, 0x27
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d38c, 0x327
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d244, 0x28
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d3a0, 0x328
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d24c, 0x29
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d3b4, 0x329
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d254, 0x2a
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d3c8, 0x32a
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d25c, 0x2b
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d3dc, 0x32b
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d264, 0x2c
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d3f0, 0x32c
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d26c, 0x2d
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d404, 0x32d
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d274, 0x2e
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d418, 0x32e
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d27c, 0x2f
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d42c, 0x32f
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d284, 0x30
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d440, 0x330
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d28c, 0x31
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d454, 0x331
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d294, 0x32
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d468, 0x332
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d29c, 0x33
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d47c, 0x333
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d2a4, 0x34
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d490, 0x334
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d2ac, 0x35
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d4a4, 0x335
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d2b4, 0x36
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d4b8, 0x336
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d2bc, 0x37
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d4cc, 0x337
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d2c4, 0x38
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d4e0, 0x338
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d2cc, 0x39
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d4f4, 0x339
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d2d4, 0x3a
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d508, 0x33a
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d2dc, 0x3b
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d51c, 0x33b
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d2e4, 0x3c
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d52e, 0x33c
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d2ec, 0x3d
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d540, 0x33d
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d2f4, 0x3e
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d552, 0x33e
	RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe0d2fc, 0x3f
	RegObjTabl 0x160000f, ResNameProc, 0x1, 0xe0d566, 0x33f

	RegMode 0x6, 0xe0, 0xd57a, 0x3, 0x1460000, 0x1a00020

	RegTitle 0x6, 0xe0, 0xd588, 0x20, 0x1460001, 0x200000
	RegTitle 0x6, 0xe0, 0xd592, 0x21, 0x1460002, 0x210000
	RegTitle 0x6, 0xe0, 0xd59c, 0x22, 0x1460003, 0x220000
	RegTitle 0x6, 0xe0, 0xd5aa, 0x23, 0x1460004, 0x230000
	RegTitle 0x6, 0xe0, 0xd5b8, 0x24, 0x1460005, 0x240000
	RegTitle 0x6, 0xe0, 0xd5c6, 0x25, 0x1460006, 0x250000
	RegTitle 0x6, 0xe0, 0xd5d4, 0x26, 0x1460007, 0x260000
	RegTitle 0x6, 0xe0, 0xd5e2, 0x27, 0x1460008, 0x270000
	RegTitle 0x6, 0xe0, 0xd5f0, 0x28, 0x1460009, 0x280000
	RegTitle 0x6, 0xe0, 0xd5fe, 0x29, 0x146000a, 0x290000
	RegTitle 0x6, 0xe0, 0xd60c, 0x2a, 0x146000b, 0x2a0000
	RegTitle 0x6, 0xe0, 0xd61a, 0x2b, 0x146000c, 0x2b0000
	RegTitle 0x6, 0xe0, 0xd628, 0x2c, 0x146000d, 0x2c0000
	RegTitle 0x6, 0xe0, 0xd636, 0x2d, 0x146000e, 0x2d0000
	RegTitle 0x6, 0xe0, 0xd644, 0x2e, 0x146000f, 0x2e0000
	RegTitle 0x6, 0xe0, 0xd652, 0x2f, 0x1460010, 0x2f0000
	RegTitle 0x6, 0xe0, 0xd660, 0x30, 0x1460011, 0x300000
	RegTitle 0x6, 0xe0, 0xd66e, 0x31, 0x1460012, 0x310000
	RegTitle 0x6, 0xe0, 0xd67c, 0x32, 0x1460013, 0x320000
	RegTitle 0x6, 0xe0, 0xd68a, 0x33, 0x1460014, 0x330000
	RegTitle 0x6, 0xe0, 0xd698, 0x34, 0x1460015, 0x340000
	RegTitle 0x6, 0xe0, 0xd6a6, 0x35, 0x1460016, 0x350000
	RegTitle 0x6, 0xe0, 0xd6b4, 0x36, 0x1460017, 0x360000
	RegTitle 0x6, 0xe0, 0xd6c2, 0x37, 0x1460018, 0x370000
	RegTitle 0x6, 0xe0, 0xd6d0, 0x38, 0x1460019, 0x380000
	RegTitle 0x6, 0xe0, 0xd6de, 0x39, 0x146001a, 0x390000
	RegTitle 0x6, 0xe0, 0xd6ec, 0x3a, 0x146001b, 0x3a0000
	RegTitle 0x6, 0xe0, 0xd6f8, 0x3b, 0x146001c, 0x3b0000
	RegTitle 0x6, 0xe0, 0xd702, 0x3c, 0x146001d, 0x3c0000
	RegTitle 0x6, 0xe0, 0xd70c, 0x3d, 0x146001e, 0x3d0000
	RegTitle 0x6, 0xe0, 0xd716, 0x3e, 0x146001f, 0x3e0000
	RegTitle 0x6, 0xe0, 0xd722, 0x3f, 0x1460020, 0x3f0000

	lda xsp, (xsp + 14)
	ret


; Sound Editor mode and title routines
	.include "audio/sound_editor_routines.s"
