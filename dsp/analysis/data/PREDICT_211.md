# §211 — THE OUTPUT STAGE: pre-registered BEFORE the run

Written and committed **before** the emulator was launched. 2026-07-31.

## 0. What is being tested, and with which instrument

The task is *"why is IC311 silent — the output stage"*, localised by §141/§150 to `w73`.

**Standing rule 11 (a blocker is a MEASUREMENT and measurements expire) applies with force here.**
§141's localisation was taken on a build whose default mask was `0x110E446A39B440F`, before §§188,
197, 201, 202, 204, 209 shipped, and **under the §138 guard (bit 55), which is NOT in the shipped
default.** So the first thing to do is not to build anything: it is to re-run the *existing*
instrument on the *current* build and see whether the epilogue still looks the way §141 described.

**Instrument: `§104 PER-SLOT QUIET/LOUD SPLIT`, which is already in the shipped build and already
covers all 384 slots including the epilogue 60..82.** No source change, no new gate. Supporting
readouts in the same log: `§70 ACCA AT w73`, `§61 PER-UNIT PRESENTATION`, `§48 DELAY READ
CONSUMED`, `§54 TRACKING`.

Vehicle: the CLEAN one (standing rule 2) — cold boot, isolated NVRAM, CHORUS on unit 0 and
CONCERT/ROOM REVERB on unit 1 by cold-boot default, a held triad from **t = 21 s to t = 27.5 s**,
`-seconds_to_run 30`. Rule 12: a DSP test with no notes playing is not a test.

## 1. ⚠ THE SCORING RULE, STATED BEFORE THE DATA

§104 flags a slot `*` when the quiet-bucket range and the loud-bucket range differ. **That flag is
not a test of input dependence**, because a FREE-RUNNING quantity (the LFO ramp in cell `0x07`)
is sampled over two buckets of different length and therefore reports two slightly different
ranges. This is trap #7 in the handoff, and it has cost this project a pass before.

So, **decided in advance**:

```
  a slot is INPUT-DEPENDENT   iff   flag == '*'  AND  (loud_lo - quiet_lo) != (loud_hi - quiet_hi)
  a slot is FREE-RUNNING      iff   flag == '*'  AND  the two deltas are EQUAL   (a pure translation)
```

A pure translation of both endpoints by the same constant is the signature of a ramp, not of a
signal. Every number below is scored by that rule and by nothing else.

## 2. THE CALIBRATION THAT CAN FAIL — run it first

The kernel slots 3..38 must contain **≥ 20 INPUT-DEPENDENT slots** by the rule above (the stale
reference log `data/clean_vehicle_default.log.gz` has 27). If the kernel shows **none**, the notes
did not sound, the loud bucket is empty or mislabelled, and **the run is VOID** — no other number
in it may be quoted.

Second calibration: `§54 TRACKING` must report a loud bucket of roughly `6.5 s x 48 kHz ~ 312 000`
frames. A loud count of 0 voids the run.

## 3. PREDICTIONS

| # | prediction | falsifier |
|---|---|---|
| **P1** | **ZERO** slots in I-RAM `39..384` are INPUT-DEPENDENT by §1's rule — i.e. no accumulator in either body or in the epilogue carries the input | any slot >= 39 scores INPUT-DEPENDENT ⇒ P1 refuted; report which, and the loss point moves later than the kernel |
| **P2** | `§70 ACCA AT w73`: **min == max == 0**, quiet and loud | min != max ⇒ the output stage has stopped being silent; then, and only then, characterise the output — and per standing rule 1 a constant is still not audio |
| **P3** | `§61 PER-UNIT PRESENTATION`: both ports **0 non-zero, peak 0** | any non-zero ⇒ report, gated on P2 |
| **P4** | `§48 DELAY READ CONSUMED`: still **0 reads with a non-zero datum** | non-zero ⇒ §205's gate has opened and Q2 below must be re-scored |
| **P5** | the LAST input-dependent slot is **`iw 38`**, and `iw 39 = 0410AFF647` is where the accumulator becomes a both-buckets constant | a different slot ⇒ report it. The qualitative claim survives if the loss point is **< 84** (kernel-side) and is **REFUTED** if it is **>= 84** (inside a body) |
| **P6** | body 0 reads its unit-0 entry cell `0x05` (slots 84/85/111/112) with `mem = 0..0` in **both** buckets | a non-zero or input-dependent residency there ⇒ the body *is* fed and P1's reading of the mechanism is wrong |

⚠ P1 and P5 are predictions taken from the **stale** reference log. They are therefore not free:
the whole point of the run is that six gates have shipped since, and any of them could have moved
the loss point. P1 failing is a *better* outcome than P1 holding.

## 4. THE QUESTION THE BRIEF ASKS, AND THE DECISION RULE FOR IT

*"Is the output silence downstream of §48's gate (delay reads return 0) or independent of it?"*

Decided before the data:

* **If P1 HOLDS** — no accumulator after `iw 38` depends on the input — then the answer is
  **NEITHER, AS POSED**. §48's delay-read gate and the output stage are *both* downstream of an
  earlier loss: the input never reaches the delay lines to be written into them, so "the delay read
  returns zero" is a symptom of the same upstream failure, not an independent cause of it.
  Corroborated by P6.
* **If P1 FAILS and §48 is still 0** — some body slot carries the input but the epilogue does not —
  then the silence **is** downstream of §48 (or of whatever kills it between that slot and `w73`),
  and the localisation to `w73` can be re-opened on the new evidence.
* **If P4 fails** (§48 opens) the question is moot and must be re-posed.

## 5. WHAT WILL **NOT** BE DONE

* No mask bit and no env gate will be flipped on the strength of a number becoming non-zero.
* No claim of audio will be made without `§70 ACCA min != max` **and** a no-stimulus window.
* `w73`'s decode will not be changed. §182/§198 established that `ACT 0x04`'s only bit-11-clear
  site in the corpus is `w73` itself, so it has no anchored pair and `bit11-family.md` item B
  concluded both presentation unknowns are undecidable by corpus comparison. Nothing measured here
  can license a decode for it, and a null on the output stage is an acceptable deliverable.
