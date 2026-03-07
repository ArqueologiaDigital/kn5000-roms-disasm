#!/usr/bin/env python3
"""Rename batch 4 of high-reference-count unnamed labels (6 refs)."""

import re

RENAMES = {
    # === BARE RET STUBS ===
    'LABEL_EF7174': 'Display_NullRet2',                # bare ret in display area
    'LABEL_F24646': 'SoundGen_NullRet',                 # ret after SoundGen_SetVoiceBitAndWriteRegs
    'LABEL_F24726': 'MidiNoteOff_NullRetA',             # ret after MidiEvent_NoteOffA
    'LABEL_F247A5': 'MidiNoteOff_NullRetB',             # ret after MidiEvent_NoteOffB
    'LABEL_F26AE5': 'VoiceChannel_NullRet',             # ret after VoiceChannel_UpdateWithPitch
    'LABEL_F26B7E': 'VoiceChannel_NullRet2',            # ret before VoiceChannel_SetParamByte7
    'LABEL_F53CA3': 'AccChord_NullRet',                 # ret before AccChord_CompareAndSetDirty
    'LABEL_F56C6C': 'AccPart_NullRet',                  # ret after AccPart_LoadParamOffsetTable
    'LABEL_F67367': 'DrumChannel_MapA_NullRet',         # ret after DrumChannel_MapToIndexA
    'LABEL_F673AC': 'DrumChannel_MapB_NullRet',         # ret after DrumChannel_MapToIndexB

    # === RETURN-ZERO STUBS (lds32 xhl,0; ret) ===
    'LABEL_F1CFC6': 'MspRgpShow_ReturnZero',           # after MspRgpShowHideFunc
    'LABEL_F2102A': 'SqMdlyPly_ReturnZero',             # after SqMdlyPlyTtlFunc
    'LABEL_F210BE': 'DkMdlyPly_ReturnZero',             # after DkMdlyPlyTtlFunc
    'LABEL_F212F8': 'DpMdlyDoc_ReturnZero',             # after DpMdlyDocTtlFunc
    'LABEL_F213A8': 'DpMdlyPd_ReturnZero',              # after DpMdlyPdTtlFunc
    'LABEL_F21465': 'DpMdlySmf_ReturnZero',             # after DpMdlySmfTtlFunc
    'LABEL_F21549': 'DpMdlySmfLyr_ReturnZero',          # after DpMdlySmfLyrTtlFunc
    # LABEL_F46CD5: already renamed to SqPlay_ReturnZero in batch 3
    'LABEL_F6C226': 'StylCnvTxt_ReturnZero',            # after StylCnvTxtTtlFunc
    'LABEL_F76618': 'TtMdExc_ReturnZero',               # after TtMdExc

    # === RETURN-ZERO WITH POP (lds32 xhl,0; pop xiz; ret) ===
    'LABEL_F1B955': 'PsCtmAtt_ReturnZero',              # before PsCtmAttStrBoxProc
    'LABEL_F2E887': 'HelpFunc_ReturnZero',              # after HelpFuncChkFunc
    'LABEL_F2FA53': 'NoteEdit_ReturnZero',              # before NoteEditFunc
    'LABEL_F33130': 'AccIll_ReturnZero2',               # after AccIll_CallSetDialDown
    'LABEL_F3224E': 'SqedtVal_ReturnZero2',             # before SqedtVal2Proc
    'LABEL_F46C87': 'SqRealRec_ReturnZero',             # after SqRealRecTitleFunc
    'LABEL_F735F0': 'TtMdmenu_ReturnZero',              # after TtMdmenu
    'LABEL_F7AD42': 'MidiSetup_ReturnZero',             # before InitializeMurai
    'LABEL_F7B661': 'TtSdmenu_ReturnZero',              # after TtSdmenu
    'LABEL_F83CE4': 'DemoMenu_ReturnZero',              # before DemoMenu_BuildItemWorkspace
    'LABEL_F9C2B3': 'TitleEdit_ReturnZero',             # before TitleEditProc
    'LABEL_F9C445': 'StringBox_ReturnZero',             # before StringBoxProc
    'LABEL_F2AE80': 'SongEdit_ReturnZero',              # song edit area

    # === RETURN-ZERO JMP (lds32 xhl,0; jr epilogue) ===
    'LABEL_F1A6C7': 'CmpSetP1_ReturnZeroJmp',          # before CmpSetP1GridCheck
    'LABEL_F1AD04': 'AcS2cMem_ReturnZeroJmp',          # before AcS2cMemNoBoxProc
    'LABEL_F1C28E': 'EasyCmp_ReturnZeroJmp',            # before EasyCmpGridCheck
    'LABEL_F30311': 'Entertainer_ReturnZeroJmp',        # before EntertainerGridCheck (already done in batch 3, skip)
    'LABEL_F738BD': 'Vocalist_ReturnZeroJmp',           # before VocalistGridCheck
    'LABEL_F754A9': 'AudioMix_ReturnZeroJmp3',         # (already done in batch 3, skip)
    'LABEL_F7A853': 'MidiPart_ReturnZeroJmp',          # (already done in batch 3, skip)
    'LABEL_F839D1': 'IvDrawbar_ReturnZeroJmp',          # before IvDrawbarNormProc
    'LABEL_F84687': 'AcPresent_ReturnZeroJmp',          # after AcPresentCtrl_CheckSSFStart
    'LABEL_FA47BC': 'ClassProc_ReturnZeroJmp',          # jr ClassProc_ReturnWithStatus
    'LABEL_FBAA4C': 'TchSens_ReturnZeroJmp',            # before TchSensGridCheck
    'LABEL_FBAFFA': 'FSWAss_ReturnZeroJmp',             # before FSWAssGridCheck
    'LABEL_F458A2': 'EffEdit_ReturnZeroJmp',            # lds hl,0; jrl epilogue
    'LABEL_F7ED57': 'LswMaster_ReturnZeroJmp',         # (already done in batch 3, skip)
    'LABEL_F83FDE': 'AudioView_ReturnZeroJmp',         # (already done in batch 3, skip)

    # === Lsw POP+RET EPILOGUES ===
    'LABEL_F7CC78': 'LswSound_PopIzRet',               # epilogue for LswSound
    'LABEL_F7D17C': 'LswDSPEffect_PopIzRet',           # epilogue for LswDSPEffect
    'LABEL_F7D255': 'LswDigitalEffect_PopIzRet',       # epilogue for LswDigitalEffect
    'LABEL_F7D32E': 'LswSustain_PopIzRet2',            # epilogue for LswSustain (2nd stub)
    'LABEL_F7D408': 'LswSustainLength_PopIzRet',       # epilogue for LswSustainLength
    'LABEL_F7D6E6': 'LswBendRange_PopIzRet',           # epilogue for LswBendRange
    'LABEL_F7DC0F': 'LswLocalControl_PopIzRet',        # epilogue for LswLocalControl

    # === OTHER POP+RET EPILOGUES ===
    'LABEL_F26DCE': 'SoundGen_PopIyRet',               # pop xiy; ret
    'LABEL_F408F8': 'SeqPart_PopRetFA',                 # pop_werp 0xFA; ret
    'LABEL_F45A9F': 'EffEdit_PopIzSkip8Ret',           # pop xiz; inc 8,xsp; ret
    'LABEL_F7F324': 'LswEnd_PopIzSkip4Ret',            # pop xiz; inc 4,xsp; ret (before IvSoftverProc)
    'LABEL_FB788B': 'EffectMode_PopRetFA',              # pop_werp 0xFA; ret
    'LABEL_FEC04C': 'Acc_PopIzRet',                     # pop xiz; ret (before Acc_LoadAndStartPlayback)

    # === FUNCTIONAL LABELS ===
    'LABEL_F61380': 'TempoRingBuf_ReInitAndRet',       # call TempoRingBuf_Init; ret
    'LABEL_F66EBD': 'Voice_ClearSlotAndRet',            # ld (xhl),0; ret
    'LABEL_F682DB': 'CmpBk_DeliverEvent',               # call ApDeliveryEvent
    'LABEL_F685F2': 'CmpBk_PostModeChange',             # call UI_PostModeChangeEvent
    'LABEL_FBB932': 'AudioTable_SendEventAndContinue',  # call SendEvent; ...
    'LABEL_FBC40A': 'SeqLoad_StoreReturnZero',          # lds32 xhl,0 + store to berp

    # === NOTEMAP AREA EPILOGUES ===
    'LABEL_FE3011': 'NoteMap_PopRetFA_StoreAE',         # pop_werp 0xFA; st_dri3b L,0xFD,0xAE,0x00; ret-like
    'LABEL_FE33BA': 'NoteMap_PopRetFA_StoreAE2',        # same pattern
    'LABEL_FE3763': 'NoteMap_PopRetFA_StoreAE3',        # same pattern
    'LABEL_FE3E9A': 'NoteMap_PopIz_StoreAC',            # pop xiz; st_dri3b L,0xFD,0xAC,0x00
    'LABEL_FE3FB0': 'NoteMap_PopRetFA_StoreAE4',        # same pop+store pattern
    'LABEL_FE4187': 'NoteMap_PopIz_StoreAC2',           # pop xiz; st_dri3b
    'LABEL_FE7607': 'NoteMap_StoreAndRet',              # st_dri3b + ret

    # === SKIPPING (too context-dependent) ===
    # LABEL_F4294B, LABEL_F42AB0, LABEL_FADD24, LABEL_FE281B, LABEL_FECB86, LABEL_F7823C
}

# Remove labels that were already renamed in batch 3
for key in ['LABEL_F30311', 'LABEL_F754A9', 'LABEL_F7A853', 'LABEL_F7ED57', 'LABEL_F83FDE']:
    if key in RENAMES:
        del RENAMES[key]

def main():
    files = [
        '/mnt/shared/kn5000-roms-disasm/maincpu/kn5000_v10_program.s',
        '/mnt/shared/kn5000-roms-disasm/symbols/maincpu_symbols_reference.txt',
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
