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
	ld	w, 41:opc
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
	ld	w, 241:opc
	.byte 0x81
	scf
	.byte 0x50
	ld	(4483:16), 32
	.byte 0xf1, 0x85
	scf
	dec	6, w
	ldio	209, 130
	scf
	ld	w, 241:opc
	.byte 0x81
	scf
	.byte 0x50
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
	calr	117
	calr	65504
	ret
	calr	110
	calr	65460
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
	jr	z, 14
	jr	gt, 10
	xor	de, 0xffff
	inc	1, de
	add	wa, de
	jr	2
	sub	wa, de
	cp	wa, 0:i3
	jr	z, 22
	jr	gt, 13
	xor	wa, 0xffff
	inc	1, wa
	ld	(4480:16), 45
	jr	12
	ld	(4480:16), 43
	jr	5
	ld (4480:16), 32
	ret
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
	call Display_CallMenuConfig
	ld a, (0x8c9a:16)
	cp a, (0x8c9b:16)
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
	ld	a, w
	call	16692690
	ret
SoundEvt_ShortPacketHandler:
	ld	(3923:16), 0
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	ld	w, 1:opc
	call	15687812
	ret
SoundEvt_LongPacketHandler:
	ld	(3923:16), 0
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	ld	w, 2:opc
	call	15687812
	ret
	call	16355597
	cp	hl, 0:i3
	jrl	nz, 26
	ld	l, (3429:16)
	and	l, 3
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, 15687848
	ld_rrl	xhl, xix, hl
	pop	xix
	call (xhl)
	ret
	.byte 0xbe, 0x61, 0xef
	nop
	.byte 0xb8, 0x60, 0xef
	nop
	push	xsp
	jr	lt, -17
	nop
	.byte 0xbe, 0x61, 0xef
	nop
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
	ld	xhl, 15687983
	ld_rrl	xiy, xhl, iy
	pop	xhl
	call (xiy)
	ld	wa, (13950:16)
	cp wa, (3816:16)
	jrl	nz, 48
	ld	a, (3420:16)
	ld	w, (3821:16)
	cp	a, w
	jrl	z, 27
	cp	(3421:16), 4
	jrl	ule, 19
	cp	w, 3:i3
	jrl	ugt, 9
	cp	a, 3:i3
	jrl	ugt, 17
	jp	15687961
	cp	a, 3:i3
	jrl	ule, 8
	call	15717826
	jp	15687978
	.byte 0xc1, 0xd3, 0x0d, 0x3e, 0x01
	call	15699972
	call	15694185
	ret
ScoopDisp_HandlerData2:
	.long VoiceCtrl_SendNoteOffSequence
	.long Timer_ParamCompareAlt
	.long Timer_ParamLoadAndCompare
	.long DefaultHandler_Ret
	.incbin "includes/romslices/v7_transplant_ScoopDisp_HandlerData2_tail.bin"
DefaultHandler_Ret:
	ret
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
	ld XHL,DefaultHandler_Ret_0x2B
	ldl_dri xiy, 0x07, 0xec, 0xf4
	pop XHL
	call (XIY)
.Lc_ef61e8:
	ret
	swi	1
	jr	lt, -17
	nop
	pop_a
	jr	ule, -17
	nop
	pop_a
	jr	ule, -17
	nop
	.byte 0xdf, 0x63, 0xef, 0x00
	cp	(10430:16), 255
	jrl	nz, 84
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, 90
	cp	(3567:16), 18
	jrl	nz, 46
	cp	hl, 9
	jrl	z, 11
	cp	hl, 10
	jrl	z, 18
	jp	15688292
	bit	7, w
	jrl	nz, 58
	call	15693677
	jp	15688292
	bit	7, w
	jrl	nz, 44
	call	15693736
	jp	15688292
	sla	hl, 2
	push	xix
	ld	xix, 15688317
	ld_rrl	xhl, xix, hl
	pop	xix
	call (xhl)
	jp	15688292
	cp	bc, 15
	jrl	nz, 8
	call	15688445
	jp	15688292
	ret
ScoopDisp_FlagSetAndDispatch:
	.byte 0xc1, 0x1c, 0xe3
ScoopDisp_FlagSetAndDispatch_Code:
	push	xiz
	ldio	200, 51
	reti	
	jrl	z, 8
	call	15707916
	jp	15688316
	call	15708093
	ret	
ScoopDisp_DispatchTable_Small:
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
	.long ScoopDisp_DispatchTable_Extended + 32
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
	jrl	nz, 17
	.byte 0xc1
	jr	gt, 38
	push	xix
	swi	6
	xor	wa, wa
	ld	a, 137:opc
	call	UI_PostModeChangeEvent
	jp	ToneParam_Evt0F_BytecodeHandler_0x17
	ret
	.byte 0xc1, 0xd3
	decf
	push	xix
	swi	6
	ld	e, (3567:16)
	xor	d, d
	sla	de, 2
	ld	iy, de
	push	xhl
	ld	xhl, PerfMode_ParamHandler_Table
	ld_rrl xiy, xhl, iy
	pop xhl
	call	(xiy)
	.byte 0xc1, 0xd3
	decf
	push	xiz
	normal
	ld	bc, (9920:16)
	cp	bc, 15
	jrl	z, 79
	cp	bc, 0:i3
	jrl	z, 5
	.byte 0xc1, 0x57
	retd	0xfe3c
	.byte 0xf1, 0x57
	retd	0x7ec8
	ldw	bc, 0xc100
	.byte 0xef
	decf
	ld	a, 201:opc
	scc16	nz, wa
	halt
	nop
	cp	bc, 6:i3
	jrl	ule, 35
	cp	a, 3:i3
	jrl	nz, 5
	cp	bc, 4:i3
	jrl	z, 25
	cp	a, 7:i3
	jrl	nz, 5
	cp	bc, 3:i3
	jrl	z, 15
	cp	a, 9
	jrl	nz, 14
	cp	bc, 4:i3
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
	.incbin "includes/romslices/v7_transplant_PerfMode_ParamHandler_Table_tail.bin"
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
	ld_rrl xhl, xix, hl
	pop xix
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
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
PerfMode_Evt03_FlagHandler_A_Code:
	ld	a, (13944:16)
	ld	l, 1:opc
	ld	h, 13:opc
	call	15689018
	ld	(13944:16), a
	call	15726319
	call	15686621
	ret	
PerfMode_Evt03_FlagHandler_B:
	.byte 0xc1, 0x1c, 0xe3
PerfMode_Evt03_FlagHandler_B_Code:
	push	xiz
	ldio	193, 121
	ldw	iz, 10017
	nop	
	ld	h, 12:opc
	call	15689018
	ld	(13945:16), a
	call	15726319
	call	15686621
	ret	
PerfMode_Evt03_ClampAndUpdate:
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08, 0xc1, 0x7a, 0x36
	.byte 0x21, 0x27, 0x00, 0x26, 0x03, 0x1d, 0x3a, 0x65
	.byte 0xef, 0xf1, 0x7a, 0x36, 0x41, 0x1d, 0xef, 0xf6
	.byte 0xef, 0x1d, 0xdd, 0x5b, 0xef, 0x0e
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
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
	ret
UIDisp_DefaultInputHandler:
	ld	bc, 1:i3
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
	ld	(3923:16), 1
	ld	(3385:16), w
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
	.byte 0xd9, 0x8b, 0xdb, 0xcf, 0x1f, 0x00, 0x7b, 0x11
	.byte 0x00, 0xdb, 0xec, 0x02, 0x3c, 0x44, 0x4e, 0x66
	.byte 0xef, 0x00, 0xe3, 0x07, 0xf0, 0xec, 0x23, 0x5c
	.byte 0xb3, 0xe8, 0x0e, 0x72, 0x65, 0xef, 0x00
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
	.byte 0xd9, 0x8b, 0xdb, 0xcf, 0x1f, 0x00, 0x7b, 0x11
	.byte 0x00, 0xdb, 0xec, 0x02, 0x3c, 0x44, 0xfc, 0x66
	.byte 0xef, 0x00, 0xe3, 0x07, 0xf0, 0xec, 0x23, 0x5c
	.byte 0xb3, 0xe8, 0x0e
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
	jrl	le, -4251
	nop
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
	.byte 0xd9, 0x8b, 0xdb, 0xcf, 0x1f, 0x00, 0x7b, 0x11
	.byte 0x00, 0xdb, 0xec, 0x02, 0x3c, 0x44, 0x32, 0x68
	.byte 0xef, 0x00, 0xe3, 0x07, 0xf0, 0xec, 0x23, 0x5c
	.byte 0xb3, 0xe8, 0x0e
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
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
	ret
PerfMode_ParamHandler_Data:
	bit	7, w
	jrl	nz, 8
	call	15699040
	jp	15689951
	call	15699069
	ret
	jrl	le, -4251
	nop
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
	; framing ported from v10's source for the same label (same span length, statement for statement); 50 of 83 slots byte-identical
	bit	7, w
	jrl	nz, 105
	ld	a, (3429:16)
	cp	a, 0:i3
	jrl	z, 96
	cp	a, 3:i3
	jrl	z, 91
	cp	a, 2:i3
	jrl	z, 78
	ld	l, (3424:16)
	dec	1, l
	push	xix
	ld	xix, 61856
	.byte 0xc3	; v10 does not spell this byte either
	reti
	.byte 0xf0	; v10 does not spell this byte either
	.byte 0xec	; v10 does not spell this byte either
	push	xsp
	incf
	pop	xix
	jrl	z, 56
	ld	(3567:16), 9
	call	Display_UpdateRegion0
	ld	l, (3424:16)
	dec	1, l
	xor	h, h
	push	xix
	ld	xix, 61856
	.byte 0xc3	; v10 does not spell this byte either
	reti
	.byte 0xf0	; v10 does not spell this byte either
	.byte 0xec	; v10 does not spell this byte either
	ld	l, 219:opc
	.byte 0xec	; v10 does not spell this byte either
	push	sr
	.byte 0x44	; v10 does not spell this byte either
	.byte 0xbd	; v10 does not spell this byte either
	.byte 0x6b	; v10 does not spell this byte either
	.byte 0xef	; v10 does not spell this byte either
	.byte 0x00	; v10 does not spell this byte either
	.byte 0xe3	; v10 does not spell this byte either
	reti
	.byte 0xf0	; v10 does not spell this byte either
	.byte 0xec	; v10 does not spell this byte either
	ld	c, 92:opc
	ld	a, (xhl)
	ld	(3831:16), a
	call	15690347
	jp	15690346
	xor	wa, wa
	ld	a, 169:opc
	call	SoundCtrl_SendCommand
	ret
	ld	xix, 3789
	ld	a, 32:opc
	ldw	bc, 27
	lda_dpi	xbc, 240
	djnz16	bc, -6
	ld	xiy, 15690404
	ld	xix, 3797
	ldw	bc, 9
	.byte 0x85	; v10 does not spell this byte either
	scf
	ld	a, (3831:16)
	exts	wa
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ld	xiy, 4481
	ld	bc, 3:i3
	.byte 0x85	; v10 does not spell this byte either
	scf
	call	Display_UpdateRegion3
	ret
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
	jrl	ugt, 17
	sla	hl, 2
	push	xix
	ld	xix, PerfMode_EventTable_9
	ld_rrl xhl, xix, hl
	pop xix
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
	.incbin "includes/romslices/v7_transplant_PerfMode_Evt04_VolumeHandler.bin"
PerfMode_VoiceAddressTable:
	.byte 0xb9, 0xf9, 0x00, 0x00, 0xed, 0xf9, 0x00, 0x00
	.byte 0xd3, 0xf9, 0x00, 0x00, 0x6f, 0xfa, 0x00, 0x00
	.byte 0x89, 0xfa, 0x00, 0x00, 0xa3, 0xfa, 0x00, 0x00
	.byte 0xbd, 0xfa, 0x00, 0x00, 0xd7, 0xfa, 0x00, 0x00
	.byte 0x21, 0xfa, 0x00, 0x00, 0x3b, 0xfa, 0x00, 0x00
	.byte 0x55, 0xfa, 0x00, 0x00, 0x07, 0xfa, 0x00, 0x00
	.byte 0x3f, 0xfb, 0x00, 0x00, 0xdb, 0xfb, 0x00, 0x00
	.byte 0xdb, 0xfb, 0x00, 0x00, 0xb9, 0xf9, 0x00, 0x00
	.byte 0xb9, 0xf9, 0x00, 0x00, 0xf1, 0xfa, 0x00, 0x00
	.byte 0x0b, 0xfb, 0x00, 0x00, 0x25, 0xfb, 0x00, 0x00
	bit 0x07,W
	jrl nz, .Lc_ef6c1e
	cp A,H
	jrl z, .Lc_ef6c25
	inc 1,A
	jp 0xef6c25
.Lc_ef6c1e:
	cp A,L
	jrl z, .Lc_ef6c25
	dec 1,A
.Lc_ef6c25:
	ret
PerfMode_ParamHandler_10:
	.byte 0xd9, 0x8b, 0xdb, 0xcf, 0x1f, 0x00, 0x7b, 0x11
	.byte 0x00, 0xdb, 0xec, 0x02, 0x3c, 0x44, 0x41, 0x6c
	.byte 0xef, 0x00, 0xe3, 0x07, 0xf0, 0xec, 0x23, 0x5c
	.byte 0xb3, 0xe8, 0x0e
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
	call StringData_PartNames_0xB3
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
	call StringData_KeyNames_0x341
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
	call StringData_PartNames_0x54
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
	call StringData_PartNames_0x120
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
	call StringData_PartNames_0x1C9
VoiceParam_CommonTail:
	.byte 0x1d, 0xdd, 0x5b, 0xef	; call Display_UpdateRegion3 (v7 addr)

	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08	; ordi8	0xe3e2, 8 (v7 patched)

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
	.byte 0xd9, 0x8b, 0xdb, 0xcf, 0x1f, 0x00, 0x7b, 0x11
	.byte 0x00, 0xdb, 0xec, 0x02, 0x3c, 0x44, 0x1a, 0x6e
	.byte 0xef, 0x00, 0xe3, 0x07, 0xf0, 0xec, 0x23, 0x5c
	.byte 0xb3, 0xe8, 0x0e
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
	ld	(3923:16), 1
	pushw	wa
	ld	wa, (13950:16)
	ld	(3816:16), wa
	popw	wa
	bit	7, w
	jrl	z, 8
	call	15701308
	jp	15691451
UIState_CallDecHandler:
	call VoiceSlot_TableSetup_0x56D
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

	.byte 0x1d, 0x43, 0x73, 0xef	; call Display_FillRegion0 (v7 addr)

	.byte 0xd1, 0x7e, 0x36, 0x20	; ldw_d16 xwa, (0x371a) (v7 patched)

	cp wa, 1:i3

	jrl z, 112

	dec 1, wa

	ld (0x287f:16), wa

	cp wa, 0x3e8

	jrl c, 3

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

	.byte 0x1d, 0x93, 0x95, 0xef	; call AccPedal_CheckBitAndUpdate (v7 addr)

	.byte 0xd1, 0x7e, 0x36, 0x20	; ldw_d16 xwa, (0x371a) (v7 patched)

	cp wa, 0x3e8

	jrl c, 3

	ldw wa, 0x3e8
Display_RedrawValues_Store:
	ld	(3662:16), wa
	call	15692621
	ld	wa, (13950:16)
	ld	(10367:16), wa
	call	15691955
	ld	a, (3424:16)
	call	15858243
	ld	(3820:16), a
	ld	l, (3822:16)
	dec	1, l
	xor	h, h
	sla	hl, 1
	push	xix
	ld	xix, 3230
	ld_rrw	wa, xix, hl
	ld	(10431:16), wa
	srl	hl, 1
	ld	xix, 3262
	ld_rrw	wa, xix, hl
	pop	xix
	and	wa, 255
	ld	(10433:16), wa
	call	15723051
	ld	xix, 3862
	call	15692107
	ld	c, 2:opc
	call	15691965
	ld	a, (3820:16)
	ld	l, a
	cp	a, 4:i3
	jrl	ule, 2
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

	.byte 0x1d, 0x57, 0x73, 0xef	; call Display_FillRegion2 (v7 addr)

	.byte 0xd1, 0x7e, 0x36, 0x20	; ldw_d16 xwa, (0x371a) (v7 patched)

	inc 1, wa

	ld (0x287f:16), wa

	cp wa, 0x3e8

	jrl c, 3

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
	ld a, (3765:16)
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
	ldb_erp A, 0x3c
	ldb_erp A, 0x3d
	ld a, c
	scf
	xorcfb_erp 0x3d
	stb_erp A, 0x3c
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
	cp	bc, 0:i3
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
	.byte 0x9a, 0x6e, 0xef, 0x00
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
	.byte 0xd9, 0x8b, 0xdb, 0xcf, 0x1f, 0x00, 0x7b, 0x11
	.byte 0x00, 0xdb, 0xec, 0x02, 0x3c, 0x44, 0x30, 0x74
	.byte 0xef, 0x00, 0xe3, 0x07, 0xf0, 0xec, 0x23, 0x5c
	.byte 0xb3, 0xe8, 0x0e
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
	ld_rrl xhl, xix, hl
	pop xix
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
	bit	7, w
	jrl	nz, 4
	call	15693736
	ret
	push	xhl
	push	xde
	push	xix
	push	xiz
	.byte 0xf1, 0x53, 0x0d, 0xcb
	jrl	z, 98
	cp	(3429:16), 0
	jrl	nz, 90
	cp	(3567:16), 18
	jrl	z, 82
	cp	(49121:16), 11
	jrl	nz, 62
	push	xhl
	ld	a, (49122:16)
	ld	(3519:16), a
	call	15706801
	ld	(3519:16), 0
	pop	xhl
	ld	wa, (49122:16)
	xor	a, w
	jrl	z, 6
	push	xhl
	call	15705072
	pop	xhl
	ld	wa, (49122:16)
	cpl	a
	and	a, w
	jrl	z, 29
	ld	(3425:16), 0
	call	15725806
	call	15686621
	jp	15693262
	cp	(49121:16), 12
	jrl	nz, 4
	call	15693342
	pop	xiz
	pop	xix
	pop	xde
	pop	xhl
	ret
	.byte 0xf1, 0x53, 0x0d, 0xcb
	jrl	z, 67
	call	15686397
	call	16355597
	cp	hl, 0:i3
	jrl	nz, 50
	cp	(3429:16), 0
	jrl	nz, 42
	cp	(35996:16), 138
	jrl	nz, 34
	cp	(3567:16), 18
	jrl	z, 20
	ld	xiy, 4360
	xor	wa, wa
	.byte 0x95, 0x3c, 0xfc, 0xff
	cp	(xiy), wa
	jrl	z, 10
	call	15706801
	ldw	(4360:16), 0
	call	15686412
	ret
	ld	a, (49122:16)
	and	a, (49123:16)
	ldb_erp	a, 60
	and	a, 3
	stb_erp	a, 60
	jrl	nz, 64
	ld	a, (49122:16)
	xor	c, c
	ldb_erp	a, 60
	ldb_erp	a, 61
	ld	a, c
	.byte 0xc7, 0x3d, 0x2b
	ccf
	.byte 0xc7, 0x3d, 0x2c
	stb_erp	a, 60
	stb_erp	a, 61
	inc	1, c
	ldb_erp	a, 60
	ldb_erp	a, 61
	ld	a, c
	.byte 0xc7, 0x3d, 0x2b
	ccf
	.byte 0xc7, 0x3d, 0x2c
	stb_erp	a, 60
	stb_erp	a, 61
	and	a, (49123:16)
	ld	(3520:16), a
	push	xhl
	call	15706801
	pop	xhl
	ld	(3520:16), 0
	ld	a, (49122:16)
	and	a, 3
	jrl	z, 87
	push	xhl
	and	a, 1
	jrl	z, 71
	ld	xhl, 3412
	.byte 0xb3, 0xcb
	jrl	z, 61
	ld	(132584:24), 255
	ld	(132588:24), 255
	ld	(132586:24), 255
	ld	a, (3822:16)
	ld	(10359:16), a
	call	15734672
	.byte 0xf1, 0x54, 0x0d, 0xb7
	ld	(3434:16), 0
	call	15704416
	ld	(132584:24), 255
	ld	(132588:24), 255
	ld	(132586:24), 255
	pushw	wa
	ld	w, 118:opc
	call	15687771
	popw	wa
	pop	xhl
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
	ld	xde, 15693631
	ld_rrb	a, xde, iy
	pop	xde
	and	a, 3
	xor	w, w
	sla	wa, 2
	ld	iy, wa
	push	xhl
	ld	xhl, 15693615
	ld_rrl	xiy, xhl, iy
	pop	xhl
	call (xiy)
	ld	a, (49122:16)
	and	a, 63
	cp	a, 0:i3
	jrl	nz, 12
	.byte 0xf1, 0x54, 0x0d, 0xb3, 0xf1, 0xf9, 0x10, 0xb1, 0xf1, 0xf9, 0x10, 0xb2
	ret
ScoopDisp_DispatchTable_Extended:
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long VoiceCtrl_CheckAndReset
	.incbin "includes/romslices/v7_transplant_ScoopDisp_DispatchTable_Extended_tail_head.bin"
	ld a, (0x0eee:16)
	ld (0x2877:16), a
	call Scoop_SpecialMode_ParamCheckBound
	res 7, (0x0d54:16)
	ld (0x0d6a:16), 0x00
	ld (0x10fa:16), 0x01
	call ScoopParam_ValueTable_0x1DD
	ld (0x10fa:16), 0x00
	and (0xe31c:16), 0x6f
	ld (0x7ea6:16), 0x23
	xor WA,WA
	ld A, 0xee:opc
	call SoundCtrl_SendCommand
	or (0x8cec:16), 0x01
	ret
	.incbin "includes/romslices/v7_transplant_ScoopDisp_DispatchTable_Extended_tail_tail.bin"
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


Timer_ModeSelect_Table:
	.long Timer_ModeHandler_0
	.long Timer_ModeHandler_1
	.long Timer_ModeHandler_1
	.long Timer_ModeHandler_3
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
	cp	hl, 0:i3
	jrl	nz, 21
	call	UIState_UpdateMultiRegions
	call	MemConfig_Handler_4_0x15B
	call	SeqState_HasModeChanged
	cp	hl, 0:i3
	jrl	nz, 4
	call	DisplayStr_StyleSectionNames_0x69
	ret
Timer_ModeHandler_0:
	call	15717160
	cp	w, 0:i3
	jrl	nz, 9
	call	15710015
	ld	(13964:16), 0
	ret
	ld	xiy, 3411
	.byte 0xb5, 0xc8
	jrl	z, 53
	ld	xiy, 13974
	ld	c, (13939:16)
	dec	1, c
	cp	c, 15
	jrl	ule, 4
	add	iy, 2
	.byte 0xc7, 0x3c, 0x99, 0xd7, 0x3e, 0x9a
	ld	de, (xiy)
	ld	a, c
	scf
	.byte 0xda, 0x2c, 0xc7, 0x3c, 0x89
	ld	(xiy), de
	.byte 0xd7, 0x3e, 0x8a, 0xf1, 0x57, 0x0f, 0xc8
	jrl	nz, 4
	call	15686671
	ret
	call	15713087
	cp	a, 144
	jrl	nz, 163
	.byte 0xc1, 0xb3, 0x28, 0x3e, 0x40
	ld	a, 1:opc
	call	15716493
	call	15672272
	ld	wa, hl
	cp	wa, 65535
	jrl	nz, -13
	call	15701869
	ld	e, (3822:16)
	call	15713280
	ld	(3522:16), a
	call	15713280
	cp	a, (3522:16)
	jrl	z, 2
	jr	106
	call	15713356
	ld	hl, wa
	pushw	hl
	call	15672285
	inc	2, xsp
	call	15713356
	ld	(3522:16), a
	ld	a, 0:opc
	ld	hl, wa
	pushw	hl
	call	15672285
	inc	2, xsp
	call	15713356
	ld	hl, wa
	pushw	hl
	call	15672285
	inc	2, xsp
	ld	a, 64:opc
	ld	hl, wa
	pushw	hl
	call	15672285
	inc	2, xsp
	ld	a, (3822:16)
	dec	1, a
	ld	hl, wa
	pushw	hl
	call	15672285
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
	call	15713447
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	call	15713293
	cp	a, 144
	jr	nz, 4
	jp	15694055
	call	15981353
	ld	a, 1:opc
	call	15716577
	ret
	ld	xhl, 3412
	.byte 0xb3, 0xca
	jrl	z, 119
	.byte 0xb3, 0xb2
	call	15713087
	and	a, 240
	cp	a, 144
	jrl	nz, 104
	call	15701869
	xor	a, a
	call	15716493
	call	15694315
	ld	hl, wa
	pushw	hl
	call	15672285
	inc	2, xsp
	call	15694315
	xor	a, a
	ld	hl, wa
	pushw	hl
	call	15672285
	inc	2, xsp
	call	15694315
	ld	hl, wa
	pushw	hl
	call	15672285
	inc	2, xsp
	call	15694315
	ld	hl, wa
	pushw	hl
	call	15672285
	inc	2, xsp
	ld	a, (3822:16)
	dec	1, a
	ld	hl, wa
	pushw	hl
	call	15672285
	inc	2, xsp
	xor	a, a
	call	15716577
	.byte 0xc1, 0xb3, 0x28, 0x3e, 0x40, 0xc1, 0x54, 0x0f, 0x3e, 0x01
	ld	(3431:16), 0
	call	15981353
	ret
	push	xhl
	call	15713263
	pop	xhl
	ret
Timer_ParamLoadAndCompare:
	ld (0x0dd0:16), 0xff
	call VoiceState_DataBlock2_0x10C
	cp W,0xff
	jrl z, .Lc_ef7a12
	cp c, 2:i3
	jrl ugt, .Lc_ef7a12
	call SysInit_BytecodeBlock_0xC9
	cp (0x7ea6:16), 0x0f
	jrl z, .Lc_ef7a1f
.Lc_ef7a12:
	ld W, 0x00:opc
	call Timer_ParamCompareAlt_0x2A
	bit 5, (0x0d54:16)
	jrl nz, .Lc_ef7a28
.Lc_ef7a1f:
	ld (0x0d55:16), 0xff
	jp Timer_ParamLoadAndCompare_0x44
.Lc_ef7a28:
	ld W, 0x00:opc
	call Timer_ParamCompareAlt_0x2A
	res 5, (0x0d54:16)
	jp Timer_ParamLoadAndCompare_0x2D
	ret
Timer_ParamCompareAlt:
	ld (0x0dd0:16), 0xff
	ld W, 0x01:opc
	call Timer_ParamCompareAlt_0x2A
	bit 5, (0x0d54:16)
	jrl nz, .Lc_ef7a52
	ld (0x0d55:16), 0xff
	jp Timer_ParamCompareAlt_0x29
.Lc_ef7a52:
	ld W, 0x01:opc
	call Timer_ParamCompareAlt_0x2A
	res 5, (0x0d54:16)
	jp Timer_ParamCompareAlt_0x12
	ret
	call	15704071
	xor	a, a
	call	15716493
	.byte 0xd1, 0x7e, 0x36, 0x04, 0xd1, 0x5c, 0x0d, 0x04
	ld	(3522:16), 0
	call	15695078
	ld	(3531:16), a
	ld	a, (3415:16)
	ld	(3521:16), a
	cp	w, 0:i3
	jrl	nz, 4
	jp	15694713
	cp	(3522:16), 0
	jrl	nz, 56
	call	15712720
	cp	w, 255
	jrl	nz, 32
	cp	(3415:16), 0
	jrl	z, 8
	inc	1, (3522:16)
	jp	15694545
	add	xsp, 4
	ld	w, 104:opc
	call	15687771
	jp	15694712
	call	15713087
	cp	a, 129
	jrl	nz, 4
	inc	1, (3522:16)
	call	15695041
	cp	(3522:16), 0
	jrl	z, 12
	cp	(3521:16), 0
	jrl	z, 33
	jp	15694953
	cp	(3521:16), 0
	jrl	nz, 4
	jp	15694991
	call	15695078
	cp	e, a
	jrl	le, 4
	jp	15694953
	jp	15694976
	decw	1, (3418:16)
	add	xsp, 4
	pushw	de
	call	15701395
	popw	de
	xor	a, a
	call	15716493
	.byte 0xd1, 0x7e, 0x36, 0x04, 0xd1, 0x5c, 0x0d, 0x04
	call	15712720
	call	15713087
	cp	a, 129
	jrl	z, 26
	call	15713141
	cp	a, 83
	jrl	le, 16
	cp	a, 95
	jrl	le, 37
	add	xsp, 4
	jp	15694712
	ld	(3415:16), 84
	.byte 0xf1, 0x5c, 0x0d, 0x06, 0xf1, 0x7e, 0x36, 0x06
	xor	a, a
	call	15716577
	call	15699782
	jp	15694712
	jp	15694976
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ld	w, 104:opc
	call	15687771
	ret
	.byte 0xc1, 0x53, 0x0d, 0x3c, 0xfb
	call	15695022
	cp	(3531:16), 255
	jrl	nz, 138
	cp	e, 96
	jrl	nz, 114
	add	xsp, 4
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	15712700
	ld	(3392:16), w
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	cp	(3521:16), 83
	jrl	ule, 17
	.byte 0xc1, 0x53, 0x0d, 0x3e, 0x04
	cp	(3392:16), 255
	jrl	nz, 4
	call	15710728
	ld	(3415:16), 0
	incw	1, (3418:16)
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	15701395
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	call	15695078
	cp	a, 0:i3
	jrl	nz, 12
	ld	(3415:16), a
	call	15699930
	jp	15694952
	ld	(3415:16), 0
	call	15699782
	jp	15694952
	ld	(3415:16), e
	add	xsp, 4
	call	15699782
	jp	15694952
	ld	a, (3531:16)
	cp	a, (3521:16)
	jrl	nz, 32
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	15712700
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	call	15713087
	cp	a, 129
	jrl	z, 27
	call	15695078
	cp	e, a
	jrl	ge, 22
	ld	(3415:16), e
	add	xsp, 4
	call	15699782
	jp	15694952
	jp	15694730
	ld	(3415:16), a
	add	xsp, 4
	call	15699930
	ret
	ld	(3415:16), e
	.byte 0xf1, 0x5c, 0x0d, 0x06, 0xf1, 0x7e, 0x36, 0x06
	xor	a, a
	call	15716577
	call	15699782
	ret
	add	xsp, 4
	ld	(3415:16), a
	call	15699930
	ret
	ld	(3415:16), 0
	add	xsp, 4
	call	15699930
	ret
	add	xsp, 4
	ld	(3415:16), e
	call	15699782
	ret
	pushw	wa
	ld	a, (3521:16)
	xor	w, w
	ld	l, 12:opc
	div8rr	a, l
	inc	1, a
	mul8rr	a, l
	ld	e, a
	popw	wa
	ret
	pushw	wa
	ld	a, (3521:16)
	xor	w, w
	ld	l, 12:opc
	div8rr	a, l
	cp	w, 0:i3
	jrl	nz, 13
	cp	a, 0:i3
	jrl	nz, 6
	ld	a, 7:opc
	jp	15695070
	dec	1, a
	xor	w, w
	mul8rr	a, l
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
	call	15713087
	cp	a, 129
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	jrl	z, 14
	pushw	wa
	call	15713141
	ld	l, a
	popw	wa
	ld	a, l
	jp	15695118
	ld	a, 255:opc
	ret
ToneParam_ModeGuardEntry:
	bit	7, w
	jrl	nz, 111
	cp	(3429:16), 1
	jrl	nz, 103
	call	15703788
	call	15716956
	cp	w, 0:i3
	jrl	nz, 17
	cp	c, 6:i3
	jrl	ugt, 12
	call	15703967
	call	15703747
	jp	15695176
	ld	(3923:16), 0
	call	15698649
	.byte 0xf1, 0x54, 0x0d, 0xb2, 0xc1, 0xd3, 0x0d, 0x3e, 0x01
	call	15699972
	call	15686696
	call	15713087
	cp	a, 129
	jrl	z, 25
	cp	a, 130
	jrl	z, 19
	call	15713141
	cp	a, (3415:16)
	jrl	ugt, 8
	call	15699930
	jp	15695228
	call	15699782
	.byte 0xf1, 0x54, 0x0d, 0xb2
	call	15686621
	ret
	bit	7, w
	jrl	nz, 101
MemConfig_Handler_5:
	.byte 0xf1, 0x54, 0x0d, 0xbb
	call	15713141
	cp	a, 130
	jrl	z, 87
	cp	a, 132
	jrl	z, 81
	call	15713087
	ld	w, a
	and	w, 240
	ld	(3572:16), w
	cp	a, 129
	jrl	z, 66
	cp	a, 132
	jrl	z, 18
	cp	a, 130
	jrl	z, 12
	cp	(3415:16), 48
	jrl	nz, 54
	call	15695447
	.byte 0xc1, 0xec, 0x8c, 0x3e, 0x01
	call	15713087
	cp	a, 144
	jr	nz, 4
	call	15705091
	call	15720788
	call	15699930
	call	15709574
	ld	w, 98:opc
	call	15687771
	xor	w, w
	jp	15695650
	call	15695374
	jp	15695306
	call	15713141
	cp	a, 48
	jrl	nz, -64
	call	15695690
	jp	15695306
	cp	(3415:16), 48
	jrl	z, 13
	call	15695471
	.byte 0xc1, 0xec, 0x8c, 0x3e, 0x01
	jp	15695650
	call	15713141
	cp	a, 130
	jrl	z, -19
	cp	a, 132
	jrl	z, -25
	cp	a, 129
	jrl	nz, 8
	call	15695471
	jp	15695386
	call	15695471
	call	15713141
	cp	a, 48
	jrl	z, -53
	call	15695690
	jp	15695386
	cp	(3572:16), 144
	jrl	nz, 8
	call	15695481
	jp	15695650
	call	15696011
	jp	15695650
	ld	w, 1:opc
	call	15712412
	jp	15695650
	xor	a, a
	call	15716493
	ld	de, 4:i3
	call	15713447
	call	15713087
	ld	(3575:16), a
	call	15713141
	ld	(3576:16), a
	xor	a, a
	call	15716577
	call	15695651
	ld	c, (3576:16)
	xor	b, b
	cp	bc, 0:i3
	jrl	z, 60
	pushw	bc
	call	15713087
	popw	bc
	cp	a, 129
	jrl	z, 39
	pushw	bc
	call	15701665
	cp	b, 22
	jrl	z, 11
	cp	b, 23
	jrl	z, 5
	popw	bc
	jp	15695644
	.byte 0xd1, 0x58, 0x0d, 0x04
	call	15712661
	.byte 0xf1, 0x58, 0x0d, 0x06
	popw	bc
	jp	15695530
	pushw	bc
	call	15695471
	popw	bc
	djnz16	bc, -60
	ld	a, (3575:16)
	cp	(3415:16), 48
	jrl	z, 14
	cp	a, 48
	jrl	nz, 42
	call	15695690
	jp	15695650
	cp	a, 48
	jrl	nz, 28
	call	15713087
	cp	a, 129
	jrl	nz, 18
	call	15695471
	call	15695690
	jp	15695650
	add	xsp, 2
	ret
	call	15713141
	ld	(3523:16), a
	call	15713141
	cp	a, (3523:16)
	jrl	nz, 19
	ld	w, 6:opc
	call	15712412
	call	15713087
	and	a, 240
	cp	a, 144
	jrl	z, -30
	ret
	xor	a, a
	call	15716493
	ld	xiy, 3577
	cp	(3415:16), 48
	jrl	nz, 7
	ld	(xiy), 2
	jp	15695719
	ld	(xiy), 1
	call	15713087
	cp	a, 132
	jrl	z, 24
	cp	a, 130
	jrl	z, 18
	cp	(3577:16), 1
	jrl	z, 20
	call	15695889
	cp	w, 255
	jrl	nz, -34
	xor	a, a
	call	15716577
	jp	15695995
	call	15695777
	cp	w, 255
	jrl	nz, -54
	jp	15695753
	cp	a, 129
	jrl	z, 33
	bit	7, a
	jrl	z, 27
	call	15713141
	cp	a, 48
	jrl	z, 25
	cp	a, 47
	jrl	z, 39
	cp	a, 95
	jrl	z, 23
	cp	a, 0:i3
	jrl	z, 38
	call	15712661
	jp	15695995
	xor	w, w
	call	15695985
	jp	15695816
	ld	w, 47:opc
	call	15695985
	jp	15695816
	ld	w, 95:opc
	call	15695985
	jp	15695816
	ld	(3577:16), 2
	ld	a, 1:opc
	call	15716493
	ld	w, 48:opc
	call	15695985
	ld	a, 1:opc
	call	15716577
	call	15712713
	call	15695471
	jp	15695816
	cp	a, 129
	jrl	z, 33
	bit	7, a
	jrl	z, 27
	call	15713141
	cp	a, 0:i3
	jrl	z, 26
	cp	a, 47
	jrl	z, 40
	cp	a, 95
	jrl	z, 24
	cp	a, 48
	jrl	z, 38
	call	15712661
	jp	15695995
	ld	w, 48:opc
	call	15695985
	jp	15695928
	ld	w, 47:opc
	call	15695985
	jp	15695928
	ld	w, 95:opc
	call	15695985
	jp	15695928
	ld	(3577:16), 1
	call	15710751
	xor	w, w
	call	15695985
	jp	15695928
	pushw	wa
	call	15713263
	popw	wa
	call	15713395
	ret
ToneParam_ShortCallHandler:
	call	ToneParam_Evt09_BytecodeHandler
	call	UIState_UpdateMultiRegions
	ret
ToneParam_Evt09_BytecodeHandler:
	bit 0x07,W
	jrl nz, .Lc_ef80e6
	call ToneParam_HandlerTable_BC_0x10
	cp w, 1:i3
	jrl z, .Lc_ef80bb
	call VoiceState_DataBlock2_0x20B
	cp w, 1:i3
	jrl z, .Lc_ef80bb
	call VoiceCtrl_BytecodeHandler
	cp B,0xff
	jrl nz, .Lc_ef80ea
.Lc_ef80a7:
	call VoiceSlot_FlagCheck
	cp a, (0x0d57:16)
	jrl nz, .Lc_ef80e6
	call ToneParam_HandlerTable_BC_0x4DC
	ld (0x7ea6:16), 0xff
.Lc_ef80bb:
	or (0x0dd3:16), 0x01
	ld l, (0x0d65:16)
	and HL,0x0003
	sla HL, 0x02
	push XIX
	ld XIX,ToneParam_HandlerTable_BC
	ldl_dri xhl, 0x07, 0xf0, 0xec
	pop XIX
	call (XHL)
	call PortConfig_Handler_0_0xD7
	res 2, (0x0d54:16)
	or (0x8cec:16), 0x01
.Lc_ef80e6:
	jp ToneParam_Evt09_BytecodeHandler_0xCF
.Lc_ef80ea:
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
	call ToneParam_HandlerTable_BC_0x4DC
	ld (0x7ea6:16), 0xff
.Lc_ef8115:
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
	ld A, 0x01:opc
	call VoiceSlot_RestoreState
	jp ToneParam_Evt09_BytecodeHandler_0x36
.Lc_ef814a:
	add XSP,0x00000002
	jp ToneParam_Evt09_BytecodeHandler_0xBB
	ret
ToneParam_HandlerTable_BC:
	.long DefaultHandler_Ret
	.long VoiceSlot_TableSetup
	.long VoiceSlot_TableSetup
	.long DefaultHandler_Ret
	cp (0x0d65:16), 0x03
	jrl z, .Lc_ef8173
.Lc_ef816d:
	ld W, 0x00:opc
	jp ToneParam_HandlerTable_BC_0x9E
.Lc_ef8173:
	call ToneParam_HandlerTable_BC_0x269
	cp W,0xff
	jrl z, .Lc_ef816d
	call ToneParam_HandlerTable_BC_0x2D4
	cp w, 0:i3
	jrl nz, .Lc_ef8192
	ld W, 0x68:opc
	call MIDI_SendSysExFromW
	ld W, 0x01:opc
	jp ToneParam_HandlerTable_BC_0x9E
.Lc_ef8192:
	ld a, (0x0e3f:16)
	ld (0x0e41:16), a
	call ToneParam_HandlerTable_BC_0x1A2
	ld a, (0x0e3f:16)
	ld (0x0e40:16), a
	cp a, (0x0e41:16)
	jrl nz, .Lc_ef81b1
	jp ToneParam_HandlerTable_BC_0x18
.Lc_ef81b1:
	ld wa, (0x0d5a:16)
	cp wa, (0x0d6b:16)
	jrl c, .Lc_ef81dd
	call ToneParam_HandlerTable_BC_0x4DC
	ld a, (0x0e40:16)
	cp a, (0x0e41:16)
	jrl c, .Lc_ef81d3
	call ToneParam_HandlerTable_BC_0x2EB
	jp ToneParam_HandlerTable_BC_0x82
.Lc_ef81d3:
	call ToneParam_HandlerTable_BC_0x357
	ld W, 0x01:opc
	jp ToneParam_HandlerTable_BC_0x9E
.Lc_ef81dd:
	and (0xe31c:16), 0x6f
	ld (0x7ea6:16), 0x19
	xor WA,WA
	ld A, 0xee:opc
	call SoundCtrl_SendCommand
	jp ToneParam_HandlerTable_BC_0x82
	ret
	.incbin "includes/romslices/v7_transplant_ToneParam_HandlerTable_BC_tail_head_tail_head.bin"
	ld A, 0x03:opc
	call VoiceSlot_SaveState
.Lc_ef82fd:
	call VoiceSlot_CompareAndBranch_0x7
	cp W,0xff
	jrl z, .Lc_ef8314
	call ToneParam_HandlerTable_BC_0x269
	cp w, 0:i3
	jrl nz, .Lc_ef82fd
	jp ToneParam_HandlerTable_BC_0x1C4
.Lc_ef8314:
	ld (0x0e3f:16), 0x04
	ld A, 0x03:opc
	call VoiceSlot_RestoreState
	ret
	.incbin "includes/romslices/v7_transplant_ToneParam_HandlerTable_BC_tail_head_tail_mid1.bin"
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
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	ld A, 0x01:opc
	call VoiceSlot_SaveState
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
	call SysInit_BytecodeBlock_0xFF
	djnz16 bc, .Lc_ef8480
	jp ToneParam_HandlerTable_BC_0x2F8
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
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	ld A, 0x01:opc
	call VoiceSlot_SaveState
	xor A,A
	ld (0x0e43:16), a
.Lc_ef84bf:
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
	jp ToneParam_HandlerTable_BC_0x36A
.Lc_ef84f0:
	inc 1, (0x0e43:16)
	call MemConfig_Handler_5_0xE4
	ld a, (0x0e41:16)
	sub a, (0x0e40:16)
	cp a, (0x0e43:16)
	jrl ugt, .Lc_ef84bf
	xor B,B
	ld c, (0x0e40:16)
.Lc_ef850d:
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
	jp ToneParam_HandlerTable_BC_0x364
.Lc_ef8536:
	and A,0xf0
	cp A,0xc0
	jrl z, .Lc_ef8549
	pushw bc
	call VoiceSlot_DispatchRet
	popw bc
	jp ToneParam_HandlerTable_BC_0x3B8
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
	.incbin "includes/romslices/v7_transplant_ToneParam_HandlerTable_BC_tail_head_tail_tail_tail.bin"
	xor A,A
	call VoiceSlot_SaveState
	call VoiceSlot_DispatchRet
	xor A,A
	call VoiceSlot_RestoreState
	ld w, (0x0dcc:16)
	call VoiceSlot_RetZ
	ret
	or (0xe31c:16), 0x08
	ld hl, (0x0d5a:16)
.Lc_ef8653:
	push XHL
	call AccPedal_CheckBitAndUpdate
.Lc_ef8658:
	call Timer_ParamCompareAlt
	xor A,A
	.incbin "includes/romslices/v7_transplant_ToneParam_HandlerTable_BC_tail_mid1.bin"
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
	call DisplayMode_Handler_3_0x30C
	res 2, (0x0d54:16)
	ld (0x0d55:16), 0xff
.Lc_ef86bb:
	ret
	call Display_UpdateRegion0
	call Display_UpdateRegion1
	call Display_UpdateRegion4
	call Display_UpdateRegion3
	call Display_UpdateRegion2
	ret
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
	call VoiceSlot_CompareAndBranch_0x7
	jp ToneParam_HandlerTable_BC_0x5A6
.Lc_ef86f7:
	call VoiceSlot_DispatchRet
	cp W,0xff
	jrl z, .Lc_ef8717
	call VoiceSlot_ReadCurrentParams
	popw bc
	cp A,0x81
	jrl nz, .Lc_ef86d6
	djnz16 bc, .Lc_ef86d6
.Lc_ef870f:
	ld W, 0x00:opc
	jp ToneParam_HandlerTable_BC_0x5C3
.Lc_ef8715:
	ld W, 0x00:opc
.Lc_ef8717:
	popw bc
	ret
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
	jrl	nz, 82
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


DisplayMode_DispatchTable:
	.long DefaultHandler_Ret
	.long DisplayMode_Handler_1
	.long DisplayMode_Handler_2
	.long DisplayMode_Handler_3
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
	call	15724415
	ld	(13964:16), 0
	call	15724565
	ret
	call VoiceSlot_ReadCurrentParams
	cp A,0x81
	jrl z, .Lc_ef8807
	cp A,0x82
	jrl z, .Lc_ef8807
	call VoiceSlot_FlagCheck
	cp a, (0x0d57:16)
	jrl ugt, .Lc_ef8807
	call DMA_FlagCheckWithCalls
	jp DisplayMode_Handler_3_0x3A
.Lc_ef8807:
	call DisplayMode_Handler_3_0x775
	.byte 0xf1, 0x54, 0x0d, 0xb2, 0x0e
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
	.byte 0xc1, 0xd3, 0x0d, 0x3e, 0x01
	call	15713087
	ld	w, a
	and	w, 240
	cp	w, 128
	jrl	z, 2
	ld	a, w
	ld	(3537:16), a
	call	15717147
	ld	e, a
	and	e, 240
	cp	(3413:16), 255
	jrl	z, 63
	cp	(3413:16), a
	jrl	z, 68
	cp	(3413:16), 210
	jrl	z, 38
	call	15717110
	call	15717160
	cp	w, 255
	jrl	nz, -46
	.byte 0xf1, 0x53, 0x0d, 0xcc
	jrl	nz, 0
	.byte 0xc1, 0x53, 0x0d, 0x3c, 0xef
	cp	(3413:16), 255
	jrl	nz, 0
	jp	15698233
	cp	a, 209
	jrl	z, 16
	jp	15698026
	cp	a, (3536:16)
	jrl	z, -55
	ld	(3536:16), 255
	cp	a, 209
	jrl	z, 107
	cp	a, 210
	jrl	z, 118
	cp	a, 128
	jrl	z, 62
	cp	a, 133
	jrl	z, 73
	cp	a, 134
	jrl	z, 75
	cp	e, 144
	jrl	z, 20
	cp	e, 176
	jrl	z, 22
	cp	e, 192
	jrl	z, 24
	call	15717110
	jp	15698030
	call	15698234
	jp	15698030
	call	15701942
	jp	15698030
	call	15702863
	jp	15698030
	call	16355597
	cp	hl, 0:i3
	jrl	nz, -41
	call	15703188
	jp	15698030
	call	15703330
	jp	15698030
	call	15703318
	jp	15698030
	call	16355597
	cp	hl, 0:i3
	jrl	nz, -74
	call	15703518
	jp	15698030
	call	16355597
	cp	hl, 0:i3
	jrl	nz, -91
	call	15703626
	jp	15698030
	ret
	call	15704071
	cp	(3429:16), 1
	jrl	z, 10
	call	15672446
	ld	wa, hl
	jp	15698492
	call	15698493
	.byte 0xf1, 0x54, 0x0d, 0xc9
	jrl	z, -15
	call	15703788
	.byte 0xf1, 0x54, 0x0d, 0xb1
	ld	e, (3541:16)
	xor	d, d
	ld	xiy, 3542
	xor	hl, hl
	ld	xix, 3471
	ld	a, (3558:16)
	ld	(xix), a
	ld	a, (3415:16)
	ld	(xix+1), a
	ld_rrb a, xiy, hl
	ld	(xix+2), a
	pushw	wa
	call	15713930
	srl	xiz, 1
	popw	wa
	push	xix
	ld	xix, 61856
	.byte 0xc3, 0x07, 0xf0, 0xf8, 0x3f, 0x0c
	pop	xix
	jrl	nz, 19
	.byte 0xf1, 0xad, 0xfd, 0xca
	jrl	z, 4
	jp	15698358
	ld	w, (64316:16)
	call	15687414
	ld	(13948:16), a
	ldfr_lerp	xiy, 56
	lda_rr	xiy, xiy, hl
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
	jrl	nz, -115
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
	call	15711654
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ld	(3541:16), 0
	call	15716956
	cp	w, 0:i3
	jrl	nz, 22
	cp	c, 6:i3
	jrl	ugt, 17
	call	15703967
	call	15703747
	ld	(3422:16), 16
	jp	15698492
	ld	(3923:16), 0
	call	15698649
	.byte 0xf1, 0x54, 0x0d, 0xb2
	ret
	call	15672446
	ld	wa, hl
	ld	(3558:16), a
	call	15672446
	call	15672446
	ld	wa, hl
	ld	(13201:16), a
	call	15672446
	ld	wa, hl
	ld	(13202:16), a
	call	15672446
	ld	wa, hl
	cp	(13202:16), 0
	jrl	nz, 4
	jp	15698618
	.byte 0xc1, 0xd3, 0x0d, 0x3c, 0xfe
	push	xhl
	push	xiy
	ld	l, (3540:16)
	cp	l, 7:i3
	jrl	ugt, 51
	xor	h, h
	ld	xiy, 3542
	ld	a, (13201:16)
	st_rrb	a, xiy, hl
	ld	a, (13202:16)
	ldfr_lerp	xiy, 56
	lda_rr	xiy, xiy, hl
	ld	(xiy+8), a
	ldto_lerp	xiy, 56
	inc	1, l
	ld	(3540:16), l
	cp	l, (3541:16)
	jrl	ule, 4
	ld	(3541:16), l
	pop	xiy
	pop	xhl
	jp	15698648
	ld	a, (3540:16)
	dec	1, a
	cp	a, 255
	jrl	z, 18
	ld	(3540:16), a
	cp	a, 0:i3
	jrl	nz, 9
	.byte 0xf1, 0x54, 0x0d, 0xb9, 0xc1, 0xd3, 0x0d, 0x3e, 0x01
	ret
	call	15703980
	ld	l, (3533:16)
	xor	h, h
	add hl, (3418:16)
	cp hl, (3418:16)
	jrl	z, 18
	push	xhl
	call	15694322
	pop	xhl
	cp	(32422:16), 15
	jrl	z, 46
	jp	15698663
	ld	l, (3534:16)
	.byte 0xc1, 0x53, 0x0d, 0x3c, 0xfb
	ld	h, (3415:16)
	cp	h, 0:i3
	jrl	nz, 9
	.byte 0xf1, 0x53, 0x0d, 0xca
	jrl	z, 2
	ld	h, 96:opc
	cp	l, h
	jrl	le, 10
	push	xhl
	call	15694322
	pop	xhl
	jp	15698697
	cp	h, 96
	jrl	nz, 14
	decw	1, (3418:16)
	push	xhl
	call	15712720
	call	15701395
	pop	xhl
	ld	(3415:16), l
	ret
	bit	7, w
	jrl	nz, 8
	call	15698774
	jp	15698773
	call	15698784
	ret
	ld	(3570:16), 1
	call	15698794
	ret
	ld	(3570:16), 255
	call	15698794
	ret
	call	15716956
	cp	w, 0:i3
	jrl	z, 146
	cp	(3429:16), 1
	jrl	nz, 138
	call	15713087
	and	a, 240
	cp	a, 144
	jrl	nz, 125
	call	15713141
	cp	a, (3415:16)
	jrl	nz, 114
	xor	a, a
	call	15716493
	ld	de, 2:i3
	call	15713447
	call	15713087
	call	15698950
	ld	w, a
	ld	l, w
	add	a, (3570:16)
	bit	7, a
	jrl	z, 2
	ld	a, w
	ld	(13948:16), a
	pushw	hl
	call	15698995
	popw	hl
	call	15713930
	sra	iz, 1
	push	xde
	ld	xde, 61856
	.byte 0xc3, 0x07, 0xe8, 0xf8, 0x3f, 0x0c
	pop	xde
	jrl	nz, 20
	.byte 0xf1, 0xad, 0xfd, 0xca
	jrl	z, 13
	cp	a, 0:i3
	jrl	nz, 8
	ld	(13948:16), l
	jp	15698930
	ld	w, a
	call	15713395
	xor	a, a
	call	15716577
	call	15726605
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	call	15686621
	ret
	pushw	wa
	call	15713930
	srl	xiz, 1
	popw	wa
	push	xix
	ld	xix, 61856
	.byte 0xc3, 0x07, 0xf0, 0xf8, 0x3f, 0x0c
	pop	xix
	jrl	nz, 19
	.byte 0xf1, 0xad, 0xfd, 0xca
	jrl	z, 4
	jp	15698994
	ld	w, (64316:16)
	call	15687414
	ret
	pushw	wa
	call	15713930
	srl	xiz, 1
	popw	wa
	push	xix
	ld	xix, 61856
	.byte 0xc3, 0x07, 0xf0, 0xf8, 0x3f, 0x0c
	pop	xix
	jrl	nz, 19
	.byte 0xf1, 0xad, 0xfd, 0xca
	jrl	z, 4
	jp	15699039
	ld	w, (64316:16)
	call	15687441
	ret
	ldw (0x0ef0:16), 0x0001
	ld (0x0df3:16), 0x02
	call DisplayMode_Handler_3_0x4C9
	call Display_BytecodeBlock_F_0x2A2
	call Display_UpdateRegion3
	or (0xe31c:16), 0x08
	ret
	ldw (0x0ef0:16), 0xffff
	ld (0x0df3:16), 0x02
	call DisplayMode_Handler_3_0x4C9
	call Display_BytecodeBlock_F_0x2A2
	call Display_UpdateRegion3
	or (0xe31c:16), 0x08
	ret
	.byte 0x1d, 0x5c, 0xd2, 0xef, 0xc8, 0xd8, 0x76, 0x8b
	.byte 0x00, 0x1d, 0x3f, 0xc3, 0xef, 0xc9, 0xcc, 0xf0
	.byte 0xc9, 0xcf, 0x80, 0x7e, 0x7e, 0x00, 0xc9, 0xd1
	.byte 0x1d, 0x8d, 0xd0, 0xef, 0xc1, 0xf3, 0x0d, 0x25
	.byte 0xcc, 0xd4, 0x1d, 0xa7, 0xc4, 0xef, 0x1d, 0x3f
	.byte 0xc3, 0xef, 0xc9, 0x8b, 0x29, 0x1d, 0x75, 0xc3
	.byte 0xef, 0xc9, 0x8f, 0xc9, 0xe9, 0x01, 0xc9, 0xcc
	.byte 0x81, 0x49, 0xcb, 0xcc, 0x7f, 0xc9, 0x88, 0xc9
	.byte 0xcc, 0x80, 0xcb, 0xe1, 0xc8, 0xcc, 0x01, 0xd8
	.byte 0x89, 0xd1, 0xf0, 0x0e, 0x80, 0xd8, 0xcf, 0x28
	.byte 0x00, 0x7f, 0x06, 0x00, 0xd9, 0x88, 0x1b, 0xfd
	.byte 0x8c, 0xef, 0xd8, 0xcf, 0x2c, 0x01, 0x73, 0x02
	.byte 0x00, 0xd9, 0x88, 0xf1, 0xf2, 0x0e, 0x50, 0xd8
	.byte 0x89, 0xc9, 0xcc, 0x7f, 0xc9, 0x88, 0x29, 0x1d
	.byte 0x73, 0xc4, 0xef, 0x1d, 0xef, 0xc3, 0xef, 0x49
	.byte 0xcb, 0x89, 0xc9, 0xcc, 0x80, 0xc9, 0xe8, 0x01
	.byte 0xca, 0xcc, 0x01, 0xca, 0xec, 0x01, 0xca, 0xe1
	.byte 0xc9, 0x88, 0x1d, 0x73, 0xc4, 0xef, 0xc9, 0xd1
	.byte 0x1d, 0xe1, 0xd0, 0xef, 0x0e, 0xf1, 0xf2, 0x0d
	.byte 0x00, 0x01, 0xf1, 0xf3, 0x0d, 0x00, 0x02, 0x1d
	.byte 0x3f, 0xc3, 0xef, 0xc9, 0x8f, 0xc9, 0xcc, 0xf0
	.byte 0xc9, 0xcf, 0xd0, 0x7e, 0x37, 0x00, 0x2b, 0x1d
	.byte 0x75, 0xc3, 0xef, 0x4b, 0xc1, 0x57, 0x0d, 0xf1
	.byte 0x7e, 0x2a, 0x00, 0x3b, 0x43, 0x85, 0x36, 0x00
	.byte 0x00, 0xf1, 0x0e, 0x11, 0x63, 0x5b, 0xcf, 0xcf
	.byte 0xd2, 0x7e, 0x08, 0x00, 0x1d, 0xb0, 0x8e, 0xef
	.byte 0x1b, 0x72, 0x8d, 0xef, 0x1d, 0x72, 0x8e, 0xef
	.byte 0x1d, 0x96, 0xf2, 0xef, 0x1d, 0xdd, 0x5b, 0xef
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08, 0x0e, 0xf1, 0xf2
	.byte 0x0d, 0x00, 0xff, 0xf1, 0xf3, 0x0d, 0x00, 0x02
	.byte 0x1d, 0x3f, 0xc3, 0xef, 0xc9, 0x8f, 0xc9, 0xcc
	.byte 0xf0, 0xc9, 0xcf, 0xd0, 0x7e, 0x37, 0x00, 0x2b
	.byte 0x1d, 0x75, 0xc3, 0xef, 0x4b, 0xc1, 0x57, 0x0d
	.byte 0xf1, 0x7e, 0x2a, 0x00, 0x3b, 0x43, 0x85, 0x36
	.byte 0x00, 0x00, 0xf1, 0x0e, 0x11, 0x63, 0x5b, 0xcf
	.byte 0xcf, 0xd2, 0x7e, 0x08, 0x00, 0x1d, 0xb0, 0x8e
	.byte 0xef, 0x1b, 0xc3, 0x8d, 0xef, 0x1d, 0x72, 0x8e
	.byte 0xef, 0x1d, 0x96, 0xf2, 0xef, 0x1d, 0xdd, 0x5b
	.byte 0xef, 0xc1, 0x1c, 0xe3, 0x3e, 0x08, 0x0e, 0xc8
	.byte 0x33, 0x07, 0x7e, 0x08, 0x00, 0x1d, 0xe4, 0x8d
	.byte 0xef, 0x1b, 0xe3, 0x8d, 0xef, 0x1d, 0x2b, 0x8e
	.byte 0xef, 0x0e, 0xf1, 0xf2, 0x0d, 0x00, 0x01, 0xf1
	.byte 0xf3, 0x0d, 0x00, 0x03, 0xc1, 0x65, 0x0d, 0x3f
	.byte 0x01, 0x7e, 0x34, 0x00, 0x1d, 0x3f, 0xc3, 0xef
	.byte 0xc9, 0xcc, 0xf0, 0xc9, 0xcf, 0x90, 0x7e, 0x27
	.byte 0x00, 0x1d, 0x75, 0xc3, 0xef, 0xc1, 0x57, 0x0d
	.byte 0xf1, 0x7e, 0x1c, 0x00, 0x3b, 0x43, 0x7b, 0x36
	.byte 0x00, 0x00, 0xf1, 0x0e, 0x11, 0x63, 0x5b, 0x1d
	.byte 0x72, 0x8e, 0xef, 0x1d, 0x0d, 0xf8, 0xef, 0xc1
	.byte 0x1c, 0xe3, 0x3e, 0x08, 0x1d, 0xdd, 0x5b, 0xef
	.byte 0x0e, 0xf1, 0xf2, 0x0d, 0x00, 0xff, 0xf1, 0xf3
	.byte 0x0d, 0x00, 0x03, 0xc1, 0x65, 0x0d, 0x3f, 0x01
	.byte 0x7e, 0x34, 0x00, 0x1d, 0x3f, 0xc3, 0xef, 0xc9
	.byte 0xcc, 0xf0, 0xc9, 0xcf, 0x90, 0x7e, 0x27, 0x00
	.byte 0x1d, 0x75, 0xc3, 0xef, 0xc1, 0x57, 0x0d, 0xf1
	.byte 0x7e, 0x1c, 0x00, 0x3b, 0x43, 0x7b, 0x36, 0x00
	.byte 0x00, 0xf1, 0x0e, 0x11, 0x63, 0x5b, 0x1d, 0x72
	.byte 0x8e, 0xef, 0x1d, 0x0d, 0xf8, 0xef, 0xc1, 0x1c
	.byte 0xe3, 0x3e, 0x08, 0x1d, 0xdd, 0x5b, 0xef, 0x0e
	.byte 0x1d, 0x5c, 0xd2, 0xef, 0xc8, 0xd8, 0x76, 0x34
	.byte 0x00, 0xc9, 0xd1, 0x1d, 0x8d, 0xd0, 0xef, 0xc1
	.byte 0xf3, 0x0d, 0x25, 0xcc, 0xd4, 0x1d, 0xa7, 0xc4
	.byte 0xef, 0x1d, 0x3f, 0xc3, 0xef, 0xc9, 0x88, 0xc1
	.byte 0xf2, 0x0d, 0x81, 0xc9, 0x33, 0x07, 0x76, 0x02
	.byte 0x00, 0xc8, 0x89, 0xe1, 0x0e, 0x11, 0x23, 0xb3
	.byte 0x41, 0xc9, 0x88, 0x1d, 0x73, 0xc4, 0xef, 0xc9
	.byte 0xd1, 0x1d, 0xe1, 0xd0, 0xef, 0x0e, 0x1d, 0x5c
	.byte 0xd2, 0xef, 0xc8, 0xd8, 0x76, 0x8c, 0x00, 0xc9
	.byte 0xd1, 0x1d, 0x8d, 0xd0, 0xef, 0xc1, 0xf3, 0x0d
	.byte 0x25, 0xcc, 0xd4, 0x1d, 0xa7, 0xc4, 0xef, 0x1d
	.byte 0x3f, 0xc3, 0xef, 0xf1, 0x85, 0x36, 0x41, 0x1d
	.byte 0x75, 0xc3, 0xef, 0xf1, 0x12, 0x11, 0x41, 0xc9
	.byte 0x88, 0xc1, 0x85, 0x36, 0x21, 0xc9, 0xcc, 0x7f
	.byte 0xc8, 0xcc, 0x7f, 0xc8, 0xe9, 0x01, 0xc8, 0x8d
	.byte 0xc8, 0xcc, 0x7f, 0xcd, 0xcc, 0x80, 0xcd, 0xe1
	.byte 0xd8, 0x89, 0xda, 0xd2, 0xc1, 0xf2, 0x0d, 0x25
	.byte 0xda, 0x13, 0xda, 0x80, 0xd8, 0xcf, 0xff, 0x3f
	.byte 0x7a, 0x3a, 0x00, 0xd8, 0xd8, 0x71, 0x35, 0x00
	.byte 0xc8, 0x33, 0x07, 0x76, 0x02, 0x00, 0xd9, 0x88
	.byte 0xd8, 0x89, 0xc9, 0xcc, 0x7f, 0xf1, 0x85, 0x36
	.byte 0x41, 0xcb, 0xe8, 0x01, 0xcb, 0xcc, 0x01, 0xc8
	.byte 0xec, 0x01, 0xc8, 0xcc, 0x7e, 0xc8, 0xe3, 0xf1
	.byte 0x12, 0x11, 0x43, 0xc9, 0x88, 0x29, 0x1d, 0x73
	.byte 0xc4, 0xef, 0x1d, 0xef, 0xc3, 0xef, 0x49, 0xcb
	.byte 0x88, 0x1d, 0x73, 0xc4, 0xef, 0xc9, 0xd1, 0x1d
	.byte 0xe1, 0xd0, 0xef, 0x0e, 0xf1, 0x57, 0x0f, 0xc8
	.byte 0x7e, 0x1a, 0x00, 0xc1, 0x65, 0x0d, 0x27, 0xcf
	.byte 0xcc, 0x03, 0xce, 0xd6, 0xdb, 0xec, 0x02, 0x3c
	.byte 0x44, 0x68, 0x8f, 0xef, 0x00, 0xe3, 0x07, 0xf0
	.byte 0xec, 0x23, 0x5c, 0xb3, 0xe8, 0x0e
DMA_ChannelSelect_Table:
	.long DMA_ChannelHandler_0
	.long DMA_ChannelHandler_1
	.long DMA_ChannelHandler_2
	.long DMA_ChannelHandler_3
DMA_ChannelHandler_1:
	.byte 0xf1, 0x7b, 0x36, 0x00, 0xff, 0xc1, 0xef, 0x0d
	.byte 0x3f, 0x00, 0x7e, 0x08, 0x00, 0x1d, 0x1e, 0xf1
	.byte 0xef, 0x1b, 0x96, 0x8f, 0xef, 0xf1, 0xef, 0x0d
	.byte 0x00, 0x00, 0x1d, 0x1a, 0xf1, 0xef, 0x0e
DMA_ChannelHandler_2:
	.byte 0xc1, 0xef
	decf
	push	xsp
	ldio	126, 8
	nop
	call	DisplayStr_TempoString_0x36
	jp	DMA_ChannelHandler_2_0x19
	ld	(3567:16), 8
	call	DisplayStr_TempoString_0x32
	ret
DMA_ChannelHandler_0:
	ld	(13964:16), 0
	call	15724622
	ret
DMA_ChannelHandler_3:
	; --- Conditional init (31 bytes) ---
	cp	(3567:16), 15
	jrl z, DMA_Channel3_CallAndInit
	ld	(3567:16), 15
	call DisplayStr_TempoString_0x6F
DMA_Channel3_CallAndInit:
	call	15724420
	ld	(13964:16), 0
	call	15724565
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
	jp VoiceSlot_TableSetup_0xF
.Lc_ef900f:
	jp VoiceSlot_TableSetup_0x106
	and (0x0dd3:16), 0xfe
	call AccPedal_CheckBitAndUpdate
	call VoiceState_DataBlock2_0x472
	xor A,A
	call VoiceSlot_SaveState
	call VoiceSlot_TableSetup_0x107
	ld (0x0dcf:16), 0x01
	call ToneParam_HandlerTable_BC_0x57C
	call VoiceState_DataBlock2_0xAD
	cp w, 0:i3
	jrl nz, .Lc_ef904e
	call VoiceSlot_ReadCurrentParams
	cp A,0x81
	jrl nz, .Lc_ef906a
	dec 1, (0x0de7:16)
	jp VoiceSlot_TableSetup_0x66
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
	ld a, (0x0eee:16)
	dec 1,A
	xor W,W
	ld HL,WA
	push XIX
	ld XIX,0x00000cbe
	ldb_dri a, 0x07, 0xf0, 0xec
	ld (0x0dec:16), a
	sla HL, 0x01
	ld XIX,0x00000c9e
	ldw_dri wa, 0x07, 0xf0, 0xec
	ld (0x0de8:16), wa
	pop XIX
	ld c, (0x0de7:16)
	xor B,B
	ld (0x0dcf:16), 0x00
	call ToneParam_HandlerTable_BC_0x57C
	ld a, (0x0eee:16)
	dec 1,A
	xor W,W
	ld HL,WA
	push XIX
	ld XIX,0x00000cbe
	ldb_dri a, 0x07, 0xf0, 0xec
	ld (0x0ded:16), a
	sla HL, 0x01
	ld XIX,0x00000c9e
	ldw_dri wa, 0x07, 0xf0, 0xec
	ld (0x0dea:16), wa
	pop XIX
	call VoiceSlot_TableSetup_0x12C
	call DisplayStr_StyleSectionNames_0x69
	call Display_UpdateRegion5
	ld wa, (0x367e:16)
	cp WA,0x03e8
	jrl c, .Lc_ef90e9
	ldw WA, 0x03e8
.Lc_ef90e9:
	ld (0x0e4e:16), wa
	xor A,A
	call VoiceSlot_RestoreState
	call VoiceSlot_TableSetup_0x2E0
	call VoiceSlot_TableSetup_0x40F
	call Display_UpdateRegion1
	bit 0, (0x0f57:16)
	jrl nz, .Lc_ef910a
	call Display_UpdateRegion4
.Lc_ef910a:
	ret
	ld c, (0x0d5c:16)
	ld a, (0x0d5d:16)
	cp a, 4:i3
	jrl ugt, .Lc_ef911c
	jp VoiceSlot_TableSetup_0x127
.Lc_ef911c:
	sub A,0x04
	cp c, 3:i3
	jrl ugt, .Lc_ef9128
	jp VoiceSlot_TableSetup_0x127
.Lc_ef9128:
	sub C,0x04
	inc 1,C
	xor B,B
	ret
	.incbin "includes/romslices/v7_transplant_VoiceSlot_TableSetup_head_tail_mid0.bin"
	ld l, (0x0d60:16)
	dec 1,L
	ld H,L
	sla L, 0x01
	add L,H
	xor H,H
	push XDE
	ld XDE,0x0000f250
	.incbin "includes/romslices/v7_transplant_VoiceSlot_TableSetup_head_tail_mid1.bin"
	ld l, (0x0d60:16)
	dec 1,L
	ld H,L
	sla L, 0x01
	add L,H
	xor H,H
	push XDE
	ld XDE,0x0000f250
	.incbin "includes/romslices/v7_transplant_VoiceSlot_TableSetup_head_tail_tail.bin"
	or (0xe31c:16), 0x08
	call AccPedal_CheckBitAndUpdate
.Lc_ef9545:
	call Timer_ParamLoadAndCompare
	xor A,A
	.incbin "includes/romslices/v7_transplant_VoiceSlot_TableSetup_mid1.bin"
	or (0xe31c:16), 0x08
	call AccPedal_CheckBitAndUpdate
.Lc_ef957a:
	call Timer_ParamCompareAlt
	xor A,A
	.incbin "includes/romslices/v7_transplant_VoiceSlot_TableSetup_tail.bin"
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
	jrl	nz, 107
	call	VoiceSlot_FinalRetZ
	and	a, 3
	ld	(3528:16), a
	call	VoiceSlot_FinalRetZ
	call	VoiceSlot_FinalRetZ
	cp	a, 72
	jrl	nz, 82
	call	VoiceSlot_FinalRetZ
	ldb_erp a, 56
	cp a, 6:i3
	jrl	z, 5
	cp	a, 5:i3
	jrl	nz, 65
	call	VoiceSlot_FinalRetZ
	ld	(3527:16), a
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
	ld	c, 7:opc
	ldb_erp a, 60
	ldb_erp a, 61
	ld a, c
	scf
	xorcfb_erp 61
	stb_erp a, 60
	jrl	nc, 23
	cp	c, 0:i3
	jrl	z, 6
	dec	1, c
	jp	VoiceCtrl_BytecodeHandler_0x61
	ld	b, 255:opc
	ld	a, 2:opc
	call	VoiceSlot_RestoreState
	jp	VoiceCtrl_BytecodeHandler_0xB9
	ld	b, c
	ldb_erp a, 60
	ld a, c
	scf
	.byte 0xf1, 0xc7
	decf
	pushw	de
	stb_erp a, 60
	jrl	c, 13
	cpib_erp 56, 6
	jrl nz, -34
	add	b, 8
	jp	VoiceCtrl_BytecodeHandler_0x80
	cpib_erp 56, 6
	jrl nz, 3
	add	b, 8
	set	4, b
	jp	VoiceCtrl_BytecodeHandler_0x9C
	ret
VoiceCtrl_CheckAndReset:
	.byte 0xc1, 0x53
VoiceCtrl_CheckAndReset_Code:
	decf	
	push	xiz
	ld	w, 193:opc
	add	(xix), xix
	push	xsp
	nop	
	jrl	z, 4
	call	15701869
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
	jrl	nz, 8
	call	15717110
	jp	15702183
	xor	a, a
	ld	(3569:16), a
	ld	(13956:16), a
	ld	xiy, 3471
	call	15672446
	ld	wa, hl
	ld	(xiy), a
	ld	w, a
	and	w, 3
	ld	(3529:16), w
	call	15672446
	ld	wa, hl
	ld	a, (3415:16)
	ld	(xiy+1), a
	call	15672446
	ld	wa, hl
	ld	(xiy+2), a
	call	15672446
	ld	wa, hl
	ld	(xiy+3), a
	call	15672446
	ld	wa, hl
	ld	(xiy+4), a
	call	15672446
	ld	wa, hl
	ld	(xiy+5), a
	call	15672446
	ld	wa, hl
	call	15702184
	cp	a, 0:i3
	jrl	nz, 115
	cp	(3429:16), 3
	jrl	nz, 29
	ld	xiy, 3471
	.byte 0x8d, 0x02, 0x3f, 0x48
	jrl	nz, 17
	.byte 0x8d, 0x03, 0x3f, 0x07
	jrl	nz, 10
	.byte 0xbd, 0x05, 0xcc
	jrl	z, 4
	call	15717257
	ld	xiy, 3471
	ld	wa, 2:i3
	ld_rrw	wa, xiy, wa
	cp	a, 72
	jrl	nz, 44
	cp	w, 5:i3
	jrl	z, 5
	cp	w, 6:i3
	jrl	nz, 34
	push	xhl
	xor	hl, hl
	ld	l, (3822:16)
	dec	1, l
	push	xix
	ld	xix, 61856
	ld_rrb	a, xix, hl
	pop	xix
	pop	xhl
	cp	a, 15
	jrl	z, 6
	cp	a, 16
	jrl	nz, 30
	ld	w, 6:opc
	ld	xiy, 3471
	call	15711654
	ld	(3422:16), 16
	ld	w, 98:opc
	call	15687771
	call	15702548
	call	15702485
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
	jrl	nz, 10
	cp	w, 8
	jrl	z, 160
	jp	15702354
	cp	a, 15
	jrl	ugt, 9
	cp	w, 3:i3
	jrl	nz, 125
	jp	15702360
	cp	a, 152
	jrl	nz, 33
	cp	w, 1:i3
	jrl	z, 9
	cp	w, 4:i3
	jrl	z, 23
	jp	15702354
	ldb_erp	a, 60
	ld	a, (xiy+4)
	and	a, 127
	stb_erp	a, 60
	jrl	z, 86
	jp	15702394
	cp	a, 152
	jrl	nz, 6
	ld	a, 24:opc
	jp	15702400
	cp	a, 16
	jrl	c, 64
	cp	a, 22
	jrl	ugt, 58
	sub	a, 16
	ld	l, a
	xor	h, h
	push	xix
	ld	xix, 15702445
	ld_rrb	l, xix, hl
	pop	xix
	cp	l, 255
	jrl	z, 33
	ld	c, l
	ld	l, a
	push	xde
	ld	xde, 15702465
	ld_rrb	l, xde, hl
	pop	xde
	cp	l, 255
	jrl	z, 11
	cp	w, l
	jrl	nz, 6
	ld	a, c
	jp	15702400
	ld	a, 0:opc
	jp	15702426
	ld	xhl, 15702427
	ld_rr8b	a, xhl, a
	jp	15702400
	ldb_erp	a, 60
	ld	a, (xiy)
	and	a, 3
	stb_erp	a, 60
	jrl	nz, -34
	ld	a, 27:opc
	jp	15702400
	ld	a, 28:opc
	jp	15702405
	ld	(3422:16), 0
	.byte 0xc1, 0x53, 0x0d, 0x3e, 0x01
	exts	wa
	ld	xhl, 3439
	add	hl, wa
	ld	a, (xiy+4)
	ld	(xhl), a
	ld	a, 1:opc
	ret
	nop
	normal
	push	sr
	pop	sr
	max
	halt
	ei	0x07
	ldio	9, 10
	pushw 3340
	ret
	retd	0x0000
	rcf
	scf
	ccf
	zcf
	push_a
	pop_a
	ex_ff
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	ld	xiy, 3471
	.byte 0x8d, 0x02, 0x3f, 0x48
	jrl	nz, 36
	.byte 0x8d, 0x03, 0x3f, 0x07
	jrl	nz, 29
	ld	bc, (xiy+4)
	ld	a, (3429:16)
	cp	a, 2:i3
	jrl	z, 13
	cp	a, 3:i3
	jrl	nz, 12
	call	15724003
	jp	15702540
	call	15723937
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
	.byte 0x8d, 0x02, 0x3f, 0x48
	jrl	nz, 51
	.byte 0x8d, 0x03, 0x3f, 0x05
	jrl	z, 7
	.byte 0x8d, 0x03, 0x3f, 0x06
	jrl	nz, 37
	ld	a, (xiy+4)
	.byte 0xf1, 0xc9, 0x0d, 0xc8
	jrl	z, 3
	or	a, 128
	ld	(3569:16), a
	ldb_erp	a, 60
	and	a, 240
	stb_erp	a, 60
	jrl	z, 4
	call	15702713
	call	15702620
	ret
	pushw	wa
	call	16355597
	cp	hl, 0:i3
	jrl	nz, 81
	xor	c, c
	ld	w, (3569:16)
	ldb_erp	a, 60
	ldb_erp	w, 61
	ld	a, c
	scf
	xorcfb_erp	61
	stb_erp	a, 60
	jrl	nc, 12
	inc	1, c
	cp	c, 8
	jrl	z, 49
	jp	15702636
	ld	a, c
	cp	(3474:16), 6
	jrl	nz, 3
	add	a, 8
	ld	xhl, 15710292
	ld_rr8b	a, xhl, a
	ld	(13964:16), a
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	15703446
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	popw	wa
	ret
	ld	a, 1:opc
	call	15716493
	.byte 0xd1, 0x5a, 0x0d, 0x04, 0xd1, 0x7e, 0x36, 0x04, 0xd1, 0x5c, 0x0d, 0x04, 0xd1, 0x57, 0x0d, 0x04
	ld	(3533:16), 0
	ld	a, (3415:16)
	add	a, 48
	cp	a, 96
	jrl	c, 7
	sub	a, 96
	inc	1, (3533:16)
	ld	(3534:16), a
	.byte 0xd1, 0x8f, 0x0d, 0x04, 0xd1, 0x91, 0x0d, 0x04, 0xd1, 0x93, 0x0d, 0x04
	ld	(32422:16), 255
	call	15698653
	.byte 0xf1, 0x93, 0x0d, 0x06, 0xf1, 0x91, 0x0d, 0x06, 0xf1, 0x8f, 0x0d, 0x06, 0xf1, 0x54, 0x0d, 0xb2
	ld	xiy, 3471
	ld	(xiy), 176
	ld	a, (3415:16)
	inc	1, a
	ld	(xiy+1), a
	.byte 0xf1, 0xc9, 0x0d, 0xc9
	jrl	z, 3
	.byte 0x85, 0x3e, 0x02
	ld	(xiy+4), 0
	ld	w, 6:opc
	push	xhl
	call	15711654
	pop	xhl
	.byte 0xf1, 0x57, 0x0d, 0x06, 0xf1, 0x5c, 0x0d, 0x06, 0xf1, 0x7e, 0x36, 0x06, 0xf1, 0x5a, 0x0d, 0x06
	ld	a, 1:opc
	call	15716577
	ret
	cp	(3429:16), 0
	jrl	nz, 4
	jp	15703187
	ld	xiy, 3471
	call	15672446
	ld	wa, hl
	ld	(xiy), a
	ld	e, a
	and	e, 1
	rrc	e
	ld	(3828:16), a
	.byte 0xc1, 0xf4, 0x0e, 0x3c, 0x04
	call	15672446
	ld	wa, hl
	ld	a, (3415:16)
	ld	(xiy+1), a
	call	15672446
	ld	wa, hl
	ld	(xiy+2), a
	ld	l, (3828:16)
	and	l, 4
	rrc_i_8	l, 3
	or	a, l
	ld	(4539:16), a
	ld	(36955:16), a
	call	15672446
	ld	wa, hl
	ld	(xiy+3), a
	ld	(13959:16), a
	call	15672446
	ld	wa, hl
	ld	(xiy+4), a
	or	a, e
	ld	(4541:16), a
	ld	(13958:16), a
	call	15672446
	ld	wa, hl
	ld	(xiy+5), a
	ld	(3829:16), a
	ld	(4542:16), a
	ld	(3655:16), a
	call	16355597
	cp	hl, 0:i3
	jrl	nz, 16
	ld	w, (4539:16)
	cp	w, 15
	jrl	le, 67
	cp	w, 72
	jrl	z, 100
	push	xhl
	ld	l, a
	ld	h, (4542:16)
	call	16554468
	ld	(4542:16), h
	ld	(13967:16), h
	pop	xhl
	call	15672446
	push	xhl
	call	15696372
	cp	w, 1:i3
	jrl	z, 16
	ld	w, 6:opc
	ld	xiy, 3471
	call	15711654
	ld	(3422:16), 16
	ld	w, 98:opc
	call	15687771
	pop	xhl
	jp	15703187
	ld	(3567:16), 1
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	15725166
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	cp	(3429:16), 3
	jrl	nz, -92
	call	15717110
	jp	15703187
	cp	(3429:16), 3
	jrl	nz, 27
	ld	(3567:16), 12
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	15724480
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	jp	15703025
	ld	(3567:16), 4
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	15723892
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	jp	15703025
	ret
	ld	xiy, 3471
	call	15672446
	ld	wa, hl
	ld	(xiy), a
	ld	(3413:16), a
	call	15672446
	ld	wa, hl
	ld	a, (3415:16)
	ld	(xiy+1), a
	call	15672446
	ld	wa, hl
	ld	(xiy+2), a
	ld	e, a
	call	15672446
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
	.byte 0xc1, 0x53, 0x0d, 0x3e, 0x10
	ld	(3538:16), 4
	ld	xhl, 3567
	cp	(3429:16), 3
	jrl	nz, 17
	.byte 0x83, 0x3f, 0x10
	jrl	z, 24
	ld	(xhl), 16
	call	15686497
	jp	15703313
	.byte 0x83, 0x3f, 0x06
	jrl	z, 7
	ld	(xhl), 6
	call	15686497
	call	15724139
	ret
	ld	a, 134:opc
	ld	(13964:16), 2
	call	15703342
	ret
	ld	a, 133:opc
	ld	(13964:16), 1
	call	15703342
	ret
	call	15703407
	cp	c, 0:i3
	jrl	z, 10
	call	15672446
	ld	wa, hl
	jp	15703406
	pushw	wa
	call	15703446
	popw	wa
	ld	xiy, 3471
	ld	(xiy), a
	ld	a, (3415:16)
	ld	(xiy+1), a
	ld	w, 2:opc
	push	xhl
	call	15711654
	pop	xhl
	call	15672446
	ld	wa, hl
	ld	w, 98:opc
	call	15687771
	ld	(3422:16), 16
	ret
	push	xhl
	ld	l, (3822:16)
	dec	1, l
	xor	h, h
	ld	c, 255:opc
	push	xix
	ld	xix, 61856
	ld_rrb	l, xix, hl
	pop	xix
	cp	l, 16
	jrl	z, 6
	cp	l, 15
	jrl	nz, 2
	xor	c, c
	pop	xhl
	ret
	push	xhl
	ld	a, (3429:16)
	and	a, 3
	exts	wa
	sla	wa, 2
	ld	iy, wa
	push	xde
	ld	xde, 15703477
	ld_rrl	xiy, xde, iy
	pop	xde
	call (xiy)
	pop	xhl
	ret
SerialPort_ModeSelect_Table:
	.long SerialPort_ModeHandler_0
	.long SerialPort_ModeHandler_1
	.long SerialPort_ModeHandler_1
	.long SerialPort_ModeHandler_3
SerialPort_ModeHandler_1:
	ld	(3567:16), 5
	call	DisplayStr_BytecodeBlock_C
	ret
SerialPort_ModeHandler_3:
	ld	(3567:16), 15
	call	DisplayStr_StyleSectionInit
	ret
SerialPort_ModeHandler_0:
	call	15724622
	ret
	cp	(3429:16), 3
	jrl	nz, 10
	call	15672446
	ld	wa, hl
	jp	15703625
	ld	xiy, 3471
	call	15672446
	ld	wa, hl
	ld	(xiy), a
	ld	(3413:16), a
	call	15672446
	ld	wa, hl
	ld	a, (3415:16)
	ld	(xiy+1), a
	call	15672446
	ld	wa, hl
	ld	(xiy+2), a
	ld	(13957:16), a
	call	15672446
	ld	wa, hl
	ld	(3538:16), 3
	ld	(13956:16), 2
	cp	(3567:16), 2
	jrl	nz, 8
	call	15723813
	jp	15703620
	ld	(3567:16), 2
	call	15723809
	ld	(3540:16), 0
	ret
	cp	(3429:16), 3
	jrl	nz, 10
	call	15672446
	ld	wa, hl
	jp	15703746
	ld	xiy, 3471
	call	15672446
	ld	wa, hl
	ld	(xiy), a
	ld	(3413:16), a
	call	15672446
	ld	wa, hl
	ld	a, (3415:16)
	ld	(xiy+1), a
	call	15672446
	ld	wa, hl
	ld	(xiy+2), a
	ld	(13957:16), a
	call	15672446
	ld	wa, hl
	ld	(xiy+3), a
	ld	(4370:16), a
	call	15672446
	ld	wa, hl
	ld	(3538:16), 4
	ld	(13956:16), 1
	cp	(3567:16), 2
	jrl	nz, 8
	call	15723813
	jp	15703741
	ld	(3567:16), 2
	call	15723809
	ld	(3540:16), 0
	ret
	ld	c, (3533:16)
	xor	b, b
	add (3418:16), bc
	cp	c, 0:i3
	jrl	z, 25
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	15710747
	djnz16	bc, -7
	call	15701395
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ret
	ld	l, (13944:16)
	cp	l, 0:i3
	jrl	nz, 2
	ld	l, 6:opc
	sla	l, 1
	xor	h, h
	push	xix
	ld	xix, 15703939
	ld_rrw	de, xix, hl
	ld	l, (13945:16)
	sla	l, 1
	ld_rrw	bc, xix, hl
	pop	xix
	add	de, bc
	ld	wa, de
	ld	l, 96:opc
	div8rr	a, l
	ld	(13203:16), w
	ld	(13204:16), a
	ld	a, (13946:16)
	cp	a, 1:i3
	jrl	nz, 21
	sla	de, 2
	ld	wa, de
	xor	de, de
	ld	hl, 5:i3
	ld	qwa, de
	div	xwa, xhl
	ld	de, qwa
	jp	15703926
	cp	a, 0:i3
	jrl	nz, 28
	ld	wa, de
	sla	wa, 4
	add	wa, de
	add	wa, de
	add	wa, de
	xor	de, de
	ldw	hl, 20
	ld	qwa, de
	div	xwa, xhl
	ld	de, qwa
	jp	15703926
	cp	a, 2:i3
	jrl	nz, 9
	srl	de, 1
	ld	wa, de
	jp	15703926
	srl	de, 2
	ld	wa, de
	ld	l, 96:opc
	div8rr	a, l
	ld	(13201:16), w
	ld	(13202:16), a
	ret
ScoopParam_ValueTable:
	.incbin "includes/romslices/v7_transplant_ScoopParam_ValueTable_head.bin"
	ld (0x3678:16), 0x04
	ld (0x3679:16), 0x00
	ld (0x367a:16), 0x01
	call 0xefa749
	call 0xefa6aa
	ld a, (0x8c9e:16)
	ld (0x0d66:16), a
	call 0xefa6ec
	call 0xefa763
	call 0xefa77d
	call 0xefa79a
	cpw (0xf231:16), 0x0000
	jrl nz, .Lc_efa1aa
	call VoiceState_DataBlock2_0x184
	cp w, 0:i3
	jrl z, .Lc_efa1aa
	ld (0x0d69:16), 0x18
	jp 0xefa2f3
.Lc_efa1aa:
	res 7, (0x0d54:16)
	call PortConfig_DataTable_B_0x20
	call SeqBuf_Init
	call 0xefa646
	call 0xefb770
	call 0xfdad86
	call MemConfig_Handler_4_0x15B
	call PortConfig_SetupBytecode
	xor WA,WA
	ld (0x0d4f:16), wa
	ld (0x0d51:16), wa
	ld c, (0x0eee:16)
	dec 1,C
	.incbin "includes/romslices/v7_transplant_ScoopParam_ValueTable_tail_head.bin"
	call 0xefa77d
	call 0xefa79a
	bit 3, (0x0d53:16)
	jrl z, .Lc_efa2ef
	call PortConfig_SetupBytecode_0x34
	cp (0x0d65:16), 0x00
	jrl nz, .Lc_efa2ef
.Lc_efa2ef:
	jp 0xefa2f3
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

Interrupt_VectorSelect_Table:
	.long Interrupt_VectorHandler_0
	.long Interrupt_VectorHandler_1
	.long Interrupt_VectorHandler_2
	.long Interrupt_VectorHandler_3
	.long Interrupt_VectorHandler_4

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
	.byte 0xc1, 0xa4, 0x8c, 0x3f, 0x00	; cpdi8 (0x8d40), 0 (v7 patched)

	.byte 0x76, 0x04, 0x00	; jrl z, Interrupt_Vec2_Ret (v7 displacement)

	.byte 0x1d, 0x12, 0xa4, 0xef	; call Interrupt_SendAllNotesOff (v7 addr)



Interrupt_Vec2_Ret:
	ret

Interrupt_VectorHandler_3:
	cp	(36004:16), 0
	jrl	nz, 8
	call	15705156
	jp	15704971
Interrupt_Vec3_UpdatePath:
	call Display_RegionUpdateFromHW

Interrupt_Vec3_Ret:
	ret

Interrupt_VectorHandler_4:
	.byte 0xc1, 0xa4, 0x8c, 0x3f, 0x00, 0x76, 0x08, 0x00
	.byte 0x1d, 0x62, 0xa4, 0xef, 0x1b, 0xa0, 0xa3, 0xef
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
	call	15725806
	call	15686621
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
	call	15725806
	call	15686621
	ret
	ld	(3432:16), 2
	ld	(3431:16), 4
	call	16635550
	ret
Interrupt_SendAllNotesOff:
	ld	(3432:16), 3
	call	15705197
	call	15701869
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	16648638
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
	call	16641574
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
	call	16635550
	ret
Interrupt_SetFlagBytecode:
	ld	(3432:16), 4
	ld	(3431:16), 0
	call	16635550
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
	call	15725806
	call	15686621
	ret
PortConfig_SetupBytecode:
	ld	(0x28be:16), 255
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
	ld	a, (3822:16)
	dec	1, a
	ld	(0x28be:16), a
	push	xix
	ld	xix, 0xf1a0
	.byte 0xf3
	reti
	stib_d8 248, 13
	pop	xix
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
PortConfig_Select_Table:
	.long PortConfig_Handler_0
	.long PortConfig_Handler_1
	.long PortConfig_Handler_1
	.long PortConfig_Handler_3
PortConfig_Handler_1:
	.byte 0xc1, 0xd3
	decf
	push	xiz
	normal
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
	call	16453929
	ld	(132584:24), 255
	ld	(132588:24), 255
	ld	(132586:24), 255
	call	15725639
	call	15686497
	call	15725762
	cp	(10430:16), 255
	jrl	z, 133
	ldw	(3660:16), 0
	ldw	(3662:16), 1
	ldw	(3664:16), 0
	call	15705595
	ld	(3702:16), 1
	ldw	(3703:16), 0
	xor	l, l
	ld	a, (1075:16)
	cp	a, 4:i3
	jrl	ule, 13
	ld	l, a
	ld	a, 4:opc
	sub	l, 4
	ldw	(3664:16), 1
	ld	(3666:16), 0
	ld	(3667:16), a
	ld	(3668:16), l
	pushw	wa
	pushw	bc
	push	xix
	ld	xix, 3786
	ldw	wa, 8224
	ldw	bc, 15
	stw_dpi	wa, 241
	djnz16	bc, -6
	pop	xix
	popw	bc
	popw	wa
	ld	(3788:16), 49
	ld	(3796:16), 69
	ld	(3797:16), 78
	ld	(3798:16), 68
	call	15686721
	call	15686591
	call	15686721
	call	15686621
	jp	15705590
	call	15720788
	call	15705618
	call	15709574
	call	16453970
	ret
	pushw	wa
	pushw	bc
	push	xix
	ld	xix, 3669
	ldw	bc, 96
	xor	wa, wa
	lda_dpi	xbc, 240
	djnz16	bc, -6
	pop	xix
	popw	bc
	popw	wa
	ret
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
	call SndDispatch_ProcessCommand_0x266
	jp PortConfig_Handler_0_0x10A
.Lc_efa641:
	call DisplayMode_Handler_3_0x775
	ret
	call	15713948
	push	xde
	ld	xde, 62032
	.byte 0xf3, 0x07, 0xe8, 0xf8, 0xcf
	pop	xde
	jrl	nz, 36
	call	15713930
	push	xix
	ld	xix, 3230
	.byte 0xf3, 0x07, 0xf0, 0xf8, 0x02, 0xff, 0xff
	srl	iz, 1
	ld	xix, 3262
	.byte 0xf3, 0x07, 0xf0, 0xf8, 0x00, 0x05
	pop	xix
	jp	15705769
	push	xde
	push	xix
	ld	xix, 62032
	inc	1, iz
	ld_rrw	de, xix, iz
	call	15713930
	ld	xix, 3230
	st_rrw	de, xix, iz
	srl	iz, 1
	ld	xix, 3262
	.byte 0xf3, 0x07, 0xf0, 0xf8, 0x00, 0x05
	pop	xix
	pop	xde
	ret
	ld	a, (3424:16)
	ld	(3822:16), a
	call	15713930
	srl	xiz, 1
	push	xix
	ld	xix, 61856
	ld_rrb	a, xix, iz
	pop	xix
	ld	xhl, 15705812
	ld_rr8b	a, xhl, a
	ld	(3429:16), a
	ret
PortConfig_DataTable_A:
	.incbin "includes/romslices/v7_transplant_PortConfig_DataTable_A_head.bin"
	call VoiceSlot_ComputeWordIndex
	srl XIZ, 0x01
	push XIX
	ld XIX,0x0000f1a0
	ldb_dri a, 0x07, 0xf0, 0xf8
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
	ldb_dri a, 0x03, 0xec, 0xe0
	cp A,0xff
	jrl z, .Lc_efa734
	ld (0x8c9e:16), a
	ld E,A
	ld D, 0xff:opc
	ldw WA, 0x1090
	call SysInit_BytecodeBlock_0x3DB
.Lc_efa734:
	ret
PortConfig_DataTable_B:
	nop
	push	sr
	normal
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
	ld	xwa, (7514:16)
	ld	(xhl), xwa
	ret
	call	TempoRingBuf_ReadByte
	ld	wa, hl
	cp	wa, 0xffff
	jrl	nz, -13
	ret
	ld	xhl, PortConfig_DataTable_B_0x44
	ld	a, (3429:16)
	and	a, 3
	ld_rr8b a, xhl, a
	ld (3567:16), a
	ret
	nop
	nop
	nop
	incf
	ret
ClockConfig_Select_Table:
	.long ClockConfig_Handler_0
	.long ClockConfig_Handler_1
	.long ClockConfig_Handler_1
	.long ClockConfig_Handler_0
ClockConfig_Handler_1:
	.byte 0xc1, 0x1c, 0xe3
ClockConfig_Handler_1_Code:
	push	xiz
	push	sr	
	ret	
ClockConfig_Handler_0:
	.incbin "includes/romslices/v7_transplant_ClockConfig_Handler_0_head.bin"
	ld (0x3673:16), 0x00
	call DisplayStr_StyleSectionNames_0x69
	ld (0x0d55:16), 0xff
	and (0x0f57:16), 0xfe
	ld (0x0d36:16), 0x00
	ld a, (0x8c9b:16)
	.incbin "includes/romslices/v7_transplant_ClockConfig_Handler_0_tail.bin"
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
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld de, (4560:16)
	ld a, c
	scf
	xorcf_a_16 de
	stw_erp DE, 0x3e
	stb_erp A, 0x3c
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

	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x81	; cpdi8 (0x8d36), 129 (v7 patched)

	.byte 0x76, 0x08, 0x00	; jrl z, SysEx_DecrementCounter (v7 displacement)

	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x8e	; cpdi8 (0x8d36), 142 (v7 patched)

	.byte 0x7e, 0x0c, 0x00	; jrl nz, SubCPU_CmdCountdownRet (v7 displacement)



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
	jrl	nz, 24
	ld	xiy, 3520
	cp	(xiy), a
	jrl	nz, 103
	ld	xiy, 4360
	cp	(xiy), wa
	jrl	nz, 130
	jp	15707065
	call	15704017
	call	15711539
	xor	h, h
	push	xix
	ld	xix, 15710496
	ld_rrb	w, xix, hl
	pop	xix
	or	w, 2
	push	xhl
	call	15687771
	pop	xhl
	push	xde
	ld	xde, 15710502
	ld_rrb	w, xde, hl
	pop	xde
	ld	(3425:16), w
	ld	(3432:16), 1
	call	15710358
	push	xhl
	call	15725806
	pop	xhl
	call	15710508
	call	15710543
	ld	(3434:16), 0
	call	15720788
	call	15709574
	ld	w, 0:opc
	jp	15707020
	call	15704017
	push	xiy
	call	15710015
	pop	xiy
	call	15711539
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, 15707066
	ld_rrl	xhl, xix, hl
	pop	xix
	call (xhl)
	jp	15707020
	call	15704017
	call	15711578
	call	15710780
	call	15710837
	call	15710874
	cp	l, 2:i3
	jrl	z, 15
	cp	l, 3:i3
	jrl	z, 10
	cp	l, 10
	jrl	z, 4
	call	15710015
	call	15710153
	ld	(3434:16), 0
	call	15720788
	call	15709574
	cp	w, 255
	jrl	nz, 8
	call	15710111
	jp	15707065
	call	15701395
	ld	a, (3420:16)
	cp	(3415:16), 48
	jrl	nz, 3
	or	a, 128
	ld	(13949:16), a
	call	15725762
	call	15686621
	ret
MemoryConfig_Handler_Table:
	.long MemConfig_Handler_0
	.long MemConfig_Handler_1
	.long MemoryConfig_Handler_Table_0xB2 + 97
	.long MemConfig_Handler_3
	.long MemConfig_Handler_4
	.long MemConfig_Handler_5
	ld XIY,MemoryConfig_Handler_Table_0xB2
	ld XIX,0x00000d8f
	ld A, 0xb0:opc
	ld (XIX),A
	ld a, (0x0d57:16)
	.incbin "includes/romslices/v7_transplant_MemoryConfig_Handler_Table_tail_tail.bin"
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
	ld XHL,0x00000d54
	bit 3,(XHL)
	jrl z, .Lc_efad7e
	res 3,(XHL)
	call PortConfig_SetupBytecode_0x34
	jp MemConfig_Handler_0_0x63
.Lc_efad7e:
	call VoiceCtrl_BytecodeHandler
	cp B,0x16
	jrl z, .Lc_efadc5
	cp B,0x17
	jrl z, .Lc_efadc5
	call VoiceSlot_FlagCheck
	cp W,0xff
	jrl z, .Lc_efadba
	xor A,A
	call VoiceSlot_SaveState
	ld W, 0x81:opc
	call VoiceSlot_FinalRetZ_0x84
	ld de, 1:i3
	call VoiceSlot_FinalRetZ_0xB8
	ld W, 0x82:opc
	call VoiceSlot_FinalRetZ_0x84
	xor A,A
	call VoiceSlot_RestoreState
	call MemConfig_Handler_1_0x8B
.Lc_efadba:
	ld W, 0xff:opc
	or (0x8cec:16), 0x01
	jp MemConfig_Handler_0_0x63
.Lc_efadc5:
	call VoiceSlot_LoadAndDispatch
	jp MemConfig_Handler_0_0x24
	ret
MemConfig_Handler_1:
	.incbin "includes/romslices/v7_transplant_MemConfig_Handler_1_head.bin"
	call VoiceSlot_ComputeWordIndex
	push XIX
	ld XIX,0x00000c9e
	ldw_dri iy, 0x07, 0xf0, 0xf8
	pop XIX
	cp IY,0xffff
	jrl nz, .Lc_efae74
	jp MemConfig_Handler_1_0x13D
.Lc_efae74:
	srl IZ, 0x01
	push XIX
	ld XIX,0x00000cbe
	ldb_dri a, 0x07, 0xf0, 0xf8
	pop XIX
	xor W,W
	inc 1,WA
	cp WA,0x00ff
	jrl ule, .Lc_efaee4
	push XIX
	ld XIX,0x0000f218
	stib_ind 0x07, 0xf0, 0xf8, 0x05
	sla IZ, 0x01
	ld XIX,0x00000c9e
	ldw_dri iy, 0x07, 0xf0, 0xf8
	pop XIX
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (0x10fd:16)
	ld IY,(XHL+0x03)
	push XIX
	ld XIX,0x0000f1f8
	stw_dri iy, 0x07, 0xf0, 0xf8
	pop XIX
	cp IY,0xffff
	jrl z, .Lc_efaf0b
	call VoiceSlot_UpdateCurrentPointer
	ld xhl, (0x10fd:16)
	ld IY,(XHL+0x03)
	cp IY,0xffff
	jrl z, .Lc_efaf0b
	ld wa, (0x286d:16)
	call VoiceSlot_FinalRetZ_0x1B2
	jp MemConfig_Handler_1_0x13D
.Lc_efaee4:
	push XIX
	ld XIX,0x0000f218
	stb_dri a, 0x07, 0xf0, 0xf8
	sla IZ, 0x01
	ld XIX,0x00000c9e
	ldw_dri iy, 0x07, 0xf0, 0xf8
	ld XIX,0x0000f1f8
	stw_dri iy, 0x07, 0xf0, 0xf8
	pop XIX
	jp MemConfig_Handler_1_0xF8
.Lc_efaf0b:
	ret
	.incbin "includes/romslices/v7_transplant_MemConfig_Handler_1_tail.bin"
MemConfig_Handler_3:
	call	15708360
	call	15708501
	call	15708395
	call	15709555
	call	15709574
	.byte 0xc1	; llvm-mc cannot spell this byte
	jr	gt, 13	; -> 0xEFB0CD
	push	xsp
	nop
	jrl	z, 0	; -> 0xEFB0C5
	ld	w, 0:opc
	ret
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
	call	AccPedal_CheckBitAndUpdate
	ld	wa, (3816:16)
	cp	wa, (13950:16)
	jrl	nz, 73	; -> 0xEFB143
	ld	wa, (3818:16)
	cp	wa, (3416:16)
	jrl	nz, 24	; -> 0xEFB11D
	ld	a, (3820:16)
	cp	a, (3415:16)
	jrl	z, 68	; -> 0xEFB154
	call	15722654
	cp	w, 0:i3
	jrl	z, 59	; -> 0xEFB154
	jp	15708471
	.byte 0xc1	; llvm-mc cannot spell this byte
	pop	xiy
	decf
	push	xsp
	max
	jrl	ule, 18	; -> 0xEFB137
	ld	a, (3821:16)
	ld	w, (3420:16)
	cp	a, 4:i3
	jrl	ule, 25	; -> 0xEFB14B
	cp	w, 4:i3
	jrl	c, 12	; -> 0xEFB143
	call	15721560
	call	Display_UpdateRegion2
	jp	15708500
	call	15720788
	jp	15708500
	cp	w, 3:i3
	jrl	ugt, -13	; -> 0xEFB143
	jp	15708471
	ret
	ld	(13964:16), 0
	ld	a, (3415:16)
	ld	(3521:16), a
	call	15708938
	xor	w, w
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, 15708540
	ld_rrl	xhl, xix, hl
	pop	xix
	call	(xhl)
	ret
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
	cp	a, 0:i3
	jrl	z, 23
	dec	1, a
	xor	w, w
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_SubTable_1
	ld_rrl xhl, xix, hl
	pop xix
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
	cp	a, 0:i3
	jrl	z, 23
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_SubTable_2
	ld_rrl xhl, xix, hl
	pop xix
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
	cp	a, 0:i3
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
	.byte 0xbe, 0x61, 0xef, 0x00
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
	cp	a, 0:i3
	jrl	z, 23
	dec	1, a
	exts	wa
	sla	wa, 2
	ld	hl, wa
	push	xix
	ld	xix, SndDispatch_SubTable_4
	ld_rrl xhl, xix, hl
	pop xix
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
	.byte 0x1d, 0xf4, 0xb3, 0xef, 0x1d, 0xa0, 0xb3, 0xef
	.byte 0xc9, 0xd8, 0x76, 0x17, 0x00, 0xc9, 0x69, 0xd8
	.byte 0x13, 0xd8, 0xec, 0x02, 0xd8, 0x8b, 0x3c, 0x44
	.byte 0xc6, 0xb2, 0xef, 0x00, 0xe3, 0x07, 0xf0, 0xec
	.byte 0x23, 0x5c, 0xb3, 0xe8, 0x0e, 0xde, 0xb2, 0xef
	.byte 0x00
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
	ld	(3415:16), 0
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
	ret
	call	15713087
	ld	xiy, 3415
	xor	w, w
	cp	a, 129
	jrl	nz, 17
	cp	(xiy), w
	jrl	nz, 6
	ld	a, 1:opc
	jp	15709087
	ld	a, 2:opc
	jp	15709087
	push	xiy
	pushw	wa
	call	15713141
	ld	(3526:16), a
	popw	wa
	pop	xiy
	and	a, 240
	cp	a, 144
	jrl	nz, 43
	cp	(xiy), w
	jrl	nz, 19
	cp	(3526:16), w
	jrl	nz, 6
	ld	a, 3:opc
	jp	15709087
	ld	a, 4:opc
	jp	15709087
	cp	(3526:16), w
	jrl	nz, 6
	ld	a, 5:opc
	jp	15709087
	ld	a, 6:opc
	jp	15709087
	cp	a, 176
	jrl	nz, 43
	cp	(xiy), w
	jrl	nz, 19
	cp	(3526:16), w
	jrl	nz, 6
	ld	a, 7:opc
	jp	15709087
	ld	a, 8:opc
	jp	15709087
	cp	(3526:16), w
	jrl	nz, 6
	ld	a, 9:opc
	jp	15709087
	ld	a, 10:opc
	jp	15709087
	xor	a, a
	ret
	call	15713087
	cp	a, 132
	jrl	nz, 6
	ld	a, 6:opc
	jp	15709171
	cp	a, 129
	jrl	nz, 6
	ld	a, 1:opc
	jp	15709171
	call	15713141
	ld	(3526:16), a
	ld	xiy, 3526
	ld	xix, 3580
	xor	a, a
	cp	(xix), a
	jrl	nz, 17
	cp	(xiy), a
	jrl	nz, 6
	ld	a, 4:opc
	jp	15709171
	ld	a, 5:opc
	jp	15709171
	cp	(xiy), a
	jrl	nz, 6
	ld	a, 2:opc
	jp	15709171
	ld	a, 3:opc
	ret
	xor	a, a
	ld	(3580:16), a
	ld	(3581:16), a
	ld	(3434:16), a
	.byte 0xc1, 0x53, 0x0d, 0x3c, 0x7f
	call	15713141
	cp	a, 130
	jrl	z, 142
	call	15713087
	ld	(3581:16), a
	cp	a, 129
	jrl	nz, 9
	incw	1, (3416:16)
	ld	(3580:16), 1
	call	15713087
	cp	a, 129
	jrl	z, 8
	call	15712700
	jp	15709246
	call	15712661
	cp	w, 255
	jrl	z, 284
	call	15713087
	cp	a, 144
	jrl	z, 90
	cp	a, 129
	jrl	z, 54
	call	15713141
	cp	a, 130
	jrl	z, 65
	cp	a, 132
	jrl	z, 59
	cp	a, 47
	jrl	z, 6
	cp	a, 95
	jrl	nz, 240
	call	15712661
	cp	w, 255
	jrl	z, 230
	call	15713087
	cp	a, 144
	jrl	z, 220
	cp	a, 129
	jrl	nz, -54
	ld	(3580:16), 1
	cp	(3581:16), 129
	jrl	z, -111
	jp	15709268
	jp	15709536
	ld	(3434:16), 255
	jp	15709536
	cp	(3580:16), 0
	jrl	nz, 176
	ld	a, (3581:16)
	and	a, 240
	cp	a, 176
	jrl	z, 163
	call	15709599
	call	15709634
	call	15713141
	ld	(3526:16), a
	call	15712700
	cp	w, 255
	jrl	z, 137
	call	15713087
	cp	a, 144
	jrl	nz, 20
	call	15713141
	cp	a, (3526:16)
	jrl	z, -31
	ld	(3415:16), 0
	jp	15709536
	call	15713141
	cp	a, 47
	jrl	z, -50
	cp	a, 95
	jrl	z, -56
	call	15713087
	cp	a, 129
	jrl	nz, 81
	.byte 0xc1, 0x53, 0x0d, 0x3e, 0x80
	ld	(3580:16), 1
	ld	a, (3579:16)
	exts	wa
	add (3416:16), wa
	ld	de, wa
	call	15713447
	call	15713087
	cp	a, 130
	jrl	z, 29
	and	a, 240
	cp	a, 144
	jrl	z, 36
	cp	a, 176
	jrl	z, 30
	bit	7, a
	jrl	nz, 4
	call	15712661
	jp	15709536
	ld	a, 1:opc
	call	15716493
	call	15710751
	ld	a, 1:opc
	call	15716577
	ret
	call	15713087
	cp	a, 144
	jr	nz, 4
	call	15705091
	call	15699930
	ret
	call	15699930
	call	15713087
	cp	a, 144
	jrl	nz, 4
	call	15705171
	ret
	call	15686497
	call	15686591
	call	15686721
	call	15686621
	call	15721560
	call	15686646
	ret
	xor	a, a
	call	15716493
	ld	de, 4:i3
	call	15713447
	call	15713263
	ld	(3575:16), a
	call	15713087
	ld	(3576:16), a
	xor	a, a
	call	15716577
	ret
	ld	a, (3576:16)
	ld	(3579:16), a
	ld	a, (3521:16)
	add	a, (3575:16)
	cp	a, 96
	jrl	c, 7
	inc	1, (3579:16)
	sub	a, 96
	ld	(3415:16), a
	ret
MemConfig_Handler_4:
	ld	xhl, 4345
	.byte 0xb3, 0xc9
	jrl	z, 14
	.byte 0xb3, 0xb1
	call	15718210
	.byte 0xf1, 0xf9, 0x10, 0xba
	jp	15709714
	call	15708360
	call	15709715
	call	15720788
	call	15709555
	call	15709574
	ld	w, 0:opc
	ret
	ld	a, 1:opc
	call	15716493
	call	15716861
	cp	w, 0:i3
	jrl	z, 72
	ld	a, (3415:16)
	ld	(3659:16), a
	call	15709817
	call	15709817
	ld	(3415:16), 0
	ld	a, 2:opc
	call	15716493
	call	15708501
	ld	a, 1:opc
	call	15716688
	cp	w, 1:i3
	jrl	z, 9
	cp	w, 2:i3
	jrl	nz, -26
	jp	15709792
	ld	a, (3659:16)
	cp	a, (3415:16)
	jrl	nz, 24
	ld	a, 2:opc
	call	15716594
	jp	15709816
	ld	(3415:16), 0
	ld	(3434:16), 0
	jp	15709816
	ret
	ld	(3434:16), 0
	call	15712713
	cp	w, 255
	jrl	z, 170
	call	15713087
	cp	a, 144
	jrl	z, 68
	cp	a, 129
	jrl	z, -31
	call	15713141
	cp	a, 47
	jrl	z, 6
	cp	a, 95
	jrl	nz, 148
	call	15712713
	cp	w, 255
	jrl	z, 128
	call	15713087
	cp	a, 144
	jrl	z, 26
	cp	a, 129
	jrl	z, -73
	call	15713141
	cp	a, 47
	jrl	z, -83
	cp	a, 95
	jrl	z, -89
	jp	15710012
	call	15713141
	ld	(3522:16), a
	ld	(13964:16), 0
	call	15712713
	cp	w, 255
	jrl	nz, 22
	call	15707428
	call	15706175
	xor	wa, wa
	ld	(3416:16), wa
	ld	(3415:16), a
	jp	15710012
	call	15713087
	cp	a, 144
	jrl	nz, 19
	call	15713141
	cp	a, (3522:16)
	jrl	z, -53
	call	15712661
	jp	15710012
	cp	a, 129
	jrl	z, 4
	jp	15709976
	incw	1, (3416:16)
	jp	15709976
	ld	w, 255:opc
	ld	(3434:16), w
	jp	15710014
	ld	w, 0:opc
	ret
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
	call SysInit_BytecodeBlock_0x3DB
	ld A, 0x48:opc
	ld W, 0x06:opc
	ld D, 0x04:opc
	xor E,E
	call SysInit_BytecodeBlock_0x3DB
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	ret
	.byte 0xc1, 0x65, 0x0d, 0x3f, 0x00, 0x7e, 0x26, 0x00
	.byte 0xc1, 0x5d, 0xfc, 0x21, 0xc9, 0xcc, 0x07, 0xc9
	.byte 0xd9, 0x7e, 0x04, 0x00, 0x1b, 0x9e, 0xb7, 0xef
	.byte 0xc1, 0x5d, 0xfc, 0x3c, 0xf8, 0xc1, 0x5d, 0xfc
	.byte 0x3e, 0x02, 0x21, 0x48, 0x20, 0x03, 0x25, 0x02
	.byte 0x24, 0x02, 0x1d, 0xfb, 0xbc, 0xef, 0x0e
SysInit_SendAllNotesAndReset:
	ld	(13964:16), 0
	call	15724565
	xor	wa, wa
	ld	a, 10:opc
	call	16355414
	ret
SystemInit_Handler_Table:
	.long SystemInit_StepHandler_0
	.long SystemInit_StepHandler_0
	.long SystemInit_StepHandler_2
	.long SystemInit_StepHandler_3
	.long SystemInit_StepHandler_4
	.long SystemInit_StepHandler_5
	.incbin "includes/romslices/v7_transplant_SystemInit_Handler_Table_tail_head.bin"
	call MemoryConfig_Handler_Table_0x18
	ld A,W
	exts WA
	sla WA, 0x02
	ld IY,WA
	push XDE
	ld XDE,SystemInit_Handler_Table
	ldl_dri xiy, 0x07, 0xe8, 0xf4
	pop XDE
	jp (XIY)
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
	ld W, 0x62:opc
	call MIDI_SendSysExFromW
	ld W, 0x00:opc
	ret
	nop
	nop
	halt
	ei	0x07
	.byte 0x0b, 0x03, 0x04
	nop
	nop
	incf
	nop
	nop
	nop
	nop
	nop
	cp	(3429:16), 0
	jrl	nz, 36
	call	15717180
	cp	(52821:16), 0
	jrl	z, 14
	pushw	wa
	ld	d, a
	xor	e, e
	call	15710377
	call	15710508
	popw	wa
	exts	wa
	ld	bc, wa
	ld	l, 96:opc
	call	15710600
	.byte 0xc1, 0x53, 0x0d, 0x3e, 0x40
	ret
	xor	h, h
	sla	hl, 2
	extz	xhl
	push	xix
	ld	xix, 15710472
	ld_rrw	de, xix, hl
	pop	xix
	xor	a, a
	ld	(3437:16), a
	ld	(3438:16), a
	ld	(4391:16), a
	ld	xiz, 3471
	ld	xiy, 52822
	ld	c, (52821:16)
	cp	c, 0:i3
	jrl	z, 61
	ld	a, (36004:16)
	ld	(3437:16), a
	ld	a, (36006:16)
	ld	(3438:16), a
	ld	a, (36008:16)
	ld	(4391:16), a
	ld	(xiz+256), 144
	ld	a, (3415:16)
	ld	(xiz+1), a
	ld	a, (xiy)
	inc	1, xiy
	ld	(xiz+2), a
	ld	(xiz+3), 64
	ld	(xiz+4), de
	dec	1, c
	add	xiz, 6
	jp	15710405
	ret
	nop
	max
	jr	f, 4
	nop
	pop	sr
	jr	f, 3
	nop
	push	sr
	jr	f, 2
	ldw	wa, 36865
	normal
	nop
	normal
	jr	f, 1
	ldw	wa, 12288
	.byte 0x01
SysInit_BytecodeBlock:
	.incbin "includes/romslices/v7_transplant_SysInit_BytecodeBlock_head.bin"
	ld b, (0xce55:16)
	sla B, 0x01
	ld C,B
	add B,B
	add B,C
	ld W,B
	ld XIY,0x00000d8f
	call SysInit_BytecodeBlock_0x486
	ret
	.incbin "includes/romslices/v7_transplant_SysInit_BytecodeBlock_mid1_head.bin"
	xor A,A
	call VoiceSlot_SaveState
	call VoiceSlot_FlagCheck
	cp A,0x84
	jrl nz, .Lc_efb9fd
	set 7, (0x0d54:16)
.Lc_efb9fd:
	call SysInit_BytecodeBlock_0xFF
	xor A,A
	call VoiceSlot_RestoreState
	ret
	.incbin "includes/romslices/v7_transplant_SysInit_BytecodeBlock_mid1_tail_head.bin"
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
	call SysInit_BytecodeBlock_0x486
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	ret
	.incbin "includes/romslices/v7_transplant_SysInit_BytecodeBlock_mid1_tail_tail.bin"
	push XIX
	pushw hl
	ld XIX,0x0000be9d
	ld hl, (0x9046:16)
	stw_dri wa, 0x07, 0xf0, 0xec
	.incbin "includes/romslices/v7_transplant_SysInit_BytecodeBlock_mid2.bin"
	ld a, (0x0eee:16)
	call SysInit_BytecodeBlock_0x499
	or (0x8cec:16), 0x01
	or (0x266a:16), 0x01
	ret
	.incbin "includes/romslices/v7_transplant_SysInit_BytecodeBlock_tail.bin"
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
	jrl	ugt, 12
	ld	(0x28ba:16), iy
	ld	(0x28bc:16), wa
	jp	VoiceSlot_RetZ_0x58
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
	ld	iy, (xhl+3)
	sub	wa, 251
	jp	VoiceSlot_RetZ_0x39
	ld	xix, 0xf1f8
	.byte 0xd3
	reti
	.byte 0xf0
	swi	0
	ld	b, 222:opc
	.byte 0xef, 0x01, 0xe7
	push	xwa
	.byte 0x9c, 0xf3
	reti
	.byte 0xf0
	swi	0
	ldw	ix, 8332
	ld	a, 231:opc
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
	cp	wa, 4:i3
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
	ld	xhl, (4349:16)
	ld	de, (xhl+1)
	st_rrw de, xix, iz
	ld	iy, de
	call	VoiceSlot_UpdateCurrentPointer
	ld	xhl, (4349:16)
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
	.byte 0xd1
	pop	xwa
	decf
	max
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
	call VoiceSlot_ReadCurrentParams
	pushw WA
	ld de, 1:i3
	call VoiceSlot_FinalRetZ_0xB8
	ld D,W
	popw	wa
	ld	w, d
	ret
	ld	a, e
	push	xiy
	push	xiz
	push	xhl
	call	15713141
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
	ld_rrw	iy, xix, iz
	pop	xix
	call	15713910
	srl	iz, 1
	push	xix
	ld	xix, 3262
	ld_rrw	iy, xix, iz
	pop	xix
	and	iy, 255
	sla	iz, 1
	ld	xhl, (4349:16)
	ld_rrb	a, xhl, iy
	popw	de
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
	call	15713087
	ld	(3524:16), a
	ld	w, d
	ld	a, e
	ld	de, 1:i3
	call	15713447
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ld	a, (3524:16)
	ret
	call	15713930
	push	xde
	ld	xde, 3230
	ld_rrw	iy, xde, iz
	pop	xde
	call	15713910
	srl	iz, 1
	push	xde
	ld	xde, 3262
	ld_rrw	iy, xde, iz
	pop	xde
	sla	iz, 1
	and	iy, 255
	ld	xhl, (4349:16)
	st_rrb	w, xhl, iy
	ret
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
	lda_rr	xix, xix, hl
	.byte 0x8c, 0x20, 0x85
	ldto_lerp	xix, 56
	adc	d, 0
	cp	de, 255
	jrl	ugt, 56
	ld_rrw	bc, xix, iz
	ld	xix, 61944
	.byte 0xd3, 0x07, 0xf0, 0xf8, 0xf1
	jrl	z, 15
	push	xwa
	ld	xwa, 3262
	st_rrb	e, xwa, hl
	pop	xwa
	ld	w, 0:opc
	ret
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, hl
	.byte 0x8c, 0x20, 0xf5
	ldto_lerp	xix, 56
	jrl	ule, -32
	ld	w, 255:opc
	jp	15713684
	sub	de, 256
	ld	wa, de
	xor	de, de
	ldw	bc, 251
	ld	qwa, de
	div	xwa, xbc
	ld	de, qwa
	inc	1, wa
	ld	bc, wa
	ld_rrw	iy, xix, iz
	call	15713910
	ld	xhl, (4349:16)
	ld	iy, (xhl+3)
	ld	l, (3566:16)
	xor	h, h
	cp	iy, 65535
	jrl	z, 56
	djnz16	bc, -27
	add	de, 5
	ld	xix, 61944
	.byte 0xd3, 0x07, 0xf0, 0xf8, 0xf5
	jrl	z, 47
	ld	xix, 3230
	st_rrw	iy, xix, iz
	srl	iz, 1
	ldfr_lerp	xix, 56
	lda_rr	xix, xix, iz
	ld	(xix+32), e
	ldto_lerp	xix, 56
	sla	iz, 1
	xor	w, w
	jp	15713684
	cp	bc, 1:i3
	jrl	z, -61
	ld	w, 255:opc
	jp	15713684
	.byte 0xd3, 0x07, 0xf0, 0xec, 0xf0
	jrl	ule, -55
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
	ld	bc, (61999:16)
	ld	(61999:16), iy
	xor	wa, wa
	call	15713910
	ld	xhl, (4349:16)
	ld	ix, (xhl+1)
	ld	de, ix
	cp	ix, 0:i3
	jrl	z, 132
	ld	iy, ix
	ldw	(xhl+1), 0
	call	15713910
	ld	xhl, (4349:16)
	ld	ix, iy
	ld	iy, (xhl+3)
	call	15713910
	ld	xhl, (4349:16)
	ld	ix, iy
	ld	iy, (xhl+3)
	cp	iy, 65535
	jrl	z, 29
	.byte 0x83, 0x3c, 0x7f
	ld	(xhl+5), 130
	inc	1, wa
	.byte 0xd1, 0xe6, 0x0c, 0xf0
	jrl	nz, -36
	dec	1, wa
	call	15713910
	ld	xhl, (4349:16)
	ld	(xhl+1), de
	cp	de, 0:i3
	jrl	z, 15
	push	xiy
	ld	iy, de
	call	15713910
	pop	xiy
	ld	xhl, (4349:16)
	ld	(xhl+3), iy
	ld	iy, ix
	call	15713910
	ld	xhl, (4349:16)
	.byte 0x83, 0x3c, 0x7f
	ld	(xhl+5), 130
	ld	(xhl+3), bc
	ld	iy, bc
	call	15713910
	ld	xhl, (4349:16)
	ld	(xhl+1), ix
	inc	1, wa
	add (62001:16), wa
	jp	15713909
	call	15713910
	ld	ix, iy
	ld	xhl, (4349:16)
	ld	iy, (xhl+3)
	cp	iy, 65535
	jrl	nz, -112
	ldw	(3302:16), 0
	ld	iy, ix
	.byte 0x83, 0x3c, 0x7f
	jp	15713800
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
	call	15713087
	cp	a, 129
	jrl	nz, 14
	ld	de, 1:i3
	call	15713447
	incw	1, (3426:16)
	jp	15713980
	ld	xiy, 3426
	ld	xix, 13964
	cp	a, 130
	jrl	z, 72
	cp	a, 132
	jrl	z, 93
	call	15713141
	ld	xiy, 3428
	cp	a, 0:i3
	jrl	z, 3
	ld	(xiy), 128
	cp	(3415:16), 48
	jrl	nz, 33
	.byte 0x85, 0x3f, 0x80
	jrl	nz, 7
	ld	(xiy), 0
	jp	15714084
	ld	(xiy), 128
	ld	wa, (3426:16)
	sub	wa, 1
	jrl	nc, 2
	xor	wa, wa
	ld	(3426:16), wa
	call	15725662
	jp	15714133
	.byte 0x95, 0x3f, 0x01, 0x00
	jrl	z, 13
	.byte 0x95, 0x3f, 0x00, 0x00
	jrl	z, 6
	decm	1, (xiy)
	jp	15714084
	ld	(xix), 8
	jp	15714129
	.byte 0x95, 0x3f, 0x00, 0x00
	jrl	nz, -42
	ld	(xix), 9
	call	15724622
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
	.incbin "includes/romslices/v7_transplant_VoiceSlot_StatusRet.bin"
VoiceState_SaveAndRestore:
	.byte 0x1d, 0x84, 0xef, 0xef, 0x1d, 0x15, 0xf0, 0xef
	.byte 0x0e, 0x4e, 0xf0, 0xef, 0x00, 0x47, 0xee, 0xef
	.byte 0x00, 0x47, 0xee, 0xef, 0x00, 0x64, 0xd0, 0xef
	.byte 0x00, 0x00, 0x05, 0x05, 0x0f, 0x00, 0x06, 0x04
	.byte 0x05, 0x03, 0x07, 0x02, 0x07, 0x01, 0x07, 0x07
	.byte 0x07
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

VoiceState_DataBlock1:	.ascii "(;>="
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
	call	15713930
	ld	xiy, 3230
	ld_rrw	wa, xiy, iz
	cp	(xix), wa
	jrl	nz, 44
	srl	iz, 1
	ldfr_lerp	xiy, 56
	lda_rr	xiy, xiy, iz
	ld	a, (xiy+32)
	ldto_lerp	xiy, 56
	cp	(xix+2), a
	jrl	ule, 6
	ld	w, 3:opc
	jp	15716808
	jrl	z, 6
	ld	w, 2:opc
	jp	15716808
	ld	w, 1:opc
	jp	15716808
	ld	iy, wa
	call	15713910
	ld	xhl, (4349:16)
	ld	wa, (xhl+1)
	cp	wa, 0:i3
	jrl	z, 9
	.byte 0x94, 0xf0
	jrl	z, 10
	jp	15716773
	ld	w, 3:opc
	jp	15716808
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
	jrl	ule, 6
	ld	w, 3:opc
	jp	15716859
	jrl	z, 6
	ld	w, 2:opc
	jp	15716859
	ld	w, 1:opc
	pop	xhl
	ret
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
	ldw_dri wa, 0x07, 0xe8, 0xf0
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
	jp VoiceState_DataBlock2_0x10B
.Lc_efd242:
	srl IX, 0x01
	push XDE
	ld XDE,0x00000cbe
	cpib_ind 0x07, 0xe8, 0xf0, 0x05
	pop XDE
	jrl nz, .Lc_efd238
.Lc_efd255:
	pop XIY
	pop XIX
	pop XHL
	popw wa
	ld W, 0x00:opc
	ret
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
	ldw_dri wa, 0x07, 0xe8, 0xec
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
	jp VoiceState_DataBlock2_0x173
.Lc_efd2c1:
	ld W, 0x00:opc
	pop XHL
	pushw wa
	ld A, 0x07:opc
	call VoiceSlot_RestoreState
	popw wa
	jp VoiceState_DataBlock2_0x183
.Lc_efd2d0:
	ld bc, 2:i3
	pop XHL
	ret
	push	xhl
	ld	a, (3822:16)
	dec	1, a
	ld	w, 3:opc
	mul8rr	a, w
	ld	hl, wa
	ld	w, 255:opc
	push	xde
	ld	xde, 62032
	.byte 0xf3, 0x07, 0xe8, 0xec, 0xcf
	pop	xde
	jrl	z, 2
	ld	w, 0:opc
	pop	xhl
	ret
	call	15672446
	ld	wa, hl
	cp	wa, 65535
	jrl	z, 23
	call	15717147
	bit	7, a
	jrl	nz, 13
	call	15672446
	ld	wa, hl
	cp	wa, 65535
	jrl	nz, -36
	ret
	push	xix
	call	15672553
	call	15672580
	ld	wa, hl
	pop	xix
	ret
	call TempoRingBuf_CheckEmpty
	ld WA,HL
	cp wa, 0:i3
	jrl z, .Lc_efd339
	ld W, 0x00:opc
	jp VoiceState_DataBlock2_0x1EB
.Lc_efd339:
	ld W, 0xff:opc
	ret
	call	16068368
	pushw	de
	ld	a, (64602:16)
	ld	d, (64612:16)
	and	d, 15
	call	16068329
	popw	de
	.byte 0xf1, 0x08, 0x11, 0xcf
	jrl	nz, 2
	mul8rr	a, e
	ret
	cp	(3429:16), 3
	jrl	z, 6
	ld	w, 0:opc
	jp	15717256
	call	15717397
	cp	w, 255
	jrl	z, -16
	call	15696937
	cp	w, 0:i3
	jrl	nz, 12
	ld	w, 104:opc
	call	15687771
	ld	w, 1:opc
	jp	15717256
	ret
	ld	a, 3:opc
	call	15716493
	call	15713087
	cp	a, 129
	jrl	z, 10
	call	15712700
	cp	w, 255
	jrl	nz, -20
	call	15712720
	cp	w, 255
	jrl	z, 95
	call	15713087
	cp	a, 129
	jrl	z, 85
	call	15717397
	cp	w, 0:i3
	jrl	nz, -29
	call	15712720
	cp	w, 255
	jrl	z, 47
	call	15713087
	cp	a, 129
	jrl	z, 17
	call	15717397
	cp	w, 0:i3
	jrl	nz, -29
	call	15697457
	jp	15717312
	call	15712700
	cp	w, 255
	jrl	z, 23
	call	15713087
	cp	a, 129
	jrl	z, 13
	call	15717397
	cp	w, 0:i3
	jrl	nz, -29
	call	15697457
	ld	w, 0:opc
	jp	15717396
	ld	a, 3:opc
	call	15716577
	ld	w, 255:opc
	ret
	push	xiy
	push	xix
	ld	a, 2:opc
	call	15716493
	ld	a, (3822:16)
	dec	1, a
	exts	wa
	ld	hl, wa
	sla	hl, 1
	push	xde
	ld	xde, 3230
	ld_rrw wa, xde, hl
	ld	(10431:16), wa
	srl	hl, 1
	ld	xde, 3262
	ld_rrb	a, xde, hl
	pop	xde
	xor	w, w
	ld	(10433:16), wa
	call	15723051
	ld	xix, 3765
	ld	a, (xix)
	and	a, 240
	cp	a, 176
	jrl	nz, 29
	.byte 0x8c, 0x02, 0x3f, 0x48
	jrl	nz, 22
	.byte 0x8c, 0x03, 0x3f, 0x07
	jrl	nz, 15
	ld	a, (xix+5)
	bit	4, a
	jrl	z, 6
	ld	w, 0:opc
	jp	15717504
	ld	w, 255:opc
	ld	a, 2:opc
	call	15716577
	pop	xix
	pop	xiy
	ret
	push	xwa
	ld	xwa, (4349:16)
	ldfr_lerp	xwa, 56
	pop	xwa
	.byte 0xe7, 0x38, 0x04
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	.byte 0xc1, 0x56, 0x0f, 0x3c, 0xfe
	ld	a, 4:opc
	call	15716493
	call	15713087
	cp	a, 129
	jrl	z, 24
	call	15712720
	cp	w, 255
	jrl	z, 14
	call	15713087
	cp	a, 129
	jrl	nz, -20
	call	15712700
	xor	a, a
	call	15716493
	call	15707428
	call	15713087
	cp	a, 129
	jrl	nz, 61
	jp	15717694
	call	15712700
	cp	w, 255
	jrl	z, 92
	call	15713930
	push	xde
	ld	xde, 3230
	ld_rrw	iy, xde, iz
	srl	iz, 1
	ld	xde, 3262
	ld_rrb	a, xde, iz
	pop	xde
	cp iy, (3583:16)
	jrl	nz, 7
	cp	a, (3585:16)
	jrl	nc, 49
	call	15713087
	and	a, 240
	cp	a, 176
	jrl	nz, -66
	call	15717729
	cp	a, 1:i3
	jrl	z, 9
	cp	a, 2:i3
	jrl	z, 13
	jp	15717601
	.byte 0xc1, 0x56, 0x0f, 0x3e, 0x01
	jp	15717601
	.byte 0xc1, 0x56, 0x0f, 0x3c, 0xfe
	jp	15717601
	ld	a, 4:opc
	call	15716577
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
	call	15713930
	push	xde
	ld	xde, 3230
	ld_rrw	iy, xde, iz
	ld	(10431:16), iy
	srl	iz, 1
	ld	xde, 3262
	ld_rrb	a, xde, iz
	pop	xde
	xor	w, w
	ld	(10433:16), wa
	call	15723051
	ld	a, (3765:16)
	and	a, 240
	cp	a, 176
	jrl	z, 6
	ld	a, 0:opc
	jp	15717825
	cp	(3767:16), 72
	jrl	nz, -14
	cp	(3768:16), 10
	jrl	nz, -22
	.byte 0xf1, 0xba, 0x0e, 0xcc
	jrl	z, -29
	ld	a, 1:opc
	.byte 0xf1, 0xb9, 0x0e, 0xcc
	jrl	nz, 2
	ld	a, 2:opc
	ret
	ld	a, 32:opc
	ld	w, (3421:16)
	cp	(3420:16), 3
	jrl	le, 7
	sub	w, 4
	jp	15717854
	cp	w, 4:i3
	jrl	ule, 2
	ld	w, 4:opc
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
	div8rr	a, l
	add	h, a
	inc	1, h
	cp	h, 32
	jrl	ule, 3
	sub	h, 32
	ld	(13939:16), h
	call	15724769
	ret
	ld	xix, 61856
	xor	bc, bc
	ld	c, 16:opc
	ld	a, 16:opc
	cp_spib	a, 240
	jrl	z, 7
	djnz16	bc, -9
	jp	15718020
	xor	wa, wa
	ld	a, 16:opc
	sub	wa, bc
	ld	iy, wa
	sla	iy, 1
	push	xix
	ld	xix, 15718033
	ld_rrw	bc, xix, iy
	pop	xix
	and	bc, (65516:24)
	cp	bc, 0:i3
	jrl	z, 52
	pushw	wa
	ld	xhl, 62032
	ld	c, 3:opc
	mul8rr	a, c
	ld	iy, wa
	.byte 0xf3, 0x07, 0xec, 0xf4, 0xcf
	jrl	z, 5
	popw	wa
	jp	15717998
	popw	wa
	jp	15718020
	inc	1, a
	ld	w, a
	ld	(3414:16), w
	.byte 0xc1, 0x54, 0x0d, 0x3e, 0x01, 0xc1, 0x7b, 0x28, 0x3e, 0x04
	jp	15718032
	.byte 0xc1, 0x54, 0x0d, 0x3c, 0xfe, 0xc1, 0x7b, 0x28, 0x3c, 0xfb
	xor	w, w
	ret
	normal
	nop
	push	sr
	nop
	max
	nop
	ldio	0, 16
	nop
	ld	w, 0:opc
	ld	xwa, 32768
	normal
	nop
	push	sr
	nop
	max
	nop
	ldio	0, 16
	nop
	ld	w, 0:opc
	ld	xwa, 3520692224
	pushw	bc
	push	xix
	call	15723051
	pop	xix
	popw	bc
	ld	a, (3765:16)
	pushw	bc
	push	xix
	call	15714134
	pop	xix
	popw	bc
	cp	w, 0:i3
	jrl	nz, -25
	cp	a, 130
	jrl	nz, 55
	cp	xix, 13978
	jrl	c, 102
	ld	xwa, xix
	sub	xwa, 13978
	cp	xwa, 0
	jrl	nz, 6
	ld	wa, 1:i3
	jp	15718133
	sla	wa, 3
	cp	a, 1:i3
	jrl	z, 2
	inc	1, a
	ld	(3931:16), a
	ld	(3930:16), 3
	jp	15718209
	cp	a, 132
	jrl	z, 50
	cp	a, 129
	jrl	z, 29
	ld	a, (3766:16)
	xor	w, w
	ld	l, 12:opc
	div8rr	a, l
	pushw	bc
	ld	c, a
	ldb_erp	a, 60
	ld	a, c
	scf
	.byte 0xb4, 0x2c, 0xc7, 0x3c, 0x89
	popw	bc
	jp	15718067
	inc	1, c
	cp	c, (3777:16)
	jrl	z, 6
	inc	1, xix
	jp	15718067
	ret
	ld	w, 114:opc
	call	15687771
	call	15699782
	call	15718231
	call	15718288
	ld	w, 0:opc
	ret
	call	15710015
	ld	xiz, 3411
	.byte 0x86, 0x3c, 0xbf
	call	15718314
	cp	(3429:16), 0
	jrl	nz, 30
	ld	(3434:16), 0
	call	15713087
	cp	a, 144
	jr	nz, 4
	call	15705091
	call	15720788
	call	15699930
	call	15709574
	ld	w, 0:opc
	ret
	call	15713087
	cp	a, 144
	jr	nz, 4
	call	15705091
	call	15720788
	call	15699930
	call	15709574
	ret
	ld	a, (3822:16)
	ld	(3654:16), a
	xor	wa, wa
	ld	(3435:16), wa
	ld	a, (3822:16)
	ld	(3822:16), a
	xor	wa, wa
	ld	(3652:16), wa
	call	15717076
	cp	w, 0:i3
	jrl	nz, -23
	call	15713087
	cp	a, 132
	jrl	z, 28
	cp	a, 129
	jrl	nz, 10
	call	15713141
	cp	a, 130
	jrl	z, 12
	call	15708501
	cp	(3434:16), 0
	jrl	nz, -38
	call	15713087
	cp	a, 132
	jrl	z, 44
	cp	a, 129
	jrl	nz, -54
	call	15713141
	cp	a, 130
	jrl	nz, -64
	ld	wa, (3416:16)
	cp	(3429:16), 0
	jrl	nz, 8
	ld	(3416:16), wa
	jp	15718467
	ld	(3418:16), wa
	jp	15718467
	ld	wa, (3416:16)
	cp	(3429:16), 0
	jrl	nz, 8
	ld	(3416:16), wa
	jp	15718467
	ld	(3418:16), wa
	ld	a, (3654:16)
	ld	(3822:16), a
	ret
	cp	(4486:16), 2
	jrl	nz, 47
	cp	(32422:16), 1
	jrl	z, 39
	ld	(32422:16), 0
	ld	a, (3429:16)
	cp	a, 0:i3
	jrl	z, 13
	cp	a, 3:i3
	jrl	z, 16
	call	15718532
	jp	15718531
	call	15718729
	jp	15718531
	call	15718654
	ret
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	z, 105
	jrl	ugt, 56
	ld	bc, (4357:16)
	sub	bc, wa
	.byte 0xc1, 0x57, 0x0f, 0x3e, 0x01
	cp	bc, 1:i3
	jrl	nz, 5
	.byte 0xc1, 0x57, 0x0f, 0x3c, 0xfe
	pushw	bc
	call	15697543
	call	15686671
	popw	bc
	cp	(32422:16), 1
	jrl	z, 63
	dec	1, bc
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	nz, -46
	jp	15718648
	ld	bc, (4357:16)
	sub	wa, bc
	ld	bc, wa
	.byte 0xc1, 0x57, 0x0f, 0x3e, 0x01
	cp	bc, 1:i3
	jrl	nz, 5
	.byte 0xc1, 0x57, 0x0f, 0x3c, 0xfe
	pushw	bc
	call	15697482
	call	15686671
	popw	bc
	dec	1, bc
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	nz, -38
	.byte 0xc1, 0x57, 0x0f, 0x3c, 0xfe
	ret
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	z, 63
	jrl	ugt, 35
	ld	bc, (4357:16)
	sub	bc, wa
	pushw	bc
	call	15701308
	popw	bc
	cp	(32422:16), 1
	jrl	z, 40
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	nz, -25
	jp	15718728
	ld	bc, (4357:16)
	sub	wa, bc
	ld	bc, wa
	pushw	bc
	call	15701361
	popw	bc
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	nz, -17
	ret
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	z, 61
	jrl	ugt, 30
	ld	bc, (4357:16)
	sub	bc, wa
	pushw	bc
	call	15707916
	popw	bc
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	ge, 35
	djnz16	bc, -20
	jp	15718801
	ld	bc, (4357:16)
	sub	wa, bc
	ld	bc, wa
	pushw	bc
	call	15708093
	popw	bc
	ld	wa, (13950:16)
	cp wa, (4357:16)
	jrl	le, 3
	djnz16	bc, -20
	ret
SubCPU_ToneParamDisplay:
	push	xix
	push	xiy
	bit	7, w
	jrl	nz, 67
	ld	a, (3429:16)
	cp	a, 0:i3
	jrl	z, 58
	cp	a, 3:i3
	jrl	z, 53
	cp	a, 2:i3
	jrl	z, 48
	xor	hl, hl
	ld	l, (3424:16)
	dec	1, l
	ld	xix, 61856
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x3f, 0x0c
	jrl	z, 26
	ld	(3567:16), 11
	call	15686497
	ld	(4380:16), 0
	call	15718961
	call	15719029
	call	15718880
	pop	xiy
	pop	xix
	ret
	push	xix
	push	xiy
	ld	a, (4381:16)
	ld	xix, 4382
	ld	(xix), 176
	cp	(4380:16), 2
	jrl	nz, 3
	.byte 0x84, 0x3e, 0x02
	ld	(xix+4), a
	.byte 0x8c, 0x04, 0x3c, 0x7f
	ld	(xix+5), 127
	bit	7, a
	jrl	z, 3
	.byte 0x84, 0x3e, 0x01
	ld	a, (3415:16)
	ld	(xix+1), a
	ld	a, (35998:16)
	ld	(xix+2), a
	ld	l, (4380:16)
	exts	hl
	ld	xiy, 15719270
	ld_rrb	a, xiy, hl
	ld	(xix+3), a
	pop	xiy
	pop	xix
	ret
	push XIX
	xor HL,HL
	ld l, (0x0d60:16)
	dec 1,L
	ld XIX,0x0000f1a0
	ldb_dri l, 0x07, 0xf0, 0xec
	sla HL, 0x02
	ld XIX,SubCPU_ToneDispatch
	ldl_dri xhl, 0x07, 0xf0, 0xec
	cp XHL,0xffffffff
	jrl z, .Lc_efda73
	xor WA,WA
	ld a, (0x111c:16)
	ld XIX,SubCPU_ToneDispatch_0x50
	ldb_dri a, 0x07, 0xf0, 0xe0
	ldb_dri a, 0x07, 0xec, 0xe0
	ld (0x111d:16), a
.Lc_efda73:
	pop XIX
	ret
	ld XIX,0x00000ecd
	ld A, 0x20:opc
	ldw BC, 0x001b
	lda_dpi	xbc, 240
	djnz16	bc, -6
	ld	xiy, 15719150
	ld	a, (4380:16)
	ld	w, a
	sla	a, 3
	sla	w, 1
	add	a, w
	xor	w, w
	lda_rr	xiy, xiy, wa
	ld	xix, 3791
	ldw	bc, 10
	.byte 0x85, 0x11
	xor	wa, wa
	ld	a, (4381:16)
	cp	(4380:16), 1
	jrl	z, 15
	cp	(4380:16), 2
	jrl	nz, 27
	ldw	de, 128
	jp	15719113
	ldw	de, 64
	push	xix
	call	15687244
	pop	xix
	ld	a, (4480:16)
	lda_dpi	xbc, 240
	jp	15719136
	push	xix
	call	15687218
	pop	xix
	ld	xiy, 4481
	ld	bc, 3:i3
	.byte 0x85, 0x11
	call	15686621
	ret
	.byte 0x50
	ld	xbc, 538976334
	ld	w, 32:opc
	ld	w, 58:opc
	popw	hl
	ld	xiy, 1213407321
	popw	bc
	ld	xiz, 1431583316
	popw	iz
	popw	bc
	popw	iz
	ld	xsp, 975183904
	ld	xde, 541347397
	.byte 0x53, 0x45, 0x4e, 0x53, 0x3a
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
	ld	b, 251:opc
	nop
	nop
	ldio	9, 10
	pushw	0xd7cf
	bit	7, w
	jrl	nz, 2
	ld	l, 3:opc
	cp	(4380:16), l
	jrl	z, 28
	ld	a, (4380:16)
	xor	l, l
	ld	h, 3:opc
	call	SubCPU_ToneStoreDigits
	ld	(4380:16), a
	call	SubCPU_ToneParamDisplay_0x9F
	call	SubCPU_ToneParamDisplay_0xE3
	call	SubCPU_ToneParamDisplay_0x4E
	ret
SubCPU_ToneHandler_A:
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08, 0xc1, 0x1d, 0x11
	.byte 0x21, 0xcf, 0xd7, 0x26, 0x7f, 0xc1, 0x1c, 0x11
	.byte 0x3f, 0x01, 0x7e, 0x08, 0x00, 0x27, 0x34, 0x26
	.byte 0x4c, 0x1b, 0xcd, 0xdb, 0xef
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
	jrl	z, 4
	jp	SubCPU_ToneClearRegion_0x62
	ld	w, (3538:16)
	ld	w, 6:opc
	ld	xiy, 4382
	call	SysInit_BytecodeBlock_0x486
SubCPU_ToneClearRegion:
	.incbin "includes/romslices/v7_transplant_SubCPU_ToneClearRegion.bin"
PerfMode_ParamHandler_11:
	ld	hl, bc
	cp	hl, 31
	jrl	ugt, 17
	sla	hl, 2
	push	xix
	ld	xix, SubCPU_ToneParamRet
	ld_rrl xhl, xix, hl
	pop xix
	call	(xhl)
	ret
SubCPU_ToneParamRet:
	.long UIDisp_DefaultInputHandler
	.long SubCPU_ToneDispatch_0x50 + 4
	.long DefaultHandler_Ret
	.long SubCPU_ToneHandler_A
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SoundEvt_ShortPacketHandler
	.long SoundEvt_LongPacketHandler
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long SubCPU_ToneFormatDone
	.long SubCPU_ToneClearRegion
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long DefaultHandler_Ret
	.long ToneParam_Evt0F_BytecodeHandler
	.long DefaultHandler_Ret
	.long UIDisp_DefaultInputHandler
	.long SubCPU_ToneDispatch_0x50 + 4
	.long DefaultHandler_Ret
	.long SubCPU_ToneHandler_A
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
	.incbin "includes/romslices/v7_transplant_SubCPU_ToneParamRet_tail.bin"
OscScope_HandlerTable:
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
	.byte 0x84
	push	xix
	.byte 0xdf, 0x84
	push	xiz
	ld	xwa, 0x1114e10e
	ld	d, 193:opc
	ld_spdb e, 14
	sla e, 2
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
	ld	a, (3770:16)
	ld	w, 96:opc
	muls8rr	a, w
	ld	l, (3769:16)
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
	ld	wa, (3778:16)
	ld	l, (3952:16)
	xor	h, h
	sub	wa, hl
OscScope_UpdateDisplay:
	cp	wa, 48
	jrl	z, 78
	ld	l, 96:opc
	div8rr	a, l
	cp	w, 48
	jrl	z, 23
	exts	wa
	ld	bc, wa
	pushw	bc
	call	DisplayStr_BytecodeBlock_A_0x53
	popw	bc
	djnz16	bc, -9
	ldw	(3778:16), 0
	jp	OscScope_RefreshLoop_0x3F
	ld	wa, (3778:16)
	ld	l, 96:opc
	div8rr	a, l
	cp	a, 0:i3
	jrl	z, 32
	ld	c, a
	ld	l, 96:opc
	muls8rr	a, l
	sub (3778:16), wa
	ld a, c
	dec	1, a
	cp	a, 0:i3
	jrl	z, 13
	exts	wa
	ld	bc, wa
	pushw	bc
	call	DisplayStr_BytecodeBlock_A_0x53
	popw	bc
	djnz16	bc, -9
	call	DisplayStr_BytecodeBlock_A_0x120
	ldw	(3778:16), 0
	ld	(3952:16), 0
	jp	OscScope_RefreshLoop_0x3F
OscScope_RefreshLoop:
	ld	wa, (3778:16)
	ld	l, 96:opc
	div8rr	a, l
	ld	c, a
	ld	e, w
	cp	c, 0:i3
	jrl	z, 29
	ld	a, 96:opc
	muls8rr	a, c
	sub (3778:16), wa
	xor b, b
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
	cp	e, 0:i3
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
	jrl	z, 52
	cp	wa, 0:i3
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
	cp	c, 2:i3
	jrl	ugt, 18
	cp	a, 129
	jrl	z, -29
	cp	a, 130
	jrl	z, 12
OscScope_RenderBlock:
	cp	a, 132
	jrl	z, 6
	ld	w, 255:opc
	jp	OscScope_RenderBlock_0xE
	ld	w, 0:opc
	pop	xhl
	pushw	wa
	ld	a, 7:opc
	call	VoiceSlot_RestoreState
	popw	wa
	jp	OscScope_RenderBlock_0x20
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
	stw_dpi	wa, 241
	djnz16	bc, -6
	ret
	ld	xix, 3701
	ldw	bc, 16
	xor	wa, wa
	stw_dpi	wa, 241
	djnz16	bc, -6
	ret
	ld	xix, 3733
	ldw	bc, 16
	xor	wa, wa
	stw_dpi wa, 241
	djnz16	bc, -6
	ret
	ld	xiy, 3669
	.byte 0x44
	pop	xbc
OscScope_FinalizeRender:
	; framing ported from v10's source for the same label (same span length, statement for statement); 68 of 92 slots byte-identical
	ret
	nop
	nop
	ld	c, 1:opc
	ld	e, (3666:16)
	sla	e, 1
	call	15722968
	.byte 0xc1	; v10 does not spell this byte either
	jrl	nc, 16145
	nop
	jrl	nz, 96
	ld	xiy, 3701
	ld	xix, 3705
	ld	c, 1:opc
	ld	e, (3667:16)
	sla	e, 1
	call	15722968
	.byte 0xc1	; v10 does not spell this byte either
	jrl	nc, 16145
	nop
	jrl	nz, 65
	ld	xiy, 3733
	ld	xix, 3737
	ld	c, 1:opc
	ld	e, (3668:16)
	sla	e, 1
	call	15722968
	ld	xiy, 3697
	.byte 0x85	; v10 does not spell this byte either
	push	xsp
	nop
	jrl	z, 3
	.byte 0x85	; v10 does not spell this byte either
	push	xiz
	.byte 0x80	; v10 does not spell this byte either
	ld	xiy, 3729
	.byte 0x85	; v10 does not spell this byte either
	push	xsp
	nop
	jrl	z, 3
	.byte 0x85	; v10 does not spell this byte either
	push	xiz
	.byte 0x80	; v10 does not spell this byte either
	ld	xiy, 3761
	.byte 0x85	; v10 does not spell this byte either
	push	xsp
	nop
	jrl	z, 3
	.byte 0x85	; v10 does not spell this byte either
	push	xiz
	.byte 0x80	; v10 does not spell this byte either
	ret
	ld	(4479:16), 0
	cp	e, 0:i3
	jrl	z, 72
	cp	c, e
	jrl	z, 67
	ld	a, (xiy+1)
	cp	a, 6:i3
	jrl	z, 5
	cp	a, 7:i3
	jrl	nz, 9
	ld	(4479:16), 255
	jp	15723050
	.byte 0x8c	; v10 does not spell this byte either
	.byte 0x01	; v10 does not spell this byte either
	push	xsp
	nop
	jrl	nz, 7
	.byte 0x8c	; v10 does not spell this byte either
	push	sr
	push	xsp
	nop
	jrl	z, 7
	.byte 0x8d	; v10 does not spell this byte either
	push	sr
	push	xsp
	nop
	jrl	nz, 7
	.byte 0x85	; v10 does not spell this byte either
	push	xix
	jrl	nc, 7195
	srl	xde, 133
	push	xiz
	xor	(xwa), e
	push	w
	nop
	add	ix, 4
	inc	1, c
	.byte 0x1b	; v10 does not spell this byte either
	.byte 0xe2	; differs from v10 here and llvm-objdump cannot read it
	srl	xbc, 14
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
	.byte 0xf1, 0xf6, 0x0e, 0x00, 0x00, 0xc1, 0xc1, 0x0e
	.byte 0x23, 0xcb, 0xec, 0x01, 0xdb, 0xd3, 0xc1, 0xc4
	.byte 0x0e, 0x27, 0xdb, 0xec, 0x02, 0xd8, 0xd0, 0xe1
	.byte 0x14, 0x11, 0x25, 0xc3, 0x07, 0xf4, 0xec, 0x21
	.byte 0xc9, 0xcc, 0x60, 0xc9, 0xd8, 0x7e, 0x07, 0x00
	.byte 0x21, 0x20, 0xf3, 0x07, 0xf4, 0xec, 0x41, 0xd8
	.byte 0xd0, 0xe7, 0x38, 0x9d, 0xf3, 0x07, 0xf4, 0xec
	.byte 0x35, 0xbd, 0x01, 0x00, 0x03, 0xe7, 0x38, 0x8d
	.byte 0xe7, 0x38, 0x9d, 0xf3, 0x07, 0xf4, 0xec, 0x35
	.byte 0xbd, 0x02, 0x50, 0xe7, 0x38, 0x8d, 0x1d, 0x2f
	.byte 0xeb, 0xef, 0x0e
	ld (0x0ef6:16), 0x00
	addw (0x0ec4:16), 0x0002
	ld c, (0x0ec1:16)
	sla C, 0x01
	cp	(3780:16), c
	jrl	c, 96
	ld	l, (3782:16)
	cp	l, 2:i3
	jrl	z, 26
	inc	1, l
	xor	h, h
	sla	hl, 2
	push	xde
	ld	xde, 15723636
	ld_rrl	xhl, xde, hl
	pop	xde
	ld	wa, (xhl)
	cp	wa, 0:i3
	jrl	nz, 9
	ld	(3830:16), 1
	jp	15723310
	ld	l, (3782:16)
	cp	l, 2:i3
	jrl	z, -18
	inc	1, l
	ld	xwa, 3701
	ld	e, (3667:16)
	cp	l, 1:i3
	jrl	z, 9
	ld	xwa, 3733
	ld	e, (3668:16)
	ld	(3777:16), e
	ld	(4372:16), xwa
	ld	(3782:16), l
	xor	b, b
	sub (3780:16), bc
	ret
	ld	(3830:16), 0
	ld	c, (3777:16)
	sla	c, 1
	xor	hl, hl
	ld	l, (3780:16)
	sla	hl, 2
	xor	wa, wa
	ld	xiy, (4372:16)
	ld_rrb	a, xiy, hl
	and	a, 96
	cp	a, 0:i3
	jrl	nz, 7
	ld	a, 32:opc
	st_rrb	a, xiy, hl
	xor	wa, wa
	ldfr_lerp	xiy, 56
	lda_rr	xiy, xiy, hl
	ld	(xiy+1), 4
	ldto_lerp	xiy, 56
	ldfr_lerp	xiy, 56
	lda_rr	xiy, xiy, hl
	ld	(xiy+2), wa
	ldto_lerp	xiy, 56
	call	15723516
	ret
	ld	(3830:16), 0
	incw	1, (3780:16)
	ld	c, (3777:16)
	sla	c, 1
	cp	(3780:16), c
	jrl	c, 96
	ld	l, (3782:16)
	cp	l, 2:i3
	jrl	z, 26
	inc	1, l
	xor	h, h
	sla	hl, 2
	push	xde
	ld	xde, 15723636
	ld_rrl	xhl, xde, hl
	pop	xde
	ld	wa, (xhl)
	cp	wa, 0:i3
	jrl	nz, 9
	ld	(3830:16), 1
	jp	15723515
	ld	l, (3782:16)
	cp	l, 2:i3
	jrl	z, -18
	inc	1, l
	ld	xwa, 3701
	ld	e, (3667:16)
	cp	l, 1:i3
	jrl	z, 9
	ld	xwa, 3733
	ld	e, (3668:16)
	ld	(3777:16), e
	ld	(4372:16), xwa
	ld	(3782:16), l
	xor	b, b
	sub (3780:16), bc
	ret
	popw	ix
	ret
	nop
	nop
	popw	iz
	ret
	nop
	nop
	.byte 0x50
	ret
	nop
	nop
	.byte 0xd1, 0xbf, 0x28, 0x04, 0xd1, 0xc1, 0x28, 0x04
	push	xhl
	push	xiy
	push	xix
	ld	xix, 3771
	call	15723111
	ld	(xix), a
	cp	a, 129
	jrl	z, 46
	cp	a, 132
	jrl	z, 40
	cp	a, 130
	jrl	z, 34
	inc	1, xix
	push	xix
	call	15723159
	call	15723111
	pop	xix
	bit	7, a
	jrl	z, -38
	ld	a, (3772:16)
	cp	a, 47
	jrl	z, -57
	cp	a, 95
	jrl	z, -63
	pop	xix
	pop	xiy
	pop	xhl
	.byte 0xf1, 0xc1, 0x28, 0x06, 0xf1, 0xbf, 0x28, 0x06
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
	.byte 0x1d, 0x61, 0x5b, 0xef, 0x1d, 0x47, 0xf4, 0xef
	.byte 0x44, 0xca, 0x0e, 0x00, 0x00, 0x30, 0x20, 0x20
	.byte 0x31, 0x0f, 0x00, 0xf5, 0xf1, 0x50, 0xd9, 0x1c
	.byte 0xfa, 0x45, 0x44, 0xed, 0xef, 0x00, 0x44, 0xcf
	.byte 0x0e, 0x00, 0x00, 0xd9, 0xaf, 0x85, 0x11, 0x21
	.byte 0x20, 0xf5, 0xf0, 0x41, 0x1d, 0x28, 0x5c, 0xef
	.byte 0x1d, 0x96, 0xf2, 0xef, 0x1d, 0xdd, 0x5b, 0xef
	.byte 0x0e, 0x1d, 0x61, 0x5b, 0xef, 0x1d, 0x47, 0xf4
	.byte 0xef, 0x45, 0x44, 0xed, 0xef, 0x00, 0x44, 0xcf
	.byte 0x0e, 0x00, 0x00, 0xd9, 0xaf, 0x85, 0x11, 0x1d
	.byte 0x28, 0x5c, 0xef, 0x1d, 0x96, 0xf2, 0xef, 0x1d
	.byte 0xdd, 0x5b, 0xef, 0x0e, 0x43, 0x4f, 0x4e, 0x54
	.byte 0x52, 0x4f, 0x4c, 0xc1, 0x87, 0x36, 0x26, 0xc1
	.byte 0x86, 0x36, 0x27, 0xc1, 0xf5, 0x0e, 0x26, 0xf1
	.byte 0x5b, 0x90, 0x00, 0x48, 0x1d, 0xe4, 0x99, 0xfc
	.byte 0x1d, 0x6f, 0xbc, 0xf5, 0x45, 0x0f, 0x34, 0x00
	.byte 0x00, 0x44, 0xd6, 0x0e, 0x00, 0x00, 0x31, 0x0d
	.byte 0x00, 0x85, 0x11, 0x0e, 0x1d, 0x61, 0x5b, 0xef
	.byte 0x1d, 0x47, 0xf4, 0xef, 0x45, 0x98, 0xed, 0xef
	.byte 0x00, 0x44, 0xcf, 0x0e, 0x00, 0x00, 0xd9, 0xae
	.byte 0x85, 0x11, 0x1d, 0x28, 0x5c, 0xef, 0x1d, 0x4b
	.byte 0xed, 0xef, 0x1d, 0xdd, 0x5b, 0xef, 0x0e
DisplayStr_RhythmLabel:
	.incbin "includes/romslices/v7_transplant_DisplayStr_RhythmLabel_head.bin"
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
	cp	(0xfc5a:16), 7
	jrl	nz, 13
	cp	(0xfc5b:16), 2
	jrl	nz, 5
	ld	xiy, DisplayStr_BytecodeBlock_C_0x77
	ld	xix, 3791
	ldw	bc, 25
	ldir85
	call	Display_UpdateRegion5
	call	Display_BytecodeBlock_F_0x2A2
	call	Display_UpdateRegion3
	ret
	ld	w, 32:opc
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
	.byte 0x20, 0x20, 0x54, 0x45, 0x4d, 0x50, 0x4f, 0x20
	.byte 0x20, 0x15, 0x3d, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x54, 0x45, 0x4d, 0x50, 0x4f
	.byte 0x20, 0x20, 0x93, 0x3d, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x1d, 0x61, 0x5b, 0xef
	call Display_BytecodeBlock_F_0x32D
	ld XIY,DisplayStr_TempoString_0x56
	ld XIX,0x00000eca
	ldw BC, 0x0019
	.byte 0x85, 0x11, 0x1d, 0x28, 0x5c, 0xef, 0x1d, 0xdd
	.byte 0x5b, 0xef, 0x1d, 0x0f, 0x5c, 0xef, 0x0e, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x1d, 0x61, 0x5b, 0xef, 0x0e
	ld wa, (0x367e:16)
	cp WA,0x03e8
	jrl c, .Lc_efef97
	call DisplayStr_FillDashes
	jp DisplayStr_TempoString_0x9F
.Lc_efef97:
	call ParamDigit_ExtractAndFormat
	ld XIY,0x00001181
	ld XIX,0x00000eca
	ld WA,(XIY)
	ld (XIX),WA
	ld A,(XIY+0x02)
	ld (XIX+0x02),A
	ret
DisplayStr_FillDashes:
	ld xix, 0xeca
	ld a, 0x2d:opc
	ld (xix), a
	ld (xix + 1), a
	ld (xix + 2), a
	ret

DisplayStr_BytecodeBlock_D:
	.byte 0x1d, 0x61, 0x5b, 0xef, 0x1d, 0x84, 0xef, 0xef
	.byte 0xc1, 0x87, 0x36, 0x26, 0xc1, 0x86, 0x36, 0x27
	.byte 0xc1, 0xf5, 0x0e, 0x26, 0xf1, 0x5b, 0x90, 0x00
	.byte 0x48, 0x1d, 0xe4, 0x99, 0xfc, 0x1d, 0x6f, 0xbc
	.byte 0xf5, 0x1d, 0xfe, 0xef, 0xef, 0x45, 0x0f, 0x34
	.byte 0x00, 0x00, 0x44, 0xcf, 0x0e, 0x00, 0x00, 0x31
	.byte 0x0d, 0x00, 0x85, 0x11, 0x21, 0x20, 0xf5, 0xf0
	.byte 0x41, 0x1d, 0xdd, 0x5b, 0xef, 0x0e
DisplayStr_ClearRegion:
	pushw wa
	pushw bc
	push xix
	ld xix, 0xecd
	ldw bc, 0x1b
	ld a, 0x20:opc

DisplayStr_ClearLoop:
	lda_dpi XBC, 0xf0
	djnz xbc, DisplayStr_ClearLoop
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
	.byte 0xf3, 0x07, 0xf4, 0xe0, 0x35, 0x30, 0x20, 0x20
	.byte 0xf5, 0xf1, 0x50, 0xf5, 0xf1, 0x50, 0xd9, 0xac
	.byte 0x95, 0x11, 0x21, 0x20, 0xd9, 0xab
DisplayStr_StyleClearLoop:
	lda_dpi XBC, 0xf0
	djnz xbc, DisplayStr_StyleClearLoop
	call Display_UpdateRegion3
	ret

DisplayStr_BytecodeBlock_E:
	ret
	ld XIX,0x00000ed4
	xor XHL,XHL
	ld l, (0x368c:16)
	sla XHL, 0x03
	ld XIY,DisplayStr_StyleSectionNames
	.byte 0xf3, 0x07, 0xf4, 0xec, 0x35, 0xd9, 0xac, 0x95
	.byte 0x11, 0x30, 0x20, 0x20, 0xf5, 0xf1, 0x50, 0xf5
	.byte 0xf1, 0x50, 0x1d, 0xdd, 0x5b, 0xef, 0x0e
DisplayStr_StyleSectionNames:	.ascii "        START   STOP    FILL IN1FILL IN2INTRO1  COUNT INENDING1 END     REPEAT  CLEAR   ENDING2 INTRO2  "
	ret
	call	Display_UpdateRegion2
	ret

Display_RedrawMenu:
	ld	wa, (13950:16)
	cp	wa, 1000
	jrl	c, 8
	call	15724464
	jp	15724821
Display_RedrawMenu_Extract:
	call	15687218
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
	call Display_BytecodeBlock_F_0x32D
	ld XIX,0x00000eca
	ldw (XIX+0x09), 0x5620
	call Display_UpdateRegion5
	call StringData_KeyNames_0x29E
	call StringData_KeyNames_0x180
	call Display_UpdateRegion3
	call Display_UpdateRegion4
	ret
	ld	xix, 3796
	ld	xiy, 15725086
	ld	a, (4539:16)
	ld	xhl, 15725070
	ld_rr8b	a, xhl, a
	exts	wa
	cp	(4539:16), 23
	jrl	nz, 6
	ld	a, 17:opc
	jp	15724915
	cp	(4539:16), 64
	jrl	nz, 2
	ld	a, 16:opc
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
	jrl	nz, 31
	ld	xix, 3800
	ld	xiy, 15727518
	cp	l, 127
	jrl	nz, 7
	cp	h, 3:i3
	jrl	nz, 2
	inc	4, xiy
	ld	bc, 4:i3
	.byte 0x85, 0x11
	jp	15725069
	call	16554468
	ld	a, 9:opc
	mul8rr	a, l
	ld	hl, wa
	push	xde
	xor	xwa, xwa
	xor	xbc, xbc
	ld	a, (4541:16)
	ld	c, (4540:16)
	ld	xde, 4543
	call	16703099
	pop	xde
	ld	xiy, 4543
	ld	xix, 3800
	cp	(4539:16), 64
	jrl	nz, 28
	cp	(4541:16), 128
	jrl	nz, 20
	cp	(4540:16), 3
	jrl	nz, 12
	ldw	(xix), 17999
	ld	(xix+2), 70
	jp	15725069
	ldw	bc, 16
	.byte 0x85, 0x11
	ret
	nop
	normal
	push	sr
	pop	sr
	max
	halt
	ei	0x07
	ldio	9, 10
	pushw 3340
	ret
	retd	0x5452
	ldw	bc, 21024
	.byte 0x54
	ldw	de, 19488
	ld	xiz, 542122068
	ldw	ix, 20512
	ld	w, 53:opc
	ld	w, 80:opc
	ld	w, 54:opc
	ld	w, 80:opc
	ld	w, 55:opc
	ld	w, 80:opc
	ld	w, 56:opc
	ld	w, 80:opc
	ld	w, 57:opc
	ld	w, 80:opc
	ldw	bc, 8240
	.byte 0x50
	ldw	bc, 8241
	.byte 0x50
	ldw	bc, 8242
	.byte 0x50
	ldw	bc, 8243
	.byte 0x50
	ldw	bc, 8244
	.byte 0x50
	ldw	bc, 8245
	popw	hl
	ld	xde, 1430528080
	ld	xbc, 1347636556
	ld	w, 45:opc
	pushw	iy
	pushw	iy
	pushw	iy
	normal
	push	sr
	pop	sr
	max
	call	15686497
	call	15725639
	ld	xix, 3786
	ld	(xix+4), 83
	ldw	(xix+5), 21839
	ldw	(xix+7), 17486
	call	15686696
	call	15724865
	call	15686621
	ret
	ld	xiy, 15725349
	ld	xix, 3800
	xor	hl, hl
	ld	l, (13956:16)
	and	l, 7
	sla	hl, 3
	lda_rr	xiy, xiy, hl
	ld	wa, (xiy)
	ld	(xix), wa
	ld	wa, (xiy+2)
	ld	(xix+2), wa
	ld	wa, (xiy+4)
	ld	(xix+4), wa
	ld	w, (xiy+6)
	ld	(xix+6), w
	cp	l, 0:i3
	jrl	z, 88
	cp	(13956:16), 1
	jrl	nz, 8
	call	15725427
	jp	15725348
	ld	xix, 3807
	ld	a, (13957:16)
	bit	7, a
	jrl	z, 36
	and	a, 127
	cp	a, 0:i3
	jrl	z, 14
	ld	xiy, 15725421
	jp	15725313
	ld	xiy, 15725424
	ld	wa, (xiy)
	ld	(xix), wa
	ld	a, (xiy+2)
	ld	(xix+2), a
	jp	15725348
	xor	w, w
	call	15687218
	ld	xiy, 4481
	ld	wa, (xiy)
	ld	(xix), wa
	ld	a, (xiy+2)
	ld	(xix+2), a
	ret
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	.byte 0x50
	pushw	iz
	ld	xde, 1027886661
	ld	w, 77:opc
	popw sp
	ld	xix, 1025515566
	ld	w, 69:opc
	pop	xwa
	.byte 0x50
	pushw	iz
	ld	w, 32:opc
	push	xiy
	ld	w, 80:opc
	pushw	iz
	popw	iy
	ld	xiy, 540876877
	ld	xbc, 539907142
	ld	w, 61:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	popw sp
	popw	iz
	popw sp
	ld	xiz, 3251693638
	.byte 0x85, 0x36
	ld	a, 193:opc
	ccf
	scf
	ld	w, 201:opc
	scc	nc, d
	and	w, 127
	rrc	w
	ld	e, w
	and	e, 128
	and	w, 127
	or	a, e
	ldw	de, 1000
	div	xwa, xde
	push	xwa
	call	15687218
	pop	xwa
	ld	xix, 3807
	ld	xiy, 4482
	ld	bc, 2:i3
	.byte 0x85, 0x11
	ld	wa, qwa
	push	xix
	call	15687258
	pop	xix
	ld	xiy, 4481
	ld	bc, 3:i3
	.byte 0x85, 0x11
	ret
	ld	wa, (3826:16)
	cp	(64602:16), 7
	jrl	nz, 19
	cp	(64603:16), 2
	jrl	nz, 11
	pushw	hl
	sla	wa, 1
	ld	l, 3:opc
	div8rr	a, l
	popw	hl
	xor	w, w
	call	15687218
	ld	xiy, 4481
	ld	xix, 3802
	ld	wa, (xiy)
	ld	(xix), wa
	ld	w, (xiy+2)
	ld	(xix+2), w
	ret
	ld	xiy, 15725601
	ld	xix, 3791
	cp	(64602:16), 7
	jrl	nz, 13
	cp	(64603:16), 2
	jrl	nz, 5
	ld	xiy, 15725620
	ldw	bc, 26
	.byte 0x85, 0x11
	call	15725500
	call	15686621
	ret
	ld	w, 84:opc
	ld	xiy, 542068813
	ld	w, 32:opc
	pop_a
	push	xiy
	push 32
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 84:opc
	ld	xiy, 542068813
	ld	w, 32:opc
	.byte 0x93, 0x3d, 0x09, 0x20
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ldw	bc, 15
	ld	xix, 3786
	ldw	wa, 8224
	stw_dpi	wa, 241
	djnz16	bc, -6
	ret
	call	15686497
	ret
	ld	bc, 7:i3
	ld	xix, 3796
	push	xix
	ldw	wa, 8224
	stw_dpi	wa, 241
	djnz16	bc, -6
	pop	xix
	cpw	(3426:16), 0
	jrl	z, 62
	stib_dsp	240, 27
	stib_dsp	240, 139
	ld	wa, (3426:16)
	call	15687181
	ld	xiy, 4481
	ldb_spi	a, 244
	lda_dpi	xbc, 240
	.byte 0x85, 0x3f, 0x20
	jrl	z, 18
	ldb_spi	a, 244
	lda_dpi	xbc, 240
	.byte 0x85, 0x3f, 0x20
	jrl	z, 6
	ldb_spi	a, 244
	lda_dpi	xbc, 240
	.byte 0xf1, 0x64, 0x0d, 0xcf
	jrl	z, 14
	stib_dsp	240, 43
	.byte 0xf1, 0x64, 0x0d, 0xcf
	jrl	z, 3
	ld	(xix), 28
	ret
	ld	wa, (13950:16)
	cp	wa, 1000
	jrl	c, 8
	call	15724464
	jp	15725805
	call	15687218
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
	muls8rr a, l
	ld hl, wa
	extz xhl
	ld xiy, StringData_KeyNames_0x20
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
	ld xiy, StringData_KeyNames_0x160
	lda_dri XIY, 0x07, 0xf4, 0xec
	ld wa, (xiy)
	ld (xix), wa
	ld wa, (xiy + 2)
	ld (xix + 2), wa
	ret

StringData_KeyNames:
	.byte 0x20, 0x20, 0x43, 0x20, 0x44, 0x88, 0x44, 0x20
	.byte 0x45, 0x88, 0x45, 0x20, 0x46, 0x20, 0x46, 0x8c
	.byte 0x47, 0x20, 0x41, 0x88, 0x41, 0x20, 0x42, 0x88
	.byte 0x42, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
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
	.byte 0x20, 0x20, 0x20, 0x20, 0x13, 0x20, 0x20, 0x20
	.byte 0x14, 0x2e, 0x20, 0x20, 0x14, 0x20, 0x20, 0x20
	.byte 0x15, 0x20, 0x20, 0x20, 0x15, 0x2e, 0x20, 0x20
	.byte 0x16, 0x20, 0x20, 0x20, 0x58, 0x58, 0x20, 0x20
	ld XIX,0x00000ed9
	xor HL,HL
	ld l, (0x3678:16)
	and L,0x0f
	sla HL, 0x02
	ld XIY,StringData_KeyNames_0x1FE
	lda_rr	xiy, xiy, hl
	ld	wa, (xiy)
	ld	(xix+256), wa
	ld	w, (xiy+2)
	ld	(xix+2), w
	ld	xix, 3805
	xor	hl, hl
	ld	l, (13945:16)
	and	l, 15
	ld	a, 5:opc
	muls8rr	a, l
	ld	hl, wa
	ld	xiy, 15726509
	lda_rr	xiy, xiy, hl
	ld	wa, (xiy+256)
	ld	(xix+256), wa
	ld	wa, (xiy+2)
	ld	(xix+2), wa
	ld	a, (xiy+4)
	ld	(xix+4), a
	ld	xix, 3811
	xor	hl, hl
	ld	l, (13946:16)
	and	l, 3
	sla	hl, 2
	ld	xiy, 15726589
	lda_rr	xiy, xiy, hl
	ld	wa, (xiy+256)
	ld	(xix+256), wa
	ld	wa, (xiy+2)
	ld	(xix+2), wa
	ret
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 24:opc
	.byte 0x1f
	ld	w, 32:opc
	push_f
	ld	w, 32:opc
	ld	w, 23:opc
	.byte 0x1f
	ld	w, 32:opc
	ldf	0x20
	ld	w, 32:opc
	.byte 0x16, 0x1f
	ld	w, 32:opc
	ex_ff
	ld	w, 32:opc
	ld	w, 21:opc
	.byte 0x1f
	ld	w, 32:opc
	pop_a
	ld	w, 32:opc
	ld	w, 20:opc
	ld	w, 32:opc
	ld	w, 19:opc
	ld	w, 32:opc
	zcf
	ld	w, (xhl+50)
	zcf
	ld	w, (xhl+51)
	zcf
	ld	w, (xhl+52)
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 43:opc
	ld	w, 24:opc
	.byte 0x1f
	ld	w, 43:opc
	ld	w, 24:opc
	ld	w, 32:opc
	pushw	hl
	ld	w, 23:opc
	.byte 0x1f
	ld	w, 43:opc
	ld	w, 23:opc
	ld	w, 32:opc
	pushw	hl
	ld	w, 22:opc
	.byte 0x1f
	ld	w, 43:opc
	ld	w, 22:opc
	ld	w, 32:opc
	pushw	hl
	ld	w, 21:opc
	.byte 0x1f
	ld	w, 43:opc
	ld	w, 21:opc
	ld	w, 32:opc
	pushw	hl
	ld	w, 20:opc
	ld	w, 32:opc
	pushw	hl
	ld	w, 19:opc
	ld	w, 32:opc
	pushw	hl
	ld	w, 19:opc
	.byte 0x8b, 0x32, 0x2b
	ld	w, 19:opc
	.byte 0x8b, 0x33, 0x2b
	ld	w, 19:opc
	ld	w, (xhl+52)
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 84:opc
	ld	xiy, 1330533710
	.byte 0x52
	popw	iy
	.byte 0x53, 0x54
	ld	xbc, 1414873923
	.byte 0x54
	ld	xix, 3791
	cp	(13947:16), 255
	jrl	nz, 22
	ldw	wa, 8224
	ld	(xix+256), wa
	ld	(xix+2), wa
	ld	(xix+4), wa
	ld	(xix+6), wa
	ld	(xix+8), a
	jp	15726721
	xor	wa, wa
	ld	a, (13948:16)
	ld	l, 12:opc
	divs8rr	a, l
	ld	xiy, 15726722
	xor	bc, bc
	ld	c, w
	sla	bc, 1
	lda_rr	xiy, xiy, bc
	ld	bc, (xiy)
	ld	(xix), bc
	ld	xiy, 15726746
	xor	bc, bc
	ld	c, a
	sla	bc, 1
	lda_rr	xiy, xiy, bc
	ld	wa, (xiy)
	ld	(xix+2), wa
	xor	wa, wa
	ld	a, (13947:16)
	call	15687218
	ld	wa, (4481:16)
	ld	(xix+6), wa
	ld	a, (4483:16)
	ld	(xix+8), a
	ld	(xix+5), 86
	ret
	ld	w, 67:opc
	ld	xhl, 1145315468
	.byte 0x8c, 0x20, 0x45
	ld	w, 70:opc
	ld	xiz, 1195843724
	.byte 0x8c, 0x20, 0x41
	ld	xbc, 759308428
	ldw	de, 12589
	ldw	wa, 12576
	ld	w, 50:opc
	ld	w, 51:opc
	ld	w, 52:opc
	ld	w, 53:opc
	ld	w, 54:opc
	ld	w, 55:opc
	ld	w, 56:opc
	.byte 0x20
	cp (0x0def:16), 0x0a
	jrl z, .Lc_eff8c1
	ld (0x0def:16), 0x0a
	call Display_UpdateRegion0
.Lc_eff8c1:
	call DisplayStr_ClearRegion
	ld l, (0x10f1:16)
	xor H,H
	sla HL, 0x02
	ld XIY,StringData_PartNames
	.byte 0xf3, 0x07, 0xf4, 0xec, 0x35, 0x44, 0xd1, 0x0e
	.byte 0x00, 0x00, 0xd9, 0xac, 0x85, 0x11, 0x45, 0x08
	.byte 0xf9, 0xef, 0x00, 0xec, 0x61, 0xd9, 0xaf, 0x85
	.byte 0x11, 0xc1, 0xf3, 0x10, 0x21, 0xc8, 0xd0, 0x3c
	.byte 0x1d, 0x32, 0x5e, 0xef, 0x5c, 0x45, 0x81, 0x11
	.byte 0x00, 0x00, 0xec, 0x61, 0xd9, 0xab, 0x85, 0x11
	.byte 0x1d, 0xdd, 0x5b, 0xef, 0x0e, 0x56, 0x4f, 0x4c
	.byte 0x55, 0x4d, 0x45, 0x3d
StringData_PartNames:	.ascii "RT1 RT2 LFT P 4 P 5 P 6 P 7 P 8 P 9 P10 P11 P12 P13 P14 P15 KBP AC1 AC2 AC3 XXXXDRUM"
	.byte 0xc1, 0xef
	decf
	push	xsp
	ldwio	118, 9
	ld	(3567:16), 10
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3793
	ld	bc, 4:i3
	.byte 0x85
	scf
	ld	xiy, StringData_PartNames_0xAC
	inc	1, xix
	ld	bc, 7:i3
	.byte 0x85
	scf
	ld	a, (4339:16)
	xor	w, w
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	ld	xiy, 4481
	inc	1, xix
	ld	bc, 3:i3
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
	ld	(3567:16), 10
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3791
	ld	bc, 4:i3
	.byte 0x85
	scf
	ld	xiy, StringData_PartNames_0x116
	inc	1, xix
	ldw	bc, 10
	.byte 0x85
	scf
	ld	a, (4339:16)
	xor	w, w
	ldw	de, 64
	push	xix
	call	ParamDigit_CalrData
	pop	xix
	inc	1, xix
	ld	a, (4480:16)
	lda_dpi xbc, 240
	ld xiy, 4481
	ld	bc, 3:i3
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
	ld	(3567:16), 10
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3791
	ld	bc, 4:i3
	.byte 0x85
	scf
	ld	xiy, StringData_PartNames_0x182
	inc	1, xix
	ld	bc, 7:i3
	.byte 0x85
	scf
	ld	a, (4339:16)
	xor	w, w
	ldw	de, 128
	push	xix
	call	ParamDigit_CalrData
	pop	xix
	inc	1, xix
	ld	a, (4480:16)
	lda_dpi xbc, 240
	ld xiy, 4481
	ld	bc, 3:i3
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.ascii "TUNING=US1 US2 US3 BAS P 8 P 9 P10 LS1 LS2 LS3 P11 P12 P13 P14 P15 KBP "
	.byte 0xc1, 0xef
	decf
	push	xsp
	ldwio	118, 9
	ld	(3567:16), 10
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
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
	ld	bc, 4:i3
	.byte 0x85
	scf
	ld	xiy, StringData_PartNames_0x222
	inc	1, xix
	ldw	bc, 10
	.byte 0x85
	scf
	ld	a, (4339:16)
	xor	w, w
	push	xix
	call	ParamDigit_ExtractAndFormat
	pop	xix
	inc	1, xix
	ld	xiy, 4482
	ld	bc, 2:i3
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.ascii "BEND SENS="
	.byte 0xc1, 0xef
	decf
	push	xsp
	normal
	jrl	z, 9
	ld	(3567:16), 1
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3791
	ld	bc, 4:i3
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
	ld	l, 4:opc
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
	normal
	jrl	z, 9
	ld	(3567:16), 1
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3791
	ld	bc, 4:i3
	.byte 0x85
	scf
	ld	xiy, StringData_PartNames_0x2EB
	inc	1, xix
	ldw	bc, 11
	.byte 0x85
	scf
	xor	hl, hl
	ld	l, 4:opc
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
	normal
	jrl	z, 9
	ld	(3567:16), 1
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3791
	ld	bc, 4:i3
	.byte 0x85
	scf
	.byte 0x45
	.long StringData_EffectLabel
	inc	1, xix
	ld	bc, 7:i3
	.byte 0x85
	scf
	.byte 0xdb
	and	(xix+4339), iz
	jrl	nz, 2
	ld	l, 4:opc
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
	normal
	jrl	z, 9
	ld	(3567:16), 1
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3791
	ld	bc, 4:i3
	.byte 0x85
	scf
	ld	xiy, StringData_EffectLabel_0x5C
	inc	1, xix
	ldw	bc, 11
	.byte 0x85
	scf
	xor	w, w
	ld	a, (4339:16)
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	bc, 3:i3
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.ascii "DSP EFFECT=¡"
	.byte 0xef
	decf
	push	xsp
	normal
	jrl	z, 9
	ld	(3567:16), 1
	call	Display_UpdateRegion0
	call	DisplayStr_ClearRegion
	ld	l, (4337:16)
	xor	h, h
	sla	hl, 2
	ld	xiy, StringData_PartNames
	lda_rr xiy, xiy, hl
	ld xix, 3791
	ld	bc, 4:i3
	.byte 0x85
	scf
	ld	xiy, StringData_EffectLabel_0xBB
	inc	1, xix
	ld	bc, 7:i3
	.byte 0x85
	scf
	xor	w, w
	ld	a, (4339:16)
	call	ParamDigit_ExtractAndFormat
	ld	xiy, 4481
	ld	bc, 3:i3
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
	normal
	jrl	z, 11
	ld	(3567:16), 1
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
	.ascii "PANEL MEMORY="
	.byte 0xc1, 0xef
	decf
	push	xsp
	normal
	jrl	z, 11
	ld	(3567:16), 1
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
	cp	a, 0:i3
	jr	z, 13
	cp	a, 1:i3
	jr	z, 0
	ld	xiy, StringData_EffectLabel_0x187
	jp	StringData_EffectLabel_0x176
	ld	xiy, StringData_EffectLabel_0x18A
	ld	bc, 3:i3
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.byte 0x46
	.ascii "ADE-IN ON OFF"
	.byte 0xc1, 0xef
	decf
	push	xsp
	normal
	jrl	z, 11
	ld	(3567:16), 1
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
	cp	a, 0:i3
	jr	z, 13
	cp	a, 1:i3
	jr	z, 0
	ld	xiy, StringData_EffectLabel_0x187
	jp	StringData_EffectLabel_0x1CB
	ld	xiy, StringData_EffectLabel_0x18A
	ld	bc, 3:i3
	.byte 0x85
	scf
	call	Display_UpdateRegion3
	ret
	.ascii "FADE-OUT "
	.byte 0xc1, 0xef
	decf
	push	xsp
	normal
	jrl	z, 11
	ld	(3567:16), 1
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
	.incbin "includes/romslices/v7_transplant_StringData_APCModeNames.bin"
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
	normal
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
	normal
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
	normal
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
	ld	l, 0:opc
	ldw	de, 6912
	ldwio	8, 0x5500
	nop
	ld	l, 0:opc
	pop	xsp
	nop
	jp	2058
	.byte 0x82
	nop
	ld	l, 0:opc
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
	ld	w, 41:opc
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
	ld	xiy, 14730518
	ld	xix, 14730528
	call	15686863
	cp	(13939:16), 0
	jr	z, 56
	ld	a, (13939:16)
	ld	(4495:16), a
	ld	xiy, 14730646
	call	15686922
	jr	37
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

	.byte 0x7e, 0xaf, 0x00	; jrl nz, Scoop_SidePanel_End (v7 displacement)

	.byte 0xc1, 0x9c, 0x8c, 0x3f, 0x8a	; cpdi8 (0x8d38), 138 (v7 patched)

	.byte 0x7e, 0xa7, 0x00	; jrl nz, Scoop_SidePanel_End (v7 displacement)

	.byte 0x45, 0x92, 0x36, 0x00, 0x00	; ld xiy, 0x372e (v7 patched)

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
	mul8rr a, c
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
	lda_dpi XBC, 0xf0
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_CopyLoop
	ld xix, 0x1192
	ld xiy, 0xe75
	ld c, 0x8:opc

Scoop_ButtonLabels_DrawRow1:
	ld a, (xiy)
	lda_dpi XBC, 0xf0
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_DrawRow1
	ld xiy, 0xe95
	ld c, 0x8:opc

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
	ld c, 0x8:opc

Scoop_ButtonLabels_Part1:
	ld a, (xiy)
	lda_dpi XBC, 0xf0
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_Part1
	ld xiy, 0xe76
	ld c, 0x8:opc

Scoop_ButtonLabels_Part2:
	ld a, (xiy)
	lda_dpi XBC, 0xf0
	add xiy, 0x4
	djnz8 c, Scoop_ButtonLabels_Part2
	ld xiy, 0xe96
	ld c, 0x8:opc

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
	ld c, 0x8:opc

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
	ld c, 0x8:opc

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
	ld c, 0x8:opc

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
	ldw_erp DE, 0xe2
	div xwa, xbc
	stw_erp DE, 0xe2
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
	.byte 0xf1
	.ascii "z&`X—"
	.byte 0xba
	pushw	wa
	ld	(0x35216e:24), 1
	sub iy, (10428:16)
	ld	(9874:16), iy
	ld	iy, (0x28bc:16)
	ldw	ix, 256
	sub ix, (10422:16)
	ld	(9876:16), ix
	ld	ix, (0x28b6:16)
	jrl	431
	ld	wa, (0x28b6:16)
	cp wa, (10428:16)
	jr	c, 4
	jr	z, 4
	jr	ugt, 5
	jr	6
	jrl	143
	jrl	252
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
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 3
	jrl	407
	cp de, (10426:16)
	jr	nz, 2
	jr	44
	ld	bc, (9870:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams_0x38
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 3
	jrl	377
	ld	bc, (9872:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, -49
	jrl	355
	ld	wa, (9870:16)
	ld	(9876:16), wa
	ldw	bc, 256
	sub	bc, 5
	ld	(9874:16), bc
	jrl	269
	ldw	bc, 256
	sub bc, (10428:16)
	ld	iy, (0x28bc:16)
	ld	ix, (0x28b6:16)
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
	cp de, (10426:16)
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
	ld	(9876:16), bc
	ld	(9874:16), bc
	jrl	157
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
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 3
	jrl	155
	ld	bc, (9870:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 3
	jrl	133
	cp de, (10426:16)
	jr	nz, 2
	jr	42
	ld	bc, (9872:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams_0x38
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 2
	jr	104
	ld	bc, (9870:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, -48
	jr	83
	ld	wa, (9872:16)
	ld	(9876:16), wa
	ldw	wa, 256
	sub	wa, 5
	ld	(9874:16), wa
	ldw	wa, 255
	sub wa, (10424:16)
	ld	bc, (9874:16)
	sub	bc, wa
	ld	(9880:16), bc
	cp (9876:16), bc
	jr	nc, 2
	jr	6
	call	Scoop_SpecialMode_UpdateParams_0x70
	jr	33
	ld	bc, (9876:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
	call	Scoop_SpecialMode_UpdateParams_0x38
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	z, 2
	jr	12
	ld	bc, (9880:16)
	sub bc, (9876:16)
	call	Scoop_SpecialMode_UpdateParams_0x70
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
	.byte 0xb0
	dec	6, l
	reti
	ld	(0x287a:16), 11
	jr	12
	push	xwa
	ld	xwa, (4349:16)
	ld	(9854:16), xwa
	pop	xwa
	ld	iy, 5:i3
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
	.byte 0xb4
	sbc	w, l
	dec	6, l
	reti
	ld	(0x287a:16), 11
	jr	10
	ld	xwa, (4349:16)
	ld	(9850:16), xwa
	ld	ix, 5:i3
	ret
	pushw	wa
	push	xde
	push	xhl
	cp	bc, 0:i3
	jr	z, 26
	ld	xhl, (9854:16)
	ld	xde, (9850:16)
	extz	xix
	extz	xiy
	add	xiy, xhl
	add	xix, xde
	.byte 0x85
	scf
	sub	xiy, (9854:16)
	sub	xix, (9850:16)
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
	.byte 0x1d, 0xd3, 0x2b, 0xf2, 0xe1, 0xfd, 0x10, 0x23
	.byte 0xdd, 0x8c, 0x9b, 0x03, 0x25, 0xdd, 0xcf, 0xff
	.byte 0xff, 0x6e, 0x96, 0xf1, 0xe6, 0x0c, 0x02, 0x00
	.byte 0x00, 0xdc, 0x8d, 0x83, 0x3c, 0x7f, 0x68, 0x9a
	ld E,A
	extz DE
	ld A,C
	extz WA
	ld BC,DE
	ld DE,WA
	ld wa, 1:i3
	jp 0xfee40d
Scoop_CurveUpdate_NextSegment:
	ld	e, a
	extz	de
	ld	a, c
	extz	wa
	ld	bc, de
	ld	de, wa
	ld	wa, 2:i3
	jp	16704525
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
	mul xwa, xde
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
	ld	w, 216:opc
	push	40
	nop
	sub	hl, wa
	sll	hl, 3
	ld	(xsp+266), hl
	ld	iy, 0:i3
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
	lda	xhl, (StyleUI_ScreenData_CtlOnly_0x23:24)
	ld_rrb a, xhl, wa
	ld (xix), a
	inc 1, iy
	cp iy, de
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
	lda	xbc, (Str_No_0xCEE:24)
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ld	w, 191:opc
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
	ld	w, 243:opc
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
	lda_rr xbc, xbc, wa
	ld wa, (xbc)
	extz	xwa
	div	wa, 40
	ld	(xsp+2), wa
	ld	wa, (xbc)
	extz	xwa
	div	wa, 40
	ld wa, qwa
	sll wa, 3
	ld (xsp+256), wa
	ld	wa, (xsp+2)
	.byte 0x99, 0x04, 0x80
	ld	(xsp+6), wa
	ld	wa, (xbc+2)
	sll	wa, 3
	ld bc, (xsp+256)
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
	jr	z, 2
	.byte 0xcf
	swi	7
	ld	a, l
	sll	a, 2
	extz	wa
	add	wa, wa
	ld	xbc, (xbc+7)
	lda_rr xbc, xbc, wa
	ld wa, (xbc)
	ld (xsp+256), wa
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
	ld (xsp+256), bc
	ld	bc, (xsp+2)
	.byte 0x98, 0x06, 0x81
	ld	(xsp+6), bc
	ld	wa, (xwa+4)
	sll	wa, 3
	ld bc, (xsp+256)
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
	ld	ix, 0:i3
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
	lda	xiy, (StyleUI_ScreenData_CtlOnly_0x23:24)
	ld_rrb c, xiy, bc
	ld (xhl), c
	inc 1, ix
	cp ix, de
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
	ld	xwa, 6:i3
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
	ld (xsp+256), bc
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
	ldb_erp a, 248
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
	ld	a, 217:opc
	push	40
	nop
	sub	hl, bc
	sll	hl, 3
	.byte 0xf3
	swi	5
	nop
	.byte 0x01, 0x53
	ld	ix, 0:i3
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
	lda	xiy, (StyleUI_ScreenData_CtlOnly_0x23:24)
	ld_rrb c, xiy, bc
	ld (xhl), c
	inc 1, ix
	cp ix, de
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
	ld	xwa, 1:i3
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
	lda xsp, (xsp-268)
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
	ld	ix, 0:i3
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
	ld	xwa, 2:i3
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
	ld (xsp+256), bc
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
	ld (xsp+256), bc
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
	ld (xsp+256), bc
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
	ld	xiy, 14732482
	lda	xix, (xsp+264)
	ld	bc, 4:i3
	.byte 0x95	; llvm-mc cannot spell this byte
	scf
	ld	wa, (xiz+2)
	extz	xwa
	ld	e, (xiz+4)
	ld	c, (xiz+5)
	ld	a, (xwa)
	and	a, e
	ld	e, a
	ld	a, c
	and	a, 15
	jr	z, 2	; -> 0xF0218A
	.byte 0xcd	; llvm-mc cannot spell this byte
	swi	7
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
	jr	z, 28	; -> 0xF021D6
	cp	wa, 1:i3
	jr	nz, 48	; -> 0xF021EE
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52426
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	jr	46	; -> 0xF02204
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52430
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	jr	22	; -> 0xF02204
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52434
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	ld	a, (xiz+6)
	and	a, 63
	extz	wa
	sla	wa, 2
	lda	xbc, (15380484:24)
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
	lda	xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, 14732502
	lda	xix, (xsp+264)
	ld	bc, 4:i3
	.byte 0x95	; llvm-mc cannot spell this byte
	scf
	ld	wa, (xiz+2)
	extz	xwa
	ld	e, (xiz+4)
	ld	c, (xiz+5)
	ld	a, (xwa)
	and	a, e
	ld	e, a
	ld	a, c
	and	a, 15
	jr	z, 2	; -> 0xF02270
	.byte 0xcd	; llvm-mc cannot spell this byte
	swi	7
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
	jr	z, 118	; -> 0xF02317
	cp	a, 128
	jr	nc, 10	; -> 0xF022B0
	cp	e, 128
	jr	c, 5	; -> 0xF022B0
	ld	a, 128:opc
	sub	e, 128
	cp	e, a
	jr	ule, 8	; -> 0xF022BC
	ld	(xsp+4), 43
	sub	e, a
	jr	8	; -> 0xF022C4
	ld	(xsp+4), 45
	sub	a, e
	ld	e, a
	ld	wa, hl
	cp	wa, 2:i3
	jr	z, 29	; -> 0xF022E7
	cp	wa, 1:i3
	jr	nz, 49	; -> 0xF022FF
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52446
	lda	xwa, (xsp+11)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	jrl	130	; -> 0xF02369
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52450
	lda	xwa, (xsp+11)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	jr	106	; -> 0xF02369
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52454
	lda	xwa, (xsp+11)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	jr	82	; -> 0xF02369
	ld	e, 0:opc
	ld	wa, hl
	cp	wa, 2:i3
	jr	z, 28	; -> 0xF0233B
	cp	wa, 1:i3
	jr	nz, 48	; -> 0xF02353
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52458
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	jr	46	; -> 0xF02369
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52462
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	jr	22	; -> 0xF02369
	ld	a, e
	extz	wa
	pushw	wa
	pushw	224
	pushw	52466
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	ld	a, (xiz+6)
	and	a, 63
	extz	wa
	sla	wa, 2
	lda	xbc, (15380484:24)
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
	.byte 0xd3, 0xfd, 0x08, 0x01, 0x6a, 0xdb, 0x88, 0xd8
	.byte 0xda, 0x66, 0x19, 0xd8, 0xd9, 0x6e, 0x2a, 0x92
	.byte 0x04, 0x0b, 0xe0, 0x00, 0x0b, 0xfe, 0xcc, 0xbf
	.byte 0x0c, 0x30, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf
	.byte 0x0a, 0x37, 0x68, 0x28
Scoop_EventLoop_36Entry_Branch1:
	.byte 0x92, 0x04, 0x0b, 0xe0, 0x00, 0x0b, 0x02, 0xcd
	.byte 0xbf, 0x0c, 0x30, 0x38, 0x1d, 0x95, 0x02, 0xff
	.byte 0xbf, 0x0a, 0x37, 0x68, 0x13
Scoop_EventLoop_36Entry_Branch2:
	pushm (xde)

	pushw 0xe0

	pushw 0xcd06

	lda xwa, (xsp + 12)

	push xwa

	call 16712341

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
	.incbin "includes/romslices/v7_transplant_Scoop_EventLoop_36Entry_Data.bin"
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
	ldw_da xwa, (\ParamC)
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
