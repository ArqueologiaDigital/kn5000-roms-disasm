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

	; Byte data, 129 B.  Read by UIRender_LoadTwoDescriptors (0xEF5DA3): `ld xiy, UIRender_DescriptorTable1`
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
	bitda	1, (0x1185)
	jr	nz, UIRender_DescriptorTable2_Return
	ldw_d16	wa, (0x1182)
	stda16	(0x1181), wa
	ld	(4483:16), 32
	bitda	0, (0x1185)
	jr	nz, UIRender_DescriptorTable2_Return
	ldw_d16	wa, (0x1182)
	stda16	(0x1181), wa
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
	ldb_sri A, 0x07, 0xec, 0xf4
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
	call ScoopParam_ValueTable_0x186
	ret
Display_ConditionalCompare:
	; --- Conditional handler: call EF6047, compare mem, ret ---
	call Display_CallMenuConfig
	ld	a, (0x8d36:16)
	cp	a, (0x8d37:16)
	jr z, Display_ConditionalCompare_Ret
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
	ld xbc, 0x01c00007
	ld	xwa, 0:i3
	call DeleteEvent
	ret
Display_CallSetupRoutine:
	; --- Simple wrapper: call EF61E9 ---
	call DefaultHandler_Ret_0x1
	ret
Display_NullHandler:
	ret


MIDI_SendSysExFromW:
	ld a, w
	call MIDI_SendSysExCmd
	ret

SoundEvt_ShortPacketHandler:
	ld	(3923:16), 0
	ordi8	(0xe3e2), 8
	ld	w, 1:opc
	call	SoundEvt_LongPacketHandler_0x11
	ret
SoundEvt_LongPacketHandler:
	ld	(3923:16), 0
	ordi8	(0xe3e2), 8
	ld	w, 2:opc
	call	SoundEvt_LongPacketHandler_0x11
	ret
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, SoundEvt_LongPacketHandler_Return
	ld	l, (3429:16)
	and	l, 3
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, SoundEvt_LongPacketHandler_DispatchTbl
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
SoundEvt_LongPacketHandler_Return:
	ret
	; Handler dispatch table, 16 B.  Read by SoundEvt_LongPacketHandler (0xEF609D): `ld xix, SoundEvt_LongPacketHandler_DispatchTbl`
	; indexed with stride 4 (`sla hl, 2`), index from `ld l, (3429:16)`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
SoundEvt_LongPacketHandler_DispatchTbl:
	.long	DefaultHandler_Ret
	.long	SoundEvt_LongPacketHandler_DispatchTbl_Target1
	.long	SoundEvt_LongPacketHandler_DispatchTbl_Target2
	.long	DefaultHandler_Ret
	; Entry 1 of SoundEvt_LongPacketHandler_DispatchTbl (a code pointer the table holds).
SoundEvt_LongPacketHandler_DispatchTbl_Target1:
	and	w, 3
	ld	(3925:16), w
	ex8	a, w
	exts	wa
	sla	wa, 2
	ld	iy, wa
	ld	wa, (0x371a:16)
	ld	(3816:16), wa
	ld	a, (3420:16)
	ld	(3821:16), a
	push	xhl
	ld	xhl, ScoopDisp_HandlerData2
	ld_rrl	xiy, xhl, iy
	pop	xhl
	call	(xiy)
	ld	wa, (0x371a:16)
	cp wa, (3816:16)
	jrl	nz, SoundEvt_LongPacketHandler_Loop
	ld	a, (3420:16)
	ld	w, (3821:16)
	cp	a, w
	jrl	z, SoundEvt_LongPacketHandler_Skip2
	cpdi8	(0x0d5d), 4
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEF612D-0xEF6143 (22 B), unreached CODE-territory, was disassembled as 8 plausible-but-dead instruction lines; per=67% dist=14 near SoundEvt_LongPacketHandler_0x35+91
	jrl	ule, SoundEvt_LongPacketHandler_0xA6
	cp	w, 3:i3
	jrl	ugt, SoundEvt_LongPacketHandler_Skip
	cp	a, 3:i3
	jrl	ugt, SoundEvt_LongPacketHandler_Loop
	jp	SoundEvt_LongPacketHandler_0xA6
SoundEvt_LongPacketHandler_Skip:
	cp	a, 3:i3
	jrl	ule, SoundEvt_LongPacketHandler_Loop
SoundEvt_LongPacketHandler_Skip2:
	call	VoiceState_DataBlock2_0x472
	jp	SoundEvt_LongPacketHandler_0xB7
SoundEvt_LongPacketHandler_Loop:
	ordi8	(0x0dd3), 1
	call	VoiceSlot_TableSetup
	call	Timer_ModeHandler_0_0x107
	ret
	; Handler dispatch table, 16 B.  Read by SoundEvt_LongPacketHandler_DispatchTbl_Target1 (0xEF60E2): `ld xhl, ScoopDisp_HandlerData2`
	; indexed with stride 4 (`sla wa, 2`), index from `ld a, (3420:16)`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
ScoopDisp_HandlerData2:
	.long	VoiceCtrl_SendNoteOffSequence
	.long	Timer_ParamCompareAlt
	.long	Timer_ParamLoadAndCompare
	.long	DefaultHandler_Ret
	; Entry 2 of SoundEvt_LongPacketHandler_DispatchTbl (a code pointer the table holds).
SoundEvt_LongPacketHandler_DispatchTbl_Target2:
	and	w, 3
	ex8	a, w
	exts	wa
	sla	wa, 2
	ld	iy, wa
	ld	wa, (0x371a:16)
	ld	(3816:16), wa
	ld	a, (3420:16)
	ld	(3821:16), a
	push	xhl
	ld	xhl, SoundEvt_LongPacketHandler_DispatchTbl2
	ld_rrl xiy, xhl, iy
	pop xhl
	call	(xiy)
	ld	wa, (0x371a:16)
	cp wa, (3816:16)
	jrl	nz, SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip3
	ld	a, (3420:16)
	ld	w, (3821:16)
	cp	a, w
	jrl	z, SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip2
	cpdi8	(0x0d5d), 4
	jrl	ule, SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip2
	cp	w, 3:i3
	jrl	ugt, SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip
	cp	a, 3:i3
	jrl	ugt, SoundEvt_LongPacketHandler_Loop
	jp	ScoopDisp_HandlerData2_0x6D
SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip:
	cp	a, 3:i3
	jrl	ule, SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip3
SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip2:
	call	VoiceState_DataBlock2_0x472
	jp	ScoopDisp_HandlerData2_0x7E
SoundEvt_LongPacketHandler_DispatchTbl_Target2_Skip3:
	ordi8	(0x0dd3), 1
	call	VoiceSlot_TableSetup
	ret
	; Handler dispatch table, 16 B.  Read by SoundEvt_LongPacketHandler_DispatchTbl_Target2 (0xEF6169): `ld xhl, SoundEvt_LongPacketHandler_DispatchTbl2`
	; indexed with stride 4 (`sla wa, 2`), index from `ld a, (3420:16)`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
SoundEvt_LongPacketHandler_DispatchTbl2:
	.long	DefaultHandler_Ret
	.long	Timer_ParamCompareAlt
	.long	Timer_ParamLoadAndCompare
	.long	DefaultHandler_Ret
; ============================================================================
; DefaultHandler_Ret - Null handler stub (immediate return)
; ============================================================================
; Returns immediately. Used as placeholder in 396+ jump table entries where
; no specific handler is assigned. The default "do nothing" dispatch target.
; ============================================================================
DefaultHandler_Ret:
	ret
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, DefaultHandler_Ret_Return2
	ld	e, (3429:16)
	and	e, 3
	xor	d, d
	sla	de, 2
	ld	iy, de
	ld	(9920:16), bc
	push	xhl
	ld	xhl, DefaultHandler_Ret_DispatchTbl
	ld_rrl xiy, xhl, iy
	pop xhl
	call	(xiy)
DefaultHandler_Ret_Return2:
	ret
	; Handler dispatch table, 16 B.  Read by DefaultHandler_Ret (0xEF61E8): `ld xhl, DefaultHandler_Ret_DispatchTbl`
	; indexed with stride 4 (`sla de, 2`)
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
DefaultHandler_Ret_DispatchTbl:
	.long	DefaultHandler_Ret_DispatchTbl_Target0
	.long	DefaultHandler_Ret_DispatchTbl_Target1
	.long	DefaultHandler_Ret_DispatchTbl_Target1
	.long	DefaultHandler_Ret_DispatchTbl_Target3
	; Entry 0 of DefaultHandler_Ret_DispatchTbl (a code pointer the table holds).
DefaultHandler_Ret_DispatchTbl_Target0:
	cpdi8	(0x28be), 255
	jrl	nz, DefaultHandler_Ret_Skip4
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, DefaultHandler_Ret_Return
	cpdi8	(0x0def), 18
	jrl	nz, DefaultHandler_Ret_Skip3
	cp	hl, 9
	jrl	z, DefaultHandler_Ret_Skip
	cp	hl, 10
	jrl	z, DefaultHandler_Ret_Skip2
	jp	DefaultHandler_Ret_0xA6
DefaultHandler_Ret_Skip:
	bit	7, w
	jrl	nz, DefaultHandler_Ret_Return
	call	ScoopDisp_DispatchTable_Extended_0x3E
	jp	DefaultHandler_Ret_0xA6
DefaultHandler_Ret_Skip2:
	bit	7, w
	jrl	nz, DefaultHandler_Ret_Return
	call	ScoopDisp_DispatchTable_Extended_0x79
	jp	DefaultHandler_Ret_0xA6
DefaultHandler_Ret_Skip3:
	sla	hl, 2
	push	xix
	ld	xix, ScoopDisp_DispatchTable_Small
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
	jp	DefaultHandler_Ret_0xA6
DefaultHandler_Ret_Skip4:
	cp	bc, 15
	jrl	nz, DefaultHandler_Ret_Return
	call	ToneParam_Evt0F_BytecodeHandler
	jp	DefaultHandler_Ret_0xA6
DefaultHandler_Ret_Return:
	ret
ScoopDisp_FlagSetAndDispatch:
	ordi8	(0xe3e2), 8
	bit	7, w
	jrl	z, ScoopDisp_FlagSetAndDispatch_Skip
	call	MemConfig_Handler_1_0x13E
	jp	ScoopDisp_FlagSetAndDispatch_0x17
ScoopDisp_FlagSetAndDispatch_Skip:
	call	MemConfig_Handler_1_0x1EF
	ret
ScoopDisp_DispatchTable_Small:
	; ScoopDisp_DispatchTable_Small -- 32 handler pointers, index scaled by 4.
	; INDEXING RULE, from the only site that loads it (this file, ~40 lines above):
	;     sla hl, 2 / push xix / ld xix, ScoopDisp_DispatchTable_Small
	;     ld_rrl xhl, xix, hl / pop xix / call (xhl)
	; The table was already typed except its LAST entry, which the old sweep read
	; as `inc 1, xwa / .byte 0xef / nop`. 32 entries reach exactly the next label.
	.long ScoopDisp_FlagSetAndDispatch
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
	.long ScoopDisp_DispatchTable_Extended_0x20
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long ScoopDisp_FlagSetAndDispatch
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
ToneParam_Evt0F_BytecodeHandler:
	bit	7, w
	jrl	nz, ToneParam_Evt0F_BytecodeHandler_Return
	anddi8	(0x266a), 254
	xor	wa, wa
	ld	a, 137:opc
	call	UI_PostModeChangeEvent
	jp	ToneParam_Evt0F_BytecodeHandler_0x17
ToneParam_Evt0F_BytecodeHandler_Return:
	ret
	; Entry 1 of DefaultHandler_Ret_DispatchTbl (a code pointer the table holds).
DefaultHandler_Ret_DispatchTbl_Target1:
	anddi8	(0x0dd3), 254
	ld	e, (3567:16)
	xor	d, d
	sla	de, 2
	ld	iy, de
	push	xhl
	ld	xhl, PerfMode_ParamHandler_Table
	ld_rrl xiy, xhl, iy
	pop xhl
	call	(xiy)
	ordi8	(0x0dd3), 1
	ld	bc, (9920:16)
	cp	bc, 15
	jrl	z, ToneParam_Evt0F_BytecodeHandler_Return2
	cp	bc, 0:i3
	jrl	z, ToneParam_Evt0F_BytecodeHandler_Skip
	anddi8	(0x0f57), 254
ToneParam_Evt0F_BytecodeHandler_Skip:
	bitda	0, (0x0f57)
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
	jp	ToneParam_Evt0F_BytecodeHandler_0x8D
ToneParam_Evt0F_BytecodeHandler_Skip5:
	anddi8	(0x0dd3), 254
ToneParam_Evt0F_BytecodeHandler_Skip6:
	call	VoiceSlot_TableSetup
	call	Timer_ModeHandler_0_0x13
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
	; Entry 3 of DefaultHandler_Ret_DispatchTbl (a code pointer the table holds).
DefaultHandler_Ret_DispatchTbl_Target3:
	ld	e, (3567:16)
	xor	d, d
	sla	de, 2
	ld	iy, de
	push	xhl
	ld	xhl, PerfMode_JumpTable_Extended
	ld_rrl	xiy, xhl, iy
	pop	xhl
	call	(xiy)
	ret
	; Handler dispatch table, 76 B.  Read by DefaultHandler_Ret_DispatchTbl_Target3 (0xEF6409): `ld xhl, PerfMode_JumpTable_Extended`
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
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
PerfMode_ParamHandler_0_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_0 (0xEF646F): `ld xix, PerfMode_EventTable_0`
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
	ordi8	(0xe3e2), 8
	ldb_d8	a, (0x3714)
	ld	l, 1:opc
	ld	h, 13:opc
	call	PerfMode_ClampValue
	ld	(0x3714:16), a
	call	Disp_ShowNoteValueFields
	call	Display_UpdateRegion3
	ret
PerfMode_Evt03_FlagHandler_B:
	ordi8	(0xe3e2), 8
	ldb_d8	a, (0x3715)
	ld	l, 0:opc
	ld	h, 12:opc
	call	PerfMode_ClampValue
	ld	(0x3715:16), a
	call	Disp_ShowNoteValueFields
	call	Display_UpdateRegion3
	ret
PerfMode_Evt03_ClampAndUpdate:
	; --- Setup: or flag, load value, clamp, store, calls (30 bytes) ---
	or	(0xe3e2:16), 8
	ld	a, (0x3716:16)
	ld l, 0x00:opc
	ld h, 0x03:opc
	call PerfMode_ClampValue
	ld	(0x3716:16), a
	call Disp_ShowNoteValueFields
	call Display_UpdateRegion3
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
	ld_rrl xhl, xix, hl
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
	ordi8	(0x0f57), 1
	ld	(3923:16), 1
	ld	(3385:16), w
	bit	7, w
	jrl	z, UIDisp_DefaultInputHandler_Skip
	call	ToneParam_HandlerTable_BC_0x532
	jp	UIDisp_DefaultInputHandler_0x40
UIDisp_DefaultInputHandler_Skip:
	call	ToneParam_HandlerTable_BC_0x4F5
	ret


	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_1 (0xEF6581): `ld xix, PerfMode_EventTable_1`
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
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
PerfMode_ParamHandler_2_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_2 (0xEF665D): `ld xix, PerfMode_ParamHandler_2_DispatchTbl`
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
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
PerfMode_ParamHandler_3_Return:
	ret
PerfMode_ParamHandler_3_Entry:
	bit	7, w
	jrl	nz, PerfMode_ParamHandler_3_Entry_Skip
	call	DisplayMode_Handler_3_0x55E
	jp	PerfMode_ParamHandler_3_Entry_0x12
PerfMode_ParamHandler_3_Entry_Skip:
	call	DisplayMode_Handler_3_0x5AF
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_3 (0xEF66F8): `ld xix, PerfMode_EventTable_3`
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
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
PerfMode_ParamHandler_4_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_4 (0xEF67A6): `ld xix, PerfMode_StringData_4`
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
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
PerfMode_ParamHandler_5_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_5 (0xEF6841): `ld xix, PerfMode_EventTable_5`
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
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
PerfMode_ParamHandler_7_Return:
	ret
PerfMode_ParamHandler_Data:
	bit	7, w
	jrl	nz, PerfMode_ParamHandler_Data_Skip
	call	DisplayMode_Handler_3_0x48F
	jp	PerfMode_ParamHandler_Data_0x12
PerfMode_ParamHandler_Data_Skip:
	call	DisplayMode_Handler_3_0x4AC
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_7 (0xEF68DC): `ld xix, PerfMode_ParamHandler_7_DispatchTbl`
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
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
PerfMode_ParamHandler_8_Return:
	ret


	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_8 (0xEF698A): `ld xix, PerfMode_EventTable_7`
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
	ld	xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xec, 0x0c	; cp (XIX+HL),0x0c
	pop	xix
	jrl	z, PerfMode_VolumeParam_Process_Skip
	ld	(3567:16), 9
	call	Display_UpdateRegion0
	ld	l, (3424:16)
	dec	1, l
	xor	h, h
	push	xix
	ld	xix, 0xf1a0
	ld_rrb	l, xix, hl
	sla	hl, 2
	ld	xix, PerfMode_VoiceAddressTable
	ld_rrl	xhl, xix, hl
	pop	xix
	ld	a, (xhl)
	ld	(3831:16), a
	call	PerfMode_VolumeParam_Process_0x70
	jp	PerfMode_VolumeParam_Process_0x6F
PerfMode_VolumeParam_Process_Skip:
	xor	wa, wa
	ld	a, 169:opc
	call	SoundCtrl_SendCommand
PerfMode_VolumeParam_Process_Return:
	ret
	ld	xix, 3789
	ld	a, 32:opc
	ldw	bc, 27
	ld (xix+), a
	djnz16 bc, -6
	ld xiy, Str_VolumeEq2
	ld	xix, 3797
	ldw	bc, 9
	ldir85
	ld	a, (3831:16)
	exts	wa
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ld	xiy, 4481
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; Lcd text, 9 B.  Read by PerfMode_VolumeParam_Process (0xEF6A25): `ld xiy, Str_VolumeEq2`
	; copies 9 byte(s) per use (`ld bc, 9` + ldir) into the LCD text buffer
Str_VolumeEq2:
	.ascii "VOLUME = "
PerfMode_ParamHandler_9:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_9_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_9
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
PerfMode_ParamHandler_9_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_9 (0xEF6AD7): `ld xix, PerfMode_EventTable_9`
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
	ordi8	(0xe3e2), 8
	ldb_d8	a, (0x0ef7)
	ld	l, 0:opc
	ld	h, 127:opc
	call	PerfMode_VoiceAddressTable_0x50
	ld	(3831:16), a
	ld	l, (3424:16)
	dec	1, l
	xor	h, h
	push	xix
	ld	xix, 0xf1a0
	ld_rrb l, xix, hl
	sla hl, 2
	ld	xix, PerfMode_VoiceAddressTable
	ld_rrl xhl, xix, hl
	ld (xhl), a
	pop xix
	ld e, (36154:16)
	ld d, 3:opc
	ld	w, 127:opc
	pushw	de
	call	SwbtWr_QueuePostEvent
	call	PerfMode_VolumeParam_Process_0x70
	popw	de
	ld	c, e
	ld	b, 3:opc
	ld	e, (3831:16)
	ld	d, 127:opc
	call	MidiStream_DispatchData_0x16
	call	MidiStream_LoadAllPresets
	call	Audio_ProcessAllMidiStreams
	ret
	; Byte data, 20 B.  No reader found: no label, positional or absolute .set
	; name at this address is loaded anywhere in the image (searched by
	; scripts/analysis/scoop_data_headers.py); purpose not established.
Unref_EF6BD3_Tbl:
	.byte	0x00, 0x01, 0x02, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x04, 0x05, 0x06, 0x03, 0x0f, 0xff, 0xff, 0xff
	.byte	0xff, 0x0c, 0x0d, 0x0e
PerfMode_VoiceAddressTable:
	; PerfMode_VoiceAddressTable -- 20 x u32 work-RAM pointers, then the routine
	; at +80.
	; INDEXING RULE, from this file: an index byte is fetched from a table at
	; 0x0000F1A0 (`ld xix, 0xf1a0 / ld_rrb l, xix, hl`), scaled by 4, and used as
	;     ld xix, PerfMode_VoiceAddressTable / ld_rrl xhl, xix, hl / ld (xhl), a
	; so entries are DATA pointers written through, not handlers.
	; EXTENT: PerfMode_VoiceAddressTable_0x50 = this label + 80 and is the target
	; of six `call`s, so 0xEF6C37 is code, not a 21st entry.
	.long 0x0000f9b9
	.long 0x0000f9ed
	.long 0x0000f9d3
	.long 0x0000fa6f
	.long 0x0000fa89
	.long 0x0000faa3
	.long 0x0000fabd
	.long 0x0000fad7
	.long 0x0000fa21
	.long 0x0000fa3b
	.long 0x0000fa55
	.long 0x0000fa07
	.long 0x0000fb3f
	.long 0x0000fbdb
	.long 0x0000fbdb
	.long 0x0000f9b9
	.long 0x0000f9b9
	.long 0x0000faf1
	.long 0x0000fb0b
	.long 0x0000fb25

	; PerfMode_VoiceAddressTable_0x50: called from six sites.
	bit 7, w
	jrl nz, PerfMode_Evt04_VolumeHandler_Skip
	cp a, h
	jrl z, PerfMode_Evt04_VolumeHandler_Return
	inc 1, a
	jp PerfMode_Evt04_VolumeHandler_Return
PerfMode_Evt04_VolumeHandler_Skip:
	cp a, l
	jrl z, PerfMode_Evt04_VolumeHandler_Return
	dec 1, a
PerfMode_Evt04_VolumeHandler_Return:
	ret
PerfMode_ParamHandler_10:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_10_Return
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_10
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
PerfMode_ParamHandler_10_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_10 (0xEF6C50): `ld xix, PerfMode_EventTable_10`
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
	call PerfMode_VoiceAddressTable_0x50
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
	call PerfMode_VoiceAddressTable_0x50
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
	call PerfMode_VoiceAddressTable_0x50
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
	call PerfMode_VoiceAddressTable_0x50
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
	call PerfMode_VoiceAddressTable_0x50
	ld	(4339:16), a
	ld	(3571:16), 4
	call VoiceSlot_ReadParamsWithSaveRestore
	call ParamPopup_PartBendSense
VoiceParam_CommonTail:
	; --- Common tail ---
	call Display_UpdateRegion3
	or	(0xe3e2:16), 8
	ret
VoiceSlot_ReadParamsWithSaveRestore:
	; --- Helper 1: guard on W, parameter setup + calls (44 bytes) ---
	call VoiceState_DataBlock2_0x10C
	cp	w, 0:i3
	jrl z, VoiceParam_SaveRestore_Ret
	xor	a, a
	call VoiceSlot_SaveState
	ld	e, (3571:16)
	xor d, d
	call VoiceSlot_FinalRetZ_0xB8
	call VoiceSlot_ReadCurrentParams
	ld	w, (4339:16)
	call VoiceSlot_FinalRetZ_0x84
	xor	a, a
	call VoiceSlot_RestoreState
VoiceParam_SaveRestore_Ret:
	ret
VoiceParam_BitManipHelper:
	; --- Helper 2: guard on W, bit manipulation + calls (70 bytes) ---
	call VoiceState_DataBlock2_0x10C
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
	call VoiceSlot_FinalRetZ_0x84
	ld	e, (3571:16)
	xor d, d
	call VoiceSlot_FinalRetZ_0xB8
	call VoiceSlot_ReadCurrentParams
	ld	w, (4339:16)
	and w, 0x7f
	call VoiceSlot_FinalRetZ_0x84
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
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
UIState_PerfModeEntry_Return:
	ret
	; Handler dispatch table, 128 B.  Read by UIState_PerfModeEntry (0xEF6E29): `ld xix, UIState_EventTable`
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
	.long	UIState_EventTable_Target11
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
	; --- State check/dispatch (61 bytes) ---
	ld	(3923:16), 1
	pushw wa
	ld	wa, (0x371a:16)
	ld	(3816:16), wa
	popw wa
	bit 0x07, w
	jrl z, UIState_CallDecHandler
	call VoiceSlot_TableSetup_0x538
	jp UIState_CheckValueChanged
UIState_CallDecHandler:
	call VoiceSlot_TableSetup_0x56D
UIState_CheckValueChanged:
	ld	wa, (0x371a:16)
	cp wa, (3816:16)
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
	call Display_FillRegion0
	ld wa, (0x371a:16)
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
	call AccPedal_CheckBitAndUpdate
	ld wa, (0x371a:16)
	cp wa, 0x3e8
	jrl c, Display_RedrawValues_Store
	ldw wa, 0x3e8

Display_RedrawValues_Store:
	ld (3662:16), wa
	call Display_FillRegion1
	ld wa, (0x371a:16)
	ld (0x287f:16), wa
	call VoiceBank_BitsAndLoad
	ld a, (3424:16)
	call SetWall_SlotResolve
	ld (3820:16), a
	ld l, (3822:16)
	dec 1, l
	xor h, h
	sla hl, 1
	push xix
	ld xix, 0xc9e
	ldw_sri WA, 0x07, 0xf0, 0xec
	ld (0x28bf:16), wa
	srl hl, 1
	ld xix, 0xcbe
	ldw_sri WA, 0x07, 0xf0, 0xec
	pop xix
	and wa, 0xff
	ld (0x28c1:16), wa
	call VoiceBank_ProcessCommand
	ld xix, 0xf16
	call VoiceBank_CheckCommand
	ld c, 0x2:opc
	call VoiceBank_StatusDoubleRCF
	ld a, (3820:16)
	ld l, a
	cp a, 4:i3
	jrl ule, Display_RedrawValues_StoreDigits
	ld a, 0x4:opc

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
	call Display_FillRegion2
	ld wa, (0x371a:16)
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
	lda_dri XIY, 0x07, 0xf4, 0xe0
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
	rrc_i_8 h, 2
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
	lda_dri XIY, 0x07, 0xf4, 0xe4
	ldw bc, 0x8
	jp String_CopyFromIY

TitleString_LoadRhythmLabel:
	ld xiy, StringData_Rhythm
	ld bc, 6:i3

String_CopyFromIY:
	ldir85

TitleString_NullRet:
	ret

	; Lcd text, 5 B.  Read by Display_TitleString_Mode0 (0xEF71C0): `ld xiy, StringData_Tempo`
	; reader Display_TitleString_Mode0: `ld xiy, StringData_Tempo`
StringData_Tempo:	.ascii "TEMPO"

	; Lcd text, 6 B.  Read by Display_TitleString_Mode2 (0xEF71D7): `ld xiy, StringData_Repeat`
	; reader Display_TitleString_Mode2: `ld xiy, StringData_Repeat`
StringData_Repeat:	.ascii "REPEAT"

	; Lcd text, 5 B.  Read by Display_TitleString_Mode3 (0xEF71E2): `ld xiy, StringData_Start`
	; reader Display_TitleString_Mode3: `ld xiy, StringData_Start`
StringData_Start:	.ascii "START"

	; Lcd text, 4 B.  Read by Display_TitleString_Mode4 (0xEF71ED): `ld xiy, StringData_Stop`
	; reader Display_TitleString_Mode4: `ld xiy, StringData_Stop`
StringData_Stop:	.ascii "STOP"

	; Lcd text, 6 B.  Read by TitleString_LoadRhythmLabel (0xEF72A1): `ld xiy, StringData_Rhythm`
	; indexed with stride 8 (`sla bc, 3`)
	; copies 6 byte(s) per use (`ld bc, 6` + ldir) into the LCD text buffer
StringData_Rhythm:	.ascii "RHYTHM"

	; Lcd text, 40 B.  Read by Display_TitleString_Mode5 (0xEF71F8): `ld xiy, StringData_VariNames`
	; reader Display_TitleString_Mode5: `ld xiy, StringData_VariNames` then `lda_dri xiy, 0x07, 0xf4, 0xe0`
StringData_VariNames:	.ascii "VARI 1    VARI 2    VARI 3    VARI 4    "

	; Lcd text, 128 B.  Read by TitleString_BuildFromBank (0xEF728B): `ld xiy, StringData_StyleSections`
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
	djnz xbc, Display_FillRegionLoop
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
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
PerfMode_BytecodeBody_A_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_BytecodeBody_A (0xEF73A4): `ld xix, PerfMode_StringData_A`
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
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
PerfMode_BytecodeEntry_B_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_BytecodeEntry_B (0xEF743F): `ld xix, PerfMode_DispatchTable_B`
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
	.long	UIState_EventTable_Target11
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
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
PerfMode_BytecodeEntry_C_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_BytecodeEntry_C (0xEF74DA): `ld xix, PerfMode_DispatchTable_C`
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
	call	ScoopDisp_DispatchTable_Extended_0x3E
PerfMode_Handler_EvtA_Return:
	ret
PerfMode_Handler_EvtB:
	bit	7, w
	jrl	nz, PerfMode_Handler_EvtB_Return
	call	ScoopDisp_DispatchTable_Extended_0x79
PerfMode_Handler_EvtB_Return:
	ret
	push	xhl
	push	xde
	push	xix
	push	xiz
	bitda	3, (0x0d53)
	jrl	z, PerfMode_Handler_EvtB_0x78
	cpdi8	(0x0d65), 0
	jrl	nz, PerfMode_Handler_EvtB_Epilogue
	cpdi8	(0x0def), 18
	jrl	z, PerfMode_Handler_EvtB_Epilogue
	cpdi8	(0xc07d), 11
	jrl	nz, PerfMode_Handler_EvtB_Skip3
	push	xhl
	ld	a, (0xc07e:16)
	ld	(3519:16), a
	call	SysEx_BytecodeDispatcher
	ld	(3519:16), 0
	pop	xhl
	ld	wa, (0xc07e:16)
	xor	a, w
	jrl	z, PerfMode_Handler_EvtB_Skip
	push	xhl
	call	Interrupt_FlagSetBytecode
	pop	xhl
PerfMode_Handler_EvtB_Skip:
	ld	wa, (0xc07e:16)
	cpl	a
	and	a, w
	jrl	z, PerfMode_Handler_EvtB_Epilogue
	ld	(3425:16), 0
	call	SNS_Init_Startup
	call	Display_UpdateRegion3
	jp	PerfMode_Handler_EvtB_0x78
PerfMode_Handler_EvtB_Skip3:
	cpdi8	(0xc07d), 12
	jrl	nz, PerfMode_Handler_EvtB_Epilogue
	call	PerfMode_Handler_EvtB_0xC8
PerfMode_Handler_EvtB_Epilogue:
	pop	xiz
	pop	xix
	pop	xde
	pop	xhl
	ret
	bitda	3, (0x0d53)
	jrl	z, PerfMode_Handler_EvtB_Return2
	call	Display_ResetDirtyFlags
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, PerfMode_Handler_EvtB_Skip5
	cpdi8	(0x0d65), 0
	jrl	nz, PerfMode_Handler_EvtB_Skip5
	cpdi8	(0x8d38), 138
	jrl	nz, PerfMode_Handler_EvtB_Skip5
	cpdi8	(0x0def), 18
	jrl	z, PerfMode_Handler_EvtB_Skip4
	ld	xiy, 4360
	xor	wa, wa
	andmi16	(xiy), 65532
	cp	(xiy), wa
	jrl	z, PerfMode_Handler_EvtB_Skip5
	call	SysEx_BytecodeDispatcher
PerfMode_Handler_EvtB_Skip4:
	ldw	(4360:16), 0
PerfMode_Handler_EvtB_Skip5:
	call	Display_UpdateDirtyRegions
PerfMode_Handler_EvtB_Return2:
	ret
	ld	a, (0xc07e:16)
	and	a, (0xc07f:16)
	ldfr_berp a, 60
	and a, 3
	ldto_berp a, 60
	jrl	nz, PerfMode_Handler_EvtB_Skip6
	ld	a, (0xc07e:16)
	xor	c, c
	ldfr_berp a, 60
	ldfr_berp a, 61
	ld a, c
	.byte	0xc7, 0x3d, 0x2b	; ldcf A,RH3
	ccf
	.byte	0xc7, 0x3d, 0x2c	; stcf A,RH3
	ldto_berp a, 60
	ldto_berp a, 61
	inc 1, c
	ldfr_berp a, 60
	ldfr_berp a, 61
	ld a, c
	.byte	0xc7, 0x3d, 0x2b	; ldcf A,RH3
	ccf
	.byte	0xc7, 0x3d, 0x2c	; stcf A,RH3
	ldto_berp a, 60
	ldto_berp a, 61
	and	a, (0xc07f:16)
	ld	(3520:16), a
	push	xhl
	call	SysEx_BytecodeDispatcher
	pop	xhl
PerfMode_Handler_EvtB_Skip6:
	ld	(3520:16), 0
	ld	a, (0xc07e:16)
	and	a, 3
	jrl	z, PerfMode_Handler_EvtB_Skip2
	push	xhl
	and	a, 1
	jrl	z, PerfMode_Handler_EvtB_Skip7
	ld	xhl, 3412
	bitm	3, (xhl)
	jrl	z, PerfMode_Handler_EvtB_Skip7
	ld	(0x0205e8:24), 255
	ld	(0x0205ec:24), 255
	ld	(0x0205ea:24), 255
	ld	a, (3822:16)
	ld	(0x2877:16), a
	call	Scoop_SpecialMode_ParamCheckBound
	resda	7, (0x0d54)
	ld	(3434:16), 0
	call	ScoopParam_ValueTable_0x1DD
	ld	(0x0205e8:24), 255
	ld	(0x0205ec:24), 255
	ld	(0x0205ea:24), 255
PerfMode_Handler_EvtB_Skip7:
	pushw	wa
	ld	w, 118:opc
	call	MIDI_SendSysExFromW
	popw	wa
	pop	xhl
PerfMode_Handler_EvtB_Skip2:
	ld	a, (0xc07e:16)
	and	a, 24
	srl	a, 1
	ld	w, (0xc07f:16)
	and	w, 24
	srl	w, 3
	or	a, w
	xor	w, w
	ld	iy, wa
	push	xde
	ld	xde, PerfMode_Handler_EvtB_Data
	ld_rrb	a, xde, iy
	pop	xde
	and	a, 3
	xor	w, w
	sla	wa, 2
	ld	iy, wa
	push	xhl
	ld	xhl, ScoopDisp_DispatchTable_Extended
	ld_rrl	xiy, xhl, iy
	pop	xhl
	call	(xiy)
	ld	a, (0xc07e:16)
	and	a, 63
	cp	a, 0:i3
	jrl	nz, PerfMode_Handler_EvtB_Return3
	resda	3, (0x0d54)
	resda	1, (0x10f9)
	resda	2, (0x10f9)
PerfMode_Handler_EvtB_Return3:
	ret


	; Handler dispatch table, 16 B.  Read by PerfMode_Handler_EvtB (0xEF7580): `ld xhl, ScoopDisp_DispatchTable_Extended`
	; indexed with stride 4 (`sla wa, 2`)
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
ScoopDisp_DispatchTable_Extended:
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	DefaultHandler_Ret
	.long	VoiceCtrl_CheckAndReset
	; Loaded by PerfMode_Handler_EvtB (0xEF7580):
	; `ld xde, PerfMode_Handler_EvtB_Data` -- a bare number until lane scoop gave this address a label.
PerfMode_Handler_EvtB_Data:
	.long	0x03030300
	.long	0x03030100
	.long	0x03020300
	.long	0x00000000
	; Entry 11 of UIState_EventTable (a code pointer the table holds).
UIState_EventTable_Target11:
	bit	7, w
	jrl	nz, UIState_EventTable_Target11_Return
	ld	xiy, 3567
	ld	a, (xiy)
	ld	(3568:16), a
	ld	(xiy), 18
	ld	(3422:16), 0
	call	Display_BytecodeBlock_F_0x33F
UIState_EventTable_Target11_Return:
	ret
	ld	a, (3822:16)
	ld	(0x2877:16), a
	call	Scoop_SpecialMode_ParamCheckBound
	resda	7, (0x0d54)
	ld	(3434:16), 0
	ld	(4346:16), 1
	call	ScoopParam_ValueTable_0x1DD
	ld	(4346:16), 0
	anddi8	(0xe3e2), 111
	stdi8	(0x7f42), 35
	xor	wa, wa
	ld	a, 238:opc
	call	SoundCtrl_SendCommand
	ordi8	(0x8d88), 1
	ret
	ld	a, (3568:16)
	ld	(3567:16), a
	call	PortConfig_SetupBytecode_0x34
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
	ld_sril3 XHL, 0x07, 0xf0, 0xec
	pop xix
	call (xhl)
	call Display_UpdateDirtyRegions

Timer_ModeDispatch_Return:
	ret


	; Handler dispatch table, 16 B.  Read by Timer_ModeDispatch (0xEF77EA): `ld xix, Timer_ModeSelect_Table`
	; indexed with stride 4 (`sla hl, 2`), index from `ld l, (3429:16)`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
Timer_ModeSelect_Table:
	.long	Timer_ModeHandler_0
	.long	Timer_ModeHandler_1
	.long	Timer_ModeHandler_1
	.long	Timer_ModeHandler_3
Timer_ModeHandler_1:
	; --- Guard/init function (55 bytes) ---
	call VoiceState_DataBlock2_0x1D8
	cp	w, 0:i3
	jrl nz, Timer_GuardCallSetup_Ret
	call DisplayMode_Handler_3_0x5F
	call MemConfig_Handler_4_0x15B
	call SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl nz, Timer_GuardCallSetup_Ret
	bit	0, (3927:16)
	jrl z, Timer_GuardCallSetup
	and	(3927:16), 254
Timer_GuardCallSetup:
	call VoiceSlot_TableSetup
	call Timer_ModeHandler_0_0x13
	call Display_UpdateRegion5
	call Display_UpdateRegion3
Timer_GuardCallSetup_Ret:
	ret


Timer_ModeHandler_3:
	call	VoiceState_DataBlock2_0x1D8
	cp	w, 0:i3
	jrl	nz, Timer_ModeHandler_3_Return
	cpdi8	(0x0def), 18
	jrl	nz, Timer_ModeHandler_3_Skip
	call	PortConfig_DataTable_B_0x20
	jp	Timer_ModeHandler_3_0x3B
Timer_ModeHandler_3_Skip:
	call	DisplayMode_Handler_3_0x5F
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, Timer_ModeHandler_3_Return
	call	UIState_UpdateMultiRegions
	call	MemConfig_Handler_4_0x15B
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, Timer_ModeHandler_3_Return
	call	DisplayStr_StyleSectionNames_0x69
Timer_ModeHandler_3_Return:
	ret
Timer_ModeHandler_0:
	call	VoiceState_DataBlock2_0x1D8
	cp	w, 0:i3
	jrl	nz, Timer_ModeHandler_0_Return
	call	MemConfig_Handler_4_0x15B
	ld	(0x3728:16), 0
Timer_ModeHandler_0_Return:
	ret
	ld	xiy, 3411
	bitm	0, (xiy)
	jrl	z, Timer_ModeHandler_0_Return3
	ld	xiy, 0x3732
	ld	c, (0x370f:16)
	dec	1, c
	cp	c, 15
	jrl	ule, Timer_ModeHandler_0_Skip2
	add	iy, 2
Timer_ModeHandler_0_Skip2:
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ld	de, (xiy)
	ld	a, c
	scf
	stcf_a_16 de	; stcf A,DE
	ldto_berp a, 60
	ld	(xiy), de
	ldto_werp DE, 0x3e	; ld DE,QHL3
	bitda	0, (0x0f57)
	jrl	nz, Timer_ModeHandler_0_Return3
	call	Display_UpdateRegion4
Timer_ModeHandler_0_Return3:
	ret
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	nz, Timer_ModeHandler_0_Skip4
	ordi8	(0x28b3), 64
	ld	a, 1:opc
	call	VoiceSlot_SaveState
Timer_ModeHandler_0_Loop:
	call	SeqBuf_ReadByte
	ld	wa, hl
	cp	wa, 0xffff
	jrl	nz, Timer_ModeHandler_0_Loop
	call	VoiceCtrl_SendNoteOffSequence
	ld	e, (3822:16)
	call	VoiceSlot_FinalRetZ_0x11
	ld	(3522:16), a
	call	VoiceSlot_FinalRetZ_0x11
	cp	a, (0x0dc2:16)
	jrl	z, Timer_ModeHandler_0_Skip3
	jr	Timer_ModeHandler_0_Skip
Timer_ModeHandler_0_Skip3:
	call	VoiceSlot_FinalRetZ_0x5D
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	call	VoiceSlot_FinalRetZ_0x5D
	ld	(3522:16), a
	ld	a, 0:opc
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	call	VoiceSlot_FinalRetZ_0x5D
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
	call	VoiceSlot_FinalRetZ_0xB8
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	call	VoiceSlot_FinalRetZ_0x1E
	cp	a, 144
	jr	nz, Timer_ModeHandler_0_Skip
	jp	Timer_ModeHandler_0_0x85
Timer_ModeHandler_0_Skip:
	call	VoiceAlloc_ScoopDisplayProcess
Timer_ModeHandler_0_Skip4:
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	ret
	ld	xhl, 3412
	bitm	2, (xhl)
	jrl	z, Timer_ModeHandler_0_Return2
	resm	2, (xhl)
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 144
	jrl	nz, Timer_ModeHandler_0_Return2
	call	VoiceCtrl_SendNoteOffSequence
	xor	a, a
	call	VoiceSlot_SaveState
	call	Timer_ModeHandler_0_0x189
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	call	Timer_ModeHandler_0_0x189
	xor	a, a
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	call	Timer_ModeHandler_0_0x189
	ld	hl, wa
	pushw	hl
	call	SeqBuf_WriteByte
	inc	2, xsp
	call	Timer_ModeHandler_0_0x189
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
	ordi8	(0x28b3), 64
	ordi8	(0x0f54), 1
	ld	(3431:16), 0
	call	VoiceAlloc_ScoopDisplayProcess
Timer_ModeHandler_0_Return2:
	ret
	push	xhl
	call	VoiceSlot_FinalRetZ
	pop	xhl
	ret
Timer_ParamLoadAndCompare:
	ld	(3536:16), 255
	call	VoiceState_DataBlock2_0x10C
	cp	w, 255
	jrl	z, Timer_ParamLoadAndCompare_Skip
	cp	c, 2:i3
	jrl	ugt, Timer_ParamLoadAndCompare_Skip
	call	SysInit_BytecodeBlock_0xC9
	cpdi8	(0x7f42), 15
	jrl	z, Timer_ParamLoadAndCompare_0x2D
Timer_ParamLoadAndCompare_Skip:
	ld	w, 0:opc
	call	Timer_ParamCompareAlt_0x2A
	bitda	5, (0x0d54)
	jrl	nz, Timer_ParamLoadAndCompare_Skip2
	ld	(3413:16), 255
	jp	Timer_ParamLoadAndCompare_0x44
Timer_ParamLoadAndCompare_Skip2:
	ld	w, 0:opc
	call	Timer_ParamCompareAlt_0x2A
	resda	5, (0x0d54)
	jp	Timer_ParamLoadAndCompare_0x2D
	ret
Timer_ParamCompareAlt:
	ld	(3536:16), 255
	ld	w, 1:opc
	call	Timer_ParamCompareAlt_0x2A
	bitda	5, (0x0d54)
	jrl	nz, Timer_ParamCompareAlt_Skip5
	ld	(3413:16), 255
	jp	Timer_ParamCompareAlt_0x29
Timer_ParamCompareAlt_Skip5:
	ld	w, 1:opc
	call	Timer_ParamCompareAlt_0x2A
	resda	5, (0x0d54)
	jp	Timer_ParamCompareAlt_0x12
	ret
	call	ScoopParam_ValueTable_0x84
	xor	a, a
	call	VoiceSlot_SaveState
	pushdi_w	(0x371a)
	pushdi_w	(0x0d5c)
	ld	(3522:16), 0
	call	Timer_ParamCompareAlt_0x2AF
	ld	(3531:16), a
	ld	a, (3415:16)
	ld	(3521:16), a
	cp	w, 0:i3
	jrl	nz, Timer_ParamCompareAlt_Skip6
	jp	Timer_ParamCompareAlt_0x142
Timer_ParamCompareAlt_Skip6:
	cpdi8	(0x0dc2), 0
	jrl	nz, Timer_ParamCompareAlt_Skip9
	call	VoiceSlot_CompareAndBranch_0x7
	cp	w, 255
	jrl	nz, Timer_ParamCompareAlt_Skip8
	cpdi8	(0x0d57), 0
	jrl	z, Timer_ParamCompareAlt_Skip7
	inc	1, (3522:16)
	jp	Timer_ParamCompareAlt_0x9A
Timer_ParamCompareAlt_Skip7:
	add	xsp, 4
	ld	w, 104:opc
	call	MIDI_SendSysExFromW
	jp	Timer_ParamCompareAlt_0x141
Timer_ParamCompareAlt_Skip8:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, Timer_ParamCompareAlt_Skip9
	inc	1, (3522:16)
Timer_ParamCompareAlt_Skip9:
	call	Timer_ParamCompareAlt_0x28A
	cpdi8	(0x0dc2), 0
	jrl	z, Timer_ParamCompareAlt_Skip10
	cpdi8	(0x0dc1), 0
	jrl	z, Timer_ParamCompareAlt_Skip13
	jp	Timer_ParamCompareAlt_0x232
Timer_ParamCompareAlt_Skip10:
	cpdi8	(0x0dc1), 0
	jrl	nz, Timer_ParamCompareAlt_Skip11
	jp	Timer_ParamCompareAlt_0x258
Timer_ParamCompareAlt_Skip11:
	call	Timer_ParamCompareAlt_0x2AF
	cp	e, a
	jrl	le, Timer_ParamCompareAlt_Skip12
	jp	Timer_ParamCompareAlt_0x232
Timer_ParamCompareAlt_Skip12:
	jp	Timer_ParamCompareAlt_0x249
Timer_ParamCompareAlt_Skip13:
	decw	1, (3418:16)
	add	xsp, 4
	pushw	de
	call	AccPedal_CheckBitAndUpdate
	popw	de
	xor	a, a
	call	VoiceSlot_SaveState
	pushdi_w	(0x371a)
	pushdi_w	(0x0d5c)
	call	VoiceSlot_CompareAndBranch_0x7
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, Timer_ParamCompareAlt_Skip14
	call	VoiceSlot_FlagCheck
	cp	a, 83
	jrl	le, Timer_ParamCompareAlt_Skip14
	cp	a, 95
	jrl	le, Timer_ParamCompareAlt_Skip15
	add	xsp, 4
	jp	Timer_ParamCompareAlt_0x141
Timer_ParamCompareAlt_Skip14:
	ld	(3415:16), 84
	popw (0x0d5c:16)	; popw (0x0d5c)
	popw (0x371a:16)	; popw (0x371a)
	xor	a, a
	call	VoiceSlot_RestoreState
	call	DisplayMode_Handler_3_0x775
	jp	Timer_ParamCompareAlt_0x141
Timer_ParamCompareAlt_Skip15:
	jp	Timer_ParamCompareAlt_0x249
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ld	w, 104:opc
	call	MIDI_SendSysExFromW
	ret
	anddi8	(0x0d53), 251
	call	Timer_ParamCompareAlt_0x277
	cpdi8	(0x0dcb), 255
	jrl	nz, Timer_ParamCompareAlt_Skip19
	cp	e, 96
	jrl	nz, Timer_ParamCompareAlt_Skip18
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
	cpdi8	(0x0dc1), 83
	jrl	ule, Timer_ParamCompareAlt_Skip16
	ordi8	(0x0d53), 4
	cpdi8	(0x0d40), 255
	jrl	nz, Timer_ParamCompareAlt_Skip16
	call	SysInit_BytecodeBlock_0xE8
Timer_ParamCompareAlt_Skip16:
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
	call	Timer_ParamCompareAlt_0x2AF
	cp	a, 0:i3
	jrl	nz, Timer_ParamCompareAlt_Skip17
	ld	(3415:16), a
	call	DMA_FlagCheckWithCalls
	jp	Timer_ParamCompareAlt_0x231
Timer_ParamCompareAlt_Skip17:
	ld	(3415:16), 0
	call	DisplayMode_Handler_3_0x775
	jp	Timer_ParamCompareAlt_0x231
Timer_ParamCompareAlt_Skip18:
	ld	(3415:16), e
	add	xsp, 4
	call	DisplayMode_Handler_3_0x775
	jp	Timer_ParamCompareAlt_0x231
Timer_ParamCompareAlt_Skip19:
	ld	a, (3531:16)
	cp a, (3521:16)
	jrl	nz, Timer_ParamCompareAlt_Skip
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
	jrl	z, Timer_ParamCompareAlt_Skip2
	call	Timer_ParamCompareAlt_0x2AF
Timer_ParamCompareAlt_Skip:
	cp	e, a
	jrl	ge, Timer_ParamCompareAlt_Skip20
	ld	(3415:16), e
	add	xsp, 4
	call	DisplayMode_Handler_3_0x775
	jp	Timer_ParamCompareAlt_0x231
Timer_ParamCompareAlt_Skip2:
	jp	Timer_ParamCompareAlt_0x153
Timer_ParamCompareAlt_Skip20:
	ld	(3415:16), a
	add	xsp, 4
	call	DMA_FlagCheckWithCalls
	ret
	ld	(3415:16), e
	popw (0x0d5c:16)	; popw (0x0d5c)
	popw (0x371a:16)	; popw (0x371a)
	xor	a, a
	call	VoiceSlot_RestoreState
	call	DisplayMode_Handler_3_0x775
	ret
	add	xsp, 4
	ld	(3415:16), a
	call	DMA_FlagCheckWithCalls
	ret
	ld	(3415:16), 0
	add	xsp, 4
	call	DMA_FlagCheckWithCalls
	ret
	add	xsp, 4
	ld	(3415:16), e
	call	DisplayMode_Handler_3_0x775
	ret
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
	pushw	wa
	ld	a, (3521:16)
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	cp	w, 0:i3
	jrl	nz, Timer_ParamCompareAlt_Skip4
	cp	a, 0:i3
	jrl	nz, Timer_ParamCompareAlt_Skip3
	ld	a, 7:opc
	jp	Timer_ParamCompareAlt_0x2A7
Timer_ParamCompareAlt_Skip3:
	dec	1, a
Timer_ParamCompareAlt_Skip4:
	xor	w, w
	mul	wa, l
	ld	e, a
	popw	wa
	ret
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
	jrl	z, Timer_ParamCompareAlt_Skip21
	pushw	wa
	call	VoiceSlot_FlagCheck
	ld	l, a
	popw	wa
	ld	a, l
	jp	Timer_ParamCompareAlt_0x2D7
Timer_ParamCompareAlt_Skip21:
	ld	a, 255:opc
	ret
ToneParam_ModeGuardEntry:
	bit	7, w
	jrl	nz, ToneParam_ModeGuardEntry_Return
	cpdi8	(0x0d65), 1
	jrl	nz, ToneParam_ModeGuardEntry_Return
	call	SerialPort_ModeHandler_0_0x113
	call	VoiceState_DataBlock2_0x10C
	cp	w, 0:i3
	jrl	nz, ToneParam_ModeGuardEntry_Skip
	cp	c, 6:i3
	jrl	ugt, ToneParam_ModeGuardEntry_Skip
	call	ScoopParam_ValueTable_0x1C
	call	SerialPort_ModeHandler_0_0xEA
	jp	ToneParam_ModeGuardEntry_0x39
ToneParam_ModeGuardEntry_Skip:
	ld	(3923:16), 0
	call	DisplayMode_Handler_3_0x308
	resda	2, (0x0d54)
	ordi8	(0x0dd3), 1
	call	VoiceSlot_TableSetup
	call	Display_UpdateRegion5
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, ToneParam_ModeGuardEntry_Skip2
	cp	a, 130
	jrl	z, ToneParam_ModeGuardEntry_Skip2
	call	VoiceSlot_FlagCheck
	cp	a, (0x0d57:16)
	jrl	ugt, ToneParam_ModeGuardEntry_Skip2
	call	DMA_FlagCheckWithCalls
	jp	ToneParam_ModeGuardEntry_0x6D
ToneParam_ModeGuardEntry_Skip2:
	call	DisplayMode_Handler_3_0x775
	resda	2, (0x0d54)
	call	Display_UpdateRegion3
ToneParam_ModeGuardEntry_Return:
	ret
	bit	7, w
	jrl	nz, MemConfig_Handler_5_Skip14
MemConfig_Handler_5:
	set	3, (3412:16)
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
	jrl	z, MemConfig_Handler_5_Skip12
	cp	a, 130
	jrl	z, MemConfig_Handler_5_Skip12
	cpdi8	(0x0d57), 48
	jrl	nz, MemConfig_Handler_5_Skip16
MemConfig_Handler_5_Loop:
	call	MemConfig_Handler_5_0xCC
MemConfig_Handler_5_Skip12:
	ordi8	(0x8d88), 1
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jr	nz, MemConfig_Handler_5_Skip13
	call	Interrupt_FlagSetBytecode_0x13
MemConfig_Handler_5_Skip13:
	call	SubCPU_ToneParamRet_0x4BD
	call	DMA_FlagCheckWithCalls
	call	SndDispatch_ProcessCommand_0x28B
	ld	w, 98:opc
	call	MIDI_SendSysExFromW
	xor	w, w
MemConfig_Handler_5_Skip14:
	jp	MemConfig_Handler_5_0x197
MemConfig_Handler_5_Skip15:
	call	MemConfig_Handler_5_0x83
	jp	MemConfig_Handler_5_0x3F
MemConfig_Handler_5_Skip16:
	call	VoiceSlot_FlagCheck
	cp	a, 48
	jrl	nz, MemConfig_Handler_5_Loop
	call	MemConfig_Handler_5_0x1BF
	jp	MemConfig_Handler_5_0x3F
	cpdi8	(0x0d57), 48
	jrl	z, MemConfig_Handler_5_Skip17
	call	MemConfig_Handler_5_0xE4
MemConfig_Handler_5_Loop2:
	ordi8	(0x8d88), 1
	jp	MemConfig_Handler_5_0x197
MemConfig_Handler_5_Skip17:
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, MemConfig_Handler_5_Loop2
	cp	a, 132
	jrl	z, MemConfig_Handler_5_Loop2
	cp	a, 129
	jrl	nz, MemConfig_Handler_5_Skip18
	call	MemConfig_Handler_5_0xE4
	jp	MemConfig_Handler_5_0x8F
MemConfig_Handler_5_Skip18:
	call	MemConfig_Handler_5_0xE4
	call	VoiceSlot_FlagCheck
	cp	a, 48
	jrl	z, MemConfig_Handler_5_Loop2
	call	MemConfig_Handler_5_0x1BF
	jp	MemConfig_Handler_5_0x8F
	cpdi8	(0x0df4), 144
	jrl	nz, MemConfig_Handler_5_Skip19
	call	MemConfig_Handler_5_0xEE
	jp	MemConfig_Handler_5_0x197
MemConfig_Handler_5_Skip19:
	call	ToneParam_Evt09_BytecodeHandler_0x6
	jp	MemConfig_Handler_5_0x197
	ld	w, 1:opc
	call	VoiceSlot_RetZ
	jp	MemConfig_Handler_5_0x197
	xor	a, a
	call	VoiceSlot_SaveState
	ld	de, 4:i3
	call	VoiceSlot_FinalRetZ_0xB8
	call	VoiceSlot_ReadCurrentParams
	ld	(3575:16), a
	call	VoiceSlot_FlagCheck
	ld	(3576:16), a
	xor	a, a
	call	VoiceSlot_RestoreState
	call	MemConfig_Handler_5_0x198
	ld	c, (3576:16)
	xor	b, b
	cp	bc, 0:i3
	jrl	z, MemConfig_Handler_5_Skip
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
	jp	MemConfig_Handler_5_0x191
MemConfig_Handler_5_Skip20:
	pushdi_w	(0x0d58)
	call	VoiceSlot_LoadAndDispatch
	popw_dd16 0x58, 0x0d	; popw (0x0d58)
	popw	bc
	jp	MemConfig_Handler_5_0x11F
MemConfig_Handler_5_Skip21:
	pushw	bc
	call	MemConfig_Handler_5_0xE4
	popw	bc
	djnz16	bc, -60
MemConfig_Handler_5_Skip:
	ld	a, (3575:16)
	cpdi8	(0x0d57), 48
	jrl	z, MemConfig_Handler_5_Skip22
	cp	a, 48
	jrl	nz, MemConfig_Handler_5_Return
	call	MemConfig_Handler_5_0x1BF
	jp	MemConfig_Handler_5_0x197
MemConfig_Handler_5_Skip22:
	cp	a, 48
	jrl	nz, MemConfig_Handler_5_Return
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, MemConfig_Handler_5_Return
	call	MemConfig_Handler_5_0xE4
	call	MemConfig_Handler_5_0x1BF
	jp	MemConfig_Handler_5_0x197
	add	xsp, 2
MemConfig_Handler_5_Return:
	ret
	call	VoiceSlot_FlagCheck
	ld	(3523:16), a
MemConfig_Handler_5_Loop3:
	call	VoiceSlot_FlagCheck
	cp a, (3523:16)
	jrl nz, MemConfig_Handler_5_Return2
	ld w, 6:opc
	call	VoiceSlot_RetZ
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 144
	jrl	z, MemConfig_Handler_5_Loop3
MemConfig_Handler_5_Return2:
	ret
	xor	a, a
	call	VoiceSlot_SaveState
	ld	xiy, 3577
	cpdi8	(0x0d57), 48
	jrl	nz, MemConfig_Handler_5_Skip23
	ld	(xiy), 2
	jp	MemConfig_Handler_5_0x1DC
MemConfig_Handler_5_Skip23:
	ld	(xiy), 1
MemConfig_Handler_5_Loop4:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, MemConfig_Handler_5_Skip24
	cp	a, 130
	jrl	z, MemConfig_Handler_5_Skip24
	cpdi8	(0x0df9), 1
	jrl	z, MemConfig_Handler_5_Skip25
	call	MemConfig_Handler_5_0x286
	cp	w, 255
	jrl	nz, MemConfig_Handler_5_Loop4
MemConfig_Handler_5_Skip24:
	xor	a, a
	call	VoiceSlot_RestoreState
	jp	MemConfig_Handler_5_0x2F0
MemConfig_Handler_5_Skip25:
	call	MemConfig_Handler_5_0x216
	cp	w, 255
	jrl	nz, MemConfig_Handler_5_Loop4
	jp	MemConfig_Handler_5_0x1FE
	cp	a, 129
	jrl	z, MemConfig_Handler_5_Skip2
	bit	7, a
	jrl	z, MemConfig_Handler_5_Skip2
	call	VoiceSlot_FlagCheck
	cp	a, 48
	jrl	z, MemConfig_Handler_5_Skip3
	cp	a, 47
	jrl	z, MemConfig_Handler_5_Skip5
	cp	a, 95
	jrl	z, MemConfig_Handler_5_Skip4
	cp	a, 0:i3
	jrl	z, MemConfig_Handler_5_Skip6
MemConfig_Handler_5_Skip2:
	call	VoiceSlot_LoadAndDispatch
	jp	MemConfig_Handler_5_0x2F0
MemConfig_Handler_5_Skip3:
	xor	w, w
	call	MemConfig_Handler_5_0x2E6
	jp	MemConfig_Handler_5_0x23D
MemConfig_Handler_5_Skip4:
	ld	w, 47:opc
	call	MemConfig_Handler_5_0x2E6
	jp	MemConfig_Handler_5_0x23D
MemConfig_Handler_5_Skip5:
	ld	w, 95:opc
	call	MemConfig_Handler_5_0x2E6
	jp	MemConfig_Handler_5_0x23D
MemConfig_Handler_5_Skip6:
	ld	(3577:16), 2
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	ld	w, 48:opc
	call	MemConfig_Handler_5_0x2E6
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	call	VoiceSlot_CompareAndBranch
	call	MemConfig_Handler_5_0xE4
	jp	MemConfig_Handler_5_0x23D
	cp	a, 129
	jrl	z, MemConfig_Handler_5_Skip7
	bit	7, a
	jrl	z, MemConfig_Handler_5_Skip7
	call	VoiceSlot_FlagCheck
	cp	a, 0:i3
	jrl	z, MemConfig_Handler_5_Skip8
	cp	a, 47
	jrl	z, MemConfig_Handler_5_Skip10
	cp	a, 95
	jrl	z, MemConfig_Handler_5_Skip9
	cp	a, 48
	jrl	z, MemConfig_Handler_5_Skip11
MemConfig_Handler_5_Skip7:
	call	VoiceSlot_LoadAndDispatch
	jp	MemConfig_Handler_5_0x2F0
MemConfig_Handler_5_Skip8:
	ld	w, 48:opc
	call	MemConfig_Handler_5_0x2E6
	jp	MemConfig_Handler_5_0x2AD
MemConfig_Handler_5_Skip9:
	ld	w, 47:opc
	call	MemConfig_Handler_5_0x2E6
	jp	MemConfig_Handler_5_0x2AD
MemConfig_Handler_5_Skip10:
	ld	w, 95:opc
	call	MemConfig_Handler_5_0x2E6
	jp	MemConfig_Handler_5_0x2AD
MemConfig_Handler_5_Skip11:
	ld	(3577:16), 1
	call	SysInit_BytecodeBlock_0xFF
	xor	w, w
	call	MemConfig_Handler_5_0x2E6
	jp	MemConfig_Handler_5_0x2AD
	pushw	wa
	call	VoiceSlot_FinalRetZ
	popw	wa
	call	VoiceSlot_FinalRetZ_0x84
	ret
ToneParam_ShortCallHandler:
	call	ToneParam_Evt09_BytecodeHandler
	call	UIState_UpdateMultiRegions
	ret
ToneParam_Evt09_BytecodeHandler:
	bit	7, w
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop3
	call	ToneParam_HandlerTable_BC_0x10
	cp	w, 1:i3
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip2
	call	VoiceState_DataBlock2_0x20B
	cp	w, 1:i3
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip2
	call	VoiceCtrl_BytecodeHandler
	cp	b, 255
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Skip3
ToneParam_Evt09_BytecodeHandler_Loop2:
	call	VoiceSlot_FlagCheck
	cp	a, (0x0d57:16)
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop3
	call	ToneParam_HandlerTable_BC_0x4DC
	ld	(0x7f42:16), 255
ToneParam_Evt09_BytecodeHandler_Skip2:
	ordi8	(0x0dd3), 1
	ld	l, (3429:16)
	and	hl, 3
	sla	hl, 2
	push	xix
	ld	xix, ToneParam_HandlerTable_BC
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
	call	PortConfig_Handler_0_0xD7
	resda	2, (0x0d54)
	ordi8	(0x8d88), 1
ToneParam_Evt09_BytecodeHandler_Loop3:
	jp	ToneParam_Evt09_BytecodeHandler_0xCF
ToneParam_Evt09_BytecodeHandler_Skip3:
	call	VoiceSlot_FlagCheck
	cp a, (3415:16)
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop3
	ld	a, b
	and	a, 15
	cp	a, 2:i3
	jrl	z, ToneParam_Evt09_BytecodeHandler_Loop2
	or	b, 16
	ld	(3530:16), b
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	call	ToneParam_HandlerTable_BC_0x4DC
	ld	(0x7f42:16), 255
ToneParam_Evt09_BytecodeHandler_Loop:
	call	VoiceCtrl_BytecodeHandler
	pushw	bc
	xor	a, a
	call	VoiceSlot_SaveState
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip
	popw	bc
	cp	(3530:16), b
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop
	xor	a, a
	call	VoiceSlot_RestoreState
	ld	w, (3532:16)
	call	VoiceSlot_RetZ
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	jp	ToneParam_Evt09_BytecodeHandler_0x36
ToneParam_Evt09_BytecodeHandler_Skip:
	add	xsp, 2
	jp	ToneParam_Evt09_BytecodeHandler_0xBB
	ret
	; Handler dispatch table, 16 B.  Read by ToneParam_Evt09_BytecodeHandler (0xEF80AF): `ld xix, ToneParam_HandlerTable_BC`
	; indexed with stride 4 (`sla hl, 2`), index from `ld l, (3429:16)`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
ToneParam_HandlerTable_BC:
	.long	DefaultHandler_Ret
	.long	VoiceSlot_TableSetup
	.long	VoiceSlot_TableSetup
	.long	DefaultHandler_Ret
	cpdi8	(0x0d65), 3
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip4
ToneParam_Evt09_BytecodeHandler_Loop4:
	ld	w, 0:opc
	jp	ToneParam_HandlerTable_BC_0x9E
ToneParam_Evt09_BytecodeHandler_Skip4:
	call	ToneParam_HandlerTable_BC_0x269
	cp	w, 255
	jrl	z, ToneParam_Evt09_BytecodeHandler_Loop4
	call	ToneParam_HandlerTable_BC_0x2D4
	cp	w, 0:i3
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Skip5
	ld	w, 104:opc
	call	MIDI_SendSysExFromW
	ld	w, 1:opc
	jp	ToneParam_HandlerTable_BC_0x9E
ToneParam_Evt09_BytecodeHandler_Skip5:
	ld	a, (3647:16)
	ld	(3649:16), a
	call	ToneParam_HandlerTable_BC_0x1A2
	ld	a, (3647:16)
	ld	(3648:16), a
	cp	a, (0x0e41:16)
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Skip6
	jp	ToneParam_HandlerTable_BC_0x18
ToneParam_Evt09_BytecodeHandler_Skip6:
	ld	wa, (3418:16)
	cp wa, (3435:16)
	jrl	c, ToneParam_Evt09_BytecodeHandler_Entry
	call	ToneParam_HandlerTable_BC_0x4DC
	ld	a, (3648:16)
	cp a, (3649:16)
	jrl c, ToneParam_Evt09_BytecodeHandler_Skip7
	call	ToneParam_HandlerTable_BC_0x2EB
	jp	ToneParam_HandlerTable_BC_0x82
ToneParam_Evt09_BytecodeHandler_Skip7:
	call	ToneParam_HandlerTable_BC_0x357
	ld	w, 1:opc
	jp	ToneParam_HandlerTable_BC_0x9E
ToneParam_Evt09_BytecodeHandler_Entry:
	anddi8	(0xe3e2), 111
	stdi8	(0x7f42), 25
	xor	wa, wa
	ld	a, 238:opc
	call	SoundCtrl_SendCommand
	jp	ToneParam_HandlerTable_BC_0x82
	ret
	ld	a, (3429:16)
	cp	a, 3:i3
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip8
	ld	w, 0:opc
	jp	ToneParam_HandlerTable_BC_0xD3
ToneParam_Evt09_BytecodeHandler_Skip8:
	ld	a, (0x3722:16)
	ld	d, (3655:16)
	call	Rhythm_DispatchNote_Tramp
	ld	(3648:16), a
	call	ToneParam_HandlerTable_BC_0x1CB
	cp	w, 0:i3
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Skip9
	call	ToneParam_HandlerTable_BC_0xD4
	jp	ToneParam_HandlerTable_BC_0xD3
ToneParam_Evt09_BytecodeHandler_Skip9:
	call	ToneParam_HandlerTable_BC_0x148
	ret
	ld	a, (3647:16)
	ld	(3649:16), a
	ld	a, (3648:16)
	cp a, (3649:16)
	jrl nz, ToneParam_Evt09_BytecodeHandler_Skip10
	call	ToneParam_HandlerTable_BC_0x4DC
	ld	w, 6:opc
	ld	xiy, 3471
	call	SysInit_BytecodeBlock_0x486
	jp	ToneParam_HandlerTable_BC_0x145
ToneParam_Evt09_BytecodeHandler_Skip10:
	ld	wa, (3418:16)
	cp wa, (3435:16)
	jrl	c, ToneParam_Evt09_BytecodeHandler_Entry2
	call	ToneParam_HandlerTable_BC_0x4DC
	ld	a, (3648:16)
	cp a, (3649:16)
	jrl c, ToneParam_Evt09_BytecodeHandler_Skip11
	call	ToneParam_HandlerTable_BC_0x2EB
	jp	ToneParam_HandlerTable_BC_0x120
ToneParam_Evt09_BytecodeHandler_Skip11:
	call	ToneParam_HandlerTable_BC_0x357
	ld	w, 6:opc
	ld	xiy, 3471
	call	SysInit_BytecodeBlock_0x486
	jp	ToneParam_HandlerTable_BC_0x145
ToneParam_Evt09_BytecodeHandler_Entry2:
	anddi8	(0xe3e2), 111
	stdi8	(0x7f42), 25
	xor	wa, wa
	ld	a, 238:opc
	call	SoundCtrl_SendCommand
	jp	ToneParam_HandlerTable_BC_0x145
	ld	w, 1:opc
	ret
	call	ToneParam_HandlerTable_BC_0x1A2
	ld	a, (3647:16)
	ld	(3649:16), a
	ld	a, (3648:16)
	cp a, (3649:16)
	jrl nz, ToneParam_Evt09_BytecodeHandler_Skip12
	ld	w, 0:opc
	jp	ToneParam_HandlerTable_BC_0x1A1
ToneParam_Evt09_BytecodeHandler_Skip12:
	ld	wa, (3418:16)
	cp wa, (3435:16)
	jrl	c, ToneParam_Evt09_BytecodeHandler_Entry3
	ld	a, (3648:16)
	cp a, (3649:16)
	jrl c, ToneParam_Evt09_BytecodeHandler_Skip13
	call	ToneParam_HandlerTable_BC_0x2EB
	jp	ToneParam_HandlerTable_BC_0x187
ToneParam_Evt09_BytecodeHandler_Skip13:
	call	ToneParam_HandlerTable_BC_0x357
	ld	w, 0:opc
	jp	ToneParam_HandlerTable_BC_0x1A1
ToneParam_Evt09_BytecodeHandler_Entry3:
	anddi8	(0xe3e2), 111
	stdi8	(0x7f42), 25
	xor	wa, wa
	ld	a, 238:opc
	call	SoundCtrl_SendCommand
	ld	w, 1:opc
	ret
	ld	a, 3:opc
	call	VoiceSlot_SaveState
ToneParam_Evt09_BytecodeHandler_Loop5:
	call	VoiceSlot_CompareAndBranch_0x7
	cp	w, 255
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip14
	call	ToneParam_HandlerTable_BC_0x269
	cp	w, 0:i3
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop5
	jp	ToneParam_HandlerTable_BC_0x1C4
ToneParam_Evt09_BytecodeHandler_Skip14:
	ld	(3647:16), 4
	ld	a, 3:opc
	call	VoiceSlot_RestoreState
	ret
	ld	a, 3:opc
	call	VoiceSlot_SaveState
ToneParam_Evt09_BytecodeHandler_Loop6:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, ToneParam_Evt09_BytecodeHandler_Loop7
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop6
ToneParam_Evt09_BytecodeHandler_Loop7:
	call	VoiceSlot_CompareAndBranch_0x7
	cp	w, 255
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip17
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip17
	call	ToneParam_HandlerTable_BC_0x269
	cp	w, 0:i3
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop7
	ld	a, 4:opc
	call	VoiceSlot_SaveState
	ld	a, (3647:16)
	ld	(3650:16), a
ToneParam_Evt09_BytecodeHandler_Loop8:
	call	VoiceSlot_CompareAndBranch_0x7
	cp	w, 255
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip15
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, ToneParam_Evt09_BytecodeHandler_Loop9
	call	ToneParam_HandlerTable_BC_0x269
	cp	w, 0:i3
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop8
	call	ToneParam_HandlerTable_BC_0x4DC
	jp	ToneParam_HandlerTable_BC_0x210
ToneParam_Evt09_BytecodeHandler_Loop9:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip16
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip16
ToneParam_Evt09_BytecodeHandler_Skip15:
	call	ToneParam_HandlerTable_BC_0x269
	cp	w, 0:i3
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop9
ToneParam_Evt09_BytecodeHandler_Skip16:
	ld	a, (3650:16)
	ld	(3647:16), a
	ld	w, 0:opc
	jp	ToneParam_HandlerTable_BC_0x268
ToneParam_Evt09_BytecodeHandler_Skip17:
	ld	a, 3:opc
	call	VoiceSlot_RestoreState
	ld	w, 255:opc
	ret
	push	xiy
	ld	a, 2:opc
	call	VoiceSlot_SaveState
	call	VoiceSlot_FinalRetZ
	ld	(3528:16), a
	and	a, 240
	cp	a, 192
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Skip19
	call	VoiceSlot_StatusRet_0x8A1
	cp	a, 72
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Skip19
	call	VoiceSlot_FinalRetZ
	ldfr_berp a, 60
	and a, 31
	ldto_berp a, 60
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Skip19
	srl	a, 5
	and	a, 3
	ld	d, a
	ld	e, (3528:16)
	and	e, 12
	or	d, e
	pushw	de
	call	VoiceSlot_ReadCurrentParams
	popw	de
	bitda	0, (0x0dc8)
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip18
	or	a, 128
ToneParam_Evt09_BytecodeHandler_Skip18:
	call	Rhythm_DispatchNote_Tramp
	ld	(3647:16), a
	ld	w, 0:opc
	jp	ToneParam_HandlerTable_BC_0x2CC
ToneParam_Evt09_BytecodeHandler_Skip19:
	ld	w, 255:opc
	ld	a, 2:opc
	call	VoiceSlot_RestoreState
	pop	xiy
	ret
	ld	w, 255:opc
	pushw	de
	xor	de, de
	cp (3418:16), de
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Epilogue
	cp e, (3415:16)
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Epilogue
	ld	w, 0:opc
ToneParam_Evt09_BytecodeHandler_Epilogue:
	popw	de
	ret
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	xor	a, a
	ld	(3651:16), a
ToneParam_Evt09_BytecodeHandler_Loop10:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Skip20
	inc	1, (3651:16)
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip21
	ld	a, (3651:16)
	cp a, (3649:16)
	jrl c, ToneParam_Evt09_BytecodeHandler_Loop10
	xor	b, b
	ld	c, (3648:16)
	sub	c, (3649:16)
	call	SysInit_BytecodeBlock_0xFF
	djnz16	bc, -7
	jp	ToneParam_HandlerTable_BC_0x2F8
ToneParam_Evt09_BytecodeHandler_Skip20:
	and	a, 240
	cp	a, 192
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip21
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop10
ToneParam_Evt09_BytecodeHandler_Skip21:
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ret
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	xor	a, a
	ld	(3651:16), a
ToneParam_Evt09_BytecodeHandler_Loop11:
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip24
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip24
	cp	a, 129
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip22
	and	a, 240
	cp	a, 192
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip24
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip24
	jp	ToneParam_HandlerTable_BC_0x36A
ToneParam_Evt09_BytecodeHandler_Skip22:
	inc	1, (3651:16)
	call	MemConfig_Handler_5_0xE4
	ld	a, (3649:16)
	sub	a, (3648:16)
	cp a, (3651:16)
	jrl ugt, ToneParam_Evt09_BytecodeHandler_Loop11
	xor	b, b
	ld	c, (3648:16)
	call	VoiceSlot_ReadCurrentParams
	cp	a, 130
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip24
	cp	a, 132
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip24
	cp	a, 129
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Skip23
	pushw	bc
	call	VoiceSlot_DispatchRet
	popw	bc
	cp	w, 255
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip24
	djnz16	bc, -37
	jp	ToneParam_HandlerTable_BC_0x364
ToneParam_Evt09_BytecodeHandler_Skip23:
	and	a, 240
	cp	a, 192
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip24
	pushw	bc
	call	VoiceSlot_DispatchRet
	popw	bc
	jp	ToneParam_HandlerTable_BC_0x3B8
ToneParam_Evt09_BytecodeHandler_Skip24:
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ret
	; Called by SerialPort_ModeHandler_0 (0xEF9E03):
	; `call SerialPort_ModeHandler_0_Helper` -- a bare number until lane scoop gave this address a label.
SerialPort_ModeHandler_0_Helper:
	ld	a, (3822:16)
	ld	(3654:16), a
	xor	wa, wa
	ld	(3822:16), a
	ld	(3435:16), wa
	cpdi8	(0x0d65), 3
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Skip27
ToneParam_Evt09_BytecodeHandler_Loop12:
	ld	a, (3822:16)
	inc	1, a
	cp	a, 16
	jrl	ugt, ToneParam_Evt09_BytecodeHandler_Skip27
	ld	(3822:16), a
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	push	xix
	ld	xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf8, 0x10	; cp (XIX+IZ),0x10
	pop	xix
	jrl	z, ToneParam_Evt09_BytecodeHandler_Loop12
	xor	wa, wa
	ld	(3652:16), wa
	call	VoiceState_DataBlock2_0x184
	cp	w, 0:i3
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop12
	xor	wa, wa
	ld	a, (3822:16)
	dec	1, a
	ld	w, a
	sla	a, 1
	add	a, w
	xor	w, w
	inc	1, wa
	push	xde
	ld	xde, 0xf250
	ld_rrw	wa, xde, wa
	push	xhl
	xor	hl, hl
	ld	l, (3822:16)
	dec	1, l
	sla	l, 1
	ld	xde, 3230
	st_rrw wa, xde, hl
	srl	l, 1
	ld	xde, 3262
	stib_ind 0x07, 0xe8, 0xec, 0x05	; ld (XDE+HL),0x05
	pop	xhl
	pop	xde
ToneParam_Evt09_BytecodeHandler_Loop13:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Skip25
	incw	1, (3652:16)
ToneParam_Evt09_BytecodeHandler_Skip25:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop13
	call	VoiceSlot_FlagCheck
	cp	a, 132
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip26
	ld	wa, (3652:16)
	cp wa, (3435:16)
	jrl	c, ToneParam_Evt09_BytecodeHandler_Loop12
	dec	1, wa
	ld	(3435:16), wa
	jp	ToneParam_HandlerTable_BC_0x41C
ToneParam_Evt09_BytecodeHandler_Skip26:
	ldw	(3435:16), 0xffff
ToneParam_Evt09_BytecodeHandler_Skip27:
	ld	a, (3654:16)
	ld	(3822:16), a
	ret
	xor	a, a
	call	VoiceSlot_SaveState
	call	VoiceSlot_DispatchRet
	xor	a, a
	call	VoiceSlot_RestoreState
	ld	w, (3532:16)
	call	VoiceSlot_RetZ
	ret
	ordi8	(0xe3e2), 8
	ldw_d16	hl, (0x0d5a)
ToneParam_Evt09_BytecodeHandler_Loop14:
	push	xhl
	call	AccPedal_CheckBitAndUpdate
ToneParam_Evt09_BytecodeHandler_Loop15:
	call	Timer_ParamCompareAlt
	xor	a, a
	cp	(3415:16), a
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop15
	cp	(3420:16), a
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop15
	pop	xhl
	cpdi16	(0x0d5a), 0
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip28
	cp hl, (3418:16)
	jrl	z, ToneParam_Evt09_BytecodeHandler_Loop14
ToneParam_Evt09_BytecodeHandler_Skip28:
	resda	2, (0x0d54)
	ld	(3413:16), 255
	ret
	ordi8	(0xe3e2), 8
	call	AccPedal_CheckBitAndUpdate
	cp	w, 255
	jrl	z, ToneParam_Evt09_BytecodeHandler_Return
	ld	l, (3421:16)
	sub	l, (3420:16)
	xor	h, h
	ld	(3533:16), hl
	ld	(3534:16), 0
	ld	(0x7f42:16), 255
	call	DisplayMode_Handler_3_0x30C
	resda	2, (0x0d54)
	ld	(3413:16), 255
ToneParam_Evt09_BytecodeHandler_Return:
	ret
	call	Display_UpdateRegion0
	call	Display_UpdateRegion1
	call	Display_UpdateRegion4
	call	Display_UpdateRegion3
	call	Display_UpdateRegion2
	ret
	cp	c, 0:i3
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip30
ToneParam_Evt09_BytecodeHandler_Loop16:
	pushw	bc
	call	VoiceSlot_ReadCurrentParams
	cp	a, 130
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip31
	cp	a, 132
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip31
	cpdi8	(0x0dcf), 0
	jrl	z, ToneParam_Evt09_BytecodeHandler_Skip29
	call	VoiceSlot_CompareAndBranch_0x7
	jp	ToneParam_HandlerTable_BC_0x5A6
ToneParam_Evt09_BytecodeHandler_Skip29:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, ToneParam_Evt09_BytecodeHandler_Epilogue2
	call	VoiceSlot_ReadCurrentParams
	popw	bc
	cp	a, 129
	jrl	nz, ToneParam_Evt09_BytecodeHandler_Loop16
	djnz16	bc, -57
ToneParam_Evt09_BytecodeHandler_Skip30:
	ld	w, 0:opc
	jp	ToneParam_HandlerTable_BC_0x5C3
ToneParam_Evt09_BytecodeHandler_Skip31:
	ld	w, 0:opc
ToneParam_Evt09_BytecodeHandler_Epilogue2:
	popw	bc
	ret
ToneEvt_Handler_Mode9:
	bit	7, w
	jrl	nz, ToneEvt_Handler_Mode9_Return
	call	ToneEvt_Handler_ModeSingle
	call	DisplayMode_Handler_3_0x3F
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
	call ToneParam_HandlerTable_BC_0x4DC
PeriphReg_LoadWordAndCall:
	ld	w, (3538:16)
	ld xiy, 0x00000d8f
	call SysInit_BytecodeBlock_0x486
	call Display_ModeHandler
PeriphReg_Ret:
	ret
; Display mode handler
Display_ModeHandler:
	or	(3539:16), 1
	xor	a, a
	ld	(3538:16), a
	ld	(3413:16), 255
	call VoiceState_DataBlock2_0x10C
	cp w, 0:i3
	jrl	nz, DisplayMode_Handler_3_Skip
	ld	l, (3429:16)
	and l, 0x03
	xor	h, h
	sla hl, 2
	push xix
	ld xix, DisplayMode_DispatchTable
	ld_rrl	xhl, xix, hl
	pop xix
	call	(xhl)
	ret


	; Handler dispatch table, 16 B.  Read by Display_ModeHandler (0xEF87A3): `ld xix, DisplayMode_DispatchTable`
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
	call	DisplayStr_TempoString_0x32
	ret
DisplayMode_Handler_3:
	ld	(3567:16), 15
	call	DisplayStr_TempoString_0x6F
	ld	(0x3728:16), 0
	call	DisplayStr_StyleSectionInit
	ret
DisplayMode_Handler_3_Skip:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, DisplayMode_Handler_3_Skip15
	cp	a, 130
	jrl	z, DisplayMode_Handler_3_Skip15
	call	VoiceSlot_FlagCheck
	cp	a, (0x0d57:16)
	jrl	ugt, DisplayMode_Handler_3_Skip15
	call	DMA_FlagCheckWithCalls
	jp	DisplayMode_Handler_3_0x3A
DisplayMode_Handler_3_Skip15:
	call	DisplayMode_Handler_3_0x775
	resda	2, (0x0d54)
	ret
	push	xiy
	ld	(xiy), 84
	ldw	(xiy+1), 16722
	ldw	(xiy+3), 19267
	pop	xiy
	ret
	push	xiy
	ld	(xiy), 32
	ldw	(xiy+1), 8224
	ldw (xiy+3), 8224
	pop	xiy
	ret
	ordi8	(0x0dd3), 1
	call	VoiceSlot_ReadCurrentParams
	ld	w, a
	and	w, 240
	cp	w, 128
	jrl	z, DisplayMode_Handler_3_Skip16
	ld	a, w
DisplayMode_Handler_3_Skip16:
	ld	(3537:16), a
DisplayMode_Handler_3_Loop4:
	call	VoiceState_DataBlock2_0x1CB
	ld	e, a
	and	e, 240
	cpdi8	(0x0d55), 255
	jrl	z, DisplayMode_Handler_3_Skip33
	cp	(3413:16), a
	jrl	z, DisplayMode_Handler_3_Skip34
	cpdi8	(0x0d55), 210
	jrl	z, DisplayMode_Handler_3_Skip35
DisplayMode_Handler_3_Loop5:
	call	VoiceState_DataBlock2_0x1A6
	call	VoiceState_DataBlock2_0x1D8
	cp	w, 255
	jrl	nz, DisplayMode_Handler_3_Loop4
	bitda	4, (0x0d53)
	jrl	nz, DisplayMode_Handler_3_Next
DisplayMode_Handler_3_Next:
	anddi8	(0x0d53), 239
	cpdi8	(0x0d55), 255
	jrl	nz, DisplayMode_Handler_3_Next2
DisplayMode_Handler_3_Next2:
	jp	DisplayMode_Handler_3_0x168
DisplayMode_Handler_3_Skip35:
	cp	a, 209
	jrl	z, DisplayMode_Handler_3_Skip34
	jp	DisplayMode_Handler_3_0x99
DisplayMode_Handler_3_Skip33:
	cp a, (3536:16)
	jrl	z, DisplayMode_Handler_3_Loop5
	ld	(3536:16), 255
DisplayMode_Handler_3_Skip34:
	cp	a, 209
	jrl	z, DisplayMode_Handler_3_Skip36
	cp	a, 210
	jrl	z, DisplayMode_Handler_3_Skip37
	cp	a, 128
	jrl	z, DisplayMode_Handler_3_Skip5
	cp	a, 133
	jrl	z, DisplayMode_Handler_3_Skip6
	cp	a, 134
	jrl	z, DisplayMode_Handler_3_Skip7
	cp	e, 144
	jrl	z, DisplayMode_Handler_3_Skip2
	cp	e, 176
	jrl	z, DisplayMode_Handler_3_Skip3
	cp	e, 192
	jrl	z, DisplayMode_Handler_3_Skip4
DisplayMode_Handler_3_Loop:
	call	VoiceState_DataBlock2_0x1A6
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip2:
	call	DisplayMode_Handler_3_0x169
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip3:
	call	VoiceCtrl_ParamSetupBytecode
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip4:
	call	VoiceCtrl_ParamSetupBytecode_0x399
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip5:
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, DisplayMode_Handler_3_Loop
	call	VoiceCtrl_ParamSetupBytecode_0x4DE
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip6:
	call	VoiceCtrl_ParamSetupBytecode_0x56C
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip7:
	call	VoiceCtrl_ParamSetupBytecode_0x560
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip36:
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, DisplayMode_Handler_3_Loop
	call	SerialPort_ModeHandler_0_0x5
	jp	DisplayMode_Handler_3_0x9D
DisplayMode_Handler_3_Skip37:
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, DisplayMode_Handler_3_Loop
	call	SerialPort_ModeHandler_0_0x71
	jp	DisplayMode_Handler_3_0x9D
	ret
	call	ScoopParam_ValueTable_0x84
	cpdi8	(0x0d65), 1
	jrl	z, DisplayMode_Handler_3_Skip17
	call	TempoRingBuf_ReadByte
	ld	wa, hl
DisplayMode_Handler_3_Loop3:
	jp	DisplayMode_Handler_3_0x26B
DisplayMode_Handler_3_Skip17:
	call	DisplayMode_Handler_3_0x26C
	bitda	1, (0x0d54)
	jrl	z, DisplayMode_Handler_3_Loop3
	call	SerialPort_ModeHandler_0_0x113
	resda	1, (0x0d54)
	ld	e, (3541:16)
	xor	d, d
	ld	xiy, 3542
	xor	hl, hl
	ld	xix, 3471
DisplayMode_Handler_3_Loop2:
	ld	a, (3558:16)
	ld	(xix), a
	ld	a, (3415:16)
	ld	(xix+1), a
	ld_rrb	a, xiy, hl
	ld	(xix+2), a
	pushw	wa
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	popw	wa
	push	xix
	ld	xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf8, 0x0c	; cp (XIX+IZ),0x0c
	pop	xix
	jrl	nz, DisplayMode_Handler_3_Skip19
	bitda	2, (0xfdad)
	jrl	z, DisplayMode_Handler_3_Skip18
	jp	DisplayMode_Handler_3_0x1E5
DisplayMode_Handler_3_Skip18:
	ld	w, (0xfb3c:16)
	call	ScoopDisp_BytecodeBlock1_0x32
DisplayMode_Handler_3_Skip19:
	ld	(0x3718:16), a
	ldfr_lerp xiy, 56
	lda_rr xiy, xiy, hl
	ld a, (xiy+8)
	ldto_lerp xiy, 56
	ld	(xix+3), a
	ld	(0x3717:16), a
	ld	a, (0x342d:16)
	ld	(xix+4), a
	ld	a, (0x342e:16)
	ld	(xix+5), a
	add	ix, 6
	inc	1, hl
	cp	hl, de
	jrl	nz, DisplayMode_Handler_3_Loop2
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
	call	SysInit_BytecodeBlock_0x486
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ld	(3541:16), 0
	call	VoiceState_DataBlock2_0x10C
	cp	w, 0:i3
	jrl	nz, DisplayMode_Handler_3_Skip20
	cp	c, 6:i3
	jrl	ugt, DisplayMode_Handler_3_Skip20
	call	ScoopParam_ValueTable_0x1C
	call	SerialPort_ModeHandler_0_0xEA
	ld	(3422:16), 16
	jp	DisplayMode_Handler_3_0x26B
DisplayMode_Handler_3_Skip20:
	ld	(3923:16), 0
	call	DisplayMode_Handler_3_0x308
	resda	2, (0x0d54)
	ret
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(3558:16), a
	call	TempoRingBuf_ReadByte
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(0x342d:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(0x342e:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	cpdi8	(0x342e), 0
	jrl	nz, DisplayMode_Handler_3_Skip21
	jp	DisplayMode_Handler_3_0x2E9
DisplayMode_Handler_3_Skip21:
	anddi8	(0x0dd3), 254
	push	xhl
	push	xiy
	ld	l, (3540:16)
	cp	l, 7:i3
	jrl	ugt, DisplayMode_Handler_3_Skip22
	xor	h, h
	ld	xiy, 3542
	ld	a, (0x342d:16)
	st_rrb a, xiy, hl
	ld a, (13358:16)
	ldfr_lerp xiy, 56
	lda_rr xiy, xiy, hl
	ld (xiy+8), a
	ldto_lerp xiy, 56
	inc 1, l
	ld (3540:16), l
	cp l, (3541:16)
	jrl	ule, DisplayMode_Handler_3_Skip22
	ld	(3541:16), l
DisplayMode_Handler_3_Skip22:
	pop	xiy
	pop	xhl
	jp	DisplayMode_Handler_3_0x307
	ld	a, (3540:16)
	dec	1, a
	cp	a, 255
	jrl	z, DisplayMode_Handler_3_Return4
	ld	(3540:16), a
	cp	a, 0:i3
	jrl	nz, DisplayMode_Handler_3_Return4
	setda	1, (0x0d54)
	ordi8	(0x0dd3), 1
DisplayMode_Handler_3_Return4:
	ret
	call	ScoopParam_ValueTable_0x29
	ld	l, (3533:16)
	xor	h, h
	add hl, (3418:16)
	cp hl, (3418:16)
	jrl	z, DisplayMode_Handler_3_Skip23
	push	xhl
	call	Timer_ParamLoadAndCompare
	pop	xhl
	cpdi8	(0x7f42), 15
	jrl	z, DisplayMode_Handler_3_Skip25
	jp	DisplayMode_Handler_3_0x316
DisplayMode_Handler_3_Skip23:
	ld	l, (3534:16)
	anddi8	(0x0d53), 251
	ld	h, (3415:16)
	cp	h, 0:i3
	jrl	nz, DisplayMode_Handler_3_Skip24
	bitda	2, (0x0d53)
	jrl	z, DisplayMode_Handler_3_Skip24
	ld	h, 96:opc
DisplayMode_Handler_3_Skip24:
	cp	l, h
	jrl	le, DisplayMode_Handler_3_Skip25
	push	xhl
	call	Timer_ParamLoadAndCompare
	pop	xhl
	jp	DisplayMode_Handler_3_0x338
DisplayMode_Handler_3_Skip25:
	cp	h, 96
	jrl	nz, DisplayMode_Handler_3_Skip26
	decw	1, (3418:16)
	push	xhl
	call	VoiceSlot_CompareAndBranch_0x7
	call	AccPedal_CheckBitAndUpdate
	pop	xhl
DisplayMode_Handler_3_Skip26:
	ld	(3415:16), l
	ret
	; Entry 1 of PerfMode_EventTable_0 (a code pointer the table holds).
PerfMode_EventTable_0_Target1:
	bit	7, w
	jrl	nz, DisplayMode_Handler_3_Skip8
	call	DisplayMode_Handler_3_0x385
	jp	DisplayMode_Handler_3_0x384
DisplayMode_Handler_3_Skip8:
	call	DisplayMode_Handler_3_0x38F
	ret
	ld	(3570:16), 1
	call	DisplayMode_Handler_3_0x399
	ret
	ld	(3570:16), 255
	call	DisplayMode_Handler_3_0x399
	ret
	call	VoiceState_DataBlock2_0x10C
	cp	w, 0:i3
	jrl	z, DisplayMode_Handler_3_Return5
	cpdi8	(0x0d65), 1
	jrl	nz, DisplayMode_Handler_3_Return5
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 144
	jrl	nz, DisplayMode_Handler_3_Return5
	call	VoiceSlot_FlagCheck
	cp a, (3415:16)
	jrl nz, DisplayMode_Handler_3_Return5
	xor a, a
	call	VoiceSlot_SaveState
	ld	de, 2:i3
	call	VoiceSlot_FinalRetZ_0xB8
	call	VoiceSlot_ReadCurrentParams
	call	DisplayMode_Handler_3_0x435
	ld	w, a
	ld	l, w
	add	a, (3570:16)
	bit	7, a
	jrl	z, DisplayMode_Handler_3_Skip27
	ld	a, w
DisplayMode_Handler_3_Skip27:
	ld	(0x3718:16), a
	pushw	hl
	call	DisplayMode_Handler_3_0x462
	popw	hl
	call	VoiceSlot_ComputeWordIndex
	sra	iz, 1
	push	xde
	ld	xde, 0xf1a0
	cpib_sri 0x07, 0xe8, 0xf8, 0x0c	; cp (XDE+IZ),0x0c
	pop	xde
	jrl	nz, DisplayMode_Handler_3_Skip28
	bitda	2, (0xfdad)
	jrl	z, DisplayMode_Handler_3_Skip28
	cp	a, 0:i3
	jrl	nz, DisplayMode_Handler_3_Skip28
	ld	(0x3718:16), l
	jp	DisplayMode_Handler_3_0x421
DisplayMode_Handler_3_Skip28:
	ld	w, a
	call	VoiceSlot_FinalRetZ_0x84
	xor	a, a
	call	VoiceSlot_RestoreState
	call	Disp_ShowNoteNameAndVelocity
	ordi8	(0xe3e2), 8
	call	Display_UpdateRegion3
DisplayMode_Handler_3_Return5:
	ret
	pushw	wa
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	popw	wa
	push	xix
	ld	xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf8, 0x0c	; cp (XIX+IZ),0x0c
	pop	xix
	jrl	nz, DisplayMode_Handler_3_Return6
	bitda	2, (0xfdad)
	jrl	z, DisplayMode_Handler_3_Skip29
	jp	DisplayMode_Handler_3_0x461
DisplayMode_Handler_3_Skip29:
	ld	w, (0xfb3c:16)
	call	ScoopDisp_BytecodeBlock1_0x32
DisplayMode_Handler_3_Return6:
	ret
	pushw	wa
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	popw	wa
	push	xix
	ld	xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf8, 0x0c	; cp (XIX+IZ),0x0c
	pop	xix
	jrl	nz, DisplayMode_Handler_3_Return7
	bitda	2, (0xfdad)
	jrl	z, DisplayMode_Handler_3_Skip30
	jp	DisplayMode_Handler_3_0x48E
DisplayMode_Handler_3_Skip30:
	ld	w, (0xfb3c:16)
	call	ScoopDisp_BytecodeBlock1_0x4D
DisplayMode_Handler_3_Return7:
	ret
	ldw	(3824:16), 1
	ld	(3571:16), 2
	call	DisplayMode_Handler_3_0x4C9
	call	Display_BytecodeBlock_F_0x2A2
	call	Display_UpdateRegion3
	ordi8	(0xe3e2), 8
	ret
	stdi16	(0x0ef0), 65535
	ld	(3571:16), 2
	call	DisplayMode_Handler_3_0x4C9
	call	Display_BytecodeBlock_F_0x2A2
	call	Display_UpdateRegion3
	ordi8	(0xe3e2), 8
	ret
	call	VoiceState_DataBlock2_0x10C
	cp	w, 0:i3
	jrl	z, DisplayMode_Handler_3_Return
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 128
	jrl	nz, DisplayMode_Handler_3_Return
	xor	a, a
	call	VoiceSlot_SaveState
	ld	e, (3571:16)
	xor	d, d
	call	VoiceSlot_FinalRetZ_0xB8
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
	add wa, (3824:16)
	cp wa, 40
	jrl	nc, DisplayMode_Handler_3_Skip9
	ld	wa, bc
	jp	DisplayMode_Handler_3_0x52C
DisplayMode_Handler_3_Skip9:
	cp	wa, 300
	jrl	ule, DisplayMode_Handler_3_Skip10
	ld	wa, bc
DisplayMode_Handler_3_Skip10:
	ld	(3826:16), wa
	ld	bc, wa
	and	a, 127
	ld	w, a
	pushw	bc
	call	VoiceSlot_FinalRetZ_0x84
	call	VoiceSlot_FinalRetZ
	popw	bc
	ld	a, c
	and	a, 128
	rlc	a
	and	b, 1
	sla	b, 1
	or	a, b
	ld	w, a
	call	VoiceSlot_FinalRetZ_0x84
	xor	a, a
	call	VoiceSlot_RestoreState
DisplayMode_Handler_3_Return:
	ret
	ld	(3570:16), 1
	ld	(3571:16), 2
	call	VoiceSlot_ReadCurrentParams
	ld	l, a
	and	a, 240
	cp	a, 208
	jrl	nz, DisplayMode_Handler_3_Return8
	pushw	hl
	call	VoiceSlot_FlagCheck
	popw	hl
	cp a, (3415:16)
	jrl nz, DisplayMode_Handler_3_Return8
	push xhl
	ld	xhl, 0x3721
	ld	(4366:16), xhl
	pop	xhl
	cp	l, 210
	jrl	nz, DisplayMode_Handler_3_Skip31
	call	DisplayMode_Handler_3_0x6DF
	jp	DisplayMode_Handler_3_0x5A1
DisplayMode_Handler_3_Skip31:
	call	DisplayMode_Handler_3_0x6A1
	call	Display_BytecodeBlock_F_0x17C
	call	Display_UpdateRegion3
	ordi8	(0xe3e2), 8
DisplayMode_Handler_3_Return8:
	ret
	stdi8	(0x0df2), 255
	ld	(3571:16), 2
	call	VoiceSlot_ReadCurrentParams
	ld	l, a
	and	a, 240
	cp	a, 208
	jrl	nz, DisplayMode_Handler_3_Return9
	pushw	hl
	call	VoiceSlot_FlagCheck
	popw	hl
	cp a, (3415:16)
	jrl nz, DisplayMode_Handler_3_Return9
	push xhl
	ld	xhl, 0x3721
	ld	(4366:16), xhl
	pop	xhl
	cp	l, 210
	jrl	nz, DisplayMode_Handler_3_Skip11
	call	DisplayMode_Handler_3_0x6DF
	jp	DisplayMode_Handler_3_0x5F2
DisplayMode_Handler_3_Skip11:
	call	DisplayMode_Handler_3_0x6A1
	call	Display_BytecodeBlock_F_0x17C
	call	Display_UpdateRegion3
	ordi8	(0xe3e2), 8
DisplayMode_Handler_3_Return9:
	ret
	; Entry 2 of PerfMode_EventTable_0 (a code pointer the table holds).
PerfMode_EventTable_0_Target2:
	bit	7, w
	jrl	nz, DisplayMode_Handler_3_Skip32
	call	DisplayMode_Handler_3_Helper
	jp	DisplayMode_Handler_3_0x612
DisplayMode_Handler_3_Skip32:
	call	DisplayMode_Handler_3_0x65A
	ret
DisplayMode_Handler_3_Helper:
	ld	(3570:16), 1
	ld	(3571:16), 3
	cpdi8	(0x0d65), 1
	jrl	nz, DisplayMode_Handler_3_Return10
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 144
	jrl	nz, DisplayMode_Handler_3_Return10
	call	VoiceSlot_FlagCheck
	cp a, (3415:16)
	jrl nz, DisplayMode_Handler_3_Return10
	push xhl
	ld	xhl, 0x3717
	ld	(4366:16), xhl
	pop	xhl
	call	DisplayMode_Handler_3_0x6A1
	call	Disp_ShowNoteNameAndVelocity
	ordi8	(0xe3e2), 8
	call	Display_UpdateRegion3
DisplayMode_Handler_3_Return10:
	ret
	ld	(3570:16), 255
	ld	(3571:16), 3
	cpdi8	(0x0d65), 1
	jrl	nz, DisplayMode_Handler_3_Return11
	call	VoiceSlot_ReadCurrentParams
	and	a, 240
	cp	a, 144
	jrl	nz, DisplayMode_Handler_3_Return11
	call	VoiceSlot_FlagCheck
	cp a, (3415:16)
	jrl nz, DisplayMode_Handler_3_Return11
	push xhl
	ld	xhl, 0x3717
	ld	(4366:16), xhl
	pop	xhl
	call	DisplayMode_Handler_3_0x6A1
	call	Disp_ShowNoteNameAndVelocity
	ordi8	(0xe3e2), 8
	call	Display_UpdateRegion3
DisplayMode_Handler_3_Return11:
	ret
	call	VoiceState_DataBlock2_0x10C
	cp	w, 0:i3
	jrl	z, DisplayMode_Handler_3_Return2
	xor	a, a
	call	VoiceSlot_SaveState
	ld	e, (3571:16)
	xor	d, d
	call	VoiceSlot_FinalRetZ_0xB8
	call	VoiceSlot_ReadCurrentParams
	ld	w, a
	add	a, (3570:16)
	bit	7, a
	jrl	z, DisplayMode_Handler_3_Skip12
	ld	a, w
DisplayMode_Handler_3_Skip12:
	ld	xhl, (4366:16)
	ld	(xhl), a
	ld	w, a
	call	VoiceSlot_FinalRetZ_0x84
	xor	a, a
	call	VoiceSlot_RestoreState
DisplayMode_Handler_3_Return2:
	ret
	call	VoiceState_DataBlock2_0x10C
	cp	w, 0:i3
	jrl	z, DisplayMode_Handler_3_Return3
	xor	a, a
	call	VoiceSlot_SaveState
	ld	e, (3571:16)
	xor	d, d
	call	VoiceSlot_FinalRetZ_0xB8
	call	VoiceSlot_ReadCurrentParams
	ld	(0x3721:16), a
	call	VoiceSlot_FlagCheck
	ld	(4370:16), a
	ld	w, a
	ld	a, (0x3721:16)
	and	a, 127
	and	w, 127
	rrc	w
	ld	e, w
	and	w, 127
	and	e, 128
	or	a, e
	ld	bc, wa
	xor	de, de
	ld	e, (3570:16)
	exts	de
	add	wa, de
	cp	wa, 0x3fff
	jrl	gt, DisplayMode_Handler_3_Skip14
	cp	wa, 0:i3
	jrl	lt, DisplayMode_Handler_3_Skip14
	bit	7, w
	jrl	z, DisplayMode_Handler_3_Skip13
	ld	wa, bc
DisplayMode_Handler_3_Skip13:
	ld	bc, wa
	and	a, 127
	ld	(0x3721:16), a
	rlc	c
	and	c, 1
	sla	w, 1
	and	w, 126
	or	c, w
	ld	(4370:16), c
	ld	w, a
	pushw	bc
	call	VoiceSlot_FinalRetZ_0x84
	call	VoiceSlot_FinalRetZ
	popw	bc
	ld	w, c
	call	VoiceSlot_FinalRetZ_0x84
DisplayMode_Handler_3_Skip14:
	xor	a, a
	call	VoiceSlot_RestoreState
DisplayMode_Handler_3_Return3:
	ret
	bitda	0, (0x0f57)
	jrl	nz, DisplayMode_Handler_3_Return12
	ld	l, (3429:16)
	and	l, 3
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, DMA_ChannelSelect_Table
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
DisplayMode_Handler_3_Return12:
	ret


	; Handler dispatch table, 16 B.  Read by PerfMode_EventTable_0_Target2 (0xEF8DFB): `ld xix, DMA_ChannelSelect_Table`
	; indexed with stride 4 (`sla hl, 2`), index from `ld l, (3429:16)`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
DMA_ChannelSelect_Table:
	.long	DMA_ChannelHandler_0
	.long	DMA_ChannelHandler_1
	.long	DMA_ChannelHandler_2
	.long	DMA_ChannelHandler_3
DMA_ChannelHandler_1:
	ld	(0x3717:16), 255
	cpdi8	(0x0def), 0
	jrl	nz, DMA_ChannelHandler_1_Skip
	call	Display_BytecodeBlock_F_0x4
	jp	DMA_ChannelHandler_1_0x1E
DMA_ChannelHandler_1_Skip:
	ld	(3567:16), 0
	call	Display_BytecodeBlock_F
	ret
DMA_ChannelHandler_2:
	cpdi8	(0x0def), 8
	jrl	nz, DMA_ChannelHandler_2_Skip
	call	DisplayStr_TempoString_0x36
	jp	DMA_ChannelHandler_2_0x19
DMA_ChannelHandler_2_Skip:
	ld	(3567:16), 8
	call	DisplayStr_TempoString_0x32
	ret
DMA_ChannelHandler_0:
	ld	(0x3728:16), 0
	call	DisplayStr_BytecodeBlock_E_0x1
	ret
DMA_ChannelHandler_3:
	; --- Conditional init (31 bytes) ---
	cp	(3567:16), 15
	jrl z, DMA_Channel3_CallAndInit
	ld	(3567:16), 15
	call DisplayStr_TempoString_0x6F
DMA_Channel3_CallAndInit:
	call DisplayStr_TempoString_0x74
	ld	(0x3728:16), 0
	call DisplayStr_StyleSectionInit
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
	bitda	0, (0x0dd3)
	jrl	z, VoiceSlot_TableSetup_Skip
	jp	VoiceSlot_TableSetup_0xF
VoiceSlot_TableSetup_Skip:
	jp	VoiceSlot_TableSetup_0x106
	anddi8	(0x0dd3), 254
	call	AccPedal_CheckBitAndUpdate
	call	VoiceState_DataBlock2_0x472
	xor	a, a
	call	VoiceSlot_SaveState
	call	VoiceSlot_TableSetup_0x107
	ld	(3535:16), 1
	call	ToneParam_HandlerTable_BC_0x57C
	call	VoiceState_DataBlock2_0xAD
	cp	w, 0:i3
	jrl	nz, VoiceSlot_TableSetup_Skip2
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceSlot_TableSetup_Code_Skip
	dec	1, (3559:16)
	jp	VoiceSlot_TableSetup_0x66
VoiceSlot_TableSetup_Skip2:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceSlot_TableSetup_Code_Skip
	call	VoiceSlot_DispatchRet
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceSlot_TableSetup_Code_Skip
	dec	1, (3559:16)
VoiceSlot_TableSetup_Code_Skip:
	ld	a, (3822:16)
	dec	1, a
	xor	w, w
	ld	hl, wa
	push	xix
	ld	xix, 3262
	ld_rrb	a, xix, hl
	stb_d8	(0x0dec), a
	sla	hl, 1
	ld	xix, 0x0c9e
	ld_rrw wa, xix, hl
	ld (3560:16), wa
	pop	xix
	ld	c, (3559:16)
	xor	b, b
	ld	(3535:16), 0
	call	ToneParam_HandlerTable_BC_0x57C
	ld	a, (3822:16)
	dec	1, a
	xor	w, w
	ld	hl, wa
	push	xix
	ld	xix, 3262
	ld_rrb	a, xix, hl
	stb_d8	(0x0ded), a
	sla	hl, 1
	ld	xix, 0x0c9e
	ld_rrw wa, xix, hl
	ld (3562:16), wa
	pop	xix
	call	VoiceSlot_TableSetup_0x12C
	call	DisplayStr_StyleSectionNames_0x69
	call	Display_UpdateRegion5
	ld	wa, (0x371a:16)
	cp	wa, 1000
	jrl	c, VoiceSlot_TableSetup_Skip3
	ldw	wa, 1000
VoiceSlot_TableSetup_Skip3:
	ld	(3662:16), wa
	xor	a, a
	call	VoiceSlot_RestoreState
	call	VoiceSlot_TableSetup_0x2E0
	call	VoiceSlot_TableSetup_0x40F
	call	Display_UpdateRegion1
	bitda	0, (0x0f57)
	jrl	nz, VoiceSlot_TableSetup_0x106
	call	Display_UpdateRegion4
	ret
	ld	c, (3420:16)
	ld	a, (3421:16)
	cp	a, 4:i3
	jrl	ugt, VoiceSlot_TableSetup_Skip4
	jp	VoiceSlot_TableSetup_0x127
VoiceSlot_TableSetup_Skip4:
	sub	a, 4
	cp	c, 3:i3
	jrl	ugt, VoiceSlot_TableSetup_Skip5
	jp	VoiceSlot_TableSetup_0x127
VoiceSlot_TableSetup_Skip5:
	sub	c, 4
	inc	1, c
	xor	b, b
	ret
	ld	wa, (3560:16)
	ld	l, (3822:16)
	dec	1, l
	xor	h, h
	sla	hl, 1
	push	xde
	ld	xde, 3230
	st_rrw wa, xde, hl
	ld	a, (3564:16)
	srl	hl, 1
	ld	xde, 3262
	st_rrb a, xde, hl
	pop xde
	ld xix, 14130
	push	xix
	ld	xix, 0x372e
	xor	wa, wa
	ld	(xix), wa
	ld	(xix+2), wa
	ld	(xix+4), wa
	ld	(xix+6), wa
	ld	(xix+8), wa
	ld	(xix+10), wa
	ld	(3930:16), a
	ld	(3931:16), a
	add	xix, 4
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceSlot_TableSetup_Code_Skip3
	ld	l, (3822:16)
	dec	1, l
	xor	h, h
	sla	hl, 1
	push	xde
	ld	xde, 3230
	ld_rrw wa, xde, hl
	pop	xde
	cp wa, (3562:16)
	jrl	nz, VoiceSlot_TableSetup_Code_Skip3
	srl	hl, 1
	push	xde
	ld	xde, 3262
	ld_rrb a, xde, hl
	pop	xde
	cp	a, (0x0ded:16)
	jrl	nz, VoiceSlot_TableSetup_Code_Skip3
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	nz, VoiceSlot_TableSetup_Code_Epilogue
	ld	xwa, xix
	sub	xwa, 0x3732
	cp	wa, 1:i3
	jrl	ugt, VoiceSlot_TableSetup_Skip6
	ld	wa, 1:i3
VoiceSlot_TableSetup_Skip6:
	sla	wa, 3
	cp	a, 1:i3
	jrl	z, VoiceSlot_TableSetup_Skip7
	inc	1, a
VoiceSlot_TableSetup_Skip7:
	ld	(3931:16), a
	ld	(3930:16), 2
	jp	VoiceSlot_TableSetup_0x2DE
VoiceSlot_TableSetup_Code_Loop:
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	push	xde
	ld	xde, 3262
	ld_rrb a, xde, iz
	pop xde
	push	xix
	call	VoiceSlot_DispatchRet
	pop	xix
	cp	w, 0:i3
	jrl	nz, VoiceSlot_TableSetup_Code_Epilogue
	ld	l, (3822:16)
	dec	1, l
	xor	h, h
	sla	hl, 1
	push	xde
	ld	xde, 3230
	ld_rrw wa, xde, hl
	pop	xde
	cp wa, (3562:16)
	jrl	nz, VoiceSlot_TableSetup_Code_Skip3
	srl	hl, 1
	push	xde
	ld	xde, 3262
	ld_rrb a, xde, hl
	pop	xde
	cp	a, (0x0ded:16)
	jrl	nz, VoiceSlot_TableSetup_Code_Skip3
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	nz, VoiceSlot_TableSetup_Code_Epilogue
	ld	xwa, xix
	sub	xwa, 0x3732
	push	xwa
	pushw	bc
	call	VoiceState_DataBlock2_0x10C
	ld	h, w
	ld	l, c
	popw	bc
	pop	xwa
	cp	h, 255
	jrl	z, VoiceSlot_TableSetup_Code_Epilogue
	cp	l, 2:i3
	jrl	nz, VoiceSlot_TableSetup_Code_Skip2
	inc	1, wa
VoiceSlot_TableSetup_Code_Skip2:
	sla	wa, 3
	inc	1, a
	ld	(3931:16), a
	ld	(3930:16), 2
	jp	VoiceSlot_TableSetup_0x2DE
VoiceSlot_TableSetup_Code_Skip3:
	call	VoiceSlot_ReadCurrentParams
	cp	w, 0:i3
	jrl	nz, VoiceSlot_TableSetup_Code_Epilogue
	call	VoiceSlot_StatusCheck
	cp	w, 0:i3
	jrl	nz, VoiceSlot_TableSetup_Code_Loop
	cp	a, 130
	jrl	nz, VoiceSlot_TableSetup_Code_Skip4
	ld	xwa, xix
	sub	xwa, 0x3732
	sla	wa, 3
	ld	(3931:16), a
	ld	(3930:16), 2
VoiceSlot_TableSetup_Code_Skip4:
	cp	a, 132
	jrl	z, VoiceSlot_TableSetup_Code_Epilogue
	cp	a, 129
	jrl	z, VoiceSlot_TableSetup_Code_Skip5
	call	VoiceSlot_FlagCheck
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	ld	c, a
	pop	xix
	ldfr_berp a, 60
	ld a, c
	scf
	stcf	a, (xix)
	ldto_berp a, 60
	push	xix
	jp	VoiceSlot_TableSetup_0x1F2
VoiceSlot_TableSetup_Code_Skip5:
	pop	xix
	inc	1, xix
	push	xix
	jp	VoiceSlot_TableSetup_0x1F2
VoiceSlot_TableSetup_Code_Epilogue:
	pop	xix
	ret
	ld	l, (3424:16)
	dec	1, l
	ld	h, l
	sla	l, 1
	add	l, h
	xor	h, h
	push	xde
	ld	xde, 0xf250
	bit_dri 7, 0x07, 0xe8, 0xec	; bit 7,(XDE+HL)
	pop	xde
	jrl	nz, VoiceSlot_TableSetup_Skip8
	xor	wa, wa
	ld	(3660:16), wa
	ld	(3666:16), a
	jp	VoiceSlot_TableSetup_0x40E
VoiceSlot_TableSetup_Skip8:
	cpdi16	(0x371a), 1
	jrl	z, VoiceSlot_TableSetup_Skip11
	cpdi8	(0x0d5c), 4
	jrl	c, VoiceSlot_TableSetup_Skip9
	ld	wa, (0x371a:16)
	ld	(0x287f:16), wa
	call	SubCPU_ToneParamRet_0x315
	ld	a, (3424:16)
	call	SetWall_SlotResolve
	cpdi8	(0x287a), 0
	jrl	nz, VoiceSlot_TableSetup_Code_Return
	ld	(3666:16), 4
	ld	(0x28c1:16), iy
	ld	iy, (0x28af:16)
	ld	(0x28bf:16), iy
	ld	iy, (0x371a:16)
	cp	iy, 1000
	jrl	c, VoiceSlot_TableSetup_Code_Skip6
	ldw	iy, 1000
VoiceSlot_TableSetup_Code_Skip6:
	ld	(3660:16), iy
	jp	VoiceSlot_TableSetup_0x3FD
VoiceSlot_TableSetup_Skip9:
	ld	wa, (0x371a:16)
	dec	1, wa
	ld	(0x287f:16), wa
	call	SubCPU_ToneParamRet_0x315
	ld	a, (3424:16)
	call	SetWall_SlotResolve
	ld	(0x28c1:16), iy
	ld	iy, (0x28af:16)
	ld	(0x28bf:16), iy
	ld	iy, (0x287f:16)
	cp	iy, 1000
	jrl	c, VoiceSlot_TableSetup_Skip10
	ldw	iy, 1000
VoiceSlot_TableSetup_Skip10:
	ld	(3660:16), iy
	ld	(3666:16), a
	cp	a, 5:i3
	jrl	c, VoiceSlot_TableSetup_Skip13
	sub	a, 4
	ld	(3666:16), a
	call	SubCPU_ToneParamRet_0x354
	jp	VoiceSlot_TableSetup_0x3FD
VoiceSlot_TableSetup_Skip11:
	cpdi8	(0x0d5c), 3
	jrl	ugt, VoiceSlot_TableSetup_Skip12
	ldw	(3660:16), 0
	jp	VoiceSlot_TableSetup_0x40E
VoiceSlot_TableSetup_Skip12:
	ld	(3666:16), 4
	ld	wa, (0x371a:16)
	ld	(0x287f:16), wa
	call	SubCPU_ToneParamRet_0x315
	ld	a, (3424:16)
	call	SetWall_SlotResolve
	cpdi8	(0x287a), 0
	jrl	nz, VoiceSlot_TableSetup_Code_Return
	ld	(0x28c1:16), iy
	ld	iy, (0x28af:16)
	ld	(0x28bf:16), iy
	ld	iy, (0x371a:16)
	cp	iy, 1000
	jrl	c, VoiceSlot_TableSetup_Code_Entry
	ldw	iy, 1000
VoiceSlot_TableSetup_Code_Entry:
	stda16	(0x0e4c), iy
VoiceSlot_TableSetup_Skip13:
	ld	xix, 0x372e
	ld	a, (3666:16)
	ld	(3777:16), a
	call	VoiceState_DataBlock2_0x561
VoiceSlot_TableSetup_Code_Return:
	ret
	ld	l, (3424:16)
	dec	1, l
	ld	h, l
	sla	l, 1
	add	l, h
	xor	h, h
	push	xde
	ld	xde, 0xf250
	bit_dri 7, 0x07, 0xe8, 0xec	; bit 7,(XDE+HL)
	pop	xde
	jrl	nz, VoiceSlot_TableSetup_Skip14
	xor	wa, wa
	ld	(3664:16), wa
	ld	(3668:16), a
	jp	VoiceSlot_TableSetup_0x525
VoiceSlot_TableSetup_Skip14:
	cpdi8	(0x0d5c), 3
	jrl	ugt, VoiceSlot_TableSetup_Skip15
	cpdi8	(0x0d5d), 4
	jrl	ugt, VoiceSlot_TableSetup_Skip20
VoiceSlot_TableSetup_Skip15:
	ld	wa, (0x371a:16)
	inc	1, wa
	ld	(0x287f:16), wa
	cp	wa, 1000
	jrl	c, VoiceSlot_TableSetup_Skip16
	ldw	wa, 1000
VoiceSlot_TableSetup_Skip16:
	ld	(3664:16), wa
	call	SubCPU_ToneParamRet_0x315
	ld	a, (3822:16)
	call	SetWall_SlotResolve
	cpdi8	(0x287a), 0
	jrl	z, VoiceSlot_TableSetup_Code_Skip7
	call	SubCPU_ToneParamRet_0x315
	cp	w, 0:i3
	jrl	z, VoiceSlot_TableSetup_Skip17
	ld	a, w
	call	SetWall_SlotResolve
	cpdi8	(0x287a), 0
	jrl	nz, VoiceSlot_TableSetup_Skip17
	cp	a, 4:i3
	jrl	ule, VoiceSlot_TableSetup_Skip18
	ld	a, 4:opc
	jp	VoiceSlot_TableSetup_0x4A7
VoiceSlot_TableSetup_Skip17:
	ld	a, (3421:16)
	cpdi8	(0x0d5d), 4
	jrl	ule, VoiceSlot_TableSetup_Skip18
	ld	a, 4:opc
VoiceSlot_TableSetup_Skip18:
	ld	(3668:16), a
	jp	VoiceSlot_TableSetup_0x525
VoiceSlot_TableSetup_Code_Skip7:
	ld	(0x28c1:16), iy
	ld	iy, (0x28af:16)
	ld	(0x28bf:16), iy
	cp	a, 4:i3
	jrl	ule, VoiceSlot_TableSetup_Skip19
	ld	a, 4:opc
VoiceSlot_TableSetup_Skip19:
	ld	(3668:16), a
	jp	VoiceSlot_TableSetup_0x514
VoiceSlot_TableSetup_Skip20:
	ld	a, (3421:16)
	sub	a, 4
	ld	(3668:16), a
	ld	wa, (0x371a:16)
	ld	(0x287f:16), wa
	cp	wa, 1000
	jrl	c, VoiceSlot_TableSetup_Code_Skip8
	ldw	wa, 1000
VoiceSlot_TableSetup_Code_Skip8:
	ld	(3664:16), wa
	call	SubCPU_ToneParamRet_0x315
	ld	a, (3424:16)
	call	SetWall_SlotResolve
	cpdi8	(0x287a), 0
	jrl	nz, VoiceSlot_TableSetup_Code_Return2
	ld	(0x28c1:16), iy
	ld	iy, (0x28af:16)
	ld	(0x28bf:16), iy
	call	SubCPU_ToneParamRet_0x354
	cp	c, 4:i3
	jrl	nz, VoiceSlot_TableSetup_Code_Return2
	ld	a, (3668:16)
	stb_d8	(0x0ec1), a
	ld	xix, 0x3736
	call	VoiceState_DataBlock2_0x561
VoiceSlot_TableSetup_Code_Return2:
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
	ordi8	(0xe3e2), 8
	call	AccPedal_CheckBitAndUpdate
VoiceSlot_TableSetup_Code_Loop2:
	call	Timer_ParamLoadAndCompare
	xor	a, a
	cp	(3415:16), a
	jrl	nz, VoiceSlot_TableSetup_Code_Loop2
	cp	(3420:16), a
	jrl	nz, VoiceSlot_TableSetup_Code_Loop2
	call	DisplayStr_TempoString_0x74
	call	VoiceSlot_FlagCheck
	cp	a, 132
	jrl	nz, VoiceSlot_TableSetup_Code_Return3
	ld	(0x3728:16), 9
	call	DisplayStr_StyleSectionInit
VoiceSlot_TableSetup_Code_Return3:
	ret
	ordi8	(0xe3e2), 8
	call	AccPedal_CheckBitAndUpdate
VoiceSlot_TableSetup_Code_Loop3:
	call	Timer_ParamCompareAlt
	xor	a, a
	cp	(3415:16), a
	jrl	nz, VoiceSlot_TableSetup_Code_Loop3
	cp	(3420:16), a
	jrl	nz, VoiceSlot_TableSetup_Code_Loop3
	call	DisplayStr_TempoString_0x74
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
	cp (0x287a:16), 0
	jrl nz, AccPedal_SendSysExAndReturn
	ld (0x371a:16), de
	ld (3420:16), c
	ld (3421:16), a
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
	ldw_sri IY, 0x07, 0xf0, 0xf8
	srl xiz, 1
	ld xix, 0xcbe
	ldb_sri A, 0x07, 0xf0, 0xf8
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
	bitda	0, (0x0dc8)
	jrl	z, VoiceCtrl_BytecodeHandler_Skip3
	ordi8	(0x0dc7), 128
VoiceCtrl_BytecodeHandler_Skip3:
	call	VoiceSlot_FinalRetZ
	bitda	1, (0x0dc8)
	jrl	z, VoiceCtrl_BytecodeHandler_Skip4
	or	a, 128
VoiceCtrl_BytecodeHandler_Skip4:
	ld	c, 7:opc
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
	jp	VoiceCtrl_BytecodeHandler_0x61
VoiceCtrl_BytecodeHandler_Skip:
	ld	b, 255:opc
VoiceCtrl_BytecodeHandler_Loop:
	ld	a, 2:opc
	call	VoiceSlot_RestoreState
	jp	VoiceCtrl_BytecodeHandler_0xB9
VoiceCtrl_BytecodeHandler_Skip5:
	ld	b, c
	ldfr_berp a, 60
	ld a, c
	scf
	xorcf a,(0x0dc7:16)	; xorcf A,(0x0dc7)
	ldto_berp a, 60
	jrl	c, VoiceCtrl_BytecodeHandler_Skip6
	cpib_erp 56, 6
	jrl nz, VoiceCtrl_BytecodeHandler_Loop
	add	b, 8
	jp	VoiceCtrl_BytecodeHandler_0x80
VoiceCtrl_BytecodeHandler_Skip6:
	cpib_erp 56, 6
	jrl nz, VoiceCtrl_BytecodeHandler_Skip7
	add	b, 8
VoiceCtrl_BytecodeHandler_Skip7:
	set	4, b
	jp	VoiceCtrl_BytecodeHandler_0x9C
	ret
VoiceCtrl_CheckAndReset:
	ordi8	(0x0d53), 32
	cpdi8	(0x8d40), 0
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
	call	VoiceState_DataBlock2_0x1A6
	jp	VoiceCtrl_ParamSetupBytecode_0xF1
VoiceCtrl_ParamSetupBytecode_Skip:
	xor	a, a
	ld	(3569:16), a
	ld	(0x3720:16), a
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
	call	VoiceState_DataBlock2_0x239
VoiceCtrl_ParamSetupBytecode_Skip2:
	ld	xiy, 3471
	ld	wa, 2:i3
	ld_rrw	wa, xiy, wa
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
	ld	xix, 0xf1a0
	ld_rrb	a, xix, hl
	pop	xix
	pop	xhl
	cp	a, 15
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip4
	cp	a, 16
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Return
VoiceCtrl_ParamSetupBytecode_Skip4:
	ld	w, 6:opc
	ld	xiy, 3471
	call	SysInit_BytecodeBlock_0x486
	ld	(3422:16), 16
VoiceCtrl_ParamSetupBytecode_Skip5:
	ld	w, 98:opc
	call	MIDI_SendSysExFromW
	call	VoiceCtrl_ParamSetupBytecode_0x25E
	call	VoiceCtrl_ParamSetupBytecode_0x21F
VoiceCtrl_ParamSetupBytecode_Return:
	ret
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
	jp	VoiceCtrl_ParamSetupBytecode_0x19C
VoiceCtrl_ParamSetupBytecode_Skip6:
	cp	a, 15
	jrl	ugt, VoiceCtrl_ParamSetupBytecode_Skip7
	cp	w, 3:i3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Loop
	jp	VoiceCtrl_ParamSetupBytecode_0x1A2
VoiceCtrl_ParamSetupBytecode_Skip7:
	cp	a, 152
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip9
	cp	w, 1:i3
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip8
	cp	w, 4:i3
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip9
	jp	VoiceCtrl_ParamSetupBytecode_0x19C
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
	ld	xix, VoiceCtrl_ParamSetupBytecode_Tbl2
	ld_rrb	l, xix, hl
	pop	xix
	cp	l, 255
	jrl	z, VoiceCtrl_ParamSetupBytecode_Loop
	ld	c, l
	ld	l, a
	push	xde
	ld	xde, VoiceCtrl_ParamSetupBytecode_Tbl3
	ld_rrb	l, xde, hl
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
	ld	xhl, VoiceCtrl_ParamSetupBytecode_Tbl
	ld_rr8b	a, xhl, a
	jp	VoiceCtrl_ParamSetupBytecode_0x1CA
VoiceCtrl_ParamSetupBytecode_Skip11:
	ldfr_berp	a, 60
	ld	a, (xiy)
	and	a, 3
	ldto_berp	a, 60
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Loop
	ld	a, 27:opc
	jp	VoiceCtrl_ParamSetupBytecode_0x1CA
	ld	a, 28:opc
	jp	VoiceCtrl_ParamSetupBytecode_0x1CF
	ld	(3422:16), 0
	or	(3411:16), 1
	exts	wa
	ld	xhl, 3439
	add	hl, wa
	ld	a, (xiy+4)
	ld	(xhl), a
	ld	a, 1:opc
	ret
	; Byte data, 18 B.  Read by VoiceCtrl_ParamSetupBytecode (0xEF97E0): `ld xhl, VoiceCtrl_ParamSetupBytecode_Tbl`
	; reader VoiceCtrl_ParamSetupBytecode: `ld xhl, VoiceCtrl_ParamSetupBytecode_Tbl` then `ld_rr8b a, xhl, a`
VoiceCtrl_ParamSetupBytecode_Tbl:
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	.byte	0x00, 0x00
	; Byte data, 20 B.  Read by VoiceCtrl_ParamSetupBytecode (0xEF97E0): `ld xix, VoiceCtrl_ParamSetupBytecode_Tbl2`
	; index bounded to 0..22 (`cp a, 22` / `jrl ugt` skips larger values)
VoiceCtrl_ParamSetupBytecode_Tbl2:
	.byte	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte	0xff, 0xff, 0xff, 0xff
	; Byte data, 20 B.  Read by VoiceCtrl_ParamSetupBytecode (0xEF97E0): `ld xde, VoiceCtrl_ParamSetupBytecode_Tbl3`
	; reader VoiceCtrl_ParamSetupBytecode: `ld xde, VoiceCtrl_ParamSetupBytecode_Tbl3` then `ld_rrb l, xde, hl`
VoiceCtrl_ParamSetupBytecode_Tbl3:
	.byte	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte	0xff, 0xff, 0xff, 0xff
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	xiy, 0x0d8f
	cp	(xiy+2), 72
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Epilogue2
	cp	(xiy+3), 7
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Epilogue2
	ld	bc, (xiy+4)
	ld	a, (3429:16)
	cp	a, 2:i3
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip18
	cp	a, 3:i3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Epilogue2
	call	DisplayStr_RhythmLabel_0x4C
	jp	VoiceCtrl_ParamSetupBytecode_0x256
VoiceCtrl_ParamSetupBytecode_Skip18:
	call	DisplayStr_RhythmLabel_0xA
VoiceCtrl_ParamSetupBytecode_Epilogue2:
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ret
	ld	xiy, 3471
	ld	xix, 3525
	ld	(xix), 0
	cp	(xiy+2), 72
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Return2
	cp	(xiy+3), 5
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip19
	cp	(xiy+3), 6
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Return2
VoiceCtrl_ParamSetupBytecode_Skip19:
	ld	a, (xiy+4)
	bitda	0, (0x0dc9)
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip20
	or	a, 128
VoiceCtrl_ParamSetupBytecode_Skip20:
	ld	(3569:16), a
	ldfr_berp a, 60
	and a, 240
	ldto_berp a, 60
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip21
	call	VoiceCtrl_ParamSetupBytecode_0x303
VoiceCtrl_ParamSetupBytecode_Skip21:
	call	VoiceCtrl_ParamSetupBytecode_0x2A6
VoiceCtrl_ParamSetupBytecode_Return2:
	ret
	pushw	wa
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Epilogue3
	xor	c, c
	ld	w, (3569:16)
	ldfr_berp a, 60
	ldfr_berp w, 61
	ld a, c
	scf
	xorcfb_erp 61
	ldto_berp a, 60
	jrl	nc, VoiceCtrl_ParamSetupBytecode_Skip22
	inc	1, c
	cp	c, 8
	jrl	z, VoiceCtrl_ParamSetupBytecode_Epilogue3
	jp	VoiceCtrl_ParamSetupBytecode_0x2B6
VoiceCtrl_ParamSetupBytecode_Skip22:
	ld	a, c
	cpdi8	(0x0d92), 6
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip23
	add	a, 8
VoiceCtrl_ParamSetupBytecode_Skip23:
	ld	xhl, VoiceCtrl_ParamSetupBytecode_Tbl4
	ld_rr8b	a, xhl, a
	stb_d8	(0x3728), a
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	VoiceCtrl_ParamSetupBytecode_0x5E0
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
VoiceCtrl_ParamSetupBytecode_Epilogue3:
	popw	wa
	ret
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	pushdi_w	(0x0d5a)
	pushdi_w	(0x371a)
	pushdi_w	(0x0d5c)
	pushdi_w	(0x0d57)
	ld	(3533:16), 0
	ld	a, (3415:16)
	add	a, 48
	cp	a, 96
	jrl	c, VoiceCtrl_ParamSetupBytecode_Skip24
	sub	a, 96
	inc	1, (3533:16)
VoiceCtrl_ParamSetupBytecode_Skip24:
	ld	(3534:16), a
	pushdi_w	(0x0d8f)
	pushdi_w	(0x0d91)
	pushdi_w	(0x0d93)
	ld	(0x7f42:16), 255
	call	DisplayMode_Handler_3_0x30C
	popw (0x0d93:16)	; popw (0x0d93)
	popw (0x0d91:16)	; popw (0x0d91)
	popw (0x0d8f:16)	; popw (0x0d8f)
	res	2, (3412:16)
	ld	xiy, 3471
	ld	(xiy), 176
	ld	a, (3415:16)
	inc	1, a
	ld	(xiy+1), a
	bit	1, (3529:16)
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip25
	ormi8	(xiy), 2
VoiceCtrl_ParamSetupBytecode_Skip25:
	ld	(xiy+4), 0
	ld	w, 6:opc
	push xhl
	call	SysInit_BytecodeBlock_0x486
	pop xhl
	popw (0x0d57:16)	; popw (0x0d57)
	popw (0x0d5c:16)	; popw (0x0d5c)
	popw (0x371a:16)	; popw (0x371a)
	popw (0x0d5a:16)	; popw (0x0d5a)
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	ret
	cp	(3429:16), 0
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip26
	jp	VoiceCtrl_ParamSetupBytecode_0x4DD
VoiceCtrl_ParamSetupBytecode_Skip26:
	ld	xiy, 3471
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy), a
	ld	e, a
	and	e, 1
	rrc	e
	ld	(3828:16), a
	and	(3828:16), 4
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	a, (3415:16)
	ld	(xiy+1), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+2), a
	ld	l, (3828:16)
	and	l, 4
	rrc_i_8 l, 3	; rrc 0x03,L  (llvm-mc: rrc	l does not round-trip)
	or	a, l
	ld	(4539:16), a
	ld	(0x90f7:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+3), a
	ld	(0x3723:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+4), a
	or	a, e
	ld	(4541:16), a
	ld	(0x3722:16), a
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
	jrl	le, VoiceCtrl_ParamSetupBytecode_Skip13
	cp	w, 72
	jrl	z, VoiceCtrl_ParamSetupBytecode_Entry
VoiceCtrl_ParamSetupBytecode_Loop2:
	push xhl
	ld	l, a
	ld	h, (4542:16)
	call	PartCtrl_WriteProgramChange
	ld	(4542:16), h
	ld	(0x372b:16), h
	pop xhl
	call	TempoRingBuf_ReadByte
	push	xhl
	call	ToneParam_HandlerTable_BC_0x9F
	cp	w, 1:i3
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip12
	ld	w, 6:opc
	ld	xiy, 3471
	call	SysInit_BytecodeBlock_0x486
	ld	(3422:16), 16
VoiceCtrl_ParamSetupBytecode_Skip12:
	ld	w, 98:opc
	call	MIDI_SendSysExFromW
	pop	xhl
	jp	VoiceCtrl_ParamSetupBytecode_0x4DD
VoiceCtrl_ParamSetupBytecode_Skip13:
	ld	(3567:16), 1
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	Display_BytecodeBlock_F_0x154
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	cpdi8	(0x0d65), 3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Loop2
	call	VoiceState_DataBlock2_0x1A6
	jp	VoiceCtrl_ParamSetupBytecode_0x4DD
VoiceCtrl_ParamSetupBytecode_Entry:
	cpdi8	(0x0d65), 3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip14
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
	jp	VoiceCtrl_ParamSetupBytecode_0x43B
VoiceCtrl_ParamSetupBytecode_Skip14:
	ld	(3567:16), 4
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	DisplayStr_BytecodeBlock_B_0x8C
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	jp	VoiceCtrl_ParamSetupBytecode_0x43B
	ret
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
	ordi8	(0x0d53), 16
	ld	(3538:16), 4
	ld	xhl, 3567
	cpdi8	(0x0d65), 3
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Skip27
	cp	(xhl), 16
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip15
	ld	(xhl), 16
	call	Display_UpdateRegion0
	jp	VoiceCtrl_ParamSetupBytecode_0x55B
VoiceCtrl_ParamSetupBytecode_Skip27:
	cp	(xhl), 6
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip15
	ld	(xhl), 6
	call	Display_UpdateRegion0
VoiceCtrl_ParamSetupBytecode_Skip15:
	call	DisplayStr_BytecodeBlock_C_0x24
	ret
	ld	a, 134:opc
	ld	(0x3728:16), 2
	call	VoiceCtrl_ParamSetupBytecode_0x578
	ret
	ld	a, 133:opc
	ld	(0x3728:16), 1
	call	VoiceCtrl_ParamSetupBytecode_0x578
	ret
	call	VoiceCtrl_ParamSetupBytecode_0x5B9
	cp	c, 0:i3
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip16
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	jp	VoiceCtrl_ParamSetupBytecode_0x5B8
VoiceCtrl_ParamSetupBytecode_Skip16:
	pushw	wa
	call	VoiceCtrl_ParamSetupBytecode_0x5E0
	popw	wa
	ld	xiy, 3471
	ld	(xiy), a
	ld	a, (3415:16)
	ld	(xiy+1), a
	ld	w, 2:opc
	push	xhl
	call	SysInit_BytecodeBlock_0x486
	pop	xhl
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	w, 98:opc
	call	MIDI_SendSysExFromW
	ld	(3422:16), 16
	ret
	push	xhl
	ld	l, (3822:16)
	dec	1, l
	xor	h, h
	ld	c, 255:opc
	push	xix
	ld	xix, 0xf1a0
	ld_rrb l, xix, hl
	pop xix
	cp	l, 16
	jrl	z, VoiceCtrl_ParamSetupBytecode_Skip17
	cp	l, 15
	jrl	nz, VoiceCtrl_ParamSetupBytecode_Epilogue
VoiceCtrl_ParamSetupBytecode_Skip17:
	xor	c, c
VoiceCtrl_ParamSetupBytecode_Epilogue:
	pop	xhl
	ret
	push	xhl
	ld	a, (3429:16)
	and	a, 3
	exts	wa
	sla	wa, 2
	ld	iy, wa
	push	xde
	ld	xde, SerialPort_ModeSelect_Table
	ld_rrl xiy, xde, iy
	pop xde
	call	(xiy)
	pop	xhl
	ret


	; Handler dispatch table, 16 B.  Read by VoiceCtrl_ParamSetupBytecode (0xEF97E0): `ld xde, SerialPort_ModeSelect_Table`
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
	call	DisplayStr_BytecodeBlock_E_0x1
	ret
	cpdi8	(0x0d65), 3
	jrl	nz, SerialPort_ModeHandler_0_Skip
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	jp	SerialPort_ModeHandler_0_0x70
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
	ld	(0x3721:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(3538:16), 3
	ld	(0x3720:16), 2
	cpdi8	(0x0def), 2
	jrl	nz, SerialPort_ModeHandler_0_Skip4
	call	DisplayStr_BytecodeBlock_B_0x3D
	jp	SerialPort_ModeHandler_0_0x6B
SerialPort_ModeHandler_0_Skip4:
	ld	(3567:16), 2
	call	DisplayStr_BytecodeBlock_B_0x39
	ld	(3540:16), 0
	ret
	cpdi8	(0x0d65), 3
	jrl	nz, SerialPort_ModeHandler_0_Skip2
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	jp	SerialPort_ModeHandler_0_0xE9
SerialPort_ModeHandler_0_Skip2:
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
	ld	(0x3721:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(xiy+3), a
	ld	(4370:16), a
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	ld	(3538:16), 4
	ld	(0x3720:16), 1
	cpdi8	(0x0def), 2
	jrl	nz, SerialPort_ModeHandler_0_Skip5
	call	DisplayStr_BytecodeBlock_B_0x3D
	jp	SerialPort_ModeHandler_0_0xE4
SerialPort_ModeHandler_0_Skip5:
	ld	(3567:16), 2
	call	DisplayStr_BytecodeBlock_B_0x39
	ld	(3540:16), 0
	ret
	ld	c, (3533:16)
	xor	b, b
	add (3418:16), bc
	cp c, 0:i3
	jrl	z, SerialPort_ModeHandler_0_Return
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	SysInit_BytecodeBlock_0xFB
	djnz16	bc, -7
	call	AccPedal_CheckBitAndUpdate
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
SerialPort_ModeHandler_0_Return:
	ret
	ld	l, (0x3714:16)
	cp	l, 0:i3
	jrl	nz, SerialPort_ModeHandler_0_Skip6
	ld	l, 6:opc
SerialPort_ModeHandler_0_Skip6:
	sla	l, 1
	xor	h, h
	push	xix
	ld	xix, ScoopParam_ValueTable
	ld_rrw	de, xix, hl
	ldb_d8	l, (0x3715)
	sla	l, 1
	ld_rrw	bc, xix, hl
	pop	xix
	add	de, bc
	ld	wa, de
	ld	l, 96:opc
	div	wa, l
	ld	(0x342f:16), w
	ld	(0x3430:16), a
	ld	a, (0x3716:16)
	cp	a, 1:i3
	jrl	nz, SerialPort_ModeHandler_0_Skip7
	sla	de, 2
	ld	wa, de
	xor	de, de
	ld	hl, 5:i3
	ld	qwa, de
	div	xwa, hl
	ld	de, qwa
	jp	SerialPort_ModeHandler_0_0x19D
SerialPort_ModeHandler_0_Skip7:
	cp	a, 0:i3
	jrl	nz, SerialPort_ModeHandler_0_Skip3
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
	jp	SerialPort_ModeHandler_0_0x19D
SerialPort_ModeHandler_0_Skip3:
	cp	a, 2:i3
	jrl	nz, SerialPort_ModeHandler_0_Skip8
	srl	de, 1
	ld	wa, de
	jp	SerialPort_ModeHandler_0_0x19D
SerialPort_ModeHandler_0_Skip8:
	srl	de, 2
	ld	wa, de
	ld	l, 96:opc
	div	wa, l
	ld	(0x342d:16), w
	ld	(0x342e:16), a
	ret
	; Byte data, 28 B.  Read by SerialPort_ModeHandler_0 (0xEF9E03): `ld xix, ScoopParam_ValueTable`
	; reader SerialPort_ModeHandler_0: `ld xix, ScoopParam_ValueTable` then `ld_rrw bc, xix, hl`
ScoopParam_ValueTable:
	.byte	0x00, 0x00, 0x08, 0x00, 0x0c, 0x00, 0x10, 0x00, 0x18, 0x00, 0x20, 0x00, 0x30, 0x00, 0x40, 0x00
	.byte	0x60, 0x00, 0xc0, 0x00, 0x80, 0x01, 0x00, 0x03, 0x80, 0x04, 0x00, 0x06
	call	SerialPort_ModeHandler_0_Helper2
	ld	(3415:16), w
	ld	(3533:16), a
	ret
	call	SerialPort_ModeHandler_0_Helper2
	ld	(3534:16), w
	ld	(3533:16), a
	ret
SerialPort_ModeHandler_0_Helper2:
	ld	w, (13359:16)
	ld	a, (13360:16)
	add	w, (3415:16)
	cp	w, 96
	jrl	c, SerialPort_ModeHandler_0_Return2
	sub	w, 96
	inc	1, a
SerialPort_ModeHandler_0_Return2:
	ret
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	xiy, 10430
	cp	(xiy), 255
	jrl	z, SerialPort_ModeHandler_0_Epilogue
	ld	(xiy), 255
	ld	a, (3822:16)
	ld	(10359:16), a
	call	Scoop_SpecialMode_ParamCheckBound
	resda	7, (0x0d54)
	call	SerialPort_ModeHandler_0_Sub
	ordi8	(0x8d88), 1
SerialPort_ModeHandler_0_Epilogue:
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ret
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
	ld	xhl, 3439
	ld_rr8b	a, xhl, a
	lda_rr	xhl, xhl, bc
	ld	(xhl), 255
	ld	e, a
	cp	a, 255
	jrl	nz, SerialPort_ModeHandler_0_Skip11
SerialPort_ModeHandler_0_Join:
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
	anddi8	(0x0d53), 254
	jp	SerialPort_ModeHandler_0_Return3
SerialPort_ModeHandler_0_Skip11:
	ld	xiy, 3471
	ld	(xiy), 176
	ld	a, (3415:16)
	ld	(xiy+1), a
	ld	(xiy+5), 127
	ld	a, c
	cp	a, 15
	jrl	ugt, SerialPort_ModeHandler_0_Skip12
	ld	xhl, SerialPort_ModeHandler_0_Tbl
	ld_rr8b	a, xhl, a
	ld	w, 3:opc
	jp	SerialPort_ModeHandler_0_Join2
SerialPort_ModeHandler_0_Skip12:
	cp	a, 27
	jrl	nz, SerialPort_ModeHandler_0_Skip13
	ld	a, 72:opc
	ld	w, 8:opc
	jp	SerialPort_ModeHandler_0_Join2
SerialPort_ModeHandler_0_Skip13:
	cp	a, 28
	jrl	z, SerialPort_ModeHandler_0_Entry
	sub	a, 16
	ld	l, a
	xor	h, h
	push	xix
	ld	xix, SerialPort_ModeHandler_0_Data
	ld_rrb	a, xix, hl
	ld	xix, SerialPort_ModeHandler_0_Data2
	ld_rrb	w, xix, hl
	pop	xix
	cp	a, 255
	jrl	nz, SerialPort_ModeHandler_0_Join2
	jp	SerialPort_ModeHandler_0_Join
SerialPort_ModeHandler_0_Entry:
	ormi8	(xiy), 4
	ld	(xiy+2), 152
	andmi8	(xiy+2), 127
	ld	(xiy+3), 1
	ld	(xiy+4), e
	ld	(xiy+5), 127
	ld	w, 6:opc
	pushw	bc
	call	SystemInit_StepHandler_0_Helper2
	popw	bc
	jp	SerialPort_ModeHandler_0_Join
SerialPort_ModeHandler_0_Join2:
	ld	(xiy+2), a
	ld	a, w
	ld	(xiy+3), a
	ld	(xiy+4), e
	ld	w, 6:opc
	pushw	bc
	call	SystemInit_StepHandler_0_Helper2
	popw	bc
	jp	SerialPort_ModeHandler_0_Join
SerialPort_ModeHandler_0_Return3:
	ret
	; Byte data, 16 B.  Read by SerialPort_ModeHandler_0 (0xEF9E03): `ld xhl, SerialPort_ModeHandler_0_Tbl`
	; index bounded to 0..15 (`cp a, 15` / `jrl ugt` skips larger values)
SerialPort_ModeHandler_0_Tbl:
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	; Loaded by SerialPort_ModeHandler_0 (0xEF9E03):
	; `ld xix, SerialPort_ModeHandler_0_Data` -- a bare number until lane scoop gave this address a label.
SerialPort_ModeHandler_0_Data:
	.byte	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 'p', 0x98, 0xff, 0xff
	; Loaded by SerialPort_ModeHandler_0 (0xEF9E03):
	; `ld xix, SerialPort_ModeHandler_0_Data2` -- a bare number until lane scoop gave this address a label.
SerialPort_ModeHandler_0_Data2:
	.byte	0x03, 0x03, 0x03, 0x03, 0x03
	.byte	0x03, 0x03, 0x03, 0x04
	ld	(4346:16), 0
	ld	a, (36150:16)
	cp	a, (36151:16)
	jrl	z, ScoopParam_ValueTable_Entry3_Code_Skip
	ld	(10430:16), 255
	call	SeqBuf_Init
	anddi8	(0x0d53), 254
	anddi8	(0x28a6), 254
	call	AccWrap_PositionClear
	ld	(32578:16), 0
	call	VoiceCtrl_CheckAndReset
	ld	a, (64605:16)
	ld	(4392:16), a
	call	PortConfig_Handler_0_Helper2
	cp	(3429:16), 0
	jrl	nz, SerialPort_ModeHandler_0_Sub
	anddi8	(0xfc5d), 247
	ld	e, 72:opc
	ld	d, 3:opc
	ld	a, (64605:16)
	ld	w, 8:opc
	call	SwbtWr_QueuePostEvent
SerialPort_ModeHandler_0_Sub:
	ld	(14100:16), 4
	ld	(14101:16), 0
	ld	(14102:16), 1
	call	PortConfig_Handler_0_Helper3
	call	PortConfig_Handler_0_Helper2
	ld	a, (36154:16)
	ld	(3430:16), a
	call	PortConfig_Handler_0_Sub
	call	PortConfig_Handler_0_Helper5
	call	PortConfig_Handler_0_Return
	call	ClockConfig_Handler_0_Helper
	cpw	(62001:16), 0
	jrl	nz, SerialPort_ModeHandler_0_Entry2
	call	VoiceState_DataBlock2_Helper
	cp	w, 0:i3
	jrl	z, SerialPort_ModeHandler_0_Entry2
	ld	(3433:16), 24
	jp	SerialPort_ModeHandler_0_Return4
SerialPort_ModeHandler_0_Entry2:
	resda	7, (0x0d54)
	call	PortConfig_Handler_0_Helper4
	call	SeqBuf_Init
	call	PortConfig_Handler_0_Helper
	call	MemConfig_Handler_4_Helper2
	call	BitMapOut_ComputeRegionDelta
	call	MemConfig_Handler_4_Helper
	call	PortConfig_SetupBytecode
	xor	wa, wa
	ld	(3407:16), wa
	ld	(3409:16), wa
	ld	c, (3822:16)
	dec	1, c
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ld	de, (3407:16)
	ld	a, c
	scf
	stcf_a_16 de	; stcf A,DE
	ldto_berp	a, 60
	ld	(3407:16), de
	ldto_werp DE, 0x3e	; ld DE,QHL3
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ld	de, (3409:16)
	ld	a, c
	scf
	stcf_a_16 de	; stcf A,DE
	ldto_berp	a, 60
	ld	(3409:16), de
	ldto_werp DE, 0x3e	; ld DE,QHL3
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ld	de, (65516:24)
	ld	a, c
	rcf
	stcf_a_16 de	; stcf A,DE
	ldto_berp	a, 60
	ld	(65516:24), de
	ldto_werp DE, 0x3e	; ld DE,QHL3
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ld	de, (61854:16)
	ld	a, c
	rcf
	stcf_a_16 de	; stcf A,DE
	ldto_berp	a, 60
	ld	(61854:16), de
	ldto_werp DE, 0x3e	; ld DE,QHL3
	ldw	(61854:16), 0
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ld	de, (10357:16)
	ld	a, c
	rcf
	stcf_a_16 de	; stcf A,DE
	ldto_berp	a, 60
	ld	(10357:16), de
	ldto_werp DE, 0x3e	; ld DE,QHL3
	ldw	(3928:16), 65535
	call	Audio_CheckSubsystemReady
	call	VoiceState_DataBlock2_Helper
	cp	w, 0:i3
	jrl	z, SerialPort_ModeHandler_0_Skip14
	call	SystemInit_StepHandler_0_Helper
	call	VoiceSlot_CompareAndBranch
	call	ScoopParam_ValueTable_Sub_Helper
	jp	SerialPort_ModeHandler_0_Join3
SerialPort_ModeHandler_0_Skip14:
	call	MemoryConfig_Handler_Table_Target2_Sub
SerialPort_ModeHandler_0_Join3:
	call	ScoopParam_ValueTable_Sub_Helper2
	bitda	2, (0x0421)
	jrl	z, SerialPort_ModeHandler_0_Entry3
	call	Demo_PreSetupAndScan
SerialPort_ModeHandler_0_Entry3:
	anddi8	(0x346e), 239
	anddi8	(0x045b), 252
	call	VoiceState_DataBlock2_Helper2
	ordi8	(0x28a7), 4
	ld	xiy, 3411
	ormi8	(xiy), 8
	andmi8	(xiy), 223
	call	AccPedal_CheckBitAndUpdate
	setda	0, (0x0dd3)
	ld	(14120:16), 0
	cp	(4346:16), 0
	jrl	nz, SerialPort_ModeHandler_0_Skip9
	call	PortConfig_SetupBytecode_0x34
SerialPort_ModeHandler_0_Skip9:
	call	SerialPort_ModeHandler_0_Helper
	jp	SerialPort_ModeHandler_0_Return4
ScoopParam_ValueTable_Entry3_Code_Skip:
	call	PortConfig_Handler_0_Return
	call	ClockConfig_Handler_0_Helper
	bitda	3, (0x0d53)
	jrl	z, SerialPort_ModeHandler_0_Skip10
	call	PortConfig_SetupBytecode_0x34
	cp	(3429:16), 0
	jrl	nz, SerialPort_ModeHandler_0_Skip10
SerialPort_ModeHandler_0_Skip10:
	jp	SerialPort_ModeHandler_0_Return4
SerialPort_ModeHandler_0_Return4:
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
	ld_sril3 XHL, 0x07, 0xe0, 0xec
	call (xhl)
	jp Interrupt_NullRet

Interrupt_NullRet:
	ret

	; Handler dispatch table, 20 B.  Read by Interrupt_CodeDispatch (0xEFA349): `ld xwa, Interrupt_VectorSelect_Table`
	; 5 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
Interrupt_VectorSelect_Table:
	.long	Interrupt_VectorHandler_0
	.long	Interrupt_VectorHandler_1
	.long	Interrupt_VectorHandler_2
	.long	Interrupt_VectorHandler_3
	.long	Interrupt_VectorHandler_4
Interrupt_VectorHandler_0:
	cp (0x8d40:16), 0
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
	cp (0x8d40:16), 0
	jrl z, Interrupt_Vec2_Ret
	call Interrupt_SendAllNotesOff

Interrupt_Vec2_Ret:
	ret

Interrupt_VectorHandler_3:
	cp (0x8d40:16), 0
	jrl nz, Interrupt_Vec3_UpdatePath
	call Interrupt_ClearModeRegs
	jp Interrupt_Vec3_Ret

Interrupt_Vec3_UpdatePath:
	call Display_RegionUpdateFromHW

Interrupt_Vec3_Ret:
	ret

Interrupt_VectorHandler_4:
	cp (0x8d40:16), 0
	jrl z, Interrupt_Vec4_InitPath
	call Interrupt_UpdateFromHW
	jp Interrupt_Vec4_Ret

Interrupt_Vec4_InitPath:
	call Interrupt_ClearModeAndRet

Interrupt_Vec4_Ret:
	ret

Interrupt_StoreHWRegsAndInit:
	cp (3422:16), 0
	jrl z, Interrupt_LoadAndStoreRegs
	ld (3422:16), 0

Interrupt_LoadAndStoreRegs:
	ld a, (0x8d40:16)
	ld (3437:16), a
	ld a, (0x8d42:16)
	ld (3438:16), a
	ld a, (0x8d44:16)
	ld (4391:16), a
	xor a, a
	ld (3425:16), a
	call SNS_Init_Startup
	call Display_UpdateRegion3
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
	ld	(3432:16), 2
	ld	(3431:16), 4
	call	Audio_CheckSubsystemReady
	ret

Interrupt_SendAllNotesOff:
	ld (3432:16), 3
	call Display_RegionUpdateFromHW
	call VoiceCtrl_SendNoteOffSequence
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call NoteMap_SendAllNotesOff
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call AudioInit_RefreshToneBank
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ret

Interrupt_ClearModeRegs:
	xor a, a
	ld (3432:16), a
	ld (3431:16), a
	call Audio_CheckSubsystemReady
	ret

Interrupt_SetFlagBytecode:
	ld	(3432:16), 4
	ld	(3431:16), 0
	call	Audio_CheckSubsystemReady
	ret

Interrupt_UpdateFromHW:
	call Display_RegionUpdateFromHW
	ret

Interrupt_ClearModeAndRet:
	ld (3432:16), 0
	ret

Display_RegionUpdateFromHW:
	ld a, (0x8d40:16)
	ld (3437:16), a
	ld a, (0x8d42:16)
	ld (3438:16), a
	ld a, (0x8d44:16)
	ld (4391:16), a
	call SNS_Init_Startup
	call Display_UpdateRegion3
	ret

PortConfig_SetupBytecode:
	ld	(0x28be:16), 255
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	push	xix
	ld	xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf8, 0x0e	; cp (XIX+IZ),0x0e
	pop	xix
	jrl	nz, PortConfig_SetupBytecode_Return
	ld	a, (3822:16)
	dec	1, a
	ld	(0x28be:16), a
	push	xix
	ld	xix, 0xf1a0
	stib_ind 0x07, 0xf0, 0xf8, 0x0d	; ld (XIX+IZ),0x0d
	pop	xix
PortConfig_SetupBytecode_Return:
	ret
	ld	a, (3429:16)
	and	wa, 3
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, PortConfig_Select_Table
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
	ret
	; Handler dispatch table, 16 B.  Read by PortConfig_SetupBytecode (0xEFA4B8): `ld xix, PortConfig_Select_Table`
	; indexed with stride 4 (`sla wa, 2`), index from `ld hl, wa`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
PortConfig_Select_Table:
	.long	PortConfig_Handler_0
	.long	PortConfig_Handler_1
	.long	PortConfig_Handler_1
	.long	PortConfig_Handler_3
PortConfig_Handler_1:
	ordi8	(0x0dd3), 1
	call	VoiceSlot_TableSetup
	call	Timer_ModeHandler_0_0x13
	call	PortConfig_Handler_0_0xD7
	call	ToneParam_HandlerTable_BC_0x567
	resda	2, (0x0d54)
	ret
PortConfig_Handler_3:
	; --- Init: call FB1536, set 3 flags, call 6 handlers, call FB155F (51 bytes) ---
	call Display_DeferOrDrawWall
	ld	(0x0205e8:24), 255
	ld	(0x0205ec:24), 255
	ld	(0x0205ea:24), 255
	call DisplayStr_TempoString_0x6F
	call DisplayStr_TempoString_0x74
	call PortConfig_Handler_0_0xD7
	call UIState_UpdateMultiRegions
	call Display_UpdateRegion3
	call Display_UpdateRegion2
	call Display_DeferOrUpdateScreen
	ret


PortConfig_Handler_0:
	call	Display_DeferOrDrawWall
	ld	(0x0205e8:24), 255
	ld	(0x0205ec:24), 255
	ld	(0x0205ea:24), 255
	call	Display_BytecodeBlock_F_0x32D
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_0x3A8
	cpdi8	(0x28be), 255
	jrl	z, PortConfig_Handler_0_Skip2
	ldw	(3660:16), 0
	ldw	(3662:16), 1
	ldw	(3664:16), 0
	call	PortConfig_Handler_0_0xC0
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
	jp	PortConfig_Handler_0_0xBB
PortConfig_Handler_0_Skip2:
	call	SubCPU_ToneParamRet_0x4BD
	call	PortConfig_Handler_0_0xD7
	call	SndDispatch_ProcessCommand_0x28B
	call	Display_DeferOrUpdateScreen
	ret
	pushw	wa
	pushw	bc
	push	xix
	ld	xix, 3669
	ldw	bc, 96
	xor	wa, wa
	ld (xix+), a
	djnz16 bc, -6
	pop xix
	popw	bc
	popw	wa
	ret
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, PortConfig_Handler_0_Skip3
	cp	a, 130
	jrl	z, PortConfig_Handler_0_Skip3
	call	VoiceSlot_FlagCheck
	cp	a, 132
	jrl	z, PortConfig_Handler_0_Skip3
	cp	a, 130
	jrl	z, PortConfig_Handler_0_Skip3
	cp	a, (0x0d57:16)
	jrl	nz, PortConfig_Handler_0_Skip3
	call	SndDispatch_ProcessCommand_0x266
	jp	PortConfig_Handler_0_0x10A
PortConfig_Handler_0_Skip3:
	call	DisplayMode_Handler_3_0x775
	ret
PortConfig_Handler_0_Helper:
	call	VoiceSlot_ComputeIndex
	push	xde
	ld	xde, 0xf250
	bit_dri 0x07, 0x07, 0xe8, 0xf8	; bit 7,(XDE+IZ)
	pop	xde
	jrl	nz, ScoopParam_ValueTable_Helper_Skip
	call	VoiceSlot_ComputeWordIndex
	push	xix
	ld	xix, 3230
	stiw_ind 0x07, 0xf0, 0xf8, 0xff, 0xff	; ld (XIX+IZ),0xffff
	srl	iz, 1
	ld	xix, 3262
	stib_ind 0x07, 0xf0, 0xf8, 0x05	; ld (XIX+IZ),0x05
	pop	xix
	jp	PortConfig_Handler_0_0x16E
ScoopParam_ValueTable_Helper_Skip:
	push	xde
	push	xix
	ld	xix, 0xf250
	inc	1, iz
	ld_rrw	de, xix, iz
	call	VoiceSlot_ComputeWordIndex
	ld	xix, 3230
	st_rrw de, xix, iz
	srl	iz, 1
	ld	xix, 3262
	stib_ind 0x07, 0xf0, 0xf8, 0x05	; ld (XIX+IZ),0x05
	pop	xix
	pop	xde
	ret
PortConfig_Handler_0_Helper2:
	ld	a, (3424:16)
	ld	(3822:16), a
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	push	xix
	ld	xix, 0xf1a0
	ld_rrb	a, xix, iz
	pop	xix
	ld	xhl, PortConfig_DataTable_A
	ld_rr8b	a, xhl, a
	stb_d8	(0x0d65), a
	ret
	; Byte data, 24 B.  Read by PortConfig_Handler_0 (0xEFA565): `ld xhl, PortConfig_DataTable_A`
	; reader PortConfig_Handler_0: `ld xhl, PortConfig_DataTable_A` then `ld_rr8b a, xhl, a`
PortConfig_DataTable_A:
	.byte	0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x02
	.byte	0x03, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
PortConfig_Handler_0_Sub:
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	push	xix
	ld	xix, 0xf1a0
	ld_rrb a, xix, iz
	pop xix
	cp	a, 15
	jrl	z, PortConfig_DataTable_A_Sub_Return
	cp	a, 16
	jrl	z, PortConfig_DataTable_A_Sub_Return
	and	a, 31
	ld	l, a
	xor	h, h
	sla	hl, 2
	ld	xhl, PortConfig_DataTable_B
	ld_rr8b	a, xhl, a
	cp	a, 255
	jrl	z, PortConfig_DataTable_A_Sub_Return
	ld	(0x8d3a:16), a
	ld	e, a
	ld	d, 255:opc
	ldw	wa, 4240
	call	SysInit_BytecodeBlock_0x3DB
PortConfig_DataTable_A_Sub_Return:
	ret
	; Byte data, 20 B.  Read by PortConfig_Handler_0 (0xEFA565): `ld xhl, PortConfig_DataTable_B`
	; indexed with stride 4 (`sla hl, 2`)
PortConfig_DataTable_B:
	.byte	0x00, 0x02, 0x01, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x04, 0x05, 0x06, 0x03, 0x0f, 0xff, 0xff, 0xff
	.byte	0xff, 0x0c, 0x0d, 0x0e
PortConfig_Handler_0_Helper3:
	ld	xhl, 4362
	ld	xwa, (7514:16)
	ld	(xhl), xwa
	ret
PortConfig_Handler_0_Helper4:
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	cp	wa, 0xffff
	jrl	nz, PortConfig_Handler_0_Helper4
	ret
PortConfig_Handler_0_Helper5:
	ld	xhl, PortConfig_Handler_0_Tbl
	ld	a, (3429:16)
	and	a, 3
	ld_rr8b a, xhl, a
	ld (3567:16), a
	ret
	; Byte data, 4 B.  Read by PortConfig_Handler_0 (0xEFA565): `ld xhl, PortConfig_Handler_0_Tbl`
	; reader PortConfig_Handler_0: `ld xhl, PortConfig_Handler_0_Tbl` then `ld_rr8b a, xhl, a`
PortConfig_Handler_0_Tbl:
	.byte	0x00, 0x00, 0x00, 0x0c
PortConfig_Handler_0_Return:
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
	ordi8	(0xe3e2), 2
	ret
ClockConfig_Handler_0:
	anddi8	(0xe3e2), 253
	ret
ClockConfig_Handler_0_Helper:
	ret
	; Byte data, 4 B.  No reader found: no label, positional or absolute .set
	; name at this address is loaded anywhere in the image (searched by
	; scripts/analysis/scoop_data_headers.py); purpose not established.
Unref_EFA7C5_Tbl:
	.byte	0x04, 0x02, 0x02, 0x04
ScoopParam_ValueTable_Sub_Helper:
	cpdi8	(0x0d65), 3
	jrl	nz, ScoopParam_ValueTable_Helper6_Return
	ld	bc, 6:i3
	ld	xiy, ClockConfig_Handler_0_Tbl
	ld	xix, 3471
	push	xix
	ldir85
	pop	xix
	ld	a, (0xfc5a:16)
	ld	w, a
	and	a, 127
	ld	(xix+4), a
	and	w, 128
	rlc	w
	or	(xix), w
	ld	a, (0xfc5b:16)
	and	a, 127
	or	(xix+5), a
	ld	xiy, xix
	ld	w, 6:opc
	call	SysInit_BytecodeBlock_0x486
	bitda	7, (0xfc5a)
	jrl	z, ScoopParam_ValueTable_Helper6_Skip
	ld	a, (0xfc5a:16)
	cp	a, 240
	jrl	nc, ScoopParam_ValueTable_Helper6_Skip
	and	a, 127
	extz	wa
	div	a, 4
	sla	w, 4
	ld	a, (0xfc61:16)
	and	a, 207
	or	a, w
	ld	(0xfc61:16), a
	ld	e, 72:opc
	ld	d, 7:opc
	ld	w, 48:opc
	call	SwbtWr_QueuePostEvent
ScoopParam_ValueTable_Helper6_Skip:
	ld	bc, 6:i3
	ld	xiy, ClockConfig_Handler_0_Tbl2
	ld	xix, 3471
	push	xix
	ldir85
	pop	xix
	ld	a, (0xfc61:16)
	and	a, 127
	ld	(xix+4), a
	ld	xiy, xix
	ld	w, 6:opc
	call	SysInit_BytecodeBlock_0x486
ScoopParam_ValueTable_Helper6_Return:
	ret
	; Byte data, 6 B.  Read by ClockConfig_Handler_0 (0xEFA7BE): `ld xiy, ClockConfig_Handler_0_Tbl`
	; reader ClockConfig_Handler_0: `ld xiy, ClockConfig_Handler_0_Tbl`
ClockConfig_Handler_0_Tbl:
	.byte	0xc0, 0x00, 0x48, 0x00, 0x00, 0x00
	; Byte data, 6 B.  Read by ClockConfig_Handler_0 (0xEFA7BE): `ld xiy, ClockConfig_Handler_0_Tbl2`
	; reader ClockConfig_Handler_0: `ld xiy, ClockConfig_Handler_0_Tbl2`
ClockConfig_Handler_0_Tbl2:
	.byte	0xb0, 0x00, 0x48, 0x07, 0x00, 0x30
ScoopParam_ValueTable_Sub_Helper2:
	xor	wa, wa
	ld	(3660:16), wa
	ld	(3662:16), wa
	ld	(3664:16), wa
	ld	(3666:16), a
	ld	(3667:16), a
	ld	(3668:16), a
	ld	(3416:16), wa
	ld	(3418:16), wa
	ld	(3415:16), a
	ld	(0x371a:16), wa
	ld	(0x3719:16), a
	ld	(0x3728:16), a
	ld	(3432:16), a
	ld	(3431:16), a
	ld	(3422:16), a
	ld	(3540:16), a
	ldw	wa, 0xffff
	ld	(3536:16), a
	ld	(3413:16), a
	pushw	bc
	push	xix
	ld	xix, 3439
	ldw	bc, 16
	ld	(xix+), wa
	djnz16	bc, -6
	pop	xix
	popw	bc
	ld	(0x371c:16), 32
	ret
	ld	(0x370f:16), 0
	call	DisplayStr_StyleSectionNames_0x69
	ld	(3413:16), 255
	anddi8	(0x0f57), 254
	ld	(3382:16), 0
	ld	a, (0x8d37:16)
	cp	(0x8d36:16), a
	jrl	z, ScoopParam_ValueTable_Helper6_Return2
	anddi8	(0x0d53), 254
	bitda	0, (0x0f54)
	jrl	z, ScoopParam_ValueTable_Helper6_Skip2
	call	VoiceCtrl_SendNoteOffSequence
ScoopParam_ValueTable_Helper6_Skip2:
	anddi8	(0x0f54), 254
	bitda	0, (0x1126)
	jrl	nz, ScoopParam_ValueTable_Helper6_Skip3
	cpdi8	(0x28be), 255
	jrl	nz, ScoopParam_ValueTable_Helper6_Skip3
	call	ScoopParam_ValueTable_0x84
ScoopParam_ValueTable_Helper6_Skip3:
	anddi8	(0x1126), 254
	ld	de, (0x2875:16)
	ld	de, (0xffec:24)
	call	VoiceState_DataBlock2_0x184
	cp	w, 0:i3
	jrl	nz, ScoopParam_ValueTable_Helper6_Skip4
	ld	c, (3822:16)
	dec	1, c
	ldfr_berp	a, 60
	ldfr_werp DE, 0x3e	; ld QHL3,DE
	ld	a, c
	scf
	stcfw_erp 0x3e	; stcf A,QHL3
	ldto_berp	a, 60
	ldto_werp DE, 0x3e	; ld DE,QHL3
ScoopParam_ValueTable_Helper6_Skip4:
	ld	(0xf19e:16), de
	ld	(0xffec:24), de
	ordi8	(0x28a5), 1
	ld	(4596:16), 0
	call	BitMapOut_RenderDisplay
	ld	a, (4392:16)
	ld	(0xfc5d:16), a
	ld	e, 72:opc
	ld	d, 3:opc
	ld	w, 8:opc
	call	SwbtWr_QueuePostEvent
	ld	a, (3430:16)
	call	PortConfig_DataTable_A_0x51
	xor	wa, wa
	ld	(3407:16), wa
	ld	(3409:16), wa
	ld	(0x370f:16), a
	ld	(3431:16), a
	ld	(4360:16), wa
	ld	(4345:16), a
	ld	(4346:16), a
	resda	3, (0x0d54)
	call	DisplayStr_StyleSectionNames_0x69
	call	ClockConfig_Handler_0_0x228
	ld	wa, (0xf1d0:16)
	ld	(3928:16), wa
	call	Audio_CheckSubsystemReady
	pushw	wa
	xor	a, a
	call	Part_InitVoiceDefaults
	popw	wa
	ordi8	(0x28b3), 16
	anddi8	(0x28a7), 247
	anddi8	(0x28a7), 251
	anddi8	(0x0d53), 247
	ld	a, (3429:16)
	cp	a, 3:i3
	jrl	nz, ScoopParam_ValueTable_Helper6_Skip5
	call	SysInit_BytecodeBlock_0x1A1
	jp	ClockConfig_Handler_0_0x227
ScoopParam_ValueTable_Helper6_Skip5:
	cp	a, 0:i3
	jrl	nz, ScoopParam_ValueTable_Helper6_Return2
	call	SysInit_BytecodeBlock_0x255
ScoopParam_ValueTable_Helper6_Return2:
	ret
	cpdi8	(0x28be), 255
	jrl	z, ScoopParam_ValueTable_Helper6_Return3
	call	VoiceSlot_ComputeWordIndex
	sra	iz, 1
	push	xix
	ld	xix, 0xf1a0
	stib_ind 0x07, 0xf0, 0xf8, 0x0e	; ld (XIX+IZ),0x0e
	pop	xix
ScoopParam_ValueTable_Helper6_Return3:
	ret

SysEx_PeriodicDispatch:
	ld xiy, 0xd69
	cp (xiy), 0x18
	jrl nz, SysEx_CountdownCheck
	and (0xe3e2:16), 111
	pushw wa
	push xiy
	ld w, 0x68:opc
	call MIDI_SendSysExFromW
	pop xiy
	popw wa
	ld (0x7f42:16), 15
	xor wa, wa
	ld a, 0xee:opc
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
	cp (0x8d36:16), 138
	jrl nz, SysEx_FlagClearAndCompare
	cp (3429:16), 3
	jrl nz, SysEx_FlagClearAndCompare
	or (3926:16), 2
	jp SubCPU_CmdCountdownRet

SysEx_FlagClearAndCompare:
	and (3926:16), 253
	cp (0x8d36:16), 129
	jrl z, SysEx_DecrementCounter
	cp (0x8d36:16), 142
	jrl nz, SubCPU_CmdCountdownRet

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
	jrl	nz, SysEx_BytecodeDispatcher_Skip2
	ld	xiy, 3520
	cp	(xiy), a
	jrl	nz, SysEx_BytecodeDispatcher_Skip3
	ld	xiy, 4360
	cp	(xiy), wa
	jrl	nz, SysEx_BytecodeDispatcher_Skip4
	jp	SysEx_BytecodeDispatcher_0x108
SysEx_BytecodeDispatcher_Skip2:
	call	ScoopParam_ValueTable_0x4E
	call	SysInit_BytecodeBlock_0x413
	xor	h, h
	push	xix
	ld	xix, SysInit_BytecodeBlock
	ld_rrb	w, xix, hl
	pop	xix
	or	w, 2
	push	xhl
	call	MIDI_SendSysExFromW
	pop	xhl
	push	xde
	ld	xde, SysEx_BytecodeDispatcher_Tbl2
	ld_rrb w, xde, hl
	pop	xde
	ld	(3425:16), w
	ld	(3432:16), 1
	call	SystemInit_StepHandler_0_0x4B
	push	xhl
	call	SNS_Init_Startup
	pop	xhl
	call	SysInit_BytecodeBlock_0xC
	call	SysInit_BytecodeBlock_0x2F
	ld	(3434:16), 0
	call	SubCPU_ToneParamRet_0x4BD
	call	SndDispatch_ProcessCommand_0x28B
	ld	w, 0:opc
	jp	SysEx_BytecodeDispatcher_0xDB
SysEx_BytecodeDispatcher_Skip3:
	call	ScoopParam_ValueTable_0x4E
	push	xiy
	call	MemConfig_Handler_4_0x15B
	pop	xiy
	call	SysInit_BytecodeBlock_0x413
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, MemoryConfig_Handler_Table
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
	jp	SysEx_BytecodeDispatcher_0xDB
SysEx_BytecodeDispatcher_Skip4:
	call	ScoopParam_ValueTable_0x4E
	call	SysInit_BytecodeBlock_0x43A
	call	SysInit_BytecodeBlock_0x11C
	call	SysInit_BytecodeBlock_0x155
	call	SysInit_BytecodeBlock_0x17A
	cp	l, 2:i3
	jrl	z, SysEx_BytecodeDispatcher_Skip
	cp	l, 3:i3
	jrl	z, SysEx_BytecodeDispatcher_Skip
	cp	l, 10
	jrl	z, SysEx_BytecodeDispatcher_Skip
	call	MemConfig_Handler_4_0x15B
SysEx_BytecodeDispatcher_Skip:
	call	SystemInit_Handler_Table_0x18
	ld	(3434:16), 0
	call	SubCPU_ToneParamRet_0x4BD
	call	SndDispatch_ProcessCommand_0x28B
	cp	w, 255
	jrl	nz, SysEx_BytecodeDispatcher_Skip5
	call	SysInit_SendAllNotesAndReset
	jp	SysEx_BytecodeDispatcher_0x108
SysEx_BytecodeDispatcher_Skip5:
	call	AccPedal_CheckBitAndUpdate
	ld	a, (3420:16)
	cpdi8	(0x0d57), 48
	jrl	nz, SysEx_BytecodeDispatcher_Skip6
	or	a, 128
SysEx_BytecodeDispatcher_Skip6:
	ld	(0x3719:16), a
	call	Display_BytecodeBlock_F_0x3A8
	call	Display_UpdateRegion3
	ret
	; Handler dispatch table, 24 B.  Read by SysEx_BytecodeDispatcher (0xEFAADB): `ld xix, MemoryConfig_Handler_Table`
	; indexed with stride 4 (`sla hl, 2`)
	; 6 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
MemoryConfig_Handler_Table:
	.long	MemConfig_Handler_0
	.long	MemConfig_Handler_1
	.long	MemoryConfig_Handler_Table_Target2
	.long	MemConfig_Handler_3
	.long	MemConfig_Handler_4
	.long	MemConfig_Handler_5
	ld	xiy, SysEx_BytecodeDispatcher_Tbl
	ld	xix, 3471
	ld	a, 176:opc
	ld	(xix), a
	ld	a, (3415:16)
	ldfr_lerp	xiy, 56
	lda_rr	xiy, xiy, hl
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
	ld_rrb	a, xiy, hl
	bit	7, a
	jrl	z, SysEx_BytecodeDispatcher_Skip8
	ormi8	(xix), 1
	ld	(xix+4), w
	jp	MemoryConfig_Handler_Table_0x67
SysEx_BytecodeDispatcher_Skip8:
	ld	(xix+4), a
	ldfr_lerp	xiy, 56
	lda_rr	xiy, xiy, hl
	ld	a, (xiy+1)
	ldto_lerp	xiy, 56
	bit	7, a
	jrl	z, SysEx_BytecodeDispatcher_Skip9
	ormi8	(xix), 2
	ld	(xix+5), w
	jp	MemoryConfig_Handler_Table_0x88
SysEx_BytecodeDispatcher_Skip9:
	ld	(xix+5), a
	push	xiy
	ld	w, 6:opc
	ld	xiy, 3471
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	SystemInit_StepHandler_0_Helper2
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	pop	xiy
	ldfr_lerp	xiy, 56
	lda_rr	xiy, xiy, hl
	ld	w, (xiy+3)
	ldto_lerp	xiy, 56
	ret
	; Byte data, 97 B.  Read by SysEx_BytecodeDispatcher (0xEFAADB): `ld xiy, SysEx_BytecodeDispatcher_Tbl`
	; reader SysEx_BytecodeDispatcher: `ld xiy, SysEx_BytecodeDispatcher_Tbl` then `lda_rr xiy, xiy, hl`
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
	setda	1, (0x10f9)
MemoryConfig_Handler_Table_Target2_Sub:
	call	MemConfig_Handler_4_Helper
	ld	xiz, 0x0d53
	andmi8	(xiz), 191
	call	MemConfig_VoiceSlotLookup
	call	ClockConfig_Handler_0_0xAB
MemoryConfig_Handler_Table_Target2_Join:
	cpdi8	(0x0d65), 0
	jrl	nz, MemoryConfig_Handler_Table_Target2_Entry
	stdi8	(0x0d6a), 0
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jr	nz, MemoryConfig_Handler_Table_Code_Sub_Skip
	call	Interrupt_FlagSetBytecode_0x13
MemoryConfig_Handler_Table_Code_Sub_Skip:
	call	SubCPU_ToneParamRet_0x4BD
	call	DMA_FlagCheckWithCalls
	call	SndDispatch_ProcessCommand_0x28B
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
	ld	xhl, 3412
	bitm	3, (xhl)
	jrl	z, MemConfig_Handler_0_Skip3
	resm	3, (xhl)
	call	PortConfig_SetupBytecode_0x34
	jp	MemConfig_Handler_0_0x63
MemConfig_Handler_0_Skip3:
	call	VoiceCtrl_BytecodeHandler
	cp	b, 22
	jrl	z, MemConfig_Handler_0_Skip2
	cp	b, 23
	jrl	z, MemConfig_Handler_0_Skip2
	call	VoiceSlot_FlagCheck
	cp	w, 255
	jrl	z, MemConfig_Handler_0_Skip
	xor	a, a
	call	VoiceSlot_SaveState
	ld	w, 129:opc
	call	VoiceSlot_FinalRetZ_0x84
	ld	de, 1:i3
	call	VoiceSlot_FinalRetZ_0xB8
	ld	w, 130:opc
	call	VoiceSlot_FinalRetZ_0x84
	xor	a, a
	call	VoiceSlot_RestoreState
	call	MemConfig_Handler_1_0x8B
MemConfig_Handler_0_Skip:
	ld	w, 255:opc
	ordi8	(0x8d88), 1
	jp	MemConfig_Handler_0_0x63
MemConfig_Handler_0_Skip2:
	call	VoiceSlot_LoadAndDispatch
	jp	MemConfig_Handler_0_0x24
	ret
MemConfig_Handler_1:
	resda	7, (0x0d54)
	call	VoiceCtrl_BytecodeHandler
	cp	b, 22
	jrl	z, MemConfig_Handler_1_Skip2
	cp	b, 23
	jrl	z, MemConfig_Handler_1_Skip2
	xor	a, a
	call	VoiceSlot_SaveState
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, MemConfig_Handler_1_Code_Skip2
MemConfig_Handler_1_Code_Loop:
	call	VoiceSlot_CompareAndBranch
	cp	w, 255
	jrl	z, MemConfig_Handler_1_Code_Skip2
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, MemConfig_Handler_1_Code_Skip
	and	a, 240
	cp	a, 144
	jrl	z, MemConfig_Handler_1_Code_Skip
	cp	a, 176
	jrl	nz, MemConfig_Handler_1_Code_Loop
MemConfig_Handler_1_Code_Skip:
	pushw	wa
	xor	a, a
	call	VoiceSlot_RestoreState
	popw	wa
	cp	a, 129
	jrl	nz, MemConfig_Handler_1_Skip
	ld	w, 132:opc
	call	VoiceSlot_FinalRetZ_0x84
	ld	de, 1:i3
	call	VoiceSlot_FinalRetZ_0xB8
	ld	w, 132:opc
	call	VoiceSlot_FinalRetZ_0x84
	xor	a, a
	call	VoiceSlot_RestoreState
	call	MemConfig_Handler_1_0x8B
MemConfig_Handler_1_Code_Skip2:
	ld	w, 255:opc
	ordi8	(0x8d88), 1
	jp	MemConfig_Handler_1_0x8A
MemConfig_Handler_1_Skip:
	ld	w, 129:opc
	jp	MemConfig_Handler_1_0x57
MemConfig_Handler_1_Skip2:
	call	VoiceSlot_LoadAndDispatch
	jp	MemConfig_Handler_1_0x14
	ret
	call	VoiceSlot_ComputeWordIndex
	push	xix
	ld	xix, 3230
	ld_rrw iy, xix, iz
	pop xix
	cp	iy, 0xffff
	jrl	nz, MemConfig_Handler_1_Code_Skip3
	jp	MemConfig_Handler_1_0x13D
MemConfig_Handler_1_Code_Skip3:
	srl	iz, 1
	push	xix
	ld	xix, 3262
	ld_rrb a, xix, iz
	pop xix
	xor	w, w
	inc	1, wa
	cp	wa, 255
	jrl	ule, MemConfig_Handler_1_Skip3
	push	xix
	ld	xix, 0xf218
	stib_ind 0x07, 0xf0, 0xf8, 0x05	; ld (XIX+IZ),0x05
	sla	iz, 1
	ld	xix, 3230
	ld_rrw iy, xix, iz
	pop xix
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	iy, (xhl+3)
	push	xix
	ld	xix, 0xf1f8
	st_rrw iy, xix, iz
	pop	xix
	cp	iy, 0xffff
	jrl	z, MemConfig_Handler_1_Return
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	iy, (xhl+3)
	cp	iy, 0xffff
	jrl	z, MemConfig_Handler_1_Return
	ld	wa, (0x286d:16)
	call	VoiceSlot_FinalRetZ_0x1B2
	jp	MemConfig_Handler_1_0x13D
MemConfig_Handler_1_Skip3:
	push	xix
	ld	xix, 0xf218
	st_rrb	a, xix, iz
	sla	iz, 1
	ld	xix, 0x0c9e
	ld_rrw iy, xix, iz
	ld xix, 61944
	st_rrw iy, xix, iz
	pop	xix
	jp	MemConfig_Handler_1_0xF8
MemConfig_Handler_1_Return:
	ret
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, MemConfig_Handler_1_Skip5
	cp	a, 132
	jrl	z, MemConfig_Handler_1_Skip5
	ld	a, 3:opc
	call	VoiceSlot_SaveState
	ld	a, (3421:16)
	sub	a, (3420:16)
	call	MemConfig_Handler_1_0x1C6
	ld	a, 4:opc
	call	VoiceSlot_SaveState
	ld	a, 3:opc
	call	VoiceSlot_RestoreState
MemConfig_Handler_1_Loop:
	call	MemConfig_Handler_3_0xAC
	cpdi8	(0x0d6a), 0
	jrl	nz, MemConfig_Handler_1_Skip4
	ld	a, 4:opc
	call	VoiceState_DataBlock2_0x7D
	cp	w, 1:i3
	jrl	z, MemConfig_Handler_1_Skip4
	cp	w, 2:i3
	jrl	nz, MemConfig_Handler_1_Loop
	bitda	7, (0x0d53)
	jrl	nz, MemConfig_Handler_1_Skip4
	ld	a, 4:opc
	call	VoiceSlot_RestoreState
MemConfig_Handler_1_Skip4:
	call	AccPedal_CheckBitAndUpdate
	ld	(3434:16), 0
	call	SubCPU_ToneParamRet_0x4BD
	call	Display_BytecodeBlock_F_0x3A8
	call	SndDispatch_ProcessCommand_0x266
	call	SndDispatch_ProcessCommand_0x28B
MemConfig_Handler_1_Skip5:
	ld	(3434:16), 0
	call	AccPedal_CheckBitAndUpdate
	xor	a, a
	ld	(3415:16), a
	ld	a, (3420:16)
	ld	(0x3719:16), a
	ret
	ld	(3582:16), a
MemConfig_Handler_1_Loop2:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, MemConfig_Handler_1_Skip6
	incw	1, (3416:16)
	dec	1, (3582:16)
MemConfig_Handler_1_Skip6:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, MemConfig_Handler_1_Return2
	cpdi8	(0x0dfe), 0
	jrl	nz, MemConfig_Handler_1_Loop2
MemConfig_Handler_1_Return2:
	ret
	ld	a, 3:opc
	call	VoiceSlot_SaveState
	ld	a, (3420:16)
	add	a, (3421:16)
	call	MemConfig_Handler_1_0x295
	call	AccPedal_CheckBitAndUpdate
	cpdi8	(0x0d5c), 0
	jrl	z, MemConfig_Handler_1_Skip7
	ld	a, (3420:16)
	call	MemConfig_Handler_1_0x295
MemConfig_Handler_1_Skip7:
	ld	a, 4:opc
	call	VoiceSlot_SaveState
	call	MemConfig_Handler_4_0x2F
	ld	a, 5:opc
	call	VoiceSlot_SaveState
MemConfig_Handler_1_Loop3:
	ld	a, 6:opc
	call	VoiceSlot_SaveState
	call	MemConfig_Handler_3_0xAC
	cpdi8	(0x0d6a), 0
	jrl	nz, MemConfig_Handler_1_Skip9
	ld	a, 4:opc
	call	VoiceState_DataBlock2_0x7D
	cp	w, 1:i3
	jrl	z, MemConfig_Handler_1_Skip8
	cp	w, 2:i3
	jrl	nz, MemConfig_Handler_1_Loop3
	bitda	7, (0x0d53)
	jrl	z, MemConfig_Handler_1_Skip8
	ld	a, 6:opc
	jp	MemConfig_Handler_1_0x256
MemConfig_Handler_1_Skip8:
	ld	a, 4:opc
	call	VoiceSlot_RestoreState
MemConfig_Handler_1_Skip9:
	call	AccPedal_CheckBitAndUpdate
	call	VoiceState_DataBlock2_0xAD
	cp	w, 255
	jrl	z, MemConfig_Handler_1_Skip10
	xor	a, a
	ld	(3415:16), a
	ld	a, (3420:16)
	ld	(0x3719:16), a
MemConfig_Handler_1_Skip10:
	call	SubCPU_ToneParamRet_0x4BD
	call	Display_BytecodeBlock_F_0x3A8
	call	SndDispatch_ProcessCommand_0x266
	call	SndDispatch_ProcessCommand_0x28B
	xor	a, a
	ld	(3415:16), a
	ld	a, (3420:16)
	ld	(0x3719:16), a
	ret
	ld	(3582:16), a
MemConfig_Handler_1_Code_Loop2:
	call	VoiceSlot_CompareAndBranch
	cp	w, 255
	jrl	z, MemConfig_Handler_1_Code_Return
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, MemConfig_Handler_1_Code_Loop2
	ld	xiy, 3582
	decm8	1, (xiy)
	cp	(xiy), 0
	jrl	nz, MemConfig_Handler_1_Code_Loop2
MemConfig_Handler_1_Loop4:
	ld	a, 6:opc
	call	VoiceSlot_SaveState
	call	VoiceSlot_CompareAndBranch_0x7
	cp	w, 255
	jrl	z, MemConfig_Handler_1_Code_Return
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, MemConfig_Handler_1_Loop4
	ld	a, 6:opc
	call	VoiceSlot_RestoreState
MemConfig_Handler_1_Code_Return:
	ret
MemConfig_Handler_3:
	call	MemConfig_Handler_3_0x1F
	call	MemConfig_Handler_3_0xAC
	call	MemConfig_Handler_3_0x42
	call	SndDispatch_ProcessCommand_0x278
	call	SndDispatch_ProcessCommand_0x28B
	cpdi8	(0x0d6a), 0
	jrl	z, MemConfig_Handler_3_Next
MemConfig_Handler_3_Next:
	ld	w, 0:opc
	ret
	pushw	wa
	ld	wa, (0x371a:16)
	ld	(3816:16), wa
	ld	wa, (3416:16)
	ld	(3818:16), wa
	ld	a, (3415:16)
	ld	(3820:16), a
	ld	a, (3420:16)
	ld	(3821:16), a
	popw	wa
	ret
	call	AccPedal_CheckBitAndUpdate
	ld	wa, (3816:16)
	cp	wa, (14106:16)
	jrl	nz, MemConfig_Handler_3_Loop
	ld	wa, (3818:16)
	cp wa, (3416:16)
	jrl	nz, MemConfig_Handler_3_Skip
	ld	a, (3820:16)
	cp a, (3415:16)
	jrl z, MemConfig_Handler_3_Return
	call MemConfig_Handler_3_Helper
	cp w, 0:i3
	jrl z, MemConfig_Handler_3_Return
	jp	MemConfig_Handler_3_0x8E
MemConfig_Handler_3_Skip:
	cpdi8	(0x0d5d), 4
	jrl	ule, MemConfig_Handler_3_Skip2
	ld	a, (3821:16)
	ld	w, (3420:16)
	cp	a, 4:i3
	jrl	ule, MemConfig_Handler_3_Skip3
	cp	w, 4:i3
	jrl	c, MemConfig_Handler_3_Loop
MemConfig_Handler_3_Skip2:
	call	SubCPU_ToneParamRet_0x7C1
	call	Display_UpdateRegion2
	jp	MemConfig_Handler_3_0xAB
MemConfig_Handler_3_Loop:
	call	SubCPU_ToneParamRet_0x4BD
	jp	MemConfig_Handler_3_0xAB
MemConfig_Handler_3_Skip3:
	cp	w, 3:i3
	jrl	ugt, MemConfig_Handler_3_Loop
	jp	MemConfig_Handler_3_0x8E
MemConfig_Handler_3_Return:
	ret
	ld	(0x3728:16), 0
	ld	a, (3415:16)
	ld	(3521:16), a
	call	SndDispatch_ProcessCommand_0xF
	xor	w, w
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_JumpTable_Main
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
	ret
	; Handler dispatch table, 44 B.  Read by MemConfig_Handler_3 (0xEFB0D3): `ld xix, SndDispatch_JumpTable_Main`
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
	call	SndDispatch_ProcessCommand_0xF9
	call	SndDispatch_ProcessCommand_0xA5
	cp	a, 0:i3
	jrl	z, SndDispatch_Handler_1_Return
	dec	1, a
	xor	w, w
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_SubTable_1
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
SndDispatch_Handler_1_Return:
	ret
	; Handler dispatch table, 24 B.  Read by SndDispatch_Handler_1 (0xEFB1D2): `ld xix, SndDispatch_SubTable_1`
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
	call	SndDispatch_ProcessCommand_0xF9
	call	SndDispatch_ProcessCommand_0xA5
	cp	a, 0:i3
	jrl	z, SndDispatch_Handler_2_Return
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_SubTable_2
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
SndDispatch_Handler_2_Return:
	ret
	; Handler dispatch table, 24 B.  Read by SndDispatch_Handler_2 (0xEFB20F): `ld xix, SndDispatch_SubTable_2`
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
	call	SndDispatch_ProcessCommand_0xF9
	call	SndDispatch_ProcessCommand_0xA5
	cp	a, 0:i3
	jrl	z, SndDispatch_TableEntryBegin_Return
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_BytecodeString
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
SndDispatch_TableEntryBegin_Return:
	ret
	; Handler dispatch table, 24 B.  Read by SndDispatch_TableEntryBegin (0xEFB24C): `ld xix, SndDispatch_BytecodeString`
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
	call	SndDispatch_ProcessCommand_0xF9
	call	SndDispatch_ProcessCommand_0xA5
	cp	a, 0:i3
	jrl	z, SndDispatch_Handler_3_Return
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_SubTable_4
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
SndDispatch_Handler_3_Return:
	ret
	; Handler dispatch table, 24 B.  Read by SndDispatch_Handler_3 (0xEFB28E): `ld xix, SndDispatch_SubTable_4`
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
	call	SndDispatch_ProcessCommand_0xF9
	call	SndDispatch_ProcessCommand_0xA5
	cp	a, 0:i3
	jrl	z, SndDispatch_Handler_4_Return
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_Handler_4_DispatchTbl
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
SndDispatch_Handler_4_Return:
	ret
	; Handler dispatch table, 24 B.  Read by SndDispatch_Handler_4 (0xEFB2CB): `ld xix, SndDispatch_Handler_4_DispatchTbl`
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
	cpdi8	(0x0d6a), 0
	jrl	nz, SndDispatch_InitHandler_Return
	ld	(3415:16), 0
SndDispatch_InitHandler_Return:
	ret
SndDispatch_SetFlag30:
	ld	(3415:16), 48
	ret
SndDispatch_ProcessCommand:
	call	VoiceSlot_FlagCheck
	bit	7, a
	jrl	nz, SndDispatch_ProcessCommand_Return
	ld	(3415:16), a
SndDispatch_ProcessCommand_Return:
	ret
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
	ret
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	nz, SndDispatch_ProcessCommand_Skip11
	ld	a, 6:opc
	jp	SndDispatch_ProcessCommand_0xF8
SndDispatch_ProcessCommand_Skip11:
	cp	a, 129
	jrl	nz, SndDispatch_ProcessCommand_Skip12
	ld	a, 1:opc
	jp	SndDispatch_ProcessCommand_0xF8
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
	jp	SndDispatch_ProcessCommand_0xF8
SndDispatch_ProcessCommand_Skip13:
	ld	a, 5:opc
	jp	SndDispatch_ProcessCommand_0xF8
SndDispatch_ProcessCommand_Skip14:
	cp	(xiy), a
	jrl	nz, SndDispatch_ProcessCommand_Skip21
	ld	a, 2:opc
	jp	SndDispatch_ProcessCommand_0xF8
SndDispatch_ProcessCommand_Skip21:
	ld	a, 3:opc
	ret
	xor	a, a
	ld	(3580:16), a
	ld	(3581:16), a
	ld	(3434:16), a
	anddi8	(0x0d53), 127
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, SndDispatch_ProcessCommand_Skip17
	call	VoiceSlot_ReadCurrentParams
	ld	(3581:16), a
	cp	a, 129
	jrl	nz, SndDispatch_ProcessCommand_Loop
	incw	1, (3416:16)
	ld	(3580:16), 1
SndDispatch_ProcessCommand_Loop:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, SndDispatch_ProcessCommand_Skip15
	call	VoiceSlot_DispatchRet
	jp	SndDispatch_ProcessCommand_0x143
SndDispatch_ProcessCommand_Skip15:
	call	VoiceSlot_LoadAndDispatch
	cp	w, 255
	jrl	z, SndDispatch_ProcessCommand_Return2
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	z, SndDispatch_ProcessCommand_Entry
	cp	a, 129
	jrl	z, SndDispatch_ProcessCommand_Skip16
SndDispatch_ProcessCommand_Loop2:
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, SndDispatch_ProcessCommand_Skip17
	cp	a, 132
	jrl	z, SndDispatch_ProcessCommand_Skip17
	cp	a, 47
	jrl	z, SndDispatch_ProcessCommand_Skip22
	cp	a, 95
	jrl	nz, SndDispatch_ProcessCommand_Return2
SndDispatch_ProcessCommand_Skip22:
	call	VoiceSlot_LoadAndDispatch
	cp	w, 255
	jrl	z, SndDispatch_ProcessCommand_Return2
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	z, SndDispatch_ProcessCommand_Return2
	cp	a, 129
	jrl	nz, SndDispatch_ProcessCommand_Loop2
SndDispatch_ProcessCommand_Skip16:
	ld	(3580:16), 1
	cpdi8	(0x0dfd), 129
	jrl	z, SndDispatch_ProcessCommand_Loop
	jp	SndDispatch_ProcessCommand_0x159
	jp	SndDispatch_ProcessCommand_0x265
SndDispatch_ProcessCommand_Skip17:
	ld	(3434:16), 255
	jp	SndDispatch_ProcessCommand_0x265
SndDispatch_ProcessCommand_Entry:
	cpdi8	(0x0dfc), 0
	jrl	nz, SndDispatch_ProcessCommand_Return2
	ld	a, (3581:16)
	and	a, 240
	cp	a, 176
	jrl	z, SndDispatch_ProcessCommand_Return2
	call	SndDispatch_ProcessCommand_0x2A4
	call	SndDispatch_ProcessCommand_0x2C7
	call	VoiceSlot_FlagCheck
	ld	(3526:16), a
SndDispatch_ProcessCommand_Loop3:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, SndDispatch_ProcessCommand_Return2
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	nz, SndDispatch_ProcessCommand_Skip18
	call	VoiceSlot_FlagCheck
	cp a, (3526:16)
	jrl	z, SndDispatch_ProcessCommand_Loop3
	ld	(3415:16), 0
	jp	SndDispatch_ProcessCommand_0x265
SndDispatch_ProcessCommand_Skip18:
	call	VoiceSlot_FlagCheck
	cp	a, 47
	jrl	z, SndDispatch_ProcessCommand_Loop3
	cp	a, 95
	jrl	z, SndDispatch_ProcessCommand_Loop3
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, SndDispatch_ProcessCommand_Return2
	ordi8	(0x0d53), 128
	ld	(3580:16), 1
	ld	a, (3579:16)
	exts	wa
	add (3416:16), wa
	ld de, wa
	call	VoiceSlot_FinalRetZ_0xB8
	call	VoiceSlot_ReadCurrentParams
	cp	a, 130
	jrl	z, SndDispatch_ProcessCommand_Skip23
	and	a, 240
	cp	a, 144
	jrl	z, SndDispatch_ProcessCommand_Return2
	cp	a, 176
	jrl	z, SndDispatch_ProcessCommand_Return2
	bit	7, a
	jrl	nz, SndDispatch_ProcessCommand_Skip19
	call	VoiceSlot_LoadAndDispatch
SndDispatch_ProcessCommand_Skip19:
	jp	SndDispatch_ProcessCommand_0x265
SndDispatch_ProcessCommand_Skip23:
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	call	SysInit_BytecodeBlock_0xFF
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
SndDispatch_ProcessCommand_Return2:
	ret
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jr	nz, SndDispatch_ProcessCommand_Skip20
	call	Interrupt_FlagSetBytecode_0x13
SndDispatch_ProcessCommand_Skip20:
	call	DMA_FlagCheckWithCalls
	ret
	call	DMA_FlagCheckWithCalls
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	nz, SndDispatch_ProcessCommand_Return3
	call	Interrupt_SetFlagBytecode
SndDispatch_ProcessCommand_Return3:
	ret
	call	Display_UpdateRegion0
	call	Display_UpdateRegion1
	call	Display_UpdateRegion6
	call	Display_UpdateRegion3
	call	SubCPU_ToneParamRet_0x7C1
	call	Display_UpdateRegion2
	ret
	xor	a, a
	call	VoiceSlot_SaveState
	ld	de, 4:i3
	call	VoiceSlot_FinalRetZ_0xB8
	call	VoiceSlot_FinalRetZ
	ld	(3575:16), a
	call	VoiceSlot_ReadCurrentParams
	ld	(3576:16), a
	xor	a, a
	call	VoiceSlot_RestoreState
	ret
	ld	a, (3576:16)
	ld	(3579:16), a
	ld	a, (3521:16)
	add	a, (3575:16)
	cp	a, 96
	jrl	c, SndDispatch_ProcessCommand_Skip24
	inc	1, (3579:16)
	sub	a, 96
SndDispatch_ProcessCommand_Skip24:
	ld	(3415:16), a
	ret
MemConfig_Handler_4:
	ld	xhl, 4345
	bitm	1, (xhl)
	jrl	z, MemConfig_Handler_4_Skip9
	resm	1, (xhl)
	call	VoiceState_DataBlock2_0x5F2
	setda	2, (0x10f9)
	jp	MemConfig_Handler_4_0x2E
MemConfig_Handler_4_Skip9:
	call	MemConfig_Handler_3_0x1F
	call	MemConfig_Handler_4_0x2F
	call	SubCPU_ToneParamRet_0x4BD
	call	SndDispatch_ProcessCommand_0x278
	call	SndDispatch_ProcessCommand_0x28B
	ld	w, 0:opc
	ret
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	call	VoiceState_DataBlock2_0xAD
	cp	w, 0:i3
	jrl	z, MemConfig_Handler_4_Skip2
	ld	a, (3415:16)
	ld	(3659:16), a
	call	MemConfig_Handler_4_0x95
	call	MemConfig_Handler_4_0x95
	ld	(3415:16), 0
MemConfig_Handler_4_Loop:
	ld	a, 2:opc
	call	VoiceSlot_SaveState
	call	MemConfig_Handler_3_0xAC
	ld	a, 1:opc
	call	VoiceState_DataBlock2
	cp	w, 1:i3
	jrl	z, MemConfig_Handler_4_Skip
	cp	w, 2:i3
	jrl	nz, MemConfig_Handler_4_Loop
	jp	MemConfig_Handler_4_0x7C
MemConfig_Handler_4_Skip:
	ld	a, (3659:16)
	cp a, (3415:16)
	jrl nz, MemConfig_Handler_4_Return
	ld a, 2:opc
	call	VoiceState_DataBlock1
	jp	MemConfig_Handler_4_0x94
MemConfig_Handler_4_Skip2:
	ld	(3415:16), 0
	ld	(3434:16), 0
	jp	MemConfig_Handler_4_0x94
MemConfig_Handler_4_Return:
	ret
MemConfig_Handler_4_Loop2:
	ld	(3434:16), 0
	call	VoiceSlot_CompareAndBranch
	cp	w, 255
	jrl	z, MemConfig_Handler_4_Skip7
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	z, MemConfig_Handler_4_Skip4
	cp	a, 129
	jrl	z, MemConfig_Handler_4_Loop2
	call	VoiceSlot_FlagCheck
	cp	a, 47
	jrl	z, MemConfig_Handler_4_Skip3
	cp	a, 95
	jrl	nz, MemConfig_Handler_4_Skip8
MemConfig_Handler_4_Skip3:
	call	VoiceSlot_CompareAndBranch
	cp	w, 255
	jrl	z, MemConfig_Handler_4_Skip7
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	z, MemConfig_Handler_4_Skip4
	cp	a, 129
	jrl	z, MemConfig_Handler_4_Loop2
	call	VoiceSlot_FlagCheck
	cp	a, 47
	jrl	z, MemConfig_Handler_4_Loop2
	cp	a, 95
	jrl	z, MemConfig_Handler_4_Loop2
	jp	MemConfig_Handler_4_0x158
MemConfig_Handler_4_Skip4:
	call	VoiceSlot_FlagCheck
	ld	(3522:16), a
	ld	(0x3728:16), 0
MemConfig_Handler_4_Loop3:
	call	VoiceSlot_CompareAndBranch
	cp	w, 255
	jrl	nz, MemConfig_Handler_4_Skip5
	call	MemConfig_VoiceSlotLookup
	call	ClockConfig_Handler_0_0xAB
	xor	wa, wa
	ld	(3416:16), wa
	ld	(3415:16), a
	jp	MemConfig_Handler_4_0x158
MemConfig_Handler_4_Skip5:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jrl	nz, MemConfig_Handler_4_Skip6
	call	VoiceSlot_FlagCheck
	cp a, (3522:16)
	jrl z, MemConfig_Handler_4_Loop3
	call	VoiceSlot_LoadAndDispatch
	jp	MemConfig_Handler_4_0x158
MemConfig_Handler_4_Skip6:
	cp	a, 129
	jrl	z, MemConfig_Handler_4_Skip10
	jp	MemConfig_Handler_4_0x134
MemConfig_Handler_4_Skip10:
	incw	1, (3416:16)
	jp	MemConfig_Handler_4_0x134
MemConfig_Handler_4_Skip7:
	ld	w, 255:opc
	ld	(3434:16), w
	jp	MemConfig_Handler_4_0x15A
MemConfig_Handler_4_Skip8:
	ld	w, 0:opc
	ret
MemConfig_Handler_4_Helper:
	ld	(0xfc5f:16), 0
	ld	(0xfc60:16), 0
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	a, 72:opc
	ld	w, 5:opc
	xor	e, e
	ld	d, 4:opc
	call	SysInit_BytecodeBlock_0x3DB
	ld	a, 72:opc
	ld	w, 6:opc
	ld	d, 4:opc
	xor	e, e
	call	SysInit_BytecodeBlock_0x3DB
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ret
MemConfig_Handler_4_Helper2:
	cpdi8	(0x0d65), 0
	jrl	nz, ScoopParam_ValueTable_Helper8_Return
	ld	a, (0xfc5d:16)
	and	a, 7
	cp	a, 1:i3
	jrl	nz, ScoopParam_ValueTable_Helper8_Skip
	jp	MemConfig_Handler_4_0x1BA
ScoopParam_ValueTable_Helper8_Skip:
	anddi8	(0xfc5d), 248
	ordi8	(0xfc5d), 2
	ld	a, 72:opc
	ld	w, 3:opc
	ld	e, 2:opc
	ld	d, 2:opc
	call	SysInit_BytecodeBlock_0x3DB
ScoopParam_ValueTable_Helper8_Return:
	ret

SysInit_SendAllNotesAndReset:
	ld (0x3728:16), 0
	call DisplayStr_StyleSectionInit
	xor wa, wa
	ld a, 0xa:opc
	call UI_PostPartChangeEvent
	ret


	; Handler dispatch table, 24 B.  Read by SysInit_SendAllNotesAndReset (0xEFB7C9): `ld xde, SystemInit_Handler_Table`
	; indexed with stride 4 (`sla wa, 2`)
	; 6 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
SystemInit_Handler_Table:
	.long	SystemInit_StepHandler_0
	.long	SystemInit_StepHandler_0
	.long	SystemInit_StepHandler_2
	.long	SystemInit_StepHandler_3
	.long	SystemInit_StepHandler_4
	.long	SystemInit_StepHandler_5
	push	xhl
	ld	a, l
	ld	xhl, VoiceCtrl_ParamSetupBytecode_Tbl4
	ld_rr8b	a, xhl, a
	ld	(0x3728:16), a
	ld	(3422:16), 16
	call	VoiceCtrl_ParamSetupBytecode_0x5E0
	pop	xhl
	sub	l, 2
	cp	l, 6:i3
	jrl	lt, SysInit_SendAllNotesAndReset_Skip
	sub	l, 2
SysInit_SendAllNotesAndReset_Skip:
	xor	h, h
	sla	hl, 3
	call	MemoryConfig_Handler_Table_0x18
	ld	a, w
	exts	wa
	sla	wa, 2
	ld	iy, wa
	push	xde
	ld	xde, SystemInit_Handler_Table
	ld_rrl	xiy, xde, iy
	pop	xde
	jp	(xiy)
SystemInit_StepHandler_5:
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	l, 5:opc
	call	SystemInit_StepHandler_0_0x4B
	call	SysInit_BytecodeBlock_0xC
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	add	hl, 4
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
	ld	w, 98:opc
	call	MIDI_SendSysExFromW
	ld	w, 0:opc
	ret
	; Byte data, 16 B.  Read by VoiceCtrl_ParamSetupBytecode (0xEF97E0): `ld xhl, VoiceCtrl_ParamSetupBytecode_Tbl4`
	; also read by SysInit_SendAllNotesAndReset
VoiceCtrl_ParamSetupBytecode_Tbl4:
	.byte	0x00, 0x00, 0x05, 0x06, 0x07, 0x0b, 0x03, 0x04, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00
	cpdi8	(0x0d65), 0
	jrl	nz, SystemInit_StepHandler_0_Skip2
	call	VoiceState_DataBlock2_0x1EC
	cpdi8	(0xcef1), 0
	jrl	z, SystemInit_StepHandler_0_Skip
	pushw	wa
	ld	d, a
	xor	e, e
	call	SystemInit_StepHandler_0_0x5E
	call	SysInit_BytecodeBlock_0xC
	popw	wa
SystemInit_StepHandler_0_Skip:
	exts	wa
	ld	bc, wa
	ld	l, 96:opc
	call	SysInit_BytecodeBlock_0x68
SystemInit_StepHandler_0_Skip2:
	ordi8	(0x0d53), 64
	ret
	xor	h, h
	sla	hl, 2
	extz	xhl
	push	xix
	ld	xix, SystemInit_StepHandler_0_Tbl
	ld_rrw de, xix, hl
	pop xix
	xor	a, a
	ld	(3437:16), a
	ld	(3438:16), a
	ld	(4391:16), a
	ld	xiz, 3471
	ld	xiy, 0xcef2
	ld	c, (0xcef1:16)
	cp	c, 0:i3
	jrl	z, SystemInit_StepHandler_0_Return
	ld	a, (0x8d40:16)
	ld	(3437:16), a
	ld	a, (0x8d42:16)
	ld	(3438:16), a
	ld	a, (0x8d44:16)
	ld	(4391:16), a
	ld (xiz+0:8), 144
	ld	a, (3415:16)
	ld	(xiz+1), a
	ld	a, (xiy)
	inc	1, xiy
	ld	(xiz+2), a
	ld	(xiz+3), 64
	ld	(xiz+4), de
	dec	1, c
	add	xiz, 6
	jp	SystemInit_StepHandler_0_0x7A
SystemInit_StepHandler_0_Return:
	ret
	; Byte data, 24 B.  Read by SystemInit_StepHandler_0 (0xEFB875): `ld xix, SystemInit_StepHandler_0_Tbl`
	; indexed with stride 4 (`sla hl, 2`)
SystemInit_StepHandler_0_Tbl:
	.byte	0x00, 0x04, 0x60, 0x04, 0x00, 0x03, 0x60, 0x03, 0x00, 0x02, 0x60, 0x02, 0x30, 0x01, 0x90, 0x01
	.byte	0x00, 0x01, 0x60, 0x01, 0x30, 0x00, 0x30, 0x01
	; Byte data, 6 B.  Read by SysEx_BytecodeDispatcher (0xEFAADB): `ld xix, SysInit_BytecodeBlock`
	; reader SysEx_BytecodeDispatcher: `ld xix, SysInit_BytecodeBlock` then `ld_rrb w, xix, hl`
SysInit_BytecodeBlock:
	.ascii	"P@0 "
	.byte	0x10, 0x00
	; Byte data, 6 B.  Read by SysEx_BytecodeDispatcher (0xEFAADB): `ld xde, SysEx_BytecodeDispatcher_Tbl2`
	; reader SysEx_BytecodeDispatcher: `ld xde, SysEx_BytecodeDispatcher_Tbl2` then `ld_rrb w, xde, hl`
SysEx_BytecodeDispatcher_Tbl2:
	.byte	0x01, 0x02, 0x03, 0x05, 0x04, 0x06
	ld	b, (0xcef1:16)
	sla	b, 1
	ld	c, b
	add	b, b
	add	b, c
	ld	w, b
	ld	xiy, 3471
	call	SysInit_BytecodeBlock_0x486
	ret
SystemInit_StepHandler_0_Loop:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, SystemInit_StepHandler_0_Skip3
	call	VoiceCtrl_BytecodeHandler
	cp	b, 22
	jrl	z, SystemInit_StepHandler_0_Loop
	cp	b, 23
	jrl	z, SystemInit_StepHandler_0_Loop
SystemInit_StepHandler_0_Skip3:
	ld	xiy, 3519
	call	SysInit_BytecodeBlock_0x413
	cp	l, 255
	jrl	z, SystemInit_StepHandler_0_Return2
	xor	h, h
	sla	hl, 2
	push	xde
	ld	xde, SystemInit_StepHandler_0_Tbl
	lda_rr xde, xde, hl
	ld	bc, (xde+2)
	pop	xde
	ld	l, c
	xor	c, c
	ex8	c, b
	ld	a, (3415:16)
	ld	(3578:16), a
	add	a, l
	cp	a, 96
	jrl	c, SystemInit_StepHandler_0_Skip4
	sub	a, 96
	ld	(3415:16), a
	call	SysInit_BytecodeBlock_0xFB
	cp	a, 96
	jrl	c, SystemInit_StepHandler_0_Skip4
	sub	a, 96
	ld	(3415:16), a
	call	SysInit_BytecodeBlock_0xFB
SystemInit_StepHandler_0_Skip4:
	djnz16	bc, -39
	ld	(3415:16), a
	cp	a, (0x0dfa:16)
	jrl	z, SystemInit_StepHandler_0_Return2
	call	MemConfig_Handler_5_0x1BF
SystemInit_StepHandler_0_Return2:
	ret
	call	VoiceState_DataBlock2_0x10C
	cp	w, 255
	jrl	z, SystemInit_StepHandler_0_Skip5
	cp	c, 2:i3
	jrl	ule, SystemInit_StepHandler_0_Return3
SystemInit_StepHandler_0_Skip5:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, SystemInit_StepHandler_0_Return3
	call	VoiceSlot_LoadAndDispatch
	jp	SysInit_BytecodeBlock_0xA7
SystemInit_StepHandler_0_Return3:
	ret
	xor	a, a
	call	VoiceSlot_SaveState
	call	VoiceSlot_FlagCheck
	cp	a, 132
	jrl	nz, SystemInit_StepHandler_0_Skip6
	setda	7, (0x0d54)
SystemInit_StepHandler_0_Skip6:
	call	SysInit_BytecodeBlock_0xFF
	xor	a, a
	call	VoiceSlot_RestoreState
	ret
	call	VoiceSlot_FlagCheck
	cp	a, 132
	jrl	nz, SystemInit_StepHandler_0_Skip7
	setda	7, (0x0d54)
SystemInit_StepHandler_0_Skip7:
	call	SysInit_BytecodeBlock_0xFF
	ret
SystemInit_StepHandler_0_Helper:
	incw	1, (3416:16)
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	w, 1:opc
	ld	xiy, 3656
	ld	(xiy), 129
	call	SysInit_BytecodeBlock_0x486
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ret
	cp	l, 2:i3
	jrl	z, SystemInit_StepHandler_0_Skip8
	cp	l, 10
	jrl	nz, SystemInit_StepHandler_0_Return4
SystemInit_StepHandler_0_Skip8:
	pushw	hl
	call	VoiceState_DataBlock2_0xAD
	popw	hl
	cp	w, 255
	jrl	z, SystemInit_StepHandler_0_Skip9
	jp	SysInit_BytecodeBlock_0x154
SystemInit_StepHandler_0_Skip9:
	xor	wa, wa
	cp (3416:16), wa
	jrl	nz, SystemInit_StepHandler_0_Skip10
	cp	(3415:16), a
	jrl	z, SystemInit_StepHandler_0_Return4
SystemInit_StepHandler_0_Skip10:
	cp	l, 2:i3
	jrl	z, SystemInit_StepHandler_0_Skip11
	ld	l, 5:opc
	jp	SysInit_BytecodeBlock_0x154
SystemInit_StepHandler_0_Skip11:
	ld	l, 4:opc
SystemInit_StepHandler_0_Return4:
	ret
	cp	l, 7:i3
	jrl	nz, SystemInit_StepHandler_0_Return5
	call	VoiceState_DataBlock2_0xAD
	cp	w, 0:i3
	jrl	z, SystemInit_StepHandler_0_Skip12
	jp	SysInit_BytecodeBlock_0x179
SystemInit_StepHandler_0_Skip12:
	xor	wa, wa
	cp (3416:16), wa
	jrl	nz, SystemInit_StepHandler_0_Return5
	cp	(3415:16), a
	jrl	nz, SystemInit_StepHandler_0_Return5
	ld	l, 3:opc
SystemInit_StepHandler_0_Return5:
	ret
	cp	l, 10
	jrl	nz, SystemInit_StepHandler_0_Return6
	call	VoiceState_DataBlock2_0xAD
	cp	w, 255
	jrl	z, SystemInit_StepHandler_0_Skip13
	jp	SysInit_BytecodeBlock_0x1A0
SystemInit_StepHandler_0_Skip13:
	xor	wa, wa
	cp (3416:16), wa
	jrl	nz, SystemInit_StepHandler_0_Return6
	cp	(3415:16), a
	jrl	nz, SystemInit_StepHandler_0_Return6
	ld	l, 5:opc
SystemInit_StepHandler_0_Return6:
	ret
	ld	xhl, 3412
	bitm	7, (xhl)
	jrl	z, ScoopParam_ValueTable_Helper9_Return
	resm	7, (xhl)
	call	VoiceState_DataBlock2_0x184
	cp	w, 0:i3
	jrl	nz, ScoopParam_ValueTable_Helper9_Return
	call	VoiceSlot_ComputeWordIndex
	push	xix
	ld	xix, 0xf1f8
	ld_rrw wa, xix, iz
	ld xix, 3230
	st_rrw wa, xix, iz
	srl	xiz, 1
	ld	xix, 0xf218
	ld_rrb	a, xix, iz
	ld	xix, 0x0cbe
	st_rrb	a, xix, iz
	pop	xix
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	nz, ScoopParam_ValueTable_Helper9_Skip
	call	VoiceSlot_CompareAndBranch_0x7
	cp	w, 255
	jrl	z, ScoopParam_ValueTable_Helper9_Return
	jp	SysInit_BytecodeBlock_0x1E7
ScoopParam_ValueTable_Helper9_Skip:
	cp	a, 129
	jrl	nz, ScoopParam_ValueTable_Helper9_Return
	xor	a, a
	call	VoiceSlot_SaveState
	ld	w, 132:opc
	call	VoiceSlot_FinalRetZ_0x84
	ld	de, 1:i3
	call	VoiceSlot_FinalRetZ_0xB8
	ld	w, 132:opc
	call	VoiceSlot_FinalRetZ_0x84
	xor	a, a
	call	VoiceSlot_RestoreState
	call	MemConfig_Handler_1_0x8B
ScoopParam_ValueTable_Helper9_Return:
	ret
	xor	a, a
	ld	(3822:16), a
ScoopParam_ValueTable_Helper9_Loop:
	ld	a, (3822:16)
	inc	1, a
	cp	a, 15
	jrl	ugt, SystemInit_StepHandler_0_Return7
	ld	(3822:16), a
	call	VoiceSlot_ComputeWordIndex
	srl	xiz, 1
	push	xix
	ld	xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf8, 0x0d	; cp (XIX+IZ),0x0d
	pop	xix
	jrl	nz, ScoopParam_ValueTable_Helper9_Loop
	call	VoiceState_DataBlock2_0x184
	cp	w, 0:i3
	jrl	nz, SystemInit_StepHandler_0_Return7
	call	VoiceSlot_ComputeIndex
	push	xix
	ld	xix, 0xf250
	add	xix, xiz
	ld	de, (xix+1)
	pop	xix
	call	VoiceSlot_ComputeWordIndex
	push	xix
	ld	xix, 3230
	st_rrw de, xix, iz
	srl	xiz, 1
	ld	xix, 3262
	stib_ind 0x07, 0xf0, 0xf8, 0x05	; ld (XIX+IZ),0x05
	pop	xix
	ld	a, 1:opc
	call	VoiceSlot_SaveState
	call	VoiceSlot_ReadCurrentParams
	ld	w, a
	and	a, 240
	cp	a, 176
	jrl	z, ScoopParam_ValueTable_Helper9_Skip2
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, SystemInit_StepHandler_0_Return7
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, SystemInit_StepHandler_0_Return7
	cp	a, 132
	jrl	z, SystemInit_StepHandler_0_Return7
	jp	SysInit_BytecodeBlock_0x28C
	jp	SysInit_BytecodeBlock_0x3DA
ScoopParam_ValueTable_Helper9_Skip2:
	and	w, 1
	rrc	w
	ld	(3528:16), w
	cp	a, 176
	jrl	nz, SystemInit_StepHandler_0_Skip16
	call	VoiceSlot_FlagCheck
	cp	a, 48
	jrl	z, SystemInit_StepHandler_0_Skip14
	cp	a, 96
	jrl	nz, SystemInit_StepHandler_0_Skip16
SystemInit_StepHandler_0_Skip14:
	ld	a, 2:opc
	call	VoiceSlot_SaveState
	ld	de, 4:i3
	call	VoiceSlot_FinalRetZ_0xB8
	call	VoiceSlot_ReadCurrentParams
	or	a, (3528:16)
	cp	a, 0:i3
	jrl	nz, SystemInit_StepHandler_0_Skip15
	ld	a, 2:opc
	call	VoiceSlot_RestoreState
	ld	de, 1:i3
	call	VoiceSlot_FinalRetZ_0xB8
	call	VoiceSlot_ReadCurrentParams
	dec	1, a
	ld	w, a
	call	VoiceSlot_FinalRetZ_0x84
SystemInit_StepHandler_0_Skip15:
	ld	a, 2:opc
	call	VoiceSlot_RestoreState
SystemInit_StepHandler_0_Skip16:
	call	VoiceSlot_FlagCheck
	ld	(3658:16), a
	xor	a, a
	ld	(3657:16), a
SystemInit_StepHandler_0_Loop2:
	call	VoiceSlot_DispatchRet
	inc	1, (3657:16)
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, SystemInit_StepHandler_0_Skip17
	cp	a, 129
	jrl	nz, SystemInit_StepHandler_0_Skip18
SystemInit_StepHandler_0_Skip17:
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	jp	SysInit_BytecodeBlock_0x2A1
SystemInit_StepHandler_0_Skip18:
	call	VoiceSlot_FlagCheck
	cp	(3658:16), a
	jrl	ule, SystemInit_StepHandler_0_Loop2
SystemInit_StepHandler_0_Loop3:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, SystemInit_StepHandler_0_Skip19
	call	VoiceSlot_FlagCheck
	cp	(3658:16), a
	jrl	ugt, SystemInit_StepHandler_0_Skip19
	inc	1, (3657:16)
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	nz, SystemInit_StepHandler_0_Loop3
	dec	1, (3657:16)
SystemInit_StepHandler_0_Skip19:
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	call	VoiceSlot_FinalRetZ
	ld	xiy, 3471
	ld	(3538:16), 0
	ld	(xiy), a
	inc	1, xiy
	inc	1, (3538:16)
	push	xiy
	call	VoiceSlot_FinalRetZ
	pop	xiy
	bit	7, a
	jrl	nz, SystemInit_StepHandler_0_Skip20
	ld	(xiy), a
	jp	SysInit_BytecodeBlock_0x392
SystemInit_StepHandler_0_Skip20:
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	call	ToneParam_HandlerTable_BC_0x4DC
	ld	c, (3657:16)
	xor	b, b
	pushw	bc
	call	VoiceSlot_DispatchRet
	popw	bc
	djnz16	bc, -9
	ld	xiy, 3471
	ld	w, (3538:16)
	call	SysInit_BytecodeBlock_0x486
	ld	a, 1:opc
	call	VoiceSlot_RestoreState
	jp	SysInit_BytecodeBlock_0x2AB
SystemInit_StepHandler_0_Return7:
	ret
	push	xix
	pushw	hl
	ld	xix, 0xbf39
	ld	hl, (0x90e2:16)
	st_rrw	wa, xix, hl
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, hl
	ld	(xix+2), de
	ldto_lerp	xix, 56
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, hl
	ld	(xix+4), 255
	ldto_lerp	xix, 56
	add	hl, 4
	ld	(0x90e2:16), hl
	popw	hl
	pop	xix
	ret
	pushw	bc
	xor	c, c
SystemInit_StepHandler_0_Loop4:
	ldfr_berp a, 60
	ld a, c
	scf
	xorcf	a, (xiy)
	ldto_berp a, 60
	jrl	nc, SystemInit_StepHandler_0_Skip21
	inc	1, c
	cp	c, 8
	jrl	c, SystemInit_StepHandler_0_Loop4
	ld	l, 255:opc
	popw	bc
	jp	SysInit_BytecodeBlock_0x439
SystemInit_StepHandler_0_Skip21:
	ld	l, c
	jp	SysInit_BytecodeBlock_0x42E
	ret
	push	xiy
	pushw	bc
	xor	c, c
SystemInit_StepHandler_0_Loop5:
	ldfr_berp a, 60
	ld a, c
	scf
	xorcf	a, (xiy)
	ldto_berp a, 60
	jrl	nc, SystemInit_StepHandler_0_Skip22
	inc	1, c
	cp	c, 8
	jrl	c, SystemInit_StepHandler_0_Loop5
	xor	c, c
	inc	1, xiy
SystemInit_StepHandler_0_Loop6:
	ldfr_berp a, 60
	ld a, c
	scf
	xorcf	a, (xiy)
	ldto_berp a, 60
	jrl	nc, SystemInit_StepHandler_0_Skip23
	inc	1, c
	cp	c, 8
	jrl	c, SystemInit_StepHandler_0_Loop6
	ld	l, 255:opc
	popw	bc
	pop	xiy
	jp	SysInit_BytecodeBlock_0x485
SystemInit_StepHandler_0_Skip22:
	ld	l, c
	jp	SysInit_BytecodeBlock_0x470
SystemInit_StepHandler_0_Skip23:
	ld	l, c
	add	l, 8
	jp	SysInit_BytecodeBlock_0x470
	ret
SystemInit_StepHandler_0_Helper2:
	ld	a, (3822:16)
	call	SysInit_BytecodeBlock_0x499
	ordi8	(0x8d88), 1
	ordi8	(0x266a), 1
	ret
	pushw	bc
	ld	(4353:16), xiy
	ld	(3822:16), a
	ld	c, w
	call	VoiceSlot_ComputeWordIndex
	ld	xix, 0xf1f8
	xor	b, b
	ld_rrw iy, xix, iz
	cp iy, 65535
	jrl	z, ScoopParam_ValueTable_Helper10_Skip3
	ld	(0x28ba:16), iy
	srl	xiz, 1
	ldfr_lerp xix, 56
	lda_rr xix, xix, iz
	ld a, (xix+32)
	ldto_lerp xix, 56
	xor	w, w
	sla	iz, 1
	ld	(0x28bc:16), wa
	ld	xix, 3230
	ld_rrw de, xix, iz
	cp de, 65535
	jrl	nz, ScoopParam_ValueTable_Helper10_Skip
	st_rrw iy, xix, iz
	srl	iz, 1
	ldfr_lerp xix, 56
	lda_rr xix, xix, iz
	ld (xix+32), 5
	ldto_lerp	xix, 56
	sla	iz, 1
	jp	SysInit_BytecodeBlock_0x4DE
ScoopParam_ValueTable_Helper10_Skip:
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, iz
	ld	iy, (xix+32)
	ldto_lerp	xix, 56
	sla	iz, 1
	and	iy, 255
	ld	(0x28b8:16), iy
	ld	xix, 0xf1f8
	srl	iz, 1
	ldfr_lerp xix, 56
	lda_rr xix, xix, iz
	ld a, (xix+32)
	ldto_lerp xix, 56
	xor	w, w
	sla	iz, 1
	add	wa, bc
	cp	wa, 255
	jrl	ugt, ScoopParam_ValueTable_Helper10_Skip2
	ld_rrw iy, xix, iz
	ld (10399:16), iy
	ld	(0x28b6:16), wa
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, iz
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
	jp	SysInit_BytecodeBlock_0x691
ScoopParam_ValueTable_Helper10_Skip2:
	sub	wa, 251
	ld	(0x28b6:16), wa
	pushw	de
	call	DispatchHandler_JumpToSubHandler
	popw	de
	cp	w, 255
	jrl	z, SystemInit_StepHandler_0_Loop7
	ld	iy, ix
	ld	xix, 0xf1f8
	srl	iz, 1
	ld	wa, (0x28b6:16)
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, iz
	ld	(xix+32), a
	ldto_lerp	xix, 56
	sla	iz, 1
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ldw (xhl+3), 65535
	ld	(0x289f:16), iy
	ld	wa, iy
	pushw	de
	ld	xix, 0xf1f8
	ld_rrw	de, xix, iz
	ld	(xhl+1), de
	st_rrw	wa, xix, iz
	ld	iy, de
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
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
	jp	SysInit_BytecodeBlock_0x691
SystemInit_StepHandler_0_Loop7:
	ld	w, 104:opc
	call	MIDI_SendSysExFromW
	anddi8	(0xe3e2), 111
	stdi8	(0x7f42), 15
	xor	wa, wa
	ld	a, 238:opc
	call	SoundCtrl_SendCommand
	popw	bc
	jp	SysInit_BytecodeBlock_0x691
ScoopParam_ValueTable_Helper10_Skip3:
	push	xix
	call	DispatchHandler_JumpToSubHandler
	ld	iy, ix
	pop	xix
	cp	w, 255
	jrl	z, SystemInit_StepHandler_0_Loop7
	st_rrw iy, xix, iz
	srl	iz, 1
	ldfr_lerp xix, 56
	lda_rr xix, xix, iz
	ld (xix+32), 5
	ldto_lerp	xix, 56
	sla	iz, 1
	pushw	wa
	push	xiz
	push	xix
	push	xiy
	ld	a, (3822:16)
	dec	1, a
	ld	w, a
	sla	a, 1
	add	a, w
	xor	w, w
	ld	iz, wa
	ld	xix, 0xf250
	or_srib_im 0x07, 0xf0, 0xf8, 0x80	; or (XIX+IZ),0x80
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, iz
	ld	(xix+1), iy
	ldto_lerp	xix, 56
	pop	xiy
	pop	xix
	pop	xiz
	popw	wa
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ldw	(xhl+1), 0
	ldw (xhl+3), 65535
	jp	SysInit_BytecodeBlock_0x4AF
	ret

VoiceSlot_InitAndProcess:
	cp bc, 0:i3
	jrl nz, VoiceSlot_InitLoop
	jp VoiceSlot_RetNZ

VoiceSlot_InitLoop:
	ld xix, 0xc9e
	srl iz, 1
	ldfr_lerp XIX, 0x38
	lda_dri XIX, 0x07, 0xf0, 0xf8
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
	lda_dri XIX, 0x07, 0xf0, 0xf8
	ld (xix + 32), c
	ldto_lerp XIX, 0x38
	sla iz, 1
	pushw iy
	ldw_sri IY, 0x07, 0xf0, 0xf8
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
	ldw_sri IY, 0x07, 0xf0, 0xf8
	srl iz, 1
	lda_dri XIX, 0x07, 0xf0, 0xf8
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
	lda_dri XIX, 0x07, 0xf0, 0xf8
	ld (xix + 32), c
	ldto_lerp XIX, 0x38
	sla iz, 1
	sub c, 0x5
	ldw_sri IY, 0x07, 0xf0, 0xf8
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	ld iy, (xhl + 3)
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	stw_dri IY, 0x07, 0xf0, 0xf8
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
	ld_rrw iy, xix, iz
	ld (10399:16), iy
	srl	iz, 1
	ldfr_lerp xix, 56
	lda_rr xix, xix, iz
	ld a, (xix+32)
	ldto_lerp xix, 56
	xor	w, w
	sla	iz, 1
	ld	(0x28b6:16), wa
	xor	b, b
	add	wa, bc
	cp	wa, 255
	jrl	ugt, VoiceSlot_RetZ_Skip
	ld	(0x28ba:16), iy
	ld	(0x28bc:16), wa
	jp	VoiceSlot_RetZ_0x58
VoiceSlot_RetZ_Skip:
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	iy, (xhl+3)
	sub	wa, 251
	jp	VoiceSlot_RetZ_0x39
	ld	xix, 0xf1f8
	ld_rrw	de, xix, iz
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, iz
	ld	a, (xix+32)
	ldto_lerp	xix, 56
	xor	w, w
	sla	iz, 1
	stda16	(0x28b8), wa
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
	lda_rr	xix, xix, iz
	ld	(xix+32), a
	ldto_lerp	xix, 56
	sla	iz, 1
	jp	VoiceSlot_RetZ_0xF8
VoiceSlot_RetZ_Skip2:
	cp	wa, 0xffff
	jrl	le, VoiceSlot_RetZ_Skip3
	add	a, 251
	jp	VoiceSlot_RetZ_0xBF
VoiceSlot_RetZ_Skip3:
	sub	wa, 5
	ld	iy, de
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	de, (xhl+1)
	st_rrw de, xix, iz
	ld	iy, de
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, iz
	ld	(xix+32), a
	ldto_lerp	xix, 56
	sla	iz, 1
	ld	iy, (xhl+3)
	ld	wa, 1:i3
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
	ldw_sri IY, 0x07, 0xf0, 0xf8
	pop xix
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	srl iz, 1
	push xde
	ld xde, 0xcbe
	ldw_sri IX, 0x07, 0xe8, 0xf8
	pop xde
	and ix, 0xff
	sla iz, 1
	cp b, 0:i3
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
	stb_dri A, 0x07, 0xe8, 0xf8
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
	ldw_sri IY, 0x07, 0xe8, 0xf8
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
	stb_dri A, 0x07, 0xe8, 0xf8
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
	ldw_sri IY, 0x07, 0xe8, 0xf8
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
	ldw_sri IY, 0x07, 0xe8, 0xf8
	pop xde
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
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
	ldw_sri IY, 0x07, 0xe8, 0xf8
	pop xde
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	srl iz, 1
	push xde
	ld xde, 0xcbe
	ldw_sri IY, 0x07, 0xe8, 0xf8
	pop xde
	sla iz, 1
	and iy, 0xff
	add iy, (3573:16)
	cp iy, 0xff
	jrl ugt, VoiceSlot_FinalCheck
	ldb_sri A, 0x07, 0xec, 0xf4
	jp VoiceSlot_FinalRetNZ

VoiceSlot_FinalCheck:
	ld iy, (xhl + 3)
	cp iy, 0xffff
	jrl z, VoiceSlot_FinalDone
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (4349:16)
	ld iy, 5:i3
	ldb_sri A, 0x07, 0xec, 0xf4
	jp VoiceSlot_FinalRetNZ

VoiceSlot_FinalDone:
	ld w, 0xff:opc

VoiceSlot_FinalRetNZ:
	ret

VoiceSlot_FinalRetZ:
	call	VoiceSlot_ReadCurrentParams
	pushw	wa
	ld	de, 1:i3
	call	VoiceSlot_FinalRetZ_0xB8
	ld	d, w
	popw	wa
	ld	w, d
	ret
	ld	a, e
	push	xiy
	push	xiz
	push	xhl
	call	VoiceSlot_FlagCheck
	pop	xhl
	pop	xiz
	pop	xiy
	ret
	push	xhl
	pushw	de
	dec	1, e
	sla	e, 1
	xor	d, d
	ld	iz, de
	extz	xiz
	push	xix
	ld	xix, 3230
	ld_rrw iy, xix, iz
	pop xix
	call	VoiceSlot_UpdateCurrentPointer
	srl	iz, 1
	push	xix
	ld	xix, 3262
	ld_rrw iy, xix, iz
	pop xix
	and	iy, 255
	sla	iz, 1
	ld	xhl, (4349:16)
	ld_rrb a, xhl, iy
	popw de
	pop	xhl
	ret
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
	call	VoiceSlot_FinalRetZ_0xB8
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ldb_d8	a, (0x0dc4)
	ret
	call	VoiceSlot_ComputeWordIndex
	push	xde
	ld	xde, 3230
	ld_rrw iy, xde, iz
	pop xde
	call	VoiceSlot_UpdateCurrentPointer
	srl	iz, 1
	push	xde
	ld	xde, 3262
	ld_rrw iy, xde, iz
	pop xde
	sla	iz, 1
	and	iy, 255
	ld	xhl, (4349:16)
	st_rrb w, xhl, iy
	ret
	ld a, (3822:16)
	dec 1, a
	ld (3566:16), a
	ld l, a
	xor h, h
	sla	a, 1
	ld	c, a
	xor	b, b
	ld	iz, bc
	ld	xix, 3230
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, hl
	add	e, (xix+32)
	ldto_lerp	xix, 56
	adc	d, 0
	cp	de, 255
	jrl	ugt, VoiceSlot_FinalRetZ_Skip2
	ld_rrw bc, xix, iz
	ld xix, 61944
	.byte	0xd3, 0x07, 0xf0, 0xf8, 0xf1	; cp BC,(XIX+IZ)
	jrl	z, VoiceSlot_FinalRetZ_Skip
VoiceSlot_FinalRetZ_Loop:
	push	xwa
	ld	xwa, 3262
	st_rrb e, xwa, hl
	pop xwa
	ld w, 0:opc
	ret
VoiceSlot_FinalRetZ_Skip:
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, hl
	cp	e, (xix+32)
	ldto_lerp	xix, 56
	jrl	ule, VoiceSlot_FinalRetZ_Loop
	ld	w, 255:opc
	jp	VoiceSlot_FinalRetZ_0x1A5
VoiceSlot_FinalRetZ_Skip2:
	sub	de, 256
	ld	wa, de
	xor	de, de
	ldw	bc, 251
	ld	qwa, de
	div	xwa, bc
	ld de, qwa
	inc 1, wa
	ld	bc, wa
	ld_rrw	iy, xix, iz
	call	VoiceSlot_UpdateCurrentPointer
	ldda32	xhl, (0x10fd)
	ld	iy, (xhl+3)
	ldb_d8	l, (0x0dee)
	xor	h, h
	cp	iy, 0xffff
	jrl	z, VoiceSlot_FinalRetZ_Skip3
VoiceSlot_FinalRetZ_Loop2:
	djnz16	bc, -27
	add	de, 5
	ld	xix, 0xf1f8
	.byte	0xd3, 0x07, 0xf0, 0xf8, 0xf5	; cp IY,(XIX+IZ)
	jrl	z, VoiceSlot_FinalRetZ_Skip4
VoiceSlot_FinalRetZ_Loop3:
	ld	xix, 3230
	st_rrw iy, xix, iz
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, iz
	ld	(xix+32), e
	ldto_lerp	xix, 56
	sla	iz, 1
	xor	w, w
	jp	VoiceSlot_FinalRetZ_0x1A5
VoiceSlot_FinalRetZ_Skip3:
	cp	bc, 1:i3
	jrl	z, VoiceSlot_FinalRetZ_Loop2
	ld	w, 255:opc
	jp	VoiceSlot_FinalRetZ_0x1A5
VoiceSlot_FinalRetZ_Skip4:
	cpw_sri_rm WA, 0x07, 0xf0, 0xec	; cp WA,(XIX+HL)
	jrl	ule, VoiceSlot_FinalRetZ_Loop3
	ld	w, 255:opc
	ret
	ld	xhl, 4362
	ld	xwa, (7514:16)
	ld	(xhl), xwa
	ret
	ld	xhl, 4362
	push	xde
	ld	xde, (7514:16)
	ld	(xhl), xde
	pop	xde
	ld	(3302:16), wa
	ld	bc, (0xf22f:16)
	ld	(0xf22f:16), iy
	xor	wa, wa
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	ix, (xhl+1)
	ld	de, ix
	cp	ix, 0:i3
	jrl	z, VoiceSlot_FinalRetZ_Skip7
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
	cp	iy, 0xffff
	jrl	z, VoiceSlot_FinalRetZ_Skip5
VoiceSlot_FinalRetZ_Entry:
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
VoiceSlot_FinalRetZ_Skip5:
	cp	de, 0:i3
	jrl	z, VoiceSlot_FinalRetZ_Skip6
	push	xiy
	ld	iy, de
	call	VoiceSlot_UpdateCurrentPointer
	pop	xiy
	ld	xhl, (4349:16)
	ld	(xhl+3), iy
VoiceSlot_FinalRetZ_Skip6:
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
	jp	VoiceSlot_FinalRetZ_0x286
VoiceSlot_FinalRetZ_Skip7:
	call	VoiceSlot_UpdateCurrentPointer
	ld	ix, iy
	ld	xhl, (4349:16)
	ld	iy, (xhl+3)
	cp	iy, 0xffff
	jrl	nz, VoiceSlot_FinalRetZ_Entry
	ldw	(3302:16), 0
	ld	iy, ix
	andmi8	(xhl), 127
	jp	VoiceSlot_FinalRetZ_Join
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
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceSlot_IndexDone_Skip
	ld	de, 1:i3
	call	VoiceSlot_FinalRetZ_0xB8
	incw	1, (3426:16)
	jp	VoiceSlot_IndexDone_0xA
VoiceSlot_IndexDone_Skip:
	ld	xiy, 3426
	ld	xix, 0x3728
	cp	a, 130
	jrl	z, VoiceSlot_IndexDone_Skip5
	cp	a, 132
	jrl	z, VoiceSlot_IndexDone_Skip7
	call	VoiceSlot_FlagCheck
	ld	xiy, 3428
	cp	a, 0:i3
	jrl	z, VoiceSlot_IndexDone_Skip2
	ld	(xiy), 128
VoiceSlot_IndexDone_Skip2:
	cpdi8	(0x0d57), 48
	jrl	nz, VoiceSlot_IndexDone_0x72
	cp	(xiy), 128
	jrl	nz, VoiceSlot_IndexDone_Skip3
	ld	(xiy), 0
	jp	VoiceSlot_IndexDone_0x72
VoiceSlot_IndexDone_Skip3:
	ld	(xiy), 128
	ld	wa, (3426:16)
	sub	wa, 1
	jrl	nc, VoiceSlot_IndexDone_Skip4
	xor	wa, wa
VoiceSlot_IndexDone_Skip4:
	ld	(3426:16), wa
VoiceSlot_IndexDone_Loop:
	call	Display_BytecodeBlock_F_0x344
	jp	VoiceSlot_IndexDone_0xA3
VoiceSlot_IndexDone_Skip5:
	cpw	(xiy), 1
	jrl	z, VoiceSlot_IndexDone_Skip6
	cpw	(xiy), 0
	jrl	z, VoiceSlot_IndexDone_Skip6
	decm	1, (xiy)
	jp	VoiceSlot_IndexDone_0x72
VoiceSlot_IndexDone_Skip6:
	ld	(xix), 8
	jp	VoiceSlot_IndexDone_0x9F
VoiceSlot_IndexDone_Skip7:
	cpw	(xiy), 0
	jrl	nz, VoiceSlot_IndexDone_Loop
	ld	(xix), 9
	call	DisplayStr_BytecodeBlock_E_0x1
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
	cpdi8	(0x0d65), 0
	jrl	nz, VoiceSlot_StatusRet_Skip2
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceSlot_StatusRet_Skip
	call	VoiceSlot_FlagCheck
	cp	a, (0x0d57:16)
	jrl	z, VoiceSlot_StatusRet_Skip2
VoiceSlot_StatusRet_Skip:
	call	VoiceSlot_IndexDone
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip2:
	call	VoiceSlot_ReadCurrentParams
	ld	w, a
	and	w, 6
	ld	(3828:16), w
	ld	w, a
	and	w, 7
	ld	(3528:16), w
	and	a, 240
	cp	a, 144
	jrl	z, VoiceSlot_StatusRet_Skip4
	cp	a, 176
	jrl	z, VoiceSlot_StatusRet_Skip14
	cp	a, 192
	jrl	z, VoiceSlot_StatusRet_Skip9
	cp	a, 128
	jrl	z, VoiceSlot_StatusRet_Skip30
	cp	a, 208
	jrl	nz, VoiceSlot_StatusRet_Loop
	jp	VoiceSlot_StatusRet_0x7D4
VoiceSlot_StatusRet_Loop:
	ld	(0x3720:16), 0
	cpdi8	(0x0def), 1
	jrl	nz, VoiceSlot_StatusRet_Skip3
	call	DisplayStr_BytecodeBlock_B_0x4
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip3:
	ld	(3567:16), 1
	call	DisplayStr_BytecodeBlock_B
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip4:
	cpdi8	(0x0d65), 0
	jrl	z, VoiceSlot_StatusRet_Skip8
	call	VoiceSlot_FinalRetZ
	call	VoiceSlot_StatusRet_0x8A1
	pushw	wa
	call	VoiceSlot_ComputeWordIndex
	srl	iz, 1
	popw	wa
	push	xix
	ld	xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf8, 0x0c	; cp (XIX+IZ),0x0c
	pop	xix
	jrl	nz, VoiceSlot_StatusRet_Skip6
	bitda	2, (0xfdad)
	jrl	z, VoiceSlot_StatusRet_Skip5
	jp	VoiceSlot_StatusRet_0xBE
VoiceSlot_StatusRet_Skip5:
	ld	w, (0xfb3c:16)
	call	ScoopDisp_BytecodeBlock1_0x32
VoiceSlot_StatusRet_Skip6:
	ld	(0x3718:16), a
	call	VoiceSlot_FinalRetZ
	ld	(0x3717:16), a
	cpdi8	(0x0def), 0
	jrl	nz, VoiceSlot_StatusRet_Skip7
	call	Display_BytecodeBlock_F_0x4
	jp	VoiceSlot_StatusRet_0xE3
VoiceSlot_StatusRet_Skip7:
	ld	(3567:16), 0
	call	Display_BytecodeBlock_F
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip8:
	call	Timer_ModeHandler_0_0x53
	call	VoiceSlot_FinalRetZ
	call	VoiceSlot_StatusRet_0x8A1
	call	VoiceSlot_StatusRet_0x8A1
	and	a, 32
	rlc_i_8 a, 3	; rlc 0x03,A  (llvm-mc: rlc	a does not round-trip)
	ld	e, a
	call	VoiceSlot_ReadCurrentParams
	and	a, 7
	sla	a, 1
	or	a, e
	ld	xhl, VoiceSlot_StatusRet_Tbl2
	ld_rr8b	a, xhl, a
	stb_d8	(0x0d61), a
	call	SNS_Init_Startup
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip9:
	call	VoiceSlot_FinalRetZ
	call	VoiceSlot_StatusRet_0x8A1
	cp	a, 72
	jrl	z, VoiceSlot_StatusRet_Skip11
	ld	(4539:16), a
	ld	(0x90f7:16), a
	call	VoiceSlot_FinalRetZ
	ld	h, a
	push	xhl
	call	VoiceSlot_FinalRetZ
	bitda	0, (0x0dc8)
	jrl	z, VoiceSlot_StatusRet_Skip10
	or	a, 128
VoiceSlot_StatusRet_Skip10:
	pop	xhl
	ld	(4541:16), a
	ld	l, a
	call	VoiceSlot_FinalRetZ
	ld	(4540:16), a
	ld	h, a
	call	PartCtrl_WriteProgramChange
	ld	(4542:16), h
	ld	(3567:16), 1
	call	Display_BytecodeBlock_F_0x154
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip11:
	call	VoiceSlot_FinalRetZ
	cp	a, 0:i3
	jrl	nz, VoiceSlot_StatusRet_Loop
	call	VoiceSlot_FinalRetZ
	bitda	0, (0x0dc8)
	jrl	z, VoiceSlot_StatusRet_Skip12
	or	a, 128
VoiceSlot_StatusRet_Skip12:
	ld	(0x3722:16), a
	call	VoiceSlot_FinalRetZ
	ld	(0x3723:16), a
	bitda	1, (0x0ef4)
	jrl	z, VoiceSlot_StatusRet_Skip13
	or	a, 128
VoiceSlot_StatusRet_Skip13:
	ld	(3829:16), a
	cpdi8	(0x0d65), 3
	jrl	z, VoiceSlot_StatusRet_Code_Skip
	ld	(3567:16), 4
	call	DisplayStr_BytecodeBlock_B_0x8C
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip:
	ld	(3567:16), 12
	call	DisplayStr_BytecodeBlock_D
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Loop:
	jp	VoiceSlot_StatusRet_0x60
VoiceSlot_StatusRet_Skip14:
	call	VoiceSlot_FinalRetZ
	call	VoiceSlot_StatusRet_0x8A1
	and	a, 127
	ld	h, (3528:16)
	and	h, 4
	sla	h, 5
	or	a, h
	ld	(4337:16), a
	cp	a, 72
	jrl	nz, VoiceSlot_StatusRet_Code_Skip13
	call	VoiceSlot_FinalRetZ
	cp	a, 5:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip10
	cp	a, 6:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip10
	cp	a, 7:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip2
	cp	a, 3:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip5
	cp	a, 4:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip9
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Code_Skip2:
	call	VoiceSlot_FinalRetZ
	ld	c, a
	pushw	bc
	call	VoiceSlot_FinalRetZ
	popw	bc
	ld	a, (3429:16)
	cp	a, 3:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip3
	cp	a, 2:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip4
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Code_Skip3:
	ld	(3567:16), 15
	pushw	bc
	call	Display_UpdateRegion0
	popw	bc
	call	DisplayStr_RhythmLabel_0x4C
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip4:
	ld	(3567:16), 4
	pushw	bc
	call	Display_UpdateRegion0
	popw	bc
	call	DisplayStr_RhythmLabel_0xA
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip5:
	call	VoiceSlot_FinalRetZ
	ld	(4339:16), a
	call	VoiceSlot_FinalRetZ
	ld	l, (3528:16)
	ld	h, l
	and	l, 1
	rrc	l
	ld	w, (4339:16)
	or	w, l
	ld	(4339:16), w
	and	h, 2
	rrc_i_8 h, 2	; rrc 0x02,H
	or	a, h
	ld	(4341:16), a
	ldfr_berp a, 60
	and a, 7
	ldto_berp a, 60
	jrl	z, VoiceSlot_StatusRet_Code_Skip6
	call	ParamPopup_ApcMode
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip6:
	bit	3, a
	jrl	z, VoiceSlot_StatusRet_Code_Skip7
	call	ParamPopup_ApcMemory
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip7:
	ldfr_berp a, 60
	and a, 224
	ldto_berp a, 60
	jrl	z, VoiceSlot_StatusRet_Code_Skip8
	call	ParamPopup_AccompPart
VoiceSlot_StatusRet_Code_Skip8:
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip9:
	call	VoiceSlot_FinalRetZ
	ld	(4339:16), a
	call	VoiceSlot_FinalRetZ
	ld	l, (3528:16)
	ld	h, l
	and	l, 1
	rrc	l
	ld	w, (4339:16)
	or	w, l
	ld	(4339:16), w
	and	h, 2
	rrc_i_8 h, 2	; rrc 0x02,H
	or	a, h
	ld	(4341:16), a
	bit	4, a
	jrl	z, VoiceSlot_StatusRet_Skip15
	call	ParamPopup_DynamicAccomp
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip15:
	bit	6, a
	jrl	z, VoiceSlot_StatusRet_Skip16
	call	ParamPopup_TechniChord
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip16:
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Code_Skip10:
	ldfr_berp a, 56
	ld	(4338:16), a
	call	VoiceSlot_FinalRetZ
	ld	c, a
	bitda	0, (0x0dc8)
	jrl	z, VoiceSlot_StatusRet_Skip17
	or	c, 128
VoiceSlot_StatusRet_Skip17:
	pushw	bc
	call	VoiceSlot_FinalRetZ
	popw	bc
	bitda	1, (0x0dc8)
	jrl	z, VoiceSlot_StatusRet_Skip18
	or	a, 128
VoiceSlot_StatusRet_Skip18:
	ld	xiy, 0x3728
	ldfr_berp a, 60
	and a, 192
	ldto_berp a, 60
	jrl	nz, VoiceSlot_StatusRet_Skip19
	ldfr_berp a, 60
	and a, 48
	ldto_berp a, 60
	jrl	nz, VoiceSlot_StatusRet_Skip21
	bit	2, a
	jrl	nz, VoiceSlot_StatusRet_Code_Skip11
	bit	3, a
	jrl	nz, VoiceSlot_StatusRet_Code_Skip12
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Skip19:
	ldfr_berp c, 60
	and c, 192
	ldto_berp c, 60
	jrl	z, VoiceSlot_StatusRet_Loop2
	bit	6, c
	jrl	z, VoiceSlot_StatusRet_Skip20
	ld	(xiy), 3
	jp	VoiceSlot_StatusRet_0x371
VoiceSlot_StatusRet_Skip20:
	ld	(xiy), 4
	call	VoiceSlot_StatusRet_0x8AA
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Loop2:
	setda	5, (0x0d54)
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip21:
	ldfr_berp	c, 60
	and	c, 48
	ldto_berp	c, 60
	jrl	z, VoiceSlot_StatusRet_Loop2
	ld	(xiy), 7
	bit	4, c
	jrl	nz, VoiceSlot_StatusRet_Skip22
	ld	(xiy), 11
VoiceSlot_StatusRet_Skip22:
	call	VoiceSlot_StatusRet_0x8AA
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip11:
	ld	(xiy), 5
	cpdi8	(0x10f2), 6
	jrl	nz, VoiceSlot_StatusRet_Skip23
	ld	(xiy), 12
VoiceSlot_StatusRet_Skip23:
	call	VoiceSlot_StatusRet_0x8AA
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip12:
	ld	(xiy), 6
	call	VoiceSlot_StatusRet_0x8AA
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip13:
	call	VoiceSlot_FinalRetZ
	ld	(4338:16), a
	call	VoiceSlot_FinalRetZ
	ld	l, (3528:16)
	ld	h, l
	and	l, 1
	rrc	l
	or	a, l
	ld	(4339:16), a
	push	xhl
	call	VoiceSlot_FinalRetZ
	pop	xhl
	and	h, 2
	rrc_i_8 h, 2	; rrc 0x02,H
	or	a, h
	ld	(4341:16), a
	ld	a, (4337:16)
	cp	a, 0:i3
	jrl	c, VoiceSlot_StatusRet_Code_Skip14
	cp	a, 13
	jrl	ule, VoiceSlot_StatusRet_Code_Skip21
	cp	a, 14
	jrl	z, VoiceSlot_StatusRet_Code_Skip21
	cp	a, 15
	jrl	z, VoiceSlot_StatusRet_Code_Skip21
	cp	a, 80
	jrl	z, VoiceSlot_StatusRet_Code_Skip21
	cp	a, 81
	jrl	z, VoiceSlot_StatusRet_Code_Skip21
	cp	a, 144
	jrl	z, VoiceSlot_StatusRet_Code_Skip21
	cp	a, 112
	jrl	z, VoiceSlot_StatusRet_Code_Skip15
	cp	a, 152
	jrl	z, VoiceSlot_StatusRet_Code_Skip15
	cp	a, 19
	jrl	z, VoiceSlot_StatusRet_Code_Skip15
	cp	a, 20
	jrl	z, VoiceSlot_StatusRet_Code_Skip15
	cp	a, 16
	jrl	z, VoiceSlot_StatusRet_Code_Skip15
	cp	a, 17
	jrl	z, VoiceSlot_StatusRet_Code_Skip15
	cp	a, 18
	jrl	z, VoiceSlot_StatusRet_Code_Skip15
VoiceSlot_StatusRet_Code_Skip14:
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Code_Skip15:
	ld	a, (4338:16)
	cp	a, 0:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip16
	cp	a, 3:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip16
	cp	a, 3:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip16
	cp	a, 3:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip16
	cp	a, 2:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip16
	cp	a, 1:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip16
	cp	a, 11
	jrl	z, VoiceSlot_StatusRet_Code_Skip16
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Code_Skip16:
	ld	a, (4339:16)
	cpdi8	(0x10f1), 112
	jrl	nz, VoiceSlot_StatusRet_Skip25
	ld	l, (4338:16)
	cp	l, 0:i3
	jrl	z, VoiceSlot_StatusRet_Code_Entry
	cp	l, 3:i3
	jrl	z, VoiceSlot_StatusRet_Skip29
	cp	l, 2:i3
	jrl	z, VoiceSlot_StatusRet_Skip24
	jp	VoiceSlot_StatusRet_0x1C5
	call	StringData_APCModeNames_0x3F8
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip24:
	call	ParamPopup_KeyNameBracketed
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Entry:
	bitda	2, (0x10f5)
	jrl	z, VoiceSlot_StatusRet_Code_Loop
	call	StringData_APCModeNames_0x463
	jp	VoiceSlot_StatusRet_0x8A0
	bitda	7, (0x10f5)
	jrl	z, VoiceSlot_StatusRet_Code_Loop
	call	ParamPopup_TotalReverb
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip25:
	cpdi8	(0x10f1), 152
	jrl	nz, VoiceSlot_StatusRet_Skip28
	ld	l, (4338:16)
	cp	l, 11
	jrl	z, VoiceSlot_StatusRet_Skip27
	cp	l, 1:i3
	jrl	z, VoiceSlot_StatusRet_Skip26
	cp	l, 3:i3
	jrl	nz, VoiceSlot_StatusRet_Code_Skip20
	ldfr_berp a, 60
	ld	a, (4341:16)
	and	a, 1
	ldto_berp a, 60
	jrl	z, VoiceSlot_StatusRet_Code_Skip20
	call	ParamPopup_Msa
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip26:
	and	a, 127
	call	ParamPopup_PanelMemory
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip27:
	ld	a, (3528:16)
	and	a, 2
	cp	a, 0:i3
	jr	nz, VoiceSlot_StatusRet_Code_Skip17
	ld	a, (4341:16)
	and	a, 64
	cp	a, 0:i3
	jr	nz, VoiceSlot_StatusRet_Code_Skip18
VoiceSlot_StatusRet_Code_Skip17:
	ld	a, (3528:16)
	and	a, 1
	call	ParamPopup_FadeIn
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip18:
	ld	a, (4339:16)
	and	a, 64
	cp	a, 0:i3
	jr	z, VoiceSlot_StatusRet_Code_Skip19
	ld	a, 1:opc
VoiceSlot_StatusRet_Code_Skip19:
	call	ParamPopup_FadeOut
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip28:
	cpdi8	(0x10f1), 19
	jrl	nz, VoiceSlot_StatusRet_Code_Entry2
	cpdi8	(0x10f2), 3
	jrl	nz, VoiceSlot_StatusRet_Code_Skip20
	ld	hl, 1:i3
	jp	VoiceSlot_StatusRet_0x5B7
VoiceSlot_StatusRet_Code_Entry2:
	cpdi8	(0x10f1), 20
	jrl	nz, VoiceSlot_StatusRet_Code_Entry3
	cpdi8	(0x10f2), 3
	jrl	nz, VoiceSlot_StatusRet_Code_Skip20
	ld	hl, 2:i3
	jp	VoiceSlot_StatusRet_0x5B7
VoiceSlot_StatusRet_Code_Entry3:
	cpdi8	(0x10f1), 16
	jrl	nz, VoiceSlot_StatusRet_Code_Entry4
	cpdi8	(0x10f2), 3
	jrl	nz, VoiceSlot_StatusRet_Code_Skip20
	ld	hl, 3:i3
	jp	VoiceSlot_StatusRet_0x5B7
VoiceSlot_StatusRet_Code_Entry4:
	cpdi8	(0x10f1), 17
	jrl	nz, VoiceSlot_StatusRet_Code_Entry5
	cpdi8	(0x10f2), 3
	jrl	nz, VoiceSlot_StatusRet_Code_Skip20
	ld	hl, 4:i3
	jp	VoiceSlot_StatusRet_0x5B7
VoiceSlot_StatusRet_Code_Entry5:
	cpdi8	(0x10f1), 18
	jrl	nz, VoiceSlot_StatusRet_Code_Skip20
	cpdi8	(0x10f2), 3
	jrl	nz, VoiceSlot_StatusRet_Code_Skip20
	ld	hl, 5:i3
	jp	VoiceSlot_StatusRet_0x5B7
VoiceSlot_StatusRet_Code_Skip20:
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Skip29:
	xor	hl, hl
	call	ParamPopup_AccompVolume
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip21:
	ld	a, (4337:16)
	cp	a, 144
	jrl	z, VoiceSlot_StatusRet_Code_Skip39
	cp	a, 80
	jrl	z, VoiceSlot_StatusRet_Code_Skip35
	cp	a, 81
	jrl	z, VoiceSlot_StatusRet_Code_Skip35
	cp	a, 0:i3
	jrl	c, VoiceSlot_StatusRet_Code_Skip22
	cp	a, 13
	jrl	ule, VoiceSlot_StatusRet_Code_Skip23
	cp	a, 14
	jrl	z, VoiceSlot_StatusRet_Code_Skip23
	cp	a, 15
	jrl	z, VoiceSlot_StatusRet_Code_Skip23
VoiceSlot_StatusRet_Code_Skip22:
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Code_Skip23:
	ld	a, (4338:16)
	cp	a, 3:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip24
	cp	a, 4:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip25
	cp	a, 12
	jrl	z, VoiceSlot_StatusRet_Code_Skip30
	cp	a, 8
	jrl	z, VoiceSlot_StatusRet_Code_Skip31
	cp	a, 9
	jrl	z, VoiceSlot_StatusRet_Code_Skip32
	cp	a, 10
	jrl	z, VoiceSlot_StatusRet_Code_Skip33
	cp	a, 11
	jrl	z, VoiceSlot_StatusRet_Code_Skip34
	cp	a, 5:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip28
	cp	a, 7:i3
	jrl	z, VoiceSlot_StatusRet_Code_Skip29
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Code_Skip24:
	call	ParamPopup_PartVolume
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip25:
	ld	a, (4341:16)
	bit	3, a
	jrl	nz, VoiceSlot_StatusRet_Code_Skip26
	bit	6, a
	jrl	nz, VoiceSlot_StatusRet_Code_Skip27
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Code_Skip26:
	call	ParamPopup_PartSustain
	jp	VoiceSlot_StatusRet_0x8A0
	call	ParamPopup_PartDspEffectOff
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip27:
	call	ParamPopup_PartEffect
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip28:
	call	ParamPopup_PartDspEffectLevel
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip29:
	call	ParamPopup_PartReverb
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip30:
	ldfr_berp a, 60
	ld	a, (4341:16)
	and	a, 192
	ldto_berp a, 60
	jrl	z, VoiceSlot_StatusRet_Code_Loop
	call	ParamPopup_PartTimbre
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip31:
	call	ParamPopup_PartPanpot
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip32:
	call	ParamPopup_PartKeyShift
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip33:
	call	ParamPopup_PartTuning
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip34:
	call	ParamPopup_PartBendSense
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip35:
	jp	VoiceSlot_StatusRet_0x1C5
	jp	VoiceSlot_StatusRet_0x1C5
	jp	VoiceSlot_StatusRet_0x1C5
	call	VoiceSlot_StatusRet_0x62A
	jp	VoiceSlot_StatusRet_0x8A0
	ld	a, (4341:16)
	bit	3, a
	jrl	nz, VoiceSlot_StatusRet_Code_Skip36
	bit	4, a
	jrl	nz, VoiceSlot_StatusRet_Code_Skip37
	bit	7, a
	jrl	nz, VoiceSlot_StatusRet_Code_Skip38
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Code_Skip36:
	call	ParamPopup_PartSustain
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip37:
	call	StringData_APCModeNames_0x394
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip38:
	call	ParamPopup_PartTremolo
	jp	VoiceSlot_StatusRet_0x8A0
	call	StringData_APCModeNames_0x3F9
	jp	VoiceSlot_StatusRet_0x8A0
	call	StringData_APCModeNames_0x3FA
	jp	VoiceSlot_StatusRet_0x8A0
	call	StringData_APCModeNames_0x413
	jp	VoiceSlot_StatusRet_0x8A0
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Code_Skip39:
	ld	a, (4338:16)
	jp	VoiceSlot_StatusRet_0x1C5
	ld	a, (4339:16)
	bit	0, a
	jrl	nz, VoiceSlot_StatusRet_Code_Loop
	bit	1, a
	jrl	nz, VoiceSlot_StatusRet_Code_Loop
	bit	2, a
	jrl	nz, VoiceSlot_StatusRet_Code_Loop
	bit	4, a
	jrl	nz, VoiceSlot_StatusRet_Code_Loop
	jp	VoiceSlot_StatusRet_0x1C5
VoiceSlot_StatusRet_Skip30:
	call	VoiceSlot_FinalRetZ
	ld	xiy, 0x3728
	cp	a, 128
	jrl	z, VoiceSlot_StatusRet_Code_Skip41
	cp	a, 133
	jrl	z, VoiceSlot_StatusRet_Code_Skip43
	cp	a, 134
	jrl	z, VoiceSlot_StatusRet_Code_Skip44
	cp	a, 129
	jrl	z, VoiceSlot_StatusRet_Code_Entry6
	cp	a, 132
	jrl	z, VoiceSlot_StatusRet_Code_Skip40
	jp	VoiceSlot_StatusRet_0x60
VoiceSlot_StatusRet_Code_Skip40:
	ld	(xiy), 9
	call	DisplayStr_BytecodeBlock_E_0x1
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip41:
	call	VoiceSlot_StatusRet_0x8A1
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
	ld	(3826:16), wa
	cpdi8	(0x0d65), 3
	jrl	z, VoiceSlot_StatusRet_Code_Skip42
	ld	(3567:16), 7
	call	DisplayStr_BytecodeBlock_C_0x90
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip42:
	ld	(3567:16), 17
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_0x2DA
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip43:
	ld	(xiy), 1
	call	VoiceSlot_StatusRet_0x8AA
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Skip44:
	ld	(xiy), 2
	call	VoiceSlot_StatusRet_0x8AA
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Code_Entry6:
	cpdi8	(0x0d65), 0
	jrl	nz, VoiceSlot_StatusRet_Code_Skip45
	call	VoiceSlot_IndexDone
VoiceSlot_StatusRet_Code_Skip45:
	jp	VoiceSlot_StatusRet_0x8A0
	call	VoiceSlot_FinalRetZ
	cp	a, 208
	jrl	z, VoiceSlot_StatusRet_Skip31
	cp	a, 209
	jrl	z, VoiceSlot_StatusRet_Skip33
	cp	a, 210
	jrl	z, VoiceSlot_StatusRet_Skip35
	cp	a, 211
	jrl	z, VoiceSlot_StatusRet_Skip37
	jp	VoiceSlot_StatusRet_0x60
VoiceSlot_StatusRet_Skip31:
	call	VoiceSlot_StatusRet_0x8A1
	ld	(0x3721:16), a
	ld	(0x3720:16), 5
	cpdi8	(0x0def), 3
	jrl	nz, VoiceSlot_StatusRet_Skip32
	call	DisplayStr_BytecodeBlock_B_0x4
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip32:
	ld	(3567:16), 3
	call	DisplayStr_BytecodeBlock_B
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip33:
	call	VoiceSlot_StatusRet_0x8A1
	ld	(0x3721:16), a
	ld	(0x3720:16), 2
	cpdi8	(0x0def), 3
	jrl	nz, VoiceSlot_StatusRet_Skip34
	call	DisplayStr_BytecodeBlock_B_0x4
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip34:
	ld	(3567:16), 3
	call	DisplayStr_BytecodeBlock_B
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip35:
	call	VoiceSlot_StatusRet_0x8A1
	ld	(0x3721:16), a
	ld	(0x3720:16), 1
	call	VoiceSlot_FinalRetZ
	ld	(4370:16), a
	cpdi8	(0x0def), 3
	jrl	nz, VoiceSlot_StatusRet_Skip36
	call	DisplayStr_BytecodeBlock_B_0x4
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip36:
	ld	(3567:16), 3
	call	DisplayStr_BytecodeBlock_B
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip37:
	call	VoiceSlot_StatusRet_0x8A1
	ld	(0x3721:16), a
	ld	(0x3720:16), 3
	cpdi8	(0x0def), 3
	jrl	nz, VoiceSlot_StatusRet_Skip38
	call	DisplayStr_BytecodeBlock_B_0x4
	jp	VoiceSlot_StatusRet_0x8A0
VoiceSlot_StatusRet_Skip38:
	ld	(3567:16), 3
	call	DisplayStr_BytecodeBlock_B
	ret
	call	VoiceSlot_FinalRetZ
	call	VoiceSlot_FinalRetZ
	ret
	ld	a, (3429:16)
	ld	xhl, VoiceSlot_StatusRet_Tbl
	ld_rr8b	a, xhl, a
	stb_d8	(0x0def), a
	call	Display_UpdateRegion0
	ld	l, (3429:16)
	and	hl, 3
	sla	hl, 2
	extz	xhl
	push	xix
	ld	xix, VoiceSlot_StatusRet_DispatchTbl
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
	ret
VoiceState_SaveAndRestore:
	call	DisplayStr_TempoString_0x74
	call	DisplayStr_StyleSectionInit
	ret
	; Handler dispatch table, 16 B.  Read by VoiceSlot_StatusRet (0xEFC7B2): `ld xix, VoiceSlot_StatusRet_DispatchTbl`
	; indexed with stride 4 (`sla hl, 2`), index from `ld l, (3429:16)`
	; 4 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
VoiceSlot_StatusRet_DispatchTbl:
	.long	DisplayStr_BytecodeBlock_E_0x1
	.long	DisplayStr_BytecodeBlock_C
	.long	DisplayStr_BytecodeBlock_C
	.long	VoiceState_SaveAndRestore
	; Byte data, 4 B.  Read by VoiceSlot_StatusRet (0xEFC7B2): `ld xhl, VoiceSlot_StatusRet_Tbl`
	; indexed with stride 4 (`sla hl, 2`), index from `ld a, (3429:16)`
VoiceSlot_StatusRet_Tbl:
	.byte	0x00, 0x05, 0x05, 0x0f
	; Byte data, 12 B.  Read by VoiceSlot_StatusRet (0xEFC7B2): `ld xhl, VoiceSlot_StatusRet_Tbl2`
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
	ldw_sri WA, 0x07, 0xf4, 0xf8
	ld (xhl), wa
	srl iz, 1
	ldfr_lerp XIY, 0x38
	lda_dri XIY, 0x07, 0xf4, 0xf8
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
	stw_dri WA, 0x07, 0xf4, 0xf8
	srl iz, 1
	ld a, (xhl + 2)
	ldfr_lerp XIY, 0x38
	lda_dri XIY, 0x07, 0xf4, 0xf8
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
	ld_rrw wa, xiy, iz
	cp (xix), wa
	jrl	nz, VoiceState_DataBlock2_Code_Skip3
	srl	iz, 1
	ldfr_lerp xiy, 56
	lda_rr xiy, xiy, iz
	ld a, (xiy+32)
	ldto_lerp xiy, 56
	cp	(xix+2), a
	jrl	ule, VoiceState_DataBlock2_Code_Skip
	ld	w, 3:opc
	jp	VoiceState_DataBlock2_0x78
VoiceState_DataBlock2_Code_Skip:
	jrl	z, VoiceState_DataBlock2_Code_Skip2
	ld	w, 2:opc
	jp	VoiceState_DataBlock2_0x78
VoiceState_DataBlock2_Code_Skip2:
	ld	w, 1:opc
	jp	VoiceState_DataBlock2_0x78
VoiceState_DataBlock2_Code_Skip3:
	ld	iy, wa
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	wa, (xhl+1)
	cp	wa, 0:i3
	jrl	z, VoiceState_DataBlock2_Code_Skip4
	cp	wa, (xix)
	jrl	z, VoiceState_DataBlock2_Code_Skip5
	jp	VoiceState_DataBlock2_0x55
VoiceState_DataBlock2_Code_Skip4:
	ld	w, 3:opc
	jp	VoiceState_DataBlock2_0x78
VoiceState_DataBlock2_Code_Skip5:
	ld	w, 2:opc
	pop	xix
	pop	xiy
	pop	xiz
	pop	xhl
	ret
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
	jp	VoiceState_DataBlock2_0xAB
VoiceState_DataBlock2_Code_Skip6:
	jrl	z, VoiceState_DataBlock2_Code_Skip7
	ld	w, 2:opc
	jp	VoiceState_DataBlock2_0xAB
VoiceState_DataBlock2_Code_Skip7:
	ld	w, 1:opc
	pop	xhl
	ret
	pushw	wa
	push	xhl
	push	xix
	push	xiy
	ld	a, (3822:16)
	dec	1, a
	exts	wa
	sla	wa, 1
	ld	ix, wa
	push	xde
	ld	xde, 3230
	ld_rrw wa, xde, ix
	pop xde
	cp	wa, 0xffff
	jrl	z, VoiceState_DataBlock2_Skip2
	cp	wa, 0:i3
	jrl	z, VoiceState_DataBlock2_Skip2
	ld	iy, wa
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	cpw	(xhl+1), 0
	jrl	z, VoiceState_DataBlock2_Skip
VoiceState_DataBlock2_Loop:
	pop	xiy
	pop	xix
	pop	xhl
	popw	wa
	ld	w, 255:opc
	jp	VoiceState_DataBlock2_0x10B
VoiceState_DataBlock2_Skip:
	srl	ix, 1
	push	xde
	ld	xde, 3262
	cpib_sri 0x07, 0xe8, 0xf0, 0x05	; cp (XDE+IX),0x05
	pop	xde
	jrl	nz, VoiceState_DataBlock2_Loop
VoiceState_DataBlock2_Skip2:
	pop	xiy
	pop	xix
	pop	xhl
	popw	wa
	ld	w, 0:opc
	ret
	push	xhl
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, VoiceState_DataBlock2_Skip3
	ld	a, 7:opc
	call	VoiceSlot_SaveState
	xor	bc, bc
	ld	l, (3822:16)
	xor	h, h
	dec	1, hl
	sla	hl, 1
	push	xde
	ld	xde, 3230
	ld_rrw wa, xde, hl
	pop	xde
	cp	wa, 0xffff
	jrl	z, VoiceState_DataBlock2_Code_Skip8
	cp	wa, 0:i3
	jrl	z, VoiceState_DataBlock2_Code_Skip8
VoiceState_DataBlock2_Code_Entry:
	push	xhl
	pushw	bc
	pushw	de
	push	xiy
	push	xix
	push	xiz
	call	VoiceSlot_FinalRetZ
	pop	xiz
	pop	xix
	pop	xiy
	popw	de
	popw	bc
	pop	xhl
	inc	1, bc
	cp	c, 6:i3
	jrl	ugt, VoiceState_DataBlock2_Code_Skip8
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Code_Entry
	cp	a, 130
	jrl	z, VoiceState_DataBlock2_Code_Skip8
	cp	a, 132
	jrl	z, VoiceState_DataBlock2_Code_Skip8
	ld	w, 255:opc
	jp	VoiceState_DataBlock2_0x173
VoiceState_DataBlock2_Code_Skip8:
	ld	w, 0:opc
	pop	xhl
	pushw	wa
	ld	a, 7:opc
	call	VoiceSlot_RestoreState
	popw	wa
	jp	VoiceState_DataBlock2_0x183
VoiceState_DataBlock2_Skip3:
	ld	bc, 2:i3
	pop	xhl
	ret
VoiceState_DataBlock2_Helper:
	push	xhl
	ld	a, (3822:16)
	dec	1, a
	ld	w, 3:opc
	mul	wa, w
	ld	hl, wa
	ld	w, 255:opc
	push	xde
	ld	xde, 0xf250
	bit_dri 7, 0x07, 0xe8, 0xec	; bit 7,(XDE+HL)
	pop	xde
	jrl	z, ScoopParam_ValueTable_Helper11_Epilogue
	ld	w, 0:opc
ScoopParam_ValueTable_Helper11_Epilogue:
	pop	xhl
	ret
VoiceState_DataBlock2_Code_Loop:
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	cp	wa, 0xffff
	jrl	z, VoiceState_DataBlock2_Code_Return
	call	VoiceState_DataBlock2_0x1CB
	bit	7, a
	jrl	nz, VoiceState_DataBlock2_Code_Return
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	cp	wa, 0xffff
	jrl	nz, VoiceState_DataBlock2_Code_Loop
VoiceState_DataBlock2_Code_Return:
	ret
	push	xix
	call	TempoRingBuf_SaveReadPos
	call	TempoRingBuf_ReadAlternate
	ld	wa, hl
	pop	xix
	ret
	call	TempoRingBuf_CheckEmpty
	ld	wa, hl
	cp	wa, 0:i3
	jrl	z, VoiceState_DataBlock2_Code_Skip9
	ld	w, 0:opc
	jp	VoiceState_DataBlock2_0x1EB
VoiceState_DataBlock2_Code_Skip9:
	ld	w, 255:opc
	ret
	call	Rhythm_TransposeTrampBlock
	pushw	de
	ld	a, (0xfc5a:16)
	ld	d, (0xfc64:16)
	and	d, 15
	call	Rhythm_DispatchNote_Tramp
	popw	de
	bitda	7, (0x1108)
	jrl	nz, VoiceState_DataBlock2_Code_Return2
	mul	wa, e
VoiceState_DataBlock2_Code_Return2:
	ret
	cpdi8	(0x0d65), 3
	jrl	z, VoiceState_DataBlock2_Code_Skip10
VoiceState_DataBlock2_Code_Loop2:
	ld	w, 0:opc
	jp	VoiceState_DataBlock2_0x238
VoiceState_DataBlock2_Code_Skip10:
	call	VoiceState_DataBlock2_0x2C5
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Code_Loop2
	call	ToneParam_HandlerTable_BC_0x2D4
	cp	w, 0:i3
	jrl	nz, VoiceState_DataBlock2_Code_Return3
	ld	w, 104:opc
	call	MIDI_SendSysExFromW
	ld	w, 1:opc
	jp	VoiceState_DataBlock2_0x238
VoiceState_DataBlock2_Code_Return3:
	ret
	ld	a, 3:opc
	call	VoiceSlot_SaveState
VoiceState_DataBlock2_Code_Loop3:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Code_Loop4
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	nz, VoiceState_DataBlock2_Code_Loop3
VoiceState_DataBlock2_Code_Loop4:
	call	VoiceSlot_CompareAndBranch_0x7
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Code_Skip13
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Code_Skip13
	call	VoiceState_DataBlock2_0x2C5
	cp	w, 0:i3
	jrl	nz, VoiceState_DataBlock2_Code_Loop4
VoiceState_DataBlock2_Code_Loop5:
	call	VoiceSlot_CompareAndBranch_0x7
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Code_Skip11
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Code_Loop6
	call	VoiceState_DataBlock2_0x2C5
	cp	w, 0:i3
	jrl	nz, VoiceState_DataBlock2_Code_Loop5
	call	ToneParam_HandlerTable_BC_0x4DC
	jp	VoiceState_DataBlock2_0x270
VoiceState_DataBlock2_Code_Loop6:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Code_Skip12
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Code_Skip12
VoiceState_DataBlock2_Code_Skip11:
	call	VoiceState_DataBlock2_0x2C5
	cp	w, 0:i3
	jrl	nz, VoiceState_DataBlock2_Code_Loop6
	call	ToneParam_HandlerTable_BC_0x4DC
VoiceState_DataBlock2_Code_Skip12:
	ld	w, 0:opc
	jp	VoiceState_DataBlock2_0x2C4
VoiceState_DataBlock2_Code_Skip13:
	ld	a, 3:opc
	call	VoiceSlot_RestoreState
	ld	w, 255:opc
	ret
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
	ld_rrw wa, xde, hl
	ld	(0x28bf:16), wa
	srl	hl, 1
	ld	xde, 3262
	ld_rrb a, xde, hl
	pop	xde
	xor	w, w
	ld	(0x28c1:16), wa
	call	VoiceBank_ProcessCommand
	ld	xix, 3765
	ld	a, (xix)
	and	a, 240
	cp	a, 176
	jrl	nz, ScoopParam_ValueTable_Helper11_Skip
	cp	(xix+2), 72
	jrl	nz, ScoopParam_ValueTable_Helper11_Skip
	cp	(xix+3), 7
	jrl	nz, ScoopParam_ValueTable_Helper11_Skip
	ld	a, (xix+5)
	bit	4, a
	jrl	z, ScoopParam_ValueTable_Helper11_Skip
	ld	w, 0:opc
	jp	VoiceState_DataBlock2_0x330
ScoopParam_ValueTable_Helper11_Skip:
	ld	w, 255:opc
	ld	a, 2:opc
	call	VoiceSlot_RestoreState
	pop	xix
	pop	xiy
	ret
	push	xwa
	ld	xwa, (4349:16)
	ldfr_lerp xwa, 56
	pop	xwa
	push_lerp	56
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	anddi8	(0x0f56), 254
	ld	a, 4:opc
	call	VoiceSlot_SaveState
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Code_Skip14
VoiceState_DataBlock2_Code_Loop7:
	call	VoiceSlot_CompareAndBranch_0x7
	cp	w, 255
	jrl	z, VoiceState_DataBlock2_Code_Skip14
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, VoiceState_DataBlock2_Code_Loop7
	call	VoiceSlot_DispatchRet
VoiceState_DataBlock2_Code_Skip14:
	xor	a, a
	call	VoiceSlot_SaveState
	call	MemConfig_VoiceSlotLookup
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, ScoopParam_ValueTable_Helper11_Skip3
	jp	VoiceState_DataBlock2_0x3EE
ScoopParam_ValueTable_Helper11_Loop:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, ScoopParam_ValueTable_Helper11_Skip4
	call	VoiceSlot_ComputeWordIndex
	push	xde
	ld	xde, 3230
	ld_rrw	iy, xde, iz
	srl	iz, 1
	ld	xde, 3262
	ld_rrb a, xde, iz
	pop xde
	cp iy, (3583:16)
	jrl	nz, ScoopParam_ValueTable_Helper11_Skip2
	cp	a, (0x0e01:16)
	jrl	nc, ScoopParam_ValueTable_Helper11_Skip4
ScoopParam_ValueTable_Helper11_Skip2:
	call	VoiceSlot_ReadCurrentParams
ScoopParam_ValueTable_Helper11_Skip3:
	and	a, 240
	cp	a, 176
	jrl	nz, ScoopParam_ValueTable_Helper11_Loop
	call	VoiceState_DataBlock2_0x411
	cp	a, 1:i3
	jrl	z, VoiceState_DataBlock2_Code_Entry2
	cp	a, 2:i3
	jrl	z, VoiceState_DataBlock2_Code_Entry3
	jp	VoiceState_DataBlock2_0x391
VoiceState_DataBlock2_Code_Entry2:
	ordi8	(0x0f56), 1
	jp	VoiceState_DataBlock2_0x391
VoiceState_DataBlock2_Code_Entry3:
	anddi8	(0x0f56), 254
	jp	VoiceState_DataBlock2_0x391
ScoopParam_ValueTable_Helper11_Skip4:
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
	ldto_lerp xwa, 56
	ld (4349:16), xwa
	pop xwa
	ret
	call	VoiceSlot_ComputeWordIndex
	push	xde
	ld	xde, 3230
	ld_rrw iy, xde, iz
	ld (10431:16), iy
	srl	iz, 1
	ld	xde, 3262
	ld_rrb a, xde, iz
	pop xde
	xor	w, w
	ld	(0x28c1:16), wa
	call	VoiceBank_ProcessCommand
	ld	a, (3765:16)
	and	a, 240
	cp	a, 176
	jrl	z, ScoopParam_ValueTable_Helper11_Skip5
ScoopParam_ValueTable_Helper11_Loop2:
	ld	a, 0:opc
	jp	VoiceState_DataBlock2_0x471
ScoopParam_ValueTable_Helper11_Skip5:
	cpdi8	(0x0eb7), 72
	jrl	nz, ScoopParam_ValueTable_Helper11_Loop2
	cpdi8	(0x0eb8), 10
	jrl	nz, ScoopParam_ValueTable_Helper11_Loop2
	bitda	4, (0x0eba)
	jrl	z, ScoopParam_ValueTable_Helper11_Loop2
	ld	a, 1:opc
	bitda	4, (0x0eb9)
	jrl	nz, VoiceState_DataBlock2_0x471
	ld	a, 2:opc
	ret
	ld	a, 32:opc
	ld	w, (3421:16)
	cpdi8	(0x0d5c), 3
	jrl	le, ScoopParam_ValueTable_Helper11_Skip6
	sub	w, 4
	jp	VoiceState_DataBlock2_0x48E
ScoopParam_ValueTable_Helper11_Skip6:
	cp	w, 4:i3
	jrl	ule, ScoopParam_ValueTable_Helper11_Skip7
	ld	w, 4:opc
ScoopParam_ValueTable_Helper11_Skip7:
	ld	(0x371c:16), a
	ld	(0x3711:16), w
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
	jrl	ule, VoiceState_DataBlock2_Code_Skip15
	sub	h, 32
VoiceState_DataBlock2_Code_Skip15:
	ld	(0x370f:16), h
	call	DisplayStr_StyleSectionNames_0x69
	ret
VoiceState_DataBlock2_Helper2:
	ld	xix, 0xf1a0
	xor	bc, bc
	ld	c, 16:opc
	ld	a, 16:opc
	cp a, (xix+)
	jrl z, VoiceState_DataBlock2_Code_Skip16
	djnz16 bc, -9
	jp	VoiceState_DataBlock2_0x534
VoiceState_DataBlock2_Code_Skip16:
	xor	wa, wa
	ld	a, 16:opc
	sub	wa, bc
	ld	iy, wa
	sla	iy, 1
	push	xix
	ld	xix, VoiceState_DataBlock2_Tbl
	ld_rrw bc, xix, iy
	pop xix
	and	bc, (0xffec:24)
	cp	bc, 0:i3
	jrl	z, ScoopParam_ValueTable_Helper12_Skip2
	pushw	wa
	ld	xhl, 0xf250
	ld	c, 3:opc
	mul	wa, c
	ld	iy, wa
	bit_dri 7, 0x07, 0xec, 0xf4	; bit 7,(XHL+IY)
	jrl	z, ScoopParam_ValueTable_Helper12_Skip
	popw	wa
	jp	VoiceState_DataBlock2_0x51E
ScoopParam_ValueTable_Helper12_Skip:
	popw	wa
	jp	VoiceState_DataBlock2_0x534
	inc	1, a
	ld	w, a
	ld	(3414:16), w
	ordi8	(0x0d54), 1
	ordi8	(0x287b), 4
	jp	VoiceState_DataBlock2_0x540
ScoopParam_ValueTable_Helper12_Skip2:
	anddi8	(0x0d54), 254
	anddi8	(0x287b), 251
	xor	w, w
	ret
	; Byte data, 32 B.  Read by VoiceState_DataBlock2 (0xEFD17A): `ld xix, VoiceState_DataBlock2_Tbl`
	; indexed with stride 2 (`sla iy, 1`)
VoiceState_DataBlock2_Tbl:
	.byte	0x01, 0x00, 0x02, 0x00, 0x04, 0x00, 0x08, 0x00, 0x10, 0x00, 0x20, 0x00, 0x40, 0x00, 0x80, 0x00
	.byte	0x00, 0x01, 0x00, 0x02, 0x00, 0x04, 0x00, 0x08, 0x00, 0x10, 0x00, 0x20, 0x00, 0x40, 0x00, 0x80
	xor	bc, bc
VoiceState_DataBlock2_Code_Loop8:
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
	jrl	nz, VoiceState_DataBlock2_Code_Loop8
	cp	a, 130
	jrl	nz, VoiceState_DataBlock2_Code_Skip19
	cp	xix, 0x3736
	jrl	c, VoiceState_DataBlock2_Code_Return4
	ld	xwa, xix
	sub	xwa, 0x3736
	cp	xwa, 0
	jrl	nz, VoiceState_DataBlock2_Code_Skip17
	ld	wa, 1:i3
	jp	VoiceState_DataBlock2_0x5A5
VoiceState_DataBlock2_Code_Skip17:
	sla	wa, 3
	cp	a, 1:i3
	jrl	z, VoiceState_DataBlock2_Code_Skip18
	inc	1, a
VoiceState_DataBlock2_Code_Skip18:
	ld	(3931:16), a
	ld	(3930:16), 3
	jp	VoiceState_DataBlock2_0x5F1
VoiceState_DataBlock2_Code_Skip19:
	cp	a, 132
	jrl	z, VoiceState_DataBlock2_Code_Return4
	cp	a, 129
	jrl	z, VoiceState_DataBlock2_Code_Skip20
	ld	a, (3766:16)
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	pushw	bc
	ld	c, a
	ldfr_berp a, 60
	ld a, c
	scf
	stcf	a, (xix)
	ldto_berp a, 60
	popw	bc
	jp	VoiceState_DataBlock2_0x563
VoiceState_DataBlock2_Code_Skip20:
	inc	1, c
	cp c, (3777:16)
	jrl	z, VoiceState_DataBlock2_Code_Return4
	inc	1, xix
	jp	VoiceState_DataBlock2_0x563
VoiceState_DataBlock2_Code_Return4:
	ret
	ld	w, 114:opc
	call	MIDI_SendSysExFromW
	call	DisplayMode_Handler_3_0x775
	call	VoiceState_DataBlock2_0x607
	call	VoiceState_DataBlock2_0x640
	ld	w, 0:opc
	ret
	call	MemConfig_Handler_4_0x15B
	ld	xiz, 3411
	andmi8	(xiz), 191
	call	VoiceState_DataBlock2_0x65A
	cpdi8	(0x0d65), 0
	jrl	nz, VoiceState_DataBlock2_Code_Skip22
	ld	(3434:16), 0
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jr	nz, VoiceState_DataBlock2_Code_Skip21
	call	Interrupt_FlagSetBytecode_0x13
VoiceState_DataBlock2_Code_Skip21:
	call	SubCPU_ToneParamRet_0x4BD
	call	DMA_FlagCheckWithCalls
	call	SndDispatch_ProcessCommand_0x28B
VoiceState_DataBlock2_Code_Skip22:
	ld	w, 0:opc
	ret
	call	VoiceSlot_ReadCurrentParams
	cp	a, 144
	jr	nz, VoiceState_DataBlock2_Code_Skip23
	call	Interrupt_FlagSetBytecode_0x13
VoiceState_DataBlock2_Code_Skip23:
	call	SubCPU_ToneParamRet_0x4BD
	call	DMA_FlagCheckWithCalls
	call	SndDispatch_ProcessCommand_0x28B
	ret
	ld	a, (3822:16)
	ld	(3654:16), a
	xor	wa, wa
	ld	(3435:16), wa
VoiceState_DataBlock2_Code_Loop9:
	ld	a, (3822:16)
	ld	(3822:16), a
	xor	wa, wa
	ld	(3652:16), wa
	call	VoiceState_DataBlock2_0x184
	cp	w, 0:i3
	jrl	nz, VoiceState_DataBlock2_Code_Loop9
VoiceState_DataBlock2_Code_Loop10:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, VoiceState_DataBlock2_Code_Skip25
	cp	a, 129
	jrl	nz, VoiceState_DataBlock2_Code_Skip24
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	z, VoiceState_DataBlock2_Code_Skip25
VoiceState_DataBlock2_Code_Skip24:
	call	MemConfig_Handler_3_0xAC
	cpdi8	(0x0d6a), 0
	jrl	nz, VoiceState_DataBlock2_Code_Loop10
VoiceState_DataBlock2_Code_Skip25:
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, VoiceState_DataBlock2_Code_Skip27
	cp	a, 129
	jrl	nz, VoiceState_DataBlock2_Code_Loop10
	call	VoiceSlot_FlagCheck
	cp	a, 130
	jrl	nz, VoiceState_DataBlock2_Code_Loop10
	ld	wa, (3416:16)
	cpdi8	(0x0d65), 0
	jrl	nz, VoiceState_DataBlock2_Code_Skip26
	ld	(3416:16), wa
	jp	VoiceState_DataBlock2_0x6F3
VoiceState_DataBlock2_Code_Skip26:
	ld	(3418:16), wa
	jp	VoiceState_DataBlock2_0x6F3
VoiceState_DataBlock2_Code_Skip27:
	ld	wa, (3416:16)
	cpdi8	(0x0d65), 0
	jrl	nz, VoiceState_DataBlock2_Code_Skip28
	ld	(3416:16), wa
	jp	VoiceState_DataBlock2_0x6F3
VoiceState_DataBlock2_Code_Skip28:
	ld	(3418:16), wa
	ld	a, (3654:16)
	ld	(3822:16), a
	ret
	cpdi8	(0x1186), 2
	jrl	nz, VoiceState_DataBlock2_Code_Return5
	cpdi8	(0x7f42), 1
	jrl	z, VoiceState_DataBlock2_Code_Return5
	ld	(0x7f42:16), 0
	ld	a, (3429:16)
	cp	a, 0:i3
	jrl	z, VoiceState_DataBlock2_Code_Skip29
	cp	a, 3:i3
	jrl	z, VoiceState_DataBlock2_Code_Skip30
	call	VoiceState_DataBlock2_0x734
	jp	VoiceState_DataBlock2_0x733
VoiceState_DataBlock2_Code_Skip29:
	call	VoiceState_DataBlock2_0x7F9
	jp	VoiceState_DataBlock2_0x733
VoiceState_DataBlock2_Code_Skip30:
	call	VoiceState_DataBlock2_0x7AE
VoiceState_DataBlock2_Code_Return5:
	ret
	ld	wa, (0x371a:16)
	cp wa, (4357:16)
	jrl	z, VoiceState_DataBlock2_Code_Entry6
	jrl	ugt, VoiceState_DataBlock2_Code_Skip32
	ld	bc, (4357:16)
	sub	bc, wa
VoiceState_DataBlock2_Code_Entry4:
	ordi8	(0x0f57), 1
	cp	bc, 1:i3
	jrl	nz, VoiceState_DataBlock2_Code_Skip31
	anddi8	(0x0f57), 254
VoiceState_DataBlock2_Code_Skip31:
	pushw	bc
	call	ToneParam_HandlerTable_BC_0x532
	call	Display_UpdateRegion4
	popw	bc
	cpdi8	(0x7f42), 1
	jrl	z, VoiceState_DataBlock2_Code_Entry6
	dec	1, bc
	ld	wa, (0x371a:16)
	cp wa, (4357:16)
	jrl	nz, VoiceState_DataBlock2_Code_Entry4
	jp	VoiceState_DataBlock2_0x7A8
VoiceState_DataBlock2_Code_Skip32:
	ld	bc, (4357:16)
	sub	wa, bc
	ld	bc, wa
VoiceState_DataBlock2_Code_Entry5:
	ordi8	(0x0f57), 1
	cp	bc, 1:i3
	jrl	nz, VoiceState_DataBlock2_Code_Skip33
	anddi8	(0x0f57), 254
VoiceState_DataBlock2_Code_Skip33:
	pushw	bc
	call	ToneParam_HandlerTable_BC_0x4F5
	call	Display_UpdateRegion4
	popw	bc
	dec	1, bc
	ld	wa, (0x371a:16)
	cp wa, (4357:16)
	jrl	nz, VoiceState_DataBlock2_Code_Entry5
VoiceState_DataBlock2_Code_Entry6:
	anddi8	(0x0f57), 254
	ret
	ld	wa, (0x371a:16)
	cp wa, (4357:16)
	jrl	z, VoiceState_DataBlock2_Code_Return6
	jrl	ugt, VoiceState_DataBlock2_Code_Skip34
	ld	bc, (4357:16)
	sub	bc, wa
VoiceState_DataBlock2_Code_Loop11:
	pushw	bc
	call	VoiceSlot_TableSetup_0x538
	popw	bc
	cpdi8	(0x7f42), 1
	jrl	z, VoiceState_DataBlock2_Code_Return6
	ld	wa, (0x371a:16)
	cp wa, (4357:16)
	jrl	nz, VoiceState_DataBlock2_Code_Loop11
	jp	VoiceState_DataBlock2_0x7F8
VoiceState_DataBlock2_Code_Skip34:
	ld	bc, (4357:16)
	sub	wa, bc
	ld	bc, wa
VoiceState_DataBlock2_Code_Loop12:
	pushw	bc
	call	VoiceSlot_TableSetup_0x56D
	popw	bc
	ld	wa, (0x371a:16)
	cp wa, (4357:16)
	jrl	nz, VoiceState_DataBlock2_Code_Loop12
VoiceState_DataBlock2_Code_Return6:
	ret
	ld	wa, (0x371a:16)
	cp wa, (4357:16)
	jrl	z, VoiceState_DataBlock2_Code_Return7
	jrl	ugt, VoiceState_DataBlock2_Code_Skip35
	ld	bc, (4357:16)
	sub	bc, wa
	pushw	bc
	call	MemConfig_Handler_1_0x13E
	popw	bc
	ld	wa, (0x371a:16)
	cp wa, (4357:16)
	jrl	ge, VoiceState_DataBlock2_Code_Return7
	djnz16	bc, -20
	jp	VoiceState_DataBlock2_0x841
VoiceState_DataBlock2_Code_Skip35:
	ld	bc, (4357:16)
	sub	wa, bc
	ld	bc, wa
	pushw	bc
	call	MemConfig_Handler_1_0x1EF
	popw	bc
	ld	wa, (0x371a:16)
	cp wa, (4357:16)
	jrl	le, VoiceState_DataBlock2_Code_Return7
	djnz16	bc, -20
VoiceState_DataBlock2_Code_Return7:
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
	ld	xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xec, 0x0c	; cp (XIX+HL),0x0c
	jrl	z, SubCPU_ToneParamDisplay_Epilogue
	ld	(3567:16), 11
	call	Display_UpdateRegion0
	ld	(4380:16), 0
	call	SubCPU_ToneParamDisplay_0x9F
	call	SubCPU_ToneParamDisplay_0xE3
	call	SubCPU_ToneParamDisplay_0x4E
SubCPU_ToneParamDisplay_Epilogue:
	pop	xiy
	pop	xix
	ret
	push	xix
	push	xiy
	ld	a, (4381:16)
	ld	xix, 4382
	ld	(xix), 176
	cpdi8	(0x111c), 2
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
	ld	a, (0x8d3a:16)
	ld	(xix+2), a
	ld	l, (4380:16)
	exts	hl
	ld	xiy, SubCPU_ToneParamDisplay_Tbl
	ld_rrb a, xiy, hl
	ld (xix+3), a
	pop xiy
	pop xix
	ret
	push xix
	xor	hl, hl
	ld	l, (3424:16)
	dec	1, l
	ld	xix, 0xf1a0
	ld_rrb	l, xix, hl
	sla	hl, 2
	ld	xix, SubCPU_ToneDispatch
	ld_rrl	xhl, xix, hl
	cp	xhl, 4294967295
	jrl	z, SubCPU_ToneParamDisplay_Epilogue2
	xor	wa, wa
	ld	a, (4380:16)
	ld	xix, SubCPU_ToneParamDisplay_Tbl
	ld_rrb a, xix, wa
	ld_rrb a, xhl, wa
	ld (4381:16), a
SubCPU_ToneParamDisplay_Epilogue2:
	pop xix
	ret
	ld	xix, 3789
	ld	a, 32:opc
	ldw	bc, 27
	ld (xix+), a
	djnz16 bc, -6
	ld xiy, Str_PanKeyShiftTuning
	ld	a, (4380:16)
	ld	w, a
	sla	a, 3
	sla	w, 1
	add	a, w
	xor	w, w
	lda_rr xiy, xiy, wa
	ld xix, 3791
	ldw	bc, 10
	ldir85
	xor	wa, wa
	ld	a, (4381:16)
	cpdi8	(0x111c), 1
	jrl	z, SubCPU_ToneParamDisplay_Skip3
	cpdi8	(0x111c), 2
	jrl	nz, SubCPU_ToneParamDisplay_Skip4
	ldw	de, 128
	jp	SubCPU_ToneParamDisplay_0x137
SubCPU_ToneParamDisplay_Skip3:
	ldw	de, 64
	push	xix
	call	ParamDigit_CalrData
	pop	xix
	ld	a, (4480:16)
	ld (xix+), a
	jp SubCPU_ToneParamDisplay_Join
SubCPU_ToneParamDisplay_Skip4:
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
SubCPU_ToneParamDisplay_Join:
	ld	xiy, 4481
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; Lcd text, 40 B.  Read by SubCPU_ToneParamDisplay (0xEFD9BC): `ld xiy, Str_PanKeyShiftTuning`
	; reader SubCPU_ToneParamDisplay: `ld xiy, Str_PanKeyShiftTuning` then `lda_rr xiy, xiy, wa`
Str_PanKeyShiftTuning:
	.byte 0x50, 0x41
	.ascii "N      :KEY SHIFT:TUNING   :BEND SENS:"
SubCPU_ToneDispatch:
	; SubCPU_ToneDispatch -- 20 x u32: work-RAM parameter-block pointers
	; (0x0000F9B6, 0x0000F9EA, ... stride 26 within each group) with 0xFFFFFFFF
	; for an absent index, the same record shape as the MIDI CC record tables.
	; EXTENT is not inferred from the values: SubCPU_ToneDispatch_0x50 is defined
	; as this label + 80 in shared/positional_labels.s and is loaded as a BYTE
	; table (`ld xiy, ..._0x50 / ld_rrb a, xiy, hl`), so 0xEFDB90 is where this
	; table stops and a different one starts.
	; Supersedes a v10_data_as_code_census.py note for 0xEFDB49-0xEFDB5C, which
	; was this array carved 9 bytes in, and so at the wrong entry boundary.
	.long 0x0000f9b6, 0x0000f9ea, 0x0000f9d0, 0x0000fa6c
	.long 0x0000fa86, 0x0000faa0, 0x0000faba, 0x0000fad4
	.long 0x0000fa1e, 0x0000fa38, 0x0000fa52, 0x0000fa04
	.long 0x0000fb3c, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0x0000faee, 0x0000fb08, 0x0000fb22
	; Byte data, 4 B.  Read by SubCPU_ToneParamDisplay (0xEFD9BC): `ld xiy, SubCPU_ToneParamDisplay_Tbl`
	; reader SubCPU_ToneParamDisplay: `ld xiy, SubCPU_ToneParamDisplay_Tbl` then `ld_rrb a, xiy, hl`
SubCPU_ToneParamDisplay_Tbl:
	.byte	0x08, 0x09, 0x0a, 0x0b
	; Entry 1 of SubCPU_ToneParamRet (a code pointer the table holds).
SubCPU_ToneParamRet_Target1:
	xor	l, l
	bit	7, w
	jrl	nz, SubCPU_ToneParamRet_Target1_Skip
	ld	l, 3:opc
SubCPU_ToneParamRet_Target1_Skip:
	cp	(4380:16), l
	jrl	z, SubCPU_ToneParamRet_Target1_Return
	ld	a, (4380:16)
	xor	l, l
	ld	h, 3:opc
	call	SubCPU_ToneStoreDigits
	ld	(4380:16), a
	call	SubCPU_ToneParamDisplay_0x9F
	call	SubCPU_ToneParamDisplay_0xE3
	call	SubCPU_ToneParamDisplay_0x4E
SubCPU_ToneParamRet_Target1_Return:
	ret
SubCPU_ToneHandler_A:
	; --- Dispatch: set flag, load A, 3-way bounds selection, clamp+calls (70 bytes) ---
	or	(0xe3e2:16), 8
	ld	a, (4381:16)
	xor l, l
	ld h, 0x7f:opc
	cp	(4380:16), 1
	jrl nz, SubCPU_ToneHandler_B
	ld l, 0x34:opc
	ld h, 0x4c:opc
	jp SubCPU_CallRoutine
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
	call PerfMode_VoiceAddressTable_0x50
	ld	(4381:16), a
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
	jrl	z, SubCPU_ToneFormatDone_Skip
	jp	SubCPU_ToneClearRegion_0x62
SubCPU_ToneFormatDone_Skip:
	ld	w, (3538:16)
	ld	w, 6:opc
	ld	xiy, 4382
	call	SysInit_BytecodeBlock_0x486
SubCPU_ToneClearRegion:
	ordi8	(0x0dd3), 1
	xor	a, a
	ld	(3538:16), a
	ld	(3413:16), 255
	call	VoiceState_DataBlock2_0x10C
	cp	w, 0:i3
	jrl	nz, SubCPU_ToneClearRegion_Skip
	ld	l, (3429:16)
	and	l, 3
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, DisplayMode_DispatchTable
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
	jp	SubCPU_ToneClearRegion_0x62
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
	jp	SubCPU_ToneClearRegion_0x5E
SubCPU_ToneClearRegion_Skip2:
	call	DisplayMode_Handler_3_0x775
	resda	2, (0x0d54)
	ret
PerfMode_ParamHandler_11:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, PerfMode_ParamHandler_11_Return
	sla	hl, 2
	push	xix
	ld	xix, SubCPU_ToneParamRet
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
PerfMode_ParamHandler_11_Return:
	ret
	; Handler dispatch table, 128 B.  Read by PerfMode_ParamHandler_11 (0xEFDCA6): `ld xix, SubCPU_ToneParamRet`
	; indexed with stride 4 (`sla hl, 2`), index from `ld hl, bc`
	; 32 x 4-byte handler pointers; entry = index * 4, called through `call (x)`
	; index bounded to 0..31 (`cp hl, 31` / `jrl ugt` skips larger values)
SubCPU_ToneParamRet:
	.long	UIDisp_DefaultInputHandler
	.long	SubCPU_ToneParamRet_Target1
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
	.long	SubCPU_ToneParamRet_Target1
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
	call	SubCPU_ToneParamRet_0x315
	call	AccPedal_CheckBitAndUpdate
	ld	wa, (0x371a:16)
	ld	(3662:16), wa
	ld	a, (3421:16)
	ld	(3784:16), a
	ld	(3667:16), a
	cpdi16	(0x371a), 1
	jrl	z, PerfMode_ParamHandler_11_Skip6
	cpdi8	(0x0ec8), 4
	jrl	ugt, PerfMode_ParamHandler_11_Entry
	call	SubCPU_ToneParamRet_0x38A
	ld	de, (3662:16)
	inc	1, de
	ld	(0x287f:16), de
	call	SubCPU_ToneParamRet_0x315
	ld	a, (3822:16)
	call	SetWall_SlotResolve
	cpdi8	(0x287a), 0
	jrl	z, PerfMode_ParamHandler_11_Skip
	xor	wa, wa
	ld	(3664:16), wa
	ld	(3668:16), a
	jp	SubCPU_ToneParamRet_0x2CC
PerfMode_ParamHandler_11_Skip:
	ld	hl, (3662:16)
	inc	1, hl
	ld	(3664:16), hl
	ld	(3785:16), a
	ld	(3668:16), a
	cp	a, 4:i3
	jrl	ule, PerfMode_ParamHandler_11_Skip2
	ld	(3668:16), 4
PerfMode_ParamHandler_11_Skip2:
	jp	SubCPU_ToneParamRet_0x2CC
PerfMode_ParamHandler_11_Entry:
	cpdi8	(0x0d5c), 3
	jrl	ugt, PerfMode_ParamHandler_11_Skip3
	call	SubCPU_ToneParamRet_0x38A
	ld	wa, (3662:16)
	ld	(3664:16), wa
	ld	a, (3667:16)
	sub	a, 4
	ld	(3668:16), a
	ld	(3667:16), 4
	jp	SubCPU_ToneParamRet_0x2CC
PerfMode_ParamHandler_11_Skip3:
	ld	de, (3662:16)
	ld	(0x287f:16), de
	call	SubCPU_ToneParamRet_0x315
	ld	a, (3822:16)
	call	SetWall_SlotResolve
	ld	wa, (0x28af:16)
	ld	(0x28bf:16), wa
	ld	(0x28c1:16), iy
	ld	wa, (3662:16)
	ld	(3660:16), wa
	ld	(3666:16), 4
	ld	a, (3784:16)
	sub	a, 4
	ld	(3667:16), a
	ld	de, (3662:16)
	inc	1, de
	ld	(0x287f:16), de
	call	SubCPU_ToneParamRet_0x315
	ld	a, (3822:16)
	call	SetWall_SlotResolve
	cpdi8	(0x287a), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip5
	ld	hl, (3662:16)
	inc	1, hl
	ld	(3664:16), hl
	ld	(3785:16), a
	ld	(3668:16), a
	cp	a, 3:i3
	jrl	ule, PerfMode_ParamHandler_11_Skip4
	ld	(3668:16), 4
PerfMode_ParamHandler_11_Skip4:
	jp	SubCPU_ToneParamRet_0x2CC
PerfMode_ParamHandler_11_Skip5:
	xor	wa, wa
	ld	(3664:16), wa
	ld	(3668:16), a
	jp	SubCPU_ToneParamRet_0x2CC
PerfMode_ParamHandler_11_Skip6:
	ld	l, (3822:16)
	dec	1, l
	ld	h, l
	sla	l, 1
	add	l, h
	xor	h, h
	push	xde
	ld	xde, 0xf250
	add	xde, 1
	ld_rrw	hl, xde, hl
	pop	xde
	ld	(0x28bf:16), hl
	ldw	(0x28c1:16), 5
	cpdi8	(0x0ec8), 4
	jrl	ugt, PerfMode_ParamHandler_11_Skip9
	xor	wa, wa
	ld	(3660:16), wa
	ld	(3666:16), a
	ld	a, (3784:16)
	ld	(3667:16), a
	ld	de, (3662:16)
	inc	1, de
	ld	(0x287f:16), de
	call	SubCPU_ToneParamRet_0x315
	ld	a, (3822:16)
	call	SetWall_SlotResolve
	cpdi8	(0x287a), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip8
	ld	hl, (3662:16)
	inc	1, hl
	ld	(3664:16), hl
	ld	(3785:16), a
	ld	(3668:16), a
	cp	a, 4:i3
	jrl	ule, PerfMode_ParamHandler_11_Skip7
	ld	(3668:16), 4
PerfMode_ParamHandler_11_Skip7:
	jp	SubCPU_ToneParamRet_0x2CC
PerfMode_ParamHandler_11_Skip8:
	xor	wa, wa
	ld	(3664:16), wa
	ld	(3668:16), a
	jp	SubCPU_ToneParamRet_0x2CC
PerfMode_ParamHandler_11_Skip9:
	cpdi8	(0x0d5c), 3
	jrl	ugt, PerfMode_ParamHandler_11_Skip10
	xor	wa, wa
	ld	(3660:16), wa
	ld	(3666:16), a
	ld	a, (3784:16)
	ld	(3667:16), 4
	sub	a, 4
	ld	(3668:16), a
	ld	wa, (3662:16)
	ld	(3664:16), wa
	jp	SubCPU_ToneParamRet_0x2CC
PerfMode_ParamHandler_11_Skip10:
	ld	wa, (0x371a:16)
	ld	(3660:16), wa
	ld	(3666:16), 4
	ld	a, (3784:16)
	sub	a, 4
	ld	(3667:16), a
	ld	de, (0x371a:16)
	inc	1, de
	ld	(0x287f:16), de
	call	SubCPU_ToneParamRet_0x315
	ld	a, (3822:16)
	call	SetWall_SlotResolve
	cpdi8	(0x287a), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip12
	ld	hl, (0x371a:16)
	inc	1, hl
	ld	(3664:16), hl
	ld	(3785:16), a
	ld	(3668:16), a
	cp	a, 4:i3
	jrl	ule, PerfMode_ParamHandler_11_Skip11
	ld	(3668:16), 4
PerfMode_ParamHandler_11_Skip11:
	jp	SubCPU_ToneParamRet_0x2CC
PerfMode_ParamHandler_11_Skip12:
	xor	wa, wa
	ld	(3664:16), wa
	ld	(3668:16), a
	jp	SubCPU_ToneParamRet_0x2CC
	ld	wa, (3660:16)
	ld	(4476:16), wa
	ld	a, (3666:16)
	ld	(3777:16), a
	ld	xwa, 3669
	ld	(4372:16), xwa
	xor	wa, wa
	ld	(3782:16), a
	ld	(3780:16), wa
	cp	(0x117c:16), wa
	jrl	nz, PerfMode_ParamHandler_11_Return2
	ld	wa, (3662:16)
	ld	(4476:16), wa
	ld	xwa, 3701
	ld	(4372:16), xwa
	ld	(3782:16), 1
	ld	a, (3667:16)
	ld	(3777:16), a
PerfMode_ParamHandler_11_Return2:
	ret
	xor	w, w
	bitda	0, (0x0d54)
	jrl	z, PerfMode_ParamHandler_11_Skip14
	xor	hl, hl
	cp	hl, 15
	jrl	ugt, PerfMode_ParamHandler_11_Return3
	push	xde
	ld	xde, 0xf1a0
	cpib_sri 0x07, 0xe8, 0xec, 0x10	; cp (XDE+HL),0x10
	pop	xde
	jrl	nz, PerfMode_ParamHandler_11_Skip13
	ld	w, l
	inc	1, w
	jp	SubCPU_ToneParamRet_0x34E
PerfMode_ParamHandler_11_Skip13:
	inc	1, hl
	jp	SubCPU_ToneParamRet_0x320
PerfMode_ParamHandler_11_Skip14:
	anddi8	(0x287b), 251
	jp	SubCPU_ToneParamRet_0x353
	ordi8	(0x287b), 4
PerfMode_ParamHandler_11_Return3:
	ret
	xor	bc, bc
	pushw	bc
	call	VoiceBank_LoadLerpState
	popw	bc
	bit	7, a
	jrl	z, PerfMode_ParamHandler_11_Skip15
	cp	a, 130
	jrl	z, PerfMode_ParamHandler_11_Return4
	cp	a, 132
	jrl	z, PerfMode_ParamHandler_11_Return4
	cp	a, 129
	jrl	nz, PerfMode_ParamHandler_11_Skip15
	inc	1, c
	cp	c, 4:i3
	jrl	z, PerfMode_ParamHandler_11_Skip16
PerfMode_ParamHandler_11_Skip15:
	pushw	bc
	call	VoiceBank_UpdateLerpState
	popw	bc
	jp	SubCPU_ToneParamRet_0x356
PerfMode_ParamHandler_11_Skip16:
	call	VoiceBank_UpdateLerpState
PerfMode_ParamHandler_11_Return4:
	ret
	ld	de, (3662:16)
	dec	1, de
	ld	(0x287f:16), de
	call	SubCPU_ToneParamRet_0x315
	ld	a, (3822:16)
	call	SetWall_SlotResolve
	pushw	wa
	ld	wa, (0x28af:16)
	ld	(0x28bf:16), wa
	ld	(0x28c1:16), iy
	ld	hl, (3662:16)
	dec	1, hl
	ld	(3660:16), hl
	popw	wa
	ld	(3783:16), a
	ld	(3666:16), a
	cp	a, 4:i3
	jrl	ule, PerfMode_ParamHandler_11_Return5
	sub	a, 4
	ld	(3666:16), a
	call	SubCPU_ToneParamRet_0x354
PerfMode_ParamHandler_11_Return5:
	ret
	call	Display_ResetDirtyFlags
	call	SubCPU_ToneParamRet_0x3DE
	call	Display_UpdateDirtyRegions
	ret
	cpdi8	(0x8d38), 138
	jrl	nz, PerfMode_ParamHandler_11_Return6
	ld	a, (0xc07d:16)
	cp	a, 0:i3
	jrl	nz, PerfMode_ParamHandler_11_Return6
	ld	a, (3429:16)
	cp	a, 1:i3
	jrl	z, PerfMode_ParamHandler_11_Skip17
	cp	a, 2:i3
	jrl	nz, PerfMode_ParamHandler_11_Return6
PerfMode_ParamHandler_11_Skip17:
	ld	w, (0xc07e:16)
	ld	a, (0xc07f:16)
	cp	w, 0:i3
	jrl	nz, PerfMode_ParamHandler_11_Return6
	and	a, 3
	cp	a, 1:i3
	jrl	z, PerfMode_ParamHandler_11_Skip18
	cp	a, 2:i3
	jrl	z, PerfMode_ParamHandler_11_Skip18
	cp	a, 3:i3
	jrl	nz, PerfMode_ParamHandler_11_Return6
PerfMode_ParamHandler_11_Skip18:
	ld	(3382:16), 0
	bitda	7, (0x0d39)
	jrl	z, PerfMode_ParamHandler_11_Skip20
	anddi8	(0x0f57), 254
	call	Display_UpdateRegion0
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, PerfMode_ParamHandler_11_Skip19
	cp	a, 130
	jrl	z, PerfMode_ParamHandler_11_Skip19
	call	VoiceSlot_FlagCheck
	cp	a, (0x0d57:16)
	jrl	nc, PerfMode_ParamHandler_11_Skip19
	call	DMA_FlagCheckWithCalls
	resda	2, (0x0d54)
	jp	SubCPU_ToneParamRet_0x461
PerfMode_ParamHandler_11_Skip19:
	ld	(0x3717:16), 255
	call	DisplayMode_Handler_3_0x775
	ordi8	(0x0dd3), 1
	ldw	(9920:16), 0
	call	VoiceSlot_TableSetup
	jp	SubCPU_ToneParamRet_0x4BC
PerfMode_ParamHandler_11_Skip20:
	anddi8	(0x0f57), 254
	call	Display_UpdateRegion0
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	z, PerfMode_ParamHandler_11_Skip21
	cp	a, 130
	jrl	z, PerfMode_ParamHandler_11_Skip21
	call	VoiceSlot_FlagCheck
	cp	a, (0x0d57:16)
	jrl	nc, PerfMode_ParamHandler_11_Skip21
	call	DMA_FlagCheckWithCalls
	resda	2, (0x0d54)
	jp	SubCPU_ToneParamRet_0x4AD
PerfMode_ParamHandler_11_Skip21:
	ld	(0x3717:16), 255
	call	DisplayMode_Handler_3_0x775
	ordi8	(0x0dd3), 1
	ldw	(9920:16), 0
	call	VoiceSlot_TableSetup
PerfMode_ParamHandler_11_Return6:
	ret
	cpdi8	(0x28be), 255
	jrl	z, PerfMode_ParamHandler_11_Skip22
PerfMode_ParamHandler_11_Loop:
	call	Display_UpdateRegion1
	jp	SubCPU_ToneParamRet_0x7B8
PerfMode_ParamHandler_11_Skip22:
	ld	l, (3424:16)
	dec	1, l
	ld	h, l
	sla	l, 1
	add	l, h
	xor	h, h
	push	xde
	ld	xde, 0xf250
	bit_dri 7, 0x07, 0xe8, 0xec	; bit 7,(XDE+HL)
	pop	xde
	jrl	z, PerfMode_ParamHandler_11_Loop
	call	OscScope_RenderBlock_0x21
	call	SubCPU_ToneParamRet_0x80
	call	VoiceBank_ProcessCommand
	cpdi8	(0x0eb5), 129
	jrl	nz, PerfMode_ParamHandler_11_Skip24
	call	DisplayStr_BytecodeBlock_A_0x1A4
	ld	a, (3771:16)
	cp	a, 130
	jrl	nz, PerfMode_ParamHandler_11_Skip23
	call	SubCPU_ToneParamRet_0x98D
	jp	SubCPU_ToneParamRet_0x7B8
PerfMode_ParamHandler_11_Skip23:
	call	StringData_APCModeNames_0x713
	jp	SubCPU_ToneParamRet_0x5E9
PerfMode_ParamHandler_11_Skip24:
	cpdi8	(0x0eb5), 130
	jrl	z, PerfMode_ParamHandler_11_Skip25
	cpdi8	(0x0eb5), 132
	jrl	z, PerfMode_ParamHandler_11_Skip25
	cpdi8	(0x0eb6), 48
	jrl	nz, PerfMode_ParamHandler_11_Skip25
	call	StringData_APCModeNames_0x713
	jp	SubCPU_ToneParamRet_0x5E9
PerfMode_ParamHandler_11_Skip25:
	ldw	(3778:16), 0
	ld	a, (3765:16)
	cp	a, 130
	jrl	z, PerfMode_ParamHandler_11_Skip26
	cp	a, 132
	jrl	nz, PerfMode_ParamHandler_11_Skip27
	call	SubCPU_ToneParamRet_0x9AF
	jp	SubCPU_ToneParamRet_0x7B8
PerfMode_ParamHandler_11_Skip26:
	call	SubCPU_ToneParamRet_0x98D
	jp	SubCPU_ToneParamRet_0x7B8
PerfMode_ParamHandler_11_Skip27:
	and	a, 240
	cp	a, 144
	jrl	nz, PerfMode_ParamHandler_11_Skip28
	call	SubCPU_ToneParamRet_0x8C5
	cpdi8	(0x0ef6), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip51
	jp	SubCPU_ToneParamRet_0x5E9
PerfMode_ParamHandler_11_Skip28:
	ld	a, (3765:16)
	cp	a, 132
	jrl	nz, PerfMode_ParamHandler_11_Skip29
	call	SubCPU_ToneParamRet_0x9AF
	jp	SubCPU_ToneParamRet_0x7B8
PerfMode_ParamHandler_11_Skip29:
	and	a, 240
	ld	a, (3766:16)
	cp	a, 47
	jrl	z, PerfMode_ParamHandler_11_Skip30
	cp	a, 95
	jrl	nz, PerfMode_ParamHandler_11_Skip31
PerfMode_ParamHandler_11_Skip30:
	jp	SubCPU_ToneParamRet_0x4F3
PerfMode_ParamHandler_11_Skip31:
	call	SubCPU_ToneParamRet_0xA1F
	ld	a, (3766:16)
	ld	(3952:16), a
PerfMode_ParamHandler_11_Loop2:
	call	VoiceBank_ProcessCommand
	ld	a, (3765:16)
	cp	a, 129
	jrl	z, PerfMode_ParamHandler_11_Loop3
	cp	a, 132
	jrl	z, PerfMode_ParamHandler_11_Loop3
	ld	l, (3766:16)
	cp	l, 47
	jrl	z, PerfMode_ParamHandler_11_Loop2
	cp	l, 95
	jrl	z, PerfMode_ParamHandler_11_Loop2
	cp	l, (0x0f70:16)
	jrl	nz, PerfMode_ParamHandler_11_Loop3
	and	a, 240
	cp	a, 144
	jrl	nz, PerfMode_ParamHandler_11_Loop2
	jp	SubCPU_ToneParamRet_0x5E9
PerfMode_ParamHandler_11_Loop3:
	ld	a, (3765:16)
	cp	a, 129
	jrl	z, PerfMode_ParamHandler_11_Skip38
	cp	a, 130
	jrl	nz, PerfMode_ParamHandler_11_Skip32
	call	SubCPU_ToneParamRet_0x98D
	jp	SubCPU_ToneParamRet_0x7B8
PerfMode_ParamHandler_11_Skip32:
	cp	a, 132
	jrl	nz, PerfMode_ParamHandler_11_Skip33
	call	SubCPU_ToneParamRet_0x9AF
	jp	SubCPU_ToneParamRet_0x7B8
PerfMode_ParamHandler_11_Skip33:
	and	a, 240
	cp	a, 144
	jrl	z, PerfMode_ParamHandler_11_Skip48
	cpdi8	(0x0eb6), 47
	jrl	z, PerfMode_ParamHandler_11_Skip34
	cpdi8	(0x0eb6), 95
	jrl	nz, PerfMode_ParamHandler_11_Skip35
PerfMode_ParamHandler_11_Skip34:
	call	VoiceBank_ProcessCommand
	jp	SubCPU_ToneParamRet_0x5E9
PerfMode_ParamHandler_11_Skip35:
	ld	a, (3766:16)
	ld	l, (3778:16)
	cp	l, 0:i3
	jrl	nz, PerfMode_ParamHandler_11_Skip36
	ld	l, (3952:16)
PerfMode_ParamHandler_11_Skip36:
	sub	a, l
	cp	a, 0:i3
	jrl	z, PerfMode_ParamHandler_11_Skip37
	call	DisplayStr_BytecodeBlock_A_0xCD
	cpdi8	(0x0ef6), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip51
PerfMode_ParamHandler_11_Skip37:
	call	SubCPU_ToneParamRet_0xA1F
	ldw	(3778:16), 0
	ld	a, (3766:16)
	ld	(3952:16), a
PerfMode_ParamHandler_11_Loop4:
	call	VoiceBank_ProcessCommand
	ld	a, (3765:16)
	cp	a, 129
	jrl	z, PerfMode_ParamHandler_11_Loop3
	cp	a, 132
	jrl	z, PerfMode_ParamHandler_11_Loop3
	ld	h, (3766:16)
	cp	h, 47
	jrl	z, PerfMode_ParamHandler_11_Loop4
	cp	h, 95
	jrl	z, PerfMode_ParamHandler_11_Loop4
	ld	l, (3952:16)
	cp	l, h
	jrl	nz, PerfMode_ParamHandler_11_Loop3
	and	a, 240
	cp	a, 144
	jrl	nz, PerfMode_ParamHandler_11_Loop4
	jp	SubCPU_ToneParamRet_0x5E9
PerfMode_ParamHandler_11_Skip38:
	call	DisplayStr_BytecodeBlock_A_0x1A4
	ld	a, (3771:16)
	cp	a, 130
	jrl	z, PerfMode_ParamHandler_11_Skip40
	cp	a, 132
	jrl	z, PerfMode_ParamHandler_11_Skip39
	cp	a, 129
	jrl	nz, PerfMode_ParamHandler_11_Skip41
PerfMode_ParamHandler_11_Skip39:
	call	DisplayStr_BytecodeBlock_A
	cpdi8	(0x0ef6), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip51
	call	VoiceBank_ProcessCommand
	jp	SubCPU_ToneParamRet_0x5E9
PerfMode_ParamHandler_11_Skip40:
	call	SubCPU_ToneParamRet_0x98D
	jp	SubCPU_ToneParamRet_0x7B8
PerfMode_ParamHandler_11_Skip41:
	ld	l, (3772:16)
	add	l, 96
	ld	c, (3952:16)
	cpdi16	(0x0ec2), 0
	jrl	z, PerfMode_ParamHandler_11_Skip42
	ld	c, (3778:16)
PerfMode_ParamHandler_11_Skip42:
	sub	l, c
	cp	l, 48
	jrl	z, PerfMode_ParamHandler_11_Skip44
	cp	l, 96
	jrl	z, PerfMode_ParamHandler_11_Skip46
	call	DisplayStr_BytecodeBlock_A
	cpdi8	(0x0ef6), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip51
	call	DisplayStr_BytecodeBlock_A_0xCD
	cpdi8	(0x0ef6), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip51
	xor	a, a
	cpdi8	(0x0ebc), 48
	jrl	nz, PerfMode_ParamHandler_11_Skip43
	ld	a, 48:opc
PerfMode_ParamHandler_11_Skip43:
	ld	(3952:16), a
	ldw	(3778:16), 0
	jp	SubCPU_ToneParamRet_0x777
PerfMode_ParamHandler_11_Skip44:
	call	DisplayStr_BytecodeBlock_A_0xCD
	cpdi8	(0x0ef6), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip51
	xor	a, a
	cpdi8	(0x0ebc), 48
	jrl	nz, PerfMode_ParamHandler_11_Skip45
	ld	a, 48:opc
PerfMode_ParamHandler_11_Skip45:
	ld	(3952:16), a
	ldw	(3778:16), 0
	jp	SubCPU_ToneParamRet_0x777
PerfMode_ParamHandler_11_Skip46:
	call	DisplayStr_BytecodeBlock_A
	cpdi8	(0x0ef6), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip51
	xor	wa, wa
	ld	(3778:16), wa
	ld	(3952:16), a
	cpdi8	(0x0ebc), 0
	jrl	z, PerfMode_ParamHandler_11_Skip47
	ld	(3952:16), 48
PerfMode_ParamHandler_11_Skip47:
	call	VoiceBank_ProcessCommand
	jp	SubCPU_ToneParamRet_0x5E9
PerfMode_ParamHandler_11_Skip48:
	ld	a, (3766:16)
	ld	l, (3778:16)
	add	l, (3952:16)
	cp	l, 96
	jrl	c, PerfMode_ParamHandler_11_Skip49
	sub	l, 96
PerfMode_ParamHandler_11_Skip49:
	sub	a, l
	cp	a, 48
	jrl	nz, PerfMode_ParamHandler_11_Skip50
	call	DisplayStr_BytecodeBlock_A_0xCD
	cpdi8	(0x0ef6), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip51
PerfMode_ParamHandler_11_Skip50:
	call	SubCPU_ToneParamRet_0x8C5
	cpdi8	(0x0ef6), 0
	jrl	nz, PerfMode_ParamHandler_11_Skip51
	jp	SubCPU_ToneParamRet_0x5E9
PerfMode_ParamHandler_11_Skip51:
	call	OscScope_RenderBlock_0x61
	call	SubCPU_ToneParamRet_0x7C1
	ret
	cpdi8	(0x0d6a), 0
	jrl	nz, PerfMode_ParamHandler_11_Return7
	call	SubCPU_ToneParamRet_0x315
	call	AccPedal_CheckBitAndUpdate
	cpdi8	(0x0d5d), 4
	jrl	ugt, PerfMode_ParamHandler_11_Skip52
	ld	a, (3420:16)
	jp	SubCPU_ToneParamRet_0x7ED
PerfMode_ParamHandler_11_Skip52:
	ld	a, (3420:16)
	cp	a, 4:i3
	jrl	c, PerfMode_ParamHandler_11_Skip53
	sub	a, 4
PerfMode_ParamHandler_11_Skip53:
	sla	a, 1
	cpdi8	(0x0d57), 0
	jrl	z, PerfMode_ParamHandler_11_Skip54
	inc	1, a
PerfMode_ParamHandler_11_Skip54:
	ld	(3823:16), a
PerfMode_ParamHandler_11_Return7:
	ret
	pushw	wa
	push	xiy
	push	xix
	ld	a, (4478:16)
	ld	(3395:16), a
	call	SubCPU_ToneParamRet_0x840
	ld	c, (4478:16)
	xor	b, b
	ld	xiy, 4457
	ld	xix, 3396
	ldir85
	push	xwa
	push	xbc
	push	xde
	xor	xwa, xwa
	ld	xwa, 3395
	xor	xbc, xbc
	ld	xbc, 3395
	xor	xde, xde
	ld	e, 2:opc
	call	NoteDisplay_StoreAndDispatch
	pop	xde
	pop	xbc
	pop	xwa
	pop	xix
	pop	xiy
	popw	wa
	ret
	ld	c, a
	dec	1, c
	xor	b, b
	xor	de, de
PerfMode_ParamHandler_11_Loop5:
	ld	xiy, 4457
	ld	xix, xiy
	inc	1, xix
	lda_rr	xiy, xiy, de
	lda_rr	xix, xix, de
	ld	a, (xiy)
	ld	w, (xix)
	cp	a, w
	jrl	c, PerfMode_ParamHandler_11_Skip55
	inc	1, xix
	ld	xhl, 4457
	lda_rr	xhl, xhl, bc
	cp	xix, xhl
	jrl	ugt, PerfMode_ParamHandler_11_Skip56
	jp	SubCPU_ToneParamRet_0x85D
PerfMode_ParamHandler_11_Skip55:
	ld	(xiy), w
	ld	(xix), a
	xor	de, de
	jp	SubCPU_ToneParamRet_0x848
PerfMode_ParamHandler_11_Skip56:
	inc	1, de
	cp	de, bc
	jrl	c, PerfMode_ParamHandler_11_Loop5
	ret
	ld	xix, (4372:16)
	xor	hl, hl
	ld	l, (3780:16)
	sla	l, 2
	lda_rr	xix, xix, hl
	xor	wa, wa
	ld	a, (xix)
	and	a, 96
	cp	a, 0:i3
	jrl	z, PerfMode_ParamHandler_11_Skip57
	inc	1, xix
	jp	SubCPU_ToneParamRet_0x8B4
PerfMode_ParamHandler_11_Skip57:
	ld	a, 32:opc
	ld	(xix+), a
	xor	a, a
	ld	(xix+), a
	ldb_d8	w, (0x0d43)
	ld	a, (3396:16)
	ld	(xix+), wa
	ret
	pushw	bc
	xor	wa, wa
	ld	bc, 3:i3
	ld	xix, 4457
	ld	(xix+), wa
	djnz16	bc, -6
	popw	bc
	ld	(4478:16), 1
	ld	a, (3766:16)
	ld	(3952:16), a
	ld	a, (3767:16)
	ld	xix, 4457
	ld	(xix+), a
	push	xix
	call	OscScope_Handler_7_Helper
	pop	xix
PerfMode_ParamHandler_11_Join:
	push	xix
	call	VoiceBank_ProcessCommand
	pop	xix
	cpdi8	(0x0eb5), 129
	jrl	z, PerfMode_ParamHandler_11_Skip58
	cpdi8	(0x0eb5), 132
	jrl	z, PerfMode_ParamHandler_11_Skip58
	ld	a, (3765:16)
	and	a, 240
	cp	a, 144
	jrl	nz, PerfMode_ParamHandler_11_Skip58
	ld	a, (3766:16)
	cp	a, (0x0f70:16)
	jrl	nz, PerfMode_ParamHandler_11_Skip58
	inc	1, (4478:16)
	ld	a, (3767:16)
	ld	(xix+), a
	jp	PerfMode_ParamHandler_11_Join
PerfMode_ParamHandler_11_Skip58:
	ld	a, (3952:16)
	xor	w, w
	ld	de, (3778:16)
	add	wa, de
	ld	(3778:16), wa
	ld	l, 96:opc
	div	wa, l
	cp	a, 0:i3
	jrl	z, PerfMode_ParamHandler_11_Skip60
	ld	c, a
	xor	b, b
	cpdi8	(0x0eb5), 129
	jrl	nz, PerfMode_ParamHandler_11_Skip59
	djnz16	bc, 4
	jp	SubCPU_ToneParamRet_0x97C
PerfMode_ParamHandler_11_Loop6:
	pushw	bc
	call	VoiceBank_ProcessCommand
	popw	bc
	jp	SubCPU_ToneParamRet_0x94F
PerfMode_ParamHandler_11_Skip59:
	ld	a, (3766:16)
	cp	a, 47
	jrl	z, PerfMode_ParamHandler_11_Loop6
	cp	a, 95
	jrl	z, PerfMode_ParamHandler_11_Loop6
	jp	SubCPU_ToneParamRet_0x980
	call	VoiceBank_ProcessCommand
PerfMode_ParamHandler_11_Skip60:
	call	SubCPU_ToneParamRet_0x7FF
	call	SubCPU_ToneParamRet_0x88B
	call	OscScope_DrawWaveform_0x4
	ret
	ld	xix, (4372:16)
	ld	e, (3780:16)
	sla	e, 2
	xor	d, d
	extz	xde
	add	xix, xde
	xor	de, de
	andmi8	(xix), 127
	ld	(xix+1), 1
	ld	(xix+2), de
	call	SubCPU_ToneParamRet_0x9D1
	ret
	ld	xix, (4372:16)
	ld	e, (3780:16)
	sla	e, 2
	xor	d, d
	extz	xde
	add	xix, xde
	xor	de, de
	andmi8	(xix), 127
	ld	(xix+1), 2
	ld	(xix+2), de
	call	SubCPU_ToneParamRet_0x9D1
	ret
	ld	l, (3777:16)
	sla	l, 1
	ld	a, (3780:16)
	cp	a, l
	jrl	nc, PerfMode_ParamHandler_11_Skip61
	incw	1, (3780:16)
	ld	ix, (3780:16)
	sla	ix, 2
	ldw	bc, 32
	sub	bc, ix
	cp	bc, 0:i3
	jrl	z, PerfMode_ParamHandler_11_Skip61
	extz	xix
	add	xix, (4372:16)
	xor	a, a
	ld	(xix+), a
	djnz16	bc, -6
PerfMode_ParamHandler_11_Skip61:
	jp	PerfMode_ParamHandler_11_Return8
	ldb_d8	e, (0x0ec6)
	cp	e, 2:i3
	jrl	z, PerfMode_ParamHandler_11_Return8
	cp	e, 0:i3
	jrl	nz, PerfMode_ParamHandler_11_Skip62
	call	OscScope_RenderBlock_0x3F
PerfMode_ParamHandler_11_Skip62:
	call	OscScope_RenderBlock_0x50
PerfMode_ParamHandler_11_Return8:
	ret
	ld	a, (3765:16)
	and	a, 1
	rrc	a
	ld	(4461:16), a
	ld	l, (3766:16)
	cp	l, 47
	jrl	z, PerfMode_ParamHandler_11_Return9
	cp	l, 95
	jrl	z, PerfMode_ParamHandler_11_Return9
	ld	l, (3767:16)
	cp	l, 72
	jrl	nz, PerfMode_ParamHandler_11_Return9
	cpdi8	(0x0eb8), 5
	jrl	z, PerfMode_ParamHandler_11_Skip63
	cpdi8	(0x0eb8), 6
	jrl	nz, PerfMode_ParamHandler_11_Return9
PerfMode_ParamHandler_11_Skip63:
	ld	a, (3769:16)
	and	a, 127
	or	a, (4461:16)
	xor	bc, bc
PerfMode_ParamHandler_11_Loop7:
	ldfr_berp	a, 60
	ldfr_berp	a, 61
	ld	a, c
	scf
	xorcfb_erp	61
	ldto_berp	a, 60
	jrl	nc, PerfMode_ParamHandler_11_Entry2
	inc	1, c
	cp	c, 7:i3
	jrl	ule, PerfMode_ParamHandler_11_Loop7
	jp	SubCPU_ToneParamRet_0xAA3
PerfMode_ParamHandler_11_Entry2:
	cpdi8	(0x0eb8), 6
	jrl	nz, PerfMode_ParamHandler_11_Skip64
	add	c, 8
PerfMode_ParamHandler_11_Skip64:
	xor	h, h
	ld	l, c
	sla	hl, 2
	extz	xhl
	push	xde
	ld	xde, OscScope_HandlerTable
	ld_rrl	xhl, xde, hl
	pop	xde
	call	(xhl)
PerfMode_ParamHandler_11_Return9:
	ret


OscScope_HandlerTable:
	; OscScope_HandlerTable -- 16 handler pointers (`ld xde, OscScope_HandlerTable`
	; in this file). Only the last entry was untyped; 16 entries reach exactly the
	; next label, SndHandler_DefaultRet.
	.long SndHandler_DefaultRet
	.long SndHandler_DefaultRet
	.long OscScope_Handler_2
	.long OscScope_Handler_3
	.long OscScope_Handler_4
	.long OscScope_Handler_4
	.long OscScope_Handler_6
	.long OscScope_Handler_7
	.long SndHandler_DefaultRet
	.long SndHandler_DefaultRet
	.long OscScope_Handler_2
	.long SndHandler_DefaultRet
	.long SndHandler_DefaultRet
	.long SndHandler_DefaultRet
	.long SndHandler_DefaultRet
	.long SndHandler_DefaultRet
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
	ld	xix, (4372:16)
	ld	e, (3780:16)
	sla	e, 2
	xor	d, d
	extz	xde
	add	xix, xde
	andmi8	(xix), 223
	ormi8	(xix), 64
	ret
	ldda32	xix, (0x1114)
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
	stda16	(0x0ec2), wa
	pop	xhl
	popw	wa
	ret
	cpdi8	(0x0f70), 48
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
	call	DisplayStr_BytecodeBlock_A_0x53
	popw	bc
	djnz16	bc, -9
	ldw	(3778:16), 0
	jp	OscScope_RefreshLoop_0x3F
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
	call	DisplayStr_BytecodeBlock_A_0x53
	popw	bc
	djnz16	bc, -9
OscScope_UpdateDisplay_Skip:
	call	DisplayStr_BytecodeBlock_A_0x120
	ldw	(3778:16), 0
	ld	(3952:16), 0
	jp	OscScope_RefreshLoop_0x3F
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
	call	DisplayStr_BytecodeBlock_A_0x53
	popw	de
	popw	bc
	cpdi8	(0x0ef6), 0
	jrl	nz, OscScope_RefreshLoop_Return
	djnz16	bc, -19
OscScope_RefreshLoop_Skip:
	cp	e, 0:i3
	jrl	z, OscScope_RefreshLoop_Return
	cpdi8	(0x0f70), 48
	jrl	z, OscScope_RefreshLoop_0x3F
	call	DisplayStr_BytecodeBlock_A_0x120
OscScope_RefreshLoop_Return:
	ret
MemConfig_Handler_3_Helper:
	push	xhl
	call	VoiceSlot_ReadCurrentParams
	cp	a, 132
	jrl	z, OscScope_RenderBlock_Skip3
	ld	a, 7:opc
	call	VoiceSlot_SaveState
	xor	bc, bc
	ld	l, (3822:16)
	xor	h, h
	dec	1, hl
	sla	hl, 1
	push	xde
	ld	xde, 3230
	ld_rrw wa, xde, hl
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
	jp	OscScope_RenderBlock_0xE
OscScope_RenderBlock_Skip2:
	ld	w, 0:opc
	pop	xhl
	pushw	wa
	ld	a, 7:opc
	call	VoiceSlot_RestoreState
	popw	wa
	jp	OscScope_RenderBlock_0x20
OscScope_RenderBlock_Skip3:
	ld	bc, 2:i3
	pop	xhl
	ld	w, 255:opc
	ret
	call	OscScope_RenderBlock_0x2E
	call	OscScope_RenderBlock_0x3F
	call	OscScope_RenderBlock_0x50
	ret
	ld	xix, 3669
	ldw	bc, 16
	xor	wa, wa
	ld	(xix+), wa
	djnz16	bc, -6
	ret
	ld	xix, 3701
	ldw	bc, 16
	xor	wa, wa
	ld	(xix+), wa
	djnz16	bc, -6
	ret
	ld	xix, 3733
	ldw	bc, 16
	xor	wa, wa
	ld	(xix+), wa
	djnz16	bc, -6
	ret
	ld	xiy, 3669
	.set	OscScope_FinalizeRender, . + 2	; no instruction starts here: the name points 2 byte(s) into the one below
	ld	xix, 0x0e59
	ld	c, 1:opc
	ld	e, (3666:16)
	sla	e, 1
	call	OscScope_FinalizeRender_0x79
	cpdi8	(0x117f), 0
	jrl	nz, OscScope_FinalizeRender_Return
	ld	xiy, 3701
	ld	xix, 3705
	ld	c, 1:opc
	ld	e, (3667:16)
	sla	e, 1
	call	OscScope_FinalizeRender_0x79
	cpdi8	(0x117f), 0
	jrl	nz, OscScope_FinalizeRender_Return
	ld	xiy, 3733
	ld	xix, 3737
	ld	c, 1:opc
	ld	e, (3668:16)
	sla	e, 1
	call	OscScope_FinalizeRender_0x79
	ld	xiy, 3697
	cp	(xiy), 0
	jrl	z, OscScope_FinalizeRender_Skip
	ormi8	(xiy), 128
OscScope_FinalizeRender_Skip:
	ld	xiy, 3729
	cp	(xiy), 0
	jrl	z, OscScope_FinalizeRender_Skip2
	ormi8	(xiy), 128
OscScope_FinalizeRender_Skip2:
	ld	xiy, 3761
	cp	(xiy), 0
	jrl	z, OscScope_FinalizeRender_Return
	ormi8	(xiy), 128
OscScope_FinalizeRender_Return:
	ret
	ld	(4479:16), 0
	cp	e, 0:i3
	jrl	z, OscScope_RenderBlock_Return
OscScope_RenderBlock_Join:
	cp	c, e
	jrl	z, OscScope_RenderBlock_Return
	ld	a, (xiy+1)
	cp	a, 6:i3
	jrl	z, OscScope_FinalizeRender_Skip3
	cp	a, 7:i3
	jrl	nz, OscScope_FinalizeRender_Entry
OscScope_FinalizeRender_Skip3:
	ld	(4479:16), 255
	jp	OscScope_FinalizeRender_0xCB
OscScope_FinalizeRender_Entry:
	cp	(xix+1), 0
	jrl	nz, OscScope_FinalizeRender_Entry2
	cp	(xix+2), 0
	jrl	z, OscScope_FinalizeRender_Entry3
OscScope_FinalizeRender_Entry2:
	cp	(xiy+2), 0
	jrl	nz, OscScope_RenderBlock_Skip4
OscScope_FinalizeRender_Entry3:
	andmi8	(xiy), 127
	jp	OscScope_RenderBlock_Join2
OscScope_RenderBlock_Skip4:
	ormi8	(xiy), 128
OscScope_RenderBlock_Join2:
	add	iy, 4
	add	ix, 4
	inc	1, c
	jp	OscScope_RenderBlock_Join
OscScope_RenderBlock_Return:
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
	ldb_sri A, 0x07, 0xf4, 0xf0
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
	ld	(3830:16), 0
	ld	c, (3777:16)
	sla	c, 1
	xor	hl, hl
	ld	l, (3780:16)
	sla	hl, 2
	xor	wa, wa
	ld	xiy, (4372:16)
	ld_rrb a, xiy, hl
	and a, 96
	cp	a, 0:i3
	jrl	nz, DisplayStr_BytecodeBlock_A_Skip4
	ld	a, 32:opc
	st_rrb	a, xiy, hl
DisplayStr_BytecodeBlock_A_Skip4:
	xor	wa, wa
	ldfr_lerp	xiy, 56
	lda_rr	xiy, xiy, hl
	ld	(xiy+1), 3
	ldto_lerp xiy, 56
	ldfr_lerp xiy, 56
	lda_rr xiy, xiy, hl
	ld (xiy+2), wa
	ldto_lerp xiy, 56
	call	DisplayStr_BytecodeBlock_A_0x53
	ret
	ld	(3830:16), 0
	adddi16	(0x0ec4), 2
	ld	c, (3777:16)
	sla	c, 1
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
	ld_rrl xhl, xde, hl
	pop	xde
	ld	wa, (xhl)
	cp	wa, 0:i3
	jrl	nz, DisplayStr_BytecodeBlock_A_Skip
DisplayStr_BytecodeBlock_A_Loop:
	ld	(3830:16), 1
	jp	DisplayStr_BytecodeBlock_A_0x52
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
	ld	(3830:16), 0
	ld	c, (3777:16)
	sla	c, 1
	xor	hl, hl
	ld	l, (3780:16)
	sla	hl, 2
	xor	wa, wa
	ld	xiy, (4372:16)
	ld_rrb a, xiy, hl
	and a, 96
	cp	a, 0:i3
	jrl	nz, DisplayStr_BytecodeBlock_A_Skip5
	ld	a, 32:opc
	st_rrb	a, xiy, hl
DisplayStr_BytecodeBlock_A_Skip5:
	xor	wa, wa
	ldfr_lerp	xiy, 56
	lda_rr	xiy, xiy, hl
	ld	(xiy+1), 4
	ldto_lerp	xiy, 56
	ldfr_lerp	xiy, 56
	lda_rr	xiy, xiy, hl
	ld	(xiy+2), wa
	ldto_lerp	xiy, 56
	call	DisplayStr_BytecodeBlock_A_0x120
	ret
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
	ld_rrl xhl, xde, hl
	pop	xde
	ld	wa, (xhl)
	cp	wa, 0:i3
	jrl	nz, DisplayStr_BytecodeBlock_A_Skip3
DisplayStr_BytecodeBlock_A_Loop2:
	ld	(3830:16), 1
	jp	DisplayStr_BytecodeBlock_A_0x11F
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
	; Byte data, 12 B.  Read by DisplayStr_BytecodeBlock_A (0xEFEB06): `ld xde, DisplayStr_BytecodeBlock_A_Tbl`
	; indexed with stride 4 (`sla hl, 2`), index from `ld l, (3782:16)`
DisplayStr_BytecodeBlock_A_Tbl:
	.byte	0x4c, 0x0e, 0x00, 0x00, 0x4e, 0x0e, 0x00, 0x00, 0x50, 0x0e, 0x00, 0x00
	pushdi_w	(0x28bf)
	pushdi_w	(0x28c1)
	push	xhl
	push	xiy
	push	xix
DisplayStr_BytecodeBlock_A_Loop3:
	ld	xix, 3771
	call	VoiceBank_LoadLerpState
DisplayStr_BytecodeBlock_A_Loop4:
	ld	(xix), a
	cp	a, 129
	jrl	z, DisplayStr_BytecodeBlock_A_Skip7
	cp	a, 132
	jrl	z, DisplayStr_BytecodeBlock_A_Skip7
	cp	a, 130
	jrl	z, DisplayStr_BytecodeBlock_A_Skip7
	inc	1, xix
	push	xix
	call	VoiceBank_UpdateLerpState
	call	VoiceBank_LoadLerpState
	pop	xix
	bit	7, a
	jrl	z, DisplayStr_BytecodeBlock_A_Loop4
	ld	a, (3772:16)
	cp	a, 47
	jrl	z, DisplayStr_BytecodeBlock_A_Loop3
	cp	a, 95
	jrl	z, DisplayStr_BytecodeBlock_A_Loop3
DisplayStr_BytecodeBlock_A_Skip7:
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
	call	Display_BytecodeBlock_F_0x32D
	ld	xix, 3786
	ldw	wa, 8224
	ldw	bc, 15
	ld	(xix+), wa
	djnz16	bc, -6
	ld	xiy, Str_Control
	ld	xix, 3791
	ld	bc, 7:i3
	ldir85
	ld	a, 32:opc
	ld	(xix+), a
	call	Display_UpdateRegion5
	call	Display_BytecodeBlock_F_0x17C
	call	Display_UpdateRegion3
	ret
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_0x32D
	ld	xiy, Str_Control
	ld	xix, 3791
	ld	bc, 7:i3
	ldir85
	call	Display_UpdateRegion5
	call	Display_BytecodeBlock_F_0x17C
	call	Display_UpdateRegion3
	ret
	; Lcd text, 7 B.  Read by DisplayStr_BytecodeBlock_B (0xEFED12): `ld xiy, Str_Control`
	; copies 7 byte(s) per use (`ld bc, 7` + ldir) into the LCD text buffer
Str_Control:
	.ascii	"CONTROL"
	ld	h, (0x3723:16)
	ld	l, (0x3722:16)
	ld	h, (3829:16)
	ld	(0x90f7:16), 72
	call	PartCtrl_WriteProgramChange
	call	AccVoice_DispatchEntry
	ld	xiy, 0x34ab
	ld	xix, 3798
	ldw	bc, 13
	ldir85
	ret
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_0x32D
	ld	xiy, Str_Rhythm
	ld	xix, 3791
	ld	bc, 6:i3
	ldir85
	call	Display_UpdateRegion5
	call	DisplayStr_BytecodeBlock_B_0x63
	call	Display_UpdateRegion3
	ret
	; Lcd text, 1 B.  Read by DisplayStr_BytecodeBlock_B (0xEFED12): `ld xiy, DisplayStr_RhythmLabel`
	; also read by DisplayStr_BytecodeBlock_C
DisplayStr_RhythmLabel:
	.byte 0x20
	; Lcd text, 9 B.  Read by DisplayStr_BytecodeBlock_B (0xEFED12): `ld xiy, Str_Rhythm`
	; copies 6 byte(s) per use (`ld bc, 6` + ldir) into the LCD text buffer
Str_Rhythm:
	.ascii	"RHYTHM   "
	pushw	bc
	call	Display_BytecodeBlock_F_0x32D
	ld	xiy, DisplayStr_RhythmLabel
	push	xiy
	call	StringData_APCModeNames_0x54E
	pop	xiy
	bitda	0, (0x10f6)
	jrl	z, DisplayStr_BytecodeBlock_B_Skip
	ld	xiy, Str_MSA
DisplayStr_BytecodeBlock_B_Skip:
	ld	xix, 3791
	ld	bc, 5:i3
	ldirw
	popw	bc
	ld	xix, 3801
	call	DisplayStr_RhythmLabel_0x64
	call	Display_UpdateRegion5
	call	Display_UpdateRegion3
	ret
	; Lcd text, 10 B.  Read by DisplayStr_BytecodeBlock_B (0xEFED12): `ld xiy, Str_MSA`
	; copies 5 byte(s) per use (`ld bc, 5` + ldir) into the LCD text buffer
Str_MSA:
	.ascii	"M.S.A.    "
	pushw	bc
	call	DisplayStr_TempoString_0x74
	call	DisplayStr_ClearRegion
	popw	bc
	ld	xix, 3796
	call	DisplayStr_RhythmLabel_0x64
	call	Display_UpdateRegion3
	ret
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
	ld	a, (4483:16)
	ld	(xix), a
	ret
	; Lcd text, 12 B.  Read by DisplayStr_BytecodeBlock_B (0xEFED12): `ld xiy, Str_VarivariOff`
	; copies 4 byte(s) per use (`ld bc, 4` + ldir) into the LCD text buffer
Str_VarivariOff:
	.byte 0x56, 0x41, 0x52
	.ascii "IVARI OFF"
	call	DisplayStr_ClearRegion
	ld	xiy, DisplayStr_StyleSectionNames
	ld	xix, 3800
	xor	xwa, xwa
	ld	a, (0x3728:16)
	sla	xwa, 3
	add	xiy, xwa
	ld	bc, 4:i3
	ldirw
	ret
DisplayStr_BytecodeBlock_C:
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_0x32D
	ld	xiy, DisplayStr_RhythmLabel
	ld	xix, 3791
	ldw	bc, 9
	ldir85
	call	Display_UpdateRegion5
	call	DisplayStr_RhythmLabel_0x92
	call	Display_UpdateRegion3
	ret
	call	Display_BytecodeBlock_F_0x32D
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
	call	Display_BytecodeBlock_F_0x2A2
	call	Display_UpdateRegion3
	ret
	; Lcd text, 25 B.  Read by DisplayStr_BytecodeBlock_C (0xEFEE71): `ld xiy, Str_TempoEq`
	; reader DisplayStr_BytecodeBlock_C: `ld xiy, Str_TempoEq`
Str_TempoEq:
	.ascii	"  TEMPO  "
	.byte	0x15
	.ascii	"=              "
	; Byte data, 25 B.  Read by DisplayStr_BytecodeBlock_C (0xEFEE71): `ld xiy, DisplayStr_BytecodeBlock_C_Tbl`
	; copies 25 byte(s) per use (`ld bc, 25` + ldir) into the LCD text buffer
DisplayStr_BytecodeBlock_C_Tbl:
	.ascii	"  TEMPO  "
	.byte	0x93
	.ascii	"=              "
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_0x32D
	ld	xiy, DisplayStr_TempoString
	cpdi8	(0xfc5a), 7
	jrl	nz, DisplayStr_BytecodeBlock_C_Skip2
	cpdi8	(0xfc5b), 2
	jrl	nz, DisplayStr_BytecodeBlock_C_Skip2
	ld	xiy, DisplayStr_BytecodeBlock_C_Tbl2
DisplayStr_BytecodeBlock_C_Skip2:
	ld	xix, 3791
	ldw	bc, 25
	ldir85
	call	Display_UpdateRegion5
	call	Display_BytecodeBlock_F_0x2A2
	call	Display_UpdateRegion3
	ret
	; Lcd text, 25 B.  Read by DisplayStr_BytecodeBlock_C (0xEFEE71): `ld xiy, DisplayStr_TempoString`
	; reader DisplayStr_BytecodeBlock_C: `ld xiy, DisplayStr_TempoString`
DisplayStr_TempoString:
	.ascii	"  TEMPO  "
	.byte	0x15
	.ascii	"=              "
	; Byte data, 25 B.  Read by DisplayStr_BytecodeBlock_C (0xEFEE71): `ld xiy, DisplayStr_BytecodeBlock_C_Tbl2`
	; copies 25 byte(s) per use (`ld bc, 25` + ldir) into the LCD text buffer
DisplayStr_BytecodeBlock_C_Tbl2:
	.ascii	"  TEMPO  "
	.byte	0x93
	.ascii	"=              "
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_0x32D
	ld	xiy, DisplayStr_BytecodeBlock_C_Text
	ld	xix, 3786
	ldw	bc, 25
	ldir85
	call	Display_UpdateRegion5
	call	Display_UpdateRegion3
	call	Display_UpdateRegion4
	ret
	; Lcd text, 25 B.  Read by DisplayStr_BytecodeBlock_C (0xEFEE71): `ld xiy, DisplayStr_BytecodeBlock_C_Text`
	; copies 25 byte(s) per use (`ld bc, 25` + ldir) into the LCD text buffer
DisplayStr_BytecodeBlock_C_Text:
	.ascii	"                         "
	call	Display_UpdateRegion0
	ret
	ld	wa, (0x371a:16)
	cp	wa, 1000
	jrl	c, DisplayStr_BytecodeBlock_C_Skip3
	call	DisplayStr_FillDashes
	jp	DisplayStr_TempoString_0x9F
DisplayStr_BytecodeBlock_C_Skip3:
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	xix, 3786
	ld	wa, (xiy)
	ld	(xix), wa
	ld	a, (xiy+2)
	ld	(xix+2), a
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
	call	DisplayStr_TempoString_0x74
	ld	h, (0x3723:16)
	ld	l, (0x3722:16)
	ld	h, (3829:16)
	ld	(0x90f7:16), 72
	call	PartCtrl_WriteProgramChange
	call	AccVoice_DispatchEntry
	call	DisplayStr_ClearRegion
	ld	xiy, 0x34ab
	ld	xix, 3791
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
	djnz xbc, DisplayStr_ClearLoop
	pop xix
	popw bc
	popw wa
	ret

DisplayStr_StyleSectionInit:
	call DisplayStr_ClearRegion
	ld xiy, DisplayStr_StyleSectionNames
	ld xix, 0xece
	xor wa, wa
	ld a, (0x3728:16)
	sla wa, 3
	lda_dri XIY, 0x07, 0xf4, 0xe0
	ldw wa, 0x2020
	ld (xix+), WA
	ld (xix+), WA
	ld bc, 4:i3
	ldirw
	ld a, 0x20:opc
	ld bc, 3:i3

DisplayStr_StyleClearLoop:
	ld (xix+), a
	djnz xbc, DisplayStr_StyleClearLoop
	call Display_UpdateRegion3
	ret

DisplayStr_BytecodeBlock_E:
	ret
	ld	xix, 3796
	xor	xhl, xhl
	ld	l, (0x3728:16)
	sla	xhl, 3
	ld	xiy, DisplayStr_StyleSectionNames
	lda_rr	xiy, xiy, hl
	ld	bc, 4:i3
	ldirw
	ldw	wa, 8224
	ld	(xix+), wa
	ld	(xix+), wa
	call	Display_UpdateRegion3
	ret
	; Byte data, 105 B.  Read by DisplayStr_BytecodeBlock_B (0xEFED12): `ld xiy, DisplayStr_StyleSectionNames`
	; indexed with stride 8 (`sla xwa, 3`)
	; copies 4 byte(s) per use (`ld bc, 4` + ldir) into the LCD text buffer
	; also read by DisplayStr_BytecodeBlock_E, DisplayStr_StyleSectionInit
DisplayStr_StyleSectionNames:
	.ascii	"        START   STOP    FILL IN1FILL IN2INTRO1  COUNT INENDING1 END     REPEAT  CLEAR   ENDING2 INTRO2  "
	.byte	0x0e
	call	Display_UpdateRegion2
	ret

Display_RedrawMenu:
	ld wa, (0x371a:16)
	cp wa, 0x3e8
	jrl c, Display_RedrawMenu_Extract
	call DisplayStr_FillDashes
	jp Display_RedrawMenu_Update

Display_RedrawMenu_Extract:
	call ParamDigit_ExtractAndFormat
	ld xiy, 0x1181
	ld xix, 0xeca
	ld wa, (xiy)
	ld (xix), wa
	ld a, (xiy + 2)
	ld w, (0x371c:16)
	ld (xix + 2), wa

Display_RedrawMenu_Update:
	call Display_UpdateRegion3
	ret

Display_BytecodeBlock_F:
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_0x32D
	ld	xix, 3786
	ldw (xix+9), 22048
	call	Display_UpdateRegion5
	call	Disp_ShowNoteNameAndVelocity
	call	Disp_ShowNoteValueFields
	call	Display_UpdateRegion3
	call	Display_UpdateRegion4
	ret
	ld	xix, 3796
	ld	xiy, Display_BytecodeBlock_F_Tbl2
	ld	a, (4539:16)
	ld	xhl, Display_BytecodeBlock_F_Tbl
	ld_rr8b a, xhl, a
	exts wa
	cpdi8	(0x11bb), 23
	jrl	nz, Display_BytecodeBlock_F_Skip4
	ld	a, 17:opc
	jp	Display_BytecodeBlock_F_0x59
Display_BytecodeBlock_F_Skip4:
	cpdi8	(0x11bb), 64
	jrl	nz, Display_BytecodeBlock_F_0x59
	ld	a, 16:opc
	sla	a, 2
	exts	xwa
	add	xiy, xwa
	ld	wa, (xiy)
	ld	(xix), wa
	ld	wa, (xiy+2)
	ld	(xix+2), wa
	ld	w, (4539:16)
	ld	(0x90f7:16), w
	ld	l, (4541:16)
	ld	h, (4540:16)
	cp	w, 23
	jrl	nz, Display_BytecodeBlock_F_Skip2
	ld	xix, 3800
	ld	xiy, Str_OnOffPair
	cp	l, 127
	jrl	nz, Display_BytecodeBlock_F_Skip
	cp	h, 3:i3
	jrl	nz, Display_BytecodeBlock_F_Skip
	inc	4, xiy
Display_BytecodeBlock_F_Skip:
	ld	bc, 4:i3
	ldir85
	jp	Display_BytecodeBlock_F_0xF3
Display_BytecodeBlock_F_Skip2:
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
	call	SndParam_ApplyProgramChangeAsync
	pop	xde
	ld	xiy, 4543
	ld	xix, 3800
	cpdi8	(0x11bb), 64
	jrl	nz, Display_BytecodeBlock_F_Skip5
	cpdi8	(0x11bd), 128
	jrl	nz, Display_BytecodeBlock_F_Skip5
	cpdi8	(0x11bc), 3
	jrl	nz, Display_BytecodeBlock_F_Skip5
	ldw (xix), 17999
	ld (xix+2), 70
	jp	Display_BytecodeBlock_F_0xF3
Display_BytecodeBlock_F_Skip5:
	ldw	bc, 16
	ldir85
	ret
	; Byte data, 16 B.  Read by Display_BytecodeBlock_F (0xEFF144): `ld xhl, Display_BytecodeBlock_F_Tbl`
	; reader Display_BytecodeBlock_F: `ld xhl, Display_BytecodeBlock_F_Tbl` then `ld_rr8b a, xhl, a`
Display_BytecodeBlock_F_Tbl:
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	; Byte data, 80 B.  Read by Display_BytecodeBlock_F (0xEFF144): `ld xiy, Display_BytecodeBlock_F_Tbl2`
	; reader Display_BytecodeBlock_F: `ld xiy, Display_BytecodeBlock_F_Tbl2` then `ld_rr8b a, xhl, a`
Display_BytecodeBlock_F_Tbl2:
	.ascii	"RT1 RT2 LFT P 4 P 5 P 6 P 7 P 8 P 9 P10 P11 P12 P13 P14 P15 KBP DUALMSP ----"
	.byte	0x01, 0x02, 0x03, 0x04
	call	Display_UpdateRegion0
	call	Display_BytecodeBlock_F_0x32D
	ld	xix, 3786
	ld	(xix+4), 83
	ldw	(xix+5), 21839
	ldw	(xix+7), 17486
	call	Display_UpdateRegion5
	call	Display_BytecodeBlock_F_0x27
	call	Display_UpdateRegion3
	ret
	ld	xiy, Str_PBendModExpEq
	ld	xix, 3800
	xor	hl, hl
	ld	l, (0x3720:16)
	and	l, 7
	sla	hl, 3
	lda_rr xiy, xiy, hl
	ld wa, (xiy)
	ld	(xix), wa
	ld	wa, (xiy+2)
	ld	(xix+2), wa
	ld	wa, (xiy+4)
	ld	(xix+4), wa
	ld	w, (xiy+6)
	ld	(xix+6), w
	cp	l, 0:i3
	jrl	z, Display_BytecodeBlock_F_Return2
	cpdi8	(0x3720), 1
	jrl	nz, Display_BytecodeBlock_F_Skip6
	call	Display_BytecodeBlock_F_0x259
	jp	Display_BytecodeBlock_F_0x20A
Display_BytecodeBlock_F_Skip6:
	ld	xix, 3807
	ld	a, (0x3721:16)
	bit	7, a
	jrl	z, Display_BytecodeBlock_F_Skip8
	and	a, 127
	cp	a, 0:i3
	jrl	z, Display_BytecodeBlock_F_Skip7
	ld	xiy, Str_On2
	jp	Display_BytecodeBlock_F_0x1E7
	ld	xiy, Str_Off2
Display_BytecodeBlock_F_Skip7:
	ld	wa, (xiy)
	ld	(xix), wa
	ld	a, (xiy+2)
	ld	(xix+2), a
	jp	Display_BytecodeBlock_F_0x20A
Display_BytecodeBlock_F_Skip8:
	xor	w, w
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	wa, (xiy)
	ld	(xix), wa
	ld	a, (xiy+2)
	ld	(xix+2), a
Display_BytecodeBlock_F_Return2:
	ret
	; Lcd text, 72 B.  Read by Display_BytecodeBlock_F (0xEFF144): `ld xiy, Str_PBendModExpEq`
	; indexed with stride 8 (`sla hl, 3`)
Str_PBendModExpEq:
	.ascii	"        P.BEND= MOD.  = EXP.  = P.MEM = AFT.  =                         "
	; Lcd text, 3 B.  Read by Display_BytecodeBlock_F (0xEFF144): `ld xiy, Str_On2`
	; reader Display_BytecodeBlock_F: `ld xiy, Str_On2`
Str_On2:
	.ascii	" ON"
	; Lcd text, 3 B.  Read by Display_BytecodeBlock_F (0xEFF144): `ld xiy, Str_Off2`
	; reader Display_BytecodeBlock_F: `ld xiy, Str_Off2`
Str_Off2:
	.ascii	"OFF"
	xor	xwa, xwa
	ldb_d8	a, (0x3721)
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
	ld	wa, (3826:16)
	cpdi8	(0xfc5a), 7
	jrl	nz, Display_BytecodeBlock_F_Skip9
	cpdi8	(0xfc5b), 2
	jrl	nz, Display_BytecodeBlock_F_Skip9
	pushw	hl
	sla	wa, 1
	ld	l, 3:opc
	div	wa, l
	popw	hl
	xor	w, w
Display_BytecodeBlock_F_Skip9:
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	xix, 3802
	ld	wa, (xiy)
	ld	(xix), wa
	ld	w, (xiy+2)
	ld	(xix+2), w
	ret
	ld	xiy, Display_BytecodeBlock_F_Tbl3
	ld	xix, 3791
	cpdi8	(0xfc5a), 7
	jrl	nz, Display_BytecodeBlock_F_Skip10
	cpdi8	(0xfc5b), 2
	jrl	nz, Display_BytecodeBlock_F_Skip10
	ld	xiy, Display_BytecodeBlock_F_Tbl4
Display_BytecodeBlock_F_Skip10:
	ldw	bc, 26
	ldir85
	call	Display_BytecodeBlock_F_0x2A2
	call	Display_UpdateRegion3
	ret
	; Byte data, 19 B.  Read by Display_BytecodeBlock_F (0xEFF144): `ld xiy, Display_BytecodeBlock_F_Tbl3`
	; reader Display_BytecodeBlock_F: `ld xiy, Display_BytecodeBlock_F_Tbl3`
Display_BytecodeBlock_F_Tbl3:
	.ascii	" TEMPO   "
	.byte	0x15
	.ascii	"="
	.byte	0x09
	.ascii	"       "
	; Byte data, 19 B.  Read by Display_BytecodeBlock_F (0xEFF144): `ld xiy, Display_BytecodeBlock_F_Tbl4`
	; copies 26 byte(s) per use (`ld bc, 26` + ldir) into the LCD text buffer
Display_BytecodeBlock_F_Tbl4:
	.ascii	" TEMPO   "
	.byte	0x93
	.ascii	"="
	.byte	0x09
	.ascii	"       "
	ldw	bc, 15
	ld	xix, 0x0eca
	ldw	wa, 8224
	ld	(xix+), wa
	djnz16	bc, -6
	ret
	call	Display_UpdateRegion0
	ret
	ld	bc, 7:i3
	ld	xix, 3796
	push	xix
	ldw	wa, 8224
	ld	(xix+), wa
	djnz16	bc, -6
	pop	xix
	cpdi16	(0x0d62), 0
	jrl	z, Display_BytecodeBlock_F_Skip12
	ld	(xix+), 27
	ld	(xix+), 139
	ldw_d16	wa, (0x0d62)
	call	UIRender_DescriptorTable2
	ld	xiy, 4481
	ld	a, (xiy+)
	ld	(xix+), a
	cp	(xiy), 32
	jrl	z, Display_BytecodeBlock_F_Skip11
	ld	a, (xiy+)
	ld	(xix+), a
	cp	(xiy), 32
	jrl	z, Display_BytecodeBlock_F_Skip11
	ld	a, (xiy+)
	ld	(xix+), a
Display_BytecodeBlock_F_Skip11:
	bitda	7, (0x0d64)
	jrl	z, Display_BytecodeBlock_F_Return
	ld (xix+), 43
Display_BytecodeBlock_F_Skip12:
	bitda	7, (0x0d64)
	jrl	z, Display_BytecodeBlock_F_Return
	ld	(xix), 28
Display_BytecodeBlock_F_Return:
	ret
	ld	wa, (0x371a:16)
	cp	wa, 1000
	jrl	c, Display_BytecodeBlock_F_Skip3
	call	DisplayStr_FillDashes
	jp	Display_BytecodeBlock_F_0x3D3
Display_BytecodeBlock_F_Skip3:
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	xix, 3786
	ld	wa, (xiy)
	ld	(xix), wa
	ld	a, (xiy+2)
	ld	(xix+2), a
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
	lda_dri XIY, 0x07, 0xf4, 0xec
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
	lda_dri XIY, 0x07, 0xf4, 0xec
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
	lda_dri XIY, 0x07, 0xf4, 0xec
	ld wa, (xiy)
	ld (xix), wa
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ret

	; StringData_KeyNames: key-root names, 16 x 2 chars, read by SNS_LoadKeyAndChord (0xEFF526):
	; `ld l, (0x0d6d) / and l, 15 / sla hl, 1` then 2 bytes to (xix).  Entry 0
	; and 13-15 blank; 1-12 the chromatic scale C, D-flat, D, E-flat, E, F,
	; F-sharp, G, A-flat, A, B-flat, B with LCD glyph 0x88 = flat and
	; 0x8C = sharp (the same spellings as Tbl_KeyNamesBracketed's "Db"/"F#").
StringData_KeyNames:
	.ascii	"  C D"
	.byte	0x88
	.ascii	"D E"
	.byte	0x88
	.ascii	"E F F"
	.byte	0x8c
	.ascii	"G A"
	.byte	0x88
	.ascii	"A B"
	.byte	0x88
	.ascii	"B       "
	; 64 x 5 chars, read by SNS_LoadKeyAndChord (0xEFF526): `ld l, (0x0d6e) /
	; and l, 0x3f / ld a, 5 / muls a, l` then 5 bytes to (xix+2).  Chord-type
	; names ("7", "Maj7", "aug", "min", "m7b5" ...); 0x88 = flat, 0x8C = sharp.
Tbl_ChordTypeNames:
	.ascii	"          7    Maj7 aug  min  min7 dim  m7"
	.byte	0x88
	.ascii	"5 mM7  7sus46    aug7   "
	.byte	0x88
	.ascii	"5 7 "
	.byte	0x88
	.ascii	"5 79   7 "
	.byte	0x88
	.ascii	"9 M79  69   m6   m "
	.byte	0x88
	.ascii	"5 m79  m69  sus4 7 "
	.byte	0x8c
	.ascii	"9 M7"
	.byte	0x88
	.ascii	"5 M7"
	.byte	0x8c
	.ascii	"5 mM7"
	.byte	0x88
	.ascii	"5   139"
	.byte	0x8c
	.ascii	"5  "
	.byte	0x88
	.ascii	"9 13"
	.byte	0x8c
	.ascii	"9 13  "
	.byte	0x88
	.ascii	"13"
	.byte	0x88
	.ascii	"9"
	.byte	0x88
	.ascii	"13"
	.byte	0x8c
	.ascii	"9"
	.byte	0x88
	.ascii	"13   13  "
	.byte	0x88
	.ascii	"137 "
	.byte	0x8c
	.ascii	"11m7 11+7"
	.byte	0x8c
	.ascii	"11 add9madd9                                                                                                              "
	; 8 x 4 chars, read by SNS_LoadDurationData (0xEFF56D): `ld l, (0x0d61) /
	; sla hl, 2` then 4 bytes to 0x0EDD.  LCD note glyphs 0x13-0x16, '.' after
	; a glyph for the dotted value, "XX" in the last entry.
Tbl_NoteValueGlyphs:
	.ascii	"    "
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEFF6FD-0xEFF712 (21 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=67% dist=6 near StringData_KeyNames_0x160+4
	.byte	0x13
	.ascii	"   "
	.byte	0x14
	.ascii	".  "
	.byte	0x14
	.ascii	"   "
	.byte	0x15
	.ascii	"   "
	.byte	0x15
	.ascii	".  "
	.byte	0x16
	.ascii	"   XX  "
	; Disp_ShowNoteValueFields
	; Fills three fields of the LCD text line from three small tables:
	; 0x0ED9 <- 3 chars of Tbl_NoteValueNames[((0x3714) & 15) * 4],
	; 0x0EDD <- 5 chars of Tbl_NoteValuePlusNames[((0x3715) & 15) * 5],
	; 0x0EE3 <- 4 chars of Tbl_ArticulationNames[((0x3716) & 3) * 4]
	; ("TENU"/"NORM"/"STAC"/"CUTT").  Called after (0x3714..0x3716) change
	; (PerfMode_Evt03_ClampAndUpdate clamps (0x3716) to 0..3 then calls this).
Disp_ShowNoteValueFields:
	ld	xix, 0x0ed9
	xor	hl, hl
	ld	l, (0x3714:16)
	and	l, 15
	sla	hl, 2
	ld	xiy, Tbl_NoteValueNames
	lda_rr xiy, xiy, hl
	ld wa, (xiy)
	ld (xix+0:8), wa
	ld	w, (xiy+2)
	ld	(xix+2), w
	ld	xix, 3805
	xor	hl, hl
	ld	l, (0x3715:16)
	and	l, 15
	ld	a, 5:opc
	muls	wa, l
	ld	hl, wa
	ld	xiy, Tbl_NoteValuePlusNames
	lda_rr xiy, xiy, hl
	ld wa, (xiy+0:8)
	ld (xix+0:8), wa
	ld	wa, (xiy+2)
	ld	(xix+2), wa
	ld	a, (xiy+4)
	ld	(xix+4), a
	ld	xix, 3811
	xor	hl, hl
	ld	l, (0x3716:16)
	and	l, 3
	sla	hl, 2
	ld	xiy, Tbl_ArticulationNames
	lda_rr	xiy, xiy, hl
	ld	wa, (xiy+0:8)
	ld	(xix+0:8), wa
	ld	wa, (xiy+2)
	ld	(xix+2), wa
	ret
	; 16 x 4 chars, read by Disp_ShowNoteValueFields (0xEFF719): `ld l,
	; (0x3714) / and l, 15 / sla hl, 2`, 3 bytes copied to 0x0ED9.  Note glyphs
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
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEFF7B6-0xEFF7CC (22 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=67% dist=7 near StringData_KeyNames_0x1FE+31
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
	; 16 x 5 chars, read by Disp_ShowNoteValueFields (0xEFF719): `ld l,
	; (0x3715) / and l, 15 / ld a, 5 / muls a, l`, 5 bytes to 0x0EDD.  The
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
	; (0xEFF719): `ld l, (0x3716) / and l, 3 / sla hl, 2`, 4 bytes to 0x0EE3.
Tbl_ArticulationNames:
	.ascii	"TENUNORMSTACCUTT"
	; Disp_ShowNoteNameAndVelocity
	; 9 chars at 0x0ECF: blank when (0x3717) = 0xFF, else note name
	; Tbl_NoteNamesSharp[((0x3718) mod 12)*2] (2 chars, `divs a, 12` remainder),
	; octave Tbl_OctaveNames[((0x3718) div 12)*2] ("-2".."8"), 'V' at +5 and
	; (0x3717) in decimal at +6 -- a MIDI note number and its velocity.
Disp_ShowNoteNameAndVelocity:
	ld	xix, 0x0ecf
	cpdi8	(0x3717), 255
	jrl	nz, Disp_ShowNoteNameAndVelocity_Skip
	ldw	wa, 8224
	ld (xix+0:8), wa
	ld	(xix+2), wa
	ld	(xix+4), wa
	ld	(xix+6), wa
	ld	(xix+8), a
	jp	StringData_KeyNames_0x312
Disp_ShowNoteNameAndVelocity_Skip:
	xor	wa, wa
	ld	a, (0x3718:16)
	ld	l, 12:opc
	divs	wa, l
	ld	xiy, Tbl_NoteNamesSharp
	xor	bc, bc
	ld	c, w
	sla	bc, 1
	lda_rr xiy, xiy, bc
	ld bc, (xiy)
	ld	(xix), bc
	ld	xiy, Tbl_OctaveNames
	xor	bc, bc
	ld	c, a
	sla	bc, 1
	lda_rr xiy, xiy, bc
	ld wa, (xiy)
	ld	(xix+2), wa
	xor	wa, wa
	ld	a, (0x3717:16)
	call	ParamDigit_ExtractAndFormat
	ld	wa, (4481:16)
	ld	(xix+6), wa
	ld	a, (4483:16)
	ld	(xix+8), a
	ld	(xix+5), 86
	ret
	; 12 x 2 chars " C" "C#" " D" ... " B" (0x8C = sharp), read by
	; Disp_ShowNoteNameAndVelocity (0xEFF837): index = (0x3718) mod 12,
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
	; (0xEFF837): index = (0x3718) div 12, `sla bc, 1`, 2 bytes to 0x0ED1.
Tbl_OctaveNames:
	.ascii	"-2-10 1 2 3 4 5 6 7 8 "
	; ParamPopup_PartVolume -- LCD parameter pop-up.
	; Pop-up id 10.  "<part> VOLUME=nnn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_VolumeEq,
	; value (0x10f3) in decimal.
ParamPopup_PartVolume:
	cpdi8	(0x0def), 10
	jrl	z, ParamPopup_PartVolume_Skip
	ld	(3567:16), 10
	call	Display_UpdateRegion0
ParamPopup_PartVolume_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr	xiy, xiy, hl
	ld	xix, 0x0ed1
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_VolumeEq
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
	; "VOLUME=", 7 chars copied by ParamPopup_PartVolume (0xEFF8DA).
	; reader ParamPopup_PartVolume: `ld xiy, Str_VolumeEq` then `ld bc, 7` + ldir (7 bytes copied)
Str_VolumeEq:
	.ascii "VOLUME="
	; StringData_PartNames: 21 x 4 chars (RT1 RT2 LFT P 4 .. P15 KBP AC1 AC2 AC3 XXXX
	; DRUM), read by every ParamPopup_Part* routine: `ld l, (0x10f1) / sla hl,
	; 2 / ld xiy, StringData_PartNames / lda_rr xiy, xiy, hl / ld bc, 4 / ldir`.
StringData_PartNames:	.ascii "RT1 RT2 LFT P 4 P 5 P 6 P 7 P 8 P 9 P10 P11 P12 P13 P14 P15 KBP AC1 AC2 AC3 XXXXDRUM"
	; ParamPopup_PartPanpot -- LCD parameter pop-up.
	; Pop-up id 10.  "<part> PANPOT=nnn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_PanpotEq,
	; value (0x10f3) in decimal.
ParamPopup_PartPanpot:
	cpdi8	(0x0def), 10
	jrl	z, ParamPopup_PartPanpot_Skip
	ld	(3567:16), 10
	call	Display_UpdateRegion0
ParamPopup_PartPanpot_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
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
	; "PANPOT=", 7 chars copied by ParamPopup_PartPanpot (0xEFF98D).
	; reader ParamPopup_PartPanpot: `ld xiy, Str_PanpotEq` then `ld bc, 7` + ldir (7 bytes copied)
Str_PanpotEq:
	.ascii	"PANPOT="
	; ParamPopup_PartKeyShift -- LCD parameter pop-up.
	; Pop-up id 10.  "<part> KEY SHIFT=snn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_KeyShiftEq,
	; value (0x10f3) formatted by ParamDigit_CalrData with DE = 64, then the
	; byte at 0x1180 and three digits from 0x1181.
ParamPopup_PartKeyShift:
	cpdi8	(0x0def), 10
	jrl	z, ParamPopup_PartKeyShift_Skip
	ld	(3567:16), 10
	call	Display_UpdateRegion0
ParamPopup_PartKeyShift_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
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
	; "KEY SHIFT=", 10 chars copied by ParamPopup_PartKeyShift (0xEFF9EC).
	; reader ParamPopup_PartKeyShift: `ld xiy, Str_KeyShiftEq` then `ld bc, 10` + ldir (10 bytes copied)
Str_KeyShiftEq:
	.ascii	"KEY SHIFT="
	; ParamPopup_PartTuning -- LCD parameter pop-up.
	; Pop-up id 10.  "<part> TUNING=snn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_TuningEq,
	; value (0x10f3) formatted by ParamDigit_CalrData with DE = 128, then the
	; byte at 0x1180 and three digits from 0x1181.
ParamPopup_PartTuning:
	cpdi8	(0x0def), 10
	jrl	z, ParamPopup_PartTuning_Skip
	ld	(3567:16), 10
	call	Display_UpdateRegion0
ParamPopup_PartTuning_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
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
	; "TUNING=", 7 chars copied by ParamPopup_PartTuning (0xEFFA59).  The 64
	; bytes after it (US1 US2 US3 BAS P 8 ..) are 4-char part names of a
	; second naming scheme with no reader found by name or 32-bit value.
Str_TuningEq:
	.ascii "TUNING=US1 US2 US3 BAS P 8 P 9 P10 LS1 LS2 LS3 P11 P12 P13 P14 P15 KBP "
	; ParamPopup_PartBendSense -- LCD parameter pop-up.
	; Pop-up id 10.  "<part> BEND SENS=nn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_BendSensEq,
	; value (0x10f3), two digits (copied from 0x1182).
ParamPopup_PartBendSense:
	cpdi8	(0x0def), 10
	jrl	z, ParamPopup_PartBendSense_Skip
	ld	(3567:16), 10
	call	Display_UpdateRegion0
ParamPopup_PartBendSense_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr	xiy, xiy, hl
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
	; "BEND SENS=", 10 chars copied by ParamPopup_PartBendSense (0xEFFB02).
	; reader ParamPopup_PartBendSense: `ld xiy, Str_BendSensEq` then `ld bc, 10` + ldir (10 bytes copied)
Str_BendSensEq:
	.ascii "BEND SENS="
	; ParamPopup_PartSustain -- LCD parameter pop-up.
	; Pop-up id 1.  "<part> SUSTAIN ON /OFF ": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_Sustain,
	; then Str_OnOffPair + 0 when bit 3 of (0x10f3) is set, + 4 when clear.
ParamPopup_PartSustain:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_PartSustain_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartSustain_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3791
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_Sustain
	inc	1, xix
	ldw	bc, 8
	ldir85
	xor	hl, hl
	bitda	3, (0x10f3)
	jrl	nz, ParamPopup_PartSustain_Skip2
	ld	l, 4:opc
ParamPopup_PartSustain_Skip2:
	ld	xiy, Str_OnOffPair
	lda_rr	xiy, xiy, hl
	ld	bc, 4:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "SUSTAIN ", 8 chars copied by ParamPopup_PartSustain (0xEFFB65).
	; reader ParamPopup_PartSustain: `ld xiy, Str_Sustain` then `ld bc, 8` + ldir (8 bytes copied)
Str_Sustain:
	.ascii	"SUSTAIN "
	; 2 x 4 chars "ON  " / "OFF ": +0 or +4 selected by a flag bit and 3 or 4
	; bytes copied, by ParamPopup_PartSustain/Effect/Tremolo/TotalReverb,
	; ParamPopup_PartDspEffectOff and Display_BytecodeBlock_F (0xEFF144).
Str_OnOffPair:
	.ascii	"ON  OFF "
	; ParamPopup_PartDspEffectOff -- LCD parameter pop-up.
	; Pop-up id 1.  "<part> DSP EFFECT OFF ": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_DspEffect,
	; then Str_OnOffPair + 4 unconditionally (`ld l, 4`).
ParamPopup_PartDspEffectOff:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_PartDspEffectOff_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartDspEffectOff_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
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
	lda_rr	xiy, xiy, hl
	ld	bc, 4:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "DSP EFFECT ", 11 chars copied by ParamPopup_PartDspEffectOff (0xEFFBD0).
	; reader ParamPopup_PartDspEffectOff: `ld xiy, Str_DspEffect` then `ld bc, 11` + ldir (11 bytes copied)
Str_DspEffect:
	.ascii	"DSP EFFECT "
	; ParamPopup_PartEffect -- LCD parameter pop-up.
	; Pop-up id 1.  "<part> EFFECT ON /OFF ": part name = StringData_PartNames[(0x10f1)*4], 4 chars, StringData_EffectLabel,
	; then Str_OnOffPair + 0 when bit 6 of (0x10f3) is set, + 4 when clear.
ParamPopup_PartEffect:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_PartEffect_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartEffect_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3791
	ld	bc, 4:i3
	ldir85
	ld	xiy, StringData_EffectLabel
	inc	1, xix
	ld	bc, 7:i3
	ldir85
	xor	hl, hl
	bitda	6, (0x10f3)
	jrl	nz, ParamPopup_PartEffect_Skip2
	ld	l, 4:opc
ParamPopup_PartEffect_Skip2:
	ld	xiy, Str_OnOffPair
	lda_rr	xiy, xiy, hl
	ld	bc, 4:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; StringData_EffectLabel: "EFFECT ", 7 chars copied by
	; ParamPopup_PartEffect (0xEFFC2F).
StringData_EffectLabel:	.ascii "EFFECT "
	; ParamPopup_PartDspEffectLevel -- LCD parameter pop-up.
	; Pop-up id 1.  "<part> DSP EFFECT=nnn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_DspEffectEq,
	; value (0x10f3) in decimal.
ParamPopup_PartDspEffectLevel:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_PartDspEffectLevel_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartDspEffectLevel_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
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
	; "DSP EFFECT=", 11 chars copied by ParamPopup_PartDspEffectLevel (0xEFFC90).
	; reader ParamPopup_PartDspEffectLevel: `ld xiy, Str_DspEffectEq` then `ld bc, 11` + ldir (11 bytes copied)
Str_DspEffectEq:
	.ascii	"DSP EFFECT="
	; ParamPopup_PartReverb -- LCD parameter pop-up.
	; Pop-up id 1.  "<part> REVERB=nnn": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_ReverbEq,
	; value (0x10f3) in decimal.
ParamPopup_PartReverb:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_PartReverb_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartReverb_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
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
	; "REVERB=", 7 chars copied by ParamPopup_PartReverb (0xEFFCF0).
	; reader ParamPopup_PartReverb: `ld xiy, Str_ReverbEq` then `ld bc, 7` + ldir (7 bytes copied)
Str_ReverbEq:
	.ascii	"REVERB="
	; ParamPopup_PanelMemory -- LCD parameter pop-up.
	; Pop-up id 1.  "PANEL MEMORY=b-n" from A on entry: A-1 divided by 8
	; gives bank = quotient+1 -> (0x11f2) and number = remainder+1 -> (0x11f3),
	; each printed in decimal with '-' (45) between them.
ParamPopup_PanelMemory:
	cpdi8	(0x0def), 1
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
	; "PANEL MEMORY=", 13 chars copied by ParamPopup_PanelMemory (0xEFFD4B).
	; reader ParamPopup_PanelMemory: `ld xiy, Str_PanelMemoryEq` then `ld bc, 13` + ldir (13 bytes copied)
Str_PanelMemoryEq:
	.ascii "PANEL MEMORY="
	; ParamPopup_FadeIn -- LCD parameter pop-up.
	; Pop-up id 1.  Str_FadeIn then Str_On or Str_Off (3 chars) chosen from
	; A on entry (0 / 1).
ParamPopup_FadeIn:
	cpdi8	(0x0def), 1
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
	jp	StringData_EffectLabel_0x176
ParamPopup_FadeIn_Skip:
	ld	xiy, Str_Off
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "FADE-IN ", 8 chars copied by ParamPopup_FadeIn (0xEFFDC1).
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
	cpdi8	(0x0def), 1
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
	jp	StringData_EffectLabel_0x1CB
ParamPopup_FadeOut_Skip2:
	ld	xiy, Str_Off
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "FADE-OUT ", 9 chars copied by ParamPopup_FadeOut (0xEFFE16).
	; reader ParamPopup_FadeOut: `ld xiy, Str_FadeOut` then `ld bc, 9` + ldir (9 bytes copied)
Str_FadeOut:
	.ascii "FADE-OUT "
	; ParamPopup_ApcMode -- LCD parameter pop-up.
	; Pop-up id 1.  16 chars of StringData_APCModeNames[(W and A) * 16] at 0x0ECF.
ParamPopup_ApcMode:
	cpdi8	(0x0def), 1
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
	lda_rr	xiy, xiy, hl
	ld	xix, 0x0ecf
	ldw	bc, 16
	ldir85
	call	Display_UpdateRegion3
	ret
	; StringData_APCModeNames: APC mode names, 9 x 16 chars (APC OFF,
	; BASIC, ADVANCED 1, PIANIST, PIANO MODE, ADVANCED 2, -, -, SPLIT), read
	; by ParamPopup_ApcMode (0xEFFE66): `sla hl, 4 / lda_rr / ld bc, 16 / ldir`.
StringData_APCModeNames:	.ascii "APC OFF         BASIC           ADVANCED 1      PIANIST         PIANO MODE      ADVANCED 2                                      SPLIT           "
	; ParamPopup_ApcMemory -- LCD parameter pop-up.
	; Pop-up id 1.  Str_ApcMemoryOn (14 chars at 0x0ECF); Str_OffAccomp
	; ("OFF") over the "ON " at 0x0EDA when (A and W) = 0.
ParamPopup_ApcMemory:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_ApcMemory_Skip
	ld	(3567:16), 1
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
	ld	xix, 3791
	ldw	bc, 14
	ldir85
	and	a, w
	jrl	nz, ParamPopup_ApcMemory_Skip2
	ld	xiy, Str_OffAccomp
	ld	xix, 3802
	ld	bc, 3:i3
	ldir85
ParamPopup_ApcMemory_Skip2:
	call	Display_UpdateRegion3
	ret
	; "APC MEMORY ON ", 14 chars copied by ParamPopup_ApcMemory (0xEFFF31).
	; reader ParamPopup_ApcMemory: `ld xiy, Str_ApcMemoryOn` then `ld bc, 14` + ldir (14 bytes copied)
Str_ApcMemoryOn:
	.ascii	"APC MEMORY ON "
	; ParamPopup_AccompPart -- LCD parameter pop-up.
	; Pop-up id 1.  A and W are reduced to their bits 7-5 (`and 224 / srl 5`);
	; 16 bytes of Tbl_AccompPartNames + A*16 go to 0x0ECF, and "OFF" to
	; 0x0EDC when (A and W) = 0.
ParamPopup_AccompPart:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_AccompPart_Skip
	ld	(3567:16), 1
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
	lda_rr xiy, xiy, hl
	ld xix, 3791
	ldw	bc, 16
	ldir85
	inc	1, xix
	and	a, w
	jrl	nz, ParamPopup_AccompPart_Skip2
	ld	xiy, Str_OffAccomp
	ld	xix, 3804
	ld	bc, 3:i3
	ldir85
ParamPopup_AccompPart_Skip2:
	call	Display_UpdateRegion3
	ret
	; 52 bytes read by ParamPopup_AccompPart (0xEFFF88): 16 bytes at +k*16,
	; k = bits 7-5 of A (`sla hl, 4 / lda_rr / ld bc, 16 / ldir` to 0x0ECF).
	; Content: 0x09 0x09 "ACCOMP PART1 ON ", "ACCOMP PART2 ON ", 0x09 0x09
	; "ACCOMP PART3 ON " -- the visible strings do NOT fall on the reader's
	; 16-byte boundaries, and the role of the 0x09 bytes is not established.
	; The values 0xF00001-0xF00004 (inside this text) are also loaded as
	; StringData_APCModeNames_0x160..0x163 by ui/drawbar_panel_ui.s's Softver
	; screen and handed to SendEvent -- more likely numeric event arguments
	; than pointers here (not verified).
Tbl_AccompPartNames:
	.byte	0x09, 0x09
	.ascii	"ACCOMP PART1 ON ACCOMP PART2 "
	.ascii	"O"
	.ascii	"N"
	.ascii	" "
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
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_DynamicAccomp_Skip
	ld	(3567:16), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
ParamPopup_DynamicAccomp_Skip:
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	xiy, Str_DynamicAccompOn
	ld	xix, 3791
	ldw	bc, 17
	ldir85
	and	w, a
	jrl	nz, ParamPopup_DynamicAccomp_Skip2
	ld	xiy, Str_OffAccomp
	ld	xix, 3806
	ld	bc, 3:i3
	ldir85
ParamPopup_DynamicAccomp_Skip2:
	call	Display_UpdateRegion3
	ret
	; "DYNAMIC ACCOMP ON ", 17 chars copied by ParamPopup_DynamicAccomp (0xF00019).
	; reader ParamPopup_DynamicAccomp: `ld xiy, Str_DynamicAccompOn` then `ld bc, 17` + ldir (17 bytes copied)
Str_DynamicAccompOn:
	.ascii "DYNAMIC ACCOMP ON "
	; ParamPopup_TechniChord -- LCD parameter pop-up.
	; Pop-up id 1.  Str_TechniChordOn (16 chars); "OFF" at 0x0EDC when
	; (W and A) = 0.
ParamPopup_TechniChord:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_TechniChord_Skip
	ld	(3567:16), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
ParamPopup_TechniChord_Skip:
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	xiy, Str_TechniChordOn
	ld	xix, 3791
	ldw	bc, 16
	ldir85
	and	w, a
	jrl	nz, ParamPopup_TechniChord_Skip2
	ld	xiy, Str_OffAccomp
	ld	xix, 3804
	ld	bc, 3:i3
	ldir85
ParamPopup_TechniChord_Skip2:
	call	Display_UpdateRegion3
	ret
	; "TECHNI-CHORD ON ", 16 chars copied by ParamPopup_TechniChord (0xF0006B).
	; reader ParamPopup_TechniChord: `ld xiy, Str_TechniChordOn` then `ld bc, 16` + ldir (16 bytes copied)
Str_TechniChordOn:
	.ascii "TECHNI-CHORD ON "
	ret
	; ParamPopup_KeyNameBracketed -- LCD parameter pop-up.
	; Pop-up id 1.  ' ' at 0x0ECE, then 4 chars of Tbl_KeyNamesBracketed
	; [((0x10f3) & 15) * 4] ("<G >", "<Ab>" ...), read as two words.
ParamPopup_KeyNameBracketed:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_KeyNameBracketed_Skip
	ld	(3567:16), 1
	pushw	wa
	call	Display_UpdateRegion0
	popw	wa
ParamPopup_KeyNameBracketed_Skip:
	pushw	wa
	call	DisplayStr_ClearRegion
	popw	wa
	ld	(3790:16), 32
	ld	xix, 3791
	ld	l, (4339:16)
	and	l, 15
	xor	h, h
	sla	hl, 2
	ld	xiy, Tbl_KeyNamesBracketed
	ld_rrw wa, xiy, hl
	ld (xix), wa
	add	hl, 2
	add	xix, 2
	ld_rrw wa, xiy, hl
	ld (xix), wa
	call	Display_UpdateRegion3
	ret
	; 16 x 4 chars "<G >" "<Ab>" .. "<F#>" then 4 blank entries, read by
	; ParamPopup_KeyNameBracketed (0xF000BC): `ld l, (0x10f3) / and l, 15 /
	; sla hl, 2 / ld_rrw wa, xiy, hl` twice.
Tbl_KeyNamesBracketed:
	.ascii "<G ><Ab><A ><Bb><B ><C ><Db><D ><Eb><E ><F ><F#>                "
	; ParamPopup_AccompVolume -- LCD parameter pop-up.
	; Pop-up id 1.  16 chars of Tbl_AccompVolumeLabels[HL * 16] (HL on entry
	; selects ACC. TOTAL / BASS / DRUMS / ACCMP1..3); then, when bit 7 of
	; (0x10f5) is set, 8 chars of Tbl_MuteOnOff (+0 "MUTE ON ", +8 when bit 7
	; of (0x10f3) is clear), else A (on entry) in decimal at 0x0EDF.
ParamPopup_AccompVolume:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_AccompVolume_Skip
	ld	(3567:16), 1
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
	lda_rr xiy, xiy, hl
	ld xix, 3791
	ldw	bc, 16
	ldir85
	popw	wa
	bitda	7, (0x10f5)
	jrl	z, ParamPopup_AccompVolume_Skip3
	ld	xiy, Tbl_MuteOnOff
	bitda	7, (0x10f3)
	jrl	nz, ParamPopup_AccompVolume_Skip2
	add	xiy, 8
ParamPopup_AccompVolume_Skip2:
	ld	xix, 3806
	ldw	bc, 8
	ldir85
	jp	StringData_APCModeNames_0x31F
ParamPopup_AccompVolume_Skip3:
	xor	w, w
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	xix, 3807
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; 6 x 16 chars (ACC. TOTAL VOL.= / BASS / DRUMS / ACCMP1 / ACCMP2 / ACCMP3
	; VOLUME =), read by ParamPopup_AccompVolume (0xF0014D): `sla hl, 4 /
	; lda_rr / ld bc, 16 / ldir`.
Tbl_AccompVolumeLabels:
	.ascii	"ACC. TOTAL VOL.=   BASS VOLUME =  DRUMS VOLUME = ACCMP1 VOLUME = ACCMP2 VOLUME = ACCMP3 VOLUME ="
	; 2 x 8 chars "MUTE ON " / "MUTE OFF", read by ParamPopup_AccompVolume
	; (0xF0014D): +8 when bit 7 of (0x10f3) is clear, 8 bytes copied.
Tbl_MuteOnOff:
	.ascii	"MUTE ON MUTE OFF"
	ret
	; ParamPopup_PartTremolo -- LCD parameter pop-up.
	; Pop-up id 1.  "<part> TREMOLO ON/OFF": part name = StringData_PartNames[(0x10f1)*4], 4 chars, Str_Tremolo,
	; then 3 chars of Str_OnOffPair + 0 (bit 7 of (0x10f3) set) or + 4.
ParamPopup_PartTremolo:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_PartTremolo_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartTremolo_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3791
	ld	bc, 4:i3
	ldir85
	ld	xiy, Str_Tremolo
	inc	1, xix
	ldw	bc, 8
	ldir85
	xor	hl, hl
	bitda	7, (0x10f3)
	jrl	nz, ParamPopup_PartTremolo_Skip2
	ld	l, 4:opc
ParamPopup_PartTremolo_Skip2:
	ld	xiy, Str_OnOffPair
	lda_rr	xiy, xiy, hl
	ld	bc, 3:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "TREMOLO ", 8 chars copied by ParamPopup_PartTremolo (0xF00236).
	; reader ParamPopup_PartTremolo: `ld xiy, Str_Tremolo` then `ld bc, 8` + ldir (8 bytes copied)
Str_Tremolo:
	.ascii "TREMOLO "
	ret
	ret
	ret
	ret
	; "EXT.TAB EFFECT:" + "EN  " + "DIS " (23 bytes).  No reader found: no
	; name at this address and no 24/32-bit value 0xF0029D anywhere in the
	; ROM; the text sits where the three `ret` stubs 0xF00299-0xF0029C end.
Str_ExtTabEffectEnDis:
	.ascii "EXT.TAB EFFECT:EN  DIS "
	ret
	; ParamPopup_TotalReverb -- LCD parameter pop-up.
	; Pop-up id 1.  Str_TotalReverb (13 chars at 0x0ED1), then 4 chars of
	; Str_OnOffPair + 0 (bit 7 of (0x10f3) set) or + 4.
ParamPopup_TotalReverb:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_TotalReverb_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_TotalReverb_Skip:
	call	DisplayStr_ClearRegion
	ld	xix, 3793
	ld	xiy, Str_TotalReverb
	ldw	bc, 13
	ldir85
	xor	hl, hl
	bitda	7, (0x10f3)
	jrl	nz, ParamPopup_TotalReverb_Skip2
	ld	l, 4:opc
ParamPopup_TotalReverb_Skip2:
	ld	xiy, Str_OnOffPair
	lda_rr	xiy, xiy, hl
	ld	bc, 4:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "TOTAL REVERB ", 13 chars copied by ParamPopup_TotalReverb (0xF002B5).
	; reader ParamPopup_TotalReverb: `ld xiy, Str_TotalReverb` then `ld bc, 13` + ldir (13 bytes copied)
Str_TotalReverb:
	.ascii	"TOTAL REVERB "
	ret
	; ParamPopup_PartTimbre -- LCD parameter pop-up.
	; Pop-up id 1.  part name = StringData_PartNames[(0x10f1)*4], 4 chars at 0x0ED1, then 6 chars of
	; Tbl_TimbreNames[((0x10f3) >> 6) * 6] (NORMAL/BRIGHT/MELLOW/WARM).
ParamPopup_PartTimbre:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_PartTimbre_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartTimbre_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3793
	ld	bc, 4:i3
	ldir85
	inc	1, xix
	ld	l, (4339:16)
	and	l, 192
	srl	l, 6
	ld	h, l
	sla	h, 1
	sla	l, 2
	add	l, h
	xor	h, h
	ld	xiy, Tbl_TimbreNames
	lda_rr	xiy, xiy, hl
	ld	bc, 6:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; 4 x 6 chars NORMAL / BRIGHT / MELLOW / WARM, read by ParamPopup_PartTimbre
	; (0xF00305): index ((0x10f3) >> 6) times 6 (`sla h,1 / sla l,2 / add l,h`).
Tbl_TimbreNames:
	.ascii "NORMALBRIGHTMELLOWWARM  "
	; ParamPopup_Msa -- LCD parameter pop-up.
	; Pop-up id 15 when (0x0d65) = 3, else 1.  Str_Msa (7 chars at 0x0ED1),
	; then 4 chars of Tbl_MsaStates[((0x10f3) & 7) * 4] (OFF/ON/#2/#3).
ParamPopup_Msa:
	cpdi8	(0x0d65), 3
	jrl	nz, ParamPopup_Msa_Skip
	cpdi8	(0x0def), 15
	jrl	z, StringData_APCModeNames_0x506
	ld	(3567:16), 15
	call	Display_UpdateRegion0
	jp	StringData_APCModeNames_0x506
ParamPopup_Msa_Skip:
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_Msa_Skip2
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_Msa_Skip2:
	call	DisplayStr_ClearRegion
	ld	xiy, Str_Msa
	ld	xix, 3793
	ld	bc, 7:i3
	ldir85
	ld	l, (4339:16)
	xor	h, h
	and	l, 7
	sla	hl, 2
	ld	xiy, Tbl_MsaStates
	lda_rr	xiy, xiy, hl
	ld	bc, 4:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; "M.S.A. ", 7 chars copied by ParamPopup_Msa (0xF00379).
	; reader ParamPopup_Msa: `ld xiy, Str_Msa` then `ld bc, 7` + ldir (7 bytes copied)
Str_Msa:
	.ascii	"M.S.A. "
	; 4 x 4 chars OFF / ON / #2 / #3, read by ParamPopup_Msa (0xF00379):
	; `ld l, (0x10f3) / and l, 7 / sla hl, 2`, 4 bytes copied.
Tbl_MsaStates:
	.ascii	"OFF ON  #2  #3  "
	push	xiz
	ldda32	xiz, (0x10fd)
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
	call	VoiceSlot_CompareAndBranch_0x7
	call	MemConfig_VoiceSlotLookup
	ld	(4342:16), 0
	call	VoiceSlot_ReadCurrentParams
	cp	a, 129
	jrl	nz, ParamPopup_Msa_Skip4
ParamPopup_Msa_Loop:
	call	VoiceSlot_DispatchRet
	cp	w, 255
	jrl	z, ParamPopup_Msa_Skip5
	call	VoiceSlot_ComputeWordIndex
	push	xhl
	ld	xhl, 3230
	ld_rrw	ix, xhl, iz
	sra	iz, 1
	ld	xhl, 3262
	ld_rrb a, xhl, iz
	pop xhl
	push	xhl
	ld	xhl, 3583
	add	xhl, 40
	cp	ix, (xhl)
	pop	xhl
	jrl	nz, ParamPopup_Msa_Skip3
	push	xhl
	ld	xhl, 3583
	add xhl,(0x2a:8)	; add XHL,(0x2a)
	cp	a, (xhl)
	pop	xhl
	jrl	nc, ParamPopup_Msa_Skip5
ParamPopup_Msa_Skip3:
	call	VoiceSlot_ReadCurrentParams
ParamPopup_Msa_Skip4:
	and	a, 240
	cp	a, 176
	jrl	nz, ParamPopup_Msa_Loop
	call	StringData_APCModeNames_0x5F5
	jp	StringData_APCModeNames_0x57E
ParamPopup_Msa_Skip5:
	ld	a, 5:opc
	call	VoiceSlot_RestoreState
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	pop_lerp 56
	push	xiz
	ldto_lerp xiz, 56
	ld (4349:16), xiz
	pop xiz
	ret
	call	VoiceSlot_ComputeWordIndex
	push	xhl
	ld	xhl, 3230
	ld_rrw ix, xhl, iz
	ld (10431:16), ix
	sra	iz, 1
	ld	xhl, 3262
	ld_rrb a, xhl, iz
	pop xhl
	xor	w, w
	ld	(0x28c1:16), wa
	call	VoiceBank_ProcessCommand
	ld	a, (3765:16)
	and	a, 240
	cp	a, 176
	jrl	z, ParamPopup_Msa_Skip6
ParamPopup_Msa_Loop2:
	jp	ParamPopup_PartPedal
ParamPopup_Msa_Skip6:
	ld	a, (3765:16)
	and	a, 4
	rrc_i_8 a, 3	; rrc 0x03,A  (llvm-mc: rrc	a does not round-trip)
	ld	w, (3767:16)
	and	w, 127
	or	a, w
	cp	a, 152
	jrl	nz, ParamPopup_Msa_Loop2
	cpdi8	(0x0eb8), 3
	jrl	nz, ParamPopup_Msa_Loop2
	bitda	0, (0x0eba)
	jrl	z, ParamPopup_Msa_Loop2
	ld	a, (3769:16)
	and	a, 1
	ld	(4342:16), a
	; ParamPopup_PartPedal -- LCD parameter pop-up.
	; Pop-up id 1.  Part name of (0x10f2) at 0x0ED1, then 10 chars of
	; Tbl_PedalNames[((0x10f1) - 181) * 10] (SUSTAIN/SOFT PEDAL/SOSTENUTE);
	; the value (0x10f3) in decimal when (0x10f1) = 181.
ParamPopup_PartPedal:
	ret
	cpdi8	(0x0def), 1
	jrl	z, ParamPopup_PartPedal_Skip
	ld	(3567:16), 1
	call	Display_UpdateRegion0
ParamPopup_PartPedal_Skip:
	call	DisplayStr_ClearRegion
	ld	l, (4338:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3793
	ld	bc, 4:i3
	ldir85
	xor	hl, hl
	ld	l, (4337:16)
	sub	l, 181
	mul	l, 10
	ld	xiy, Tbl_PedalNames
	lda_rr	xiy, xiy, hl
	ldw	bc, 10
	ldir85
	inc	1, xix
	cpdi8	(0x10f1), 181
	jrl	nz, ParamPopup_PartPedal_Skip2
	xor	wa, wa
	ld	a, (4339:16)
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ld	xiy, 4481
	ld	bc, 3:i3
	ldir85
	jp	StringData_APCModeNames_0x6F0
ParamPopup_PartPedal_Skip2:
	ld	c, (4339:16)
	xor	hl, hl
	cp	c, 64
	jrl	nc, ParamPopup_PartPedal_Skip3
	ld	hl, 4:i3
ParamPopup_PartPedal_Skip3:
	ld	xiy, Str_OnOffPair
	lda_rr	xiy, xiy, hl
	ld	bc, 4:i3
	ldir85
	call	Display_UpdateRegion3
	ret
	; 3 x 10 chars " SUSTAIN  " / "SOFT PEDAL" / "SOSTENUTE ", read by
	; ParamPopup_PartPedal (0xF00505): index ((0x10f1) - 181) times 10.
Tbl_PedalNames:
	.ascii	" SUSTAIN  SOFT PEDALSOSTENUTE "
	call	StringData_APCModeNames_0x9D6
	cp	l, 0:i3
	jrl	z, ParamPopup_PartPedal_Skip5
	ld	a, (3765:16)
	cp	a, 129
	jrl	z, ParamPopup_PartPedal_Skip4
	call	DisplayStr_BytecodeBlock_A_0xCD
	ld	(3952:16), 48
	ldw	(3778:16), 0
	jp	StringData_APCModeNames_0x9B1
ParamPopup_PartPedal_Skip4:
	call	DisplayStr_BytecodeBlock_A
	xor	wa, wa
	ld	(3952:16), a
	ld	(3778:16), wa
	jp	StringData_APCModeNames_0x9AD
ParamPopup_PartPedal_Skip5:
	ld	a, (4463:16)
	ld	(3952:16), a
	ld	a, (4462:16)
	and	a, 240
	cp	a, 144
	jrl	z, ParamPopup_PartPedal_Skip7
	cpdi8	(0x0eb5), 129
	jrl	z, ParamPopup_PartPedal_Skip6
	call	DisplayStr_BytecodeBlock_A_0xCD
	ldw	(3778:16), 0
	ld	(3952:16), 48
	jp	StringData_APCModeNames_0x9B1
ParamPopup_PartPedal_Skip6:
	call	DisplayStr_BytecodeBlock_A
	xor	wa, wa
	ld	(3778:16), wa
	ld	(3952:16), a
	jp	StringData_APCModeNames_0x9AD
ParamPopup_PartPedal_Skip7:
	call	StringData_APCModeNames_0x9C1
	ld	a, (4463:16)
	exts	wa
	add (3778:16), wa
	xor h, h
	ld	l, 96:opc
	cpdi8	(0x0eb5), 129
	jrl	z, ParamPopup_PartPedal_Skip8
	ld	l, 48:opc
ParamPopup_PartPedal_Skip8:
	ld	wa, (4468:16)
	ldw	bc, 96
	muls	xwa, bc
	ld	de, qwa
	add	hl, wa
	ld	(4470:16), hl
	ld	wa, (3778:16)
	cp	wa, hl
	jrl	ugt, ParamPopup_PartPedal_Skip10
	jrl	c, ParamPopup_PartPedal_Skip14
	cpdi8	(0x0eb5), 129
	jrl	nz, ParamPopup_PartPedal_Skip9
	call	DisplayStr_BytecodeBlock_A_0x53
	ld	(3952:16), 0
	ldw	(3778:16), 0
	jp	StringData_APCModeNames_0x9AD
ParamPopup_PartPedal_Skip9:
	call	DisplayStr_BytecodeBlock_A_0x120
	ld	(3952:16), 48
	ldw	(3778:16), 0
	jp	StringData_APCModeNames_0x9B1
ParamPopup_PartPedal_Skip10:
	sub	wa, hl
	ld	(3778:16), wa
	cp	wa, 96
	jrl	c, ParamPopup_PartPedal_Skip11
	xor	de, de
	xor	b, b
	ld	c, 96:opc
	ld	qwa, de
	div	xwa, bc
	ld de, qwa
	ld bc, wa
	ldw	hl, 96
	muls	xwa, hl
	ld	de, qwa
	ld	de, (3778:16)
	sub	de, wa
	ld	(3778:16), de
	ldw	(3952:16), 0
	pushw	bc
	call	DisplayStr_BytecodeBlock_A_0x53
	popw	bc
	pushw	bc
	call	VoiceBank_ProcessCommand
	popw	bc
	pushw	bc
	call	DisplayStr_BytecodeBlock_A_0x53
	popw	bc
	cpdi8	(0x0ef6), 0
	jrl	nz, ParamPopup_PartPedal_Return
	djnz16	bc, -23
	cpdi16	(0x0ec2), 48
	jrl	nz, StringData_APCModeNames_0x9AD
	call	DisplayStr_BytecodeBlock_A_0x120
	jp	StringData_APCModeNames_0x9AD
ParamPopup_PartPedal_Skip11:
	call	DisplayStr_BytecodeBlock_A_0x120
	call	DisplayStr_BytecodeBlock_A_0x1A4
	cpdi8	(0x0ebb), 129
	jrl	nz, ParamPopup_PartPedal_Skip12
	call	DisplayStr_BytecodeBlock_A_0x53
	ld	(3952:16), 48
	ldw	(3778:16), 0
	jp	StringData_APCModeNames_0x9AD
ParamPopup_PartPedal_Skip12:
	cpdi8	(0x0ebb), 132
	jrl	nz, ParamPopup_PartPedal_Entry
	call	StringData_APCModeNames_0x9B2
	jp	StringData_APCModeNames_0x9AD
ParamPopup_PartPedal_Entry:
	cpdi8	(0x0ebc), 0
	jrl	nz, ParamPopup_PartPedal_Skip13
	call	DisplayStr_BytecodeBlock_A_0xCD
	xor	wa, wa
	ld	(3952:16), 0
	ld	(3778:16), wa
	jp	StringData_APCModeNames_0x9AD
ParamPopup_PartPedal_Skip13:
	call	DisplayStr_BytecodeBlock_A_0x53
	ld	(3952:16), 48
	ldw	(3778:16), 0
	jp	StringData_APCModeNames_0x9AD
ParamPopup_PartPedal_Skip14:
	sub	hl, wa
	cp	hl, 96
	jrl	c, ParamPopup_PartPedal_Entry2
	cpdi8	(0x0eb5), 129
	jrl	z, ParamPopup_PartPedal_Skip15
	call	DisplayStr_BytecodeBlock_A_0xCD
	ld	(3952:16), 48
	ldw	(3778:16), 0
	jp	StringData_APCModeNames_0x9B1
ParamPopup_PartPedal_Skip15:
	ld	wa, hl
	ld	l, 96:opc
	div	wa, l
	ld	(3952:16), w
	cpdi8	(0x116e), 129
	jrl	z, ParamPopup_PartPedal_Skip16
	pushw	wa
	call	DisplayStr_BytecodeBlock_A_0x1A4
	popw	wa
	cp	w, 48
	jrl	nz, ParamPopup_PartPedal_Skip16
	pushw	wa
	call	DisplayStr_BytecodeBlock_A_0x120
	popw	wa
	cpdi8	(0x0ebb), 129
	jrl	z, ParamPopup_PartPedal_Skip18
	cpdi8	(0x0ebc), 48
	jrl	z, ParamPopup_PartPedal_Skip18
ParamPopup_PartPedal_Skip16:
	cp	w, 48
	jrl	z, ParamPopup_PartPedal_Skip17
	jp	StringData_APCModeNames_0x928
	cp	a, 1:i3
	jrl	z, ParamPopup_PartPedal_Skip18
ParamPopup_PartPedal_Skip17:
	call	DisplayStr_BytecodeBlock_A_0xCD
	jp	StringData_APCModeNames_0x92C
ParamPopup_PartPedal_Skip18:
	call	DisplayStr_BytecodeBlock_A
	ldw	(3778:16), 0
	jp	StringData_APCModeNames_0x9AD
ParamPopup_PartPedal_Entry2:
	cpdi8	(0x0eb5), 129
	jrl	z, ParamPopup_PartPedal_Skip19
	call	DisplayStr_BytecodeBlock_A_0xCD
	ld	(3952:16), 48
	ldw	(3778:16), 0
	jp	StringData_APCModeNames_0x9B1
ParamPopup_PartPedal_Skip19:
	call	DisplayStr_BytecodeBlock_A_0x120
	call	DisplayStr_BytecodeBlock_A_0x1A4
	cpdi8	(0x0ebb), 129
	jrl	nz, ParamPopup_PartPedal_Entry3
	call	DisplayStr_BytecodeBlock_A
	ld	(3952:16), 48
	ldw	(3778:16), 0
	jp	StringData_APCModeNames_0x9AD
ParamPopup_PartPedal_Entry3:
	cpdi8	(0x0ebb), 132
	jrl	nz, ParamPopup_PartPedal_Entry4
	call	StringData_APCModeNames_0x9B2
	jp	StringData_APCModeNames_0x9AD
ParamPopup_PartPedal_Entry4:
	cpdi8	(0x0ebc), 0
	jrl	nz, ParamPopup_PartPedal_Skip20
	call	DisplayStr_BytecodeBlock_A_0xCD
	xor	wa, wa
	ld	(3952:16), a
	ld	(3778:16), wa
	jp	StringData_APCModeNames_0x9AD
ParamPopup_PartPedal_Skip20:
	call	DisplayStr_BytecodeBlock_A
	ld	(3952:16), 48
	ldw	(3778:16), 0
	call	VoiceBank_ProcessCommand
ParamPopup_PartPedal_Return:
	ret
	call	DisplayStr_BytecodeBlock_A_0xCD
	xor	wa, wa
	ld	(3952:16), a
	ld	(3778:16), wa
	ret
	ld	a, (4467:16)
	ld	w, 96:opc
	muls	wa, w
	ld	l, (4466:16)
	xor	h, h
	add	wa, hl
	ld	(3778:16), wa
	ret
	push	xiy
	call	StringData_APCModeNames_0xA38
	xor	wa, wa
	ld	(4468:16), wa
	ld	wa, (0x28c1:16)
	ld	(4472:16), wa
	ld	wa, (0x28bf:16)
	ld	(4474:16), wa
ParamPopup_PartPedal_Loop:
	call	StringData_APCModeNames_0xA48
	call	StringData_APCModeNames_0xAAC
	bit	7, a
	jrl	z, ParamPopup_PartPedal_Loop
ParamPopup_PartPedal_Loop2:
	call	StringData_APCModeNames_0xA48
	cp	l, 0:i3
	jrl	nz, ParamPopup_PartPedal_Epilogue
	call	StringData_APCModeNames_0xAAC
	bit	7, a
	jrl	z, ParamPopup_PartPedal_Loop2
	cp	a, 129
	jrl	nz, ParamPopup_PartPedal_Skip21
	incw	1, (4468:16)
	jp	StringData_APCModeNames_0x9FF
ParamPopup_PartPedal_Skip21:
	ld	l, 0:opc
	call	StringData_APCModeNames_0xAC2
	ld	a, (4463:16)
	cp	a, 47
	jrl	z, ParamPopup_PartPedal_Loop2
	cp	a, 95
	jrl	z, ParamPopup_PartPedal_Loop2
ParamPopup_PartPedal_Epilogue:
	pop	xiy
	ret
	ld	xix, 4462
	xor	wa, wa
	ld	bc, 3:i3
	ld	(xix+), wa
	djnz16	bc, -6
	ret
	ld	wa, (4472:16)
	cp	wa, 5:i3
	jrl	nz, ParamPopup_PartPedal_Skip23
	ld	hl, (4474:16)
	call	DisplayStr_ComputeTableAddr
	ld	xhl, (4349:16)
	ld	wa, (xhl+1)
	cp	wa, 0:i3
	jrl	nz, ParamPopup_PartPedal_Skip22
	ld	l, 1:opc
	jp	StringData_APCModeNames_0xA7E
ParamPopup_PartPedal_Skip22:
	ld	(4474:16), wa
	ldw	wa, 255
	jp	StringData_APCModeNames_0xA78
ParamPopup_PartPedal_Skip23:
	dec	1, wa
	ld	(4472:16), wa
	xor	hl, hl
	ret
ParamPopup_PartPedal_Helper:
	push	xix
	ld	wa, (4472:16)
	cp	wa, 255
	jrl	nz, ParamPopup_PartPedal_Skip24
	ld	hl, (4474:16)
	call	DisplayStr_ComputeTableAddr
	ld	xhl, (4349:16)
	ld	hl, (xhl+3)
	ld	(4474:16), hl
	ld	wa, 5:i3
	jp	StringData_APCModeNames_0xAA6
ParamPopup_PartPedal_Skip24:
	inc	1, wa
	ld	(4472:16), wa
	pop	xix
	ret
	ld	hl, (4474:16)
	call	DisplayStr_ComputeTableAddr
	ld	xhl, (4349:16)
	ld	iy, (4472:16)
	ld_rrb a, xhl, iy
	ret
	pushdi_w	(0x117a)
	pushdi_w	(0x1178)
	ld	xix, 4462
	push	xix
	call	StringData_APCModeNames_0xAAC
	pop	xix
	ld (xix+), a
ParamPopup_PartPedal_Join:
	push xix
	call ParamPopup_PartPedal_Helper
	call	StringData_APCModeNames_0xAAC
	pop	xix
	bit	7, a
	jrl	nz, ParamPopup_PartPedal_Entry5
	ld (xix+), a
	jp ParamPopup_PartPedal_Join
ParamPopup_PartPedal_Entry5:
	popw (0x1178:16)	; popw (0x1178)
	popw (0x117a:16)	; popw (0x117a)
	ret

;=============================================================================
; Display_RedrawStatusBar - Redraw the status bar region
;
; Updates the top status bar area with current mode, tempo, and status info.
;=============================================================================
Display_RedrawStatusBar:
	bit 0, (3927:16)
	jrl nz, Scoop_Return
	cp (0x8d38:16), 138
	jrl nz, Scoop_Return
	ld (0x03efa8:24), 0x00
	call UIRender_LoadTwoDescriptors
	ld l, (3567:16)
	xor h, h
	cp l, 0x12
	jr nz, Scoop_SetupDisplayTables
	call Display_DeferOrDrawWall
	ld (0x03efa8:24), 0x00
	ld xiy, StyleUI_ParamBlock_AltD
	ld xix, StyleUI_ParamBlock_AltE
	call UIRender_TwoTableGeneral
	call Display_DeferOrUpdateScreen
	jrl Scoop_Return

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
	ld xiy, StyleUI_ParamBlockPtrTable_0x98

Scoop_SelectModeTable_2Part:
	ld_sril3 XIY, 0x07, 0xf4, 0xec
	ld xix, StyleUI_ParamBlockPtrTable_0x4C
	cp (3429:16), 2
	jr nz, Scoop_SelectModeTable_2Part_XIX
	ld xix, StyleUI_ParamBlockPtrTable_0xE4

Scoop_SelectModeTable_2Part_XIX:
	ld_sril3 XIX, 0x07, 0xf0, 0xec
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
	ldb_sri A, 0x03, 0xf4, 0xe0
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

	; Uirender display list, 8 B.  Read by Scoop_CallDisplayHelper (0xF00A94): `ld xiy, Scoop_DisplayData_ButtonLayout`
	; handed in XIY to UIRender_TwoTableGeneral
Scoop_DisplayData_ButtonLayout:
	.byte	0x0e, 0x08, 0x92, 0x12, 0x06, 0x00, 0x13, 0x00
	ld	xiy, Scoop_CallDisplayHelper_DisplayList
	ld	xix, Scoop_DisplayData_ButtonLayout_0x21
	call	UIRender_TwoTableGeneral
	ret
	; Uirender display list, 10 B.  Read by Scoop_CallDisplayHelper (0xF00A94): `ld xiy, Scoop_CallDisplayHelper_DisplayList`
	; handed in XIY to UIRender_TwoTableGeneral
Scoop_CallDisplayHelper_DisplayList:
	.byte	0x1b, 0x0a, 0x08, 0x00, 0x32, 0x00, 0x10, 0x01, 0x42, 0x00
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

	; Uirender display list, 90 B.  Read by Scoop_DrawGridLines (0xF00AD3): `ld xiy, Scoop_GridLineData`
	; handed in XIY to UIRender_TwoTableGeneral
Scoop_GridLineData:
	.byte	0x1b, 0x0a, 0x08, 0x00, 0x32, 0x00, 0x10, 0x01, 0x42, 0x00, 0x1b, 0x0a, 0x05, 0x00, 0x4b, 0x00
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF00AEE-0xF00B0A (28 B), unreached CODE-territory, was disassembled as 18 plausible-but-dead instruction lines; per=78% dist=9 near Scoop_GridLineData+8
	.byte	0x05, 0x00, 0x4f, 0x00, 0x1b, 0x0a, 0x49, 0x00, 0x4b, 0x00, 0x49, 0x00, 0x4f, 0x00, 0x1b, 0x0a
	.byte	0x89, 0x00, 0x4b, 0x00, 0x89, 0x00, 0x4f, 0x00, 0x1b, 0x0a, 0xc9, 0x00, 0x4b, 0x00, 0xc9, 0x00
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF00B15-0xF00B26 (17 B), unreached CODE-territory, was disassembled as 10 plausible-but-dead instruction lines; per=100% dist=8 near Scoop_GridLineData+47
	.byte	0x4f, 0x00, 0x1b, 0x0a, 0x09, 0x01, 0x4b, 0x00, 0x09, 0x01, 0x4f, 0x00, 0x1b, 0x0a, 0x05, 0x00
	.byte	0x50, 0x00, 0x09, 0x01, 0x50, 0x00, 0x1b, 0x0a, 0x08, 0x00, 0x5f, 0x00, 0x10, 0x01, 0x6f, 0x00
	.byte	0x1b, 0x0a, 0x08, 0x00, 0x8c, 0x00, 0x10, 0x01, 0x9c, 0x00

Scoop_DrawGridDividers:
	ld xiy, Scoop_GridDividerData
	ld xix, Scoop_DrawFrameLines
	call UIRender_TwoTableGeneral
	ret

	; Uirender display list, 30 B.  Read by Scoop_DrawGridDividers (0xF00B40): `ld xiy, Scoop_GridDividerData`
	; handed in XIY to UIRender_TwoTableGeneral
Scoop_GridDividerData:
	.byte	0x1b, 0x0a, 0x08, 0x00, 0x28, 0x00, 0x27, 0x00, 0x32, 0x00, 0x1b, 0x0a, 0x08, 0x00, 0x55, 0x00
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF00B53-0xF00B67 (20 B), unreached CODE-territory, was disassembled as 10 plausible-but-dead instruction lines; per=80% dist=9 near Scoop_GridDividerData+4
	.byte	0x27, 0x00, 0x5f, 0x00, 0x1b, 0x0a, 0x08, 0x00, 0x82, 0x00, 0x27, 0x00, 0x8c, 0x00

Scoop_DrawFrameLines:
	ld xiy, Scoop_FrameData
	ld xix, Scoop_InitDisplayFull
	call UIRender_TwoTableGeneral
	ret

	; Uirender display list, 113 B.  Read by Scoop_DrawFrameLines (0xF00B6D): `ld xiy, Scoop_FrameData`
	; handed in XIY to UIRender_TwoTableGeneral
Scoop_FrameData:
	.byte	0x0e, 0x08, 0x12, 0x06, 0x06, 0x00, 0x13, 0x00, 0x0e, 0x08, 0x52, 0x0c, 0x06, 0x00, 0x13, 0x00
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF00B7D-0xF00B9F (34 B), unreached CODE-territory, was disassembled as 22 plausible-but-dead instruction lines; per=62% dist=15 near Scoop_FrameData+1
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
	ldb_sri A, 0x03, 0xf4, 0xe0
	ld (4493:16), a
	ld xiy, SOUND_DATA_DRUM_KITS_0x3A
	call Scoop_ConditionalCurveUpdate
	ret

Display_RedrawMainContent:
	cp (0x8d38:16), 138
	jr nz, Scoop_RedrawMainContent_End
	ld (0x03efa8:24), 0x00
	ld xiy, StyleUI_ScreenData_Main_0x1F9
	call Scoop_CurveUpdate_Direct

Scoop_RedrawMainContent_End:
	ret

Display_RedrawFooter:
	cp (0x8d38:16), 138
	jr nz, Scoop_RedrawFooter_End
	ld (0x03efa8:24), 0x00
	ld a, (3922:16)
	ld (4497:16), a
	ld (4498:16), a
	ld xiy, StyleUI_ScreenData_Main_0x21C
	cpw (3664:16), 0
	jr nz, Scoop_FooterShowPartValue
	ld xix, StyleUI_ScreenData_Main_0x258
	jr Scoop_FooterCallDisplay

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
	cp (0x8d38:16), 138
	jrl nz, Scoop_TitleBar_End
	ld (0x03efa8:24), 0x02
	calr Scoop_DrawGridLines
	calr Scoop_TitleBar_SelectPartRange
	cpw (3660:16), 0
	jr z, Scoop_TitleBar_Part1Check
	xor bc, bc
	calr Scoop_TitleBar_GetPartConfig
	cpw (3660:16), 1000
	jr c, Scoop_TitleBar_ShowBPM_Part0
	ld xiy, StyleUI_ScreenData_Main_0x1E0
	call Scoop_ConditionalGlideSetup
	jr Scoop_TitleBar_Part1Check

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
	cp (0x8d38:16), 138
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
	ld xiy, StyleUI_ScreenData_Main_0x986
	ld xix, StyleUI_ScreenData_Main_0x990
	call UIRender_TwoTableGeneral
	cp (0x370f:16), 0
	jr z, Scoop_Selection_End
	ld a, (0x370f:16)
	ld (4495:16), a
	ld xiy, StyleUI_ScreenData_Main_0xA06
	call UIRender_TwoTableEvtCheck
	jr Scoop_Selection_End

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
	jrl nz, Scoop_SidePanel_End
	cp (0x8d38:16), 138
	jrl nz, Scoop_SidePanel_End
	ld xiy, 0x372e
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
	cp (0x8d38:16), 138
	jr nz, Scoop_ButtonLabels_End
	ld (0x03efa8:24), 0x00
	call Scoop_ButtonLabels_CopySlotData
	ld xiy, StyleUI_ScreenData_Main_0xBD4
	ld xix, StyleUI_ScreenData_Main_0xD3C
	call GraphicsRender_TwoTable
	call Scoop_ButtonLabels_SetupPartButtons
	ld (0x03efa8:24), 0x02
	ld xiy, StyleUI_ScreenData_Main_0x276
	ld xix, StyleUI_ScreenData_Main_0x3DE
	call GraphicsRender_TwoTable
	call Scoop_ButtonLabels_DrawPitchLabels
	ld xix, 0xe55
	ld xiy, StyleUI_ScreenData_Main_0x3DE
	calr Scoop_ButtonLabels_DrawCategory
	call Scoop_ButtonLabels_DrawAmpLabels
	ld xix, 0xe75
	ld xiy, StyleUI_ScreenData_Main_0x546
	calr Scoop_ButtonLabels_DrawCategory
	call Scoop_ButtonLabels_DrawFilterLabels
	ld xix, 0xe95
	ld xiy, StyleUI_ScreenData_Main_0x6AE
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
	cp (0x8d38:16), 138
	jr nz, Scoop_EventHandler_SetupData
	xor bc, bc

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
	stda32	(0x267a), xwa
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
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	cpdi8	(0x287a), 0
	jr	z, Scoop_EventHandler_SpecialMode_Loop
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Loop:
	cp de, (10426:16)
	jr	nz, Scoop_EventHandler_SpecialMode_Skip4
	jr	Scoop_EventHandler_SpecialMode_Join2
Scoop_EventHandler_SpecialMode_Skip4:
	ld	bc, (9870:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams_0x38
	cpdi8	(0x287a), 0
	jr	z, Scoop_EventHandler_SpecialMode_Skip5
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Skip5:
	ld	bc, (9872:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	cpdi8	(0x287a), 0
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
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	cpdi8	(0x287a), 0
	jr	z, Scoop_EventHandler_SpecialMode_Skip6
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Skip6:
	call	Scoop_SpecialMode_UpdateParams_0x38
	cpdi8	(0x287a), 0
	jr	z, Scoop_EventHandler_SpecialMode_Loop2
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Loop2:
	cp de, (10426:16)
	jr	nz, Scoop_EventHandler_SpecialMode_Skip7
	jr	Scoop_EventHandler_SpecialMode_Join4
Scoop_EventHandler_SpecialMode_Skip7:
	ldw	bc, 256
	sub	bc, 5
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	cpdi8	(0x287a), 0
	jr	z, Scoop_EventHandler_SpecialMode_Skip8
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Skip8:
	call	Scoop_SpecialMode_UpdateParams_0x38
	cpdi8	(0x287a), 0
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
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams_0x38
	cpdi8	(0x287a), 0
	jr	z, Scoop_EventHandler_SpecialMode_Skip9
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Skip9:
	ld	bc, (9870:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	cpdi8	(0x287a), 0
	jr	z, Scoop_EventHandler_SpecialMode_Loop3
	jrl	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Loop3:
	cp de, (10426:16)
	jr	nz, Scoop_EventHandler_SpecialMode_Skip10
	jr	Scoop_EventHandler_SpecialMode_Join6
Scoop_EventHandler_SpecialMode_Skip10:
	ld	bc, (9872:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams_0x38
	cpdi8	(0x287a), 0
	jr	z, Scoop_EventHandler_SpecialMode_Skip11
	jr	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Skip11:
	ld	bc, (9870:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	cpdi8	(0x287a), 0
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
	call	Scoop_SpecialMode_UpdateParams_0x70
	jr	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Join8:
	ld	bc, (9876:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams_0x38
	cpdi8	(0x287a), 0
	jr	z, Scoop_EventHandler_SpecialMode_Skip13
	jr	Scoop_EventHandler_SpecialMode_Return
Scoop_EventHandler_SpecialMode_Skip13:
	ld	bc, (9880:16)
	sub bc, (9876:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
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
	call DispatchHandler_SubJumpTable
	ld xhl, (4349:16)
	ld ix, iy
	ld iy, (xhl + 3)
	cp iy, 0xffff
	jr nz, Scoop_SpecialMode_ValueSend_Part2
	ldw (3302:16), 0
	ld iy, ix
	andmi8 (xhl), 0x7f
	jr Scoop_SpecialMode_ValueSend_Part3
	ld e, a
	extz de
	ld a, c
	extz wa
	ld bc, de
	ld de, wa
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
	lda_dri XSP, 0xfd, 0xf0, 0xfe
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
	lda xbc, (Str_No_0xCEE:24)
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
	lda_dri XWA, 0xfd, 0x0c, 0x01
	ld xhl, xwa
	lda_dri XWA, 0xfd, 0x08, 0x01
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
	lda_dri XSP, 0xfd, 0x10, 0x01
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
	ld_rrb a, xhl, wa
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
	lda	xbc, (Str_No_0xCEE:24)
	ld_rrl	xwa, xbc, wa
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
	lda_rr xbc, xbc, wa
	ld wa, (xbc)
	extz xwa
	div wa, 40
	ld (xsp+2), wa
	ld wa, (xbc)
	extz xwa
	div wa, 40
	ld wa, qwa
	sll wa, 3
	ld (xsp+0:8), wa
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF01B97-0xF01BAB (20 B), unreached CODE-territory, was disassembled as 7 plausible-but-dead instruction lines; per=89% dist=12 near Scoop_EnvelopeCalc_Data+337
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
	lda_rr xbc, xbc, wa
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
	stw_dri HL, 0xfd, 0x00, 0x01	; ld (XSP+0x0100),HL
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
	ld_rrb c, xiy, bc
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
	lda_dri XSP, 0xfd, 0xf4, 0xfe
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
	ld xbc, 0:i3
	call CalcTotalWidth
	ldw_sri0 WA, (xsp + 0x0102)
	add wa, hl
	stw_dri WA, 0xfd, 0x0a, 0x01
	ldw_sri0 WA, (xsp + 0x0104)
	stw_dri WA, 0xfd, 0x08, 0x01
	ld xwa, 0:i3
	call GetCharDescent
	ld iz, hl
	ld xwa, 0:i3
	call GetCharHeight
	ldw_sri0 WA, (xsp + 0x0104)
	add wa, hl
	sub wa, iz
	stw_dri WA, 0xfd, 0x0c, 0x01
	lda_dri XWA, 0xfd, 0x06, 0x01
	ld xhl, xwa
	lda_dri XWA, 0xfd, 0x02, 0x01
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
	lda_dri XSP, 0xfd, 0x0c, 0x01
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
	stw_dri HL, 0xfd, 0x00, 0x01	; ld (XSP+0x0100),HL
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
	ld_rrb c, xiy, bc
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
	stw_dri HL, 0xfd, 0x00, 0x01	; ld (XSP+0x0100),HL
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
	lda_dri XSP, 0xfd, 0x6a, 0xff
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
	lda_dri XIZ, 0x07, 0xf8, 0xe0
	cpl_sri_mr XIZ, 0xfd, 0x96, 0x00
	jr ugt, Scoop_EventLoop_12Entry_Process

Scoop_EventLoop_12Entry_End:
	pop xiz
	lda_dri XSP, 0xfd, 0x96, 0x00
	ret

Scoop_EnvProcessor_Data:
	lda	xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, StyleUI_ScreenData_CtlOnly_0x1CB
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
	jr	z, Scoop_EventLoop_12Entry_Skip9
	srla e	; srl A,E
Scoop_EventLoop_12Entry_Skip9:
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
	jr	z, Scoop_EventLoop_12Entry_Skip
	cp	wa, 1:i3
	jr	nz, Scoop_EventLoop_12Entry_Skip2
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xccca
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_12Entry_Join
Scoop_EventLoop_12Entry_Skip:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xccce
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_12Entry_Join
Scoop_EventLoop_12Entry_Skip2:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw 0xccd2
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
Scoop_EventLoop_12Entry_Join:
	ld	a, (xiz+6)
	and	a, 63
	extz	wa
	sla	wa, 2
	lda	xbc, (Str_No_0xCEE:24)
	ld_rrl	xix, xbc, wa
	lda	xwa, (xsp+264)
	ld	xhl, xwa
	lda	xwa, (xsp+260)
	ld	xbc, xwa
	lda	xwa, (xsp+4)
	ld	xde, xwa
	push	xix
	pushw 255
	pushw 245
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
	jr	z, Scoop_EventLoop_12Entry_Skip10
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
	ld	a, (xiz+10)
	cp	a, e
	jr	z, Scoop_EventLoop_12Entry_Skip11
	cp	a, 128
	jr	nc, Scoop_EventLoop_12Entry_Skip3
	cp	e, 128
	jr	c, Scoop_EventLoop_12Entry_Skip3
	ld	a, 128:opc
	sub	e, 128
Scoop_EventLoop_12Entry_Skip3:
	cp	e, a
	jr	ule, Scoop_EventLoop_12Entry_Skip4
	ld	(xsp+4), 43
	sub	e, a
	jr	Scoop_EventLoop_12Entry_Join2
Scoop_EventLoop_12Entry_Skip4:
	ld	(xsp+4), 45
	sub	a, e
	ld	e, a
Scoop_EventLoop_12Entry_Join2:
	ld	wa, hl
	cp	wa, 2:i3
	jr	z, Scoop_EventLoop_12Entry_Skip5
	cp	wa, 1:i3
	jr	nz, Scoop_EventLoop_12Entry_Skip6
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xccde
	lda	xwa, (xsp+11)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jrl	Scoop_EventLoop_12Entry_Join3
Scoop_EventLoop_12Entry_Skip5:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xcce2
	lda	xwa, (xsp+11)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_12Entry_Join3
Scoop_EventLoop_12Entry_Skip6:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xcce6
	lda	xwa, (xsp+11)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_12Entry_Join3
Scoop_EventLoop_12Entry_Skip11:
	ld	e, 0:opc
	ld	wa, hl
	cp	wa, 2:i3
	jr	z, Scoop_EventLoop_12Entry_Skip7
	cp	wa, 1:i3
	jr	nz, Scoop_EventLoop_12Entry_Skip8
	ld	a, e
	extz	wa
	pushw wa
	pushw 224
	pushw 0xccea
	lda	xwa, (xsp+10)
	push xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	t, Scoop_EventLoop_12Entry_Join3
Scoop_EventLoop_12Entry_Skip7:
	ld	a, e
	extz	wa
	pushw wa
	pushw 224
	pushw 0xccee
	lda	xwa, (xsp+10)
	push xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	t, Scoop_EventLoop_12Entry_Join3
Scoop_EventLoop_12Entry_Skip8:
	ld	a, e
	extz	wa
	pushw wa
	pushw 224
	pushw 0xccf2
	lda	xwa, (xsp+10)
	push xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
Scoop_EventLoop_12Entry_Join3:
	ld	a, (xiz+6)
	and	a, 63
	extz	wa
	sla	wa, 2
	lda	xbc, (Str_No_0xCEE:24)
	ld_rrl	xix, xbc, wa
	lda	xwa, (xsp+264)
	ld	xhl, xwa
	lda	xwa, (xsp+260)
	ld	xbc, xwa
	lda	xwa, (xsp+4)
	ld	xde, xwa
	push	xix
	pushw 255
	pushw 245
	ld	xwa, xhl
	call	DrawString
	pop	xiz
	lda	xsp, (xsp+268)
	ret

Scoop_EventLoop_36Entry:
	lda_dri XSP, 0xfd, 0xec, 0xfe
	pushw iz
	stl_dri XWA, 0xfd, 0x12, 0x01
	ld xiy, StyleUI_ScreenData_CtlOnly_0x1FF
	lda_dri XIX, 0xfd, 0x0a, 0x01
	ld bc, 4:i3
	ldirw
	ld XWA, (xsp + 0x0112)
	ld de, (xwa + 2)
	extz xde
	ld XWA, (xsp + 0x0112)
	ld bc, (xwa + 7)
	ld XWA, (xsp + 0x0112)
	ld a, (xwa + 9)
	ld l, a
	extz hl
	ld wa, bc
	extz xwa
	div wa, 0x28
	stw_dri WA, 0xfd, 0x08, 0x01
	ldw_sri0 WA, (xsp + 0x0108)
	muls wa, 0x28
	sub bc, wa
	sll bc, 3
	stw_dri BC, 0xfd, 0x06, 0x01
	dec_sriw 2, 0xfd, 0x08, 0x01
	ld wa, hl
	cp wa, 2:i3
	jr z, Scoop_EventLoop_36Entry_Branch1
	cp wa, 1:i3
	jr nz, Scoop_EventLoop_36Entry_Branch2
	pushm (xde)
	pushw 0xe0
	pushw 0xccfe
	lda xwa, (xsp + 12)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	jr Scoop_EventLoop_36Entry_Branch3

Scoop_EventLoop_36Entry_Branch1:
	pushm (xde)
	pushw 0xe0
	pushw 0xcd02
	lda xwa, (xsp + 12)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	jr Scoop_EventLoop_36Entry_Branch3

Scoop_EventLoop_36Entry_Branch2:
	pushm (xde)
	pushw 0xe0
	pushw 0xcd06
	lda xwa, (xsp + 12)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)

Scoop_EventLoop_36Entry_Branch3:
	ld XWA, (xsp + 0x0112)
	ld a, (xwa + 6)
	and a, 0x3f
	extz wa
	sla wa, 2
	lda xbc, (Str_No_0xCEE:24)
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
	lda_dri XWA, 0xfd, 0x0a, 0x01
	ld xhl, xwa
	lda_dri XWA, 0xfd, 0x06, 0x01
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
	lda_dri XSP, 0xfd, 0x14, 0x01
	ret

Scoop_EventLoop_36Entry_Data:
	lda xsp, (xsp-268)
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
	jr	z, Scoop_EventLoop_36Entry_Skip5
	srla e	; srl A,E
Scoop_EventLoop_36Entry_Skip5:
	ld	c, (xiz+11)
	ld	wa, (xiz+7)
	ld	(xsp+260), wa
	ld	wa, (xiz+9)
	ld	(xsp+262), wa
	ld	a, c
	cp	a, 2:i3
	jr	z, Scoop_EventLoop_36Entry_Skip6
	cp	a, 1:i3
	jr	nz, Scoop_EventLoop_36Entry_Skip7
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xcd12
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Join
Scoop_EventLoop_36Entry_Skip6:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xcd16
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Join
Scoop_EventLoop_36Entry_Skip7:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xcd1a
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
Scoop_EventLoop_36Entry_Join:
	ld	a, (xiz+6)
	and	a, 15
	extz	wa
	sla	wa, 2
	lda	xbc, (Str_No_0xDEE:24)
	ld_rrl xix, xbc, wa
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
	lda xsp, (xsp-268)
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
	jr	z, Scoop_EventLoop_36Entry_Skip8
	srla e	; srl A,E
Scoop_EventLoop_36Entry_Skip8:
	ld	c, (xiz+11)
	ld	wa, (xiz+7)
	ld	(xsp+260), wa
	ld	wa, (xiz+9)
	ld	(xsp+262), wa
	ld	a, (xiz+12)
	cp	a, e
	jr	z, Scoop_EventLoop_36Entry_Skip11
	cp	a, 128
	jr	nc, Scoop_EventLoop_36Entry_Skip9
	cp	e, 128
	jr	c, Scoop_EventLoop_36Entry_Skip9
	ld	a, 128:opc
	sub	e, 128
Scoop_EventLoop_36Entry_Skip9:
	cp	e, a
	jr	ule, Scoop_EventLoop_36Entry_Skip10
	ld	(xsp+4), 43
	sub	e, a
	jr	Scoop_EventLoop_36Entry_Join2
Scoop_EventLoop_36Entry_Skip10:
	ld	(xsp+4), 45
	sub	a, e
	ld	e, a
Scoop_EventLoop_36Entry_Join2:
	ld	a, c
	cp	a, 2:i3
	jr	z, Scoop_EventLoop_36Entry_Skip
	cp	a, 1:i3
	jr	nz, Scoop_EventLoop_36Entry_Skip2
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xcd26
	lda	xwa, (xsp+11)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jrl	Scoop_EventLoop_36Entry_Join3
Scoop_EventLoop_36Entry_Skip:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xcd2a
	lda	xwa, (xsp+11)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Join3
Scoop_EventLoop_36Entry_Skip2:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xcd2e
	lda	xwa, (xsp+11)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Join3
Scoop_EventLoop_36Entry_Skip11:
	ld	e, 0:opc
	ld	a, c
	cp	a, 2:i3
	jr	z, Scoop_EventLoop_36Entry_Skip3
	cp	a, 1:i3
	jr	nz, Scoop_EventLoop_36Entry_Skip4
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xcd32
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Join3
Scoop_EventLoop_36Entry_Skip3:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xcd36
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Join3
Scoop_EventLoop_36Entry_Skip4:
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	0xcd3a
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
Scoop_EventLoop_36Entry_Join3:
	ld	a, (xiz+6)
	and	a, 15
	extz	wa
	sla	wa, 2
	lda	xbc, (Str_No_0xDEE:24)
	ld_rrl	xix, xbc, wa
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
	lda xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, GUI_FormatStrings_0x20
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
	jr	z, Scoop_EventLoop_36Entry_Skip12
	cp	a, 1:i3
	jr	nz, Scoop_EventLoop_36Entry_Skip13
	pushm	(xbc)
	pushw	224
	pushw	0xcd46
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Join4
Scoop_EventLoop_36Entry_Skip12:
	pushm	(xbc)
	pushw	224
	pushw	0xcd4a
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	Scoop_EventLoop_36Entry_Join4
Scoop_EventLoop_36Entry_Skip13:
	pushm	(xbc)
	pushw	224
	pushw	0xcd4e
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
Scoop_EventLoop_36Entry_Join4:
	ld	a, (xiz+6)
	and	a, 15
	extz	wa
	sla	wa, 2
	lda	xbc, (Str_No_0xDEE:24)
	ld_rrl	xix, xbc, wa
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
	lda xsp, (xsp-270)
	push	xiz
	ld	xde, xwa
	ld	xiy, GUI_FormatStrings_0x34
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
	jr	z, Scoop_EventLoop_36Entry_Skip14
	srla c	; srl A,C
Scoop_EventLoop_36Entry_Skip14:
	ld	(xsp+4), c
	ld	wa, (xde+13)
	ld	(xsp+262), wa
	ld	wa, (xde+15)
	ld	(xsp+264), wa
	ld	iy, (xde+11)
	ld	ix, 0:i3
	cp	ix, iy
	jr	nc, Scoop_EventLoop_36Entry_Skip15
Scoop_EventLoop_36Entry_Loop:
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
	jr	c, Scoop_EventLoop_36Entry_Loop
Scoop_EventLoop_36Entry_Skip15:
	ld	wa, ix
	extz	xwa
	lda	xbc, (xsp+6)
	add	xbc, xwa
	ld	(xbc), 0
	ld	a, (xde+6)
	and	a, 15
	extz	wa
	sla	wa, 2
	lda	xbc, (Str_No_0xDEE:24)
	ld_rrl	xix, xbc, wa
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
	lda_dri XIZ, 0x07, 0xf8, 0xe0
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
	lda_24 xwa, (\ParamB)
	ld (xbc + 4), xwa
	ld wa, (\ParamC:24)	; was `ldw_da xwa, ...`: d2 nn nn nn 20 loads WA, not XWA
	ld (xbc + 8), wa
	lda_24 xwa, (\ParamD)
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
	lda_24 xwa, (\ParamB)
	ld (xbc + 4), xwa
	ldw (xbc + 8), \ParamC
	lda_24 xwa, (\ParamD)
	ld (xbc + 10), xwa
	.if \ParamE <= 7
	ld wa, \ParamE:i3
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


.macro RegTitle ParamA, ParamBhi, ParamBlow, ParamC, ParamD, ParamE
	pushw \ParamA
	pushw \ParamBhi
	pushw \ParamBlow
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

	RegObjTable 0x1600004, 0xfa44e2, 0xe0cdac, 0xe0cd94, 0x166
	RegObjTable 0x160000c, 0xfa58fb, 0xe0cdb2, 0xe0cdae, 0x1c6
	RegObjTable 0x160000d, 0xfa5948, 0xe0cdb8, 0xe0cdb4, 0x1e6
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
