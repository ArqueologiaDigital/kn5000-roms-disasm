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

MIDI_CC_MODWHEEL_PENDING	EQU 8EE0h ; Modulation value with change flag (bit 7)
MIDI_CC_EXPRESSION_PENDING	EQU 8EE2h ; Expression value with change flag (bit 7)
MIDI_CC_MODWHEEL_VALUE		EQU 8EE4h ; Current modulation wheel value (CC#1)
MIDI_CC_EXPRESSION_VALUE	EQU 8EE6h ; Current expression value (CC#0)
MIDI_CC_BREATH_VALUE		EQU 8EE8h ; Breath controller value (CC#2?)
MIDI_CC_FOOT_VALUE		EQU 8EEAh ; Foot controller value (CC#4?)
MIDI_CC_VOLUME_VALUE		EQU 8EF4h ; Volume controller value

; =============================================================================
; Encoder Raw Input Storage (RAM at 0x8Exxh)
; =============================================================================
; Raw ADC values from encoders before lookup table processing

ENCODER_RAW_MODWHEEL		EQU 8ECAh ; Raw modulation wheel input
ENCODER_RAW_VOLUME		EQU 8ECCh ; Raw volume input
ENCODER_RAW_BREATH		EQU 8ED4h ; Raw breath controller input
ENCODER_RAW_FOOT		EQU 8ED6h ; Raw foot controller input
ENCODER_RAW_EXPRESSION		EQU 8ED8h ; Raw expression input

; =============================================================================
; Encoder Configuration/Mode Values (RAM at 0x8Exxh)
; =============================================================================
; Configuration values that control encoder behavior

ENCODER_BREATH_MODE		EQU 8EDAh ; Breath controller mode/enable
ENCODER_VOLUME_MODE		EQU 8EDCh ; Volume mode value
ENCODER_RANGE_LIMIT		EQU 8EDEh ; Encoder range limit value

; =============================================================================
; Encoder Lookup Tables (ROM at 0xEDAxxxh)
; =============================================================================
; These tables convert raw encoder values to MIDI CC values.
; Each table is 128 bytes (one entry per raw value 0-127).

ENCODER_LUT_MODWHEEL		EQU 0EDA13Ch ; Modulation wheel lookup table
ENCODER_LUT_VOLUME		EQU 0EDA1BCh ; Volume lookup table
ENCODER_LUT_BREATH_INDEX	EQU 0EDA2BCh ; Breath controller index lookup (word)
ENCODER_LUT_BREATH_VALUE	EQU 0EDA2D2h ; Breath controller value lookup
ENCODER_LUT_BREATH_MULT		EQU 0EDA3D2h ; Breath controller multiplier table
ENCODER_LUT_BREATH_OFFSET	EQU 0EDA3EAh ; Breath controller offset table
ENCODER_LUT_FOOT		EQU 0EDA402h ; Foot controller lookup table
ENCODER_LUT_EXPRESSION		EQU 0EDA482h ; Expression lookup table

; =============================================================================
; Encoder State Tracking (RAM at 0x8Fxxh)
; =============================================================================
; Variables for tracking encoder state changes

ENCODER_0_LAST_VALUE		EQU 8EFCh ; Previous encoder 0 reading (for delta)
ENCODER_1_LAST_VALUE		EQU 8EFEh ; Previous encoder 1 reading (for delta)
ENCODER_0_STATUS		EQU 8F04h ; Encoder 0 status flags (bit 3 = changed)
ENCODER_1_STATUS		EQU 8F06h ; Encoder 1 status flags (bit 3 = changed)
ENCODER_0_OUTPUT		EQU 8F10h ; Encoder 0 output buffer (2 bytes: value + flags)
ENCODER_1_OUTPUT		EQU 8F16h ; Encoder 1 output buffer (2 bytes: value + flags)
ENCODER_STATE_BASE		EQU 8F18h ; Base of encoder state structure

; =============================================================================
; Encoder Handler Jump Table (ROM at 0xEDA0BCh)
; =============================================================================
; Jump table for encoder-specific value processing routines.
; Indexed by 5-bit encoder ID (0-31). Each entry is a 32-bit address.
; See ENCODER_HANDLER_TABLE_DATA in main source for the actual table contents.

ENCODER_HANDLER_TABLE		EQU 0EDA0BCh ; Jump table for encoder-specific handlers (in ROM)

; End of MIDI/Encoder constants
