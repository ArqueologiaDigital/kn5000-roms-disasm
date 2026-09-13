# PRE-REGISTERED: does `SRC 0x0B = mem[ptr]` on a non-delay word fix the input stage?  (§73)

Committed **BEFORE the run**.

## How this site was found (§72 → here)
A **matched pair** — `prog06_ensemble` (input `0x01` = 152 576, hand-off ends at **0**) and
`prog56_mix_up` (157 952, hand-off ends **RAILED**) — same machine, inputs 3.5 % apart, opposite
failures, running the **byte-identical shared kernel**. Tracing the `tA` column:

```
   iw7   0090A011C8  ACT 08  tempA <- -23296 / 188160 / -14848     a real sample, all three
   iw25  00002002D9  ACT 19  tempA <-      0 / -8388608 / 8388352  ★ OVERWRITTEN with 0 or a RAIL
   iw39  0410AFF647  SRC 19  reads tempA  (LO_SRC_TA, an ANCHORED source)
   iw40  0C4A1C0820          multiplies it
   iw45  0010A0020C  ST      stores the result into the HAND-OFF cell 0x05
```

⇒ **Both failure modes are one defect**: `iw25` destroys a good tempA, and whether the hand-off
ends at `0` or at the rail is just whether the garbage was `0` or `±8 388 608`.

## The arm, and why THIS one
`iw25` = `00002002D9` is **class 2 — NOT a delay word** (class 1 is the delay class), and its
source is **`SRC 0x0B`**. The device already ships a default-off rival for exactly that case:

> `UPD6383_SRC0B2`: *0 = SHIPPED: `SRC 0x0B` is the delay-read register everywhere;
> 1 = RIVAL: **on a word with no delay access it is `mem[ptr]`***

Under the shipped reading `iw25` captures the **stale delay-read register**; under the rival it
captures **`mem[ptr]`** — a real cell. ⇒ the rival predicts tempA survives as a sample.
★ This is not a new hypothesis invented to fit: it is a **pre-existing, committed decode rival**,
now with a reason to prefer it and a criterion that can refute it.

## PREDICTIONS, registered in advance
| # | with `UPD6383_SRC0B2=1`, true default | refuted if |
|---|---|---|
| **P1** | at `iw25`, tempA takes a **sample-like** value (10³…10⁶), **not 0 and not a rail** | it is still 0/railed ⇒ the source is not the variable |
| **P2** | `prog56_mix_up`'s hand-off cell `0x05` **stops railing** | still railed |
| **P3** | `prog06_ensemble`'s hand-off `0x05` **stops being 0** | still 0 |
| **P4** | internal null: cells `0x01`/`0x04` **unchanged** in all three | the arm does more than claimed |

## CONTROL
| # | | |
|---|---|---|
| **C1** | `prog04_flanger` — the ONE healthy program — must **still** be healthy (`0x05` a plausible sample, not 0, not railed) | a fix that breaks the only working program is not a fix |

⚠ Even a clean sweep does **not** promote it: one kernel site passing is not the 1 610-word
population `SRC 0x0B` spans. It would make the rival the leading reading **at this site** and give
the input stage its first real candidate.
