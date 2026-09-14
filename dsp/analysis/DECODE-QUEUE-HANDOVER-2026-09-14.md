# DECODE QUEUE — HANDOVER, 2026-09-14

**Read this before touching the decode queue.** Standing project rule: *check the handover first*.
Ten attacks were run on this queue in one session; two decoded, eight are nulls. The nulls are the
valuable part of this file — each closes a line and says why, so nobody walks it again.

## Where coverage stands

| region | start of session | now |
|---|---:|---:|
| KN5000 resident kernel (I-RAM 0…82) | 47.0 % | **61.4 %** |
| …header 0…59 | 56.7 % | **71.7 %** |
| …output stage 60…82 | 21.7 % | **34.8 %** |
| FRAME FLOOR (kernel + reverb) | 74.5 % | **80.1 %** |
| all 38 KN5000 body images | 80.4 % | 80.4 % |
| SX-WSA1R corpus (undecoded words 3091 → 851) | 37.5 % | **79.9 %** |

Mirrors **8003/8003** (pooled, `tools/upd6383d_diff.sh -p`); `dsp/verify.py` BYTE-MATCH OK.

## What decoded, and why it worked

* **§122** — the C-format payload is an I-RAM address. Two routes: the region test (11 of 11 inside
  their own image, p = 6.6e-9) and the **relocation test** against the WSA1R's byte-homologous copy
  of the kernel header (§121). +11 words, kernel 47.0 → 60.2 %.
* **§128** — **mode 1 is the register file.** `class4 & 7` is the addressing mode, so class 1 and
  class 9 were one question. Four measurements anchored the read half. +143 words.

**The method that paid, both times: a second copy of the same code at a different offset.** A field
that is an address shifts with a relocation; one that is data does not. No semantics, no null.

## The three blocks — 619 of the ~1358 remaining pooled words

### `ACT 0x0B` — 191 sole (62 KN + 129 WSA). THREE criteria measured blind.
* Anchored **only** on class A (fourth multiplicand route, FORCED under a 2-input ALU). §133
  checked whether that restriction is really the **cursor-fetch bit** rather than class A: it is
  not separable — every fetch-bit ACT-0x0B word *is* class A.
* §129 **withdrew the reason it was closed**: *"every ACT-0x0B delay word carries `addr8`
  0x20/0x30"* drops the population of a scoped measurement (`dram-matching.md` item J: "203 slots
  over the 83 algorithms where `#cells == #consumers`"). Six carry `0x60`, the FORCED write — two
  inside the KN5000's own algorithm images.
* **Criteria that failed, with their reasons:**
  1. SINGLE DELAY's lag-1001 ROM product — all six readings accepted (LEDGER §291, re-run).
  2. §130, the tempA hazard — beat its permutation null (0 of 48, null min 4) and **died to the
     per-action control**: 5 of 14 actions equally excluded.
  3. §133, the symmetric code (`ACT 0x0B` deposits what `SRC 0x0B` collects) — **0 of 488 at lag 1**,
     median lag 14, rank 8 of 16.
* ★ **§136: 86 % OF THE OPEN WORDS ARE DELAY ESCAPES** — 165 of the 191 sole-blocked. The 18
  class-A words are already decoded, and every "plain" ACT-0x0B word in the reverbs is one of them
  (`102.A.00.64B`), so `capture-signature.md` item F's *"BLOCK A needs ACT 0x0B"* is already
  satisfied and **the reverb is not where the open words are**. That also reframes §107's null:
  a09's three ACT-0x0B words are all escapes, so SINGLE DELAY was **the right population, measured**.
* **What would break it — now a searchable static condition, not a modelling job.** `mem<-bus` is
  one of the three survivors and §107 measured `mem[ptr]` live at every site, so a criterion with
  power must be sensitive to a `mem[ptr]` write **at an escape word** — which a09's echo is not.
  ⛔ **§137 RAN THAT SEARCH AND IT IS CLOSED.** Of the 165 escape sites, **134 (81 %)** do have
  their pointer cell read later in the same program — confirming §107 — but **0** have that reader
  inside a DF-I section interior, so the bit-exact oracle cannot be aimed at the code from the
  memory side either (§135 closed the section side). ⚠ A proximity cut ("reader within 3 of a latch
  word") returned seven candidates including the WSA1R's parametric EQ; all seven were program
  **ambles** (`w0` → `w1`). **When a span exists, test membership in the span, never distance to its
  landmark** — the same trap as §135, twice in one session.
  ⇒ what is left for this code is **hardware**, or an oracle anchored on a program whose ACT-0x0B
  words are escapes AND whose arithmetic the ROM pins. No such program exists in either corpus.

### `SRC 0x11` — 171 sole (54 KN + 117 WSA). A DEPENDENCY CYCLE, not a capture problem.
`DSP-DATAPATH-DECODE-HANDOFF-2026-09-11.md` states it: splitting `accb←acc` from `accb←P` needs a
program whose accb input **varies**, and every reachable program feeds it the frame-invariant
kernel-B constant — which is the very input route that is blocked. *"Capture campaigns cannot
settle accb… the break is the store/source-code decode from the bit-encoding (or hardware), NOT
another capture."* Confirmed there from three independent angles including the speculative ISA.
**Do not run another capture campaign at this.**

### `f31` 3…7 — 257 undecoded occurrences.
Downstream of the LFO rate defect §120 localised to **one word, `iw40`**. §132 measured the
documented-sibling route at exactly this field and it does **not** transfer: uPD6383 `ADD = 1`,
`HOLD = 2` against NEC uPD7725 `ADD = 5`, `NOP = 0`. The source-code match that made the rosetta
analogy credible is real and is **not** evidence about the ALU field.

## Lines closed this session — do not re-walk

| line | result |
|---|---|
| more class minimal pairs from the homolog pairs (§132) | **zero** aligned class substitutions; classes-4/6 stays at n = 2 |
| the class guard's missing 2×2 corner, class 0 (§132) | real asymmetry, **inert** — 221 words, 0 would decode |
| SRC/ACT codes exclusive to the WSA1R (§132) | **none**; one shared vocabulary, so its 851 words are blocked by the same codes |
| the documented sibling at the ALU field (§132) | codes **do not transfer** |
| `ACT 0x0B` = the write side of `SRC 0x0B` (§133) | **refuted**, 0 of 488 at lag 1 |
| `ACT 0x01` as the delay-data producer (§133) | **one word** in 27 images, not a field property (rule 9) |
| mode 3 / `class 3` (§131) | **exists** — the published class space is KN5000-local — but its addressing is undocumented and there is **no class twin** |
| the `0x820` targets as a strict NEXT-BLOCK pointer | **refuted**: 3 of 5 (KN) and 4 of 5 (WSA), weaker than §122's ζ (4/5, 5/5). `w31`/`w36` point **two** blocks ahead, consistently in both products. ζ is the right generality and `w40` stays the sole exception |

## Two method rules this session earned the hard way

1. **A null that moves is not a null that discriminates.** §128's first test was invariant under
   its own shuffle (mean 95.0, sd 0.0); §130's beat its permutation null and died to the
   per-category control. **Run the per-category control with the test, not after it.**
2. **De-duplicate before quoting a rate** (rule 9, `adjudication-round8` item E). §133's 70-of-91
   was one distinct word in 27 images.

## ⛔ §138 WAS RETRACTED — read this before chasing "the oracle has a target"

An earlier cut of this handover led with *"17 undecoded words sit inside a DF-I section, 8 of them
one instruction in the wah programs."* **That was wrong.** It scored section membership with a
**tempA live range** instead of `lle_oracle.py`'s own definition (five consecutive
coefficient-consuming **class-A** MACs plus the class-8 makeup). The claimed target,
`804.8.16.1DA`, is **class 8** — a shape the oracle does not model at all.

Corrected: **7** undecoded words sit inside a real DF-I section (97 sections, 498 words pooled) —
six multi-axis (`kernel w30`, `prog15_rock_rotary w65`/`w79`) and one `SRC 0x11`
(`prog15_rock_rotary w18`). **Zero** `ACT 0x1A`. Six of seven need several axes closed at once, so
it is a thin lead, not a sized next step. `prog39_parametric_eq` has none, which is still why the
oracle has never had to say anything.

★ **Method rule, earned three times in one session:** use the model's own definition of a region —
not a proxy for it, and not a landmark near it.

★ **The one lead that survives bounding (§139).** Of those 7, exactly one has `SRC 0x11` as its
**sole** open axis: `prog15_rock_rotary w18 = 0212A01452`, a class-A MAC inside the `w16…w21` run.
If the oracle could name its operand role it would anchor `SRC 0x11` **from the biquad rather than
from accb captures**, sidestepping the dependency cycle. ⛔ Three preconditions first, none met:
the run is SIX class-A words so the section boundary is inferred; `lle_oracle.py` **assumes** the
cell order `[b1, b0, b2, −a1, −a2, makeup]` rather than deriving it, and that order is established
only for `prog39_parametric_eq`; and instantiating a model validated on the EQ at an unvalidated
site is §135's problem again. **Establish the section, derive the order, then read the operand.**
★ **§140 did the first step: PRECONDITION 1 IS MET.** `prog15_rock_rotary` (algo 15) `w17…w21`
carries the full §7 signature — `mac.ta` (ACT 0x13) at `w17`, `mac.tb` (ACT 0x14) at `w20`, class-8
`post` at `w23` — and excluding `w16` (its annotation calls it an output-level gain) leaves exactly
the oracle's six cells, C-RAM `0x05…0x09` + makeup. `w18` is **index 1**, canonical operand `x0`.
⛔ **Precondition 2 is now named precisely**: deriving the order by stability needs the
**per-coefficient SCALES**, solved in `biquad-eq.md` for the **EQ only**. Two of the rotary's five
raw coefficients exceed `2^23` (15 353 414 and 8 958 128), so no uniform divisor applies and the
poles are not computable. ⇒ **apply `biquad-eq.md`'s scale-solving method to algo 15.** That is the
next concrete step, and it is bounded work rather than an unknown.

## What would actually move this

* **Hardware.** Parked — `kn7000_mame/notes/HARDWARE-QUESTIONS-PENDING-FELIPE.md`.
* **A new anchored oracle** for one of the three codes. ⛔ **NOT the existing HLE — §135 measured
  it.** `dsp/hle/effects.py` line 9 says its own models are *"models of the decoded ALGORITHM
  (graded), not bit-exact to the chip"*, and the two oracles that ARE anchored cannot see
  `ACT 0x0B`: the biquad oracle is validated on `prog39_parametric_eq`, which contains **zero**
  ACT-0x0B words, and SINGLE DELAY's lag-1001 product is measured blind to it. In the EQ-bearing
  programs the code sits in program **ambles** and **delay escapes**, never in a filter section.
  A new oracle has to be anchored on a program that actually carries the code — the reverbs, where
  the HLE is graded rather than bit-exact. **That is the gap to close, and it is a modelling job,
  not a search.**
* **`iw40`'s driver** (§120). It is now decoded as `ldreg r20,#iw14` — a register load whose I-RAM
  address points **at** a block terminator where all nine siblings point **past** one. What supplies
  `P` there is the best-posed question left, and it has a known answer at each end: the hand-off
  live at ±2.9 M and the ramp at the ROM's 114.
