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
	.byte 0x1d, 0xea, 0xe7, 0xfe	; EXTZ WA
	.byte 0xbf, 0x0e, 0x31	; LD E, C
	.byte 0x89, 0x01, 0x25	; AND E, 007h	; Extract bits 0-2 of encoder ID
	.byte 0xda, 0x12	; AND C, 0c0h	; Extract bits 6-7
	.byte 0x81, 0x21	; SRL 3, C	; Shift to bits 3-4
	.byte 0xd8, 0x12	; OR C, E	; Combine to form 5-bit index
	.byte 0xd8, 0xee, 0x08	; EXTZ BC
	.byte 0xda, 0x80	; SLA 002h, BC	; Multiply by 4 (jump table entry size)
	.byte 0xd8, 0x89	; LDA XDE, ENCODER_HANDLER_TABLE
	.byte 0xe9, 0x12	; EXTS XBC
	.byte 0xe9, 0xee, 0x00	; ADD XBC, XDE	; XBC = table entry address
	.byte 0xaf, 0x14, 0x20	; LD XIX, (XBC)	; Load handler address
	.byte 0xd8, 0x8a	; JP T, XIX	; Jump to handler

; ============================================================================
; Encoder Value Processing Handlers
; These routines process raw encoder inputs and convert them to MIDI CC values
; using lookup tables. Called via ENCODER_HANDLER_TABLE dispatch.
; ============================================================================

; Encoder_ProcessModwheel - Process modulation wheel input (Encoder ID 2)
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessModwheel:
	.byte 0xea, 0x12	; LD HL, 0FFFFh	; Default return = no change
	.byte 0xe9, 0x82	; CPL A	; Invert input value
	.byte 0x40, 0xff, 0xff, 0xff, 0xff	; LD C, A
	.byte 0x41, 0x23, 0x00, 0xc0, 0x01	; LD (ENCODER_RAW_MODWHEEL), C	; Store raw value
	.byte 0x1d, 0x58, 0x9d, 0xfa	; SRL 001h, A	; Divide by 2
	.byte 0x78, 0xc5, 0x01	; EXTZ WA
	.byte 0xd8, 0x12	; LDA XBC, ENCODER_LUT_MODWHEEL	; Lookup table address
	.byte 0xaf, 0x14, 0x21	; LD A, (XBC + WA)	; Get processed value from table
	.byte 0xe9, 0xef, 0x00	; LD C, (MIDI_CC_MODWHEEL_VALUE)	; Get current value
	.byte 0xd7, 0xe6, 0xa8	; RES 007h, C	; Clear change flag
	.byte 0xd9, 0x8a	; CP C, A	; Compare with new value
	.byte 0xd9, 0xef, 0x08	; RET Z	; Return if unchanged
	.byte 0x22, 0x00	; LD (MIDI_CC_MODWHEEL_VALUE), A	; Store new value
	.byte 0xd9, 0x12	; LD L, A
	.byte 0xda, 0x12	; EXTZ HL	; Return value in HL
	.byte 0x1d, 0xf9, 0x9c, 0xfc	; RET

; Encoder_ProcessVolume - Process volume/expression slider (Encoder ID 5)
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessVolume:
	.byte 0xaf, 0x14, 0x20	; PUSH IZ
	.byte 0xd8, 0x12	; LD IZ, 0FFFFh	; Default return = no change
	.byte 0xaf, 0x14, 0x21	; LD (ENCODER_RAW_VOLUME), A	; Store raw value
	.byte 0xe9, 0xef, 0x00	; EXTZ WA
	.byte 0xd7, 0xe6, 0xa8	; LDA XBC, ENCODER_LUT_VOLUME	; Lookup table address
	.byte 0xd9, 0x8a	; LD A, (XBC + WA)	; Get processed value
	.byte 0xda, 0xef, 0x08	; CALR Encoder_ClampScaleAndNormalize	; Clamp to valid range
	.byte 0x24, 0x00	; LD A, L
	.byte 0xda, 0x12	; CP A, (MIDI_CC_VOLUME_VALUE)	; Compare with current
	.byte 0xd9, 0x12	; JR Z, Encoder_ProcessVolume_NoChange
	.byte 0x29	; LD (MIDI_CC_VOLUME_VALUE), A	; Store new value
	.byte 0xd9, 0xa8	; LD IZL, A
	.byte 0x1d, 0x55, 0xb2, 0xfd	; EXTZ IZ	; IZ = new value

Encoder_ProcessVolume_NoChange:
	.byte 0xd8, 0xa9	; LD HL, IZ	; Return value in HL
	.byte 0x78, 0x82, 0x01	; POP IZ
	.byte 0xbf, 0x04, 0x50	; RET

; Encoder_ClampScaleAndNormalize - Clamp value L to minimum in ENCODER_RANGE_LIMIT
; Input: L = value to clamp, A = raw lookup value
; Output: HL = clamped and scaled value
Encoder_ClampScaleAndNormalize:
	.byte 0x9f, 0x04, 0x3f, 0x0f, 0x00	; LD L, A
	.byte 0x62, 0x10	; LD C, (ENCODER_RANGE_LIMIT)	; Get minimum limit
	.byte 0x9f, 0x04, 0x3f, 0x15, 0x00	; CP L, C	; Compare with limit
	.byte 0x71, 0x74, 0x01	; JR NC, Encoder_PerformScaling	; Skip if >= limit
	.byte 0x9f, 0x04, 0x3f, 0x16, 0x00	; LD L, C	; Clamp to minimum

Encoder_PerformScaling:
	.byte 0x7a, 0x6c, 0x01	; SUB L, C	; Subtract minimum
	.byte 0xbf, 0x0c, 0x02, 0x00, 0x00	; LD_H 000h
	.byte 0xaf, 0x14, 0x20	; EXTZ XHL
	.byte 0xe8, 0xef, 0x00	; SLL 008h, XHL	; Scale up (multiply by 256)
	.byte 0xd7, 0xe2, 0xa8	; LD XWA, XHL
	.byte 0xbf, 0x0a, 0x50	; LD XBC, 0000ECh	; Divisor
	.byte 0x9f, 0x04, 0x20	; CALL 0FF0C18h	; Division routine
	.byte 0xd9, 0xa8	; LD A, (ENCODER_VOLUME_MODE)	; Get mode value
	.byte 0x1d, 0xf7, 0xd4, 0xfc	; EXTZ WA
	.byte 0xbf, 0x11, 0x47	; ADD WA, WA	; Double for word table index
	.byte 0x9f, 0x04, 0x20	; LDA XBC, ENCODER_LUT_BREATH_INDEX	; Index table
	.byte 0x31, 0x20, 0x00	; LD BC, (XBC + WA)	; Get index offset
	.byte 0x1d, 0xf7, 0xd4, 0xfc	; EXTZ XBC
	.byte 0xbf, 0x0e, 0x30	; LD XWA, XHL
	.byte 0xb8, 0x04, 0x47	; CALL 0FF0A5Ch	; Processing routine
	.byte 0x9f, 0x04, 0x21	; LD XWA, XHL
	.byte 0xb8, 0x02, 0x43	; LD XBC, 00000014h	; Constant
	.byte 0x1d, 0xea, 0xe7, 0xfe	; CALL 0FF0C18h	; Division
	.byte 0xbf, 0x0e, 0x31	; CP XHL, 0000007Fh	; Clamp to 127 max
	.byte 0x81, 0x21	; RET ULE	; Return if <= 127
	.byte 0xd8, 0x12	; LD XHL, 0000007Fh	; Clamp to 127
	.byte 0xbf, 0x08, 0x50	; RET

; Encoder_ProcessBreath - Process breath controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessBreath:
	.byte 0x89, 0x01, 0x21	; LD HL, 0FFFFh	; Default return = no change
	.byte 0xc7, 0xf8, 0x99	; CPL A	; Invert input
	.byte 0xde, 0x12	; LD (ENCODER_RAW_BREATH), A	; Store raw value
	.byte 0x9f, 0x04, 0x20	; EXTZ WA
	.byte 0x9f, 0x08, 0x21	; LDA XBC, ENCODER_LUT_BREATH_VALUE	; Lookup table
	.byte 0x1e, 0x2b, 0x01	; LD A, (XBC + WA)	; Get processed value
	.byte 0xbf, 0x06, 0x53	; LD C, (0379Bh)	; Get system mode flags
	.byte 0x9f, 0x0a, 0x86	; AND C, 00Fh	; Mask relevant bits
	.byte 0xde, 0xd8	; JR NZ, Encoder_ProcessBreath_WithModeAdjustment	; If mode active, process
	.byte 0x69, 0x59	; CP (07F0Bh), 000h	; Check alternate condition
	.byte 0x9f, 0x08, 0x3f, 0x00, 0x00	; JR Z, Encoder_ProcessBreath_SimplePassthrough	; Simple processing if clear

Encoder_ProcessBreath_WithModeAdjustment:
	.byte 0x62, 0x4d	; LD C, (ENCODER_BREATH_MODE)	; Get breath mode
	.byte 0x9f, 0x08, 0x20	; CP C, 0
	.byte 0xd7, 0xfa, 0x98	; RET Z	; Return if disabled
	.byte 0xbf, 0x0a, 0x56	; SRL 001h, A	; Divide by 2
	.byte 0x9f, 0x06, 0x23	; LD L, A
	.byte 0xd7, 0xfa, 0xd8	; EXTZ HL
	.byte 0x72, 0x9d, 0x00	; DEC 1, C	; Decrement mode for index
	.byte 0xd7, 0xfa, 0x69	; EXTZ BC
	.byte 0x9f, 0x04, 0x20	; ADD BC, BC	; Word index
	.byte 0xd7, 0xfa, 0x89	; LDA XWA, ENCODER_LUT_BREATH_MULT	; Multiplier table
	.byte 0x1e, 0xfc, 0x00	; LD DE, (XWA + BC)	; Get multiplier
	.byte 0xdb, 0x88	; MUL XHL, DE	; Multiply
	.byte 0xd8, 0x61	; LDA XWA, ENCODER_LUT_BREATH_OFFSET	; Offset table
	.byte 0x9f, 0x0a, 0x88	; LD WA, (XWA + BC)	; Get offset
	.byte 0xdb, 0xcf, 0xff, 0xff	; SUB HL, WA	; Subtract offset
	.byte 0x6e, 0x15	; ADD HL, 04080h	; Add center offset
	.byte 0xd7, 0xfa, 0xd8	; SRL 008h, HL	; Divide by 256
	.byte 0x6a, 0x10	; ADD HL, HL	; Double
	.byte 0x9f, 0x08, 0x20	; LD A, L
	.byte 0xd7, 0xfa, 0x98	; LD (MIDI_CC_BREATH_VALUE), A	; Store result
	.byte 0xbf, 0x0a, 0x02, 0x00, 0x00	; JR T, Encoder_ProcessBreath_Return

Encoder_ProcessBreath_SimplePassthrough:
	.byte 0x9f, 0x06, 0x23	; CP (MIDI_CC_BREATH_VALUE), A	; Compare with current
	.byte 0x68, 0x6f	; RET Z	; Return if unchanged
	.byte 0xdb, 0xcf, 0xff, 0xff	; LD (MIDI_CC_BREATH_VALUE), A	; Store new value
	.byte 0x6e, 0x69	; LD L, A
	.byte 0xd7, 0xfa, 0xd8	; EXTZ HL

Encoder_ProcessBreath_Return:
	.byte 0x6a, 0xc7	; RET

; Encoder_ProcessFoot - Process foot controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value, or 0xFFFF if unchanged
Encoder_ProcessFoot:
	.byte 0x68, 0x62	; LD HL, 0FFFFh	; Default return = no change
	.byte 0xde, 0xa8	; LD (ENCODER_RAW_FOOT), A	; Store raw value
	.byte 0x78, 0xc1, 0x00	; SRL 001h, A	; Divide by 2
	.byte 0x9f, 0x06, 0xf6	; EXTZ WA
	.byte 0x72, 0xbb, 0x00	; LDA XBC, ENCODER_LUT_FOOT	; Lookup table
	.byte 0x9f, 0x08, 0x3f, 0x11, 0x00	; LD A, (XBC + WA)	; Get processed value
	.byte 0x79, 0xb0, 0x00	; LD C, (MIDI_CC_FOOT_VALUE)	; Get current value
	.byte 0x9f, 0x08, 0x20	; RES 007h, C	; Clear change flag
	.byte 0xd7, 0xfa, 0x98	; CP C, A	; Compare
	.byte 0xbf, 0x0a, 0x56	; RET Z	; Return if unchanged
	.byte 0x9f, 0x06, 0x23	; LD (MIDI_CC_FOOT_VALUE), A	; Store new value
	.byte 0xd7, 0xfa, 0xcf, 0x11, 0x00	; LD L, A
	.byte 0x69, 0x3c	; EXTZ HL	; Return value in HL
	.byte 0xd7, 0xfa, 0x61	; RET

; Encoder_ProcessExpression - Process expression controller input
; Input: A = raw encoder value
; Output: HL = processed MIDI CC value (always returns value, no skip)
Encoder_ProcessExpression:
	.byte 0xdb, 0x61	; CPL A	; Invert input
	.byte 0x9f, 0x0a, 0xab	; LD C, A
	.byte 0x9f, 0x04, 0x20	; LD (ENCODER_RAW_EXPRESSION), C	; Store raw value
	.byte 0xd7, 0xfa, 0x89	; SRL 001h, A	; Divide by 2
	.byte 0x1e, 0x96, 0x00	; EXTZ WA
	.byte 0xdb, 0xcf, 0xff, 0xff	; LDA XBC, ENCODER_LUT_EXPRESSION	; Lookup table
	.byte 0x6e, 0x18	; LD A, (XBC + WA)	; Get processed value
	.byte 0xd7, 0xfa, 0xcf, 0x11, 0x00	; LD (MIDI_CC_EXPRESSION_VALUE), A	; Store value
	.byte 0x61, 0x11	; EXTZ WA
	.byte 0x9f, 0x08, 0x20	; LD HL, WA	; Return value in HL
	.byte 0xd7, 0xfa, 0x98	; RET

; Encoder_PassthroughIdentity - Simple passthrough: returns input value in HL
; Input: A = value
; Output: HL = value
Encoder_PassthroughIdentity:
	.byte 0x9f, 0x06, 0x20	; LD L, A
	.byte 0xbf, 0x0a, 0x50	; EXTZ HL
	.byte 0x9f, 0x06, 0x23	; RET

; Encoder_ReturnDefaultConstant - Returns constant 1
; Output: HL = 1
Encoder_ReturnDefaultConstant:
	.byte 0x68, 0x0d	; LD HL, 1
	.byte 0xdb, 0xcf, 0xff, 0xff	; RET

; Encoder_ApplySystemModeSettings - Select processing mode based on system state
; Reads mode value from 0xC07D and configures encoder processing accordingly
Encoder_ApplySystemModeSettings:
	.byte 0x6e, 0x07	; LD A, (0C07Dh)	; Get mode selector
	.byte 0xd7, 0xfa, 0xcf, 0x11, 0x00	; CP A, 6
	.byte 0x61, 0xc4	; JR Z, Encoder_ConfigureRangeLimit	; Jump if mode 6
	.byte 0xd7, 0xfa, 0x88	; CP A, 5
	.byte 0xbf, 0x08, 0x50	; JR Z, Encoder_ConfigureVolumeMode	; Jump if mode 5
	.byte 0x9f, 0x0a, 0x26	; CP A, 4
	.byte 0xbf, 0x06, 0x53	; RET NZ	; Return if not mode 4
	; Mode 4: Configure breath mode
	.byte 0x9f, 0x0c, 0x3f, 0x00, 0x00	; LD A, (0C07Fh)
	.byte 0x76, 0x32, 0xff	; AND A, 00Fh	; Mask low nibble
	.byte 0xbf, 0x0e, 0x31	; RET Z	; Return if zero
	.byte 0x89, 0x01, 0x21	; LD A, (0C07Eh)
	.byte 0xd8, 0x12	; AND A, 00Fh	; Mask low nibble
	.byte 0xde, 0xf0	; LD (ENCODER_BREATH_MODE), A	; Set breath mode
	.byte 0x6e, 0x09	; RET

Encoder_ConfigureVolumeMode:
	.byte 0x81, 0x21	; LD A, (0C07Fh)
	.byte 0xd8, 0x12	; AND A, 0FFh	; Full byte check
	.byte 0x9f, 0x08, 0xf0	; RET Z	; Return if zero
	.byte 0x66, 0x31	; LD A, (0C07Eh)
	.byte 0x9f, 0x04, 0x20	; AND A, 0FFh	; Full byte
	.byte 0xd8, 0x12	; LD (ENCODER_VOLUME_MODE), A	; Set volume mode
	.byte 0x9f, 0x08, 0x21	; RET

Encoder_ConfigureRangeLimit:
	.byte 0xd9, 0x12	; LD A, (0C07Fh)
	.byte 0xc7, 0xf8, 0x8d	; RES 007h, A	; Clear bit 7
	.byte 0xda, 0x12	; CP A, 0
	.byte 0x1d, 0xf9, 0x9c, 0xfc	; RET Z	; Return if zero
	.byte 0x9f, 0x04, 0x20	; LD A, (0C07Eh)
	.byte 0xd8, 0x12	; RES 007h, A	; Clear bit 7
	.byte 0x9f, 0x08, 0x21	; LD (ENCODER_RANGE_LIMIT), A	; Set range limit
	.byte 0xcb, 0x8d	; RET

; End of MIDI encoder routines
