# Evidence for the 2026-09-01 migration of the WSA1R tree into this repository

These are the **before/after measurements the migration was declared safe on**, kept because the
claims made from them ("byte-identical to the pre-migration baseline") were otherwise resting on a
session scratchpad, which is volatile storage.

| file | what it is |
|---|---|
| `heads.txt` | the two HEADs at the moment of migration, and the rollback tags |
| `wsa1-gate-before.txt` / `-after.txt` | the WSA1R byte gate, standalone repo vs `wsa1/` in this tree |
| `wsa1-cov-before.txt` / `-after.txt` | `reachability.py --targets`, same pair |
| `kn5000-gate-before.txt` / `-after.txt` | the KN5000 byte gate, before and after the merge |
| `health-after-migration.json` / `.log` | the first post-migration `probe_health` sweep, all four images |

## How the migration was done

    git filter-repo --to-subdirectory-filter wsa1     # all 206 commits rewritten to the prefix
    git merge --allow-unrelated-histories             # so `git log wsa1/<path>` reaches them all

Rollback tags: `pre-wsa1-migration-2026-09-01` here, `pre-migration-2026-09-01` in the
decommissioned standalone repo (renamed `wsa1-roms-disasm.DECOMMISSIONED-2026-09-01`).

## ⚠ What these files actually showed, including the part that was wrong

The gate and coverage pairs are identical before and after, and that much held up: a clean rebuild
from the unified root produces four byte-identical ROMs.

**But `health-after-migration.json` is the file that disproves the conclusion drawn from it.** Its
summary line reads `VACUOUS+LOUD: 3`, matching the pre-migration baseline, and that was quoted as
"the migration is clean". It was not:

* the summary **excludes NONDET**, and a deterministically-broken probe was grading NONDET because
  it died citing a randomly-named temp directory;
* worse, `probe_health` itself had been disabled by the move — it plants a `.git` symlink beside its
  scratch trees, that pointed at a nonexistent `wsa1/.git`, so every scratch tree stopped being a
  git repository, revision-reading probes failed IDENTICALLY in all three trees, and the whole
  bucket graded **UNAFFECTED**.

24 of 31 git-reading probes were broken at this point. See
`../git-path-migration-2026-09-01/` for the repair and its audit. This JSON is kept as the record of
a green-looking measurement taken with an instrument that could not fail.
