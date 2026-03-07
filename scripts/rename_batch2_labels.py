#!/usr/bin/env python3
"""Rename batch 2 of high-reference-count unnamed labels (9-11 refs)."""

import re

RENAMES = {
    # === 11 REFS ===
    'LABEL_FA4D1A': 'GetMode_Epilogue10',        # pop xiz + skip 10 + ret (before GetModeNow)
    'LABEL_F345CF': 'SeqAccomp_ReturnZeroJmp',    # lds32 xhl, 0; jr epilogue
    'LABEL_F2410D': 'SMF_NullRet',                # bare ret before "MTrk" string
    'LABEL_F16E5A': 'Util_FrameSetup10',          # stack frame setup (10 bytes)

    # === 10 REFS ===
    'LABEL_FBF42A': 'RVari_NotifyAndReturn',       # calr RVari_UpdateDisplayNotify
    'LABEL_FBC6E5': 'SeqSave_ReturnZeroJmp',       # lds32 xhl, 0; jr epilogue
    'LABEL_FBC0C6': 'SeqLoad_ReturnZeroJmp',       # lds32 xhl, 0; jr epilogue
    'LABEL_FB8E79': 'SeqFileAlt_ReturnZeroJmp',    # lds32 xhl, 0; jr epilogue
    'LABEL_FAE7D9': 'DrawFunc_Epilogue74',         # pop xiz + skip 74 + ret
    'LABEL_F99436': 'UIWidget_ReturnZero',          # lds32 xhl, 0; ret
    'LABEL_F808BD': 'Util_SignExtendAndDouble',     # exts xwa; xhl=xwa; add xhl,xhl
    'LABEL_F7D0A6': 'AudioCtrl_PopIzRet1',         # pop xiz; ret
    'LABEL_F7CE8F': 'AudioCtrl_PopIzRet2',         # pop xiz; ret
    'LABEL_F7CD86': 'AudioCtrl_PopIzRet3',         # pop xiz; ret
    'LABEL_F7C7F4': 'AudioCtrl_SendEventThenReturn',  # call SendEvent before epilogue
    'LABEL_F76F4D': 'AccFunc_ReturnZeroJmp',       # lds32 xhl, 0; jr epilogue
    'LABEL_F72A04': 'Util_ExtractAndShiftBits',     # bit manipulation + shift
    'LABEL_F6CBDB': 'AccRhythm_ReturnZero',        # lds32 xhl, 0; ret
    'LABEL_F69E1F': 'AccBass_ReturnZero',           # lds32 xhl, 0; ret
    'LABEL_F397AD': 'SeqPlay_PopIzSkip6Ret',        # pop xiz + inc 6 + ret
    'LABEL_F20E31': 'CDlikeSwTtl_ReturnZero2',       # lds32 xhl, 0; ret
    'LABEL_F18EC1': 'FloppyCtrl_PopIzStoreRet',     # pop xiz + store + ret
    'LABEL_F18BF1': 'FloppyCtrl_LoadIzAndContinue',  # ld hl, iz; jr ...
    'LABEL_EF3C3C': 'FlashWrite_Entry',             # label just before FlashWrite

    # === 9 REFS ===
    'LABEL_FE9412': 'Audio_NullRet1',               # bare ret
    'LABEL_FCAFD1': 'MidiCtrl_NullRet',              # bare ret
    'LABEL_FA2D03': 'UIList_ReturnZeroJmp',          # lds32 xhl, 0; jr epilogue
    'LABEL_F7D610': 'AudioCtrl_PopIzRet4',           # pop xiz; ret
    'LABEL_F7D50C': 'AudioCtrl_PopIzRet5',           # pop xiz; ret
    'LABEL_F7CFA3': 'AudioCtrl_PopIzRet6',           # pop xiz; ret
    'LABEL_F6C1DB': 'AccChord_ReturnZero',            # lds32 xhl, 0; ret
    'LABEL_F569DA': 'AccVoice_NullRet',               # bare ret before AccVoice_LookupTableAddress
    'LABEL_F47E36': 'AppEvent_LoadIzToHL',            # ld hl, iz
    'LABEL_F452BD': 'AppEvent_PopIzSkip2Ret',         # pop xiz + inc 2 + ret
    'LABEL_F2555F': 'VoiceParam_NullRet2',            # bare ret
    'LABEL_F24E3A': 'VoiceSynth_NullRet2',            # bare ret
    'LABEL_F2EED9': 'SqedtNote_ReturnZero',           # lds32 xhl, 0
    'LABEL_F1B253': 'FdcFormat_ReturnZeroJmp',         # lds32 xhl, 0; jr epilogue
    'LABEL_EF3ADA': 'FlashOp_Epilogue10',              # ei 0; pop xiz; skip 10
}

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
