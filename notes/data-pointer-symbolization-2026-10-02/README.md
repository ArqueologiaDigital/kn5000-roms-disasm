# Numeric ROM addresses in data tables (`.long 0x00EB2AAE`)

`scripts/analysis/semantic_debt_dashboard.py`'s `numaddr` counts numeric own-ROM addresses in
INSTRUCTION operands only.  Data tables hold them too, and nothing measured them.

| script | question it answers | run |
|---|---|---|
| `long_pointer_census.py` | For every numeric own-ROM value on a `.long`/`.4byte`/`.word` line: is an ELF symbol there already, does a source line start there, or is it inside an `.incbin` / a list / an instruction? (census marker mirror) | `make all; python3 notes/data-pointer-symbolization-2026-10-02/long_pointer_census.py --tree v10` |

2026-10-02, v10 (HEAD 96d30767 + the claims-review batch): 1,028 values -- 847 inside an
`.incbin` slice, 127 at an existing symbol (mostly the absolute `.set NAME, 0xADDR`
constants of `kn5000_v10_program.s`, 599 of them), 41 at the start of a data line, 13 at the
start of a code line, 0 inside an instruction.  By file: effects_sequencer_screens.s 643,
disk_menu_file_io_screens.s 127, widget_names_charmap.s 72, technichord_part_settings.s 64,
style_bitmaps.s 53.  Most of the in-`.incbin` targets are NAKA widget records that the
registered Viewable tables point at.

After `scripts/tools/label_naka_records.py` (same day, notes/naka-record-labels-2026-10-02/):
422 -- 284 in-incbin, 118 labelled (the absolute `.set` constants), 13 line-start-code,
7 line-start-data.
