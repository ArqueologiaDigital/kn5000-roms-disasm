# Documentation fact-check, 2026-08-07

Both adversarial passes over the documentation refresh **completed**, and all of
their verdicts were applied before publishing.

| pass | verdicts | confirmed | refuted | unverifiable |
|---|---|---|---|---|
| addresses & structure | 24 | 12 | 12 | 0 |
| behaviour, provenance & overclaiming | 58 | 47 | 9 | 2 |

Files:

- `docs-factcheck-verdicts.json` — all 82 verdicts, each tagged with the pass
  that produced it, its evidence, and the correction text where refuted.
- `docs-factcheck-inputs.json` — the 292 claims the writers made, with the
  evidence each author cited. Enough to re-run either pass standalone.

**Re-running next week** (Felipe asked for this): read the pages as published in
`../kn5000-docs/` rather than from a scratch directory, and split the work across
two or three agents by package group. Both passes carried all ~292 claims to a
single large structured return at the end of a long investigation; one of them
took two attempts to deliver it, and a completed result was briefly mistaken for
a stall. Smaller returns avoid both problems.
