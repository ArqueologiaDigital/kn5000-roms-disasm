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
| `trusted_seed_acc_batch2_<tree>.json` | 18 blocks of accompaniment_engine.s (`seeds_acc_batch2_v10_v9.txt`) | 18 / 18 / 11 (`seeds_acc_batch2_v7.txt`) | 51 / 51 / 13 | 51 / 51 / 13, `--verify` PASS |

The seed was chosen because the block is coherent without the trace. All six `calr`s resolve to
one routine. That routine's two `calr`s resolve to a nibble splitter and a bare `ret`, and the
digit table "0123456789ABCDEF" follows.

### How the batch-2 seeds were chosen

`list_r3_clusters.py` prints each cluster of R3 refusals with the code around it and with line addresses.
Every cluster was read before seeding.  Seeded: blocks that are coherent code, i.e. a loop's branch lands on
its own head, all calls go to existing routines, and the flags a branch tests are set by the instruction
before it.  Not seeded:
- tables decoded as code: a run of `xx 56 f6 00` pointers (0xF65657), bit masks (0xF6A55D), and byte tables
  indexed by (0x34D6) (0xF65CAF);
- a garbage decode (`ld xsp,0xca041ef1`, 0xF5AACD);
- a loop that branches on flags no instruction set (`ld a,(xiy)` / `jr nz`, 0xF63813);
- a block whose entry is unclear (0xF65AF6).

v7's seeds are v10's mapped through the nearest label that both trees have, kept only when v7's instruction at
the mapped address has the same mnemonic.  Seven did not map, because v7 still holds those blocks as `.byte`.
