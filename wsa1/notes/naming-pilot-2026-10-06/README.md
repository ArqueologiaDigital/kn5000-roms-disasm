# WSA1 naming pilot, 2026-10-06 -- routine names from callers, with evidence

**What question this answers.** Each `sub_FXXXXX` routine here was renamed. What was the name based on?

Read-only triage passes picked the unnamed routines that the most NAMED routines call. `OldCopy_*` callers were left
out, because that module is an older build's. For each routine the pass read the callers and then the body. It gave a
name only when the callers' context and the body agreed. A body alone was not enough.

`proposals_<image>.json` holds one object per routine: `old`, `new`, a `header` (what it does), a `basis`, and
`evidence`, the `file:line` instructions that decide the name, including at least one caller site. The reviewer
re-read a sample of bodies against those claims. Each new label carries its header and points back to this file.

**Applied with** the session's rename helper (`wsa1_rename.py`, in research-scratch). It declares every rename to
`notes/prom_a_preservation_check.py` and `notes/prom_b_names_session_53b889a2.py`. After it:
- `notes/prom_b_thunks_round6.py --pending-args` named the routine-directory slots after their targets, with
  `--mark` and `--fix-ranges`;
- `make gate-all` and both preservation checks were re-run.

**Wave 2** (`proposals_wave2_{c,d,e,f}.json`) used the same process on the next 120 routines that at least two
named routines call (`OldCopy_*` callers excluded): 102 named, 18 refused. Refusals are kept with their reasons, e.g.
routines acting on song-data marker bytes whose meaning is not established, or veneers whose only callers are
unnamed.
