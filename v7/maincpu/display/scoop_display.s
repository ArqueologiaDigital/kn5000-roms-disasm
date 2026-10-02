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
	lda xwa, (0x1a0000:24)
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
	ldw (0x0205e6:24), 0x0000
	ldw (0x0205e4:24), 0x0000
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
	ld (0x0205e6:24), 0x01
	cpw (0x0205e4:24), 0
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
	ldw (0x0205e4:24), 0xffff
	ret

; Undisassembled data block (18 bytes) - possibly lookup table
Display_Data_ScoopInit:
	ld	a, 255:opc
	ld	(0x0205ea:24), a
	ld	(0x0205e8:24), a
	ld	(0x0205ec:24), a
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion0 - Update status bar region (bit 0)
;
; Checks if status bar needs refresh by comparing cached values.
; If changed, calls the status bar redraw routine.
;-----------------------------------------------------------------------------
Display_UpdateRegion0:
	bit 0, (0x0205e6:24)
	jr nz, Display_UpdateRegion0_Check
	set 0, (0x0205e4:24)
	ret

Display_UpdateRegion0_Check:
	bit 0, (0x0205e4:24)
	jr z, Display_UpdateRegion0_Done
	pushw wa
	ld a, (3429:16)
	cp a, (0x0205ea:24)
	jr nz, Display_UpdateRegion0_Changed
	ld a, (3567:16)
	cp a, (0x0205e8:24)
	jr nz, Display_UpdateRegion0_Changed
	ld a, (3424:16)
	cp a, (0x0205ec:24)
	jr z, Display_UpdateRegion0_NoChange

Display_UpdateRegion0_Changed:
	bit 0, (3927:16)
	jrl nz, Display_UpdateRegion0_NoChange
	call Display_RedrawStatusBar
	ld a, (3429:16)
	ld (0x0205ea:24), a
	ld a, (3567:16)
	ld (0x0205e8:24), a
	ld a, (3424:16)
	ld (0x0205ec:24), a

Display_UpdateRegion0_NoChange:
	popw wa

Display_UpdateRegion0_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion1 - Update title bar region (bit 1)
;-----------------------------------------------------------------------------
Display_UpdateRegion1:
	bit 0, (0x0205e6:24)
	jr nz, Display_UpdateRegion1_Check
	set 1, (0x0205e4:24)
	ret

Display_UpdateRegion1_Check:
	bit 1, (0x0205e4:24)
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
	bit 0, (0x0205e6:24)
	jr nz, Display_UpdateRegion3_Check
	set 3, (0x0205e4:24)
	ret

Display_UpdateRegion3_Check:
	bit 3, (0x0205e4:24)
	jr z, Display_UpdateRegion3_Done
	call Display_RedrawMainContent

Display_UpdateRegion3_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion2 - Update selection highlight (bit 4)
;-----------------------------------------------------------------------------
Display_UpdateRegion2:
	bit 0, (0x0205e6:24)
	jr nz, Display_UpdateRegion2_Check
	set 4, (0x0205e4:24)
	ret

Display_UpdateRegion2_Check:
	bit 4, (0x0205e4:24)
	jr z, Display_UpdateRegion2_Done
	call Display_RedrawSelection

Display_UpdateRegion2_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion4 - Update side panel (bit 5)
;-----------------------------------------------------------------------------
Display_UpdateRegion4:
	bit 0, (0x0205e6:24)
	jr nz, Display_UpdateRegion4_Check
	set 5, (0x0205e4:24)
	ret

Display_UpdateRegion4_Check:
	bit 5, (0x0205e4:24)
	jr z, Display_UpdateRegion4_Done
	call Display_RedrawSidePanel

Display_UpdateRegion4_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion5 - Update menu area (bit 6)
;-----------------------------------------------------------------------------
Display_UpdateRegion5:
	bit 0, (0x0205e6:24)
	jr nz, Display_UpdateRegion5_Check
	set 6, (0x0205e4:24)
	ret

Display_UpdateRegion5_Check:
	bit 6, (0x0205e4:24)
	jr z, Display_UpdateRegion5_Done
	call Display_RedrawMenu

Display_UpdateRegion5_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion6 - Update button labels (bit 7)
;-----------------------------------------------------------------------------
Display_UpdateRegion6:
	bit 0, (0x0205e6:24)
	jr nz, Display_UpdateRegion6_Check
	set 7, (0x0205e4:24)
	ret

Display_UpdateRegion6_Check:
	bit 7, (0x0205e4:24)
	jr z, Display_UpdateRegion6_Done
	call Display_RedrawButtonLabels

Display_UpdateRegion6_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion7 - Update parameter display (bit 0 of 0x205e5)
;-----------------------------------------------------------------------------
Display_UpdateRegion7:
	bit 0, (0x0205e6:24)
	jr nz, Display_UpdateRegion7_Check
	set 0, (0x0205e5:24)
	ret

Display_UpdateRegion7_Check:
	bit 0, (0x0205e5:24)
	jr z, Display_UpdateRegion7_Done
	call Display_RedrawParameters

Display_UpdateRegion7_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion8 - Update value display (bit 1 of 0x205e5)
;-----------------------------------------------------------------------------
Display_UpdateRegion8:
	bit 0, (0x0205e6:24)
	jr nz, Display_UpdateRegion8_Check
	set 1, (0x0205e5:24)
	ret

Display_UpdateRegion8_Check:
	bit 1, (0x0205e5:24)
	jr z, Display_UpdateRegion8_Done
	call Display_RedrawValues

Display_UpdateRegion8_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion9 - Update indicator area (bit 2 of 0x205e5)
;-----------------------------------------------------------------------------
Display_UpdateRegion9:
	bit 0, (0x0205e6:24)
	jr nz, Display_UpdateRegion9_Check
	set 2, (0x0205e5:24)
	ret

Display_UpdateRegion9_Check:
	bit 2, (0x0205e5:24)
	jr z, Display_UpdateRegion9_Done
	call Display_RedrawIndicators

Display_UpdateRegion9_Done:
	ret

;-----------------------------------------------------------------------------
; Display_UpdateRegion10 - Update footer area (bit 3 of 0x205e5)
;-----------------------------------------------------------------------------
Display_UpdateRegion10:
	bit 0, (0x0205e6:24)
	jr nz, Display_UpdateRegion10_Check
	set 3, (0x0205e5:24)
	ret

Display_UpdateRegion10_Check:
	bit 3, (0x0205e5:24)
	jr z, Display_UpdateRegion10_Done
	call Display_RedrawFooter

Display_UpdateRegion10_Done:
	ret

UIRender_SingleTable:
	bit 0, (0x0205e6:24)
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
	bit 0, (0x0205e6:24)
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
	bit 0, (0x0205e6:24)
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
	bit 0, (0x0205e6:24)
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
	bit 0, (0x0205e6:24)
	jr nz, UIRender_TwoTableEvtCheck_Body
	ret

UIRender_TwoTableEvtCheck_Body:
	push xwa
	ld xwa, xiy
	call ColorBlit_WithPaletteSave
	pop xwa
	ret

UIRender_ConditionalDrawInit:
	bit 0, (0x0205e6:24)
	jr nz, UIRender_ConditionalDrawInit_Body
	ret

UIRender_ConditionalDrawInit_Body:
	push xwa
	ld xwa, xiy
	call DrawFunc_Init
	pop xwa
	ret

Scoop_ConditionalCurveUpdate:
	bit 0, (0x0205e6:24)
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
	bit 0, (0x0205e6:24)
	jr nz, Scoop_ConditionalGlideSetup_Body
	ret

Scoop_ConditionalGlideSetup_Body:
	push xwa
	ld xwa, xiy
	call Scoop_GlideParam_Setup
	pop xwa
	ret

UIRender_ConditionalFBCall:
	bit 0, (0x0205e6:24)
	jr nz, UIRender_ConditionalFBCall_Body
	ret

UIRender_ConditionalFBCall_Body:
	push xwa
	ld xwa, xiy
	call ColorBlit_ComputeRectAndBlit
	pop xwa
	ret

GraphicsRender_EventCheck:
	bit 0, (0x0205e6:24)
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

	; Byte data, 129 B.  Read by UIRender_LoadTwoDescriptors (0xEF5D79): `ld xiy, UIRender_DescriptorTable1`
	; reader UIRender_LoadTwoDescriptors: `ld xiy, UIRender_DescriptorTable1`
UIRender_DescriptorTable1:
	.byte	0x0e, 0x08, 0x12, 0x06, 0x06, 0x00, 0x13, 0x00, 0x0e, 0x08, 0x52, 0x0c, 0x06, 0x00, 0x13, 0x00
	.byte	0x0e, 0x08, 0x92, 0x12, 0x06, 0x00, 0x13, 0x00, 0x1b, 0x0a, 0x0b, 0x01, 0x9e, 0x00, 0x35, 0x01
	.byte	0xb1, 0x00, 0x07, 0x05, 0x77, 0x19, 0x20, 0x20, 0x29, 0x19, 0x1f, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte	0x20, 0x09, 0x1a, 0x17, 0x20, 0x20, 0x20, 0x20, 0x20, 0x0e, 0x08, 0xd5, 0x20, 0x05, 0x00, 0xec
	.byte	0x00, 0x0e, 0x08, 0xda, 0x20, 0x05, 0x00, 0xec, 0x00, 0x0e, 0x08, 0xdf, 0x20, 0x05, 0x00, 0xec
	.byte	0x00, 0x0e, 0x08, 0xe4, 0x20, 0x05, 0x00, 0xec, 0x00, 0x0e, 0x08, 0xe9, 0x20, 0x05, 0x00, 0xec
	.byte	0x00

UIRender_DescriptorTable2:
	calr	ParamDigit_DivideValue
	bit	1, (0x1185:16)
	jr	nz, UIRender_DescriptorTable2_Return
	ldw_d16	wa, (0x1182)
	ld	(0x1181:16), wa
	ld	(4483:16), 32
	bit	0, (0x1185:16)
	jr	nz, UIRender_DescriptorTable2_Return
	ldw_d16	wa, (0x1182)
	ld	(0x1181:16), wa
UIRender_DescriptorTable2_Return:
	ret

ParamDigit_ExtractAndFormat:
	calr ParamDigit_DivideValue
	bit 1, (4485:16)
	jr nz, ParamDigit_ExtractDone
	ld (4481:16), 32
	bit 0, (4485:16)
	jr nz, ParamDigit_ExtractDone
	ld (4482:16), 32

ParamDigit_ExtractDone:
	ret

ParamDigit_CalrData:
	calr	ScoopDisp_BytecodeBlock1
	calr	ParamDigit_ExtractAndFormat
	ret
	calr	ScoopDisp_BytecodeBlock1
	calr	UIRender_DescriptorTable2
	ret

ParamDigit_DivideValue:
	push c
	and (4485:16), 252
	ld (4481:16), 0
	ldw (4482:16), 0
	cp wa, 0:i3
	jr z, ParamUpdate_AddAndStore
	xor c, c

ParamDigit_Div100Loop:
	sub wa, 0x64
	jr c, ParamDigit_Div100Done
	inc 1, c
	or (4485:16), 2
	cp wa, 0:i3
	jr nz, ParamDigit_Div100Loop
	ld (4481:16), c
	jr ParamUpdate_AddAndStore

ParamDigit_Div100Done:
	ld (4481:16), c
	add wa, 0x64
	xor c, c

ParamDigit_Div10Loop:
	sub wa, 0xa
	jr c, ParamDigit_Div10Done
	inc 1, c
	or (4485:16), 1
	cp wa, 0:i3
	jr nz, ParamDigit_Div10Loop
	ld (4482:16), c
	jr ParamUpdate_AddAndStore

ParamDigit_Div10Done:
	ld (4482:16), c
	add wa, 0xa
	ld (4483:16), a


; -----------------------------------------------------------------------------
; Section: Parameter Update Routines
; -----------------------------------------------------------------------------
; Parameter add/store, zero-check, and conditional
; update helpers.
; -----------------------------------------------------------------------------

ParamUpdate_AddAndStore:
	add (4481:16), 48
	addw (4482:16), 0x3030
	pop c
	ret

ScoopDisp_BytecodeBlock1:
	cp	de, 0:i3
	jr	z, ScoopDisp_BytecodeBlock1_Join
	jr	gt, ScoopDisp_BytecodeBlock1_Skip
	xor	de, 0xffff
	inc	1, de
	add	wa, de
	jr	ScoopDisp_BytecodeBlock1_Join
ScoopDisp_BytecodeBlock1_Skip:
	sub	wa, de
ScoopDisp_BytecodeBlock1_Join:
	cp	wa, 0:i3
	jr	z, ScoopDisp_BytecodeBlock1_Skip3
	jr	gt, ScoopDisp_BytecodeBlock1_Skip2
	xor	wa, 0xffff
	inc	1, wa
	ld	(4480:16), 45
	jr	ScoopDisp_BytecodeBlock1_Return
ScoopDisp_BytecodeBlock1_Skip2:
	ld	(4480:16), 43
	jr	ScoopDisp_BytecodeBlock1_Return
ScoopDisp_BytecodeBlock1_Skip3:
	ld (4480:16), 32
ScoopDisp_BytecodeBlock1_Return:
	ret
ScoopDisp_BytecodeBlock1_0x32:
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
	call	ScoopDisp_BytecodeBlock1_Helper
	ld	a, l
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	ret
ScoopDisp_BytecodeBlock1_0x4D:
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
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	ret

ChannelFilter_InitAndApply:
	call ChannelFilter_SetMode
	call ChannelFilter_ApplyWrapper
	ldw (4360:16), 0
	ret

ChannelFilter_SetMode:
	ld (3294:16), 2
	ret

ChannelFilter_ApplyWrapper:
	calr ChannelFilter_ApplyMask
	ret

ChannelFilter_ApplyMask:
	ld de, (0xf19e:16)
	push	sr
	cpl de
	pop	sr
	ld xhl, 0xf1a0
	xor bc, bc

ChannelFilter_BitScanLoop:
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld a, c
	scf
	xorcfw_erp 0x3e
	ldto_berp A, 0x3c
	jr c, ChannelFilter_NextBit
	ld iy, bc
	ld	a, (xhl+iy)
	cp a, 0xd
	jr z, ChannelFilter_ClearBit
	cp a, 0x10
	jr nz, ChannelFilter_NextBit

ChannelFilter_ClearBit:
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld a, c
	rcf
	stcfw_erp 0x3e
	ldto_berp A, 0x3c
	ldto_werp DE, 0x3e

ChannelFilter_NextBit:
	inc 1, c
	cp c, 0x10
	jr c, ChannelFilter_BitScanLoop
	ld wa, (0xf19e:16)
	ret

Display_LoadAndSetIndicator:
	call Display_LoadChannelMask
	xor wa, wa
	ld a, 0x4c:opc
	call CtrlPanel_SetIndicatorBit
	ret

Display_LoadChannelMask:
	ld wa, (0xf19e:16)
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
	ld l, (0x00ffe3:24)
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
	ldw	(4360:16), 0
	ret
Display_InitParamLoader1:
	; --- Param loader 1: C=0, A=0x0c, A=0x10, call FB1536 ---
	ld c, 0x00:opc
	ld a, 0x0c:opc
	ld a, 0x10:opc
	call Display_DeferOrDrawWall
	ld	(0x03efa8:24), 0
	ret
Display_InitParamLoader2:
	; --- Param loader 2: C=7, A=0x0c, call FB155F ---
	ld c, 0x07:opc
	ld a, 0x0c:opc
	call Display_DeferOrUpdateScreen
	ret
Display_CallMenuInit:
	; --- Simple wrapper: call EFA133 ---
	call Display_CallMenuInit_Helper
	ret
Display_ConditionalCompare:
	call Display_CallMenuConfig
	ld a, (0x8c9a:16)
	cp a, (0x8c9b:16)
	jr z, Display_ConditionalCompare_Ret
Display_ConditionalCompare_Ret:
	ret
Display_CallMenuConfig:
	; --- Simple wrapper: call EFA8CE ---
	call Display_CallMenuConfig_Helper
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
	ld a, 0x01:opc
	call AudioLock_GetCount
	cp	l, 0:i3
	jr z, Display_PollAudioDone
	ld a, 0x03:opc
	call TaskSched_YieldToQueue
	jr t, Display_PollAudioLoop
Display_PollAudioDone:
	call Display_DeletePollEvent
	ret
Display_DeletePollEvent:
	; --- XBC/XWA setup and call ---
	ld xbc, EVT_SW_IN
	ld	xwa, 0:i3
	call DeleteEvent
	ret
Display_CallSetupRoutine:
	; --- Simple wrapper: call EF61E9 ---
	call DisplayMode_Dispatch
	ret
Display_NullHandler:
	ret


MIDI_SendSysExFromW:
	ld	a, w
	call	MIDI_SendSysExCmd
	ret
SoundEvt_ShortPacketHandler:
	ld	(3923:16), 0
	or	(0xe31c:16), 8
	ld	w, 1:opc
	call	SoundEvt_ModeDispatch
	ret
SoundEvt_LongPacketHandler:
	ld	(3923:16), 0
	or	(0xe31c:16), 8
	ld	w, 2:opc
	call	SoundEvt_ModeDispatch
	ret
; SoundEvt_ModeDispatch -- if SeqState_HasModeChanged returns 0, dispatch on the
; display mode byte (0x0D65) & 3 through SoundEvt_ModeDispatch_Tbl.  Called with
; W = 1 / 2 by the two routines above.
SoundEvt_ModeDispatch:
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, SoundEvt_LongPacketHandler_Return
	ld	l, (3429:16)
	and	l, 3
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, SoundEvt_ModeDispatch_Tbl
	ld	xhl, (xix+hl)
	pop	xix
	call (xhl)
SoundEvt_LongPacketHandler_Return:
	ret
	; 4 handlers indexed by (0x0D65) & 3, the display mode; read by SoundEvt_ModeDispatch
	; (`ld xix, SoundEvt_ModeDispatch_Tbl`, stride 4).
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
SoundEvt_ModeDispatch_Tbl:
	.long	DefaultHandler_Ret
	.long	SoundEvt_LongPacketHandler_DispatchTbl_Target1
	.long	SoundEvt_LongPacketHandler_DispatchTbl_Target2
	.long	DefaultHandler_Ret
	; Entry 1 of SoundEvt_ModeDispatch_Tbl (a code pointer the table holds).
SoundEvt_LongPacketHandler_DispatchTbl_Target1:
	and	w, 3
	ld	(3925:16), w
	ex8 a, w
	exts	wa
	sla	wa, 2
	ld	iy, wa
	ld	wa, (13950:16)
	ld	(3816:16), wa
	ld	a, (3420:16)
	ld	(3821:16), a
	push	xhl
	ld	xhl, ScoopDisp_HandlerData2
	ld	xiy, (xhl+iy)
	pop	xhl
	call (xiy)
	ld	wa, (13950:16)
	cp wa, (3816:16)
	jrl	nz, SoundEvt_LongPacketHandler_Entry
	ld	a, (3420:16)
	ld	w, (3821:16)
	cp	a, w
	jrl	z, SoundEvt_LongPacketHandler_Join
	cp	(3421:16), 4
	jrl	ule, SoundEvt_LongPacketHandler_Join
	cp	w, 3:i3
	jrl	ugt, SoundEvt_LongPacketHandler_Skip
	cp	a, 3:i3
	jrl	ugt, SoundEvt_LongPacketHandler_Entry
	jp	SoundEvt_LongPacketHandler_Join
SoundEvt_LongPacketHandler_Skip:
	cp	a, 3:i3
	jrl	ule, SoundEvt_LongPacketHandler_Entry
SoundEvt_LongPacketHandler_Join:
	call	SoundEvt_LongPacketHandler_Helper2
	jp	SoundEvt_LongPacketHandler_DispatchTbl_Target1_Join
SoundEvt_LongPacketHandler_Entry:
	or	(0x0dd3:16), 1
	call	VoiceSlot_TableSetup
SoundEvt_LongPacketHandler_DispatchTbl_Target1_Join:
	call	SoundEvt_LongPacketHandler_Helper
	ret
	; Handler dispatch table, 16 B.  Read by SoundEvt_LongPacketHandler_DispatchTbl_Target1 (0xEF60B8): `ld xhl, ScoopDisp_HandlerData2`
	; indexed with stride 4 (`sla wa, 2`), index from `ld a, (3420:16)`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
ScoopDisp_HandlerData2:
	.long	VoiceCtrl_SendNoteOffSequence
	.long	Timer_ParamCompareAlt
	.long	Timer_ParamLoadAndCompare
	.long	DefaultHandler_Ret
	; Entry 2 of SoundEvt_ModeDispatch_Tbl (a code pointer the table holds).
SoundEvt_LongPacketHandler_DispatchTbl_Target2:
	and	w, 3
	ex8	a, w
	exts	wa
	sla	wa, 2
	ld	iy, wa
	ldw_d16	wa, (0x367e)
	ld	(0x0ee8:16), wa
	ldb_d8	a, (0x0d5c)
	stb_d8	(0x0eed), a
	push	xhl
	ld	xhl, SoundEvt_LongPacketHandler_DispatchTbl2
	ld	xiy, (xhl+iy)
	pop	xhl
	call	(xiy)
	ldw_d16	wa, (0x367e)
	cp	wa, (0x0ee8:16)
	jrl	nz, SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip2
	ldb_d8	a, (0x0d5c)
	ldb_d8	w, (0x0eed)
	cp	a, w
	jrl	z, SoundEvt_LongPacketHandler_DispatchTbl_Target2_Join
	cp	(0x0d5d:16), 4
	jrl	ule, SoundEvt_LongPacketHandler_DispatchTbl_Target2_Join
	cp	w, 3:i3
	jrl	ugt, SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip
	cp	a, 3:i3
	jrl	ugt, SoundEvt_LongPacketHandler_Entry
	jp	SoundEvt_LongPacketHandler_DispatchTbl_Target2_Join
SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip:
	cp	a, 3:i3
	jrl	ule, SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip2
SoundEvt_LongPacketHandler_DispatchTbl_Target2_Join:
	call	SoundEvt_LongPacketHandler_Helper2
	jp	SoundEvt_LongPacketHandler_DispatchTbl_Target2_Return
SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip2:
	or	(0x0dd3:16), 1
	call	VoiceSlot_TableSetup
SoundEvt_LongPacketHandler_DispatchTbl_Target2_Return:
	ret
	; Handler dispatch table, 16 B.  Read by SoundEvt_LongPacketHandler_DispatchTbl_Target2 (0xEF613F): `ld xhl, SoundEvt_LongPacketHandler_DispatchTbl2`
	; indexed with stride 4 (`sla wa, 2`)
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
SoundEvt_LongPacketHandler_DispatchTbl2:
	.long	DefaultHandler_Ret
	.long	Timer_ParamCompareAlt
	.long	Timer_ParamLoadAndCompare
	.long	DefaultHandler_Ret
DefaultHandler_Ret:
	ret
; DisplayMode_Dispatch -- if SeqState_HasModeChanged returns 0, dispatch on the
; display mode byte (0x0D65) & 3 through DisplayMode_Dispatch_Tbl, with BC (stored to
; 0x26C0) as the handlers' argument.  Called from Display_CallSetupRoutine.
DisplayMode_Dispatch:
	call SeqState_HasModeChanged
	cp hl, 0:i3
	jrl nz, .Lc_ef61e8
	ld e, (0x0d65:16)
	and E,0x03
	xor D,D
	sla DE, 0x02
	ld IY,DE
	ld (0x26c0:16), bc
	push XHL
	ld XHL,DisplayMode_Dispatch_Tbl
	ld	xiy, (xhl+iy)
	pop XHL
	call (XIY)
.Lc_ef61e8:
DisplayMode_Dispatch_Return:
	ret
	; 4 handlers indexed by (0x0D65) & 3, the display mode; read by DisplayMode_Dispatch
	; (`ld XHL,DisplayMode_Dispatch_Tbl / ld xiy, (xhl+iy) / call (XIY)`, stride 4)
DisplayMode_Dispatch_Tbl:
	.long	DisplayMode_Dispatch_Mode0
	.long	DisplayMode_Dispatch_Mode1
	.long	DisplayMode_Dispatch_Mode1
	.long	DisplayMode_Dispatch_Mode3
	; Entry 0 of DisplayMode_Dispatch_Tbl (a code pointer the table holds).
DisplayMode_Dispatch_Mode0:
	cp	(10430:16), 255
	jrl	nz, DefaultHandler_Ret_Skip4
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, DefaultHandler_Ret_Return
	cp	(3567:16), 18
	jrl	nz, DefaultHandler_Ret_Skip3
	cp	hl, 9
	jrl	z, DefaultHandler_Ret_Skip
	cp	hl, 10
	jrl	z, DefaultHandler_Ret_Skip2
	jp	DefaultHandler_Ret_Return
DefaultHandler_Ret_Skip:
	bit	7, w
	jrl	nz, DefaultHandler_Ret_Return
	call	DefaultHandler_Ret_Helper
	jp	DefaultHandler_Ret_Return
DefaultHandler_Ret_Skip2:
	bit	7, w
	jrl	nz, DefaultHandler_Ret_Return
	call	DefaultHandler_Ret_Helper2
	jp	DefaultHandler_Ret_Return
DefaultHandler_Ret_Skip3:
	sla	hl, 2
	push	xix
	ld	xix, ScoopDisp_DispatchTable_Small
	ld	xhl, (xix+hl)
	pop	xix
	call (xhl)
	jp	DefaultHandler_Ret_Return
DefaultHandler_Ret_Skip4:
	cp	bc, 15
	jrl	nz, DefaultHandler_Ret_Return
	call	ToneParam_Evt0F_BytecodeHandler
	jp	DefaultHandler_Ret_Return
DefaultHandler_Ret_Return:
	ret
ScoopDisp_FlagSetAndDispatch:
	or	(0xe31c:16), 8
	bit	7, w
	jrl	z, ScoopDisp_FlagSetAndDispatch_Skip
	call	VoiceState_DataBlock2_Helper6
	jp	ScoopDisp_FlagSetAndDispatch_Return
ScoopDisp_FlagSetAndDispatch_Skip:
	call	ScoopDisp_FlagSetAndDispatch_Helper
ScoopDisp_FlagSetAndDispatch_Return:
	ret	
	; Handler dispatch table, 128 B.  Read by DisplayMode_Dispatch_Mode0 (0xEF61F9): `ld xix, ScoopDisp_DispatchTable_Small`
	; indexed with stride 4 (`sla hl, 2`)
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
ScoopDisp_DispatchTable_Small:
	.long	ScoopDisp_FlagSetAndDispatch
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ScoopDisp_DispatchTable_Small_Target11
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	ScoopDisp_FlagSetAndDispatch
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
ToneParam_Evt0F_BytecodeHandler:
	bit	7, w
	jrl	nz, ToneParam_Evt0F_BytecodeHandler_Return
	and	(0x266a:16), 254
	xor	wa, wa
	ld	a, 137:opc
	call	UI_PostModeChangeEvent
	jp	ToneParam_Evt0F_BytecodeHandler_Return
ToneParam_Evt0F_BytecodeHandler_Return:
	ret
	; Entry 1 of DisplayMode_Dispatch_Tbl (a code pointer the table holds).
DisplayMode_Dispatch_Mode1:
	and	(0x0dd3:16), 254
	ld	e, (3567:16)
	xor	d, d
	sla	de, 2
	ld	iy, de
	push	xhl
	ld	xhl, PerfMode_ParamHandler_Table
	ld	xiy, (xhl+iy)
	pop xhl
	call	(xiy)
	or	(0x0dd3:16), 1
	ld	bc, (9920:16)
	cp	bc, 15
	jrl	z, ToneParam_Evt0F_BytecodeHandler_Return2
	cp	bc, 0:i3
	jrl	z, ToneParam_Evt0F_BytecodeHandler_Skip
	and	(0x0f57:16), 254
ToneParam_Evt0F_BytecodeHandler_Skip:
	bit	0, (0x0f57:16)
	jrl	nz, ToneParam_Evt0F_BytecodeHandler_Skip5
	ldb_d8	a, (0x0def)
	cp	a, 0:i3
	jrl	nz, ToneParam_Evt0F_BytecodeHandler_Skip2
	cp	bc, 6:i3
	jrl	ule, ToneParam_Evt0F_BytecodeHandler_Skip5
ToneParam_Evt0F_BytecodeHandler_Skip2:
	cp	a, 3:i3
	jrl	nz, ToneParam_Evt0F_BytecodeHandler_Skip3
	cp	bc, 4:i3
	jrl	z, ToneParam_Evt0F_BytecodeHandler_Skip5
ToneParam_Evt0F_BytecodeHandler_Skip3:
	cp	a, 7:i3
	jrl	nz, ToneParam_Evt0F_BytecodeHandler_Skip4
	cp	bc, 3:i3
	jrl	z, ToneParam_Evt0F_BytecodeHandler_Skip5
ToneParam_Evt0F_BytecodeHandler_Skip4:
	cp	a, 9
	jrl	nz, ToneParam_Evt0F_BytecodeHandler_Skip6
	cp	bc, 4:i3
	jrl	z, ToneParam_Evt0F_BytecodeHandler_Skip5
	jp	ToneParam_Evt0F_BytecodeHandler_Skip6
ToneParam_Evt0F_BytecodeHandler_Skip5:
	and	(0x0dd3:16), 254
ToneParam_Evt0F_BytecodeHandler_Skip6:
	call	VoiceSlot_TableSetup
	call	DisplayMode_Dispatch_Mode1_Helper
ToneParam_Evt0F_BytecodeHandler_Return2:
	ret

; -----------------------------------------------------------------------------
; Section: Performance Mode Parameter Handlers
; -----------------------------------------------------------------------------
; Parameter handler dispatch table and individual
; handlers for each performance mode parameter.
; -----------------------------------------------------------------------------

PerfMode_ParamHandler_Table:
	.long PerfMode_ParamHandler_0
	.long PerfMode_ParamHandler_1
	.long PerfMode_ParamHandler_2
	.long PerfMode_ParamHandler_3
	.long PerfMode_ParamHandler_4
	.long PerfMode_ParamHandler_5
	.long PerfMode_ParamHandler_2
	.long PerfMode_ParamHandler_7
	.long PerfMode_ParamHandler_8
	.long PerfMode_ParamHandler_9
	.long PerfMode_ParamHandler_10
	.long PerfMode_ParamHandler_11
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	; Entry 3 of DisplayMode_Dispatch_Tbl (a code pointer the table holds).
DisplayMode_Dispatch_Mode3:
	ldb_d8	e, (0x0def)
	xor	d, d
	sla	de, 2
	ld	iy, de
	push	xhl
	ld	xhl, PerfMode_JumpTable_Extended
	ld	xiy, (xhl+iy)
	pop	xhl
	call	(xiy)
	ret
	; Handler dispatch table, 76 B.  Read by DisplayMode_Dispatch_Mode3 (0xEF63DF): `ld xhl, PerfMode_JumpTable_Extended`
	; indexed with stride 4 (`sla de, 2`)
	; 19 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
PerfMode_JumpTable_Extended:
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	UIState_PerfModeEntry
	.long	PerfMode_BytecodeEntry_A
	.long	PerfMode_BytecodeEntry_A
	.long	UIState_PerfModeEntry
	.long	PerfMode_BytecodeBody_A
	.long	PerfMode_BytecodeEntry_B
	.long	PerfMode_BytecodeEntry_C
PerfMode_ParamHandler_0:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_0_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_0
	ld	xhl, (xix+hl)
	pop xix
	call	(xhl)
PerfMode_ParamHandler_0_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_0 (0xEF6445): `ld xix, PerfMode_EventTable_0`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_EventTable_0:
	.long	UIDisp_DefaultInputHandler
	.long	PerfMode_EventTable_0_Target1
	.long	PerfMode_EventTable_0_Target2
	.long	PerfMode_Evt03_FlagHandler_A
	.long	PerfMode_Evt03_FlagHandler_B
	.long	PerfMode_Evt03_ClampAndUpdate
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	PerfMode_VolumeParam_Process
	.long	ToneParam_Evt09_BytecodeHandler
	.long	SubCPU_ToneParamDisplay
	.long	ToneParam_ModeGuardEntry
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIDisp_DefaultInputHandler
	.long	PerfMode_EventTable_0_Target1
	.long	PerfMode_EventTable_0_Target2
	.long	PerfMode_Evt03_FlagHandler_A
	.long	PerfMode_Evt03_FlagHandler_B
	.long	PerfMode_Evt03_ClampAndUpdate
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
PerfMode_Evt03_FlagHandler_A:
	or	(0xe31c:16), 8
PerfMode_Evt03_FlagHandler_A_Code:
	ld	a, (13944:16)
	ld	l, 1:opc
	ld	h, 13:opc
	call	PerfMode_ClampValue
	ld	(13944:16), a
	call	PerfMode_Evt03_FlagHandler_A_Code_Helper
	call	Display_UpdateRegion3
	ret	
PerfMode_Evt03_FlagHandler_B:
	or	(0xe31c:16), 8
	ldb_d8	a, (0x3679)
	ld	l, 0:opc
	ld	h, 12:opc
	call	PerfMode_ClampValue
	ld	(13945:16), a
	call	PerfMode_Evt03_FlagHandler_A_Code_Helper
	call	Display_UpdateRegion3
	ret	
PerfMode_Evt03_ClampAndUpdate:
	or	(0xe31c:16), 8
	ldb_d8	a, (0x367a)
	ld	l, 0:opc
	ld	h, 3:opc
	call	PerfMode_ClampValue
	stb_d8	(0x367a), a
	call	PerfMode_Evt03_FlagHandler_A_Code_Helper
	call	Display_UpdateRegion3
	ret
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
	jrl	ugt, PerfMode_ParamHandler_1_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_1
	ld	xhl, (xix+hl)
	pop xix
	call	(xhl)
PerfMode_ParamHandler_1_Return:
	ret
UIDisp_DefaultInputHandler:
	ld	bc, 1:i3
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	UIDisp_DefaultInputHandler_Helper
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
UIDisp_DefaultInputHandler_Helper:
	or	(0x0f57:16), 1
	ld	(3923:16), 1
	ld	(3385:16), w
	bit	7, w
	jrl	z, UIDisp_DefaultInputHandler_Skip
	call	VoiceState_DataBlock2_Helper4
	jp	UIDisp_DefaultInputHandler_Return
UIDisp_DefaultInputHandler_Skip:
	call	VoiceState_DataBlock2_Helper3
UIDisp_DefaultInputHandler_Return:
	ret


	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_1 (0xEF6557): `ld xix, PerfMode_EventTable_1`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_EventTable_1:
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	PerfMode_VolumeParam_Process
	.long	ToneParam_Evt09_BytecodeHandler
	.long	SubCPU_ToneParamDisplay
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
PerfMode_ParamHandler_2:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_2_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_ParamHandler_2_DispatchTbl
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
PerfMode_ParamHandler_2_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_2 (0xEF6633): `ld xix, PerfMode_ParamHandler_2_DispatchTbl`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_ParamHandler_2_DispatchTbl:
	.long	UIDisp_DefaultInputHandler
PerfMode_EventTable_2:
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	PerfMode_VolumeParam_Process
	.long	DefaultHandler_Ret
	.long	PeriphReg_CheckAndDispatch
	.long	ToneEvt_Handler_ModeSingle
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
PerfMode_ParamHandler_3:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_3_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_3
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
PerfMode_ParamHandler_3_Return:
	ret
PerfMode_ParamHandler_3_Entry:
	bit	7, w
	jrl	nz, PerfMode_ParamHandler_3_Entry_Skip
	call	PerfMode_ParamHandler_3_Helper
	jp	PerfMode_ParamHandler_3_Return2
PerfMode_ParamHandler_3_Entry_Skip:
	call	PerfMode_ParamHandler_3_Helper2
PerfMode_ParamHandler_3_Return2:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_3 (0xEF66CE): `ld xix, PerfMode_EventTable_3`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_EventTable_3:
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	PerfMode_ParamHandler_3_Entry
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	PerfMode_VolumeParam_Process
	.long	ToneParam_Evt09_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	PerfMode_ParamHandler_3_Entry
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
PerfMode_ParamHandler_4:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_4_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_StringData_4
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
PerfMode_ParamHandler_4_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_4 (0xEF677C): `ld xix, PerfMode_StringData_4`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_StringData_4:
	.long	UIDisp_DefaultInputHandler
PerfMode_EventTable_4:
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	PerfMode_VolumeParam_Process
	.long	ToneParam_Evt09_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
PerfMode_ParamHandler_5:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_5_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_5
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
PerfMode_ParamHandler_5_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_5 (0xEF6817): `ld xix, PerfMode_EventTable_5`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_EventTable_5:
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	PerfMode_VolumeParam_Process
	.long	ToneParam_Evt09_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
PerfMode_ParamHandler_7:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_7_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_ParamHandler_7_DispatchTbl
	ld	xhl, (xix+hl)
	pop xix
	call	(xhl)
PerfMode_ParamHandler_7_Return:
	ret
PerfMode_ParamHandler_Data:
	bit	7, w
	jrl	nz, PerfMode_ParamHandler_Data_Skip
	call	PerfMode_ParamHandler_Data_Helper
	jp	PerfMode_ParamHandler_7_Return2
PerfMode_ParamHandler_Data_Skip:
	call	PerfMode_ParamHandler_Data_Helper2
PerfMode_ParamHandler_7_Return2:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_7 (0xEF68B2): `ld xix, PerfMode_ParamHandler_7_DispatchTbl`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_ParamHandler_7_DispatchTbl:
	.long	UIDisp_DefaultInputHandler
PerfMode_EventTable_6:
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	PerfMode_ParamHandler_Data
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	PerfMode_VolumeParam_Process
	.long	ToneParam_Evt09_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	PerfMode_ParamHandler_Data
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
PerfMode_ParamHandler_8:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_8_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_7
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
PerfMode_ParamHandler_8_Return:
	ret


	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_8 (0xEF6960): `ld xix, PerfMode_EventTable_7`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_EventTable_7:
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	PerfMode_VolumeParam_Process
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
PerfMode_VolumeParam_Process:
	; framing ported from v10's source for the same label (same span length, statement for statement); 50 of 83 slots byte-identical
	bit	7, w
	jrl	nz, PerfMode_VolumeParam_Process_Return
	ld	a, (3429:16)
	cp	a, 0:i3
	jrl	z, PerfMode_VolumeParam_Process_Return
	cp	a, 3:i3
	jrl	z, PerfMode_VolumeParam_Process_Return
	cp	a, 2:i3
	jrl	z, PerfMode_VolumeParam_Process_Skip
	ld	l, (3424:16)
	dec	1, l
	push	xix
	ld	xix, 61856
	; v10 does not spell this byte either
	cp	(xix+hl), 0x0c
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	pop	xix
	jrl	z, PerfMode_VolumeParam_Process_Skip
	ld	(3567:16), 9
	call	Display_UpdateRegion0
	ld	l, (3424:16)
	dec	1, l
	xor	h, h
	push	xix
	ld	xix, 61856
	; v10 does not spell this byte either
	ld	l, (xix+hl)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	sla	hl, 2
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	xix, PerfMode_VoiceAddressTable
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	xhl, (xix+hl)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	pop	xix
	ld	a, (xhl)
	ld	(3831:16), a
	call	PerfMode_VolumeParam_Process_Helper
	jp	PerfMode_VolumeParam_Process_Return
PerfMode_VolumeParam_Process_Skip:
	xor	wa, wa
	ld	a, 169:opc
	call	SoundCtrl_SendCommand
PerfMode_VolumeParam_Process_Return:
	ret
PerfMode_VolumeParam_Process_Helper:
	ld	xix, 3789
	ld	a, 32:opc
	ldw	bc, 27
	ld	(xix+), a
	djnz16	bc, -6
	ld	xiy, Str_VolumeEq2
	ld	xix, 3797
	ldw	bc, 9
	; v10 does not spell this byte either
	ldir85
	ld	a, (3831:16)
	exts	wa
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ld	xiy, 4481
	ld	bc, 3:i3
	; v10 does not spell this byte either
	ldir85
	call	Display_UpdateRegion3
	ret
	; Loaded by PerfMode_VolumeParam_Process (0xEF69FB):
	; `ld xiy, Str_VolumeEq2` -- a bare number until lane scoop gave this address a label.
Str_VolumeEq2:
	.byte 0x56	; v10 does not spell this byte either
	.byte 0x4f	; v10 does not spell this byte either
	.byte 0x4c	; v10 does not spell this byte either
	.byte 0x55	; v10 does not spell this byte either
	.byte 0x4d	; v10 does not spell this byte either
	.byte 0x45	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x3d	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
PerfMode_ParamHandler_9:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_9_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_9
	ld	xhl, (xix+hl)
	pop xix
	call	(xhl)
PerfMode_ParamHandler_9_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_9 (0xEF6AAD): `ld xix, PerfMode_EventTable_9`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_EventTable_9:
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	PerfMode_Evt04_VolumeHandler
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	PerfMode_Evt04_VolumeHandler
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
PerfMode_Evt04_VolumeHandler:
	or	(0xe31c:16), 8
	ldb_d8	a, (0x0ef7)
	ld	l, 0:opc
	ld	h, 127:opc
	call	PerfMode_Evt04_VolumeHandler_Helper
	stb_d8	(0x0ef7), a
	ldb_d8	l, (0x0d60)
	dec	1, l
	xor	h, h
	push	xix
	ld	xix, 0xf1a0
	ld	l, (xix+hl)
	sla	hl, 2
	ld	xix, PerfMode_VoiceAddressTable
	ld	xhl, (xix+hl)
	ld	(xhl), a
	pop	xix
	ldb_d8	e, (0x8c9e)
	ld	d, 3:opc
	ld	w, 127:opc
	pushw	de
	call	SysEx_ApplyVoiceParam_49
	call	PerfMode_VolumeParam_Process_Helper
	popw	de
	ld	c, e
	ld	b, 3:opc
	ldb_d8	e, (0x0ef7)
	ld	d, 127:opc
	call	PerfMode_Evt04_VolumeHandler_Helper2
	call	MidiStream_LoadAllPresets
	call	Audio_ProcessAllMidiStreams
	ret
	; Byte data, 20 B.  No reader found: no label, positional or absolute .set
	; name at this address is loaded anywhere in the image (searched by
	; scripts/analysis/scoop_data_headers.py); purpose not established.
Unref_EF6BA9_Tbl:
	.byte	0x00, 0x01, 0x02, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x04, 0x05, 0x06, 0x03, 0x0f, 0xff, 0xff, 0xff
	.byte	0xff, 0x0c, 0x0d, 0x0e
	; 20 x u32 RAM pointers to the 26-byte part records at 0xF9B9 + 26*k, indexed by part
	; number = byte [0xF1A0 + (0x0D60) - 1] (`sla hl, 2`); written through (`ld (xhl), a`)
	; by PerfMode_VolumeParam_Process and PerfMode_Evt04_VolumeHandler.  Data, not handlers.
PerfMode_VoiceAddressTable:
	.long	0x0000f9b9
	.long	0x0000f9ed
	.long	0x0000f9d3
	.long	0x0000fa6f
	.long	0x0000fa89
	.long	0x0000faa3
	.long	0x0000fabd
	.long	0x0000fad7
	.long	0x0000fa21
	.long	0x0000fa3b
	.long	0x0000fa55
	.long	0x0000fa07
	.long	0x0000fb3f
	.long	0x0000fbdb
	.long	0x0000fbdb
	.long	0x0000f9b9
	.long	0x0000f9b9
	.long	0x0000faf1
	.long	0x0000fb0b
	.long	0x0000fb25
PerfMode_Evt04_VolumeHandler_Helper:
	bit 0x07,W
	jrl nz, .Lc_ef6c1e
	cp A,H
	jrl z, .Lc_ef6c25
	inc 1,A
	jp .Lc_ef6c25
.Lc_ef6c1e:
	cp A,L
	jrl z, .Lc_ef6c25
	dec 1,A
.Lc_ef6c25:
	ret
PerfMode_ParamHandler_10:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_10_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_10
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
PerfMode_ParamHandler_10_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_10 (0xEF6C26): `ld xix, PerfMode_EventTable_10`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_EventTable_10:
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	VoiceParam_MultiDispatch
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	PerfMode_VolumeParam_Process
	.long	ToneParam_Evt09_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIDisp_DefaultInputHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	VoiceParam_MultiDispatch
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
VoiceParam_MultiDispatch:
	; --- Dispatcher: 5-way branch on (0x10f2) value (318 bytes total) ---
	ld	a, (4337:16)
	ld l, 0x03:opc
	ld	a, (4338:16)
	cp a, l
	jrl z, VoiceParam_Case03
	cp a, 0x08
	jrl z, VoiceParam_Case08
	cp a, 0x0a
	jrl z, VoiceParam_Case0A
	cp a, 0x0b
	jrl z, VoiceParam_Case0B
	; --- Default handler: H=0x4c, L=0x34 ---
	ld	a, (4339:16)
	ld l, 0x34:opc
	ld h, 0x4c:opc
	call PerfMode_Evt04_VolumeHandler_Helper
	ld	(4339:16), a
	ld	(3571:16), 4
	call VoiceSlot_ReadParamsWithSaveRestore
	call ParamPopup_PartKeyShift
	jp VoiceParam_CommonTail
VoiceParam_Case03:
	; --- Case 0x03: H=0x7f, L=0x00 ---
	ld	a, (4339:16)
	ld l, 0x00:opc
	ld h, 0x7f:opc
	call PerfMode_Evt04_VolumeHandler_Helper
	ld	(4339:16), a
	ld	(3571:16), 4
	call VoiceSlot_ReadParamsWithSaveRestore
	call ParamPopup_PartVolume
	jp VoiceParam_CommonTail
VoiceParam_Case08:
	; --- Case 0x08: H=0x7f, L=0x00 ---
	ld	a, (4339:16)
	ld l, 0x00:opc
	ld h, 0x7f:opc
	call PerfMode_Evt04_VolumeHandler_Helper
	ld	(4339:16), a
	ld	(3571:16), 4
	call VoiceSlot_ReadParamsWithSaveRestore
	call ParamPopup_PartPanpot
	jp VoiceParam_CommonTail
VoiceParam_Case0A:
	; --- Case 0x0a: H=0xff, L=0x00 ---
	ld	a, (4339:16)
	ld l, 0x00:opc
	ld h, 0xff:opc
	call PerfMode_Evt04_VolumeHandler_Helper
	ld	(4339:16), a
	ld	(3571:16), 4
	call VoiceParam_BitManipHelper
	call ParamPopup_PartTuning
	jp VoiceParam_CommonTail
VoiceParam_Case0B:
	; --- Case 0x0b: H=0x0c, L=0x00 ---
	ld	a, (4339:16)
	ld l, 0x00:opc
	ld h, 0x0c:opc
	call PerfMode_Evt04_VolumeHandler_Helper
	ld	(4339:16), a
	ld	(3571:16), 4
	call VoiceSlot_ReadParamsWithSaveRestore
	call ParamPopup_PartBendSense
VoiceParam_CommonTail:
	; call Display_UpdateRegion3 (v7 addr)
	call	Display_UpdateRegion3
	; ordi8	0xe3e2, 8 (v7 patched)
	or	(0xe31c:16), 8

	ret

VoiceSlot_ReadParamsWithSaveRestore:
	; --- Helper 1: guard on W, parameter setup + calls (44 bytes) ---
	call ToneParam_ModeGuardEntry_Helper4
	cp	w, 0:i3
	jrl z, VoiceParam_SaveRestore_Ret
	xor	a, a
	call VoiceSlot_SaveState
	ld	e, (3571:16)
	xor d, d
	call Timer_ModeHandler_0_Helper6
	call VoiceSlot_ReadCurrentParams
	ld	w, (4339:16)
	call MemConfig_Handler_5_Code_Helper13
	xor	a, a
	call VoiceSlot_RestoreState
VoiceParam_SaveRestore_Ret:
	ret
VoiceParam_BitManipHelper:
	; --- Helper 2: guard on W, bit manipulation + calls (70 bytes) ---
	call ToneParam_ModeGuardEntry_Helper4
	cp	w, 0:i3
	jrl z, VoiceParam_BitManip_Ret
	xor	a, a
	call VoiceSlot_SaveState
	call VoiceSlot_ReadCurrentParams
	ld	w, (4339:16)
	and w, 0x80
	rlc	w
	and a, 0xfe
	or w, a
	call MemConfig_Handler_5_Code_Helper13
	ld	e, (3571:16)
	xor d, d
	call Timer_ModeHandler_0_Helper6
	call VoiceSlot_ReadCurrentParams
	ld	w, (4339:16)
	and w, 0x7f
	call MemConfig_Handler_5_Code_Helper13
	xor	a, a
	call VoiceSlot_RestoreState
VoiceParam_BitManip_Ret:
	ret


UIState_PerfModeEntry:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, UIState_PerfModeEntry_Return
	sla	hl, 2
	push	xix
	ld	xix, UIState_EventTable
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
UIState_PerfModeEntry_Return:
	ret
	; Handler dispatch table, 128 B.  Read by UIState_PerfModeEntry (0xEF6DFF): `ld xix, UIState_EventTable`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
UIState_EventTable:
	.long	UIState_DispatchHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	UIState_EventTable_Target5
	.long	UIState_EventTable_Target6
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_ShortCallHandler
	.long	DefaultHandler_Ret
	.long	ScoopDisp_DispatchTable_Small_Target11
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIState_DispatchHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	UIState_EventTable_Target5
	.long	UIState_EventTable_Target6
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
UIState_DispatchHandler:
	ld	(3923:16), 1
	pushw	wa
	ld	wa, (13950:16)
	ld	(3816:16), wa
	popw	wa
	bit	7, w
	jrl	z, UIState_CallDecHandler
	call	UIState_DispatchHandler_Helper
	jp	UIState_CheckValueChanged
UIState_CallDecHandler:
	call VoiceState_DataBlock2_Helper5
UIState_CheckValueChanged:
	ld wa, (0x367e:16)
	cp wa, (0x0ee8:16)
	jrl nz, UIState_UpdateAllRegions
	call Display_UpdateRegion8
	call Display_UpdateRegion10
	jp UIState_Dispatch_Ret
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
	and (3922:16), 252

	ldw (3660:16), 0

	; call Display_FillRegion0 (v7 addr)
	call	Display_FillRegion0
	; ldw_d16 xwa, (0x371a) (v7 patched)
	ldw_d16	wa, (0x367e)

	cp wa, 1:i3

	jrl z, Display_RedrawParams_Ret

	dec 1, wa

	ld (0x287f:16), wa

	cp wa, 0x3e8

	jrl c, Display_RedrawParams_StoreAndLoad

	ldw wa, 0x3e8



Display_RedrawParams_StoreAndLoad:
	ld (3660:16), wa
	call VoiceBank_BitsAndLoad
	ld a, (3424:16)
	call SetWall_SlotResolve
	ld (3820:16), a
	ld wa, (0x28af:16)
	ld (0x28bf:16), wa
	ld (0x28c1:16), iy
	call VoiceBank_ProcessCommand
	ld xix, 0xef8
	call VoiceBank_CheckCommand
	ld c, 0x0:opc
	call VoiceBank_StatusDoubleRCF
	ld a, (3820:16)
	ld l, a
	cp a, 4:i3
	jrl ule, Display_RedrawParams_StoreDigits
	ld a, 0x4:opc

Display_RedrawParams_StoreDigits:
	ld (3666:16), a
	cp l, 4:i3
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
	and (3922:16), 243

	; call AccPedal_CheckBitAndUpdate (v7 addr)
	call	AccPedal_CheckBitAndUpdate
	; ldw_d16 xwa, (0x371a) (v7 patched)
	ldw_d16	wa, (0x367e)

	cp wa, 0x3e8

	jrl c, Display_RedrawValues_Store

	ldw wa, 0x3e8
Display_RedrawValues_Store:
	ld	(3662:16), wa
	call	Display_FillRegion1
	ld	wa, (13950:16)
	ld	(10367:16), wa
	call	VoiceBank_BitsAndLoad
	ld	a, (3424:16)
	call	SetWall_SlotResolve
	ld	(3820:16), a
	ld	l, (3822:16)
	dec	1, l
	xor	h, h
	sla	hl, 1
	push	xix
	ld	xix, 3230
	ld	wa, (xix+hl)
	ld	(10431:16), wa
	srl	hl, 1
	ld	xix, 3262
	ld	wa, (xix+hl)
	pop	xix
	and	wa, 255
	ld	(10433:16), wa
	call	VoiceBank_ProcessCommand
	ld	xix, 3862
	call	VoiceBank_CheckCommand
	ld	c, 2:opc
	call	VoiceBank_StatusDoubleRCF
	ld	a, (3820:16)
	ld	l, a
	cp	a, 4:i3
	jrl	ule, Display_RedrawValues_StoreDigits
	ld	a, 4:opc
Display_RedrawValues_StoreDigits:
	ld (3667:16), a
	cp l, 4:i3
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
	and (3922:16), 207

	; call Display_FillRegion2 (v7 addr)
	call	Display_FillRegion2
	; ldw_d16 xwa, (0x371a) (v7 patched)
	ldw_d16	wa, (0x367e)

	inc 1, wa

	ld (0x287f:16), wa

	cp wa, 0x3e8

	jrl c, Display_RedrawInd_Store

	ldw wa, 0x3e8



Display_RedrawInd_Store:
	ld (3664:16), wa
	call VoiceBank_BitsAndLoad
	ld a, (3424:16)
	call SetWall_SlotResolve
	cp (0x287a:16), 0
	jrl z, Display_RedrawInd_LoadDirect
	ld a, (3421:16)
	ld (3820:16), a
	jp Display_RedrawInd_CalcSlotCount

Display_RedrawInd_LoadDirect:
	ld (3820:16), a
	ld wa, (0x28af:16)
	ld (0x28bf:16), wa
	ld (0x28c1:16), iy
	call VoiceBank_ProcessCommand
	ld xix, 0xf34
	call VoiceBank_CheckCommand
	ld c, 0x4:opc
	call VoiceBank_StatusDoubleRCF

Display_RedrawInd_CalcSlotCount:
	ld a, (3820:16)
	ld l, a
	cp a, 4:i3
	jrl ule, Display_RedrawInd_StoreDigits
	ld a, 0x4:opc

Display_RedrawInd_StoreDigits:
	ld (3668:16), a
	cp l, 4:i3
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
	ld w, (3822:16)
	or (0x287b:16), 4
	ret

VoiceBank_StatusDoubleRCF:
	ldfr_berp A, 0x3c
	ld a, c
	rcf
	stcfa_dd16 0x52, 0x0f
	ldto_berp A, 0x3c
	inc 1, c
	ldfr_berp A, 0x3c
	ld a, c
	rcf
	stcfa_dd16 0x52, 0x0f
	ldto_berp A, 0x3c
	dec 1, c
	ld a, (3765:16)
	cp a, 0x81
	jrl z, Display_NullRet2
	cp a, 0x82
	jrl z, Display_NullRet2
	cp a, 0x84
	jrl z, Display_NullRet2
	ldfr_berp A, 0x3c
	ld a, c
	scf
	stcfa_dd16 0x52, 0x0f
	ldto_berp A, 0x3c

Display_RedrawFooter_Main:
	pushw bc
	call VoiceBank_ProcessCommand
	popw bc
	ld a, (3765:16)
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
	cp (3766:16), 0
	jrl nz, Display_RedrawFooter_Main

Display_RedrawTitleString:
	ldfr_berp A, 0x3c
	ld a, c
	rcf
	stcfa_dd16 0x52, 0x0f
	ldto_berp A, 0x3c
	inc 1, c
	ldfr_berp A, 0x3c
	ld a, c
	scf
	stcfa_dd16 0x52, 0x0f
	ldto_berp A, 0x3c

Display_NullRet2:
	ret

VoiceBank_CheckCommand:
	cp (3765:16), 129
	jrl nz, Display_TitleString_BuildFromMode
	push xix
	call VoiceBank_ProcessCommand
	pop xix
	cp (3765:16), 129
	jrl z, TitleString_NullRet

Display_TitleString_BuildFromMode:
	ld a, (3765:16)
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
	ld bc, 5:i3
	jp String_CopyFromIY

Display_TitleString_Mode1:
	ldw (xix), 0x4e45
	ld (xix + 2), 0x44
	jp TitleString_NullRet

Display_TitleString_Mode2:
	ld xiy, StringData_Repeat
	ld bc, 6:i3
	jp String_CopyFromIY

Display_TitleString_Mode3:
	ld xiy, StringData_Start
	ld bc, 5:i3
	jp String_CopyFromIY

Display_TitleString_Mode4:
	ld xiy, StringData_Stop
	ld bc, 4:i3
	jp String_CopyFromIY

Display_TitleString_Mode5:
	cp (3767:16), 72
	jrl nz, TitleString_NullRet
	ld a, (3768:16)
	cp a, 5:i3
	jrl z, TitleString_MaskAndFormat
	cp a, 6:i3
	jrl z, TitleString_MaskAndFormat
	cp a, 7:i3
	jrl nz, TitleString_NullRet
	bit 4, (3770:16)
	jrl z, TitleString_NullRet
	ld a, (3769:16)
	and a, 0x30
	sra a, 4
	ldw bc, 0xa
	ld xiy, StringData_VariNames
	ld w, a
	sla a, 3
	sla w, 1
	add a, w
	xor w, w
	lda	xiy, (xiy+wa)
	jp String_CopyFromIY

TitleString_MaskAndFormat:
	ld w, (3765:16)
	ld h, w
	and w, 0x1
	rrc w
	ld a, (3769:16)
	or a, w
	and h, 0x2
	ld l, (3770:16)
	rrc h, 2
	or l, h
	and a, l
	xor c, c

TitleString_BitScanLoop:
	ldfr_berp A, 0x3c
	ldfr_berp A, 0x3d
	ld a, c
	scf
	xorcfb_erp 0x3d
	ldto_berp A, 0x3c
	jrl nc, TitleString_CheckRhythmBank
	inc 1, c
	cp c, 7:i3
	jrl ule, TitleString_BitScanLoop
	jp TitleString_NullRet

TitleString_CheckRhythmBank:
	cp (3768:16), 6
	jrl nz, TitleString_BuildFromBank
	add c, 0x8

TitleString_BuildFromBank:
	xor b, b
	sla bc, 3
	ld xiy, StringData_StyleSections
	lda	xiy, (xiy+bc)
	ldw bc, 0x8
	jp String_CopyFromIY

TitleString_LoadRhythmLabel:
	ld xiy, StringData_Rhythm
	ld bc, 6:i3

String_CopyFromIY:
	ldir85

TitleString_NullRet:
	ret

	; Lcd text, 5 B.  Read by Display_TitleString_Mode0 (0xEF7196): `ld xiy, StringData_Tempo`
	; reader Display_TitleString_Mode0: `ld xiy, StringData_Tempo`
StringData_Tempo:	.ascii "TEMPO"

	; Lcd text, 6 B.  Read by Display_TitleString_Mode2 (0xEF71AD): `ld xiy, StringData_Repeat`
	; reader Display_TitleString_Mode2: `ld xiy, StringData_Repeat`
StringData_Repeat:	.ascii "REPEAT"

	; Lcd text, 5 B.  Read by Display_TitleString_Mode3 (0xEF71B8): `ld xiy, StringData_Start`
	; reader Display_TitleString_Mode3: `ld xiy, StringData_Start`
StringData_Start:	.ascii "START"

	; Lcd text, 4 B.  Read by Display_TitleString_Mode4 (0xEF71C3): `ld xiy, StringData_Stop`
	; reader Display_TitleString_Mode4: `ld xiy, StringData_Stop`
StringData_Stop:	.ascii "STOP"

	; Lcd text, 6 B.  Read by TitleString_LoadRhythmLabel (0xEF7277): `ld xiy, StringData_Rhythm`
	; indexed with stride 8 (`sla bc, 3`)
	; copies 6 byte(s) per use (`ld bc, 6` + ldir) into the LCD text buffer
StringData_Rhythm:	.ascii "RHYTHM"

	; Lcd text, 40 B.  Read by Display_TitleString_Mode5 (0xEF71CE): `ld xiy, StringData_VariNames`
	; reader Display_TitleString_Mode5: `ld xiy, StringData_VariNames` then `lda xiy, (xiy+wa)`
StringData_VariNames:	.ascii "VARI 1    VARI 2    VARI 3    VARI 4    "

	; Lcd text, 128 B.  Read by TitleString_BuildFromBank (0xEF7261): `ld xiy, StringData_StyleSections`
	; indexed with stride 8 (`sla bc, 3`)
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
	ld (xix+), WA
	djnz16 bc, Display_FillRegionLoop
	popw wa
	ret

PerfMode_BytecodeEntry_A:
	cp	bc, 0:i3
	jrl	nz, PerfMode_BytecodeEntry_A_Return
	call	UIState_DispatchHandler
PerfMode_BytecodeEntry_A_Return:
	ret
PerfMode_BytecodeBody_A:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_BytecodeBody_A_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_StringData_A
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
PerfMode_BytecodeBody_A_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_BytecodeBody_A (0xEF737A): `ld xix, PerfMode_StringData_A`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_StringData_A:
	.long	UIState_DispatchHandler
PerfMode_DispatchTable_A:
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneEvt_Handler_ModeAlt
	.long	ToneEvt_Handler_Mode9
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIState_DispatchHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
PerfMode_BytecodeEntry_B:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_BytecodeEntry_B_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_DispatchTable_B
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
PerfMode_BytecodeEntry_B_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_BytecodeEntry_B (0xEF7415): `ld xix, PerfMode_DispatchTable_B`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_DispatchTable_B:
	.long	UIState_DispatchHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	PerfMode_ParamHandler_Data
	.long	DefaultHandler_Ret
	.long	UIState_EventTable_Target5
	.long	UIState_EventTable_Target6
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_ShortCallHandler
	.long	DefaultHandler_Ret
	.long	ScoopDisp_DispatchTable_Small_Target11
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIState_DispatchHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	PerfMode_ParamHandler_Data
	.long	DefaultHandler_Ret
	.long	UIState_EventTable_Target5
	.long	UIState_EventTable_Target6
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
PerfMode_BytecodeEntry_C:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_BytecodeEntry_C_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_DispatchTable_C
	ld	xhl, (xix+hl)
	pop xix
	call	(xhl)
PerfMode_BytecodeEntry_C_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_BytecodeEntry_C (0xEF74B0): `ld xix, PerfMode_DispatchTable_C`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
PerfMode_DispatchTable_C:
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	PerfMode_Handler_EvtA
	.long	PerfMode_Handler_EvtB
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
PerfMode_Handler_EvtA:
	bit	7, w
	jrl	nz, PerfMode_Handler_EvtA_Return
	call	DefaultHandler_Ret_Helper
PerfMode_Handler_EvtA_Return:
	ret
PerfMode_Handler_EvtB:
	bit	7, w
	jrl	nz, PerfMode_Handler_EvtB_Return
	call	DefaultHandler_Ret_Helper2
PerfMode_Handler_EvtB_Return:
	ret
	push	xhl
	push	xde
	push	xix
	push	xiz
	bit	3, (0x0d53:16)
	jrl	z, PerfMode_Handler_EvtB_Epilogue
	cp	(3429:16), 0
	jrl	nz, PerfMode_Handler_EvtB_Epilogue
	cp	(3567:16), 18
	jrl	z, PerfMode_Handler_EvtB_Epilogue
	cp	(49121:16), 11
	jrl	nz, PerfMode_Handler_EvtB_Skip2
	push	xhl
	ld	a, (49122:16)
	ld	(3519:16), a
	call	SysEx_BytecodeDispatcher
	ld	(3519:16), 0
	pop	xhl
	ld	wa, (49122:16)
	xor	a, w
	jrl	z, PerfMode_Handler_EvtB_Skip
	push	xhl
	call	Interrupt_FlagSetBytecode
	pop	xhl
PerfMode_Handler_EvtB_Skip:
	ld	wa, (49122:16)
	cpl	a
	and	a, w
	jrl	z, PerfMode_Handler_EvtB_Epilogue
	ld	(3425:16), 0
	call	SNS_Init_Startup
	call	Display_UpdateRegion3
	jp	PerfMode_Handler_EvtB_Epilogue
PerfMode_Handler_EvtB_Skip2:
	cp	(49121:16), 12
	jrl	nz, PerfMode_Handler_EvtB_Epilogue
	call	PerfMode_Handler_EvtB_Helper
PerfMode_Handler_EvtB_Epilogue:
	pop	xiz
	pop	xix
	pop	xde
	pop	xhl
	ret
	bit	3, (0x0d53:16)
	jrl	z, PerfMode_Handler_EvtB_Return2
	call	Display_ResetDirtyFlags
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, PerfMode_Handler_EvtB_Skip4
	cp	(3429:16), 0
	jrl	nz, PerfMode_Handler_EvtB_Skip4
	cp	(35996:16), 138
	jrl	nz, PerfMode_Handler_EvtB_Skip4
	cp	(3567:16), 18
	jrl	z, PerfMode_Handler_EvtB_Skip3
	ld	xiy, 4360
	xor	wa, wa
	andmi16	(xiy), 65532
	cp	(xiy), wa
	jrl	z, PerfMode_Handler_EvtB_Skip4
	call	SysEx_BytecodeDispatcher
PerfMode_Handler_EvtB_Skip3:
	ldw	(4360:16), 0
PerfMode_Handler_EvtB_Skip4:
	call	Display_UpdateDirtyRegions
PerfMode_Handler_EvtB_Return2:
	ret
PerfMode_Handler_EvtB_Helper:
	ld	a, (49122:16)
	and	a, (49123:16)
	ldfr_berp	a, 60
	and	a, 3
	ldto_berp	a, 60
	jrl	nz, PerfMode_Handler_EvtB_Skip5
	ld	a, (49122:16)
	xor	c, c
	ldfr_berp	a, 60
	ldfr_berp	a, 61
	ld	a, c
	.byte	0xc7, 0x3d, 0x2b	; ldcf A,RH3
	ccf
	.byte	0xc7, 0x3d, 0x2c	; stcf A,RH3
	ldto_berp	a, 60
	ldto_berp	a, 61
	inc	1, c
	ldfr_berp	a, 60
	ldfr_berp	a, 61
	ld	a, c
	.byte	0xc7, 0x3d, 0x2b	; ldcf A,RH3
	ccf
	.byte	0xc7, 0x3d, 0x2c	; stcf A,RH3
	ldto_berp	a, 60
	ldto_berp	a, 61
	and	a, (49123:16)
	ld	(3520:16), a
	push	xhl
	call	SysEx_BytecodeDispatcher
	pop	xhl
PerfMode_Handler_EvtB_Skip5:
	ld	(3520:16), 0
	ld	a, (49122:16)
	and	a, 3
	jrl	z, PerfMode_Handler_EvtB_Skip7
	push	xhl
	and	a, 1
	jrl	z, PerfMode_Handler_EvtB_Skip6
	ld	xhl, 3412
	bitm	3, (xhl)
	jrl	z, PerfMode_Handler_EvtB_Skip6
	ld	(132584:24), 255
	ld	(132588:24), 255
	ld	(132586:24), 255
	ld	a, (3822:16)
	ld	(10359:16), a
	call	Scoop_SpecialMode_ParamCheckBound
	res	7, (0x0d54:16)
	ld	(3434:16), 0
	call	PerfMode_Handler_EvtB_Helper2
	ld	(132584:24), 255
	ld	(132588:24), 255
	ld	(132586:24), 255
PerfMode_Handler_EvtB_Skip6:
	pushw	wa
	ld	w, 118:opc
	call	MIDI_SendSysExFromW
	popw	wa
	pop	xhl
PerfMode_Handler_EvtB_Skip7:
	ld	a, (49122:16)
	and	a, 24
	srl	a, 1
	ld	w, (49123:16)
	and	w, 24
	srl	w, 3
	or	a, w
	xor	w, w
	ld	iy, wa
	push	xde
	ld	xde, PerfMode_Handler_EvtB_Data
	ld	a, (xde+iy)
	pop	xde
	and	a, 3
	xor	w, w
	sla	wa, 2
	ld	iy, wa
	push	xhl
	ld	xhl, ScoopDisp_DispatchTable_Extended
	ld	xiy, (xhl+iy)
	pop	xhl
	call (xiy)
	ld	a, (49122:16)
	and	a, 63
	cp	a, 0:i3
	jrl	nz, PerfMode_Handler_EvtB_Return3
	res	3, (0x0d54:16)
	res	1, (0x10f9:16)
	res	2, (0x10f9:16)
PerfMode_Handler_EvtB_Return3:
	ret
	; Handler dispatch table, 16 B.  Read by PerfMode_Handler_EvtB (0xEF7556): `ld xhl, ScoopDisp_DispatchTable_Extended`
	; indexed with stride 4 (`sla wa, 2`)
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
ScoopDisp_DispatchTable_Extended:
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long VoiceCtrl_CheckAndReset
	; Loaded by PerfMode_Handler_EvtB (0xEF7556):
	; `ld xde, PerfMode_Handler_EvtB_Data` -- a bare number until lane scoop gave this address a label.
PerfMode_Handler_EvtB_Data:
	.byte	0x00, 0x03, 0x03, 0x03, 0x00, 0x01, 0x03, 0x03, 0x00, 0x03, 0x02, 0x03, 0x00, 0x00, 0x00, 0x00
	; Entry 11 of ScoopDisp_DispatchTable_Small (a code pointer the table holds).
ScoopDisp_DispatchTable_Small_Target11:
	bit	7, w
	jrl	nz, ScoopDisp_DispatchTable_Small_Target11_Return
	ld	xiy, 0x0def
	ld	a, (xiy)
	stb_d8	(0x0df0), a
	ld	(xiy), 18
	ld	(0x0d5e:16), 0
	call	ScoopDisp_DispatchTable_Small_Target11_Helper2
ScoopDisp_DispatchTable_Small_Target11_Return:
	ret
DefaultHandler_Ret_Helper:
	ld a, (0x0eee:16)
	ld (0x2877:16), a
	call Scoop_SpecialMode_ParamCheckBound
	res 7, (0x0d54:16)
	ld (0x0d6a:16), 0x00
	ld (0x10fa:16), 0x01
	call PerfMode_Handler_EvtB_Helper2
	ld (0x10fa:16), 0x00
	and (0xe31c:16), 0x6f
	ld (0x7ea6:16), 0x23
	xor WA,WA
	ld A, 0xee:opc
	call SoundCtrl_SendCommand
	or (0x8cec:16), 0x01
	ret
DefaultHandler_Ret_Helper2:
	ldb_d8	a, (0x0df0)
	stb_d8	(0x0def), a
	call	ScoopDisp_DispatchTable_Small_Target11_Helper
	ret
Display_DirtyRegionDispatch:
	bit 3, (3411:16)
	jrl z, Timer_ModeDispatch_Return
	call Display_ResetDirtyFlags
; Timer mode dispatch
; Index: DRAM[3429] & 0x3 (0-3), entries: 4
; Dispatches display timer update based on current mode
Timer_ModeDispatch:
	ld l, (3429:16)
	and l, 0x3
	xor h, h
	sla hl, 2
	push xix
	ld xix, Timer_ModeSelect_Table
	ld	xhl, (xix+hl)
	pop xix
	call (xhl)
	call Display_UpdateDirtyRegions

Timer_ModeDispatch_Return:
	ret


	; Handler dispatch table, 16 B.  Read by Timer_ModeDispatch (0xEF77C0): `ld xix, Timer_ModeSelect_Table`
	; indexed with stride 4 (`sla hl, 2`), index from `ld l, (3429:16)`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
Timer_ModeSelect_Table:
	.long	Timer_ModeHandler_0
	.long	Timer_ModeHandler_1
	.long	Timer_ModeHandler_1
	.long	Timer_ModeHandler_3
Timer_ModeHandler_1:
	; --- Guard/init function (55 bytes) ---
	call Timer_ModeHandler_0_Helper7
	cp	w, 0:i3
	jrl nz, Timer_GuardCallSetup_Ret
	call Timer_ModeHandler_1_Helper
	call Timer_ModeHandler_0_Helper2
	call SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl nz, Timer_GuardCallSetup_Ret
	bit	0, (3927:16)
	jrl z, Timer_GuardCallSetup
	and	(3927:16), 254
Timer_GuardCallSetup:
	call VoiceSlot_TableSetup
	call DisplayMode_Dispatch_Mode1_Helper
	call Display_UpdateRegion5
	call Display_UpdateRegion3
Timer_GuardCallSetup_Ret:
	ret


Timer_ModeHandler_3:
	call	Timer_ModeHandler_0_Helper7
	cp	w, 0:i3
	jrl	nz, Timer_ModeHandler_3_Return
	cp	(0x0def:16), 18
	jrl	nz, Timer_ModeHandler_3_Skip
	call	PortConfig_Handler_0_Loop
	jp	Timer_ModeHandler_3_Return
Timer_ModeHandler_3_Skip:
	call	Timer_ModeHandler_1_Helper
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, Timer_ModeHandler_3_Return
	call	UIState_UpdateMultiRegions
	call	Timer_ModeHandler_0_Helper2
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, Timer_ModeHandler_3_Return
	call	VoiceState_DataBlock2_Helper16
Timer_ModeHandler_3_Return:
	ret
Timer_ModeHandler_0:
	call	Timer_ModeHandler_0_Helper7
	cp	w, 0:i3
	jrl	nz, Timer_ModeHandler_0_Return
	call	Timer_ModeHandler_0_Helper2
	ld	(13964:16), 0
Timer_ModeHandler_0_Return:
	ret
DisplayMode_Dispatch_Mode1_Helper:
	ld	xiy, 3411
	bitm	0, (xiy)
	jrl	z, Timer_ModeHandler_0_Return2
	ld	xiy, 13974
	ld	c, (13939:16)
	dec	1, c
	cp	c, 15
	jrl	ule, Timer_ModeHandler_0_Entry
	add	iy, 2
Timer_ModeHandler_0_Entry:
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ld	de, (xiy)
	ld	a, c
	scf
	stcf_a_16 de	; stcf A,DE
	ldto_berp	a, 60
	ld	(xiy), de
	ldto_werp DE, 0x3e	; ld DE,QHL3
	bit	0, (0x0f57:16)
	jrl	nz, Timer_ModeHandler_0_Return2
	call	Display_UpdateRegion4
Timer_ModeHandler_0_Return2:
	ret
VoiceSlot_StatusRet_Helper:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	nz, Timer_ModeHandler_0_Skip2
	or	(0x28b3:16), 64
	ld	a, 1:opc
	call	VoiceSlot_SaveState
Timer_ModeHandler_0_Loop:
	call	SeqBuf_ReadByte
	ld	wa, hl
	cp	wa, 65535
	jrl	nz, Timer_ModeHandler_0_Loop
	call	VoiceCtrl_SendNoteOffSequence
	ld	e, (3822:16)
	call	VoiceSlot_FinalRetZ_0x11
	ld	(3522:16), a
Timer_ModeHandler_0_Join:
	call	VoiceSlot_FinalRetZ_0x11
	cp	a, (3522:16)
	jrl	z, Timer_ModeHandler_0_Skip
	jr	Timer_ModeHandler_0_Join2
Timer_ModeHandler_0_Skip:
	call	Timer_ModeHandler_0_Helper5
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	call	Timer_ModeHandler_0_Helper5
	ld	(3522:16), a
	ld	a, 0:opc
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	call	Timer_ModeHandler_0_Helper5
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	ld	a, 64:opc
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	ld	a, (3822:16)
	dec	1, a
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	ld	wa, de
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	de, 3:i3
	call	Timer_ModeHandler_0_Helper6
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	call	VoiceSlot_FinalRetZ_0x1E
	cp	a, 144
	jr	nz, Timer_ModeHandler_0_Join2
	jp	Timer_ModeHandler_0_Join
Timer_ModeHandler_0_Join2:
	call	VoiceAlloc_ScoopDisplayProcess
Timer_ModeHandler_0_Skip2:
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	ret
SoundEvt_LongPacketHandler_Helper:
	ld	xhl, 3412
	bitm	2, (xhl)
	jrl	z, Timer_ModeHandler_0_Return3
	resm	2, (xhl)
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 144
	jrl	nz, Timer_ModeHandler_0_Return3
	call	VoiceCtrl_SendNoteOffSequence
	xor	a, a
	call	VoiceSlot_SaveState
	call	Timer_ModeHandler_0_Helper
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	call	Timer_ModeHandler_0_Helper
	xor	a, a
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	call	Timer_ModeHandler_0_Helper
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	call	Timer_ModeHandler_0_Helper
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	ld	a, (3822:16)
	dec	1, a
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	xor	a, a
	call	VoiceSlot_RestoreState
	or	(0x28b3:16), 64
	or	(0x0f54:16), 1
	ld	(3431:16), 0
	call	VoiceAlloc_ScoopDisplayProcess
Timer_ModeHandler_0_Return3:
	ret
Timer_ModeHandler_0_Helper:
	push	xhl
	call	VoiceSlot_FinalRetZ
	pop	xhl
	ret
Timer_ParamLoadAndCompare:
	ld (0x0dd0:16), 0xff
	call ToneParam_ModeGuardEntry_Helper4
	cp W,0xff
	jrl z, .Lc_ef7a12
	cp c, 2:i3
	jrl ugt, .Lc_ef7a12
	call Timer_ParamLoadAndCompare_Helper2
	cp (0x7ea6:16), 0x0f
	jrl z, .Lc_ef7a1f
.Lc_ef7a12:
Timer_ParamLoadAndCompare_Skip:
	ld W, 0x00:opc
	call Timer_ParamLoadAndCompare_Helper
	bit 5, (0x0d54:16)
	jrl nz, .Lc_ef7a28
.Lc_ef7a1f:
Timer_ParamLoadAndCompare_Join:
	ld (0x0d55:16), 0xff
	jp Timer_ParamLoadAndCompare_Return
.Lc_ef7a28:
	ld W, 0x00:opc
	call Timer_ParamLoadAndCompare_Helper
	res 5, (0x0d54:16)
	jp Timer_ParamLoadAndCompare_Join
Timer_ParamLoadAndCompare_Return:
	ret
Timer_ParamCompareAlt:
	ld (0x0dd0:16), 0xff
	ld W, 0x01:opc
	call Timer_ParamLoadAndCompare_Helper
	bit 5, (0x0d54:16)
	jrl nz, .Lc_ef7a52
Timer_ParamCompareAlt_Join7:
	ld (0x0d55:16), 0xff
	jp Timer_ParamCompareAlt_Return4
.Lc_ef7a52:
	ld W, 0x01:opc
	call Timer_ParamLoadAndCompare_Helper
	res 5, (0x0d54:16)
	jp Timer_ParamCompareAlt_Join7
Timer_ParamCompareAlt_Return4:
	ret
Timer_ParamLoadAndCompare_Helper:
	call	Timer_ParamCompareAlt_Helper7
	xor	a, a
	call	VoiceSlot_SaveState
	pushdi_w	(0x367e)
	pushdi_w	(0x0d5c)
	ld	(3522:16), 0
	call	Timer_ParamCompareAlt_Helper3
	ld	(3531:16), a
	ld	a, (3415:16)
	ld	(3521:16), a
	cp	w, 0:i3
	jrl	nz, Timer_ParamCompareAlt_Skip
	jp	Timer_ParamCompareAlt_Entry
Timer_ParamCompareAlt_Skip:
	cp	(3522:16), 0
	jrl	nz, Timer_ParamCompareAlt_Join
	call	Timer_ParamCompareAlt_Helper5
	cp	w, 255
	jrl	nz, Timer_ParamCompareAlt_Skip3
	cp	(3415:16), 0
	jrl	z, Timer_ParamCompareAlt_Skip2
	inc	1, (3522:16)
	jp	Timer_ParamCompareAlt_Join
Timer_ParamCompareAlt_Skip2:
	add	xsp, 4
	ld	w, 104:opc
	call	MIDI_SendSysExFromW
	jp	Timer_ParamCompareAlt_Return
Timer_ParamCompareAlt_Skip3:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, Timer_ParamCompareAlt_Join
	inc	1, (3522:16)
Timer_ParamCompareAlt_Join:
	call	Timer_ParamCompareAlt_Helper2
	cp	(3522:16), 0
	jrl	z, Timer_ParamCompareAlt_Skip4
	cp	(3521:16), 0
	jrl	z, Timer_ParamCompareAlt_Skip7
	jp	Timer_ParamCompareAlt_Join3
Timer_ParamCompareAlt_Skip4:
	cp	(3521:16), 0
	jrl	nz, Timer_ParamCompareAlt_Skip5
	jp	Timer_ParamCompareAlt_Join5
Timer_ParamCompareAlt_Skip5:
	call	Timer_ParamCompareAlt_Helper3
	cp	e, a
	jrl	le, Timer_ParamCompareAlt_Skip6
	jp	Timer_ParamCompareAlt_Join3
Timer_ParamCompareAlt_Skip6:
	jp	Timer_ParamCompareAlt_Join4
Timer_ParamCompareAlt_Skip7:
	decw	1, (3418:16)
	add	xsp, 4
	pushw	de
	call	AccPedal_CheckBitAndUpdate
	popw	de
	xor	a, a
	call	VoiceSlot_SaveState
	pushdi_w	(0x367e)
	pushdi_w	(0x0d5c)
	call	Timer_ParamCompareAlt_Helper5
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, Timer_ParamCompareAlt_Skip8
	call	VoiceSlot_FlagCheck
	cp	a, 83
	jrl	le, Timer_ParamCompareAlt_Skip8
	cp	a, 95
	jrl	le, Timer_ParamCompareAlt_Skip9
	add	xsp, 4
	jp	Timer_ParamCompareAlt_Return
Timer_ParamCompareAlt_Skip8:
	ld	(3415:16), 84
	popw (0x0d5c:16)	; popw (0x0d5c)
	popw (0x367e:16)	; popw (0x367e)
	xor	a, a
	call	VoiceSlot_RestoreState
	call	Timer_ParamCompareAlt_Helper6
	jp	Timer_ParamCompareAlt_Return
Timer_ParamCompareAlt_Skip9:
	jp	Timer_ParamCompareAlt_Join4
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ld	w, 104:opc
	call	MIDI_SendSysExFromW
Timer_ParamCompareAlt_Return:
	ret
Timer_ParamCompareAlt_Entry:
	and	(0x0d53:16), 251
	call	Timer_ParamCompareAlt_Helper
	cp	(3531:16), 255
	jrl	nz, Timer_ParamCompareAlt_Skip13
Timer_ParamCompareAlt_Join2:
	cp	e, 96
	jrl	nz, Timer_ParamCompareAlt_Skip12
	add	xsp, 4
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	VoiceSlot_DispatchRet
	ld	(3392:16), w
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	cp	(3521:16), 83
	jrl	ule, Timer_ParamCompareAlt_Skip10
	or	(0x0d53:16), 4
	cp	(3392:16), 255
	jrl	nz, Timer_ParamCompareAlt_Skip10
	call	Timer_ParamCompareAlt_Helper4
Timer_ParamCompareAlt_Skip10:
	ld	(3415:16), 0
	incw	1, (3418:16)
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	AccPedal_CheckBitAndUpdate
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	call	Timer_ParamCompareAlt_Helper3
	cp	a, 0:i3
	jrl	nz, Timer_ParamCompareAlt_Skip11
	ld	(3415:16), a
	call	DMA_FlagCheckWithCalls
	jp	Timer_ParamCompareAlt_Return2
Timer_ParamCompareAlt_Skip11:
	ld	(3415:16), 0
	call	Timer_ParamCompareAlt_Helper6
	jp	Timer_ParamCompareAlt_Return2
Timer_ParamCompareAlt_Skip12:
	ld	(3415:16), e
	add	xsp, 4
	call	Timer_ParamCompareAlt_Helper6
	jp	Timer_ParamCompareAlt_Return2
Timer_ParamCompareAlt_Skip13:
	ld	a, (3531:16)
	cp	a, (3521:16)
	jrl	nz, Timer_ParamCompareAlt_Skip14
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	VoiceSlot_DispatchRet
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, Timer_ParamCompareAlt_Skip15
	call	Timer_ParamCompareAlt_Helper3
Timer_ParamCompareAlt_Skip14:
	cp	e, a
	jrl	ge, Timer_ParamCompareAlt_Skip16
	ld	(3415:16), e
	add	xsp, 4
	call	Timer_ParamCompareAlt_Helper6
	jp	Timer_ParamCompareAlt_Return2
Timer_ParamCompareAlt_Skip15:
	jp	Timer_ParamCompareAlt_Join2
Timer_ParamCompareAlt_Skip16:
	ld	(3415:16), a
	add	xsp, 4
	call	DMA_FlagCheckWithCalls
Timer_ParamCompareAlt_Return2:
	ret
Timer_ParamCompareAlt_Join3:
	ld	(3415:16), e
	popw (0x0d5c:16)	; popw (0x0d5c)
	popw (0x367e:16)	; popw (0x367e)
	xor	a, a
	call	VoiceSlot_RestoreState
	call	Timer_ParamCompareAlt_Helper6
	ret
Timer_ParamCompareAlt_Join4:
	add	xsp, 4
	ld	(3415:16), a
	call	DMA_FlagCheckWithCalls
	ret
Timer_ParamCompareAlt_Join5:
	ld	(3415:16), 0
	add	xsp, 4
	call	DMA_FlagCheckWithCalls
	ret
	add	xsp, 4
	ld	(3415:16), e
	call	Timer_ParamCompareAlt_Helper6
	ret
Timer_ParamCompareAlt_Helper:
	pushw	wa
	ld	a, (3521:16)
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	inc	1, a
	mul	wa, l
	ld	e, a
	popw	wa
	ret
Timer_ParamCompareAlt_Helper2:
	pushw	wa
	ld	a, (3521:16)
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	cp	w, 0:i3
	jrl	nz, Timer_ParamCompareAlt_Join6
	cp	a, 0:i3
	jrl	nz, Timer_ParamCompareAlt_Skip17
	ld	a, 7:opc
	jp	Timer_ParamCompareAlt_Join6
Timer_ParamCompareAlt_Skip17:
	dec	1, a
Timer_ParamCompareAlt_Join6:
	xor	w, w
	mul	wa, l
	ld	e, a
	popw	wa
	ret
Timer_ParamCompareAlt_Helper3:
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	jrl	z, Timer_ParamCompareAlt_Skip18
	pushw	wa
	call	VoiceSlot_FlagCheck
	ld	l, a
	popw	wa
	ld	a, l
	jp	Timer_ParamCompareAlt_Return3
Timer_ParamCompareAlt_Skip18:
	ld	a, 255:opc
Timer_ParamCompareAlt_Return3:
	ret
ToneParam_ModeGuardEntry:
	bit	7, w
	jrl	nz, ToneParam_ModeGuardEntry_Return
	cp	(3429:16), 1
	jrl	nz, ToneParam_ModeGuardEntry_Return
	call	ToneParam_ModeGuardEntry_Helper3
	call	ToneParam_ModeGuardEntry_Helper4
	cp	w, 0:i3
	jrl	nz, ToneParam_ModeGuardEntry_Skip
	cp	c, 6:i3
	jrl	ugt, ToneParam_ModeGuardEntry_Skip
	call	ScoopParam_ValueTable_0x1C
	call	ToneParam_ModeGuardEntry_Helper2
	jp	ToneParam_ModeGuardEntry_Join
ToneParam_ModeGuardEntry_Skip:
	ld	(3923:16), 0
	call	ToneParam_ModeGuardEntry_Helper
	res	2, (0x0d54:16)
ToneParam_ModeGuardEntry_Join:
	or	(0x0dd3:16), 1
	call	VoiceSlot_TableSetup
	call	Display_UpdateRegion5
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, ToneParam_ModeGuardEntry_Skip2
	cp	a, 130
	jrl	z, ToneParam_ModeGuardEntry_Skip2
	call	VoiceSlot_FlagCheck
	cp	a, (3415:16)
	jrl	ugt, ToneParam_ModeGuardEntry_Skip2
	call	DMA_FlagCheckWithCalls
	jp	ToneParam_ModeGuardEntry_Join2
ToneParam_ModeGuardEntry_Skip2:
	call	Timer_ParamCompareAlt_Helper6
ToneParam_ModeGuardEntry_Join2:
	res	2, (0x0d54:16)
	call	Display_UpdateRegion3
ToneParam_ModeGuardEntry_Return:
	ret
	bit	7, w
	jrl	nz, MemConfig_Handler_5_Skip14
MemConfig_Handler_5:
	set	3, (0x0d54:16)
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, MemConfig_Handler_5_Skip14
	cp	a, 132
	jrl	z, MemConfig_Handler_5_Skip14
	call	VoiceSlot_ReadCurrentParams
	ld	w, a
	and	w, 240
	ld	(3572:16), w
	cp	a, 129
	jrl	z, MemConfig_Handler_5_Skip15
	cp	a, 132
	jrl	z, MemConfig_Handler_5_Code_Entry
	cp	a, 130
	jrl	z, MemConfig_Handler_5_Code_Entry
	cp	(3415:16), 48
	jrl	nz, MemConfig_Handler_5_Code_Skip4
MemConfig_Handler_5_Code_Loop:
	call	MemConfig_Handler_5_Helper2
MemConfig_Handler_5_Code_Entry:
	or	(0x8cec:16), 1
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jr	nz, MemConfig_Handler_5_Skip13
	call	MemConfig_Handler_5_Code_Helper10
MemConfig_Handler_5_Skip13:
	call	MemConfig_Handler_5_Helper
	call	DMA_FlagCheckWithCalls
	call	MemConfig_Handler_5_Code_Helper11
	ld	w, 98:opc
	call	MIDI_SendSysExFromW
	xor	w, w
MemConfig_Handler_5_Skip14:
	jp	MemConfig_Handler_5_Code_Return
MemConfig_Handler_5_Skip15:
	call	MemConfig_Handler_5_0x83
	jp	MemConfig_Handler_5_Code_Entry
MemConfig_Handler_5_Code_Skip4:
	call	VoiceSlot_FlagCheck
	cp	a, 48
	jrl	nz, MemConfig_Handler_5_Code_Loop
	call	MemConfig_Handler_5_Helper6
	jp	MemConfig_Handler_5_Code_Entry
MemConfig_Handler_5_0x83:
	cp	(3415:16), 48
	jrl	z, MemConfig_Handler_5_Skip17
	call	MemConfig_Handler_5_Helper3
MemConfig_Handler_5_Code_Entry2:
	or	(0x8cec:16), 1
	jp	MemConfig_Handler_5_Code_Return
MemConfig_Handler_5_Skip17:
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, MemConfig_Handler_5_Code_Entry2
	cp	a, 132
	jrl	z, MemConfig_Handler_5_Code_Entry2
	cp	a, 129
	jrl	nz, MemConfig_Handler_5_Skip18
	call	MemConfig_Handler_5_Helper3
	jp	MemConfig_Handler_5_Code_Entry2
MemConfig_Handler_5_Skip18:
	call	MemConfig_Handler_5_Helper3
	call	VoiceSlot_FlagCheck
	cp	a, 48
	jrl	z, MemConfig_Handler_5_Code_Entry2
	call	MemConfig_Handler_5_Helper6
	jp	MemConfig_Handler_5_Code_Entry2
MemConfig_Handler_5_Helper2:
	cp	(3572:16), 144
	jrl	nz, MemConfig_Handler_5_Code_Skip7
	call	MemConfig_Handler_5_Helper4
	jp	MemConfig_Handler_5_Code_Return
MemConfig_Handler_5_Code_Skip7:
	call	ToneParam_Evt09_BytecodeHandler_Sub
	jp	MemConfig_Handler_5_Code_Return
MemConfig_Handler_5_Helper3:
	ld	w, 1:opc
	call	VoiceSlot_RetZ
	jp	MemConfig_Handler_5_Code_Return
MemConfig_Handler_5_Helper4:
	xor	a, a
	call	VoiceSlot_SaveState
	ld	de, 4:i3
	call	Timer_ModeHandler_0_Helper6
	call	VoiceSlot_ReadCurrentParams
	ld	(3575:16), a
	call	VoiceSlot_FlagCheck
	ld	(3576:16), a
	xor	a, a
	call	VoiceSlot_RestoreState
	call	MemConfig_Handler_5_Helper5
	ld	c, (3576:16)
	xor	b, b
	cp	bc, 0:i3
	jrl	z, MemConfig_Handler_5_Skip
MemConfig_Handler_5_Join:
	pushw	bc
	call	VoiceSlot_ReadCurrentParams
	popw	bc
	cp	a, 129
	jrl	z, MemConfig_Handler_5_Skip21
	pushw	bc
	call	VoiceCtrl_BytecodeHandler
	cp	b, 22
	jrl	z, MemConfig_Handler_5_Skip20
	cp	b, 23
	jrl	z, MemConfig_Handler_5_Skip20
	popw	bc
	jp	MemConfig_Handler_5_Join2
MemConfig_Handler_5_Skip20:
	pushdi_w	(0x0d58)
	call	VoiceSlot_LoadAndDispatch
	popw_dd16 0x58, 0x0d	; popw (0x0d58)
	popw	bc
	jp	MemConfig_Handler_5_Join
MemConfig_Handler_5_Skip21:
	pushw	bc
	call	MemConfig_Handler_5_Helper3
	popw	bc
	djnz16	bc, -60
MemConfig_Handler_5_Skip:
	ld	a, (3575:16)
	cp	(3415:16), 48
	jrl	z, MemConfig_Handler_5_Skip22
	cp	a, 48
	jrl	nz, MemConfig_Handler_5_Code_Return
	call	MemConfig_Handler_5_Helper6
	jp	MemConfig_Handler_5_Code_Return
MemConfig_Handler_5_Skip22:
	cp	a, 48
	jrl	nz, MemConfig_Handler_5_Code_Return
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, MemConfig_Handler_5_Code_Return
	call	MemConfig_Handler_5_Helper3
	call	MemConfig_Handler_5_Helper6
	jp	MemConfig_Handler_5_Code_Return
MemConfig_Handler_5_Join2:
	add	xsp, 2
MemConfig_Handler_5_Code_Return:
	ret
MemConfig_Handler_5_Helper5:
	call	VoiceSlot_FlagCheck
	ld	(3523:16), a
MemConfig_Handler_5_Loop3:
	call	VoiceSlot_FlagCheck
	cp	a, (3523:16)
	jrl	nz, MemConfig_Handler_5_Return2
	ld	w, 6:opc
	call	VoiceSlot_RetZ
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 144
	jrl	z, MemConfig_Handler_5_Loop3
MemConfig_Handler_5_Return2:
	ret
MemConfig_Handler_5_Helper6:
	xor	a, a
	call	VoiceSlot_SaveState
	ld	xiy, 3577
	cp	(3415:16), 48
	jrl	nz, MemConfig_Handler_5_Skip23
	ld	(xiy), 2
	jp	MemConfig_Handler_5_Loop4
MemConfig_Handler_5_Skip23:
	ld	(xiy), 1
MemConfig_Handler_5_Loop4:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, MemConfig_Handler_5_Code_Join2
	cp	a, 130
	jrl	z, MemConfig_Handler_5_Code_Join2
	cp	(3577:16), 1
	jrl	z, MemConfig_Handler_5_Code_Skip12
	call	MemConfig_Handler_5_Helper8
	cp	w, 255
	jrl	nz, MemConfig_Handler_5_Loop4
MemConfig_Handler_5_Code_Join2:
	xor	a, a
	call	VoiceSlot_RestoreState
	jp	MemConfig_Handler_5_Return3
MemConfig_Handler_5_Code_Skip12:
	call	MemConfig_Handler_5_Helper7
	cp	w, 255
	jrl	nz, MemConfig_Handler_5_Loop4
	jp	MemConfig_Handler_5_Code_Join2
MemConfig_Handler_5_Helper7:
	cp	a, 129
	jrl	z, MemConfig_Handler_5_Code_Join3
	bit	7, a
	jrl	z, MemConfig_Handler_5_Code_Join3
	call	VoiceSlot_FlagCheck
	cp	a, 48
	jrl	z, MemConfig_Handler_5_Skip3
	cp	a, 47
	jrl	z, MemConfig_Handler_5_Skip5
	cp	a, 95
	jrl	z, MemConfig_Handler_5_Skip4
	cp	a, 0:i3
	jrl	z, MemConfig_Handler_5_Skip6
MemConfig_Handler_5_Code_Join3:
	call	VoiceSlot_LoadAndDispatch
	jp	MemConfig_Handler_5_Return3
MemConfig_Handler_5_Skip3:
	xor	w, w
	call	MemConfig_Handler_5_Helper9
	jp	MemConfig_Handler_5_Code_Join3
MemConfig_Handler_5_Skip4:
	ld	w, 47:opc
	call	MemConfig_Handler_5_Helper9
	jp	MemConfig_Handler_5_Code_Join3
MemConfig_Handler_5_Skip5:
	ld	w, 95:opc
	call	MemConfig_Handler_5_Helper9
	jp	MemConfig_Handler_5_Code_Join3
MemConfig_Handler_5_Skip6:
	ld	(3577:16), 2
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	ld	w, 48:opc
	call	MemConfig_Handler_5_Helper9
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	call	VoiceSlot_CompareAndBranch
	call	MemConfig_Handler_5_Helper3
	jp	MemConfig_Handler_5_Code_Join3
MemConfig_Handler_5_Helper8:
	cp	a, 129
	jrl	z, MemConfig_Handler_5_Code_Join4
	bit	7, a
	jrl	z, MemConfig_Handler_5_Code_Join4
	call	VoiceSlot_FlagCheck
	cp	a, 0:i3
	jrl	z, MemConfig_Handler_5_Skip8
	cp	a, 47
	jrl	z, MemConfig_Handler_5_Skip10
	cp	a, 95
	jrl	z, MemConfig_Handler_5_Skip9
	cp	a, 48
	jrl	z, MemConfig_Handler_5_Skip11
MemConfig_Handler_5_Code_Join4:
	call	VoiceSlot_LoadAndDispatch
	jp	MemConfig_Handler_5_Return3
MemConfig_Handler_5_Skip8:
	ld	w, 48:opc
	call	MemConfig_Handler_5_Helper9
	jp	MemConfig_Handler_5_Code_Join4
MemConfig_Handler_5_Skip9:
	ld	w, 47:opc
	call	MemConfig_Handler_5_Helper9
	jp	MemConfig_Handler_5_Code_Join4
MemConfig_Handler_5_Skip10:
	ld	w, 95:opc
	call	MemConfig_Handler_5_Helper9
	jp	MemConfig_Handler_5_Code_Join4
MemConfig_Handler_5_Skip11:
	ld	(3577:16), 1
	call	MemConfig_Handler_5_Code_Helper12
	xor	w, w
	call	MemConfig_Handler_5_Helper9
	jp	MemConfig_Handler_5_Code_Join4
MemConfig_Handler_5_Helper9:
	pushw	wa
	call	VoiceSlot_FinalRetZ
	popw	wa
	call	MemConfig_Handler_5_Code_Helper13
MemConfig_Handler_5_Return3:
	ret
ToneParam_ShortCallHandler:
	call	ToneParam_Evt09_BytecodeHandler
	call	UIState_UpdateMultiRegions
	ret
ToneParam_Evt09_BytecodeHandler:
	bit 0x07,W
	jrl nz, .Lc_ef80e6
ToneParam_Evt09_BytecodeHandler_Sub:
	call ToneParam_Evt09_BytecodeHandler_Helper
	cp w, 1:i3
	jrl z, .Lc_ef80bb
	call ToneParam_Evt09_BytecodeHandler_Helper2
	cp w, 1:i3
	jrl z, .Lc_ef80bb
	call VoiceCtrl_BytecodeHandler
	cp B,0xff
	jrl nz, .Lc_ef80ea
.Lc_ef80a7:
ToneParam_Evt09_BytecodeHandler_Loop2:
	call VoiceSlot_FlagCheck
	cp a, (0x0d57:16)
	jrl nz, .Lc_ef80e6
	call VoiceState_DataBlock2_Helper2
	ld (0x7ea6:16), 0xff
.Lc_ef80bb:
ToneParam_Evt09_BytecodeHandler_Skip2:
	or (0x0dd3:16), 0x01
	ld l, (0x0d65:16)
	and HL,0x0003
	sla HL, 0x02
	push XIX
	ld XIX,ToneParam_HandlerTable_BC
	ld	xhl, (xix+hl)
	pop XIX
	call (XHL)
	call PortConfig_Handler_0_Helper2
	res 2, (0x0d54:16)
	or (0x8cec:16), 0x01
.Lc_ef80e6:
ToneParam_Evt09_BytecodeHandler_Loop3:
	jp ToneParam_Evt09_BytecodeHandler_Return2
.Lc_ef80ea:
ToneParam_Evt09_BytecodeHandler_Skip3:
	call VoiceSlot_FlagCheck
	cp a, (0x0d57:16)
	jrl nz, .Lc_ef80e6
	ld A,B
	and A,0x0f
	cp a, 2:i3
	jrl z, .Lc_ef80a7
	or B,0x10
	ld (0x0dca:16), b
	ld A, 0x01:opc
	call VoiceSlot_SaveState
	call VoiceState_DataBlock2_Helper2
	ld (0x7ea6:16), 0xff
.Lc_ef8115:
ToneParam_Evt09_BytecodeHandler_Loop:
	call VoiceCtrl_BytecodeHandler
	pushw bc
	xor A,A
	call VoiceSlot_SaveState
	call VoiceSlot_DispatchRet
	cp W,0xff
	jrl z, .Lc_ef814a
	popw bc
	cp (0x0dca:16), b
	jrl nz, .Lc_ef8115
	xor A,A
	call VoiceSlot_RestoreState
	ld w, (0x0dcc:16)
	call VoiceSlot_RetZ
ToneParam_Evt09_BytecodeHandler_Join:
	ld A, 0x01:opc
	call VoiceSlot_RestoreState
	jp ToneParam_Evt09_BytecodeHandler_Skip2
.Lc_ef814a:
	add XSP,0x00000002
	jp ToneParam_Evt09_BytecodeHandler_Join
ToneParam_Evt09_BytecodeHandler_Return2:
	ret
	; Pointer table, 16 B.  Read by ToneParam_Evt09_BytecodeHandler (0xEF8085): `ld XIX,ToneParam_HandlerTable_BC`
	; indexed with stride 1 (`sla HL, 0x02`), index from `ld l, (0x0d65:16)`
ToneParam_HandlerTable_BC:
	.long	DefaultHandler_Ret
	.long	VoiceSlot_TableSetup
	.long	VoiceSlot_TableSetup
	.long	DefaultHandler_Ret
ToneParam_Evt09_BytecodeHandler_Helper:
	cp (0x0d65:16), 0x03
	jrl z, .Lc_ef8173
.Lc_ef816d:
ToneParam_HandlerTable_BC_Join:
	ld W, 0x00:opc
	jp ToneParam_HandlerTable_BC_Return
.Lc_ef8173:
	call ToneParam_HandlerTable_BC_Helper5
	cp W,0xff
	jrl z, .Lc_ef816d
	call VoiceState_DataBlock2_Helper
	cp w, 0:i3
	jrl nz, .Lc_ef8192
	ld W, 0x68:opc
	call MIDI_SendSysExFromW
	ld W, 0x01:opc
	jp ToneParam_HandlerTable_BC_Return
.Lc_ef8192:
	ld a, (0x0e3f:16)
	ld (0x0e41:16), a
	call ToneParam_HandlerTable_BC_Helper3
	ld a, (0x0e3f:16)
	ld (0x0e40:16), a
	cp a, (0x0e41:16)
	jrl nz, .Lc_ef81b1
	jp ToneParam_HandlerTable_BC_Join
.Lc_ef81b1:
	ld wa, (0x0d5a:16)
	cp wa, (0x0d6b:16)
	jrl c, .Lc_ef81dd
	call VoiceState_DataBlock2_Helper2
	ld a, (0x0e40:16)
	cp a, (0x0e41:16)
	jrl c, .Lc_ef81d3
	call ToneParam_HandlerTable_BC_Helper6
	jp ToneParam_HandlerTable_BC_Join2
.Lc_ef81d3:
	call ToneParam_HandlerTable_BC_Helper7
ToneParam_HandlerTable_BC_Join2:
	ld W, 0x01:opc
	jp ToneParam_HandlerTable_BC_Return
.Lc_ef81dd:
	and (0xe31c:16), 0x6f
	ld (0x7ea6:16), 0x19
	xor WA,WA
	ld A, 0xee:opc
	call SoundCtrl_SendCommand
	jp ToneParam_HandlerTable_BC_Join2
ToneParam_HandlerTable_BC_Return:
	ret
VoiceCtrl_ParamSetupBytecode_Helper:
	ldb_d8	a, (0x0d65)
	cp	a, 3:i3
	jrl	z, VoiceCtrl_ParamSetupBytecode_Helper_Skip
	ld	w, 0:opc
	jp	ToneParam_HandlerTable_BC_Return2
VoiceCtrl_ParamSetupBytecode_Helper_Skip:
	ldb_d8	a, (0x3686)
	ldb_d8	d, (0x0e47)
	call	Rhythm_DispatchNote_Tramp
	stb_d8	(0x0e40), a
	call	ToneParam_HandlerTable_BC_Helper4
	cp	w, 0:i3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Helper_Skip2
	call	ToneParam_HandlerTable_BC_Helper
	jp	ToneParam_HandlerTable_BC_Return2
VoiceCtrl_ParamSetupBytecode_Helper_Skip2:
	call	ToneParam_HandlerTable_BC_Helper2
ToneParam_HandlerTable_BC_Return2:
	ret
ToneParam_HandlerTable_BC_Helper:
	ldb_d8	a, (0x0e3f)
	stb_d8	(0x0e41), a
	ldb_d8	a, (0x0e40)
	cp	a, (0x0e41:16)
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Helper_Skip3
	call	VoiceState_DataBlock2_Helper2
	ld	w, 6:opc
	ld	xiy, 0x0d8f
	call	DisplayMode_Handler_3_Helper16
	jp	ToneParam_HandlerTable_BC_Join4
VoiceCtrl_ParamSetupBytecode_Helper_Skip3:
	ldw_d16	wa, (0x0d5a)
	cp	wa, (0x0d6b:16)
	jrl	c, VoiceCtrl_ParamSetupBytecode_Helper_Skip5
	call	VoiceState_DataBlock2_Helper2
	ldb_d8	a, (0x0e40)
	cp	a, (0x0e41:16)
	jrl	c, VoiceCtrl_ParamSetupBytecode_Helper_Skip4
	call	ToneParam_HandlerTable_BC_Helper6
	jp	ToneParam_HandlerTable_BC_Join3
VoiceCtrl_ParamSetupBytecode_Helper_Skip4:
	call	ToneParam_HandlerTable_BC_Helper7
ToneParam_HandlerTable_BC_Join3:
	ld	w, 6:opc
	ld	xiy, 0x0d8f
	call	DisplayMode_Handler_3_Helper16
	jp	ToneParam_HandlerTable_BC_Join4
VoiceCtrl_ParamSetupBytecode_Helper_Skip5:
	and	(0xe31c:16), 111
	ld	(0x7ea6:16), 25
	xor	wa, wa
	ld	a, 238:opc
	call	SoundCtrl_SendCommand
	jp	ToneParam_HandlerTable_BC_Join4
ToneParam_HandlerTable_BC_Join4:
	ld	w, 1:opc
	ret
ToneParam_HandlerTable_BC_Helper2:
	call	ToneParam_HandlerTable_BC_Helper3
	ldb_d8	a, (0x0e3f)
	stb_d8	(0x0e41), a
	ldb_d8	a, (0x0e40)
	cp	a, (0x0e41:16)
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Helper_Skip6
	ld	w, 0:opc
	jp	ToneParam_HandlerTable_BC_Return3
VoiceCtrl_ParamSetupBytecode_Helper_Skip6:
	ldw_d16	wa, (0x0d5a)
	cp	wa, (0x0d6b:16)
	jrl	c, VoiceCtrl_ParamSetupBytecode_Helper_Skip8
	ldb_d8	a, (0x0e40)
	cp	a, (0x0e41:16)
	jrl	c, VoiceCtrl_ParamSetupBytecode_Helper_Skip7
	call	ToneParam_HandlerTable_BC_Helper6
	jp	ToneParam_HandlerTable_BC_Join5
VoiceCtrl_ParamSetupBytecode_Helper_Skip7:
	call	ToneParam_HandlerTable_BC_Helper7
ToneParam_HandlerTable_BC_Join5:
	ld	w, 0:opc
	jp	ToneParam_HandlerTable_BC_Return3
VoiceCtrl_ParamSetupBytecode_Helper_Skip8:
	and	(0xe31c:16), 111
	ld	(0x7ea6:16), 25
	xor	wa, wa
	ld	a, 238:opc
	call	SoundCtrl_SendCommand
	ld	w, 1:opc
ToneParam_HandlerTable_BC_Return3:
	ret
ToneParam_HandlerTable_BC_Helper3:
	ld A, 0x03:opc
	call VoiceSlot_SaveState
.Lc_ef82fd:
	call Timer_ParamCompareAlt_Helper5
	cp W,0xff
	jrl z, .Lc_ef8314
	call ToneParam_HandlerTable_BC_Helper5
	cp w, 0:i3
	jrl nz, .Lc_ef82fd
	jp ToneParam_HandlerTable_BC_Join6
.Lc_ef8314:
	ld (0x0e3f:16), 0x04
ToneParam_HandlerTable_BC_Join6:
	ld A, 0x03:opc
	call VoiceSlot_RestoreState
	ret
ToneParam_HandlerTable_BC_Helper4:
	ld	a, 3:opc
	call	VoiceSlot_SaveState
VoiceCtrl_ParamSetupBytecode_Helper_Loop:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceCtrl_ParamSetupBytecode_Helper_Loop2
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Helper_Loop
VoiceCtrl_ParamSetupBytecode_Helper_Loop2:
	call	Timer_ParamCompareAlt_Helper5
	cp	w, 255
	jrl	z, VoiceCtrl_ParamSetupBytecode_Helper_Skip11
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceCtrl_ParamSetupBytecode_Helper_Skip11
	call	ToneParam_HandlerTable_BC_Helper5
	cp	w, 0:i3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Helper_Loop2
	ld	a, 4:opc
	call	VoiceSlot_SaveState
	ldb_d8	a, (0x0e3f)
	stb_d8	(0x0e42), a
ToneParam_HandlerTable_BC_Loop:
	call	Timer_ParamCompareAlt_Helper5
	cp	w, 255
	jrl	z, VoiceCtrl_ParamSetupBytecode_Helper_Skip9
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceCtrl_ParamSetupBytecode_Helper_Loop3
	call	ToneParam_HandlerTable_BC_Helper5
	cp	w, 0:i3
	jrl	nz, ToneParam_HandlerTable_BC_Loop
	call	VoiceState_DataBlock2_Helper2
	jp	ToneParam_HandlerTable_BC_Loop
VoiceCtrl_ParamSetupBytecode_Helper_Loop3:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, VoiceCtrl_ParamSetupBytecode_Helper_Skip10
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceCtrl_ParamSetupBytecode_Helper_Skip10
VoiceCtrl_ParamSetupBytecode_Helper_Skip9:
	call	ToneParam_HandlerTable_BC_Helper5
	cp	w, 0:i3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Helper_Loop3
VoiceCtrl_ParamSetupBytecode_Helper_Skip10:
	ldb_d8	a, (0x0e42)
	stb_d8	(0x0e3f), a
	ld	w, 0:opc
	jp	ToneParam_HandlerTable_BC_Return4
VoiceCtrl_ParamSetupBytecode_Helper_Skip11:
	ld	a, 3:opc
	call	VoiceSlot_RestoreState
	ld	w, 255:opc
ToneParam_HandlerTable_BC_Return4:
	ret
ToneParam_HandlerTable_BC_Helper5:
	push	xiy
	ld	a, 2:opc
	call	VoiceSlot_SaveState
	call	VoiceSlot_FinalRetZ
	stb_d8	(0x0dc8), a
	and	a, 240
	cp	a, 192
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Helper_Skip13
	call	ToneParam_HandlerTable_BC_Helper8
	cp	a, 72
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Helper_Skip13
	call	VoiceSlot_FinalRetZ
	ldfr_berp	a, 60
	and	a, 31
	ldto_berp	a, 60
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Helper_Skip13
	srl	a, 5
	and	a, 3
	ld	d, a
	ldb_d8	e, (0x0dc8)
	and	e, 12
	or	d, e
	pushw	de
	call	VoiceSlot_ReadCurrentParams
	popw	de
	bit	0, (0x0dc8:16)
	jrl	z, VoiceCtrl_ParamSetupBytecode_Helper_Skip12
	or	a, 128
VoiceCtrl_ParamSetupBytecode_Helper_Skip12:
	call	Rhythm_DispatchNote_Tramp
	stb_d8	(0x0e3f), a
	ld	w, 0:opc
	jp	ToneParam_HandlerTable_BC_Join7
VoiceCtrl_ParamSetupBytecode_Helper_Skip13:
	ld	w, 255:opc
ToneParam_HandlerTable_BC_Join7:
	ld	a, 2:opc
	call	VoiceSlot_RestoreState
	pop	xiy
	ret
VoiceState_DataBlock2_Helper:
	ld W, 0xff:opc
	pushw de
	xor DE,DE
	cp (0x0d5a:16), de
	jrl nz, .Lc_ef843e
	cp e, (0x0d57:16)
	jrl nz, .Lc_ef843e
	ld W, 0x00:opc
.Lc_ef843e:
	popw de
	ret
ToneParam_HandlerTable_BC_Helper6:
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	ld A, 0x01:opc
	call VoiceSlot_SaveState
ToneParam_HandlerTable_BC_Join8:
	xor A,A
	ld (0x0e43:16), a
.Lc_ef8453:
	call VoiceSlot_ReadCurrentParams
	cp A,0x81
	jrl nz, .Lc_ef848b
	inc 1, (0x0e43:16)
	call VoiceSlot_DispatchRet
	cp W,0xff
	jrl z, .Lc_ef849e
	ld a, (0x0e43:16)
	cp a, (0x0e41:16)
	jrl c, .Lc_ef8453
	xor B,B
	ld c, (0x0e40:16)
	sub c, (0x0e41:16)
.Lc_ef8480:
	call MemConfig_Handler_5_Code_Helper12
	djnz16 bc, .Lc_ef8480
	jp ToneParam_HandlerTable_BC_Join8
.Lc_ef848b:
	and A,0xf0
	cp A,0xc0
	jrl z, .Lc_ef849e
	call VoiceSlot_DispatchRet
	cp W,0xff
	jrl nz, .Lc_ef8453
.Lc_ef849e:
	ld A, 0x01:opc
	call VoiceSlot_RestoreState
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	ret
ToneParam_HandlerTable_BC_Helper7:
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	ld A, 0x01:opc
	call VoiceSlot_SaveState
ToneParam_HandlerTable_BC_Join9:
	xor A,A
	ld (0x0e43:16), a
.Lc_ef84bf:
ToneParam_HandlerTable_BC_Join10:
	call VoiceSlot_FlagCheck
	cp A,0x82
	jrl z, .Lc_ef8549
	call VoiceSlot_ReadCurrentParams
	cp A,0x84
	jrl z, .Lc_ef8549
	cp A,0x81
	jrl z, .Lc_ef84f0
	and A,0xf0
	cp A,0xc0
	jrl z, .Lc_ef8549
	call VoiceSlot_DispatchRet
	cp W,0xff
	jrl z, .Lc_ef8549
	jp ToneParam_HandlerTable_BC_Join10
.Lc_ef84f0:
	inc 1, (0x0e43:16)
	call MemConfig_Handler_5_Helper3
	ld a, (0x0e41:16)
	sub a, (0x0e40:16)
	cp a, (0x0e43:16)
	jrl ugt, .Lc_ef84bf
	xor B,B
	ld c, (0x0e40:16)
.Lc_ef850d:
ToneParam_HandlerTable_BC_Join11:
	call VoiceSlot_ReadCurrentParams
	cp A,0x82
	jrl z, .Lc_ef8549
	cp A,0x84
	jrl z, .Lc_ef8549
	cp A,0x81
	jrl nz, .Lc_ef8536
	pushw bc
	call VoiceSlot_DispatchRet
	popw bc
	cp W,0xff
	jrl z, .Lc_ef8549
	djnz16 bc, .Lc_ef850d
	jp ToneParam_HandlerTable_BC_Join9
.Lc_ef8536:
	and A,0xf0
	cp A,0xc0
	jrl z, .Lc_ef8549
	pushw bc
	call VoiceSlot_DispatchRet
	popw bc
	jp ToneParam_HandlerTable_BC_Join11
.Lc_ef8549:
	ld A, 0x01:opc
	call VoiceSlot_RestoreState
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	ret
PerfMode_Handler_EvtB_Helper2_Helper:
	ldb_d8	a, (0x0eee)
	stb_d8	(0x0e46), a
	xor	wa, wa
	stb_d8	(0x0eee), a
	ld	(0x0d6b:16), wa
	cp	(0x0d65:16), 3
	jrl	nz, VoiceState_DataBlock2_Helper_Skip3
ToneParam_HandlerTable_BC_Loop2:
	ldb_d8	a, (0x0eee)
	inc	1, a
	cp	a, 16
	jrl	ugt, VoiceState_DataBlock2_Helper_Skip3
	stb_d8	(0x0eee), a
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	push	xix
	ld	xix, 0xf1a0
	cp	(xix+iz), 0x10
	pop	xix
	jrl	z, ToneParam_HandlerTable_BC_Loop2
	xor	wa, wa
	ld	(0x0e44:16), wa
	call	VoiceState_DataBlock2_Helper7
	cp	w, 0:i3
	jrl	nz, ToneParam_HandlerTable_BC_Loop2
	xor	wa, wa
	ldb_d8	a, (0x0eee)
	dec	1, a
	ld	w, a
	sla	a, 1
	add	a, w
	xor	w, w
	inc	1, wa
	push	xde
	ld	xde, 0xf250
	ld	wa, (xde+wa)
	push	xhl
	xor	hl, hl
	ldb_d8	l, (0x0eee)
	dec	1, l
	sla	l, 1
	ld	xde, 0x0c9e
	ld	(xde+hl), wa
	srl	l, 1
	ld	xde, 0x0cbe
	ld	(xde+hl), 0x05
	pop	xhl
	pop	xde
VoiceState_DataBlock2_Helper_Loop:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceState_DataBlock2_Helper_Skip
	incw	1, (0x0e44:16)
VoiceState_DataBlock2_Helper_Skip:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	nz, VoiceState_DataBlock2_Helper_Loop
	call	VoiceSlot_FlagCheck
	cp	a, 132
	jrl	z, VoiceState_DataBlock2_Helper_Skip2
	ldw_d16	wa, (0x0e44)
	cp	wa, (0x0d6b:16)
	jrl	c, ToneParam_HandlerTable_BC_Loop2
	dec	1, wa
	ld	(0x0d6b:16), wa
	jp	ToneParam_HandlerTable_BC_Loop2
VoiceState_DataBlock2_Helper_Skip2:
	ldw	(0x0d6b:16), 65535
VoiceState_DataBlock2_Helper_Skip3:
	ldb_d8	a, (0x0e46)
	stb_d8	(0x0eee), a
	ret
VoiceState_DataBlock2_Helper2:
	xor A,A
	call VoiceSlot_SaveState
	call VoiceSlot_DispatchRet
	xor A,A
	call VoiceSlot_RestoreState
	ld w, (0x0dcc:16)
	call VoiceSlot_RetZ
	ret
VoiceState_DataBlock2_Helper3:
	or (0xe31c:16), 0x08
	ld hl, (0x0d5a:16)
.Lc_ef8653:
	push XHL
	call AccPedal_CheckBitAndUpdate
.Lc_ef8658:
	call Timer_ParamCompareAlt
	xor A,A
	cp	(0x0d57:16), a
	jrl	nz, .Lc_ef8658
	cp	(0x0d5c:16), a
	jrl	nz, .Lc_ef8658
	pop	xhl
	cpw	(0x0d5a:16), 0
	jrl	z, VoiceState_DataBlock2_Helper3_Skip
	cp	hl, (0x0d5a:16)
	jrl	z, .Lc_ef8653
VoiceState_DataBlock2_Helper3_Skip:
	res	2, (0x0d54:16)
	ld	(0x0d55:16), 255
	ret
VoiceState_DataBlock2_Helper4:
	or (0xe31c:16), 0x08
	call AccPedal_CheckBitAndUpdate
	cp W,0xff
	jrl z, .Lc_ef86bb
	ld l, (0x0d5d:16)
	sub l, (0x0d5c:16)
	xor H,H
	ld (0x0dcd:16), hl
	ld (0x0dce:16), 0x00
	ld (0x7ea6:16), 0xff
	call DisplayMode_Handler_3_Sub
	res 2, (0x0d54:16)
	ld (0x0d55:16), 0xff
.Lc_ef86bb:
	ret
PortConfig_Handler_1_Helper:
	call Display_UpdateRegion0
	call Display_UpdateRegion1
	call Display_UpdateRegion4
	call Display_UpdateRegion3
	call Display_UpdateRegion2
	ret
VoiceSlot_TableSetup_Helper:
	cp c, 0:i3
	jrl z, .Lc_ef870f
.Lc_ef86d6:
	pushw bc
	call VoiceSlot_ReadCurrentParams
	cp A,0x82
	jrl z, .Lc_ef8715
	cp A,0x84
	jrl z, .Lc_ef8715
	cp (0x0dcf:16), 0x00
	jrl z, .Lc_ef86f7
	call Timer_ParamCompareAlt_Helper5
	jp ToneParam_HandlerTable_BC_Join12
.Lc_ef86f7:
	call VoiceSlot_DispatchRet
ToneParam_HandlerTable_BC_Join12:
	cp W,0xff
	jrl z, .Lc_ef8717
	call VoiceSlot_ReadCurrentParams
	popw bc
	cp A,0x81
	jrl nz, .Lc_ef86d6
	djnz16 bc, .Lc_ef86d6
.Lc_ef870f:
	ld W, 0x00:opc
	jp ToneParam_HandlerTable_BC_Return5
.Lc_ef8715:
	ld W, 0x00:opc
.Lc_ef8717:
	popw bc
ToneParam_HandlerTable_BC_Return5:
	ret
ToneEvt_Handler_Mode9:
	bit	7, w
	jrl	nz, ToneEvt_Handler_Mode9_Return
	call	ToneEvt_Handler_ModeSingle
	call	ToneEvt_Handler_Mode9_Helper
ToneEvt_Handler_Mode9_Return:
	ret
ToneEvt_Handler_ModeSingle:
	bit	7, w
	jrl	nz, ToneEvt_Handler_ModeSingle_Return
	call	Display_ModeHandler
ToneEvt_Handler_ModeSingle_Return:
	ret
ToneEvt_Handler_ModeAlt:
	bit	7, w
	jrl	nz, ToneEvt_Handler_ModeAlt_Return
	call	PeriphReg_CheckAndDispatch
ToneEvt_Handler_ModeAlt_Return:
	ret
PeriphReg_CheckAndDispatch:
	; --- Peripheral register handler (111 bytes, 2 functions) ---
	bit 7, w
	jrl z, PeriphReg_CheckActiveSlot
	jp PeriphReg_Ret
PeriphReg_CheckActiveSlot:
	cp	(3413:16), 255
	jrl nz, PeriphReg_StoreAndUpdate
	jp PeriphReg_Ret
PeriphReg_StoreAndUpdate:
	ld	a, (3471:16)
	ld	(3536:16), a
	cp	a, (3537:16)
	jrl nz, PeriphReg_LoadWordAndCall
	call VoiceState_DataBlock2_Helper2
PeriphReg_LoadWordAndCall:
	ld	w, (3538:16)
	ld xiy, 0x00000d8f
	call DisplayMode_Handler_3_Helper16
	call Display_ModeHandler
PeriphReg_Ret:
	ret
; Display mode handler
Display_ModeHandler:
	or	(3539:16), 1
	xor	a, a
	ld	(3538:16), a
	ld	(3413:16), 255
	call ToneParam_ModeGuardEntry_Helper4
	cp w, 0:i3
	jrl	nz, DisplayMode_Handler_3_Skip
	ld	l, (3429:16)
	and l, 0x03
	xor	h, h
	sla hl, 2
	push xix
	ld xix, DisplayMode_DispatchTable
	ld	xhl, (xix+hl)
	pop xix
	call	(xhl)
	ret


	; Handler dispatch table, 16 B.  Read by Display_ModeHandler (0xEF8779): `ld xix, DisplayMode_DispatchTable`
	; indexed with stride 4 (`sla hl, 2`), index from `ld l, (3429:16)`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; also read by SubCPU_ToneClearRegion
DisplayMode_DispatchTable:
	.long	DefaultHandler_Ret
	.long	DisplayMode_Handler_1
	.long	DisplayMode_Handler_2
	.long	DisplayMode_Handler_3
DisplayMode_Handler_1:
	ld	(3567:16), 0
	call	Display_BytecodeBlock_F
	ret
DisplayMode_Handler_2:
	ld	(3567:16), 8
	call	DisplayMode_Handler_2_Helper
	ret
DisplayMode_Handler_3:
	ld	(3567:16), 15
	call	DisplayMode_Handler_3_Helper19
	ld	(13964:16), 0
	call	DisplayStr_StyleSectionInit
	ret
DisplayMode_Handler_3_Skip:
	call VoiceSlot_ReadCurrentParams
	cp A,0x81
	jrl z, .Lc_ef8807
	cp A,0x82
	jrl z, .Lc_ef8807
	call VoiceSlot_FlagCheck
	cp a, (0x0d57:16)
	jrl ugt, .Lc_ef8807
	call DMA_FlagCheckWithCalls
	jp DisplayMode_Handler_3_Join
.Lc_ef8807:
	call Timer_ParamCompareAlt_Helper6
DisplayMode_Handler_3_Join:
	res	2, (0x0d54:16)
	ret
ToneEvt_Handler_Mode9_Helper:
	push XIY
	ld (XIY),0x54
	ldw (XIY+0x01), 0x4152
	ldw (XIY+0x03), 0x4b43
	pop XIY
	ret
	push	xiy
	ld	(xiy), 32
	ldw	(xiy+1), 8224
	ldw	(xiy+3), 8224
	pop	xiy
	ret
Timer_ModeHandler_1_Helper:
	or	(0x0dd3:16), 1
	call	VoiceSlot_ReadCurrentParams
	ld	w, a
	and	w, 240
	cp	w, 128
	jrl	z, DisplayMode_Handler_3_Skip2
	ld	a, w
DisplayMode_Handler_3_Skip2:
	ld	(3537:16), a
DisplayMode_Handler_3_Loop4:
	call	DisplayMode_Handler_3_Helper18
	ld	e, a
	and	e, 240
	cp	(3413:16), 255
	jrl	z, DisplayMode_Handler_3_Skip33
	cp	(3413:16), a
	jrl	z, DisplayMode_Handler_3_Skip34
	cp	(3413:16), 210
	jrl	z, DisplayMode_Handler_3_Skip35
DisplayMode_Handler_3_Loop5:
	call	DisplayMode_Handler_3_Helper17
DisplayMode_Handler_3_0x9D:
	call	Timer_ModeHandler_0_Helper7
	cp	w, 255
	jrl	nz, DisplayMode_Handler_3_Loop4
	bit	4, (0x0d53:16)
	jrl	nz, DisplayMode_Handler_3_Next
DisplayMode_Handler_3_Next:
	and	(0x0d53:16), 239
	cp	(3413:16), 255
	jrl	nz, DisplayMode_Handler_3_Next2
DisplayMode_Handler_3_Next2:
	jp	DisplayMode_Handler_3_Return7
DisplayMode_Handler_3_Skip35:
	cp	a, 209
	jrl	z, DisplayMode_Handler_3_Skip34
	jp	DisplayMode_Handler_3_Loop5
DisplayMode_Handler_3_Skip33:
	cp	a, (3536:16)
	jrl	z, DisplayMode_Handler_3_Loop5
	ld	(3536:16), 255
DisplayMode_Handler_3_Skip34:
	cp	a, 209
	jrl	z, DisplayMode_Handler_3_Skip25
	cp	a, 210
	jrl	z, DisplayMode_Handler_3_Skip26
	cp	a, 128
	jrl	z, DisplayMode_Handler_3_Skip6
	cp	a, 133
	jrl	z, DisplayMode_Handler_3_Skip7
	cp	a, 134
	jrl	z, DisplayMode_Handler_3_Skip8
	cp	e, 144
	jrl	z, DisplayMode_Handler_3_Skip3
	cp	e, 176
	jrl	z, DisplayMode_Handler_3_Skip4
	cp	e, 192
	jrl	z, DisplayMode_Handler_3_Skip5
DisplayMode_Handler_3_Loop:
	call	DisplayMode_Handler_3_Helper17
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip3:
	call	DisplayMode_Handler_3_Helper3
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip4:
	call	VoiceCtrl_ParamSetupBytecode
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip5:
	call	DisplayMode_Handler_3_Helper10
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip6:
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, DisplayMode_Handler_3_Loop
	call	DisplayMode_Handler_3_Helper11
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip7:
	call	DisplayMode_Handler_3_Helper13
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip8:
	call	DisplayMode_Handler_3_Helper12
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip25:
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, DisplayMode_Handler_3_Loop
	call	SerialPort_ModeHandler_0_0x5
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip26:
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, DisplayMode_Handler_3_Loop
	call	DisplayMode_Handler_3_Helper15
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Return7:
	ret
DisplayMode_Handler_3_Helper3:
	call	Timer_ParamCompareAlt_Helper7
	cp	(3429:16), 1
	jrl	z, DisplayMode_Handler_3_Skip9
	call	TempoRingBuf_ReadByte
	ld	wa, hl
DisplayMode_Handler_3_Loop2:
	jp	DisplayMode_Handler_3_Return
DisplayMode_Handler_3_Skip9:
	call	DisplayMode_Handler_3_Helper4
	bit	1, (0x0d54:16)
	jrl	z, DisplayMode_Handler_3_Loop2
	call	ToneParam_ModeGuardEntry_Helper3
	res	1, (0x0d54:16)
	ld	e, (3541:16)
	xor	d, d
	ld	xiy, 3542
	xor	hl, hl
	ld	xix, 3471
DisplayMode_Handler_3_Loop3:
	ld	a, (3558:16)
	ld	(xix), a
	ld	a, (3415:16)
	ld	(xix+1), a
	ld	a, (xiy+hl)
	ld	(xix+2), a
	pushw	wa
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	popw	wa
	push	xix
	ld	xix, 61856
	cp	(xix+iz), 0x0c
	pop	xix
	jrl	nz, DisplayMode_Handler_3_Join2
	bit	2, (0xfdad:16)
	jrl	z, DisplayMode_Handler_3_Skip10
	jp	DisplayMode_Handler_3_Join2
DisplayMode_Handler_3_Skip10:
	ld	w, (64316:16)
	call	ScoopDisp_BytecodeBlock1_0x32
DisplayMode_Handler_3_Join2:
	ld	(13948:16), a
	ldfr_lerp	xiy, 56
	lda	xiy, (xiy+hl)
	ld	a, (xiy+8)
	ldto_lerp	xiy, 56
	ld	(xix+3), a
	ld	(13947:16), a
	ld	a, (13201:16)
	ld	(xix+4), a
	ld	a, (13202:16)
	ld	(xix+5), a
	add	ix, 6
	inc	1, hl
	cp	hl, de
	jrl	nz, DisplayMode_Handler_3_Loop3
	ld	xiy, 3471
	ld	a, l
	sla	a, 1
	ld	w, a
	sla	a, 1
	add	w, a
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	DisplayMode_Handler_3_Helper16
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ld	(3541:16), 0
	call	ToneParam_ModeGuardEntry_Helper4
	cp	w, 0:i3
	jrl	nz, DisplayMode_Handler_3_Skip11
	cp	c, 6:i3
	jrl	ugt, DisplayMode_Handler_3_Skip11
	call	ScoopParam_ValueTable_0x1C
	call	ToneParam_ModeGuardEntry_Helper2
	ld	(3422:16), 16
	jp	DisplayMode_Handler_3_Return
DisplayMode_Handler_3_Skip11:
	ld	(3923:16), 0
	call	ToneParam_ModeGuardEntry_Helper
	res	2, (0x0d54:16)
DisplayMode_Handler_3_Return:
	ret
DisplayMode_Handler_3_Helper4:
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(3558:16), a
	call	TempoRingBuf_ReadByte
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(13201:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(13202:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	cp	(13202:16), 0
	jrl	nz, DisplayMode_Handler_3_Entry
	jp	DisplayMode_Handler_3_Join3
DisplayMode_Handler_3_Entry:
	and	(0x0dd3:16), 254
	push	xhl
	push	xiy
	ld	l, (3540:16)
	cp	l, 7:i3
	jrl	ugt, DisplayMode_Handler_3_Skip12
	xor	h, h
	ld	xiy, 3542
	ld	a, (13201:16)
	ld	(xiy+hl), a
	ld	a, (13202:16)
	ldfr_lerp	xiy, 56
	lda	xiy, (xiy+hl)
	ld	(xiy+8), a
	ldto_lerp	xiy, 56
	inc	1, l
	ld	(3540:16), l
	cp	l, (3541:16)
	jrl	ule, DisplayMode_Handler_3_Skip12
	ld	(3541:16), l
DisplayMode_Handler_3_Skip12:
	pop	xiy
	pop	xhl
	jp	DisplayMode_Handler_3_Return2
DisplayMode_Handler_3_Join3:
	ld	a, (3540:16)
	dec	1, a
	cp	a, 255
	jrl	z, DisplayMode_Handler_3_Return2
	ld	(3540:16), a
	cp	a, 0:i3
	jrl	nz, DisplayMode_Handler_3_Return2
	set	1, (0x0d54:16)
	or	(0x0dd3:16), 1
DisplayMode_Handler_3_Return2:
	ret
ToneParam_ModeGuardEntry_Helper:
	call	ScoopParam_ValueTable_0x29
DisplayMode_Handler_3_Sub:
	ld	l, (3533:16)
	xor	h, h
	add hl, (3418:16)
DisplayMode_Handler_3_Join4:
	cp hl, (3418:16)
	jrl	z, DisplayMode_Handler_3_Skip23
	push	xhl
	call	Timer_ParamLoadAndCompare
	pop	xhl
	cp	(32422:16), 15
	jrl	z, DisplayMode_Handler_3_Skip15
	jp	DisplayMode_Handler_3_Join4
DisplayMode_Handler_3_Skip23:
	ld	l, (3534:16)
	and	(0x0d53:16), 251
DisplayMode_Handler_3_Join5:
	ld	h, (3415:16)
	cp	h, 0:i3
	jrl	nz, DisplayMode_Handler_3_Skip14
	bit	2, (0x0d53:16)
	jrl	z, DisplayMode_Handler_3_Skip14
	ld	h, 96:opc
DisplayMode_Handler_3_Skip14:
	cp	l, h
	jrl	le, DisplayMode_Handler_3_Skip15
	push	xhl
	call	Timer_ParamLoadAndCompare
	pop	xhl
	jp	DisplayMode_Handler_3_Join5
DisplayMode_Handler_3_Skip15:
	cp	h, 96
	jrl	nz, DisplayMode_Handler_3_Skip16
	decw	1, (3418:16)
	push	xhl
	call	Timer_ParamCompareAlt_Helper5
	call	AccPedal_CheckBitAndUpdate
	pop	xhl
DisplayMode_Handler_3_Skip16:
	ld	(3415:16), l
	ret
	; Entry 1 of PerfMode_EventTable_0 (a code pointer the table holds).
PerfMode_EventTable_0_Target1:
	bit	7, w
	jrl	nz, DisplayMode_Handler_3_Skip17
	call	DisplayMode_Handler_3_Helper5
	jp	DisplayMode_Handler_3_Return3
DisplayMode_Handler_3_Skip17:
	call	DisplayMode_Handler_3_Helper6
DisplayMode_Handler_3_Return3:
	ret
DisplayMode_Handler_3_Helper5:
	ld	(3570:16), 1
	call	DisplayMode_Handler_3_Helper7
	ret
DisplayMode_Handler_3_Helper6:
	ld	(3570:16), 255
	call	DisplayMode_Handler_3_Helper7
	ret
DisplayMode_Handler_3_Helper7:
	call	ToneParam_ModeGuardEntry_Helper4
	cp	w, 0:i3
	jrl	z, DisplayMode_Handler_3_Return4
	cp	(3429:16), 1
	jrl	nz, DisplayMode_Handler_3_Return4
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 144
	jrl	nz, DisplayMode_Handler_3_Return4
	call	VoiceSlot_FlagCheck
	cp	a, (3415:16)
	jrl	nz, DisplayMode_Handler_3_Return4
	xor	a, a
	call	VoiceSlot_SaveState
	ld	de, 2:i3
	call	Timer_ModeHandler_0_Helper6
	call	VoiceSlot_ReadCurrentParams
	call	DisplayMode_Handler_3_Helper8
	ld	w, a
	ld	l, w
	add	a, (3570:16)
	bit	7, a
	jrl	z, DisplayMode_Handler_3_Skip18
	ld	a, w
DisplayMode_Handler_3_Skip18:
	ld	(13948:16), a
	pushw	hl
	call	PerfMode_EventTable_0_Target1_Helper5
	popw	hl
	call	VoiceSlot_ComputeWordIndex
	sra	iz, 1
	push	xde
	ld	xde, 61856
	cp	(xde+iz), 0x0c
	pop	xde
	jrl	nz, DisplayMode_Handler_3_Skip19
	bit	2, (0xfdad:16)
	jrl	z, DisplayMode_Handler_3_Skip19
	cp	a, 0:i3
	jrl	nz, DisplayMode_Handler_3_Skip19
	ld	(13948:16), l
	jp	DisplayMode_Handler_3_Join6
DisplayMode_Handler_3_Skip19:
	ld	w, a
	call	MemConfig_Handler_5_Code_Helper13
DisplayMode_Handler_3_Join6:
	xor	a, a
	call	VoiceSlot_RestoreState
	call	DisplayMode_Handler_3_Helper20
	or	(0xe31c:16), 8
	call	Display_UpdateRegion3
DisplayMode_Handler_3_Return4:
	ret
DisplayMode_Handler_3_Helper8:
	pushw	wa
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	popw	wa
	push	xix
	ld	xix, 61856
	cp	(xix+iz), 0x0c
	pop	xix
	jrl	nz, DisplayMode_Handler_3_Return5
	bit	2, (0xfdad:16)
	jrl	z, DisplayMode_Handler_3_Skip20
	jp	DisplayMode_Handler_3_Return5
DisplayMode_Handler_3_Skip20:
	ld	w, (64316:16)
	call	ScoopDisp_BytecodeBlock1_0x32
DisplayMode_Handler_3_Return5:
	ret
PerfMode_EventTable_0_Target1_Helper5:
	pushw	wa
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	popw	wa
	push	xix
	ld	xix, 61856
	cp	(xix+iz), 0x0c
	pop	xix
	jrl	nz, DisplayMode_Handler_3_Return6
	bit	2, (0xfdad:16)
	jrl	z, DisplayMode_Handler_3_Skip21
	jp	DisplayMode_Handler_3_Return6
DisplayMode_Handler_3_Skip21:
	ld	w, (64316:16)
	call	ScoopDisp_BytecodeBlock1_0x4D
DisplayMode_Handler_3_Return6:
	ret
PerfMode_ParamHandler_Data_Helper:
	ldw (0x0ef0:16), 0x0001
	ld (0x0df3:16), 0x02
	call PerfMode_EventTable_0_Target1_Helper
	call Display_BytecodeBlock_F_Helper
	call Display_UpdateRegion3
	or (0xe31c:16), 0x08
	ret
PerfMode_ParamHandler_Data_Helper2:
	ldw (0x0ef0:16), 0xffff
	ld (0x0df3:16), 0x02
	call PerfMode_EventTable_0_Target1_Helper
	call Display_BytecodeBlock_F_Helper
	call Display_UpdateRegion3
	or (0xe31c:16), 0x08
	ret
PerfMode_EventTable_0_Target1_Helper:
	call	ToneParam_ModeGuardEntry_Helper4
	cp	w, 0:i3
	jrl	z, DisplayMode_Handler_3_Helper9_Return
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 128
	jrl	nz, DisplayMode_Handler_3_Helper9_Return
	xor	a, a
	call	VoiceSlot_SaveState
	ldb_d8	e, (0x0df3)
	xor	d, d
	call	Timer_ModeHandler_0_Helper6
	call	VoiceSlot_ReadCurrentParams
	ld	c, a
	pushw	bc
	call	VoiceSlot_FlagCheck
	ld	l, a
	rrc	a
	and	a, 129
	popw	bc
	and	c, 127
	ld	w, a
	and	a, 128
	or	a, c
	and	w, 1
	ld	bc, wa
	add	wa, (0x0ef0:16)
	cp	wa, 40
	jrl	nc, DisplayMode_Handler_3_Helper9_Skip
	ld	wa, bc
	jp	PerfMode_EventTable_0_Target1_Join
DisplayMode_Handler_3_Helper9_Skip:
	cp	wa, 300
	jrl	ule, PerfMode_EventTable_0_Target1_Join
	ld	wa, bc
PerfMode_EventTable_0_Target1_Join:
	ld	(0x0ef2:16), wa
	ld	bc, wa
	and	a, 127
	ld	w, a
	pushw	bc
	call	MemConfig_Handler_5_Code_Helper13
	call	VoiceSlot_FinalRetZ
	popw	bc
	ld	a, c
	and	a, 128
	rlc	a
	and	b, 1
	sla	b, 1
	or	a, b
	ld	w, a
	call	MemConfig_Handler_5_Code_Helper13
	xor	a, a
	call	VoiceSlot_RestoreState
DisplayMode_Handler_3_Helper9_Return:
	ret
PerfMode_ParamHandler_3_Helper:
	ld	(0x0df2:16), 1
	ld	(0x0df3:16), 2
	call	VoiceSlot_ReadCurrentParams
	ld	l, a
	and	a, 240
	cp	a, 208
	jrl	nz, DisplayMode_Handler_3_Helper9_Return2
	pushw	hl
	call	VoiceSlot_FlagCheck
	popw	hl
	cp	a, (0x0d57:16)
	jrl	nz, DisplayMode_Handler_3_Helper9_Return2
	push	xhl
	ld	xhl, 0x3685
	ld	(0x110e:16), xhl
	pop	xhl
	cp	l, 210
	jrl	nz, PerfMode_ParamHandler_Data_Helper2_Skip
	call	PerfMode_EventTable_0_Target1_Helper3
	jp	PerfMode_EventTable_0_Target1_Join2
PerfMode_ParamHandler_Data_Helper2_Skip:
	call	PerfMode_EventTable_0_Target1_Helper2
PerfMode_EventTable_0_Target1_Join2:
	call	PerfMode_EventTable_0_Target1_Helper4
	call	Display_UpdateRegion3
	or	(0xe31c:16), 8
DisplayMode_Handler_3_Helper9_Return2:
	ret
PerfMode_ParamHandler_3_Helper2:
	ld	(0x0df2:16), 255
	ld	(0x0df3:16), 2
	call	VoiceSlot_ReadCurrentParams
	ld	l, a
	and	a, 240
	cp	a, 208
	jrl	nz, DisplayMode_Handler_3_Helper9_Return3
	pushw	hl
	call	VoiceSlot_FlagCheck
	popw	hl
	cp	a, (0x0d57:16)
	jrl	nz, DisplayMode_Handler_3_Helper9_Return3
	push	xhl
	ld	xhl, 0x3685
	ld	(0x110e:16), xhl
	pop	xhl
	cp	l, 210
	jrl	nz, DisplayMode_Handler_3_Helper9_Skip2
	call	PerfMode_EventTable_0_Target1_Helper3
	jp	PerfMode_EventTable_0_Target1_Join3
DisplayMode_Handler_3_Helper9_Skip2:
	call	PerfMode_EventTable_0_Target1_Helper2
PerfMode_EventTable_0_Target1_Join3:
	call	PerfMode_EventTable_0_Target1_Helper4
	call	Display_UpdateRegion3
	or	(0xe31c:16), 8
DisplayMode_Handler_3_Helper9_Return3:
	ret
	; Entry 2 of PerfMode_EventTable_0 (a code pointer the table holds).
PerfMode_EventTable_0_Target2:
	bit	7, w
	jrl	nz, DisplayMode_Handler_3_Helper9_Skip3
	call	DisplayMode_Handler_3_Helper9_Helper
	jp	PerfMode_EventTable_0_Target2_Return
DisplayMode_Handler_3_Helper9_Skip3:
	call	PerfMode_EventTable_0_Target2_Helper
PerfMode_EventTable_0_Target2_Return:
	ret
DisplayMode_Handler_3_Helper9_Helper:
	ld	(0x0df2:16), 1
	ld	(0x0df3:16), 3
	cp	(0x0d65:16), 1
	jrl	nz, DisplayMode_Handler_3_Helper9_Return4
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 144
	jrl	nz, DisplayMode_Handler_3_Helper9_Return4
	call	VoiceSlot_FlagCheck
	cp	a, (0x0d57:16)
	jrl	nz, DisplayMode_Handler_3_Helper9_Return4
	push	xhl
	ld	xhl, 0x367b
	ld	(0x110e:16), xhl
	pop	xhl
	call	PerfMode_EventTable_0_Target1_Helper2
	call	DisplayMode_Handler_3_Helper20
	or	(0xe31c:16), 8
	call	Display_UpdateRegion3
DisplayMode_Handler_3_Helper9_Return4:
	ret
PerfMode_EventTable_0_Target2_Helper:
	ld	(0x0df2:16), 255
	ld	(0x0df3:16), 3
	cp	(0x0d65:16), 1
	jrl	nz, DisplayMode_Handler_3_Helper9_Return5
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 144
	jrl	nz, DisplayMode_Handler_3_Helper9_Return5
	call	VoiceSlot_FlagCheck
	cp	a, (0x0d57:16)
	jrl	nz, DisplayMode_Handler_3_Helper9_Return5
	push	xhl
	ld	xhl, 0x367b
	ld	(0x110e:16), xhl
	pop	xhl
	call	PerfMode_EventTable_0_Target1_Helper2
	call	DisplayMode_Handler_3_Helper20
	or	(0xe31c:16), 8
	call	Display_UpdateRegion3
DisplayMode_Handler_3_Helper9_Return5:
	ret
PerfMode_EventTable_0_Target1_Helper2:
	call	ToneParam_ModeGuardEntry_Helper4
	cp	w, 0:i3
	jrl	z, DisplayMode_Handler_3_Helper9_Return6
	xor	a, a
	call	VoiceSlot_SaveState
	ldb_d8	e, (0x0df3)
	xor	d, d
	call	Timer_ModeHandler_0_Helper6
	call	VoiceSlot_ReadCurrentParams
	ld	w, a
	add	a, (0x0df2:16)
	bit	7, a
	jrl	z, DisplayMode_Handler_3_Helper9_Skip4
	ld	a, w
DisplayMode_Handler_3_Helper9_Skip4:
	ld	xhl, (0x110e:16)
	ld	(xhl), a
	ld	w, a
	call	MemConfig_Handler_5_Code_Helper13
	xor	a, a
	call	VoiceSlot_RestoreState
DisplayMode_Handler_3_Helper9_Return6:
	ret
PerfMode_EventTable_0_Target1_Helper3:
	call	ToneParam_ModeGuardEntry_Helper4
	cp	w, 0:i3
	jrl	z, DisplayMode_Handler_3_Helper9_Return7
	xor	a, a
	call	VoiceSlot_SaveState
	ldb_d8	e, (0x0df3)
	xor	d, d
	call	Timer_ModeHandler_0_Helper6
	call	VoiceSlot_ReadCurrentParams
	stb_d8	(0x3685), a
	call	VoiceSlot_FlagCheck
	stb_d8	(0x1112), a
	ld	w, a
	ldb_d8	a, (0x3685)
	and	a, 127
	and	w, 127
	rrc	w
	ld	e, w
	and	w, 127
	and	e, 128
	or	a, e
	ld	bc, wa
	xor	de, de
	ldb_d8	e, (0x0df2)
	exts	de
	add	wa, de
	cp	wa, 16383
	jrl	gt, DisplayMode_Handler_3_Helper9_Helper_Skip2
	cp	wa, 0:i3
	jrl	lt, DisplayMode_Handler_3_Helper9_Helper_Skip2
	bit	7, w
	jrl	z, DisplayMode_Handler_3_Helper9_Helper_Skip
	ld	wa, bc
DisplayMode_Handler_3_Helper9_Helper_Skip:
	ld	bc, wa
	and	a, 127
	stb_d8	(0x3685), a
	rlc	c
	and	c, 1
	sla	w, 1
	and	w, 126
	or	c, w
	stb_d8	(0x1112), c
	ld	w, a
	pushw	bc
	call	MemConfig_Handler_5_Code_Helper13
	call	VoiceSlot_FinalRetZ
	popw	bc
	ld	w, c
	call	MemConfig_Handler_5_Code_Helper13
DisplayMode_Handler_3_Helper9_Helper_Skip2:
	xor	a, a
	call	VoiceSlot_RestoreState
DisplayMode_Handler_3_Helper9_Return7:
	ret
Timer_ParamCompareAlt_Helper6:
	bit	0, (0x0f57:16)
	jrl	nz, DisplayMode_Handler_3_Helper9_Return8
	ldb_d8	l, (0x0d65)
	and	l, 3
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, DMA_ChannelSelect_Table
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
DisplayMode_Handler_3_Helper9_Return8:
	ret
	; Handler dispatch table, 16 B.  Read by PerfMode_EventTable_0_Target2 (0xEF8DD1): `ld xix, DMA_ChannelSelect_Table`
	; indexed with stride 4 (`sla hl, 2`)
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
DMA_ChannelSelect_Table:
	.long	DMA_ChannelHandler_0
	.long	DMA_ChannelHandler_1
	.long	DMA_ChannelHandler_2
	.long	DMA_ChannelHandler_3
DMA_ChannelHandler_1:
	ld	(0x367b:16), 255
	cp	(0x0def:16), 0
	jrl	nz, DMA_ChannelHandler_1_Skip
	call	Display_BytecodeBlock_F_Sub3
	jp	DMA_ChannelHandler_1_Return
DMA_ChannelHandler_1_Skip:
	ld	(0x0def:16), 0
	call	Display_BytecodeBlock_F
DMA_ChannelHandler_1_Return:
	ret
DMA_ChannelHandler_2:
	cp	(0x0def:16), 8
	jrl	nz, DMA_ChannelHandler_2_Skip
	call	DisplayStr_BytecodeBlock_C_Tbl2_Sub
	jp	DMA_ChannelHandler_2_Return
DMA_ChannelHandler_2_Skip:
	ld	(3567:16), 8
	call	DisplayMode_Handler_2_Helper
DMA_ChannelHandler_2_Return:
	ret
DMA_ChannelHandler_0:
	ld	(13964:16), 0
	call	SerialPort_ModeHandler_0_Helper
	ret
DMA_ChannelHandler_3:
	; --- Conditional init (31 bytes) ---
	cp	(3567:16), 15
	jrl z, DMA_Channel3_CallAndInit
	ld	(3567:16), 15
	call DisplayMode_Handler_3_Helper19
DMA_Channel3_CallAndInit:
	call	DMA_ChannelHandler_3_Helper
	ld	(13964:16), 0
	call	DisplayStr_StyleSectionInit
	ret
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
	ld	(3422:16), 0
	ret


VoiceSlot_TableSetup:
	bit 0, (0x0dd3:16)
	jrl z, .Lc_ef900f
	jp VoiceSlot_TableSetup_Join
.Lc_ef900f:
	jp VoiceSlot_TableSetup_Return
VoiceSlot_TableSetup_Join:
	and (0x0dd3:16), 0xfe
	call AccPedal_CheckBitAndUpdate
	call SoundEvt_LongPacketHandler_Helper2
	xor A,A
	call VoiceSlot_SaveState
	call VoiceSlot_TableSetup_Helper2
	ld (0x0dcf:16), 0x01
	call VoiceSlot_TableSetup_Helper
	call MemConfig_Handler_4_Helper6
	cp w, 0:i3
	jrl nz, .Lc_ef904e
	call VoiceSlot_ReadCurrentParams
	cp A,0x81
	jrl nz, .Lc_ef906a
	dec 1, (0x0de7:16)
	jp VoiceSlot_TableSetup_Join2
.Lc_ef904e:
	call VoiceSlot_ReadCurrentParams
	cp A,0x81
	jrl nz, .Lc_ef906a
	call VoiceSlot_DispatchRet
	call VoiceSlot_ReadCurrentParams
	cp A,0x81
	jrl nz, .Lc_ef906a
	dec 1, (0x0de7:16)
.Lc_ef906a:
VoiceSlot_TableSetup_Join2:
	ld a, (0x0eee:16)
	dec 1,A
	xor W,W
	ld HL,WA
	push XIX
	ld XIX,0x00000cbe
	ld	a, (xix+hl)
	ld (0x0dec:16), a
	sla HL, 0x01
	ld XIX,0x00000c9e
	ld	wa, (xix+hl)
	ld (0x0de8:16), wa
	pop XIX
	ld c, (0x0de7:16)
	xor B,B
	ld (0x0dcf:16), 0x00
	call VoiceSlot_TableSetup_Helper
	ld a, (0x0eee:16)
	dec 1,A
	xor W,W
	ld HL,WA
	push XIX
	ld XIX,0x00000cbe
	ld	a, (xix+hl)
	ld (0x0ded:16), a
	sla HL, 0x01
	ld XIX,0x00000c9e
	ld	wa, (xix+hl)
	ld (0x0dea:16), wa
	pop XIX
	call VoiceSlot_TableSetup_Helper3
	call VoiceState_DataBlock2_Helper16
	call Display_UpdateRegion5
	ld wa, (0x367e:16)
	cp WA,0x03e8
	jrl c, .Lc_ef90e9
	ldw WA, 0x03e8
.Lc_ef90e9:
	ld (0x0e4e:16), wa
	xor A,A
	call VoiceSlot_RestoreState
	call VoiceSlot_TableSetup_Helper4
	call VoiceSlot_TableSetup_Helper5
	call Display_UpdateRegion1
	bit 0, (0x0f57:16)
	jrl nz, .Lc_ef910a
	call Display_UpdateRegion4
.Lc_ef910a:
VoiceSlot_TableSetup_Return:
	ret
VoiceSlot_TableSetup_Helper2:
	ld c, (0x0d5c:16)
	ld a, (0x0d5d:16)
	cp a, 4:i3
	jrl ugt, .Lc_ef911c
	jp VoiceSlot_TableSetup_Join3
.Lc_ef911c:
	sub A,0x04
	cp c, 3:i3
	jrl ugt, .Lc_ef9128
	jp VoiceSlot_TableSetup_Join3
.Lc_ef9128:
	sub C,0x04
VoiceSlot_TableSetup_Join3:
	inc 1,C
	xor B,B
	ret
VoiceSlot_TableSetup_Helper3:
	ldw_d16	wa, (0x0de8)
	ldb_d8	l, (0x0eee)
	dec	1, l
	xor	h, h
	sla	hl, 1
	push	xde
	ld	xde, 0x0c9e
	ld	(xde+hl), wa
	ldb_d8	a, (0x0dec)
	srl	hl, 1
	ld	xde, 0x0cbe
	ld	(xde+hl), a
	pop	xde
	ld	xix, 0x3696
	push	xix
	ld	xix, 0x3692
	xor	wa, wa
	ld	(xix), wa
	ld	(xix+2), wa
	ld	(xix+4), wa
	ld	(xix+6), wa
	ld	(xix+8), wa
	ld	(xix+10), wa
	stb_d8	(0x0f5a), a
	stb_d8	(0x0f5b), a
	add	xix, 4
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceSlot_TableSetup_Skip4
	ldb_d8	l, (0x0eee)
	dec	1, l
	xor	h, h
	sla	hl, 1
	push	xde
	ld	xde, 0x0c9e
	ld	wa, (xde+hl)
	pop	xde
	cp	wa, (0x0dea:16)
	jrl	nz, VoiceSlot_TableSetup_Skip4
	srl	hl, 1
	push	xde
	ld	xde, 0x0cbe
	ld	a, (xde+hl)
	pop	xde
	cp	a, (0x0ded:16)
	jrl	nz, VoiceSlot_TableSetup_Skip4
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	nz, VoiceSlot_TableSetup_Epilogue
	ld	xwa, xix
	sub	xwa, 13974
	cp	wa, 1:i3
	jrl	ugt, VoiceSlot_TableSetup_Skip
	ld	wa, 1:i3
VoiceSlot_TableSetup_Skip:
	sla	wa, 3
	cp	a, 1:i3
	jrl	z, VoiceSlot_TableSetup_Skip2
	inc	1, a
VoiceSlot_TableSetup_Skip2:
	stb_d8	(0x0f5b), a
	ld	(0x0f5a:16), 2
	jp	VoiceSlot_TableSetup_Epilogue
VoiceSlot_TableSetup_Loop:
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	push	xde
	ld	xde, 0x0cbe
	ld	a, (xde+iz)
	pop	xde
	push	xix
	call	VoiceSlot_DispatchRet
	pop	xix
	cp	w, 0:i3
	jrl	nz, VoiceSlot_TableSetup_Epilogue
	ldb_d8	l, (0x0eee)
	dec	1, l
	xor	h, h
	sla	hl, 1
	push	xde
	ld	xde, 0x0c9e
	ld	wa, (xde+hl)
	pop	xde
	cp	wa, (0x0dea:16)
	jrl	nz, VoiceSlot_TableSetup_Skip4
	srl	hl, 1
	push	xde
	ld	xde, 0x0cbe
	ld	a, (xde+hl)
	pop	xde
	cp	a, (0x0ded:16)
	jrl	nz, VoiceSlot_TableSetup_Skip4
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	nz, VoiceSlot_TableSetup_Epilogue
	ld	xwa, xix
	sub	xwa, 13974
	push	xwa
	pushw	bc
	call	ToneParam_ModeGuardEntry_Helper4
	ld	h, w
	ld	l, c
	popw	bc
	pop	xwa
	cp	h, 255
	jrl	z, VoiceSlot_TableSetup_Epilogue
	cp	l, 2:i3
	jrl	nz, VoiceSlot_TableSetup_Skip3
	inc	1, wa
VoiceSlot_TableSetup_Skip3:
	sla	wa, 3
	inc	1, a
	stb_d8	(0x0f5b), a
	ld	(0x0f5a:16), 2
	jp	VoiceSlot_TableSetup_Epilogue
VoiceSlot_TableSetup_Skip4:
	call	VoiceSlot_ReadCurrentParams
	cp	w, 0:i3
	jrl	nz, VoiceSlot_TableSetup_Epilogue
	call	VoiceSlot_StatusCheck
	cp	w, 0:i3
	jrl	nz, VoiceSlot_TableSetup_Loop
	cp	a, 130
	jrl	nz, VoiceSlot_TableSetup_Skip5
	ld	xwa, xix
	sub	xwa, 13974
	sla	wa, 3
	stb_d8	(0x0f5b), a
	ld	(0x0f5a:16), 2
VoiceSlot_TableSetup_Skip5:
	cp	a, 132
	jrl	z, VoiceSlot_TableSetup_Epilogue
	cp	a, 129
	jrl	z, VoiceSlot_TableSetup_Skip6
	call	VoiceSlot_FlagCheck
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	ld	c, a
	pop	xix
	ldfr_berp	a, 60
	ld	a, c
	scf
	stcf	a, (xix)
	ldto_berp	a, 60
	push	xix
	jp	VoiceSlot_TableSetup_Loop
VoiceSlot_TableSetup_Skip6:
	pop	xix
	inc	1, xix
	push	xix
	jp	VoiceSlot_TableSetup_Loop
VoiceSlot_TableSetup_Epilogue:
	pop	xix
	ret
VoiceSlot_TableSetup_Helper4:
	ld l, (0x0d60:16)
	dec 1,L
	ld H,L
	sla L, 0x01
	add L,H
	xor H,H
	push XDE
	ld XDE,0x0000f250
	bit	7, (xde+hl)
	pop	xde
	jrl	nz, VoiceSlot_TableSetup_Skip7
	xor	wa, wa
	ld	(0x0e4c:16), wa
	stb_d8	(0x0e52), a
	jp	VoiceSlot_TableSetup_Return2
VoiceSlot_TableSetup_Skip7:
	cpw	(0x367e:16), 1
	jrl	z, VoiceSlot_TableSetup_Skip11
	cp	(0x0d5c:16), 4
	jrl	c, VoiceSlot_TableSetup_Skip9
	ldw_d16	wa, (0x367e)
	ld	(0x287f:16), wa
	call	VoiceSlot_TableSetup_Helper7
	ldb_d8	a, (0x0d60)
	call	SetWall_SlotResolve
	cp	(0x287a:16), 0
	jrl	nz, VoiceSlot_TableSetup_Return2
	ld	(0x0e52:16), 4
	ld	(0x28c1:16), iy
	ldw_d16	iy, (0x28af)
	ld	(0x28bf:16), iy
	ldw_d16	iy, (0x367e)
	cp	iy, 1000
	jrl	c, VoiceSlot_TableSetup_Skip8
	ldw	iy, 1000
VoiceSlot_TableSetup_Skip8:
	ld	(0x0e4c:16), iy
	jp	VoiceSlot_TableSetup_Join4
VoiceSlot_TableSetup_Skip9:
	ldw_d16	wa, (0x367e)
	dec	1, wa
	ld	(0x287f:16), wa
	call	VoiceSlot_TableSetup_Helper7
	ldb_d8	a, (0x0d60)
	call	SetWall_SlotResolve
	ld	(0x28c1:16), iy
	ldw_d16	iy, (0x28af)
	ld	(0x28bf:16), iy
	ldw_d16	iy, (0x287f)
	cp	iy, 1000
	jrl	c, VoiceSlot_TableSetup_Skip10
	ldw	iy, 1000
VoiceSlot_TableSetup_Skip10:
	ld	(0x0e4c:16), iy
	stb_d8	(0x0e52), a
	cp	a, 5:i3
	jrl	c, VoiceSlot_TableSetup_Join4
	sub	a, 4
	stb_d8	(0x0e52), a
	call	VoiceSlot_TableSetup_Helper8
	jp	VoiceSlot_TableSetup_Join4
VoiceSlot_TableSetup_Skip11:
	cp	(0x0d5c:16), 3
	jrl	ugt, VoiceSlot_TableSetup_Skip12
	ldw	(0x0e4c:16), 0
	jp	VoiceSlot_TableSetup_Return2
VoiceSlot_TableSetup_Skip12:
	ld	(0x0e52:16), 4
	ldw_d16	wa, (0x367e)
	ld	(0x287f:16), wa
	call	VoiceSlot_TableSetup_Helper7
	ldb_d8	a, (0x0d60)
	call	SetWall_SlotResolve
	cp	(0x287a:16), 0
	jrl	nz, VoiceSlot_TableSetup_Return2
	ld	(0x28c1:16), iy
	ldw_d16	iy, (0x28af)
	ld	(0x28bf:16), iy
	ldw_d16	iy, (0x367e)
	cp	iy, 1000
	jrl	c, VoiceSlot_TableSetup_Skip13
	ldw	iy, 1000
VoiceSlot_TableSetup_Skip13:
	ld	(0x0e4c:16), iy
VoiceSlot_TableSetup_Join4:
	ld	xix, 0x3692
	ldb_d8	a, (0x0e52)
	stb_d8	(0x0ec1), a
	call	VoiceSlot_TableSetup_Helper6
VoiceSlot_TableSetup_Return2:
	ret
VoiceSlot_TableSetup_Helper5:
	ld l, (0x0d60:16)
	dec 1,L
	ld H,L
	sla L, 0x01
	add L,H
	xor H,H
	push XDE
	ld XDE,0x0000f250
	bit	7, (xde+hl)
	pop	xde
	jrl	nz, VoiceSlot_TableSetup_Skip14
	xor	wa, wa
	ld	(0x0e50:16), wa
	stb_d8	(0x0e54), a
	jp	VoiceSlot_TableSetup_Return3
VoiceSlot_TableSetup_Skip14:
	cp	(0x0d5c:16), 3
	jrl	ugt, VoiceSlot_TableSetup_Skip15
	cp	(0x0d5d:16), 4
	jrl	ugt, VoiceSlot_TableSetup_Skip20
VoiceSlot_TableSetup_Skip15:
	ldw_d16	wa, (0x367e)
	inc	1, wa
	ld	(0x287f:16), wa
	cp	wa, 1000
	jrl	c, VoiceSlot_TableSetup_Skip16
	ldw	wa, 1000
VoiceSlot_TableSetup_Skip16:
	ld	(0x0e50:16), wa
	call	VoiceSlot_TableSetup_Helper7
	ldb_d8	a, (0x0eee)
	call	SetWall_SlotResolve
	cp	(0x287a:16), 0
	jrl	z, VoiceSlot_TableSetup_Skip18
	call	VoiceSlot_TableSetup_Helper7
	cp	w, 0:i3
	jrl	z, VoiceSlot_TableSetup_Skip17
	ld	a, w
	call	SetWall_SlotResolve
	cp	(0x287a:16), 0
	jrl	nz, VoiceSlot_TableSetup_Skip17
	cp	a, 4:i3
	jrl	ule, VoiceSlot_TableSetup_Join5
	ld	a, 4:opc
	jp	VoiceSlot_TableSetup_Join5
VoiceSlot_TableSetup_Skip17:
	ldb_d8	a, (0x0d5d)
	cp	(0x0d5d:16), 4
	jrl	ule, VoiceSlot_TableSetup_Join5
	ld	a, 4:opc
VoiceSlot_TableSetup_Join5:
	stb_d8	(0x0e54), a
	jp	VoiceSlot_TableSetup_Return3
VoiceSlot_TableSetup_Skip18:
	ld	(0x28c1:16), iy
	ldw_d16	iy, (0x28af)
	ld	(0x28bf:16), iy
	cp	a, 4:i3
	jrl	ule, VoiceSlot_TableSetup_Skip19
	ld	a, 4:opc
VoiceSlot_TableSetup_Skip19:
	stb_d8	(0x0e54), a
	jp	VoiceSlot_TableSetup_Join6
VoiceSlot_TableSetup_Skip20:
	ldb_d8	a, (0x0d5d)
	sub	a, 4
	stb_d8	(0x0e54), a
	ldw_d16	wa, (0x367e)
	ld	(0x287f:16), wa
	cp	wa, 1000
	jrl	c, VoiceSlot_TableSetup_Code_Skip8
	ldw	wa, 1000
VoiceSlot_TableSetup_Code_Skip8:
	ld	(0x0e50:16), wa
	call	VoiceSlot_TableSetup_Helper7
	ldb_d8	a, (0x0d60)
	call	SetWall_SlotResolve
	cp	(0x287a:16), 0
	jrl	nz, VoiceSlot_TableSetup_Return3
	ld	(0x28c1:16), iy
	ldw_d16	iy, (0x28af)
	ld	(0x28bf:16), iy
	call	VoiceSlot_TableSetup_Helper8
	cp	c, 4:i3
	jrl	nz, VoiceSlot_TableSetup_Return3
VoiceSlot_TableSetup_Join6:
	ldb_d8	a, (0x0e54)
	stb_d8	(0x0ec1), a
	ld	xix, 0x369a
	call	VoiceSlot_TableSetup_Helper6
VoiceSlot_TableSetup_Return3:
	ret
	; Entry 6 of UIState_EventTable (a code pointer the table holds).
UIState_EventTable_Target6:
	call	MemConfig_Handler_0
	call	SysInit_SendAllNotesAndReset
	ret
	; Entry 5 of UIState_EventTable (a code pointer the table holds).
UIState_EventTable_Target5:
	call	MemConfig_Handler_1
	call	SysInit_SendAllNotesAndReset
	ret
UIState_DispatchHandler_Helper:
	or (0xe31c:16), 0x08
	call AccPedal_CheckBitAndUpdate
.Lc_ef9545:
	call Timer_ParamLoadAndCompare
	xor A,A
	cp	(0x0d57:16), a
	jrl	nz, .Lc_ef9545
	cp	(0x0d5c:16), a
	jrl	nz, .Lc_ef9545
	call	DMA_ChannelHandler_3_Helper
	call	VoiceSlot_FlagCheck
	cp	a, 132
	jrl	nz, UIState_DispatchHandler_Helper_Return
	ld	(0x368c:16), 9
	call	DisplayStr_StyleSectionInit
UIState_DispatchHandler_Helper_Return:
	ret
VoiceState_DataBlock2_Helper5:
	or (0xe31c:16), 0x08
	call AccPedal_CheckBitAndUpdate
.Lc_ef957a:
	call Timer_ParamCompareAlt
	xor A,A
	cp	(0x0d57:16), a
	jrl	nz, .Lc_ef957a
	cp	(0x0d5c:16), a
	jrl	nz, .Lc_ef957a
	call	DMA_ChannelHandler_3_Helper
	ret
AccPedal_CheckBitAndUpdate:
	bit 0, (3412:16)
	jrl z, AccPedal_ClearFlagAndJump
	or (0x287b:16), 4

AccPedal_LoadModeAndChannel:
	ld w, (3414:16)
	ld a, (3822:16)
	cp (3429:16), 0
	jrl z, AccPedal_LoadAddr0
	ld hl, (3418:16)
	jp AccPedal_StoreAddrAndCheck

AccPedal_LoadAddr0:
	ld hl, (3416:16)

AccPedal_StoreAddrAndCheck:
	ld (3299:16), hl
	cp (3429:16), 3
	jrl nz, AccPedal_CallEventSwitch
	ld w, a
	or (0x287b:16), 4

AccPedal_CallEventSwitch:
	call Scoop_EventHandler_MenuSwitch
	cp (0x287a:16), 0x00
	jrl nz, AccPedal_SendSysExAndReturn
	ld (0x367e:16), de
	ld (0x0d5c:16), c
	ld (0x0d5d:16), a
	jp AccPedal_Ret
AccPedal_ClearFlagAndJump:
	and (0x287b:16), 251
	jp AccPedal_LoadModeAndChannel

AccPedal_SendSysExAndReturn:
	ld w, 0x68:opc
	call MIDI_SendSysExFromW
	ld w, 0xff:opc

AccPedal_Ret:
	ret

AccPedal_ScanVoiceSlots:
	push xwa
	ld xwa, (4349:16)
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
	and (3411:16), 253
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
	ld	iy, (xix+iz)
	srl xiz, 1
	ld xix, 0xcbe
	ld	a, (xix+iz)
	pop xix
	cp iy, (3583:16)
	jrl nz, AccPedal_RereadParams
	cp a, (3585:16)
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
	or (3411:16), 2
	jp VoiceSlot_ProcessedWordRet

AccPedal_ClearBit2Flag:
	and (3411:16), 253
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
	ld (4349:16), xwa
	pop xwa
	ret

VoiceCtrl_BytecodeHandler:
	ld	a, 2:opc
	call	VoiceSlot_SaveState
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 176
	jrl	nz, VoiceCtrl_BytecodeHandler_Skip
	call	VoiceSlot_FinalRetZ
	and	a, 3
	ld	(3528:16), a
	call	VoiceSlot_FinalRetZ
	call	VoiceSlot_FinalRetZ
	cp	a, 72
	jrl	nz, VoiceCtrl_BytecodeHandler_Skip
	call	VoiceSlot_FinalRetZ
	ldfr_berp a, 56
	cp a, 6:i3
	jrl	z, VoiceCtrl_BytecodeHandler_Skip2
	cp	a, 5:i3
	jrl	nz, VoiceCtrl_BytecodeHandler_Skip
VoiceCtrl_BytecodeHandler_Skip2:
	call	VoiceSlot_FinalRetZ
	ld	(3527:16), a
	bit	0, (0x0dc8:16)
	jrl	z, VoiceCtrl_BytecodeHandler_Skip3
	or	(0x0dc7:16), 128
VoiceCtrl_BytecodeHandler_Skip3:
	call	VoiceSlot_FinalRetZ
	bit	1, (0x0dc8:16)
	jrl	z, VoiceCtrl_BytecodeHandler_Skip4
	or	a, 128
VoiceCtrl_BytecodeHandler_Skip4:
	ld	c, 7:opc
VoiceCtrl_BytecodeHandler_Join:
	ldfr_berp a, 60
	ldfr_berp a, 61
	ld a, c
	scf
	xorcfb_erp 61
	ldto_berp a, 60
	jrl	nc, VoiceCtrl_BytecodeHandler_Skip5
	cp	c, 0:i3
	jrl	z, VoiceCtrl_BytecodeHandler_Skip
	dec	1, c
	jp	VoiceCtrl_BytecodeHandler_Join
VoiceCtrl_BytecodeHandler_Skip:
	ld	b, 255:opc
VoiceCtrl_BytecodeHandler_Loop:
	ld	a, 2:opc
	call	VoiceSlot_RestoreState
	jp	VoiceCtrl_BytecodeHandler_Return
VoiceCtrl_BytecodeHandler_Skip5:
	ld	b, c
	ldfr_berp a, 60
	ld a, c
	scf
	xorcf a,(0x0dc7:16)	; xorcf A,(0x0dc7)
	ldto_berp a, 60
	jrl	c, VoiceCtrl_BytecodeHandler_Skip6
VoiceCtrl_BytecodeHandler_Join2:
	cpib_erp 56, 6
	jrl nz, VoiceCtrl_BytecodeHandler_Loop
	add	b, 8
	jp	VoiceCtrl_BytecodeHandler_Loop
VoiceCtrl_BytecodeHandler_Skip6:
	cpib_erp 56, 6
	jrl nz, VoiceCtrl_BytecodeHandler_Skip7
	add	b, 8
VoiceCtrl_BytecodeHandler_Skip7:
	set	4, b
	jp	VoiceCtrl_BytecodeHandler_Join2
VoiceCtrl_BytecodeHandler_Return:
	ret
VoiceCtrl_CheckAndReset:
	or	(0x0d53:16), 32
	cp	(0x8ca4:16), 0
	jrl	z, VoiceCtrl_CheckAndReset_Return
	call	VoiceCtrl_SendNoteOffSequence
VoiceCtrl_CheckAndReset_Return:
	ret	
VoiceCtrl_SendNoteOffSequence:
	push xhl
	pushw wa
	or (0x28b3:16), 64
	ld a, 0x90:opc
	ld hl, wa
	pushw hl
	call SeqBuf_WriteByte
	inc 2, xsp
	ld a, 0x7f:opc
	ld hl, wa
	pushw hl
	call SeqBuf_WriteByte
	inc 2, xsp
	ld a, 0x33:opc
	ld hl, wa
	pushw hl
	call SeqBuf_WriteByte
	inc 2, xsp
	ld a, 0x0:opc
	ld hl, wa
	pushw hl
	call SeqBuf_WriteByte
	inc 2, xsp
	ld a, (3822:16)
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
	cp	(3429:16), 0
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip
	call	DisplayMode_Handler_3_Helper17
	jp	VoiceCtrl_ParamSetupBytecode_0xF1
VoiceCtrl_ParamSetupBytecode_Skip:
	xor	a, a
	ld	(3569:16), a
	ld	(13956:16), a
	ld	xiy, 3471
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy), a
	ld	w, a
	and	w, 3
	ld	(3529:16), w
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	a, (3415:16)
	ld	(xiy+1), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+2), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+3), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+4), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+5), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	call	VoiceCtrl_ParamSetupBytecode_0xF2
	cp	a, 0:i3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip5
	cp	(3429:16), 3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip2
	ld	xiy, 3471
	cp	(xiy+2), 72
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip2
	cp	(xiy+3), 7
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip2
	bitm	4, (xiy+5)
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip2
	call	VoiceCtrl_ParamSetupBytecode_Helper9
VoiceCtrl_ParamSetupBytecode_Skip2:
	ld	xiy, 3471
	ld	wa, 2:i3
	ld	wa, (xiy+wa)
	cp	a, 72
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip4
	cp	w, 5:i3
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip3
	cp	w, 6:i3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip4
VoiceCtrl_ParamSetupBytecode_Skip3:
	push	xhl
	xor	hl, hl
	ld	l, (3822:16)
	dec	1, l
	push	xix
	ld	xix, 61856
	ld	a, (xix+hl)
	pop	xix
	pop	xhl
	cp	a, 15
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip4
	cp	a, 16
	jrl	nz, VoiceCtrl_ParamSetupBytecode_0xF1
VoiceCtrl_ParamSetupBytecode_Skip4:
	ld	w, 6:opc
	ld	xiy, 3471
	call	DisplayMode_Handler_3_Helper16
	ld	(3422:16), 16
VoiceCtrl_ParamSetupBytecode_Skip5:
	ld	w, 98:opc
	call	MIDI_SendSysExFromW
	call	VoiceCtrl_ParamSetupBytecode_Helper3
	call	VoiceCtrl_ParamSetupBytecode_Sub
VoiceCtrl_ParamSetupBytecode_0xF1:
	ret
VoiceCtrl_ParamSetupBytecode_0xF2:
	ld	a, (xiy+2)
	push	xhl
	ld	h, (xiy)
	and	h, 4
	sla	h, 5
	or	a, h
	pop	xhl
	ld	w, (xiy+3)
	cp	a, 72
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip6
	cp	w, 8
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip11
	jp	VoiceCtrl_ParamSetupBytecode_Loop
VoiceCtrl_ParamSetupBytecode_Skip6:
	cp	a, 15
	jrl	ugt, VoiceCtrl_ParamSetupBytecode_Skip7
	cp	w, 3:i3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Loop
	jp	VoiceCtrl_ParamSetupBytecode_Join
VoiceCtrl_ParamSetupBytecode_Skip7:
	cp	a, 152
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip9
	cp	w, 1:i3
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip8
	cp	w, 4:i3
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip9
	jp	VoiceCtrl_ParamSetupBytecode_Loop
VoiceCtrl_ParamSetupBytecode_Skip8:
	ldfr_berp	a, 60
	ld	a, (xiy+4)
	and	a, 127
	ldto_berp	a, 60
	jrl	z, VoiceCtrl_ParamSetupBytecode_Loop
	jp	VoiceCtrl_ParamSetupBytecode_0x1C4
VoiceCtrl_ParamSetupBytecode_Skip9:
	cp	a, 152
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip10
	ld	a, 24:opc
	jp	VoiceCtrl_ParamSetupBytecode_0x1CA
VoiceCtrl_ParamSetupBytecode_Skip10:
	cp	a, 16
	jrl	c, VoiceCtrl_ParamSetupBytecode_Loop
	cp	a, 22
	jrl	ugt, VoiceCtrl_ParamSetupBytecode_Loop
	sub	a, 16
	ld	l, a
	xor	h, h
	push	xix
	ld	xix, VoiceCtrl_ParamSetupBytecode_Data
	ld	l, (xix+hl)
	pop	xix
	cp	l, 255
	jrl	z, VoiceCtrl_ParamSetupBytecode_Loop
	ld	c, l
	ld	l, a
	push	xde
	ld	xde, VoiceCtrl_ParamSetupBytecode_Data_2
	ld	l, (xde+hl)
	pop	xde
	cp	l, 255
	jrl	z, VoiceCtrl_ParamSetupBytecode_Loop
	cp	w, l
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Loop
	ld	a, c
	jp	VoiceCtrl_ParamSetupBytecode_0x1CA
VoiceCtrl_ParamSetupBytecode_Loop:
	ld	a, 0:opc
	jp	VoiceCtrl_ParamSetupBytecode_0x1E4
VoiceCtrl_ParamSetupBytecode_Join:
	ld	xhl, VoiceCtrl_ParamSetupBytecode_Tbl
	ld	a, (xhl+a)
	jp	VoiceCtrl_ParamSetupBytecode_0x1CA
VoiceCtrl_ParamSetupBytecode_Skip11:
	ldfr_berp	a, 60
	ld	a, (xiy)
	and	a, 3
	ldto_berp	a, 60
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Loop
	ld	a, 27:opc
	jp	VoiceCtrl_ParamSetupBytecode_0x1CA
VoiceCtrl_ParamSetupBytecode_0x1C4:
	ld	a, 28:opc
	jp	VoiceCtrl_ParamSetupBytecode_0x1CF
VoiceCtrl_ParamSetupBytecode_0x1CA:
	ld	(3422:16), 0
VoiceCtrl_ParamSetupBytecode_0x1CF:
	or	(0x0d53:16), 1
	exts	wa
	ld	xhl, 3439
	add	hl, wa
	ld	a, (xiy+4)
	ld	(xhl), a
	ld	a, 1:opc
VoiceCtrl_ParamSetupBytecode_0x1E4:
	ret
	; Byte data, 18 B.  Read by VoiceCtrl_ParamSetupBytecode (0xEF97B6): `ld xhl, VoiceCtrl_ParamSetupBytecode_Tbl`
	; reader VoiceCtrl_ParamSetupBytecode: `ld xhl, VoiceCtrl_ParamSetupBytecode_Tbl` then `ld_rr8b a, xhl, a`
VoiceCtrl_ParamSetupBytecode_Tbl:
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	.byte	0x00, 0x00
VoiceCtrl_ParamSetupBytecode_Data:	.byte	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte	0xff, 0xff, 0xff, 0xff, 0xff, 0xff
VoiceCtrl_ParamSetupBytecode_Data_2:	.byte	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0xff, 0xff, 0xff
	.byte	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
VoiceCtrl_ParamSetupBytecode_Sub:
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	xiy, 3471
	cp	(xiy+2), 72
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Epilogue
	cp	(xiy+3), 7
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Epilogue
	ld	bc, (xiy+4)
	ld	a, (3429:16)
	cp	a, 2:i3
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip12
	cp	a, 3:i3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Epilogue
	call	VoiceCtrl_ParamSetupBytecode_Sub_Helper2
	jp	VoiceCtrl_ParamSetupBytecode_Epilogue
VoiceCtrl_ParamSetupBytecode_Skip12:
	call	VoiceCtrl_ParamSetupBytecode_Sub_Helper
VoiceCtrl_ParamSetupBytecode_Epilogue:
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ret
VoiceCtrl_ParamSetupBytecode_Helper3:
	ld	xiy, 3471
	ld	xix, 3525
	ld	(xix), 0
	cp	(xiy+2), 72
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Return3
	cp	(xiy+3), 5
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip13
	cp	(xiy+3), 6
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Return3
VoiceCtrl_ParamSetupBytecode_Skip13:
	ld	a, (xiy+4)
	bit	0, (0x0dc9:16)
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip14
	or	a, 128
VoiceCtrl_ParamSetupBytecode_Skip14:
	ld	(3569:16), a
	ldfr_berp	a, 60
	and	a, 240
	ldto_berp	a, 60
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip15
	call	VoiceCtrl_ParamSetupBytecode_Helper5
VoiceCtrl_ParamSetupBytecode_Skip15:
	call	VoiceCtrl_ParamSetupBytecode_Helper4
VoiceCtrl_ParamSetupBytecode_Return3:
	ret
VoiceCtrl_ParamSetupBytecode_Helper4:
	pushw	wa
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Epilogue2
	xor	c, c
	ld	w, (3569:16)
VoiceCtrl_ParamSetupBytecode_Join4:
	ldfr_berp	a, 60
	ldfr_berp	w, 61
	ld	a, c
	scf
	xorcfb_erp	61
	ldto_berp	a, 60
	jrl	nc, VoiceCtrl_ParamSetupBytecode_Skip16
	inc	1, c
	cp	c, 8
	jrl	z, VoiceCtrl_ParamSetupBytecode_Epilogue2
	jp	VoiceCtrl_ParamSetupBytecode_Join4
VoiceCtrl_ParamSetupBytecode_Skip16:
	ld	a, c
	cp	(3474:16), 6
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip17
	add	a, 8
VoiceCtrl_ParamSetupBytecode_Skip17:
	ld	xhl, SysInit_SendAllNotesAndReset_Tbl
	ld	a, (xhl+a)
	ld	(13964:16), a
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	VoiceCtrl_ParamSetupBytecode_Helper8
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
VoiceCtrl_ParamSetupBytecode_Epilogue2:
	popw	wa
	ret
VoiceCtrl_ParamSetupBytecode_Helper5:
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	pushdi_w	(0x0d5a)
	pushdi_w	(0x367e)
	pushdi_w	(0x0d5c)
	pushdi_w	(0x0d57)
	ld	(3533:16), 0
	ld	a, (3415:16)
	add	a, 48
	cp	a, 96
	jrl	c, VoiceCtrl_ParamSetupBytecode_Skip18
	sub	a, 96
	inc	1, (3533:16)
VoiceCtrl_ParamSetupBytecode_Skip18:
	ld	(3534:16), a
	pushdi_w	(0x0d8f)
	pushdi_w	(0x0d91)
	pushdi_w	(0x0d93)
	ld	(32422:16), 255
	call	DisplayMode_Handler_3_Sub
	popw (0x0d93:16)	; popw (0x0d93)
	popw (0x0d91:16)	; popw (0x0d91)
	popw (0x0d8f:16)	; popw (0x0d8f)
	res	2, (0x0d54:16)
	ld	xiy, 3471
	ld	(xiy), 176
	ld	a, (3415:16)
	inc	1, a
	ld	(xiy+1), a
	bit	1, (0x0dc9:16)
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip19
	ormi8	(xiy), 2
VoiceCtrl_ParamSetupBytecode_Skip19:
	ld	(xiy+4), 0
	ld	w, 6:opc
	push	xhl
	call	DisplayMode_Handler_3_Helper16
	pop	xhl
	popw (0x0d57:16)	; popw (0x0d57)
	popw (0x0d5c:16)	; popw (0x0d5c)
	popw (0x367e:16)	; popw (0x367e)
	popw (0x0d5a:16)	; popw (0x0d5a)
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	ret
DisplayMode_Handler_3_Helper10:
	cp	(3429:16), 0
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip20
	jp	VoiceCtrl_ParamSetupBytecode_Return4
VoiceCtrl_ParamSetupBytecode_Skip20:
	ld	xiy, 3471
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy), a
	ld	e, a
	and	e, 1
	rrc	e
	ld	(3828:16), a
	and	(0x0ef4:16), 4
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	a, (3415:16)
	ld	(xiy+1), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+2), a
	ld	l, (3828:16)
	and	l, 4
	rrc	l, 3
	or	a, l
	ld	(4539:16), a
	ld	(36955:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+3), a
	ld	(13959:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+4), a
	or	a, e
	ld	(4541:16), a
	ld	(13958:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+5), a
	ld	(3829:16), a
	ld	(4542:16), a
	ld	(3655:16), a
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Loop2
	ld	w, (4539:16)
	cp	w, 15
	jrl	le, VoiceCtrl_ParamSetupBytecode_Skip22
	cp	w, 72
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip23
VoiceCtrl_ParamSetupBytecode_Loop2:
	push	xhl
	ld	l, a
	ld	h, (4542:16)
	call	PartCtrl_WriteProgramChange
	ld	(4542:16), h
	ld	(13967:16), h
	pop	xhl
	call	TempoRingBuf_ReadByte
	push	xhl
	call	VoiceCtrl_ParamSetupBytecode_Helper
	cp	w, 1:i3
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip21
	ld	w, 6:opc
	ld	xiy, 3471
	call	DisplayMode_Handler_3_Helper16
	ld	(3422:16), 16
VoiceCtrl_ParamSetupBytecode_Skip21:
	ld	w, 98:opc
	call	MIDI_SendSysExFromW
	pop	xhl
	jp	VoiceCtrl_ParamSetupBytecode_Return4
VoiceCtrl_ParamSetupBytecode_Skip22:
	ld	(3567:16), 1
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	Display_BytecodeBlock_F_Sub
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	cp	(3429:16), 3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Loop2
	call	DisplayMode_Handler_3_Helper17
	jp	VoiceCtrl_ParamSetupBytecode_Return4
VoiceCtrl_ParamSetupBytecode_Skip23:
	cp	(3429:16), 3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip24
	ld	(3567:16), 12
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	DisplayStr_BytecodeBlock_D
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	jp	VoiceCtrl_ParamSetupBytecode_Loop2
VoiceCtrl_ParamSetupBytecode_Skip24:
	ld	(3567:16), 4
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	DisplayMode_Handler_3_Helper10_Helper
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	jp	VoiceCtrl_ParamSetupBytecode_Loop2
VoiceCtrl_ParamSetupBytecode_Return4:
	ret
DisplayMode_Handler_3_Helper11:
	ld	xiy, 3471
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy), a
	ld	(3413:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	a, (3415:16)
	ld	(xiy+1), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+2), a
	ld	e, a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+3), a
	ld	l, a
	rrc	a
	and	a, 128
	or	a, e
	ld	w, l
	rrc	w
	and	w, 1
	ld	(3826:16), wa
	or	(0x0d53:16), 16
	ld	(3538:16), 4
	ld	xhl, 3567
	cp	(3429:16), 3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Entry
	cp	(xhl), 16
	jrl	z, VoiceCtrl_ParamSetupBytecode_Join5
	ld	(xhl), 16
	call	Display_UpdateRegion0
	jp	VoiceCtrl_ParamSetupBytecode_Join5
VoiceCtrl_ParamSetupBytecode_Entry:
	cp	(xhl), 6
	jrl	z, VoiceCtrl_ParamSetupBytecode_Join5
	ld	(xhl), 6
	call	Display_UpdateRegion0
VoiceCtrl_ParamSetupBytecode_Join5:
	call	DisplayStr_BytecodeBlock_C_0x24
	ret
DisplayMode_Handler_3_Helper12:
	ld	a, 134:opc
	ld	(13964:16), 2
	call	VoiceCtrl_ParamSetupBytecode_Helper6
	ret
DisplayMode_Handler_3_Helper13:
	ld	a, 133:opc
	ld	(13964:16), 1
	call	VoiceCtrl_ParamSetupBytecode_Helper6
	ret
VoiceCtrl_ParamSetupBytecode_Helper6:
	call	VoiceCtrl_ParamSetupBytecode_Helper7
	cp	c, 0:i3
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip25
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	jp	VoiceCtrl_ParamSetupBytecode_Return5
VoiceCtrl_ParamSetupBytecode_Skip25:
	pushw	wa
	call	VoiceCtrl_ParamSetupBytecode_Helper8
	popw	wa
	ld	xiy, 3471
	ld	(xiy), a
	ld	a, (3415:16)
	ld	(xiy+1), a
	ld	w, 2:opc
	push	xhl
	call	DisplayMode_Handler_3_Helper16
	pop	xhl
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	w, 98:opc
	call	MIDI_SendSysExFromW
	ld	(3422:16), 16
VoiceCtrl_ParamSetupBytecode_Return5:
	ret
VoiceCtrl_ParamSetupBytecode_Helper7:
	push	xhl
	ld	l, (3822:16)
	dec	1, l
	xor	h, h
	ld	c, 255:opc
	push	xix
	ld	xix, 61856
	ld	l, (xix+hl)
	pop	xix
	cp	l, 16
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip26
	cp	l, 15
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Epilogue3
VoiceCtrl_ParamSetupBytecode_Skip26:
	xor	c, c
VoiceCtrl_ParamSetupBytecode_Epilogue3:
	pop	xhl
	ret
VoiceCtrl_ParamSetupBytecode_Helper8:
	push	xhl
	ld	a, (3429:16)
	and	a, 3
	exts	wa
	sla	wa, 2
	ld	iy, wa
	push	xde
	ld	xde, SerialPort_ModeSelect_Table
	ld	xiy, (xde+iy)
	pop	xde
	call (xiy)
	pop	xhl
	ret
	; Handler dispatch table, 16 B.  Read by VoiceCtrl_ParamSetupBytecode (0xEF97B6): `ld xde, SerialPort_ModeSelect_Table`
	; indexed with stride 4 (`sla wa, 2`), index from `ld a, (3429:16)`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
SerialPort_ModeSelect_Table:
	.long	SerialPort_ModeHandler_0
	.long	SerialPort_ModeHandler_1
	.long	SerialPort_ModeHandler_1
	.long	SerialPort_ModeHandler_3
SerialPort_ModeHandler_1:
	ld	(3567:16), 5
	call	DisplayStr_BytecodeBlock_C
	ret
SerialPort_ModeHandler_3:
	ld	(3567:16), 15
	call	DisplayStr_StyleSectionInit
	ret
SerialPort_ModeHandler_0:
	call	SerialPort_ModeHandler_0_Helper
	ret
SerialPort_ModeHandler_0_0x5:
	cp	(3429:16), 3
	jrl	nz, SerialPort_ModeHandler_0_Skip
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	jp	SerialPort_ModeHandler_0_Return
SerialPort_ModeHandler_0_Skip:
	ld	xiy, 3471
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy), a
	ld	(3413:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	a, (3415:16)
	ld	(xiy+1), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+2), a
	ld	(13957:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(3538:16), 3
	ld	(13956:16), 2
	cp	(3567:16), 2
	jrl	nz, SerialPort_ModeHandler_0_Skip2
	call	DisplayStr_BytecodeBlock_B_Sub2
	jp	SerialPort_ModeHandler_0_Join
SerialPort_ModeHandler_0_Skip2:
	ld	(3567:16), 2
	call	DisplayStr_BytecodeBlock_B_0x39
SerialPort_ModeHandler_0_Join:
	ld	(3540:16), 0
SerialPort_ModeHandler_0_Return:
	ret
DisplayMode_Handler_3_Helper15:
	cp	(3429:16), 3
	jrl	nz, SerialPort_ModeHandler_0_Skip3
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	jp	SerialPort_ModeHandler_0_Return2
SerialPort_ModeHandler_0_Skip3:
	ld	xiy, 3471
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy), a
	ld	(3413:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	a, (3415:16)
	ld	(xiy+1), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+2), a
	ld	(13957:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+3), a
	ld	(4370:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(3538:16), 4
	ld	(13956:16), 1
	cp	(3567:16), 2
	jrl	nz, SerialPort_ModeHandler_0_Skip4
	call	DisplayStr_BytecodeBlock_B_Sub2
	jp	SerialPort_ModeHandler_0_Join2
SerialPort_ModeHandler_0_Skip4:
	ld	(3567:16), 2
	call	DisplayStr_BytecodeBlock_B_0x39
SerialPort_ModeHandler_0_Join2:
	ld	(3540:16), 0
SerialPort_ModeHandler_0_Return2:
	ret
ToneParam_ModeGuardEntry_Helper2:
	ld	c, (3533:16)
	xor	b, b
	add (3418:16), bc
	cp	c, 0:i3
	jrl	z, SerialPort_ModeHandler_0_Return3
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	ToneParam_ModeGuardEntry_Helper2_Helper
	djnz16	bc, -7
	call	AccPedal_CheckBitAndUpdate
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
SerialPort_ModeHandler_0_Return3:
	ret
ToneParam_ModeGuardEntry_Helper3:
	ld	l, (13944:16)
	cp	l, 0:i3
	jrl	nz, SerialPort_ModeHandler_0_Skip5
	ld	l, 6:opc
SerialPort_ModeHandler_0_Skip5:
	sla	l, 1
	xor	h, h
	push	xix
	ld	xix, ScoopParam_ValueTable
	ld	de, (xix+hl)
	ld	l, (13945:16)
	sla	l, 1
	ld	bc, (xix+hl)
	pop	xix
	add	de, bc
	ld	wa, de
	ld	l, 96:opc
	div	wa, l
	ld	(13203:16), w
	ld	(13204:16), a
	ld	a, (13946:16)
	cp	a, 1:i3
	jrl	nz, SerialPort_ModeHandler_0_Skip6
	sla	de, 2
	ld	wa, de
	xor	de, de
	ld	hl, 5:i3
	ld	qwa, de
	div	xwa, hl
	ld	de, qwa
	jp	SerialPort_ModeHandler_0_Join3
SerialPort_ModeHandler_0_Skip6:
	cp	a, 0:i3
	jrl	nz, SerialPort_ModeHandler_0_Skip7
	ld	wa, de
	sla	wa, 4
	add	wa, de
	add	wa, de
	add	wa, de
	xor	de, de
	ldw	hl, 20
	ld	qwa, de
	div	xwa, hl
	ld	de, qwa
	jp	SerialPort_ModeHandler_0_Join3
SerialPort_ModeHandler_0_Skip7:
	cp	a, 2:i3
	jrl	nz, SerialPort_ModeHandler_0_Skip8
	srl	de, 1
	ld	wa, de
	jp	SerialPort_ModeHandler_0_Join3
SerialPort_ModeHandler_0_Skip8:
	srl	de, 2
	ld	wa, de
SerialPort_ModeHandler_0_Join3:
	ld	l, 96:opc
	div	wa, l
	ld	(13201:16), w
	ld	(13202:16), a
	ret
	; Byte data, 28 B.  Read by SerialPort_ModeHandler_0 (0xEF9DD9): `ld xix, ScoopParam_ValueTable`
	; reader SerialPort_ModeHandler_0: `ld xix, ScoopParam_ValueTable` then `ld_rrw bc, xix, hl`
ScoopParam_ValueTable:
	.byte	0x00, 0x00, 0x08, 0x00, 0x0c, 0x00, 0x10, 0x00, 0x18, 0x00, 0x20, 0x00, 0x30, 0x00, 0x40, 0x00
	.byte	0x60, 0x00, 0xc0, 0x00, 0x80, 0x01, 0x00, 0x03, 0x80, 0x04, 0x00, 0x06
ScoopParam_ValueTable_0x1C:
	call	SerialPort_ModeHandler_0_Helper2
	stb_d8	(0x0d57), w
	stb_d8	(0x0dcd), a
	ret
ScoopParam_ValueTable_0x29:
	call	SerialPort_ModeHandler_0_Helper2
	stb_d8	(0x0dce), w
	stb_d8	(0x0dcd), a
	ret
SerialPort_ModeHandler_0_Helper2:
	ldb_d8	w, (0x3393)
	ldb_d8	a, (0x3394)
	add	w, (0x0d57:16)
	cp	w, 96
	jrl	c, SerialPort_ModeHandler_0_Return4
	sub	w, 96
	inc	1, a
SerialPort_ModeHandler_0_Return4:
	ret
SysEx_BytecodeDispatcher_Helper5:
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	xiy, 0x28be
	cp	(xiy), 255
	jrl	z, SerialPort_ModeHandler_0_Epilogue
	ld	(xiy), 255
	ldb_d8	a, (0x0eee)
	stb_d8	(0x2877), a
	call	Scoop_SpecialMode_ParamCheckBound
	res	7, (0x0d54:16)
	call	PerfMode_Handler_EvtB_Helper2
	or	(0x8cec:16), 1
SerialPort_ModeHandler_0_Epilogue:
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ret
Timer_ParamCompareAlt_Helper7:
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	xor	bc, bc
SerialPort_ModeHandler_0_Loop:
	ld	wa, bc
	ld	xhl, 0x0d6f
	ld	a, (xhl+a)
	lda	xhl, (xhl+bc)
	ld	(xhl), 255
	ld	e, a
	cp	a, 255
	jrl	nz, SerialPort_ModeHandler_0_Skip9
SerialPort_ModeHandler_0_Join4:
	inc	1, bc
	cp	bc, 28
	jrl	ule, SerialPort_ModeHandler_0_Loop
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	and	(0x0d53:16), 254
	jp	SerialPort_ModeHandler_0_Return5
SerialPort_ModeHandler_0_Skip9:
	ld	xiy, 0x0d8f
	ld	(xiy), 176
	ldb_d8	a, (0x0d57)
	ld	(xiy+1), a
	ld	(xiy+5), 127
	ld	a, c
	cp	a, 15
	jrl	ugt, SerialPort_ModeHandler_0_Skip10
	ld	xhl, SerialPort_ModeHandler_0_Tbl
	ld	a, (xhl+a)
	ld	w, 3:opc
	jp	SerialPort_ModeHandler_0_Join5
SerialPort_ModeHandler_0_Skip10:
	cp	a, 27
	jrl	nz, SerialPort_ModeHandler_0_Skip11
	ld	a, 72:opc
	ld	w, 8:opc
	jp	SerialPort_ModeHandler_0_Join5
SerialPort_ModeHandler_0_Skip11:
	cp	a, 28
	jrl	z, SerialPort_ModeHandler_0_Skip12
	sub	a, 16
	ld	l, a
	xor	h, h
	push	xix
	ld	xix, SerialPort_ModeHandler_0_Data
	ld	a, (xix+hl)
	ld	xix, SerialPort_ModeHandler_0_Data2
	ld	w, (xix+hl)
	pop	xix
	cp	a, 255
	jrl	nz, SerialPort_ModeHandler_0_Join5
	jp	SerialPort_ModeHandler_0_Join4
SerialPort_ModeHandler_0_Skip12:
	ormi8	(xiy), 4
	ld	(xiy+2), 152
	andmi8	(xiy+2), 127
	ld	(xiy+3), 1
	ld	(xiy+4), e
	ld	(xiy+5), 127
	ld	w, 6:opc
	pushw	bc
	call	DisplayMode_Handler_3_Helper16
	popw	bc
	jp	SerialPort_ModeHandler_0_Join4
SerialPort_ModeHandler_0_Join5:
	ld	(xiy+2), a
	ld	a, w
	ld	(xiy+3), a
	ld	(xiy+4), e
	ld	w, 6:opc
	pushw	bc
	call	DisplayMode_Handler_3_Helper16
	popw	bc
	jp	SerialPort_ModeHandler_0_Join4
SerialPort_ModeHandler_0_Return5:
	ret
	; Byte data, 16 B.  Read by SerialPort_ModeHandler_0 (0xEF9DD9): `ld xhl, SerialPort_ModeHandler_0_Tbl`
	; index bounded to 0..15 (`cp a, 15` / `jrl ugt` skips larger values)
SerialPort_ModeHandler_0_Tbl:
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	; Loaded by SerialPort_ModeHandler_0 (0xEF9DD9):
	; `ld xix, SerialPort_ModeHandler_0_Data` -- a bare number until lane scoop gave this address a label.
SerialPort_ModeHandler_0_Data:
	.byte	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 'p', 0x98, 0xff, 0xff
	; Loaded by SerialPort_ModeHandler_0 (0xEF9DD9):
	; `ld xix, SerialPort_ModeHandler_0_Data2` -- a bare number until lane scoop gave this address a label.
SerialPort_ModeHandler_0_Data2:
	.byte	0x03, 0x03, 0x03, 0x03, 0x03
	.byte	0x03, 0x03, 0x03, 0x04
Display_CallMenuInit_Helper:
	ld	(0x10fa:16), 0
	ldb_d8	a, (0x8c9a)
	cp	a, (0x8c9b:16)
	jrl	z, PerfMode_Handler_EvtB_Helper2_Skip4
	ld	(0x28be:16), 255
	call	SeqBuf_Init
	and	(0x0d53:16), 254
	and	(0x28a6:16), 254
	call	AccWrap_PositionClear
	ld	(0x7ea6:16), 0
	call	VoiceCtrl_CheckAndReset
	ldb_d8	a, (0xfc5d)
	stb_d8	(0x1128), a
	call	PortConfig_Handler_0_Helper4
	cp	(0x0d65:16), 0
	jrl	nz, PerfMode_Handler_EvtB_Helper2
	and	(0xfc5d:16), 247
	ld	e, 72:opc
	ld	d, 3:opc
	ldb_d8	a, (0xfc5d)
	ld	w, 8:opc
	call	SysEx_ApplyVoiceParam_49
PerfMode_Handler_EvtB_Helper2:
	ld (0x3678:16), 0x04
	ld (0x3679:16), 0x00
	ld (0x367a:16), 0x01
	call PerfMode_Handler_EvtB_Helper2_Helper4
	call PortConfig_Handler_0_Helper4
	ld a, (0x8c9e:16)
	ld (0x0d66:16), a
	call PerfMode_Handler_EvtB_Helper2_Helper3
	call PerfMode_Handler_EvtB_Helper2_Helper5
	call PerfMode_Handler_EvtB_Helper2_Helper6
	call ClockConfig_Handler_0_Helper
	cpw (0xf231:16), 0x0000
	jrl nz, .Lc_efa1aa
	call VoiceState_DataBlock2_Helper7
	cp w, 0:i3
	jrl z, .Lc_efa1aa
	ld (0x0d69:16), 0x18
	jp SerialPort_ModeHandler_0_Return6
.Lc_efa1aa:
	res 7, (0x0d54:16)
	call PortConfig_Handler_0_Loop
	call SeqBuf_Init
	call PerfMode_Handler_EvtB_Helper2_Helper2
	call PerfMode_Handler_EvtB_Helper2_Helper9
	call BitMapOut_ComputeRegionDelta
	call Timer_ModeHandler_0_Helper2
	call PortConfig_SetupBytecode
	xor WA,WA
	ld (0x0d4f:16), wa
	ld (0x0d51:16), wa
	ld c, (0x0eee:16)
	dec 1,C
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ldw_d16	de, (0x0d4f)
	ld	a, c
	scf
	stcf_a_16 de	; stcf A,DE
	ldto_berp	a, 60
	ld	(0x0d4f:16), de
	ldto_werp DE, 0x3e	; ld DE,QHL3
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ldw_d16	de, (0x0d51)
	ld	a, c
	scf
	stcf_a_16 de	; stcf A,DE
	ldto_berp	a, 60
	ld	(0x0d51:16), de
	ldto_werp DE, 0x3e	; ld DE,QHL3
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ld	de, (0xffec:24)
	ld	a, c
	rcf
	stcf_a_16 de	; stcf A,DE
	ldto_berp	a, 60
	ld	(0xffec:24), de
	ldto_werp DE, 0x3e	; ld DE,QHL3
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ldw_d16	de, (0xf19e)
	ld	a, c
	rcf
	stcf_a_16 de	; stcf A,DE
	ldto_berp	a, 60
	ld	(0xf19e:16), de
	ldto_werp DE, 0x3e	; ld DE,QHL3
	ldw	(0xf19e:16), 0
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ldw_d16	de, (0x2875)
	ld	a, c
	rcf
	stcf_a_16 de	; stcf A,DE
	ldto_berp	a, 60
	ld	(0x2875:16), de
	ldto_werp DE, 0x3e	; ld DE,QHL3
	ldw	(0x0f58:16), 65535
	call	PerfMode_Handler_EvtB_Helper2_Helper11
	call	VoiceState_DataBlock2_Helper7
	cp	w, 0:i3
	jrl	z, PerfMode_Handler_EvtB_Helper2_Skip
	call	ToneParam_ModeGuardEntry_Helper2_Helper
	call	VoiceSlot_CompareAndBranch
	call	PerfMode_Handler_EvtB_Helper2_Helper8
	jp	PerfMode_Handler_EvtB_Helper2_Join
PerfMode_Handler_EvtB_Helper2_Skip:
	call	MemoryConfig_Handler_Table_Target2_Sub
PerfMode_Handler_EvtB_Helper2_Join:
	call	MemConfig_Handler_4_Helper5_Helper
	bit	2, (0x0421:16)
	jrl	z, PerfMode_Handler_EvtB_Helper2_Skip2
	call	Demo_PreSetupAndScan
PerfMode_Handler_EvtB_Helper2_Skip2:
	and	(0x33d2:16), 239
	and	(0x045b:16), 252
	call	PerfMode_Handler_EvtB_Helper2_Helper10
	or	(0x28a7:16), 4
	ld	xiy, 0x0d53
	ormi8	(xiy), 8
	andmi8	(xiy), 223
	call	AccPedal_CheckBitAndUpdate
	set	0, (0x0dd3:16)
	ld	(0x368c:16), 0
	cp	(0x10fa:16), 0
	jrl	nz, PerfMode_Handler_EvtB_Helper2_Skip3
	call	ScoopDisp_DispatchTable_Small_Target11_Helper
PerfMode_Handler_EvtB_Helper2_Skip3:
	call	PerfMode_Handler_EvtB_Helper2_Helper
	jp	SerialPort_ModeHandler_0_Return6
PerfMode_Handler_EvtB_Helper2_Skip4:
	call PerfMode_Handler_EvtB_Helper2_Helper6
	call ClockConfig_Handler_0_Helper
	bit 3, (0x0d53:16)
	jrl z, .Lc_efa2ef
	call ScoopDisp_DispatchTable_Small_Target11_Helper
	cp (0x0d65:16), 0x00
	jrl nz, .Lc_efa2ef
.Lc_efa2ef:
	jp SerialPort_ModeHandler_0_Return6
SerialPort_ModeHandler_0_Return6:
	ret
Interrupt_ModeGuardCheck:
	cp (3567:16), 18
	jrl z, Interrupt_NullRet
	cp (3429:16), 0
	jrl nz, Interrupt_NullRet
	jp Interrupt_ModeGuardEntry
Interrupt_JumpToGuard:
	jp	Interrupt_NullRet

Interrupt_ModeGuardEntry:
	cp (3429:16), 0
	jrl nz, Interrupt_NullRet
	ld a, (3432:16)
	cp a, 4:i3
	jrl ule, Interrupt_CodeDispatch
	xor a, a

; Interrupt dispatch by code
Interrupt_CodeDispatch:
	xor w, w
	sla a, 2
	ld hl, wa
	ld xwa, Interrupt_VectorSelect_Table
	ld	xhl, (xwa+hl)
	call (xhl)
	jp Interrupt_NullRet

Interrupt_NullRet:
	ret

	; Handler dispatch table, 20 B.  Read by Interrupt_CodeDispatch (0xEFA31F): `ld xwa, Interrupt_VectorSelect_Table`
	; 5 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
Interrupt_VectorSelect_Table:
	.long	Interrupt_VectorHandler_0
	.long	Interrupt_VectorHandler_1
	.long	Interrupt_VectorHandler_2
	.long	Interrupt_VectorHandler_3
	.long	Interrupt_VectorHandler_4
Interrupt_VectorHandler_0:
	cp (0x8ca4:16), 0x00
	jrl z, Interrupt_Vec0_InitPath
	call Interrupt_StoreHWRegsAndInit
	jp Interrupt_Vec0_Ret
Interrupt_Vec0_InitPath:
	call Interrupt_ClearRegsAndInit

Interrupt_Vec0_Ret:
	ret

Interrupt_VectorHandler_1:
	ld (3432:16), 0
	call Interrupt_VectorHandler_0
	ret

Interrupt_VectorHandler_2:
	; cpdi8 (0x8d40), 0 (v7 patched)
	cp	(0x8ca4:16), 0
	; jrl z, Interrupt_Vec2_Ret (v7 displacement)
	jrl	z, Interrupt_Vec2_Ret
	; call Interrupt_SendAllNotesOff (v7 addr)
	call	Interrupt_SendAllNotesOff



Interrupt_Vec2_Ret:
	ret

Interrupt_VectorHandler_3:
	cp	(36004:16), 0
	jrl	nz, Interrupt_Vec3_UpdatePath
	call	Interrupt_ClearModeRegs
	jp	Interrupt_Vec3_Ret
Interrupt_Vec3_UpdatePath:
	call Display_RegionUpdateFromHW

Interrupt_Vec3_Ret:
	ret

Interrupt_VectorHandler_4:
	cp	(0x8ca4:16), 0
	jrl	z, Interrupt_Vec4_InitPath
	call	Interrupt_UpdateFromHW
	jp	Interrupt_Vec4_Ret
Interrupt_Vec4_InitPath:
	call Interrupt_ClearModeAndRet

Interrupt_Vec4_Ret:
	ret

Interrupt_StoreHWRegsAndInit:
	cp (3422:16), 0
	jrl z, Interrupt_LoadAndStoreRegs
	ld (3422:16), 0

Interrupt_LoadAndStoreRegs:
	ld	a, (36004:16)
	ld	(3437:16), a
	ld	a, (36006:16)
	ld	(3438:16), a
	ld	a, (36008:16)
	ld	(4391:16), a
	xor	a, a
	ld	(3425:16), a
	call	SNS_Init_Startup
	call	Display_UpdateRegion3
	ret
Interrupt_ClearRegsAndInit:
	xor a, a
	ld (3437:16), a
	ld (3438:16), a
	ld (3425:16), a
	ld (4391:16), a
	call SNS_Init_Startup
	call Display_UpdateRegion3
	ret

Interrupt_FlagSetBytecode:
	xor	a, a
	ld	(3432:16), a
	ld	(3425:16), a
	call	SNS_Init_Startup
	call	Display_UpdateRegion3
	ret
MemConfig_Handler_5_Code_Helper10:
	ld	(3432:16), 2
	ld	(3431:16), 4
	call	PerfMode_Handler_EvtB_Helper2_Helper11
	ret
Interrupt_SendAllNotesOff:
	ld	(3432:16), 3
	call	Display_RegionUpdateFromHW
	call	VoiceCtrl_SendNoteOffSequence
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	Interrupt_FlagSetBytecode_Helper2
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	Interrupt_FlagSetBytecode_Helper
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ret
Interrupt_ClearModeRegs:
	xor	a, a
	ld	(3432:16), a
	ld	(3431:16), a
	call	PerfMode_Handler_EvtB_Helper2_Helper11
	ret
Interrupt_SetFlagBytecode:
	ld	(3432:16), 4
	ld	(3431:16), 0
	call	PerfMode_Handler_EvtB_Helper2_Helper11
	ret
Interrupt_UpdateFromHW:
	call Display_RegionUpdateFromHW
	ret

Interrupt_ClearModeAndRet:
	ld (3432:16), 0
	ret

Display_RegionUpdateFromHW:
	ld	a, (36004:16)
	ld	(3437:16), a
	ld	a, (36006:16)
	ld	(3438:16), a
	ld	a, (36008:16)
	ld	(4391:16), a
	call	SNS_Init_Startup
	call	Display_UpdateRegion3
	ret
PortConfig_SetupBytecode:
	ld	(0x28be:16), 255
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	push	xix
	ld	xix, 0xf1a0
	cp	(xix+iz), 0x0e
	pop	xix
	jrl	nz, PortConfig_SetupBytecode_Return
	ld	a, (3822:16)
	dec	1, a
	ld	(0x28be:16), a
	push	xix
	ld	xix, 0xf1a0
	ld	(xix+iz), 0x0d
	pop	xix
PortConfig_SetupBytecode_Return:
	ret
ScoopDisp_DispatchTable_Small_Target11_Helper:
	ld	a, (3429:16)
	and	wa, 3
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, PortConfig_Select_Table
	ld	xhl, (xix+hl)
	pop xix
	call	(xhl)
	ret
	; Handler dispatch table, 16 B.  Read by PortConfig_SetupBytecode (0xEFA48E): `ld xix, PortConfig_Select_Table`
	; indexed with stride 4 (`sla wa, 2`), index from `ld hl, wa`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
PortConfig_Select_Table:
	.long	PortConfig_Handler_0
	.long	PortConfig_Handler_1
	.long	PortConfig_Handler_1
	.long	PortConfig_Handler_3
PortConfig_Handler_1:
	or	(0x0dd3:16), 1
	call	VoiceSlot_TableSetup
	call	DisplayMode_Dispatch_Mode1_Helper
	call	PortConfig_Handler_0_Helper2
	call	PortConfig_Handler_1_Helper
	res	2, (0x0d54:16)
	ret
PortConfig_Handler_3:
	; --- Init: call FB1536, set 3 flags, call 6 handlers, call FB155F (51 bytes) ---
	call Display_DeferOrDrawWall
	ld	(0x0205e8:24), 255
	ld	(0x0205ec:24), 255
	ld	(0x0205ea:24), 255
	call DisplayMode_Handler_3_Helper19
	call DMA_ChannelHandler_3_Helper
	call PortConfig_Handler_0_Helper2
	call UIState_UpdateMultiRegions
	call Display_UpdateRegion3
	call Display_UpdateRegion2
	call Display_DeferOrUpdateScreen
	ret
PortConfig_Handler_0:
	call	Display_DeferOrDrawWall
	ld	(132584:24), 255
	ld	(132588:24), 255
	ld	(132586:24), 255
	call	Display_BytecodeBlock_F_Sub2
	call	Display_UpdateRegion0
	call	PortConfig_Handler_0_Helper3
	cp	(10430:16), 255
	jrl	z, PortConfig_Handler_0_Skip2
	ldw	(3660:16), 0
	ldw	(3662:16), 1
	ldw	(3664:16), 0
	call	PortConfig_Handler_0_Helper
	ld	(3702:16), 1
	ldw	(3703:16), 0
	xor	l, l
	ld	a, (1075:16)
	cp	a, 4:i3
	jrl	ule, PortConfig_Handler_0_Skip
	ld	l, a
	ld	a, 4:opc
	sub	l, 4
	ldw	(3664:16), 1
PortConfig_Handler_0_Skip:
	ld	(3666:16), 0
	ld	(3667:16), a
	ld	(3668:16), l
	pushw	wa
	pushw	bc
	push	xix
	ld	xix, 3786
	ldw	wa, 8224
	ldw	bc, 15
	ld	(xix+), wa
	djnz16	bc, -6
	pop	xix
	popw	bc
	popw	wa
	ld	(3788:16), 49
	ld	(3796:16), 69
	ld	(3797:16), 78
	ld	(3798:16), 68
	call	Display_UpdateRegion6
	call	Display_UpdateRegion1
	call	Display_UpdateRegion6
	call	Display_UpdateRegion3
	jp	PortConfig_Handler_0_Join
PortConfig_Handler_0_Skip2:
	call	MemConfig_Handler_5_Helper
	call	PortConfig_Handler_0_Helper2
	call	MemConfig_Handler_5_Code_Helper11
PortConfig_Handler_0_Join:
	call	Display_DeferOrUpdateScreen
	ret
PortConfig_Handler_0_Helper:
	pushw	wa
	pushw	bc
	push	xix
	ld	xix, 3669
	ldw	bc, 96
	xor	wa, wa
	ld	(xix+), a
	djnz16	bc, -6
	pop	xix
	popw	bc
	popw	wa
	ret
PortConfig_Handler_0_Helper2:
	call VoiceSlot_ReadCurrentParams
	cp A,0x84
	jrl z, .Lc_efa641
	cp A,0x82
	jrl z, .Lc_efa641
	call VoiceSlot_FlagCheck
	cp A,0x84
	jrl z, .Lc_efa641
	cp A,0x82
	jrl z, .Lc_efa641
	cp a, (0x0d57:16)
	jrl nz, .Lc_efa641
	call PortConfig_Handler_0_Helper5
	jp PortConfig_Handler_0_Return2
.Lc_efa641:
	call Timer_ParamCompareAlt_Helper6
PortConfig_Handler_0_Return2:
	ret
PerfMode_Handler_EvtB_Helper2_Helper2:
	call	VoiceSlot_ComputeIndex
	push	xde
	ld	xde, 62032
	bit	7, (xde+iz)
	pop	xde
	jrl	nz, PortConfig_Handler_0_Skip3
	call	VoiceSlot_ComputeWordIndex
	push	xix
	ld	xix, 3230
	ldw	(xix+iz), 0xffff	; ld (XIX+IZ),0xffff
	srl	iz, 1
	ld	xix, 3262
	ld	(xix+iz), 0x05
	pop	xix
	jp	PortConfig_Handler_0_Return
PortConfig_Handler_0_Skip3:
	push	xde
	push	xix
	ld	xix, 62032
	inc	1, iz
	ld	de, (xix+iz)
	call	VoiceSlot_ComputeWordIndex
	ld	xix, 3230
	ld	(xix+iz), de
	srl	iz, 1
	ld	xix, 3262
	ld	(xix+iz), 0x05
	pop	xix
	pop	xde
PortConfig_Handler_0_Return:
	ret
PortConfig_Handler_0_Helper4:
	ld	a, (3424:16)
	ld	(3822:16), a
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	push	xix
	ld	xix, 61856
	ld	a, (xix+iz)
	pop	xix
	ld	xhl, PortConfig_DataTable_A
	ld	a, (xhl+a)
	ld	(3429:16), a
	ret
	; Byte data, 24 B.  Read by PortConfig_Handler_0 (0xEFA53B): `ld xhl, PortConfig_DataTable_A`
	; reader PortConfig_Handler_0: `ld xhl, PortConfig_DataTable_A` then `ld_rr8b a, xhl, a`
PortConfig_DataTable_A:
	.byte	0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x02
	.byte	0x03, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
PerfMode_Handler_EvtB_Helper2_Helper3:
	call VoiceSlot_ComputeWordIndex
	srl XIZ, 0x01
	push XIX
	ld XIX,0x0000f1a0
	ld	a, (xix+iz)
	pop XIX
	cp A,0x0f
	jrl z, .Lc_efa734
	cp A,0x10
	jrl z, .Lc_efa734
	and A,0x1f
	ld L,A
	xor H,H
	sla HL, 0x02
	ld XHL,PortConfig_DataTable_B
	ld	a, (xhl+a)
	cp A,0xff
	jrl z, .Lc_efa734
PortConfig_DataTable_A_Sub:
	ld (0x8c9e:16), a
	ld E,A
	ld D, 0xff:opc
	ldw WA, 0x1090
	call PortConfig_DataTable_A_Helper
.Lc_efa734:
PortConfig_DataTable_A_Sub_Return:
	ret
	; Byte data, 20 B.  Read by PortConfig_Handler_0 (0xEFA53B): `ld XHL,PortConfig_DataTable_B`
	; indexed with stride 1 (`sla HL, 0x02`)
PortConfig_DataTable_B:
	.byte	0x00, 0x02, 0x01, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x04, 0x05, 0x06, 0x03, 0x0f, 0xff, 0xff, 0xff
	.byte	0xff, 0x0c, 0x0d, 0x0e
PerfMode_Handler_EvtB_Helper2_Helper4:
	ld	xhl, 4362
	ld	xwa, (7514:16)
	ld	(xhl), xwa
	ret
PortConfig_Handler_0_Loop:
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	cp	wa, 0xffff
	jrl	nz, PortConfig_Handler_0_Loop
	ret
PerfMode_Handler_EvtB_Helper2_Helper5:
	ld	xhl, PortConfig_Handler_0_Tbl
	ld	a, (3429:16)
	and	a, 3
	ld	a, (xhl+a)
	ld (3567:16), a
	ret
	; Byte data, 4 B.  Read by PortConfig_Handler_0 (0xEFA53B): `ld xhl, PortConfig_Handler_0_Tbl`
	; reader PortConfig_Handler_0: `ld xhl, PortConfig_Handler_0_Tbl` then `ld_rr8b a, xhl, a`
PortConfig_Handler_0_Tbl:
	.byte	0x00, 0x00, 0x00, 0x0c
PerfMode_Handler_EvtB_Helper2_Helper6:
	ret
	; Pointer table, 16 B.  No reader found: no label, positional or absolute .set
	; name at this address is loaded anywhere in the image (searched by
	; scripts/analysis/scoop_data_headers.py); purpose not established.
ClockConfig_Select_Table:
	.long	ClockConfig_Handler_0
	.long	ClockConfig_Handler_1
	.long	ClockConfig_Handler_1
	.long	ClockConfig_Handler_0
ClockConfig_Handler_1:
	or	(0xe31c:16), 2
	ret	
ClockConfig_Handler_0:
	and	(0xe31c:16), 253
	ret
ClockConfig_Handler_0_Helper:
	ret
	; Byte data, 4 B.  No reader found: no label, positional or absolute .set
	; name at this address is loaded anywhere in the image (searched by
	; scripts/analysis/scoop_data_headers.py); purpose not established.
Unref_EFA79B_Tbl:
	.byte	0x04, 0x02, 0x02, 0x04
PerfMode_Handler_EvtB_Helper2_Helper8:
	cp	(0x0d65:16), 3
	jrl	nz, ClockConfig_Handler_0_Return
	ld	bc, 6:i3
	ld	xiy, ClockConfig_Handler_0_Tbl
	ld	xix, 0x0d8f
	push	xix
	ldir85
	pop	xix
	ldb_d8	a, (0xfc5a)
	ld	w, a
	and	a, 127
	ld	(xix+4), a
	and	w, 128
	rlc	w
	or	(xix), w
	ldb_d8	a, (0xfc5b)
	and	a, 127
	or	(xix+5), a
	ld	xiy, xix
	ld	w, 6:opc
	call	DisplayMode_Handler_3_Helper16
	bit	7, (0xfc5a:16)
	jrl	z, ClockConfig_Handler_0_Skip
	ldb_d8	a, (0xfc5a)
	cp	a, 240
	jrl	nc, ClockConfig_Handler_0_Skip
	and	a, 127
	extz	wa
	div	a, 4
	sla	w, 4
	ldb_d8	a, (0xfc61)
	and	a, 207
	or	a, w
	stb_d8	(0xfc61), a
	ld	e, 72:opc
	ld	d, 7:opc
	ld	w, 48:opc
	call	SysEx_ApplyVoiceParam_49
ClockConfig_Handler_0_Skip:
	ld	bc, 6:i3
	ld	xiy, ClockConfig_Handler_0_Tbl2
	ld	xix, 0x0d8f
	push	xix
	ldir85
	pop	xix
	ldb_d8	a, (0xfc61)
	and	a, 127
	ld	(xix+4), a
	ld	xiy, xix
	ld	w, 6:opc
	call	DisplayMode_Handler_3_Helper16
ClockConfig_Handler_0_Return:
	ret
	; 6-byte template, copied (`ldir`, BC = 6) to RAM 0x0D8F by PerfMode_Handler_EvtB_Helper2_Helper8
	; (v10: ScoopParam_ValueTable_Sub_Helper; display mode 3), which fills bytes +0/+4/+5 from 0xFC5A/0xFC5B and passes the six
	; bytes to DisplayMode_Handler_3_Helper16 (W = 6).
ClockConfig_Handler_0_Tbl:
	.byte	0xc0, 0x00, 'H', 0x00, 0x00, 0x00
	; 6-byte template, copied the same way (`ldir`, BC = 6, to RAM 0x0D8F) by the
	; ClockConfig_Handler_0_Skip path (v10: ScoopParam_ValueTable_Helper6_Skip), which fills
	; it from 0xFC61.
ClockConfig_Handler_0_Tbl2:
	.byte	0xb0, 0x00, 'H', 0x07, 0x00, '0'
MemConfig_Handler_4_Helper5_Helper:
	xor	wa, wa
	ld	(0x0e4c:16), wa
	ld	(0x0e4e:16), wa
	ld	(0x0e50:16), wa
	stb_d8	(0x0e52), a
	stb_d8	(0x0e53), a
	stb_d8	(0x0e54), a
	ld	(0x0d58:16), wa
	ld	(0x0d5a:16), wa
	stb_d8	(0x0d57), a
	ld	(0x367e:16), wa
	stb_d8	(0x367d), a
	stb_d8	(0x368c), a
	stb_d8	(0x0d68), a
	stb_d8	(0x0d67), a
	stb_d8	(0x0d5e), a
	stb_d8	(0x0dd4), a
	ldw	wa, 65535
	stb_d8	(0x0dd0), a
	stb_d8	(0x0d55), a
	pushw	bc
	push	xix
	ld	xix, 0x0d6f
	ldw	bc, 16
	ld	(xix+), wa
	djnz16	bc, -6
	pop	xix
	popw	bc
	ld	(0x3680:16), 32
	ret
Display_CallMenuConfig_Helper:
	ld (0x3673:16), 0x00
	call VoiceState_DataBlock2_Helper16
	ld (0x0d55:16), 0xff
	and (0x0f57:16), 0xfe
	ld (0x0d36:16), 0x00
	ld a, (0x8c9b:16)
	cp	(0x8c9a:16), a
	jrl	z, ClockConfig_Handler_0_Tbl2_Return
	and	(0x0d53:16), 254
	bit	0, (0x0f54:16)
	jrl	z, ClockConfig_Handler_0_Skip2
	call	VoiceCtrl_SendNoteOffSequence
ClockConfig_Handler_0_Skip2:
	and	(0x0f54:16), 254
	bit	0, (0x1126:16)
	jrl	nz, ClockConfig_Handler_0_Skip3
	cp	(0x28be:16), 255
	jrl	nz, ClockConfig_Handler_0_Skip3
	call	Timer_ParamCompareAlt_Helper7
ClockConfig_Handler_0_Skip3:
	and	(0x1126:16), 254
	ldw_d16	de, (0x2875)
	ld	de, (0xffec:24)
	call	VoiceState_DataBlock2_Helper7
	cp	w, 0:i3
	jrl	nz, ClockConfig_Handler_0_Skip4
	ldb_d8	c, (0x0eee)
	dec	1, c
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ld	a, c
	scf
	stcfw_erp 0x3e	; stcf A,QHL3
	ldto_berp	a, 60
	ldto_werp DE, 0x3e	; ld DE,QHL3
ClockConfig_Handler_0_Skip4:
	ld	(0xf19e:16), de
	ld	(0xffec:24), de
	or	(0x28a5:16), 1
	ld	(0x11f4:16), 0
	call	BitMapOut_RenderDisplay
	ldb_d8	a, (0x1128)
	stb_d8	(0xfc5d), a
	ld	e, 72:opc
	ld	d, 3:opc
	ld	w, 8:opc
	call	SysEx_ApplyVoiceParam_49
	ldb_d8	a, (0x0d66)
	call	PortConfig_DataTable_A_Sub
	xor	wa, wa
	ld	(0x0d4f:16), wa
	ld	(0x0d51:16), wa
	stb_d8	(0x3673), a
	stb_d8	(0x0d67), a
	ld	(0x1108:16), wa
	stb_d8	(0x10f9), a
	stb_d8	(0x10fa), a
	res	3, (0x0d54:16)
	call	VoiceState_DataBlock2_Helper16
	call	ClockConfig_Handler_0_Tbl2_Helper
	ldw_d16	wa, (0xf1d0)
	ld	(0x0f58:16), wa
	call	PerfMode_Handler_EvtB_Helper2_Helper11
	pushw	wa
	xor	a, a
	call	Part_InitVoiceDefaults
	popw	wa
	or	(0x28b3:16), 16
	and	(0x28a7:16), 247
	and	(0x28a7:16), 251
	and	(0x0d53:16), 247
	ldb_d8	a, (0x0d65)
	cp	a, 3:i3
	jrl	nz, ClockConfig_Handler_0_Skip5
	call	ClockConfig_Handler_0_Tbl2_Helper2
	jp	ClockConfig_Handler_0_Tbl2_Return
ClockConfig_Handler_0_Skip5:
	cp	a, 0:i3
	jrl	nz, ClockConfig_Handler_0_Tbl2_Return
	call	SysInit_BytecodeBlock_Sub
ClockConfig_Handler_0_Tbl2_Return:
	ret
ClockConfig_Handler_0_Tbl2_Helper:
	cp	(0x28be:16), 255
	jrl	z, ClockConfig_Handler_0_Return2
	call	VoiceSlot_ComputeWordIndex
	sra	iz, 1
	push	xix
	ld	xix, 0xf1a0
	ld	(xix+iz), 0x0e
	pop	xix
ClockConfig_Handler_0_Return2:
	ret
SysEx_PeriodicDispatch:
	ld XIY,0x00000d69
	cp (XIY),0x18
	jrl nz, SysEx_CountdownCheck
	and (0xe31c:16), 0x6f
	pushw wa
	push XIY
	ld W, 0x68:opc
	call MIDI_SendSysExFromW
	pop XIY
	popw wa
	ld (0x7ea6:16), 0x0f
	xor WA,WA
	ld A, 0xee:opc
	call SoundCtrl_SendCommand
	jp SysEx_DecrementAndCheck
SysEx_CountdownCheck:
	cp (xiy), 0x0
	jrl z, SysEx_ControllerBitCheck

SysEx_DecrementAndCheck:
	decm8 1, (xiy)
	cp (xiy), 0x0
	jrl nz, SysEx_ControllerBitCheck
	call SysInit_SendAllNotesAndReset

SysEx_ControllerBitCheck:
	bit 3, (3411:16)
	jrl z, ControllerMode_UpdateFlags
	bit 0, (3924:16)
	jrl z, SysEx_ModeChangeCheck
	ld c, (3925:16)
	add c, 0x5
	ld xwa, (0x02749a:24)
	or xwa, (0x02749e:24)
	ld (4560:16), xwa
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (4560:16)
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jrl nc, SysEx_ModeChangeCheck
	and (3924:16), 254
	call VoiceCtrl_SendNoteOffSequence

SysEx_ModeChangeCheck:
	ld xiy, 0xd5e
	cp (xiy), 0x0
	jrl z, ControllerMode_UpdateFlags
	call SeqState_HasModeChanged
	cp hl, 0:i3
	jrl nz, ControllerMode_UpdateFlags
	decm8 1, (xiy)
	cp (xiy), 0x0
	jrl nz, ControllerMode_UpdateFlags

ControllerMode_UpdateFlags:
	cp (0x8c9a:16), 0x8a
	jrl nz, SysEx_FlagClearAndCompare
	cp (0x0d65:16), 0x03
	jrl nz, SysEx_FlagClearAndCompare
	or (0x0f56:16), 0x02
	jp SubCPU_CmdCountdownRet
SysEx_FlagClearAndCompare:
	and (3926:16), 253

	; cpdi8 (0x8d36), 129 (v7 patched)
	cp	(0x8c9a:16), 129
	; jrl z, SysEx_DecrementCounter (v7 displacement)
	jrl	z, SysEx_DecrementCounter
	; cpdi8 (0x8d36), 142 (v7 patched)
	cp	(0x8c9a:16), 142
	; jrl nz, SubCPU_CmdCountdownRet (v7 displacement)
	jrl	nz, SubCPU_CmdCountdownRet



SysEx_DecrementCounter:
	cp (3393:16), 0
	jrl z, SubCPU_CmdCountdownRet
	dec 1, (3393:16)

SubCPU_CmdCountdownRet:
	ret
SysEx_BytecodeDispatcher:
	xor	wa, wa
	ld	xiy, 3519
	cp	(xiy), a
	jrl	nz, SysEx_BytecodeDispatcher_Skip
	ld	xiy, 3520
	cp	(xiy), a
	jrl	nz, SysEx_BytecodeDispatcher_Skip2
	ld	xiy, 4360
	cp	(xiy), wa
	jrl	nz, SysEx_BytecodeDispatcher_Skip3
	jp	SysEx_BytecodeDispatcher_Return
SysEx_BytecodeDispatcher_Skip:
	call	SysEx_BytecodeDispatcher_Helper5
	call	SysEx_BytecodeDispatcher_Helper8
	xor	h, h
	push	xix
	ld	xix, SysInit_BytecodeBlock
	ld	w, (xix+hl)
	pop	xix
	or	w, 2
	push	xhl
	call	MIDI_SendSysExFromW
	pop	xhl
	push	xde
	ld	xde, SysEx_BytecodeDispatcher_Data
	ld	w, (xde+hl)
	pop	xde
	ld	(3425:16), w
	ld	(3432:16), 1
	call	SysEx_BytecodeDispatcher_Helper2
	push	xhl
	call	SNS_Init_Startup
	pop	xhl
	call	SysEx_BytecodeDispatcher_Helper3
	call	SysEx_BytecodeDispatcher_Helper3_Sub
	ld	(3434:16), 0
	call	MemConfig_Handler_5_Helper
	call	MemConfig_Handler_5_Code_Helper11
	ld	w, 0:opc
	jp	SysEx_BytecodeDispatcher_Join
SysEx_BytecodeDispatcher_Skip2:
	call	SysEx_BytecodeDispatcher_Helper5
	push	xiy
	call	Timer_ModeHandler_0_Helper2
	pop	xiy
	call	SysEx_BytecodeDispatcher_Helper8
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, MemoryConfig_Handler_Table
	ld	xhl, (xix+hl)
	pop	xix
	call (xhl)
	jp	SysEx_BytecodeDispatcher_Join
SysEx_BytecodeDispatcher_Skip3:
	call	SysEx_BytecodeDispatcher_Helper5
	call	SysEx_BytecodeDispatcher_Helper9
	call	SysEx_BytecodeDispatcher_Helper4
	call	SysEx_BytecodeDispatcher_Helper6
	call	SysEx_BytecodeDispatcher_Helper7
	cp	l, 2:i3
	jrl	z, SysEx_BytecodeDispatcher_Skip4
	cp	l, 3:i3
	jrl	z, SysEx_BytecodeDispatcher_Skip4
	cp	l, 10
	jrl	z, SysEx_BytecodeDispatcher_Skip4
	call	Timer_ModeHandler_0_Helper2
SysEx_BytecodeDispatcher_Skip4:
	call	SystemInit_Handler_Table_0x18
	ld	(3434:16), 0
	call	MemConfig_Handler_5_Helper
	call	MemConfig_Handler_5_Code_Helper11
SysEx_BytecodeDispatcher_Join:
	cp	w, 255
	jrl	nz, SysEx_BytecodeDispatcher_Skip5
	call	SysInit_SendAllNotesAndReset
	jp	SysEx_BytecodeDispatcher_Return
SysEx_BytecodeDispatcher_Skip5:
	call	AccPedal_CheckBitAndUpdate
	ld	a, (3420:16)
	cp	(3415:16), 48
	jrl	nz, SysEx_BytecodeDispatcher_Skip6
	or	a, 128
SysEx_BytecodeDispatcher_Skip6:
	ld	(13949:16), a
	call	PortConfig_Handler_0_Helper3
	call	Display_UpdateRegion3
SysEx_BytecodeDispatcher_Return:
	ret
	; Handler dispatch table, 24 B.  Read by SysEx_BytecodeDispatcher (0xEFAAB1): `ld xix, MemoryConfig_Handler_Table`
	; indexed with stride 4 (`sla hl, 2`)
	; 6 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
MemoryConfig_Handler_Table:
	.long	MemConfig_Handler_0
	.long	MemConfig_Handler_1
	.long	MemoryConfig_Handler_Table_Target2
	.long	MemConfig_Handler_3
	.long	MemConfig_Handler_4
	.long	MemConfig_Handler_5
SystemInit_Handler_Table_Helper:
	ld XIY,SysEx_BytecodeDispatcher_Tbl
	ld XIX,0x00000d8f
	ld A, 0xb0:opc
	ld (XIX),A
	ld a, (0x0d57:16)
	ldfr_lerp	xiy, 56
	lda	xiy, (xiy+hl)
	add	a, (xiy+2)
	ldto_lerp	xiy, 56
	ld	(xix+1), a
	ld	(xix+2), 72
	ld	a, 5:opc
	cp	hl, 48
	jrl	c, SysEx_BytecodeDispatcher_Skip7
	ld	a, 6:opc
SysEx_BytecodeDispatcher_Skip7:
	ld	(xix+3), a
	xor	w, w
	ld	a, (xiy+hl)
	bit	7, a
	jrl	z, SysEx_BytecodeDispatcher_Skip8
	ormi8	(xix), 1
	ld	(xix+4), w
	jp	MemoryConfig_Handler_Table_Join
SysEx_BytecodeDispatcher_Skip8:
	ld	(xix+4), a
MemoryConfig_Handler_Table_Join:
	ldfr_lerp	xiy, 56
	lda	xiy, (xiy+hl)
	ld	a, (xiy+1)
	ldto_lerp	xiy, 56
	bit	7, a
	jrl	z, SysEx_BytecodeDispatcher_Skip9
	ormi8	(xix), 2
	ld	(xix+5), w
	jp	MemoryConfig_Handler_Table_Join2
SysEx_BytecodeDispatcher_Skip9:
	ld	(xix+5), a
MemoryConfig_Handler_Table_Join2:
	push	xiy
	ld	w, 6:opc
	ld	xiy, 0x0d8f
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	DisplayMode_Handler_3_Helper16
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	pop	xiy
	ldfr_lerp	xiy, 56
	lda	xiy, (xiy+hl)
	ld	w, (xiy+3)
	ldto_lerp	xiy, 56
	ret
	; Byte data, 97 B.  Read by SysEx_BytecodeDispatcher (0xEFAAB1): `ld XIY,SysEx_BytecodeDispatcher_Tbl`
	; reader SysEx_BytecodeDispatcher: `ld XIY,SysEx_BytecodeDispatcher_Tbl` then `lda_rr xiy, xiy, hl`
SysEx_BytecodeDispatcher_Tbl:
	.byte	0x04, 0x04, 0x00, 0x03, 0x00, 0x04, 0x00, 0x00, 0x08, 0x08, 0x00, 0x03, 0x00, 0x08, 0x00, 0x00
	.byte	0x10, 0x10, 0x00, 0x05, 0x00, 0x10, 0x2f, 0x02, 0x20, 0x20, 0x00, 0x05, 0x00, 0x20, 0x2f, 0x02
	.byte	0x40, 0x40, 0x00, 0x04, 0x00, 0x40, 0x2f, 0x01, 0x80, 0x80, 0x00, 0x04, 0x00, 0x80, 0x2f, 0x01
	.byte	0x04, 0x04, 0x00, 0x03, 0x00, 0x04, 0x00, 0x00, 0x08, 0x08, 0x00, 0x03, 0x00, 0x08, 0x00, 0x00
	.byte	0x10, 0x10, 0x00, 0x05, 0x00, 0x10, 0x2f, 0x02, 0x20, 0x20, 0x00, 0x05, 0x00, 0x20, 0x2f, 0x02
	.byte	0x40, 0x40, 0x00, 0x04, 0x00, 0x40, 0x2f, 0x01, 0x80, 0x80, 0x00, 0x04, 0x00, 0x80, 0x2f, 0x01
	.byte	0x0e
	; Entry 2 of MemoryConfig_Handler_Table (a code pointer the table holds).
MemoryConfig_Handler_Table_Target2:
	ld	xhl, 0x10f9
	bitm	2, (xhl)
	jrl	z, MemoryConfig_Handler_Table_Target2_Skip
	resm	2, (xhl)
	jp	MemoryConfig_Handler_Table_Target2_Join
MemoryConfig_Handler_Table_Target2_Skip:
	ld	w, 114:opc
	call	MIDI_SendSysExFromW
	set	1, (0x10f9:16)
MemoryConfig_Handler_Table_Target2_Sub:
	call	Timer_ModeHandler_0_Helper2
	ld	xiz, 0x0d53
	andmi8	(xiz), 191
	call	MemConfig_VoiceSlotLookup
	call	MemConfig_Handler_4_Helper5_Helper
MemoryConfig_Handler_Table_Target2_Join:
	cp	(0x0d65:16), 0
	jrl	nz, MemoryConfig_Handler_Table_Target2_Entry
	ld	(0x0d6a:16), 0
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jr	nz, MemoryConfig_Handler_Table_Target2_Skip2
	call	MemConfig_Handler_5_Code_Helper10
MemoryConfig_Handler_Table_Target2_Skip2:
	call	MemConfig_Handler_5_Helper
	call	DMA_FlagCheckWithCalls
	call	MemConfig_Handler_5_Code_Helper11
MemoryConfig_Handler_Table_Target2_Entry:
	ld	w, 0:opc
	ret
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
	ld	(xix+iz), wa
	pop xix

MemConfig_VoiceSlotCompare:
	srl xiz, 1
	push xix
	ld xix, 0xcbe
	ld	(xix+iz), 0x05
	pop xix
	jp MemConfig_VoiceSlotRet

MemConfig_VoiceSlotSkip:
	call VoiceSlot_ComputeWordIndex
	jp MemConfig_VoiceSlotCompare

MemConfig_VoiceSlotRet:
	ret

MemConfig_Handler_0:
	ld XHL,0x00000d54
	bit 3,(XHL)
	jrl z, .Lc_efad7e
	res 3,(XHL)
	call ScoopDisp_DispatchTable_Small_Target11_Helper
	jp MemConfig_Handler_0_Return
.Lc_efad7e:
MemConfig_Handler_0_Skip3:
	call VoiceCtrl_BytecodeHandler
	cp B,0x16
	jrl z, .Lc_efadc5
	cp B,0x17
	jrl z, .Lc_efadc5
MemConfig_Handler_0_Join:
	call VoiceSlot_FlagCheck
	cp W,0xff
	jrl z, .Lc_efadba
	xor A,A
	call VoiceSlot_SaveState
	ld W, 0x81:opc
	call MemConfig_Handler_5_Code_Helper13
	ld de, 1:i3
	call Timer_ModeHandler_0_Helper6
	ld W, 0x82:opc
	call MemConfig_Handler_5_Code_Helper13
	xor A,A
	call VoiceSlot_RestoreState
	call MemConfig_Handler_0_Helper
.Lc_efadba:
	ld W, 0xff:opc
	or (0x8cec:16), 0x01
	jp MemConfig_Handler_0_Return
.Lc_efadc5:
MemConfig_Handler_0_Skip2:
	call VoiceSlot_LoadAndDispatch
	jp MemConfig_Handler_0_Join
MemConfig_Handler_0_Return:
	ret
MemConfig_Handler_1:
	res	7, (0x0d54:16)
	call	VoiceCtrl_BytecodeHandler
	cp	b, 22
	jrl	z, MemConfig_Handler_1_Skip4
	cp	b, 23
	jrl	z, MemConfig_Handler_1_Skip4
MemConfig_Handler_1_Join:
	xor	a, a
	call	VoiceSlot_SaveState
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, MemConfig_Handler_1_Skip2
MemConfig_Handler_1_Loop:
	call	VoiceSlot_CompareAndBranch
	cp	w, 255
	jrl	z, MemConfig_Handler_1_Skip2
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, MemConfig_Handler_1_Code_Skip
	and	a, 240
	cp	a, 144
	jrl	z, MemConfig_Handler_1_Code_Skip
	cp	a, 176
	jrl	nz, MemConfig_Handler_1_Loop
MemConfig_Handler_1_Code_Skip:
	pushw	wa
	xor	a, a
	call	VoiceSlot_RestoreState
	popw	wa
	cp	a, 129
	jrl	nz, MemConfig_Handler_1_Skip3
	ld	w, 132:opc
MemConfig_Handler_1_Join2:
	call	MemConfig_Handler_5_Code_Helper13
	ld	de, 1:i3
	call	Timer_ModeHandler_0_Helper6
	ld	w, 132:opc
	call	MemConfig_Handler_5_Code_Helper13
	xor	a, a
	call	VoiceSlot_RestoreState
	call	MemConfig_Handler_0_Helper
MemConfig_Handler_1_Skip2:
	ld	w, 255:opc
	or	(0x8cec:16), 1
	jp	MemConfig_Handler_1_Return
MemConfig_Handler_1_Skip3:
	ld	w, 129:opc
	jp	MemConfig_Handler_1_Join2
MemConfig_Handler_1_Skip4:
	call	VoiceSlot_LoadAndDispatch
	jp	MemConfig_Handler_1_Join
MemConfig_Handler_1_Return:
	ret
MemConfig_Handler_0_Helper:
	call VoiceSlot_ComputeWordIndex
	push XIX
	ld XIX,0x00000c9e
	ld	iy, (xix+iz)
	pop XIX
	cp IY,0xffff
	jrl nz, .Lc_efae74
	jp MemConfig_Handler_1_Return2
.Lc_efae74:
MemConfig_Handler_1_Code_Skip3:
	srl IZ, 0x01
	push XIX
	ld XIX,0x00000cbe
	ld	a, (xix+iz)
	pop XIX
	xor W,W
	inc 1,WA
	cp WA,0x00ff
	jrl ule, .Lc_efaee4
	push XIX
	ld XIX,0x0000f218
	ld	(xix+iz), 0x05
	sla IZ, 0x01
	ld XIX,0x00000c9e
	ld	iy, (xix+iz)
	pop XIX
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (0x10fd:16)
	ld IY,(XHL+0x03)
	push XIX
	ld XIX,0x0000f1f8
	ld	(xix+iz), iy
	pop XIX
	cp IY,0xffff
	jrl z, .Lc_efaf0b
MemConfig_Handler_1_Join3:
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (0x10fd:16)
	ld IY,(XHL+0x03)
	cp IY,0xffff
	jrl z, .Lc_efaf0b
	ld wa, (0x286d:16)
	call MemConfig_Handler_1_Helper3
	jp MemConfig_Handler_1_Return2
.Lc_efaee4:
	push XIX
	ld XIX,0x0000f218
	ld	(xix+iz), a
	sla IZ, 0x01
	ld XIX,0x00000c9e
	ld	iy, (xix+iz)
	ld XIX,0x0000f1f8
	ld	(xix+iz), iy
	pop XIX
	jp MemConfig_Handler_1_Join3
.Lc_efaf0b:
MemConfig_Handler_1_Return2:
	ret
VoiceState_DataBlock2_Helper6:
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, VoiceState_DataBlock2_Helper6_Skip2
	cp	a, 132
	jrl	z, VoiceState_DataBlock2_Helper6_Skip2
	ld	a, 3:opc
	call	VoiceSlot_SaveState
	ldb_d8	a, (0x0d5d)
	sub	a, (0x0d5c:16)
	call	MemConfig_Handler_1_Helper
	ld	a, 4:opc
	call	VoiceSlot_SaveState
	ld	a, 3:opc
	call	VoiceSlot_RestoreState
VoiceState_DataBlock2_Helper6_Loop:
	call	MemConfig_Handler_4_Helper2
	cp	(0x0d6a:16), 0
	jrl	nz, VoiceState_DataBlock2_Helper6_Skip
	ld	a, 4:opc
	call	MemConfig_Handler_1_Helper4
	cp	w, 1:i3
	jrl	z, VoiceState_DataBlock2_Helper6_Skip
	cp	w, 2:i3
	jrl	nz, VoiceState_DataBlock2_Helper6_Loop
	bit	7, (0x0d53:16)
	jrl	nz, VoiceState_DataBlock2_Helper6_Skip
	ld	a, 4:opc
	call	VoiceSlot_RestoreState
VoiceState_DataBlock2_Helper6_Skip:
	call	AccPedal_CheckBitAndUpdate
	ld	(0x0d6a:16), 0
	call	MemConfig_Handler_5_Helper
	call	PortConfig_Handler_0_Helper3
	call	PortConfig_Handler_0_Helper5
	call	MemConfig_Handler_5_Code_Helper11
VoiceState_DataBlock2_Helper6_Skip2:
	ld	(0x0d6a:16), 0
	call	AccPedal_CheckBitAndUpdate
	xor	a, a
	stb_d8	(0x0d57), a
	ldb_d8	a, (0x0d5c)
	stb_d8	(0x367d), a
	ret
MemConfig_Handler_1_Helper:
	stb_d8	(0x0dfe), a
VoiceState_DataBlock2_Helper6_Loop2:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceState_DataBlock2_Helper6_Skip3
	incw	1, (0x0d58:16)
	dec	1, (0x0dfe:16)
VoiceState_DataBlock2_Helper6_Skip3:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Helper6_Return
	cp	(0x0dfe:16), 0
	jrl	nz, VoiceState_DataBlock2_Helper6_Loop2
VoiceState_DataBlock2_Helper6_Return:
	ret
ScoopDisp_FlagSetAndDispatch_Helper:
	ld	a, 3:opc
	call	VoiceSlot_SaveState
	ldb_d8	a, (0x0d5c)
	add	a, (0x0d5d:16)
	call	MemConfig_Handler_1_Helper2
	call	AccPedal_CheckBitAndUpdate
	cp	(0x0d5c:16), 0
	jrl	z, VoiceState_DataBlock2_Helper6_Skip4
	ldb_d8	a, (0x0d5c)
	call	MemConfig_Handler_1_Helper2
VoiceState_DataBlock2_Helper6_Skip4:
	ld	a, 4:opc
	call	VoiceSlot_SaveState
	call	MemConfig_Handler_4_Helper4
	ld	a, 5:opc
	call	VoiceSlot_SaveState
VoiceState_DataBlock2_Helper6_Loop3:
	ld	a, 6:opc
	call	VoiceSlot_SaveState
	call	MemConfig_Handler_4_Helper2
	cp	(0x0d6a:16), 0
	jrl	nz, MemConfig_Handler_1_Skip9
	ld	a, 4:opc
	call	MemConfig_Handler_1_Helper4
	cp	w, 1:i3
	jrl	z, VoiceState_DataBlock2_Helper6_Skip5
	cp	w, 2:i3
	jrl	nz, VoiceState_DataBlock2_Helper6_Loop3
	bit	7, (0x0d53:16)
	jrl	z, VoiceState_DataBlock2_Helper6_Skip5
	ld	a, 6:opc
	jp	MemConfig_Handler_1_Join4
VoiceState_DataBlock2_Helper6_Skip5:
	ld	a, 4:opc
MemConfig_Handler_1_Join4:
	call	VoiceSlot_RestoreState
MemConfig_Handler_1_Skip9:
	call	AccPedal_CheckBitAndUpdate
	call	MemConfig_Handler_4_Helper6
	cp	w, 255
	jrl	z, MemConfig_Handler_1_Skip10
	xor	a, a
	stb_d8	(0x0d57), a
	ldb_d8	a, (0x0d5c)
	stb_d8	(0x367d), a
MemConfig_Handler_1_Skip10:
	call	MemConfig_Handler_5_Helper
	call	PortConfig_Handler_0_Helper3
	call	PortConfig_Handler_0_Helper5
	call	MemConfig_Handler_5_Code_Helper11
	xor	a, a
	stb_d8	(0x0d57), a
	ldb_d8	a, (0x0d5c)
	stb_d8	(0x367d), a
	ret
MemConfig_Handler_1_Helper2:
	stb_d8	(0x0dfe), a
VoiceState_DataBlock2_Helper6_Loop4:
	call	VoiceSlot_CompareAndBranch
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Helper6_Return2
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceState_DataBlock2_Helper6_Loop4
	ld	xiy, 0x0dfe
	decm8	1, (xiy)
	cp	(xiy), 0
	jrl	nz, VoiceState_DataBlock2_Helper6_Loop4
MemConfig_Handler_1_Loop4:
	ld	a, 6:opc
	call	VoiceSlot_SaveState
	call	Timer_ParamCompareAlt_Helper5
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Helper6_Return2
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, MemConfig_Handler_1_Loop4
	ld	a, 6:opc
	call	VoiceSlot_RestoreState
VoiceState_DataBlock2_Helper6_Return2:
	ret
MemConfig_Handler_3:
	call	MemConfig_Handler_4_Helper
	call	MemConfig_Handler_4_Helper2
	call	MemConfig_Handler_3_Helper3
	call	MemConfig_Handler_4_Helper3
	call	MemConfig_Handler_5_Code_Helper11
	; llvm-mc cannot spell this byte
	cp	(0x0d6a:16), 0
	; -> 0xEFB0CD
	jrl	z, MemConfig_Handler_3_Next	; -> 0xEFB0C5
MemConfig_Handler_3_Next:
	ld	w, 0:opc
	ret
MemConfig_Handler_4_Helper:
	pushw	wa
	ld	wa, (13950:16)
	ld	(3816:16), wa
	ld	wa, (3416:16)
	ld	(3818:16), wa
	ld	a, (3415:16)
	ld	(3820:16), a
	ld	a, (3420:16)
	ld	(3821:16), a
	popw	wa
	ret
MemConfig_Handler_3_Helper3:
	call	AccPedal_CheckBitAndUpdate
	ld	wa, (3816:16)
	cp	wa, (13950:16)
	jrl	nz, MemConfig_Handler_3_Loop	; -> 0xEFB143
	ld	wa, (3818:16)
	cp	wa, (3416:16)
	jrl	nz, MemConfig_Handler_3_Skip	; -> 0xEFB11D
	ld	a, (3820:16)
	cp	a, (3415:16)
	jrl	z, MemConfig_Handler_4_Helper_Return	; -> 0xEFB154
	call	MemConfig_Handler_4_Helper_Helper2
	cp	w, 0:i3
	jrl	z, MemConfig_Handler_4_Helper_Return	; -> 0xEFB154
	jp	MemConfig_Handler_3_Skip2
	; llvm-mc cannot spell this byte
MemConfig_Handler_3_Skip:
	cp	(0x0d5d:16), 4
	jrl	ule, MemConfig_Handler_3_Skip2	; -> 0xEFB137
	ld	a, (3821:16)
	ld	w, (3420:16)
	cp	a, 4:i3
	jrl	ule, MemConfig_Handler_4_Helper_Skip2	; -> 0xEFB14B
	cp	w, 4:i3
	jrl	c, MemConfig_Handler_3_Loop	; -> 0xEFB143
MemConfig_Handler_3_Skip2:
	call	MemConfig_Handler_4_Helper_Helper
	call	Display_UpdateRegion2
	jp	MemConfig_Handler_4_Helper_Return
MemConfig_Handler_3_Loop:
	call	MemConfig_Handler_5_Helper
	jp	MemConfig_Handler_4_Helper_Return
MemConfig_Handler_4_Helper_Skip2:
	cp	w, 3:i3
	jrl	ugt, MemConfig_Handler_3_Loop	; -> 0xEFB143
	jp	MemConfig_Handler_3_Skip2
MemConfig_Handler_4_Helper_Return:
	ret
MemConfig_Handler_4_Helper2:
	ld	(13964:16), 0
	ld	a, (3415:16)
	ld	(3521:16), a
	call	SndDispatch_ProcessCommand_0xF
	xor	w, w
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_JumpTable_Main
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
	ret
	; Handler dispatch table, 44 B.  Read by MemConfig_Handler_3 (0xEFB0A9): `ld xix, SndDispatch_JumpTable_Main`
	; indexed with stride 4 (`sla wa, 2`), index from `ld hl, wa`
	; 11 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
SndDispatch_JumpTable_Main:
	.long	DefaultHandler_Ret
	.long	SndDispatch_Handler_1
	.long	SndDispatch_Handler_2
	.long	SndDispatch_TableEntryBegin
	.long	SndDispatch_ShortHandler
	.long	SndDispatch_TableEntryBegin
	.long	SndDispatch_TableEntryBegin
	.long	SndDispatch_Handler_3
	.long	SndDispatch_ShortHandler
	.long	SndDispatch_Handler_3
	.long	SndDispatch_Handler_4
SndDispatch_Handler_1:
	call	SndDispatch_Handler_1_Helper2
	call	SndDispatch_Handler_1_Helper
	cp	a, 0:i3
	jrl	z, SndDispatch_Handler_1_Return
	dec	1, a
	xor	w, w
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_SubTable_1
	ld	xhl, (xix+hl)
	pop xix
	call	(xhl)
SndDispatch_Handler_1_Return:
	ret
	; Handler dispatch table, 24 B.  Read by SndDispatch_Handler_1 (0xEFB1A8): `ld xix, SndDispatch_SubTable_1`
	; indexed with stride 4 (`sla wa, 2`), index from `ld hl, wa`
	; 6 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
SndDispatch_SubTable_1:
	.long	SndDispatch_InitHandler
	.long	SndDispatch_ProcessCommand
	.long	SndDispatch_ProcessCommand
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
SndDispatch_Handler_2:
	call	SndDispatch_Handler_1_Helper2
	call	SndDispatch_Handler_1_Helper
	cp	a, 0:i3
	jrl	z, SndDispatch_Handler_2_Return
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_SubTable_2
	ld	xhl, (xix+hl)
	pop xix
	call	(xhl)
SndDispatch_Handler_2_Return:
	ret
	; Handler dispatch table, 24 B.  Read by SndDispatch_Handler_2 (0xEFB1E5): `ld xix, SndDispatch_SubTable_2`
	; indexed with stride 4 (`sla wa, 2`), index from `ld hl, wa`
	; 6 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
SndDispatch_SubTable_2:
	.long	SndDispatch_InitHandler
	.long	SndDispatch_ProcessCommand
	.long	SndDispatch_ProcessCommand
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
SndDispatch_TableEntryBegin:
	call	SndDispatch_Handler_1_Helper2
	call	SndDispatch_Handler_1_Helper
	cp	a, 0:i3
	jrl	z, SndDispatch_TableEntryBegin_Return
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_BytecodeString
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
SndDispatch_TableEntryBegin_Return:
	ret
	; Handler dispatch table, 24 B.  Read by SndDispatch_TableEntryBegin (0xEFB222): `ld xix, SndDispatch_BytecodeString`
	; indexed with stride 4 (`sla wa, 2`), index from `ld hl, wa`
	; 6 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
SndDispatch_BytecodeString:
	.long	DefaultHandler_Ret
SndDispatch_SubTable_3:
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SndDispatch_ProcessCommand
	.long	SndDispatch_ProcessCommand
	.long	DefaultHandler_Ret
SndDispatch_ShortHandler:
	call	SndDispatch_ProcessCommand
	ret
SndDispatch_Handler_3:
	call	SndDispatch_Handler_1_Helper2
	call	SndDispatch_Handler_1_Helper
	cp	a, 0:i3
	jrl	z, SndDispatch_Handler_3_Return
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_SubTable_4
	ld	xhl, (xix+hl)
	pop xix
	call	(xhl)
SndDispatch_Handler_3_Return:
	ret
	; Handler dispatch table, 24 B.  Read by SndDispatch_Handler_3 (0xEFB264): `ld xix, SndDispatch_SubTable_4`
	; indexed with stride 4 (`sla wa, 2`), index from `ld hl, wa`
	; 6 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
SndDispatch_SubTable_4:
	.long	SndDispatch_CallAndInit
	.long	SndDispatch_InitHandler
	.long	SndDispatch_InitHandler
	.long	SndDispatch_ProcessCommand
	.long	SndDispatch_InitHandler
	.long	DefaultHandler_Ret
SndDispatch_Handler_4:
	call	SndDispatch_Handler_1_Helper2
	call	SndDispatch_Handler_1_Helper
	cp	a, 0:i3
	jrl	z, SndDispatch_Handler_4_Return
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_Handler_4_DispatchTbl
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
SndDispatch_Handler_4_Return:
	ret
	; Handler dispatch table, 24 B.  Read by SndDispatch_Handler_4 (0xEFB2A1): `ld xix, SndDispatch_Handler_4_DispatchTbl`
	; indexed with stride 4 (`sla wa, 2`), index from `ld hl, wa`
	; 6 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
SndDispatch_Handler_4_DispatchTbl:
	.long	SndDispatch_CallAndInit
SndDispatch_SubTable_5:
	.long	SndDispatch_InitHandler
	.long	SndDispatch_SetFlag30
	.long	SndDispatch_ProcessCommand
	.long	SndDispatch_SetFlag30
	.long	DefaultHandler_Ret
SndDispatch_CallAndInit:
	call	VoiceSlot_SubrRetZ
	call	SndDispatch_InitHandler
	ret
SndDispatch_InitHandler:
	cp	(0x0d6a:16), 0
	jrl	nz, SndDispatch_InitHandler_Return
	ld	(3415:16), 0
SndDispatch_InitHandler_Return:
	ret
SndDispatch_SetFlag30:
	ld	(3415:16), 48
	ret
SndDispatch_ProcessCommand:
	call VoiceSlot_FlagCheck
	bit 0x07,A
	jrl nz, .Lc_efb309
	ld (0x0d57:16), a
.Lc_efb309:
SndDispatch_ProcessCommand_Return:
	ret
SndDispatch_ProcessCommand_0xF:
	call	VoiceSlot_ReadCurrentParams
	ld	xiy, 3415
	xor	w, w
	cp	a, 129
	jrl	nz, SndDispatch_ProcessCommand_Skip2
	cp	(xiy), w
	jrl	nz, SndDispatch_ProcessCommand_Skip
	ld	a, 1:opc
	jp	SndDispatch_ProcessCommand_0xA4
SndDispatch_ProcessCommand_Skip:
	ld	a, 2:opc
	jp	SndDispatch_ProcessCommand_0xA4
SndDispatch_ProcessCommand_Skip2:
	push	xiy
	pushw	wa
	call	VoiceSlot_FlagCheck
	ld	(3526:16), a
	popw	wa
	pop	xiy
	and	a, 240
	cp	a, 144
	jrl	nz, SndDispatch_ProcessCommand_Skip6
	cp	(xiy), w
	jrl	nz, SndDispatch_ProcessCommand_Skip4
	cp	(3526:16), w
	jrl	nz, SndDispatch_ProcessCommand_Skip3
	ld	a, 3:opc
	jp	SndDispatch_ProcessCommand_0xA4
SndDispatch_ProcessCommand_Skip3:
	ld	a, 4:opc
	jp	SndDispatch_ProcessCommand_0xA4
SndDispatch_ProcessCommand_Skip4:
	cp	(3526:16), w
	jrl	nz, SndDispatch_ProcessCommand_Skip5
	ld	a, 5:opc
	jp	SndDispatch_ProcessCommand_0xA4
SndDispatch_ProcessCommand_Skip5:
	ld	a, 6:opc
	jp	SndDispatch_ProcessCommand_0xA4
SndDispatch_ProcessCommand_Skip6:
	cp	a, 176
	jrl	nz, SndDispatch_ProcessCommand_Skip10
	cp	(xiy), w
	jrl	nz, SndDispatch_ProcessCommand_Skip8
	cp	(3526:16), w
	jrl	nz, SndDispatch_ProcessCommand_Skip7
	ld	a, 7:opc
	jp	SndDispatch_ProcessCommand_0xA4
SndDispatch_ProcessCommand_Skip7:
	ld	a, 8:opc
	jp	SndDispatch_ProcessCommand_0xA4
SndDispatch_ProcessCommand_Skip8:
	cp	(3526:16), w
	jrl	nz, SndDispatch_ProcessCommand_Skip9
	ld	a, 9:opc
	jp	SndDispatch_ProcessCommand_0xA4
SndDispatch_ProcessCommand_Skip9:
	ld	a, 10:opc
	jp	SndDispatch_ProcessCommand_0xA4
SndDispatch_ProcessCommand_Skip10:
	xor	a, a
SndDispatch_ProcessCommand_0xA4:
	ret
SndDispatch_Handler_1_Helper:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	nz, SndDispatch_ProcessCommand_Skip11
	ld	a, 6:opc
	jp	SndDispatch_ProcessCommand_Return2
SndDispatch_ProcessCommand_Skip11:
	cp	a, 129
	jrl	nz, SndDispatch_ProcessCommand_Skip12
	ld	a, 1:opc
	jp	SndDispatch_ProcessCommand_Return2
SndDispatch_ProcessCommand_Skip12:
	call	VoiceSlot_FlagCheck
	ld	(3526:16), a
	ld	xiy, 3526
	ld	xix, 3580
	xor	a, a
	cp	(xix), a
	jrl	nz, SndDispatch_ProcessCommand_Skip14
	cp	(xiy), a
	jrl	nz, SndDispatch_ProcessCommand_Skip13
	ld	a, 4:opc
	jp	SndDispatch_ProcessCommand_Return2
SndDispatch_ProcessCommand_Skip13:
	ld	a, 5:opc
	jp	SndDispatch_ProcessCommand_Return2
SndDispatch_ProcessCommand_Skip14:
	cp	(xiy), a
	jrl	nz, SndDispatch_ProcessCommand_Skip15
	ld	a, 2:opc
	jp	SndDispatch_ProcessCommand_Return2
SndDispatch_ProcessCommand_Skip15:
	ld	a, 3:opc
SndDispatch_ProcessCommand_Return2:
	ret
SndDispatch_Handler_1_Helper2:
	xor	a, a
	ld	(3580:16), a
	ld	(3581:16), a
	ld	(3434:16), a
	and	(0x0d53:16), 127
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, SndDispatch_ProcessCommand_Skip19
	call	VoiceSlot_ReadCurrentParams
	ld	(3581:16), a
	cp	a, 129
	jrl	nz, SndDispatch_ProcessCommand_Loop
	incw	1, (3416:16)
	ld	(3580:16), 1
SndDispatch_ProcessCommand_Loop:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, SndDispatch_ProcessCommand_Skip16
	call	VoiceSlot_DispatchRet
	jp	SndDispatch_ProcessCommand_Join
SndDispatch_ProcessCommand_Skip16:
	call	VoiceSlot_LoadAndDispatch
SndDispatch_ProcessCommand_Join:
	cp	w, 255
	jrl	z, SndDispatch_ProcessCommand_Return3
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	z, SndDispatch_ProcessCommand_Skip20
	cp	a, 129
	jrl	z, SndDispatch_ProcessCommand_Skip18
SndDispatch_ProcessCommand_Loop2:
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, SndDispatch_ProcessCommand_Skip19
	cp	a, 132
	jrl	z, SndDispatch_ProcessCommand_Skip19
	cp	a, 47
	jrl	z, SndDispatch_ProcessCommand_Skip17
	cp	a, 95
	jrl	nz, SndDispatch_ProcessCommand_Return3
SndDispatch_ProcessCommand_Skip17:
	call	VoiceSlot_LoadAndDispatch
	cp	w, 255
	jrl	z, SndDispatch_ProcessCommand_Return3
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	z, SndDispatch_ProcessCommand_Return3
	cp	a, 129
	jrl	nz, SndDispatch_ProcessCommand_Loop2
SndDispatch_ProcessCommand_Skip18:
	ld	(3580:16), 1
	cp	(3581:16), 129
	jrl	z, SndDispatch_ProcessCommand_Loop
	jp	SndDispatch_ProcessCommand_Loop2
	jp	SndDispatch_ProcessCommand_Return3
SndDispatch_ProcessCommand_Skip19:
	ld	(3434:16), 255
	jp	SndDispatch_ProcessCommand_Return3
SndDispatch_ProcessCommand_Skip20:
	cp	(3580:16), 0
	jrl	nz, SndDispatch_ProcessCommand_Return3
	ld	a, (3581:16)
	and	a, 240
	cp	a, 176
	jrl	z, SndDispatch_ProcessCommand_Return3
	call	SndDispatch_ProcessCommand_Helper
	call	SndDispatch_ProcessCommand_Helper2
	call	VoiceSlot_FlagCheck
	ld	(3526:16), a
SndDispatch_ProcessCommand_Loop3:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, SndDispatch_ProcessCommand_Return3
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	nz, SndDispatch_ProcessCommand_Skip21
	call	VoiceSlot_FlagCheck
	cp	a, (3526:16)
	jrl	z, SndDispatch_ProcessCommand_Loop3
	ld	(3415:16), 0
	jp	SndDispatch_ProcessCommand_Return3
SndDispatch_ProcessCommand_Skip21:
	call	VoiceSlot_FlagCheck
	cp	a, 47
	jrl	z, SndDispatch_ProcessCommand_Loop3
	cp	a, 95
	jrl	z, SndDispatch_ProcessCommand_Loop3
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, SndDispatch_ProcessCommand_Return3
	or	(0x0d53:16), 128
	ld	(3580:16), 1
	ld	a, (3579:16)
	exts	wa
	add (3416:16), wa
	ld	de, wa
	call	Timer_ModeHandler_0_Helper6
	call	VoiceSlot_ReadCurrentParams
	cp	a, 130
	jrl	z, SndDispatch_ProcessCommand_Skip23
	and	a, 240
	cp	a, 144
	jrl	z, SndDispatch_ProcessCommand_Return3
	cp	a, 176
	jrl	z, SndDispatch_ProcessCommand_Return3
	bit	7, a
	jrl	nz, SndDispatch_ProcessCommand_Skip22
	call	VoiceSlot_LoadAndDispatch
SndDispatch_ProcessCommand_Skip22:
	jp	SndDispatch_ProcessCommand_Return3
SndDispatch_ProcessCommand_Skip23:
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	call	MemConfig_Handler_5_Code_Helper12
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
SndDispatch_ProcessCommand_Return3:
	ret
PortConfig_Handler_0_Helper5:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jr	nz, SndDispatch_ProcessCommand_Skip24
	call	MemConfig_Handler_5_Code_Helper10
SndDispatch_ProcessCommand_Skip24:
	call	DMA_FlagCheckWithCalls
	ret
MemConfig_Handler_4_Helper3:
	call	DMA_FlagCheckWithCalls
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	nz, SndDispatch_ProcessCommand_Return4
	call	Interrupt_SetFlagBytecode
SndDispatch_ProcessCommand_Return4:
	ret
MemConfig_Handler_5_Code_Helper11:
	call	Display_UpdateRegion0
	call	Display_UpdateRegion1
	call	Display_UpdateRegion6
	call	Display_UpdateRegion3
	call	MemConfig_Handler_4_Helper_Helper
	call	Display_UpdateRegion2
	ret
SndDispatch_ProcessCommand_Helper:
	xor	a, a
	call	VoiceSlot_SaveState
	ld	de, 4:i3
	call	Timer_ModeHandler_0_Helper6
	call	VoiceSlot_FinalRetZ
	ld	(3575:16), a
	call	VoiceSlot_ReadCurrentParams
	ld	(3576:16), a
	xor	a, a
	call	VoiceSlot_RestoreState
	ret
SndDispatch_ProcessCommand_Helper2:
	ld	a, (3576:16)
	ld	(3579:16), a
	ld	a, (3521:16)
	add	a, (3575:16)
	cp	a, 96
	jrl	c, SndDispatch_ProcessCommand_Skip25
	inc	1, (3579:16)
	sub	a, 96
SndDispatch_ProcessCommand_Skip25:
	ld	(3415:16), a
	ret
MemConfig_Handler_4:
	ld	xhl, 4345
	bitm	1, (xhl)
	jrl	z, MemConfig_Handler_4_Skip
	resm	1, (xhl)
	call	MemConfig_Handler_4_Helper7
	set	2, (0x10f9:16)
	jp	MemConfig_Handler_4_Return
MemConfig_Handler_4_Skip:
	call	MemConfig_Handler_4_Helper
	call	MemConfig_Handler_4_Helper4
	call	MemConfig_Handler_5_Helper
	call	MemConfig_Handler_4_Helper3
	call	MemConfig_Handler_5_Code_Helper11
	ld	w, 0:opc
MemConfig_Handler_4_Return:
	ret
MemConfig_Handler_4_Helper4:
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	call	MemConfig_Handler_4_Helper6
	cp	w, 0:i3
	jrl	z, MemConfig_Handler_4_Skip3
	ld	a, (3415:16)
	ld	(3659:16), a
	call	MemConfig_Handler_4_Helper5
	call	MemConfig_Handler_4_Helper5
	ld	(3415:16), 0
MemConfig_Handler_4_Loop:
	ld	a, 2:opc
	call	VoiceSlot_SaveState
	call	MemConfig_Handler_4_Helper2
	ld	a, 1:opc
	call	VoiceState_DataBlock2
	cp	w, 1:i3
	jrl	z, MemConfig_Handler_4_Skip2
	cp	w, 2:i3
	jrl	nz, MemConfig_Handler_4_Loop
	jp	MemConfig_Handler_4_Join
MemConfig_Handler_4_Skip2:
	ld	a, (3659:16)
	cp	a, (3415:16)
	jrl	nz, MemConfig_Handler_4_Return2
MemConfig_Handler_4_Join:
	ld	a, 2:opc
	call	VoiceState_DataBlock1
	jp	MemConfig_Handler_4_Return2
MemConfig_Handler_4_Skip3:
	ld	(3415:16), 0
	ld	(3434:16), 0
	jp	MemConfig_Handler_4_Return2
MemConfig_Handler_4_Return2:
	ret
MemConfig_Handler_4_Helper5:
	ld	(3434:16), 0
	call	VoiceSlot_CompareAndBranch
	cp	w, 255
	jrl	z, MemConfig_Handler_4_Skip9
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	z, MemConfig_Handler_4_Skip5
	cp	a, 129
	jrl	z, MemConfig_Handler_4_Helper5
	call	VoiceSlot_FlagCheck
	cp	a, 47
	jrl	z, MemConfig_Handler_4_Skip4
	cp	a, 95
	jrl	nz, MemConfig_Handler_4_Join3
MemConfig_Handler_4_Skip4:
	call	VoiceSlot_CompareAndBranch
	cp	w, 255
	jrl	z, MemConfig_Handler_4_Skip9
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	z, MemConfig_Handler_4_Skip5
	cp	a, 129
	jrl	z, MemConfig_Handler_4_Helper5
	call	VoiceSlot_FlagCheck
	cp	a, 47
	jrl	z, MemConfig_Handler_4_Helper5
	cp	a, 95
	jrl	z, MemConfig_Handler_4_Helper5
	jp	MemConfig_Handler_4_Join3
MemConfig_Handler_4_Skip5:
	call	VoiceSlot_FlagCheck
	ld	(3522:16), a
	ld	(13964:16), 0
MemConfig_Handler_4_Loop2:
	call	VoiceSlot_CompareAndBranch
	cp	w, 255
	jrl	nz, MemConfig_Handler_4_Skip6
	call	MemConfig_VoiceSlotLookup
	call	MemConfig_Handler_4_Helper5_Helper
	xor	wa, wa
	ld	(3416:16), wa
	ld	(3415:16), a
	jp	MemConfig_Handler_4_Join3
MemConfig_Handler_4_Skip6:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	nz, MemConfig_Handler_4_Skip7
	call	VoiceSlot_FlagCheck
	cp	a, (3522:16)
	jrl	z, MemConfig_Handler_4_Loop2
MemConfig_Handler_4_Join2:
	call	VoiceSlot_LoadAndDispatch
	jp	MemConfig_Handler_4_Join3
MemConfig_Handler_4_Skip7:
	cp	a, 129
	jrl	z, MemConfig_Handler_4_Skip8
	jp	MemConfig_Handler_4_Join2
MemConfig_Handler_4_Skip8:
	incw	1, (3416:16)
	jp	MemConfig_Handler_4_Join2
MemConfig_Handler_4_Skip9:
	ld	w, 255:opc
	ld	(3434:16), w
	jp	MemConfig_Handler_4_Return3
MemConfig_Handler_4_Join3:
	ld	w, 0:opc
MemConfig_Handler_4_Return3:
	ret
Timer_ModeHandler_0_Helper2:
	ld (0xfc5f:16), 0x00
	ld (0xfc60:16), 0x00
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	ld A, 0x48:opc
	ld W, 0x05:opc
	xor E,E
	ld D, 0x04:opc
	call PortConfig_DataTable_A_Helper
	ld A, 0x48:opc
	ld W, 0x06:opc
	ld D, 0x04:opc
	xor E,E
	call PortConfig_DataTable_A_Helper
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	ret
PerfMode_Handler_EvtB_Helper2_Helper9:
	cp	(0x0d65:16), 0
	jrl	nz, MemConfig_Handler_4_Return4
	ldb_d8	a, (0xfc5d)
	and	a, 7
	cp	a, 1:i3
	jrl	nz, Timer_ModeHandler_0_Helper2_Skip
	jp	MemConfig_Handler_4_Return4
Timer_ModeHandler_0_Helper2_Skip:
	and	(0xfc5d:16), 248
	or	(0xfc5d:16), 2
	ld	a, 72:opc
	ld	w, 3:opc
	ld	e, 2:opc
	ld	d, 2:opc
	call	PortConfig_DataTable_A_Helper
MemConfig_Handler_4_Return4:
	ret
SysInit_SendAllNotesAndReset:
	ld	(13964:16), 0
	call	DisplayStr_StyleSectionInit
	xor	wa, wa
	ld	a, 10:opc
	call	UI_PostPartChangeEvent
	ret
	; Pointer table, 24 B.  Read by SysInit_SendAllNotesAndReset (0xEFB79F): `ld XDE,SystemInit_Handler_Table`
	; indexed with stride 1 (`sla WA, 0x02`)
SystemInit_Handler_Table:
	.long	SystemInit_StepHandler_0
	.long	SystemInit_StepHandler_0
	.long	SystemInit_StepHandler_2
	.long	SystemInit_StepHandler_3
	.long	SystemInit_StepHandler_4
	.long	SystemInit_StepHandler_5
SystemInit_Handler_Table_0x18:
	push	xhl
	ld	a, l
	ld	xhl, SysInit_SendAllNotesAndReset_Tbl
	ld	a, (xhl+a)
	stb_d8	(0x368c), a
	ld	(0x0d5e:16), 16
	call	VoiceCtrl_ParamSetupBytecode_Helper8
	pop	xhl
	sub	l, 2
	cp	l, 6:i3
	jrl	lt, SysEx_BytecodeDispatcher_Helper_Skip
	sub	l, 2
SysEx_BytecodeDispatcher_Helper_Skip:
	xor	h, h
	sla	hl, 3
SystemInit_Handler_Table_Join:
	call SystemInit_Handler_Table_Helper
	ld A,W
	exts WA
	sla WA, 0x02
	ld IY,WA
	push XDE
	ld XDE,SystemInit_Handler_Table
	ld	xiy, (xde+iy)
	pop XDE
	jp (XIY)
SystemInit_StepHandler_5:
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	l, 5:opc
	call	SysEx_BytecodeDispatcher_Helper2
	call	SysEx_BytecodeDispatcher_Helper3
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	add	hl, 4
	jp	SystemInit_Handler_Table_Join
SystemInit_StepHandler_4:
	add	hl, 4
	jp	SystemInit_Handler_Table_Join
SystemInit_StepHandler_3:
	call	SystemInit_StepHandler_3_Helper
	jp	SystemInit_StepHandler_0
SystemInit_StepHandler_2:
	call	MemConfig_Handler_0
	call	SysInit_SendAllNotesAndReset
	jp	SystemInit_StepHandler_0
SystemInit_StepHandler_0:
	ld W, 0x62:opc
	call MIDI_SendSysExFromW
	ld W, 0x00:opc
	ret
	; Byte data, 16 B.  Read by VoiceCtrl_ParamSetupBytecode (0xEF97B6): `ld xhl, SysInit_SendAllNotesAndReset_Tbl`
	; also read by SysInit_SendAllNotesAndReset
SysInit_SendAllNotesAndReset_Tbl:
	.byte	0x00, 0x00, 0x05, 0x06, 0x07, 0x0b, 0x03, 0x04, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00
SystemInit_StepHandler_3_Helper:
	cp	(3429:16), 0
	jrl	nz, SystemInit_StepHandler_0_Skip2
	call	SystemInit_StepHandler_0_Helper
	cp	(52821:16), 0
	jrl	z, SystemInit_StepHandler_0_Skip
	pushw	wa
	ld	d, a
	xor	e, e
	call	SysEx_BytecodeDispatcher_Helper2_Sub
	call	SysEx_BytecodeDispatcher_Helper3
	popw	wa
SystemInit_StepHandler_0_Skip:
	exts	wa
	ld	bc, wa
	ld	l, 96:opc
	call	SysEx_BytecodeDispatcher_Helper3_Sub2
SystemInit_StepHandler_0_Skip2:
	or	(0x0d53:16), 64
	ret
SysEx_BytecodeDispatcher_Helper2:
	xor	h, h
	sla	hl, 2
	extz	xhl
	push	xix
	ld	xix, SystemInit_StepHandler_0_Tbl
	ld	de, (xix+hl)
	pop	xix
SysEx_BytecodeDispatcher_Helper2_Sub:
	xor	a, a
	ld	(3437:16), a
	ld	(3438:16), a
	ld	(4391:16), a
	ld	xiz, 3471
	ld	xiy, 52822
	ld	c, (52821:16)
SysEx_BytecodeDispatcher_Helper2_Join:
	cp	c, 0:i3
	jrl	z, SystemInit_StepHandler_0_Return
	ld	a, (36004:16)
	ld	(3437:16), a
	ld	a, (36006:16)
	ld	(3438:16), a
	ld	a, (36008:16)
	ld	(4391:16), a
	ld	(xiz+0:8), 144
	ld	a, (3415:16)
	ld	(xiz+1), a
	ld	a, (xiy)
	inc	1, xiy
	ld	(xiz+2), a
	ld	(xiz+3), 64
	ld	(xiz+4), de
	dec	1, c
	add	xiz, 6
	jp	SysEx_BytecodeDispatcher_Helper2_Join
SystemInit_StepHandler_0_Return:
	ret
	; Byte data, 24 B.  Read by SystemInit_StepHandler_0 (0xEFB84B): `ld xix, SystemInit_StepHandler_0_Tbl`
	; indexed with stride 4 (`sla hl, 2`)
SystemInit_StepHandler_0_Tbl:
	.byte	0x00, 0x04, 0x60, 0x04, 0x00, 0x03, 0x60, 0x03, 0x00, 0x02, 0x60, 0x02, 0x30, 0x01, 0x90, 0x01
	.byte	0x00, 0x01, 0x60, 0x01, 0x30, 0x00, 0x30, 0x01
SysInit_BytecodeBlock:
	.byte	0x50, 0x40, 0x30, 0x20, 0x10, 0x00
SysEx_BytecodeDispatcher_Data:	.byte	0x01, 0x02, 0x03, 0x05, 0x04, 0x06
SysEx_BytecodeDispatcher_Helper3:
	ld b, (0xce55:16)
	sla B, 0x01
	ld C,B
	add B,B
	add B,C
	ld W,B
	ld XIY,0x00000d8f
	call DisplayMode_Handler_3_Helper16
	ret
SysEx_BytecodeDispatcher_Helper3_Loop:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, SysEx_BytecodeDispatcher_Helper3_Skip
SysEx_BytecodeDispatcher_Helper3_Sub:
	call	VoiceCtrl_BytecodeHandler
	cp	b, 22
	jrl	z, SysEx_BytecodeDispatcher_Helper3_Loop
	cp	b, 23
	jrl	z, SysEx_BytecodeDispatcher_Helper3_Loop
SysEx_BytecodeDispatcher_Helper3_Skip:
	ld	xiy, 0x0dbf
	call	SysEx_BytecodeDispatcher_Helper8
	cp	l, 255
	jrl	z, SysEx_BytecodeDispatcher_Helper3_Return
	xor	h, h
	sla	hl, 2
	push	xde
	ld	xde, SystemInit_StepHandler_0_Tbl
	lda	xde, (xde+hl)
	ld	bc, (xde+2)
	pop	xde
	ld	l, c
	xor	c, c
	ex8	c, b
SysEx_BytecodeDispatcher_Helper3_Sub2:
	ldb_d8	a, (0x0d57)
	stb_d8	(0x0dfa), a
	add	a, l
	cp	a, 96
	jrl	c, SysEx_BytecodeDispatcher_Helper3_Skip2
	sub	a, 96
	stb_d8	(0x0d57), a
	call	ToneParam_ModeGuardEntry_Helper2_Helper
	cp	a, 96
	jrl	c, SysEx_BytecodeDispatcher_Helper3_Skip2
	sub	a, 96
	stb_d8	(0x0d57), a
	call	ToneParam_ModeGuardEntry_Helper2_Helper
SysEx_BytecodeDispatcher_Helper3_Skip2:
	djnz16	bc, -39
	stb_d8	(0x0d57), a
	cp	a, (0x0dfa:16)
	jrl	z, SysEx_BytecodeDispatcher_Helper3_Return
	call	MemConfig_Handler_5_Helper6
SysEx_BytecodeDispatcher_Helper3_Return:
	ret
SysInit_BytecodeBlock_Join:
	call	ToneParam_ModeGuardEntry_Helper4
	cp	w, 255
	jrl	z, SysEx_BytecodeDispatcher_Helper3_Skip3
	cp	c, 2:i3
	jrl	ule, SysEx_BytecodeDispatcher_Helper3_Return2
SysEx_BytecodeDispatcher_Helper3_Skip3:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, SysEx_BytecodeDispatcher_Helper3_Return2
	call	VoiceSlot_LoadAndDispatch
	jp	SysInit_BytecodeBlock_Join
SysEx_BytecodeDispatcher_Helper3_Return2:
	ret
Timer_ParamLoadAndCompare_Helper2:
	xor A,A
	call VoiceSlot_SaveState
	call VoiceSlot_FlagCheck
	cp A,0x84
	jrl nz, .Lc_efb9fd
	set 7, (0x0d54:16)
.Lc_efb9fd:
	call MemConfig_Handler_5_Code_Helper12
	xor A,A
	call VoiceSlot_RestoreState
	ret
Timer_ParamCompareAlt_Helper4:
	call	VoiceSlot_FlagCheck
	cp	a, 132
	jrl	nz, Timer_ParamCompareAlt_Helper4_Skip
	set	7, (0x0d54:16)
Timer_ParamCompareAlt_Helper4_Skip:
	call	MemConfig_Handler_5_Code_Helper12
	ret
ToneParam_ModeGuardEntry_Helper2_Helper:
	incw	1, (0x0d58:16)
MemConfig_Handler_5_Code_Helper12:
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	ld W, 0x01:opc
	ld XIY,0x00000e48
	ld (XIY),0x81
	call DisplayMode_Handler_3_Helper16
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	ret
SysEx_BytecodeDispatcher_Helper4:
	cp	l, 2:i3
	jrl	z, SysEx_BytecodeDispatcher_Helper4_Skip
	cp	l, 10
	jrl	nz, SysInit_BytecodeBlock_Return
SysEx_BytecodeDispatcher_Helper4_Skip:
	pushw	hl
	call	MemConfig_Handler_4_Helper6
	popw	hl
	cp	w, 255
	jrl	z, SysEx_BytecodeDispatcher_Helper4_Skip2
	jp	SysInit_BytecodeBlock_Return
SysEx_BytecodeDispatcher_Helper4_Skip2:
	xor	wa, wa
	cp	(0x0d58:16), wa
	jrl	nz, SysEx_BytecodeDispatcher_Helper4_Skip3
	cp	(0x0d57:16), a
	jrl	z, SysInit_BytecodeBlock_Return
SysEx_BytecodeDispatcher_Helper4_Skip3:
	cp	l, 2:i3
	jrl	z, SysEx_BytecodeDispatcher_Helper4_Skip4
	ld	l, 5:opc
	jp	SysInit_BytecodeBlock_Return
SysEx_BytecodeDispatcher_Helper4_Skip4:
	ld	l, 4:opc
SysInit_BytecodeBlock_Return:
	ret
SysEx_BytecodeDispatcher_Helper6:
	cp	l, 7:i3
	jrl	nz, SysInit_BytecodeBlock_Return2
	call	MemConfig_Handler_4_Helper6
	cp	w, 0:i3
	jrl	z, SysEx_BytecodeDispatcher_Helper4_Skip5
	jp	SysInit_BytecodeBlock_Return2
SysEx_BytecodeDispatcher_Helper4_Skip5:
	xor	wa, wa
	cp	(0x0d58:16), wa
	jrl	nz, SysInit_BytecodeBlock_Return2
	cp	(0x0d57:16), a
	jrl	nz, SysInit_BytecodeBlock_Return2
	ld	l, 3:opc
SysInit_BytecodeBlock_Return2:
	ret
SysEx_BytecodeDispatcher_Helper7:
	cp	l, 10
	jrl	nz, SysInit_BytecodeBlock_Return3
	call	MemConfig_Handler_4_Helper6
	cp	w, 255
	jrl	z, SysEx_BytecodeDispatcher_Helper4_Skip6
	jp	SysInit_BytecodeBlock_Return3
SysEx_BytecodeDispatcher_Helper4_Skip6:
	xor	wa, wa
	cp	(0x0d58:16), wa
	jrl	nz, SysInit_BytecodeBlock_Return3
	cp	(0x0d57:16), a
	jrl	nz, SysInit_BytecodeBlock_Return3
	ld	l, 5:opc
SysInit_BytecodeBlock_Return3:
	ret
ClockConfig_Handler_0_Tbl2_Helper2:
	ld	xhl, 0x0d54
	bitm	7, (xhl)
	jrl	z, SysEx_BytecodeDispatcher_Helper4_Return
	resm	7, (xhl)
	call	VoiceState_DataBlock2_Helper7
	cp	w, 0:i3
	jrl	nz, SysEx_BytecodeDispatcher_Helper4_Return
	call	VoiceSlot_ComputeWordIndex
	push	xix
	ld	xix, 0xf1f8
	ld	wa, (xix+iz)
	ld	xix, 0x0c9e
	ld	(xix+iz), wa
	srl	xiz, 1
	ld	xix, 0xf218
	ld	a, (xix+iz)
	ld	xix, 0x0cbe
	ld	(xix+iz), a
	pop	xix
SysInit_BytecodeBlock_Join2:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	nz, SysEx_BytecodeDispatcher_Helper4_Skip7
	call	Timer_ParamCompareAlt_Helper5
	cp	w, 255
	jrl	z, SysEx_BytecodeDispatcher_Helper4_Return
	jp	SysInit_BytecodeBlock_Join2
SysEx_BytecodeDispatcher_Helper4_Skip7:
	cp	a, 129
	jrl	nz, SysEx_BytecodeDispatcher_Helper4_Return
	xor	a, a
	call	VoiceSlot_SaveState
	ld	w, 132:opc
	call	MemConfig_Handler_5_Code_Helper13
	ld	de, 1:i3
	call	Timer_ModeHandler_0_Helper6
	ld	w, 132:opc
	call	MemConfig_Handler_5_Code_Helper13
	xor	a, a
	call	VoiceSlot_RestoreState
	call	MemConfig_Handler_0_Helper
SysEx_BytecodeDispatcher_Helper4_Return:
	ret
	xor	a, a
	stb_d8	(0x0eee), a
SysEx_BytecodeDispatcher_Helper4_Loop:
	ldb_d8	a, (0x0eee)
	inc	1, a
	cp	a, 15
	jrl	ugt, SysInit_BytecodeBlock_Return4
	stb_d8	(0x0eee), a
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	push	xix
	ld	xix, 0xf1a0
	cp	(xix+iz), 0x0d
	pop	xix
	jrl	nz, SysEx_BytecodeDispatcher_Helper4_Loop
SysInit_BytecodeBlock_Sub:
	call	VoiceState_DataBlock2_Helper7
	cp	w, 0:i3
	jrl	nz, SysInit_BytecodeBlock_Return4
	call	VoiceSlot_ComputeIndex
	push	xix
	ld	xix, 0xf250
	add	xix, xiz
	ld	de, (xix+1)
	pop	xix
	call	VoiceSlot_ComputeWordIndex
	push	xix
	ld	xix, 0x0c9e
	ld	(xix+iz), de
	srl	xiz, 1
	ld	xix, 0x0cbe
	ld	(xix+iz), 0x05
	pop	xix
SysInit_BytecodeBlock_Join3:
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	call	VoiceSlot_ReadCurrentParams
	ld	w, a
	and	a, 240
	cp	a, 176
	jrl	z, SysEx_BytecodeDispatcher_Helper4_Skip8
SysInit_BytecodeBlock_Join4:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, SysInit_BytecodeBlock_Return4
SysInit_BytecodeBlock_Join5:
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, SysInit_BytecodeBlock_Return4
	cp	a, 132
	jrl	z, SysInit_BytecodeBlock_Return4
	jp	SysInit_BytecodeBlock_Join3
	jp	SysInit_BytecodeBlock_Return4
SysEx_BytecodeDispatcher_Helper4_Skip8:
	and	w, 1
	rrc	w
	stb_d8	(0x0dc8), w
	cp	a, 176
	jrl	nz, SysEx_BytecodeDispatcher_Helper4_Skip11
	call	VoiceSlot_FlagCheck
	cp	a, 48
	jrl	z, SysEx_BytecodeDispatcher_Helper4_Skip9
	cp	a, 96
	jrl	nz, SysEx_BytecodeDispatcher_Helper4_Skip11
SysEx_BytecodeDispatcher_Helper4_Skip9:
	ld	a, 2:opc
	call	VoiceSlot_SaveState
	ld	de, 4:i3
	call	Timer_ModeHandler_0_Helper6
	call	VoiceSlot_ReadCurrentParams
	or	a, (0x0dc8:16)
	cp	a, 0:i3
	jrl	nz, SysEx_BytecodeDispatcher_Helper4_Skip10
	ld	a, 2:opc
	call	VoiceSlot_RestoreState
	ld	de, 1:i3
	call	Timer_ModeHandler_0_Helper6
	call	VoiceSlot_ReadCurrentParams
	dec	1, a
	ld	w, a
	call	MemConfig_Handler_5_Code_Helper13
SysEx_BytecodeDispatcher_Helper4_Skip10:
	ld	a, 2:opc
	call	VoiceSlot_RestoreState
SysEx_BytecodeDispatcher_Helper4_Skip11:
	call	VoiceSlot_FlagCheck
	stb_d8	(0x0e4a), a
	xor	a, a
	stb_d8	(0x0e49), a
SysEx_BytecodeDispatcher_Helper4_Loop2:
	call	VoiceSlot_DispatchRet
	inc	1, (0x0e49:16)
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, SysEx_BytecodeDispatcher_Helper4_Skip12
	cp	a, 129
	jrl	nz, SysEx_BytecodeDispatcher_Helper4_Skip13
SysEx_BytecodeDispatcher_Helper4_Skip12:
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	jp	SysInit_BytecodeBlock_Join4
SysEx_BytecodeDispatcher_Helper4_Skip13:
	call	VoiceSlot_FlagCheck
	cp	(0x0e4a:16), a
	jrl	ule, SysEx_BytecodeDispatcher_Helper4_Loop2
SysEx_BytecodeDispatcher_Helper4_Loop3:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, SysEx_BytecodeDispatcher_Helper4_Skip14
	call	VoiceSlot_FlagCheck
	cp	(0x0e4a:16), a
	jrl	ugt, SysEx_BytecodeDispatcher_Helper4_Skip14
	inc	1, (0x0e49:16)
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	nz, SysEx_BytecodeDispatcher_Helper4_Loop3
	dec	1, (0x0e49:16)
SysEx_BytecodeDispatcher_Helper4_Skip14:
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	call	VoiceSlot_FinalRetZ
	ld	xiy, 0x0d8f
	ld	(0x0dd2:16), 0
	ld	(xiy), a
SysInit_BytecodeBlock_Join6:
	inc	1, xiy
	inc	1, (0x0dd2:16)
	push	xiy
	call	VoiceSlot_FinalRetZ
	pop	xiy
	bit	7, a
	jrl	nz, SysEx_BytecodeDispatcher_Helper4_Skip15
	ld	(xiy), a
	jp	SysInit_BytecodeBlock_Join6
SysEx_BytecodeDispatcher_Helper4_Skip15:
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	call	VoiceState_DataBlock2_Helper2
	ldb_d8	c, (0x0e49)
	xor	b, b
	pushw	bc
	call	VoiceSlot_DispatchRet
	popw	bc
	djnz16	bc, -9
	ld	xiy, 0x0d8f
	ldb_d8	w, (0x0dd2)
	call	DisplayMode_Handler_3_Helper16
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	jp	SysInit_BytecodeBlock_Join5
SysInit_BytecodeBlock_Return4:
	ret
PortConfig_DataTable_A_Helper:
	push XIX
	pushw hl
	ld XIX,0x0000be9d
	ld hl, (0x9046:16)
	ld	(xix+hl), wa
	ldfr_lerp	xix, 56
	lda	xix, (xix+hl)
	ld	(xix+2), de
	ldto_lerp	xix, 56
	ldfr_lerp	xix, 56
	lda	xix, (xix+hl)
	ld	(xix+4), 255
	ldto_lerp	xix, 56
	add	hl, 4
	ld	(0x9046:16), hl
	popw	hl
	pop	xix
	ret
SysEx_BytecodeDispatcher_Helper8:
	pushw	bc
	xor	c, c
SysEx_BytecodeDispatcher_Helper4_Loop4:
	ldfr_berp	a, 60
	ld	a, c
	scf
	xorcf	a, (xiy)
	ldto_berp	a, 60
	jrl	nc, SysEx_BytecodeDispatcher_Helper4_Skip16
	inc	1, c
	cp	c, 8
	jrl	c, SysEx_BytecodeDispatcher_Helper4_Loop4
	ld	l, 255:opc
SysInit_BytecodeBlock_Join7:
	popw	bc
	jp	SysInit_BytecodeBlock_Return5
SysEx_BytecodeDispatcher_Helper4_Skip16:
	ld	l, c
	jp	SysInit_BytecodeBlock_Join7
SysInit_BytecodeBlock_Return5:
	ret
SysEx_BytecodeDispatcher_Helper9:
	push	xiy
	pushw	bc
	xor	c, c
SysEx_BytecodeDispatcher_Helper4_Loop5:
	ldfr_berp	a, 60
	ld	a, c
	scf
	xorcf	a, (xiy)
	ldto_berp	a, 60
	jrl	nc, SysEx_BytecodeDispatcher_Helper4_Skip17
	inc	1, c
	cp	c, 8
	jrl	c, SysEx_BytecodeDispatcher_Helper4_Loop5
	xor	c, c
	inc	1, xiy
SysEx_BytecodeDispatcher_Helper4_Loop6:
	ldfr_berp	a, 60
	ld	a, c
	scf
	xorcf	a, (xiy)
	ldto_berp	a, 60
	jrl	nc, SysEx_BytecodeDispatcher_Helper4_Skip18
	inc	1, c
	cp	c, 8
	jrl	c, SysEx_BytecodeDispatcher_Helper4_Loop6
	ld	l, 255:opc
SysInit_BytecodeBlock_Join8:
	popw	bc
	pop	xiy
	jp	SysInit_BytecodeBlock_Return6
SysEx_BytecodeDispatcher_Helper4_Skip17:
	ld	l, c
	jp	SysInit_BytecodeBlock_Join8
SysEx_BytecodeDispatcher_Helper4_Skip18:
	ld	l, c
	add	l, 8
	jp	SysInit_BytecodeBlock_Join8
SysInit_BytecodeBlock_Return6:
	ret
DisplayMode_Handler_3_Helper16:
	ld a, (0x0eee:16)
	call SysInit_BytecodeBlock_Helper
	or (0x8cec:16), 0x01
	or (0x266a:16), 0x01
	ret
SysInit_BytecodeBlock_Helper:
	pushw	bc
	ld	(0x1101:16), xiy
	stb_d8	(0x0eee), a
	ld	c, w
	call	VoiceSlot_ComputeWordIndex
	ld	xix, 0xf1f8
	xor	b, b
SysInit_BytecodeBlock_Join9:
	ld	iy, (xix+iz)
	cp	iy, 65535
	jrl	z, DisplayMode_Handler_3_Helper16_Skip3
	ld	(0x28ba:16), iy
	srl	xiz, 1
	ldfr_lerp	xix, 56
	lda	xix, (xix+iz)
	ld	a, (xix+32)
	ldto_lerp	xix, 56
	xor	w, w
	sla	iz, 1
	ld	(0x28bc:16), wa
	ld	xix, 0x0c9e
SysInit_BytecodeBlock_Join10:
	ld	de, (xix+iz)
	cp	de, 65535
	jrl	nz, DisplayMode_Handler_3_Helper16_Skip
	ld	(xix+iz), iy
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda	xix, (xix+iz)
	ld	(xix+32), 5
	ldto_lerp	xix, 56
	sla	iz, 1
	jp	SysInit_BytecodeBlock_Join10
DisplayMode_Handler_3_Helper16_Skip:
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda	xix, (xix+iz)
	ld	iy, (xix+32)
	ldto_lerp	xix, 56
	sla	iz, 1
	and	iy, 255
	ld	(0x28b8:16), iy
	ld	xix, 0xf1f8
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda	xix, (xix+iz)
	ld	a, (xix+32)
	ldto_lerp	xix, 56
	xor	w, w
	sla	iz, 1
	add	wa, bc
	cp	wa, 255
	jrl	ugt, DisplayMode_Handler_3_Helper16_Skip2
	ld	iy, (xix+iz)
	ld	(0x289f:16), iy
	ld	(0x28b6:16), wa
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda	xix, (xix+iz)
	ld	(xix+32), a
	ldto_lerp	xix, 56
	sla	iz, 1
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	Scoop_EventHandler_Scroll
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	call	VoiceSlot_InitAndProcess
	xor	w, w
	popw	bc
	jp	SysInit_BytecodeBlock_Return7
DisplayMode_Handler_3_Helper16_Skip2:
	sub	wa, 251
	ld	(0x28b6:16), wa
	pushw	de
	call	DispatchHandler_JumpToSubHandler
	popw	de
	cp	w, 255
	jrl	z, DisplayMode_Handler_3_Helper16_Loop
	ld	iy, ix
	ld	xix, 0xf1f8
	srl	iz, 1
	ldw_d16	wa, (0x28b6)
	ldfr_lerp	xix, 56
	lda	xix, (xix+iz)
	ld	(xix+32), a
	ldto_lerp	xix, 56
	sla	iz, 1
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (0x10fd:16)
	ldw	(xhl+3), 65535
	ld	(0x289f:16), iy
	ld	wa, iy
	pushw	de
	ld	xix, 0xf1f8
	ld	de, (xix+iz)
	ld	(xhl+1), de
	ld	(xix+iz), wa
	ld	iy, de
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (0x10fd:16)
	ld	(xhl+3), wa
	popw	de
	pushw	de
	pushw	bc
	push	xhl
	push	xiz
	call	Scoop_EventHandler_Scroll
	pop	xiz
	pop	xhl
	popw	bc
	popw	de
	call	VoiceSlot_InitAndProcess
	xor	w, w
	popw	bc
	jp	SysInit_BytecodeBlock_Return7
DisplayMode_Handler_3_Helper16_Loop:
	ld	w, 104:opc
	call	MIDI_SendSysExFromW
	and	(0xe31c:16), 111
	ld	(0x7ea6:16), 15
	xor	wa, wa
	ld	a, 238:opc
	call	SoundCtrl_SendCommand
	popw	bc
	jp	SysInit_BytecodeBlock_Return7
DisplayMode_Handler_3_Helper16_Skip3:
	push	xix
	call	DispatchHandler_JumpToSubHandler
	ld	iy, ix
	pop	xix
	cp	w, 255
	jrl	z, DisplayMode_Handler_3_Helper16_Loop
	ld	(xix+iz), iy
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda	xix, (xix+iz)
	ld	(xix+32), 5
	ldto_lerp	xix, 56
	sla	iz, 1
	pushw	wa
	push	xiz
	push	xix
	push	xiy
	ldb_d8	a, (0x0eee)
	dec	1, a
	ld	w, a
	sla	a, 1
	add	a, w
	xor	w, w
	ld	iz, wa
	ld	xix, 0xf250
	or	(xix+iz), 0x80
	ldfr_lerp	xix, 56
	lda	xix, (xix+iz)
	ld	(xix+1), iy
	ldto_lerp	xix, 56
	pop	xiy
	pop	xix
	pop	xiz
	popw	wa
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (0x10fd:16)
	ldw	(xhl+1), 0
	ldw	(xhl+3), 65535
	jp	SysInit_BytecodeBlock_Join9
SysInit_BytecodeBlock_Return7:
	ret
VoiceSlot_InitAndProcess:
	cp bc, 0:i3
	jrl nz, VoiceSlot_InitLoop
	jp VoiceSlot_RetNZ

VoiceSlot_InitLoop:
	ld xix, 0xc9e
	srl iz, 1
	ldfr_lerp XIX, 0x38
	lda	xix, (xix+iz)
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
	lda	xix, (xix+iz)
	ld (xix + 32), c
	ldto_lerp XIX, 0x38
	sla iz, 1
	pushw iy
	ld	iy, (xix+iz)
	call VoiceSlot_UpdateCurrentPointer
	popw iy
	ld xhl, (4349:16)
	extz xiy
	add xhl, xiy
	popw bc
	ld xix, xhl
	ld xiy, (4353:16)
	ldir85
	jp VoiceSlot_RetNZ

VoiceSlot_ProcessEntry:
	ld de, bc
	ldw wa, 0x100
	ld	iy, (xix+iz)
	srl iz, 1
	lda	xix, (xix+iz)
	ld ix, (xix + 32)
	and ix, 0xff
	sub wa, ix
	ld bc, wa
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	extz xix
	add xhl, xix
	ld xix, xhl
	ld xiy, (4353:16)
	add (4353:16), bc
	ldir85
	ld bc, de
	sub bc, 0xfb
	ld xix, 0xc9e
	ldfr_lerp XIX, 0x38
	lda	xix, (xix+iz)
	ld (xix + 32), c
	ldto_lerp XIX, 0x38
	sla iz, 1
	sub c, 0x5
	ld	iy, (xix+iz)
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	ld iy, (xhl + 3)
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	ld	(xix+iz), iy
	ld xix, xhl
	add xix, 0x5
	ld xiy, (4353:16)
	cp bc, 0:i3
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
	ld	iy, (xix+iz)
	ld (10399:16), iy
	srl	iz, 1
	ldfr_lerp xix, 56
	lda	xix, (xix+iz)
	ld a, (xix+32)
	ldto_lerp xix, 56
	xor	w, w
	sla	iz, 1
	ld	(0x28b6:16), wa
	xor	b, b
	add	wa, bc
	cp	wa, 255
	jrl	ugt, VoiceSlot_RetZ_Skip
VoiceSlot_RetZ_Join:
	ld	(0x28ba:16), iy
	ld	(0x28bc:16), wa
	jp	VoiceSlot_RetZ_Join2
VoiceSlot_RetZ_Skip:
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	iy, (xhl+3)
	sub	wa, 251
	jp	VoiceSlot_RetZ_Join
VoiceSlot_RetZ_Join2:
	ld	xix, 0xf1f8
	ld	de, (xix+iz)
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda	xix, (xix+iz)
	ld	a, (xix+32)
	ldto_lerp	xix, 56
	xor	w, w
	sla	iz, 1
	ld	(0x28b8:16), wa
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	Scoop_EventHandler_SpecialMode
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	sub	wa, bc
	cp	wa, 4:i3
	jrl	le, VoiceSlot_RetZ_Skip2
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda	xix, (xix+iz)
	ld	(xix+32), a
	ldto_lerp	xix, 56
	sla	iz, 1
	jp	VoiceSlot_RetZ_Return
VoiceSlot_RetZ_Skip2:
	cp	wa, 0xffff
	jrl	le, VoiceSlot_RetZ_Skip3
	add	a, 251
	jp	VoiceSlot_RetZ_Join3
VoiceSlot_RetZ_Skip3:
	sub	wa, 5
VoiceSlot_RetZ_Join3:
	ld	iy, de
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	de, (xhl+1)
	ld	(xix+iz), de
	ld	iy, de
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda	xix, (xix+iz)
	ld	(xix+32), a
	ldto_lerp	xix, 56
	sla	iz, 1
	ld	iy, (xhl+3)
	ld	wa, 1:i3
	call	MemConfig_Handler_1_Helper3
VoiceSlot_RetZ_Return:
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
	ld w, 0x0:opc
	call VoiceSlot_CompareRet
	jp VoiceSlot_DispatchDone

VoiceSlot_ReadParamsErrExit:
	ld w, 0xff:opc

VoiceSlot_DispatchDone:
	ret

VoiceSlot_DispatchRet:
	push_sd16w 0x58, 0x0d
	call VoiceSlot_LoadAndDispatch
	popw_dd16 0x58, 0x0d
	ret

VoiceSlot_CompareAndBranch:
	ld	w, 1:opc
	call	VoiceSlot_CompareRet
	ret
Timer_ParamCompareAlt_Helper5:
	pushdi_w	(0x0d58)
	call	VoiceSlot_CompareAndBranch
	popw_dd16 0x58, 0x0d	; popw (0x0d58)
	ret

VoiceSlot_CompareRet:
	ld h, w
	call VoiceSlot_ComputeWordIndex
	pushw bc
	xor c, c
	ld b, h
	push xix
	ld xix, 0xc9e
	ld	iy, (xix+iz)
	pop xix
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	srl iz, 1
	push xde
	ld xde, 0xcbe
	ld	ix, (xde+iz)
	pop xde
	and ix, 0xff
	sla iz, 1
	cp b, 0:i3
	jrl nz, VoiceSlot_DecCountLoop

VoiceSlot_StoreAndAdvance:
	inc 1, ix
	cp ix, 0xff
	jrl ugt, VoiceSlot_LoadFromTableBody
	ld	a, (xhl+ix)
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
	ld	(xde+iz), iy
	srl iz, 1
	ld xde, 0xcbe
	ld	(xde+iz), a
	pop xde
	sla iz, 1
	xor w, w
	ld (3532:16), c
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
	incw 1, (3416:16)

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
	ld	iy, (xde+iz)
	pop xde
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	ld iy, (xhl + 3)
	cp iy, 0xffff
	jrl z, VoiceSlot_SubrDone
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	ld ix, 4:i3
	jp VoiceSlot_StoreAndAdvance

VoiceSlot_DecCountLoop:
	dec 1, ix
	cp ix, 4:i3
	jrl le, VoiceSlot_SubroutineBody
	ld	a, (xhl+ix)
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
	ld	(xde+iz), iy
	srl iz, 1
	ld xde, 0xcbe
	ld	(xde+iz), a
	pop xde
	sla iz, 1
	xor w, w
	ld (3532:16), c
	popw bc
	jp VoiceSlot_SubrRetNZ

VoiceSlot_SubroutineTable:
	call VoiceSlot_SubrRetZ
	jp VoiceSlot_CallSubroutine

VoiceSlot_SubroutineBody:
	push xde
	ld xde, 0xc9e
	ld	iy, (xde+iz)
	pop xde
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	ld iy, (xhl + 1)
	cp iy, 0:i3
	jrl z, VoiceSlot_SubrDone
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	ldw ix, 0x100
	jp VoiceSlot_DecCountLoop

VoiceSlot_SubrDone:
	ld w, 0xff:opc
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
	ld	iy, (xde+iz)
	pop xde
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	srl iz, 1
	push xde
	ld xde, 0xcbe
	ld	iy, (xde+iz)
	pop xde
	sla iz, 1
	and iy, 0xff
	ld	a, (xhl+iy)
	xor w, w
	ret

VoiceSlot_FlagCheck:
	ldw (3573:16), 1
	call VoiceSlot_FlagCheckDone
	ret

VoiceSlot_FlagCheckBody:
	ldw (3573:16), 2
	call VoiceSlot_FlagCheckDone
	ret

VoiceSlot_FlagCheckDone:
	call VoiceSlot_ComputeWordIndex
	xor w, w
	push xde
	ld xde, 0xc9e
	ld	iy, (xde+iz)
	pop xde
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	srl iz, 1
	push xde
	ld xde, 0xcbe
	ld	iy, (xde+iz)
	pop xde
	sla iz, 1
	and iy, 0xff
	add iy, (3573:16)
	cp iy, 0xff
	jrl ugt, VoiceSlot_FinalCheck
	ld	a, (xhl+iy)
	jp VoiceSlot_FinalRetNZ

VoiceSlot_FinalCheck:
	ld iy, (xhl + 3)
	cp iy, 0xffff
	jrl z, VoiceSlot_FinalDone
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	ld iy, 5:i3
	ld	a, (xhl+iy)
	jp VoiceSlot_FinalRetNZ

VoiceSlot_FinalDone:
	ld w, 0xff:opc

VoiceSlot_FinalRetNZ:
	ret

VoiceSlot_FinalRetZ:
	call VoiceSlot_ReadCurrentParams
	pushw WA
	ld de, 1:i3
	call Timer_ModeHandler_0_Helper6
	ld D,W
	popw	wa
	ld	w, d
	ret
VoiceSlot_FinalRetZ_0x11:
	ld	a, e
	push	xiy
	push	xiz
	push	xhl
	call	VoiceSlot_FlagCheck
	pop	xhl
	pop	xiz
	pop	xiy
	ret
VoiceSlot_FinalRetZ_0x1E:
	push	xhl
	pushw	de
	dec	1, e
	sla	e, 1
	xor	d, d
	ld	iz, de
	extz	xiz
	push	xix
	ld	xix, 3230
	ld	iy, (xix+iz)
	pop	xix
	call	VoiceSlot_UpdateCurrentPointer
	srl	iz, 1
	push	xix
	ld	xix, 3262
	ld	iy, (xix+iz)
	pop	xix
	and	iy, 255
	sla	iz, 1
	ld	xhl, (4349:16)
	ld	a, (xhl+iy)
	popw	de
	pop	xhl
	ret
Timer_ModeHandler_0_Helper5:
	ld	d, w
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	VoiceSlot_ReadCurrentParams
	ld	(3524:16), a
	ld	w, d
	ld	a, e
	ld	de, 1:i3
	call	Timer_ModeHandler_0_Helper6
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ld	a, (3524:16)
	ret
MemConfig_Handler_5_Code_Helper13:
	call	VoiceSlot_ComputeWordIndex
	push	xde
	ld	xde, 3230
	ld	iy, (xde+iz)
	pop	xde
	call	VoiceSlot_UpdateCurrentPointer
	srl	iz, 1
	push	xde
	ld	xde, 3262
	ld	iy, (xde+iz)
	pop	xde
	sla	iz, 1
	and	iy, 255
	ld	xhl, (4349:16)
	ld	(xhl+iy), w
	ret
Timer_ModeHandler_0_Helper6:
	ld	a, (3822:16)
	dec	1, a
	ld	(3566:16), a
	ld	l, a
	xor	h, h
	sla	a, 1
	ld	c, a
	xor	b, b
	ld	iz, bc
	ld	xix, 3230
	ldfr_lerp	xix, 56
	lda	xix, (xix+hl)
	add	e, (xix+32)
	ldto_lerp	xix, 56
	adc	d, 0
	cp	de, 255
	jrl	ugt, VoiceSlot_FinalRetZ_Skip2
	ld	bc, (xix+iz)
	ld	xix, 61944
	cp	bc, (xix+iz)
	jrl	z, VoiceSlot_FinalRetZ_Skip
VoiceSlot_FinalRetZ_Loop:
	push	xwa
	ld	xwa, 3262
	ld	(xwa+hl), e
	pop	xwa
	ld	w, 0:opc
	ret
VoiceSlot_FinalRetZ_Skip:
	ldfr_lerp	xix, 56
	lda	xix, (xix+hl)
	cp	e, (xix+32)
	ldto_lerp	xix, 56
	jrl	ule, VoiceSlot_FinalRetZ_Loop
	ld	w, 255:opc
	jp	VoiceSlot_FinalRetZ_Return
VoiceSlot_FinalRetZ_Skip2:
	sub	de, 256
	ld	wa, de
	xor	de, de
	ldw	bc, 251
	ld	qwa, de
	div	xwa, bc
	ld	de, qwa
	inc	1, wa
	ld	bc, wa
	ld	iy, (xix+iz)
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	iy, (xhl+3)
	ld	l, (3566:16)
	xor	h, h
	cp	iy, 65535
	jrl	z, VoiceSlot_FinalRetZ_Skip3
VoiceSlot_FinalRetZ_Loop2:
	djnz16	bc, -27
	add	de, 5
	ld	xix, 61944
	cp	iy, (xix+iz)
	jrl	z, VoiceSlot_FinalRetZ_Entry
VoiceSlot_FinalRetZ_Loop3:
	ld	xix, 3230
	ld	(xix+iz), iy
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda	xix, (xix+iz)
	ld	(xix+32), e
	ldto_lerp	xix, 56
	sla	iz, 1
	xor	w, w
	jp	VoiceSlot_FinalRetZ_Return
VoiceSlot_FinalRetZ_Skip3:
	cp	bc, 1:i3
	jrl	z, VoiceSlot_FinalRetZ_Loop2
	ld	w, 255:opc
	jp	VoiceSlot_FinalRetZ_Return
VoiceSlot_FinalRetZ_Entry:
	cp	wa, (xix+hl)
	jrl	ule, VoiceSlot_FinalRetZ_Loop3
	ld	w, 255:opc
VoiceSlot_FinalRetZ_Return:
	ret
	ld	xhl, 4362
	ld	xwa, (7514:16)
	ld	(xhl), xwa
	ret
MemConfig_Handler_1_Helper3:
	ld	xhl, 4362
	push	xde
	ld	xde, (7514:16)
	ld	(xhl), xde
	pop	xde
	ld	(3302:16), wa
	ld	bc, (61999:16)
	ld	(61999:16), iy
	xor	wa, wa
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	ix, (xhl+1)
	ld	de, ix
	cp	ix, 0:i3
	jrl	z, VoiceSlot_FinalRetZ_Skip6
	ld	iy, ix
	ldw	(xhl+1), 0
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	ix, iy
	ld	iy, (xhl+3)
VoiceSlot_FinalRetZ_Loop4:
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	ix, iy
	ld	iy, (xhl+3)
	cp	iy, 65535
	jrl	z, VoiceSlot_FinalRetZ_Skip4
VoiceSlot_FinalRetZ_Entry2:
	andmi8	(xhl), 127
	ld	(xhl+5), 130
	inc	1, wa
	cp	wa, (0x0ce6:16)
	jrl	nz, VoiceSlot_FinalRetZ_Loop4
	dec	1, wa
VoiceSlot_FinalRetZ_Join:
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	(xhl+1), de
VoiceSlot_FinalRetZ_Skip4:
	cp	de, 0:i3
	jrl	z, VoiceSlot_FinalRetZ_Skip5
	push	xiy
	ld	iy, de
	call	VoiceSlot_UpdateCurrentPointer
	pop	xiy
	ld	xhl, (4349:16)
	ld	(xhl+3), iy
VoiceSlot_FinalRetZ_Skip5:
	ld	iy, ix
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	andmi8	(xhl), 127
	ld	(xhl+5), 130
	ld	(xhl+3), bc
	ld	iy, bc
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	(xhl+1), ix
	inc	1, wa
	add (62001:16), wa
	jp	VoiceSlot_FinalRetZ_Return2
VoiceSlot_FinalRetZ_Skip6:
	call	VoiceSlot_UpdateCurrentPointer
	ld	ix, iy
	ld	xhl, (4349:16)
	ld	iy, (xhl+3)
	cp	iy, 65535
	jrl	nz, VoiceSlot_FinalRetZ_Entry2
	ldw	(3302:16), 0
	ld	iy, ix
	andmi8	(xhl), 127
	jp	VoiceSlot_FinalRetZ_Join
VoiceSlot_FinalRetZ_Return2:
	ret
VoiceSlot_UpdateCurrentPointer:
	ld hl, iy
	dec 1, hl
	extz xhl
	sla xhl, 8
	add xhl, (7514:16)
	ld (4349:16), xhl
	xor xhl, xhl
	ret

VoiceSlot_ComputeWordIndex:
	pushw wa
	ld a, (3822:16)
	dec 1, a
	xor w, w
	sla wa, 1
	ld iz, wa
	extz xiz
	popw wa
	ret

VoiceSlot_ComputeIndex:
	pushw wa
	ld a, (3822:16)
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
	xor	wa, wa
	ld	(3428:16), a
	ld	(3426:16), wa
VoiceSlot_IndexDone_Join:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceSlot_ComputeIndex_Skip
	ld	de, 1:i3
	call	Timer_ModeHandler_0_Helper6
	incw	1, (3426:16)
	jp	VoiceSlot_IndexDone_Join
VoiceSlot_ComputeIndex_Skip:
	ld	xiy, 3426
	ld	xix, 13964
	cp	a, 130
	jrl	z, VoiceSlot_IndexDone_Skip5
	cp	a, 132
	jrl	z, VoiceSlot_ComputeIndex_Entry2
	call	VoiceSlot_FlagCheck
	ld	xiy, 3428
	cp	a, 0:i3
	jrl	z, VoiceSlot_IndexDone_Skip2
	ld	(xiy), 128
VoiceSlot_IndexDone_Skip2:
	cp	(3415:16), 48
	jrl	nz, VoiceSlot_IndexDone_Loop
	cp	(xiy), 128
	jrl	nz, VoiceSlot_IndexDone_Skip3
	ld	(xiy), 0
	jp	VoiceSlot_IndexDone_Loop
VoiceSlot_IndexDone_Skip3:
	ld	(xiy), 128
	ld	wa, (3426:16)
	sub	wa, 1
	jrl	nc, VoiceSlot_IndexDone_Skip4
	xor	wa, wa
VoiceSlot_IndexDone_Skip4:
	ld	(3426:16), wa
VoiceSlot_IndexDone_Loop:
	call	VoiceSlot_ComputeIndex_Helper
	jp	VoiceSlot_IndexDone_Return
VoiceSlot_IndexDone_Skip5:
	cpw	(xiy), 1
	jrl	z, VoiceSlot_IndexDone_Skip6
	cpw	(xiy), 0
	jrl	z, VoiceSlot_IndexDone_Skip6
	decm	1, (xiy)
	jp	VoiceSlot_IndexDone_Loop
VoiceSlot_IndexDone_Skip6:
	ld	(xix), 8
	jp	VoiceSlot_IndexDone_Join2
VoiceSlot_ComputeIndex_Entry2:
	cpw	(xiy), 0
	jrl	nz, VoiceSlot_IndexDone_Loop
	ld	(xix), 9
VoiceSlot_IndexDone_Join2:
	call	SerialPort_ModeHandler_0_Helper
VoiceSlot_IndexDone_Return:
	ret
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
	ld w, 0x0:opc
	jp VoiceSlot_StatusDone

VoiceSlot_SetFFAndContinue:
	ld w, 0xff:opc

VoiceSlot_StatusDone:
	ret

VoiceSlot_StatusRet:
	cp	(0x0d65:16), 0
	jrl	nz, VoiceSlot_StatusRet_Skip2
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceSlot_StatusRet_Skip
	call	VoiceSlot_FlagCheck
	cp	a, (0x0d57:16)
	jrl	z, VoiceSlot_StatusRet_Skip2
VoiceSlot_StatusRet_Skip:
	call	VoiceSlot_IndexDone
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip2:
	call	VoiceSlot_ReadCurrentParams
	ld	w, a
	and	w, 6
	stb_d8	(0x0ef4), w
	ld	w, a
	and	w, 7
	stb_d8	(0x0dc8), w
	and	a, 240
	cp	a, 144
	jrl	z, VoiceSlot_StatusRet_Skip4
	cp	a, 176
	jrl	z, VoiceSlot_StatusRet_Skip14
	cp	a, 192
	jrl	z, VoiceSlot_StatusRet_Skip8
	cp	a, 128
	jrl	z, VoiceSlot_StatusRet_Skip72
	cp	a, 208
	jrl	nz, VoiceSlot_StatusRet_Loop2
	jp	VoiceSlot_StatusRet_Join5
VoiceSlot_StatusRet_Loop2:
	ld	(0x3684:16), 0
	cp	(0x0def:16), 1
	jrl	nz, VoiceSlot_StatusRet_Skip3
	call	DisplayStr_BytecodeBlock_B_Sub
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip3:
	ld	(0x0def:16), 1
	call	DisplayStr_BytecodeBlock_B
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip4:
	cp	(0x0d65:16), 0
	jrl	z, VoiceSlot_StatusRet_Skip7
	call	VoiceSlot_FinalRetZ
	call	ToneParam_HandlerTable_BC_Helper8
	pushw	wa
	call	VoiceSlot_ComputeWordIndex
	srl	iz, 1
	popw	wa
	push	xix
	ld	xix, 0xf1a0
	cp	(xix+iz), 0x0c
	pop	xix
	jrl	nz, VoiceSlot_StatusRet_Join
	bit	2, (0xfdad:16)
	jrl	z, VoiceSlot_StatusRet_Skip5
	jp	VoiceSlot_StatusRet_Join
VoiceSlot_StatusRet_Skip5:
	ldb_d8	w, (0xfb3c)
	call	ScoopDisp_BytecodeBlock1_0x32
VoiceSlot_StatusRet_Join:
	stb_d8	(0x367c), a
	call	VoiceSlot_FinalRetZ
	stb_d8	(0x367b), a
	cp	(0x0def:16), 0
	jrl	nz, VoiceSlot_StatusRet_Skip6
	call	Display_BytecodeBlock_F_Sub3
	jp	VoiceSlot_StatusRet_Join2
VoiceSlot_StatusRet_Skip6:
	ld	(0x0def:16), 0
	call	Display_BytecodeBlock_F
VoiceSlot_StatusRet_Join2:
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip7:
	call	VoiceSlot_StatusRet_Helper
	call	VoiceSlot_FinalRetZ
	call	ToneParam_HandlerTable_BC_Helper8
	call	ToneParam_HandlerTable_BC_Helper8
	and	a, 32
	rlc a, 3	; rlc 0x03,A
	ld	e, a
	call	VoiceSlot_ReadCurrentParams
	and	a, 7
	sla	a, 1
	or	a, e
	ld	xhl, VoiceSlot_StatusRet_Tbl2
	ld	a, (xhl+a)
	stb_d8	(0x0d61), a
	call	SNS_Init_Startup
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip8:
	call	VoiceSlot_FinalRetZ
	call	ToneParam_HandlerTable_BC_Helper8
	cp	a, 72
	jrl	z, VoiceSlot_StatusRet_Skip10
	stb_d8	(0x11bb), a
	stb_d8	(0x905b), a
	call	VoiceSlot_FinalRetZ
	ld	h, a
	push	xhl
	call	VoiceSlot_FinalRetZ
	bit	0, (0x0dc8:16)
	jrl	z, VoiceSlot_StatusRet_Skip9
	or	a, 128
VoiceSlot_StatusRet_Skip9:
	pop	xhl
	stb_d8	(0x11bd), a
	ld	l, a
	call	VoiceSlot_FinalRetZ
	stb_d8	(0x11bc), a
	ld	h, a
	call	PartCtrl_WriteProgramChange
	stb_d8	(0x11be), h
	ld	(0x0def:16), 1
	call	Display_BytecodeBlock_F_Sub
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip10:
	call	VoiceSlot_FinalRetZ
	cp	a, 0:i3
	jrl	nz, VoiceSlot_StatusRet_Loop2
	call	VoiceSlot_FinalRetZ
	bit	0, (0x0dc8:16)
	jrl	z, VoiceSlot_StatusRet_Skip11
	or	a, 128
VoiceSlot_StatusRet_Skip11:
	stb_d8	(0x3686), a
	call	VoiceSlot_FinalRetZ
	stb_d8	(0x3687), a
	bit	1, (0x0ef4:16)
	jrl	z, VoiceSlot_StatusRet_Skip12
	or	a, 128
VoiceSlot_StatusRet_Skip12:
	stb_d8	(0x0ef5), a
	cp	(0x0d65:16), 3
	jrl	z, VoiceSlot_StatusRet_Skip13
	ld	(0x0def:16), 4
	call	DisplayMode_Handler_3_Helper10_Helper
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip13:
	ld	(0x0def:16), 12
	call	DisplayStr_BytecodeBlock_D
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Loop3:
	jp	VoiceSlot_StatusRet_Loop2
VoiceSlot_StatusRet_Skip14:
	call	VoiceSlot_FinalRetZ
	call	ToneParam_HandlerTable_BC_Helper8
	and	a, 127
	ldb_d8	h, (0x0dc8)
	and	h, 4
	sla	h, 5
	or	a, h
	stb_d8	(0x10f1), a
	cp	a, 72
	jrl	nz, VoiceSlot_StatusRet_Skip35
	call	VoiceSlot_FinalRetZ
	cp	a, 5:i3
	jrl	z, VoiceSlot_StatusRet_Skip25
	cp	a, 6:i3
	jrl	z, VoiceSlot_StatusRet_Skip25
	cp	a, 7:i3
	jrl	z, VoiceSlot_StatusRet_Skip15
	cp	a, 3:i3
	jrl	z, VoiceSlot_StatusRet_Skip18
	cp	a, 4:i3
	jrl	z, VoiceSlot_StatusRet_Skip22
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Skip15:
	call	VoiceSlot_FinalRetZ
	ld	c, a
	pushw	bc
	call	VoiceSlot_FinalRetZ
	popw	bc
	ldb_d8	a, (0x0d65)
	cp	a, 3:i3
	jrl	z, VoiceSlot_StatusRet_Skip16
	cp	a, 2:i3
	jrl	z, VoiceSlot_StatusRet_Skip17
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Skip16:
	ld	(0x0def:16), 15
	pushw	bc
	call	Display_UpdateRegion0
	popw	bc
	call	VoiceCtrl_ParamSetupBytecode_Sub_Helper2
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip17:
	ld	(0x0def:16), 4
	pushw	bc
	call	Display_UpdateRegion0
	popw	bc
	call	VoiceCtrl_ParamSetupBytecode_Sub_Helper
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip18:
	call	VoiceSlot_FinalRetZ
	stb_d8	(0x10f3), a
	call	VoiceSlot_FinalRetZ
	ldb_d8	l, (0x0dc8)
	ld	h, l
	and	l, 1
	rrc	l
	ldb_d8	w, (0x10f3)
	or	w, l
	stb_d8	(0x10f3), w
	and	h, 2
	rrc h, 2	; rrc 0x02,H
	or	a, h
	stb_d8	(0x10f5), a
	ldfr_berp	a, 60
	and	a, 7
	ldto_berp	a, 60
	jrl	z, VoiceSlot_StatusRet_Skip19
	call	ParamPopup_ApcMode
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip19:
	bit	3, a
	jrl	z, VoiceSlot_StatusRet_Skip20
	call	ParamPopup_ApcMemory
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip20:
	ldfr_berp	a, 60
	and	a, 224
	ldto_berp	a, 60
	jrl	z, VoiceSlot_StatusRet_Skip21
	call	ParamPopup_AccompPart
VoiceSlot_StatusRet_Skip21:
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip22:
	call	VoiceSlot_FinalRetZ
	stb_d8	(0x10f3), a
	call	VoiceSlot_FinalRetZ
	ldb_d8	l, (0x0dc8)
	ld	h, l
	and	l, 1
	rrc	l
	ldb_d8	w, (0x10f3)
	or	w, l
	stb_d8	(0x10f3), w
	and	h, 2
	rrc h, 2	; rrc 0x02,H
	or	a, h
	stb_d8	(0x10f5), a
	bit	4, a
	jrl	z, VoiceSlot_StatusRet_Skip23
	call	ParamPopup_DynamicAccomp
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip23:
	bit	6, a
	jrl	z, VoiceSlot_StatusRet_Skip24
	call	ParamPopup_TechniChord
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip24:
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Skip25:
	ldfr_berp	a, 56
	stb_d8	(0x10f2), a
	call	VoiceSlot_FinalRetZ
	ld	c, a
	bit	0, (0x0dc8:16)
	jrl	z, VoiceSlot_StatusRet_Skip26
	or	c, 128
VoiceSlot_StatusRet_Skip26:
	pushw	bc
	call	VoiceSlot_FinalRetZ
	popw	bc
	bit	1, (0x0dc8:16)
	jrl	z, VoiceSlot_StatusRet_Skip27
	or	a, 128
VoiceSlot_StatusRet_Skip27:
	ld	xiy, 0x368c
	ldfr_berp	a, 60
	and	a, 192
	ldto_berp	a, 60
	jrl	nz, VoiceSlot_StatusRet_Skip28
	ldfr_berp	a, 60
	and	a, 48
	ldto_berp	a, 60
	jrl	nz, VoiceSlot_StatusRet_Skip30
	bit	2, a
	jrl	nz, VoiceSlot_StatusRet_Skip32
	bit	3, a
	jrl	nz, VoiceSlot_StatusRet_Skip34
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Skip28:
	ldfr_berp	c, 60
	and	c, 192
	ldto_berp	c, 60
	jrl	z, VoiceSlot_StatusRet_Loop
	bit	6, c
	jrl	z, VoiceSlot_StatusRet_Skip29
	ld	(xiy), 3
	jp	VoiceSlot_StatusRet_Join3
VoiceSlot_StatusRet_Skip29:
	ld	(xiy), 4
VoiceSlot_StatusRet_Join3:
	call	Display_ModePopupDispatch
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Loop:
	set	5, (0x0d54:16)
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip30:
	ldfr_berp	c, 60
	and	c, 48
	ldto_berp	c, 60
	jrl	z, VoiceSlot_StatusRet_Loop
	ld	(xiy), 7
	bit	4, c
	jrl	nz, VoiceSlot_StatusRet_Skip31
	ld	(xiy), 11
VoiceSlot_StatusRet_Skip31:
	call	Display_ModePopupDispatch
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip32:
	ld	(xiy), 5
	cp	(0x10f2:16), 6
	jrl	nz, VoiceSlot_StatusRet_Skip33
	ld	(xiy), 12
VoiceSlot_StatusRet_Skip33:
	call	Display_ModePopupDispatch
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip34:
	ld	(xiy), 6
	call	Display_ModePopupDispatch
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip35:
	call	VoiceSlot_FinalRetZ
	stb_d8	(0x10f2), a
	call	VoiceSlot_FinalRetZ
	ldb_d8	l, (0x0dc8)
	ld	h, l
	and	l, 1
	rrc	l
	or	a, l
	stb_d8	(0x10f3), a
	push	xhl
	call	VoiceSlot_FinalRetZ
	pop	xhl
	and	h, 2
	rrc h, 2	; rrc 0x02,H
	or	a, h
	stb_d8	(0x10f5), a
	ldb_d8	a, (0x10f1)
	cp	a, 0:i3
	jrl	c, VoiceSlot_StatusRet_Skip36
	cp	a, 13
	jrl	ule, VoiceSlot_StatusRet_Skip54
	cp	a, 14
	jrl	z, VoiceSlot_StatusRet_Skip54
	cp	a, 15
	jrl	z, VoiceSlot_StatusRet_Skip54
	cp	a, 80
	jrl	z, VoiceSlot_StatusRet_Skip54
	cp	a, 81
	jrl	z, VoiceSlot_StatusRet_Skip54
	cp	a, 144
	jrl	z, VoiceSlot_StatusRet_Skip54
	cp	a, 112
	jrl	z, VoiceSlot_StatusRet_Skip37
	cp	a, 152
	jrl	z, VoiceSlot_StatusRet_Skip37
	cp	a, 19
	jrl	z, VoiceSlot_StatusRet_Skip37
	cp	a, 20
	jrl	z, VoiceSlot_StatusRet_Skip37
	cp	a, 16
	jrl	z, VoiceSlot_StatusRet_Skip37
	cp	a, 17
	jrl	z, VoiceSlot_StatusRet_Skip37
	cp	a, 18
	jrl	z, VoiceSlot_StatusRet_Skip37
VoiceSlot_StatusRet_Skip36:
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Skip37:
	ldb_d8	a, (0x10f2)
	cp	a, 0:i3
	jrl	z, VoiceSlot_StatusRet_Skip38
	cp	a, 3:i3
	jrl	z, VoiceSlot_StatusRet_Skip38
	cp	a, 3:i3
	jrl	z, VoiceSlot_StatusRet_Skip38
	cp	a, 3:i3
	jrl	z, VoiceSlot_StatusRet_Skip38
	cp	a, 2:i3
	jrl	z, VoiceSlot_StatusRet_Skip38
	cp	a, 1:i3
	jrl	z, VoiceSlot_StatusRet_Skip38
	cp	a, 11
	jrl	z, VoiceSlot_StatusRet_Skip38
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Skip38:
	ldb_d8	a, (0x10f3)
	cp	(0x10f1:16), 112
	jrl	nz, VoiceSlot_StatusRet_Skip41
	ldb_d8	l, (0x10f2)
	cp	l, 0:i3
	jrl	z, VoiceSlot_StatusRet_Skip40
	cp	l, 3:i3
	jrl	z, VoiceSlot_StatusRet_Skip53
	cp	l, 2:i3
	jrl	z, VoiceSlot_StatusRet_Skip39
	jp	VoiceSlot_StatusRet_Loop3
	call	VoiceSlot_StatusRet_Helper6
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip39:
	call	ParamPopup_KeyNameBracketed
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip40:
	bit	2, (0x10f5:16)
	jrl	z, VoiceSlot_StatusRet_Loop3
	call	VoiceSlot_StatusRet_Helper10
	jp	VoiceSlot_StatusRet_Return
	bit	7, (0x10f5:16)
	jrl	z, VoiceSlot_StatusRet_Loop3
	call	ParamPopup_TotalReverb
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip41:
	cp	(0x10f1:16), 152
	jrl	nz, VoiceSlot_StatusRet_Skip47
	ldb_d8	l, (0x10f2)
	cp	l, 11
	jrl	z, VoiceSlot_StatusRet_Skip43
	cp	l, 1:i3
	jrl	z, VoiceSlot_StatusRet_Skip42
	cp	l, 3:i3
	jrl	nz, VoiceSlot_StatusRet_Skip52
	ldfr_berp	a, 60
	ldb_d8	a, (0x10f5)
	and	a, 1
	ldto_berp	a, 60
	jrl	z, VoiceSlot_StatusRet_Skip52
	call	ParamPopup_Msa
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip42:
	and	a, 127
	call	ParamPopup_PanelMemory
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip43:
	ldb_d8	a, (0x0dc8)
	and	a, 2
	cp	a, 0:i3
	jr	nz, VoiceSlot_StatusRet_Skip44
	ldb_d8	a, (0x10f5)
	and	a, 64
	cp	a, 0:i3
	jr	nz, VoiceSlot_StatusRet_Skip45
VoiceSlot_StatusRet_Skip44:
	ldb_d8	a, (0x0dc8)
	and	a, 1
	call	ParamPopup_FadeIn
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip45:
	ldb_d8	a, (0x10f3)
	and	a, 64
	cp	a, 0:i3
	jr	z, VoiceSlot_StatusRet_Skip46
	ld	a, 1:opc
VoiceSlot_StatusRet_Skip46:
	call	ParamPopup_FadeOut
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip47:
	cp	(0x10f1:16), 19
	jrl	nz, VoiceSlot_StatusRet_Skip48
	cp	(0x10f2:16), 3
	jrl	nz, VoiceSlot_StatusRet_Skip52
	ld	hl, 1:i3
	jp	VoiceSlot_StatusRet_Join4
VoiceSlot_StatusRet_Skip48:
	cp	(0x10f1:16), 20
	jrl	nz, VoiceSlot_StatusRet_Skip49
	cp	(0x10f2:16), 3
	jrl	nz, VoiceSlot_StatusRet_Skip52
	ld	hl, 2:i3
	jp	VoiceSlot_StatusRet_Join4
VoiceSlot_StatusRet_Skip49:
	cp	(0x10f1:16), 16
	jrl	nz, VoiceSlot_StatusRet_Skip50
	cp	(0x10f2:16), 3
	jrl	nz, VoiceSlot_StatusRet_Skip52
	ld	hl, 3:i3
	jp	VoiceSlot_StatusRet_Join4
VoiceSlot_StatusRet_Skip50:
	cp	(0x10f1:16), 17
	jrl	nz, VoiceSlot_StatusRet_Skip51
	cp	(0x10f2:16), 3
	jrl	nz, VoiceSlot_StatusRet_Skip52
	ld	hl, 4:i3
	jp	VoiceSlot_StatusRet_Join4
VoiceSlot_StatusRet_Skip51:
	cp	(0x10f1:16), 18
	jrl	nz, VoiceSlot_StatusRet_Skip52
	cp	(0x10f2:16), 3
	jrl	nz, VoiceSlot_StatusRet_Skip52
	ld	hl, 5:i3
	jp	VoiceSlot_StatusRet_Join4
VoiceSlot_StatusRet_Skip52:
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Skip53:
	xor	hl, hl
VoiceSlot_StatusRet_Join4:
	call	ParamPopup_AccompVolume
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip54:
	ldb_d8	a, (0x10f1)
	cp	a, 144
	jrl	z, VoiceSlot_StatusRet_Skip71
	cp	a, 80
	jrl	z, VoiceSlot_StatusRet_Skip67
	cp	a, 81
	jrl	z, VoiceSlot_StatusRet_Skip67
	cp	a, 0:i3
	jrl	c, VoiceSlot_StatusRet_Skip55
	cp	a, 13
	jrl	ule, VoiceSlot_StatusRet_Skip56
	cp	a, 14
	jrl	z, VoiceSlot_StatusRet_Skip56
	cp	a, 15
	jrl	z, VoiceSlot_StatusRet_Skip56
VoiceSlot_StatusRet_Skip55:
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Skip56:
	ldb_d8	a, (0x10f2)
	cp	a, 3:i3
	jrl	z, VoiceSlot_StatusRet_Helper2
	cp	a, 4:i3
	jrl	z, VoiceSlot_StatusRet_Skip57
	cp	a, 12
	jrl	z, VoiceSlot_StatusRet_Skip62
	cp	a, 8
	jrl	z, VoiceSlot_StatusRet_Skip63
	cp	a, 9
	jrl	z, VoiceSlot_StatusRet_Skip64
	cp	a, 10
	jrl	z, VoiceSlot_StatusRet_Skip65
	cp	a, 11
	jrl	z, VoiceSlot_StatusRet_Skip66
	cp	a, 5:i3
	jrl	z, VoiceSlot_StatusRet_Skip60
	cp	a, 7:i3
	jrl	z, VoiceSlot_StatusRet_Skip61
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Helper2:
	call	ParamPopup_PartVolume
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip57:
	ldb_d8	a, (0x10f5)
	bit	3, a
	jrl	nz, VoiceSlot_StatusRet_Skip58
	bit	6, a
	jrl	nz, VoiceSlot_StatusRet_Skip59
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Skip58:
	call	ParamPopup_PartSustain
	jp	VoiceSlot_StatusRet_Return
	call	ParamPopup_PartDspEffectOff
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip59:
	call	ParamPopup_PartEffect
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip60:
	call	ParamPopup_PartDspEffectLevel
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip61:
	call	ParamPopup_PartReverb
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip62:
	ldfr_berp	a, 60
	ldb_d8	a, (0x10f5)
	and	a, 192
	ldto_berp	a, 60
	jrl	z, VoiceSlot_StatusRet_Loop3
	call	ParamPopup_PartTimbre
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip63:
	call	ParamPopup_PartPanpot
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip64:
	call	ParamPopup_PartKeyShift
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip65:
	call	ParamPopup_PartTuning
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip66:
	call	ParamPopup_PartBendSense
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip67:
	jp	VoiceSlot_StatusRet_Loop3
	jp	VoiceSlot_StatusRet_Loop3
	jp	VoiceSlot_StatusRet_Loop3
	call	VoiceSlot_StatusRet_Helper2
	jp	VoiceSlot_StatusRet_Return
	ldb_d8	a, (0x10f5)
	bit	3, a
	jrl	nz, VoiceSlot_StatusRet_Skip68
	bit	4, a
	jrl	nz, VoiceSlot_StatusRet_Skip69
	bit	7, a
	jrl	nz, VoiceSlot_StatusRet_Skip70
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Skip68:
	call	ParamPopup_PartSustain
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip69:
	call	VoiceSlot_StatusRet_Helper5
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip70:
	call	ParamPopup_PartTremolo
	jp	VoiceSlot_StatusRet_Return
	call	VoiceSlot_StatusRet_Helper7
	jp	VoiceSlot_StatusRet_Return
	call	VoiceSlot_StatusRet_Helper8
	jp	VoiceSlot_StatusRet_Return
	call	VoiceSlot_StatusRet_Helper9
	jp	VoiceSlot_StatusRet_Return
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Skip71:
	ldb_d8	a, (0x10f2)
	jp	VoiceSlot_StatusRet_Loop3
	ldb_d8	a, (0x10f3)
	bit	0, a
	jrl	nz, VoiceSlot_StatusRet_Loop3
	bit	1, a
	jrl	nz, VoiceSlot_StatusRet_Loop3
	bit	2, a
	jrl	nz, VoiceSlot_StatusRet_Loop3
	bit	4, a
	jrl	nz, VoiceSlot_StatusRet_Loop3
	jp	VoiceSlot_StatusRet_Loop3
VoiceSlot_StatusRet_Skip72:
	call	VoiceSlot_FinalRetZ
	ld	xiy, 0x368c
	cp	a, 128
	jrl	z, VoiceSlot_StatusRet_Skip74
	cp	a, 133
	jrl	z, VoiceSlot_StatusRet_Skip76
	cp	a, 134
	jrl	z, VoiceSlot_StatusRet_Skip77
	cp	a, 129
	jrl	z, VoiceSlot_StatusRet_Skip78
	cp	a, 132
	jrl	z, VoiceSlot_StatusRet_Skip73
	jp	VoiceSlot_StatusRet_Loop2
VoiceSlot_StatusRet_Skip73:
	ld	(xiy), 9
	call	SerialPort_ModeHandler_0_Helper
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip74:
	call	ToneParam_HandlerTable_BC_Helper8
	ld	c, a
	pushw	bc
	call	VoiceSlot_ReadCurrentParams
	ld	l, a
	rrc	a
	and	a, 128
	popw	bc
	or	a, c
	srl	l, 1
	and	l, 1
	ld	w, l
	ld	(0x0ef2:16), wa
	cp	(0x0d65:16), 3
	jrl	z, VoiceSlot_StatusRet_Skip75
	ld	(0x0def:16), 7
	call	VoiceSlot_StatusRet_Helper3
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip75:
	ld	(0x0def:16), 17
	call	Display_UpdateRegion0
	call	VoiceSlot_StatusRet_Helper4
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip76:
	ld	(xiy), 1
	call	Display_ModePopupDispatch
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip77:
	ld	(xiy), 2
	call	Display_ModePopupDispatch
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip78:
	cp	(0x0d65:16), 0
	jrl	nz, VoiceSlot_StatusRet_Skip79
	call	VoiceSlot_IndexDone
VoiceSlot_StatusRet_Skip79:
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Join5:
	call	VoiceSlot_FinalRetZ
	cp	a, 208
	jrl	z, VoiceSlot_StatusRet_Skip80
	cp	a, 209
	jrl	z, VoiceSlot_StatusRet_Skip82
	cp	a, 210
	jrl	z, VoiceSlot_StatusRet_Skip84
	cp	a, 211
	jrl	z, VoiceSlot_StatusRet_Skip86
	jp	VoiceSlot_StatusRet_Loop2
VoiceSlot_StatusRet_Skip80:
	call	ToneParam_HandlerTable_BC_Helper8
	stb_d8	(0x3685), a
	ld	(0x3684:16), 5
	cp	(0x0def:16), 3
	jrl	nz, VoiceSlot_StatusRet_Skip81
	call	DisplayStr_BytecodeBlock_B_Sub
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip81:
	ld	(0x0def:16), 3
	call	DisplayStr_BytecodeBlock_B
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip82:
	call	ToneParam_HandlerTable_BC_Helper8
	stb_d8	(0x3685), a
	ld	(0x3684:16), 2
	cp	(0x0def:16), 3
	jrl	nz, VoiceSlot_StatusRet_Skip83
	call	DisplayStr_BytecodeBlock_B_Sub
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip83:
	ld	(0x0def:16), 3
	call	DisplayStr_BytecodeBlock_B
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip84:
	call	ToneParam_HandlerTable_BC_Helper8
	stb_d8	(0x3685), a
	ld	(0x3684:16), 1
	call	VoiceSlot_FinalRetZ
	stb_d8	(0x1112), a
	cp	(0x0def:16), 3
	jrl	nz, VoiceSlot_StatusRet_Skip85
	call	DisplayStr_BytecodeBlock_B_Sub
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip85:
	ld	(0x0def:16), 3
	call	DisplayStr_BytecodeBlock_B
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip86:
	call	ToneParam_HandlerTable_BC_Helper8
	stb_d8	(0x3685), a
	ld	(0x3684:16), 3
	cp	(0x0def:16), 3
	jrl	nz, VoiceSlot_StatusRet_Skip87
	call	DisplayStr_BytecodeBlock_B_Sub
	jp	VoiceSlot_StatusRet_Return
VoiceSlot_StatusRet_Skip87:
	ld	(0x0def:16), 3
	call	DisplayStr_BytecodeBlock_B
VoiceSlot_StatusRet_Return:
	ret
ToneParam_HandlerTable_BC_Helper8:
	call	VoiceSlot_FinalRetZ
	call	VoiceSlot_FinalRetZ
	ret
; Display_ModePopupDispatch -- the pop-up id for the display mode (0x0D65), from
; Display_ModePopupIds, goes to (0x0DEF) before Display_UpdateRegion0; then a call
; through Display_ModePopupDispatch_Tbl[(0x0D65) & 3].
Display_ModePopupDispatch:
	ldb_d8	a, (0x0d65)
	ld	xhl, Display_ModePopupIds
	ld	a, (xhl+a)
	stb_d8	(0x0def), a
	call	Display_UpdateRegion0
	ldb_d8	l, (0x0d65)
	and	hl, 3
	sla	hl, 2
	extz	xhl
	push	xix
	ld	xix, Display_ModePopupDispatch_Tbl
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
	ret
VoiceState_SaveAndRestore:
	call	DMA_ChannelHandler_3_Helper
	call	DisplayStr_StyleSectionInit
	ret
	; Handler dispatch table, 16 B.  Read by VoiceSlot_StatusRet (0xEFC788): `ld xix, Display_ModePopupDispatch_Tbl`
	; indexed with stride 4 (`sla hl, 2`)
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
Display_ModePopupDispatch_Tbl:
	.long	SerialPort_ModeHandler_0_Helper
	.long	DisplayStr_BytecodeBlock_C
	.long	DisplayStr_BytecodeBlock_C
	.long	VoiceState_SaveAndRestore
	; Byte data, 4 B.  Read by VoiceSlot_StatusRet (0xEFC788): `ld xhl, Display_ModePopupIds`
	; indexed with stride 4 (`sla hl, 2`)
Display_ModePopupIds:
	.byte	0x00, 0x05, 0x05, 0x0f
	; Byte data, 12 B.  Read by VoiceSlot_StatusRet (0xEFC788): `ld xhl, VoiceSlot_StatusRet_Tbl2`
	; reader VoiceSlot_StatusRet: `ld xhl, VoiceSlot_StatusRet_Tbl2` then `ld_rr8b a, xhl, a`
VoiceSlot_StatusRet_Tbl2:
	.byte	0x00, 0x06, 0x04, 0x05, 0x03, 0x07, 0x02, 0x07, 0x01, 0x07, 0x07, 0x07
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
	ld	wa, (xiy+iz)
	ld (xhl), wa
	srl iz, 1
	ldfr_lerp XIY, 0x38
	lda	xiy, (xiy+iz)
	ld a, (xiy + 32)
	ldto_lerp XIY, 0x38
	ld (xhl + 2), a
	ld a, (3415:16)
	ld (xhl + 3), a
	ld wa, (3416:16)
	ld (xhl + 4), wa
	ld wa, (3418:16)
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

VoiceState_DataBlock1:
	pushw	wa
	push	xhl
	push	xiz
	push	xiy
	call	VoiceState_RestoreEntry
	ld	a, (xhl+3)
	ld	(3415:16), a
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
	ld	(xiy+iz), wa
	srl iz, 1
	ld a, (xhl + 2)
	ldfr_lerp XIY, 0x38
	lda	xiy, (xiy+iz)
	ld (xiy + 32), a
	ldto_lerp XIY, 0x38
	ret

VoiceState_RestoreDone:
	ld wa, (xhl + 4)
	ld (3416:16), wa
	ld wa, (xhl + 6)
	ld (3418:16), wa
	ret
VoiceState_DataBlock2:
	push	xhl
	push	xiz
	push	xiy
	push	xix
	and	a, 7
	sla	a, 3
	xor	w, w
	exts	xwa
	add	xwa, 3583
	ld	xix, xwa
	call	VoiceSlot_ComputeWordIndex
	ld	xiy, 3230
	ld	wa, (xiy+iz)
	cp	(xix), wa
	jrl	nz, VoiceState_DataBlock2_Code_Skip3
	srl	iz, 1
	ldfr_lerp	xiy, 56
	lda	xiy, (xiy+iz)
	ld	a, (xiy+32)
	ldto_lerp	xiy, 56
	cp	(xix+2), a
	jrl	ule, VoiceState_DataBlock2_Code_Skip
	ld	w, 3:opc
	jp	VoiceState_DataBlock2_Epilogue
VoiceState_DataBlock2_Code_Skip:
	jrl	z, VoiceState_DataBlock2_Code_Skip2
	ld	w, 2:opc
	jp	VoiceState_DataBlock2_Epilogue
VoiceState_DataBlock2_Code_Skip2:
	ld	w, 1:opc
	jp	VoiceState_DataBlock2_Epilogue
VoiceState_DataBlock2_Code_Skip3:
	ld	iy, wa
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	wa, (xhl+1)
	cp	wa, 0:i3
	jrl	z, VoiceState_DataBlock2_Code_Skip4
	cp	wa, (xix)
	jrl	z, VoiceState_DataBlock2_Code_Skip5
	jp	VoiceState_DataBlock2_Code_Skip3
VoiceState_DataBlock2_Code_Skip4:
	ld	w, 3:opc
	jp	VoiceState_DataBlock2_Epilogue
VoiceState_DataBlock2_Code_Skip5:
	ld	w, 2:opc
VoiceState_DataBlock2_Epilogue:
	pop	xix
	pop	xiy
	pop	xiz
	pop	xhl
	ret
MemConfig_Handler_1_Helper4:
	push	xhl
	xor	w, w
	and	a, 7
	sla	a, 3
	exts	xwa
	add	xwa, 3583
	ld	xhl, xwa
	ld	hl, (xhl+4)
	cp hl, (3416:16)
	jrl	ule, VoiceState_DataBlock2_Code_Skip6
	ld	w, 3:opc
	jp	VoiceState_DataBlock2_Epilogue2
VoiceState_DataBlock2_Code_Skip6:
	jrl	z, VoiceState_DataBlock2_Code_Skip7
	ld	w, 2:opc
	jp	VoiceState_DataBlock2_Epilogue2
VoiceState_DataBlock2_Code_Skip7:
	ld	w, 1:opc
VoiceState_DataBlock2_Epilogue2:
	pop	xhl
	ret
MemConfig_Handler_4_Helper6:
	pushw wa
	push XHL
	push XIX
	push XIY
	ld a, (0x0eee:16)
	dec 1,A
	exts WA
	sla WA, 0x01
	ld IX,WA
	push XDE
	ld XDE,0x00000c9e
	ld	wa, (xde+ix)
	pop XDE
	cp WA,0xffff
	jrl z, .Lc_efd255
	cp wa, 0:i3
	jrl z, .Lc_efd255
	ld IY,WA
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (0x10fd:16)
	cpw (XHL+0x01), 0x0000
	jrl z, .Lc_efd242
.Lc_efd238:
	pop XIY
	pop XIX
	pop XHL
	popw wa
	ld W, 0xff:opc
	jp VoiceState_DataBlock2_Return10
.Lc_efd242:
	srl IX, 0x01
	push XDE
	ld XDE,0x00000cbe
	cp	(xde+ix), 0x05
	pop XDE
	jrl nz, .Lc_efd238
.Lc_efd255:
	pop XIY
	pop XIX
	pop XHL
	popw wa
	ld W, 0x00:opc
VoiceState_DataBlock2_Return10:
	ret
ToneParam_ModeGuardEntry_Helper4:
	push XHL
	call VoiceSlot_ReadCurrentParams
	cp A,0x84
	jrl z, .Lc_efd2d0
	ld A, 0x07:opc
	call VoiceSlot_SaveState
	xor BC,BC
	ld l, (0x0eee:16)
	xor H,H
	dec 1,HL
	sla HL, 0x01
	push XDE
	ld XDE,0x00000c9e
	ld	wa, (xde+hl)
	pop XDE
	cp WA,0xffff
	jrl z, .Lc_efd2c1
	cp wa, 0:i3
	jrl z, .Lc_efd2c1
.Lc_efd292:
	push XHL
	pushw bc
	pushw de
	push XIY
	push XIX
	push XIZ
	call VoiceSlot_FinalRetZ
	pop XIZ
	pop XIX
	pop XIY
	popw de
	popw bc
	pop XHL
	inc 1,BC
	cp c, 6:i3
	jrl ugt, .Lc_efd2c1
	cp A,0x81
	jrl z, .Lc_efd292
	cp A,0x82
	jrl z, .Lc_efd2c1
	cp A,0x84
	jrl z, .Lc_efd2c1
	ld W, 0xff:opc
	jp VoiceState_DataBlock2_Join6
.Lc_efd2c1:
	ld W, 0x00:opc
VoiceState_DataBlock2_Join6:
	pop XHL
	pushw wa
	ld A, 0x07:opc
	call VoiceSlot_RestoreState
	popw wa
	jp VoiceState_DataBlock2_Return11
.Lc_efd2d0:
	ld bc, 2:i3
	pop XHL
VoiceState_DataBlock2_Return11:
	ret
VoiceState_DataBlock2_Helper7:
	push	xhl
	ld	a, (3822:16)
	dec	1, a
	ld	w, 3:opc
	mul	wa, w
	ld	hl, wa
	ld	w, 255:opc
	push	xde
	ld	xde, 62032
	bit	7, (xde+hl)
	pop	xde
	jrl	z, VoiceState_DataBlock2_Epilogue3
	ld	w, 0:opc
VoiceState_DataBlock2_Epilogue3:
	pop	xhl
	ret
DisplayMode_Handler_3_Helper17:
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	cp	wa, 65535
	jrl	z, VoiceState_DataBlock2_Return
	call	DisplayMode_Handler_3_Helper18
	bit	7, a
	jrl	nz, VoiceState_DataBlock2_Return
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	cp	wa, 65535
	jrl	nz, DisplayMode_Handler_3_Helper17
VoiceState_DataBlock2_Return:
	ret
DisplayMode_Handler_3_Helper18:
	push	xix
	call	TempoRingBuf_SaveReadPos
	call	TempoRingBuf_ReadAlternate
	ld	wa, hl
	pop	xix
	ret
Timer_ModeHandler_0_Helper7:
	call TempoRingBuf_CheckEmpty
	ld WA,HL
	cp wa, 0:i3
	jrl z, .Lc_efd339
	ld W, 0x00:opc
	jp VoiceState_DataBlock2_Return12
.Lc_efd339:
	ld W, 0xff:opc
VoiceState_DataBlock2_Return12:
	ret
SystemInit_StepHandler_0_Helper:
	call	Rhythm_TransposeTrampBlock
	pushw	de
	ld	a, (64602:16)
	ld	d, (64612:16)
	and	d, 15
	call	Rhythm_DispatchNote_Tramp
	popw	de
	bit	7, (0x1108:16)
	jrl	nz, VoiceState_DataBlock2_Return2
	mul	wa, e
VoiceState_DataBlock2_Return2:
	ret
ToneParam_Evt09_BytecodeHandler_Helper2:
	cp	(3429:16), 3
	jrl	z, VoiceState_DataBlock2_Skip7
VoiceState_DataBlock2_Loop:
	ld	w, 0:opc
	jp	VoiceState_DataBlock2_Return3
VoiceState_DataBlock2_Skip7:
	call	VoiceState_DataBlock2_Helper8
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Loop
	call	VoiceState_DataBlock2_Helper
	cp	w, 0:i3
	jrl	nz, VoiceState_DataBlock2_Return3
	ld	w, 104:opc
	call	MIDI_SendSysExFromW
	ld	w, 1:opc
	jp	VoiceState_DataBlock2_Return3
VoiceState_DataBlock2_Return3:
	ret
VoiceCtrl_ParamSetupBytecode_Helper9:
	ld	a, 3:opc
	call	VoiceSlot_SaveState
VoiceState_DataBlock2_Loop2:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Loop3
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	nz, VoiceState_DataBlock2_Loop2
VoiceState_DataBlock2_Loop3:
	call	Timer_ParamCompareAlt_Helper5
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Skip10
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Skip10
	call	VoiceState_DataBlock2_Helper8
	cp	w, 0:i3
	jrl	nz, VoiceState_DataBlock2_Loop3
VoiceState_DataBlock2_Loop4:
	call	Timer_ParamCompareAlt_Helper5
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Skip8
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Loop5
	call	VoiceState_DataBlock2_Helper8
	cp	w, 0:i3
	jrl	nz, VoiceState_DataBlock2_Loop4
	call	VoiceState_DataBlock2_Helper2
	jp	VoiceState_DataBlock2_Loop4
VoiceState_DataBlock2_Loop5:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Skip9
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Skip9
VoiceState_DataBlock2_Skip8:
	call	VoiceState_DataBlock2_Helper8
	cp	w, 0:i3
	jrl	nz, VoiceState_DataBlock2_Loop5
	call	VoiceState_DataBlock2_Helper2
VoiceState_DataBlock2_Skip9:
	ld	w, 0:opc
	jp	VoiceState_DataBlock2_Return4
VoiceState_DataBlock2_Skip10:
	ld	a, 3:opc
	call	VoiceSlot_RestoreState
	ld	w, 255:opc
VoiceState_DataBlock2_Return4:
	ret
VoiceState_DataBlock2_Helper8:
	push	xiy
	push	xix
	ld	a, 2:opc
	call	VoiceSlot_SaveState
	ld	a, (3822:16)
	dec	1, a
	exts	wa
	ld	hl, wa
	sla	hl, 1
	push	xde
	ld	xde, 3230
	ld	wa, (xde+hl)
	ld	(10431:16), wa
	srl	hl, 1
	ld	xde, 3262
	ld	a, (xde+hl)
	pop	xde
	xor	w, w
	ld	(10433:16), wa
	call	VoiceBank_ProcessCommand
	ld	xix, 3765
	ld	a, (xix)
	and	a, 240
	cp	a, 176
	jrl	nz, VoiceState_DataBlock2_Skip11
	cp	(xix+2), 72
	jrl	nz, VoiceState_DataBlock2_Skip11
	cp	(xix+3), 7
	jrl	nz, VoiceState_DataBlock2_Skip11
	ld	a, (xix+5)
	bit	4, a
	jrl	z, VoiceState_DataBlock2_Skip11
	ld	w, 0:opc
	jp	VoiceState_DataBlock2_Join2
VoiceState_DataBlock2_Skip11:
	ld	w, 255:opc
VoiceState_DataBlock2_Join2:
	ld	a, 2:opc
	call	VoiceSlot_RestoreState
	pop	xix
	pop	xiy
	ret
	push	xwa
	ld	xwa, (4349:16)
	ldfr_lerp	xwa, 56
	pop	xwa
	push_lerp	56
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	and	(0x0f56:16), 254
	ld	a, 4:opc
	call	VoiceSlot_SaveState
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Skip12
VoiceState_DataBlock2_Loop6:
	call	Timer_ParamCompareAlt_Helper5
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Skip12
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceState_DataBlock2_Loop6
	call	VoiceSlot_DispatchRet
VoiceState_DataBlock2_Skip12:
	xor	a, a
	call	VoiceSlot_SaveState
	call	MemConfig_VoiceSlotLookup
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceState_DataBlock2_Skip14
	jp	VoiceState_DataBlock2_Entry2
VoiceState_DataBlock2_Loop7:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Skip15
	call	VoiceSlot_ComputeWordIndex
	push	xde
	ld	xde, 3230
	ld	iy, (xde+iz)
	srl	iz, 1
	ld	xde, 3262
	ld	a, (xde+iz)
	pop	xde
	cp iy, (3583:16)
	jrl	nz, VoiceState_DataBlock2_Skip13
	cp	a, (3585:16)
	jrl	nc, VoiceState_DataBlock2_Skip15
VoiceState_DataBlock2_Skip13:
	call	VoiceSlot_ReadCurrentParams
VoiceState_DataBlock2_Skip14:
	and	a, 240
	cp	a, 176
	jrl	nz, VoiceState_DataBlock2_Loop7
	call	VoiceState_DataBlock2_Helper9
	cp	a, 1:i3
	jrl	z, VoiceState_DataBlock2_Entry
	cp	a, 2:i3
	jrl	z, VoiceState_DataBlock2_Entry2
	jp	VoiceState_DataBlock2_Loop7
VoiceState_DataBlock2_Entry:
	or	(0x0f56:16), 1
	jp	VoiceState_DataBlock2_Loop7
VoiceState_DataBlock2_Entry2:
	and	(0x0f56:16), 254
	jp	VoiceState_DataBlock2_Loop7
VoiceState_DataBlock2_Skip15:
	ld	a, 4:opc
	call	VoiceSlot_RestoreState
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	pop_lerp 56
	push	xwa
	ldto_lerp	xwa, 56
	ld	(4349:16), xwa
	pop	xwa
	ret
VoiceState_DataBlock2_Helper9:
	call	VoiceSlot_ComputeWordIndex
	push	xde
	ld	xde, 3230
	ld	iy, (xde+iz)
	ld	(10431:16), iy
	srl	iz, 1
	ld	xde, 3262
	ld	a, (xde+iz)
	pop	xde
	xor	w, w
	ld	(10433:16), wa
	call	VoiceBank_ProcessCommand
	ld	a, (3765:16)
	and	a, 240
	cp	a, 176
	jrl	z, VoiceState_DataBlock2_Skip16
VoiceState_DataBlock2_Loop8:
	ld	a, 0:opc
	jp	VoiceState_DataBlock2_Return5
VoiceState_DataBlock2_Skip16:
	cp	(3767:16), 72
	jrl	nz, VoiceState_DataBlock2_Loop8
	cp	(3768:16), 10
	jrl	nz, VoiceState_DataBlock2_Loop8
	bit	4, (0x0eba:16)
	jrl	z, VoiceState_DataBlock2_Loop8
	ld	a, 1:opc
	bit	4, (0x0eb9:16)
	jrl	nz, VoiceState_DataBlock2_Return5
	ld	a, 2:opc
VoiceState_DataBlock2_Return5:
	ret
SoundEvt_LongPacketHandler_Helper2:
	ld	a, 32:opc
	ld	w, (3421:16)
	cp	(3420:16), 3
	jrl	le, VoiceState_DataBlock2_Skip17
	sub	w, 4
	jp	VoiceState_DataBlock2_Join3
VoiceState_DataBlock2_Skip17:
	cp	w, 4:i3
	jrl	ule, VoiceState_DataBlock2_Join3
	ld	w, 4:opc
VoiceState_DataBlock2_Join3:
	ld	(13952:16), a
	ld	(13941:16), w
	ld	(3667:16), w
	ld	(3559:16), w
	ld	a, (3420:16)
	sla	a, 3
	ld	h, a
	ld	a, (3415:16)
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	add	h, a
	inc	1, h
	cp	h, 32
	jrl	ule, VoiceState_DataBlock2_Skip18
	sub	h, 32
VoiceState_DataBlock2_Skip18:
	ld	(13939:16), h
	call	VoiceState_DataBlock2_Helper16
	ret
PerfMode_Handler_EvtB_Helper2_Helper10:
	ld	xix, 61856
	xor	bc, bc
	ld	c, 16:opc
	ld	a, 16:opc
	cp	a, (xix+)
	jrl	z, VoiceState_DataBlock2_Skip19
	djnz16	bc, -9
	jp	VoiceState_DataBlock2_Entry3
VoiceState_DataBlock2_Skip19:
	xor	wa, wa
	ld	a, 16:opc
	sub	wa, bc
	ld	iy, wa
	sla	iy, 1
	push	xix
	ld	xix, VoiceState_DataBlock2_Tbl
	ld	bc, (xix+iy)
	pop	xix
	and	bc, (65516:24)
	cp	bc, 0:i3
	jrl	z, VoiceState_DataBlock2_Entry3
	pushw	wa
	ld	xhl, 62032
	ld	c, 3:opc
	mul	wa, c
	ld	iy, wa
	bit	7, (xhl+iy)
	jrl	z, SoundEvt_LongPacketHandler_Helper2_Skip
	popw	wa
	jp	SoundEvt_LongPacketHandler_Helper2_Join
SoundEvt_LongPacketHandler_Helper2_Skip:
	popw	wa
	jp	VoiceState_DataBlock2_Entry3
SoundEvt_LongPacketHandler_Helper2_Join:
	inc	1, a
	ld	w, a
	ld	(3414:16), w
	or	(0x0d54:16), 1
	or	(0x287b:16), 4
	jp	VoiceState_DataBlock2_Entry3_Code_Return
VoiceState_DataBlock2_Entry3:
	and	(0x0d54:16), 254
	and	(0x287b:16), 251
	xor	w, w
VoiceState_DataBlock2_Entry3_Code_Return:
	ret
	; Byte data, 32 B.  Read by VoiceState_DataBlock2 (0xEFD150): `ld xix, VoiceState_DataBlock2_Tbl`
	; indexed with stride 2 (`sla iy, 1`)
VoiceState_DataBlock2_Tbl:
	.byte	0x01, 0x00, 0x02, 0x00, 0x04, 0x00, 0x08, 0x00, 0x10, 0x00, 0x20, 0x00, 0x40, 0x00, 0x80, 0x00
	.byte	0x00, 0x01, 0x00, 0x02, 0x00, 0x04, 0x00, 0x08, 0x00, 0x10, 0x00, 0x20, 0x00, 0x40, 0x00, 0x80
VoiceSlot_TableSetup_Helper6:
	xor	bc, bc
VoiceState_DataBlock2_Loop9:
	pushw	bc
	push	xix
	call	VoiceBank_ProcessCommand
	pop	xix
	popw	bc
	ld	a, (3765:16)
	pushw	bc
	push	xix
	call	VoiceSlot_StatusCheck
	pop	xix
	popw	bc
	cp	w, 0:i3
	jrl	nz, VoiceState_DataBlock2_Loop9
	cp	a, 130
	jrl	nz, VoiceState_DataBlock2_Skip22
	cp	xix, 13978
	jrl	c, VoiceState_DataBlock2_Return6
	ld	xwa, xix
	sub	xwa, 13978
	cp	xwa, 0
	jrl	nz, VoiceState_DataBlock2_Skip20
	ld	wa, 1:i3
	jp	VoiceState_DataBlock2_Join4
VoiceState_DataBlock2_Skip20:
	sla	wa, 3
VoiceState_DataBlock2_Join4:
	cp	a, 1:i3
	jrl	z, VoiceState_DataBlock2_Skip21
	inc	1, a
VoiceState_DataBlock2_Skip21:
	ld	(3931:16), a
	ld	(3930:16), 3
	jp	VoiceState_DataBlock2_Return6
VoiceState_DataBlock2_Skip22:
	cp	a, 132
	jrl	z, VoiceState_DataBlock2_Return6
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Skip23
	ld	a, (3766:16)
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	pushw	bc
	ld	c, a
	ldfr_berp	a, 60
	ld	a, c
	scf
	stcf	a, (xix)
	ldto_berp	a, 60
	popw	bc
	jp	VoiceState_DataBlock2_Loop9
VoiceState_DataBlock2_Skip23:
	inc	1, c
	cp	c, (3777:16)
	jrl	z, VoiceState_DataBlock2_Return6
	inc	1, xix
	jp	VoiceState_DataBlock2_Loop9
VoiceState_DataBlock2_Return6:
	ret
MemConfig_Handler_4_Helper7:
	ld	w, 114:opc
	call	MIDI_SendSysExFromW
	call	Timer_ParamCompareAlt_Helper6
	call	VoiceState_DataBlock2_Helper10
	call	VoiceState_DataBlock2_Helper11
	ld	w, 0:opc
	ret
VoiceState_DataBlock2_Helper10:
	call	Timer_ModeHandler_0_Helper2
	ld	xiz, 3411
	andmi8	(xiz), 191
	call	VoiceState_DataBlock2_Helper12
	cp	(3429:16), 0
	jrl	nz, VoiceState_DataBlock2_Skip25
	ld	(3434:16), 0
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jr	nz, VoiceState_DataBlock2_Skip24
	call	MemConfig_Handler_5_Code_Helper10
VoiceState_DataBlock2_Skip24:
	call	MemConfig_Handler_5_Helper
	call	DMA_FlagCheckWithCalls
	call	MemConfig_Handler_5_Code_Helper11
VoiceState_DataBlock2_Skip25:
	ld	w, 0:opc
	ret
VoiceState_DataBlock2_Helper11:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jr	nz, VoiceState_DataBlock2_Skip26
	call	MemConfig_Handler_5_Code_Helper10
VoiceState_DataBlock2_Skip26:
	call	MemConfig_Handler_5_Helper
	call	DMA_FlagCheckWithCalls
	call	MemConfig_Handler_5_Code_Helper11
	ret
VoiceState_DataBlock2_Helper12:
	ld	a, (3822:16)
	ld	(3654:16), a
	xor	wa, wa
	ld	(3435:16), wa
VoiceState_DataBlock2_Loop10:
	ld	a, (3822:16)
	ld	(3822:16), a
	xor	wa, wa
	ld	(3652:16), wa
	call	VoiceState_DataBlock2_Helper7
	cp	w, 0:i3
	jrl	nz, VoiceState_DataBlock2_Loop10
VoiceState_DataBlock2_Loop11:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, VoiceState_DataBlock2_Skip28
	cp	a, 129
	jrl	nz, VoiceState_DataBlock2_Skip27
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, VoiceState_DataBlock2_Skip28
VoiceState_DataBlock2_Skip27:
	call	MemConfig_Handler_4_Helper2
	cp	(3434:16), 0
	jrl	nz, VoiceState_DataBlock2_Loop11
VoiceState_DataBlock2_Skip28:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, VoiceState_DataBlock2_Skip30
	cp	a, 129
	jrl	nz, VoiceState_DataBlock2_Loop11
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	nz, VoiceState_DataBlock2_Loop11
	ld	wa, (3416:16)
	cp	(3429:16), 0
	jrl	nz, VoiceState_DataBlock2_Skip29
	ld	(3416:16), wa
	jp	VoiceState_DataBlock2_Join5
VoiceState_DataBlock2_Skip29:
	ld	(3418:16), wa
	jp	VoiceState_DataBlock2_Join5
VoiceState_DataBlock2_Skip30:
	ld	wa, (3416:16)
	cp	(3429:16), 0
	jrl	nz, VoiceState_DataBlock2_Skip31
	ld	(3416:16), wa
	jp	VoiceState_DataBlock2_Join5
VoiceState_DataBlock2_Skip31:
	ld	(3418:16), wa
VoiceState_DataBlock2_Join5:
	ld	a, (3654:16)
	ld	(3822:16), a
	ret
	cp	(4486:16), 2
	jrl	nz, VoiceState_DataBlock2_Return7
	cp	(32422:16), 1
	jrl	z, VoiceState_DataBlock2_Return7
	ld	(32422:16), 0
	ld	a, (3429:16)
	cp	a, 0:i3
	jrl	z, VoiceState_DataBlock2_Skip32
	cp	a, 3:i3
	jrl	z, VoiceState_DataBlock2_Skip33
	call	VoiceState_DataBlock2_Helper13
	jp	VoiceState_DataBlock2_Return7
VoiceState_DataBlock2_Skip32:
	call	VoiceState_DataBlock2_Helper15
	jp	VoiceState_DataBlock2_Return7
VoiceState_DataBlock2_Skip33:
	call	VoiceState_DataBlock2_Helper14
VoiceState_DataBlock2_Return7:
	ret
VoiceState_DataBlock2_Helper13:
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	z, VoiceState_DataBlock2_Entry6
	jrl	ugt, VoiceState_DataBlock2_Skip35
	ld	bc, (4357:16)
	sub	bc, wa
VoiceState_DataBlock2_Entry4:
	or	(0x0f57:16), 1
	cp	bc, 1:i3
	jrl	nz, VoiceState_DataBlock2_Skip34
	and	(0x0f57:16), 254
VoiceState_DataBlock2_Skip34:
	pushw	bc
	call	VoiceState_DataBlock2_Helper4
	call	Display_UpdateRegion4
	popw	bc
	cp	(32422:16), 1
	jrl	z, VoiceState_DataBlock2_Entry6
	dec	1, bc
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	nz, VoiceState_DataBlock2_Entry4
	jp	VoiceState_DataBlock2_Entry6
VoiceState_DataBlock2_Skip35:
	ld	bc, (4357:16)
	sub	wa, bc
	ld	bc, wa
VoiceState_DataBlock2_Entry5:
	or	(0x0f57:16), 1
	cp	bc, 1:i3
	jrl	nz, VoiceState_DataBlock2_Skip36
	and	(0x0f57:16), 254
VoiceState_DataBlock2_Skip36:
	pushw	bc
	call	VoiceState_DataBlock2_Helper3
	call	Display_UpdateRegion4
	popw	bc
	dec	1, bc
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	nz, VoiceState_DataBlock2_Entry5
VoiceState_DataBlock2_Entry6:
	and	(0x0f57:16), 254
	ret
VoiceState_DataBlock2_Helper14:
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	z, VoiceState_DataBlock2_Return8
	jrl	ugt, VoiceState_DataBlock2_Skip37
	ld	bc, (4357:16)
	sub	bc, wa
VoiceState_DataBlock2_Loop12:
	pushw	bc
	call	UIState_DispatchHandler_Helper
	popw	bc
	cp	(32422:16), 1
	jrl	z, VoiceState_DataBlock2_Return8
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	nz, VoiceState_DataBlock2_Loop12
	jp	VoiceState_DataBlock2_Return8
VoiceState_DataBlock2_Skip37:
	ld	bc, (4357:16)
	sub	wa, bc
	ld	bc, wa
VoiceState_DataBlock2_Loop13:
	pushw	bc
	call	VoiceState_DataBlock2_Helper5
	popw	bc
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	nz, VoiceState_DataBlock2_Loop13
VoiceState_DataBlock2_Return8:
	ret
VoiceState_DataBlock2_Helper15:
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	z, VoiceState_DataBlock2_Return9
	jrl	ugt, VoiceState_DataBlock2_Skip38
	ld	bc, (4357:16)
	sub	bc, wa
	pushw	bc
	call	VoiceState_DataBlock2_Helper6
	popw	bc
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	ge, VoiceState_DataBlock2_Return9
	djnz16	bc, -20
	jp	VoiceState_DataBlock2_Return9
VoiceState_DataBlock2_Skip38:
	ld	bc, (4357:16)
	sub	wa, bc
	ld	bc, wa
	pushw	bc
	call	ScoopDisp_FlagSetAndDispatch_Helper
	popw	bc
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	le, VoiceState_DataBlock2_Return9
	djnz16	bc, -20
VoiceState_DataBlock2_Return9:
	ret
SubCPU_ToneParamDisplay:
	push	xix
	push	xiy
	bit	7, w
	jrl	nz, SubCPU_ToneParamDisplay_Epilogue
	ld	a, (3429:16)
	cp	a, 0:i3
	jrl	z, SubCPU_ToneParamDisplay_Epilogue
	cp	a, 3:i3
	jrl	z, SubCPU_ToneParamDisplay_Epilogue
	cp	a, 2:i3
	jrl	z, SubCPU_ToneParamDisplay_Epilogue
	xor	hl, hl
	ld	l, (3424:16)
	dec	1, l
	ld	xix, 61856
	cp	(xix+hl), 0x0c
	jrl	z, SubCPU_ToneParamDisplay_Epilogue
	ld	(3567:16), 11
	call	Display_UpdateRegion0
	ld	(4380:16), 0
	call	SubCPU_ToneParamDisplay_Helper2
	call	SubCPU_ToneParamDisplay_Helper3
	call	SubCPU_ToneParamDisplay_Helper
SubCPU_ToneParamDisplay_Epilogue:
	pop	xiy
	pop	xix
	ret
SubCPU_ToneParamDisplay_Helper:
	push	xix
	push	xiy
	ld	a, (4381:16)
	ld	xix, 4382
	ld	(xix), 176
	cp	(4380:16), 2
	jrl	nz, SubCPU_ToneParamDisplay_Skip
	ormi8	(xix), 2
SubCPU_ToneParamDisplay_Skip:
	ld	(xix+4), a
	andmi8	(xix+4), 127
	ld	(xix+5), 127
	bit	7, a
	jrl	z, SubCPU_ToneParamDisplay_Skip2
	ormi8	(xix), 1
SubCPU_ToneParamDisplay_Skip2:
	ld	a, (3415:16)
	ld	(xix+1), a
	ld	a, (35998:16)
	ld	(xix+2), a
	ld	l, (4380:16)
	exts	hl
	ld	xiy, SubCPU_ToneParamDisplay_Tbl
	ld	a, (xiy+hl)
	ld	(xix+3), a
	pop	xiy
	pop	xix
	ret
SubCPU_ToneParamDisplay_Helper2:
	push XIX
	xor HL,HL
	ld l, (0x0d60:16)
	dec 1,L
	ld XIX,0x0000f1a0
	ld	l, (xix+hl)
	sla HL, 0x02
	ld XIX,SubCPU_ToneDispatch
	ld	xhl, (xix+hl)
	cp XHL,0xffffffff
	jrl z, .Lc_efda73
	xor WA,WA
	ld a, (0x111c:16)
	ld XIX,SubCPU_ToneParamDisplay_Tbl
	ld	a, (xix+wa)
	ld	a, (xhl+wa)
	ld (0x111d:16), a
.Lc_efda73:
SubCPU_ToneParamDisplay_Epilogue2:
	pop XIX
	ret
SubCPU_ToneParamDisplay_Helper3:
	ld XIX,0x00000ecd
	ld A, 0x20:opc
	ldw BC, 0x001b
	ld	(xix+), a
	djnz16	bc, -6
	ld	xiy, Str_PanKeyShiftTuning
	ld	a, (4380:16)
	ld	w, a
	sla	a, 3
	sla	w, 1
	add	a, w
	xor	w, w
	lda	xiy, (xiy+wa)
	ld	xix, 3791
	ldw	bc, 10
	ldir85
	xor	wa, wa
	ld	a, (4381:16)
	cp	(4380:16), 1
	jrl	z, SubCPU_ToneParamDisplay_Skip3
	cp	(4380:16), 2
	jrl	nz, SubCPU_ToneParamDisplay_Skip4
	ldw	de, 128
	jp	SubCPU_ToneParamDisplay_0x137
SubCPU_ToneParamDisplay_Skip3:
	ldw	de, 64
SubCPU_ToneParamDisplay_0x137:
	push	xix
	call	ParamDigit_CalrData
	pop	xix
	ld	a, (4480:16)
	ld	(xix+), a
	jp	SubCPU_ToneParamDisplay_Join2
SubCPU_ToneParamDisplay_Skip4:
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
SubCPU_ToneParamDisplay_Join2:
	ld	xiy, 4481
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; Lcd text, 40 B.  Read by SubCPU_ToneParamDisplay (0xEFD992): `ld xiy, Str_PanKeyShiftTuning`
	; reader SubCPU_ToneParamDisplay: `ld xiy, Str_PanKeyShiftTuning` then `lda_rr xiy, xiy, wa`
Str_PanKeyShiftTuning:
	.ascii	"PAN      :KEY SHIFT:TUNING   :BEND SENS:"
	; Byte data, 80 B.  Read by SubCPU_ToneParamDisplay (0xEFD992): `ld XIX,SubCPU_ToneDispatch`
	; indexed with stride 1 (`sla HL, 0x02`), index from `ld l, (0x0d60:16)`
SubCPU_ToneDispatch:
	.byte	0xb6, 0xf9, 0x00
	.long	0x00f9ea00
	.long	0x00f9d000
	.long	0x00fa6c00
	.long	0x00fa8600
	.long	0x00faa000
	.long	0x00faba00
	.long	0x00fad400
	.long	0x00fa1e00
	.long	0x00fa3800
	.long	0x00fa5200
	.long	0x00fa0400
	.long	0x00fb3c00
	.byte	0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.long	0x00faeeff
	.long	0x00fb0800
	.long	0x00fb2200
	.byte	0x00
SubCPU_ToneParamDisplay_Tbl:
	ld	(9:8), 10:io
	pushw	0xd7cf
	bit	7, w
	jrl	nz, SubCPU_ToneParamDisplay_Skip5
	ld	l, 3:opc
SubCPU_ToneParamDisplay_Skip5:
	cp	(4380:16), l
	jrl	z, SubCPU_ToneParamDisplay_Return
	ld	a, (4380:16)
	xor	l, l
	ld	h, 3:opc
	call	SubCPU_ToneStoreDigits
	ld	(4380:16), a
	call	SubCPU_ToneParamDisplay_Helper2
	call	SubCPU_ToneParamDisplay_Helper3
	call	SubCPU_ToneParamDisplay_Helper
SubCPU_ToneParamDisplay_Return:
	ret
SubCPU_ToneHandler_A:
	or	(0xe31c:16), 8
	ldb_d8	a, (0x111d)
	xor	l, l
	ld	h, 127:opc
	cp	(0x111c:16), 1
	jrl	nz, SubCPU_ToneHandler_B
	ld	l, 52:opc
	ld	h, 76:opc
	jp	SubCPU_CallRoutine
SubCPU_ToneHandler_B:
	cp	(4380:16), 3
	jrl nz, SubCPU_ToneLoadAndStore
	ld h, 0x0c:opc
	jp SubCPU_CallRoutine
SubCPU_ToneLoadAndStore:
	cp	(4380:16), 2
	jrl nz, SubCPU_CallRoutine
	ld h, 0xff:opc
SubCPU_CallRoutine:
	call PerfMode_Evt04_VolumeHandler_Helper
	ld	(4381:16), a
	call SubCPU_ToneParamDisplay_Helper3
	call SubCPU_ToneParamDisplay_Helper
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
	jrl	z, SubCPU_ToneFormatDone_Skip
	jp	SubCPU_ToneClearRegion_Return
SubCPU_ToneFormatDone_Skip:
	ld	w, (3538:16)
	ld	w, 6:opc
	ld	xiy, 4382
	call	DisplayMode_Handler_3_Helper16
SubCPU_ToneClearRegion:
	or	(0x0dd3:16), 1
	xor	a, a
	stb_d8	(0x0dd2), a
	ld	(0x0d55:16), 255
	call	ToneParam_ModeGuardEntry_Helper4
	cp	w, 0:i3
	jrl	nz, SubCPU_ToneClearRegion_Skip
	ldb_d8	l, (0x0d65)
	and	l, 3
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, DisplayMode_DispatchTable
	ld	xhl, (xix+hl)
	pop	xix
	call	(xhl)
	jp	SubCPU_ToneClearRegion_Return
SubCPU_ToneClearRegion_Skip:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, SubCPU_ToneClearRegion_Skip2
	cp	a, 130
	jrl	z, SubCPU_ToneClearRegion_Skip2
	call	VoiceSlot_FlagCheck
	cp	a, (0x0d57:16)
	jrl	ugt, SubCPU_ToneClearRegion_Skip2
	call	DMA_FlagCheckWithCalls
	jp	SubCPU_ToneClearRegion_Join
SubCPU_ToneClearRegion_Skip2:
	call	Timer_ParamCompareAlt_Helper6
SubCPU_ToneClearRegion_Join:
	res	2, (0x0d54:16)
SubCPU_ToneClearRegion_Return:
	ret
PerfMode_ParamHandler_11:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_11_Return
	sla	hl, 2
	push	xix
	ld	xix, SubCPU_ToneParamRet
	ld	xhl, (xix+hl)
	pop xix
	call	(xhl)
PerfMode_ParamHandler_11_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_11 (0xEFDC7C): `ld xix, SubCPU_ToneParamRet`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
SubCPU_ToneParamRet:
	.long	UIDisp_DefaultInputHandler
	.long	SubCPU_ToneDispatch_0x54
	.long	DefaultHandler_Ret
	.long	SubCPU_ToneHandler_A
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SubCPU_ToneFormatDone
	.long	SubCPU_ToneClearRegion
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	ToneParam_Evt0F_BytecodeHandler
	.long	DefaultHandler_Ret
	.long	UIDisp_DefaultInputHandler
	.long	SubCPU_ToneDispatch_0x54
	.long	DefaultHandler_Ret
	.long	SubCPU_ToneHandler_A
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	SoundEvt_ShortPacketHandler
	.long	SoundEvt_LongPacketHandler
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
SubCPU_ToneParamRet_Helper:
	call	VoiceSlot_TableSetup_Helper7
	call	AccPedal_CheckBitAndUpdate
	ldw_d16	wa, (0x367e)
	ld	(0x0e4e:16), wa
	ldb_d8	a, (0x0d5d)
	stb_d8	(0x0ec8), a
	stb_d8	(0x0e53), a
	cpw	(0x367e:16), 1
	jrl	z, PerfMode_ParamHandler_11_Skip7
	cp	(0x0ec8:16), 4
	jrl	ugt, PerfMode_ParamHandler_11_Skip3
	call	SubCPU_ToneParamRet_Helper2
	ldw_d16	de, (0x0e4e)
	inc	1, de
	ld	(0x287f:16), de
	call	VoiceSlot_TableSetup_Helper7
	ldb_d8	a, (0x0eee)
	call	SetWall_SlotResolve
	cp	(0x287a:16), 0
	jrl	z, PerfMode_ParamHandler_11_Skip
	xor	wa, wa
	ld	(0x0e50:16), wa
	stb_d8	(0x0e54), a
	jp	SubCPU_ToneParamRet_Join
PerfMode_ParamHandler_11_Skip:
	ldw_d16	hl, (0x0e4e)
	inc	1, hl
	ld	(0x0e50:16), hl
	stb_d8	(0x0ec9), a
	stb_d8	(0x0e54), a
	cp	a, 4:i3
	jrl	ule, PerfMode_ParamHandler_11_Skip2
	ld	(0x0e54:16), 4
PerfMode_ParamHandler_11_Skip2:
	jp	SubCPU_ToneParamRet_Join
PerfMode_ParamHandler_11_Skip3:
	cp	(0x0d5c:16), 3
	jrl	ugt, PerfMode_ParamHandler_11_Skip4
	call	SubCPU_ToneParamRet_Helper2
	ldw_d16	wa, (0x0e4e)
	ld	(0x0e50:16), wa
	ldb_d8	a, (0x0e53)
	sub	a, 4
	stb_d8	(0x0e54), a
	ld	(0x0e53:16), 4
	jp	SubCPU_ToneParamRet_Join
PerfMode_ParamHandler_11_Skip4:
	ldw_d16	de, (0x0e4e)
	ld	(0x287f:16), de
	call	VoiceSlot_TableSetup_Helper7
	ldb_d8	a, (0x0eee)
	call	SetWall_SlotResolve
	ldw_d16	wa, (0x28af)
	ld	(0x28bf:16), wa
	ld	(0x28c1:16), iy
	ldw_d16	wa, (0x0e4e)
	ld	(0x0e4c:16), wa
	ld	(0x0e52:16), 4
	ldb_d8	a, (0x0ec8)
	sub	a, 4
	stb_d8	(0x0e53), a
	ldw_d16	de, (0x0e4e)
	inc	1, de
	ld	(0x287f:16), de
	call	VoiceSlot_TableSetup_Helper7
	ldb_d8	a, (0x0eee)
	call	SetWall_SlotResolve
	cp	(0x287a:16), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip6
	ldw_d16	hl, (0x0e4e)
	inc	1, hl
	ld	(0x0e50:16), hl
	stb_d8	(0x0ec9), a
	stb_d8	(0x0e54), a
	cp	a, 3:i3
	jrl	ule, PerfMode_ParamHandler_11_Skip5
	ld	(0x0e54:16), 4
PerfMode_ParamHandler_11_Skip5:
	jp	SubCPU_ToneParamRet_Join
PerfMode_ParamHandler_11_Skip6:
	xor	wa, wa
	ld	(0x0e50:16), wa
	stb_d8	(0x0e54), a
	jp	SubCPU_ToneParamRet_Join
PerfMode_ParamHandler_11_Skip7:
	ldb_d8	l, (0x0eee)
	dec	1, l
	ld	h, l
	sla	l, 1
	add	l, h
	xor	h, h
	push	xde
	ld	xde, 0xf250
	add	xde, 1
	ld	hl, (xde+hl)
	pop	xde
	ld	(0x28bf:16), hl
	ldw	(0x28c1:16), 5
	cp	(0x0ec8:16), 4
	jrl	ugt, PerfMode_ParamHandler_11_Skip10
	xor	wa, wa
	ld	(0x0e4c:16), wa
	stb_d8	(0x0e52), a
	ldb_d8	a, (0x0ec8)
	stb_d8	(0x0e53), a
	ldw_d16	de, (0x0e4e)
	inc	1, de
	ld	(0x287f:16), de
	call	VoiceSlot_TableSetup_Helper7
	ldb_d8	a, (0x0eee)
	call	SetWall_SlotResolve
	cp	(0x287a:16), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip9
	ldw_d16	hl, (0x0e4e)
	inc	1, hl
	ld	(0x0e50:16), hl
	stb_d8	(0x0ec9), a
	stb_d8	(0x0e54), a
	cp	a, 4:i3
	jrl	ule, PerfMode_ParamHandler_11_Skip8
	ld	(0x0e54:16), 4
PerfMode_ParamHandler_11_Skip8:
	jp	SubCPU_ToneParamRet_Join
PerfMode_ParamHandler_11_Skip9:
	xor	wa, wa
	ld	(0x0e50:16), wa
	stb_d8	(0x0e54), a
	jp	SubCPU_ToneParamRet_Join
PerfMode_ParamHandler_11_Skip10:
	cp	(0x0d5c:16), 3
	jrl	ugt, PerfMode_ParamHandler_11_Skip11
	xor	wa, wa
	ld	(0x0e4c:16), wa
	stb_d8	(0x0e52), a
	ldb_d8	a, (0x0ec8)
	ld	(0x0e53:16), 4
	sub	a, 4
	stb_d8	(0x0e54), a
	ldw_d16	wa, (0x0e4e)
	ld	(0x0e50:16), wa
	jp	SubCPU_ToneParamRet_Join
PerfMode_ParamHandler_11_Skip11:
	ldw_d16	wa, (0x367e)
	ld	(0x0e4c:16), wa
	ld	(0x0e52:16), 4
	ldb_d8	a, (0x0ec8)
	sub	a, 4
	stb_d8	(0x0e53), a
	ldw_d16	de, (0x367e)
	inc	1, de
	ld	(0x287f:16), de
	call	VoiceSlot_TableSetup_Helper7
	ldb_d8	a, (0x0eee)
	call	SetWall_SlotResolve
	cp	(0x287a:16), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip13
	ldw_d16	hl, (0x367e)
	inc	1, hl
	ld	(0x0e50:16), hl
	stb_d8	(0x0ec9), a
	stb_d8	(0x0e54), a
	cp	a, 4:i3
	jrl	ule, PerfMode_ParamHandler_11_Skip12
	ld	(0x0e54:16), 4
PerfMode_ParamHandler_11_Skip12:
	jp	SubCPU_ToneParamRet_Join
PerfMode_ParamHandler_11_Skip13:
	xor	wa, wa
	ld	(0x0e50:16), wa
	stb_d8	(0x0e54), a
	jp	SubCPU_ToneParamRet_Join
SubCPU_ToneParamRet_Join:
	ldw_d16	wa, (0x0e4c)
	ld	(0x117c:16), wa
	ldb_d8	a, (0x0e52)
	stb_d8	(0x0ec1), a
	ld	xwa, 0x0e55
	ld	(0x1114:16), xwa
	xor	wa, wa
	stb_d8	(0x0ec6), a
	ld	(0x0ec4:16), wa
	cp	(0x117c:16), wa
	jrl	nz, PerfMode_ParamHandler_11_Return2
	ldw_d16	wa, (0x0e4e)
	ld	(0x117c:16), wa
	ld	xwa, 0x0e75
	ld	(0x1114:16), xwa
	ld	(0x0ec6:16), 1
	ldb_d8	a, (0x0e53)
	stb_d8	(0x0ec1), a
PerfMode_ParamHandler_11_Return2:
	ret
VoiceSlot_TableSetup_Helper7:
	xor	w, w
	bit	0, (0x0d54:16)
	jrl	z, PerfMode_ParamHandler_11_Skip15
	xor	hl, hl
SubCPU_ToneParamRet_Join2:
	cp	hl, 15
	jrl	ugt, SubCPU_ToneParamRet_Return
	push	xde
	ld	xde, 0xf1a0
	cp	(xde+hl), 0x10
	pop	xde
	jrl	nz, PerfMode_ParamHandler_11_Skip14
	ld	w, l
	inc	1, w
	jp	SubCPU_ToneParamRet_Join3
PerfMode_ParamHandler_11_Skip14:
	inc	1, hl
	jp	SubCPU_ToneParamRet_Join2
PerfMode_ParamHandler_11_Skip15:
	and	(0x287b:16), 251
	jp	SubCPU_ToneParamRet_Return
SubCPU_ToneParamRet_Join3:
	or	(0x287b:16), 4
SubCPU_ToneParamRet_Return:
	ret
VoiceSlot_TableSetup_Helper8:
	xor	bc, bc
SubCPU_ToneParamRet_Join4:
	pushw	bc
	call	VoiceBank_LoadLerpState
	popw	bc
	bit	7, a
	jrl	z, PerfMode_ParamHandler_11_Skip16
	cp	a, 130
	jrl	z, PerfMode_ParamHandler_11_Return3
	cp	a, 132
	jrl	z, PerfMode_ParamHandler_11_Return3
	cp	a, 129
	jrl	nz, PerfMode_ParamHandler_11_Skip16
	inc	1, c
	cp	c, 4:i3
	jrl	z, PerfMode_ParamHandler_11_Skip17
PerfMode_ParamHandler_11_Skip16:
	pushw	bc
	call	VoiceBank_UpdateLerpState
	popw	bc
	jp	SubCPU_ToneParamRet_Join4
PerfMode_ParamHandler_11_Skip17:
	call	VoiceBank_UpdateLerpState
PerfMode_ParamHandler_11_Return3:
	ret
SubCPU_ToneParamRet_Helper2:
	ldw_d16	de, (0x0e4e)
	dec	1, de
	ld	(0x287f:16), de
	call	VoiceSlot_TableSetup_Helper7
	ldb_d8	a, (0x0eee)
	call	SetWall_SlotResolve
	pushw	wa
	ldw_d16	wa, (0x28af)
	ld	(0x28bf:16), wa
	ld	(0x28c1:16), iy
	ldw_d16	hl, (0x0e4e)
	dec	1, hl
	ld	(0x0e4c:16), hl
	popw	wa
	stb_d8	(0x0ec7), a
	stb_d8	(0x0e52), a
	cp	a, 4:i3
	jrl	ule, PerfMode_ParamHandler_11_Return4
	sub	a, 4
	stb_d8	(0x0e52), a
	call	VoiceSlot_TableSetup_Helper8
PerfMode_ParamHandler_11_Return4:
	ret
	call	Display_ResetDirtyFlags
	call	SubCPU_ToneParamRet_Helper3
	call	Display_UpdateDirtyRegions
	ret
SubCPU_ToneParamRet_Helper3:
	cp	(0x8c9c:16), 138
	jrl	nz, SubCPU_ToneParamRet_Return2
	ldb_d8	a, (0xbfe1)
	cp	a, 0:i3
	jrl	nz, SubCPU_ToneParamRet_Return2
	ldb_d8	a, (0x0d65)
	cp	a, 1:i3
	jrl	z, PerfMode_ParamHandler_11_Skip18
	cp	a, 2:i3
	jrl	nz, SubCPU_ToneParamRet_Return2
PerfMode_ParamHandler_11_Skip18:
	ldb_d8	w, (0xbfe2)
	ldb_d8	a, (0xbfe3)
	cp	w, 0:i3
	jrl	nz, SubCPU_ToneParamRet_Return2
	and	a, 3
	cp	a, 1:i3
	jrl	z, PerfMode_ParamHandler_11_Skip19
	cp	a, 2:i3
	jrl	z, PerfMode_ParamHandler_11_Skip19
	cp	a, 3:i3
	jrl	nz, SubCPU_ToneParamRet_Return2
PerfMode_ParamHandler_11_Skip19:
	ld	(0x0d36:16), 0
	bit	7, (0x0d39:16)
	jrl	z, PerfMode_ParamHandler_11_Skip21
	and	(0x0f57:16), 254
	call	Display_UpdateRegion0
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, PerfMode_ParamHandler_11_Skip20
	cp	a, 130
	jrl	z, PerfMode_ParamHandler_11_Skip20
	call	VoiceSlot_FlagCheck
	cp	a, (0x0d57:16)
	jrl	nc, PerfMode_ParamHandler_11_Skip20
	call	DMA_FlagCheckWithCalls
	res	2, (0x0d54:16)
	jp	SubCPU_ToneParamRet_Join5
PerfMode_ParamHandler_11_Skip20:
	ld	(0x367b:16), 255
	call	Timer_ParamCompareAlt_Helper6
SubCPU_ToneParamRet_Join5:
	or	(0x0dd3:16), 1
	ldw	(0x26c0:16), 0
	call	VoiceSlot_TableSetup
	jp	SubCPU_ToneParamRet_Return2
PerfMode_ParamHandler_11_Skip21:
	and	(0x0f57:16), 254
	call	Display_UpdateRegion0
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, PerfMode_ParamHandler_11_Skip22
	cp	a, 130
	jrl	z, PerfMode_ParamHandler_11_Skip22
	call	VoiceSlot_FlagCheck
	cp	a, (0x0d57:16)
	jrl	nc, PerfMode_ParamHandler_11_Skip22
	call	DMA_FlagCheckWithCalls
	res	2, (0x0d54:16)
	jp	SubCPU_ToneParamRet_Join6
PerfMode_ParamHandler_11_Skip22:
	ld	(0x367b:16), 255
	call	Timer_ParamCompareAlt_Helper6
SubCPU_ToneParamRet_Join6:
	or	(0x0dd3:16), 1
	ldw	(0x26c0:16), 0
	call	VoiceSlot_TableSetup
SubCPU_ToneParamRet_Return2:
	ret
MemConfig_Handler_5_Helper:
	cp	(0x28be:16), 255
	jrl	z, PerfMode_ParamHandler_11_Skip23
PerfMode_ParamHandler_11_Loop:
	call	Display_UpdateRegion1
	jp	SubCPU_ToneParamRet_Join9
PerfMode_ParamHandler_11_Skip23:
	ldb_d8	l, (0x0d60)
	dec	1, l
	ld	h, l
	sla	l, 1
	add	l, h
	xor	h, h
	push	xde
	ld	xde, 0xf250
	bit	7, (xde+hl)
	pop	xde
	jrl	z, PerfMode_ParamHandler_11_Loop
	call	SubCPU_ToneParamRet_Helper13
	call	SubCPU_ToneParamRet_Helper
SubCPU_ToneParamRet_Join7:
	call	VoiceBank_ProcessCommand
	cp	(0x0eb5:16), 129
	jrl	nz, PerfMode_ParamHandler_11_Skip25
	call	SubCPU_ToneParamRet_Helper18
	ldb_d8	a, (0x0ebb)
	cp	a, 130
	jrl	nz, PerfMode_ParamHandler_11_Skip24
	call	SubCPU_ToneParamRet_Helper8
	jp	SubCPU_ToneParamRet_Join9
PerfMode_ParamHandler_11_Skip24:
	call	SubCPU_ToneParamRet_Helper19
	jp	SubCPU_ToneParamRet_Loop
PerfMode_ParamHandler_11_Skip25:
	cp	(0x0eb5:16), 130
	jrl	z, PerfMode_ParamHandler_11_Skip26
	cp	(0x0eb5:16), 132
	jrl	z, PerfMode_ParamHandler_11_Skip26
	cp	(0x0eb6:16), 48
	jrl	nz, PerfMode_ParamHandler_11_Skip26
	call	SubCPU_ToneParamRet_Helper19
	jp	SubCPU_ToneParamRet_Loop
PerfMode_ParamHandler_11_Skip26:
	ldw	(0x0ec2:16), 0
	ldb_d8	a, (0x0eb5)
	cp	a, 130
	jrl	z, PerfMode_ParamHandler_11_Skip27
	cp	a, 132
	jrl	nz, PerfMode_ParamHandler_11_Skip28
	call	SubCPU_ToneParamRet_Helper9
	jp	SubCPU_ToneParamRet_Join9
PerfMode_ParamHandler_11_Skip27:
	call	SubCPU_ToneParamRet_Helper8
	jp	SubCPU_ToneParamRet_Join9
PerfMode_ParamHandler_11_Skip28:
	and	a, 240
	cp	a, 144
	jrl	nz, PerfMode_ParamHandler_11_Skip29
	call	SubCPU_ToneParamRet_Helper7
	cp	(0x0ef6:16), 0
	jrl	nz, SubCPU_ToneParamRet_Join9
	jp	SubCPU_ToneParamRet_Loop
PerfMode_ParamHandler_11_Skip29:
	ldb_d8	a, (0x0eb5)
	cp	a, 132
	jrl	nz, PerfMode_ParamHandler_11_Skip30
	call	SubCPU_ToneParamRet_Helper9
	jp	SubCPU_ToneParamRet_Join9
PerfMode_ParamHandler_11_Skip30:
	and	a, 240
	ldb_d8	a, (0x0eb6)
	cp	a, 47
	jrl	z, PerfMode_ParamHandler_11_Skip31
	cp	a, 95
	jrl	nz, PerfMode_ParamHandler_11_Skip32
PerfMode_ParamHandler_11_Skip31:
	jp	SubCPU_ToneParamRet_Join7
PerfMode_ParamHandler_11_Skip32:
	call	SubCPU_ToneParamRet_Helper11
	ldb_d8	a, (0x0eb6)
	stb_d8	(0x0f70), a
PerfMode_ParamHandler_11_Loop2:
	call	VoiceBank_ProcessCommand
	ldb_d8	a, (0x0eb5)
	cp	a, 129
	jrl	z, SubCPU_ToneParamRet_Loop
	cp	a, 132
	jrl	z, SubCPU_ToneParamRet_Loop
	ldb_d8	l, (0x0eb6)
	cp	l, 47
	jrl	z, PerfMode_ParamHandler_11_Loop2
	cp	l, 95
	jrl	z, PerfMode_ParamHandler_11_Loop2
	cp	l, (0x0f70:16)
	jrl	nz, SubCPU_ToneParamRet_Loop
	and	a, 240
	cp	a, 144
	jrl	nz, PerfMode_ParamHandler_11_Loop2
	jp	SubCPU_ToneParamRet_Loop
SubCPU_ToneParamRet_Loop:
	ldb_d8	a, (0x0eb5)
	cp	a, 129
	jrl	z, PerfMode_ParamHandler_11_Skip39
	cp	a, 130
	jrl	nz, PerfMode_ParamHandler_11_Skip33
	call	SubCPU_ToneParamRet_Helper8
	jp	SubCPU_ToneParamRet_Join9
PerfMode_ParamHandler_11_Skip33:
	cp	a, 132
	jrl	nz, PerfMode_ParamHandler_11_Skip34
	call	SubCPU_ToneParamRet_Helper9
	jp	SubCPU_ToneParamRet_Join9
PerfMode_ParamHandler_11_Skip34:
	and	a, 240
	cp	a, 144
	jrl	z, PerfMode_ParamHandler_11_Skip48
	cp	(0x0eb6:16), 47
	jrl	z, PerfMode_ParamHandler_11_Skip35
	cp	(0x0eb6:16), 95
	jrl	nz, PerfMode_ParamHandler_11_Skip36
PerfMode_ParamHandler_11_Skip35:
	call	VoiceBank_ProcessCommand
	jp	SubCPU_ToneParamRet_Loop
PerfMode_ParamHandler_11_Skip36:
	ldb_d8	a, (0x0eb6)
	ldb_d8	l, (0x0ec2)
	cp	l, 0:i3
	jrl	nz, PerfMode_ParamHandler_11_Skip37
	ldb_d8	l, (0x0f70)
PerfMode_ParamHandler_11_Skip37:
	sub	a, l
	cp	a, 0:i3
	jrl	z, PerfMode_ParamHandler_11_Skip38
	call	SubCPU_ToneParamRet_Helper17
	cp	(0x0ef6:16), 0
	jrl	nz, SubCPU_ToneParamRet_Join9
PerfMode_ParamHandler_11_Skip38:
	call	SubCPU_ToneParamRet_Helper11
	ldw	(0x0ec2:16), 0
	ldb_d8	a, (0x0eb6)
	stb_d8	(0x0f70), a
PerfMode_ParamHandler_11_Loop3:
	call	VoiceBank_ProcessCommand
	ldb_d8	a, (0x0eb5)
	cp	a, 129
	jrl	z, SubCPU_ToneParamRet_Loop
	cp	a, 132
	jrl	z, SubCPU_ToneParamRet_Loop
	ldb_d8	h, (0x0eb6)
	cp	h, 47
	jrl	z, PerfMode_ParamHandler_11_Loop3
	cp	h, 95
	jrl	z, PerfMode_ParamHandler_11_Loop3
	ldb_d8	l, (0x0f70)
	cp	l, h
	jrl	nz, SubCPU_ToneParamRet_Loop
	and	a, 240
	cp	a, 144
	jrl	nz, PerfMode_ParamHandler_11_Loop3
	jp	SubCPU_ToneParamRet_Loop
PerfMode_ParamHandler_11_Skip39:
	call	SubCPU_ToneParamRet_Helper18
	ldb_d8	a, (0x0ebb)
	cp	a, 130
	jrl	z, PerfMode_ParamHandler_11_Skip41
	cp	a, 132
	jrl	z, PerfMode_ParamHandler_11_Skip40
	cp	a, 129
	jrl	nz, PerfMode_ParamHandler_11_Skip42
PerfMode_ParamHandler_11_Skip40:
	call	DisplayStr_BytecodeBlock_A
	cp	(0x0ef6:16), 0
	jrl	nz, SubCPU_ToneParamRet_Join9
	call	VoiceBank_ProcessCommand
	jp	SubCPU_ToneParamRet_Loop
PerfMode_ParamHandler_11_Skip41:
	call	SubCPU_ToneParamRet_Helper8
	jp	SubCPU_ToneParamRet_Join9
PerfMode_ParamHandler_11_Skip42:
	ldb_d8	l, (0x0ebc)
	add	l, 96
	ldb_d8	c, (0x0f70)
	cpw	(0x0ec2:16), 0
	jrl	z, PerfMode_ParamHandler_11_Skip43
	ldb_d8	c, (0x0ec2)
PerfMode_ParamHandler_11_Skip43:
	sub	l, c
	cp	l, 48
	jrl	z, PerfMode_ParamHandler_11_Skip45
	cp	l, 96
	jrl	z, PerfMode_ParamHandler_11_Skip47
	call	DisplayStr_BytecodeBlock_A
	cp	(0x0ef6:16), 0
	jrl	nz, SubCPU_ToneParamRet_Join9
	call	SubCPU_ToneParamRet_Helper17
	cp	(0x0ef6:16), 0
	jrl	nz, SubCPU_ToneParamRet_Join9
	xor	a, a
	cp	(0x0ebc:16), 48
	jrl	nz, PerfMode_ParamHandler_11_Skip44
	ld	a, 48:opc
PerfMode_ParamHandler_11_Skip44:
	stb_d8	(0x0f70), a
	ldw	(0x0ec2:16), 0
	jp	SubCPU_ToneParamRet_Join8
PerfMode_ParamHandler_11_Skip45:
	call	SubCPU_ToneParamRet_Helper17
	cp	(0x0ef6:16), 0
	jrl	nz, SubCPU_ToneParamRet_Join9
	xor	a, a
	cp	(0x0ebc:16), 48
	jrl	nz, PerfMode_ParamHandler_11_Skip46
	ld	a, 48:opc
PerfMode_ParamHandler_11_Skip46:
	stb_d8	(0x0f70), a
	ldw	(0x0ec2:16), 0
	jp	SubCPU_ToneParamRet_Join8
PerfMode_ParamHandler_11_Skip47:
	call	DisplayStr_BytecodeBlock_A
	cp	(0x0ef6:16), 0
	jrl	nz, SubCPU_ToneParamRet_Join9
	xor	wa, wa
	ld	(0x0ec2:16), wa
	stb_d8	(0x0f70), a
	cp	(0x0ebc:16), 0
	jrl	z, SubCPU_ToneParamRet_Join8
	ld	(0x0f70:16), 48
SubCPU_ToneParamRet_Join8:
	call	VoiceBank_ProcessCommand
	jp	SubCPU_ToneParamRet_Loop
PerfMode_ParamHandler_11_Skip48:
	ldb_d8	a, (0x0eb6)
	ldb_d8	l, (0x0ec2)
	add	l, (0x0f70:16)
	cp	l, 96
	jrl	c, PerfMode_ParamHandler_11_Skip49
	sub	l, 96
PerfMode_ParamHandler_11_Skip49:
	sub	a, l
	cp	a, 48
	jrl	nz, PerfMode_ParamHandler_11_Skip50
	call	SubCPU_ToneParamRet_Helper17
	cp	(0x0ef6:16), 0
	jrl	nz, SubCPU_ToneParamRet_Join9
PerfMode_ParamHandler_11_Skip50:
	call	SubCPU_ToneParamRet_Helper7
	cp	(0x0ef6:16), 0
	jrl	nz, SubCPU_ToneParamRet_Join9
	jp	SubCPU_ToneParamRet_Loop
SubCPU_ToneParamRet_Join9:
	call	SubCPU_ToneParamRet_Helper16
	call	MemConfig_Handler_4_Helper_Helper
	ret
MemConfig_Handler_4_Helper_Helper:
	cp	(0x0d6a:16), 0
	jrl	nz, PerfMode_ParamHandler_11_Return5
	call	VoiceSlot_TableSetup_Helper7
	call	AccPedal_CheckBitAndUpdate
	cp	(0x0d5d:16), 4
	jrl	ugt, PerfMode_ParamHandler_11_Skip51
	ldb_d8	a, (0x0d5c)
	jp	SubCPU_ToneParamRet_Join10
PerfMode_ParamHandler_11_Skip51:
	ldb_d8	a, (0x0d5c)
	cp	a, 4:i3
	jrl	c, SubCPU_ToneParamRet_Join10
	sub	a, 4
SubCPU_ToneParamRet_Join10:
	sla	a, 1
	cp	(0x0d57:16), 0
	jrl	z, PerfMode_ParamHandler_11_Skip52
	inc	1, a
PerfMode_ParamHandler_11_Skip52:
	stb_d8	(0x0eef), a
PerfMode_ParamHandler_11_Return5:
	ret
SubCPU_ToneParamRet_Helper4:
	pushw	wa
	push	xiy
	push	xix
	ldb_d8	a, (0x117e)
	stb_d8	(0x0d43), a
	call	SubCPU_ToneParamRet_Helper5
	ldb_d8	c, (0x117e)
	xor	b, b
	ld	xiy, 0x1169
	ld	xix, 0x0d44
	ldir85
	push	xwa
	push	xbc
	push	xde
	xor	xwa, xwa
	ld	xwa, 0x0d43
	xor	xbc, xbc
	ld	xbc, 0x0d43
	xor	xde, xde
	ld	e, 2:opc
	call	VoiceAlloc_ScoopDisplayProcess_Helper3
	pop	xde
	pop	xbc
	pop	xwa
	pop	xix
	pop	xiy
	popw	wa
	ret
SubCPU_ToneParamRet_Helper5:
	ld	c, a
	dec	1, c
	xor	b, b
	xor	de, de
SubCPU_ToneParamRet_Loop2:
	ld	xiy, 0x1169
	ld	xix, xiy
	inc	1, xix
	lda	xiy, (xiy+de)
	lda	xix, (xix+de)
	ld	a, (xiy)
SubCPU_ToneParamRet_Join11:
	ld	w, (xix)
	cp	a, w
	jrl	c, PerfMode_ParamHandler_11_Skip53
	inc	1, xix
	ld	xhl, 0x1169
	lda	xhl, (xhl+bc)
	cp	xix, xhl
	jrl	ugt, PerfMode_ParamHandler_11_Skip54
	jp	SubCPU_ToneParamRet_Join11
PerfMode_ParamHandler_11_Skip53:
	ld	(xiy), w
	ld	(xix), a
	xor	de, de
	jp	SubCPU_ToneParamRet_Loop2
PerfMode_ParamHandler_11_Skip54:
	inc	1, de
	cp	de, bc
	jrl	c, SubCPU_ToneParamRet_Loop2
	ret
SubCPU_ToneParamRet_Helper6:
	ld	xix, (0x1114:16)
	xor	hl, hl
	ldb_d8	l, (0x0ec4)
	sla	l, 2
	lda	xix, (xix+hl)
	xor	wa, wa
	ld	a, (xix)
	and	a, 96
	cp	a, 0:i3
	jrl	z, PerfMode_ParamHandler_11_Skip55
	inc	1, xix
	jp	SubCPU_ToneParamRet_Join12
PerfMode_ParamHandler_11_Skip55:
	ld	a, 32:opc
	ld	(xix+), a
SubCPU_ToneParamRet_Join12:
	xor	a, a
	ld	(xix+), a
	ldb_d8	w, (0x0d43)
	ldb_d8	a, (0x0d44)
	ld	(xix+), wa
	ret
SubCPU_ToneParamRet_Helper7:
	pushw	bc
	xor	wa, wa
	ld	bc, 3:i3
	ld	xix, 0x1169
	ld	(xix+), wa
	djnz16	bc, -6
	popw	bc
	ld	(0x117e:16), 1
	ldb_d8	a, (0x0eb6)
	stb_d8	(0x0f70), a
	ldb_d8	a, (0x0eb7)
	ld	xix, 0x1169
	ld	(xix+), a
	push	xix
	call	OscScope_Handler_7_Helper
	pop	xix
PerfMode_ParamHandler_11_Join:
	push	xix
	call	VoiceBank_ProcessCommand
	pop	xix
	cp	(0x0eb5:16), 129
	jrl	z, PerfMode_ParamHandler_11_Skip56
	cp	(0x0eb5:16), 132
	jrl	z, PerfMode_ParamHandler_11_Skip56
	ldb_d8	a, (0x0eb5)
	and	a, 240
	cp	a, 144
	jrl	nz, PerfMode_ParamHandler_11_Skip56
	ldb_d8	a, (0x0eb6)
	cp	a, (0x0f70:16)
	jrl	nz, PerfMode_ParamHandler_11_Skip56
	inc	1, (0x117e:16)
	ldb_d8	a, (0x0eb7)
	ld	(xix+), a
	jp	PerfMode_ParamHandler_11_Join
PerfMode_ParamHandler_11_Skip56:
	ldb_d8	a, (0x0f70)
	xor	w, w
	ldw_d16	de, (0x0ec2)
	add	wa, de
	ld	(0x0ec2:16), wa
	ld	l, 96:opc
	div	wa, l
	cp	a, 0:i3
	jrl	z, SubCPU_ToneParamRet_Join15
	ld	c, a
	xor	b, b
SubCPU_ToneParamRet_Join13:
	cp	(0x0eb5:16), 129
	jrl	nz, PerfMode_ParamHandler_11_Skip57
	djnz16	bc, 4
	jp	SubCPU_ToneParamRet_Join14
PerfMode_ParamHandler_11_Loop4:
	pushw	bc
	call	VoiceBank_ProcessCommand
	popw	bc
	jp	SubCPU_ToneParamRet_Join13
PerfMode_ParamHandler_11_Skip57:
	ldb_d8	a, (0x0eb6)
	cp	a, 47
	jrl	z, PerfMode_ParamHandler_11_Loop4
	cp	a, 95
	jrl	z, PerfMode_ParamHandler_11_Loop4
	jp	SubCPU_ToneParamRet_Join15
SubCPU_ToneParamRet_Join14:
	call	VoiceBank_ProcessCommand
SubCPU_ToneParamRet_Join15:
	call	SubCPU_ToneParamRet_Helper4
	call	SubCPU_ToneParamRet_Helper6
	call	SubCPU_ToneParamRet_Helper12
	ret
SubCPU_ToneParamRet_Helper8:
	ld	xix, (0x1114:16)
	ldb_d8	e, (0x0ec4)
	sla	e, 2
	xor	d, d
	extz	xde
	add	xix, xde
	xor	de, de
	andmi8	(xix), 127
	ld	(xix+1), 1
	ld	(xix+2), de
	call	SubCPU_ToneParamRet_Helper10
	ret
SubCPU_ToneParamRet_Helper9:
	ld	xix, (0x1114:16)
	ldb_d8	e, (0x0ec4)
	sla	e, 2
	xor	d, d
	extz	xde
	add	xix, xde
	xor	de, de
	andmi8	(xix), 127
	ld	(xix+1), 2
	ld	(xix+2), de
	call	SubCPU_ToneParamRet_Helper10
	ret
SubCPU_ToneParamRet_Helper10:
	ldb_d8	l, (0x0ec1)
	sla	l, 1
	ldb_d8	a, (0x0ec4)
	cp	a, l
	jrl	nc, PerfMode_ParamHandler_11_Skip58
	incw	1, (0x0ec4:16)
	ldw_d16	ix, (0x0ec4)
	sla	ix, 2
	ldw	bc, 32
	sub	bc, ix
	cp	bc, 0:i3
	jrl	z, PerfMode_ParamHandler_11_Skip58
	extz	xix
	add	xix, (0x1114:16)
	xor	a, a
	ld	(xix+), a
	djnz16	bc, -6
PerfMode_ParamHandler_11_Skip58:
	jp	PerfMode_ParamHandler_11_Return6
	ldb_d8	e, (0x0ec6)
	cp	e, 2:i3
	jrl	z, PerfMode_ParamHandler_11_Return6
	cp	e, 0:i3
	jrl	nz, PerfMode_ParamHandler_11_Skip59
	call	SubCPU_ToneParamRet_Helper14
PerfMode_ParamHandler_11_Skip59:
	call	SubCPU_ToneParamRet_Helper15
PerfMode_ParamHandler_11_Return6:
	ret
SubCPU_ToneParamRet_Helper11:
	ldb_d8	a, (0x0eb5)
	and	a, 1
	rrc	a
	stb_d8	(0x116d), a
	ldb_d8	l, (0x0eb6)
	cp	l, 47
	jrl	z, SubCPU_ToneParamRet_Return3
	cp	l, 95
	jrl	z, SubCPU_ToneParamRet_Return3
	ldb_d8	l, (0x0eb7)
	cp	l, 72
	jrl	nz, SubCPU_ToneParamRet_Return3
	cp	(0x0eb8:16), 5
	jrl	z, PerfMode_ParamHandler_11_Skip60
	cp	(0x0eb8:16), 6
	jrl	nz, SubCPU_ToneParamRet_Return3
PerfMode_ParamHandler_11_Skip60:
	ldb_d8	a, (0x0eb9)
	and	a, 127
	or	a, (0x116d:16)
	xor	bc, bc
PerfMode_ParamHandler_11_Loop5:
	ldfr_berp	a, 60
	ldfr_berp	a, 61
	ld	a, c
	scf
	xorcfb_erp	61
	ldto_berp	a, 60
	jrl	nc, PerfMode_ParamHandler_11_Skip61
	inc	1, c
	cp	c, 7:i3
	jrl	ule, PerfMode_ParamHandler_11_Loop5
	jp	SubCPU_ToneParamRet_Return3
PerfMode_ParamHandler_11_Skip61:
	cp	(0x0eb8:16), 6
	jrl	nz, PerfMode_ParamHandler_11_Skip62
	add	c, 8
PerfMode_ParamHandler_11_Skip62:
	xor	h, h
	ld	l, c
	sla	hl, 2
	extz	xhl
	push	xde
	ld	xde, OscScope_HandlerTable
	ld	xhl, (xde+hl)
	pop	xde
	call	(xhl)
SubCPU_ToneParamRet_Return3:
	ret
	; Handler dispatch table, 64 B.  Read by PerfMode_ParamHandler_11 (0xEFDC7C): `ld xde, OscScope_HandlerTable`
	; indexed with stride 4 (`sla hl, 2`)
	; 16 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
OscScope_HandlerTable:
	.long	SndHandler_DefaultRet
	.long	SndHandler_DefaultRet
	.long	OscScope_Handler_2
	.long	OscScope_Handler_3
	.long	OscScope_Handler_4
	.long	OscScope_Handler_4
	.long	OscScope_Handler_6
	.long	OscScope_Handler_7
	.long	SndHandler_DefaultRet
	.long	SndHandler_DefaultRet
	.long	OscScope_Handler_2
	.long	SndHandler_DefaultRet
	.long	SndHandler_DefaultRet
	.long	SndHandler_DefaultRet
	.long	SndHandler_DefaultRet
	.long	SndHandler_DefaultRet
SndHandler_DefaultRet:
	ret
OscScope_Handler_2:
	call	OscScope_Handler_2_Helper
	ret
OscScope_Handler_3:
	call	OscScope_Handler_2_Helper
	ret
OscScope_Handler_4:
	call	OscScope_Handler_2_Helper
	ret
OscScope_Handler_6:
	call	OscScope_Handler_2_Helper
	ret
OscScope_Handler_7:
	call	OscScope_Handler_2_Helper
	ret
OscScope_Handler_2_Helper:
	ld	xix, (4372:16)
	ld	e, (3780:16)
	sla	e, 2
	xor	d, d
	extz	xde
	add	xix, xde
	andmi8	(xix), 223
	ormi8	(xix), 64
	ret
	ld	xix, (0x1114:16)
	ldb_d8	e, (0x0ec4)
	sla e, 2
	xor	d, d
	extz	xde
	add	xix, xde
	xor	de, de
	ld	(xix), e
	ld	(xix+1), a
	ld	(xix+2), de
	ret
OscScope_Handler_7_Helper:
	pushw	wa
	push	xhl
	ld	a, (3770:16)
	ld	w, 96:opc
	muls	wa, w
	ld	l, (3769:16)
	xor	h, h
	add	wa, hl
	.set	OscScope_DrawWaveform, . + 3	; no instruction starts here: the name points 3 byte(s) into the one below
	ld	(0x0ec2:16), wa
	pop	xhl
	popw	wa
	ret
SubCPU_ToneParamRet_Helper12:
	cp	(0x0f70:16), 48
	jrl	nz, OscScope_RefreshLoop
	ld	wa, (3778:16)
	ld	l, (3952:16)
	xor	h, h
	sub	wa, hl
OscScope_UpdateDisplay:
	cp	wa, 48
	jrl	z, OscScope_UpdateDisplay_Skip
	ld	l, 96:opc
	div	wa, l
	cp	w, 48
	jrl	z, OscScope_UpdateDisplay_Skip2
	exts	wa
	ld	bc, wa
	pushw	bc
	call	OscScope_UpdateDisplay_Helper
	popw	bc
	djnz16	bc, -9
	ldw	(3778:16), 0
	jp	OscScope_RefreshLoop_Return
OscScope_UpdateDisplay_Skip2:
	ld	wa, (3778:16)
	ld	l, 96:opc
	div	wa, l
	cp	a, 0:i3
	jrl	z, OscScope_UpdateDisplay_Skip
	ld	c, a
	ld	l, 96:opc
	muls	wa, l
	sub (3778:16), wa
	ld a, c
	dec	1, a
	cp	a, 0:i3
	jrl	z, OscScope_UpdateDisplay_Skip
	exts	wa
	ld	bc, wa
	pushw	bc
	call	OscScope_UpdateDisplay_Helper
	popw	bc
	djnz16	bc, -9
OscScope_UpdateDisplay_Skip:
	call	DisplayStr_BytecodeBlock_A_Code_Helper
	ldw	(3778:16), 0
	ld	(3952:16), 0
	jp	OscScope_RefreshLoop_Return
OscScope_RefreshLoop:
	ld	wa, (3778:16)
	ld	l, 96:opc
	div	wa, l
	ld	c, a
	ld	e, w
	cp	c, 0:i3
	jrl	z, OscScope_RefreshLoop_Skip
	ld	a, 96:opc
	muls	wa, c
	sub (3778:16), wa
	xor b, b
	pushw	bc
	pushw	de
	call	OscScope_UpdateDisplay_Helper
	popw	de
	popw	bc
	cp	(0x0ef6:16), 0
	jrl	nz, OscScope_RefreshLoop_Return
	djnz16	bc, -19
OscScope_RefreshLoop_Skip:
	cp	e, 0:i3
	jrl	z, OscScope_RefreshLoop_Return
	cp	(0x0f70:16), 48
	jrl	z, OscScope_RefreshLoop_Return
	call	DisplayStr_BytecodeBlock_A_Code_Helper
OscScope_RefreshLoop_Return:
	ret
MemConfig_Handler_4_Helper_Helper2:
	push	xhl
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, OscScope_Handler_7_Skip2
	ld	a, 7:opc
	call	VoiceSlot_SaveState
	xor	bc, bc
	ld	l, (3822:16)
	xor	h, h
	dec	1, hl
	sla	hl, 1
	push	xde
	ld	xde, 3230
	ld	wa, (xde+hl)
	pop	xde
	cp	wa, 0xffff
	jrl	z, OscScope_RenderBlock_Skip2
	cp	wa, 0:i3
	jrl	z, OscScope_RenderBlock_Skip2
OscScope_RefreshLoop_Loop:
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
	cp	c, 2:i3
	jrl	ugt, OscScope_RenderBlock_Skip
	cp	a, 129
	jrl	z, OscScope_RefreshLoop_Loop
	cp	a, 130
	jrl	z, OscScope_RenderBlock_Skip2
OscScope_RenderBlock:
	cp	a, 132
	jrl	z, OscScope_RenderBlock_Skip2
OscScope_RenderBlock_Skip:
	ld	w, 255:opc
	jp	OscScope_RenderBlock_Join3
OscScope_RenderBlock_Skip2:
	ld	w, 0:opc
OscScope_RenderBlock_Join3:
	pop	xhl
	pushw	wa
	ld	a, 7:opc
	call	VoiceSlot_RestoreState
	popw	wa
	jp	OscScope_RenderBlock_Return2
OscScope_Handler_7_Skip2:
	ld	bc, 2:i3
	pop	xhl
	ld	w, 255:opc
OscScope_RenderBlock_Return2:
	ret
SubCPU_ToneParamRet_Helper13:
	call	OscScope_RenderBlock_Helper
	call	SubCPU_ToneParamRet_Helper14
	call	SubCPU_ToneParamRet_Helper15
	ret
OscScope_RenderBlock_Helper:
	ld	xix, 3669
	ldw	bc, 16
	xor	wa, wa
	ld	(xix+), wa
	djnz16	bc, -6
	ret
SubCPU_ToneParamRet_Helper14:
	ld	xix, 3701
	ldw	bc, 16
	xor	wa, wa
	ld	(xix+), wa
	djnz16	bc, -6
	ret
SubCPU_ToneParamRet_Helper15:
	ld	xix, 3733
	ldw	bc, 16
	xor	wa, wa
	ld (xix+), wa
	djnz16	bc, -6
	ret
SubCPU_ToneParamRet_Helper16:
	ld	xiy, 3669
	.set	OscScope_FinalizeRender, . + 2	; no instruction starts here: the name points 2 byte(s) into the one below
	ld	xix, 0x0e59
	; framing ported from v10's source for the same label (same span length, statement for statement); 68 of 92 slots byte-identical
	ld	c, 1:opc
	ld	e, (3666:16)
	sla	e, 1
	call	OscScope_FinalizeRender_0x79
	; v10 does not spell this byte either
	cp	(0x117f:16), 0
	jrl	nz, OscScope_FinalizeRender_Return
	ld	xiy, 3701
	ld	xix, 3705
	ld	c, 1:opc
	ld	e, (3667:16)
	sla	e, 1
	call	OscScope_FinalizeRender_0x79
	; v10 does not spell this byte either
	cp	(0x117f:16), 0
	jrl	nz, OscScope_FinalizeRender_Return
	ld	xiy, 3733
	ld	xix, 3737
	ld	c, 1:opc
	ld	e, (3668:16)
	sla	e, 1
	call	OscScope_FinalizeRender_0x79
	ld	xiy, 3697
	; v10 does not spell this byte either
	cp	(xiy), 0
	jrl	z, OscScope_FinalizeRender_Skip
	; v10 does not spell this byte either
	ormi8	(xiy), 128
	; v10 does not spell this byte either
OscScope_FinalizeRender_Skip:
	ld	xiy, 3729
	; v10 does not spell this byte either
	cp	(xiy), 0
	jrl	z, OscScope_FinalizeRender_Skip2
	; v10 does not spell this byte either
	ormi8	(xiy), 128
	; v10 does not spell this byte either
OscScope_FinalizeRender_Skip2:
	ld	xiy, 3761
	; v10 does not spell this byte either
	cp	(xiy), 0
	jrl	z, OscScope_FinalizeRender_Return
	; v10 does not spell this byte either
	ormi8	(xiy), 128
	; v10 does not spell this byte either
OscScope_FinalizeRender_Return:
	ret
OscScope_FinalizeRender_0x79:
	ld	(4479:16), 0
	cp	e, 0:i3
	jrl	z, OscScope_DrawWaveform_Code_Helper_Return
OscScope_DrawWaveform_Code_Helper_Join:
	cp	c, e
	jrl	z, OscScope_DrawWaveform_Code_Helper_Return
	ld	a, (xiy+1)
	cp	a, 6:i3
	jrl	z, OscScope_FinalizeRender_Skip3
	cp	a, 7:i3
	jrl	nz, OscScope_FinalizeRender_Entry
OscScope_FinalizeRender_Skip3:
	ld	(4479:16), 255
	jp	OscScope_DrawWaveform_Code_Helper_Return
OscScope_FinalizeRender_Entry:
	; v10 does not spell this byte either
	cp	(xix+1), 0
	; v10 does not spell this byte either
	jrl	nz, OscScope_DrawWaveform_Code_Entry2
	; v10 does not spell this byte either
	cp	(xix+2), 0
	jrl	z, OscScope_FinalizeRender_Entry3
OscScope_DrawWaveform_Code_Entry2:
	; v10 does not spell this byte either
	cp	(xiy+2), 0
	jrl	nz, OscScope_DrawWaveform_Code_Helper_Skip
OscScope_FinalizeRender_Entry3:
	; v10 does not spell this byte either
	andmi8	(xiy), 127
	jp	OscScope_DrawWaveform_Code_Helper_Join2
OscScope_DrawWaveform_Code_Helper_Skip:
	ormi8	(xiy), 128
OscScope_DrawWaveform_Code_Helper_Join2:
	add	iy, 4
	add	ix, 4
	inc	1, c
	; v10 does not spell this byte either
	jp	OscScope_DrawWaveform_Code_Helper_Join
	; differs from v10 here and llvm-objdump cannot read it
OscScope_DrawWaveform_Code_Helper_Return:
	ret
VoiceBank_ProcessCommand:
	ld xix, 0xeb5
	call VoiceBank_LoadLerpState
	ld (xix+), a
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
	ld (xix+), a
	jp VoiceBank_CallAndLoop

VoiceBank_Ret:
	ret

VoiceBank_LoadLerpState:
	push xiz
	ld xiz, (4349:16)
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	push xix
	ld hl, (0x28bf:16)
	call DisplayStr_ComputeTableAddr
	ld xiy, (4349:16)
	ld ix, (0x28c1:16)
	ld	a, (xiy+ix)
	pop xix
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	ld (4349:16), xiz
	pop xiz
	ret

VoiceBank_UpdateLerpState:
	push xiz
	ld xiz, (4349:16)
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	push xix
	ld wa, (0x28c1:16)
	cp wa, 0xff
	jrl nz, VoiceBank_IncrementIndex
	ld hl, (0x28bf:16)
	call DisplayStr_ComputeTableAddr
	ld xhl, (4349:16)
	ld hl, (xhl + 3)
	ld (0x28bf:16), hl
	ld wa, 5:i3
	jp VoiceBank_StoreIndex

VoiceBank_IncrementIndex:
	inc 1, wa

VoiceBank_StoreIndex:
	ld (0x28c1:16), wa
	pop xix
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	ld (4349:16), xiz
	pop xiz
	ret

DisplayStr_BytecodeBlock_A:
	ld	(0x0ef6:16), 0
	ldb_d8	c, (0x0ec1)
	sla	c, 1
	xor	hl, hl
	ldb_d8	l, (0x0ec4)
	sla	hl, 2
	xor	wa, wa
	ld	xiy, (0x1114:16)
	ld	a, (xiy+hl)
	and	a, 96
	cp	a, 0:i3
	jrl	nz, DisplayStr_BytecodeBlock_A_Skip4
	ld	a, 32:opc
	ld	(xiy+hl), a
DisplayStr_BytecodeBlock_A_Skip4:
	xor	wa, wa
	ldfr_lerp	xiy, 56
	lda	xiy, (xiy+hl)
	ld	(xiy+1), 3
	ldto_lerp	xiy, 56
	ldfr_lerp	xiy, 56
	lda	xiy, (xiy+hl)
	ld	(xiy+2), wa
	ldto_lerp	xiy, 56
	call	OscScope_UpdateDisplay_Helper
DisplayStr_BytecodeBlock_A_Return3:
	ret
OscScope_UpdateDisplay_Helper:
	ld (0x0ef6:16), 0x00
	addw (0x0ec4:16), 0x0002
	ld c, (0x0ec1:16)
	sla C, 0x01
	cp	(3780:16), c
	jrl	c, DisplayStr_BytecodeBlock_A_Return
	ld	l, (3782:16)
	cp	l, 2:i3
	jrl	z, DisplayStr_BytecodeBlock_A_Loop
	inc	1, l
	xor	h, h
	sla	hl, 2
	push	xde
	ld	xde, DisplayStr_BytecodeBlock_A_Tbl
	ld	xhl, (xde+hl)
	pop	xde
	ld	wa, (xhl)
	cp	wa, 0:i3
	jrl	nz, DisplayStr_BytecodeBlock_A_Skip
DisplayStr_BytecodeBlock_A_Loop:
	ld	(3830:16), 1
	jp	DisplayStr_BytecodeBlock_A_Return3
DisplayStr_BytecodeBlock_A_Skip:
	ld	l, (3782:16)
	cp	l, 2:i3
	jrl	z, DisplayStr_BytecodeBlock_A_Loop
	inc	1, l
	ld	xwa, 3701
	ld	e, (3667:16)
	cp	l, 1:i3
	jrl	z, DisplayStr_BytecodeBlock_A_Skip2
	ld	xwa, 3733
	ld	e, (3668:16)
DisplayStr_BytecodeBlock_A_Skip2:
	ld	(3777:16), e
	ld	(4372:16), xwa
	ld	(3782:16), l
	xor	b, b
	sub (3780:16), bc
DisplayStr_BytecodeBlock_A_Return:
	ret
SubCPU_ToneParamRet_Helper17:
	ld	(3830:16), 0
	ld	c, (3777:16)
	sla	c, 1
	xor	hl, hl
	ld	l, (3780:16)
	sla	hl, 2
	xor	wa, wa
	ld	xiy, (4372:16)
	ld	a, (xiy+hl)
	and	a, 96
	cp	a, 0:i3
	jrl	nz, DisplayStr_BytecodeBlock_A_Skip5
	ld	a, 32:opc
	ld	(xiy+hl), a
DisplayStr_BytecodeBlock_A_Skip5:
	xor	wa, wa
	ldfr_lerp	xiy, 56
	lda	xiy, (xiy+hl)
	ld	(xiy+1), 4
	ldto_lerp	xiy, 56
	ldfr_lerp	xiy, 56
	lda	xiy, (xiy+hl)
	ld	(xiy+2), wa
	ldto_lerp	xiy, 56
	call	DisplayStr_BytecodeBlock_A_Code_Helper
DisplayStr_BytecodeBlock_A_Return4:
	ret
DisplayStr_BytecodeBlock_A_Code_Helper:
	ld	(3830:16), 0
	incw	1, (3780:16)
	ld	c, (3777:16)
	sla	c, 1
	cp	(3780:16), c
	jrl	c, DisplayStr_BytecodeBlock_A_Return2
	ld	l, (3782:16)
	cp	l, 2:i3
	jrl	z, DisplayStr_BytecodeBlock_A_Loop2
	inc	1, l
	xor	h, h
	sla	hl, 2
	push	xde
	ld	xde, DisplayStr_BytecodeBlock_A_Tbl
	ld	xhl, (xde+hl)
	pop	xde
	ld	wa, (xhl)
	cp	wa, 0:i3
	jrl	nz, DisplayStr_BytecodeBlock_A_Skip3
DisplayStr_BytecodeBlock_A_Loop2:
	ld	(3830:16), 1
	jp	DisplayStr_BytecodeBlock_A_Return4
DisplayStr_BytecodeBlock_A_Skip3:
	ld	l, (3782:16)
	cp	l, 2:i3
	jrl	z, DisplayStr_BytecodeBlock_A_Loop2
	inc	1, l
	ld	xwa, 3701
	ld	e, (3667:16)
	cp	l, 1:i3
	jrl	z, DisplayStr_BytecodeBlock_A_Skip6
	ld	xwa, 3733
	ld	e, (3668:16)
DisplayStr_BytecodeBlock_A_Skip6:
	ld	(3777:16), e
	ld	(4372:16), xwa
	ld	(3782:16), l
	xor	b, b
	sub (3780:16), bc
DisplayStr_BytecodeBlock_A_Return2:
	ret
	; Byte data, 12 B.  Read by DisplayStr_BytecodeBlock_A (0xEFEADC): `ld xde, DisplayStr_BytecodeBlock_A_Tbl`
	; indexed with stride 4 (`sla hl, 2`), index from `ld l, (3782:16)`
DisplayStr_BytecodeBlock_A_Tbl:
	.byte	0x4c, 0x0e, 0x00, 0x00, 0x4e, 0x0e, 0x00, 0x00, 0x50, 0x0e, 0x00, 0x00
SubCPU_ToneParamRet_Helper18:
	pushdi_w	(0x28bf)
	pushdi_w	(0x28c1)
	push	xhl
	push	xiy
	push	xix
DisplayStr_BytecodeBlock_A_Code_Loop3:
	ld	xix, 3771
	call	VoiceBank_LoadLerpState
DisplayStr_BytecodeBlock_A_Code_Loop4:
	ld	(xix), a
	cp	a, 129
	jrl	z, DisplayStr_BytecodeBlock_A_Code_Helper_Skip2
	cp	a, 132
	jrl	z, DisplayStr_BytecodeBlock_A_Code_Helper_Skip2
	cp	a, 130
	jrl	z, DisplayStr_BytecodeBlock_A_Code_Helper_Skip2
	inc	1, xix
	push	xix
	call	VoiceBank_UpdateLerpState
	call	VoiceBank_LoadLerpState
	pop	xix
	bit	7, a
	jrl	z, DisplayStr_BytecodeBlock_A_Code_Loop4
	ld	a, (3772:16)
	cp	a, 47
	jrl	z, DisplayStr_BytecodeBlock_A_Code_Loop3
	cp	a, 95
	jrl	z, DisplayStr_BytecodeBlock_A_Code_Loop3
DisplayStr_BytecodeBlock_A_Code_Helper_Skip2:
	pop	xix
	pop	xiy
	pop	xhl
	popw (0x28c1:16)	; popw (0x28c1)
	popw (0x28bf:16)	; popw (0x28bf)
	ret
DisplayStr_ComputeTableAddr:
	dec 1, hl
	extz xhl
	sla xhl, 8
	add xhl, (7514:16)
	ld (4349:16), xhl
	xor xhl, xhl
	ret

DisplayStr_BytecodeBlock_B:
	call	Display_UpdateRegion0
DisplayStr_BytecodeBlock_B_Sub:
	call	Display_BytecodeBlock_F_Sub2
	ld	xix, 0x0eca
	ldw	wa, 8224
	ldw	bc, 15
	ld	(xix+), wa
	djnz16	bc, -6
	ld	xiy, Str_Control
	ld	xix, 0x0ecf
	ld	bc, 7:i3
	ldir85
	ld	a, 32:opc
	ld	(xix+), a
	call	Display_UpdateRegion5
	call	PerfMode_EventTable_0_Target1_Helper4
	call	Display_UpdateRegion3
	ret
DisplayStr_BytecodeBlock_B_0x39:
	call	Display_UpdateRegion0
DisplayStr_BytecodeBlock_B_Sub2:
	call	Display_BytecodeBlock_F_Sub2
	ld	xiy, Str_Control
	ld	xix, 0x0ecf
	ld	bc, 7:i3
	ldir85
	call	Display_UpdateRegion5
	call	PerfMode_EventTable_0_Target1_Helper4
	call	Display_UpdateRegion3
	ret
	; Lcd text, 7 B.  Read by DisplayStr_BytecodeBlock_B (0xEFECE8): `ld xiy, Str_Control`
	; copies 7 byte(s) per use (`ld bc, 7` + ldir) into the LCD text buffer
Str_Control:
	.ascii	"CONTROL"
Str_Control_Helper:
	ldb_d8	h, (0x3687)
	ldb_d8	l, (0x3686)
	ldb_d8	h, (0x0ef5)
	ld	(0x905b:16), 72
	call	PartCtrl_WriteProgramChange
	call	AccVoice_DispatchEntry
	ld	xiy, 0x340f
	ld	xix, 0x0ed6
	ldw	bc, 13
	ldir85
	ret
DisplayMode_Handler_3_Helper10_Helper:
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_Sub2
	ld	xiy, Str_Rhythm
	ld	xix, 0x0ecf
	ld	bc, 6:i3
	ldir85
	call	Display_UpdateRegion5
	call	Str_Control_Helper
	call	Display_UpdateRegion3
	ret
	; Lcd text, 1 B.  Read by DisplayStr_BytecodeBlock_B (0xEFECE8): `ld xiy, DisplayStr_RhythmLabel`
	; also read by DisplayStr_BytecodeBlock_C
DisplayStr_RhythmLabel:
	.ascii	" "
	; Lcd text, 9 B.  Read by DisplayStr_BytecodeBlock_B (0xEFECE8): `ld xiy, Str_Rhythm`
	; copies 6 byte(s) per use (`ld bc, 6` + ldir) into the LCD text buffer
Str_Rhythm:
	.ascii	"RHYTHM   "
VoiceCtrl_ParamSetupBytecode_Sub_Helper:
	pushw	bc
	call	Display_BytecodeBlock_F_Sub2
	ld	xiy, DisplayStr_RhythmLabel
	push	xiy
	call	Str_Rhythm_Helper2
	pop	xiy
	bit	0, (0x10f6:16)
	jrl	z, DisplayStr_BytecodeBlock_B_Skip
	ld	xiy, Str_MSA
DisplayStr_BytecodeBlock_B_Skip:
	ld	xix, 0x0ecf
	ld	bc, 5:i3
	ldirw
	popw	bc
	ld	xix, 0x0ed9
	call	Str_Rhythm_Helper
	call	Display_UpdateRegion5
	call	Display_UpdateRegion3
	ret
	; Lcd text, 10 B.  Read by DisplayStr_BytecodeBlock_B (0xEFECE8): `ld xiy, Str_MSA`
	; copies 5 byte(s) per use (`ld bc, 5` + ldir) into the LCD text buffer
Str_MSA:
	.ascii	"M.S.A.    "
VoiceCtrl_ParamSetupBytecode_Sub_Helper2:
	pushw	bc
	call	DMA_ChannelHandler_3_Helper
	call	DisplayStr_ClearRegion
	popw	bc
	ld	xix, 0x0ed4
	call	Str_Rhythm_Helper
	call	Display_UpdateRegion3
	ret
Str_Rhythm_Helper:
	xor	wa, wa
	ld	a, c
	and	a, 48
	sra	a, 4
	inc	1, a
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ld	xiy, Str_VarivariOff
	ld	bc, 4:i3
	ldir85
	ldb_d8	a, (0x1183)
	ld	(xix), a
	ret
	; Lcd text, 12 B.  Read by DisplayStr_BytecodeBlock_B (0xEFECE8): `ld xiy, Str_VarivariOff`
	; copies 4 byte(s) per use (`ld bc, 4` + ldir) into the LCD text buffer
Str_VarivariOff:
	.ascii	"VARIVARI OFF"
DisplayStr_BytecodeBlock_C_Helper:
	call DisplayStr_ClearRegion
	ld XIY,DisplayStr_StyleSectionNames
	ld XIX,0x00000ed8
	xor XWA,XWA
	ld a, (0x368c:16)
	sla XWA, 0x03
	add XIY,XWA
	ld bc, 4:i3
	ldirw
	ret
DisplayStr_BytecodeBlock_C:
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_Sub2
	ld	xiy, DisplayStr_RhythmLabel
	ld	xix, 3791
	ldw	bc, 9
	ldir85
	call	Display_UpdateRegion5
	call	DisplayStr_BytecodeBlock_C_Helper
	call	Display_UpdateRegion3
	ret
DisplayStr_BytecodeBlock_C_0x24:
	call	Display_BytecodeBlock_F_Sub2
	ld	xix, 3786
	ld	xiy, Str_TempoEq
	cp	(0xfc5a:16), 7
	jrl	nz, DisplayStr_BytecodeBlock_C_Skip
	cp	(0xfc5b:16), 2
	jrl	nz, DisplayStr_BytecodeBlock_C_Skip
	ld	xiy, DisplayStr_BytecodeBlock_C_Tbl
DisplayStr_BytecodeBlock_C_Skip:
	ld	xix, 3791
	ldw	bc, 25
	ldir85
	call	Display_UpdateRegion5
	call	Display_BytecodeBlock_F_Helper
	call	Display_UpdateRegion3
	ret
	; Lcd text, 25 B.  Read by DisplayStr_BytecodeBlock_C (0xEFEE47): `ld xiy, Str_TempoEq`
	; reader DisplayStr_BytecodeBlock_C: `ld xiy, Str_TempoEq`
Str_TempoEq:
	.ascii	"  TEMPO  "
	.byte	0x15
	.ascii	"=              "
	; Byte data, 25 B.  Read by DisplayStr_BytecodeBlock_C (0xEFEE47): `ld xiy, DisplayStr_BytecodeBlock_C_Tbl`
	; copies 25 byte(s) per use (`ld bc, 25` + ldir) into the LCD text buffer
DisplayStr_BytecodeBlock_C_Tbl:
	.ascii	"  TEMPO  "
	.byte	0x93
	.ascii	"=              "
VoiceSlot_StatusRet_Helper3:
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_Sub2
	ld	xiy, DisplayStr_TempoString
	cp	(0xfc5a:16), 7
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Helper10_Skip
	cp	(0xfc5b:16), 2
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Helper10_Skip
	ld	xiy, DisplayStr_BytecodeBlock_C_Tbl2
VoiceCtrl_ParamSetupBytecode_Helper10_Skip:
	ld	xix, 3791
	ldw	bc, 25
	ldir85
	call	Display_UpdateRegion5
	call	Display_BytecodeBlock_F_Helper
	call	Display_UpdateRegion3
	ret
	; Lcd text, 25 B.  Read by DisplayStr_BytecodeBlock_C (0xEFEE47): `ld xiy, DisplayStr_TempoString`
	; reader DisplayStr_BytecodeBlock_C: `ld xiy, DisplayStr_TempoString`
DisplayStr_TempoString:
	.ascii	"  TEMPO  "
	.byte	0x15
	.ascii	"=              "
	; Byte data, 25 B.  Read by DisplayStr_BytecodeBlock_C (0xEFEE47): `ld xiy, DisplayStr_BytecodeBlock_C_Tbl2`
	; copies 25 byte(s) per use (`ld bc, 25` + ldir) into the LCD text buffer
DisplayStr_BytecodeBlock_C_Tbl2:
	.ascii	"  TEMPO  "
	.byte	0x93
	.ascii	"=              "
DisplayMode_Handler_2_Helper:
	call	Display_UpdateRegion0
DisplayStr_BytecodeBlock_C_Tbl2_Sub:
	call Display_BytecodeBlock_F_Sub2
	ld XIY,DisplayStr_BytecodeBlock_C_Text
	ld XIX,0x00000eca
	ldw BC, 0x0019
	ldir85
	call	Display_UpdateRegion5
	call	Display_UpdateRegion3
	call	Display_UpdateRegion4
	ret
	; Lcd text, 25 B.  Read by DisplayStr_BytecodeBlock_C (0xEFEE47): `ld XIY,DisplayStr_BytecodeBlock_C_Text`
	; copies 25 byte(s) per use (`ld bc, 25` + ldir) into the LCD text buffer
DisplayStr_BytecodeBlock_C_Text:
	.ascii	"                         "
DisplayMode_Handler_3_Helper19:
	call	Display_UpdateRegion0
	ret
DMA_ChannelHandler_3_Helper:
	ld wa, (0x367e:16)
	cp WA,0x03e8
	jrl c, .Lc_efef97
	call DisplayStr_FillDashes
	jp DisplayStr_BytecodeBlock_C_Text_Return
.Lc_efef97:
	call ParamDigit_ExtractAndFormat
	ld XIY,0x00001181
	ld XIX,0x00000eca
	ld WA,(XIY)
	ld (XIX),WA
	ld A,(XIY+0x02)
	ld (XIX+0x02),A
DisplayStr_BytecodeBlock_C_Text_Return:
	ret
DisplayStr_FillDashes:
	ld xix, 0xeca
	ld a, 0x2d:opc
	ld (xix), a
	ld (xix + 1), a
	ld (xix + 2), a
	ret

DisplayStr_BytecodeBlock_D:
	call	Display_UpdateRegion0
	call	DMA_ChannelHandler_3_Helper
	ldb_d8	h, (0x3687)
	ldb_d8	l, (0x3686)
	ldb_d8	h, (0x0ef5)
	ld	(0x905b:16), 72
	call	PartCtrl_WriteProgramChange
	call	AccVoice_DispatchEntry
	call	DisplayStr_ClearRegion
	ld	xiy, 0x340f
	ld	xix, 0x0ecf
	ldw	bc, 13
	ldir85
	ld	a, 32:opc
	ld	(xix+), a
	call	Display_UpdateRegion3
	ret
DisplayStr_ClearRegion:
	pushw wa
	pushw bc
	push xix
	ld xix, 0xecd
	ldw bc, 0x1b
	ld a, 0x20:opc

DisplayStr_ClearLoop:
	ld (xix+), a
	djnz16 bc, DisplayStr_ClearLoop
	pop xix
	popw bc
	popw wa
	ret

DisplayStr_StyleSectionInit:
	call DisplayStr_ClearRegion
	ld XIY,DisplayStr_StyleSectionNames
	ld XIX,0x00000ece
	xor WA,WA
	ld a, (0x368c:16)
	sla WA, 0x03
	lda	xiy, (xiy+wa)
	ldw	wa, 8224
	ld	(xix+), wa
	ld	(xix+), wa
	ld	bc, 4:i3
	ldirw
	ld	a, 32:opc
	ld	bc, 3:i3
DisplayStr_StyleClearLoop:
	ld (xix+), a
	djnz16 bc, DisplayStr_StyleClearLoop
	call Display_UpdateRegion3
	ret

DisplayStr_BytecodeBlock_E:
	ret
SerialPort_ModeHandler_0_Helper:
	ld XIX,0x00000ed4
	xor XHL,XHL
	ld l, (0x368c:16)
	sla XHL, 0x03
	ld XIY,DisplayStr_StyleSectionNames
	lda	xiy, (xiy+hl)
	ld	bc, 4:i3
	ldirw
	ldw	wa, 8224
	ld	(xix+), wa
	ld	(xix+), wa
	call	Display_UpdateRegion3
	ret
	; Byte data, 105 B.  Read by DisplayStr_BytecodeBlock_B (0xEFECE8): `ld XIY,DisplayStr_StyleSectionNames`
	; indexed with stride 1 (`sla XWA, 0x03`)
	; copies 4 byte(s) per use (`ld bc, 4` + ldir) into the LCD text buffer
	; also read by DisplayStr_BytecodeBlock_E, DisplayStr_StyleSectionInit
DisplayStr_StyleSectionNames:
	.ascii	"        START   STOP    FILL IN1FILL IN2INTRO1  COUNT INENDING1 END     REPEAT  CLEAR   ENDING2 INTRO2  "
	.byte	0x0e
VoiceState_DataBlock2_Helper16:
	call	Display_UpdateRegion2
	ret

Display_RedrawMenu:
	ld	wa, (13950:16)
	cp	wa, 1000
	jrl	c, Display_RedrawMenu_Extract
	call	DisplayStr_FillDashes
	jp	Display_RedrawMenu_Update
Display_RedrawMenu_Extract:
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	xix, 3786
	ld	wa, (xiy)
	ld	(xix), wa
	ld	a, (xiy+2)
	ld	w, (13952:16)
	ld	(xix+2), wa
Display_RedrawMenu_Update:
	call Display_UpdateRegion3
	ret

Display_BytecodeBlock_F:
	call Display_UpdateRegion0
Display_BytecodeBlock_F_Sub3:
	call Display_BytecodeBlock_F_Sub2
	ld XIX,0x00000eca
	ldw (XIX+0x09), 0x5620
	call Display_UpdateRegion5
	call Disp_ShowNoteNameAndVelocity
	call Disp_ShowNoteValueFields
	call Display_UpdateRegion3
	call Display_UpdateRegion4
	ret
Display_BytecodeBlock_F_Sub_Helper:
	ld	xix, 3796
	ld	xiy, Display_BytecodeBlock_F_Data
	ld	a, (4539:16)
	ld	xhl, Display_BytecodeBlock_F_Tbl
	ld	a, (xhl+a)
	exts	wa
	cp	(4539:16), 23
	jrl	nz, Display_BytecodeBlock_F_Skip
	ld	a, 17:opc
	jp	Display_BytecodeBlock_F_Join
Display_BytecodeBlock_F_Skip:
	cp	(4539:16), 64
	jrl	nz, Display_BytecodeBlock_F_Join
	ld	a, 16:opc
Display_BytecodeBlock_F_Join:
	sla	a, 2
	exts	xwa
	add	xiy, xwa
	ld	wa, (xiy)
	ld	(xix), wa
	ld	wa, (xiy+2)
	ld	(xix+2), wa
	ld	w, (4539:16)
	ld	(36955:16), w
	ld	l, (4541:16)
	ld	h, (4540:16)
	cp	w, 23
	jrl	nz, Display_BytecodeBlock_F_Skip3
	ld	xix, 3800
	ld	xiy, Str_OnOffPair
	cp	l, 127
	jrl	nz, Display_BytecodeBlock_F_Skip2
	cp	h, 3:i3
	jrl	nz, Display_BytecodeBlock_F_Skip2
	inc	4, xiy
Display_BytecodeBlock_F_Skip2:
	ld	bc, 4:i3
	ldir85
	jp	Display_BytecodeBlock_F_Return
Display_BytecodeBlock_F_Skip3:
	call	PartCtrl_WriteProgramChange
	ld	a, 9:opc
	mul	wa, l
	ld	hl, wa
	push	xde
	xor	xwa, xwa
	xor	xbc, xbc
	ld	a, (4541:16)
	ld	c, (4540:16)
	ld	xde, 4543
	call	Display_BytecodeBlock_F_Helper2
	pop	xde
	ld	xiy, 4543
	ld	xix, 3800
	cp	(4539:16), 64
	jrl	nz, Display_BytecodeBlock_F_Skip9
	cp	(4541:16), 128
	jrl	nz, Display_BytecodeBlock_F_Skip9
	cp	(4540:16), 3
	jrl	nz, Display_BytecodeBlock_F_Skip9
	ldw	(xix), 17999
	ld	(xix+2), 70
	jp	Display_BytecodeBlock_F_Return
Display_BytecodeBlock_F_Skip9:
	ldw	bc, 16
	ldir85
Display_BytecodeBlock_F_Return:
	ret
	; Byte data, 16 B.  Read by Display_BytecodeBlock_F (0xEFF11A): `ld xhl, Display_BytecodeBlock_F_Tbl`
	; reader Display_BytecodeBlock_F: `ld xhl, Display_BytecodeBlock_F_Tbl` then `ld_rr8b a, xhl, a`
Display_BytecodeBlock_F_Tbl:
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b
	.byte	0x0c, 0x0d, 0x0e, 0x0f
Display_BytecodeBlock_F_Data:
	.ascii	"RT1 RT2 LFT P 4 P 5 P 6 P 7 P 8 P 9 P10 P11 P12 P13 P14 P15 KBP DUALMSP ----"
	.byte	0x01, 0x02, 0x03, 0x04
Display_BytecodeBlock_F_Sub:
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_Sub2
	ld	xix, 3786
	ld	(xix+4), 83
	ldw	(xix+5), 21839
	ldw	(xix+7), 17486
	call	Display_UpdateRegion5
	call	Display_BytecodeBlock_F_Sub_Helper
	call	Display_UpdateRegion3
	ret
PerfMode_EventTable_0_Target1_Helper4:
	ld	xiy, Str_PBendModExpEq
	ld	xix, 3800
	xor	hl, hl
	ld	l, (13956:16)
	and	l, 7
	sla	hl, 3
	lda	xiy, (xiy+hl)
	ld	wa, (xiy)
	ld	(xix), wa
	ld	wa, (xiy+2)
	ld	(xix+2), wa
	ld	wa, (xiy+4)
	ld	(xix+4), wa
	ld	w, (xiy+6)
	ld	(xix+6), w
	cp	l, 0:i3
	jrl	z, Display_BytecodeBlock_F_Return2
	cp	(13956:16), 1
	jrl	nz, Display_BytecodeBlock_F_Skip4
	call	Display_BytecodeBlock_F_Sub_Helper2
	jp	Display_BytecodeBlock_F_Return2
Display_BytecodeBlock_F_Skip4:
	ld	xix, 3807
	ld	a, (13957:16)
	bit	7, a
	jrl	z, Display_BytecodeBlock_F_Skip5
	and	a, 127
	cp	a, 0:i3
	jrl	z, Display_BytecodeBlock_F_Join2
	ld	xiy, Display_BytecodeBlock_F_0x253
	jp	Display_BytecodeBlock_F_Join2
	ld	xiy, Display_BytecodeBlock_F_0x256
Display_BytecodeBlock_F_Join2:
	ld	wa, (xiy)
	ld	(xix), wa
	ld	a, (xiy+2)
	ld	(xix+2), a
	jp	Display_BytecodeBlock_F_Return2
Display_BytecodeBlock_F_Skip5:
	xor	w, w
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	wa, (xiy)
	ld	(xix), wa
	ld	a, (xiy+2)
	ld	(xix+2), a
Display_BytecodeBlock_F_Return2:
	ret
	; Lcd text, 72 B.  Read by Display_BytecodeBlock_F (0xEFF11A): `ld xiy, Str_PBendModExpEq`
	; indexed with stride 8 (`sla hl, 3`)
Str_PBendModExpEq:
	.ascii	"        P.BEND= MOD.  = EXP.  = P.MEM = AFT.  =                          ONOFF"
Display_BytecodeBlock_F_Sub_Helper2:
	xor	xwa, xwa
	ldb_d8	a, (0x3685)
	ldb_d8	w, (0x1112)
	and	a, 127
	and	w, 127
	rrc	w
	ld	e, w
	and	e, 128
	and	w, 127
	or	a, e
	ldw	de, 1000
	div	xwa, de
	push	xwa
	call	ParamDigit_ExtractAndFormat
	pop	xwa
	ld	xix, 3807
	ld	xiy, 4482
	ld	bc, 2:i3
	ldir85
	ld	wa, qwa
	push	xix
	call	ParamDigit_DivideValue
	pop	xix
	ld	xiy, 4481
	ld	bc, 3:i3
	ldir85
	ret
Display_BytecodeBlock_F_Helper:
	ld	wa, (3826:16)
	cp	(64602:16), 7
	jrl	nz, Display_BytecodeBlock_F_Skip6
	cp	(64603:16), 2
	jrl	nz, Display_BytecodeBlock_F_Skip6
	pushw	hl
	sla	wa, 1
	ld	l, 3:opc
	div	wa, l
	popw	hl
	xor	w, w
Display_BytecodeBlock_F_Skip6:
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	xix, 3802
	ld	wa, (xiy)
	ld	(xix), wa
	ld	w, (xiy+2)
	ld	(xix+2), w
	ret
VoiceSlot_StatusRet_Helper4:
	ld	xiy, Display_BytecodeBlock_F_Tbl2
	ld	xix, 3791
	cp	(64602:16), 7
	jrl	nz, Display_BytecodeBlock_F_Skip7
	cp	(64603:16), 2
	jrl	nz, Display_BytecodeBlock_F_Skip7
	ld	xiy, Display_BytecodeBlock_F_0x31A
Display_BytecodeBlock_F_Skip7:
	ldw	bc, 26
	ldir85
	call	Display_BytecodeBlock_F_Helper
	call	Display_UpdateRegion3
	ret
	; Byte data, 19 B.  Read by Display_BytecodeBlock_F (0xEFF11A): `ld xiy, Display_BytecodeBlock_F_Tbl2`
	; reader Display_BytecodeBlock_F: `ld xiy, Display_BytecodeBlock_F_Tbl2`
Display_BytecodeBlock_F_Tbl2:
	.ascii	" TEMPO   "
	.byte	0x15
	.ascii	"="
	.byte	0x09
	.ascii	"        TEMPO   "
	.byte	0x93
	.ascii	"="
	.byte	0x09
	.ascii	"       "
Display_BytecodeBlock_F_Sub2:
	ldw	bc, 15
	ld	xix, 3786
	ldw	wa, 8224
	ld	(xix+), wa
	djnz16	bc, -6
	ret
ScoopDisp_DispatchTable_Small_Target11_Helper2:
	call	Display_UpdateRegion0
	ret
VoiceSlot_ComputeIndex_Helper:
	ld	bc, 7:i3
	ld	xix, 3796
	push	xix
	ldw	wa, 8224
	ld	(xix+), wa
	djnz16	bc, -6
	pop	xix
	cpw	(3426:16), 0
	jrl	z, Display_BytecodeBlock_F_Entry2
	ld	(xix+), 27
	ld	(xix+), 139
	ld	wa, (3426:16)
	call	UIRender_DescriptorTable2
	ld	xiy, 4481
	ld	a, (xiy+)
	ld	(xix+), a
	cp	(xiy), 32
	jrl	z, Display_BytecodeBlock_F_Entry
	ld	a, (xiy+)
	ld	(xix+), a
	cp	(xiy), 32
	jrl	z, Display_BytecodeBlock_F_Entry
	ld	a, (xiy+)
	ld	(xix+), a
Display_BytecodeBlock_F_Entry:
	bit	7, (0x0d64:16)
	jrl	z, Display_BytecodeBlock_F_Return3
	ld	(xix+), 43
Display_BytecodeBlock_F_Entry2:
	bit	7, (0x0d64:16)
	jrl	z, Display_BytecodeBlock_F_Return3
	ld	(xix), 28
Display_BytecodeBlock_F_Return3:
	ret
PortConfig_Handler_0_Helper3:
	ld	wa, (13950:16)
	cp	wa, 1000
	jrl	c, Display_BytecodeBlock_F_Skip8
	call	DisplayStr_FillDashes
	jp	Display_BytecodeBlock_F_Return4
Display_BytecodeBlock_F_Skip8:
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	xix, 3786
	ld	wa, (xiy)
	ld	(xix), wa
	ld	a, (xiy+2)
	ld	(xix+2), a
Display_BytecodeBlock_F_Return4:
	ret
SNS_Init_Startup:
	ld xix, 0xed4
	call SNS_LoadKeyAndChord
	call SNS_LoadDurationData
	ret

SNS_LoadKeyAndChord:
	xor xhl, xhl
	ld l, (3437:16)
	and l, 0xf
	sla hl, 1
	ld xiy, StringData_KeyNames
	lda	xiy, (xiy+hl)
	ld wa, (xiy)
	ld (xix), wa
	xor hl, hl
	ld l, (3438:16)
	and l, 0x3f
	ld a, 0x5:opc
	muls wa, l
	ld hl, wa
	extz xhl
	ld xiy, Tbl_ChordTypeNames
	lda	xiy, (xiy+hl)
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
	ld l, (3425:16)
	sla hl, 2
	ld xiy, Tbl_NoteValueGlyphs
	lda	xiy, (xiy+hl)
	ld wa, (xiy)
	ld (xix), wa
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ret

	; StringData_KeyNames: key-root names, 16 x 2 chars, read by SNS_LoadKeyAndChord (0xEFF4FC):
	; `ld l, (0x0d6d) / and l, 15 / sla hl, 1` then 2 bytes to (xix).  Entry 0
	; and 13-15 blank; 1-12 the chromatic scale C, D-flat, D, E-flat, E, F,
	; F-sharp, G, A-flat, A, B-flat, B with LCD glyph 0x88 = flat and
	; 0x8C = sharp (the same spellings as Tbl_KeyNamesBracketed's "Db"/"F#").
StringData_KeyNames:
	.byte 0x20, 0x20, 0x43, 0x20, 0x44, 0x88, 0x44, 0x20
	.byte 0x45, 0x88, 0x45, 0x20, 0x46, 0x20, 0x46, 0x8c
	.byte 0x47, 0x20, 0x41, 0x88, 0x41, 0x20, 0x42, 0x88
	.byte 0x42, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	; 64 x 5 chars, read by SNS_LoadKeyAndChord (0xEFF4FC): `ld l, (0x0d6e) /
	; and l, 0x3f / ld a, 5 / muls a, l` then 5 bytes to (xix+2).  Chord-type
	; names ("7", "Maj7", "aug", "min", "m7b5" ...); 0x88 = flat, 0x8C = sharp.
Tbl_ChordTypeNames:
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x37, 0x20, 0x20, 0x20, 0x20, 0x4d
	.byte 0x61, 0x6a, 0x37, 0x20, 0x61, 0x75, 0x67, 0x20
	.byte 0x20, 0x6d, 0x69, 0x6e, 0x20, 0x20, 0x6d, 0x69
	.byte 0x6e, 0x37, 0x20, 0x64, 0x69, 0x6d, 0x20, 0x20
	.byte 0x6d, 0x37, 0x88, 0x35, 0x20, 0x6d, 0x4d, 0x37
	.byte 0x20, 0x20, 0x37, 0x73, 0x75, 0x73, 0x34, 0x36
	.byte 0x20, 0x20, 0x20, 0x20, 0x61, 0x75, 0x67, 0x37
	.byte 0x20, 0x20, 0x20, 0x88, 0x35, 0x20, 0x37, 0x20
	.byte 0x88, 0x35, 0x20, 0x37, 0x39, 0x20, 0x20, 0x20
	.byte 0x37, 0x20, 0x88, 0x39, 0x20, 0x4d, 0x37, 0x39
	.byte 0x20, 0x20, 0x36, 0x39, 0x20, 0x20, 0x20, 0x6d
	.byte 0x36, 0x20, 0x20, 0x20, 0x6d, 0x20, 0x88, 0x35
	.byte 0x20, 0x6d, 0x37, 0x39, 0x20, 0x20, 0x6d, 0x36
	.byte 0x39, 0x20, 0x20, 0x73, 0x75, 0x73, 0x34, 0x20
	.byte 0x37, 0x20, 0x8c, 0x39, 0x20, 0x4d, 0x37, 0x88
	.byte 0x35, 0x20, 0x4d, 0x37, 0x8c, 0x35, 0x20, 0x6d
	.byte 0x4d, 0x37, 0x88, 0x35, 0x20, 0x20, 0x20, 0x31
	.byte 0x33, 0x39, 0x8c, 0x35, 0x20, 0x20, 0x88, 0x39
	.byte 0x20, 0x31, 0x33, 0x8c, 0x39, 0x20, 0x31, 0x33
	.byte 0x20, 0x20, 0x88, 0x31, 0x33, 0x88, 0x39, 0x88
	.byte 0x31, 0x33, 0x8c, 0x39, 0x88, 0x31, 0x33, 0x20
	.byte 0x20, 0x20, 0x31, 0x33, 0x20, 0x20, 0x88, 0x31
	.byte 0x33, 0x37, 0x20, 0x8c, 0x31, 0x31, 0x6d, 0x37
	.byte 0x20, 0x31, 0x31, 0x2b, 0x37, 0x8c, 0x31, 0x31
	.byte 0x20, 0x61, 0x64, 0x64, 0x39, 0x6d, 0x61, 0x64
	.byte 0x64, 0x39, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	; 8 x 4 chars, read by SNS_LoadDurationData (0xEFF543): `ld l, (0x0d61) /
	; sla hl, 2` then 4 bytes to 0x0EDD.  LCD note glyphs 0x13-0x16, '.' after
	; a glyph for the dotted value, "XX" in the last entry.
Tbl_NoteValueGlyphs:
	.byte 0x20, 0x20, 0x20, 0x20, 0x13, 0x20, 0x20, 0x20
	.byte 0x14, 0x2e, 0x20, 0x20, 0x14, 0x20, 0x20, 0x20
	.byte 0x15, 0x20, 0x20, 0x20, 0x15, 0x2e, 0x20, 0x20
	.byte 0x16, 0x20, 0x20, 0x20, 0x58, 0x58, 0x20, 0x20
	; Disp_ShowNoteValueFields
	; Fills three fields of the LCD text line from three small tables:
	; 0x0ED9 <- 3 chars of Tbl_NoteValueNames[((0x3678) & 15) * 4],
	; 0x0EDD <- 5 chars of Tbl_NoteValuePlusNames[((0x3679) & 15) * 5],
	; 0x0EE3 <- 4 chars of Tbl_ArticulationNames[((0x367a) & 3) * 4]
	; ("TENU"/"NORM"/"STAC"/"CUTT").  Called after (0x3678..0x367a) change
	; (PerfMode_Evt03_ClampAndUpdate clamps (0x367a) to 0..3 then calls this).
Disp_ShowNoteValueFields:
PerfMode_Evt03_FlagHandler_A_Code_Helper:
	ld XIX,0x00000ed9
	xor HL,HL
	ld l, (0x3678:16)
	and L,0x0f
	sla HL, 0x02
	ld XIY,Tbl_NoteValueNames
	lda	xiy, (xiy+hl)
	ld	wa, (xiy)
	ld	(xix+0:8), wa
	ld	w, (xiy+2)
	ld	(xix+2), w
	ld	xix, 3805
	xor	hl, hl
	ld	l, (13945:16)
	and	l, 15
	ld	a, 5:opc
	muls	wa, l
	ld	hl, wa
	ld	xiy, Tbl_NoteValuePlusNames
	lda	xiy, (xiy+hl)
	ld	wa, (xiy+0:8)
	ld	(xix+0:8), wa
	ld	wa, (xiy+2)
	ld	(xix+2), wa
	ld	a, (xiy+4)
	ld	(xix+4), a
	ld	xix, 3811
	xor	hl, hl
	ld	l, (13946:16)
	and	l, 3
	sla	hl, 2
	ld	xiy, Tbl_ArticulationNames
	lda	xiy, (xiy+hl)
	ld	wa, (xiy+0:8)
	ld	(xix+0:8), wa
	ld	wa, (xiy+2)
	ld	(xix+2), wa
	ret
	; 16 x 4 chars, read by Disp_ShowNoteValueFields (0xEFF6EF): `ld l,
	; (0x3678) / and l, 15 / sla hl, 2`, 3 bytes copied to 0x0ED9.  Note glyphs
	; 0x13-0x18 with 0x1F / 0x8B markers after some (tuplet-style values).
Tbl_NoteValueNames:
	.ascii	"     "
	.byte	0x18, 0x1f
	.ascii	"  "
	.byte	0x18
	.ascii	"   "
	.byte	0x17, 0x1f
	.ascii	"  "
	.byte	0x17
	.ascii	"   "
	.byte	0x16, 0x1f
	.ascii	"  "
	.byte	0x16
	.ascii	"   "
	.byte	0x15, 0x1f
	.ascii	"  "
	.byte	0x15
	.ascii	"   "
	.byte	0x14
	.ascii	"   "
	.byte	0x13
	.ascii	"  "
	.byte	0x13, 0x8b
	.ascii	"2 "
	.byte	0x13, 0x8b
	.ascii	"3 "
	.byte	0x13, 0x8b
	.ascii	"4         "
	; 16 x 5 chars, read by Disp_ShowNoteValueFields (0xEFF6EF): `ld l,
	; (0x3679) / and l, 15 / ld a, 5 / muls a, l`, 5 bytes to 0x0EDD.  The
	; Tbl_NoteValueNames values with a "+" in front.
Tbl_NoteValuePlusNames:
	.ascii	"     + "
	.byte	0x18, 0x1f
	.ascii	" + "
	.byte	0x18
	.ascii	"  + "
	.byte	0x17, 0x1f
	.ascii	" + "
	.byte	0x17
	.ascii	"  + "
	.byte	0x16, 0x1f
	.ascii	" + "
	.byte	0x16
	.ascii	"  + "
	.byte	0x15, 0x1f
	.ascii	" + "
	.byte	0x15
	.ascii	"  + "
	.byte	0x14
	.ascii	"  + "
	.byte	0x13
	.ascii	"  + "
	.byte	0x13, 0x8b
	.ascii	"2+ "
	.byte	0x13, 0x8b
	.ascii	"3+ "
	.byte	0x13, 0x8b
	.ascii	"4          "
	; 4 x 4 chars "TENU" "NORM" "STAC" "CUTT", read by Disp_ShowNoteValueFields
	; (0xEFF6EF): `ld l, (0x367a) / and l, 3 / sla hl, 2`, 4 bytes to 0x0EE3.
Tbl_ArticulationNames:
	.ascii	"TENUNORMSTACCUTT"
	; Disp_ShowNoteNameAndVelocity
	; 9 chars at 0x0ECF: blank when (0x367b) = 0xFF, else note name
	; Tbl_NoteNamesSharp[((0x367c) mod 12)*2] (2 chars, `divs a, 12` remainder),
	; octave Tbl_OctaveNames[((0x367c) div 12)*2] ("-2".."8"), 'V' at +5 and
	; (0x367b) in decimal at +6 -- a MIDI note number and its velocity.
Disp_ShowNoteNameAndVelocity:
DisplayMode_Handler_3_Helper20:
	ld	xix, 3791
	cp	(13947:16), 255
	jrl	nz, Disp_ShowNoteNameAndVelocity_Skip
	ldw	wa, 8224
	ld	(xix+0:8), wa
	ld	(xix+2), wa
	ld	(xix+4), wa
	ld	(xix+6), wa
	ld	(xix+8), a
	jp	Disp_ShowNoteNameAndVelocity_Return
Disp_ShowNoteNameAndVelocity_Skip:
	xor	wa, wa
	ld	a, (13948:16)
	ld	l, 12:opc
	divs	wa, l
	ld	xiy, Tbl_NoteNamesSharp
	xor	bc, bc
	ld	c, w
	sla	bc, 1
	lda	xiy, (xiy+bc)
	ld	bc, (xiy)
	ld	(xix), bc
	ld	xiy, Tbl_OctaveNames
	xor	bc, bc
	ld	c, a
	sla	bc, 1
	lda	xiy, (xiy+bc)
	ld	wa, (xiy)
	ld	(xix+2), wa
	xor	wa, wa
	ld	a, (13947:16)
	call	ParamDigit_ExtractAndFormat
	ld	wa, (4481:16)
	ld	(xix+6), wa
	ld	a, (4483:16)
	ld	(xix+8), a
	ld	(xix+5), 86
Disp_ShowNoteNameAndVelocity_Return:
	ret
	; 12 x 2 chars " C" "C#" " D" ... " B" (0x8C = sharp), read by
	; Disp_ShowNoteNameAndVelocity (0xEFF80D): index = (0x367c) mod 12,
	; `sla bc, 1`, 2 bytes to 0x0ECF.
Tbl_NoteNamesSharp:
	.ascii	" CC"
	.byte	0x8c
	.ascii	" DD"
	.byte	0x8c
	.ascii	" E FF"
	.byte	0x8c
	.ascii	" GG"
	.byte	0x8c
	.ascii	" AA"
	.byte	0x8c
	.ascii	" B"
	; 11 x 2 chars "-2" "-1" "0 " .. "8 ", read by Disp_ShowNoteNameAndVelocity
	; (0xEFF80D): index = (0x367c) div 12, `sla bc, 1`, 2 bytes to 0x0ED1.
Tbl_OctaveNames:
	.ascii	"-2-10 1 2 3 4 5 6 7 8 "
	; ParamPopup_PartVolume -- LCD parameter pop-up.
	; Pop-up id 10.  "<part> VOLUME=nnn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_VolumeEq,
	; value (0x10f3) in decimal.
ParamPopup_PartVolume:
	cp (0x0def:16), 0x0a
	jrl z, .Lc_eff8c1
	ld (0x0def:16), 0x0a
	call Display_UpdateRegion0
.Lc_eff8c1:
ParamPopup_PartVolume_Skip:
	call DisplayStr_ClearRegion
	ld l, (0x10f1:16)
	xor H,H
	sla HL, 0x02
	ld XIY,StringData_PartNames
	lda	xiy, (xiy+hl)
	ld	xix, 0x0ed1
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_VolumeEq
	inc	1, xix
	ld	bc, 7:i3
	ldir85
	ldb_d8	a, (0x10f3)
	xor	w, w
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ld	xiy, 0x1181
	inc	1, xix
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "VOLUME=", 7 chars copied by ParamPopup_PartVolume (0xEFF8B0).
	; reader ParamPopup_PartVolume: `ld xiy, Str_VolumeEq` then `ld bc, 7` + ldir (7 bytes copied)
Str_VolumeEq:
	.ascii	"VOLUME="
	; StringData_PartNames: 21 x 4 chars (RT1 RT2 LFT P 4 .. P15 KBP AC1 AC2 AC3 XXXX
	; DRUM), read by every ParamPopup_Part* routine: `ld l, (0x10f1) / sla hl,
	; 2 / ld xiy, StringData_PartNames / lda_rr xiy, xiy, hl / ld bc, 4 / ldir`.
StringData_PartNames:	.ascii "RT1 RT2 LFT P 4 P 5 P 6 P 7 P 8 P 9 P10 P11 P12 P13 P14 P15 KBP AC1 AC2 AC3 XXXXDRUM"
	; ParamPopup_PartPanpot -- LCD parameter pop-up.
	; Pop-up id 10.  "<part> PANPOT=nnn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_PanpotEq,
	; value (0x10f3) in decimal.
ParamPopup_PartPanpot:
	cp	(0x0def:16), 10
	jrl	z, ParamPopup_PartPanpot_Skip
	ld	(3567:16), 10
	call	Display_UpdateRegion0
ParamPopup_PartPanpot_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda	xiy, (xiy+hl)
	ld xix, 3793
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_PanpotEq
	inc	1, xix
	ld	bc, 7:i3
	ldir85
	ld	a, (4339:16)
	xor	w, w
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ld	xiy, 4481
	inc	1, xix
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "PANPOT=", 7 chars copied by ParamPopup_PartPanpot (0xEFF963).
	; reader ParamPopup_PartPanpot: `ld xiy, Str_PanpotEq` then `ld bc, 7` + ldir (7 bytes copied)
Str_PanpotEq:
	.ascii	"PANPOT="
	; ParamPopup_PartKeyShift -- LCD parameter pop-up.
	; Pop-up id 10.  "<part> KEY SHIFT=snn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_KeyShiftEq,
	; value (0x10f3) formatted by ParamDigit_CalrData with DE = 64, then the
	; byte at 0x1180 and three digits from 0x1181.
ParamPopup_PartKeyShift:
	cp	(0x0def:16), 10
	jrl	z, ParamPopup_PartKeyShift_Skip
	ld	(3567:16), 10
	call	Display_UpdateRegion0
ParamPopup_PartKeyShift_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda	xiy, (xiy+hl)
	ld xix, 3791
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_KeyShiftEq
	inc	1, xix
	ldw	bc, 10
	ldir85
	ld	a, (4339:16)
	xor	w, w
	ldw	de, 64
	push	xix
	call	ParamDigit_CalrData
	pop	xix
	inc	1, xix
	ld	a, (4480:16)
	ld (xix+), a
	ld xiy, 4481
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "KEY SHIFT=", 10 chars copied by ParamPopup_PartKeyShift (0xEFF9C2).
	; reader ParamPopup_PartKeyShift: `ld xiy, Str_KeyShiftEq` then `ld bc, 10` + ldir (10 bytes copied)
Str_KeyShiftEq:
	.ascii	"KEY SHIFT="
	; ParamPopup_PartTuning -- LCD parameter pop-up.
	; Pop-up id 10.  "<part> TUNING=snn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_TuningEq,
	; value (0x10f3) formatted by ParamDigit_CalrData with DE = 128, then the
	; byte at 0x1180 and three digits from 0x1181.
ParamPopup_PartTuning:
	cp	(0x0def:16), 10
	jrl	z, ParamPopup_PartTuning_Skip
	ld	(3567:16), 10
	call	Display_UpdateRegion0
ParamPopup_PartTuning_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda	xiy, (xiy+hl)
	ld xix, 3791
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_TuningEq
	inc	1, xix
	ld	bc, 7:i3
	ldir85
	ld	a, (4339:16)
	xor	w, w
	ldw	de, 128
	push	xix
	call	ParamDigit_CalrData
	pop	xix
	inc	1, xix
	ld	a, (4480:16)
	ld (xix+), a
	ld xiy, 4481
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "TUNING=", 7 chars copied by ParamPopup_PartTuning (0xEFFA2F).  The 64
	; bytes after it (US1 US2 US3 BAS P 8 ..) are 4-char part names of a
	; second naming scheme with no reader found by name or 32-bit value.
Str_TuningEq:
	.ascii "TUNING=US1 US2 US3 BAS P 8 P 9 P10 LS1 LS2 LS3 P11 P12 P13 P14 P15 KBP "
	; ParamPopup_PartBendSense -- LCD parameter pop-up.
	; Pop-up id 10.  "<part> BEND SENS=nn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_BendSensEq,
	; value (0x10f3), two digits (copied from 0x1182).
ParamPopup_PartBendSense:
	cp	(0x0def:16), 10
	jrl	z, ParamPopup_PartBendSense_Skip
	ld	(3567:16), 10
	call	Display_UpdateRegion0
ParamPopup_PartBendSense_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda	xiy, (xiy+hl)
	ld	xix, 0x0ecf
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_BendSensEq
	inc	1, xix
	ldw	bc, 10
	ldir85
	ld	a, (4339:16)
	xor	w, w
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	inc	1, xix
	ld	xiy, 4482
	ld	bc, 2:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "BEND SENS=", 10 chars copied by ParamPopup_PartBendSense (0xEFFAD8).
	; reader ParamPopup_PartBendSense: `ld xiy, Str_BendSensEq` then `ld bc, 10` + ldir (10 bytes copied)
Str_BendSensEq:
	.ascii "BEND SENS="
	; ParamPopup_PartSustain -- LCD parameter pop-up.
	; Pop-up id 1.  "<part> SUSTAIN ON /OFF ": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_Sustain,
	; then Str_OnOffPair + 0 when bit 3 of (0x10f3) is set, + 4 when clear.
ParamPopup_PartSustain:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_PartSustain_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartSustain_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda	xiy, (xiy+hl)
	ld xix, 3791
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_Sustain
	inc	1, xix
	ldw	bc, 8
	ldir85
	xor	hl, hl
	bit	3, (0x10f3:16)
	jrl	nz, ParamPopup_PartSustain_Skip2
	ld	l, 4:opc
ParamPopup_PartSustain_Skip2:
	ld	xiy, Str_OnOffPair
	lda	xiy, (xiy+hl)
	ld	bc, 4:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "SUSTAIN ", 8 chars copied by ParamPopup_PartSustain (0xEFFB3B).
	; reader ParamPopup_PartSustain: `ld xiy, Str_Sustain` then `ld bc, 8` + ldir (8 bytes copied)
Str_Sustain:
	.ascii	"SUSTAIN "
	; 2 x 4 chars "ON  " / "OFF ": +0 or +4 selected by a flag bit and 3 or 4
	; bytes copied, by ParamPopup_PartSustain/Effect/Tremolo/TotalReverb,
	; ParamPopup_PartDspEffectOff and Display_BytecodeBlock_F (0xEFF11A).
Str_OnOffPair:
	.ascii	"ON  OFF "
	; ParamPopup_PartDspEffectOff -- LCD parameter pop-up.
	; Pop-up id 1.  "<part> DSP EFFECT OFF ": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_DspEffect,
	; then Str_OnOffPair + 4 unconditionally (`ld l, 4`).
ParamPopup_PartDspEffectOff:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_PartDspEffectOff_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartDspEffectOff_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda	xiy, (xiy+hl)
	ld xix, 3791
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_DspEffect
	inc	1, xix
	ldw	bc, 11
	ldir85
	xor	hl, hl
	ld	l, 4:opc
	ld	xiy, Str_OnOffPair
	lda	xiy, (xiy+hl)
	ld	bc, 4:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "DSP EFFECT ", 11 chars copied by ParamPopup_PartDspEffectOff (0xEFFBA6).
	; reader ParamPopup_PartDspEffectOff: `ld xiy, Str_DspEffect` then `ld bc, 11` + ldir (11 bytes copied)
Str_DspEffect:
	.ascii	"DSP EFFECT "
	; ParamPopup_PartEffect -- LCD parameter pop-up.
	; Pop-up id 1.  "<part> EFFECT ON /OFF ": part name = StringData_PartNames[(0x10f1)*4], 4 chars, StringData_EffectLabel,
	; then Str_OnOffPair + 0 when bit 6 of (0x10f3) is set, + 4 when clear.
ParamPopup_PartEffect:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_PartEffect_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartEffect_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda	xiy, (xiy+hl)
	ld xix, 3791
	ld	bc, 4:i3
	ldir85
	ld	xiy, StringData_EffectLabel
	inc	1, xix
	ld	bc, 7:i3
	ldir85
	xor	hl, hl
	bit	6, (0x10f3:16)
	jrl	nz, ParamPopup_PartEffect_Skip2
	ld	l, 4:opc
ParamPopup_PartEffect_Skip2:
	ld	xiy, Str_OnOffPair
	lda	xiy, (xiy+hl)
	ld	bc, 4:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; StringData_EffectLabel: "EFFECT ", 7 chars copied by
	; ParamPopup_PartEffect (0xEFFC05).
StringData_EffectLabel:	.ascii "EFFECT "
	; ParamPopup_PartDspEffectLevel -- LCD parameter pop-up.
	; Pop-up id 1.  "<part> DSP EFFECT=nnn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_DspEffectEq,
	; value (0x10f3) in decimal.
ParamPopup_PartDspEffectLevel:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_PartDspEffectLevel_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartDspEffectLevel_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda	xiy, (xiy+hl)
	ld xix, 3791
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_DspEffectEq
	inc	1, xix
	ldw	bc, 11
	ldir85
	xor	w, w
	ld	a, (4339:16)
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "DSP EFFECT=", 11 chars copied by ParamPopup_PartDspEffectLevel (0xEFFC66).
	; reader ParamPopup_PartDspEffectLevel: `ld xiy, Str_DspEffectEq` then `ld bc, 11` + ldir (11 bytes copied)
Str_DspEffectEq:
	.ascii	"DSP EFFECT="
	; ParamPopup_PartReverb -- LCD parameter pop-up.
	; Pop-up id 1.  "<part> REVERB=nnn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_ReverbEq,
	; value (0x10f3) in decimal.
ParamPopup_PartReverb:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_PartReverb_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartReverb_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda	xiy, (xiy+hl)
	ld xix, 3791
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_ReverbEq
	inc	1, xix
	ld	bc, 7:i3
	ldir85
	xor	w, w
	ld	a, (4339:16)
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "REVERB=", 7 chars copied by ParamPopup_PartReverb (0xEFFCC6).
	; reader ParamPopup_PartReverb: `ld xiy, Str_ReverbEq` then `ld bc, 7` + ldir (7 bytes copied)
Str_ReverbEq:
	.ascii	"REVERB="
	; ParamPopup_PanelMemory -- LCD parameter pop-up.
	; Pop-up id 1.  "PANEL MEMORY=b-n" from A on entry: A-1 divided by 8
	; gives bank = quotient+1 -> (0x11f2) and number = remainder+1 -> (0x11f3),
	; each printed in decimal with '-' (45) between them.
ParamPopup_PanelMemory:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_PanelMemory_Skip
	ld	(3567:16), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
ParamPopup_PanelMemory_Skip:
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	xiy, Str_PanelMemoryEq
	ld	xix, 3791
	ldw	bc, 13
	ldir85
	xor	w, w
	dec	1, a
	div	a, 8
	inc	1, a
	inc	1, w
	ld	(4594:16), a
	ld	(4595:16), w
	xor	wa, wa
	ld	a, (4594:16)
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ld	wa, (4482:16)
	ld	(xix), wa
	ld	(xix+2), 45
	xor	wa, wa
	ld	a, (4595:16)
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ld	a, (4483:16)
	ld	(xix+3), a
	call	Display_UpdateRegion3
	ret
	; "PANEL MEMORY=", 13 chars copied by ParamPopup_PanelMemory (0xEFFD21).
	; reader ParamPopup_PanelMemory: `ld xiy, Str_PanelMemoryEq` then `ld bc, 13` + ldir (13 bytes copied)
Str_PanelMemoryEq:
	.ascii "PANEL MEMORY="
	; ParamPopup_FadeIn -- LCD parameter pop-up.
	; Pop-up id 1.  Str_FadeIn then Str_On or Str_Off (3 chars) chosen from
	; A on entry (0 / 1).
ParamPopup_FadeIn:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_FadeIn_Skip2
	ld	(3567:16), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
ParamPopup_FadeIn_Skip2:
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	xiy, Str_FadeIn
	ld	xix, 3791
	ldw	bc, 8
	ldir85
	cp	a, 0:i3
	jr	z, ParamPopup_FadeIn_Skip
	cp	a, 1:i3
	jr	z, ParamPopup_FadeIn_Next
ParamPopup_FadeIn_Next:
	ld	xiy, Str_On
	jp	ParamPopup_FadeIn_Join
ParamPopup_FadeIn_Skip:
	ld	xiy, Str_Off
ParamPopup_FadeIn_Join:
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "FADE-IN ", 8 chars copied by ParamPopup_FadeIn (0xEFFD97).
	; reader ParamPopup_FadeIn: `ld xiy, Str_FadeIn` then `ld bc, 8` + ldir (8 bytes copied)
Str_FadeIn:
	.ascii	"FADE-IN "
	; "ON ", 3 chars copied by ParamPopup_FadeIn and ParamPopup_FadeOut.
	; reader ParamPopup_FadeIn: `ld xiy, Str_On` then `ld bc, 3` + ldir (3 bytes copied)
Str_On:
	.ascii	"ON "
	; "OFF", 3 chars copied by ParamPopup_FadeIn and ParamPopup_FadeOut.
	; reader ParamPopup_FadeIn: `ld xiy, Str_Off` then `ld bc, 3` + ldir (3 bytes copied)
Str_Off:
	.ascii	"OFF"
	; ParamPopup_FadeOut -- LCD parameter pop-up.
	; Pop-up id 1.  Str_FadeOut then Str_On or Str_Off (3 chars) chosen from
	; A on entry (0 / 1).
ParamPopup_FadeOut:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_FadeOut_Skip
	ld	(3567:16), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
ParamPopup_FadeOut_Skip:
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	xiy, Str_FadeOut
	ld	xix, 3791
	ldw	bc, 9
	ldir85
	cp	a, 0:i3
	jr	z, ParamPopup_FadeOut_Skip2
	cp	a, 1:i3
	jr	z, ParamPopup_FadeOut_Next
ParamPopup_FadeOut_Next:
	ld	xiy, Str_On
	jp	ParamPopup_FadeOut_Join
ParamPopup_FadeOut_Skip2:
	ld	xiy, Str_Off
ParamPopup_FadeOut_Join:
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "FADE-OUT ", 9 chars copied by ParamPopup_FadeOut (0xEFFDEC).
	; reader ParamPopup_FadeOut: `ld xiy, Str_FadeOut` then `ld bc, 9` + ldir (9 bytes copied)
Str_FadeOut:
	.ascii "FADE-OUT "
	; ParamPopup_ApcMode -- LCD parameter pop-up.
	; Pop-up id 1.  16 chars of StringData_APCModeNames[(W and A) * 16] at 0x0ECF.
ParamPopup_ApcMode:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_ApcMode_Skip
	ld	(3567:16), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
ParamPopup_ApcMode_Skip:
	and	w, a
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	l, w
	xor	h, h
	sla	hl, 4
	ld	xiy, StringData_APCModeNames
	lda	xiy, (xiy+hl)
	ld	xix, 0x0ecf
	ldw	bc, 16
	ldir85
	call	Display_UpdateRegion3
	ret
	; StringData_APCModeNames: APC mode names, 9 x 16 chars (APC OFF,
	; BASIC, ADVANCED 1, PIANIST, PIANO MODE, ADVANCED 2, -, -, SPLIT), read
	; by ParamPopup_ApcMode (0xEFFE3C): `sla hl, 4 / lda_rr / ld bc, 16 / ldir`.
StringData_APCModeNames:
	.ascii	"APC OFF         BASIC           ADVANCED 1      PIANIST         PIANO MODE      ADVANCED 2                                      SPLIT           "
	; ParamPopup_ApcMemory -- LCD parameter pop-up.
	; Pop-up id 1.  Str_ApcMemoryOn (14 chars at 0x0ECF); Str_OffAccomp
	; ("OFF") over the "ON " at 0x0EDA when (A and W) = 0.
ParamPopup_ApcMemory:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_ApcMemory_Skip
	ld	(0x0def:16), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
ParamPopup_ApcMemory_Skip:
	and	w, a
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	l, w
	xor	h, h
	sla	hl, 4
	ld	xiy, Str_ApcMemoryOn
	ld	xix, 0x0ecf
	ldw	bc, 14
	ldir85
	and	a, w
	jrl	nz, ParamPopup_ApcMemory_Skip2
	ld	xiy, Str_OffAccomp
	ld	xix, 0x0eda
	ld	bc, 3:i3
	ldir85
ParamPopup_ApcMemory_Skip2:
	call	Display_UpdateRegion3
	ret
	; "APC MEMORY ON ", 14 chars copied by ParamPopup_ApcMemory (0xEFFF07).
	; reader ParamPopup_ApcMemory: `ld xiy, Str_ApcMemoryOn` then `ld bc, 14` + ldir (14 bytes copied)
Str_ApcMemoryOn:
	.ascii	"APC MEMORY ON "
	; ParamPopup_AccompPart -- LCD parameter pop-up.
	; Pop-up id 1.  A and W are reduced to their bits 7-5 (`and 224 / srl 5`);
	; 16 bytes of Tbl_AccompPartNames + A*16 go to 0x0ECF, and "OFF" to
	; 0x0EDC when (A and W) = 0.
ParamPopup_AccompPart:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_AccompPart_Skip
	ld	(0x0def:16), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
ParamPopup_AccompPart_Skip:
	and	w, 224
	and	a, 224
	srl	w, 5
	srl	a, 5
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	l, a
	xor	h, h
	sla	hl, 4
	ld	xiy, Tbl_AccompPartNames
	lda	xiy, (xiy+hl)
	ld	xix, 0x0ecf
	ldw	bc, 16
	ldir85
	inc	1, xix
	and	a, w
	jrl	nz, ParamPopup_AccompPart_Skip2
	ld	xiy, Str_OffAccomp
	ld	xix, 0x0edc
	ld	bc, 3:i3
	ldir85
ParamPopup_AccompPart_Skip2:
	call	Display_UpdateRegion3
	ret
	; 52 bytes read by ParamPopup_AccompPart (0xEFFF5E): 16 bytes at +k*16,
	; k = bits 7-5 of A (`sla hl, 4 / lda_rr / ld bc, 16 / ldir` to 0x0ECF).
	; Content: 0x09 0x09 "ACCOMP PART1 ON ", "ACCOMP PART2 ON ", 0x09 0x09
	; "ACCOMP PART3 ON " -- the visible strings do NOT fall on the reader's
	; 16-byte boundaries, and the role of the 0x09 bytes is not established.
	; The values 0xEFFFD7-0xEFFFDA (inside this text) are also loaded as
	; StringData_APCModeNames_0x160..0x163 by ui/drawbar_panel_ui.s's Softver
	; screen and handed to SendEvent -- more likely numeric event arguments
	; than pointers here (not verified).
Tbl_AccompPartNames:
	.byte	0x09, 0x09
	.ascii	"ACCOMP PART1 ON ACCOMP PART2 ON "
Softver_ShowHide_Data_4:
	.byte	0x09, 0x09
	.ascii	"ACCOMP PART3 ON "
	; "OFF", 3 chars copied over the "ON " of the ACCOMP/APC MEMORY/DYNAMIC
	; ACCOMP/TECHNI-CHORD pop-ups when their flag is clear.
Str_OffAccomp:
	.ascii	"OFF"
	; ParamPopup_DynamicAccomp -- LCD parameter pop-up.
	; Pop-up id 1.  Str_DynamicAccompOn (17 chars); "OFF" at 0x0EDE when
	; (W and A) = 0.
ParamPopup_DynamicAccomp:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_DynamicAccomp_Skip
	ld	(0x0def:16), 1
	pushw	wa
	call	Display_UpdateRegion0
Softver_ShowHide_Code:
	popw	wa
ParamPopup_DynamicAccomp_Skip:
	pushw	wa
Softver_ShowHide_Code_2:
	call	DisplayStr_ClearRegion
	popw	wa
	ld	xiy, Str_DynamicAccompOn
	ld	xix, 0x0ecf
	ldw	bc, 17
	ldir85
	and	w, a
	jrl	nz, ParamPopup_DynamicAccomp_Skip2
	ld	xiy, Str_OffAccomp
	ld	xix, 0x0ede
	ld	bc, 3:i3
	ldir85
ParamPopup_DynamicAccomp_Skip2:
	call	Display_UpdateRegion3
	ret
	; "DYNAMIC ACCOMP ON ", 17 chars copied by ParamPopup_DynamicAccomp (0xEFFFEF).
	; reader ParamPopup_DynamicAccomp: `ld xiy, Str_DynamicAccompOn` then `ld bc, 17` + ldir (17 bytes copied)
Str_DynamicAccompOn:
	.ascii	"DYNAMIC ACCOMP ON "
	; ParamPopup_TechniChord -- LCD parameter pop-up.
	; Pop-up id 1.  Str_TechniChordOn (16 chars); "OFF" at 0x0EDC when
	; (W and A) = 0.
ParamPopup_TechniChord:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_TechniChord_Skip
	ld	(0x0def:16), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
ParamPopup_TechniChord_Skip:
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	xiy, Str_TechniChordOn
	ld	xix, 0x0ecf
	ldw	bc, 16
	ldir85
	and	w, a
	jrl	nz, ParamPopup_TechniChord_Skip2
	ld	xiy, Str_OffAccomp
	ld	xix, 0x0edc
	ld	bc, 3:i3
	ldir85
ParamPopup_TechniChord_Skip2:
	call	Display_UpdateRegion3
	ret
	; "TECHNI-CHORD ON ", 16 chars copied by ParamPopup_TechniChord (0xF00041).
	; reader ParamPopup_TechniChord: `ld xiy, Str_TechniChordOn` then `ld bc, 16` + ldir (16 bytes copied)
Str_TechniChordOn:
	.ascii	"TECHNI-CHORD ON "
	ret
	; ParamPopup_KeyNameBracketed -- LCD parameter pop-up.
	; Pop-up id 1.  ' ' at 0x0ECE, then 4 chars of Tbl_KeyNamesBracketed
	; [((0x10f3) & 15) * 4] ("<G >", "<Ab>" ...), read as two words.
ParamPopup_KeyNameBracketed:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_KeyNameBracketed_Skip
	ld	(0x0def:16), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
ParamPopup_KeyNameBracketed_Skip:
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	(0x0ece:16), 32
	ld	xix, 0x0ecf
	ldb_d8	l, (0x10f3)
	and	l, 15
	xor	h, h
	sla	hl, 2
	ld	xiy, Tbl_KeyNamesBracketed
ParamPopup_KeyNameBracketed_Code:
	ld	wa, (xiy+hl)
	ld	(xix), wa
	add	hl, 2
	add	xix, 2
	ld	wa, (xiy+hl)
	ld	(xix), wa
	call	Display_UpdateRegion3
	ret
	; 16 x 4 chars "<G >" "<Ab>" .. "<F#>" then 4 blank entries, read by
	; ParamPopup_KeyNameBracketed (0xF00092): `ld l, (0x10f3) / and l, 15 /
	; sla hl, 2 / ld_rrw wa, xiy, hl` twice.
Tbl_KeyNamesBracketed:
	.ascii	"<G ><Ab><A ><Bb><B ><C ><Db><D ><Eb><E ><F ><F#>                "
	; ParamPopup_AccompVolume -- LCD parameter pop-up.
	; Pop-up id 1.  16 chars of Tbl_AccompVolumeLabels[HL * 16] (HL on entry
	; selects ACC. TOTAL / BASS / DRUMS / ACCMP1..3); then, when bit 7 of
	; (0x10f5) is set, 8 chars of Tbl_MuteOnOff (+0 "MUTE ON ", +8 when bit 7
	; of (0x10f3) is clear), else A (on entry) in decimal at 0x0EDF.
ParamPopup_AccompVolume:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_AccompVolume_Skip
	ld	(0x0def:16), 1
	pushw	wa
	pushw	hl
	call	Display_UpdateRegion0
	popw	hl
	popw	wa
ParamPopup_AccompVolume_Skip:
	pushw	wa
	pushw	hl
	call	DisplayStr_ClearRegion
	popw	hl
	popw	wa
	pushw	wa
	ld	bc, hl
	sla	hl, 4
	ld	xiy, Tbl_AccompVolumeLabels
	lda	xiy, (xiy+hl)
	ld	xix, 0x0ecf
	ldw	bc, 16
	ldir85
	popw	wa
	bit	7, (0x10f5:16)
	jrl	z, ParamPopup_AccompVolume_Skip3
	ld	xiy, Tbl_MuteOnOff
	bit	7, (0x10f3:16)
	jrl	nz, ParamPopup_AccompVolume_Skip2
	add	xiy, 8
ParamPopup_AccompVolume_Skip2:
	ld	xix, 0x0ede
	ldw	bc, 8
	ldir85
	jp	ParamPopup_AccompVolume_Join
ParamPopup_AccompVolume_Skip3:
	xor	w, w
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 0x1181
	ld	xix, 0x0edf
	ld	bc, 3:i3
	ldir85
ParamPopup_AccompVolume_Join:
	call	Display_UpdateRegion3
	ret
	; 6 x 16 chars (ACC. TOTAL VOL.= / BASS / DRUMS / ACCMP1 / ACCMP2 / ACCMP3
	; VOLUME =), read by ParamPopup_AccompVolume (0xF00123): `sla hl, 4 /
	; lda_rr / ld bc, 16 / ldir`.
Tbl_AccompVolumeLabels:
	.ascii	"ACC. TOTAL VOL.=   BASS VOLUME =  DRUMS VOLUME = ACCMP1 VOLUME = ACCMP2 VOLUME = ACCMP3 VOLUME ="
	; 2 x 8 chars "MUTE ON " / "MUTE OFF", read by ParamPopup_AccompVolume
	; (0xF00123): +8 when bit 7 of (0x10f3) is clear, 8 bytes copied.
Tbl_MuteOnOff:
	.ascii	"MUTE ON MUTE OFF"
VoiceSlot_StatusRet_Helper5:
	ret
	; ParamPopup_PartTremolo -- LCD parameter pop-up.
	; Pop-up id 1.  "<part> TREMOLO ON/OFF": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_Tremolo,
	; then 3 chars of Str_OnOffPair + 0 (bit 7 of (0x10f3) set) or + 4.
ParamPopup_PartTremolo:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_PartTremolo_Skip
	ld	(0x0def:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartTremolo_Skip:
	call	DisplayStr_ClearRegion
	ldb_d8	l, (0x10f1)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda	xiy, (xiy+hl)
	ld	xix, 0x0ecf
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_Tremolo
	inc	1, xix
	ldw	bc, 8
	ldir85
	xor	hl, hl
	bit	7, (0x10f3:16)
	jrl	nz, ParamPopup_PartTremolo_Skip2
	ld	l, 4:opc
ParamPopup_PartTremolo_Skip2:
	ld	xiy, Str_OnOffPair
	lda	xiy, (xiy+hl)
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "TREMOLO ", 8 chars copied by ParamPopup_PartTremolo (0xF0020C).
	; reader ParamPopup_PartTremolo: `ld xiy, Str_Tremolo` then `ld bc, 8` + ldir (8 bytes copied)
Str_Tremolo:
	.ascii	"TREMOLO "
VoiceSlot_StatusRet_Helper6:
	ret
VoiceSlot_StatusRet_Helper7:
	ret
VoiceSlot_StatusRet_Helper8:
	ret
	ret
	; "EXT.TAB EFFECT:" + "EN  " + "DIS " (23 bytes).  No reader found: no
	; name at this address and no 24/32-bit value 0xF00273 anywhere in the
	; ROM; the text sits where the three `ret` stubs 0xF0026F-0xF00272 end.
Str_ExtTabEffectEnDis:
	.ascii	"EXT.TAB EFFECT:EN  DIS "
VoiceSlot_StatusRet_Helper9:
	ret
	; ParamPopup_TotalReverb -- LCD parameter pop-up.
	; Pop-up id 1.  Str_TotalReverb (13 chars at 0x0ED1), then 4 chars of
	; Str_OnOffPair + 0 (bit 7 of (0x10f3) set) or + 4.
ParamPopup_TotalReverb:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_TotalReverb_Skip
	ld	(0x0def:16), 1
	call	Display_UpdateRegion0
ParamPopup_TotalReverb_Skip:
	call	DisplayStr_ClearRegion
	ld	xix, 0x0ed1
	ld	xiy, Str_TotalReverb
	ldw	bc, 13
	ldir85
	xor	hl, hl
	bit	7, (0x10f3:16)
	jrl	nz, ParamPopup_TotalReverb_Skip2
	ld	l, 4:opc
ParamPopup_TotalReverb_Skip2:
	ld	xiy, Str_OnOffPair
	lda	xiy, (xiy+hl)
	ld	bc, 4:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "TOTAL REVERB ", 13 chars copied by ParamPopup_TotalReverb (0xF0028B).
	; reader ParamPopup_TotalReverb: `ld xiy, Str_TotalReverb` then `ld bc, 13` + ldir (13 bytes copied)
Str_TotalReverb:
	.ascii	"TOTAL REVERB "
VoiceSlot_StatusRet_Helper10:
	ret
	; ParamPopup_PartTimbre -- LCD parameter pop-up.
	; Pop-up id 1.  part name = StringData_PartNames[(0x10f1)*4], 4 chars at 0x0ED1, then 6 chars of
	; Tbl_TimbreNames[((0x10f3) >> 6) * 6] (NORMAL/BRIGHT/MELLOW/WARM).
ParamPopup_PartTimbre:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_PartTimbre_Skip
	ld	(0x0def:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartTimbre_Skip:
	call	DisplayStr_ClearRegion
	ldb_d8	l, (0x10f1)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda	xiy, (xiy+hl)
	ld	xix, 0x0ed1
	ld	bc, 4:i3
	ldir85
	inc	1, xix
	ldb_d8	l, (0x10f3)
	and	l, 192
	srl	l, 6
	ld	h, l
	sla	h, 1
	sla	l, 2
	add	l, h
	xor	h, h
	ld	xiy, Tbl_TimbreNames
	lda	xiy, (xiy+hl)
	ld	bc, 6:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; 4 x 6 chars NORMAL / BRIGHT / MELLOW / WARM, read by ParamPopup_PartTimbre
	; (0xF002DB): index ((0x10f3) >> 6) times 6 (`sla h,1 / sla l,2 / add l,h`).
Tbl_TimbreNames:
	.ascii	"NORMALBRIGHTMELLOWWARM  "
	; ParamPopup_Msa -- LCD parameter pop-up.
	; Pop-up id 15 when (0x0d65) = 3, else 1.  Str_Msa (7 chars at 0x0ED1),
	; then 4 chars of Tbl_MsaStates[((0x10f3) & 7) * 4] (OFF/ON/#2/#3).
ParamPopup_Msa:
	cp	(0x0d65:16), 3
	jrl	nz, ParamPopup_Msa_Skip
	cp	(0x0def:16), 15
	jrl	z, ParamPopup_Msa_Join
	ld	(0x0def:16), 15
	call	Display_UpdateRegion0
	jp	ParamPopup_Msa_Join
ParamPopup_Msa_Skip:
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_Msa_Join
	ld	(0x0def:16), 1
	call	Display_UpdateRegion0
ParamPopup_Msa_Join:
	call	DisplayStr_ClearRegion
	ld	xiy, Str_Msa
	ld	xix, 0x0ed1
	ld	bc, 7:i3
	ldir85
	ldb_d8	l, (0x10f3)
	xor	h, h
	and	l, 7
	sla	hl, 2
	ld	xiy, Tbl_MsaStates
	lda	xiy, (xiy+hl)
	ld	bc, 4:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "M.S.A. ", 7 chars copied by ParamPopup_Msa (0xF0034F).
	; reader ParamPopup_Msa: `ld xiy, Str_Msa` then `ld bc, 7` + ldir (7 bytes copied)
Str_Msa:
	.ascii	"M.S.A. "
	; 4 x 4 chars OFF / ON / #2 / #3, read by ParamPopup_Msa (0xF0034F):
	; `ld l, (0x10f3) / and l, 7 / sla hl, 2`, 4 bytes copied.
Tbl_MsaStates:
	.ascii	"OFF ON  #2  #3  "
Str_Rhythm_Helper2:
	push	xiz
	ld	xiz, (0x10fd:16)
	ldfr_lerp	xiz, 56
	pop	xiz
	push_lerp	56
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	a, 5:opc
	call	VoiceSlot_SaveState
	call	Timer_ParamCompareAlt_Helper5
	call	MemConfig_VoiceSlotLookup
	ld	(0x10f6:16), 0
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, ParamPopup_Msa_Skip3
Tbl_MsaStates_Loop:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, ParamPopup_Msa_Skip4
	call	VoiceSlot_ComputeWordIndex
	push	xhl
	ld	xhl, 0x0c9e
	ld	ix, (xhl+iz)
	sra	iz, 1
	ld	xhl, 0x0cbe
	ld	a, (xhl+iz)
	pop	xhl
	push	xhl
	ld	xhl, 0x0dff
	add	xhl, 40
	cp	ix, (xhl)
	pop	xhl
	jrl	nz, ParamPopup_Msa_Skip2
	push	xhl
	ld	xhl, 0x0dff
	add xhl,(0x2a:8)	; add XHL,(0x2a)
	cp	a, (xhl)
	pop	xhl
	jrl	nc, ParamPopup_Msa_Skip4
ParamPopup_Msa_Skip2:
	call	VoiceSlot_ReadCurrentParams
ParamPopup_Msa_Skip3:
	and	a, 240
	cp	a, 176
	jrl	nz, Tbl_MsaStates_Loop
	call	Tbl_MsaStates_Helper
	jp	Tbl_MsaStates_Loop
ParamPopup_Msa_Skip4:
	ld	a, 5:opc
	call	VoiceSlot_RestoreState
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	pop_lerp	56
	push	xiz
	ldto_lerp	xiz, 56
	ld	(0x10fd:16), xiz
	pop	xiz
	ret
Tbl_MsaStates_Helper:
	call	VoiceSlot_ComputeWordIndex
	push	xhl
	ld	xhl, 0x0c9e
	ld	ix, (xhl+iz)
	ld	(0x28bf:16), ix
	sra	iz, 1
	ld	xhl, 0x0cbe
	ld	a, (xhl+iz)
	pop	xhl
	xor	w, w
	ld	(0x28c1:16), wa
	call	VoiceBank_ProcessCommand
	ldb_d8	a, (0x0eb5)
	and	a, 240
	cp	a, 176
	jrl	z, ParamPopup_Msa_Skip5
ParamPopup_Msa_Loop:
	jp	ParamPopup_PartPedal
ParamPopup_Msa_Skip5:
	ldb_d8	a, (0x0eb5)
	and	a, 4
	rrc a, 3	; rrc 0x03,A
	ldb_d8	w, (0x0eb7)
	and	w, 127
	or	a, w
	cp	a, 152
	jrl	nz, ParamPopup_Msa_Loop
	cp	(0x0eb8:16), 3
	jrl	nz, ParamPopup_Msa_Loop
	bit	0, (0x0eba:16)
	jrl	z, ParamPopup_Msa_Loop
	ldb_d8	a, (0x0eb9)
	and	a, 1
	stb_d8	(0x10f6), a
	; ParamPopup_PartPedal -- LCD parameter pop-up.
	; Pop-up id 1.  Part name of (0x10f2) at 0x0ED1, then 10 chars of
	; Tbl_PedalNames[((0x10f1) - 181) * 10] (SUSTAIN/SOFT PEDAL/SOSTENUTE);
	; the value (0x10f3) in decimal when (0x10f1) = 181.
ParamPopup_PartPedal:
	ret
	cp	(0x0def:16), 1
	jrl	z, ParamPopup_PartPedal_Skip2
	ld	(0x0def:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartPedal_Skip2:
	call	DisplayStr_ClearRegion
	ldb_d8	l, (0x10f2)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda	xiy, (xiy+hl)
	ld	xix, 0x0ed1
	ld	bc, 4:i3
	ldir85
	xor	hl, hl
	ldb_d8	l, (0x10f1)
	sub	l, 181
	mul	l, 10
	ld	xiy, Tbl_PedalNames
	lda	xiy, (xiy+hl)
	ldw	bc, 10
	ldir85
	inc	1, xix
	cp	(0x10f1:16), 181
	jrl	nz, ParamPopup_PartPedal_Skip3
	xor	wa, wa
	ldb_d8	a, (0x10f3)
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ld	xiy, 0x1181
	ld	bc, 3:i3
	ldir85
	jp	ParamPopup_PartPedal_Join2
ParamPopup_PartPedal_Skip3:
	ldb_d8	c, (0x10f3)
	xor	hl, hl
	cp	c, 64
	jrl	nc, ParamPopup_PartPedal_Skip4
	ld	hl, 4:i3
ParamPopup_PartPedal_Skip4:
	ld	xiy, Str_OnOffPair
	lda	xiy, (xiy+hl)
	ld	bc, 4:i3
	ldir85
ParamPopup_PartPedal_Join2:
	call	Display_UpdateRegion3
	ret
	; 3 x 10 chars " SUSTAIN  " / "SOFT PEDAL" / "SOSTENUTE ", read by
	; ParamPopup_PartPedal (0xF004DB): index ((0x10f1) - 181) times 10.
Tbl_PedalNames:
	.ascii	" SUSTAIN  SOFT PEDALSOSTENUTE "
SubCPU_ToneParamRet_Helper19:
	call	Tbl_PedalNames_Helper3
	cp	l, 0:i3
	jrl	z, ParamPopup_PartPedal_Skip
	ldb_d8	a, (0x0eb5)
	cp	a, 129
	jrl	z, ParamPopup_PartPedal_Skip5
	call	SubCPU_ToneParamRet_Helper17
	ld	(0x0f70:16), 48
	ldw	(0x0ec2:16), 0
	jp	Tbl_PedalNames_Return
ParamPopup_PartPedal_Skip5:
	call	DisplayStr_BytecodeBlock_A
	xor	wa, wa
	stb_d8	(0x0f70), a
	ld	(0x0ec2:16), wa
	jp	Tbl_PedalNames_Join3
ParamPopup_PartPedal_Skip:
	ldb_d8	a, (0x116f)
	stb_d8	(0x0f70), a
	ldb_d8	a, (0x116e)
	and	a, 240
	cp	a, 144
	jrl	z, ParamPopup_PartPedal_Skip7
	cp	(0x0eb5:16), 129
	jrl	z, ParamPopup_PartPedal_Skip6
	call	SubCPU_ToneParamRet_Helper17
	ldw	(0x0ec2:16), 0
	ld	(0x0f70:16), 48
	jp	Tbl_PedalNames_Return
ParamPopup_PartPedal_Skip6:
	call	DisplayStr_BytecodeBlock_A
	xor	wa, wa
	ld	(0x0ec2:16), wa
	stb_d8	(0x0f70), a
	jp	Tbl_PedalNames_Join3
ParamPopup_PartPedal_Skip7:
	call	Tbl_PedalNames_Helper2
	ldb_d8	a, (0x116f)
	exts	wa
	add	(0x0ec2:16), wa
	xor	h, h
	ld	l, 96:opc
	cp	(0x0eb5:16), 129
	jrl	z, ParamPopup_PartPedal_Skip8
	ld	l, 48:opc
ParamPopup_PartPedal_Skip8:
	ldw_d16	wa, (0x1174)
	ldw	bc, 96
	muls	xwa, bc
	ld	de, qwa
	add	hl, wa
	ld	(0x1176:16), hl
	ldw_d16	wa, (0x0ec2)
	cp	wa, hl
	jrl	ugt, ParamPopup_PartPedal_Skip10
	jrl	c, ParamPopup_PartPedal_Skip15
	cp	(0x0eb5:16), 129
	jrl	nz, ParamPopup_PartPedal_Skip9
	call	OscScope_UpdateDisplay_Helper
	ld	(0x0f70:16), 0
	ldw	(0x0ec2:16), 0
	jp	Tbl_PedalNames_Join3
ParamPopup_PartPedal_Skip9:
	call	DisplayStr_BytecodeBlock_A_Code_Helper
	ld	(0x0f70:16), 48
	ldw	(0x0ec2:16), 0
	jp	Tbl_PedalNames_Return
ParamPopup_PartPedal_Skip10:
	sub	wa, hl
	ld	(0x0ec2:16), wa
	cp	wa, 96
	jrl	c, ParamPopup_PartPedal_Skip11
	xor	de, de
	xor	b, b
	ld	c, 96:opc
	ld	qwa, de
	div	xwa, bc
	ld	de, qwa
	ld	bc, wa
	ldw	hl, 96
	muls	xwa, hl
	ld	de, qwa
	ldw_d16	de, (0x0ec2)
	sub	de, wa
	ld	(0x0ec2:16), de
	ldw	(0x0f70:16), 0
	pushw	bc
	call	OscScope_UpdateDisplay_Helper
	popw	bc
	pushw	bc
	call	VoiceBank_ProcessCommand
	popw	bc
	pushw	bc
	call	OscScope_UpdateDisplay_Helper
	popw	bc
	cp	(0x0ef6:16), 0
	jrl	nz, Tbl_PedalNames_Return
	djnz16	bc, -23
	cpw	(0x0ec2:16), 48
	jrl	nz, Tbl_PedalNames_Join3
	call	DisplayStr_BytecodeBlock_A_Code_Helper
	jp	Tbl_PedalNames_Join3
ParamPopup_PartPedal_Skip11:
	call	DisplayStr_BytecodeBlock_A_Code_Helper
	call	SubCPU_ToneParamRet_Helper18
	cp	(0x0ebb:16), 129
	jrl	nz, ParamPopup_PartPedal_Skip12
	call	OscScope_UpdateDisplay_Helper
	ld	(0x0f70:16), 48
	ldw	(0x0ec2:16), 0
	jp	Tbl_PedalNames_Join3
ParamPopup_PartPedal_Skip12:
	cp	(0x0ebb:16), 132
	jrl	nz, ParamPopup_PartPedal_Skip13
	call	Tbl_PedalNames_Helper
	jp	Tbl_PedalNames_Join3
ParamPopup_PartPedal_Skip13:
	cp	(0x0ebc:16), 0
	jrl	nz, ParamPopup_PartPedal_Skip14
	call	SubCPU_ToneParamRet_Helper17
	xor	wa, wa
	ld	(0x0f70:16), 0
	ld	(0x0ec2:16), wa
	jp	Tbl_PedalNames_Join3
ParamPopup_PartPedal_Skip14:
	call	OscScope_UpdateDisplay_Helper
	ld	(0x0f70:16), 48
	ldw	(0x0ec2:16), 0
	jp	Tbl_PedalNames_Join3
ParamPopup_PartPedal_Skip15:
	sub	hl, wa
	cp	hl, 96
	jrl	c, ParamPopup_PartPedal_Skip19
	cp	(0x0eb5:16), 129
	jrl	z, ParamPopup_PartPedal_Skip16
	call	SubCPU_ToneParamRet_Helper17
	ld	(0x0f70:16), 48
	ldw	(0x0ec2:16), 0
	jp	Tbl_PedalNames_Return
ParamPopup_PartPedal_Skip16:
	ld	wa, hl
	ld	l, 96:opc
	div	wa, l
	stb_d8	(0x0f70), w
	cp	(0x116e:16), 129
	jrl	z, ParamPopup_PartPedal_Skip17
	pushw	wa
	call	SubCPU_ToneParamRet_Helper18
	popw	wa
	cp	w, 48
	jrl	nz, ParamPopup_PartPedal_Skip17
	pushw	wa
	call	DisplayStr_BytecodeBlock_A_Code_Helper
	popw	wa
	cp	(0x0ebb:16), 129
	jrl	z, Tbl_PedalNames_Join
	cp	(0x0ebc:16), 48
	jrl	z, Tbl_PedalNames_Join
ParamPopup_PartPedal_Skip17:
	cp	w, 48
	jrl	z, ParamPopup_PartPedal_Skip18
	jp	Tbl_PedalNames_Join
	cp	a, 1:i3
	jrl	z, Tbl_PedalNames_Join
ParamPopup_PartPedal_Skip18:
	call	SubCPU_ToneParamRet_Helper17
	jp	Tbl_PedalNames_Join2
Tbl_PedalNames_Join:
	call	DisplayStr_BytecodeBlock_A
Tbl_PedalNames_Join2:
	ldw	(0x0ec2:16), 0
	jp	Tbl_PedalNames_Join3
ParamPopup_PartPedal_Skip19:
	cp	(0x0eb5:16), 129
	jrl	z, ParamPopup_PartPedal_Skip20
	call	SubCPU_ToneParamRet_Helper17
	ld	(0x0f70:16), 48
	ldw	(0x0ec2:16), 0
	jp	Tbl_PedalNames_Return
ParamPopup_PartPedal_Skip20:
	call	DisplayStr_BytecodeBlock_A_Code_Helper
	call	SubCPU_ToneParamRet_Helper18
	cp	(0x0ebb:16), 129
	jrl	nz, ParamPopup_PartPedal_Skip21
	call	DisplayStr_BytecodeBlock_A
	ld	(0x0f70:16), 48
	ldw	(0x0ec2:16), 0
	jp	Tbl_PedalNames_Join3
ParamPopup_PartPedal_Skip21:
	cp	(0x0ebb:16), 132
	jrl	nz, ParamPopup_PartPedal_Skip22
	call	Tbl_PedalNames_Helper
	jp	Tbl_PedalNames_Join3
ParamPopup_PartPedal_Skip22:
	cp	(0x0ebc:16), 0
	jrl	nz, ParamPopup_PartPedal_Skip23
	call	SubCPU_ToneParamRet_Helper17
	xor	wa, wa
	stb_d8	(0x0f70), a
	ld	(0x0ec2:16), wa
	jp	Tbl_PedalNames_Join3
ParamPopup_PartPedal_Skip23:
	call	DisplayStr_BytecodeBlock_A
	ld	(0x0f70:16), 48
	ldw	(0x0ec2:16), 0
Tbl_PedalNames_Join3:
	call	VoiceBank_ProcessCommand
Tbl_PedalNames_Return:
	ret
Tbl_PedalNames_Helper:
	call	SubCPU_ToneParamRet_Helper17
	xor	wa, wa
	stb_d8	(0x0f70), a
	ld	(0x0ec2:16), wa
	ret
Tbl_PedalNames_Helper2:
	ldb_d8	a, (0x1173)
	ld	w, 96:opc
	muls	wa, w
	ldb_d8	l, (0x1172)
	xor	h, h
	add	wa, hl
	ld	(0x0ec2:16), wa
	ret
Tbl_PedalNames_Helper3:
	push	xiy
	call	Tbl_PedalNames_Helper4
	xor	wa, wa
	ld	(0x1174:16), wa
	ldw_d16	wa, (0x28c1)
	ld	(0x1178:16), wa
	ldw_d16	wa, (0x28bf)
	ld	(0x117a:16), wa
ParamPopup_PartPedal_Loop:
	call	Tbl_PedalNames_Helper5
	call	Tbl_PedalNames_Helper6
	bit	7, a
	jrl	z, ParamPopup_PartPedal_Loop
Tbl_PedalNames_Loop:
	call	Tbl_PedalNames_Helper5
	cp	l, 0:i3
	jrl	nz, ParamPopup_PartPedal_Epilogue
	call	Tbl_PedalNames_Helper6
	bit	7, a
	jrl	z, Tbl_PedalNames_Loop
	cp	a, 129
	jrl	nz, ParamPopup_PartPedal_Skip24
	incw	1, (0x1174:16)
	jp	Tbl_PedalNames_Loop
ParamPopup_PartPedal_Skip24:
	ld	l, 0:opc
	call	Tbl_PedalNames_Helper7
	ldb_d8	a, (0x116f)
	cp	a, 47
	jrl	z, Tbl_PedalNames_Loop
	cp	a, 95
	jrl	z, Tbl_PedalNames_Loop
ParamPopup_PartPedal_Epilogue:
	pop	xiy
	ret
Tbl_PedalNames_Helper4:
	ld	xix, 0x116e
	xor	wa, wa
	ld	bc, 3:i3
	ld	(xix+), wa
	djnz16	bc, -6
	ret
Tbl_PedalNames_Helper5:
	ldw_d16	wa, (0x1178)
	cp	wa, 5:i3
	jrl	nz, ParamPopup_PartPedal_Skip26
	ldw_d16	hl, (0x117a)
	call	DisplayStr_ComputeTableAddr
	ld	xhl, (0x10fd:16)
	ld	wa, (xhl+1)
	cp	wa, 0:i3
	jrl	nz, ParamPopup_PartPedal_Skip25
	ld	l, 1:opc
	jp	Tbl_PedalNames_Return2
ParamPopup_PartPedal_Skip25:
	ld	(0x117a:16), wa
	ldw	wa, 255
	jp	Tbl_PedalNames_Join4
ParamPopup_PartPedal_Skip26:
	dec	1, wa
Tbl_PedalNames_Join4:
	ld	(0x1178:16), wa
	xor	hl, hl
Tbl_PedalNames_Return2:
	ret
ParamPopup_PartPedal_Helper:
	push	xix
	ldw_d16	wa, (0x1178)
	cp	wa, 255
	jrl	nz, ParamPopup_PartPedal_Skip27
	ldw_d16	hl, (0x117a)
	call	DisplayStr_ComputeTableAddr
	ld	xhl, (0x10fd:16)
	ld	hl, (xhl+3)
	ld	(0x117a:16), hl
	ld	wa, 5:i3
	jp	Tbl_PedalNames_Join5
ParamPopup_PartPedal_Skip27:
	inc	1, wa
Tbl_PedalNames_Join5:
	ld	(0x1178:16), wa
	pop	xix
	ret
Tbl_PedalNames_Helper6:
	ldw_d16	hl, (0x117a)
	call	DisplayStr_ComputeTableAddr
	ld	xhl, (0x10fd:16)
	ldw_d16	iy, (0x1178)
	ld	a, (xhl+iy)
	ret
Tbl_PedalNames_Helper7:
	pushdi_w	(0x117a)
	pushdi_w	(0x1178)
	ld	xix, 0x116e
	push	xix
	call	Tbl_PedalNames_Helper6
	pop	xix
	ld	(xix+), a
ParamPopup_PartPedal_Join:
	push	xix
	call	ParamPopup_PartPedal_Helper
	call	Tbl_PedalNames_Helper6
	pop	xix
	bit	7, a
	jrl	nz, ParamPopup_PartPedal_Entry
	ld	(xix+), a
	jp	ParamPopup_PartPedal_Join
ParamPopup_PartPedal_Entry:
	popw (0x1178:16)	; popw (0x1178)
	popw (0x117a:16)	; popw (0x117a)
	ret
Display_RedrawStatusBar:
	bit 0, (0x0f57:16)
	jrl nz, Scoop_Return
	cp (0x8c9c:16), 0x8a
	jrl nz, Scoop_Return
	ld (0x03efa8:24), 0x00
	call UIRender_LoadTwoDescriptors
	ld l, (0x0def:16)
	xor H,H
	cp L,0x12
	jr nz, Scoop_SetupDisplayTables
	call Display_DeferOrDrawWall
	ld (0x03efa8:24), 0x00
	ld XIY,StyleUI_ParamBlock_AltD
	ld XIX,StyleUI_ParamBlock_AltE
	call UIRender_TwoTableGeneral
	call Display_DeferOrUpdateScreen
	jrl t, Scoop_Return
Scoop_SetupDisplayTables:
	ld xiy, StyleUI_ParamBlock_AltB
	ld xix, StyleUI_ParamBlock_AltC
	push xhl
	call UIRender_TwoTableGeneral
	pop xhl
	cp (3429:16), 0
	jr nz, Scoop_InitPartDisplay
	call Scoop_InitDisplayFull
	jr Scoop_Return

Scoop_InitPartDisplay:
	ld a, (3424:16)
	ld (4494:16), a
	ld xiy, StyleUI_ScreenData_Main_0x1EF
	push xhl
	call UIRender_ConditionalDrawInit
	pop xhl
	push xhl
	sla hl, 2
	ld xiy, StyleUI_ParamBlockPtrTable
	cp (3429:16), 2
	jr nz, Scoop_SelectModeTable_2Part
	ld xiy, Scoop_InitPartDisplay_Data

Scoop_SelectModeTable_2Part:
	ld	xiy, (xiy+hl)
	ld xix, Scoop_SelectModeTable_2Part_Data
	cp (3429:16), 2
	jr nz, Scoop_SelectModeTable_2Part_XIX
	ld xix, Scoop_SelectModeTable_2Part_Data_2

Scoop_SelectModeTable_2Part_XIX:
	ld	xix, (xix+hl)
	call UIRender_TwoTableGeneral
	call Scoop_CheckPartStatus
	pop xhl
	cp l, 0:i3
	jr nz, Scoop_SetPartIndexAndDisplay
	ld xiy, StyleUI_ScreenData_Main_0xD3F
	ld xix, StyleUI_ScreenData_MeasCursor
	call UIRender_TwoTableGeneral

Scoop_SetPartIndexAndDisplay:
	ld a, (3424:16)
	dec 1, a
	ld xiy, 0xf1a0
	ld	a, (xiy+a)
	ld (4493:16), a
	ld xiy, SOUND_DATA_DRUM_KITS_0x3A
	call Scoop_ConditionalCurveUpdate

Scoop_Return:
	ret

Scoop_CheckPartStatus:
	pushw hl
	push xix
	ld h, 0x0:opc
	ld l, (3424:16)
	dec 1, l
	ld xix, 0xf1a0
	cp	(xix+hl), 0x0c
	jrl nz, Scoop_CheckPartStatus_End
	call Scoop_CallDisplayHelper

Scoop_CheckPartStatus_End:
	pop xix
	popw hl
	ret

Scoop_CallDisplayHelper:
	ld xiy, Scoop_DisplayData_ButtonLayout
	ld xix, Scoop_DrawButtonLayout2
	call UIRender_TwoTableGeneral
	ret

	; Uirender display list, 8 B.  Read by Scoop_CallDisplayHelper (0xF00A6A): `ld xiy, Scoop_DisplayData_ButtonLayout`
	; handed in XIY to UIRender_TwoTableGeneral
Scoop_DisplayData_ButtonLayout:
	.byte	0x0e, 0x08, 0x92, 0x12, 0x06, 0x00, 0x13, 0x00
; Scoop_DrawButtonLayout2 -- reached as the XIX continuation of
; Scoop_CallDisplayHelper's UIRender_TwoTableGeneral call; draws the next button
; layout list the same way.
Scoop_DrawButtonLayout2:
	ld	xiy, Scoop_CallDisplayHelper_DisplayList
	ld	xix, Scoop_CallDisplayHelper_DisplayList_Code
	call	UIRender_TwoTableGeneral
	ret
	; Uirender display list, 10 B.  Read by Scoop_DrawButtonLayout2: `ld xiy, Scoop_CallDisplayHelper_DisplayList`
	; handed in XIY to UIRender_TwoTableGeneral
Scoop_CallDisplayHelper_DisplayList:
	.byte	0x1b, 0x0a, 0x08, 0x00, 0x32, 0x00, 0x10, 0x01, 0x42, 0x00
Scoop_CallDisplayHelper_DisplayList_Code:
	ld	xiy, 0xe0b42a
	ld	xix, SOUND_DATA_DRUM_KITS_0x1A
	call	UIRender_SingleTable
	ret

Scoop_DrawGridLines:
	ld xiy, Scoop_GridLineData
	ld xix, Scoop_DrawGridDividers
	call UIRender_TwoTableGeneral
	call Scoop_DrawGridDividers
	ret

	; Uirender display list, 90 B.  Read by Scoop_DrawGridLines (0xF00AA9): `ld xiy, Scoop_GridLineData`
	; handed in XIY to UIRender_TwoTableGeneral
Scoop_GridLineData:
	.byte	0x1b, 0x0a, 0x08, 0x00, 0x32, 0x00, 0x10, 0x01, 0x42, 0x00, 0x1b, 0x0a, 0x05, 0x00, 0x4b, 0x00
	.byte	0x05, 0x00, 0x4f, 0x00, 0x1b, 0x0a, 0x49, 0x00, 0x4b, 0x00, 0x49, 0x00, 0x4f, 0x00, 0x1b, 0x0a
	.byte	0x89, 0x00, 0x4b, 0x00, 0x89, 0x00, 0x4f, 0x00, 0x1b, 0x0a, 0xc9, 0x00, 0x4b, 0x00, 0xc9, 0x00
	.byte	0x4f, 0x00, 0x1b, 0x0a, 0x09, 0x01, 0x4b, 0x00, 0x09, 0x01, 0x4f, 0x00, 0x1b, 0x0a, 0x05, 0x00
	.byte	0x50, 0x00, 0x09, 0x01, 0x50, 0x00, 0x1b, 0x0a, 0x08, 0x00, 0x5f, 0x00, 0x10, 0x01, 0x6f, 0x00
	.byte	0x1b, 0x0a, 0x08, 0x00, 0x8c, 0x00, 0x10, 0x01, 0x9c, 0x00

Scoop_DrawGridDividers:
	ld xiy, Scoop_GridDividerData
	ld xix, Scoop_DrawFrameLines
	call UIRender_TwoTableGeneral
	ret

	; Uirender display list, 30 B.  Read by Scoop_DrawGridDividers (0xF00B16): `ld xiy, Scoop_GridDividerData`
	; handed in XIY to UIRender_TwoTableGeneral
Scoop_GridDividerData:
	.byte	0x1b, 0x0a, 0x08, 0x00, 0x28, 0x00, 0x27, 0x00, 0x32, 0x00, 0x1b, 0x0a, 0x08, 0x00, 0x55, 0x00
	.byte	0x27, 0x00, 0x5f, 0x00, 0x1b, 0x0a, 0x08, 0x00, 0x82, 0x00, 0x27, 0x00, 0x8c, 0x00

Scoop_DrawFrameLines:
	ld xiy, Scoop_FrameData
	ld xix, Scoop_InitDisplayFull
	call UIRender_TwoTableGeneral
	ret

	; Uirender display list, 113 B.  Read by Scoop_DrawFrameLines (0xF00B43): `ld xiy, Scoop_FrameData`
	; handed in XIY to UIRender_TwoTableGeneral
Scoop_FrameData:
	.byte	0x0e, 0x08, 0x12, 0x06, 0x06, 0x00, 0x13, 0x00, 0x0e, 0x08, 0x52, 0x0c, 0x06, 0x00, 0x13, 0x00
	.byte	0x0e, 0x08, 0x92, 0x12, 0x06, 0x00, 0x13, 0x00, 0x0e, 0x08, 0xd1, 0x18, 0x07, 0x00, 0x13, 0x00
	.byte	0x20, 0x29, 0x19, 0x1f, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x0e, 0x08, 0xd5, 0x20, 0x05, 0x00, 0xec
	.byte	0x00, 0x0e, 0x08, 0xda, 0x20, 0x05, 0x00, 0xec, 0x00, 0x0e, 0x08, 0xdf, 0x20, 0x05, 0x00, 0xec
	.byte	0x00, 0x0e, 0x08, 0xe4, 0x20, 0x05, 0x00, 0xec, 0x00, 0x0e, 0x08, 0xe9, 0x20, 0x05, 0x00, 0xec
	.byte	0x00

Scoop_InitDisplayFull:
	ld (0x03efa8:24), 0x00
	calr Scoop_DrawFrameLines
	ld xiy, StyleUI_ParamBlock_AltE
	ld xix, StyleUI_ParamBlockPtrTable
	call UIRender_TwoTableGeneral
	ld a, (3424:16)
	ld (4494:16), a
	ld xiy, StyleUI_ScreenData_Main_0x1EF
	call UIRender_ConditionalDrawInit
	ld a, (3424:16)
	dec 1, a
	ld xiy, 0xf1a0
	ld	a, (xiy+a)
	ld (4493:16), a
	ld xiy, SOUND_DATA_DRUM_KITS_0x3A
	call Scoop_ConditionalCurveUpdate
	ret

Display_RedrawMainContent:
	cp (0x8c9c:16), 0x8a
	jr nz, Scoop_RedrawMainContent_End
	ld (0x03efa8:24), 0x00
	ld XIY,StyleUI_ScreenData_Main_0x1F9
	call Scoop_CurveUpdate_Direct
Scoop_RedrawMainContent_End:
	ret

Display_RedrawFooter:
	cp (0x8c9c:16), 0x8a
	jr nz, Scoop_RedrawFooter_End
	ld (0x03efa8:24), 0x00
	ld a, (0x0f52:16)
	ld (0x1191:16), a
	ld (0x1192:16), a
	ld XIY,StyleUI_ScreenData_Main_0x21C
	cpw (0x0e50:16), 0x0000
	jr nz, Scoop_FooterShowPartValue
	ld XIX,StyleUI_ScreenData_Main_0x258
	jr t, Scoop_FooterCallDisplay
Scoop_FooterShowPartValue:
	ld a, (3922:16)
	ld (4499:16), a
	ld xix, StyleUI_ScreenData_Main_0x276

Scoop_FooterCallDisplay:
	call GraphicsRender_TwoTable

Scoop_RedrawFooter_End:
	ret

;=============================================================================
; Display_RedrawTitleBar - Redraw the title bar region
;=============================================================================
Display_RedrawTitleBar:
	cp (0x8c9c:16), 0x8a
	jrl nz, Scoop_TitleBar_End
	ld (0x03efa8:24), 0x02
	calr Scoop_DrawGridLines
	calr Scoop_TitleBar_SelectPartRange
	cpw (0x0e4c:16), 0x0000
	jr z, Scoop_TitleBar_Part1Check
	xor BC,BC
	calr Scoop_TitleBar_GetPartConfig
	cpw (0x0e4c:16), 0x03e8
	jr c, Scoop_TitleBar_ShowBPM_Part0
	ld XIY,StyleUI_ScreenData_Main_0x1E0
	call Scoop_ConditionalGlideSetup
	jr t, Scoop_TitleBar_Part1Check
Scoop_TitleBar_ShowBPM_Part0:
	ld wa, (3660:16)
	ld (4487:16), wa
	ld xiy, StyleUI_ScreenData_Main_0x1C2
	call GraphicsRender_EventCheck

Scoop_TitleBar_Part1Check:
	cpw (3662:16), 0
	jr z, Scoop_TitleBar_Part2Check
	ld bc, 1:i3
	calr Scoop_TitleBar_GetPartConfig
	cpw (3662:16), 1000
	jr c, Scoop_TitleBar_ShowBPM_Part1
	ld xiy, StyleUI_ScreenData_Main_0x1E5
	call Scoop_ConditionalGlideSetup
	jr Scoop_TitleBar_Part2Check

Scoop_TitleBar_ShowBPM_Part1:
	ld wa, (3662:16)
	ld (4489:16), wa
	ld xiy, StyleUI_ScreenData_Main_0x1CC
	call GraphicsRender_EventCheck

Scoop_TitleBar_Part2Check:
	cpw (3664:16), 0
	jr z, Scoop_TitleBar_End
	ld bc, 2:i3
	calr Scoop_TitleBar_GetPartConfig
	cpw (3664:16), 1000
	jr c, Scoop_TitleBar_ShowBPM_Part2
	ld xiy, StyleUI_ScreenData_Main_0x1EA
	call Scoop_ConditionalGlideSetup
	jr Scoop_TitleBar_End

Scoop_TitleBar_ShowBPM_Part2:
	ld wa, (3664:16)
	ld (4491:16), wa
	ld xiy, StyleUI_ScreenData_Main_0x1D6
	call GraphicsRender_EventCheck

Scoop_TitleBar_End:
	ret

Scoop_TitleBar_SelectPartRange:
	xor xbc, xbc
	ld c, (3667:16)
	cp c, (3668:16)
	jr nc, Scoop_TitleBar_ClampParts
	ld c, (3668:16)

Scoop_TitleBar_ClampParts:
	cp c, 4:i3
	jr ule, Scoop_TitleBar_DisplayPartTable
	ld bc, 4:i3

Scoop_TitleBar_DisplayPartTable:
	ld xiy, StyleUI_ScreenData_Main
	ld xix, xiy
	muls bc, 0x2d
	add xix, xbc
	call UIRender_TwoTableGeneral
	ret

Scoop_TitleBar_GetPartConfig:
	ld xiy, StyleUI_ScreenData_Main_0xB4
	cp bc, 1:i3
	jr ge, Scoop_TitleBar_Part1Config
	ld a, (3666:16)
	cp a, 0:i3
	jr nz, Scoop_TitleBar_ShowPartSlot
	jr Scoop_TitleBar_GetPartConfig_End

Scoop_TitleBar_Part1Config:
	cp bc, 2:i3
	jr ge, Scoop_TitleBar_Part2Config
	add xiy, 0x5a
	ld a, (3667:16)
	cp a, 0:i3
	jr nz, Scoop_TitleBar_ShowPartSlot
	jr Scoop_TitleBar_GetPartConfig_End

Scoop_TitleBar_Part2Config:
	add xiy, 0xb4
	ld a, (3668:16)
	cp a, 0:i3
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
	cp (0x8c9c:16), 0x8a
	jr z, Scoop_Selection_RedrawActive
	jp Scoop_Selection_End
Scoop_Selection_RedrawActive:
	ld (0x03efa8:24), 0x01
	ld a, (3429:16)
	cp a, 0:i3
	jr nz, Scoop_Selection_CheckMode1
	pushw wa
	ld xiy, StyleUI_ScreenData_Main_0x97E
	ld xix, StyleUI_ScreenData_Main_0x986
	call UIRender_SingleTable
	ld a, (3823:16)
	ld (4497:16), a
	popw wa
	ld xiy, StyleUI_ScreenData_Main_0x9BB
	call UIRender_TwoTableEvtCheck
	jp Scoop_Selection_End

Scoop_Selection_CheckMode1:
	cp a, 1:i3
	jr nz, Scoop_Selection_DrawMode2

Scoop_Selection_DrawMode1:
	ld	xiy, StyleUI_ScreenData_Main_0x986
	ld	xix, StyleUI_ScreenData_Main_0x990
	call	UIRender_TwoTableGeneral
	cp	(13939:16), 0
	jr	z, Scoop_Selection_End
	ld	a, (13939:16)
	ld	(4495:16), a
	ld	xiy, StyleUI_ScreenData_Main_0xA06
	call	UIRender_TwoTableEvtCheck
	jr	Scoop_Selection_End
Scoop_Selection_DrawMode2:
	cp a, 2:i3
	jr z, Scoop_Selection_DrawMode1
	ld xiy, StyleUI_ScreenData_Main_0x97E
	ld xix, StyleUI_ScreenData_Main_0x986
	call UIRender_SingleTable
	pushw wa
	ld a, (3922:16)
	ld (4500:16), a
	popw wa
	ld xiy, StyleUI_ScreenData_Main_0x990
	call UIRender_TwoTableEvtCheck

Scoop_Selection_End:
	ret

Display_RedrawSidePanel:
	bit 0, (3927:16)

	; jrl nz, Scoop_SidePanel_End (v7 displacement)
	jrl	nz, Scoop_SidePanel_End
	; cpdi8 (0x8d38), 138 (v7 patched)
	cp	(0x8c9c:16), 138
	; jrl nz, Scoop_SidePanel_End (v7 displacement)
	jrl	nz, Scoop_SidePanel_End
	; ld xiy, 0x372e (v7 patched)
	ld	xiy, 0x3692

	ld xix, 0xa51

	xor de, de



Scoop_SidePanel_DrawPartLoop:
	xor bc, bc
	ld xiz, 0xe52
	xor xwa, xwa
	ld a, e
	add xiz, xwa
	ld d, (xiz)
	cp d, 0:i3
	jr z, Scoop_SidePanel_NextPart

Scoop_SidePanel_DrawSlotPair:
	xor hl, hl
	ld l, c
	ld	l, (xiy+hl)
	and l, 0xf
	calr Scoop_SidePanel_DrawOneSlot
	add xix, 0x4
	xor hl, hl
	ld l, c
	ld	l, (xiy+hl)
	and l, 0xf0
	srl l, 4
	calr Scoop_SidePanel_DrawOneSlot
	add xix, 0x4
	inc 1, c
	cp c, d
	jr c, Scoop_SidePanel_DrawSlotPair

Scoop_SidePanel_NextPart:
	inc 1, e
	cp e, 3:i3
	jr ge, Scoop_SidePanel_DrawValues
	add xiy, 0x4
	ld a, 0x8:opc
	mul wa, c
	extz xwa
	sub xix, xwa
	add xix, 0x708
	jr Scoop_SidePanel_DrawPartLoop

Scoop_SidePanel_DrawValues:
	ld (0x03efa8:24), 0x00
	ld a, (3666:16)
	cp (3660:16), 0
	jr nz, Scoop_SidePanel_StoreAndDraw
	ld a, 0x0:opc

Scoop_SidePanel_StoreAndDraw:
	ld (4507:16), a
	ld a, (3667:16)
	ld (4508:16), a
	ld a, (3668:16)
	ld (4509:16), a
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
	ld bc, 4:i3
	ld (0x03efa8:24), 0x00
	ld xwa, 0x11d4
	ld (xwa), 0x6
	ld (xwa + 1), 0x8
	ld (xwa + 2), ix
	extz hl
	extz xhl
	sll xhl, 2
	add xiy, xhl
	ld L, (xiy+)
	ld (xwa + 4), l
	ld L, (xiy+)
	ld (xwa + 5), l
	ld L, (xiy+)
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
	cp (3930:16), 0
	jr z, Scoop_AltContent_ClearRegions
	ld xix, 0x820
	xor wa, wa
	ld a, (3930:16)
	dec 1, wa
	muls wa, 0x708
	add xix, xwa
	xor xwa, xwa
	ld a, (3931:16)
	cp a, 0:i3
	jr z, Scoop_AltContent_ClearRegions
	add xix, xwa
	ld (0x03efa8:24), 0x02
	ld xiy, StyleUI_ScreenData_CtlOnly_0x20
	ld bc, 3:i3
	xor hl, hl
	ld (4579:16), 6
	ld (4580:16), 7
	ld (4581:16), ix
	ld (4583:16), 69
	ld (4584:16), 78
	ld (4585:16), 68
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
	ld (0x03efa8:24), 0x02
	ldw bc, 0x20
	ldw hl, 0xa
	ld (4586:16), 14
	ld (4587:16), 8
	ld (4588:16), iy
	ld (4590:16), bc
	ld (4592:16), hl
	ld xiy, 0x11ea
	call UIRender_ConditionalFBCall
	ret

Display_RedrawButtonLabels:
	cp (0x8c9c:16), 0x8a
	jr nz, Scoop_ButtonLabels_End
	ld (0x03efa8:24), 0x00
	call Scoop_ButtonLabels_CopySlotData
	ld XIY,StyleUI_ScreenData_Main_0xBD4
	ld XIX,StyleUI_ScreenData_Main_0xD3C
	call GraphicsRender_TwoTable
	call Scoop_ButtonLabels_SetupPartButtons
	ld (0x03efa8:24), 0x02
	ld XIY,StyleUI_ScreenData_Main_0x276
	ld XIX,StyleUI_ScreenData_Main_0x3DE
	call GraphicsRender_TwoTable
	call Scoop_ButtonLabels_DrawPitchLabels
	ld XIX,0x00000e55
	ld XIY,StyleUI_ScreenData_Main_0x3DE
	calr Scoop_ButtonLabels_DrawCategory
	call Scoop_ButtonLabels_DrawAmpLabels
	ld XIX,0x00000e75
	ld XIY,StyleUI_ScreenData_Main_0x546
	calr Scoop_ButtonLabels_DrawCategory
	call Scoop_ButtonLabels_DrawFilterLabels
	ld XIX,0x00000e95
	ld XIY,StyleUI_ScreenData_Main_0x6AE
	calr Scoop_ButtonLabels_DrawCategory
Scoop_ButtonLabels_End:
	ret

Scoop_ButtonLabels_CopySlotData:
	pushw wa
	pushw bc
	push xix
	push xiy
	ld xix, 0x11b3
	ld xiy, 0xe55
	ld c, 0x8:opc

Scoop_ButtonLabels_CopyLoop:
	ld a, (xiy)
	ld (xix+), a
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_CopyLoop
	ld xix, 0x1192
	ld xiy, 0xe75
	ld c, 0x8:opc

Scoop_ButtonLabels_DrawRow1:
	ld a, (xiy)
	ld (xix+), a
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_DrawRow1
	ld xiy, 0xe95
	ld c, 0x8:opc

Scoop_ButtonLabels_DrawRow1_Alt:
	ld a, (xiy)
	ld (xix+), a
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
	ld c, 0x8:opc

Scoop_ButtonLabels_Part1:
	ld a, (xiy)
	ld (xix+), a
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_Part1
	ld xiy, 0xe76
	ld c, 0x8:opc

Scoop_ButtonLabels_Part2:
	ld a, (xiy)
	ld (xix+), a
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_Part2
	ld xiy, 0xe96
	ld c, 0x8:opc

Scoop_ButtonLabels_Part3:
	ld a, (xiy)
	ld (xix+), a
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
	ld c, 0x8:opc

Scoop_ButtonLabels_DrawPitchLabel1:
	ld wa, (xiy)
	ld (xix+), WA
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
	ld c, 0x8:opc

Scoop_ButtonLabels_DrawAmpLabel1:
	ld wa, (xiy)
	ld (xix+), WA
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
	ld c, 0x8:opc

Scoop_ButtonLabels_DrawFilterLabel1:
	ld wa, (xiy)
	ld (xix+), WA
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_DrawFilterLabel1
	pop xiy
	pop xix
	popw bc
	popw wa
	ret

Scoop_ButtonLabels_DrawCategory:
	cp (0x8c9c:16), 0x8a
	jr nz, Scoop_EventHandler_SetupData
	xor BC,BC
Scoop_ButtonLabels_DrawCategoryData:
	push xix
	inc 2, xix
	ld a, (xix)
	cp a, 0:i3
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
	cp a, 1:i3
	jr nz, Scoop_EventHandler_PartSelect
	ld (4531:16), 0
	jr Scoop_EventHandler_PartRedrawData

Scoop_EventHandler_PartSelect:
	cp a, 2:i3
	jr nz, Scoop_EventHandler_Part1
	ld (4531:16), a
	jr Scoop_EventHandler_PartRedrawData

Scoop_EventHandler_Part1:
	cp a, 0xb
	jr nz, Scoop_EventHandler_PartRedraw
	ld (4531:16), 3
	jr Scoop_EventHandler_PartRedrawData

Scoop_EventHandler_PartRedraw:
	ld (4531:16), 1

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
	cp bc, 7:i3
	jr ule, Scoop_ButtonLabels_DrawCategoryData

Scoop_EventHandler_SetupData:
	ret

Scoop_EventHandler_MenuSwitch:
	pushw wa
	call SetWall_ParserInit
	popw wa
	ld (0x287a:16), 0
	bit 2, (0x287b:16)
	jr nz, Scoop_EventHandler_MenuSwitch_Mode1
	xor de, de
	ld wa, (3299:16)
	xor bc, bc
	ld c, (1075:16)
	ldfr_werp DE, 0xe2
	div xwa, bc
	ldto_werp DE, 0xe2
	ld c, e
	ld de, wa
	inc 1, de
	ld a, (1075:16)
	jr Scoop_EventHandler_MenuSwitch_End

Scoop_EventHandler_MenuSwitch_Mode1:
	ld (0x288d:16), w
	call SetWall_DualPassScanner
	xor wa, wa
	ld a, (0x288e:16)
	ld bc, (3299:16)
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
	ld a, (0x288e:16)
	jr Scoop_EventHandler_MenuSwitch_Mode2

Scoop_EventHandler_MenuSwitch_End:
	ret

Scoop_EventHandler_Scroll:
	ld (0x287a:16), 0
	ld hl, (0x28ba:16)
	call SetWall_StreamIndexResolve
	ld xwa, (4349:16)
	ld (9854:16), xwa
	ld hl, (0x289f:16)
	call SetWall_StreamIndexResolve
	ld xwa, (4349:16)
	ld (9850:16), xwa
	cp de, (0x28ba:16)
	jr nz, Scoop_Scroll_ValidateRange
	ld iy, (0x28bc:16)
	sub iy, 0x5
	inc 1, iy
	ld (9874:16), iy
	ld iy, (0x28bc:16)
	ld ix, (0x28b6:16)
	sub ix, 0x5
	inc 1, ix
	ld (9876:16), ix
	ld ix, (0x28b6:16)
	jrl Scoop_ButtonGrid_ProcessCell

Scoop_Scroll_ValidateRange:
	ld wa, (0x28b6:16)
	cp wa, (0x28bc:16)
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
	sub wa, (0x28bc:16)
	ld (9870:16), wa
	ldw bc, 0x100
	sub bc, 0x5
	sub bc, wa
	ld (9872:16), bc
	ld iy, (0x28bc:16)
	ld ix, (0x28b6:16)
	ld bc, (0x28bc:16)
	sub bc, 0x5
	inc 1, bc
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Data
	cp (0x287a:16), 0
	jrl nz, Scoop_ButtonGrid_Data

Scoop_EventHandler_CategorySelect:
	cp de, (0x28ba:16)
	jrl z, Scoop_CategorySelect_Pitch
	ld bc, (9870:16)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Draw
	cp (0x287a:16), 0
	jrl nz, Scoop_ButtonGrid_Data
	ld bc, (9872:16)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Data
	cp (0x287a:16), 0
	jr z, Scoop_EventHandler_CategorySelect
	jrl Scoop_ButtonGrid_Data

Scoop_CategorySelect_Pitch:
	ld wa, (9870:16)
	ld (9876:16), wa
	ldw bc, 0x100
	sub bc, 0x5
	ld (9874:16), bc
	jrl Scoop_ButtonGrid_ProcessCell

Scoop_CategorySelect_Amplitude:
	ld bc, (0x28bc:16)
	sub bc, 0x5
	inc 1, bc
	ld iy, (0x28bc:16)
	ld ix, (0x28b6:16)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Draw
	cp (0x287a:16), 0
	jrl nz, Scoop_ButtonGrid_Data
	call Scoop_SpecialMode_Data
	cp (0x287a:16), 0
	jrl nz, Scoop_ButtonGrid_Data

Scoop_CategorySelect_Filter:
	cp de, (0x28ba:16)
	jrl z, Scoop_CategorySelect_End
	ldw bc, 0x100
	sub bc, 0x5
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Draw
	cp (0x287a:16), 0
	jrl nz, Scoop_ButtonGrid_Data
	call Scoop_SpecialMode_Data
	cp (0x287a:16), 0
	jr z, Scoop_CategorySelect_Filter
	jrl Scoop_ButtonGrid_Data

Scoop_CategorySelect_End:
	ldw bc, 0x100
	sub bc, 0x5
	ld (9876:16), bc
	ld (9874:16), bc
	jrl Scoop_ButtonGrid_ProcessCell

Scoop_CategorySelect_UpdateDisplay:
	ld wa, (0x28bc:16)
	sub wa, (0x28b6:16)
	ld (9870:16), wa
	ldw bc, 0x100
	sub bc, 0x5
	sub bc, wa
	ld (9872:16), bc
	ld iy, (0x28bc:16)
	ld ix, (0x28b6:16)
	ld bc, (0x28b6:16)
	sub bc, 0x5
	inc 1, bc
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Draw
	cp (0x287a:16), 0
	jrl nz, Scoop_ButtonGrid_Data
	ld bc, (9870:16)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Data
	cp (0x287a:16), 0
	jrl nz, Scoop_ButtonGrid_Data

Scoop_EventHandler_ButtonGrid:
	cp de, (0x28ba:16)
	jrl z, Scoop_ButtonGrid_CheckBounds
	ld bc, (9872:16)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Draw
	cp (0x287a:16), 0
	jrl nz, Scoop_ButtonGrid_Data
	ld bc, (9870:16)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Data
	cp (0x287a:16), 0
	jr z, Scoop_EventHandler_ButtonGrid
	jr Scoop_ButtonGrid_Data

Scoop_ButtonGrid_CheckBounds:
	ld wa, (9872:16)
	ld (9876:16), wa
	ldw wa, 0x100
	sub wa, 0x5
	ld (9874:16), wa

Scoop_ButtonGrid_ProcessCell:
	ld wa, (0x28b8:16)
	sub wa, 0x5
	ld bc, (9874:16)
	sub bc, wa
	ld (9880:16), bc
	cp (9876:16), bc
	jr nc, Scoop_ButtonGrid_UpdateValue
	jr Scoop_ButtonGrid_End

Scoop_ButtonGrid_UpdateValue:
	call Scoop_SpecialMode_Setup
	jr Scoop_ButtonGrid_Data

Scoop_ButtonGrid_End:
	ld bc, (9876:16)
	call Scoop_SpecialMode_Setup
	call Scoop_SpecialMode_Draw
	cp (0x287a:16), 0
	jr nz, Scoop_ButtonGrid_Data
	ld bc, (9880:16)
	sub bc, (9876:16)
	call Scoop_SpecialMode_Setup

Scoop_ButtonGrid_Data:
	ret

Scoop_EventHandler_SpecialMode:
	ld	(0x287a:16), 0
	ld	hl, (0x28ba:16)
	call	SetWall_StreamIndexResolve
	push	xwa
	ld	xwa, (4349:16)
	ld	(9854:16), xwa
	ld	hl, (0x289f:16)
	call	SetWall_StreamIndexResolve
	ld	xwa, (4349:16)
	ld	(0x267a:16), xwa
	pop	xwa
	cp	de, (0x28ba:16)
	jr	nz, Scoop_EventHandler_SpecialMode_Skip14
	ldw	iy, 256
	sub iy, (10428:16)
	ld	(9874:16), iy
	ld	iy, (0x28bc:16)
	ldw	ix, 256
	sub ix, (10422:16)
	ld	(9876:16), ix
	ld	ix, (0x28b6:16)
	jrl	Scoop_EventHandler_SpecialMode_Join7
Scoop_EventHandler_SpecialMode_Skip14:
	ld	wa, (0x28b6:16)
	cp wa, (10428:16)
	jr	c, Scoop_EventHandler_SpecialMode_Skip
	jr	z, Scoop_EventHandler_SpecialMode_Skip2
	jr	ugt, Scoop_EventHandler_SpecialMode_Skip3
Scoop_EventHandler_SpecialMode_Skip:
	jr	Scoop_EventHandler_SpecialMode_Join
Scoop_EventHandler_SpecialMode_Skip2:
	jrl	Scoop_EventHandler_SpecialMode_Join3
Scoop_EventHandler_SpecialMode_Skip3:
	jrl	Scoop_EventHandler_SpecialMode_Join5
Scoop_EventHandler_SpecialMode_Join:
	ldw	wa, 256
	sub wa, (10422:16)
	ldw	bc, 256
	sub bc, (10428:16)
	sub wa, bc
	ld	(9870:16), wa
	ldw	bc, 256
	sub	bc, 5
	sub	bc, wa
	ld	(9872:16), bc
	ld	iy, (0x28bc:16)
	ld	ix, (0x28b6:16)
	ldw	bc, 256
	sub bc, (10428:16)
	call	Scoop_EventHandler_SpecialMode_Helper2
	call	Scoop_SpecialMode_UpdateParams
	cp	(0x287a:16), 0
	jr	z, Scoop_EventHandler_SpecialMode_Loop
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Loop:
	cp de, (10426:16)
	jr	nz, Scoop_EventHandler_SpecialMode_Skip4
	jr	Scoop_EventHandler_SpecialMode_Join2
Scoop_EventHandler_SpecialMode_Skip4:
	ld	bc, (9870:16)
	call	Scoop_EventHandler_SpecialMode_Helper2
	call	Scoop_EventHandler_SpecialMode_Helper
	cp	(0x287a:16), 0
	jr	z, Scoop_EventHandler_SpecialMode_Skip5
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Skip5:
	ld	bc, (9872:16)
	call	Scoop_EventHandler_SpecialMode_Helper2
	call	Scoop_SpecialMode_UpdateParams
	cp	(0x287a:16), 0
	jr	z, Scoop_EventHandler_SpecialMode_Loop
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Join2:
	ld	wa, (9870:16)
	ld	(9876:16), wa
	ldw	bc, 256
	sub	bc, 5
	ld	(9874:16), bc
	jrl	Scoop_EventHandler_SpecialMode_Join7
Scoop_EventHandler_SpecialMode_Join3:
	ldw	bc, 256
	sub bc, (10428:16)
	ld	iy, (0x28bc:16)
	ld	ix, (0x28b6:16)
	call	Scoop_EventHandler_SpecialMode_Helper2
	call	Scoop_SpecialMode_UpdateParams
	cp	(0x287a:16), 0
	jr	z, Scoop_EventHandler_SpecialMode_Skip6
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Skip6:
	call	Scoop_EventHandler_SpecialMode_Helper
	cp	(0x287a:16), 0
	jr	z, Scoop_EventHandler_SpecialMode_Loop2
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Loop2:
	cp de, (10426:16)
	jr	nz, Scoop_EventHandler_SpecialMode_Skip7
	jr	Scoop_EventHandler_SpecialMode_Join4
Scoop_EventHandler_SpecialMode_Skip7:
	ldw	bc, 256
	sub	bc, 5
	call	Scoop_EventHandler_SpecialMode_Helper2
	call	Scoop_SpecialMode_UpdateParams
	cp	(0x287a:16), 0
	jr	z, Scoop_EventHandler_SpecialMode_Skip8
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Skip8:
	call	Scoop_EventHandler_SpecialMode_Helper
	cp	(0x287a:16), 0
	jr	z, Scoop_EventHandler_SpecialMode_Loop2
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Join4:
	ldw	bc, 256
	sub	bc, 5
	ld	(9876:16), bc
	ld	(9874:16), bc
	jrl	Scoop_EventHandler_SpecialMode_Join7
Scoop_EventHandler_SpecialMode_Join5:
	ldw	wa, 256
	sub wa, (10428:16)
	ldw	bc, 256
	sub bc, (10422:16)
	sub wa, bc
	ld	(9870:16), wa
	ldw	bc, 256
	sub	bc, 5
	sub	bc, wa
	ld	(9872:16), bc
	ld	iy, (0x28bc:16)
	ld	ix, (0x28b6:16)
	ldw	bc, 256
	sub bc, (10422:16)
	call	Scoop_EventHandler_SpecialMode_Helper2
	call	Scoop_EventHandler_SpecialMode_Helper
	cp	(0x287a:16), 0
	jr	z, Scoop_EventHandler_SpecialMode_Skip9
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Skip9:
	ld	bc, (9870:16)
	call	Scoop_EventHandler_SpecialMode_Helper2
	call	Scoop_SpecialMode_UpdateParams
	cp	(0x287a:16), 0
	jr	z, Scoop_EventHandler_SpecialMode_Loop3
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Loop3:
	cp de, (10426:16)
	jr	nz, Scoop_EventHandler_SpecialMode_Skip10
	jr	Scoop_EventHandler_SpecialMode_Join6
Scoop_EventHandler_SpecialMode_Skip10:
	ld	bc, (9872:16)
	call	Scoop_EventHandler_SpecialMode_Helper2
	call	Scoop_EventHandler_SpecialMode_Helper
	cp	(0x287a:16), 0
	jr	z, Scoop_EventHandler_SpecialMode_Skip11
	jr	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Skip11:
	ld	bc, (9870:16)
	call	Scoop_EventHandler_SpecialMode_Helper2
	call	Scoop_SpecialMode_UpdateParams
	cp	(0x287a:16), 0
	jr	z, Scoop_EventHandler_SpecialMode_Loop3
	jr	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Join6:
	ld	wa, (9872:16)
	ld	(9876:16), wa
	ldw	wa, 256
	sub	wa, 5
	ld	(9874:16), wa
Scoop_EventHandler_SpecialMode_Join7:
	ldw	wa, 255
	sub wa, (10424:16)
	ld	bc, (9874:16)
	sub	bc, wa
	ld	(9880:16), bc
	cp (9876:16), bc
	jr	nc, Scoop_EventHandler_SpecialMode_Skip12
	jr	Scoop_EventHandler_SpecialMode_Join8
Scoop_EventHandler_SpecialMode_Skip12:
	call	Scoop_EventHandler_SpecialMode_Helper2
	jr	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Join8:
	ld	bc, (9876:16)
	call	Scoop_EventHandler_SpecialMode_Helper2
	call	Scoop_EventHandler_SpecialMode_Helper
	cp	(0x287a:16), 0
	jr	z, Scoop_EventHandler_SpecialMode_Skip13
	jr	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Skip13:
	ld	bc, (9880:16)
	sub bc, (9876:16)
	call	Scoop_EventHandler_SpecialMode_Helper2
Scoop_EventHandler_SpecialMode_Return:
	ret

Scoop_SpecialMode_Setup:
	pushw wa
	push xde
	push xhl
	cp bc, 0:i3
	jr z, Scoop_SpecialMode_CheckState
	ld xhl, (9854:16)
	ld xde, (9850:16)
	extz xiy
	extz xix
	add xhl, xiy
	add xde, xix
	lddr83
	sub xhl, (9854:16)
	sub xde, (9850:16)
	ld iy, hl
	ld ix, de

Scoop_SpecialMode_CheckState:
	pop xhl
	pop xde
	popw wa
	ret

Scoop_SpecialMode_Data:
	xor iy, iy
	ld xiy, (9854:16)
	ld (4349:16), xiy
	ld wa, (xiy + 1)
	ld (0x28ba:16), wa
	extz xwa
	dec 1, xwa
	sla xwa, 8
	add xwa, (7514:16)
	ld (4349:16), xwa
	bitm 7, (xwa)
	jr nz, Scoop_SpecialMode_Toggle
	ld (0x287a:16), 11
	jr Scoop_SpecialMode_ToggleEnd

Scoop_SpecialMode_Toggle:
	ld xwa, (4349:16)
	ld (9854:16), xwa
	ldw iy, 0xff

Scoop_SpecialMode_ToggleEnd:
	ret

Scoop_SpecialMode_Draw:
	xor ix, ix
	ld xix, (9850:16)
	ld (4349:16), xix
	ld wa, (xix + 1)
	ld (0x289f:16), wa
	extz xwa
	dec 1, xwa
	sla xwa, 8
	add xwa, (7514:16)
	ld (4349:16), xwa
	bitm 7, (xwa)
	jr nz, Scoop_SpecialMode_DrawAlt
	ld (0x287a:16), 11
	jr Scoop_SpecialMode_DrawEnd

Scoop_SpecialMode_DrawAlt:
	ld xwa, (4349:16)
	ld (9850:16), xwa
	ldw ix, 0xff

Scoop_SpecialMode_DrawEnd:
	ret

Scoop_SpecialMode_UpdateParams:
	xor	iy, iy
	ld	xiy, (9854:16)
	ld	(3304:16), xiy
	ld	wa, (xiy+3)
	ld	(0x28ba:16), wa
	extz	xwa
	dec	1, xwa
	sla	xwa, 8
	add	xwa, (7514:16)
	ld	(4349:16), xwa
	bitm	7, (xwa)
	jr	nz, Scoop_SpecialMode_UpdateParams_Skip
	ld	(0x287a:16), 11
	jr	Scoop_SpecialMode_UpdateParams_Return
Scoop_SpecialMode_UpdateParams_Skip:
	push	xwa
	ld	xwa, (4349:16)
	ld	(9854:16), xwa
	pop	xwa
	ld	iy, 5:i3
Scoop_SpecialMode_UpdateParams_Return:
	ret
Scoop_EventHandler_SpecialMode_Helper:
	xor	xix, xix
	ld	xix, (9850:16)
	ld	(4349:16), xix
	ld	wa, (xix+3)
	ld	(0x289f:16), wa
	extz	xwa
	dec	1, xwa
	sla	xwa, 8
	add	xwa, (7514:16)
	ld	(4349:16), xwa
	bitm	7, (xix)
	bitm	7, (xwa)
	jr	nz, Scoop_SpecialMode_UpdateParams_Skip2
	ld	(0x287a:16), 11
	jr	Scoop_SpecialMode_UpdateParams_Return2
Scoop_SpecialMode_UpdateParams_Skip2:
	ld	xwa, (4349:16)
	ld	(9850:16), xwa
	ld	ix, 5:i3
Scoop_SpecialMode_UpdateParams_Return2:
	ret
Scoop_EventHandler_SpecialMode_Helper2:
	pushw	wa
	push	xde
	push	xhl
	cp	bc, 0:i3
	jr	z, Scoop_SpecialMode_UpdateParams_Epilogue
	ld	xhl, (9854:16)
	ld	xde, (9850:16)
	extz	xix
	extz	xiy
	add	xiy, xhl
	add	xix, xde
	ldir85
	sub	xiy, (9854:16)
	sub	xix, (9850:16)
Scoop_SpecialMode_UpdateParams_Epilogue:
	pop	xhl
	pop	xde
	popw	wa
	ret

Scoop_SpecialMode_ParamCheckBound:
	ld a, (0x2877:16)
	cp a, 1:i3
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
	ld a, (0x2877:16)
	dec 1, a
	ld iy, wa
	pushw bc
	ld c, a
	ld iz, (0x2875:16)
	ld a, c
	rcf
	stcf_a_16 iz
	ld (0x2875:16), iz
	popw bc
	ld xix, 0xf218
	ld	(xix+iy), 0x05
	ld xix, 0xcbe
	ld	(xix+iy), 0x05
	sla iy, 1
	ld xix, 0xf1f8
	ldw	(xix+iy), 0xffff
	ld xix, 0xc9e
	ldw	(xix+iy), 0xffff
	muls wa, 0x3
	ld iy, wa
	ld xix, 0xf250
	bit	7, (xix+iy)
	jr z, Scoop_SpecialMode_ValueEditEnd
	and	(xix+iy), 0x7f
	inc 1, iy
	ld	wa, (xix+iy)
	cp wa, 0xffff
	jr z, Scoop_SpecialMode_ValueEditEnd
	ldw	(xix+iy), 0xffff
	ld iy, wa
	ld wa, (0x286d:16)
	calr Scoop_SpecialMode_ValueSend

Scoop_SpecialMode_ValueEditEnd:
	ret

Scoop_SpecialMode_ValueSend:
	ld (3302:16), wa
	ld bc, (0xf22f:16)
	ld (0xf22f:16), iy
	xor wa, wa
	call DispatchHandler_SubJumpTable
	ld xhl, (4349:16)
	ld ix, (xhl + 1)
	ld de, ix
	cp ix, 0:i3
	jr z, Scoop_CurveUpdate_DrawSegment
	ld iy, ix
	ldw (xhl + 1), 0x0
	call DispatchHandler_SubJumpTable
	ld xhl, (4349:16)
	ld ix, iy
	ld iy, (xhl + 3)

Scoop_SpecialMode_ValueSend_Part1:
	call DispatchHandler_SubJumpTable
	ld xhl, (4349:16)
	ld ix, iy
	ld iy, (xhl + 3)
	cp iy, 0xffff
	jr z, Scoop_SpecialMode_ValueSend_End

Scoop_SpecialMode_ValueSend_Part2:
	andmi8 (xhl), 0x7f
	ld (xhl + 5), 0x82
	inc 1, wa
	cp wa, (3302:16)
	jr nz, Scoop_SpecialMode_ValueSend_Part1
	dec 1, wa

Scoop_SpecialMode_ValueSend_Part3:
	call DispatchHandler_SubJumpTable
	ld xhl, (4349:16)
	ld (xhl + 1), de

Scoop_SpecialMode_ValueSend_End:
	cp de, 0:i3
	jr z, Scoop_SpecialMode_CurveUpdate
	pushw iy
	ld iy, de
	call DispatchHandler_SubJumpTable
	ld xhl, (4349:16)
	popw iy
	ld (xhl + 3), iy

Scoop_SpecialMode_CurveUpdate:
	ld iy, ix
	call DispatchHandler_SubJumpTable
	ld xhl, (4349:16)
	andmi8 (xhl), 0x7f
	ld (xhl + 5), 0x82
	ld (xhl + 3), bc
	ld iy, bc
	call DispatchHandler_SubJumpTable
	ld xhl, (4349:16)
	ld (xhl + 1), ix
	inc 1, wa
	add (0xf231:16), wa
	ret

Scoop_CurveUpdate_DrawSegment:
	call	DispatchHandler_SubJumpTable
	ld	xhl, (0x10fd:16)
	ld	ix, iy
	ld	iy, (xhl+3)
	cp	iy, 65535
	jr	nz, Scoop_SpecialMode_ValueSend_Part2
	ldw	(0x0ce6:16), 0
	ld	iy, ix
	andmi8	(xhl), 127
	jr	Scoop_SpecialMode_ValueSend_Part3
ScoopDisp_BytecodeBlock1_Helper:
	ld E,A
	extz DE
	ld A,C
	extz WA
	ld BC,DE
	ld DE,WA
	ld wa, 1:i3
	jp Param_SignExtendReturn
Scoop_CurveUpdate_NextSegment:
	ld	e, a
	extz	de
	ld	a, c
	extz	wa
	ld	bc, de
	ld	de, wa
	ld	wa, 2:i3
	jp	Param_SignExtendReturn
Scoop_CurveUpdate_SegmentEnd:
	lda xsp, (xsp-272)
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
	ld	(xsp+266), wa
	ld	wa, (xsp+266)
	muls wa, 0x28
	sub hl, wa
	sll hl, 3
	ld	(xsp+264), hl
	ld iy, 0:i3
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
	mul xwa, de
	ld hl, iy
	extz xhl
	add xhl, xwa
	add xhl, xiz
	ld a, (xhl)
	extz wa
	lda xhl, (StyleUI_ScreenData_CtlOnly_0x23:24)
	ld	a, (xhl+wa)
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
	lda xbc, (Scoop_EnvelopeCalc_Data_2:24)
	ld	xwa, (xbc+wa)
	ld (xsp + 4), xwa
	decw	2, (xsp+266)
	ld	wa, (xsp+264)
	ld	(xsp+268), wa
	lda xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call CalcTotalWidth
	ld	wa, (xsp+264)
	add wa, hl
	ld	(xsp+272), wa
	ld	wa, (xsp+266)
	ld	(xsp+270), wa
	ld xwa, (xsp + 4)
	call GetCharHeight
	ld	wa, (xsp+266)
	add wa, hl
	ld	(xsp+274), wa
	lda xwa, (xsp+268)
	ld xhl, xwa
	lda xwa, (xsp+264)
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
	lda xsp, (xsp+272)
	ret

Scoop_EnvelopeCalc_Data:
	lda xsp, (xsp-274)
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
	jr	z, Scoop_CurveUpdate_SegmentEnd_Skip
	srla e	; srl A,E
Scoop_CurveUpdate_SegmentEnd_Skip:
	ld	(xsp+8), e
	ld	hl, (xbc+13)
	ld	de, (xbc+11)
	ld	wa, hl
	extz	xwa
	div	wa, 40
	ld	(xsp+268), wa
	ld	wa, (xsp+268)
	muls	wa, 40
	sub	hl, wa
	sll	hl, 3
	ld	(xsp+266), hl
	ld	iy, 0:i3
	cp	iy, de
	jr	nc, Scoop_CurveUpdate_SegmentEnd_Skip2
Scoop_CurveUpdate_SegmentEnd_Loop:
	ld	xiz, (xbc+7)
	ld	wa, iy
	extz	xwa
	lda	xix, (xsp+10)
	add	xix, xwa
	ld	a, (xsp+8)
	extz	wa
	mul	xwa, de
	ld	hl, iy
	extz	xhl
	add	xhl, xwa
	add	xhl, xiz
	ld	a, (xhl)
	extz	wa
	lda	xhl, (StyleUI_ScreenData_CtlOnly_0x23:24)
	ld	a, (xhl+wa)
	ld (xix), a
	inc 1, iy
	cp iy, de
	jr	c, Scoop_CurveUpdate_SegmentEnd_Loop
Scoop_CurveUpdate_SegmentEnd_Skip2:
	ld	wa, iy
	extz	xwa
	lda	xde, (xsp+10)
	add	xde, xwa
	ld	(xde), 0
	ld	a, (xbc+6)
	and	a, 63
	extz	wa
	sla	wa, 2
	lda	xbc, (Scoop_EnvelopeCalc_Data_2:24)
	ld	xwa, (xbc+wa)
	ld	(xsp+4), xwa
	decm	2, (xsp+268)
	ld	wa, (xsp+266)
	ld	(xsp+270), wa
	lda	xwa, (xsp+10)
	ld	xbc, (xsp+4)
	call	CalcTotalWidth
	ld	wa, (xsp+266)
	add	wa, hl
	ld	(xsp+274), wa
	ld	wa, (xsp+268)
	ld	(xsp+272), wa
	ld	xwa, (xsp+4)
	call	GetCharDescent
	ld	(xsp+8), hl
	ld	xwa, (xsp+4)
	call	GetCharHeight
	ld	wa, (xsp+268)
	add	wa, hl
	sub	wa, (xsp+8)
	ld	(xsp+276), wa
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
	lda	xsp, (xsp+274)
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
	jr	z, Scoop_CurveUpdate_SegmentEnd_Skip3
	srla l	; srl A,L
Scoop_CurveUpdate_SegmentEnd_Skip3:
	ld	a, l
	mul	a, 3
	extz	wa
	add	wa, wa
	ld	xbc, (xbc+7)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	extz	xwa
	div	wa, 40
	ld	(xsp+2), wa
	ld	wa, (xbc)
	extz	xwa
	div	wa, 40
	ld wa, qwa
	sll wa, 3
	ld (xsp+0:8), wa
	ld	wa, (xsp+2)
	add	wa, (xbc+4)
	ld	(xsp+6), wa
	ld	wa, (xbc+2)
	sll	wa, 3
	ld bc, (xsp+0:8)
	add bc, wa
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
	jr	z, Scoop_CurveUpdate_SegmentEnd_Skip4
	srla l	; srl A,L
Scoop_CurveUpdate_SegmentEnd_Skip4:
	ld	a, l
	sll	a, 2
	extz	wa
	add	wa, wa
	ld	xbc, (xbc+7)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	ld (xsp+0:8), wa
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
	ld bc, qbc
	sll bc, 3
	ld (xsp+0:8), bc
	ld	bc, (xsp+2)
	add	bc, (xwa+6)
	ld	(xsp+6), bc
	ld	wa, (xwa+4)
	sll	wa, 3
	ld bc, (xsp+0:8)
	add bc, wa
	ld	(xsp+4), bc
	lda	xwa, (xsp)
	ldw	bc, 245
	call	DrawBox
	inc	8, xsp
	ret
Scoop_EnvCalc_Handler1:
	lda xsp, (xsp-268)
	ld	xiy, StyleUI_ScreenData_CtlOnly_0x123
	lda	xix, (xsp+260)
	ld	bc, 4:i3
	ldirw
	ld	hl, (xwa+2)
	ld	c, (xwa+1)
	dec	4, c
	ld	e, c
	extz	de
	ld	bc, hl
	extz	xbc
	div	bc, 40
	ld	(xsp+258), bc
	ld	bc, (xsp+258)
	muls	bc, 40
	sub	hl, bc
	sll	hl, 3
	ld	(xsp+256), hl	; ld (XSP+0x0100),HL
	ld	ix, 0:i3
	cp	ix, de
	jr	nc, Scoop_CurveUpdate_SegmentEnd_Skip5
Scoop_CurveUpdate_SegmentEnd_Loop2:
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
	lda	xiy, (StyleUI_ScreenData_CtlOnly_0x23:24)
	ld	c, (xiy+bc)
	ld (xhl), c
	inc 1, ix
	cp ix, de
	jr	c, Scoop_CurveUpdate_SegmentEnd_Loop2
Scoop_CurveUpdate_SegmentEnd_Skip5:
	ld	wa, ix
	extz	xwa
	lda	xbc, (xsp)
	add	xbc, xwa
	ld	(xbc), 0
	lda	xwa, (xsp+260)
	ld	xhl, xwa
	lda xwa, (xsp+256)	; lda XWA,XSP+0x0100
	ld	xbc, xwa
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	xwa, 6:i3
	push	xwa
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	lda	xsp, (xsp+268)
	ret
Scoop_EnvCalc_Handler2:
	dec	8, xsp
	ld	bc, (xwa+2)
	ld	(xsp+4), bc
	ld	bc, (xwa+4)
	ld	(xsp+6), bc
	ld	bc, (xwa+6)
	ld (xsp+0:8), bc
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
	ld bc, qbc
	sll bc, 3
	ld	(xsp+10), bc
	ld	a, (xwa+2)
	ldfr_berp a, 248
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
	lda xsp, (xsp-268)
	pushw iz
	ld hl, (xwa + 2)
	ld c, (xwa + 1)
	dec 4, c
	ld e, c
	extz de
	ld bc, hl
	extz xbc
	div bc, 0x28
	ld	(xsp+260), bc
	ld	bc, (xsp+260)
	muls bc, 0x28
	sub hl, bc
	sll hl, 3
	ld	(xsp+258), hl
	ld ix, 0:i3
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
	lda xiy, (StyleUI_ScreenData_CtlOnly_0x23:24)
	ld	c, (xiy+bc)
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
	decw	2, (xsp+260)
	ld	wa, (xsp+258)
	ld	(xsp+262), wa
	lda xwa, (xsp + 2)
	ld xbc, 0:i3
	call CalcTotalWidth
	ld	wa, (xsp+258)
	add wa, hl
	ld	(xsp+266), wa
	ld	wa, (xsp+260)
	ld	(xsp+264), wa
	ld xwa, 0:i3
	call GetCharDescent
	ld iz, hl
	ld xwa, 0:i3
	call GetCharHeight
	ld	wa, (xsp+260)
	add wa, hl
	sub wa, iz
	ld	(xsp+268), wa
	lda xwa, (xsp+262)
	ld xhl, xwa
	lda xwa, (xsp+258)
	ld xbc, xwa
	lda xwa, (xsp + 2)
	ld xde, xwa
	ld xwa, 0:i3
	push xwa
	pushw 0xff
	pushw 0xf5
	ld xwa, xhl
	call DrawString
	popw iz
	lda xsp, (xsp+268)
	ret

Scoop_GlideParam_Data:
	lda xsp, (xsp-268)
	ld	xiy, StyleUI_ScreenData_CtlOnly_0x12B
	lda	xix, (xsp+260)
	ld	bc, 4:i3
	ldirw
	ld	hl, (xwa+2)
	ld	c, (xwa+1)
	dec	4, c
	ld	e, c
	extz	de
	ld	bc, hl
	extz	xbc
	div	bc, 40
	ld	(xsp+258), bc
	ld	bc, (xsp+258)
	muls	bc, 40
	sub	hl, bc
	sll	hl, 3
	ld	(xsp+256), hl	; ld (XSP+0x0100),HL
	ld	ix, 0:i3
	cp	ix, de
	jr	nc, Scoop_GlideParam_Setup_Skip
Scoop_GlideParam_Setup_Loop:
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
	lda	xiy, (StyleUI_ScreenData_CtlOnly_0x23:24)
	ld	c, (xiy+bc)
	ld (xhl), c
	inc 1, ix
	cp ix, de
	jr	c, Scoop_GlideParam_Setup_Loop
Scoop_GlideParam_Setup_Skip:
	ld	wa, ix
	extz	xwa
	lda	xbc, (xsp)
	add	xbc, xwa
	ld	(xbc), 0
	lda	xwa, (xsp+260)
	ld	xhl, xwa
	lda xwa, (xsp+256)	; lda XWA,XSP+0x0100
	ld	xbc, xwa
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	xwa, 1:i3
	push	xwa
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	lda	xsp, (xsp+268)
	ret
Scoop_GlideCalc_Handler0:
	lda xsp, (xsp-268)
	ld	xiy, StyleUI_ScreenData_CtlOnly_0x133
	lda	xix, (xsp+260)
	ld	bc, 4:i3
	ldirw
	ld	hl, (xwa+2)
	ld	c, (xwa+1)
	dec	4, c
	ld	e, c
	extz	de
	ld	bc, hl
	extz	xbc
	div	bc, 40
	ld	(xsp+258), bc
	ld	bc, (xsp+258)
	muls	bc, 40
	sub	hl, bc
	sll	hl, 3
	ld	(xsp+256), hl	; ld (XSP+0x0100),HL
	ld	ix, 0:i3
	cp	ix, de
	jr	nc, Scoop_GlideParam_Setup_Skip2
Scoop_GlideParam_Setup_Loop2:
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
	jr	c, Scoop_GlideParam_Setup_Loop2
Scoop_GlideParam_Setup_Skip2:
	ld	wa, ix
	extz	xwa
	lda	xbc, (xsp)
	add	xbc, xwa
	ld	(xbc), 0
	lda	xwa, (xsp+260)
	ld	xhl, xwa
	lda xwa, (xsp+256)	; lda XWA,XSP+0x0100
	ld	xbc, xwa
	lda	xwa, (xsp)
	ld	xde, xwa
	ld	xwa, 2:i3
	push	xwa
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	lda	xsp, (xsp+268)
	ret
Scoop_GlideCalc_Handler1:
	dec	8, xsp
	ld	bc, (xwa+2)
	ld (xsp+0:8), bc
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
	ld (xsp+0:8), bc
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
	ld (xsp+0:8), bc
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
	lda xsp, (xsp-150)
	push xiz
	ld	(xsp+150), xbc
	ld xiz, xwa
	ld xiy, StyleUI_ScreenData_CtlOnly_0x13B
	lda xix, (xsp + 6)
	ldw bc, 0x48
	ldirw
	cp	(xsp+150), xiz
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
	lda	xiz, (xiz+wa)
	cp	(xsp+150), xiz
	jr ugt, Scoop_EventLoop_12Entry_Process

Scoop_EventLoop_12Entry_End:
	pop xiz
	lda xsp, (xsp+150:16)
	ret

Scoop_EnvProcessor_Data:
	lda	xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, StyleUI_ScreenData_CtlOnly_0x1CB
	lda	xix, (xsp+264)
	ld	bc, 4:i3
	; llvm-mc cannot spell this byte
	ldirw
	ld	wa, (xiz+2)
	extz	xwa
	ld	e, (xiz+4)
	ld	c, (xiz+5)
	ld	a, (xwa)
	and	a, e
	ld	e, a
	ld	a, c
	and	a, 15
	jr	z, Scoop_EventLoop_12Entry_Skip10	; -> 0xF0218A
	; llvm-mc cannot spell this byte
	srla e	; srl A,E
Scoop_EventLoop_12Entry_Skip10:
	ld	bc, (xiz+7)
	ld	a, (xiz+9)
	ld	l, a
	extz	hl
	ld	wa, bc
	extz	xwa
	div	wa, 40
	ld	(xsp+262), wa
	ld	wa, (xsp+262)
	muls	wa, 40
	sub	bc, wa
	sll	bc, 3
	ld	(xsp+260), bc
	ld	wa, hl
	cp	wa, 2:i3
	jr	z, Scoop_EventLoop_12Entry_Skip	; -> 0xF021D6
	cp	wa, 1:i3
	jr	nz, Scoop_EventLoop_12Entry_Skip2	; -> 0xF021EE
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52426
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_12Entry_Join	; -> 0xF02204
Scoop_EventLoop_12Entry_Skip:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52430
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_12Entry_Join	; -> 0xF02204
Scoop_EventLoop_12Entry_Skip2:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52434
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
Scoop_EventLoop_12Entry_Join:
	ld	a, (xiz+6)
	and	a, 63
	extz	wa
	sla	wa, 2
	lda	xbc, (Scoop_EnvelopeCalc_Data_2:24)
	ld	xix, (xbc+wa)
	lda	xwa, (xsp+264)
	ld	xhl, xwa
	lda	xwa, (xsp+260)
	ld	xbc, xwa
	lda	xwa, (xsp+4)
	ld	xde, xwa
	push	xix
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	pop	xiz
	lda	xsp, (xsp+268)
	ret
	lda	xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, StyleUI_ScreenData_CtlOnly_0x1DF
	lda	xix, (xsp+264)
	ld	bc, 4:i3
	; llvm-mc cannot spell this byte
	ldirw
	ld	wa, (xiz+2)
	extz	xwa
	ld	e, (xiz+4)
	ld	c, (xiz+5)
	ld	a, (xwa)
	and	a, e
	ld	e, a
	ld	a, c
	and	a, 15
	jr	z, Scoop_EventLoop_12Entry_Skip11	; -> 0xF02270
	; llvm-mc cannot spell this byte
	srla e	; srl A,E
Scoop_EventLoop_12Entry_Skip11:
	ld	bc, (xiz+7)
	ld	a, (xiz+9)
	ld	l, a
	extz	hl
	ld	wa, bc
	extz	xwa
	div	wa, 40
	ld	(xsp+262), wa
	ld	wa, (xsp+262)
	muls	wa, 40
	sub	bc, wa
	sll	bc, 3
	ld	(xsp+260), bc
	ld	a, (xiz+10)
	cp	a, e
	jr	z, Scoop_EventLoop_12Entry_Skip7	; -> 0xF02317
	cp	a, 128
	jr	nc, Scoop_EventLoop_12Entry_Skip3	; -> 0xF022B0
	cp	e, 128
	jr	c, Scoop_EventLoop_12Entry_Skip3	; -> 0xF022B0
	ld	a, 128:opc
	sub	e, 128
Scoop_EventLoop_12Entry_Skip3:
	cp	e, a
	jr	ule, Scoop_EventLoop_12Entry_Skip4	; -> 0xF022BC
	ld	(xsp+4), 43
	sub	e, a
	jr	Scoop_EventLoop_12Entry_Join2	; -> 0xF022C4
Scoop_EventLoop_12Entry_Skip4:
	ld	(xsp+4), 45
	sub	a, e
	ld	e, a
Scoop_EventLoop_12Entry_Join2:
	ld	wa, hl
	cp	wa, 2:i3
	jr	z, Scoop_EventLoop_12Entry_Skip5	; -> 0xF022E7
	cp	wa, 1:i3
	jr	nz, Scoop_EventLoop_12Entry_Skip6	; -> 0xF022FF
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52446
	lda	xwa, (xsp+11)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jrl	Scoop_EventLoop_12Entry_Join3	; -> 0xF02369
Scoop_EventLoop_12Entry_Skip5:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52450
	lda	xwa, (xsp+11)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_12Entry_Join3	; -> 0xF02369
Scoop_EventLoop_12Entry_Skip6:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52454
	lda	xwa, (xsp+11)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_12Entry_Join3	; -> 0xF02369
Scoop_EventLoop_12Entry_Skip7:
	ld	e, 0:opc
	ld	wa, hl
	cp	wa, 2:i3
	jr	z, Scoop_EventLoop_12Entry_Skip8	; -> 0xF0233B
	cp	wa, 1:i3
	jr	nz, Scoop_EventLoop_12Entry_Skip9	; -> 0xF02353
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52458
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_12Entry_Join3	; -> 0xF02369
Scoop_EventLoop_12Entry_Skip8:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52462
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_12Entry_Join3	; -> 0xF02369
Scoop_EventLoop_12Entry_Skip9:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52466
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
Scoop_EventLoop_12Entry_Join3:
	ld	a, (xiz+6)
	and	a, 63
	extz	wa
	sla	wa, 2
	lda	xbc, (Scoop_EnvelopeCalc_Data_2:24)
	ld	xix, (xbc+wa)
	lda	xwa, (xsp+264)
	ld	xhl, xwa
	lda	xwa, (xsp+260)
	ld	xbc, xwa
	lda	xwa, (xsp+4)
	ld	xde, xwa
	push	xix
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	pop	xiz
	lda	xsp, (xsp+268)
	ret
Scoop_EventLoop_36Entry:
	lda xsp, (xsp - 0x0114)
	pushw iz
	ld (XSP+0x0112),XWA
	ld XIY,StyleUI_ScreenData_CtlOnly_0x1FF
	lda xix, (xsp + 0x010a)
	ld bc, 4:i3
	ldirw
	ld XWA,(XSP+0x0112)
	ld DE,(XWA+0x02)
	extz XDE
	ld XWA,(XSP+0x0112)
	ld BC,(XWA+0x07)
	ld XWA,(XSP+0x0112)
	ld A,(XWA+0x09)
	ld L,A
	extz HL
	ld WA,BC
	extz XWA
	div WA,0x0028
	ld (XSP+0x0108),WA
	ld WA,(XSP+0x0108)
	muls WA,0x0028
	sub BC,WA
	sll BC, 0x03
	ld (XSP+0x0106),BC
	decm	2, (xsp+264)
	ld	wa, hl
	cp	wa, 2:i3
	jr	z, Scoop_EventLoop_36Entry_Branch1
	cp	wa, 1:i3
	jr	nz, Scoop_EventLoop_36Entry_Branch2
	pushm	(xde)
	pushw	224
	pushw	52478
	lda	xwa, (xsp+12)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Branch3
Scoop_EventLoop_36Entry_Branch1:
	pushm	(xde)
	pushw	224
	pushw	52482
	lda	xwa, (xsp+12)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Branch3
Scoop_EventLoop_36Entry_Branch2:
	pushm (xde)

	pushw 0xe0

	pushw 0xcd06

	lda xwa, (xsp + 12)

	push xwa

	call Scoop_EventLoop_12Entry_Helper

	lda xsp, (xsp + 10)



Scoop_EventLoop_36Entry_Branch3:
	ld XWA, (xsp + 0x0112)
	ld a, (xwa + 6)
	and a, 0x3f
	extz wa
	sla wa, 2
	lda xbc, (Scoop_EnvelopeCalc_Data_2:24)
	ld	xwa, (xbc+wa)
	ld (xsp + 2), xwa
	ld	wa, (xsp+262)
	ld	(xsp+266), wa
	lda xwa, (xsp + 6)
	ld xbc, (xsp + 2)
	call CalcTotalWidth
	ld	wa, (xsp+262)
	add wa, hl
	ld	(xsp+270), wa
	ld	wa, (xsp+264)
	inc 2, wa
	ld	(xsp+268), wa
	ld xwa, (xsp + 2)
	call GetCharDescent
	ld iz, hl
	ld xwa, (xsp + 2)
	call GetCharHeight
	ld	wa, (xsp+264)
	add wa, hl
	sub wa, iz
	ld	(xsp+272), wa
	lda xwa, (xsp+266)
	ld xhl, xwa
	lda xwa, (xsp+262)
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
	lda xsp, (xsp+276)
	ret

Scoop_EventLoop_36Entry_Data:
	lda	xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, StyleUI_ScreenData_CtlOnly_0x213
	lda	xix, (xsp+264)
	ld	bc, 4:i3
	ldirw
	ld	wa, (xiz+2)
	extz	xwa
	ld	e, (xiz+4)
	ld	c, (xiz+5)
	ld	a, (xwa)
	and	a, e
	ld	e, a
	ld	a, c
	and	a, 15
	jr	z, Scoop_EventLoop_36Entry_Branch1_Code_Skip
	srla e	; srl A,E
Scoop_EventLoop_36Entry_Branch1_Code_Skip:
	ld	c, (xiz+11)
	ld	wa, (xiz+7)
	ld	(xsp+260), wa
	ld	wa, (xiz+9)
	ld	(xsp+262), wa
	ld	a, c
	cp	a, 2:i3
	jr	z, Scoop_EventLoop_36Entry_Branch1_Code_Skip2
	cp	a, 1:i3
	jr	nz, Scoop_EventLoop_36Entry_Branch1_Code_Skip3
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52498
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Branch1_Code_Join
Scoop_EventLoop_36Entry_Branch1_Code_Skip2:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52502
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Branch1_Code_Join
Scoop_EventLoop_36Entry_Branch1_Code_Skip3:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52506
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
Scoop_EventLoop_36Entry_Branch1_Code_Join:
	ld	a, (xiz+6)
	and	a, 15
	extz	wa
	sla	wa, 2
	lda	xbc, (Scoop_EventLoop_36Entry_Branch3_Data_3:24)
	ld	xix, (xbc+wa)
	lda	xwa, (xsp+264)
	ld	xhl, xwa
	lda	xwa, (xsp+260)
	ld	xbc, xwa
	lda	xwa, (xsp+4)
	ld	xde, xwa
	push	xix
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	pop	xiz
	lda	xsp, (xsp+268)
	ret
	lda	xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, GUI_FormatStrings
	lda	xix, (xsp+264)
	ld	bc, 4:i3
	ldirw
	ld	wa, (xiz+2)
	extz	xwa
	ld	e, (xiz+4)
	ld	c, (xiz+5)
	ld	a, (xwa)
	and	a, e
	ld	e, a
	ld	a, c
	and	a, 15
	jr	z, Scoop_EventLoop_36Entry_Branch1_Code_Skip4
	srla e	; srl A,E
Scoop_EventLoop_36Entry_Branch1_Code_Skip4:
	ld	c, (xiz+11)
	ld	wa, (xiz+7)
	ld	(xsp+260), wa
	ld	wa, (xiz+9)
	ld	(xsp+262), wa
	ld	a, (xiz+12)
	cp	a, e
	jr	z, Scoop_EventLoop_36Entry_Branch1_Code_Skip9
	cp	a, 128
	jr	nc, Scoop_EventLoop_36Entry_Branch1_Code_Skip5
	cp	e, 128
	jr	c, Scoop_EventLoop_36Entry_Branch1_Code_Skip5
	ld	a, 128:opc
	sub	e, 128
Scoop_EventLoop_36Entry_Branch1_Code_Skip5:
	cp	e, a
	jr	ule, Scoop_EventLoop_36Entry_Branch1_Code_Skip6
	ld	(xsp+4), 43
	sub	e, a
	jr	Scoop_EventLoop_36Entry_Branch1_Code_Join2
Scoop_EventLoop_36Entry_Branch1_Code_Skip6:
	ld	(xsp+4), 45
	sub	a, e
	ld	e, a
Scoop_EventLoop_36Entry_Branch1_Code_Join2:
	ld	a, c
	cp	a, 2:i3
	jr	z, Scoop_EventLoop_36Entry_Branch1_Code_Skip7
	cp	a, 1:i3
	jr	nz, Scoop_EventLoop_36Entry_Branch1_Code_Skip8
	ld	a, e
	extz	wa
	pushw	wa
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt1d@hi16
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt1d@lo16
	lda	xwa, (xsp+11)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jrl	Scoop_EventLoop_36Entry_Branch1_Code_Join3
Scoop_EventLoop_36Entry_Branch1_Code_Skip7:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt2d@hi16
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt2d@lo16
	lda	xwa, (xsp+11)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Branch1_Code_Join3
Scoop_EventLoop_36Entry_Branch1_Code_Skip8:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt3d@hi16
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt3d@lo16
	lda	xwa, (xsp+11)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Branch1_Code_Join3
Scoop_EventLoop_36Entry_Branch1_Code_Skip9:
	ld	e, 0:opc
	ld	a, c
	cp	a, 2:i3
	jr	z, Scoop_EventLoop_36Entry_Branch1_Code_Skip10
	cp	a, 1:i3
	jr	nz, Scoop_EventLoop_36Entry_Branch1_Code_Skip11
	ld	a, e
	extz	wa
	pushw	wa
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt2d_2@hi16
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt2d_2@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Branch1_Code_Join3
Scoop_EventLoop_36Entry_Branch1_Code_Skip10:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt3d_3@hi16
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt3d_3@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Branch1_Code_Join3
Scoop_EventLoop_36Entry_Branch1_Code_Skip11:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt4d@hi16
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt4d@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
Scoop_EventLoop_36Entry_Branch1_Code_Join3:
	ld	a, (xiz+6)
	and	a, 15
	extz	wa
	sla	wa, 2
	lda	xbc, (Scoop_EventLoop_36Entry_Branch3_Data_3:24)
	ld	xix, (xbc+wa)
	lda	xwa, (xsp+264)
	ld	xhl, xwa
	lda	xwa, (xsp+260)
	ld	xbc, xwa
	lda	xwa, (xsp+4)
	ld	xde, xwa
	push	xix
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	pop	xiz
	lda	xsp, (xsp+268)
	ret
	lda	xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, Scoop_EventLoop_36Entry_Branch3_Data
	lda	xix, (xsp+264)
	ld	bc, 4:i3
	ldirw
	ld	bc, (xiz+2)
	extz	xbc
	ld	e, (xiz+11)
	ld	wa, (xiz+7)
	ld	(xsp+260), wa
	ld	wa, (xiz+9)
	ld	(xsp+262), wa
	ld	a, e
	cp	a, 2:i3
	jr	z, Scoop_EventLoop_36Entry_Branch1_Code_Skip12
	cp	a, 1:i3
	jr	nz, Scoop_EventLoop_36Entry_Branch1_Code_Skip13
	pushm	(xbc)
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt1d_2@hi16
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt1d_2@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Branch1_Code_Join4
Scoop_EventLoop_36Entry_Branch1_Code_Skip12:
	pushm	(xbc)
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt2d_3@hi16
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt2d_3@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Branch1_Code_Join4
Scoop_EventLoop_36Entry_Branch1_Code_Skip13:
	pushm	(xbc)
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt3d_2@hi16
	pushw	Scoop_EventLoop_36Entry_Branch3_Str_Fmt3d_2@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
Scoop_EventLoop_36Entry_Branch1_Code_Join4:
	ld	a, (xiz+6)
	and	a, 15
	extz	wa
	sla	wa, 2
	lda	xbc, (Scoop_EventLoop_36Entry_Branch3_Data_3:24)
	ld	xix, (xbc+wa)
	lda	xwa, (xsp+264)
	ld	xhl, xwa
	lda	xwa, (xsp+260)
	ld	xbc, xwa
	lda	xwa, (xsp+4)
	ld	xde, xwa
	push	xix
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	pop	xiz
	lda	xsp, (xsp+268)
	ret
	lda	xsp, (xsp-270)
	push	xiz
	ld	xde, xwa
	ld	xiy, Scoop_EventLoop_36Entry_Branch3_Data_2
	lda	xix, (xsp+266)
	ld	bc, 4:i3
	ldirw
	ld	iz, (xde+2)
	extz	xiz
	ld	l, (xde+4)
	ld	c, (xde+5)
	ld	a, (xiz)
	and	a, l
	ld	(xsp+4), a
	ld	a, c
	ld	c, (xsp+4)
	and	a, 15
	jr	z, Scoop_EventLoop_36Entry_Branch1_Code_Skip14
	srla c	; srl A,C
Scoop_EventLoop_36Entry_Branch1_Code_Skip14:
	ld	(xsp+4), c
	ld	wa, (xde+13)
	ld	(xsp+262), wa
	ld	wa, (xde+15)
	ld	(xsp+264), wa
	ld	iy, (xde+11)
	ld	ix, 0:i3
	cp	ix, iy
	jr	nc, Scoop_EventLoop_36Entry_Branch1_Code_Skip15
Scoop_EventLoop_36Entry_Branch1_Code_Loop:
	ld	xiz, (xde+7)
	ld	wa, ix
	extz	xwa
	lda	xhl, (xsp+6)
	add	xhl, xwa
	ld	a, (xsp+4)
	extz	wa
	mul	xwa, iy
	ld	bc, ix
	extz	xbc
	add	xbc, xwa
	add	xbc, xiz
	ld	a, (xbc)
	ld	(xhl), a
	inc	1, ix
	cp	ix, iy
	jr	c, Scoop_EventLoop_36Entry_Branch1_Code_Loop
Scoop_EventLoop_36Entry_Branch1_Code_Skip15:
	ld	wa, ix
	extz	xwa
	lda	xbc, (xsp+6)
	add	xbc, xwa
	ld	(xbc), 0
	ld	a, (xde+6)
	and	a, 15
	extz	wa
	sla	wa, 2
	lda	xbc, (Scoop_EventLoop_36Entry_Branch3_Data_3:24)
	ld	xix, (xbc+wa)
	lda	xwa, (xsp+266)
	ld	xhl, xwa
	lda	xwa, (xsp+262)
	ld	xbc, xwa
	lda	xwa, (xsp+6)
	ld	xde, xwa
	push	xix
	pushw	255
	pushw	245
	ld	xwa, xhl
	call	DrawString
	pop	xiz
	lda	xsp, (xsp+270)
	ret
Scoop_EventLoop_12Entry_Alt:
	lda xsp, (xsp - 54)
	push xiz
	ld (xsp + 54), xbc
	ld xiz, xwa
	ld xiy, Scoop_EventLoop_12Entry_Alt_Data
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
	lda	xiz, (xiz+wa)
	cp (xsp + 54), xiz
	jr ugt, Scoop_EventLoop_12Entry_Alt_Process

Scoop_EventLoop_12Entry_Alt_End:
	pop xiz
	lda xsp, (xsp + 54)
	ret

.macro RegObjTable ParamA, ParamB, ParamC, ParamD, ParamE
	mri_d2 0xb7, 0x31
	.if \ParamA <= 7
	ld xwa, \ParamA:i3
	.else
	ld xwa, \ParamA
	.endif
	ld (xbc), xwa
	lda xwa, (\ParamB:24)
	ld (xbc + 4), xwa
	ld wa, (\ParamC:24)	; was `ldw_da xwa, ...`: d2 nn nn nn 20 loads WA, not XWA
	ld (xbc + 8), wa
	lda xwa, (\ParamD:24)
	ld (xbc + 10), xwa
	.if \ParamE <= 7
	ld wa, \ParamE:i3
	.else
	ldw wa, \ParamE
	.endif
	call RegisterObjectTable
.endm


.macro RegObjTabl ParamA, ParamB, ParamC, ParamD, ParamE
	mri_d2 0xb7, 0x31
	.if \ParamA <= 7
	ld xwa, \ParamA:i3
	.else
	ld xwa, \ParamA
	.endif
	ld (xbc), xwa
	lda xwa, (\ParamB:24)
	ld (xbc + 4), xwa
	ldw (xbc + 8), \ParamC
	lda xwa, (\ParamD:24)
	ld (xbc + 10), xwa
	.if \ParamE <= 7
	ld wa, \ParamE:i3
	.else
	ldw wa, \ParamE
	.endif
	call RegisterObjectTable
.endm


; The far pointer is ONE address (TOOLCHAIN_VERSION UPDATE 20: `@hi16`/`@lo16`);
; the compiled call pushes ParamA, then its high and low halves.
.macro RegMode ParamA, ParamB, ParamC, ParamD, ParamE
	pushw \ParamA
	pushw \ParamB\()@hi16
	pushw \ParamB\()@lo16
	.if \ParamC <= 7
	ld xwa, \ParamC:i3
	.else
	ld xwa, \ParamC
	.endif
	.if \ParamD <= 7
	ld xbc, \ParamD:i3
	.else
	ld xbc, \ParamD
	.endif
	.if \ParamE <= 7
	ld xde, \ParamE:i3
	.else
	ld xde, \ParamE
	.endif
	call RegisterMode
.endm


; The far pointer is ONE address (TOOLCHAIN_VERSION UPDATE 20: `@hi16`/`@lo16`);
; the compiled call pushes ParamA, then its high and low halves.
.macro RegTitle ParamA, ParamB, ParamC, ParamD, ParamE
	pushw \ParamA
	pushw \ParamB\()@hi16
	pushw \ParamB\()@lo16
	.if \ParamC <= 7
	ld xwa, \ParamC:i3
	.else
	ld xwa, \ParamC
	.endif
	.if \ParamD <= 7
	ld xbc, \ParamD:i3
	.else
	ld xbc, \ParamD
	.endif
	.if \ParamE <= 7
	ld xde, \ParamE:i3
	.else
	ld xde, \ParamE
	.endif
	call RegisterTitle
.endm


InitializeScoop:
	lda xsp, (xsp - 14)

	RegObjTable NAKA_CLASS_Class, ClassProc, 0xe0cdac, 0xe0cd94, 0x166
	RegObjTable NAKA_CLASS_ResEvent, ResEventProc, 0xe0cdb2, Scoop_ResEventTable_1C6, 0x1c6
	RegObjTable NAKA_CLASS_ResMethod, ResMethodProc, 0xe0cdb8, 0xe0cdb4, 0x1e6
	RegObjTabl NAKA_CLASS_ApFunction, ApFunctionProc, 0x0, 0xe0cd8a, 0x126
	RegObjTabl NAKA_CLASS_ApFunction, ApFunctionProc, 0x0, Scoop_ApFunctionTable_426, 0x426
	RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x0, 0xe0cdba, 0x106
	RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x0, Scoop_FunctionTable_406, 0x406
	RegObjTabl NAKA_CLASS_MainFunction, MainFunctionProc, 0x21, GUI_DisplayStructData_0x750, 0x146
	RegObjTabl NAKA_CLASS_MainFunction, MainFunctionProc, 0x21, GUI_DisplayStructData_0x7D8, 0x446
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, GUI_DisplayStructData_0x226, 0x20
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, GUI_DisplayStructData_0x326, 0x320
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_021, 0x21
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_321, 0x321
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_022, 0x22
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_322, 0x322
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_023, 0x23
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_323, 0x323
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_024, 0x24
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_324, 0x324
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_025, 0x25
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_325, 0x325
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_026, 0x26
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_326, 0x326
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_027, 0x27
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_327, 0x327
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_028, 0x28
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_328, 0x328
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_029, 0x29
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_329, 0x329
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_02A, 0x2a
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_32A, 0x32a
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_02B, 0x2b
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_32B, 0x32b
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_02C, 0x2c
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_32C, 0x32c
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_02D, 0x2d
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_32D, 0x32d
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_02E, 0x2e
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_32E, 0x32e
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_02F, 0x2f
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_32F, 0x32f
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_030, 0x30
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_330, 0x330
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_031, 0x31
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_331, 0x331
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_032, 0x32
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_332, 0x332
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_033, 0x33
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_333, 0x333
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_034, 0x34
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_334, 0x334
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_035, 0x35
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_335, 0x335
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_036, 0x36
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_336, 0x336
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_037, 0x37
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_337, 0x337
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_038, 0x38
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_338, 0x338
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_039, 0x39
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_339, 0x339
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_03A, 0x3a
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_33A, 0x33a
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_03B, 0x3b
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_33B, 0x33b
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_03C, 0x3c
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_33C, 0x33c
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_03D, 0x3d
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_33D, 0x33d
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_03E, 0x3e
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_33E, 0x33e
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Scoop_ViewableTable_03F, 0x3f
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Scoop_ResNameTable_33F, 0x33f

	RegMode 0x6, GUI_DisplayStructData_0x59C, 0x3, NAKA_MAINFUNC_SeMenuModeFunc, TITLE_SEMENU

	RegTitle 0x6, InitializeScoop_Str_TT_SEMENU, 0x20, NAKA_MAINFUNC_SeMenuTitleFunc, 0x200000
	RegTitle 0x6, InitializeScoop_Str_TT_SEEASY, 0x21, NAKA_MAINFUNC_SeEasyTitleFunc, 0x210000
	RegTitle 0x6, InitializeScoop_Str_TT_SETONTON1, 0x22, NAKA_MAINFUNC_SeTonTon1TitleFunc, 0x220000
	RegTitle 0x6, InitializeScoop_Str_TT_SETONTON2, 0x23, NAKA_MAINFUNC_SeTonTon2TitleFunc, 0x230000
	RegTitle 0x6, InitializeScoop_Str_TT_SETONRAN1, 0x24, NAKA_MAINFUNC_SeTonRan1TitleFunc, 0x240000
	RegTitle 0x6, InitializeScoop_Str_TT_SETONRAN2, 0x25, NAKA_MAINFUNC_SeTonRan2TitleFunc, 0x250000
	RegTitle 0x6, InitializeScoop_Str_TT_SETONHYB1, 0x26, NAKA_MAINFUNC_SeTonHyb1TitleFunc, 0x260000
	RegTitle 0x6, InitializeScoop_Str_TT_SEPITPIT1, 0x27, NAKA_MAINFUNC_SePitPit1TitleFunc, 0x270000
	RegTitle 0x6, InitializeScoop_Str_TT_SEPITENV1, 0x28, NAKA_MAINFUNC_SePitEnv1TitleFunc, 0x280000
	RegTitle 0x6, InitializeScoop_Str_TT_SEPITENV2, 0x29, NAKA_MAINFUNC_SePitEnv2TitleFunc, 0x290000
	RegTitle 0x6, InitializeScoop_Str_TT_SEPITLFO1, 0x2a, NAKA_MAINFUNC_SePitLfo1TitleFunc, 0x2a0000
	RegTitle 0x6, InitializeScoop_Str_TT_SEAMPAMP1, 0x2b, NAKA_MAINFUNC_SeAmpAmp1TitleFunc, 0x2b0000
	RegTitle 0x6, InitializeScoop_Str_TT_SEAMPAMP2, 0x2c, NAKA_MAINFUNC_SeAmpAmp2TitleFunc, 0x2c0000
	RegTitle 0x6, InitializeScoop_Str_TT_SEAMPENV1, 0x2d, NAKA_MAINFUNC_SeAmpEnv1TitleFunc, 0x2d0000
	RegTitle 0x6, InitializeScoop_Str_TT_SEAMPENV2, 0x2e, NAKA_MAINFUNC_SeAmpEnv2TitleFunc, 0x2e0000
	RegTitle 0x6, InitializeScoop_Str_TT_SEAMPLFO1, 0x2f, NAKA_MAINFUNC_SeAmpLfo1TitleFunc, 0x2f0000
	RegTitle 0x6, InitializeScoop_Str_TT_SEFILLPQ1, 0x30, NAKA_MAINFUNC_SeFilLpq1TitleFunc, 0x300000
	RegTitle 0x6, InitializeScoop_Str_TT_SEFILHPQ1, 0x31, NAKA_MAINFUNC_SeFilHpq1TitleFunc, 0x310000
	RegTitle 0x6, InitializeScoop_Str_TT_SEFILL241, 0x32, NAKA_MAINFUNC_SeFilL241TitleFunc, 0x320000
	RegTitle 0x6, InitializeScoop_Str_TT_SEFILH241, 0x33, NAKA_MAINFUNC_SeFilH241TitleFunc, 0x330000
	RegTitle 0x6, InitializeScoop_Str_TT_SEFILBPF1, 0x34, NAKA_MAINFUNC_SeFilBpf1TitleFunc, 0x340000
	RegTitle 0x6, InitializeScoop_Str_TT_SEFILBCF1, 0x35, NAKA_MAINFUNC_SeFilBcf1TitleFunc, 0x350000
	RegTitle 0x6, InitializeScoop_Str_TT_SEFILFIL2, 0x36, NAKA_MAINFUNC_SeFilFil2TitleFunc, 0x360000
	RegTitle 0x6, InitializeScoop_Str_TT_SEFILENV1, 0x37, NAKA_MAINFUNC_SeFilEnv1TitleFunc, 0x370000
	RegTitle 0x6, InitializeScoop_Str_TT_SEFILENV2, 0x38, NAKA_MAINFUNC_SeFilEnv2TitleFunc, 0x380000
	RegTitle 0x6, InitializeScoop_Str_TT_SEFILLFO1, 0x39, NAKA_MAINFUNC_SeFilLfo1TitleFunc, 0x390000
	RegTitle 0x6, InitializeScoop_Str_TT_SEDIGEFF, 0x3a, NAKA_MAINFUNC_SeDigEffTitleFunc, 0x3a0000
	RegTitle 0x6, InitializeScoop_Str_TT_SECTR2, 0x3b, NAKA_MAINFUNC_SeCtr2TitleFunc, 0x3b0000
	RegTitle 0x6, InitializeScoop_Str_TT_SECTR3, 0x3c, NAKA_MAINFUNC_SeCtr3TitleFunc, 0x3c0000
	RegTitle 0x6, InitializeScoop_Str_TT_SECOPY, 0x3d, NAKA_MAINFUNC_SeCopyTitleFunc, 0x3d0000
	RegTitle 0x6, InitializeScoop_Str_TT_SEWRTMEM, 0x3e, NAKA_MAINFUNC_SeWrtMemTitleFunc, 0x3e0000
	RegTitle 0x6, InitializeScoop_Str_TT_SEWRTSND, 0x3f, NAKA_MAINFUNC_SeWrtSndTitleFunc, 0x3f0000

	lda xsp, (xsp + 14)
	ret


; Sound Editor mode and title routines
	.include "audio/sound_editor_routines.s"
