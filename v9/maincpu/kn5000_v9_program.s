; =============================================================================
; KN5000 Main CPU Program ROM (2MB: E00000-FFFFFF)
; =============================================================================

; --- Constants, Macros & SFR Definitions ---
	.text

	.include "shared/macros.s"
	.include "shared/sfr_tmp94c241.s"
	.include "shared/vga_constants.s"
	.include "shared/event_codes.s"
	.include "fdc_constants.s"
	.include "gui_constants.s"
	.include "cpanel_constants.s"
	.include "midi_encoder_constants.s"

; --- Boot Dispatch Tables, LED Patterns & Dialog Bitmaps ---
; =============================================================================
; Constants for shared boot routines
; =============================================================================
.equ REGION_CODE_VAR, 0x408	; RAM address for region code
.equ BOOT_ENTRY_POINT, RESET_HANDLER	; Entry point for watchdog reset

.equ INTER_CPU_COMM_LATCHES, 0x140000	; This is a pair of 8-bit latches
                                            ; used for bidirectional
                                            ; communication between
                                            ; maincpu and subcpu
.equ HDAE5000_PPI__PORT_A, 0x160000
.equ HDAE5000_PPI__PORT_B, 0x160002
.equ HDAE5000_PPI__PORT_C, 0x160004
.equ HDAE5000_PPI__CONTROL_REG, 0x160006
.equ HDAE5000_ROM__BASE_ADDR, 0x280000
.equ CUSTOM_DATA_FLASH__BASE_ADDR, 0x300000
.equ RHYTHM_DATA_ROM__BASE_ADDR, 0x400000
.equ TABLE_DATA_ROM__BASE_ADDR, 0x800000
.equ PROGRAM_FLASH__BASE_ADDR, 0xe00000

.equ SYSTEM_TIMESTAMP, 0x409

.equ MSP_SETTINGS, 0xc9a	; 1500h = 5376 bytes
					; next free address: 0219Ah

.equ COM_SELECT, 0xb7e0	; (byte)

.equ SEQ_ALT3_RINGBUF_BASE, 0x201c1

.equ MSP_SETTINGS__BASE_ADDR, 0x1e8800

	; Auto-generated labels for mid-function ROM addresses
	.set FILETYPE_SIG_TABLE_2_0x15_, 0xe000ed
	.set Bitmap_1bit_Completed_0x15C_, 0xe00a22
	.set SOUND_DATA_DRUM_KITS_0x1A_, 0xe0b432
	.set SOUND_DATA_DRUM_KITS_0x3A_, 0xe0b452
	.set StyleUI_ParamBlockPtrTable_0x4C_, 0xe0baac
	.set StyleUI_ParamBlockPtrTable_0x98_, 0xe0baf8
	.set StyleUI_ParamBlockPtrTable_0xE4_, 0xe0bb44
	.set StyleUI_ScreenData_Main_0xB4_, 0xe0bc44
	.set StyleUI_ScreenData_Main_0x1C2_, 0xe0bd52
	.set StyleUI_ScreenData_Main_0x1CC_, 0xe0bd5c
	.set StyleUI_ScreenData_Main_0x1D6_, 0xe0bd66
	.set StyleUI_ScreenData_Main_0x1E0_, 0xe0bd70
	.set StyleUI_ScreenData_Main_0x1E5_, 0xe0bd75
	.set StyleUI_ScreenData_Main_0x1EA_, 0xe0bd7a
	.set StyleUI_ScreenData_Main_0x1EF_, 0xe0bd7f
	.set StyleUI_ScreenData_Main_0x1F9_, 0xe0bd89
	.set StyleUI_ScreenData_Main_0x21C_, 0xe0bdac
	.set StyleUI_ScreenData_Main_0x258_, 0xe0bde8
	.set StyleUI_ScreenData_Main_0x276_, 0xe0be06
	.set StyleUI_ScreenData_Main_0x3DE_, 0xe0bf6e
	.set StyleUI_ScreenData_Main_0x546_, 0xe0c0d6
	.set StyleUI_ScreenData_Main_0x6AE_, 0xe0c23e
	.set StyleUI_ScreenData_Main_0x97E_, 0xe0c50e
	.set StyleUI_ScreenData_Main_0x986_, 0xe0c516
	.set StyleUI_ScreenData_Main_0x990_, 0xe0c520
	.set StyleUI_ScreenData_Main_0x9BB_, 0xe0c54b
	.set StyleUI_ScreenData_Main_0xA06_, 0xe0c596
	.set StyleUI_ScreenData_Main_0xB19_, 0xe0c6a9
	.set StyleUI_ScreenData_Main_0xB3A_, 0xe0c6ca
	.set StyleUI_ScreenData_Main_0xB94_, 0xe0c724
	.set StyleUI_ScreenData_Main_0xBD4_, 0xe0c764
	.set StyleUI_ScreenData_Main_0xD3C_, 0xe0c8cc
	.set StyleUI_ScreenData_Main_0xD3F_, 0xe0c8cf
	.set StyleUI_ScreenData_CtlOnly_0x20_, 0xe0cb17
	.set StyleUI_ScreenData_CtlOnly_0x23_, 0xe0cb1a
	.set StyleUI_ScreenData_CtlOnly_0x123_, 0xe0cc1a
	.set StyleUI_ScreenData_CtlOnly_0x12B_, 0xe0cc22
	.set StyleUI_ScreenData_CtlOnly_0x133_, 0xe0cc2a
	.set StyleUI_ScreenData_CtlOnly_0x13B_, 0xe0cc32
	.set StyleUI_ScreenData_CtlOnly_0x1CB_, 0xe0ccc2
	.set StyleUI_ScreenData_CtlOnly_0x1DF_, 0xe0ccd6
	.set StyleUI_ScreenData_CtlOnly_0x1FF_, 0xe0ccf6
	.set StyleUI_ScreenData_CtlOnly_0x213_, 0xe0cd0a
	.set GUI_FormatStrings_0x20_, 0xe0cd3e
	.set GUI_FormatStrings_0x34_, 0xe0cd52
	.set GUI_FormatStrings_0x3C_, 0xe0cd5a
	.set GUI_DisplayStructData_0xAD8_, 0xe0dab6
	.set GUI_DisplayStructData_0xAE8_, 0xe0dac6
	.set GUI_DisplayStructData_0xAF8_, 0xe0dad6
	.set GUI_DisplayStructData_0xB08_, 0xe0dae6
	.set GUI_DisplayStructData_0xB18_, 0xe0daf6
	.set GUI_DisplayStructData_0xB28_, 0xe0db06
	.set GUI_DisplayStructData_0xB38_, 0xe0db16
	.set GUI_DisplayStructData_0xB48_, 0xe0db26
	.set GUI_DisplayStructData_0xB58_, 0xe0db36
	.set GUI_DisplayStructData_0xB68_, 0xe0db46
	.set GUI_DisplayStructData_0xB78_, 0xe0db56
	.set GUI_DisplayStructData_0xB88_, 0xe0db66
	.set GUI_DisplayStructData_0xB98_, 0xe0db76
	.set GUI_DisplayStructData_0xBA8_, 0xe0db86
	.set GUI_DisplayStructData_0xBB8_, 0xe0db96
	.set GUI_DisplayStructData_0xBC8_, 0xe0dba6
	.set GUI_DisplayStructData_0xBD8_, 0xe0dbb6
	.set GUI_DisplayStructData_0xBE8_, 0xe0dbc6
	.set GUI_DisplayStructData_0xBF8_, 0xe0dbd6
	.set GUI_DisplayStructData_0xC08_, 0xe0dbe6
	.set GUI_DisplayStructData_0xC18_, 0xe0dbf6
	.set GUI_DisplayStructData_0xC28_, 0xe0dc06
	.set GUI_DisplayStructData_0xC38_, 0xe0dc16
	.set GUI_DisplayStructData_0xC48_, 0xe0dc26
	.set GUI_DisplayStructData_0xC58_, 0xe0dc36
	.set GUI_DisplayStructData_0xC68_, 0xe0dc46
	.set GUI_DisplayStructData_0xC78_, 0xe0dc56
	.set GUI_DisplayStructData_0xC88_, 0xe0dc66
	.set GUI_DisplayStructData_0xC98_, 0xe0dc76
	.set GUI_DisplayStructData_0xCA8_, 0xe0dc86
	.set GUI_DisplayStructData_0xCB8_, 0xe0dc96
	.set GUI_DisplayStructData_0xCC8_, 0xe0dca6
	.set GUI_DisplayStructData_0xCD8_, 0xe0dcb6
	.set GUI_DisplayStructData_0xD20_, 0xe0dcfe
	.set GUI_DisplayStructData_0xD68_, 0xe0dd46
	.set GUI_DisplayStructData_0xDB0_, 0xe0dd8e
	.set GUI_DisplayStructData_0xDF8_, 0xe0ddd6
	.set GUI_DisplayStructData_0xE40_, 0xe0de1e
	.set GUI_DisplayStructData_0xE88_, 0xe0de66
	.set GUI_DisplayStructData_0xED0_, 0xe0deae
	.set GUI_DisplayStructData_0xF18_, 0xe0def6
	.set GUI_DisplayStructData_0xF60_, 0xe0df3e
	.set GUI_DisplayStructData_0xFA8_, 0xe0df86
	.set GUI_DisplayStructData_0xFF0_, 0xe0dfce
	.set GUI_DisplayStructData_0x1038_, 0xe0e016
	.set GUI_DisplayStructData_0x1080_, 0xe0e05e
	.set GUI_DisplayStructData_0x10C8_, 0xe0e0a6
	.set GUI_DisplayStructData_0x1110_, 0xe0e0ee
	.set GUI_DisplayStructData_0x111D_, 0xe0e0fb
	.set GUI_DisplayStructData_0x1129_, 0xe0e107
	.set GUI_DisplayStructData_0x118A_, 0xe0e168
	.set GUI_DisplayStructData_0x120C_, 0xe0e1ea
	.set GUI_DisplayStructData_0x120F_, 0xe0e1ed
	.set GUI_DisplayStructData_0x1222_, 0xe0e200
	.set GUI_DisplayStructData_0x126A_, 0xe0e248
	.set GUI_DisplayStructData_0x12B2_, 0xe0e290
	.set GUI_DisplayStructData_0x12FA_, 0xe0e2d8
	.set GUI_DisplayStructData_0x1342_, 0xe0e320
	.set GUI_DisplayStructData_0x1362_, 0xe0e340
	.set GUI_DisplayStructData_0x136F_, 0xe0e34d
	.set GUI_DisplayStructData_0x13B7_, 0xe0e395
	.set GUI_DisplayStructData_0x13FF_, 0xe0e3dd
	.set ToneGen_ParamTable_0x1E_, 0xe0e425
	.set ToneGen_ParamTable_0x66_, 0xe0e46d
	.set ToneGen_ParamTable_0xAE_, 0xe0e4b5
	.set ToneGen_ParamTable_0xF6_, 0xe0e4fd
	.set ToneGen_ParamTable_0x13E_, 0xe0e545
	.set ToneGen_ParamTable_0x186_, 0xe0e58d
	.set ToneGen_ParamTable_0x1CE_, 0xe0e5d5
	.set ToneGen_ParamTable_0x216_, 0xe0e61d
	.set ToneGen_ParamTable_0x25E_, 0xe0e665
	.set ToneGen_ParamTable_0x2A6_, 0xe0e6ad
	.set ToneGen_ParamTable_0x2EE_, 0xe0e6f5
	.set ToneGen_ParamTable_0x306_, 0xe0e70d
	.set ToneGen_ParamTable_0x31A_, 0xe0e721
	.set ToneGen_ParamTable_0x326_, 0xe0e72d
	.set NAKA_PerfReg_Container_Root_0x1697_, 0xe1000b
	.set NAKA_UIObjectTable_0x13E0_, 0xe1482e
	.set NAKA_UIObjectTable_0x1452_, 0xe148a0
	.set NAKA_UIObjectTable_0x1492_, 0xe148e0
	.set NAKA_UIObjectTable_0x1684_, 0xe14ad2
	.set NAKA_UIObjectTable_0x16FC_, 0xe14b4a
	.set NAKA_UIObjectTable_0x186C_, 0xe14cba
	.set NAKA_UIObjectTable_0x19FE_, 0xe14e4c
	.set NAKA_UIObjectTable_0x1B8A_, 0xe14fd8
	.set NAKA_UIObjectTable_0x1D6E_, 0xe151bc
	.set NAKA_UIObjectTable_0x1DF2_, 0xe15240
	.set NAKA_UIObjectTable_0x1F94_, 0xe153e2
	.set NAKA_UIObjectTable_0x2004_, 0xe15452
	.set NAKA_UIObjectTable_0x2166_, 0xe155b4
	.set NAKA_UIObjectTable_0x21E0_, 0xe1562e
	.set NAKA_UIObjectTable_0x2342_, 0xe15790
	.set NAKA_UIObjectTable_0x24B2_, 0xe15900
	.set NAKA_UIObjectTable_0x2512_, 0xe15960
	.set NAKA_UIObjectTable_0x2572_, 0xe159c0
	.set NAKA_UIObjectTable_0x25D2_, 0xe15a20
	.set NAKA_UIObjectTable_0x26D2_, 0xe15b20
	.set MSP_Default_SoundReserved_0x30_, 0xe15c20
	.set MSP_Default_SoundReserved_0x50_, 0xe15c40
	.set MSP_Default_SeqReserved_0x40_, 0xe15cb0
	.set MSP_Default_ChannelMap_0x1E_, 0xe160de
	.set Composer_SettingsBlock_0x60_, 0xe161e4
	.set Composer_SettingsBlock_0x70_, 0xe161f4
	.set Composer_SettingsBlock_0x80_, 0xe16204
	.set Composer_SettingsBlock_0xC0_, 0xe16244
	.set NoteStepDisplayData_0x38_, 0xe1ce16
	.set NoteStepDisplayData_0x4A_, 0xe1ce28
	.set NoteStepDisplayData_0x5C_, 0xe1ce3a
	.set StrTimeSig_1_2_0x10_, 0xe1cef0
	.set StrTimeSig_1_2_0x20_, 0xe1cf00
	.set StrPanLeft64_0x0A_, 0xe1d40e
	.set StrPanLeft64_0x18_, 0xe1d41c
	.set StrTranspose_Minus25_0x04_, 0xe1d728
	.set StrTranspose_Minus25_0x12_, 0xe1d736
	.set StrBeatOff_0x04_, 0xe1d78e
	.set StrBeatOff_0x12_, 0xe1d79c
	.set StrRhySlot_MemoryA_0x0A_, 0xe1db5c
	.set StrRhySlot_MemoryA_0x12_, 0xe1db64
	.set StrRhySlot_MemoryA_0x1A_, 0xe1db6c
	.set StrRhySlot_MemoryA_0x22_, 0xe1db74
	.set StrRhySlot_MemoryA_0x2A_, 0xe1db7c
	.set StrStyleSect2_A_Vari1_0x08_, 0xe1dd08
	.set StyleVarGrp_AEnd2b_0x02_, 0xe1de4c
	.set StrGenre_8Beat_0x12_, 0xe1df0e
	.set StrGenre_8Beat_0x1A_, 0xe1df16
	.set StrGenre_8Beat_0x28_, 0xe1df24
	.set StrBankShort_User1_0x0A_, 0xe1df5c
	.set StrMsBankLong2_Effect1_0x18_, 0xe1e2c2
	.set StrMsBankLong2_Effect1_0x26_, 0xe1e2d0
	.set StrCompileBank1_0x30_, 0xe1e318
	.set StrInstantStart_0x12_, 0xe1e344
	.set StrInstantStart_0x26_, 0xe1e358
	.set StrInstantStart_0x2C_, 0xe1e35e
	.set StrInstantStart_0x3A_, 0xe1e36c
	.set MSG_ATTENTION_ID_0x0C_, 0xe1e516
	.set MSG_ARE_YOU_SURE_ID_0x1C_, 0xe1e596
	.set MSG_CUSTOM_SOUND_COPY_ID_0x8E_, 0xe1e994
	.set MSG_SOUND_GROUP_AFFECTED_ID_0x24_, 0xe1ea88
	.set MSG_CUSTOM_SOUND_FULL_ID_0x7C_, 0xe1ed64
	.set MSG_CUSTOM_RHYTHMS_AFFECTED_ID_0x1E_, 0xe1ee2c
	.set MSG_INSERT_STYLE_CONVERT_ID_0x26_, 0xe1ef42
	.set FDTest_String_TestTitleFunc_0x0E_, 0xe1fd4c
	.set FDTest_String_TestTitleFunc_0x1A_, 0xe1fd58
	.set FDTest_String_TestTitleFunc_0x26_, 0xe1fd64
	.set FDTest_String_TestTitleFunc_0x36_, 0xe1fd74
	.set FDTest_String_TestTitleFunc_0x48_, 0xe1fd86
	.set FDTest_String_TestTitleFunc_0x58_, 0xe1fd96
	.set FDTest_String_TestTitleFunc_0x70_, 0xe1fdae
	.set FDTest_String_TestTitleFunc_0x7C_, 0xe1fdba
	.set FDTest_String_TestTitleFunc_0x8C_, 0xe1fdca
	.set FDTest_String_TestTitleFunc_0xA2_, 0xe1fde0
	.set FDTest_String_TestTitleFunc_0xA8_, 0xe1fde6
	.set FDTest_String_TestTitleFunc_0xB4_, 0xe1fdf2
	.set FDTest_String_TestTitleFunc_0xC0_, 0xe1fdfe
	.set FDTest_String_TestTitleFunc_0xD0_, 0xe1fe0e
	.set FDTest_String_TestTitleFunc_0xDC_, 0xe1fe1a
	.set FDTest_String_TestTitleFunc_0xEA_, 0xe1fe28
	.set FDTest_String_TestTitleFunc_0xFA_, 0xe1fe38
	.set FDTest_String_TestTitleFunc_0x100_, 0xe1fe3e
	.set FDTest_String_TestTitleFunc_0x104_, 0xe1fe42
	.set FDTest_String_TestTitleFunc_0x108_, 0xe1fe46
	.set FDTest_String_TestTitleFunc_0x118_, 0xe1fe56
	.set FDTest_String_TestTitleFunc_0x128_, 0xe1fe66
	.set FDTest_String_TestTitleFunc_0x130_, 0xe1fe6e
	.set FDTest_String_TestTitleFunc_0x134_, 0xe1fe72
	.set FDTest_String_TestTitleFunc_0x148_, 0xe1fe86
	.set FDTest_String_TestTitleFunc_0x14C_, 0xe1fe8a
	.set FDTest_String_TestTitleFunc_0x164_, 0xe1fea2
	.set FDTest_String_TestTitleFunc_0x174_, 0xe1feb2
	.set FDTest_String_TestTitleFunc_0x17C_, 0xe1feba
	.set FDTest_String_TestTitleFunc_0x180_, 0xe1febe
	.set FDTest_String_TestTitleFunc_0x18E_, 0xe1fecc
	.set FDTest_String_TestTitleFunc_0x192_, 0xe1fed0
	.set FDTest_String_TestTitleFunc_0x1AA_, 0xe1fee8
	.set FDTest_String_TestTitleFunc_0x1B2_, 0xe1fef0
	.set FDTest_String_TestTitleFunc_0x1B6_, 0xe1fef4
	.set FDTest_String_TestTitleFunc_0x1C8_, 0xe1ff06
	.set FDTest_String_TestTitleFunc_0x1D8_, 0xe1ff16
	.set FDTest_String_TestTitleFunc_0x1DC_, 0xe1ff1a
	.set FDTest_String_TestTitleFunc_0x1E0_, 0xe1ff1e
	.set FDTest_String_TestTitleFunc_0x1F6_, 0xe1ff34
	.set FDTest_String_TestTitleFunc_0x204_, 0xe1ff42
	.set FDTest_String_TestTitleFunc_0x20E_, 0xe1ff4c
	.set FDTest_String_TestTitleFunc_0x21A_, 0xe1ff58
	.set FDTest_String_TestTitleFunc_0x220_, 0xe1ff5e
	.set FDTest_String_TestTitleFunc_0x22A_, 0xe1ff68
	.set FDTest_String_TestTitleFunc_0x22E_, 0xe1ff6c
	.set FDTest_String_TestTitleFunc_0x236_, 0xe1ff74
	.set FDTest_String_TestTitleFunc_0x242_, 0xe1ff80
	.set FDTest_String_TestTitleFunc_0x252_, 0xe1ff90
	.set FDTest_String_TestTitleFunc_0x264_, 0xe1ffa2
	.set FDTest_String_TestTitleFunc_0x28E_, 0xe1ffcc
	.set SepaOut_Config_0_0x04_, 0xe1ffea
	.set SepaOut_Config_0_0x08_, 0xe1ffee
	.set SepaOut_Config_0_0x0C_, 0xe1fff2
	.set SepaOut_Config_0_0x10_, 0xe1fff6
	.set SepaOut_Config_0_0x14_, 0xe1fffa
	.set SepaOut_Config_0_0x20_, 0xe20006
	.set SepaOut_Config_0_0x25_, 0xe2000b
	.set SepaOut_Config_0_0x2C_, 0xe20012
	.set SepaOut_Config_0_0x38_, 0xe2001e
	.set SepaOut_Config_0_0x44_, 0xe2002a
	.set SepaOut_Config_0_0x52_, 0xe20038
	.set SepaOut_Config_0_0x56_, 0xe2003c
	.set SepaOut_Config_0_0x62_, 0xe20048
	.set SepaOut_Config_0_0x6E_, 0xe20054
	.set SepaOut_Config_0_0x8E_, 0xe20074
	.set SepaOut_Config_0_0xCE_, 0xe200b4
	.set SepaOut_Config_0_0xDC_, 0xe200c2
	.set SepaOut_Config_0_0xE8_, 0xe200ce
	.set SepaOut_Config_0_0xF4_, 0xe200da
	.set SepaOut_Config_0_0x100_, 0xe200e6
	.set SepaOut_FormatData_Tail_0x33_, 0xe20120
	.set SepaOut_FormatData_Tail_0x4F_, 0xe2013c
	.set SepaOut_FormatData_Tail_0x63_, 0xe20150
	.set SepaOut_FormatData_Tail_0x6F_, 0xe2015c
	.set SepaOut_FormatData_Tail_0x83_, 0xe20170
	.set SepaOut_FormatData_Tail_0x8F_, 0xe2017c
	.set SepaOut_FormatData_Tail_0xA3_, 0xe20190
	.set SepaOut_FormatData_Tail_0xAF_, 0xe2019c
	.set SepaOut_FormatData_Tail_0xBB_, 0xe201a8
	.set SepaOut_FormatData_Tail_0xC7_, 0xe201b4
	.set SepaOut_FormatData_Tail_0xD7_, 0xe201c4
	.set SepaOut_FormatData_Tail_0xE3_, 0xe201d0
	.set SepaOut_FormatData_Tail_0xEF_, 0xe201dc
	.set SepaOut_FormatData_Tail_0xFB_, 0xe201e8
	.set SepaOut_FormatData_Tail_0x11B_, 0xe20208
	.set SepaOut_FormatData_Tail_0x163_, 0xe20250
	.set NakaWidgetPtrTbl_SmfDp_0x1DA0_, 0xe25e50
	.set NakaWidgetPtrTbl_SmfDp_0x1FC8_, 0xe26078
	.set NakaWidgetPtrTbl_SmfDp_0x1FE0_, 0xe26090
	.set NakaWidgetPtrTbl_SmfDp_0x1FF8_, 0xe260a8
	.set NakaWidgetPtrTbl_SmfDp_0x2010_, 0xe260c0
	.set NakaWidgetPtrTbl_SmfDp_0x2028_, 0xe260d8
	.set NakaWidgetPtrTbl_SmfDp_0x2040_, 0xe260f0
	.set NakaWidgetPtrTbl_SmfDp_0x2058_, 0xe26108
	.set NakaWidgetPtrTbl_SmfDp_0x2070_, 0xe26120
	.set NakaWidgetPtrTbl_SmfDp_0x221A_, 0xe262ca
	.set NakaWidgetPtrTbl_SmfDp_0x2332_, 0xe263e2
	.set NakaWidgetPtrTbl_SmfDp_0x235E_, 0xe2640e
	.set NakaWidgetPtrTbl_SmfDp_0x238A_, 0xe2643a
	.set NakaWidgetPtrTbl_SmfDp_0x2398_, 0xe26448
	.set NakaWidgetPtrTbl_SmfDp_0x23B8_, 0xe26468
	.set NakaWidgetPtrTbl_SmfDp_0x23CC_, 0xe2647c
	.set NakaWidgetPtrTbl_SmfDp_0x23E0_, 0xe26490
	.set NakaWidgetPtrTbl_SmfDp_0x23E4_, 0xe26494
	.set NakaWidgetPtrTbl_SmfDp_0x23E8_, 0xe26498
	.set NakaWidgetPtrTbl_SmfDp_0x23EC_, 0xe2649c
	.set NakaWidgetPtrTbl_SmfDp_0x23F0_, 0xe264a0
	.set NakaWidgetPtrTbl_SmfDp_0x23F4_, 0xe264a4
	.set NakaWidgetPtrTbl_SmfDp_0x23F8_, 0xe264a8
	.set NakaWidgetPtrTbl_SmfDp_0x23FC_, 0xe264ac
	.set NakaWidgetPtrTbl_SmfDp_0x2400_, 0xe264b0
	.set NakaWidgetPtrTbl_SmfDp_0x2404_, 0xe264b4
	.set NakaWidgetPtrTbl_SmfDp_0x2408_, 0xe264b8
	.set NakaWidgetPtrTbl_SmfDp_0x240C_, 0xe264bc
	.set NakaWidgetPtrTbl_SmfDp_0x2410_, 0xe264c0
	.set NakaWidgetPtrTbl_SmfDp_0x2414_, 0xe264c4
	.set NakaWidgetPtrTbl_SmfDp_0x2418_, 0xe264c8
	.set NakaWidgetPtrTbl_SmfDp_0x241C_, 0xe264cc
	.set NakaWidgetPtrTbl_SmfDp_0x2420_, 0xe264d0
	.set NakaWidgetPtrTbl_SmfDp_0x242E_, 0xe264de
	.set NakaWidgetPtrTbl_SmfDp_0x2434_, 0xe264e4
	.set NakaWidgetPtrTbl_SmfDp_0x243A_, 0xe264ea
	.set NakaWidgetPtrTbl_SmfDp_0x2460_, 0xe26510
	.set NakaWidgetPtrTbl_SmfDp_0x2500_, 0xe265b0
	.set NakaWidgetPtrTbl_SmfDp_0x2514_, 0xe265c4
	.set NakaWidgetPtrTbl_SmfDp_0x25AE_, 0xe2665e
	.set NakaWidgetPtrTbl_SmfDp_0x25C2_, 0xe26672
	.set NakaWidgetPtrTbl_SmfDp_0x25D6_, 0xe26686
	.set NakaWidgetPtrTbl_SmfDp_0x25F6_, 0xe266a6
	.set NakaWidgetPtrTbl_SmfDp_0x26B6_, 0xe26766
	.set NakaWidgetPtrTbl_SmfDp_0x26CA_, 0xe2677a
	.set NakaWidgetPtrTbl_SmfDp_0x26D6_, 0xe26786
	.set MedleyDisp_Blank_0x0C_, 0xe2679e
	.set MedleyDisp_Blank_0x18_, 0xe267aa
	.set PlayModeStr_Play_0x06_, 0xe267c4
	.set PlayModeStr_Play_0x0C_, 0xe267ca
	.set PlayModeStr_Pause_0x06_, 0xe267e4
	.set PlayModeStr_Pause_0x0C_, 0xe267ea
	.set Naka_ReverbScreen_EmptyStr_0x4804_, 0xe2c7a8
	.set NakaInst_FADE_IN_OUT_SETTING_0x2475_, 0xe3000b
	.set Naka_Help_569_E30113_0x82B_, 0xe3093e
	.set Naka_Help_569_E30113_0x833_, 0xe30946
	.set Naka_Help_569_E30113_0xCB3_, 0xe30dc6
	.set Naka_Help_569_E30113_0xCEB_, 0xe30dfe
	.set NakaData_WidgetDescriptors_0x1F4_, 0xe31054
	.set NakaData_WidgetDescriptors_0x272_, 0xe310d2
	.set NakaData_WidgetDescriptors_0x466_, 0xe312c6
	.set NakaData_WidgetDescriptors_0x65A_, 0xe314ba
	.set NakaData_WidgetDescriptors_0x84E_, 0xe316ae
	.set NakaData_WidgetDescriptors_0xA42_, 0xe318a2
	.set NakaData_WidgetDescriptors_0xBB0_, 0xe31a10
	.set NakaData_WidgetDescriptors_0xBBA_, 0xe31a1a
	.set NakaData_WidgetDescriptors_0xDAE_, 0xe31c0e
	.set NakaData_WidgetDescriptors_0xFA2_, 0xe31e02
	.set NakaData_WidgetDescriptors_0x1196_, 0xe31ff6
	.set NakaData_WidgetDescriptors_0x11A6_, 0xe32006
	.set NakaData_WidgetDescriptors_0x139A_, 0xe321fa
	.set NakaData_WidgetDescriptors_0x1530_, 0xe32390
	.set NakaData_WidgetDescriptors_0x15B8_, 0xe32418
	.set NakaData_WidgetDescriptors_0x1664_, 0xe324c4
	.set NakaData_WidgetDescriptors_0x1C1A_, 0xe32a7a
	.set NakaInst_NO_OPERATION_0x12_, 0xe3357a
	.set NakaInst_NO_OPERATION_0x1A_, 0xe33582
	.set NakaInst_NO_OPERATION_0x22_, 0xe3358a
	.set NakaInst_NO_OPERATION_0x82_, 0xe335ea
	.set NakaInst_NO_OPERATION_0x19A_, 0xe33702
	.set NakaInst_NO_OPERATION_0x1D4_, 0xe3373c
	.set NakaInst_NO_OPERATION_0x1F0_, 0xe33758
	.set NakaInst_NO_OPERATION_0x1FC_, 0xe33764
	.set NakaInst_NO_OPERATION_0x208_, 0xe33770
	.set NakaInst_NO_OPERATION_0x250_, 0xe337b8
	.set NakaInst_NO_OPERATION_0x268_, 0xe337d0
	.set NakaInst_NO_OPERATION_0x27A_, 0xe337e2
	.set NakaInst_anular_la_pista_se_borra_la_grabaci_n_de_las_0x3F4_, 0xe343ee
	.set NakaInst_anular_la_pista_se_borra_la_grabaci_n_de_las_0x4DA_, 0xe344d4
	.set ExtDevice_ModeDispatch_Table_0x14_, 0xe344ec
	.set ExtDevice_ModeDispatch_Table_0x2C_, 0xe34504
	.set ExtDevice_ModeDispatch_Table_0x44_, 0xe3451c
	.set ExtDevice_ModeDispatch_Table_0x5C_, 0xe34534
	.set ExtDevice_ModeDispatch_Table_0x74_, 0xe3454c
	.set ExtDevice_ModeDispatch_Table_0x8C_, 0xe34564
	.set ExtDevice_ModeDispatch_Table_0xA4_, 0xe3457c
	.set ExtDevice_ModeDispatch_Table_0xBC_, 0xe34594
	.set ExtDevice_ModeDispatch_Table_0xD4_, 0xe345ac
	.set ExtDevice_ModeDispatch_Table_0xEC_, 0xe345c4
	.set ExtDevice_ModeDispatch_Table_0x104_, 0xe345dc
	.set ExtDevice_ModeDispatch_Table_0x11C_, 0xe345f4
	.set ExtDevice_ModeDispatch_Table_0x140_, 0xe34618
	.set ExtDevice_ModeDispatch_Table_0x148_, 0xe34620
	.set ExtDevice_ModeDispatch_Table_0x14C_, 0xe34624
	.set ExtDevice_ModeDispatch_Table_0x154_, 0xe3462c
	.set ExtDevice_ModeDispatch_Table_0x160_, 0xe34638
	.set ExtDevice_ModeDispatch_Table_0x164_, 0xe3463c
	.set ExtDevice_ModeDispatch_Table_0x17C_, 0xe34654
	.set ExtDevice_ModeDispatch_Table_0x19C_, 0xe34674
	.set ExtDevice_ModeDispatch_Table_0x1A2_, 0xe3467a
	.set ExtDevice_ModeDispatch_Table_0x1A8_, 0xe34680
	.set ExtDevice_ModeDispatch_Table_0x1AC_, 0xe34684
	.set ExtDevice_ModeDispatch_Table_0x1B2_, 0xe3468a
	.set ExtDevice_ModeDispatch_Table_0x1B8_, 0xe34690
	.set ExtDevice_ModeDispatch_Table_0x1BC_, 0xe34694
	.set ExtDevice_ModeDispatch_Table_0x1C8_, 0xe346a0
	.set ExtDevice_ModeDispatch_Table_0x1D0_, 0xe346a8
	.set ExtDevice_ModeDispatch_Table_0x1D8_, 0xe346b0
	.set ExtDevice_ModeDispatch_Table_0x1E0_, 0xe346b8
	.set ExtDevice_ModeDispatch_Table_0x1E8_, 0xe346c0
	.set ExtDevice_ModeDispatch_Table_0x1F0_, 0xe346c8
	.set ExtDevice_ModeDispatch_Table_0x1FC_, 0xe346d4
	.set ExtDevice_ModeDispatch_Table_0x200_, 0xe346d8
	.set ExtDevice_ModeDispatch_Table_0x21C_, 0xe346f4
	.set ExtDevice_ModeDispatch_Table_0x246_, 0xe3471e
	.set ExtDevice_ModeDispatch_Table_0x258_, 0xe34730
	.set ExtDevice_ModeDispatch_Table_0x26A_, 0xe34742
	.set ExtDevice_ModeDispatch_Table_0x278_, 0xe34750
	.set ExtDevice_ModeDispatch_Table_0x29C_, 0xe34774
	.set ExtDevice_ModeDispatch_Table_0x2B0_, 0xe34788
	.set ExtDevice_ModeDispatch_Table_0x2BA_, 0xe34792
	.set ExtDevice_ModeDispatch_Table_0x2CE_, 0xe347a6
	.set ExtDevice_ModeDispatch_Table_0x2D8_, 0xe347b0
	.set ExtDevice_ModeDispatch_Table_0x2F6_, 0xe347ce
	.set ExtDevice_ModeDispatch_Table_0x308_, 0xe347e0
	.set ExtDevice_ModeDispatch_Table_0x31A_, 0xe347f2
	.set ExtDevice_ModeDispatch_Table_0x334_, 0xe3480c
	.set ExtDevice_ModeDispatch_Table_0x344_, 0xe3481c
	.set ExtDevice_ModeDispatch_Table_0x362_, 0xe3483a
	.set ExtDevice_ModeDispatch_Table_0x37A_, 0xe34852
	.set ExtDevice_ModeDispatch_Table_0x38A_, 0xe34862
	.set ExtDevice_ModeDispatch_Table_0x3A2_, 0xe3487a
	.set ExtDevice_ModeDispatch_Table_0x3B2_, 0xe3488a
	.set ExtDevice_ModeDispatch_Table_0x3B8_, 0xe34890
	.set ExtDevice_ModeDispatch_Table_0x3BC_, 0xe34894
	.set ExtDevice_ModeDispatch_Table_0x3C2_, 0xe3489a
	.set ExtDevice_ModeDispatch_Table_0x3C8_, 0xe348a0
	.set ExtDevice_ModeDispatch_Table_0x3CE_, 0xe348a6
	.set ExtDevice_ModeDispatch_Table_0x3D0_, 0xe348a8
	.set ExtDevice_ModeDispatch_Table_0x3DE_, 0xe348b6
	.set ExtDevice_ModeDispatch_Table_0x3EC_, 0xe348c4
	.set ExtDevice_ModeDispatch_Table_0x3FA_, 0xe348d2
	.set ExtDevice_ModeDispatch_Table_0x402_, 0xe348da
	.set ExtDevice_ModeDispatch_Table_0x408_, 0xe348e0
	.set ExtDevice_ModeDispatch_Table_0x428_, 0xe34900
	.set ExtDevice_ModeDispatch_Table_0x42C_, 0xe34904
	.set ExtDevice_ModeDispatch_Table_0x430_, 0xe34908
	.set ExtDevice_ModeDispatch_Table_0x43E_, 0xe34916
	.set ExtDevice_ModeDispatch_Table_0x44E_, 0xe34926
	.set ExtDevice_ModeDispatch_Table_0x45E_, 0xe34936
	.set ExtDevice_ModeDispatch_Table_0x4C6_, 0xe3499e
	.set ExtDevice_ModeDispatch_Table_0x4FC_, 0xe349d4
	.set ExtDevice_ModeDispatch_Table_0x53E_, 0xe34a16
	.set ExtDevice_ModeDispatch_Table_0x55A_, 0xe34a32
	.set ExtDevice_ModeDispatch_Table_0x5C4_, 0xe34a9c
	.set ExtDevice_ModeDispatch_Table_0x5C8_, 0xe34aa0
	.set ExtDevice_ModeDispatch_Table_0x5CC_, 0xe34aa4
	.set ExtDevice_ModeDispatch_Table_0x5D0_, 0xe34aa8
	.set ExtDevice_ModeDispatch_Table_0x5D6_, 0xe34aae
	.set ExtDevice_ModeDispatch_Table_0x5DA_, 0xe34ab2
	.set ExtDevice_ModeDispatch_Table_0x5E0_, 0xe34ab8
	.set ExtDevice_ModeDispatch_Table_0x5E6_, 0xe34abe
	.set ExtDevice_ModeDispatch_Table_0x5EC_, 0xe34ac4
	.set ExtDevice_ModeDispatch_Table_0x5F2_, 0xe34aca
	.set ExtDevice_ModeDispatch_Table_0x5F8_, 0xe34ad0
	.set ExtDevice_ModeDispatch_Table_0x5FE_, 0xe34ad6
	.set ExtDevice_ModeDispatch_Table_0x604_, 0xe34adc
	.set ExtDevice_ModeDispatch_Table_0x60A_, 0xe34ae2
	.set ExtDevice_ModeDispatch_Table_0x610_, 0xe34ae8
	.set ExtDevice_ModeDispatch_Table_0x616_, 0xe34aee
	.set ExtDevice_ModeDispatch_Table_0x61C_, 0xe34af4
	.set ExtDevice_ModeDispatch_Table_0x628_, 0xe34b00
	.set ExtDevice_ModeDispatch_Table_0x62E_, 0xe34b06
	.set ExtDevice_ModeDispatch_Table_0x634_, 0xe34b0c
	.set ExtDevice_ModeDispatch_Table_0x63A_, 0xe34b12
	.set ExtDevice_ModeDispatch_Table_0x64A_, 0xe34b22
	.set ExtDevice_ModeDispatch_Table_0x660_, 0xe34b38
	.set ExtDevice_ModeDispatch_Table_0x674_, 0xe34b4c
	.set ExtDevice_ModeDispatch_Table_0x67A_, 0xe34b52
	.set ExtDevice_ModeDispatch_Table_0x680_, 0xe34b58
	.set ExtDevice_ModeDispatch_Table_0x692_, 0xe34b6a
	.set ExtDevice_ModeDispatch_Table_0x698_, 0xe34b70
	.set ExtDevice_ModeDispatch_Table_0x69E_, 0xe34b76
	.set ExtDevice_ModeDispatch_Table_0x6A4_, 0xe34b7c
	.set ExtDevice_ModeDispatch_Table_0x6AA_, 0xe34b82
	.set NakaInst_3d_0x06_, 0xe34b8e
	.set NakaInst_3d_0x0C_, 0xe34b94
	.set NakaInst_3d_0x12_, 0xe34b9a
	.set NakaInst_3d_0x3E_, 0xe34bc6
	.set NakaInst_3d_0x44_, 0xe34bcc
	.set NakaInst_3d_0x4C_, 0xe34bd4
	.set NakaInst_3d_0x54_, 0xe34bdc
	.set NakaInst_3d_0x5A_, 0xe34be2
	.set NakaInst_3d_0x60_, 0xe34be8
	.set NakaInst_3d_0x68_, 0xe34bf0
	.set NakaInst_3d_0x70_, 0xe34bf8
	.set NakaInst_3d_0x76_, 0xe34bfe
	.set NakaInst_3d_0x7E_, 0xe34c06
	.set NakaInst_3d_0x86_, 0xe34c0e
	.set NakaInst_3d_0x8C_, 0xe34c14
	.set NakaInst_3d_0x92_, 0xe34c1a
	.set NakaInst_3d_0x98_, 0xe34c20
	.set NakaInst_3d_0x9E_, 0xe34c26
	.set NakaInst_3d_0xA4_, 0xe34c2c
	.set NakaInst_3d_0xAA_, 0xe34c32
	.set NakaInst_3d_0xB0_, 0xe34c38
	.set NakaInst_3d_0xB6_, 0xe34c3e
	.set NakaInst_3d_0xC2_, 0xe34c4a
	.set NakaInst_2d_0x06_, 0xe34c56
	.set NakaInst_2d_0x12_, 0xe34c62
	.set NakaInst_2d_0x1C_, 0xe34c6c
	.set NakaInst_2d_0x20_, 0xe34c70
	.set NakaInst_2d_0x40_, 0xe34c90
	.set NakaInst_2d_0x5E_, 0xe34cae
	.set NakaInst_2d_0x70_, 0xe34cc0
	.set NakaInst_2d_0x80_, 0xe34cd0
	.set NakaInst_2d_0x92_, 0xe34ce2
	.set NakaInst_2d_0xA0_, 0xe34cf0
	.set NakaInst_2d_0xB0_, 0xe34d00
	.set NakaInst_2d_0xC0_, 0xe34d10
	.set NakaInst_2d_0xD0_, 0xe34d20
	.set NakaInst_2d_0x120_, 0xe34d70
	.set NakaInst_2d_0x142_, 0xe34d92
	.set NakaInst_2d_0x154_, 0xe34da4
	.set NakaInst_2d_0x176_, 0xe34dc6
	.set NakaInst_2d_0x17E_, 0xe34dce
	.set NakaInst_2d_0x18C_, 0xe34ddc
	.set NakaInst_2d_0x19E_, 0xe34dee
	.set NakaInst_2d_0x1BC_, 0xe34e0c
	.set NakaInst_2d_0x1C2_, 0xe34e12
	.set NakaInst_2d_0x1C8_, 0xe34e18
	.set NakaInst_2d_0x1D4_, 0xe34e24
	.set NakaInst_2d_0x1D8_, 0xe34e28
	.set NakaInst_2d_0x204_, 0xe34e54
	.set Bitmap_Ntedt0d_0x1189_, 0xe367f1
	.set Bitmap_Dredt0d_0x9A8_, 0xe40008
	.set Bitmap_Dredt0d_0x9A9_, 0xe40009
	.set Bitmap_Dredt0d_0x9AA_, 0xe4000a
	.set Bitmap_Dredt0d_0xA8D_, 0xe400ed
	.set WidgetData_DrawbarPositionTable_0x6A_, 0xe444e2
	.set WidgetData_DrawbarPositionTable_0x82_, 0xe444fa
	.set WidgetData_DrawbarPositionTable_0x86_, 0xe444fe
	.set WidgetData_DrawbarPositionTable_0xA6_, 0xe4451e
	.set WidgetData_DrawbarPositionTable_0xBE_, 0xe44536
	.set WidgetData_DrawbarPositionTable_0xD2_, 0xe4454a
	.set WidgetData_DrawbarPositionTable_0xE2_, 0xe4455a
	.set WidgetData_DrawbarPositionTable_0xF2_, 0xe4456a
	.set WidgetData_DrawbarPositionTable_0x122_, 0xe4459a
	.set WidgetData_DrawbarPositionTable_0x12E_, 0xe445a6
	.set WidgetData_DrawbarPositionTable_0x13A_, 0xe445b2
	.set WidgetData_DrawbarPositionTable_0x146_, 0xe445be
	.set WidgetData_DrawbarPositionTable_0x152_, 0xe445ca
	.set WidgetData_DrawbarPositionTable_0x15E_, 0xe445d6
	.set WidgetData_DrawbarPositionTable_0x16A_, 0xe445e2
	.set WidgetData_DrawbarPositionTable_0x176_, 0xe445ee
	.set WidgetData_DrawbarPositionTable_0x17A_, 0xe445f2
	.set WidgetData_DrawbarPositionTable_0x188_, 0xe44600
	.set WidgetData_DrawbarPositionTable_0x198_, 0xe44610
	.set WidgetData_DrawbarPositionTable_0x19C_, 0xe44614
	.set WidgetData_DrawbarPositionTable_0x1A0_, 0xe44618
	.set WidgetData_DrawbarPositionTable_0x1A4_, 0xe4461c
	.set WidgetData_DrawbarPositionTable_0x1A8_, 0xe44620
	.set WidgetData_DrawbarPositionTable_0x1B0_, 0xe44628
	.set WidgetData_DrawbarPositionTable_0x1B6_, 0xe4462e
	.set WidgetData_DrawbarPositionTable_0x1BA_, 0xe44632
	.set WidgetData_CharsetMappingTable_0x08_, 0xe4463e
	.set WidgetData_CharsetMappingTable_0x10_, 0xe44646
	.set WidgetData_CharsetMappingTable_0x20_, 0xe44656
	.set WidgetData_CharsetMappingTable_0x26_, 0xe4465c
	.set WidgetData_CharsetMappingTable_0xA6_, 0xe446dc
	.set WidgetData_CharsetMappingTable_0x126_, 0xe4475c
	.set WidgetData_CharsetMappingTable_0x1A6_, 0xe447dc
	.set WidgetData_CharsetMappingTable_0x226_, 0xe4485c
	.set WidgetData_CharsetMappingTable_0x248_, 0xe4487e
	.set WidgetData_CharsetMappingTable_0x264_, 0xe4489a
	.set WidgetData_CharsetMappingTable_0x270_, 0xe448a6
	.set WidgetData_CharsetMappingTable_0x27C_, 0xe448b2
	.set WidgetData_CharsetMappingTable_0x28C_, 0xe448c2
	.set WidgetData_CharsetMappingTable_0x29C_, 0xe448d2
	.set WidgetData_CharsetMappingTable_0x2C0_, 0xe448f6
	.set WidgetData_CharsetMappingTable_0x300_, 0xe44936
	.set WidgetData_CharsetMappingTable_0x30C_, 0xe44942
	.set WidgetData_CharsetMappingTable_0x318_, 0xe4494e
	.set WidgetData_CharsetMappingTable_0x328_, 0xe4495e
	.set WidgetData_CharsetMappingTable_0x338_, 0xe4496e
	.set WidgetData_CharsetMappingTable_0x35C_, 0xe44992
	.set WidgetData_CharsetMappingTable_0x39C_, 0xe449d2
	.set WidgetData_CharsetMappingTable_0x3AC_, 0xe449e2
	.set WidgetData_CharsetMappingTable_0x3CC_, 0xe44a02
	.set WidgetData_CharsetMappingTable_0x3E4_, 0xe44a1a
	.set WidgetData_CharsetMappingTable_0x3FC_, 0xe44a32
	.set WidgetData_CharsetMappingTable_0x40C_, 0xe44a42
	.set WidgetData_CharsetMappingTable_0x41C_, 0xe44a52
	.set WidgetData_CharsetMappingTable_0x434_, 0xe44a6a
	.set WidgetData_CharsetMappingTable_0x452_, 0xe44a88
	.set WidgetData_CharsetMappingTable_0x474_, 0xe44aaa
	.set WidgetData_CharsetMappingTable_0x4A6_, 0xe44adc
	.set WidgetData_CharsetMappingTable_0x4D8_, 0xe44b0e
	.set WidgetData_CharsetMappingTable_0x50A_, 0xe44b40
	.set FontPalette_Gradient7_0x32_, 0xe44ba4
	.set Display_FontPalette_Table_0x1E_, 0xe44e76
	.set Display_FontPalette_Table_0x20_, 0xe44e78
	.set Display_FontPalette_Table_0x24_, 0xe44e7c
	.set Display_FontPalette_Table_0x2C_, 0xe44e84
	.set Display_FontPalette_Table_0x30_, 0xe44e88
	.set Display_FontPalette_Table_0x36_, 0xe44e8e
	.set Display_FontPalette_Table_0x44_, 0xe44e9c
	.set Display_FontPalette_Table_0x46_, 0xe44e9e
	.set Display_FontPalette_Table_0x5C_, 0xe44eb4
	.set Display_FontPalette_Table_0x68_, 0xe44ec0
	.set Display_FontPalette_Table_0x7E_, 0xe44ed6
	.set Display_FontPalette_Table_0x8C_, 0xe44ee4
	.set Display_FontPalette_Table_0x9A_, 0xe44ef2
	.set Display_FontPalette_Table_0xA8_, 0xe44f00
	.set Display_FontPalette_Table_0x104_, 0xe44f5c
	.set Display_FontPalette_Table_0x160_, 0xe44fb8
	.set Display_FontPalette_Table_0x1FE_, 0xe45056
	.set Display_FontPalette_Table_0x21E_, 0xe45076
	.set Display_FontPalette_Table_0x23E_, 0xe45096
	.set Display_FontPalette_Table_0x24E_, 0xe450a6
	.set Display_FontPalette_Table_0x25E_, 0xe450b6
	.set Display_FontPalette_Table_0x27E_, 0xe450d6
	.set Display_FontPalette_Table_0x282_, 0xe450da
	.set Display_FontPalette_Table_0x2A2_, 0xe450fa
	.set Display_FontPalette_Table_0x2AC_, 0xe45104
	.set Display_FontPalette_Table_0x2C0_, 0xe45118
	.set Display_FontPalette_Table_0x2EA_, 0xe45142
	.set Display_FontPalette_Table_0x12EA_, 0xe46142
	.set Display_FontPalette_Table_0x136A_, 0xe461c2
	.set Display_FontPalette_Table_0x1532_, 0xe4638a
	.set Display_FontPalette_Table_0x1D32_, 0xe46b8a
	.set Display_FontPalette_Table_0x1D46_, 0xe46b9e
	.set Display_FontPalette_Table_0x1D58_, 0xe46bb0
	.set Display_FontPalette_Table_0x1D61_, 0xe46bb9
	.set Display_FontPalette_Table_0x1DA1_, 0xe46bf9
	.set Display_FontPalette_Table_0x1DBF_, 0xe46c17
	.set Display_FontPalette_Table_0x1EBF_, 0xe46d17
	.set Display_FontPalette_Table_0x21EF_, 0xe47047
	.set Display_FontPalette_Table_0x22EF_, 0xe47147
	.set Display_FontPalette_Table_0x3127_, 0xe47f7f
	.set Display_FontPalette_Table_0x4507_, 0xe4935f
	.set Display_FontPalette_Table_0x4D07_, 0xe49b5f
	.set Display_FontPalette_Table_0x4FFB_, 0xe49e53
	.set Display_FontPalette_Table_0x50FB_, 0xe49f53
	.set Display_FontPalette_Table_0x511C_, 0xe49f74
	.set Display_FontPalette_Table_0x513C_, 0xe49f94
	.set Display_FontPalette_Table_0x515C_, 0xe49fb4
	.set Display_FontPalette_Table_0x5170_, 0xe49fc8
	.set Display_FontPalette_Table_0x51E4_, 0xe4a03c
	.set Display_FontPalette_Table_0x51E8_, 0xe4a040
	.set Display_FontPalette_Table_0x51EC_, 0xe4a044
	.set Display_FontPalette_Table_0x524C_, 0xe4a0a4
	.set Display_FontPalette_Table_0x5260_, 0xe4a0b8
	.set Display_FontPalette_Table_0x5270_, 0xe4a0c8
	.set Display_FontPalette_Table_0x52C0_, 0xe4a118
	.set Display_FontPalette_Table_0x52CE_, 0xe4a126
	.set Display_FontPalette_Table_0x52DC_, 0xe4a134
	.set Display_FontPalette_Table_0x537C_, 0xe4a1d4
	.set Display_FontPalette_Table_0x53C2_, 0xe4a21a
	.set Display_FontPalette_Table_0x6E9A_, 0xe4bcf2
	.set Display_FontPalette_Table_0x701A_, 0xe4be72
	.set Display_FontPalette_Table_0x7028_, 0xe4be80
	.set Display_FontPalette_Table_0x7040_, 0xe4be98
	.set Display_FontPalette_Table_0x704E_, 0xe4bea6
	.set Display_FontPalette_Table_0x7068_, 0xe4bec0
	.set Display_FontPalette_Table_0x7076_, 0xe4bece
	.set Display_FontPalette_Table_0x7084_, 0xe4bedc
	.set Display_FontPalette_Table_0x709A_, 0xe4bef2
	.set Display_FontPalette_Table_0x70A8_, 0xe4bf00
	.set Display_FontPalette_Table_0x70D0_, 0xe4bf28
	.set Display_FontPalette_Table_0x70DE_, 0xe4bf36
	.set Display_FontPalette_Table_0x70F2_, 0xe4bf4a
	.set Display_FontPalette_Table_0x70FE_, 0xe4bf56
	.set Display_FontPalette_Table_0x710C_, 0xe4bf64
	.set Display_FontPalette_Table_0x7124_, 0xe4bf7c
	.set Display_FontPalette_Table_0x7132_, 0xe4bf8a
	.set Display_FontPalette_Table_0x715A_, 0xe4bfb2
	.set Display_FontPalette_Table_0x7168_, 0xe4bfc0
	.set Display_FontPalette_Table_0x71E0_, 0xe4c038
	.set NakaInst_MEMORY_A_0x0E_, 0xe4c06e
	.set NakaInst_MEMORY_A_0x26_, 0xe4c086
	.set NakaInst_MEMORY_A_0x34_, 0xe4c094
	.set NakaInst_MEMORY_A_0x42_, 0xe4c0a2
	.set NakaInst_MEMORY_A_0x50_, 0xe4c0b0
	.set NakaInst_MEMORY_A_0x5E_, 0xe4c0be
	.set NakaInst_DashDash_0x04_, 0xe4c0c6
	.set NakaInst_OFF_Str_0x04_, 0xe4c0d6
	.set NakaInst_OFF_Str_0x0A_, 0xe4c0dc
	.set NakaInst_OFF_Str_0x1E_, 0xe4c0f0
	.set NakaInst_OFF_Str_0x32_, 0xe4c104
	.set NakaInst_OFF_Str_0x42_, 0xe4c114
	.set NakaInst_OFF_Str_0x60_, 0xe4c132
	.set NakaInst_OFF_Str_0x6C_, 0xe4c13e
	.set NakaInst_OFF_Str_0x78_, 0xe4c14a
	.set NakaInst_OFF_Str_0x80_, 0xe4c152
	.set NakaInst_OFF_Str_0x84_, 0xe4c156
	.set NakaInst_OFF_Str_0x88_, 0xe4c15a
	.set NakaInst_OFF_Str_0x8C_, 0xe4c15e
	.set NakaInst_OFF_Str_0x90_, 0xe4c162
	.set NakaInst_OFF_Str_0x94_, 0xe4c166
	.set NakaInst_OFF_Str_0x98_, 0xe4c16a
	.set NakaInst_OFF_Str_0xB6_, 0xe4c188
	.set NakaInst_OFF_Str_0xD4_, 0xe4c1a6
	.set Bitmap_SplitPoint_Gb_0x2B_, 0xe600ed
	.set Bitmap_MIDIConnections_2_0x3BB0_, 0xe70002
	.set Bitmap_MIDIConnections_2_0x3BB3_, 0xe70005
	.set Bitmap_MIDIConnections_2_0x3BB8_, 0xe7000a
	.set Bitmap_MIDIConnections_2_0x3BBE_, 0xe70010
	.set Bitmap_MIDIConnections_2_0x3BC5_, 0xe70017
	.set Bitmap_MIDIConnections_2_0x3BC7_, 0xe70019
	.set Bitmap_MIDIConnections_2_0x3BCA_, 0xe7001c
	.set Bitmap_MIDIConnections_2_0x3BD2_, 0xe70024
	.set Bitmap_MIDIConnections_2_0x3BD4_, 0xe70026
	.set Bitmap_MIDIConnections_2_0x3BD5_, 0xe70027
	.set Bitmap_MIDIConnections_2_0x3BDA_, 0xe7002c
	.set Bitmap_MIDIConnections_2_0x3BDC_, 0xe7002e
	.set Bitmap_MIDIConnections_2_0x3BDD_, 0xe7002f
	.set MidiPart_PageDisplay_Data_0x08_, 0xe7ecfa
	.set MidiPart_PageDisplay_Data_0x0C_, 0xe7ecfe
	.set MidiPart_PageStr_1of2_0x0A_, 0xe7ed1a
	.set MidiPart_PageStr_1of3_0x0A_, 0xe7ed44
	.set MidiPart_PageStr_1of3_0x12_, 0xe7ed4c
	.set MidiPart_PageStr_1of3_0x2A_, 0xe7ed64
	.set MidiPart_PageStr_1of3_0x42_, 0xe7ed7c
	.set MidiPart_PageStr_1of3_0x50_, 0xe7ed8a
	.set MidiPart_OctaveStr_m2_0x04_, 0xe7ee60
	.set MidiPart_OctaveStr_m2_0x64_, 0xe7eec0
	.set MidiPart_OctaveStr_m2_0x84_, 0xe7eee0
	.set MidiPart_OctaveStr_m2_0x90_, 0xe7eeec
	.set MidiPart_OctaveStr_m2_0xD8_, 0xe7ef34
	.set MidiPart_OctaveStr_m2_0xE4_, 0xe7ef40
	.set MidiPart_OctaveStr_m2_0xF0_, 0xe7ef4c
	.set MidiPart_OctaveStr_m2_0xFC_, 0xe7ef58
	.set MidiPart_OctaveStr_m2_0x108_, 0xe7ef64
	.set MidiPart_OctaveStr_m2_0x128_, 0xe7ef84
	.set MidiPart_OctaveStr_m2_0x12E_, 0xe7ef8a
	.set MidiPart_OctaveStr_m2_0x134_, 0xe7ef90
	.set MidiPart_OctaveStr_m2_0x140_, 0xe7ef9c
	.set MidiPart_OctaveStr_m2_0x17C_, 0xe7efd8
	.set MidiPart_OctaveStr_m2_0x188_, 0xe7efe4
	.set MidiPart_OctaveStr_m2_0x194_, 0xe7eff0
	.set MidiPart_RecvTransStr_0x0C_, 0xe7f008
	.set MidiPart_AfterStr_0x28_, 0xe7f03c
	.set MidiPart_AfterStr_0x2E_, 0xe7f042
	.set MidiPart_AfterStr_0x34_, 0xe7f048
	.set MidiPart_ColWidthData_0x28_, 0xe7f098
	.set MidiPart_ColWidthData_0x36_, 0xe7f0a6
	.set MidiPart_ColWidthData_0x42_, 0xe7f0b2
	.set MidiPart_HarmLocalStr_0x18_, 0xe7f0ce
	.set MidiPart_HarmLocalStr_0x1C_, 0xe7f0d2
	.set MidiPart_HarmLocalStr_0x24_, 0xe7f0da
	.set MidiPart_HarmLocalStr_0x30_, 0xe7f0e6
	.set MidiPart_HarmLocalStr_0x36_, 0xe7f0ec
	.set MidiPart_HarmLocalStr_0x3C_, 0xe7f0f2
	.set GMMode_Attention_English2_0x204_, 0xe7f34e
	.set GMMode_Attention_English2_0x47C_, 0xe7f5c6
	.set GMMode_Attention_English2_0x494_, 0xe7f5de
	.set GMMode_Attention_English2_0x514_, 0xe7f65e
	.set SplitPoint_NoteEntry_C_Code_0x04_, 0xe7f7e2
	.set SplitPoint_NoteEntry_C_Code_0x38_, 0xe7f816
	.set SplitPoint_NoteEntry_C_Code_0x42_, 0xe7f820
	.set SplitPoint_NoteEntry_C_Code_0x48_, 0xe7f826
	.set SplitPoint_NoteEntry_C_Code_0x4E_, 0xe7f82c
	.set SplitPoint_NoteEntry_C_Code_0x54_, 0xe7f832
	.set SplitPoint_NoteEntry_C_Code_0x5A_, 0xe7f838
	.set SplitPoint_NoteEntry_C_Code_0x60_, 0xe7f83e
	.set SplitPoint_NoteEntry_C_Code_0x66_, 0xe7f844
	.set SplitPoint_NoteEntry_C_Code_0xD2_, 0xe7f8b0
	.set SplitPoint_NoteEntry_C_Code_0xDC_, 0xe7f8ba
	.set SplitPoint_NoteEntry_C_Code_0xF0_, 0xe7f8ce
	.set SplitPoint_NoteEntry_C_Code_0xFA_, 0xe7f8d8
	.set SplitPoint_NoteEntry_C_Code_0x104_, 0xe7f8e2
	.set SplitPoint_NoteEntry_C_Code_0x118_, 0xe7f8f6
	.set NakaInst_OFF_WidgetTbl2_0x12_, 0xe7f928
	.set NakaInst_OFF_WidgetTbl2_0x32_, 0xe7f948
	.set NakaInst_OFF_WidgetTbl2_0x40_, 0xe7f956
	.set NakaInst_OFF_WidgetTbl2_0x4E_, 0xe7f964
	.set NakaInst_OFF_WidgetTbl2_0x5C_, 0xe7f972
	.set NakaInst_OFF_WidgetTbl2_0x78_, 0xe7f98e
	.set NakaInst_OFF_WidgetTbl2_0x9C_, 0xe7f9b2
	.set NakaInst_OFF_WidgetTbl2_0xB0_, 0xe7f9c6
	.set NakaInst_OFF_WidgetTbl2_0xB6_, 0xe7f9cc
	.set NakaInst_OFF_WidgetTbl2_0xBC_, 0xe7f9d2
	.set NakaInst_OFF_WidgetTbl2_0xCA_, 0xe7f9e0
	.set NakaInst_OFF_WidgetTbl2_0xDC_, 0xe7f9f2
	.set NakaInst_OFF_WidgetTbl2_0xEE_, 0xe7fa04
	.set NakaInst_OFF_WidgetTbl2_0x100_, 0xe7fa16
	.set NakaInst_OFF_WidgetTbl2_0x112_, 0xe7fa28
	.set NakaInst_OFF_WidgetTbl2_0x1CC_, 0xe7fae2
	.set NakaInst_OFF_WidgetTbl2_0x29E_, 0xe7fbb4
	.set NakaInst_OFF_WidgetTbl2_0x370_, 0xe7fc86
	.set NakaInst_OFF_WidgetTbl2_0x37E_, 0xe7fc94
	.set NakaInst_OFF_E7FCA2_0x06_, 0xe7fca8
	.set ControlMode_Option_Table_0x0A_, 0xe7fcc4
	.set NakaInst_DIRECT_E7FCE4_0x0A_, 0xe7fcee
	.set NakaInst_DIRECT_E7FCE4_0x56_, 0xe7fd3a
	.set NakaInst_DIRECT_E7FCE4_0x68_, 0xe7fd4c
	.set NakaInst_DIRECT_E7FCE4_0x7A_, 0xe7fd5e
	.set NakaInst_DIRECT_E7FCE4_0x8C_, 0xe7fd70
	.set NakaInst_DIRECT_E7FCE4_0xA0_, 0xe7fd84
	.set NakaInst_DIRECT_E7FCE4_0xA6_, 0xe7fd8a
	.set FileTransfer_BlankStatus_0x0A_, 0xe7fdd6
	.set FileTransfer_BlankStatus_0x1E_, 0xe7fdea
	.set FileTransfer_BlankStatus_0x32_, 0xe7fdfe
	.set FileTransfer_BlankStatus_0x46_, 0xe7fe12
	.set FileTransfer_BlankStatus_0x5A_, 0xe7fe26
	.set FileTransfer_BlankStatus_0x6E_, 0xe7fe3a
	.set FileTransfer_BlankStatus_0x88_, 0xe7fe54
	.set FileTransfer_BlankStatus_0xA2_, 0xe7fe6e
	.set FileTransfer_BlankStatus_0xB4_, 0xe7fe80
	.set FileTransfer_BlankStatus_0xC6_, 0xe7fe92
	.set UserMemory_ConfirmData_0x16_, 0xe7feb6
	.set NakaInst_INITIAL_0x0A_, 0xe7ff02
	.set NakaInst_INITIAL_0x1A_, 0xe7ff12
	.set NakaInst_INITIAL_0x28_, 0xe7ff20
	.set UserMemory_FormatStrings_0x16_, 0xe7ff44
	.set UserMemory_FormatStrings_0xC0_, 0xe7ffee
	.set UserMemory_FormatStrings_0xCE_, 0xe7fffc
	.set UserMemory_FormatStrings_0xD6_, 0xe80004
	.set NakaData_ModeConfig1_0x04_, 0xe8000c
	.set NakaData_ModeConfig2_0x08_, 0xe80016
	.set NakaData_ModeConfig2_0x2C_, 0xe8003a
	.set NakaToggle_OnOff_Data_0x04_, 0xe80044
	.set NakaInst_OFF_E80048_0x02_, 0xe8004a
	.set NakaInst_OFF_E80048_0x08_, 0xe80050
	.set NakaInst_NORMAL_0x0A_, 0xe80064
	.set NakaInst_NORMAL_0x14_, 0xe8006e
	.set NakaInst_GM_0x08_, 0xe80078
	.set NakaInst_GM_0x12_, 0xe80082
	.set NakaInst_GM_0x18_, 0xe80088
	.set NakaInst_GM_0x1E_, 0xe8008e
	.set NakaInst_GM_0x28_, 0xe80098
	.set NakaInst_GM_0x32_, 0xe800a2
	.set NakaInst_GM_0x3C_, 0xe800ac
	.set NakaInst_GM_0x46_, 0xe800b6
	.set NakaInst_GM_0x50_, 0xe800c0
	.set NakaInst_GM_0x6C_, 0xe800dc
	.set NakaInst_NEXT_E800E8_0x02_, 0xe800ea
	.set NakaInst_2d_d_0x07_, 0xe80124
	.set NakaInst_ON_E80168_0x52_, 0xe801ba
	.set NakaInst_ON_E80168_0x58_, 0xe801c0
	.set NakaInst_ON_E80168_0x5E_, 0xe801c6
	.set NakaInst_ON_E80168_0x82_, 0xe801ea
	.set NakaInst_ON_E80168_0x10A_, 0xe80272
	.set NakaInst_ON_E80168_0x118_, 0xe80280
	.set NakaInst_ON_E80168_0x11A_, 0xe80282
	.set NakaInst_ON_E80168_0x12A_, 0xe80292
	.set NakaInst_ON_E80168_0x1A6_, 0xe8030e
	.set NakaInst_ON_E80168_0x210_, 0xe80378
	.set NakaInst_ON_E80168_0x21E_, 0xe80386
	.set NakaInst_ON_E80168_0x266_, 0xe803ce
	.set NakaInst_ON_E80168_0x270_, 0xe803d8
	.set NakaInst_ON_E80168_0x276_, 0xe803de
	.set NakaInst_ON_E80168_0x27C_, 0xe803e4
	.set NakaInst_ON_E80168_0x282_, 0xe803ea
	.set NakaInst_ON_E80168_0x288_, 0xe803f0
	.set NakaInst_ON_E80168_0x296_, 0xe803fe
	.set NakaInst_ON_E80168_0x298_, 0xe80400
	.set NakaInst_ON_E80168_0x2B4_, 0xe8041c
	.set NakaInst_ON_E80168_0x2C6_, 0xe8042e
	.set NakaInst_ON_E80168_0x2DA_, 0xe80442
	.set NakaInst_ON_E80168_0x2DE_, 0xe80446
	.set NakaInst_ON_E80168_0x2EE_, 0xe80456
	.set NakaInst_ON_E80168_0x32A_, 0xe80492
	.set NakaInst_ON_E80168_0x36C_, 0xe804d4
	.set NakaInst_ON_E80168_0x3AA_, 0xe80512
	.set NakaInst_ON_E80168_0x3B8_, 0xe80520
	.set NakaInst_ON_E80168_0x3C0_, 0xe80528
	.set Transpose_String_Plus2_0x12_, 0xe806b0
	.set Transpose_String_Plus2_0x52_, 0xe806f0
	.set Transpose_String_Plus2_0x58_, 0xe806f6
	.set Transpose_String_Plus2_0x5E_, 0xe806fc
	.set TextInput_Prop_NullTerm_0x01_, 0xe80c17
	.set MixerPartTable_Start_0x08_, 0xe952aa
	.set MixerPartTable_Start_0x80_, 0xe95322
	.set MixerPartTable_Start_0x104_, 0xe953a6
	.set MixerPartTable_Start_0x108_, 0xe953aa
	.set MixerPartTable_Start_0x128_, 0xe953ca
	.set MixerPartTable_Start_0x12C_, 0xe953ce
	.set Str_PartName_Right1_0x10_, 0xe95550
	.set Str_PartName_Right1_0x24_, 0xe95564
	.set Str_PartName_Right1_0x4C_, 0xe9558c
	.set Str_PartName_Right1_0x52_, 0xe95592
	.set Str_PartName_Right1_0x5C_, 0xe9559c
	.set Str_PartName_Right1_0x62_, 0xe955a2
	.set Str_PartName_Right1_0x68_, 0xe955a8
	.set Str_PartName_Right1_0x6C_, 0xe955ac
	.set Str_PartName_Right1_0x72_, 0xe955b2
	.set Str_PartName_Right1_0x78_, 0xe955b8
	.set Str_PartName_Right1_0x8C_, 0xe955cc
	.set Str_PartName_Right1_0x90_, 0xe955d0
	.set Str_PartName_Right1_0x94_, 0xe955d4
	.set Str_PartName_Right1_0x98_, 0xe955d8
	.set Str_PartName_Right1_0x9C_, 0xe955dc
	.set Str_PartName_Right1_0xA0_, 0xe955e0
	.set Str_PartName_Right1_0xB2_, 0xe955f2
	.set Str_PartName_Right1_0xB6_, 0xe955f6
	.set Str_PartName_Right1_0xC0_, 0xe95600
	.set Str_PartName_Right1_0xC6_, 0xe95606
	.set Str_PartName_Right1_0xD4_, 0xe95614
	.set Str_PartName_Right1_0xD8_, 0xe95618
	.set Str_PartName_Right1_0xDC_, 0xe9561c
	.set Str_PartName_Right1_0xE0_, 0xe95620
	.set Str_PartName_Right1_0xE4_, 0xe95624
	.set Str_PartName_Right1_0xE8_, 0xe95628
	.set Str_PartName_Right1_0xEC_, 0xe9562c
	.set Str_PartName_Right1_0xF0_, 0xe95630
	.set Str_PartName_Right1_0xF4_, 0xe95634
	.set Str_PartName_Right1_0xF8_, 0xe95638
	.set Str_PartName_Right1_0xFC_, 0xe9563c
	.set Str_PartName_Right1_0x100_, 0xe95640
	.set Str_PartName_Right1_0x104_, 0xe95644
	.set Str_PartName_Right1_0x108_, 0xe95648
	.set Str_PartName_Right1_0x10C_, 0xe9564c
	.set Str_PartName_Right1_0x110_, 0xe95650
	.set Str_PartName_Right1_0x114_, 0xe95654
	.set Str_PartName_Right1_0x118_, 0xe95658
	.set Str_DiskErr20_Italian_0x5DE_, 0xe97fec
	.set Str_Err24Chord_English_0x4E_, 0xe98382
	.set Str_Err24Ctrl_Italian_0x170_, 0xe9855c
	.set NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118_, 0xe9d340
	.set NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x11E_, 0xe9d346
	.set NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x122_, 0xe9d34a
	.set NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x586_, 0xe9d7ae
	.set NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x5A2_, 0xe9d7ca
	.set NakaInst_RIGHT_1_E9D9B0_0x1C_, 0xe9d9cc
	.set NakaInst_RIGHT_1_E9D9B0_0x54_, 0xe9da04
	.set NakaInst_RIGHT_1_E9DB0C_0x14_, 0xe9db20
	.set NakaInst_RIGHT_1_E9DB0C_0x64_, 0xe9db70
	.set NakaInst_RIGHT_1_E9DB0C_0x70_, 0xe9db7c
	.set NakaInst_RIGHT_1_E9DB0C_0xAA_, 0xe9dbb6
	.set NakaInst_KEY_C_E9DE14_0x0A_, 0xe9de1e
	.set NakaInst_TOTAL_0x34_, 0xe9de60
	.set Bitmap_DigitL_0x22_, 0xe9dec6
	.set Bitmap_DigitL_0x44_, 0xe9dee8
	.set Bitmap_DigitD_0x22_, 0xe9df4e
	.set Bitmap_DigitD_0x8DA_, 0xe9e806
	.set Bitmap_DigitD_0x11CE_, 0xe9f0fa
	.set Bitmap_DigitD_0x11D6_, 0xe9f102
	.set Bitmap_DigitD_0x11F0_, 0xe9f11c
	.set TrackName4_Tr1_0x2E_, 0xe9f5a8
	.set TrackName4_Tr1_0x42_, 0xe9f5bc
	.set MidiParamStr2_Sound_0x08_, 0xe9f6c0
	.set MidiParamStr2_Sound_0x48_, 0xe9f700
	.set MidiParam_MixerCfgData_0x02_, 0xe9f804
	.set MidiParam_MixerCfgData_0x2A_, 0xe9f82c
	.set MidiParam_MixerCfgData_0x6A_, 0xe9f86c
	.set MidiParam_MixerCfgData_0x78_, 0xe9f87a
	.set MidiParam_MixerCfgData_0x8A_, 0xe9f88c
	.set KeyShiftStr_Zero_0x28_, 0xe9f94e
	.set KeyShiftStr_Zero_0x3A_, 0xe9f960
	.set KeyShiftStr_Zero_0x5E_, 0xe9f984
	.set KeyShiftStr_Zero_0x6A_, 0xe9f990
	.set KeyShiftStr_Zero_0x8C_, 0xe9f9b2
	.set DemoDiskPrompt_English1_0x86_, 0xe9fcc4
	.set DemoDiskPrompt_English1_0x8A_, 0xe9fcc8
	.set DemoDiskPrompt_English1_0x8E_, 0xe9fccc
	.set DemoDiskPrompt_English1_0x92_, 0xe9fcd0
	.set DemoDiskPrompt_English1_0x96_, 0xe9fcd4
	.set DemoDiskPrompt_English1_0xB4_, 0xe9fcf2
	.set DemoDiskPrompt_English1_0xB8_, 0xe9fcf6
	.set DemoDiskPrompt_English1_0x192_, 0xe9fdd0
	.set FileTypeName_Song_0x06_, 0xe9fe16
	.set FileTypeName_Song_0x48_, 0xe9fe58
	.set FileTypeName_Song_0x5A_, 0xe9fe6a
	.set UIStr_No_0x04_, 0xe9fe80
	.set ImgAttr_Size_0x06_, 0xe9fe9a
	.set ImgAttrName_Src_0x04_, 0xe9ff28
	.set ImgAttrName_Src_0x46_, 0xe9ff6a
	.set ImgAttrName_Src_0x88_, 0xe9ffac
	.set ObjAttr_Obj_0x04_, 0xe9ffba
	.set ObjAttr_Obj_0x46_, 0xe9fffc
	.set Presentation_RootEntry_0x02_, 0xea0002
	.set Presentation_RootEntry_0x03_, 0xea0003
	.set Presentation_RootEntry_0x04_, 0xea0004
	.set Presentation_RootEntry_0x05_, 0xea0005
	.set Presentation_RootEntry_0x06_, 0xea0006
	.set Presentation_TagStrTable_0x04_, 0xea000c
	.set Presentation_TagStrTable_0x16_, 0xea001e
	.set Presentation_TagStrTable_0x17_, 0xea001f
	.set Presentation_TagStrTable_0x18_, 0xea0020
	.set Presentation_TagStrTable_0x1E_, 0xea0026
	.set Presentation_TagStrTable_0x20_, 0xea0028
	.set Presentation_TagStrTable_0x46_, 0xea004e
	.set Presentation_TagStrTable_0x4A_, 0xea0052
	.set Presentation_TagStrTable_0x64_, 0xea006c
	.set Presentation_TagStrTable_0x6E_, 0xea0076
	.set Presentation_TagStrTable_0x72_, 0xea007a
	.set Presentation_TagStrTable_0x88_, 0xea0090
	.set Presentation_TagStrTable_0x96_, 0xea009e
	.set Presentation_TagStrTable_0xA0_, 0xea00a8
	.set Presentation_TagStrTable_0xA4_, 0xea00ac
	.set Presentation_TagStrTable_0xA5_, 0xea00ad
	.set Presentation_TagStrTable_0xD2_, 0xea00da
	.set Presentation_TagStrTable_0xF2_, 0xea00fa
	.set Presentation_TagStrTable_0xFC_, 0xea0104
	.set Presentation_TagStrTable_0x100_, 0xea0108
	.set Presentation_TagStrTable_0x102_, 0xea010a
	.set Presentation_TagTableEnd_0x33_, 0xea0172
	.set Presentation_TagTableEnd_0x37_, 0xea0176
	.set Presentation_TagTableEnd_0x3B_, 0xea017a
	.set Presentation_TagTableEnd_0x3F_, 0xea017e
	.set Presentation_TagTableEnd_0x43_, 0xea0182
	.set Presentation_TagTableEnd_0x47_, 0xea0186
	.set Presentation_TagTableEnd_0x4D_, 0xea018c
	.set Presentation_TagTableEnd_0x51_, 0xea0190
	.set Presentation_TagTableEnd_0x55_, 0xea0194
	.set Presentation_TagTableEnd_0x59_, 0xea0198
	.set Presentation_TagTableEnd_0x5D_, 0xea019c
	.set Presentation_TagTableEnd_0x61_, 0xea01a0
	.set Presentation_TagTableEnd_0x65_, 0xea01a4
	.set Presentation_TagTableEnd_0x69_, 0xea01a8
	.set Presentation_TagTableEnd_0x6D_, 0xea01ac
	.set Presentation_TagTableEnd_0x71_, 0xea01b0
	.set Presentation_TagTableEnd_0x75_, 0xea01b4
	.set Presentation_TagTableEnd_0x79_, 0xea01b8
	.set Presentation_TagTableEnd_0x7D_, 0xea01bc
	.set Presentation_TagTableEnd_0x81_, 0xea01c0
	.set Presentation_TagTableEnd_0x83_, 0xea01c2
	.set Presentation_TagTableEnd_0xB1_, 0xea01f0
	.set Presentation_TagTableEnd_0xB5_, 0xea01f4
	.set Resource_Region3_Start_0x04_, 0xea0204
	.set Resource_Region3_Start_0x08_, 0xea0208
	.set Resource_Region3_Start_0x0C_, 0xea020c
	.set Resource_Region3_Start_0x10_, 0xea0210
	.set Resource_Region3_Start_0x12_, 0xea0212
	.set Resource_Region3_Start_0x40_, 0xea0240
	.set Resource_Region3_Start_0x44_, 0xea0244
	.set Resource_Region3_Start_0x48_, 0xea0248
	.set Resource_RegionPad_0x04_, 0xea0250
	.set Resource_RegionPad_0x08_, 0xea0254
	.set Resource_RegionPad_0x0C_, 0xea0258
	.set Resource_RegionPad_0x10_, 0xea025c
	.set Resource_RegionPad_0x14_, 0xea0260
	.set Resource_RegionPad_0x18_, 0xea0264
	.set Resource_RegionPad_0x1C_, 0xea0268
	.set Resource_RegionPad_0x9C_, 0xea02e8
	.set Resource_RegionPad_0xAC_, 0xea02f8
	.set Resource_RegionPad_0xBC_, 0xea0308
	.set Resource_RegionPad_0xCC_, 0xea0318
	.set Resource_RegionPad_0xDC_, 0xea0328
	.set SeqFileTypeCode_Lsw_0x04_, 0xea0390
	.set SeqFileTypeCode_Lsw_0x08_, 0xea0394
	.set SeqFileTypeCode_Lsw_0x0C_, 0xea0398
	.set SeqFileTypeCode_Lsw_0x4E_, 0xea03da
	.set SeqFileTypeCode_Lsw_0x50_, 0xea03dc
	.set SeqFileTypeCode_Lsw_0x5C_, 0xea03e8
	.set SeqFileTypeCode_Lsw_0x6A_, 0xea03f6
	.set SeqFileTypeCode_Lsw_0xAE_, 0xea043a
	.set Filename_TemplateArea_0x02_, 0xea044a
	.set Filename_TemplateArea_0x0A_, 0xea0452
	.set Filename_TemplateArea_0x18_, 0xea0460
	.set Filename_TemplateArea_0x1A_, 0xea0462
	.set Filename_TemplateArea_0x26_, 0xea046e
	.set Filename_TemplateArea_0x36_, 0xea047e
	.set Filename_TemplateArea_0x46_, 0xea048e
	.set Filename_TemplateArea_0x4A_, 0xea0492
	.set Filename_TemplateArea_0x4E_, 0xea0496
	.set Filename_TemplateArea_0x54_, 0xea049c
	.set Filename_TemplateArea_0x64_, 0xea04ac
	.set Filename_TemplateArea_0x6A_, 0xea04b2
	.set Filename_TemplateArea_0x70_, 0xea04b8
	.set Filename_TemplateArea_0x76_, 0xea04be
	.set FileOp_StubAndDirNames_0x04_, 0xea04c6
	.set FileOp_StubAndDirNames_0x08_, 0xea04ca
	.set FileOp_StubAndDirNames_0x0C_, 0xea04ce
	.set FileOp_StubAndDirNames_0x10_, 0xea04d2
	.set FileOp_StubAndDirNames_0x14_, 0xea04d6
	.set FileOp_StubAndDirNames_0x18_, 0xea04da
	.set FileOp_StubAndDirNames_0x1C_, 0xea04de
	.set FileOp_StubAndDirNames_0x1E_, 0xea04e0
	.set FileOp_StubAndDirNames_0x22_, 0xea04e4
	.set FileOp_StubAndDirNames_0x2C_, 0xea04ee
	.set FileOp_StubAndDirNames_0x30_, 0xea04f2
	.set FileOp_StubAndDirNames_0x3E_, 0xea0500
	.set FileOp_StubAndDirNames_0x42_, 0xea0504
	.set FileOp_StubAndDirNames_0x4C_, 0xea050e
	.set FileOp_StubAndDirNames_0x50_, 0xea0512
	.set FileOp_StubAndDirNames_0x5E_, 0xea0520
	.set FileOp_StubAndDirNames_0x62_, 0xea0524
	.set FileOp_StubAndDirNames_0x6C_, 0xea052e
	.set FileOp_StubAndDirNames_0x70_, 0xea0532
	.set FileOp_StubAndDirNames_0x7E_, 0xea0540
	.set FileOp_StubAndDirNames_0x82_, 0xea0544
	.set FileOp_StubAndDirNames_0x86_, 0xea0548
	.set FileOp_StubAndDirNames_0x8A_, 0xea054c
	.set FileOp_StubAndDirNames_0x90_, 0xea0552
	.set StorageAreaName_PanelMemory_0x0E_, 0xea05f2
	.set BankStr_Bank3_0x06_, 0xea0624
	.set BankStr_Memory_0x0A_, 0xea066a
	.set DiskOp_ChannelCfgTable_0x10_, 0xea067c
	.set DiskOp_ChannelCfgTable_0x44_, 0xea06b0
	.set DiskOp_ChannelCfgTable_0x52_, 0xea06be
	.set DiskOp_ChannelCfgTable_0x5A_, 0xea06c6
	.set DiskOp_ChannelCfgTable_0x64_, 0xea06d0
	.set DiskOp_ChannelCfgTable_0x6A_, 0xea06d6
	.set DiskOp_ChannelCfgTable_0x6E_, 0xea06da
	.set DiskOp_ChannelCfgTable_0x78_, 0xea06e4
	.set DiskOp_ChannelCfgTable_0x80_, 0xea06ec
	.set DiskOp_ChannelCfgTable_0x82_, 0xea06ee
	.set DiskOp_ChannelCfgTable_0x88_, 0xea06f4
	.set DiskOp_ChannelCfgTable_0x8E_, 0xea06fa
	.set DiskOp_ChannelCfgTable_0x94_, 0xea0700
	.set DiskOp_ChannelCfgTable_0x9A_, 0xea0706
	.set DiskOp_ChannelCfgTable_0xA0_, 0xea070c
	.set DiskOp_ChannelCfgTable_0xA6_, 0xea0712
	.set DiskOp_ChannelCfgTable_0xAC_, 0xea0718
	.set DiskOp_ChannelCfgTable_0xB2_, 0xea071e
	.set DiskOp_ChannelCfgTable_0xB8_, 0xea0724
	.set DiskOp_ChannelCfgTable_0xBE_, 0xea072a
	.set DiskOp_ChannelCfgTable_0xC4_, 0xea0730
	.set DiskOp_ChannelCfgTable_0xCA_, 0xea0736
	.set DiskOp_ChannelCfgTable_0xD0_, 0xea073c
	.set DiskOp_ChannelCfgTable_0xDC_, 0xea0748
	.set DiskOp_ChannelCfgTable_0xE8_, 0xea0754
	.set Str_SmfConvert_GmToGm_0x10_, 0xea0790
	.set Str_SmfConvert_GmToGm_0x1E_, 0xea079e
	.set Str_SmfConvert_GmToGm_0x2A_, 0xea07aa
	.set Str_SmfConvert_GmToGm_0x2E_, 0xea07ae
	.set Str_Variation1_0x08_, 0xea083e
	.set PtrTbl_DrumKitNames_0x02_, 0xea08da
	.set PtrTbl_DrumKitNames_0x60_, 0xea0938
	.set PtrTbl_DrumKitNames_0x64_, 0xea093c
	.set PtrTbl_DrumKitNames_0x68_, 0xea0940
	.set PtrTbl_DrumKitNames_0x7A_, 0xea0952
	.set PtrTbl_DrumKitNames_0x80_, 0xea0958
	.set PtrTbl_DrumKitNames_0x82_, 0xea095a
	.set PtrTbl_DrumKitNames_0x86_, 0xea095e
	.set PtrTbl_DrumKitNames_0x8A_, 0xea0962
	.set PtrTbl_DrumKitNames_0x9C_, 0xea0974
	.set PtrTbl_DrumKitNames_0xA0_, 0xea0978
	.set PtrTbl_DrumKitNames_0xA4_, 0xea097c
	.set Str_AllOption_EA0980_0x12_, 0xea0992
	.set Str_AllOption_EA0980_0x16_, 0xea0996
	.set Str_AllOption_EA0980_0x2A_, 0xea09aa
	.set Str_AllOption_EA0980_0x2E_, 0xea09ae
	.set Str_AllOption_EA09B2_0x12_, 0xea09c4
	.set Str_AllOption_EA09B2_0x16_, 0xea09c8
	.set Str_AllOption_EA09B2_0x1A_, 0xea09cc
	.set Str_AllOption_EA09B2_0x20_, 0xea09d2
	.set Str_AllOption_EA09B2_0x24_, 0xea09d6
	.set Str_AllOption_EA09B2_0x28_, 0xea09da
	.set Str_AllOption_EA09B2_0x3A_, 0xea09ec
	.set Data_SaveLoadMenuTable_0x04_, 0xea09f4
	.set Data_SaveLoadMenuTable_0x08_, 0xea09f8
	.set Data_SaveLoadMenuTable_0x1A_, 0xea0a0a
	.set Data_SaveLoadMenuTable_0x1E_, 0xea0a0e
	.set Data_SaveLoadMenuTable_0x22_, 0xea0a12
	.set Data_SaveLoadMenuTable_0x26_, 0xea0a16
	.set Data_SaveLoadMenuTable_0x3A_, 0xea0a2a
	.set Data_SaveLoadMenuTable_0x4E_, 0xea0a3e
	.set Data_SaveLoadMenuTable_0x62_, 0xea0a52
	.set Data_SaveLoadMenuTable_0x64_, 0xea0a54
	.set NakaInst_WaitWinCtlSmf_0x7C8_, 0xea85c8
	.set NakaInst_WaitWinCtlSmf_0x88E_, 0xea868e
	.set NakaInst_WaitWinCtlSmf_0xA32_, 0xea8832
	.set NakaInst_WaitWinCtlSmf_0xC0C_, 0xea8a0c
	.set NakaInst_WaitWinCtlSmf_0xDF0_, 0xea8bf0
	.set NakaInst_WaitWinCtlSmf_0xDFE_, 0xea8bfe
	.set NakaInst_WaitWinCtlSmf_0xE5C_, 0xea8c5c
	.set DiskWarning_ConfirmStrings_0x30_, 0xea8cdc
	.set DiskWarning_ConfirmStrings_0x1C4_, 0xea8e70
	.set DiskWarning_ConfirmStrings_0x47E_, 0xea912a
	.set DiskWarning_ConfirmStrings_0x790_, 0xea943c
	.set DiskWarning_ConfirmStrings_0x8AC_, 0xea9558
	.set DiskWarning_ConfirmStrings_0x9DE_, 0xea968a
	.set DiskWarning_ConfirmStrings_0xA38_, 0xea96e4
	.set DiskWarning_ConfirmStrings_0xA4C_, 0xea96f8
	.set DiskWarning_ConfirmStrings_0xA6C_, 0xea9718
	.set DiskWarning_ConfirmStrings_0xB46_, 0xea97f2
	.set DiskWarning_ConfirmStrings_0xBFA_, 0xea98a6
	.set DiskWarning_ConfirmStrings_0xC06_, 0xea98b2
	.set DiskWarning_ConfirmStrings_0xC1E_, 0xea98ca
	.set DiskWarning_ConfirmStrings_0xC36_, 0xea98e2
	.set DiskWarning_ConfirmStrings_0xCBA_, 0xea9966
	.set DiskWarning_ConfirmStrings_0xD4C_, 0xea99f8
	.set DiskWarning_ConfirmStrings_0xD58_, 0xea9a04
	.set DiskWarning_ConfirmStrings_0xDAE_, 0xea9a5a
	.set DiskWarning_ConfirmStrings_0xE2E_, 0xea9ada
	.set DiskWarning_ConfirmStrings_0xE56_, 0xea9b02
	.set DiskWarning_ConfirmStrings_0xE70_, 0xea9b1c
	.set DiskWarning_ConfirmStrings_0xE8A_, 0xea9b36
	.set DiskWarning_ConfirmStrings_0xE96_, 0xea9b42
	.set DiskWarning_ConfirmStrings_0xEB4_, 0xea9b60
	.set DiskWarning_ConfirmStrings_0xEC4_, 0xea9b70
	.set DiskWarning_ConfirmStrings_0xED6_, 0xea9b82
	.set DiskWarning_ConfirmStrings_0xF00_, 0xea9bac
	.set DiskWarning_ConfirmStrings_0xF12_, 0xea9bbe
	.set DiskWarning_ConfirmStrings_0xF32_, 0xea9bde
	.set DiskWarning_ConfirmStrings_0xF46_, 0xea9bf2
	.set DiskWarning_ConfirmStrings_0x1154_, 0xea9e00
	.set Data_SoundEditorCharsLayout_0x0C_, 0xea9ede
	.set Data_SoundEditorCharsLayout_0x18_, 0xea9eea
	.set Data_SoundEditorCharsLayout_0x24_, 0xea9ef6
	.set Data_SoundEditorCharsLayout_0x4E_, 0xea9f20
	.set Data_SoundEditorCharsLayout_0x294_, 0xeaa166
	.set Data_SoundEditorCharsLayout_0x298_, 0xeaa16a
	.set Data_SoundEditorCharsLayout_0x29C_, 0xeaa16e
	.set Data_SoundEditorCharsLayout_0x2A0_, 0xeaa172
	.set Data_SoundEditorCharsLayout_0x2A4_, 0xeaa176
	.set Data_SoundEditorCharsLayout_0x2A8_, 0xeaa17a
	.set Data_SoundEditorCharsLayout_0x320_, 0xeaa1f2
	.set Data_SoundEditorCharsLayout_0x340_, 0xeaa212
	.set Data_SoundEditorCharsLayout_0x376_, 0xeaa248
	.set Data_SoundEditorCharsLayout_0x386_, 0xeaa258
	.set Data_SoundEditorCharsLayout_0x39A_, 0xeaa26c
	.set Data_SoundEditorCharsLayout_0x3B0_, 0xeaa282
	.set Data_SoundEditorCharsLayout_0x3C8_, 0xeaa29a
	.set Data_SoundEditorCharsLayout_0x3E8_, 0xeaa2ba
	.set Data_SoundEditorCharsLayout_0x3FC_, 0xeaa2ce
	.set Data_SoundEditorCharsLayout_0x410_, 0xeaa2e2
	.set Data_SoundEditorCharsLayout_0x414_, 0xeaa2e6
	.set Data_SoundEditorCharsLayout_0x418_, 0xeaa2ea
	.set Data_SoundEditorCharsLayout_0x41C_, 0xeaa2ee
	.set Data_SoundEditorCharsLayout_0x420_, 0xeaa2f2
	.set Data_SoundEditorCharsLayout_0x424_, 0xeaa2f6
	.set NakaInst_OK_0x04_, 0xeaa2fe
	.set NakaInst_OK_0x08_, 0xeaa302
	.set NakaInst_OK_0x0C_, 0xeaa306
	.set NakaInst_OK_0x0E_, 0xeaa308
	.set NakaInst_OK_0x10_, 0xeaa30a
	.set NakaInst_OK_0x14_, 0xeaa30e
	.set NakaInst_OK_0x18_, 0xeaa312
	.set Str_No_0x04_, 0xeaa31a
	.set Str_No_0x26_, 0xeaa33c
	.set Str_No_0x38_, 0xeaa34e
	.set Str_No_0x6E_, 0xeaa384
	.set Str_No_0x74_, 0xeaa38a
	.set Str_No_0x7A_, 0xeaa390
	.set Str_No_0x80_, 0xeaa396
	.set Str_No_0xB0_, 0xeaa3c6
	.set Str_No_0xF4_, 0xeaa40a
	.set Str_No_0x1F6_, 0xeaa50c
	.set Str_No_0x1FA_, 0xeaa510
	.set Str_No_0x30E_, 0xeaa624
	.set Str_No_0x39E_, 0xeaa6b4
	.set Str_No_0x3A4_, 0xeaa6ba
	.set Str_No_0x3E4_, 0xeaa6fa
	.set Str_No_0x3FC_, 0xeaa712
	.set Str_No_0x42E_, 0xeaa744
	.set Str_No_0x43A_, 0xeaa750
	.set Str_No_0x4DA_, 0xeaa7f0
	.set Str_No_0x504_, 0xeaa81a
	.set Str_No_0x514_, 0xeaa82a
	.set Str_No_0x51E_, 0xeaa834
	.set Str_No_0x52E_, 0xeaa844
	.set Str_No_0x58E_, 0xeaa8a4
	.set Str_No_0x5B6_, 0xeaa8cc
	.set Str_No_0x5C6_, 0xeaa8dc
	.set Str_No_0x5DE_, 0xeaa8f4
	.set Str_No_0x5E0_, 0xeaa8f6
	.set Str_No_0x5E2_, 0xeaa8f8
	.set Str_No_0x5F2_, 0xeaa908
	.set Str_No_0x5FE_, 0xeaa914
	.set Str_No_0x600_, 0xeaa916
	.set Str_No_0x602_, 0xeaa918
	.set Str_No_0x606_, 0xeaa91c
	.set Str_No_0x6AA_, 0xeaa9c0
	.set Str_No_0x6B6_, 0xeaa9cc
	.set Str_No_0x6D0_, 0xeaa9e6
	.set Str_No_0x6DE_, 0xeaa9f4
	.set Str_No_0x6E8_, 0xeaa9fe
	.set Str_No_0x6EE_, 0xeaaa04
	.set Str_No_0x6FA_, 0xeaaa10
	.set Str_No_0x700_, 0xeaaa16
	.set Str_No_0x70C_, 0xeaaa22
	.set Str_No_0x712_, 0xeaaa28
	.set Str_No_0x71E_, 0xeaaa34
	.set Str_No_0x724_, 0xeaaa3a
	.set Str_No_0x730_, 0xeaaa46
	.set Str_No_0x736_, 0xeaaa4c
	.set Str_No_0x742_, 0xeaaa58
	.set Str_No_0x748_, 0xeaaa5e
	.set Str_No_0x754_, 0xeaaa6a
	.set Str_No_0x866_, 0xeaab7c
	.set Str_No_0x86A_, 0xeaab80
	.set Str_No_0x892_, 0xeaaba8
	.set Str_No_0x896_, 0xeaabac
	.set Str_No_0x8B6_, 0xeaabcc
	.set Str_No_0x8BC_, 0xeaabd2
	.set Str_No_0x8C0_, 0xeaabd6
	.set Str_No_0x8C8_, 0xeaabde
	.set Str_No_0x8CE_, 0xeaabe4
	.set Str_No_0x8DC_, 0xeaabf2
	.set Str_No_0xAE0_, 0xeaadf6
	.set Str_No_0xB00_, 0xeaae16
	.set Str_No_0xB48_, 0xeaae5e
	.set Str_No_0xB4C_, 0xeaae62
	.set Str_No_0xB50_, 0xeaae66
	.set Str_No_0xB7E_, 0xeaae94
	.set Str_No_0xBBE_, 0xeaaed4
	.set Str_No_0xBFE_, 0xeaaf14
	.set Str_No_0xC8E_, 0xeaafa4
	.set Str_No_0xCBE_, 0xeaafd4
	.set Str_No_0xCC6_, 0xeaafdc
	.set Str_No_0xCCE_, 0xeaafe4
	.set Str_No_0xCD6_, 0xeaafec
	.set Str_No_0xCDE_, 0xeaaff4
	.set Str_No_0xCE6_, 0xeaaffc
	.set Str_No_0xCEE_, 0xeab004
	.set Str_No_0xDEE_, 0xeab104
	.set Str_No_0xDFE_, 0xeab114
	.set Str_No_0xE06_, 0xeab11c
	.set Str_No_0xE0E_, 0xeab124
	.set Str_No_0xE16_, 0xeab12c
	.set Str_No_0xE1A_, 0xeab130
	.set Str_No_0xE1E_, 0xeab134
	.set Str_No_0xE22_, 0xeab138
	.set Str_No_0xE2A_, 0xeab140
	.set Str_No_0xE36_, 0xeab14c
	.set Str_No_0xE3A_, 0xeab150
	.set Str_No_0xE3E_, 0xeab154
	.set Str_No_0xE42_, 0xeab158
	.set Str_No_0xE4A_, 0xeab160
	.set Str_No_0xE4E_, 0xeab164
	.set Str_No_0xE52_, 0xeab168
	.set Str_No_0xE56_, 0xeab16c
	.set Str_No_0xE5E_, 0xeab174
	.set Str_No_0xE62_, 0xeab178
	.set Str_No_0xE66_, 0xeab17c
	.set Str_No_0xE6A_, 0xeab180
	.set Str_No_0xE72_, 0xeab188
	.set Str_No_0xE7A_, 0xeab190
	.set Str_No_0xE7E_, 0xeab194
	.set Str_No_0xE82_, 0xeab198
	.set Str_No_0xE86_, 0xeab19c
	.set Data_CharMapFormatBlock_0x08_, 0xeab1a8
	.set Data_CharMapFormatBlock_0x10_, 0xeab1b0
	.set Data_CharMapFormatBlock_0x14_, 0xeab1b4
	.set Data_CharMapFormatBlock_0x22A_, 0xeab3ca
	.set Data_CharMapFormatBlock_0x22C_, 0xeab3cc
	.set NakaData_WidgetNames_0x624_, 0xeada94
	.set WidgetName_InitPtrTable_0x15_, 0xeb0007
	.set WidgetName_PtrBlock_A_0x01_, 0xeb0009
	.set WidgetName_PtrBlock_A_0x0F_, 0xeb0017
	.set Str_InitializeRoot_0x10_, 0xeb193a
	.set Str_InitializeRoot_0x12_, 0xeb193c
	.set NakaDbg_LowerCaseChars2_0x960_, 0xeb37de
	.set NakaInst_IT_Off_0x08_, 0xeb7690
	.set WidgetStyleDataTable_0x10_, 0xeb7942
	.set WidgetStyleDataTable_0x154_, 0xeb7a86
	.set WidgetStyleDataTable_0x15E_, 0xeb7a90
	.set WidgetStyleDataTable_0x2A8_, 0xeb7bda
	.set WidgetStyleDataTable_0x362_, 0xeb7c94
	.set WidgetStyleDataTable_0x36E_, 0xeb7ca0
	.set WidgetStyleDataTable_0x4FA_, 0xeb7e2c
	.set WidgetStyleDataTable_0x554_, 0xeb7e86
	.set WidgetStyleDataTable_0x55A_, 0xeb7e8c
	.set WidgetStyleDataTable_0x6BA_, 0xeb7fec
	.set WidgetStyleDataTable_0x6DA_, 0xeb800c
	.set WidgetStyleDataTable_0x6FC_, 0xeb802e
	.set WidgetStyleDataTable_0x706_, 0xeb8038
	.set WidgetStyleDataTable_0x710_, 0xeb8042
	.set WidgetStyleDataTable_0x71C_, 0xeb804e
	.set WidgetStyleDataTable_0x728_, 0xeb805a
	.set WidgetStyleDataTable_0x734_, 0xeb8066
	.set StyleSong_MasterTable_0x04_, 0xeba498
	.set StyleSong_MasterTable_0x176A_, 0xebbbfe
	.set StyleGroup_LatinWorld_PairTable_0x2FA_, 0xecfca4
	.set NakaInst_Rock_Pop_0x24_, 0xecfda8
	.set NakaInst_Rock_Pop_0x28_, 0xecfdac
	.set NakaInst_Rock_Pop_0x2C_, 0xecfdb0
	.set NakaInst_Rock_Pop_0x30_, 0xecfdb4
	.set SeqChan_Map_2ch_0x02_, 0xecfdd4
	.set NakaInst_MEMORY_A_ECFDF4_0x0A_, 0xecfdfe
	.set MemScreen_Blank_0x04_, 0xecff6a
	.set NoteStr3_Blank_3_0x04_, 0xed04c4
	.set Str_Attention_EN_0x0C_, 0xed051e
	.set Str_InitSettingWarn_IT_0x19A_, 0xed073e
	.set Str_AreYouSure_IT_0x46_, 0xed07b6
	.set Str_FactoryResetDesc_EN3_0x156_, 0xed0a74
	.set Str_StoreSoundBalance_DE_0x58_, 0xed0b7c
	.set Str_StoreTotalSetting_DE_0x98_, 0xed0d24
	.set Str_StoreTotalSetting_DE_0xCC_, 0xed0d58
	.set Str_StoreTotalSetting_DE_0xDA_, 0xed0d66
	.set Str_StoreTotalSetting_DE_0xFE_, 0xed0d8a
	.set Str_StoreTotalSetting_DE_0x112_, 0xed0d9e
	.set Str_StoreTotalSetting_DE_0x136_, 0xed0dc2
	.set Str_StoreTotalSetting_DE_0x15A_, 0xed0de6
	.set Str_StoreTotalSetting_DE_0x164_, 0xed0df0
	.set Str_StoreTotalSetting_DE_0x16E_, 0xed0dfa
	.set Str_StoreTotalSetting_DE_0x178_, 0xed0e04
	.set Str_StoreTotalSetting_DE_0x188_, 0xed0e14
	.set Str_StoreTotalSetting_DE_0x1AC_, 0xed0e38
	.set Str_StoreTotalSetting_DE_0x1D0_, 0xed0e5c
	.set Str_StoreTotalSetting_DE_0x1F4_, 0xed0e80
	.set Str_StoreTotalSetting_DE_0x216_, 0xed0ea2
	.set Str_StoreTotalSetting_DE_0x238_, 0xed0ec4
	.set Str_StoreTotalSetting_DE_0x246_, 0xed0ed2
	.set Str_StoreTotalSetting_DE_0x258_, 0xed0ee4
	.set Str_StoreTotalSetting_DE_0x25C_, 0xed0ee8
	.set Str_StoreTotalSetting_DE_0x26C_, 0xed0ef8
	.set Str_StoreTotalSetting_DE_0x270_, 0xed0efc
	.set Str_StoreTotalSetting_DE_0x27C_, 0xed0f08
	.set Str_StoreTotalSetting_DE_0x28A_, 0xed0f16
	.set Str_StoreTotalSetting_DE_0x298_, 0xed0f24
	.set Str_StoreTotalSetting_DE_0x2B8_, 0xed0f44
	.set CtrlAssignStr_Off_0x4A_, 0xed1226
	.set CtrlAssignStr_Off_0x58_, 0xed1234
	.set ParamStr02_Vocalist_0x14_, 0xed13f0
	.set ParamStr02_Vocalist_0x20_, 0xed13fc
	.set ParamStr02_Vocalist_0x44_, 0xed1420
	.set ParamStr02_Vocalist_0x52_, 0xed142e
	.set ParamStr02_Vocalist_0x76_, 0xed1452
	.set ParamStr02_Vocalist_0x9A_, 0xed1476
	.set ParamStr02_Vocalist_0x9E_, 0xed147a
	.set ParamStr02_Vocalist_0xA2_, 0xed147e
	.set ParamStr02_Vocalist_0xA6_, 0xed1482
	.set ParamStr02_Vocalist_0xAA_, 0xed1486
	.set ParamStr02_Vocalist_0xAE_, 0xed148a
	.set ParamStr02_Vocalist_0xB2_, 0xed148e
	.set ParamStr02_Vocalist_0xB6_, 0xed1492
	.set ParamStr02_Vocalist_0xBE_, 0xed149a
	.set ParamStr02_Vocalist_0xCC_, 0xed14a8
	.set FadeTimeStr_Off_0x38_, 0xed1582
	.set FadeTimeStr_Off_0x5A_, 0xed15a4
	.set FadeTimeStr_Off_0x5E_, 0xed15a8
	.set FadeTimeStr_Off_0x62_, 0xed15ac
	.set FadeTimeStr_Off_0xA4_, 0xed15ee
	.set FadeTimeStr_Off_0xBA_, 0xed1604
	.set VariationStr_V1_0x04_, 0xed1646
	.set VariationStr_V1_0x3C_, 0xed167e
	.set TransposeNoteStr_C_0x12_, 0xed1726
	.set TransposeNoteStr_C_0x26_, 0xed173a
	.set TransposeNoteStr_C_0x58_, 0xed176c
	.set TransposeNoteStr_C_0x64_, 0xed1778
	.set TransposeNoteStr_C_0x7C_, 0xed1790
	.set TransposeNoteStr_C_0xA0_, 0xed17b4
	.set TransposeNoteStr_C_0xC6_, 0xed17da
	.set TransposeNoteStr_C_0xE4_, 0xed17f8
	.set TransposeNoteStr_C_0x10C_, 0xed1820
	.set TransposeNoteStr_C_0x12A_, 0xed183e
	.set TransposeNoteStr_C_0x148_, 0xed185c
	.set TransposeNoteStr_C_0x16A_, 0xed187e
	.set TransposeNoteStr_C_0x18E_, 0xed18a2
	.set TransposeNoteStr_C_0x19A_, 0xed18ae
	.set TransposeNoteStr_C_0x1AA_, 0xed18be
	.set TransposeNoteStr_C_0x1B2_, 0xed18c6
	.set TransposeNoteStr_C_0x1C6_, 0xed18da
	.set TransposeNoteStr_C_0x1CE_, 0xed18e2
	.set TransposeNoteStr_C_0x1D6_, 0xed18ea
	.set TransposeNoteStr_C_0x1DE_, 0xed18f2
	.set TransposeNoteStr_C_0x1F2_, 0xed1906
	.set TransposeNoteStr_C_0x1FA_, 0xed190e
	.set TransposeNoteStr_C_0x202_, 0xed1916
	.set TransposeNoteStr_C_0x20A_, 0xed191e
	.set TransposeNoteStr_C_0x21E_, 0xed1932
	.set TransposeNoteStr_C_0x40E_, 0xed1b22
	.set TransposeNoteStr_C_0x420_, 0xed1b34
	.set SplitNoteStr_C_0x04_, 0xed1baa
	.set OctaveDigitStr_0B_0x32_, 0xed1c1c
	.set KeyScaleNoteStr_G_0x14_, 0xed1c96
	.set KeyScaleNoteStr_G_0x18_, 0xed1c9a
	.set NakaInst_ExtDevice_Screens_0x2814_, 0xed8fe0
	.set NakaInst_ExtDevice_Screens_0x29E0_, 0xed91ac
	.set NakaInst_ExtDevice_Screens_0x2B0C_, 0xed92d8
	.set NakaInst_ExtDevice_Screens_0x2B26_, 0xed92f2
	.set NakaInst_ExtDevice_Screens_0x2B3E_, 0xed930a
	.set NakaInst_ExtDevice_Screens_0x2B6E_, 0xed933a
	.set NakaInst_ExtDevice_Screens_0x2C68_, 0xed9434
	.set NakaInst_ExtDevice_Screens_0x2D52_, 0xed951e
	.set NakaInst_ExtDevice_Screens_0x2E3C_, 0xed9608
	.set NakaInst_ExtDevice_Screens_0x2E4E_, 0xed961a
	.set NakaInst_ExtDevice_Screens_0x2E60_, 0xed962c
	.set NakaInst_ExtDevice_Screens_0x3452_, 0xed9c1e
	.set NakaInst_ExtDevice_Screens_0x34D2_, 0xed9c9e
	.set SoundParam_EncoderMappingData_0x286_, 0xed9fa4
	.set SoundParam_EncoderMappingData_0x302_, 0xeda020
	.set EffectMode_DispatchTable_0x10_, 0xeda03c
	.set ENCODER_LUT_MODWHEEL_0x3C6_, 0xeda502
	.set ENCODER_LUT_MODWHEEL_0x3FC_, 0xeda538
	.set ENCODER_LUT_MODWHEEL_0x43E_, 0xeda57a
	.set ENCODER_LUT_MODWHEEL_0x48C_, 0xeda5c8
	.set ENCODER_LUT_MODWHEEL_0x49E_, 0xeda5da
	.set ENCODER_LUT_MODWHEEL_0x4A4_, 0xeda5e0
	.set ENCODER_LUT_MODWHEEL_0x4BC_, 0xeda5f8
	.set ENCODER_LUT_MODWHEEL_0x4D4_, 0xeda610
	.set Protocol_values_for_LED_rows_0x10_, 0xeda626
	.set Protocol_values_for_LED_rows_0x16_, 0xeda62c
	.set Protocol_values_for_LED_rows_0x38_, 0xeda64e
	.set Protocol_values_for_LED_rows_0x3E_, 0xeda654
	.set Protocol_values_for_LED_rows_0x46_, 0xeda65c
	.set Protocol_values_for_LED_rows_0x56_, 0xeda66c
	.set SoundProgram_DispatchTable_0x400_, 0xedae64
	.set SoundProgram_DispatchTable_0x800_, 0xedb264
	.set SoundProgram_DispatchTable_0x888_, 0xedb2ec
	.set SoundProgram_DispatchTable_0x890_, 0xedb2f4
	.set SoundProgram_DispatchTable_0x892_, 0xedb2f6
	.set SoundProgram_DispatchTable_0x896_, 0xedb2fa
	.set SoundProgram_DispatchTable_0x8AE_, 0xedb312
	.set SoundProgram_DispatchTable_0x8C0_, 0xedb324
	.set SoundProgram_DispatchTable_0x8D2_, 0xedb336
	.set SoundProgram_DispatchTable_0x8D6_, 0xedb33a
	.set SoundProgram_DispatchTable_0x8DA_, 0xedb33e
	.set SoundProgram_DispatchTable_0x8F4_, 0xedb358
	.set SoundProgram_DispatchTable_0x908_, 0xedb36c
	.set Naka_ToshiParam_Table_0x24_, 0xedb394
	.set Naka_ToshiParam_Table_0x48_, 0xedb3b8
	.set Naka_ToshiParam_Table_0x6C_, 0xedb3dc
	.set Naka_ToshiParam_Table_0x8C_, 0xedb3fc
	.set Naka_ToshiParam_Table_0x6BC_, 0xedba2c
	.set Naka_ToshiParam_Table_0x6C8_, 0xedba38
	.set Naka_ToshiParam_Table_0x6CC_, 0xedba3c
	.set NakaInst_Param_Field02_0x04_, 0xee0016
	.set NakaInst_Param_IdxA0_01_0x12_, 0xee0154
	.set Naka_SubDispatch_A_Table_0x28_, 0xee0180
	.set Naka_SubDispatch_B_Table_0x04_, 0xee019c
	.set Naka_SubDispatch_B_Table_0x08_, 0xee01a0
	.set Naka_MainDispatch_Table_0xDC0_, 0xee10d0
	.set Naka_MainDispatch_Table_0xDDC_, 0xee10ec
	.set Naka_MainDispatch_Table_0xE00_, 0xee1110
	.set Naka_MainDispatch_Table_0xE20_, 0xee1130
	.set Naka_MainDispatch_Table_0xE38_, 0xee1148
	.set Naka_MainDispatch_Table_0xE50_, 0xee1160
	.set Naka_MainDispatch_Table_0xF70_, 0xee1280
	.set Naka_MainDispatch_Table_0x1250_, 0xee1560
	.set NakaInst_SoundConfig_LookupTable_0x10_, 0xee1584
	.set NakaInst_SoundConfig_LookupTable_0x28_, 0xee159c
	.set NakaInst_SoundConfig_LookupTable_0x38_, 0xee15ac
	.set NakaInst_SoundConfig_LookupTable_0x48_, 0xee15bc
	.set NakaInst_SoundConfig_LookupTable_0x58_, 0xee15cc
	.set NakaInst_SoundConfig_LookupTable_0x8A_, 0xee15fe
	.set NakaInst_SoundConfig_LookupTable_0x1786_, 0xee2cfa
	.set NakaInst_SoundConfig_LookupTable_0x17B6_, 0xee2d2a
	.set NakaInst_SoundConfig_LookupTable_0x17D6_, 0xee2d4a
	.set NakaInst_SoundConfig_LookupTable_0x17F6_, 0xee2d6a
	.set SeqChan_CommandDispatch_Table_0x9C_, 0xee2e08
	.set SeqChan_CommandDispatch_Table_0xF4_, 0xee2e60
	.set SeqChan_CommandDispatch_Table_0x14C_, 0xee2eb8
	.set SeqChan_CommandDispatch_Table_0x152_, 0xee2ebe
	.set SeqChan_CommandDispatch_Table_0x1AA_, 0xee2f16
	.set SeqFormat_ReferenceData_0x10_, 0xee2f36
	.set SeqFormat_ReferenceData_0x50_, 0xee2f76
	.set SeqFormat_ReferenceData_0x58_, 0xee2f7e
	.set SeqData_SubDispatch_Table_0x9C_, 0xee3028
	.set SeqData_SubDispatch_Table_0xA0_, 0xee302c
	.set SeqData_SubDispatch_Table_0xAE_, 0xee303a
	.set SeqData_SubDispatch_Table_0xBC_, 0xee3048
	.set MidiPkt_EventType_Table_0x33_, 0xee307f
	.set MidiPkt_EventType_Table_0x300_, 0xee334c
	.set MidiPkt_EventType_Table_0x304_, 0xee3350
	.set MidiPkt_EventType_Table_0x308_, 0xee3354
	.set MidiPkt_EventType_Table_0x30C_, 0xee3358
	.set MidiPkt_EventType_Table_0x312_, 0xee335e
	.set MidiPkt_EventType_Table_0x318_, 0xee3364
	.set MidiPkt_EventType_Table_0x31C_, 0xee3368
	.set MidiPkt_EventType_Table_0x320_, 0xee336c
	.set MidiPkt_EventType_Table_0x324_, 0xee3370
	.set MidiPkt_EventType_Table_0x330_, 0xee337c
	.set MidiPkt_EventType_Table_0x340_, 0xee338c
	.set MidiPkt_EventType_Table_0x344_, 0xee3390
	.set MidiPkt_EventType_Table_0x348_, 0xee3394
	.set MidiPkt_EventType_Table_0x34C_, 0xee3398
	.set MidiPkt_EventType_Table_0x350_, 0xee339c
	.set MidiPkt_EventType_Table_0x354_, 0xee33a0
	.set MidiPkt_EventType_Table_0x358_, 0xee33a4
	.set MidiPkt_EventType_Table_0x360_, 0xee33ac
	.set MidiPkt_EventType_Table_0x3E0_, 0xee342c
	.set MidiPkt_EventType_Table_0x3E8_, 0xee3434
	.set MidiPkt_EventType_Table_0x468_, 0xee34b4
	.set MidiPkt_EventType_Table_0x472_, 0xee34be
	.set MidiPkt_EventType_Table_0x480_, 0xee34cc
	.set MidiPkt_EventType_Table_0x48A_, 0xee34d6
	.set MidiPkt_EventType_Table_0x498_, 0xee34e4
	.set MidiPkt_EventType_Table_0x4A8_, 0xee34f4
	.set MidiPkt_EventType_Table_0x4B8_, 0xee3504
	.set MidiPkt_EventType_Table_0x4C6_, 0xee3512
	.set MidiPkt_EventType_Table_0x4D4_, 0xee3520
	.set MidiPkt_EventType_Table_0x4E4_, 0xee3530
	.set MidiPkt_EventType_Table_0x4EE_, 0xee353a
	.set MidiPkt_EventType_Table_0x4F8_, 0xee3544
	.set MidiPkt_EventType_Table_0x502_, 0xee354e
	.set MidiPkt_EventType_Table_0x50C_, 0xee3558
	.set MidiPkt_EventType_Table_0x516_, 0xee3562
	.set MidiPkt_EventType_Table_0x520_, 0xee356c
	.set MidiPkt_EventType_Table_0x52C_, 0xee3578
	.set MidiPkt_EventType_Table_0x538_, 0xee3584
	.set MidiPkt_EventType_Table_0x548_, 0xee3594
	.set MidiPkt_EventType_Table_0x54E_, 0xee359a
	.set MidiPkt_EventType_Table_0x554_, 0xee35a0
	.set MidiPkt_EventType_Table_0x55A_, 0xee35a6
	.set MidiPkt_EventType_Table_0x560_, 0xee35ac
	.set MidiPkt_EventType_Table_0x566_, 0xee35b2
	.set MidiPkt_EventType_Table_0x56C_, 0xee35b8
	.set MidiPkt_EventType_Table_0x570_, 0xee35bc
	.set MidiPkt_EventType_Table_0x578_, 0xee35c4
	.set MidiPkt_EventType_Table_0x580_, 0xee35cc
	.set MidiPkt_EventType_Table_0x584_, 0xee35d0
	.set MidiPkt_EventType_Table_0x58A_, 0xee35d6
	.set MidiPkt_EventType_Table_0x590_, 0xee35dc
	.set MidiPkt_EventType_Table_0x596_, 0xee35e2
	.set MidiPkt_EventType_Table_0x5A2_, 0xee35ee
	.set MidiPkt_EventType_Table_0x5AE_, 0xee35fa
	.set MidiPkt_EventType_Table_0x5BA_, 0xee3606
	.set MidiPkt_EventType_Table_0x5C6_, 0xee3612
	.set MidiPkt_EventType_Table_0x5D2_, 0xee361e
	.set MidiPkt_EventType_Table_0x5DE_, 0xee362a
	.set MidiPkt_EventType_Table_0x5E8_, 0xee3634
	.set MidiPkt_EventType_Table_0x5F4_, 0xee3640
	.set MidiPkt_EventType_Table_0x600_, 0xee364c
	.set MidiPkt_EventType_Table_0x60A_, 0xee3656
	.set MidiPkt_EventType_Table_0x616_, 0xee3662
	.set MidiPkt_EventType_Table_0x622_, 0xee366e
	.set WidgetParam_Entry_018_0x24_, 0xee493e
	.set WidgetParam_Entry_018_0x26_, 0xee4940
	.set WidgetParam_Entry_018_0x84_, 0xee499e
	.set WidgetParam_Entry_018_0x9A_, 0xee49b4
	.set WidgetParam_Entry_018_0xBE_, 0xee49d8
	.set WidgetParam_Entry_018_0xCE_, 0xee49e8
	.set ToneKit_FrequencyTable_0xB2_, 0xee4ac2
	.set ToneKit_FrequencyTable_0xDA_, 0xee4aea
	.set ToneKit_FrequencyTable_0x35A_, 0xee4d6a
	.set ToneKit_FrequencyTable_0x372_, 0xee4d82
	.set ToneKit_FrequencyTable_0x37E_, 0xee4d8e
	.set ToneKit_FrequencyTable_0x38A_, 0xee4d9a
	.set ToneKit_FrequencyTable_0x396_, 0xee4da6
	.set ToneKit_FrequencyTable_0x39E_, 0xee4dae
	.set ToneKit_FrequencyTable_0x3B6_, 0xee4dc6
	.set ToneKit_FrequencyTable_0x3BE_, 0xee4dce
	.set ToneKit_FrequencyTable_0x3E2_, 0xee4df2
	.set ToneKit_FrequencyTable_0x3F4_, 0xee4e04
	.set ToneKit_FrequencyTable_0x406_, 0xee4e16
	.set ToneKit_FrequencyTable_0x408_, 0xee4e18
	.set WidgetParam_SelfRef_Table_0x04_, 0xee4e20
	.set WidgetParam_SelfRef_Table_0x0A_, 0xee4e26
	.set WidgetParam_SelfRef_Table_0x0E_, 0xee4e2a
	.set WidgetParam_SelfRef_Table_0x3A_, 0xee4e56
	.set WidgetParam_SelfRef_Table_0x66_, 0xee4e82
	.set WidgetParam_SelfRef_Table_0x6A_, 0xee4e86
	.set WidgetParam_SelfRef_Table_0x6E_, 0xee4e8a
	.set WidgetParam_SelfRef_Table_0x9E_, 0xee4eba
	.set WidgetParam_SelfRef_Table_0xCE_, 0xee4eea
	.set WidgetParam_SelfRef_Table_0xD2_, 0xee4eee
	.set WidgetParam_SelfRef_Table_0xD6_, 0xee4ef2
	.set WidgetParam_SelfRef_Table_0xDA_, 0xee4ef6
	.set WidgetParam_SelfRef_Table_0xDE_, 0xee4efa
	.set WidgetParam_SelfRef_Table_0x116_, 0xee4f32
	.set WidgetParam_SelfRef_Table_0x136_, 0xee4f52
	.set WidgetParam_SelfRef_Table_0x14E_, 0xee4f6a
	.set WidgetParam_SelfRef_Table_0x17E_, 0xee4f9a
	.set WidgetParam_SelfRef_Table_0x19E_, 0xee4fba
	.set WidgetParam_SelfRef_Table_0x1A6_, 0xee4fc2
	.set WidgetParam_SelfRef_Table_0x1A8_, 0xee4fc4
	.set ToneKit_ParamBlock_116_0x18_, 0xee5fe0
	.set ToneKit_ParamBlock_116_0x7C_, 0xee6044
	.set ToneKit_VoiceDispatch_Table_0x18C_, 0xee61d4
	.set ToneKit_VoiceDispatch_Table_0x31C_, 0xee6364
	.set ToneKit_VoiceDispatch_Table_0x320_, 0xee6368
	.set ToneKit_VoiceDispatch_Table_0x324_, 0xee636c
	.set ToneKit_VoiceDispatch_Table_0x32A_, 0xee6372
	.set ToneKit_VoiceDispatch_Table_0x332_, 0xee637a
	.set ToneKit_VoiceDispatch_Table_0x33C_, 0xee6384
	.set ToneKit_VoiceDispatch_Table_0x348_, 0xee6390
	.set WidgetParam_Config_058_0x36_, 0xee75f6
	.set Naka_DisplayMode_Table_0x10_, 0xee7786
	.set UIState_DefaultConfig_A_0x04_, 0xee7ca3
	.set UIState_DefaultConfig_B_0x04_, 0xee86b4
	.set UIState_DefaultConfig_C_0x04_, 0xee8c79
	.set SystemConfig_PointerTable_0x56_, 0xee8cd4
	.set SystemConfig_PointerTable_0x76_, 0xee8cf4
	.set AudioInit_VoiceDispatch_Table_0x7C_, 0xee8d74
	.set AudioInit_VoiceDispatch_Table_0xFC_, 0xee8df4
	.set AudioInit_VoiceDispatch_Table_0x11C_, 0xee8e14
	.set AudioInit_VoiceDispatch_Table_0x124_, 0xee8e1c
	.set AudioInit_VoiceDispatch_Table_0x130_, 0xee8e28
	.set AudioInit_VoiceDispatch_Table_0x150_, 0xee8e48
	.set AudioInit_VoiceDispatch_Table_0x15E_, 0xee8e56
	.set AudioInit_VoiceDispatch_Table_0x16A_, 0xee8e62
	.set AudioInit_VoiceDispatch_Table_0x18A_, 0xee8e82
	.set AudioInit_VoiceDispatch_Table_0x1AA_, 0xee8ea2
	.set AudioInit_VoiceDispatch_Table_0x1BE_, 0xee8eb6
	.set CharMap_ValueData_B_0x10_, 0xee8ee8
	.set CharMap_ValueData_B_0x14_, 0xee8eec
	.set CharMap_ValueData_B_0x18_, 0xee8ef0
	.set CharMap_ValueData_B_0x20_, 0xee8ef8
	.set CharMap_ValueData_B_0x26_, 0xee8efe
	.set CharMap_ValueData_B_0x2E_, 0xee8f06
	.set CharMap_ValueData_B_0x4A_, 0xee8f22
	.set CharMap_ValueData_B_0x56_, 0xee8f2e
	.set CharMap_ValueData_B_0x5A_, 0xee8f32
	.set CharMap_ValueData_B_0x5E_, 0xee8f36
	.set CharMap_ValueData_B_0x98_, 0xee8f70
	.set CharMap_ValueData_B_0xA0_, 0xee8f78
	.set CharMap_ValueData_B_0xA8_, 0xee8f80
	.set CharMap_ValueData_B_0xA9_, 0xee8f81
	.set CharMap_ValueData_B_0xC2_, 0xee8f9a
	.set CharMap_ValueData_B_0xCC_, 0xee8fa4
	.set CharMap_ValueData_B_0xD6_, 0xee8fae
	.set CharMap_ValueData_B_0xE8_, 0xee8fc0
	.set CharMap_ValueData_B_0xF6_, 0xee8fce
	.set CharMap_ValueData_B_0x246_, 0xee911e
	.set CharMap_ValueData_B_0x4E6_, 0xee93be
	.set CharMap_ValueData_B_0xA26_, 0xee98fe
	.set CharMap_ValueData_B_0xB76_, 0xee9a4e
	.set CharMap_ValueData_B_0xF66_, 0xee9e3e
	.set CharMap_ValueData_B_0x19E6_, 0xeea8be
	.set CharMap_ValueData_B_0x1F26_, 0xeeadfe
	.set CharMap_ValueData_B_0x1F27_, 0xeeadff
	.set CharMap_ValueData_B_0x1F28_, 0xeeae00
	.set CharMap_ValueData_B_0x1F29_, 0xeeae01
	.set CharMap_ValueData_B_0x1F2A_, 0xeeae02
	.set CharMap_ValueData_B_0x1F2B_, 0xeeae03
	.set CharMap_ValueData_B_0x1F2C_, 0xeeae04
	.set SoundEffect_Dispatch_Table_0x3C_, 0xeeae44
	.set SoundEffect_Dispatch_Table_0x103C_, 0xeebe44
	.set SoundEffect_Dispatch_Table_0x123C_, 0xeec044
	.set SoundEffect_Dispatch_Table_0x1256_, 0xeec05e
	.set SoundEffect_Dispatch_Table_0x1266_, 0xeec06e
	.set SoundEffect_Dispatch_Table_0x1284_, 0xeec08c
	.set SoundEffect_Dispatch_Table_0x1292_, 0xeec09a
	.set SoundEffect_Dispatch_Table_0x129E_, 0xeec0a6
	.set SoundEffect_Dispatch_Table_0x12AA_, 0xeec0b2
	.set SoundEffect_Dispatch_Table_0x12B6_, 0xeec0be
	.set SoundEffect_Dispatch_Table_0x12DA_, 0xeec0e2
	.set SoundEffect_Dispatch_Table_0x12E6_, 0xeec0ee
	.set SoundEffect_Dispatch_Table_0x12F2_, 0xeec0fa
	.set SoundEffect_Dispatch_Table_0x12FE_, 0xeec106
	.set SoundEffect_Dispatch_Table_0x130A_, 0xeec112
	.set SoundEffect_Dispatch_Table_0x1316_, 0xeec11e
	.set SoundEffect_Dispatch_Table_0x1322_, 0xeec12a
	.set SoundEffect_Dispatch_Table_0x132E_, 0xeec136
	.set SoundEffect_Dispatch_Table_0x133A_, 0xeec142
	.set SoundEffect_Dispatch_Table_0x1346_, 0xeec14e
	.set SoundEffect_Dispatch_Table_0x1352_, 0xeec15a
	.set SoundEffect_Dispatch_Table_0x1360_, 0xeec168
	.set SoundEffect_Dispatch_Table_0x136E_, 0xeec176
	.set SoundEffect_Dispatch_Table_0x1380_, 0xeec188
	.set SoundEffect_Dispatch_Table_0x13C0_, 0xeec1c8
	.set SoundEffect_Dispatch_Table_0x13C6_, 0xeec1ce
	.set SoundEffect_Dispatch_Table_0x13CC_, 0xeec1d4
	.set SoundEffect_Dispatch_Table_0x13D6_, 0xeec1de
	.set SoundEffect_Dispatch_Table_0x13E0_, 0xeec1e8
	.set SoundEffect_Dispatch_Table_0x1400_, 0xeec208
	.set SoundEffect_Dispatch_Table_0x1410_, 0xeec218
	.set SoundEffect_Dispatch_Table_0x1420_, 0xeec228
	.set SoundEffect_Dispatch_Table_0x1430_, 0xeec238
	.set SoundEffect_Dispatch_Table_0x1440_, 0xeec248
	.set SoundEffect_Dispatch_Table_0x1450_, 0xeec258
	.set SoundEffect_Dispatch_Table_0x1460_, 0xeec268
	.set CharMap_FullPermutation_0x80_, 0xeed198
	.set CharMap_FullPermutation_0x100_, 0xeed218
	.set CharMap_FullPermutation_0x180_, 0xeed298
	.set CharMap_FullPermutation_0x190_, 0xeed2a8
	.set CharMap_FullPermutation_0x1A1_, 0xeed2b9
	.set CharMap_FullPermutation_0x22E_, 0xeed346
	.set CharMap_FullPermutation_0x2AE_, 0xeed3c6
	.set CharMap_FullPermutation_0x2BA_, 0xeed3d2
	.set CharMap_FullPermutation_0x2D6_, 0xeed3ee
	.set CharMap_FullPermutation_0x323_, 0xeed43b
	.set CharMap_FullPermutation_0x331_, 0xeed449
	.set CharMap_FullPermutation_0x37E_, 0xeed496
	.set CharMap_FullPermutation_0x38C_, 0xeed4a4
	.set CharMap_FullPermutation_0x3A0_, 0xeed4b8
	.set CharMap_FullPermutation_0x3B7_, 0xeed4cf
	.set CharMap_FullPermutation_0x3BD_, 0xeed4d5
	.set CharMap_FullPermutation_0x3E6_, 0xeed4fe
	.set CharMap_FullPermutation_0x3F4_, 0xeed50c
	.set CharMap_FullPermutation_0x408_, 0xeed520
	.set CharMap_FullPermutation_0x423_, 0xeed53b
	.set CharMap_FullPermutation_0x42A_, 0xeed542
	.set CharMap_FullPermutation_0x42E_, 0xeed546
	.set CharMap_FullPermutation_0x432_, 0xeed54a
	.set CharMap_FullPermutation_0x443_, 0xeed55b
	.set CharMap_FullPermutation_0x454_, 0xeed56c
	.set CharMap_FullPermutation_0x475_, 0xeed58d
	.set CharMap_FullPermutation_0x485_, 0xeed59d
	.set CharMap_FullPermutation_0x647_, 0xeed75f
	.set CharMap_FullPermutation_0x653_, 0xeed76b
	.set CharMap_FullPermutation_0x660_, 0xeed778
	.set CharMap_FullPermutation_0x760_, 0xeed878
	.set CharMap_FullPermutation_0x78C_, 0xeed8a4
	.set CharMap_FullPermutation_0x79E_, 0xeed8b6
	.set CharMap_FullPermutation_0x7B0_, 0xeed8c8
	.set Naka_DrawbarReg_Table_0x4DE_, 0xeefa66
	.set CharEncoding_PrintableHi_0x04_, 0xef0004
	.set CharEncoding_PrintableHi_0x07_, 0xef0007
	.set CharEncoding_PrintableHi_0x0A_, 0xef000a
	.set Checksum_ComputeComplement_0x04_, 0xef18eb
	.set TaskSched_ScreenGroupTable_0x3C_, 0xef1933
	.set TaskSched_ScreenGroupTable_0x46_, 0xef193d
	.set TaskSched_InitMsgQueues_0x12_, 0xef1a7e
	.set Show_ScreenGroup_Entry_0x7A_, 0xef1c16
	.set ScoopDisp_BytecodeBlock1_0x32_, 0xef5f20
	.set ScoopDisp_BytecodeBlock1_0x4D_, 0xef5f3b
	.set SoundEvt_LongPacketHandler_0x11_, 0xef60ae
	.set SoundEvt_LongPacketHandler_0x35_, 0xef60d2
	.set SoundEvt_LongPacketHandler_0xA6_, 0xef6143
	.set SoundEvt_LongPacketHandler_0xB7_, 0xef6154
	.set ScoopDisp_HandlerData2_0x6D_, 0xef61c6
	.set ScoopDisp_HandlerData2_0x7E_, 0xef61d7
	.set ScoopDisp_HandlerData2_0x7F_, 0xef61d8
	.set DefaultHandler_Ret_0x01_, 0xef61e9
	.set DefaultHandler_Ret_0x2B_, 0xef6213
	.set DefaultHandler_Ret_0xA6_, 0xef628e
	.set ScoopDisp_FlagSetAndDispatch_0x17_, 0xef62a6
	.set ToneParam_Evt0F_BytecodeHandler_0x17_, 0xef633e
	.set ToneParam_Evt0F_BytecodeHandler_0x8D_, 0xef63b4
	.set UIDisp_DefaultInputHandler_0x20_, 0xef65bc
	.set UIDisp_DefaultInputHandler_0x40_, 0xef65dc
	.set PerfMode_ParamHandler_2_0x1B_, 0xef6678
	.set PerfMode_ParamHandler_3_Entry_0x12_, 0xef6725
	.set PerfMode_ParamHandler_Data_0x12_, 0xef6909
	.set PerfMode_ParamHandler_Data_0x13_, 0xef690a
	.set PerfMode_VolumeParam_Process_0x6F_, 0xef6a94
	.set PerfMode_VolumeParam_Process_0x70_, 0xef6a95
	.set PerfMode_VoiceAddressTable_0x50_, 0xef6c37
	.set PerfMode_Handler_EvtB_0x78_, 0xef75f8
	.set PerfMode_Handler_EvtB_0xC8_, 0xef7648
	.set ScoopDisp_DispatchTable_Extended_0x3E_, 0xef7797
	.set ScoopDisp_DispatchTable_Extended_0x79_, 0xef77d2
	.set Timer_ModeHandler_3_0x3B_, 0xef788b
	.set Timer_ModeHandler_0_0x13_, 0xef789f
	.set Timer_ModeHandler_0_0x53_, 0xef78df
	.set Timer_ModeHandler_0_0x85_, 0xef7911
	.set Timer_ModeHandler_0_0x107_, 0xef7993
	.set Timer_ModeHandler_0_0x189_, 0xef7a15
	.set Timer_ParamLoadAndCompare_0x2D_, 0xef7a49
	.set Timer_ParamLoadAndCompare_0x44_, 0xef7a60
	.set Timer_ParamCompareAlt_0x12_, 0xef7a73
	.set Timer_ParamCompareAlt_0x29_, 0xef7a8a
	.set Timer_ParamCompareAlt_0x2A_, 0xef7a8b
	.set Timer_ParamCompareAlt_0x9A_, 0xef7afb
	.set Timer_ParamCompareAlt_0x141_, 0xef7ba2
	.set Timer_ParamCompareAlt_0x142_, 0xef7ba3
	.set Timer_ParamCompareAlt_0x153_, 0xef7bb4
	.set Timer_ParamCompareAlt_0x231_, 0xef7c92
	.set Timer_ParamCompareAlt_0x232_, 0xef7c93
	.set Timer_ParamCompareAlt_0x249_, 0xef7caa
	.set Timer_ParamCompareAlt_0x258_, 0xef7cb9
	.set Timer_ParamCompareAlt_0x277_, 0xef7cd8
	.set Timer_ParamCompareAlt_0x28A_, 0xef7ceb
	.set Timer_ParamCompareAlt_0x2A7_, 0xef7d08
	.set Timer_ParamCompareAlt_0x2AF_, 0xef7d10
	.set Timer_ParamCompareAlt_0x2D7_, 0xef7d38
	.set ToneParam_ModeGuardEntry_0x39_, 0xef7d72
	.set ToneParam_ModeGuardEntry_0x6D_, 0xef7da6
	.set MemConfig_Handler_5_0x3F_, 0xef7df4
	.set MemConfig_Handler_5_0x83_, 0xef7e38
	.set MemConfig_Handler_5_0x8F_, 0xef7e44
	.set MemConfig_Handler_5_0xCC_, 0xef7e81
	.set MemConfig_Handler_5_0xE4_, 0xef7e99
	.set MemConfig_Handler_5_0xEE_, 0xef7ea3
	.set MemConfig_Handler_5_0x11F_, 0xef7ed4
	.set MemConfig_Handler_5_0x191_, 0xef7f46
	.set MemConfig_Handler_5_0x197_, 0xef7f4c
	.set MemConfig_Handler_5_0x198_, 0xef7f4d
	.set MemConfig_Handler_5_0x1BF_, 0xef7f74
	.set MemConfig_Handler_5_0x1DC_, 0xef7f91
	.set MemConfig_Handler_5_0x1FE_, 0xef7fb3
	.set MemConfig_Handler_5_0x216_, 0xef7fcb
	.set MemConfig_Handler_5_0x23D_, 0xef7ff2
	.set MemConfig_Handler_5_0x286_, 0xef803b
	.set MemConfig_Handler_5_0x2AD_, 0xef8062
	.set MemConfig_Handler_5_0x2E6_, 0xef809b
	.set MemConfig_Handler_5_0x2F0_, 0xef80a5
	.set ToneParam_Evt09_BytecodeHandler_0x06_, 0xef80b5
	.set ToneParam_Evt09_BytecodeHandler_0x36_, 0xef80e5
	.set ToneParam_Evt09_BytecodeHandler_0xBB_, 0xef816a
	.set ToneParam_Evt09_BytecodeHandler_0xCF_, 0xef817e
	.set ToneParam_HandlerTable_BC_0x10_, 0xef818f
	.set ToneParam_HandlerTable_BC_0x18_, 0xef8197
	.set ToneParam_HandlerTable_BC_0x82_, 0xef8201
	.set ToneParam_HandlerTable_BC_0x9E_, 0xef821d
	.set ToneParam_HandlerTable_BC_0x9F_, 0xef821e
	.set ToneParam_HandlerTable_BC_0xD3_, 0xef8252
	.set ToneParam_HandlerTable_BC_0xD4_, 0xef8253
	.set ToneParam_HandlerTable_BC_0x120_, 0xef829f
	.set ToneParam_HandlerTable_BC_0x145_, 0xef82c4
	.set ToneParam_HandlerTable_BC_0x148_, 0xef82c7
	.set ToneParam_HandlerTable_BC_0x187_, 0xef8306
	.set ToneParam_HandlerTable_BC_0x1A1_, 0xef8320
	.set ToneParam_HandlerTable_BC_0x1A2_, 0xef8321
	.set ToneParam_HandlerTable_BC_0x1C4_, 0xef8343
	.set ToneParam_HandlerTable_BC_0x1CB_, 0xef834a
	.set ToneParam_HandlerTable_BC_0x210_, 0xef838f
	.set ToneParam_HandlerTable_BC_0x268_, 0xef83e7
	.set ToneParam_HandlerTable_BC_0x269_, 0xef83e8
	.set ToneParam_HandlerTable_BC_0x2CC_, 0xef844b
	.set ToneParam_HandlerTable_BC_0x2D4_, 0xef8453
	.set ToneParam_HandlerTable_BC_0x2EB_, 0xef846a
	.set ToneParam_HandlerTable_BC_0x2F8_, 0xef8477
	.set ToneParam_HandlerTable_BC_0x357_, 0xef84d6
	.set ToneParam_HandlerTable_BC_0x364_, 0xef84e3
	.set ToneParam_HandlerTable_BC_0x36A_, 0xef84e9
	.set ToneParam_HandlerTable_BC_0x3B8_, 0xef8537
	.set ToneParam_HandlerTable_BC_0x41C_, 0xef859b
	.set ToneParam_HandlerTable_BC_0x4DC_, 0xef865b
	.set ToneParam_HandlerTable_BC_0x4F5_, 0xef8674
	.set ToneParam_HandlerTable_BC_0x532_, 0xef86b1
	.set ToneParam_HandlerTable_BC_0x567_, 0xef86e6
	.set ToneParam_HandlerTable_BC_0x57C_, 0xef86fb
	.set ToneParam_HandlerTable_BC_0x5A6_, 0xef8725
	.set ToneParam_HandlerTable_BC_0x5C3_, 0xef8742
	.set DisplayMode_Handler_3_0x3A_, 0xef8835
	.set DisplayMode_Handler_3_0x3F_, 0xef883a
	.set DisplayMode_Handler_3_0x5F_, 0xef885a
	.set DisplayMode_Handler_3_0x99_, 0xef8894
	.set DisplayMode_Handler_3_0x9D_, 0xef8898
	.set DisplayMode_Handler_3_0x168_, 0xef8963
	.set DisplayMode_Handler_3_0x169_, 0xef8964
	.set DisplayMode_Handler_3_0x1E5_, 0xef89e0
	.set DisplayMode_Handler_3_0x26B_, 0xef8a66
	.set DisplayMode_Handler_3_0x26C_, 0xef8a67
	.set DisplayMode_Handler_3_0x2E9_, 0xef8ae4
	.set DisplayMode_Handler_3_0x307_, 0xef8b02
	.set DisplayMode_Handler_3_0x308_, 0xef8b03
	.set DisplayMode_Handler_3_0x30C_, 0xef8b07
	.set DisplayMode_Handler_3_0x316_, 0xef8b11
	.set DisplayMode_Handler_3_0x338_, 0xef8b33
	.set DisplayMode_Handler_3_0x384_, 0xef8b7f
	.set DisplayMode_Handler_3_0x385_, 0xef8b80
	.set DisplayMode_Handler_3_0x38F_, 0xef8b8a
	.set DisplayMode_Handler_3_0x399_, 0xef8b94
	.set DisplayMode_Handler_3_0x421_, 0xef8c1c
	.set DisplayMode_Handler_3_0x435_, 0xef8c30
	.set DisplayMode_Handler_3_0x461_, 0xef8c5c
	.set DisplayMode_Handler_3_0x462_, 0xef8c5d
	.set DisplayMode_Handler_3_0x48E_, 0xef8c89
	.set DisplayMode_Handler_3_0x48F_, 0xef8c8a
	.set DisplayMode_Handler_3_0x4AC_, 0xef8ca7
	.set DisplayMode_Handler_3_0x4C9_, 0xef8cc4
	.set DisplayMode_Handler_3_0x52C_, 0xef8d27
	.set DisplayMode_Handler_3_0x55E_, 0xef8d59
	.set DisplayMode_Handler_3_0x5A1_, 0xef8d9c
	.set DisplayMode_Handler_3_0x5AF_, 0xef8daa
	.set DisplayMode_Handler_3_0x5F2_, 0xef8ded
	.set DisplayMode_Handler_3_0x612_, 0xef8e0d
	.set DisplayMode_Handler_3_0x65A_, 0xef8e55
	.set DisplayMode_Handler_3_0x6A1_, 0xef8e9c
	.set DisplayMode_Handler_3_0x6DF_, 0xef8eda
	.set DisplayMode_Handler_3_0x775_, 0xef8f70
	.set DMA_ChannelHandler_1_0x1E_, 0xef8fc0
	.set DMA_ChannelHandler_2_0x19_, 0xef8fda
	.set VoiceSlot_TableSetup_0x0F_, 0xef903d
	.set VoiceSlot_TableSetup_0x66_, 0xef9094
	.set VoiceSlot_TableSetup_0x106_, 0xef9134
	.set VoiceSlot_TableSetup_0x107_, 0xef9135
	.set VoiceSlot_TableSetup_0x127_, 0xef9155
	.set VoiceSlot_TableSetup_0x12C_, 0xef915a
	.set VoiceSlot_TableSetup_0x1F2_, 0xef9220
	.set VoiceSlot_TableSetup_0x2DE_, 0xef930c
	.set VoiceSlot_TableSetup_0x2E0_, 0xef930e
	.set VoiceSlot_TableSetup_0x3FD_, 0xef942b
	.set VoiceSlot_TableSetup_0x40E_, 0xef943c
	.set VoiceSlot_TableSetup_0x40F_, 0xef943d
	.set VoiceSlot_TableSetup_0x4A7_, 0xef94d5
	.set VoiceSlot_TableSetup_0x514_, 0xef9542
	.set VoiceSlot_TableSetup_0x525_, 0xef9553
	.set VoiceSlot_TableSetup_0x538_, 0xef9566
	.set VoiceSlot_TableSetup_0x56D_, 0xef959b
	.set VoiceCtrl_BytecodeHandler_0x61_, 0xef972c
	.set VoiceCtrl_BytecodeHandler_0x80_, 0xef974b
	.set VoiceCtrl_BytecodeHandler_0x9C_, 0xef9767
	.set VoiceCtrl_BytecodeHandler_0xB9_, 0xef9784
	.set VoiceCtrl_ParamSetupBytecode_0xF1_, 0xef98d1
	.set VoiceCtrl_ParamSetupBytecode_0xF2_, 0xef98d2
	.set VoiceCtrl_ParamSetupBytecode_0x19C_, 0xef997c
	.set VoiceCtrl_ParamSetupBytecode_0x1A2_, 0xef9982
	.set VoiceCtrl_ParamSetupBytecode_0x1C4_, 0xef99a4
	.set VoiceCtrl_ParamSetupBytecode_0x1CA_, 0xef99aa
	.set VoiceCtrl_ParamSetupBytecode_0x1CF_, 0xef99af
	.set VoiceCtrl_ParamSetupBytecode_0x1E4_, 0xef99c4
	.set VoiceCtrl_ParamSetupBytecode_0x1E5_, 0xef99c5
	.set VoiceCtrl_ParamSetupBytecode_0x1F7_, 0xef99d7
	.set VoiceCtrl_ParamSetupBytecode_0x20B_, 0xef99eb
	.set VoiceCtrl_ParamSetupBytecode_0x21F_, 0xef99ff
	.set VoiceCtrl_ParamSetupBytecode_0x256_, 0xef9a36
	.set VoiceCtrl_ParamSetupBytecode_0x25E_, 0xef9a3e
	.set VoiceCtrl_ParamSetupBytecode_0x2A6_, 0xef9a86
	.set VoiceCtrl_ParamSetupBytecode_0x2B6_, 0xef9a96
	.set VoiceCtrl_ParamSetupBytecode_0x303_, 0xef9ae3
	.set VoiceCtrl_ParamSetupBytecode_0x399_, 0xef9b79
	.set VoiceCtrl_ParamSetupBytecode_0x43B_, 0xef9c1b
	.set VoiceCtrl_ParamSetupBytecode_0x4DD_, 0xef9cbd
	.set VoiceCtrl_ParamSetupBytecode_0x4DE_, 0xef9cbe
	.set VoiceCtrl_ParamSetupBytecode_0x55B_, 0xef9d3b
	.set VoiceCtrl_ParamSetupBytecode_0x560_, 0xef9d40
	.set VoiceCtrl_ParamSetupBytecode_0x56C_, 0xef9d4c
	.set VoiceCtrl_ParamSetupBytecode_0x578_, 0xef9d58
	.set VoiceCtrl_ParamSetupBytecode_0x5B8_, 0xef9d98
	.set VoiceCtrl_ParamSetupBytecode_0x5B9_, 0xef9d99
	.set VoiceCtrl_ParamSetupBytecode_0x5E0_, 0xef9dc0
	.set SerialPort_ModeHandler_0_0x05_, 0xef9e08
	.set SerialPort_ModeHandler_0_0x6B_, 0xef9e6e
	.set SerialPort_ModeHandler_0_0x70_, 0xef9e73
	.set SerialPort_ModeHandler_0_0x71_, 0xef9e74
	.set SerialPort_ModeHandler_0_0xE4_, 0xef9ee7
	.set SerialPort_ModeHandler_0_0xE9_, 0xef9eec
	.set SerialPort_ModeHandler_0_0xEA_, 0xef9eed
	.set SerialPort_ModeHandler_0_0x113_, 0xef9f16
	.set SerialPort_ModeHandler_0_0x19D_, 0xef9fa0
	.set ScoopParam_ValueTable_0x1C_, 0xef9fc9
	.set ScoopParam_ValueTable_0x29_, 0xef9fd6
	.set ScoopParam_ValueTable_0x4E_, 0xef9ffb
	.set ScoopParam_ValueTable_0x84_, 0xefa031
	.set ScoopParam_ValueTable_0x186_, 0xefa133
	.set ScoopParam_ValueTable_0x1DD_, 0xefa18a
	.set Interrupt_FlagSetBytecode_0x13_, 0xefa42d
	.set PortConfig_SetupBytecode_0x34_, 0xefa4ec
	.set PortConfig_Handler_0_0xBB_, 0xefa620
	.set PortConfig_Handler_0_0xC0_, 0xefa625
	.set PortConfig_Handler_0_0xD7_, 0xefa63c
	.set PortConfig_Handler_0_0x10A_, 0xefa66f
	.set PortConfig_Handler_0_0x16E_, 0xefa6d3
	.set PortConfig_DataTable_A_0x51_, 0xefa74f
	.set PortConfig_DataTable_B_0x20_, 0xefa77f
	.set PortConfig_DataTable_B_0x44_, 0xefa7a3
	.set ClockConfig_Handler_0_0x9F_, 0xefa85d
	.set ClockConfig_Handler_0_0xA5_, 0xefa863
	.set ClockConfig_Handler_0_0xAB_, 0xefa869
	.set ClockConfig_Handler_0_0x110_, 0xefa8ce
	.set ClockConfig_Handler_0_0x227_, 0xefa9e5
	.set ClockConfig_Handler_0_0x228_, 0xefa9e6
	.set SysEx_BytecodeDispatcher_0xDB_, 0xefabb6
	.set SysEx_BytecodeDispatcher_0x108_, 0xefabe3
	.set MemoryConfig_Handler_Table_0x18_, 0xefabfc
	.set MemoryConfig_Handler_Table_0x67_, 0xefac4b
	.set MemoryConfig_Handler_Table_0x88_, 0xefac6c
	.set MemoryConfig_Handler_Table_0xB2_, 0xefac96
	.set MemConfig_Handler_0_0x24_, 0xefadb8
	.set MemConfig_Handler_0_0x63_, 0xefadf7
	.set MemConfig_Handler_1_0x14_, 0xefae0c
	.set MemConfig_Handler_1_0x57_, 0xefae4f
	.set MemConfig_Handler_1_0x8A_, 0xefae82
	.set MemConfig_Handler_1_0x8B_, 0xefae83
	.set MemConfig_Handler_1_0xF8_, 0xefaef0
	.set MemConfig_Handler_1_0x13D_, 0xefaf35
	.set MemConfig_Handler_1_0x13E_, 0xefaf36
	.set MemConfig_Handler_1_0x1C6_, 0xefafbe
	.set MemConfig_Handler_1_0x1EF_, 0xefafe7
	.set MemConfig_Handler_1_0x256_, 0xefb04e
	.set MemConfig_Handler_1_0x295_, 0xefb08d
	.set MemConfig_Handler_3_0x1F_, 0xefb0f2
	.set MemConfig_Handler_3_0x42_, 0xefb115
	.set MemConfig_Handler_3_0x8E_, 0xefb161
	.set MemConfig_Handler_3_0xAB_, 0xefb17e
	.set MemConfig_Handler_3_0xAC_, 0xefb17f
	.set SndDispatch_Handler_4_0x25_, 0xefb2f0
	.set SndDispatch_ProcessCommand_0x0F_, 0xefb334
	.set SndDispatch_ProcessCommand_0xA4_, 0xefb3c9
	.set SndDispatch_ProcessCommand_0xA5_, 0xefb3ca
	.set SndDispatch_ProcessCommand_0xF8_, 0xefb41d
	.set SndDispatch_ProcessCommand_0xF9_, 0xefb41e
	.set SndDispatch_ProcessCommand_0x143_, 0xefb468
	.set SndDispatch_ProcessCommand_0x159_, 0xefb47e
	.set SndDispatch_ProcessCommand_0x265_, 0xefb58a
	.set SndDispatch_ProcessCommand_0x266_, 0xefb58b
	.set SndDispatch_ProcessCommand_0x278_, 0xefb59d
	.set SndDispatch_ProcessCommand_0x28B_, 0xefb5b0
	.set SndDispatch_ProcessCommand_0x2A4_, 0xefb5c9
	.set SndDispatch_ProcessCommand_0x2C7_, 0xefb5ec
	.set MemConfig_Handler_4_0x2E_, 0xefb63c
	.set MemConfig_Handler_4_0x2F_, 0xefb63d
	.set MemConfig_Handler_4_0x7C_, 0xefb68a
	.set MemConfig_Handler_4_0x94_, 0xefb6a2
	.set MemConfig_Handler_4_0x95_, 0xefb6a3
	.set MemConfig_Handler_4_0x134_, 0xefb742
	.set MemConfig_Handler_4_0x158_, 0xefb766
	.set MemConfig_Handler_4_0x15A_, 0xefb768
	.set MemConfig_Handler_4_0x15B_, 0xefb769
	.set MemConfig_Handler_4_0x1BA_, 0xefb7c8
	.set SystemInit_Handler_Table_0x18_, 0xefb7f3
	.set SystemInit_Handler_Table_0x43_, 0xefb81e
	.set SystemInit_StepHandler_0_0x09_, 0xefb87e
	.set SystemInit_StepHandler_0_0x19_, 0xefb88e
	.set SystemInit_StepHandler_0_0x4B_, 0xefb8c0
	.set SystemInit_StepHandler_0_0x5E_, 0xefb8d3
	.set SystemInit_StepHandler_0_0x7A_, 0xefb8ef
	.set SystemInit_StepHandler_0_0xBD_, 0xefb932
	.set SysInit_BytecodeBlock_0x06_, 0xefb950
	.set SysInit_BytecodeBlock_0x0C_, 0xefb956
	.set SysInit_BytecodeBlock_0x2F_, 0xefb979
	.set SysInit_BytecodeBlock_0x68_, 0xefb9b2
	.set SysInit_BytecodeBlock_0xA7_, 0xefb9f1
	.set SysInit_BytecodeBlock_0xC9_, 0xefba13
	.set SysInit_BytecodeBlock_0xE8_, 0xefba32
	.set SysInit_BytecodeBlock_0xFB_, 0xefba45
	.set SysInit_BytecodeBlock_0xFF_, 0xefba49
	.set SysInit_BytecodeBlock_0x11C_, 0xefba66
	.set SysInit_BytecodeBlock_0x154_, 0xefba9e
	.set SysInit_BytecodeBlock_0x155_, 0xefba9f
	.set SysInit_BytecodeBlock_0x179_, 0xefbac3
	.set SysInit_BytecodeBlock_0x17A_, 0xefbac4
	.set SysInit_BytecodeBlock_0x1A0_, 0xefbaea
	.set SysInit_BytecodeBlock_0x1A1_, 0xefbaeb
	.set SysInit_BytecodeBlock_0x1E7_, 0xefbb31
	.set SysInit_BytecodeBlock_0x255_, 0xefbb9f
	.set SysInit_BytecodeBlock_0x28C_, 0xefbbd6
	.set SysInit_BytecodeBlock_0x2A1_, 0xefbbeb
	.set SysInit_BytecodeBlock_0x2AB_, 0xefbbf5
	.set SysInit_BytecodeBlock_0x392_, 0xefbcdc
	.set SysInit_BytecodeBlock_0x3DA_, 0xefbd24
	.set SysInit_BytecodeBlock_0x3DB_, 0xefbd25
	.set SysInit_BytecodeBlock_0x413_, 0xefbd5d
	.set SysInit_BytecodeBlock_0x42E_, 0xefbd78
	.set SysInit_BytecodeBlock_0x439_, 0xefbd83
	.set SysInit_BytecodeBlock_0x43A_, 0xefbd84
	.set SysInit_BytecodeBlock_0x470_, 0xefbdba
	.set SysInit_BytecodeBlock_0x485_, 0xefbdcf
	.set SysInit_BytecodeBlock_0x486_, 0xefbdd0
	.set SysInit_BytecodeBlock_0x499_, 0xefbde3
	.set SysInit_BytecodeBlock_0x4AF_, 0xefbdf9
	.set SysInit_BytecodeBlock_0x4DE_, 0xefbe28
	.set SysInit_BytecodeBlock_0x691_, 0xefbfdb
	.set VoiceSlot_RetZ_0x39_, 0xefc0ff
	.set VoiceSlot_RetZ_0x58_, 0xefc11e
	.set VoiceSlot_RetZ_0xBF_, 0xefc185
	.set VoiceSlot_RetZ_0xF8_, 0xefc1be
	.set VoiceSlot_CompareAndBranch_0x07_, 0xefc1fa
	.set VoiceSlot_FinalRetZ_0x11_, 0xefc42a
	.set VoiceSlot_FinalRetZ_0x1E_, 0xefc437
	.set VoiceSlot_FinalRetZ_0x5D_, 0xefc476
	.set VoiceSlot_FinalRetZ_0x84_, 0xefc49d
	.set VoiceSlot_FinalRetZ_0xB8_, 0xefc4d1
	.set VoiceSlot_FinalRetZ_0x1A5_, 0xefc5be
	.set VoiceSlot_FinalRetZ_0x1B2_, 0xefc5cb
	.set VoiceSlot_FinalRetZ_0x286_, 0xefc69f
	.set VoiceSlot_IndexDone_0x0A_, 0xefc6e6
	.set VoiceSlot_IndexDone_0x72_, 0xefc74e
	.set VoiceSlot_IndexDone_0x9F_, 0xefc77b
	.set VoiceSlot_IndexDone_0xA3_, 0xefc77f
	.set VoiceSlot_StatusRet_0x60_, 0xefc812
	.set VoiceSlot_StatusRet_0xBE_, 0xefc870
	.set VoiceSlot_StatusRet_0xE3_, 0xefc895
	.set VoiceSlot_StatusRet_0x1C5_, 0xefc977
	.set VoiceSlot_StatusRet_0x371_, 0xefcb23
	.set VoiceSlot_StatusRet_0x5B7_, 0xefcd69
	.set VoiceSlot_StatusRet_0x62A_, 0xefcddc
	.set VoiceSlot_StatusRet_0x7D4_, 0xefcf86
	.set VoiceSlot_StatusRet_0x8A0_, 0xefd052
	.set VoiceSlot_StatusRet_0x8A1_, 0xefd053
	.set VoiceSlot_StatusRet_0x8AA_, 0xefd05c
	.set VoiceState_SaveAndRestore_0x09_, 0xefd097
	.set VoiceState_SaveAndRestore_0x19_, 0xefd0a7
	.set VoiceState_SaveAndRestore_0x1D_, 0xefd0ab
	.set VoiceState_DataBlock2_0x55_, 0xefd1cf
	.set VoiceState_DataBlock2_0x78_, 0xefd1f2
	.set VoiceState_DataBlock2_0x7D_, 0xefd1f7
	.set VoiceState_DataBlock2_0xAB_, 0xefd225
	.set VoiceState_DataBlock2_0xAD_, 0xefd227
	.set VoiceState_DataBlock2_0x10B_, 0xefd285
	.set VoiceState_DataBlock2_0x10C_, 0xefd286
	.set VoiceState_DataBlock2_0x173_, 0xefd2ed
	.set VoiceState_DataBlock2_0x183_, 0xefd2fd
	.set VoiceState_DataBlock2_0x184_, 0xefd2fe
	.set VoiceState_DataBlock2_0x1A6_, 0xefd320
	.set VoiceState_DataBlock2_0x1CB_, 0xefd345
	.set VoiceState_DataBlock2_0x1D8_, 0xefd352
	.set VoiceState_DataBlock2_0x1EB_, 0xefd365
	.set VoiceState_DataBlock2_0x1EC_, 0xefd366
	.set VoiceState_DataBlock2_0x20B_, 0xefd385
	.set VoiceState_DataBlock2_0x238_, 0xefd3b2
	.set VoiceState_DataBlock2_0x239_, 0xefd3b3
	.set VoiceState_DataBlock2_0x270_, 0xefd3ea
	.set VoiceState_DataBlock2_0x2C4_, 0xefd43e
	.set VoiceState_DataBlock2_0x2C5_, 0xefd43f
	.set VoiceState_DataBlock2_0x330_, 0xefd4aa
	.set VoiceState_DataBlock2_0x391_, 0xefd50b
	.set VoiceState_DataBlock2_0x3EE_, 0xefd568
	.set VoiceState_DataBlock2_0x411_, 0xefd58b
	.set VoiceState_DataBlock2_0x471_, 0xefd5eb
	.set VoiceState_DataBlock2_0x472_, 0xefd5ec
	.set VoiceState_DataBlock2_0x48E_, 0xefd608
	.set VoiceState_DataBlock2_0x51E_, 0xefd698
	.set VoiceState_DataBlock2_0x534_, 0xefd6ae
	.set VoiceState_DataBlock2_0x540_, 0xefd6ba
	.set VoiceState_DataBlock2_0x541_, 0xefd6bb
	.set VoiceState_DataBlock2_0x561_, 0xefd6db
	.set VoiceState_DataBlock2_0x563_, 0xefd6dd
	.set VoiceState_DataBlock2_0x5A5_, 0xefd71f
	.set VoiceState_DataBlock2_0x5F1_, 0xefd76b
	.set VoiceState_DataBlock2_0x5F2_, 0xefd76c
	.set VoiceState_DataBlock2_0x607_, 0xefd781
	.set VoiceState_DataBlock2_0x640_, 0xefd7ba
	.set VoiceState_DataBlock2_0x65A_, 0xefd7d4
	.set VoiceState_DataBlock2_0x6F3_, 0xefd86d
	.set VoiceState_DataBlock2_0x733_, 0xefd8ad
	.set VoiceState_DataBlock2_0x734_, 0xefd8ae
	.set VoiceState_DataBlock2_0x7A8_, 0xefd922
	.set VoiceState_DataBlock2_0x7AE_, 0xefd928
	.set VoiceState_DataBlock2_0x7F8_, 0xefd972
	.set VoiceState_DataBlock2_0x7F9_, 0xefd973
	.set VoiceState_DataBlock2_0x841_, 0xefd9bb
	.set SubCPU_ToneParamDisplay_0x4E_, 0xefda0a
	.set SubCPU_ToneParamDisplay_0x9F_, 0xefda5b
	.set SubCPU_ToneParamDisplay_0xE3_, 0xefda9f
	.set SubCPU_ToneParamDisplay_0x137_, 0xefdaf3
	.set SubCPU_ToneDispatch_0x50_, 0xefdb90
	.set SubCPU_ToneClearRegion_0x5E_, 0xefdca1
	.set SubCPU_ToneClearRegion_0x62_, 0xefdca5
	.set SubCPU_ToneParamRet_0x80_, 0xefdd41
	.set SubCPU_ToneParamRet_0x2CC_, 0xefdf8d
	.set SubCPU_ToneParamRet_0x315_, 0xefdfd6
	.set SubCPU_ToneParamRet_0x320_, 0xefdfe1
	.set SubCPU_ToneParamRet_0x34E_, 0xefe00f
	.set SubCPU_ToneParamRet_0x353_, 0xefe014
	.set SubCPU_ToneParamRet_0x354_, 0xefe015
	.set SubCPU_ToneParamRet_0x356_, 0xefe017
	.set SubCPU_ToneParamRet_0x38A_, 0xefe04b
	.set SubCPU_ToneParamRet_0x3DE_, 0xefe09f
	.set SubCPU_ToneParamRet_0x461_, 0xefe122
	.set SubCPU_ToneParamRet_0x4AD_, 0xefe16e
	.set SubCPU_ToneParamRet_0x4BC_, 0xefe17d
	.set SubCPU_ToneParamRet_0x4BD_, 0xefe17e
	.set SubCPU_ToneParamRet_0x4F3_, 0xefe1b4
	.set SubCPU_ToneParamRet_0x5E9_, 0xefe2aa
	.set SubCPU_ToneParamRet_0x777_, 0xefe438
	.set SubCPU_ToneParamRet_0x7B8_, 0xefe479
	.set SubCPU_ToneParamRet_0x7C1_, 0xefe482
	.set SubCPU_ToneParamRet_0x7ED_, 0xefe4ae
	.set SubCPU_ToneParamRet_0x7FF_, 0xefe4c0
	.set SubCPU_ToneParamRet_0x840_, 0xefe501
	.set SubCPU_ToneParamRet_0x848_, 0xefe509
	.set SubCPU_ToneParamRet_0x85D_, 0xefe51e
	.set SubCPU_ToneParamRet_0x88B_, 0xefe54c
	.set SubCPU_ToneParamRet_0x8B4_, 0xefe575
	.set SubCPU_ToneParamRet_0x8C5_, 0xefe586
	.set SubCPU_ToneParamRet_0x94F_, 0xefe610
	.set SubCPU_ToneParamRet_0x97C_, 0xefe63d
	.set SubCPU_ToneParamRet_0x980_, 0xefe641
	.set SubCPU_ToneParamRet_0x98D_, 0xefe64e
	.set SubCPU_ToneParamRet_0x9AF_, 0xefe670
	.set SubCPU_ToneParamRet_0x9D1_, 0xefe692
	.set SubCPU_ToneParamRet_0xA1F_, 0xefe6e0
	.set SubCPU_ToneParamRet_0xAA3_, 0xefe764
	.set OscScope_Handler_7_0x05_, 0xefe7bf
	.set OscScope_DrawWaveform_0x04_, 0xefe80c
	.set OscScope_RefreshLoop_0x3F_, 0xefe8c7
	.set OscScope_RenderBlock_0x0E_, 0xefe92f
	.set OscScope_RenderBlock_0x20_, 0xefe941
	.set OscScope_RenderBlock_0x21_, 0xefe942
	.set OscScope_RenderBlock_0x2E_, 0xefe94f
	.set OscScope_RenderBlock_0x3F_, 0xefe960
	.set OscScope_RenderBlock_0x50_, 0xefe971
	.set OscScope_RenderBlock_0x61_, 0xefe982
	.set OscScope_FinalizeRender_0x79_, 0xefea02
	.set OscScope_FinalizeRender_0xCB_, 0xefea54
	.set DisplayStr_BytecodeBlock_A_0x52_, 0xefeb58
	.set DisplayStr_BytecodeBlock_A_0x53_, 0xefeb59
	.set DisplayStr_BytecodeBlock_A_0xCD_, 0xefebd3
	.set DisplayStr_BytecodeBlock_A_0x11F_, 0xefec25
	.set DisplayStr_BytecodeBlock_A_0x120_, 0xefec26
	.set DisplayStr_BytecodeBlock_A_0x198_, 0xefec9e
	.set DisplayStr_BytecodeBlock_A_0x1A4_, 0xefecaa
	.set DisplayStr_BytecodeBlock_B_0x04_, 0xefed16
	.set DisplayStr_BytecodeBlock_B_0x39_, 0xefed4b
	.set DisplayStr_BytecodeBlock_B_0x3D_, 0xefed4f
	.set DisplayStr_BytecodeBlock_B_0x5C_, 0xefed6e
	.set DisplayStr_BytecodeBlock_B_0x63_, 0xefed75
	.set DisplayStr_BytecodeBlock_B_0x8C_, 0xefed9e
	.set DisplayStr_RhythmLabel_0x01_, 0xefedc2
	.set DisplayStr_RhythmLabel_0x0A_, 0xefedcb
	.set DisplayStr_RhythmLabel_0x42_, 0xefee03
	.set DisplayStr_RhythmLabel_0x4C_, 0xefee0d
	.set DisplayStr_RhythmLabel_0x64_, 0xefee25
	.set DisplayStr_RhythmLabel_0x86_, 0xefee47
	.set DisplayStr_RhythmLabel_0x92_, 0xefee53
	.set DisplayStr_BytecodeBlock_C_0x24_, 0xefee95
	.set DisplayStr_BytecodeBlock_C_0x5E_, 0xefeecf
	.set DisplayStr_BytecodeBlock_C_0x77_, 0xefeee8
	.set DisplayStr_BytecodeBlock_C_0x90_, 0xefef01
	.set DisplayStr_TempoString_0x19_, 0xefef53
	.set DisplayStr_TempoString_0x32_, 0xefef6c
	.set DisplayStr_TempoString_0x36_, 0xefef70
	.set DisplayStr_TempoString_0x56_, 0xefef90
	.set DisplayStr_TempoString_0x6F_, 0xefefa9
	.set DisplayStr_TempoString_0x74_, 0xefefae
	.set DisplayStr_TempoString_0x9F_, 0xefefd9
	.set DisplayStr_BytecodeBlock_E_0x01_, 0xeff078
	.set DisplayStr_StyleSectionNames_0x69_, 0xeff10b
	.set Display_BytecodeBlock_F_0x04_, 0xeff148
	.set Display_BytecodeBlock_F_0x27_, 0xeff16b
	.set Display_BytecodeBlock_F_0x59_, 0xeff19d
	.set Display_BytecodeBlock_F_0xF3_, 0xeff237
	.set Display_BytecodeBlock_F_0xF4_, 0xeff238
	.set Display_BytecodeBlock_F_0x104_, 0xeff248
	.set Display_BytecodeBlock_F_0x154_, 0xeff298
	.set Display_BytecodeBlock_F_0x17C_, 0xeff2c0
	.set Display_BytecodeBlock_F_0x1E7_, 0xeff32b
	.set Display_BytecodeBlock_F_0x20A_, 0xeff34e
	.set Display_BytecodeBlock_F_0x20B_, 0xeff34f
	.set Display_BytecodeBlock_F_0x253_, 0xeff397
	.set Display_BytecodeBlock_F_0x256_, 0xeff39a
	.set Display_BytecodeBlock_F_0x259_, 0xeff39d
	.set Display_BytecodeBlock_F_0x2A2_, 0xeff3e6
	.set Display_BytecodeBlock_F_0x2DA_, 0xeff41e
	.set Display_BytecodeBlock_F_0x307_, 0xeff44b
	.set Display_BytecodeBlock_F_0x31A_, 0xeff45e
	.set Display_BytecodeBlock_F_0x32D_, 0xeff471
	.set Display_BytecodeBlock_F_0x33F_, 0xeff483
	.set Display_BytecodeBlock_F_0x344_, 0xeff488
	.set Display_BytecodeBlock_F_0x3A8_, 0xeff4ec
	.set Display_BytecodeBlock_F_0x3D3_, 0xeff517
	.set StringData_KeyNames_0x20_, 0xeff5b9
	.set StringData_KeyNames_0x160_, 0xeff6f9
	.set StringData_KeyNames_0x180_, 0xeff719
	.set StringData_KeyNames_0x1FE_, 0xeff797
	.set StringData_KeyNames_0x23E_, 0xeff7d7
	.set StringData_KeyNames_0x29E_, 0xeff837
	.set StringData_KeyNames_0x312_, 0xeff8ab
	.set StringData_KeyNames_0x313_, 0xeff8ac
	.set StringData_KeyNames_0x32B_, 0xeff8c4
	.set StringData_KeyNames_0x341_, 0xeff8da
	.set StringData_KeyNames_0x399_, 0xeff932
	.set StringData_PartNames_0x54_, 0xeff98d
	.set StringData_PartNames_0xAC_, 0xeff9e5
	.set StringData_PartNames_0xB3_, 0xeff9ec
	.set StringData_PartNames_0x116_, 0xeffa4f
	.set StringData_PartNames_0x120_, 0xeffa59
	.set StringData_PartNames_0x182_, 0xeffabb
	.set StringData_PartNames_0x1C9_, 0xeffb02
	.set StringData_PartNames_0x222_, 0xeffb5b
	.set StringData_PartNames_0x22C_, 0xeffb65
	.set StringData_PartNames_0x287_, 0xeffbc0
	.set StringData_PartNames_0x28F_, 0xeffbc8
	.set StringData_PartNames_0x297_, 0xeffbd0
	.set StringData_PartNames_0x2EB_, 0xeffc24
	.set StringData_PartNames_0x2F6_, 0xeffc2f
	.set StringData_EffectLabel_0x07_, 0xeffc90
	.set StringData_EffectLabel_0x5C_, 0xeffce5
	.set StringData_EffectLabel_0x67_, 0xeffcf0
	.set StringData_EffectLabel_0xBB_, 0xeffd44
	.set StringData_EffectLabel_0xC2_, 0xeffd4b
	.set StringData_EffectLabel_0x12B_, 0xeffdb4
	.set StringData_EffectLabel_0x138_, 0xeffdc1
	.set StringData_EffectLabel_0x176_, 0xeffdff
	.set StringData_EffectLabel_0x17F_, 0xeffe08
	.set StringData_EffectLabel_0x187_, 0xeffe10
	.set StringData_EffectLabel_0x18A_, 0xeffe13
	.set StringData_EffectLabel_0x18D_, 0xeffe16
	.set StringData_EffectLabel_0x1CB_, 0xeffe54
	.set StringData_EffectLabel_0x1D4_, 0xeffe5d
	.set StringData_EffectLabel_0x1DD_, 0xeffe66
	.set StringData_APCModeNames_0x90_, 0xefff31
	.set StringData_APCModeNames_0xD9_, 0xefff7a
	.set StringData_APCModeNames_0xE7_, 0xefff88
	.set StringData_APCModeNames_0x141_, 0xefffe2
	.set StringData_APCModeNames_0x160_, 0xf00001
	.set StringData_APCModeNames_0x161_, 0xf00002
	.set StringData_APCModeNames_0x162_, 0xf00003
	.set StringData_APCModeNames_0x163_, 0xf00004
	.set StringData_APCModeNames_0x175_, 0xf00016
	.set StringData_APCModeNames_0x178_, 0xf00019
	.set StringData_APCModeNames_0x1B8_, 0xf00059
	.set StringData_APCModeNames_0x1CA_, 0xf0006b
	.set StringData_APCModeNames_0x20A_, 0xf000ab
	.set StringData_APCModeNames_0x21B_, 0xf000bc
	.set StringData_APCModeNames_0x24F_, 0xf000f0
	.set StringData_APCModeNames_0x26C_, 0xf0010d
	.set StringData_APCModeNames_0x2AC_, 0xf0014d
	.set StringData_APCModeNames_0x31F_, 0xf001c0
	.set StringData_APCModeNames_0x324_, 0xf001c5
	.set StringData_APCModeNames_0x384_, 0xf00225
	.set StringData_APCModeNames_0x394_, 0xf00235
	.set StringData_APCModeNames_0x395_, 0xf00236
	.set StringData_APCModeNames_0x3F0_, 0xf00291
	.set StringData_APCModeNames_0x3F8_, 0xf00299
	.set StringData_APCModeNames_0x3F9_, 0xf0029a
	.set StringData_APCModeNames_0x3FA_, 0xf0029b
	.set StringData_APCModeNames_0x413_, 0xf002b4
	.set StringData_APCModeNames_0x414_, 0xf002b5
	.set StringData_APCModeNames_0x456_, 0xf002f7
	.set StringData_APCModeNames_0x463_, 0xf00304
	.set StringData_APCModeNames_0x464_, 0xf00305
	.set StringData_APCModeNames_0x4C0_, 0xf00361
	.set StringData_APCModeNames_0x4D8_, 0xf00379
	.set StringData_APCModeNames_0x506_, 0xf003a7
	.set StringData_APCModeNames_0x537_, 0xf003d8
	.set StringData_APCModeNames_0x53E_, 0xf003df
	.set StringData_APCModeNames_0x54E_, 0xf003ef
	.set StringData_APCModeNames_0x57E_, 0xf0041f
	.set StringData_APCModeNames_0x5F5_, 0xf00496
	.set StringData_APCModeNames_0x664_, 0xf00505
	.set StringData_APCModeNames_0x6F0_, 0xf00591
	.set StringData_APCModeNames_0x6F5_, 0xf00596
	.set StringData_APCModeNames_0x713_, 0xf005b4
	.set StringData_APCModeNames_0x928_, 0xf007c9
	.set StringData_APCModeNames_0x92C_, 0xf007cd
	.set StringData_APCModeNames_0x9AD_, 0xf0084e
	.set StringData_APCModeNames_0x9B1_, 0xf00852
	.set StringData_APCModeNames_0x9B2_, 0xf00853
	.set StringData_APCModeNames_0x9C1_, 0xf00862
	.set StringData_APCModeNames_0x9D6_, 0xf00877
	.set StringData_APCModeNames_0x9FF_, 0xf008a0
	.set StringData_APCModeNames_0xA38_, 0xf008d9
	.set StringData_APCModeNames_0xA48_, 0xf008e9
	.set StringData_APCModeNames_0xA78_, 0xf00919
	.set StringData_APCModeNames_0xA7E_, 0xf0091f
	.set StringData_APCModeNames_0xAA6_, 0xf00947
	.set StringData_APCModeNames_0xAAC_, 0xf0094d
	.set StringData_APCModeNames_0xAC2_, 0xf00963
	.set Scoop_DisplayData_ButtonLayout_0x08_, 0xf00aab
	.set Scoop_DisplayData_ButtonLayout_0x17_, 0xf00aba
	.set Scoop_DisplayData_ButtonLayout_0x21_, 0xf00ac4
	.set Scoop_SpecialMode_UpdateParams_0x38_, 0xf0175d
	.set Scoop_SpecialMode_UpdateParams_0x70_, 0xf01795
	.set Scoop_CurveUpdate_DrawSegment_0x20_, 0xf0190c
	.set Scoop_SoundEditorData_0x33_, 0xf03db3
	.set Scoop_SoundEditorData_0x61_, 0xf03de1
	.set Scoop_SoundEditorData_0x8F_, 0xf03e0f
	.set Scoop_SoundEditorData_0xBD_, 0xf03e3d
	.set Scoop_SoundEditorData_0xEB_, 0xf03e6b
	.set Scoop_SoundEditorData_0x10DE_, 0xf04e5e
	.set Scoop_SoundEditorData_0x110C_, 0xf04e8c
	.set Scoop_SoundEditorData_0x113A_, 0xf04eba
	.set Scoop_SoundEditorData_0x1168_, 0xf04ee8
	.set Scoop_SoundEditorData_0x1196_, 0xf04f16
	.set Scoop_SoundEditorData_0x11C4_, 0xf04f44
	.set Scoop_SoundEditorData_0x11F2_, 0xf04f72
	.set Scoop_SoundEditorData_0x1220_, 0xf04fa0
	.set Scoop_SoundEditorData_0x124E_, 0xf04fce
	.set Scoop_SoundEditorData_0x127C_, 0xf04ffc
	.set SeMenu_RegisterElement_Type1_ClearLoop_0x44_, 0xf06290
	.set SeMenu_RegisterParamDisplay_Data_0x71_, 0xf06500
	.set SeMenu_SetupDisplayObject_Alt2_Continue_0x21_, 0xf06693
	.set SeMenu_PartMask_Data_0x05_, 0xf06aa5
	.set SeMenu_BitShiftMask_End_0x14_, 0xf06b72
	.set SeMenu_BitShiftMask_End_0x1A3_, 0xf06d01
	.set SeMenu_BitShiftMask_End_0x1C4_, 0xf06d22
	.set SeMenu_TransferPartValues_AltLoop_0x09_, 0xf06daf
	.set SeMenu_TransferPartValues_EndData_0x8D_, 0xf06e5b
	.set SeMenu_TransferPartValues_EndData_0x9E_, 0xf06e6c
	.set SeMenu_TransferPartValues_EndData_0xA3_, 0xf06e71
	.set SeMenu_TransferPartValues_EndData_0xC0_, 0xf06e8e
	.set SeMenu_TransferPartValues_EndData_0x169_, 0xf06f37
	.set SeMenu_TransferPartValues_EndData_0x1E0_, 0xf06fae
	.set SeMenu_TransferPartValues_EndData_0x20E_, 0xf06fdc
	.set SeMenu_SetupPartDisplay_End_0x90_, 0xf07333
	.set SeMenu_SetupPartDisplay_End_0xD3_, 0xf07376
	.set SeMenu_SetupPartDisplay_End_0xE8_, 0xf0738b
	.set SeMenu_SetupPartDisplay_End_0x1AA_, 0xf0744d
	.set SeMenu_SetupPartDisplay_End_0x1AF_, 0xf07452
	.set SeMenu_SetupPartDisplay_End_0x1B4_, 0xf07457
	.set SeMenu_SetupPartDisplay_End_0x1C6_, 0xf07469
	.set SeMenu_SetupPartDisplay_End_0x1DA_, 0xf0747d
	.set SeMenu_SetupPartDisplay_End_0x1E0_, 0xf07483
	.set SeMenu_SetupPartDisplay_End_0x1F6_, 0xf07499
	.set SeMenu_SetupPartDisplay_End_0x219_, 0xf074bc
	.set SeMenu_SetupPartDisplay_End_0x235_, 0xf074d8
	.set SeMenu_SetupPartDisplay_End_0x24D_, 0xf074f0
	.set SeMenu_SetupPartDisplay_End_0x26E_, 0xf07511
	.set SeMenu_ApplyPartEdit_Data2_0x39_, 0xf076a5
	.set SeMenu_ApplyPartEdit_Data2_0xB6_, 0xf07722
	.set SeMenu_ApplyPartEdit_Data2_0x133_, 0xf0779f
	.set SeMenu_ApplyPartEdit_Data2_0x1B0_, 0xf0781c
	.set SeMenu_ApplyPartEdit_Data2_0x22B_, 0xf07897
	.set SeMenu_ApplyPartEdit_Data2_0x292_, 0xf078fe
	.set SeMenu_ApplyPartEdit_Data2_0x2FA_, 0xf07966
	.set SeMenu_ApplyPartEdit_Data2_0x332_, 0xf0799e
	.set SeMenu_ApplyPartEdit_Data2_0x396_, 0xf07a02
	.set SeMenu_ApplyPartEdit_Data2_0x3FA_, 0xf07a66
	.set SeMenu_ApplyPartEdit_Data2_0x498_, 0xf07b04
	.set SeMenu_ApplyPartEdit_Data2_0x4FC_, 0xf07b68
	.set SeMenu_ApplyPartEdit_Data2_0x59C_, 0xf07c08
	.set SeMenu_ApplyPartEdit_Data2_0x602_, 0xf07c6e
	.set SeMenu_ApplyPartEdit_Data2_0x6A2_, 0xf07d0e
	.set SeMenu_ApplyPartEdit_Data2_0x732_, 0xf07d9e
	.set SeMenu_ApplyPartEdit_Data2_0x7C2_, 0xf07e2e
	.set SeMenu_ApplyPartEdit_Data2_0x852_, 0xf07ebe
	.set SeMenu_ApplyPartEdit_Data2_0x8A1_, 0xf07f0d
	.set SeMenu_ApplyPartEdit_Data2_0x8F4_, 0xf07f60
	.set SeMenu_ApplyPartEdit_Data2_0x948_, 0xf07fb4
	.set SeMenu_ApplyPartEdit_Data2_0xA1D_, 0xf08089
	.set SeMenu_ApplyPartEdit_Data2_0xA49_, 0xf080b5
	.set SeMenu_ApplyPartEdit_Data2_0xA69_, 0xf080d5
	.set SeMenu_ApplyPartEdit_Data2_0xDB3_, 0xf0841f
	.set SeMenu_ApplyPartEdit_Data2_0x13DE_, 0xf08a4a
	.set SeMenu_ApplyPartEdit_Data2_0x162C_, 0xf08c98
	.set SeMenu_ApplyPartEdit_Data2_0x17C1_, 0xf08e2d
	.set SeMenu_ApplyPartEdit_Data2_0x1815_, 0xf08e81
	.set SeMenu_ApplyPartEdit_Data2_0x19BD_, 0xf09029
	.set SeMenu_ApplyPartEdit_Data2_0x1AAD_, 0xf09119
	.set SeMenu_ApplyPartEdit_Data2_0x1C63_, 0xf092cf
	.set SeMenu_ApplyPartEdit_Data2_0x1C7A_, 0xf092e6
	.set SeMenu_ApplyPartEdit_Data2_0x1C84_, 0xf092f0
	.set SeMenu_ApplySynthParam_Data_0x53_, 0xf09567
	.set SeMenu_SetMode_Data_0x05_, 0xf095ba
	.set SeMenu_SetMode_Data_0x0F_, 0xf095c4
	.set SeMenu_HandleMenuChange_Data_0x05_, 0xf09764
	.set SeMenu_PatchBank_Data_0x74_, 0xf097e7
	.set SeMenu_OrPartConfig_Data_0x06_, 0xf098d7
	.set SeMenu_DisplayState_Data_0x05_, 0xf09917
	.set SeMenu_DisplayState_Data_0x0A_, 0xf0991c
	.set SeMenu_RefreshPartDisplay_Data_0x0D_, 0xf09ad0
	.set SeMenu_RefreshPartDisplay_Data_0x3B_, 0xf09afe
	.set SeMenu_RefreshPartDisplay_Data_0x69_, 0xf09b2c
	.set SeMenu_RefreshPartDisplay_Data_0x97_, 0xf09b5a
	.set UpdSeSel_ExtendedOps_Data_0xE1_, 0xf0a786
	.set UpdSeSel_ExtendedOps_Data_0x1F6_, 0xf0a89b
	.set UpdSeSel_ExtendedOps_Data_0x28C_, 0xf0a931
	.set UpdSeSel_ExtendedOps_Data_0x336_, 0xf0a9db
	.set UpdSeSel_ExtendedOps_Data_0x43E_, 0xf0aae3
	.set UpdSeSel_ExtendedOps_Data_0x58E_, 0xf0ac33
	.set UpdSeSel_ExtendedOps_Data_0x62F_, 0xf0acd4
	.set UpdSeSel_ExtendedOps_Data_0x72B_, 0xf0add0
	.set UpdSeSel_ExtendedOps_Data_0x7D6_, 0xf0ae7b
	.set UpdSeSel_ExtendedOps_Data_0x7DC_, 0xf0ae81
	.set UpdSeSel_ExtendedOps_Data_0x966_, 0xf0b00b
	.set UpdSeSel_ExtendedOps_Data_0x9AA_, 0xf0b04f
	.set UpdSeSel_ExtendedOps_Data_0xAE6_, 0xf0b18b
	.set UpdSeSel_ExtendedOps_Data_0xB01_, 0xf0b1a6
	.set UpdSeSel_ExtendedOps_Data_0xB18_, 0xf0b1bd
	.set UpdSeSel_ExtendedOps_Data_0xB2F_, 0xf0b1d4
	.set UpdSeSel_ExtendedOps_Data_0xB42_, 0xf0b1e7
	.set UpdSeSel_ExtendedOps_Data_0xB51_, 0xf0b1f6
	.set UpdSeSel_ExtendedOps_Data_0xBF2_, 0xf0b297
	.set UpdSeSel_ExtendedOps_Data_0xC88_, 0xf0b32d
	.set UpdSeSel_ExtendedOps_Data_0xD32_, 0xf0b3d7
	.set SeMenu_AltUpdate_Data_0xDC_, 0xf0b630
	.set SeMenu_AltUpdate_Data_0x1BB_, 0xf0b70f
	.set SeMenu_CopyWriteUpdate_Data_0xFA_, 0xf0babe
	.set SeMenu_CopyWriteUpdate_Data_0x114_, 0xf0bad8
	.set SeMenu_CopyWriteUpdate_Data_0x1B9_, 0xf0bb7d
	.set SeMenu_CopyWriteUpdate_Data_0x212_, 0xf0bbd6
	.set SeMenu_CopyWriteUpdate_Data_0x21C_, 0xf0bbe0
	.set SeMenu_CopyWriteUpdate_Data_0x21D_, 0xf0bbe1
	.set SeMenu_CopyWriteUpdate_Data_0x227_, 0xf0bbeb
	.set SeMenu_CopyWriteUpdate_Data_0x228_, 0xf0bbec
	.set SeMenu_CopyWriteUpdate_Data_0x232_, 0xf0bbf6
	.set SeMenu_CopyWriteUpdate_Data_0x233_, 0xf0bbf7
	.set SeMenu_CopyWriteUpdate_Data_0x23D_, 0xf0bc01
	.set SeMenu_CopyWriteUpdate_Data_0x23E_, 0xf0bc02
	.set SeMenu_CopyWriteUpdate_Data_0x248_, 0xf0bc0c
	.set SeMenu_CopyWriteUpdate_Data_0x249_, 0xf0bc0d
	.set SeMenu_CopyWriteUpdate_Data_0x253_, 0xf0bc17
	.set SeMenu_CopyWriteUpdate_Data_0x254_, 0xf0bc18
	.set SeMenu_CopyWriteUpdate_Data_0x25E_, 0xf0bc22
	.set SeMenu_CopyWriteUpdate_Data_0x25F_, 0xf0bc23
	.set SeMenu_CopyWriteUpdate_Data_0x269_, 0xf0bc2d
	.set SeMenu_CopyWriteUpdate_Data_0x26A_, 0xf0bc2e
	.set SeMenu_CopyWriteUpdate_Data_0x274_, 0xf0bc38
	.set SeMenu_CopyWriteUpdate_Data_0x275_, 0xf0bc39
	.set SeMenu_CopyWriteUpdate_Data_0x27F_, 0xf0bc43
	.set SeMenu_CopyWriteUpdate_Data_0x28B_, 0xf0bc4f
	.set SeMenu_CopyWriteUpdate_Data_0x295_, 0xf0bc59
	.set SeMenu_CopyWriteUpdate_Data_0x296_, 0xf0bc5a
	.set SeMenu_CopyWriteUpdate_Data_0x2A0_, 0xf0bc64
	.set SeMenu_CopyWriteUpdate_Data_0x2A1_, 0xf0bc65
	.set SeMenu_CopyWriteUpdate_Data_0x2AB_, 0xf0bc6f
	.set SeMenu_CopyWriteUpdate_Data_0x2AC_, 0xf0bc70
	.set SeMenu_CopyWriteUpdate_Data_0x2B6_, 0xf0bc7a
	.set SeMenu_CopyWriteUpdate_Data_0x2B7_, 0xf0bc7b
	.set SeMenu_CopyWriteUpdate_Data_0x2C1_, 0xf0bc85
	.set SeMenu_CopyWriteUpdate_Data_0x2C2_, 0xf0bc86
	.set SeMenu_CopyWriteUpdate_Data_0x2CC_, 0xf0bc90
	.set SeMenu_CopyWriteUpdate_Data_0x2CD_, 0xf0bc91
	.set SeMenu_CopyWriteUpdate_Data_0x2D7_, 0xf0bc9b
	.set SeMenu_CopyWriteUpdate_Data_0x2D8_, 0xf0bc9c
	.set SeMenu_CopyWriteUpdate_Data_0x2E2_, 0xf0bca6
	.set SeMenu_CopyWriteUpdate_Data_0x2E3_, 0xf0bca7
	.set SeMenu_CopyWriteUpdate_Data_0x2ED_, 0xf0bcb1
	.set SeMenu_CopyWriteUpdate_Data_0x2EE_, 0xf0bcb2
	.set SeMenu_CopyWriteUpdate_Data_0x2F8_, 0xf0bcbc
	.set SeMenu_CopyWriteUpdate_Data_0x2F9_, 0xf0bcbd
	.set SeMenu_CopyWriteUpdate_Data_0x303_, 0xf0bcc7
	.set SeMenu_CopyWriteUpdate_Data_0x304_, 0xf0bcc8
	.set SeMenu_CopyWriteUpdate_Data_0x30E_, 0xf0bcd2
	.set SeMenu_CopyWriteUpdate_Data_0x30F_, 0xf0bcd3
	.set SeMenu_CopyWriteUpdate_Data_0x319_, 0xf0bcdd
	.set SeMenu_CopyWriteUpdate_Data_0x31A_, 0xf0bcde
	.set SeMenu_CopyWriteUpdate_Data_0x324_, 0xf0bce8
	.set SeMenu_CopyWriteUpdate_Data_0x325_, 0xf0bce9
	.set SeMenu_CopyWriteUpdate_Data_0x32F_, 0xf0bcf3
	.set SeMenu_CopyWriteUpdate_Data_0x330_, 0xf0bcf4
	.set SeMenu_CopyWriteUpdate_Data_0x33A_, 0xf0bcfe
	.set SeMenu_CopyWriteUpdate_Data_0x33B_, 0xf0bcff
	.set SeMenu_CopyWriteUpdate_Data_0x345_, 0xf0bd09
	.set SeMenu_CopyWriteUpdate_Data_0x346_, 0xf0bd0a
	.set SeMenu_CopyWriteUpdate_Data_0x347_, 0xf0bd0b
	.set SeMenu_CopyWriteUpdate_Data_0x348_, 0xf0bd0c
	.set SeMenu_CopyWriteUpdate_Data_0x349_, 0xf0bd0d
	.set SeMenu_CopyWriteUpdate_Data_0x34A_, 0xf0bd0e
	.set SeMenu_CopyWriteUpdate_Data_0x354_, 0xf0bd18
	.set SeMenu_CopyWriteUpdate_Data_0x355_, 0xf0bd19
	.set SeMenu_CopyWriteUpdate_Data_0x35F_, 0xf0bd23
	.set SeMenu_CopyWriteUpdate_Data_0x360_, 0xf0bd24
	.set SeMenu_CopyWriteUpdate_Data_0x36A_, 0xf0bd2e
	.set SeMenu_CopyWriteUpdate_Data_0x36B_, 0xf0bd2f
	.set SeMenu_CopyWriteUpdate_Data_0x399_, 0xf0bd5d
	.set SeMenu_CopyWriteUpdate_Data_0x582_, 0xf0bf46
	.set SeMenu_CopyWriteUpdate_Data_0xD15_, 0xf0c6d9
	.set SeMenu_CopyWriteUpdate_Data_0xD43_, 0xf0c707
	.set SeMenu_CopyWriteUpdate_Data_0xD71_, 0xf0c735
	.set SeMenu_CopyWriteUpdate_Data_0xD9F_, 0xf0c763
	.set SeMenu_CopyWriteUpdate_Data_0xDCD_, 0xf0c791
	.set SeMenu_CopyWriteUpdate_Data_0x1D4C_, 0xf0d710
	.set SeMenu_CopyWriteUpdate_Data_0x1D7A_, 0xf0d73e
	.set SeMenu_CopyWriteUpdate_Data_0x1DA8_, 0xf0d76c
	.set SeMenu_CopyWriteUpdate_Data_0x1DD6_, 0xf0d79a
	.set SeMenu_CopyWriteUpdate_Data_0x1E04_, 0xf0d7c8
	.set SeMenu_CopyWriteUpdate_Data_0x292E_, 0xf0e2f2
	.set SeMenu_DisplayPartValue_Data_0x7F_, 0xf0edfc
	.set SeMenu_DisplayPartValue_Data_0xB6_, 0xf0ee33
	.set SeMenu_ShowConfirmDialog_Data_0xC0_, 0xf0f04a
	.set SeMenu_ShowConfirmDialog_Data_0x10A_, 0xf0f094
	.set SeMenu_ShowConfirmDialog_Data_0x1BF_, 0xf0f149
	.set SeMenu_ShowConfirmDialog_Data_0x1F6_, 0xf0f180
	.set SeMenu_ShowConfirmDialog_Data_0x331_, 0xf0f2bb
	.set SeMenu_ShowConfirmDialog_Data_0x3F4_, 0xf0f37e
	.set SeMenu_ShowConfirmDialog_Data_0x408_, 0xf0f392
	.set SeMenu_ShowConfirmDialog_Data_0x4A9_, 0xf0f433
	.set SeMenu_ShowConfirmDialog_Data_0x54C_, 0xf0f4d6
	.set SeMenu_WaveformSelect_Data_0x6D_, 0xf0f5a3
	.set SeMenu_WaveformSelect_Data_0x99_, 0xf0f5cf
	.set SeMenu_WaveformSelect_Data_0xAF_, 0xf0f5e5
	.set SeMenu_PresetManager_Data_0x60_, 0xf0f7a5
	.set SeMenu_PresetManager_Data_0xEA_, 0xf0f82f
	.set SeMenu_PresetManager_Data_0x152_, 0xf0f897
	.set SeMenu_PresetManager_Data_0x1AF_, 0xf0f8f4
	.set SeMenu_PresetManager_Data_0x1C4_, 0xf0f909
	.set SeMenu_PresetManager_Data_0x1D9_, 0xf0f91e
	.set SeMenu_PresetBrowser_Data_0x08_, 0xf0f99e
	.set SeMenu_PresetBrowser_Data_0x3B_, 0xf0f9d1
	.set SeMenu_PresetBrowser_Data_0x98_, 0xf0fa2e
	.set SeMenu_CompareAndApply_Data6_0x32_, 0xf0fc31
	.set SeMenu_Utility_CopyBlock_0x8B_, 0xf0fce1
	.set SeMenu_Utility_End_0x12_, 0xf0ffd9
	.set Data_UnknownBlock_0x6E_, 0xf1036a
	.set Data_UnknownBlock_0x23D_, 0xf10539
	.set Data_UnknownBlock_0x46B_, 0xf10767
	.set SeMenu_FilterEdit_Init_0x04_, 0xf1096d
	.set SeMenu_EqEdit_DrawInit_0x15_, 0xf10be7
	.set SeBitmap_EnvCurve5_0x190_, 0xf1115e
	.set SeBitmap_EnvCurve5_0x19A_, 0xf11168
	.set SeBitmap_EnvCurve5_0x2BD_, 0xf1128b
	.set SeBitmap_EnvCurve5_0x2E9_, 0xf112b7
	.set SeBitmap_EnvCurve5_0x313_, 0xf112e1
	.set SeBitmap_EnvCurve5_0x31D_, 0xf112eb
	.set SeBitmap_EnvCurve5_0x327_, 0xf112f5
	.set SeBitmap_EnvCurve5_0x40B_, 0xf113d9
	.set SeBitmap_EnvCurve5_0x453_, 0xf11421
	.set SeBitmap_EnvCurve5_0x46B_, 0xf11439
	.set SeBitmap_EnvCurve5_0x492_, 0xf11460
	.set SeBitmap_EnvCurve5_0x49C_, 0xf1146a
	.set SeBitmap_EnvCurve5_0x4A6_, 0xf11474
	.set SeBitmap_EnvCurve5_0x4B0_, 0xf1147e
	.set SeBitmap_EnvCurve5_0x50F_, 0xf114dd
	.set SeBitmap_EnvCurve5_0x5E2_, 0xf115b0
	.set SeBitmap_EnvCurve5_0x60D_, 0xf115db
	.set SeBitmap_EnvCurve5_0x612_, 0xf115e0
	.set SeBitmap_EnvCurve5_0x7B6_, 0xf11784
	.set SeBitmap_EnvCurve5_0x7C0_, 0xf1178e
	.set SeBitmap_EnvCurve5_0x7CA_, 0xf11798
	.set SeBitmap_EnvCurve5_0x7E6_, 0xf117b4
	.set SeBitmap_EnvCurve5_0x82E_, 0xf117fc
	.set SeBitmap_EnvCurve5_0x892_, 0xf11860
	.set SeBitmap_EnvCurve5_0x90A_, 0xf118d8
	.set SeBitmap_EnvCurve5_0x94C_, 0xf1191a
	.set SeBitmap_EnvCurve5_0x986_, 0xf11954
	.set SeBitmap_EnvCurve5_0x996_, 0xf11964
	.set SeBitmap_EnvCurve5_0xA46_, 0xf11a14
	.set SeBitmap_EnvCurve5_0xA4B_, 0xf11a19
	.set SeBitmap_EnvCurve5_0xA69_, 0xf11a37
	.set SeBitmap_EnvCurve5_0xC7B_, 0xf11c49
	.set SeBitmap_EnvCurve5_0xCC1_, 0xf11c8f
	.set SeBitmap_EnvCurve5_0xD38_, 0xf11d06
	.set SeBitmap_EnvCurve5_0xD73_, 0xf11d41
	.set SeBitmap_EnvCurve5_0xD78_, 0xf11d46
	.set SeBitmap_EnvCurve5_0xD82_, 0xf11d50
	.set SeBitmap_EnvCurve5_0xD8C_, 0xf11d5a
	.set SeBitmap_EnvCurve5_0xE88_, 0xf11e56
	.set SeBitmap_EnvCurve5_0xE9C_, 0xf11e6a
	.set SeBitmap_EnvCurve5_0xEA8_, 0xf11e76
	.set SeBitmap_EnvCurve5_0xEBC_, 0xf11e8a
	.set SeBitmap_EnvCurve5_0xEC8_, 0xf11e96
	.set SeBitmap_EnvCurve5_0xFB5_, 0xf11f83
	.set SeBitmap_EnvCurve5_0x1069_, 0xf12037
	.set SeBitmap_EnvCurve5_0x108A_, 0xf12058
	.set SeBitmap_EnvCurve5_0x109E_, 0xf1206c
	.set SeBitmap_EnvCurve5_0x10B6_, 0xf12084
	.set SeBitmap_EnvCurve5_0x115B_, 0xf12129
	.set SeBitmap_EnvCurve5_0x12A6_, 0xf12274
	.set SeBitmap_EnvCurve5_0x12BA_, 0xf12288
	.set SeBitmap_EnvCurve5_0x12E0_, 0xf122ae
	.set SeBitmap_EnvCurve5_0x1373_, 0xf12341
	.set SeBitmap_EnvCurve5_0x1378_, 0xf12346
	.set SeBitmap_EnvCurve5_0x1396_, 0xf12364
	.set SeBitmap_EnvCurve5_0x13AE_, 0xf1237c
	.set SeBitmap_EnvCurve5_0x13B8_, 0xf12386
	.set SeBitmap_EnvCurve5_0x13C3_, 0xf12391
	.set SeBitmap_EnvCurve5_0x1510_, 0xf124de
	.set SeBitmap_EnvCurve5_0x1525_, 0xf124f3
	.set SeBitmap_EnvCurve5_0x1539_, 0xf12507
	.set SeBitmap_EnvCurve5_0x15CF_, 0xf1259d
	.set SeBitmap_EnvCurve5_0x15E3_, 0xf125b1
	.set SeBitmap_EnvCurve5_0x15F8_, 0xf125c6
	.set SeBitmap_EnvCurve5_0x1702_, 0xf126d0
	.set SeBitmap_EnvCurve5_0x1719_, 0xf126e7
	.set SeBitmap_EnvCurve5_0x1723_, 0xf126f1
	.set SeBitmap_EnvCurve5_0x172D_, 0xf126fb
	.set SeBitmap_EnvCurve5_0x1739_, 0xf12707
	.set SeBitmap_EnvCurve5_0x1743_, 0xf12711
	.set SeBitmap_EnvCurve5_0x1865_, 0xf12833
	.set SeBitmap_EnvCurve5_0x18B2_, 0xf12880
	.set SeBitmap_EnvCurve5_0x19EF_, 0xf129bd
	.set SeBitmap_EnvCurve5_0x1A03_, 0xf129d1
	.set SeBitmap_EnvCurve5_0x1B06_, 0xf12ad4
	.set SeBitmap_EnvCurve5_0x1B2F_, 0xf12afd
	.set SeBitmap_EnvCurve5_0x1B7B_, 0xf12b49
	.set SeBitmap_EnvCurve5_0x1B85_, 0xf12b53
	.set SeBitmap_EnvCurve5_0x1BAD_, 0xf12b7b
	.set SeBitmap_EnvCurve5_0x1BB8_, 0xf12b86
	.set SeBitmap_EnvCurve5_0x1BE0_, 0xf12bae
	.set SeBitmap_EnvCurve5_0x1C76_, 0xf12c44
	.set SeBitmap_EnvCurve5_0x1C7E_, 0xf12c4c
	.set SeBitmap_EnvCurve5_0x1CDD_, 0xf12cab
	.set SeBitmap_EnvCurve5_0x1CE9_, 0xf12cb7
	.set SeBitmap_EnvCurve5_0x1CF5_, 0xf12cc3
	.set SeBitmap_EnvCurve5_0x1D33_, 0xf12d01
	.set SeBitmap_EnvCurve5_0x1D3D_, 0xf12d0b
	.set SeBitmap_EnvCurve5_0x1D65_, 0xf12d33
	.set SeBitmap_EnvCurve5_0x1D98_, 0xf12d66
	.set SeBitmap_EnvCurve5_0x1DDA_, 0xf12da8
	.set SeBitmap_EnvCurve5_0x1DF8_, 0xf12dc6
	.set SeBitmap_EnvCurve5_0x1E54_, 0xf12e22
	.set SeBitmap_EnvCurve5_0x1E87_, 0xf12e55
	.set SeBitmap_EnvCurve5_0x1E97_, 0xf12e65
	.set SeBitmap_EnvCurve5_0x1EE8_, 0xf12eb6
	.set SeBitmap_EnvCurve5_0x1F00_, 0xf12ece
	.set SeBitmap_EnvCurve5_0x1F75_, 0xf12f43
	.set SeMenu_CompareScreen_DataTable_0x10_, 0xf12f55
	.set SeMenu_CompareScreen_DataTable_0x24_, 0xf12f69
	.set SeMenu_CompareScreen_DataTable_0x50_, 0xf12f95
	.set SeMenu_CompareScreen_DataTable_0xDB_, 0xf13020
	.set SeMenu_CompareScreen_DataTable_0x10F_, 0xf13054
	.set SeMenu_CompareScreen_DataTable_0x119_, 0xf1305e
	.set SeMenu_CompareScreen_DataTable_0x141_, 0xf13086
	.set SeMenu_CompareScreen_DataTable_0x179_, 0xf130be
	.set SeMenu_CompareScreen_DataTable_0x189_, 0xf130ce
	.set SeMenu_CompareScreen_DataTable_0x1CF_, 0xf13114
	.set SeMenu_CompareScreen_DataTable_0x1EB_, 0xf13130
	.set SeMenu_CompareScreen_DataTable_0x260_, 0xf131a5
	.set SeMenu_CompareScreen_DataTable_0x278_, 0xf131bd
	.set TuningSys_Param_NamesAndCoords_0x0B_, 0xf13293
	.set TuningSys_Param_NamesAndCoords_0x21_, 0xf132a9
	.set TuningSys_Param_ModeSelect_0x0B_, 0xf132bf
	.set TuningSys_Param_ModeSelect_0x17B_, 0xf1342f
	.set TuningSys_Param_ModeSelect_0x185_, 0xf13439
	.set TuningSys_Param_ModeSelect_0x18F_, 0xf13443
	.set TuningSystem_Handler_Table_0x3C_, 0xf13483
	.set TuningSystem_Handler_Table_0x55_, 0xf1349c
	.set TuningSystem_Handler_Table_0x69_, 0xf134b0
	.set TuningSystem_Handler_Table_0x82_, 0xf134c9
	.set TuningSystem_Handler_Table_0x8D_, 0xf134d4
	.set TuningSystem_Handler_Table_0xCB_, 0xf13512
	.set TuningSystem_Handler_Table_0xDF_, 0xf13526
	.set TuningSystem_Handler_Table_0x123_, 0xf1356a
	.set TuningSystem_Handler_Table_0x12D_, 0xf13574
	.set TuningSystem_Handler_Table_0x137_, 0xf1357e
	.set TuningSystem_Handler_Table_0x15F_, 0xf135a6
	.set TuningSystem_Handler_Table_0x173_, 0xf135ba
	.set TuningSystem_Handler_Table_0x17D_, 0xf135c4
	.set TuningSystem_Handler_Table_0x187_, 0xf135ce
	.set TuningSystem_Handler_Table_0x191_, 0xf135d8
	.set TuningSystem_Handler_Table_0x1E1_, 0xf13628
	.set TuningSystem_Handler_Table_0x295_, 0xf136dc
	.set TuningSystem_Handler_Table_0x2C1_, 0xf13708
	.set TuningSystem_Handler_Table_0x2D1_, 0xf13718
	.set TuningSystem_Handler_Table_0x3C9_, 0xf13810
	.set TuningSystem_Handler_Table_0x3F1_, 0xf13838
	.set TuningSystem_Handler_Table_0x3F4_, 0xf1383b
	.set TuningSystem_Handler_Table_0x416_, 0xf1385d
	.set TuningSystem_Handler_Table_0x442_, 0xf13889
	.set TuningSystem_Handler_Table_0x5F9_, 0xf13a40
	.set TuningSystem_Handler_Table_0x603_, 0xf13a4a
	.set TuningSystem_Handler_Table_0x617_, 0xf13a5e
	.set TuningSystem_Handler_Table_0x628_, 0xf13a6f
	.set TuningSystem_Handler_Table_0x633_, 0xf13a7a
	.set TuningSystem_Handler_Table_0x64F_, 0xf13a96
	.set TuningSystem_Handler_Table_0x66B_, 0xf13ab2
	.set TuningSystem_Handler_Table_0x675_, 0xf13abc
	.set TuningSystem_Handler_Table_0x67F_, 0xf13ac6
	.set TuningSystem_Handler_Table_0x6FF_, 0xf13b46
	.set TuningSystem_Handler_Table_0x71F_, 0xf13b66
	.set TuningSystem_Handler_Table_0xB2B_, 0xf13f72
	.set TuningSystem_Handler_Table_0xCA8_, 0xf140ef
	.set TuningSystem_Handler_Table_0xCB2_, 0xf140f9
	.set TuningSystem_Handler_Table_0xD22_, 0xf14169
	.set TuningSystem_Handler_Table_0xDF2_, 0xf14239
	.set TuningSystem_Handler_Table_0xE1F_, 0xf14266
	.set TuningSystem_Handler_Table_0xFC4_, 0xf1440b
	.set TuningSystem_Handler_Table_0xFE0_, 0xf14427
	.set TuningSystem_Handler_Table_0x1028_, 0xf1446f
	.set TuningSystem_Handler_Table_0x1040_, 0xf14487
	.set TuningSystem_Handler_Table_0x10A0_, 0xf144e7
	.set TuningSystem_Handler_Table_0x10DC_, 0xf14523
	.set TuningSystem_Handler_Table_0x110E_, 0xf14555
	.set TuningSystem_Handler_Table_0x114A_, 0xf14591
	.set TuningSystem_Handler_Table_0x1155_, 0xf1459c
	.set TuningSystem_Handler_Table_0x117D_, 0xf145c4
	.set TuningSystem_Handler_Table_0x11F9_, 0xf14640
	.set TuningSystem_Handler_Table_0x123D_, 0xf14684
	.set TuningSystem_Handler_Table_0x1247_, 0xf1468e
	.set TuningSystem_Handler_Table_0x126F_, 0xf146b6
	.set TuningSystem_Handler_Table_0x12B6_, 0xf146fd
	.set TuningSystem_Handler_Table_0x12CA_, 0xf14711
	.set TuningSystem_Handler_Table_0x12D4_, 0xf1471b
	.set TuningSystem_Handler_Table_0x12FC_, 0xf14743
	.set TuningSystem_Handler_Table_0x132F_, 0xf14776
	.set TuningSystem_Handler_Table_0x1343_, 0xf1478a
	.set TuningSystem_Handler_Table_0x139A_, 0xf147e1
	.set TuningSystem_Handler_Table_0x13C2_, 0xf14809
	.set TuningSystem_Handler_Table_0x13F1_, 0xf14838
	.set TuningSystem_Handler_Table_0x13F6_, 0xf1483d
	.set TuningSystem_Handler_Table_0x14A5_, 0xf148ec
	.set TuningSystem_Handler_Table_0x14D6_, 0xf1491d
	.set TuningSystem_Handler_Table_0x14F5_, 0xf1493c
	.set TuningSystem_Handler_Table_0x1592_, 0xf149d9
	.set TuningSystem_Handler_Table_0x15B0_, 0xf149f7
	.set TuningSystem_Handler_Table_0x15F6_, 0xf14a3d
	.set TuningSystem_Handler_Table_0x1614_, 0xf14a5b
	.set TuningSystem_Handler_Table_0x161F_, 0xf14a66
	.set TuningSystem_Handler_Table_0x198B_, 0xf14dd2
	.set TuningSystem_Handler_Table_0x19A9_, 0xf14df0
	.set TuningSystem_Handler_Table_0x19E1_, 0xf14e28
	.set TuningSystem_Handler_Table_0x19FF_, 0xf14e46
	.set TuningSystem_Handler_Table_0x1A15_, 0xf14e5c
	.set TuningSystem_Handler_Table_0x1A20_, 0xf14e67
	.set TuningSystem_Handler_Table_0x1BD9_, 0xf15020
	.set TuningSystem_Handler_Table_0x1C06_, 0xf1504d
	.set TuningSystem_Handler_Table_0x1C45_, 0xf1508c
	.set TuningSystem_Handler_Table_0x1E73_, 0xf152ba
	.set TuningSystem_Handler_Table_0x1E8B_, 0xf152d2
	.set TuningSystem_Handler_Table_0x1F3F_, 0xf15386
	.set TuningSystem_Handler_Table_0x1F5D_, 0xf153a4
	.set TuningSystem_Handler_Table_0x1F7B_, 0xf153c2
	.set TuningSystem_Handler_Table_0x1F9A_, 0xf153e1
	.set TuningSystem_Handler_Table_0x209A_, 0xf154e1
	.set TuningSystem_Handler_Table_0x23BD_, 0xf15804
	.set TuningSystem_Handler_Table_0x241D_, 0xf15864
	.set TuningSystem_Handler_Table_0x242C_, 0xf15873
	.set FlashWrite_BlockRef_Type6_0x10_, 0xf15aa1
	.set FlashWrite_BlockRef_Type6_0x40_, 0xf15ad1
	.set FlashWrite_BlockRef_Type6_0x118_, 0xf15ba9
	.set FlashWrite_BlockRef_Type6_0x295_, 0xf15d26
	.set FlashWrite_BlockRef_Type6_0x561_, 0xf15ff2
	.set FlashWrite_BlockRef_Type6_0x633_, 0xf160c4
	.set FlashWrite_BlockRef_Type6_0x655_, 0xf160e6
	.set FlashWrite_BlockRef_Type6_0x690_, 0xf16121
	.set FlashWrite_BlockRef_Type6_0x69A_, 0xf1612b
	.set DrumDetailEdit_Menu_Table_0x40_, 0xf1616f
	.set DrumDetailEdit_Menu_Table_0x10A_, 0xf16239
	.set DrumDetailEdit_Menu_Table_0x1A4_, 0xf162d3
	.set DrumDetailEdit_Menu_Table_0x27B_, 0xf163aa
	.set DrumDetailEdit_Menu_Table_0x2B2_, 0xf163e1
	.set DrumDetailEdit_Menu_Table_0x2C6_, 0xf163f5
	.set DrumDetailEdit_Menu_Table_0x2D0_, 0xf163ff
	.set DrumDetailEdit_Menu_Table_0x2E8_, 0xf16417
	.set DrumDetailEdit_Menu_Table_0x32A_, 0xf16459
	.set DrumDetailEdit_Menu_Table_0x35E_, 0xf1648d
	.set DrumDetailEdit_Menu_Table_0x3C8_, 0xf164f7
	.set DrumDetailEdit_Menu_Table_0x3D7_, 0xf16506
	.set EffectParam_Edit_Table_0x70_, 0xf1659f
	.set EffectParam_Edit_Table_0x7A_, 0xf165a9
	.set Flash_InitBytecodeBlock_0x2BF_, 0xf16d8a
	.set Flash_SlotUpdateOpsBlock_0x336_, 0xf186a9
	.set Flash_SlotUpdateOpsBlock_0x480_, 0xf187f3
	.set DualVoice_WriteBackSlots_0x05_, 0xf194c9
	.set SetWall_InlineCodeBlock_0x7F_, 0xf1eeba
	.set SetWall_InlineCodeBlock_0xC8_, 0xf1ef03
	.set SetWall_InlineCodeBlock_0xCD_, 0xf1ef08
	.set SetWall_DataBlock1_0x0F_, 0xf1f10b
	.set SetWall_InlineCodeBlock2_0x5E_, 0xf1f412
	.set SetWall_InlineCodeBlock3_0x01_, 0xf20087
	.set SetWall_InlineCodeBlock3_0x40_, 0xf200c6
	.set SetWall_MiscDataAndCode_0x02_, 0xf200f1
	.set SetWall_MiscDataAndCode_0x51_, 0xf20140
	.set SetWall_MiscDataAndCode_0x52_, 0xf20141
	.set SetWall_MiscDataAndCode_0xCB_, 0xf201ba
	.set UIStateEvt_VoiceParamHandler_0x24_, 0xf20310
	.set UIStateEvt_VoiceParamHandler_0xC9_, 0xf203b5
	.set PlayMode_InitFlagBlock_0x05_, 0xf2063e
	.set PlayMode_InitFlagBlock_0x16_, 0xf2064f
	.set SongMode_InitFlagBlock_0x02_, 0xf20776
	.set SongMode_InitFlagBlock_0x07_, 0xf2077b
	.set SongMode_InitFlagBlock_0x18_, 0xf2078c
	.set SongMode_InitFlagBlock_0x23_, 0xf20797
	.set PartFormat_InitFlagBlock_0x05_, 0xf208dc
	.set PartFormat_InitFlagBlock_0x0A_, 0xf208e1
	.set PartFormat_InitFlagBlock_0x1B_, 0xf208f2
	.set PartFormat_InitFlagBlock_0x26_, 0xf208fd
	.set PlayModeStop_InitFlagBlock_0x04_, 0xf2095e
	.set PlayModeStop_InitFlagBlock_0x10_, 0xf2096a
	.set PlayModeStop_InitFlagBlock_0x21_, 0xf2097b
	.set PlayModeStop_InitFlagBlock_0x2C_, 0xf20986
	.set PlayModeStop_ClearFlagBlock_0x04_, 0xf209f2
	.set PlayModeStop_ClearFlagBlock_0x05_, 0xf209f3
	.set CDlikeSwTtl_DispatchData_0x06_, 0xf22907
	.set CDlikeSwTtl_DispatchData_0x4A_, 0xf2294b
	.set SoundBank_DefaultTrackData_0x08_, 0xf2312c
	.set SoundBank_DefaultNamePadding_0x0A_, 0xf2324b
	.set SMF_HeaderMagic_MThdMTrk_0x04_, 0xf236b3
	.set VoiceChannels_PartMapTable_0x10_, 0xf23e28
	.set SeqTrack_ChannelMapIdentity_0x10_, 0xf2436b
	.set VoiceChannel_ParamTable1_0x40_, 0xf26c5e
	.set VoiceChannel_ParamTable1_0x80_, 0xf26c9e
	.set SMF_HeaderConstants_0x04_, 0xf2823e
	.set SMF_HeaderConstants_0x12_, 0xf2824c
	.set SMF_HeaderConstants_0x1A_, 0xf28254
	.set SMF_HeaderConstants_0x42_, 0xf2827c
	.set SMF_HeaderConstants_0x4A_, 0xf28284
	.set SMF_HeaderConstants_0x52_, 0xf2828c
	.set SMF_SlotParam_RPNReturn_0x1F_, 0xf29d2a
	.set Sqedt_ValueDispatch_0x28_, 0xf35054
	.set Sqedt_ValueDispatch_0x58_, 0xf35084
	.set Sqedt_ValueDispatch_0x82_, 0xf350ae
	.set SeqFormat_DispatchA_0x70_, 0xf351ad
	.set SeqPlay_DataBlock_BBE_0x2C_, 0xf38bea
	.set SeqPlay_DataBlock_BBE_0xF4_, 0xf38cb2
	.set SeqPlay_DataBlock_BBE_0x126_, 0xf38ce4
	.set SeqPlay_DataBlock_BBE_0x155_, 0xf38d13
	.set SeqPlay_DataBlock_BBE_0x19B_, 0xf38d59
	.set AppEvent_ExtendedHandler_0x07_, 0xf3ff26
	.set SeqData_ScanTracks_OuterLoop_0x0C_, 0xf40001
	.set SeqData_ScanTracks_InnerLoop_0x05_, 0xf40007
	.set AppEvtHandler_Branch_002_0x4B_, 0xf441c9
	.set AppEvtHandler_Branch_006_0x3B_, 0xf4427e
	.set AppEvtHandler_Branch_021_0x5E_, 0xf44517
	.set AppEvtHandler_Branch_024_0x97_, 0xf44647
	.set AppEvent_SubDispatch_0x3A6_, 0xf44c4a
	.set AppEvent_SubDispatch_0x4CC_, 0xf44d70
	.set SeqLoad_ProcessDataBlock_0x80_, 0xf479da
	.set SeqLoad_ProcessDataBlock_0xCC_, 0xf47a26
	.set SeqStep_ByteBlockEA5F_0x4E_, 0xf4eaad
	.set SeqStep_FileSectorPopReturn_0x35E_, 0xf5000b
	.set SeqStep_FileSectorPopReturn_0x361_, 0xf5000e
	.set SeqStep_FileSectorPopReturn_0x364_, 0xf50011
	.set SeqStep_FileSectorPopReturn_0x367_, 0xf50014
	.set SeqByteBlock_StyleBitmapRef_0x736_, 0xf50822
	.set FDC_ClearDiskChangeStatus_0x12_, 0xf51e43
	.set SeqDispatch_TrampolineBlock_0x0B_, 0xf532dc
	.set SeqDispatch_TrampolineBlock_0x0C_, 0xf532dd
	.set Rhythm_InstrMapTable_Default_0x31_, 0xf550fb
	.set Rhythm_InstrMapTable_Default_0x62_, 0xf5512c
	.set Rhythm_PitchShiftTable_Default_0x31_, 0xf552a0
	.set Rhythm_VelocityTable_A_0x31_, 0xf5535f
	.set AccStyle_TempoLookupData_0x06_, 0xf55be9
	.set AccVoice_ParamIndexData_0x26_, 0xf56439
	.set AccVoice_ParamIndexData_0x57_, 0xf5646a
	.set AccVoice_ParamIndexData_0x5B_, 0xf5646e
	.set AccVoice_ParamIndexData_0x63_, 0xf56476
	.set AccStyle_ByteDataBlock_0x5C_, 0xf5664a
	.set AccStyle_ByteDataBlock_0xAC_, 0xf5669a
	.set AccStyle_ByteDataBlock_0xBC_, 0xf566aa
	.set AccWrap_JumpTable_0x14_, 0xf59a95
	.set AccWrap_JumpTable_0x15_, 0xf59a96
	.set AccPedal_RawHandler_0x02_, 0xf59b6f
	.set AccAutoPlay_ModeAvail_Extended_0x02_, 0xf5aacd
	.set AccPlayMode_Dispatch_Table_0x02_, 0xf5adf9
	.set AccTempo_WriteMarker_Padding_0x02_, 0xf5b0a5
	.set AccPos_ClearOnStart_Padding_0x02_, 0xf5b414
	.set AccTiming_SlotOffsetTables_0x20_, 0xf5bd56
	.set AccProcess_InlinedCode_0xBF_, 0xf5c00d
	.set AccVoice_ROMLookup_OffsetTable_0x02_, 0xf5c120
	.set AccVoice_IndexedTableLookup_BaseOffsets_0x02_, 0xf5c188
	.set AccVoice_IndexedTableLookup_BaseOffsets_0x152_, 0xf5c2d8
	.set AccVoice_IndexedTableLookup_BaseOffsets_0x2C8_, 0xf5c44e
	.set AccVoice_ChannelCountTable_0x02_, 0xf5c488
	.set AccVoice_CopyFromROM_DataBlock_0x46_, 0xf5c50d
	.set AccVoice_CopyFromROM_DataBlock_0x6D_, 0xf5c534
	.set AccStyle_InlinedBlock_0x06_, 0xf5c6da
	.set AccStyle_InlinedBlock_0x1E0_, 0xf5c8b4
	.set AccVoiceState_PartLookupTable_0x80_, 0xf5cbe3
	.set AccStyle_SC0ByteSelect_0x19_, 0xf5cd7d
	.set AccStyle_SC0ByteSelect_0x32_, 0xf5cd96
	.set AccStyle_SC0ByteSelect_0x4B_, 0xf5cdaf
	.set AccStyle_SC0ByteSelect_0x64_, 0xf5cdc8
	.set Demo_StyleRhythmData_0x60_, 0xf5d02c
	.set Demo_StyleRhythmData_0x240_, 0xf5d20c
	.set Demo_StyleRhythmData_0x274_, 0xf5d240
	.set Demo_StyleRhythmData_0x334_, 0xf5d300
	.set Demo_StyleRhythmData_0x374_, 0xf5d340
	.set Demo_StyleRhythmData_0x474_, 0xf5d440
	.set Demo_StyleRhythmData_0x574_, 0xf5d540
	.set Demo_StyleRhythmData_0x57C_, 0xf5d548
	.set AccTone_InlineBytecodeData_0xB2_, 0xf5d977
	.set AccTone_InlineBytecodeData_0x188_, 0xf5da4d
	.set AccTone_InlineBytecodeData_0x28B_, 0xf5db50
	.set AccTone_InlineBytecodeData_0x2A4_, 0xf5db69
	.set AccTone_InlineBytecodeData_0x576_, 0xf5de3b
	.set AccTone_InlineBytecodeData_0x5A4_, 0xf5de69
	.set AccVoice_BarCounterBytecodeData_0x11A_, 0xf5e016
	.set AccVoice_BarCounterBytecodeData_0x215_, 0xf5e111
	.set AccVoice_BarCounterBytecodeData_0x30A_, 0xf5e206
	.set AccTuning_DispatchDataBlock_A_0x4C_, 0xf5e893
	.set AccPatch_MultiCallWrapper_0x09_, 0xf5e96f
	.set AccPatch_MultiCallWrapper_0x13_, 0xf5e979
	.set AccPatch_SlotScanByteData_0x38_, 0xf5ebd4
	.set AccPatch_SlotScanByteData_0xB2_, 0xf5ec4e
	.set AccPatch_SeqBaseAddrTable_0x18_, 0xf5f2bf
	.set AccPatch_ChannelToParamTable_0x10_, 0xf5f320
	.set AccPatch_ComplexDataBlock_0x14D_, 0xf5fc15
	.set AccPatch_ComplexDataBlock_0x14E_, 0xf5fc16
	.set AccPatch_TransposeNoteTable_0x02_, 0xf60909
	.set AccPatch_TransposeNoteTable_0x0E_, 0xf60915
	.set AccPatch_AdvPlayPos_DataBlock_0x07_, 0xf60c61
	.set AccPatch_AdvPlayPos_DataBlock_0x4B_, 0xf60ca5
	.set ToneGen_MapNoteToOctaveBitmask_0x20_, 0xf616a1
	.set ToneGen_VoiceSlotLookupTable_0x02_, 0xf6181a
	.set __pad_F62002_0x02_, 0xf62004
	.set __pad_F62002_0x0E_, 0xf62010
	.set __pad_F62230_0x02_, 0xf62232
	.set __pad_F62230_0x46_, 0xf62276
	.set ToneGen_CalcTempo_DataTable_0x02_, 0xf625c4
	.set AccPat_InlineFunctions_DataBlock_0x35_, 0xf63125
	.set RhythmROM_LoadPattern_0x34_, 0xf635c1
	.set VoiceSlot_ResolveIndex_0x02_, 0xf63b04
	.set __pad_F63EC6_0x02_, 0xf63ec8
	.set __pad_F63F8F_0x33_, 0xf63fc2
	.set __pad_F63F8F_0x18D_, 0xf6411c
	.set __pad_F63F8F_0x1A8_, 0xf64137
	.set DrumKit_GroupAssignTable_0x1E_, 0xf6451d
	.set DrumKit_GroupAssignTable_0x3C_, 0xf6453b
	.set DrumKit_GroupAssignTable_0x3F_, 0xf6453e
	.set DrumKit_GroupAssignTable_0x42_, 0xf64541
	.set DrumKit_GroupAssignTable_0x45_, 0xf64544
	.set DrumKit_GroupAssignTable_0x48_, 0xf64547
	.set DrumKit_GroupAssignTable_0x4B_, 0xf6454a
	.set DrumKit_GroupAssignTable_0x4E_, 0xf6454d
	.set DrumParam_PointerTableAndData_0x02_, 0xf6476b
	.set DrumKitExit_DataPad_0x01_, 0xf64bcb
	.set DrumKit_InlineCode1_0x07_, 0xf64ca6
	.set DrumKit_InlineCode1_0x08_, 0xf64ca7
	.set DrumKit_InlineCode1_0x0F_, 0xf64cae
	.set DrumKit_InlineCode1_0x61_, 0xf64d00
	.set DrumKit_InlineCode1_0x7F_, 0xf64d1e
	.set DrumKit_InlineCode1_0x86_, 0xf64d25
	.set RhythmFillIn_PatternTable_0x08_, 0xf64f55
	.set RhythmVariation_InlineCode_0x04_, 0xf65095
	.set RhythmVariation_InlineCode_0x26_, 0xf650b7
	.set RhythmVariation_InlineCode_0x32_, 0xf650c3
	.set RhythmVariation_InlineCode_0x59_, 0xf650ea
	.set RhythmVariation_InlineCode_0x79_, 0xf6510a
	.set RhythmVariation_InlineCode_0xA0_, 0xf65131
	.set RhythmVariation_InlineCode_0x17B_, 0xf6520c
	.set RhythmVariation_InlineCode_0x182_, 0xf65213
	.set RhythmConfig_InlineCode2_0x07_, 0xf65241
	.set DrumVoice_Handler7_0x75_, 0xf65525
	.set DrumVoice_Handler7_0x7C_, 0xf6552c
	.set DrumVoice_Handler7_0xE2_, 0xf65592
	.set DrumVoice_Handler7_0xEE_, 0xf6559e
	.set DrumVoice_Handler7_0xF5_, 0xf655a5
	.set DrumVoice_Handler7_0x100_, 0xf655b0
	.set DrumVoice_Handler7_0x107_, 0xf655b7
	.set DrumVoice_Handler7_0x123_, 0xf655d3
	.set DrumVoice_Handler7_0x12A_, 0xf655da
	.set DrumVoice_Handler7_0x140_, 0xf655f0
	.set DrumVoice_Handler7_0x146_, 0xf655f6
	.set DrumVoice_Handler7_0x14D_, 0xf655fd
	.set DrumVoice_Handler7_0x169_, 0xf65619
	.set DrumVoice_Handler7_0x170_, 0xf65620
	.set DrumVoice_Handler7_0x186_, 0xf65636
	.set DrumVoice_Handler7_0x191_, 0xf65641
	.set DrumVoice_Handler7_0x1A7_, 0xf65657
	.set DrumVoice_Handler7_0x238_, 0xf656e8
	.set DrumVoice_Handler7_0x26F_, 0xf6571f
	.set DrumVoice_Handler7_0x323_, 0xf657d3
	.set TimeSig_DisplayStrings_0x21B_, 0xf65b24
	.set TimeSig_DisplayStrings_0x227_, 0xf65b30
	.set TimeSig_DisplayStrings_0x233_, 0xf65b3c
	.set TimeSig_DisplayStrings_0x2EE_, 0xf65bf7
	.set TimeSig_DisplayStrings_0x3A6_, 0xf65caf
	.set TimeSig_DisplayStrings_0x3C7_, 0xf65cd0
	.set TimeSig_DisplayStrings_0x5CC_, 0xf65ed5
	.set TimeSig_DisplayStrings_0x745_, 0xf6604e
	.set TimeSig_DisplayStrings_0x754_, 0xf6605d
	.set TimeSig_DisplayStrings_0x7C6_, 0xf660cf
	.set TimeSig_DisplayStrings_0x7CD_, 0xf660d6
	.set TimeSig_DisplayStrings_0x843_, 0xf6614c
	.set TimeSig_DisplayStrings_0x84A_, 0xf66153
	.set TimeSig_DisplayStrings_0x86D_, 0xf66176
	.set TimeSig_DisplayStrings_0x8A0_, 0xf661a9
	.set TimeSig_DisplayStrings_0x8AB_, 0xf661b4
	.set TimeSig_DisplayStrings_0x8DE_, 0xf661e7
	.set TimeSig_DisplayStrings_0x8E2_, 0xf661eb
	.set TimeSig_DisplayStrings_0x935_, 0xf6623e
	.set VoiceSlot_Dispatch_Return_0x07_, 0xf66f83
	.set RegPreset_LoadVoiceData_0x04_, 0xf67248
	.set RegPreset_LoadVoiceData_0x14_, 0xf67258
	.set RegPreset_LoadVoiceData_0x24_, 0xf67268
	.set ExtVoice_ProcessList_0x01_, 0xf674f5
	.set ExtVoice_ProcessList_0x08_, 0xf674fc
	.set ExtVoice_ProcessList_0x1C_, 0xf67510
	.set ExtVoice_ProcessList_0x23_, 0xf67517
	.set AccVoice_SetupSlots_DataBlock_0x106_, 0xf6781d
	.set AccVoice_SetupSlots_DataBlock_0x107_, 0xf6781e
	.set AccVoice_SetupSlots_DataBlock_0x26C_, 0xf67983
	.set AccVoice_SetupSlots_DataBlock_0x4B2_, 0xf67bc9
	.set __pad_F67D15_0x07_, 0xf67d1c
	.set AccScreen_DataBlock_0x17_, 0xf6a39d
	.set AccScreen_DataBlock_0x5A_, 0xf6a3e0
	.set AccScreen_DataBlock_0x7A_, 0xf6a400
	.set AccScreen_DataBlock_0xE9_, 0xf6a46f
	.set AccScreen_DataBlock_0x103_, 0xf6a489
	.set AccScreen_DataBlock_0x18C_, 0xf6a512
	.set AccScreen_DataBlock_0x274_, 0xf6a5fa
	.set AccScreen_DataBlock_0x294_, 0xf6a61a
	.set AccScreen_DataBlock_0x2BB_, 0xf6a641
	.set AccScreen_UIDataBlock_0x33_, 0xf6aa0a
	.set AccScreen_UIDataBlock_0x15A_, 0xf6ab31
	.set AccScreen_UIDataBlock_0x1E7_, 0xf6abbe
	.set AccScreen_UIDataBlock_0x256_, 0xf6ac2d
	.set AccScreen_UIDataBlock_0x291_, 0xf6ac68
	.set AccScreen_UIDataBlock_0x2BA_, 0xf6ac91
	.set AccScreen_UIDataBlock_0x341_, 0xf6ad18
	.set AccScreen_UIDataBlock_0x356_, 0xf6ad2d
	.set AccScreen_UIDataBlock_0x360_, 0xf6ad37
	.set AccScreen_UIDataBlock_0x37E_, 0xf6ad55
	.set AccScreen_UIDataBlock_0x386_, 0xf6ad5d
	.set AccScreen_UIDataBlock_0x390_, 0xf6ad67
	.set AccScreen_UIDataBlock_0x3B8_, 0xf6ad8f
	.set AccScreen_UIDataBlock_0x4B6_, 0xf6ae8d
	.set AccScreen_UIDataBlock_0x4F6_, 0xf6aecd
	.set AccScreen_UIDataBlock_0x582_, 0xf6af59
	.set AccScreen_UIDataBlock_0x5DC_, 0xf6afb3
	.set AccScreen_UIDataBlock_0x636_, 0xf6b00d
	.set AccScreen_UIDataBlock_0x690_, 0xf6b067
	.set AccScreen_UIDataBlock_0x6EA_, 0xf6b0c1
	.set AccScreen_UIDataBlock_0x72A_, 0xf6b101
	.set AccScreen_UIDataBlock_0x804_, 0xf6b1db
	.set AccScreen_UIDataBlock_0x829_, 0xf6b200
	.set AccPatch_VoiceAssignDataBlock_0x1EE_, 0xf6b593
	.set AccStyle_TableDataEntry_0x90_, 0xf6d8dd
	.set AccompSeq_LargeCodeBlock2_0x04_, 0xf6e651
	.set AccompSeq_WriteMidi_CodeBlock_0x0A_, 0xf6ea61
	.set AccompSeq_MidiFilterCodeBlock_0x79_, 0xf6ec39
	.set AccompSeq_MidiFilterCodeBlock_0x7A_, 0xf6ec3a
	.set Voice_InitBankDataSafe_Alt1_0x07_, 0xf6f0a3
	.set Voice_InitBankDataSafe_Alt1_0x0E_, 0xf6f0aa
	.set Voice_NoteChannelTable1_0x02_, 0xf71055
	.set Voice_NoteChannelTable1_0x402_, 0xf71455
	.set Voice_NoteChannelTable1_0x422_, 0xf71475
	.set Voice_NoteChannelTable1_0x43F_, 0xf71492
	.set Voice_NoteChannelTable2_0x02_, 0xf715b4
	.set Voice_BankIndexTable_0x02_, 0xf719d2
	.set Voice_NoteParamTable_0x02_, 0xf71a26
	.set VocalistGrid_DispatchData_0x160_, 0xf73a98
	.set AudioCtrl_PageHandler_0x0B_, 0xf80006
	.set AudioCtrl_PageHandler_0x0D_, 0xf80008
	.set AudioCtrl_PageHandler_0x0F_, 0xf8000a
	.set AudioCtrl_PageHandler_0x11_, 0xf8000c
	.set AudioCtrl_PageHandler_0x13_, 0xf8000e
	.set AudioCtrl_PageHandler_0x15_, 0xf80010
	.set AudioCtrl_DataBlock_0x1BDA_, 0xf824c0
	.set AudioCtrl_DataBlock_0x1BDB_, 0xf824c1
	.set AudioCtrl_DataBlock_0x1BDC_, 0xf824c2
	.set AudioCtrl_DataBlock_0x1BDD_, 0xf824c3
	.set FileIO_ByteBlock_DemoProc1_0xD8_, 0xf88256
	.set FileIO_ByteBlock_DemoProc1_0x1F8_, 0xf88376
	.set FileIO_ByteBlock_DemoProc1_0x2DE_, 0xf8845c
	.set FileIO_ByteBlock_DemoProc1_0x356_, 0xf884d4
	.set FileIO_ByteBlock_DemoProc1_0x4AC_, 0xf8862a
	.set FileIO_ByteBlock_DemoProc2_0x2D_, 0xf8a10e
	.set FileIO_ByteBlock_DemoProc2_0xA7_, 0xf8a188
	.set FileIO_ByteBlock_DemoProc2_0x13A_, 0xf8a21b
	.set FileIO_ByteBlock_DemoProc2_0x1B4_, 0xf8a295
	.set FileIO_ByteBlock_DemoProc2_0x238_, 0xf8a319
	.set FileIO_ByteBlock_DemoProc2_0x2B3_, 0xf8a394
	.set FileIO_ByteBlock_DemoProc2_0x323_, 0xf8a404
	.set Reset_Floppy_Disk_Controller_0x12_, 0xf97edb
	.set VwMenuBox_Confirm_RenderBottom_0x2E_, 0xfa0917
	.set DbMemo_DrawContent_Loop_0x61_, 0xfa2ea1
	.set DrawWall_Deferred_0x11_, 0xfabbe5
	.set DrawBitmapSP_Return_0x06_, 0xfac24a
	.set DrawBitmapSPFast_Return_0x06_, 0xfac439
	.set DrawBitmapSP2_Return_0x06_, 0xfac579
	.set DrawString_Return_0x07_, 0xfacb69
	.set DrawDesignBox_ByteData_0x59_, 0xfad279
	.set PaletteBankRotate_0x18_, 0xfaf35e
	.set ColorBlit2_LargeCodeBlock_0x65_, 0xfafbad
	.set ColorBlit2_LargeCodeBlock_0x3F0_, 0xfaff38
	.set ColorBlit2_LargeCodeBlock_0xBD9_, 0xfb0721
	.set DrawText_PopAndReturn_0x07_, 0xfb0f31
	.set TextRender_PopAndReturn_0x09_, 0xfb144a
	.set GraphicsRender_ByteData_0x06_, 0xfb1456
	.set GraphicsRender_ByteData_0x2D_, 0xfb147d
	.set GraphicsRender_ByteData_0x67_, 0xfb14b7
	.set GraphicsRender_ByteData_0x7F_, 0xfb14cf
	.set Display_DeferOrDrawWall_0x18_, 0xfb154e
	.set Display_DeferOrUpdateScreen_0x18_, 0xfb1577
	.set Display_DeferOrUpdateScreen_Direct_0x0F_, 0xfb1588
	.set GraphicsRender_ShortByteBlock_0x05_, 0xfb158f
	.set DrawText_LayoutAndRender_Variant1_0x2EB_, 0xfb19d4
	.set DrawText_LayoutAndRender_Variant1_0x33F_, 0xfb1a28
	.set DrawText_LayoutAndRender_Variant1_0x3BD_, 0xfb1aa6
	.set DrawText_LayoutAndRender_Variant1_0x3E7_, 0xfb1ad0
	.set DrawText_LayoutAndRender_Variant1_0x616_, 0xfb1cff
	.set DrawText_LayoutAndRender_Variant1_0x6CA_, 0xfb1db3
	.set DrawFunc_Init_Variant1_0x108_, 0xfb2201
	.set FontGlyph_ByteData_0x11_, 0xfb2841
	.set BitMapOut_UpdateWidget_Done_0x8A_, 0xfb62b5
	.set BitMapOut_UpdateWidget_Done_0x8B_, 0xfb62b6
	.set BitMapOut_UpdateWidget_Done_0x98_, 0xfb62c3
	.set BitMapOut_UpdateWidget_Done_0x99_, 0xfb62c4
	.set DispTimeSet_EventDispatch_0x64_, 0xfbc799
	.set RVari_SelectO_SecondItem_Draw_0x21_, 0xfc0001
	.set RVari_SelectO_SecondItem_Draw_0x22_, 0xfc0002
	.set RVari_SelectO_SecondItem_Draw_0x23_, 0xfc0003
	.set ToneGen_DSPCfg_Initialize_0x06_, 0xfc4ce4
	.set VoiceData_ExtendedParamSetup_0x27_, 0xfc7ea9
	.set VoiceData_ExtendedParamSetup_0x40_, 0xfc7ec2
	.set VoiceData_ExtendedParamSetup_0xAF_, 0xfc7f31
	.set SndBuf_WriteParamEntries_0x36_, 0xfc9bcd
	.set SndBuf_WriteParamEntries_0x6C_, 0xfc9c03
	.set RegBitManip_Handler_4_0x08_, 0xfca3f6
	.set RegBitManip_Handler_4_0x1B_, 0xfca409
	.set RegBitManip_Handler_4_0x30_, 0xfca41e
	.set RegBitManip_Handler_4_0x43_, 0xfca431
	.set MidiSeqBuf_ProcessorTable_0x01_, 0xfca697
	.set TempoRing_ProcessorTable_0x01_, 0xfca8b9
	.set VoiceMode3_DispatchTable_0x01_, 0xfcb025
	.set VoiceMode_ParamConfigTables_0x24_, 0xfcba03
	.set VoiceMode_ParamConfigTables_0x38_, 0xfcba17
	.set VoiceMode_ParamConfigTables_0x47_, 0xfcba26
	.set VoiceMode_ParamConfigTables_0x56_, 0xfcba35
	.set VoiceMode_ParamConfigTables_0x68_, 0xfcba47
	.set VoiceMode_ParamConfigTables_0x5C4_, 0xfcbfa3
	.set VoiceMode_ParamConfigTables_0xAB8_, 0xfcc497
	.set VoiceMode_ParamConfigTables_0xB68_, 0xfcc547
	.set MidiStream_DispatchData_0x04_, 0xfcc5b7
	.set MidiStream_DispatchData_0x16_, 0xfcc5c9
	.set MidiStream_DispatchData_0x42_, 0xfcc5f5
	.set MidiStream_DispatchData_0x67_, 0xfcc61a
	.set MidiStream_DispatchData_0x81_, 0xfcc634
	.set MidiStream_DispatchData_0x98_, 0xfcc64b
	.set MidiStream_DispatchData_0xB2_, 0xfcc665
	.set MidiStream_DispatchData_0xD0_, 0xfcc683
	.set MidiStream_DispatchData_0xEE_, 0xfcc6a1
	.set MidiStream_DispatchData_0x173_, 0xfcc726
	.set MidiStream_DispatchData_0x191_, 0xfcc744
	.set MidiStream_ExtendedDispatch_0x01_, 0xfccb1d
	.set MidiStream_ExtendedDispatch_0x73_, 0xfccb8f
	.set MidiStream_ExtendedDispatch_0x197_, 0xfcccb3
	.set MidiStream_ExtendedDispatch_0x28F_, 0xfccdab
	.set MidiStream_ExtendedDispatch_0x298_, 0xfccdb4
	.set MidiStream_ExtendedDispatch_0x307_, 0xfcce23
	.set MidiStream_HandleRunningStatus_0x21_, 0xfcce8a
	.set MidiStream_HandleRunningStatus_0x98_, 0xfccf01
	.set MIDI_CHANNEL_HANDLER_JUMP_TABLE_0x01_, 0xfcf761
	.set MidiSerial_StatusTable_0x01_, 0xfcfa05
	.set MidiCC_Handler_BitManipulation_0x45_, 0xfcfcb9
	.set MidiCC_Handler_RangeCheck_0x3F_, 0xfcfd77
	.set MidiCC_Handler_ChannelMapping_0x60_, 0xfcfddb
	.set PanelEvt_Dispatch6_TableAndHandlers_0x01_, 0xfd0877
	.set PanelEvt_Dispatch6_TableAndHandlers_0x49_, 0xfd08bf
	.set PanelEvt_Dispatch6_TableAndHandlers_0xAC_, 0xfd0922
	.set PanelEvt_Dispatch6_TableAndHandlers_0xB5_, 0xfd092b
	.set PanelEvt_Dispatch11_TableAndHandlers_0x01_, 0xfd09ab
	.set PanelEvt_Dispatch11_TableAndHandlers_0x5F_, 0xfd0a09
	.set MidiCC_ChannelMappingData_0x80_, 0xfd0ee7
	.set MidiCC_ChannelMappingData_0xE0_, 0xfd0f47
	.set MidiCC_ChannelMappingData_0x140_, 0xfd0fa7
	.set MidiCC_ChannelMappingData_0x1A0_, 0xfd1007
	.set MidiCC_ChannelMappingData_0x200_, 0xfd1067
	.set MidiCC_ChannelMappingData_0x260_, 0xfd10c7
	.set MidiCC_ChannelMappingData_0x2C0_, 0xfd1127
	.set MidiCC_ChannelMappingData_0x320_, 0xfd1187
	.set MidiCC_ChannelMappingData_0x380_, 0xfd11e7
	.set MidiCC_ChannelMappingData_0x3E0_, 0xfd1247
	.set MidiCC_ChannelMappingData_0x440_, 0xfd12a7
	.set MidiCC_ChannelMappingData_0x560_, 0xfd13c7
	.set MidiCC_ChannelMappingData_0x5C0_, 0xfd1427
	.set MidiCC_ChannelMappingData_0x620_, 0xfd1487
	.set MidiCC_ChannelMappingData_0x680_, 0xfd14e7
	.set MidiCC_ChannelMappingData_0x6E0_, 0xfd1547
	.set MidiCC_ChannelMappingData_0x720_, 0xfd1587
	.set MidiCC_ChannelMappingData_0x760_, 0xfd15c7
	.set MidiCC_ChannelMappingData_0x7A0_, 0xfd1607
	.set MidiCC_ChannelMappingData_0x7E0_, 0xfd1647
	.set MidiCC_ChannelMappingData_0x820_, 0xfd1687
	.set MidiCC_ChannelMappingData_0x840_, 0xfd16a7
	.set PanelEvt_Handler_4_DualValueCheck_0x77_, 0xfd175e
	.set PanelEvt_Handler_4_DualValueCheck_0x377_, 0xfd1a5e
	.set PanelEvt_Handler_4_DualValueCheck_0x3A7_, 0xfd1a8e
	.set PanelEvt_Handler_4_DualValueCheck_0x427_, 0xfd1b0e
	.set PanelEvt_Handler_4_DualValueCheck_0x4A7_, 0xfd1b8e
	.set PanelEvt_Handler_4_DualValueCheck_0x527_, 0xfd1c0e
	.set PanelEvt_Handler_4_DualValueCheck_0x5A7_, 0xfd1c8e
	.set PanelEvt_Handler_4_DualValueCheck_0x628_, 0xfd1d0f
	.set PanelEvt_Handler_4_DualValueCheck_0x6A8_, 0xfd1d8f
	.set PanelEvt_Handler_4_DualValueCheck_0x728_, 0xfd1e0f
	.set PanelEvt_Handler_4_DualValueCheck_0x7A8_, 0xfd1e8f
	.set PanelEvt_Handler_4_DualValueCheck_0x828_, 0xfd1f0f
	.set PanelEvt_Handler_4_DualValueCheck_0x8A8_, 0xfd1f8f
	.set PanelEvt_Handler_4_DualValueCheck_0x928_, 0xfd200f
	.set PanelEvt_Handler_4_DualValueCheck_0x9A8_, 0xfd208f
	.set PanelEvt_Handler_4_DualValueCheck_0xA28_, 0xfd210f
	.set PanelEvt_Handler_4_DualValueCheck_0xAA8_, 0xfd218f
	.set PanelEvt_Handler_4_DualValueCheck_0xB28_, 0xfd220f
	.set PanelEvt_Handler_4_DualValueCheck_0xBA8_, 0xfd228f
	.set PanelEvt_Handler_4_DualValueCheck_0xC28_, 0xfd230f
	.set PanelEvt_Handler_4_DualValueCheck_0xCA8_, 0xfd238f
	.set PanelEvt_Handler_4_DualValueCheck_0xD28_, 0xfd240f
	.set PanelEvt_Handler_4_DualValueCheck_0xDA8_, 0xfd248f
	.set PanelEvt_Handler_4_DualValueCheck_0xE28_, 0xfd250f
	.set SeqVoice_DispatchProcess_Data_0x88_, 0xfd6d15
	.set SeqVoice_DispatchProcess_Data_0xDC_, 0xfd6d69
	.set SeqVoice_DispatchProcess_Data_0x13E_, 0xfd6dcb
	.set SeqVoice_DispatchProcess_Data_0x15F_, 0xfd6dec
	.set SeqVoice_DispatchProcess_Data_0x178_, 0xfd6e05
	.set SeqVoice_DispatchProcess_Data_0x191_, 0xfd6e1e
	.set SeqVoice_DispatchProcess_Data_0x1AB_, 0xfd6e38
	.set SeqVoice_DispatchProcess_Data_0x1C3_, 0xfd6e50
	.set SeqVoice_DispatchProcess_Data_0x1E3_, 0xfd6e70
	.set SeqVoice_DispatchProcess_Data_0x213_, 0xfd6ea0
	.set SeqVoice_DispatchProcess_Data_0x22A_, 0xfd6eb7
	.set SeqVoice_DispatchProcess_Data_0x241_, 0xfd6ece
	.set SeqVoice_DispatchProcess_Data_0x28A_, 0xfd6f17
	.set SeqVoice_DispatchProcess_Data_0x2C3_, 0xfd6f50
	.set SeqVoice_DispatchProcess_Data_0x2DA_, 0xfd6f67
	.set SeqVoice_DispatchProcess_Data_0x2F2_, 0xfd6f7f
	.set SeqVoice_DispatchProcess_Data_0x325_, 0xfd6fb2
	.set SeqVoice_DispatchProcess_Data_0x354_, 0xfd6fe1
	.set SeqVoice_DispatchProcess_Data_0x36D_, 0xfd6ffa
	.set SeqVoice_DispatchProcess_Data_0x386_, 0xfd7013
	.set Part_ProcessEntry_Data_0x19_, 0xfd72e7
	.set Part_ProcessEntry_Data_0x48_, 0xfd7316
	.set MidiSeq_PartConfigure_Data_0x08_, 0xfd7617
	.set MidiSeq_PartConfigure_Data_0x1D_, 0xfd762c
	.set MidiSeq_PartConfigure_Data_0x29_, 0xfd7638
	.set MidiSeq_PartConfigure_Data_0x35_, 0xfd7644
	.set MidiSeq_PartConfigure_Data_0x41_, 0xfd7650
	.set MidiSeq_PartConfigure_Data_0x4D_, 0xfd765c
	.set MidiSeq_PartConfigure_Data_0x4E_, 0xfd765d
	.set MidiPkt_ArpConfigChain_Data_0x34C_, 0xfd7a59
	.set MidiSysEx_ProcessBlock_0x17A_, 0xfd82b1
	.set MidiSysEx_ProcessBlock_0x19A_, 0xfd82d1
	.set MidiSysEx_ProcessBlock_0x1AB_, 0xfd82e2
	.set MidiSysEx_ProcessBlock_0x1BC_, 0xfd82f3
	.set MidiSysEx_ProcessBlock_0x1CD_, 0xfd8304
	.set MidiSysEx_ProcessBlock_0x1DD_, 0xfd8314
	.set MidiSysEx_ProcessBlock_0x1EA_, 0xfd8321
	.set DSPCfg_Data_ParamDispatch_0x1C9_, 0xfdcea0
	.set AudioInit_MixFallbackDefault_0x05_, 0xfdecef
	.set __jrt_nop_FE9709_Data_0x0C_, 0xfe9818
	.set __jrt_nop_FEA344_Data_0x0D_, 0xfea356
	.set __jrt_nop_FEA344_Data_0x91_, 0xfea3da
	.set __jrt_nop_FEA344_Data_0xBA_, 0xfea403
	.set __jrt_nop_FEA344_Data_0x189_, 0xfea4d2
	.set UIState_ProcessKeyEvent_0x3D_, 0xfea84f
	.set SeqVoice_CheckAndRet_Data_0x4A_, 0xfebca0
	.set SeqVoice_CheckAndRet_Data_0x101_, 0xfebd57
	.set ApplyProgramChangeAs_LoadReg2_0x0A_, 0xfee7e8
	.set Param_SignExtendRetu_Data_0x69_, 0xfeec84
	.set Param_SignExtendRetu_Data_0x264_, 0xfeee7f
	.set Param_SignExtendRetu_Data_0x3CB_, 0xfeefe6
	.set Param_SignExtendRetu_Data_0x4C3_, 0xfef0de
	.set Param_SignExtendRetu_Data_0x59C_, 0xfef1b7
	.set SendPartDataBlock_Data2_0x0B, 0xff0000
	.set Sprintf_Octal_ZeroFillBody_0x02, 0xff182c
	.set Debug_SWI_JumpTable_0x06_, 0xfffed8
	.set ROM_PaddingFF_0x02_, 0xfffeed
	.set ROM_PaddingFF_0x03_, 0xfffeee
	.set ROM_PaddingFF_0x04_, 0xfffeef
	.org PROGRAM_FLASH__BASE_ADDR - 0xe00000, 0xff

	.include "boot/boot_data_tables.s"

; --- SSF (Style Synthesis Format) Gate State Data ---
	.include "sequencer/ssf_gate_states.s"

; --- Instrument Sound Data & Category Metadata ---
	.include "audio/sound_data.s"

; --- Style UI Parameter Blocks & Screen Data ---
	.include "ui_widgets/style_ui_params.s"

GUI_FormatStrings:		.include "includes/gui_format_strings.s"
GUI_DisplayStructData:
	.incbin "includes/generated/gui_display_struct_data.bin"
ToneGen_ParamTable:
	.incbin "includes/generated/tonegen_param_table.bin"

; =============================================================================
; NAKA UI Descriptor Blocks (ROM E0E974-EEF587)
; Screen layouts, style selection, sequencer UI, effect editors,
; chord recognition, MIDI control, language dialogs, style bitmaps
; =============================================================================
	.include "ui_widgets/performance_style_screens.s"
	.include "ui_widgets/naka_property_descriptors.s"
	.include "ui_widgets/composer_style_convert_screens.s"
	.include "ui_widgets/naka_accomp7_widgets.s"
	.include "ui_widgets/msp_recording_screens.s"
	.include "ui_widgets/naka_screen_dispatch.s"
	.include "factory_test/test_data.s"
	.include "factory_test/fd_test_data.s"
	.include "ui/sepaout_config.s"
	.include "ui_widgets/naka_debug_proc_names.s"
	.include "ui_widgets/naka_direct_play_property_tables.s"
	.include "ui_widgets/naka_direct_play_dispatch.s"
	.include "ui_widgets/direct_play_medley_screens.s"
	.include "ui_widgets/naka_widget_tables_1.s"
	.include "ui_widgets/sequencer_exit_widgets.s"
	.include "ui_widgets/naka_effects_eq_dispatch.s"
	.include "ui_widgets/effects_sequencer_screens.s"
	.include "ui_widgets/widget_descriptors.s"
	.include "ui_widgets/naka_widget_desc_dispatch.s"
	.include "ui_widgets/midi_reverb_presets_screens.s"
	.include "ui_widgets/naka_widget_tables_2.s"
	.include "ui_widgets/sound_menu_drawbar_screens.s"
	.include "ui_widgets/naka_sound_technichord_dispatch.s"
	.include "ui_widgets/technichord_part_settings.s"
	.include "ui_widgets/technichord_string_data.s"
	.include "ui_widgets/disk_menu_file_io_screens.s"
	.include "ui_widgets/disk_warning_strings.s"
	.include "ui_widgets/block_012.s"
	.include "ui_widgets/widget_names_charmap.s"
	.include "ui_widgets/debug_naming_panel_sim.s"

; =============================================================================
; UI Widget Style Bitmaps & Dispatch (end of NAKA widget section)
; =============================================================================
	.include "ui_widgets/style_bitmaps.s"
	.include "ui_widgets/widget_dispatch.s"

; =============================================================================
; Character Encoding Tables & System Core (ROM EEF588-FC3113)
; =============================================================================
	.include "ui/char_encoding_naka_state.s"
	.include "ui/charmap_dispatch_table.s"

Boot_HaltInstruction:
	halt

Boot_PostHaltData:
	.byte 0x0e, 0x68, 0x01, 0x0e


; --- RESET Handler & Boot Sequence ---
RESET_HANDLER:
	; Hardware initialization code shared with table_data ROM
	.include "shared/boot_hw_init.s"
	; End of shared boot code (315 bytes)
	ldio 0xd2, 0x29
	ldio 0xd1, 0x00
	and_sd8b_im 0xd3, 0xcf
	and_sd8b_im 0xd3, 0xf0

Boot_InitIOPorts:
	stdi8 304, 255
	stdi8 305, 255
	stdi8 306, 3
	ldio 0x3a, 0x20
	ld xsp, 0xc00
	calr Boot_InitWorkRAM

Boot_RunSelfTest:
	call MainCPU_self_test_routines
	call Get_Firmware_Version
	cp l, 0xff
	jr nz, Boot_PostSelfTest

We_seem_to_be_running_boot_ROM_code:
	call VGA_Setup
	pushw 0x8
	pushw 0x3
	ld xwa, Bitmap_1bit_Please_Wait	; "Please Wait !!"
	ldw bc, 0x30
	ldw de, 0x50
	call Draw_FlashMemUpdate_message_bitmap

Boot_PostSelfTest:
	lds32 xwa, 0
	stda32 1033, xwa
	stdi8 1024, 2
	call TaskSched_Init
	stdi8 1024, 3
Boot_InitPeripherals:
	calr Boot_ClearConfigFlag7
	lda_dd8l XBC, 0xe4
	ld a, (xbc)
	and a, 0x8f
	or a, 0x30
	ld (xbc), a
	lda_dd8l XBC, 0xe6
	ld a, (xbc)
	and a, 0xf8
	or a, 0x3
	ld (xbc), a
	calr Detect_Region_Code
	cpdi16_24 65482, 23205
	jr z, Boot_FlashAndExtensions
	lda_24 xde, 0x00066e
	srl xde, 1
	ld xwa, 0xf980
	ld xbc, 0x1e8000
	call Copy_DE_words_from_XBC_to_XWA

Boot_FlashAndExtensions:
	call Flash_InitAllBanks
	bit_dd8 0, 0x38	;  Is the optional HD-AE5000 board present?
	jr nz, BootInit_SeqAndPanel
	calr Get_Region_Code
	cps l, 4
	call_24 nz, HDAE5000_Parport_Setup	; if it is present (and this unit was sold in
					; a specific market region), then call the
					; HDAE5000 PPI init code

; Boot initialization handler (SeqInit + CPanel scan)
BootInit_SeqAndPanel:
	call Seq_FullInit
	ei 0
	ld32_24 xhl, CPanel_InitDispatchTable
	call (xhl)
	call CPanel_ScanButtons
	stda8 1026, l
	call Get_Firmware_Version
	cp l, 0xff
	jr nz, User_didnt_request_flash_mem_update
	call Check_for_Floppy_Disk_Change
	cps hl, 0
	jr z, User_didnt_request_flash_mem_update
	cpdi8 1026, 4
	jr nz, User_didnt_request_flash_mem_update
	call FLASH_MEM_UPDATE

Boot_MainSequence_Trampoline:
	jr Boot_MainSequence_Trampoline

; ===========================================================================
; User_didnt_request_flash_mem_update - Main Boot Sequence
; ===========================================================================
; This is the main boot path after power-on self-test and flash update check.
; Initializes Sub-CPU communication, transfers firmware payload, and verifies
; the transfer succeeded. On failure, displays the "ERROR in CPU data
; transmission" dialog (Screen Group 7).
;
; Boot flow:
;   1. Initialize DMA channels for inter-CPU communication
;   2. Send 192KB Sub-CPU firmware payload
;   3. Verify payload integrity (checksum validation)
;   4. Check error flag - if set, display error dialog
;   5. Continue to main UI initialization
;
; Error handling:
;   - If SubCPU_Payload_Verify returns non-zero in HL, boot with error state
;   - Error state (WA=2) displays error dialog via ScreenGroup_Dispatch
;   - Eventually Screen Group 7 "CPU data transmission" error is shown
;
; See also:
;   - SubCPU_Send_Payload - Payload transfer routine
;   - SubCPU_Payload_Verify - Checksum verification
;   - ErrorDialog_CPUTransmissionError - Error dialog widget
; ===========================================================================
User_didnt_request_flash_mem_update:
	ldda8 a, 1026		; Load boot combo code
	extz wa
	calr Boot_HandleFactoryReset	; Reset if combo 1 + invalid checksums
	sti16_24 0x00ffca, 0x0000
	set_dd8 0, 0x28	; Release Sub-CPU from reset
	call SubCPU_Init_DMA_Channels	; Initialize DMA for inter-CPU comm
	ei 0
	calr SubCPU_Send_Payload	; Transfer 192KB Sub-CPU firmware
	calr SubCPU_Payload_Verify	; Verify payload checksum
	lds wa, 0
	call ScreenGroup_Dispatch	; Display initial boot screen (group 0)
	ei 0
	call SelfTest_FirmwareVersionCheck
	calr SubCPU_Payload_GetErrorFlag	; Check if payload transfer failed
	cps hl, 0	; HL=0: success, HL!=0: error
	jr nz, Boot_PayloadError	; Branch if error occurred
	lds wa, 1	; Success: use screen group 1
	jr Boot_DisplayScreen

; Sub-CPU payload transfer or verification failed
Boot_PayloadError:
	lds wa, 2	; Error: use screen group 2

Boot_DisplayScreen:
	call ScreenGroup_Dispatch	; Display appropriate screen group
	stdi8 1024, 6
	lds wa, 3
	call ScreenGroup_Dispatch
	stdi8 1024, 128
	sti16_24 0x00ffd4, 0x0000
	ldda8 a, 1026		; Load boot combo code
	extz wa
	calr Boot_HandleComboDisplay	; Handle combo 2 (LEDs) or combo 3 (version screen)
	lds wa, 4
	call Show_ScreenGroup	; Show screen group 4 (main UI initialization)
	calr Boot_SetConfigFlag7
	jp MainLoop

Boot_GetButtonComboCode:
	ldda8 l, 1026
	ret

Boot_ClearAllInterruptEnables:
	ldio 0xf0, 0x00
	ldio 0xe0, 0x00
	ldio 0xe1, 0x00
	ldio 0xe2, 0x00
	ldio 0xe3, 0x00
	ldio 0xe4, 0x00
	ldio 0xe5, 0x00
	ldio 0xe6, 0x00
	ldio 0xe7, 0x00
	ldio 0xe8, 0x00
	ldio 0xe9, 0x00
	ldio 0xea, 0x00
	ldio 0xeb, 0x00
	ldio 0xec, 0x00
	ldio 0xed, 0x00
	ldio 0xee, 0x00
	ldio 0xef, 0x00
	ret

; ===========================================================================
; SubCPU_Send_Payload - Transfer 192KB Sub-CPU payload from Table Data ROM
; ===========================================================================
; Entry: None (reads from 0xfffeef to check if transfer should proceed)
; Exit:  XIZ restored, payload transferred to Sub-CPU RAM
; Notes: Sends the Sub-CPU firmware payload in multiple 64KB chunks:
;        - 0x830000-0x870000 (5 x 64KB) -> Sub-CPU 0x050000-0x090000
;        - Additional data from Table Data ROM -> Sub-CPU 0x00f000-0x02f000
;        - Final 256 bytes -> Sub-CPU 0x000400 (entry point area)
;        Uses E1 bulk transfer protocol via InterCPU_E1_Bulk_Transfer
;        Includes 0x2000 and 0x100000 iteration delay loops for timing
;        Called during boot sequence after SubCPU_Init_DMA_Channels
; ===========================================================================
SubCPU_Send_Payload:
	push xiz
	cpi8_24 ROM_PaddingFF_0x04_, 0xff
	jrl nz, SubCPU_Payload_Done
	lds32 xiz, 0

SubCPU_Payload_DelayLoop_Short:
	inc 1, xiz
	cp xiz, 0x2000
	jr c, SubCPU_Payload_DelayLoop_Short
	ld xwa, 0x830000
	ld xbc, 0x10000
	ld xde, 0x50000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, 0x840000
	ld xbc, 0x10000
	ld xde, 0x60000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, 0x850000
	ld xbc, 0x10000
	ld xde, 0x70000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, 0x860000
	ld xbc, 0x10000
	ld xde, 0x80000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, 0x870000
	ld xbc, 0x10000
	ld xde, 0x90000
	call InterCPU_E1_Bulk_Transfer
	ld xiz, 0x800000
	cpi8_24 ROM_PaddingFF_0x02_, 0xff
	jr nz, SubCPU_Payload_TransferPart2
	ld xiz, 0x50000
	ld xwa, 0x3e0000
	ld xbc, 0x50000
	call SLIDE_Parse_Header
	cp hl, 0xffff
	jr nz, SubCPU_Payload_TransferPart2
	ld xiz, 0x800000

SubCPU_Payload_TransferPart2:
	ldmm_sriw 0xf9, 0x00, 0x01, 0x04, 0x04
	ld xwa, xiz
	add xwa, 0x100
	ld xbc, 0x10000
	ld xde, 0xf000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, xiz
	add xwa, 0x10100
	ld xbc, 0x10000
	ld xde, 0x1f000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, xiz
	add xwa, 0x20100
	ldw bc, 0xff00
	ld xde, 0x2f000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, xiz
	ldw bc, 0x100
	ld xde, 0x400
	call InterCPU_E1_Bulk_Transfer
	lds32 xiz, 0

SubCPU_Payload_DelayLoop_Long:
	inc 1, xiz
	cp xiz, 0x100000
	jr c, SubCPU_Payload_DelayLoop_Long

SubCPU_Payload_Done:
	pop xiz
	ret

Boot_ClearConfigFlag7:
	resda 7, 1030
	ret

Boot_SetConfigFlag7:
	setda 7, 1030
	ret

Boot_CheckConfigFlag7:
	ldcf_dd16 7, 0x06, 0x04
	scc8 c, a
	cps a, 1
	scc16 z, hl
	ret

; ===========================================================================
; Boot_HandleComboDisplay - Handle boot-time combo display modes
; ===========================================================================
; Entry: A = combo code from CPanel_CheckSpecialCombos (0-4)
; Called from Boot_DisplayScreen after subsystems are initialized.
;   Combo 2: Show firmware version on control panel LEDs
;   Combo 3: Show software version / internal build numbers screen
;   Others: return (no special display)
; ===========================================================================
Boot_HandleComboDisplay:
	cps a, 2
	jr nz, Boot_HandleComboDisplay_Check3
	; --- Combo 2: Firmware version on LEDs ---
	call Get_Firmware_Version	; Returns version byte in L (0x0a = v10)
	and l, 0xf
	extz hl
	lda_24 xbc, LED_patterns_indicating_firmware_version		; LED_patterns_indicating_firmware_version table
	ld_srib3 C, 0x07, 0xe4, 0xec	; Read LED pattern from table
	extz bc
	lds wa, 7
	call Set_LEDs			; Display version on control panel LEDs
	push xiz
	call CPanel_Poll		; Poll control panel (keep LEDs updated)
	pop xiz
	ret

Boot_HandleComboDisplay_Check3:
	cps a, 3
	ret nz
	; --- Combo 3: Software version screen ---
	ldw wa, 0xf0
	call SoundCtrl_SendCommand		; Display SOFT VERSION screen
	ret

Boot_ParseTableDataTimestamp:
	ld xwa, 0x9fffc4
	push xwa
	call ParseInt16
	inc 4, xsp
	ret

Boot_GetSystemPointer:
	ldda16 xhl, 1028
	ret

Boot_ParseSubCPUTimestamp:
	ld xwa, 0x87fff5
	push xwa
	call ParseInt16
	inc 4, xsp
	ret

; ===========================================================================
; Boot_HandleFactoryReset - Factory reset if combo 1 AND checksums invalid
; ===========================================================================
; Entry: A = combo code from CPanel_CheckSpecialCombos
; If combo code == 1 (Initial Setting) AND DRAM[0xFFCA] != 0x5aa5
; (payload checksums invalid, e.g. after Flash ROM replacement),
; zero-fills all work DRAM and SRAM, then restarts the boot sequence.
; Otherwise returns immediately (normal boot continues).
; ===========================================================================
Boot_HandleFactoryReset:
	cpdi16_24 65482, 23205	; DRAM[0xFFCA] == 0x5aa5 (valid checksums)?
	ret z			; Yes -> checksums valid, skip reset
	cps a, 1		; Combo code == 1 (Initial Setting)?
	ret nz			; No -> not requesting reset, return
	; --- Factory Reset: clear all DRAM and SRAM ---
	call ToneGen_FlashReadAndRestore
	ei 7
	calr Boot_ClearAllInterruptEnables	; Clear all interrupt enables
	ld xbc, 0x400

FactoryReset_ClearDRAM:
	lds32 xwa, 0
	st_dpil XWA, 0xe6
	cp xbc, 0x100000
	jr c, FactoryReset_ClearDRAM
	ld xbc, 0x1e0000

FactoryReset_ClearSRAM:
	lds32 xwa, 0
	st_dpil XWA, 0xe6
	cp xbc, 0x200000
	jr c, FactoryReset_ClearSRAM
	sti16_24 0x00ffca, 0x5aa5
	jp Boot_InitIOPorts
FactoryReset_TrailingByte:
	ret

Boot_ReadFDCStatus:
	ldda8 l, 36458
	ret

; =============================================================================
; Shared boot routines (Detect_Region_Code, Get_Region_Code, handlers)
; Uses REGION_CODE_VAR and BOOT_ENTRY_POINT defined at top of file
; =============================================================================
	.include "shared/boot_routines.s"

; =============================================================================
; Boot_CallInitHandlers - Call initialization handlers from table (Shared)
; Configuration for maincpu: byte comparison, local indirect call helper
; =============================================================================
.equ INIT_FLAG_COMPARE_WORD, 0	; maincpu uses byte comparison
.equ INDIRECT_CALL_HELPER, AudioMix_WriteChannelGroup	; indirect call helper in maincpu

	.include "shared/boot_call_init_handlers.s"

; --- System Handlers (interrupts, NMI, UI state machine, task scheduler) ---
	.include "boot/system_handlers.s"

; =============================================================================
; VGA Initialization Code - Shared with table_data ROM
; Uses macros and code from ../shared/vga_init.asm
; =============================================================================

; --- VGA Initialization & Display Subsystem ---
	.include "shared/vga_init.s"
	.include "display/scoop_display.s"
	.include "display/scoop_editor_data.s"
	.include "audio/semenu_routines.s"
	.include "audio/sound_editor_ui.s"

; VoiceSynth command handler case 0
VoiceSynth_CmdCase0:
	.byte 0xc2, 0x04, 0xdd, 0x03, 0x3f, 0x00, 0xb0, 0xf6
	.byte 0x43, 0x14, 0x00, 0x28, 0x00, 0xb3, 0xe8, 0x0e
; VoiceSynth command handler case 1
VoiceSynth_CmdCase1:
; Get resource info based on resource type (WA 0-9)
; Uses offset table at RESOURCE_INFO_HANDLER_OFFSETS (10 entries)
GetResouceInfo:
	cp wa, 0x9
	ret ugt
	add wa, wa
	lda_24 xix, RESOURCE_INFO_HANDLER_OFFSETS
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, RESOURCE_INFO_HANDLERS
	jp_dri 8, 0x07, 0xf0, 0xe0
; Resource info handlers - 10 handlers for different resource types
RESOURCE_INFO_HANDLERS:
	ldada xwa, 63872
	ld (xbc), xwa
	ldada xwa, 65470
	ld xde, xwa
	inc 2, xde
	ldada xwa, 63872
	sub xde, xwa
	ld (xbc + 4), xde
	ret

ResInfo_GetSRAMBankRange:
	lda_24 xwa, 0x1e7800
	ld (xbc), xwa
	lda_24 xwa, 0x1e7800
	ld xde, xwa
	lda_24 xwa, 0x1e8000
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetUserAreaRange:
	lda_24 xwa, 0x1ed350
	ld (xbc), xwa
	lda_24 xwa, 0x1ed350
	ld xde, xwa
	lda_24 xwa, 0x200000
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetFlashBankRange:
	lda_24 xwa, 0x1e0000
	ld (xbc), xwa
	lda_24 xwa, 0x1e0000
	ld xde, xwa
	lda_24 xwa, 0x1e7800
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetTableDataInfo:
	ld xwa, 0x3d3000
	ld (xbc), xwa
	ld xwa, 0x400
	ld (xbc + 4), xwa
	ret

ResInfo_GetSndParamRange:
	lda_24 xwa, 0x0ab000
	ld (xbc), xwa
	ld xwa, 0x5000
	ld (xbc + 4), xwa
	ret

ResInfo_GetVoiceBankRange:
	lda_24 xwa, 0x0b0000
	ld (xbc), xwa
	lda_24 xwa, 0x0b0000
	ld xde, xwa
	lda_24 xwa, 0x0fd800
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetToneGenRange:
	lda_24 xwa, 0x094800
	ld (xbc), xwa
	lda_24 xwa, 0x094800
	ld xde, xwa
	lda_24 xwa, 0x0ab000
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetMspSettingsRange:
	lda_24 xwa, 0x1e8800
	ld (xbc), xwa
	lda_24 xwa, 0x1e8800
	ld xde, xwa
	lda_24 xwa, 0x1ec400
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetResourceListPtr:
	lda_24 xwa, FDTest_String_TestTitleFunc_0x28E_
	ld (xbc), xwa
	lds32 xwa, 0
	ld (xbc + 4), xwa
	ret

ResInfo_NullHandler:
	ret

rcm_ld_XAPR_j:
	jp FloppyDisk_LoadNoteEvents

rcm_sv_XAPR_j:
	jp FloppyDisk_ComputeToneParams

SetSepaOutMode:
	lda xsp, (xsp - 20)
	ld xiy, SepaOut_Config_0
	lda xix, (xsp + 16)
	ldiw
	ldiw
	ld xiy, SepaOut_Config_0_0x04_
	lda xix, (xsp + 12)
	ldiw
	ldiw
	ld xiy, SepaOut_Config_0_0x08_
	lda xix, (xsp + 8)
	ldiw
	ldiw
	ld xiy, SepaOut_Config_0_0x0C_
	lda xix, (xsp + 4)
	ldiw
	ldiw
	ld xiy, SepaOut_Config_0_0x10_
	ld xix, xsp
	ldiw
	ldiw
	cps wa, 3
	jrl z, SetSepaOut_Mode3
	cps wa, 2
	jrl z, SetSepaOut_Mode2
	cps wa, 1
	jr z, SetSepaOut_Mode1
	cps wa, 0
	jrl nz, FileIO_SendCommand_Return
	ld (xsp + 17), 0x14
	lda xwa, (xsp + 16)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x14
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 17), 0x13
	lda xwa, (xsp + 16)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x13
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 17), 0x16
	lda xwa, (xsp + 16)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x16
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	jrl FileIO_SendCommand_Return

SetSepaOut_Mode1:
	ld (xsp + 13), 0x14
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x14
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 17), 0x13
	lda xwa, (xsp + 16)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x13
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 17), 0x16
	lda xwa, (xsp + 16)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x16
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	jrl FileIO_SendCommand_Return

SetSepaOut_Mode2:
	ld (xsp + 13), 0x14
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x14
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 13), 0x13
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x13
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 13), 0x16
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x16
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	jr FileIO_SendCommand_Return

SetSepaOut_Mode3:
	ld (xsp + 13), 0x14
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 1), 0x14
	lda xwa, (xsp)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 13), 0x13
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 5), 0x13
	lda xwa, (xsp + 4)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 13), 0x16
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 5), 0x16
	lda xwa, (xsp + 4)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM

FileIO_SendCommand_Return:
	lda xsp, (xsp + 20)
	ret

fopen_ext:
	jp FileIO_OpenWithMode

fwrite_ext:
	jp FileIO_WriteByte_Impl

fread_ext:
	jp FileIO_ReadBlock

fclose_ext:
	jp FileIO_CloseHandle

ferror_ext:
	jp FileIO_ReturnError

rot_rdq_X:
	jp TaskSched_YieldToQueue

set_flg_X:
	jp TaskSched_SignalEvent

wai_flg_X:
	jp TaskSched_WaitForEvent

sig_sem_X:
	jp Audio_Lock_Release

preq_sem_X:
	jp AudioLock_TryAcquire

wai_sem_X:
	jp Audio_Lock_Acquire

ref_sem_X:
	jp AudioLock_GetCount

snd_msg_X:
	jp TaskMsg_Send

rcv_msg_X:
	jp TaskMsg_Receive

prcv_msg_X:
	jp TaskMsg_TryReceive

get_tid_X:
	jp TaskSched_GetCurrentGroup

pdly_tim_X:
	jp TaskSched_DelayTicks

PlayHalt:
	dec 2, xsp
	ld (xsp), a
	call SeqBuf_Init
	call NoteMap_SendAllNotesOff
	call Part_ReinitAllActive
	call AccWrap_PlayModeDispatch
	cp (xsp), 0x0
	jr z, PlayHalt_SkipSetFlag
	setda 2, 10407

PlayHalt_SkipSetFlag:
	call AccompSeq_StopSequence
	call AudioInit_RefreshToneBank
	call NoteMap_ProcessAndMerge
	call Voice_InitializeAll
	call Voice_InitTablePair
	call Voice_InitTableGroup
	call MIDI_SendAllSoundOff
	call MidiThru_Enable
	inc 2, xsp
	ret

PlayStandBy:
	bitda 2, 10407
	jr z, PlayStandBy_SkipClearFlag
	resda 2, 10407

PlayStandBy_SkipClearFlag:
	resda 3, 10407
	call SeqAcc_InitPlaybackState
	jp MidiThru_Disable

EditSwRefresh:
	call CPanel_InitButtonState_SaveRegs
	call RefreshSwEvent
	jp RefreshApTask

putc_mtx_bf_X:
	extz wa
	pushw wa
	call SeqBuf_MidiOut_WriteByte
	inc 2, xsp
	ret

putc_mrx_bf_X:
	extz wa
	pushw wa
	call SeqMain_WriteByte
	inc 2, xsp
	ret

midi_out_en_X:
	jp MIDI_SC0_TX_DISPATCH

GetAdr_sqbtof:
	ldada xhl, 1052
	ret

GetAdr_sq_beadt:
	ldada xhl, 1051
	ret

GetAdr_sqsrtc:
	ldada xhl, 1057
	ret

GetAdr_rtmcfg:
	ldada xhl, 10407
	ret

SetGlobalError:
	stda8 32578, a
	ret

malloc_X:
	pushw wa
	call Malloc
	inc 2, xsp
	ret

free_X:
	push xwa
	call Free
	inc 4, xsp
	ret


; --- Wallpaper & Demo Routines ---
	.include "ui/setwall_routines.s"
	.include "ui/ui_playback_modes.s"
	.include "demo/demo_routines.s"
	.include "demo/demo_seq_bridge.s"
	.include "sequencer/smf_playback.s"
	.include "sequencer/smf_tonegen_core.s"
; --- SMF Event Processing, Sequencer UI & Engine ---
	.include "sequencer/smf_event_processor.s"
	.include "sequencer/seq_audio_mode.s"
	.include "sequencer/rhythm_routines.s"
	.include "sequencer/accompaniment_engine.s"
Voice_InitBankDataSafe:
	push xiz
	call Voice_InitBankData
	pop xiz
	ret

Voice_InitBankDataSafe_Alt1:
	push	xiz
	call	Voice_BankLookupCode
	pop	xiz
	ret
	push	xiz
	call	Voice_RefreshBankData
	pop	xiz
	ret
	push	xiz
	call	Voice_InitBankTables
	pop	xiz
	ret

Voice_InitBankTables:
	ld xiy, Voice_BankHeaderDefaults
	ld xix, 0x1e8800
	ldw bc, 0x10
	ldirw
	ldb a, 0xc

Voice_InitBankTables_Loop:
	ld xiy, Voice_BankSlotZeroInit
	ldw bc, 0x8
	ldirw
	dec 1, a
	jr nz, Voice_InitBankTables_Loop
	ld xiy, BLOCK_OF_64_ZEROES
	ld xix, 0x1e8a00
	ldw bc, 0x20
	ldirw
	ld xiy, HEADER__COMPILE_BANKS
	ld xix, 0x1e8a40
	ldw bc, 0x20
	ldirw
	ld xiy, HEADER__USER_BANKS
	ld xix, 0x1e8a80
	ldw bc, 0x20
	ldirw
	ld xix, 0x1e8b00
	ldb a, 0x39

Voice_InitBankTables_SlotLoop:
	ld xiy, Voice_SlotTemplate
	ldw bc, 0x80
	ldirw
	dec 1, a
	jr nz, Voice_InitBankTables_SlotLoop
	stdi16 32280, 57
	ret

	.include "audio/voice_bank_defaults.s"
Voice_InitBankData:
	calr Voice_InitBankTables
	ld xiy, Voice_FactoryPresetData
	ld xix, 0x1e8820
	ldw bc, 0xf0
	ldirw
	ld xix, 0x1e8a00
	ld xiy, BLOCK_OF_64_ZEROES
	ldw bc, 0x60
	ldirw
	ld xix, 0x1e8b00
	ld xiy, MSP_FACTORY_DEFAULTS
	ldw bc, 0xa80
	ldirw
	calr CountAvailableVoiceSlots
	ret

Voice_BankLookupCode:
	.byte 0x45, 0x00, 0x88, 0x1e, 0x00, 0xb5, 0x00, 0x48
	.byte 0xbd, 0x01, 0x00, 0x00, 0xbd, 0x02, 0x00, 0x4b
	ret

Voice_RefreshBankData:
	calr Voice_ComputeAllocSize
	ret

Voice_ResetToFactoryBanks:
	ldw wa, 0xa
	ld xhl, 0x7aec
	ldw bc, 0xff
	ldw de, 0xf6
	calr Voice_SetBankParams
	ld xhl, 0x7bec
	calr Voice_SetBankParams
	calr Voice_ReinitIfBankCountNonzero
	calr Voice_ReinitIfBitFlagSet
	calr CountAvailableVoiceSlots
	ret

Voice_SetBankParams:
	ld (xhl + 256), wa
	ld (xhl + 2), bc
	ld (xhl + 4), wa
	ld (xhl + 6), wa
	ld (xhl + 8), de
	ret

Voice_ReinitIfBankCountNonzero:
	ld xiy, 0x1e8800
	add xiy, 0xe
	ld wa, (xiy)
	cps wa, 0
	jr z, Voice_ReinitIfBankCount_Done
	calr Voice_InitBankData

Voice_ReinitIfBankCount_Done:
	ret

Voice_ReinitIfBitFlagSet:
	ld xiy, 0x1e8800
	add xiy, 0xa
	ld a, (xiy)
	bit 0, a
	jr z, Voice_ReinitIfBitFlag_Done
	calr Voice_InitBankData

Voice_ReinitIfBitFlag_Done:
	ret

CountAvailableVoiceSlots:
	ldw wa, 0x39
	ldw de, 0x38

CountVoiceSlots_Loop:
	ld hl, de
	calr Voice_GetSlotAddress
	bitm 7, (xhl)
	jr z, CountVoiceSlots_NotUsed
	dec 1, wa

CountVoiceSlots_NotUsed:
	dec 1, de
	cp de, 0xffff
	jr z, CountVoiceSlots_Done
	jr CountVoiceSlots_Loop

CountVoiceSlots_Done:
	stda16 32280, xwa
	ret

Voice_GetSlotAddress:
	and xhl, 0xffff
	sla xhl, 8
	add xhl, 0x1e8b00
	ret

Voice_ComputeAllocSize:
	ld xhl, 0x3c00
	ld xiy, 0x1e8800
	add xiy, 0x200
	add xiy, 0x3800
	ldb c, 0x39

Voice_AllocSize_Loop:
	cps c, 0
	jr z, Voice_AllocSize_Done
	ld a, (xiy)
	bit 7, a
	jr nz, Voice_AllocSize_Done
	sub xhl, 0x100
	sub xiy, 0x100
	dec 1, c
	jr Voice_AllocSize_Loop

Voice_AllocSize_Done:
	ld xwa, xhl
	add xwa, 0x3ff
	and xwa, 0xfffffc00
	srl xwa, 4
	ld xiy, 0x1e881c
	ld (xiy), wa
	calr CountAvailableVoiceSlots
	ret

Voice_FactoryPresetData:
	.incbin "includes/generated/voice_factory_presets.bin"

; F6F60F:
	.zero 32

; MSP_FACTORY_DEFAULTS:	
	.include "msp_factory_defaults.s"
	.include "sequencer/seq_event_playback.s"
	.include "midi/computer_interface_config.s"
	.include "midi/ac_listener_handlers.s"
	.include "midi/sysex_routines.s"
	.include "midi/param_load_routines.s"
	.include "ui/ui_control_panel.s"
	.include "audio/presentation_sound_nav.s"
	.include "ui/ui_window_procs.s"
	exts	xwa
	add	xwa, xhl
	add	xde, xwa
	bitm	7, (xde)
	jr	z, 4
	resm	6, (xde)
	jr	2
	setm	6, (xde)
	incm8	1, (xsp+24)
	ld	xwa, (xsp+12)
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	sra	xwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+16)
	add	(xbc+2), wa
	lds32	xwa, 1
	add	(xsp+20), xwa
	ld	xwa, (xsp+20)
	cp	xwa, (xsp+8)
	jrl	le, -249
	jrl	330
	ld	xwa, (xsp+8)
	sla	xwa, 0
	ld	xbc, (xsp+4)
	call	Math_DivideSigned32
	ld	xiz, xhl
	ld	xwa, (xsp+16)
	ld	xbc, xiz
	call	Math_MultiplyAccumulate
	ld	(xsp+16), xhl
	ld	xbc, (xsp+34)
	ld	xwa, xbc
	inc	2, xwa
	ld	(xsp+34), xwa
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+8), xwa
	sla	xwa, 0
	ld	(xsp+8), xwa
	ld	xwa, 32768
	add	(xsp+8), xwa
	lds32	xwa, 0
	ld	(xsp+20), xwa
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, 255
	cp	(xsp+24), 3
	jr	ule, 7
	ld	(xsp+24), 0
	jrl	206
	cp	(xsp+24), 1
	jrl	ugt, 196
	ld8_24	l, 257962
	ld	xwa, (xsp+34)
	ld	wa, (xwa)
	exts	xwa
	ld	xde, xwa
	sll	xde, 2
	add	xde, xwa
	sll	xde, 6
	cps	l, 2
	jrl	z, 146
	cps	l, 1
	jr	z, 117
	cps	l, 0
	jrl	nz, 160
	ld	xhl, xbc
	ld	iy, (xsp+50)
	ld	wa, (xbc)
	exts	xwa
	add	xwa, xde
	lda_24	xix, 277504
	add	xix, xwa
	cpw	(xsp+50), 245
	jr	z, 30
	andmi8	(xix), 96
	ld	wa, iy
	and	wa, 159
	add	(xix), a
	ld	de, iy
	and	de, 128
	ld	a, (xix)
	and	a, 128
	extz	wa
	cp	wa, de
	jr	nz, 54
	jr	105
	ld32_24	xiy, 197714
	ld	de, (xhl)
	exts	xde
	ld	wa, (xhl+2)
	exts	xwa
	ld	xhl, xwa
	sll	xhl, 2
	add	xhl, xwa
	sll	xhl, 6
	add	xhl, xde
	add	xiy, xhl
	andmi8	(xix), 96
	ld	a, (xiy)
	and	a, 159
	add	(xix), a
	ld	e, (xiy)
	and	e, 128
	ld	a, (xix)
	and	a, 128
	cp	a, e
	jr	z, 53
	xormi8	(xix), 96
	jr	48
	ld	wa, (xbc)
	exts	xwa
	add	xwa, xde
	lda_24	xde, 277504
	add	xde, xwa
	bitm	7, (xde)
	jr	z, 4
	resm	5, (xde)
	jr	27
	setm	5, (xde)
	jr	23
	ld	wa, (xbc)
	exts	xwa
	add	xwa, xde
	lda_24	xde, 277504
	add	xde, xwa
	bitm	7, (xde)
	jr	z, 4
	resm	6, (xde)
	jr	2
	setm	6, (xde)
	incm8	1, (xsp+24)
	ld	xwa, (xsp+16)
	add	(xsp+8), xwa
	ld	xde, (xsp+8)
	sra	xde, 0
	ld	xwa, (xsp+34)
	ld	(xwa), de
	ld	xwa, (xsp+12)
	add	(xbc), wa
	lds32	xwa, 1
	add	(xsp+20), xwa
	ld	xwa, (xsp+20)
	cp	xwa, (xsp+4)
	jrl	le, -255
	lda	xwa, (xsp+38)
	ld	xbc, (xsp+30)
	ld	bc, (xbc)
	ld	(xwa+2), bc
	ld	xbc, (xsp+56)
	ld	bc, (xbc)
	ld	(xwa), bc
	ld	xbc, (xsp+52)
	ld	bc, (xbc)
	ld	(xwa+4), bc
	ld	xbc, (xsp+26)
	ld	bc, (xbc)
	ld	(xwa+6), bc
	calr	39507
	pop	xiz
	lda	xsp, (xsp+56)
	ret
	dec	2, xsp
	push	xiz
	ld	(xsp+4), bc
	ld	xiz, xwa
	calr	38931
	cps	hl, 0
	jr	z, 29
	ld8_24	a, 257960
	st8_24	257962, a
	cpdi16_24	197710, 0
	jr	z, 51
	ld	xwa, xiz
	ld	bc, (xsp+4)
	calr	78
	jr	41
	ldw	wa, 16
	calr	38654
	ld	xwa, xhl
	lda_24	xbc, 16452973
	ld	(xwa), xbc
	ld	xiy, xiz
	lda	xix, (xwa+4)
	lds	bc, 4
	ldirw
	ld	bc, (xsp+4)
	ld	(xwa+12), bc
	ld8_24	c, 257960
	ld	(xwa+14), c
	calr	38403
	pop	xiz
	inc	2, xsp
	ret
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	ld	de, (xbc+12)
	ld	c, (xbc+14)
	st8_24	257962, c
	cpdi16_24	197710, 0
	ret	z
	ld	bc, de
	calr	1
	ret
	lda	xsp, (xsp-18)
	pushw	iz
	ld	(xsp+14), bc
	ld	(xsp+16), xwa
	ld	xwa, (xsp+16)
	inc	2, xwa
	ld	(xsp+2), xwa
	cpw	(xwa), 0
	jr	ge, 7
	ld	xwa, (xsp+2)
	ldw	(xwa), 0
	ld	xwa, (xsp+16)
	cpw	(xwa), 0
	jr	ge, 4
	ldw	(xwa), 0
	ld	xwa, (xsp+16)
	lda	xhl, (xwa+4)
	cpw	(xhl), 320
	jr	lt, 4
	ldw	(xhl), 319
	ld	xwa, (xsp+16)
	lda	xix, (xwa+6)
	cpw	(xix), 240
	jr	lt, 4
	ldw	(xix), 239
	ld	de, (xix)
	ld	xwa, (xsp+2)
	ld	iz, (xwa)
	lda	xwa, (xsp+10)
	lda	xbc, (xsp+6)
	lda	xiy, (xbc+2)
	ld	(xwa+2), iz
	cp	de, iz
	jr	nz, 20
	ld	xde, (xsp+16)
	ld	de, (xde)
	ld	(xwa), de
	ld	de, (xhl)
	ld	(xbc), de
	ld	de, (xix)
	ld	(xiy), de
	ld	de, (xsp+14)
	jr	110
	ld	xde, (xsp+16)
	ld	de, (xde)
	ld	(xwa), de
	ld	de, (xhl)
	ld	(xbc), de
	ld	xde, (xsp+2)
	ld	de, (xde)
	ld	(xiy), de
	ld	de, (xsp+14)
	calr	61759
	lda	xwa, (xsp+10)
	ld	xbc, (xsp+16)
	lda	xde, (xbc+6)
	ld	bc, (xde)
	ld	(xwa+2), bc
	lda	xbc, (xsp+6)
	ld	de, (xde)
	ld	(xbc+2), de
	ld	de, (xsp+14)
	calr	61731
	lda	xwa, (xsp+10)
	ld	xhl, (xsp+16)
	ld	bc, (xhl+2)
	ld	(xwa+2), bc
	ld	bc, (xhl)
	ld	(xwa), bc
	lda	xbc, (xsp+6)
	ld	de, (xhl)
	ld	(xbc), de
	ld	de, (xhl+6)
	ld	(xbc+2), de
	ld	de, (xsp+14)
	calr	61696
	lda	xwa, (xsp+10)
	ld	xbc, (xsp+16)
	lda	xde, (xbc+4)
	ld	bc, (xde)
	ld	(xwa), bc
	lda	xbc, (xsp+6)
	ld	de, (xde)
	ld	(xbc), de
	ld	de, (xsp+14)
	calr	61670
	ld	xwa, (xsp+16)
	calr	39144
	popw	iz
	lda	xsp, (xsp+18)
	ret

DrawText_QueueOrDirect:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawText_QueueDeferred
	ld8_24 a, 0x03efa8
	st8_24 0x03efaa, a
	cpdi16_24 197710, 0
	jrl z, DrawText_PopAndReturn
	ld xwa, (xsp + 28)
	push xwa
	pushm (xsp + 30)
	pushm (xsp + 30)
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	calr TextRender_BeginDraw
	jr DrawText_PopAndReturn

DrawText_QueueDeferred:
	ld xwa, (xsp + 8)
	push xwa
	call Strlen
	inc 4, xsp
	inc 1, hl
	ld wa, hl
	calr DrawQueue_Alloc
	ld (xsp + 4), xhl
	ldw wa, 0x1e
	calr DrawQueue_Alloc
	ld xiz, xhl
	lda_24 xwa, DrawText_PopAndReturn_0x07_
	ld (xhl), xwa
	ld xwa, (xsp + 16)
	ld xiy, xwa
	lda xix, (xhl + 4)
	lds bc, 4
	ldirw
	ld xwa, (xsp + 12)
	ld xiy, xwa
	lda xix, (xhl + 12)
	ldiw
	ldiw
	ld xbc, (xsp + 4)
	ld (xhl + 16), xbc
	ld xwa, (xsp + 8)
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 28)
	ld (xiz + 20), xwa
	ld wa, (xsp + 26)
	ld (xiz + 24), wa
	ld wa, (xsp + 24)
	ld (xiz + 26), wa
	ld8_24 a, 0x03efa8
	ld (xiz + 28), a
	ld xwa, xiz
	calr DisplayCmd_DequeueAndExecute

DrawText_PopAndReturn:
	pop xiz
	lda xsp, (xsp + 16)
	retd 0x8
	push xiz
	ld xiz, xwa
	lda xhl, (xiz + 4)
	lda xbc, (xiz + 12)
	ld xiy, (xiz + 20)
	ld ix, (xiz + 24)
	ld de, (xiz + 26)
	ld a, (xiz + 28)
	st8_24 0x03efaa, a
	cpdi16_24 197710, 0
	jr z, DrawText_DeferredFreeAndReturn
	push xiy
	pushw ix
	pushw de
	ld xde, (xiz + 16)
	ld xwa, xhl
	calr TextRender_BeginDraw

DrawText_DeferredFreeAndReturn:
	ld xwa, (xiz + 16)
	calr DrawFunc_Return
	pop xiz
	ret

TextRender_BeginDraw:
	st_dri3b L, 0xfd, 0xc6, 0xfe
	push xiz
	st_dri3l XDE, 0xfd, 0x36, 0x01
	st_dri3l XWA, 0xfd, 0x3a, 0x01
	ld_sril XWA, (xsp + 0x0136)
	cp (xwa), 0x0
	jrl z, TextRender_PopAndReturn
	ld_sril XWA, (xsp + 0x013a)
	inc 2, xwa
	ld (xsp + 34), xwa
	cpw (xwa), 0x0
	jr ge, TextRender_ClampYOrigin
	ld xwa, (xsp + 34)
	ldw (xwa), 0x0

TextRender_ClampYOrigin:
	ld_sril XWA, (xsp + 0x013a)
	cpw (xwa), 0x0
	jr ge, TextRender_ClampXOrigin
	ldw (xwa), 0x0

TextRender_ClampXOrigin:
	ld_sril XWA, (xsp + 0x013a)
	inc 4, xwa
	cpw (xwa), 0x140
	jr lt, TextRender_ClampXRight
	ldw (xwa), 0x13f

TextRender_ClampXRight:
	ld_sril XWA, (xsp + 0x013a)
	lda xde, (xwa + 6)
	cpw (xde), 0xf0
	jr lt, TextRender_SetupColorAndFont
	ldw (xde), 0xef

TextRender_SetupColorAndFont:
	ld xiy, xbc
	st_dri3b D, 0xfd, 0x2a, 0x01
	ldiw
	ldiw
	ld_sril XIX, (xsp + 0x0146)
	or xix, xix
	jr nz, TextRender_ClampNullXStart
	dec_sriw 2, 0xfd, 0x2c, 0x01

TextRender_ClampNullXStart:
	st_dri3b C, 0xfd, 0x2a, 0x01
	cpw (xhl), 0x0
	jr ge, TextRender_ClampNullYStart
	ldw (xhl), 0x0

TextRender_ClampNullYStart:
	lda xbc, (xhl + 2)
	cpw (xbc), 0x0
	jr ge, TextRender_LoadFontData
	ldw (xbc), 0x0

TextRender_LoadFontData:
	ld xwa, 0x945c00
	ld (xsp + 4), xwa
	ld xwa, xix
	sll xwa, 4
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 12)
	ld xiy, (xwa + 8)
	or xiz, xiz
	jr nz, TextRender_StoreGlyphPos
	ld wa, (xwa)
	ld (xsp + 20), wa
	ld xwa, (xsp + 4)
	ld wa, (xwa + 6)
	ld (xsp + 22), wa
	jr TextRender_SetupGlyph

TextRender_StoreGlyphPos:
	ld (xsp + 8), xiz

TextRender_SetupGlyph:
	ld (xsp + 12), xiy
	st_dri3b H, 0xfd, 0x2e, 0x01
	lda xiy, (xiz + 2)
	ld wa, (xbc)
	ld (xiy), wa
	ld wa, (xhl)
	ld (xiz), wa
	ld wa, (xhl)
	dec 1, wa
	ld (xiz + 4), wa
	ld xwa, (xsp + 4)
	ld hl, (xwa + 2)
	add hl, (xbc)
	lda xbc, (xiz + 6)
	ld wa, hl
	ld (xbc), hl
	or xix, xix
	jr nz, TextRender_HasCustomFont
	dec 1, wa
	ld (xbc), wa

TextRender_HasCustomFont:
	ld xwa, (xsp + 34)
	ld wa, (xwa)
	cp (xiy), wa
	jr ge, TextRender_DefaultFontWidth
	ld (xiy), wa

TextRender_DefaultFontWidth:
	ld wa, (xde)
	cp (xbc), wa
	jr le, TextRender_CustomFontWidth
	ld (xbc), wa

TextRender_CustomFontWidth:
	ld_sril XWA, (xsp + 0x0136)
	push xwa
	lda xwa, (xsp + 42)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 38)
	ld (xsp + 30), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 12)
	or xwa, xwa
	jr nz, TextRender_ProcessStringLoop
	ld xwa, (xsp + 30)
	push xwa
	call Strlen
	inc 4, xsp
	ld wa, (xsp + 20)
	mul xwa, xhl
	jr TextRender_AddToDrawPos

TextRender_ProcessStringLoop:
	ld xwa, (xsp + 30)
	cp (xwa), 0x0
	jr z, TextRender_MaxWidthReached

TextRender_CharWidthAccum:
	ld xwa, (xsp + 30)
	ld_spib C, 0xe0
	ld (xsp + 30), xwa
	sub c, 0x20
	extz bc
	sla bc, 2
	ld xwa, (xsp + 8)
	exts xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld (xsp + 20), wa
	ld xwa, (xsp + 30)
	cp (xwa), 0x0
	jr nz, TextRender_CharWidthAccum

TextRender_MaxWidthReached:
	ld wa, (xsp + 20)

TextRender_AddToDrawPos:
	add_sriw_mr WA, 0xfd, 0x32, 0x01
	st_dri3b W, 0xfd, 0x2e, 0x01
	lda xde, (xwa + 2)
	ld_sril XBC, (xsp + 0x013a)
	ld bc, (xbc + 2)
	cp (xde), bc
	jr ge, TextRender_ClampGlyphTop
	ld (xde), bc

TextRender_ClampGlyphTop:
	ld de, (xwa)
	ld_sril XBC, (xsp + 0x013a)
	cp de, (xbc)
	jr ge, TextRender_ClampGlyphLeft
	ld bc, (xbc)
	ld (xwa), bc

TextRender_ClampGlyphLeft:
	lda xde, (xwa + 4)
	ld_sril XBC, (xsp + 0x013a)
	ld bc, (xbc + 4)
	cp (xde), bc
	jr le, TextRender_ClampGlyphRight
	ld (xde), bc

TextRender_ClampGlyphRight:
	lda xde, (xwa + 6)
	ld_sril XBC, (xsp + 0x013a)
	ld bc, (xbc + 6)
	cp (xde), bc
	jr le, TextRender_ClampGlyphBottom
	ld (xde), bc

TextRender_ClampGlyphBottom:
	ld_sriw BC, (xsp + 0x0142)
	cp bc, 0xf7
	call_24 nz, ColorBlit2_Impl
	lda xwa, (xsp + 38)
	ld (xsp + 30), xwa
	cp (xwa), 0x0
	jrl z, TextRender_Finalize

TextRender_CharEncodeAndDraw:
	ld xhl, (xsp + 30)
	ld c, (xhl)
	extz bc
	lda_24 xde, Data_CharMapFormatBlock_0x14_
	ld_srib3 C, 0x07, 0xe8, 0xe4
	ld (xhl), c
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 12)
	or xwa, xwa
	jr nz, TextRender_CustomFontCharDraw
	ld bc, (xbc + 2)
	ld a, (xhl)
	sub a, 0x20
	extz wa
	mrdw3 0x9f, 0x16, 0x40
	mul xwa, xbc
	ld (xsp + 16), xwa
	ld xwa, (xsp + 12)
	add (xsp + 16), xwa
	jr TextRender_BeginScanLines

TextRender_CustomFontCharDraw:
	ld xwa, (xsp + 30)
	ld c, (xwa)
	sub c, 0x20
	extz bc
	sla bc, 2
	ld xwa, (xsp + 8)
	exts xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld (xsp + 20), wa
	ld (xsp + 22), wa
	srl wa, 3
	inc 1, wa
	ld (xsp + 22), wa
	ld wa, (xbc + 2)
	extz xwa
	ld (xsp + 16), xwa
	ld xwa, (xsp + 12)
	add (xsp + 16), xwa

TextRender_BeginScanLines:
	ldw (xsp + 26), 0x0
	cpw (xsp + 22), 0x0
	jrl ule, TextRender_AdvanceStringPointer

TextRender_ScanLineLoop:
	ld bc, (xsp + 26)
	sll bc, 3
	ld wa, (xsp + 20)
	sub wa, bc
	ld (xsp + 24), wa
	cpw (xsp + 24), 0x8
	jr c, TextRender_SelectDrawMode
	ldw (xsp + 24), 0x8

TextRender_SelectDrawMode:
	ld8_24 a, 0x03efaa
	cps a, 2
	jrl z, TextRender_XorMode_Init
	cps a, 1
	jrl z, TextRender_BitMask5_Init
	cps a, 0
	jrl nz, TextRender_AdvanceToNextLine
	ldw (xsp + 28), 0x0
	jrl TextRender_BitMask4_CheckColumnEnd

TextRender_BitMask4_DrawPixel:
	ld xwa, (xsp + 16)
	cp (xwa), 0x0
	jrl z, TextRender_BitMask5_ProcessCharacter
	st_dri3b A, 0xfd, 0x26, 0x01
	st_dri3b W, 0xfd, 0x2a, 0x01
	ld (xsp + 34), xwa
	ld hl, (xwa + 2)
	add hl, (xsp + 28)
	ld de, hl
	ld (xbc + 2), hl
	ld_sril XWA, (xsp + 0x013a)
	cp hl, (xwa + 2)
	jrl lt, TextRender_BitMask5_ProcessCharacter
	cp de, (xwa + 6)
	jrl gt, TextRender_AdvanceToNextLine
	ld wa, de
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld xwa, (xsp + 34)
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	lda_24 xix, 0x043c00
	add xix, xwa
	lds hl, 0
	cpw (xsp + 24), 0x0
	jr ule, TextRender_BitMask5_ProcessCharacter

TextRender_BitMask4_PixelLoop:
	ld xwa, (xsp + 34)
	ld de, (xwa)
	add de, hl
	ld (xbc), de
	ld_sril XWA, (xsp + 0x013a)
	cp de, (xwa)
	jr lt, TextRender_BitMask4_Return
	ld de, (xbc)
	cp de, (xwa + 4)
	jr gt, TextRender_BitMask5_ProcessCharacter
	lds wa, 7
	sub wa, hl
	lds iy, 1
	and a, 0xf
	jr z, TextRender_BitMask4_ShiftAndTest
	slaa iy

TextRender_BitMask4_ShiftAndTest:
	ld xwa, (xsp + 16)
	ld a, (xwa)
	extz wa
	and wa, iy
	jr z, TextRender_BitMask4_Return
	andmi8 (xix), 0x60
	ld_sriw DE, (xsp + 0x0144)
	ld wa, de
	and wa, 0x9f
	add (xix), a
	and de, 0x80
	ld a, (xix)
	and a, 0x80
	extz wa
	cp wa, de
	jr z, TextRender_BitMask4_Return
	xormi8 (xix), 0x60

TextRender_BitMask4_Return:
	inc 1, hl
	inc 1, xix
	cp hl, (xsp + 24)
	jr c, TextRender_BitMask4_PixelLoop

TextRender_BitMask5_ProcessCharacter:
	lds32 xwa, 1
	add (xsp + 16), xwa
	incm 1, (xsp + 28)

TextRender_BitMask4_CheckColumnEnd:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	cp (xsp + 28), wa
	jrl c, TextRender_BitMask4_DrawPixel
	jrl TextRender_AdvanceToNextLine

TextRender_BitMask5_Init:
	ldw (xsp + 28), 0x0
	jrl TextRender_BitMask5_CheckColumnEnd

TextRender_BitMask5_DrawPixel:
	ld xwa, (xsp + 16)
	cp (xwa), 0x0
	jrl z, TextRender_BitMask5_AdvancePointer
	st_dri3b D, 0xfd, 0x26, 0x01
	st_dri3b B, 0xfd, 0x2a, 0x01
	ld hl, (xde + 2)
	add hl, (xsp + 28)
	ld bc, hl
	ld (xix + 2), hl
	ld_sril XWA, (xsp + 0x013a)
	cp hl, (xwa + 2)
	jr lt, TextRender_BitMask5_AdvancePointer
	cp bc, (xwa + 6)
	jrl gt, TextRender_AdvanceToNextLine
	ld wa, bc
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld wa, (xde)
	exts xwa
	add xwa, xbc
	lda_24 xiz, 0x043c00
	add xiz, xwa
	lds hl, 0
	cpw (xsp + 24), 0x0
	jr ule, TextRender_BitMask5_AdvancePointer

TextRender_BitMask5_PixelLoop:
	ld bc, (xde)
	add bc, hl
	ld (xix), bc
	ld_sril XIY, (xsp + 0x013a)
	cp bc, (xiy)
	jr lt, TextRender_BitMask5_Return
	ld wa, (xix)
	cp wa, (xiy + 4)
	jr gt, TextRender_BitMask5_AdvancePointer
	lds wa, 7
	sub wa, hl
	lds iy, 1
	and a, 0xf
	jr z, TextRender_BitMask5_ShiftAndTest
	slaa iy

TextRender_BitMask5_ShiftAndTest:
	ld xwa, (xsp + 16)
	ld a, (xwa)
	extz wa
	and wa, iy
	jr z, TextRender_BitMask5_Return
	bitm 7, (xiz)
	jr z, TextRender_BitMask5_SetBit
	resm 5, (xiz)
	jr TextRender_BitMask5_Return

TextRender_BitMask5_SetBit:
	setm 5, (xiz)

TextRender_BitMask5_Return:
	inc 1, hl
	inc 1, xiz
	cp hl, (xsp + 24)
	jr c, TextRender_BitMask5_PixelLoop

TextRender_BitMask5_AdvancePointer:
	lds32 xwa, 1
	add (xsp + 16), xwa
	incm 1, (xsp + 28)

TextRender_BitMask5_CheckColumnEnd:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	cp (xsp + 28), wa
	jrl c, TextRender_BitMask5_DrawPixel
	jrl TextRender_AdvanceToNextLine

TextRender_XorMode_Init:
	ldw (xsp + 28), 0x0
	jrl TextRender_CheckColumnEnd

TextRender_XorMode_DrawPixel:
	ld xwa, (xsp + 16)
	cp (xwa), 0x0
	jrl z, TextRender_AdvancePointerAndUpdateLine
	st_dri3b D, 0xfd, 0x26, 0x01
	st_dri3b B, 0xfd, 0x2a, 0x01
	ld hl, (xde + 2)
	add hl, (xsp + 28)
	ld bc, hl
	ld (xix + 2), hl
	ld_sril XWA, (xsp + 0x013a)
	cp hl, (xwa + 2)
	jr lt, TextRender_AdvancePointerAndUpdateLine
	cp bc, (xwa + 6)
	jr gt, TextRender_AdvanceToNextLine
	ld wa, bc
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld wa, (xde)
	exts xwa
	.include "display/graphics_text_vga.s"
	call Sprintf_Locked
	lda xsp, (xsp + 12)

ChordProc_SendRefreshEvent:
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent

UI_EventHandler_InitReturnZero:
	lds32 xhl, 0

UI_EventHandler_PopAndReturn:
	pop xiz
	st_dri3b L, 0xfd, 0x04, 0x01
	ret

ChordProc_TrailingData:
	.byte 0x43, 0x03, 0x00, 0x02, 0x01, 0x0e
AcChordBoxProc_Entry:

AcChordBoxProc:
	st_dri3b L, 0xfd, 0xfc, 0xfe
	push xiz
	ld xiz, xde
	st_dri3l XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c20001
	jr z, AcChordBox_HandleChordUpdate
	cp xbc, 0x1c00001
	jr z, AcChordBox_HandleInitOrSelect
	cp xbc, 0x1c20000
	jr z, AcChordBox_HandleInitOrSelect
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jr AcChordBox_PopAndReturn

AcChordBox_HandleInitOrSelect:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, 0x1420007
	ld xbc, 0x1e2000d
	lds32 xde, 0
	call MainFuncCall
	jr AcChordBox_ReturnZero

AcChordBox_HandleChordUpdate:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	push xiz
	pushw 0xed
	pushw 0x1c92
	lda xwa, (xsp + 12)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 0
	jr nz, AcChordBox_ReturnZero
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent

AcChordBox_ReturnZero:
	lds32 xhl, 0

AcChordBox_PopAndReturn:
	pop xiz
	st_dri3b L, 0xfd, 0x04, 0x01
	ret

MainChordPre:
	push xiz
	cp xbc, 0x1e2000d
	jrl nz, MainChordPre_ReturnZero
	pushw 0x15
	call Malloc
	ld xiz, xhl
	ld (xiz), 0x0
	ldda8 a, 36160
	extz wa
	sla wa, 2
	lda_24 xbc, Naka_MemoryC_Screens
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	push xiz
	call Strcat
	ldda8 a, 36162
	extz wa
	sla wa, 2
	lda_24 xbc, MemScreen_Blank_0x04_
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	push xiz
	call Strcat
	lda xsp, (xsp + 18)
	cpdi8 36164, 0
	jr z, MainChordPre_EmptyChordStr
	bitda 1, 52958
	jr z, MainChordPre_EmptyChordStr
	ld xwa, KeyScaleNoteStr_G_0x14_
	jr MainChordPre_AppendChordSuffix

MainChordPre_EmptyChordStr:
	ld xwa, KeyScaleNoteStr_G_0x18_

MainChordPre_AppendChordSuffix:
	push xwa
	push xiz
	call Strcat
	ldda8 a, 36162
	extz wa
	sla wa, 2
	lda_24 xbc, 0x03f2f8
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	ldda8 a, 36160
	extz wa
	sla wa, 2
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	ldda8 a, 36164
	extz wa
	sla wa, 2
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	push xbc
	push xiz
	call Strcat
	lda xsp, (xsp + 16)
	ld xwa, 0xffffffff
	ld xbc, 0x1c20001
	ld xde, xiz
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, xiz
	call ApPostEvent

MainChordPre_ReturnZero:
	lds32 xhl, 0
	pop xiz
	ret

MainChordPre_ReturnDefaultResult:
	ld xhl, 0x1020005
	ret


; =============================================================================
; Extension Device Initialization (TOSHI) & Control Panel (ROM FC3114-FFFFFF)
; =============================================================================
	.include "extensions/extension_init.s"

InitializeKSS:
	ret

InitializeUser12:
	ret

InitializeUser13:
	ret

InitializeUser14:
	ret

InitializeUser15:
	ret

InitializeUser16:
	ret

InitializeUser17:
	ret

InitializeUser18:
	ret

InitializeUser19:
	ret

InitializeUser20:
	ret

InitializeUser21:
	ret

InitializeUser22:
	ret

InitializeUser23:
	ret

InitializeUser24:
	ret

InitializeUser25:
	ret

InitializeUser26:
	ret

InitializeUser27:
	ret

InitializeUser28:
	ret

InitializeUser29:
	ret

InitializeUser30:
	ret

InitializeUser31:
	ret

EmptyRoutine_01:
	ret

CPanel_InitDispatchTable:
	.long CPanel_InitSequence
	.long EmptyRoutine_03
	.long EmptyRoutine_03
	.long EmptyRoutine_02

CPanel_InitSequence:
	ei 0
	calr DELAY_51_TICKS
	calr DELAY_51_TICKS
	calr DELAY_51_TICKS
	calr CPanel_InitHardware
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_PollStartup
	ret


EmptyRoutine_02:
	ret


CPanel_RX_ProcessOrInit:
	ldda8 a, 36236
	and a, 0xc0
	jr z, CPanel_RX_SkipToProcess
				; if CP_Flags_A.76 != 0:
	ld xhl, 0x200ad
	ldw (xhl - 4), 0x0
	ldw (xhl - 8), 0x0
	ldw (xhl - 2), 0x80
	ei 6
	stdi16 36253, 0
	stdi16 36255, 0
	ordi8 36242, 1	; CP_Flags_B.0 = 1
	ei 0
	jr CPanel_RX_Return
				; else:
CPanel_RX_SkipToProcess:
	calr CPanel_RX_Process

CPanel_RX_Return:
	ret

CPanel_Poll:
	calr CPanel_InterruptPoll_MainLoop
	ret

CPanel_InitButtonState_SaveRegs:
	push xix
	push xiz
	push xhl
	push xde
	calr CPanel_InitButtonState
	pop xde
	pop xhl
	pop xiz
	pop xix
	ret


CPanel_PanelDetection_Wrapper:
	calr CPanel_PanelDetection
	ret


CPanel_KeyProcessing_Wrapper:
	calr ToneGen_Config_AlignByte
	ret


EmptyRoutine_03:
	ret


	.include "ui/cpanel_routines.s"


	.include "audio/tonegen_fileio_handlers.s"
	.include "audio/audio_control_engine.s"
	.include "boot/interrupt_vector_trampolines.s"

; =============================================================================
; SoundParam_NotifyChange -- Notify UI of sound parameter change
; =============================================================================
; Hashes parameter ID and triggers UI refresh for affected widgets.
; Called after preset loads: 0x4002 for reverb, 0x4006 for EQ.
; Args: xwa = parameter ID
SoundParam_NotifyChange:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), de
	ld (xsp + 12), bc
	ldw (xsp + 4), 0x0
	ld xiz, xwa
	lds32 xwa, 0
	ld (xsp + 6), xwa
	ld xhl, xiz
	and xhl, 0xff
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 8
	and xhl, 0xff
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 0
	and xhl, 0x1f
	add xhl, xwa
	ld xwa, xhl
	ld xbc, 0x7ff
	call DivMod32
	ld ix, hl
	jr SndParam_ProbeEntry


; --- Sound Parameters, MIDI Serial, DSP & Voice Mapping ---
	.include "audio/sndparam_routines.s"

; MIDI Serial Communication routines (SC0)
	.include "midi/midi_serial_routines.s"
	.include "midi/midi_dispatch_handlers.s"
	.include "audio/dsp_config_sysex.s"
	.include "audio/note_voice_mapping.s"

Debug_PrintHexByte:
	push	xiz
	calr	61
	pop	xiz
	ret
	push	xiz
	ld	w, a
	srl	a, 4
	calr	37
	pushw	wa
	calr	46
	popw	wa
	ld	a, w
	and	a, 15
	calr	24
	calr	34
	pop	xiz
	ret

Debug_PrintString:
	push xiz
	ld xix, xwa

Debug_PrintString_Loop:
	ld_spib A, 0xf0
	cps a, 0
	jr z, Debug_PrintString_Done
	push xix
	calr Debug_UartDelay
	pop xix
	jr Debug_PrintString_Loop

Debug_PrintString_Done:
	pop xiz
	ret

Debug_UartHelpers:
	.byte 0xc9, 0xcf, 0x0a, 0x6f, 0x04, 0xc9, 0xc8, 0x30, 0x0e, 0xc9, 0xc8, 0x57, 0x0e

Debug_UartDelay:
	ldw iz, 0xfe00
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ret

Debug_SWI_JumpTable:
	swi	7
	swi	7
	jp	Boot_InitWorkRAM_Trailer
	jp	HDAE5000_Init_DetectAndVerify
	jp	Boot_InitIOPorts
	jp	BOOT_ENTRY_POINT
	ret

Get_Firmware_Version:
	ld8_24 l, FIRMWARE_VERSION
	ret

ROM_PaddingFF:
	.byte 0xff, 0xff, 0xff, 0x00, 0xff

	.include "boot/rom_end_structure.s"

; Labels emitted as .set (exact addresses from ORG/name)
	.set SeqRingBuf_WriteDispatch_Table_0x11, 0xe00023
	.set SeqRingBuf_WriteDispatch_Table_0x16, 0xe00028
	.set LongStr_ics_KN5000_Program, 0xe00065
	.set Str_gramDATAFILE22, 0xe00073
	.set Str_AFILE22, 0xe0007c
	.set NakaStr_DataFile1of2, 0xe000c3
	.set Str_ableDATAFILEPCK, 0xe00111
	.set NakaStr_DataFilePck, 0xe00113
	.set NakaData_FileScreenConfig, 0xe0019e
	.set NakaData_FileScreenDispatch, 0xe00302
	.set Bitmap_1bit_FlashStatus_Icon, 0xe00800
	.set ScoopDisp_BitmapDataBlock, 0xe00b04
	.set ScoopDisp_EmptyBitmapData, 0xe00b28
	.set NakaUI_ObjectTable_End, 0xe14c32
	.set LongStr_Explore_1000_Musical, 0xe14c86
	.set StrFld_ParaList_Font_0x06, 0xe16bac
	.set Str_S2cGridBox, 0xe1708a
	.set AlignedStr_CmpNameMenuBox, 0xe17096
	.set NakaInst_AcApcToggle, 0xe17112
	.set NakaInst_AcApcToggle_0x0C, 0xe1711e
	.set Str_TEMPO, 0xe18d4c
	.set Str_FROM, 0xe1a224
	.set NumStr_11, 0xe1cde2
	.set NumStr_10, 0xe1cde6
	.set NumStr_9, 0xe1cdea
	.set NumStr_8, 0xe1cdee
	.set NumStr_7, 0xe1cdf2
	.set NumStr_6, 0xe1cdf6
	.set NumStr_5, 0xe1cdfa
	.set NumStr_4, 0xe1cdfe
	.set NumStr_3, 0xe1ce02
	.set NumStr_2, 0xe1ce06
	.set NumStr_1, 0xe1ce0a
	.set NumStr_0, 0xe1ce0e
	.set StrNotePos_FlatAlt, 0xe1dd4c
	.set StrNotePos_FlatAltB8, 0xe1dd52
	.set StrNotePos_AcNatural, 0xe1dd5a
	.set WidgetDispatch_FDTestPtrTable, 0xe1ffb6
	.set NakaDirectPlay_PropPtrTable, 0xe208a4
	.set NakaStr_LyricsBox, 0xe20b7c
	.set AlignedStr_AcMuteToggleBox, 0xe20b86
	.set Str_ORCH, 0xe21ad2
	.set NakaStr_PdMdlyOrcha, 0xe22322
	.set Str_AFTER_TOUCH_SETTING, 0xe2364a
	.set NakaStr_Gamelan, 0xe23c12
	.set NakaWidget_Perf2Flute, 0xe23c1a
	.set Str_SaxBrass, 0xe23cca
	.set NakaWidget_Perf2Piano, 0xe23cd4
	.set NakaStr_Organ, 0xe23d0a
	.set Str_HokieDance, 0xe23e62
	.set NakaWidget_Perf3JazzBand, 0xe23e6e
	.set Str_GospelRevival, 0xe23ea4
	.set NakaWidget_Perf3LatinOrch, 0xe23eb4
	.set Str_OrganCombo, 0xe23eea
	.set NakaWidget_Perf3BigBand, 0xe23ef6
	.set Str_BigBandMid, 0xe23f2c
	.set NakaWidget_Perf3SymphOrch, 0xe23f3a
	.set NakaStr_Rhythm, 0xe2405e
	.set NakaFld_TabIndexFunc, 0xe270ea
	.set NakaDesc_SeqExitWidgets, 0xe2713c
	.set NakaInst_SqedtVal, 0xe27564
	.set NakaInst_SqedtVal_B, 0xe27574
	.set NakaInst_EqualizerBox, 0xe27586
	.set Data_NakaPresetConfig, 0xe278a9
	.set NakaInst_FadeInOutSetting_Params, 0xe2df22
	.set Str_ENGLISH, 0xe2df54
	.set Str_ENGLISH_0x10, 0xe2df64
	.set Str_ENGLISH_0x52, 0xe2dfa6
	.set NakaData_EffectsBlock_Byte1, 0xe30001
	.set NakaData_EffectsBlock_Byte2, 0xe30002
	.set NakaData_EffectsBlock_Byte3, 0xe30003
	.set NakaData_EffectsBlock_Byte5, 0xe30005
	.set NakaData_EffectsStringPtrs, 0xe30006
	.set Str_20469e32473220, 0xe30b2a
	.set Str_42a03242322043, 0xe30b51
	.set TableData_NullDialogText, 0xe33824
	.set Str_ATTENTION, 0xe3382c
	.set Str_Apakahyakinakandihapus, 0xe338a6
	.set WarnStr_Featuresforcreatingas, 0xe338c2
	.set LongStr_Funktionen_zur_Erstellung, 0xe338e2
	.set LongStr_SongClear_Spanish, 0xe33ee4
	.set LongStr_Gunakan_SONG_CLEAR, 0xe33f22
	.set LongStr_TrackClear_Spanish, 0xe3405e
	.set LongStr_Gunakan_TRACK_CLEAR, 0xe340a6
	.set WarnStr_PresstheSTARTSTOPbutt, 0xe34104
	.set WarnStr_PresstheSTARTSTOPbutt_0x26, 0xe3412a
	.set FmtStr_pct3d, 0xe34614
	.set LongStr_1_2_3, 0xe34944
	.set FmtStr_pct3d_4B5E, 0xe34b5e
	.set FmtStr_pluspct3d, 0xe34bb6
	.set FmtStr_minuspct3d, 0xe34bbe
	.set Pad_AfterBitmap_Dredt0k, 0xe3def1
	.set Pad_AfterBitmap_Dredt0k_2, 0xe3e0f1
	.set Pad_BeforeBitmap_Dredt0d, 0xe3e2f2
	.set NakaData_ExternalBase, 0xe40000
	.set Pad_AfterNakaData_ExternalBase, 0xe40002
	.set Pad_NakaExternal_Block1, 0xe40005
	.set Pad_NakaExternal_Block2, 0xe40031
	.set Pad_NakaExternal_Block3, 0xe40046
	.set Pad_BeforeNakaData_ExternalBase_0x66, 0xe40059
	.set NakaData_ExternalBase_0x66, 0xe40066
	.set Pad_AfterNakaData_ExternalBase_0x66, 0xe4006e
	.set Pad_NakaExternal_Block4, 0xe40081
	.set NakaData_ExternalPadBlock_A, 0xe40096
	.set NakaData_ExternalPadBlock_B, 0xe400a9
	.set Pad_BeforeNakaData_UserMemoryConfig, 0xe400be
	.set NakaData_UserMemoryConfig, 0xe400d0
	.set Pad_AfterNakaData_UserMemoryConfig, 0xe40101
	.set Pad_BeforeNakaData_StyleBitmapPad, 0xe40116
	.set NakaData_ExternalBitmapBlock, 0xe40a09
	.set NakaData_StyleBitmapPad, 0xe41807
	.set RhythmTiming_OffsetTable, 0xe46312
	.set TechnichordParam_Block1, 0xe5002d
	.set TechnichordParam_Block2, 0xe5006e
	.set TechnichordParam_Block3, 0xe500be
	.set TechnichordParam_Block4, 0xe500ce
	.set TechnichordParam_Block5, 0xe500fe
	.set NakaData_TechnichordParams, 0xe50117
	.set NakaHandler_CtrlMessages, 0xe56acc
	.set NakaHandler_RealtimeMessages, 0xe56b14
	.set NakaHandler_CommonSetting, 0xe56b5c
	.set NakaHandler_ProgChangeMidiOut, 0xe56cbc
	.set NakaInst_InOutSettingGrid, 0xe57504
	.set NakaInst_MidiPresetConfig, 0xe578aa
	.set NakaInst_KN5000_MidiPresets, 0xe57982
	.set NakaInst_UserSettingSelector, 0xe57c8e
	.set NakaHandler_SplitPointDialog, 0xe57e6e
	.set NakaInst_SndModVocalistExtSeq, 0xe57f36
	.set NakaInst_KN5000_SysexBulkDump, 0xe57fa2
	.set NakaInst_WithAPC_Presets, 0xe5804e
	.set NakaInst_WithoutAPC_Presets, 0xe580a6
	.set NakaInst_Value_SysexPresets, 0xe580d2
	.set NakaInst_WithAPC_GM, 0xe5821e
	.set NakaInst_WithoutAPC_GM, 0xe58276
	.set NakaInst_Value_GM, 0xe582a2
	.set NakaInst_KN5000_GM, 0xe582e2
	.set NakaInst_BulkDumpCategorySelect, 0xe583a6
	.set NakaInst_Receiving_Sysex, 0xe58742
	.set NakaInst_ProgChangeLabel, 0xe58fda
	.set NakaInst_P_MEM_ON_OFF_PART, 0xe5904a
	.set NakaInst_PresetSettingsLabel, 0xe59532
	.set NakaInst_ItemLabel_RevEqPreset, 0xe5985a
	.set NakaData_DescriptorSection_Start, 0xe60000
	.set NakaData_DescriptorPad1, 0xe60008
	.set NakaData_DescriptorPad_ZeroA, 0xe6009a
	.set NakaData_DescriptorPad_ZeroB, 0xe600aa
	.set NakaData_DescriptorPad_ZeroC, 0xe600da
	.set NakaData_DescriptorZero, 0xe600df
	.set NakaData_DescriptorZero_PadA, 0xe600e4
	.set NakaData_DescriptorZero_PadB, 0xe600ec
	.set Pad_AfterBitmap_MIDIConnections_1, 0xe678ff
	.set NakaData_Tables2Pad1, 0xe70015
	.set NakaData_Tables2Pad2, 0xe7001e
	.set Pad_AfterNakaData_Tables2Pad2, 0xe70022
	.set NakaData_Tables2Pad3, 0xe700de
	.set Bitmap_MIDIConnections_Header, 0xe70b28
	.set DisplayMode_FormatStr1, 0xe7f91c
	.set DisplayMode_FormatStr2, 0xe7f922
	.set Data_AcGridParamTable, 0xe7f9ac
	.set Str_AL, 0xe8005f
	.set NakaInst_GM_0x5A, 0xe800ca
	.set NakaInst_GM_0x5E, 0xe800ce
	.set NakaInst_GM_0x6E, 0xe800de
	.set NakaInst_LEFT_0x04, 0xe800fa
	.set AlignedStr_ON, 0xe8013c
	.set NakaInst_ON_E80168_0x6C, 0xe801d4
	.set Transpose_String_Minus3, 0xe8068c
	.set Transpose_String_Error, 0xe80692
	.set Transpose_String_Plus1, 0xe806a4
	.set Transpose_String_Zero, 0xe806aa
	.set Str_ol, 0xe80b12
	.set Bitmap_AccompBitmapSpacer, 0xe878f9
	.set DrawbarSlider_ConfigData, 0xe8cfeb
	.set Bitmap_TechnichordBackground_1, 0xe90077
	.set NakaData_TechnichordBitmap1, 0xe900d8
	.set NakaData_TechnichordBitmap1_0x09, 0xe900e1
	.set NakaData_TechnichordBitmap1_0x14, 0xe900ec
	.set NakaInst_SequencerComboBox, 0xe90130
	.set NakaInst_SequencerComboBox_0x03, 0xe90133
	.set NakaData_TechnichordBitmap2, 0xe9013d
	.set Bitmap_TechnichordBackground_2, 0xe90b3b
	.set StrPtrTable_DiskErr03, 0xe96344
	.set Str_DiskErr12_French_0x5A, 0xe97114
	.set StrPtrTable_DiskErr16, 0xe971de
	.set StrPtrTable_DiskErr20_End, 0xe97bde
	.set StrPtrTable_DiskErr24_Start, 0xe97dc2
	.set Str_Err24APC_French_0x62, 0xe98676
	.set StrPtrTable_DiskErr24_French_End, 0xe9871a
	.set StrPtrTable_DiskErr28_Start, 0xe98aee
	.set StrPtrTable_DiskErr30_End, 0xe99a0e
	.set StrPtrTable_DiskErr41_Start, 0xe99cd4
	.set Str_BeimEmpfangderSys, 0xe99edc
	.set StrPtrTable_DiskErr43_Start, 0xe9a2c4
	.set StrPtrTable_Error55_End, 0xe9b92a
	.set StrPtrTable_Error55_Block2, 0xe9bf3a
	.set StrPtrTable_SpecialTracks_Start, 0xe9c524
	.set LongStr_RKB_und_LKB, 0xe9c6fc
	.set StrPtrTable_InitSettingWarning_Start, 0xe9cf14
	.set Str_DISKNAME, 0xea1d7a
	.set Str_LOAD, 0xea2442
	.set Str_COMP, 0xea263a
	.set Str_CUSTOM, 0xea26aa
	.set Str_MIDI, 0xea26d2
	.set Str_RHYTHM_CUSTOM, 0xea27a2
	.set Str_COMPOSER, 0xea2822
	.set Str_LOAD_2952, 0xea2952
	.set Str_SINGLE_LOAD, 0xea29a2
	.set NakaStr_Single, 0xea2d36
	.set NakaStr_Bank, 0xea2d3e
	.set Str_PREV, 0xea2e26
	.set Str_DISK, 0xea2f0e
	.set Str_LOAD_AS, 0xea2f3a
	.set Str_SOUND_MEMORY, 0xea3b5a
	.set Str_SEQUENCER, 0xea3bb2
	.set Str_PERFORM, 0xea3d2a
	.set Str_BACKUP, 0xea3d7a
	.set Str_PNL, 0xea3dca
	.set Str_COMP_3F6A, 0xea3f6a
	.set Str_CUSTOM_3FDA, 0xea3fda
	.set Str_MIDI_4002, 0xea4002
	.set Str_ALL_OFF, 0xea4082
	.set Str_SAVE, 0xea41d2
	.set Str_NEXT, 0xea435a
	.set Str_OFF, 0xea43bc
	.set Str_SAVE_44A2, 0xea44a2
	.set Str_PREV_471A, 0xea471a
	.set Str_DISKINSERTOPTION, 0xea66b6
	.set Str_FILETYPEPRIORITY, 0xea6706
	.set DiskWarning_GermanConfirm, 0xea8cbc
	.set Pad_AfterStr_No, 0xeaaef4
	.set FmtStr_pct2d, 0xeab18c
	.set WidgetPropStr_Max, 0xeac1ba
	.set WidgetPropStr_RangeFigures, 0xeac1be
	.set NakaData_CharaFontTable, 0xeada96
	.set NakaStr_Chara1pFnt, 0xeadb1a
	.set NakaStr_Chara5Fnt, 0xeadb26
	.set NakaStr_Chara4Fnt, 0xeadb32
	.set NakaStr_Chara3Fnt, 0xeadb3e
	.set NakaStr_Chara2Fnt, 0xeadb4a
	.set NakaStr_Chara1Fnt, 0xeadb56
	.set IconBitmapName_i96o, 0xeb2796
	.set BmpFile_i69_bmp, 0xeb287e
	.set BmpFile_i68_bmp, 0xeb2886
	.set BmpFile_i67_bmp, 0xeb288e
	.set BmpFile_i66_bmp, 0xeb2896
	.set BmpFile_i65_bmp, 0xeb289e
	.set BmpFile_i64_bmp, 0xeb28a6
	.set BmpFile_i63_bmp, 0xeb28ae
	.set BmpFile_i62_bmp, 0xeb28b6
	.set BmpFile_i61_bmp, 0xeb28be
	.set BmpFile_i60_bmp, 0xeb28c6
	.set BmpFile_i59_bmp, 0xeb28ce
	.set BmpFile_i58_bmp, 0xeb28d6
	.set BmpFile_i57_bmp, 0xeb28de
	.set BmpFile_i56_bmp, 0xeb28e6
	.set BmpFile_i55_bmp, 0xeb28ee
	.set BmpFile_i54_bmp, 0xeb28f6
	.set BmpFile_i53_bmp, 0xeb28fe
	.set BmpFile_i52_bmp, 0xeb2906
	.set BmpFile_i51_bmp, 0xeb290e
	.set BmpFile_i50_bmp, 0xeb2916
	.set BmpFile_i49_bmp, 0xeb291e
	.set BmpFile_i48_bmp, 0xeb2926
	.set BmpFile_i47_bmp, 0xeb292e
	.set BmpFile_i46_bmp, 0xeb2936
	.set BmpFile_i45_bmp, 0xeb293e
	.set BmpFile_i44_bmp, 0xeb2946
	.set BmpFile_i43_bmp, 0xeb294e
	.set BmpFile_i42_bmp, 0xeb2956
	.set BmpFile_i41_bmp, 0xeb295e
	.set BmpFile_i40_bmp, 0xeb2966
	.set BmpFile_i39_bmp, 0xeb296e
	.set BmpFile_i38_bmp, 0xeb2976
	.set BmpFile_i37_bmp, 0xeb297e
	.set BmpFile_i36_bmp, 0xeb2986
	.set BmpFile_i35_bmp, 0xeb298e
	.set BmpFile_i34_bmp, 0xeb2996
	.set BmpFile_i33_bmp, 0xeb299e
	.set BmpFile_i32_bmp, 0xeb29a6
	.set BmpFile_i31_bmp, 0xeb29ae
	.set BmpFile_i30_bmp, 0xeb29b6
	.set BmpFile_i29_bmp, 0xeb29be
	.set BmpFile_i28_bmp, 0xeb29c6
	.set BmpFile_i27_bmp, 0xeb29ce
	.set BmpFile_i26_bmp, 0xeb29d6
	.set BmpFile_i25_bmp, 0xeb29de
	.set BmpFile_i24_bmp, 0xeb29e6
	.set BmpFile_i23_bmp, 0xeb29ee
	.set BmpFile_i22_bmp, 0xeb29f6
	.set BmpFile_i21_bmp, 0xeb29fe
	.set BmpFile_i20_bmp, 0xeb2a06
	.set BmpFile_i19_bmp, 0xeb2a0e
	.set BmpFile_i18_bmp, 0xeb2a16
	.set BmpFile_i17_bmp, 0xeb2a1e
	.set BmpFile_i16_bmp, 0xeb2a26
	.set BmpFile_i15_bmp, 0xeb2a2e
	.set BmpFile_i14_bmp, 0xeb2a36
	.set BmpFile_i13_bmp, 0xeb2a3e
	.set BmpFile_i12_bmp, 0xeb2a46
	.set BmpFile_i11_bmp, 0xeb2a4e
	.set BmpFile_i10_bmp, 0xeb2a56
	.set BmpFile_i9_bmp, 0xeb2a5e
	.set BmpFile_i8_bmp, 0xeb2a66
	.set BmpFile_i7_bmp, 0xeb2a6e
	.set StyleBmp_i6obmp, 0xeb2a76
	.set BmpFile_i5_bmp, 0xeb2a7e
	.set StyleBmp_i4obmp, 0xeb2a86
	.set StyleBmp_i3obmp, 0xeb2a8e
	.set BmpFile_i2_bmp, 0xeb2a96
	.set BmpFile_i1_bmp, 0xeb2a9e
	.set BmpFile_i0_bmp, 0xeb2aa6
	.set StyleBmp_trashbmp, 0xeb2aae
	.set Palette_8bit_RGBA, 0xeb37de
	.set StyleBmp_ZachariasSwing, 0xebbc26
	.set StyleBmp_YeeHaFiddles, 0xebbcae
	.set StyleBmp_WunderPops, 0xebbd36
	.set StyleBmp_WildSideOrgan, 0xebbdbe
	.set StyleBmp_WheelsofLife, 0xebbe46
	.set StyleBmp_WeddingParty, 0xebbece
	.set StyleBmp_WandrinKeys, 0xebbf56
	.set StyleBmp_WaltzingConcert, 0xebbfde
	.set StyleBmp_WailersGuitar, 0xebc066
	.set StyleBmp_VocalBeats, 0xebc0ee
	.set StyleBmp_ViennaWoods, 0xebc176
	.set StyleBmp_VegasShowman, 0xebc1fe
	.set StyleBmp_UptownHorns, 0xebc286
	.set StyleBmp_TwoStepDuo, 0xebc30e
	.set StyleBmp_TwilightPiano, 0xebc396
	.set StyleBmp_TravoltaDance, 0xebc41e
	.set StyleBmp_TopBrassJive, 0xebc4a6
	.set StyleBmp_TirolerHarp, 0xebc52e
	.set StyleBmp_TheatreBand, 0xebc5b6
	.set StyleBmp_ThePartyBand, 0xebc63e
	.set StyleBmp_TheDukesPiano, 0xebc6c6
	.set StyleBmp_TennesseeGuitar, 0xebc74e
	.set StyleBmp_TechnoFiddle, 0xebc7d6
	.set StyleBmp_TangoMarcato, 0xebc85e
	.set StyleBmp_TakeItEasy, 0xebc8e6
	.set StyleBmp_SynthParty, 0xebc96e
	.set StyleBmp_SynthForSoul, 0xebc9f6
	.set StyleBmp_SymphonyBallad, 0xebca7e
	.set StyleBmp_SwingingKeys, 0xebcb06
	.set StyleBmp_SwingSerenade, 0xebcb8e
	.set StyleBmp_SwingB3Threes, 0xebcc16
	.set StyleBmp_SweetSoprano, 0xebcc9e
	.set StyleBmp_SweepingBridge, 0xebcd26
	.set StyleBmp_SunnySpainMood, 0xebcdae
	.set StyleBmp_StreetTalk, 0xebce36
	.set StyleBmp_StephaneDjango, 0xebcebe
	.set StyleBmp_SteelStrings, 0xebcf46
	.set StyleBmp_SpyraSteel, 0xebcfce
	.set StyleBmp_SpanishMoments, 0xebd056
	.set StyleBmp_SouthernStyle, 0xebd0de
	.set StyleBmp_SoulfulWhaWha, 0xebd166
	.set StyleBmp_SoulVocalDuo, 0xebd1ee
	.set StyleBmp_SoulHorn, 0xebd276
	.set StyleBmp_SopranoGroove, 0xebd2fe
	.set StyleBmp_SolidSixteen, 0xebd386
	.set StyleBmp_SolidDistortion, 0xebd40e
	.set StyleBmp_SoftRock, 0xebd496
	.set StyleBmp_SmoothLips, 0xebd51e
	.set StyleBmp_SlowSpinGroove, 0xebd5a6
	.set StyleBmp_SlapBackRock, 0xebd62e
	.set StyleBmp_SkeletonDance, 0xebd6b6
	.set StyleBmp_SingItPlayIt, 0xebd73e
	.set StyleBmp_SinatraStrings, 0xebd7c6
	.set StyleBmp_SimpleBand, 0xebd84e
	.set StyleBmp_ShuffleOrgan, 0xebd8d6
	.set StyleBmp_ShearingCombo, 0xebd95e
	.set StyleBmp_SevilleOctaves, 0xebd9e6
	.set StyleBmp_SentimentalSolo, 0xebda6e
	.set StyleBmp_SaxyMambo, 0xebdaf6
	.set StyleBmp_SaxDrumsRRoll, 0xebdb7e
	.set StyleBmp_SaxMamboist, 0xebdc06
	.set StyleBmp_SantasHelpers, 0xebdc8e
	.set StyleBmp_SambaUnion, 0xebdd16
	.set StyleBmp_SambaParty, 0xebdd9e
	.set StyleBmp_RossVocals, 0xebde26
	.set StyleBmp_RollingWheels, 0xebdeae
	.set StyleBmp_RockSymphony, 0xebdf36
	.set StyleBmp_RockFall, 0xebdfbe
	.set StyleBmp_RioHorns, 0xebe046
	.set StyleBmp_RickysStrat, 0xebe0ce
	.set StyleBmp_RetroGroove, 0xebe156
	.set StyleBmp_ReinhardtsSolo, 0xebe1de
	.set StyleBmp_ReggaeDanceHit, 0xebe266
	.set StyleBmp_ReedItSwing, 0xebe2ee
	.set StyleBmp_RastaJambo, 0xebe376
	.set StyleBmp_RadioOrchestra, 0xebe3fe
	.set StyleBmp_PuentesBigband, 0xebe486
	.set StyleBmp_PowerSaxSwing, 0xebe50e
	.set StyleBmp_PopLeader, 0xebe596
	.set StyleBmp_PopBridge, 0xebe61e
	.set StyleBmp_PolyDance, 0xebe6a6
	.set StyleBmp_PlateDance, 0xebe72e
	.set StyleBmp_PennyFolkSong, 0xebe7b6
	.set StyleBmp_PartyPopStack, 0xebe83e
	.set StyleBmp_PartyAccordion, 0xebe8c6
	.set StyleBmp_ParadiseKeys, 0xebe94e
	.set StyleBmp_OverTheTopWah, 0xebe9d6
	.set StyleBmp_OrganistsSwing, 0xebea5e
	.set StyleBmp_OrchestralEight, 0xebeae6
	.set StyleBmp_OneTwoThree, 0xebeb6e
	.set StyleBmp_OleGuitar, 0xebebf6
	.set StyleBmp_OldTimeSaloon, 0xebec7e
	.set StyleBmp_OldNewFunk, 0xebed06
	.set StyleBmp_OklahomaDance, 0xebed8e
	.set StyleBmp_OceanVocals, 0xebee16
	.set StyleBmp_NotRavels, 0xebee9e
	.set StyleBmp_NiceKeroncong, 0xebef26
	.set StyleBmp_NewSquareDance, 0xebefae
	.set StyleBmp_NewJazzBallad, 0xebf036
	.set StyleBmp_NashvilleDance, 0xebf0be
	.set StyleBmp_MuteSoloist, 0xebf146
	.set StyleBmp_MusetteBallad, 0xebf1ce
	.set StyleBmp_MovieBallad, 0xebf256
	.set StyleBmp_MoschsMilitary, 0xebf2de
	.set StyleBmp_MoiksMarchshow, 0xebf366
	.set StyleBmp_ModernBoogie, 0xebf3ee
	.set StyleBmp_MirandaMallets, 0xebf476
	.set StyleBmp_MidnightTunes, 0xebf4fe
	.set StyleBmp_MerengueParty, 0xebf586
	.set StyleBmp_MellowSection, 0xebf60e
	.set StyleBmp_MellowJazzTabs, 0xebf696
	.set StyleBmp_MellowShuffle, 0xebf71e
	.set StyleBmp_MaxsOrchestra, 0xebf7a6
	.set StyleBmp_MarchingPolka, 0xebf82e
	.set StyleBmp_MamboJambo, 0xebf8b6
	.set StyleBmp_MadTabs, 0xebf93e
	.set StyleBmp_LondonsBigbone, 0xebf9c6
	.set StyleBmp_LionelsJazz, 0xebfa4e
	.set StyleBmp_LikeSunday, 0xebfad6
	.set StyleBmp_LetItShine, 0xebfb5e
	.set StyleBmp_LatinoPiccolo, 0xebfbe6
	.set StyleBmp_LatinPassion, 0xebfc6e
	.set StyleBmp_LatinBallroom, 0xebfcf6
	.set StyleBmp_LastStarparade, 0xebfd7e
	.set StyleBmp_LAWarmth, 0xebfe06
	.set StyleBmp_KnopflerTribute, 0xebfe8e
	.set StyleBmp_KeyGrooves, 0xebff16
	.set StyleBmp_JustTheFlute, 0xebff9e
	.set NakaStr_SoundPreset176, 0xec00c7
	.set SoundName_160, 0xec00ec
	.set SoundName_160_0x27, 0xec0113
	.set SoundName_ToTheBone, 0xec013b
	.set NakaStr_SoundPresetBone, 0xec013f
	.set NakaInst_Hard_Analogue_148_0x65, 0xec0a1b
	.set SoundName_MournfulTenor, 0xec88ec
	.set StyleSound_BluesAlley_Data, 0xec8974
	.set SoundName_HymnBand, 0xec89b4
	.set SoundName_HymnBand_0x66, 0xec8a1a
	.set SoundName_PreachTheWord, 0xec8a7c
	.set SoundName_LushTango, 0xecb09c
	.set SoundName_LushTango_0x66, 0xecb102
	.set SoundName_AstorsTango, 0xecb164
	.set SoundName_SymphonicWaltz, 0xecb26c
	.set StyleSound_QuickWaltz_Data, 0xecb2f4
	.set SoundName_NotStrauss, 0xecb334
	.set SoundName_NotStrauss_0x66, 0xecb39a
	.set SoundName_BavarianFlutes, 0xecb3fc
	.set SoundName_BeachPartySong, 0xecdbec
	.set SoundName_CubanReeds, 0xecdcb4
	.set SoundName_LatinoPiccolo, 0xecdd7c
	.set SoundName_JamaicanBars, 0xecde44
	.set SoundName_SambaUnion, 0xecde84
	.set SoundName_NewOrganSamba, 0xecdf4c
	.set SoundName_NiceKeroncong, 0xece014
	.set SoundName_EasyDangdut, 0xece0dc
	.set SoundName_PadangBeat, 0xece11c
	.set SoundName_RastaVoice, 0xece1e4
	.set SoundName_MarleysDrums, 0xece2ac
	.set EffSeqScreen_ChordTypePtr_A, 0xed0072
	.set EffSeqScreen_ChordTypePtr_B, 0xed009c
	.set NakaInst_WITH_APC, 0xed00d5
	.set NakaStr_CtrlParam9e9, 0xed013b
	.set SeqChanContainer_ChordTypeRef_A, 0xed0212
	.set SeqChanContainer_ChordTypeRef_B, 0xed029c
	.set ParamStr08_varisupart, 0xed210e
	.set ParamStr08_page, 0xed2116
	.set ParamStr08_fontcolor, 0xed211c
	.set ParamStr08_font, 0xed2122
	.set ParamStr08_func, 0xed212c
	.set ParamStr19_fixedcol, 0xed250c
	.set ParamStr22_nowsongsubctgdtno, 0xed275c
	.set ParamStr22_func, 0xed276e
	.set ParamStr22_fixedrow, 0xed2774
	.set ParamStr22_fixedcol, 0xed277e
	.set NakaInst_AcMstSugAlpGridBox, 0xed2b9a
	.set NakaInst_AcFSWAssGridBox, 0xed2be2
	.set NakaDesc_AcTchSensGridBox, 0xed2bf4
	.set NakaInst_AcTchSensGridBox, 0xed2bf6
	.set NakaDesc_IvMstStyleWindowPgCtl, 0xed2c0c
	.set NakaInst_IvMstStyleWindowPgCtl, 0xed2c0e
	.set NakaDesc_IvPmemWindowPageCtl, 0xed2c22
	.set NakaInst_IvPmemWindowPageCtl, 0xed2c24
	.set NakaInst_MsaModeScreen, 0xed2c62
	.set Str_7f, 0xed46d2
	.set Str_RHYTHM, 0xed4722
	.set SoundName_SOUNDRHYTHM, 0xed474a
	.set Str_PANEL_MEMORY, 0xed477a
	.set Str_PANEL_MEMORY_4922, 0xed4922
	.set Str_7f_4A82, 0xed4a82
	.set Str_DISPLAY_TYPE, 0xed4de2
	.set Str_USER_INITIAL, 0xed5122
	.set Str_VALUE, 0xed517a
	.set ExtDevScreen_SndParamBank_Desc, 0xed690a
	.set ExtDevScreen_SndParamPage_Desc, 0xed69a2
	.set ExtDevScreen_VoiceParamBank_Desc, 0xed6a7a
	.set ExtDevScreen_VoiceParamRhythm_Desc, 0xed6b0a
	.set ExtDevScreen_VoiceParamDrums_Desc, 0xed6b52
	.set ExtDevScreen_VoiceSetup_Desc, 0xed6be2
	.set ExtDevScreen_VoiceMainPage_Desc, 0xed6c6e
	.set ExtDevScreen_MidiCtrl_Desc, 0xed6ff2
	.set ExtDevScreen_MidiCtrlPage_Desc, 0xed70a2
	.set ExtDevScreen_MidiCtrlDetail_Desc, 0xed71b2
	.set ExtDevScreen_MidiCtrlAdvanced_Desc, 0xed723a
	.set ExtDevScreen_DspEffect_Desc, 0xed729a
	.set ExtDevScreen_DspEffectPage_Desc, 0xed734a
	.set ExtDevScreen_ReverbSetup_Desc, 0xed745a
	.set ExtDevScreen_ReverbPage_Desc, 0xed74e2
	.set ExtDevScreen_Equalizer_Desc, 0xed7542
	.set ExtDevScreen_EqualizerPage_Desc, 0xed75f2
	.set ExtDevScreen_UserInitWallpaper_Flag, 0xed9f54
	.set ExtDevScreen_UserInitWallpaper_Data, 0xed9f5c
	.set ENCODER_LUT_VOLUME, 0xeda1bc
	.set ENCODER_LUT_BREATH_INDEX, 0xeda2bc
	.set ENCODER_LUT_BREATH_VALUE, 0xeda2d2
	.set ENCODER_LUT_BREATH_MULT, 0xeda3d2
	.set ENCODER_LUT_BREATH_OFFSET, 0xeda3ea
	.set ENCODER_LUT_FOOT, 0xeda402
	.set ENCODER_LUT_EXPRESSION, 0xeda482
	.set ToshiParam_Entry_01, 0xeda704
	.set ToshiParam_Entry_02, 0xeda71c
	.set ToshiParam_Entry_03, 0xeda734
	.set ToshiParam_Entry_04, 0xeda74c
	.set ToshiParam_Entry_05, 0xeda764
	.set ToshiParam_Entry_06, 0xeda77c
	.set ToshiParam_Entry_07, 0xeda794
	.set ToshiParam_Entry_08, 0xeda7ac
	.set ToshiParam_Entry_09, 0xeda7c4
	.set ToshiParam_Entry_10, 0xeda7dc
	.set ToshiParam_Entry_11, 0xeda7f4
	.set ToshiParam_Entry_12, 0xeda80c
	.set ToshiParam_Entry_13, 0xeda824
	.set ToshiParam_Entry_14, 0xeda83c
	.set ToshiParam_Entry_15, 0xeda854
	.set ToshiParam_Entry_16, 0xeda86c
	.set ToshiParam_Entry_17, 0xeda884
	.set ToshiParam_Entry_18, 0xeda89c
	.set ToshiParam_Entry_19, 0xeda8b4
	.set ToshiParam_Entry_20, 0xeda8e4
	.set ToshiParam_Entry_21, 0xeda914
	.set ToshiParam_Entry_22, 0xeda944
	.set ToshiParam_Entry_23, 0xeda974
	.set ToshiParam_Entry_24, 0xeda9a4
	.set ToshiParam_Entry_25, 0xeda9d4
	.set ToshiParam_Entry_26, 0xedaa04
	.set ToshiParam_Entry_27, 0xedaa34
	.set SoundProgram_ParamPtrTable, 0xedb2e4
	.set WidgetParam_TestMode_Entry, 0xedba44
	.set WidgetParam_SineWave_Entry, 0xedbaae
	.set Naka_SubDispatch_B_Table_0x6E, 0xee0206
	.set SeqData_SubDispatch_ParamA, 0xee3023
	.set SeqData_SubDispatch_ParamB, 0xee3025
	.set WidgetParam_Entry_002_0x18, 0xee45d2
	.set WidgetParam_Entry_002_0x30, 0xee45ea
	.set WidgetParam_Entry_006_0x18, 0xee4662
	.set WidgetParam_Entry_006_0x48, 0xee4692
	.set WidgetParam_Entry_008_0x18, 0xee46da
	.set WidgetParam_Entry_009_0x18, 0xee470a
	.set WidgetParam_Entry_011_0x18, 0xee4752
	.set WidgetParam_Entry_011_0x48, 0xee4782
	.set WidgetParam_Entry_011_0x60, 0xee479a
	.set CharMap_PermutationPtrTable_A, 0xeed3de
	.set CharMap_PermutationPtrTable_B, 0xeed52b
	.set Pad_AfterNaka_DrawbarOrgan_Screens, 0xeee812
	.set NakaData_NormalModeMap, 0xef001f
	.set NakaData_NormalModeMap_0x07, 0xef0026
	.set ScoopDisp_DispatchTable_Extended_0x20, 0xef7779
	.set PerfMode_Evt01_Handler, 0xef8b6d
	.set PerfMode_Evt02_Handler, 0xef8dfb
	.set UIState_Evt06_Handler, 0xef9554
	.set UIState_Evt05_Handler, 0xef955d
	.set MemConfig_Handler_2, 0xefacf7
	.set SubCPU_ToneDispatch_0x54, 0xefdb94
	.set StringData_PartModeNames, 0xeff827
	.set SeMenu_DataBlock_01, 0xf1039e
	.set SeMenu_DataBlock_02, 0xf1040d
	.set SeMenu_DataBlock_03, 0xf1041d
	.set SeMenu_DataBlock_04, 0xf10454
	.set SeMenu_DataBlock_05, 0xf10464
	.set SeMenu_DataBlock_06, 0xf1048e
	.set SeMenu_DataBlock_07, 0xf104b8
	.set SeMenu_DataBlock_08, 0xf104c8
	.set SeMenu_DataBlock_09, 0xf104d8
	.set SeMenu_DataBlock_10, 0xf104e8
	.set SeMenu_DataBlock_11, 0xf10512
	.set SeMenu_DataBlock_12, 0xf105c4
	.set SeMenu_DataBlock_13, 0xf10676
	.set SeMenu_DataBlock_14, 0xf10689
	.set FlashRead_BlockData_Field8, 0xf15891
	.set FlashRead_BlockData_Field7, 0xf1589c
	.set DrumDetailEdit_Entry_01, 0xf16006
	.set DrumDetailEdit_Entry_02, 0xf16028
	.set DrumDetailEdit_Entry_03, 0xf1604a
	.set DrumDetailEdit_Entry_04, 0xf16056
	.set DrumDetailEdit_Entry_05, 0xf16063
	.set DrumDetailEdit_Entry_06, 0xf16070
	.set DrumDetailEdit_Entry_07, 0xf16092
	.set DrumDetailEdit_Entry_08, 0xf1609e
	.set DrumDetailEdit_Entry_09, 0xf160ab
	.set Data_Dispatch_Entry, 0xf160b8
	.set Data_Dispatch_Entry_0x39, 0xf160f1
	.set Data_Dispatch_Entry_0x45, 0xf160fd
	.set EffectParamEdit_Entry_01, 0xf1649b
	.set EffectParamEdit_Entry_02, 0xf164a6
	.set EffectParamEdit_Entry_03, 0xf164b5
	.set EffectParamEdit_Entry_04, 0xf164c0
	.set EffectParamEdit_Entry_05, 0xf164cb
	.set EffectParamEdit_Entry_06, 0xf164d6
	.set EffectParamEdit_Entry_07, 0xf164e1
	.set EffectParamEdit_Entry_08, 0xf164ec
	.set SeqVoice_ValidateAndProcessState_0x13, 0xf400ec
	.set NakaData_PerfStyleCode, 0xf5001f
	.set NakaData_PerfStyleCode_0x10, 0xf5002f
	.set NakaData_PerfStyleCode_0x1A, 0xf50039
	.set NakaData_PerfStyleCode_0x33, 0xf50052
	.set NakaData_PerfStyleCode_0x59, 0xf50078
	.set MSP_FactoryPresetData_Continued, 0xf700bb
	.set SLDstBankList_FuncBody_0x44, 0xf900b9
	.set SLDstBankList_FuncBody_0x7C, 0xf900f1
	.set FDC_INIT, 0xf96bbf
	.set FDC_CONFIG_VERIFY, 0xf96bd0
	.set FDC_CMD_DISPATCH_SUB, 0xf96d95
	.set FDC_CMD_SEND, 0xf972f9
	.set FDC_DETECT_CHECK, 0xf974fe
	.set FDC_DRIVE_DETECT, 0xf97544
	.set FDC_DRIVE_STATUS, 0xf97592
	.set FDC_PRE_OP_CHECK, 0xf975ac
	.set FDC_TIMING_DELAY, 0xf975dc
	.set FDC_POST_OP, 0xf975e2
	.set FDC_STATUS_HANDLER, 0xf97696
	.set FDC_CE_DISPATCH, 0xf9782a
	.set FDC_CE_EXIT, 0xf97833
	.set FDC_SECTOR_XFER, 0xf97835
	.set FDC_SX_MAIN, 0xf9795e
	.set FDC_SX_EXIT, 0xf97967
	.set FDC_CMD_ENABLE, 0xf97c21
	.set FDC_CMD_DISABLE, 0xf97c4b
	.set FDC_OUTPUT_CTRL, 0xf97c5b
	.set RVari_SelectO_SecondItem_Draw_0x32, 0xfc0012
	.set NakaData_WidgetInit1, 0xfc645a
	.set NakaData_WidgetInit2, 0xfc647f
	.set NakaData_WidgetInit3, 0xfc64ea
	.set SeqChan_UnhandledCmd, 0xfd8261
	.set SeqChan_UnhandledCmd_0x01, 0xfd8262
	.set SeqChan_UnhandledCmd_0x02, 0xfd8263
	.set SeqChan_UnhandledCmd_0x03, 0xfd8264
	.set SeqChan_UnhandledCmd_0x12, 0xfd8273
	.set AudioInit_PartConfig_Loop_0x26, 0xfe0053
	.set HdaeRom_DispatchOffsetTable, CharMap_PermutationPtrTable_B + 540
	.set HdaeRom_AltDispatchOffsetTable, CharMap_PermutationPtrTable_B + 552
	.set _addr24_Mem_Copy, 0xff0d8b
	.set NakaData_RomEnd, 0xffffff
