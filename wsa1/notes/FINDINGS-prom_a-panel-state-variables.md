# prom_a panel state: the mode / screen latches and the dial's button pair (2026-10-03)

## 1. The mode / screen latches

`PanelState_LatchPrevious` (0xF860D9) copies three current values into their "previous" twins on every
pass of the panel task, unless `(0x2077)` is 0xFF:

```
ld A,(0x2078) / ld (0x2079),A      ; mode
ld A,(0x207A) / ld (0x207B),A      ; latched screen
ld A,(0x207C) / ld (0x207D),A      ; screen id (UI_ScreenId)
```

| address | name | holds | evidence |
|---|---|---|---|
| 0x2078 | `PanelMode` | the panel mode; `PanelMode_ToScreenId` maps it to a screen id, `PanelMode_ToGroup` to the LED group | PanelState_LatchPrevious, PanelMode_ToScreenId |
| 0x2079 | `PanelMode_Previous` | `PanelMode` at the previous pass | PanelState_LatchPrevious |
| 0x207A | `UI_ScreenLatch` | `UI_ScreenId` taken by `PanelState_UpdateScreenLatch` (0xF863F5) when the mode changed (`(0x2078) != (0x2079)`) or bit 0 of `(0x2092)` is clear; `PanelState_Init` starts it at 1 (SOUND MODE) or 2 (COMBINATION MODE) by `(0x7F02) & 0xF0` | PanelState_UpdateScreenLatch, PanelState_Init |
| 0x207B | `UI_ScreenLatch_Previous` | `UI_ScreenLatch` at the previous pass; the screens' Enter / Leave bodies compare the two (`ld c,(0x207a) / cp (0x207b),c`) to tell a fresh entry from a redraw | PanelState_LatchPrevious; e.g. ScreenLeave_SoundCopy |
| 0x207D | `UI_ScreenId_Previous` | `UI_ScreenId` at the previous pass | PanelState_LatchPrevious |

What `(0x2077)` = 0xFF and bit 0 of `(0x2092)` mean is not established.

## 2. The dial's button pair

`PanelEvent_Code21_Dial` (0xF86833): with bit 0 of `(0x2075)` set the dial is routed as a BUTTON
through `PanelButton_Route` -- `W = (0x209C)` when the step byte from `PanelDial_DeltaToStepIndex` has
bit 7 clear (a positive delta), `W = (0x209B)` when it is set (negative) (0xF86874 / 0xF8687A).  The
screens bind it with a word store, `ldw (0x209B),0x0605` (SOUND COPY's SINGLE page and others), and
`PanelDial_UnbindFromButtons` clears bit 0 of `(0x2075)`.

| address | name | holds |
|---|---|---|
| 0x209B | `PanelDial_DownButton` | the button code the dial acts as when turned down |
| 0x209C | `PanelDial_UpButton` | the button code the dial acts as when turned up |

Census of every operand of these addresses: `python3 notes/wsa1_panel_state_census.py` (wsa1/).
