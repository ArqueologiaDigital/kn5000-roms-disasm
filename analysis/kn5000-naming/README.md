# KN5000 routine names from callers, with evidence (2026-10-06)

**What question this answers.** Routines that were renamed from a generic label (`X_Helper7` is just "a piece of
X"): what is each name based on?

Read-only triage passes took the `_Helper` routines of v10 ranked by named callers
(`~/compartilhado/research-scratch`, `rank_helpers.py`). For each routine the pass read the callers and then the
body, and gave a name only when the two agreed. Every record in `proposals-*.json` has `old`, `new`, a `header`
(what it does, with its basis) and `evidence`: the `file:line` instructions, paths relative to `v10/maincpu`, with
at least one caller site. Refused records keep the reason and a mechanical description of the body.

**Apply** with `scripts/renaming/apply_kn5000_naming_proposals.py TAG proposals-*.json --apply`. It renames v10 only,
because an old generic label of v9 / v7 need not sit on the same code. Then `make all` and
`scripts/renaming/harmonize_version_labels.py --to v9 --apply` / `--to v7 --apply`: they carry the new names by address
correspondence with a byte proof. Then run `make gate-all` and `l2_symbol_reference.py --regen` / `--check`.

**Batches e-h** (`proposals-2026-10-06-helpers-{e,f,g,h}.json`): the next 120 `_Helper` routines with a named caller,
minus the ones refused before; nearly all have one named caller. 94 named, 26 refused. The harmonizer carried 93 to v9
and 50 to v7 (the rest sit where v7's code differs).

`probes/rhythm_probe.py` answers what byte +976 (0x3D0) of each rhythm header in the Rhythm Data ROM holds: the
time-signature index that `Rhythm_LoadCurrentTimeSig` copies to RAM 0x34F0. Run it from the repository root on a
built tree. On 2026-10-06 it printed 201 rhythms: 7 for 186 of them, 6 for 13, and 9 and 11 once each.
