; =============================================================================
; midi_encoder_routines.asm - MIDI Encoder Processing Routines
; =============================================================================
; This file contains the encoder dispatch and MIDI CC value processing
; routines for the KN5000 Main CPU.
;
; The encoder system works as follows:
; 1. Raw ADC values come from analog controllers (modwheel, volume, etc.)
; 2. CPanel_EncoderDispatch routes to encoder-specific handlers
; 3. Each handler uses lookup tables to convert raw -> MIDI CC values
; 4. Processed values are stored in MIDI_CC_*_VALUE variables
;
; Routines:
;   CPanel_EncoderDispatch    - Dispatch to encoder-specific handler
;   Encoder_ProcessModwheel   - Process modulation wheel (ID 2)
;   Encoder_ProcessVolume     - Process volume slider (ID 5)
;   Encoder_ClampScaleAndNormalize      - Clamp value to configured range
;   Encoder_ProcessBreath     - Process breath controller (ID 25)
;   Encoder_ProcessFoot       - Process foot controller (ID 26)
;   Encoder_ProcessExpression - Process expression (ID 27)
;   Encoder_PassthroughIdentity       - Simple passthrough (ID 31)
;   Encoder_ReturnDefaultConstant         - Return constant 1 (default/unused)
;   Encoder_ApplySystemModeSettings        - Select processing mode based on system state
;
; Required includes before this file:
;   - midi_encoder_constants.asm (or equivalent EQU definitions)
;
; =============================================================================

; CPanel_EncoderDispatch - Dispatch to encoder-specific handler
; Input: A = encoder data value, BC = encoder type/index
; Extracts encoder ID from bits 0-2 and 6-7, looks up handler in jump table
CPanel_EncoderDispatch:
	extz wa
	ld e, c
	and e, 0x7	; Extract bits 0-2 of encoder ID
	and c, 0xc0	; Extract bits 6-7
	srl c, 3	; Shift to bits 3-4
	or c, e	; Combine to form 5-bit index
	extz bc
	sla bc, 2	; Multiply by 4 (jump table entry size)
	lda_24 xde, (ENCODER_HANDLER_TABLE)
	exts xbc
	add xbc, xde	; XBC = table entry address
	ld xix, (xbc)	; Load handler address
	jp (xix)	; Jump to handler

; ============================================================================
; Encoder Value Processing Handlers
; These routines process raw encoder inputs and convert them to MIDI CC values
; using lookup tables. Called via ENCODER_HANDLER_TABLE dispatch.
; ============================================================================

; Encoder_ProcessModwheel - Process modulation wheel input (Encoder ID 2)
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessModwheel:
	.byte 0x33, 0xff, 0xff, 0xc9, 0x06, 0xc9, 0x8b, 0xf1
	.byte 0x2e, 0x8e, 0x43, 0xc9, 0xef, 0x01, 0xd8, 0x12
	.byte 0xf2, 0x3c, 0xa1, 0xed, 0x31, 0xc3, 0x07, 0xe4
	.byte 0xe0, 0x21, 0xc1, 0x48, 0x8e, 0x23, 0xcb, 0x30
	.byte 0x07, 0xc9, 0xf3, 0xb0, 0xf6, 0xf1, 0x48, 0x8e
	.byte 0x41, 0xc9, 0x8f, 0xdb, 0x12, 0x0e
Encoder_ProcessModwheel_End:

; Encoder_ProcessVolume - Process volume/expression slider (Encoder ID 5)
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessVolume:
	.byte 0x2e, 0x36, 0xff, 0xff, 0xf1, 0x30, 0x8e, 0x41
	.byte 0xd8, 0x12, 0xf2, 0xbc, 0xa1, 0xed, 0x31, 0xc3
	.byte 0x07, 0xe4, 0xe0, 0x21, 0x1e, 0x15, 0x00, 0xcf
	.byte 0x89, 0xc1, 0x58, 0x8e, 0xf1, 0x66, 0x09, 0xf1
	.byte 0x58, 0x8e, 0x41, 0xc7, 0xf8, 0x99, 0xde, 0x12
Encoder_ProcessVolume_NoChange:
	ld hl, iz	; Return value in HL
	popw iz
	ret

; Encoder_ClampScaleAndNormalize - Clamp value L to minimum in ENCODER_RANGE_LIMIT
; Input: L = value to clamp, A = raw lookup value
; Output: HL = clamped and scaled value
Encoder_ClampScaleAndNormalize:
	ld	l, a
	ldb_d8	c, (36418)
	cp	l, c
	jr	nc, 2
	ld	l, c
Encoder_PerformScaling:
	.byte 0xcb, 0xa7, 0x26, 0x00, 0xeb, 0x12, 0xeb, 0xee
	.byte 0x08, 0xeb, 0x88, 0x41, 0xec, 0x00, 0x00, 0x00
	.byte 0x1d, 0x3b, 0x04, 0xff, 0xc1, 0x40, 0x8e, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x80, 0xf2, 0xbc, 0xa2, 0xed
	.byte 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x21, 0xe9, 0x12
	.byte 0xeb, 0x88, 0x1d, 0x7f, 0x02, 0xff, 0xeb, 0x88
	.byte 0x41, 0x14, 0x00, 0x00, 0x00, 0x1d, 0x3b, 0x04
	.byte 0xff, 0xeb, 0xcf, 0x7f, 0x00, 0x00, 0x00, 0xb0
	.byte 0xf3, 0x43, 0x7f, 0x00, 0x00, 0x00, 0x0e
Encoder_ClampScaleAndNormalize_End:

; Encoder_ProcessBreath - Process breath controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessBreath:
	.byte 0x33, 0xff, 0xff, 0xc9, 0x06, 0xf1, 0x38, 0x8e
	.byte 0x41, 0xd8, 0x12, 0xf2, 0xd2, 0xa2, 0xed, 0x31
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x21, 0xc1, 0xff, 0x36
	.byte 0x23, 0xcb, 0xcc, 0x0f, 0x6e, 0x07, 0xc1, 0x6f
	.byte 0x7e, 0x3f, 0x00, 0x66, 0x3e
Encoder_ProcessBreath_WithModeAdjustment:
	.byte 0xc1, 0x3e, 0x8e, 0x23, 0xcb, 0xd8, 0xb0, 0xf6
	.byte 0xc9, 0xef, 0x01, 0xc9, 0x8f, 0xdb, 0x12, 0xcb
	.byte 0x69, 0xd9, 0x12, 0xd9, 0x81, 0xf2, 0xd2, 0xa3
	.byte 0xed, 0x30, 0xd3, 0x07, 0xe0, 0xe4, 0x22, 0xda
	.byte 0x43, 0xf2, 0xea, 0xa3, 0xed, 0x30, 0xd3, 0x07
	.byte 0xe0, 0xe4, 0x20, 0xd8, 0xa3, 0xdb, 0xc8, 0x80
	.byte 0x40, 0xdb, 0xef, 0x08, 0xdb, 0x83, 0xcf, 0x89
	.byte 0xf1, 0x4c, 0x8e, 0x41, 0x68, 0x0e
Encoder_ProcessBreath_SimplePassthrough:
	cpdm8	(36428), a
	ret	z
	stb_d8	(36428), a
	ld	l, a
	extz	hl
Encoder_ProcessBreath_Return:
	ret
Encoder_ProcessBreath_End:

; Encoder_ProcessFoot - Process foot controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessFoot:
	.byte 0x33, 0xff, 0xff, 0xf1, 0x3a, 0x8e, 0x41, 0xc9
	.byte 0xef, 0x01, 0xd8, 0x12, 0xf2, 0x02, 0xa4, 0xed
	.byte 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x21, 0xc1, 0x4e
	.byte 0x8e, 0x23, 0xcb, 0x30, 0x07, 0xc9, 0xf3, 0xb0
	.byte 0xf6, 0xf1, 0x4e, 0x8e, 0x41, 0xc9, 0x8f, 0xdb
	.byte 0x12, 0x0e
Encoder_ProcessFoot_End:

; Encoder_ProcessExpression - Process expression controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value (always returns value, no skip)
Encoder_ProcessExpression:
	.byte 0xc9, 0x06, 0xc9, 0x8b, 0xf1, 0x3c, 0x8e, 0x43
	.byte 0xc9, 0xef, 0x01, 0xd8, 0x12, 0xf2, 0x82, 0xa4
	.byte 0xed, 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x21, 0xf1
	.byte 0x4a, 0x8e, 0x41, 0xd8, 0x12, 0xd8, 0x8b, 0x0e
Encoder_ProcessExpression_End:

; Encoder_PassthroughIdentity - Simple passthrough: returns input value in HL
; Input: A = value
; Output: HL = value
Encoder_PassthroughIdentity:
	ld l, a
	extz hl
	ret
Encoder_PassthroughIdentity_End:

; Encoder_ReturnDefaultConstant - Returns constant 1
; Output: HL = 1
Encoder_ReturnDefaultConstant:
	lds hl, 1
	ret
Encoder_ReturnDefaultConstant_End:

; Encoder_ApplySystemModeSettings - Select processing mode based on system state
; Reads mode value from 0xc07d and configures encoder processing accordingly
Encoder_ApplySystemModeSettings:
	ldb_d8	a, (49121)
	cps	a, 6
	jr	z, 50
	cps	a, 5
	jr	z, 25
	cps	a, 4
	ret	nz
	ldb_d8	a, (49123)
	and	a, 15
	ret	z
	ldb_d8	a, (49122)
	and	a, 15
	stb_d8	(36414), a
	ret
Encoder_ConfigureVolumeMode:
	ldb_d8	a, (49123)
	and	a, 255
	ret	z
	ldb_d8	a, (49122)
	and	a, 255
	stb_d8	(36416), a
	ret
Encoder_ConfigureRangeLimit:
	.incbin "includes/generated/v7_fix_encoder_configurerangelimit.bin"
