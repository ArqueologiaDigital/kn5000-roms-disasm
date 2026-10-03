# Far pointers into the middle of objects (round 2, 2026-10-02 evening)

`before_<tree>.json`: symbolize_far_pointer_pushes.py's report before this round; rows
"inside <object>+<offset>" are the input of `scripts/tools/label_far_pointer_targets.py`,
which places `<Reader>_Str_<Text>` / `<Reader>_Data` at each pointer (scripts/tools/
place_labels.py), after which symbolize_far_pointer_pushes.py --apply spells the pushes.

| tree | distinct targets | placed (line / slice / list) | inside an instruction, left | pushes spelled |
|---|---|---|---|---|
| v10 | 94 | 13 / 24 / 25 | 32 | 99 |
| v9  | 99 | 12 / 24 / 30 | 33 | 82 |
| v7  | 99 | 12 / 23 / 32 | 32 | 76 |

Then v7 harmonized with v10 once more (2 renamed, 1 inserted; report
notes/version-label-harmony-2026-10-02/v7_from_v10_round4.json).

## CORRECTION (2026-10-03): some of those "pointers" were colour pairs

A `pushw HI / pushw LO` pair before a call of the DrawString family is that renderer's 32-bit
COLOUR argument, not a far pointer: the values are (0xff, 0xf5), (0xfb, 0xf5), (0xff, 0xf7),
(0x00, 0x07), (0xff, 0x08) -- palette indices; DrawStringReverse is documented as drawing "with
swapped fg/bg colors".  The far-pointer passes had spelled 35 such pairs in v10 (13 in v9, 9 in
v7) as `Label@hi16/@lo16` and placed `<Reader>_Data` labels on code lines for some of them
(PmBank_DrawRegionInfo_Data, NoteEditBox_EventDispatch2_Data, PmBank_OnPaint_Data, ...).
scripts/tools/unsymbolize_color_pairs.py restored the numbers with a comment; the labels left
unreferenced were removed; symbolize_far_pointer_pushes.py and the dashboard's numfar now skip
pairs that feed a DrawString* call.
