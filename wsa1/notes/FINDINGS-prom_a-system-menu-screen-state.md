# prom_a SYSTEM-menu screens: their state bytes (2026-10-03)

The SYSTEM-menu screens of prom_a (`notes/lanes/wsa1-naming-r1-2026-10-02/`, pack prom_a-s06, read
and applied 2026-10-03) keep their cursor and selection in RAM 0x2690-0x270F.  Each screen steps its
values through `T_F42C78` (prom_b 0xF550A6: step a byte through a 9-byte descriptor, A = 1 when it
changed) with `lda xwa,(var) / push` as the argument, so the stepping routine names the variable; the
screen's display-list records read the same byte (`+0x02 source variable`).

| address | name | holds | evidence (routine, prom_a) |
|---|---|---|---|
| 0x2690 | `TuneScale_ItemCursor` | TUNE & SCALE item, 0..4 in bits 0-2 (MASTER TUNE .. KEY SCALING SHIFT) | TuneScale_MoveItemCursor (T_F42C78, Descriptor9_FA1E49), TuneScale_AdjustSelectedItem (`and 7`, 5-entry table) |
| 0x2691 | `TuneScale_MasterTuneIndex` | index into ByteTable79_FA1C5C, the MASTER TUNE value | TuneScale_StoreMasterTune, TuneScale_LoadFields |
| 0x2692 | `TuneScale_KeyScalingIndex` | index into ByteTable16_FA1C4C, the key-scaling type | TuneScale_StoreKeyScalingType, TuneScale_KeyScalingCodeToIndex |
| 0x2695 | `SoundGroupNaming_Bank` | bank 0..4 (ByteTable5_FA17CA: USER1/USER2/RE-MAP1-3) | SoundGroupNaming_AdjustBank, _LoadGroupNames |
| 0x2696 | `SoundGroupNaming_Group` | group 0..15 | SoundGroupNaming_AdjustGroup, _DrawGroupCursor |
| 0x2698 | `CombinationGroupNaming_Bank` | bank 0..3 (ByteTable4_FA182B) | CombinationGroupNaming_AdjustBank |
| 0x2699 | `CombinationGroupNaming_Group` | group 0..15 | CombinationGroupNaming_AdjustGroup |
| 0x269A | `CopyScreen_Page` | SOUND COPY / COMBINATION COPY page: bit 0 SINGLE (else GROUP), bit 1 the overwrite question, bit 2 an error page | Paint_SoundCopy / Paint_CombinationCopy dispatch on it; SoundCopy_ClearErrorState `and 0xF9`; both Enter bodies set 1 |
| 0x269B | `SoundCopy_SourceBank` | ROM 1 / ROM 2 / USER 1 / USER 2 / EXT 1 (ByteTable5_FA188B) | SoundCopy_AdjustSourceBank |
| 0x269C | `SoundCopy_SourceGroup` | the source group; cleared when the bank changes | SoundCopy_AdjustSourceBank, the next stepper (EXT: max = (0x08E8) - 1) |
| 0x269D | `SoundCopy_SourceSound` | SINGLE page: the source sound in the group | SoundCopy_DrawSourceSoundCursor (record FA405F) |
| 0x269E | `SoundCopy_SourceGroupRow` | GROUP page: the cursor row of the source group list | SoundCopy_DrawSourceGroupCursor (record FA3CBE) |
| 0x269F | `SoundCopy_SourceListTop` | GROUP page: the first group the source list shows | SoundCopy_DrawSourceGroupList (record FA3D4F) |
| 0x26A0 | `SoundCopy_DestBank` | USER 1 / USER 2 | SoundCopy_AdjustDestBank (Descriptor9_FA1ACA) |
| 0x26A1 | `SoundCopy_DestGroup` | the destination group; cleared when the bank changes | SoundCopy_AdjustDestBank |
| 0x26A2 | `SoundCopy_DestSound` | SINGLE page: the destination sound | SoundCopy_DrawDestSoundCursor (record FA406A) |
| 0x26A3 | `SoundCopy_DestGroupRow` | GROUP page: the cursor row of the destination list | SoundCopy_DrawDestGroupCursor (record FA3CC9) |
| 0x26A4 | `SoundCopy_DestListTop` | GROUP page: the first group the destination list shows | SoundCopy_DrawDestGroupList (record FA3DC7) |
| 0x26A5 | `DataLoadFilter_ItemCursor` | DATA LOAD FILTER row, indexing JumpTable_F9EC58 | DataLoadFilter_* (the row's editor) |
| 0x2702 | `DrumsMap_Map` | NORMAL / USER 1-3 | DrumsMap_AdjustMap (Descriptor9_FA1B5A), DrumsMap_StoreMapCode |
| 0x2703 | `DrumsMap_RowCursor` | the cursor row, 0..11 | DrumsMap_MoveRowCursor, DrumsMap_DrawRowCursor (record FA4B9F) |
| 0x2704 | `DrumsMap_ListTop` | the first note the 12 rows show (scrolled at the edges) | DrumsMap_MoveRowCursor |
| 0x2706 | `CombinationCopy_SourceBank` | the source bank (+EXT when (0x08EC) bit 1) | CombinationCopy_AdjustSourceBank (Descriptor9_FA1663) |
| 0x2707 | `CombinationCopy_SourceGroup` | the source group; a change clears 0x2708 | the stepper after CombinationCopy_AdjustSourceBank |
| 0x2708 | `CombinationCopy_SourceCombi` | SINGLE page: the source combination | CombinationCopy_DrawSourceCombiCursor (record FA4265) |
| 0x2709 | `CombinationCopy_SourceGroupRow` | GROUP page: cursor row of the source list | CombinationCopy_DrawSourceGroupCursor (record FA4141) |
| 0x270A | `CombinationCopy_SourceListTop` | GROUP page: first group of the source list | CombinationCopy_DrawSourceGroupList (record FA4157) |
| 0x270B | `CombinationCopy_DestBank` | the destination bank | CombinationCopy_AdjustDestBank (Descriptor9_FA1AF7) |
| 0x270C | `CombinationCopy_DestGroup` | the destination group | CombinationCopy_AdjustDestBank |
| 0x270D | `CombinationCopy_DestCombi` | SINGLE page: the destination combination | CombinationCopy_DrawDestCombiCursor (record FA4270) |
| 0x270E | `CombinationCopy_DestGroupRow` | GROUP page: cursor row of the destination list | CombinationCopy_DrawDestGroupCursor (record FA414C) |
| 0x270F | `CombinationCopy_DestListTop` | GROUP page: first group of the destination list | CombinationCopy_DrawDestGroupList (record FA41CF) |

Not named here: RE-MAP EDIT's 0x26F3-0x26FF (their rows and the SOUND/COMBI selector are drawn from
them, but which byte is which list was not re-read), 0x2694 / 0x2697 (read by the group-naming
screens' handlers, purpose not read), and SOUND MUTE / MEMORY PROTECT's bytes.

## 2. The MIDI and disk screens (pack prom_a-s05 and others, same day)

| address | name | holds | evidence (routine, prom_a) |
|---|---|---|---|
| 0x2720 | `UI_ScreenItem` | the item the current screen's cursor is on -- MIDI TOTAL MODE 0..5, I/O FILTER 0..7, OUT PROGRAM CHANGE 0..3, SYSEX BULK DUMP and the disk screens' rows; GENERAL MIDI uses bit 2 for its pending ON / OFF | MidiTotalMode_StepItem, MidiInputOutputFilter_StepItem, MidiOutProgramChange_StepItem, LcdKeyRow1..4_SysexBulkDump, LcdKeyRow3/4_GeneralMidiMode_Page0, the DiskL0adFile / DiskSaveFile row keys (39 routines) |
| 0x2746 | `MidiOutPgm_Channel` | MIDI OUT PROGRAM CHANGE: MIDI channel 0..0x1F | MidiOutProgramChange_EditMidiCh, _PaintMidiCh |
| 0x2747 | `MidiOutPgm_Program` | the program, 0..0x7F (shown +1) | MidiOutProgramChange_EditProgram, _PaintProgram, _NumberPadProgram |
| 0x2748 | `MidiOutPgm_BankMsb` | bank select MSB, 0..0x7F | MidiOutProgramChange_EditBankMsb, _PaintBankMsb |
| 0x2749 | `MidiOutPgm_BankLsb` | bank select LSB, 0..0x7F | MidiOutProgramChange_EditBankLsb, _PaintBankLsb |
| 0x274A | `MidiOutPgm_BankSelect` | word MSB * 128 + LSB, 0xFFFF = bank select OFF | MidiOutProgramChange_EditBankMsb (recomputes it), _EditBankLsb (OFF below 0), _PaintBankSelect, _ResetState (0xFFFF) |

MidiOutProgramChange_Send passes (0x2746), (0x2747) and (0x274A) to T_MIDI_SendBankAndProgram.
