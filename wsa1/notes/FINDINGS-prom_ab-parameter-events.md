# prom_a / prom_b: the UI event lists carry parameter changes (2026-10-04)

`UiEventList_Run` dispatches 4-byte event records to the class lists `UiList{A,B,C}_ClassNN`. Their headers said
"what the handlers DO is not claimed here". One fact makes most of them readable. **The class is a parameter
record id.** Byte 1 is a byte index in that record, byte 2 is the new value, and byte 3 is the mask of the bits
that changed. notes/sysex-probes/README.md shows this for GM mode: the event {0x91, 0x03, value, 0x04} is
record 0x91, payload byte 3, bit 2.

The SysEx parameter descriptors give each Reference-Guide parameter a record (`rec`), an offset and a mask
(`notes/sysex-probes/sysex_param_addresses.py`, names in `param_names.json`). So a handler that tests
(class, byte index, mask) can be named after the parameter it reacts to:

| record | what it is (from the descriptors) |
|---|---|
| 0x00-0x1F | the 32 parts' first record: PROGRAM CHANGE & BANK (byte 0), KEY SCALING (12), BASIC CHANNEL / LOCAL CONTROL / MIDI OUT / MIDI IN SETTING (13) |
| 0x20-0x3F | the parts' second record (`rec` 32): outputs, VELOCITY OFFSET, ASSIGN MODE, layers, the controller and MIDI filters, MIDI OUT KEY TRANSPOSE |
| 0x79 | KEY TRANSPOSE, MAIN OUT EQUALIZER, EFFECT1 / 2 OUTPUT SELECT |
| 0x80 | the MIDI system record: PROGRAM CHANGE MODE, MIDI INPUT / OUTPUT MODE, SINGLE CHANNEL, LOCAL TOTAL |
| 0x91 | MASTER TUNING, the GM bit, DRUMS MAP SELECT |
| 0x93 | VELOCITY CURVE / OFFSET, AFTER TOUCH CURVE / THRESHOLD |
| 0x98 | PLAY MODE REQUEST, COMBINATION NUMBER and BANK, METRONOME VOLUME, DATA LOAD FILTER |

Classes 0xB1 and 0xB4 do not follow this scheme. Their byte 1 is a part number:
`Msg0716_OnPitchBendEvent` and `Msg0716_OnChannelPressureEvent` read it that way. This matches the
`ParamMsg_PartMask_*` comments ("parts receiving B1", "B4").

Handlers named this way on 2026-10-04 (notes/prom_ab_read_names_2026_10_04.py):
- note routing: FINDINGS-prom_a-note-frames.md section 9;
- `ProgramChangeMode_OnEvent` (0x80 byte 0; it calls an empty slot);
- GM mode, record 0x91 byte 3 bit 2:
  - `GmMode_OnEventPassB`, which runs unless `GmMode_HandleChange` is running and posts
    `Msg0716_PostGmSystemOnOff` (F0 7F 09 01 / 02) through `GmMode_PostToMsg0716`;
  - `GmMode_RepaintModeScreen`;
- COMBINATION EDIT: `CombiEdit_OnPartParamEvent` chooses by screen between `CombiEditPage_`, `CombiEditMixer_`
  and `CombiEditConfigure_OnPartParamEvent`;
- `DspEffect_OnParamEvent` (part 0's records and the effect records 0x60-0x63 / 0x79);
- CREATOR SELECT CONTROLLER (screen 0xAD):
  - `CreatorSelectController_OpenOnEvent` (record 0xA8 byte 5 bit 2 opens the screen);
  - `CreatorSelectController_OnPartEvent`;
- `Drawbar_MarkReloadOnSoundEvent` and `Drawbar_ReloadIfMarked` (`Drawbar_ReloadMark`, 0x28A0).

Not established:
- records 0xA8 and 0xA9 and byte 9 of record 0x80 have no descriptor;
- the handlers of 0xA8 byte 17 (`sub_F4E525` -> T_F409E0, 24 callers, unnamed) and of 0x9A;
- the Msg0716 entry stubs `sub_FC0430` / `sub_FC0450` / `sub_FC0460`.

## COMBINATION EDIT MIXER cells (2026-10-05)

The MIXER screens (0x3A / 0xB7) draw 8 parts by 13 cells. Each cell painter reads one byte of a part record
through `T_IndexedTable_GetByte`. The (record, offset, mask) of that read matches exactly one PART parameter in
the SysEx descriptors, which is how they are named (`notes/prom_a_combi_mixer_cells.py`):

| cell painter | record byte | parameter | dirty mask |
|---|---|---|---|
| `CombiEditMixer_DrawSound` | second record +0x1B..+0x1D (or `T_F42CA0`'s text) | the sound | 0x2770 |
| `CombiEditMixer_DrawLocalControl` | first 13 & 0x20 | LOCAL CONTROL | 0x2771 |
| `CombiEditMixer_DrawPanpot` | first 8 | PANPOT | 0x2772 |
| `CombiEditMixer_DrawVolume` | first 3 | VOLUME | 0x2773 |
| `CombiEditMixer_DrawReverbSend` | first 7 | REVERB SEND | 0x2774 |
| `CombiEditMixer_DrawEffect1Send` | first 5 | EFFECT1 SEND | 0x2775 |
| `CombiEditMixer_DrawEffect2OnOff` | first 6 & 0x7F | EFFECT2 ON/OFF | 0x2776 |
| `CombiEditMixer_DrawSubOut` | second 4 | SUB OUT | 0x2777 |
| `CombiEditMixer_DrawMainOut` | second 3 | MAIN OUT | 0x2778 |
| `CombiEditMixer_DrawMidiOutSetting` | first 13 & 0x40 | MIDI OUT SETTING | 0x2779 |
| `CombiEditMixer_DrawMidiInSetting` | first 13 & 0x80 | MIDI IN SETTING | 0x277A |
| `CombiEditMixer_DrawBasicChannel` | first 13 (no mask; by elimination) | BASIC CHANNEL | 0x277B |
| `CombiEditMixer_DrawKeyShift` | first 9 | KEY SHIFT | 0x277C |

When a parameter event arrives, `CombiEditMixer_OnPartParamEvent`'s page routine ORs the part's bit into the
dirty mask and posts the matching `CombiEditMixer_RepaintMarked*` callback. That callback takes the mask and
clears it with interrupts held (`ei 6`), then repaints the marked parts of the edited group.

The switches go through `CombiEditMixer_DrawSwitchCell` and the levels through `CombiEditMixer_DrawValueCell`.
The basis is the descriptor match, which is a table-index basis. Not established: `sub_FBE5CA` (the
edited-part header) and the page painters, which are still `.L` labels in 0xFBE2E9..0xFBE4AF.

### COMBINATION EDIT state (2026-10-05)

The INTERNAL SOUND, MIXER and CONFIGURE screens share three RAM bytes:
- `CombiEdit_Part` (0x2765): the edited part, 0..31. Its group of 8 is `& 0xF8`. `ModeEnter_CombiEditPart`, the
  screens' enter bodies and `CombiEditMixer_ColumnKey` set it.
- `CombiEdit_Page` (0x2767): the screen's page, 0..2. Each enter routine sets it to 0. The MIXER chooses its page
  painter (`PtrTable_F1B03F`) and its page event handler (`PtrTable_F1AE89`) by it.
- `CombiEdit_Row` (0x2769): the selected field on the page. The enter and PAGE routines reset it.
  `CombiEditMixer_ColumnKey` steps field `IndexMap_F1B031[row]` of the part.

The MIXER's three pages, by the cells they draw:
- `CombiEditMixer_PaintSoundPanVolumePage`: sound, LOCAL CONTROL in group 0x16, PANPOT, VOLUME.
- `CombiEditMixer_PaintSendsPage`: REVERB, EFFECT1, EFFECT2, MAIN OUT, KEY SHIFT.
- `CombiEditMixer_PaintMidiPage`: LOCAL CONTROL, MIDI OUT / IN, BASIC CHANNEL, SUB OUT.

Each page has a matching event handler, `CombiEditMixer_On*PageEvent`. All six were reached only through prom_b
pointers and had no label.

### COMBINATION EDIT entry, exit and COMPARE (2026-10-05)

- **Entry.** `CombiEdit_Begin` (`T_CombiEdit_Begin`) switches to combination mode and makes the current part
  `CombiEdit_Part`, keeping the previous one in `CombiEdit_EntryPart`. It then copies the current combination
  (`Combination_Current`, the 0x2C0-byte record at 0x7620 in CPU 2's preset format) to
  `CombiEdit_CompareOriginal` (0x1400), using `CombiEdit_SaveOriginalForCompare`.
- **COMPARE on.** `CombiEdit_SwapForCompare` first saves the edited record to `CombiEdit_CompareEdited` (0x1D00).
  It then loads the original into `Combination_Current`.
- **COMPARE off.** It restores the edited record, then queues the parameter differences
  (`T_ParamImage_QueueDiffCombination`).
- **Exit.** `CombiEdit_End` (`T_CombiEdit_End`) restores the part and turns COMPARE off.
- **Shared dirty mask.** `CombiEdit_DirtySound` (0x2770) is set by both the MIXER and CONFIGURE handlers. It was
  `CombiEditMixer_DirtySound` for one commit.
- **CONFIGURE pages.** They draw the MIDI settings (byte 13), KEY LAYER and VELOCITY LAYER of the parts. The
  layer pages show parts 0-7 only.

### COMBINATION EDIT INTERNAL SOUND pages (2026-10-05)

`CombiEditSound_PageIndex` maps the screen and `CombiEdit_Page` to one of six page painters. They sat in
prom_b's `PtrTable_F1AFBD` as numbers and had no labels; the dispatch census flagged them. Each is named by the
part-record bytes it draws, matched to the SysEx descriptors:

| index | screens / pages | painter | parameters |
|---|---|---|---|
| 0 | 0x37 / 0xB4 page 0 | `CombiEditSound_PaintLevelsPage` | VOLUME, PANPOT, EFFECT1 SEND, EFFECT2, REVERB SEND, KEY SHIFT, FINE TUNE, BEND RANGE, MAIN OUT |
| 1 | 0x37 / 0xB4 page 1 | `CombiEditSound_PaintControllerFilterPage` | CONTROLLER INTERNAL FILTER (second record 11-14) |
| 2 | 0x37 / 0xB4 page 2 | `CombiEditSound_PaintAssignAndInputFilterPage` | ASSIGN MODE, KEY SCALING, VELOCITY OFFSET, MIDI INPUT FILTER |
| 3 | 0xB5 page 0, 0x38 page 1 | `CombiEditSound_PaintMidiOutPage` | MIDI OUTPUT FILTER (19, 20), MIDI OUT KEY TRANSPOSE |
| 4 | 0xB5 page 1, 0x38 page 2 | `CombiEditSound_PaintMidiOutFilterPage` | MIDI OUTPUT FILTER (19-22) |
| 5 | 0x38 page 0 | `CombiEditSound_PaintMultipleMessagesPage` | MIDI MULTIPLE MESSAGES OUTPUT (first record 14-21) |

The census also flagged two button-table targets with no labels:
- slots 8 and 9 (LCD key rows 1 and 2) of the PART MENU and INTERNAL SOUND button tables, both stepping the
  edited part (`LcdKeyRow1_` / `LcdKeyRow2_CombiEditPartSelect`);
- WRITE PROTECT ERROR's LCD row 4 and EXIT (`WriteProtectError_Dismiss`).
