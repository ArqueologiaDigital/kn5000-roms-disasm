# R3 refusals that control flow refutes (2026-10-02/03)

`trace_r3_sites.py` (usage in its docstring) traces control flow over one source file's
address range, entering only at addresses some `call`/`calr` of the tree targets, and lists the
"absurd block" (R3) refusals of symbolize_numeric_branches.py whose branch AND target are
reached as instruction starts.  `trusted_<file>_<tree>.json` are those lists, as applied with
`symbolize_numeric_branches.py --trust-traced` (every other rule still applies; `--verify`
re-mirrors the tree and compares the dump: PASS each time).

| tree | accompaniment_engine.s: R3 sites / traced / applied | other files, applied |
|---|---|---|
| v10 | 153 / 54 / 54 | 17 (audio_control_engine 3, flash_floppy_handlers 8, sound_editor_ui 3, note_voice_mapping 3) |
| v9 | 153 / 54 / 54 | 17 |
| v7 | 445 / 362 / 362 | 29 |

Every trace reported 0 conflicts.  The remaining refusals are in code no call reaches (jump
tables and indirect calls are not followed), or in data.
