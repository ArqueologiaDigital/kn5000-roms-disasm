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


---

## RESULT — **W1 5/5 HIT, W2 5/5 HIT, W3 0/5 MISS** ([`volcell2_run_2026-09-13.txt`](volcell2_run_2026-09-13.txt))

```
   TYPE  limit | arm OFF (shipped)                        | GATECLR ON
   16    <=22  | (3075606, -8388608..8388607, chg 188032) | (2260027, -1..8388607, chg 13)
   17    <=23  | (8388607, -8388608..8388607, chg 120328) | (2260027, -1..8388607, chg 13)
   18    <=24  | (8388607, -8388608..8388607, chg  10746) | (2260027, -1..8388607, chg 13)
   19    <=25  | (6913425, -8388608..8388607, chg  49056) | (2260027, -1..8388607, chg 13)
   20    <=26  | (8388607, -8388608..8388607, chg  52201) | (2260027, -1..8388607, chg 13)
```

* **W1 HIT 5 of 5** — `chg = 13` against limits of 22…26, on five programs (`auto_pan`, `vibrato`,
  `auto_wah`, `rock_rotary` ×2) **captured for the first time in this session**.
* **W2 HIT 5 of 5** — the shipped arm churns the cell **10 746 … 188 032** times on the same
  programs. The instrument is not blind.
* **W3 MISS 0 of 5** — the arm-ON *range* still reaches `+8388607`.

### What W1 actually measures — stated correctly, because it is not what the title says
`§176`'s `chg` counts **value changes, not writes.** And the gate word does not write `0x06` in
either arm: the shipped reading already suppresses its store. So the arm cannot be changing how
often the cell is *written* — it changes the accumulator, and therefore the VALUE that some other
word stores there. ⇒ what the 5/5 tests is **"the VOLUME cell holds a constant under the arm and
churns without it"**, which is the firmware's expectation for that cell and is exactly as
falsifiable, but it is not "written once per load" and must not be quoted that way.

### W3, and the same caveat a fifth time
The `-1..8388607` range accumulates from boot along with `chg`, so it cannot say **which** program
reached the rail — only that one did somewhere in the walk. The earlier ten-program run localises
it: `TYPE 15` (PARAMETRIC EQ) rails `0x06` with the arm on. So the arm does **not** fix every
program, which is consistent with the LFO result halving rather than eliminating the error. ⚠ I
wrote W3 against a cumulative quantity after writing the caveat about cumulative quantities twice.

### Verdict
★ **The gate's `clr:before` survivor now has an out-of-sample pass on a criterion the FIRMWARE
supplies** — 5 of 5, with a control that fires 5 of 5 on the same programs — plus a halved 255×
LFO error and no regression over ten programs. That is the strongest evidence the store gate has
ever had, and it is evidence about **the CLEAR**.

⛔ It does not settle the MEMORY ACCESS. `LD` passes W1/W2 just as `-` does: both drop the
accumulator feedback's effect on whatever writes `0x06`. ⇒ the axis goes from three-way to
**two-way**, and `alu_decoded()` still refuses these 138 words. **Coverage is unchanged at 75.0 %**,
exactly as this pre-registration said a pass would leave it.
