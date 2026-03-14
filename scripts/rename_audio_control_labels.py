#!/usr/bin/env python3
"""
Rename LABEL_XXXXXX to semantic names in audio_control_engine.s and all referencing files.
Uses binary I/O to preserve Latin-1 bytes.
"""

import os
import sys
import subprocess

REPO = '/mnt/shared/kn5000-roms-disasm'

# Map: old_label -> new_label
# Only labels where purpose is confidently determined from code analysis
RENAMES = {
    # === Voice entry search/scan functions ===
    'LABEL_FC693D': 'VoiceEntry_FindMasterVolume',     # Searches voice entries for 0x98/0x01/0x7F pattern (master volume CC)
    'LABEL_FC6947': 'VoiceEntry_CheckMatch',           # Compares voice entry fields at (xde)
    'LABEL_FC6960': 'VoiceEntry_SaveMatch',             # Saves matched entry pointer to xbc
    'LABEL_FC696C': 'VoiceEntry_CheckTerminator',       # Checks if entry is 0xFF terminator

    # === Audio state copy/init functions ===
    'LABEL_FC6972': 'Audio_CopyStateFromROM',           # Copies audio state from ROM table (0xeda020) to DRAM
    'LABEL_FC6983': 'AudioCopy_TransferLoop',           # Loop body: ldiw pairs, incrementing source/dest

    # === Stub return labels (unused/placeholder handlers) ===
    'LABEL_FC6994': 'Audio_NullHandler_A',              # Single ret - null handler A
    'LABEL_FC6995': 'Audio_NullHandler_B',              # Single ret - null handler B
    'LABEL_FC6996': 'Audio_NullHandler_C',              # Single ret - null handler C

    # === Encoder timing ===
    'LABEL_FC69A9': 'Encoder_CheckTimerDelta',          # Loads timer and computes delta from stored value
    'LABEL_FC69BE': 'Encoder_CheckBitAndProcess',       # Tests bit 0 of timer counter
    'LABEL_FC69C4': 'Encoder_ProcessUpdate',            # Calls the audio update routine
    'LABEL_FC69C7': 'Encoder_IncrementAndDispatch',     # Increments counter and dispatches
    'LABEL_FC69D7': 'Audio_PeriodicUpdate',             # Called periodically: stores timer, processes MIDI/voice/params
    'LABEL_FC69EE': 'Audio_ProcessVoiceQueue',          # Processes queued voice entries
    'LABEL_FC69FA': 'VoiceQueue_ParseNextEntry',        # Loop: parse MIDI params then setup voice
    'LABEL_FC6A10': 'VoiceQueue_Done',                  # Pop xiz and return

    # === MIDI helpers ===
    'LABEL_FC6A53': 'MIDI_ProcessVoiceAssignment',      # Voice assignment processing after MIDI parse
    'LABEL_FC6A7C': 'MIDI_ValidateParam',               # Validates MIDI parameter
    'LABEL_FC6A94': 'MIDI_WriteSecondByte',             # Writes second byte of MIDI param
    'LABEL_FC6ABC': 'MIDI_ChannelSetup_Skip',           # Skip/branch in channel setup
    'LABEL_FC6ABE': 'MIDI_ChannelSetup_Store',          # Store to channel setup buffer
    'LABEL_FC6AD7': 'MIDI_ChannelSetup_Init',           # Initialize channel setup
    'LABEL_FC6B1C': 'MIDI_ProcessControlChange',        # Processes MIDI control change messages
    'LABEL_FC6B46': 'MidiCC_ProcessParam',              # Process a CC parameter
    'LABEL_FC6B6B': 'MidiCC_SkipEntry',                 # Skip this CC entry
    'LABEL_FC6B6D': 'MidiCC_LookupHandler',             # Lookup CC handler by number
    'LABEL_FC6BD3': 'MidiCC_ValidateRange',             # Validate CC value range
    'LABEL_FC6BEF': 'MidiCC_StoreAndDispatch',          # Store CC value and dispatch
    'LABEL_FC6C03': 'MidiCC_CheckOverflow',             # Check for CC value overflow
    'LABEL_FC6C0B': 'MidiCC_Finalize',                  # Finalize CC processing
    'LABEL_FC6C29': 'MidiCC_Return',                    # Return from CC processing
    'LABEL_FC6C2B': 'MidiCC_ReturnClean',               # Clean return from CC processing
    'LABEL_FC6C4F': 'MidiCC_SyncForceResync',           # Entry to force resync from CC
    'LABEL_FC6C54': 'MidiCC_ResetState',                # Reset MIDI CC state

    # === MIDI changed channel processing ===
    'LABEL_FC7000': 'Audio_UpdateLEDsAndChannels',      # Calls channel init then ORs LED flag
    'LABEL_FC702E': 'MidiChanged_ProcessGroup2',        # Process second changed channel group (36670)
    'LABEL_FC7048': 'MidiChanged_ProcessGroup3',        # Process third changed channel group (36674)
    'LABEL_FC7062': 'MidiChanged_ProcessGroup4',        # Process fourth changed channel group (36678)
    'LABEL_FC7094': 'MidiDispatch_CheckGroup2',         # Dispatch: check group 2 (36672)
    'LABEL_FC70A4': 'MidiDispatch_CheckGroup3',         # Dispatch: check group 3 (36676)
    'LABEL_FC70B4': 'MidiDispatch_CheckGroup4',         # Dispatch: check group 4 (36680)
    'LABEL_FC70C4': 'MidiDispatch_UpdateLEDs',          # Jump to LED update routine
    'LABEL_FC70C7': 'Audio_InitChannelTimers',          # Initialize 6 channel timer slots to 5
    'LABEL_FC70E6': 'Audio_IncrementUpdateCounter',     # Increment the periodic update counter (36682)
    'LABEL_FC70EB': 'Audio_CheckAndFlagChanges',        # Check audio state and flag changes (reads F9A541, selection state)
    'LABEL_FC70FF': 'AudioChange_CheckSelectionState',  # Part of change detection: CtrlPanel_GetSelectionState
    'LABEL_FC7113': 'AudioChange_UpdatePreviousSelect', # Update previous selection state on change
    'LABEL_FC7120': 'AudioChange_SetChannelFlag',       # Set flag in channel group 3 (36674)

    # === Bitmask dispatch helpers ===
    'LABEL_FC7145': 'BitmaskDispatch_NextEntry',        # Advance to next entry in bitmask dispatch table
    'LABEL_FC714D': 'BitmaskDispatch_Return',           # Return from bitmask dispatch

    # === LED update routine ===
    'LABEL_FC7151': 'CtrlPanel_UpdateLEDState',         # Update control panel LED state from channel data
    'LABEL_FC716E': 'LEDUpdate_ProcessChannel',         # Process one LED channel in update loop
    'LABEL_FC71A3': 'LEDUpdate_NextChannel',            # Advance to next channel in LED update
    'LABEL_FC71AC': 'LEDUpdate_Cleanup',                # Cleanup and return from LED update

    # === LED write subroutines ===
    'LABEL_FC71D2': 'LED_WriteToPanel',                 # Write LED pattern to control panel via Seq_TimerEventLoop/CPanel_Poll
    'LABEL_FC71F6': 'LED_WriteSecondByte',              # Write second byte of LED data
    'LABEL_FC7217': 'LED_WriteThirdByte',               # Write third byte of LED data
    'LABEL_FC7222': 'LED_WriteDone',                    # Pop and return from LED write

    # === Sound parameter bit manipulation (SndParam_LookupReadOnly + set/res bit) ===
    'LABEL_FC7224': 'SndParam_SetResBit0_Via028100',    # Lookup 0x028100, set/res bit 0 at (xwa)
    'LABEL_FC7241': 'SndParam_SetResBit1_Via028100_028101', # Lookup 0x028100+0x028101, set/res bit 1
    'LABEL_FC726A': 'SndParam_SetResBit2_Via028101_028102', # Lookup 0x028101+0x028102, set/res bit 2
    'LABEL_FC7293': 'SndParam_SetResBit3_Via028101_028102', # Lookup 0x028101+0x028102, set/res bit 3
    'LABEL_FC72BC': 'SndParam_SetResBit3_Via4002',      # Lookup 0x4002, set/res bit 3 at (xwa) via xiz+6
    'LABEL_FC72D9': 'SndParam_SetResBit4_Via4004',      # Lookup 0x4004, set/res bit 4 at (xwa) via xiz+6
    'LABEL_FC72F6': 'SndParam_TableLookup_Via4100',     # Lookup 0x4100, table at 0xEDA626, nibble merge
    'LABEL_FC731D': 'SndParam_SetResBit1_ViaPartCC5E',  # Part-based CC 0x5E, set/res bit 1
    'LABEL_FC7342': 'SndParam_SetResBit2_ViaPartCC5D',  # Part-based CC 0x5D, set/res bit 2
    'LABEL_FC7379': 'SndParam_SetResBit0_ViaPartCC40',  # Part-based CC 0x40, set/res bit 0
    'LABEL_FC739E': 'SndParam_GuardedNibbleSet_028103', # Guarded nibble set via 0x028103
    'LABEL_FC73D9': 'SndParam_SetResBit0_Via028103',    # Lookup 0x028103, set/res bit 0 at xiz+13
    'LABEL_FC73F6': 'SndParam_SetResBit5_Via028080',    # Lookup 0x028080, set/res bit 5 at xiz+3
    'LABEL_FC7413': 'SndParam_VoiceEntryLookup_028000', # 3x lookup (028000/028001/028002), nibble merge
    'LABEL_FC746E': 'SndParam_SetResBit7_Via4200',      # Lookup 0x4200, set/res bit 7 at xiz+10
    'LABEL_FC748B': 'SndParam_MaskShiftMerge_8F58',     # Read 0x8F58, mask+shift, merge into 0x8F1C
    'LABEL_FC749F': 'SndParam_DecrLookup_Via0300',      # Lookup 0x300, dec+mask+lookup indicator
    'LABEL_FC74C7': 'SndParam_SetResBit4_Via0400',      # Lookup 0x400, set/res bit 4
    'LABEL_FC74E4': 'SndParam_SetResBit7_ViaSelection', # Via CtrlPanel_GetSelectionState, set/res bit 7
    'LABEL_FC7501': 'SndParam_SetResBit7_ViaF9A541',    # Via LABEL_F9A541, set/res bit 7

    # === Branch targets in set/res bit routines ===
    'LABEL_FC723D': 'SndParam028100_ResBit0',
    'LABEL_FC723F': 'SndParam028100_Done',
    'LABEL_FC7260': 'SndParam028101_SetBit1',
    'LABEL_FC7265': 'SndParam028101_ResBit1',
    'LABEL_FC7268': 'SndParam028101_Done',
    'LABEL_FC7289': 'SndParam028102_SetBit2',
    'LABEL_FC728E': 'SndParam028102_ResBit2',
    'LABEL_FC7291': 'SndParam028102_Done',
    'LABEL_FC72B2': 'SndParam028102_SetBit3',
    'LABEL_FC72B7': 'SndParam028102_ResBit3',
    'LABEL_FC72BA': 'SndParam028102_Done2',
    'LABEL_FC72D5': 'SndParam4002_ResBit3',
    'LABEL_FC72D7': 'SndParam4002_Done',
    'LABEL_FC72F2': 'SndParam4004_ResBit4',
    'LABEL_FC72F4': 'SndParam4004_Done',
    'LABEL_FC731D': 'SndParam_SetResBit1_ViaPartCC5E',  # Already in main list
    'LABEL_FC733E': 'SndParamCC5E_ResBit1',
    'LABEL_FC7340': 'SndParamCC5E_Done',
    'LABEL_FC736F': 'SndParamCC5D_ResBit2',
    'LABEL_FC7374': 'SndParamCC5D_SetBit2',
    'LABEL_FC7377': 'SndParamCC5D_Done',
    'LABEL_FC739A': 'SndParamCC40_ResBit0',
    'LABEL_FC739C': 'SndParamCC40_Done',
    'LABEL_FC73F2': 'SndParam028103_ResBit0',
    'LABEL_FC73F4': 'SndParam028103_Done',
    'LABEL_FC740F': 'SndParam028080_SetBit5',
    'LABEL_FC7411': 'SndParam028080_Done',
    'LABEL_FC7454': 'SndParam028000_GetBankBit',
    'LABEL_FC745C': 'SndParam028000_LookupAndMerge',
    'LABEL_FC7487': 'SndParam4200_ResBit7',
    'LABEL_FC7489': 'SndParam4200_Done',
    'LABEL_FC74B5': 'SndParam0300_DecrAndMask',
    'LABEL_FC74C2': 'SndParam0300_StoreLookup',
    'LABEL_FC74E0': 'SndParam0400_ResBit4',
    'LABEL_FC74E2': 'SndParam0400_Done',
    'LABEL_FC74FD': 'SndParamSelect_SetBit7',
    'LABEL_FC7515': 'SndParamF9A541_ResBit7',
    'LABEL_FC7517': 'SndParamF9A541_Done',

    # === CtrlPanel indicator group branches ===
    'LABEL_FC796E': 'CtrlPanel_SetIndicator_Group2',    # OR into 36670
    'LABEL_FC7974': 'CtrlPanel_SetIndicator_Group3',    # OR into 36674
    'LABEL_FC797A': 'CtrlPanel_SetIndicator_Group4',    # OR into 36678
    'LABEL_FC79B3': 'CtrlPanel_DispIndicator_Group2',   # OR into 36672
    'LABEL_FC79B9': 'CtrlPanel_DispIndicator_Group3',   # OR into 36676
    'LABEL_FC79BF': 'CtrlPanel_DispIndicator_Group4',   # OR into 36680
    'LABEL_FC7A04': 'CtrlPanel_SetLED_Group3',          # AND 36676, OR 36674

    # === MIDI channel output state ===
    'LABEL_FC7A35': 'MidiChOut_CheckHWState',           # Check hardware bit state
    'LABEL_FC7A52': 'MidiChOut_Mode6or3_Mask7',         # Mode 6 or 3: mask with 0x7
    'LABEL_FC7A5C': 'MidiChOut_OtherMode_Mask3',        # Other modes: mask with 0x3
    'LABEL_FC7A64': 'MidiChOut_TableLookup',            # Table lookup and apply to output
    'LABEL_FC7A75': 'MidiChOut_CheckBit1Clear',         # Check if bit 1 needs clearing
    'LABEL_FC7A83': 'MidiChOut_ClearLowNibble',         # Clear low nibble of output
    'LABEL_FC7A88': 'MidiChOut_DetectChanges',          # Detect changes in MIDI channel output state
    'LABEL_FC7AF0': 'MidiScan_CheckBit2InAddr1057',     # Check bit 2 at address 1057
    'LABEL_FC7AF6': 'MidiScan_ClearAndReturn',          # Clear low nibble and return
    'LABEL_FC7AFB': 'MidiScan_AltPathCheck',            # Alternative path check

    # === UI state control bit handlers ===
    'LABEL_FC7B2C': 'UIState_SwitchOnDisplayMode',      # Switch on A=(0xC07D), or bits
    'LABEL_FC7B4C': 'UIState_Mode0or1',                 # Mode 0/1: OR 0x006F
    'LABEL_FC7B53': 'UIState_Mode3',                    # Mode 3: OR 0x0200
    'LABEL_FC7B5A': 'UIState_Mode4',                    # Mode 4: OR 0x8000
    'LABEL_FC7BBB': 'UIState_SwitchForMidiFlags',       # Switch for MIDI channel flags
    'LABEL_FC7BD1': 'UIState_MidiMode6',                # MIDI mode 6: OR 0x0400
    'LABEL_FC7BD8': 'UIState_MidiMode3F',               # MIDI mode 0x3F: OR 0x0800
    'LABEL_FC7BDF': 'UIState_MidiMode4',                # MIDI mode 4: OR 0x0002
    'LABEL_FC7BE6': 'UIState_MidiMode14',               # MIDI mode 0x14: OR 0x1000
    'LABEL_FC7BED': 'UIState_NullReturn',               # Null return
    'LABEL_FC7B61': 'UIState_ProcessExtendedMode',      # Extended mode processing
    'LABEL_FC7BEE': 'UIState_ProcessAltMode',           # Alternative mode processing
    'LABEL_FC7C14': 'UIState_ProcessSimpleMode',        # Simple mode processing

    # === Utility ===
    'LABEL_FC7C33': 'Util_FindLowestSetBit',            # Find lowest set bit position in xwa
    'LABEL_FC7C3E': 'FindBit_ShiftLoop',                # Shift right and check bit 0

    # === Audio initialization ===
    'LABEL_FC7C49': 'Audio_InitAllDefaults',            # Initialize all audio defaults (255/0 patterns to many addresses)
    'LABEL_FC7CA9': 'AudioInit_FillLoop',               # Fill loop with 0xE050 pattern
    'LABEL_FC7CB9': 'Audio_ResetAfterPayloadError',     # Check SubCPU payload error, reinit if needed
    'LABEL_FC7CF0': 'Audio_ReinitDisplay',              # Reinit display and render
    'LABEL_FC7CFA': 'Audio_ReinitToneGen',              # Reinit tone gen, DSP, tempo
    'LABEL_FC7D23': 'Audio_FillParamBuffer',            # Fill parameter buffer loop
    'LABEL_FC7D2C': 'AudioFill_Loop',                   # Inner fill loop
    'LABEL_FC7D35': 'Audio_JumpTrampoline',             # jr t, 0x82 trampoline
    'LABEL_FC7D37': 'Audio_ReinitToneGenAndOutput',     # Reinit tone gen + output bank
    'LABEL_FC7D73': 'Audio_UpdateTempoAndReturn',       # SeqTimer_UpdateTempoReg + CompIface_SetMax
    'LABEL_FC7D7B': 'Audio_FullReinitWithPreset',       # Full reinit with sound preset reload
    'LABEL_FC7DAE': 'Audio_CheckAndReinitReverb',       # Check param 0x2880 == 0xB7, reinit reverb

    # === Display bitmap write ===
    'LABEL_FC81E0': 'Display_SetRegionNon2',            # Region code != 2: write 0x02
    'LABEL_FC81E6': 'Display_RegionDone',               # Region setup done
    'LABEL_FC81EF': 'Display_CopyAndRenderBitmaps',     # Copy bitmap data and render all 0x50 entries
    'LABEL_FC821B': 'DisplayRender_Loop',               # Render loop for 0x50 bitmap entries
    'LABEL_FC822D': 'Display_ProcessBitmapTable',       # Process bitmap table entries
    'LABEL_FC8235': 'BitmapTable_ProcessEntry',         # Process one bitmap table entry
    'LABEL_FC828A': 'BitmapTable_RenderLine',           # Render one bitmap line
    'LABEL_FC82AB': 'BitmapTable_CheckOffset',          # Check offset < 0x50
    'LABEL_FC82DD': 'BitmapTable_NextEntry',            # Next entry in bitmap table
    'LABEL_FC82EC': 'MIDI_WriteMultiByteWithHeader',    # Write multi-byte MIDI message with header
    'LABEL_FC832F': 'MidiMultiByte_WriteLoop',          # Loop writing remaining bytes
    'LABEL_FC8351': 'MidiMultiByte_Done',               # Done writing multi-byte
    'LABEL_FC8355': 'MIDI_WriteMultiByteNoHeader',      # Write multi-byte MIDI without header
    'LABEL_FC8370': 'MidiNoHeader_WriteLoop',           # Loop writing bytes (no header)
    'LABEL_FC8392': 'MidiNoHeader_Done',                # Done writing (no header)

    # === MIDI write buffer overflow ===
    'LABEL_FC840C': 'MidiWrite_ReturnDiscard',          # retd 0x2 - return discarding stack frame

    # === Audio param init loop ===
    'LABEL_FC840F': 'Audio_InitAllChannelParams',       # Loop over 0x0F channels, call per-channel init
    'LABEL_FC8415': 'AudioParamInit_Loop',              # Per-channel loop body
    'LABEL_FC842A': 'Audio_InitSingleChannelParams',    # Init params for one channel (volume/pan/expression)

    # === Audio update (main periodic) ===
    'LABEL_FC84A0': 'Audio_MainPeriodicUpdate',         # Main periodic audio update (checks state, runs MIDI, processes events)
    'LABEL_FC84DC': 'Audio_SyncBufferPositions',        # Sync buffer positions (37171/37088 from 37086)

    # === File I/O dispatch helpers ===
    'LABEL_FC851C': 'FileIO_ProcessRemainingOps',       # Process remaining operations in buffer

    # === Sound param apply/fetch ===
    'LABEL_FC9A95': 'SndParam_ApplyAndFetch',           # Apply program change and fetch osc table
    'LABEL_FC9AC9': 'SndParam_CheckRhythm',             # Check if channel is rhythm (0x48)
    'LABEL_FC9AD1': 'SndParam_ApplyDone',               # Done applying
    'LABEL_FC9AD4': 'SndParam_ApplyFromPointer',        # Apply from pointer via xiz
    'LABEL_FC9B16': 'SndParam_FetchAndStore',           # Fetch osc table and store results
    'LABEL_FC9B4A': 'SndParam_FetchCheckRhythm',        # Check rhythm in fetch path
    'LABEL_FC9B52': 'SndParam_FetchDone',               # Done fetching
    'LABEL_FC9B6A': 'SndParamResolve_CheckRhythm',     # Check rhythm in resolve path
    'LABEL_FC9B95': 'SndParamResolve_Done',             # Done resolving

    # === Sound preset search branch targets ===
    'LABEL_FC9EA5': 'ReverbPreset_SearchLoop',          # Reverb preset search loop
    'LABEL_FC9ED1': 'ReverbPreset_NextEntry',           # Next entry in reverb search
    'LABEL_FC9EDC': 'ReverbPreset_SearchDone',          # Done searching reverb presets
    'LABEL_FC9EDE': 'EQPreset_FindMatch',               # Find matching EQ preset (type 1)
    'LABEL_FC9EE1': 'EQPreset_SearchLoop',              # EQ preset search loop
    'LABEL_FC9F0D': 'EQPreset_NextEntry',               # Next entry in EQ search
    'LABEL_FC9F18': 'EQPreset_SearchDone',              # Done searching EQ presets
    'LABEL_FC9F1D': 'CombinedPreset_SearchLoop',        # Combined preset search loop
    'LABEL_FC9F74': 'CombinedPreset_NextEntry',         # Next entry in combined search

    # === MIDI CC lookup/dispatch helpers ===
    'LABEL_FCA0FB': 'MIDI_MapCCToIndex',                # Map CC number (97-102) to index (0-4)

    # === Safe wrapper functions ===
    'LABEL_FCA18C': 'SndParam_ApplyProgramChange_Safe', # Safe wrapper: save regs, call FC9A95
    'LABEL_FCA1D2': 'SndParam_UpdateVoiceEntry_Safe',   # Safe wrapper: save regs, call FC9C84

    # === MIDI parameter validation ===
    'LABEL_FCA45F': 'MidiParamValid_CheckW78',          # Check w == 0x78
    'LABEL_FCA464': 'MidiParamValid_SetInvalid',        # Set invalid (inc 1, hl)
    'LABEL_FCA466': 'MidiParamValid_Return',            # Return from validation

    # === MIDI stream processing ===
    'LABEL_FCA467': 'MidiStream_ProcessEventBuffer',    # Process MIDI event buffer (main path)
    'LABEL_FCA497': 'MidiStream_NextEvent',             # Next event in stream
    'LABEL_FCA4BF': 'MidiStream_ScanForMatch',          # Scan for matching event
    'LABEL_FCA4CF': 'MidiStream_FoundMatch',            # Found matching event
    'LABEL_FCA4EF': 'MidiStream_BufferDone',            # Buffer exhausted
    'LABEL_FCA4F7': 'MidiStream_Return',                # Return from stream processing
    'LABEL_FCA51A': 'MidiStream_InitFromLookup',        # Init stream from lookup table
    'LABEL_FCA542': 'MidiStreamInit_CopyLoop',          # Copy loop during init
    'LABEL_FCA553': 'MidiStreamInit_Done',              # Done initializing

    # === MIDI stream processing path B ===
    'LABEL_FCA5F5': 'MidiStream_ProcessSeqBuffer',      # Process sequencer MIDI buffer
    'LABEL_FCA627': 'MidiSeqBuf_NextEvent',             # Next event in seq buffer
    'LABEL_FCA652': 'MidiSeqBuf_ScanForMatch',          # Scan seq buffer for match
    'LABEL_FCA662': 'MidiSeqBuf_FoundMatch',            # Found match in seq buffer
    'LABEL_FCA68C': 'MidiSeqBuf_Done',                  # Seq buffer done
    'LABEL_FCA694': 'MidiSeqBuf_Return',                # Return from seq buffer processing
    'LABEL_FCA696': 'MidiSeqBuf_ProcessorTable',        # Table data for seq buffer processors
    'LABEL_FCA6B8': 'MidiSeqBuf_InitFromTable',         # Init seq buffer from table
    'LABEL_FCA6C7': 'MidiSeqBufInit_CopyLoop',          # Copy loop during seq buf init
    'LABEL_FCA6DA': 'MidiSeqBufInit_Done',              # Done initializing seq buffer

    # === Tempo/expression control ===
    'LABEL_FCA6DB': 'Tempo_ProcessExpressionChange',    # Process tempo expression change
    'LABEL_FCA6EE': 'TempoExpr_FindActivePart',         # Find active part for expression
    'LABEL_FCA6FD': 'TempoExpr_StorePartIndex',         # Store part index
    'LABEL_FCA732': 'TempoExpr_CheckHighBitW',          # Check high bit of W register
    'LABEL_FCA73E': 'TempoExpr_WriteAndProcess',        # Write and process entry
    'LABEL_FCA75A': 'TempoExpr_Done',                   # Done processing expression
    'LABEL_FCA75D': 'Audio_ProcessAllMidiStreams',       # Process all MIDI streams (event+seq+modulation+ringbuf)
    'LABEL_FCA796': 'TempoSrc_CheckAutoPlay',           # Check auto-play mode for tempo source
    'LABEL_FCA7B2': 'TempoSrc_DirectTempoMode',         # Direct tempo mode (0xD)
    'LABEL_FCA7C0': 'Mod_SelectExpressionSource',       # Select modulation expression source
    'LABEL_FCA7E5': 'ModExpr_CheckAutoPlay',            # Check auto-play for modulation
    'LABEL_FCA803': 'ModExpr_DirectMode',               # Direct modulation mode (0xD)

    # === MIDI stream processing path C ===
    'LABEL_FCA810': 'MidiStream_ProcessTempoRingBuf',   # Process tempo ring buffer
    'LABEL_FCA83B': 'TempoRing_NextEvent',              # Next event in ring buffer
    'LABEL_FCA85E': 'TempoRing_InitAndScan',            # Init and scan for match
    'LABEL_FCA86E': 'TempoRing_ScanForMatch',           # Scan ring buffer for match
    'LABEL_FCA87E': 'TempoRing_FoundMatch',             # Found match in ring buffer
    'LABEL_FCA89C': 'TempoRing_UpdateAndContinue',      # Update counter and continue
    'LABEL_FCA8AE': 'TempoRing_Done',                   # Ring buffer done
    'LABEL_FCA8B6': 'TempoRing_Return',                 # Return from ring buffer processing
    'LABEL_FCA8B8': 'TempoRing_ProcessorTable',         # Table data for ring buf processors
    'LABEL_FCA8FA': 'TempoRing_ValidateState',          # Validate ring buffer state

    # === MIDI tempo CC transmit ===
    'LABEL_FCAAE4': 'TempoCC_CheckHighBitW',            # Check high bit of W
    'LABEL_FCAAF0': 'TempoCC_WriteAndProcess',          # Write CC and process
    'LABEL_FCAB08': 'TempoCC_Return',                   # Return from tempo CC
    'LABEL_FCAB09': 'TempoRing_InitPartStream',         # Init per-part stream for ring buffer
    'LABEL_FCAB4B': 'TempoPartStream_CopyLoop',         # Copy loop for part stream
    'LABEL_FCAB5E': 'TempoPartStream_Done',             # Done copying part stream

    # === Tempo ring buffer entry processing ===
    'LABEL_FCAB95': 'TempoRingBuf_ClearEntryType',      # Clear entry type after processing
    'LABEL_FCAB9A': 'TempoRingBuf_EntryDone',           # Done processing entry
    'LABEL_FCAB9B': 'Audio_ProcessPartExpressions',     # Process part-level expressions (called from audioinit)
    'LABEL_FCABBA': 'PartExpr_ProcessNextBit',          # Process next bit in part expression mask
    'LABEL_FCABDF': 'PartExpr_WriteToBuffer',           # Write expression to ring buffer
    'LABEL_FCABFB': 'PartExpr_AddPartIndex',            # Add part index to buffer
    'LABEL_FCAC13': 'PartExpr_ReadCurrentValue',        # Read current expression value
    'LABEL_FCAC29': 'PartExpr_AdvanceBit',              # Advance to next bit
    'LABEL_FCAC38': 'PartExpr_Done',                    # Done processing expressions

    # === Part reinitialization ===
    'LABEL_FCAC40': 'PartReinit_ProcessNextPart',       # Process next part in reinit loop
    'LABEL_FCAC7F': 'PartReinit_AdvancePart',           # Advance to next part
    'LABEL_FCAC93': 'PartReinit_SendD2Command',         # Send D2 command (program bank MSB)
    'LABEL_FCACB1': 'PartReinit_SendD1Command',         # Send D1 command (bank select)
    'LABEL_FCACCC': 'PartReinit_SendD0Command',         # Send D0 command (program change)
    'LABEL_FCACE7': 'PartReinit_SendB0Command',         # Send B0 command (controller)
    'LABEL_FCAD23': 'PartReinit_CheckSpecialPart15',    # Check if part 15, send 0x298 param
    'LABEL_FCAD38': 'PartReinit_SpecialDone',           # Done with special part check
    'LABEL_FCAD39': 'Audio_ReinitAndProcessEvents',     # Reinit audio and process MIDI events
    'LABEL_FCAD44': 'Audio_SyncAndProcessSequencer',    # Sync buffer positions and process sequencer
    'LABEL_FCAD50': 'AudioSeq_CheckEventPending',       # Check if sequencer event pending

    # === Channel param bank write ===
    'LABEL_FCA2D9': 'Audio_WriteBankSelectParams',      # Write bank select parameters for both channels
    'LABEL_FCA2F8': 'BankSelect_CheckChannel1',         # Check and write channel 1 bank select
    'LABEL_FCA316': 'BankSelect_Done',                  # Done with bank select

    # === Seq timer ===
    'LABEL_FCA33B': 'SeqTimer_ClampToDefault',          # Clamp tempo to default 0x78
    'LABEL_FCA346': 'SeqTimer_ComputeRegValue',         # Compute timer register value
    'LABEL_FCA361': 'SeqTimer_AdjustForMode4',          # Adjust for mode 4
    'LABEL_FCA371': 'SeqTimer_RoundUp',                 # Round up division result
    'LABEL_FCA385': 'SeqTimer_ClearFlag',               # Clear update flag
    'LABEL_FCA38F': 'SeqTimer_Return',                  # Return from tempo update

    # === Voice param helpers ===
    'LABEL_FCA221': 'MidiGuarded_Return',               # Return (guarded dispatch done)
    'LABEL_FCA262': 'MidiWriteVoice_Done',              # Done writing voice param
    'LABEL_FCA266': 'MIDI_WriteVoiceParamFromBuffer',   # Write voice param from buffer (37246-37249)
    'LABEL_FCA276': 'MIDI_WriteVoiceParamDirect',       # Write voice param directly
    'LABEL_FCA2B6': 'MidiWriteDirect_Done',             # Done writing direct

    # === CtrlPanel bit manipulation sub-labels ===
    'LABEL_FC77B0': 'CtrlPanel_ClearBits1_2',           # AND (xbc), 0xF9
    'LABEL_FC77B5': 'CtrlPanel_SetBit2',                # Set bit 2 at (xbc)
    'LABEL_FC77BF': 'CtrlPanel_SyncBit0_From8F5C',     # Sync bit 0 from 0x8F5C to (xwa)
    'LABEL_FC77CC': 'CtrlPanel_ResBit0_8F5C',           # Res bit 0 when 8F5C bit 0 clear
    'LABEL_FC77CF': 'CtrlPanel_SetBit3_OnStyleD0D3',    # Set bit 3 at 0x8F25 if style D0-D3
    'LABEL_FC77F0': 'CtrlPanel_SetResBit0_ViaLookup4',  # Set/res bit 0 at xiz+4 via indicator lookup + 0x8F54
    'LABEL_FC780E': 'CtrlPanelLookup4_ResBit0',
    'LABEL_FC7810': 'CtrlPanelLookup4_Done',
    'LABEL_FC7812': 'CtrlPanel_SetResBit1_ViaLookup56', # Set/res bit 1 at xiz+4 via 0x8F56
    'LABEL_FC7830': 'CtrlPanelLookup56_ResBit1',
    'LABEL_FC7832': 'CtrlPanelLookup56_Done',
    'LABEL_FC7834': 'CtrlPanel_SetResBit2_ViaLookup50', # Set/res bit 2 at xiz+4 via 0x8F50
    'LABEL_FC7852': 'CtrlPanelLookup50_ResBit2',
    'LABEL_FC7854': 'CtrlPanelLookup50_Done',
    'LABEL_FC7856': 'CtrlPanel_SetResBit3_ViaLookup52', # Set/res bit 3 at xiz+4 via 0x8F52
    'LABEL_FC7874': 'CtrlPanelLookup52_ResBit3',
    'LABEL_FC7876': 'CtrlPanelLookup52_Done',
    'LABEL_FC7878': 'CtrlPanel_GuardedNibbleSet_8F4E',  # Guarded nibble set via 0x8F4E
    'LABEL_FC789E': 'CtrlPanelGuard_PassedCheck',
    'LABEL_FC78BF': 'CtrlPanelGuard_ClearNibble',
    'LABEL_FC78C4': 'CtrlPanel_SetResBit0_ViaLookup4C', # Set/res bit 0 at xiz+13 via 0x8F4C
    'LABEL_FC78E2': 'CtrlPanelLookup4C_ResBit0',
    'LABEL_FC78E4': 'CtrlPanelLookup4C_Done',
    'LABEL_FC78E6': 'CtrlPanel_SetResBit7_ViaLookup4C', # Set/res bit 7 of (xiz) via 0x8F4C
    'LABEL_FC78FF': 'CtrlPanelBit7_Res',
    'LABEL_FC7901': 'CtrlPanelBit7_Done',
    'LABEL_FC7903': 'CtrlPanel_SetResBit5_ViaLookup4C', # Set/res bit 5 of (xiz) via 0x8F4C
    'LABEL_FC791C': 'CtrlPanelBit5_Res',
    'LABEL_FC791E': 'CtrlPanelBit5_Done',
    'LABEL_FC7920': 'CtrlPanel_SetResBit6_ViaLookup4C', # Set/res bit 6 of (xiz) via 0x8F4C
    'LABEL_FC7939': 'CtrlPanelBit6_Res',
    'LABEL_FC793B': 'CtrlPanelBit6_Done',

    # === File I/O callback ===
    'LABEL_FC5843': 'FileIO_ShiftD',                    # Shift d register (before callback handler)
    'LABEL_FC5863': 'FileIO_AdvancePointer',            # Advance xiz by 8
    'LABEL_FC5865': 'FileIO_MainLoop',                  # Main file I/O callback loop
    'LABEL_FC5874': 'FileIO_BytecodeData',              # File I/O bytecode data block

    # === CtrlPanel indicator state refresh subroutines ===
    'LABEL_FC90FB': 'CtrlPanel_CompareAndUpdateIndicators', # Compare old/new indicator state, dispatch changes
    'LABEL_FC916D': 'CtrlPanelRefresh_ProcessRemoved',  # Process removed indicators
    'LABEL_FC91CC': 'CtrlPanelRefresh_DispatchVoiceCC', # Dispatch voice CC for refresh
    'LABEL_FC91DC': 'CtrlPanelRefresh_CheckMigration',  # Check indicator migration
    'LABEL_FC9242': 'CtrlPanelRefresh_Done',            # Done refreshing

    # === Part bitmask search/index helpers ===
    'LABEL_FC9295': 'BitmaskToIndex_ScanLoop',          # Scan loop in bitmask to index conversion
    'LABEL_FC92AC': 'BitmaskToIndex_ShiftAndAdvance',   # Shift right and advance position
    'LABEL_FC92B7': 'BitmaskToIndex_Terminate',         # Terminate list with 0xFF

    # === Volume/parameter iteration loops ===
    'LABEL_FC92C1': 'Audio_IteratePartsWithVolume',     # Iterate parts and apply volume param (0xB2)
    'LABEL_FC92CC': 'VolumeIter_NextPart',              # Next part in volume iteration
    'LABEL_FC92E7': 'VolumeIter_ApplyParam',            # Apply volume param for one part
    'LABEL_FC9331': 'VolumeIter_AdvancePart',           # Advance to next part
    'LABEL_FC9339': 'VolumeIter_Done',                  # Done iterating
    'LABEL_FC933D': 'Audio_IteratePartsWithExpression',  # Iterate parts and apply expression (0xB1)
    'LABEL_FC9375': 'ExprIter_Start',                   # Start expression iteration
    'LABEL_FC9377': 'ExprIter_NextPart',                # Next part in expression iteration
    'LABEL_FC9392': 'ExprIter_ApplyParam',              # Apply expression param for one part
    'LABEL_FC93E0': 'ExprIter_AdvancePart',             # Advance to next part
    'LABEL_FC93E8': 'ExprIter_Done',                    # Done iterating
    'LABEL_FC93EC': 'Audio_IteratePartsWithPan',        # Iterate parts and apply pan param (0xB4)
    'LABEL_FC93F7': 'PanIter_NextPart',                 # Next part in pan iteration
    'LABEL_FC9412': 'PanIter_ApplyParam',               # Apply pan param for one part
    'LABEL_FC9479': 'PanIter_Done',                     # Done iterating

    # === MIDI voice param dispatch ===
    'LABEL_FC948C': 'VoiceParamCC_NextPart',            # Next part in voice param dispatch
    'LABEL_FC94FB': 'VoiceParamCC_AdvancePart',         # Advance to next part
    'LABEL_FC9503': 'VoiceParamCC_Done',                # Done dispatching

    # === Tone gen voice update ===
    'LABEL_FC99F3': 'Audio_FlushPendingBankSelects',    # Flush pending bank select changes
    'LABEL_FC9A19': 'BankFlush_CheckChannel1',          # Check channel 1 bank select

    # === Sound param voice channel lookup ===
    'LABEL_FC9E19': 'VoiceLookup_CheckRhythm',         # Check if rhythm channel (0x48)
    'LABEL_FC9E23': 'VoiceLookup_ReturnInvalid',        # Return 0xFFFFFFFF (invalid)
    'LABEL_FC9E31': 'VoicePanInit_Loop',                # Loop body of pan init from preset

    # === Sound param update dispatch ===
    'LABEL_FC9C84': 'SndParam_UpdateVoiceEntry',        # Update voice entry with program/bank/mode data
    'LABEL_FC9CB1': 'SndParamUpdate_SetResBit6',        # Set/res bit 6 in update
    'LABEL_FC9CD2': 'SndParamUpdate_DispatchWrite',     # Dispatch write to voice entry
    'LABEL_FC9CF3': 'SndParamUpdate_Done',              # Done updating

    # === MIDI channel distribute ===
    'LABEL_FC9D10': 'MidiDistribute_LookupAndWrite',    # Lookup channel and write param
    'LABEL_FC9D31': 'MidiDistribute_Fallthrough',       # Fallthrough after lookup
    'LABEL_FC9D33': 'MidiDistribute_CheckRhythm',      # Check rhythm channel in distribute
    'LABEL_FC9D3E': 'MidiDistribute_Done',              # Done distributing
}

# Remove duplicates (some entries appeared twice)
# Build final rename dict
renames_final = {}
for old, new in RENAMES.items():
    if old not in renames_final:
        renames_final[old] = new

def find_files_with_label(label):
    """Find all .s files referencing this label."""
    result = subprocess.run(
        ['grep', '-rl', label, '--include=*.s', '.'],
        capture_output=True, text=True, cwd=REPO
    )
    return [f.strip() for f in result.stdout.strip().split('\n') if f.strip()]

def rename_in_file(filepath, old_label, new_label):
    """Replace old_label with new_label in file using binary I/O."""
    with open(filepath, 'rb') as f:
        data = f.read()
    old_bytes = old_label.encode('ascii')
    new_bytes = new_label.encode('ascii')
    if old_bytes not in data:
        return False
    data = data.replace(old_bytes, new_bytes)
    with open(filepath, 'wb') as f:
        f.write(data)
    return True

def check_collision(new_label):
    """Check if new_label already exists in codebase."""
    result = subprocess.run(
        ['grep', '-rl', new_label, '--include=*.s', '.'],
        capture_output=True, text=True, cwd=REPO
    )
    return result.stdout.strip() != ''

def main():
    # First, check for collisions
    print("Checking for naming collisions...")
    collisions = []
    for old, new in renames_final.items():
        if check_collision(new):
            # Check it's not just the old label being renamed
            collisions.append((old, new))

    if collisions:
        print(f"WARNING: {len(collisions)} potential collisions found:")
        for old, new in collisions:
            print(f"  {old} -> {new}")
        # Don't abort - some may be from the same label in other contexts

    # Process renames
    total_files_modified = 0
    total_renames = 0

    for old, new in sorted(renames_final.items()):
        files = find_files_with_label(old)
        if not files:
            print(f"  SKIP: {old} not found in any file")
            continue

        modified = 0
        for f in files:
            filepath = os.path.join(REPO, f.lstrip('./'))
            if rename_in_file(filepath, old, new):
                modified += 1

        if modified:
            total_renames += 1
            total_files_modified += modified
            if modified > 1:
                print(f"  {old} -> {new} ({modified} files)")
            else:
                print(f"  {old} -> {new}")

    print(f"\nDone: {total_renames} labels renamed across {total_files_modified} file modifications")

if __name__ == '__main__':
    main()
