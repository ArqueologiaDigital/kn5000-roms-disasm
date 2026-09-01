# The 2026-09-01 move into `wsa1/`, and the git reads it broke

*Lane M1. Every number below is produced by `notes/git_path_audit.py`; the JSON
and the console log of each run are beside this file.*

## The bug, in one sentence

`os.path` paths in this tree are relative to `ROOT`, which `__file__` follows
wherever the tree goes.  `git show <rev>:<path>` is resolved from the
**repository root** and takes no notice of `-C <dir>` or `cwd=`; a pathspec
(`git diff <rev> -- <path>`) is resolved from the **current directory**.  When
ROOT stopped being the repository root, one of those three stayed correct and
the other two silently stopped naming the file they meant.

## What each shape did when it broke

| shape | what happened | visible? |
|---|---|---|
| `git show HEAD:prom_a/wsa1_prom_a.s` | rc 128, empty stdout | only if the caller checked rc -- half did not |
| `git diff <pre-move-rev> -- prom_a/wsa1_prom_a.s` | git asked that revision for `wsa1/prom_a/...`, matched nothing on the old side, and reported all 175,190 working-tree lines as **added** | no: rc 0, big answer |
| `git show HEAD:notes/asm_source.py` | would have returned the **KN5000** tree's file of the same name | no: rc 0, wrong file |

The third is why `git_path()` tries the prefixed spelling FIRST.  `notes/`,
`scripts/`, `notas/`, `original_ROMs/`, `Makefile` and `README.md` exist on both
sides of the unified tree, and `scripts/analysis/assert_byte_identical.py` is a
file on both sides.

## How the measurement was taken

    # BEFORE: a worktree of 3947944a, the last commit before this lane
    git worktree add --detach /tmp/before-wt 3947944a
    cp notes/git_path_audit.py /tmp/before-wt/wsa1/notes/
    cd /tmp/before-wt/wsa1 && python3 notes/git_path_audit.py --trace --json before.json

    # AFTER: the same sweep on the fixed tree
    cd <repo>/wsa1 && python3 notes/git_path_audit.py --trace --json after.json

Each script runs with a logging `git` first on PATH, so every git call it issues
is recorded with what it asked for, its return code, and the size of its answer.
`bad` counts an object read that failed and a pathspec the named revision does
not spell that way.

## Result

See `RESULT.md` for the numbers, which are pasted from the two logs.

## The pinned baselines

    python3 notes/git_path_audit.py --revs

Nine revisions are named by hash in this tree.  All nine still resolve -- and all
nine are **root-relative**, which is why the helper asks git for the prefix per
REVISION instead of hardcoding `wsa1/`.  None of them is an ancestor of HEAD;
they survive only through `refs/tags/pre-migration-2026-09-01`.
