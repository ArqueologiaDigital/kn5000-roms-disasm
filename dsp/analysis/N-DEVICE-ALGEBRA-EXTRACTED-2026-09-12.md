# The device's accumulator algebra, extracted mechanically (2026-09-12)

**Tool:** `dsp/tools/class2_solve.py` — **Artefacts:** `dsp/analysis/data/class2_algebra_2026-09-12.txt`,
`dsp/analysis/data/allclass_algebra_2026-09-12.txt` (104 captures, 52 device configurations).

## 1. What this is, and what it is NOT
For every executed trace row the tool tests a fixed algebra of candidate accumulator transitions
against the measured `acc[N]`, groups the rows by `(class4, ACT, SRC, f31)`, and keeps the
candidates that survive **every** row of a group.

⛔ **The `acc` column is the DEVICE's accumulator.** A group that comes out unique states what
`upd6383.cpp` does, **not what the chip does**. This is a *specification extractor*, not a decode.
It is worth having for three reasons, and only those three:

1. it states the device's model in **one 40-row table** instead of several thousand lines of C++,
   so a reading that drifted from the code shows up as a mismatch rather than surviving in prose;
2. the **VACUOUS** rows name the `(class, ACT, SRC, f31)` combinations that *no capture in the
   whole corpus distinguishes* — those are what a new experiment has to target, and they are
   invisible from the source;
3. the **⛔** rows say the device's behaviour is not in the algebra at all — which is how the
   combined form in §3 was found.

A statement about the **chip** still needs the oracle: run the program through the HLE and compare
what it *computes*, not what the device computed.

## 2. The f31 field, confirmed uniformly and across classes (device)
Every discriminating group agrees, in classes 0, 1, 2, 3, 4, 6, 8 and A alike:

| `f31` | accumulator |
|---|---|
| 0 | `acc ← P[N−1]` (LOAD) |
| 1 | `acc ← acc[N−1] + P[N−1]` (ACCUMULATE) |
| 2 | hold |
| 4 | behaves as 0 (LOAD) — bit 2 does not change the accumulator op |

The largest single group is `clsA ACT15 SRC07 f31=1 → acc+P`: **623 rows, 53 programs, 25 device
configurations, 623 discriminating**. That is the biquad's `mac`.

## 3. ★ `ACT 0x00` ADDS THE BUS TERM ON TOP OF THE f31 OP
Three groups, all unique and all heavily discriminating:

| group | op | rows | programs |
|---|---|---|---|
| `cls2 ACT00 SRC07 f31=1` | `acc + P + (L << 16)` | 148 | 24 |
| `cls2 ACT00 SRC00 f31=1` | `acc + P + (L << 16)` | 136 | 48 |
| `cls2 ACT00 SRC00 f31=0` | `P + (L << 16)` | 54 | 29 |
| `cls2 ACT00 SRC00 f31=4` | `P + (L << 16)` | 24 | 24 |
| `clsA ACT00 SRC00 f31=1` | `acc + P + (L << 16)` | 80 | 20 |

So `ACT 0x00` is **orthogonal to `f31`**: `f31` picks LOAD or ACCUMULATE of the product, and
`ACT 0x00` adds the bus datum at datum scale on top. This matches what `upd6383.cpp` already says
in prose at the row-26 site ("ACTION 0x00 ADDS the bus rather than replacing the accumulator") —
the value here is that it is now stated as one arithmetic form, checked on 442 rows.

⚠ Where a note or a commit message writes the device's *"bus-add"* form as `acc += L<<16`, that
shorthand drops the product term. `dlyseed_confront.py`'s own test has always included it
(`acc[N] == acc[N−1] + P[N−1] + (L[N] << 16)`, `:187`); the prose is what is loose.
`N-DLYSEED2-SINGLE-DELAY-CONFRONT-2026-09-12.md` carried the loose form and is corrected in place.

## 4. ★ `ACT 0x0D` REPLACES the accumulator with the bus, `f31` notwithstanding
| group | op | rows | programs |
|---|---|---|---|
| `cls2 ACT0D SRC07 f31=0` | `L << 16` | 63 | 53 |
| `cls2 ACT0D SRC07 f31=1` | `L << 16` | 29 | 29 |

**`f31 = 1` gives `L<<16`, not `acc + L<<16`** (29 discriminating rows), so this code overrides the
accumulate.

⚠ This does **not** contradict the committed speculative gloss *"ACT 0x0D = delay/state MIXING:
mem onto bus"* — that gloss describes what drives the **bus**, and this describes what the
**accumulator** receives. They are the two halves of the same word, and the measured half is the
one that was missing: whatever `ACT 0x0D` puts on the bus, the accumulator **takes it and drops
its own contents**, `f31` notwithstanding. The same distinction applies to `ACT 0x0E` (*"acc onto
bus"*): on the accumulator side it is a plain `f31` LOAD (`P`, 53 rows, 53 programs), which is
consistent with the accumulator being that word's **source** rather than its destination.

## 5. Two corrections the tool forced on ITSELF
Both are recorded because they are the kind of error that would otherwise have shipped as a result.

- ⛔ **The ±2³⁹ clamp was wrong.** The first version clamped every candidate to `±2^39` on the
  strength of §227's saturation magnitude, and reported **208 rows "no candidate explains"**. They
  were not unexplained: the traces carry accumulator values past `2.1e12` (≈ 2⁴¹) — the EQ's
  `mac.st tb` at `iw94`, `acc −1 644 307 152 896 + P 544 882 360 320 = −1 099 424 792 576`, exact —
  and the clamp destroyed the match. Whatever ±2³⁹ governs, **it is not a ceiling on the
  accumulator values the trace reports.** The clamp is now off by default (`--sat N` restores it).
- ⛔ **Pooling captures pools MACHINES.** `cls8 ACT15 SRC10 f31=2` came out "no candidate explains"
  over 240 rows. The cause: **134 of them are from captures with `UPD6383_C8SHIFT` unset**, where
  the word holds the accumulator, and **106 from captures with `C8SHIFT=1`**, where it is
  `acc >> 1`, exact. Both behaviours are real; they are not the same machine. The tool now reads
  the device's own arm-report lines back out of each log and prints how many configurations each
  group spans — this corpus has **52**.

## 6. What the VACUOUS rows are asking for
These are the combinations the whole 104-capture corpus cannot separate. They are the shortest
list of experiments worth designing, and none of them needs a new idea — only data where the
relevant register is non-zero:

| group | tied candidates | what would separate them |
|---|---|---|
| `cls2 ACT0E SRC07 f31=2` | `hold`, `acc ± tA<<16` | a frame where **tempA ≠ 0** at those rows |
| `cls3 ACT0C SRC11 f31=0` | same tie | same |
| `cls0 ACT03 SRC11 f31=0` | same tie | same |
| `cls6 ACT0D SRC13 f31=0` | same tie | same |
| `cls2 ACT0E SRC10 f31=0` | `P`, `acc+P−L<<16` | a row where `acc ≠ L<<16` |
| `cls2 ACT07 SRC11 f31=0` | `P`, `acc+P−L<<16` | same |
| `clsA ACT08 SRC13 f31=1` | `acc*2`, `acc+P`, … | a row where **`P ≠ acc`** |
| `cls2 ACT15 SRC19 f31=1` | `acc*2`, `acc+P` | same |
| `cls2 ACT00 SRC00 f31=5` | `acc+P+L<<16`, `acc+P+mem<<16` | a row where `L ≠ mem` |

★ Four separate groups are tied **only because tempA is zero in every capture**. One capture with a
non-zero tempA at those words settles four rows of this table at once — that is the single highest
-value experiment the tool identifies.

## 7. ★ THE TEMP-REGISTER WRITER MAP (`--target ta|tb`)
Same machinery, different left-hand side: which `(class, ACT, SRC, f31)` groups **write** tempA or
tempB, and with what. Everything not listed HOLDS the register — that alone is worth having, since
it says the temps are written by a short, named list rather than as a side effect of arithmetic.
Artefacts: `data/temp_ta_algebra_2026-09-12.txt`, `data/temp_tb_algebra_2026-09-12.txt`.

| group | writes tempA | rows | programs |
|---|---|---|---|
| `clsA ACT08 SRC11 f31=1` | **`L`** | 53 | 53 |
| `clsA ACT19 SRC10 f31=0` | **`L`** | 53 | 53 |
| `cls2 ACT19 SRC0B f31=0` | **`L`** | 53 | 53 |
| `cls1 ACT01 SRC07 f31=0` | **`L`** | 53 | 53 |
| `cls1 ACT19 SRC0B f31=0` | **`L`** | 18 | 9 |

⇒ every uniquely-determined tempA writer in the corpus writes **the operand latch `L`**, across
five different `(class, ACT)` combinations and 53 programs. That is the concrete form of the
project's standing reading that *"a read's datum reaches the multiplicand through tempA, one slot
later"*. tempB has no uniquely determined writer yet: `clsA ACT1A SRC08 f31=0` is tied between `L`
and `coef[-1]`, and `clsA ACT14 SRC07 f31=1` between `L` and `mem[-1]`.

### ★★ And this locates why tempA is zero in the body
MEASURED on the chorus kernel, one frame, `UPD6383_LO12CAP=1`:

```
iw37  clsA ACT00 SRC07 f31=1   acc = 443 684 591 449
iw38  cls0 ACT19 SRC00 f31=4   tA 000000 -> 674DA9      <- the gate word captures the LIVE audio
iw39  clsA ACT07 SRC19 f31=0   L = 6 770 089 = tA       <- and the next word CONSUMES it
iw45  clsA ACT0C SRC08 f31=0   tA 674DA9 -> 000000      <- and nine words later it is WIPED
```

`0x674DA9 = 6 770 089 = acc[iw37] >> 16`, exactly — so the capture is the accumulator's datum, as
`UPD6383_LO12CAP=1` implements it, and it is genuinely live audio. The body starts at `iw84` with
`tA = 0` because **`iw45` overwrote it**, and `iw45` is `ACT 0x0C`, whose tempA write the corpus
cannot pin: the survivors are `{L, coef[-1], zero}` and all three are zero on all 53 rows.

⇒ **`ACT 0x0C` is now the single highest-value open code.** It is the one that decides whether the
body sees the kernel's audio in tempA, and it is the same code that leaves four accumulator groups
tied in §6. One experiment — a capture where `L`, `coef[-1]` and `0` differ at `iw45` — resolves
both. ⚠ Note this is a statement about the DEVICE's tempA; what the chip does at `iw45` is what the
experiment has to establish.

## Honest grade
MEASURED, about the **emulator**. The tables are regenerable with one command (in the tool's
docstring) from the archived captures. Nothing here is a statement about the µPD6383GF; §1 says so
and the tool's own docstring says so before any output is printed.
