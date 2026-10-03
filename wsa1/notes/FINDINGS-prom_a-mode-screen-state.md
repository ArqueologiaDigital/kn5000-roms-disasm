# prom_a: SOUND / COMBINATION MODE screen state (2026-10-03)

From round-1 packs prom_a-s01 / s02 / s03 (read and applied 2026-10-03; their evidence lines are in
`notes/lanes/wsa1-naming-r1-2026-10-02/accepted/`), re-checked against the code.

## 1. The sound selection and the group screens

| address | name | holds | evidence (prom_a) |
|---|---|---|---|
| 0x216A | `SoundSel_Bank` | the selected bank: R1 0x00, R2 0x01, U1 0x08, U2 0x09, RD 0x20, UD1/UD2 0x28/0x29, E1 0x10, RE-MAP 0x18-0x1A | SoundBank_SelectR1OrU1 .. _SelectExt write it; PanelLed_ShowBank lights it; SoundBank_IsReMap tests 0x18-0x1A |
| 0x2169 | `SoundSel_Group` | the selected group | SoundGroup_StepSelected; DisplayHold_ShowGroupNumber shows it + 1 |
| 0x216B | `SoundSel_Member` | the selected member | SoundGroup_LoadSelectionFromPart / _FromGlobal load all three (part record +0x3D / +0x3B / +0x3C, or 0x7F0A / 0x7F08 / 0x7F09) |
| 0x2675 | `SoundGroupMenu_Highlight` | the group the menu's box is drawn on | SoundGroupMenu_MoveGroupHighlight, CombinationGroupMenu_MoveHighlight erase the old box, fill (0x2169)'s, store it |
| 0x2670 | `GroupMembers_Page` | the page of members shown (8 per page) | GroupMembers_ShowPageOfTwo / _ShowPageOfMany |
| 0x267F | `DisplayHold_Flag` | bit 0: DISPLAY HOLD on | SoftKeyCol7/8_GroupSoundDisplayHold `xor 1`; DisplayHold_DrawHoldHighlight; GroupSoundDisplayHold_PickSound returns to the mode screen unless it is set |

## 2. COMBINATION MODE

| address | name | holds | evidence (prom_a) |
|---|---|---|---|
| 0x2687 | `CombinationMode_Page` | 0 page 1, 1 page 2 | PageKey_C0mbinati0nM0de; ScreenButton_C0mbinati0nM0de picks the button table by it |
| 0x2678 | `CombinationMode_EditRow` | page 2's row being edited: bit 0 SOUND, bit 3 INT, bit 2 PAN, bit 1 VOL | LcdKeyRow1..4_C0mbinati0nM0de_Page2 set it; C0mbinati0nM0de_EditSelectedRow dispatches on it |
| 0x267D | `CombinationMode_Solo` | bit 0: SOLO | LcdKeyRow1_C0mbinati0nM0de_Page2 toggles it (SoloIndicatorOn / Off); ScreenLeaveBody_C0mbinati0nM0de clears it |
| 0x267E | `CombinationMode_ShownPart` | the part the PART box was last drawn for | C0mbinati0nM0de_ShowSelectedPart (skips while (0x2250) equals it) |
| 0x2676 | `ModeScreen_DirtyFields` | page-1 value fields to redraw, one bit each | Paint_SoundModeFields / C0mbinati0nM0de_RepaintPage1Fields draw the fields whose bit is set; UiEvent_MarkRedrawFromPartClass sets them |
| 0x2677 | `ModeScreen_DirtyFields2` | more such bits (0x18 / 0x19 / 0x1A events set bits 0-2) | UiEvent_MarkRedrawFromClass20Block |
| 0x2679 | `CombinationMode_DirtySound` | page 2: parts whose SOUND cell is to be redrawn | UiEvent_MarkPartRedrawBits (code 0); Paint_C0mbinati0nM0dePage2Fields -> FieldRedrawPtrs_F91865 (DrawPartNSound) |
| 0x267A | `CombinationMode_DirtyInt` | parts whose INT cell is to be redrawn | code 0x0D -> FieldRedrawPtrs_F91885 (DrawPartNInt) |
| 0x267B | `CombinationMode_DirtyPan` | parts whose PAN cell is to be redrawn | code 8 -> FieldRedrawPtrs_F918A5 (DrawPartNPan) |
| 0x267C | `CombinationMode_DirtyVol` | parts whose VOL cell is to be redrawn | code 3 -> FieldRedrawPtrs_F918C5 (DrawPartNVol) |
