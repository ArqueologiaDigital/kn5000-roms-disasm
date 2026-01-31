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
	EXTZ WA
	LD E, C
	AND E, 007h			; Extract bits 0-2 of encoder ID
	AND C, 0c0h			; Extract bits 6-7
	SRL 3, C			; Shift to bits 3-4
	OR C, E				; Combine to form 5-bit index
	EXTZ BC
	SLA 002h, BC			; Multiply by 4 (jump table entry size)
	LDA XDE, ENCODER_HANDLER_TABLE
	EXTS XBC
	ADD XBC, XDE			; XBC = table entry address
	LD XIX, (XBC)			; Load handler address
	JP T, XIX			; Jump to handler

; ============================================================================
; Encoder Value Processing Handlers
; These routines process raw encoder inputs and convert them to MIDI CC values
; using lookup tables. Called via ENCODER_HANDLER_TABLE dispatch.
; ============================================================================

; Encoder_ProcessModwheel - Process modulation wheel input (Encoder ID 2)
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessModwheel:
	LD HL, 0FFFFh			; Default return = no change
	CPL A				; Invert input value
	LD C, A
	LD (ENCODER_RAW_MODWHEEL), C	; Store raw value
	SRL 001h, A			; Divide by 2
	EXTZ WA
	LDA XBC, ENCODER_LUT_MODWHEEL	; Lookup table address
	LD A, (XBC + WA)		; Get processed value from table
	LD C, (MIDI_CC_MODWHEEL_VALUE)	; Get current value
	RES 007h, C			; Clear change flag
	CP C, A				; Compare with new value
	RET Z				; Return if unchanged
	LD (MIDI_CC_MODWHEEL_VALUE), A	; Store new value
	LD L, A
	EXTZ HL				; Return value in HL
	RET

; Encoder_ProcessVolume - Process volume/expression slider (Encoder ID 5)
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessVolume:
	PUSH IZ
	LD IZ, 0FFFFh			; Default return = no change
	LD (ENCODER_RAW_VOLUME), A	; Store raw value
	EXTZ WA
	LDA XBC, ENCODER_LUT_VOLUME	; Lookup table address
	LD A, (XBC + WA)		; Get processed value
	CALR Encoder_ClampScaleAndNormalize	; Clamp to valid range
	LD A, L
	CP A, (MIDI_CC_VOLUME_VALUE)	; Compare with current
	JR Z, Encoder_ProcessVolume_NoChange
	LD (MIDI_CC_VOLUME_VALUE), A	; Store new value
	LD IZL, A
	EXTZ IZ				; IZ = new value

Encoder_ProcessVolume_NoChange:
	LD HL, IZ			; Return value in HL
	POP IZ
	RET

; Encoder_ClampScaleAndNormalize - Clamp value L to minimum in ENCODER_RANGE_LIMIT
; Input: L = value to clamp, A = raw lookup value
; Output: HL = clamped and scaled value
Encoder_ClampScaleAndNormalize:
	LD L, A
	LD C, (ENCODER_RANGE_LIMIT)	; Get minimum limit
	CP L, C				; Compare with limit
	JR NC, Encoder_PerformScaling		; Skip if >= limit
	LD L, C				; Clamp to minimum

Encoder_PerformScaling:
	SUB L, C			; Subtract minimum
	LD_H 000h
	EXTZ XHL
	SLL 008h, XHL			; Scale up (multiply by 256)
	LD XWA, XHL
	LD XBC, 0000ECh			; Divisor
	CALL 0FF0C18h			; Division routine
	LD A, (ENCODER_VOLUME_MODE)	; Get mode value
	EXTZ WA
	ADD WA, WA			; Double for word table index
	LDA XBC, ENCODER_LUT_BREATH_INDEX ; Index table
	LD BC, (XBC + WA)		; Get index offset
	EXTZ XBC
	LD XWA, XHL
	CALL 0FF0A5Ch			; Processing routine
	LD XWA, XHL
	LD XBC, 00000014h		; Constant
	CALL 0FF0C18h			; Division
	CP XHL, 0000007Fh		; Clamp to 127 max
	RET ULE				; Return if <= 127
	LD XHL, 0000007Fh		; Clamp to 127
	RET

; Encoder_ProcessBreath - Process breath controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessBreath:
	LD HL, 0FFFFh			; Default return = no change
	CPL A				; Invert input
	LD (ENCODER_RAW_BREATH), A	; Store raw value
	EXTZ WA
	LDA XBC, ENCODER_LUT_BREATH_VALUE ; Lookup table
	LD A, (XBC + WA)		; Get processed value
	LD C, (0379Bh)			; Get system mode flags
	AND C, 00Fh			; Mask relevant bits
	JR NZ, Encoder_ProcessBreath_WithModeAdjustment	; If mode active, process
	CP (07F0Bh), 000h		; Check alternate condition
	JR Z, Encoder_ProcessBreath_SimplePassthrough	; Simple processing if clear

Encoder_ProcessBreath_WithModeAdjustment:
	LD C, (ENCODER_BREATH_MODE)	; Get breath mode
	CP C, 0
	RET Z				; Return if disabled
	SRL 001h, A			; Divide by 2
	LD L, A
	EXTZ HL
	DEC 1, C			; Decrement mode for index
	EXTZ BC
	ADD BC, BC			; Word index
	LDA XWA, ENCODER_LUT_BREATH_MULT ; Multiplier table
	LD DE, (XWA + BC)		; Get multiplier
	MUL XHL, DE			; Multiply
	LDA XWA, ENCODER_LUT_BREATH_OFFSET ; Offset table
	LD WA, (XWA + BC)		; Get offset
	SUB HL, WA			; Subtract offset
	ADD HL, 04080h			; Add center offset
	SRL 008h, HL			; Divide by 256
	ADD HL, HL			; Double
	LD A, L
	LD (MIDI_CC_BREATH_VALUE), A	; Store result
	JR T, Encoder_ProcessBreath_Return

Encoder_ProcessBreath_SimplePassthrough:
	CP (MIDI_CC_BREATH_VALUE), A	; Compare with current
	RET Z				; Return if unchanged
	LD (MIDI_CC_BREATH_VALUE), A	; Store new value
	LD L, A
	EXTZ HL

Encoder_ProcessBreath_Return:
	RET

; Encoder_ProcessFoot - Process foot controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessFoot:
	LD HL, 0FFFFh			; Default return = no change
	LD (ENCODER_RAW_FOOT), A	; Store raw value
	SRL 001h, A			; Divide by 2
	EXTZ WA
	LDA XBC, ENCODER_LUT_FOOT	; Lookup table
	LD A, (XBC + WA)		; Get processed value
	LD C, (MIDI_CC_FOOT_VALUE)	; Get current value
	RES 007h, C			; Clear change flag
	CP C, A				; Compare
	RET Z				; Return if unchanged
	LD (MIDI_CC_FOOT_VALUE), A	; Store new value
	LD L, A
	EXTZ HL				; Return value in HL
	RET

; Encoder_ProcessExpression - Process expression controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value (always returns value, no skip)
Encoder_ProcessExpression:
	CPL A				; Invert input
	LD C, A
	LD (ENCODER_RAW_EXPRESSION), C	; Store raw value
	SRL 001h, A			; Divide by 2
	EXTZ WA
	LDA XBC, ENCODER_LUT_EXPRESSION	; Lookup table
	LD A, (XBC + WA)		; Get processed value
	LD (MIDI_CC_EXPRESSION_VALUE), A ; Store value
	EXTZ WA
	LD HL, WA			; Return value in HL
	RET

; Encoder_PassthroughIdentity - Simple passthrough: returns input value in HL
; Input: A = value
; Output: HL = value
Encoder_PassthroughIdentity:
	LD L, A
	EXTZ HL
	RET

; Encoder_ReturnDefaultConstant - Returns constant 1
; Output: HL = 1
Encoder_ReturnDefaultConstant:
	LD HL, 1
	RET

; Encoder_ApplySystemModeSettings - Select processing mode based on system state
; Reads mode value from 0xC07D and configures encoder processing accordingly
Encoder_ApplySystemModeSettings:
	LD A, (0C07Dh)			; Get mode selector
	CP A, 6
	JR Z, Encoder_ConfigureRangeLimit		; Jump if mode 6
	CP A, 5
	JR Z, Encoder_ConfigureVolumeMode		; Jump if mode 5
	CP A, 4
	RET NZ				; Return if not mode 4
	; Mode 4: Configure breath mode
	LD A, (0C07Fh)
	AND A, 00Fh			; Mask low nibble
	RET Z				; Return if zero
	LD A, (0C07Eh)
	AND A, 00Fh			; Mask low nibble
	LD (ENCODER_BREATH_MODE), A	; Set breath mode
	RET

Encoder_ConfigureVolumeMode:
	LD A, (0C07Fh)
	AND A, 0FFh			; Full byte check
	RET Z				; Return if zero
	LD A, (0C07Eh)
	AND A, 0FFh			; Full byte
	LD (ENCODER_VOLUME_MODE), A	; Set volume mode
	RET

Encoder_ConfigureRangeLimit:
	LD A, (0C07Fh)
	RES 007h, A			; Clear bit 7
	CP A, 0
	RET Z				; Return if zero
	LD A, (0C07Eh)
	RES 007h, A			; Clear bit 7
	LD (ENCODER_RANGE_LIMIT), A	; Set range limit
	RET

; End of MIDI encoder routines
