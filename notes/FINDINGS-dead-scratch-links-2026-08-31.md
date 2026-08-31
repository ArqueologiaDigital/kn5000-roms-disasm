# Committed files whose evidence or input lives in a DELETED scratchpad

Found 2026-08-31 during a pre-shutdown sweep. **Pre-existing — nothing from the 2026-08-29/31
session is affected.** Inventory: `notes/DEAD-SCRATCH-LINKS-2026-08-31.txt` (regenerate with the
one-liner at the bottom).

## Why this matters

The project rule is *"a claim whose evidence lives only in scratch is a claim nobody can check,
including me later."* **15 citations in 10 committed files point into `/tmp/claude-1000/<session>/`
directories belonging to sessions that have since ended. Every one of those paths is GONE.**

## Two kinds, with different severity

**A. Scripts that CANNOT RUN.** They `open()` a dead path as their input, so they fail immediately:

| file | dead input |
|---|---|
| `tools/session-probes-2026-08-23/adv/checks.py` | `.../scratchpad/adv/sites2.pkl` |
| `tools/session-probes-2026-08-23/adv/show_blocked.py` | `.../scratchpad/adv/sites.pkl` |
| `tools/session-probes-2026-08-23/verify.py` | `.../scratchpad/allsites.json` |
| `tools/session-probes-2026-08-23/dump_all.py` | writes `.../scratchpad/allsites.json` |
| `tools/session-probes-2026-08-23/dump_sites2.py` | writes `.../scratchpad/hits2.json` |
| `tools/session-probes-2026-08-23/ex5.py` | writes `.../scratchpad/dbrows.pkl` |

These form a chain: `dump_all` → `allsites.json` → `verify`. The chain was committed but its
intermediate store was not, so the committed half reproduces nothing. **Fix: point them at a path
inside the repo (or a caller-supplied `--out`), and commit the intermediate if it is small.**

**B. A SCORE whose control and test inputs are gone.**
`dsp/analysis/data/HDRBASE_SCORE_REV_227.txt` names its control as REV4's `kn5000_dsp1_upload.txt`
(21 cmd-0x02 runs) and its test as REV0's (13 runs). Both paths are deleted. ⚠ The score is still
*stated*; it is no longer *checkable*. Either regenerate both logs and commit them, or annotate the
file to say the inputs are unrecoverable and the number rests on the write-up alone.
`dsp/analysis/STRATEGIC-REVIEW-2026-07-31.md` and `PREDICT_S1_hi12_bench.md` cite a task-output file
and an `ISO=` scratch tree the same way; `analysis/wave7-packages/packages-and-critiques.json` too.

## Not in scope of this note

Citations of the form "write the output to /tmp/foo" are **command templates, not evidence**, and are
fine. Only paths naming a *specific past session* are listed here.

## Regenerate the inventory

    git grep -nE '/tmp/claude-1000/[A-Za-z0-9_./-]+' \
      | while read -r l; do p=${l#*:*:}; done   # see notes/DEAD-SCRATCH-LINKS-2026-08-31.txt
