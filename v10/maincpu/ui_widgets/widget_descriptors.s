
; =============================================================================
; Widget Descriptor Tables & Grid Data  (ROM 0xE30E60-0xE55BC7, 150888 bytes)
; Source: maincpu/ui_widgets/naka_widget_descriptors.c (compiled, then .incbin'd)
; =============================================================================
; One packed C struct covering the whole blob.  Most of it is NAKA widget
; descriptor material; the labels below name the parts that other modules
; reach into.
;
; DSP EFFECT NAMING ZONE (0xE32418-0xE33579)
; -----------------------------------------
; The user-facing naming layer of the effects DSP.  Four tables, all consumed
; by the effect-editor handlers in sequencer/sequencer_ui.s:
;
;   0xE32418  DspParamUnit_Table     86 x  2  parameter unit  ("Hz", "ms", "s ")
;   0xE324C4  DspParamName_Table     86 x 17  parameter name + ':' separator
;   0xE32A7A  DspEffectName_PtrTable 128 x u32, indexed by EFFECT NUMBER
;   0xE32C7A  DspEffectName_Strings  128 x 18  16 chars + 0x00 + 0xFF filler
;
; DspEffectName_PtrTable[n] points at DspEffectName_Strings + 18*(127-n): the
; string block is stored in DESCENDING effect order, which is why the existing
; NakaInst_<EFFECT> labels below run from effect 127 (lowest address) down to
; effect 0 (highest).  Effect numbers 100-127 are "   ----------   " spares.
;
; The unit and name tables share one index: the parameter-id byte of the
; effect's ordered UI parameter list.  Slots 0 and 85 are blank spares.
;
; Consumers (sequencer/sequencer_ui.s):
;   DspItem0_DisplayEffectName  0xF355F3  effect no. (RAM 0x2976) -> ptr table
;   DspItem0_DisplayParamNames  0xF3561F  param id -> name, Strncpy 17
;   DspItem0_DisplayParamValues 0xF3566C  param id -> unit, Strncpy 2
;   EntGridCheck (0xF30326 region)        also reads DspEffectName_PtrTable
;
; Both parameter routines take the id from the per-effect ordered id list at
; RAM 0x29AC, starting at the row index held in the byte at 0x021098, and
; paint 8 rows per page.
;
; The algorithms these names label live in the sub-CPU payload; see
; v142/subcpu/subcpu_data_tables.s (DSP_EffNN_* / DSP2_EffNN_* blocks) and
; kn5000-docs/dsp-effect-data-zone.md.
; =============================================================================
NakaData_WidgetDescriptors:
	.incbin "includes/generated/naka_widget_descriptors.bin", 0, 0x24400
EmbeddedPtrTable_v10_naka_widget_descriptors_024400:
	.long CtlMsgGridCheck
	.long TtMdPart
	.long MidiPartGridCheck
	.long TtMdExc
	.long ExcSendFunc
	.long ExcDotFunc
	.long ExcPmemFunc
	.long ExcSmemFunc
	.long ExcCompFunc
	.long ExcSeqFunc
	.long ExcMspFunc
	.long TtMdPreset
	.long MdPresetOKFunc
	.long MdPresetWithoutFunc
	.long MdPresetWithFunc
	.long BitmapBmphk
	.long TtMdGm
	.long GMOKFunc
	.long StsAttentionCheck
	.long StsGMOnCheck
	.long StsGMOffCheck
	.long StsAreYouSureCheck
	.long GMYesFunc
	.long GMNoFunc
	.long HarmOnOffFunc
	.long TtVocalistWorkstation
	.long VocalistGridCheck
	.long VocalistPage1OKFunc
	.long VocalistPage2OKFunc
	.long TtFadeInOut
	.long FadeSetGridCheck
	.long TtMdInOut
	.long InOutGridCheck
	.long StsSplitCheck
	.long SplitPointFunc
	.long RevSelFunc
	.long EqSelFunc
	.long EqOnOffFunc
	.long RevEqSelFunc
	.long RevEqOnOffFunc
	.long 0x00000000
	.long NakaInst_TtMdmenu
	.long NakaInst_TtMdRealMsg
	.long NakaInst_MdPcgModeFunc
	.long NakaInst_MdDrumTypeFunc
	.long NakaInst_MdSetupLoadFunc
	.long NakaInst_TtComputerConnection
	.long NakaInst_MdCmptCnctFunc
	.long NakaInst_R12OctaveFunc
	.long NakaInst_TtMdParaLoad
	.long NakaInst_ParaLoadOptGridCheck
	.long NakaInst_ParaLoadOptOKFunc
	.long NakaInst_TtMdPcgOut
	.long NakaInst_PcgOutGridCheck
	.long NakaInst_PcgOutSendFunc
	.long NakaInst_TtComSet
	.long NakaInst_ComSetGridCheck
	.long NakaInst_TtMdPmemOut
	.long NakaInst_PmemOutLGridCheck
	.long NakaInst_PmemOutRGridCheck
	.long NakaInst_TtMdCtlMsg
	.long NakaInst_CtlMsgGridCheck
	.long NakaInst_TtMdPart
	.long NakaInst_MidiPartGridCheck
	.incbin "includes/generated/naka_widget_descriptors.bin", 0x24500, 0x868

; External label offsets within the binary blob above.
; The NakaInst_<EFFECT> run starting at +0x01e1a IS DspEffectName_Strings:
; NakaInst_FxReservedSlot_00 (+0x01e1a) is effect 127 and
; NakaInst_NO_OPERATION (+0x02708) is effect 0 -- so the effect number of
; any label in that run is (0x02708 - offset) / 18.

; --- DSP effect naming zone: table bases ---------------------------------
	.equ DspParamUnit_Table, NakaData_WidgetDescriptors + 0x015b8	; 0xE32418, 86 x 2
	.equ DspParamName_Table, NakaData_WidgetDescriptors + 0x01664	; 0xE324C4, 86 x 17
	.equ DspEffectName_PtrTable, NakaData_WidgetDescriptors + 0x01c1a	; 0xE32A7A, 128 x u32
	.equ DspEffectName_Strings, NakaData_WidgetDescriptors + 0x01e1a	; 0xE32C7A, 128 x 18

; --- DSP parameter slots: name at +0x11*i, unit at DspParamUnit_Table+2*i -
	.equ DspParamName_00_Blank, NakaData_WidgetDescriptors + 0x01664	; slot  0 "(spare)"
	.equ DspParamName_01_VOLUME, NakaData_WidgetDescriptors + 0x01675	; slot  1 "VOLUME"
	.equ DspParamName_02_VOLUME, NakaData_WidgetDescriptors + 0x01686	; slot  2 "VOLUME"
	.equ DspParamName_03_REV_SEND, NakaData_WidgetDescriptors + 0x01697	; slot  3 "REV SEND"
	.equ DspParamName_04_DRIVE, NakaData_WidgetDescriptors + 0x016a8	; slot  4 "DRIVE"
	.equ DspParamName_05_ADJUST, NakaData_WidgetDescriptors + 0x016b9	; slot  5 "ADJUST"
	.equ DspParamName_06_EMPHASIS_GAIN, NakaData_WidgetDescriptors + 0x016ca	; slot  6 "EMPHASIS GAIN"
	.equ DspParamName_07_DEPTH, NakaData_WidgetDescriptors + 0x016db	; slot  7 "DEPTH"
	.equ DspParamName_08_LFO_SPEED, NakaData_WidgetDescriptors + 0x016ec	; slot  8 "LFO SPEED" [Hz]
	.equ DspParamName_09_SLOW_LFO_SPEED, NakaData_WidgetDescriptors + 0x016fd	; slot  9 "SLOW LFO SPEED" [Hz]
	.equ DspParamName_10_FAST_LFO_BALANCE, NakaData_WidgetDescriptors + 0x0170e	; slot 10 "FAST LFO BALANCE"
	.equ DspParamName_11_RESONANCE, NakaData_WidgetDescriptors + 0x0171f	; slot 11 "RESONANCE"
	.equ DspParamName_12_MANUAL, NakaData_WidgetDescriptors + 0x01730	; slot 12 "MANUAL"
	.equ DspParamName_13_SLOW_FAST, NakaData_WidgetDescriptors + 0x01741	; slot 13 "SLOW/FAST"
	.equ DspParamName_14_TREBLE_FAST, NakaData_WidgetDescriptors + 0x01752	; slot 14 "TREBLE FAST" [Hz]
	.equ DspParamName_15_SLOW, NakaData_WidgetDescriptors + 0x01763	; slot 15 "SLOW" [Hz]
	.equ DspParamName_16_WIND_UP, NakaData_WidgetDescriptors + 0x01774	; slot 16 "WIND UP" [s ]
	.equ DspParamName_17_WIND_DOWN, NakaData_WidgetDescriptors + 0x01785	; slot 17 "WIND DOWN" [s ]
	.equ DspParamName_18_BASS_FAST, NakaData_WidgetDescriptors + 0x01796	; slot 18 "BASS   FAST" [Hz]
	.equ DspParamName_19_BASS_SLOW, NakaData_WidgetDescriptors + 0x017a7	; slot 19 "BASS   SLOW" [Hz]
	.equ DspParamName_20_VOLUME_ADJUST, NakaData_WidgetDescriptors + 0x017b8	; slot 20 "VOLUME ADJUST"
	.equ DspParamName_21_OSC_SPEED, NakaData_WidgetDescriptors + 0x017c9	; slot 21 "OSC SPEED" [Hz]
	.equ DspParamName_22_DELAY_L, NakaData_WidgetDescriptors + 0x017da	; slot 22 "DELAY L" [ms]
	.equ DspParamName_23_DELAY_R, NakaData_WidgetDescriptors + 0x017eb	; slot 23 "DELAY R" [ms]
	.equ DspParamName_24_FEEDBACK_L, NakaData_WidgetDescriptors + 0x017fc	; slot 24 "FEEDBACK L"
	.equ DspParamName_25_FEEDBACK_R, NakaData_WidgetDescriptors + 0x0180d	; slot 25 "FEEDBACK R"
	.equ DspParamName_26_DELAY_DRY_WET, NakaData_WidgetDescriptors + 0x0181e	; slot 26 "DELAY DRY/WET"
	.equ DspParamName_27_CHORUS_DRY_WET, NakaData_WidgetDescriptors + 0x0182f	; slot 27 "CHORUS DRY/WET"
	.equ DspParamName_28_FLANGER_DRY_WET, NakaData_WidgetDescriptors + 0x01840	; slot 28 "FLANGER DRY/WET"
	.equ DspParamName_29_PHASER_DRY_WET, NakaData_WidgetDescriptors + 0x01851	; slot 29 "PHASER DRY/WET"
	.equ DspParamName_30_LOW_EMPHASIS_FC, NakaData_WidgetDescriptors + 0x01862	; slot 30 "LOW  EMPHASIS FC"
	.equ DspParamName_31_LOW_EMPHASIS_G, NakaData_WidgetDescriptors + 0x01873	; slot 31 "LOW  EMPHASIS  G"
	.equ DspParamName_32_HIGH_EMPHASIS_FC, NakaData_WidgetDescriptors + 0x01884	; slot 32 "HIGH EMPHASIS FC" [Hz]
	.equ DspParamName_33_HIGH_EMPHASIS_G, NakaData_WidgetDescriptors + 0x01895	; slot 33 "HIGH EMPHASIS  G"
	.equ DspParamName_34_REVERB_TIME, NakaData_WidgetDescriptors + 0x018a6	; slot 34 "REVERB TIME" [s ]
	.equ DspParamName_35_PRE_DELAY, NakaData_WidgetDescriptors + 0x018b7	; slot 35 "PRE DELAY" [ms]
	.equ DspParamName_36_HIGH_DAMP_GAIN, NakaData_WidgetDescriptors + 0x018c8	; slot 36 "HIGH DAMP GAIN"
	.equ DspParamName_37_ERLEVEL, NakaData_WidgetDescriptors + 0x018d9	; slot 37 "ER.LEVEL"
	.equ DspParamName_38_PITCH_L, NakaData_WidgetDescriptors + 0x018ea	; slot 38 "PITCH L"
	.equ DspParamName_39_PITCH_R, NakaData_WidgetDescriptors + 0x018fb	; slot 39 "PITCH R"
	.equ DspParamName_40_THRESHOLD, NakaData_WidgetDescriptors + 0x0190c	; slot 40 "THRESHOLD"
	.equ DspParamName_41_RATIO, NakaData_WidgetDescriptors + 0x0191d	; slot 41 "RATIO"
	.equ DspParamName_42_ATTACK_SENS, NakaData_WidgetDescriptors + 0x0192e	; slot 42 "ATTACK SENS." [s ]
	.equ DspParamName_43_RELEASE_SENS, NakaData_WidgetDescriptors + 0x0193f	; slot 43 "RELEASE SENS." [s ]
	.equ DspParamName_44_ATTACK_RATE, NakaData_WidgetDescriptors + 0x01950	; slot 44 "ATTACK RATE" [s ]
	.equ DspParamName_45_RELEASE_RATE, NakaData_WidgetDescriptors + 0x01961	; slot 45 "RELEASE RATE" [s ]
	.equ DspParamName_46_GATE_TIME, NakaData_WidgetDescriptors + 0x01972	; slot 46 "GATE TIME" [ms]
	.equ DspParamName_47_MASK_TIME, NakaData_WidgetDescriptors + 0x01983	; slot 47 "MASK TIME" [ms]
	.equ DspParamName_48_HARS_TIME, NakaData_WidgetDescriptors + 0x01994	; slot 48 "HARS TIME"
	.equ DspParamName_49_LFO_WAVEFORM, NakaData_WidgetDescriptors + 0x019a5	; slot 49 "LFO WAVEFORM"
	.equ DspParamName_50_OSC_WAVEFORM, NakaData_WidgetDescriptors + 0x019b6	; slot 50 "OSC WAVEFORM"
	.equ DspParamName_51_BAND_EMPHASIS_FC, NakaData_WidgetDescriptors + 0x019c7	; slot 51 "BAND EMPHASIS FC" [Hz]
	.equ DspParamName_52_BAND_EMPHASIS_Q, NakaData_WidgetDescriptors + 0x019d8	; slot 52 "BAND EMPHASIS  Q"
	.equ DspParamName_53_BAND_EMPHASIS_G, NakaData_WidgetDescriptors + 0x019e9	; slot 53 "BAND EMPHASIS  G"
	.equ DspParamName_54_LOW_MIX, NakaData_WidgetDescriptors + 0x019fa	; slot 54 "LOW MIX"
	.equ DspParamName_55_HIGH_MIX, NakaData_WidgetDescriptors + 0x01a0b	; slot 55 "HIGH MIX"
	.equ DspParamName_56_PHASE, NakaData_WidgetDescriptors + 0x01a1c	; slot 56 "PHASE"
	.equ DspParamName_57_FEEDBACK, NakaData_WidgetDescriptors + 0x01a2d	; slot 57 "FEEDBACK"
	.equ DspParamName_58_SWEEP_RANGE, NakaData_WidgetDescriptors + 0x01a3e	; slot 58 "SWEEP RANGE"
	.equ DspParamName_59_WAH_CENTER_FC, NakaData_WidgetDescriptors + 0x01a4f	; slot 59 "WAH CENTER FC"
	.equ DspParamName_60_HARS_TIME_L, NakaData_WidgetDescriptors + 0x01a60	; slot 60 "HARS TIME L" [ms]
	.equ DspParamName_61_HARS_TIME_R, NakaData_WidgetDescriptors + 0x01a71	; slot 61 "HARS TIME R" [ms]
	.equ DspParamName_62_BALANCE_L, NakaData_WidgetDescriptors + 0x01a82	; slot 62 "BALANCE L"
	.equ DspParamName_63_BALANCE_R, NakaData_WidgetDescriptors + 0x01a93	; slot 63 "BALANCE R"
	.equ DspParamName_64_FAST_LFO_SPEED_L, NakaData_WidgetDescriptors + 0x01aa4	; slot 64 "FAST LFO SPEED L" [Hz]
	.equ DspParamName_65_FAST_LFO_SPEED_R, NakaData_WidgetDescriptors + 0x01ab5	; slot 65 "FAST LFO SPEED R" [Hz]
	.equ DspParamName_66_MODULATION_DEPTH, NakaData_WidgetDescriptors + 0x01ac6	; slot 66 "MODULATION DEPTH"
	.equ DspParamName_67_DELAY1_DRY_WET, NakaData_WidgetDescriptors + 0x01ad7	; slot 67 "DELAY1 DRY/WET"
	.equ DspParamName_68_DELAY2_DRY_WET, NakaData_WidgetDescriptors + 0x01ae8	; slot 68 "DELAY2 DRY/WET"
	.equ DspParamName_69_VIBRATO_DRY_WET, NakaData_WidgetDescriptors + 0x01af9	; slot 69 "VIBRATO DRY/WET"
	.equ DspParamName_70_WAH_DRY_WET, NakaData_WidgetDescriptors + 0x01b0a	; slot 70 "WAH DRY/WET"
	.equ DspParamName_71_FAST_LFO_SPEED, NakaData_WidgetDescriptors + 0x01b1b	; slot 71 "FAST LFO SPEED" [Hz]
	.equ DspParamName_72_TREBLE_DEPTH, NakaData_WidgetDescriptors + 0x01b2c	; slot 72 "TREBLE DEPTH"
	.equ DspParamName_73_FAST, NakaData_WidgetDescriptors + 0x01b3d	; slot 73 "FAST" [Hz]
	.equ DspParamName_74_BASS_DEPTH, NakaData_WidgetDescriptors + 0x01b4e	; slot 74 "BASS DEPTH"
	.equ DspParamName_75_DELAY_1, NakaData_WidgetDescriptors + 0x01b5f	; slot 75 "DELAY 1" [ms]
	.equ DspParamName_76_DELAY_2, NakaData_WidgetDescriptors + 0x01b70	; slot 76 "DELAY 2" [ms]
	.equ DspParamName_77_DELAY_3, NakaData_WidgetDescriptors + 0x01b81	; slot 77 "DELAY 3" [ms]
	.equ DspParamName_78_DELAY_4, NakaData_WidgetDescriptors + 0x01b92	; slot 78 "DELAY 4" [ms]
	.equ DspParamName_79_PAN_1, NakaData_WidgetDescriptors + 0x01ba3	; slot 79 "PAN   1"
	.equ DspParamName_80_PAN_2, NakaData_WidgetDescriptors + 0x01bb4	; slot 80 "PAN   2"
	.equ DspParamName_81_PAN_3, NakaData_WidgetDescriptors + 0x01bc5	; slot 81 "PAN   3"
	.equ DspParamName_82_PAN_4, NakaData_WidgetDescriptors + 0x01bd6	; slot 82 "PAN   4"
	.equ DspParamName_83_INTENSITY, NakaData_WidgetDescriptors + 0x01be7	; slot 83 "INTENSITY"
	.equ DspParamName_84_EXCITE, NakaData_WidgetDescriptors + 0x01bf8	; slot 84 "EXCITE"
	.equ DspParamName_85_Blank, NakaData_WidgetDescriptors + 0x01c09	; slot 85 "(spare)"
	.equ NakaInst_FxReservedSlot_00, NakaData_WidgetDescriptors + 0x01e1a
	.equ NakaInst_FxReservedSlot_01, NakaData_WidgetDescriptors + 0x01e2c
	.equ NakaInst_FxReservedSlot_02, NakaData_WidgetDescriptors + 0x01e3e
	.equ NakaInst_FxReservedSlot_03, NakaData_WidgetDescriptors + 0x01e50
	.equ NakaInst_FxReservedSlot_04, NakaData_WidgetDescriptors + 0x01e62
	.equ NakaInst_FxReservedSlot_05, NakaData_WidgetDescriptors + 0x01e74
	.equ NakaInst_FxReservedSlot_06, NakaData_WidgetDescriptors + 0x01e86
	.equ NakaInst_FxReservedSlot_07, NakaData_WidgetDescriptors + 0x01e98
	.equ NakaInst_FxReservedSlot_08, NakaData_WidgetDescriptors + 0x01eaa
	.equ NakaInst_FxReservedSlot_09, NakaData_WidgetDescriptors + 0x01ebc
	.equ NakaInst_FxReservedSlot_10, NakaData_WidgetDescriptors + 0x01ece
	.equ NakaInst_FxReservedSlot_11, NakaData_WidgetDescriptors + 0x01ee0
	.equ NakaInst_FxReservedSlot_12, NakaData_WidgetDescriptors + 0x01ef2
	.equ NakaInst_FxReservedSlot_13, NakaData_WidgetDescriptors + 0x01f04
	.equ NakaInst_FxReservedSlot_14, NakaData_WidgetDescriptors + 0x01f16
	.equ NakaInst_FxReservedSlot_15, NakaData_WidgetDescriptors + 0x01f28
	.equ NakaInst_FxReservedSlot_16, NakaData_WidgetDescriptors + 0x01f3a
	.equ NakaInst_FxReservedSlot_17, NakaData_WidgetDescriptors + 0x01f4c
	.equ NakaInst_FxReservedSlot_18, NakaData_WidgetDescriptors + 0x01f5e
	.equ NakaInst_FxReservedSlot_19, NakaData_WidgetDescriptors + 0x01f70
	.equ NakaInst_FxReservedSlot_20, NakaData_WidgetDescriptors + 0x01f82
	.equ NakaInst_FxReservedSlot_21, NakaData_WidgetDescriptors + 0x01f94
	.equ NakaInst_FxReservedSlot_22, NakaData_WidgetDescriptors + 0x01fa6
	.equ NakaInst_FxReservedSlot_23, NakaData_WidgetDescriptors + 0x01fb8
	.equ NakaInst_FxReservedSlot_24, NakaData_WidgetDescriptors + 0x01fca
	.equ NakaInst_FxReservedSlot_25, NakaData_WidgetDescriptors + 0x01fdc
	.equ NakaInst_FxReservedSlot_26, NakaData_WidgetDescriptors + 0x01fee
	.equ NakaInst_FxReservedSlot_27, NakaData_WidgetDescriptors + 0x02000
	.equ NakaInst_PEQ_OVERDR_DELAY, NakaData_WidgetDescriptors + 0x02012
	.equ NakaInst_PEQ_DIST_DELAY, NakaData_WidgetDescriptors + 0x02024
	.equ NakaInst_PEQ_COMPR_OVERDR, NakaData_WidgetDescriptors + 0x02036
	.equ NakaInst_PEQ_COMPR_DIST, NakaData_WidgetDescriptors + 0x02048
	.equ NakaInst_FxComboReserved_0, NakaData_WidgetDescriptors + 0x0205a
	.equ NakaInst_FxComboReserved_1, NakaData_WidgetDescriptors + 0x0206c
	.equ NakaInst_FxComboReserved_2, NakaData_WidgetDescriptors + 0x0207e
	.equ NakaInst_FxComboReserved_3, NakaData_WidgetDescriptors + 0x02090
	.equ NakaInst_STAGE, NakaData_WidgetDescriptors + 0x020a2
	.equ NakaInst_BATH_ROOM, NakaData_WidgetDescriptors + 0x020b4
	.equ NakaInst_KARAOKE, NakaData_WidgetDescriptors + 0x020c6
	.equ NakaInst_ROOM, NakaData_WidgetDescriptors + 0x020d8
	.equ NakaInst_ReverbReserved_0, NakaData_WidgetDescriptors + 0x020ea
	.equ NakaInst_ReverbReserved_1, NakaData_WidgetDescriptors + 0x020fc
	.equ NakaInst_ReverbReserved_2, NakaData_WidgetDescriptors + 0x0210e
	.equ NakaInst_ReverbReserved_3, NakaData_WidgetDescriptors + 0x02120
	.equ NakaInst_ReverbReserved_4, NakaData_WidgetDescriptors + 0x02132
	.equ NakaInst_ReverbReserved_5, NakaData_WidgetDescriptors + 0x02144
	.equ NakaInst_OVER_D, NakaData_WidgetDescriptors + 0x02156
	.equ NakaInst_DS_D, NakaData_WidgetDescriptors + 0x02168
	.equ NakaInst_GEQ, NakaData_WidgetDescriptors + 0x0217a
	.equ NakaInst_EqReserved_0, NakaData_WidgetDescriptors + 0x0218c
	.equ NakaInst_EqReserved_1, NakaData_WidgetDescriptors + 0x0219e
	.equ NakaInst_EqReserved_2, NakaData_WidgetDescriptors + 0x021b0
	.equ NakaInst_PEQ_COMPRESSOR, NakaData_WidgetDescriptors + 0x021c2
	.equ NakaInst_PEQ_VIBRATO, NakaData_WidgetDescriptors + 0x021d4
	.equ NakaInst_PEQ_FLANGER, NakaData_WidgetDescriptors + 0x021e6
	.equ NakaInst_PEQ_S_DELAY, NakaData_WidgetDescriptors + 0x021f8
	.equ NakaInst_PEQ_CHORUS, NakaData_WidgetDescriptors + 0x0220a
	.equ NakaInst_AUTO_WAH_S_DELAY, NakaData_WidgetDescriptors + 0x0221c
	.equ NakaInst_PEDAL_WAH_DELAY, NakaData_WidgetDescriptors + 0x0222e
	.equ NakaInst_S_DELAY_PHASER, NakaData_WidgetDescriptors + 0x02240
	.equ NakaInst_S_DELAY_VIBRATO, NakaData_WidgetDescriptors + 0x02252
	.equ NakaInst_S_DELAY_FLANGER, NakaData_WidgetDescriptors + 0x02264
	.equ NakaInst_S_DELAY_S_DELAY, NakaData_WidgetDescriptors + 0x02276
	.equ NakaInst_S_DELAY_CHORUS, NakaData_WidgetDescriptors + 0x02288
	.equ NakaInst_STRING, NakaData_WidgetDescriptors + 0x0229a
	.equ NakaInst_ChorusReserved_0, NakaData_WidgetDescriptors + 0x022ac
	.equ NakaInst_ChorusReserved_1, NakaData_WidgetDescriptors + 0x022be
	.equ NakaInst_DEEP_SPACE, NakaData_WidgetDescriptors + 0x022d0
	.equ NakaInst_SYMPHONIC, NakaData_WidgetDescriptors + 0x022e2
	.equ NakaInst_PERCUSSIVE, NakaData_WidgetDescriptors + 0x022f4
	.equ NakaInst_STANDARD, NakaData_WidgetDescriptors + 0x02306
	.equ NakaInst_MIX_UP, NakaData_WidgetDescriptors + 0x02318
	.equ NakaInst_HARS_EFFECT, NakaData_WidgetDescriptors + 0x0232a
	.equ NakaInst_RING_MODULATOR, NakaData_WidgetDescriptors + 0x0233c
	.equ NakaInst_ROTARY_SPEAKER, NakaData_WidgetDescriptors + 0x0234e
	.equ NakaInst_AUTO_WAH, NakaData_WidgetDescriptors + 0x02360
	.equ NakaInst_PEDAL_WAH, NakaData_WidgetDescriptors + 0x02372
	.equ NakaInst_VIBRATO, NakaData_WidgetDescriptors + 0x02384
	.equ NakaInst_PITCH_SHIFTER, NakaData_WidgetDescriptors + 0x02396
	.equ NakaInst_AUTO_PAN, NakaData_WidgetDescriptors + 0x023a8
	.equ NakaInst_ModulationReserved_0, NakaData_WidgetDescriptors + 0x023ba
	.equ NakaInst_ModulationReserved_1, NakaData_WidgetDescriptors + 0x023cc
	.equ NakaInst_CELM, NakaData_WidgetDescriptors + 0x023de
	.equ NakaInst_CEL, NakaData_WidgetDescriptors + 0x023f0
	.equ NakaInst_CelReserved_0, NakaData_WidgetDescriptors + 0x02402
	.equ NakaInst_CelReserved_1, NakaData_WidgetDescriptors + 0x02414
	.equ NakaInst_CelReserved_2, NakaData_WidgetDescriptors + 0x02426
	.equ NakaInst_CelReserved_3, NakaData_WidgetDescriptors + 0x02438
	.equ NakaInst_PARAMETRIC_EQ, NakaData_WidgetDescriptors + 0x0244a
	.equ NakaInst_NOISE_FLANGER, NakaData_WidgetDescriptors + 0x0245c
	.equ NakaInst_SLOW_ATTACKER, NakaData_WidgetDescriptors + 0x0246e
	.equ NakaInst_COMPRESSOR, NakaData_WidgetDescriptors + 0x02480
	.equ NakaInst_EXCITER, NakaData_WidgetDescriptors + 0x02492
	.equ NakaInst_FUZZ, NakaData_WidgetDescriptors + 0x024a4
	.equ NakaInst_OVERDRIVE, NakaData_WidgetDescriptors + 0x024b6
	.equ NakaInst_DISTORTION, NakaData_WidgetDescriptors + 0x024c8
	.equ NakaInst_DistReserved_0, NakaData_WidgetDescriptors + 0x024da
	.equ NakaInst_DistReserved_1, NakaData_WidgetDescriptors + 0x024ec
	.equ NakaInst_DistReserved_2, NakaData_WidgetDescriptors + 0x024fe
	.equ NakaInst_DistReserved_3, NakaData_WidgetDescriptors + 0x02510
	.equ NakaInst_WAVE_REVERB_2, NakaData_WidgetDescriptors + 0x02522
	.equ NakaInst_WAVE_REVERB_1, NakaData_WidgetDescriptors + 0x02534
	.equ NakaInst_BRIGHT_REVERB_2, NakaData_WidgetDescriptors + 0x02546
	.equ NakaInst_BRIGHT_REVERB_1, NakaData_WidgetDescriptors + 0x02558
	.equ NakaInst_DARK_REVERB_2, NakaData_WidgetDescriptors + 0x0256a
	.equ NakaInst_DARK_REVERB_1, NakaData_WidgetDescriptors + 0x0257c
	.equ NakaInst_CONCERT_REVERB_2, NakaData_WidgetDescriptors + 0x0258e
	.equ NakaInst_CONCERT_REVERB_1, NakaData_WidgetDescriptors + 0x025a0
	.equ NakaInst_PLATE_REVERB_2, NakaData_WidgetDescriptors + 0x025b2
	.equ NakaInst_PLATE_REVERB_1, NakaData_WidgetDescriptors + 0x025c4
	.equ NakaInst_ROOM_REVERB_2, NakaData_WidgetDescriptors + 0x025d6
	.equ NakaInst_ROOM_REVERB_1, NakaData_WidgetDescriptors + 0x025e8
	.equ NakaInst_ROCK_ROTARY, NakaData_WidgetDescriptors + 0x025fa
	.equ NakaInst_DelayReserved_0, NakaData_WidgetDescriptors + 0x0260c
	.equ NakaInst_DelayReserved_1, NakaData_WidgetDescriptors + 0x0261e
	.equ NakaInst_DelayReserved_2, NakaData_WidgetDescriptors + 0x02630
	.equ NakaInst_MODULATION_DELAY, NakaData_WidgetDescriptors + 0x02642
	.equ NakaInst_MULTI_TAP_DELAY, NakaData_WidgetDescriptors + 0x02654
	.equ NakaInst_SINGLE_DELAY, NakaData_WidgetDescriptors + 0x02666
	.equ NakaInst_GATED_REVERB, NakaData_WidgetDescriptors + 0x02678
	.equ NakaInst_ReverbGateReserved, NakaData_WidgetDescriptors + 0x0268a
	.equ NakaInst_ENSEMBLE, NakaData_WidgetDescriptors + 0x0269c
	.equ NakaInst_PHASER, NakaData_WidgetDescriptors + 0x026ae
	.equ NakaInst_FLANGER, NakaData_WidgetDescriptors + 0x026c0
	.equ NakaInst_ENHANCER, NakaData_WidgetDescriptors + 0x026d2
	.equ NakaInst_MODULATED_CHORUS, NakaData_WidgetDescriptors + 0x026e4
	.equ NakaInst_CHORUS, NakaData_WidgetDescriptors + 0x026f6
	.equ NakaInst_NO_OPERATION, NakaData_WidgetDescriptors + 0x02708
	.equ NakaInst_ACHTUNG, NakaData_WidgetDescriptors + 0x029d8
	.equ NakaInst_ATTENTION, NakaData_WidgetDescriptors + 0x029e2
	.equ NakaInst_ATENCI_N, NakaData_WidgetDescriptors + 0x029ee
	.equ NakaInst_Perhatian, NakaData_WidgetDescriptors + 0x029fa
	.equ NakaInst_Sind_Sie_sicher, NakaData_WidgetDescriptors + 0x02a14
	.equ NakaInst_Etes_vous_sur_FR, NakaData_WidgetDescriptors + 0x02a26
	.equ NakaInst_Est_seguro, NakaData_WidgetDescriptors + 0x02a36
	.equ NakaInst_Features_for_editing_a_song, NakaData_WidgetDescriptors + 0x02aa8
	.equ NakaInst_Funktionen_zur_Bearbeitung_eines_Songs, NakaData_WidgetDescriptors + 0x02ac6
	.equ NakaInst_EASY_RECORD_sets_the_Sequencer_to_record_your, NakaData_WidgetDescriptors + 0x02aee
	.equ NakaInst_EASY_RECORD_aktiviert_DE, NakaData_WidgetDescriptors + 0x02b70
	.equ NakaInst_Press_OK_to_proceed, NakaData_WidgetDescriptors + 0x02c02
	.equ NakaInst_Bestaetigen_Sie_mit_OK_DE, NakaData_WidgetDescriptors + 0x02c18
	.equ NakaInst_PANEL_WRITE_replaces_the_sounds_and_settings_at, NakaData_WidgetDescriptors + 0x02c30
	.equ NakaInst_PANEL_WRITE_ersetzt_alle_Kl_nge_und_Einstellungen, NakaData_WidgetDescriptors + 0x02cf2
	.equ NakaInst_Press_the_up_down_buttons_under_the_screen, NakaData_WidgetDescriptors + 0x02dd0
	.equ NakaInst_Druecken_Sie_Doppeltasten_DE, NakaData_WidgetDescriptors + 0x02e30
	.equ NakaInst_Press_OK_to_complete_TRACK_CLEAR, NakaData_WidgetDescriptors + 0x02e98
	.equ NakaInst_Druecken_OK_TRACK_CLEAR_DE, NakaData_WidgetDescriptors + 0x02eba
	.equ NakaInst_Press_the_up_down_button_under_the_screen, NakaData_WidgetDescriptors + 0x02ee6
	.equ NakaInst_Dr_cken_Sie_eine_der_Doppeltasten_unter_dem, NakaData_WidgetDescriptors + 0x02f42
	.equ NakaInst_Using_SONG_CLEAR_will_erase_any_existing, NakaData_WidgetDescriptors + 0x02faa
	.equ NakaInst_SONG_CLEAR_loescht_DE, NakaData_WidgetDescriptors + 0x02ff0
	.equ NakaInst_Al_anular_la_canci_n_se_borra_la_grabaci_n_del, NakaData_WidgetDescriptors + 0x0302c
	.equ NakaInst_Using_TRACK_CLEAR_will_erase_any_existing, NakaData_WidgetDescriptors + 0x03110
	.equ NakaInst_TRACK_CLEAR_l_scht_alle_Daten_in_den_ausgew_hlten, NakaData_WidgetDescriptors + 0x0315e
	.equ NakaInst_anular_la_pista_se_borra_la_grabaci_n_de_las, NakaData_WidgetDescriptors + 0x0319a
	.equ ExtDevice_ModeDispatch_Table, NakaData_WidgetDescriptors + 0x03678
	.equ NakaInst_3d, NakaData_WidgetDescriptors + 0x03d28
	.equ NakaInst_2d, NakaData_WidgetDescriptors + 0x03df0
	.equ Bitmap_Ntedt0k, NakaData_WidgetDescriptors + 0x04018
	.equ Bitmap_Ntedt0d, NakaData_WidgetDescriptors + 0x04808
	.equ Bitmap_Dredt0k, NakaData_WidgetDescriptors + 0x0bf18
	.equ Bitmap_Dredt0d, NakaData_WidgetDescriptors + 0x0e800
	.equ WidgetData_DrawbarPositionTable, NakaData_WidgetDescriptors + 0x13618
	.equ WidgetData_CharsetMappingTable, NakaData_WidgetDescriptors + 0x137d6
	.equ FontPalette_Gradient7, NakaData_WidgetDescriptors + 0x13d12
	.equ FontPalette_Gradient6, NakaData_WidgetDescriptors + 0x13d58
	.equ FontPalette_Gradient5, NakaData_WidgetDescriptors + 0x13db8
	.equ FontPalette_Gradient4, NakaData_WidgetDescriptors + 0x13e18
	.equ FontPalette_Gradient3, NakaData_WidgetDescriptors + 0x13e78
	.equ FontPalette_Gradient2, NakaData_WidgetDescriptors + 0x13ed8
	.equ FontPalette_Gradient1, NakaData_WidgetDescriptors + 0x13f38
	.equ FontPalette_Gradient0, NakaData_WidgetDescriptors + 0x13f98
	.equ Display_FontPalette_Table, NakaData_WidgetDescriptors + 0x13ff8
	.equ NakaInst_MEMORY_C, NakaData_WidgetDescriptors + 0x1b1e4
	.equ NakaInst_MEMORY_B, NakaData_WidgetDescriptors + 0x1b1f2
	.equ NakaInst_MEMORY_A, NakaData_WidgetDescriptors + 0x1b200
	.equ NakaInst_DashDash, NakaData_WidgetDescriptors + 0x1b262
	.equ NakaInst_ON_Str, NakaData_WidgetDescriptors + 0x1b26e
	.equ NakaInst_OFF_Str, NakaData_WidgetDescriptors + 0x1b272
	.equ Naka_UIStringRef_Table, NakaData_WidgetDescriptors + 0x244a8
	.equ NakaInst_EmptyFuncName, NakaData_WidgetDescriptors + 0x24598
	.equ NakaInst_RevEqOnOffFunc, NakaData_WidgetDescriptors + 0x2459a
	.equ NakaInst_RevEqSelFunc, NakaData_WidgetDescriptors + 0x245aa
	.equ NakaInst_EqOnOffFunc, NakaData_WidgetDescriptors + 0x245b8
	.equ NakaInst_EqSelFunc, NakaData_WidgetDescriptors + 0x245c4
	.equ NakaInst_RevSelFunc, NakaData_WidgetDescriptors + 0x245ce
	.equ NakaInst_SplitPointFunc, NakaData_WidgetDescriptors + 0x245da
	.equ NakaInst_StsSplitCheck, NakaData_WidgetDescriptors + 0x245ea
	.equ NakaInst_InOutGridCheck, NakaData_WidgetDescriptors + 0x245f8
	.equ NakaInst_TtMdInOut, NakaData_WidgetDescriptors + 0x24608
	.equ NakaInst_FadeSetGridCheck, NakaData_WidgetDescriptors + 0x24612
	.equ NakaInst_TtFadeInOut, NakaData_WidgetDescriptors + 0x24624
	.equ NakaInst_VocalistPage2OKFunc, NakaData_WidgetDescriptors + 0x24630
	.equ NakaInst_VocalistPage1OKFunc, NakaData_WidgetDescriptors + 0x24644
	.equ NakaInst_VocalistGridCheck, NakaData_WidgetDescriptors + 0x24658
	.equ NakaInst_TtVocalistWorkstation, NakaData_WidgetDescriptors + 0x2466a
	.equ NakaInst_HarmOnOffFunc, NakaData_WidgetDescriptors + 0x24680
	.equ NakaInst_GMNoFunc, NakaData_WidgetDescriptors + 0x2468e
	.equ NakaInst_GMYesFunc, NakaData_WidgetDescriptors + 0x24698
	.equ NakaInst_StsAreYouSureCheck, NakaData_WidgetDescriptors + 0x246a2
	.equ NakaInst_StsGMOffCheck, NakaData_WidgetDescriptors + 0x246b6
	.equ NakaInst_StsGMOnCheck, NakaData_WidgetDescriptors + 0x246c4
	.equ NakaInst_StsAttentionCheck, NakaData_WidgetDescriptors + 0x246d2
	.equ NakaInst_GMOKFunc, NakaData_WidgetDescriptors + 0x246e4
	.equ NakaInst_TtMdGm, NakaData_WidgetDescriptors + 0x246ee
	.equ NakaInst_BitmapBmphk, NakaData_WidgetDescriptors + 0x246f6
	.equ NakaInst_MdPresetWithFunc, NakaData_WidgetDescriptors + 0x24702
	.equ NakaInst_MdPresetWithoutFunc, NakaData_WidgetDescriptors + 0x24714
	.equ NakaInst_MdPresetOKFunc, NakaData_WidgetDescriptors + 0x24728
	.equ NakaInst_TtMdPreset, NakaData_WidgetDescriptors + 0x24738
	.equ NakaInst_ExcMspFunc, NakaData_WidgetDescriptors + 0x24744
	.equ NakaInst_ExcSeqFunc, NakaData_WidgetDescriptors + 0x24750
	.equ NakaInst_ExcCompFunc, NakaData_WidgetDescriptors + 0x2475c
	.equ NakaInst_ExcSmemFunc, NakaData_WidgetDescriptors + 0x24768
	.equ NakaInst_ExcPmemFunc, NakaData_WidgetDescriptors + 0x24774
	.equ NakaInst_ExcDotFunc, NakaData_WidgetDescriptors + 0x24780
	.equ NakaInst_ExcSendFunc, NakaData_WidgetDescriptors + 0x2478c
	.equ NakaInst_TtMdExc, NakaData_WidgetDescriptors + 0x24798
	.equ NakaInst_MidiPartGridCheck, NakaData_WidgetDescriptors + 0x247a0
	.equ NakaInst_TtMdPart, NakaData_WidgetDescriptors + 0x247b2
	.equ NakaInst_CtlMsgGridCheck, NakaData_WidgetDescriptors + 0x247bc
	.equ NakaInst_TtMdCtlMsg, NakaData_WidgetDescriptors + 0x247cc
	.equ NakaInst_PmemOutRGridCheck, NakaData_WidgetDescriptors + 0x247d8
	.equ NakaInst_PmemOutLGridCheck, NakaData_WidgetDescriptors + 0x247ea
	.equ NakaInst_TtMdPmemOut, NakaData_WidgetDescriptors + 0x247fc
	.equ NakaInst_ComSetGridCheck, NakaData_WidgetDescriptors + 0x24808
	.equ NakaInst_TtComSet, NakaData_WidgetDescriptors + 0x24818
	.equ NakaInst_PcgOutSendFunc, NakaData_WidgetDescriptors + 0x24822
	.equ NakaInst_PcgOutGridCheck, NakaData_WidgetDescriptors + 0x24832
	.equ NakaInst_TtMdPcgOut, NakaData_WidgetDescriptors + 0x24842
	.equ NakaInst_ParaLoadOptOKFunc, NakaData_WidgetDescriptors + 0x2484e
	.equ NakaInst_ParaLoadOptGridCheck, NakaData_WidgetDescriptors + 0x24860
	.equ NakaInst_TtMdParaLoad, NakaData_WidgetDescriptors + 0x24876
	.equ NakaInst_R12OctaveFunc, NakaData_WidgetDescriptors + 0x24884
	.equ NakaInst_MdCmptCnctFunc, NakaData_WidgetDescriptors + 0x24892
	.equ NakaInst_TtComputerConnection, NakaData_WidgetDescriptors + 0x248a2
	.equ NakaInst_MdSetupLoadFunc, NakaData_WidgetDescriptors + 0x248b8
	.equ NakaInst_MdDrumTypeFunc, NakaData_WidgetDescriptors + 0x248c8
	.equ NakaInst_MdPcgModeFunc, NakaData_WidgetDescriptors + 0x248d8
	.equ NakaInst_TtMdRealMsg, NakaData_WidgetDescriptors + 0x248e6
	.equ NakaInst_TtMdmenu, NakaData_WidgetDescriptors + 0x248f2
	.equ NakaDesc_PageWindow_Sentinel, NakaData_WidgetDescriptors + 0x24906
	.equ NakaDesc_PageWindow_Table, NakaData_WidgetDescriptors + 0x24908
	.equ NakaDesc_PageWindow_NullStr, NakaData_WidgetDescriptors + 0x24918
	.equ NakaDesc_PageWindow_Window1, NakaData_WidgetDescriptors + 0x2491a
	.equ NakaDesc_PageWindow_Window0, NakaData_WidgetDescriptors + 0x24922
	.equ NakaDesc_PageWindow_Page, NakaData_WidgetDescriptors + 0x2492a
	.equ NakaDesc_OnOffStyle_Table, NakaData_WidgetDescriptors + 0x24930
	.equ NakaDesc_OnOffStyle_NullStr, NakaData_WidgetDescriptors + 0x24944
	.equ NakaDesc_OnOffStyle_Onoff, NakaData_WidgetDescriptors + 0x24946
	.equ NakaDesc_OnOffStyle_Str, NakaData_WidgetDescriptors + 0x2494c
	.equ NakaDesc_OnOffStyle_Func, NakaData_WidgetDescriptors + 0x24950
	.equ NakaDesc_OnOffStyle_Style, NakaData_WidgetDescriptors + 0x24956
	.equ NakaDesc_PmanOnOff_NullTerm, NakaData_WidgetDescriptors + 0x24960
	.equ NakaDesc_PmanOnOff1_Table, NakaData_WidgetDescriptors + 0x24962
	.equ NakaDesc_PmanOnOff1_NullEntry, NakaData_WidgetDescriptors + 0x2497a
	.equ NakaDesc_PmanOnOff1_PmanOut, NakaData_WidgetDescriptors + 0x2497c
	.equ NakaDesc_PmanOnOff1_PmanAdr, NakaData_WidgetDescriptors + 0x24986
	.equ NakaDesc_PmanOnOff1_OffStr, NakaData_WidgetDescriptors + 0x24990
	.equ NakaDesc_PmanOnOff1_OnStr, NakaData_WidgetDescriptors + 0x24998
	.equ NakaDesc_PmanOnOff1_Data, NakaData_WidgetDescriptors + 0x249a0
	.equ NakaDesc_PmanOnOff2_Table, NakaData_WidgetDescriptors + 0x249a6
	.equ NakaDesc_PmanOnOff2_NullEntry, NakaData_WidgetDescriptors + 0x249be
	.equ NakaDesc_PmanOnOff2_PmanOut, NakaData_WidgetDescriptors + 0x249c0
	.equ NakaDesc_PmanOnOff2_PmanAdr, NakaData_WidgetDescriptors + 0x249ca
	.equ NakaDesc_PmanOnOff2_OffStr, NakaData_WidgetDescriptors + 0x249d4
	.equ NakaDesc_PmanOnOff2_OnStr, NakaData_WidgetDescriptors + 0x249dc
	.equ NakaDesc_PmanOnOff2_Data, NakaData_WidgetDescriptors + 0x249e4
	.equ NakaDesc_GridBox1_NullEntry, NakaData_WidgetDescriptors + 0x249fa
	.equ NakaDesc_GridBox1_Func, NakaData_WidgetDescriptors + 0x249fc
	.equ NakaDesc_GridBox1_FixedRow, NakaData_WidgetDescriptors + 0x24a02
	.equ NakaDesc_GridBox1_FixedCol, NakaData_WidgetDescriptors + 0x24a0c
	.equ NakaDesc_GridBox2_NullEntry, NakaData_WidgetDescriptors + 0x24a26
	.equ NakaDesc_GridBox2_Func, NakaData_WidgetDescriptors + 0x24a28
	.equ NakaDesc_GridBox2_FixedRow, NakaData_WidgetDescriptors + 0x24a2e
	.equ NakaDesc_GridBox2_FixedCol, NakaData_WidgetDescriptors + 0x24a38
	.equ NakaDesc_GridBox3_NullEntry, NakaData_WidgetDescriptors + 0x24a52
	.equ NakaDesc_GridBox3_Func, NakaData_WidgetDescriptors + 0x24a54
	.equ NakaDesc_GridBox3_FixedRow, NakaData_WidgetDescriptors + 0x24a5a
	.equ NakaDesc_GridBox3_FixedCol, NakaData_WidgetDescriptors + 0x24a64
	.equ NakaDesc_GridBox4_NullEntry, NakaData_WidgetDescriptors + 0x24a7e
	.equ NakaDesc_GridBox4_Func, NakaData_WidgetDescriptors + 0x24a80
	.equ NakaDesc_GridBox4_FixedRow, NakaData_WidgetDescriptors + 0x24a86
	.equ NakaDesc_GridBox4_FixedCol, NakaData_WidgetDescriptors + 0x24a90
	.equ NakaDesc_GridBox5_NullEntry, NakaData_WidgetDescriptors + 0x24aaa
	.equ NakaDesc_GridBox5_Func, NakaData_WidgetDescriptors + 0x24aac
	.equ NakaDesc_GridBox5_FixedRow, NakaData_WidgetDescriptors + 0x24ab2
	.equ NakaDesc_GridBox5_FixedCol, NakaData_WidgetDescriptors + 0x24abc
	.equ NakaDesc_GridBox6_NullEntry, NakaData_WidgetDescriptors + 0x24ad6
	.equ NakaDesc_GridBox6_Func, NakaData_WidgetDescriptors + 0x24ad8
	.equ NakaDesc_GridBox6_FixedRow, NakaData_WidgetDescriptors + 0x24ade
	.equ NakaDesc_GridBox6_FixedCol, NakaData_WidgetDescriptors + 0x24ae8
	.equ NakaDesc_GridBox7_NullEntry, NakaData_WidgetDescriptors + 0x24b02
	.equ NakaDesc_GridBox7_Func, NakaData_WidgetDescriptors + 0x24b04
	.equ NakaDesc_GridBox7_FixedRow, NakaData_WidgetDescriptors + 0x24b0a
	.equ NakaDesc_GridBox7_FixedCol, NakaData_WidgetDescriptors + 0x24b14
	.equ NakaDesc_PageGridBox1_Table, NakaData_WidgetDescriptors + 0x24b1e
	.equ NakaDesc_PageGridBox1_Null, NakaData_WidgetDescriptors + 0x24b32
	.equ NakaDesc_PageGridBox1_Page, NakaData_WidgetDescriptors + 0x24b34
	.equ NakaDesc_PageGridBox1_Func, NakaData_WidgetDescriptors + 0x24b3a
	.equ NakaDesc_PageGridBox1_FixedRow, NakaData_WidgetDescriptors + 0x24b40
	.equ NakaDesc_PageGridBox1_FixedCol, NakaData_WidgetDescriptors + 0x24b4a
	.equ NakaDesc_PageGridBox2_Table, NakaData_WidgetDescriptors + 0x24b58
	.equ NakaDesc_PageGridBox2_NullStr, NakaData_WidgetDescriptors + 0x24b68
	.equ NakaDesc_PageGridBox2_Page, NakaData_WidgetDescriptors + 0x24b6a
	.equ NakaDesc_PageGridBox2_Func, NakaData_WidgetDescriptors + 0x24b70
	.equ NakaDesc_PageGridBox2_FixedRow, NakaData_WidgetDescriptors + 0x24b76
	.equ NakaDesc_PageGridBox2_FixedCol, NakaData_WidgetDescriptors + 0x24b80
	.equ NakaData_Block007, NakaData_WidgetDescriptors + 0x24bd6
