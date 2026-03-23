; ===========================================================================
; Composer / MSP (Music Style Preset) Default Configuration
; ===========================================================================
;
; MSP is the Music Style Preset system - user-saveable performance setups
; that capture sound selections, accompaniment style, tempo, and panel
; settings. "Cmp" = Composer (the style editor/recorder). "S2c" = Song-to-
; Composer (import a song as a custom accompaniment).
;
; This file contains:
;
; 1. MSP_DefaultSettings - Initial parameter values for a new MSP preset
;    Three sub-blocks, each beginning with an "HK" signature (0x48, 0x4b):
;      Sub-block 1 (offset 0x00): Sound/voice defaults
;        - Default volumes (0x5a = 90 for 3 channels)
;        - Channel-to-part assignments (parts 1-2 across 8 slots)
;        - Reverb/chorus levels, voice enable bitmask (0x80..0x87)
;      Sub-block 2 (offset 0xe0): Sequencer defaults
;        - Tempo (0x28 = 40?), time signature, quantize settings
;      Sub-block 3 (offset 0x130): Accompaniment/rhythm defaults
;        - Part counts, group sizes, rhythm channel mapping
;        - Interleaved group/variation index tables
;        - Offset tables for rhythm pattern positioning
;
; 2. Composer_SettingsBlock - Composer UI configuration
;    - "HK" signature header
;    - Display layout parameters
;    - Bank name strings ("Compile Bank 1/2", "User Bank 1/2")
;    - Callback function pointer table (55 entries) for UI event handlers
;    - Null-terminated (.long 0 sentinel)
;
; 3. Composer_CallbackNameTable - Debug name string table
;    - Parallel array of .long pointers to FuncName_* strings
;    - One entry per callback, same order as the function pointer table
;    - Used by the NAKA widget system for debug/diagnostic display
;
; 4. FuncName_* strings - Null-terminated function name strings
;    - Each contains the ASCII name of a callback function
;    - Referenced only by Composer_CallbackNameTable
;
; ===========================================================================


; ---------------------------------------------------------------------------
; Sub-block 1: Sound/Voice Defaults (offset 0x00, 224 bytes)
; ---------------------------------------------------------------------------
MSP_DefaultSettings:
MSP_Default_SoundVoice:
MSP_Default_Signature1:		.byte 0x48, 0x00, 0x4b, 0x00	; "H\0K\0"
MSP_Default_Flags1:		.long 0x00000000
MSP_Default_Padding1:		.byte 0x00, 0x00, 0x00
MSP_Default_Volume:		.byte 90, 90, 90		; (3 channels, range 0-99)
MSP_Default_VolumeFlags:	.short 0x0000
MSP_Default_BankSelect:		.byte 1
MSP_Default_BankFlags:		.long 0x00000000
MSP_Default_PartAssign1:	.byte 1, 1, 1, 1		; channels 1-4
MSP_Default_PartAssign2:	.byte 2, 2, 2, 2		; channels 5-8
MSP_Default_PartFlags:		.byte 0x00
MSP_Default_ReverbLevel:	.byte 128		; range 0-127
MSP_Default_ChorusLevel:	.byte 22		; range 0-127
MSP_Default_PanPosition1:	.byte 96, 0		; slightly right of center
MSP_Default_PanPosition2:	.byte 96, 0		; slightly right of center
MSP_Default_EffectDepth:	.byte 30, 0
MSP_Default_VoiceMode:		.byte 0, 1
MSP_Default_Transpose:		.byte 84		; offset-encoded
MSP_Default_OctaveShift:	.byte 1
MSP_Default_TouchSense:		.byte 64		; range 0-127
MSP_Default_TouchFlags:		.byte 0x00, 0x00, 0x00
MSP_Default_ReverbLevel2:	.byte 128		; range 0-127
MSP_Default_ChorusLevel2:	.byte 22		; range 0-127
MSP_Default_SoundPadding:	.zero 48
MSP_Default_VoiceEnable:	.byte 0x80
MSP_Default_VoiceMask:		.byte 0xff, 0xff, 0xff, 0xff	; all channels enabled
MSP_Default_VoiceConfig:	.byte 0x87
MSP_Default_VoiceFlags1:	.byte 0x81, 0x81
MSP_Default_VoiceFlags2:	.byte 0x81, 0x81, 0x81, 0x81
MSP_Default_VoiceFlags3:	.byte 0x81, 0x81
MSP_Default_VoiceFlags4:	.byte 0x83, 0x87
MSP_Default_SoundReserved:	.zero 112

; ---------------------------------------------------------------------------
; Sub-block 2: Sequencer Defaults (offset 0xe0, 96 bytes)
; ---------------------------------------------------------------------------
MSP_Default_Sequencer:
MSP_Default_Signature2:		.byte 0x48, 0x00, 0x4b, 0x00	; "H\0K\0"
MSP_Default_SeqFlags:		.long 0x00000000
MSP_Default_Tempo:		.byte 40, 0		; internal units
MSP_Default_TimeSig:		.byte 4, 0		; numerator
MSP_Default_Quantize:		.byte 16, 0		; 16th note
MSP_Default_SeqMode:		.byte 0, 1
MSP_Default_SeqReserved:	.zero 80

; ---------------------------------------------------------------------------
; Sub-block 3: Accompaniment/Rhythm Defaults (offset 0x140, ~1220 bytes)
; ---------------------------------------------------------------------------
MSP_Default_Accompaniment:
MSP_Default_Signature3:		.byte 0x48, 0x00, 0x4b, 0x00	; "H\0K\0"
MSP_Default_AccompFlags:	.long 0x00000000
MSP_Default_NumParts:		.byte 20, 0
MSP_Default_PartsField1:	.byte 0x00, 0x00
MSP_Default_NumVariations:	.byte 10, 0
MSP_Default_VarField1:		.byte 0x00, 0x00
MSP_Default_NumGroups:		.byte 7, 0
MSP_Default_GroupField1:	.byte 0x00, 0x00
MSP_Default_PartsPerGroup:	.byte 3, 0
MSP_Default_GroupField2:	.byte 0x00, 0x00
MSP_Default_NumChannels:	.byte 8, 0
MSP_Default_ChannelField:	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
MSP_Default_AccompPad1:		.zero 32
MSP_Default_RhythmFlags:	.byte 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
MSP_Default_AccompPad2:		.zero 24
MSP_Default_RhythmConfig:	.byte 0x00, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
MSP_Default_AccompReserved:	.zero 920

; Rhythm channel mapping table (30 entries + 10 padding)
; Maps interleaved part indices: group 0=[0,4,8], group 1=[1,5,9], ...
MSP_Default_ChannelMap:		.byte  0,  4,  8,  1,  5,  9,  2,  6
				.byte 10,  3,  7, 11, 12, 18, 24, 13
				.byte 19, 25, 14, 20, 26, 15, 21, 27
				.byte 16, 22, 28, 17, 23, 29,  0,  0
MSP_Default_ChannelMapPad:	.zero 8

; Group index table: maps each of 20 parts to its group (1-7)
MSP_Default_GroupIndex:		.byte 1, 1, 1		; parts 0-2
				.byte 2, 2, 2		; parts 3-5
				.byte 3, 3, 3		; parts 6-8
				.byte 4, 4, 4		; parts 9-11
				.byte 5, 5, 5		; parts 12-14
				.byte 6, 6, 6		; parts 15-17
				.byte 7, 7		; parts 18-19
MSP_Default_GroupIndexPad:	.zero 10

; Variation index table: maps each of 20 parts to its variation (0-2)
MSP_Default_VarIndex:		.byte 0, 1, 2		; group 1
				.byte 0, 1, 2		; group 2
				.byte 0, 1, 2		; group 3
				.byte 0, 1, 2		; group 4
				.byte 0, 1, 2		; group 5
				.byte 0, 1, 2		; group 6
				.byte 0, 1		; group 7 (2 parts)

; Group offset table A (byte offsets for 7 groups)
MSP_Default_GroupOffsetA:	.short 0, 6, 12, 18, 24, 30, 36

; Group offset table B (duplicate)
MSP_Default_GroupOffsetB:	.short 0, 6, 12, 18, 24, 30, 36

; Variation size table (cumulative)
MSP_Default_VarSize:		.short 0, 10, 100, 109, 118, 127, 136	; cumulative

; Part-to-bank mapping (14 entries)
MSP_Default_PartBankMap:	.byte 0, 0		; part 0: bank 0.0
				.byte 0, 1		; part 1: bank 0.1
				.byte 0, 2		; part 2: bank 0.2
				.byte 0, 3		; part 3: bank 0.3
				.byte 0, 4		; part 4: bank 0.4
				.byte 0, 5		; part 5: bank 0.5
				.byte 0, 0		; entry 6
				.byte 0, 0		; entry 7
				.byte 1, 0		; entry 8: bank 1.0
				.byte 1, 1		; entry 9: bank 1.1
				.byte 1, 2		; entry 10: bank 1.2
				.byte 1, 3		; entry 11: bank 1.3
				.byte 1, 4		; entry 12: bank 1.4
				.byte 1, 5		; entry 13: bank 1.5
MSP_Default_TrailingPad:	.zero 36

Composer_SettingsBlock:
	.byte 0x48, 0x00, 0x4b, 0x00, 0x00, 0x03
	.zero 90

	.byte 0x20, 0x00, 0xc0, 0x00
	.byte 0x0c, 0x00, 0x00, 0x01, 0x39, 0x00, 0x0c, 0x00
	.byte 0x00, 0x00, 0xc0, 0x03, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7f
	.byte 0x40, 0x00, 0x00, 0x00
	.ascii " Compile Bank 1  Compile Bank 2                                    User Bank 1     User Bank 2                                  "
	.long CmpBndRngFunc
	.long CmpNamingCheck
	.long CmpNameOkFunc
	.long MspNamingCheck
	.long MspNameOkFunc
	.long CmpClrYesFunc
	.long CmpClrNoFunc
	.long CmpSetP1GridCheck
	.long CmpSetGridCheck
	.long S2cGridCheck
	.long MspRGrpSetGridCheck
	.long MspRGrpSetBnkFunc
	.long MspNameBnkFunc
	.long MspPlayModeFunc
	.long EasyCmpGridCheck
	.long ApcOnOffFunc
	.long ApcOnBasFunc
	.long SndArgTtlCheck
	.long SndArgGridCheck
	.long StylCnvStorBnkSel
	.long CmpSetPageFunc
	.long StylCnvStorOkFunc
	.long MspBnkShow
	.long S2cShowHideFunc
	.long MspRgpShowHideFunc
	.long AcMemNoBoxProc
	.long AcCmpMdBoxProc
	.long AcApcMdBoxProc
	.long AcMspBnkSlBoxProc
	.long VwVariBoxProc
	.long AcCmpTempoBoxProc
	.long AcCmpRecBoxProc
	.long PsCmpQtzBoxProc
	.long PsCmpMeasBoxProc
	.long PsCmpMemBoxProc
	.long PsS2cFmeasBoxProc
	.long PsS2cLmeasBoxProc
	.long PsSeqSongNoBoxProc
	.long PsS2cTransBoxProc
	.long AcS2cMemNoBoxProc
	.long PsCstmCpBnkBoxProc
	.long PsCstmCpSwBoxProc
	.long PsCmpCpFGrpBoxProc
	.long PsCmpCpFVariBoxProc
	.long PsCmpCpFPtnBoxProc
	.long PsNameMemBoxProc
	.long AcCmpSetGridBoxProc
	.long PsRgpSetBnkBoxProc
	.long PsMspBnkNameBoxProc
	.long AcEasyCmpGridBoxProc
	.long PsMspMeasBoxProc
	.long PsMspMemBoxProc
	.long PsMspRecPadBoxProc
	.long PsMspRecBnkBoxProc
	.long PsCstmCpNameBoxProc
	.long AcApcToggleProc
	.long PsMspNameBnkProc
	.long AcSndArgGridBoxProc
	.long PsParaListBoxProc
	.long PsSCTxtBoxProc
	.long PsSCTxtBox2Proc
	.long CmpNameMenuBoxProc
	.long PsCtmAttStrBoxProc
	.long S2cGridBoxProc
	.long AttLangCheck
	.long SureLangCheck
	.long SndMemLangCheck
	.long SndMem1LangCheck
	.long MemfulLangCheck
	.long Memful2LangCheck
	.long StylCnvLangCheck
	.long SndArrLangCheck
	.long PsStylCnvVerProc
	.long 0
Composer_CallbackNameTable:
	.long FuncName_CmpBndRngFunc
	.long FuncName_CmpNamingCheck
	.long FuncName_CmpNameOkFunc
	.long FuncName_MspNamingCheck
	.long FuncName_MspNameOkFunc
	.long FuncName_CmpClrYesFunc
	.long FuncName_CmpClrNoFunc
	.long FuncName_CmpSetP1GridCheck
	.long FuncName_CmpSetGridCheck
	.long FuncName_S2cGridCheck
	.long FuncName_MspRGrpSetGridCheck
	.long FuncName_MspRGrpSetBnkFunc
	.long FuncName_MspNameBnkFunc
	.long FuncName_MspPlayModeFunc
	.long FuncName_EasyCmpGridCheck
	.long FuncName_ApcOnOffFunc
	.long FuncName_ApcOnBasFunc
	.long FuncName_SndArgTtlCheck
	.long FuncName_SndArgGridCheck
	.long FuncName_StylCnvStorBnkSel
	.long FuncName_CmpSetPageFunc
	.long FuncName_StylCnvStorOkFunc
	.long FuncName_MspBnkShow
	.long FuncName_S2cShowHideFunc
	.long FuncName_MspRgpShowHideFunc
	.long FuncName_AcMemNoBoxProc
	.long FuncName_AcCmpMdBoxProc
	.long FuncName_AcApcMdBoxProc
	.long FuncName_AcMspBnkSlBoxProc
	.long FuncName_VwVariBoxProc
	.long FuncName_AcCmpTempoBoxProc
	.long FuncName_AcCmpRecBoxProc
	.long FuncName_PsCmpQtzBoxProc
	.long FuncName_PsCmpMeasBoxProc
	.long FuncName_PsCmpMemBoxProc
	.long FuncName_PsS2cFmeasBoxProc
	.long FuncName_PsS2cLmeasBoxProc
	.long FuncName_PsSeqSongNoBoxProc
	.long FuncName_PsS2cTransBoxProc
	.long FuncName_AcS2cMemNoBoxProc
	.long FuncName_PsCstmCpBnkBoxProc
	.long FuncName_PsCstmCpSwBoxProc
	.long FuncName_PsCmpCpFGrpBoxProc
	.long FuncName_PsCmpCpFVariBoxProc
	.long FuncName_PsCmpCpFPtnBoxProc
	.long FuncName_PsNameMemBoxProc
	.long FuncName_AcCmpSetGridBoxProc
	.long FuncName_PsRgpSetBnkBoxProc
	.long FuncName_PsMspBnkNameBoxProc
	.long FuncName_AcEasyCmpGridBoxProc
	.long FuncName_PsMspMeasBoxProc
	.long FuncName_PsMspMemBoxProc
	.long FuncName_PsMspRecPadBoxProc
	.long FuncName_PsMspRecBnkBoxProc
	.long FuncName_PsCstmCpNameBoxProc
	.long FuncName_AcApcToggleProc
	.long FuncName_PsMspNameBnkProc
	.long FuncName_AcSndArgGridBoxProc
	.long FuncName_PsParaListBoxProc
	.long FuncName_PsSCTxtBoxProc
	.long FuncName_PsSCTxtBox2Proc
	.long FuncName_CmpNameMenuBoxProc
	.long FuncName_PsCtmAttStrBoxProc
	.long FuncName_S2cGridBoxProc
	.long FuncName_AttLangCheck
	.long FuncName_SureLangCheck
	.long FuncName_SndMemLangCheck
	.long FuncName_SndMem1LangCheck
	.long FuncName_MemfulLangCheck
	.long FuncName_Memful2LangCheck
	.long FuncName_StylCnvLangCheck
	.long FuncName_SndArrLangCheck
	.long FuncName_PsStylCnvVerProc
	.long FuncName_Empty_0
FuncName_Empty_0:		aligned_string ""
FuncName_PsStylCnvVerProc:	aligned_string "PsStylCnvVerProc"
FuncName_SndArrLangCheck:	aligned_string "SndArrLangCheck"
FuncName_StylCnvLangCheck:	aligned_string "StylCnvLangCheck"
FuncName_Memful2LangCheck:	aligned_string "Memful2LangCheck"
FuncName_MemfulLangCheck:	aligned_string "MemfulLangCheck"
FuncName_SndMem1LangCheck:	aligned_string "SndMem1LangCheck"
FuncName_SndMemLangCheck:	aligned_string "SndMemLangCheck"
FuncName_SureLangCheck:		aligned_string "SureLangCheck"
FuncName_AttLangCheck:		aligned_string "AttLangCheck"
FuncName_S2cGridBoxProc:	aligned_string "S2cGridBoxProc"
FuncName_PsCtmAttStrBoxProc:	aligned_string "PsCtmAttStrBoxProc"
FuncName_CmpNameMenuBoxProc:	aligned_string "CmpNameMenuBoxProc"
FuncName_PsSCTxtBox2Proc:	aligned_string "PsSCTxtBox2Proc"
FuncName_PsSCTxtBoxProc:	aligned_string "PsSCTxtBoxProc"
FuncName_PsParaListBoxProc:	aligned_string "PsParaListBoxProc"
FuncName_AcSndArgGridBoxProc:	aligned_string "AcSndArgGridBoxProc"
FuncName_PsMspNameBnkProc:	aligned_string "PsMspNameBnkProc"
FuncName_AcApcToggleProc:	aligned_string "AcApcToggleProc"
FuncName_PsCstmCpNameBoxProc:	aligned_string "PsCstmCpNameBoxProc"
FuncName_PsMspRecBnkBoxProc:	aligned_string "PsMspRecBnkBoxProc"
FuncName_PsMspRecPadBoxProc:	aligned_string "PsMspRecPadBoxProc"
FuncName_PsMspMemBoxProc:	aligned_string "PsMspMemBoxProc"
FuncName_PsMspMeasBoxProc:	aligned_string "PsMspMeasBoxProc"
FuncName_AcEasyCmpGridBoxProc:	aligned_string "AcEasyCmpGridBoxProc"
FuncName_PsMspBnkNameBoxProc:	aligned_string "PsMspBnkNameBoxProc"
FuncName_PsRgpSetBnkBoxProc:	aligned_string "PsRgpSetBnkBoxProc"
FuncName_AcCmpSetGridBoxProc:	aligned_string "AcCmpSetGridBoxProc"
FuncName_PsNameMemBoxProc:	aligned_string "PsNameMemBoxProc"
FuncName_PsCmpCpFPtnBoxProc:	aligned_string "PsCmpCpFPtnBoxProc"
FuncName_PsCmpCpFVariBoxProc:	aligned_string "PsCmpCpFVariBoxProc"
FuncName_PsCmpCpFGrpBoxProc:	aligned_string "PsCmpCpFGrpBoxProc"
FuncName_PsCstmCpSwBoxProc:	aligned_string "PsCstmCpSwBoxProc"
FuncName_PsCstmCpBnkBoxProc:	aligned_string "PsCstmCpBnkBoxProc"
FuncName_AcS2cMemNoBoxProc:	aligned_string "AcS2cMemNoBoxProc"
FuncName_PsS2cTransBoxProc:	aligned_string "PsS2cTransBoxProc"
FuncName_PsSeqSongNoBoxProc:	aligned_string "PsSeqSongNoBoxProc"
FuncName_PsS2cLmeasBoxProc:	aligned_string "PsS2cLmeasBoxProc"
FuncName_PsS2cFmeasBoxProc:	aligned_string "PsS2cFmeasBoxProc"
FuncName_PsCmpMemBoxProc:	aligned_string "PsCmpMemBoxProc"
FuncName_PsCmpMeasBoxProc:	aligned_string "PsCmpMeasBoxProc"
FuncName_PsCmpQtzBoxProc:	aligned_string "PsCmpQtzBoxProc"
FuncName_AcCmpRecBoxProc:	aligned_string "AcCmpRecBoxProc"
FuncName_AcCmpTempoBoxProc:	aligned_string "AcCmpTempoBoxProc"
FuncName_VwVariBoxProc:		aligned_string "VwVariBoxProc"
FuncName_AcMspBnkSlBoxProc:	aligned_string "AcMspBnkSlBoxProc"
FuncName_AcApcMdBoxProc:	aligned_string "AcApcMdBoxProc"
FuncName_AcCmpMdBoxProc:	aligned_string "AcCmpMdBoxProc"
FuncName_AcMemNoBoxProc:	aligned_string "AcMemNoBoxProc"
FuncName_MspRgpShowHideFunc:	aligned_string "MspRgpShowHideFunc"
FuncName_S2cShowHideFunc:	aligned_string "S2cShowHideFunc"
FuncName_MspBnkShow:		aligned_string "MspBnkShow"
FuncName_StylCnvStorOkFunc:	aligned_string "StylCnvStorOkFunc"
FuncName_CmpSetPageFunc:	aligned_string "CmpSetPageFunc"
FuncName_StylCnvStorBnkSel:	aligned_string "StylCnvStorBnkSel"
FuncName_SndArgGridCheck:	aligned_string "SndArgGridCheck"
FuncName_SndArgTtlCheck:	aligned_string "SndArgTtlCheck"
FuncName_ApcOnBasFunc:		aligned_string "ApcOnBasFunc"
FuncName_ApcOnOffFunc:		aligned_string "ApcOnOffFunc"
FuncName_EasyCmpGridCheck:	aligned_string "EasyCmpGridCheck"
FuncName_MspPlayModeFunc:	aligned_string "MspPlayModeFunc"
FuncName_MspNameBnkFunc:	aligned_string "MspNameBnkFunc"
FuncName_MspRGrpSetBnkFunc:	aligned_string "MspRGrpSetBnkFunc"
FuncName_MspRGrpSetGridCheck:	aligned_string "MspRGrpSetGridCheck"
FuncName_S2cGridCheck:		aligned_string "S2cGridCheck"
FuncName_CmpSetGridCheck:	aligned_string "CmpSetGridCheck"
FuncName_CmpSetP1GridCheck:	aligned_string "CmpSetP1GridCheck"
FuncName_CmpClrNoFunc:		aligned_string "CmpClrNoFunc"
FuncName_CmpClrYesFunc:		aligned_string "CmpClrYesFunc"
FuncName_MspNameOkFunc:		aligned_string "MspNameOkFunc"
FuncName_MspNamingCheck:	aligned_string "MspNamingCheck"
FuncName_CmpNameOkFunc:		aligned_string "CmpNameOkFunc"
FuncName_CmpNamingCheck:	aligned_string "CmpNamingCheck"
FuncName_CmpBndRngFunc:		aligned_string "CmpBndRngFunc"

