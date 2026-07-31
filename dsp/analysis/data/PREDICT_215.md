# §215 — `SRC 0x0B` AT `iw25`: pre-registered BEFORE the build

Written and committed **before** `build.sh` was run and before the emulator was launched.
2026-07-31. Task: *does the `SRC 0x0B` decode hold for `000.2.00.2D9` = kernel `iw25`, the one
word that decides what the unit-0 send carries?*

Control run for every "today" number below: `data/kernelA_213.log.gz` (shipped default
`0xB910E446A39B440F`, all env gates ON, clean vehicle, 1 440 001 frames, 313 960 loud).

---

## 0. ★★ THE DISCRIMINATOR IS THE CORPUS, NOT THE FOUR FALSIFIERS — stated first

`HANDOFF-NEXT.md` §1.2 pre-computed four falsifiers for the rival reading
(`SRC 0x0B` at a class-2 word = `mem[ptr]`). **I am recording, before the run, that all four are
NECESSARY BUT NOT SUFFICIENT, and that passing them is NOT evidence for `mem[ptr]`.**

`iw25`'s pointer is on cell `0x06`, whose §104 residency at that slot is
`0..0` quiet ‖ `-5 579 776..4 994 816` loud. **Any** reading of `SRC 0x0B` that puts that cell —
or any other live cell — on the bus makes tempA, `P`, `acc` and the send input-dependent. So
F1–F4 grade *"is the substituted operand alive"*, not *"is the operand `mem[ptr]`"*. A run that
scores 4/4 discriminates nothing. This is standing rule 1's shape one level up: **a number
becoming non-zero is not evidence.**

The test that CAN discriminate is a corpus one, and it is computed and stated here in advance.

## 1. THE CORPUS TEST, COMPUTED BEFORE THE RUN (41 listings, 3057 words)

```
   lo12 = 0x2D9  (SRC 0x0B + ACT 0x19, "tempA <- bus")     36 words
        class 1  addr8 0x60  delay WRITE     29    14 programs
        class 1  addr8 0x20  delay READ       6    ENSEMBLE w10/20/30/68/78/88
        class 2  addr8 0x00  NO ACCESS        1    THE KERNEL, iw25
   word 0x0012201655  ("mac ta,(p)+1" -- multiplies tempA)  13 of 3057 = 0.43 %
```

**PREDICTION C1 (already computed, restated so it can be checked):** all 13 sites of
`0012201655` are IMMEDIATELY preceded by a class-1 `addr8 0x20` **delay READ** word
(`880.1.20.xxx`). 13 of 13.

**PREDICTION C2:** the slot two words before `0012201655` — the "load the multiplicand into
tempA" slot — is filled by `2D9` in ENSEMBLE (on the read word itself) and by the kernel's
`000.2.00.2D9` at `iw25` (split off, one word before the read at `iw26 = 880.1.20.40B`). The
flanger family fills the same slot with `000.2.00.44C` (`SRC 0x11`).

**⇒ VERDICT RULE, fixed in advance:** if C1 and C2 hold, `iw25` is grouped **by its successor**
with the six ENSEMBLE class-1 delay READS, whose `SRC 0x0B` cannot be anything but the delay
datum — and `SRC 0x0B = the delay-read data register` **SURVIVES at `iw25`**. The rival then has
to claim one lo12 means two different things on two classes, *and* leave the kernel's two delay
READs (`iw12 = 880.1.20.2D5`, `iw26 = 880.1.20.40B`) with **no consumer anywhere in the frame**.

**⇒ FALSIFIER FOR MY OWN VERDICT:** if C1 fails (some `0012201655` site has a non-delay
predecessor), or if the kernel has another word that consumes `SRC 0x0B`, the grouping argument
collapses and the rival is back in play.

## 2. THE NULL, COMPUTED BEFORE THE BUILD

From the control log:

```
   §48  DELAY READ CONSUMED (SRC 0x0B)   23 733 120 evaluations, 0 with a non-zero datum
   §77  ... of which reached from a DELAY word  22 521 600
   =>   class-2 (non-delay) SRC 0x0B evaluations  =  1 211 520      <- iw25, and only iw25
   §61  unit0 body executions 1 203 840
   =>   1 211 520 / 1 203 840 = 1.0064 per body execution
```

**N1:** the new counter `§215 class-2 SRC 0x0B` must read **1 211 520 ± 1 %**. A different number
means the gate is not on the word I think it is, and the run is VOID.

**N2 (arm A = gate OFF):** the build must be **read-only**. `s104_score.py` must score arm A and
`data/kernelA_213.log.gz` **identically in all three columns** — `acc 27/2`, `mem 21/9`,
`L 18/3` — and `§70 ACCA` / `§211 ACCB` must stay `min 0 max 0` in both buckets. Any difference
voids the whole run (it means the counter changed behaviour).

**N3:** the gate's fired count must be **0 in arm A** and **equal to N1 in arm B**.

## 3. CALIBRATION THAT CAN FAIL — check before quoting anything else

* `coldnotes2.lua` must print `located=true` and a NOTE ON/OFF pair around t = 21.0/27.5 s.
* `§54 TRACKING` must report a **loud** bucket in **250 000 – 380 000** frames. 0 voids the run.
* ⚠ the isolated `-cfg_directory` must carry `:DSPCFG value="3"`. A report that prints **nothing**
  is zero DSP frames, not a crash (§213's vehicle note).

## 4. THE FOUR FALSIFIERS (arm B, gate ON) — scored, but see §0

| # | today (control) | prediction under the rival | falsifier |
|---|---|---|---|
| **F1** | `tempA` at `iw25..iw52` = `0..0` ‖ `0..0`, flag `=` | `iw25` becomes `0..0` ‖ `-5 579 776..4 994 816`, flag `*`, INPUT-DEPENDENT | stays `=` ⇒ the substitution did not reach tempA; the gate is mis-aimed and the run is VOID |
| **F2** | `P` at `iw39` = `0..0` ‖ `0..0` | becomes INPUT-DEPENDENT | stays constant ⇒ the multiply does not take tempA and §213 §2's mechanism is wrong |
| **F3** | §104 LAST input-dependent **acc** slot = `iw38` (`acc 27/2`) | moves to **≥ iw45** | stays at `iw38` ⇒ `iw41`'s `acc <- P` is not the route |
| **F4** | body 0 `iw84`/`iw85`: `acc`, `mem`, `L` all `0..0` ‖ `0..0` | at least one becomes non-zero / flagged | stays all-zero ⇒ the send does not reach the body even when it carries a live value, and the §211 output-stage null is upstream of the send after all |

## 5. ★ STANDING RULE 1 — the prediction I care most about, and it is a NULL

```
   §70  ACCA AT w73   quiet min 0 max 0  |  loud min 0 max 0        <- today
   §211 ACCB AT w78   quiet min 0 max 0  |  loud min 0 max 0        <- today
   §61  unit0/DO1 0 non-zero peak 0 | unit1/DO2 0 non-zero peak 0   <- today
```

**P-NULL: I predict all of these are UNCHANGED in arm B, even if F1–F4 all pass.** §211 closed the
output stage as a null independently of the send: the epilogue's accumulator is the constant
`2 603 010 048` from `w54` to `w64` and `0` from `w65`, and `§211 ACCB AT w78` is a hard zero.
Nothing in this experiment touches the epilogue.

**If `min != max` appears anywhere, it is NOT an audio claim until:** (a) the quiet bucket — the
run's own **no-stimulus window**, 726 040 frames — is inspected separately; (b) `min` is compared
to `max` in EACH bucket; (c) the value is compared against the **input**, not against silence.
Two "IC311 outputs audio" claims have been retracted on this project and one was a DC.

## 6. THE CHANGE

`UPD6383_SRC0B2`, an **env var, default OFF**, with a fired count. u64 spec mask is EXHAUSTED.
Scope: the `SRC 0x0B` case of the ALU bus evaluator, **only** when
`class4(word) != 1` (the word performs no delay access). The 99 class-1 delay words —
22 521 600 of the 23 733 120 evaluations — are **not** touched in either arm.

Two unconditional counters, present in BOTH arms so arm A measures the null:
`m_src0b2_n` (class-2 SRC-0x0B evaluations) and `m_src0b2_memnz` (of those, how many had
`mem[m_dp] != 0`, i.e. what the rival WOULD have delivered).

## 7. WHAT I WILL REPORT EITHER WAY

Whether `SRC 0x0B` survives at `iw25`; whether anything downstream became input-dependent;
whether `§70`/`§211` `min` still equals `max`. **A null is a fine outcome** and is the outcome
this pre-registration expects: C1+C2 upheld, F1–F4 passing but not discriminating, P-NULL holding.
