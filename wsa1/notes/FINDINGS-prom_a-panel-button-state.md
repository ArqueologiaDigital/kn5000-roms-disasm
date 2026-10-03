# prom_a: held buttons, auto-repeat and the hold timer (2026-10-03)

The prom_a headers of `PanelButton_Accept`, `PanelButton_SweepHeld`, `PanelButton_Dispatch`,
`PanelTimers_Step`, `PanelTimer_ButtonRepeat`, `PanelHold_Tick` and the two `PanelEvent_*_ArmHold`
handlers already establish what each of these cells does. They come from the wave-6/7 rounds and the
checks named in each header. This note names the cells and re-counts every operand:

    python3 wsa1/notes/prom_ab_ram_operand_shapes.py 0x2088 0x2084 0x2082 0x2074 0x20a7 0x2096 --sites

## 1. The held-button state

`PanelButton_Accept` folds one button event into a 32-bit bitmap.
`PanelButton_BitMask32` is the identity, entry[i] == 1 << i, so bit i of each bitmap is button
code i.

| address | name | holds | uses |
|---|---|---|---|
| 0x2088 | `PanelButton_HeldMask` | bit i = button i is down. Set on a press unless `PanelButton_InterlockMask32` hits `PanelHeld_Pos0` / `PanelHeld_Pos1`; cleared on release; 0 on a mode or screen change | 25 |
| 0x2084 | `PanelButton_HeldPairPos` | bit i = button i was pressed with bit 0 of (0x20B9) set, i.e. the pair position: Accept sets the bit, then clears it again unless that bit is set. `PanelButton_SweepHeld` ORs 0x80 into the code from it | 6 (one `.short 0x2084` among them is display-list data) |
| 0x2082 | `PanelButton_Current` | the code `PanelButton_DispatchCurrent` routes (`ld W,(0x2082)`), with 0x80 = the pair position; written by `PanelButton_Accept` and, per held bit, by `PanelButton_SweepHeld` | 3 |
| 0x2074 | `PanelButton_RepeatTimer` | ticks to the next auto-repeat. `PanelButton_Accept` loads 0x10 (the first repeat), `PanelButton_Dispatch` loads 3 (between repeats), and a release that empties `PanelButton_HeldMask` loads 0. `PanelTimer_ButtonRepeat` counts it down and raises `UI_Request_Hi` bit 3, which re-enters `PanelButton_SweepHeld` | 5 |

`PanelTimers_Step` runs this repeat timer only while `PanelButton_HeldMask` is non-zero, and the
screen timers otherwise. That is the `cp XWA,0` at 0xF86907.

(0x208C) is left a number. `PanelButton_Accept` sets a button's bit there when (0x20B9) == 3,
release clears it, and `PanelButton_PostClass70` tests bit 14 of it. What a state byte of 3 means
for a button was not pinned down here.

## 2. The hold timer

| address | name | holds | uses |
|---|---|---|---|
| 0x20A7 | `PanelHold_Timer` | ticks before a held event requests a screen: 0x40 (`PanelEvent_Code01_ArmHold`) or 0x30 (`PanelEvent_Code20_ArmHold`), 0 to cancel. `PanelHold_Tick` counts it down | 6 |
| 0x2096 | `PanelHold_Index` | the 16-bit index into `PanelHold_ScreenRequest`. `PanelHold_Tick` loads the word there into `UI_Request` when the timer reaches 0; the ArmHold handlers write 2, 7 or 0 | 6 instructions; the census also lists 8 `.short 0x2096`, which are display-list data in prom_b's `DL_*` and not this variable |

`Paint_DiskL0adFile` also writes 0 to (0x2096) and compares it with 7.

⚠ Still open, as the headers say: why index 7, whose `PanelHold_ScreenRequest` entry is 0xFFFF,
is armed at all.

## 3. Correction to FINDINGS-prom_a-panel-state-variables.md

That note ended "What (0x2077) = 0xFF and bit 0 of (0x2092) mean is not established." Both are
answered in `FINDINGS-prom_a-panel-mode-group-and-screen-hold.md`:

- (0x2077) is `PanelModeGroup_Previous`. 0xFF is the value `PanelState_Init` leaves there, and it
  makes the first `PanelState_LatchPrevious` skip latching the mode and the two screen ids. The
  group itself is still copied.
- Bit 0 of (0x2092) is `UI_ScreenHoldState`'s "the screen hold timer is running".
