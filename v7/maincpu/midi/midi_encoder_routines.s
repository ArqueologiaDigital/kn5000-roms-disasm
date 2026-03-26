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
	.incbin "includes/generated/v7_transplant_Encoder_ProcessModwheel.bin"
Encoder_ProcessModwheel_End:

; Encoder_ProcessVolume - Process volume/expression slider (Encoder ID 5)
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessVolume:
	.incbin "includes/generated/v7_transplant_Encoder_ProcessVolume.bin"
Encoder_ProcessVolume_NoChange:
	ld hl, iz	; Return value in HL
	popw iz
	ret

; Encoder_ClampScaleAndNormalize - Clamp value L to minimum in ENCODER_RANGE_LIMIT
; Input: L = value to clamp, A = raw lookup value
; Output: HL = clamped and scaled value
Encoder_ClampScaleAndNormalize:
	.incbin "includes/generated/v7_transplant_Encoder_ClampScaleAndNormalize.bin"
Encoder_PerformScaling:
	.incbin "includes/generated/v7_transplant_Encoder_PerformScaling.bin"
Encoder_ClampScaleAndNormalize_End:

; Encoder_ProcessBreath - Process breath controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessBreath:
	.incbin "includes/generated/v7_transplant_Encoder_ProcessBreath.bin"
Encoder_ProcessBreath_WithModeAdjustment:
	.incbin "includes/generated/v7_transplant_Encoder_ProcessBreath_WithModeAdjustment.bin"
Encoder_ProcessBreath_SimplePassthrough:
	.incbin "includes/generated/v7_transplant_Encoder_ProcessBreath_SimplePassthrough.bin"
Encoder_ProcessBreath_Return:
	ret
Encoder_ProcessBreath_End:

; Encoder_ProcessFoot - Process foot controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessFoot:
	.incbin "includes/generated/v7_transplant_Encoder_ProcessFoot.bin"
Encoder_ProcessFoot_End:

; Encoder_ProcessExpression - Process expression controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value (always returns value, no skip)
Encoder_ProcessExpression:
	.incbin "includes/generated/v7_transplant_Encoder_ProcessExpression.bin"
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
	.incbin "includes/generated/v7_transplant_Encoder_ApplySystemModeSettings.bin"
Encoder_ConfigureVolumeMode:
	.incbin "includes/generated/v7_transplant_Encoder_ConfigureVolumeMode.bin"
Encoder_ConfigureRangeLimit:
	ldb_d8 a, (0xc07f)
	res 7, a	; Clear bit 7
	cps a, 0
	ret z	; Return if zero
	ldb_d8 a, (0xc07e)
	res 7, a	; Clear bit 7
	stb_d8 (0x8ede), a; Set range limit
	ret

; End of MIDI encoder routines
