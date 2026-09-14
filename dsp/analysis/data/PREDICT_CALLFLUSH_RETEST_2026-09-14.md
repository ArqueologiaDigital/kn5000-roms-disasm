# PRE-REGISTRATION — re-test `UPD6383_CALLFLUSH` at TODAY's default

Written **before** the run. 2026-09-14.

## Why a reverted arm is being re-tested, and why that is not cherry-picking
§118 localised the LFO's contaminant: it is a product formed in the KERNEL that **survives the
block CALL** into the body, where the LFO's ramp word adds it. Clearing the product at the block
call is exactly `UPD6383_CALLFLUSH` (§36), which the LEDGER records as giving the chorus **a
constant +114/frame ramp** — the ROM's own increment.

§56 **reverted** it, for a reason that was right at the time: it had been validated with
`SPEC=B9108446A39B440F` (ACT `0x0E` selector 4) while the device ships selector 7, and at the
shipped mask it **added railing to the PARAMETRIC EQ** (22 cells / 59 rows / 0 railed → 24 / 105 /
6 railed).

⚠ **The default it was refuted against no longer exists.** Since then this project has promoted
`UPD6383_SRC0B2` (§76 — the input stage now reads the input), the store gate's `clr:before`
(§106), and the C-format destination (§115), and decoded the block terminator (§112). §94 already
recorded one §28-era refutation that stopped reproducing once the input stage was fixed, and set
the rule: *"a refutation expiring does not make the claim true"* — so this is a re-test with its
own criteria, not a reinstatement.

## The test
`UPD6383_CALLFLUSH=1`, `UPD6383_CENSUS_PERPROG=1`, true default otherwise. TYPE 0 (chorus, the LFO
witness) and TYPE 15 (PARAMETRIC EQ, the program §56's revert was about).

| | prediction |
|---|---|
| **T1** | the arm fires (`§36` count > 0) |
| **T2** ★★ | chorus: the LFO `mean step` at or near **114** (ROM `floor(0.5993 × 2²³/44100)`), against the shipped 15 544 |
| **T3** ★★ | chorus: the per-unit hand-off `0x05` **survives** — this is what §117's mode 1 failed |
| **T4** ★ | ⚠ **THE REASON FOR THE REVERT, re-measured**: PARAMETRIC EQ must NOT gain railed cells. §56's number was 0 railed → 6 railed. If it rails again at today's default the revert stands and this ends here |
| **T5** | if T2–T4 hold: the 10-program hand-off regression, 0 BROKEN, before anything is promoted |

⛔ A pass would fix the LFO **rate**, and by §116's chain unblock the auto-pan discriminator for
`f31` 3/4/5/7. It would not itself decode any word, and the coverage number would not move until
that discriminator is run.


---

## RESULT — **T1 HIT, T3 HIT, T2 MISS. The revert stands, and now for a second reason.**

```
   CALLFLUSH FIRED 3 181 374 times (2 per frame -- the two block calls)
   chorus LFO  07: step 114..3 470 859  mean 15 543.9286   -- IDENTICAL to the control
   hand-off    05:177684(-2869494..3486228/chg175660)      -- survives
```

**T1 HIT**, **T3 HIT**, **T2 MISS**: clearing the product at the block CALL does **nothing** for the
ramp at today's default. ⇒ the LEDGER's *"CALLFLUSH gives a constant +114/frame ramp"* was measured
at the OLD default — with the `PSHIFT=2` baseline arms §72 exposed, and before §76 / §106 / §115.
**§56's revert stands, and the benefit it was kept alive for does not reproduce either.**

★ §94's rule cuts both ways and this is the other side of it: *a refutation expiring does not make
the claim true* — and here the CLAIM expired too. Recorded so nobody re-promotes it on the
strength of a ledger line.

### ★★ What is left, and it is a sharper question than the one we started with
Three arms now bracket the contaminant:

| arm | LFO | hand-off |
|---|---|---|
| clear `P` at **every** C-format word (§117 mode 1) | **114.256 — the ROM's number** | ⛔ destroyed |
| clear `P` at **`is_c40`** words only (§118 mode 2) | unchanged | ✔ survives |
| clear `P` at the **block CALL** (CALLFLUSH) | unchanged | ✔ survives |

⇒ **only the KERNEL's own C-format words matter** — its eight are opcodes `605/602/621/625/632`,
and the body's four are `0x620`. Clearing there fixes the ramp and starves the input stage.

★★★ **So the question is now per-site, not global: WHICH kernel C-format word's product does the
input stage consume, and which one does the LFO inherit?** If they are different words — and the
kernel's eight sit at iw1, 15, 22, 29, 31, 40, 48, 56, spanning both sides of the iw45 that writes
the hand-off — then clearing at one and not the other fixes both. That is a per-word experiment
with a known answer at each end, and it is a much better-posed question than "the LFO rate is
wrong".
