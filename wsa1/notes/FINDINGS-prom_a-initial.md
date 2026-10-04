# INITIAL: the factory-reset menu and its SysEx twin (2026-10-04)

The SYSTEM menu's INITIAL item resets one section of the instrument to its factory settings. The
same seven resets can also be requested over System Exclusive. Both paths are traced here, and both
dispatch to the same seven reset routines.

## 1. The screen: seven items, one table

Screen 0x6A, `Screen_Initial_*`, draws `DL_InitialSystemResetTheTotalOrIndividualSections`. Its text
records are, in order:

    INITIAL / SYSTEM / "Reset the total or individual sections" / "to the original factory settings" /
    "except SOUND and COMBINATION area." / OK /
    TOTAL / PART SETTING / SYSTEM / MIDI SETTING / RE-MAP / DRUMS MAP / SEQUENCER

The seven item names are values 0..6 of `Initial_SelectedItem` (RAM 0x26F2):

- The screen's enter path zeroes it (0xFA136E).
- Two key handlers step it (0xFA150D, 0xFA1570).
- `Initial_ExecuteSelected` (0xFA1445) bounds it with `cp BC,6 / jr UGT` and jumps through
  `Initial_ItemTable` (0xFA146F, 7 entries).

`LcdKeyRow3_Initial` is the OK / YES key. At `UI_ScreenStage` 0 it calls `Initial_AskConfirmation`,
which moves to stage 1, the "Using Initial Setting will replace any current data ..." page. At stage 1
it calls `Initial_ExecuteSelected`.

| item | text | `Initial_ItemTable` arm | what the arm calls |
|---|---|---|---|
| 0 | TOTAL | `Initial_Total` | `T_ModuleInit_Phase2Veneer`, `T_F40A00`, `T_F43450`, then `sub_FA0DCC` |
| 1 | PART SETTING | `Initial_PartSetting` | `T_PartSettings_ResetToDefault` |
| 2 | SYSTEM | `Initial_System` | `T_Mode_SwitchToSound`, `T_SystemSettings_ResetToDefault`, `sub_FA0DCC` |
| 3 | MIDI SETTING | `Initial_MidiSetting` | `T_MidiSettings_ResetToDefault` |
| 4 | RE-MAP | `Initial_ReMap` | `T_SoundRemap_ResetToDefault`, `T_CombiRemap_ResetToDefault` |
| 5 | DRUMS MAP | `Initial_DrumsMap` | `T_DrumMap_ResetToDefault` |
| 6 | SEQUENCER | `Initial_Sequencer` | `T_Sequencer_ResetToDefault` |

All seven then show status 0x23 and request screen 0xAB at stage 2.

## 2. The evidence that item k IS the reset k calls

Items 4 and 5 call routines that already carried their names, `*Remap_ResetToDefault` and
`DrumMap_ResetToDefault`, so the item order and the table order agree there. The names
`PartSettings_ / SystemSettings_ / MidiSettings_ / Sequencer_ResetToDefault` (prom_a 0xFAAE2A,
0xFAAF91, 0xFAA967 and prom_b 0xF455A0) rest on that agreement plus each body:

- 0xFAAE2A loops over the parameter records from number 0x20, the PART records
  (`ParamNumber_GetRecordPtr`).
- 0xF455A0 resets the block store and posts tempo 120. It writes 120 to (0x7EE2) and queues it as
  parameter 0x7A, the default the SysEx tempo receiver and the sequencer clock also use
  (sysex-probes `25` = TEMPO).

⚠ Not established: what `T_F43450` (prom_a 0xFAABB3) and `sub_FA0DCC` add for TOTAL and SYSTEM.

## 3. The SysEx twin: parameter 08 00, INITIAL

The Technics Reference Guide names SysEx parameter address 08 00 "INITIAL" and marks it
receive-only (`sysex-probes/param_names.json`).

- Its descriptor's setter (+0x14) is `SysExParam_SetInitial` (0xFB3E5A). It reads the value, refuses
  7 and above, shows status 0x25, runs `T_F409AC`, and jumps through `SysExInitial_ItemTable`
  (prom_b 0xF4FB1C, 7 entries).
- Its reader (+0x18) is `SysExParam_ReceiveOnly`, a bare `ret`.

| value | arm | calls |
|---|---|---|
| 0 | `SysExInitial_Total` | `T_ModuleInit_Phase2Veneer`, `T_F40A00` |
| 1 | `SysExInitial_PartSetting` | `T_PartSettings_ResetToDefault` |
| 2 | `SysExInitial_System` | `T_SystemSettings_ResetToDefault`, then a 0x3FFF countdown |
| 3 | `SysExInitial_MidiSetting` | `T_MidiSettings_ResetToDefault`, then a 0x7FFF countdown |
| 4 | `SysExInitial_ReMap` | the two remap resets, then a 0xFFFF countdown |
| 5 | `SysExInitial_DrumsMap` | `T_DrumMap_ResetToDefault`, then a 0xFFFF countdown |
| 6 | `SysExInitial_Sequencer` | `T_Sequencer_ResetToDefault`, then a 0xFFFF countdown |

So the wire value is the screen's item number.

The SysEx arms differ from the screen's in three ways:

- TOTAL skips `T_F43450` and `sub_FA0DCC`.
- SYSTEM skips `T_Mode_SwitchToSound`.
- Each arm except 0 and 1 ends in a busy countdown.

⚠ Not established: why the delays differ.
