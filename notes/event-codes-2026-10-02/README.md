# Event-code and object-id catalog (2026-10-02)

**Question:** the KN5000 firmware passes 32-bit codes in 0x01000000..0x01FFFFFF to its object
system (`cp xbc, 0x1e10000`, `ld xbc, 0x1c00001`, `ld xhl, 0x01020003`). What does each one
mean, and what should it be called in the source?

**Answer, in one sentence:** the firmware names almost all of them itself. NAKA registers
per-module name tables next to its dispatch tables. Code `0x01Cm00nn` is entry nn of module m's
**ResEvent** table (`EV_*` strings, slot 0x1C0+m). `0x01Em00nn` is entry nn of its
**ResMethod** table (`MT_*`). `0x010m/012m/014m/016m/0180xxxx` are entries of its Function /
ApFunction / MainFunction / Class / Mode object tables, which also have name tables. The
catalog gives each value the firmware's own name, as `EVT_*` / `NAKA_*` constants with the
original string in the comment (CLAUDE.md policy 5: original names stay in comments).

Spot-checked independently against the v10 ROM:
- ResMethod 0x1E0 is `RegObjTable 0x160000d, 0xfa5948, 0xeafa6c, 0xeaebb2, 0x1e0`. Its count
  word at 0xEAFA6C is 188, and the strings via u32 table[k] are: 0 `MT_GetClassSp`,
  1 `MT_GetParentClassSp`, 2 `MT_GetProcedureSp`, 3 `MT_GetInstanceSizeSp`,
  0xD `MT_GetPropDataSp`, 0xE `MT_GetPropDataCountSp`, 0xF `MT_GetInstance`,
  0x14 `MT_CheckClass`, 0x15 `MT_GetName`, 0x8F `MT_GetSelectedCel`, 0x9C `MT_SetVisible`,
  0xA1-0xA3 `MT_GetBitmapData/Width/Height`.
- ResEvent 0x1C0 is `RegObjTable 0x160000c, 0xfa58fb, 0xeaebb0, 0xeae7b6, 0x1c0`. Its count
  is 60, and the strings are: 1 `EV_SHOW`, 2 `EV_HIDE`, 8 `EV_SWON`, 0xD `EV_DRAW`,
  0xF `EV_PARADRAW`, 0x13 `EV_ACTIVATE`, 0x16 `EV_INTERRUPT_TITLE`, 0x39 `EV_NEW_TITLE`.

## This corrects every one of the 26 constants that existed before

They were named from one observed use each, and the firmware's names say otherwise. A few
examples:
- `EVT_IDENTITY` (said "returns XWA unchanged") is MT_GetClassSp.
- `EVT_GET_HL` is MT_GetParentClassSp.
- `EVT_KEYPRESS` is MT_GetPropDataSp.
- `EVT_RETURN_ZERO` is MT_GetInstance.
- `EVT_MENU_OPEN` ("DISK MENU screen displayed") is EV_SHOW.
- `EVT_ACTIVATE` ("DISK MENU entry selected") is EV_SWON, posted for every panel switch press.
- `EVT_DISPLAY_CALLBACK` / `EVT_DISPLAY_UPDATE` are the HD-AE5000's EV_SeqStop / EV_TICKS.
- `EVT_GRIDCHECK_RESP_A/B` are MT_PanUp / MT_RLmtUp: composer-set grid requests, not widget
  responses.

All 26 are renamed (`scripts/tools/apply_event_constants.py --rename-existing`, through
`scripts/renaming/rename_event_constants.sed`). Their definition comments are rewritten too,
because the old ones described the wrong names.

## How it was made

`event-code-catalog.js` (the exact workflow) ran 8 read-only researchers, one per value group
(class ids; 0x01A0; 0x01C0; 0x01C1-01CA; 0x01E0 low/high; 0x01E1-01E7; 0x01E8-01EF). Each
researcher was followed by an independent skeptic, who re-derived at least 30 names from the
handler (where the code compares equal) and a sender. Skeptics checked 538 names and rejected
10, all of them name collisions across groups or sibling-naming inconsistencies. Their better
names were applied. Two remaining event/method pairs that shared a name (`EV_LSWDATA` /
`MT_LswData`, `EV_RAMDATA` / `MT_RamData`) were resolved like the skeptics' other cases: the
method twin gets `_REQ`.

| file | what it is |
|---|---|
| `catalog.json` | the final catalog: value, name ("" = not established, or not an event at all), meaning, evidence (handler + sender by label and address), confidence, and the skeptic's note where one rejected the first name |
| `research_and_verdicts.json` | every researcher's and skeptic's full return, including each group's `existing_conflicts`: source comments, labels and technics-docs text that the firmware names contradict |
| `worklist_v10_hdae.json` | the input: every in-range value used as an instruction operand in v10 + hdae5000, with occurrence counts and up to 12 sites |
| `event-code-catalog.js` | the workflow script |

Of 727 values, 725 are named (723 distinct names plus the two `_REQ` twins). The 2 unnamed ones,
and the entries whose meaning says "not an object id", are coincidental constants that only look
like codes, for example the rhythm-ROM header word 0x01008305 and an audio-mixer init word
0x0101001F. The substitution tool skips unnamed values, so those stay numeric.

## Follow-up the catalog makes possible (not done here)

- technics-docs `event-codes.md` should list the full catalog with the firmware's names. Its
  "0x01E0 = lifecycle", "0x01E4 = widget responses" framing is wrong (see each group's
  `existing_conflicts`).
- Labels and headers that the conflicts sections name as contradicted: `SoundCtrl_SendCommand` is
  the 0x01C00016 title request; `UI_PostModeChangeEvent` posts a title request; the FDC header's
  `ei 4`/`di 4` comment; HD-AE5000 SEL_DIR arm comments; `NAKA_TYPE_*` in macros.s, whose low
  bytes the firmware's class names contradict for 8 of 11. These go to the Wave 3b lanes.
