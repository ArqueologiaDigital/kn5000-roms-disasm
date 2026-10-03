# prom_a + prom_b: the screen stage (0x207E) and the screen flags (0x2095) (2026-10-03)

`FINDINGS-prom_b-dispatch-layers.md` recorded that what `(0x207E)` means was "still not
established". It said only that the byte picks one of a screen's two button maps and one of two
title lists. This note establishes it from every operand in both images, together with the flag
byte next to it.

All counts come from `python3 wsa1/notes/prom_ab_screen_stage_and_flags_census.py`. It matches the
hex spelling (prom_a), the decimal one (prom_b) and the symbol, so it prints the same figures
before and after the rename.

## 1. `UI_ScreenStage` (0x207E): which page of the current screen is up

On the job screens, 0 is the parameter page and 1 is the "Are You Sure ?" / "Attention" page.

Census figures:

- **Writes:** 0 written 55 times, 1 written 19 times, 2 written once; one `ld (0x207E),A` and one
  `inc 1,(0x207E)`.
- **Tests:** 42 `cp (0x207E),0` and 33 `cp (0x207E),1`.
- **Which side draws the confirmation list.** Every `cp (0x207E),0 / jr nz` was checked, using the
  list start XIY only, because XIX is the list's end bound and draws nothing:
  - 25 draw an `AreYouSure` or `Attention` list on the non-zero side;
  - 0 draw one on the zero side;
  - 4 draw neither (`Paint_PowerOnSplash` is one of them).
- **The two-press shape of an execute key**, `cp (0x207E),1 / jr z, run / ld (0x207E),1 /
  or (0x2071),0x10`, occurs 14 times (prom_b's command module, e.g. `SongClear_LcdKeyRow4` and
  `sub_F7B162`):
  - the first press sets the stage to 1 and requests a redraw, which paints the question;
  - the second press, with the stage already 1, runs the job and writes 0 back.

Other uses:

- `PanelState_ClearOnChange` writes 0 (`xor WA,WA` then `ld (0x207E),A`) whenever `UI_ScreenLatch`
  differs from `UI_ScreenLatch_Previous`, so a new screen always opens on stage 0.
- The screen objects' Button methods pick the button map from it:
  `ld XIX,ButtonTable_<screen>_StageZero / cp (0x207E),0 / jr z / ld XIX,ButtonTable_<screen>_StageNonZero`.
  Those labels, and the key handlers named after them, carried the address as `_207EZero` /
  `_207ENonZero` until `scripts/renaming/rename_wsa1_screen_stage_labels.sed` renamed them.

⚠ **Not established:**

- On screens that are not job screens, the byte is that screen's own phase, and what each value
  means there is open. Examples:
  - `Paint_PowerOnSplash` writes 0 then 1 between its two splash images;
  - `PanelTimer_Repeat20AB` increments it;
  - `sub_FA14C2` writes 2 together with screen request 0xAB.
- The name is therefore `UI_ScreenStage`, not `..._Confirm`.

## 2. `UI_ScreenFlags` (0x2095): request and repaint flags of the panel task

The main loop runs `PanelTask_Step` when either `(0x2095)` or `UI_Request_Hi` is non-zero
(0xF82100: `cp (0x2095),0 / jr nz` then `cp (0x2071),0 / jr z`). So any set bit here is pending
panel work.

Census, per bit. `and (XIX),0xEF` through `lda XIX,(0x2095)` in `Paint_MidiTotalMode`,
`Paint_MidiRealtimeMessages` and one more Paint routine is 3 further bit-4 clears; these appear in
the census as `byte lda x3`.

| bit | set | clear | test | meaning |
|---|---|---|---|---|
| 4 | 86 | 14 | 47 | **repaint the current screen in place** |
| 0 | 1 | 2 | 2 | a screen request allowed past the `UI_RequestBits` bit 4 lock |
| 1 | 1 | 1 | 1 | do not record the return screen in (0x20A2) for this request |

**Bit 4.**

- **Who sets it.** The value-change handlers, e.g. `SoundBank_Select*`, `*_StepItem`,
  `*_AdjustBank` and `S0ngSelectName_NextSong`.
- **How it reaches the redraw.** `PanelState_SyncScreenFlags` copies it into `UI_Request_Hi` bit 4, and
  `UI_Request_Hi` is published into (0x2072) when quiet. `PanelScreen_RunRedraw` re-Enters the
  current screen on (0x2072) bit 4.
- **What the Paint routines do with it.** When the bit is set, the Paint routines skip the screen
  clear: `bit 4,(0x2095) / jr nz` over `PromB_LCD_ScreenRedraw_Begin` in `Paint_S0ngSelectName` and
  `Paint_StepRecordPartSelect`, and over `LCD_ScreenRedraw_Begin` in prom_b's `Paint_SongClear`.
- **Who clears it.**
  - `PanelTask_Step` clears it right after `PanelScreen_RunRedraw` (0xF86087).
  - Every `InstallPainter_*` and Paint routine that sees a NEW screen (`UI_ScreenId` or
    `UI_ScreenLatch` differs from its previous value) clears it too. A fresh screen is therefore
    drawn in full.

**Bits 0 and 1.** `PanelState_CheckRequestAllowed` sets both together (`or (0x2095),0x03`). It does
so when `UI_Request_Hi` bit 6 is set and the requested id (the low byte of `UI_Request`) is one of
the two `PanelState_AllowedScreenIds`.

- **Bit 0.** `PanelScreen_ApplyRequest` and `PanelScreen_ApplyRequestForced` test it: with bit 0
  set they skip the `UI_RequestBits` bit 4 test that otherwise blocks the request.
  - `PanelState_ClearOnChange` clears it on every pass.
  - `PanelState_CheckRequestAllowed` clears it when (0x2092) bit 0 is clear and `UI_RequestBits`
    bit 4 is set.
- **Bit 1.** `PanelScreen_ApplyRequest` tests it before saving the current screen id into (0x20A2):
  with bit 1 set it does not save it. It then clears bit 1 (`and (0x2095),0xFD`).

⚠ Not established: what the two `PanelState_AllowedScreenIds` screens are, and why they need the
override.

## 3. Two prom_a headers corrected

- **`PanelState_SyncScreenFlags`.** The header said that bit 4 of (0x2095) is cleared "when bit 4 of
  (0x2071) is clear". The code does the opposite:
  - `bit 4,(0x2071) / jr z` jumps over the `and (0x2095),0xEF` when the (0x2071) bit is clear;
  - so (0x2095) bit 4 is cleared only when (0x2071) bit 4 is already set, i.e. when the request
    is already in flight.
- **`PanelState_CheckRequestAllowed`.** The header said "bit 7 of (0x2071)" and cited
  "`bit 0x07,W` at 0xF86B1F". The instruction there is `c8 33 06`, `bit 6,W`, and W is the high
  byte of `ld WA,(0x2070)`, i.e. (0x2071) bit 6.
