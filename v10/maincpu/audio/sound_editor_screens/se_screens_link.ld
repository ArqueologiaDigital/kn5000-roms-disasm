/* se_screens_link.ld — Shared linker script for Sound Editor screen data files
 *
 * Provides absolute symbol addresses for extern references in SE screen C files.
 * These addresses point to data tables embedded in sound_editor_ui.s.
 *
 * Address categories:
 *   0x00F1XXXX  — ROM data tables (strings, cursor coordinates)
 *   0x0002XXXX  — DRAM parameter block addresses (runtime data)
 *   0x03XXXXXX  — Flagged DRAM addresses (high byte = 0x03 mode flag)
 *   0x08XXXXXX  — Table Data ROM references (high byte = 0x08 bank)
 */

ENTRY(0)

SECTIONS {
    .text : { *(.text*) }
    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}

/* ═══ ROM String Tables (sound_editor_ui.s data) ═══════════════════════ */

/* General Edit screen value name tables */
SE_MonoPoly_Names          = 0x00F12AED;  /* "LOW HIGHMONOPOLY" */
SE_Transpose_Values        = 0x00F12DDA;  /* "-6-3 0+3+6+9-12..." signed offsets */
SE_Detune_Values           = 0x00F12DF8;  /* " -- -6 -5 -4..." signed offsets */
SE_Frequency_Values        = 0x00F13CF2;  /* " 65.4 69.3 73.4..." Hz values */

/* Drum Kit display channel labels */
SE_DrumChannel_Labels      = 0x00F12CCF;  /* "A:B:C:D:E:F:G:H:..." */

/* Name Editor / Tuning System name tables */
SE_TuningSystem_Names      = 0x00F132BF;  /* "OFF     PURE MAJPURE MIN..." */
SE_NoteDivision_Names      = 0x00F133BF;  /* "NORM 1/2 1/4 1/8..." */

/* Parameter Grid control/trigger mode names */
SE_ParamGrid_ControlNames  = 0x00F14658;  /* "CTRL  R  KEY ON KEY OFF..." */
SE_ParamGrid_TriggerNames  = 0x00F14661;  /* "KEY ON KEY OFFLEGATO..." */

/* Transport display parameter names */
SE_Transport_SwitchNames   = 0x00F14A86;  /* "OFF ON---INV---..." */
SE_Transport_ParamNames    = 0x00F14A92;  /* "---...PITCH BEND   AMP EN..." */

/* Setup Sel3 option names */
SE_SetupSel3_HoldNames     = 0x00F14E46;  /* "LONGHOLDDISABLEENABLE" */
SE_SetupSel3_EnableNames   = 0x00F14E4E;  /* "DISABLEENABLE" */

/* ═══ ROM Cursor Coordinate Tables ═════════════════════════════════════ */

SE_CompareScreen_CursorCoords   = 0x00F1305E;
SE_NameEditor_CursorCoords_0    = 0x00F133DF;
SE_NameEditor_CursorCoords_1    = 0x00F13407;
SE_ParamGrid_CursorCoords       = 0x00F1468E;
SE_Transport_CursorCoords       = 0x00F14DF0;
SE_ApplyConfirm_CursorCoords    = 0x00F163FF;

/* ═══ DRAM Parameter Block Addresses ═══════════════════════════════════ */
/* Runtime data — 4 rows spaced 0x500 apart in DRAM */

/* Drum Kit display DRAM slots (16-byte spacing) */
SE_DrumKit_ParamAddr_0     = 0x00020BF3;
SE_DrumKit_ParamAddr_1     = 0x00020C03;
SE_DrumKit_ParamAddr_2     = 0x00020C13;
SE_DrumKit_ParamAddr_3     = 0x00020C23;

/* Name Editor DRAM parameter pairs (A/B per row) */
SE_NameEdit_ParamAddr_R1A  = 0x00020D4E;
SE_NameEdit_ParamAddr_R1B  = 0x00020D53;
SE_NameEdit_ParamAddr_R2A  = 0x0002124E;
SE_NameEdit_ParamAddr_R2B  = 0x00021253;
SE_NameEdit_ParamAddr_R3A  = 0x0002174E;
SE_NameEdit_ParamAddr_R3B  = 0x00021753;
SE_NameEdit_ParamAddr_R4A  = 0x00021C4E;
SE_NameEdit_ParamAddr_R4B  = 0x00021C53;

/* Apply Confirm DRAM addresses (1 per row, 2 rows) */
SE_ApplyConfirm_ParamAddr_R1  = 0x00020D50;
SE_ApplyConfirm_ParamAddr_R2  = 0x00021250;

/* Compare Screen DRAM addresses (1 per row, 4 rows) */
SE_Compare_ParamAddr_R1    = 0x00020D57;
SE_Compare_ParamAddr_R2    = 0x00021257;
SE_Compare_ParamAddr_R3    = 0x0002177F;
SE_Compare_ParamAddr_R4    = 0x00021C7F;

/* ═══ Flagged Addresses (0x03 high byte = alternate mode) ══════════════ */

SE_GeneralEdit_FlaggedAddr     = 0x03012298;

SE_ApplyConfirm_FlaggedAddr_R1 = 0x03020D55;
SE_ApplyConfirm_FlaggedAddr_R2 = 0x03021255;

SE_Compare_FlaggedAddr_R1      = 0x03020D5D;
SE_Compare_FlaggedAddr_R2      = 0x0302125D;
SE_Compare_FlaggedAddr_R3      = 0x03021785;
SE_Compare_FlaggedAddr_R4      = 0x03021C85;

/* ═══ Table Data ROM References (0x08 high byte = table ROM bank) ══════ */

SE_NameEdit_TableData_0    = 0x08011122;
SE_NameEdit_TableData_1    = 0x08011762;
SE_NameEdit_TableData_2    = 0x08011DA2;
