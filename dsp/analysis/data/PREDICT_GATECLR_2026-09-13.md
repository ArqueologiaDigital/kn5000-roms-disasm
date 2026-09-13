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
