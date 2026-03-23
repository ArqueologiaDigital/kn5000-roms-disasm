; =============================================================================
; midi_encoder_constants.asm - MIDI and Encoder Constants for Main CPU
; =============================================================================
; This file contains all MIDI controller and encoder-related constants,
; including RAM addresses for controller values and ROM addresses for
; lookup tables.
;
; The KN5000 uses analog encoders (modwheel, volume slider, breath, foot,
; expression) that are converted to MIDI CC values via lookup tables.
;
; Contents:
;   - MIDI CC value storage addresses (RAM)
;   - Raw encoder input storage (RAM)
;   - Encoder configuration variables (RAM)
;   - Encoder lookup tables (ROM addresses)
;   - Encoder state tracking (RAM)
;   - Encoder handler jump table (ROM address)
; =============================================================================

; =============================================================================
; MIDI Controller Values (RAM at 0x8exxh)
; =============================================================================
; These store the current MIDI CC values. Bit 7 is used as a "pending change"
; flag for active sensing / change detection.

.equ MIDI_CC_MODWHEEL_PENDING, 0x8ee0	; Modulation value with change flag (bit 7)
.equ MIDI_CC_EXPRESSION_PENDING, 0x8ee2	; Expression value with change flag (bit 7)
.equ MIDI_CC_MODWHEEL_VALUE, 0x8ee4	; Current modulation wheel value (CC#1)
.equ MIDI_CC_EXPRESSION_VALUE, 0x8ee6	; Current expression value (CC#0)
.equ MIDI_CC_BREATH_VALUE, 0x8ee8	; Breath controller value (CC#2?)
.equ MIDI_CC_FOOT_VALUE, 0x8eea	; Foot controller value (CC#4?)
.equ MIDI_CC_VOLUME_VALUE, 0x8ef4	; Volume controller value

; =============================================================================
; Encoder Raw Input Storage (RAM at 0x8exxh)
; =============================================================================
; Raw ADC values from encoders before lookup table processing

.equ ENCODER_RAW_MODWHEEL, 0x8eca	; Raw modulation wheel input
.equ ENCODER_RAW_VOLUME, 0x8ecc	; Raw volume input
.equ ENCODER_RAW_BREATH, 0x8ed4	; Raw breath controller input
.equ ENCODER_RAW_FOOT, 0x8ed6	; Raw foot controller input
.equ ENCODER_RAW_EXPRESSION, 0x8ed8	; Raw expression input

; =============================================================================
; Encoder Configuration/Mode Values (RAM at 0x8exxh)
; =============================================================================
; Configuration values that control encoder behavior

.equ ENCODER_BREATH_MODE, 0x8eda	; Breath controller mode/enable
.equ ENCODER_VOLUME_MODE, 0x8edc	; Volume mode value
.equ ENCODER_RANGE_LIMIT, 0x8ede	; Encoder range limit value

; =============================================================================
; Encoder Lookup Tables (ROM at 0xedaxxxh)
; =============================================================================
; These tables convert raw encoder values to MIDI CC values.
; Each table is 128 bytes (one entry per raw value 0-127).

	; (EQU->inline label) ENCODER_LUT_MODWHEEL = 0xeda13c
	; (EQU->inline label) ENCODER_LUT_VOLUME = 0xeda1bc
	; (EQU->inline label) ENCODER_LUT_BREATH_INDEX = 0xeda2bc
	; (EQU->inline label) ENCODER_LUT_BREATH_VALUE = 0xeda2d2
	; (EQU->inline label) ENCODER_LUT_BREATH_MULT = 0xeda3d2
	; (EQU->inline label) ENCODER_LUT_BREATH_OFFSET = 0xeda3ea
	; (EQU->inline label) ENCODER_LUT_FOOT = 0xeda402
	; (EQU->inline label) ENCODER_LUT_EXPRESSION = 0xeda482

; =============================================================================
; Encoder State Tracking (RAM at 0x8fxxh)
; =============================================================================
; Variables for tracking encoder state changes

.equ ENCODER_0_LAST_VALUE, 0x8efc	; Previous encoder 0 reading (for delta)
.equ ENCODER_1_LAST_VALUE, 0x8efe	; Previous encoder 1 reading (for delta)
.equ ENCODER_0_STATUS, 0x8f04	; Encoder 0 status flags (bit 3 = changed)
.equ ENCODER_1_STATUS, 0x8f06	; Encoder 1 status flags (bit 3 = changed)
.equ ENCODER_0_OUTPUT, 0x8f10	; Encoder 0 output buffer (2 bytes: value + flags)
.equ ENCODER_1_OUTPUT, 0x8f16	; Encoder 1 output buffer (2 bytes: value + flags)
.equ ENCODER_STATE_BASE, 0x8f18	; Base of encoder state structure

; =============================================================================
; Encoder Handler Jump Table (ROM at 0xeda0bch)
; =============================================================================
; Jump table for encoder-specific value processing routines.
; Indexed by 5-bit encoder ID (0-31). Each entry is a 32-bit address.
; See ENCODER_HANDLER_TABLE_DATA in main source for the actual table contents.

	; (EQU->inline label) ENCODER_HANDLER_TABLE = 0xeda0bc

; End of MIDI/Encoder constants
