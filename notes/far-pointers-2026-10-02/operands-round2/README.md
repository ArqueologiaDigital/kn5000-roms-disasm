# Numeric operands at addresses with no label (2026-10-02 evening)

`before_<tree>.json`: scripts/converters/symbolize_kn5000_rom_operands.py --report before the
round ("no-symbol" rows: `lda xix, 0xed9d30` where nothing is labelled).
scripts/tools/label_far_pointer_targets.py placed a label at each (`<Reader>_Code` at a code
line -- a handler address loaded as a value, purpose not established; `<Reader>_Str_<Text>`;
`<Reader>_Data`), then symbolize_kn5000_rom_operands.py --apply:

| tree | distinct targets | placed (line / slice / list) | inside a line, left | operands spelled |
|---|---|---|---|---|
| v10 | 74 | 35 / 33 / 1 | 5 | 74 |
| v9 | 75 | 35 / 33 / 1 | 6 | 74 |
| v7 | 155 | 84 / 40 / 11 | 20 | 165 |
| hdae5000 | 10 | 6 / 0 / 0 | 4 | 7 |

v7 harmonized with v10 again afterwards: 1 renamed (report
notes/version-label-harmony-2026-10-02/v7_from_v10_round5.json).
