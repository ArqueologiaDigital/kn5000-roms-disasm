# prom_a: panel LED, analog-control and held-key state (2026-10-03)

From round-1 pack prom_a-s01 (read and applied 2026-10-03), re-checked against the code.

| address | name | holds | evidence (prom_a) |
|---|---|---|---|
| 0x20D0 | `PanelLed_Shadow` | 8 LED bytes, as they should be (`+n` = LED byte n) | PanelLed_ShowBank / _ShowModeMenu / _ShowCtrl1Offset ... write them through `ld XIX,0x20d0`; PanelLed_SendChangedBytes compares them |
| 0x20F0 | `PanelLed_Sent` | the 8 LED bytes as last sent to the panel | PanelLed_SendChangedBytes sends each byte that differs from PanelLed_Shadow and copies it; PanelLed_ToggleActivityLed mirrors byte 6 |
| 0x28E0 | `AnalogScan_HystState` | two hysteresis bytes per A/D channel 0-3 (`+2n`, `+2n+1`) | AnalogScan_AdChannel0..3 load W / C from them for AnalogScan_Hysteresis |
| 0x28EC | `AnalogScan_Cooked` | six cooked controller values, bit 7 = changed: `+0` channel 4, `+1` channel 5 (RAM sources), `+2..+5` A/D channels 0-3 | AnalogScan_RamChannel4/5, AnalogScan_AdChannel0..3 write `value \| 0x80`; PanelGroupQueue_AppendFlaggedGroups consumes them |
| 0x2252 | `PanelHeld_Pos0` | 32-bit set: the pair-position-0 keys held | PanelAction_PairPos0_HeldMask(_AltCode) set / clear their bit; PanelButton_Accept |
| 0x2256 | `PanelHeld_Pos1` | 32-bit set: the pair-position-1 keys held | PanelAction_PairPos1_HeldMask(_AltCode) |
| 0x2196 | `PanelWire_Phase` | the poll phase 0..3 (phases 0 and 2 poll the producers) | PanelWire_ThrottledPoll |
| 0x2197 | `PanelWire_LastPollTick` | Tick_Count at the last producer poll (word) | PanelWire_PollProducers stores it; PanelWire_ThrottledPoll resets the phase 16 ticks after |
