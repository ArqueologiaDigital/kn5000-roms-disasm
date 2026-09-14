# PRE-REGISTRATION — a C-format word INVALIDATES the product register

Written **before** the run. 2026-09-14.

## Where this comes from
§109 measured that giving the C-format immediate the destination `P` takes the chorus LFO from
**153 Hz to 0.674 Hz** against a ROM constant of **0.5993** — the only thing all session to put
that number in the right order of magnitude — while **destroying** the per-unit hand-off cell.
§115 then settled the destination as `reg[lo12]` on a proven sub-case (`is_setvec`), so `P` is not
where the immediate goes.

⇒ the LFO improvement was a **side effect**: writing `P` overwrote the **stale product**, which
§102's trace already named as the contaminant — *"the gate word still LOADS the one-slot product,
and at the LFO ramp word that product is the PREVIOUS word's"*.

A C-format word issues no multiply, so the one-slot product after it is not that instruction's.
**Invalidating** it tests the side effect without the injection that wrecked the hand-off.

⚠ NOT `UPD6383_PCLR`. That is the GLOBAL policy *"clear P on any word that did not drive it"*, and
it is **refuted and default-off** — the LEDGER records it as *"a trade, not a decode"*. This is one
word FORM, and the C-format form is the one §109's measurement points at.

## The arm
`UPD6383_CFMTPCLR=1`, default OFF. `UPD6383_CENSUS_PERPROG=1`, chorus (TYPE 0), true default
otherwise.

## Predictions

| | prediction | what a miss means |
|---|---|---|
| **R1** | the arm FIRES (count > 0) | the run says nothing |
| **R2** ★★ | **THE KNOWN ANSWER**: the chorus phase cell `07` reads `mean step` at or near **114** — `floor(0.5993 × 2²³/44100)`, i.e. ~0.5993 Hz, period ~73 584 frames. Shipped it is **15 544 / 81.7 Hz** | the stale product is not the (whole) contaminant and the LFO defect is elsewhere |
| **R3** ★ | the per-unit hand-off `0x05` SURVIVES — live, ±2.9 M, ~175 660 changes — unlike §109's destination-`P` arm, which collapsed it to 14 | the arm is the same trade §109 refused, not a fix |
| **R4** | the **VOLUME** cell `0x06` stays written-once and unrailed | it breaks a firmware criterion |
| **R5** | if R2–R4 hold: the 10-program hand-off regression, **0 BROKEN**, before anything is promoted | a trade, not a decode |

## What a pass would unlock
★ §116 established the chain: **`f31` 3/4/5/7 is blocked on a clean LFO ramp, which is blocked on
this rate defect.** A pass makes the auto-pan discriminator — the instrument `f31-high.md` §4
item 1 asked for — usable for the first time.

⛔ A pass would not decode `f31` by itself, and it would not be a claim about the C-format word's
DESTINATION, which §115 settled separately.


---

## RESULT — **R2 HIT to 0.6 %. R3 MISS. NOT promoted — and the trade is now localised.**
Data: [`cfmtpclr_2026-09-14.txt`](cfmtpclr_2026-09-14.txt).

```
   arm ON   07: step 114..402 306   mean   114.2560   period 73 419 frames = 0.60065 Hz
   control  07: step 114..3 470 859 mean 15 543.9286  period    540 frames = 81.7 Hz
   ROM                                      114                73 584 frames = 0.5993 Hz
```

**R1 HIT** (28 577 436 firings). **R2 HIT** — `mean step 114.2560` against the ROM's **114**, a
rate of **0.60065 Hz** against **0.5993**: **0.6 % from the number the ROM states**, where the
shipped model is **255× wrong**. ★★★ The stale product **is** the LFO's contaminant, and this is
the first time this project has reproduced that constant end-to-end from the machine.

⛔ **R3 MISS.** The per-unit hand-off cell `0x05` is **ABSENT — zero** under the arm, against
`177684(-2869494..3486228/chg175660)` in the control. The audio path dies. By the
pre-registration, that is "the same trade §109 refused, not a fix". **NOT PROMOTED.**

### ★★ What the trade localises, which is the real result
The two halves together say something neither says alone: **the audio path is currently living on
the stale product, and the LFO is being poisoned by the same value.** One register, two consumers,
opposite requirements.

⇒ **the defect is not the stale product itself — it is that nothing drives `P` for the audio path
at that point.** Clear it and the LFO becomes exactly right while the audio starves; leave it and
the audio borrows a residue while the LFO runs 255× fast.

★ And that is **the same shape §240 already found for the EQ**: *"the baseline's EQ activity is the
KERNEL'S RESIDUE being filtered"* — an audio path running on a leftover rather than on its own
operand. Two independent routes to one diagnosis.

### The chain, updated
```
   f31 3/4/5/7  ⟵ needs ⟵  a clean LFO ramp   ⟵ THIS ARM PRODUCES ONE (114.256, 0.6 % off)
                                              ⟵ but at the cost of the audio hand-off
                                              ⟵ because P has no real driver on the audio path
   ⇒ THE NEXT QUESTION IS NOT `f31'.  It is: what SHOULD be driving the product register
     where the C-format word currently leaves a stale one?
```

---

## §118 — the cut mode 1 was missing, registered before the run

Mode 1 cleared `P` at **every** C-format word. MEASURED why that is too broad: the resident
**kernel** carries 8 C-format words and the **output stage** 3, and **not one of them is
`is_c40`** — they are opcodes `605 / 602 / 621 / 625 / 632 / 60B / 600` — while a body's are all
`0x620`. The kernel's sit at **iw1…iw40, BEFORE the iw45 that writes the hand-off cell**, so mode 1
was emptying the input stage's product. That is the whole of R3's miss.

**Mode 2 restricts the invalidate to `is_c40`** — the ONE opcode §115 decoded as the immediate
load. By the census above it **cannot touch the kernel**.

| | prediction |
|---|---|
| **S1** | fires, ≈ 4 per frame in the chorus (its four body C40 words) |
| **S2** ★ | the LFO reads `mean step` at or near **114** — as mode 1 did (114.2560) |
| **S3** ★★ | the hand-off `0x05` **SURVIVES** — live, ±2.9 M, ~175 660 changes — because the kernel is untouched BY CONSTRUCTION |
| **S4** | the VOLUME cell `0x06` written-once and unrailed |
| **S5** | if S2–S4 hold: 10-program hand-off regression, 0 BROKEN, before anything is promoted |

⚠ If S2 holds and S3 does not, the kernel was not the only path and the census argument above is
wrong — which would be a measurement against my own reasoning, and is why S3 is stated as a
prediction rather than assumed.
