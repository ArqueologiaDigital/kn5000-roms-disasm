# Naming pipeline (2026-10-05 .. 2026-10-07)

The tools that drove the caller-based naming waves of the semantic push: KN5000 helper / switch-case /
single-image / generic-label batches (`analysis/kn5000-naming/`) and WSA1 waves 1-11
(`wsa1/notes/naming-pilot-2026-10-06/`). Copied here from the session scratch so the process can be re-run;
they keep their scratch working directories (`~/compartilhado/tmp/kn5000-naming/`, `~/compartilhado/tmp/wsa1-triage/`)
for rankings, batch files and agent proposals, which are inputs and outputs, not records.

The method: a ranker lists generic or positional labels with the evidence that can name them (named callers,
referrers, table indices); batches go to read-only agents with a prompt from `prompts/`; the proposals are
validated, copied into the repo as the evidence record, then applied by a renaming script; derivative passes and
the version harmonizer follow; the gates prove nothing moved.

| script | question it answers / job | run |
|---|---|---|
| `kn5000_rank_helpers.py` | which v10 `_Helper` routines have named callers | `python3 .../kn5000_rank_helpers.py` -> `helpers.json` |
| `kn5000_rank_generic.py` | which v10 `_<Suffix>` labels (default `_Entry`) have named callers | `python3 .../kn5000_rank_generic.py Entry` |
| `kn5000_validate_proposals.py` | do proposals `proposals_kbatch_<b>.json` rename existing labels to names free in v10/v9/v7, unique, non-generic, unused by earlier proposals | `python3 .../kn5000_validate_proposals.py o,p,c9` |
| `wsa1_rank_routines.py` | which prom_a/prom_b `sub_` routines have named callers (through T_ thunks too) | run from `wsa1/` -> `ranked.json` |
| `wsa1_build_rename_args.py` | validate a WSA1 wave's proposals and build `old=new\|header` args | `WSA1_WAVE=11 python3 .../wsa1_build_rename_args.py a11,t11 --args` |
| `wsa1_rename.py` | one WSA1 rename step: both images and the notes that quote the names, an optional header, `scripts/renaming/<SEDNAME>.sed`, and the declarations the preservation checks need | `python3 .../wsa1_rename.py SEDNAME 'old=new\|header' ...` (args from a JSON list via subprocess when headers contain spaces) |

Applying, in the repo: `scripts/renaming/apply_kn5000_naming_proposals.py` (v10 or `--tree` for single images),
`rename_orphan_locals.py` (`--misplaced` too), `name_se_screen_records.py`, `harmonize_version_labels.py --to v9/v7`
(re-run until it settles); WSA1 derivative passes in `wsa1/notes/` (`prom_b_thunks_round6.py --pending-args /
--mark SED / --fix-ranges SED`, `prom_ab_wrapper_names.py`, `wsa1_display_list_drawer_names.py`,
`wsa1_exact_copy_names.py`, `prom_b_oldcopy_follow.py`). Checks: `make gate-all`, `l2_symbol_reference.py --check`,
`assert_c_comments_preserved.py`, `wsa1/notes/prom_a_preservation_check.py --ref HEAD`,
`wsa1/notes/prom_b_naming_preservation.py --base HEAD`, `make dispatch-census`, then `make semantic-score`.
Set `WSA1_RENAME_SKIP=wsa1/notes/prom_b_thunks_round6.py,wsa1/notes/gen_prom_b_f6d002_module.py` for the WSA1 renames.

`prompts/` holds one prompt per batch kind, as last used (the batch letter inside is the last batch's); every
agent was read-only and told never to write into the repository.
