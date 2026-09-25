#!/usr/bin/env python3
"""sequi_rename_case_bases.py -- the rename + header pass of 2026-09-25 (lane sequi).

JOB: nine labels on CODE carried data-shaped names (`*_ByteData*`, `*Data`,
`*JumpTable`, `*DispatchTable`, `*_CodeBlock`); seven of them are the base
label of a `jp_ind` switch (jp (xix + r), xix = the label), i.e. the offset-0
case.  Renames them (and their `_Skip`/`_Join` sub-labels, by prefix) and
inserts a header before each.  Applied once; kept as the record of the exact
transformation.  Comment gate: scripts/analysis/assert_comments_preserved.py
--rename-map notes/sequi-2026-09-25/rename-case-bases.map.

RUN (already applied; a re-run renames nothing and adds no second header)
    python3 scripts/renaming/sequi_rename_case_bases.py FILE...
"""
import re, sys
REN = {
 'NoteEdit_ParamJumpTable': 'NoteEdit_GetParamValue_Cases',
 'SqplyVal_ExtraParamsData': 'SqplyVal_ParamCases',
 'SqedtVal_DrawParamsData': 'SqedtVal_ParamCases',
 'SqplyFunc_ParamFormatData': 'SqplyFunc_FormatCases',
 'EqFormat_DispatchTable': 'Equalizer_FormatCases',
 'TrAsGridChk_ByteData': 'TrAsGridCheck_Cases',
 'TrAsGrid_ByteData1': 'TrAsGrid_StepListValue',
 'SeqStep_NoteByteBlock': 'SeqStep_NoteCases',
 'SMF_ConfigSlot_CodeBlock': 'SMF_AdvanceInPageChain',
}
CASES = {
 'NoteEdit_GetParamValue_Cases': 'NoteEdit_GetParamValue (xde-1 = 0..13; word offsets at ExtDevice_ModeDispatch_Table_0x200)',
 'SqplyVal_ParamCases': 'the SqplyVal handler above (index 0..7; word offsets at ExtDevice_ModeDispatch_Table_0x334)',
 'SqedtVal_ParamCases': 'the SqedtVal handler above (index 0..14; word offsets at ExtDevice_ModeDispatch_Table_0x344)',
 'SqplyFunc_FormatCases': 'the SqplyFunc handler above (events 0x1E8003E-0x1E80047; word offsets at ExtDevice_ModeDispatch_Table_0x660)',
 'Equalizer_FormatCases': 'Equalizer_FormatDispatch (word offsets at NakaInst_2d_0x204)',
 'TrAsGridCheck_Cases': 'TrAsGridCheck (events 0x1C00017-0x1C0001D; word offsets at NakaWidgetPtrTbl_SmfDp_0x2420)',
 'SeqStep_NoteCases': 'the dispatcher above (event byte 0x80-0x86; word offsets at Display_FontPalette_Table_0x7E)',
}
for p in sys.argv[1:]:
    s = open(p, encoding='latin-1').read()
    pat = re.compile(r'(?<![\w.$@])(%s)(?=[\w.$@]*)' % "|".join(map(re.escape, REN)))
    # rename in the CODE part of each line only: the headers below say
    # "formerly <old name>", and no pre-existing comment mentioned an old name
    lines = s.split('\n')
    for i, ln in enumerate(lines):
        k = ln.find(';')
        code, com = (ln, '') if k < 0 else (ln[:k], ln[k:])
        lines[i] = pat.sub(lambda m: REN[m.group(1)], code) + com
    s = '\n'.join(lines)
    for lab, who in CASES.items():
        key = '\n%s:\n' % lab
        if key in s and ('; code.' + key) not in s:
            s = s.replace(key, '''
; Case bodies of the `jp_ind` switch in %s: jp (xix + r) with xix = this
; label, so this label is the offset-0 case.  Formerly named as data; it is
; code.
%s:
''' % (who, lab), 1)
    key = '\nTrAsGrid_StepListValue:\n'
    if key in s and ('the TrAsGridCheck cases.' + key) not in s:
        s = s.replace(key, '''
; TrAsGrid_StepListValue (formerly TrAsGrid_ByteData1: it is code) -- A :=
; position of value A in the 20-entry list NakaWidgetPtrTbl_SmfDp_0x23B8; step
; it up (C == 0, stopping at 19) or down (stopping at 0); return in L the
; list value at the new position from NakaWidgetPtrTbl_SmfDp_0x23CC.  Called
; by the TrAsGridCheck cases.
TrAsGrid_StepListValue:
''', 1)
    key = '\nSMF_AdvanceInPageChain:\n'
    if key in s and ('on its address).' + key) not in s:
        s = s.replace(key, '''
; SMF_AdvanceInPageChain (formerly SMF_ConfigSlot_CodeBlock) -- RAM 0x113F :=
; word 0x2887; word 0x1141 := IY + 1; once that passes 255, follow the link
; word at +3 of the record RAM 0x2881 points to: store it in 0x113F and
; 0x2887, turn it into an address through SMF_CalcPageAddress (0x100 bytes per
; page, base in RAM 0x1D5A), and either stop with RAM 0x287A := 2 (bit 7 of
; the new page's first byte clear) or continue there with 0x1141 := 5, IY := 5.
; NO CALLER FOUND (scripts/analysis/sequi_find_refs.py on its address).
SMF_AdvanceInPageChain:
''', 1)
    open(p, 'w', encoding='latin-1').write(s)
    print('ok', p)
