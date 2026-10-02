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

## The absolute `.set NAME, 0xE.....` constants (same day)

`scripts/tools/materialize_address_sets.py --tree <v> --apply --report OUT.json`; reports
`address_sets_<tree>.json`.  Each maincpu top-level source ended with ~600 "Labels emitted as
.set (exact addresses from ORG/name)" -- ROM addresses as numbers, left by the ASL-to-LLVM
conversion.

| | v10 | v9 | v7 |
|---|---|---|---|
| constants | 600 | 599 | 598 |
| became a label (slice cut / in front of a line / list cut) | 348 / 149 / 3 | 348 / 151 / 1 | 351 / 143 / 1 |
| a label was already there: constant retired into it | 62 | 61 | 65 |
| ... the label (structural) took the constant's name instead | 15 | 15 | 15 |
| used, inside a string or instruction: now `Label + offset` | 6 | 6 | 6 |
| unused and inside a line (bitmaps, mid-signature): deleted | 14 | 14 | 14 |
| region constants kept (PROGRAM_FLASH__BASE_ADDR, NakaData_RomEnd) | 2 | 2 | 2 |
| kept as a number (no label on its line) | 1 | 1 | 1 |

Which name survives when a label is already at the address: the constant's, only when the
label is structural (`FDC_CMD_EXEC_Helper4`), the constant is not, and code uses the constant
or ../technics-docs documents it (fdc-subsystem.md, reverse-engineering.md: FDC_DRIVE_DETECT,
FDC_POST_OP ...).  An unused, undocumented constant never wins -- many are the ASL era's
"forward references to helper routines in raw byte sections"
(archive/asl/maincpu/fdc_routines.asm:1113), named before anyone disassembled them; and two
NakaWidget_* names are settled by the record's captions (NakaWidget_Perf2Flute is retired: the
record's caption is "Guitar", the firmware's name "DemoSong8").

Numeric own-ROM `.long` values in v10 after both passes: 304 (from 1,028).
