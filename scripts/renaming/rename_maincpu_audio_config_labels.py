#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in kn5000_v10_program.s (audio config functions).

Covers two major function groups:
  1. Audio_CommandEncoder (FF1054-FF292E) — Printf-like audio command byte formatter
     and its helper functions (string formatting, BCD conversion, float formatting,
     base conversion, digit array manipulation, string copy/search).
  2. Audio_CheckInitStatus (FDF00A-FE01F8) — Audio init status checking, voice/part
     configuration comparison, and command queue building for sub-CPU communication.

Each rename was verified by analysing the routine's code, register usage, called
functions, branch targets, and callers within the file.

Uses binary I/O to handle Latin-1 encoding safely.  Never use the Edit tool on
kn5000_v10_program.s — it corrupts the Latin-1 encoding.
"""

import os
import re

# ---------------------------------------------------------------------------
# Rename table: (old_label, new_label, brief_comment)
#
# Groups follow the natural function boundaries visible in the source.
#
#   FDF00A-FDF074  Audio_CheckInitStatus prologue helpers: part mask init & flags
#   FDF074-FDF4E3  Audio_CheckInitStatus main loop: per-channel status checking
#   FDF4F0-FDF5F5  AudioInit helper sub-functions (priority select, MIDI check)
#   FDF61E-FDF8EB  AudioInit_ConfigureVoiceRouting: voice routing/assignment
#   FDF8F2-FDFA03  AudioInit_ConfigurePanning: stereo/mono pan assignment
#   FDFA0F-FDFAD5  AudioInit_DispatchChanges: master change dispatch loop
#   FDFAF5-FDFB71  AudioInit_QueueCommand: command queue write
#   FDFB71-FDFE28  AudioInit_ComparePartStates: part-level diff detection
#   FDFE28-FE01F8  AudioInit_CompareChannelStates: channel-level diff loops
#
#   FF1054-FF1918  Audio_CommandEncoder: printf-like format string parser
#   FF1933-FF19F5  AudioCmd_IntToStr / AudioCmd_UIntToStr: signed/unsigned
#   FF19C2-FF1A17  AudioCmd_HexToStr / AudioCmd_OctalToStr: hex/octal formatters
#   FF1A17-FF1DD1  AudioCmd_FormatFloat: floating-point formatting entry
#   FF1AC4-FF1DD5  AudioCmd_FormatFFixed: fixed-point %f formatting
#   FF1DE9-FF2135  AudioCmd_FormatEScientific: %e/%E scientific formatting
#   FF2139-FF2410  AudioCmd_FormatGGeneral: %g/%G general float formatting
#   FF2424-FF24ED  AudioCmd_ShiftDigitArray: digit array shift/carry helper
#   FF24ED-FF258D  AudioCmd_NormalizeDigits: digit normalization/rounding
#   FF258D-FF25D4  AudioCmd_InsertCarry: carry propagation for digit add
#   FF25D4-FF265F  AudioCmd_DivideDigitsByTen: digit array divide-by-10
#   FF265F-FF26A4  AudioCmd_MultiplyDigitsByTen: digit array multiply-by-10
#   FF26A4-FF2716  AudioCmd_CountLeadingZeros: count leading zero digits
#   FF2716-FF2768  AudioCmd_CountTrailingZeros: count trailing zero digits
#   FF2768-FF27EC  AudioCmd_DecimalExponent: decimal exponent calculation
#   FF27EC-FF2930  AudioCmd helper: memory copy, itoa-base-N, string search
# ---------------------------------------------------------------------------

RENAMES = [
    # ==================================================================
    # Audio_CheckInitStatus helper prologue (FDF00A-FDF074)
    # Sets up 16-channel part mask tables and global enable flags
    # before the main per-channel comparison loop.
    # ==================================================================

    ('LABEL_FDF00A', 'AudioInit_SetPartMasks',
     'Set bit 5 in part mask table (49954) for all 16 channels'),

    ('LABEL_FDF012', 'AudioInit_SetPartMasks_Loop',
     'Loop body: set bit 5 in part mask entry, increment channel'),

    ('LABEL_FDF028', 'AudioInit_CheckGlobalFlag6',
     'Check global flag bit 6 at addr 64851 for voice group enables'),

    ('LABEL_FDF044', 'AudioInit_ClearVoiceGroupFlags',
     'Global flag clear: reset bit 5 in voice group entries (49986-49996)'),

    ('LABEL_FDF05E', 'AudioInit_CheckVoiceFlag6',
     'Check voice flag bit 6 at addr 64848 for aux voice enable'),

    ('LABEL_FDF06A', 'AudioInit_ClearAuxVoiceFlag',
     'Aux voice flag clear: reset bit 5 in entry 49994'),

    ('LABEL_FDF074', 'AudioInit_CheckReverbFlag',
     'Check reverb flag bit 7 at addr 64851 for reverb enable'),

    ('LABEL_FDF07F', 'AudioInit_ClearReverbFlag',
     'Reverb flag clear: reset bit 5 in reverb entry 50004'),

    # ==================================================================
    # Audio_CheckInitStatus main body (FDF0B1-FDF4E3)
    # Per-channel loop comparing current vs shadow state tables.
    # Reads voice assignment, part bitmasks, and dispatches changes.
    # ==================================================================

    ('LABEL_FDF0B1', 'AudioInit_ClearStatusBit8',
     'Clear bit 8 in status word (no voice group A present)'),

    ('LABEL_FDF0B7', 'AudioInit_CheckGroupB_Presence',
     'Check voice group B presence (addr 10408 OR 3407)'),

    ('LABEL_FDF0CD', 'AudioInit_ClearStatusBit9',
     'Clear bit 9 in status word (no voice group B present)'),

    ('LABEL_FDF0D3', 'AudioInit_ChannelLoop_Init',
     'Initialize channel loop counter e=0, loop over 16 channels'),

    ('LABEL_FDF0DB', 'AudioInit_ChannelLoop_Body',
     'Channel loop body: load voice assignment, compare with shadow'),

    ('LABEL_FDF12C', 'AudioInit_VoiceNotAssigned',
     'Voice not assigned to this channel (mask AND failed): mark 0xFF'),

    ('LABEL_FDF130', 'AudioInit_CheckVoiceChanged',
     'Compare current voice ID vs shadow voice table entry'),

    ('LABEL_FDF159', 'AudioInit_VoiceUnchanged',
     'Voice unchanged or unassigned: write 0xFF to both part tables'),

    ('LABEL_FDF17A', 'AudioInit_CheckGroupA',
     'Check status bit 8 (group A present) for this channel'),

    ('LABEL_FDF1EB', 'AudioInit_GroupA_TypeE',
     'Group A voice type 0xE: set status bit 64, store mapping'),

    ('LABEL_FDF230', 'AudioInit_GroupA_OtherType',
     'Group A other voice types: check MIDI mode (addr 36150 vs 0x8A)'),

    ('LABEL_FDF28B', 'AudioInit_GroupA_NoAuxMapping',
     'No aux mapping available: write 0xFF to part table 49810'),

    ('LABEL_FDF29E', 'AudioInit_GroupA_DefaultMapping',
     'Default voice mapping: store voice ID in part table 49794'),

    ('LABEL_FDF2F2', 'AudioInit_GroupA_NoSecondary',
     'No secondary mapping: write 0xFF to second part table 49810'),

    ('LABEL_FDF303', 'AudioInit_StoreChannelMapping',
     'Store channel mapping byte from erp register to table 49826'),

    ('LABEL_FDF316', 'AudioInit_CheckGroupB_Channel',
     'Check status bit 9 (group B present) for this channel'),

    ('LABEL_FDF34E', 'AudioInit_GroupB_CheckType',
     'Group B: compare voice type (d register) for dispatch'),

    ('LABEL_FDF3A6', 'AudioInit_GroupB_TypeE',
     'Group B voice type 0xE: set status bit 4, store mapping'),

    ('LABEL_FDF3EA', 'AudioInit_GroupB_Type10',
     'Group B voice type 0x10: write 0xFF to both part tables'),

    ('LABEL_FDF410', 'AudioInit_GroupB_DefaultMapping',
     'Group B default: store voice mapping in both part tables'),

    ('LABEL_FDF44C', 'AudioInit_ChannelLoop_Next',
     'Set channel done bits, advance to next channel (inc e)'),

    ('LABEL_FDF45A', 'AudioInit_ChannelLoop_Done',
     'All 16 channels processed: check if any changes were found'),

    ('LABEL_FDF466', 'AudioInit_SetChangedFlag',
     'At least one channel changed: set status bit 0 (changed)'),

    ('LABEL_FDF472', 'AudioInit_CheckExternalBit3',
     'Check external config bit 3 (addr 10419) to clear bit 9'),

    # ==================================================================
    # AudioInit_ConfigureOutputRouting (FDF4A7-FDF4E3)
    # Determines audio output routing from voice config flags.
    # ==================================================================

    ('LABEL_FDF4A7', 'AudioInit_NoTypeE_CheckD',
     'No type-E voice: check for type-D (status bits AND 0x22)'),

    ('LABEL_FDF4CE', 'AudioInit_DefaultOutputRouting',
     'Default output routing: use full 4-bit config from addr 64605'),

    ('LABEL_FDF4E3', 'AudioInit_ApplyOutputRouting',
     'Apply computed output routing bits to status word 50582'),

    # ==================================================================
    # AudioInit_SelectPriority (FDF4F0-FDF5CC)
    # Selects voice priority levels based on configuration byte.
    # ==================================================================

    ('LABEL_FDF4F0', 'AudioInit_SelectPriority',
     'Select priority assignment based on config byte (addr 14235)'),

    ('LABEL_FDF52C', 'AudioInit_Priority_Mode2',
     'Priority mode 2: channel 1 = priority 1, others = 0xFF'),

    ('LABEL_FDF54C', 'AudioInit_Priority_Mode4',
     'Priority mode 4: channel 2 = priority 2, others = 0xFF'),

    ('LABEL_FDF56C', 'AudioInit_Priority_Mode8',
     'Priority mode 8: channel 3 = priority 3, others = 0xFF'),

    ('LABEL_FDF58C', 'AudioInit_Priority_Mode10',
     'Priority mode 0x10: channel 4 = priority 4, others = 0xFF'),

    ('LABEL_FDF5AC', 'AudioInit_Priority_Default',
     'Default priority: all channels = 0xFF (no priority)'),

    # ==================================================================
    # AudioInit_CheckMIDIStatus (FDF5CC-FDF5F5)
    # Checks MIDI channel enable status.
    # ==================================================================

    ('LABEL_FDF5CC', 'AudioInit_CheckMIDIStatus',
     'Check MIDI status byte at addr 32523 for MIDI channel config'),

    ('LABEL_FDF5E4', 'AudioInit_MIDIDisabled',
     'MIDI disabled: write 0xFF to both MIDI tables, set flag'),

    ('LABEL_FDF5F5', 'AudioInit_RefreshToneBank',
     'Refresh tone bank: call tone generator and voice assign routines'),

    # ==================================================================
    # AudioInit_ConfigureVoiceRouting (FDF61E-FDF8EB)
    # Encoded command table + voice routing logic for stereo/mono/split.
    # ==================================================================

    ('LABEL_FDF61E', 'AudioInit_VoiceRoutingTable',
     'Encoded byte table for voice routing commands (~248 bytes)'),

    ('LABEL_FDF716', 'AudioInit_ConfigureVoiceRouting',
     'Main voice routing: clear bit 8, check routing mode bits'),

    ('LABEL_FDF77E', 'AudioInit_Routing_SetOverrideFlag',
     'Set routing override flag (bit 8 in status 50582)'),

    ('LABEL_FDF787', 'AudioInit_Routing_CheckSplitMode',
     'Check split mode: bit 1 of addr 64607'),

    ('LABEL_FDF7AA', 'AudioInit_Routing_SplitCheckAux',
     'Split mode: check aux voice enable (bit 5 of 64433)'),

    ('LABEL_FDF7B9', 'AudioInit_Routing_SplitOverride',
     'Split mode with FC bits: set override flag'),

    ('LABEL_FDF7C2', 'AudioInit_Routing_NoSplit',
     'No split mode: check FC bits in addr 64607/64608'),

    ('LABEL_FDF7DF', 'AudioInit_Routing_NoSplitCheckAux',
     'No split, no FC bits: check aux voice (bit 5 of 64433)'),

    ('LABEL_FDF7EE', 'AudioInit_Routing_CheckTypeEDFlags',
     'FC bits present: check type-E/D status (bits 5+6 of 50584)'),

    ('LABEL_FDF803', 'AudioInit_Routing_TypeED_CheckAux',
     'Type-E/D with no override: check aux enable'),

    ('LABEL_FDF812', 'AudioInit_Routing_TypeED_Override',
     'Type-E/D override present: set override flag'),

    ('LABEL_FDF81B', 'AudioInit_Routing_NoGroupAB',
     'No group A or B routing: simple priority-based assignment'),

    ('LABEL_FDF826', 'AudioInit_Routing_SimpleAssign',
     'Simple assignment: set priority levels 21/22, check page mode'),

    ('LABEL_FDF84F', 'AudioInit_Routing_AllDisabled',
     'Page mode matched: disable all priorities (0xFF)'),

    ('LABEL_FDF85C', 'AudioInit_Routing_CheckMixMode',
     'Check mix mode: status bit 9 and split enable'),

    ('LABEL_FDF889', 'AudioInit_Routing_MixCheckAux',
     'Mix mode: check aux voice enable (bit 5 of 64433)'),

    ('LABEL_FDF896', 'AudioInit_Routing_MixFCBits',
     'Mix with FC bits: check type-E/D override for priority'),

    ('LABEL_FDF8AB', 'AudioInit_Routing_MixFCCheckAux',
     'Mix FC bits: check aux voice (bit 5 of 64433)'),

    ('LABEL_FDF8B6', 'AudioInit_Routing_SkipToEnd',
     'Skip to end of routing configuration'),

    ('LABEL_FDF8B8', 'AudioInit_Routing_NoActiveVoices',
     'No active voice groups: check bit 2 for fallback priority'),

    ('LABEL_FDF8D7', 'AudioInit_Routing_FullDisable',
     'Fully disable all routing: all priorities = 0xFF'),

    ('LABEL_FDF8EB', 'AudioInit_Routing_Done',
     'Voice routing complete: set done bits (260) in status 50588'),

    # ==================================================================
    # AudioInit_ConfigurePanning (FDF8F2-FDFA03)
    # Stereo/mono pan position assignment based on voice config.
    # ==================================================================

    ('LABEL_FDF8F2', 'AudioInit_ConfigurePanning',
     'Check panning config: verify bit 10 set and bit 2 clear in 50582'),

    ('LABEL_FDF916', 'AudioInit_Pan_CheckMode0',
     'Pan mode: check if voice ID = 0 (addr 49663)'),

    ('LABEL_FDF91D', 'AudioInit_Pan_SetStereoLeft',
     'Pan = stereo left: write 0 to pan position (49844)'),

    ('LABEL_FDF924', 'AudioInit_Pan_CheckMode1',
     'Pan mode: check if voice ID = 1 (addr 49663)'),

    ('LABEL_FDF931', 'AudioInit_Pan_CheckMode1b',
     'Secondary check for voice ID = 1 via bit 1 of 49662'),

    ('LABEL_FDF938', 'AudioInit_Pan_SetStereoRight',
     'Pan = stereo right: write 1 to pan position (49844)'),

    ('LABEL_FDF93F', 'AudioInit_Pan_CheckTypeED',
     'Check type-E/D status bits for special pan handling'),

    ('LABEL_FDF95B', 'AudioInit_Pan_TypeED_Left',
     'Type-E/D pan: left position (write 0 to 49844)'),

    ('LABEL_FDF962', 'AudioInit_Pan_DefaultCenter',
     'Default pan: center position (write 0xFF to 49844)'),

    ('LABEL_FDF967', 'AudioInit_Pan_CheckReverbChannel',
     'Check reverb channel pan (compare addr 59840 vs 14)'),

    ('LABEL_FDF97B', 'AudioInit_Pan_Reverb_CheckMode0',
     'Reverb pan: check voice mode 0 for left assignment'),

    ('LABEL_FDF982', 'AudioInit_Pan_Reverb_Left',
     'Reverb pan = left: write 0 to reverb pan (49852)'),

    ('LABEL_FDF989', 'AudioInit_Pan_Reverb_CheckMode1',
     'Reverb pan: check voice mode 1 for right assignment'),

    ('LABEL_FDF996', 'AudioInit_Pan_Reverb_CheckMode1b',
     'Reverb pan: secondary check for voice mode 1'),

    ('LABEL_FDF99D', 'AudioInit_Pan_Reverb_Right',
     'Reverb pan = right: write 1 to reverb pan (49852)'),

    ('LABEL_FDF9A4', 'AudioInit_Pan_Reverb_CheckTypeED',
     'Reverb pan: check type-E/D status for special handling'),

    ('LABEL_FDF9C0', 'AudioInit_Pan_Reverb_TypeED_Left',
     'Reverb type-E/D pan: left (write 0)'),

    ('LABEL_FDF9C7', 'AudioInit_Pan_Reverb_Center',
     'Reverb default pan: center (write 0xFF)'),

    ('LABEL_FDF9CE', 'AudioInit_Pan_Reverb_CopyFromMain',
     'Reverb channel <= 14: copy pan from main channel (addr 59840)'),

    ('LABEL_FDF9D4', 'AudioInit_Pan_Done',
     'Panning config done: set bit 8 (256) in status 50588'),

    # ==================================================================
    # AudioInit_CheckStereoMode (FDF9DB-FDFA03)
    # Determines stereo/mono mode from voice config flags.
    # ==================================================================

    ('LABEL_FDF9DB', 'AudioInit_CheckStereoMode',
     'Check stereo mode: verify bit 11 of status 50582'),

    ('LABEL_FDF9F1', 'AudioInit_Stereo_CheckBit1',
     'Check bit 1 of 49662 for stereo mode 1'),

    ('LABEL_FDF9FE', 'AudioInit_Stereo_Default',
     'Default stereo: write 0xFF (center/disabled) to 49664'),

    ('LABEL_FDFA03', 'AudioInit_Stereo_CheckBit3',
     'Check bit 3 of 49662 for dual-mono override'),

    # ==================================================================
    # AudioInit_DispatchChanges (FDFA0F-FDFAD5)
    # Master dispatch: calls individual change-detection routines
    # based on which status bits are set in the tracking words.
    # ==================================================================

    ('LABEL_FDFA0F', 'AudioInit_DispatchChanges',
     'Master dispatch: clear command count, check all change flags'),

    ('LABEL_FDFA3E', 'AudioInit_Dispatch_CheckVoiceChange',
     'Check voice change flag or deferred voice bit'),

    ('LABEL_FDFA50', 'AudioInit_Dispatch_SendVoiceChange',
     'Send voice change commands to sub-CPU'),

    ('LABEL_FDFA53', 'AudioInit_Dispatch_CheckPartChange',
     'Check part/channel change flag or deferred bits'),

    ('LABEL_FDFA66', 'AudioInit_Dispatch_SendPartChange',
     'Send part/channel change commands'),

    ('LABEL_FDFA69', 'AudioInit_Dispatch_CheckMisc',
     'Check and dispatch misc flags: bits 2,3,6,4 of 50588'),

    ('LABEL_FDFAAB', 'AudioInit_Dispatch_CheckToneRefresh',
     'Check if tone refresh needed (bit 13 of 50586 or bit 4 of 50582)'),

    ('LABEL_FDFAB4', 'AudioInit_Dispatch_RefreshTone',
     'Call tone generator refresh routine'),

    ('LABEL_FDFAC0', 'AudioInit_Dispatch_CheckVoiceAssign',
     'Check voice assignment refresh (bit 14 of 50586)'),

    ('LABEL_FDFAD5', 'AudioInit_Dispatch_Finalize',
     'Finalize: copy shadow tables, clear change flags, return'),

    # ==================================================================
    # AudioInit_QueueCommand (FDFAF5-FDFB71)
    # Writes a 4-byte command entry to the circular command queue.
    # ==================================================================

    ('LABEL_FDFAF5', 'AudioInit_QueueCommand',
     'Queue a 4-byte audio command: (type, channel, value, extra)'),

    ('LABEL_FDFB11', 'AudioInit_QueueCommand_Write',
     'Write command to queue at current write pointer (50378-50383)'),

    # ==================================================================
    # AudioInit_ComparePartStates (FDFB71-FDFE28)
    # Compares current vs shadow part state tables, queuing commands
    # for each detected difference.
    # ==================================================================

    ('LABEL_FDFB71', 'AudioInit_ComparePartStates',
     'Compare part states: check bit 3 of 50588 (part change flag)'),

    ('LABEL_FDFB85', 'AudioInit_PartCompare_Loop',
     'Part compare loop: iterate 26 parts (iz = 0..0x19)'),

    ('LABEL_FDFBD0', 'AudioInit_PartCompare_SameVoice',
     'Same voice ID: check if voice is active (not 0xFF)'),

    ('LABEL_FDFC23', 'AudioInit_PartCompare_Next',
     'Advance to next part in comparison loop'),

    ('LABEL_FDFC2C', 'AudioInit_PartCompare_CheckGlobalBits',
     'After part loop: compare global config bits (carry flags)'),

    ('LABEL_FDFC4D', 'AudioInit_ComparePanState',
     'Compare pan/stereo state: check bit 8 of 50588'),

    ('LABEL_FDFC78', 'AudioInit_PartCompare_Return',
     'Part compare done: restore iz and return'),

    # ==================================================================
    # AudioInit_CompareVoiceConfig (FDFC7A-FDFE05)
    # Compares voice configuration including split/layer settings.
    # ==================================================================

    ('LABEL_FDFC7A', 'AudioInit_CompareVoiceConfig',
     'Compare voice config: check voice ID, split, and layer changes'),

    ('LABEL_FDFCC4', 'AudioInit_VoiceCompare_BothFF',
     'Both current and shadow voice = 0xFF: check layer bits'),

    ('LABEL_FDFCFF', 'AudioInit_VoiceCompare_LayerLoop',
     'Layer compare loop: iterate 6 voice layers (ix = 0..5)'),

    ('LABEL_FDFD68', 'AudioInit_VoiceCompare_LayerChanged',
     'Layer changed: check if active (AND with d register mask)'),

    ('LABEL_FDFD78', 'AudioInit_VoiceCompare_LayerNext',
     'Next layer: shift mask (d), increment ix'),

    ('LABEL_FDFD83', 'AudioInit_VoiceCompare_NotBothFF',
     'Voice IDs not both 0xFF: compare layer bits with mask 0xF8'),

    ('LABEL_FDFDE5', 'AudioInit_VoiceCompare_SetBit3',
     'Voice layer mismatch on bit 3 entry: set bits in e and l'),

    ('LABEL_FDFDEB', 'AudioInit_VoiceCompare_BuildCmd',
     'Build voice change command from e (added) and l (removed) masks'),

    ('LABEL_FDFDF3', 'AudioInit_VoiceCompare_QueueCmd',
     'Queue voice change command if e != 0 or l != 0'),

    ('LABEL_FDFE05', 'AudioInit_VoiceCompare_PanCheck',
     'After voice compare: check pan state change'),

    # ==================================================================
    # AudioInit_CompareChannelMappings (FDFE28-FDFF05)
    # Compares per-channel mapping tables (26 entries for parts,
    # 16 entries for channels) and queues change commands.
    # ==================================================================

    ('LABEL_FDFE28', 'AudioInit_CompareChannelMappings',
     'Compare channel mapping tables: check bits 6+7 of 50588'),

    ('LABEL_FDFE3D', 'AudioInit_ChannelMap_Loop',
     'Channel mapping loop: iterate 16 channels (iz = 0..0x0F)'),

    ('LABEL_FDFE86', 'AudioInit_ChannelMap_CheckPrimary',
     'Check primary part table (49794) vs shadow (50152)'),

    ('LABEL_FDFECF', 'AudioInit_ChannelMap_Next',
     'Next channel in mapping comparison loop'),

    ('LABEL_FDFED8', 'AudioInit_ChannelMap_CheckPan',
     'After channel loop: check pan change (bit 8 of 50588)'),

    ('LABEL_FDFF03', 'AudioInit_ChannelMap_Return',
     'Channel mapping comparison done: restore iz and return'),

    # ==================================================================
    # AudioInit_ComparePriorityTable (FDFF05-FDFF5D)
    # Compares voice priority assignment table (3 entries).
    # ==================================================================

    ('LABEL_FDFF05', 'AudioInit_ComparePriorityTable',
     'Compare 3-entry priority table (49850 vs 50208)'),

    ('LABEL_FDFF0C', 'AudioInit_Priority_Loop',
     'Priority compare loop: iterate 3 entries (iz = 0..2)'),

    ('LABEL_FDFF55', 'AudioInit_Priority_Next',
     'Next priority entry in comparison loop'),

    ('LABEL_FDFF5B', 'AudioInit_Priority_Return',
     'Priority comparison done: restore iz and return'),

    # ==================================================================
    # AudioInit_ComparePartAssignment (FDFF5D-FE0023)
    # Compares 26-entry part assignment tables with special handling
    # for MIDI-through channels (indices 2, 0x15, 0x16).
    # ==================================================================

    ('LABEL_FDFF5D', 'AudioInit_ComparePartAssignment',
     'Compare 26-entry part assignment table (49666 vs 50024)'),

    ('LABEL_FDFF67', 'AudioInit_PartAssign_Loop',
     'Part assignment loop: iterate 26 parts (iz = 0..0x19)'),

    ('LABEL_FDFFA5', 'AudioInit_PartAssign_CheckIdx15',
     'Check special index 0x15: MIDI-through priority channel'),

    ('LABEL_FDFFC8', 'AudioInit_PartAssign_CheckIdx16',
     'Check special index 0x16: MIDI-through secondary channel'),

    ('LABEL_FDFFEB', 'AudioInit_PartAssign_QueueChange',
     'Queue part assignment change command (type = 7)'),

    ('LABEL_FE0018', 'AudioInit_PartAssign_Next',
     'Next part in assignment comparison loop'),

    ('LABEL_FE0021', 'AudioInit_PartAssign_Return',
     'Part assignment comparison done: restore iz and return'),

    # ==================================================================
    # AudioInit_ComparePartConfig (FE0023-FE013C)
    # Compares 26-entry part config tables with carry-flag checks
    # for reverb and effect send level differences.
    # ==================================================================

    ('LABEL_FE0023', 'AudioInit_ComparePartConfig',
     'Compare 26-entry part config tables (49698 vs 50056)'),

    ('LABEL_FE002D', 'AudioInit_PartConfig_Loop',
     'Part config loop: iterate 26 parts (iz = 0..0x19)'),

    ('LABEL_FE007A', 'AudioInit_PartConfig_SameVoice',
     'Same voice: check reverb channel (iz == 0x19) for send level'),

    ('LABEL_FE00DF', 'AudioInit_PartConfig_NotReverb',
     'Not reverb channel: check if voice is active (not 0xFF)'),

    ('LABEL_FE00EE', 'AudioInit_PartConfig_CheckCarry',
     'Active voice: compare carry flags (bit 5 of 50312 vs 49954)'),

    ('LABEL_FE0133', 'AudioInit_PartConfig_Next',
     'Next part in config comparison loop'),

    ('LABEL_FE013C', 'AudioInit_PartConfig_Return',
     'Part config comparison done: restore iz and return'),

    # ==================================================================
    # AudioInit_CompareChannelConfig (FE013E-FE0199)
    # Compares 16-entry channel config tables (primary part mapping).
    # ==================================================================

    ('LABEL_FE013E', 'AudioInit_CompareChannelConfig',
     'Compare 16-entry channel config (49794 vs 50152), type = 9'),

    ('LABEL_FE0147', 'AudioInit_ChannelConfig_Loop',
     'Channel config loop: iterate 16 channels (iz = 0..0x0F)'),

    ('LABEL_FE0191', 'AudioInit_ChannelConfig_Next',
     'Next channel in config comparison loop'),

    ('LABEL_FE0199', 'AudioInit_ChannelConfig_Return',
     'Channel config comparison done: restore iz and return'),

    # ==================================================================
    # AudioInit_CompareVolumeTable (FE019B-FE01F8)
    # Compares 26-entry volume/expression tables.
    # ==================================================================

    ('LABEL_FE019B', 'AudioInit_CompareVolumeTable',
     'Compare 26-entry volume table (49730 vs 50088), type = 0xA'),

    ('LABEL_FE01A4', 'AudioInit_Volume_Loop',
     'Volume table loop: iterate 26 entries (iz = 0..0x19)'),

    ('LABEL_FE01EE', 'AudioInit_Volume_Next',
     'Next entry in volume comparison loop'),

    ('LABEL_FE01F6', 'AudioInit_Volume_Return',
     'Volume table comparison done: restore iz and return'),

    ('LABEL_FE01F8', 'AudioInit_InitPartSendLevels',
     'Initialize 161-entry part send level table (50730-50731)'),

    # ==================================================================
    # Audio_CommandEncoder body (FF1054-FF1918)
    # Printf-like format string parser for audio command packets.
    # Stack frame: 74 bytes. Parses % specifiers to build packets.
    # ==================================================================

    ('LABEL_FF1054', 'AudioCmd_OutputLiteral',
     'Not a % specifier: output literal char via callback, advance'),

    ('LABEL_FF1068', 'AudioCmd_ParseFormatSpec',
     'Found %: init flags/width/precision, start parsing specifier'),

    ('LABEL_FF107E', 'AudioCmd_ReadFormatChar',
     'Read next format char: dispatch flag characters (0#+ -)'),

    ('LABEL_FF10D3', 'AudioCmd_StarWidth_Positive',
     'Star-width >= 0: read next format char and continue'),

    ('LABEL_FF10E3', 'AudioCmd_Flag_Space',
     'Flag 0x20 (space): set bit 2 in flags'),

    ('LABEL_FF10E8', 'AudioCmd_Flag_Hash',
     'Flag 0x23 (#): set bit 3 in flags (alternate form)'),

    ('LABEL_FF10ED', 'AudioCmd_Flag_Plus',
     'Flag 0x2B (+): set bit 0 in flags (force sign)'),

    ('LABEL_FF10F2', 'AudioCmd_Flag_Minus',
     'Flag 0x2D (-): set bit 1 in flags (left-align)'),

    ('LABEL_FF10F7', 'AudioCmd_Flag_Zero',
     'Flag 0x30 (0): set pad char to 0x30 in fill field'),

    ('LABEL_FF1101', 'AudioCmd_ParseWidthDigit',
     'Parse width digit: width = width * 10 + (char - 0x30)'),

    ('LABEL_FF1122', 'AudioCmd_CheckIfDigit',
     'Check if current char is a digit (lookup table at 0xEED778)'),

    ('LABEL_FF1133', 'AudioCmd_CheckPrecisionDot',
     'Check for . (0x2E): start precision field parsing'),

    ('LABEL_FF1169', 'AudioCmd_StarPrecision_Applied',
     'Star-precision applied: read next format char'),

    ('LABEL_FF1179', 'AudioCmd_ParsePrecisionDigit',
     'Parse precision digit: precision = precision * 10 + (char - 0x30)'),

    ('LABEL_FF119A', 'AudioCmd_CheckPrecisionDigit',
     'Check if current char is a digit for precision field'),

    ('LABEL_FF11AB', 'AudioCmd_CheckLengthH',
     'Check for h (0x68): short int length modifier'),

    ('LABEL_FF11C4', 'AudioCmd_CheckLengthL',
     'Check for l (0x6C): long int length modifier'),

    ('LABEL_FF11DD', 'AudioCmd_CheckLengthLL',
     'Check for L (0x4C): long double length modifier'),

    ('LABEL_FF11F4', 'AudioCmd_DispatchType',
     'Dispatch format type: G/E -> float, X -> hex, c/s/d/o/u/x/p/n'),

    ('LABEL_FF1237', 'AudioCmd_Format_Percent',
     'Format %%: output % literal with left/right padding'),

    ('LABEL_FF1241', 'AudioCmd_Percent_PadLeft',
     'Pad left with spaces before % char'),

    ('LABEL_FF1250', 'AudioCmd_Percent_PadLeftLoop',
     'Left-pad loop: decrement width, output space if > 0'),

    ('LABEL_FF125A', 'AudioCmd_Format_CharOrPercent',
     'Format %c or %%: output char from varargs or literal %'),

    ('LABEL_FF1271', 'AudioCmd_Percent_LiteralPush',
     'Push literal 0x25 (%) for output'),

    ('LABEL_FF1274', 'AudioCmd_Percent_OutputChar',
     'Output character via callback, then check right-pad'),

    ('LABEL_FF1286', 'AudioCmd_Percent_PadRight',
     'Right-pad with spaces after character'),

    ('LABEL_FF1293', 'AudioCmd_Percent_PadRightLoop',
     'Right-pad loop: decrement width, output space if > 0'),

    # -- %s string formatting --

    ('LABEL_FF12C3', 'AudioCmd_String_UseStrLen',
     'Use measured string length as precision'),

    ('LABEL_FF12C8', 'AudioCmd_String_UsePrecision',
     'Use specified precision (shorter than string)'),

    ('LABEL_FF12CB', 'AudioCmd_String_ComputePadding',
     'Compute padding: compare precision vs width'),

    ('LABEL_FF12DA', 'AudioCmd_String_WidthAvailable',
     'Width >= precision: subtract used chars from width'),

    ('LABEL_FF12E3', 'AudioCmd_String_CheckLeftAlign',
     'Check left-align flag for string output'),

    ('LABEL_FF12ED', 'AudioCmd_String_PadLeftSpace',
     'Pad left with spaces before string'),

    ('LABEL_FF12F9', 'AudioCmd_String_PadLeftLoop',
     'Left-pad space loop: decrement width count'),

    ('LABEL_FF1305', 'AudioCmd_String_OutputChars',
     'Output string characters via callback, one byte at a time'),

    ('LABEL_FF1318', 'AudioCmd_String_OutputLoop',
     'String output loop: decrement precision, output next char'),

    ('LABEL_FF132D', 'AudioCmd_String_PadRightSpace',
     'Pad right with spaces after string'),

    ('LABEL_FF1337', 'AudioCmd_String_PadRightLoop',
     'Right-pad loop: decrement width count'),

    # -- %d signed decimal formatting --

    ('LABEL_FF135D', 'AudioCmd_Decimal_GetShortArg',
     'Get short (16-bit) argument for %d, sign-extend to 32-bit'),

    ('LABEL_FF136E', 'AudioCmd_Decimal_Setup',
     'Set up decimal formatting: init sign, check for zero suppression'),

    ('LABEL_FF1396', 'AudioCmd_Decimal_ConvertToString',
     'Convert integer to decimal string buffer via signed itoa'),

    ('LABEL_FF13BC', 'AudioCmd_Decimal_CheckPrecision',
     'Check if explicit precision vs measured length'),

    ('LABEL_FF13CC', 'AudioCmd_Decimal_NoPrecision',
     'No precision specified: zero out precision field'),

    ('LABEL_FF13D3', 'AudioCmd_Decimal_SubtractLength',
     'Subtract converted length from precision'),

    ('LABEL_FF13D9', 'AudioCmd_Decimal_CheckSign',
     'Check if sign char needed (bits 0+2: force-sign or space)'),

    ('LABEL_FF13E7', 'AudioCmd_Decimal_ComputeWidth',
     'Compute total width: length + precision + sign indicator'),

    ('LABEL_FF13FA', 'AudioCmd_Decimal_FinalWidth',
     'Final width calculation for padding'),

    ('LABEL_FF1428', 'AudioCmd_Decimal_PadLeftSpace',
     'Left-pad with spaces (not left-aligned, not zero-fill)'),

    ('LABEL_FF1432', 'AudioCmd_Decimal_PadLeftLoop',
     'Left-pad space loop: decrement width'),

    ('LABEL_FF1441', 'AudioCmd_Decimal_OutputSign',
     'Output sign character if needed (- + or space)'),

    ('LABEL_FF1451', 'AudioCmd_Decimal_PlusSign',
     'Positive with force-sign: output + (0x2B)'),

    ('LABEL_FF145E', 'AudioCmd_Decimal_SpaceSign',
     'Positive with space-sign: output space (0x20)'),

    ('LABEL_FF1469', 'AudioCmd_Decimal_EmitSign',
     'Emit sign character via callback'),

    ('LABEL_FF1470', 'AudioCmd_Decimal_ZeroFill',
     'Check and emit zero-fill padding before digits'),

    ('LABEL_FF1483', 'AudioCmd_Decimal_ZeroFillBody',
     'Zero-fill loop body: push 0x30, call output'),

    ('LABEL_FF148D', 'AudioCmd_Decimal_ZeroFillLoop',
     'Zero-fill loop: decrement width, output 0 if > 0'),

    ('LABEL_FF1499', 'AudioCmd_Decimal_PrecZeroBody',
     'Precision zero-fill body: push 0x30'),

    ('LABEL_FF14A3', 'AudioCmd_Decimal_PrecZeroLoop',
     'Precision zero-fill loop: fill to precision width'),

    ('LABEL_FF14AF', 'AudioCmd_Decimal_OutputDigits',
     'Output converted digit string from buffer'),

    ('LABEL_FF14C7', 'AudioCmd_Decimal_DigitLoop',
     'Digit output loop: decrement digit count, output next'),

    ('LABEL_FF14D9', 'AudioCmd_Decimal_PadRightSpace',
     'Right-pad with spaces after decimal number'),

    ('LABEL_FF14E3', 'AudioCmd_Decimal_PadRightLoop',
     'Right-pad loop: decrement width'),

    # -- %u unsigned decimal formatting --

    ('LABEL_FF1506', 'AudioCmd_Unsigned_GetShortArg',
     'Get short (16-bit) argument for %u, zero-extend to 32-bit'),

    ('LABEL_FF1514', 'AudioCmd_Unsigned_Setup',
     'Set up unsigned formatting: init buffer, check zero suppression'),

    ('LABEL_FF1531', 'AudioCmd_Unsigned_ConvertToString',
     'Convert unsigned int to string via unsigned itoa'),

    ('LABEL_FF1543', 'AudioCmd_Unsigned_CheckPrecision',
     'Check precision for unsigned output'),

    ('LABEL_FF1550', 'AudioCmd_Unsigned_NoPrecision',
     'No precision: zero out field'),

    ('LABEL_FF1557', 'AudioCmd_Unsigned_SubtractLength',
     'Subtract converted length from precision'),

    ('LABEL_FF155A', 'AudioCmd_Unsigned_ComputeWidth',
     'Compute total output width for unsigned number'),

    ('LABEL_FF1569', 'AudioCmd_Unsigned_FinalWidth',
     'Final width with zero-floor'),

    ('LABEL_FF157E', 'AudioCmd_Unsigned_PadLeftSpace',
     'Left-pad unsigned with spaces'),

    ('LABEL_FF158A', 'AudioCmd_Unsigned_PadLeftLoop',
     'Left-pad space loop for unsigned'),

    ('LABEL_FF1596', 'AudioCmd_Unsigned_PrecZeroBody',
     'Precision zero-fill body for unsigned'),

    ('LABEL_FF15A0', 'AudioCmd_Unsigned_PrecZeroLoop',
     'Precision zero-fill loop for unsigned'),

    ('LABEL_FF15AC', 'AudioCmd_Unsigned_OutputDigits',
     'Output unsigned digit string from buffer'),

    ('LABEL_FF15C0', 'AudioCmd_Unsigned_DigitLoop',
     'Unsigned digit output loop'),

    ('LABEL_FF15CF', 'AudioCmd_Unsigned_PadRightSpace',
     'Right-pad unsigned with spaces'),

    ('LABEL_FF15D9', 'AudioCmd_Unsigned_PadRightLoop',
     'Right-pad loop for unsigned'),

    # -- %X/%x hex formatting --

    ('LABEL_FF15E9', 'AudioCmd_Hex_GetArg',
     'Get argument for hex formatting, check long modifier'),

    ('LABEL_FF15FF', 'AudioCmd_Hex_GetShortArg',
     'Get short (16-bit) argument for hex, zero-extend'),

    ('LABEL_FF160D', 'AudioCmd_Hex_Setup',
     'Set up hex formatting: init buffer, check zero suppression'),

    ('LABEL_FF162D', 'AudioCmd_Hex_ConvertToString',
     'Convert to hex string via hex-digit itoa'),

    ('LABEL_FF1641', 'AudioCmd_Hex_CheckPrecision',
     'Check precision for hex output'),

    ('LABEL_FF1651', 'AudioCmd_Hex_NoPrecision',
     'No precision: zero out field'),

    ('LABEL_FF1658', 'AudioCmd_Hex_SubtractLength',
     'Subtract converted hex length from precision'),

    ('LABEL_FF165E', 'AudioCmd_Hex_CheckAltForm',
     'Check # flag (bit 3): if set, prefix "0x" (add 2 chars)'),

    ('LABEL_FF166C', 'AudioCmd_Hex_AltFormPrefix',
     'Alt form: set prefix width to 2 (for "0x")'),

    ('LABEL_FF167F', 'AudioCmd_Hex_ComputeWidth',
     'Compute total hex output width with prefix'),

    ('LABEL_FF16A1', 'AudioCmd_Hex_PadLeftSpace',
     'Left-pad hex with spaces'),

    ('LABEL_FF16AB', 'AudioCmd_Hex_PadLeftLoop',
     'Left-pad space loop for hex'),

    ('LABEL_FF16B5', 'AudioCmd_Hex_EmitPrefix',
     'Emit "0x" prefix if alt form and non-zero value'),

    ('LABEL_FF16D1', 'AudioCmd_Hex_ZeroFill',
     'Check and emit zero-fill for hex formatting'),

    ('LABEL_FF16E4', 'AudioCmd_Hex_ZeroFillBody',
     'Zero-fill body: output 0x30'),

    ('LABEL_FF16EE', 'AudioCmd_Hex_ZeroFillLoop',
     'Zero-fill loop for hex'),

    ('LABEL_FF16FA', 'AudioCmd_Hex_PrecZeroBody',
     'Precision zero-fill body for hex'),

    ('LABEL_FF1704', 'AudioCmd_Hex_PrecZeroLoop',
     'Precision zero-fill loop for hex'),

    ('LABEL_FF1710', 'AudioCmd_Hex_OutputDigits',
     'Output hex digit string from buffer'),

    ('LABEL_FF1728', 'AudioCmd_Hex_DigitLoop',
     'Hex digit output loop'),

    ('LABEL_FF173A', 'AudioCmd_Hex_PadRightSpace',
     'Right-pad hex with spaces'),

    ('LABEL_FF1744', 'AudioCmd_Hex_PadRightLoop',
     'Right-pad loop for hex'),

    # -- %o octal formatting --

    ('LABEL_FF1767', 'AudioCmd_Octal_GetShortArg',
     'Get short (16-bit) arg for octal, zero-extend'),

    ('LABEL_FF1775', 'AudioCmd_Octal_Setup',
     'Set up octal formatting: init buffer, check zero suppression'),

    ('LABEL_FF1792', 'AudioCmd_Octal_ConvertToString',
     'Convert to octal string via octal-digit itoa'),

    ('LABEL_FF17A4', 'AudioCmd_Octal_CheckPrecision',
     'Check precision for octal output'),

    ('LABEL_FF17B1', 'AudioCmd_Octal_NoPrecision',
     'No precision: zero out field'),

    ('LABEL_FF17B8', 'AudioCmd_Octal_SubtractLength',
     'Subtract converted octal length from precision'),

    ('LABEL_FF17BB', 'AudioCmd_Octal_CheckAltForm',
     'Check # flag: if set, prefix with single 0'),

    ('LABEL_FF17DB', 'AudioCmd_Octal_ComputeWidth',
     'Compute total octal output width'),

    ('LABEL_FF17FC', 'AudioCmd_Octal_PadLeftSpace',
     'Left-pad octal with spaces'),

    ('LABEL_FF1806', 'AudioCmd_Octal_PadLeftLoop',
     'Left-pad space loop for octal'),

    ('LABEL_FF1810', 'AudioCmd_Octal_EmitPrefix',
     'Emit "0" prefix if alt form and non-zero value'),

    ('LABEL_FF1825', 'AudioCmd_Octal_ZeroFill',
     'Check and emit zero-fill for octal'),

    ('LABEL_FF1838', 'AudioCmd_Octal_ZeroFillBody',
     'Zero-fill body for octal'),

    ('LABEL_FF1842', 'AudioCmd_Octal_ZeroFillLoop',
     'Zero-fill loop for octal'),

    ('LABEL_FF184E', 'AudioCmd_Octal_PrecZeroBody',
     'Precision zero-fill body for octal'),

    ('LABEL_FF1858', 'AudioCmd_Octal_PrecZeroLoop',
     'Precision zero-fill loop for octal'),

    ('LABEL_FF1864', 'AudioCmd_Octal_OutputDigits',
     'Output octal digit string from buffer'),

    ('LABEL_FF1878', 'AudioCmd_Octal_DigitLoop',
     'Octal digit output loop'),

    ('LABEL_FF1887', 'AudioCmd_Octal_PadRightSpace',
     'Right-pad octal with spaces'),

    ('LABEL_FF1891', 'AudioCmd_Octal_PadRightLoop',
     'Right-pad loop for octal'),

    # -- %n (store count) and %G/%E/%f float entry --

    ('LABEL_FF18BA', 'AudioCmd_StoreCount_Short',
     '%n short modifier: store 16-bit output count to pointer'),

    ('LABEL_FF18C1', 'AudioCmd_FormatFloat_Entry',
     '%G or %E: load float argument, set up float formatting'),

    ('LABEL_FF18E1', 'AudioCmd_FormatFloat_ShortArg',
     'Float short arg: 8-byte copy from varargs'),

    ('LABEL_FF18F3', 'AudioCmd_FormatFloat_Dispatch',
     'Float dispatch: push args, call format sub (eE->sci, fF->fixed, gG->general)'),

    ('LABEL_FF1918', 'AudioCmd_MainLoop_ReadNext',
     'Main loop: read next format char, branch if non-null'),

    # ==================================================================
    # AudioCmd_IntToStr (FF1933) — signed integer to decimal string
    # ==================================================================

    ('LABEL_FF1933', 'AudioCmd_IntToStr',
     'Signed int-to-string: handle negative, then itoa via /10 loop'),

    ('LABEL_FF1948', 'AudioCmd_IntToStr_Positive',
     'Value is positive (or now negated): start divmod loop'),

    ('LABEL_FF194A', 'AudioCmd_IntToStr_DivLoop',
     'Divmod loop: extract digits via DivMod32, store in buffer'),

    # ==================================================================
    # AudioCmd_UIntToStr (FF1983) — unsigned integer to decimal string
    # ==================================================================

    ('LABEL_FF1983', 'AudioCmd_UIntToStr',
     'Unsigned int-to-string: divmod loop without sign handling'),

    ('LABEL_FF1989', 'AudioCmd_UIntToStr_DivLoop',
     'Unsigned divmod loop: extract digits via DivMod32'),

    # ==================================================================
    # AudioCmd_HexToStr (FF19C2) — value to hex string
    # ==================================================================

    ('LABEL_FF19C2', 'AudioCmd_HexToStr',
     'Hex-to-string: select uppercase/lowercase digit table'),

    ('LABEL_FF19D3', 'AudioCmd_HexToStr_TableSelected',
     'Hex digit table selected: start conversion loop'),

    ('LABEL_FF19DB', 'AudioCmd_HexToStr_Loop',
     'Hex loop: extract nibble (AND 0xF), lookup digit, shift right 4'),

    # ==================================================================
    # AudioCmd_OctalToStr (FF19F5) — value to octal string
    # ==================================================================

    ('LABEL_FF19F5', 'AudioCmd_OctalToStr',
     'Octal-to-string: extract 3-bit groups, add 0x30'),

    ('LABEL_FF19FB', 'AudioCmd_OctalToStr_Loop',
     'Octal loop: extract 3 bits (AND 0x7), add 0x30, shift right 3'),

    # ==================================================================
    # AudioCmd_FormatFloat (FF1A17) — float formatting dispatcher
    # Calls format-specific sub-functions for e/E, f/F, or g/G.
    # ==================================================================

    ('LABEL_FF1A17', 'AudioCmd_FormatFloat',
     'Float formatter entry: decompose float, dispatch by specifier'),

    ('LABEL_FF1A60', 'AudioCmd_FormatFloat_eE',
     'Specifier e or E: push args for scientific notation'),

    ('LABEL_FF1A70', 'AudioCmd_FormatFloat_fF_Check',
     'Check for f or F specifier'),

    ('LABEL_FF1A7A', 'AudioCmd_FormatFloat_fF',
     'Specifier f or F: push args for fixed-point'),

    ('LABEL_FF1A88', 'AudioCmd_FormatFloat_fF_Call',
     'Call fixed-point format sub-function'),

    ('LABEL_FF1A90', 'AudioCmd_FormatFloat_gG',
     'Specifier g or G: default precision 6 if not set'),

    ('LABEL_FF1A9D', 'AudioCmd_FormatFloat_gG_Setup',
     'g/G setup: push args, check exponent range for e vs f'),

    ('LABEL_FF1AB9', 'AudioCmd_FormatFloat_gG_UseSci',
     'g/G exponent out of range: use scientific notation'),

    ('LABEL_FF1ABF', 'AudioCmd_FormatFloat_Return',
     'Float formatter return: restore iz, clean stack'),

    # ==================================================================
    # AudioCmd_FormatFFixed (FF1AC4) — fixed-point %f formatter
    # ==================================================================

    ('LABEL_FF1AC4', 'AudioCmd_FormatFFixed',
     'Fixed-point %f formatter entry: set up digit limits'),

    ('LABEL_FF1ADA', 'AudioCmd_FFixed_SetPrecision',
     'Set precision from argument'),

    ('LABEL_FF1AE0', 'AudioCmd_FFixed_CheckDefaults',
     'Check and apply default precision (6) and long-double limit'),

    ('LABEL_FF1AED', 'AudioCmd_FFixed_CheckLongDouble',
     'Check long-double flag (bit 7): set limit to 18 if set'),

    ('LABEL_FF1AFA', 'AudioCmd_FFixed_CheckLongDoubleLimit',
     'Set digit limit to 0x12 (18) for long double'),

    ('LABEL_FF1B16', 'AudioCmd_FFixed_SpecNoUpperCase',
     'Specifier is lowercase: no case conversion'),

    ('LABEL_FF1B18', 'AudioCmd_FFixed_CheckSpecG',
     'Check if specifier is G: adjust precision/digit count'),

    ('LABEL_FF1B22', 'AudioCmd_FFixed_NotG',
     'Not G: add exponent to precision for total digits'),

    ('LABEL_FF1B28', 'AudioCmd_FFixed_RoundCheck',
     'Check if rounding needed: compare iz vs limit'),

    ('LABEL_FF1B42', 'AudioCmd_FFixed_RoundCarry',
     'Rounding: carry propagation, set digit to 0x30'),

    ('LABEL_FF1B4B', 'AudioCmd_FFixed_RoundLoop',
     'Rounding loop: decrement iz, increment digit, check overflow'),

    ('LABEL_FF1B61', 'AudioCmd_FFixed_AfterRound',
     'After rounding: re-check case for leading digit handling'),

    ('LABEL_FF1B6F', 'AudioCmd_FFixed_AfterRound_NoCase',
     'After round, no case conversion'),

    ('LABEL_FF1B71', 'AudioCmd_FFixed_CheckG_StripZeros',
     'G specifier: check if trailing zeros should be stripped'),

    ('LABEL_FF1B83', 'AudioCmd_FFixed_CheckG_AltForm',
     'G with # flag: keep trailing zeros'),

    ('LABEL_FF1B8B', 'AudioCmd_FFixed_CaseApplied',
     'Case conversion applied: check G specifier for zero stripping'),

    ('LABEL_FF1B9A', 'AudioCmd_FFixed_StripZeroLoop',
     'Strip trailing zeros: decrement iz and precision'),

    ('LABEL_FF1B9F', 'AudioCmd_FFixed_StripZeroCheck',
     'Check if current digit is 0x30 (zero): continue stripping'),

    ('LABEL_FF1BAA', 'AudioCmd_FFixed_ComputeOutputLen',
     'Compute output length: precision + sign + decimal point'),

    ('LABEL_FF1BB9', 'AudioCmd_FFixed_CheckPrecZero',
     'Check if precision is zero (no decimal point needed)'),

    ('LABEL_FF1BBC', 'AudioCmd_FFixed_AdjustForSign',
     'Adjust output length for sign character'),

    ('LABEL_FF1BCC', 'AudioCmd_FFixed_AdjustForSign2',
     'Second sign adjustment (force-sign or space flags)'),

    ('LABEL_FF1BCF', 'AudioCmd_FFixed_ComputePadding',
     'Compute padding: subtract digit count from min-width'),

    ('LABEL_FF1BE3', 'AudioCmd_FFixed_CheckOverflow',
     'Check if lead digit > 9: adjust padding'),

    ('LABEL_FF1BEF', 'AudioCmd_FFixed_PadLeftCheck',
     'Check left-align flag for padding direction'),

    ('LABEL_FF1C02', 'AudioCmd_FFixed_PadLeftSpace',
     'Left-pad with spaces, increment output counter'),

    ('LABEL_FF1C11', 'AudioCmd_FFixed_PadLeftLoop',
     'Left-pad loop: decrement count, output space'),

    ('LABEL_FF1C1B', 'AudioCmd_FFixed_EmitSign',
     'Emit sign character (-, +, or space) if needed'),

    ('LABEL_FF1C24', 'AudioCmd_FFixed_SignPlus',
     'Force-sign: output + (0x2B)'),

    ('LABEL_FF1C31', 'AudioCmd_FFixed_SignSpace',
     'Space-sign: output space (0x20)'),

    ('LABEL_FF1C3C', 'AudioCmd_FFixed_SignEmit',
     'Call output callback for sign char'),

    ('LABEL_FF1C48', 'AudioCmd_FFixed_ZeroFill',
     'Check zero-fill padding before digits'),

    ('LABEL_FF1C5B', 'AudioCmd_FFixed_ZeroFillBody',
     'Zero-fill body: output 0x30'),

    ('LABEL_FF1C6A', 'AudioCmd_FFixed_ZeroFillLoop',
     'Zero-fill loop: decrement, output 0'),

    ('LABEL_FF1C74', 'AudioCmd_FFixed_LeadDigit',
     'Output leading digit: handle overflow (>9 -> output 1)'),

    ('LABEL_FF1C95', 'AudioCmd_FFixed_LeadDigitZero',
     'Leading digit zero case: output 0x30'),

    ('LABEL_FF1CA6', 'AudioCmd_FFixed_LeadDigitDone',
     'Leading digit emitted: increment output counter'),

    ('LABEL_FF1CAB', 'AudioCmd_FFixed_IntegerDigits',
     'Output integer part digits from buffer'),

    ('LABEL_FF1CAF', 'AudioCmd_FFixed_IntDigitOutput',
     'Output one integer digit from buffer'),

    ('LABEL_FF1CC8', 'AudioCmd_FFixed_IntDigitLoop',
     'Integer digit loop: check against limit'),

    ('LABEL_FF1CDD', 'AudioCmd_FFixed_IntZeroFill',
     'Fill remaining integer positions with 0x30'),

    ('LABEL_FF1CEC', 'AudioCmd_FFixed_IntZeroLoop',
     'Integer zero-fill loop'),

    ('LABEL_FF1D05', 'AudioCmd_FFixed_DecimalPoint',
     'Output decimal point (0x2E) if precision > 0 or # flag'),

    ('LABEL_FF1D16', 'AudioCmd_FFixed_FracLeadZeros',
     'Fractional leading zeros: fill with 0 before significant digits'),

    ('LABEL_FF1D39', 'AudioCmd_FFixed_FracLeadZeroBody',
     'Fractional zero body: output 0x30'),

    ('LABEL_FF1D43', 'AudioCmd_FFixed_FracLeadZeroDone',
     'Fractional leading zeros done: increment output counter'),

    ('LABEL_FF1D4B', 'AudioCmd_FFixed_FracLeadZeroLoop',
     'Fractional leading zero loop: check exponent'),

    ('LABEL_FF1D5C', 'AudioCmd_FFixed_FracDigits',
     'Output fractional digits from buffer'),

    ('LABEL_FF1D67', 'AudioCmd_FFixed_FracDigitOutput',
     'Output one fractional digit'),

    ('LABEL_FF1D80', 'AudioCmd_FFixed_FracDigitLoop',
     'Fractional digit loop: check against limit'),

    ('LABEL_FF1D95', 'AudioCmd_FFixed_FracTrailZeros',
     'Fractional trailing zeros: fill to precision'),

    ('LABEL_FF1DA4', 'AudioCmd_FFixed_FracTrailLoop',
     'Fractional trailing zero loop'),

    ('LABEL_FF1DB8', 'AudioCmd_FFixed_PadRightSpace',
     'Right-pad with spaces (left-aligned mode)'),

    ('LABEL_FF1DC7', 'AudioCmd_FFixed_PadRightLoop',
     'Right-pad space loop'),

    ('LABEL_FF1DD1', 'AudioCmd_FFixed_Return',
     'Fixed-point formatter return: restore iz, clean stack'),

    ('LABEL_FF1DD5', 'AudioCmd_FFixed_DataTable',
     'Data table for fixed-point formatting (20 bytes)'),

    # ==================================================================
    # AudioCmd_FormatEScientific (FF1DE9) — %e/%E scientific formatter
    # ==================================================================

    ('LABEL_FF1DE9', 'AudioCmd_FormatEScientific',
     'Scientific %e/%E formatter: set up precision and digit limits'),

    ('LABEL_FF1DFE', 'AudioCmd_ESci_ApplyDefaults',
     'Apply default precision (6) if not specified'),

    ('LABEL_FF1E19', 'AudioCmd_ESci_SpecNoUpperCase',
     'Specifier is lowercase: no case conversion'),

    ('LABEL_FF1E1C', 'AudioCmd_ESci_CheckSpecG',
     'Check if specifier is G for general float mode'),

    ('LABEL_FF1E2B', 'AudioCmd_ESci_SetDigitCount',
     'Set total digit count from precision'),

    ('LABEL_FF1E40', 'AudioCmd_ESci_RoundCheck',
     'Check if rounding needed: compare digits vs limit'),

    ('LABEL_FF1E5F', 'AudioCmd_ESci_RoundCarry',
     'Rounding carry: set digit to 0x30, decrement'),

    ('LABEL_FF1E6B', 'AudioCmd_ESci_RoundLoop',
     'Rounding loop: increment digit, check > 9'),

    ('LABEL_FF1E80', 'AudioCmd_ESci_AfterRound',
     'After rounding: re-check case conversion'),

    ('LABEL_FF1E8C', 'AudioCmd_ESci_AfterRound_NoCase',
     'After round, no case needed'),

    ('LABEL_FF1E8F', 'AudioCmd_ESci_StripTrailZeros',
     'G specifier: strip trailing zeros if no # flag'),

    ('LABEL_FF1EA4', 'AudioCmd_ESci_StripLoop',
     'Strip trailing zeros loop: decrement counter and precision'),

    ('LABEL_FF1EAA', 'AudioCmd_ESci_StripCheck',
     'Check if current digit is zero for stripping'),

    ('LABEL_FF1EBA', 'AudioCmd_ESci_ComputeOutputLen',
     'Compute output length: digits + sign + exponent (5 chars)'),

    ('LABEL_FF1ECC', 'AudioCmd_ESci_CheckPrecZero',
     'Check precision zero: no decimal point if zero'),

    ('LABEL_FF1ECF', 'AudioCmd_ESci_AdjustForSign',
     'Adjust for sign character if needed'),

    ('LABEL_FF1EDF', 'AudioCmd_ESci_AdjustForSign2',
     'Second sign adjustment (force-sign or space)'),

    ('LABEL_FF1EE2', 'AudioCmd_ESci_ComputePadding',
     'Compute padding width: min-width minus output length'),

    ('LABEL_FF1EEF', 'AudioCmd_ESci_PadLeftCheck',
     'Check left-align for padding direction'),

    ('LABEL_FF1F02', 'AudioCmd_ESci_PadLeftSpace',
     'Left-pad with spaces'),

    ('LABEL_FF1F11', 'AudioCmd_ESci_PadLeftLoop',
     'Left-pad space loop'),

    ('LABEL_FF1F1B', 'AudioCmd_ESci_EmitSign',
     'Emit sign character (-, +, or space)'),

    ('LABEL_FF1F24', 'AudioCmd_ESci_SignPlus',
     'Force-sign: output +'),

    ('LABEL_FF1F31', 'AudioCmd_ESci_SignSpace',
     'Space-sign: output space'),

    ('LABEL_FF1F3C', 'AudioCmd_ESci_SignEmit',
     'Call output callback for sign'),

    ('LABEL_FF1F48', 'AudioCmd_ESci_ZeroFill',
     'Zero-fill padding before mantissa'),

    ('LABEL_FF1F5B', 'AudioCmd_ESci_ZeroFillBody',
     'Zero-fill body: output 0x30'),

    ('LABEL_FF1F6A', 'AudioCmd_ESci_ZeroFillLoop',
     'Zero-fill loop'),

    ('LABEL_FF1F74', 'AudioCmd_ESci_LeadDigit',
     'Output leading mantissa digit (handle overflow)'),

    ('LABEL_FF1FA0', 'AudioCmd_ESci_Overflow_DecExp',
     'Overflow: decrement exponent'),

    ('LABEL_FF1FA5', 'AudioCmd_ESci_LeadDigitNormal',
     'Normal leading digit: output directly'),

    ('LABEL_FF1FBC', 'AudioCmd_ESci_DecimalPoint',
     'Output decimal point if precision > 0 or # flag'),

    ('LABEL_FF1FCB', 'AudioCmd_ESci_DecimalPointEmit',
     'Emit decimal point (0x2E)'),

    ('LABEL_FF1FDA', 'AudioCmd_ESci_MantissaDigits',
     'Output mantissa digits from buffer'),

    ('LABEL_FF1FF3', 'AudioCmd_ESci_MantissaNoCase',
     'Mantissa no case conversion needed'),

    ('LABEL_FF1FF6', 'AudioCmd_ESci_CheckGTrim',
     'G specifier: check if all zeros trimmed'),

    ('LABEL_FF200A', 'AudioCmd_ESci_OutputMantissa',
     'Start mantissa digit output loop'),

    ('LABEL_FF2018', 'AudioCmd_ESci_MantDigitOutput',
     'Output one mantissa digit from buffer'),

    ('LABEL_FF2032', 'AudioCmd_ESci_MantDigitLoop',
     'Mantissa digit loop: check against count'),

    ('LABEL_FF204A', 'AudioCmd_ESci_MantTrailZeros',
     'Mantissa trailing zeros: fill to precision'),

    ('LABEL_FF2059', 'AudioCmd_ESci_MantTrailLoop',
     'Mantissa trailing zero loop'),

    ('LABEL_FF2099', 'AudioCmd_ESci_ExpNoCase',
     'Exponent: no case conversion needed'),

    ('LABEL_FF209C', 'AudioCmd_ESci_CheckExpG',
     'Check if G specifier adjusts exponent format'),

    ('LABEL_FF20A8', 'AudioCmd_ESci_ExpLetterNormal',
     'Normal exponent letter (e or E)'),

    ('LABEL_FF20AB', 'AudioCmd_ESci_EmitExpLetter',
     'Emit exponent letter (e/E/g-2)'),

    ('LABEL_FF20C6', 'AudioCmd_ESci_ExpSignPositive',
     'Exponent sign positive: output +'),

    ('LABEL_FF20C9', 'AudioCmd_ESci_EmitExpSign',
     'Emit exponent sign via callback'),

    ('LABEL_FF20DA', 'AudioCmd_ESci_ExpLeadZeros',
     'Exponent leading zeros: pad to 3 digits'),

    ('LABEL_FF20E9', 'AudioCmd_ESci_ExpLeadZeroLoop',
     'Exponent leading zero loop'),

    ('LABEL_FF20F5', 'AudioCmd_ESci_ExpDigitOutput',
     'Output exponent digits from buffer'),

    ('LABEL_FF210E', 'AudioCmd_ESci_ExpDigitLoop',
     'Exponent digit output loop'),

    ('LABEL_FF211C', 'AudioCmd_ESci_PadRightSpace',
     'Right-pad with spaces (left-aligned mode)'),

    ('LABEL_FF212B', 'AudioCmd_ESci_PadRightLoop',
     'Right-pad space loop'),

    ('LABEL_FF2135', 'AudioCmd_ESci_Return',
     'Scientific formatter return: restore iz, clean stack'),

    # ==================================================================
    # AudioCmd_FormatGGeneral (FF2139) — %g/%G general float formatter
    # Decomposes float, selects between f and e format.
    # ==================================================================

    ('LABEL_FF2139', 'AudioCmd_FormatGGeneral',
     'General %g/%G formatter: decompose float, set up digit arrays'),

    ('LABEL_FF215E', 'AudioCmd_GGen_ClearArrays',
     'Clear digit arrays (0x03C244 and 0x03C284)'),

    ('LABEL_FF2197', 'AudioCmd_GGen_CheckLongDouble',
     'Check long-double flag: adjust limits (8 -> 10 digits)'),

    ('LABEL_FF21A1', 'AudioCmd_GGen_LoadDigits',
     'Load float digits into array from mantissa buffer'),

    ('LABEL_FF21C3', 'AudioCmd_GGen_CheckSign',
     'Check sign bit of mantissa for negative flag'),

    ('LABEL_FF21CE', 'AudioCmd_GGen_Negative',
     'Float is negative: set sign = 1'),

    ('LABEL_FF21D0', 'AudioCmd_GGen_ExtractExponent',
     'Extract exponent from decomposed float'),

    ('LABEL_FF21EA', 'AudioCmd_GGen_LongDoubleExp',
     'Long-double exponent extraction (8-bit + bias 0x4000)'),

    ('LABEL_FF21F6', 'AudioCmd_GGen_NormalExp',
     'Normal float: check for zero mantissa'),

    ('LABEL_FF2200', 'AudioCmd_GGen_NonZero',
     'Non-zero mantissa: extract 4-bit exponent + bias 0x400'),

    ('LABEL_FF220F', 'AudioCmd_GGen_ComputeDecExp',
     'Compute decimal exponent from binary exponent'),

    ('LABEL_FF221D', 'AudioCmd_GGen_ShiftMantissa',
     'Shift mantissa if exponent bits non-zero'),

    ('LABEL_FF2223', 'AudioCmd_GGen_DecimalExponent',
     'Call decimal exponent calculator'),

    ('LABEL_FF2233', 'AudioCmd_GGen_AdjustNegExp',
     'Adjust for negative exponent'),

    ('LABEL_FF223E', 'AudioCmd_GGen_LongDoubleDigits',
     'Long-double: load all 10 digit pairs into array'),

    ('LABEL_FF2266', 'AudioCmd_GGen_NormalDigits',
     'Normal float: load 8 digit pairs, find leading non-zero'),

    ('LABEL_FF226B', 'AudioCmd_GGen_FindLeadDigit',
     'Find first non-zero digit in array'),

    ('LABEL_FF227A', 'AudioCmd_GGen_FindLeadDone',
     'Leading digit found or array exhausted'),

    ('LABEL_FF2284', 'AudioCmd_GGen_LoadDigitPairs',
     'Load digit pairs into working array (0x03C244)'),

    ('LABEL_FF228B', 'AudioCmd_GGen_DigitPairLoop',
     'Digit pair loading loop'),

    ('LABEL_FF22B8', 'AudioCmd_GGen_NormalizeArray',
     'Normalize digit array: count leading zeros'),

    ('LABEL_FF22D4', 'AudioCmd_GGen_MultiplyLoop',
     'Multiply digit array by 10 to shift left (positive exponent)'),

    ('LABEL_FF22F9', 'AudioCmd_GGen_PositiveExpDone',
     'Positive exponent shifting done: compute remaining'),

    ('LABEL_FF2309', 'AudioCmd_GGen_DivideLoop',
     'Divide digit array by 10 to shift right (negative exponent)'),

    ('LABEL_FF2321', 'AudioCmd_GGen_NegativeExpCheck',
     'Negative exponent: check loop continuation'),

    ('LABEL_FF233B', 'AudioCmd_GGen_FinalShift',
     'Final digit array shift for alignment'),

    ('LABEL_FF2343', 'AudioCmd_GGen_RoundLoop',
     'Rounding loop: process each digit position'),

    ('LABEL_FF2383', 'AudioCmd_GGen_ExtractResult',
     'Extract formatted result from digit array'),

    ('LABEL_FF239F', 'AudioCmd_GGen_CopyDigits',
     'Copy digit values to output buffer (0x03C224)'),

    ('LABEL_FF23B5', 'AudioCmd_GGen_CopyLoop',
     'Digit copy loop'),

    ('LABEL_FF23D8', 'AudioCmd_GGen_HandleCarry',
     'Handle carry from rounding (digit > 9)'),

    ('LABEL_FF23E3', 'AudioCmd_GGen_CarryLoop',
     'Carry propagation loop: increment higher digit'),

    ('LABEL_FF23F3', 'AudioCmd_GGen_CarryCheck',
     'Check if carry needed at current position'),

    ('LABEL_FF2402', 'AudioCmd_GGen_ConvertToAscii',
     'Convert digit values to ASCII (OR with 0x30)'),

    ('LABEL_FF2407', 'AudioCmd_GGen_AsciiLoop',
     'ASCII conversion loop'),

    ('LABEL_FF2410', 'AudioCmd_GGen_AsciiDone',
     'ASCII conversion done: store exponent and return'),

    # ==================================================================
    # AudioCmd_ShiftDigitArray (FF2424) — shift digit array with carry
    # ==================================================================

    ('LABEL_FF2424', 'AudioCmd_ShiftDigitArray',
     'Shift digit array: build mask, shift entries with carry'),

    ('LABEL_FF2432', 'AudioCmd_Shift_BuildMask',
     'Build bit mask for shift amount'),

    ('LABEL_FF243D', 'AudioCmd_Shift_SetupLoop',
     'Set up shift loop from high digit to low'),

    ('LABEL_FF245C', 'AudioCmd_Shift_Loop',
     'Shift loop: shift current entry, carry from previous'),

    ('LABEL_FF2470', 'AudioCmd_Shift_ApplyShift',
     'Apply right-shift to current digit pair'),

    ('LABEL_FF248B', 'AudioCmd_Shift_ApplyCarry',
     'Apply carry bits from lower digit to upper'),

    ('LABEL_FF2498', 'AudioCmd_Shift_LastEntry',
     'Process last (lowest) digit entry'),

    ('LABEL_FF24A3', 'AudioCmd_Shift_LastShift',
     'Shift last entry and return'),

    # ==================================================================
    # AudioCmd_PropagateCarry (FF24A9) — carry propagation helper
    # ==================================================================

    ('LABEL_FF24A9', 'AudioCmd_PropagateCarry',
     'Propagate carry through digit array after multiplication'),

    ('LABEL_FF24B9', 'AudioCmd_PropCarry_Loop',
     'Carry propagation loop: shift, add overflow to next'),

    ('LABEL_FF24CD', 'AudioCmd_PropCarry_Store',
     'Store shifted digit, extract overflow'),

    ('LABEL_FF24E8', 'AudioCmd_PropCarry_Check',
     'Check loop termination'),

    # ==================================================================
    # AudioCmd_NormalizeDigits (FF24ED) — digit normalization/rounding
    # ==================================================================

    ('LABEL_FF24ED', 'AudioCmd_NormalizeDigits',
     'Normalize digit array: clear BCD buffer, add rounding offset'),

    ('LABEL_FF24F8', 'AudioCmd_Normalize_ClearLoop',
     'Clear BCD accumulator array'),

    ('LABEL_FF2509', 'AudioCmd_Normalize_MainLoop',
     'Main normalization loop: check for all-zero and process digits'),

    ('LABEL_FF254E', 'AudioCmd_Normalize_MultiplyTen',
     'Multiply digit array by 10 (shift left one decimal place)'),

    ('LABEL_FF2553', 'AudioCmd_Normalize_ExtractDigit',
     'Extract current leading digit from array'),

    ('LABEL_FF258B', 'AudioCmd_Normalize_Done',
     'Normalization complete: restore iz and return'),

    # ==================================================================
    # AudioCmd_InsertCarry (FF258D) — carry insertion after digit add
    # ==================================================================

    ('LABEL_FF258D', 'AudioCmd_InsertCarry',
     'Insert carry into digit array at specified position'),

    ('LABEL_FF25A3', 'AudioCmd_InsertCarry_Clamp',
     'Clamp insertion position to array bounds'),

    ('LABEL_FF25A5', 'AudioCmd_InsertCarry_ClampLoop',
     'Clamp loop: decrement position until in range'),

    ('LABEL_FF25A7', 'AudioCmd_InsertCarry_Check',
     'Check if position is within digit array'),

    ('LABEL_FF25B4', 'AudioCmd_InsertCarry_Propagate',
     'Propagate carry: increment digit, subtract 10 if >= 10'),

    ('LABEL_FF25C7', 'AudioCmd_InsertCarry_PropCheck',
     'Check if carry propagation needed (digit >= 10)'),

    # ==================================================================
    # AudioCmd_DivideDigitsByTen (FF25D4) — divide array by 10
    # ==================================================================

    ('LABEL_FF25D4', 'AudioCmd_DivideDigitsByTen',
     'Divide digit array by 10: shift all entries right'),

    ('LABEL_FF25DC', 'AudioCmd_DivByTen_Loop',
     'Divide loop: divmod each entry, carry remainder to next'),

    # ==================================================================
    # AudioCmd_MultiplyDigitsByTen (FF25FD) — multiply array by 10
    # ==================================================================

    ('LABEL_FF25FD', 'AudioCmd_MultiplyDigitsByTen',
     'Multiply digit array by 10 with carry propagation'),

    ('LABEL_FF2602', 'AudioCmd_MulByTen_Loop',
     'Multiply loop: mul each entry by 10, propagate overflow'),

    ('LABEL_FF2619', 'AudioCmd_MulByTen_CarryLoop',
     'Carry loop: propagate overflow to higher entries'),

    ('LABEL_FF262E', 'AudioCmd_MulByTen_CarryCheck',
     'Check if carry overflow exists (> 0xFF)'),

    ('LABEL_FF2642', 'AudioCmd_MulByTen_Next',
     'Next entry in multiply loop'),

    ('LABEL_FF2659', 'AudioCmd_MulByTen_HandleOverflow',
     'Handle top-entry overflow: increment count if bit 7 set'),

    # ==================================================================
    # AudioCmd_MultiplyBCDByTen (FF265F) — BCD buffer multiply
    # ==================================================================

    ('LABEL_FF265F', 'AudioCmd_MultiplyBCDByTen',
     'Multiply BCD accumulator buffer by 10'),

    ('LABEL_FF2669', 'AudioCmd_BCDMul_Loop',
     'BCD multiply loop: mul each pair by 10'),

    ('LABEL_FF2677', 'AudioCmd_BCDMul_Skip',
     'Skip zero entries in BCD multiply'),

    ('LABEL_FF2683', 'AudioCmd_BCDMul_CarryLoop',
     'BCD carry propagation: handle overflow > 0xFF'),

    ('LABEL_FF269B', 'AudioCmd_BCDMul_Next',
     'Next entry in BCD carry loop'),

    # ==================================================================
    # AudioCmd_CountLeadingZeros (FF26A4) — count leading zero digits
    # ==================================================================

    ('LABEL_FF26A4', 'AudioCmd_CountLeadingZeros',
     'Count leading zero entries in digit array'),

    ('LABEL_FF26B0', 'AudioCmd_LeadZero_Loop',
     'Leading zero loop: scan until non-zero found'),

    ('LABEL_FF26C6', 'AudioCmd_LeadZero_CheckAllZero',
     'Check if all entries were zero'),

    ('LABEL_FF26CF', 'AudioCmd_LeadZero_CountBits',
     'Non-zero found: count shift bits needed'),

    ('LABEL_FF26D6', 'AudioCmd_LeadZero_ShiftLoop',
     'Shift loop: count high bits needing alignment'),

    ('LABEL_FF26DD', 'AudioCmd_LeadZero_ShiftBody',
     'Shift body: process array entries'),

    ('LABEL_FF26E4', 'AudioCmd_LeadZero_CheckBit7',
     'Check if bit 7 set (entry needs shifting)'),

    ('LABEL_FF26F1', 'AudioCmd_LeadZero_ApplyShift',
     'Apply shift if needed via PropagateCarry helper'),

    ('LABEL_FF2702', 'AudioCmd_LeadZero_AccumShift',
     'Accumulate total shift count'),

    ('LABEL_FF2705', 'AudioCmd_LeadZero_OuterLoop',
     'Outer loop: continue until no more high bits'),

    ('LABEL_FF2712', 'AudioCmd_LeadZero_Return',
     'Return total leading zero count in hl'),

    # ==================================================================
    # AudioCmd_CountTrailingZeros (FF2716) — count trailing zero digits
    # ==================================================================

    ('LABEL_FF2716', 'AudioCmd_CountTrailingZeros',
     'Count trailing zero entries in digit array'),

    ('LABEL_FF2723', 'AudioCmd_TrailZero_Loop',
     'Trailing zero scan loop from start'),

    ('LABEL_FF2737', 'AudioCmd_TrailZero_CheckAllZero',
     'Check if all entries were zero'),

    ('LABEL_FF273F', 'AudioCmd_TrailZero_CountBits',
     'Count trailing bit positions needing shift'),

    ('LABEL_FF2745', 'AudioCmd_TrailZero_ShiftLoop',
     'Shift loop: count low bits'),

    ('LABEL_FF274A', 'AudioCmd_TrailZero_CheckHigh',
     'Check if high byte is non-zero'),

    ('LABEL_FF2758', 'AudioCmd_TrailZero_ApplyShift',
     'Apply alignment shift if needed'),

    ('LABEL_FF2764', 'AudioCmd_TrailZero_Done',
     'Return trailing zero count in hl'),

    ('LABEL_FF2766', 'AudioCmd_TrailZero_Return',
     'Restore iz and return'),

    # ==================================================================
    # AudioCmd_DecimalExponent (FF2768) — decimal exponent calculation
    # Computes floor(log10(abs(x))) for float formatting.
    # ==================================================================

    ('LABEL_FF2768', 'AudioCmd_DecimalExponent',
     'Compute decimal exponent via multiply-accumulate with log10(2)'),

    ('LABEL_FF2790', 'AudioCmd_DecExp_Positive',
     'Exponent is positive: store directly'),

    ('LABEL_FF2793', 'AudioCmd_DecExp_ComputeQuotient',
     'Divide by 1000 to get approximate decimal exponent'),

    ('LABEL_FF27BE', 'AudioCmd_DecExp_CheckRemainder',
     'Check remainder: round up if > 0x3D4 (980)'),

    ('LABEL_FF27D2', 'AudioCmd_DecExp_ApplySign',
     'Apply sign to computed exponent'),

    ('LABEL_FF27E6', 'AudioCmd_DecExp_Positive_Return',
     'Positive exponent: return in xhl'),

    ('LABEL_FF27E8', 'AudioCmd_DecExp_Return',
     'Decimal exponent return'),

    # ==================================================================
    # Helper functions (FF27EC-FF292E) — memory copy, itoa, string ops
    # ==================================================================

    ('LABEL_FF27EC', 'AudioCmd_CopyBytes8',
     'Copy 8 bytes from (xbc) to (xwa) (two 32-bit loads)'),

    ('LABEL_FF27F7', 'AudioCmd_ItoaBaseN',
     'Integer-to-string with arbitrary base (2-36)'),

    ('LABEL_FF2809', 'AudioCmd_ItoaBaseN_Invalid',
     'Invalid base (< 2 or > 36): store null and return'),

    ('LABEL_FF2811', 'AudioCmd_ItoaBaseN_Setup',
     'Set up itoa buffer and division loop'),

    ('LABEL_FF2827', 'AudioCmd_ItoaBaseN_DivLoop',
     'Itoa divmod loop: extract digit, check > 9 for alpha'),

    ('LABEL_FF2848', 'AudioCmd_ItoaBaseN_StoreDigit',
     'Store digit: add 0x27 offset if > 9 (a-z)'),

    ('LABEL_FF285E', 'AudioCmd_ItoaBaseN_Reverse',
     'Reverse digit buffer to correct order'),

    ('LABEL_FF2877', 'AudioCmd_ItoaBaseN_Return',
     'Itoa return: pointer to result in xhl'),

    ('LABEL_FF287F', 'AudioCmd_ItoaBaseN_Pad',
     'Padding byte (0xFF) between functions'),

    ('LABEL_FF2880', 'AudioCmd_CopyBytes10',
     'Copy 10 bytes from (xbc) to (xwa) (two 32-bit + one 16-bit)'),

    ('LABEL_FF2891', 'AudioCmd_StringNSearch',
     'Search for char in string with length limit'),

    ('LABEL_FF28B2', 'AudioCmd_StringNSearch_Found',
     'Char found: compute position from pointer difference'),

    ('LABEL_FF28BB', 'AudioCmd_StringNSearch_Copy',
     'Copy result string segment to output'),

    ('LABEL_FF28D1', 'AudioCmd_MemChr',
     'Memory search for byte (like memchr): scan bc bytes for wa'),

    ('LABEL_FF28E9', 'AudioCmd_DataBlock_28E9',
     'Data block between functions (32 bytes)'),

    ('LABEL_FF2909', 'AudioCmd_StringLength',
     'Compute string length (like strlen) and find char'),

    ('LABEL_FF2924', 'AudioCmd_StrLen_ScanLoop',
     'String scan loop: compare each byte'),

    ('LABEL_FF292C', 'AudioCmd_StrLen_NotFound',
     'Character not found: return 0'),

    ('LABEL_FF292E', 'AudioCmd_StrLen_Return',
     'String length return'),

    ('LABEL_FF2930', 'AudioCmd_FillToEnd',
     'Fill region to end of ROM space (0xFF padding)'),

    ('LABEL_FFCCE8', 'AudioCmd_FillToVectors',
     'Fill region before interrupt vectors (0xFF padding)'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')
    renamed = 0
    for old_label, new_label, comment in RENAMES:
        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        if refs == 0:
            print(f'  WARNING: {old_label} not found, skipping')
            continue
        content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
        renamed += 1
        print(f'  {old_label:25s} -> {new_label:45s} ({refs} refs)')
    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))
    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
