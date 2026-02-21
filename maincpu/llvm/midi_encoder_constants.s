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
; MIDI Controller Values (RAM at 0x8Exxh)
; =============================================================================
; These store the current MIDI CC values. Bit 7 is used as a "pending change"
; flag for active sensing / change detection.

.equ MIDI_CC_MODWHEEL_PENDING, 0x8EE0	; Modulation value with change flag (bit 7)
.equ MIDI_CC_EXPRESSION_PENDING, 0x8EE2	; Expression value with change flag (bit 7)
.equ MIDI_CC_MODWHEEL_VALUE, 0x8EE4	; Current modulation wheel value (CC#1)
.equ MIDI_CC_EXPRESSION_VALUE, 0x8EE6	; Current expression value (CC#0)
.equ MIDI_CC_BREATH_VALUE, 0x8EE8	; Breath controller value (CC#2?)
.equ MIDI_CC_FOOT_VALUE, 0x8EEA	; Foot controller value (CC#4?)
.equ MIDI_CC_VOLUME_VALUE, 0x8EF4	; Volume controller value

; =============================================================================
; Encoder Raw Input Storage (RAM at 0x8Exxh)
; =============================================================================
; Raw ADC values from encoders before lookup table processing

.equ ENCODER_RAW_MODWHEEL, 0x8ECA	; Raw modulation wheel input
.equ ENCODER_RAW_VOLUME, 0x8ECC	; Raw volume input
.equ ENCODER_RAW_BREATH, 0x8ED4	; Raw breath controller input
.equ ENCODER_RAW_FOOT, 0x8ED6	; Raw foot controller input
.equ ENCODER_RAW_EXPRESSION, 0x8ED8	; Raw expression input

; =============================================================================
; Encoder Configuration/Mode Values (RAM at 0x8Exxh)
; =============================================================================
; Configuration values that control encoder behavior

.equ ENCODER_BREATH_MODE, 0x8EDA	; Breath controller mode/enable
.equ ENCODER_VOLUME_MODE, 0x8EDC	; Volume mode value
.equ ENCODER_RANGE_LIMIT, 0x8EDE	; Encoder range limit value

; =============================================================================
; Encoder Lookup Tables (ROM at 0xEDAxxxh)
; =============================================================================
; These tables convert raw encoder values to MIDI CC values.
; Each table is 128 bytes (one entry per raw value 0-127).

.equ ENCODER_LUT_MODWHEEL, 0xEDA13C	; Modulation wheel lookup table
.equ ENCODER_LUT_VOLUME, 0xEDA1BC	; Volume lookup table
.equ ENCODER_LUT_BREATH_INDEX, 0xEDA2BC	; Breath controller index lookup (word)
.equ ENCODER_LUT_BREATH_VALUE, 0xEDA2D2	; Breath controller value lookup
.equ ENCODER_LUT_BREATH_MULT, 0xEDA3D2	; Breath controller multiplier table
.equ ENCODER_LUT_BREATH_OFFSET, 0xEDA3EA	; Breath controller offset table
.equ ENCODER_LUT_FOOT, 0xEDA402	; Foot controller lookup table
.equ ENCODER_LUT_EXPRESSION, 0xEDA482	; Expression lookup table

; =============================================================================
; Encoder State Tracking (RAM at 0x8Fxxh)
; =============================================================================
; Variables for tracking encoder state changes

.equ ENCODER_0_LAST_VALUE, 0x8EFC	; Previous encoder 0 reading (for delta)
.equ ENCODER_1_LAST_VALUE, 0x8EFE	; Previous encoder 1 reading (for delta)
.equ ENCODER_0_STATUS, 0x8F04	; Encoder 0 status flags (bit 3 = changed)
.equ ENCODER_1_STATUS, 0x8F06	; Encoder 1 status flags (bit 3 = changed)
.equ ENCODER_0_OUTPUT, 0x8F10	; Encoder 0 output buffer (2 bytes: value + flags)
.equ ENCODER_1_OUTPUT, 0x8F16	; Encoder 1 output buffer (2 bytes: value + flags)
.equ ENCODER_STATE_BASE, 0x8F18	; Base of encoder state structure

; =============================================================================
; Encoder Handler Jump Table (ROM at 0xEDA0BCh)
; =============================================================================
; Jump table for encoder-specific value processing routines.
; Indexed by 5-bit encoder ID (0-31). Each entry is a 32-bit address.
; See ENCODER_HANDLER_TABLE_DATA in main source for the actual table contents.

.equ ENCODER_HANDLER_TABLE, 0xEDA0BC	; Jump table for encoder-specific handlers (in ROM)

; End of MIDI/Encoder constants
