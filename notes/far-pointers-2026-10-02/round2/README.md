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
