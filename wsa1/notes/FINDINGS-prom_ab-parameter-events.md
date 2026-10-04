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
