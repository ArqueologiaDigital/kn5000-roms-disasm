# prom_a: the panel-mode group (0x2076/0x2077) and the screen hold timer (0x2073, 0x209A, 0x2092) (2026-10-03)

Neighbours of the panel variables in `FINDINGS-prom_a-panel-state-variables.md`. Each row rests
on the existing prom_a headers of the routines named, and was re-checked against every operand:

    python3 wsa1/notes/prom_ab_ram_operand_shapes.py 0x2076 0x2077 0x2073 0x209a 0x2092 --sites
    python3 wsa1/notes/prom_a_panel_mode_group_map.py

## 1. `PanelModeGroup` (0x2076) and `PanelModeGroup_Previous` (0x2077)

`PanelMode_ToGroup` (0xF86CAE), called once per pass from `PanelTask_Step`, stores
`PanelMode_GroupMap[PanelMode]` into (0x2076). A mode above 0x1F is replaced by 1, not clamped.

The map at 0xF86E81 is the identity for 18 of its 32 entries. It merges the rest:

- modes 3, 4, 5, 6 and 7 all become group 3;
- modes 0, 1, 0x11 and 0x18-0x1F all become group 1.

So (0x2076) is the mode with those modes folded together. Its 82 uses never test a value outside
the map's image:

- 36 are `cp (0x2076),0x16` and 15 are `cp (0x2076),0x17`;
- the remaining tests are 0x01, 0x02, 0x08, 0x09, 0x0A, 0x0C, 0x0D, 0x12 and 0x13;
- the five `PanelAction_*` sound/bank routines branch on 0x09 and 0x08.

(0x2077) is the group at the previous pass:

- `PanelState_LatchPrevious` copies (0x2076) into it;
- `PanelState_Init` writes 0xFF to it, which `PanelState_LatchPrevious` tests (`cp (0x2077),0xFF`);
- its 5 uses are those three, plus `lda XIX,(0x2077)` in `ScreenLeaveBody_CombiEditMixer` and `cp (0x2077),0x12` in
  `ScreenLeaveBody_CombiEditConfigure`.

⚠ Not established: what any single mode or group IS, i.e. which instrument mode 0x16 or 0x17
selects. The name says only what the code does: it groups modes.

## 2. The screen hold timer: `UI_ScreenHoldTimer` (0x2073), `UI_ScreenHoldPending` (0x209A), `UI_ScreenHoldState` (0x2092)

**`UI_ScreenHoldTimer` (0x2073)** is the countdown `PanelTimer_ScreenHold` runs (two
`dec 1,(0x2073)`). When the countdown reaches zero, or when it is at most 1 while (0x20A2) holds a
screen, it raises `UI_Request_Hi` bit 2. That is the bit `PanelState_RunRequests` hands to
`PanelScreen_ApplyPendingId`, so the requested screen is dropped after a time.

What loads it:

- 0x70 when a screen request is applied: `PanelScreen_ApplyRequest`, `PanelEvent_Code21_Dial`,
  and `PanelButton_Accept` (through `ld A,0x70 / ld (0x2073),A`);
- 0 on a mode change (`PanelScreen_ApplyModeChange`) and in `PanelScreen_ApplyRequestForced`;
- 1 in `PanelEvent_Code03`;
- the pending value, in `PanelState_TakePendingHoldTime`.

The census also lists `.short 0x2073` once, in prom_b's `DL_T0neLayerSoundEditTrigGer`. It is not
this variable: it is the screen position word of an op-0x06 text record, between `.ascii` runs.

**`UI_ScreenHoldPending` (0x209A)** is a one-shot preload. `PanelState_TakePendingHoldTime` moves
it into the timer when it is non-zero and then zeroes it. It is written:

- 1 by 32 handlers (`*_AdjustBank`, `ExitKey_*GroupMenu`, `DrumsMap_AdjustRowSound` ...);
- 0xFF by `InstallPainter_MessageScreen` and `Paint_PowerOnSplash`;
- 0x3F by `Paint_PowerOnSplash`.

**`UI_ScreenHoldState` (0x2092)** is written only by `PanelState_UpdateScreenHoldState`:

- bit 0 = the timer is non-zero this pass;
- bit 1 = it has just stopped. While the timer runs, the bit is written 0 (`ld W,1`). Once the
  timer is zero, the bit takes the old bit 0 (`sla 1,W / and W,2`). It is therefore set for
  exactly one pass, the first with the timer at zero;
- bits 2-7 are kept (`and A,0xFC`).

No reader tests anything but bit 0. There are 30 `bit 0,(0x2092)`, 21 `ld C,(0x2092) / and C,1`,
one `bit 0,A` and one `and A,1`.

Two loads are not followed by a test in the census, and neither is an exception:

- in `sub_FBFE2C`, the `and C,0x01` comes one line later, after that routine's label;
- the other is `PanelState_UpdateScreenHoldState`'s own read-modify-write.

Among the readers:

- `PanelState_UpdateScreenLatch` re-latches `UI_ScreenLatch` from `UI_ScreenId` when the mode changed,
  or when bit 0 is clear. So while the timer runs, an unchanged mode keeps the latch.
- `PanelState_CheckRequestAllowed` clears the `UI_ScreenFlags` bit 0 override when bit 0 here is
  clear and `UI_RequestBits` bit 4 is set.

⚠ Not established: why a held screen must not re-latch `UI_ScreenLatch`. Nor why so many value
handlers end their screen's hold at the next tick (a preload of 1).
