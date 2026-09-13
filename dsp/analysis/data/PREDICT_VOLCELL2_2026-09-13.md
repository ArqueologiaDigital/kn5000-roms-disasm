# PRE-REGISTRATION — the VOLUME criterion, restated correctly, on OUT-OF-SAMPLE programs

Written **before** the run, on TYPE indices **not used in any capture this session**.

## Why there is a second one
`PREDICT_VOLCELL_2026-09-13.md` asked for `chg ≤ 2` as though each capture were one program load.
It is not: `fx_ab.lua` steps UP from TYPE 0 and `§176`'s census accumulates from boot, a caveat
this session had already documented in `N-INPUT-GATE-OPENED` §100 and which I then failed to apply.
The arm-ON column came out **1, 1, 3, 3, 3, 6, 6, 6, 6, 13** against walks of up to sixteen loads —
the right shape, scored against the wrong threshold. **That fit is post-hoc and is not being
rescored.** This is the same claim stated correctly and tested on data nobody has looked at.

## The claim
`register-space.md` item A1 (PROVEN BY CONSTRUCTION, 49 of 49 algorithms): cell `0x06` is the
user's effect **VOLUME**, written **once per program load** by `EFF_VolumeLoop` and never by the
microcode.

## The test
TYPES `16 17 18 19 20` — **not captured at any point in this session** — at the true device
default, both arms, one binary. A walk to TYPE *n* passes through *n + 1* program loads.

| | prediction |
|---|---|
| **W1** ★ | with `GATECLR` ON, cell `0x06`'s `chg ≤ n + 5` for **all 5** programs (one write per load, plus slack) |
| **W2** ★ | with the arm OFF, `chg > 1000` for **all 5** — the control that can fail; if the shipped machine already writes it once, the instrument is blind |
| **W3** | with `GATECLR` ON, `0x06` is **not railed** in any of the 5 |
| **W4** | RULE 12: input cells non-zero and moving in every capture; every identity fingerprinted ✅ |

⚠ W1 and W2 together are the test. W1 alone is satisfiable by an arm that freezes the cell, which
is why W2 requires the OFF arm to be visibly wrong on the same programs and W3 requires the ON value
to be a plausible depth rather than a rail.

⛔ A pass would say the gate's clear is taken BEFORE the ALU, on a criterion the firmware supplies.
It would still not distinguish `-` from `ST(acc→else)` (unreadable by construction), would not
settle `LD`, and **would not move the coverage number** — `alu_decoded()` refuses these 138 words
because the MEMORY ACCESS is three-way open, which the clear does not touch.
