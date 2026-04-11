#!/usr/bin/env python3
"""Rename batch 7 of high-reference-count unnamed labels (4 refs, auto-classified patterns)."""

import re

RENAMES = {
    # === NULL RET (bare ret) ===
    'LABEL_EFA360': 'Interrupt_NullRet',
    'LABEL_EFDC29': 'PerfMode_NullRet',
    'LABEL_F20B2B': 'CDlikeSw_NullRet',
    'LABEL_F249F2': 'Scoop_NullRet',
    'LABEL_F25055': 'VoiceSynth_NullRet3',
    'LABEL_F25779': 'VoiceParam_NullRet3',
    'LABEL_F420AA': 'MIDI_NullRet',
    'LABEL_F5F23B': 'MapBitFlags_NullRet',
    'LABEL_F604BA': 'AccPatch_NullRet',
    'LABEL_F60FE2': 'DSP_NullRet',
    'LABEL_F61075': 'DSP_NullRet2',
    'LABEL_F6124F': 'AccPatch_NullRet2',
    'LABEL_F612E7': 'AccPatch_NullRet3',
    'LABEL_F6208D': 'ToneGen_NullRet',
    'LABEL_F62E3C': 'ToneGen_NullRet2',
    'LABEL_F62EAB': 'Rhythm_NullRet',
    'LABEL_F637D8': 'RhythmROM_NullRet',
    'LABEL_F67D14': 'CmpMode_NullRet',
    'LABEL_FC99F2': 'SwbtWr_NullRet',
    'LABEL_FD0B10': 'PanelEvent_NullRet',
    'LABEL_FD0BC0': 'PanelEvent_NullRet2',
    'LABEL_FE9670': 'Voice_NullRet2',
    'LABEL_FE9D90': 'NoteBuffer_NullRet',

    # === RETURN-ZERO (lds32 xhl,0; ret / lds32 xhl,0; pop xiz; ...) ===
    'LABEL_F20D51': 'SqTrAs_ReturnZero',
    'LABEL_F20F1D': 'SqTrAsPsTtl_ReturnZero',
    'LABEL_F30938': 'SndParam_ReturnZero',
    'LABEL_F35AFF': 'ParamCmd_ReturnZero',
    'LABEL_F46AEC': 'SeqPlayMode_ReturnZero',
    'LABEL_F46D01': 'SqQtzTtl_ReturnZero',
    'LABEL_F46D2D': 'SqMdelTtl_ReturnZero',
    'LABEL_F46D59': 'SqMersTtl_ReturnZero',
    'LABEL_F46D85': 'SqVcngTtl_ReturnZero',
    'LABEL_F46DE4': 'SqMcpyTtl_ReturnZero',
    'LABEL_F46E19': 'SqMinsTtl_ReturnZero',
    'LABEL_F470A1': 'EtmenuTtl_ReturnZero',
    'LABEL_F67E56': 'CmpMenuTtl_ReturnZero',
    'LABEL_F69FF8': 'MspRecTtl_ReturnZero',
    'LABEL_F73FAE': 'AcVocalist_ReturnZero',
    'LABEL_F75715': 'SndParam_ReturnZero2',
    'LABEL_F7655C': 'MdPreset_PostMainFunc',      # call MainFuncCall fallthrough (not pure return-zero)
    'LABEL_F7732B': 'ParaLoadOpt_ReturnZero',
    'LABEL_F782D4': 'UI_ReturnZero',
    'LABEL_F791DD': 'PmemOutGrid_ReturnZero',
    'LABEL_F79A91': 'TtMdCtlMsg_ReturnZero2',
    'LABEL_F7A184': 'CtlMsgGrid_ReturnZero',
    'LABEL_F987E6': 'ApTaskCtrl_ReturnZero',
    'LABEL_F98839': 'MainTaskCtrl_ReturnZero',
    'LABEL_FBAD94': 'TchSensGrid_ReturnZero',
    'LABEL_FBB936': 'AudioTable_ReturnZero',
    'LABEL_FBCCF1': 'DispTimeSet_ReturnZero',

    # === RETURN-ZERO JMP ===
    'LABEL_F35005': 'SeqFunc_ReturnZeroJmp',
    'LABEL_F9D05B': 'AcLswBox_ReturnZeroJmp',
    'LABEL_FA1187': 'AcIndexEdit_ReturnZeroJmp',

    # === POP+RET EPILOGUES ===
    'LABEL_F1A398': 'CmpBndRng_PopIzRet',
    'LABEL_F2B208': 'LyricsBox_PopIzRet',
    'LABEL_F3FE9A': 'SeqVoice_PopIzRet2',
    'LABEL_F40050': 'SeqData_PopIzRet',
    'LABEL_F400A5': 'SeqData_PopIzRet2',
    'LABEL_F52F33': 'TaskBuf_PopIzRet',
    'LABEL_F74AF7': 'R12Octave_PopIzRet',
    'LABEL_F7B723': 'LswLeftHold_PopIzRet',
    'LABEL_F7EB2B': 'LswOrchestra_PopIzRet',
    'LABEL_F7F16B': 'LswScaleSharp_PopIzRet',
    'LABEL_F7F1D0': 'LswScaleSharp_PopIzRet2',
    'LABEL_F7F235': 'LswScaleMode_PopIzRet',
    'LABEL_FA48A7': 'SupportClass_PopIzRet',
    'LABEL_FC6C4D': 'MIDI_PopIzRet',
    'LABEL_FC73D7': 'MidiCtrl_PopIzRet',
    'LABEL_FD68B6': 'MidiSeq_PopIzRet',
    'LABEL_FE9C46': 'Audio_PopIzRet',

    # === POP_FA+RET EPILOGUES ===
    'LABEL_FC797E': 'CtrlPanel_PopRetFA',
    'LABEL_FC79C3': 'CtrlPanel_PopRetFA2',
    'LABEL_FD6955': 'MidiSeq_PopRetFA',

    # === POP+SKIP+RET EPILOGUES ===
    'LABEL_F3E24C': 'Seq_PopIzSkip8Ret',
    'LABEL_F47E38': 'AppEvent_PopIzSkip6Ret',
    'LABEL_F7F104': 'LswScaleType_PopIzSkip4Ret',
    'LABEL_FA492E': 'FuncProc_PopIzSkip4Ret',
    'LABEL_FC2533': 'WallHome_PopIzSkip4Ret',
    'LABEL_FD9287': 'SeqAlt_PopIzSkip4Ret',
    'LABEL_FD9335': 'SeqAlt_PopIzSkip4Ret2',
    'LABEL_FEE556': 'SndParam_PopIzSkip4Ret',

    # === EPILOGUE (pop xiz + frame cleanup) ===
    'LABEL_F863DF': 'Seq_Epilogue32',
}

def main():
    files = [
        '/home/fsanches/compartilhado/kn5000-roms-disasm/maincpu/kn5000_v10_program.s',
        '/home/fsanches/compartilhado/kn5000-roms-disasm/symbols/maincpu_symbols_reference.txt',
    ]

    # Pre-check for collisions
    with open(files[0], 'rb') as f:
        text = f.read().decode('latin-1')
    collisions = [new for new in RENAMES.values() if new + ':' in text]
    if collisions:
        print(f'COLLISIONS: {collisions}')
        return

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
