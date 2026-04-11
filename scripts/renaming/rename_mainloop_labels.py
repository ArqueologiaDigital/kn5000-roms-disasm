#!/usr/bin/env python3
"""Rename MainLoop-related labels and other high-ref-count labels to semantic names."""

import re

RENAMES = {
    # === MAIN LOOP DISPATCH LABELS ===
    # LABEL_EF086F is already EQU'd to Boot_CallInitHandlers

    # Second call in MainLoop: processes MIDI channel output state
    'LABEL_FC7A10': 'MidiChannel_ProcessOutputState',

    # Input processing gate: CPanel RX + init
    'LABEL_FC3E94': 'CPanel_RX_ProcessOrInit',

    # Encoder timing/output processing after delta computation
    'LABEL_FC6997': 'Encoder_TimingAndOutput',

    # MIDI channel scan for pending changes
    'LABEL_FC7AA8': 'MidiChannel_ScanPending',

    # Process changed MIDI bitmask handlers
    'LABEL_FC707D': 'MidiChannel_DispatchChanged',

    # SwbtWr init + reinit routine
    'LABEL_EF13AF': 'MainLoop_ReinitSwbtWr',

    # Audio subsystem periodic check
    'LABEL_EF13C0': 'MainLoop_AudioPeriodicCheck',

    # Timer-based countdown handler
    'LABEL_FB6CA9': 'EffectMode_TimerCountdown',

    # SysEx/communication dispatch
    'LABEL_EFAA03': 'SysEx_PeriodicDispatch',

    # Effect mode update dispatch
    'LABEL_FB78A5': 'EffectMode_CheckAndDispatch',

    # CD-like switch playback mode timer
    'LABEL_F20A0A': 'CDlikeSwitch_PlaybackTimer',

    # Communication port status check + send
    'LABEL_FEF6B1': 'CommPort_StatusCheckAndSend',

    # Periodic timestamp comparison
    'LABEL_FD0E45': 'Periodic_TimestampCheck',

    # Sequencer phase: operation state init
    'LABEL_F8B268': 'SeqPhase_OperationStateCheck',

    # Display dirty region update dispatch (main loop wrapper)
    'LABEL_EF77DF': 'Display_DirtyRegionDispatch',

    # Accompaniment sequencer entry point
    'LABEL_F6DCA9': 'AccompSeq_PeriodicEntry',

    # SeqAlt2 data read loop
    'LABEL_FDB8E5': 'SeqAlt2_DataReadLoop',

    # Encoder value scan and sync
    'LABEL_FC5761': 'Encoder_ValueScanAndSync',

    # === MAIN LOOP INTERNAL LABELS ===
    'LABEL_EF1259': 'MainLoop_AfterTimerSync',
    'LABEL_EF126F': 'MainLoop_AfterInput',
    'LABEL_EF1279': 'MainLoop_AfterSeqTick',
    'LABEL_EF1297': 'MainLoop_AfterVoiceReset',
    'LABEL_EF12A6': 'MainLoop_AfterMidiDispatch',
    'LABEL_EF12AC': 'MainLoop_AfterBit1Check',
    'LABEL_EF12B2': 'MainLoop_AfterBit3Check',
    'LABEL_EF12BE': 'MainLoop_AfterSeqAlt2',
    'LABEL_EF12D4': 'MainLoop_AfterAccWrap',
    'LABEL_EF12DE': 'MainLoop_AfterPedalReset',
    'LABEL_EF12F0': 'MainLoop_AfterSwbtWr',
    'LABEL_EF130A': 'MainLoop_AfterSeqAlt4',
    'LABEL_EF1315': 'MainLoop_AfterDialCheck',
    'LABEL_EF132F': 'MainLoop_AfterMidiPoll',
    'LABEL_EF133D': 'MainLoop_AfterDemoTick',
    'LABEL_EF134F': 'MainLoop_AfterMidiPoll2',
    'LABEL_EF135D': 'MainLoop_AfterBitmapTimer',

    # === TOP REFERENCED SHARED STUBS (14 refs each) ===
    # These are return-zero stubs and shared epilogues

    # SeqFile area return-zero
    'LABEL_FB95D6': 'SeqFile_ReturnZeroJmp',
    # Shared epilogue: pop xiz + skip 34 + ret
    'LABEL_FA5862': 'TitleFunc_Epilogue34',
    # Simple return-zero: lds hl, 0; ret
    'LABEL_F99818': 'BoxCheck_ReturnZero',
    # SeqPlay epilogue: popw iz; ret
    'LABEL_F39394': 'SeqPlay_PopIzRet',
    # Bare ret before VoiceParam table
    'LABEL_F256B8': 'VoiceParam_NullRet',
    # Bare ret before VoiceSynth table
    'LABEL_F24F9F': 'VoiceSynth_NullRet',
    # Bare ret in voice area
    'LABEL_F23CC9': 'Voice_NullRet',
    # Return-zero before SeqStepModeFunc
    'LABEL_F221E3': 'SeqStep_ReturnZero',

    # === 13-REF LABELS ===
    'LABEL_FE1BA3': 'Audio_StoreParamAndReturn',
    'LABEL_F9B3DC': 'AcNaming_ReturnZero',
    'LABEL_F84332': 'AudioCtrl_ReturnZeroJmp',
    'LABEL_F568A7': 'SoundPatch_NullRet',
    'LABEL_F525E5': 'FdcOp_Epilogue20',
    'LABEL_F454EB': 'AppEvent_ReturnZeroEpilogue4',

    # === 12-REF LABELS ===
    'LABEL_FB88BF': 'SeqFile_ReturnZeroJmp2',
    'LABEL_F9C115': 'UIDialog_ReturnZeroJmp',
    'LABEL_F751DA': 'AudioMix_ReturnZeroJmp',
    'LABEL_F74F87': 'AudioMix_ReturnZeroJmp2',
    'LABEL_F67FEB': 'CmpReal_ReturnZero',
}

def main():
    files = [
        '/home/fsanches/compartilhado/kn5000-roms-disasm/maincpu/kn5000_v10_program.s',
        '/home/fsanches/compartilhado/kn5000-roms-disasm/symbols/maincpu_symbols_reference.txt',
    ]

    for filepath in files:
        with open(filepath, 'rb') as f:
            data = f.read()

        text = data.decode('latin-1')
        count = 0
        for old, new in RENAMES.items():
            pattern = r'\b' + re.escape(old) + r'\b'
            matches = len(re.findall(pattern, text))
            if matches > 0:
                text = re.sub(pattern, new, text)
                count += matches

        with open(filepath, 'wb') as f:
            f.write(text.encode('latin-1'))

        print(f"{filepath}: {count} replacements")

if __name__ == '__main__':
    main()
