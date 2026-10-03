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

## Seeded blocks (2026-10-03)

`--seed ADDR[,ADDR...]` adds entry addresses for a block that no `call` reaches but that was read
by hand as code. The trace still has to reach each R3 site and its target from there, so a seed
vouches only for the block's first instruction.

| file | block | seed (v10 / v9 / v7) | R3 sites reached | applied |
|---|---|---|---|---|
| `trusted_seed_cmstep_debug_<tree>.json` | `CmStep_DebugShowHexBytes` (accompaniment_engine.s) | 0xF6304A / 0xF6304A / 0xF62C46 | 11 / 11 / 11 | 11 each, `--verify` PASS |

The seed was chosen because the block is coherent without the trace. All six `calr`s resolve to
one routine. That routine's two `calr`s resolve to a nibble splitter and a bare `ret`, and the
digit table "0123456789ABCDEF" follows.
