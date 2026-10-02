# Positional aliases at code line starts become labels (2026-10-02)

Tool: `scripts/tools/label_alias_branch_targets.py --tree <v> [--apply]` (run `make all` first).

| | v10 | v9 | v7 |
|---|---|---|---|
| positional aliases before | 1,266 | 1,265 | 1,058 |
| label placed: Helper (called, starts a routine of its own) | 457 | 456 | 179 |
| label placed: Join / Return / Sub / Code / Epilogue | 230 / 106 / 23 / 67 / 2 | (same shape) | 194 / ... / 52 |
| retired into a label already there | 128 | | |
| left: unused, or used by data | 131 | 131 | 334 |
| left: not the start of a code line | 122 | 121 | 114 |
| positional aliases after (dashboard posalias) | 253 | 252 | 448 |

Roles follow scripts/converters/symbolize_numeric_branches.py (structure only, no claim of
purpose).  v7 then harmonized with v10 (70 renamed, 5 inserted: v7's parents differ, so its
generated names did; report notes/version-label-harmony-2026-10-02/v7_from_v10_round7.json).
