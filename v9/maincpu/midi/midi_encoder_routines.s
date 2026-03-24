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
	lda_24 xde, ENCODER_HANDLER_TABLE
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
	ldw hl, 0xffff	; Default return = no change
	cpl a	; Invert input value
	ld c, a
	stda8 0x8eca, c	; Store raw value
	srl a, 1	; Divide by 2
	extz wa
	lda_24 xbc, ENCODER_LUT_MODWHEEL                  ; Lookup table address
	ld_srib3 A, 0x07, 0xe4, 0xe0	; Get processed value from table
	ldda8 c, 0x8ee4	; Get current value
	res 7, c	; Clear change flag
	cp c, a	; Compare with new value
	ret z	; Return if unchanged
	stda8 0x8ee4, a	; Store new value
	ld l, a
	extz hl	; Return value in HL
	ret
Encoder_ProcessModwheel_End:

; Encoder_ProcessVolume - Process volume/expression slider (Encoder ID 5)
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessVolume:
	pushw iz
	ldw iz, 0xffff	; Default return = no change
	stda8 0x8ecc, a	; Store raw value
	extz wa
	lda_24 xbc, ENCODER_LUT_VOLUME                  ; Lookup table address
	ld_srib3 A, 0x07, 0xe4, 0xe0	; Get processed value
	calr Encoder_ClampScaleAndNormalize	; Clamp to valid range
	ld a, l
	cpda8 a, 0x8ef4	; Compare with current
	jr z, Encoder_ProcessVolume_NoChange
	stda8 0x8ef4, a	; Store new value
	ldfr_berp A, 0xf8
	extz iz	; IZ = new value

Encoder_ProcessVolume_NoChange:
	ld hl, iz	; Return value in HL
	popw iz
	ret

; Encoder_ClampScaleAndNormalize - Clamp value L to minimum in ENCODER_RANGE_LIMIT
; Input: L = value to clamp, A = raw lookup value
; Output: HL = clamped and scaled value
Encoder_ClampScaleAndNormalize:
	ld l, a
	ldda8 c, 0x8ede	; Get minimum limit
	cp l, c	; Compare with limit
	jr nc, Encoder_PerformScaling	; Skip if >= limit
	ld l, c	; Clamp to minimum

Encoder_PerformScaling:
	sub l, c	; Subtract minimum
	ldb h, 0x0
	extz xhl
	sll xhl, 8	; Scale up (multiply by 256)
	ld xwa, xhl
	ld xbc, 0xec	; Divisor
	call Math_DivideU32	; Division routine
	ldda8 a, 0x8edc	; Get mode value
	extz wa
	add wa, wa	; Double for word table index
	lda_24 xbc, ENCODER_LUT_BREATH_INDEX                  ; Index table
	ld_sriw3 BC, 0x07, 0xe4, 0xe0	; Get index offset
	extz xbc
	ld xwa, xhl
	call Math_MultiplyAccumulate	; Processing routine
	ld xwa, xhl
	ld xbc, 0x14	; Constant
	call Math_DivideU32	; Division
	cp xhl, 0x7f	; Clamp to 127 max
	ret ule	; Return if <= 127
	ld xhl, 0x7f	; Clamp to 127
	ret
Encoder_ClampScaleAndNormalize_End:

; Encoder_ProcessBreath - Process breath controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessBreath:
	ldw hl, 0xffff	; Default return = no change
	cpl a	; Invert input
	stda8 0x8ed4, a	; Store raw value
	extz wa
	lda_24 xbc, ENCODER_LUT_BREATH_VALUE                  ; Lookup table
	ld_srib3 A, 0x07, 0xe4, 0xe0	; Get processed value
	ldda8 c, 0x379b	; Get system mode flags
	and c, 0xf	; Mask relevant bits
	jr nz, Encoder_ProcessBreath_WithModeAdjustment	; If mode active, process
	cpdi8 0x7f0b, 0	; Check alternate condition
	jr z, Encoder_ProcessBreath_SimplePassthrough	; Simple processing if clear

Encoder_ProcessBreath_WithModeAdjustment:
	ldda8 c, 0x8eda	; Get breath mode
	cps c, 0
	ret z	; Return if disabled
	srl a, 1	; Divide by 2
	ld l, a
	extz hl
	dec 1, c	; Decrement mode for index
	extz bc
	add bc, bc	; Word index
	lda_24 xwa, ENCODER_LUT_BREATH_MULT                  ; Multiplier table
	ld_sriw3 DE, 0x07, 0xe0, 0xe4	; Get multiplier
	mul xhl, xde	; Multiply
	lda_24 xwa, ENCODER_LUT_BREATH_OFFSET                  ; Offset table
	ld_sriw3 WA, 0x07, 0xe0, 0xe4	; Get offset
	sub hl, wa	; Subtract offset
	add hl, 0x4080	; Add center offset
	srl hl, 8	; Divide by 256
	add hl, hl	; Double
	ld a, l
	stda8 0x8ee8, a	; Store result
	jr Encoder_ProcessBreath_Return

Encoder_ProcessBreath_SimplePassthrough:
	cpdm8 0x8ee8, a	; Compare with current
	ret z	; Return if unchanged
	stda8 0x8ee8, a	; Store new value
	ld l, a
	extz hl

Encoder_ProcessBreath_Return:
	ret
Encoder_ProcessBreath_End:

; Encoder_ProcessFoot - Process foot controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessFoot:
	ldw hl, 0xffff	; Default return = no change
	stda8 0x8ed6, a	; Store raw value
	srl a, 1	; Divide by 2
	extz wa
	lda_24 xbc, ENCODER_LUT_FOOT                  ; Lookup table
	ld_srib3 A, 0x07, 0xe4, 0xe0	; Get processed value
	ldda8 c, 0x8eea	; Get current value
	res 7, c	; Clear change flag
	cp c, a	; Compare
	ret z	; Return if unchanged
	stda8 0x8eea, a	; Store new value
	ld l, a
	extz hl	; Return value in HL
	ret
Encoder_ProcessFoot_End:

; Encoder_ProcessExpression - Process expression controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value (always returns value, no skip)
Encoder_ProcessExpression:
	cpl a	; Invert input
	ld c, a
	stda8 0x8ed8, c	; Store raw value
	srl a, 1	; Divide by 2
	extz wa
	lda_24 xbc, ENCODER_LUT_EXPRESSION                  ; Lookup table
	ld_srib3 A, 0x07, 0xe4, 0xe0	; Get processed value
	stda8 0x8ee6, a	; Store value
	extz wa
	ld hl, wa	; Return value in HL
	ret
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
	ldda8 a, 0xc07d	; Get mode selector
	cps a, 6
	jr z, Encoder_ConfigureRangeLimit	; Jump if mode 6
	cps a, 5
	jr z, Encoder_ConfigureVolumeMode	; Jump if mode 5
	cps a, 4
	ret nz	; Return if not mode 4
	; Mode 4: Configure breath mode
	ldda8 a, 0xc07f
	and a, 0xf	; Mask low nibble
	ret z	; Return if zero
	ldda8 a, 0xc07e
	and a, 0xf	; Mask low nibble
	stda8 0x8eda, a	; Set breath mode
	ret

Encoder_ConfigureVolumeMode:
	ldda8 a, 0xc07f
	and a, 0xff	; Full byte check
	ret z	; Return if zero
	ldda8 a, 0xc07e
	and a, 0xff	; Full byte
	stda8 0x8edc, a	; Set volume mode
	ret

Encoder_ConfigureRangeLimit:
	ldda8 a, 0xc07f
	res 7, a	; Clear bit 7
	cps a, 0
	ret z	; Return if zero
	ldda8 a, 0xc07e
	res 7, a	; Clear bit 7
	stda8 0x8ede, a	; Set range limit
	ret

; End of MIDI encoder routines
