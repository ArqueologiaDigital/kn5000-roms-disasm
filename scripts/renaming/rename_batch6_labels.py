#!/usr/bin/env python3
"""Rename batch 6 of high-reference-count unnamed labels (5 refs, mixed patterns)."""

import re

RENAMES = {
    # === RETURN-ZERO + POP (lds32 xhl,0; pop xiz; ...) ===
    'LABEL_F1A9BC': 'GridCheck_ReturnZero',             # after GridCheck_SendEvent
    'LABEL_F2E7AB': 'HelpLang_ReturnZero',              # after HelpLangChkFunc
    'LABEL_F761F8': 'MdPreset_ReturnZero2',             # before TtMdPreset
    'LABEL_F227A1': 'SongBank_ReturnZero',              # after SongBank_HandleNextPrev

    # === RETURN-ZERO JMP (lds32 xhl,0; jr epilogue) ===
    'LABEL_F1CB7F': 'MspBnkSlBox_ReturnZeroJmp',       # after AcMspBnkSlBoxProc
    # LABEL_F839D1: already renamed to IvDrawbar_ReturnZeroJmp in batch 5
    'LABEL_F7F071': 'IvSdscltyp2_ReturnZeroJmp',       # after IvSdscltyp2Proc
    'LABEL_F83B3D': 'IvDrawbarNorm_ReturnZeroJmp',     # after IvDrawbarNormProc
    'LABEL_FA33E5': 'ScrollBox_ReturnZero',             # after UI_ScrollBox_ComputeLayout

    # === BARE RET STUBS ===
    'LABEL_F3E3C4': 'SeqEvent_NullRet',                 # after SeqEvent_GetParamLength
    'LABEL_F3EB36': 'SeqPart_NullRet',                  # after SeqPart_InitVoiceChannelConfig
    'LABEL_F53720': 'AccChord_ReadKeysRet',             # after AccChord_ReadAndStoreKeys
    'LABEL_F565ED': 'AccStyle_ReadParamRet',            # after AccStyle_ReadParamOffset
    'LABEL_F62F31': 'RhythmChannel_NullRet',            # bare ret in rhythm area
    'LABEL_F7256E': 'MidiSeq_SustainRet',               # after MidiSeq_ProcessSustainEvent

    # === EPILOGUES ===
    'LABEL_F35239': 'SqedtFunc_Epilogue12',             # pop xiz; lda xsp,(xsp+12); ret
    'LABEL_F3C666': 'SeqPlay_BassEpilogue18',           # lda xsp,(xsp+18); ret
    'LABEL_F3C758': 'SeqPlay_ChordEpilogue14',          # lda xsp,(xsp+14); ret
    'LABEL_F6D841': 'StylCnv_Epilogue114',              # pop xiz; lda xsp,(xsp+114); ret

    # === FUNCTIONAL LABELS ===
    'LABEL_EFC7AF': 'VoiceSlot_SetFFAndContinue',       # ldb w,0xFF then falls through
    'LABEL_F33F8E': 'EffectBox_SetAutoInc',             # call SetAutoInc before EffectBoxProc_ReturnZero
    'LABEL_F40BBF': 'SeqVoice_WriteErrorAndReturn',     # calr SeqPlay_WriteErrorToVoiceTable; pop
    'LABEL_F437B1': 'SeqPlay_CheckMidiPending',         # cpdi8 7584,0; ret z
    'LABEL_F45467': 'EffEdit_WriteDSPAndReturn',        # call DSPCfg_WriteParamFull; jr epilogue
    'LABEL_F46352': 'SeqAccomp_InitAndReturn',          # call SeqPlay_InitStartState; jr epilogue
    'LABEL_F46567': 'NoteEditSy_DeliverEvent',          # call ApDeliveryEvent
    'LABEL_F66BE2': 'Voice_SetScanType3',               # ldi_werp 0xFA,3; jr Voice_ScanTableEntries
    'LABEL_F6D83D': 'StylCnv_PostModeChange',           # call UI_PostModeChangeEvent
    'LABEL_F76558': 'MdPreset_CallMainFunc',            # call MainFuncCall
    'LABEL_F9C111': 'WndScroll_SendAndReturn',          # call SendEvent
    'LABEL_FA57AB': 'TitleProc_ClearAndReturn',         # calr TitleProc_ClearResourceDirtyFlag; jrl ReturnZero
    'LABEL_FAE7D6': 'DrawFunc_DrawLineAndReturn',       # calr DrawLine_Impl
    'LABEL_F61372': 'AccPatch_CheckEmpty',              # call TempoRingBuf_CheckEmpty
    'LABEL_F2062F': 'Part_ValidateCallAndClear',        # call + DispatchHandler_ClearActiveFlag

    # === ITERATOR/LOOP LABELS ===
    'LABEL_F23090': 'SoundBank_NextEntry1',             # popw bc; inc 1,bc (loop iteration)
    'LABEL_F231C4': 'SoundBank_NextEntry2',             # popw bc; inc 1,bc
    'LABEL_F23232': 'SoundBank_NextEntry3',             # popw bc; inc 1,bc
    'LABEL_F3ACC7': 'SeqNote_ShiftAndIncrement',        # srl iz,1; inc berp
    'LABEL_F3DB36': 'SeqBuf_IncrAndLoop16',             # inc berp; cp 0x10 (16-channel loop)
}

def main():
    files = [
        '/mnt/shared/kn5000-roms-disasm/maincpu/kn5000_v10_program.s',
        '/mnt/shared/kn5000-roms-disasm/symbols/maincpu_symbols_reference.txt',
    ]

    # Pre-check for collisions
    with open(files[0], 'rb') as f:
        text = f.read().decode('latin-1')
    for new in RENAMES.values():
        if new + ':' in text:
            print(f'WARNING: {new} already exists!')
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
