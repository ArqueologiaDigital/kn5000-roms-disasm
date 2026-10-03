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

.equ MIDI_CC_MODWHEEL_PENDING, 0x8e44	; Modulation value with change flag (bit 7)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8ee0
.equ MIDI_CC_EXPRESSION_PENDING, 0x8e46	; Expression value with change flag (bit 7)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8ee2
.equ MIDI_CC_MODWHEEL_VALUE, 0x8e48	; Current modulation wheel value (CC#1)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8ee4
.equ MIDI_CC_EXPRESSION_VALUE, 0x8e4a	; Current expression value (CC#0)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8ee6
.equ MIDI_CC_BREATH_VALUE, 0x8e4c	; Breath controller value (CC#2?)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8ee8
.equ MIDI_CC_FOOT_VALUE, 0x8e4e	; Foot controller value (CC#4?)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8eea
.equ MIDI_CC_VOLUME_VALUE, 0x8e58	; Volume controller value	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8ef4

; =============================================================================
; Encoder Raw Input Storage (RAM at 0x8exxh)
; =============================================================================
; Raw ADC values from encoders before lookup table processing

.equ ENCODER_RAW_MODWHEEL, 0x8e2e	; Raw modulation wheel input	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8eca
.equ ENCODER_RAW_VOLUME, 0x8e30	; Raw volume input	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8ecc
.equ ENCODER_RAW_BREATH, 0x8e38	; Raw breath controller input	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8ed4
.equ ENCODER_RAW_FOOT, 0x8e3a	; Raw foot controller input	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8ed6
.equ ENCODER_RAW_EXPRESSION, 0x8e3c	; Raw expression input	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8ed8

; =============================================================================
; Encoder Configuration/Mode Values (RAM at 0x8exxh)
; =============================================================================
; Configuration values that control encoder behavior

.equ ENCODER_BREATH_MODE, 0x8e3e	; Breath controller mode/enable	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8eda
.equ ENCODER_VOLUME_MODE, 0x8e40	; Volume mode value	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8edc
.equ ENCODER_RANGE_LIMIT, 0x8e42	; Encoder range limit value	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8ede

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

.equ ENCODER_0_LAST_VALUE, 0x8e60	; Previous encoder 0 reading (for delta)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8efc
.equ ENCODER_1_LAST_VALUE, 0x8e62	; Previous encoder 1 reading (for delta)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8efe
.equ ENCODER_0_STATUS, 0x8e68	; Encoder 0 status flags (bit 3 = changed)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8f04
.equ ENCODER_1_STATUS, 0x8e6a	; Encoder 1 status flags (bit 3 = changed)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8f06
.equ ENCODER_0_OUTPUT, 0x8e74	; Encoder 0 output buffer (2 bytes: value + flags)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8f10
.equ ENCODER_1_OUTPUT, 0x8e7a	; Encoder 1 output buffer (2 bytes: value + flags)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8f16
.equ ENCODER_STATE_BASE, 0x8e7c	; Base of encoder state structure	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0x8f18

; =============================================================================
; Encoder Handler Jump Table (ROM at 0xeda0bch)
; =============================================================================
; Jump table for encoder-specific value processing routines.
; Indexed by 5-bit encoder ID (0-31). Each entry is a 32-bit address.
; See ENCODER_HANDLER_TABLE_DATA in main source for the actual table contents.

	; (EQU->inline label) ENCODER_HANDLER_TABLE = 0xeda0bc

; End of MIDI/Encoder constants

; Rhythm Data ROM (IC14, at 0x400000) status/base, 32-bit: RhythmROM_ValidateHeader stores 0
; when the ROM starts with its 12-byte signature (00 01 04 05 83 00 01 04 05 83 00 01) and
; 0xffffffff when not (RhythmROM_CheckValid tests that); the rhythm readers add it to
; 0x400000 + a RhythmROM_BankProgramLocators offset.
.equ RHYTHM_ROM_BASE, 0x31db
