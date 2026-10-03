# SX-WSA1R routine naming, round 1 -- STOPPED by the owner after 8 of 43 slices (2026-10-02)

**Question:** can the 6,186 address-named placeholder routines (`sub_XXXXXX`) of the SX-WSA1R
sources get names that say what they do, each backed by evidence that can be cited?

**State:** the owner stopped the workflow because it was too expensive. Eight `prom_a` slices
had finished naming. **None of their packs was verified, and none is applied.** The pipeline
queued all 43 namers ahead of the verification stage, so no skeptic ran.

| slice | routines in slice | renames proposed | left unnamed |
|---|---:|---:|---:|
| prom_a-s00 | 146 | 118 | 28 |
| prom_a-s01 | 146 | 122 | 24 |
| prom_a-s02 | 146 | 125 | 21 |
| prom_a-s03 | 146 | 110 | 36 |
| prom_a-s04 | 146 | 90 | 56 |
| prom_a-s05 | 146 | 112 | 34 |
| prom_a-s06 | 146 | 142 | 4 |
| prom_a-s08 | 146 | 110 | 36 |
| **total** | | **929** | |

Every pack passes `scripts/tools/apply_label_edits.py --check`: no collision, every OLD name is
defined exactly once, and no chain. That is a MECHANICAL check only. The names are proposals
with one-line evidence each, for example `sub_F99F24 -> Paint_MidiMenu` (Enter of screen 0x70,
title op 0x1C "MIDI"). Nobody has independently re-derived them.

## Files

| file | what it is |
|---|---|
| `packs/<slice>.json` | edit packs in `apply_label_edits.py` format, plus `left_unnamed` (with reasons), the namer's `notes` (patterns, misframing suspicions, cross-slice leads) and `"verified": false` |
| `worklist_*.json`, `AT_COMMIT` | the input: `scripts/analysis/routine_naming_worklist.py` output at the commit in AT_COMMIT, sliced (prom_a 26 slices, prom_b 16, plus prom_c and kernel) |
| `wsa1-naming-r1.js` | the workflow script. Its verify stage never ran: put the verifier first in the queue, e.g. by running naming and verification as separate workflows |

## To use these packs later

1. Verify first: an independent reader re-derives a sample of each pack, at least 40 renames
   and every name that asserts a specific screen, message or device, and drops the rejected
   ones.
2. Apply one pack at a time with `python3 scripts/tools/apply_label_edits.py <pack>`, then run
   `make gate-all`. Structural children (`sub_X_Join`, ...) follow their parent automatically.
3. Re-derive the `T_` trampoline names in prom_b with `wsa1/notes/prom_b_thunks_round6.py`,
   which only promotes from CONTENT targets.
4. Regenerate the worklist: routines whose callees are now named become "ready" for round 2.

## Applying them (from 2026-10-03)

The packs were made at AT_COMMIT; later work renamed some of the same routines, and the packs listed
prom_a only although prom_b's thunks reach prom_a's names through `.set sub_X, 0xX` aliases.  So:

1. `rebase_packs.py` -> `rebased/<pack>.json`: drops renames whose OLD name is gone, adds the
   `also` list (prom_b and both linker scripts) that `scripts/tools/apply_label_edits.py` now
   understands -- the renames reach those files, where OLD may only be a `.set` alias.
2. `review_sheet.py <pack> FROM TO` prints each rename with the routine as it stands, the display
   lists / descriptors it loads, and its callers.  An independent reader goes through it.
3. `verdicts/<pack>.json` records what was read, how, and what was rejected or amended;
   `apply_verdicts.py <pack>` writes `accepted/<pack>.json` with that record as `"verified"`.
4. `python3 scripts/tools/apply_label_edits.py accepted/<pack>.json`, then `make gate-all`.  The
   sed it writes (`scripts/renaming/rename_wsa1-naming-r1-<pack>.sed`) is also run over prose
   that quotes the old names (prom_c's preset_bank.s comments, notes docstrings).
5. Step 3 of the list above (`wsa1/notes/prom_b_thunks_round6.py --apply`) currently REFUSES:
   prom_b was split into include files after that tool was written, and it writes the whole image
   into the master; it needs `asm_source.edit_image()`.  Not done.

| pack | rebased renames | read | rejected | applied in |
|---|---:|---:|---:|---|
| prom_a-s00 | 109 | 109 | 0 | 8180b9b1 |
| prom_a-s01 | 102 | 102 | 0 | bcc02630 |
| prom_a-s02 | 100 | 100 | 0 | 42ab99c7 |
| prom_a-s03 | 93 | 93 | 0 | 295213fd |
| prom_a-s04 | 60 | 60 | 0 | 818baaed |
| prom_a-s05 | 104 | 104 | 0 | 591c85fa |
| prom_a-s06 | 120 | 120 | 0 | 4305cf6e |
| prom_a-s08 | 99 | 99 | 0 | 94f69793 |

Total 787 renames, all read, none rejected.  prom_a's `addrlbl` (semantic_debt_dashboard.py) went
3,177 -> 2,390.  Slices s07 and s09-s25 of prom_a, prom_b's 16 slices, prom_c and the kernel were never named.
