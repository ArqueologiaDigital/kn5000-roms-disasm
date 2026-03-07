#!/usr/bin/env python3
"""Rename batch 5 of high-reference-count unnamed labels (5 refs, easy patterns)."""

import re

RENAMES = {
    # === RETURN-ZERO STUBS (lds32 xhl, 0; ret) ===
    'LABEL_F1AA48': 'CmpSetPage_ReturnZero',           # after CmpSetPageFunc
    'LABEL_F1B291': 'S2cShow_ReturnZero',               # after S2cShowHideFunc
    'LABEL_F682DF': 'CmpBk_ReturnZero',                 # after CmpBk_DeliverEvent
    'LABEL_F68458': 'CmpBksl_ReturnZero',               # after CmpBksl_ApplyAndReturnZero
    'LABEL_F68C16': 'CmEsy_ReturnZero',                 # before CmEsyTtlFunc
    'LABEL_F69594': 'CstmCp_ReturnZero2',               # after CstmCpTtlFunc
    'LABEL_F7363F': 'TtVocalist_ReturnZero',            # after TtVocalistWorkstation
    'LABEL_F74FDC': 'TtMdRealMsg_ReturnZero',           # after TtMdRealMsg
    'LABEL_F75226': 'TtFadeInOut_ReturnZero',           # after TtFadeInOut
    'LABEL_F75757': 'TtMdInOut_ReturnZero',             # after TtMdInOut
    'LABEL_F76233': 'TtMdPreset_ReturnZero',            # after TtMdPreset
    'LABEL_F76C5B': 'TtMdParaLoad_ReturnZero',         # after TtMdParaLoad
    'LABEL_F77F69': 'TtComSet_ReturnZero',              # after TtComSet
    'LABEL_F78326': 'TtMdPmemOut_ReturnZero',           # after TtMdPmemOut
    'LABEL_F79AD9': 'TtMdCtlMsg_ReturnZero',            # after TtMdCtlMsg
    'LABEL_F7A1F1': 'TtMdPart_ReturnZero',              # after TtMdPart
    'LABEL_F7EECC': 'TtSdscltyp_ReturnZero',           # after TtSdscltyp

    # === POP+RET EPILOGUES ===
    'LABEL_F359C9': 'Equalizer_PopIzRet',               # after Equalizer_LookupParamString
    'LABEL_F38726': 'BmDrEdit_PopIzRet',                # after BmDrEdit_SkipEventAndContinue
    'LABEL_F3FDD2': 'Part_PopRetFA2',                   # pop_werp 0xFA; ret
    'LABEL_F43658': 'SeqVoice_PopRetFA',                # pop_werp 0xFA; ret
    'LABEL_F8307C': 'LswPercDecay_PopIzRet',            # after LswPercDecay
    'LABEL_F8318B': 'LswPercLevel_PopIzRet',            # after LswPercLevel
    'LABEL_F8326C': 'LswDrawAttack_PopIzRet',           # after LswDrawAttack
    'LABEL_F8334D': 'LswDrawRelease_PopIzRet',          # after LswDrawRelease
    'LABEL_FB713F': 'EffectMode_PopIzRet',              # pop xiz; ret in effect mode area
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
