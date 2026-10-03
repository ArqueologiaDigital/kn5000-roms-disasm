# prom_a: the MIDI settings bytes 0x7F32-0x7F3B (2026-10-03)

The MIDI screens of pack prom_a-s05 (read and applied 2026-10-03) edit these bytes field by field and
post each change as parameter record 0x80 byte D (`{0x80, W = mask, D = byte}` via T_F41B18): D = 0 is
0x7F32, so the block is record 0x80's payload.  The MIDI-in handlers read the same bits.

| address | name | fields | evidence (prom_a) |
|---|---|---|---|
| 0x7F32 | `MidiCfg_ModeBits` | bits 0-1 PROG CHANGE MODE (NORMAL / TECH / REMAP), bit 3 SINGLE CH PROG CHANGE = COMBI; the clock / realtime-command code reads it too | MidiTotalMode_EditProgChangeMode, _EditSingleChProgChange; Draw_RealtimeCommandsClock, INTT1_Tick |
| 0x7F33 | `MidiFilter_SongSelect` | bit 3: SONG SELECT filter | MidiInputOutputFilter_EditSongSelect (D = 1); MidiIn_SongSelect |
| 0x7F35 | `MidiCfg_InOutMode` | bits 0-3 INPUT MODE (MULTI / SINGLE / OMNI), bits 4-7 OUTPUT MODE (MULTI / SINGLE) | MidiTotalMode_EditInputMode / _EditOutputMode (D = 3); MidiIn_BuildChannelRouteTable and the MidiIn_CC* handlers |
| 0x7F36 | `MidiCfg_SingleChannel` | bits 0-3 SINGLE CHANNEL, bit 5 LOCAL TOTAL (set = OFF) | MidiTotalMode_EditSingleChannel / _EditLocalTotal (D = 4) |
| 0x7F38 | `MidiFilter_Exclusive` | bits 0-3: EXCLUSIVE (ON when any is set) | MidiInputOutputFilter_EditExclusive (D = 6) |
| 0x7F39 | `MidiFilter_ChannelMsgs` | bit 3 CONTROL CHANGE, 4 PROGRAM CHANGE, 5 CHANNEL PRESSURE, 6 PITCH BEND | MidiInputOutputFilter_Edit* (D = 7); MidiIn_ProgramChange / _PitchBend / _ChannelPressure |
| 0x7F3A | `MidiFilter_BankSelect` | bit 7: BANK SELECT | MidiInputOutputFilter_EditBankSelect (D = 8); MidiOut_SendBankSelect |
| 0x7F3B | `MidiFilter_ResetAllCtrl` | bit 0: RESET ALL CTRL | MidiInputOutputFilter_EditResetAllCtrl (D = 9) |
