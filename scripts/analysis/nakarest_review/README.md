# nakarest_review -- triage of the `[nakarest] purpose not established` slices

These scripts produce `analysis/nakarest-slices/reviewed-*.json`, which `scripts/converters/nakarest_reviewed_slices.py`
applies. WORKDIR is scratch (`$TMPDIR/...`), never the repository.

| script | what question it answers | run |
|---|---|---|
| `inventory.py` | Which slices still carry the note? For each one: its readers, its bytes, and how many placeholder or symbolic C members cover it. | `python3 scripts/analysis/nakarest_review/inventory.py WORKDIR` |
| `verify_proposals.py` | Does each proposal hold up mechanically? It checks that the type's size matches, that the check is true, and that each cited line exists. | `python3 scripts/analysis/nakarest_review/verify_proposals.py WORKDIR/proposals_batchN.json` |
| `merge_proposals.py` | Turns the proposals of batch N into the reviewed file. It adds the inventory fields, marks checks written with slice offsets, and renames a later piece that kept the old label. | `python3 scripts/analysis/nakarest_review/merge_proposals.py WORKDIR N ...` |

How a batch was made on 2026-10-06:
1. The inventory was cut into four batches of pure-data slices (no symbolic C member, not the RAM-image blob).
2. Each batch was given to a read-only triage pass. It read the readers named in each note, wrote
   `proposals_batchN.json` (type, name, header, `file:line` evidence, and a byte `check`), and refused when the
   code did not show the meaning.
3. The reviewer ran `verify_proposals.py` and read the reader code of a sample again. The reviewed records say
   which ones in their `review` field.
4. The reviewer then ran `merge_proposals.py`, applied the result in a scratch worktree, and ran `make gate-all`
   and the C comment gate before applying it to the tree.
