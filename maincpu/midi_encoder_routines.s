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
	and c, 0xC0	; Extract bits 6-7
	srl c, 3	; Shift to bits 3-4
	or c, e	; Combine to form 5-bit index
	extz bc
	sla bc, 2	; Multiply by 4 (jump table entry size)
	lda_24 xde, 0xeda0bc
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
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessModwheel:
	ldw hl, 0xFFFF	; Default return = no change
	cpl a	; Invert input value
	ld c, a
	stda8 36554, c	; Store raw value
	srl a, 1	; Divide by 2
	extz wa
	lda_24 xbc, 0xeda13c                  ; Lookup table address
	ld_srib3 A, 0x07, 0xE4, 0xE0	; Get processed value from table
	ldda8 c, 36580	; Get current value
	res 7, c	; Clear change flag
	cp c, a	; Compare with new value
	ret z	; Return if unchanged
	stda8 36580, a	; Store new value
	ld l, a
	extz hl	; Return value in HL
	ret
LABEL_FC6CAE:

; Encoder_ProcessVolume - Process volume/expression slider (Encoder ID 5)
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessVolume:
	pushw iz
	ldw iz, 0xFFFF	; Default return = no change
	stda8 36556, a	; Store raw value
	extz wa
	lda_24 xbc, 0xeda1bc                  ; Lookup table address
	ld_srib3 A, 0x07, 0xE4, 0xE0	; Get processed value
	calr Encoder_ClampScaleAndNormalize	; Clamp to valid range
	ld a, l
	cpda8 a, 36596	; Compare with current
	jr z, Encoder_ProcessVolume_NoChange
	stda8 36596, a	; Store new value
	ldfr_berp A, 0xF8
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
	ldda8 c, 36574	; Get minimum limit
	cp l, c	; Compare with limit
	jr nc, Encoder_PerformScaling	; Skip if >= limit
	ld l, c	; Clamp to minimum

Encoder_PerformScaling:
	sub l, c	; Subtract minimum
	ldb h, 0x0
	extz xhl
	sll xhl, 8	; Scale up (multiply by 256)
	ld xwa, xhl
	ld xbc, 0xEC	; Divisor
	call LABEL_FF0C18	; Division routine
	ldda8 a, 36572	; Get mode value
	extz wa
	add wa, wa	; Double for word table index
	lda_24 xbc, 0xeda2bc                  ; Index table
	ld_sriw3 BC, 0x07, 0xE4, 0xE0	; Get index offset
	extz xbc
	ld xwa, xhl
	call LABEL_FF0A5C	; Processing routine
	ld xwa, xhl
	ld xbc, 0x14	; Constant
	call LABEL_FF0C18	; Division
	cp xhl, 0x7F	; Clamp to 127 max
	ret ule	; Return if <= 127
	ld xhl, 0x7F	; Clamp to 127
	ret
LABEL_FC6D2D:

; Encoder_ProcessBreath - Process breath controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessBreath:
	ldw hl, 0xFFFF	; Default return = no change
	cpl a	; Invert input
	stda8 36564, a	; Store raw value
	extz wa
	lda_24 xbc, 0xeda2d2                  ; Lookup table
	ld_srib3 A, 0x07, 0xE4, 0xE0	; Get processed value
	ldda8 c, 14235	; Get system mode flags
	and c, 0xF	; Mask relevant bits
	jr nz, Encoder_ProcessBreath_WithModeAdjustment	; If mode active, process
	cpdi8 32523, 0	; Check alternate condition
	jr z, Encoder_ProcessBreath_SimplePassthrough	; Simple processing if clear

Encoder_ProcessBreath_WithModeAdjustment:
	ldda8 c, 36570	; Get breath mode
	cps c, 0
	ret z	; Return if disabled
	srl a, 1	; Divide by 2
	ld l, a
	extz hl
	dec 1, c	; Decrement mode for index
	extz bc
	add bc, bc	; Word index
	lda_24 xwa, 0xeda3d2                  ; Multiplier table
	ld_sriw3 DE, 0x07, 0xE0, 0xE4	; Get multiplier
	mul xhl, xde	; Multiply
	lda_24 xwa, 0xeda3ea                  ; Offset table
	ld_sriw3 WA, 0x07, 0xE0, 0xE4	; Get offset
	sub hl, wa	; Subtract offset
	add hl, 0x4080	; Add center offset
	srl hl, 8	; Divide by 256
	add hl, hl	; Double
	ld a, l
	stda8 36584, a	; Store result
	jr Encoder_ProcessBreath_Return

Encoder_ProcessBreath_SimplePassthrough:
	cpdm8 36584, a	; Compare with current
	ret z	; Return if unchanged
	stda8 36584, a	; Store new value
	ld l, a
	extz hl

Encoder_ProcessBreath_Return:
	ret
LABEL_FC6D9F:

; Encoder_ProcessFoot - Process foot controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessFoot:
	ldw hl, 0xFFFF	; Default return = no change
	stda8 36566, a	; Store raw value
	srl a, 1	; Divide by 2
	extz wa
	lda_24 xbc, 0xeda402                  ; Lookup table
	ld_srib3 A, 0x07, 0xE4, 0xE0	; Get processed value
	ldda8 c, 36586	; Get current value
	res 7, c	; Clear change flag
	cp c, a	; Compare
	ret z	; Return if unchanged
	stda8 36586, a	; Store new value
	ld l, a
	extz hl	; Return value in HL
	ret
LABEL_FC6DC9:

; Encoder_ProcessExpression - Process expression controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value (always returns value, no skip)
Encoder_ProcessExpression:
	cpl a	; Invert input
	ld c, a
	stda8 36568, c	; Store raw value
	srl a, 1	; Divide by 2
	extz wa
	lda_24 xbc, 0xeda482                  ; Lookup table
	ld_srib3 A, 0x07, 0xE4, 0xE0	; Get processed value
	stda8 36582, a	; Store value
	extz wa
	ld hl, wa	; Return value in HL
	ret
LABEL_FC6DE9:

; Encoder_PassthroughIdentity - Simple passthrough: returns input value in HL
; Input: A = value
; Output: HL = value
Encoder_PassthroughIdentity:
	ld l, a
	extz hl
	ret
LABEL_FC6DEE:

; Encoder_ReturnDefaultConstant - Returns constant 1
; Output: HL = 1
Encoder_ReturnDefaultConstant:
	lds hl, 1
	ret
LABEL_FC6DF1:

; Encoder_ApplySystemModeSettings - Select processing mode based on system state
; Reads mode value from 0xC07D and configures encoder processing accordingly
Encoder_ApplySystemModeSettings:
	ldda8 a, 49277	; Get mode selector
	cps a, 6
	jr z, Encoder_ConfigureRangeLimit	; Jump if mode 6
	cps a, 5
	jr z, Encoder_ConfigureVolumeMode	; Jump if mode 5
	cps a, 4
	ret nz	; Return if not mode 4
	; Mode 4: Configure breath mode
	ldda8 a, 49279
	and a, 0xF	; Mask low nibble
	ret z	; Return if zero
	ldda8 a, 49278
	and a, 0xF	; Mask low nibble
	stda8 36570, a	; Set breath mode
	ret

Encoder_ConfigureVolumeMode:
	ldda8 a, 49279
	and a, 0xFF	; Full byte check
	ret z	; Return if zero
	ldda8 a, 49278
	and a, 0xFF	; Full byte
	stda8 36572, a	; Set volume mode
	ret

Encoder_ConfigureRangeLimit:
	ldda8 a, 49279
	res 7, a	; Clear bit 7
	cps a, 0
	ret z	; Return if zero
	ldda8 a, 49278
	res 7, a	; Clear bit 7
	stda8 36574, a	; Set range limit
	ret

; End of MIDI encoder routines
