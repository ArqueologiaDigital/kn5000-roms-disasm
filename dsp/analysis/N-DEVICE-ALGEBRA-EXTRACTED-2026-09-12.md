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
  ★ **`--split-config` closes it.** Keying every group by the arms its capture was taken with
  turns that one ⛔ into eight `★ UNIQUE` rows, one per machine, and each reads exactly as its arm
  says: `hold` wherever `UPD6383_C8SHIFT` is unset, `acc >> 1` at `C8SHIFT=1`, `acc >> 2` at 2,
  `acc >> 3` at 3 — every one fully discriminating. That is the class-8 post-sum-scale decode
  recovered mechanically and per configuration
  (`data/allclass_algebra_bycfg_2026-09-12.txt`). Use `--split-config` the moment a group with
  many rows reports that no candidate explains them all.

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

✅ **UPDATE (§10): the first row is SETTLED, and it did not need a new capture — it needed a corpus
that was ONE MACHINE.** On the ten-program single-configuration sweep `cls2 ACT0E SRC07 f31=2`
comes out **`hold`, 13 rows over 5 programs, all discriminating**. The pooled corpus could not
separate it; ten programs on one machine could. Try `--split-config`, or a single-configuration
corpus, **before** designing a capture for any row of this table.

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

## 8. THE PREDICTION THAT FOLLOWS, written before the run
`iw45` fetches a coefficient (`cur+`) and multiplies by it, and the coefficient it fetches is
**zero** — so its product is zero, and `iw46`, the kernel's **external delay-DRAM WRITE** word
(`cls1 ACT0B SRC00 f31=0`, a LOAD), takes `acc ← P[iw45] = 0`. That is where the kernel's audio
dies: `iw45` arrives holding `acc = 269 380 293 754` (the live signal) and `iw46` replaces it with
zero, one word before the delay line is written.

Why is that coefficient zero? Because the cursor is sitting at `0x70`, the **delay-descriptor ramp
table**, put there by `iw42`'s `ldptr #$70` under the **§52 reading (row 25 seeds the coefficient
cursor from `ldptr`)**. The same trace shows what the cursor fetches when it is *not* seeded:
`iw36 → 0x5D70A3`, `iw37 → 0x5C28F5`, `iw39 → 0x599999`, `iw41 → 0x4CCCCC` at `cur = 0xA1..0xA4` —
genuine coefficients around 0.6–0.73 at Q23.

⇒ **Prediction.** With `UPD6383_SPEC` **bit 12 set** (the mask bit that CLEARS row 25 —
`B9108446A39B440F | 0x1000 = B9108446A39B540F`), the cursor runs on continuously into `0xA5`,
`iw45`'s product is non-zero, and `iw46` no longer erases the accumulator. `upd6383.cpp` already
argues bit 12 on independent grounds: without row 25 the run is kernel `0x90..0xA4` (21 cells) plus
body `0xA5..0xB4` (16), and **21 + 16 = 37 = exactly the host's coefficient run count**, while with
row 25 the sixteen genuine coefficients at `0xA5..0xB4` are read by nobody.

Test: `dsp/tools/pair_gate.sh spec12 UPD6383_LO12CAP=1 UPD6383_SPEC=B9108446A39B540F`, plus the
tempA trajectory at `iw45` from the same chorus capture. ⚠ Two-sided, like everything else here:
the chorus phase must still be 114 **and** the EQ must stay live. Recorded before the run so the
measurement can contradict it.

## 9. ⛔ §8 IS REFUTED — and the refutation is a NEW positive fact about §52
Ran it: `pair_gate.sh spec12 UPD6383_LO12CAP=1 UPD6383_SPEC=B9108446A39B540F` (bit 12 set, i.e.
row 25's cursor seed CLEARED), same binary and baseline arms as everything else.

| | chorus increment | EQ cells moved | EQ rows |
|---|---|---|---|
| seed ON (`…440F`) | 3 129 519 ⛔ | 39 of 44 | 105 of 105 |
| seed OFF (`…540F`) | **114** ✅ | **0** | **0** ⛔ |

So clearing the seed does **not** rescue the kernel's audio. It does the opposite, and the trace
says exactly where:

| | input cell `0x01` | input cell `0x04` | **pickup `0x05`** | `0x10` | kernel peak acc | body rows with non-zero `P` |
|---|---|---|---|---|---|---|
| seed ON | 60 672 | 122 880 | **4 899 462** | 7 792 377 | 8.05e11 | 100 of 105 |
| seed OFF | 60 672 | 122 880 | **0** | 524 288 | 1.76e11 | **9 of 105** |

The **inputs are bit-identical** and the EQ's coefficient cursor covers the **same** range
(`0x00..0x1E`, 31 distinct cells) in both — so this is not a re-aiming of coefficients. What
changes is that the **kernel stops delivering**: the pickup cell the body reads goes to zero, and
with it 91 of the body's 100 non-zero products.

★ ⇒ **Row 25 — the `ldptr` seeding of the coefficient cursor (§52) — is load-bearing for the
kernel's delivery of audio to the body.** That is a *second and independent* argument for a
reading the project has on file as "⛔ STILL AGAINST K3" and has argued against on counting grounds
(21 + 16 = 37 = the host's coefficient run count). The counting argument is unchanged; it now has a
measured argument against it, and **the measured one is about audio actually arriving**. Neither
is proof; what is settled is that row 25 cannot be removed as a tidy-up.

⚠ And §8's specific story — *"`iw45` fetches a zero coefficient off the ramp, `iw46` loads it over
live audio"* — is refuted as a *cause*. `iw46` does load a zero over the audio; removing the seed
does not fix it, it removes the audio earlier. The observation stands, the causal claim does not.

⚠ Grade: MEASURED. `data/pair_gate_spec12_2026-09-12.txt` + `data/pg_spec12_*_2026-09-12.log.gz`.

## 10. ★★ THE ALGEBRA ON **ONE MACHINE**, TEN PROGRAMS — and it closes a standing lead
The tables above pooled 104 captures across **52 device configurations**, which §5 records as a
trap: pooling captures pools machines. The catalogue-regression sweep produced the corpus that
fixes it — **one configuration** (`PSHIFT=2 C8SHIFT=1 LO12CAP=1 SPEC=…440F`), **ten programs**
spanning modulation, reverb, both delay shapes and the biquad. Artefact:
`data/algebra_one_machine_10programs_2026-09-12.txt`.

Groups that were VACUOUS in the pooled run come out **uniquely determined** here, because the ten
programs exercise registers the old corpus left at zero:

| group | op | rows | programs | note |
|---|---|---|---|---|
| **`cls2 ACT0E SRC07 f31=2`** | **`hold`** | 13 | 5 | ★★ **`f31 = 2` = accumulator HOLD, non-vacuously** |
| `cls2 ACT15 SRC07 f31=2` | `hold` | 30 | 4 | the same, on a second ACT code |
| `cls2 ACT00 SRC00 f31=2` | `acc + L<<16` | 16 | 4 | ★ at `f31 = 2` `ACT 0x00` **still adds the bus** |
| `cls1 ACT00 SRC00 f31=0` | `P + L<<16` | 11 | 8 | was tied in the pooled run |
| `cls2 ACT00 SRC1A f31=1` | `acc + P + L<<16` | 13 | 2 | new |
| `cls8 ACT15 SRC10 f31=2` | `acc >> 1` | 10 | 1 | the class-8 scale, clean on one machine |

★★ **`f31 = 2` = HOLD is now measured rather than argued.** The project's memory carried it as
*"the HLE argues `f31 = 2` = acc-HOLD on the class-2 port reads (STRONG lead, build-lane to
confirm)"*. It needed no build lane in the end — it needed a corpus that was **one machine**, and
13 fully discriminating rows over 5 programs settle it. Together with `ACT 0x00`'s bus term
surviving at `f31 = 2`, the picture is that **`f31` chooses what happens to the PRODUCT and `ACT`
chooses what happens to the BUS, independently** — which is the cleanest structural statement the
extractor has produced.

⚠ One group is still ⛔ on a single machine, and it is informative: `cls2 ACT00 SRC00 f31=0`
(39 rows, 5 programs). Reading its rows, **`P + L<<16` explains the live ones** — e.g. the EQ's
`iw136`, `−13 473 677 312 + (19 859 << 16) = −12 172 197 888`, exact — while a run of
`0000200000` words with **`addr8 = 0x00`** simply HOLD. ⇒ the group key needs `addr8`, or those
words are padding the device treats differently. That is a decode question, not a pooling
artefact, and it is the next thing this tool should be pointed at.

⚠ Grade: MEASURED on one configuration.

## 11. THE TEMP WRITERS ON ONE MACHINE — and `ACT 0x19` has TWO behaviours, cleanly separated
Same ten-program single-configuration corpus, `--target ta|tb`
(`data/temp_ta_one_machine_2026-09-12.txt`, `…_tb_…`). Everything not listed holds.

| group | writes | rows | programs | |
|---|---|---|---|---|
| `cls2 ACT19 SRC0B f31=0` | **`L`** | 10 | 10 | the ordinary capture |
| `cls1 ACT19 SRC0B f31=0` | **`L`** | 11 | 4 | the same, class 1 |
| `cls1 ACT01 SRC07 f31=0` | **`L`** | 10 | 10 | |
| `cls1 ACT14 SRC0B f31=0` | **`L`** → **tempB** | 7 | 1 | ★ the **first** uniquely determined tempB writer |
| `cls0 ACT19 SRC00 f31=4` | **`acc_datum`** | 10 | 10 | ⚠ **circular** — see below |

★ **`ACT 0x19` is not one action.** With `SRC 0x0B` it captures **the operand latch `L`**, on 10
programs; at the audio-gate word (`class 0`, `SRC 0x00`, `f31 = 4`) it captures **the accumulator's
datum**. Two distinct behaviours under one ACT code, separated by 10 programs on one machine where
the pooled corpus reported the second as ⛔ (it mixed captures with `UPD6383_LO12CAP` on and off —
§5's trap again).

⚠ **The second row is CIRCULAR and must not be quoted as a decode**: `UPD6383_LO12CAP=1` *is* the
arm that makes the gate word capture the accumulator, so recovering that is recovering the arm's
own definition. What the row does establish is narrower and still worth having: the arm is
**self-consistent across all ten programs** and does not collide with the ordinary `ACT 0x19`
capture, which keeps taking `L`. The handover's *"taking the accumulator — the open half of
`ACT 0x19`"* stays open on the chip; on the device the two halves are now distinguishable.

★ Non-circular and new: **tempB has a uniquely determined writer** (`cls1 ACT14 SRC0B f31=0 → L`),
where the pooled corpus had none — every tempB group was tied.

⚠ Grade: MEASURED on one configuration, ten programs; one row flagged circular in place.

## 12. `--by-addr8` closes the last unexplained group on a clean machine — it was the NOP
§10 left one ⛔ on the single-machine corpus: `cls2 ACT00 SRC00 f31=0`, 39 rows over 5 programs.
Adding `addr8` to the group key (`--by-addr8`) splits it into two, both uniquely determined and
both fully discriminating:

| group | op | rows | programs |
|---|---|---|---|
| `cls2 ACT00 SRC00 f31=0 **a8=00**` | **`hold`** | 22 | 3 |
| `cls2 ACT00 SRC00 f31=0 **a8=01**` | `P + (L << 16)` | 5 | 2 |

Every row of the first is the **same word**, `0000200000` — and the disassembler already renders
that word **`nop`**, at 62 sites across the corpus. So the group was never contradictory: it was
the machine's NOP sharing a key with real arithmetic, because the key ignored `addr8`.

★ Two things worth keeping from that:
1. **A small but real cross-check between the disassembler and the device**: the word the listing
   calls `nop` does in fact leave the accumulator alone, measured on 22 discriminating rows. The
   two halves of the project agree where nobody had checked that they did.
2. **`addr8` participates in the accumulator semantics** of class-2 words, which every table above
   had been averaging over. For class 2 `addr8` is the pointer post-increment delta, so
   *"`addr8 = 0` and holds"* is exactly the shape a do-nothing word should have.

⇒ `--by-addr8` belongs in any run that reports a ⛔ on a single machine, alongside
`--split-config` for one that pools several. Artefact:
`data/algebra_one_machine_byaddr8_2026-09-12.txt`.

⚠ Grade: MEASURED. Not a new decode of the chip — a correction to the extractor's grouping, and a
confirmation that the listing's `nop` and the device's behaviour match.

## Honest grade
MEASURED, about the **emulator**. The tables are regenerable with one command (in the tool's
docstring) from the archived captures. Nothing here is a statement about the µPD6383GF; §1 says so
and the tool's own docstring says so before any output is printed.
