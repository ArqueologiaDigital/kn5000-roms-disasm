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
.equ PROGRAM_FLASH__BASE_ADDR, 0xE00000

.equ SYSTEM_TIMESTAMP, 0x409

.equ MSP_SETTINGS, 0xC9A	; 1500h = 5376 bytes
					; next free address: 0219Ah

.equ COM_SELECT, 0xB7E0	; (byte)

.equ SEQ_ALT3_RINGBUF_BASE, 0x201C1

.equ MSP_SETTINGS__BASE_ADDR, 0x1E8800

	.org PROGRAM_FLASH__BASE_ADDR - 0xE00000, 0xFF

LED_patterns_indicating_firmware_version:
	.byte 0x10	; v0:  0001 0000
	.byte 0x18	; v1:  0001 1000
	.byte 0x14	; v2:  0001 0100
	.byte 0x1c	; v3:  0001 1100
	.byte 0x12	; v4:  0001 0010
	.byte 0x1a	; v5:  0001 1010
	.byte 0x16	; v6:  0001 0110
	.byte 0x1e	; v7:  0001 1110
LED_patterns_firmware_v8_plus:
	.byte 0x11	; v8:  0001 0001
	.byte 0x19	; v9:  0001 1001
	.byte 0x15	; v10: 0001 0101
	.byte 0x1d	; v11: 0001 1101
	.byte 0x13	; v12: 0001 0011
	.byte 0x1b	; v13: 0001 1011
	.byte 0x17	; v14: 0001 0111
	.byte 0x1f	; v15: 0001 1111

LED_pattern_test_data:
	.byte 0x10, 0xff

; DMA ISR event router: dispatches incoming sequencer data to ring buffers
; Index: DRAM[1508] bits [7:5] (top 3 bits of status byte), 8 entries
; Called from E1DMA_ISR handler (system_handlers.s)
;
; Each entry routes DMA event bytes to a specific ring buffer, consumed by:
;   NoteEvent  (0x0203D5) -> note_voice_mapping, sound_editor_ui
;   SoundEdit  (via EF2E39) -> sound_editor_ui
;   VoiceMap   (0x0201C1) -> note_voice_mapping
;   DspSysEx   (0x01FCA3) -> dsp_config_sysex
;   MidiOut    (0x01F785) -> midi_serial_routines  (not in this table)
SeqRingBuf_WriteDispatch_Table:
	.long SeqDMA_MultiWrite_NoteEvent	; 0: -> NoteEvent buffer (block writes)
	.long SeqDMA_MultiWrite_SoundEdit	; 1: -> SoundEdit buffer
	.long SeqDMA_WriteMidi_NoteOn		; 2: -> NoteEvent buffer (MIDI 0x90 Note On)
	.long SeqDMA_MultiWrite_VoiceMap	; 3: -> VoiceMap buffer
	.long SeqDMA_MultiWrite_DspSysEx	; 4: -> DspSysEx buffer
	.long SeqDMA_Nop			; 5: unused
	.long SeqDMA_Nop			; 6: unused
	.long SeqDMA_Nop			; 7: unused

SLIDE_STRING:			aligned_string "SLIDE"
FILETYPE_SIG_PROGRAM_1:		aligned_string "Technics KN5000 Program  DATA FILE 1/2"
FILETYPE_SIG_PROGRAM_2:		aligned_string "Technics KN5000 Program  DATA FILE 2/2"
FILETYPE_SIG_PROGRAM_PCK:	aligned_string "Technics KN5000 Program  DATA FILE PCK"
FILETYPE_SIG_TABLE_1:		aligned_string "Technics KN5000 Table    DATA FILE 1/2"
FILETYPE_SIG_TABLE_2:		aligned_string "Technics KN5000 Table    DATA FILE 2/2"
FILETYPE_SIG_TABLE_PCK:		aligned_string "Technics KN5000 Table    DATA FILE PCK"
FILETYPE_SIG_CMPCUSTOM:		aligned_string "Technics KN5000 CMPCUSTOMDATA FILE    "
FILETYPE_SIG_HDAE_PRG:		aligned_string "Technics KN5000 HD-AEPRG DATA FILE    "

.equ HANDLE_UPDATE_BASE_ADDR, HANDLE_UPDATE_FILE_TYPE_ID_001h

HANDLE_UPDATE_OFFSETS:
	.short HANDLE_UPDATE_FILE_TYPE_ID_001h - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 Program DATA FILE 1/2"
	.short SHOW_ILLEGAL_DISK_MESSAGE - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 Program DATA FILE 2/2"
	.short HANDLE_UPDATE_FILE_TYPE_ID_003h - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 Table DATA FILE 1/2"
	.short SHOW_ILLEGAL_DISK_MESSAGE - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 Table DATA FILE 2/2"
	.short HANDLE_UPDATE_FILE_TYPE_ID_005h - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 CMPCUSTOMDATA FILE"
	.short HANDLE_UPDATE_FILE_TYPE_ID_006h - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 HD-AEPRG DATA FILE"
	.short HANDLE_UPDATE_FILE_TYPE_ID_007h - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 Program DATA FILE PCK"
	.short HANDLE_UPDATE_FILE_TYPE_ID_008h - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 Table DATA FILE PCK"

SLIDE_STRING_2:
	aligned_string "SLIDE"

Bitmap_1bit_Flash_Memory_Update:	.incbin "images/Bitmap_1bit_Flash_Memory_Update.bin"
Bitmap_1bit_Now_Erasing:		.incbin "images/Bitmap_1bit_Now_Erasing.bin"
Bitmap_1bit_FD_to_Flash_Memory:		.incbin "images/Bitmap_1bit_FD_to_Flash_Memory.bin"
Bitmap_1bit_Completed:			.incbin "images/Bitmap_1bit_Completed.bin"
Bitmap_1bit_Please_Wait:		.incbin "images/Bitmap_1bit_Please_Wait.bin"
Bitmap_1bit_Change_FD_2_of_2:		.incbin "images/Bitmap_1bit_Change_FD_2_of_2.bin"
Bitmap_1bit_Illegal_Disk:		.incbin "images/Bitmap_1bit_Illegal_Disk.bin"
Bitmap_1bit_Turn_On_AGAIN:		.incbin "images/Bitmap_1bit_Turn_On_AGAIN.bin"


; --- SSF (Style Synthesis Format) Gate State Data ---
.include "sequencer/ssf_gate_states.s"


; --- Instrument Sound Data & Category Metadata ---
	.include "audio/sound_data.s"


; --- Style UI Parameter Blocks & Screen Data ---
	.include "ui_widgets/style_ui_params.s"

GUI_FormatStrings:		.include "includes/gui_format_strings.s"
GUI_DisplayStructData:		.include "includes/gui_display_struct_data.s"
ToneGen_ParamTable:		.include "audio/tonegen_param_table.s"
; =============================================================================
; NAKA UI Descriptor Blocks (ROM E0E974-EEF587)
; Screen layouts, style selection, sequencer UI, effect editors,
; chord recognition, MIDI control, language dialogs, style bitmaps
; =============================================================================
.include "ui_widgets/performance_style_screens.s"
	.ascii "     Init       "
	.zero 16

	.include "sequencer/composer_msp_defaults.s"
StrDesc_Empty_0:
	.long StrVal_Empty_0
StrVal_Empty_0:	aligned_string ""
StrDesc_RecordBits:
	.long StrVal_RecBit
	.long StrVal_SoloBit
	.long StrVal_Empty_RecordBits
StrVal_Empty_RecordBits:	aligned_string ""
StrVal_SoloBit:			aligned_string "solobit"
StrVal_RecBit:			aligned_string "recbit"
StrDesc_Empty_1:
	.long StrVal_Empty_1
StrVal_Empty_1:	aligned_string ""
StrDesc_Empty_2:
	.long StrVal_Empty_2
StrVal_Empty_2:	aligned_string ""
StrDesc_Empty_3:
	.long StrVal_Empty_3
StrVal_Empty_3:	aligned_string ""
StrDesc_Empty_4:
	.long StrVal_Empty_4
StrVal_Empty_4:	aligned_string ""
StrDesc_Empty_5:
	.long StrVal_Empty_5
StrVal_Empty_5:	aligned_string ""
StrDesc_Empty_6:
	.long StrVal_Empty_6
StrVal_Empty_6:	aligned_string ""
StrDesc_Empty_7:
	.long StrVal_Empty_7
StrVal_Empty_7:	aligned_string ""
StrDesc_Empty_8:
	.long StrVal_Empty_8
StrVal_Empty_8:	aligned_string ""
StrDesc_BankPair_0:
	.long StrFld_BankPair_0_Bank
	.long StrVal_BankPair_0_Empty
StrVal_BankPair_0_Empty:	aligned_string ""
StrFld_BankPair_0_Bank:	aligned_string "bank"
StrDesc_BankPair_1:
	.long StrFld_BankPair_1_Bank
	.long StrVal_BankPair_1_Empty
StrVal_BankPair_1_Empty:	aligned_string ""
StrFld_BankPair_1_Bank:	aligned_string "bank"
StrDesc_RamField:
	.long StrVal_RamField_Empty
StrVal_RamField_Empty:	aligned_string ""
StrDesc_RamNamePair:
	.long StrFld_RamNamePair_Ram
	.long StrVal_RamNamePair_Empty
StrVal_RamNamePair_Empty:	aligned_string ""
StrFld_RamNamePair_Ram:	aligned_string "ram"
StrDesc_ApcDataPair:
	.long StrFld_ApcDataPair_ApcData
	.long StrVal_ApcDataPair_Empty
StrVal_ApcDataPair_Empty:	aligned_string ""
StrFld_ApcDataPair_ApcData:	aligned_string "apcdata"
StrDesc_MspBnkPair_0:
	jr	f, 0x6a
	.byte 0xe1, 0x00
	.long StrVal_MspBnkPair_0_Empty
StrVal_MspBnkPair_0_Empty:	aligned_string ""
StrFld_MspBnkPair_0_MspBnk:	aligned_string "mspbnk"
StrDesc_MspBnkPair_1:
	.long StrFld_MspBnkPair_1_MspBnk
	.long StrVal_MspBnkPair_1_Empty
StrVal_MspBnkPair_1_Empty:	aligned_string ""
StrFld_MspBnkPair_1_MspBnk:	aligned_string "mspbnk"
StrDesc_Empty_9:
	.long StrVal_Empty_9
StrVal_Empty_9:	aligned_string ""
StrDesc_Empty_10:
	.long StrVal_Empty_10
StrVal_Empty_10:	aligned_string ""
StrDesc_Empty_11:
	.long StrVal_Empty_11
StrVal_Empty_11:	aligned_string ""
StrDesc_Empty_12:
	.long StrVal_Empty_12
StrVal_Empty_12:	aligned_string ""
StrDesc_Empty_13:
	.long StrVal_Empty_13
StrVal_Empty_13:	aligned_string ""
GridProperty_Config_Table:
	.long StrFld_GridConfig_FixedCol
	.long StrFld_GridConfig_FixedRow
	.long StrFld_GridConfig_Func
	.long StrVal_GridConfig_Empty
StrVal_GridConfig_Empty:	aligned_string ""
StrFld_GridConfig_Func:	aligned_string "func"
StrFld_GridConfig_FixedRow:	aligned_string "fixedrow"
StrFld_GridConfig_FixedCol:	aligned_string "fixedcol"
StrDesc_Empty_14:
	.long StrVal_Empty_14
StrVal_Empty_14:	aligned_string ""
GridProperty_AltConfig_Table:
	.long StrFld_AltGridConfig_FixedCol
	.long StrFld_AltGridConfig_FixedRow
	.long StrFld_AltGridConfig_Func
	.long StrVal_AltGridConfig_Empty
StrVal_AltGridConfig_Empty:	aligned_string ""
StrFld_AltGridConfig_Func:	aligned_string "func"
StrFld_AltGridConfig_FixedRow:	aligned_string "fixedrow"
StrFld_AltGridConfig_FixedCol:	aligned_string "fixedcol"
StrDesc_Empty_15:
	.long StrVal_Empty_15
StrVal_Empty_15:	aligned_string ""
StrDesc_Empty_16:
	.long StrVal_Empty_16
StrVal_Empty_16:	aligned_string ""
StrDesc_Empty_17:
	.long StrVal_Empty_17
StrVal_Empty_17:	aligned_string ""
StrDesc_Empty_18:
	.long StrVal_Empty_18
StrVal_Empty_18:	aligned_string ""
StrDesc_Empty_19:
	.long StrVal_Empty_19
StrVal_Empty_19:	aligned_string ""
StrDesc_CstmCpNameBox:
	.long StrFld_CstmCpName_CstmNo
	.long StrVal_Empty_CstmCpName
StrVal_Empty_CstmCpName:	aligned_string ""
StrFld_CstmCpName_CstmNo:	aligned_string "cstmno"
StrDesc_AcApcToggle:
	.long StrFld_ApcToggle_Func
	.long StrFld_ApcToggle_PmanAd
	.long StrVal_Empty_AcApcToggle
StrVal_Empty_AcApcToggle:	aligned_string ""
StrFld_ApcToggle_PmanAd:	aligned_string "pman_ad"
StrFld_ApcToggle_Func:		aligned_string "func"
StrDesc_AcSndArgGrid:
	.long StrFld_SndArgGrid_FixedCol
	.long StrFld_SndArgGrid_FixedRow
	.long StrFld_SndArgGrid_Func
	.long StrVal_Empty_AcSndArgGrid
StrVal_Empty_AcSndArgGrid:	aligned_string ""
StrFld_SndArgGrid_Func:		aligned_string "func"
StrFld_SndArgGrid_FixedRow:	aligned_string "fixedrow"
StrFld_SndArgGrid_FixedCol:	aligned_string "fixedcol"


StrDesc_PsParaListBox:
	.long StrFld_ParaList_Font
	.long StrFld_ParaList_FontColor
	.long StrFld_ParaList_Column
	.long StrFld_ParaList_Row
	.long StrFld_ParaList_SelNum
	.long StrVal_Empty_PsParaList
StrVal_Empty_PsParaList:	aligned_string ""
StrFld_ParaList_SelNum:		aligned_string "sel_num"
StrFld_ParaList_Row:
	.byte 0x72, 0x6f, 0x77, 0x00
StrFld_ParaList_Column:		aligned_string "column"
StrFld_ParaList_FontColor:	aligned_string "fontcolor"
StrFld_ParaList_Font:
	jr	z, 0x6f
	.byte 0x6e, 0x74, 0x00, 0xff, 0xb0, 0x6b, 0xe1, 0x00
	.byte 0x00, 0xff
StrDesc_PsSCTxtBox2:
	.long StrVal_Empty_PsSCTxtBox2
StrVal_Empty_PsSCTxtBox2:	aligned_string ""
StrDesc_VwVariBox:
	.long StrFld_VwVari_Font
	.long StrFld_VwVari_FontColor
	.long StrFld_VwVari_Align
	.long StrFld_VwVari_EditSw
	.long StrFld_VwVari_Selected
	.long StrFld_VwVari_MspBnk
	.long StrVal_Empty_VwVariBox
StrVal_Empty_VwVariBox:		aligned_string ""
StrFld_VwVari_MspBnk:		aligned_string "mspbnk"
StrFld_VwVari_Selected:		aligned_string "selected"
StrFld_VwVari_EditSw:		aligned_string "editsw"
StrFld_VwVari_Align:		aligned_string "align"
StrFld_VwVari_FontColor:	aligned_string "fontcolor"
StrFld_VwVari_Font:		aligned_string "font"


StrDesc_YajirushiBox:
	.long StrFld_Yajirushi_Color
	.long StrFld_Yajirushi_FrameOnly
	.long StrFld_Yajirushi_Dir
	.long StrFld_Yajirushi_TailXRate
	.long StrFld_Yajirushi_TailYRate
	.long StrVal_Empty_Yajirushi
StrVal_Empty_Yajirushi:		aligned_string ""
StrFld_Yajirushi_TailYRate:	aligned_string "tail_y_rate"
StrFld_Yajirushi_TailXRate:	aligned_string "tail_x_rate"
StrFld_Yajirushi_Dir:
	.byte 0x64, 0x69, 0x72, 0x00
StrFld_Yajirushi_FrameOnly:	aligned_string "frame_only"
StrFld_Yajirushi_Color:		aligned_string "color"
StrDesc_CmpNameMenuBox:
	.long StrVal_Empty_CmpNameMenu
StrVal_Empty_CmpNameMenu:	aligned_string ""
StrDesc_S2cGridBox:
	.long StrFld_S2cGrid_FixedCol
	.long StrFld_S2cGrid_FixedRow
	.long StrFld_S2cGrid_Func
	.long StrVal_Empty_S2cGridBox
StrVal_Empty_S2cGridBox:	aligned_string ""
StrFld_S2cGrid_Func:		aligned_string "func"
StrFld_S2cGrid_FixedRow:	aligned_string "fixedrow"
StrFld_S2cGrid_FixedCol:	aligned_string "fixedcol"
StrDesc_PsStylCnvVer:
	.long StrVal_Empty_PsStylCnvVer
StrVal_Empty_PsStylCnvVer:	aligned_string ""
	.long AcMemNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_AcMemNoBox
	.long StrEmpty_AcMemNoBox
	.long StrDesc_Empty_0
	.long AcCmpRecBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x26, 0x00
	.byte 0x02, 0x00
	.long StrName_AcCmpRecBox
	.long StrPrefix_AcCmpRecBox
	.long StrDesc_RecordBits
	.long PsCmpQtzBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCmpQtzBox
	.long StrEmpty_PsCmpQtzBox
	.long StrDesc_Empty_1
	.long PsCmpMeasBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCmpMeasBox
	.long StrEmpty_PsCmpMeasBox
	.long StrDesc_Empty_2
	.long PsCmpMemBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCmpMemBox
	.long StrEmpty_PsCmpMemBox
	.long StrDesc_Empty_3
	.long AcS2cMemNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_AcS2cMemNoBox
	.long StrEmpty_AcS2cMemNoBox
	.long StrDesc_Empty_4
	.long PsS2cFmeasBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsS2cFmeasBox
	.long StrEmpty_PsS2cFmeasBox
	.long StrDesc_Empty_5
	.long PsS2cLmeasBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsS2cLmeasBox
	.long StrEmpty_PsS2cLmeasBox
	.long StrDesc_Empty_6
	.long PsSeqSongNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsSeqSongNoBox
	.long StrEmpty_PsSeqSongNoBox
	.long StrDesc_Empty_7
	.long PsS2cTransBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsS2cTransBox
	.long StrEmpty_PsS2cTransBox
	.long StrDesc_Empty_8
	.long PsCstmCpBnkBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x26, 0x00
	.byte 0x02, 0x00
	.long StrName_PsCstmCpBnkBox
	.long StrPrefix_PsCstmCpBnkBox
	.long StrDesc_BankPair_0
	.long PsCstmCpSwBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x26, 0x00
	.byte 0x02, 0x00
	.long StrName_PsCstmCpSwBox
	.long StrPrefix_PsCstmCpSwBox
	.long StrDesc_BankPair_1
	.long PsCtmAttStrBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCtmAttStrBox
	.long StrEmpty_PsCtmAttStrBox
	.long StrDesc_RamField
	.long AcCmpMdBoxProc
	naka_header NAKA_TYPE_0x15
	.byte 0x34, 0x00
	.byte 0x02, 0x00
	.long StrName_AcCmpMdBox
	.long StrPrefix_AcCmpMdBox
	.long StrDesc_RamNamePair
	.long AcApcMdBoxProc
	naka_header NAKA_TYPE_0x15
	.byte 0x34, 0x00
	.byte 0x02, 0x00
	.long StrName_AcApcMdBox
	.long StrPrefix_AcApcMdBox
	.long StrDesc_ApcDataPair
	.long AcMspBnkSlBoxProc
	naka_header NAKA_TYPE_0x15
	.byte 0x34, 0x00
	.byte 0x02, 0x00
	.long StrName_AcMspBnkSlBox
	.long StrPrefix_AcMspBnkSlBox
	.long StrDesc_MspBnkPair_0
	.long PsMspBnkNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x26, 0x00
	.byte 0x02, 0x00
	.long StrName_PsMspBnkNameBox
	.long StrPrefix_PsMspBnkNameBox
	.long StrDesc_MspBnkPair_1
	.long AcCmpTempoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_AcCmpTempoBox
	.long StrEmpty_AcCmpTempoBox
	.long StrDesc_Empty_9
	.long PsCmpCpFGrpBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCmpCpFGrpBox
	.long StrEmpty_PsCmpCpFGrpBox
	.long StrDesc_Empty_10
	.long PsCmpCpFVariBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCmpCpFVariBox
	.long StrEmpty_PsCmpCpFVariBox
	.long StrDesc_Empty_11
	.long PsCmpCpFPtnBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsCmpCpFPtnBox
	.long StrEmpty_PsCmpCpFPtnBox
	.long StrDesc_Empty_12
	.long PsNameMemBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsNameMemBox
	.long StrEmpty_PsNameMemBox
	.long StrDesc_Empty_13
	.long AcCmpSetGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00
	.byte 0x0c, 0x00
	.long StrName_AcCmpSetGridBox
	.long StrPrefix_AcCmpSetGrid
	.long GridProperty_Config_Table
	.long PsRgpSetBnkBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsRgpSetBnkBox
	.long StrEmpty_PsRgpSetBnkBox
	.long StrDesc_Empty_14
	.long AcEasyCmpGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00
	.byte 0x0c, 0x00
	.long StrName_AcEasyCmpGridBox
	.long StrPrefix_AcEasyCmpGrid
	.long GridProperty_AltConfig_Table
	.long PsMspMeasBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsMspMeasBox
	.long StrEmpty_PsMspMeasBox
	.long StrDesc_Empty_15
	.long PsMspMemBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsMspMemBox
	.long StrEmpty_PsMspMemBox
	.long StrDesc_Empty_16
	.long PsMspRecPadBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsMspRecPadBox
	.long StrEmpty_PsMspRecPadBox
	.long StrDesc_Empty_17
	.long PsMspRecBnkBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsMspRecBnkBox
	.long StrEmpty_PsMspRecBnkBox
	.long StrDesc_Empty_18
	.long PsMspNameBnkProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsMspNameBnk
	.long StrEmpty_PsMspNameBnk
	.long StrDesc_Empty_19
	.long PsCstmCpNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x26, 0x00
	.byte 0x02, 0x00
	.long StrName_PsCstmCpNameBox
	.long LABEL_E1711E
	.long StrDesc_CstmCpNameBox
	.long AcApcToggleProc
	naka_header NAKA_TYPE_0x26
	.byte 0x30, 0x00
	.byte 0x08, 0x00
	.long LABEL_E17112
	.long StrPrefix_AcApcToggle
	.long StrDesc_AcApcToggle
	.long AcSndArgGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00
	.byte 0x0c, 0x00
	.long StrName_AcSndArgGridBox
	.long StrPrefix_AcSndArgGrid
	.long StrDesc_AcSndArgGrid
	.long PsParaListBoxProc
	naka_header NAKA_TYPE_0x11
	.byte 0x2a, 0x00
	.byte 0x0e, 0x00
	.long StrName_PsParaListBox
	.long StrExtra_ParaList_JpChars
	.long StrDesc_PsParaListBox
	.long PsSCTxtBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsSCTxtBox
	.long StrEmpty_PsSCTxtBox
	.long LABEL_E16BAC
	.long PsSCTxtBox2Proc
	naka_header NAKA_TYPE_0x65
	.byte 0x26, 0x00
	.byte 0x00, 0x00
	.long StrName_PsSCTxtBox2
	.long StrEmpty_PsSCTxtBox2
	.long StrDesc_PsSCTxtBox2
	.long VwVariBoxProc
	naka_header NAKA_TYPE_0x11
	.byte 0x2c, 0x00
	.byte 0x10, 0x00
NakaDesc_VwVariBox_DataPtrs:
	.long StrName_VwVariBox
	.long StrExtra_Yajirushi_JpChars2
	.long StrDesc_VwVariBox
	.long StylCnvStorBnk_ProcDataBlock
	naka_header NAKA_TYPE_0x10
	.byte 0x20, 0x00
	.byte 0x0a, 0x00
	.long StrName_YajirushiBox
	.long StrExtra_Yajirushi_JpChars
	.long StrDesc_YajirushiBox
	.long CmpNameMenuBoxProc
	naka_header NAKA_TYPE_0x3D
	.byte 0x32, 0x00
	.byte 0x00, 0x00
	.long StrName_CmpNameMenuBox
	.long LABEL_E17096
	.long StrDesc_CmpNameMenuBox
	.long S2cGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00
	.byte 0x0c, 0x00
	.long LABEL_E1708A
	.long StrPrefix_S2cGridBox
	.long StrDesc_S2cGridBox
	.long PsStylCnvVerProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00
	.byte 0x00, 0x00
	.long StrName_PsStylCnvVer
	.long StrEmpty_PsStylCnvVer
	.long StrDesc_PsStylCnvVer
	.zero 24
StrEmpty_PsStylCnvVer:	aligned_string ""
StrName_PsStylCnvVer:	aligned_string "PsStylCnvVer"
StrPrefix_S2cGridBox:
	.byte 0x58, 0x58
	jr	gt, 0x00
	aligned_string "S2cGridBox"
	.byte 0x00, 0xff
StrName_CmpNameMenuBox:		aligned_string "CmpNameMenuBox"
StrExtra_Yajirushi_JpChars:	aligned_string "^GBBB"
StrName_YajirushiBox:		aligned_string "Yajirushi"
StrExtra_Yajirushi_JpChars2:	aligned_string "c^demC"
StrName_VwVariBox:		aligned_string "VwVariBox"
StrEmpty_PsSCTxtBox2:		aligned_string ""
StrName_PsSCTxtBox2:		aligned_string "PSSCTxtBox2"
StrEmpty_PsSCTxtBox:		aligned_string ""
StrName_PsSCTxtBox:		aligned_string "PsSCTxtBox"
StrExtra_ParaList_JpChars:	.asciz "c^AAn"
StrName_PsParaListBox:		aligned_string "PsParaListBox"
StrPrefix_AcSndArgGrid:
	.byte 0x58, 0x58, 0x6a, 0x00
StrName_AcSndArgGridBox:	aligned_string "AcSndArgGridBox"
StrPrefix_AcApcToggle:
	jr	gt, 0x46
	.byte 0x00, 0xff
	aligned_string "AcApcToggle"
	.byte 0x43, 0x00
StrName_PsCstmCpNameBox:	aligned_string "PsCstmCpNameBox"
StrEmpty_PsMspNameBnk:		aligned_string ""
StrName_PsMspNameBnk:		aligned_string "PsMspNameBnk"
StrEmpty_PsMspRecBnkBox:	aligned_string ""
StrName_PsMspRecBnkBox:		aligned_string "PsMspRecBnkBox"
StrEmpty_PsMspRecPadBox:	aligned_string ""
StrName_PsMspRecPadBox:		aligned_string "PsMspRecPadBox"
StrEmpty_PsMspMemBox:		aligned_string ""
StrName_PsMspMemBox:		aligned_string "PsMspMemBox"
StrEmpty_PsMspMeasBox:		aligned_string ""
StrName_PsMspMeasBox:		aligned_string "PsMspMeasBox"
StrPrefix_AcEasyCmpGrid:
	.byte 0x58, 0x58, 0x6a, 0x00
StrName_AcEasyCmpGridBox:	aligned_string "AcEasyCmpGridBox"
StrEmpty_PsRgpSetBnkBox:	aligned_string ""
StrName_PsRgpSetBnkBox:		aligned_string "PsRgpSetBnkBox"
StrPrefix_AcCmpSetGrid:
	.byte 0x58, 0x58, 0x6a, 0x00
StrName_AcCmpSetGridBox:	aligned_string "AcCmpSetGridBox"
StrEmpty_PsNameMemBox:		aligned_string ""
StrName_PsNameMemBox:		aligned_string "PsNameMemBox"
StrEmpty_PsCmpCpFPtnBox:	aligned_string ""
StrName_PsCmpCpFPtnBox:		aligned_string "PsCmpCpFPtnBox"
StrEmpty_PsCmpCpFVariBox:	aligned_string ""
StrName_PsCmpCpFVariBox:	aligned_string "PsCmpCpFVariBox"
StrEmpty_PsCmpCpFGrpBox:	aligned_string ""
StrName_PsCmpCpFGrpBox:		aligned_string "PsCmpCpFGrpBox"
StrEmpty_AcCmpTempoBox:		aligned_string ""
StrName_AcCmpTempoBox:		aligned_string "AcCmpTempoBox"
StrPrefix_PsMspBnkNameBox:
	.byte 0x43, 0x00
StrName_PsMspBnkNameBox:	aligned_string "PsMspBnkNameBox"
StrPrefix_AcMspBnkSlBox:
	.byte 0x43, 0x00
StrName_AcMspBnkSlBox:	aligned_string "AcMspBnkSlBox"
StrPrefix_AcApcMdBox:
	.byte 0x43, 0x00
StrName_AcApcMdBox:	aligned_string "AcApcMdBox"
StrPrefix_AcCmpMdBox:
	.byte 0x43, 0x00
StrName_AcCmpMdBox:		aligned_string "AcCmpMdBox"
StrEmpty_PsCtmAttStrBox:	aligned_string ""
StrName_PsCtmAttStrBox:		aligned_string "PsCtmAttStrBox"
StrPrefix_PsCstmCpSwBox:
	.byte 0x43, 0x00
StrName_PsCstmCpSwBox:	aligned_string "PsCstmCpSwBox"
StrPrefix_PsCstmCpBnkBox:
	.byte 0x43, 0x00
StrName_PsCstmCpBnkBox:		aligned_string "PsCstmCpBnkBox"
StrEmpty_PsS2cTransBox:		aligned_string ""
StrName_PsS2cTransBox:		aligned_string "PsS2cTransBox"
StrEmpty_PsSeqSongNoBox:	aligned_string ""
StrName_PsSeqSongNoBox:		aligned_string "PsSeqSongNoBox"
StrEmpty_PsS2cLmeasBox:		aligned_string ""
StrName_PsS2cLmeasBox:		aligned_string "PsS2cLmeasBox"
StrEmpty_PsS2cFmeasBox:		aligned_string ""
StrName_PsS2cFmeasBox:		aligned_string "PsS2cFmeasBox"
StrEmpty_AcS2cMemNoBox:		aligned_string ""
StrName_AcS2cMemNoBox:		aligned_string "AcS2cMemNoBox"
StrEmpty_PsCmpMemBox:		aligned_string ""
StrName_PsCmpMemBox:		aligned_string "PsCmpMemBox"
StrEmpty_PsCmpMeasBox:		aligned_string ""
StrName_PsCmpMeasBox:		aligned_string "PsCmpMeasBox"
StrEmpty_PsCmpQtzBox:		aligned_string ""
StrName_PsCmpQtzBox:		aligned_string "PsCmpQtzBox"
StrPrefix_AcCmpRecBox:
	.byte 0x43, 0x43, 0x00, 0xff
StrName_AcCmpRecBox:	aligned_string "AcCmpRecBox"
StrEmpty_AcMemNoBox:	aligned_string ""
StrName_AcMemNoBox:	aligned_string "AcMemNoBox"
	.byte 0x29, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00
NakaMethodTable_PtrsStart:
	.long MTStr_CmpNameSet
	.long MTStr_MspNameSet
	.long MTStr_RhyGrpNmGet
	.long MTStr_RhyVariNmGet
	.long MTStr_APRHYGRPNM
	.long MTStr_APRHYVARINM
	.long MTStr_CmpClrYes
	.long MTStr_CmpClrNo
	.long MTStr_PanUp
	.long MTStr_PanDn
	.long MTStr_RLmtUp
	.long MTStr_RLmtDn
	.long MTStr_PanValGet
	.long MTStr_RLmtValGet
	.long MTStr_CmpSetP1Up
	.long MTStr_CmpSetP1Dn
	.long MTStr_S2cTrUp
	.long MTStr_S2cTrDn
	.long MTStr_RgpBnkUp
	.long MTStr_RgpBnkDn
	.long MTStr_RgpPadUp
	.long MTStr_RgpPadDn
	.long MTStr_CstmCpOk
	.long MTStr_MspUsr1NmGet
	.long MTStr_MspUsr2NmGet
	.long MTStr_MspRgp1NmGet
	.long MTStr_MspRgp2NmGet
	.long MTStr_MspUsr1NmDisp
	.long MTStr_MspUsr2NmDisp
	.long MTStr_MspRgp1NmDisp
	.long MTStr_MspRgp2NmDisp
	.long MTStr_MspPlyMdSet
	.long MTStr_ArgToneNmGet
	.long MTStr_ArgChoGet
	.long MTStr_ArgToneNmDisp
	.long MTStr_ArgChoDisp
	.long MTStr_SetPtSel
	.long MTStr_EsCmpPartUp
	.long MTStr_EsCmpPartDn
	.long MTStr_EsCmpStylUp
	.long MTStr_EsCmpStylDn
	.long MTStr_EsCmpVariUp
	.long MTStr_EsCmpVariDn
	.long MTStr_CstmFNmGet
	.long MTStr_CstmTNmGet
	.long MTStr_CstmFNmDisp
	.long MTStr_CstmTNmDisp
	.long MTStr_SetSelectedLine
	.long MTStr_StylCnvStor
	.long MTStr_ClrGridHanten
	.byte 0x00, 0x00, 0x00, 0x00
MTStr_ClrGridHanten:	aligned_string "MT_ClrGridHanten"
MTStr_StylCnvStor:	aligned_string "MT_StylCnvStor"
MTStr_SetSelectedLine:	aligned_string "MT_SetSelectedLine"
MTStr_CstmTNmDisp:	aligned_string "MT_CstmTNmDisp"
MTStr_CstmFNmDisp:	aligned_string "MT_CstmFNmDisp"
MTStr_CstmTNmGet:	aligned_string "MT_CstmTNmGet"
MTStr_CstmFNmGet:	aligned_string "MT_CstmFNmGet"
MTStr_EsCmpVariDn:	aligned_string "MT_EsCmpVariDn"
MTStr_EsCmpVariUp:	aligned_string "MT_EsCmpVariUp"
MTStr_EsCmpStylDn:	aligned_string "MT_EsCmpStylDn"
MTStr_EsCmpStylUp:	aligned_string "MT_EsCmpStylUp"
MTStr_EsCmpPartDn:	aligned_string "MT_EsCmpPartDn"
MTStr_EsCmpPartUp:	aligned_string "MT_EsCmpPartUp"
MTStr_SetPtSel:	aligned_string "MT_SetPtSel"
MTStr_ArgChoDisp:	aligned_string "MT_ArgChoDisp"
MTStr_ArgToneNmDisp:	aligned_string "MT_ArgToneNmDisp"
MTStr_ArgChoGet:	aligned_string "MT_ArgChoGet"
MTStr_ArgToneNmGet:	aligned_string "MT_ArgToneNmGet"
MTStr_MspPlyMdSet:	aligned_string "MT_MspPlyMdSet"
MTStr_MspRgp2NmDisp:	aligned_string "MT_MspRgp2NmDisp"
MTStr_MspRgp1NmDisp:	aligned_string "MT_MspRgp1NmDisp"
MTStr_MspUsr2NmDisp:	aligned_string "MT_MspUsr2NmDisp"
MTStr_MspUsr1NmDisp:	aligned_string "MT_MspUsr1NmDisp"
MTStr_MspRgp2NmGet:	aligned_string "MT_MspRgp2NmGet"
MTStr_MspRgp1NmGet:	aligned_string "MT_MspRgp1NmGet"
MTStr_MspUsr2NmGet:	aligned_string "MT_MspUsr2NmGet"
MTStr_MspUsr1NmGet:	aligned_string "MT_MspUsr1NmGet"
MTStr_CstmCpOk:	aligned_string "MT_CstmCpOk"
MTStr_RgpPadDn:	aligned_string "MT_RgpPadDn"
MTStr_RgpPadUp:	aligned_string "MT_RgpPadUp"
MTStr_RgpBnkDn:	aligned_string "MT_RgpBnkDn"
MTStr_RgpBnkUp:	aligned_string "MT_RgpBnkUp"
MTStr_S2cTrDn:	aligned_string "MT_S2cTrDn"
MTStr_S2cTrUp:	aligned_string "MT_S2cTrUp"
MTStr_CmpSetP1Dn:	aligned_string "MT_CmpSetP1Dn"
MTStr_CmpSetP1Up:	aligned_string "MT_CmpSetP1Up"
MTStr_RLmtValGet:	aligned_string "MT_RLmtValGet"
MTStr_PanValGet:	aligned_string "MT_PanValGet"
MTStr_RLmtDn:	aligned_string "MT_RLmtDn"
MTStr_RLmtUp:	aligned_string "MT_RLmtUp"
MTStr_PanDn:	aligned_string "MT_PanDn"
MTStr_PanUp:	aligned_string "MT_PanUp"
MTStr_CmpClrNo:	aligned_string "MT_CmpClrNo"
MTStr_CmpClrYes:	aligned_string "MT_CmpClrYes"
MTStr_APRHYVARINM:	aligned_string "MT_APRHYVARINM"
MTStr_APRHYGRPNM:	aligned_string "MT_APRHYGRPNM"
MTStr_RhyVariNmGet:	aligned_string "MT_RhyVariNmGet"
MTStr_RhyGrpNmGet:	aligned_string "MT_RhyGrpNmGet"
MTStr_MspNameSet:	aligned_string "MT_MspNameSet"
MTStr_CmpNameSet:	aligned_string "MT_CmpNameSet"
	.byte 0x32, 0x00, 0xb1, 0xdf, 0xf1, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0xe6, 0x76, 0xe1, 0x00
	.long NakaStr_PaintArrowProc_Empty
.include "ui_widgets/composer_style_convert_screens.s"
	.short 0x0
	.long Naka_PresentationRootState
	.byte 0xff, 0x00, 0x00, 0x00, 0x01, 0x00, 0xa0, 0x01, 0x26, 0xd7, 0x03, 0x00
	.long String_MSP_BANK_SELECT
	.long 0xA5

String_MSP_BANK_SELECT:
	aligned_string "MSP BANK SELECT"

NakaNode_Accomp7_Widget01:
	naka_header NAKA_TYPE_0x25
	.byte 0x00, 0x00, 0xff, 0xff, 0x02, 0x00
	.byte 0xff, 0xff, 0x08, 0x00, 0xf5, 0x00, 0x06, 0x00
	.byte 0x3b, 0x01, 0x17, 0x00, 0xf3, 0x00, 0xc1, 0x00
	.byte 0xff, 0xff, 0x2a, 0xd7, 0x03, 0x00, 0x01, 0x00
	.byte 0x02, 0x00
NakaNode_Accomp7_Widget02:


	naka_header NAKA_TYPE_0x28
	.byte 0x00, 0x00
	.byte 0xff, 0xff, 0x03, 0x00, 0x01, 0x00, 0x18, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x1f, 0x00, 0x1f, 0x00
	.byte 0x01, 0x00, 0x06, 0x00, 0xc8, 0x00
NakaNode_Accomp7_Widget03:


	naka_header NAKA_TYPE_0x28
	.byte 0x00, 0x00, 0xff, 0xff, 0x04, 0x00
	.byte 0x02, 0x00, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x1f, 0x00, 0x1f, 0x00, 0x02, 0x00, 0x11, 0x00
	.byte 0xc8, 0x00
NakaNode_Accomp7_Widget04:


	naka_header NAKA_TYPE_0x64
	.byte 0x00, 0x00
	.byte 0xff, 0xff, 0x05, 0x00, 0x03, 0x00, 0x18, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x1f, 0x00, 0x1f, 0x00
	.byte 0x16, 0x00, 0x24, 0x01
NakaNode_Accomp7_Widget05:


	naka_header NAKA_TYPE_0x62
	.byte 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0x04, 0x00
	.byte 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0x00
	.byte 0x1f, 0x00, 0x01, 0x00
NakaNode_Accomp7_Widget06:


	naka_header NAKA_TYPE_0x35
	.byte 0xff, 0xff, 0x07, 0x00, 0xff, 0xff, 0xff, 0xff
	.byte 0x08, 0x00, 0x00, 0x00, 0x1e, 0x00, 0x3f, 0x01
	.byte 0xef, 0x00, 0xf5, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x2c, 0xd7, 0x03, 0x00, 0x30, 0xd7, 0x03, 0x00
NakaNode_Accomp7_Widget07:
	.byte 0x24, 0x00, 0x64, 0x01, 0x06, 0x00, 0xff, 0xff
	.byte 0x08, 0x00, 0xff, 0xff, 0x08, 0x00, 0x08, 0x00
	.byte 0x1e, 0x00, 0x9c, 0x00, 0x37, 0x00, 0x07, 0x00
	.byte 0xc1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x01, 0x00, 0x88, 0x00, 0x34, 0xd7
	.byte 0x03, 0x00, 0x00, 0x00
NakaNode_Accomp7_Widget08:
	.byte 0x24, 0x00, 0x64, 0x01
	.byte 0x06, 0x00, 0xff, 0xff, 0x09, 0x00, 0x07, 0x00
	.byte 0x08, 0x00, 0x08, 0x00, 0x48, 0x00, 0x9c, 0x00
	.byte 0x61, 0x00, 0x07, 0x00, 0xc1, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00
	.byte 0x89, 0x00, 0x36, 0xd7, 0x03, 0x00, 0x01, 0x00
NakaNode_Accomp7_Widget09:
	.byte 0x24, 0x00, 0x64, 0x01, 0x06, 0x00, 0xff, 0xff
	.byte 0x0a, 0x00, 0x08, 0x00, 0x08, 0x00, 0x08, 0x00
	.byte 0x72, 0x00, 0x9c, 0x00, 0x8b, 0x00, 0x07, 0x00
	.byte 0xc1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x01, 0x00, 0x8a, 0x00, 0x38, 0xd7
	.byte 0x03, 0x00, 0x02, 0x00
NakaNode_Accomp7_Widget10:
	.byte 0x24, 0x00, 0x64, 0x01
	.byte 0x06, 0x00, 0xff, 0xff, 0x0b, 0x00, 0x09, 0x00
	.byte 0x08, 0x00, 0x08, 0x00, 0x9c, 0x00, 0x9c, 0x00
	.byte 0xb5, 0x00, 0x07, 0x00, 0xc1, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00
	.byte 0x8b, 0x00, 0x3a, 0xd7, 0x03, 0x00, 0x03, 0x00
NakaNode_Accomp7_Widget11:
	.byte 0x24, 0x00, 0x64, 0x01, 0x06, 0x00, 0xff, 0xff
	.byte 0x0c, 0x00, 0x0a, 0x00, 0x08, 0x00, 0x08, 0x00
	.byte 0xc6, 0x00, 0x9c, 0x00, 0xdf, 0x00, 0x07, 0x00
	.byte 0xc1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x01, 0x00, 0x8c, 0x00, 0x3c, 0xd7
	.byte 0x03, 0x00, 0x04, 0x00
NakaNode_Accomp7_Widget12:
	.byte 0x24, 0x00, 0x64, 0x01
	.byte 0x06, 0x00, 0xff, 0xff, 0x0d, 0x00, 0x0b, 0x00
	.byte 0x08, 0x00, 0xa3, 0x00, 0x1e, 0x00, 0x37, 0x01
	.byte 0x37, 0x00, 0x07, 0x00, 0xc1, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00
	.byte 0x08, 0x00, 0x3e, 0xd7, 0x03, 0x00, 0x05, 0x00
NakaNode_Accomp7_Widget13:
	.byte 0x24, 0x00, 0x64, 0x01, 0x06, 0x00, 0xff, 0xff
	.byte 0x0e, 0x00, 0x0c, 0x00, 0x08, 0x00, 0xa3, 0x00
	.byte 0x48, 0x00, 0x37, 0x01, 0x61, 0x00, 0x07, 0x00
	.byte 0xc1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x01, 0x00, 0x09, 0x00, 0x40, 0xd7
	.byte 0x03, 0x00, 0x06, 0x00
NakaNode_Accomp7_Widget14:
	.byte 0x24, 0x00, 0x64, 0x01
	.byte 0x06, 0x00, 0xff, 0xff, 0x0f, 0x00, 0x0d, 0x00
	.byte 0x08, 0x00, 0xa3, 0x00, 0x72, 0x00, 0x37, 0x01
	.byte 0x8b, 0x00, 0x07, 0x00, 0xc1, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00
	.byte 0x0a, 0x00, 0x42, 0xd7, 0x03, 0x00, 0x07, 0x00
NakaNode_Accomp7_Widget15:
	.byte 0x24, 0x00, 0x64, 0x01, 0x06, 0x00, 0xff, 0xff
	.byte 0x10, 0x00, 0x0e, 0x00, 0x08, 0x00, 0xa3, 0x00
	.byte 0x9c, 0x00, 0x37, 0x01, 0xb5, 0x00, 0x07, 0x00
	.byte 0xc1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x01, 0x00, 0x0b, 0x00, 0x44, 0xd7
	.byte 0x03, 0x00, 0x08, 0x00
NakaNode_Accomp7_Widget16:
	.byte 0x24, 0x00, 0x64, 0x01
	.byte 0x06, 0x00, 0xff, 0xff, 0xff, 0xff, 0x0f, 0x00
	.byte 0x08, 0x00, 0xa3, 0x00, 0xc6, 0x00, 0x37, 0x01
	.byte 0xdf, 0x00, 0x07, 0x00, 0xc1, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00
	.byte 0x0c, 0x00, 0x46, 0xd7, 0x03, 0x00, 0x09, 0x00
NakaNode_Accomp7_Widget17:


	naka_header NAKA_TYPE_0x35
	.byte 0xff, 0xff, 0x12, 0x00
	.byte 0xff, 0xff, 0xff, 0xff, 0x08, 0x00, 0x00, 0x00
	.byte 0x1e, 0x00
	.long Naka_PresentationRootState
	.byte 0xf5, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x48, 0xd7, 0x03, 0x00
	.byte 0x4c, 0xd7, 0x03, 0x00
NakaNode_Accomp7_Widget18:
	.byte 0x24, 0x00, 0x64, 0x01
	.byte 0x11, 0x00, 0xff, 0xff, 0x13, 0x00, 0xff, 0xff
	.byte 0x08, 0x00, 0x08, 0x00, 0x1e, 0x00, 0x9c, 0x00
	.byte 0x37, 0x00, 0x07, 0x00, 0xc1, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00
	.byte 0x88, 0x00, 0x50, 0xd7, 0x03, 0x00, 0x0a, 0x00
NakaNode_Accomp7_Widget19:
	.byte 0x24, 0x00, 0x64, 0x01, 0x11, 0x00, 0xff, 0xff
	.byte 0x14, 0x00, 0x12, 0x00, 0x08, 0x00, 0x08, 0x00
	.byte 0x48, 0x00, 0x9c, 0x00, 0x61, 0x00, 0x07, 0x00
	.byte 0xc1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x01, 0x00, 0x89, 0x00, 0x52, 0xd7
	.byte 0x03, 0x00, 0x0b, 0x00
NakaNode_Accomp7_Widget20:
	.byte 0x24, 0x00, 0x64, 0x01
	.byte 0x11, 0x00, 0xff, 0xff, 0x15, 0x00, 0x13, 0x00
	.byte 0x08, 0x00, 0x08, 0x00, 0x72, 0x00, 0x9c, 0x00
	.byte 0x8b, 0x00, 0x07, 0x00, 0xc1, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00
	.byte 0x8a, 0x00, 0x54, 0xd7, 0x03, 0x00, 0x0c, 0x00
NakaNode_Accomp7_Widget21:
	.byte 0x24, 0x00, 0x64, 0x01, 0x11, 0x00, 0xff, 0xff
	.byte 0x16, 0x00, 0x14, 0x00, 0x08, 0x00, 0x08, 0x00
	.byte 0x9c, 0x00, 0x9c, 0x00, 0xb5, 0x00, 0x07, 0x00
	.byte 0xc1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x01, 0x00, 0x8b, 0x00, 0x56, 0xd7
	.byte 0x03, 0x00, 0x0d, 0x00
NakaNode_Accomp7_Widget22:
	.byte 0x24, 0x00, 0x64, 0x01
	.byte 0x11, 0x00, 0xff, 0xff, 0x17, 0x00, 0x15, 0x00
	.byte 0x08, 0x00, 0x08, 0x00, 0xc6, 0x00, 0x9c, 0x00
	.byte 0xdf, 0x00, 0x07, 0x00, 0xc1, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00
	.byte 0x8c, 0x00, 0x58, 0xd7, 0x03, 0x00, 0x0e, 0x00
NakaNode_Accomp7_Widget23:
	.byte 0x24, 0x00, 0x64, 0x01, 0x11, 0x00, 0xff, 0xff
	.byte 0x18, 0x00, 0x16, 0x00, 0x08, 0x00, 0xa3, 0x00
	.byte 0x1e, 0x00, 0x37, 0x01, 0x37, 0x00, 0x07, 0x00
	.byte 0xc1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x01, 0x00, 0x08, 0x00, 0x5a, 0xd7
	.byte 0x03, 0x00, 0x0f, 0x00
NakaNode_Accomp7_Widget24:
	.byte 0x24, 0x00, 0x64, 0x01
	.byte 0x11, 0x00, 0xff, 0xff, 0x19, 0x00, 0x17, 0x00
	.byte 0x08, 0x00, 0xa3, 0x00, 0x48, 0x00, 0x37, 0x01
	.byte 0x61, 0x00, 0x07, 0x00, 0xc1, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00
	.byte 0x09, 0x00, 0x5c, 0xd7, 0x03, 0x00, 0x10, 0x00
NakaNode_Accomp7_Widget25:
	.byte 0x24, 0x00, 0x64, 0x01, 0x11, 0x00, 0xff, 0xff
	.byte 0x1a, 0x00, 0x18, 0x00, 0x08, 0x00, 0xa3, 0x00
	.byte 0x72, 0x00, 0x37, 0x01, 0x8b, 0x00, 0x07, 0x00
	.byte 0xc1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x01, 0x00, 0x0a, 0x00, 0x5e, 0xd7
	.byte 0x03, 0x00, 0x11, 0x00
NakaNode_Accomp7_Widget26:
	.byte 0x24, 0x00, 0x64, 0x01
	.byte 0x11, 0x00, 0xff, 0xff, 0xff, 0xff, 0x19, 0x00
	.byte 0x08, 0x00, 0xa3, 0x00, 0x9c, 0x00, 0x37, 0x01
	.byte 0xb5, 0x00, 0x07, 0x00, 0xc1, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00
	.byte 0x0b, 0x00, 0x60, 0xd7, 0x03, 0x00, 0x12, 0x00
.include "ui_widgets/msp_recording_screens.s"
.include "ui_widgets/naka_screen_dispatch.s"
.include "factory_test/test_data.s"
.include "factory_test/fd_test_data.s"
RESOURCE_INFO_HANDLER_OFFSETS:
	.short RESOURCE_INFO_HANDLERS - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetSRAMBankRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetUserAreaRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetSndParamRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetVoiceBankRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetToneGenRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetFlashBankRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetMspSettingsRange - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetResourceListPtr - RESOURCE_INFO_HANDLERS
	.short ResInfo_GetTableDataInfo - RESOURCE_INFO_HANDLERS

SepaOut_Config_0:
	.short 0xB0
	.short 0x19B

SepaOut_Config_1:
	.short 0xB0
	.short 0x209B

SepaOut_Config_2:
	.short 0xB0
	.short 0x9D

SepaOut_Config_3:
	.short 0xB0
	.short 0x19D

SepaOut_Config_4:
	.short 0xB0
	.short 0x29D

SepaOut_LayoutParams_0:
	.byte 0x00, 0x00, 0x0e, 0x00, 0x1a, 0x00
	.byte 0x1a
SepaOut_LayoutByte_0:
	.byte 0x00
SepaOut_LayoutByte_1:
	.byte 0x1a
SepaOut_LayoutByte_2:
	.byte 0x00
SepaOut_LayoutByte_3:
	.byte 0x1a
SepaOut_LayoutByte_4:
	.byte 0x00
SepaOut_LayoutByte_5:
	.byte 0x00, 0x00
	.byte 0x0e, 0x00, 0x1a, 0x00, 0x1a, 0x00, 0x1a, 0x00
	.byte 0x1a, 0x00, 0x00, 0x00, 0x33, 0x00, 0xa3, 0x00
	.byte 0x4c, 0x00, 0xa3, 0x00, 0xa3, 0x00, 0x00, 0x00
	.byte 0x3e, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00
	.byte 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01
SepaOut_LayoutParams_1:
	.byte 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00
	.byte 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0e, 0x00
	.byte 0x5a, 0x00, 0x5a, 0x00, 0x5a, 0x00, 0x5a, 0x00
	.byte 0x00, 0x00, 0x0e, 0x00, 0x5a, 0x00, 0x5a, 0x00
	.byte 0x5a, 0x00, 0x5a, 0x00, 0x01, 0x00, 0x02, 0x00
SepaOut_BitMaskTable:
	.byte 0x04, 0x00, 0x08, 0x00, 0x10, 0x00, 0x20, 0x00
	.byte 0x40, 0x00, 0x80, 0x00, 0x00, 0x01, 0x00, 0x02
	.byte 0x00, 0x04, 0x00, 0x08, 0x00, 0x10, 0x00, 0x20
	.byte 0x00, 0x40, 0x00, 0x80, 0x00, 0x00, 0x01, 0x00
	.byte 0x02, 0x00, 0x03, 0x00, 0x04, 0x00, 0x05, 0x00
	.byte 0x06, 0x00, 0x07, 0x00, 0x08, 0x00, 0x09, 0x00
	.byte 0x0a, 0x00, 0x0b, 0x00, 0x0c, 0x00, 0x0d, 0x00
	.byte 0x0e, 0x00, 0x0f, 0x00, 0x10, 0x00, 0x11, 0x00
	.byte 0x12, 0x00, 0x13, 0x00, 0x14, 0x00, 0x15, 0x00
	.byte 0x16, 0x00, 0x17, 0x00, 0x18, 0x00, 0x19, 0x00
	.byte 0x1a, 0x00, 0x1b, 0x00, 0x1c, 0x00, 0x1d, 0x00
	.byte 0x1e, 0x00, 0x1f, 0x00, 0x00, 0x00, 0x1e, 0x00
	.byte 0x7a, 0x00, 0xb8, 0x00, 0x0f, 0x00, 0x4c, 0x00
	.byte 0x98, 0x00, 0x00, 0x00, 0x1b, 0x00, 0x74, 0x00
	.byte 0x74, 0x00, 0x74, 0x00, 0x74, 0x00, 0x00, 0x00
	.byte 0x1b, 0x00, 0x74, 0x00, 0x74, 0x00, 0x74, 0x00
	.byte 0x74, 0x00, 0x00, 0x00, 0x28, 0x00, 0x81, 0x00
	.byte 0x81, 0x00, 0x81, 0x00, 0x81, 0x00, 0x00, 0x00
	.byte 0x49, 0x00, 0xa7, 0x00, 0x5a
SepaOut_FormatData_Tail:
	.byte 0x00, 0xa7, 0x00
	.byte 0xa7, 0x00
	aligned_string "%2d : %s"
	aligned_string "FILE%02d:%s"
	aligned_string "%03d:%s"
	aligned_string "%02d:%s"
	aligned_string "%02d:%s"
	.byte 0x00, 0x00, 0x48, 0x00, 0x81, 0x00, 0xc1, 0x00
	.byte 0xb9, 0x02, 0x3b, 0x01, 0x0d, 0x01, 0xb5, 0x01
	.byte 0x87, 0x01, 0xb9, 0x02, 0xb9, 0x02, 0xb9, 0x02
	.byte 0xfd, 0x01, 0x59, 0x02, 0x00, 0x00, 0x05, 0x00
	.byte 0x29, 0x00, 0x6b, 0x00, 0x2e, 0x00, 0x6b, 0x00
	.byte 0x6b, 0x00, 0x6b, 0x00, 0x3a, 0x00, 0x35, 0x00
	.byte 0x00, 0x00
	.byte 0x13, 0x00, 0xe1, 0x00, 0xe1, 0x00, 0xe1, 0x00
	.byte 0xe1, 0x00, 0x00, 0x00, 0x05, 0x00
	.byte 0x29, 0x00, 0x6b, 0x00, 0x2e, 0x00, 0x6b, 0x00
	.byte 0x6b, 0x00, 0x6b, 0x00, 0x3a, 0x00, 0x35, 0x00
	.byte 0x00, 0x00
	.byte 0x13, 0x00, 0xe1, 0x00, 0xe1, 0x00, 0xe1, 0x00
	.byte 0xe1, 0x00, 0x00, 0x00, 0x05, 0x00
	.byte 0x29, 0x00, 0x6b, 0x00, 0x2e, 0x00, 0x6b, 0x00
	.byte 0x6b, 0x00, 0x6b, 0x00, 0x3a, 0x00, 0x35, 0x00
	.byte 0x00, 0x00, 0x21, 0x00, 0x07, 0x01, 0x07, 0x01
	.byte 0x07, 0x01, 0x07, 0x01, 0x00, 0x00, 0x0e, 0x00


	.byte 0xd5, 0x00, 0x14, 0x00, 0xd5, 0x00, 0xd5, 0x00
	.byte 0x00, 0x00, 0x0e, 0x00, 0x1a, 0x00, 0x1a, 0x00
	.byte 0x1a, 0x00, 0x1a, 0x00, 0x62, 0x22, 0xf2, 0x00
	.byte 0x88, 0x22, 0xf2, 0x00, 0x95, 0x22, 0xf2, 0x00
	.byte 0xa2, 0x22, 0xf2, 0x00, 0x00, 0x00, 0x8f, 0x00
	.byte 0x8f, 0x00, 0x8f, 0x00, 0x8f, 0x00, 0x8f, 0x00
	.byte 0x00, 0x00, 0x8a, 0x00, 0x8a, 0x00, 0x8a, 0x00
	.byte 0x8a, 0x00, 0x8a, 0x00, 0x00, 0x00, 0x8a, 0x00
	.byte 0x8a, 0x00, 0x8a, 0x00, 0x8a, 0x00, 0x8a, 0x00
	.byte 0x00, 0x00, 0x13, 0x00, 0x97, 0x00, 0x97, 0x00
	.byte 0x2e, 0x00, 0x3c, 0x00, 0x66, 0x00, 0x74, 0x00
	.byte 0x4a, 0x00, 0x58, 0x00, 0x82, 0x00, 0x88, 0x00
	.byte 0x8d, 0x00
	aligned_string "%3d%%"
	.byte 0x01, 0x00, 0xe1, 0x00, 0x02, 0x00, 0xe1, 0x00
	.byte 0x03, 0x00, 0xe1, 0x00, 0x04, 0x00, 0xe1, 0x00
	.byte 0x05, 0x00, 0xe1, 0x00, 0x06, 0x00, 0xe1, 0x00
	.byte 0x01, 0x00, 0xe2, 0x00, 0x02, 0x00, 0xe2, 0x00
	.byte 0x03, 0x00, 0xe2, 0x00, 0x04, 0x00, 0xe2, 0x00
	.byte 0x05, 0x00, 0xe2, 0x00, 0x06, 0x00, 0xe2, 0x00
	.byte 0x01, 0x00, 0xe3, 0x00, 0x02, 0x00, 0xe3, 0x00
	.byte 0x03, 0x00, 0xe3, 0x00, 0x04, 0x00, 0xe3, 0x00
	.byte 0x05, 0x00, 0xe3, 0x00, 0x06, 0x00, 0xe3, 0x00
	.byte 0x00, 0x00, 0x03, 0x00, 0x06, 0x00, 0x00, 0x00
	.byte 0x09, 0x00, 0x23, 0x00, 0x30, 0x00, 0x16, 0x00
	.byte 0x2c, 0xa9, 0xf2, 0x00, 0x3d, 0xa9, 0xf2, 0x00
	.byte 0x4e, 0xa9, 0xf2, 0x00, 0x5f, 0xa9, 0xf2, 0x00
	.byte 0x70, 0xa9, 0xf2, 0x00, 0x81, 0xa9, 0xf2, 0x00
	.byte 0x92, 0xa9, 0xf2, 0x00, 0xa3, 0xa9, 0xf2, 0x00
	.byte 0x88, 0xcc, 0xf2, 0x00, 0x16, 0xcc, 0xf2, 0x00
	.byte 0x27, 0xcc, 0xf2, 0x00, 0xe8, 0xcc, 0xf2, 0x00
	.byte 0x4d, 0xcd, 0xf2, 0x00, 0x36, 0xce, 0xf2, 0x00
	.byte 0xbb, 0xce, 0xf2, 0x00, 0xfa, 0xce, 0xf2, 0x00
	.byte 0x39, 0xcf, 0xf2, 0x00, 0x79, 0xcf, 0xf2, 0x00
	.byte 0xe3, 0xcf, 0xf2, 0x00, 0xb9, 0xcf, 0xf2, 0x00
	.byte 0x77, 0xc4, 0xf2, 0x00, 0xb2, 0xd0, 0xf2, 0x00
	.byte 0x2a, 0xd1, 0xf2, 0x00, 0xa2, 0xd1, 0xf2, 0x00
	.byte 0xa3, 0xb5, 0xf2, 0x00, 0x9a, 0xb6, 0xf2, 0x00
	.byte 0xd0, 0xb6, 0xf2, 0x00, 0x77, 0xb7, 0xf2, 0x00
	.byte 0x6c, 0xb9, 0xf2, 0x00, 0xba, 0xba, 0xf2, 0x00
	.byte 0x1e, 0xb8, 0xf2, 0x00, 0xc5, 0xb8, 0xf2, 0x00
	.byte 0x13, 0xba, 0xf2, 0x00, 0x61, 0xbb, 0xf2, 0x00
	.byte 0x9d, 0xc9, 0xf2, 0x00, 0xfb, 0xca, 0xf2, 0x00
	.byte 0x6f, 0xcb, 0xf2, 0x00, 0x5c, 0xca, 0xf2, 0x00
	.byte 0x1e, 0xbf, 0xf2, 0x00, 0xda, 0xcd, 0xf2, 0x00
	.byte 0x32, 0xaa, 0xf2, 0x00, 0x0a, 0xb2, 0xf2, 0x00
	.byte 0xc5, 0xb3, 0xf2, 0x00, 0xb4, 0xb4, 0xf2, 0x00
	.byte 0x3c, 0xd0, 0xf2, 0x00, 0x1a, 0xd2, 0xf2, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0xfc, 0x06, 0xe2, 0x00
DbgStr_NakaProcName_Table:
	.long DbgStr_AfterLangCheck
	.long DbgStr_TrAsPreLangCheck
	.long DbgStr_AtentionLangCheck
	.long DbgStr_AreYouSureLangCheck
	.long DbgStr_GmOnSureLangCheck
	.long DbgStr_GmOffSureLangCheck
	.long DbgStr_TrAsSureLangCheck
	.long DbgStr_SqTrAsPsSongFunc
	.long DbgStr_DemoSongSelFunc
	.long DbgStr_SmfMuteChSelFunc
	.long DbgStr_SqAftSetFunc
	.long DbgStr_MuteChSetFunc
	.long DbgStr_SMFMuteOnOffFunc
	.long DbgStr_Rt1MuteFunc
	.long DbgStr_Rt2MuteFunc
	.long DbgStr_DocOrchMuteFunc
	.long DbgStr_PdOrchMuteFunc
	.long DbgStr_SeqNamingCheck
	.long DbgStr_SeqNameOKFunc
	.long DbgStr_TrAsGridCheck
	.long DbgStr_DemoMedDspCheck
	.long DbgStr_DPPlayDspCheck
	.long DbgStr_DPPauseDspCheck
	.long DbgStr_MeasureBoxProc
	.long DbgStr_MeasureBoxFunc
	.long DbgStr_AcDiskFileNameBoxProc
	.long DbgStr_AcSmfFileNameBoxProc
	.long DbgStr_AcDocFileNoBoxProc
	.long DbgStr_AcPDFileNoBoxProc
	.long DbgStr_AcSmfSongNameBoxProc
	.long DbgStr_AcDocSongNameBoxProc
	.long DbgStr_AcPDSongNameBoxProc
	.long DbgStr_IvNamingExitProc
	.long DbgStr_AcModeSelBoxProc
	.long DbgStr_AcCurrentSongBoxProc
	.long DbgStr_AcCurSongNameBoxProc
	.long DbgStr_AcDemoSongBoxProc
	.long DbgStr_AcTrAsGridBoxProc
	.long DbgStr_AcMuteToggleBoxProc
	.long DbgStr_LyricsBoxProc
	.long DbgStr_LyricsBoxFuncProc
	.long DbgStr_SongNameBoxProc
	.long DbgStr_ComporserNameBoxProc
	.long DbgStr_AcDemoMedleyDispBoxProc
	.long DbgStr_IvExitModeTrSelProc
	.long DbgStr_EmptyProc
DbgStr_EmptyProc:			aligned_string ""
DbgStr_IvExitModeTrSelProc:			aligned_string "IvExitModeTrSelProc"
DbgStr_AcDemoMedleyDispBoxProc:			aligned_string "AcDemoMedleyDispBoxProc"
DbgStr_ComporserNameBoxProc:			aligned_string "ComporserNameBoxProc"
DbgStr_SongNameBoxProc:			aligned_string "SongNameBoxProc"
DbgStr_LyricsBoxFuncProc:			aligned_string "LyricsBoxFuncProc"
DbgStr_LyricsBoxProc:			aligned_string "LyricsBoxProc"
DbgStr_AcMuteToggleBoxProc:			aligned_string "AcMuteToggleBoxProc"
DbgStr_AcTrAsGridBoxProc:			aligned_string "AcTrAsGridBoxProc"
DbgStr_AcDemoSongBoxProc:			aligned_string "AcDemoSongBoxProc"
DbgStr_AcCurSongNameBoxProc:			aligned_string "AcCurSongNameBoxProc"
DbgStr_AcCurrentSongBoxProc:			aligned_string "AcCurrentSongBoxProc"
DbgStr_AcModeSelBoxProc:			aligned_string "AcModeSelBoxProc"
DbgStr_IvNamingExitProc:			aligned_string "IvNamingExitProc"
DbgStr_AcPDSongNameBoxProc:			aligned_string "AcPDSongNameBoxProc"
DbgStr_AcDocSongNameBoxProc:			aligned_string "AcDocSongNameBoxProc"
DbgStr_AcSmfSongNameBoxProc:			aligned_string "AcSmfSongNameBoxProc"
DbgStr_AcPDFileNoBoxProc:			aligned_string "AcPDFileNoBoxProc"
DbgStr_AcDocFileNoBoxProc:			aligned_string "AcDocFileNoBoxProc"
DbgStr_AcSmfFileNameBoxProc:			aligned_string "AcSmfFileNameBoxProc"
DbgStr_AcDiskFileNameBoxProc:			aligned_string "AcDiskFileNameBoxProc"
DbgStr_MeasureBoxFunc:		aligned_string "MeasureBoxFunc"
DbgStr_MeasureBoxProc:		aligned_string "MeasureBoxProc"
DbgStr_DPPauseDspCheck:		aligned_string "DPPauseDspCheck"
DbgStr_DPPlayDspCheck:		aligned_string "DPPlayDspCheck"
DbgStr_DemoMedDspCheck:		aligned_string "DemoMedDspCheck"
DbgStr_TrAsGridCheck:		aligned_string "TrAsGridCheck"
DbgStr_SeqNameOKFunc:		aligned_string "SeqNameOKFunc"
DbgStr_SeqNamingCheck:		aligned_string "SeqNamingCheck"
DbgStr_PdOrchMuteFunc:		aligned_string "PdOrchMuteFunc"
DbgStr_DocOrchMuteFunc:		aligned_string "DocOrchMuteFunc"
DbgStr_Rt2MuteFunc:		aligned_string "Rt2MuteFunc"
DbgStr_Rt1MuteFunc:		aligned_string "Rt1MuteFunc"
DbgStr_SMFMuteOnOffFunc:	aligned_string "SMFMuteOnOffFunc"
DbgStr_MuteChSetFunc:		aligned_string "MuteChSetFunc"
DbgStr_SqAftSetFunc:		aligned_string "SqAftSetFunc"
DbgStr_SmfMuteChSelFunc:	aligned_string "SmfMuteChSelFunc"
DbgStr_DemoSongSelFunc:		aligned_string "DemoSongSelFunc"
DbgStr_SqTrAsPsSongFunc:	aligned_string "SqTrAsPsSongFunc"
DbgStr_TrAsSureLangCheck:	aligned_string "TrAsSureLangCheck"
DbgStr_GmOffSureLangCheck:	aligned_string "GmOffSureLangCheck"
DbgStr_GmOnSureLangCheck:	aligned_string "GmOnSureLangCheck"
DbgStr_AreYouSureLangCheck:	aligned_string "AreYouSureLangCheck"
DbgStr_AtentionLangCheck:	aligned_string "AtentionLangCheck"
DbgStr_TrAsPreLangCheck:	aligned_string "TrAsPreLangCheck"
DbgStr_AfterLangCheck:		aligned_string "AfterLangCheck"
DbgStr_PartSelLangCheck:	aligned_string "PartSelLangCheck"
NakaPropTbl_IvNamingExit:
	.long NakaPropStr_IvNamingExit_0
NakaPropStr_IvNamingExit_0:	aligned_string ""
NakaPropTbl_SelBox:
	.long NakaPropStr_SelBox_Font
	.long NakaPropStr_SelBox_FontColor
	.long NakaPropStr_SelBox_MainFunc
	.long NakaPropStr_SelBox_Column
	.long NakaPropStr_SelBox_Row
	.long NakaPropStr_SelBox_SelNum
	.long NakaPropStr_SelBox_Dial
	.long NakaPropStr_SelBox_AutoInc
	.long NakaPropStr_SelBox_0
NakaPropStr_SelBox_0:	aligned_string ""
NakaPropStr_SelBox_AutoInc:		aligned_string "auto_inc"
NakaPropStr_SelBox_Dial:		aligned_string "dial"
NakaPropStr_SelBox_SelNum:		aligned_string "sel_num"
NakaPropStr_SelBox_Row:
	.byte 0x72, 0x6f, 0x77, 0x00
NakaPropStr_SelBox_Column:	aligned_string "column"
NakaPropStr_SelBox_MainFunc:	aligned_string "main_func"
NakaPropStr_SelBox_FontColor:	aligned_string "fontcolor"
NakaPropStr_SelBox_Font:	aligned_string "font"
NakaPropTbl_Ram:
	.long NakaPropStr_Ram_1
	.long NakaPropStr_Ram_0
NakaPropStr_Ram_0:	aligned_string ""
NakaPropStr_Ram_1:
	.byte 0x72, 0x61, 0x6d, 0x00
NakaPropTbl_Func:
	.long NakaPropStr_Func_Func
	.long NakaPropStr_Func_0
NakaPropStr_Func_0:	aligned_string ""
NakaPropStr_Func_Func:		aligned_string "func"
NakaPropTbl_CurSongName:
	.long NakaPropStr_CurSongName_0
NakaPropStr_CurSongName_0:	aligned_string ""
NakaPropTbl_TrAsGrid:
	.long NakaPropStr_TrAsGrid_0
NakaPropStr_TrAsGrid_0:	aligned_string ""
NakaPropTbl_Grid:
	.long NakaPropStr_Grid_FixedCol
	.long NakaPropStr_Grid_FixedRow
	.long NakaPropStr_Grid_Func
	.long NakaPropStr_Grid_0
NakaPropStr_Grid_0:	aligned_string ""
NakaPropStr_Grid_Func:		aligned_string "func"
NakaPropStr_Grid_FixedRow:		aligned_string "fixedrow"
NakaPropStr_Grid_FixedCol:		aligned_string "fixedcol"
NakaPropTbl_SmfFileName:
	.long NakaPropStr_SmfFileName_0
NakaPropStr_SmfFileName_0:	aligned_string ""
NakaPropTbl_DocFileNo:
	.long NakaPropStr_DocFileNo_0
NakaPropStr_DocFileNo_0:	aligned_string ""
NakaPropTbl_PdFileNo:
	.long NakaPropStr_PdFileNo_0
NakaPropStr_PdFileNo_0:	aligned_string ""
NakaPropTbl_SmfSongName:
	.long NakaPropStr_SmfSongName_0
NakaPropStr_SmfSongName_0:	aligned_string ""
NakaPropTbl_DocSongName:
	.long NakaPropStr_DocSongName_0
NakaPropStr_DocSongName_0:	aligned_string ""
NakaPropTbl_PdSongName:
	.long NakaPropStr_PdSongName_0
NakaPropStr_PdSongName_0:	aligned_string ""
NakaPropTbl_MeasureBox:
	.long NakaPropStr_MeasureBox_0
NakaPropStr_MeasureBox_0:	aligned_string ""
NakaPropTbl_MuteToggle:
	.long NakaPropStr_MuteToggle_Color
	.long NakaPropStr_MuteToggle_FontColor
	.long NakaPropStr_MuteToggle_Func
	.long NakaPropStr_MuteToggle_0
NakaPropStr_MuteToggle_0:	aligned_string ""
NakaPropStr_MuteToggle_Func:			aligned_string "func"
NakaPropStr_MuteToggle_FontColor:			aligned_string "fontcolor"
NakaPropStr_MuteToggle_Color:			aligned_string "color"
NakaPropTbl_LyricsBox:
	.long NakaPropStr_LyricsBox_0
NakaPropStr_LyricsBox_0:	aligned_string ""
NakaPropTbl_TextLabel:
	.long NakaPropStr_TextLabel_Font
	.long NakaPropStr_TextLabel_FontColor
	.long NakaPropStr_TextLabel_ReverseColor
	.long NakaPropStr_TextLabel_Alignment
	.long NakaPropStr_TextLabel_Lines
	.long NakaPropStr_TextLabel_0
NakaPropStr_TextLabel_0:	aligned_string ""
NakaPropStr_TextLabel_Lines:			aligned_string "lines"
NakaPropStr_TextLabel_Alignment:			aligned_string "alignment"
NakaPropStr_TextLabel_ReverseColor:			aligned_string "reversecolor"
NakaPropStr_TextLabel_FontColor:			aligned_string "fontcolor"
NakaPropStr_TextLabel_Font:			aligned_string "font"


NakaPropTbl_TextLabel2:
	.long NakaPropStr_TextLabel2_Font
	.long NakaPropStr_TextLabel2_FontColor
	.long NakaPropStr_TextLabel2_Alignment
	.long NakaPropStr_TextLabel2_Lines
	.long NakaPropStr_TextLabel2_0
NakaPropStr_TextLabel2_0:	aligned_string ""
NakaPropStr_TextLabel2_Lines:			aligned_string "lines"
NakaPropStr_TextLabel2_Alignment:			aligned_string "alignment"
NakaPropStr_TextLabel2_FontColor:			aligned_string "fontcolor"
NakaPropStr_TextLabel2_Font:
	jr	z, 0x6f
	.byte 0x6e, 0x74, 0x00, 0xff, 0xd4, 0x08, 0xe2, 0x00


NakaPropTbl_LyricsBoxFunc:
	.long NakaPropStr_LyricsBoxFunc_FontColor
	.long NakaPropStr_LyricsBoxFunc_Alignment
	.long NakaPropStr_LyricsBoxFunc_Lines
	.long NakaPropStr_LyricsBoxFunc_0
NakaPropStr_LyricsBoxFunc_0:	aligned_string ""
NakaPropStr_LyricsBoxFunc_Lines:			aligned_string "lines"
NakaPropStr_LyricsBoxFunc_Alignment:			aligned_string "alignment"
NakaPropStr_LyricsBoxFunc_FontColor:			aligned_string "fontcolor"
NakaPropStr_LyricsBoxFunc_Font:			aligned_string "font"
NakaPropTbl_DemoMedleyDisp:
	.long NakaPropStr_DemoMedleyDisp_0
NakaPropStr_DemoMedleyDisp_0:	aligned_string ""
NakaPropTbl_IvExitModeTrSel:
	.long NakaPropStr_IvExitModeTrSel_0
NakaPropStr_IvExitModeTrSel_0:	aligned_string ""
NakaPropTbl_IvExitModeTrSelEnd:
	.long NakaPropStr_IvExitModeTrSelEnd_0
NakaPropStr_IvExitModeTrSelEnd_0:	.byte 0x00, 0xff, 0x61, 0xbb, 0xf2, 0x00


	naka_header NAKA_TYPE_0x47
	.byte 0x16, 0x00, 0x00, 0x00
NakaWidgetList_AcModeBoxes:
	.long NakaBoxName_IvNamingExit
	.long NakaBoxData_IvNamingExit
	.long NakaPropTbl_IvNamingExit
	.long IvNamingExit_ScreenData
	naka_header NAKA_TYPE_0x11
	.byte 0x32, 0x00, 0x16, 0x00
	.long NakaBoxName_PsSongSelBoxProc
	.long NakaBoxEnc_PsSongSelBox
	.long NakaPropTbl_SelBox
	.long AcModeSelBoxProc
	naka_header NAKA_TYPE_0x15
	.byte 0x34, 0x00, 0x02, 0x00
	.long NakaBoxName_AcModeSelBox
	.long NakaBoxData_AcModeSelBox
	.long NakaPropTbl_Ram
	.long AcDemoSongBoxProc
	naka_header NAKA_TYPE_0x15
	.byte 0x36, 0x00, 0x04, 0x00
	.long NakaBoxName_AcDemoSongBox
	.long NakaBoxData_AcDemoSongBox
	.long NakaPropTbl_Func
	.long AcCurrentSongBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcCurrentSongBox
	.long NakaBoxData_AcCurrentSongBox
	.long NakaPropTbl_CurSongName
	.long AcCurSongNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcCurSongNameBox
	.long NakaBoxData_AcCurSongNameBox
	.long NakaPropTbl_TrAsGrid
	.long AcTrAsGridBoxProc
	naka_header NAKA_TYPE_0x54
	.byte 0x4a, 0x00, 0x0c, 0x00
	.long NakaBoxName_AcTrAsGridBox
	.long NakaBoxData_AcTrAsGridBox
	.long NakaPropTbl_Grid
	.long AcDiskFileNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcDiskFileNameBox
	.long NakaBoxData_AcDiskFileNameBox
	.long NakaPropTbl_SmfFileName
	.long AcSmfFileNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcSmfFileNameBox
	.long NakaBoxData_AcSmfFileNameBox
	.long NakaPropTbl_DocFileNo
	.long AcDocFileNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcDocFileNoBox
	.long NakaBoxData_AcDocFileNoBox
	.long NakaPropTbl_PdFileNo
	.long AcPDFileNoBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcPDFileNoBox
	.long NakaBoxData_AcPDFileNoBox
	.long NakaPropTbl_SmfSongName
	.long AcSmfSongNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcSmfSongNameBox
	.long NakaBoxData_AcSmfSongNameBox
	.long NakaPropTbl_DocSongName
	.long AcDocSongNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcDocSongNameBox
	.long NakaBoxData_AcDocSongNameBox
	.long NakaPropTbl_PdSongName
	.long AcPDSongNameBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcPDSongNameBox
	.long NakaBoxData_AcPDSongNameBox
	.long NakaPropTbl_MeasureBox
	.long MeasureBoxProc
	naka_header NAKA_TYPE_0x10
	.byte 0x1e, 0x00, 0x08, 0x00
	.long NakaBoxName_MeasureBox
	.long NakaBoxData_MeasureBox
	.long NakaPropTbl_MuteToggle
	.long AcMuteToggleBoxProc
	naka_header NAKA_TYPE_0x44
	.byte 0x2c, 0x00, 0x00, 0x00
	.long NakaBoxName_AcMuteToggleBox
	.long LABEL_E20B86
	.long NakaPropTbl_LyricsBox
	.long LyricsBoxProc
	naka_header NAKA_TYPE_0x11
	.byte 0x28, 0x00, 0x0c, 0x00
	.long LABEL_E20B7C
	.long NakaBoxData_LyricsBox
	.long NakaPropTbl_TextLabel
	.long SongNameBoxProc
	naka_header NAKA_TYPE_0x11
	.byte 0x26, 0x00, 0x0a, 0x00
	.long NakaBoxName_SongNameBox
	.long NakaBoxData_SongNameBox
	.long NakaPropTbl_TextLabel2
	.long ComporserNameBoxProc
	naka_header NAKA_TYPE_0x11
	.byte 0x26, 0x00, 0x0a, 0x00
	.long NakaBoxName_ComporserNameBox
	.long NakaBoxData_ComporserNameBox
	.long LABEL_E208A4
	.long LyricsBoxFuncProc
	naka_header NAKA_TYPE_0x27
	.byte 0x16, 0x00, 0x00, 0x00
	.long NakaBoxName_LyricsBoxFunc
	.long NakaBoxData_LyricsBoxFunc
	.long NakaPropTbl_DemoMedleyDisp
	.long AcDemoMedleyDispBoxProc
	naka_header NAKA_TYPE_0x12
	.byte 0x24, 0x00, 0x00, 0x00
	.long NakaBoxName_AcDemoMedleyDisp
	.long NakaBoxData_AcDemoMedleyDisp
	.long NakaPropTbl_IvExitModeTrSel
	.long IvExitModeTrSelProc
	naka_header NAKA_TYPE_0x47
	.byte 0x16, 0x00, 0x00, 0x00
	.long NakaBoxName_IvExitModeTrSel
	.long NakaBoxData_IvExitModeTrSel
	.long NakaPropTbl_IvExitModeTrSelEnd
	.zero 24
NakaBoxData_IvExitModeTrSel:	aligned_string ""
NakaBoxName_IvExitModeTrSel:	aligned_string "IvExitModeTrSel"
NakaBoxData_AcDemoMedleyDisp:	aligned_string ""
NakaBoxName_AcDemoMedleyDisp:	aligned_string "AcDemoMedleyDispBox"
NakaBoxData_LyricsBoxFunc:	aligned_string ""
NakaBoxName_LyricsBoxFunc:	aligned_string "LyeicsBoxFunc"
NakaBoxData_ComporserNameBox:	aligned_string "c^dB"
NakaBoxName_ComporserNameBox:	aligned_string "ComporserNameBox"
NakaBoxData_SongNameBox:	aligned_string "c^dB"
NakaBoxName_SongNameBox:	aligned_string "SongNameBox"
NakaBoxData_LyricsBox:
	jr	ule, 0x5e
	.byte 0x5e, 0x64, 0x42, 0x00
	aligned_string "LyricsBox"
	.byte 0x00, 0xff
NakaBoxName_AcMuteToggleBox:	aligned_string "AcMuteToggleBox"
NakaBoxData_MeasureBox:
	.byte 0x5e, 0x5e, 0x6a, 0x00
NakaBoxName_MeasureBox:		aligned_string "MeasureBox"
NakaBoxData_AcPDSongNameBox:	aligned_string ""
NakaBoxName_AcPDSongNameBox:	aligned_string "AcPDSongNameBox"
NakaBoxData_AcDocSongNameBox:	aligned_string ""
NakaBoxName_AcDocSongNameBox:	aligned_string "AcDocSongNameBox"
NakaBoxData_AcSmfSongNameBox:	aligned_string ""
NakaBoxName_AcSmfSongNameBox:	aligned_string "AcSmfSongNameBox"
NakaBoxData_AcPDFileNoBox:	aligned_string ""
NakaBoxName_AcPDFileNoBox:	aligned_string "AcPDFileNoBox"
NakaBoxData_AcDocFileNoBox:	aligned_string ""
NakaBoxName_AcDocFileNoBox:	aligned_string "AcDocFileNoBox"
NakaBoxData_AcSmfFileNameBox:	aligned_string ""
NakaBoxName_AcSmfFileNameBox:	aligned_string "AcSmfFileNameBox"
NakaBoxData_AcDiskFileNameBox:	aligned_string ""
NakaBoxName_AcDiskFileNameBox:	aligned_string "AcDiskFileNameBox"
NakaBoxData_AcTrAsGridBox:
	.byte 0x58, 0x58, 0x6a, 0x00
NakaBoxName_AcTrAsGridBox:	aligned_string "AcTrAsGridBox"
NakaBoxData_AcCurSongNameBox:	aligned_string ""
NakaBoxName_AcCurSongNameBox:	aligned_string "AcCurSongNameBox"
NakaBoxData_AcCurrentSongBox:	aligned_string ""
NakaBoxName_AcCurrentSongBox:	aligned_string "AcCurrentSongBox"
NakaBoxData_AcDemoSongBox:
	.byte 0x6a, 0x00
NakaBoxName_AcDemoSongBox:	aligned_string "AcDemoSongBox"
NakaBoxData_AcModeSelBox:
	.byte 0x43, 0x00
NakaBoxName_AcModeSelBox:	aligned_string "AcModeSelBox"
NakaBoxEnc_PsSongSelBox:	aligned_string "c^kAAnGG"
NakaBoxName_PsSongSelBoxProc:	aligned_string "PsSongSelBox"
NakaBoxData_IvNamingExit:	aligned_string ""
NakaBoxName_IvNamingExit:	aligned_string "IvNamingExit"
	.byte 0x16, 0x00
EvtName_PtrTable:
	.long EvtName_CurSongName
	.long EvtName_DiskFileName
	.long EvtName_SmfFileName
	.long EvtName_SmfSongName
	.long EvtName_DocFileName
	.long EvtName_DocSongName
	.long EvtName_DocFileNo
	.long EvtName_PdSongName
	.long EvtName_PdFileNo
	.long EvtName_AllClear
	.long EvtName_AllDraw
	.long EvtName_Renew
	.long EvtName_Reverse
	.long EvtName_ScrollUp
	.long EvtName_ComporserWrite
	.long EvtName_SongWrite
	.long EvtName_PlayStartIni
	.long EvtName_PlayRequest
	.long EvtName_GetEvent
	.long EvtName_ChangeColor
	.byte 0x00, 0x00, 0x00, 0x00
EvtName_ChangeColor:	aligned_string "EV_ChangeColor"
EvtName_GetEvent:	aligned_string "EV_GetEvent"
EvtName_PlayRequest:	aligned_string "EV_PlayRequest"
EvtName_PlayStartIni:	aligned_string "EV_PlayStartIni"
EvtName_SongWrite:	aligned_string "EV_SONGWRITE"
EvtName_ComporserWrite:	aligned_string "EV_COMPORSERWRITE"
EvtName_ScrollUp:	aligned_string "EV_SCROLLUP"
EvtName_Reverse:	aligned_string "EV_REVERSE"
EvtName_Renew:		aligned_string "EV_RENEW"
EvtName_AllDraw:	aligned_string "EV_ALLDRAW"
EvtName_AllClear:	aligned_string "EV_ALLCLEAR"
EvtName_PdFileNo:	aligned_string "EV_PDFILENO"
EvtName_PdSongName:	aligned_string "EV_PDSONGNAME"
EvtName_DocFileNo:	aligned_string "EV_DOCFILENO"
EvtName_DocSongName:	aligned_string "EV_DOCSONGNAME"
EvtName_DocFileName:	aligned_string "EV_DOCFILENAME"
EvtName_SmfSongName:	aligned_string "EV_SMFSONGNAME"
EvtName_SmfFileName:	aligned_string "EV_SMFFILENAME"
EvtName_DiskFileName:	aligned_string "EV_DISKFILENAME"
EvtName_CurSongName:	aligned_string "EV_CURSONGNAME"
	.byte 0x14, 0x00, 0x5a, 0x10, 0xe2, 0x00
MtName_PtrTable:
	.long MtName_SongNameSet
	.long MtName_PsSongSelBoxID
	.long MtName_SetSelectedFileNum
	.long MtName_TrAsTrackInc
	.long MtName_TrAsTrackDec
	.long MtName_TrAsPartInc
	.long MtName_TrAsPartDec
	.long MtName_TrAsPageInc
	.long MtName_TrAsPageDec
	.long MtName_AmdCall
	.long MtName_DirectPlayMute
	.long MtName_TrackMidiCall
	.long MtName_GetCurSongName
	.long MtName_GetDiskFileName
	.long MtName_GetSmfFileName
	.long MtName_GetSmfSongName
	.long MtName_GetDocFileName
	.long MtName_GetDocSongName
	.long MtName_GetDocFileNo
	.long MtName_GetPDSongName
	.long MtName_GetPDFileNo
	.long MtName_GetMeasString
	.long MtName_GetToggleSw
	.long MtName_LyricsCharaReq
	.long MtName_GetLyricsSongName
	.long MtName_GetComporserName
	.byte 0x00, 0x00, 0x00, 0x00
MtName_GetComporserName:	aligned_string "MT_GetComporserName"
MtName_GetLyricsSongName:	aligned_string "MT_GetLyricsSongName"
MtName_LyricsCharaReq:		aligned_string "MT_LyricsCharaReq"
MtName_GetToggleSw:		aligned_string "MT_GetToggleSw"
MtName_GetMeasString:		aligned_string "MT_GetMeasString"
MtName_GetPDFileNo:		aligned_string "MT_GetPDFileNo"
MtName_GetPDSongName:		aligned_string "MT_GetPDSongName"
MtName_GetDocFileNo:		aligned_string "MT_GetDocFileNo"
MtName_GetDocSongName:		aligned_string "MT_GetDocSongName"
MtName_GetDocFileName:		aligned_string "MT_GetDocFileName"
MtName_GetSmfSongName:		aligned_string "MT_GetSmfSongName"
MtName_GetSmfFileName:		aligned_string "MT_GetSmfFileName"
MtName_GetDiskFileName:		aligned_string "MT_GetDiskFileName"
MtName_GetCurSongName:		aligned_string "MT_GetCurSongName"
MtName_TrackMidiCall:		aligned_string "MT_TrackMidiCall"
MtName_DirectPlayMute:		aligned_string "MT_DirectPlayMute"
MtName_AmdCall:			aligned_string "MT_AmdCall"
MtName_TrAsPageDec:		aligned_string "MT_TrAsPageDec"
MtName_TrAsPageInc:		aligned_string "MT_TrAsPageInc"
MtName_TrAsPartDec:		aligned_string "MT_TrAsPartDec"
MtName_TrAsPartInc:		aligned_string "MT_TrAsPartInc"
MtName_TrAsTrackDec:		aligned_string "MT_TrAsTrackDec"
MtName_TrAsTrackInc:		aligned_string "MT_TrAsTrackInc"
MtName_SetSelectedFileNum:	aligned_string "MT_SetSelectedFileNum"
MtName_PsSongSelBoxID:		aligned_string "MT_PsSongSelBoxID"
MtName_SongNameSet:		aligned_string "MT_SongNameSet"
	aligned_string "MT_DemoSongSel"
	.byte 0x1b, 0x00, 0xf9, 0xbb, 0xf2, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x7e, 0x10, 0xe2, 0x00
	.long NakaBoxData_PsSongSelBox
.include "ui_widgets/direct_play_medley_screens.s"
.include "ui_widgets/naka_widget_tables_1.s"
.include "ui_widgets/sequencer_exit_widgets.s"
	jr	gt, 0x00
	aligned_string "SqedtVal2"
	aligned_string "^^jC"
	aligned_string "SqedtVal"
	.byte 0x6a, 0x43, 0x00, 0xff
	aligned_string "EqualizerBox"
	.byte 0x6a, 0x42
	.byte 0x42, 0x43, 0x00, 0xff
	aligned_string "EffectBox"
	.byte 0x1a, 0x00
EvtEffDraw_PtrTable:
	.long EvtName_EffFixDraw
	.long EvtName_EffParaDraw
	.long EvtName_EqLineDraw
	.long EvtName_EqStrDraw
	.long EvtName_GraphDraw
	.byte 0x00, 0x00, 0x00, 0x00
EvtName_GraphDraw:	aligned_string "EV_GRAPHDRAW"
EvtName_EqStrDraw:	aligned_string "EV_EQSTRDRAW"
EvtName_EqLineDraw:	aligned_string "EV_EQLINEDRAW"
EvtName_EffParaDraw:	aligned_string "EV_EFFPARADRAW"
EvtName_EffFixDraw:	aligned_string "EV_EFFFIXDRAW"
	.byte 0x05, 0x00

MT_FuncName_PtrTable:
	.long MT_GetEffFixString_Name
	.long MT_GetEffDlt0Str_Name
	.long MT_GetEffDlt1Str_Name
	.long MT_GetEffDlt2Str_Name
	.long MT_GetEffDlt3Str_Name
	.long MT_GetEffDlt4Str_Name
	.long MT_GetEffDlt5Str_Name
	.long MT_GetEffDlt6Str_Name
	.long MT_GetEffDlt7Str_Name
	.long MT_GetItemExist_Name
	.long MT_SetItemOff_Name
	.long MT_GetItemOff_Name
	.long MT_SetItemTop_Name
	.long MT_GetItemTop_Name
	.long MT_RetEffFix_Name
	.long MT_RetEffPara_Name
	.long MT_GetParaSize_Name
	.long MT_CngEffType_Name
	.long MT_CngEffPara_Name
	.long MT_GetDispPos_Name
	.long MT_IncVal_Name
	.long MT_DecVal_Name
	.long MT_GetTrkString_Name
	.long MT_GetFMString_Name
	.long MT_GetLMString_Name
	.long MT_GetAdlyString_Name
	.long MT_GetTrnsString_Name
	.long MT_GetVeloString_Name
	.long MT_GetMersString_Name
	.long MT_GetQtzValString_Name
	.long MT_GetQtzStrString_Name
	.long MT_GetQtzWinString_Name
	.long MT_GetTnString_Name
	.long MT_GetCnString_Name
	.long MT_GetMrgTrAString_Name
	.long MT_GetMrgTrBString_Name
	.long MT_GetMrgTrCString_Name
	.long MT_GetMcpTrAString_Name
	.long MT_GetMcpFMString_Name
	.long MT_GetMcpLMString_Name
	.long MT_GetMcpTrBString_Name
	.long MT_GetMcpSMString_Name
	.long MT_GetMcpRepString_Name
	.long MT_GetMinsTrAString_Name
	.long MT_GetMinsFMString_Name
	.long MT_GetMinsLMString_Name
	.long MT_GetMinsTrBString_Name
	.long MT_GetMinsSMString_Name
	.long MT_GetMinsRepString_Name
	.long MT_GetScpFsngString_Name
	.long MT_GetScpFtrString_Name
	.long MT_GetScpTsngString_Name
	.long MT_GetScpTtrString_Name
	.long MT_SetCurPos_Name
	.long MT_GetCurPos_Name
	.long MT_CurToParam_Name
	.long MT_ChkCur_Name
	.long MT_ChkCur2_Name
	.long MT_GetFromCur_Name
	.long MT_SetFromCur_Name
	.long MT_GetToCur_Name
	.long MT_SetToCur_Name
	.long MT_GetMeasString_Name
	.long MT_GetBeatString_Name
	.long MT_GetMemString_Name
	.long MT_GetCycEnString_Name
	.long MT_GetCycSrtMString_Name
	.long MT_GetCycEndMString_Name
	.long MT_SetCycle_Name
	.long MT_SetMetro_Name
	.long MT_SetPunch_Name
	.long MT_GetSoloEnString_Name
	.long MT_GetSclrNoString_Name
	.long MT_GetSclrNameString_Name
	.long MT_GetSclrKbString_Name
	.long MT_GetSclrPerString_Name
	.long MT_GetAccLvlStr_Name
	.long MT_GetPMeasString_Name
	.long MT_GetPInMeasString_Name
	.long MT_GetPOutMeasString_Name
	.long MT_GetPCntInString_Name
	.long MT_GetEndPos_Name
	.long MT_GetTriPos_Name
	.long MT_GetLinePos_Name
	.long MT_GetHakuString_Name
	.long MT_GetPosString_Name
	.long MT_GetIncString_Name
	.long MT_GetNoteString_Name
	.long MT_GetVelString_Name
	.long MT_GetInputVelString_Name
	.long MT_GetLenString_Name
	.long MT_GetInputLenString_Name
	.long MT_GetMeasTopNumSv_Name
	.long MT_GetMeasCngSv_Name
	.long MT_NoteBarDisp_Name
	.long MT_NoteBarDisp2_Name
	.long MT_NoteHilightDisp_Name
	.long MT_GetEq0Str_Name
	.long MT_GetEq1Str_Name
	.long MT_GetEq2Str_Name
	.long MT_GetEq3Str_Name
	.long MT_GetEq4Str_Name
	.long MT_GetEq5Str_Name
	.long MT_GetEq6Str_Name
	.long MT_GetEq7Str_Name
	.long MT_GetTtlNow_Name
	.long MT_GetKb1Str_Name
	.long MT_GetKb2Str_Name
	.long MT_GetDrNumString_Name
	.long MT_GetDrNameString_Name
	.long MT_ChkToggleEditSw_Name
	.long MT_GetLang_Name
	.long MT_SetLang_Name
	.long MT_ChkLang_Name
	.long MT_GetFSngNameString_Name
	.long MT_GetTSngNameString_Name
	.long MT_FlashWrite_Name
	.long MT_FlashLoad_Name
	.long MT_Panic_Name
	.zero 4
MT_Panic_Name:			aligned_string "MT_PANIC"
MT_FlashLoad_Name:		aligned_string "MT_FLASHLOAD"
MT_FlashWrite_Name:		aligned_string "MT_FLASHWRITE"
MT_GetTSngNameString_Name:	aligned_string "MT_GetTSngNameString"
MT_GetFSngNameString_Name:	aligned_string "MT_GetFSngNameString"
MT_ChkLang_Name:		aligned_string "MT_ChkLang"
MT_SetLang_Name:		aligned_string "MT_SetLang"
MT_GetLang_Name:		aligned_string "MT_GetLang"
MT_ChkToggleEditSw_Name:	aligned_string "MT_ChkToggleEditSw"
MT_GetDrNameString_Name:	aligned_string "MT_GetDrNameString"
MT_GetDrNumString_Name:		aligned_string "MT_GetDrNumString"
MT_GetKb2Str_Name:		aligned_string "MT_GetKb2Str"
MT_GetKb1Str_Name:		aligned_string "MT_GetKb1Str"
MT_GetTtlNow_Name:		aligned_string "MT_GetTtlNow"
MT_GetEq7Str_Name:		aligned_string "MT_GetEq7Str"
MT_GetEq6Str_Name:		aligned_string "MT_GetEq6Str"
MT_GetEq5Str_Name:		aligned_string "MT_GetEq5Str"
MT_GetEq4Str_Name:		aligned_string "MT_GetEq4Str"
MT_GetEq3Str_Name:		aligned_string "MT_GetEq3Str"
MT_GetEq2Str_Name:		aligned_string "MT_GetEq2Str"
MT_GetEq1Str_Name:		aligned_string "MT_GetEq1Str"
MT_GetEq0Str_Name:		aligned_string "MT_GetEq0Str"
MT_NoteHilightDisp_Name:	aligned_string "MT_NoteHilightDisp"
MT_NoteBarDisp2_Name:		aligned_string "MT_NoteBarDisp2"
MT_NoteBarDisp_Name:		aligned_string "MT_NoteBarDisp"
MT_GetMeasCngSv_Name:		aligned_string "MT_GetMeasCngSv"
MT_GetMeasTopNumSv_Name:	aligned_string "MT_GetMeasTopNumSv"
MT_GetInputLenString_Name:	aligned_string "MT_GetInputLenString"
MT_GetLenString_Name:		aligned_string "MT_GetLenString"
MT_GetInputVelString_Name:	aligned_string "MT_GetInputVelString"
MT_GetVelString_Name:		aligned_string "MT_GetVelString"
MT_GetNoteString_Name:		aligned_string "MT_GetNoteString"
MT_GetIncString_Name:		aligned_string "MT_GetIncString"
MT_GetPosString_Name:		aligned_string "MT_GetPosString"
MT_GetHakuString_Name:		aligned_string "MT_GetHakuString"
MT_GetLinePos_Name:		aligned_string "MT_GetLinePos"
MT_GetTriPos_Name:		aligned_string "MT_GetTriPos"
MT_GetEndPos_Name:		aligned_string "MT_GetEndPos"
MT_GetPCntInString_Name:	aligned_string "MT_GetPCntInString"
MT_GetPOutMeasString_Name:	aligned_string "MT_GetPOutMeasString"
MT_GetPInMeasString_Name:	aligned_string "MT_GetPInMeasString"
MT_GetPMeasString_Name:		aligned_string "MT_GetPMeasString"
MT_GetAccLvlStr_Name:		aligned_string "MT_GetAccLvlStr"
MT_GetSclrPerString_Name:	aligned_string "MT_GetSclrPerString"
MT_GetSclrKbString_Name:	aligned_string "MT_GetSclrKbString"
MT_GetSclrNameString_Name:	aligned_string "MT_GetSclrNameString"
MT_GetSclrNoString_Name:	aligned_string "MT_GetSclrNoString"
MT_GetSoloEnString_Name:	aligned_string "MT_GetSoloEnString"
MT_SetPunch_Name:		aligned_string "MT_SetPunch"
MT_SetMetro_Name:		aligned_string "MT_SetMetro"
MT_SetCycle_Name:		aligned_string "MT_SetCycle"
MT_GetCycEndMString_Name:	aligned_string "MT_GetCycEndMString"
MT_GetCycSrtMString_Name:	aligned_string "MT_GetCycSrtMString"
MT_GetCycEnString_Name:		aligned_string "MT_GetCycEnString"
MT_GetMemString_Name:		aligned_string "MT_GetMemString"
MT_GetBeatString_Name:		aligned_string "MT_GetBeatString"
MT_GetMeasString_Name:		aligned_string "MT_GetMeasString"
MT_SetToCur_Name:		aligned_string "MT_SetToCur"
MT_GetToCur_Name:		aligned_string "MT_GetToCur"
MT_SetFromCur_Name:		aligned_string "MT_SetFromCur"
MT_GetFromCur_Name:		aligned_string "MT_GetFromCur"
MT_ChkCur2_Name:		aligned_string "MT_ChkCur2"
MT_ChkCur_Name:			aligned_string "MT_ChkCur"
MT_CurToParam_Name:		aligned_string "MT_CurToParam"
MT_GetCurPos_Name:		aligned_string "MT_GetCurPos"
MT_SetCurPos_Name:		aligned_string "MT_SetCurPos"
MT_GetScpTtrString_Name:	aligned_string "MT_GetScpTtrString"
MT_GetScpTsngString_Name:	aligned_string "MT_GetScpTsngString"
MT_GetScpFtrString_Name:	aligned_string "MT_GetScpFtrString"
MT_GetScpFsngString_Name:	aligned_string "MT_GetScpFsngString"
MT_GetMinsRepString_Name:	aligned_string "MT_GetMinsRepString"
MT_GetMinsSMString_Name:	aligned_string "MT_GetMinsSMString"
MT_GetMinsTrBString_Name:	aligned_string "MT_GetMinsTrBString"
MT_GetMinsLMString_Name:	aligned_string "MT_GetMinsLMString"
MT_GetMinsFMString_Name:	aligned_string "MT_GetMinsFMString"
MT_GetMinsTrAString_Name:	aligned_string "MT_GetMinsTrAString"
MT_GetMcpRepString_Name:	aligned_string "MT_GetMcpRepString"
MT_GetMcpSMString_Name:		aligned_string "MT_GetMcpSMString"
MT_GetMcpTrBString_Name:	aligned_string "MT_GetMcpTrBString"
MT_GetMcpLMString_Name:		aligned_string "MT_GetMcpLMString"
MT_GetMcpFMString_Name:		aligned_string "MT_GetMcpFMString"
MT_GetMcpTrAString_Name:	aligned_string "MT_GetMcpTrAString"
MT_GetMrgTrCString_Name:	aligned_string "MT_GetMrgTrCString"
MT_GetMrgTrBString_Name:	aligned_string "MT_GetMrgTrBString"
MT_GetMrgTrAString_Name:	aligned_string "MT_GetMrgTrAString"
MT_GetCnString_Name:		aligned_string "MT_GetCnString"
MT_GetTnString_Name:		aligned_string "MT_GetTnString"
MT_GetQtzWinString_Name:	aligned_string "MT_GetQtzWinString"
MT_GetQtzStrString_Name:	aligned_string "MT_GetQtzStrString"
MT_GetQtzValString_Name:	aligned_string "MT_GetQtzValString"
MT_GetMersString_Name:		aligned_string "MT_GetMersString"
MT_GetVeloString_Name:		aligned_string "MT_GetVeloString"
MT_GetTrnsString_Name:		aligned_string "MT_GetTrnsString"
MT_GetAdlyString_Name:		aligned_string "MT_GetAdlyString"
MT_GetLMString_Name:		aligned_string "MT_GetLMString"
MT_GetFMString_Name:		aligned_string "MT_GetFMString"
MT_GetTrkString_Name:		aligned_string "MT_GetTrkString"
MT_DecVal_Name:			aligned_string "MT_DecVal"
MT_IncVal_Name:			aligned_string "MT_IncVal"
MT_GetDispPos_Name:		aligned_string "MT_GetDispPos"
MT_CngEffPara_Name:		aligned_string "MT_CngEffPara"
MT_CngEffType_Name:		aligned_string "MT_CngEffType"
MT_GetParaSize_Name:		aligned_string "MT_GetParaSize"
MT_RetEffPara_Name:		aligned_string "MT_RetEffPara"
MT_RetEffFix_Name:		aligned_string "MT_RetEffFix"
MT_GetItemTop_Name:		aligned_string "MT_GetItemTop"
MT_SetItemTop_Name:		aligned_string "MT_SetItemTop"
MT_GetItemOff_Name:		aligned_string "MT_GetItemOff"
MT_SetItemOff_Name:		aligned_string "MT_SetItemOff"
MT_GetItemExist_Name:		aligned_string "MT_GetItemExist"
MT_GetEffDlt7Str_Name:		aligned_string "MT_GetEffDlt7Str"
MT_GetEffDlt6Str_Name:		aligned_string "MT_GetEffDlt6Str"
MT_GetEffDlt5Str_Name:		aligned_string "MT_GetEffDlt5Str"
MT_GetEffDlt4Str_Name:		aligned_string "MT_GetEffDlt4Str"
MT_GetEffDlt3Str_Name:		aligned_string "MT_GetEffDlt3Str"
MT_GetEffDlt2Str_Name:		aligned_string "MT_GetEffDlt2Str"
MT_GetEffDlt1Str_Name:		aligned_string "MT_GetEffDlt1Str"
MT_GetEffDlt0Str_Name:

	aligned_string "MT_GetEffDlt0Str"

MT_GetEffFixString_Name:	aligned_string "MT_GetEffFixString"

EffectsEditor_GapByte:
	.byte 0x77, 0x00
.include "ui_widgets/effects_sequencer_screens.s"
	.include "ui_widgets/widget_descriptors.s"
	jr	gt, 0x00
	aligned_string "AcPmemOutLGridBox"
	.byte 0x58, 0x58, 0x6a, 0x00
	aligned_string "AcPcgOutGridBox"
	.byte 0x58, 0x58, 0x6a, 0x00
	aligned_string "AcParaLoadOptGridBox"
	.byte 0x58, 0x58, 0x6a, 0x00
	aligned_string "AcInOutGridBox"
	.byte 0x58, 0x58
	jr	gt, 0x00
	aligned_string "AcVocalGridBox"
	.byte 0x58, 0x58, 0x6a, 0x00
	aligned_string "AcFadeSetGridBox"
	aligned_string "nXXFB"
	aligned_string "AcLswFuncBox"
	aligned_string "nXXFB"
	aligned_string "AcLswFuncEditBox"
	.byte 0x00, 0xff
	aligned_string "AcGMOnOffBox"
	aligned_string "fjXn"
	aligned_string "AcSendEditSw"
	.byte 0x41, 0x74, 0x74, 0x00
	aligned_string "IvMpstPageControl"
	.byte 0x00, 0xff
	aligned_string "AcVocalistListBox"
	.byte 0x00, 0xff
	aligned_string "PsHarmOnOffBox"
	.byte 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0xa0, 0x5d, 0xe5, 0x00


MidiMenu_MsgType_Table:
	.long MsgType_ExcSend
	.long MsgType_DrawKey
	.long MsgType_MpstLoad
	.long MsgType_MpstWrite
	.long MsgType_FlashWrite
	.long MsgType_FlashLoad
	.long MsgType_VstPstOk
	.long MsgType_VstSendOk
	.long MsgType_RevLoad
	.long MsgType_EqLoad
	.long MsgType_RevEqLoad
	.byte 0x00, 0x00, 0x00, 0x00
MsgType_RevEqLoad:	aligned_string "MT_REVEQLOAD"
MsgType_EqLoad:		aligned_string "MT_EQLOAD"
MsgType_RevLoad:	aligned_string "MT_REVLOAD"
MsgType_VstSendOk:	aligned_string "MT_VST_SEND_OK"
MsgType_VstPstOk:	aligned_string "MT_VST_PST_OK"
MsgType_FlashLoad:	aligned_string "MT_FLASHLOAD"
MsgType_FlashWrite:	aligned_string "MT_FLASHWRITE"
MsgType_MpstWrite:	aligned_string "MT_MPSTWRITE"
MsgType_MpstLoad:	aligned_string "MT_MPSTLOAD"
MsgType_DrawKey:	aligned_string "MT_DRAWKEY"
MsgType_ExcSend:	aligned_string "MT_EXCSEND"
	aligned_string "MT_PCGSEND"
	.byte 0x0c, 0x00, 0xb5, 0x3f, 0xf7, 0x00, 0x19
	.byte 0x40, 0xf7, 0x00, 0x36, 0x62, 0xf7, 0x00, 0xf5
	.byte 0x7d, 0xf7, 0x00, 0x10, 0x47, 0xf7, 0x00, 0x8c
	.byte 0x4d, 0xf7, 0x00, 0xdf, 0x4f, 0xf7, 0x00, 0x29
	.byte 0x52, 0xf7, 0x00, 0x42, 0x36, 0xf7, 0x00, 0x5a
	.byte 0x57, 0xf7, 0x00, 0x5e, 0x6c, 0xf7, 0x00, 0xda
	.byte 0x73, 0xf7, 0x00, 0x29, 0x83, 0xf7, 0x00, 0x7c
	.byte 0x86, 0xf7, 0x00, 0xdc, 0x9a, 0xf7, 0x00, 0xf4
	.byte 0xa1, 0xf7, 0x00, 0x00, 0x00, 0x00, 0x00
MidiMenu_NakaProcName_Table:
	.long NakaInst_AcVocalistListBoxProc
	.long NakaInst_PsHarmOnOffBoxProc
	.long NakaInst_IvMpstPageControlProc
	.long NakaInst_AcSendEditSwProc
	.long NakaInst_AcGMOnOffBoxProc
	.long NakaInst_AcLswFuncBoxProc
	.long NakaInst_AcLswFuncEditBoxProc
	.long NakaInst_AcFadeSetGridBoxProc
	.long NakaInst_AcVocalGridBoxProc
	.long NakaInst_AcInOutGridBoxProc
	.long NakaInst_AcParaLoadOptGridBoxProc
	.long NakaInst_AcPcgOutGridBoxProc
	.long NakaInst_AcPmemOutLGridBoxProc
	.long NakaInst_AcPmemOutRGridBoxProc
	.long NakaInst_AcCtlMsgGridBoxProc
	.long NakaInst_AcMidiPartGridBoxProc
	.long NakaProc_NullEntry
NakaProc_NullEntry:
	.byte 0x00, 0xff
.include "ui_widgets/midi_reverb_presets_screens.s"
.include "ui_widgets/naka_widget_tables_2.s"
.include "ui_widgets/sound_menu_drawbar_screens.s"
	.short 0xFFFF, 0x2
	.short 0xFFFF, 0x8
	.short 0xF5	; X-left coord of the button
	.short 0x6	; y-top coord of the button
	.short 0x13B, 0x17	; x-right coord of the button
	.short 0xF3, 0xC1	; y-botton coord
	.short 0xFFFF
	.long 0x3E664	; <-- the LSByte here affects the page number
	.short 0x1
	.short 0x2	; total number of pages
NakaWidget_SoundMenu_ScrollBar1:

	naka_header NAKA_TYPE_0x28
	.byte 0x00, 0x00
	.byte 0xff, 0xff, 0x03, 0x00, 0x01, 0x00, 0x18, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x1f, 0x00, 0x1f, 0x00
	.byte 0x01, 0x00, 0x06, 0x00, 0x02, 0x00
NakaWidget_SoundMenu_ScrollBar2:


	naka_header NAKA_TYPE_0x28
	.byte 0x00, 0x00, 0xff, 0xff, 0x04, 0x00
	.byte 0x02, 0x00, 0x18, 0x00, 0x24, 0x00, 0x00, 0x00
	.byte 0x43, 0x00, 0x1f, 0x00, 0x02, 0x00, 0x11, 0x00
	.byte 0x02, 0x00
NakaWidget_SoundMenu_ListBox:


	naka_header NAKA_TYPE_0x48
	.byte 0x00, 0x00
	.byte 0xff, 0xff, 0x05, 0x00, 0x03, 0x00, 0x18, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x1f, 0x00, 0x1f, 0x00
	.byte 0x01, 0x00, 0x80, 0x01
NakaWidget_SoundMenu_ValueEdit:


	naka_header NAKA_TYPE_0x64
	.byte 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0x04, 0x00
	.byte 0x18, 0x00, 0x48, 0x00, 0x00, 0x00, 0x67, 0x00
	.byte 0x1f, 0x00, 0x00, 0x00, 0x21, 0x01
NakaWidget_SoundMenu_PageControl:


	naka_header NAKA_TYPE_0x35
	.byte 0xff, 0xff, 0x07, 0x00, 0xff, 0xff
	.byte 0xff, 0xff, 0x08, 0x00, 0x84, 0x00, 0x40, 0x00
	.byte 0xab, 0x00, 0x53, 0x00, 0xf7, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x66, 0xe6, 0x03, 0x00, 0x6a, 0xe6
	.byte 0x03, 0x00


NakaMenuItem_PartSetting:
	naka_header NAKA_TYPE_MENU_ITEM
	.byte 0x06, 0x00
	.short 0xFFFF, 0x8
	.short 0xFFFF, 0x8
	.short 0x8, 0x1E
	.short 0x9C, 0x37
	.short 0xF7, 0x0
	.short 0xFFFF, 0x0
	.short 0x0, 0xFF
	.short 0x0, 0x88
	.long 0x3E66E
	.long MenuStr_PartSetting
	.short 0x3, 0x1A0
	.long 0x2

MenuStr_PartSetting:	aligned_string "PART SETTING"

; header: type=1D
;MenuItem     STRUCT
;header   db 6 dup (?)
;unk06		dw ?
;unk08		dw ?
;unk0a		dw ?
;unk0c		dw ?
;x		dw ?	; 0eh
;icon_y		dw ?	; 10h
;unk12		dw ?
;y		dw ?	; 14h
;bg_color	dw ?	; 16h
;unk18		dw ?
;unk1a		dw ?
;unk1c		dw ?
;unk1e		dw ?
;unk20		dw ?
;unk22		dw ?
;flags		dw ?	; 24h
;ptr26		dd ?
;text_string	dd ?	; 2ah
;unk2e		dw ?
;unk30		dw ?
;icon_id		dd ?	; 32h
;MenuItem     ENDSTRUCT


NakaMenuItem_Mixer:
	.byte 0x1d, 0x00
	.byte 0x60, 0x01, 0x06, 0x00
	.short 0xFFFF, 0x9
	.short 0x7, 0x8
	.short 0x8	; X coord of menu item
	.short 0x48	; <== affects Y coord of the menu item's icon
			;     and the text seems to disappear
	.short 0x9C
	.short 0x61	; Y coord of menu item
	.short 0xF7	; bg color of menu item (00F7 means transparent)
	.short 0x0
	.short 0xFFFF, 0x0
	.short 0x0, 0xFF
	.short 0x0
	.short 0x89	; <= affects positioning of label and icon
			;    with mirror and offset on the x axis

	.long 0x3E670
	.long MenuStr_Mixer
	.short 0x8, 0x1A0
	.long 0x7	; <== Select Icon (0 = no-icon, 1=worm, 2=... etc)

MenuStr_Mixer:	aligned_string "MIXER"


NakaMenuItem_MasterTuning:
	naka_header NAKA_TYPE_MENU_ITEM
	.byte 0x06, 0x00
	.byte 0xff, 0xff, 0x0a, 0x00, 0x08, 0x00, 0x08, 0x00
	.byte 0x08, 0x00, 0x9c, 0x00, 0x9c, 0x00, 0xb5, 0x00
	.byte 0xf7, 0x00, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00
	.byte 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0x8b, 0x00
	.byte 0x72, 0xe6, 0x03, 0x00, 0x50, 0x1a, 0xe8, 0x00
	.byte 0x04, 0x00, 0xa0, 0x01, 0x09, 0x00, 0x00, 0x00
	aligned_string "MASTER TUNING"
NakaMenuItem_KeyScaling:

	naka_header NAKA_TYPE_MENU_ITEM
	.byte 0x06, 0x00
	.byte 0xff, 0xff, 0x0b, 0x00
	.byte 0x09, 0x00, 0x08, 0x00
	.byte 0x08, 0x00, 0xc6, 0x00
	.byte 0x9c, 0x00, 0xdf, 0x00
	.byte 0xf7, 0x00, 0x00, 0x00
	.byte 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0xff, 0x00
	.byte 0x00, 0x00, 0x8c, 0x00
	.long 0x3E674
	.long MenuStr_KeyScaling
	.byte 0x05, 0x00, 0xa0, 0x01
	.byte 0x84, 0x00, 0x00, 0x00
MenuStr_KeyScaling:	aligned_string "KEY SCALING"
NakaMenuItem_ReverbEqPresets:

	naka_header NAKA_TYPE_MENU_ITEM
	.byte 0x06, 0x00
	.byte 0xff, 0xff, 0x0c, 0x00
	.byte 0x0a, 0x00, 0x08, 0x00
	.byte 0xa3, 0x00, 0x1e, 0x00
	.byte 0x37, 0x01, 0x37, 0x00
	.byte 0xf7, 0x00, 0x00, 0x00
	.byte 0xff, 0xff, 0x00, 0x00, 0x00, 0x00
	.byte 0xff, 0x00, 0x00, 0x00, 0x08, 0x00
	.long 0x3E676
	.long MenuStr_ReverbEqPresets
	.byte 0x09, 0x00
	.byte 0xa0, 0x01, 0x91, 0x00, 0x00, 0x00

MenuStr_ReverbEqPresets:	aligned_string "REVERB & EQ PRESETS"
NakaMenuItem_Reverb:

	naka_header NAKA_TYPE_MENU_ITEM
	.byte 0x06, 0x00
	.byte 0xff, 0xff, 0x0d, 0x00, 0x0b, 0x00, 0x08, 0x00
	.byte 0xa3, 0x00, 0x48, 0x00, 0x37, 0x01, 0x61, 0x00
	.byte 0xf7, 0x00, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00
	.byte 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0x09, 0x00
	.byte 0x78, 0xe6, 0x03, 0x00, 0x20, 0x1b, 0xe8, 0x00
	.byte 0x0a, 0x00, 0xa0, 0x01, 0x17, 0x00, 0x00, 0x00
	aligned_string "REVERB"
NakaMenuItem_Equalizer:

	naka_header NAKA_TYPE_MENU_ITEM
	.byte 0x06, 0x00, 0xff, 0xff
	.byte 0x0e, 0x00, 0x0c, 0x00, 0x08, 0x00, 0xa3, 0x00
	.byte 0x72, 0x00, 0x37, 0x01, 0x8b, 0x00, 0xf7, 0x00
	.byte 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00
	.byte 0xff, 0x00, 0x00, 0x00, 0x0a, 0x00, 0x7a, 0xe6
	.byte 0x03, 0x00, 0x5e, 0x1b, 0xe8, 0x00, 0x0c, 0x00
	.byte 0xa0, 0x01, 0x0d, 0x00, 0x00, 0x00
	aligned_string "EQUALIZER"
NakaMenuItem_DspEffect:

	naka_header NAKA_TYPE_MENU_ITEM
	.byte 0x06, 0x00, 0xff, 0xff
	.byte 0x0f, 0x00, 0x0d, 0x00, 0x08, 0x00, 0xa3, 0x00
	.byte 0x9c, 0x00, 0x37, 0x01, 0xb5, 0x00, 0xf7, 0x00
	.byte 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00
	.byte 0xff, 0x00, 0x00, 0x00, 0x0b, 0x00, 0x7c, 0xe6
	.byte 0x03, 0x00, 0x9e, 0x1b, 0xe8, 0x00, 0x0b, 0x00
	.byte 0xa0, 0x01, 0x0c, 0x00, 0x00, 0x00
	aligned_string "DSP EFFECT"
NakaMenuItem_AcousticIllusion:

	naka_header NAKA_TYPE_MENU_ITEM
	.byte 0x06, 0x00
	.byte 0xff, 0xff, 0x10, 0x00, 0x0e, 0x00, 0x08, 0x00
	.byte 0xa3, 0x00, 0xc6, 0x00, 0x37, 0x01, 0xdf, 0x00
	.byte 0xf7, 0x00, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00
	.byte 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0x0c, 0x00
	.long 0x3E67E
	.long MenuStr_AcousticIllusion
	.byte 0x0e, 0x00, 0xa0, 0x01, 0x92, 0x00, 0x00, 0x00

MenuStr_AcousticIllusion:	aligned_string "ACOUSTIC ILLUSION"
NakaWidget_SoundEdit:

	.byte 0x20, 0x00, 0x61, 0x01, 0x06, 0x00
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0x0f, 0x00
	.byte 0x08, 0x00
	.byte 0x08, 0x00
	.byte 0x72, 0x00
	.byte 0x9c, 0x00
	.byte 0x8b, 0x00
	.byte 0xf7, 0x00
	.byte 0x00, 0x00
	.byte 0xff, 0xff
	.zero 4
	.byte 0xff, 0x00
	.byte 0x00, 0x00
	.byte 0x8a, 0x00
	.long 0x3E680
	.long MenuStr_SoundEdit
	.byte 0x03, 0x00, 0x80, 0x01, 0x0f, 0x00, 0x00, 0x00

MenuStr_SoundEdit:	aligned_string "SOUND EDIT"
NakaWidget_SoundMenu_PageControl2:

	naka_header NAKA_TYPE_0x35
	.byte 0xff, 0xff, 0x12, 0x00, 0xff, 0xff, 0xff, 0xff
	.byte 0x08, 0x00, 0x38, 0x00, 0x78, 0x00, 0x5b, 0x00
	.byte 0x87, 0x00, 0xf7, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x82, 0xe6, 0x03, 0x00, 0x86, 0xe6, 0x03, 0x00
NakaMenuItem_LeftHold:

	naka_header NAKA_TYPE_MENU_ITEM
	.byte 0x11, 0x00, 0xff, 0xff
	.byte 0x13, 0x00, 0xff, 0xff, 0x08, 0x00, 0x08, 0x00
	.byte 0x72, 0x00, 0x9c, 0x00, 0x8b, 0x00, 0xf7, 0x00
	.byte 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00
	.byte 0xff, 0x00, 0x00, 0x00, 0x8a, 0x00, 0x8a, 0xe6
	.byte 0x03, 0x00, 0x8e, 0x1c, 0xe8, 0x00, 0x07, 0x00
	.byte 0xa0, 0x01, 0x16, 0x00, 0x00, 0x00
	aligned_string "LEFT HOLD"
NakaMenuItem_TechniChord:

	naka_header NAKA_TYPE_MENU_ITEM
	.byte 0x11, 0x00
	.byte 0xff, 0xff, 0xff, 0xff, 0x12, 0x00, 0x08, 0x00
	.byte 0xa3, 0x00, 0x72, 0x00, 0x37, 0x01, 0x8b, 0x00
	.byte 0xf7, 0x00, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00
	.byte 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0x0a, 0x00
	.long 0x3E68C
	.long NakaInst_TECHNI_CHORD
	.byte 0x0d, 0x00
	.byte 0xa0, 0x01, 0x18, 0x00, 0x00, 0x00
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
	.ascii " \"!#\"$#%$&%'&(')(*)+*,+-,.-/.0/102132435465768798:9;:<;=<>=?>@?A@BACBDCEDFEGFHGIHJIKJLKMLNMONPOQPRQSRTSUTVUWVXWYXZY[Z\\[]\\^]_^`_a`bacbdce"
CharEncoding_PrintableHi:	.ascii "dfegfhgihjikjlkmlnmonpoqprqsrtsutvuwvxwyxzy{z|{}|~}"
	.byte 0x7f, 0x7e, 0x80, 0x7f, 0x00
	.byte 0x81, 0x81, 0x82, 0x82, 0x83, 0x83, 0x84, 0x84
	.byte 0x85, 0x85, 0x86, 0x86, 0x87, 0x87
CharEncoding_ExtendedLo:
	.byte 0x88, 0x88
	.byte 0x89, 0x89, 0x8a, 0x8a, 0x8b, 0x8b, 0x8c, 0x8c
	.byte 0x8d, 0x8d, 0x8e, 0x8e, 0x8f, 0x8f, 0x90, 0x90
	.byte 0x91, 0x91, 0x92, 0x92, 0x93, 0x93, 0x94, 0x94
	.byte 0x95, 0x95, 0x96, 0x96, 0x97, 0x97, 0x98, 0x98
	.byte 0x99
CharEncoding_ExtendedHi:
	.byte 0x99, 0x9a, 0x9a, 0x9b, 0x9b, 0x9c, 0x9c
	.byte 0x9d, 0x9d, 0x9e, 0x9e, 0x9f, 0x9f, 0xa0, 0xa0
	.byte 0x20, 0x01, 0x00, 0x02, 0x01, 0x03, 0x02, 0x04
	.byte 0x03, 0x05, 0x04, 0x06, 0x05, 0x07, 0x06, 0x08
	.byte 0x07, 0x09, 0x08, 0x0a, 0x09, 0x0b, 0x0a, 0x0c
	.byte 0x0b, 0x0d, 0x0c, 0x0e, 0x0d, 0x0f, 0x0e, 0x10
	.byte 0x0f, 0x11, 0x10, 0x12, 0x11, 0x13, 0x12, 0x14
	.byte 0x13, 0x15, 0x14, 0x16, 0x15, 0x17, 0x16, 0x18
	.byte 0x17, 0x19, 0x18, 0x1a, 0x19, 0x1b, 0x1a, 0x1c
	.byte 0x1b, 0x1d, 0x1c, 0x1e, 0x1d, 0x1f, 0x1e, 0x20
	.byte 0x1f, 0x00
	.asciz "!!\"\"##$$"
	.byte 0x00, 0x0a, 0xff, 0x14, 0xff
	.byte 0x00, 0xff, 0x00, 0xff, 0x00, 0x00, 0x00, 0x00
	.zero 12
NakaState_ZeroBlock_0:
	.zero 23
NakaState_ZeroBlock_1:
	.zero 2
NakaState_ZeroBlock_2:
	.zero 34
NakaState_ZeroBlock_3:
	.zero 20
NakaInst_BASS_ACCOMP1_ACCOMP2_ACCOMP3:
	.zero 5
NakaInst_RHYTHM_SELECT_TEMPO_APC_MEMORY_SPLIT_POINT:
	.zero 11
NakaState_ZeroBlock_4:
	.zero 2
NakaState_ZeroBlock_5:
	.zero 2
Naka_PresentationRootState:
	.zero 371
NakaState_PresentationTail:
	.zero 94
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00
	.byte 0x00


CharMap_ModeDispatchTable:
	.long CharMap_DefaultIdentity
	.long CharMap_DefaultIdentity
	.long CharMap_DefaultIdentity
	.long CharMap_DefaultIdentity
	.long CharMap_DefaultIdentity
	.long CharMap_DefaultIdentity
	.long CharMap_Mode6Forward
	.long CharMap_Mode7
	.long CharMap_Mode1Forward
	.long CharMap_Mode6Reverse
	.long CharMap_Mode17
	.long CharMap_FullPermutation
	.long CharMap_Mode1Forward
	.long CharMap_Mode6Reverse
	.long CharMap_Mode1Forward
	.long CharMap_Mode6Reverse
	.long CharMap_Mode12
	.long CharMap_Mode18
	.long CharMap_Mode2Forward
	.long CharMap_Mode2Reverse
	.long CharMap_Mode2Forward
	.long CharMap_Mode2Reverse
	.long CharMap_Mode13
	.long CharMap_Mode19
	.long CharMap_Mode3Forward
	.long CharMap_Mode3Reverse
	.long CharMap_Mode3Forward
	.long CharMap_Mode3Reverse
	.long CharMap_Mode14
	.long CharMap_Mode20
	.long CharMap_Mode5Forward
	.long CharMap_Mode5Reverse
	.long CharMap_Mode9
	.long CharMap_Mode11
	.long CharMap_Mode16
	.long CharMap_Mode22
	.long CharMap_Mode4Forward
	.long CharMap_Mode4Reverse
	.long CharMap_Mode8
	.long CharMap_Mode10
	.long CharMap_Mode15
	.long CharMap_Mode21

Boot_HaltInstruction:
	halt

Boot_PostHaltData:
	.byte 0x0e, 0x68, 0x01, 0x0e


; --- RESET Handler & Boot Sequence ---
RESET_HANDLER:
	; Hardware initialization code shared with table_data ROM
	.include "shared/boot_hw_init.s"
	; End of shared boot code (315 bytes)
	ldio 0xD2, 0x29
	ldio 0xD1, 0x00
	and_sd8b_im 0xD3, 0xCF
	and_sd8b_im 0xD3, 0xF0

Boot_InitIOPorts:
	stdi8 304, 255
	stdi8 305, 255
	stdi8 306, 3
	ldio 0x3A, 0x20
	ld xsp, 0xC00
	calr Boot_InitWorkRAM

Boot_RunSelfTest:
	call MainCPU_self_test_routines
	call Get_Firmware_Version
	cp l, 0xFF
	jr nz, Boot_PostSelfTest

We_seem_to_be_running_boot_ROM_code:
	call VGA_Setup
	pushw 0x8
	pushw 0x3
	ld xwa, 0xE00B2E	; "Please Wait !!"
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
	lda_dd8l XBC, 0xE4
	ld a, (xbc)
	and a, 0x8F
	or a, 0x30
	ld (xbc), a
	lda_dd8l XBC, 0xE6
	ld a, (xbc)
	and a, 0xF8
	or a, 0x3
	ld (xbc), a
	calr Detect_Region_Code
	cpdi16_24 65482, 23205
	jr z, Boot_FlashAndExtensions
	lda_24 xde, 0x00066e
	srl xde, 1
	ld xwa, 0xF980
	ld xbc, 0x1E8000
	call Copy_DE_words_from_XBC_to_XWA

Boot_FlashAndExtensions:
	call Flash_InitAllBanks
	bit_dd8 0, 0x38	;  Is the optional HD-AE5000 board present?
	jr nz, BootInit_SeqAndPanel
	calr Get_Region_Code
	cps l, 4
	call_24 nz, 0xEF4BCC	; if it is present (and this unit was sold in
					; a specific market region), then call the
					; HDAE5000 PPI init code

; Boot initialization handler (SeqInit + CPanel scan)
BootInit_SeqAndPanel:
	call Seq_FullInit
	ei 0
	ld32_24 xhl, 0xfc3e65
	call (xhl)
	call CPanel_ScanButtons
	stda8 1026, l
	call Get_Firmware_Version
	cp l, 0xFF
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
	ldio 0xF0, 0x00
	ldio 0xE0, 0x00
	ldio 0xE1, 0x00
	ldio 0xE2, 0x00
	ldio 0xE3, 0x00
	ldio 0xE4, 0x00
	ldio 0xE5, 0x00
	ldio 0xE6, 0x00
	ldio 0xE7, 0x00
	ldio 0xE8, 0x00
	ldio 0xE9, 0x00
	ldio 0xEA, 0x00
	ldio 0xEB, 0x00
	ldio 0xEC, 0x00
	ldio 0xED, 0x00
	ldio 0xEE, 0x00
	ldio 0xEF, 0x00
	ret

; ===========================================================================
; SubCPU_Send_Payload - Transfer 192KB Sub-CPU payload from Table Data ROM
; ===========================================================================
; Entry: None (reads from 0xFFFEEF to check if transfer should proceed)
; Exit:  XIZ restored, payload transferred to Sub-CPU RAM
; Notes: Sends the Sub-CPU firmware payload in multiple 64KB chunks:
;        - 0x830000-0x870000 (5 x 64KB) → Sub-CPU 0x050000-0x090000
;        - Additional data from Table Data ROM → Sub-CPU 0x00F000-0x02F000
;        - Final 256 bytes → Sub-CPU 0x000400 (entry point area)
;        Uses E1 bulk transfer protocol via InterCPU_E1_Bulk_Transfer
;        Includes 0x2000 and 0x100000 iteration delay loops for timing
;        Called during boot sequence after SubCPU_Init_DMA_Channels
; ===========================================================================
SubCPU_Send_Payload:
	push xiz
	cpi8_24 0xfffeef, 0xff
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
	cpi8_24 0xfffeed, 0xff
	jr nz, SubCPU_Payload_TransferPart2
	ld xiz, 0x50000
	ld xwa, 0x3E0000
	ld xbc, 0x50000
	call SLIDE_Parse_Header
	cp hl, 0xFFFF
	jr nz, SubCPU_Payload_TransferPart2
	ld xiz, 0x800000

SubCPU_Payload_TransferPart2:
	ldmm_sriw 0xF9, 0x00, 0x01, 0x04, 0x04
	ld xwa, xiz
	add xwa, 0x100
	ld xbc, 0x10000
	ld xde, 0xF000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, xiz
	add xwa, 0x10100
	ld xbc, 0x10000
	ld xde, 0x1F000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, xiz
	add xwa, 0x20100
	ldw bc, 0xFF00
	ld xde, 0x2F000
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
	call Get_Firmware_Version	; Returns version byte in L (0x0A = v10)
	and l, 0xF
	extz hl
	lda_24 xbc, 0xe00000		; LED_patterns_indicating_firmware_version table
	ld_srib3 C, 0x07, 0xE4, 0xEC	; Read LED pattern from table
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
	ldw wa, 0xF0
	call SoundCtrl_SendCommand		; Display SOFT VERSION screen
	ret

Boot_ParseTableDataTimestamp:
	ld xwa, 0x9FFFC4
	push xwa
	call ParseInt16
	inc 4, xsp
	ret

Boot_GetSystemPointer:
	ldda16 xhl, 1028
	ret

Boot_ParseSubCPUTimestamp:
	ld xwa, 0x87FFF5
	push xwa
	call ParseInt16
	inc 4, xsp
	ret

; ===========================================================================
; Boot_HandleFactoryReset - Factory reset if combo 1 AND checksums invalid
; ===========================================================================
; Entry: A = combo code from CPanel_CheckSpecialCombos
; If combo code == 1 (Initial Setting) AND DRAM[0xFFCA] != 0x5AA5
; (payload checksums invalid, e.g. after Flash ROM replacement),
; zero-fills all work DRAM and SRAM, then restarts the boot sequence.
; Otherwise returns immediately (normal boot continues).
; ===========================================================================
Boot_HandleFactoryReset:
	cpdi16_24 65482, 23205	; DRAM[0xFFCA] == 0x5AA5 (valid checksums)?
	ret z			; Yes → checksums valid, skip reset
	cps a, 1		; Combo code == 1 (Initial Setting)?
	ret nz			; No → not requesting reset, return
	; --- Factory Reset: clear all DRAM and SRAM ---
	call ToneGen_FlashReadAndRestore
	ei 7
	calr Boot_ClearAllInterruptEnables	; Clear all interrupt enables
	ld xbc, 0x400

FactoryReset_ClearDRAM:
	lds32 xwa, 0
	st_dpil XWA, 0xE6
	cp xbc, 0x100000
	jr c, FactoryReset_ClearDRAM
	ld xbc, 0x1E0000

FactoryReset_ClearSRAM:
	lds32 xwa, 0
	st_dpil XWA, 0xE6
	cp xbc, 0x200000
	jr c, FactoryReset_ClearSRAM
	sti16_24 0x00ffca, 0x5aa5
	jp Boot_InitIOPorts
FactoryReset_TrailingByte:
	.byte 0x0e

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
	lda_24 xix, 0xe1ffd2
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf1ea4c
	jp_dri 8, 0x07, 0xF0, 0xE0
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
	ld xwa, 0x3D3000
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
	lda_24 xwa, 0xe1ffcc
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
	ld xiy, 0xE1FFE6
	lda xix, (xsp + 16)
	ldiw
	ldiw
	ld xiy, 0xE1FFEA
	lda xix, (xsp + 12)
	ldiw
	ldiw
	ld xiy, 0xE1FFEE
	lda xix, (xsp + 8)
	ldiw
	ldiw
	ld xiy, 0xE1FFF2
	lda xix, (xsp + 4)
	ldiw
	ldiw
	ld xiy, 0xE1FFF6
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
	call	16184125
	pop	xiz
	ret
	push	xiz
	call	16184142
	pop	xiz
	ret
	push	xiz
	call	16183473
	pop	xiz
	ret

Voice_InitBankTables:
	ld xiy, 0xF6F119
	ld xix, 0x1E8800
	ldw bc, 0x10
	ldirw
	ldb a, 0xC

Voice_InitBankTables_Loop:
	ld xiy, 0xF6F139
	ldw bc, 0x8
	ldirw
	dec 1, a
	jr nz, Voice_InitBankTables_Loop
	ld xiy, 0xF6F249
	ld xix, 0x1E8A00
	ldw bc, 0x20
	ldirw
	ld xiy, 0xF6F289
	ld xix, 0x1E8A40
	ldw bc, 0x20
	ldirw
	ld xiy, 0xF6F2C9
	ld xix, 0x1E8A80
	ldw bc, 0x20
	ldirw
	ld xix, 0x1E8B00
	ldb a, 0x39

Voice_InitBankTables_SlotLoop:
	ld xiy, 0xF6F149
	ldw bc, 0x80
	ldirw
	dec 1, a
	jr nz, Voice_InitBankTables_SlotLoop
	stdi16 32280, 57
	ret

Voice_BankHeaderDefaults:
	.byte 0x48, 0x00, 0x4b, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x5a, 0x5a, 0x5a, 0x00, 0x00
	.byte 0x20, 0x00, 0x10, 0x00, 0x1e, 0x00, 0x00, 0x01
	.byte 0x39, 0x00, 0x0c, 0x00, 0xc0, 0x03, 0xc0, 0x03

Voice_BankSlotZeroInit:
	.zero 16

Voice_SlotTemplate:
	.byte 0x00
	.long 0xFFFFFFFF
	.byte 0x87
	.zero 248
	.byte 0x00, 0x87

BLOCK_OF_64_ZEROES:
	.zero 64

HEADER__COMPILE_BANKS:
	.ascii " Compile Bank 1  Compile Bank 2                                 "

HEADER__USER_BANKS:
	.ascii "  User Bank 1     User Bank 2                                   "

Voice_InitBankData:
	calr Voice_InitBankTables
	ld xiy, 0xF6F42F
	ld xix, 0x1E8820
	ldw bc, 0xF0
	ldirw
	ld xix, 0x1E8A00
	ld xiy, 0xF6F249
	ldw bc, 0x60
	ldirw
	ld xix, 0x1E8B00
	ld xiy, 0xF6F62F
	ldw bc, 0xA80
	ldirw
	calr CountAvailableVoiceSlots
	ret

Voice_BankLookupCode:
	.byte 0x45, 0x00, 0x88, 0x1e, 0x00, 0xb5, 0x00, 0x48
	.byte 0xbd, 0x01, 0x00, 0x00, 0xbd, 0x02, 0x00, 0x4b
	.byte 0x0e

Voice_RefreshBankData:
	calr Voice_ComputeAllocSize
	ret

Voice_ResetToFactoryBanks:
	ldw wa, 0xA
	ld xhl, 0x7AEC
	ldw bc, 0xFF
	ldw de, 0xF6
	calr Voice_SetBankParams
	ld xhl, 0x7BEC
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
	ld xiy, 0x1E8800
	add xiy, 0xE
	ld wa, (xiy)
	cps wa, 0
	jr z, Voice_ReinitIfBankCount_Done
	calr Voice_InitBankData

Voice_ReinitIfBankCount_Done:
	ret

Voice_ReinitIfBitFlagSet:
	ld xiy, 0x1E8800
	add xiy, 0xA
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
	cp de, 0xFFFF
	jr z, CountVoiceSlots_Done
	jr CountVoiceSlots_Loop

CountVoiceSlots_Done:
	stda16 32280, xwa
	ret

Voice_GetSlotAddress:
	and xhl, 0xFFFF
	sla xhl, 8
	add xhl, 0x1E8B00
	ret

Voice_ComputeAllocSize:
	ld xhl, 0x3C00
	ld xiy, 0x1E8800
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
	add xwa, 0x3FF
	and xwa, 0xFFFFFC00
	srl xwa, 4
	ld xiy, 0x1E881C
	ld (xiy), wa
	calr CountAvailableVoiceSlots
	ret

Voice_FactoryPresetData:
	.byte 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x1a, 0x00, 0x7f, 0x40, 0x01, 0x00, 0x00
	.byte 0x11, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x16, 0x00, 0x7f, 0x40, 0x00, 0x00, 0x00
	.byte 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x63, 0x00, 0x7f, 0x40, 0x01, 0x00, 0x00
	.byte 0x11, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x52, 0x02, 0x7f, 0x40, 0x01, 0x00, 0x00
	.byte 0x11, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0xf0, 0x00, 0x7f, 0x40, 0x00, 0x00, 0x00
	.byte 0x11, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0xfc, 0x00, 0x7f, 0x40, 0x00, 0x00, 0x00
	.byte 0x01, 0x00, 0x00, 0x0f, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0xf0, 0x00, 0x7f, 0x40, 0x00, 0x00, 0x00
	.byte 0x01, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0xf0, 0x00, 0x7f, 0x40, 0x00, 0x00, 0x00
	.byte 0x01, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0xf0, 0x00, 0x7f, 0x40, 0x00, 0x00, 0x00
	.byte 0x01, 0x00, 0x00, 0x12, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0xf0, 0x00, 0x7f, 0x40, 0x00, 0x00, 0x00
	.byte 0x01, 0x00, 0x00, 0x13, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0xf0, 0x00, 0x7f, 0x40, 0x00, 0x00, 0x00
	.byte 0x01, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0xfc, 0x00, 0x7f, 0x40, 0x00, 0x00, 0x00
	.zero 288

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
	.byte 0xe8, 0x13, 0xeb, 0x80, 0xe8, 0x82, 0xb2, 0xcf
	.byte 0x66, 0x04, 0xb2, 0xb6, 0x68, 0x02, 0xb2, 0xbe
	.byte 0x8f, 0x18, 0x61, 0xaf, 0x0c, 0x20, 0xaf, 0x04
	.byte 0x88, 0xaf, 0x04, 0x20, 0xe8, 0xed, 0x00, 0xb1
	.byte 0x50, 0xaf, 0x10, 0x20, 0x99, 0x02, 0x88, 0xe8
	.byte 0xa9, 0xaf, 0x14, 0x88, 0xaf, 0x14, 0x20, 0xaf
	.byte 0x08, 0xf0, 0x72, 0x07, 0xff, 0x78, 0x4a, 0x01
	.byte 0xaf, 0x08, 0x20, 0xe8, 0xec, 0x00, 0xaf, 0x04
	.byte 0x21, 0x1d, 0x0e, 0x0c, 0xff, 0xeb, 0x8e, 0xaf
	.byte 0x10, 0x20, 0xee, 0x89, 0x1d, 0x5c, 0x0a, 0xff
	.byte 0xbf, 0x10, 0x63, 0xaf, 0x22, 0x21, 0xe9, 0x88
	.byte 0xe8, 0x62, 0xbf, 0x22, 0x60, 0x90, 0x20, 0xe8
	.byte 0x13, 0xbf, 0x08, 0x60, 0xe8, 0xec, 0x00, 0xbf
	.byte 0x08, 0x60, 0x40, 0x00, 0x80, 0x00, 0x00, 0xaf
	.byte 0x08, 0x88, 0xe8, 0xa8, 0xbf, 0x14, 0x60, 0xaf
	.byte 0x04, 0x20, 0xe8, 0xcf, 0x00, 0x00, 0x00, 0x00
	.byte 0x71, 0xff, 0x00, 0x8f, 0x18, 0x3f, 0x03, 0x63
	.byte 0x07, 0xbf, 0x18, 0x00, 0x00, 0x78, 0xce, 0x00
	.byte 0x8f, 0x18, 0x3f, 0x01, 0x7b, 0xc4, 0x00, 0xc2
	.byte 0xaa, 0xef, 0x03, 0x27, 0xaf, 0x22, 0x20, 0x90
	.byte 0x20, 0xe8, 0x13, 0xe8, 0x8a, 0xea, 0xee, 0x02
	.byte 0xe8, 0x82, 0xea, 0xee, 0x06, 0xcf, 0xda, 0x76
	.byte 0x92, 0x00, 0xcf, 0xd9, 0x66, 0x75, 0xcf, 0xd8
	.byte 0x7e, 0xa0, 0x00, 0xe9, 0x8b, 0x9f, 0x32, 0x25
	.byte 0x91, 0x20, 0xe8, 0x13, 0xea, 0x80, 0xf2, 0x00
	.byte 0x3c, 0x04, 0x34, 0xe8, 0x84, 0x9f, 0x32, 0x3f
	.byte 0xf5, 0x00, 0x66, 0x1e, 0x84, 0x3c, 0x60, 0xdd
	.byte 0x88, 0xd8, 0xcc, 0x9f, 0x00, 0x84, 0x89, 0xdd
	.byte 0x8a, 0xda, 0xcc, 0x80, 0x00, 0x84, 0x21, 0xc9
	.byte 0xcc, 0x80, 0xd8, 0x12, 0xda, 0xf0, 0x6e, 0x36
	.byte 0x68, 0x69, 0xe2, 0x52, 0x04, 0x03, 0x25, 0x93
	.byte 0x22, 0xea, 0x13, 0x9b, 0x02, 0x20, 0xe8, 0x13
	.byte 0xe8, 0x8b, 0xeb, 0xee, 0x02, 0xe8, 0x83, 0xeb
	.byte 0xee, 0x06, 0xea, 0x83, 0xeb, 0x85, 0x84, 0x3c
	.byte 0x60, 0x85, 0x21, 0xc9, 0xcc, 0x9f, 0x84, 0x89
	.byte 0x85, 0x25, 0xcd, 0xcc, 0x80, 0x84, 0x21, 0xc9
	.byte 0xcc, 0x80, 0xcd, 0xf1, 0x66, 0x35, 0x84, 0x3d
	.byte 0x60, 0x68, 0x30, 0x91, 0x20, 0xe8, 0x13, 0xea
	.byte 0x80, 0xf2, 0x00, 0x3c, 0x04, 0x32, 0xe8, 0x82
	.byte 0xb2, 0xcf, 0x66, 0x04, 0xb2, 0xb5, 0x68, 0x1b
	.byte 0xb2, 0xbd, 0x68, 0x17, 0x91, 0x20, 0xe8, 0x13
	.byte 0xea, 0x80, 0xf2, 0x00, 0x3c, 0x04, 0x32, 0xe8
	.byte 0x82, 0xb2, 0xcf, 0x66, 0x04, 0xb2, 0xb6, 0x68
	.byte 0x02, 0xb2, 0xbe, 0x8f, 0x18, 0x61, 0xaf, 0x10
	.byte 0x20, 0xaf, 0x08, 0x88, 0xaf, 0x08, 0x22, 0xea
	.byte 0xed, 0x00, 0xaf, 0x22, 0x20, 0xb0, 0x52, 0xaf
	.byte 0x0c, 0x20, 0x91, 0x88, 0xe8, 0xa9, 0xaf, 0x14
	.byte 0x88, 0xaf, 0x14, 0x20, 0xaf, 0x04, 0xf0, 0x72
	.byte 0x01, 0xff, 0xbf, 0x26, 0x30, 0xaf, 0x1e, 0x21
	.byte 0x91, 0x21, 0xb8, 0x02, 0x51, 0xaf, 0x38, 0x21
	.byte 0x91, 0x21, 0xb0, 0x51, 0xaf, 0x34, 0x21, 0x91
	.byte 0x21, 0xb8, 0x04, 0x51, 0xaf, 0x1a, 0x21, 0x91
	.byte 0x21, 0xb8, 0x06, 0x51, 0x1e, 0x53, 0x9a, 0x5e
	.byte 0xbf, 0x38, 0x37, 0x0e, 0xef, 0x6a, 0x3e, 0xbf
	.byte 0x04, 0x51, 0xe8, 0x8e, 0x1e, 0x13, 0x98, 0xdb
	.byte 0xd8, 0x66, 0x1d, 0xc2, 0xa8, 0xef, 0x03, 0x21
	.byte 0xf2, 0xaa, 0xef, 0x03, 0x41, 0xd2, 0x4e, 0x04
	.byte 0x03, 0x3f, 0x00, 0x00, 0x66, 0x33, 0xee, 0x88
	.byte 0x9f, 0x04, 0x21, 0x1e, 0x4e, 0x00, 0x68, 0x29
	.byte 0x30, 0x10, 0x00, 0x1e, 0xfe, 0x96, 0xeb, 0x88
	.byte 0xf2, 0x6d, 0x0d, 0xfb, 0x31, 0xb0, 0x61, 0xee
	.byte 0x8d, 0xb8, 0x04, 0x34, 0xd9, 0xac, 0x95, 0x11
	.byte 0x9f, 0x04, 0x21, 0xb8, 0x0c, 0x51, 0xc2, 0xa8
	.byte 0xef, 0x03, 0x23, 0xb8, 0x0e, 0x43, 0x1e, 0x03
	.byte 0x96, 0x5e, 0xef, 0x62, 0x0e, 0xe8, 0x89, 0xb9
	.byte 0x04, 0x30, 0x99, 0x0c, 0x22, 0x89, 0x0e, 0x23
	.byte 0xf2, 0xaa, 0xef, 0x03, 0x43, 0xd2, 0x4e, 0x04
	.byte 0x03, 0x3f, 0x00, 0x00, 0xb0, 0xf6, 0xda, 0x89
	.byte 0x1e, 0x01, 0x00, 0x0e, 0xbf, 0xee, 0x37, 0x2e
	.byte 0xbf, 0x0e, 0x51, 0xbf, 0x10, 0x60, 0xaf, 0x10
	.byte 0x20, 0xe8, 0x62, 0xbf, 0x02, 0x60, 0x90, 0x3f
	.byte 0x00, 0x00, 0x69, 0x07, 0xaf, 0x02, 0x20, 0xb0
	.byte 0x02, 0x00, 0x00, 0xaf, 0x10, 0x20, 0x90, 0x3f
	.byte 0x00, 0x00, 0x69, 0x04, 0xb0, 0x02, 0x00, 0x00
	.byte 0xaf, 0x10, 0x20, 0xb8, 0x04, 0x33, 0x93, 0x3f
	.byte 0x40, 0x01, 0x61, 0x04, 0xb3, 0x02, 0x3f, 0x01
	.byte 0xaf, 0x10, 0x20, 0xb8, 0x06, 0x34, 0x94, 0x3f
	.byte 0xf0, 0x00, 0x61, 0x04, 0xb4, 0x02, 0xef, 0x00
	.byte 0x94, 0x22, 0xaf, 0x02, 0x20, 0x90, 0x26, 0xbf
	.byte 0x0a, 0x30, 0xbf, 0x06, 0x31, 0xb9, 0x02, 0x35
	.byte 0xb8, 0x02, 0x56, 0xde, 0xf2, 0x6e, 0x14, 0xaf
	.byte 0x10, 0x22, 0x92, 0x22, 0xb0, 0x52, 0x93, 0x22
	.byte 0xb1, 0x52, 0x94, 0x22, 0xb5, 0x52, 0x9f, 0x0e
	.byte 0x22, 0x68, 0x6e, 0xaf, 0x10, 0x22, 0x92, 0x22
	.byte 0xb0, 0x52, 0x93, 0x22, 0xb1, 0x52, 0xaf, 0x02
	.byte 0x22, 0x92, 0x22, 0xb5, 0x52, 0x9f, 0x0e, 0x22
	.byte 0x1e, 0x3f, 0xf1, 0xbf, 0x0a, 0x30, 0xaf, 0x10
	.byte 0x21, 0xb9, 0x06, 0x32, 0x92, 0x21, 0xb8, 0x02
	.byte 0x51, 0xbf, 0x06, 0x31, 0x92, 0x22, 0xb9, 0x02
	.byte 0x52, 0x9f, 0x0e, 0x22, 0x1e, 0x23, 0xf1, 0xbf
	.byte 0x0a, 0x30, 0xaf, 0x10, 0x23, 0x9b, 0x02, 0x21
	.byte 0xb8, 0x02, 0x51, 0x93, 0x21, 0xb0, 0x51, 0xbf
	.byte 0x06, 0x31, 0x93, 0x22, 0xb1, 0x52, 0x9b, 0x06
	.byte 0x22, 0xb9, 0x02, 0x52, 0x9f, 0x0e, 0x22, 0x1e
	.byte 0x00, 0xf1, 0xbf, 0x0a, 0x30, 0xaf, 0x10, 0x21
	.byte 0xb9, 0x04, 0x32, 0x92, 0x21, 0xb0, 0x51, 0xbf
	.byte 0x06, 0x31, 0x92, 0x22, 0xb1, 0x52, 0x9f, 0x0e
	.byte 0x22, 0x1e, 0xe6, 0xf0, 0xaf, 0x10, 0x20, 0x1e
	.byte 0xe8, 0x98, 0x4e, 0xbf, 0x12, 0x37, 0x0e

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
	ldw wa, 0x1E
	calr DrawQueue_Alloc
	ld xiz, xhl
	lda_24 xwa, 0xfb0f31
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
	st_dri3b L, 0xFD, 0xC6, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x36, 0x01
	st_dri3l XWA, 0xFD, 0x3A, 0x01
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
	ldw (xwa), 0x13F

TextRender_ClampXRight:
	ld_sril XWA, (xsp + 0x013a)
	lda xde, (xwa + 6)
	cpw (xde), 0xF0
	jr lt, TextRender_SetupColorAndFont
	ldw (xde), 0xEF

TextRender_SetupColorAndFont:
	ld xiy, xbc
	st_dri3b D, 0xFD, 0x2A, 0x01
	ldiw
	ldiw
	ld_sril XIX, (xsp + 0x0146)
	or xix, xix
	jr nz, TextRender_ClampNullXStart
	dec_sriw 2, 0xFD, 0x2C, 0x01

TextRender_ClampNullXStart:
	st_dri3b C, 0xFD, 0x2A, 0x01
	cpw (xhl), 0x0
	jr ge, TextRender_ClampNullYStart
	ldw (xhl), 0x0

TextRender_ClampNullYStart:
	lda xbc, (xhl + 2)
	cpw (xbc), 0x0
	jr ge, TextRender_LoadFontData
	ldw (xbc), 0x0

TextRender_LoadFontData:
	ld xwa, 0x945C00
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
	st_dri3b H, 0xFD, 0x2E, 0x01
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
	ld_spib C, 0xE0
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
	add_sriw_mr WA, 0xFD, 0x32, 0x01
	st_dri3b W, 0xFD, 0x2E, 0x01
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
	cp bc, 0xF7
	call_24 nz, 0xFAF938
	lda xwa, (xsp + 38)
	ld (xsp + 30), xwa
	cp (xwa), 0x0
	jrl z, TextRender_Finalize

TextRender_CharEncodeAndDraw:
	ld xhl, (xsp + 30)
	ld c, (xhl)
	extz bc
	lda_24 xde, 0xeab1b4
	ld_srib3 C, 0x07, 0xE8, 0xE4
	ld (xhl), c
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 12)
	or xwa, xwa
	jr nz, TextRender_CustomFontCharDraw
	ld bc, (xbc + 2)
	ld a, (xhl)
	sub a, 0x20
	extz wa
	mrdw3 0x9F, 0x16, 0x40
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
	st_dri3b A, 0xFD, 0x26, 0x01
	st_dri3b W, 0xFD, 0x2A, 0x01
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
	and a, 0xF
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
	and wa, 0x9F
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
	st_dri3b D, 0xFD, 0x26, 0x01
	st_dri3b B, 0xFD, 0x2A, 0x01
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
	and a, 0xF
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
	st_dri3b D, 0xFD, 0x26, 0x01
	st_dri3b B, 0xFD, 0x2A, 0x01
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
	call Audio_SendCommand
	lda xsp, (xsp + 12)

ChordProc_SendRefreshEvent:
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1C0000F
	call SendEvent

UI_EventHandler_InitReturnZero:
	lds32 xhl, 0

UI_EventHandler_PopAndReturn:
	pop xiz
	st_dri3b L, 0xFD, 0x04, 0x01
	ret

ChordProc_TrailingData:
	.byte 0x43, 0x03, 0x00, 0x02, 0x01, 0x0e
AcChordBoxProc_Entry:

AcChordBoxProc:
	st_dri3b L, 0xFD, 0xFC, 0xFE
	push xiz
	ld xiz, xde
	st_dri3l XWA, 0xFD, 0x04, 0x01
	cp xbc, 0x1C20001
	jr z, AcChordBox_HandleChordUpdate
	cp xbc, 0x1C00001
	jr z, AcChordBox_HandleInitOrSelect
	cp xbc, 0x1C20000
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
	ld xbc, 0x1E2000D
	lds32 xde, 0
	call MainFuncCall
	jr AcChordBox_ReturnZero

AcChordBox_HandleChordUpdate:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	push xiz
	pushw 0xED
	pushw 0x1C92
	lda xwa, (xsp + 12)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 0
	jr nz, AcChordBox_ReturnZero
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1C0000F
	call SendEvent

AcChordBox_ReturnZero:
	lds32 xhl, 0

AcChordBox_PopAndReturn:
	pop xiz
	st_dri3b L, 0xFD, 0x04, 0x01
	ret

MainChordPre:
	push xiz
	cp xbc, 0x1E2000D
	jrl nz, MainChordPre_ReturnZero
	pushw 0x15
	call Malloc
	ld xiz, xhl
	ld (xiz), 0x0
	ldda8 a, 36160
	extz wa
	sla wa, 2
	lda_24 xbc, 0xecfee0
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	push xiz
	call Strcat
	ldda8 a, 36162
	extz wa
	sla wa, 2
	lda_24 xbc, 0xecff6a
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	push xiz
	call Strcat
	lda xsp, (xsp + 18)
	cpdi8 36164, 0
	jr z, MainChordPre_EmptyChordStr
	bitda 1, 52958
	jr z, MainChordPre_EmptyChordStr
	ld xwa, 0xED1C96
	jr MainChordPre_AppendChordSuffix

MainChordPre_EmptyChordStr:
	ld xwa, 0xED1C9A

MainChordPre_AppendChordSuffix:
	push xwa
	push xiz
	call Strcat
	ldda8 a, 36162
	extz wa
	sla wa, 2
	lda_24 xbc, 0x03f2f8
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	ldda8 a, 36160
	extz wa
	sla wa, 2
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	ldda8 a, 36164
	extz wa
	sla wa, 2
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	push xbc
	push xiz
	call Strcat
	lda xsp, (xsp + 16)
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C20001
	ld xde, xiz
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
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

EMPTY_ROUTINE__FC3E64:
	ret

CPanel_InitDispatchTable:
	.long CPanel_InitSequence
	.long EMPTY_ROUTINE__FC3EE4
	.long EMPTY_ROUTINE__FC3EE4
	.long EMPTY_ROUTINE__FC3E93

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


EMPTY_ROUTINE__FC3E93:
	ret


CPanel_RX_ProcessOrInit:
	ldda8 a, 36236
	and a, 0xC0
	jr z, CPanel_RX_SkipToProcess
				; if CP_Flags_A.76 != 0:
	ld xhl, 0x200AD
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


EMPTY_ROUTINE__FC3EE4:
	ret


	.include "ui/cpanel_routines.s"


.include "audio/tonegen_fileio_handlers.s"
	.include "audio/audio_control_engine.s"
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xcb, 0xc9, 0xfc
	.byte 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0x0d, 0xca, 0xfc
	.byte 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0x45, 0xca, 0xfc
	.byte 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 5, 1, 0xff

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
	and xhl, 0xFF
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 8
	and xhl, 0xFF
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 0
	and xhl, 0x1F
	add xhl, xwa
	ld xwa, xhl
	ld xbc, 0x7FF
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
	.byte 0x0e

Debug_PrintString:
	push xiz
	ld xix, xwa

Debug_PrintString_Loop:
	ld_spib A, 0xF0
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
	.byte 0xc9, 0xcf, 0x0a, 0x6f, 0x04, 0xc9, 0xc8, 0x30
	.byte 0x0e, 0xc9, 0xc8, 0x57, 0x0e

Debug_UartDelay:
	ldw iz, 0xFE00
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
	jp	15666168
	jp	15682388
	jp	15664399
	jp	15664070
	ret

Get_Firmware_Version:
	ld8_24 l, 0xffffe8
	ret

ROM_PaddingFF:
	.byte 0xff, 0xff, 0xff, 0x00, 0xff

System_TimestampPointers:
	.long 0x409
	.long 0x409
	.long 0x409
	.long 0x409
InterruptVectorTable:


; TMP94C241C Interrupt Vector Table:
	.long RESET_HANDLER

	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler

	.long NMI_HANDLER
	.long Watchdog_Reset_Handler
	.long INT0_HANDLER
	.long INT4_HANDLER
	.long INT5_HANDLER

	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler

	.long INTA_HANDLER

	.long Empty_Handler
	.long Empty_Handler

	.long INTT1_HANDLER
	.long INTT2_HANDLER
	.long INTT3_HANDLER
	.long INTTR4_HANDLER

	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler

	.long INTRX0_HANDLER
	.long INTTX0_HANDLER
	.long INTRX1_HANDLER
	.long INTTX1_HANDLER

	.long Empty_Handler

	.long INTTC0_HANDLER

	.long Empty_Handler

	.long INTTC2_HANDLER
	.long INTTC3_HANDLER

	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler

; RESERVED:
	.fill 52, 1, 0xff

FIRMWARE_VERSION:
	.byte 0x0a

; RESERVED:
	.fill 23, 1, 0xff

; Labels emitted as .set (exact addresses from ORG/name)
	.set LABEL_E00023, 0xE00023
	.set LABEL_E00028, 0xE00028
	.set LABEL_E00065, 0xE00065
	.set LABEL_E00073, 0xE00073
	.set LABEL_E0007C, 0xE0007C
	.set LABEL_E000C3, 0xE000C3
	.set LABEL_E00111, 0xE00111
	.set LABEL_E00113, 0xE00113
	.set LABEL_E0019E, 0xE0019E
	.set LABEL_E00302, 0xE00302
	.set LABEL_E00800, 0xE00800
	.set LABEL_E00B04, 0xE00B04
	.set LABEL_E00B28, 0xE00B28
	.set LABEL_E14C32, 0xE14C32
	.set LABEL_E14C86, 0xE14C86
	.set LABEL_E16BAC, 0xE16BAC
	.set LABEL_E1708A, 0xE1708A
	.set LABEL_E17096, 0xE17096
	.set LABEL_E17112, 0xE17112
	.set LABEL_E1711E, 0xE1711E
	.set LABEL_E18D4C, 0xE18D4C
	.set LABEL_E1A224, 0xE1A224
	.set LABEL_E1CDE2, 0xE1CDE2
	.set LABEL_E1CDE6, 0xE1CDE6
	.set LABEL_E1CDEA, 0xE1CDEA
	.set LABEL_E1CDEE, 0xE1CDEE
	.set LABEL_E1CDF2, 0xE1CDF2
	.set LABEL_E1CDF6, 0xE1CDF6
	.set LABEL_E1CDFA, 0xE1CDFA
	.set LABEL_E1CDFE, 0xE1CDFE
	.set LABEL_E1CE02, 0xE1CE02
	.set LABEL_E1CE06, 0xE1CE06
	.set LABEL_E1CE0A, 0xE1CE0A
	.set LABEL_E1CE0E, 0xE1CE0E
	.set StrNotePos_FlatAlt, 0xE1DD4C
	.set StrNotePos_FlatAltB8, 0xE1DD52
	.set StrNotePos_AcNatural, 0xE1DD5A
	.set LABEL_E1FFB6, 0xE1FFB6
	.set LABEL_E208A4, 0xE208A4
	.set LABEL_E20B7C, 0xE20B7C
	.set LABEL_E20B86, 0xE20B86
	.set LABEL_E21AD2, 0xE21AD2
	.set NakaStr_PdMdlyOrcha, 0xE22322
	.set LABEL_E2364A, 0xE2364A
	.set LABEL_E23C12, 0xE23C12
	.set NakaWidget_Perf2Flute, 0xE23C1A
	.set LABEL_E23CCA, 0xE23CCA
	.set NakaWidget_Perf2Piano, 0xE23CD4
	.set LABEL_E23D0A, 0xE23D0A
	.set LABEL_E23E62, 0xE23E62
	.set NakaWidget_Perf3JazzBand, 0xE23E6E
	.set LABEL_E23EA4, 0xE23EA4
	.set NakaWidget_Perf3LatinOrch, 0xE23EB4
	.set LABEL_E23EEA, 0xE23EEA
	.set NakaWidget_Perf3BigBand, 0xE23EF6
	.set LABEL_E23F2C, 0xE23F2C
	.set NakaWidget_Perf3SymphOrch, 0xE23F3A
	.set LABEL_E2405E, 0xE2405E
	.set NakaFld_TabIndexFunc, 0xE270EA
	.set LABEL_E2713C, 0xE2713C
	.set NakaInst_SqedtVal, 0xE27564
	.set NakaInst_SqedtVal_B, 0xE27574
	.set NakaInst_EqualizerBox, 0xE27586
	.set Data_NakaPresetConfig, 0xE278A9
	.set LABEL_E2DF22, 0xE2DF22
	.set LABEL_E2DF54, 0xE2DF54
	.set LABEL_E2DF64, 0xE2DF64
	.set LABEL_E2DFA6, 0xE2DFA6
	.set LABEL_E30001, 0xE30001
	.set LABEL_E30002, 0xE30002
	.set LABEL_E30003, 0xE30003
	.set LABEL_E30005, 0xE30005
	.set LABEL_E30006, 0xE30006
	.set LABEL_E30B2A, 0xE30B2A
	.set LABEL_E30B51, 0xE30B51
	.set TableData_NullDialogText, 0xE33824
	.set LABEL_E3382C, 0xE3382C
	.set LABEL_E338A6, 0xE338A6
	.set LABEL_E338C2, 0xE338C2
	.set LABEL_E338E2, 0xE338E2
	.set LABEL_E33EE4, 0xE33EE4
	.set LABEL_E33F22, 0xE33F22
	.set LABEL_E3405E, 0xE3405E
	.set LABEL_E340A6, 0xE340A6
	.set LABEL_E34104, 0xE34104
	.set LABEL_E3412A, 0xE3412A
	.set LABEL_E34614, 0xE34614
	.set LABEL_E34944, 0xE34944
	.set LABEL_E34B5E, 0xE34B5E
	.set LABEL_E34BB6, 0xE34BB6
	.set LABEL_E34BBE, 0xE34BBE
	.set LABEL_E3DEF1, 0xE3DEF1
	.set LABEL_E3E0F1, 0xE3E0F1
	.set LABEL_E3E2F2, 0xE3E2F2
	.set LABEL_E40000, 0xE40000
	.set LABEL_E40002, 0xE40002
	.set LABEL_E40005, 0xE40005
	.set LABEL_E40031, 0xE40031
	.set LABEL_E40046, 0xE40046
	.set LABEL_E40059, 0xE40059
	.set LABEL_E40066, 0xE40066
	.set LABEL_E4006E, 0xE4006E
	.set LABEL_E40081, 0xE40081
	.set LABEL_E40096, 0xE40096
	.set LABEL_E400A9, 0xE400A9
	.set LABEL_E400BE, 0xE400BE
	.set LABEL_E400D0, 0xE400D0
	.set LABEL_E40101, 0xE40101
	.set LABEL_E40116, 0xE40116
	.set LABEL_E40A09, 0xE40A09
	.set LABEL_E41807, 0xE41807
	.set LABEL_E46312, 0xE46312
	.set LABEL_E5002D, 0xE5002D
	.set LABEL_E5006E, 0xE5006E
	.set LABEL_E500BE, 0xE500BE
	.set LABEL_E500CE, 0xE500CE
	.set LABEL_E500FE, 0xE500FE
	.set LABEL_E50117, 0xE50117
	.set NakaHandler_CtrlMessages, 0xE56ACC
	.set NakaHandler_RealtimeMessages, 0xE56B14
	.set NakaHandler_CommonSetting, 0xE56B5C
	.set NakaHandler_ProgChangeMidiOut, 0xE56CBC
	.set NakaInst_InOutSettingGrid, 0xE57504
	.set LABEL_E578AA, 0xE578AA
	.set NakaInst_KN5000_MidiPresets, 0xE57982
	.set NakaInst_UserSettingSelector, 0xE57C8E
	.set NakaHandler_SplitPointDialog, 0xE57E6E
	.set NakaInst_SndModVocalistExtSeq, 0xE57F36
	.set NakaInst_KN5000_SysexBulkDump, 0xE57FA2
	.set NakaInst_WithAPC_Presets, 0xE5804E
	.set NakaInst_WithoutAPC_Presets, 0xE580A6
	.set NakaInst_Value_SysexPresets, 0xE580D2
	.set NakaInst_WithAPC_GM, 0xE5821E
	.set NakaInst_WithoutAPC_GM, 0xE58276
	.set NakaInst_Value_GM, 0xE582A2
	.set NakaInst_KN5000_GM, 0xE582E2
	.set NakaInst_BulkDumpCategorySelect, 0xE583A6
	.set NakaInst_Receiving_Sysex, 0xE58742
	.set NakaInst_ProgChangeLabel, 0xE58FDA
	.set NakaInst_P_MEM_ON_OFF_PART, 0xE5904A
	.set NakaInst_PresetSettingsLabel, 0xE59532
	.set NakaInst_ItemLabel_RevEqPreset, 0xE5985A
	.set LABEL_E60000, 0xE60000
	.set LABEL_E60008, 0xE60008
	.set LABEL_E6009A, 0xE6009A
	.set LABEL_E600AA, 0xE600AA
	.set LABEL_E600DA, 0xE600DA
	.set LABEL_E600DF, 0xE600DF
	.set LABEL_E600E4, 0xE600E4
	.set LABEL_E600EC, 0xE600EC
	.set LABEL_E678FF, 0xE678FF
	.set LABEL_E70015, 0xE70015
	.set LABEL_E7001E, 0xE7001E
	.set LABEL_E70022, 0xE70022
	.set LABEL_E700DE, 0xE700DE
	.set LABEL_E70B28, 0xE70B28
	.set LABEL_E7F91C, 0xE7F91C
	.set LABEL_E7F922, 0xE7F922
	.set Data_AcGridParamTable, 0xE7F9AC
	.set LABEL_E8005F, 0xE8005F
	.set LABEL_E800CA, 0xE800CA
	.set LABEL_E800CE, 0xE800CE
	.set LABEL_E800DE, 0xE800DE
	.set LABEL_E800FA, 0xE800FA
	.set LABEL_E8013C, 0xE8013C
	.set LABEL_E801D4, 0xE801D4
	.set LABEL_E8068C, 0xE8068C
	.set LABEL_E80692, 0xE80692
	.set LABEL_E806A4, 0xE806A4
	.set LABEL_E806AA, 0xE806AA
	.set LABEL_E80B12, 0xE80B12
	.set LABEL_E878F9, 0xE878F9
	.set LABEL_E8CFEB, 0xE8CFEB
	.set LABEL_E90077, 0xE90077
	.set LABEL_E900D8, 0xE900D8
	.set LABEL_E900E1, 0xE900E1
	.set LABEL_E900EC, 0xE900EC
	.set NakaInst_SequencerComboBox, 0xE90130
	.set LABEL_E90133, 0xE90133
	.set LABEL_E9013D, 0xE9013D
	.set LABEL_E90B3B, 0xE90B3B
	.set LABEL_E96344, 0xE96344
	.set LABEL_E97114, 0xE97114
	.set LABEL_E971DE, 0xE971DE
	.set LABEL_E97BDE, 0xE97BDE
	.set LABEL_E97DC2, 0xE97DC2
	.set LABEL_E98676, 0xE98676
	.set LABEL_E9871A, 0xE9871A
	.set LABEL_E98AEE, 0xE98AEE
	.set LABEL_E99A0E, 0xE99A0E
	.set LABEL_E99CD4, 0xE99CD4
	.set LABEL_E99EDC, 0xE99EDC
	.set LABEL_E9A2C4, 0xE9A2C4
	.set LABEL_E9B92A, 0xE9B92A
	.set LABEL_E9BF3A, 0xE9BF3A
	.set LABEL_E9C524, 0xE9C524
	.set LABEL_E9C6FC, 0xE9C6FC
	.set LABEL_E9CF14, 0xE9CF14
	.set LABEL_EA1D7A, 0xEA1D7A
	.set LABEL_EA2442, 0xEA2442
	.set LABEL_EA263A, 0xEA263A
	.set LABEL_EA26AA, 0xEA26AA
	.set LABEL_EA26D2, 0xEA26D2
	.set LABEL_EA27A2, 0xEA27A2
	.set LABEL_EA2822, 0xEA2822
	.set LABEL_EA2952, 0xEA2952
	.set LABEL_EA29A2, 0xEA29A2
	.set LABEL_EA2D36, 0xEA2D36
	.set LABEL_EA2D3E, 0xEA2D3E
	.set LABEL_EA2E26, 0xEA2E26
	.set LABEL_EA2F0E, 0xEA2F0E
	.set LABEL_EA2F3A, 0xEA2F3A
	.set LABEL_EA3B5A, 0xEA3B5A
	.set LABEL_EA3BB2, 0xEA3BB2
	.set LABEL_EA3D2A, 0xEA3D2A
	.set LABEL_EA3D7A, 0xEA3D7A
	.set LABEL_EA3DCA, 0xEA3DCA
	.set LABEL_EA3F6A, 0xEA3F6A
	.set LABEL_EA3FDA, 0xEA3FDA
	.set LABEL_EA4002, 0xEA4002
	.set LABEL_EA4082, 0xEA4082
	.set LABEL_EA41D2, 0xEA41D2
	.set LABEL_EA435A, 0xEA435A
	.set LABEL_EA43BC, 0xEA43BC
	.set LABEL_EA44A2, 0xEA44A2
	.set LABEL_EA471A, 0xEA471A
	.set LABEL_EA66B6, 0xEA66B6
	.set LABEL_EA6706, 0xEA6706
	.set LABEL_EA8CAC, 0xEA8CAC
	.set LABEL_EA8CBC, 0xEA8CBC
	.set LABEL_EAAEF4, 0xEAAEF4
	.set LABEL_EAB18C, 0xEAB18C
	.set WidgetPropStr_Max, 0xEAC1BA
	.set WidgetPropStr_RangeFigures, 0xEAC1BE
	.set LABEL_EADA96, 0xEADA96
	.set LABEL_EADB1A, 0xEADB1A
	.set LABEL_EADB26, 0xEADB26
	.set LABEL_EADB32, 0xEADB32
	.set LABEL_EADB3E, 0xEADB3E
	.set LABEL_EADB4A, 0xEADB4A
	.set LABEL_EADB56, 0xEADB56
	.set IconBitmapName_i96o, 0xEB2796
	.set LABEL_EB287E, 0xEB287E
	.set LABEL_EB2886, 0xEB2886
	.set LABEL_EB288E, 0xEB288E
	.set LABEL_EB2896, 0xEB2896
	.set LABEL_EB289E, 0xEB289E
	.set LABEL_EB28A6, 0xEB28A6
	.set LABEL_EB28AE, 0xEB28AE
	.set LABEL_EB28B6, 0xEB28B6
	.set LABEL_EB28BE, 0xEB28BE
	.set LABEL_EB28C6, 0xEB28C6
	.set LABEL_EB28CE, 0xEB28CE
	.set LABEL_EB28D6, 0xEB28D6
	.set LABEL_EB28DE, 0xEB28DE
	.set LABEL_EB28E6, 0xEB28E6
	.set LABEL_EB28EE, 0xEB28EE
	.set LABEL_EB28F6, 0xEB28F6
	.set LABEL_EB28FE, 0xEB28FE
	.set LABEL_EB2906, 0xEB2906
	.set LABEL_EB290E, 0xEB290E
	.set LABEL_EB2916, 0xEB2916
	.set LABEL_EB291E, 0xEB291E
	.set LABEL_EB2926, 0xEB2926
	.set LABEL_EB292E, 0xEB292E
	.set LABEL_EB2936, 0xEB2936
	.set LABEL_EB293E, 0xEB293E
	.set LABEL_EB2946, 0xEB2946
	.set LABEL_EB294E, 0xEB294E
	.set LABEL_EB2956, 0xEB2956
	.set LABEL_EB295E, 0xEB295E
	.set LABEL_EB2966, 0xEB2966
	.set LABEL_EB296E, 0xEB296E
	.set LABEL_EB2976, 0xEB2976
	.set LABEL_EB297E, 0xEB297E
	.set LABEL_EB2986, 0xEB2986
	.set LABEL_EB298E, 0xEB298E
	.set LABEL_EB2996, 0xEB2996
	.set LABEL_EB299E, 0xEB299E
	.set LABEL_EB29A6, 0xEB29A6
	.set LABEL_EB29AE, 0xEB29AE
	.set LABEL_EB29B6, 0xEB29B6
	.set LABEL_EB29BE, 0xEB29BE
	.set LABEL_EB29C6, 0xEB29C6
	.set LABEL_EB29CE, 0xEB29CE
	.set LABEL_EB29D6, 0xEB29D6
	.set LABEL_EB29DE, 0xEB29DE
	.set LABEL_EB29E6, 0xEB29E6
	.set LABEL_EB29EE, 0xEB29EE
	.set LABEL_EB29F6, 0xEB29F6
	.set LABEL_EB29FE, 0xEB29FE
	.set LABEL_EB2A06, 0xEB2A06
	.set LABEL_EB2A0E, 0xEB2A0E
	.set LABEL_EB2A16, 0xEB2A16
	.set LABEL_EB2A1E, 0xEB2A1E
	.set LABEL_EB2A26, 0xEB2A26
	.set LABEL_EB2A2E, 0xEB2A2E
	.set LABEL_EB2A36, 0xEB2A36
	.set LABEL_EB2A3E, 0xEB2A3E
	.set LABEL_EB2A46, 0xEB2A46
	.set LABEL_EB2A4E, 0xEB2A4E
	.set LABEL_EB2A56, 0xEB2A56
	.set LABEL_EB2A5E, 0xEB2A5E
	.set LABEL_EB2A66, 0xEB2A66
	.set LABEL_EB2A6E, 0xEB2A6E
	.set LABEL_EB2A76, 0xEB2A76
	.set LABEL_EB2A7E, 0xEB2A7E
	.set LABEL_EB2A86, 0xEB2A86
	.set LABEL_EB2A8E, 0xEB2A8E
	.set LABEL_EB2A96, 0xEB2A96
	.set LABEL_EB2A9E, 0xEB2A9E
	.set LABEL_EB2AA6, 0xEB2AA6
	.set LABEL_EB2AAE, 0xEB2AAE
	.set Palette_8bit_RGBA, 0xEB37DE
	.set LABEL_EBBC26, 0xEBBC26
	.set LABEL_EBBCAE, 0xEBBCAE
	.set LABEL_EBBD36, 0xEBBD36
	.set LABEL_EBBDBE, 0xEBBDBE
	.set LABEL_EBBE46, 0xEBBE46
	.set LABEL_EBBECE, 0xEBBECE
	.set LABEL_EBBF56, 0xEBBF56
	.set LABEL_EBBFDE, 0xEBBFDE
	.set LABEL_EBC066, 0xEBC066
	.set LABEL_EBC0EE, 0xEBC0EE
	.set LABEL_EBC176, 0xEBC176
	.set LABEL_EBC1FE, 0xEBC1FE
	.set LABEL_EBC286, 0xEBC286
	.set LABEL_EBC30E, 0xEBC30E
	.set LABEL_EBC396, 0xEBC396
	.set LABEL_EBC41E, 0xEBC41E
	.set LABEL_EBC4A6, 0xEBC4A6
	.set LABEL_EBC52E, 0xEBC52E
	.set LABEL_EBC5B6, 0xEBC5B6
	.set LABEL_EBC63E, 0xEBC63E
	.set LABEL_EBC6C6, 0xEBC6C6
	.set LABEL_EBC74E, 0xEBC74E
	.set LABEL_EBC7D6, 0xEBC7D6
	.set LABEL_EBC85E, 0xEBC85E
	.set LABEL_EBC8E6, 0xEBC8E6
	.set LABEL_EBC96E, 0xEBC96E
	.set LABEL_EBC9F6, 0xEBC9F6
	.set LABEL_EBCA7E, 0xEBCA7E
	.set LABEL_EBCB06, 0xEBCB06
	.set LABEL_EBCB8E, 0xEBCB8E
	.set LABEL_EBCC16, 0xEBCC16
	.set LABEL_EBCC9E, 0xEBCC9E
	.set LABEL_EBCD26, 0xEBCD26
	.set LABEL_EBCDAE, 0xEBCDAE
	.set LABEL_EBCE36, 0xEBCE36
	.set LABEL_EBCEBE, 0xEBCEBE
	.set LABEL_EBCF46, 0xEBCF46
	.set LABEL_EBCFCE, 0xEBCFCE
	.set LABEL_EBD056, 0xEBD056
	.set LABEL_EBD0DE, 0xEBD0DE
	.set LABEL_EBD166, 0xEBD166
	.set LABEL_EBD1EE, 0xEBD1EE
	.set LABEL_EBD276, 0xEBD276
	.set LABEL_EBD2FE, 0xEBD2FE
	.set LABEL_EBD386, 0xEBD386
	.set LABEL_EBD40E, 0xEBD40E
	.set LABEL_EBD496, 0xEBD496
	.set LABEL_EBD51E, 0xEBD51E
	.set LABEL_EBD5A6, 0xEBD5A6
	.set LABEL_EBD62E, 0xEBD62E
	.set LABEL_EBD6B6, 0xEBD6B6
	.set LABEL_EBD73E, 0xEBD73E
	.set LABEL_EBD7C6, 0xEBD7C6
	.set LABEL_EBD84E, 0xEBD84E
	.set LABEL_EBD8D6, 0xEBD8D6
	.set LABEL_EBD95E, 0xEBD95E
	.set LABEL_EBD9E6, 0xEBD9E6
	.set LABEL_EBDA6E, 0xEBDA6E
	.set LABEL_EBDAF6, 0xEBDAF6
	.set LABEL_EBDB7E, 0xEBDB7E
	.set LABEL_EBDC06, 0xEBDC06
	.set LABEL_EBDC8E, 0xEBDC8E
	.set LABEL_EBDD16, 0xEBDD16
	.set LABEL_EBDD9E, 0xEBDD9E
	.set LABEL_EBDE26, 0xEBDE26
	.set LABEL_EBDEAE, 0xEBDEAE
	.set LABEL_EBDF36, 0xEBDF36
	.set LABEL_EBDFBE, 0xEBDFBE
	.set LABEL_EBE046, 0xEBE046
	.set LABEL_EBE0CE, 0xEBE0CE
	.set LABEL_EBE156, 0xEBE156
	.set LABEL_EBE1DE, 0xEBE1DE
	.set LABEL_EBE266, 0xEBE266
	.set LABEL_EBE2EE, 0xEBE2EE
	.set LABEL_EBE376, 0xEBE376
	.set LABEL_EBE3FE, 0xEBE3FE
	.set LABEL_EBE486, 0xEBE486
	.set LABEL_EBE50E, 0xEBE50E
	.set LABEL_EBE596, 0xEBE596
	.set LABEL_EBE61E, 0xEBE61E
	.set LABEL_EBE6A6, 0xEBE6A6
	.set LABEL_EBE72E, 0xEBE72E
	.set LABEL_EBE7B6, 0xEBE7B6
	.set LABEL_EBE83E, 0xEBE83E
	.set LABEL_EBE8C6, 0xEBE8C6
	.set LABEL_EBE94E, 0xEBE94E
	.set LABEL_EBE9D6, 0xEBE9D6
	.set LABEL_EBEA5E, 0xEBEA5E
	.set LABEL_EBEAE6, 0xEBEAE6
	.set LABEL_EBEB6E, 0xEBEB6E
	.set LABEL_EBEBF6, 0xEBEBF6
	.set LABEL_EBEC7E, 0xEBEC7E
	.set LABEL_EBED06, 0xEBED06
	.set LABEL_EBED8E, 0xEBED8E
	.set LABEL_EBEE16, 0xEBEE16
	.set LABEL_EBEE9E, 0xEBEE9E
	.set LABEL_EBEF26, 0xEBEF26
	.set LABEL_EBEFAE, 0xEBEFAE
	.set LABEL_EBF036, 0xEBF036
	.set LABEL_EBF0BE, 0xEBF0BE
	.set LABEL_EBF146, 0xEBF146
	.set LABEL_EBF1CE, 0xEBF1CE
	.set LABEL_EBF256, 0xEBF256
	.set LABEL_EBF2DE, 0xEBF2DE
	.set LABEL_EBF366, 0xEBF366
	.set LABEL_EBF3EE, 0xEBF3EE
	.set LABEL_EBF476, 0xEBF476
	.set LABEL_EBF4FE, 0xEBF4FE
	.set LABEL_EBF586, 0xEBF586
	.set LABEL_EBF60E, 0xEBF60E
	.set LABEL_EBF696, 0xEBF696
	.set LABEL_EBF71E, 0xEBF71E
	.set LABEL_EBF7A6, 0xEBF7A6
	.set LABEL_EBF82E, 0xEBF82E
	.set LABEL_EBF8B6, 0xEBF8B6
	.set LABEL_EBF93E, 0xEBF93E
	.set LABEL_EBF9C6, 0xEBF9C6
	.set LABEL_EBFA4E, 0xEBFA4E
	.set LABEL_EBFAD6, 0xEBFAD6
	.set LABEL_EBFB5E, 0xEBFB5E
	.set LABEL_EBFBE6, 0xEBFBE6
	.set LABEL_EBFC6E, 0xEBFC6E
	.set LABEL_EBFCF6, 0xEBFCF6
	.set LABEL_EBFD7E, 0xEBFD7E
	.set LABEL_EBFE06, 0xEBFE06
	.set LABEL_EBFE8E, 0xEBFE8E
	.set LABEL_EBFF16, 0xEBFF16
	.set LABEL_EBFF9E, 0xEBFF9E
	.set LABEL_EC00C7, 0xEC00C7
	.set LABEL_EC00EC, 0xEC00EC
	.set LABEL_EC0113, 0xEC0113
	.set LABEL_EC013B, 0xEC013B
	.set LABEL_EC013F, 0xEC013F
	.set LABEL_EC0A1B, 0xEC0A1B
	.set LABEL_EC88EC, 0xEC88EC
	.set LABEL_EC8974, 0xEC8974
	.set LABEL_EC89B4, 0xEC89B4
	.set LABEL_EC8A1A, 0xEC8A1A
	.set LABEL_EC8A7C, 0xEC8A7C
	.set LABEL_ECB09C, 0xECB09C
	.set LABEL_ECB102, 0xECB102
	.set LABEL_ECB164, 0xECB164
	.set LABEL_ECB26C, 0xECB26C
	.set LABEL_ECB2F4, 0xECB2F4
	.set LABEL_ECB334, 0xECB334
	.set LABEL_ECB39A, 0xECB39A
	.set LABEL_ECB3FC, 0xECB3FC
	.set LABEL_ECDBEC, 0xECDBEC
	.set LABEL_ECDCB4, 0xECDCB4
	.set LABEL_ECDD7C, 0xECDD7C
	.set LABEL_ECDE44, 0xECDE44
	.set LABEL_ECDE84, 0xECDE84
	.set LABEL_ECDF4C, 0xECDF4C
	.set LABEL_ECE014, 0xECE014
	.set LABEL_ECE0DC, 0xECE0DC
	.set LABEL_ECE11C, 0xECE11C
	.set LABEL_ECE1E4, 0xECE1E4
	.set LABEL_ECE2AC, 0xECE2AC
	.set EffSeqScreen_ChordTypePtr_A, 0xED0072
	.set EffSeqScreen_ChordTypePtr_B, 0xED009C
	.set NakaInst_WITH_APC, 0xED00D5
	.set LABEL_ED013B, 0xED013B
	.set SeqChanContainer_ChordTypeRef_A, 0xED0212
	.set SeqChanContainer_ChordTypeRef_B, 0xED029C
	.set ParamStr08_varisupart, 0xED210E
	.set ParamStr08_page, 0xED2116
	.set ParamStr08_fontcolor, 0xED211C
	.set ParamStr08_font, 0xED2122
	.set ParamStr08_func, 0xED212C
	.set ParamStr19_fixedcol, 0xED250C
	.set ParamStr22_nowsongsubctgdtno, 0xED275C
	.set ParamStr22_func, 0xED276E
	.set ParamStr22_fixedrow, 0xED2774
	.set ParamStr22_fixedcol, 0xED277E
	.set NakaInst_AcMstSugAlpGridBox, 0xED2B9A
	.set NakaInst_AcFSWAssGridBox, 0xED2BE2
	.set NakaDesc_AcTchSensGridBox, 0xED2BF4
	.set NakaInst_AcTchSensGridBox, 0xED2BF6
	.set NakaDesc_IvMstStyleWindowPgCtl, 0xED2C0C
	.set NakaInst_IvMstStyleWindowPgCtl, 0xED2C0E
	.set NakaDesc_IvPmemWindowPageCtl, 0xED2C22
	.set NakaInst_IvPmemWindowPageCtl, 0xED2C24
	.set NakaInst_MsaModeScreen, 0xED2C62
	.set LABEL_ED46D2, 0xED46D2
	.set LABEL_ED4722, 0xED4722
	.set LABEL_ED474A, 0xED474A
	.set LABEL_ED477A, 0xED477A
	.set LABEL_ED4922, 0xED4922
	.set LABEL_ED4A82, 0xED4A82
	.set LABEL_ED4DE2, 0xED4DE2
	.set LABEL_ED5122, 0xED5122
	.set LABEL_ED517A, 0xED517A
	.set ExtDevScreen_SndParamBank_Desc, 0xED690A
	.set ExtDevScreen_SndParamPage_Desc, 0xED69A2
	.set ExtDevScreen_VoiceParamBank_Desc, 0xED6A7A
	.set ExtDevScreen_VoiceParamRhythm_Desc, 0xED6B0A
	.set ExtDevScreen_VoiceParamDrums_Desc, 0xED6B52
	.set ExtDevScreen_VoiceSetup_Desc, 0xED6BE2
	.set ExtDevScreen_VoiceMainPage_Desc, 0xED6C6E
	.set ExtDevScreen_MidiCtrl_Desc, 0xED6FF2
	.set ExtDevScreen_MidiCtrlPage_Desc, 0xED70A2
	.set ExtDevScreen_MidiCtrlDetail_Desc, 0xED71B2
	.set ExtDevScreen_MidiCtrlAdvanced_Desc, 0xED723A
	.set ExtDevScreen_DspEffect_Desc, 0xED729A
	.set ExtDevScreen_DspEffectPage_Desc, 0xED734A
	.set ExtDevScreen_ReverbSetup_Desc, 0xED745A
	.set ExtDevScreen_ReverbPage_Desc, 0xED74E2
	.set ExtDevScreen_Equalizer_Desc, 0xED7542
	.set ExtDevScreen_EqualizerPage_Desc, 0xED75F2
	.set ExtDevScreen_UserInitWallpaper_Flag, 0xED9F54
	.set ExtDevScreen_UserInitWallpaper_Data, 0xED9F5C
	.set ENCODER_LUT_VOLUME, 0xEDA1BC
	.set ENCODER_LUT_BREATH_INDEX, 0xEDA2BC
	.set ENCODER_LUT_BREATH_VALUE, 0xEDA2D2
	.set ENCODER_LUT_BREATH_MULT, 0xEDA3D2
	.set ENCODER_LUT_BREATH_OFFSET, 0xEDA3EA
	.set ENCODER_LUT_FOOT, 0xEDA402
	.set ENCODER_LUT_EXPRESSION, 0xEDA482
	.set LABEL_EDA704, 0xEDA704
	.set LABEL_EDA71C, 0xEDA71C
	.set LABEL_EDA734, 0xEDA734
	.set LABEL_EDA74C, 0xEDA74C
	.set LABEL_EDA764, 0xEDA764
	.set LABEL_EDA77C, 0xEDA77C
	.set LABEL_EDA794, 0xEDA794
	.set LABEL_EDA7AC, 0xEDA7AC
	.set LABEL_EDA7C4, 0xEDA7C4
	.set LABEL_EDA7DC, 0xEDA7DC
	.set LABEL_EDA7F4, 0xEDA7F4
	.set LABEL_EDA80C, 0xEDA80C
	.set LABEL_EDA824, 0xEDA824
	.set LABEL_EDA83C, 0xEDA83C
	.set LABEL_EDA854, 0xEDA854
	.set LABEL_EDA86C, 0xEDA86C
	.set LABEL_EDA884, 0xEDA884
	.set LABEL_EDA89C, 0xEDA89C
	.set LABEL_EDA8B4, 0xEDA8B4
	.set LABEL_EDA8E4, 0xEDA8E4
	.set LABEL_EDA914, 0xEDA914
	.set LABEL_EDA944, 0xEDA944
	.set LABEL_EDA974, 0xEDA974
	.set LABEL_EDA9A4, 0xEDA9A4
	.set LABEL_EDA9D4, 0xEDA9D4
	.set LABEL_EDAA04, 0xEDAA04
	.set LABEL_EDAA34, 0xEDAA34
	.set LABEL_EDB2E4, 0xEDB2E4
	.set WidgetParam_TestMode_Entry, 0xEDBA44
	.set WidgetParam_SineWave_Entry, 0xEDBAAE
	.set LABEL_EE0206, 0xEE0206
	.set LABEL_EE3023, 0xEE3023
	.set LABEL_EE3025, 0xEE3025
	.set LABEL_EE45D2, 0xEE45D2
	.set LABEL_EE45EA, 0xEE45EA
	.set LABEL_EE4662, 0xEE4662
	.set LABEL_EE4692, 0xEE4692
	.set LABEL_EE46DA, 0xEE46DA
	.set LABEL_EE470A, 0xEE470A
	.set LABEL_EE4752, 0xEE4752
	.set LABEL_EE4782, 0xEE4782
	.set LABEL_EE479A, 0xEE479A
	.set LABEL_EED3DE, 0xEED3DE
	.set LABEL_EED52B, 0xEED52B
	.set LABEL_EEE812, 0xEEE812
	.set LABEL_EF001F, 0xEF001F
	.set LABEL_EF0026, 0xEF0026
	.set LABEL_EF7779, 0xEF7779
	.set LABEL_EF8B6D, 0xEF8B6D
	.set LABEL_EF8DFB, 0xEF8DFB
	.set LABEL_EF9554, 0xEF9554
	.set LABEL_EF955D, 0xEF955D
	.set MemConfig_Handler_2, 0xEFACF7
	.set LABEL_EFDB94, 0xEFDB94
	.set LABEL_EFF827, 0xEFF827
	.set LABEL_F1039E, 0xF1039E
	.set LABEL_F1040D, 0xF1040D
	.set LABEL_F1041D, 0xF1041D
	.set LABEL_F10454, 0xF10454
	.set LABEL_F10464, 0xF10464
	.set LABEL_F1048E, 0xF1048E
	.set LABEL_F104B8, 0xF104B8
	.set LABEL_F104C8, 0xF104C8
	.set LABEL_F104D8, 0xF104D8
	.set LABEL_F104E8, 0xF104E8
	.set LABEL_F10512, 0xF10512
	.set LABEL_F105C4, 0xF105C4
	.set LABEL_F10676, 0xF10676
	.set LABEL_F10689, 0xF10689
	.set LABEL_F15891, 0xF15891
	.set LABEL_F1589C, 0xF1589C
	.set LABEL_F16006, 0xF16006
	.set LABEL_F16028, 0xF16028
	.set LABEL_F1604A, 0xF1604A
	.set LABEL_F16056, 0xF16056
	.set LABEL_F16063, 0xF16063
	.set LABEL_F16070, 0xF16070
	.set LABEL_F16092, 0xF16092
	.set LABEL_F1609E, 0xF1609E
	.set LABEL_F160AB, 0xF160AB
	.set Data_Dispatch_Entry, 0xF160B8
	.set LABEL_F160F1, 0xF160F1
	.set LABEL_F160FD, 0xF160FD
	.set LABEL_F1649B, 0xF1649B
	.set LABEL_F164A6, 0xF164A6
	.set LABEL_F164B5, 0xF164B5
	.set LABEL_F164C0, 0xF164C0
	.set LABEL_F164CB, 0xF164CB
	.set LABEL_F164D6, 0xF164D6
	.set LABEL_F164E1, 0xF164E1
	.set LABEL_F164EC, 0xF164EC
	.set LABEL_F400EC, 0xF400EC
	.set LABEL_F5001F, 0xF5001F
	.set LABEL_F5002F, 0xF5002F
	.set LABEL_F50039, 0xF50039
	.set LABEL_F50052, 0xF50052
	.set LABEL_F50078, 0xF50078
	.set LABEL_F700BB, 0xF700BB
	.set LABEL_F900B9, 0xF900B9
	.set LABEL_F900F1, 0xF900F1
	.set FDC_INIT, 0xF96BBF
	.set FDC_CONFIG_VERIFY, 0xF96BD0
	.set FDC_CMD_DISPATCH_SUB, 0xF96D95
	.set FDC_CMD_SEND, 0xF972F9
	.set FDC_DETECT_CHECK, 0xF974FE
	.set FDC_DRIVE_DETECT, 0xF97544
	.set FDC_DRIVE_STATUS, 0xF97592
	.set FDC_PRE_OP_CHECK, 0xF975AC
	.set FDC_TIMING_DELAY, 0xF975DC
	.set FDC_POST_OP, 0xF975E2
	.set FDC_STATUS_HANDLER, 0xF97696
	.set FDC_CE_DISPATCH, 0xF9782A
	.set FDC_CE_EXIT, 0xF97833
	.set FDC_SECTOR_XFER, 0xF97835
	.set FDC_SX_MAIN, 0xF9795E
	.set FDC_SX_EXIT, 0xF97967
	.set FDC_CMD_ENABLE, 0xF97C21
	.set FDC_CMD_DISABLE, 0xF97C4B
	.set FDC_OUTPUT_CTRL, 0xF97C5B
	.set LABEL_FC0012, 0xFC0012
	.set LABEL_FC645A, 0xFC645A
	.set LABEL_FC647F, 0xFC647F
	.set LABEL_FC64EA, 0xFC64EA
	.set SeqChan_UnhandledCmd, 0xFD8261
	.set LABEL_FD8262, 0xFD8262
	.set LABEL_FD8263, 0xFD8263
	.set LABEL_FD8264, 0xFD8264
	.set LABEL_FD8273, 0xFD8273
	.set LABEL_FE0053, 0xFE0053
	.set LABEL_FF0270, 0xFF0270
	.set LABEL_FFFFFF, 0xFFFFFF
