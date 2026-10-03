; =============================================================================
; KN5000 Main CPU Program ROM (2MB: E00000-FFFFFF)
; =============================================================================

; --- Constants, Macros & SFR Definitions ---
	.text

	.include "shared/macros.s"
	.include "shared/positional_labels.s"
	.include "shared/sfr_tmp94c241.s"
	.include "shared/vga_constants.s"
	.include "shared/event_codes.s"
	.include "fdc_constants.s"
	.include "gui_constants.s"
	.include "cpanel_constants.s"
	.include "midi_encoder_constants.s"
	.include "shared/ram_variables.s"

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

.equ COM_SELECT, 0xb744	; (byte)	; v7 address, derived from v10's uses (name_kn5000_ram.py); was a copy of v10's 0xb7e0

.equ SEQ_ALT3_RINGBUF_BASE, 0x201c1

.equ MSP_SETTINGS__BASE_ADDR, 0x1e8800

	.org PROGRAM_FLASH__BASE_ADDR - 0xe00000, 0xff

	.include "boot/boot_data_tables.s"

; --- SSF (Style Synthesis Format) Gate State Data ---
	.include "sequencer/ssf_gate_states.s"

; --- Instrument Sound Data & Category Metadata ---
	.include "audio/sound_data.s"

; --- Style UI Parameter Blocks & Screen Data ---
	.include "ui_widgets/style_ui_params.s"

GUI_FormatStrings:		.include "includes/gui_format_strings.s"
; -----------------------------------------------------------------------------
; GUI_DisplayStructData .. the end of ToneGen_ParamTable: the data of the Scoop
; and sound-editor objects, cut at every address the code loads or names
; (scripts/lanes/sys/gui_tables.py: object parameter blocks passed to
; RegisterObjectTable, 18-entry code-pointer tables the Scoop_SoundEditorData /
; SeMenu_* dispatchers call through, and tables other code reads).  The bytes come
; from includes/gui_display_struct_data.c and audio/tonegen_param_table.c; the
; section names in those files' comments predate this and were not derived from
; these readers (ToneGen_ParamTable is not tone-generator data:
; scripts/analysis/v7_tonegen_paramtable_is_a_jumptable.py).
; -----------------------------------------------------------------------------
; purpose not established.
; tried: `lda`/`ld` of a 24- or 32-bit immediate, and any little-endian 24-bit copy of an address from 0x120 B before this slice to its end, anywhere in the ROM: none found
GUI_DisplayStructData:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x0, 0x6
NakaWidget_sefillpq1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x6, 0x22
NakaWidget_sefilhpq1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x28, 0x22
NakaWidget_sefill241:	.incbin "includes/generated/gui_display_struct_data.bin", 0x4A, 0x22
NakaWidget_sefilh241:	.incbin "includes/generated/gui_display_struct_data.bin", 0x6C, 0x22
NakaWidget_sefilbpf1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x8E, 0x22
NakaWidget_sefilbcf1:	.incbin "includes/generated/gui_display_struct_data.bin", 0xB0, 0x22
NakaWidget_sefilfil2:	.incbin "includes/generated/gui_display_struct_data.bin", 0xD2, 0x22
NakaWidget_sefilenv1:	.incbin "includes/generated/gui_display_struct_data.bin", 0xF4, 0x22
NakaWidget_sefilenv2:	.incbin "includes/generated/gui_display_struct_data.bin", 0x116, 0x22
NakaWidget_sefillfo1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x138, 0x22
NakaWidget_sedigeff:	.incbin "includes/generated/gui_display_struct_data.bin", 0x15A, 0x22
NakaWidget_sectr2:	.incbin "includes/generated/gui_display_struct_data.bin", 0x17C, 0x22
NakaWidget_sectr3:	.incbin "includes/generated/gui_display_struct_data.bin", 0x19E, 0x22
NakaWidget_secopy:	.incbin "includes/generated/gui_display_struct_data.bin", 0x1C0, 0x22
NakaWidget_sewrtmem:	.incbin "includes/generated/gui_display_struct_data.bin", 0x1E2, 0x22
NakaWidget_sewrtsnd:	.incbin "includes/generated/gui_display_struct_data.bin", 0x204, 0x22
; 32 parameter blocks of 8 B, one per object 0x20..0x3f (class 0x01600010, proc ViewableProc),
; registered by InitializeScoop+0x16F: the block address is the +10 data field of the 14-byte
; descriptor {+0 class, +4 proc, +8 u16, +10 data} RegisterObjectTable copies to 0x27ED2 + 14*index
GUI_DisplayStructData_0x226:	.incbin "includes/generated/gui_display_struct_data.bin", 0x226, 0x8
Scoop_ViewableTable_021:	.incbin "includes/generated/gui_display_struct_data.bin", 0x22E, 0x8
Scoop_ViewableTable_022:	.incbin "includes/generated/gui_display_struct_data.bin", 0x236, 0x8
Scoop_ViewableTable_023:	.incbin "includes/generated/gui_display_struct_data.bin", 0x23E, 0x8
Scoop_ViewableTable_024:	.incbin "includes/generated/gui_display_struct_data.bin", 0x246, 0x8
Scoop_ViewableTable_025:	.incbin "includes/generated/gui_display_struct_data.bin", 0x24E, 0x8
Scoop_ViewableTable_026:	.incbin "includes/generated/gui_display_struct_data.bin", 0x256, 0x8
Scoop_ViewableTable_027:	.incbin "includes/generated/gui_display_struct_data.bin", 0x25E, 0x8
Scoop_ViewableTable_028:	.incbin "includes/generated/gui_display_struct_data.bin", 0x266, 0x8
Scoop_ViewableTable_029:	.incbin "includes/generated/gui_display_struct_data.bin", 0x26E, 0x8
Scoop_ViewableTable_02A:	.incbin "includes/generated/gui_display_struct_data.bin", 0x276, 0x8
Scoop_ViewableTable_02B:	.incbin "includes/generated/gui_display_struct_data.bin", 0x27E, 0x8
Scoop_ViewableTable_02C:	.incbin "includes/generated/gui_display_struct_data.bin", 0x286, 0x8
Scoop_ViewableTable_02D:	.incbin "includes/generated/gui_display_struct_data.bin", 0x28E, 0x8
Scoop_ViewableTable_02E:	.incbin "includes/generated/gui_display_struct_data.bin", 0x296, 0x8
Scoop_ViewableTable_02F:	.incbin "includes/generated/gui_display_struct_data.bin", 0x29E, 0x8
Scoop_ViewableTable_030:	.incbin "includes/generated/gui_display_struct_data.bin", 0x2A6, 0x8
Scoop_ViewableTable_031:	.incbin "includes/generated/gui_display_struct_data.bin", 0x2AE, 0x8
Scoop_ViewableTable_032:	.incbin "includes/generated/gui_display_struct_data.bin", 0x2B6, 0x8
Scoop_ViewableTable_033:	.incbin "includes/generated/gui_display_struct_data.bin", 0x2BE, 0x8
Scoop_ViewableTable_034:	.incbin "includes/generated/gui_display_struct_data.bin", 0x2C6, 0x8
Scoop_ViewableTable_035:	.incbin "includes/generated/gui_display_struct_data.bin", 0x2CE, 0x8
Scoop_ViewableTable_036:	.incbin "includes/generated/gui_display_struct_data.bin", 0x2D6, 0x8
Scoop_ViewableTable_037:	.incbin "includes/generated/gui_display_struct_data.bin", 0x2DE, 0x8
Scoop_ViewableTable_038:	.incbin "includes/generated/gui_display_struct_data.bin", 0x2E6, 0x8
Scoop_ViewableTable_039:	.incbin "includes/generated/gui_display_struct_data.bin", 0x2EE, 0x8
Scoop_ViewableTable_03A:	.incbin "includes/generated/gui_display_struct_data.bin", 0x2F6, 0x8
Scoop_ViewableTable_03B:	.incbin "includes/generated/gui_display_struct_data.bin", 0x2FE, 0x8
Scoop_ViewableTable_03C:	.incbin "includes/generated/gui_display_struct_data.bin", 0x306, 0x8
Scoop_ViewableTable_03D:	.incbin "includes/generated/gui_display_struct_data.bin", 0x30E, 0x8
Scoop_ViewableTable_03E:	.incbin "includes/generated/gui_display_struct_data.bin", 0x316, 0x8
Scoop_ViewableTable_03F:	.incbin "includes/generated/gui_display_struct_data.bin", 0x31E, 0x8
; 32 parameter blocks of 18-20 B (address differences), one per object 0x320..0x33f (class 0x0160000F, proc ResNameProc),
; registered by InitializeScoop+0x194: the block address is the +10 data field of the 14-byte
; descriptor {+0 class, +4 proc, +8 u16, +10 data} RegisterObjectTable copies to 0x27ED2 + 14*index
GUI_DisplayStructData_0x326:	.incbin "includes/generated/gui_display_struct_data.bin", 0x326, 0x12
Scoop_ResNameTable_321:		.incbin "includes/generated/gui_display_struct_data.bin", 0x338, 0x12
Scoop_ResNameTable_322:		.incbin "includes/generated/gui_display_struct_data.bin", 0x34A, 0x14
Scoop_ResNameTable_323:		.incbin "includes/generated/gui_display_struct_data.bin", 0x35E, 0x14
Scoop_ResNameTable_324:		.incbin "includes/generated/gui_display_struct_data.bin", 0x372, 0x14
Scoop_ResNameTable_325:		.incbin "includes/generated/gui_display_struct_data.bin", 0x386, 0x14
Scoop_ResNameTable_326:		.incbin "includes/generated/gui_display_struct_data.bin", 0x39A, 0x14
Scoop_ResNameTable_327:		.incbin "includes/generated/gui_display_struct_data.bin", 0x3AE, 0x14
Scoop_ResNameTable_328:		.incbin "includes/generated/gui_display_struct_data.bin", 0x3C2, 0x14
Scoop_ResNameTable_329:		.incbin "includes/generated/gui_display_struct_data.bin", 0x3D6, 0x14
Scoop_ResNameTable_32A:		.incbin "includes/generated/gui_display_struct_data.bin", 0x3EA, 0x14
Scoop_ResNameTable_32B:		.incbin "includes/generated/gui_display_struct_data.bin", 0x3FE, 0x14
Scoop_ResNameTable_32C:		.incbin "includes/generated/gui_display_struct_data.bin", 0x412, 0x14
Scoop_ResNameTable_32D:		.incbin "includes/generated/gui_display_struct_data.bin", 0x426, 0x14
Scoop_ResNameTable_32E:		.incbin "includes/generated/gui_display_struct_data.bin", 0x43A, 0x14
Scoop_ResNameTable_32F:		.incbin "includes/generated/gui_display_struct_data.bin", 0x44E, 0x14
Scoop_ResNameTable_330:		.incbin "includes/generated/gui_display_struct_data.bin", 0x462, 0x14
Scoop_ResNameTable_331:		.incbin "includes/generated/gui_display_struct_data.bin", 0x476, 0x14
Scoop_ResNameTable_332:		.incbin "includes/generated/gui_display_struct_data.bin", 0x48A, 0x14
Scoop_ResNameTable_333:		.incbin "includes/generated/gui_display_struct_data.bin", 0x49E, 0x14
Scoop_ResNameTable_334:		.incbin "includes/generated/gui_display_struct_data.bin", 0x4B2, 0x14
Scoop_ResNameTable_335:		.incbin "includes/generated/gui_display_struct_data.bin", 0x4C6, 0x14
Scoop_ResNameTable_336:		.incbin "includes/generated/gui_display_struct_data.bin", 0x4DA, 0x14
Scoop_ResNameTable_337:		.incbin "includes/generated/gui_display_struct_data.bin", 0x4EE, 0x14
Scoop_ResNameTable_338:		.incbin "includes/generated/gui_display_struct_data.bin", 0x502, 0x14
Scoop_ResNameTable_339:		.incbin "includes/generated/gui_display_struct_data.bin", 0x516, 0x14
Scoop_ResNameTable_33A:		.incbin "includes/generated/gui_display_struct_data.bin", 0x52A, 0x14
Scoop_ResNameTable_33B:		.incbin "includes/generated/gui_display_struct_data.bin", 0x53E, 0x12
Scoop_ResNameTable_33C:		.incbin "includes/generated/gui_display_struct_data.bin", 0x550, 0x12
Scoop_ResNameTable_33D:		.incbin "includes/generated/gui_display_struct_data.bin", 0x562, 0x12
Scoop_ResNameTable_33E:		.incbin "includes/generated/gui_display_struct_data.bin", 0x574, 0x14
Scoop_ResNameTable_33F:		.incbin "includes/generated/gui_display_struct_data.bin", 0x588, 0x14
; purpose not established.
; tried: `lda`/`ld` of a 24- or 32-bit immediate, and any little-endian 24-bit copy of an address from 0x120 B before this slice to its end, anywhere in the ROM: none found
GUI_DisplayStructData_0x59C:		.incbin "includes/generated/gui_display_struct_data.bin", 0x59C, 0xE
InitializeScoop_Str_TT_SEMENU:		.incbin "includes/generated/gui_display_struct_data.bin", 0x5AA, 0xA	; "TT_SEMENU"
InitializeScoop_Str_TT_SEEASY:		.incbin "includes/generated/gui_display_struct_data.bin", 0x5B4, 0xA	; "TT_SEEASY"
InitializeScoop_Str_TT_SETONTON1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x5BE, 0xE	; "TT_SETONTON1"
InitializeScoop_Str_TT_SETONTON2:	.incbin "includes/generated/gui_display_struct_data.bin", 0x5CC, 0xE	; "TT_SETONTON2"
InitializeScoop_Str_TT_SETONRAN1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x5DA, 0xE	; "TT_SETONRAN1"
InitializeScoop_Str_TT_SETONRAN2:	.incbin "includes/generated/gui_display_struct_data.bin", 0x5E8, 0xE	; "TT_SETONRAN2"
InitializeScoop_Str_TT_SETONHYB1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x5F6, 0xE	; "TT_SETONHYB1"
InitializeScoop_Str_TT_SEPITPIT1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x604, 0xE	; "TT_SEPITPIT1"
InitializeScoop_Str_TT_SEPITENV1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x612, 0xE	; "TT_SEPITENV1"
InitializeScoop_Str_TT_SEPITENV2:	.incbin "includes/generated/gui_display_struct_data.bin", 0x620, 0xE	; "TT_SEPITENV2"
InitializeScoop_Str_TT_SEPITLFO1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x62E, 0xE	; "TT_SEPITLFO1"
InitializeScoop_Str_TT_SEAMPAMP1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x63C, 0xE	; "TT_SEAMPAMP1"
InitializeScoop_Str_TT_SEAMPAMP2:	.incbin "includes/generated/gui_display_struct_data.bin", 0x64A, 0xE	; "TT_SEAMPAMP2"
InitializeScoop_Str_TT_SEAMPENV1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x658, 0xE	; "TT_SEAMPENV1"
InitializeScoop_Str_TT_SEAMPENV2:	.incbin "includes/generated/gui_display_struct_data.bin", 0x666, 0xE	; "TT_SEAMPENV2"
InitializeScoop_Str_TT_SEAMPLFO1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x674, 0xE	; "TT_SEAMPLFO1"
InitializeScoop_Str_TT_SEFILLPQ1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x682, 0xE	; "TT_SEFILLPQ1"
InitializeScoop_Str_TT_SEFILHPQ1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x690, 0xE	; "TT_SEFILHPQ1"
InitializeScoop_Str_TT_SEFILL241:	.incbin "includes/generated/gui_display_struct_data.bin", 0x69E, 0xE	; "TT_SEFILL241"
InitializeScoop_Str_TT_SEFILH241:	.incbin "includes/generated/gui_display_struct_data.bin", 0x6AC, 0xE	; "TT_SEFILH241"
InitializeScoop_Str_TT_SEFILBPF1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x6BA, 0xE	; "TT_SEFILBPF1"
InitializeScoop_Str_TT_SEFILBCF1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x6C8, 0xE	; "TT_SEFILBCF1"
InitializeScoop_Str_TT_SEFILFIL2:	.incbin "includes/generated/gui_display_struct_data.bin", 0x6D6, 0xE	; "TT_SEFILFIL2"
InitializeScoop_Str_TT_SEFILENV1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x6E4, 0xE	; "TT_SEFILENV1"
InitializeScoop_Str_TT_SEFILENV2:	.incbin "includes/generated/gui_display_struct_data.bin", 0x6F2, 0xE	; "TT_SEFILENV2"
InitializeScoop_Str_TT_SEFILLFO1:	.incbin "includes/generated/gui_display_struct_data.bin", 0x700, 0xE	; "TT_SEFILLFO1"
InitializeScoop_Str_TT_SEDIGEFF:	.incbin "includes/generated/gui_display_struct_data.bin", 0x70E, 0xC	; "TT_SEDIGEFF"
InitializeScoop_Str_TT_SECTR2:		.incbin "includes/generated/gui_display_struct_data.bin", 0x71A, 0xA	; "TT_SECTR2"
InitializeScoop_Str_TT_SECTR3:		.incbin "includes/generated/gui_display_struct_data.bin", 0x724, 0xA	; "TT_SECTR3"
InitializeScoop_Str_TT_SECOPY:		.incbin "includes/generated/gui_display_struct_data.bin", 0x72E, 0xA	; "TT_SECOPY"
InitializeScoop_Str_TT_SEWRTMEM:	.incbin "includes/generated/gui_display_struct_data.bin", 0x738, 0xC	; "TT_SEWRTMEM"
InitializeScoop_Str_TT_SEWRTSND:	.incbin "includes/generated/gui_display_struct_data.bin", 0x744, 0xC	; "TT_SEWRTSND"
; parameter block of object 0x146 (class 0x01600003, proc MainFunctionProc), registered by InitializeScoop+0x125
; (+10 data field of a RegisterObjectTable descriptor, registry 0x27ED2 + 14*index); the slice runs to the next boundary, 136 B; the proc's read length was not measured
GUI_DisplayStructData_0x750:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x750, 0x88
; parameter block of object 0x446 (class 0x01600003, proc MainFunctionProc), registered by InitializeScoop+0x14A
; (+10 data field of a RegisterObjectTable descriptor, registry 0x27ED2 + 14*index); the slice runs to the next boundary, 768 B; the proc's read length was not measured
GUI_DisplayStructData_0x7D8:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x7D8, 0x300
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:60 `ld xiy, GUI_DisplayStructData_0xAD8`
GUI_DisplayStructData_0xAD8:
	.incbin "includes/generated/gui_display_struct_data.bin", 0xAD8, 0x10
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:81 `ld xiy, GUI_DisplayStructData_0xAE8`
GUI_DisplayStructData_0xAE8:
	.incbin "includes/generated/gui_display_struct_data.bin", 0xAE8, 0x10
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:102 `ld xiy, GUI_DisplayStructData_0xAF8`
GUI_DisplayStructData_0xAF8:
	.incbin "includes/generated/gui_display_struct_data.bin", 0xAF8, 0x8
; purpose not established.
; tried: `lda`/`ld` of a 24- or 32-bit immediate, and any little-endian 24-bit copy of an address from 0x120 B before this slice to its end, anywhere in the ROM: none found
	.long SeTonTon1TitleFunc_DisplayData+0x8
	.long SeTonTon1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:123 `ld xiy, GUI_DisplayStructData_0xB08`
GUI_DisplayStructData_0xB08:
	.long SeTonTon2TitleFunc_DisplayData
	.long SeTonTon2TitleFunc_DisplayData+0x4
	.long SeTonTon2TitleFunc_DisplayData+0x8
	.long SeTonTon2TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:144 `ld xiy, GUI_DisplayStructData_0xB18`
GUI_DisplayStructData_0xB18:
	.long SeTonRan1TitleFunc_DisplayData
	.long SeTonRan1TitleFunc_DisplayData+0x4
	.long SeTonRan1TitleFunc_DisplayData+0x8
	.long SeTonRan1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:165 `ld xiy, GUI_DisplayStructData_0xB28`
GUI_DisplayStructData_0xB28:
	.long SeTonRan2TitleFunc_DisplayData
	.long SeTonRan2TitleFunc_DisplayData+0x4
	.long SeTonRan2TitleFunc_DisplayData+0x8
	.long SeTonRan2TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:186 `ld xiy, GUI_DisplayStructData_0xB38`
GUI_DisplayStructData_0xB38:
	.long SeTonHyb1TitleFunc_DisplayData
	.long SeTonHyb1TitleFunc_DisplayData+0x4
	.long SeTonHyb1TitleFunc_DisplayData+0x8
	.long SeTonHyb1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:207 `ld xiy, GUI_DisplayStructData_0xB48`
GUI_DisplayStructData_0xB48:
	.long SePitPit1TitleFunc_DisplayData
	.long SePitPit1TitleFunc_DisplayData+0x4
	.long SePitPit1TitleFunc_DisplayData+0x8
	.long SePitPit1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:228 `ld xiy, GUI_DisplayStructData_0xB58`
GUI_DisplayStructData_0xB58:
	.long SePitEnv1TitleFunc_DisplayData
	.long SePitEnv1TitleFunc_DisplayData+0x4
	.long SePitEnv1TitleFunc_DisplayData+0x8
	.long SePitEnv1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:249 `ld xiy, GUI_DisplayStructData_0xB68`
GUI_DisplayStructData_0xB68:
	.long SePitEnv2TitleFunc_DisplayData
	.long SePitEnv2TitleFunc_DisplayData+0x4
	.long SePitEnv2TitleFunc_DisplayData+0x8
	.long SePitEnv2TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:270 `ld xiy, GUI_DisplayStructData_0xB78`
GUI_DisplayStructData_0xB78:
	.long SePitLfo1TitleFunc_DisplayData
	.long SePitLfo1TitleFunc_DisplayData+0x4
	.long SePitLfo1TitleFunc_DisplayData+0x8
	.long SePitLfo1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:291 `ld xiy, GUI_DisplayStructData_0xB88`
GUI_DisplayStructData_0xB88:
	.long SeAmpAmp1TitleFunc_DisplayData
	.long SeAmpAmp1TitleFunc_DisplayData+0x4
	.long SeAmpAmp1TitleFunc_DisplayData+0x8
	.long SeAmpAmp1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:312 `ld xiy, GUI_DisplayStructData_0xB98`
GUI_DisplayStructData_0xB98:
	.long SeAmpAmp2TitleFunc_DisplayData
	.long SeAmpAmp2TitleFunc_DisplayData+0x4
	.long SeAmpAmp2TitleFunc_DisplayData+0x8
	.long SeAmpAmp2TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:333 `ld xiy, GUI_DisplayStructData_0xBA8`
GUI_DisplayStructData_0xBA8:
	.long SeAmpEnv1TitleFunc_DisplayData
	.long SeAmpEnv1TitleFunc_DisplayData+0x4
	.long SeAmpEnv1TitleFunc_DisplayData+0x8
	.long SeAmpEnv1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:354 `ld xiy, GUI_DisplayStructData_0xBB8`
GUI_DisplayStructData_0xBB8:
	.long SeAmpEnv2TitleFunc_DisplayData
	.long SeAmpEnv2TitleFunc_DisplayData+0x4
	.long SeAmpEnv2TitleFunc_DisplayData+0x8
	.long SeAmpEnv2TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:375 `ld xiy, GUI_DisplayStructData_0xBC8`
GUI_DisplayStructData_0xBC8:
	.long SeAmpLfo1TitleFunc_DisplayData
	.long SeAmpLfo1TitleFunc_DisplayData+0x4
	.long SeAmpLfo1TitleFunc_DisplayData+0x8
	.long SeAmpLfo1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:396 `ld xiy, GUI_DisplayStructData_0xBD8`
GUI_DisplayStructData_0xBD8:
	.long SeFilLpq1TitleFunc_DisplayData
	.long SeFilLpq1TitleFunc_DisplayData+0x4
	.long SeFilLpq1TitleFunc_DisplayData+0x8
	.long SeFilLpq1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:417 `ld xiy, GUI_DisplayStructData_0xBE8`
GUI_DisplayStructData_0xBE8:
	.long SeFilHpq1TitleFunc_DisplayData
	.long SeFilHpq1TitleFunc_DisplayData+0x4
	.long SeFilHpq1TitleFunc_DisplayData+0x8
	.long SeFilHpq1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:438 `ld xiy, GUI_DisplayStructData_0xBF8`
GUI_DisplayStructData_0xBF8:
	.long SeFilL241TitleFunc_DisplayData
	.long SeFilL241TitleFunc_DisplayData+0x4
	.long SeFilL241TitleFunc_DisplayData+0x8
	.long SeFilL241TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:459 `ld xiy, GUI_DisplayStructData_0xC08`
GUI_DisplayStructData_0xC08:
	.long SeFilH241TitleFunc_DisplayData
	.long SeFilH241TitleFunc_DisplayData+0x4
	.long SeFilH241TitleFunc_DisplayData+0x8
	.long SeFilH241TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:480 `ld xiy, GUI_DisplayStructData_0xC18`
GUI_DisplayStructData_0xC18:
	.long SeFilBpf1TitleFunc_DisplayData
	.long SeFilBpf1TitleFunc_DisplayData+0x4
	.long SeFilBpf1TitleFunc_DisplayData+0x8
	.long SeFilBpf1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:501 `ld xiy, GUI_DisplayStructData_0xC28`
GUI_DisplayStructData_0xC28:
	.long SeFilBcf1TitleFunc_DisplayData
	.long SeFilBcf1TitleFunc_DisplayData+0x4
	.long SeFilBcf1TitleFunc_DisplayData+0x8
	.long SeFilBcf1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:522 `ld xiy, GUI_DisplayStructData_0xC38`
GUI_DisplayStructData_0xC38:
	.long SeFilFil2TitleFunc_DisplayData
	.long SeFilFil2TitleFunc_DisplayData+0x4
	.long SeFilFil2TitleFunc_DisplayData+0x8
	.long SeFilFil2TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:543 `ld xiy, GUI_DisplayStructData_0xC48`
GUI_DisplayStructData_0xC48:
	.long SeFilEnv1TitleFunc_DisplayData
	.long SeFilEnv1TitleFunc_DisplayData+0x4
	.long SeFilEnv1TitleFunc_DisplayData+0x8
	.long SeFilEnv1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:564 `ld xiy, GUI_DisplayStructData_0xC58`
GUI_DisplayStructData_0xC58:
	.long SeFilEnv2TitleFunc_DisplayData
	.long SeFilEnv2TitleFunc_DisplayData+0x4
	.long SeFilEnv2TitleFunc_DisplayData+0x8
	.long SeFilEnv2TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:585 `ld xiy, GUI_DisplayStructData_0xC68`
GUI_DisplayStructData_0xC68:
	.long SeFilLfo1TitleFunc_DisplayData
	.long SeFilLfo1TitleFunc_DisplayData+0x4
	.long SeFilLfo1TitleFunc_DisplayData+0x8
	.long SeFilLfo1TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:606 `ld xiy, GUI_DisplayStructData_0xC78`
GUI_DisplayStructData_0xC78:
	.long SeDigEffTitleFunc_DisplayData
	.long SeDigEffTitleFunc_DisplayData+0x4
	.long SeDigEffTitleFunc_DisplayData+0x8
	.long SeDigEffTitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:627 `ld xiy, GUI_DisplayStructData_0xC88`
GUI_DisplayStructData_0xC88:
	.long SeCtr2TitleFunc_DisplayData
	.long SeCtr2TitleFunc_DisplayData+0x4
	.long SeCtr2TitleFunc_DisplayData+0x8
	.long SeCtr2TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:648 `ld xiy, GUI_DisplayStructData_0xC98`
GUI_DisplayStructData_0xC98:
	.long SeCtr3TitleFunc_DisplayData
	.long SeCtr3TitleFunc_DisplayData+0x4
	.long SeCtr3TitleFunc_DisplayData+0x8
	.long SeCtr3TitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:669 `ld xiy, GUI_DisplayStructData_0xCA8`
GUI_DisplayStructData_0xCA8:
	.long SeCopyTitleFunc_DisplayData
	.long SeCopyTitleFunc_DisplayData+0x4
	.long SeCopyTitleFunc_DisplayData+0x8
	.long SeCopyTitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:690 `ld xiy, GUI_DisplayStructData_0xCB8`
GUI_DisplayStructData_0xCB8:
	.long SeWrtMemTitleFunc_DisplayData
	.long SeWrtMemTitleFunc_DisplayData+0x4
	.long SeWrtMemTitleFunc_DisplayData+0x8
	.long SeWrtMemTitleFunc_DisplayData+0x12
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/sound_editor_routines.s:711 `ld xiy, GUI_DisplayStructData_0xCC8`
GUI_DisplayStructData_0xCC8:
	.long Scoop_SoundEditorData
	.long Scoop_SoundEditorData+0x4
	.long Scoop_SoundEditorData+0x8
	.long Scoop_SoundEditorData_Skip+0xB
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join56+0x1E (0xF03DA7) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0xCD8:
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0xEB+0x2E
	.long Scoop_SoundEditorData_0xEB+0xDC
	.long Scoop_SoundEditorData_0xEB+0x18F
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0xEB+0x201
	.long Scoop_SoundEditorData_0xEB+0x211
	.long Scoop_SoundEditorData_0xEB+0x221
	.long Scoop_SoundEditorData_0xEB+0x250
	.long Scoop_SoundEditorData_0xEB+0x274
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0xEB+0x2BA
	.long Scoop_SoundEditorData_0xEB+0x298
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join57+0x1E (0xF03DD5) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0xD20:
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0xEB+0x2E9
	.long Scoop_SoundEditorData_0xEB+0x35C
	.long Scoop_SoundEditorData_0xEB+0x3C0
	.long Scoop_SoundEditorData_0xEB+0x434
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0xEB+0x498
	.long Scoop_SoundEditorData_0xEB+0x4A8
	.long Scoop_SoundEditorData_0xEB+0x4C0
	.long Scoop_SoundEditorData_0xEB+0x4DF
	.long Scoop_SoundEditorData_0xEB+0x4F7
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0xEB+0x51D
	.long Scoop_SoundEditorData_0xEB+0x50F
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join58+0x1E (0xF03E03) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0xD68:
	.long Scoop_SoundEditorData_0xEB+0x531
	.long Scoop_SoundEditorData_0xEB+0x5C2
	.long Scoop_SoundEditorData_0xEB+0x662
	.long Scoop_SoundEditorData_0xEB+0x702
	.long Scoop_SoundEditorData_0xEB+0x7A2
	.long Scoop_SoundEditorData_0xEB+0x859
	.long Scoop_SoundEditorData_0xEB+0x910
	.long Scoop_SoundEditorData_0xEB+0x973
	.long Scoop_SoundEditorData_0xEB+0x9E3
	.long Scoop_SoundEditorData_0xEB+0x9EC
	.long Scoop_SoundEditorData_0xEB+0xA0B
	.long Scoop_SoundEditorData_0xEB+0xA3E
	.long Scoop_SoundEditorData_0xEB+0xA6A
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0xEB+0xAF6
	.long Scoop_SoundEditorData_0xEB+0xAD4
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join59+0x1E (0xF03E31) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0xDB0:
	.long Scoop_SoundEditorData_0xEB+0xB25
	.long Scoop_SoundEditorData_0xEB+0xBB9
	.long Scoop_SoundEditorData_0xEB+0xC4D
	.long Scoop_SoundEditorData_0xEB+0xCE1
	.long Scoop_SoundEditorData_0xEB+0xD45
	.long Scoop_SoundEditorData_0xEB+0xDB9
	.long Scoop_SoundEditorData_0xEB+0xE1D
	.long Scoop_SoundEditorData_0xEB+0xE6F
	.long Scoop_SoundEditorData_0xEB+0xEC2
	.long Scoop_SoundEditorData_0xEB+0xECB
	.long Scoop_SoundEditorData_0xEB+0xEEA
	.long Scoop_SoundEditorData_0xEB+0xF09
	.long Scoop_SoundEditorData_0xEB+0xF21
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0xEB+0xF47
	.long Scoop_SoundEditorData_0xEB+0xF39
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_0xEB+0x1E (0xF03E5F) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0xDF8:
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0xEB+0xF5B
	.long Scoop_SoundEditorData_0xEB+0xF63
	.long Scoop_SoundEditorData_0xEB+0xF6B
	.long Scoop_SoundEditorData_0xEB+0xF73
	.long Scoop_SoundEditorData_0xEB+0xF7B
	.long Scoop_SoundEditorData_0xEB+0xF83
	.long Scoop_SoundEditorData_0xEB+0xF8B
	.long Scoop_SoundEditorData_0xEB+0xF93
	.long Scoop_SoundEditorData_0xEB+0xFA3
	.long Scoop_SoundEditorData_0xEB+0xFB8
	.long Scoop_SoundEditorData_0xEB+0xFC5
	.long Scoop_SoundEditorData_0xEB+0xFD2
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0xEB+0xFDF
	.long SeMenu_BitShift_Stub
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join60+0x1E (0xF04E52) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0xE40:
	.long Scoop_SoundEditorData_0x127C+0x2E
	.long Scoop_SoundEditorData_0x127C+0xC7
	.long Scoop_SoundEditorData_0x127C+0x160
	.long Scoop_SoundEditorData_0x127C+0x1F0
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x280
	.long Scoop_SoundEditorData_0x127C+0x307
	.long Scoop_SoundEditorData_0x127C+0x388
	.long Scoop_SoundEditorData_0x127C+0x40A
	.long Scoop_SoundEditorData_0x127C+0x432
	.long Scoop_SoundEditorData_0x127C+0x44A
	.long Scoop_SoundEditorData_0x127C+0x47D
	.long Scoop_SoundEditorData_0x127C+0x4C9
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x517
	.long Scoop_SoundEditorData_0x127C+0x4F5
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join61+0x1E (0xF04E80) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0xE88:
	.long Scoop_SoundEditorData_0x127C+0x546
	.long Scoop_SoundEditorData_0x127C+0x558
	.long Scoop_SoundEditorData_0x127C+0x56A
	.long Scoop_SoundEditorData_0x127C+0x574
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x57E
	.long Scoop_SoundEditorData_0x127C+0x583
	.long Scoop_SoundEditorData_0x127C+0x588
	.long Scoop_SoundEditorData_0x127C+0x58D
	.long Scoop_SoundEditorData_0x127C+0x592
	.long Scoop_SoundEditorData_0x127C+0x597
	.long Scoop_SoundEditorData_0x127C+0x59C
	.long Scoop_SoundEditorData_0x127C+0x5E9
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x610
	.long Scoop_SoundEditorData_0x127C+0x5EE
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join62+0x1E (0xF04EAE) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0xED0:
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x63F
	.long Scoop_SoundEditorData_0x127C+0x651
	.long Scoop_SoundEditorData_0x127C+0x663
	.long Scoop_SoundEditorData_0x127C+0x66D
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x677
	.long Scoop_SoundEditorData_0x127C+0x69F
	.long Scoop_SoundEditorData_0x127C+0x6B7
	.long Scoop_SoundEditorData_0x127C+0x6EA
	.long Scoop_SoundEditorData_0x127C+0x736
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x784
	.long Scoop_SoundEditorData_0x127C+0x762
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join63+0x1E (0xF04EDC) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0xF18:
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x7B3
	.long Scoop_SoundEditorData_0x127C+0x7C5
	.long Scoop_SoundEditorData_0x127C+0x7D7
	.long Scoop_SoundEditorData_0x127C+0x7E1
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x7EB
	.long Scoop_SoundEditorData_0x127C+0x7F0
	.long Scoop_SoundEditorData_0x127C+0x7F5
	.long Scoop_SoundEditorData_0x127C+0x7FA
	.long Scoop_SoundEditorData_0x127C+0x847
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x86E
	.long Scoop_SoundEditorData_0x127C+0x84C
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join64+0x1E (0xF04F0A) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0xF60:
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x89D
	.long Scoop_SoundEditorData_0x127C+0x928
	.long Scoop_SoundEditorData_0x127C+0x936
	.long Scoop_SoundEditorData_0x127C+0x9C5
	.long Scoop_SoundEditorData_0x127C+0xA47
	.long Scoop_SoundEditorData_0x127C+0xA51
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0xA5B
	.long Scoop_SoundEditorData_0x127C+0xA83
	.long Scoop_SoundEditorData_0x127C+0xA9B
	.long Scoop_SoundEditorData_0x127C+0xACE
	.long Scoop_SoundEditorData_0x127C+0xB17
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0xB65
	.long Scoop_SoundEditorData_0x127C+0xB43
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join65+0x1E (0xF04F38) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0xFA8:
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0xB94
	.long Scoop_SoundEditorData_0x127C+0xBBC
	.long Scoop_SoundEditorData_0x127C+0xBD4
	.long Scoop_SoundEditorData_0x127C+0xC07
	.long Scoop_SoundEditorData_0x127C+0xC53
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0xCA1
	.long Scoop_SoundEditorData_0x127C+0xC7F
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join66+0x1E (0xF04F66) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0xFF0:
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0xCD0
	.long Scoop_SoundEditorData_0x127C+0xD43
	.long Scoop_SoundEditorData_0x127C+0xDA7
	.long Scoop_SoundEditorData_0x127C+0xE1B
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0xE7F
	.long Scoop_SoundEditorData_0x127C+0xE8F
	.long Scoop_SoundEditorData_0x127C+0xEA7
	.long Scoop_SoundEditorData_0x127C+0xEC6
	.long Scoop_SoundEditorData_0x127C+0xEDE
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0xF04
	.long Scoop_SoundEditorData_0x127C+0xEF6
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join67+0x1E (0xF04F94) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0x1038:
	.long Scoop_SoundEditorData_0x127C+0xF18
	.long Scoop_SoundEditorData_0x127C+0xF23
	.long Scoop_SoundEditorData_0x127C+0xF2E
	.long Scoop_SoundEditorData_0x127C+0xF3A
	.long Scoop_SoundEditorData_0x127C+0xF45
	.long Scoop_SoundEditorData_0x127C+0xF51
	.long Scoop_SoundEditorData_0x127C+0xF5C
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0xF68
	.long Scoop_SoundEditorData_0x127C+0xF71
	.long Scoop_SoundEditorData_0x127C+0xF90
	.long Scoop_SoundEditorData_0x127C+0xFAF
	.long Scoop_SoundEditorData_0x127C+0xFCD
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0xFF9
	.long Scoop_SoundEditorData_0x127C+0xFEB
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Join68+0x1E (0xF04FC2) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0x1080:
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x100D
	.long Scoop_SoundEditorData_0x127C+0x1016
	.long Scoop_SoundEditorData_0x127C+0x101F
	.long Scoop_SoundEditorData_0x127C+0x1028
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x1031
	.long Scoop_SoundEditorData_0x127C+0x103A
	.long Scoop_SoundEditorData_0x127C+0x1043
	.long Scoop_SoundEditorData_0x127C+0x104C
	.long Scoop_SoundEditorData_0x127C+0x106B
	.long Scoop_SoundEditorData_0x127C+0x108A
	.long Scoop_SoundEditorData_0x127C+0x10A2
	.long SeMenu_BitShift_Stub
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x10C8
	.long Scoop_SoundEditorData_0x127C+0x10BA
	.long 0x00000000
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_0x127C+0x1E (0xF04FF0) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0x10C8:
	.long SeMenu_BitShift_Stub
	.long Scoop_SoundEditorData_0x127C+0x10DC
	.long Scoop_SoundEditorData_0x127C+0x10E4
	.long Scoop_SoundEditorData_0x127C+0x10EC
	.long Scoop_SoundEditorData_0x127C+0x10F4
	.long Scoop_SoundEditorData_0x127C+0x10FC
	.long Scoop_SoundEditorData_0x127C+0x1104
	.long Scoop_SoundEditorData_0x127C+0x110C
	.long Scoop_SoundEditorData_0x127C+0x1114
	.long Scoop_SoundEditorData_0x127C+0x1124
	.long Scoop_SoundEditorData_0x127C+0x1139
	.long Scoop_SoundEditorData_0x127C+0x1146
	.long Scoop_SoundEditorData_0x127C+0x1153
	.long SeMenu_BitShift_Stub
; the rest of the code-pointer table at GUI_DisplayStructData_0x10C8, from entry 14 on;
; the table runs across this boundary (file slice)
GUI_DisplayStructData_0x1100:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x1100, 0x10
; data read by SeMenu_ApplyPartEdit_Helper11+0x23 (0xF08A09)
; evidence: `lda xde, (this)` then `ld E,(XDE+WA) / mul L,0x1c`
GUI_DisplayStructData_0x1110:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x1110, 0xD
; data read by SeMenu_CopyWriteUpdate_Helper7+0x20 (0xF08C8E)
; evidence: `lda xbc, (this)` then `ld WA,(XBC+WA) / ld (XSP),WA`
GUI_DisplayStructData_0x111D:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x111D, 0xC
; data read by SeMenu_CopyWriteUpdate_Step3_Code_3_Helper7+0xB (0xF074B9)
; evidence: `lda xde, (this)` then `ld A,(XDE+WA) / ld (XBC),A`
GUI_DisplayStructData_0x1129:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x1129, 0x61
; data read by SeMenu_CopyWriteUpdate_Step3_Code_3_Helper8+0xC (0xF074D2)
; evidence: `lda xde, (this)` then `ld A,(XDE+WA) / ld (XBC),A`
GUI_DisplayStructData_0x118A:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x118A, 0x82
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/semenu_routines.s:6021 `ld xiy, GUI_DisplayStructData_0x120C`
GUI_DisplayStructData_0x120C:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x120C, 0x3
; object named by 1 line(s) of code outside this file; what that code does with it:
; evidence: audio/semenu_routines.s:6026 `ld xiy, GUI_DisplayStructData_0x120F`
GUI_DisplayStructData_0x120F:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x120F, 0x13
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_RefreshPartDisplay_Join5+0x1E (0xF09AC4) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0x1222:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x1222, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_RefreshPartDisplay_Join6+0x1E (0xF09AF2) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0x126A:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x126A, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_RefreshPartDisplay_Join7+0x1E (0xF09B20) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0x12B2:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x12B2, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_RefreshPartDisplay_Join8+0x1E (0xF09B4E) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0x12FA:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x12FA, 0x48
; data read by SeMenu_RefreshPartDisplay_Join8+0x19C (0xF09CCC)
; evidence: `lda xde, (this)` then `ld A,(XDE+WA) / ld (XBC),A`
GUI_DisplayStructData_0x1342:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x1342, 0x20
; data read by SeMenu_RefreshPartDisplay_Join8+0x1D4 (0xF09D04)
; evidence: `lda xbc, (this)` then `ld C,(XBC+WA) / ld (XSP+0x0e),C`
GUI_DisplayStructData_0x1362:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x1362, 0xD
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_CopyWriteUpdate_Step3_Join33+0x1E (0xF0BD23) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0x136F:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x136F, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_CopyWriteUpdate_Step3_Join34+0x1E (0xF0BD51) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0x13B7:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x13B7, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_CopyWriteUpdate_Step3_Join35+0x66 (0xF0BF82) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
GUI_DisplayStructData_0x13FF:
	.incbin "includes/generated/gui_display_struct_data.bin", 0x13FF, 0x2A
; the rest of the code-pointer table at GUI_DisplayStructData_0x13FF, from entry 10 byte 2 on;
; the table runs across this boundary (label of the next source)
ToneGen_ParamTable:
	.incbin "includes/generated/tonegen_param_table.bin", 0x0, 0x1E
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_CopyWriteUpdate_Step3_Join36+0x1E (0xF0C6CD) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
ToneGen_ParamTable_0x1E:
	.incbin "includes/generated/tonegen_param_table.bin", 0x1E, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_CopyWriteUpdate_Step3_Join37+0x1E (0xF0C6FB) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
ToneGen_ParamTable_0x66:
	.incbin "includes/generated/tonegen_param_table.bin", 0x66, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_CopyWriteUpdate_Step3_Join38+0x1E (0xF0C729) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
ToneGen_ParamTable_0xAE:
	.incbin "includes/generated/tonegen_param_table.bin", 0xAE, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_CopyWriteUpdate_Step3_Join39+0x1E (0xF0C757) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
ToneGen_ParamTable_0xF6:
	.incbin "includes/generated/tonegen_param_table.bin", 0xF6, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_CopyWriteUpdate_Step3_Join40+0x1E (0xF0C785) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
ToneGen_ParamTable_0x13E:
	.incbin "includes/generated/tonegen_param_table.bin", 0x13E, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_CopyWriteUpdate_Step3_Join41+0x1E (0xF0D704) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
ToneGen_ParamTable_0x186:
	.incbin "includes/generated/tonegen_param_table.bin", 0x186, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_CopyWriteUpdate_Step3_Join43+0x1E (0xF0D760) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
ToneGen_ParamTable_0x1CE:
	.incbin "includes/generated/tonegen_param_table.bin", 0x1CE, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: Scoop_SoundEditorData_Helper+0x1E (0xF0D78E) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
ToneGen_ParamTable_0x216:
	.incbin "includes/generated/tonegen_param_table.bin", 0x216, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_CopyWriteUpdate_Step3_Join44+0x38 (0xF0D7D6) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
ToneGen_ParamTable_0x25E:
	.incbin "includes/generated/tonegen_param_table.bin", 0x25E, 0x48
; table of 4-byte code pointers, 72 B = 18 entries to the next address the code names
; evidence: SeMenu_CopyWriteUpdate_Step3_Join42+0x1E (0xF0D732) loads it into XDE, adds BC*4 and calls the entry (`exts xbc / add xbc,xde / ld xhl,(xbc) / call (xhl)`)
ToneGen_ParamTable_0x2A6:
	.incbin "includes/generated/tonegen_param_table.bin", 0x2A6, 0x48
; data read by SeMenu_CopyWriteUpdate_Step3_Join44+0x4AF (0xF0DC4D)
; evidence: `lda xix, (this)` then `ld WA,(XIX+WA) / lda XIX,0xf0dc61`
ToneGen_ParamTable_0x2EE:
	.incbin "includes/generated/tonegen_param_table.bin", 0x2EE, 0x18
; data read by SeMenu_CopyWriteUpdate_Step3_Join44+0x55A (0xF0DCF8)
; evidence: `lda xix, (this)` then `ld WA,(XIX+WA) / lda XIX,0xf0dd0c`
ToneGen_ParamTable_0x306:
	.incbin "includes/generated/tonegen_param_table.bin", 0x306, 0x14
; data read by SeMenu_CopyWriteUpdate_Step3_Join44+0x5EB (0xF0DD89)
; evidence: `lda xix, (this)` then `ld WA,(XIX+WA) / lda XIX,0xf0dd9d`
ToneGen_ParamTable_0x31A:
	.incbin "includes/generated/tonegen_param_table.bin", 0x31A, 0xC
; data read by SeMenu_PopupDialog_Close_Data+0x1D (0xF0E9E4)
; evidence: `lda xbc, (this)` then `ld XHL,(XBC+WA) / call T,XHL`
; data read by SeMenu_ListSelector_HandleInput+0x1A (0xF0EB24)
; evidence: `lda xbc, (this)` then `ld XHL,(XBC+WA) / call T,XHL`
ToneGen_ParamTable_0x326:
	.incbin "includes/generated/tonegen_param_table.bin", 0x326, 0x81
; parameter block of object 0x12b (class 0x01600002, proc ApFunctionProc), registered by InitializeNaka+0x91
; (+10 data field of a RegisterObjectTable descriptor, registry 0x27ED2 + 14*index); the slice runs to the next boundary, 76 B; the proc's read length was not measured
ToneGen_ParamTable_0x3A7:
	.incbin "includes/generated/tonegen_param_table.bin", 0x3A7, 0x4C
; parameter block of object 0x42b (class 0x01600002, proc ApFunctionProc), registered by InitializeNaka+0xB6
; (+10 data field of a RegisterObjectTable descriptor, registry 0x27ED2 + 14*index); the slice runs to the next boundary, 330 B; the proc's read length was not measured
ToneGen_ParamTable_0x3F3:
	.incbin "includes/generated/tonegen_param_table.bin", 0x3F3, 0x14A
; parameter block of object 0x16b (class 0x01600004, proc ClassProc), registered by InitializeNaka+0x1C
; (+10 data field of a RegisterObjectTable descriptor, registry 0x27ED2 + 14*index); the slice runs to the next boundary, 26 B; the proc's read length was not measured
ToneGen_ParamTable_0x53D:
	.incbin "includes/generated/tonegen_param_table.bin", 0x53D, 0x18
Naka_ClassCount_16B:	.incbin "includes/generated/tonegen_param_table.bin", 0x555, 0x2
; parameter block of object 0x1cb (class 0x0160000C, proc ResEventProc), registered by InitializeNaka+0x44
; (+10 data field of a RegisterObjectTable descriptor, registry 0x27ED2 + 14*index); the slice runs to the next boundary, 6 B; the proc's read length was not measured
ToneGen_ParamTable_0x557:
	.incbin "includes/generated/tonegen_param_table.bin", 0x557, 0x4
InitializeNaka_Data_2:	.incbin "includes/generated/tonegen_param_table.bin", 0x55B, 0x2
; parameter block of object 0x1eb (class 0x0160000D, proc ResMethodProc), registered by InitializeNaka+0x6C
; (+10 data field of a RegisterObjectTable descriptor, registry 0x27ED2 + 14*index); the slice runs to the next boundary, 6 B; the proc's read length was not measured
ToneGen_ParamTable_0x55D:
	.incbin "includes/generated/tonegen_param_table.bin", 0x55D, 0x4
InitializeNaka_Data_3:	.incbin "includes/generated/tonegen_param_table.bin", 0x561, 0x2
; parameter block of object 0x10b (class 0x01600001, proc FunctionProc), registered by InitializeNaka+0xDB
; (+10 data field of a RegisterObjectTable descriptor, registry 0x27ED2 + 14*index); the slice runs to the next boundary, 4 B; the proc's read length was not measured
ToneGen_ParamTable_0x563:
	.incbin "includes/generated/tonegen_param_table.bin", 0x563, 0x4
; parameter block of object 0x40b (class 0x01600001, proc FunctionProc), registered by InitializeNaka+0x100
; (+10 data field of a RegisterObjectTable descriptor, registry 0x27ED2 + 14*index); the slice runs to the next boundary, 6 B; the proc's read length was not measured
ToneGen_ParamTable_0x567:
	.incbin "includes/generated/tonegen_param_table.bin", 0x567, 0x6

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
	ld (0xd2:8), 0x29:io
	ld (0xd1:8), 0x00:io
	and_sd8b_im 0xd3, 0xcf
	and_sd8b_im 0xd3, 0xf0

Boot_InitIOPorts:
	ld (304:16), 255
	ld (305:16), 255
	ld (306:16), 3
	ld (0x3a:8), 0x20:io
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
	ld xwa, 0:i3
	ld (SYSTEM_TIMESTAMP:16), xwa
	ld (1024:16), 2
	call TaskSched_Init
	ld (1024:16), 3
Boot_InitPeripherals:
	calr Boot_ClearConfigFlag7
	lda_dd8l XBC, (0xe4)
	ld a, (xbc)
	and a, 0x8f
	or a, 0x30
	ld (xbc), a
	lda_dd8l XBC, (0xe6)
	ld a, (xbc)
	and a, 0xf8
	or a, 0x3
	ld (xbc), a
	calr Detect_Region_Code
	cpw (65482:24), 23205
	jr z, Boot_FlashAndExtensions
	lda xde, (0x00066e:24)
	srl xde, 1
	ld xwa, 0xf980
	ld xbc, 0x1e8000
	call Copy_DE_words_from_XBC_to_XWA

Boot_FlashAndExtensions:
	call Flash_InitAllBanks
	bit_dd8 0, 0x38	;  Is the optional HD-AE5000 board present?
	jr nz, BootInit_SeqAndPanel
	calr Get_Region_Code
	cp l, 4:i3
	call nz, (HDAE5000_Parport_Setup:24)	; if it is present (and this unit was sold in
					; a specific market region), then call the
					; HDAE5000 PPI init code

; Boot initialization handler (SeqInit + CPanel scan)
BootInit_SeqAndPanel:
	call Seq_FullInit
	ei 0
	ld xhl, (CPanel_InitDispatchTable:24)
	call (xhl)
	call CPanel_ScanButtons
	ld (1026:16), l
	call Get_Firmware_Version
	cp l, 0xff
	jr nz, User_didnt_request_flash_mem_update
	call Check_for_Floppy_Disk_Change
	cp hl, 0:i3
	jr z, User_didnt_request_flash_mem_update
	cp (1026:16), 4
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
	ld	a, (1026:16)
	extz	wa
	calr	Boot_HandleFactoryReset
	ldw	(65482:24), 0
	set_dd8	0, 40
	call	SubCPU_Init_DMA_Channels
	ei	0
	calr	SubCPU_Send_Payload
	calr	SubCPU_Payload_Verify
	ld	wa, 0:i3
	call	ScreenGroup_Dispatch
	ei	0
	call	SelfTest_FirmwareVersionCheck
	calr	SubCPU_Payload_GetErrorFlag
	cp	hl, 0:i3
	jr	nz, Boot_PayloadError
	ld	wa, 1:i3
	jr	Boot_DisplayScreen
Boot_PayloadError:
	ld wa, 2:i3	; Error: use screen group 2

Boot_DisplayScreen:
	call	ScreenGroup_Dispatch
	ld	(1024:16), 6
	ld	wa, 3:i3
	call	ScreenGroup_Dispatch
	ld	(1024:16), 128
	ldw	(65492:24), 0
	ld	a, (1026:16)
	extz	wa
	calr	Boot_HandleComboDisplay
	ld	wa, 4:i3
	call	Show_ScreenGroup
	calr	Boot_SetConfigFlag7
	jp	MainLoop
Boot_GetButtonComboCode:
	ld l, (1026:16)
	ret

Boot_ClearAllInterruptEnables:
	ld (0xf0:8), 0x00:io
	ld (0xe0:8), 0x00:io
	ld (0xe1:8), 0x00:io
	ld (0xe2:8), 0x00:io
	ld (0xe3:8), 0x00:io
	ld (0xe4:8), 0x00:io
	ld (0xe5:8), 0x00:io
	ld (0xe6:8), 0x00:io
	ld (0xe7:8), 0x00:io
	ld (0xe8:8), 0x00:io
	ld (0xe9:8), 0x00:io
	ld (0xea:8), 0x00:io
	ld (0xeb:8), 0x00:io
	ld (0xec:8), 0x00:io
	ld (0xed:8), 0x00:io
	ld (0xee:8), 0x00:io
	ld (0xef:8), 0x00:io
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
	cp (SubCPU_Send_Payload_Data:24), 0xff
	jrl nz, SubCPU_Payload_Done
	ld xiz, 0:i3

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
	cp (SubCPU_Payload_DelayLoop_Short_Data:24), 0xff
	jr nz, SubCPU_Payload_TransferPart2
	ld xiz, 0x50000
	ld xwa, 0x3e0000
	ld xbc, 0x50000
	call SLIDE_Parse_Header
	cp hl, 0xffff
	jr nz, SubCPU_Payload_TransferPart2
	ld xiz, 0x800000

SubCPU_Payload_TransferPart2:
	ldw	(0x0404:16), (xiz+256)
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
	ld xiz, 0:i3

SubCPU_Payload_DelayLoop_Long:
	inc 1, xiz
	cp xiz, 0x100000
	jr c, SubCPU_Payload_DelayLoop_Long

SubCPU_Payload_Done:
	pop xiz
	ret

Boot_ClearConfigFlag7:
	res 7, (1030:16)
	ret

Boot_SetConfigFlag7:
	set 7, (1030:16)
	ret

Boot_CheckConfigFlag7:
	ldcf_dd16 7, 0x06, 0x04
	scc8 c, a
	cp a, 1:i3
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
	cp a, 2:i3
	jr nz, Boot_HandleComboDisplay_Check3
	; --- Combo 2: Firmware version on LEDs ---
	call Get_Firmware_Version	; Returns version byte in L (0x0a = v10)
	and l, 0xf
	extz hl
	lda xbc, (LED_patterns_indicating_firmware_version:24); LED_patterns_indicating_firmware_version table
	ld	c, (xbc+hl)	; Read LED pattern from table
	extz bc
	ld wa, 7:i3
	call Set_LEDs			; Display version on control panel LEDs
	push xiz
	call CPanel_Poll		; Poll control panel (keep LEDs updated)
	pop xiz
	ret

Boot_HandleComboDisplay_Check3:
	cp a, 3:i3
	ret nz
	; --- Combo 3: Software version screen ---
	ldw wa, 0xf0
	call SoundCtrl_SendCommand		; Display SOFT VERSION screen
	ret

Boot_ParseTableDataTimestamp:
	ld	xwa, 10485700
	push	xwa
	call	ParseInt16
	inc	4, xsp
	ret
Boot_GetSystemPointer:
	ld hl, (1028:16)
	ret

Boot_ParseSubCPUTimestamp:
	ld	xwa, 8912885
	push	xwa
	call	ParseInt16
	inc	4, xsp
	ret
Boot_HandleFactoryReset:
	cpw (65482:24), 23205; DRAM[0xFFCA] == 0x5aa5 (valid checksums)?
	ret z			; Yes -> checksums valid, skip reset
	cp a, 1:i3		; Combo code == 1 (Initial Setting)?
	ret nz			; No -> not requesting reset, return
	; --- Factory Reset: clear all DRAM and SRAM ---
	call ToneGen_FlashReadAndRestore
	ei 7
	calr Boot_ClearAllInterruptEnables	; Clear all interrupt enables
	ld xbc, 0x400

FactoryReset_ClearDRAM:
	ld xwa, 0:i3
	ld (xbc+), XWA
	cp xbc, 0x100000
	jr c, FactoryReset_ClearDRAM
	ld xbc, 0x1e0000

FactoryReset_ClearSRAM:
	ld xwa, 0:i3
	ld (xbc+), XWA
	cp xbc, 0x200000
	jr c, FactoryReset_ClearSRAM
	ldw (0x00ffca:24), 0x5aa5
	jp Boot_InitIOPorts
FactoryReset_TrailingByte:
	ret

Boot_ReadFDCStatus:
	; Disassembled from the committed romslice (no source of any kind existed):
	; llvm-mc round-trips these 5 B byte-exact; v9/v10's Boot_ReadFDCStatus is the
	; identical two instructions, "ldb_d8 l,(0x8e6a) / ret", with only the FDC
	; status register address shifted (36302 here vs v9/v10's 36458).
	ld	l, (36302:16)
	ret
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
	lda xix, (RESOURCE_INFO_HANDLER_OFFSETS:24)
	ld	wa, (xix+wa)
	lda xix, (RESOURCE_INFO_HANDLERS:24)
	jp	t, (xix+wa)
; Resource info handlers - 10 handlers for different resource types
RESOURCE_INFO_HANDLERS:
	lda xwa, (63872:16)
	ld (xbc), xwa
	lda xwa, (65470:16)
	ld xde, xwa
	inc 2, xde
	lda xwa, (63872:16)
	sub xde, xwa
	ld (xbc + 4), xde
	ret

ResInfo_GetSRAMBankRange:
	lda xwa, (0x1e7800:24)
	ld (xbc), xwa
	lda xwa, (0x1e7800:24)
	ld xde, xwa
	lda xwa, (0x1e8000:24)
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetUserAreaRange:
	lda xwa, (0x1ed350:24)
	ld (xbc), xwa
	lda xwa, (0x1ed350:24)
	ld xde, xwa
	lda xwa, (0x200000:24)
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetFlashBankRange:
	lda xwa, (0x1e0000:24)
	ld (xbc), xwa
	lda xwa, (0x1e0000:24)
	ld xde, xwa
	lda xwa, (0x1e7800:24)
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
	lda xwa, (0x0ab000:24)
	ld (xbc), xwa
	ld xwa, 0x5000
	ld (xbc + 4), xwa
	ret

ResInfo_GetVoiceBankRange:
	lda xwa, (0x0b0000:24)
	ld (xbc), xwa
	lda xwa, (0x0b0000:24)
	ld xde, xwa
	lda xwa, (0x0fd800:24)
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetToneGenRange:
	lda xwa, (RHYTHM_PATTERN_BUF_A:24)
	ld (xbc), xwa
	lda xwa, (RHYTHM_PATTERN_BUF_A:24)
	ld xde, xwa
	lda xwa, (0x0ab000:24)
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetMspSettingsRange:
	lda xwa, (0x1e8800:24)
	ld (xbc), xwa
	lda xwa, (0x1e8800:24)
	ld xde, xwa
	lda xwa, (0x1ec400:24)
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetResourceListPtr:
	lda xwa, (ResInfo_GetResourceListPtr_Str_TEST:24)
	ld (xbc), xwa
	ld xwa, 0:i3
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
	ld xiy, SetSepaOutMode_Data
	lda xix, (xsp + 12)
	ldiw
	ldiw
	ld xiy, SetSepaOutMode_Data_2
	lda xix, (xsp + 8)
	ldiw
	ldiw
	ld xiy, SetSepaOutMode_Data_3
	lda xix, (xsp + 4)
	ldiw
	ldiw
	ld xiy, SetSepaOutMode_Data_4
	ld xix, xsp
	ldiw
	ldiw
	cp wa, 3:i3
	jrl z, SetSepaOut_Mode3
	cp wa, 2:i3
	jrl z, SetSepaOut_Mode2
	cp wa, 1:i3
	jr z, SetSepaOut_Mode1
	cp wa, 0:i3
	jrl nz, FileIO_SendCommand_Return
	ld (xsp + 17), 0x14
	lda xwa, (xsp + 16)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 9), 0x14
	lda xwa, (xsp + 8)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 17), 0x13
	lda xwa, (xsp + 16)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 9), 0x13
	lda xwa, (xsp + 8)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 17), 0x16
	lda xwa, (xsp + 16)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 9), 0x16
	lda xwa, (xsp + 8)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	jrl FileIO_SendCommand_Return

SetSepaOut_Mode1:
	ld (xsp + 13), 0x14
	lda xwa, (xsp + 12)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 9), 0x14
	lda xwa, (xsp + 8)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 17), 0x13
	lda xwa, (xsp + 16)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 9), 0x13
	lda xwa, (xsp + 8)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 17), 0x16
	lda xwa, (xsp + 16)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 9), 0x16
	lda xwa, (xsp + 8)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	jrl FileIO_SendCommand_Return

SetSepaOut_Mode2:
	ld (xsp + 13), 0x14
	lda xwa, (xsp + 12)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 9), 0x14
	lda xwa, (xsp + 8)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 13), 0x13
	lda xwa, (xsp + 12)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 9), 0x13
	lda xwa, (xsp + 8)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 13), 0x16
	lda xwa, (xsp + 12)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 9), 0x16
	lda xwa, (xsp + 8)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	jr FileIO_SendCommand_Return

SetSepaOut_Mode3:
	ld (xsp + 13), 0x14
	lda xwa, (xsp + 12)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 1), 0x14
	lda xwa, (xsp)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 13), 0x13
	lda xwa, (xsp + 12)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 5), 0x13
	lda xwa, (xsp + 4)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 13), 0x16
	lda xwa, (xsp + 12)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	ld (xsp + 5), 0x16
	lda xwa, (xsp + 4)
	ld xde, xwa
	ld wa, 0:i3
	ld bc, 4:i3
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
	dec	2, xsp
	ld	(xsp), a
	call	SeqBuf_Init
	call	NoteMap_SendAllNotesOff
	call	Part_ReinitAllActive
	call	AccWrap_PlayModeDispatch
	cp	(xsp), 0x0
	jr	z, PlayHalt_SkipSetFlag
	set	2, (10407:16)
PlayHalt_SkipSetFlag:
	call	AccompSeq_StopSequence
	call	AudioInit_RefreshToneBank
	call	NoteMap_ProcessAndMerge
	call	Voice_InitializeAll
	call	Voice_InitTablePair
	call	Voice_InitTableGroup
	call	MIDI_SendAllSoundOff
	call	MidiThru_Enable
	inc	2, xsp
	ret
PlayStandBy:
	bit 2, (10407:16)
	jr z, PlayStandBy_SkipClearFlag
	res 2, (10407:16)

PlayStandBy_SkipClearFlag:
	res	3, (10407:16)
	call	SeqAcc_InitPlaybackState
	jp	MidiThru_Disable
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
	jp	MIDI_SC0_TX_DISPATCH
GetAdr_sqbtof:
	lda xhl, (SEQ_BEAT_COUNT:16)
	ret

GetAdr_sq_beadt:
	lda xhl, (SEQ_BEAT_TICK:16)
	ret

GetAdr_sqsrtc:
	lda xhl, (SEQ_TRANSPORT_STATE:16)
	ret

GetAdr_rtmcfg:
	lda xhl, (10407:16)
	ret

SetGlobalError:
	ld	(GLOBAL_ERROR_CODE:16), a
	ret
malloc_X:
	pushw	wa
	call	Malloc
	inc	2, xsp
	ret
free_X:
	; Disassembled from the committed romslice (no source of any kind existed):
	; llvm-mc round-trips these 8 B byte-exact; v9/v10's free_X is the identical
	; four instructions ("push xwa / call Free / inc 4,xsp / ret"), and its own
	; neighbour malloc_X (immediately above) already carries a numeric call
	; target in this exact style, so the convention is not new here.
	push	xwa
	call	Free
	inc	4, xsp
	ret
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
SeqVoice_StoreEntryDone_Helper:
	push	xiz
	call	Voice_RefreshBankData
	pop	xiz
	ret
SeqChan_UnhandledCmd_Helper:
	push	xiz
	call	Voice_InitBankTables
	pop	xiz
	ret

Voice_InitBankTables:
	ld xiy, Voice_BankHeaderDefaults
	ld xix, 0x1e8800
	ldw bc, 0x10
	ldirw
	ld a, 0xc:opc

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
	ld a, 0x39:opc

Voice_InitBankTables_SlotLoop:
; (was .incbin "includes/romslices/v7_fix_voice_initbanktables_slotloop.bin")
	.byte	0x45, 0x45, 0xed, 0xf6, 0x00, 0x31, 0x80, 0x00
	.byte	0x95, 0x11, 0xc9, 0x69, 0x6e, 0xf2, 0xf1, 0x7c
	.byte	0x7d, 0x02, 0x39, 0x00
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
	ld XIY,0x001e8800
	ld (XIY),0x48
	ld (XIY+0x01),0x00
	ld (XIY+0x02),0x4b
	ret

Voice_RefreshBankData:
	calr Voice_ComputeAllocSize
	ret

Voice_ResetToFactoryBanks:
	ldw	wa, 10
	ld	xhl, 31312
	ldw	bc, 255
	ldw	de, 246
	calr	Voice_SetBankParams
	ld	xhl, 31568
	calr	Voice_SetBankParams
	calr	Voice_ReinitIfBankCountNonzero
	calr	Voice_ReinitIfBitFlagSet
	calr	CountAvailableVoiceSlots
	ret
Voice_SetBankParams:
	ld (xhl + 0:8), wa
	ld (xhl + 2), bc
	ld (xhl + 4), wa
	ld (xhl + 6), wa
	ld (xhl + 8), de
	ret

Voice_ReinitIfBankCountNonzero:
	ld xiy, 0x1e8800
	add xiy, 0xe
	ld wa, (xiy)
	cp wa, 0:i3
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
	ld	(32124:16), wa
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
	ld c, 0x39:opc

Voice_AllocSize_Loop:
	cp c, 0:i3
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
	jr	z, Voice_FactoryPresetData_Code_Skip
	resm	6, (xde)
	jr	Voice_FactoryPresetData_Code_Join
Voice_FactoryPresetData_Code_Skip:
	setm	6, (xde)
Voice_FactoryPresetData_Code_Join:
	incm8	1, (xsp+24)
Voice_FactoryPresetData_Code_Join6:
	ld	xwa, (xsp+12)
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	sra	xwa, 16
	ld	(xbc), wa
	ld	xwa, (xsp+16)
	add	(xbc+2), wa
	ld	xwa, 1:i3
	add	(xsp+20), xwa
	ld	xwa, (xsp+20)
	cp	xwa, (xsp+8)
	jrl	le, DrawDottedLineWithMode_Impl_Loop3
	jrl	Voice_FactoryPresetData_Code_Join4
Voice_FactoryPresetData_Code_Skip15:
	ld	xwa, (xsp+8)
	sla	xwa, 16
	ld	xbc, (xsp+4)
; call Math_DivideSigned32 (v7)
	call	Math_DivideSigned32
	ld	xiz, xhl
	ld	xwa, (xsp+16)
	ld	xbc, xiz
; call Math_MultiplyAccumulate (v7)
	call	Math_MultiplyAccumulate
	ld	(xsp+16), xhl
	ld	xbc, (xsp+34)
	ld	xwa, xbc
	inc	2, xwa
	ld	(xsp+34), xwa
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+8), xwa
	sla	xwa, 16
	ld	(xsp+8), xwa
	ld	xwa, 32768
	add	(xsp+8), xwa
	ld	xwa, 0:i3
	ld	(xsp+20), xwa
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, Voice_FactoryPresetData_Code_Join4
Voice_FactoryPresetData_Code_Loop:
	cp	(xsp+24), 3
	jr	ule, Voice_FactoryPresetData_Code_Skip2
	ld	(xsp+24), 0
	jrl	Voice_FactoryPresetData_Code_Join3
Voice_FactoryPresetData_Code_Skip2:
	cp	(xsp+24), 1
	jrl	ugt, Voice_FactoryPresetData_Code_Join2
	ld	l, (COLORBLIT_MODE_ACTIVE:24)
	ld	xwa, (xsp+34)
	ld	wa, (xwa)
	exts	xwa
	ld	xde, xwa
SubCPU_ToneDispatch_Target13:
	sll	xde, 2
	add	xde, xwa
	sll	xde, 6
	cp	l, 2:i3
	jrl	z, Voice_FactoryPresetData_Code_Skip7
	cp	l, 1:i3
	jr	z, Voice_FactoryPresetData_Code_Skip5
	cp	l, 0:i3
	jrl	nz, Voice_FactoryPresetData_Code_Join2
	ld	xhl, xbc
	ld	iy, (xsp+50)
	ld	wa, (xbc)
	exts	xwa
	add	xwa, xde
	lda	xix, (OFFSCREEN_BUFFER_1:24)
	add	xix, xwa
	cpw	(xsp+50), 245
	jr	z, Voice_FactoryPresetData_Code_Skip3
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
	jr	nz, Voice_FactoryPresetData_Code_Skip4
	jr	Voice_FactoryPresetData_Code_Join2
Voice_FactoryPresetData_Code_Skip3:
	ld	xiy, (197714:24)
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
	jr	z, Voice_FactoryPresetData_Code_Join2
Voice_FactoryPresetData_Code_Skip4:
	xormi8	(xix), 96
	jr	Voice_FactoryPresetData_Code_Join2
Voice_FactoryPresetData_Code_Skip5:
	ld	wa, (xbc)
	exts	xwa
	add	xwa, xde
	lda	xde, (OFFSCREEN_BUFFER_1:24)
	add	xde, xwa
	bitm	7, (xde)
	jr	z, Voice_FactoryPresetData_Code_Skip6
	resm	5, (xde)
	jr	Voice_FactoryPresetData_Code_Join2
Voice_FactoryPresetData_Code_Skip6:
	setm	5, (xde)
	jr	Voice_FactoryPresetData_Code_Join2
Voice_FactoryPresetData_Code_Skip7:
	ld	wa, (xbc)
	exts	xwa
	add	xwa, xde
	lda	xde, (OFFSCREEN_BUFFER_1:24)
	add	xde, xwa
	bitm	7, (xde)
	jr	z, Voice_FactoryPresetData_Code_Skip8
	resm	6, (xde)
	jr	Voice_FactoryPresetData_Code_Join2
Voice_FactoryPresetData_Code_Skip8:
	setm	6, (xde)
Voice_FactoryPresetData_Code_Join2:
	incm8	1, (xsp+24)
Voice_FactoryPresetData_Code_Join3:
	ld	xwa, (xsp+16)
	add	(xsp+8), xwa
	ld	xde, (xsp+8)
	sra	xde, 16
	ld	xwa, (xsp+34)
	ld	(xwa), de
	ld	xwa, (xsp+12)
	add	(xbc), wa
	ld	xwa, 1:i3
	add	(xsp+20), xwa
	ld	xwa, (xsp+20)
	cp	xwa, (xsp+4)
	jrl	le, Voice_FactoryPresetData_Code_Loop
Voice_FactoryPresetData_Code_Join4:
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
	calr	SetChangeRect
Voice_FactoryPresetData_Code_Epilogue2:
	pop	xiz
	lda	xsp, (xsp+56)
	ret
DrawText_LayoutAndRender_Variant1_Helper:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), bc
	ld	xiz, xwa
	calr	IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp	hl, 0:i3
	jr	z, Voice_FactoryPresetData_Code_Skip9
	ld	a, (COLORBLIT_MODE:24)
	ld	(COLORBLIT_MODE_ACTIVE:24), a
	cpw	(197710:24), 0
	jr	z, Voice_FactoryPresetData_Code_Epilogue
	ld	xwa, xiz
	ld	bc, (xsp+4)
	calr	Voice_FactoryPresetData_Code_Helper
	jr	Voice_FactoryPresetData_Code_Epilogue
Voice_FactoryPresetData_Code_Skip9:
	ldw	wa, 16
	calr	DrawQueue_Alloc
	ld	xwa, xhl
	lda	xbc, (Voice_FactoryPresetData_Code:24)
	ld	(xwa), xbc
	ld	xiy, xiz
	lda	xix, (xwa+4)
	ld	bc, 4:i3
	ldirw
	ld	bc, (xsp+4)
	ld	(xwa+12), bc
	ld	c, (COLORBLIT_MODE:24)
	ld	(xwa+14), c
	calr	DrawRing_Post
Voice_FactoryPresetData_Code_Epilogue:
	pop	xiz
	inc	2, xsp
	ret
Voice_FactoryPresetData_Code:
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	ld	de, (xbc+12)
	ld	c, (xbc+14)
	ld	(COLORBLIT_MODE_ACTIVE:24), c
	cpw	(197710:24), 0
	ret	z
	ld	bc, de
	calr	Voice_FactoryPresetData_Code_Helper
	ret
Voice_FactoryPresetData_Code_Helper:
	lda	xsp, (xsp-18)
	pushw	iz
	ld	(xsp+14), bc
	ld	(xsp+16), xwa
	ld	xwa, (xsp+16)
	inc	2, xwa
	ld	(xsp+2), xwa
	cpw	(xwa), 0
	jr	ge, Voice_FactoryPresetData_Code_Skip10
	ld	xwa, (xsp+2)
	ldw	(xwa), 0
Voice_FactoryPresetData_Code_Skip10:
	ld	xwa, (xsp+16)
	cpw	(xwa), 0
	jr	ge, Voice_FactoryPresetData_Code_Skip11
	ldw	(xwa), 0
Voice_FactoryPresetData_Code_Skip11:
	ld	xwa, (xsp+16)
	lda	xhl, (xwa+4)
	cpw	(xhl), 320
	jr	lt, Voice_FactoryPresetData_Code_Skip12
	ldw	(xhl), 319
Voice_FactoryPresetData_Code_Skip12:
	ld	xwa, (xsp+16)
	lda	xix, (xwa+6)
	cpw	(xix), 240
	jr	lt, Voice_FactoryPresetData_Code_Skip13
	ldw	(xix), 239
Voice_FactoryPresetData_Code_Skip13:
	ld	de, (xix)
	ld	xwa, (xsp+2)
	ld	iz, (xwa)
	lda	xwa, (xsp+10)
	lda	xbc, (xsp+6)
	lda	xiy, (xbc+2)
	ld	(xwa+2), iz
	cp	de, iz
	jr	nz, Voice_FactoryPresetData_Code_Skip14
	ld	xde, (xsp+16)
	ld	de, (xde)
	ld	(xwa), de
	ld	de, (xhl)
	ld	(xbc), de
	ld	de, (xix)
	ld	(xiy), de
	ld	de, (xsp+14)
	jr	Voice_FactoryPresetData_Code_Join5
Voice_FactoryPresetData_Code_Skip14:
	ld	xde, (xsp+16)
	ld	de, (xde)
	ld	(xwa), de
	ld	de, (xhl)
	ld	(xbc), de
	ld	xde, (xsp+2)
	ld	de, (xde)
	ld	(xiy), de
	ld	de, (xsp+14)
	calr	DrawLineWithMode_Impl
	lda	xwa, (xsp+10)
	ld	xbc, (xsp+16)
	lda	xde, (xbc+6)
	ld	bc, (xde)
	ld	(xwa+2), bc
	lda	xbc, (xsp+6)
	ld	de, (xde)
	ld	(xbc+2), de
	ld	de, (xsp+14)
	calr	DrawLineWithMode_Impl
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
	calr	DrawLineWithMode_Impl
	lda	xwa, (xsp+10)
	ld	xbc, (xsp+16)
	lda	xde, (xbc+4)
	ld	bc, (xde)
	ld	(xwa), bc
	lda	xbc, (xsp+6)
	ld	de, (xde)
	ld	(xbc), de
	ld	de, (xsp+14)
Voice_FactoryPresetData_Code_Join5:
	calr	DrawLineWithMode_Impl
	ld	xwa, (xsp+16)
	calr	SetChangeRect
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
	cp hl, 0:i3
	jr z, DrawText_QueueDeferred
	ld a, (COLORBLIT_MODE:24)
	ld (COLORBLIT_MODE_ACTIVE:24), a
	cpw (197710:24), 0
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
	ld	xwa, (xsp + 8)
	push	xwa
	call	Strlen
	inc	4, xsp
	inc	1, hl
	ld	wa, hl
	calr	DrawQueue_Alloc
	ld	(xsp + 4), xhl
	ldw	wa, 0x1e
	calr	DrawQueue_Alloc
	ld	xiz, xhl
	lda	xwa, (DrawText_PopAndReturn_Code:24)
	ld	(xhl), xwa
	ld	xwa, (xsp + 16)
	ld	xiy, xwa
	lda	xix, (xhl + 4)
	ld	bc, 4:i3
	ldirw
	ld	xwa, (xsp + 12)
	ld	xiy, xwa
	lda	xix, (xhl + 12)
	ldiw
	ldiw
	ld	xbc, (xsp + 4)
	ld	(xhl + 16), xbc
	ld	xwa, (xsp + 8)
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	xwa, (xsp + 28)
	ld	(xiz + 20), xwa
	ld	wa, (xsp + 26)
	ld	(xiz + 24), wa
	ld	wa, (xsp + 24)
	ld	(xiz + 26), wa
	ld	a, (COLORBLIT_MODE:24)
	ld	(xiz + 28), a
	ld	xwa, xiz
	calr	DrawRing_Post
DrawText_PopAndReturn:
	pop xiz
	lda xsp, (xsp + 16)
	retd 0x8
DrawText_PopAndReturn_Code:
	push xiz
	ld xiz, xwa
	lda xhl, (xiz + 4)
	lda xbc, (xiz + 12)
	ld xiy, (xiz + 20)
	ld ix, (xiz + 24)
	ld de, (xiz + 26)
	ld a, (xiz + 28)
	ld (COLORBLIT_MODE_ACTIVE:24), a
	cpw (197710:24), 0
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
	lda xsp, (xsp-314)
	push xiz
	ld	(xsp+310), xde
	ld	(xsp+314), xwa
	ld XWA, (xsp + 0x0136)
	cp (xwa), 0x0
	jrl z, TextRender_PopAndReturn
	ld XWA, (xsp + 0x013a)
	inc 2, xwa
	ld (xsp + 34), xwa
	cpw (xwa), 0x0
	jr ge, TextRender_ClampYOrigin
	ld xwa, (xsp + 34)
	ldw (xwa), 0x0

TextRender_ClampYOrigin:
	ld XWA, (xsp + 0x013a)
	cpw (xwa), 0x0
	jr ge, TextRender_ClampXOrigin
	ldw (xwa), 0x0

TextRender_ClampXOrigin:
	ld XWA, (xsp + 0x013a)
	inc 4, xwa
	cpw (xwa), 0x140
	jr lt, TextRender_ClampXRight
	ldw (xwa), 0x13f

TextRender_ClampXRight:
	ld XWA, (xsp + 0x013a)
	lda xde, (xwa + 6)
	cpw (xde), 0xf0
	jr lt, TextRender_SetupColorAndFont
	ldw (xde), 0xef

TextRender_SetupColorAndFont:
	ld xiy, xbc
	lda xix, (xsp+298)
	ldiw
	ldiw
	ld XIX, (xsp + 0x0146)
	or xix, xix
	jr nz, TextRender_ClampNullXStart
	decw	2, (xsp+300)

TextRender_ClampNullXStart:
	lda xhl, (xsp+298)
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
	lda xiz, (xsp+302)
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
	ld	xwa, (xsp+310)
	push	xwa
	lda	xwa, (xsp+42)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xwa, (xsp+38)
	ld	(xsp+30), xwa
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+12)
	or	xwa, xwa
	jr	nz, TextRender_ProcessStringLoop
	ld	xwa, (xsp+30)
	push	xwa
	call	Strlen
	inc	4, xsp
	ld	wa, (xsp+20)
	mul	xwa, hl
	jr	TextRender_AddToDrawPos
TextRender_ProcessStringLoop:
	ld xwa, (xsp + 30)
	cp (xwa), 0x0
	jr z, TextRender_MaxWidthReached

TextRender_CharWidthAccum:
	ld xwa, (xsp + 30)
	ld C, (xwa+)
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
	add	(xsp+306), wa
	lda xwa, (xsp+302)
	lda xde, (xwa + 2)
	ld XBC, (xsp + 0x013a)
	ld bc, (xbc + 2)
	cp (xde), bc
	jr ge, TextRender_ClampGlyphTop
	ld (xde), bc

TextRender_ClampGlyphTop:
	ld de, (xwa)
	ld XBC, (xsp + 0x013a)
	cp de, (xbc)
	jr ge, TextRender_ClampGlyphLeft
	ld bc, (xbc)
	ld (xwa), bc

TextRender_ClampGlyphLeft:
	lda xde, (xwa + 4)
	ld XBC, (xsp + 0x013a)
	ld bc, (xbc + 4)
	cp (xde), bc
	jr le, TextRender_ClampGlyphRight
	ld (xde), bc

TextRender_ClampGlyphRight:
	lda xde, (xwa + 6)
	ld XBC, (xsp + 0x013a)
	ld bc, (xbc + 6)
	cp (xde), bc
	jr le, TextRender_ClampGlyphBottom
	ld (xde), bc

TextRender_ClampGlyphBottom:
	ld	bc, (xsp+322)
	cp bc, 0xf7
	call nz, (ColorBlit2_Impl:24)
	lda xwa, (xsp + 38)
	ld (xsp + 30), xwa
	cp (xwa), 0x0
	jrl z, TextRender_Finalize

TextRender_CharEncodeAndDraw:
	ld xhl, (xsp + 30)
	ld c, (xhl)
	extz bc
	lda xde, (TextRender_CharEncodeAndDraw_Data:24)
	ld	c, (xde+bc)
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
	mul xwa, bc
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
	ld a, (COLORBLIT_MODE_ACTIVE:24)
	cp a, 2:i3
	jrl z, TextRender_XorMode_Init
	cp a, 1:i3
	jrl z, TextRender_BitMask5_Init
	cp a, 0:i3
	jrl nz, TextRender_AdvanceToNextLine
	ldw (xsp + 28), 0x0
	jrl TextRender_BitMask4_CheckColumnEnd

TextRender_BitMask4_DrawPixel:
	ld xwa, (xsp + 16)
	cp (xwa), 0x0
	jrl z, TextRender_BitMask5_ProcessCharacter
	lda xbc, (xsp+294)
	lda xwa, (xsp+298)
	ld (xsp + 34), xwa
	ld hl, (xwa + 2)
	add hl, (xsp + 28)
	ld de, hl
	ld (xbc + 2), hl
	ld XWA, (xsp + 0x013a)
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
	lda xix, (OFFSCREEN_BUFFER_1:24)
	add xix, xwa
	ld hl, 0:i3
	cpw (xsp + 24), 0x0
	jr ule, TextRender_BitMask5_ProcessCharacter

TextRender_BitMask4_PixelLoop:
	ld xwa, (xsp + 34)
	ld de, (xwa)
	add de, hl
	ld (xbc), de
	ld XWA, (xsp + 0x013a)
	cp de, (xwa)
	jr lt, TextRender_BitMask4_Return
	ld de, (xbc)
	cp de, (xwa + 4)
	jr gt, TextRender_BitMask5_ProcessCharacter
	ld wa, 7:i3
	sub wa, hl
	ld iy, 1:i3
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
	ld	de, (xsp+324)
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
	ld xwa, 1:i3
	add (xsp + 16), xwa
	incw 1, (xsp + 28)

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
	lda xix, (xsp+294)
	lda xde, (xsp+298)
	ld hl, (xde + 2)
	add hl, (xsp + 28)
	ld bc, hl
	ld (xix + 2), hl
	ld XWA, (xsp + 0x013a)
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
	lda xiz, (OFFSCREEN_BUFFER_1:24)
	add xiz, xwa
	ld hl, 0:i3
	cpw (xsp + 24), 0x0
	jr ule, TextRender_BitMask5_AdvancePointer

TextRender_BitMask5_PixelLoop:
	ld bc, (xde)
	add bc, hl
	ld (xix), bc
	ld XIY, (xsp + 0x013a)
	cp bc, (xiy)
	jr lt, TextRender_BitMask5_Return
	ld wa, (xix)
	cp wa, (xiy + 4)
	jr gt, TextRender_BitMask5_AdvancePointer
	ld wa, 7:i3
	sub wa, hl
	ld iy, 1:i3
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
	ld xwa, 1:i3
	add (xsp + 16), xwa
	incw 1, (xsp + 28)

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
	lda xix, (xsp+294)
	lda xde, (xsp+298)
	ld hl, (xde + 2)
	add hl, (xsp + 28)
	ld bc, hl
	ld (xix + 2), hl
	ld XWA, (xsp + 0x013a)
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
	ld XWA, (xsp + 0x0104)
	ld xbc, EVT_PARA_DRAW
	call SendEvent

UI_EventHandler_InitReturnZero:
	ld xhl, 0:i3

UI_EventHandler_PopAndReturn:
	pop xiz
	lda xsp, (xsp+260)
	ret

ChordProc_TrailingData:
	ld	xhl, NAKA_FUNC_AcTransposeBoxProc
	ret
AcChordBoxProc_Entry:

AcChordBoxProc:
	lda xsp, (xsp-260)
	push xiz
	ld xiz, xde
	ld	(xsp+260), xwa
	cp xbc, EVT_CHORD_DSP
	jr z, AcChordBox_HandleChordUpdate
	cp xbc, EVT_SHOW
	jr z, AcChordBox_HandleInitOrSelect
	cp xbc, EVT_CHORD_SHOW
	jr z, AcChordBox_HandleInitOrSelect
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jr AcChordBox_PopAndReturn

AcChordBox_HandleInitOrSelect:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, NAKA_MAINFUNC_MainChordPre
	ld xbc, EVT_CHORD_PRE
	ld xde, 0:i3
	call MainFuncCall
	jr AcChordBox_ReturnZero

AcChordBox_HandleChordUpdate:
	ld	xwa, (xsp+260)
	ld	xde, xiz
	call	InheritedProc
	push	xiz
	pushw	AcChordBox_HandleChordUpdate_Str_Fmts@hi16
	pushw	AcChordBox_HandleChordUpdate_Str_Fmts@lo16
	lda	xwa, (xsp+12)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	ld	xwa, 192
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	nz, AcChordBox_ReturnZero
	lda	xde, (xsp+4)
	ld	xwa, (xsp+260)
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
AcChordBox_ReturnZero:
	ld xhl, 0:i3

AcChordBox_PopAndReturn:
	pop xiz
	lda xsp, (xsp+260)
	ret

MainChordPre:
	push	xiz
	cp	xbc, EVT_CHORD_PRE
	jrl	nz, MainChordPre_ReturnZero
	pushw	0x15
	call	Malloc
	ld	xiz, xhl
	ld	(xiz), 0x0
	ld	a, (0x8ca4:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (Naka_MemoryC_Screens:24)
	ld	xwa, (xbc+wa)
	push	xwa
	push	xiz
	call	Strcat
	ld	a, (0x8ca6:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (MainChordPre_PtrTable:24)
	ld	xwa, (xbc+wa)
	push	xwa
	push	xiz
	call	Strcat
	lda	xsp, (xsp + 18)
	cp	(0x8ca8:16), 0
	jr	z, MainChordPre_EmptyChordStr
	bit	1, (0xce42:16)
	jr	z, MainChordPre_EmptyChordStr
	ld	xwa, ChordStr_On
	jr	MainChordPre_AppendChordSuffix
MainChordPre_EmptyChordStr:
	ld xwa, ChordStr_Blank

MainChordPre_AppendChordSuffix:
	push	xwa
	push	xiz
	call	Strcat
	ld	a, (36006:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (258808:24)
	ld	xbc, (xbc+wa)
	ld	a, (36004:16)
	extz	wa
	sla	wa, 2
	ld	xbc, (xbc+wa)
	ld	a, (36008:16)
	extz	wa
	sla	wa, 2
	ld	xbc, (xbc+wa)
	push	xbc
	push	xiz
	call	Strcat
	lda	xsp, (xsp+16)
	ld	xwa, 4294967295
	ld	xbc, EVT_CHORD_DSP
	ld	xde, xiz
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_AUTO_FREE
	ld	xde, xiz
	call	ApPostEvent
MainChordPre_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	ret

MainChordPre_ReturnDefaultResult:
	ld xhl, NAKA_FUNC_AcChordBoxProc
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
	ld a, (CPANEL_TX_RX_FLAGS:16)
	and A,0xc0
	jr z, CPanel_RX_SkipToProcess
	ld XHL,CPANEL_RX_EVENT_QUEUE
	ldw	(xhl - 4), 0x0
	ldw	(xhl - 8), 0x0
	ldw	(xhl - 2), 0x80
	ei	6
	ldw	(CPANEL_RX_READ_PTR:16), 0
	ldw	(CPANEL_RX_WRITE_PTR:16), 0
	or	(CPANEL_PROTOCOL_FLAGS:16), 1	; [v10] CP_Flags_B.0 = 1
	ei	0
	jr	CPanel_RX_Return
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
	; Disassembled from the committed romslice (no source of any kind existed):
	; a single 0x0e byte. v9/v10's EmptyRoutine_03 is the same single `ret`,
	; matching the name; round-trips byte-exact.
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
; v7 note (2026-09-25): the routine described above is NOT here in v7.  v7's
; SoundParam_NotifyChange is 0xFCCA30 (54 `call`s in the v7 ROM), inside the
; bytes of audio/audio_control_engine.s; this spot, 0xFCCE4A, had no caller and
; holds the code v10 carries at 0xFCD61B, inside SndParam_ResolveWidget
; (audio/sndparam_routines.s), 0x7D1 bytes on.  The label that stood here was
; dropped for that reason; the 85-byte romslice below was ported from v10 by
; scripts/lanes/sys/port_islands.py.  Its branch targets are v10's
; SndParam_RW_ChainCheckFirst / _FoundCallback / _ChainContinue / _ProcessResult,
; and here they carry those names.  (Until 2026-10-03 they had a _v7 suffix,
; because audio/sndparam_routines.s also defined the plain names 0x41A higher;
; notes/v7-port-sndser-2026-10-03/ removed that drift.)
; (was .incbin "includes/romslices/v7_block_soundparam_notifychange.bin")
	.byte	0x00, 0x00
	and	xwa, xix
	and	xwa, 0xff
	jr	z, SndParam_RW_ChainCheckFirst
EmptyRoutine_03_Skip:
	ld	hl, 0:i3
	jr	SndParam_RW_FoundCallback
SndParam_RW_ChainCheckFirst:
	cp	hl, 0xffff
	jr	z, SndParam_RW_ChainContinue
SndParam_RW_FoundCallback:
	ld	xwa, (xde + 4)
	jr	SndParam_RW_ProcessResult
SndParam_RW_ChainContinue:
	ld	xwa, (xde + 8)
	or	xwa, xwa
	jr	nz, DkMdlyPly_CheckState_Helper_Loop
EmptyRoutine_03_Skip2:
	ld	xwa, 0:i3
SndParam_RW_ProcessResult:
	ld	xiz, xwa
	or	xwa, xwa
	jr	z, SndParam_ProbeMatchFound_Join_Skip
	ld	xwa, (xsp + 18)
	ld	xbc, (xiz)
	ld	(xwa), xbc
	ld	xwa, (xsp + 22)
	cp	(xwa), 0xb1
	jr	z, SndParam_ProbeMatchFound_Skip
	ld	a, (xiz + 15)
	inc	3, a
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_EncodeHandlers:24)
	lda	xde, (xbc+wa)
	ld	xwa, xiz
	ld	bc, (xsp + 4)
	ld	xix, (xde)
	.byte	0xb4
	.include "audio/sndparam_routines.s"

; MIDI Serial Communication routines (SC0)
	.include "midi/midi_serial_routines.s"
	.include "midi/midi_dispatch_handlers.s"
	.include "audio/dsp_config_sysex.s"
	.include "audio/note_voice_mapping.s"

Debug_PrintHexByte:
	push	xiz
	calr	Debug_UartDelay
	pop	xiz
	ret
	push	xiz
	ld	w, a
	srl	a, 4
	calr	Debug_UartHelpers
	pushw	wa
	calr	Debug_UartDelay
	popw	wa
	ld	a, w
	and	a, 15
	calr	Debug_UartHelpers
	calr	Debug_UartDelay
	pop	xiz
	ret

Debug_PrintString:
	push xiz
	ld xix, xwa

Debug_PrintString_Loop:
	ld A, (xix+)
	cp a, 0:i3
	jr z, Debug_PrintString_Done
	push xix
	calr Debug_UartDelay
	pop xix
	jr Debug_PrintString_Loop

Debug_PrintString_Done:
	pop xiz
	ret

Debug_UartHelpers:
	cp	a, 10
	jr	nc, 4
	add	a, 48
	ret
	add A,0x57
	ret

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
Debug_SWI_JumpTable_Code:
	jp	HDAE5000_Init_DetectAndVerify
	jp	Boot_InitIOPorts
	jp	BOOT_ENTRY_POINT
	ret

Get_Firmware_Version:
	ld l, (FIRMWARE_VERSION:24)
	ret

ROM_PaddingFF:
	.byte	0xff, 0xff
SubCPU_Payload_DelayLoop_Short_Data:	.byte	0xff
Boot_CallInitHandlers_Data:	.byte	0x00
SubCPU_Send_Payload_Data:	.byte	0xff

	.include "boot/rom_end_structure.s"

; v7-specific internal labels for UIStateEvt
	.set AudioInit_ClearPartFlags_ByMode, UIStateEvt_TransposeUpdate + 3475

	.set AudioInit_ChannelLoop_Body, UIStateEvt_TransposeUpdate + 3679
	.set UIStateEvt_ParamEdit_Data, UIStateEvt_TransposeUpdate + 94
	.set UIStateEvt_VolumeMixer_Data, UIStateEvt_TransposeUpdate + 714
	.set UIStateEvt_EffectSelect_Data, UIStateEvt_TransposeUpdate + 1075
	.set UIStateEvt_PlayModeGuard_Data, UIStateEvt_TransposeUpdate + 1387
	.set UIStateEvt_ChannelConfig_Data, UIStateEvt_TransposeUpdate + 1441
	.set UIStateEvt_StubReturn, UIStateEvt_TransposeUpdate + 1847
	.set UIStateEvt_MuteToggle_Data, UIStateEvt_TransposeUpdate + 1849
	.set AudioInit_ConfigStereoVoice, UIStateEvt_TransposeUpdate + 1892
	.set AudioInit_ConfigureVoiceFromFlags, UIStateEvt_TransposeUpdate + 2107
	.set AudioInit_SelectVoiceByType, UIStateEvt_TransposeUpdate + 2181
	.set AudioInit_PushAndConfigVoice, UIStateEvt_TransposeUpdate + 2272
	.set AudioInit_PushAndConfigVoiceAlt, UIStateEvt_TransposeUpdate + 2272
	.set AudioInit_CheckSoundGroup, UIStateEvt_TransposeUpdate + 2344
	.set AudioInit_CheckSoundGroup51, UIStateEvt_TransposeUpdate + 2487
	.set AudioInit_MixFallbackDefault, UIStateEvt_TransposeUpdate + 2613
	.set AudioInit_CheckMixMode, UIStateEvt_TransposeUpdate + 2623
	.set AudioInit_DrumSaveReturn, UIStateEvt_TransposeUpdate + 2709
	.set AudioInit_VoiceParamCtrl, UIStateEvt_TransposeUpdate + 2738
	.set AudioInit_DrumRoutingCheck, UIStateEvt_TransposeUpdate + 2872
	.set Audio_CheckInitStatus, UIStateEvt_TransposeUpdate + 3598

; v7-specific internal labels for .incbin-replaced blocks
	.set SeqPlay_ConfigureVoiceChannels, SeqPlay_VoiceChannelCfg + 11
	.set SeqPlay_ProcessChannelsAndDrum, SeqPlay_VoiceChannelCfg + 167
	.set Part_SendVoiceOff_AllParts, SeqTimerFlags_CheckSysFlag + 22
	.set SeqChLoad_ReadEventLoop, SeqChLoad_SetupAndCopy + 38
	.set SeqLoad_InitPartPanPresets, SeqLoad_ProcessEpilogue + 4
	.set MidiStream_HandlePartSelect, MidiStream_CmdPedalDone + 1
	.set MidiStream_ExtendedDispatch, MidiStream_CmdPedalDone + 84
	.set BitMapOut_Snapshot_SetFlags, BitMapOut_Snapshot_Execute + 141

; Labels emitted as .set (exact addresses from ORG/name)






	.set NakaStr_DataFile1of2, FILETYPE_SIG_TABLE_1 + 19


	.set NakaStr_DataFilePck, FILETYPE_SIG_TABLE_PCK + 19


	.set NakaData_FileScreenDispatch, Bitmap_1bit_Flash_Memory_Update + 372














































































































































































































































































































































































































































































	.set EffSeqScreen_ChordTypePtr_A, ChordTypeStr_Blank_1 + 2

	.set EffSeqScreen_ChordTypePtr_B, ChordTypeStr_Type55 + 2


	.set NakaStr_CtrlParam9e9, ChordTypeStr_Flat13_Only + 1














































































































	.set SubCPU_ToneDispatch_0x54, 0xefdb6a


















	.set DrumDetailEdit_Entry_01, SeScreenData_0x5400

	.set DrumDetailEdit_Entry_02, SeScreenData_0x5422

	.set DrumDetailEdit_Entry_03, SeScreenData_0x5444

	.set DrumDetailEdit_Entry_04, SeScreenData_0x5450

	.set DrumDetailEdit_Entry_05, SeScreenData_0x545D

	.set DrumDetailEdit_Entry_06, SeScreenData_0x546A

	.set DrumDetailEdit_Entry_07, SeScreenData_0x548C

	.set DrumDetailEdit_Entry_08, SeScreenData_0x5498

	.set DrumDetailEdit_Entry_09, SeScreenData_0x54A5

	.set Data_Dispatch_Entry, SeScreenData_0x54B2



	.set EffectParamEdit_Entry_01, SeScreenData_0x5895

	.set EffectParamEdit_Entry_02, SeScreenData_0x58A0

	.set EffectParamEdit_Entry_03, SeScreenData_0x58AF

	.set EffectParamEdit_Entry_04, SeScreenData_0x58BA

	.set EffectParamEdit_Entry_05, SeScreenData_0x58C5

	.set EffectParamEdit_Entry_06, SeScreenData_0x58D0

	.set EffectParamEdit_Entry_07, SeScreenData_0x58DB

	.set EffectParamEdit_Entry_08, SeScreenData_0x58E6










































	.set NakaData_RomEnd, 0xffffff
