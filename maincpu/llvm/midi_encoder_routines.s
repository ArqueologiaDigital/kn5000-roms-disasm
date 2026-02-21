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
	extz WA
	ld E, C
	and E, 0x7	; Extract bits 0-2 of encoder ID
	and C, 0xc0	; Extract bits 6-7
	srl C, 3	; Shift to bits 3-4
	or C, E	; Combine to form 5-bit index
	extz BC
	sla BC, 0x2	; Multiply by 4 (jump table entry size)
	lda XDE, ENCODER_HANDLER_TABLE
	exts XBC
	add XBC, XDE	; XBC = table entry address
	ld XIX, (XBC)	; Load handler address
	jp XIX	; Jump to handler

; ============================================================================
; Encoder Value Processing Handlers
; These routines process raw encoder inputs and convert them to MIDI CC values
; using lookup tables. Called via ENCODER_HANDLER_TABLE dispatch.
; ============================================================================

; Encoder_ProcessModwheel - Process modulation wheel input (Encoder ID 2)
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessModwheel:
	ld HL, 0xFFFF	; Default return = no change
	cpl A	; Invert input value
	ld C, A
	ld (ENCODER_RAW_MODWHEEL), C	; Store raw value
	srl A, 0x1	; Divide by 2
	extz WA
	lda XBC, ENCODER_LUT_MODWHEEL	; Lookup table address
	ld A, (XBC + WA)	; Get processed value from table
	ld C, (MIDI_CC_MODWHEEL_VALUE)	; Get current value
	res 0x7, C	; Clear change flag
	cp C, A	; Compare with new value
	ret Z	; Return if unchanged
	ld (MIDI_CC_MODWHEEL_VALUE), A	; Store new value
	ld L, A
	extz HL	; Return value in HL
	ret

; Encoder_ProcessVolume - Process volume/expression slider (Encoder ID 5)
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessVolume:
	push IZ
	ld IZ, 0xFFFF	; Default return = no change
	ld (ENCODER_RAW_VOLUME), A	; Store raw value
	extz WA
	lda XBC, ENCODER_LUT_VOLUME	; Lookup table address
	ld A, (XBC + WA)	; Get processed value
	CALR Encoder_ClampScaleAndNormalize	; Clamp to valid range
	ld A, L
	cp A, (MIDI_CC_VOLUME_VALUE)	; Compare with current
	jr Z, Encoder_ProcessVolume_NoChange
	ld (MIDI_CC_VOLUME_VALUE), A	; Store new value
	ld IZL, A
	extz IZ	; IZ = new value

Encoder_ProcessVolume_NoChange:
	ld HL, IZ	; Return value in HL
	pop IZ
	ret

; Encoder_ClampScaleAndNormalize - Clamp value L to minimum in ENCODER_RANGE_LIMIT
; Input: L = value to clamp, A = raw lookup value
; Output: HL = clamped and scaled value
Encoder_ClampScaleAndNormalize:
	ld L, A
	ld C, (ENCODER_RANGE_LIMIT)	; Get minimum limit
	cp L, C	; Compare with limit
	jr NC, Encoder_PerformScaling	; Skip if >= limit
	ld L, C	; Clamp to minimum

Encoder_PerformScaling:
	sub L, C	; Subtract minimum
	LD_H 0x0
	extz XHL
	sll XHL, 0x8	; Scale up (multiply by 256)
	ld XWA, XHL
	ld XBC, 0xEC	; Divisor
	call 0xFF0C18	; Division routine
	ld A, (ENCODER_VOLUME_MODE)	; Get mode value
	extz WA
	add WA, WA	; Double for word table index
	lda XBC, ENCODER_LUT_BREATH_INDEX	; Index table
	ld BC, (XBC + WA)	; Get index offset
	extz XBC
	ld XWA, XHL
	call 0xFF0A5C	; Processing routine
	ld XWA, XHL
	ld XBC, 0x14	; Constant
	call 0xFF0C18	; Division
	cp XHL, 0x7F	; Clamp to 127 max
	ret ULE	; Return if <= 127
	ld XHL, 0x7F	; Clamp to 127
	ret

; Encoder_ProcessBreath - Process breath controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessBreath:
	ld HL, 0xFFFF	; Default return = no change
	cpl A	; Invert input
	ld (ENCODER_RAW_BREATH), A	; Store raw value
	extz WA
	lda XBC, ENCODER_LUT_BREATH_VALUE	; Lookup table
	ld A, (XBC + WA)	; Get processed value
	ld C, (0x379B)	; Get system mode flags
	and C, 0xF	; Mask relevant bits
	jr NZ, Encoder_ProcessBreath_WithModeAdjustment	; If mode active, process
	cp (0x7F0B), 0x0	; Check alternate condition
	jr Z, Encoder_ProcessBreath_SimplePassthrough	; Simple processing if clear

Encoder_ProcessBreath_WithModeAdjustment:
	ld C, (ENCODER_BREATH_MODE)	; Get breath mode
	cp C, 0
	ret Z	; Return if disabled
	srl A, 0x1	; Divide by 2
	ld L, A
	extz HL
	dec 1, C	; Decrement mode for index
	extz BC
	add BC, BC	; Word index
	lda XWA, ENCODER_LUT_BREATH_MULT	; Multiplier table
	ld DE, (XWA + BC)	; Get multiplier
	mul XHL, DE	; Multiply
	lda XWA, ENCODER_LUT_BREATH_OFFSET	; Offset table
	ld WA, (XWA + BC)	; Get offset
	sub HL, WA	; Subtract offset
	add HL, 0x4080	; Add center offset
	srl HL, 0x8	; Divide by 256
	add HL, HL	; Double
	ld A, L
	ld (MIDI_CC_BREATH_VALUE), A	; Store result
	jr Encoder_ProcessBreath_Return

Encoder_ProcessBreath_SimplePassthrough:
	cp (MIDI_CC_BREATH_VALUE), A	; Compare with current
	ret Z	; Return if unchanged
	ld (MIDI_CC_BREATH_VALUE), A	; Store new value
	ld L, A
	extz HL

Encoder_ProcessBreath_Return:
	ret

; Encoder_ProcessFoot - Process foot controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessFoot:
	ld HL, 0xFFFF	; Default return = no change
	ld (ENCODER_RAW_FOOT), A	; Store raw value
	srl A, 0x1	; Divide by 2
	extz WA
	lda XBC, ENCODER_LUT_FOOT	; Lookup table
	ld A, (XBC + WA)	; Get processed value
	ld C, (MIDI_CC_FOOT_VALUE)	; Get current value
	res 0x7, C	; Clear change flag
	cp C, A	; Compare
	ret Z	; Return if unchanged
	ld (MIDI_CC_FOOT_VALUE), A	; Store new value
	ld L, A
	extz HL	; Return value in HL
	ret

; Encoder_ProcessExpression - Process expression controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value (always returns value, no skip)
Encoder_ProcessExpression:
	cpl A	; Invert input
	ld C, A
	ld (ENCODER_RAW_EXPRESSION), C	; Store raw value
	srl A, 0x1	; Divide by 2
	extz WA
	lda XBC, ENCODER_LUT_EXPRESSION	; Lookup table
	ld A, (XBC + WA)	; Get processed value
	ld (MIDI_CC_EXPRESSION_VALUE), A	; Store value
	extz WA
	ld HL, WA	; Return value in HL
	ret

; Encoder_PassthroughIdentity - Simple passthrough: returns input value in HL
; Input: A = value
; Output: HL = value
Encoder_PassthroughIdentity:
	ld L, A
	extz HL
	ret

; Encoder_ReturnDefaultConstant - Returns constant 1
; Output: HL = 1
Encoder_ReturnDefaultConstant:
	ld HL, 1
	ret

; Encoder_ApplySystemModeSettings - Select processing mode based on system state
; Reads mode value from 0xC07D and configures encoder processing accordingly
Encoder_ApplySystemModeSettings:
	ld A, (0xC07D)	; Get mode selector
	cp A, 6
	jr Z, Encoder_ConfigureRangeLimit	; Jump if mode 6
	cp A, 5
	jr Z, Encoder_ConfigureVolumeMode	; Jump if mode 5
	cp A, 4
	ret NZ	; Return if not mode 4
	; Mode 4: Configure breath mode
	ld A, (0xC07F)
	and A, 0xF	; Mask low nibble
	ret Z	; Return if zero
	ld A, (0xC07E)
	and A, 0xF	; Mask low nibble
	ld (ENCODER_BREATH_MODE), A	; Set breath mode
	ret

Encoder_ConfigureVolumeMode:
	ld A, (0xC07F)
	and A, 0xFF	; Full byte check
	ret Z	; Return if zero
	ld A, (0xC07E)
	and A, 0xFF	; Full byte
	ld (ENCODER_VOLUME_MODE), A	; Set volume mode
	ret

Encoder_ConfigureRangeLimit:
	ld A, (0xC07F)
	res 0x7, A	; Clear bit 7
	cp A, 0
	ret Z	; Return if zero
	ld A, (0xC07E)
	res 0x7, A	; Clear bit 7
	ld (ENCODER_RANGE_LIMIT), A	; Set range limit
	ret

; End of MIDI encoder routines
