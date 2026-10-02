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
	lda xde, (ENCODER_HANDLER_TABLE:24)
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
	ldw	hl, 65535
	cpl	a
	ld	c, a
	ld	(36398:16), c
	srl	a, 1
	extz	wa
	lda	xbc, (ENCODER_LUT_MODWHEEL:24)
	ld	a, (xbc+wa)
	ld	c, (36424:16)
	res	7, c
	cp	c, a
	ret	z
	ld	(36424:16), a
	ld	l, a
	extz	hl
	ret
Encoder_ProcessModwheel_End:

; Encoder_ProcessVolume - Process volume/expression slider (Encoder ID 5)
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessVolume:
	pushw	iz
	ldw	iz, 65535
	ld	(36400:16), a
	extz	wa
	lda	xbc, (ENCODER_LUT_VOLUME:24)
	ld	a, (xbc+wa)
	calr	Encoder_ClampScaleAndNormalize
	ld	a, l
	cp	a, (36440:16)
	jr	z, Encoder_ProcessVolume_NoChange	; -> 0xFC650B
	ld	(36440:16), a
	ldfr_berp	a, 248
	extz	iz
Encoder_ProcessVolume_NoChange:
	ld hl, iz	; Return value in HL
	popw iz
	ret

; Encoder_ClampScaleAndNormalize - Clamp value L to minimum in ENCODER_RANGE_LIMIT
; Input: L = value to clamp, A = raw lookup value
; Output: HL = clamped and scaled value
Encoder_ClampScaleAndNormalize:
	ld	l, a
	ld	c, (36418:16)
	cp	l, c
	jr	nc, Encoder_PerformScaling
	ld	l, c
Encoder_PerformScaling:
	sub	l, c
	ld	h, 0:opc
	extz	xhl
	sll	xhl, 8
	ld	xwa, xhl
	ld	xbc, 236
	call	16712763
	ld	a, (36416:16)
	extz	wa
	add	wa, wa
	lda	xbc, (ENCODER_LUT_BREATH_INDEX:24)
	ld	bc, (xbc+wa)
	extz	xbc
	ld	xwa, xhl
	call	16712319
	ld	xwa, xhl
	ld	xbc, 20
	call	16712763
	cp	xhl, 127
	ret	ule
	ld	xhl, 127
	ret
Encoder_ClampScaleAndNormalize_End:

; Encoder_ProcessBreath - Process breath controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessBreath:
	ldw	hl, 0xffff
	cpl	a
	ld	(0x8e38:16), a
	extz	wa
	lda	xbc, (ENCODER_LUT_BREATH_VALUE:24)
	ld	a, (xbc+wa)
	ld	c, (0x36ff:16)
	and	c, 15
	jr	nz, Encoder_ProcessBreath_WithModeAdjustment
	cp	(0x7e6f:16), 0
	jr	z, Encoder_ProcessBreath_SimplePassthrough
Encoder_ProcessBreath_WithModeAdjustment:
	ld	c, (0x8e3e:16)
	cp	c, 0:i3
	ret	z
	srl	a, 1
	ld	l, a
	extz	hl
	dec	1, c
	extz	bc
	add	bc, bc
	lda	xwa, (ENCODER_LUT_BREATH_MULT:24)
	ld	de, (xwa+bc)
	mul	xhl, de
	lda	xwa, (ENCODER_LUT_BREATH_OFFSET:24)
	ld	wa, (xwa+bc)
	sub	hl, wa
	add	hl, 0x4080
	srl	hl, 8
	add	hl, hl
	ld	a, l
	ld	(0x8e4c:16), a
	; -> 0xFC65D3
	jr	Encoder_ProcessBreath_Return
Encoder_ProcessBreath_SimplePassthrough:
	cp	(0x8e4c:16), a
	ret	z
	ld	(0x8e4c:16), a
	ld	l, a
	extz	hl
Encoder_ProcessBreath_Return:
	ret
Encoder_ProcessBreath_End:

; Encoder_ProcessFoot - Process foot controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xffff if unchanged
Encoder_ProcessFoot:
	ldw	hl, 65535
	ld	(36410:16), a
	srl	a, 1
	extz	wa
	lda	xbc, (ENCODER_LUT_FOOT:24)
	ld	a, (xbc+wa)
	ld	c, (36430:16)
	res	7, c
	cp	c, a
	ret	z
	ld	(36430:16), a
	ld	l, a
	extz	hl
	ret
Encoder_ProcessFoot_End:

; Encoder_ProcessExpression - Process expression controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value (always returns value, no skip)
Encoder_ProcessExpression:
	cpl	a
	ld	c, a
	ld	(36412:16), c
	srl	a, 1
	extz	wa
	lda	xbc, (ENCODER_LUT_EXPRESSION:24)
	ld	a, (xbc+wa)
	ld	(36426:16), a
	extz	wa
	ld	hl, wa
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
	ld hl, 1:i3
	ret
Encoder_ReturnDefaultConstant_End:

; Encoder_ApplySystemModeSettings - Select processing mode based on system state
; Reads mode value from 0xc07d and configures encoder processing accordingly
Encoder_ApplySystemModeSettings:
	ld	a, (49121:16)
	cp	a, 6:i3
	jr	z, Encoder_ConfigureRangeLimit
	cp	a, 5:i3
	jr	z, Encoder_ConfigureVolumeMode
	cp	a, 4:i3
	ret	nz
	ld	a, (49123:16)
	and	a, 15
	ret	z
	ld	a, (49122:16)
	and	a, 15
	ld	(36414:16), a
	ret
Encoder_ConfigureVolumeMode:
	ld	a, (49123:16)
	and	a, 255
	ret	z
	ld	a, (49122:16)
	and	a, 255
	ld	(36416:16), a
	ret
Encoder_ConfigureRangeLimit:
	; Disassembled from the committed romslice (no source of any kind existed):
	; llvm-mc round-trips these 23 B byte-exact, and matches v9/v10's
	; Encoder_ConfigureRangeLimit instruction-for-instruction (ldb_d8 a,(..) /
	; res 7,a / cps a,0 / ret z / ...); only the two register addresses differ
	; from v9/v10's 0xc07f/0xc07e, a real cross-revision shift.
	ld	a, (49123:16)
	res	7, a
	cp	a, 0:i3
	ret	z
	ld	a, (49122:16)
	res	7, a
	ld	(36418:16), a
	ret
