# PRE-REGISTRATION — `UPD6383_GATECLR`: the store gate's `clr:before` survivor, graded on the LFO

Written **before** the run. 2026-09-13.

## Why the LFO, and why now
`store-gate.md` §4 leaves the gate at `(bit 7, f31 == 1)` three-way open, and its surviving
families are (a) `-` with `clr ∈ {never, before, after}`, (b) `ST(acc→else)` with the same clears,
(c) `LD`. All of them differ **only in the accumulator**, so only a context with known accumulator
arithmetic can choose among them. §101 found that context: **`092.A.00.200`, the LFO ramp word, IS
a gate word** — 46 occurrences over 26 images — and its bit-7-clear twin `012.A.00.200` exists.

The LFO is this project's best-anchored arithmetic: `lfo-ramp.md` anchors 29 blocks in 16 images
**nine-fold**, the increment being exactly `floor(f × 2²³ / 44100)` for round decimal rates. For
the chorus that constant is **114** = `floor(0.5993 × 2²³ / 44100)`, i.e. **0.5993 Hz**.

## The defect this predicts, MEASURED in the control before the arm exists
`§228`'s LFO RISE CENSUS — read-only, already in the binary, and graded against the machine's own
clock so its Hz is not circular — reports for the chorus's phase cell:

```
   07: rises 1 481 033 of 1 783 404 frames, step 114..4 190 812 (VARIES) mean 29 098.0293
       period 2^23/step = 288.3 frames = 152.972113 Hz at the declared 44100 Hz
```

★ **The minimum step is exactly 114 — the ROM's own constant — and the mean is 255× larger.** The
phase advances by the right amount sometimes and by a contaminated amount usually, and the shipped
LFO runs at **153 Hz where the ROM specifies 0.599 Hz**.

The frame trace says where the contamination comes from: with `clr:never` (the shipped reading)
the ramp word's `acc += P` adds the increment **on top of whatever the kernel left in the
accumulator**, and the next word (`082.2.00.1C0`, decoded — `SRC 0x07` = the phase cell, `ACT 0x00`
= bus into the accumulator's input term) then adds the resident phase, after which the WRAP word
`094.A.00.200` stores the sum back. Under the gate's **`clr:before`** survivor the accumulator is
zeroed before the ALU, so the sum is exactly `increment + phase` and nothing else.

## The arm
`UPD6383_GATECLR=1`, default OFF. On a word carrying the bit-4 store **and** bit 7 **and**
`f31 == 1` — the open gate, and nothing else — the accumulator's feedback term is zero, which is
`clr:before` exactly. Blast radius: the 138 KN5000 gate words.

## Predictions, in advance

| | prediction | what a miss means |
|---|---|---|
| **P1** | the gate FIRES, count > 0 and ≈ 1 per LFO block per frame | the run says nothing; discard it |
| **P2** ★★ | **THE KNOWN ANSWER.** `§228` cell `07` becomes `step 114..114`, `mean 114.000`, `period 2²³/114 = 73 584 frames = 0.5993 Hz` — the ROM's own constant, computed from `C-RAM[0x00]` and not from the machine | the reading does not produce the rate the ROM specifies, and `clr:before` is out |
| **P3** | CONTROL THAT CAN FAIL: the increment's SOURCE must not change — `L = 114` at the ramp word (it reads `C-RAM[0x00]`). If `L` moves, the arm is changing the operand and not the feedback | the measurement is void |
| **P4** | the OTHER LFO-bearing programs land on THEIR OWN ROM constants too — `lfo-ramp.md` has **9 distinct increments over 29 blocks in 16 images**, so this is nine known answers, not one | a single-program fit is a coincidence; nine is not |
| **P5** | REGRESSION: 10-program catalogue at the true default, hand-off cell `0x05`, **0 BROKEN** | the arm is a trade, not a decode |
| **P6** | RULE 12: notes playing, input cells non-zero | not a test |

## What a pass would settle, and what it would not
★★ A pass would **choose among `store-gate.md` item D's survivors on known mathematics** — the
thing that item explicitly lacked — and it would do so on a quantity the ROM states and the
emulator does not: the LFO rate. `clr:never` (shipped) and `clr:after` both fail P2 by
construction; `LD` predicts `2 × phase + increment`, which diverges rather than ramps.

⛔ It would **not** distinguish `-` from `ST(acc→else)`: those two are the same machine wherever
the `else` key is unreadable, which `gate_settle.py:70` makes true by construction. The result
would be "the clear is BEFORE the ALU", not "there is no store".

⛔ And it would not by itself move the coverage number: `alu_decoded()` refuses these words for the
gate being open, and closing the *clear* leaves the memory access still three-way. What it would do
is reduce a three-way open axis to a two-way one on 138 words, and fix a 255× rate error.

⚠ RISK, stated first: `§196`'s superseded census and `§228`'s rise census disagree on the period
(307 vs 288 frames). Both are far from 73 584; the argument does not rest on which is right.


---

## RESULT — **P1 HIT, P2 MISS by a factor of 136**, and my criterion embedded an unchecked premise

```
   §102 GATECLR (ON): gate words with the feedback dropped: 22 230 564
```

**P1 HIT.** And the LFO rise census on the chorus phase cell:

| | step | mean | period | rate |
|---|---|---:|---:|---:|
| control (shipped) | 114 … 4 190 812 | 29 098.03 | 288.3 frames | **152.97 Hz** |
| `GATECLR` | 114 … 3 470 859 | **15 506.97** | 541.0 frames | **81.52 Hz** |
| P2 predicted | **114 … 114** | **114.000** | 73 584 frames | **0.5993 Hz** |

⛔ **P2 MISSES.** The mean halves and the maximum drops — the right direction — but the target was
`114` flat and the result is 15 507, out by **136×**.

### ⚠ The criterion was not clean, and that is my third this session
P2's arithmetic assumed **the gate word is the only thing adding junk to the phase**. I never
checked that, and it is false: the ramp block's phase chain runs through at least two other words
(`000.2.F4.407`, `082.2.00.1C0`), and clearing the gate's feedback removes about half the
contamination rather than all of it. ⇒ **the miss does not refute `clr:before`** the way the
pre-registration said it would ("`clr:before` is out"); it refutes *"the gate alone accounts for
the LFO's 255× rate error"*, which is what the prediction actually encoded.

★ That is the third criterion of this session with a defect in it — §100's P2 required an index the
arm could not supply, the class-4/6 gate's P1 was patched at the wrong site twice, and this one
assumed a sole cause. All three were caught by the criterion rather than by the result, which is
the argument for writing them down; none of them should have needed catching.

### ★ A post-hoc observation, labelled as such, and worth a pre-registered test of its own
The arm removes **every railed cell from the chorus**:

```
   control:  06 (8388607, 0..8388607, chg 1389)   92 (8388607, 0..8388607, chg 1)
   GATECLR:  06 (2260027, 0..2260027, chg    1)   92 (5456405, 0..7474246, chg 2)
   railed cells: off ['06','92']  ->  on []
```

⚠⚠ **Cell `0x06` is the user's effect VOLUME** — `register-space.md` item A1, **PROVEN BY
CONSTRUCTION**: the effect's parameter bytecode ends with opcode `0x63`, `T1[0x63][0] = 0x06`
(37 unit-0 algorithms) / `0x86` (12 reverbs), evaluated by a dB curve-table lookup, and bound to
the name VOLUME in **49 of 49** algorithms. The firmware writes it **once**, after linking
(`EFF_VolumeLoop`), and `dsp_disasm.py` already warns that anything overwriting it would leave the
user's depth surviving *"exactly ONE frame"*.

Under the shipped reading that cell is **railed and rewritten 1389 times**. Under `GATECLR` it is
**written once** and holds 2 260 027 — about 0.27 of full scale, a plausible effect depth.

⛔ This was noticed AFTER the run and is a LEAD, not a result. The pre-registered test it deserves
is across programs and units: *cell `0x06` (and `0x86` on the reverbs) must be written once per
program load and never by the microcode*, which is a known answer the firmware supplies and which
neither this run nor any earlier one was designed to check.

### Verdict
**NOT PROMOTED.** P2 missed its number. What the run earns: `clr:before` is **not refuted** (the
criterion that would have refuted it was mis-specified), it halves a 255× rate error, and it turns
a proven-by-construction parameter cell from railed-and-overwritten into written-once. That is a
better lead than the gate has had, and it needs a criterion built on the VOLUME cell rather than on
the LFO rate.

---

## RE-TEST — P2 was measured on a CUMULATIVE census, like everything else

Registered before the run. §103 built `UPD6383_CENSUS_PERPROG`, and it applies to §228's LFO rise
census as much as to §176: the `step 114..3 470 859, mean 15 506.97` quoted above was accumulated
over the **whole type walk**, i.e. over sixteen other programs' LFOs as well as the chorus's. The
chorus's own step has never been measured.

**P2′ (same prediction, correct instrument):** with `UPD6383_CENSUS_PERPROG=1` and `GATECLR=1`, the
chorus's cell `07` must read `step 114..114`, `mean 114.000`, `period 73 584 frames = 0.5993 Hz` —
the ROM's own constant. Control: the same capture with `GATECLR` off must NOT.

---

## P2″ — the OTHER clear placement, registered before the run

P2′ missed per-program too (`step 114..4190812 mean 29167` off, `114..3470859 mean 15544` on). The
frame trace says why, and it is not a defect in the criterion this time: with the feedback dropped
the gate word still LOADS the one-slot product `m_p`, and at the LFO ramp word that product is the
PREVIOUS word's — junk. The increment does not arrive until the NEXT word (`082.2.00.1C0`,
`SRC 0x07` + `ACT 0x00`, `f31 == 1`), where the pipeline delivers it.

**`clr:after` — the accumulator left at ZERO after the gate word — removes that too**, and it is
`store-gate.md` §4's other surviving clear placement, not a new hypothesis.

**P2″ (`UPD6383_GATECLR=2`, with `UPD6383_CENSUS_PERPROG=1`):**

| | prediction | what a miss means |
|---|---|---|
| **Q1** | the arm fires (count > 0) | discard |
| **Q2** ★★ | chorus cell `07`: `step 114..114`, `mean 114.000`, `0.5993 Hz` — the ROM's constant | `clr:after` does not produce the ROM's rate either, and BOTH clear placements are out on this criterion |
| **Q3** | the VOLUME cell `0x06` stays written-once and unrailed (what `clr:before` already achieves) | the arm trades one firmware criterion for the other |
| **Q4** | 10-program hand-off regression, 0 BROKEN | it is a trade, not a decode |


---

## P2″ RESULT — **`clr:after` is REFUTED: it kills the LFO outright**

```
   §102/§104 GATECLR (mode 2): gate words affected: 22 230 564          Q1 HIT
```

With `UPD6383_GATECLR=2` and the per-program census, **cell `07` disappears from both instruments**:
it is absent from §176's non-zero list (11 of 256 non-zero, `07` not among them) and it has **no row
at all** in §228's rise census. Under the shipped arm the same capture reads
`07:2946538(0..8388606/chg1574370)`.

⇒ **Q2 MISS, and not a near miss: the LFO phase never moves.** The chorus's modulation stops
existing. `0x06` is zero too, so Q3 fails with it — the effect depth would be silence.

★ The hand-off cell is untouched (`05:177684(-2869494..3486228/chg175660)`, identical to control),
so the damage is specific rather than a broken machine.

### ★★★ Which FORCES the clear, by elimination
Three clear placements, three independent anchored criteria:

| placement | verdict | on what |
|---|---|---|
| `clr:never` (**shipped**) | ⛔ REFUTED | the **VOLUME** cell — railed 5 of 5, churned 11 … 177 316 times, against a firmware-proven write-once |
| `clr:after` | ⛔ REFUTED | the **LFO** — the phase cell never moves at all |
| **`clr:before`** | ✔ **the only survivor** | VOLUME written once and unrailed 5 of 5; LFO alive (rate still wrong, which is a separate defect) |

**The store gate's clear is taken BEFORE the ALU.** Both rivals fall on criteria the ROM and the
firmware supply, neither of which the emulator can fake, and each of which demonstrably CAN fail —
because each of them just did, on a different arm.

---

## R-TEST — item D's THIRD family, `LD`, at both placements. Registered before the run.

With `clr:before` forced by P2″, the only rivals left are item D's `LD` family: the memory access
read INTO the accumulator (bit 7 as a memory-port DIRECTION bit), at `@before` and `@after`.

★ **If both fall on the same anchored criteria, the axis closes for EXECUTION.** The two survivors
would be `none` and `ST(acc→else)`, and those are **the same machine** — `gate_settle.py:70`
declares the `else` key *"a memory key no pointer can ever equal"*, so nothing can read what it
writes. *"Is there a store at all"* stays unanswerable, and stops mattering.

| | prediction | what a miss means |
|---|---|---|
| **R1** | modes 3 and 4 fire (count > 0) | discard |
| **R2** ★ | the **VOLUME** cell `0x06` is railed or churned (`chg > 2`) under **both** modes — i.e. they behave like the refuted `clr:never`, because the accumulator carries a memory value into whatever writes that cell | if a mode leaves it written-once, `LD` is still alive and the axis stays open |
| **R3** ★ | the **LFO** phase cell `07` fails to ramp at 114 under both modes | as above |
| **R4** | CONTROL: mode 1 (`clr:before`) on the same binary must still give `06 chg 1`, unrailed | the binary changed something else and the comparison is void |

⛔ A pass closes the gate **for execution only**. It does not say whether the word stores; it says
that whatever it does with memory cannot be observed, which is what `decoded()` asks.


---

## R-TEST RESULT — **both `LD` placements REFUTED. The gate is DETERMINED for execution.**

One binary, chorus, per-program census, `UPD6383_GATECLR` = 3 / 4 / 1:

| mode | VOLUME `0x06` | LFO phase `07` | |
|---|---|---|---|
| **3** `LD@before` | `(6454331, 0..6454331, chg 1)` ok | `rises 85 902`, **step 36 … 4 194 103, mean 2 082 744, period 4.0 frames** | ⛔ the LFO at ~11 kHz against a ROM constant of 114/frame |
| **4** `LD@after` | `(4194304, 0..4194304, chg 1)` ok | **ABSENT — the phase cell is dead** | ⛔ |
| **1** `clr:before` (control) | `(2260027, 0..2260027, chg 1)` | `chg 1 570 842`, **min step exactly 114** | ✔ |

**R1 HIT** (22 230 564 each). **R2 MISS** — the VOLUME cell does *not* discriminate the `LD` family;
it only refuted `clr:never` and `clr:after`. **R3 HIT on both** — the LFO does. **R4 HIT** — the
control reproduces.

### ★★★★★ The elimination, complete

| reading | refuted by | measurement |
|---|---|---|
| `-/clr:never` (**shipped**) | the **VOLUME** cell | railed 5 of 5 out-of-sample, churned 11 … 177 316 |
| `-/clr:after` | the **LFO** | phase cell absent from both instruments |
| `LD@before` | the **LFO** | 4.0-frame period; step up to 4 194 103 against 114 |
| `LD@after` | the **LFO** | phase cell dead |
| **`-/clr:before`** | — | VOLUME once and unrailed 5/5; LFO alive, min step = the ROM's 114; 10 KEPT / 0 BROKEN |

`ST(acc→else)/clr:before` is **the same machine** as `-/clr:before`: `gate_settle.py:70` declares
the `else` key *"a memory key no pointer can ever equal"*. ⇒ *"is there a store at all"* stays
**unanswerable and stops mattering for EXECUTION**, which is what `decoded()` asks.

**PROMOTED.** `UPD6383_GATECLR` default 1 (`=0` is the control), **re-verified with NO ENV SET AT
ALL** (§56's rule): hand-off `05:177684(-2869494..3486228/chg175660)` unchanged, `06` written once,
`07` alive. The disassembler's guard 7 now admits `f31 == 1`; mirrors agree 3057/3057; byte-match
OK; the 24 documentation pages regenerate and the HLE-permanence test passes.

⚠ **Coverage 75.0 % → 77.6 %** (tier 1 74.0 % → **76.6 %**, +78 body words; the frame floor
70.4 % → 72.2 %).

⚠ NOT claimed fixed: the LFO's **rate** is still wrong under the survivor (81 Hz against the ROM's
0.599 Hz). §102 measured that the gate is not its only cause. That defect is open.
