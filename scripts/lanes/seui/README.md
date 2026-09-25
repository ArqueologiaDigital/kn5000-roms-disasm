# Lane `seui` (2026-09-25 semantic push) -- sound-editor UI files

Owned files (v10, v9 and v7 copies): `audio/sound_editor_ui.s`,
`sound_editor_routines.s`, `sound_editor_screens/*`, `semenu_routines.s`,
`sndparam_routines.s`, `sndparam_records/*`.

| script | question it answers | command |
|---|---|---|
| `se_gfx_wrappers_probe.py` | Are the 17 `SeGfx_*` wrappers (ex `SeMenu_NameEditor_*`) what their names say? Reads both ScreenData handler tables out of each ROM and checks every wrapper's single `call` (decoded by MAME unidasm) against the table entry its name claims, and its use of the RAM record buffer 0x6CA. | `python3 scripts/lanes/seui/se_gfx_wrappers_probe.py` (needs the three `.llvm.elf`) |
| `seui_census_summary.py` | How much of this lane's files is CODE / KNOWN-A / KNOWN-B / UNKNOWN / research target, plus data-as-code markers and v7 romslice bytes? | `python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json X.json && python3 scripts/lanes/seui/seui_census_summary.py X.json` |
| `seui_amap.py` | Which source line emits which address, for v10, v9 AND v7 (reuses the census's proven-inert mirror)? | `python3 scripts/lanes/seui/seui_amap.py --image v7 --out amap.json` |

The rename itself is `scripts/renaming/rename_seui_gfx_wrappers.sed` (applied to
the three `sound_editor_ui.s`).  `scripts/renaming/rename_maincpu_seq_init_labels.py`
still holds the old `SeMenu_NameEditor_*` names: it is the historical record of
an earlier pass and is deliberately left as it was.
