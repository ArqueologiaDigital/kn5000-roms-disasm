#!/usr/bin/env python3
"""
Replace the raw MSP_DefaultSettings byte block with labeled field positions.
Binary I/O for Latin-1 safety.
"""

import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILE = os.path.join(REPO, 'maincpu', 'sequencer', 'composer_msp_defaults.s')

# The new structured MSP_DefaultSettings with field labels
NEW_MSP_BLOCK = b"""; ---------------------------------------------------------------------------
; Sub-block 1: Sound/Voice Defaults (offset 0x00, 224 bytes)
; ---------------------------------------------------------------------------
MSP_DefaultSettings:
MSP_Default_SoundVoice:
MSP_Default_Signature1:		.byte 0x48, 0x00, 0x4b, 0x00	; "H\\0K\\0" region signature
MSP_Default_Flags1:		.zero 4				; reserved flags
MSP_Default_Padding1:		.zero 3
MSP_Default_Volume:		.byte 0x5a, 0x5a, 0x5a		; default volume = 90 (x3 channels)
MSP_Default_VolumeFlags:	.zero 2
MSP_Default_BankSelect:		.byte 0x01			; bank select = 1
MSP_Default_BankFlags:		.zero 4
MSP_Default_PartAssign:		.byte 0x01, 0x01, 0x01, 0x01	; channels 1-4: part 1
				.byte 0x02, 0x02, 0x02, 0x02	; channels 5-8: part 2
MSP_Default_PartFlags:		.byte 0x00
MSP_Default_ReverbLevel:	.byte 0x80			; reverb send level
MSP_Default_ChorusLevel:	.byte 0x16			; chorus send level
MSP_Default_PanPosition1:	.byte 0x60, 0x00		; pan = 96 (slightly right)
MSP_Default_PanPosition2:	.byte 0x60, 0x00		; pan = 96
MSP_Default_EffectDepth:	.byte 0x1e, 0x00		; effect depth = 30
MSP_Default_VoiceMode:		.byte 0x00, 0x01		; voice mode
MSP_Default_Transpose:		.byte 0x54			; transpose (+84 semitones? or offset encoding)
MSP_Default_OctaveShift:	.byte 0x01			; octave shift
MSP_Default_TouchSense:		.byte 0x40			; touch sensitivity = 64
MSP_Default_TouchFlags:		.byte 0x00, 0x00, 0x00
MSP_Default_ReverbLevel2:	.byte 0x80			; reverb level (secondary)
MSP_Default_ChorusLevel2:	.byte 0x16			; chorus level (secondary)
MSP_Default_SoundPadding:	.zero 48
MSP_Default_VoiceEnable:	.byte 0x80			; voice enable master flag
MSP_Default_VoiceMask:		.byte 0xff, 0xff, 0xff, 0xff	; voice channel mask (all enabled)
MSP_Default_VoiceConfig:	.byte 0x87			; voice config flags
				.byte 0x81, 0x81		; per-voice flags
				.byte 0x81, 0x81, 0x81, 0x81	; per-voice flags (cont.)
				.byte 0x81, 0x81		; per-voice flags (cont.)
				.byte 0x83, 0x87		; per-voice flags (last 2)
MSP_Default_SoundReserved:	.zero 112

; ---------------------------------------------------------------------------
; Sub-block 2: Sequencer Defaults (offset 0xE0, 96 bytes)
; ---------------------------------------------------------------------------
MSP_Default_Sequencer:
MSP_Default_Signature2:		.byte 0x48, 0x00, 0x4b, 0x00	; "H\\0K\\0" region signature
MSP_Default_SeqFlags:		.zero 4				; reserved flags
MSP_Default_Tempo:		.byte 0x28, 0x00		; tempo = 40 (internal units)
MSP_Default_TimeSignature:	.byte 0x04, 0x00		; time signature numerator = 4
MSP_Default_Quantize:		.byte 0x10, 0x00		; quantize = 16 (16th note)
MSP_Default_SeqMode:		.byte 0x00, 0x01		; sequencer mode
MSP_Default_SeqReserved:	.zero 80

; ---------------------------------------------------------------------------
; Sub-block 3: Accompaniment/Rhythm Defaults (offset 0x140, ~1128 bytes)
; ---------------------------------------------------------------------------
MSP_Default_Accompaniment:
MSP_Default_Signature3:		.byte 0x48, 0x00, 0x4b, 0x00	; "H\\0K\\0" region signature
MSP_Default_AccompFlags:	.zero 4				; reserved flags
MSP_Default_NumParts:		.byte 0x14, 0x00		; number of parts = 20
MSP_Default_PartsField1:	.byte 0x00, 0x00
MSP_Default_NumVariations:	.byte 0x0a, 0x00		; variations = 10
MSP_Default_VarField1:		.byte 0x00, 0x00
MSP_Default_NumGroups:		.byte 0x07, 0x00		; groups = 7
MSP_Default_GroupField1:	.byte 0x00, 0x00
MSP_Default_PartsPerGroup:	.byte 0x03, 0x00		; parts per group = 3
MSP_Default_GroupField2:	.byte 0x00, 0x00
MSP_Default_NumChannels:	.byte 0x08, 0x00		; channels = 8
MSP_Default_ChannelField:	.byte 0x00, 0x00, 0x00, 0x00
MSP_Default_AccompPadding1:	.zero 32
MSP_Default_RhythmFlags:	.byte 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
MSP_Default_AccompPadding2:	.zero 24
MSP_Default_RhythmConfig:	.byte 0x00, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
MSP_Default_AccompReserved:	.zero 920

; Rhythm channel mapping table (30 entries + 2 padding)
; Maps interleaved part indices across 7 groups x ~3 parts/group + extras
; Pattern: group 0 parts [0,4,8], group 1 [1,5,9], ... group 6 [3,7,11], then [12..29]
MSP_Default_ChannelMap:		.byte 0x00, 0x04, 0x08, 0x01, 0x05, 0x09, 0x02, 0x06
				.byte 0x0a, 0x03, 0x07, 0x0b, 0x0c, 0x12, 0x18, 0x0d
				.byte 0x13, 0x19, 0x0e, 0x14, 0x1a, 0x0f, 0x15, 0x1b
				.byte 0x10, 0x16, 0x1c, 0x11, 0x17, 0x1d
MSP_Default_ChannelMapPad:	.zero 10

; Group index table: maps each of 20 parts to its group (1-7, 0=unused)
MSP_Default_GroupIndex:		.byte 0x01, 0x01, 0x01		; parts 0-2:  group 1
				.byte 0x02, 0x02, 0x02		; parts 3-5:  group 2
				.byte 0x03, 0x03, 0x03		; parts 6-8:  group 3
				.byte 0x04, 0x04, 0x04		; parts 9-11: group 4
				.byte 0x05, 0x05, 0x05		; parts 12-14: group 5
				.byte 0x06, 0x06, 0x06		; parts 15-17: group 6
				.byte 0x07, 0x07		; parts 18-19: group 7
MSP_Default_GroupIndexPad:	.zero 12

; Variation index table: maps each of 20 parts to its variation (0-2)
MSP_Default_VariationIndex:	.byte 0x00, 0x01, 0x02		; group 1: variations 0,1,2
				.byte 0x00, 0x01, 0x02		; group 2
				.byte 0x00, 0x01, 0x02		; group 3
				.byte 0x00, 0x01, 0x02		; group 4
				.byte 0x00, 0x01, 0x02		; group 5
				.byte 0x00, 0x01, 0x02		; group 6
				.byte 0x00, 0x01		; group 7 (2 parts only)

; Group offset table A: byte offsets for 7 groups (little-endian .short)
MSP_Default_GroupOffsetA:	.short 0x0000			; group 1 offset
				.short 0x0006			; group 2 offset
				.short 0x000c			; group 3 offset
				.short 0x0012			; group 4 offset
				.short 0x0018			; group 5 offset
				.short 0x001e			; group 6 offset
				.short 0x0024			; group 7 offset

; Group offset table B: duplicate/alternate offsets
MSP_Default_GroupOffsetB:	.short 0x0000
				.short 0x0006
				.short 0x000c
				.short 0x0012
				.short 0x0018
				.short 0x001e
				.short 0x0024

; Variation size table: cumulative sizes for 6 variations (little-endian .short)
MSP_Default_VariationSize:	.short 0x0000			; base
				.short 0x000a			; size 10
				.short 0x0064			; size 100
				.short 0x006d			; size 109
				.short 0x0076			; size 118
				.short 0x007f			; size 127
				.short 0x0088			; size 136

; Part-to-bank mapping: (bank_hi, bank_lo) pairs for 12 entries
MSP_Default_PartBankMap:	.byte 0x00, 0x00		; part 0: bank 0.0
				.byte 0x00, 0x01		; part 1: bank 0.1
				.byte 0x00, 0x02		; part 2: bank 0.2
				.byte 0x00, 0x03		; part 3: bank 0.3
				.byte 0x00, 0x04		; part 4: bank 0.4
				.byte 0x00, 0x05		; part 5: bank 0.5
				.byte 0x00, 0x00		; entry 6
				.byte 0x00, 0x00		; entry 7
				.byte 0x01, 0x00		; entry 8: bank 1.0
				.byte 0x01, 0x01		; entry 9: bank 1.1
				.byte 0x01, 0x02		; entry 10: bank 1.2
				.byte 0x01, 0x03		; entry 11: bank 1.3
				.byte 0x01, 0x04		; entry 12: bank 1.4
				.byte 0x01, 0x05		; entry 13: bank 1.5
MSP_Default_TrailingPad:	.zero 36
"""


def main():
    with open(FILE, 'rb') as f:
        data = f.read()

    # Find the old MSP_DefaultSettings block (from "MSP_DefaultSettings:" to "Composer_SettingsBlock:")
    start_marker = b'MSP_DefaultSettings:\n'
    end_marker = b'\nComposer_SettingsBlock:'

    start = data.find(start_marker)
    end = data.find(end_marker)
    assert start >= 0, "Start marker not found"
    assert end >= 0, "End marker not found"

    # Replace everything from start_marker to (but not including) end_marker's newline
    new_data = data[:start] + NEW_MSP_BLOCK + data[end + 1:]  # +1 to skip the \n before Composer

    with open(FILE, 'wb') as f:
        f.write(new_data)

    print(f"Replaced MSP_DefaultSettings with labeled field structure")


if __name__ == '__main__':
    main()
