# PRE-REGISTRATION — the VOLUME cell as a criterion for the store gate

Written **before** reading the ten-program `GATECLR` captures (they are still being taken as this
is committed; only the CHORUS pair has been seen, and it is what suggested the test).

## The known answer, and it comes from the firmware rather than from the emulator
`register-space.md` item A1, **PROVEN BY CONSTRUCTION**: every effect's parameter bytecode ends
with a record whose opcode is `0x63`, whose T1 address is `0x06` (37 unit-0 algorithms) or `0x86`
(12 unit-1 reverbs), and whose evaluator is a dB curve-table lookup — binding opcode `0x63` to the
name **VOLUME in 49 of 49** algorithms. The host writes that cell **once**, after linking
(`EFF_VolumeLoop`), and `dsp_disasm.py` already records the consequence of anything else writing
it: the user's depth would survive *"exactly ONE frame"*.

⇒ **a correct machine writes `0x06`/`0x86` once per program load and never from the microcode.**
That is a criterion the ROM and the firmware supply jointly, and no DSP decode has ever been graded
on it.

## What the shipped reading does, on the one program already seen
```
   chorus, arm OFF :  06 (8388607, 0..8388607, chg 1389)      ← RAILED and rewritten
   chorus, GATECLR :  06 (2260027, 0..2260027, chg    1)      ← written once, ~0.27 FS
```

## Predictions, over the ten-program catalogue at the TRUE DEVICE DEFAULT

| | prediction |
|---|---|
| **V1** ★ | with `GATECLR` on, `0x06` has `chg ≤ 2` in **at least 9 of 10** programs |
| **V2** | with `GATECLR` on, `0x06` is **not railed** in any of the 10 |
| **V3** | CONTROL THAT CAN FAIL: with the arm OFF, at least **3** of the 10 must show `0x06` railed or `chg > 100`. If the shipped machine already writes it once everywhere, the instrument is blind and V1/V2 mean nothing |
| **V4** | the hand-off regression (`src0b2_regression.py`) must report **0 BROKEN** |
| **V5** | ⚠ `0x86` is the UNIT-1 cell and only the 12 reverbs use it; it is reported but **not graded**, because the sample contains one reverb |

## What a pass would and would not settle
★ A pass would be the first time the store gate has been graded against a criterion the FIRMWARE
supplies, on a cell whose role is proven by construction rather than inferred — and it would say
the gate's clear is taken BEFORE the ALU.

⛔ It would still not distinguish `-` from `ST(acc→else)` (unreadable by construction), nor settle
`LD`, and it would not move the coverage number: `alu_decoded()` refuses these words because the
MEMORY ACCESS is three-way open, which the clear does not touch.

⚠ And the LFO criterion this replaces MISSED — see `PREDICT_GATECLR_2026-09-13.md`. This one is
offered as the better-posed successor, not as a second bite at the same claim; it is graded on a
different quantity, with its own control that can fail.


---

## RESULT — **V1 MISS, V2 MISS, V3 HIT, V4 HIT** ([`volcell_run_2026-09-13.txt`](volcell_run_2026-09-13.txt))

```
   TYPE   arm OFF (shipped)                          GATECLR ON
    0     (8388607,       0..8388607, chg   1389)    (2260027,  0..2260027, chg  1)
    1     (8388607,       0..8388607, chg  17036)    (2260027,  0..2260027, chg  1)
    2     (8388607,       0..8388607, chg  68498)    (2260027,  0..2260027, chg  3)
    3     (2513195, -599857..8388607, chg 157550)    (2260027,  0..2260027, chg  3)
    4     (8388607, -599857..8388607, chg 111203)    (2260027,  0..2260027, chg  3)
    5     (8388607, -599857..8388607, chg 108666)    (2260027, -1..2260027, chg  6)
    6     (8388607,       0..8388607, chg 100804)    (2260027, -1..2260027, chg  6)
    7     (8388607,       0..8388607, chg 110013)    (2260027, -1..2260027, chg  6)
    8     (7148770,       0..8388607, chg 110049)    (2260027, -1..2260027, chg  6)
   15     (8102393,-8388608..8388607, chg 183545)    (2260027, -1..8388607, chg 13)
```

| | as registered | |
|---|---|---|
| **V1** `chg ≤ 2` in ≥ 9 of 10, arm ON | **2 of 10** | ⛔ **MISS** |
| **V2** not railed in any, arm ON | **1 of 10 railed** (TYPE 15) | ⛔ **MISS** |
| **V3** control: ≥ 3 of 10 bad with the arm OFF | **10 of 10** | ✔ HIT — the instrument can see it |
| **V4** hand-off regression | **10 KEPT, 0 BROKEN** | ✔ HIT |

### ⚠⚠ V1's THRESHOLD WAS MIS-SPECIFIED AGAINST A CAVEAT I HAD ALREADY WRITTEN DOWN
`§100` records, in my own words two hours before this pre-registration: *"`fx_ab.lua` steps UP from
TYPE 0 and `§176`'s D-RAM census accumulates from boot … that census is CUMULATIVE, not
per-program."* V1 said `chg ≤ 2` as though each capture were one program load. It is not: the
TYPE-15 capture has walked through sixteen.

Read against the right model the numbers are exact — the arm-ON column is
**1, 1, 3, 3, 3, 6, 6, 6, 6, 13** against a walk of up to sixteen program loads, i.e. **the cell is
written about once per load and never otherwise**, which is precisely what `EFF_VolumeLoop` does
and what `register-space.md` item A1 proves it should. The shipped column is **1 389 … 183 545**,
i.e. thousands of writes per load.

⛔ **I am NOT rescoring V1 on that.** A criterion re-read after the data is not a criterion. What
this is: a **strong post-hoc fit** to a firmware-supplied known answer, which now needs the same
prediction stated in cumulative terms (`chg ≈ the number of program loads walked`) and re-run —
ideally with a per-program capture rather than a walk, so the caveat cannot bite a third time.

★ **This is my fourth defective criterion of the session and the worst of them**, because unlike
the other three it contradicted something I had already documented. §100's P2 needed an index the
arm could not supply; the class-4/6 P1 was patched at the wrong site twice; §102's P2 assumed a
sole cause; and this one ignored my own caveat. Every one was caught by the criterion or the
control rather than by the result — which is the case for writing them — but the rate is the
finding.

### Verdict
**NOT PROMOTED, and coverage is unchanged at 75.0 %.** V4 says the arm breaks nothing. V3 says the
instrument works. V1/V2 missed as written. The gate's `clr:before` survivor now has: no
refutation, a halved 255× LFO error, and a firmware-anchored cell that goes from railed-and-
rewritten to written-once-per-load — and it needs one correctly-specified run to become a
determination.
