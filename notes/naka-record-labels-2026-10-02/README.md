# Every NAKA widget record gets a label (2026-10-02)

Tool: `scripts/tools/label_naka_records.py` (placement: `scripts/tools/place_labels.py`).
Run: `make all; python3 scripts/tools/label_naka_records.py --tree v10 --apply --report OUT.json`.
`report_<tree>.json` is the run's per-record report (renamed / kept / placed, with captions).

The 209 registered Viewable tables point at 3,340 widget records per tree (v10, v9 and v7
alike).  Before: 507 had a label; the tables pointing at the rest were `.long 0x00E2841C`
numbers or `.incbin` bytes.

| per tree | v10 | v9 | v7 |
|---|---|---|---|
| record already labelled, kept | 452 | 452 | 452 |
| NakaWidget_* label contradicting the firmware's own name, renamed | 33 | 33 | 33 |
| ... kept because every caption word supports it | 22 | 22 | 22 |
| label placed by cutting an `.incbin` slice | 2,680 | 2,680 | 2,680 |
| label placed in front of a line | 139 | 139 | 139 |
| label placed by cutting a list | 14 | 14 | 14 |
| numeric `.long` values that became a label | 606 | 598 | 599 |

Names: `NakaWidget_<ResName>` where the firmware's ResName table (registry slot + 0x300)
names the element (600 records); otherwise `NakaWidget_<Screen>_<k>_<Class>` -- Screen is the
ResName of element 0 of the same table (151 of 209 tables), else `<Module>View<slot>`; k is
the element index (object id 0x01000000 | slot << 16 | k); Class is the record's class.

The 33 renames (`scripts/renaming/rename_naka_records_<tree>.sed`) are labels whose names
described something else: v10's NakaWidget_SmfDpFileList is an AcMuteToggleBox with captions
"ON"/"OFF" that the firmware names "SMFMuteSw"; NakaWidget_TrAsPresetGmRec / _Measure sat one
entry off ("TrAsPsTechSel" = "TECHNICS MULTI RECORDING", "TrAsPsGmSel" = "GM MULTI
RECORDING"); NakaWidget_Perf2Guitar's caption is "Piano".  A label is kept when every caption
word of 3+ letters appears in it by its first three letters (NakaWidget_PerfMainMedley,
caption "Main Medley", firmware "DemoSong0").

Numeric `.long` ROM addresses in v10 (notes/data-pointer-symbolization-2026-10-02/
long_pointer_census.py): 1,028 before, 422 after -- 284 inside `.incbin` slices (strings and
tables other than records), 118 at absolute `.set NAME, 0xADDR` constants, 20 at line starts.
