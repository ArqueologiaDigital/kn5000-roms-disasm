# KN5000 routine names from callers, with evidence (2026-10-06)

**What question this answers.** Routines that were renamed from a generic label (`X_Helper7` is just "a piece of
X"): what is each name based on?

Read-only triage passes took the `_Helper` routines of v10 ranked by named callers
(`~/compartilhado/research-scratch`, `rank_helpers.py`). For each routine the pass read the callers and then the
body, and gave a name only when the two agreed. Every record in `proposals-*.json` has `old`, `new`, a `header`
(what it does, with its basis) and `evidence`: the `file:line` instructions, paths relative to `v10/maincpu`, with
at least one caller site. Refused records keep the reason and a mechanical description of the body.

**Apply** with `scripts/renaming/apply_kn5000_naming_proposals.py TAG proposals-*.json --apply`. It works on v10,
v9 and v7, which share the names. Then run `make gate-all` and `l2_symbol_reference.py --regen` / `--check`.
