#!/usr/bin/env python3
"""Rename batch 3 of high-reference-count unnamed labels (7-8 refs)."""

import re

RENAMES = {
    # === 8 REFS ===
    'LABEL_F22BFD': 'DispatchHandler_SubJumpTable',   # jr/jr/call dispatch table
    'LABEL_F30934': 'SndParam_SendEventReturnZero',    # call SendEvent; lds32 xhl,0; pop+lda+ret
    'LABEL_F39B8F': 'SeqPlay_IncrLoopCounter',         # incm8 counter; cp 0x10; loop
    'LABEL_F63049': 'RhythmFunc_NullRet',              # bare ret before data
    'LABEL_F637D6': 'RhythmROM_ReturnZero',            # xor a,a; ret

    # === 7 REFS ===
    'LABEL_EF72AA': 'TitleString_NullRet',             # bare ret before "TEMPO" string
    'LABEL_F1CA38': 'MspBnk_ReturnZero',               # lds32 xhl,0; pop xiz; ret
    'LABEL_F208D6': 'PartFormat_NullRet',              # bare ret before data block
    'LABEL_F2B3B9': 'SongName_ReturnZeroJmp',          # lds32 xhl,0; jr epilogue
    'LABEL_F30311': 'Entertainer_ReturnZeroJmp',       # lds32 xhl,0; jr epilogue
    'LABEL_F3312C': 'AccIll_CallSetDialDown',          # call SetDialDown
    'LABEL_F3A094': 'SeqPlay_ReturnFalse',             # ldb l,0; pop+ret
    'LABEL_F3A565': 'SeqVoice_ReturnFalse',            # ldb l,0; pop xiz+ret
    'LABEL_F42CFB': 'AppEvent_CheckAndBranch',         # cpi_berp 0xFB,1; jrl
    'LABEL_F46CD5': 'SqPlay_ReturnZero',               # lds32 xhl,0; ret
    'LABEL_F52AA5': 'FdcFile_Epilogue20',              # pop xiz; lda xsp,(xsp+20); ret
    'LABEL_F566FF': 'AccVoice_ReturnExtHL',            # extz xhl; ret
    'LABEL_F68DDF': 'S2cTtl_ReturnZero',               # lds32 xhl,0; ret
    'LABEL_F69224': 'CstmCp_ReturnZero',               # lds32 xhl,0; ret
    'LABEL_F754A9': 'AudioMix_ReturnZeroJmp3',         # lds32 xhl,0; jr epilogue
    'LABEL_F7A853': 'MidiPart_ReturnZeroJmp',          # lds32 xhl,0; jr epilogue
    'LABEL_F7D7C3': 'LswGlide_PopIzRet',              # pop xiz; ret (after LswGlidePedal)
    'LABEL_F7D8A0': 'LswSustain_PopIzRet',            # pop xiz; ret (after LswSustainPedal)
    'LABEL_F7D97D': 'LswKeyScale_PopIzRet',           # pop xiz; ret (after LswKeyScaling)
    'LABEL_F7DA5A': 'LswAfterTouch_PopIzRet',         # pop xiz; ret (after LswAfterTouch)
    'LABEL_F7DB39': 'LswPartExp_PopIzRet',            # pop xiz; ret (after LswPartExp)
    'LABEL_F7DD1F': 'LswLocal_PopIzSkip4Ret',         # pop xiz; inc 4,xsp; ret
    'LABEL_F7ED57': 'LswMaster_ReturnZeroJmp',        # lds32 xhl,0; jr epilogue
    'LABEL_F83FDE': 'AudioView_ReturnZeroJmp',         # lds32 xhl,0; jrl epilogue
    'LABEL_F8B335': 'SeqPhase_PopIzRet',               # popw iz; ret
    'LABEL_FA25B6': 'AcRhythm_ReturnZeroJmp',          # lds32 xhl,0; jr epilogue
    'LABEL_FB88BB': 'SeqFile_CallApFunc',              # call ApFuncCall
    'LABEL_FBBB46': 'SeqLoad_ReturnZeroJmp2',          # lds32 xhl,0; pop xiz; inc 4; ret
    'LABEL_FC7B05': 'MidiScan_PopIzRet',               # pop xiz; ret (after MidiChannel_ScanPending)
    'LABEL_FE7DFC': 'NoteMap_PopIzStoreRet',           # popw iz; store; ret
    'LABEL_FE9B48': 'Audio_NullRet2',                  # bare ret
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
