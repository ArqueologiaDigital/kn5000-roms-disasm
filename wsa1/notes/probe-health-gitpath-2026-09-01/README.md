# probe_health after the git-path migration fix

*Lane M1, 2026-09-01.  ★ REGRESSED is 0 for all four images.*

| image | how measured | invocations | REGRESSED | IMPROVED |
|---|---|---:|---:|---:|
| prom_d | **full sweep** vs `probe-health-baseline-2026-08-30` | 51 | **0** | 7 |
| prom_c | **full sweep** vs `probe-health-baseline-2026-08-30` | 137 | **0** | 44 |
| prom_b | touched-script subset of `probe-health-prom_b-wave8-2026-08-31/prom_b-full.json` | 23 of 189 | **0** | 0 |
| prom_a | touched-script subset of `probe-health-2026-08-31-prom_a/final.json` | 30 of 198 | **0** | 1 |

## Why two of the four are a subset, said plainly

`--image prom_b` is 760 subprocess runs and `--image prom_a` about the same.  On
this machine, which was also compiling MAME for another lane, they were running
at roughly 25 runs per 10 minutes -- five hours each.  ⚠ **That is a reason to
measure less, not to measure nothing.**  `regrade_touched.py` re-measures exactly
the baseline's invocations of the scripts this lane edited, in the same four
trees, and joins on argv.

It is not the full sweep and must not be reported as one.  What it cannot see:

* a row whose script is untouched but whose answer depends on a touched one.
  ★ `probe_health.py` itself is that dependency for EVERY row, and it changed in
  this lane -- which is why it is in the touched set, and why prom_c and prom_d
  were run in full: they are the control showing what the instrument change does
  to rows this lane never opened.  It improves 51 of them and regresses none.
* a script the baseline never ran.  Those are printed as NOT IN BASELINE.

To finish the two full sweeps later:

    python3 notes/probe_health.py --image prom_b --jobs 8 --json ph-prom_b.json
    python3 notes/probe_health.py --image prom_a --jobs 8 --json ph-prom_a.json
    python3 notes/probe_health_regression.py \
        notes/probe-health-prom_b-wave8-2026-08-31/prom_b-full.json \
        ph-prom_b.json --image prom_b

## The two prom_c rows that first looked like regressions

The first prom_c sweep graded `gen_prom_c_block.py` and
`gen_prom_c_block_headers.py --start 0xF9A050 --end 0xFA5949` **TIMEOUT**, which
is non-green, so the run reported REGRESSED 2.  A TIMEOUT is not a changed
answer -- it is the instrument not seeing one -- and both came back UNAFFECTED
on a regrade with the machine quiet (`regrade-prom_c.log`).  `apply_regrade.py`
folds that back into the sweep and prints every substitution; the table above
uses `ph-prom_c-regraded.json`.

★ The honest repair for a TIMEOUT is to re-run it and say so.  Widening the
timeout until it passes, or folding TIMEOUT into UNAFFECTED, would have turned
"never measured" into "green".

## Where the 51 improvements come from

Mostly the instrument, not this lane's edits.  probe_health plants a `.git`
symlink beside its scratch trees; after the move into `wsa1/` that symlink was
dangling, so **every scratch tree stopped being a git repository**.  A probe that
reads a revision then failed identically in asis, full and stub -- `full == stub`
-- and was graded UNAFFECTED.  Restoring git to the scratch trees is what turned
44 prom_c rows and 7 prom_d rows from VACUOUS/LOUD into a real answer.

## Files

    ph-prom_c.json / ph-prom_d.json        the full sweeps as run
    ph-prom_c-regraded.json                prom_c with the two timeouts re-run
    regrade-prom_c.{json,log}              the regrade itself
    touched-prom_a.{json,log}              the touched-script subsets
    touched-prom_b.{json,log}
    regression-prom_c-prom_d.log           probe_health_regression output
    regrade_touched.py  apply_regrade.py   both with --selftest
