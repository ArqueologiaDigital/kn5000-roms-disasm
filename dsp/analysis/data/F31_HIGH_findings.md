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

## 1. Result — scored against the pre-registration

| # | prediction | outcome |
|---|---|---|
| **P1** | published `f31` counts sit on a two-chip population | ★ **HIT, and located precisely.** `f31-high.md`'s **203 / 3154 / 40 images** is the wide basis; the IC311 answer is **150 / 2974 / 38**. `SPECULATIVE-APPLIED-REGISTER.md` §139's counts are already IC311-correct and reproduce to the word. |
| **P2** | `f31 ∈ {4,5}` is heavily aliased (≤ 4 distinct `hi12`) | **criterion HIT, conclusion REFUTED — and the criterion was a bad one.** `f31=4` and `f31=5` each come from exactly **3** distinct `hi12` values, but so do the *decoded* values (`f31=2`: 9, `f31=0`: 11, `f31=1`: 21). Low `hi12` diversity is a property of the whole corpus, so the test could not discriminate. This is the project's own "a criterion that cannot fail is not a test" rule biting the person who wrote it. |
| **P3** | `hi12` bit 5 is the family marker, NMI ≥ 0.30 | ★ **HIT as a measurement** (NMI = **0.620** against `f31 > 2`; `f31 ∈ {3,6,7} ⇒ bit 5 = 1`, **0 counterexamples in 2452** bit-5-clear plain words) — **and REFUTED as the mechanism** by P4. |
| **P4** | ≥ 1 minimal pair involving `f31 > 2` | ★★★ **HIT, far beyond the prediction. 8 contexts**, one of them carrying **7 of the 8** `f31` values on byte-identical words, and **3 of them stand an undecoded `f31` against an arm that is already decoded.** |
| **P5** | §139 §4's absences survive the population correction | ★ **HIT, 6 of 6.** |
| **P6** | the corpus decides the ENCODING but not the SEMANTICS | ★ **HIT.** No reading of `f31 = 4` or `f31 = 5` is forced by the ROM. What the pass delivers instead is a **vehicle with a decoded reference arm**, which is what was missing. |

---

## 2. Population — the correction (MEASURED)

`python3 dsp/tools/f31hi_census.py pop`

| basis | slots | images | words | `f31 > 2` | histogram `f31` 0..7 |
|---|---|---|---|---|---|
| **published** (`delayline.ctx`) | 96 | 40 | 3154 | 203 | `1335 1331 285 53 59 58 12 21` |
| **IC311 only** (`lfo_ramp.algo_to_image`) | 91 | 38 | 2974 | **150** | `1261 1288 275 32 46 55 2 15` |

The difference is **two images**, algo **79** (48 words) and algo **88** (132), which
`gen_dsp_disasm.py` and `second-dsp-and-ready.md` §2 identify as **IC310 / MN19413**
programs — a *different chip*. They contribute **53 of the 203**.

⛔ **What moves.** `f31-high.md` items **B** and **C** — the shape argument — are
computed on the wide basis and change materially:

```
  PUBLISHED   bit2=0 [1335, 1331, 285, 53]   norm 1.000 0.997 0.213 0.040
              bit2=1 [  59,   58,  12, 21]   norm 1.000 0.983 0.203 0.356
              expected bit2=1 [66.7 66.5 14.2 2.6]    chi2 = 129.6 (3 df)

  IC311 ONLY  bit2=0 [1261, 1288, 275, 32]   norm 1.000 1.021 0.218 0.025
              bit2=1 [  46,   55,   2, 15]   norm 1.000 1.196 0.043 0.326
              expected bit2=1 [52.1 53.2 11.4 1.3]    chi2 = 150.0 (3 df)
```

Item B's headline — *"bases 0, 1 and 2 track to three digits"* — **does not survive**.
On the correct chip base 1 tracks to 1.021 vs 1.196 (17 % apart) and **base 2 tracks
to 0.218 vs 0.043, a factor of 5**. Nine of `f31 = 6`'s twelve occurrences and 21 of
`f31 = 3`'s fifty-three were IC310's. Item C's *conclusion* (bit 2 is not a pure
modifier) survives and is **stronger** — `chi2` rises to 150.0. **MEASURED.**

✔ **What does not move.** §139's per-program counts (`CHORUS ×0`, `ROOM REVERB 1 ×0`,
`PARAMETRIC EQ f31=4 ×2 / f31=5 ×2`, `KERNEL f31=5 ×1`, `EPILOGUE ×0`) and its
plain/total split (`f31=4`: 46 plain of 48; `f31=5`: 52 plain of 60) reproduce
**exactly** on the IC311 basis. §139 was already using the right population; only
`f31-high.md` was not.

---

## 3. The census (MEASURED)

`python3 dsp/tools/f31hi_census.py census` — **plain** words only (`f31` is not a
field inside C-format or the bit-11 escape), whole machine = 38 body images +
kernel (60) + epilogue (23) = **2619 plain words**.

| `f31` | plain | imgs | class4 | SRC | ACT | C-fmt/ESC words w/ same bits |
|---|---|---|---|---|---|---|
| 0 | 920 | 40 | `2`:580 `A`:213 `0`:55 `6`:53 | `10`:361 `07`:210 `00`:121 `11`:99 | `07`:232 `15`:223 `00`:118 `0E`:106 | 382 |
| 1 | 1309 | 40 | `2`:684 `A`:554 `4`:53 | `07`:504 `00`:286 `10`:262 | `00`:477 `15`:309 `07`:135 | 1 |
| 2 | 241 | 38 | `2`:184 `A`:50 `1`:7 | `07`:155 `00`:48 `08`:29 | `00`:79 `15`:68 `0E`:59 | 42 |
| **3** | **34** | 11 | `2`:32 `9`:1 `1`:1 | `00`:20 `11`:6 `10`:4 `07`:3 | `00`:20 `07`:11 | 1 |
| **4** | **46** | 21 | `2`:18 `A`:16 `1`:12 | `00`:29 `07`:17 | `00`:29 `15`:16 `0D`:1 | 2 |
| **5** | **52** | 19 | `2`:42 `A`:10 | `00`:35 `08`:10 `10`:7 | `00`:41 `07`:7 `0B`:3 | 8 |
| **6** | **2** | 1 | `2`:1 `1`:1 | `07`:1 `00`:1 | `0D`:1 `00`:1 | 1 |
| **7** | **15** | 7 | `2`:15 | `00`:13 `10`:2 | `00`:12 `07`:2 `0B`:1 | 1 |

Flags, as a fraction of each value's plain population, plus mean normalised
position in the frame and the number of distinct `hi12` values:

| `f31` | b10 END | b7 | b6 | **b5** | b4 ST | b0 | mean pos | distinct `hi12` |
|---|---|---|---|---|---|---|---|---|
| 0 | 0.021 | 0.003 | 0.060 | 0.013 | 0.023 | 0.002 | 0.486 | 11 |
| 1 | 0.009 | 0.225 | 0.005 | 0.018 | 0.483 | 0.000 | 0.501 | 21 |
| 2 | 0.033 | 0.137 | 0.000 | 0.017 | 0.120 | 0.000 | 0.508 | 9 |
| **3** | 0.000 | 0.235 | 0.000 | **1.000** | 0.000 | 0.029 | 0.456 | 4 |
| **4** | 0.261 | **0.000** | **0.000** | 0.739 | 0.261 | 0.000 | **0.622** | 3 |
| **5** | 0.000 | 0.192 | **0.000** | 0.808 | 0.192 | 0.000 | **0.391** | 3 |
| **6** | 0.500 | 0.000 | 0.000 | **1.000** | 0.000 | 0.000 | 0.865 | 2 |
| **7** | 0.000 | 0.000 | 0.000 | **1.000** | 0.000 | 0.000 | 0.360 | 1 |

Region split (plain): `f31 > 2` is **overwhelmingly a BODY phenomenon** — kernel
carries one (`f31 = 5`), epilogue two (`f31 = 3`), body the other 146.

★ Two exact complements fall out and are worth recording because they are *forced*,
not fitted: for `f31 = 4`, `bit 5 = 0` on 12 words and `bit 4 = 1` on the same 12;
for `f31 = 5`, `bit 5 = 0` on 10 and `bit 4 = 1` on the same 10. In the corpus
**`f31 ∈ {4,5} ⇒ bit 5 = NOT bit 4`, 98 of 98.** The 22 bit-5-clear words are
`018.A.00.1D5` ×12, `09A.A.00.200` ×9 and `29A.A.B8.21A` ×1 — and they are exactly
where §4's decisive evidence lives.

### 3.1 §139 §4's absences, re-verified on the IC311 population (P5)

| §139 §4 claim | verdict |
|---|---|
| `f31 = 4` never carries bit 7 | ✔ 0 / 46 |
| neither `4` nor `5` ever carries bit 6 | ✔ 0 / 98 |
| non-null SRC sets **disjoint**: `4 → {07}`, `5 → {08,10}` | ✔ exactly |
| 12 of 38 images terminate on `428.1.0E.000` (`f31 = 4`); none on `f31 = 5` | ✔ exactly |
| `f31 = 4` has the highest mean position (0.622), `f31 = 5` among the lowest (0.391) | ✔ 0.622 / 0.391 |
| neither is ever a delay-DRAM word | ✔ (those carry bit 11, where `f31` is not a field) |

**6 of 6 MEASURED.** §139 §4 is the most durable thing written about this field.

### 3.2 A structure §139 §4 did not name: the END word carries `f31`

All 38 body images end on their one END word (`hi12` bit 10, escape clear), and
that word's `hi12` varies systematically:

```
  428.1.0E.000 x12  (f31=4)   400.1.0E.000 x7  (f31=0)   612.1.0E.000 x4 (f31=1)
  604.1.0E.000 x4   (f31=2)   602.1.0E.000 x3  (f31=1)   424.1.0E.000 x2 (f31=2)
  420.1.0E.000 x2   (f31=0)   42C.1.0E.000 x1  (f31=6)   400.1.0E.407 x1 (f31=0)
  504.1.0E.407 x1   (f31=2)   612.1.0F.000 x1  (f31=1)
```

★ Inside the bit-5-set terminator family (`420/424/428/42C`, 17 images) the `f31`
values are **0, 2, 4, 6 — every one even**, i.e. `hi12` bit 1 is always clear and the
terminator carries a **2-bit code at `hi12[3:2]`**. **MEASURED.** Nothing in the notes
records this; it is the cleanest sub-structure `f31` shows anywhere.

---

## 4. ★★★ THE ALIASING QUESTION — ANSWERED: `f31` IS A GENUINE FIELD

`python3 dsp/tools/f31hi_census.py mi alias pairs anchors`

### 4.1 The contingency, and what it looks like it says

`H(f31) = 1.6936` bits over 2619 plain words. Mutual information with every other
field (`I − I_null` is the excess over 20 label-shuffles):

| Y | H(Y) | I(f31;Y) | I − I_null | H(f31 \| Y) | NMI |
|---|---|---|---|---|---|
| `class4` | 1.4483 | 0.1341 | 0.1240 | 1.5595 | 0.093 |
| `addr8` | 3.9573 | 0.2858 | 0.1564 | 1.4078 | 0.169 |
| `lo12` | 4.1615 | 0.5081 | 0.4347 | 1.1855 | 0.300 |
| SRC | 2.5410 | 0.2471 | 0.2252 | 1.4465 | 0.146 |
| ACT | 2.9277 | 0.2524 | 0.2215 | 1.4412 | 0.149 |
| `f98` | 1.4461 | 0.5650 | 0.5600 | 1.1286 | 0.391 |
| `hi12` b10 END | 0.1406 | 0.0174 | 0.0156 | 1.6762 | 0.124 |
| `hi12` b7 | 0.5663 | 0.0932 | 0.0906 | 1.6005 | 0.165 |
| `hi12` b6 | 0.1616 | 0.0229 | 0.0209 | 1.6708 | 0.141 |
| ★ **`hi12` b5** | 0.3422 | 0.2012 | 0.1991 | 1.4924 | **0.588** |
| `hi12` b4 ST | 0.8397 | 0.2078 | 0.2059 | 1.4858 | 0.247 |
| `hi12` b0 | 0.0128 | 0.0025 | 0.0018 | 1.6911 | 0.195 |
| all nine non-`f31` `hi12` bits | 3.1847 | 1.1823 | 1.1440 | 0.5113 | **0.698** |
| image | 5.2384 | 0.1452 | 0.0735 | 1.5484 | 0.086 |
| (`class4`,SRC,ACT) | 4.6842 | 0.6425 | 0.5473 | 1.0512 | 0.379 |

And the 2×2 against `f31 > 2`:

| bit | 0 & f≤2 | 0 & f>2 | 1 & f≤2 | 1 & f>2 | NMI |
|---|---|---|---|---|---|
| b10 END | 2431 | 136 | 39 | 13 | 0.042 |
| b7 | 2139 | 131 | 331 | 18 | 0.000 |
| b6 | 2408 | 149 | 62 | 0 | 0.013 |
| ★ **b5** | 2430 | **22** | 40 | **127** | **0.620** |
| b4 ST | 1788 | 127 | 682 | 22 | 0.012 |
| b0 | 2468 | 148 | 2 | 1 | 0.046 |

★ `hi12` **bit 5** is the only real covariate, and its strongest form is exhaustive:
**`f31 ∈ {3, 6, 7} ⇒ bit 5 = 1`, with 0 counterexamples in 2452 bit-5-clear plain
words.** Inside the bit-5 family `f31 > 2` is **76.05 %** (127/167); outside it,
**0.90 %** (22/2452). This is `SPECULATIVE-APPLIED-REGISTER.md` **§140 S1**, and it
was already written down — the contribution here is that it is now **measured, and
exhaustive on three of the five values**. ★ (Rule check: I did not discover S1. It
was in the notes.)

### 4.2 Conditioning on the ENTIRE rest of the word

```
  H(f31)                             = 1.6936 bits
  H(f31 | ENTIRE rest of word)       = 0.1822 bits
  the same with f31 labels SHUFFLED  = 1.1583 +- 0.0117   (z = -83.1)
```

The rest of the word predicts `f31` far better than chance — that is what a
horizontal microword built from a small set of idiomatic word-shapes looks like.
**But it is not zero**, and an aliased or don't-care field would be *fully*
determined. 324 words live in the 17 contexts where the value genuinely varies.

### 4.3 ★★★ EXCHANGEABILITY — the falsifier for aliasing

If `f31 = 4` were "`f31 = 0` plus a family prefix carried elsewhere in the word",
then **no** `f31 = 4` word could be byte-identical to an `f31 = 0` word outside bits
[3:1] — the prefix would have to differ too. Count the words that would be
impossible:

| `f31` | contexts | shared with another `f31` | rate |
|---|---|---|---|
| 0 | 230 | 5 | 0.02 |
| 1 | 357 | 12 | 0.03 |
| 2 | 70 | 11 | 0.16 |
| 3 | 13 | 3 | 0.23 |
| **4** | **7** | **5** | **0.71** |
| 5 | 12 | 2 | 0.17 |
| **6** | **2** | **2** | **1.00** |
| **7** | 5 | 3 | 0.60 |

★★ **`f31 = 4` is the MOST exchangeable value in the whole field** — the exact
opposite of what a prefix predicts. **FORCED: `f31` is a genuine 3-bit operation
selector, not two fields aliased together.** Bit 5's association with it is a
**usage** correlation (the designer sets bit 5 in the same stages where the high
`f31` codes are wanted), not an encoding constraint — and the proof is that the
decisive pairs below hold bit 5 *constant*, at **zero**, while `f31` moves from a
decoded value to 4 or 5.

⇒ **§140 S1 is REFUTED as an explanation of `f31 = 4/5`.** It remains true as a
distribution. It cannot be the carrier, because the sharpest `f31 = 4` and
`f31 = 5` evidence in the corpus is bit-5-**clear** on both arms.

⇒ Bit 5 is independently confirmed to be its own microword bit: the corpus contains
**two byte-identical-except-bit-5 pairs**, `000.2.00.000` / `020.2.00.000` and
`400.1.0E.000` / `420.1.0E.000`, both at `f31 = 0`.

### 4.4 The minimal pairs — all 8 contexts with an `f31 > 2` arm

```
  ★  020.2.00.000 f31=0 x2   022 f31=1 x14   024 f31=2 x2   026 f31=3 x18
     028.2.00.000 f31=4 x17  02A f31=5 x28   02E f31=7 x11        <-- 7 of 8 VALUES
  ★  026.2.F5.000 f31=3      02E.2.F5.000 f31=7
  ★  026.2.F6.407 f31=3 x2   02E.2.F6.407 f31=7
  ★  028.2.0A.1CD f31=4      02C.2.0A.1CD f31=6
  ★  420.1.0E.000 f31=0 x2   424 f31=2 x2   428 f31=4 x12   42C f31=6 x1
  ★  092.A.00.200 f31=1 x24  094.A.00.200 f31=2 x28   09A.A.00.200 f31=5 x9
  ★  010.A.00.1D5 f31=0 x2   012.A.00.1D5 f31=1 x1    018.A.00.1D5 f31=4 x12
  ★  020.A.06.1D5 f31=0 x1   028.A.06.1D5 f31=4 x2
```

`020…02E.2.00.000` carrying **seven of the eight values** on words that are
otherwise identical to the bit is on its own decisive: a field the designer varies
seven ways in one slot is a field.

---

## 5. ★★★ THE THREE ANCHORED PAIRS — an undecoded `f31` against a DECODED twin

Only three contexts put `f31 > 2` on a word bit-identical to one whose operation is
already known. These are the entire remaining constraint on `f31 = 4` and `f31 = 5`.

### A. `class A, addr8 0x06, lo12 0x1D5` — ★ and the identical run is **NINE WORDS**

```
  a71 PEQ+CHORUS w38..w46   vs   a73 PEQ+FLANGER w38..w46   (and a74 PEQ+VIBRATO w31..w39)

      -3  202.A.FC.415   202.A.FC.415
      -2  204.2.00.000   204.2.00.000
      -1  092.2.FA.700   092.2.FA.700
      +0  020.A.06.1D5   028.A.06.1D5    <== f31 = 0  vs  f31 = 4   ** ONE BIT **
      +1  182.2.00.407   182.2.00.407
      +2  040.0.00.C63   040.0.00.C63
      +3  000.6.18.4CD   000.6.18.4CD
      +4  012.4.01.1CE   012.4.01.1CE
      +5  104.2.06.1CE   104.2.06.1CE
```

★★★ **This is the single sharpest piece of evidence about `f31` in the corpus**, and
`f31-high.md` / §139 / §140 do not contain it. Nine consecutive words, three
shipping programs, one differing bit — `hi12` bit 3.

**And it lands inside a stage whose arithmetic is already MEASURED.**
[`lfo-ramp.md`](../lfo-ramp.md) §10 identifies `040.0.00.C63 | 000.6.TT.4CD |
012.4.01.1CE` as the **waveform table lookup**, and the class-A word two before it as
the **phase-to-index scale**: `(coef × phase) >> 23`, MEASURED coefficient
`0x000018 = 24` at 8 of 8 plain sites, mapping the Q0.23 LFO phase onto an integer
index into a **24-entry** table. ★ **VERIFIED HERE that the coefficient is the same
in all three arms** — `algo 71 C-RAM[0x0F] = algo 73 C-RAM[0x10] = algo 74
C-RAM[0x0D] = 0x000018 = 24.** So the *only* difference between PEQ+CHORUS and
PEQ+FLANGER/PEQ+VIBRATO at this stage is `hi12` bit 3.

★ Census of that slot over all **46** table-lookup sites (new here):

| table extent (`addr8`) | `f31` of the scale word | sites |
|---|---|---|
| 40 (waveshaper) | 0 | **17 — exceptionless** |
| 24 (LFO) | 0 | 11 |
| 24 (LFO) | 1 | 11 |
| 24 (LFO) | 2 | 5 |
| **24 (LFO)** | **4** | **2** — `a73 w41`, `a74 w34` |

Read with the decoded meanings: `f31 = 0` = *index := 24·phase*; `f31 = 1` = *index
:= acc + 24·phase* (a phase **offset** added to the scaled ramp); `f31 = 2` =
*index := acc, discard the product*. `f31 = 4` is the first LFO scale word of
exactly two programs, PEQ+FLANGER and PEQ+VIBRATO.

★ And the slot has an internal ordering rule: **in every program whose two LFO
scale words differ, the LATER one is `f31 = 1` — 7 of 7** (PHASER `2→1`, MIX UP
`0→1→1`, SD+FLANGER / SD+VIBRATO / SD+PHASER `2→1`, **PEQ+FLANGER `4→1`,
PEQ+VIBRATO `4→1`**). The programs whose scale words agree all use one value
throughout. So `f31 = 4` occupies the *first-of-a-pair* position that `f31 = 0` and
`f31 = 2` occupy elsewhere — it is a **peer of the decoded values in the same
structural slot**, which is exactly what makes the pair usable. **MEASURED.**

★★ **And the observable is immediate and unambiguous**: `w+1` = `182.2.00.407` has
`SRC 0x10` (**the accumulator**) and `ACT 0x07` (**`mem[ptr] ← bus`**). The value
`f31 = 4` produces is written to memory **one word later**, with no `f31 = 0`
barrier, no biquad, no store-gate ambiguity and no dependence on `hi12` bit 4.
**This is the decidable context `f31-high.md` item G said it could not find, and
§139 §1 concluded did not exist.** §139 was right about PARAMETRIC EQ and AUTO PAN
and wrong to generalise: `PEQ+FLANGER` and `PEQ+VIBRATO` carry a fully-operanded
`f31 = 4` word feeding a known consumer.

### B. `class A, addr8 0x00, lo12 0x200` — the pair that PROVED `f31` is a field

```
  092.A.00.200  f31 = 1   acc <- acc + P     24 images   (the LFO)
  094.A.00.200  f31 = 2   acc unchanged      28 images   (the LFO wrap)
  09A.A.00.200  f31 = 5   ???                 9 sites: COMPRESSOR x2, PEQ+COMPRESSOR x2,
                                              PEQ+COMPR+DIST x2, PEQ+COMPR+OVER x2, KERNEL w30
```

`dsp_disasm.py`'s own comment records that `092` / `094` is what FORCED `hi12[3:1]`
to be a field. `09A` is the third arm and it is **`f31 = 5`**.

★ Already in the notes, and it matters: [`lfo-ramp.md`](../lfo-ramp.md) records that
`09A.A.00.200` is the **COMPRESSOR's envelope step**, that it eats `0x600000 = 0.75`
and **`0x517CC1 = 0.636620 = 2/π`**, and that the three surviving store-gate rules
differ on 13 words of which **9 are this one** — so *"deciding between the three
gates means decoding `hi12[3:1] == 5`"*. **Recording that it was already written
down.** What is added here is the *third arm's decoded twins*: `f31 = 5` stands
against `f31 = 1` (add) and `f31 = 2` (hold) on a byte-identical word.

⛔ **CORRECTION TO §140 S5.** S5 nominates kernel `w30` (`09A.A.00.200`) as *"the
cheapest `f31=5` observable in the machine"*. It is not observable at all through the
accumulator: walking the kernel forward from `w30` gives `w31 = C0A.4.B1.820`
(C-format) and then `w32 = 000.A.FF.207`, an **`f31 = 0` barrier**, two words later.
The only channel out of `w30` is **its own bit-4 store** — and `w30` is `(bit7,
f31) = (1, 5)`, i.e. precisely one of the 13 words the three surviving store gates
disagree about. **S5 is circular**: you cannot observe `f31 = 5` through `w30`
without first deciding whether `w30` stores, and `lfo-ramp.md` says the store gate
cannot be decided without decoding `f31 = 5`. **Do not run S5.** (A saved run, in the
same spirit as §139's saving of the AUTO PAN run.)

### C. `class A, addr8 0x00, lo12 0x1D5` — the 2/π level detector

```
  010.A.00.1D5  f31 = 0   acc <- P            CHORUS w42, SD+CHORUS w53
  012.A.00.1D5  f31 = 1   acc <- acc + P      GATED REVERB w85
  018.A.00.1D5  f31 = 4   ???                 12 sites, 8 images -- the 2/pi idiom
```

The idiom, byte-identical at all 12 sites (§139 §3):

```
      02E | 026 . 2 . xx . xxx      f31 = 7 or 3
   ** 018.A.00.1D5                  f31 = 4, ST   x C-RAM = 0x517CC1 = 2/pi
      104.A.00.1D5                  f31 = 2       x C-RAM = 0x400000 = 0.5
      C40.2.C0.000                  C-format immediate
      182.A.00.000                  f31 = 1       one-pole smoother
```

`018` and `104` share `class4`, `addr8` **and all twelve `lo12` bits** — the same
operand routing — so the multiply by `2/π` and the multiply by `0.5` differ **only
in `hi12`**. Observability is mixed: at `COMPRESSOR w3` the difference reaches a
bit-4 store at `w9`; at `NO OPERATION w11` and `AUTO WAH w25` it dies at an
`f31 = 0` barrier four words later.

---

## 6. §140 S2 and S4, re-verified on the corrected population (MEASURED)

**S2.** The images with **zero** `f31 ≥ 3` on the IC311 basis are exactly

> CHORUS, MODULATED CHORUS, FLANGER, ENSEMBLE, SINGLE DELAY, MULTI TAP DELAY,
> ROOM REVERB 1, VIBRATO, MIX UP, and the five S.DELAY combis (64, 66, 67, 68, 72)

— **14 of 38, and every one of them is a purely LINEAR program.** S2's list
reproduces item for item. ★ But the converse **fails**, and S2 already said so:
PHASER and PARAMETRIC EQ are linear and do carry `f31 ≥ 3`. So the correct statement
is an **inclusion, not a biconditional**: *linear ⇒ no `f31 ≥ 3`* holds 14/14;
*`f31 ≥ 3` ⇒ nonlinear* does not. Recording S2 as already-in-the-notes.

**S4.** `f98 ≠ 0 ⇒ f31 ∈ {1,2}` on **1203 / 1207 = 99.67 %** of IC311 plain words.
The sharper contrapositive is the one that bears on this question:
**`f31 > 2 ⇒ f98 = 0` on 146 / 149 = 97.99 %** (the three exceptions all carry
`f98 = 2`). So the high `f31` codes and the `f98` field are very nearly mutually
exclusive — consistent with S4's reading that the operation is a joint `(f98, f31)`
code, and it means **any `f31 > 2` experiment must hold `f98 = 0`**, which all three
anchored pairs do.

---

## 7. Ranked candidate meanings for `f31 = 4` and `f31 = 5`

The three anchored pairs say the same thing structurally: **`hi12` bit 3 is a
modifier applied to the base operation named by `hi12[2:1]`** — `4 = LOAD+m`,
`5 = ADD+m`, `6 = HOLD+m`, `7 = base3+m`. That much is INFERRED from the pairs
(`020`↔`028` modifies LOAD; `092`/`094`↔`09A` modifies ADD/HOLD; `010`/`012`↔`018`
modifies LOAD/ADD). **What `m` is, the ROM does not say.** Ranked:

| rank | reading of bit 3 | for | against | grade |
|---|---|---|---|---|
| **1** | **RECTIFY / absolute value** (§140 S3) | `0x517CC1` is `floor(2/π·2²³)` exactly and it is **the coefficient `018` (f31=4) multiplies by**, and `2/π` is the mean of `\|sin\|`; the ISA has **no ACT code** for an absolute value; the S2 inclusion is 14/14; `lfo-ramp.md` independently records `09A` (f31=5) eating the same `2/π` | at pair A the LFO phase is masked to `[0, 2²³)` (`0x7FFFFF` wrap, 29/29) and the coefficient is `+24`, so a rectify there would be **inert** — the designer would have emitted two opcodes for one behaviour | **SPECULATIVE**, best-supported |
| **2** | **SATURATE / clip the result** | every waveshaper carries it (DISTORTION / FUZZ share the identical `02E…028…02E…028` skeleton, 42 words, only 4 differing); fits S2 | does not explain the 2/π detector, PEQ or PHASER; and at pair A the index cannot exceed 23 anyway, so it too would be inert | **SPECULATIVE** |
| **3** | **SHIFT / rescale the product** (×2 or ÷2, a headroom bit) | the 2/π word is immediately followed by a ×0.5 — a gain-staging chain; extremely common in fixed-point microcode | at pair A it would put the table index in `[0,47]`, **off the end of a 24-entry table**, in two shipping programs | **SPECULATIVE**, weakened by pair A |
| **4** | **NEGATE the product** (`negP`, already implemented) | a natural microword bit | subtraction is **already reachable** through ACT/SRC (`acc ← tB − acc`, `acc ← 0 − acc`, `allpass-adder-rerun.md`); explains none of the S2 split; at pair A it gives a **negative table index** | **SPECULATIVE**, weak |
| **5** | **product bypassed, `acc ← bus`** (`prod`) | would explain the operand-free `02x.2.00.000` family | at pair A the bus is the raw 23-bit phase — index wildly out of range | **SPECULATIVE**, weak |
| — | **selects a second accumulator (ACCB)** | — | ⛔ **REFUTED**: §27's argument, killed by §28 against its own criterion, shown actively harmful by §32's bisection, and §139 §2 withdrew its evidence entirely (all three cited words carry bit 11, where `f31` is not a field) | **REFUTED — do not re-test** |

⚠ **Every candidate above is uncomfortable at pair A.** Readings 1 and 2 are inert
there; 3, 4 and 5 put the table index out of range in a shipping effect. That is
*exactly* `f31-high.md` item 3's warning — *"the four readings are a starting set,
not an enumeration"* — arriving as a measurement rather than a caution. **The most
likely truth is that the reading space is wrong**, and the missing reading is
something about the *alignment* of the product or the *domain* of the result
(index-vs-fraction), which pair A's 24-entry table is unusually well placed to
expose. Marked **SPECULATIVE** and kept out of the measured findings, per the
brief's invitation to let patterns emerge.

---

## 8. THE DECIDING EXPERIMENT — for the emulator worker

### E0 (prerequisite, from §139 §5) — make the stimulus alternate sign

`bx_stim` (`upd6383.h`) returns `0x010000 + n·0x101` and `0x018000 + n·0x203`:
**strictly positive and monotone**. A rectifier is invisible to it, so candidate 1
**cannot fail** under the present instrument. Fix this first or no result about
`f31 > 2` means anything.

### E1 ★ — the 24-entry index vehicle (the pass's main deliverable)

**Vehicle.** `algo 71` PEQ+CHORUS `w41` = `020.A.06.1D5` (`f31 = 0`, decoded
`acc ← P`) against `algo 73` PEQ+FLANGER `w41` and `algo 74` PEQ+VIBRATO `w34` =
`028.A.06.1D5` (`f31 = 4`). Nine byte-identical words around each; fetched
coefficient `0x000018 = 24` verified identical in all three C-RAM banks.

**Observable.** The cell written by `w+1` (`182.2.00.407`, `SRC 0x10` = accumulator,
`ACT 0x07` = `mem[ptr] ← bus`), traced over one full LFO period. **No** `f31 = 0`
barrier, **no** biquad, **no** store-gate dependence.

**Known input.** The LFO ramp, anchored nine-fold to `floor(f·2²³/44100)` for round
decimal rates, masked to `[0, 2²³)` (`lfo-ramp.md`).

**Hard constraint the answer must satisfy.** The result must be a valid index into a
**24-entry** table, i.e. in `[0, 23]` after the `>>23` alignment. PEQ+FLANGER and
PEQ+VIBRATO are shipping effects; any reading that puts the index outside that range
is refuted by the instrument itself.

**Pre-register these before running:**

| reading | predicted index trajectory at `a73` vs the `a71` reference |
|---|---|
| `base` (bit 3 inert) | identical to `a71` |
| rectify | identical to `a71` (phase ≥ 0) ⇒ **this vehicle is BLIND to rectify** |
| saturate | identical to `a71` (index already ≤ 23) ⇒ **blind** |
| `negP` | `[−23, 0]` — negative index |
| shift ×2 | `[0, 47]` — off the end of the table |
| `prod` (`acc ← bus`) | up to 2²³ — wildly off |

**★ THE CONTROL THAT CAN FAIL.** Patch `a73 w41`'s `hi12` from `0x028` to `0x020`
and confirm the traced index sequence becomes byte-identical to `a71`'s. If it does
not, the vehicle is not what this note claims and everything above about pair A is
withdrawn.

**★ THE PRE-REGISTERED FALSIFIER FOR THE READING SPACE.** If every enumerated
reading either reproduces the `f31 = 0` trace exactly or drives the index out of
`[0,23]`, then the space is wrong — **do not add a sixth reading to fit the data**
(`f31-high.md` item 3, and `ROADMAP-2026-07-29.md` P5.2's own instruction). Record
the blindness and move to E2.

### E2 — the 2/π detector, with E0's sign-alternating stimulus

Pair C in `algo 36` COMPRESSOR (`w2 026.2.F3.000 | w3 018.A.00.1D5 | w4
104.A.00.1D5 | w5 C40.2.C0.000 | w6 182.A.00.000`), difference reaching the bit-4
store at `w9`. **Candidate 1 predicts the detector output is EVEN in the sign of the
input; candidates 3/4/5 predict it is ODD.** One trace separates them. This is the
only experiment that can test rectify at all, because E1 is provably blind to it.

### E3 — extend the reading space in `action00_discriminate.Machine`

`F31HI = ("base", "negP", "hold", "prod")` contains **no rectify, no saturate and no
shift**. Add `rect` (`|P|`), `sat` and `shift` before E1/E2 are scored, or the
experiment enumerates a space that cannot contain the answer.

### ⛔ Do NOT run

* **AUTO PAN** — §139 §1 already showed its four sites are the operand-free NOP form.
* **PARAMETRIC EQ's biquad** — `f31-high.md` item E, PROVEN BY CONSTRUCTION blind.
* **kernel `w30`** (§140 S5) — §5 B above: circular, its only channel is the store
  whose gate needs `f31 = 5` decoded first.

---

## 9. Evidence grades

| section | grade |
|---|---|
| §2 population correction, and what moves in `f31-high.md` items B/C | **MEASURED** |
| §3 census, §3.1 §139 §4 re-verification, §3.2 terminator sub-structure | **MEASURED** |
| §4.1 contingency / MI; bit 5 exhaustive on `f31 ∈ {3,6,7}` | **MEASURED** |
| §4.3 `f31` is a genuine field, not aliased | ★ **FORCED** by the byte-identical pairs |
| §4.3 §140 S1 refuted **as the carrier** (it survives as a distribution) | **FORCED** |
| §4.4 / §5 the eight minimal-pair contexts and the nine-word run | **MEASURED** |
| §5 A the coefficient is `24` in all three arms; the slot is the LFO index scale | **MEASURED** (the slot's role is `lfo-ramp.md` §10's, MEASURED there) |
| §5 B §140 S5 is circular | **FORCED** |
| §6 S2 inclusion 14/14; S4 at 99.67 % / 97.99 % | **MEASURED** |
| §7 bit 3 is a modifier over the base named by `hi12[2:1]` | **INFERRED** from the three pairs |
| §7 which modifier | **SPECULATIVE**, ranked, none forced |
| §8 the experiments | **not yet run** |

## 10. What was already in the notes (rule ★)

Recorded plainly, because finding it already written is a result:

* **§140 S1** (bit 5 changes what `f31` means) — already there. Measured here; then
  refuted as the carrier.
* **§140 S2** (`f31 ≥ 3` marks the nonlinear stage) — already there, re-verified.
* **§140 S3** (bit 2 of the field = rectify) — already there, and still the
  best-supported candidate. **Not discovered here.**
* **§140 S4** (`f98` and `f31` nearly exclusive) — already there, re-verified.
* **§139 §3** (`0x517CC1 = floor(2/π·2²³)` and the four-word idiom) — already there.
* **§139 §4** (the absences) — already there, 6 of 6 survive.
* **§139 §5** (the stimulus cannot see a rectifier) — already there, and it is E0.
* **`lfo-ramp.md` §10** (the class-A word before a table lookup is a phase-to-index
  scale, coefficient 24, 24-entry table) — already there. **This is what makes pair
  A decidable, and it had been sitting in the notes since the LFO pass.**
* **`lfo-ramp.md`** (`09A.A.00.200` is the COMPRESSOR envelope step, eats `2/π`, and
  9 of the 13 store-gate-disputed words) — already there.
* **`dsp_disasm.py`** (`092`/`094` forced `f31` into `hi12`) — already there.

New here: the population defect and its effect on items B/C; the terminator's
2-bit `hi12[3:2]` code; the exchangeability measurement; **the three anchored
minimal pairs**, above all the nine-word `a71` / `a73` / `a74` run with a verified
common coefficient; the 46-site census of the table-lookup scale slot; and the
demonstration that §140 S5 is circular.
