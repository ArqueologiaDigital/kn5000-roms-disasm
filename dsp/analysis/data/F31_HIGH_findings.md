# `f31 > 2` — a full-corpus census, the aliasing test, and the minimal pairs

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-30**.
No hardware. Static analysis of the Sub CPU ROM corpus only.

Owning notes checked first, per rule ★: [`f31-high.md`](../f31-high.md),
[`SPECULATIVE-APPLIED-REGISTER.md`](../SPECULATIVE-APPLIED-REGISTER.md) §139 / §140,
[`action00-discriminator.md`](../action00-discriminator.md),
[`ROADMAP-2026-07-29.md`](../ROADMAP-2026-07-29.md) §P5.2,
[`instruction-set.md`](../../instruction-set.md), [`three-codes.md`](../three-codes.md),
[`act0b-reverb.md`](../act0b-reverb.md) §4.

Tool: [`../../tools/f31hi_census.py`](../../tools/f31hi_census.py).

Grades: **MEASURED** / **FORCED** / **INFERRED** / **SPECULATIVE**.

---

## 0. PRE-REGISTRATION — written and committed BEFORE any number was computed

Committed as its own commit; `git log --follow` on this file shows this section
landing before the census section.

### 0.1 The NULL — what the census looks like if `f31` is a don't-care

Two distinct nulls, and they make opposite predictions, which is the whole point
of computing them first:

* **NULL-A, "`f31` is a genuine flat 3-bit opcode field."** Then each of the 8
  values is chosen by the *designer* per word for its operation, so `f31` should
  be *conditionally independent* of the routing fields given the program's needs:
  every value should appear across many `class4`, many SRC, many ACT, in many
  images, and knowing the rest of the word should NOT let you predict `f31`.
  Quantitatively: `H(f31 | rest-of-word-fields)` stays close to `H(f31)`.
* **NULL-B, "`f31` is a don't-care / residue bit-pattern."** Then its values are
  whatever the assembler emitted, and it would be predicted almost perfectly by
  the rest of the word — `H(f31 | hi12-minus-f31)` ≈ 0 by construction is *not*
  informative (the field is *part of* `hi12`), so the honest conditioner is the
  **other fields**: `class4`, `addr8`, `lo12`, and the *non-`f31`* `hi12` bits
  taken as a set.

A third possibility is the one the task names: **ALIASING** — `f31 = 4,5` are not
independent codes but `f31 = 0,1` carried inside a different *word family*, the
family being marked by some other bit. Under aliasing the contingency table is
near-block-diagonal: the family bit predicts whether `f31`'s high bit is set, and
inside each family only the low 2 bits vary.

### 0.2 Predictions, with their falsifiers

| # | prediction | falsifier (what result kills it) |
|---|---|---|
| **P1** | ★ **The published `f31` counts are computed over a POPULATION DEFECT.** `f31-high.md` and §139 quote "40 distinct body images, 3154 words" and "203 words". `gen_dsp_disasm.py` says the IC311 population is **91 slots / 38 distinct images / 2974 words** — the other 5 images are **IC310 (MN19413)** programs. I predict the 5 IC310 images carry `f31 > 2` words, so the IC311-only count is **< 203**. | The 5 IC310 images contribute **0** `f31 > 2` words ⇒ the published count stands for IC311 and P1 is dead. |
| **P2** | **`f31 ∈ {4,5}` is heavily ALIASED, not a free field.** ≥ 80 % of plain `f31 ∈ {4,5}` words come from **≤ 4 distinct `hi12` values**. | The plain `f31 ∈ {4,5}` words spread over **≥ 10** distinct `hi12` values with several `class4`/SRC/ACT combinations each ⇒ genuine independent field, P2 dead. |
| **P3** | ★ **§140 S1 is right and is the mechanism**: `hi12` bit 5 is the family marker. I predict the contingency `bit5 × (f31 > 2)` has **normalised mutual information ≥ 0.30** and that bit-5-set words are the large majority of `f31 > 2`. | NMI **< 0.10**, or `f31 > 2` is spread evenly across bit 5 ⇒ S1 dead as a mechanism. |
| **P4** | **Minimal pairs exist**: ≥ 1 pair of corpus words identical in `class4`, `addr8`, `lo12` and in every `hi12` bit outside `[3:1]`, differing only in `f31`, with at least one member having `f31 > 2`. | **Zero** such pairs ⇒ `f31 > 2` never substitutes for `f31 ≤ 2` in an otherwise identical word, which is itself strong aliasing evidence (and kills the "modifier over the same base op" reading of `f31-high.md` item B by a second route). |
| **P5** | **The `f31 = 4` / `f31 = 5` SRC disjointness of §139 §4 survives the population correction** (`f31=4 → {07}`, `f31=5 → {08,10}`, both never bit 6, `f31=4` never bit 7). | Any overlap appears after restricting to the 91 IC311 slots ⇒ §139 §4's sharpest claim was an artefact of the mixed corpus. |
| **P6** | **The corpus alone cannot decide the SEMANTICS** — it can decide the *encoding structure* (is `f31` one field or two) but not what operation `4` and `5` name, because every `f31 ∈ {4,5}` word §139 §1 found in a cold-boot-reachable program is the operand-free NOP form. I predict the ranked candidate list ends with an **emulator experiment**, not a ROM answer. | A minimal pair in a program with independently known arithmetic (biquad / LFO ramp / delay) that forces one reading ⇒ P6 dead, and that would be the pass's result. |

### 0.3 A criterion that cannot fail is not a test

Explicitly declared **before** running: the `f31-high.md` `biquad` control is not
re-run here — it is *known* to be unable to fail (its item E is PROVEN BY
CONSTRUCTION). Nothing below is scored through PARAMETRIC EQ's biquad.

---
</content>
