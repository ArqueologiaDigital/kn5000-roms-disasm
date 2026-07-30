# SPECULATIVE PATTERNS — a corpus-wide idiom, structure and field sweep

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date **2026-07-30**.
Static analysis of the Sub CPU ROM corpus only — **no MAME source was read or
written, nothing was run, no hardware**.

Population: the **3057-word** corpus = 60-word header + 23-word output stage +
**38 distinct body images** (the 91 well-formed IC311 streams collapse to 38;
the five IC310/MN19413 streams 79/88/89/90/91 are excluded, per
[`second-dsp-and-ready.md`](../second-dsp-and-ready.md) §2 and the
population correction in [`F31_HIGH_findings.md`](F31_HIGH_findings.md) §2).

Tools, all stdlib-only, all in `dsp/tools/`:

```
python3 dsp/tools/pat_corpus.py                      # the loader + field decode
python3 dsp/tools/pat_ngram.py  control|null|top|maximal|det
python3 dsp/tools/pat_struct.py combi|split|matrix|twins|period
python3 dsp/tools/pat_fields.py addr8|closure|family|traits|cooc|pos
```

**Grades.** **MEASURED** = it comes out of the tool. **FORCED** = no alternative
survives. **INFERRED** = the best reading, alternatives exist. **SPECULATIVE** =
a pattern with a proposed meaning and no test yet. Everything speculative is in
**§11**, separated from everything above it, as the brief requires.

★ **Owning notes checked first**, per the standing rule. Where a result is
already recorded, this note **says so and cites it** — that is a result, not a
failure. Notes read before anything was computed:
[`LEDGER.md`](../LEDGER.md) (all four tiers), [`instruction-set.md`](../../instruction-set.md),
[`dark-words.md`](../dark-words.md), [`closure-pointer.md`](../closure-pointer.md),
[`k4-cursor.md`](../k4-cursor.md), [`r1-allpass-motif.md`](../r1-allpass-motif.md),
[`lfo-ramp.md`](../lfo-ramp.md), [`output-stage-decode.md`](../output-stage-decode.md),
[`host-side.md`](../host-side.md), [`algorithms/families.md`](../../algorithms/families.md),
`SPECULATIVE-APPLIED-REGISTER.md` §139 / §140, and (read-only, another worker's)
[`F31_HIGH_findings.md`](F31_HIGH_findings.md).

⚠ **§§166–169 landed while this pass was running** (commits `f9b008a`…`e007889`).
Everything that touches the table-lookup idiom was **re-measured against them
before publication**, not against the state of the notes at the start — §3.1,
SP1 and EXP-1 are written post-§169 and cite it. §166 independently found the
`C63` ↔ class-6 bijection this pass's n-gram sweep also produces; that half is
**ALREADY KNOWN and credited**, and what survives as new is the two words
*upstream* of `C63`.

⚠ This note **does not touch** the LEDGER's dead-end list. In particular
**dead end #3** — *"`addr8` on the class-6 word = the table EXTENT"* — is
respected: §3.2 below reads class-6 `addr8` as a **selector** (which
`instruction-set.md` already says), never as an extent, and does not revive the
`0x18 = 24 = the wavetable period` numerology that #3 killed.

---

## 0. THE CONTROL — does the method rediscover what is already known?

`python3 dsp/tools/pat_ngram.py control`. A pattern-finder that misses the
established idioms is measuring noise. Ranked by (frequency × programs) over all
n-grams of that length:

| known idiom | n | count | programs | rank (exact key) | rank (addr8-masked) |
|---|--:|--:|--:|---|---|
| table-lookup motif `C63 / 4CD / 1CE` | 3 | 29 / 46 | 16 / 25 | **#1** of 1637 | **#2** of 817 |
| LFO block `092.A.dd.200 / 082.2.00.1C0 / 094.A.dd.200` | 3 | 24 / 29 | 14 / 16 | **#7** of 1637 | **#5** of 817 |
| all-pass motif, 6 words (R1) | 6 | 13 / 15 | 2 / 2 | #19 of 2092 | #54 of 1280 |
| all-pass inner run, 4 words | 4 | 15 | 2 | #42 of 1841 | #74 of 1007 |

**PASS.** All four are found; the two corpus-wide ones are in the top seven.
Two sanity checks fall out of the control and both reproduce published numbers
exactly:

* the all-pass motif's `15` occurrences over **2 distinct images** is
  `r1-allpass-motif.md`'s **114 slots in 13 programs** re-expressed on the
  distinct-image basis (`ROOM REVERB 1` ×9 + `GATED REVERB` ×6 = 15; the 12
  reverb presets share one image);
* the LFO block's `29` in `16` images is `lfo-ramp.md`'s **29 blocks in 16
  programs**, to the digit.

**The all-pass motif ranks lower than the LFO/table idioms because it lives in
only two images.** That is the metric working, not failing: `count × programs`
rewards *portability*, and the reverb motif is not portable. Both orderings are
printed so neither is hidden.

⚠ **Two keys, and the difference is load-bearing.** `exact` = the whole 36-bit
word; `m8` = **`addr8` masked out**. The LFO block and the all-pass motif both
vary `addr8` between instances, so `m8` is the key that finds them whole. On a
**C-format** word `addr8` is immediate data, so `m8` deliberately merges
different immediates — flagged at every use.

---

## 1. ★★★ THE CORPUS IS A MACRO LIBRARY, AND THE NULL IS ANNIHILATED — **MEASURED**

`python3 dsp/tools/pat_ngram.py null` (within-program shuffle, B = 60; the
shuffle preserves each program's word multiset and its length, so it is the
right null for *order*).

Distinct n-grams occurring ≥ 2 times:

| n | obs (exact) | null | z | obs (m8) | null | z |
|--:|--:|--:|--:|--:|--:|--:|
| 2 | 396 | 229.1 ± 10.4 | +16.1 | 334 | 498.7 ± 13.1 | **−12.6** |
| 3 | 385 | 8.9 ± 3.5 | +106.5 | 414 | 38.0 ± 6.5 | +57.7 |
| 4 | 371 | 0.3 ± 0.6 | +594 | 446 | 1.7 ± 1.4 | +319 |
| 5 | 350 | 0.0 ± 0.2 | +1950 | 457 | 0.1 ± 0.3 | +1523 |
| 6 | 330 | 0.0 ± 0.0 | ∞ (null max 0) | 470 | 0.0 ± 0.0 | ∞ (null max 0) |

⚠ **The one negative z is not a counter-result and must not be quoted as one.**
At `n = 2, m8` the *count of distinct* recurring bigrams is below the null
because the real corpus **concentrates** its repeats into fewer bigram types at
much higher multiplicity, while a shuffle sprays them thinly over many types.
The statistic is non-monotone in idiomaticity at n = 2; from n = 3 up it is not.
The coverage measure below is the one to quote.

**Coverage.** `pat_ngram.py maximal`: fraction of the 3057 word-slots lying
inside a **maximal repeat** (both left- and right-diverse, length ≥ 4, count ≥ 2,
in ≥ 2 programs) —

```
   key m8     2439 / 3057 = 79.8 %        NULL 0.2 % +- 0.2 % (max 0.7 %)
   key exact  1793 / 3057 = 58.7 %        NULL 0.0 % +- 0.1 % (max 0.3 %)
```

**Deterministic successors** (`pat_ngram.py det`): of the 144 word forms
occurring ≥ 4 times, **44 (30.6 %) have exactly ONE successor in the entire
corpus** — null **0.0 % ± 0.0 %**. The top ones are the macro glue:

```
   x35  A00.0.00.041 -> 880.1.20.2C7      x35  804.8.16.415 -> 212.A.FF.407
   x35  202.A.01.1D4 -> 202.A.00.1D5      x34  212.A.01.412 -> 202.A.01.1D5
   x29  C40.3.20.44C -> A00.0.00.041      x29  000.6.18.4CD -> 012.4.01.1CE
   x28  212.2.00.419 -> 880.1.20.64B      x24  092.A.00.200 -> 082.2.00.1C0
```

★ **ALREADY KNOWN, and this quantifies it.** `algorithms/families.md`'s
Combinations section already asserts the effects are *"compiled from a common
library"*. What was missing was a number and a null; **79.8 % coverage against a
0.2 % null** is that number.

---

## 2. THE MACRO LIBRARY — top 26 maximal repeats, `m8` key — **MEASURED**

`python3 dsp/tools/pat_struct.py`/`pat_ngram.py maximal --key m8`. Score =
count × programs. Field decode for every member is printed by the tool; the
compact form is given here.

| # | len | ×  | progs | the idiom | status |
|--:|--:|--:|--:|---|---|
| 1 | 4 | 46 | 25 | `040.0.**.C63 \| 000.6.**.4CD \| 012.4.**.1CE \| 104.2.**.1CE` | **known 3-word core**, §3.1 extends it |
| 2 | 3 | 34 | 19 | `012.4.**.1CE \| 104.2.**.1CE \| 102.2.**.000` | tail of #1 |
| 3 | 4 | 31 | 17 | #2 + `000.A.**.415` | tail of #1 |
| 4 | 5 | 31 | 16 | #1 + `102.2.**.000` | §3.1 |
| 5 | 3 | 29 | 16 | `092.A.**.200 \| 082.2.**.1C0 \| 094.A.**.200` | **known** (LFO, `lfo-ramp.md`) |
| 6 | 6 | 35 | 13 | `202.A.**.1D5 \| 202.A.**.1D4 \| 202.A.**.1D5 \| 102.2.**.687 \| 804.8.**.415 \| 212.A.**.407` | **known** (biquad core, §124) |
| 7 | 3 | 35 | 13 | `A00.0.**.041 \| 880.1.**.2C7 \| 102.A.**.4C8` | the **swept-tap read**, §3.3 |
| 8 | 7 | 34 | 13 | #6 + `000.2.**.647` | biquad |
| 9 | 7 | 34 | 12 | `212.A.**.412` + #6 | biquad |
| 10 | 8 | 33 | 12 | `212.A.**.412` + #8 | biquad |
| 11 | 6 | 28 | 14 | #1 + `102.2.**.000 \| 000.A.**.415` | §3.1 |
| 12 | 4 | 26 | 15 | #5 + `000.2.**.447` | **known** (26 of 29, `lfo-ramp.md`) |
| 13 | 5 | 25 | 13 | `182.2.**.000` + #1 | ★ §3.1 |
| 14 | 3 | 21 | 15 | `000.2.**.1CD \| 000.2.**.40E \| 212.2.**.000` | body prologue, §6 |
| 15 | 3 | 25 | 12 | `000.2.**.000 \| 212.2.**.419 \| 880.1.**.64B` | delay-write glue |
| 16 | 7 | 29 | 10 | `900.1.**.1D5 \| 192.A.**.000 \| 082.2.**.1C0 \| C40.3.**.44C \| A00.0.**.041 \| 880.1.**.2C7 \| 102.A.**.4C8` | ★ the **CHORUS VOICE**, §3.3 |
| 17 | 8 | 27 | 10 | `000.A.**.1D3` + #10 | biquad |
| 18 | 9 | 26 | 10 | `000.A.**.1D3` + #10 + `000.2.**.647` | ★ **the full 9-word biquad section**, §3.4 |
| 19 | 3 | 26 | 10 | `000.2.**.407 \| 000.2.**.1D5 \| 202.A.**.415` | delay tail |
| 20 | 5 | 21 | 12 | `182.2.**.407` + #1 | ★ §3.1 |
| 21 | 3 | 22 | 10 | `212.2.**.419 \| 880.1.**.64B \| 000.2.**.407` | delay-write glue |
| 22 | 3 | 22 | 10 | `202.A.**.415 \| 204.2.**.1CD \| 000.2.**.40E` | delay tail |
| 23 | 6 | 19 | 10 | `182.2.**.000` + #11 | §3.1 |
| 24 | 6 | 20 | 9 | `000.2.**.000 \| 212.2.**.419 \| 880.1.**.64B \| 000.2.**.407 \| 000.2.**.1D5 \| 202.A.**.415` | **SINGLE DELAY tail** |
| 25 | 5 | 20 | 9 | `880.1.**.2D9 \| 202.A.**.655` + #15 | **SINGLE DELAY head** |
| 26 | 4 | 20 | 9 | `202.A.**.415 \| 204.2.**.1CD \| 000.2.**.40E \| 212.2.**.000` | delay tail |

**200 maximal repeats in total.** Longest with ≥ 2 programs: the reverb's
**24-word triple all-pass core** (`GATED REVERB` ×1 + `ROOM REVERB 1` ×5) and a
**24-word CHORUS/MODULATED-CHORUS run**.

---

## 3. IDIOMS WHOSE EXTENT IS LONGER THAN THE OWNING NOTE RECORDS — **MEASURED**

### 3.1 ★★★ The table-lookup idiom reaches TWO words further UPSTREAM, and the word at −2 is `ACT 0x15`

⚠ **Written after §§166–169 landed mid-pass; re-measured against them, not
against the state of the notes when this pass started.** §166 already established
the **`C63` ↔ class-6 bijection, 53/53 both ways**, so that half of §3.1's first
draft is **ALREADY KNOWN and is cited, not claimed.** What is new is what sits
*before* the `C63` word — and it lands squarely on the current NEXT TASK.

Over all 53 `C63` sites (C-format excluded — the kernel's `0C646A2007` is the
corpus's only C-format class-6 word and is not one of these):

```
  offset  what is there                                        count
   -2     class A, ACT 0x15, SRC 0x07 (mem[ptr])                 29 \  46 of 53
   -2     class A, ACT 0x15, SRC 0x10 (acc)                      17 /
   -2     class 4, ACT 0x0E  (= the PREVIOUS lookup's own word)   7    the CHAINED sites
   -1     class 2, ACT 0x07, SRC 0x10   acc -> mem[ptr]          21
   -1     class 2, ACT 0x00, SRC 0x00                            25
   -1     class 2, ACT 0x0E, SRC 0x07                             7    the CHAINED sites
    0     040/142.0.**.C63   SRC 0x11 / ACT 0x03  -> tempB       53    (§166)
   +1     class 6            SRC 0x13 / ACT 0x0D  -> table[..]   53    (§166)
```

★★★ **Every non-chained table lookup in the machine — 46 of 46 — is preceded at
exactly −2 by a class-A `ACT 0x15` word.** The other 7 are the *chained* second
lookups (the class-6 `lo12 = 0x407` sub-family in CHORUS / MODULATED CHORUS /
ENSEMBLE / S.DELAY+CHORUS / PEQ+CHORUS), whose index comes from the first
lookup's own output. So the account is **exceptionless at 53/53**.

**Why this matters right now.** §169 named `000.A.00.1D5` — class A, `SRC 0x07`,
**`ACT 0x15`** — as *"the word that must issue `scale × phase`"*, and measured
`m_p 0..0 chg 0` — the index multiply never issues, because `ACT 0x15` decodes
as `LO_ACT_NONE_5`. **The corpus says that is not a CHORUS-specific word: the
same slot, at the same offset, is occupied by a class-A `ACT 0x15` word at every
lookup in the machine.** Decoding `ACT 0x15` therefore unblocks 46 lookup sites
in 25 images at once, not one site in one program.

★★ **And it hands over a minimal-pair family for decoding it.** The 46 `ACT 0x15`
words at −2 split into exactly two SRC flavours — `SRC 0x07` (`mem[ptr]`) ×29 and
`SRC 0x10` (the accumulator) ×17 — same ACTION, same class, same downstream
consumer, two different operands. That is the shape a discriminator needs, and it
is available statically. CHORUS's own site is `202.A.07.1D5` (`SRC 0x07`) at
body `w28`.

The tail is exceptionless one word further than `instruction-set.md` records
(`012.4.01.1CE | 104.2.**.1CE`, 46/46) and usually two more
(`102.2.**.000 | 000.A.**.415`, 28 of 46 in 14 images), and the `−1` word is a
class-2 `hi12 == 0x182` in **46 of 46** non-chained cases. Assembled:

```
   xxx.A.**.1D5   class A, ACT 0x15     <- the multiply that never issues (169)
   182.2.**.407   SRC 0x10 / ACT 0x07   acc -> mem[ptr]      x21
    or 182.2.**.000  SRC 0x00 / ACT 0x00                     x25
   040.0.**.C63   SRC 0x11 / ACT 0x03   -> tempB             (166)
   000.6.TT.4CD   SRC 0x13 / ACT 0x0D   -> table[tempB]      TT = selector (3.2)
   012.4.01.1CE   SRC 0x07 / ACT 0x0E   (class 4: ONE word in the whole ISA)
   104.2.**.1CE   SRC 0x07 / ACT 0x0E
  [102.2.**.000 | 000.A.**.415]                              28 of 46
```

**NULL.** Pooled-marginal expectation of the 4-word `C63`-onwards core is
**2.19e-4** occurrences; adding the `182.2` head takes it to **2.26e-6**. The
within-program shuffle null for the 5-word form is **0.00 ± 0.00 over 40
shuffles** (max 0), against 25 observed. For the `ACT 0x15` slot: `ACT 0x15` is
707 of 2989 plain words = 23.7 %, and class-A-**and**-`ACT 0x15` is **472** of
2989 = **15.8 %**, so chance predicts **8.4 of 53** sites, not 46. Binomial
`P(X ≥ 46 | n = 53, p = 0.158) < 1e-30`.

**Grade: MEASURED** (the offsets, the counts, the split). The reading of the
chain as *multiply → deposit → index-load → table-read* is **INFERRED** from the
anchored field decodes plus §166 and §169; SP1 in §11 states what is still
speculative in it.

### 3.2 ★★★ The class-6 `addr8` selector, resolved to its two CONSUMERS — **MEASURED**

`instruction-set.md` already says class-6 `addr8` is a *table selector*. What
nobody had done is count, per image, what each selector value goes with:

```
   image                  LFO blocks   000.6.18.4CD   000.6.28.4CD
   CHORUS                       1            1              0
   MODULATED CHORUS             2            2              0
   FLANGER / PHASER / AUTO PAN /
   VIBRATO / RING MOD           2            2              0     (each)
   MIX UP                       3            3              0
   ENSEMBLE, S.DELAY+CHORUS,
   PEQ+CHORUS                   1            1              0     (each)
   S.DELAY+{FLANGER,VIBRATO,PHASER},
   PEQ+{FLANGER,VIBRATO}        2            2              0     (each)
   ---------------------------------------------------------------
   DISTORTION / OVERDRIVE / FUZZ / EXCITER /
   PEQ+COMPR+DIST / PEQ+COMPR+OVERDR /
   PEQ+DIST+DELAY / PEQ+OVERDR+DELAY   0      0              2     (each)
   ROCK ROTARY                  0            0              1
   ---------------------------------------------------------------
   TOTAL                       29           29             17
```

★ **`addr8 = 0x18` occurs exactly once per LFO block, PER IMAGE, in all 25
images that carry either — 29 = 29, no exceptions.** `addr8 = 0x28` occurs
**only** in the eight waveshaper images (twice each = stereo) plus `ROCK ROTARY`
once, and **never** in an image with an LFO block. The two selector values
partition the corpus **modulation | waveshaper** with zero overlap.

**NULL.** Under the trait test (`pat_fields.py traits`, family read off the
effect *name*, never the words) `addr8 == 0x18` present in 16 images all of
which are MOD has `P = 7.6e-10` against a size-matched random-subset null.

**Grade: MEASURED** (the counts, the partition). The identification of `0x18`
with the host's uploaded **LFO WAVEFORM table** (`host-side.md` A3: 36- or
32-entry D-RAM table at base cell `0x1D`, SINE / TRIANGLE / SQUARE) is
**INFERRED** — it follows from the 1:1 accounting, not from the number 0x18.
⛔ It is explicitly **not** the refuted "0x18 = 24 = the table period" reading
(LEDGER dead end #3); nothing here depends on what the number *equals*.

There is a third, smaller class-6 sub-family the notes list but do not separate:
`lo12 = 0x407` (7 words, `addr8 ∈ {0x1A, 0x1E, 0x20}`) occurs **only** in
`CHORUS`, `MODULATED CHORUS`, `ENSEMBLE`, `S.DELAY+CHORUS`, `PEQ+CHORUS` —
i.e. only in the multi-voice chorus family, and `ENSEMBLE` carries all three
values. **Class 6 is 53 words, 5 distinct forms, and they split 46 `4CD` / 7
`407`.**

### 3.3 ★★ The CHORUS "voice" is a 7-word macro, and it is what carries a swept tap

Item #16, 29 instances in 10 images (`CHORUS` ×4, `MODULATED CHORUS` ×4,
`ENHANCER` ×2, `ROCK ROTARY` ×3, `VIBRATO` ×2, `MIX UP` ×2, `S.DELAY+CHORUS` ×4,
`S.DELAY+VIBRATO` ×2, `PEQ+CHORUS` ×4, `PEQ+VIBRATO` ×2):

```
   900.1.**.1D5     delay-DRAM      (mode1+ESC)
   192.A.**.000     class-A multiply, store
   082.2.**.1C0     SRC 0x07 = mem[ptr] -> acc          <- the LFO phase read word
   C40.3.20.44C     C-format immediate, imm13 = 800 (A = 25) -- ONE form, x29
   A00.0.**.041     class 0, SRC 0x01 ACT 0x01           <- DARK
   880.1.**.2C7     delay-DRAM READ (addr8 bit 6 = 0)    <- the swept tap
   102.A.**.4C8     SRC 0x13 (the TABLE port) ACT 0x08
```

`dark-words.md` §2 names the shorter `900.1.60.1D5 … C40.3.20.44C, A00.0.00.041,
880.1.20.2C7` run as *"a repeating idiom"* in CHORUS with 4 instances; this is
the same object measured across the whole corpus, **7 words wide and 29
instances in 10 images**, and it ends on a `SRC 0x13` **table read** — the same
port the class-6 lookup uses. Its last three words are a deterministic chain
(§1). **MEASURED.**

### 3.4 The biquad section is 9 words and it is exact — a second known-answer control

Item #18: `000.A.**.1D3 | 212.A.**.412 | 202.A.**.1D5 | 202.A.**.1D4 |
202.A.**.1D5 | 102.2.**.687 | 804.8.**.415 | 212.A.**.407 | 000.2.**.647`,
**26 instances in 10 images**. This is §124's *"verbatim core match, the stride-9
repeat"* recovered blind. `PARAMETRIC EQ` carries 9 of them; the count agrees
with the documented "10 sections, 5 bands × 2 channels" once the 10th section's
trailing word is counted (`pat_struct.py period` shows the periodic run as
5 × 9 + 4 × 9 either side of the `rstcur`). **MEASURED, and it is a control:
the method reproduces the one program whose arithmetic is independently known.**

---

## 4. ARE THE COMBIS THEIR COMPONENTS CONCATENATED? — **NO** — **MEASURED**

`python3 dsp/tools/pat_struct.py combi|split`. `cov(B|C) = LCS(C,B)/len(B)` —
the fraction of base *B* recoverable, **in order**, inside combi *C*.
Components are taken from the effect **name** only.

```
                                    key=exact        key=m8
   mean cov, DECLARED components     0.345            0.536
   mean cov, BEST non-component      0.646            0.738   <- the control
   mean cov, ALL non-components      0.214 +- 0.158   0.323 +- 0.177
   z of the declared mean            +4.8             +7.0
```

★ **The declared bases are significantly present — and every combi resembles
another COMBI more than it resembles its own bases.** For 15 of 15 combis the
best-matching non-component is another combi or a sibling.

The concatenation test is worse still. Best split point `k` maximising
`cov(base1 | C[:k]) + cov(base2 | C[k:])`:

| combi | len | k* | base1 in prefix | base2 in suffix |
|---|--:|--:|--:|--:|
| S.DELAY+CHORUS | 95 | 17 | SINGLE DELAY 0.083 | CHORUS 0.500 |
| S.DELAY+FLANGER | 100 | 26 | SINGLE DELAY 0.104 | FLANGER 0.569 |
| S.DELAY+PHASER | 110 | 17 | SINGLE DELAY 0.125 | PHASER 0.387 |
| AUTO WAH+S.DELAY | 105 | **85** | AUTO WAH 0.569 | SINGLE DELAY 0.125 |
| PEQ+CHORUS | 93 | 17 | PARAMETRIC EQ 0.086 | CHORUS 0.514 |
| PEQ+COMPRESSOR | 59 | 10 | PARAMETRIC EQ 0.076 | COMPRESSOR 0.625 |

⇒ `algorithms/families.md`'s *"one or two flat biquad bands and/or a
single-delay block, then a standalone effect block verbatim"* is **half right**.
The **second** component is substantially verbatim (0.39–0.63); the **first** is
not (0.076–0.125). The PEQ/S.DELAY head is a *reduced* block — a 1-band flat PEQ
is not the 5-band PARAMETRIC EQ program, and the head S.DELAY is not the
48-word SINGLE DELAY program.

★ **AND THE NAME ORDER IS REAL — a control that could have failed and did not.**
Scoring the *reversed* assignment (base2 in the prefix, base1 in the suffix):
forward mean **0.551** vs reversed **0.490**, and forward wins **10 of 11** with
1 tie and **0 reversals** (`S.DELAY+S.DELAY` is the tie, necessarily).
Binomial `P(10/10) = 9.8e-4`. **The order in the effect's NAME is the order in
the microcode.** MEASURED.

Pairwise longest common **contiguous** run over all 780 program pairs: observed
mean 5.43 / max 42, shuffled mean 1.56 / max 4.

---

## 5. ★★★ DISTORTION AND FUZZ ARE ONE PROGRAM, PARAMETERISED ONLY BY `addr8` — **MEASURED**

`python3 dsp/tools/pat_struct.py twins`. The only pair in the corpus with
identical `(hi12, class4, lo12)` sequences:

```
   a32 DISTORTION  <->  a34 FUZZ,  both 42 words
      words differing OUTSIDE addr8 : 0
      words differing at all        : 4
      w6   092.2.F9.700  vs  092.2.86.700     addr8   -7  vs  -122
      w8   182.2.07.000  vs  182.2.7A.000     addr8   +7  vs  +122
      w16  000.2.F0.40E  vs  000.2.7D.40E     addr8  -16  vs  +125
      w17  212.2.10.000  vs  212.2.83.000     addr8  +16  vs  -125
```

Both twins are **two ± pairs**: `(−7, +7)` and `(−16, +16)` for DISTORTION,
`(−122, +122)` and `(+125, −125)` for FUZZ — each pair sums to zero, so the two
programs have the *same* net pointer walk (§8: both −5) and differ only in
**how far from the cursor they reach**. `w8` is a `182.2` word, i.e. the head of
a table-lookup macro (§3.1), and `w6`/`w8` bracket it.

Nothing in `analysis/` or `algorithms/` records this. `algorithms/families.md`
lists DISTORTION and FUZZ in the same paragraph as *"an AGC waveshaper through
the 3-word table-lookup idiom"* and `programs.tsv` gives them different roles
(*"curve A"* vs *"rail-clip"*), which the words do **not** support: **the two
effects run the same 42 instructions**. **MEASURED.**

---

## 6. HAND-UNROLLED STAGES, AND WHAT A STAGE DOES TO THE POINTER — **MEASURED**

`python3 dsp/tools/pat_struct.py period` (period *p* accepted only with ≥ 2 full
repetitions — the naive "run ≥ p+1" criterion is satisfied by a single matching
pair and was corrected before any number below was taken).

| program | period | reps | at | net signed-`addr8` per period |
|---|--:|--:|---|---|
| **PHASER** | **3** | **9** | w12 and w71 | `0 0 0 0 0 0 0 0 0` (both) |
| S.DELAY+PHASER | 3 | 4 | w26 and w86 | `0 0 0 0` (both) |
| ROOM REVERB 1 | 8 | 5 / 4 | w19 / w69 | `0 0 0 0 0` / `−70 0 0 0` |
| GATED REVERB | 8 | 2 / 3 | w13 / w39 | `0 0` / `−60 0 0` |
| **PARAMETRIC EQ** | **9** | **5 / 4** | w5 / w59 | `4 4 4 4 −82` / `4 4 4 4` |
| ENSEMBLE | 10 | 3 / 3 | w6 / w64 | `1 1 −13` / `1 1 −18` |
| SINGLE DELAY | 5 | 2 / 2 | w10 / w33 | `1 −74` / `1 −75` |
| MULTI TAP DELAY | 4 | 3 | w10 | `1 1 −11` |
| MIX UP | 4 | 3 | w4 | `1 1 8` |
| ROCK ROTARY | 8 | 2 | w35 | `−3 −17` |

**38 of 70 stage instances have net pointer displacement exactly 0.**

Two of these are known-answer controls and both pass: `ROOM REVERB 1`'s
period 8 is the all-pass core plus its two `nop`s, and the 5 + 4 split
reproduces `algorithms/reverb.md`'s *"ladders of 5 and 4"*; `PARAMETRIC EQ`'s
period 9 reproduces §124's stride-9, and its **+4 per section** is exactly the
**4 Direct-Form-I state words** per section that the host's 40-cell zero-fill
(`0x50..0x77` = 5 bands × 2 ch × 4) implies. Two independent derivations of the
same 4.

★ **The genuinely new row is PHASER.** `algorithms/families.md` says in as many
words: *"in the phaser its position differs and the **stage count is still not
decoded**"*. The corpus decodes it:

```
   a05 PHASER  w12..w38 :  9 identical 3-word stages, twice (w12 and w71)
       stage k =  102.2.(0x45+k).1CD | 212.2.01.412 | 104.2.(0xBA-k).1D5
       displacements    +(69+k)      ,    +1        ,   -(70+k)      = 0
       operand offsets from the stage base: 0, +(69+k), +(70+k)
```

The two operand offsets walk **outward in lock-step**, `+69…+77` and `+70…+78`,
which is a **10-cell contiguous shift register** read as overlapping pairs
`(state[k], state[k+1])` — the textbook cascaded first-order all-pass.
`S.DELAY+PHASER` carries the same stage at 4 repetitions × 2.

**Grade:** the period, the repetition count and the arithmetic are **MEASURED**;
the shift-register reading is **INFERRED** (it follows from the ISA's own
MEASURED `addr8` post-increment plus the offsets, not from any new assumption).

---

## 7. `addr8` × `class4` — WHERE SIGNED ENDS AND ABSOLUTE BEGINS — **MEASURED**

`python3 dsp/tools/pat_fields.py addr8`. **Null stated first:** under a uniform
`addr8` the share of values with `|s8| ≤ 32` is `65/256 = 25.4 %`, and the share
`≥ 0x80` is 50 %. A *signed displacement* clusters at small `|s8|` **and**
straddles `0x80`; an *absolute address* does neither.

| bucket | n | distinct | \|s8\|≤32 | =0 | ≥0x80 | mean\|s8\| | reading |
|---|--:|--:|--:|--:|--:|--:|---|
| cls 2 (mode 2, ptr+) | 1556 | 105 | **84.2 %** | 47.6 % | 24.0 % | 13.7 | **SIGNED** |
| cls A (mode 2, cur+) | 843 | 72 | **86.7 %** | 44.5 % | 26.3 % | 11.2 | **SIGNED** |
| cls 1 + ESC (delay-DRAM) | 276 | **3** | 38.4 % | 0 % | 0 % | 61.3 | SUB-OP `{20,30,60}` |
| cls 0 (mode 0) | 109 | 9 | 91.7 % | **91.7 %** | 1.8 % | 6.8 | INERT (or absolute payload) |
| C-format | 68 | 14 | 61.8 % | 4.4 % | 48.5 % | 50.3 | IMMEDIATE data |
| cls 6 (mode 6) | 53 | **5** | 67.9 % | 0 % | 0 % | 30.0 | **SELECTOR** (§3.2) |
| cls 4 (mode 4) | 53 | **1** | 100 % | 0 % | 0 % | 1.0 | **CONSTANT `0x01`** |
| cls 8 (mode 0, cur) | 44 | 3 | 100 % | 0 % | 0 % | 21.6 | **CONSTANT `0x16`** |
| cls 1 + END (unit tag) | 40 | 2 | 100 % | 0 % | 0 % | 14.1 | UNIT TAG `{0E,0F}` |
| cls 1 plain (register file) | 8 | 6 | 12.5 % | 0 % | **87.5 %** | 102.8 | **ABSOLUTE** |
| cls 9 (mode 1, cur) | 4 | 4 | 75 % | 0 % | 25 % | 20.5 | ABSOLUTE (`D0 05 0E 0F`) |

★ **The boundary is exactly `mode == 2`, and nothing else in the corpus behaves
like a displacement.** That is the ISA note's MEASURED rule (`instruction-set.md`
"Addressing": signed post-increment *"active only for `class4 & 7 == 2`"*)
re-derived from the value distributions alone, with no assumption — the two
mode-2 buckets are the *only* two that straddle `0x80` at all (24 % / 26 %) while
still concentrating at small `|s8|`. The class-1 register file straddles it the
*other* way (87.5 % ≥ 0x80) because bit 7 is the **unit selector**, not a sign,
which is R2/K4's result and shows up here as an opposite-signed anomaly.

**Two constants nobody has written down as such:**

```
   class 4 : addr8 == 0x01 in 53 of 53   -- and class 4 is ONE distinct word,
                                            `012.4.01.1CE`, in the whole ISA
   class 8 : addr8 == 0x16 in  42 of 42  BODY words, across THREE lo12 values
             (`804.8.16.415` x35, `804.8.16.1DA` x4, `80A.8.16.000` x3).
             The only two exceptions in the corpus are `800.8.0C.000`
             (KERNEL w47) and `82E.8.0F.000` (EPILOGUE w15).
```

`instruction-set.md` names `804.8.16.415` and its 35 sites; the **invariance of
`addr8` across the class-8 sub-forms, and the kernel/body split of the two
exceptions, is new.** It sharpens the standing warning that *"65 of the kernel's
75 families never occur in the body corpus"* into an exceptionless statement for
one class. **MEASURED.**

---

## 8. ★★ THE PER-BODY NET POINTER DISPLACEMENT IS ALMOST A CONSTANT — **MEASURED**

`python3 dsp/tools/pat_fields.py closure`. Sum of signed `addr8` over the
mode-2 words of each of the 38 distinct body images:

```
   net   images
   -133   1   ROOM REVERB 1                       (the only unit-1 image)
    -16   1   ROCK ROTARY
     -9   4   CHORUS, MODULATED CHORUS, S.DELAY+CHORUS, PEQ+CHORUS
     -7   5   ENHANCER, VIBRATO, MIX UP, S.DELAY+VIBRATO, PEQ+VIBRATO
     -5  23   everything else
     -4   1   GATED REVERB
     +5   1   PHASER
     +6   1   FLANGER
   +112   1   PARAMETRIC EQ
```

**NULL** (resample each body's mode-2 `addr8` values from the pooled corpus
marginal, keeping *n*, B = 2000):

```
   modal mass     observed 23 / 38     null 1.62 +- 0.51 (max 4)   z = +41.7
   top-3 mass     observed 32 / 38     null 3.87 +- 0.86 (max 7)   z = +32.7
```

★ **ALREADY KNOWN — the SET.** `closure-pointer.md` §5 records
`net(body0) + 2 ∈ {7, 8, 114, 242, 249, 251, 253, 254}` — the identical eight
values — and §9 item 2 says *"the unit-0 pool varies over 8 nets and 37
images"*. **What is new is the DISTRIBUTION**: the note treats the eight values
as a pool; **23 of 38 images share one value**, and `{−5, −7, −9}` covers 32 of
38, at z = +33 against a marginal-preserving null.

★ **And the three modal values are FAMILY-ALIGNED.** `−9` is exactly the four
chorus-derived images and nothing else; `−7` is VIBRATO, MIX UP and both
VIBRATO combis (plus ENHANCER). No image outside those families takes either
value. The reading is SP4 in §11.

⚠ Honest limit, stated: `FLANGER` (+6) and `PHASER` (+5) do **not** pass their
net to their own combis (`S.DELAY+FLANGER`, `S.DELAY+PHASER`, `PEQ+FLANGER` are
all −5), so "the combi inherits its second component's net" is **false as a
general rule** and is not claimed.

---

## 9. FIELD/VALUE × EFFECT FAMILY — **MEASURED**

`python3 dsp/tools/pat_fields.py family|traits`. Two groupings, because the
`programs.tsv` `family` column puts **14 of 38 images in one bucket (`combi`)**
and that bucket swamps any purity test.

**(a) tsv families, null = purity of a size-matched RANDOM image set** (B = 300).
Exactly **one** row clears its own p99:

```
   addr8 == 0xEE   9 images, 9 occurrences, purity 1.00 (combi)
                   null 0.39, p99 0.67
```

and all nine sites are near the very end of the body:

```
   S.DELAY+{CHORUS,FLANGER,VIBRATO,PHASER}, PEQ+{CHORUS,FLANGER,VIBRATO},
   PEQ+OVERDR+DELAY   ->  202.A.EE.415   (1..3 words before the terminator)
   PEQ+COMPR+DIST     ->  212.2.EE.000
```

`0xEE` is `−18`. It occurs **nowhere else in the 3057-word corpus** and is not
mentioned in any note. **MEASURED.**

**(b) traits read off the effect NAME** (never the words), null = the exact
hypergeometric probability that a *k*-image set falls entirely inside the trait:

| trait | field | value | images | occ | P(null) | note |
|---|---|---|--:|--:|--:|---|
| MOD | `hi12` | `094` | 16 | 29 | 7.6e-10 | **known** — the LFO wrap word |
| MOD | `addr8` | `18` | 16 | 29 | 7.6e-10 | §3.2 |
| DYN | `cfmt_lo12` | `451` | 4 | 8 | 1.4e-5 | ★ the COMPRESSOR block |
| DYN | `hi12` | `9A` | 4 | 8 | 1.4e-5 | ★ (see below) |
| DYN | `hi12` | `A2` | 4 | 8 | 1.4e-5 | ★ |
| DYN | `lo12` | `219` | 4 | 8 | 1.4e-5 | ★ |
| DYN | `addr8` | `E0` | 4 | 8 | 1.4e-5 | ★ |
| DRIVE | `(f31,ACT)` | `(5,7)` | 4 | 7 | 9.5e-4 | `02A.2.**.407` |
| DELAY | `hi12` | `604` | 4 | 4 | 4.5e-3 | a terminator variant |
| EQ | `(f31,ACT)` | `(5,11)` | 3 | 3 | 1.4e-2 | |
| MOD | `(class4,SRC)` | `(6,16)` | 5 | 7 | 1.2e-2 | the class-6 `407` sub-family |

★ **The COMPRESSOR's detector is a rigid 5-word block, 8 instances, 4 images:**

```
   0A2.2.00.000 | <one varying word> | 000.A.00.219 | 09A.A.00.200 | C40.1.E0.451
```

twice per image (stereo) in COMPRESSOR, PEQ+COMPRESSOR, PEQ+COMPR+DIST,
PEQ+COMPR+OVERDR — **8 of 8, exceptionless, no other image carries any member**.

★ **And its fourth slot is the machine's cheapest live probe.** `09A.A.00.200` is
the word §140-S5 nominates as *"the cheapest `f31 = 5` observable in the
machine"* because it is the only plain `f31 ∈ {4,5}` word that executes at cold
boot (kernel `w30`). **This pass gives it a semantic neighbourhood the kernel
alone could never supply**: the *same word* is slot 4 of the compressor's
envelope block. (The other worker's `F31_HIGH_findings.md` §B reaches
`09A.A.00.200` = *"the COMPRESSOR's envelope step"* from the coefficient side;
this is the same conclusion from the *block-structure* side, independently, and
the two should be cross-cited. Nothing here is a claim about `f31`'s
semantics — that is their territory and is not duplicated.)

---

## 10. EXCEPTIONLESS FIELD IMPLICATIONS — **MEASURED**

`python3 dsp/tools/pat_fields.py cooc`. Rules `A == a ⇒ B == b` with support
≥ 15 and **zero** exceptions over the 2989 plain (non-C-format) words.
**NULL: each field column independently resampled from its own marginal**,
B = 60 → **12.1 ± 2.4 rules (max 16)**; **observed 101**.

⚠ Roughly half of the 101 are structurally forced and are **not results**:
`class4 == 2 ⇒ mode == 2` is the definition of `mode`, and `mode == 2 ⇒
b11 == 0` is R2's exceptionless space-selector result (324/324, already in
`instruction-set.md`). The rules worth looking at:

| n | rule | status |
|--:|---|---|
| 106 | `SRC == 0x0B ⇒ f31 == 0` **and** `⇒ b4 == 0` **and** `⇒ b10 == 0` | ★ the delay-RAM read register **never** stores and never carries an operation. The 106 population is the same one `dark-words.md` §6 calls *"0-of-106 clean"* for the `0x0B`/`0x07` separation; the `f31`/`b4` half is new |
| 87 | `SRC == 0x13 ⇒ b4 == 0, b7 == 0, b10 == 0, b11 == 0` | ★ the **table read port** never stores, never escapes. Directly relevant to §3.1/§3.2 |
| 54 | `mode == 4 ⇒ b4 == 1` | ★★ **every mode-4 word carries the accumulator STORE bit.** Mode 4 is 54 words: `012.4.01.1CE` ×53 and the epilogue's `E30.C.00.404` ×1 |
| 53 | `mode == 6 ⇒ f98 == 0, f31 == 0, b7 == 0, class4 == 6` | class 6 has no microword variation at all |
| 85 | `ACT == 0x12 ⇒ mode == 2` | |
| 76 | `SRC == 0x1A ⇒ mode == 2` | tempB is only ever read in mode 2 |
| 54 | `ACT == 0x03 ⇒ b4 == 0, b10 == 0, b11 == 0` | the `C63` word's action |

---

## 11. ★ SPECULATIVE — patterns with a proposed meaning and NO test yet

**None of this is evidence.** Each carries what would confirm or kill it.
Numbering continues from `SPECULATIVE-APPLIED-REGISTER.md` §140's S1–S5, which
this section does not repeat or contradict.

**SP1 — `182.2.**.407` IS THE WRITER OF THE CELL §168 FOUND FROZEN.**
§168's diagnosis is *"`C63` reads cell `0x0C`. The phase is in cell `0x07`. It
is reading the wrong cell."* The corpus names the only word that can be putting
anything **into** `0x0C`: the `−1` word, `182.2.**.407` — `SRC 0x10` (the
accumulator, an ANCHORED code) with `ACT 0x07` (*write the operand to the
mode's destination*, `mem[ptr]` in mode 2) — at 21 of 46 sites, **including
CHORUS `w29`, the vehicle's own site**, and with `addr8 = 0x00` so it and the
`C63` word address **the same cell**.

⇒ Two readings, and they are **opposite diagnoses of §168**:
* **(a)** `C63` reads the *right* cell and the deposit is correct, but the
  accumulator arriving at `w29` is 0 — which §169 explains completely
  (`ACT 0x15` at `w28` never issues the product, so `acc` never gets one).
  Then there is **no addressing defect at all** and `0x0C` is exactly where the
  index belongs; §164's "cell `0x0C` never changes" is a *symptom of `ACT 0x15`*,
  not an independent defect.
* **(b)** §168's addressing reading is right and the deposit is landing
  somewhere else.

★ **(a) is the cheaper and more parsimonious of the two and nobody has stated
it**, because §168 was written before §169 found the dead multiply. It predicts
that fixing `ACT 0x15` alone makes cell `0x0C` start moving with no addressing
change whatsoever. *Kill it by:* EXP-1 P2 below — if `mem[m_dp]` after `w29`
does not equal the accumulator before it, the store is not landing and (b) wins.
⚠ **Not** a proposal to re-arm bit 18: §168 tested it (9 279 912 firings, `m_tb`
unchanged) and it stays off. **SPECULATIVE (strong).**

**SP2 — class-6 `addr8` names a *table*, and the corpus names two of them.**
`0x18` ⇔ the LFO waveform table, `0x28` ⇔ the waveshaper transfer curve
(§3.2, 29 = 29 per image, zero overlap). The *selector* reading is the ISA
note's; what is speculative is the assignment of `0x28` to the waveshaper curve
and the prediction that the host uploads a **second** D-RAM table (the LEDGER
records only the LFO one, `host-side.md` A3, six ROM variants at base `0x1D`).
*Kill it by:* finding no tag-`0x15` host upload other than the wavetable in a
DISTORTION/FUZZ/OVERDRIVE/EXCITER parameter stream. **SPECULATIVE.**

**SP3 — `0x18` and `0x28` are two BASES in one table space, not two selectors.**
`0x28 − 0x18 = 0x10 = 16`, and LEDGER dead end #3 records that *"the `0x28`
sites are fed by scale `0x000010` = 16"*. Under this reading `addr8` is the
table's **base cell** in the tag-`0x15` space and the scale coefficient is the
stride/offset that reaches it. This is compatible with dead end #3 (which killed
*extent*, not *base*) and with SP2. *Kill it by:* a third class-6 `4CD` value
appearing that is not `0x18 + 16k`. **SPECULATIVE.**

**SP4 — the per-body net displacement is a per-effect STATE-BLOCK SIZE, and
`−5` is `−ENTRY`.** `output-stage-decode.md` A **FORCES** the unit-0 body entry
pointer to `0x05`. A body whose net is `−5` therefore hands the pointer back at
absolute D-RAM `0x00`. **23 of 38 do exactly that**, and `{−5, −7, −9}` = exit
at `{0x00, 0xFE, 0xFC}`. The reading: the standard body convention is *"leave
the pointer at cell 0"*, and the chorus/vibrato families need 2 and 4 extra
cells below it. *Kill it by:* an image whose net is `−5` but whose lowest host
zero-fill cell is not `0x05`. ⚠ This is an **anchor-value** proposal, and
LEDGER standing rule 9 says *"when the fix you reach for is an ANCHOR VALUE,
stop"* — it is offered as a **description**, never as a fix. **SPECULATIVE.**

**SP5 — `addr8 = 0xEE` marks the COMBI RETURN GLUE.** Nine sites (§9a), all
combi, all 1–3 words before the terminator, `202.A.EE.415` ×8. `−18` is the same
displacement in every one, across combis of five different lengths, so it is
**not** a program-specific offset — it is a fixed step back to a shared cell.
Reading: the combi's two sub-blocks each own a state region, and the tail must
step back from the second block's region to the unit's output cell.
*Kill it by:* a non-combi image with `addr8 = 0xEE`, or a combi whose `0xEE`
word is not in its last quarter. **SPECULATIVE.**

**SP6 — the PHASER is a 10-stage cascade, and the two runs are the two
channels.** §6: nine 3-word stages twice, operands walking `+69…+77` /
`+70…+78`. `algorithms/families.md` records the stage count as *not decoded*.
The 10th stage differs (`212.A.B0.412` is class **A**, not class 2 — it fetches
a coefficient the other nine do not), so "10 stages, the last one gain-scaled"
is the reading and "9 stages plus an output scaler" is the alternative; the
corpus does not separate them. *Kill it by:* the host's C-RAM map for algo 5
having a number of all-pass coefficients that is neither 9 nor 10.
**SPECULATIVE (strong on the count, open on the 10th).**

**SP7 — DISTORTION and FUZZ differ ONLY in reach, so the "curve" difference is
a lie in `programs.tsv`.** §5. Both run the same 42 words; the only difference
is `±7/±16` vs `±122/±125` in four `addr8` fields. If `addr8` selects *where*
the waveshaper's table/state lives, the two effects use **different tables at
different D-RAM distances** and the ROM's own role strings ("curve A" /
"rail-clip") describe the *data*, not the *program*. *Kill it by:* the two
algorithms' host streams uploading identical table data. **SPECULATIVE.**

**SP8 — the combi head is a REDUCED base, not a truncated one.** §4 shows the
first declared component covers only 0.076–0.125 of its own program while the
second covers 0.39–0.63. If the library were "cut the base program short", the
head's coverage would be high with a low LCR; it is low with an *equally* low
LCR (2–9 words). So the head is a **separately authored 1-band / 1-tap block**,
not a prefix of the 5-band / full-delay program. *Kill it by:* an alignment in
which some contiguous ≥ 20-word run of PARAMETRIC EQ appears in a PEQ+ combi
(the observed maximum is 9). **SPECULATIVE (strong).**

**SP9 — `A00.0.00.041` is the swept-tap's ADDRESS WORD.** It occurs 35 times,
is **DARK** (`dark-words.md` §4.4, class 0, `SRC 0x01 / ACT 0x01`, and its SRC
code occurs essentially nowhere else), and it is a *deterministic* predecessor
of the delay-DRAM read `880.1.**.2C7` on **35 of 35** occurrences (§1). Its own
predecessor is `C40.3.20.44C` on **29 of 35** sites (`104.2.00.1D5` on the other
6) — the machine's **only** `C40.3.**.44C` form, `imm13 = 800` — and
`dark-words.md` §4.2 already notes that **800 samples is the ROOM REVERB
pre-delay R3 derived independently** from the descriptor cells. Reading:
`C40.3.20.44C` loads a delay offset and `A00.0.00.041` applies it to the
descriptor address, which is the `G` in R3's `DESCRIPTOR_CELL[cursor] + G`.
*Kill it by:* `imm13 = 800` failing to correspond to anything in the CHORUS
delay range in the host stream. ⚠ Note this is one immediate at 29 sites in 10
different effects, which is itself odd for a per-effect delay offset — the
alternative that it is a fixed *table* length or mask is not excluded.
**SPECULATIVE.**

**SP10 — the body prologue/epilogue is a fixed frame, and it is I/O.**
`pat_fields.py pos`: word 0 is a delay-DRAM word in **28 of 38** bodies (27 of
them with `addr8 = 0x30`, R3's "first DRAM access" marker); word −2 is a
delay-DRAM word in **30 of 38** (25 of them exactly `880.1.60.000`, the line
WRITE); word −1 is the class-1+END terminator in **38 of 38**. Reading: the
body macro is `[read the line] … [write the line] [return]`, i.e. the delay line
is the body's *calling convention*, not an optional resource. This is a
structural restatement of `dark-words.md` item D(a) — *"the external delay line
is never read and never written"* — from the other side: **the delay line is the
first and last thing a body touches**, so a core that traps those two words has
lost the body's input and output, not merely an effect. **SPECULATIVE** as a
reading; the three counts are **MEASURED**.

**SP11 — `f31` is a modifier on a fixed `lo12` route, and `lo12 = 0x200` is the
cleanest three-arm example in the machine.** `092/094/09A .A.**.200` are 29/29/9
occurrences of one route under `f31 = 1 / 2 / 5`. §9 places the `09A` arm inside
a rigid 5-word compressor block. ⚠ **This overlaps another worker's live pass**
(`F31_HIGH_findings.md` §B reaches the same three-arm family from the
coefficient side and grades the semantics OPEN); it is recorded here only for
the **block context**, and nothing about `f31`'s meaning is claimed.
**SPECULATIVE — deferred to that note.**

**SP12 — an unrolled stage's pointer displacement encodes its STATE SHAPE.**
§6: all-pass stages net 0 (state addressed as offsets from a fixed base),
biquad sections net +4 (four state words consumed per section, walking),
voice/tap blocks net +1 with an end-of-run rewind (one cell per voice). If that
holds generally, **the net displacement of a repeated block is a direct readout
of how many D-RAM cells the block privately owns** — a static measurement that
would let every body's state footprint be computed without executing anything.
*Kill it by:* a block whose net displacement disagrees with the host's zero-fill
size for that algorithm. **SPECULATIVE (strong; the biquad's +4 already agrees
with the host's 40-cell fill).**

---

## 12. EXPERIMENTS ANOTHER WORKER COULD RUN

Ranked by what they unblock. EXP-1 is on the **current TIER-0a blocker**.

### EXP-1 — SP1 / §3.1: does §168's "addressing defect" survive §169?

**Why.** The handoff's NEXT TASK is *decode `ACT 0x15`*. §3.1 says that word sits
at **−2 from every one of the 46 non-chained lookups**, so the decode is worth 46
sites, not one — and it says the word at **−1** is the writer of the very cell
§168 found frozen. §168 and §169 were written in that order and **nobody has put
them side by side**: if `ACT 0x15` is the reason `acc` is 0, then cell `0x0C` is
frozen *because of that*, and there is no separate addressing defect to chase.
Standing rule 10 — a blocker is a measurement — applies to §168 exactly as it
applied to §163.

**Setup.** Instrumentation only, **no gate change, no source semantics changed**.
Vehicle: use the handoff's own recommendation (§169 §4) — FLANGER / AUTO PAN /
VIBRATO / RING MODULATOR, gap 6 — **not** cold-boot CHORUS at gap 24. CHORUS's
own chain, for reference, is body `w28..w31` = I-RAM 112..115:
`202.A.07.1D5 (ACT 0x15) | 182.2.00.407 | 040.0.00.C63 | 000.6.18.4CD`.

**Pre-register, in this order, each with a two-sided outcome:**
1. At the **−2** word log `acc`, `mem[m_dp]`, `m_p`, `m_dp`.
   **P1: `acc` and/or `mem[m_dp]` at −2 VARIES.** Arm 2 (both constant) says the
   gap is upstream of the whole macro and `ACT 0x15` would have nothing to
   multiply even if decoded — which is a *bigger* result than a hit and must be
   reported as one.
2. At the **−1** word (`182.2.**.407`) log `acc` in, `m_dp`, and `mem[m_dp]` out.
   **P2: `mem[m_dp]` after equals `acc` before, and `m_dp` here == `m_dp` at the
   `C63` word** (both carry `addr8 = 0x00`, so it must). **Arm 2 ⇒ §168's
   addressing reading (b) wins and the store is landing elsewhere.**
3. **P3, the cheap decisive one:** count how many of the 46 `ACT 0x15` sites the
   cold-boot frame actually executes, and confirm every one of them is at −2 from
   a `C63`. Static + one trace; it converts §169's one-word finding into a
   site list for the `ACT 0x15` decode.
4. **Control that can fail:** the same instrumentation on `PARAMETRIC EQ`, which
   carries **zero** class-6 words but **does** carry `ACT 0x15`. It must show the
   `ACT 0x15` probes firing and the lookup probes never firing. A probe set that
   fires everywhere is not measuring the idiom.

⛔ **Do not** re-arm bit 18 (§168: 9 279 912 firings, `m_tb` unchanged) and do
not implement the class-6 lookup before P1 returns arm 1 (standing rule 4, and
LEDGER dead end #4).

**Cost.** One instrumented run. **Falsifiable at step 1, both ways.**

### EXP-1b — the `ACT 0x15` minimal-pair family, static

§3.1's 46 `ACT 0x15` words at −2 split **29 `SRC 0x07` / 17 `SRC 0x10`** — same
ACTION, same class, same consumer, different operand. **P1: the two flavours
correlate with something downstream** — e.g. whether the `−1` word is the
`ACT 0x07` store (21) or the `ACT 0x00` form (25). Cross-tabulate them; a clean
2×2 says the two SRC arms are two *different* index constructions and `ACT 0x15`
is the same operation in both. A scrambled table says the `−1` split is
independent and the ACTION is doing all the work. Either answer constrains the
`ACT 0x15` decode, and it costs one pass over data already extracted.

### EXP-2 — SP4/§8: is the modal net `−5` really `−ENTRY`?

**Setup.** Purely static, one pass over the host parameter streams already
extracted. For each of the 38 images compute (a) the net from
`pat_fields.py closure` and (b) `min(host zero-fill cell)` for that algorithm.

**Pre-register.** **P1: `net + min_fill == 0` for the 23 images with net −5.**
**P2: the 5 images with net −7 have `min_fill == 0x07`** and the 4 with −9 have
`0x09`. **Falsifier:** `min_fill` is `0x05` for all 38 (which is what
`output-stage-decode.md` reports for 79/79 *streams*, so P2 is a genuine risk and
this test can fail). If P2 fails, SP4's "extra cells" reading dies and the
`−7`/`−9` values need a different explanation.

### EXP-3 — SP2/SP6: two table uploads, and the phaser's coefficient count

**Setup.** Static, on the parameter streams. (a) For each of the 8 waveshaper
images, list every tag-`0x15` (D-RAM) upload block. **P1: a block other than the
`0x1D..0x40` wavetable exists, in all 8.** (b) For algo 5 (PHASER), count the
C-RAM coefficients the host writes for the all-pass chain. **P2: it is 9 or 10,
matching §6's stage count; not 14 (the image's class-A total).**

### EXP-4 — SP7: are DISTORTION and FUZZ the same effect with different data?

**Setup.** Static. Diff the full host parameter streams of algos 32 and 34.
**P1: the I-RAM images differ in exactly the four `addr8` bytes §5 lists.**
(Already MEASURED — this is the known-answer half.) **P2: the C-RAM / D-RAM
payloads differ.** If they do **not**, then two ROM effect slots ship byte-
identical programs *and* byte-identical data, and the KN5000's "FUZZ" and
"DISTORTION" are the same sound — which Felipe can falsify **by ear on the real
instrument in under a minute**, and which would be the cheapest hardware test in
the project. ★ This is the one item on the list worth putting to him directly.

### EXP-5 — SP5: what is at `ptr − 18`?

**Setup.** Instrument the nine `addr8 = 0xEE` sites in one combi
(`PEQ+CHORUS w89`, `202.A.EE.415`). Log `m_dp` before and the cell read.
**P1: the cell is the same one the body's own terminator/output word reads.**
**P2: `m_dp − 18` is inside the host's zero-fill block for that algorithm.**
Falsifier for both: the cell is outside the fill, i.e. `0xEE` reaches state the
host never clears, which would make it an inter-block hand-off instead.

---

## 13. WHAT IS ALREADY KNOWN vs WHAT IS NEW — the honest ledger

**Already recorded; this pass reproduces it (and that is the control):**

* the all-pass motif, the LFO block, the table-lookup core, the biquad section,
  the reverb's 5+4 ladders, the stride-9 repeat, `804.8.16.415`, class-6
  `addr8` = a selector, mode-2 `addr8` = a signed post-increment, class-1 plain
  `addr8` bit 7 = the unit, `mode == 2 ⇒ no escape` (324/324), the LFO's 29
  blocks in 16 programs, the 26-of-29 `447` tail, the eight per-body net
  displacements (`closure-pointer.md` §5), `09A.A.00.200` = the compressor's
  envelope step (`F31_HIGH_findings.md` §B, `lfo-ramp.md`), the effects being
  "compiled from a common library" (`algorithms/families.md`).

**New here:**

1. the **79.8 % maximal-repeat coverage** against a 0.2 % null, and the
   **30.6 % deterministic-successor** rate against 0.0 % — the first numbers on
   the "macro library" claim;
2. ★ the table-lookup idiom's **two upstream words**: a class-A **`ACT 0x15`**
   word at exactly −2 on **46 of 46** non-chained sites (the other 7 are chained
   lookups, so 53/53 is accounted for), and a `182.2` head at −1 on 46 of 46.
   §166 owns the `C63` ↔ class-6 half; this extends it upstream and turns §169's
   one-word `ACT 0x15` finding into a **46-site, 25-image** result with a
   **29 / 17 SRC minimal-pair family** for decoding it;
3. the **class-6 selector's per-image 1:1 accounting** (`0x18` ⇔ LFO 29 = 29,
   `0x28` ⇔ waveshaper, zero overlap) and the `lo12 = 0x407` chorus-only
   sub-family;
4. the **CHORUS voice macro at 7 words / 29 instances / 10 images**;
5. **DISTORTION ≡ FUZZ** up to four `addr8` bytes;
6. the **PHASER's 9(+1) 3-word stages**, their net-zero displacement and the
   `+69+k / −(70+k)` shift-register walk — where `families.md` says the stage
   count is undecoded;
7. **per-stage displacement as a state-shape readout** (all-pass 0, biquad +4,
   voice/tap +1), with the biquad's +4 matching the host's 40-cell fill;
8. the **combis are not concatenations** (declared-base cov 0.345 vs
   best-non-component 0.646) **but the name order is the microcode order**
   (10 of 11, P = 9.8e-4);
9. **class 4 = one word, `addr8 = 0x01`, 53/53, and `mode 4 ⇒ store bit set`**;
   **class 8 `addr8 = 0x16` in 42/42 body words**, both exceptions in the kernel;
10. the **net-displacement distribution** (23/38 at −5, z = +41.7) and its
    **family alignment** — where the note that owns it records only the set;
11. `addr8 = 0xEE` as a **combi-exclusive** value, 9 sites, absent from every
    note;
12. the **COMPRESSOR's rigid 5-word detector block**, 8/8, and its identity with
    kernel `w30`;
13. `SRC 0x0B ⇒ f31 = 0, b4 = 0, b10 = 0` and `SRC 0x13 ⇒ b4 = b7 = b10 = b11 =
    0` — 106 and 87 words, exceptionless, against a 12.1 ± 2.4 null.

**Explicitly NOT claimed:** anything about the semantics of `f31 = 4/5` (another
worker's live pass); any revival of LEDGER dead ends #1–#10; any re-arming of
mask bit 18 (§168 tested it and it stays off); the `C63` ↔ class-6 bijection
(§166's, not this pass's); or any implementation of the class-6 lookup before
its inputs are measured to vary (standing rule 4, dead end #4).

---

## 14. Files

* `dsp/tools/pat_corpus.py` — corpus loader + the 36-bit field decode.
* `dsp/tools/pat_ngram.py` — n-grams, maximal repeats, nulls, controls,
  deterministic successors.
* `dsp/tools/pat_struct.py` — combi containment, concatenation test, pairwise
  LCR, twins, periodicity.
* `dsp/tools/pat_fields.py` — `addr8` × `class4`, pointer closure, family and
  trait purity, exceptionless implications, positional structure.
* this note.
