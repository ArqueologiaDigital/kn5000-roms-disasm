#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for voice update routines in subcpu (023-024 range).

Based on analysis of the 0x023000-0x024FFF address range in the SubCPU
audio subsystem.  This range implements per-voice parameter calculation
routines that are called in sequence from the main voice-update dispatcher
(LABEL_02B4E3 / LABEL_02BCD6) once per active voice on every note-on or
control-change event.

Functional groups in address order:

  023000-0231D9  Pitch / frequency computation helpers
                   022F3C  compute frequency word for left output register
                   022FCC  compute frequency word for right output register
                   02300E  (opaque .byte block — variant, not renamed)
                   023043  compute + write left-channel frequency to DSP reg 0x045204
                   02315F  compute + write right-channel level to DSP reg 0x045206
                   0231DA  (opaque .byte block — variant, not renamed)

  0231DA-02326C  Colour / timbre helpers
                   02324E  look up timbre index → HL (channel colour word)
                   023279  clamp upper bound of pan/timbre field
                   023290  clamp lower bound
                   02329C  interpolate colour delta → HL

  0232B3-0232C6  Generic clamp-to-byte helpers
                   0232B3  clamp WA to [0, 0xFF] → WA
                   023328  clamp WA to [0, 0xFF] → HL  (duplicate variant)

  0232C7-02333D  Voice colour write
                   0232C7  compute colour word and write to DSP reg 0x0451D0

  02333E-0235BC  Voice envelope / velocity triggers
                   02333E  update envelope velocity/release counters for voice
                   0233F8  apply velocity to DSP envelope (type-0 voice)
                   02341F  velocity handler c=1 (type-0 voice)
                   02343C  velocity handler c=0 → call Note_Attack_S1
                   023448  velocity handler c=1-bit-1
                   023453  velocity handler c=1-bit-1 → call Note_Attack_S2
                   02345F  velocity handler c=2, check trigger bit 3
                   023477  velocity handler c=2, trigger velocity attack
                   023490  velocity handler c=3, check trigger bit 3
                   0234A8  velocity handler c=3, trigger velocity attack
                   0234C1  clear return flag
                   0234C3  gate: call LABEL_02289D if flag set
                   0234D2  velocity handler for type-2 voice (dispatch c=0..3)
                   0234EF  type-2, c=0 → call Note_Attack_S1
                   0234FB  type-2, c=1
                   023506  type-2, c=1 → call Note_Attack_S2
                   023512  type-2, c=2, check trigger bit 4
                   02352A  type-2, c=2, trigger velocity attack
                   023543  type-2, c=3, check trigger bit 4
                   02355B  type-2, c=3, trigger velocity attack
                   023574  clear return flag (type-2)
                   023576  gate: call LABEL_0228D9 if flag set

  023584-023808  Pitch computation with detune/transpose
                   023584  compute pitch word including detune/bend/vibrato
                   023637  pitch bend handler: type 0x80 (octave)
                   023658  pitch bend handler: type 0x40 (fixed offset)
                   023660  pitch bend handler: type 0x41 (scaled table lookup)
                   02367C  pitch bend handler: type 0x42 (second table)
                   023698  non-active path: load base pitch, apply bend type
                   0236CB  non-active bend type 0x40
                   0236D2  non-active bend type 0x41
                   0236ED  non-active bend type 0x42
                   023708  non-active bend type 0x42+ (chromatic table)
                   023738  apply portamento scaling + store pitch word
                   023774  portamento off: add offset from legato table
                   02377E  portamento 7: load direct legato pitch
                   023786  portamento active: subtract centre bias
                   023797  portamento centre bias only
                   02379D  portamento: set fixed pitch 0x4280
                   0237A0  apply coarse/fine tune offsets, then compute final pitch
                   0237E5  compute legato pitch (variant B)
                   023804  return from pitch computation

  023809-023808  Simple pitch word copy (non-portamento path)
                   023809  copy base pitch and apply ADSR pitch envelope

  023849-0238F7  Pitch interpolation dispatch
                   023849  dispatch pitch interpolation by voice flags (bits 5,6,7)
                   0238AC  interp variant: bits 5+6
                   0238B9  interp variant: bit 7 set, bit 5 clear
                   0238CA  interp variant: bits 6+7 only
                   0238D7  interp variant: bit 6 clear, bit 7 set
                   0238E8  interp variant: base path
                   0238F3  return from pitch interp dispatch

  0238F8-023A03  Pitch envelope advancement
                   0238F8  advance pitch envelope state machine for voice
                   023942  pitch env state >= 1 and < 3: use table B
                   023979  pitch env state >= 3: use routing table
                   02399D  store updated pitch envelope output registers

  0239E1-023A03  Volume scale helper
                   0239E1  scale velocity DRAM word → write to 0x041366

  023A05-023A8D  Pitch output register write (with portamento)
                   023A05  compute + write output pitch offset to 0x0451DA (portamento on)
                   023A44  clear portamento flag bit 10
                   023A4A  compute + write output pitch offset to 0x0451DA (portamento off)
                   023A70  portamento down: add detune offset
                   023A76  apply portamento output + store 0x0451DA
                   023A83  store 0x0451DA and return
                   023A8E  copy base pitch word to voice output (0451DA)
                   023A99  compute secondary pitch output (portamento off variant)
                   023ABF  secondary portamento down
                   023AC5  store secondary pitch output

  023AD0-023CCF  Output level (amplitude) computation
                   023AD0  compute output level triplet (main + 2 side channels)
                   023B09  level components positive: load as-is
                   023B21  modulate level by envelope amount
                   023B60  level ch-1 unmodulated base
                   023B74  level ch-2 modulated by envelope
                   023B94  level ch-2 unmodulated base
                   023BA8  level ch-3 modulated by envelope
                   023BC6  level ch-3 unmodulated base
                   023BDC  all three level components unmodulated
                   023C18  apply velocity modulation to level (mod depth != 0)
                   023C3C  clamp and pack level into DSP output registers
                   023CAA  clamp without velocity mod
                   023CC6  pack side-channel levels into 0x0451EE / 0x0451F0

  023D01-024101  Pitch parameter pack routines (mode-indexed dispatch)
                   023D01  compute pitch param pack: mode 1 (standard, no detune)
                   023D8D  mode 1 alt: use voice table LUT for detune correction
                   023DB1  return from pitch param pack mode 1
                   023DB5  compute pitch param pack: mode 2 (detune negative)
                   023E44  mode 2 alt path
                   023EBE  return from pitch param pack mode 2
                   023EC2  compute pitch param pack: mode 3 (detune positive)
                   023F4E  mode 3 alt path (no 9-bit flag)
                   023FB9  return from pitch param pack mode 3
                   023FBD  compute single-channel pitch param pack (mode 4)
                   023FDE  mode 4 alt path
                   023FF0  finalize pitch pack and write voice regs
                   02403D  compute dual-channel pitch param pack (mode 5)
                   024069  mode 5: apply detune offset to both channels
                   024097  finalize dual-channel pitch pack

  024102-02412D  Pitch param dispatch (field[23]+5 selects mode 0-5)
                   024102  dispatch pitch param pack by algo mode (0-5)
                   02412B  jump table targets for modes 0-5

  02413E-0242A1  Pitch param pack with simple channel routing
                   02413E  compute pitch pack mode A (two regs, positive routing)
                   0241A0  compute pitch pack mode B (two regs, negative routing)
                   024205  compute pitch pack mode C (single reg, dual-encoded)
                   024250  compute pitch pack mode D (single reg, negative flag)
                   0242A1  compute pitch pack mode E (two regs, split source)

  024300-024363  Pitch register write dispatch (field[23]+15 selects mode 0-5)
                   024300  dispatch pitch register write by algo mode
                   02432C  jump table targets + write 0x0451D4/D6

  024364-024442  Pan register write helpers
                   024364  return from pitch write dispatch
                   024366  write pan with detune apply (positive/negative/fixed)
                   024394  pan detune positive branch
                   0243A7  clamp + write pan register 0x0451D4
                   0243BA  write pan register 0x0451D4 as-is
                   0243C2  write pan register 0x0451D6 and return
                   0243CC  write both pan regs with symmetric detune
                   0243FA  symmetric detune positive branch
                   02440D  clamp + write both pan registers
                   024432  write both pan registers as-is

  024444-024551  Pan write dispatch (field[23]+54 selects mode 0-5)
                   024444  dispatch pan register write by algo mode
                   024472  jump table targets for modes 0-5
                   0244A0  mode 2: check 9-bit flag
                   0244F0  mode 5: detune positive branch
                   024517  finalize mode 5 pan with clamp + write
                   024540  mode 5 (fixed): write pan regs as-is
                   024550  return from pan write dispatch

  024554-024661  Pan write dispatch variant B (field[23]+15 selects mode 0-5)
                   024554  dispatch pan register write variant B by algo mode
                   024582  jump table targets for modes 0-5 (variant B)
                   0245B0  mode 2 variant B: check 9-bit flag
                   024600  mode 5 variant B: detune positive branch
                   024627  finalize mode 5 variant B pan with clamp + write
                   024650  mode 5 variant B (fixed): write pan regs as-is
                   024660  return from pan write dispatch variant B

  024664-024A58  Stereo level / balance computation
                   024664  compute stereo level triplet (L/R/centre) with LFO mod
                   0246BC  stereo level ch-1 unmodulated
                   0246D3  stereo level ch-2 modulated
                   0246F9  stereo level ch-2 unmodulated
                   024710  stereo level ch-3 modulated
                   024734  stereo level ch-3 unmodulated
                   02474D  all three stereo level channels unmodulated
                   024792  apply LFO tremolo to level (depth != 0)
                   0247BF  clamp ch-1, compute portamento scale, write 0x0451F2
                   02484C  clamp ch-2/3 without LFO mod
                   024868  pack and write ch-2/3 to 0x0451F4 / 0x0451F6

  0248D5-024A58  Envelope / portamento level computation
                   0248D5  compute portamento level + vibrato blend → 0x0451E2/EA
                   024911  portamento direction positive: use level as-is
                   02492D  scale portamento amount, pack two bytes → 0x0451E2
                   0249BF  clear all output level registers for voice

  024A59-024BC2  Voice operator parameter write (core slot patcher)
                   024A59  write operator params to voice slot buffer (6 bytes)
                   024B5E  copy operator params without global offset
                   024B7B  apply sustain-pedal override to operator flags
                   024B91  set operator flag 2 = 0x80 (sustain release)
                   024B95  apply sostenuto-pedal override to operator flags
                   024BAB  set operator flag 4 = 0x80 (sostenuto release)
                   024BAF  copy waveform bits from operator params
                   024BBB  clear waveform select bit 5
                   024BBD  pack envelope type bits and write operator byte 0

  024BE3-024F40  Voice channel params + pitch note trigger
                   024BE3  compute voice channel parameters (pitch/volume/algo)
                   024C81  channel param compute path (no algo-select flag)
                   024CAB  resolve voice slot from algo index, write slot byte 6
                   024CF9  write operator params to all 4 voice slots
                   024D31  check pitch envelope gate / algo flag
                   024D42  check pitch envelope bit 5 for sustain
                   024D46  reset pitch envelope and trigger via LABEL_02DA96
                   024D65  check if pitch envelope is free-running
                   024D73  check envelope mode bits before triggering
                   024D96  voice has choke group: trigger envelope via LABEL_02DA96
                   024DBE  fallback: no active wave table entry
                   024E44  write precomputed pitch/vol params + trigger via 0x2DA16

  024E66-024F3F  Secondary pitch note trigger path
                   024E66  secondary pitch trigger (right-channel / algo-1 path)
                   024EEA  compute right-channel pitch delta + trigger LABEL_02DB33
                   024F3C  return from voice channel param computation

  024F41-024FFF  SubCPU operator note trigger (SubVoice)
                   024F41  compute SubVoice operator parameters and trigger note
                   024FD4  SubVoice compute path (no algo-select flag)
                   024FFF  resolve SubVoice slot, write slot byte 6

Uses binary I/O to handle encoding safely.
"""

import os
import re

# Renames: (old_label, new_label, brief_comment)
RENAMES = [
    # --- 023000 range: pitch / frequency output registers ---

    # 02300E is an opaque .byte block (undecodable instructions at analysis time);
    # give it a descriptive stub name so it is findable but clearly provisional.
    ('LABEL_02300E', 'Voice_Freq_ComputeLeft_Raw',
     'Opaque .byte block: compute left-channel frequency word variant'),

    ('LABEL_023043', 'Voice_Freq_WriteLeft',
     'Compute frequency + write left-channel DSP register 0x045204'),

    ('LABEL_0230AD', 'Voice_Freq_WriteLeft_Clamp',
     'Clamp left frequency to 0x1FFF range before storing'),

    ('LABEL_0230BD', 'Voice_Freq_WriteLeft_Store',
     'Merge frequency index bits and write left-channel word to 0x045204'),

    ('LABEL_0230DE', 'Voice_Freq_WriteLeft_HiRange',
     'High-range (>= 0x40) variant: compute frequency and write 0x04520E'),

    ('LABEL_02312C', 'Voice_Freq_WriteLeft_HiRange_Clamp',
     'Clamp high-range left frequency to 0x1FFF'),

    ('LABEL_02313C', 'Voice_Freq_WriteLeft_HiRange_Store',
     'Merge and write high-range left frequency to 0x04520E'),

    ('LABEL_02315B', 'Voice_Freq_WriteLeft_Return',
     'Restore xiz and return from frequency write'),

    ('LABEL_02315F', 'Voice_Freq_WriteRight',
     'Compute frequency + write right-channel level to DSP reg 0x045206'),

    ('LABEL_0231AF', 'Voice_Freq_WriteRight_FlagSet',
     'Right-channel frequency: set bit 15 if voice flag bit 5 set'),

    ('LABEL_0231BD', 'Voice_Freq_WriteRight_Store',
     'Write right-channel frequency word to 0x045206'),

    ('LABEL_0231C4', 'Voice_Freq_WriteRight_HiRange',
     'High-range right-channel frequency clamp path'),

    ('LABEL_0231D1', 'Voice_Freq_WriteRight_HiRange_Store',
     'Write high-range right-channel frequency to 0x04520A'),

    ('LABEL_0231D6', 'Voice_Freq_WriteRight_Return',
     'Restore xiz and return from right-channel frequency write'),

    # 0231DA is another opaque .byte block
    ('LABEL_0231DA', 'Voice_Freq_ComputeRight_Raw',
     'Opaque .byte block: compute right-channel frequency word variant'),

    # --- 023200 range: timbre / colour helpers ---

    ('LABEL_02324E', 'Voice_Colour_LookupIndex',
     'Map timbre byte → colour index word in HL via DRAM table 0x106E4'),

    ('LABEL_023279', 'Voice_Colour_ClampUpper',
     'Clamp colour value to upper pan/timbre bound'),

    ('LABEL_023290', 'Voice_Colour_ClampLower',
     'Clamp colour value to lower pan/timbre bound'),

    ('LABEL_02329C', 'Voice_Colour_InterpolateDelta',
     'Interpolate colour delta between bounds → HL'),

    ('LABEL_0232B3', 'Voice_Clamp_Byte_WA',
     'Clamp signed WA to [0, 0xFF] → WA (generic helper)'),

    ('LABEL_0232BE', 'Voice_Clamp_Byte_WA_LowBound',
     'Lower-bound clamp for Voice_Clamp_Byte_WA'),

    ('LABEL_0232C4', 'Voice_Clamp_Byte_WA_Return',
     'Copy WA to HL and return'),

    ('LABEL_0232C7', 'Voice_Colour_Write',
     'Compute combined colour/pan word and write to DSP reg 0x0451D0'),

    ('LABEL_023309', 'Voice_Colour_Write_NoPanOverride',
     'Use voice pan field (offset +6) when pan-override flag is clear'),

    ('LABEL_02331C', 'Voice_Colour_Write_Store',
     'Set bit 15, merge pan into colour word, write 0x0451D0'),

    ('LABEL_023328', 'Voice_Clamp_Byte_HL',
     'Clamp signed WA to [0, 0xFF] → HL (duplicate variant)'),

    ('LABEL_023335', 'Voice_Clamp_Byte_HL_LowBound',
     'Lower-bound clamp for Voice_Clamp_Byte_HL'),

    ('LABEL_02333B', 'Voice_Clamp_Byte_HL_Return',
     'Copy WA to HL and return'),

    # --- 02333E range: envelope velocity triggers ---

    ('LABEL_02333E', 'Voice_Env_UpdateVelocityCounters',
     'Update envelope velocity/release counters for voice (called from Voice_SetVelocity)'),

    ('LABEL_023391', 'Voice_Env_UpdateVelocity_SetPhase1',
     'Counter just reached 1: write phase flag 0x10 to envelope state byte'),

    ('LABEL_0233A6', 'Voice_Env_UpdateVelocity_SetPhase2',
     'Counter reached 2: write phase flag 0x20 to envelope state byte'),

    ('LABEL_0233BB', 'Voice_Env_UpdateVelocity_Reset',
     'Counter overflow (>= 0x19): reset phase counter and flag to 0'),

    ('LABEL_0233E1', 'Voice_Env_UpdateVelocity_Store',
     'Store updated counter value back to envelope state table'),

    ('LABEL_0233F8', 'Voice_Env_ApplyVelocity_Type0',
     'Apply velocity parameter to DSP envelope for type-0 voice (c = part index)'),

    ('LABEL_02341F', 'Voice_Env_VelocityDispatch_c1',
     'Velocity dispatch for type-0 voice, c=1: check trigger bit 3'),

    ('LABEL_02343C', 'Voice_Env_VelocityDispatch_c0_NoBit3',
     'Velocity dispatch c=0, bit 3 clear: fetch base level, call Note_Attack_S1'),

    ('LABEL_023448', 'Voice_Env_VelocityDispatch_c1_Bit1',
     'Velocity dispatch c=1: check trigger bit 3 (variant)'),

    ('LABEL_023453', 'Voice_Env_VelocityDispatch_c1_NoBit3',
     'Velocity dispatch c=1, bit 3 clear: call Note_Attack_S2'),

    ('LABEL_02345F', 'Voice_Env_VelocityDispatch_c2',
     'Velocity dispatch c=2: check trigger bit 3 in voice flags'),

    ('LABEL_023477', 'Voice_Env_VelocityDispatch_c2_Trigger',
     'Velocity dispatch c=2: fetch velocity address and trigger attack'),

    ('LABEL_023490', 'Voice_Env_VelocityDispatch_c3',
     'Velocity dispatch c=3: check trigger bit 3 in voice flags'),

    ('LABEL_0234A8', 'Voice_Env_VelocityDispatch_c3_Trigger',
     'Velocity dispatch c=3: fetch velocity address and trigger attack'),

    ('LABEL_0234C1', 'Voice_Env_VelocityDispatch_ClearFlag',
     'Clear return flag l=0 (no-match path)'),

    ('LABEL_0234C3', 'Voice_Env_VelocityDispatch_Gate',
     'Gate: if flag set call LABEL_02289D (velocity envelope arm)'),

    ('LABEL_0234D2', 'Voice_Env_ApplyVelocity_Type2',
     'Apply velocity to type-2 voice envelope (c = part sub-index)'),

    ('LABEL_0234EF', 'Voice_Env_Type2_c0_NoBit4',
     'Type-2 dispatch c=0, bit 4 clear: call Note_Attack_S1'),

    ('LABEL_0234FB', 'Voice_Env_Type2_c1',
     'Type-2 velocity dispatch c=1: check trigger bit 4'),

    ('LABEL_023506', 'Voice_Env_Type2_c1_NoBit4',
     'Type-2 c=1, bit 4 clear: call Note_Attack_S2'),

    ('LABEL_023512', 'Voice_Env_Type2_c2',
     'Type-2 velocity dispatch c=2: check trigger bit 4 in voice flags'),

    ('LABEL_02352A', 'Voice_Env_Type2_c2_Trigger',
     'Type-2 c=2: fetch velocity address and trigger attack'),

    ('LABEL_023543', 'Voice_Env_Type2_c3',
     'Type-2 velocity dispatch c=3: check trigger bit 4 in voice flags'),

    ('LABEL_02355B', 'Voice_Env_Type2_c3_Trigger',
     'Type-2 c=3: fetch velocity address and trigger attack'),

    ('LABEL_023574', 'Voice_Env_Type2_ClearFlag',
     'Clear return flag l=0 (type-2 no-match path)'),

    ('LABEL_023576', 'Voice_Env_Type2_Gate',
     'Gate: if flag set call LABEL_0228D9 (type-2 velocity envelope arm)'),

    ('LABEL_023581', 'Voice_Env_ApplyVelocity_Return',
     'Restore stack and return from velocity apply'),

    # --- 023584 range: pitch computation with detune/vibrato/portamento ---

    ('LABEL_023584', 'Voice_Pitch_Compute',
     'Compute final pitch word including detune, bend, vibrato for voice'),

    ('LABEL_023637', 'Voice_Pitch_BendType_Octave',
     'Pitch bend type 0x80: compute octave shift from semitone field'),

    ('LABEL_023658', 'Voice_Pitch_BendType_Fixed',
     'Pitch bend type 0x40: add fixed offset 267110 to pitch'),

    ('LABEL_023660', 'Voice_Pitch_BendType_TableA',
     'Pitch bend type 0x41: add scaled entry from table 0x00FCE4'),

    ('LABEL_02367C', 'Voice_Pitch_BendType_TableB',
     'Pitch bend type 0x42: add scaled entry from table 0x00FDE4'),

    ('LABEL_023698', 'Voice_Pitch_Compute_Inactive',
     'Non-active voice: load base pitch from voice slot, apply bend type'),

    ('LABEL_0236CB', 'Voice_Pitch_Inactive_BendType_Fixed',
     'Inactive voice bend type 0x40: add fixed offset'),

    ('LABEL_0236D2', 'Voice_Pitch_Inactive_BendType_TableA',
     'Inactive voice bend type 0x41: add scaled entry from table 0x00FCE4'),

    ('LABEL_0236ED', 'Voice_Pitch_Inactive_BendType_TableB',
     'Inactive voice bend type 0x42: add scaled entry from table 0x00FDE4'),

    ('LABEL_023708', 'Voice_Pitch_Inactive_BendType_Chromatic',
     'Inactive voice bend type 0x42+: chromatic table lookup at 0x011B68'),

    ('LABEL_023738', 'Voice_Pitch_ApplyPortamento',
     'Apply portamento scaling, store pitch word at voice+8, then compute output'),

    ('LABEL_023774', 'Voice_Pitch_Portamento_Off_AddOffset',
     'Portamento mode off: add legato table offset to pitch'),

    ('LABEL_02377E', 'Voice_Pitch_Portamento_Mode7_Direct',
     'Portamento mode 7: load direct legato pitch from voice legato table'),

    ('LABEL_023786', 'Voice_Pitch_Portamento_Active_SubBias',
     'Portamento active: subtract centre bias 0x4280 before scaling'),

    ('LABEL_023797', 'Voice_Pitch_Portamento_Active_AddBias',
     'Portamento active: add centre bias 0x4280 back after scaling'),

    ('LABEL_02379D', 'Voice_Pitch_Portamento_Active_SetFixed',
     'Portamento active mode 7: set fixed pitch to 0x4280'),

    ('LABEL_0237A0', 'Voice_Pitch_ApplyFineTune',
     'Add coarse/fine tune offsets from voice block, compute final pitch word'),

    ('LABEL_0237E5', 'Voice_Pitch_ApplyFineTune_LegatoB',
     'Apply fine tune then compute legato pitch (variant B via LABEL_02299D)'),

    ('LABEL_023804', 'Voice_Pitch_Compute_Return',
     'Store pitch result at voice+6, return from pitch computation'),

    ('LABEL_023809', 'Voice_Pitch_CopyBase',
     'Copy base pitch from legato table, apply ADSR pitch envelope'),

    # --- 023849 range: pitch interpolation dispatch ---

    ('LABEL_023849', 'Voice_Pitch_InterpDispatch',
     'Dispatch pitch interpolation variant by voice flag bits 5, 6, 7'),

    ('LABEL_0238AC', 'Voice_Pitch_Interp_Bits56',
     'Pitch interpolation variant: bits 5 and 6 both set'),

    ('LABEL_0238B9', 'Voice_Pitch_Interp_Bit7_NoB5',
     'Pitch interpolation variant: bit 7 set, bit 5 clear'),

    ('LABEL_0238CA', 'Voice_Pitch_Interp_Bits67',
     'Pitch interpolation variant: bits 6 and 7, no bit 5'),

    ('LABEL_0238D7', 'Voice_Pitch_Interp_Bit7_NoB6',
     'Pitch interpolation variant: bit 7 set, bit 6 clear'),

    ('LABEL_0238E8', 'Voice_Pitch_Interp_Base',
     'Base pitch interpolation path (no special flags)'),

    ('LABEL_0238F3', 'Voice_Pitch_InterpDispatch_Return',
     'Return from pitch interpolation dispatch'),

    # --- 0238F8 range: pitch envelope state machine ---

    ('LABEL_0238F8', 'Voice_PitchEnv_Advance',
     'Advance pitch envelope state machine; resolve operator pointer offset'),

    ('LABEL_023942', 'Voice_PitchEnv_Advance_StateB',
     'Pitch envelope state 1..2: look up interpolation via table B (LABEL_02B1E0)'),

    ('LABEL_023979', 'Voice_PitchEnv_Advance_RoutingTable',
     'Pitch envelope state >= 3: fetch interpolation from routing table entry'),

    ('LABEL_02399D', 'Voice_PitchEnv_StoreOutputRegs',
     'Store pitch envelope result into 0x0451CE and 0x0451AE'),

    ('LABEL_0239DD', 'Voice_PitchEnv_StoreOutputRegs_Return',
     'Return from pitch envelope output register store'),

    # --- 0239E1: volume scale helper ---

    ('LABEL_0239E1', 'Voice_Vol_ScaleVelocityWord',
     'Scale velocity DRAM word by 0x0D/128, write result to 0x041366'),

    # --- 023A05 range: pitch output register writes ---

    ('LABEL_023A05', 'Voice_Pitch_WriteOutputReg_Portamento',
     'Compute output pitch offset with portamento correction, write to 0x0451DA'),

    ('LABEL_023A44', 'Voice_Pitch_WriteOutputReg_Portamento_ClearBit',
     'Clear portamento flag bit 10 in voice word and return'),

    ('LABEL_023A4A', 'Voice_Pitch_WriteOutputReg_Legato',
     'Compute output pitch offset (legato/detune path), write to 0x0451DA'),

    ('LABEL_023A70', 'Voice_Pitch_Legato_DetuneDown',
     'Legato detune: subtract detune offset (downward)'),

    ('LABEL_023A76', 'Voice_Pitch_Legato_StoreOutput',
     'Apply portamento scaling and store final value to 0x0451DA'),

    ('LABEL_023A83', 'Voice_Pitch_Legato_StoreOutput_Return',
     'Store HL to 0x0451DA and return'),

    ('LABEL_023A8E', 'Voice_Pitch_WriteOutputReg_Direct',
     'Copy base pitch word directly to voice output register (no portamento)'),

    ('LABEL_023A99', 'Voice_Pitch_WriteOutputReg_Secondary',
     'Compute secondary pitch offset (right/secondary channel path)'),

    ('LABEL_023ABF', 'Voice_Pitch_Secondary_DetuneDown',
     'Secondary channel pitch: subtract detune offset (downward)'),

    ('LABEL_023AC5', 'Voice_Pitch_Secondary_StoreOutput',
     'Apply portamento scaling and store secondary pitch to 0x0451DA'),

    # --- 023AD0 range: output amplitude computation ---

    ('LABEL_023AD0', 'Voice_Level_ComputeTriplet',
     'Compute output level triplet (main + 2 side) from voice block envelope'),

    ('LABEL_023B09', 'Voice_Level_Triplet_Positive',
     'Envelope direction positive: load level components as-is'),

    ('LABEL_023B21', 'Voice_Level_Triplet_ModByEnv',
     'Modulate level triplet by envelope amount (non-zero env depth)'),

    ('LABEL_023B60', 'Voice_Level_Ch1_Unmodulated',
     'Level ch-1 base: no envelope modulation, store direct'),

    ('LABEL_023B74', 'Voice_Level_Ch2_Modulated',
     'Level ch-2: envelope-modulated offset + base'),

    ('LABEL_023B94', 'Voice_Level_Ch2_Unmodulated',
     'Level ch-2 base: no envelope modulation, store direct'),

    ('LABEL_023BA8', 'Voice_Level_Ch3_Modulated',
     'Level ch-3: envelope-modulated offset + base'),

    ('LABEL_023BC6', 'Voice_Level_Ch3_Unmodulated',
     'Level ch-3 base: no envelope modulation, store direct'),

    ('LABEL_023BDC', 'Voice_Level_Triplet_Unmodulated',
     'Zero envelope depth: load all three level components unmodulated'),

    ('LABEL_023C18', 'Voice_Level_ApplyVelocityMod',
     'Apply LFO velocity modulation to level (mod depth != 0)'),

    ('LABEL_023C3C', 'Voice_Level_PackAndStore',
     'Clamp level, apply fine tune, pack byte pair, write 0x0451EC'),

    ('LABEL_023CAA', 'Voice_Level_PackAndStore_NoVelocityMod',
     'Clamp without velocity mod, pack and write 0x0451EC'),

    ('LABEL_023CC6', 'Voice_Level_PackSideChannels',
     'Scale and pack side-channel levels, write 0x0451EE / 0x0451F0'),

    # --- 023D01 range: pitch parameter pack routines ---

    ('LABEL_023D01', 'Voice_PitchPack_Mode1',
     'Compute pitch parameter pack mode 1 (standard, positive detune)'),

    ('LABEL_023D8D', 'Voice_PitchPack_Mode1_UseVoiceLUT',
     'Mode 1 alt: use voice LUT for detune correction'),

    ('LABEL_023DB1', 'Voice_PitchPack_Mode1_Return',
     'Return from pitch param pack mode 1'),

    ('LABEL_023DB5', 'Voice_PitchPack_Mode2',
     'Compute pitch parameter pack mode 2 (detune negative, set bit 7)'),

    ('LABEL_023E44', 'Voice_PitchPack_Mode2_AltPath',
     'Mode 2 alt path (bit 9 of algo flags clear)'),

    ('LABEL_023EBE', 'Voice_PitchPack_Mode2_Return',
     'Return from pitch param pack mode 2'),

    ('LABEL_023EC2', 'Voice_PitchPack_Mode3',
     'Compute pitch parameter pack mode 3 (detune positive, set bit 7)'),

    ('LABEL_023F4E', 'Voice_PitchPack_Mode3_AltPath',
     'Mode 3 alt path (no 9-bit flag): encode dual bit fields'),

    ('LABEL_023FB9', 'Voice_PitchPack_Mode3_Return',
     'Return from pitch param pack mode 3'),

    ('LABEL_023FBD', 'Voice_PitchPack_Mode4_Single',
     'Compute single-channel pitch param pack (mode 4)'),

    ('LABEL_023FDE', 'Voice_PitchPack_Mode4_AltPath',
     'Mode 4 alt path: add algo detune offset'),

    ('LABEL_023FF0', 'Voice_PitchPack_Mode4_Finalize',
     'Finalize mode 4 pitch pack and write voice registers (+66/+68)'),

    ('LABEL_02403D', 'Voice_PitchPack_Mode5_Dual',
     'Compute dual-channel pitch parameter pack (mode 5)'),

    ('LABEL_024069', 'Voice_PitchPack_Mode5_ApplyDetune',
     'Mode 5: apply algo detune to both channel pitch values'),

    ('LABEL_024097', 'Voice_PitchPack_Mode5_Finalize',
     'Finalize mode 5 dual-channel pitch pack: scale, pack, write regs'),

    # --- 024102 range: pitch param dispatch ---

    ('LABEL_024102', 'Voice_PitchPack_Dispatch',
     'Dispatch pitch parameter pack routine by algo mode (0-5 from voice[23]+5)'),

    ('LABEL_02412B', 'Voice_PitchPack_Dispatch_Table',
     'Jump table for pitch pack modes 0-5 (jrl/calr targets)'),

    # --- 02413E range: pitch pack with simple channel routing ---

    ('LABEL_02413E', 'Voice_PitchPack_RouteA',
     'Compute pitch pack mode A: two output regs, positive routing'),

    ('LABEL_0241A0', 'Voice_PitchPack_RouteB',
     'Compute pitch pack mode B: two output regs, negative routing (set bit 7)'),

    ('LABEL_024205', 'Voice_PitchPack_RouteC',
     'Compute pitch pack mode C: single reg, dual-encoded (sll 10 + sll 13)'),

    ('LABEL_024250', 'Voice_PitchPack_RouteD',
     'Compute pitch pack mode D: single reg, negative flag (set bit 7)'),

    ('LABEL_0242A1', 'Voice_PitchPack_RouteE',
     'Compute pitch pack mode E: two output regs, split source (ch1 + ch2 separate)'),

    # --- 024300 range: pitch register write dispatch ---

    ('LABEL_024300', 'Voice_PitchReg_WriteDispatch',
     'Dispatch pitch register write by algo mode (0-5 from voice[23]+15)'),

    ('LABEL_02432C', 'Voice_PitchReg_WriteDispatch_Table',
     'Jump table for pitch reg write modes 0-5 + write 0x0451D4/D6'),

    ('LABEL_024364', 'Voice_PitchReg_WriteDispatch_Return',
     'Return from pitch register write dispatch'),

    # --- 024366 range: pan register write helpers ---

    ('LABEL_024366', 'Voice_Pan_WriteWithDetune',
     'Write pan register 0x0451D4 with detune applied (pos/neg/fixed by flags)'),

    ('LABEL_024394', 'Voice_Pan_WriteWithDetune_Positive',
     'Pan detune positive branch: add detune offset to base pan value'),

    ('LABEL_0243A7', 'Voice_Pan_WriteWithDetune_Clamp',
     'Clamp detune result to [0, 0x78] and write 0x0451D4'),

    ('LABEL_0243BA', 'Voice_Pan_Write_AsIs',
     'Write pan register 0x0451D4 as-is (no detune applied)'),

    ('LABEL_0243C2', 'Voice_Pan_WriteSecondary',
     'Write secondary pan register 0x0451D6 and return'),

    ('LABEL_0243CC', 'Voice_Pan_WriteBothWithDetune',
     'Write both pan regs 0x0451D4/D6 with symmetric detune'),

    ('LABEL_0243FA', 'Voice_Pan_WriteBoth_Positive',
     'Both-pan detune positive branch: add offset to both values'),

    ('LABEL_02440D', 'Voice_Pan_WriteBoth_Clamp',
     'Clamp both pan values and write 0x0451D4 / 0x0451D6'),

    ('LABEL_024432', 'Voice_Pan_WriteBoth_AsIs',
     'Write both pan registers as-is (no detune)'),

    ('LABEL_024442', 'Voice_Pan_WriteBoth_Return',
     'Return from both-pan write'),

    # --- 024444 range: pan write dispatch (mode 0-5) ---

    ('LABEL_024444', 'Voice_PanReg_WriteDispatch',
     'Dispatch pan register write by algo mode (0-5 from voice[23]+54)'),

    ('LABEL_024472', 'Voice_PanReg_WriteDispatch_Table',
     'Jump table for pan write modes 0-5'),

    ('LABEL_0244A0', 'Voice_PanReg_Dispatch_Mode2_CheckBit9',
     'Pan write mode 2: check bit 9 of algo flags to select pan variant'),

    ('LABEL_0244F0', 'Voice_PanReg_Dispatch_Mode5_Positive',
     'Pan write mode 5 positive detune: add detune offset to both channels'),

    ('LABEL_024517', 'Voice_PanReg_Dispatch_Mode5_Finalize',
     'Mode 5 pan: clamp both values and write 0x0451D4/D6'),

    ('LABEL_024540', 'Voice_PanReg_Dispatch_Mode5_AsIs',
     'Mode 5 pan (fixed, no detune): write both regs as-is'),

    ('LABEL_024550', 'Voice_PanReg_WriteDispatch_Return',
     'Return from pan register write dispatch'),

    # --- 024554 range: pan write dispatch variant B ---

    ('LABEL_024554', 'Voice_PanReg_WriteDispatchB',
     'Dispatch pan register write variant B by algo mode (voice[23]+15)'),

    ('LABEL_024582', 'Voice_PanReg_WriteDispatchB_Table',
     'Jump table for pan write modes 0-5 (variant B)'),

    ('LABEL_0245B0', 'Voice_PanReg_DispatchB_Mode2_CheckBit9',
     'Pan write B mode 2: check bit 9 of algo flags'),

    ('LABEL_024600', 'Voice_PanReg_DispatchB_Mode5_Positive',
     'Pan write B mode 5 positive: add detune offset'),

    ('LABEL_024627', 'Voice_PanReg_DispatchB_Mode5_Finalize',
     'Mode 5 B pan: clamp and write 0x0451D4/D6'),

    ('LABEL_024650', 'Voice_PanReg_DispatchB_Mode5_AsIs',
     'Mode 5 B pan (no detune): write both regs as-is'),

    ('LABEL_024660', 'Voice_PanReg_WriteDispatchB_Return',
     'Return from pan register write dispatch variant B'),

    # --- 024664 range: stereo level triplet computation ---

    ('LABEL_024664', 'Voice_StereoLevel_Compute',
     'Compute stereo level triplet (L/R/centre) with LFO tremolo modulation'),

    ('LABEL_0246BC', 'Voice_StereoLevel_Ch1_Unmodulated',
     'Stereo level ch-1: no LFO mod, store direct'),

    ('LABEL_0246D3', 'Voice_StereoLevel_Ch2_Modulated',
     'Stereo level ch-2: LFO-modulated offset + base'),

    ('LABEL_0246F9', 'Voice_StereoLevel_Ch2_Unmodulated',
     'Stereo level ch-2: no mod, store direct'),

    ('LABEL_024710', 'Voice_StereoLevel_Ch3_Modulated',
     'Stereo level ch-3: LFO-modulated offset + base'),

    ('LABEL_024734', 'Voice_StereoLevel_Ch3_Unmodulated',
     'Stereo level ch-3: no mod, store direct'),

    ('LABEL_02474D', 'Voice_StereoLevel_AllUnmodulated',
     'All three stereo level channels without LFO modulation'),

    ('LABEL_024792', 'Voice_StereoLevel_ApplyTremolo',
     'Apply LFO tremolo depth to level ch-1 (depth != 0)'),

    ('LABEL_0247BF', 'Voice_StereoLevel_PackCh1',
     'Clamp ch-1, compute portamento scale, pack and write 0x0451F2'),

    ('LABEL_02484C', 'Voice_StereoLevel_ClampCh23_NoMod',
     'Clamp ch-2/3 without LFO modulation'),

    ('LABEL_024868', 'Voice_StereoLevel_PackCh23',
     'Pack and write stereo ch-2/3 to 0x0451F4 / 0x0451F6'),

    # --- 0248D5 range: portamento level + vibrato blend ---

    ('LABEL_0248D5', 'Voice_PortaLevel_Compute',
     'Compute portamento level + vibrato blend, write 0x0451E2 / 0x0451EA'),

    ('LABEL_024911', 'Voice_PortaLevel_Compute_Positive',
     'Portamento direction positive: use level fields as-is'),

    ('LABEL_02492D', 'Voice_PortaLevel_ScaleAndPack',
     'Scale portamento amount by velocity, pack two bytes, write 0x0451E2'),

    # --- 0249BF: clear output level registers ---

    ('LABEL_0249BF', 'Voice_Level_ClearAllOutputRegs',
     'Clear all voice output level registers (0x0451E0..F6 and 0x0451DC/DE)'),

    ('LABEL_024A25', 'Voice_Level_ClearAllOutputRegs_Check2',
     'Level clear: check if voice slot mode == 2 (set 0x7F)'),

    ('LABEL_024A42', 'Voice_Level_ClearAllOutputRegs_FromTable',
     'Level clear: read level from voice table entry'),

    ('LABEL_024A49', 'Voice_Level_ClearAllOutputRegs_Store',
     'Store resolved level to 0x0451D8 and clear 0x0451E0'),

    # --- 024A59 range: operator slot parameter patcher ---

    ('LABEL_024A59', 'Voice_OpSlot_WriteParams',
     'Write 6 operator-slot bytes into voice slot buffer (with global offset)'),

    ('LABEL_024B5E', 'Voice_OpSlot_WriteParams_Direct',
     'Write operator-slot params without global offset adjustment'),

    ('LABEL_024B7B', 'Voice_OpSlot_ApplySustainPedal',
     'Apply sustain-pedal override to operator flag byte 2'),

    ('LABEL_024B91', 'Voice_OpSlot_SustainRelease_Set',
     'Sustain pedal held: set operator flag 2 = 0x80 (release mode)'),

    ('LABEL_024B95', 'Voice_OpSlot_ApplySostenuto',
     'Apply sostenuto-pedal override to operator flag byte 4'),

    ('LABEL_024BAB', 'Voice_OpSlot_SostenutoRelease_Set',
     'Sostenuto pedal held: set operator flag 4 = 0x80'),

    ('LABEL_024BAF', 'Voice_OpSlot_CopyWaveformBits',
     'Copy waveform select bits from operator data into slot flags byte'),

    ('LABEL_024BBB', 'Voice_OpSlot_ClearWaveformBit5',
     'Clear waveform select bit 5 in slot flags'),

    ('LABEL_024BBD', 'Voice_OpSlot_PackEnvelopeBits',
     'Pack envelope type bits (from operator byte 3) and write operator byte 0'),

    # --- 024BE3 range: voice channel parameter computation + note trigger ---

    ('LABEL_024BE3', 'Voice_Chan_ComputeParams',
     'Compute voice channel parameters (pitch/vol/algo) and trigger note'),

    ('LABEL_024C81', 'Voice_Chan_ComputeParams_NoAlgoSelect',
     'Channel param compute path when algo-select flag is not set'),

    ('LABEL_024CAB', 'Voice_Chan_ResolveSlot',
     'Resolve voice slot from algo index via DRAM, write slot byte 6'),

    ('LABEL_024CF9', 'Voice_Chan_WriteOpSlots',
     'Write operator params to all 4 voice slots via Voice_OpSlot_WriteParams'),

    ('LABEL_024D31', 'Voice_Chan_CheckPitchEnvGate',
     'Check pitch envelope gate and algo flag for auto-trigger'),

    ('LABEL_024D42', 'Voice_Chan_PitchEnvGate_CheckBit5',
     'Check pitch envelope sustain bit 5 for trigger eligibility'),

    ('LABEL_024D46', 'Voice_Chan_PitchEnvGate_Trigger',
     'Reset pitch envelope and trigger via LABEL_02DA96'),

    ('LABEL_024D65', 'Voice_Chan_PitchEnvFreeRun_Check',
     'Check if pitch envelope is free-running (bit 5 clear, flags clear)'),

    ('LABEL_024D73', 'Voice_Chan_PitchEnvFreeRun_Trigger',
     'Free-run pitch envelope: compute output pitch and trigger via LABEL_02DA96'),

    ('LABEL_024D96', 'Voice_Chan_ChokeGroup_Trigger',
     'Voice has choke group: trigger pitch envelope via LABEL_02DA96'),

    ('LABEL_024DBE', 'Voice_Chan_Fallback_NoWaveTable',
     'Fallback: no active wave-table entry (algo flags bit 15 check)'),

    ('LABEL_024E44', 'Voice_Chan_Fallback_WritePrecomputed',
     'Write precomputed pitch/vol params and trigger via call 0x2DA16'),

    # --- 024E66 range: secondary pitch trigger ---

    ('LABEL_024E66', 'Voice_Chan_SecondaryPitch_Trigger',
     'Secondary pitch trigger (right-channel / algo-1 path)'),

    ('LABEL_024EEA', 'Voice_Chan_SecondaryPitch_ComputeDelta',
     'Compute right-channel pitch delta + trigger via LABEL_02DB33'),

    ('LABEL_024F3C', 'Voice_Chan_ComputeParams_Return',
     'Return from voice channel parameter computation'),

    # --- 024F41 range: SubVoice operator note trigger ---

    ('LABEL_024F41', 'Voice_SubVoice_ComputeAndTrigger',
     'Compute SubVoice operator parameters and trigger note'),

    ('LABEL_024FD4', 'Voice_SubVoice_Compute_NoAlgoSelect',
     'SubVoice compute path when algo-select flag is not set'),

    ('LABEL_024FFF', 'Voice_SubVoice_ResolveSlot',
     'Resolve SubVoice slot from algo index, write slot byte 6'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'subcpu', 'kn5000_subprogram_v142.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label + ':' not in content:
            print(f'  WARNING: {old_label} not found, skipping')
            continue

        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)

        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:50s} ({refs} refs)')

    # Check maincpu for cross-references (none expected per grep, but check anyway)
    maincpu_src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(maincpu_src, 'rb') as f:
        maincpu_content = f.read().decode('latin-1')

    maincpu_renames = 0
    for old_label, new_label, _ in RENAMES:
        if old_label in maincpu_content:
            maincpu_content = re.sub(
                r'\b' + re.escape(old_label) + r'\b', new_label, maincpu_content)
            maincpu_renames += 1

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    if maincpu_renames > 0:
        with open(maincpu_src, 'wb') as f:
            f.write(maincpu_content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in subcpu ({maincpu_renames} cross-refs in maincpu)')


if __name__ == '__main__':
    main()
